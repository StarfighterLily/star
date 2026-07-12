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
            TypedStmt::Let { name, ty, .. } => {
                if matches!(ty, Ty::Named(_)) {
                    local_structs.insert(name.clone());
                }
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
    if frame_locals.contains(name) {
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
        | TypedExpr::FStr(..)
        | TypedExpr::SelfExpr(..)
        | TypedExpr::EnumVariant { .. }
        | TypedExpr::Closure { .. }
        | TypedExpr::ListNew { .. }
        | TypedExpr::ListLit { .. }
        | TypedExpr::ListIndex { .. }
        | TypedExpr::ListMethod { .. }
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
        _ => None,
    }
}

/// The frame-escape source of a block used in value position (an `if`/
/// `match` arm): only its trailing expression contributes a value, mirroring
/// `Codegen::emit_stmts_value`.
fn frame_escape_source_block(block: &TypedBlock, frame_locals: &HashSet<String>, local_structs: &HashSet<String>) -> Option<String> {
    match block.stmts.last() {
        Some(TypedStmt::Expr(e)) => frame_escape_source(e, frame_locals, local_structs),
        _ => None,
    }
}
