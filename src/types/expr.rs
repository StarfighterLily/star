//! Expression type inference.

use std::collections::HashMap;

use crate::ast::*;
use crate::diagnostics::{suggest, Span};

use super::*;

impl Checker {
    pub(super) fn check_expr_infer(&mut self, expr: &Expr) -> TypedExpr {
        let mut dummy_vars = HashMap::new();
        self.infer_expr(expr, &mut dummy_vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))
    }

    pub(super) fn infer_expr(&mut self, expr: &Expr, vars: &mut HashMap<String, Ty>) -> Result<TypedExpr, ()> {
        match expr {
            Expr::Int(v, s) => Ok(TypedExpr::Int(*v, Ty::Int, *s)),
            Expr::Float(v, s) => Ok(TypedExpr::Float(*v, Ty::Float, *s)),
            Expr::Str(s, sp) => Ok(TypedExpr::Str(s.clone(), Ty::Str, *sp)),
            Expr::Bool(v, s) => Ok(TypedExpr::Bool(*v, Ty::Bool, *s)),
            Expr::FStr(parts, s) => {
                let mut typed_parts = Vec::new();
                for part in parts {
                    match part {
                        FStrExpr::Literal(lit) => typed_parts.push(TypedFStrExpr::Literal(lit.clone())),
                        FStrExpr::Expr(e) => {
                            let typed = self.infer_expr(e, vars)?;
                            typed_parts.push(TypedFStrExpr::Expr(Box::new(typed)));
                        }
                    }
                }
                Ok(TypedExpr::FStr(typed_parts, Ty::Str, *s))
            }
            Expr::Ident(name, s) => {
                let ty = vars.get(name).cloned().unwrap_or(Ty::Named("unknown".into()));
                Ok(TypedExpr::Ident { name: name.clone(), ty, span: *s })
            }
            Expr::SelfExpr(s) => {
                let ty = vars.get("self").cloned().unwrap_or(Ty::Named("Self".into()));
                Ok(TypedExpr::SelfExpr(ty, *s))
            }
            Expr::Field { base, field, span } => {
                let base_expr = self.infer_expr(base, vars)?;
                let field_ty = self.resolve_field_type(&base_expr, field, *span);
                Ok(TypedExpr::Field { base: Box::new(base_expr), field: field.clone(), ty: field_ty, span: *span })
            }
            Expr::Call { callee, args, span } => {
                let callee_expr = self.infer_expr(callee, vars)?;
                let arg_exprs: Vec<TypedExpr> = args.iter().map(|a| self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))).collect();
                // Standard-library builtins (`print`/`println`, math, string
                // ops) aren't declared by any `fn` item, so they never show
                // up in `self.functions`; special-case their return types
                // here before falling back to the function table.
                if let TypedExpr::Ident { name, .. } = &callee_expr {
                    if let Some(ty) = builtin_return_ty(name, &arg_exprs) {
                        return Ok(TypedExpr::Call { callee: Box::new(callee_expr), args: arg_exprs, ty, span: *span });
                    }
                }
                // Look up the return type from the function table. Impl
                // methods share the same flat table as free functions
                // (keyed by name only), so a method call `obj.method()`
                // resolves exactly like a free-function call: through the
                // callee's name, whether that name came from an `Ident` or
                // (for methods) the field of a `Field` access.
                let ret_ty = match &callee_expr {
                    TypedExpr::Ident { name, .. } => {
                        self.functions.get(name)
                            .and_then(|(_, ret)| ret.clone())
                            .unwrap_or(Ty::Named("unknown".into()))
                    }
                    TypedExpr::Field { field, .. } => {
                        self.functions.get(field)
                            .and_then(|(_, ret)| ret.clone())
                            .unwrap_or(Ty::Named("unknown".into()))
                    }
                    _ => Ty::Named("unknown".into()),
                };
                Ok(TypedExpr::Call { callee: Box::new(callee_expr), args: arg_exprs, ty: ret_ty, span: *span })
            }
            Expr::Binary { op, lhs, rhs, span } => {
                let lhs_expr = self.infer_expr(lhs, vars)?;
                let rhs_expr = self.infer_expr(rhs, vars)?;
                let lhs_ty = lhs_expr.clone().into_ty();
                let rhs_ty = rhs_expr.clone().into_ty();
                let ty = self.infer_binop_ty(op, &lhs_ty, &rhs_ty, *span);
                Ok(TypedExpr::Binary { op: *op, lhs: Box::new(lhs_expr), rhs: Box::new(rhs_expr), ty, span: *span })
            }
            Expr::Unary { op, operand, span } => {
                let operand_expr = self.infer_expr(operand, vars)?;
                // `-x` preserves the operand's own numeric type (Int stays
                // Int, Float stays Float) rather than always widening to Int.
                let ty = match op {
                    UnOp::Neg => operand_expr.clone().into_ty(),
                    UnOp::Not => Ty::Bool,
                };
                Ok(TypedExpr::Unary { op: *op, operand: Box::new(operand_expr), ty, span: *span })
            }
            Expr::Match { scrutinee, arms, span } => {
                let scrutinee_expr = self.infer_expr(scrutinee, vars)?;
                let arm_tys: Vec<TypedMatchArm> = arms.iter().map(|a| self.check_match_arm(a, &scrutinee_expr, vars)).collect();
                let ty = arm_tys.first().map(|a| a.ty.clone()).unwrap_or(Ty::Named("unknown".into()));
                Ok(TypedExpr::Match { scrutinee: Box::new(scrutinee_expr), arms: arm_tys, ty, span: *span })
            }
            Expr::StructLit { name, args, span } => {
                let arg_exprs: Vec<TypedExpr> = args.iter().map(|a| self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))).collect();
                let resolved_ty = self.resolve_type(&Type::Named(name.clone())).unwrap_or_else(|| Ty::Named(name.clone()));
                self.check_builtin_ctor_arity(&resolved_ty, name, &arg_exprs, *span);
                Ok(TypedExpr::StructLit { name: name.clone(), args: arg_exprs, ty: resolved_ty, span: *span })
            }
            Expr::If { cond, then_block, else_block, span } => {
                let cond_typed = self.infer_expr(cond, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                if !matches!(cond_typed.clone().into_ty(), Ty::Bool) {
                    self.error("if condition must be of type bool", cond.span());
                }
                let then_typed = self.check_block_inner(then_block, &mut vars.clone());
                let else_typed = else_block.as_ref().map(|b| self.check_block_inner(b, &mut vars.clone()));
                let ty = then_typed.stmts.last()
                    .and_then(|s| if let TypedStmt::Expr(e) = s { Some(e.clone().into_ty()) } else { None })
                    .unwrap_or_else(|| Ty::Named("void".into()));
                Ok(TypedExpr::If {
                    cond: Box::new(cond_typed),
                    then_block: then_typed,
                    else_block: else_typed,
                    ty,
                    span: *span,
                })
            }
            Expr::GenRefCreate { inner_ty, value, span } => {
                let resolved_inner = self.resolve_type(inner_ty).unwrap_or(Ty::Named("unknown".into()));
                self.require_backing_arena(&resolved_inner, *span);
                let value_typed = self.infer_expr(value, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                if !matches!(value_typed.clone().into_ty(), Ty::Int) {
                    self.error("`GenRef<T>(..)` index must be `i32`", *span);
                }
                Ok(TypedExpr::GenRefCreate { inner_ty: resolved_inner, value: Box::new(value_typed), span: *span })
            }
            Expr::GenRefIndex { base, index, span } => {
                let base_expr = self.infer_expr(base, vars)?;
                let index_expr = self.infer_expr(index, vars)?;
                let inner_ty = match base_expr.clone().into_ty() {
                    Ty::GenRef(inner) => {
                        self.require_backing_arena(&inner, *span);
                        *inner
                    }
                    other => {
                        self.error(format!("`[..]` dereference requires a `GenRef<T>`, found `{:?}`", other), *span);
                        Ty::Named("unknown".into())
                    }
                };
                Ok(TypedExpr::GenRefIndex { base: Box::new(base_expr), index: Box::new(index_expr), ty: inner_ty, span: *span })
            }
        }
    }

    /// Validate constructor arity/argument types for the builtin vec/mat
    /// literal forms (`Vec2(x,y)`, `Vec3(x,y,z)`, `Vec4(x,y,z,w)`,
    /// `Mat4(row0,row1,row2,row3)`). No-op for user-defined structs (`Ty::Named`),
    /// which are not validated today either.
    fn check_builtin_ctor_arity(&mut self, ty: &Ty, name: &str, args: &[TypedExpr], span: Span) {
        let is_numeric = |t: &Ty| matches!(t, Ty::Int | Ty::Float);
        match ty {
            Ty::Vec2 | Ty::Vec3 | Ty::Vec4 => {
                let expected = ty.vec_arity().unwrap() as usize;
                if args.len() != expected
                    || !args.iter().all(|a| is_numeric(&a.clone().into_ty()))
                {
                    self.error(format!("{}(..) expects {} float arguments", name, expected), span);
                }
            }
            Ty::Mat4 => {
                if args.len() != 4 || !args.iter().all(|a| matches!(a.clone().into_ty(), Ty::Vec4)) {
                    self.error(format!("{}(..) expects 4 Vec4 row arguments", name), span);
                }
            }
            _ => {}
        }
    }

    /// Infer the result type of a binary operator, dispatching on whether
    /// either operand is a builtin vector/matrix type. Falls through to the
    /// original Int/Float/Bool behavior when both operands are scalar.
    fn infer_binop_ty(&mut self, op: &BinOp, lhs_ty: &Ty, rhs_ty: &Ty, span: Span) -> Ty {
        let is_cmp = matches!(op, BinOp::Eq | BinOp::Ne | BinOp::Lt | BinOp::Gt | BinOp::Le | BinOp::Ge);
        if !lhs_ty.is_vec() && !lhs_ty.is_mat() && !rhs_ty.is_vec() && !rhs_ty.is_mat() {
            // Original scalar behavior, preserved exactly.
            return if is_cmp {
                Ty::Bool
            } else {
                match (lhs_ty, rhs_ty) {
                    (Ty::Float, _) | (_, Ty::Float) => Ty::Float,
                    _ => Ty::Int,
                }
            };
        }

        if is_cmp {
            self.error("comparison operators are not supported on vector/matrix types", span);
            return Ty::Bool;
        }
        if matches!(op, BinOp::Rem) {
            self.error("`%` is not supported on vector/matrix types", span);
            return lhs_ty.clone();
        }

        let is_scalar = |t: &Ty| matches!(t, Ty::Int | Ty::Float);

        match op {
            BinOp::Add | BinOp::Sub => {
                if lhs_ty.is_mat() && rhs_ty.is_mat() {
                    if lhs_ty == rhs_ty { Ty::Mat4 } else {
                        self.error("mismatched matrix arity in `+`/`-`", span);
                        lhs_ty.clone()
                    }
                } else if lhs_ty.is_vec() && rhs_ty.is_vec() {
                    if lhs_ty == rhs_ty {
                        lhs_ty.clone()
                    } else {
                        self.error("mismatched vector arity in `+`/`-`", span);
                        lhs_ty.clone()
                    }
                } else {
                    self.error("`+`/`-` between a vector/matrix and a scalar is not supported", span);
                    if lhs_ty.is_vec() || lhs_ty.is_mat() { lhs_ty.clone() } else { rhs_ty.clone() }
                }
            }
            BinOp::Mul | BinOp::Div => {
                if lhs_ty.is_mat() && rhs_ty.is_mat() {
                    if *op == BinOp::Div {
                        self.error("matrix division is not supported", span);
                    }
                    Ty::Mat4
                } else if lhs_ty.is_mat() && *rhs_ty == Ty::Vec4 {
                    if *op == BinOp::Div {
                        self.error("matrix division is not supported", span);
                    }
                    Ty::Vec4
                } else if *lhs_ty == Ty::Vec4 && rhs_ty.is_mat() {
                    self.error("vector * matrix is not supported (use matrix * vector)", span);
                    Ty::Vec4
                } else if lhs_ty.is_vec() && rhs_ty.is_vec() {
                    if lhs_ty == rhs_ty {
                        lhs_ty.clone()
                    } else {
                        self.error("mismatched vector arity in `*`/`/`", span);
                        lhs_ty.clone()
                    }
                } else if lhs_ty.is_vec() && is_scalar(rhs_ty) {
                    lhs_ty.clone()
                } else if is_scalar(lhs_ty) && rhs_ty.is_vec() {
                    rhs_ty.clone()
                } else {
                    self.error("unsupported operand types for `*`/`/`", span);
                    if lhs_ty.is_vec() || lhs_ty.is_mat() { lhs_ty.clone() } else { rhs_ty.clone() }
                }
            }
            _ => unreachable!("Rem and comparisons handled above"),
        }
    }

    fn resolve_field_type(&mut self, base: &TypedExpr, field: &str, span: Span) -> Ty {
        let base_ty = base.clone().into_ty();
        if let Some(arity) = base_ty.vec_arity() {
            return self.resolve_swizzle(arity, field, span);
        }
        let name = match &base_ty {
            Ty::Named(n) => n,
            _ => return Ty::Named("unknown".into()),
        };
        let Some(sdef) = self.structs.get(name).cloned() else {
            // Unknown struct name: already reported elsewhere (or is a
            // synthesized/inferred placeholder type), so stay silent here.
            return Ty::Named("unknown".into());
        };
        match sdef.fields.iter().find(|f| f.name == field) {
            Some(f) => self.resolve_type(&f.ty).unwrap_or(Ty::Named("unknown".into())),
            None => {
                let candidates: Vec<&str> = sdef.fields.iter().map(|f| f.name.as_str()).collect();
                match suggest(field, candidates) {
                    Some(close) => self.error_note(
                        format!("no field `{}` on `{}`", field, name),
                        span,
                        format!("did you mean `{}`?", close),
                    ),
                    None => self.error(format!("no field `{}` on `{}`", field, name), span),
                }
                Ty::Named("unknown".into())
            }
        }
    }

    /// Validate and resolve a GLSL-style swizzle string (`.x`, `.xyz`, `.zyx`,
    /// ...) against a vector base of the given component count.
    fn resolve_swizzle(&mut self, arity: u8, field: &str, span: Span) -> Ty {
        if field.is_empty() || field.len() > 4 {
            self.error("invalid swizzle: expected 1-4 components", span);
            return Ty::Named("unknown".into());
        }
        for c in field.chars() {
            let idx = match c {
                'x' => 0,
                'y' => 1,
                'z' => 2,
                'w' => 3,
                _ => {
                    self.error(format!("invalid swizzle component `{}`", c), span);
                    return Ty::Named("unknown".into());
                }
            };
            if idx >= arity {
                self.error(format!("swizzle component `{}` out of range for Vec{}", c, arity), span);
                return Ty::Named("unknown".into());
            }
        }
        Ty::vec_of_arity(field.len() as u8).unwrap_or(Ty::Named("unknown".into()))
    }

    fn check_match_arm(&mut self, arm: &MatchArm, _scrutinee_expr: &TypedExpr, vars: &mut HashMap<String, Ty>) -> TypedMatchArm {
        let mut stmts = Vec::new();
        for stmt in &arm.body.stmts {
            if let Some(typed) = self.check_stmt(stmt, vars) {
                stmts.push(typed);
            }
        }
        TypedMatchArm { pattern: arm.pattern.clone(), body: TypedBlock { stmts, span: arm.span }, ty: Ty::Named("unknown".into()), span: arm.span }
    }
}
