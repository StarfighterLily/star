//! Statement type-checking.

use std::collections::{HashMap, HashSet};

use crate::ast::*;
use crate::diagnostics::Span;

use super::*;

impl Checker {
    pub(super) fn check_stmt(&mut self, stmt: &Stmt, vars: &mut HashMap<String, Ty>) -> Option<TypedStmt> {
        Some(match stmt {
            Stmt::Let { is_mut, name, ty, value, span } => {
                let annotated_ty = ty.as_ref().and_then(|t| self.resolve_type(t));
                // A bracket literal (`[a, b, c]`) against a `[T; N]`
                // annotation with a matching element count is coerced to a
                // fixed-size array instead of falling into `Expr::ListLit`'s
                // default `List<T>` inference -- see
                // `Checker::try_infer_array_lit`'s doc comment, `todo.md` P2
                // #10. Anything that doesn't match (no annotation, a
                // non-array annotation, a count mismatch) falls straight
                // through to the exact same `infer_expr` call this always
                // ran, so `let l = [1, 2, 3]` and `let l: List<i32> = [1, 2,
                // 3]` are both unaffected.
                let value_typed = match (value, &annotated_ty) {
                    (Expr::ListLit(elems, lspan), Some(expected)) => self
                        .try_infer_array_lit(elems, expected, vars, *lspan)
                        .unwrap_or_else(|| self.infer_expr(value, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))),
                    _ => self.infer_expr(value, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into()))),
                };
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
                // A re-`let` of the same name (shadowing) rebinds its
                // mutability too -- `let mut x = 1; let x = 2;` makes the
                // second `x` immutable again, regardless of the first's.
                if *is_mut {
                    self.mut_vars.insert(name.clone());
                } else {
                    self.mut_vars.remove(name);
                }
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
                // `s[i] = ...`: unlike `ListIndex`/`GenRefIndex`, `str` has no
                // mutating methods at all -- `StrIndex` exists for reads
                // only. Rejected here rather than left to `Codegen::emit_place`'s
                // generic fallback, which would silently spill the assigned
                // value into a dead alloca (a byte written nowhere) instead
                // of erroring.
                if let TypedExpr::StrIndex { .. } = &target_typed {
                    self.error("cannot assign into a `str` index -- strings are immutable in Star", *span);
                }
                // `table[i].field = v` (and any deeper chain rooted at one --
                // `table[i].field[j] = v`, `table[i].nested.x = v`, ...) used
                // to be rejected here: `Codegen::emit_place` had no way to
                // address a single field's storage through a table index, so
                // the write would silently target a disconnected temporary
                // instead of the real column. `Codegen::emit_place`'s `Field`
                // arm now special-cases a `TableIndex` base directly
                // (`Codegen::emit_table_field_place`), addressing that
                // column slot for real, so this is accepted like any other
                // place -- see `Ty::Table`'s doc comment.
                // `mut` is required to change state (`docs/design.md`): the
                // binding an assignment ultimately writes through -- `x`,
                // `x.f`, `x[i]`, `self.f`, ... -- must have been declared
                // `mut` (a `let mut`, a `mut` parameter, or `fn foo(mut
                // self)`). Previously nothing checked this at all; every
                // binding was silently mutable regardless of the keyword.
                if let Some(root) = Self::assign_root_name(&target_typed) {
                    if !self.mut_vars.contains(root) {
                        let subject = if root == "self" { "self".to_string() } else { format!("`{}`", root) };
                        self.error(
                            format!("cannot assign to {} -- it was not declared `mut`", subject),
                            *span,
                        );
                    }
                }
                // A struct field can independently be declared without
                // `mut` (`name: String` vs `mut health: i32`), so even a
                // `mut`-bound receiver can still have specific fields that
                // may only ever be set once (at construction).
                if let TypedExpr::Field { base, field, .. } = &target_typed {
                    if self.field_is_mut(&base.clone().into_ty(), field) == Some(false) {
                        self.error(format!("field `{}` is not mutable -- declare it `mut {}: ...` to allow assignment", field, field), *span);
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
                if matches!(op, AssignOp::Shl | AssignOp::Shr) {
                    // `<<=`/`>>=` are the one compound-assign pair whose rhs
                    // is never the same type as the target -- a shift count
                    // is always `int` regardless of what's being shifted
                    // (`reg: mut u8 = 1; reg <<= 4`), the same asymmetry
                    // plain `<<`/`>>` already have (see `infer_shift_ty`).
                    // The generic `types_compatible` gate below assumes a
                    // shared type on both sides (built for `=`/`+=`/`&=`/...),
                    // so it's bypassed here in favor of `infer_binop_ty`'s
                    // own shift-specific legality check.
                    let binop = if matches!(op, AssignOp::Shl) { BinOp::Shl } else { BinOp::Shr };
                    self.infer_binop_ty(&binop, &target_ty, &value_ty, *span);
                } else if !Self::types_compatible(&target_ty, &value_ty) {
                    self.error(
                        format!("cannot assign a value of type `{:?}` to a target of type `{:?}`", value_ty, target_ty),
                        *span,
                    );
                } else if let Some(binop) = match op {
                    AssignOp::Eq => None,
                    AssignOp::Add => Some(BinOp::Add),
                    AssignOp::Sub => Some(BinOp::Sub),
                    AssignOp::Mul => Some(BinOp::Mul),
                    AssignOp::Div => Some(BinOp::Div),
                    AssignOp::BitAnd => Some(BinOp::BitAnd),
                    AssignOp::BitOr => Some(BinOp::BitOr),
                    AssignOp::BitXor => Some(BinOp::BitXor),
                    AssignOp::Shl | AssignOp::Shr => unreachable!("handled above"),
                } {
                    // `types_compatible` alone isn't enough for a compound
                    // op: `s: mut str = "a"; s += "b"` has a compatible
                    // (`Str`, `Str`) pair but `+=` still isn't defined for
                    // `str` -- reuse `infer_binop_ty`'s own operand-type
                    // legality checks (numeric scalars, vec/mat where
                    // supported) rather than drifting out of sync with what
                    // plain `x + y` binary expressions already accept/reject.
                    self.infer_binop_ty(&binop, &target_ty, &value_ty, *span);
                }
                TypedStmt::Assign { target: target_typed, op: *op, value: value_typed, span: *span }
            }
            Stmt::Return { value, span } => {
                // Mirrors `Stmt::Let`'s identical array-literal coercion
                // (`Checker::try_infer_array_lit`, `todo.md` P2 #10):
                // `return [a, b, c]` against a `[T; N]`-returning function
                // with a matching element count is coerced to a fixed-size
                // array instead of `Expr::ListLit`'s default `List<T>`.
                let value_typed = match (value, self.current_ret_ty.clone()) {
                    (Some(Expr::ListLit(elems, lspan)), Some(Some(expected))) => Some(
                        self.try_infer_array_lit(elems, &expected, vars, *lspan)
                            .unwrap_or_else(|| self.infer_expr(value.as_ref().unwrap(), vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))),
                    ),
                    _ => value.as_ref().map(|v| self.infer_expr(v, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))),
                };
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
            Stmt::Frame { budget, body, span } => {
                // The parser already rejected a non-positive literal (see
                // `Parser::parse_frame_stmt`); only the upper bound needs
                // checking here, mirroring `Item::Arena`'s own capacity
                // check. An out-of-range budget still resolves to a valid
                // (clamped) value rather than abandoning the block, so the
                // rest of this program's diagnostics stay meaningful
                // instead of cascading from one bad literal.
                let resolved_budget = match budget {
                    Some(n) if *n > MAX_FRAME_BUDGET => {
                        self.error(
                            format!("`frame` budget {} exceeds the maximum of {} bytes", n, MAX_FRAME_BUDGET),
                            *span,
                        );
                        MAX_FRAME_BUDGET
                    }
                    Some(n) => *n,
                    None => DEFAULT_FRAME_BUDGET,
                };
                let body_typed = self.check_block_inner(body, &mut vars.clone());
                TypedStmt::Frame { budget: resolved_budget, body: body_typed, span: *span }
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
                // `par`/`swarm`'s whole reason to exist is safe, disjointness-
                // proven in-place mutation of each worker's own arena element
                // -- there's no `mut` keyword available in `par var in arena:`
                // syntax at all, so `var` is implicitly, unconditionally
                // mutable for the body's duration (the actual safety
                // enforcement is `check_par_disjoint` below, not `mut`).
                let saved_mut_vars = self.mut_vars.clone();
                self.mut_vars.insert(var.clone());
                // A `par`/`swarm` body dispatches across worker threads, so
                // `break`/`continue` have no well-defined target even if this
                // statement is lexically nested inside an outer loop; hide
                // any outer loop depth for the duration of this body.
                let saved_loop_depth = self.loop_depth;
                self.loop_depth = 0;
                let body_typed = self.check_block_inner(body, &mut inner_vars);
                self.loop_depth = saved_loop_depth;
                self.mut_vars = saved_mut_vars;
                self.check_par_disjoint(var, &body_typed);
                TypedStmt::Par { var: var.clone(), elem_ty, arena: arena.clone(), body: body_typed, span: *span }
            }
            Stmt::Each { var, index_var, arena, body, span } => {
                let elem_ty = match self.arenas.get(arena) {
                    Some(t) => t.clone(),
                    None => {
                        self.error(format!("undefined arena `{}`", arena), *span);
                        Ty::Named("unknown".into())
                    }
                };
                if let Some(idx) = index_var {
                    if idx == var {
                        self.error(
                            format!("`each {} , {} in {}`: the index binding must have a different name from the element binding", var, idx, arena),
                            *span,
                        );
                    }
                }
                let mut inner_vars = vars.clone();
                inner_vars.insert(var.clone(), elem_ty.clone());
                if let Some(idx) = index_var {
                    // The raw slot index, `i32` to match `despawn`'s own
                    // index operand type (`check_despawn_stmt` below) -- so
                    // `despawn ArenaName[idx]` type-checks with no cast.
                    inner_vars.insert(idx.clone(), Ty::Int);
                }
                // Sequential (single-threaded) iteration, unlike `par`/
                // `swarm` -- there's no concurrency to prove disjoint, so
                // `var` is implicitly mutable (mirrors `Stmt::Par`'s own
                // "no `mut` keyword in the syntax" reasoning) but the body is
                // otherwise checked exactly like any ordinary loop body: no
                // `check_par_disjoint` call, and `break`/`continue` are valid
                // and target *this* loop (`loop_depth` is incremented, not
                // hidden, unlike `Stmt::Par` above).
                let saved_mut_vars = self.mut_vars.clone();
                self.mut_vars.insert(var.clone());
                self.loop_depth += 1;
                let body_typed = self.check_block_inner(body, &mut inner_vars);
                self.loop_depth -= 1;
                self.mut_vars = saved_mut_vars;
                TypedStmt::Each {
                    var: var.clone(),
                    index_var: index_var.clone(),
                    elem_ty,
                    arena: arena.clone(),
                    body: body_typed,
                    span: *span,
                }
            }
            // Every `yield` inside a `sequence` body is consumed by the
            // desugaring pass in `check()` before this point; one reaching
            // here means it was written outside a `sequence`.
            Stmt::Yield { span } => {
                self.error("`yield` is only valid at the top level of a `sequence` body", *span);
                TypedStmt::Expr(TypedExpr::Error(Ty::Named("void".into())))
            }
            Stmt::Spawn { arena, args, arg_names, span } => self.check_spawn_stmt(arena, args, arg_names, vars, *span),
            Stmt::Despawn { arena, index, span } => self.check_despawn_stmt(arena, index, vars, *span),
            Stmt::Parallel { systems, span } => self.check_parallel_stmt(systems, *span),
        })
    }

    /// Type-check `spawn ArenaName(args...)`: resolves the arena's declared
    /// element type, checks it's a struct (the only kind of value an arena
    /// can hold), validates the argument count against the struct's field
    /// list, and packages the constructed element as a `StructLit` so
    /// codegen only has to append it to the arena's backing array.
    fn check_spawn_stmt(&mut self, arena: &str, args: &[Expr], arg_names: &[Option<String>], vars: &mut HashMap<String, Ty>, span: Span) -> TypedStmt {
        let (arena, elem) = self.resolve_spawn_elem(arena, args, arg_names, vars, span);
        TypedStmt::Spawn { arena, elem, span }
    }

    /// Shared arena/argument resolution behind both `spawn`'s statement form
    /// (`check_spawn_stmt` above, discards the result) and its expression
    /// form (`Checker::infer_expr`'s `Expr::Spawn` arm, which additionally
    /// types the whole thing as `Ty::Int` -- see `Expr::Spawn`'s doc
    /// comment). Returns the resolved arena name plus the constructed
    /// element (a `StructLit`) so codegen only has to append it to the
    /// arena's backing array.
    pub(super) fn resolve_spawn_elem(
        &mut self,
        arena: &str,
        args: &[Expr],
        arg_names: &[Option<String>],
        vars: &mut HashMap<String, Ty>,
        span: Span,
    ) -> (String, TypedExpr) {
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
        // `spawn` constructs the arena's element struct, so the same named-
        // argument matching and default-filling as an ordinary struct
        // literal applies -- see `resolve_ctor_arg_exprs`.
        let resolved_args: Vec<Expr> = match self.ctor_field_list(&elem_name) {
            Some((field_names, defaults)) => {
                match self.resolve_ctor_arg_exprs(&format!("`spawn {}(..)`", arena), &field_names, &defaults, args, arg_names, span) {
                    Ok(v) => v,
                    Err(true) => {
                        // Already reported; don't let the arity check below
                        // pile a second diagnostic onto the same spawn.
                        let elem = TypedExpr::StructLit { name: elem_name, args: Vec::new(), ty: elem_ty, span };
                        return (arena.to_string(), elem);
                    }
                    Err(false) => args.to_vec(),
                }
            }
            None => {
                if arg_names.iter().any(|n| n.is_some()) {
                    self.error(
                        format!("named arguments are not supported for `spawn {}(..)` -- `{}` has no user-declared fields", arena, elem_name),
                        span,
                    );
                }
                args.to_vec()
            }
        };
        let args = &resolved_args;
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
        (arena.to_string(), elem)
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
