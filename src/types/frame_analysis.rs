//! `frame:` escape analysis, plus the closure-capturing-`self` escape check
//! it grew a second half to cover.
//!
//! design.md's safety pitch for `frame` is that "frame pointers can never
//! be assigned to lifetimes exceeding the current tick": a `frame:` block
//! is a scoped bump allocator whose offset is rewound the instant the
//! block ends, so a struct value whose *identity* traces back to a
//! binding declared inside one must never survive past it. Scalars,
//! Vec/Mat SIMD values, and `GenRef`s are plain data copied by value
//! everywhere in this compiler and can never dangle, so only `Ty::Named`
//! (user struct) values are tracked here; reading a scalar-typed field
//! out of a frame-local struct (`p.x`), or passing the struct itself
//! through a function call (which only borrows it for the duration of
//! that synchronous call, and is independently checked against leaking
//! its own frame-locals right back out), is not an escape.
//!
//! The three vectors this catches, matching todo.md's language: returning
//! a frame-local struct from the enclosing function (an explicit
//! `return`, or an implicit trailing-expression fallthrough out of a
//! `frame:` block in tail position), assigning one into a target that
//! isn't itself frame-local (a struct field, an outer variable, ...), and
//! `spawn`-ing one into a (necessarily longer-lived) arena. These three
//! checks stay scoped to `frame_locals` (`let`s declared inside a
//! `frame:` block) exactly as before -- an ordinary local struct's *value*
//! is always a safe, independent copy when returned/assigned/spawned (see
//! `Codegen::emit_fn`/`emit_stmt`'s `Let`/`Assign` arms), so broadening
//! these three to ordinary locals would reject sound, common code
//! (`fn make() -> Point:\n    let p = Point(1, 2)\n    return p`) for no
//! safety benefit.
//!
//! A closure escaping with a captured `self` *pointer* is a different
//! animal, tracked separately below: `self` is captured by pointer, not
//! by value (`Codegen::captured_value_llvm_ty`), and `Codegen::emit_place`
//! resolves *any* receiver shape -- a bare local, a nested field access,
//! or an arbitrary rvalue spilled into a fresh alloca -- to a pointer
//! whose backing storage is never any longer-lived than the function that
//! computed it. That makes every `Ty::Named` local in the compiler's
//! current object model equally risky as a method receiver whose method
//! returns a closure: not just `frame:`-scoped ones, but ordinary `let`
//! bindings and by-value parameters too (see `local_structs` below).
//! `self` itself is deliberately excluded from that set: its backing
//! storage belongs to *this* function's own caller, whose safety is
//! independently verified when the caller's body is checked in turn.

use std::collections::HashSet;

use super::*;

impl Checker {
    pub(super) fn check_frame_escapes(&mut self, body: &TypedBlock, sig: &TypedFnSig) {
        let mut frame_locals = HashSet::new();
        // Seed with every by-value `Ty::Named` parameter (`self` excluded,
        // see this module's doc comment) -- its storage is this function's
        // own alloca, exactly like a `let`-bound local, so a method call
        // through it that returns a closure has the same dangling-`self`
        // risk as todo.md's "or a by-value parameter" repro.
        let mut local_structs: HashSet<String> =
            sig.params.iter().filter(|p| !p.is_self && matches!(p.ty, Ty::Named(_))).map(|p| p.name.clone()).collect();
        self.walk_frame_stmts(&body.stmts, &mut frame_locals, &mut local_structs, false, true);
    }

    fn walk_frame_stmts(
        &mut self,
        stmts: &[TypedStmt],
        frame_locals: &mut HashSet<String>,
        local_structs: &mut HashSet<String>,
        in_frame: bool,
        tail: bool,
    ) {
        let last = stmts.len().saturating_sub(1);
        for (i, stmt) in stmts.iter().enumerate() {
            self.walk_frame_stmt(stmt, frame_locals, local_structs, in_frame, tail && i == last);
        }
    }

    fn walk_frame_stmt(
        &mut self,
        stmt: &TypedStmt,
        frame_locals: &mut HashSet<String>,
        local_structs: &mut HashSet<String>,
        in_frame: bool,
        tail: bool,
    ) {
        match stmt {
            TypedStmt::Let { name, value, .. } => {
                // `let name = spawn ArenaName(args...)` -- the expression
                // form of `spawn` (see `Expr::Spawn`'s doc comment) is only
                // ever reachable as exactly this statement's `value`, so
                // this is the one place that needs the same frame-escape
                // check `TypedStmt::Spawn`'s arm below applies to the
                // statement form: the spawned struct's constructor args
                // must not reference a frame-local (or self-captured-by-
                // pointer) struct that doesn't outlive the arena.
                if let TypedExpr::Spawn { elem, span, .. } = value {
                    if let Some(escaped) = frame_escape_source(elem, frame_locals, local_structs) {
                        self.error(
                            format!(
                                "cannot `spawn` using `{}`: it is {} and does not outlive the arena",
                                escaped,
                                escape_reason(&escaped, frame_locals)
                            ),
                            *span,
                        );
                    }
                }
                // Registered regardless of `ty` -- not just a `Ty::Named`
                // local -- mirroring `frame_locals`'s own unconditional
                // insert just below. A tuple/array-typed local (`let pair:
                // (Point, Point) = (..)`) is itself backed by this
                // function's own storage exactly like a plain struct local
                // is, and a `Ty::Named` *element* of it (`pair.0`) is just a
                // positional projection into that same storage (see
                // `local_struct_receiver`'s `TupleIndex`/`ArrayIndex` arms) --
                // every consumer of `local_structs` already re-checks the
                // *access site*'s own type is `Ty::Named` before treating a
                // hit as a hazard, so registering non-`Ty::Named` names here
                // too can only close gaps, never introduce a false positive.
                // Previously gating this insert on `ty` itself meant a
                // tuple/array-typed local's struct-typed element could never
                // be found in `local_structs` at all, regardless of how
                // `local_struct_receiver` chained through it.
                local_structs.insert(name.clone());
                if in_frame {
                    frame_locals.insert(name.clone());
                }
            }
            TypedStmt::Assign { target, value, span, .. } => {
                if let Some(name) = frame_escape_source(value, frame_locals, local_structs) {
                    let escapes = match root_ident(target) {
                        Some(root) => !frame_locals.contains(&root),
                        None => true,
                    };
                    if escapes {
                        self.error(
                            format!(
                                "`{}` is {}; its memory does not outlive that scope, so it cannot be assigned outside it",
                                name,
                                escape_reason(&name, frame_locals)
                            ),
                            *span,
                        );
                    }
                }
            }
            TypedStmt::Return { value, span } => {
                if let Some(v) = value {
                    if let Some(name) = frame_escape_source(v, frame_locals, local_structs) {
                        self.error(
                            format!("cannot return `{}`: it is {} and does not outlive the current tick", name, escape_reason(&name, frame_locals)),
                            *span,
                        );
                    }
                }
            }
            TypedStmt::Expr(e) => {
                if tail {
                    if let Some(name) = frame_escape_source(e, frame_locals, local_structs) {
                        self.error(
                            format!(
                                "cannot use `{}` as this function's value: it is {} and does not outlive the current tick",
                                name,
                                escape_reason(&name, frame_locals)
                            ),
                            e.span(),
                        );
                    }
                }
            }
            TypedStmt::If { then_block, else_block, .. } => {
                let mut l = frame_locals.clone();
                let mut ls = local_structs.clone();
                self.walk_frame_stmts(&then_block.stmts, &mut l, &mut ls, in_frame, false);
                if let Some(e) = else_block {
                    let mut l = frame_locals.clone();
                    let mut ls = local_structs.clone();
                    self.walk_frame_stmts(&e.stmts, &mut l, &mut ls, in_frame, false);
                }
            }
            TypedStmt::While { then_block, else_block, .. } => {
                let mut l = frame_locals.clone();
                let mut ls = local_structs.clone();
                self.walk_frame_stmts(&then_block.stmts, &mut l, &mut ls, in_frame, false);
                if let Some(e) = else_block {
                    let mut l = frame_locals.clone();
                    let mut ls = local_structs.clone();
                    self.walk_frame_stmts(&e.stmts, &mut l, &mut ls, in_frame, false);
                }
            }
            TypedStmt::For { body, .. } => {
                let mut l = frame_locals.clone();
                let mut ls = local_structs.clone();
                self.walk_frame_stmts(&body.stmts, &mut l, &mut ls, in_frame, false);
            }
            TypedStmt::Break { .. } | TypedStmt::Continue { .. } => {}
            TypedStmt::Frame { body, .. } => {
                let mut l = frame_locals.clone();
                let mut ls = local_structs.clone();
                self.walk_frame_stmts(&body.stmts, &mut l, &mut ls, true, tail);
            }
            TypedStmt::Par { body, .. } => {
                let mut l = frame_locals.clone();
                let mut ls = local_structs.clone();
                self.walk_frame_stmts(&body.stmts, &mut l, &mut ls, in_frame, false);
            }
            TypedStmt::Each { body, .. } => {
                let mut l = frame_locals.clone();
                let mut ls = local_structs.clone();
                self.walk_frame_stmts(&body.stmts, &mut l, &mut ls, in_frame, false);
            }
            TypedStmt::Spawn { elem, span, .. } => {
                if let Some(name) = frame_escape_source(elem, frame_locals, local_structs) {
                    self.error(
                        format!("cannot `spawn` using `{}`: it is {} and does not outlive the arena", name, escape_reason(&name, frame_locals)),
                        *span,
                    );
                }
            }
            TypedStmt::Despawn { .. } => {}
        }
    }
}

/// The human-readable reason a tracked name is unsafe to let escape,
/// distinguishing a `frame:`-scoped local (rewound at block exit) from an
/// ordinary local/by-value parameter (scoped to the whole function, only
/// unsafe here because a closure captured it as `self` by pointer -- see
/// this module's doc comment) so the diagnostic stays accurate either way.
fn escape_reason(name: &str, frame_locals: &HashSet<String>) -> String {
    if name == ANONYMOUS_CALL_RESULT {
        "a temporary struct with no binding of its own, whose method was called by a closure that captured it as `self` by pointer".to_string()
    } else if frame_locals.contains(name) {
        "a struct allocated inside a `frame:` scope (or a closure that captured it as `self` by pointer)".to_string()
    } else {
        "a local struct (or by-value parameter) whose method was called by a closure that captured it as `self` by pointer".to_string()
    }
}

/// If `expr`'s value is (or is a struct-typed projection of) a frame-local
/// struct, returns that binding's name. See
/// [`Checker::check_frame_escapes`] for why only `Ty::Named` values are
/// tracked -- scalars, Vec/Mat, and `GenRef` are plain data and can never
/// dangle past their `frame:` scope.
fn frame_escape_source(expr: &TypedExpr, frame_locals: &HashSet<String>, local_structs: &HashSet<String>) -> Option<String> {
    match expr {
        TypedExpr::Ident { name, ty, .. } => {
            if matches!(ty, Ty::Named(_)) && frame_locals.contains(name) {
                Some(name.clone())
            } else {
                None
            }
        }
        TypedExpr::Field { base, ty, .. } => {
            if matches!(ty, Ty::Named(_)) { frame_escape_source(base, frame_locals, local_structs) } else { None }
        }
        // Same reasoning as `Field` above: a tuple element read is just a
        // positional projection of `base`'s own storage (an anonymous
        // struct-shaped aggregate, laid out inline exactly like a nominal
        // struct's fields), so a `Ty::Named`-typed element still needs to
        // chain back through `base` to find out whether it ultimately
        // reaches frame-owned storage. Uses `root_ident` (an *ungated*
        // structural walk), not a recursive `frame_escape_source(base, ..)`
        // call: `base`'s own type here is `Ty::Tuple`, never `Ty::Named`, so
        // dispatching back through this function would hit the `Ident` arm's
        // `matches!(ty, Ty::Named(_))` gate on `base` itself and always fail
        // it -- even though *this* `TupleIndex` expression's own type (just
        // confirmed above) is exactly the `Ty::Named` this whole check cares
        // about. Previously, a `frame:`-scoped tuple's struct-typed element
        // (`frame: let pair: (Point, Point) = (..); pair.0.<escapes>`) was
        // silently never recognized as reaching frame-owned storage at all.
        TypedExpr::TupleIndex { base, ty, .. } => {
            if matches!(ty, Ty::Named(_)) {
                match root_ident(base) {
                    Some(root) if frame_locals.contains(&root) => Some(root),
                    _ => None,
                }
            } else {
                None
            }
        }
        // Same reasoning as `TupleIndex` above: an array element read is a
        // positional projection of `base`'s own inline storage, and `base`'s
        // own type (`Ty::Array`) is never itself `Ty::Named` either.
        TypedExpr::ArrayIndex { base, ty, .. } => {
            if matches!(ty, Ty::Named(_)) {
                match root_ident(base) {
                    Some(root) if frame_locals.contains(&root) => Some(root),
                    _ => None,
                }
            } else {
                None
            }
        }
        // Same reasoning as `ArrayIndex` above: a `Ring<T,N>` is stored
        // inline (see `Ty::Ring`'s doc comment), so `ring[idx]` is a
        // positional projection of `base`'s own storage exactly like an
        // array element, not a copy handed out of an independently
        // heap-allocated buffer (contrast `ListIndex`, bucketed below with
        // `ListMethod` as untracked for exactly that reason).
        TypedExpr::RingIndex { base, ty, .. } => {
            if matches!(ty, Ty::Named(_)) {
                match root_ident(base) {
                    Some(root) if frame_locals.contains(&root) => Some(root),
                    _ => None,
                }
            } else {
                None
            }
        }
        TypedExpr::StructLit { args, ty, .. } => {
            if matches!(ty, Ty::Named(_)) {
                args.iter().find_map(|a| frame_escape_source(a, frame_locals, local_structs))
            } else {
                None
            }
        }
        TypedExpr::If { then_block, else_block, ty, .. } => {
            if matches!(ty, Ty::Named(_)) {
                frame_escape_source_block(then_block, frame_locals, local_structs)
                    .or_else(|| else_block.as_ref().and_then(|b| frame_escape_source_block(b, frame_locals, local_structs)))
            } else {
                None
            }
        }
        TypedExpr::Match { arms, ty, .. } => {
            if matches!(ty, Ty::Named(_)) {
                arms.iter().find_map(|arm| frame_escape_source_block(&arm.body, frame_locals, local_structs))
            } else {
                None
            }
        }
        // A call only borrows its arguments for the duration of that
        // synchronous invocation (and the callee's own body is checked
        // independently against leaking its own frame-locals back out) --
        // *except* when the call is a method call on a receiver whose
        // storage is scoped to this function (a `frame:`-scoped local, an
        // ordinary local, or a by-value parameter -- `local_structs`
        // covers all three) and returns a closure:
        // `Codegen::captured_value_llvm_ty` documents that a closure
        // captures its `self` receiver *by pointer*, not by value (every
        // other capture is a genuine value copy, safe by the same
        // reasoning as the closure-literal case below). That pointer is
        // smuggled straight past this analysis and out through the call's
        // return value -- undetected, since a plain `Call` was previously
        // never inspected at all. Conservatively (and soundly) treat any
        // such call as carrying the receiver's identity onward, checking
        // it against the *broader* `local_structs` set (not just
        // `frame_locals`) since `Codegen::emit_place` never hands out a
        // receiver pointer with a verified longer lifetime for any of
        // them -- see `rejects_closure_capturing_frame_local_self_*` and
        // `rejects_closure_capturing_plain_local_self_*` in
        // `tests/frontend.rs` for the concrete repros this closes.
        TypedExpr::Call { callee, ty, .. } => {
            if matches!(ty, Ty::Closure(..)) {
                if let TypedExpr::Field { base, .. } = callee.as_ref() {
                    if let Some(name) = frame_escape_source(base, frame_locals, local_structs) {
                        return Some(name);
                    }
                    return local_struct_receiver(base, local_structs);
                }
            }
            None
        }
        // `GenRef` creation/dereference is plain index+generation data
        // backed by the arena's own (non-frame) storage; everything else is
        // a scalar. None of these can carry frame identity onward.
        // A closure literal captures every visible local *by value* (a
        // snapshot copied into its own heap-allocated environment, not a
        // reference into this stack frame -- see
        // `Codegen::emit_closure_lit`), so it can never carry a frame-local
        // struct's identity onward regardless of what it captured -- *this*
        // function's own `self` is never itself tracked (only a `let`/
        // by-value parameter is, and `self` is neither -- see this module's
        // doc comment), so a closure literal appearing directly in this
        // body is not a risk on its own; the risk is specifically a *call*
        // reaching into another function's body where `self` gets captured,
        // handled by the `TypedExpr::Call` arm above.
        //
        // A `List<T>` (`ListNew`/`ListLit`/`ListIndex`/`ListMethod`) stores
        // its elements by value into its own independently `malloc`'d
        // buffer (see `crate::codegen::list`), not by reference into this
        // stack frame -- pushing a frame-local struct into a list copies it,
        // the same reasoning that makes a closure's captures safe above.
        TypedExpr::GenRefCreate { .. }
        | TypedExpr::GenRefIndex { .. }
        | TypedExpr::Binary { .. }
        | TypedExpr::Unary { .. }
        | TypedExpr::Int(..)
        | TypedExpr::Float(..)
        | TypedExpr::Str(..)
        | TypedExpr::Bool(..)
        | TypedExpr::Char(..)
        // A cast's target is always a numeric/`char` type, never `Ty::Named`
        // -- so like the scalar literals above, it can never carry a
        // frame-local struct's identity onward.
        | TypedExpr::Cast { .. }
        // Both lower to a plain scalar (see their own `Ty` doc comments) --
        // can never carry a frame-local struct's identity onward, same
        // reasoning as `Cast` just above.
        | TypedExpr::WrappingNew { .. }
        | TypedExpr::FixedNew { .. }
        | TypedExpr::BitFieldNew { .. }
        | TypedExpr::FlagsNew { .. }
        | TypedExpr::FStr(..)
        | TypedExpr::SelfExpr(..)
        | TypedExpr::EnumVariant { .. }
        | TypedExpr::Closure { .. }
        | TypedExpr::ListNew { .. }
        | TypedExpr::ListLit { .. }
        | TypedExpr::ListIndex { .. }
        | TypedExpr::ListMethod { .. }
        // `Ring<T,N>`'s `push`/`pop` (unlike `RingIndex` above) have no
        // dedicated `Codegen::emit_place` arm, so a method-call receiver
        // shaped like `ring.pop().make_closure()` resolves through
        // `emit_place`'s generic fallback -- a fresh, disconnected alloca
        // holding a copy of the popped value -- severing any connection to
        // `ring`'s own (possibly frame-buffer-backed) storage, exactly like
        // `ListMethod` above. `RingNew` constructs a fresh, empty ring with
        // no frame-local identity to carry forward, same as `ListNew`.
        | TypedExpr::RingNew { .. }
        | TypedExpr::RingMethod { .. }
        // `Map<K,V>`/`Set<T>` store keys/values by value into their own
        // independently `malloc`'d buffers (see `crate::codegen::map`/
        // `crate::codegen::set`), same reasoning as `List` above.
        | TypedExpr::MapNew { .. }
        | TypedExpr::SetNew { .. }
        | TypedExpr::MapMethod { .. }
        | TypedExpr::SetMethod { .. }
        // `Table<T>` stores its elements by value, decomposed across its own
        // independently `malloc`'d column buffers (see `crate::codegen::table`),
        // same reasoning as `List`/`Map`/`Set` above -- pushing a frame-local
        // struct into a table copies its fields out, it doesn't reference
        // this stack frame. `TableIndex` reassembles a fresh copy from those
        // columns on every read, same as `ListIndex` above.
        | TypedExpr::TableNew { .. }
        | TypedExpr::TableMethod { .. }
        | TypedExpr::TableIndex { .. }
        // A `str` byte read (`s[i]`) yields a plain `i32`, never a
        // frame-local struct's identity -- same reasoning as `ListIndex`
        // just above.
        | TypedExpr::StrIndex { .. }
        // A tuple literal's own type is always `Ty::Tuple`, never
        // `Ty::Named` -- and since a tuple has no user-declared methods at
        // all, it can never itself be a call receiver, so (unlike
        // `StructLit`) there's no need to search its elements here; any
        // `Ty::Named` element that matters is reached individually through
        // `TupleIndex` above instead.
        | TypedExpr::TupleLit { .. }
        // Same reasoning as `TupleLit` above: an array's own type is always
        // `Ty::Array`, never `Ty::Named`, and has no user-declared methods
        // either. `ArrayLen`'s result is always `Ty::Int`, irrelevant here
        // regardless of what its `base` is.
        | TypedExpr::ArrayRepeat { .. }
        | TypedExpr::ArrayLen { .. }
        // `TypedExpr::Spawn`'s own result is always `Ty::Int` (the raw slot
        // index, or `-1` on drop -- see its doc comment), never `Ty::Named`,
        // so it can never itself carry a frame-local struct's identity
        // onward. Its constructor args are a separate concern, checked
        // directly in `walk_frame_stmt`'s `TypedStmt::Let` arm (mirroring
        // the existing `TypedStmt::Spawn` statement-form check just below)
        // rather than here.
        | TypedExpr::Spawn { .. }
        | TypedExpr::Error(_) => None,
    }
}

/// Whether `expr` is a struct value backed by *this function's own* stack
/// storage -- a `let`-bound local or a by-value parameter, tracked in
/// `local_structs` -- as opposed to something with an independently
/// verified longer lifetime. Used only by `frame_escape_source`'s
/// `TypedExpr::Call` arm to decide whether a method call's receiver might
/// be smuggling a dangling `self` pointer past this function's own return.
/// Deliberately narrower than `frame_escape_source` itself: a receiver
/// that isn't a bare local or field projection of one (a `GenRef`
/// dereference, a list index, another call's result) is spilled by
/// `Codegen::emit_place` into a *fresh* alloca of its own -- also
/// function-scoped and therefore also unsafe, but it has no `let`/param
/// name to report, so `frame_escape_source`'s own recursion into that
/// receiver already falls through its "None of these can carry identity
/// onward" arms and simply isn't flagged here (a pre-existing gap in what
/// this analysis can name, not a new one this fix introduces).
fn local_struct_receiver(expr: &TypedExpr, local_structs: &HashSet<String>) -> Option<String> {
    match expr {
        TypedExpr::Ident { name, ty, .. } => {
            if matches!(ty, Ty::Named(_)) && local_structs.contains(name) { Some(name.clone()) } else { None }
        }
        TypedExpr::Field { base, ty, .. } => {
            if matches!(ty, Ty::Named(_)) { local_struct_receiver(base, local_structs) } else { None }
        }
        // Same reasoning as `Field` above, and mirroring
        // `frame_escape_source`'s own `TupleIndex`/`ArrayIndex` arms: a
        // tuple/array element read is just a positional projection of
        // `base`'s own inline storage, so a `Ty::Named`-typed element
        // (`pair.0`, `points[0]`) still needs to chain back through `base`
        // to find out whether it's ultimately backed by a `local_structs`
        // binding. Previously missing here (this function's `_ => None`
        // fallback silently swallowed both), a plain local (non-`frame:`)
        // tuple/array's struct-typed element used as a method-call receiver
        // that returns a closure went undetected: `let pair: (Point, Point)
        // = (..)` then `pair.0.make_closure()`, where `make_closure` returns
        // a closure capturing `self` by pointer, escaped this check entirely.
        //
        // Uses `root_ident` (an *ungated* structural walk) rather than
        // recursing back through `local_struct_receiver` itself: `base`'s
        // own type here is `Ty::Tuple`/`Ty::Array`, never `Ty::Named`, so a
        // recursive call would hit this function's own `Ident` arm's
        // `matches!(ty, Ty::Named(_))` gate on `base` and always fail it --
        // even though this `TupleIndex`/`ArrayIndex` expression's own type
        // (just confirmed above) is exactly the `Ty::Named` this check cares
        // about. A first attempt at this fix added these two arms but kept
        // the recursive-`local_struct_receiver` call, which silently
        // continued to miss every tuple/array case for exactly this reason.
        TypedExpr::TupleIndex { base, ty, .. } => {
            if matches!(ty, Ty::Named(_)) {
                match root_ident(base) {
                    Some(root) if local_structs.contains(&root) => Some(root),
                    _ => None,
                }
            } else {
                None
            }
        }
        TypedExpr::ArrayIndex { base, ty, .. } => {
            if matches!(ty, Ty::Named(_)) {
                match root_ident(base) {
                    Some(root) if local_structs.contains(&root) => Some(root),
                    _ => None,
                }
            } else {
                None
            }
        }
        // Same reasoning as `ArrayIndex` above -- see `frame_escape_source`'s
        // matching `RingIndex` arm.
        TypedExpr::RingIndex { base, ty, .. } => {
            if matches!(ty, Ty::Named(_)) {
                match root_ident(base) {
                    Some(root) if local_structs.contains(&root) => Some(root),
                    _ => None,
                }
            } else {
                None
            }
        }
        // A method/function call's own return value, if it's a `Ty::Named`
        // struct, is *always* spilled by `Codegen::emit_place` into a fresh,
        // function-scoped alloca -- there is no other storage for a bare
        // call-expression result to live in (see this module's own
        // `TypedExpr::Call` doc comment above). So using it as a further
        // method-call receiver that itself returns a closure
        // (`Holder(777).identity().get_closure()`, where `identity()`
        // returns `Holder` by value and `get_closure()` captures *that*
        // `self` by pointer) is exactly as unsafe as using a named local or
        // by-value parameter -- just with no `let`/param name to attribute
        // the escape to, since it's an anonymous temporary. This was
        // previously the one receiver shape this function's `_ => None`
        // catch-all silently let through (see this function's own doc
        // comment on why -- `frame_escape_source`'s recursion into it always
        // falls through as well, since a struct-returning call's own type
        // is never `Ty::Closure`).
        TypedExpr::Call { ty, .. } if matches!(ty, Ty::Named(_)) => Some(ANONYMOUS_CALL_RESULT.to_string()),
        // An `if`/`match` used in value position is, like a call's return
        // value just above, spilled by `Codegen::emit_place` into a fresh,
        // function-scoped alloca -- there's no other storage for a
        // multi-branch expression's result to live in. Previously missing
        // here (falling through to `_ => None` below), a method call on such
        // a receiver built from plain (non-`frame:`) locals escaped
        // undetected: `return (if cond: a else: b).get_closure()` where
        // `get_closure` captures `self` by pointer. Mirrors
        // `frame_escape_source`'s own `If`/`Match` arms (which already
        // catch the `frame:`-scoped-local case via `frame_locals`) --
        // conservatively flagging the *whole* expression if *any* branch
        // resolves to a local struct, since `emit_place`'s spill can't tell
        // at runtime which branch actually ran.
        TypedExpr::If { then_block, else_block, ty, .. } => {
            if matches!(ty, Ty::Named(_)) {
                local_struct_receiver_block(then_block, local_structs)
                    .or_else(|| else_block.as_ref().and_then(|b| local_struct_receiver_block(b, local_structs)))
            } else {
                None
            }
        }
        TypedExpr::Match { arms, ty, .. } => {
            if matches!(ty, Ty::Named(_)) {
                arms.iter().find_map(|arm| local_struct_receiver_block(&arm.body, local_structs))
            } else {
                None
            }
        }
        _ => None,
    }
}

/// The `local_struct_receiver` source of a block used in value position (an
/// `if`/`match` arm) -- same "only the trailing expression contributes a
/// value" shape as `frame_escape_source_block`, generalized from
/// `frame_locals` to the broader `local_structs` set.
fn local_struct_receiver_block(block: &TypedBlock, local_structs: &HashSet<String>) -> Option<String> {
    match block.stmts.last() {
        Some(TypedStmt::Expr(e)) => local_struct_receiver(e, local_structs),
        Some(TypedStmt::Frame { body, .. }) => {
            let mut ls = local_structs.clone();
            for stmt in &body.stmts {
                if let TypedStmt::Let { name, ty, .. } = stmt {
                    if matches!(ty, Ty::Named(_)) {
                        ls.insert(name.clone());
                    }
                }
            }
            local_struct_receiver_block(body, &ls)
        }
        _ => None,
    }
}

/// Sentinel "name" `local_struct_receiver` reports for a receiver that's a
/// call's return value rather than a real `let`/param binding -- there's no
/// source identifier to point at, but the escape is exactly as real. See
/// `escape_reason`'s matching special case, which phrases the diagnostic
/// around this sentinel instead of treating it as a literal variable name.
const ANONYMOUS_CALL_RESULT: &str = "this method call's result";

/// The frame-escape source of a block used in value position (an `if`/
/// `match` arm): only its trailing expression contributes a value, mirroring
/// `Codegen::emit_stmts_value`.
fn frame_escape_source_block(block: &TypedBlock, frame_locals: &HashSet<String>, local_structs: &HashSet<String>) -> Option<String> {
    match block.stmts.last() {
        Some(TypedStmt::Expr(e)) => frame_escape_source(e, frame_locals, local_structs),
        // A trailing `frame:` block's own value falls out of that scope the
        // same way a direct, function-body-level trailing `frame:` block
        // does (see `walk_frame_stmt`'s own `TypedStmt::Frame` arm) --
        // `Codegen::emit_stmts_value` treats a trailing `TypedStmt::Frame`
        // exactly like a trailing `TypedStmt::Expr`, propagating its value
        // out through the `if`/`match` arm containing it. Without this arm,
        // `return if cond:\n    frame:\n        let p = Point(1, 2)\n        p\nelse:\n    ...`
        // silently skipped this whole check, since this lookahead only ever
        // recognized a bare trailing expression. Every `Ty::Named` local the
        // frame body itself `let`-binds is folded into the set checked
        // against, mirroring what `walk_frame_stmt`'s stateful walker would
        // have registered had it actually descended into this frame body
        // (which it never does -- this helper only exists for the
        // value-producing `if`/`match`-arm lookahead `frame_escape_source`
        // needs, a separate path from the statement-level walk).
        Some(TypedStmt::Frame { body, .. }) => {
            let mut l = frame_locals.clone();
            let mut ls = local_structs.clone();
            for stmt in &body.stmts {
                if let TypedStmt::Let { name, ty, .. } = stmt {
                    if matches!(ty, Ty::Named(_)) {
                        ls.insert(name.clone());
                    }
                    l.insert(name.clone());
                }
            }
            frame_escape_source_block(body, &l, &ls)
        }
        _ => None,
    }
}
