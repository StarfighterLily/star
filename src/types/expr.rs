//! Expression type inference.

use std::collections::{HashMap, HashSet};

use crate::ast::*;
use crate::diagnostics::{suggest, Span};

use super::*;

impl Checker {
    /// If `expr` is a bare integer literal, or a unary `-` directly over
    /// one, returns its signed magnitude -- used by `Expr::Cast`'s literal
    /// fast path to look through the exact `-x as T`-is-`(-x) as T`
    /// precedence shape `Parser::parse_cast`'s doc comment describes,
    /// without generically recursing through `infer_expr` (which would
    /// apply `Expr::Int`'s default-`i32` range check before the cast ever
    /// gets a chance to widen it). `Expr::Int`'s own magnitude is always
    /// non-negative (see `Lexer::scan_number`'s doc comment), so `-v` here
    /// never overflows `i64`.
    fn cast_literal_magnitude(expr: &Expr) -> Option<i64> {
        match expr {
            Expr::Int(v, _) => Some(*v),
            Expr::Unary { op: UnOp::Neg, operand, .. } => {
                if let Expr::Int(v, _) = operand.as_ref() { Some(-*v) } else { None }
            }
            _ => None,
        }
    }

    /// The inclusive `[lo, hi]` range an `int_shape`-described integer type
    /// can hold, clamped to what an `i64`-backed literal token can actually
    /// represent (an unsigned 64-bit type's true upper bound, `u64::MAX`,
    /// exceeds `i64::MAX` and isn't reachable through this storage -- a
    /// separate, pre-existing limitation of `Lexer::scan_number`'s `i64`
    /// token storage, not one this cast fast path introduces).
    fn int_shape_range(width: u32, signed: bool) -> (i64, i64) {
        if signed {
            if width >= 64 { (i64::MIN, i64::MAX) } else { (-(1i64 << (width - 1)), (1i64 << (width - 1)) - 1) }
        } else if width >= 64 {
            (0, i64::MAX)
        } else {
            (0, (1i64 << width) - 1)
        }
    }

    pub(super) fn check_expr_infer(&mut self, expr: &Expr) -> TypedExpr {
        let mut dummy_vars = HashMap::new();
        self.infer_expr(expr, &mut dummy_vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))
    }

    pub(super) fn infer_expr(&mut self, expr: &Expr, vars: &mut HashMap<String, Ty>) -> Result<TypedExpr, ()> {
        match expr {
            Expr::Int(v, s) => {
                // A plain (un-cast) integer literal's type always defaults
                // to `Ty::Int` (`i32`) -- the lexer itself now only rejects
                // a magnitude that doesn't fit `i64` at all (see
                // `Lexer::scan_number`'s doc comment), deferring the
                // "does this fit the type it's actually used as" question
                // here. A literal that's the direct operand of a widening
                // `as <sized int type>` cast is special-cased in the
                // `Expr::Cast` arm below, before it ever reaches this arm,
                // so reaching here with an out-of-`i32`-range magnitude
                // means it's genuinely defaulting to `i32` and doesn't fit.
                if *v < i32::MIN as i64 || *v > i32::MAX as i64 {
                    self.error(format!("integer literal `{}` is too large for a 32-bit integer (max 2147483647)", v), *s);
                }
                Ok(TypedExpr::Int(*v, Ty::Int, *s))
            }
            Expr::Float(v, s) => Ok(TypedExpr::Float(*v, Ty::Float, *s)),
            Expr::Str(s, sp) => Ok(TypedExpr::Str(s.clone(), Ty::Str, *sp)),
            Expr::Bool(v, s) => Ok(TypedExpr::Bool(*v, Ty::Bool, *s)),
            Expr::Char(c, s) => Ok(TypedExpr::Char(*c, Ty::Char, *s)),
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
                    if let Ty::Map(key_ty, val_ty) = base_typed.clone().into_ty() {
                        return Ok(self.infer_map_method(base_typed, field, *key_ty, *val_ty, args, vars, *span));
                    }
                    if let Ty::Set(elem_ty) = base_typed.clone().into_ty() {
                        return Ok(self.infer_set_method(base_typed, field, *elem_ty, args, vars, *span));
                    }
                    if let Ty::Array(_, count) = base_typed.clone().into_ty() {
                        return Ok(self.infer_array_method(base_typed, field, count, args, vars, *span));
                    }
                    if let Ty::Ring(elem_ty, count) = base_typed.clone().into_ty() {
                        return Ok(self.infer_ring_method(base_typed, field, *elem_ty, count, args, vars, *span));
                    }
                    if let Ty::Table(elem_ty) = base_typed.clone().into_ty() {
                        return Ok(self.infer_table_method(base_typed, field, *elem_ty, args, vars, *span));
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
                            if let Some((param_tys, _, has_self)) = self.methods.get(&method_key).cloned() {
                                self.check_call_args(&param_tys, has_self, &arg_exprs, *span);
                            }
                            let ret_ty = self.methods.get(&method_key).and_then(|(_, ret, _)| ret.clone()).unwrap_or(Ty::Named("unknown".into()));
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
                    // Free functions (`self.functions`) never have a `self`
                    // receiver, so they're normalized to `has_self: false`
                    // here to share the same tuple shape as `self.methods`
                    // (whose `bool` reflects whether that specific method
                    // actually declared `self` -- see `check_call_args`'s
                    // call sites' doc comments for why this can't be
                    // inferred from the call's syntactic shape alone).
                    let sig: Option<(Vec<Ty>, Option<Ty>, bool)> = match &callee_expr {
                        TypedExpr::Ident { name, .. } => self.functions.get(name).cloned().map(|(p, r)| (p, r, false)),
                        TypedExpr::Field { base, field, .. } => {
                            if let Ty::Named(struct_name) = base.clone().into_ty() {
                                self.methods.get(&format!("{}#{}", struct_name, field)).cloned()
                                    .or_else(|| self.functions.get(field).cloned().map(|(p, r)| (p, r, false)))
                            } else {
                                self.functions.get(field).cloned().map(|(p, r)| (p, r, false))
                            }
                        }
                        _ => None,
                    };
                    match sig {
                        Some((param_tys, ret, has_self)) => {
                            self.check_call_args(&param_tys, has_self, &arg_exprs, *span);
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
                // `-2147483648` is the only legal way to spell `i32::MIN`:
                // the lexer stores the literal magnitude `2147483648`
                // verbatim (positive -- it fits `i64` fine, see
                // `Lexer::scan_number`'s doc comment), so intercept this
                // exact raw-AST shape -- a unary `-` directly over that one
                // magnitude -- before generically recursing into `operand`,
                // which would otherwise hit the `Expr::Int` arm's `i32`
                // bounds check and reject its own sanctioned case (that
                // literal's positive value doesn't itself fit `i32`).
                if matches!(op, UnOp::Neg) {
                    if let Expr::Int(v, _) = operand.as_ref() {
                        if *v == (i32::MAX as i64) + 1 {
                            return Ok(TypedExpr::Int(i32::MIN as i64, Ty::Int, *span));
                        }
                    }
                }
                let operand_expr = self.infer_expr(operand, vars)?;
                // `-x` preserves the operand's own numeric type (Int stays
                // Int, Float stays Float) rather than always widening to Int.
                let ty = match op {
                    // Reuse binary `-`'s own type-legality check (`Neg`
                    // lowers to exactly `0 - x` in `Codegen::emit_unary`) so
                    // an operand type that doesn't support subtraction
                    // (`str`, a struct, `List<T>`, `GenRef<T>`, ...) is
                    // rejected here with a real source location instead of
                    // silently passing the checker and only failing later
                    // with an unlocated "unsupported operand types" codegen
                    // error -- the exact same class of bug `infer_binop_ty`'s
                    // own doc comments describe already being fixed for
                    // binary `+ - * / %` and comparisons.
                    UnOp::Neg => {
                        let operand_ty = operand_expr.clone().into_ty();
                        self.infer_binop_ty(&BinOp::Sub, &operand_ty, &operand_ty, *span)
                    }
                    UnOp::Not => {
                        // `Codegen::emit_unary`'s `Not` case unconditionally
                        // emits `xor i1 true, <operand>`, assuming the
                        // operand is already `i1` -- the checker used to
                        // return `Ty::Bool` here regardless of the operand's
                        // real type, so `!5`/`!"x"`/`!my_struct` type-checked
                        // cleanly and only failed later with an unlocated
                        // "defined with type 'iN' but expected 'i1'" `clang`
                        // error. Same class of bug as `Neg` just above.
                        let operand_ty = operand_expr.clone().into_ty();
                        if operand_ty != Ty::Bool && !Self::is_placeholder_ty(&operand_ty) {
                            self.error(
                                format!("`!`/`not` operand must be `bool`, found `{:?}`", operand_ty),
                                *span,
                            );
                        }
                        Ty::Bool
                    }
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
                    // Same reasoning as `arm_vars` itself: an arm body's own
                    // `let mut`s must not leak their mutability into a
                    // sibling arm or the surrounding scope. `check_match_arm`
                    // checks its body via direct `check_stmt` calls (not
                    // `check_block_inner`), so this scoping has to happen
                    // here rather than being covered by that function's own.
                    let saved_mut_vars = self.mut_vars.clone();
                    let arm = self.check_match_arm(a, &scrutinee_expr, &mut arm_vars);
                    self.mut_vars = saved_mut_vars;
                    arm
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
                if name == "Map" {
                    return Ok(self.infer_map_new(type_args, &arg_exprs, *span));
                }
                if name == "Set" {
                    return Ok(self.infer_set_new(type_args, &arg_exprs, *span));
                }
                if name == "Table" {
                    return Ok(self.infer_table_new(type_args, &arg_exprs, *span));
                }
                if self.generic_structs.contains_key(name) {
                    return Ok(self.infer_generic_struct_lit(name, type_args, arg_exprs, *span));
                }
                let resolved_ty = self.resolve_type(&Type::Named(name.clone())).unwrap_or_else(|| Ty::Named(name.clone()));
                self.check_builtin_ctor_arity(&resolved_ty, name, &arg_exprs, *span);
                self.check_struct_ctor_args(name, &arg_exprs, *span);
                Ok(TypedExpr::StructLit { name: name.clone(), args: arg_exprs, ty: resolved_ty, span: *span })
            }
            Expr::If { cond, then_block, else_block, span } => {
                let cond_typed = self.infer_expr(cond, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                if !matches!(cond_typed.clone().into_ty(), Ty::Bool) {
                    self.error("if condition must be of type bool", cond.span());
                }
                let then_typed = self.check_block_inner(then_block, &mut vars.clone());
                let else_typed = else_block.as_ref().map(|b| self.check_block_inner(b, &mut vars.clone()));
                // Mirrors `Codegen::emit_stmts_value`'s exact notion of which
                // statement shapes contribute a value: a bare trailing
                // expression, or a `frame:` scope whose own trailing
                // statement does -- previously only the former was
                // recognized here, so an `if`-expression whose `then`
                // branch ended in a trailing `frame:` block (`if cond:
                // frame: let p = Point(1, 2); p`) inferred `void` instead
                // of `Point`, either rejecting sound code downstream or
                // (if reached via an explicit `return`) letting the
                // `check_frame_escapes` pass beneath it silently skip the
                // struct entirely (see `frame_escape_source_block`'s own
                // matching fix).
                let ty = Self::trailing_value_ty(&then_typed.stmts).unwrap_or_else(|| Ty::Named("void".into()));
                Ok(TypedExpr::If {
                    cond: Box::new(cond_typed),
                    then_block: then_typed,
                    else_block: else_typed,
                    ty,
                    span: *span,
                })
            }
            Expr::GenRefCreate { inner_ty, value, is_handle, span } => {
                let kind = if *is_handle { "Handle" } else { "GenRef" };
                let resolved_inner = self.resolve_type(inner_ty).unwrap_or(Ty::Named("unknown".into()));
                self.require_backing_arena(&resolved_inner, kind, *span);
                let value_typed = self.infer_expr(value, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                if !matches!(value_typed.clone().into_ty(), Ty::Int) {
                    self.error(format!("`{}<T>(..)` index must be `i32`", kind), *span);
                }
                Ok(TypedExpr::GenRefCreate { inner_ty: resolved_inner, value: Box::new(value_typed), is_handle: *is_handle, span: *span })
            }
            Expr::WrappingNew { inner_ty, value, span } => {
                let resolved_inner = self.resolve_type(inner_ty).unwrap_or(Ty::Named("unknown".into()));
                if resolved_inner.int_shape().is_none() && !Self::is_placeholder_ty(&resolved_inner) {
                    self.error(
                        format!("`Wrapping<T>` requires `T` to be an integer type, found `{:?}`", resolved_inner),
                        *span,
                    );
                }
                // A literal (optionally negated) that fits `resolved_inner`'s
                // range is accepted directly with that type, mirroring
                // `Expr::Cast`'s own literal fast path just above (`x as u8`
                // already lets a narrower-than-`i32`-range literal through
                // the same way) -- otherwise a bare literal argument (which
                // defaults to `Ty::Int`) would be rejected by the exact-type-
                // match check below for any `T` narrower than `i32`.
                if let Some(v) = Self::cast_literal_magnitude(value) {
                    if let Some((width, signed)) = resolved_inner.int_shape() {
                        let (lo, hi) = Self::int_shape_range(width, signed);
                        if v >= lo && v <= hi {
                            let lit = TypedExpr::Int(v, resolved_inner.clone(), *span);
                            return Ok(TypedExpr::WrappingNew { inner_ty: resolved_inner, value: Box::new(lit), span: *span });
                        }
                        self.error(
                            format!("integer literal `{}` does not fit in `Wrapping<{:?}>` (range {}..={})", v, resolved_inner, lo, hi),
                            *span,
                        );
                        let lit = TypedExpr::Int(v, resolved_inner.clone(), *span);
                        return Ok(TypedExpr::WrappingNew { inner_ty: resolved_inner, value: Box::new(lit), span: *span });
                    }
                }
                let value_typed = self.infer_expr(value, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                let value_ty = value_typed.clone().into_ty();
                if value_ty != resolved_inner && !Self::is_placeholder_ty(&value_ty) && !Self::is_placeholder_ty(&resolved_inner) {
                    self.error(
                        format!("`Wrapping<T>(..)` expected a value of type `{:?}`, found `{:?}` -- use `as` to cast", resolved_inner, value_ty),
                        *span,
                    );
                }
                Ok(TypedExpr::WrappingNew { inner_ty: resolved_inner, value: Box::new(value_typed), span: *span })
            }
            Expr::FixedNew { bits, frac, value, span } => {
                if !matches!(bits, 8 | 16 | 32 | 64) {
                    self.error(format!("`Fixed<{}, {}>`'s bit width must be one of 8, 16, 32, 64", bits, frac), *span);
                } else if *frac >= *bits {
                    self.error(
                        format!("`Fixed<{}, {}>`'s fractional-bit count must be less than its bit width", bits, frac),
                        *span,
                    );
                }
                let value_typed = self.infer_expr(value, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                let value_ty = value_typed.clone().into_ty();
                let ok = value_ty.int_shape().is_some() || matches!(value_ty, Ty::Float | Ty::F64) || Self::is_placeholder_ty(&value_ty);
                if !ok {
                    self.error(
                        format!("`Fixed<Bits, Frac>(..)` expects an integer or float value, found `{:?}`", value_ty),
                        *span,
                    );
                }
                Ok(TypedExpr::FixedNew { bits: *bits, frac: *frac, value: Box::new(value_typed), span: *span })
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
                        } else {
                            self.check_enum_variant_ctor_args(enum_name, variant, &vdef.fields, &arg_exprs, *span);
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
                        self.require_backing_arena(&inner, "GenRef", *span);
                        Ok(TypedExpr::GenRefIndex { base: Box::new(base_expr), index: Box::new(index_expr), ty: *inner, span: *span })
                    }
                    // `Handle<T>` dereferences through the exact same
                    // `TypedExpr::GenRefIndex` node/codegen as `GenRef<T>` --
                    // see `Ty::Handle`'s doc comment; the only difference is
                    // which nominal wrapper type `base` had.
                    Ty::Handle(inner) => {
                        self.require_backing_arena(&inner, "Handle", *span);
                        Ok(TypedExpr::GenRefIndex { base: Box::new(base_expr), index: Box::new(index_expr), ty: *inner, span: *span })
                    }
                    Ty::List(inner) => {
                        Ok(TypedExpr::ListIndex { base: Box::new(base_expr), index: Box::new(index_expr), ty: *inner, span: *span })
                    }
                    Ty::Array(inner, _) => {
                        Ok(TypedExpr::ArrayIndex { base: Box::new(base_expr), index: Box::new(index_expr), ty: *inner, span: *span })
                    }
                    Ty::Ring(inner, _) => {
                        Ok(TypedExpr::RingIndex { base: Box::new(base_expr), index: Box::new(index_expr), ty: *inner, span: *span })
                    }
                    Ty::Table(inner) => {
                        Ok(TypedExpr::TableIndex { base: Box::new(base_expr), index: Box::new(index_expr), ty: *inner, span: *span })
                    }
                    // `s[i]` -- a bounds-checked byte read (0-255 as `i32`),
                    // not a Python-style length-1 substring; see
                    // `TypedExpr::StrIndex`'s doc comment.
                    Ty::Str => {
                        Ok(TypedExpr::StrIndex { base: Box::new(base_expr), index: Box::new(index_expr), ty: Ty::Int, span: *span })
                    }
                    other => {
                        self.error(format!("`[..]` indexing requires a `GenRef<T>`, `Handle<T>`, `List<T>`, `[T; N]`, `Ring<T,N>`, `Table<T>`, or `str`, found `{:?}`", other), *span);
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
                // Saved/restored around the whole closure body (not just
                // covered by `check_block_inner`'s own internal scoping)
                // because a lambda parameter can shadow an outer `mut`
                // variable of the same name with a non-`mut` one (or vice
                // versa) -- that shadowing must not survive past the end of
                // this closure literal.
                let saved_mut_vars = self.mut_vars.clone();
                for p in &typed_params {
                    inner_vars.insert(p.name.clone(), p.ty.clone());
                    if p.is_mut {
                        self.mut_vars.insert(p.name.clone());
                    } else {
                        self.mut_vars.remove(&p.name);
                    }
                }
                // A closure's return type is inferred *from* its body below
                // (its trailing expression, unless explicitly declared) --
                // checking `return` statements against it here would be
                // circular, so return-type checking is suspended for the
                // duration of this body (see `current_ret_ty`'s doc comment).
                let saved_ret_ty = std::mem::replace(&mut self.current_ret_ty, None);
                let body_typed = self.check_block_inner(body, &mut inner_vars);
                self.current_ret_ty = saved_ret_ty;
                self.mut_vars = saved_mut_vars;
                // A declared `-> Ret` is used as-is; otherwise (mirroring the
                // `if`-expression's own type inference) the closure's return
                // type is whatever its trailing expression evaluates to, or
                // the `unknown` placeholder codegen already treats as `void`
                // for a body with no trailing value.
                let ret_ty = match ret {
                    Some(t) => self.resolve_type(t).unwrap_or(Ty::Named("unknown".into())),
                    // Mirrors `Codegen::emit_stmts_value`'s exact notion of
                    // which statement shapes contribute a value (see the
                    // matching fix on the `if`-expression's own type
                    // inference above) -- a closure body ending in a
                    // trailing `frame:` block previously inferred `unknown`
                    // (void) instead of that block's real trailing type.
                    None => Self::trailing_value_ty(&body_typed.stmts).unwrap_or_else(|| Ty::Named("unknown".into())),
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
            Expr::Try { inner, span } => Ok(self.infer_try(inner, vars, *span)),
            Expr::TupleLit(elems, span) => {
                let typed: Vec<TypedExpr> = elems.iter()
                    .map(|e| self.infer_expr(e, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into()))))
                    .collect();
                let elem_tys: Vec<Ty> = typed.iter().map(|e| e.clone().into_ty()).collect();
                Ok(TypedExpr::TupleLit { elems: typed, ty: Ty::Tuple(elem_tys), span: *span })
            }
            Expr::TupleIndex { base, index, span } => {
                let base_typed = self.infer_expr(base, vars)?;
                let base_ty = base_typed.clone().into_ty();
                let ty = match &base_ty {
                    Ty::Tuple(elems) => match elems.get(*index) {
                        Some(t) => t.clone(),
                        None => {
                            self.error(
                                format!("tuple index `{}` out of range for a {}-element tuple `{:?}`", index, elems.len(), base_ty),
                                *span,
                            );
                            Ty::Named("unknown".into())
                        }
                    },
                    _ => {
                        self.error(format!("`.{}` requires a tuple, found `{:?}`", index, base_ty), *span);
                        Ty::Named("unknown".into())
                    }
                };
                Ok(TypedExpr::TupleIndex { base: Box::new(base_typed), index: *index, ty, span: *span })
            }
            Expr::ArrayRepeat { value, count, span } => {
                let value_typed = self.infer_expr(value, vars)?;
                let elem_ty = value_typed.clone().into_ty();
                Ok(TypedExpr::ArrayRepeat { value: Box::new(value_typed), count: *count, elem_ty, span: *span })
            }
            Expr::RingNew { elem_ty, count, span } => {
                let elem_ty = self.resolve_type(elem_ty).unwrap_or(Ty::Named("unknown".into()));
                Ok(TypedExpr::RingNew { elem_ty, count: *count, span: *span })
            }
            Expr::Cast { expr, ty, span } => {
                let target = self.resolve_type(ty).unwrap_or(Ty::Named("unknown".into()));
                // A literal (optionally directly negated) that's the
                // operand of a widening `as` cast is special-cased here,
                // before it reaches the generic `infer_expr` call below
                // (which types a bare literal as `i32` by default and
                // rejects anything outside `i32`'s range) -- otherwise
                // `5000000000 as i64` would be rejected for not fitting
                // `i32` before the cast ever got a chance to widen it,
                // defeating the entire reason `i64`/`u64` exist
                // (`docs/design.md`'s "large-world coordinates" numeric-
                // widths motivation). Only takes this path when the
                // literal's magnitude doesn't already fit `i32` -- values
                // that do keep flowing through the generic `Ty::Int` +
                // `Cast` path unchanged, preserving existing truncating-
                // narrow-cast semantics like `200 as i8`.
                if let Some(v) = Self::cast_literal_magnitude(expr) {
                    if v < i32::MIN as i64 || v > i32::MAX as i64 {
                        if let Some((width, signed)) = target.int_shape() {
                            let (lo, hi) = Self::int_shape_range(width, signed);
                            if v >= lo && v <= hi {
                                return Ok(TypedExpr::Int(v, target.clone(), *span));
                            }
                            self.error(
                                format!("integer literal `{}` does not fit in `{:?}` (range {}..={})", v, target, lo, hi),
                                *span,
                            );
                            return Ok(TypedExpr::Int(v, target.clone(), *span));
                        }
                    }
                }
                let inner = self.infer_expr(expr, vars)?;
                let inner_ty = inner.clone().into_ty();
                // `as` supports conversions between any two numeric types
                // (narrowing/widening/sign-reinterpreting, matching Rust's
                // own infallible truncating `as`) and between a numeric
                // integer type and `char` (a bare codepoint reinterpretation
                // -- like Rust's `u8 as char`/`u32 as char`, this trusts the
                // caller to pass a valid codepoint rather than validating it,
                // consistent with this compiler's existing lack of a
                // fallible-conversion/`Result`-returning cast path).
                // `Wrapping<T> <-> T` is a free bit-preserving relabel (same
                // underlying LLVM integer, see `Ty::Wrapping`'s doc comment);
                // `Fixed<Bits,Frac> <-> float/f64` is a true scaled
                // conversion (see `Ty::Fixed`'s doc comment), not a bit
                // reinterpret -- deliberately not folded into `is_numeric()`
                // (neither type is "numeric" for `sqrt`/`abs`/FFI purposes),
                // so both get their own explicit pairing here instead.
                let wrapping_ok = match (&inner_ty, &target) {
                    (Ty::Wrapping(w), t) => **w == *t,
                    (t, Ty::Wrapping(w)) => *t == **w,
                    _ => false,
                };
                let fixed_ok = matches!(
                    (&inner_ty, &target),
                    (Ty::Fixed(..), Ty::Float | Ty::F64) | (Ty::Float | Ty::F64, Ty::Fixed(..))
                );
                let ok = (inner_ty.is_numeric() && target.is_numeric())
                    || (inner_ty.is_numeric() && target == Ty::Char)
                    || (inner_ty == Ty::Char && target.is_numeric())
                    || (inner_ty == Ty::Char && target == Ty::Char)
                    || wrapping_ok
                    || fixed_ok;
                if !ok && !Self::is_placeholder_ty(&inner_ty) && !Self::is_placeholder_ty(&target) {
                    self.error(
                        format!(
                            "cannot cast `{:?}` as `{:?}` -- `as` only supports conversions between numeric types and `char`",
                            inner_ty, target
                        ),
                        *span,
                    );
                }
                Ok(TypedExpr::Cast { expr: Box::new(inner), ty: target, span: *span })
            }
        }
    }

    /// Desugar `inner?` into a `TypedExpr::Match` over `inner`'s `Option`/
    /// `Result` variants, reusing the exact tagged-union enum/pattern
    /// machinery an ordinary hand-written `match` already produces -- there
    /// is no dedicated codegen path for `Expr::Try` at all (see its doc
    /// comment in `crate::ast`). The "unwrap" arm (`Some`/`Ok`) evaluates to
    /// the payload value; the "propagate" arm (`None`/`Err`) `return`s the
    /// same variant back out of the enclosing function unchanged.
    fn infer_try(&mut self, inner: &Expr, vars: &mut HashMap<String, Ty>, span: Span) -> TypedExpr {
        let inner_expr = self.infer_expr(inner, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
        let inner_ty = inner_expr.clone().into_ty();
        let Ty::Enum(mangled) = &inner_ty else {
            self.error(format!("`?` requires an `Option<T>` or `Result<T,E>`, found `{:?}`", inner_ty), span);
            return TypedExpr::Error(Ty::Named("infer_error".into()));
        };
        let Some((template, _ty_args)) = self.mono_enum_of.get(mangled).cloned() else {
            self.error(format!("`?` requires an `Option<T>` or `Result<T,E>`, found `{}`", mangled), span);
            return TypedExpr::Error(Ty::Named("infer_error".into()));
        };
        if template != "Option" && template != "Result" {
            self.error(format!("`?` requires an `Option<T>` or `Result<T,E>`, found `{}`", mangled), span);
            return TypedExpr::Error(Ty::Named("infer_error".into()));
        }
        // Star has no `From`/`Into` conversion machinery to reconcile e.g. a
        // `Result<T,E1>` being propagated out of a `Result<T,E2>`-returning
        // function, so `?`'s enum type must exactly match the enclosing
        // function's declared return type.
        match &self.current_ret_ty {
            None => self.error("`?` cannot be used inside a closure, which has no declared return type to propagate out of", span),
            Some(None) => self.error(
                format!("`?` requires the enclosing function to declare a return type of `{}`", mangled),
                span,
            ),
            Some(Some(Ty::Enum(ret_mangled))) if ret_mangled == mangled => {}
            Some(Some(other)) => self.error(
                format!("`?` on `{}` requires the enclosing function to return the exact same type, found `{:?}`", mangled, other),
                span,
            ),
        }
        let (ok_variant, err_variant) = if template == "Option" { ("Some", "None") } else { ("Ok", "Err") };
        let variant_field_ty = |this: &mut Self, variant: &str| -> Ty {
            this.enums.get(mangled)
                .and_then(|e| e.variants.iter().find(|v| v.name == variant).cloned())
                .and_then(|v| v.fields.first().cloned())
                .and_then(|f| this.resolve_type(&f.ty))
                .unwrap_or(Ty::Named("unknown".into()))
        };
        let value_ty = variant_field_ty(self, ok_variant);
        let ok_arm = TypedMatchArm {
            pattern: Pattern::EnumVariant(mangled.clone(), ok_variant.to_string(), vec!["__try_val".to_string()]),
            body: TypedBlock {
                stmts: vec![TypedStmt::Expr(TypedExpr::Ident { name: "__try_val".to_string(), ty: value_ty.clone(), span })],
                span,
            },
            ty: value_ty.clone(),
            span,
        };
        let (err_bindings, propagated_args) = if template == "Option" {
            (Vec::new(), Vec::new())
        } else {
            let err_ty = variant_field_ty(self, "Err");
            (
                vec!["__try_err".to_string()],
                vec![TypedExpr::Ident { name: "__try_err".to_string(), ty: err_ty, span }],
            )
        };
        let err_arm = TypedMatchArm {
            pattern: Pattern::EnumVariant(mangled.clone(), err_variant.to_string(), err_bindings),
            body: TypedBlock {
                stmts: vec![TypedStmt::Return {
                    value: Some(TypedExpr::EnumVariant {
                        enum_name: mangled.clone(),
                        variant: err_variant.to_string(),
                        args: propagated_args,
                        ty: Ty::Enum(mangled.clone()),
                        span,
                    }),
                    span,
                }],
                span,
            },
            ty: Ty::Named("unknown".into()),
            span,
        };
        TypedExpr::Match { scrutinee: Box::new(inner_expr), arms: vec![ok_arm, err_arm], ty: value_ty, span }
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
                self.check_mut_receiver(&base, "push", span);
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
                self.check_mut_receiver(&base, "pop", span);
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

    /// `arr.len()`: always `count`, the array's static, compile-time-known
    /// element count -- unlike `infer_list_method`'s `Len`, there's no
    /// runtime buffer to read a length out of, so this is the only method
    /// an array supports (no `push`/`pop`: an array's size is fixed, part
    /// of its type).
    fn infer_array_method(&mut self, base: TypedExpr, method: &str, count: u64, args: &[Expr], vars: &mut HashMap<String, Ty>, span: Span) -> TypedExpr {
        let arg_exprs: Vec<TypedExpr> = args.iter().map(|a| self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))).collect();
        match method {
            "len" => {
                if !arg_exprs.is_empty() {
                    self.error(format!("`len()` expects 0 arguments, found {}", arg_exprs.len()), span);
                }
                TypedExpr::ArrayLen { base: Box::new(base), count, span }
            }
            _ => {
                self.error(format!("no method `{}` on `[T; N]` (expected `len`)", method), span);
                TypedExpr::Error(Ty::Named("infer_error".into()))
            }
        }
    }

    /// Type-check a `Ring<T,N>` method call (`push`/`pop`/`len`), called from
    /// `Expr::Call`'s special-case above once `base`'s type is known to be
    /// `Ty::Ring(elem_ty, count)`. Mirrors `infer_list_method` almost exactly
    /// -- `count` (the ring's static capacity) isn't needed for type-checking
    /// any of the three methods, only by codegen (see
    /// `crate::codegen::ring`), so it's accepted here purely to match the
    /// dispatch site's `Ty::Ring(elem_ty, count)` destructure.
    fn infer_ring_method(&mut self, base: TypedExpr, method: &str, elem_ty: Ty, _count: u64, args: &[Expr], vars: &mut HashMap<String, Ty>, span: Span) -> TypedExpr {
        let arg_exprs: Vec<TypedExpr> = args.iter().map(|a| self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))).collect();
        match method {
            "push" => {
                self.check_mut_receiver(&base, "push", span);
                if arg_exprs.len() != 1 {
                    self.error(format!("`push(..)` expects 1 argument, found {}", arg_exprs.len()), span);
                } else {
                    let arg_ty = arg_exprs[0].clone().into_ty();
                    if arg_ty != elem_ty {
                        self.error(format!("`push(..)` expects `{:?}`, found `{:?}`", elem_ty, arg_ty), span);
                    }
                }
                TypedExpr::RingMethod { base: Box::new(base), method: RingMethod::Push, args: arg_exprs, ty: Ty::Named("unknown".into()), span }
            }
            "pop" => {
                self.check_mut_receiver(&base, "pop", span);
                if !arg_exprs.is_empty() {
                    self.error(format!("`pop()` expects 0 arguments, found {}", arg_exprs.len()), span);
                }
                TypedExpr::RingMethod { base: Box::new(base), method: RingMethod::Pop, args: Vec::new(), ty: elem_ty, span }
            }
            "len" => {
                if !arg_exprs.is_empty() {
                    self.error(format!("`len()` expects 0 arguments, found {}", arg_exprs.len()), span);
                }
                TypedExpr::RingMethod { base: Box::new(base), method: RingMethod::Len, args: Vec::new(), ty: Ty::Int, span }
            }
            _ => {
                self.error(format!("no method `{}` on `Ring<..>` (expected `push`, `pop`, or `len`)", method), span);
                TypedExpr::Error(Ty::Named("infer_error".into()))
            }
        }
    }

    /// `Table<T>()`: an empty struct-of-arrays table construction, mirroring
    /// `infer_list_new` -- requires an explicit `<T>` turbofish, and `T`
    /// must resolve to a plain declared `struct` (enforced by
    /// `Checker::resolve_type`'s own `"Table"` branch, the same place
    /// `Map`'s key hashability is enforced).
    fn infer_table_new(&mut self, type_args: &[Type], arg_exprs: &[TypedExpr], span: Span) -> TypedExpr {
        if !arg_exprs.is_empty() {
            self.error("`Table<T>()` takes no arguments", span);
        }
        let elem_ty = match type_args.first() {
            Some(t) => self.resolve_type(t).unwrap_or(Ty::Named("unknown".into())),
            None => {
                self.error("`Table<T>()` needs an explicit type argument, e.g. `Table<Player>()`", span);
                Ty::Named("unknown".into())
            }
        };
        // Mirrors `Checker::resolve_type`'s own `"Table"` branch (which
        // validates this same requirement for a `Table<T>` *type
        // annotation*, e.g. `let e: Table<Enemy>`) -- that branch only ever
        // sees `Type::Generic("Table", [inner])` as a whole, so it can't
        // catch this turbofish-construction call site, which resolves the
        // single type argument `inner` directly instead. Skipped for the
        // `unknown` placeholder (an error was already reported resolving
        // `inner` itself, e.g. an undefined type name).
        let is_struct = matches!(&elem_ty, Ty::Named(n) if self.structs.contains_key(n));
        if !is_struct && !matches!(&elem_ty, Ty::Named(n) if n == "unknown") {
            self.error(format!("`Table<T>()` requires `T` to be a struct type, found `{:?}`", elem_ty), span);
        }
        TypedExpr::TableNew { elem_ty, span }
    }

    /// Type-check a `Table<T>` method call (`push`/`pop`/`len`), called from
    /// `Expr::Call`'s special-case above once `base`'s type is known to be
    /// `Ty::Table(elem_ty)`. Mirrors `infer_list_method` exactly -- `push`'s
    /// argument and `pop`'s return are both the whole element type `T`
    /// (`Ty::Named`), decomposed into/reassembled from every column by
    /// codegen (`crate::codegen::table`), not visible at this layer.
    fn infer_table_method(&mut self, base: TypedExpr, method: &str, elem_ty: Ty, args: &[Expr], vars: &mut HashMap<String, Ty>, span: Span) -> TypedExpr {
        let arg_exprs: Vec<TypedExpr> = args.iter().map(|a| self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))).collect();
        match method {
            "push" => {
                self.check_mut_receiver(&base, "push", span);
                if arg_exprs.len() != 1 {
                    self.error(format!("`push(..)` expects 1 argument, found {}", arg_exprs.len()), span);
                } else {
                    let arg_ty = arg_exprs[0].clone().into_ty();
                    if arg_ty != elem_ty {
                        self.error(format!("`push(..)` expects `{:?}`, found `{:?}`", elem_ty, arg_ty), span);
                    }
                }
                TypedExpr::TableMethod { base: Box::new(base), method: TableMethod::Push, args: arg_exprs, ty: Ty::Named("unknown".into()), span }
            }
            "pop" => {
                self.check_mut_receiver(&base, "pop", span);
                if !arg_exprs.is_empty() {
                    self.error(format!("`pop()` expects 0 arguments, found {}", arg_exprs.len()), span);
                }
                TypedExpr::TableMethod { base: Box::new(base), method: TableMethod::Pop, args: Vec::new(), ty: elem_ty, span }
            }
            "len" => {
                if !arg_exprs.is_empty() {
                    self.error(format!("`len()` expects 0 arguments, found {}", arg_exprs.len()), span);
                }
                TypedExpr::TableMethod { base: Box::new(base), method: TableMethod::Len, args: Vec::new(), ty: Ty::Int, span }
            }
            _ => {
                self.error(format!("no method `{}` on `Table<..>` (expected `push`, `pop`, or `len`)", method), span);
                TypedExpr::Error(Ty::Named("infer_error".into()))
            }
        }
    }

    /// `Map<K,V>()`: an empty map construction, mirroring `infer_list_new` --
    /// requires an explicit `<K,V>` turbofish, since there's nothing to
    /// infer a type from otherwise.
    fn infer_map_new(&mut self, type_args: &[Type], arg_exprs: &[TypedExpr], span: Span) -> TypedExpr {
        if !arg_exprs.is_empty() {
            self.error("`Map<K,V>()` takes no arguments", span);
        }
        if type_args.len() != 2 {
            self.error("`Map<K,V>()` needs explicit type arguments, e.g. `Map<str, i32>()`", span);
            return TypedExpr::Error(Ty::Named("infer_error".into()));
        }
        let key_ty = self.resolve_type(&type_args[0]).unwrap_or(Ty::Named("unknown".into()));
        let val_ty = self.resolve_type(&type_args[1]).unwrap_or(Ty::Named("unknown".into()));
        // `resolve_type` only runs `Checker::check_hashable_ty` when *itself*
        // resolving a `Map<K,V>` type reference (a param/field/return type
        // spelled out directly) -- here it's invoked on `key_ty`/`val_ty`
        // individually (e.g. `Type::Named("i32")`, `Type::Generic("List",
        // ...)`), never on a `Type::Generic("Map", ...)` node, so that
        // branch's check never runs for a bare `Map<K,V>()` construction.
        // Re-check explicitly so `Map<List<i32>, i32>()` is still rejected.
        let mut visited = HashSet::new();
        self.check_hashable_ty(&key_ty, &mut visited);
        TypedExpr::MapNew { key_ty, val_ty, span }
    }

    /// `Set<T>()`: an empty set construction, mirroring `infer_list_new`.
    fn infer_set_new(&mut self, type_args: &[Type], arg_exprs: &[TypedExpr], span: Span) -> TypedExpr {
        if !arg_exprs.is_empty() {
            self.error("`Set<T>()` takes no arguments", span);
        }
        let elem_ty = match type_args.first() {
            Some(t) => self.resolve_type(t).unwrap_or(Ty::Named("unknown".into())),
            None => {
                self.error("`Set<T>()` needs an explicit type argument, e.g. `Set<i32>()`", span);
                Ty::Named("unknown".into())
            }
        };
        // See `infer_map_new`'s matching comment on why this re-check is
        // necessary here too.
        let mut visited = HashSet::new();
        self.check_hashable_ty(&elem_ty, &mut visited);
        TypedExpr::SetNew { elem_ty, span }
    }

    /// Type-check a `Map<K,V>` method call (`insert`/`get`/`remove`/
    /// `contains`/`len`), called from `Expr::Call`'s special-case above once
    /// `base`'s type is known to be `Ty::Map(key_ty, val_ty)`. `get`/
    /// `remove` return `Option<V>` -- a real, checker-instantiated
    /// monomorphization of the builtin `Option<T>` template (see
    /// `Checker::instantiate_enum`), the same as if the user had written
    /// `Option<V>` themselves.
    fn infer_map_method(&mut self, base: TypedExpr, method: &str, key_ty: Ty, val_ty: Ty, args: &[Expr], vars: &mut HashMap<String, Ty>, span: Span) -> TypedExpr {
        let arg_exprs: Vec<TypedExpr> = args.iter().map(|a| self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))).collect();
        let option_of = |this: &mut Self, ty: Ty| -> Ty { Ty::Enum(this.instantiate_enum("Option", &[ty])) };
        match method {
            "insert" => {
                self.check_mut_receiver(&base, "insert", span);
                if arg_exprs.len() != 2 {
                    self.error(format!("`insert(..)` expects 2 arguments, found {}", arg_exprs.len()), span);
                } else {
                    let k = arg_exprs[0].clone().into_ty();
                    let v = arg_exprs[1].clone().into_ty();
                    if k != key_ty {
                        self.error(format!("`insert(..)` key expects `{:?}`, found `{:?}`", key_ty, k), span);
                    }
                    if v != val_ty {
                        self.error(format!("`insert(..)` value expects `{:?}`, found `{:?}`", val_ty, v), span);
                    }
                }
                TypedExpr::MapMethod { base: Box::new(base), method: MapMethod::Insert, args: arg_exprs, ty: Ty::Named("unknown".into()), span }
            }
            "get" => {
                if arg_exprs.len() != 1 {
                    self.error(format!("`get(..)` expects 1 argument, found {}", arg_exprs.len()), span);
                } else if arg_exprs[0].clone().into_ty() != key_ty {
                    self.error(format!("`get(..)` expects a key of `{:?}`, found `{:?}`", key_ty, arg_exprs[0].clone().into_ty()), span);
                }
                let ret_ty = option_of(self, val_ty);
                TypedExpr::MapMethod { base: Box::new(base), method: MapMethod::Get, args: arg_exprs, ty: ret_ty, span }
            }
            "remove" => {
                self.check_mut_receiver(&base, "remove", span);
                if arg_exprs.len() != 1 {
                    self.error(format!("`remove(..)` expects 1 argument, found {}", arg_exprs.len()), span);
                } else if arg_exprs[0].clone().into_ty() != key_ty {
                    self.error(format!("`remove(..)` expects a key of `{:?}`, found `{:?}`", key_ty, arg_exprs[0].clone().into_ty()), span);
                }
                let ret_ty = option_of(self, val_ty);
                TypedExpr::MapMethod { base: Box::new(base), method: MapMethod::Remove, args: arg_exprs, ty: ret_ty, span }
            }
            "contains" => {
                if arg_exprs.len() != 1 {
                    self.error(format!("`contains(..)` expects 1 argument, found {}", arg_exprs.len()), span);
                } else if arg_exprs[0].clone().into_ty() != key_ty {
                    self.error(format!("`contains(..)` expects a key of `{:?}`, found `{:?}`", key_ty, arg_exprs[0].clone().into_ty()), span);
                }
                TypedExpr::MapMethod { base: Box::new(base), method: MapMethod::Contains, args: arg_exprs, ty: Ty::Bool, span }
            }
            "len" => {
                if !arg_exprs.is_empty() {
                    self.error(format!("`len()` expects 0 arguments, found {}", arg_exprs.len()), span);
                }
                TypedExpr::MapMethod { base: Box::new(base), method: MapMethod::Len, args: Vec::new(), ty: Ty::Int, span }
            }
            _ => {
                self.error(format!("no method `{}` on `Map<..>` (expected `insert`, `get`, `remove`, `contains`, or `len`)", method), span);
                TypedExpr::Error(Ty::Named("infer_error".into()))
            }
        }
    }

    /// Type-check a `Set<T>` method call (`insert`/`remove`/`contains`/
    /// `len`), mirroring `infer_map_method`.
    fn infer_set_method(&mut self, base: TypedExpr, method: &str, elem_ty: Ty, args: &[Expr], vars: &mut HashMap<String, Ty>, span: Span) -> TypedExpr {
        let arg_exprs: Vec<TypedExpr> = args.iter().map(|a| self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))).collect();
        match method {
            "insert" => {
                self.check_mut_receiver(&base, "insert", span);
                if arg_exprs.len() != 1 {
                    self.error(format!("`insert(..)` expects 1 argument, found {}", arg_exprs.len()), span);
                } else if arg_exprs[0].clone().into_ty() != elem_ty {
                    self.error(format!("`insert(..)` expects `{:?}`, found `{:?}`", elem_ty, arg_exprs[0].clone().into_ty()), span);
                }
                TypedExpr::SetMethod { base: Box::new(base), method: SetMethod::Insert, args: arg_exprs, ty: Ty::Bool, span }
            }
            "remove" => {
                self.check_mut_receiver(&base, "remove", span);
                if arg_exprs.len() != 1 {
                    self.error(format!("`remove(..)` expects 1 argument, found {}", arg_exprs.len()), span);
                } else if arg_exprs[0].clone().into_ty() != elem_ty {
                    self.error(format!("`remove(..)` expects `{:?}`, found `{:?}`", elem_ty, arg_exprs[0].clone().into_ty()), span);
                }
                TypedExpr::SetMethod { base: Box::new(base), method: SetMethod::Remove, args: arg_exprs, ty: Ty::Bool, span }
            }
            "contains" => {
                if arg_exprs.len() != 1 {
                    self.error(format!("`contains(..)` expects 1 argument, found {}", arg_exprs.len()), span);
                } else if arg_exprs[0].clone().into_ty() != elem_ty {
                    self.error(format!("`contains(..)` expects `{:?}`, found `{:?}`", elem_ty, arg_exprs[0].clone().into_ty()), span);
                }
                TypedExpr::SetMethod { base: Box::new(base), method: SetMethod::Contains, args: arg_exprs, ty: Ty::Bool, span }
            }
            "len" => {
                if !arg_exprs.is_empty() {
                    self.error(format!("`len()` expects 0 arguments, found {}", arg_exprs.len()), span);
                }
                TypedExpr::SetMethod { base: Box::new(base), method: SetMethod::Len, args: Vec::new(), ty: Ty::Int, span }
            }
            _ => {
                self.error(format!("no method `{}` on `Set<..>` (expected `insert`, `remove`, `contains`, or `len`)", method), span);
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
    /// `Mat4(row0,row1,row2,row3)`). No-op for user-defined structs
    /// (`Ty::Named`) -- those are validated separately, by
    /// `check_struct_ctor_args`.
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

    /// Validate a struct literal's argument count and per-argument types
    /// against the struct's declared fields, in declaration order (positional
    /// construction, no named-argument reordering) -- the same per-argument
    /// check `check_call_args` already applies to an ordinary function call.
    /// Previously entirely absent for ordinary (`Ty::Named`) struct
    /// construction -- see `check_builtin_ctor_arity`'s doc comment, which
    /// only ever validated the four builtin vec/mat literal forms and
    /// explicitly no-ops for everything else. Without this, a swapped- or
    /// wrong-typed constructor argument (`Item(count, kind)` against
    /// `struct Item: kind: Color, count: i32`) type-checked cleanly and
    /// either silently miscompiled (same-width fields swapped, e.g. two
    /// `i32`s) or produced invalid LLVM IR the `clang` step rejected with no
    /// Star-level diagnostic pointing at the offending call -- `crate::
    /// codegen::expr`'s `StructLit` codegen stores each argument positionally
    /// using the struct's declared field type at that index, not the
    /// argument's own inferred type, so a mismatch here is a real, silent
    /// codegen hazard rather than a merely cosmetic gap. A no-op if `name`
    /// isn't a known plain struct (the builtin vec/mat forms and generic
    /// structs are validated by their own dedicated paths instead).
    fn check_struct_ctor_args(&mut self, name: &str, arg_exprs: &[TypedExpr], span: Span) {
        let Some(sdef) = self.structs.get(name).cloned() else { return };
        // A `sequence`'s desugared struct carries extra fields (hoisted
        // locals, `state`) beyond its declared parameters -- see
        // `sequence_param_counts`'s doc comment -- so its constructor call
        // is only ever expected to supply that leading parameter count, not
        // the struct's full field list.
        let expected_len = self.sequence_param_counts.get(name).copied().unwrap_or(sdef.fields.len());
        if expected_len != arg_exprs.len() {
            self.error(
                format!("`{}(..)` expects {} argument(s), found {}", name, expected_len, arg_exprs.len()),
                span,
            );
            return;
        }
        for (i, (f, a)) in sdef.fields.iter().zip(arg_exprs.iter()).enumerate() {
            let declared = self.resolve_type(&f.ty).unwrap_or(Ty::Named("unknown".into()));
            let actual = a.clone().into_ty();
            if !Self::types_compatible(&declared, &actual) {
                self.error(
                    format!(
                        "`{}`'s field `{}` (argument {}) expects type `{:?}`, found `{:?}`",
                        name, f.name, i + 1, declared, actual
                    ),
                    span,
                );
            }
        }
    }

    /// Per-argument type check for a plain (non-generic) enum variant's
    /// constructor, called only once the caller has already confirmed arity
    /// matches -- same reasoning and same previously-missing coverage as
    /// `check_struct_ctor_args` above, for `EnumVariant` construction instead
    /// of `StructLit`.
    fn check_enum_variant_ctor_args(&mut self, enum_name: &str, variant: &str, fields: &[EnumFieldDef], arg_exprs: &[TypedExpr], span: Span) {
        for (i, (f, a)) in fields.iter().zip(arg_exprs.iter()).enumerate() {
            let declared = self.resolve_type(&f.ty).unwrap_or(Ty::Named("unknown".into()));
            let actual = a.clone().into_ty();
            if !Self::types_compatible(&declared, &actual) {
                self.error(
                    format!(
                        "`{}::{}(..)`'s field `{}` (argument {}) expects type `{:?}`, found `{:?}`",
                        enum_name, variant, f.name, i + 1, declared, actual
                    ),
                    span,
                );
            }
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
            // `Ty::is_numeric()` covers every explicit-width integer type
            // and `f64` alongside the original `i32`/`f32` -- this used to
            // shadow it with a narrower `Int | Float`-only check, left
            // behind when the sized numeric types landed, which made
            // `sqrt`/`floor`/`ceil`/`abs`/`pow`/`min`/`max` hard type errors
            // on every `i8`/`u8`/`i16`/`u16`/`u32`/`i64`/`u64`/`f64`
            // argument even though the checker otherwise treats them as
            // full numeric citizens.
            t.is_numeric() || is_placeholder(t)
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
                    // Same "one legacy mixed pair, otherwise an exact match"
                    // rule `infer_binop_ty` enforces for arithmetic/compare
                    // operators (`docs/design.md`'s "Numeric widths and
                    // modes") -- `i8`/`i64` or `u32`/`f64` mismatches are
                    // hard errors pointing at `as`, not a silent implicit
                    // widening, now that more than one numeric width exists.
                    if is_numeric(&arg_tys[0]) && is_numeric(&arg_tys[1]) {
                        let legacy_int_float_pair =
                            matches!((&arg_tys[0], &arg_tys[1]), (Ty::Int, Ty::Float) | (Ty::Float, Ty::Int));
                        if arg_tys[0] != arg_tys[1] && !legacy_int_float_pair
                            && !is_placeholder(&arg_tys[0]) && !is_placeholder(&arg_tys[1])
                        {
                            self.error(
                                format!(
                                    "`{}` arguments must be the same numeric type, found `{:?}` and `{:?}`",
                                    name, arg_tys[0], arg_tys[1]
                                ),
                                span,
                            );
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
    pub(super) fn infer_binop_ty(&mut self, op: &BinOp, lhs_ty: &Ty, rhs_ty: &Ty, span: Span) -> Ty {
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
        // `Wrapping<T>`/`Fixed<Bits,Frac>` get their own dedicated branch,
        // the same way `Vec2`/`Vec3`/`Vec4`/`Mat4` do just below -- neither
        // is folded into `Ty::is_numeric()` (see their own doc comments), so
        // they'd otherwise fall through to the "not supported" error at the
        // bottom of the plain-scalar branch. Requires an exact
        // `lhs_ty == rhs_ty` match, same "no implicit anything" rule every
        // other sized numeric type gets (no mixed-`T` `Wrapping`/`Fixed` pair,
        // and never mixed with the bare inner type without an explicit `as`).
        if matches!(lhs_ty, Ty::Wrapping(_) | Ty::Fixed(..)) || matches!(rhs_ty, Ty::Wrapping(_) | Ty::Fixed(..)) {
            let op_str = match op {
                BinOp::Add => "+", BinOp::Sub => "-", BinOp::Mul => "*",
                BinOp::Div => "/", BinOp::Rem => "%",
                BinOp::Eq => "==", BinOp::Ne => "!=",
                BinOp::Lt => "<", BinOp::Gt => ">", BinOp::Le => "<=", BinOp::Ge => ">=",
                BinOp::And | BinOp::Or => unreachable!("handled above"),
            };
            if lhs_ty != rhs_ty {
                self.error(
                    format!("`{}` between mismatched types `{:?}` and `{:?}` -- use `as` to cast one side", op_str, lhs_ty, rhs_ty),
                    span,
                );
                return if is_cmp { Ty::Bool } else { lhs_ty.clone() };
            }
            if matches!(op, BinOp::Rem) && matches!(lhs_ty, Ty::Fixed(..)) {
                self.error("`%` is not supported on `Fixed<Bits,Frac>` values", span);
                return lhs_ty.clone();
            }
            return if is_cmp { Ty::Bool } else { lhs_ty.clone() };
        }
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
                let op_str = match op {
                    BinOp::Eq => "==", BinOp::Ne => "!=",
                    BinOp::Lt => "<", BinOp::Gt => ">",
                    BinOp::Le => "<=", BinOp::Ge => ">=",
                    _ => unreachable!("is_cmp already restricts op to these six"),
                };
                // The original `Int`/`Float` mixed-pair comparison is
                // preserved exactly; every other numeric width requires an
                // exact type match -- `docs/design.md`'s "Numeric widths and
                // modes" treats `i8 == i16` etc. as a hard mismatch requiring
                // an explicit `as` cast, not a silent implicit widening (the
                // `Int`/`Float` pair is the one pre-existing exception, kept
                // for backward compatibility). `char` supports equality/
                // ordering against another `char` the same way, but never
                // against a numeric type.
                let legacy_int_float_pair = matches!((lhs_ty, rhs_ty), (Ty::Int, Ty::Float) | (Ty::Float, Ty::Int));
                if (lhs_ty.is_numeric() && rhs_ty.is_numeric() && (lhs_ty == rhs_ty || legacy_int_float_pair))
                    || (*lhs_ty == Ty::Char && *rhs_ty == Ty::Char)
                {
                    return Ty::Bool;
                }
                if *lhs_ty == Ty::Ptr && *rhs_ty == Ty::Ptr {
                    if !matches!(op, BinOp::Eq | BinOp::Ne) {
                        self.error("only `==`/`!=` are supported on `ptr` values", span);
                    }
                    return Ty::Bool;
                }
                if lhs_ty.is_numeric() && rhs_ty.is_numeric() {
                    self.error(
                        format!(
                            "`{}` between mismatched numeric types `{:?}` and `{:?}` -- use `as` to cast one side",
                            op_str, lhs_ty, rhs_ty
                        ),
                        span,
                    );
                    return Ty::Bool;
                }
                self.error(
                    format!("`{}` is not supported between `{:?}` and `{:?}`", op_str, lhs_ty, rhs_ty),
                    span,
                );
                return Ty::Bool;
            }
            // Original scalar arithmetic behavior, preserved exactly -- but
            // only once both operands are actually numeric. Every other
            // type (`str`, an enum, a struct, `List<T>`, a closure, `bool`,
            // `GenRef<T>`, or any mismatched pair) previously fell straight
            // through to the `Ty::Int` fallback below and type-checked
            // cleanly, only to fail with an unlocated "unsupported operand
            // types" error once `Codegen::emit_binop` actually saw it --
            // the exact same class of bug the `is_cmp` branch above was
            // already hardened against; this mirrors that fix for `+ - * /
            // %`.
            let op_str = match op {
                BinOp::Add => "+", BinOp::Sub => "-", BinOp::Mul => "*",
                BinOp::Div => "/", BinOp::Rem => "%",
                _ => unreachable!("this branch only reaches Add/Sub/Mul/Div/Rem -- And/Or/comparisons return earlier"),
            };
            if !lhs_ty.is_numeric() || !rhs_ty.is_numeric() {
                self.error(
                    format!("`{}` is not supported between `{:?}` and `{:?}`", op_str, lhs_ty, rhs_ty),
                    span,
                );
                return Ty::Int;
            }
            if lhs_ty == rhs_ty {
                return lhs_ty.clone();
            }
            // The original `Int`/`Float` mixed-pair promotion (`1 + 1.5 ==
            // 2.5`) is preserved exactly; every other numeric width pairing
            // is a hard mismatch (see the comparison branch above for the
            // identical rule and rationale) -- `i8 + i64`, `u32 + f64`, etc.
            // all require an explicit `as` cast on one side first.
            if matches!((lhs_ty, rhs_ty), (Ty::Int, Ty::Float) | (Ty::Float, Ty::Int)) {
                return Ty::Float;
            }
            self.error(
                format!(
                    "`{}` between mismatched numeric types `{:?}` and `{:?}` -- use `as` to cast one side",
                    op_str, lhs_ty, rhs_ty
                ),
                span,
            );
            return lhs_ty.clone();
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
        // `Pattern::Int`/`Pattern::Bool`/`Pattern::Compare` were previously
        // never checked against the scrutinee's type at all -- only their
        // *coverage* (`check_match_exhaustive`) was validated, mirroring the
        // struct/enum-variant fix above but for the three pattern kinds
        // codegen (`src/codegen/expr.rs`'s match-arm lowering) hardcodes as
        // `icmp eq i32`/`icmp sle i32`/etc. regardless of the scrutinee's
        // real LLVM type. A mismatch here (`match some_str: 5 -> ...`)
        // previously type-checked cleanly and only surfaced as an opaque
        // `clang` IR-verifier failure ("defined with type 'ptr' but expected
        // 'i32'") instead of a clean diagnostic at the offending pattern.
        match &arm.pattern {
            Pattern::Int(v) => {
                let scrutinee_ty = scrutinee_expr.clone().into_ty();
                // Any integer-shaped scrutinee (the original `i32` plus every
                // explicit-width type -- `Ty::int_shape`), not just `Ty::Int`
                // -- codegen (`Codegen::emit_expr`'s `TypedExpr::Match` arm)
                // lowers this against the scrutinee's *actual* LLVM width/
                // signedness, mirroring `emit_sized_int_binop`.
                match scrutinee_ty.int_shape() {
                    None => {
                        self.error(format!("pattern `{}` does not match scrutinee type `{:?}`", v, scrutinee_ty), arm.span);
                    }
                    // A pattern literal that doesn't fit the scrutinee's
                    // actual width used to type-check cleanly and reach
                    // `Codegen::int_pattern_literal`, which *truncates* to
                    // fit rather than erroring (needed so an in-range
                    // literal renders correctly for every width, not a
                    // license for an out-of-range one to silently
                    // reinterpret) -- e.g. a bare `2147483648` pattern
                    // against an `i32` scrutinee (`Lexer::scan_number` no
                    // longer caps a literal's magnitude at `i32::MAX`, so
                    // this became reachable) silently matched as
                    // `i32::MIN`'s bit pattern with zero diagnostic. Reject
                    // it here instead, mirroring `Expr::Int`'s own default-
                    // width range check.
                    Some((width, signed)) => {
                        let (lo, hi) = Self::int_shape_range(width, signed);
                        if *v < lo || *v > hi {
                            self.error(
                                format!("pattern `{}` does not fit in `{:?}` (range {}..={})", v, scrutinee_ty, lo, hi),
                                arm.span,
                            );
                        }
                    }
                }
            }
            Pattern::Bool(v) => {
                let scrutinee_ty = scrutinee_expr.clone().into_ty();
                if !matches!(scrutinee_ty, Ty::Bool) {
                    self.error(format!("pattern `{}` does not match scrutinee type `{:?}`", v, scrutinee_ty), arm.span);
                }
            }
            Pattern::Compare(..) => {
                let scrutinee_ty = scrutinee_expr.clone().into_ty();
                // Same widening as `Pattern::Int` above.
                if scrutinee_ty.int_shape().is_none() {
                    self.error(
                        format!("comparison pattern requires an integer scrutinee, found `{:?}`", scrutinee_ty),
                        arm.span,
                    );
                }
            }
            _ => {}
        }
        // `Pattern::Binding(name)` binds the *whole* scrutinee value to a
        // fresh name (`match x: v -> v + 1`) and, per `check_match_exhaustive`'s
        // own doc comment, is an unconditional catch-all -- but until now
        // nothing ever inserted `name` into the arm-local scope, so any use
        // of it inside the arm body failed with "undefined name" on every
        // single use, making this documented pattern kind entirely unusable.
        if let Pattern::Binding(name) = &arm.pattern {
            let scrutinee_ty = scrutinee_expr.clone().into_ty();
            vars.insert(name.clone(), scrutinee_ty);
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
        // bare expression, and isn't a `frame:` scope whose own trailing
        // statement is -- `Self::trailing_value_ty` mirrors
        // `Codegen::emit_stmts_value`'s exact notion of which statement
        // shapes contribute a value) has no such value, so it stays
        // `unknown`.
        let ty = Self::trailing_value_ty(&stmts).unwrap_or_else(|| Ty::Named("unknown".into()));
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
