//! `system`/`parallel` arena-access and cross-system lock-conflict analysis.
//!
//! `docs/features.md` pitches `par`/`swarm` as having "compile-time locks":
//! the compiler forbids running two systems concurrently if they'd hold a
//! conflicting (>= 1 mutable) lock on the same arena in the same tick. This
//! module is what actually makes that literal: `check_system` proves a
//! `system`'s body only ever touches the arenas it declared (respecting
//! read-only vs `mut`), and `check_parallel_stmt` proves a `parallel:`
//! block's listed systems don't conflict before letting them be dispatched
//! to the worker pool at the same time.
//!
//! v1 scope, deliberately narrow (mirrors `par_analysis`'s own "small,
//! conservative, sound" precedent rather than trying to attribute hazards
//! through an arbitrary call graph): a system body may not call another
//! user-defined `fn`/method at all, and may not write through a `GenRef`
//! index (read-only `GenRef` indexing is fine -- see `check_system_assign_target`).
//! Both are real restrictions, not silent gaps: rejected with a diagnostic
//! that says so, same as `par_analysis`'s own explicit bans on `frame`/
//! `each`/`spawn`/`despawn` inside a `par`/`swarm` body.

use std::collections::{HashMap, HashSet};

use super::par_analysis::is_banned_sdl_builtin_in_par;
use super::*;

/// The worker pool `codegen::par_pool` dispatches `par`/`swarm` chunks *and*
/// (once compiled) whole `system`s onto sizes itself at runtime from the
/// real hardware core count (see `codegen::par_pool::ensure_init`), but
/// never with fewer than `codegen::par_pool::MIN_WORKERS` live threads --
/// that floor, not the runtime-detected count, is the bound this
/// compile-time diagnostic must respect, since it runs long before any
/// hardware is known. A `parallel:` block can never meaningfully list more
/// systems than that floor: there'd be nowhere left to run the (N+1)th one
/// concurrently on a machine that happens to only have that many cores.
/// Kept as a small literal, doc-commented cross-reference rather than
/// plumbed across the `types`/`codegen` module boundary, since it only
/// matters as a compile-time diagnostic bound here -- must never exceed
/// `codegen::par_pool::MIN_WORKERS`.
const MAX_PARALLEL_SYSTEMS: usize = 4;

/// Per-system-body walk state: the declared arena-access table (unchanged
/// for the whole walk) plus the set of currently-in-scope loop variable
/// names bound by an `each` over a *read-only*-declared arena (mutating one
/// of these -- or a field of one -- is the one thing `each`'s own ordinary
/// checking doesn't already forbid, since a system's read-only declaration
/// has no `mut`-keyword-shaped syntax to hang a ban on the way `par`/`swarm`
/// hangs its disjointness proof off the loop variable). Cloned per nested
/// scope exactly like `par_analysis::walk_par_stmt`'s own `locals` set, so a
/// read-only `each` nested inside another doesn't leak its loop variable
/// into a sibling branch.
#[derive(Clone)]
struct SysCtx {
    accesses: HashMap<String, bool>,
    readonly_vars: HashSet<String>,
}

impl Checker {
    /// Type-check a `system Name(mut ArenaA, ArenaB): <body>` declaration.
    /// Mirrors `check_fn`'s body-checking skeleton (a system is, mechanically,
    /// a zero-parameter, non-returning procedure), then runs the
    /// arena-access walk below over the already-checked body.
    pub(super) fn check_system(&mut self, s: &SystemDecl) -> Option<TypedSystemDef> {
        let mut accesses_vec = Vec::new();
        let mut accesses_map: HashMap<String, bool> = HashMap::new();
        for acc in &s.accesses {
            if !self.arenas.contains_key(&acc.arena) {
                self.error(format!("system `{}` declares access to undefined arena `{}`", s.name, acc.arena), acc.span);
            }
            accesses_map.insert(acc.arena.clone(), acc.mutable);
            accesses_vec.push((acc.arena.clone(), acc.mutable));
        }

        // Same reentrancy guard `check_fn_with_self_ty` applies to
        // `loop_depth` around its own `check_block` call -- harmless here
        // today (a `system` is only ever checked from the top-level item
        // loop, never triggered mid-expression the way generic
        // monomorphization can trigger a `fn` body), but cheap and matches
        // the established convention for anything that calls `check_block`.
        let saved_loop_depth = self.loop_depth;
        self.loop_depth = 0;
        let dummy_sig = TypedFnSig { name: s.name.clone(), params: Vec::new(), ret: None, span: s.span };
        let body = self.check_block(&s.body, &dummy_sig)?;
        self.loop_depth = saved_loop_depth;

        let ctx = SysCtx { accesses: accesses_map, readonly_vars: HashSet::new() };
        self.walk_system_stmts(&s.name, &ctx, &body.stmts);

        Some(TypedSystemDef { name: s.name.clone(), accesses: accesses_vec, body, span: s.span })
    }

    /// Check a `parallel: SystemA() SystemB() ...` block: every listed name
    /// must resolve to a declared system, no name may repeat, the list may
    /// not exceed the worker pool's guaranteed minimum size, and no two listed systems
    /// may declare a conflicting (>= 1 mutable) access to the same arena --
    /// the literal "compile-time lock" `docs/features.md` describes.
    pub(super) fn check_parallel_stmt(&mut self, systems: &[(String, Span)], span: Span) -> TypedStmt {
        let mut resolved: Vec<(String, Vec<(String, bool)>)> = Vec::new();
        let mut seen_names: HashSet<String> = HashSet::new();
        for (name, name_span) in systems {
            match self.systems.get(name) {
                None => self.error(format!("undefined system `{}`", name), *name_span),
                Some(accesses) => {
                    if !seen_names.insert(name.clone()) {
                        self.error(
                            format!("system `{}` is listed more than once in the same `parallel:` block", name),
                            *name_span,
                        );
                    } else {
                        resolved.push((name.clone(), accesses.clone()));
                    }
                }
            }
        }

        if resolved.len() > MAX_PARALLEL_SYSTEMS {
            self.error(
                format!(
                    "a `parallel:` block can dispatch at most {} systems (the worker pool's guaranteed minimum size), found {}",
                    MAX_PARALLEL_SYSTEMS,
                    resolved.len()
                ),
                span,
            );
        }

        for i in 0..resolved.len() {
            for j in (i + 1)..resolved.len() {
                let (name_a, accesses_a) = &resolved[i];
                let (name_b, accesses_b) = &resolved[j];
                for (arena_a, mut_a) in accesses_a {
                    for (arena_b, mut_b) in accesses_b {
                        if arena_a == arena_b && (*mut_a || *mut_b) {
                            self.error(
                                format!(
                                    "systems `{}` and `{}` both request a lock on arena `{}` in the same tick \
                                     -- at least one is mutable, so they cannot run concurrently in one `parallel:` block",
                                    name_a, name_b, arena_a
                                ),
                                span,
                            );
                        }
                    }
                }
            }
        }

        TypedStmt::Parallel { systems: resolved.into_iter().map(|(name, _)| name).collect(), span }
    }

    fn check_system_arena_declared(&mut self, sys_name: &str, ctx: &SysCtx, arena: &str, needs_mut: bool, what: &str, span: Span) {
        match ctx.accesses.get(arena) {
            None => self.error(
                format!(
                    "system `{}` uses `{}` on arena `{}` without declaring it (add `{}{}` to `{}`'s access list)",
                    sys_name,
                    what,
                    arena,
                    if needs_mut { "mut " } else { "" },
                    arena,
                    sys_name
                ),
                span,
            ),
            Some(false) if needs_mut => self.error(
                format!(
                    "system `{}` declares arena `{}` read-only but `{}` requires mutable access (declare `mut {}`)",
                    sys_name, arena, what, arena
                ),
                span,
            ),
            Some(_) => {}
        }
    }

    fn walk_system_stmts(&mut self, sys_name: &str, ctx: &SysCtx, stmts: &[TypedStmt]) {
        for stmt in stmts {
            self.walk_system_stmt(sys_name, ctx, stmt);
        }
    }

    fn walk_system_stmt(&mut self, sys_name: &str, ctx: &SysCtx, stmt: &TypedStmt) {
        match stmt {
            TypedStmt::Let { value, .. } => self.walk_system_expr(sys_name, ctx, value),
            TypedStmt::Assign { target, value, span, .. } => {
                self.walk_system_expr(sys_name, ctx, value);
                self.check_system_assign_target(sys_name, ctx, target, *span);
            }
            TypedStmt::Return { value, .. } => {
                if let Some(v) = value {
                    self.walk_system_expr(sys_name, ctx, v);
                }
            }
            TypedStmt::Expr(e) => self.walk_system_expr(sys_name, ctx, e),
            TypedStmt::If { cond, then_block, else_block, .. } => {
                self.walk_system_expr(sys_name, ctx, cond);
                self.walk_system_stmts(sys_name, ctx, &then_block.stmts);
                if let Some(e) = else_block {
                    self.walk_system_stmts(sys_name, ctx, &e.stmts);
                }
            }
            TypedStmt::While { cond, then_block, else_block, .. } => {
                self.walk_system_expr(sys_name, ctx, cond);
                self.walk_system_stmts(sys_name, ctx, &then_block.stmts);
                if let Some(e) = else_block {
                    self.walk_system_stmts(sys_name, ctx, &e.stmts);
                }
            }
            TypedStmt::For { start, end, body, .. } => {
                self.walk_system_expr(sys_name, ctx, start);
                self.walk_system_expr(sys_name, ctx, end);
                self.walk_system_stmts(sys_name, ctx, &body.stmts);
            }
            TypedStmt::Break { .. } | TypedStmt::Continue { .. } => {}
            // Not arena-scoped at all -- the frame bump allocator's offset
            // is a single shared global, exactly as unsafe to touch from a
            // concurrently-dispatched system as from a `par`/`swarm` worker
            // (see `par_analysis`'s own `TypedStmt::Frame` arm).
            TypedStmt::Frame { span, .. } => {
                self.error(
                    format!(
                        "`frame:` cannot be used inside system `{}` (the frame bump allocator's offset is a \
                         single shared global, not thread-safe when systems run concurrently via `parallel:`)",
                        sys_name
                    ),
                    *span,
                );
            }
            // `par`'s whole point is per-iteration mutation, and its own
            // disjointness proof (`check_par_disjoint`, already run when
            // this `Stmt::Par` was type-checked) permits writing the loop
            // variable's own fields -- so unlike `each` below, a system's
            // `par` loop always requires `mut` on its arena, regardless of
            // whether this particular body happens to only read.
            TypedStmt::Par { arena, body, span, .. } => {
                self.check_system_arena_declared(sys_name, ctx, arena, true, "par", *span);
                self.walk_system_stmts(sys_name, ctx, &body.stmts);
            }
            // Unlike `par`, `each` may be declared read-only: if so, the
            // loop variable is added to `readonly_vars` for the duration of
            // this body, so `check_system_assign_target` can reject writing
            // to it (the one mutation shape that isn't already tagged with
            // an arena name the way `spawn`/`despawn`/`par` are).
            TypedStmt::Each { var, arena, body, span, .. } => {
                self.check_system_arena_declared(sys_name, ctx, arena, false, "each", *span);
                let mut inner = ctx.clone();
                if matches!(ctx.accesses.get(arena), Some(false)) {
                    inner.readonly_vars.insert(var.clone());
                }
                self.walk_system_stmts(sys_name, &inner, &body.stmts);
            }
            TypedStmt::Spawn { arena, elem, span } => {
                self.check_system_arena_declared(sys_name, ctx, arena, true, "spawn", *span);
                self.walk_system_expr(sys_name, ctx, elem);
            }
            TypedStmt::Despawn { arena, index, span } => {
                self.check_system_arena_declared(sys_name, ctx, arena, true, "despawn", *span);
                self.walk_system_expr(sys_name, ctx, index);
            }
            // A system already runs on a worker-pool thread once dispatched
            // via `parallel:` -- nesting another `parallel:` inside it would
            // try to dispatch onto the very pool it's already occupying a
            // slot in, exactly the reentrancy hazard
            // `codegen::par_pool::emit_par_dispatch`'s nested-`par` fallback
            // exists for, except there's no equivalent "run the nested
            // dispatch serially instead" fallback for whole systems.
            TypedStmt::Parallel { span, .. } => {
                self.error(
                    format!(
                        "`parallel:` cannot be nested inside system `{}` (a system already runs on a \
                         worker-pool thread once dispatched via `parallel:`)",
                        sys_name
                    ),
                    *span,
                );
            }
        }
    }

    /// `target`'s own sub-expressions (index expressions embedded in a
    /// projection chain, e.g. `arr[hazard()] = 1`) plus the two mutation
    /// shapes that aren't already tagged with an arena name the way
    /// `spawn`/`despawn`/`par`/`each` are: writing a read-only `each`
    /// loop variable's own field, and writing through a `GenRef` index at
    /// all (v1 scope: unsupported inside a system body -- see this module's
    /// doc comment).
    fn check_system_assign_target(&mut self, sys_name: &str, ctx: &SysCtx, target: &TypedExpr, span: Span) {
        self.walk_system_assign_target_subexprs(sys_name, ctx, target);
        if let Some(root) = root_ident(target) {
            if ctx.readonly_vars.contains(&root) {
                self.error(
                    format!("system `{}` cannot mutate `{}` -- its arena is declared read-only in this `each` loop", sys_name, root),
                    span,
                );
            }
        } else if genref_index_rooted(target) {
            self.error(
                format!(
                    "system `{}` cannot write through a `GenRef` index yet -- iterate the target arena directly \
                     with `par`/`each` instead",
                    sys_name
                ),
                span,
            );
        }
    }

    fn walk_system_assign_target_subexprs(&mut self, sys_name: &str, ctx: &SysCtx, target: &TypedExpr) {
        match target {
            TypedExpr::Field { base, .. } | TypedExpr::TupleIndex { base, .. } => {
                self.walk_system_assign_target_subexprs(sys_name, ctx, base);
            }
            TypedExpr::ListIndex { base, index, .. }
            | TypedExpr::ArrayIndex { base, index, .. }
            | TypedExpr::RingIndex { base, index, .. }
            | TypedExpr::TableIndex { base, index, .. }
            | TypedExpr::GenRefIndex { base, index, .. } => {
                self.walk_system_assign_target_subexprs(sys_name, ctx, base);
                self.walk_system_expr(sys_name, ctx, index);
            }
            _ => {}
        }
    }

    fn check_system_call(&mut self, sys_name: &str, callee: &TypedExpr, span: Span) {
        match callee {
            TypedExpr::Ident { name, .. } => {
                if is_banned_sdl_builtin_in_par(name) {
                    self.error(
                        format!(
                            "cannot call `{}` inside system `{}`: it touches SDL's shared window/renderer state or \
                             its global input-event queue, which is unsafe when systems run concurrently via `parallel:`",
                            name, sys_name
                        ),
                        span,
                    );
                } else if self.functions.contains_key(name) || self.generic_fns.contains_key(name) {
                    self.error(
                        format!(
                            "system `{}` cannot call the function `{}` (calling other functions from inside a \
                             system body is not supported yet -- inline the logic directly in the system)",
                            sys_name, name
                        ),
                        span,
                    );
                }
            }
            TypedExpr::Field { base, field, .. } => {
                if is_banned_sdl_builtin_in_par(field) {
                    self.error(
                        format!(
                            "cannot call `{}` inside system `{}`: it touches SDL's shared window/renderer state or \
                             its global input-event queue, which is unsafe when systems run concurrently via `parallel:`",
                            field, sys_name
                        ),
                        span,
                    );
                } else if let Ty::Named(struct_name) = base.clone().into_ty() {
                    let key = format!("{}#{}", struct_name, field);
                    if self.methods.contains_key(&key) {
                        self.error(
                            format!(
                                "system `{}` cannot call the method `{}` (calling other functions/methods from \
                                 inside a system body is not supported yet -- inline the logic directly in the system)",
                                sys_name, field
                            ),
                            span,
                        );
                    }
                }
            }
            _ => {}
        }
    }

    fn walk_system_expr(&mut self, sys_name: &str, ctx: &SysCtx, expr: &TypedExpr) {
        match expr {
            TypedExpr::Call { callee, args, span, .. } => {
                self.check_system_call(sys_name, callee, *span);
                self.walk_system_expr(sys_name, ctx, callee);
                for a in args {
                    self.walk_system_expr(sys_name, ctx, a);
                }
            }
            TypedExpr::Field { base, .. } => self.walk_system_expr(sys_name, ctx, base),
            TypedExpr::Binary { lhs, rhs, .. } => {
                self.walk_system_expr(sys_name, ctx, lhs);
                self.walk_system_expr(sys_name, ctx, rhs);
            }
            TypedExpr::Unary { operand, .. } => self.walk_system_expr(sys_name, ctx, operand),
            TypedExpr::Cast { expr, .. } => self.walk_system_expr(sys_name, ctx, expr),
            TypedExpr::Match { scrutinee, arms, .. } => {
                self.walk_system_expr(sys_name, ctx, scrutinee);
                for arm in arms {
                    self.walk_system_stmts(sys_name, ctx, &arm.body.stmts);
                }
            }
            TypedExpr::StructLit { args, .. } => {
                for a in args {
                    self.walk_system_expr(sys_name, ctx, a);
                }
            }
            TypedExpr::FStr(parts, ..) => {
                for p in parts {
                    if let TypedFStrExpr::Expr(e) = p {
                        self.walk_system_expr(sys_name, ctx, e);
                    }
                }
            }
            TypedExpr::If { cond, then_block, else_block, .. } => {
                self.walk_system_expr(sys_name, ctx, cond);
                self.walk_system_stmts(sys_name, ctx, &then_block.stmts);
                if let Some(e) = else_block {
                    self.walk_system_stmts(sys_name, ctx, &e.stmts);
                }
            }
            TypedExpr::Spawn { arena, elem, span, .. } => {
                self.check_system_arena_declared(sys_name, ctx, arena, true, "spawn", *span);
                self.walk_system_expr(sys_name, ctx, elem);
            }
            TypedExpr::GenRefCreate { value, .. }
            | TypedExpr::WrappingNew { value, .. }
            | TypedExpr::FixedNew { value, .. }
            | TypedExpr::BitFieldNew { value, .. }
            | TypedExpr::ArrayRepeat { value, .. } => self.walk_system_expr(sys_name, ctx, value),
            TypedExpr::FlagsNew { args, .. } | TypedExpr::EnumVariant { args, .. } | TypedExpr::TupleLit { elems: args, .. } => {
                for a in args {
                    self.walk_system_expr(sys_name, ctx, a);
                }
            }
            // A read through a `GenRef` index is unrestricted (only a
            // *write* is banned, in `check_system_assign_target`) --
            // reading data another system might concurrently also be
            // reading (or that this system's own declared arenas already
            // cover) is exactly as safe as any other pure read.
            TypedExpr::GenRefIndex { base, index, .. } => {
                self.walk_system_expr(sys_name, ctx, base);
                self.walk_system_expr(sys_name, ctx, index);
            }
            // A closure literal defined inside a system body can only ever
            // be invoked from within that same body (a system takes no
            // parameters and has no enclosing scope to capture from, unlike
            // a `par`/`swarm` body nested inside an ordinary function), so
            // its statements are exactly as inspectable as the rest of the
            // body -- walk into it directly rather than banning it outright
            // the way `par_analysis` must (there, a closure might be called
            // from a completely different, unprovable context).
            TypedExpr::Closure { body, .. } => self.walk_system_stmts(sys_name, ctx, &body.stmts),
            TypedExpr::ListLit { elems, .. } => {
                for e in elems {
                    self.walk_system_expr(sys_name, ctx, e);
                }
            }
            TypedExpr::ListIndex { base, index, .. }
            | TypedExpr::StrIndex { base, index, .. }
            | TypedExpr::ArrayIndex { base, index, .. }
            | TypedExpr::RingIndex { base, index, .. }
            | TypedExpr::TableIndex { base, index, .. } => {
                self.walk_system_expr(sys_name, ctx, base);
                self.walk_system_expr(sys_name, ctx, index);
            }
            TypedExpr::ListMethod { base, args, .. }
            | TypedExpr::MapMethod { base, args, .. }
            | TypedExpr::SetMethod { base, args, .. }
            | TypedExpr::RingMethod { base, args, .. }
            | TypedExpr::TableMethod { base, args, .. } => {
                self.walk_system_expr(sys_name, ctx, base);
                for a in args {
                    self.walk_system_expr(sys_name, ctx, a);
                }
            }
            TypedExpr::TupleIndex { base, .. } | TypedExpr::ArrayLen { base, .. } => {
                self.walk_system_expr(sys_name, ctx, base)
            }
            TypedExpr::ListNew { .. } | TypedExpr::MapNew { .. } | TypedExpr::SetNew { .. } | TypedExpr::RingNew { .. } | TypedExpr::TableNew { .. } => {}
            TypedExpr::Int(..)
            | TypedExpr::Float(..)
            | TypedExpr::Str(..)
            | TypedExpr::Bool(..)
            | TypedExpr::Char(..)
            | TypedExpr::Ident { .. }
            | TypedExpr::SelfExpr(..)
            | TypedExpr::Error(_) => {}
        }
    }
}

/// True if `target`'s ultimate projection root (after peeling `Field`/
/// `TupleIndex`/`ListIndex`/`ArrayIndex`/`RingIndex`/`TableIndex`, mirroring
/// `root_ident`'s own recursion through the same node kinds) is a
/// `GenRefIndex` -- i.e. this assignment writes through a `GenRef`
/// dereference, e.g. `g[0].hp -= 1`. See `check_system_assign_target`'s doc
/// comment for why this is unconditionally rejected in a system body: unlike
/// `spawn`/`despawn`/`par`/`each`, a `GenRef` doesn't carry which specific
/// arena it points into (only its pointee *type*, which more than one arena
/// could share), so there's no sound way to attribute the write to one of
/// the system's declared accesses.
fn genref_index_rooted(target: &TypedExpr) -> bool {
    match target {
        TypedExpr::GenRefIndex { .. } => true,
        TypedExpr::Field { base, .. } | TypedExpr::TupleIndex { base, .. } => genref_index_rooted(base),
        TypedExpr::ListIndex { base, .. }
        | TypedExpr::ArrayIndex { base, .. }
        | TypedExpr::RingIndex { base, .. }
        | TypedExpr::TableIndex { base, .. } => genref_index_rooted(base),
        _ => false,
    }
}
