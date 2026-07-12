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
            Expr::Int(v, s) => {
                if *v == i32::MIN as i64 {
                    // The lexer stores the literal magnitude `2147483648`
                    // pre-negated to `i32::MIN`'s bit pattern (its positive
                    // value doesn't fit `i32` on its own -- `-2147483648` is
                    // the only legal spelling of `i32::MIN`), since normal
                    // digit scanning never otherwise produces a negative
                    // token value. A directly enclosing unary `-` sanctions
                    // that reinterpretation (see the `Expr::Unary` arm below,
                    // which intercepts this exact shape before recursing
                    // here); reaching here un-sanctioned means the source
                    // wrote the bare literal `2147483648` with no negation at
                    // all, which previously type-checked cleanly and
                    // silently became `-2147483648` with zero diagnostics.
                    self.error("integer literal `2147483648` is too large for a 32-bit integer (max 2147483647)", *s);
                }
                Ok(TypedExpr::Int(*v, Ty::Int, *s))
            }
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
                let ty = if let Some(t) = vars.get(name) {
                    t.clone()
                } else if self.functions.contains_key(name) || self.generic_fns.contains_key(name) || is_builtin_name(name) {
                    self.fn_value_ty(name)
                } else {
                    // No local binding, no declared top-level function/generic
                    // function, and not a recognized builtin name -- this is a
                    // genuinely undefined identifier. Previously this fell
                    // through to the `unknown` placeholder type silently (no
                    // diagnostic at all), so a typo'd variable or function
                    // name type-checked cleanly and only broke much later at
                    // the `clang` step against generated IR referencing
                    // `%unknown`/`%undef` the user never wrote.
                    let candidates: Vec<&str> = vars.keys().map(String::as_str)
                        .chain(self.functions.keys().map(String::as_str))
                        .collect();
                    match suggest(name, candidates) {
                        Some(close) => self.error_note(
                            format!("undefined name `{}`", name),
                            *s,
                            format!("did you mean `{}`?", close),
                        ),
                        None => self.error(format!("undefined name `{}`", name), *s),
                    }
                    Ty::Named("unknown".into())
                };
                Ok(TypedExpr::Ident { name: name.clone(), ty, span: *s })
            }
            Expr::SelfExpr(s) => {
                let ty = match vars.get("self") {
                    Some(t) => t.clone(),
                    None => {
                        // No `self` param in scope: this function/closure isn't
                        // a method with a receiver at all. Previously this
                        // silently fell back to the `Self` placeholder type
                        // (one of `is_placeholder`'s recognized sentinels), so
                        // `self` used inside a bare top-level `fn` type-checked
                        // cleanly and only failed at the `clang` step
                        // ("unknown struct `Self`") once codegen tried to
                        // resolve a concrete receiver type that never existed.
                        self.error("`self` is not valid outside of a method with a `self` parameter", *s);
                        Ty::Named("Self".into())
                    }
                };
                Ok(TypedExpr::SelfExpr(ty, *s))
            }
            Expr::Field { base, field, span } => {
                let base_expr = self.infer_expr(base, vars)?;
                let field_ty = self.resolve_field_type(&base_expr, field, *span);
                Ok(TypedExpr::Field { base: Box::new(base_expr), field: field.clone(), ty: field_ty, span: *span })
            }
            Expr::Call { callee, args, span } => {
                // A call to a generic free function: its type arguments
                // aren't written at the call site (no turbofish call
                // syntax), they're inferred by unifying each declared
                // (possibly parameterized) parameter type against the
                // corresponding argument's own inferred type -- see
                // `infer_generic_call`.
                if let Expr::Ident(name, ident_span) = callee.as_ref() {
                    if self.generic_fns.contains_key(name) {
                        return Ok(self.infer_generic_call(name, *ident_span, args, vars, *span));
                    }
                }
                // `list.push(v)` / `.pop()` / `.len()`: intercepted ahead of
                // the generic `Expr::Field`-based method resolution below
                // (which only ever looks a name up in a struct's *field*
                // list, see `resolve_field_type`, and would reject `List<T>`
                // outright since it isn't a user struct).
                if let Expr::Field { base, field, span: field_span } = callee.as_ref() {
                    let base_typed = self.infer_expr(base, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                    if let Ty::List(elem_ty) = base_typed.clone().into_ty() {
                        return Ok(self.infer_list_method(base_typed, field, *elem_ty, args, vars, *span));
                    }
                    // A method call `obj.method(args)` where `method` isn't
                    // also a field on `obj`'s struct: type the callee as a
                    // bare `Field` (`ty: unknown`, resolved below through
                    // `Checker::methods`, keyed by `"{struct}#{method}"` so
                    // two unrelated structs can declare a same-named method
                    // without colliding -- see that field's own doc comment)
                    // rather than routing it through the generic `Expr::Field`
                    // arm's `resolve_field_type`, which only ever looks a
                    // name up in the struct's *field* list and would reject
                    // any real method call outright ("no field `method` on
                    // `Type`").
                    if let Ty::Named(struct_name) = base_typed.clone().into_ty() {
                        let is_real_field = self.structs.get(&struct_name)
                            .map(|s| s.fields.iter().any(|f| f.name == *field))
                            .unwrap_or(false);
                        let method_key = format!("{}#{}", struct_name, field);
                        if !is_real_field && self.methods.contains_key(&method_key) {
                            let callee_expr = TypedExpr::Field {
                                base: Box::new(base_typed),
                                field: field.clone(),
                                ty: Ty::Named("unknown".into()),
                                span: *field_span,
                            };
                            let arg_exprs: Vec<TypedExpr> = args.iter()
                                .map(|a| self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into()))))
                                .collect();
                            if let Some((param_tys, _)) = self.methods.get(&method_key).cloned() {
                                self.check_call_args(&param_tys, true, &arg_exprs, *span);
                            }
                            let ret_ty = self.methods.get(&method_key).and_then(|(_, ret)| ret.clone()).unwrap_or(Ty::Named("unknown".into()));
                            return Ok(TypedExpr::Call { callee: Box::new(callee_expr), args: arg_exprs, ty: ret_ty, span: *span });
                        }
                    }
                }
                // A direct call to a plain named top-level function: type the
                // callee as a bare, unwidened `Ident` (`ty: unknown`) so it
                // stays on `emit_call_expr`'s direct-call codegen path.
                // `fn_value_ty`'s `Ty::Closure` widening (used by the general
                // `Expr::Ident` arm) is only for when a function name is used
                // as a first-class *value* (an argument, a `let` binding,
                // ...); applying it here too would route every ordinary call
                // through the indirect closure-call mechanism instead.
                let callee_expr = match callee.as_ref() {
                    Expr::Ident(name, ident_span) if !vars.contains_key(name) && self.functions.contains_key(name) => {
                        TypedExpr::Ident { name: name.clone(), ty: Ty::Named("unknown".into()), span: *ident_span }
                    }
                    _ => self.infer_expr(callee, vars)?,
                };
                let arg_exprs: Vec<TypedExpr> = args.iter().map(|a| self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))).collect();
                // Standard-library builtins (`print`/`println`, math, string
                // ops) aren't declared by any `fn` item, so they never show
                // up in `self.functions`; special-case their return types
                // here before falling back to the function table.
                if let TypedExpr::Ident { name, .. } = &callee_expr {
                    if let Some(ty) = builtin_return_ty(name, &arg_exprs) {
                        // `print`/`println`'s non-f-string form passes its
                        // argument straight through as `printf`'s format
                        // string (see `Codegen::emit_print_like`) -- it's
                        // never a `%s`-substituted value, so anything but a
                        // `str` reaches codegen as a raw non-pointer value
                        // (an `i32`, a bare `i1`, ...) where an `i8*` format
                        // string is required, producing invalid LLVM IR that
                        // only fails later at the `clang` step with a
                        // confusing, mislocated error instead of a clean
                        // diagnostic here.
                        if matches!(name.as_str(), "print" | "println") {
                            if let Some(arg) = arg_exprs.first() {
                                let is_fstr = matches!(arg, TypedExpr::FStr(..));
                                let arg_ty = arg.clone().into_ty();
                                if !is_fstr && !matches!(arg_ty, Ty::Str) {
                                    self.error(
                                        format!(
                                            "`{}` expects a `str` argument, found `{:?}` -- use an f-string to print other types, e.g. `f\"{{x}}\"`",
                                            name, arg_ty
                                        ),
                                        *span,
                                    );
                                }
                            }
                        } else {
                            self.check_builtin_call_args(name, &arg_exprs, *span);
                        }
                        return Ok(TypedExpr::Call { callee: Box::new(callee_expr), args: arg_exprs, ty, span: *span });
                    }
                }
                // A call whose callee is itself closure-typed (a `let`-bound
                // lambda, a closure-typed parameter/field, or a lambda
                // literal called immediately) resolves its return type from
                // that closure type directly, rather than the name-keyed
                // function table below (which only ever holds `fn`
                // declarations, not values).
                let ret_ty = if let Ty::Closure(_, ret) = callee_expr.clone().into_ty() {
                    *ret
                } else {
                    // Look up the signature from the function table. §1.4:
                    // this is also where argument count/type validation
                    // happens for an ordinary call -- previously entirely
                    // absent, so `add("foo", "bar")` against `fn add(a: i32,
                    // b: i32)` type-checked cleanly and only misbehaved
                    // (undefined behavior from treating two string pointers
                    // as `i32`s) once actually run.
                    //
                    // Most `Field`-callee method calls are already resolved
                    // (and returned) by the per-struct `self.methods` lookup
                    // above; this branch only remains reachable for a method
                    // call whose receiver type wasn't a plain `Ty::Named`
                    // (e.g. still `unknown` from an earlier error), so it
                    // falls back to `self.functions` defensively rather than
                    // reporting "no such method" twice.
                    let sig = match &callee_expr {
                        TypedExpr::Ident { name, .. } => self.functions.get(name).cloned(),
                        TypedExpr::Field { base, field, .. } => {
                            if let Ty::Named(struct_name) = base.clone().into_ty() {
                                self.methods.get(&format!("{}#{}", struct_name, field)).cloned()
                                    .or_else(|| self.functions.get(field).cloned())
                            } else {
                                self.functions.get(field).cloned()
                            }
                        }
                        _ => None,
                    };
                    match sig {
                        Some((param_tys, ret)) => {
                            let skip_self = matches!(&callee_expr, TypedExpr::Field { .. });
                            self.check_call_args(&param_tys, skip_self, &arg_exprs, *span);
                            ret.unwrap_or(Ty::Named("unknown".into()))
                        }
                        None => Ty::Named("unknown".into()),
                    }
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
                // `-2147483648` is the only legal way to spell `i32::MIN`
                // (see the `Expr::Int` arm's doc comment above): intercept
                // this exact raw-AST shape -- a unary `-` directly over the
                // literal -- before generically recursing into `operand`,
                // which would otherwise hit that arm's bounds check and
                // reject its own sanctioned case.
                if matches!(op, UnOp::Neg) {
                    if let Expr::Int(v, _) = operand.as_ref() {
                        if *v == i32::MIN as i64 {
                            return Ok(TypedExpr::Int(i32::MIN as i64, Ty::Int, *span));
                        }
                    }
                }
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
                // Each arm gets its own scoped copy of `vars`: a payload
                // pattern's bindings (see `check_match_arm`) must not leak
                // into sibling arms or the surrounding scope.
                let arm_tys: Vec<TypedMatchArm> = arms.iter().map(|a| {
                    let mut arm_vars = vars.clone();
                    self.check_match_arm(a, &scrutinee_expr, &mut arm_vars)
                }).collect();
                self.check_match_exhaustive(&scrutinee_expr.clone().into_ty(), &arm_tys, *span);
                // The match's own value type is the first arm that actually
                // has one -- an arm ending in `return`/`break`/`continue`
                // never flows into the join point (see `Codegen`'s match
                // arm below), so its `unknown` placeholder (see
                // `check_match_arm`) must not shadow a real type reported by
                // a later, value-producing arm.
                let ty = arm_tys.iter()
                    .map(|a| a.ty.clone())
                    .find(|t| !matches!(t, Ty::Named(n) if n == "unknown"))
                    .unwrap_or(Ty::Named("unknown".into()));
                Ok(TypedExpr::Match { scrutinee: Box::new(scrutinee_expr), arms: arm_tys, ty, span: *span })
            }
            Expr::StructLit { name, type_args, args, span } => {
                let arg_exprs: Vec<TypedExpr> = args.iter().map(|a| self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))).collect();
                if name == "List" {
                    return Ok(self.infer_list_new(type_args, &arg_exprs, *span));
                }
                if self.generic_structs.contains_key(name) {
                    return Ok(self.infer_generic_struct_lit(name, type_args, arg_exprs, *span));
                }
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
            Expr::EnumVariant { enum_name, type_args, variant, args, span } => {
                let arg_exprs: Vec<TypedExpr> = args.iter().map(|a| self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))).collect();
                if self.generic_enums.contains_key(enum_name) {
                    return Ok(self.infer_generic_enum_variant(enum_name, type_args, variant, arg_exprs, *span));
                }
                self.check_enum_variant_name(enum_name, variant, *span);
                if let Some(edef) = self.enums.get(enum_name).cloned() {
                    if let Some(vdef) = edef.variants.iter().find(|v| &v.name == variant) {
                        if vdef.fields.len() != arg_exprs.len() {
                            self.error(
                                format!(
                                    "`{}::{}(..)` expects {} argument(s), found {}",
                                    enum_name, variant, vdef.fields.len(), arg_exprs.len()
                                ),
                                *span,
                            );
                        }
                    }
                }
                Ok(TypedExpr::EnumVariant {
                    enum_name: enum_name.clone(),
                    variant: variant.clone(),
                    args: arg_exprs,
                    ty: Ty::Enum(enum_name.clone()),
                    span: *span,
                })
            }
            Expr::GenRefIndex { base, index, span } => {
                let base_expr = self.infer_expr(base, vars)?;
                let index_expr = self.infer_expr(index, vars)?;
                if !matches!(index_expr.clone().into_ty(), Ty::Int) {
                    self.error("`[..]` index must be `i32`", *span);
                }
                // `[..]` is the general index syntax: dispatch on `base`'s
                // resolved type to either a `GenRef<T>` generation-checked
                // dereference or a `List<T>` bounds-checked element read --
                // see `Expr::GenRefIndex`'s doc comment in `crate::ast`.
                match base_expr.clone().into_ty() {
                    Ty::GenRef(inner) => {
                        self.require_backing_arena(&inner, *span);
                        Ok(TypedExpr::GenRefIndex { base: Box::new(base_expr), index: Box::new(index_expr), ty: *inner, span: *span })
                    }
                    Ty::List(inner) => {
                        Ok(TypedExpr::ListIndex { base: Box::new(base_expr), index: Box::new(index_expr), ty: *inner, span: *span })
                    }
                    other => {
                        self.error(format!("`[..]` indexing requires a `GenRef<T>` or `List<T>`, found `{:?}`", other), *span);
                        Ok(TypedExpr::Error(Ty::Named("unknown".into())))
                    }
                }
            }
            Expr::Lambda { params, ret, body, span } => {
                for p in params {
                    if p.is_self {
                        self.error("`self` is not allowed in a closure's parameter list", p.span);
                    }
                }
                let typed_params: Vec<TypedParam> = params.iter().map(|p| self.check_param_with_self_ty(p, &Ty::Named("infer".into()))).collect();
                let mut inner_vars = vars.clone();
                for p in &typed_params {
                    inner_vars.insert(p.name.clone(), p.ty.clone());
                }
                // A closure's return type is inferred *from* its body below
                // (its trailing expression, unless explicitly declared) --
                // checking `return` statements against it here would be
                // circular, so return-type checking is suspended for the
                // duration of this body (see `current_ret_ty`'s doc comment).
                let saved_ret_ty = std::mem::replace(&mut self.current_ret_ty, None);
                let body_typed = self.check_block_inner(body, &mut inner_vars);
                self.current_ret_ty = saved_ret_ty;
                // A declared `-> Ret` is used as-is; otherwise (mirroring the
                // `if`-expression's own type inference) the closure's return
                // type is whatever its trailing expression evaluates to, or
                // the `unknown` placeholder codegen already treats as `void`
                // for a body with no trailing value.
                let ret_ty = match ret {
                    Some(t) => self.resolve_type(t).unwrap_or(Ty::Named("unknown".into())),
                    None => body_typed.stmts.last()
                        .and_then(|s| if let TypedStmt::Expr(e) = s { Some(e.clone().into_ty()) } else { None })
                        .unwrap_or_else(|| Ty::Named("unknown".into())),
                };
                let param_tys: Vec<Ty> = typed_params.iter().map(|p| p.ty.clone()).collect();
                let closure_ty = Ty::Closure(param_tys, Box::new(ret_ty));
                Ok(TypedExpr::Closure { params: typed_params, body: body_typed, ty: closure_ty, span: *span })
            }
            Expr::ListLit(elems, span) => {
                if elems.is_empty() {
                    self.error("empty list literal `[]` has no element to infer a type from -- use `List<T>()`", *span);
                    return Ok(TypedExpr::Error(Ty::Named("infer_error".into())));
                }
                let typed: Vec<TypedExpr> = elems.iter().map(|e| self.infer_expr(e, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))).collect();
                let elem_ty = typed[0].clone().into_ty();
                for e in &typed[1..] {
                    let t = e.clone().into_ty();
                    if t != elem_ty {
                        self.error(format!("list literal elements must all have the same type (found `{:?}` and `{:?}`)", elem_ty, t), *span);
                    }
                }
                Ok(TypedExpr::ListLit { elems: typed, elem_ty, span: *span })
            }
        }
    }

    /// `List<T>()`: an empty list construction, the syntactic counterpart to
    /// a non-empty `[e1, e2, ...]` literal (which infers its element type
    /// from its elements instead). Requires an explicit `<T>` turbofish --
    /// there's nothing to infer a type from otherwise, mirroring
    /// `Option<i32>::None`'s own requirement in `infer_generic_enum_variant`.
    fn infer_list_new(&mut self, type_args: &[Type], arg_exprs: &[TypedExpr], span: Span) -> TypedExpr {
        if !arg_exprs.is_empty() {
            self.error("`List<T>()` takes no arguments -- use a list literal `[e1, e2, ...]` to build a non-empty list", span);
        }
        let elem_ty = match type_args.first() {
            Some(t) => self.resolve_type(t).unwrap_or(Ty::Named("unknown".into())),
            None => {
                self.error("`List<T>()` needs an explicit type argument, e.g. `List<i32>()`", span);
                Ty::Named("unknown".into())
            }
        };
        TypedExpr::ListNew { elem_ty, span }
    }

    /// Type-check a `List<T>` method call (`push`/`pop`/`len`), called from
    /// `Expr::Call`'s special-case above once `base`'s type is known to be
    /// `Ty::List(elem_ty)`.
    fn infer_list_method(&mut self, base: TypedExpr, method: &str, elem_ty: Ty, args: &[Expr], vars: &mut HashMap<String, Ty>, span: Span) -> TypedExpr {
        let arg_exprs: Vec<TypedExpr> = args.iter().map(|a| self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))).collect();
        match method {
            "push" => {
                if arg_exprs.len() != 1 {
                    self.error(format!("`push(..)` expects 1 argument, found {}", arg_exprs.len()), span);
                } else {
                    let arg_ty = arg_exprs[0].clone().into_ty();
                    if arg_ty != elem_ty {
                        self.error(format!("`push(..)` expects `{:?}`, found `{:?}`", elem_ty, arg_ty), span);
                    }
                }
                TypedExpr::ListMethod { base: Box::new(base), method: ListMethod::Push, args: arg_exprs, ty: Ty::Named("unknown".into()), span }
            }
            "pop" => {
                if !arg_exprs.is_empty() {
                    self.error(format!("`pop()` expects 0 arguments, found {}", arg_exprs.len()), span);
                }
                TypedExpr::ListMethod { base: Box::new(base), method: ListMethod::Pop, args: Vec::new(), ty: elem_ty, span }
            }
            "len" => {
                if !arg_exprs.is_empty() {
                    self.error(format!("`len()` expects 0 arguments, found {}", arg_exprs.len()), span);
                }
                TypedExpr::ListMethod { base: Box::new(base), method: ListMethod::Len, args: Vec::new(), ty: Ty::Int, span }
            }
            _ => {
                self.error(format!("no method `{}` on `List<..>` (expected `push`, `pop`, or `len`)", method), span);
                TypedExpr::Error(Ty::Named("infer_error".into()))
            }
        }
    }

    /// Type-check a call to generic function `name`: infer its type
    /// arguments by unifying each declared parameter type against the
    /// corresponding (already-inferred) argument type, then dispatch to its
    /// monomorphized concrete copy (instantiating it on first use). Requires
    /// every type parameter to appear in at least one parameter's type --
    /// one that only appears in the return type can't be inferred from the
    /// call site alone (this compiler has no call-site turbofish for
    /// functions), and is reported as an error.
    fn infer_generic_call(&mut self, name: &str, ident_span: Span, args: &[Expr], vars: &mut HashMap<String, Ty>, span: Span) -> TypedExpr {
        let arg_exprs: Vec<TypedExpr> = args.iter().map(|a| self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))).collect();
        let template = self.generic_fns.get(name).cloned().expect("caller already checked generic_fns.contains_key");
        let mut subst: HashMap<String, Ty> = HashMap::new();
        let mut conflicts = Vec::new();
        for (p, a) in template.sig.params.iter().zip(arg_exprs.iter()) {
            if let Some(pty) = &p.ty {
                self.unify_ty(pty, &a.clone().into_ty(), &template.sig.type_params, &mut subst, &mut conflicts);
            }
        }
        for (tp, first, second) in &conflicts {
            self.error(
                format!(
                    "type parameter `{}` of `{}` is used inconsistently: inferred both `{:?}` and `{:?}` from its arguments",
                    tp, name, first, second
                ),
                span,
            );
        }
        let mut type_args = Vec::new();
        for tp in &template.sig.type_params {
            match subst.get(tp) {
                Some(t) => type_args.push(t.clone()),
                None => self.error(format!("cannot infer type parameter `{}` of `{}` from its arguments", tp, name), span),
            }
        }
        if template.sig.params.len() != arg_exprs.len() {
            self.error(
                format!("`{}(..)` expects {} argument(s), found {}", name, template.sig.params.len(), arg_exprs.len()),
                span,
            );
        }
        if type_args.len() != template.sig.type_params.len() {
            return TypedExpr::Error(Ty::Named("infer_error".into()));
        }
        let mangled = self.instantiate_fn(name, &type_args);
        let ret_ty = self.functions.get(&mangled).and_then(|(_, r)| r.clone()).unwrap_or(Ty::Named("unknown".into()));
        let callee_expr = TypedExpr::Ident { name: mangled, ty: Ty::Named("unknown".into()), span: ident_span };
        TypedExpr::Call { callee: Box::new(callee_expr), args: arg_exprs, ty: ret_ty, span }
    }

    /// Resolve a generic struct construction's type arguments -- either the
    /// explicit turbofish `type_args` (`Box<i32>(..)`), or, when absent, by
    /// unifying each field's declared type against the corresponding
    /// (already-inferred) constructor argument's type -- then dispatch to
    /// its monomorphized concrete copy.
    fn infer_generic_struct_lit(&mut self, name: &str, type_args: &[Type], arg_exprs: Vec<TypedExpr>, span: Span) -> TypedExpr {
        let template = self.generic_structs.get(name).cloned().expect("caller already checked generic_structs.contains_key");
        let concrete_args = self.resolve_generic_ctor_args(
            name, type_args, &template.type_params,
            template.fields.iter().map(|f| &f.ty),
            &arg_exprs,
            span,
        );
        let Some(concrete_args) = concrete_args else { return TypedExpr::Error(Ty::Named("infer_error".into())) };
        let mangled = self.instantiate_struct(name, &concrete_args);
        let field_count = self.structs.get(&mangled).map(|s| s.fields.len()).unwrap_or(0);
        if arg_exprs.len() != field_count {
            self.error(format!("`{}(..)` expects {} argument(s), found {}", name, field_count, arg_exprs.len()), span);
        }
        TypedExpr::StructLit { name: mangled.clone(), args: arg_exprs, ty: Ty::Named(mangled), span }
    }

    /// Resolve a generic enum variant construction's type arguments and
    /// dispatch to its monomorphized concrete copy. Mirrors
    /// `infer_generic_struct_lit`; see its doc comment. A variant with no
    /// payload fields (e.g. `None`) has nothing to infer from, so it
    /// requires an explicit turbofish (`Option<i32>::None`).
    fn infer_generic_enum_variant(&mut self, enum_name: &str, type_args: &[Type], variant: &str, arg_exprs: Vec<TypedExpr>, span: Span) -> TypedExpr {
        let template = self.generic_enums.get(enum_name).cloned().expect("caller already checked generic_enums.contains_key");
        let Some(vdef) = template.variants.iter().find(|v| v.name == variant).cloned() else {
            let candidates: Vec<&str> = template.variants.iter().map(|v| v.name.as_str()).collect();
            match suggest(variant, candidates) {
                Some(close) => self.error_note(
                    format!("enum `{}` has no variant `{}`", enum_name, variant),
                    span,
                    format!("did you mean `{}`?", close),
                ),
                None => self.error(format!("enum `{}` has no variant `{}`", enum_name, variant), span),
            }
            return TypedExpr::Error(Ty::Named("infer_error".into()));
        };
        let concrete_args = self.resolve_generic_ctor_args(
            enum_name, type_args, &template.type_params,
            vdef.fields.iter().map(|f| &f.ty),
            &arg_exprs,
            span,
        );
        let Some(concrete_args) = concrete_args else { return TypedExpr::Error(Ty::Named("infer_error".into())) };
        if vdef.fields.len() != arg_exprs.len() {
            self.error(
                format!("`{}::{}(..)` expects {} argument(s), found {}", enum_name, variant, vdef.fields.len(), arg_exprs.len()),
                span,
            );
        }
        let mangled = self.instantiate_enum(enum_name, &concrete_args);
        TypedExpr::EnumVariant { enum_name: mangled.clone(), variant: variant.to_string(), args: arg_exprs, ty: Ty::Enum(mangled), span }
    }

    /// Shared type-argument resolution for a generic struct/enum-variant
    /// construction site: use the explicit turbofish `type_args` if given
    /// (validating its arity), otherwise unify `field_tys` positionally
    /// against `arg_exprs`'s inferred types. `None` means resolution failed
    /// and an error was already recorded.
    fn resolve_generic_ctor_args<'a>(
        &mut self,
        template_name: &str,
        type_args: &[Type],
        type_params: &[String],
        field_tys: impl Iterator<Item = &'a Type>,
        arg_exprs: &[TypedExpr],
        span: Span,
    ) -> Option<Vec<Ty>> {
        if !type_args.is_empty() {
            if type_args.len() != type_params.len() {
                self.error(
                    format!("`{}` expects {} type argument(s), found {}", template_name, type_params.len(), type_args.len()),
                    span,
                );
                return None;
            }
            let resolved: Vec<Ty> = type_args.iter().filter_map(|t| self.resolve_type(t)).collect();
            if resolved.len() != type_args.len() {
                return None;
            }
            return Some(resolved);
        }
        let mut subst: HashMap<String, Ty> = HashMap::new();
        let mut conflicts = Vec::new();
        for (fty, a) in field_tys.zip(arg_exprs.iter()) {
            self.unify_ty(fty, &a.clone().into_ty(), type_params, &mut subst, &mut conflicts);
        }
        for (tp, first, second) in &conflicts {
            self.error(
                format!(
                    "type parameter `{}` of `{}` is used inconsistently: inferred both `{:?}` and `{:?}` from its arguments",
                    tp, template_name, first, second
                ),
                span,
            );
        }
        let mut out = Vec::new();
        for tp in type_params {
            match subst.get(tp) {
                Some(t) => out.push(t.clone()),
                None => self.error(
                    format!("cannot infer type argument `{}` for `{}` -- use an explicit `{}<...>`", tp, template_name, template_name),
                    span,
                ),
            }
        }
        if out.len() != type_params.len() {
            return None;
        }
        Some(out)
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

    /// Validate an ordinary call's argument count and per-argument types
    /// against a declared signature's parameter types (§1.4). `skip_self` is
    /// true for a method call, whose stored signature includes the `self`
    /// receiver as `param_tys[0]` (registered as the placeholder type
    /// `Ty::Named("infer")` -- see `Checker::check`'s impl-block signature
    /// pass -- since `self`'s real type isn't resolved at that point) but
    /// whose call-site `arg_exprs` never includes an explicit receiver
    /// argument (the receiver is threaded separately at codegen).
    fn check_call_args(&mut self, param_tys: &[Ty], skip_self: bool, arg_exprs: &[TypedExpr], span: Span) {
        let expected: &[Ty] = if skip_self && !param_tys.is_empty() { &param_tys[1..] } else { param_tys };
        if expected.len() != arg_exprs.len() {
            self.error(
                format!("this call expects {} argument(s), found {}", expected.len(), arg_exprs.len()),
                span,
            );
            return;
        }
        for (i, (p, a)) in expected.iter().zip(arg_exprs.iter()).enumerate() {
            let actual = a.clone().into_ty();
            if !Self::types_compatible(p, &actual) {
                self.error(
                    format!("argument {} expected type `{:?}`, found `{:?}`", i + 1, p, actual),
                    span,
                );
            }
        }
    }

    /// Validate a builtin call's argument count and types against what its
    /// `crate::codegen` lowering actually assumes. Builtins aren't declared
    /// by any `fn` item (see `builtin_return_ty`), so unlike an ordinary
    /// call they never passed through `check_call_args` at all -- and several
    /// (`emit_abs`/`emit_dot`/`emit_clamp`/`emit_file_open`/...) `untag` an
    /// argument using *another* argument's inferred type rather than a fixed
    /// type of their own choosing. A caller passing an unexpected type
    /// (`file_open(42, 3.5)`, `clamp("x", 1, 5)`, `dot(v2, v3)`) previously
    /// type-checked cleanly and only failed later at the `clang` step with a
    /// confusing "expected value token" error pointing at generated IR the
    /// user never wrote, instead of a clean diagnostic here -- the same class
    /// of bug the `print`/`println` check just above (the first instance of
    /// this fix) already guards against. `print`/`println` are validated by
    /// the caller instead of here since their check is about the raw-
    /// `printf`-format-string case, not ordinary argument arity/type.
    fn check_builtin_call_args(&mut self, name: &str, args: &[TypedExpr], span: Span) {
        fn is_placeholder(t: &Ty) -> bool {
            matches!(t, Ty::Named(n) if matches!(n.as_str(), "unknown" | "infer_error" | "infer" | "Self"))
        }
        fn is_numeric(t: &Ty) -> bool {
            matches!(t, Ty::Int | Ty::Float) || is_placeholder(t)
        }
        fn is_vec(t: &Ty) -> bool {
            t.is_vec() || is_placeholder(t)
        }
        fn tys_eq(a: &Ty, b: &Ty) -> bool {
            a == b || is_placeholder(a) || is_placeholder(b)
        }

        let arg_tys: Vec<Ty> = args.iter().map(|a| a.clone().into_ty()).collect();
        let arity_ok = |want: usize, this: &mut Self| -> bool {
            if arg_tys.len() != want {
                this.error(format!("`{}` expects {} argument(s), found {}", name, want, arg_tys.len()), span);
                false
            } else {
                true
            }
        };

        match name {
            "sqrt" | "floor" | "ceil" | "abs" => {
                if arity_ok(1, self) && !is_numeric(&arg_tys[0]) {
                    self.error(format!("`{}` expects a numeric (`int`/`float`) argument, found `{:?}`", name, arg_tys[0]), span);
                }
            }
            "pow" | "min" | "max" => {
                if arity_ok(2, self) {
                    for (i, t) in arg_tys.iter().enumerate() {
                        if !is_numeric(t) {
                            self.error(format!("`{}` argument {} expected a numeric (`int`/`float`) value, found `{:?}`", name, i + 1, t), span);
                        }
                    }
                }
            }
            "len" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Str) {
                    self.error(format!("`len` expects a `str` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            "concat" => {
                if arity_ok(2, self) {
                    for (i, t) in arg_tys.iter().enumerate() {
                        if !tys_eq(t, &Ty::Str) {
                            self.error(format!("`concat` argument {} expected `str`, found `{:?}`", i + 1, t), span);
                        }
                    }
                }
            }
            "read_line" | "rand" | "null_ptr" => {
                arity_ok(0, self);
            }
            "dot" => {
                if arity_ok(2, self) {
                    if !is_vec(&arg_tys[0]) {
                        self.error(format!("`dot` argument 1 expected a `Vec2`/`Vec3`/`Vec4` value, found `{:?}`", arg_tys[0]), span);
                    } else if !tys_eq(&arg_tys[0], &arg_tys[1]) {
                        self.error(format!("`dot` arguments must be the same vector type, found `{:?}` and `{:?}`", arg_tys[0], arg_tys[1]), span);
                    }
                }
            }
            "length" => {
                if arity_ok(1, self) && !is_vec(&arg_tys[0]) {
                    self.error(format!("`length` expects a `Vec2`/`Vec3`/`Vec4` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            "lerp" => {
                if arity_ok(3, self) {
                    let a_ok = matches!(arg_tys[0], Ty::Float) || is_vec(&arg_tys[0]) || is_placeholder(&arg_tys[0]);
                    if !a_ok {
                        self.error(format!("`lerp` argument 1 expected `float`/`Vec2`/`Vec3`/`Vec4`, found `{:?}`", arg_tys[0]), span);
                    } else if !tys_eq(&arg_tys[0], &arg_tys[1]) {
                        self.error(format!("`lerp` arguments 1 and 2 must be the same type, found `{:?}` and `{:?}`", arg_tys[0], arg_tys[1]), span);
                    }
                    if !is_numeric(&arg_tys[2]) {
                        self.error(format!("`lerp` argument 3 (`t`) expected a numeric (`int`/`float`) value, found `{:?}`", arg_tys[2]), span);
                    }
                }
            }
            "clamp" => {
                if arity_ok(3, self) {
                    if !is_numeric(&arg_tys[0]) {
                        self.error(format!("`clamp` argument 1 expected a numeric (`int`/`float`) value, found `{:?}`", arg_tys[0]), span);
                    } else {
                        for (i, t) in [&arg_tys[1], &arg_tys[2]].into_iter().enumerate() {
                            if !tys_eq(&arg_tys[0], t) {
                                self.error(format!("`clamp` argument {} expected `{:?}` (same as argument 1), found `{:?}`", i + 2, arg_tys[0], t), span);
                            }
                        }
                    }
                }
            }
            "rand_range" => {
                if arity_ok(2, self) {
                    for (i, t) in arg_tys.iter().enumerate() {
                        if !tys_eq(t, &Ty::Int) {
                            self.error(format!("`rand_range` argument {} expected `int`, found `{:?}`", i + 1, t), span);
                        }
                    }
                }
            }
            "rand_seed" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Int) {
                    self.error(format!("`rand_seed` expects an `int` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            "is_null" | "ptr_to_str" | "file_close" | "file_read" | "file_read_line" | "tcp_close" | "tcp_recv" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Ptr) {
                    self.error(format!("`{}` expects a `ptr` argument, found `{:?}`", name, arg_tys[0]), span);
                }
            }
            "file_exists" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Str) {
                    self.error(format!("`file_exists` expects a `str` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            "file_open" => {
                if arity_ok(2, self) {
                    for (i, t) in arg_tys.iter().enumerate() {
                        if !tys_eq(t, &Ty::Str) {
                            self.error(format!("`file_open` argument {} expected `str`, found `{:?}`", i + 1, t), span);
                        }
                    }
                }
            }
            "file_write" => {
                if arity_ok(2, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`file_write` argument 1 expected `ptr`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Str) {
                        self.error(format!("`file_write` argument 2 expected `str`, found `{:?}`", arg_tys[1]), span);
                    }
                }
            }
            "args" => {
                arity_ok(0, self);
            }
            "env_get" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Str) {
                    self.error(format!("`env_get` expects a `str` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            "env_set" => {
                if arity_ok(2, self) {
                    for (i, t) in arg_tys.iter().enumerate() {
                        if !tys_eq(t, &Ty::Str) {
                            self.error(format!("`env_set` argument {} expected `str`, found `{:?}`", i + 1, t), span);
                        }
                    }
                }
            }
            "tcp_connect" => {
                if arity_ok(2, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Str) {
                        self.error(format!("`tcp_connect` argument 1 expected `str`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Int) {
                        self.error(format!("`tcp_connect` argument 2 expected `int`, found `{:?}`", arg_tys[1]), span);
                    }
                }
            }
            "tcp_send" => {
                if arity_ok(2, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`tcp_send` argument 1 expected `ptr`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Str) {
                        self.error(format!("`tcp_send` argument 2 expected `str`, found `{:?}`", arg_tys[1]), span);
                    }
                }
            }
            _ => {}
        }
    }

    /// Infer the result type of a binary operator, dispatching on whether
    /// either operand is a builtin vector/matrix type. Falls through to the
    /// original Int/Float/Bool behavior when both operands are scalar.
    fn infer_binop_ty(&mut self, op: &BinOp, lhs_ty: &Ty, rhs_ty: &Ty, span: Span) -> Ty {
        if matches!(op, BinOp::And | BinOp::Or) {
            if *lhs_ty != Ty::Bool || *rhs_ty != Ty::Bool {
                self.error(
                    format!("`&&`/`||` (`and`/`or`) operands must both be `bool`, found `{:?}` and `{:?}`", lhs_ty, rhs_ty),
                    span,
                );
            }
            return Ty::Bool;
        }
        let is_cmp = matches!(op, BinOp::Eq | BinOp::Ne | BinOp::Lt | BinOp::Gt | BinOp::Le | BinOp::Ge);
        if !lhs_ty.is_vec() && !lhs_ty.is_mat() && !rhs_ty.is_vec() && !rhs_ty.is_mat() {
            if is_cmp {
                // Only these two shapes have real codegen support today
                // (`Codegen::emit_binop`'s scalar and `Ty::Ptr` arms): a
                // scalar Int/Float pair (any mix, all six operators), and a
                // `ptr`/`ptr` pair restricted to `==`/`!=`. Every other type
                // -- `GenRef<T>`, `str`, an enum, a struct, `List<T>`, a
                // closure, `bool`, or any mismatched pair -- used to fall
                // through this same "original scalar behavior" branch and
                // type-check cleanly regardless, only to fail with an
                // unlocated error once `emit_binop` actually saw it at
                // codegen time.
                let is_scalar = |t: &Ty| matches!(t, Ty::Int | Ty::Float);
                if is_scalar(lhs_ty) && is_scalar(rhs_ty) {
                    return Ty::Bool;
                }
                if *lhs_ty == Ty::Ptr && *rhs_ty == Ty::Ptr {
                    if !matches!(op, BinOp::Eq | BinOp::Ne) {
                        self.error("only `==`/`!=` are supported on `ptr` values", span);
                    }
                    return Ty::Bool;
                }
                let op_str = match op {
                    BinOp::Eq => "==", BinOp::Ne => "!=",
                    BinOp::Lt => "<", BinOp::Gt => ">",
                    BinOp::Le => "<=", BinOp::Ge => ">=",
                    _ => unreachable!("is_cmp already restricts op to these six"),
                };
                self.error(
                    format!("`{}` is not supported between `{:?}` and `{:?}`", op_str, lhs_ty, rhs_ty),
                    span,
                );
                return Ty::Bool;
            }
            // Original scalar arithmetic behavior, preserved exactly.
            return match (lhs_ty, rhs_ty) {
                (Ty::Float, _) | (_, Ty::Float) => Ty::Float,
                _ => Ty::Int,
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

    /// The type of a bare identifier that isn't a local -- if it names a
    /// declared top-level function, that function used as a first-class
    /// value is a closure with no captures, so it gets the same `Ty::Closure`
    /// a lambda literal would; otherwise `unknown` (an undeclared name).
    fn fn_value_ty(&self, name: &str) -> Ty {
        self.functions.get(name)
            .map(|(params, ret)| Ty::Closure(params.clone(), Box::new(ret.clone().unwrap_or(Ty::Named("unknown".into())))))
            .unwrap_or(Ty::Named("unknown".into()))
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

    /// Report a checker error if `arms` doesn't provably cover every value
    /// of `scrutinee_ty` -- previously nothing did, so a non-exhaustive
    /// `match` compiled cleanly and fell through to an `undef` value at
    /// runtime (see the "no arm matched" fallthrough path in
    /// `Codegen::emit_expr`'s `TypedExpr::Match` arm, which assumes
    /// exhaustiveness was already checked here). `Pattern::Wildcard`,
    /// `Pattern::Binding`, and a `Pattern::Struct` matching the scrutinee's
    /// own struct type (per its doc comment, a struct pattern carries no tag
    /// and always matches) are all unconditional catch-alls. Otherwise,
    /// exhaustiveness is provable only for `enum` (every variant covered)
    /// and `bool` (`true` and `false` both covered) scrutinees; every other
    /// type's domain (`i32`, `str`, ...) can't be proven covered by a finite
    /// set of literal/`Compare` patterns, so those always require an
    /// explicit catch-all.
    fn check_match_exhaustive(&mut self, scrutinee_ty: &Ty, arms: &[TypedMatchArm], span: Span) {
        if Self::is_placeholder_ty(scrutinee_ty) {
            return;
        }
        let has_catchall = arms.iter().any(|a| matches!(a.pattern, Pattern::Wildcard | Pattern::Binding(_)));
        if has_catchall {
            return;
        }
        match scrutinee_ty {
            Ty::Enum(name) => {
                let Some(edef) = self.enums.get(name).cloned() else { return };
                let covered: std::collections::HashSet<&str> = arms.iter()
                    .filter_map(|a| if let Pattern::EnumVariant(_, variant, _) = &a.pattern { Some(variant.as_str()) } else { None })
                    .collect();
                let missing: Vec<&str> = edef.variants.iter()
                    .map(|v| v.name.as_str())
                    .filter(|v| !covered.contains(v))
                    .collect();
                if !missing.is_empty() {
                    self.error(
                        format!(
                            "non-exhaustive match over `{}`: missing variant(s) `{}` -- add a match arm for each, or a wildcard `_`",
                            name, missing.join("`, `")
                        ),
                        span,
                    );
                }
            }
            Ty::Bool => {
                let has_true = arms.iter().any(|a| matches!(a.pattern, Pattern::Bool(true)));
                let has_false = arms.iter().any(|a| matches!(a.pattern, Pattern::Bool(false)));
                if !(has_true && has_false) {
                    self.error("non-exhaustive match over `bool`: missing `true` and/or `false` -- add a wildcard `_` or cover both", span);
                }
            }
            Ty::Named(struct_name) => {
                let has_struct_catchall = arms.iter().any(|a| matches!(&a.pattern, Pattern::Struct(n, _) if n == struct_name));
                if !has_struct_catchall {
                    self.error(
                        format!("non-exhaustive match over `{}`: add a `{}(..)` pattern or a wildcard `_`", struct_name, struct_name),
                        span,
                    );
                }
            }
            _ => {
                self.error("non-exhaustive match: add a wildcard `_` arm to cover any remaining values", span);
            }
        }
    }

    fn check_match_arm(&mut self, arm: &MatchArm, scrutinee_expr: &TypedExpr, vars: &mut HashMap<String, Ty>) -> TypedMatchArm {
        let mut pattern = arm.pattern.clone();
        if let Pattern::Struct(struct_name, bindings) = &arm.pattern {
            // A pattern may name a generic template (`Box`) rather than an
            // already-concrete struct; resolve it to whichever concrete
            // monomorphization the scrutinee's own type was instantiated
            // from, so the same generic pattern syntax matches any
            // instantiation (mirrors the `Pattern::EnumVariant` case below).
            let resolved_name = self.resolve_pattern_struct_name(struct_name, scrutinee_expr);
            let scrutinee_ty = scrutinee_expr.clone().into_ty();
            if let Ty::Named(scrutinee_struct) = &scrutinee_ty {
                if scrutinee_struct != &resolved_name {
                    self.error(
                        format!("pattern `{}(..)` does not match scrutinee type `{}`", struct_name, scrutinee_struct),
                        arm.span,
                    );
                }
            } else {
                // The scrutinee's type isn't `Ty::Named` at all (`i32`,
                // `bool`, `Ty::Enum`, `List<T>`, a vector type, ...) --
                // previously this whole mismatch check was skipped whenever
                // the `if let` above simply didn't match, so a struct pattern
                // against a non-struct scrutinee type-checked cleanly and
                // only failed at the `clang` step (a GEP into a struct type
                // the scrutinee was never laid out as).
                self.error(
                    format!("pattern `{}(..)` does not match scrutinee type `{:?}`", struct_name, scrutinee_ty),
                    arm.span,
                );
            }
            match self.structs.get(&resolved_name).cloned() {
                Some(sdef) => {
                    if sdef.fields.len() != bindings.len() {
                        self.error(
                            format!(
                                "pattern `{}(..)` expects {} binding(s), found {}",
                                struct_name, sdef.fields.len(), bindings.len()
                            ),
                            arm.span,
                        );
                    }
                    for (bind_name, field) in bindings.iter().zip(sdef.fields.iter()) {
                        let fty = self.resolve_type(&field.ty).unwrap_or(Ty::Named("unknown".into()));
                        vars.insert(bind_name.clone(), fty);
                    }
                }
                None => {
                    let candidates: Vec<&str> = self.structs.keys().map(String::as_str).collect();
                    match suggest(struct_name, candidates) {
                        Some(close) => self.error_note(
                            format!("undefined struct `{}`", struct_name),
                            arm.span,
                            format!("did you mean `{}`?", close),
                        ),
                        None => self.error(format!("undefined struct `{}`", struct_name), arm.span),
                    }
                }
            }
            pattern = Pattern::Struct(resolved_name, bindings.clone());
        }
        if let Pattern::EnumVariant(enum_name, variant, bindings) = &arm.pattern {
            let resolved_name = self.resolve_pattern_enum_name(enum_name, scrutinee_expr);
            self.check_enum_variant_name(&resolved_name, variant, arm.span);
            let scrutinee_ty = scrutinee_expr.clone().into_ty();
            if let Ty::Enum(scrutinee_enum) = &scrutinee_ty {
                if scrutinee_enum != &resolved_name {
                    self.error(
                        format!("pattern `{}::{}` does not match scrutinee type `{}`", enum_name, variant, scrutinee_enum),
                        arm.span,
                    );
                }
            } else {
                // Same fix as the struct-pattern arm above: the scrutinee's
                // type isn't `Ty::Enum` at all, so this mismatch check used
                // to be silently skipped rather than flagged.
                self.error(
                    format!("pattern `{}::{}` does not match scrutinee type `{:?}`", enum_name, variant, scrutinee_ty),
                    arm.span,
                );
            }
            // A payload pattern's bindings destructure the variant's fields
            // in declaration order; bind each name to its field's resolved
            // type in the arm-local scope before checking the arm body.
            if !bindings.is_empty() {
                if let Some(vdef) = self.enums.get(&resolved_name).and_then(|e| e.variants.iter().find(|v| &v.name == variant)).cloned() {
                    if vdef.fields.len() != bindings.len() {
                        self.error(
                            format!(
                                "pattern `{}::{}(..)` expects {} binding(s), found {}",
                                enum_name, variant, vdef.fields.len(), bindings.len()
                            ),
                            arm.span,
                        );
                    }
                    for (bind_name, field) in bindings.iter().zip(vdef.fields.iter()) {
                        let fty = self.resolve_type(&field.ty).unwrap_or(Ty::Named("unknown".into()));
                        vars.insert(bind_name.clone(), fty);
                    }
                }
            }
            pattern = Pattern::EnumVariant(resolved_name, variant.clone(), bindings.clone());
        }
        let mut stmts = Vec::new();
        for stmt in &arm.body.stmts {
            if let Some(typed) = self.check_stmt(stmt, vars) {
                stmts.push(typed);
            }
        }
        // An arm's type is its trailing expression statement's type (the
        // value it contributes when this `match` is used as a
        // value-producing expression, phi-merged across arms by codegen);
        // an arm used purely for side effects (its last statement isn't a
        // bare expression) has no such value, so it stays `unknown`.
        let ty = match stmts.last() {
            Some(TypedStmt::Expr(e)) => e.clone().into_ty(),
            _ => Ty::Named("unknown".into()),
        };
        TypedMatchArm { pattern, body: TypedBlock { stmts, span: arm.span }, ty, span: arm.span }
    }

    /// If `name` is a generic struct template (e.g. `Box`) rather than an
    /// already-concrete struct, resolve it to the concrete monomorphized
    /// struct name the scrutinee's own type was instantiated from. Falls
    /// back to `name` unchanged when it's already concrete, undefined, or
    /// the scrutinee wasn't instantiated from this template (a mismatch
    /// reported separately by the caller).
    fn resolve_pattern_struct_name(&self, name: &str, scrutinee: &TypedExpr) -> String {
        if !self.generic_structs.contains_key(name) {
            return name.to_string();
        }
        if let Ty::Named(scrutinee_name) = scrutinee.clone().into_ty() {
            if self.mono_struct_of.get(&scrutinee_name).map(|(t, _)| t.as_str()) == Some(name) {
                return scrutinee_name;
            }
        }
        name.to_string()
    }

    /// Enum-variant counterpart of `resolve_pattern_struct_name`.
    fn resolve_pattern_enum_name(&self, name: &str, scrutinee: &TypedExpr) -> String {
        if !self.generic_enums.contains_key(name) {
            return name.to_string();
        }
        if let Ty::Enum(scrutinee_name) = scrutinee.clone().into_ty() {
            if self.mono_enum_of.get(&scrutinee_name).map(|(t, _)| t.as_str()) == Some(name) {
                return scrutinee_name;
            }
        }
        name.to_string()
    }

    /// Validate that `enum_name::variant` names a real enum variant,
    /// emitting a "did you mean" style error otherwise (an undefined enum
    /// name, or an undefined variant on a known enum).
    fn check_enum_variant_name(&mut self, enum_name: &str, variant: &str, span: Span) {
        match self.enums.get(enum_name) {
            Some(edef) => {
                if !edef.variants.iter().any(|v| v.name == variant) {
                    let candidates: Vec<&str> = edef.variants.iter().map(|v| v.name.as_str()).collect();
                    match suggest(variant, candidates) {
                        Some(close) => self.error_note(
                            format!("enum `{}` has no variant `{}`", enum_name, variant),
                            span,
                            format!("did you mean `{}`?", close),
                        ),
                        None => self.error(format!("enum `{}` has no variant `{}`", enum_name, variant), span),
                    }
                }
            }
            None => {
                let candidates: Vec<&str> = self.enums.keys().map(String::as_str).collect();
                match suggest(enum_name, candidates) {
                    Some(close) => self.error_note(
                        format!("undefined enum `{}`", enum_name),
                        span,
                        format!("did you mean `{}`?", close),
                    ),
                    None => self.error(format!("undefined enum `{}`", enum_name), span),
                }
            }
        }
    }
}
