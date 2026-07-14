//! Desugars `sequence` items into a plain `struct` + `impl` pair before type
//! checking ever sees them.
//!
//! A `sequence Name(params): <body with top-level `yield`s>` becomes:
//! - a `struct Name` whose fields are the sequence's params, its hoisted
//!   top-level locals, and a trailing `state: i32` field;
//! - an `impl Name: fn resume(mut self) -> bool` whose body is a nested
//!   `if self.state == 0: ... else: if self.state == 1: ... else: ...`
//!   chain, one arm per `yield`-delimited segment of the original body.
//!
//! Every reference to a param or hoisted local inside the body is rewritten
//! to a `self.<name>` field access, since those values must now live in the
//! struct (not on the stack) to survive across ticks. Running the rest of
//! the pipeline (checker, codegen) over the desugared struct/impl requires
//! no coroutine-specific support anywhere else, other than codegen zero-
//! filling the `state`/hoisted-local fields that the `Name(...)` call site
//! never supplies (see `Codegen::zero_value`).
//!
//! Limitation: `yield` is only supported at the top level of a `sequence`
//! body, not nested inside `if`/`while`/`frame`. Supporting arbitrary nested
//! `yield` would require a full CFG-based state-machine transform; this
//! covers the common "flat script" coroutine shape (do a step, yield, do the
//! next step, yield, ...).

use crate::ast::*;
use crate::diagnostics::{Diagnostic, Span};
use std::collections::HashSet;

/// Replace every `Item::Sequence` in `module` with its desugared
/// `Item::Struct` + `Item::Impl` pair. Returns any errors found while
/// desugaring (e.g. `yield` nested inside control flow, or a hoisted local
/// missing an explicit type annotation); the returned module is only
/// meaningful when the error list is empty.
pub fn desugar_module(module: &Module) -> (Module, Vec<Diagnostic>) {
    let mut items = Vec::new();
    let mut errors = Vec::new();
    for item in &module.items {
        match item {
            Item::Sequence(seq) => match desugar_sequence(seq) {
                Ok((struct_def, impl_block)) => {
                    items.push(Item::Struct(struct_def));
                    items.push(Item::Impl(impl_block));
                }
                Err(mut errs) => errors.append(&mut errs),
            },
            other => items.push(other.clone()),
        }
    }
    (Module { items }, errors)
}

fn desugar_sequence(seq: &SequenceDef) -> Result<(StructDef, ImplBlock), Vec<Diagnostic>> {
    let mut errors = Vec::new();
    check_no_nested_yield(&seq.body, &mut errors);

    let param_names: HashSet<String> = seq.params.iter().map(|p| p.name.clone()).collect();

    // Every param and every top-level `let` becomes a `self.<name>` field
    // access throughout the body (nested blocks included), since both must
    // live in the struct to survive across `resume()` calls.
    let mut hoist: HashSet<String> = param_names.clone();
    for stmt in &seq.body.stmts {
        if let Stmt::Let { name, ty, span, .. } = stmt {
            if ty.is_none() {
                errors.push(Diagnostic::error(
                    format!(
                        "sequence local `{}` needs an explicit type (e.g. `let mut {}: i32 = 0`); \
                         it becomes a struct field and its type can't be inferred at this stage",
                        name, name
                    ),
                    *span,
                ));
            }
            // `state: i32` is unconditionally appended as this sequence's own
            // resume-dispatch counter field below -- a param or hoisted local
            // also named `state` would silently share that one struct field
            // with the coroutine's own dispatch machinery (both a param and
            // a hoisted local become plain struct fields with no renaming),
            // corrupting control flow the moment either one writes to it.
            if name == "state" {
                errors.push(Diagnostic::error(
                    "`state` is a reserved field name in a `sequence` (used internally for \
                     resume-dispatch state) -- rename this local",
                    *span,
                ));
            }
            hoist.insert(name.clone());
        }
    }
    if let Some(p) = seq.params.iter().find(|p| p.name == "state") {
        errors.push(Diagnostic::error(
            "`state` is a reserved parameter name in a `sequence` (used internally for \
             resume-dispatch state) -- rename this parameter",
            p.span,
        ));
    }
    if !errors.is_empty() {
        return Err(errors);
    }

    // Split the top-level statements into segments at each top-level `yield`,
    // rewriting hoisted identifiers to `self.<name>` as we go.
    let mut segments: Vec<Vec<Stmt>> = vec![Vec::new()];
    for stmt in &seq.body.stmts {
        match stmt {
            Stmt::Yield { .. } => segments.push(Vec::new()),
            Stmt::Let { name, .. } if !param_names.contains(name) => {
                // A hoisted `let x: T = v` becomes `self.x = v` (the field
                // itself is declared once on the struct, not per-segment).
                let Stmt::Let { value, span, .. } = stmt else { unreachable!() };
                segments.last_mut().unwrap().push(Stmt::Assign {
                    target: self_field(name, *span),
                    op: AssignOp::Eq,
                    value: rewrite_expr(value, &hoist),
                    span: *span,
                });
            }
            other => segments.last_mut().unwrap().push(rewrite_stmt(other, &hoist)),
        }
    }

    // struct Name: <params...>, <hoisted locals (excluding params)...>, state: i32
    let mut fields: Vec<FieldDef> = seq
        .params
        .iter()
        .map(|p| FieldDef {
            is_mut: true,
            name: p.name.clone(),
            ty: p.ty.clone().unwrap_or_else(|| Type::Named("i32".into())),
            default: None,
            decorators: Vec::new(),
            span: p.span,
        })
        .collect();
    for stmt in &seq.body.stmts {
        if let Stmt::Let { name, ty, span, .. } = stmt {
            if param_names.contains(name) {
                continue;
            }
            fields.push(FieldDef {
                is_mut: true,
                name: name.clone(),
                ty: ty.clone().expect("checked above"),
                default: None,
                decorators: Vec::new(),
                span: *span,
            });
        }
    }
    fields.push(FieldDef {
        is_mut: true,
        name: "state".into(),
        ty: Type::Named("i32".into()),
        default: None,
        decorators: Vec::new(),
        span: seq.span,
    });

    let struct_def = StructDef { name: seq.name.clone(), type_params: Vec::new(), fields, span: seq.span };

    let resume_body = Block { stmts: vec![build_state_if(&segments, 0, seq.span)], span: seq.span };
    let resume_fn = FnDef {
        sig: FnSig {
            name: "resume".into(),
            type_params: Vec::new(),
            params: vec![Param { is_self: true, is_mut: true, name: "self".into(), ty: None, span: seq.span }],
            ret: Some(Type::Named("bool".into())),
            span: seq.span,
        },
        body: resume_body,
        span: seq.span,
    };
    let impl_block =
        ImplBlock { trait_name: None, type_name: seq.name.clone(), methods: vec![resume_fn], span: seq.span };

    Ok((struct_def, impl_block))
}

fn self_field(name: &str, span: Span) -> Expr {
    Expr::Field { base: Box::new(Expr::SelfExpr(span)), field: name.to_string(), span }
}

/// Build the `if self.state == idx: <segment>; self.state = next; return ...
/// else: <recurse>` chain for segment `idx` onward.
fn build_state_if(segments: &[Vec<Stmt>], idx: usize, span: Span) -> Stmt {
    let is_last = idx == segments.len() - 1;
    let cond = Expr::Binary {
        op: BinOp::Eq,
        lhs: Box::new(self_field("state", span)),
        rhs: Box::new(Expr::Int(idx as i64, span)),
        span,
    };
    let mut then_stmts = segments[idx].clone();
    let next_state = if is_last { segments.len() as i64 } else { (idx + 1) as i64 };
    then_stmts.push(Stmt::Assign {
        target: self_field("state", span),
        op: AssignOp::Eq,
        value: Expr::Int(next_state, span),
        span,
    });
    then_stmts.push(Stmt::Return { value: Some(Expr::Bool(!is_last, span)), span });

    let else_block = if is_last {
        Block { stmts: vec![Stmt::Return { value: Some(Expr::Bool(false, span)), span }], span }
    } else {
        Block { stmts: vec![build_state_if(segments, idx + 1, span)], span }
    };

    Stmt::If { cond, then_block: Block { stmts: then_stmts, span }, else_block: Some(else_block), span }
}

/// Reject `yield` anywhere nested inside `if`/`while`/`frame` (only
/// top-level `yield` is supported).
fn check_no_nested_yield(block: &Block, errors: &mut Vec<Diagnostic>) {
    for stmt in &block.stmts {
        scan_for_nested_yield(stmt, errors, false);
    }
}

fn scan_for_nested_yield(stmt: &Stmt, errors: &mut Vec<Diagnostic>, nested: bool) {
    match stmt {
        Stmt::Yield { span } => {
            if nested {
                errors.push(Diagnostic::error(
                    "`yield` is only supported at the top level of a `sequence` body \
                     (not inside `if`/`while`/`frame`)",
                    *span,
                ));
            }
        }
        Stmt::If { then_block, else_block, .. } => {
            for s in &then_block.stmts {
                scan_for_nested_yield(s, errors, true);
            }
            if let Some(e) = else_block {
                for s in &e.stmts {
                    scan_for_nested_yield(s, errors, true);
                }
            }
        }
        Stmt::While { body, else_block, .. } => {
            for s in &body.stmts {
                scan_for_nested_yield(s, errors, true);
            }
            if let Some(e) = else_block {
                for s in &e.stmts {
                    scan_for_nested_yield(s, errors, true);
                }
            }
        }
        Stmt::Frame { body, .. } => {
            for s in &body.stmts {
                scan_for_nested_yield(s, errors, true);
            }
        }
        Stmt::For { body, .. } => {
            for s in &body.stmts {
                scan_for_nested_yield(s, errors, true);
            }
        }
        // A `match` used as a statement is `Stmt::Expr(Expr::Match{..})`,
        // and an expression-form `if`/lambda literal reaches here the same
        // way whenever it appears as a `let`/assignment/return value or a
        // bare expression statement -- each carries its own `Block`s that
        // can just as easily hide a `yield` as `if`/`while`/`frame`/`for`
        // can, so they need the same nested scan (previously only these
        // four statement-form constructs were scanned; a `yield` inside a
        // match arm, an `if`-as-value branch, or a lambda body slipped
        // through unrecognized here and was only caught later, by the
        // generic type-checker fallback, with a strictly worse diagnostic).
        Stmt::Let { value, .. } => scan_expr_for_nested_yield(value, errors),
        Stmt::Assign { target, value, .. } => {
            scan_expr_for_nested_yield(target, errors);
            scan_expr_for_nested_yield(value, errors);
        }
        Stmt::Return { value: Some(v), .. } => scan_expr_for_nested_yield(v, errors),
        Stmt::Expr(e) => scan_expr_for_nested_yield(e, errors),
        _ => {}
    }
}

/// Look inside `expr` for a nested `Block` (a `match` arm body, an `if`-as-
/// value branch, a lambda body) that might itself contain a `yield`, and
/// scan each one found (always as `nested = true`: there is no expression
/// position from which a `yield` could ever be considered top-level).
fn scan_expr_for_nested_yield(expr: &Expr, errors: &mut Vec<Diagnostic>) {
    match expr {
        Expr::Match { scrutinee, arms, .. } => {
            scan_expr_for_nested_yield(scrutinee, errors);
            for a in arms {
                for s in &a.body.stmts {
                    scan_for_nested_yield(s, errors, true);
                }
            }
        }
        Expr::If { cond, then_block, else_block, .. } => {
            scan_expr_for_nested_yield(cond, errors);
            for s in &then_block.stmts {
                scan_for_nested_yield(s, errors, true);
            }
            if let Some(e) = else_block {
                for s in &e.stmts {
                    scan_for_nested_yield(s, errors, true);
                }
            }
        }
        Expr::Lambda { body, .. } => {
            for s in &body.stmts {
                scan_for_nested_yield(s, errors, true);
            }
        }
        Expr::FStr(parts, _) => {
            for p in parts {
                if let FStrExpr::Expr(e) = p {
                    scan_expr_for_nested_yield(e, errors);
                }
            }
        }
        Expr::Field { base, .. } => scan_expr_for_nested_yield(base, errors),
        Expr::Call { callee, args, .. } => {
            scan_expr_for_nested_yield(callee, errors);
            for a in args {
                scan_expr_for_nested_yield(a, errors);
            }
        }
        Expr::Binary { lhs, rhs, .. } => {
            scan_expr_for_nested_yield(lhs, errors);
            scan_expr_for_nested_yield(rhs, errors);
        }
        Expr::Unary { operand, .. } => scan_expr_for_nested_yield(operand, errors),
        Expr::StructLit { args, .. } | Expr::EnumVariant { args, .. } => {
            for a in args {
                scan_expr_for_nested_yield(a, errors);
            }
        }
        Expr::GenRefCreate { value, .. } => scan_expr_for_nested_yield(value, errors),
        Expr::GenRefIndex { base, index, .. } => {
            scan_expr_for_nested_yield(base, errors);
            scan_expr_for_nested_yield(index, errors);
        }
        Expr::ListLit(elems, _) => {
            for e in elems {
                scan_expr_for_nested_yield(e, errors);
            }
        }
        Expr::Try { inner, .. } => scan_expr_for_nested_yield(inner, errors),
        Expr::TupleLit(elems, _) => {
            for e in elems {
                scan_expr_for_nested_yield(e, errors);
            }
        }
        Expr::TupleIndex { base, .. } => scan_expr_for_nested_yield(base, errors),
        Expr::ArrayRepeat { value, .. } => scan_expr_for_nested_yield(value, errors),
        Expr::Int(..) | Expr::Float(..) | Expr::Str(..) | Expr::Bool(..) | Expr::Ident(..) | Expr::SelfExpr(..) => {}
    }
}

// --- identifier rewriting: hoisted names -> `self.<name>` -----------------

fn rewrite_stmt(stmt: &Stmt, hoist: &HashSet<String>) -> Stmt {
    match stmt {
        Stmt::Let { is_mut, name, ty, value, span } => {
            Stmt::Let { is_mut: *is_mut, name: name.clone(), ty: ty.clone(), value: rewrite_expr(value, hoist), span: *span }
        }
        Stmt::Assign { target, op, value, span } => {
            Stmt::Assign { target: rewrite_expr(target, hoist), op: *op, value: rewrite_expr(value, hoist), span: *span }
        }
        // A bare early `return` (aborting the sequence before it reaches its
        // next `yield`, e.g. "if target.dead: return") is passed through by
        // the old code entirely unchanged -- but the surrounding function
        // has been rewritten to a `resume(mut self) -> bool`, so a `ret
        // void` reaching a function declared to return `bool` is invalid
        // LLVM IR, caught only by the backend with no Star diagnostic
        // pointing at the offending line. An early exit has no value of its
        // own to return; `resume`'s real channel is the `bool` "not done
        // yet" signal, and aborting early is naturally "no more work to
        // do" -- the same `false` value the final segment's own implicit
        // fallthrough already returns (see `build_state_if`).
        Stmt::Return { value, span } => Stmt::Return {
            value: Some(match value {
                Some(v) => rewrite_expr(v, hoist),
                None => Expr::Bool(false, *span),
            }),
            span: *span,
        },
        Stmt::Expr(e) => Stmt::Expr(rewrite_expr(e, hoist)),
        Stmt::If { cond, then_block, else_block, span } => Stmt::If {
            cond: rewrite_expr(cond, hoist),
            then_block: rewrite_block(then_block, hoist),
            else_block: else_block.as_ref().map(|b| rewrite_block(b, hoist)),
            span: *span,
        },
        Stmt::While { cond, body, else_block, span } => Stmt::While {
            cond: rewrite_expr(cond, hoist),
            body: rewrite_block(body, hoist),
            else_block: else_block.as_ref().map(|b| rewrite_block(b, hoist)),
            span: *span,
        },
        Stmt::For { var, start, end, body, span } => {
            // `var` shadows any hoisted field of the same name for the
            // duration of the loop body -- without this, a use of `var`
            // inside `body` would be wrongly rewritten to `self.var`
            // (the outer, stale hoisted value) instead of referring to the
            // loop's own induction variable.
            let inner_hoist = without(hoist, std::slice::from_ref(var));
            Stmt::For {
                var: var.clone(),
                start: rewrite_expr(start, hoist),
                end: rewrite_expr(end, hoist),
                body: rewrite_block(body, &inner_hoist),
                span: *span,
            }
        }
        Stmt::Break { span } => Stmt::Break { span: *span },
        Stmt::Continue { span } => Stmt::Continue { span: *span },
        Stmt::Frame { body, span } => Stmt::Frame { body: rewrite_block(body, hoist), span: *span },
        Stmt::Par { var, arena, body, span } => {
            Stmt::Par { var: var.clone(), arena: arena.clone(), body: rewrite_block(body, hoist), span: *span }
        }
        Stmt::Yield { span } => Stmt::Yield { span: *span },
        Stmt::Spawn { arena, args, span } => Stmt::Spawn {
            arena: arena.clone(),
            args: args.iter().map(|a| rewrite_expr(a, hoist)).collect(),
            span: *span,
        },
        Stmt::Despawn { arena, index, span } => {
            Stmt::Despawn { arena: arena.clone(), index: rewrite_expr(index, hoist), span: *span }
        }
    }
}

fn rewrite_block(block: &Block, hoist: &HashSet<String>) -> Block {
    Block { stmts: block.stmts.iter().map(|s| rewrite_stmt(s, hoist)).collect(), span: block.span }
}

/// `hoist` minus `names` -- used to temporarily shadow hoisted fields that a
/// nested scope (a `for` loop's induction variable, a lambda's parameters, a
/// match arm's bound names) rebinds locally, so a reference to the shadowing
/// name inside that scope rewrites to the local binding instead of the outer
/// `self.<name>` field.
fn without(hoist: &HashSet<String>, names: &[String]) -> HashSet<String> {
    if names.is_empty() {
        return hoist.clone();
    }
    let mut out = hoist.clone();
    for n in names {
        out.remove(n);
    }
    out
}

/// The fresh local names a pattern binds in its arm's body, if any.
fn pattern_bound_names(pattern: &Pattern) -> Vec<String> {
    match pattern {
        Pattern::Binding(name) => vec![name.clone()],
        Pattern::EnumVariant(_, _, bindings) | Pattern::Struct(_, bindings) => bindings.clone(),
        Pattern::Wildcard | Pattern::Int(_) | Pattern::Bool(_) | Pattern::Compare(..) => Vec::new(),
    }
}

fn rewrite_pattern(pattern: &Pattern, hoist: &HashSet<String>) -> Pattern {
    match pattern {
        Pattern::Compare(op, e) => Pattern::Compare(*op, Box::new(rewrite_expr(e, hoist))),
        other => other.clone(),
    }
}

fn rewrite_expr(expr: &Expr, hoist: &HashSet<String>) -> Expr {
    match expr {
        Expr::Ident(name, span) if hoist.contains(name) => self_field(name, *span),
        Expr::Int(..) | Expr::Float(..) | Expr::Str(..) | Expr::Bool(..) | Expr::Ident(..) | Expr::SelfExpr(..) => {
            expr.clone()
        }
        Expr::FStr(parts, span) => Expr::FStr(
            parts
                .iter()
                .map(|p| match p {
                    FStrExpr::Literal(s) => FStrExpr::Literal(s.clone()),
                    FStrExpr::Expr(e) => FStrExpr::Expr(Box::new(rewrite_expr(e, hoist))),
                })
                .collect(),
            *span,
        ),
        Expr::Field { base, field, span } => {
            Expr::Field { base: Box::new(rewrite_expr(base, hoist)), field: field.clone(), span: *span }
        }
        Expr::Call { callee, args, span } => Expr::Call {
            callee: Box::new(rewrite_expr(callee, hoist)),
            args: args.iter().map(|a| rewrite_expr(a, hoist)).collect(),
            span: *span,
        },
        Expr::Binary { op, lhs, rhs, span } => {
            Expr::Binary { op: *op, lhs: Box::new(rewrite_expr(lhs, hoist)), rhs: Box::new(rewrite_expr(rhs, hoist)), span: *span }
        }
        Expr::Unary { op, operand, span } => Expr::Unary { op: *op, operand: Box::new(rewrite_expr(operand, hoist)), span: *span },
        Expr::Match { scrutinee, arms, span } => Expr::Match {
            scrutinee: Box::new(rewrite_expr(scrutinee, hoist)),
            arms: arms
                .iter()
                .map(|a| {
                    // A binding pattern (`Pattern::Binding`/`EnumVariant`/
                    // `Struct`) introduces fresh local names for the arm's
                    // body -- each one shadows a same-named hoisted field for
                    // the duration of that arm, same reasoning as the `for`
                    // loop and lambda-parameter cases above.
                    let bound = pattern_bound_names(&a.pattern);
                    let inner_hoist = without(hoist, &bound);
                    MatchArm { pattern: rewrite_pattern(&a.pattern, hoist), body: rewrite_block(&a.body, &inner_hoist), span: a.span }
                })
                .collect(),
            span: *span,
        },
        Expr::StructLit { name, type_args, args, span } => Expr::StructLit {
            name: name.clone(),
            type_args: type_args.clone(),
            args: args.iter().map(|a| rewrite_expr(a, hoist)).collect(),
            span: *span,
        },
        Expr::If { cond, then_block, else_block, span } => Expr::If {
            cond: Box::new(rewrite_expr(cond, hoist)),
            then_block: rewrite_block(then_block, hoist),
            else_block: else_block.as_ref().map(|b| rewrite_block(b, hoist)),
            span: *span,
        },
        Expr::GenRefCreate { inner_ty, value, span } => {
            Expr::GenRefCreate { inner_ty: inner_ty.clone(), value: Box::new(rewrite_expr(value, hoist)), span: *span }
        }
        Expr::GenRefIndex { base, index, span } => {
            Expr::GenRefIndex { base: Box::new(rewrite_expr(base, hoist)), index: Box::new(rewrite_expr(index, hoist)), span: *span }
        }
        Expr::EnumVariant { enum_name, type_args, variant, args, span } => Expr::EnumVariant {
            enum_name: enum_name.clone(),
            type_args: type_args.clone(),
            variant: variant.clone(),
            args: args.iter().map(|a| rewrite_expr(a, hoist)).collect(),
            span: *span,
        },
        // A lambda's own parameters aren't hoisted locals, and each one
        // shadows a same-named hoisted field for the duration of the
        // lambda's body -- without removing them from the effective hoist
        // set, a use of a shadowing parameter inside the body would be
        // wrongly rewritten to the outer `self.<name>` instead of the
        // lambda's own parameter.
        Expr::Lambda { params, ret, body, span } => {
            let param_names: Vec<String> = params.iter().map(|p| p.name.clone()).collect();
            let inner_hoist = without(hoist, &param_names);
            Expr::Lambda { params: params.clone(), ret: ret.clone(), body: rewrite_block(body, &inner_hoist), span: *span }
        }
        Expr::ListLit(elems, span) => Expr::ListLit(elems.iter().map(|e| rewrite_expr(e, hoist)).collect(), *span),
        Expr::Try { inner, span } => Expr::Try { inner: Box::new(rewrite_expr(inner, hoist)), span: *span },
        Expr::TupleLit(elems, span) => Expr::TupleLit(elems.iter().map(|e| rewrite_expr(e, hoist)).collect(), *span),
        Expr::TupleIndex { base, index, span } => {
            Expr::TupleIndex { base: Box::new(rewrite_expr(base, hoist)), index: *index, span: *span }
        }
        Expr::ArrayRepeat { value, count, span } => {
            Expr::ArrayRepeat { value: Box::new(rewrite_expr(value, hoist)), count: *count, span: *span }
        }
    }
}
