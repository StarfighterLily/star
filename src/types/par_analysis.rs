//! `par`/`swarm` disjoint-access analysis.
//!
//! Proves (conservatively) that a `par` body's iterations don't race: the
//! only things a body may *mutate* are the loop variable's own fields and
//! locals it declares itself (both are per-iteration/per-thread, so safe
//! by construction). Any write to a name captured from the enclosing
//! scope — including `self` — is rejected, since concurrent writes to
//! shared state from multiple worker threads would race. Method calls are
//! held to the same standard, since a call `x.foo()` might mutate `x`
//! internally: only calls on the loop variable (or a body-local) are
//! allowed.

use std::collections::HashSet;

use super::*;

impl Checker {
    pub(super) fn check_par_disjoint(&mut self, var: &str, block: &TypedBlock) {
        let mut locals: HashSet<String> = HashSet::new();
        locals.insert(var.to_string());
        self.walk_par_stmts(&block.stmts, &mut locals);
    }

    fn walk_par_stmts(&mut self, stmts: &[TypedStmt], locals: &mut HashSet<String>) {
        for stmt in stmts {
            self.walk_par_stmt(stmt, locals);
        }
    }

    fn walk_par_stmt(&mut self, stmt: &TypedStmt, locals: &mut HashSet<String>) {
        match stmt {
            TypedStmt::Let { name, value, .. } => {
                self.walk_par_expr(value, locals);
                locals.insert(name.clone());
            }
            TypedStmt::Assign { target, value, span, .. } => {
                self.walk_par_expr(value, locals);
                self.walk_par_assign_target(target, locals);
                match root_ident(target) {
                    Some(root) if locals.contains(&root) => {}
                    Some(root) => self.error(
                        format!(
                            "par/swarm body may only mutate the loop variable or locals it declares; \
                             write to `{}` cannot be proven disjoint across threads",
                            root
                        ),
                        *span,
                    ),
                    None => self.error("unsupported mutation target in par/swarm body", *span),
                }
            }
            TypedStmt::Return { value, .. } => {
                if let Some(v) = value {
                    self.walk_par_expr(v, locals);
                }
            }
            TypedStmt::Expr(e) => self.walk_par_expr(e, locals),
            TypedStmt::If { cond, then_block, else_block, .. } => {
                self.walk_par_expr(cond, locals);
                let mut l = locals.clone();
                self.walk_par_stmts(&then_block.stmts, &mut l);
                if let Some(e) = else_block {
                    let mut l = locals.clone();
                    self.walk_par_stmts(&e.stmts, &mut l);
                }
            }
            TypedStmt::While { cond, then_block, else_block, .. } => {
                self.walk_par_expr(cond, locals);
                let mut l = locals.clone();
                self.walk_par_stmts(&then_block.stmts, &mut l);
                if let Some(e) = else_block {
                    let mut l = locals.clone();
                    self.walk_par_stmts(&e.stmts, &mut l);
                }
            }
            TypedStmt::For { var, start, end, body, .. } => {
                self.walk_par_expr(start, locals);
                self.walk_par_expr(end, locals);
                let mut l = locals.clone();
                l.insert(var.clone());
                self.walk_par_stmts(&body.stmts, &mut l);
            }
            TypedStmt::Break { .. } | TypedStmt::Continue { .. } => {}
            TypedStmt::Frame { span, .. } => {
                // `@frame.off`/`@frame.buf` are single process-wide globals
                // (see `Codegen::emit_par_stmt`'s own `self.in_frame = false`
                // comment: "the frame bump allocator's offset is a single
                // shared global, not thread-safe") -- every worker thread
                // bump-allocating from the same shared buffer concurrently
                // would race exactly like `spawn`/`despawn` racing on an
                // arena's globals, so this must be rejected the same way
                // rather than silently recursing into the body as if it were
                // an ordinary nested scope.
                self.error(
                    "`frame:` cannot be used inside a par/swarm body (the frame bump allocator's offset is a \
                     single shared global, not thread-safe across worker threads)",
                    *span,
                );
            }
            TypedStmt::Par { var, body, .. } => {
                // A nested par loop gets its own fresh disjointness proof
                // (via its own `Stmt::Par` check_par_disjoint call, triggered
                // separately when `check_block_inner` type-checked it); this
                // walk just recurses for any captures the nested body makes
                // of the *outer* scope. The nested loop's own variable must
                // still be added to `locals` here -- it's per-iteration
                // state of the nested loop, not a shared/captured outer
                // name, so mutating its own fields is exactly as safe as any
                // other body-local, and without this the nested body's own
                // (already-proven-safe) mutation of its own loop variable
                // would incorrectly be flagged as an outer-scope capture.
                let mut l = locals.clone();
                l.insert(var.clone());
                self.walk_par_stmts(&body.stmts, &mut l);
            }
            TypedStmt::Spawn { span, .. } => {
                // Every worker thread would race on the same arena's
                // `count`/`data` globals, so population can't happen from
                // inside a body whose iterations are supposed to be disjoint.
                self.error(
                    "`spawn` cannot be used inside a par/swarm body (arena population is not disjoint across threads)",
                    *span,
                );
            }
            TypedStmt::Despawn { span, .. } => {
                // Same race as `spawn`: every worker thread would contend on
                // the same arena's `gen` global.
                self.error(
                    "`despawn` cannot be used inside a par/swarm body (concurrent generation bumps are not disjoint across threads)",
                    *span,
                );
            }
        }
    }

    /// Walk the sub-expressions of an assignment *target* that aren't
    /// themselves the write location -- specifically, any index expression
    /// nested inside it (`arr[hazard()] = 1`, `t[hazard()].f = 1`, ...).
    /// `walk_par_stmt`'s `Assign` arm already proves *which* binding is
    /// being written to via `root_ident` (and that it's a body-local, not a
    /// captured outer name) -- but `root_ident` only extracts the target's
    /// *root* identifier, never inspecting an index sub-expression along
    /// the way, so a hazardous call embedded in one (anything
    /// `unsafe_par_fns` would otherwise reject in a `let`/argument
    /// position) was invisible to this whole analysis: previously
    /// `Stmt::Assign` only ever called `walk_par_expr` on `value`, never on
    /// `target`, so `arr[hazard()] = 1` (where `hazard()` transitively
    /// `spawn`s into a shared arena) type-checked cleanly even though the
    /// exact same call in a `let x = hazard()` position was correctly
    /// rejected -- a soundness hole letting an unsynchronized-across-
    /// worker-threads race compile silently. Mirrors `root_ident`'s own
    /// recursion through the same projection kinds, but also walks each
    /// index-bearing node's `index` expression via `walk_par_expr` (the
    /// same hazard/capture-aware walk a `let`/call-argument position gets)
    /// rather than silently skipping it.
    fn walk_par_assign_target(&mut self, target: &TypedExpr, locals: &HashSet<String>) {
        match target {
            TypedExpr::Field { base, .. } | TypedExpr::TupleIndex { base, .. } => {
                self.walk_par_assign_target(base, locals);
            }
            TypedExpr::ListIndex { base, index, .. }
            | TypedExpr::ArrayIndex { base, index, .. }
            | TypedExpr::RingIndex { base, index, .. }
            | TypedExpr::TableIndex { base, index, .. }
            | TypedExpr::GenRefIndex { base, index, .. } => {
                self.walk_par_assign_target(base, locals);
                self.walk_par_expr(index, locals);
            }
            _ => {}
        }
    }

    fn walk_par_expr(&mut self, expr: &TypedExpr, locals: &HashSet<String>) {
        match expr {
            TypedExpr::Call { callee, args, span, .. } => {
                // The callable name, whichever syntactic shape the call took
                // (`name(..)` or `obj.method(..)`), used below to check
                // whether it (transitively) performs an operation the
                // disjointness proof can't see through -- see
                // `Checker::unsafe_par_fns`.
                let called_name: Option<&str> = match callee.as_ref() {
                    TypedExpr::Field { base, field, .. } => {
                        match root_ident(base) {
                            Some(root) if locals.contains(&root) => {}
                            _ => self.error(
                                "cannot call a method on a captured value inside a par/swarm body \
                                 (only the loop variable's own methods may be called)",
                                *span,
                            ),
                        }
                        Some(field.as_str())
                    }
                    TypedExpr::Ident { name, .. } => Some(name.as_str()),
                    _ => None,
                };
                // A plain function call was previously entirely unchecked
                // here: the disjointness proof only ever looked at *this*
                // body's statements, so moving a `spawn`/`despawn`/`frame:`
                // one level into a helper function (or nesting it further,
                // through a chain of calls) bypassed the ban completely --
                // even though it produces the exact same unsynchronized
                // 4-thread race on the arena's globals `spawn`/`despawn`
                // are directly banned to prevent. `unsafe_par_fns` is
                // precomputed (transitively, through the whole call graph)
                // before any body is checked, so this catches the hazard
                // regardless of declaration order or how many calls deep it is.
                // A call whose *callee itself* is closure-typed (a captured
                // `let`-bound lambda, a closure-typed field/parameter, or an
                // immediately-invoked lambda literal) is a call to a value
                // whose body was never a top-level `fn`/`impl` declaration at
                // all -- `compute_unsafe_par_fns` only ever walks named
                // function/method bodies (see its own doc comment on why it
                // skips `Expr::Lambda`), so `unsafe_par_fns` can never
                // recognize a closure body's hazards, and the `called_name`
                // check below silently passes regardless of what the closure
                // actually does. `rejects_closure_inside_par_body` already
                // bans *defining* a closure literal in a par/swarm body for
                // exactly this "can't prove its body disjoint" reason (see
                // `TypedExpr::Closure`'s arm below); *invoking* one captured
                // from the outer scope is the same hazard reached a
                // different way -- e.g. a closure defined outside a `par`
                // that itself calls `spawn`, then invoked from inside the
                // body, previously type-checked cleanly and raced all four
                // worker threads on the arena's globals.
                if matches!(callee.clone().into_ty(), Ty::Closure(..)) {
                    self.error(
                        "cannot call a closure value inside a par/swarm body (its body cannot be proven \
                         disjoint across worker threads -- only a plain, named function/method call is allowed)",
                        *span,
                    );
                }
                if let Some(name) = called_name {
                    // `unsafe_par_fns` is keyed by each hazardous function's
                    // *declared* (template) name, computed from the raw AST
                    // before any generic instantiation happens (see
                    // `compute_unsafe_par_fns`). A call to a generic
                    // function/method instead names its *mangled* monomorphized
                    // form here (`sneaky__i32`, via `Checker::instantiate_fn`)
                    // -- resolve back through `mono_fn_of` (populated at the
                    // instantiation site) so the hazard is still recognized,
                    // or this whole ban is silently bypassed for any generic
                    // hazard just by it being generic.
                    let hazard_name = self.mono_fn_of.get(name).map(|s| s.as_str()).unwrap_or(name);
                    if self.unsafe_par_fns.contains(hazard_name) {
                        self.error(
                            format!(
                                "cannot call `{}` inside a par/swarm body: it spawns/despawns entities or opens a \
                                 `frame:` block (directly or through another call), which cannot be proven disjoint \
                                 across worker threads",
                                name
                            ),
                            *span,
                        );
                    }
                }
                self.walk_par_expr(callee, locals);
                for a in args {
                    self.walk_par_expr(a, locals);
                }
            }
            TypedExpr::Field { base, .. } => self.walk_par_expr(base, locals),
            TypedExpr::Binary { lhs, rhs, .. } => {
                self.walk_par_expr(lhs, locals);
                self.walk_par_expr(rhs, locals);
            }
            TypedExpr::Unary { operand, .. } => self.walk_par_expr(operand, locals),
            TypedExpr::Match { scrutinee, arms, .. } => {
                self.walk_par_expr(scrutinee, locals);
                for arm in arms {
                    let mut l = locals.clone();
                    // A payload pattern's bindings are fresh per-match
                    // locals (destructured out of the scrutinee), safe to
                    // treat the same as any other body-local.
                    if let Pattern::EnumVariant(_, _, bindings) | Pattern::Struct(_, bindings) = &arm.pattern {
                        for b in bindings {
                            l.insert(b.clone());
                        }
                    }
                    // `Pattern::Binding(name)` binds the *whole* scrutinee to
                    // a fresh per-arm name (`match x: v -> ...`) -- just as
                    // much a fresh body-local as a destructured payload
                    // field above; without this, mutating it was rejected as
                    // "cannot mutate a captured value" even though it's
                    // exactly as safe as any other match-arm/body-local.
                    if let Pattern::Binding(name) = &arm.pattern {
                        l.insert(name.clone());
                    }
                    self.walk_par_stmts(&arm.body.stmts, &mut l);
                }
            }
            TypedExpr::StructLit { args, .. } => {
                for a in args {
                    self.walk_par_expr(a, locals);
                }
            }
            TypedExpr::FStr(parts, ..) => {
                for p in parts {
                    if let TypedFStrExpr::Expr(e) = p {
                        self.walk_par_expr(e, locals);
                    }
                }
            }
            TypedExpr::If { cond, then_block, else_block, .. } => {
                self.walk_par_expr(cond, locals);
                let mut l = locals.clone();
                self.walk_par_stmts(&then_block.stmts, &mut l);
                if let Some(e) = else_block {
                    let mut l = locals.clone();
                    self.walk_par_stmts(&e.stmts, &mut l);
                }
            }
            TypedExpr::GenRefCreate { value, .. } => self.walk_par_expr(value, locals),
            TypedExpr::WrappingNew { value, .. } => self.walk_par_expr(value, locals),
            TypedExpr::FixedNew { value, .. } => self.walk_par_expr(value, locals),
            TypedExpr::GenRefIndex { base, index, .. } => {
                self.walk_par_expr(base, locals);
                self.walk_par_expr(index, locals);
            }
            TypedExpr::EnumVariant { args, .. } => {
                for a in args {
                    self.walk_par_expr(a, locals);
                }
            }
            // A closure literal's body isn't walked by this per-statement
            // disjointness proof (it only runs when/if the closure is later
            // called, possibly from entirely outside this par/swarm body),
            // so any mutation it makes can't be soundly proven disjoint here.
            // Simplest safe answer: reject closures inside a par/swarm body
            // outright, mirroring `spawn`/`despawn` above.
            TypedExpr::Closure { span, .. } => {
                self.error("closures are not supported inside a par/swarm body", *span);
            }
            TypedExpr::ListNew { .. } => {}
            TypedExpr::ListLit { elems, .. } => {
                for e in elems {
                    self.walk_par_expr(e, locals);
                }
            }
            TypedExpr::ListIndex { base, index, .. } => {
                self.walk_par_expr(base, locals);
                self.walk_par_expr(index, locals);
            }
            TypedExpr::StrIndex { base, index, .. } => {
                self.walk_par_expr(base, locals);
                self.walk_par_expr(index, locals);
            }
            // `push`/`pop` mutate the receiver in place (growing/shrinking
            // its backing buffer), so they're held to the same standard as
            // a struct method call above: only the loop variable's own
            // list (or a body-local one) can be proven disjoint across
            // threads. `len` only reads, so it's exempt.
            TypedExpr::ListMethod { base, method, args, span, .. } => {
                if matches!(method, ListMethod::Push | ListMethod::Pop) {
                    match root_ident(base) {
                        Some(root) if locals.contains(&root) => {}
                        _ => self.error(
                            "cannot mutate a captured list inside a par/swarm body \
                             (only the loop variable's own locals may be mutated)",
                            *span,
                        ),
                    }
                }
                self.walk_par_expr(base, locals);
                for a in args {
                    self.walk_par_expr(a, locals);
                }
            }
            TypedExpr::MapNew { .. } => {}
            TypedExpr::SetNew { .. } => {}
            // Same reasoning as `ListMethod` above: `insert`/`remove` mutate
            // the receiver's backing buffer in place, so only a body-local
            // receiver can be proven disjoint across threads; `get`/
            // `contains`/`len` only read, so they're exempt.
            TypedExpr::MapMethod { base, method, args, span, .. } => {
                if matches!(method, MapMethod::Insert | MapMethod::Remove) {
                    match root_ident(base) {
                        Some(root) if locals.contains(&root) => {}
                        _ => self.error(
                            "cannot mutate a captured map inside a par/swarm body \
                             (only the loop variable's own locals may be mutated)",
                            *span,
                        ),
                    }
                }
                self.walk_par_expr(base, locals);
                for a in args {
                    self.walk_par_expr(a, locals);
                }
            }
            TypedExpr::SetMethod { base, method, args, span, .. } => {
                if matches!(method, SetMethod::Insert | SetMethod::Remove) {
                    match root_ident(base) {
                        Some(root) if locals.contains(&root) => {}
                        _ => self.error(
                            "cannot mutate a captured set inside a par/swarm body \
                             (only the loop variable's own locals may be mutated)",
                            *span,
                        ),
                    }
                }
                self.walk_par_expr(base, locals);
                for a in args {
                    self.walk_par_expr(a, locals);
                }
            }
            TypedExpr::TupleLit { elems, .. } => {
                for e in elems {
                    self.walk_par_expr(e, locals);
                }
            }
            TypedExpr::TupleIndex { base, .. } => self.walk_par_expr(base, locals),
            TypedExpr::ArrayRepeat { value, .. } => self.walk_par_expr(value, locals),
            // A read is always fine to walk into (mirrors `ListIndex`
            // above); there's no `push`/`pop`-style mutating method to gate
            // here at all -- array element writes go through a plain
            // `Stmt::Assign` target, checked generically via `root_ident` in
            // `walk_par_stmt`.
            TypedExpr::ArrayIndex { base, index, .. } => {
                self.walk_par_expr(base, locals);
                self.walk_par_expr(index, locals);
            }
            TypedExpr::ArrayLen { base, .. } => self.walk_par_expr(base, locals),
            TypedExpr::RingNew { .. } => {}
            // Same reasoning as `ListMethod` above: `push`/`pop` mutate the
            // receiver's own inline storage, so only a body-local receiver
            // can be proven disjoint across threads; `len` only reads, so
            // it's exempt.
            TypedExpr::RingMethod { base, method, args, span, .. } => {
                if matches!(method, RingMethod::Push | RingMethod::Pop) {
                    match root_ident(base) {
                        Some(root) if locals.contains(&root) => {}
                        _ => self.error(
                            "cannot mutate a captured ring inside a par/swarm body \
                             (only the loop variable's own locals may be mutated)",
                            *span,
                        ),
                    }
                }
                self.walk_par_expr(base, locals);
                for a in args {
                    self.walk_par_expr(a, locals);
                }
            }
            // A read is always fine to walk into (mirrors `ArrayIndex`
            // above); a ring element *write* goes through a plain
            // `Stmt::Assign` target, checked generically via `root_ident` in
            // `walk_par_stmt`.
            TypedExpr::RingIndex { base, index, .. } => {
                self.walk_par_expr(base, locals);
                self.walk_par_expr(index, locals);
            }
            TypedExpr::TableNew { .. } => {}
            // Same reasoning as `ListMethod` above: `push`/`pop` mutate the
            // receiver's own column buffers in place, so only a body-local
            // receiver can be proven disjoint across threads; `len` only
            // reads, so it's exempt.
            TypedExpr::TableMethod { base, method, args, span, .. } => {
                if matches!(method, TableMethod::Push | TableMethod::Pop) {
                    match root_ident(base) {
                        Some(root) if locals.contains(&root) => {}
                        _ => self.error(
                            "cannot mutate a captured table inside a par/swarm body \
                             (only the loop variable's own locals may be mutated)",
                            *span,
                        ),
                    }
                }
                self.walk_par_expr(base, locals);
                for a in args {
                    self.walk_par_expr(a, locals);
                }
            }
            // A read is always fine to walk into (mirrors `ListIndex`
            // above); a table element *write* goes through a plain
            // `Stmt::Assign` target, checked generically via `root_ident` in
            // `walk_par_stmt`.
            TypedExpr::TableIndex { base, index, .. } => {
                self.walk_par_expr(base, locals);
                self.walk_par_expr(index, locals);
            }
            TypedExpr::Int(..)
            | TypedExpr::Float(..)
            | TypedExpr::Str(..)
            | TypedExpr::Bool(..)
            | TypedExpr::Char(..)
            | TypedExpr::Ident { .. }
            | TypedExpr::SelfExpr(..)
            | TypedExpr::Error(_) => {}
            // A cast has no receiver/mutation of its own to gate -- just
            // walk its inner expression, same as `Unary` above.
            TypedExpr::Cast { expr, .. } => self.walk_par_expr(expr, locals),
        }
    }
}
