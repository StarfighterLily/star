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

    /// Try to type a bracket literal `elems` directly as a fixed-size
    /// `[T; N]` array under an expected type known from context (a `let`'s
    /// own annotation, a struct field's declared type, or a function's
    /// declared return type) -- `None` when `expected` isn't `Ty::Array` or
    /// the element count doesn't match `N`, letting the caller fall through
    /// to the ordinary `Expr::ListLit` path (a heap `List<T>`) unchanged.
    /// This is the one place this checker looks at an expected type before
    /// inferring an expression, mirroring `cast_literal_magnitude`'s sibling
    /// special-cases' "peek at the raw `Expr` node before falling into
    /// `infer_expr`" pattern rather than threading a general expected-type
    /// parameter through every expression kind -- deliberately narrow: three
    /// call sites only (`Stmt::Let`, struct-literal field arguments,
    /// `Stmt::Return`). See `todo.md` P2 #10.
    pub(super) fn try_infer_array_lit(&mut self, elems: &[Expr], expected: &Ty, vars: &mut HashMap<String, Ty>, span: Span) -> Option<TypedExpr> {
        let Ty::Array(elem_ty, count) = expected else { return None };
        if elems.is_empty() || elems.len() as u64 != *count {
            return None;
        }
        let elem_ty = elem_ty.as_ref().clone();
        let typed: Vec<TypedExpr> = elems.iter().map(|e| self.infer_array_lit_elem(e, &elem_ty, vars)).collect();
        Some(TypedExpr::ArrayLit { elems: typed, elem_ty, span })
    }

    /// A single `[a, b, c]` -> `[T; N]` element: a bare integer literal (or
    /// a directly-negated one) that fits `elem_ty`'s range is typed with
    /// `elem_ty` directly, mirroring `Expr::WrappingNew`/`Expr::BitFieldNew`'s
    /// identical literal fast path -- otherwise a plain `let glyphs: [u8; N]
    /// = [0, 1, 2, ...]` would reject every element (a bare literal defaults
    /// to `Ty::Int`) and force an explicit `as u8` on each one, defeating
    /// most of the ergonomic point of this literal form. Any other
    /// expression shape is inferred normally and checked against `elem_ty`.
    fn infer_array_lit_elem(&mut self, e: &Expr, elem_ty: &Ty, vars: &mut HashMap<String, Ty>) -> TypedExpr {
        if let Some(v) = Self::cast_literal_magnitude(e) {
            if let Some((width, signed)) = elem_ty.int_shape() {
                let (lo, hi) = Self::int_shape_range(width, signed);
                if v >= lo && v <= hi {
                    return TypedExpr::Int(v, elem_ty.clone(), e.span());
                }
                self.error(
                    format!("integer literal `{}` does not fit in `{:?}` (range {}..={})", v, elem_ty, lo, hi),
                    e.span(),
                );
                return TypedExpr::Int(v, elem_ty.clone(), e.span());
            }
        }
        let typed = self.infer_expr(e, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
        let actual = typed.clone().into_ty();
        if !Self::types_compatible(elem_ty, &actual) {
            self.error(
                format!("array literal element expects type `{:?}`, found `{:?}`", elem_ty, actual),
                e.span(),
            );
        }
        typed
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
                            // See `Ty::is_fstring_unprintable`'s doc comment:
                            // a struct/tuple/array/`Ring`/closure/`GenRef`/
                            // `Handle` value has no defined print format --
                            // it lowers to an LLVM aggregate passed by
                            // value, so letting it reach
                            // `Codegen::emit_print_like`'s catch-all would
                            // silently emit a C-ABI-mismatched `printf` call
                            // (garbage output, not a crash) instead of this
                            // clean diagnostic.
                            let ty = typed.clone().into_ty();
                            if ty.is_fstring_unprintable() {
                                self.error(
                                    format!(
                                        "cannot interpolate a `{:?}` value into an f-string -- no print format is defined for structs, tuples, arrays, `Ring`, closures, `GenRef`, or `Handle`; print individual fields/elements instead",
                                        ty
                                    ),
                                    typed.span(),
                                );
                            }
                            typed_parts.push(TypedFStrExpr::Expr(Box::new(typed)));
                        }
                    }
                }
                Ok(TypedExpr::FStr(typed_parts, Ty::Str, *s))
            }
            Expr::Ident(name, s) => {
                // A top-level `const` reference substitutes directly to its
                // already-folded literal value here (see
                // `Checker::resolve_const`) -- checked after `vars` (so a
                // local binding of the same name still shadows it, ordinary
                // lexical scoping) but before the function/builtin case just
                // below, so codegen never has to know `const`s exist at all:
                // by the time any `TypedExpr` tree reaches it, every const
                // reference is already an ordinary `TypedExpr::Int`/`Float`/
                // `Bool`/`Str`/`Char` node.
                if !vars.contains_key(name) {
                    if let Some(value) = self.consts.get(name) {
                        return Ok(value.clone().into_typed_expr(*s));
                    }
                }
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
            Expr::Call { callee, args, arg_names, span } => {
                // Named-argument/default-value resolution (`docs/
                // requests.md` #6): if `callee` is a plain free function or
                // a `recv.method(..)` call with a simple receiver, and
                // resolution is actually needed (a named argument is
                // present, or the positional count undersupplies the
                // declared parameters), `args`/`arg_names` are shadowed
                // here with a fully positional, fully filled list (every
                // `arg_names` entry `None`) -- so the blanket rejection
                // just below never fires for a call this resolved, and
                // every branch further down (generic-fn calls, list/map/
                // set/etc. builtin methods, closures, standard-library
                // builtins, free-function/method calls) sees an ordinary
                // positional argument list exactly as it always has.
                // Anything this doesn't resolve (an exact-arity positional
                // call, an unrecognized callee shape) shadows to the exact
                // same `args`/`arg_names` it already had -- completely
                // unaffected by this feature.
                let (args, arg_names) = match self.try_resolve_call_defaults(callee, args, arg_names, vars, *span) {
                    Some(resolved) => {
                        let len = resolved.len();
                        (resolved, vec![None; len])
                    }
                    None => (args.clone(), arg_names.clone()),
                };
                let args = &args;
                let arg_names = &arg_names;
                // Ordinary call arguments are matched to parameters purely
                // positionally -- there is no named-parameter machinery for
                // functions/methods beyond what's resolved just above, so
                // silently accepting (and previously dropping) `name =
                // expr` here would let `f(b = 1, a = 2)` reorder nothing
                // while looking like it did.
                if arg_names.iter().any(|n| n.is_some()) {
                    self.error(
                        "named arguments are only supported when constructing a struct or enum variant, or calling a plain free function/method with declared parameter names -- this callee's arguments are matched positionally",
                        *span,
                    );
                }
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
                    // `Bytes` reuses `List<u8>`'s method surface wholesale
                    // (`push`/`pop`/`len`) -- see `Ty::Bytes`'s doc comment.
                    if let Ty::Bytes = base_typed.clone().into_ty() {
                        return Ok(self.infer_list_method(base_typed, field, Ty::U8, args, vars, *span));
                    }
                    // `Palette` reuses `List<Color32>`'s method surface
                    // wholesale -- see `Ty::Palette`'s doc comment.
                    if let Ty::Palette = base_typed.clone().into_ty() {
                        return Ok(self.infer_list_method(base_typed, field, Ty::Color32, args, vars, *span));
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
                if let Some(overloaded) = self.try_operator_overload_call(op, &lhs_expr, &rhs_expr, *span) {
                    return Ok(overloaded);
                }
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
                if matches!(op, UnOp::Neg) {
                    if let Some(overloaded) = self.try_neg_overload_call(&operand_expr, *span) {
                        return Ok(overloaded);
                    }
                }
                // `-x` preserves the operand's own numeric type (Int stays
                // Int, Float stays Float) rather than always widening to Int.
                let ty = match op {
                    // Reuse binary `-`'s own type-legality check (`Neg`
                    // lowers to exactly `0 - x` in `Codegen::emit_unary`) so
                    // an operand type that doesn't support subtraction
                    // (`str`, `List<T>`, `GenRef<T>`, ...) is rejected here
                    // with a real source location instead of silently
                    // passing the checker and only failing later with an
                    // unlocated "unsupported operand types" codegen error --
                    // the exact same class of bug `infer_binop_ty`'s own doc
                    // comments describe already being fixed for binary
                    // `+ - * / %` and comparisons. A struct operand is
                    // special-cased out entirely rather than falling into
                    // `infer_binop_ty(Sub, ...)`: `try_neg_overload_call`
                    // just above already handled the one case where a struct
                    // has real unary-`-` semantics (implementing `Neg`), and
                    // routing a non-`Neg` struct through `infer_binop_ty`
                    // here would wrongly accept it whenever that same struct
                    // happens to implement `Sub` (added alongside this same
                    // feature, for binary `-`) -- computing `x.sub(x)`
                    // instead of a real negation, and disagreeing with
                    // `Codegen::emit_unary`'s still-`Sub`-trait-unaware
                    // `Ty::Named` lowering (`zeroinitializer` minus an
                    // aggregate struct is not legal LLVM IR).
                    UnOp::Neg => {
                        let operand_ty = operand_expr.clone().into_ty();
                        if matches!(operand_ty, Ty::Named(_)) && !Self::is_placeholder_ty(&operand_ty) {
                            self.error(
                                format!(
                                    "unary `-` is not supported on `{:?}` -- implement the `Neg` trait (`fn neg(self) -> Self`) to support it",
                                    operand_ty
                                ),
                                *span,
                            );
                            operand_ty
                        } else {
                            self.infer_binop_ty(&BinOp::Sub, &operand_ty, &operand_ty, *span)
                        }
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
                    // `~x` -- one's complement, the unary counterpart of
                    // `&`/`|`/`^`/`<<`/`>>`. Accepts the same
                    // `Ty::bit_shape()` set `bit_not(x)` already validates
                    // (any integer width, `Wrapping<T>`, `BitField<N>`; not
                    // `Flags<E>`, see `infer_shift_ty`'s doc comment for why).
                    // `~x` preserves the operand's own type, the same
                    // "output type mirrors input type" rule `Neg` follows.
                    UnOp::BitNot => {
                        let operand_ty = operand_expr.clone().into_ty();
                        if operand_ty.bit_shape().is_none() && !Self::is_placeholder_ty(&operand_ty) {
                            self.error(
                                format!("`~` operand expected an integer/`Wrapping<T>`/`BitField<N>` value, found `{:?}`", operand_ty),
                                *span,
                            );
                        }
                        operand_ty
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
            Expr::StructLit { name, type_args, args, arg_names, span } => {
                // Resolve named arguments and fill omitted-field defaults
                // *before* inference, so every downstream path (builtin
                // dispatch, generic unification, arity/field-type checks,
                // codegen) sees the complete positional list it expects.
                let resolved_args: Vec<Expr> = match self.ctor_field_list(name) {
                    Some((field_names, defaults)) => {
                        match self.resolve_ctor_arg_exprs(&format!("`{}(..)`", name), &field_names, &defaults, args, arg_names, *span) {
                            Ok(v) => v,
                            Err(true) => return Ok(TypedExpr::Error(Ty::Named("infer_error".into()))),
                            Err(false) => args.clone(),
                        }
                    }
                    None => {
                        if arg_names.iter().any(|n| n.is_some()) {
                            self.error(
                                format!("named arguments are not supported for `{}(..)` -- it has no user-declared fields", name),
                                *span,
                            );
                        }
                        args.clone()
                    }
                };
                let args = &resolved_args;
                // A plain user struct's declared field types, resolved up
                // front so a bracket-literal argument (`FontData(glyphs =
                // [0, 1, 2, ...])`) can be coerced to that field's `[T; N]`
                // array type below -- see `Checker::try_infer_array_lit`,
                // `todo.md` P2 #10. `None` for a builtin construction
                // (`List`/`Map`/`Set`/`Table`/`Flags`) or a generic struct
                // (those go through `infer_generic_struct_lit`'s own
                // dedicated arg handling instead, dispatched further below),
                // in which case every arg just falls through to the
                // ordinary `infer_expr` call this always ran.
                let field_tys: Option<Vec<Type>> = self.structs.get(name).map(|sdef| sdef.fields.iter().map(|f| f.ty.clone()).collect());
                let field_tys: Option<Vec<Ty>> = field_tys.map(|tys| tys.iter().map(|t| self.resolve_type(t).unwrap_or(Ty::Named("unknown".into()))).collect());
                let arg_exprs: Vec<TypedExpr> = args.iter().enumerate().map(|(i, a)| {
                    if let (Expr::ListLit(elems, lspan), Some(tys)) = (a, &field_tys) {
                        if let Some(expected) = tys.get(i) {
                            if let Some(coerced) = self.try_infer_array_lit(elems, expected, vars, *lspan) {
                                return coerced;
                            }
                        }
                    }
                    self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))
                }).collect();
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
                if name == "Flags" && !self.structs.contains_key(name) {
                    return Ok(self.infer_flags_new(type_args, &arg_exprs, *span));
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
            Expr::Spawn { arena, args, arg_names, span } => {
                let (arena, elem) = self.resolve_spawn_elem(arena, args, arg_names, vars, *span);
                Ok(TypedExpr::Spawn { arena, elem: Box::new(elem), ty: Ty::Int, span: *span })
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
            // `docs/design.md`'s "Bit-level types" section: constructs from
            // a single int-shaped value (any width), widened/narrowed to the
            // underlying `i{bits}` at codegen time -- see `Ty::BitField`'s
            // doc comment and `Codegen::emit_bitfield_new`. Mirrors
            // `Ty::Tick`'s own "any int_shape(), no exact-match requirement"
            // construction rule (`check_builtin_ctor_arity`'s `Ty::Tick` arm)
            // rather than `Wrapping<T>`'s exact-type-match rule, since a
            // register width is a storage detail the caller shouldn't need
            // an exact-width literal/variable to satisfy.
            Expr::BitFieldNew { bits, value, span } => {
                if !matches!(bits, 8 | 16 | 32 | 64) {
                    self.error(format!("`BitField<{}>`'s bit width must be one of 8, 16, 32, 64", bits), *span);
                }
                // Same literal-fast-path treatment as `Expr::WrappingNew`
                // just above -- a bare literal argument (defaulting to
                // `Ty::Int`, i.e. `i32`) would otherwise be rejected both by
                // a width narrower than `i32` (e.g. `BitField<8>(200)`, `200`
                // not fitting `i8`'s signed range) and by one wider (e.g.
                // `BitField<64>(5000000000)`, not fitting `i32` at all).
                // Tagged with the matching-width *unsigned* type (mirroring
                // `Ty::BitField`'s own always-unsigned `bit_shape()`), not
                // bare `Ty::Int`, so a wide literal's codegen constant isn't
                // truncated back down to `i32` by `Codegen::emit_bitfield_new`'s
                // own `int_shape()`-driven widen/narrow logic.
                if let Some(v) = Self::cast_literal_magnitude(value) {
                    let (lo, hi) = Self::int_shape_range(*bits, false);
                    if v >= lo && v <= hi {
                        let lit_ty = match bits {
                            8 => Ty::U8,
                            16 => Ty::U16,
                            32 => Ty::U32,
                            _ => Ty::U64,
                        };
                        let lit = TypedExpr::Int(v, lit_ty, *span);
                        return Ok(TypedExpr::BitFieldNew { bits: *bits, value: Box::new(lit), span: *span });
                    }
                }
                let value_typed = self.infer_expr(value, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                let value_ty = value_typed.clone().into_ty();
                if value_ty.int_shape().is_none() && !Self::is_placeholder_ty(&value_ty) {
                    self.error(format!("`BitField<N>(..)` expects an integer value, found `{:?}`", value_ty), *span);
                }
                Ok(TypedExpr::BitFieldNew { bits: *bits, value: Box::new(value_typed), span: *span })
            }
            Expr::EnumVariant { enum_name, type_args, variant, args, arg_names, span } => {
                // Same pre-inference named-argument resolution as the
                // `StructLit` arm above -- a variant's payload fields are
                // named/typed just like struct fields (no defaults, though).
                let variant_fields: Option<Vec<String>> = self.enums.get(enum_name)
                    .or_else(|| self.generic_enums.get(enum_name))
                    .and_then(|e| e.variants.iter().find(|v| &v.name == variant))
                    .map(|v| v.fields.iter().map(|f| f.name.clone()).collect());
                let resolved_args: Vec<Expr> = match variant_fields {
                    Some(field_names) => {
                        let defaults = vec![None; field_names.len()];
                        match self.resolve_ctor_arg_exprs(&format!("`{}::{}(..)`", enum_name, variant), &field_names, &defaults, args, arg_names, *span) {
                            Ok(v) => v,
                            Err(true) => return Ok(TypedExpr::Error(Ty::Named("infer_error".into()))),
                            Err(false) => args.clone(),
                        }
                    }
                    None => {
                        if arg_names.iter().any(|n| n.is_some()) {
                            self.error(
                                format!("named arguments are not supported here -- `{}::{}` is not a known payload variant", enum_name, variant),
                                *span,
                            );
                        }
                        args.clone()
                    }
                };
                let args = &resolved_args;
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
                    // `bytes[i]` -- reuses the exact same `TypedExpr::ListIndex`
                    // node/codegen as `List<u8>` indexing -- see `Ty::Bytes`'s
                    // doc comment.
                    Ty::Bytes => {
                        Ok(TypedExpr::ListIndex { base: Box::new(base_expr), index: Box::new(index_expr), ty: Ty::U8, span: *span })
                    }
                    // `palette[i]` -- reuses the exact same
                    // `TypedExpr::ListIndex` node/codegen as `List<Color32>`
                    // indexing -- see `Ty::Palette`'s doc comment.
                    Ty::Palette => {
                        Ok(TypedExpr::ListIndex { base: Box::new(base_expr), index: Box::new(index_expr), ty: Ty::Color32, span: *span })
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
                        self.error(format!("`[..]` indexing requires a `GenRef<T>`, `Handle<T>`, `List<T>`, `Bytes`, `Palette`, `[T; N]`, `Ring<T,N>`, `Table<T>`, or `str`, found `{:?}`", other), *span);
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
                // A closure literal lowers to its own independent top-level
                // LLVM function (see `Codegen::emit_closure_lit`), not an
                // inline block of the function it's lexically written inside
                // -- so `break`/`continue` in its body have no well-defined
                // target even when the literal sits lexically inside an
                // enclosing `while`/`for` loop, exactly like `Stmt::Par`'s
                // body above (see that arm's own `saved_loop_depth` comment).
                // Previously `self.loop_depth` was left untouched here, so a
                // closure defined inside a loop inherited that loop's nonzero
                // depth and a bare `break`/`continue` directly in the
                // closure's body type-checked cleanly -- but
                // `emit_closure_lit` never saves/restores `self.loop_stack`
                // either (nothing needs to: this now-fixed checker gap was
                // the only way a closure body could ever contain one), so
                // codegen emitted a `br label %<outer loop's block>`
                // referencing a basic block that only exists in the
                // *enclosing* function, not the closure's own deferred
                // `closure_N` function -- invalid LLVM IR ("use of undefined
                // value") that `clang` rejected outright, confirmed via a
                // real `star build` failure on a closure containing a bare
                // `break` defined inside a `while` loop.
                let saved_loop_depth = self.loop_depth;
                self.loop_depth = 0;
                let body_typed = self.check_block_inner(body, &mut inner_vars);
                self.loop_depth = saved_loop_depth;
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
                // Mirrors `Checker::resolve_type`'s `Type::Array` bound --
                // `[value; N]` never goes through that path at all (`count`
                // here is already a bare `u64`, not a `Type::Array` node), so
                // without this check a huge `N` reached `Codegen::
                // emit_array_repeat`'s `for i in 0..count` loop directly,
                // which emits two LLVM IR text lines per iteration and hangs
                // the compiler indefinitely on e.g. `[0; 999999999999]`.
                if *count > Self::MAX_INLINE_LEN {
                    self.error(
                        format!(
                            "array size `{}` is too large (max {}) -- `[value; N]` is stored inline with no heap allocation of its own, so an enormous `N` either hangs the compiler emitting one instruction per element or bakes a multi-gigabyte type into the generated code; use a heap-backed `List<T>` instead",
                            count, Self::MAX_INLINE_LEN
                        ),
                        *span,
                    );
                }
                Ok(TypedExpr::ArrayRepeat { value: Box::new(value_typed), count: *count, elem_ty, span: *span })
            }
            Expr::RingNew { elem_ty, count, span } => {
                let elem_ty = self.resolve_type(elem_ty).unwrap_or(Ty::Named("unknown".into()));
                // Mirrors `Checker::resolve_type`'s `Type::Ring` bound -- see
                // `Expr::ArrayRepeat`'s identical check just above for why
                // `Ring<T, N>()`'s literal `count` needs its own check too
                // rather than relying on `resolve_type` alone.
                if *count > Self::MAX_INLINE_LEN {
                    self.error(
                        format!(
                            "`Ring<T, N>` capacity `{}` is too large (max {}) -- a `Ring` is stored inline with no heap allocation of its own, so an enormous `N` bakes a multi-gigabyte type into the generated code",
                            count, Self::MAX_INLINE_LEN
                        ),
                        *span,
                    );
                }
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
                // `Tick`/`Duration`/`Instant` <-> `i64`: a free bit-preserving
                // relabel, same reasoning as `Wrapping<T> <-> T` above -- see
                // `Ty::Tick`'s doc comment. Only `i64` itself (not any other
                // width) is a legal pairing, since that's the one width these
                // three actually lower to.
                let time_ok = matches!(
                    (&inner_ty, &target),
                    (Ty::Tick | Ty::Duration | Ty::Instant, Ty::I64) | (Ty::I64, Ty::Tick | Ty::Duration | Ty::Instant)
                );
                // `Symbol <-> i64`: a free bit-preserving relabel, same
                // reasoning as `Tick`/`Duration`/`Instant <-> i64` above --
                // see `Ty::Symbol`'s doc comment.
                let symbol_ok = matches!((&inner_ty, &target), (Ty::Symbol, Ty::I64) | (Ty::I64, Ty::Symbol));
                // `BitField<N> <-> i{N}`/`u{N}`: a free bit-preserving
                // relabel, same reasoning as `Wrapping<T> <-> T` above -- see
                // `Ty::BitField`'s doc comment. `BitField<N>` has no declared
                // signedness of its own (it's a bit count, not a stored
                // `Ty`), so unlike `Wrapping<T> <-> T`'s exact-`Ty`-match
                // rule, either signedness at the matching width is a legal
                // pairing -- both lower to the identical bare `i{N}`.
                let bitfield_ok = match (&inner_ty, &target) {
                    (Ty::BitField(n), t) => t.int_shape().is_some_and(|(w, _)| w == *n),
                    (t, Ty::BitField(n)) => t.int_shape().is_some_and(|(w, _)| w == *n),
                    _ => false,
                };
                // `Flags<E> <-> i64`: a free bit-preserving relabel, same
                // reasoning as `Symbol <-> i64` above -- see `Ty::Flags`'s
                // doc comment.
                let flags_ok = matches!((&inner_ty, &target), (Ty::Flags(_), Ty::I64) | (Ty::I64, Ty::Flags(_)));
                // `Color32 <-> i32`/`u32`: a free bit-preserving relabel --
                // see `Ty::Color32`'s doc comment.
                let color32_ok = matches!(
                    (&inner_ty, &target),
                    (Ty::Color32, Ty::Int | Ty::U32) | (Ty::Int | Ty::U32, Ty::Color32)
                );
                // `PaletteIndex <-> u8`: a free bit-preserving relabel -- see
                // `Ty::PaletteIndex`'s doc comment.
                let palette_index_ok = matches!((&inner_ty, &target), (Ty::PaletteIndex, Ty::U8) | (Ty::U8, Ty::PaletteIndex));
                let ok = (inner_ty.is_numeric() && target.is_numeric())
                    || (inner_ty.is_numeric() && target == Ty::Char)
                    || (inner_ty == Ty::Char && target.is_numeric())
                    || (inner_ty == Ty::Char && target == Ty::Char)
                    || wrapping_ok
                    || fixed_ok
                    || time_ok
                    || symbol_ok
                    || bitfield_ok
                    || flags_ok
                    || color32_ok
                    || palette_index_ok;
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

    /// `Flags<E>(a, b, ...)` -- a typed bitflag set construction, see
    /// `Ty::Flags`'s doc comment. Unlike `infer_list_new`/`infer_table_new`
    /// (always zero arguments), `Flags<E>` accepts zero or more `E`-typed
    /// arguments, each OR'd together bit-by-bit at codegen time -- so
    /// `Flags<Direction>()` (empty), `Flags<Direction>(Direction::Up)`
    /// (single), and `Flags<Direction>(Direction::Up, Direction::Down)`
    /// (multiple) are all legal, mirroring a plain `ListLit`'s "however many
    /// elements" arity but through the turbofish-plus-call constructor shape
    /// `List<T>()`/`Table<T>()` already use rather than bracket-literal
    /// syntax (which has no way to also carry the `<E>` turbofish).
    fn infer_flags_new(&mut self, type_args: &[Type], arg_exprs: &[TypedExpr], span: Span) -> TypedExpr {
        let elem_ty = match type_args.first() {
            Some(t) => self.resolve_type(t).unwrap_or(Ty::Named("unknown".into())),
            None => {
                self.error("`Flags<E>(..)` needs an explicit type argument, e.g. `Flags<Direction>()`", span);
                Ty::Named("unknown".into())
            }
        };
        let Ty::Enum(enum_name) = &elem_ty else {
            if !matches!(&elem_ty, Ty::Named(n) if n == "unknown") {
                self.error(format!("`Flags<E>` requires `E` to be an enum type, found `{:?}`", elem_ty), span);
            }
            return TypedExpr::Error(Ty::Named("infer_error".into()));
        };
        for (i, a) in arg_exprs.iter().enumerate() {
            let a_ty = a.clone().into_ty();
            if a_ty != elem_ty && !Self::is_placeholder_ty(&a_ty) {
                self.error(format!("`Flags<{}>(..)` argument {} expected `{}`, found `{:?}`", enum_name, i + 1, enum_name, a_ty), span);
            }
        }
        TypedExpr::FlagsNew { enum_name: enum_name.clone(), args: arg_exprs.to_vec(), span }
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
            match subst.get(&tp.name) {
                Some(t) => type_args.push(t.clone()),
                None => self.error(format!("cannot infer type parameter `{}` of `{}` from its arguments", tp.name, name), span),
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
        // Trait-bound enforcement (`fn f<T: Trait>(...)`): reject a call
        // whose inferred type argument doesn't implement every bound its
        // corresponding type parameter declares, before instantiating the
        // template body against it -- skipping the instantiation on failure
        // avoids cascading a second, more confusing diagnostic from
        // type-checking the substituted body against an already-known-bad
        // argument (see `check_type_bounds`'s doc comment).
        if !self.check_type_bounds("function", name, &template.sig.type_params, &type_args, span) {
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
        if !self.check_type_bounds("struct", name, &template.type_params, &concrete_args, span) {
            return TypedExpr::Error(Ty::Named("infer_error".into()));
        }
        let mangled = self.instantiate_struct(name, &concrete_args);
        let fields = self.structs.get(&mangled).map(|s| s.fields.clone()).unwrap_or_default();
        if arg_exprs.len() != fields.len() {
            self.error(format!("`{}(..)` expects {} argument(s), found {}", name, fields.len(), arg_exprs.len()), span);
        } else {
            self.check_field_ctor_types(name, &fields, &arg_exprs, span);
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
        if !self.check_type_bounds("enum", enum_name, &template.type_params, &concrete_args, span) {
            return TypedExpr::Error(Ty::Named("infer_error".into()));
        }
        if vdef.fields.len() != arg_exprs.len() {
            self.error(
                format!("`{}::{}(..)` expects {} argument(s), found {}", enum_name, variant, vdef.fields.len(), arg_exprs.len()),
                span,
            );
        }
        let mangled = self.instantiate_enum(enum_name, &concrete_args);
        // Same missing-validation hazard `check_field_ctor_types`'s doc
        // comment describes for the generic-struct path, mirrored here for
        // a generic enum variant's payload fields: without this, an
        // untyped literal argument against a narrower concrete field kept
        // its default `Ty::Int` all the way to codegen, and the payload
        // union's store picked its width from that (wrong) inferred type
        // instead of the variant's declared field type -- corrupting
        // whatever payload bytes sit after it.
        if vdef.fields.len() == arg_exprs.len() {
            if let Some(concrete_fields) = self.enums.get(&mangled)
                .and_then(|e| e.variants.iter().find(|v| v.name == variant))
                .map(|v| v.fields.clone())
            {
                self.check_enum_variant_ctor_args(enum_name, variant, &concrete_fields, &arg_exprs, span);
            }
        }
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
        type_params: &[TypeParam],
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
            match subst.get(&tp.name) {
                Some(t) => out.push(t.clone()),
                None => self.error(
                    format!("cannot infer type argument `{}` for `{}` -- use an explicit `{}<...>`", tp.name, template_name, template_name),
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
            // `docs/design.md`'s "Math and geometry" section: `Mat2`/`Mat3`
            // mirror `Mat4`'s own "N row arguments of the matching vector
            // type" constructor shape.
            Ty::Mat2 => {
                if args.len() != 2 || !args.iter().all(|a| matches!(a.clone().into_ty(), Ty::Vec2)) {
                    self.error(format!("{}(..) expects 2 Vec2 row arguments", name), span);
                }
            }
            Ty::Mat3 => {
                if args.len() != 3 || !args.iter().all(|a| matches!(a.clone().into_ty(), Ty::Vec3)) {
                    self.error(format!("{}(..) expects 3 Vec3 row arguments", name), span);
                }
            }
            // `Quat`/`Color` mirror `Vec4`'s own "4 float arguments"
            // constructor shape -- see their own `Ty` doc comments.
            Ty::Quat | Ty::Color => {
                if args.len() != 4 || !args.iter().all(|a| is_numeric(&a.clone().into_ty())) {
                    self.error(format!("{}(..) expects 4 float arguments", name), span);
                }
            }
            // `Color32(r, g, b, a)`: four 0-255 channel values, any
            // int-shaped type (mirroring `Ty::Tick`'s own "any int_shape(),
            // no exact-match requirement" construction rule) -- range
            // validated at codegen time (`Codegen::emit_color32_new`), not
            // here, since a non-literal argument's value isn't known until
            // runtime.
            Ty::Color32 => {
                if args.len() != 4 || !args.iter().all(|a| a.clone().into_ty().int_shape().is_some()) {
                    self.error(format!("{}(..) expects 4 integer (0-255) channel arguments", name), span);
                }
            }
            // `PaletteIndex(value)` -- mirrors `Ty::Tick`'s own single
            // int-shaped-argument construction rule.
            Ty::PaletteIndex => {
                if args.len() != 1 || !args.iter().all(|a| a.clone().into_ty().int_shape().is_some()) {
                    self.error(format!("{}(..) expects 1 integer argument", name), span);
                }
            }
            // `Palette()` starts empty -- mirrors `Ty::Bytes`'s own
            // no-argument constructor.
            Ty::Palette => {
                if !args.is_empty() {
                    self.error(format!("{}() takes no arguments", name), span);
                }
            }
            // `docs/design.md`'s "Time" section: `Tick`/`Duration`/`Instant`
            // each construct from a single int-shaped value (any width),
            // widened/narrowed to the underlying `i64` at codegen time --
            // see `Ty::Tick`'s doc comment and `Codegen::emit_time_new`.
            Ty::Tick | Ty::Duration | Ty::Instant => {
                if args.len() != 1 || !args.iter().all(|a| a.clone().into_ty().int_shape().is_some()) {
                    self.error(format!("{}(..) expects 1 integer argument", name), span);
                }
            }
            // `docs/design.md`'s "Text and bytes" section: `Bytes()` starts
            // empty (mirrors `List<T>()`); `Symbol(s)` interns a `str` --
            // see `Ty::Symbol`'s doc comment.
            Ty::Bytes => {
                if !args.is_empty() {
                    self.error(format!("{}() takes no arguments", name), span);
                }
            }
            Ty::Symbol => {
                if args.len() != 1 || !matches!(args[0].clone().into_ty(), Ty::Str) {
                    self.error(format!("{}(..) expects 1 `str` argument", name), span);
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
        self.check_field_ctor_types(name, &sdef.fields, arg_exprs, span);
    }

    /// Resolve a construction's (possibly named) argument list against its
    /// declared field list, at the AST level and *before* any inference:
    /// positional arguments fill fields in declaration order, named
    /// arguments (`field = expr`) fill their named field in any order, and
    /// any field left unfilled falls back to its declared default
    /// initializer -- producing the full positional expression list every
    /// downstream check and codegen path already expects. Previously the
    /// parser dropped argument names outright and everything matched
    /// positionally, so `Pair(b = 1, a = 2)` silently compiled to
    /// `a = 1, b = 2`, and a field default could never actually be omitted
    /// at a construction site.
    ///
    /// Errors this reports (returning `Err(true)`): an unknown or duplicate
    /// field name, a positional argument after a named one, too many
    /// positional arguments mixed with named ones, and an unfilled field
    /// with no default. A *purely positional* argument list whose count
    /// mismatches (and that defaults can't complete) returns `Err(false)`
    /// without reporting, leaving the caller's existing arity diagnostics
    /// to fire exactly as before.
    pub(super) fn resolve_ctor_arg_exprs(
        &mut self,
        desc: &str,
        field_names: &[String],
        defaults: &[Option<Expr>],
        args: &[Expr],
        arg_names: &[Option<String>],
        span: Span,
    ) -> Result<Vec<Expr>, bool> {
        let has_names = arg_names.iter().any(|n| n.is_some());
        if !has_names {
            if args.len() == field_names.len() {
                return Ok(args.to_vec());
            }
            // An undersupplied positional prefix is only completable when
            // every remaining field has a declared default.
            if args.len() < field_names.len() && defaults[args.len()..].iter().all(|d| d.is_some()) {
                let mut out = args.to_vec();
                out.extend(defaults[args.len()..].iter().map(|d| d.clone().unwrap()));
                return Ok(out);
            }
            return Err(false);
        }
        let mut slots: Vec<Option<Expr>> = vec![None; field_names.len()];
        let mut reported = false;
        let mut seen_named = false;
        let mut pos = 0usize;
        for (arg, name) in args.iter().zip(arg_names.iter()) {
            match name {
                None => {
                    if seen_named {
                        self.error(format!("positional argument after a named argument in {}", desc), span);
                        reported = true;
                        continue;
                    }
                    if pos >= slots.len() {
                        self.error(format!("{} expects {} argument(s), found {}", desc, field_names.len(), args.len()), span);
                        reported = true;
                        break;
                    }
                    slots[pos] = Some(arg.clone());
                    pos += 1;
                }
                Some(n) => {
                    seen_named = true;
                    match field_names.iter().position(|f| f == n) {
                        None => {
                            self.error(format!("{} has no field `{}`", desc, n), span);
                            reported = true;
                        }
                        Some(idx) if slots[idx].is_some() => {
                            self.error(format!("field `{}` is given more than once in {}", n, desc), span);
                            reported = true;
                        }
                        Some(idx) => slots[idx] = Some(arg.clone()),
                    }
                }
            }
        }
        let mut out = Vec::with_capacity(slots.len());
        for (i, slot) in slots.into_iter().enumerate() {
            match slot.or_else(|| defaults.get(i).cloned().flatten()) {
                Some(e) => out.push(e),
                None => {
                    self.error(
                        format!("{} is missing a value for field `{}`, which has no default", desc, field_names[i]),
                        span,
                    );
                    reported = true;
                }
            }
        }
        if reported { Err(true) } else { Ok(out) }
    }

    /// Entry point for `Expr::Call`'s named-argument/default-value handling
    /// (`docs/requests.md` #6): if `callee` is a shape this can resolve
    /// parameter metadata for *and* resolution is actually needed (a named
    /// argument is present, or the positional count undersupplies the
    /// declared parameters), returns the fully positional, filled argument
    /// list via `resolve_call_arg_exprs`. Returns `None` otherwise --
    /// either because nothing needs resolving (an exact-arity, purely
    /// positional call), or because `callee` isn't a shape this recognizes
    /// -- in which case `Expr::Call` proceeds exactly as it did before this
    /// feature existed (including the blanket "named arguments aren't
    /// supported" error for any callee shape not handled here).
    ///
    /// Two callee shapes are recognized: a plain free-function name
    /// (`fn_param_meta`, an ordinary `HashMap` lookup with no side
    /// effects), and `recv.method(..)` where `recv` is a bare identifier or
    /// `self` (`method_param_meta`) -- deliberately *not* a general
    /// receiver expression like `f().method(..)`, because determining a
    /// compound receiver's type requires calling `infer_expr` on it, and
    /// `Expr::Call`'s own handling below calls `infer_expr` on that same
    /// receiver again regardless of what happens here; doing so a second
    /// time here too would duplicate any diagnostic the receiver itself
    /// produces. A bare identifier/`self` receiver's type is instead read
    /// straight out of `vars`, which has no such risk.
    fn try_resolve_call_defaults(
        &mut self,
        callee: &Expr,
        args: &[Expr],
        arg_names: &[Option<String>],
        vars: &HashMap<String, Ty>,
        span: Span,
    ) -> Option<Vec<Expr>> {
        let has_names = arg_names.iter().any(|n| n.is_some());
        let (desc, params): (String, Vec<Param>) = match callee {
            Expr::Ident(name, _) if !vars.contains_key(name) => {
                (format!("`{}(..)`", name), self.fn_param_meta.get(name)?.clone())
            }
            Expr::Field { base, field, .. } => {
                let recv_ty = match base.as_ref() {
                    Expr::Ident(n, _) => vars.get(n).cloned(),
                    Expr::SelfExpr(_) => vars.get("self").cloned(),
                    _ => None,
                }?;
                let Ty::Named(struct_name) = recv_ty else { return None };
                let is_real_field = self.structs.get(&struct_name).map(|s| s.fields.iter().any(|f| f.name == *field)).unwrap_or(false);
                if is_real_field {
                    return None;
                }
                let method_key = format!("{}#{}", struct_name, field);
                (format!("`{}(..)`", field), self.method_param_meta.get(&method_key)?.clone())
            }
            _ => return None,
        };
        if !has_names && args.len() >= params.len() {
            // Exact arity or too many positional arguments, no names --
            // nothing for this to do; let the existing arity check fire
            // with its usual wording.
            return None;
        }
        self.resolve_call_arg_exprs(&desc, &params, args, arg_names, span)
    }

    /// Resolve an ordinary call's (possibly named, possibly under-supplied)
    /// argument list against `params`' declared names/defaults into a fully
    /// positional `Vec<Expr>` -- the function/method-call counterpart of
    /// `resolve_ctor_arg_exprs` just above (see its doc comment for the
    /// shared positional-fill/named-match/default-fill algorithm this
    /// mirrors), with call-appropriate wording ("parameter"/"argument"
    /// rather than "field") and no `self`/receiver entry in `params` (every
    /// caller already excludes it, matching `fn_param_meta`/
    /// `method_param_meta`'s own stored shape). `docs/requests.md` #6.
    ///
    /// Only ever called once the caller has already established resolution
    /// is actually needed -- a named argument is present, or the positional
    /// count undersupplies `params` -- so an exact-arity, purely positional
    /// call never reaches this at all; its behavior (including error
    /// wording on a genuine arity mismatch) is completely unchanged from
    /// before this feature existed. Returns `None` (after reporting a
    /// specific error) on an unknown/duplicate named argument, a positional
    /// argument after a named one, or a still-missing argument with no
    /// default.
    fn resolve_call_arg_exprs(&mut self, desc: &str, params: &[Param], args: &[Expr], arg_names: &[Option<String>], span: Span) -> Option<Vec<Expr>> {
        let param_names: Vec<&str> = params.iter().map(|p| p.name.as_str()).collect();
        let has_names = arg_names.iter().any(|n| n.is_some());
        if !has_names {
            // Reached only when `args.len() < params.len()` (the caller's
            // own precondition for calling this at all in the no-names
            // case), so `params[args.len()..]` never panics.
            if params[args.len()..].iter().all(|p| p.default.is_some()) {
                let mut out = args.to_vec();
                let mut ok = true;
                for p in &params[args.len()..] {
                    let default = p.default.clone().unwrap();
                    if !self.check_default_is_scope_independent(&default, &p.name, desc) {
                        ok = false;
                        continue;
                    }
                    out.push(default);
                }
                return if ok { Some(out) } else { None };
            }
            self.error(
                format!("{} is missing argument `{}`, which has no default", desc, param_names[args.len()]),
                span,
            );
            return None;
        }
        let mut slots: Vec<Option<Expr>> = vec![None; params.len()];
        let mut reported = false;
        let mut seen_named = false;
        let mut pos = 0usize;
        for (arg, name) in args.iter().zip(arg_names.iter()) {
            match name {
                None => {
                    if seen_named {
                        self.error(format!("positional argument after a named argument in {}", desc), span);
                        reported = true;
                        continue;
                    }
                    if pos >= slots.len() {
                        self.error(format!("{} expects {} argument(s), found {}", desc, params.len(), args.len()), span);
                        reported = true;
                        break;
                    }
                    slots[pos] = Some(arg.clone());
                    pos += 1;
                }
                Some(n) => {
                    seen_named = true;
                    match param_names.iter().position(|p| p == n) {
                        None => {
                            self.error(format!("{} has no parameter named `{}`", desc, n), span);
                            reported = true;
                        }
                        Some(idx) if slots[idx].is_some() => {
                            self.error(format!("parameter `{}` is given more than once in {}", n, desc), span);
                            reported = true;
                        }
                        Some(idx) => slots[idx] = Some(arg.clone()),
                    }
                }
            }
        }
        let mut out = Vec::with_capacity(slots.len());
        for (i, slot) in slots.into_iter().enumerate() {
            match slot {
                Some(e) => out.push(e),
                None => match params[i].default.clone() {
                    Some(default) => {
                        if self.check_default_is_scope_independent(&default, param_names[i], desc) {
                            out.push(default);
                        } else {
                            reported = true;
                        }
                    }
                    None => {
                        self.error(
                            format!("{} is missing a value for parameter `{}`, which has no default", desc, param_names[i]),
                            span,
                        );
                        reported = true;
                    }
                },
            }
        }
        if reported { None } else { Some(out) }
    }

    /// Type-checks `default` in complete isolation -- an empty `vars`, no
    /// parameter/`self`/local scope of any kind -- exactly the check a bare
    /// module-level expression would get. Guards against a real hygiene bug
    /// this feature shipped with: a default value expression is a raw
    /// `Expr` cloned straight into the caller's own resolved argument list
    /// (`resolve_call_arg_exprs`/`resolve_ctor_arg_exprs`), so without this
    /// check it was later re-inferred against the *caller's* ambient
    /// `vars`, not the callee's own declaration scope -- `Expr::Ident`'s
    /// lookup (just above in this file) checks `vars` before anything else,
    /// so `fn compute(base: i32, bonus: i32 = base): base + bonus` silently
    /// captured whatever local happened to be named `base` at each call
    /// site instead of referring to `compute`'s own `base` parameter:
    /// `compute(1)` called from a scope with an unrelated `let base = 999`
    /// returned `1000`, not the `2` a hygienic default would give (and a
    /// scope with no such local got a confusing "undefined name `base`"
    /// pointing at what reads like a perfectly valid parameter reference).
    /// No mainstream language with default arguments (C++, Swift, Kotlin)
    /// lets one default reference a sibling parameter either, so the fix
    /// here is to reject it outright, cleanly, at first use, rather than
    /// silently or confusingly miscompile it -- diagnostics `infer_expr`
    /// produces against the empty scope are swapped for one clear,
    /// correctly-attributed error; a default that only ever references
    /// globals/consts/functions (every existing test fixture, e.g. `x: i32
    /// = 1 + 2` or `x: i32 = base()` calling a free function) type-checks
    /// here exactly as before and is spliced in unchanged.
    fn check_default_is_scope_independent(&mut self, default: &Expr, param_name: &str, desc: &str) -> bool {
        let errors_before = self.errors.len();
        let mut empty_vars = HashMap::new();
        let _ = self.infer_expr(default, &mut empty_vars);
        if self.errors.len() > errors_before {
            self.errors.truncate(errors_before);
            self.error(
                format!(
                    "{}'s default value for `{}` cannot reference other parameters, `self`, or local variables -- only globals, constants, and function calls are allowed",
                    desc, param_name
                ),
                default.span(),
            );
            return false;
        }
        true
    }

    /// The `(field names, field defaults)` a `StructLit` naming `name`
    /// should resolve named arguments against: a plain struct's declared
    /// fields, a generic struct template's declared fields, or -- for a
    /// desugared `sequence`'s state struct -- only its leading declared
    /// parameters (the hoisted-local/`state` fields behind them are
    /// internal, and a sequence constructor takes no named/default
    /// arguments for them). `None` when `name` isn't a user-declared
    /// struct at all (builtin `Vec3`/`List`/... constructions have no
    /// named fields to match).
    pub(super) fn ctor_field_list(&self, name: &str) -> Option<(Vec<String>, Vec<Option<Expr>>)> {
        if let Some(sdef) = self.structs.get(name) {
            let n = self.sequence_param_counts.get(name).copied().unwrap_or(sdef.fields.len()).min(sdef.fields.len());
            let is_sequence = self.sequence_param_counts.contains_key(name);
            return Some((
                sdef.fields[..n].iter().map(|f| f.name.clone()).collect(),
                sdef.fields[..n].iter().map(|f| if is_sequence { None } else { f.default.clone() }).collect(),
            ));
        }
        if let Some(template) = self.generic_structs.get(name) {
            return Some((
                template.fields.iter().map(|f| f.name.clone()).collect(),
                template.fields.iter().map(|f| f.default.clone()).collect(),
            ));
        }
        None
    }

    /// Per-argument declared-vs-actual field type check, factored out of
    /// `check_struct_ctor_args` so `infer_generic_struct_lit` can reuse it
    /// against a monomorphized generic struct's *concrete* field list --
    /// previously that path only ran `resolve_generic_ctor_args`'s
    /// `unify_ty` (which exists purely to solve type-parameter bindings and
    /// silently no-ops on a field whose declared type is already concrete,
    /// e.g. `tag: i8` in `struct Box<T>: value: T  tag: i8`), so an
    /// untyped literal argument against a narrower concrete field
    /// (`Box<u8>(250 as u8, 3)`, `tag: i8`) kept its default `Ty::Int` all
    /// the way to codegen. `crate::codegen::expr`'s generic `StructLit`
    /// store path picks its LLVM store width from the *argument's* inferred
    /// type, not the field's declared type (same hazard
    /// `check_struct_ctor_args`'s own doc comment already describes for the
    /// non-generic case) -- so this produced a real, silent 4-byte store
    /// into a struct with only 1 byte of room past that field, corrupting
    /// whatever sits directly after it in memory. By the time
    /// `instantiate_struct` returns, a monomorphized struct's fields have
    /// already been fully substituted (see `subst_type`) -- no leftover
    /// type parameter remains -- so this is exactly the same check either
    /// way, just against a different field list.
    fn check_field_ctor_types(&mut self, name: &str, fields: &[FieldDef], arg_exprs: &[TypedExpr], span: Span) {
        for (i, (f, a)) in fields.iter().zip(arg_exprs.iter()).enumerate() {
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
            "sqrt" | "floor" | "ceil" | "abs" | "sin" | "cos" | "tan" | "asin" | "acos" | "atan" | "exp" | "exp2"
            | "log" | "log2" | "log10" => {
                if arity_ok(1, self) && !is_numeric(&arg_tys[0]) {
                    self.error(format!("`{}` expects a numeric (`int`/`float`) argument, found `{:?}`", name, arg_tys[0]), span);
                }
            }
            "pow" | "min" | "max" | "atan2" => {
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
            "bytes_from_str" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Str) {
                    self.error(format!("`bytes_from_str` expects a `str` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            "str_from_bytes" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Bytes) {
                    self.error(format!("`str_from_bytes` expects a `Bytes` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            "symbol_name" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Symbol) {
                    self.error(format!("`symbol_name` expects a `Symbol` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            // `docs/design.md`'s "Bit-level types" section: `bit_get`/
            // `bit_set`/`bit_clear`/`bit_toggle`/`bit_not` work on any
            // integer type (any width), `Wrapping<T>`, or `BitField<N>` --
            // `Ty::bit_shape()`'s exact set -- but deliberately not
            // `Flags<E>` (see `Ty::Flags`'s doc comment for why raw
            // bit-indexing a flag set is excluded). `bit_and`/`bit_or`/
            // `bit_xor` additionally accept `Flags<E>` (`Ty::
            // bitwise_combine_shape()`), safe to share since union/
            // intersect/symmetric-difference of two valid masks never gains
            // an undefined bit.
            "bit_get" | "bit_set" | "bit_clear" | "bit_toggle" => {
                if arity_ok(2, self) {
                    if arg_tys[0].bit_shape().is_none() && !is_placeholder(&arg_tys[0]) {
                        self.error(
                            format!("`{}` argument 1 expected an integer/`Wrapping<T>`/`BitField<N>` value, found `{:?}`", name, arg_tys[0]),
                            span,
                        );
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Int) {
                        self.error(format!("`{}` argument 2 (bit index) expected `int`, found `{:?}`", name, arg_tys[1]), span);
                    }
                }
            }
            "bit_not" => {
                if arity_ok(1, self) && arg_tys[0].bit_shape().is_none() && !is_placeholder(&arg_tys[0]) {
                    self.error(
                        format!("`bit_not` expects an integer/`Wrapping<T>`/`BitField<N>` value, found `{:?}`", arg_tys[0]),
                        span,
                    );
                }
            }
            "bit_and" | "bit_or" | "bit_xor" => {
                if arity_ok(2, self) {
                    if arg_tys[0].bitwise_combine_shape().is_none() && !is_placeholder(&arg_tys[0]) {
                        self.error(
                            format!(
                                "`{}` argument 1 expected an integer/`Wrapping<T>`/`BitField<N>`/`Flags<E>` value, found `{:?}`",
                                name, arg_tys[0]
                            ),
                            span,
                        );
                    } else if !tys_eq(&arg_tys[0], &arg_tys[1]) {
                        self.error(format!("`{}` arguments must be the same type, found `{:?}` and `{:?}`", name, arg_tys[0], arg_tys[1]), span);
                    }
                }
            }
            "flags_is_empty" => {
                if arity_ok(1, self) && !matches!(&arg_tys[0], Ty::Flags(_)) && !is_placeholder(&arg_tys[0]) {
                    self.error(format!("`flags_is_empty` expects a `Flags<E>` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            "flags_has" | "flags_with" | "flags_without" => {
                if arity_ok(2, self) {
                    match &arg_tys[0] {
                        Ty::Flags(inner) => {
                            if arg_tys[1] != **inner && !is_placeholder(&arg_tys[1]) {
                                self.error(
                                    format!("`{}` argument 2 expected `{:?}` (`{}`'s element type), found `{:?}`", name, inner, name, arg_tys[1]),
                                    span,
                                );
                            }
                        }
                        t if !is_placeholder(t) => {
                            self.error(format!("`{}` argument 1 expected a `Flags<E>` value, found `{:?}`", name, t), span);
                        }
                        _ => {}
                    }
                }
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
            // `is_null` alone also accepts `Str`, not just `Ptr` -- both
            // share the exact same `i8*` runtime representation (see
            // `crate::codegen::builtins::emit_is_null`, which is already
            // fully type-agnostic under the hood), and `tcp_recv`
            // (`crate::codegen::net`'s module doc comment) now legitimately
            // returns a null-backed `str` to signal "no data yet" on a
            // non-blocking socket -- callers need `is_null` to check that
            // *before* the `str` is otherwise usable, since a real `str`
            // method call on a null `i8*` would crash.
            "is_null" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Ptr) && !tys_eq(&arg_tys[0], &Ty::Str) {
                    self.error(format!("`is_null` expects a `ptr` or `str` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            "ptr_to_str" | "file_close" | "file_read" | "file_read_bytes" | "file_read_line" | "tcp_close" | "tcp_recv" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Ptr) {
                    self.error(format!("`{}` expects a `ptr` argument, found `{:?}`", name, arg_tys[0]), span);
                }
            }
            "file_exists" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Str) {
                    self.error(format!("`file_exists` expects a `str` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            "open_file_dialog" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Str) {
                    self.error(format!("`open_file_dialog` expects a `str` argument, found `{:?}`", arg_tys[0]), span);
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
            "file_write_bytes" => {
                if arity_ok(2, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`file_write_bytes` argument 1 expected `ptr`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Bytes) {
                        self.error(format!("`file_write_bytes` argument 2 expected `Bytes`, found `{:?}`", arg_tys[1]), span);
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
            "tcp_set_nonblocking" => {
                if arity_ok(2, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`tcp_set_nonblocking` argument 1 expected `ptr`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Bool) {
                        self.error(format!("`tcp_set_nonblocking` argument 2 expected `bool`, found `{:?}`", arg_tys[1]), span);
                    }
                }
            }
            // `docs/design.md`'s "Math and geometry" section -- see
            // `crate::codegen::geometry` for each function's lowering.
            "quat_identity" => {
                arity_ok(0, self);
            }
            "quat_conjugate" | "quat_normalize" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Quat) {
                    self.error(format!("`{}` expects a `Quat` argument, found `{:?}`", name, arg_tys[0]), span);
                }
            }
            "quat_rotate" => {
                if arity_ok(2, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Quat) {
                        self.error(format!("`quat_rotate` argument 1 expected `Quat`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Vec3) {
                        self.error(format!("`quat_rotate` argument 2 expected `Vec3`, found `{:?}`", arg_tys[1]), span);
                    }
                }
            }
            "rect_contains" => {
                if arity_ok(2, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Named("Rect".into())) {
                        self.error(format!("`rect_contains` argument 1 expected `Rect`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Vec2) {
                        self.error(format!("`rect_contains` argument 2 expected `Vec2`, found `{:?}`", arg_tys[1]), span);
                    }
                }
            }
            "rect_intersects" => {
                if arity_ok(2, self) {
                    for (i, t) in arg_tys.iter().enumerate() {
                        if !tys_eq(t, &Ty::Named("Rect".into())) {
                            self.error(format!("`rect_intersects` argument {} expected `Rect`, found `{:?}`", i + 1, t), span);
                        }
                    }
                }
            }
            "aabb2_contains" => {
                if arity_ok(2, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Named("Aabb2".into())) {
                        self.error(format!("`aabb2_contains` argument 1 expected `Aabb2`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Vec2) {
                        self.error(format!("`aabb2_contains` argument 2 expected `Vec2`, found `{:?}`", arg_tys[1]), span);
                    }
                }
            }
            "aabb2_intersects" => {
                if arity_ok(2, self) {
                    for (i, t) in arg_tys.iter().enumerate() {
                        if !tys_eq(t, &Ty::Named("Aabb2".into())) {
                            self.error(format!("`aabb2_intersects` argument {} expected `Aabb2`, found `{:?}`", i + 1, t), span);
                        }
                    }
                }
            }
            "aabb3_contains" => {
                if arity_ok(2, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Named("Aabb3".into())) {
                        self.error(format!("`aabb3_contains` argument 1 expected `Aabb3`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Vec3) {
                        self.error(format!("`aabb3_contains` argument 2 expected `Vec3`, found `{:?}`", arg_tys[1]), span);
                    }
                }
            }
            "aabb3_intersects" => {
                if arity_ok(2, self) {
                    for (i, t) in arg_tys.iter().enumerate() {
                        if !tys_eq(t, &Ty::Named("Aabb3".into())) {
                            self.error(format!("`aabb3_intersects` argument {} expected `Aabb3`, found `{:?}`", i + 1, t), span);
                        }
                    }
                }
            }
            "ray_at" => {
                if arity_ok(2, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Named("Ray".into())) {
                        self.error(format!("`ray_at` argument 1 expected `Ray`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !is_numeric(&arg_tys[1]) {
                        self.error(format!("`ray_at` argument 2 (`t`) expected a numeric value, found `{:?}`", arg_tys[1]), span);
                    }
                }
            }
            "plane_distance_to_point" => {
                if arity_ok(2, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Named("Plane".into())) {
                        self.error(format!("`plane_distance_to_point` argument 1 expected `Plane`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Vec3) {
                        self.error(format!("`plane_distance_to_point` argument 2 expected `Vec3`, found `{:?}`", arg_tys[1]), span);
                    }
                }
            }
            "frustum_contains_point" => {
                if arity_ok(2, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Named("Frustum".into())) {
                        self.error(format!("`frustum_contains_point` argument 1 expected `Frustum`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Vec3) {
                        self.error(format!("`frustum_contains_point` argument 2 expected `Vec3`, found `{:?}`", arg_tys[1]), span);
                    }
                }
            }
            "transform_apply_point" => {
                if arity_ok(2, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Named("Transform".into())) {
                        self.error(format!("`transform_apply_point` argument 1 expected `Transform`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Vec3) {
                        self.error(format!("`transform_apply_point` argument 2 expected `Vec3`, found `{:?}`", arg_tys[1]), span);
                    }
                }
            }
            "color32_r" | "color32_g" | "color32_b" | "color32_a" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Color32) {
                    self.error(format!("`{}` expects a `Color32` argument, found `{:?}`", name, arg_tys[0]), span);
                }
            }
            "color_to_color32" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Color) {
                    self.error(format!("`color_to_color32` expects a `Color` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            "color32_to_color" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Color32) {
                    self.error(format!("`color32_to_color` expects a `Color32` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            // SDL2-backed graphics/input builtins (`todo.md` #4) -- see
            // `crate::codegen::sdl`.
            "window_create" => {
                if arity_ok(3, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Str) {
                        self.error(format!("`window_create` argument 1 expected `str`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Int) {
                        self.error(format!("`window_create` argument 2 expected `int`, found `{:?}`", arg_tys[1]), span);
                    }
                    if !tys_eq(&arg_tys[2], &Ty::Int) {
                        self.error(format!("`window_create` argument 3 expected `int`, found `{:?}`", arg_tys[2]), span);
                    }
                }
            }
            "window_destroy" | "present" | "window_should_close" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Ptr) {
                    self.error(format!("`{}` expects a `ptr` argument, found `{:?}`", name, arg_tys[0]), span);
                }
            }
            "clear_screen" => {
                if arity_ok(2, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`clear_screen` argument 1 expected `ptr`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Color32) {
                        self.error(format!("`clear_screen` argument 2 expected `Color32`, found `{:?}`", arg_tys[1]), span);
                    }
                }
            }
            "draw_pixel" => {
                if arity_ok(4, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`draw_pixel` argument 1 expected `ptr`, found `{:?}`", arg_tys[0]), span);
                    }
                    for (i, t) in arg_tys[1..3].iter().enumerate() {
                        if !tys_eq(t, &Ty::Int) {
                            self.error(format!("`draw_pixel` argument {} expected `int`, found `{:?}`", i + 2, t), span);
                        }
                    }
                    if !tys_eq(&arg_tys[3], &Ty::Color32) {
                        self.error(format!("`draw_pixel` argument 4 expected `Color32`, found `{:?}`", arg_tys[3]), span);
                    }
                }
            }
            "draw_rect" => {
                if arity_ok(6, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`draw_rect` argument 1 expected `ptr`, found `{:?}`", arg_tys[0]), span);
                    }
                    for (i, t) in arg_tys[1..5].iter().enumerate() {
                        if !tys_eq(t, &Ty::Int) {
                            self.error(format!("`draw_rect` argument {} expected `int`, found `{:?}`", i + 2, t), span);
                        }
                    }
                    if !tys_eq(&arg_tys[5], &Ty::Color32) {
                        self.error(format!("`draw_rect` argument 6 expected `Color32`, found `{:?}`", arg_tys[5]), span);
                    }
                }
            }
            "draw_line" => {
                if arity_ok(6, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`draw_line` argument 1 expected `ptr`, found `{:?}`", arg_tys[0]), span);
                    }
                    for (i, t) in arg_tys[1..5].iter().enumerate() {
                        if !tys_eq(t, &Ty::Int) {
                            self.error(format!("`draw_line` argument {} expected `int`, found `{:?}`", i + 2, t), span);
                        }
                    }
                    if !tys_eq(&arg_tys[5], &Ty::Color32) {
                        self.error(format!("`draw_line` argument 6 expected `Color32`, found `{:?}`", arg_tys[5]), span);
                    }
                }
            }
            // `draw_pixels(handle, pixels: Bytes, width, height, dst_x,
            // dst_y, dst_w, dst_h)` -- `pixels` must be exactly `width *
            // height * 4` bytes, tightly packed row-major RGBA (checked at
            // runtime by `emit_draw_pixels`, not here -- this checker has no
            // way to relate a `Bytes` value's runtime length to two `int`
            // arguments at type-check time).
            "draw_pixels" => {
                if arity_ok(8, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`draw_pixels` argument 1 expected `ptr`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Bytes) {
                        self.error(format!("`draw_pixels` argument 2 expected `Bytes`, found `{:?}`", arg_tys[1]), span);
                    }
                    for (i, t) in arg_tys[2..8].iter().enumerate() {
                        if !tys_eq(t, &Ty::Int) {
                            self.error(format!("`draw_pixels` argument {} expected `int`, found `{:?}`", i + 3, t), span);
                        }
                    }
                }
            }
            // `texture_create`/`texture_update`/`texture_draw`/
            // `texture_destroy` -- the cached-handle sibling of `draw_pixels`
            // above (`crate::codegen::sdl::emit_texture_create`'s own doc
            // comment).
            "texture_create" => {
                if arity_ok(3, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`texture_create` argument 1 expected `ptr`, found `{:?}`", arg_tys[0]), span);
                    }
                    for (i, t) in arg_tys[1..3].iter().enumerate() {
                        if !tys_eq(t, &Ty::Int) {
                            self.error(format!("`texture_create` argument {} expected `int`, found `{:?}`", i + 2, t), span);
                        }
                    }
                }
            }
            "texture_update" => {
                if arity_ok(4, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`texture_update` argument 1 expected `ptr`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Bytes) {
                        self.error(format!("`texture_update` argument 2 expected `Bytes`, found `{:?}`", arg_tys[1]), span);
                    }
                    for (i, t) in arg_tys[2..4].iter().enumerate() {
                        if !tys_eq(t, &Ty::Int) {
                            self.error(format!("`texture_update` argument {} expected `int`, found `{:?}`", i + 3, t), span);
                        }
                    }
                }
            }
            "texture_draw" => {
                if arity_ok(6, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`texture_draw` argument 1 expected `ptr`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Ptr) {
                        self.error(format!("`texture_draw` argument 2 expected `ptr`, found `{:?}`", arg_tys[1]), span);
                    }
                    for (i, t) in arg_tys[2..6].iter().enumerate() {
                        if !tys_eq(t, &Ty::Int) {
                            self.error(format!("`texture_draw` argument {} expected `int`, found `{:?}`", i + 3, t), span);
                        }
                    }
                }
            }
            "texture_destroy" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Ptr) {
                    self.error(format!("`texture_destroy` expects a `ptr` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            "key_down" | "mouse_button_down" | "delay" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Int) {
                    self.error(format!("`{}` expects an `int` argument, found `{:?}`", name, arg_tys[0]), span);
                }
            }
            "mouse_x" | "mouse_y" | "ticks" => {
                arity_ok(0, self);
            }
            // Text-rendering/font-loading builtins -- see
            // `crate::codegen::font`.
            "font_load" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Str) {
                    self.error(format!("`font_load` expects a `str` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            "font_free" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Ptr) {
                    self.error(format!("`font_free` expects a `ptr` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            "default_font" => {
                arity_ok(0, self);
            }
            "draw_text" => {
                if arity_ok(7, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`draw_text` argument 1 (window) expected `ptr`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Ptr) {
                        self.error(format!("`draw_text` argument 2 (font) expected `ptr`, found `{:?}`", arg_tys[1]), span);
                    }
                    if !tys_eq(&arg_tys[2], &Ty::Str) {
                        self.error(format!("`draw_text` argument 3 (text) expected `str`, found `{:?}`", arg_tys[2]), span);
                    }
                    for (i, t) in arg_tys[3..6].iter().enumerate() {
                        if !tys_eq(t, &Ty::Int) {
                            self.error(format!("`draw_text` argument {} expected `int`, found `{:?}`", i + 4, t), span);
                        }
                    }
                    if !tys_eq(&arg_tys[6], &Ty::Color32) {
                        self.error(format!("`draw_text` argument 7 (color) expected `Color32`, found `{:?}`", arg_tys[6]), span);
                    }
                }
            }
            "measure_text" => {
                if arity_ok(3, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`measure_text` argument 1 (font) expected `ptr`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Str) {
                        self.error(format!("`measure_text` argument 2 (text) expected `str`, found `{:?}`", arg_tys[1]), span);
                    }
                    if !tys_eq(&arg_tys[2], &Ty::Int) {
                        self.error(format!("`measure_text` argument 3 (scale) expected `int`, found `{:?}`", arg_tys[2]), span);
                    }
                }
            }
            "get_pixel" => {
                if arity_ok(3, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`get_pixel` argument 1 expected `ptr`, found `{:?}`", arg_tys[0]), span);
                    }
                    for (i, t) in arg_tys[1..3].iter().enumerate() {
                        if !tys_eq(t, &Ty::Int) {
                            self.error(format!("`get_pixel` argument {} expected `int`, found `{:?}`", i + 2, t), span);
                        }
                    }
                }
            }
            // Proportional GDI-backed text rendering -- see
            // `crate::codegen::system_font`.
            "font_load_system" | "font_load_ttf" => {
                let label = if name == "font_load_system" { "family" } else { "path" };
                if arity_ok(3, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`{}` argument 1 (window) expected `ptr`, found `{:?}`", name, arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Str) {
                        self.error(format!("`{}` argument 2 ({}) expected `str`, found `{:?}`", name, label, arg_tys[1]), span);
                    }
                    if !tys_eq(&arg_tys[2], &Ty::Int) {
                        self.error(format!("`{}` argument 3 (size) expected `int`, found `{:?}`", name, arg_tys[2]), span);
                    }
                }
            }
            "font_ttf_free" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Ptr) {
                    self.error(format!("`font_ttf_free` expects a `ptr` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            "draw_text_ttf" => {
                if arity_ok(6, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`draw_text_ttf` argument 1 (window) expected `ptr`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Ptr) {
                        self.error(format!("`draw_text_ttf` argument 2 (font) expected `ptr`, found `{:?}`", arg_tys[1]), span);
                    }
                    if !tys_eq(&arg_tys[2], &Ty::Str) {
                        self.error(format!("`draw_text_ttf` argument 3 (text) expected `str`, found `{:?}`", arg_tys[2]), span);
                    }
                    for (i, t) in arg_tys[3..5].iter().enumerate() {
                        if !tys_eq(t, &Ty::Int) {
                            self.error(format!("`draw_text_ttf` argument {} expected `int`, found `{:?}`", i + 4, t), span);
                        }
                    }
                    if !tys_eq(&arg_tys[5], &Ty::Color32) {
                        self.error(format!("`draw_text_ttf` argument 6 (color) expected `Color32`, found `{:?}`", arg_tys[5]), span);
                    }
                }
            }
            "measure_text_ttf" => {
                if arity_ok(2, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`measure_text_ttf` argument 1 (font) expected `ptr`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Str) {
                        self.error(format!("`measure_text_ttf` argument 2 (text) expected `str`, found `{:?}`", arg_tys[1]), span);
                    }
                }
            }
            // Audio playback / gamepad input builtins (`todo.md` #8) -- see
            // `crate::codegen::audio`/`crate::codegen::gamepad`.
            "sound_load" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Str) {
                    self.error(format!("`sound_load` expects a `str` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            "sound_free" | "sound_play" | "music_play" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Ptr) {
                    self.error(format!("`{}` expects a `ptr` argument, found `{:?}`", name, arg_tys[0]), span);
                }
            }
            "music_stop" | "sound_stop_all" | "gamepad_count" => {
                arity_ok(0, self);
            }
            "sound_play_channel" => {
                if arity_ok(3, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`sound_play_channel` argument 1 (sound) expected `ptr`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Int) {
                        self.error(format!("`sound_play_channel` argument 2 (channel) expected `int`, found `{:?}`", arg_tys[1]), span);
                    }
                    if !tys_eq(&arg_tys[2], &Ty::Bool) {
                        self.error(format!("`sound_play_channel` argument 3 (looped) expected `bool`, found `{:?}`", arg_tys[2]), span);
                    }
                }
            }
            "sound_stop_channel" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Int) {
                    self.error(format!("`sound_stop_channel` expects an `int` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            "gamepad_open" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Int) {
                    self.error(format!("`gamepad_open` expects an `int` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            "gamepad_close" | "gamepad_attached" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Ptr) {
                    self.error(format!("`{}` expects a `ptr` argument, found `{:?}`", name, arg_tys[0]), span);
                }
            }
            "gamepad_button_down" | "gamepad_axis" => {
                if arity_ok(2, self) {
                    if !tys_eq(&arg_tys[0], &Ty::Ptr) {
                        self.error(format!("`{}` argument 1 expected `ptr`, found `{:?}`", name, arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Int) {
                        self.error(format!("`{}` argument 2 expected `int`, found `{:?}`", name, arg_tys[1]), span);
                    }
                }
            }
            "str_contains" | "str_starts_with" | "str_ends_with" | "str_index_of" => {
                if arity_ok(2, self) {
                    for (i, t) in arg_tys.iter().enumerate() {
                        if !tys_eq(t, &Ty::Str) {
                            self.error(format!("`{}` argument {} expected `str`, found `{:?}`", name, i + 1, t), span);
                        }
                    }
                }
            }
            "str_trim" => {
                if arity_ok(1, self) && !tys_eq(&arg_tys[0], &Ty::Str) {
                    self.error(format!("`str_trim` expects a `str` argument, found `{:?}`", arg_tys[0]), span);
                }
            }
            "str_replace" => {
                if arity_ok(3, self) {
                    for (i, t) in arg_tys.iter().enumerate() {
                        if !tys_eq(t, &Ty::Str) {
                            self.error(format!("`str_replace` argument {} expected `str`, found `{:?}`", i + 1, t), span);
                        }
                    }
                }
            }
            "str_split" => {
                if arity_ok(2, self) {
                    for (i, t) in arg_tys.iter().enumerate() {
                        if !tys_eq(t, &Ty::Str) {
                            self.error(format!("`str_split` argument {} expected `str`, found `{:?}`", i + 1, t), span);
                        }
                    }
                }
            }
            "str_join" => {
                if arity_ok(2, self) {
                    let list_ok = matches!(&arg_tys[0], Ty::List(inner) if **inner == Ty::Str) || is_placeholder(&arg_tys[0]);
                    if !list_ok {
                        self.error(format!("`str_join` argument 1 expected `List<str>`, found `{:?}`", arg_tys[0]), span);
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Str) {
                        self.error(format!("`str_join` argument 2 expected `str`, found `{:?}`", arg_tys[1]), span);
                    }
                }
            }
            // `reflect_get_*`/`reflect_set_*`: argument 1 must be a real
            // struct value (any `Ty::Named` this checker actually declared,
            // including a monomorphized generic instantiation -- the same
            // `self.structs.contains_key` test `Table<T>`'s own element-type
            // validation already uses) that declares at least one
            // `@export`/`@tweakable` field of the exact primitive type this
            // getter/setter reads/writes. That second half is the one static
            // guarantee this checker *can* give -- which specific field (if
            // any) a given call actually hits depends on argument 2, a
            // runtime `str` this checker can't see the value of, so a name
            // that doesn't match anything is left to codegen's generated
            // `strcmp` chain to fail safe on (`crate::codegen::reflect`),
            // mirroring this codebase's established "safe fallback, not a
            // crash" convention for every other runtime-keyed lookup (an
            // out-of-bounds `List<T>` index, a stale `GenRef`, ...).
            "reflect_get_i32" | "reflect_get_f32" | "reflect_get_bool" => {
                if arity_ok(2, self) {
                    let want = match name {
                        "reflect_get_i32" => Ty::Int,
                        "reflect_get_f32" => Ty::Float,
                        _ => Ty::Bool,
                    };
                    self.check_reflect_struct_arg(name, &arg_tys[0], &want, false, span);
                    if !tys_eq(&arg_tys[1], &Ty::Str) {
                        self.error(format!("`{}` argument 2 expected `str`, found `{:?}`", name, arg_tys[1]), span);
                    }
                }
            }
            "reflect_set_i32" | "reflect_set_f32" | "reflect_set_bool" => {
                if arity_ok(3, self) {
                    let want = match name {
                        "reflect_set_i32" => Ty::Int,
                        "reflect_set_f32" => Ty::Float,
                        _ => Ty::Bool,
                    };
                    self.check_reflect_struct_arg(name, &arg_tys[0], &want, true, span);
                    if !tys_eq(&arg_tys[1], &Ty::Str) {
                        self.error(format!("`{}` argument 2 expected `str`, found `{:?}`", name, arg_tys[1]), span);
                    }
                    if !tys_eq(&arg_tys[2], &want) {
                        self.error(format!("`{}` argument 3 expected `{:?}`, found `{:?}`", name, want, arg_tys[2]), span);
                    }
                    // Unlike a `Field`/method-call-receiver chain rooted at a
                    // `Table<T>` index (`t[i].field = v`, `t[i].tags.push(v)`
                    // -- both genuinely supported now, see `Ty::Table`'s doc
                    // comment), `reflect_set_*` mutates its *whole* argument-1
                    // struct value by runtime field-name lookup, not a single
                    // compile-time-known field -- there is no single
                    // contiguous address for a whole table element to hand
                    // out (`t[i]`'s fields live in independent column
                    // buffers), so `emit_place`'s generic fallback would
                    // materialize a *disconnected* copy and the write would
                    // silently vanish instead of erroring or taking effect.
                    // Checked explicitly, before falling through to the
                    // ordinary mut-binding check, since `check_mut_receiver`
                    // alone no longer flags this shape (it only ever guarded
                    // the now-supported `Field`/`TupleIndex`/... chains).
                    if Self::writes_through_table_index(&args[0]) {
                        self.error(
                            format!(
                                "cannot call `{}(..)` on a `Table<T>` index -- a table element's fields live in independent columns with no single addressable struct to mutate as a whole; assign or read the whole element instead (`table[i] = ...`)",
                                name
                            ),
                            span,
                        );
                    } else {
                        // The same `mut`-receiver gate a mutating collection
                        // method call's receiver already gets (`List::push`,
                        // `Map::insert`, ...) -- `reflect_set_*` mutates
                        // argument 1 in place exactly like a method call
                        // would mutate its receiver, just spelled as a free
                        // function instead of `s.reflect_set_i32(..)`.
                        self.check_mut_receiver(&args[0], name, span);
                    }
                }
            }
            "reflect_has_field" => {
                if arity_ok(2, self) {
                    match &arg_tys[0] {
                        Ty::Named(n) if self.structs.contains_key(n) => {}
                        t if is_placeholder(t) => {}
                        t => self.error(format!("`reflect_has_field` argument 1 must be a struct value, found `{:?}`", t), span),
                    }
                    if !tys_eq(&arg_tys[1], &Ty::Str) {
                        self.error(format!("`reflect_has_field` argument 2 expected `str`, found `{:?}`", arg_tys[1]), span);
                    }
                }
            }
            _ => {}
        }
    }

    /// Shared argument-1 validation for `reflect_get_*`/`reflect_set_*`: must
    /// be a known struct type that declares at least one `@export`/
    /// `@tweakable` field whose resolved type is exactly `want` (and, when
    /// `require_mut` is set -- `reflect_set_*` only -- that's also declared
    /// `mut`, see `struct_has_decorated_field_of_ty`'s doc comment). See
    /// `check_builtin_call_args`'s `reflect_get_*`/`reflect_set_*` arms for
    /// why this is the one static half of the check that's actually
    /// possible.
    fn check_reflect_struct_arg(&mut self, name: &str, arg_ty: &Ty, want: &Ty, require_mut: bool, span: Span) {
        match arg_ty {
            Ty::Named(n) if self.structs.contains_key(n) => {
                if !self.struct_has_decorated_field_of_ty(n, want, require_mut) {
                    let mut_note = if require_mut { " (also `mut`)" } else { "" };
                    self.error(
                        format!(
                            "`{}` argument 1 (`{}`) declares no `@export`/`@tweakable` field of type `{:?}`{}",
                            name, n, want, mut_note
                        ),
                        span,
                    );
                }
            }
            Ty::Named(n) if matches!(n.as_str(), "unknown" | "infer_error" | "infer" | "Self") => {}
            t => self.error(format!("`{}` argument 1 must be a struct value, found `{:?}`", name, t), span),
        }
    }

    /// Render a `BinOp` back to its source spelling, for diagnostics -- the
    /// same small match every `infer_binop_ty` branch already repeats
    /// locally for its own error messages, factored out just for the two
    /// operator-overloading diagnostics below (not a wholesale refactor of
    /// every existing inline copy, to keep this change scoped).
    fn binop_symbol(op: &BinOp) -> &'static str {
        match op {
            BinOp::Add => "+", BinOp::Sub => "-", BinOp::Mul => "*", BinOp::Div => "/", BinOp::Rem => "%",
            BinOp::Eq => "==", BinOp::Ne => "!=", BinOp::Lt => "<", BinOp::Gt => ">", BinOp::Le => "<=", BinOp::Ge => ">=",
            BinOp::And => "&&", BinOp::Or => "||",
            BinOp::BitAnd => "&", BinOp::BitOr => "|", BinOp::BitXor => "^", BinOp::Shl => "<<", BinOp::Shr => ">>",
        }
    }

    /// The canonical `(trait, method)` pair an operator maps to when
    /// overloaded on a user struct, e.g. `+` -> `("Add", "add")` for an
    /// `impl Add for Point: fn add(self, rhs: Self) -> Self:` block. `None`
    /// for `&&`/`||`, which stay `bool`-only and are never overloadable.
    ///
    /// `==`/`!=` share the single `Eq` trait's `eq` method -- `!=` is
    /// desugared to `!eq(...)` by `try_operator_overload_call`, mirroring
    /// how `PartialEq::ne` is derived from `eq` in languages with the same
    /// split, so implementing `Eq` is enough to get both operators. `< > <=
    /// >=` are four independent methods on one `Ord` trait rather than
    /// derived from a single `cmp`-style method: this language has no
    /// `Ordering`-shaped return type to invent for that, and a trait
    /// declaring only a subset (say, just `lt`) naturally yields support for
    /// only the corresponding operator (`<`) rather than an all-or-nothing
    /// requirement.
    fn operator_trait_method(op: &BinOp) -> Option<(&'static str, &'static str)> {
        Some(match op {
            BinOp::Add => ("Add", "add"),
            BinOp::Sub => ("Sub", "sub"),
            BinOp::Mul => ("Mul", "mul"),
            BinOp::Div => ("Div", "div"),
            BinOp::Rem => ("Rem", "rem"),
            BinOp::Eq | BinOp::Ne => ("Eq", "eq"),
            BinOp::Lt => ("Ord", "lt"),
            BinOp::Gt => ("Ord", "gt"),
            BinOp::Le => ("Ord", "le"),
            BinOp::Ge => ("Ord", "ge"),
            BinOp::And | BinOp::Or => return None,
            // Never overloadable on a struct: `&`/`|`/`^`/`<<`/`>>` only
            // ever reach `infer_bitwise_combine_ty`/`infer_shift_ty`
            // (`Ty::bit_shape()`/`bitwise_combine_shape()`-restricted, never
            // a `Ty::Named` struct), so `try_operator_overload_call`'s
            // caller never has a struct-typed `lhs_ty` to look this up for
            // in the first place -- same reasoning as `And`/`Or` above.
            BinOp::BitAnd | BinOp::BitOr | BinOp::BitXor | BinOp::Shl | BinOp::Shr => return None,
        })
    }

    /// Desugar `lhs op rhs` into an ordinary method call (`lhs.add(rhs)`,
    /// `lhs.eq(rhs)`, ...) whenever `lhs`'s type is a struct that nominally
    /// implements the trait `op` canonically maps to (see
    /// `operator_trait_method`) -- reusing the exact same, already-tested
    /// method-call type-checking (`self.methods`'s argument/return-type
    /// checks via `check_call_args`) and codegen (`Codegen::emit_call_expr`'s
    /// `TypedExpr::Field` branch) a hand-written `.add(...)` call would get,
    /// rather than inventing a second, parallel dispatch path just for
    /// operator syntax -- so a synthesized call here needs zero codegen
    /// changes of its own.
    ///
    /// This is also what makes a trait-bounded generic body's own use of an
    /// operator work at all (`fn total<T: Add>(a: T, b: T) -> T: return a +
    /// b`): `Checker::instantiate_fn_inner` substitutes `T` with a concrete
    /// type before this function's caller (`Expr::Binary`'s own arm) ever
    /// runs, so the substituted body's `a + b` reaches this exact same
    /// check, resolved the same way a hand-written `a.add(b)` on that
    /// concrete type would be.
    ///
    /// Returns `None` -- leaving the caller to fall back to
    /// `infer_binop_ty`'s native scalar/vector dispatch, or (for `==`/`!=`)
    /// `Ty::Named`'s existing structural-comparison fallback -- whenever the
    /// operator isn't overloadable at all, the left operand isn't a struct,
    /// or that struct never wrote an `impl <Trait> for <Type>:` block for
    /// it. Only the left operand's type ever selects an implementation:
    /// there is no right-hand/`impl Add<Point> for i32`-style dispatch, so
    /// `5 + point` is never overloaded even if `Point` implements `Add`.
    fn try_operator_overload_call(&mut self, op: &BinOp, lhs_expr: &TypedExpr, rhs_expr: &TypedExpr, span: Span) -> Option<TypedExpr> {
        let lhs_ty = lhs_expr.clone().into_ty();
        let Ty::Named(struct_name) = &lhs_ty else { return None };
        let (trait_name, method_name) = Self::operator_trait_method(op)?;
        if !self.ty_implements_trait(&lhs_ty, trait_name) {
            return None;
        }
        let method_key = format!("{}#{}", struct_name, method_name);
        let (param_tys, ret_ty, has_self) = self.methods.get(&method_key)?.clone();
        let callee = TypedExpr::Field {
            base: Box::new(lhs_expr.clone()),
            field: method_name.to_string(),
            ty: Ty::Named("unknown".into()),
            span,
        };
        let args = vec![rhs_expr.clone()];
        self.check_call_args(&param_tys, has_self, &args, span);
        let mut result_ty = ret_ty.unwrap_or(Ty::Named("unknown".into()));
        let is_comparison = matches!(op, BinOp::Eq | BinOp::Ne | BinOp::Lt | BinOp::Gt | BinOp::Le | BinOp::Ge);
        if is_comparison && result_ty != Ty::Bool && !Self::is_placeholder_ty(&result_ty) {
            self.error(
                format!(
                    "`{}`'s `{}` method must return `bool` to back operator `{}`, found `{:?}`",
                    trait_name, method_name, Self::binop_symbol(op), result_ty
                ),
                span,
            );
            // Report just the one error above, not a second cascading
            // "condition must be bool"/mismatched-operand diagnostic from
            // whatever consumes this comparison next -- safe to force
            // regardless of the method's real declared return type since a
            // checker error here always aborts before codegen ever sees
            // this (possibly LLVM-type-mismatched) `ty` (see `Driver::check`).
            result_ty = Ty::Bool;
        }
        let call = TypedExpr::Call { callee: Box::new(callee), args, ty: result_ty, span };
        if matches!(op, BinOp::Ne) {
            return Some(TypedExpr::Unary { op: UnOp::Not, operand: Box::new(call), ty: Ty::Bool, span });
        }
        Some(call)
    }

    /// The unary-operator counterpart of `try_operator_overload_call`:
    /// desugars `-operand` into `operand.neg()` when `operand`'s type is a
    /// struct implementing `Neg` (`impl Neg for Point: fn neg(self) ->
    /// Self:`). Returns `None` for every other type, leaving the caller's
    /// existing (struct-excluding, see that call site's own comment)
    /// `infer_binop_ty(Sub, ...)`-based legality check for plain
    /// numeric/vector negation untouched.
    fn try_neg_overload_call(&mut self, operand_expr: &TypedExpr, span: Span) -> Option<TypedExpr> {
        let operand_ty = operand_expr.clone().into_ty();
        let Ty::Named(struct_name) = &operand_ty else { return None };
        if !self.ty_implements_trait(&operand_ty, "Neg") {
            return None;
        }
        let method_key = format!("{}#neg", struct_name);
        let (param_tys, ret_ty, has_self) = self.methods.get(&method_key)?.clone();
        let callee = TypedExpr::Field {
            base: Box::new(operand_expr.clone()),
            field: "neg".to_string(),
            ty: Ty::Named("unknown".into()),
            span,
        };
        self.check_call_args(&param_tys, has_self, &[], span);
        let result_ty = ret_ty.unwrap_or(Ty::Named("unknown".into()));
        Some(TypedExpr::Call { callee: Box::new(callee), args: Vec::new(), ty: result_ty, span })
    }

    /// Infer the result type of a binary operator, dispatching on whether
    /// either operand is a builtin vector/matrix type. Falls through to the
    /// original Int/Float/Bool behavior when both operands are scalar.
    ///
    /// `todo.md` P2 #7 (binop-dispatch unification, arithmetic-bearing types):
    /// `Wrapping<T>`/`Fixed<Bits,Frac>` are folded into one shared branch
    /// below -- once `Fixed`'s `%` rejection is special-cased out, both
    /// families are the exact same shape (every arithmetic/comparison
    /// operator, exact `lhs_ty == rhs_ty` required, no implicit widening),
    /// the same reasoning `Ty::eq_only_scalar_shape` already applies one
    /// level down to `Symbol`/`BitField<N>`/`Flags<E>`/`Color32`/
    /// `PaletteIndex`. `Tick`/`Duration`/`Instant` deliberately stay their
    /// own dedicated function (`infer_time_binop_ty`) instead of joining that
    /// branch: their legal pairings are *asymmetric* per operator and per
    /// type (`Tick + i64 -> Tick`, `Tick - Tick -> i64`, `Instant - Instant
    /// -> Duration`, `Instant + Duration -> Instant`, ...), so unifying them
    /// would require a per-`(lhs, op, rhs)` result-type table rather than one
    /// shared "operands match, result mirrors operand type" rule -- at that
    /// point it stops being a shared *shape* and just becomes the dedicated
    /// dispatch table it already is. This split is the permanent decision,
    /// not a placeholder: a future contributor adding a fourth `Wrapping`/
    /// `Fixed`-shaped type gets one new match arm in the shared branch below;
    /// a future asymmetric time-like type gets its own `infer_*_binop_ty`
    /// sibling instead, same as `Tick`/`Duration`/`Instant` today.
    /// `a & b` / `a | b` / `a ^ b` -- the operator-syntax counterpart of the
    /// `bit_and`/`bit_or`/`bit_xor` free functions' own type checking
    /// (`"bit_and" | "bit_or" | "bit_xor"` arm, this same file), sharing the
    /// identical `Ty::bitwise_combine_shape()` legality: any integer width,
    /// `Wrapping<T>`, `BitField<N>`, or `Flags<E>`, with both operands
    /// required to be the exact same type (no implicit widening, matching
    /// every other sized-numeric operator in this compiler). Returns
    /// `lhs_ty` (a placeholder-tolerant best-effort type) on any mismatch so
    /// a caller building a `TypedExpr::Binary` around this still has
    /// *something* to attach, the same "error once, keep going" convention
    /// `infer_binop_ty`'s other branches already follow.
    fn infer_bitwise_combine_ty(&mut self, op: &BinOp, lhs_ty: &Ty, rhs_ty: &Ty, span: Span) -> Ty {
        let sym = match op {
            BinOp::BitAnd => "&",
            BinOp::BitOr => "|",
            BinOp::BitXor => "^",
            _ => unreachable!("caller only routes BitAnd/BitOr/BitXor here"),
        };
        if lhs_ty.bitwise_combine_shape().is_none() && !Self::is_placeholder_ty(lhs_ty) {
            self.error(
                format!(
                    "`{}` left operand expected an integer/`Wrapping<T>`/`BitField<N>`/`Flags<E>` value, found `{:?}`",
                    sym, lhs_ty
                ),
                span,
            );
            return lhs_ty.clone();
        }
        if lhs_ty != rhs_ty && !Self::is_placeholder_ty(rhs_ty) {
            self.error(
                format!("`{}` operands must be the same type, found `{:?}` and `{:?}`", sym, lhs_ty, rhs_ty),
                span,
            );
        }
        lhs_ty.clone()
    }

    /// `a << b` / `a >> b`. The left operand accepts any `Ty::bit_shape()`
    /// type (any integer width, `Wrapping<T>`, `BitField<N>` -- deliberately
    /// *not* `Flags<E>`, unlike the `&`/`|`/`^` trio just above: shifting a
    /// flag mask bit-by-bit isn't a meaningful set operation the way union/
    /// intersect/symmetric-difference are, see `Ty::bitwise_combine_shape`'s
    /// doc comment for the same reasoning applied to `bit_not`). The right
    /// operand (the shift count) is always plain `int` regardless of the
    /// left operand's own type -- the same "index/count operand is always
    /// `int`" convention `bit_get`'s second argument already established --
    /// *not* required to match the left operand's type the way `&`/`|`/`^`
    /// require an exact pair, since a shift count is conceptually a small
    /// magnitude, not a same-shaped value to combine bits with. Returns the
    /// left operand's own type either way, matching every other
    /// same-type-in-same-type-out sized-integer operator.
    fn infer_shift_ty(&mut self, lhs_ty: &Ty, rhs_ty: &Ty, span: Span) -> Ty {
        if lhs_ty.bit_shape().is_none() && !Self::is_placeholder_ty(lhs_ty) {
            self.error(
                format!("`<<`/`>>` left operand expected an integer/`Wrapping<T>`/`BitField<N>` value, found `{:?}`", lhs_ty),
                span,
            );
            return lhs_ty.clone();
        }
        if *rhs_ty != Ty::Int && !Self::is_placeholder_ty(rhs_ty) {
            self.error(format!("`<<`/`>>` right operand (shift count) expected `int`, found `{:?}`", rhs_ty), span);
        }
        lhs_ty.clone()
    }

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
        // `&`/`|`/`^` and `<<`/`>>` get their own dedicated dispatch, the
        // same way `&&`/`||` do just above -- their legal operand set
        // (`Ty::bit_shape()`/`Ty::bitwise_combine_shape()`: any integer
        // width, `Wrapping<T>`, `BitField<N>`, and for the combine trio also
        // `Flags<E>`) has nothing to do with `is_numeric()`/vec/mat dispatch
        // below, and reuses the exact same shape queries the `bit_get`/
        // `bit_and`/etc. free functions already validate against
        // (`todo.md` P0 #3 -- these are the real operator-syntax surface for
        // what those free functions could previously only offer as calls).
        if matches!(op, BinOp::BitAnd | BinOp::BitOr | BinOp::BitXor) {
            return self.infer_bitwise_combine_ty(op, lhs_ty, rhs_ty, span);
        }
        if matches!(op, BinOp::Shl | BinOp::Shr) {
            return self.infer_shift_ty(lhs_ty, rhs_ty, span);
        }
        let is_cmp = matches!(op, BinOp::Eq | BinOp::Ne | BinOp::Lt | BinOp::Gt | BinOp::Le | BinOp::Ge);
        // `Tick`/`Duration`/`Instant` get their own dedicated dispatch too --
        // unlike `Wrapping`/`Fixed` just below, their legal operator set is
        // *asymmetric* (e.g. `Instant - Instant -> Duration` but
        // `Instant + Duration -> Instant`), so it's factored into its own
        // function rather than squeezed into this uniform "operands must
        // match exactly" shape. See `Ty::Tick`'s doc comment for the full
        // legal-pairing table.
        if matches!(lhs_ty, Ty::Tick | Ty::Duration | Ty::Instant) || matches!(rhs_ty, Ty::Tick | Ty::Duration | Ty::Instant) {
            return self.infer_time_binop_ty(op, lhs_ty, rhs_ty, span);
        }
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
                BinOp::BitAnd | BinOp::BitOr | BinOp::BitXor | BinOp::Shl | BinOp::Shr => {
                    unreachable!("handled above, before Wrapping/Fixed are ever reached")
                }
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
                // `bool == bool` / `!=` -- a single `i1` comparison. No
                // ordering: `Ty::Bool` isn't `is_numeric()` (deliberately --
                // see that method's doc comment), so it never reached
                // `emit_scalar_binop` above, and fell all the way through to
                // this function's own "not supported" fallback for *every*
                // operator, `==`/`!=` included -- confirmed live (`star
                // check` on a bare `println(f"{true == false}")` rejects it
                // outright), a real gap despite `bool` being one of this
                // codebase's own oldest, most basic types.
                if *lhs_ty == Ty::Bool && *rhs_ty == Ty::Bool {
                    if !matches!(op, BinOp::Eq | BinOp::Ne) {
                        self.error("only `==`/`!=` are supported between `bool` values", span);
                    }
                    return Ty::Bool;
                }
                // `str == str` / `str != str`: structural byte equality,
                // lowered to the same `strcmp` comparison `Map<str, V>` key
                // lookup already uses (see `Codegen::emit_binop`'s `Str`
                // arm). Ordering comparisons stay unsupported -- there's no
                // collation story to promise anything sensible about.
                if *lhs_ty == Ty::Str && *rhs_ty == Ty::Str {
                    if !matches!(op, BinOp::Eq | BinOp::Ne) {
                        self.error("only `==`/`!=` are supported between `str` values", span);
                    }
                    return Ty::Bool;
                }
                // `Symbol`/`BitField<N>`/`Flags<E>`/`Color32`/`PaletteIndex`
                // == same type / `!=` -- a single opaque-width `icmp`, no
                // ordering (none of these have a meaningful "less than") --
                // see `Ty::eq_only_scalar_shape`'s doc comment for why this
                // is one shared table instead of five hand-copied blocks.
                if let Some((_, name)) = lhs_ty.eq_only_scalar_shape() {
                    if lhs_ty == rhs_ty {
                        if !matches!(op, BinOp::Eq | BinOp::Ne) {
                            self.error(format!("only `==`/`!=` are supported between `{}` values", name), span);
                        }
                        return Ty::Bool;
                    }
                }
                // A fieldless `enum`, a `struct` composed entirely of
                // structurally-comparable fields (recursively), or a
                // `Tuple`/`Array` of such -- exactly `Checker::check_hashable_ty`'s
                // rule for a legal `Map`/`Set` key, since `Codegen::eq_fn_name`/
                // `emit_eq_body` (already built to compare those same shapes
                // for `Map`/`Set` lookup) is what actually backs this at
                // codegen time. No ordering: same reasoning as
                // `Ty::BitField`/`Ty::Symbol` above -- a discriminant or
                // field-tuple has no meaningful "less than".
                if matches!(lhs_ty, Ty::Enum(_) | Ty::Named(_) | Ty::Tuple(_) | Ty::Array(..)) && lhs_ty == rhs_ty {
                    if !matches!(op, BinOp::Eq | BinOp::Ne) {
                        self.error(
                            format!("only `==`/`!=` are supported between `{:?}` values -- there is no ordering for an enum, struct, tuple, or array", lhs_ty),
                            span,
                        );
                        return Ty::Bool;
                    }
                    if !self.is_structurally_comparable_ty(lhs_ty) {
                        self.error(
                            format!(
                                "`{}` is not supported between `{:?}` values: only a fieldless enum, or a struct/tuple/array composed entirely of \
                                 structurally-comparable elements, supports `==`/`!=` -- a payload-carrying enum or anything containing a \
                                 `GenRef`/`List`/`Map`/`Set`/closure/`ptr` does not",
                                op_str, lhs_ty
                            ),
                            span,
                        );
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

        // `Quat * Quat` computes the true quaternion (Hamilton) product, the
        // operation that actually composes two rotations -- not a
        // componentwise multiply, which is what falling through to the
        // generic `is_vec() && is_vec()` branch below would give (`Ty::Quat`
        // is included in `is_vec()`/`vec_arity()` purely so field access/
        // `+`/`-`/scalar `*`/`/`/`dot`/`length`/`lerp` fall out for free --
        // see `Ty::Quat`'s doc comment). Checked ahead of the generic
        // dispatch below for exactly that reason.
        if *op == BinOp::Mul && *lhs_ty == Ty::Quat && *rhs_ty == Ty::Quat {
            return Ty::Quat;
        }

        match op {
            BinOp::Add | BinOp::Sub => {
                if lhs_ty.is_mat() && rhs_ty.is_mat() {
                    if lhs_ty == rhs_ty { lhs_ty.clone() } else {
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
                // The matrix's own row-vector type, e.g. `Mat3` -> `Vec3` --
                // generalizes the old `Mat4`-only `*rhs_ty == Ty::Vec4` check
                // (`Ty::vec_of_arity`/`Ty::mat_dim` didn't exist before
                // `Mat2`/`Mat3` landed, since `Mat4` was the only matrix type).
                let mat_vec_ty = |t: &Ty| t.mat_dim().and_then(|d| Ty::vec_of_arity(d as u8));
                if lhs_ty.is_mat() && rhs_ty.is_mat() {
                    if *op == BinOp::Div {
                        self.error("matrix division is not supported", span);
                    }
                    if lhs_ty != rhs_ty {
                        self.error("mismatched matrix arity in `*`", span);
                    }
                    lhs_ty.clone()
                } else if lhs_ty.is_mat() && mat_vec_ty(lhs_ty).as_ref() == Some(rhs_ty) {
                    if *op == BinOp::Div {
                        self.error("matrix division is not supported", span);
                    }
                    rhs_ty.clone()
                } else if rhs_ty.is_mat() && mat_vec_ty(rhs_ty).as_ref() == Some(lhs_ty) {
                    self.error("vector * matrix is not supported (use matrix * vector)", span);
                    lhs_ty.clone()
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

    /// Dedicated binop dispatch for `Tick`/`Duration`/`Instant`
    /// (`docs/design.md`'s "Time" section), mirroring Rust's own
    /// `std::time::{Instant,Duration}` operator set:
    /// - `Tick + i64 -> Tick` / `Tick - i64 -> Tick` (advance/rewind by a
    ///   step count), `Tick - Tick -> i64` (a tick delta)
    /// - `Duration + Duration -> Duration` / `Duration - Duration ->
    ///   Duration`
    /// - `Instant - Instant -> Duration` (elapsed time), `Instant +
    ///   Duration -> Instant` / `Instant - Duration -> Instant`
    /// - `==`/`!=`/`<`/`>`/`<=`/`>=` between two values of the *same* one of
    ///   these three types
    ///
    /// Every other pairing (including mixing `Tick`/`Duration`/`Instant`
    /// with each other outside the table above, or with a bare `i32`) is a
    /// hard error -- there is no implicit anything here, same "no implicit
    /// widening" philosophy every other explicit-width type in
    /// `docs/design.md`'s "Numeric widths and modes" already follows.
    fn infer_time_binop_ty(&mut self, op: &BinOp, lhs_ty: &Ty, rhs_ty: &Ty, span: Span) -> Ty {
        let is_cmp = matches!(op, BinOp::Eq | BinOp::Ne | BinOp::Lt | BinOp::Gt | BinOp::Le | BinOp::Ge);
        match (lhs_ty, op, rhs_ty) {
            (Ty::Tick, BinOp::Add | BinOp::Sub, Ty::I64) => return Ty::Tick,
            (Ty::Tick, BinOp::Sub, Ty::Tick) => return Ty::I64,
            (Ty::Duration, BinOp::Add | BinOp::Sub, Ty::Duration) => return Ty::Duration,
            (Ty::Instant, BinOp::Sub, Ty::Instant) => return Ty::Duration,
            (Ty::Instant, BinOp::Add | BinOp::Sub, Ty::Duration) => return Ty::Instant,
            _ => {}
        }
        if is_cmp && lhs_ty == rhs_ty && matches!(lhs_ty, Ty::Tick | Ty::Duration | Ty::Instant) {
            return Ty::Bool;
        }
        let op_str = match op {
            BinOp::Add => "+", BinOp::Sub => "-", BinOp::Mul => "*",
            BinOp::Div => "/", BinOp::Rem => "%",
            BinOp::Eq => "==", BinOp::Ne => "!=",
            BinOp::Lt => "<", BinOp::Gt => ">", BinOp::Le => "<=", BinOp::Ge => ">=",
            BinOp::And | BinOp::Or => unreachable!("handled by infer_binop_ty before this is ever called"),
            BinOp::BitAnd | BinOp::BitOr | BinOp::BitXor | BinOp::Shl | BinOp::Shr => {
                unreachable!("handled by infer_binop_ty before this is ever called")
            }
        };
        self.error(
            format!("`{}` is not supported between `{:?}` and `{:?}`", op_str, lhs_ty, rhs_ty),
            span,
        );
        if is_cmp { Ty::Bool } else { lhs_ty.clone() }
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
            // Every other concrete type (`Mat4`, `Tick`/`Duration`/
            // `Instant`, `str`, `bool`, `List<T>`/`Map<K,V>`/`Set<T>`/
            // `Table<T>`, every numeric width, an enum value, ...) has no
            // fields at all -- unlike the `Ty::Named` branch below, whose
            // "not a known struct" case can legitimately be a synthesized/
            // inferred placeholder standing in for an error already
            // reported elsewhere, a non-`Named`/non-vec type here is always
            // a fully concrete, already-resolved type. Silently falling
            // through (as this used to, returning `unknown` with no
            // diagnostic) let something like `mat4_value.x` or
            // `some_option.field` type-check with zero errors, only to
            // blow up later at codegen with an unlocated "field access on
            // non-struct type" that names neither the offending field nor
            // its type. Report it here instead, mirroring the struct
            // branch's own "no field on struct" diagnostic below.
            _ => {
                self.error(format!("no field `{}` on type `{:?}`", field, base_ty), span);
                return Ty::Named("unknown".into());
            }
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
            // `r`/`g`/`b`/`a` are accepted as aliases of `x`/`y`/`z`/`w` --
            // `docs/design.md`'s "Math and geometry" section: `Ty::Color`
            // reuses `Vec4`'s exact layout (see its own doc comment), and a
            // color's channels are conventionally named `r`/`g`/`b`/`a`
            // rather than `x`/`y`/`z`/`w`, even though it's a `Vec4` under
            // the hood -- there's no reason to reject the vector spelling
            // either, so both are always accepted regardless of the base's
            // concrete type (`Vec2`/`Vec3`/`Vec4`/`Quat`/`Color`).
            let idx = match c {
                'x' | 'r' => 0,
                'y' | 'g' => 1,
                'z' | 'b' => 2,
                'w' | 'a' => 3,
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
