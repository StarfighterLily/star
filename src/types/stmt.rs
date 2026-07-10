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
                let actual_ty: Ty = ty.as_ref().and_then(|t| self.resolve_type(t))
                    .unwrap_or_else(|| value_typed.clone().into_ty());
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
                TypedStmt::Assign { target: target_typed, op: *op, value: value_typed, span: *span }
            }
            Stmt::Return { value, span } => {
                let value_typed = value.as_ref().map(|v| self.infer_expr(v, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into()))));
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
                let then_typed = self.check_block_inner(body, &mut vars.clone());
                let else_typed = else_block.as_ref().map(|b| self.check_block_inner(b, &mut vars.clone()));
                TypedStmt::While { cond: cond_typed, then_block: then_typed, else_block: else_typed, span: *span }
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
                let body_typed = self.check_block_inner(body, &mut inner_vars);
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
