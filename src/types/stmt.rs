//! Statement type-checking.

use std::collections::{HashMap, HashSet};

use crate::ast::*;
use crate::diagnostics::Span;

use super::*;

impl Checker {
    pub(super) fn check_stmt(&mut self, stmt: &Stmt, vars: &mut HashMap<String, Ty>) -> Option<TypedStmt> {
        Some(match stmt {
            Stmt::Let { is_mut, name, ty, value, span } => {
                let value_typed = self.infer_expr(value, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                let annotated_ty = ty.as_ref().and_then(|t| self.resolve_type(t));
                // §1.1: the annotation, if present, was previously resolved
                // and used as the variable's tracked type with *no*
                // comparison against the value's actual inferred type at
                // all -- a mistyped `let a: Foo = 42` type-checked cleanly
                // and only surfaced as a broken `load %Foo, %Foo* %t0`
                // (really an `i32` alloca) at codegen, or as a runtime
                // segfault if it reached a compiled binary at all.
                if let Some(declared) = &annotated_ty {
                    let actual = value_typed.clone().into_ty();
                    if !Self::types_compatible(declared, &actual) {
                        self.error(
                            format!("`let {}: {:?}` but the value has type `{:?}`", name, declared, actual),
                            *span,
                        );
                    }
                }
                let actual_ty: Ty = annotated_ty.unwrap_or_else(|| value_typed.clone().into_ty());
                vars.insert(name.clone(), actual_ty.clone());
                TypedStmt::Let { is_mut: *is_mut, name: name.clone(), ty: actual_ty, value: value_typed, span: *span }
            }
            Stmt::Assign { target, op, value, span } => {
                let target_typed = self.infer_expr(target, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                let value_typed = self.infer_expr(value, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                if let TypedExpr::Field { base, field, .. } = &target_typed {
                    if base.clone().into_ty().is_vec() {
                        let mut seen = HashSet::new();
                        for c in field.chars() {
                            if !seen.insert(c) {
                                self.error(format!("duplicate swizzle component `{}` in write target `.{}`", c, field), *span);
                                break;
                            }
                        }
                    }
                }
                // §1.2: assignments were never type-checked at all -- only
                // the swizzle-specific duplicate-component check above
                // existed in this arm. `x += y`/`x -= y`/etc. are held to
                // the same standard as plain `=`: this compiler has no
                // numeric-widening assignment coercions (e.g. assigning an
                // `i32` into an `f32` binding), matching `infer_binop_ty`'s
                // own strictness for vector arithmetic.
                let target_ty = target_typed.clone().into_ty();
                let value_ty = value_typed.clone().into_ty();
                if !Self::types_compatible(&target_ty, &value_ty) {
                    self.error(
                        format!("cannot assign a value of type `{:?}` to a target of type `{:?}`", value_ty, target_ty),
                        *span,
                    );
                }
                TypedStmt::Assign { target: target_typed, op: *op, value: value_typed, span: *span }
            }
            Stmt::Return { value, span } => {
                let value_typed = value.as_ref().map(|v| self.infer_expr(v, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into()))));
                if let Some(expected) = self.current_ret_ty.clone() {
                    match (&value_typed, &expected) {
                        (Some(v), Some(expected_ty)) => {
                            let actual = v.clone().into_ty();
                            if !Self::types_compatible(expected_ty, &actual) {
                                self.error(
                                    format!("expected return type `{:?}`, found `{:?}`", expected_ty, actual),
                                    *span,
                                );
                            }
                        }
                        (Some(v), None) => {
                            let actual = v.clone().into_ty();
                            self.error(
                                format!("this function has no declared return type, but `return` provides a value of type `{:?}`", actual),
                                *span,
                            );
                        }
                        (None, Some(expected_ty)) => {
                            self.error(
                                format!("expected a return value of type `{:?}`, found bare `return`", expected_ty),
                                *span,
                            );
                        }
                        (None, None) => {}
                    }
                }
                TypedStmt::Return { value: value_typed, span: *span }
            }
            Stmt::Expr(expr) => TypedStmt::Expr(self.infer_expr(expr, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))),
            Stmt::If { cond, then_block, else_block, span } => {
                let cond_typed = self.infer_expr(cond, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                if !matches!(cond_typed.clone().into_ty(), Ty::Bool) {
                    self.error("if condition must be of type bool", cond.span());
                }
                let then_typed = self.check_block_inner(then_block, &mut vars.clone());
                let else_typed = else_block.as_ref().map(|b| self.check_block_inner(b, &mut vars.clone()));
                TypedStmt::If { cond: cond_typed, then_block: then_typed, else_block: else_typed, span: *span }
            }
            Stmt::While { cond, body, else_block, span } => {
                let cond_typed = self.infer_expr(cond, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                if !matches!(cond_typed.clone().into_ty(), Ty::Bool) {
                    self.error("while condition must be of type bool", cond.span());
                }
                self.loop_depth += 1;
                let then_typed = self.check_block_inner(body, &mut vars.clone());
                self.loop_depth -= 1;
                // The `else:` clause runs once after the loop exits normally;
                // it is not itself loop body, so `break`/`continue` inside it
                // still refer to any *enclosing* loop, not this one.
                let else_typed = else_block.as_ref().map(|b| self.check_block_inner(b, &mut vars.clone()));
                TypedStmt::While { cond: cond_typed, then_block: then_typed, else_block: else_typed, span: *span }
            }
            Stmt::For { var, start, end, body, span } => {
                let start_typed = self.infer_expr(start, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                let end_typed = self.infer_expr(end, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                if !matches!(start_typed.clone().into_ty(), Ty::Int) {
                    self.error("`for` range start must be of type `i32`", start.span());
                }
                if !matches!(end_typed.clone().into_ty(), Ty::Int) {
                    self.error("`for` range end must be of type `i32`", end.span());
                }
                let mut inner_vars = vars.clone();
                inner_vars.insert(var.clone(), Ty::Int);
                self.loop_depth += 1;
                let body_typed = self.check_block_inner(body, &mut inner_vars);
                self.loop_depth -= 1;
                TypedStmt::For { var: var.clone(), start: start_typed, end: end_typed, body: body_typed, span: *span }
            }
            Stmt::Break { span } => {
                if self.loop_depth == 0 {
                    self.error("`break` outside of a loop", *span);
                }
                TypedStmt::Break { span: *span }
            }
            Stmt::Continue { span } => {
                if self.loop_depth == 0 {
                    self.error("`continue` outside of a loop", *span);
                }
                TypedStmt::Continue { span: *span }
            }
            Stmt::Frame { body, span } => {
                let body_typed = self.check_block_inner(body, &mut vars.clone());
                TypedStmt::Frame { body: body_typed, span: *span }
            }
            Stmt::Par { var, arena, body, span } => {
                let elem_ty = match self.arenas.get(arena) {
                    Some(t) => t.clone(),
                    None => {
                        self.error(format!("undefined arena `{}`", arena), *span);
                        Ty::Named("unknown".into())
                    }
                };
                let mut inner_vars = vars.clone();
                inner_vars.insert(var.clone(), elem_ty.clone());
                // A `par`/`swarm` body dispatches across worker threads, so
                // `break`/`continue` have no well-defined target even if this
                // statement is lexically nested inside an outer loop; hide
                // any outer loop depth for the duration of this body.
                let saved_loop_depth = self.loop_depth;
                self.loop_depth = 0;
                let body_typed = self.check_block_inner(body, &mut inner_vars);
                self.loop_depth = saved_loop_depth;
                self.check_par_disjoint(var, &body_typed);
                TypedStmt::Par { var: var.clone(), elem_ty, arena: arena.clone(), body: body_typed, span: *span }
            }
            // Every `yield` inside a `sequence` body is consumed by the
            // desugaring pass in `check()` before this point; one reaching
            // here means it was written outside a `sequence`.
            Stmt::Yield { span } => {
                self.error("`yield` is only valid at the top level of a `sequence` body", *span);
                TypedStmt::Expr(TypedExpr::Error(Ty::Named("void".into())))
            }
            Stmt::Spawn { arena, args, span } => self.check_spawn_stmt(arena, args, vars, *span),
            Stmt::Despawn { arena, index, span } => self.check_despawn_stmt(arena, index, vars, *span),
        })
    }

    /// Type-check `spawn ArenaName(args...)`: resolves the arena's declared
    /// element type, checks it's a struct (the only kind of value an arena
    /// can hold), validates the argument count against the struct's field
    /// list, and packages the constructed element as a `StructLit` so
    /// codegen only has to append it to the arena's backing array.
    fn check_spawn_stmt(&mut self, arena: &str, args: &[Expr], vars: &mut HashMap<String, Ty>, span: Span) -> TypedStmt {
        let elem_ty = match self.arenas.get(arena) {
            Some(t) => t.clone(),
            None => {
                self.error(format!("undefined arena `{}`", arena), span);
                Ty::Named("unknown".into())
            }
        };
        let elem_name = match &elem_ty {
            Ty::Named(n) => n.clone(),
            other => {
                self.error(format!("`spawn` requires an arena of a struct type, but `{}` holds `{:?}`", arena, other), span);
                "unknown".into()
            }
        };
        let arg_exprs: Vec<TypedExpr> = args
            .iter()
            .map(|a| self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into()))))
            .collect();
        if let Some(sdef) = self.structs.get(&elem_name).cloned() {
            if arg_exprs.len() != sdef.fields.len() {
                self.error(
                    format!(
                        "`spawn {}(..)` expects {} argument(s) for `{}`, found {}",
                        arena, sdef.fields.len(), elem_name, arg_exprs.len()
                    ),
                    span,
                );
            }
        } else if elem_name != "unknown" {
            self.error(format!("arena `{}` element type `{}` is not a struct", arena, elem_name), span);
        }
        let elem = TypedExpr::StructLit { name: elem_name, args: arg_exprs, ty: elem_ty, span };
        TypedStmt::Spawn { arena: arena.to_string(), elem, span }
    }

    /// Type-check `despawn ArenaName[index]`: resolves the arena (an error if
    /// undefined) and requires `index` to be an `i32`. No arity/struct
    /// checking needed -- unlike `spawn`, `despawn` doesn't construct a
    /// value, it just bumps a generation counter.
    fn check_despawn_stmt(&mut self, arena: &str, index: &Expr, vars: &mut HashMap<String, Ty>, span: Span) -> TypedStmt {
        if !self.arenas.contains_key(arena) {
            self.error(format!("undefined arena `{}`", arena), span);
        }
        let index_typed = self.infer_expr(index, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
        if !matches!(index_typed.clone().into_ty(), Ty::Int) {
            self.error("`despawn` index must be `i32`", span);
        }
        TypedStmt::Despawn { arena: arena.to_string(), index: index_typed, span }
    }
}
