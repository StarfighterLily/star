//! `frame:` escape analysis.
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
//! `spawn`-ing one into a (necessarily longer-lived) arena.

use std::collections::HashSet;

use super::*;

impl Checker {
    pub(super) fn check_frame_escapes(&mut self, body: &TypedBlock) {
        let mut frame_locals = HashSet::new();
        self.walk_frame_stmts(&body.stmts, &mut frame_locals, false, true);
    }

    fn walk_frame_stmts(&mut self, stmts: &[TypedStmt], frame_locals: &mut HashSet<String>, in_frame: bool, tail: bool) {
        let last = stmts.len().saturating_sub(1);
        for (i, stmt) in stmts.iter().enumerate() {
            self.walk_frame_stmt(stmt, frame_locals, in_frame, tail && i == last);
        }
    }

    fn walk_frame_stmt(&mut self, stmt: &TypedStmt, frame_locals: &mut HashSet<String>, in_frame: bool, tail: bool) {
        match stmt {
            TypedStmt::Let { name, .. } => {
                if in_frame {
                    frame_locals.insert(name.clone());
                }
            }
            TypedStmt::Assign { target, value, span, .. } => {
                if let Some(name) = frame_escape_source(value, frame_locals) {
                    let escapes = match root_ident(target) {
                        Some(root) => !frame_locals.contains(&root),
                        None => true,
                    };
                    if escapes {
                        self.error(
                            format!(
                                "`{}` is a struct allocated inside a `frame:` scope; its memory is reclaimed when that scope ends, so it cannot be assigned outside it",
                                name
                            ),
                            *span,
                        );
                    }
                }
            }
            TypedStmt::Return { value, span } => {
                if let Some(v) = value {
                    if let Some(name) = frame_escape_source(v, frame_locals) {
                        self.error(
                            format!(
                                "cannot return `{}`: it is a struct allocated inside a `frame:` scope and does not outlive the current tick",
                                name
                            ),
                            *span,
                        );
                    }
                }
            }
            TypedStmt::Expr(e) => {
                if tail {
                    if let Some(name) = frame_escape_source(e, frame_locals) {
                        self.error(
                            format!(
                                "cannot use `{}` as this function's value: it is a struct allocated inside a `frame:` scope and does not outlive the current tick",
                                name
                            ),
                            e.span(),
                        );
                    }
                }
            }
            TypedStmt::If { then_block, else_block, .. } => {
                let mut l = frame_locals.clone();
                self.walk_frame_stmts(&then_block.stmts, &mut l, in_frame, false);
                if let Some(e) = else_block {
                    let mut l = frame_locals.clone();
                    self.walk_frame_stmts(&e.stmts, &mut l, in_frame, false);
                }
            }
            TypedStmt::While { then_block, else_block, .. } => {
                let mut l = frame_locals.clone();
                self.walk_frame_stmts(&then_block.stmts, &mut l, in_frame, false);
                if let Some(e) = else_block {
                    let mut l = frame_locals.clone();
                    self.walk_frame_stmts(&e.stmts, &mut l, in_frame, false);
                }
            }
            TypedStmt::For { body, .. } => {
                let mut l = frame_locals.clone();
                self.walk_frame_stmts(&body.stmts, &mut l, in_frame, false);
            }
            TypedStmt::Break { .. } | TypedStmt::Continue { .. } => {}
            TypedStmt::Frame { body, .. } => {
                let mut l = frame_locals.clone();
                self.walk_frame_stmts(&body.stmts, &mut l, true, tail);
            }
            TypedStmt::Par { body, .. } => {
                let mut l = frame_locals.clone();
                self.walk_frame_stmts(&body.stmts, &mut l, in_frame, false);
            }
            TypedStmt::Spawn { elem, span, .. } => {
                if let Some(name) = frame_escape_source(elem, frame_locals) {
                    self.error(
                        format!(
                            "cannot `spawn` using `{}`: it is a struct allocated inside a `frame:` scope and does not outlive the arena",
                            name
                        ),
                        *span,
                    );
                }
            }
            TypedStmt::Despawn { .. } => {}
        }
    }
}

/// If `expr`'s value is (or is a struct-typed projection of) a frame-local
/// struct, returns that binding's name. See
/// [`Checker::check_frame_escapes`] for why only `Ty::Named` values are
/// tracked -- scalars, Vec/Mat, and `GenRef` are plain data and can never
/// dangle past their `frame:` scope.
fn frame_escape_source(expr: &TypedExpr, frame_locals: &HashSet<String>) -> Option<String> {
    match expr {
        TypedExpr::Ident { name, ty, .. } => {
            if matches!(ty, Ty::Named(_)) && frame_locals.contains(name) {
                Some(name.clone())
            } else {
                None
            }
        }
        TypedExpr::Field { base, ty, .. } => {
            if matches!(ty, Ty::Named(_)) { frame_escape_source(base, frame_locals) } else { None }
        }
        TypedExpr::StructLit { args, ty, .. } => {
            if matches!(ty, Ty::Named(_)) { args.iter().find_map(|a| frame_escape_source(a, frame_locals)) } else { None }
        }
        TypedExpr::If { then_block, else_block, ty, .. } => {
            if matches!(ty, Ty::Named(_)) {
                frame_escape_source_block(then_block, frame_locals)
                    .or_else(|| else_block.as_ref().and_then(|b| frame_escape_source_block(b, frame_locals)))
            } else {
                None
            }
        }
        TypedExpr::Match { arms, ty, .. } => {
            if matches!(ty, Ty::Named(_)) {
                arms.iter().find_map(|arm| frame_escape_source_block(&arm.body, frame_locals))
            } else {
                None
            }
        }
        // A call only borrows its arguments for the duration of that
        // synchronous invocation (and the callee's own body is checked
        // independently against leaking its own frame-locals back out);
        // `GenRef` creation/dereference is plain index+generation data
        // backed by the arena's own (non-frame) storage; everything else is
        // a scalar. None of these can carry frame identity onward.
        // A closure literal captures every visible local *by value* (a
        // snapshot copied into its own heap-allocated environment, not a
        // reference into this stack frame -- see
        // `Codegen::emit_closure_lit`), so it can never carry a frame-local
        // struct's identity onward regardless of what it captured.
        //
        // A `List<T>` (`ListNew`/`ListLit`/`ListIndex`/`ListMethod`) stores
        // its elements by value into its own independently `malloc`'d
        // buffer (see `crate::codegen::list`), not by reference into this
        // stack frame -- pushing a frame-local struct into a list copies it,
        // the same reasoning that makes a closure's captures safe above.
        TypedExpr::Call { .. }
        | TypedExpr::GenRefCreate { .. }
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

/// The frame-escape source of a block used in value position (an `if`/
/// `match` arm): only its trailing expression contributes a value, mirroring
/// `Codegen::emit_stmts_value`.
fn frame_escape_source_block(block: &TypedBlock, frame_locals: &HashSet<String>) -> Option<String> {
    match block.stmts.last() {
        Some(TypedStmt::Expr(e)) => frame_escape_source(e, frame_locals),
        _ => None,
    }
}
