//! Closures/lambdas, fn-values, if/match-as-value
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Closures/lambdas ====================================================

/// Parse an inline-bodied lambda literal (`fn(params) -> Ret: expr`, mirroring
/// a `match` arm's own inline-body grammar) as a `let` initializer.
#[test]
fn parses_lambda_inline_body() {
    let src = "fn t():\n    let add1 = fn(x: i32) -> i32: x + 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected Let") };
    let Expr::Lambda { params, ret, body, .. } = value else { panic!("expected Expr::Lambda, got {:?}", value) };
    assert_eq!(params.len(), 1);
    assert_eq!(params[0].name, "x");
    assert_eq!(ret, &Some(Type::Named("i32".into())));
    assert!(matches!(body.stmts[0], Stmt::Expr(Expr::Binary { op: BinOp::Add, .. })));
}

/// Parse a block-bodied lambda literal (full indented block, mirroring
/// `if`/`match`'s own block-body grammar).
#[test]
fn parses_lambda_block_body() {
    let src = "fn t():\n    let f = fn(x: i32) -> i32:\n        let y = x + 1\n        y\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected Let") };
    let Expr::Lambda { body, .. } = value else { panic!("expected Expr::Lambda") };
    assert_eq!(body.stmts.len(), 2);
}

/// A `let` bound to a block-bodied lambda, followed by another statement at
/// the *same* indentation as the `let` itself, must parse -- previously the
/// lambda body's own closing `Dedent` (which re-syncs with the enclosing
/// block) was consumed by the nested `parse_block`, leaving nothing for
/// `parse_let`'s own `expect_line_end()`, which then choked on the next
/// statement's first token ("expected end of line, found an integer
/// literal"). Exact repro from todo.md's "Immediate" section.
#[test]
fn parses_let_bound_block_lambda_followed_by_sibling_statement() {
    let src = "fn t() -> i32:\n    let c = fn() -> i32:\n        let y = 1\n        y\n    0\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert_eq!(f.body.stmts.len(), 2, "both the `let` and the trailing `0` must be parsed as sibling statements");
    assert!(matches!(f.body.stmts[0], Stmt::Let { .. }));
    assert!(matches!(f.body.stmts[1], Stmt::Expr(Expr::Int(0, _))));
}

/// The same Dedent-consumption root cause, but via an `if`-expression (not
/// an `if`-statement) used as a `let` value, followed by a sibling
/// statement -- covered by the same generic `block_just_closed` fix rather
/// than a lambda-specific patch.
#[test]
fn parses_let_bound_if_expr_followed_by_sibling_statement() {
    let src = "fn t(cond: bool) -> i32:\n    let x = if cond:\n        1\n    else:\n        2\n    x + 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert_eq!(f.body.stmts.len(), 2, "both the `let` and the trailing `x + 1` must be parsed as sibling statements");
    assert!(matches!(f.body.stmts[0], Stmt::Let { .. }));
}

/// A lambda with no declared parameters and no `->` return type still
/// parses (both are optional).
#[test]
fn parses_lambda_no_params_no_ret() {
    let src = "fn t():\n    let f = fn(): 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected Let") };
    let Expr::Lambda { params, ret, .. } = value else { panic!("expected Expr::Lambda") };
    assert!(params.is_empty());
    assert!(ret.is_none());
}

/// A closure literal nested directly in a call's argument list (no `let`
/// binding) parses fine, since it doesn't itself need to consume a
/// statement-ending line -- only the call as a whole does.
#[test]
fn parses_lambda_as_call_argument() {
    let src = "fn apply(f: Fn(i32) -> i32, x: i32) -> i32:\n    f(x)\n\nfn t() -> i32:\n    apply(fn(x: i32) -> i32: x * 2, 5)\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok());
}

/// A closure-typed parameter annotation `Fn(T1, T2) -> Ret` parses to
/// `Type::Fn`.
#[test]
fn parses_fn_type_annotation() {
    let src = "fn apply(f: Fn(i32, i32) -> i32) -> i32:\n    f(1, 2)\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert_eq!(
        f.sig.params[0].ty,
        Some(Type::Fn(vec![Type::Named("i32".into()), Type::Named("i32".into())], Box::new(Type::Named("i32".into()))))
    );
}

/// `let` with no explicit annotation infers a `Ty::Closure` from a lambda
/// initializer, and a subsequent call through that variable resolves its
/// result type from the closure's own declared return type.
#[test]
fn checks_lambda_infers_closure_ty_and_call_result() {
    let ty = typed_fn_result_ty("fn t() -> i32:\n    let add1 = fn(x: i32) -> i32: x + 1\n    add1(41)\n");
    assert_eq!(ty, Ty::Int);
}

/// A lambda with no `-> Ret` annotation infers its return type from its
/// trailing expression, exactly like an `if`-expression with no annotation.
#[test]
fn checks_lambda_infers_return_type_from_body() {
    let ty = typed_fn_result_ty("fn t() -> f32:\n    let f = fn(x: f32): x * 2.0\n    f(3.0)\n");
    assert_eq!(ty, Ty::Float);
}

/// A closure captures an outer local by value: the checker resolves the
/// captured identifier's type from the enclosing scope inside the lambda
/// body, not just its own parameters.
#[test]
fn checks_lambda_captures_outer_local() {
    let ty = typed_fn_result_ty("fn t() -> i32:\n    let base = 10\n    let f = fn(x: i32) -> i32: x + base\n    f(5)\n");
    assert_eq!(ty, Ty::Int);
}

/// A closure-typed function parameter (`f: Fn(i32) -> i32`) can be called
/// like any other closure value inside the function body.
#[test]
fn checks_closure_typed_param_is_callable() {
    let module = Driver::parse("fn apply(f: Fn(i32) -> i32, x: i32) -> i32:\n    f(x)\n").expect("should parse");
    assert!(Driver::check(&module).is_ok(), "calling a closure-typed parameter should type-check");
}

/// `self` is rejected in a lambda's parameter list (lambdas have no
/// receiver).
#[test]
fn rejects_self_in_lambda_params() {
    let src = "struct S:\n    n: i32\n\nimpl S:\n    fn m(self):\n        let f = fn(self) -> i32: 1\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "`self` in a lambda's own parameter list should be a type error");
}

/// Codegen for a closure literal: the deferred top-level `closure_N`
/// function, the `{ i8*, i8* }` fat-pointer value construction (fn ptr +
/// null env ptr for a capture-free lambda), and no captured-environment
/// `malloc` call since there's nothing to capture.
#[test]
fn codegen_closure_literal_emits_deferred_function_and_fat_pointer() {
    let src = "fn t() -> i32:\n    let add1 = fn(x: i32) -> i32: x + 1\n    add1(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i32 @closure_0(i8* %envp, i32 %arg_x)"), "{}", ir);
    assert!(ir.contains("insertvalue { i8*, i8* } undef, i8*"), "{}", ir);
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    assert!(!fn_ir.contains("call i8* @malloc") && !fn_ir.contains("call i8* @star_rc_alloc"), "a capture-free closure should not allocate an environment: {}", fn_ir);
}

/// Codegen for a closure that captures an outer local: a `malloc`'d
/// environment (sized via the GEP-null/`ptrtoint` idiom) plus a store of the
/// captured value into it.
#[test]
fn codegen_closure_capturing_local_allocates_environment() {
    let src = "fn t() -> i32:\n    let base = 10\n    let f = fn(x: i32) -> i32: x + base\n    f(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("call i8* @malloc"), "a capturing closure should heap-allocate its environment: {}", ir);
    assert!(ir.contains("ptrtoint { i32 }* "), "environment size should be computed via the GEP-null/ptrtoint sizeof idiom: {}", ir);
}

/// Codegen for a call through a closure value: an indirect call bitcasting
/// the extracted `i8*` function pointer back to its real signature, rather
/// than a direct `call @name(...)`.
#[test]
fn codegen_closure_call_is_indirect() {
    let src = "fn t() -> i32:\n    let add1 = fn(x: i32) -> i32: x + 1\n    add1(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("extractvalue { i8*, i8* }"), "{}", ir);
    assert!(ir.contains("bitcast i8* %t") && ir.contains("to i32 (i8*, i32)*"), "{}", ir);
}

/// A void closure (no return value) lowers its deferred function and call
/// site to LLVM `void`, matching the existing `unknown`-means-`void`
/// convention used for ordinary functions with no declared return type.
#[test]
fn codegen_void_closure_lowers_to_void() {
    let src = "fn t():\n    let say = fn(): println(\"hi\")\n    say()\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define void @closure_0(i8* %envp)"), "{}", ir);
}

/// A closure literal is rejected inside a `par`/`swarm` body (its captured
/// environment escapes the per-iteration disjointness proof -- see
/// `Checker::walk_par_expr`'s `TypedExpr::Closure` arm).
#[test]
fn rejects_closure_inside_par_body() {
    let src = "struct P:\n    n: i32\n\narena Arena: P\n\nfn t():\n    par p in Arena:\n        let f = fn() -> i32: p.n\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "a closure literal inside a par/swarm body should be rejected");
}

/// Runtime test: `examples/closures.exe` exercises closures end to end
/// through a real clang-compiled executable -- a plain capture-free
/// closure, a closure capturing an outer immutable local, passing a
/// closure as a `Fn(i32) -> i32`-typed function argument, *returning* a
/// closure from a function (the escaping-closure case that specifically
/// exercises heap-allocating the environment rather than capturing stack
/// pointers), value-capture semantics (mutating a captured variable after
/// the closure was created must not affect what the closure already
/// snapshotted), a void closure called purely for its side effect, and (the
/// "indirect/function-pointer calls are rejected" bug) a plain top-level
/// function -- never wrapped in a lambda literal -- called directly and
/// passed as a first-class `Fn(i32) -> i32` value into `apply_twice`.
#[test]
fn runtime_closures_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/closures.exe").output().expect("failed to execute closures.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("add1(5) = 6"), "plain capture-free closure: {}", stdout);
    assert!(stdout.contains("add_base(7) = 17"), "closure capturing an outer local: {}", stdout);
    assert!(stdout.contains("apply_twice(add1, 5) = 7"), "closure passed as a Fn(i32) -> i32 argument: {}", stdout);
    assert!(stdout.contains("add_one(5) = 6"), "direct call to a plain top-level function: {}", stdout);
    assert!(stdout.contains("apply_twice(add_one, 5) = 7"), "plain top-level function passed as a Fn(i32) -> i32 value: {}", stdout);
    assert!(stdout.contains("adder(5) = 105"), "closure returned from a function (escaping, heap-allocated environment): {}", stdout);
    assert!(stdout.contains("bump() = 1"), "value-capture: mutating the captured var after closure creation must not change its snapshot: {}", stdout);
    assert!(stdout.contains("hi from a void closure"), "void closure called for its side effect: {}", stdout);
}

// ===== Bug fixes: fn-values, match-as-value, match-as-statement, method calls ====

/// A bare identifier naming a declared top-level function, used as a
/// first-class *value* (here, `let`-bound) rather than called directly,
/// is widened to the same `Ty::Closure` a lambda literal would get --
/// see `Checker::fn_value_ty`. Before this fix the identifier stayed
/// `unknown`, and codegen had no local `alloca` to load it from (it
/// names a global function, not a variable), so a plain top-level
/// function couldn't be used as an indirect/function-pointer value at all.
#[test]
fn checks_fn_name_used_as_value_gets_closure_ty() {
    let src = "fn add_one(x: i32) -> i32:\n    x + 1\n\nfn t() -> i32:\n    let f = add_one\n    f(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(t) = &typed.items[1] else { panic!("expected fn") };
    let TypedStmt::Let { value, .. } = &t.body.stmts[0] else { panic!("expected let, got {:?}", t.body.stmts[0]) };
    assert!(matches!(value.clone().into_ty(), Ty::Closure(..)), "expected Ty::Closure, got {:?}", value.clone().into_ty());
}

/// Regression guard for the direct-call fast path: a *direct* call to a
/// named top-level function (`add_one(5)`, not through a variable) must
/// keep its callee typed as a bare, unwidened `Ident` (`ty: unknown`) --
/// widening it to `Ty::Closure` here too would route every ordinary call
/// through the indirect closure-call mechanism instead of `emit_call_expr`'s
/// direct `call @name(...)` path.
#[test]
fn checks_direct_call_to_named_fn_keeps_unwidened_callee_ty() {
    let src = "fn add_one(x: i32) -> i32:\n    x + 1\n\nfn t() -> i32:\n    add_one(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(t) = &typed.items[1] else { panic!("expected fn") };
    let TypedStmt::Expr(TypedExpr::Call { callee, .. }) = &t.body.stmts[0] else { panic!("expected a call statement, got {:?}", t.body.stmts[0]) };
    assert_eq!(callee.clone().into_ty(), Ty::Named("unknown".into()), "direct-call callee must not be widened to Ty::Closure");
}

/// Codegen for a direct call to a named function stays a plain `call
/// @name(...)` -- no indirect thunk involved (mirrors
/// `checks_direct_call_to_named_fn_keeps_unwidened_callee_ty` at the
/// codegen layer).
#[test]
fn codegen_direct_call_to_named_fn_stays_direct() {
    let src = "fn add_one(x: i32) -> i32:\n    x + 1\n\nfn t() -> i32:\n    add_one(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("call i32 @add_one(i32 5)"), "{}", ir);
    assert!(!ir.contains("fnval_add_one"), "a direct call must not go through the fn-value thunk: {}", ir);
}

/// Codegen for a plain top-level function used as a value: the underlying
/// `@add_one` was emitted by `emit_fn` with the ordinary (no `i8* %envp`
/// prefix) signature every direct call uses, so referencing it as a
/// `Ty::Closure` value goes through a small generated thunk
/// (`Codegen::emit_fn_value`) that drops the incoming envp and forwards to
/// the real function, rather than bitcasting `@add_one` itself to the
/// closure-call shape (which would silently misalign every argument).
#[test]
fn codegen_fn_name_used_as_value_wraps_in_thunk() {
    let src = "fn add_one(x: i32) -> i32:\n    x + 1\n\nfn apply(f: Fn(i32) -> i32, x: i32) -> i32:\n    f(x)\n\nfn t() -> i32:\n    apply(add_one, 5)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i32 @fnval_add_one(i8* %envp, i32 %arg_0)"), "{}", ir);
    assert!(ir.contains("call i32 @add_one(i32 %arg_0)"), "the thunk should forward to the real function: {}", ir);
    assert!(ir.contains("bitcast i32 (i8*, i32)* @fnval_add_one to i8*"), "{}", ir);
}

/// `match` used as a value-producing expression: each non-terminating arm's
/// trailing expression is inferred as the arm's own type (previously always
/// stubbed to `unknown`, see `Checker::check_match_arm`), and the overall
/// `match` picks up the first arm type that isn't just the "no value"
/// placeholder.
#[test]
fn checks_match_used_as_value_infers_arm_result_ty() {
    let ty = typed_fn_result_ty("fn t(x: i32) -> i32:\n    match x:\n        <= 0 -> -1\n        _ -> 1\n");
    assert_eq!(ty, Ty::Int);
}

/// Codegen for `match` used as a value: non-terminating arms each
/// contribute `(value, block)` to a `phi` at the join block instead of the
/// match always yielding a meaningless placeholder register.
#[test]
fn codegen_match_used_as_value_emits_phi() {
    let src = "fn t(x: i32) -> i32:\n    match x:\n        <= 0 -> -1\n        _ -> 1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains(" = phi i32 ["), "{}", ir);
}

/// A `match` used purely for side effects (every arm ends in `println`, not
/// a value-producing trailing expression) must not spuriously synthesize a
/// `phi` -- regression guard for conflating the match's own `unknown`
/// "no value" placeholder with a real result type.
#[test]
fn codegen_void_match_does_not_emit_phi() {
    let src = "fn t(x: i32):\n    match x:\n        <= 0 -> println(\"neg\")\n        _ -> println(\"pos\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(!ir.contains("phi"), "a side-effect-only match should not emit a phi: {}", ir);
}

/// A `match` used as a bare statement that is *not* the last statement of
/// its enclosing block must still parse -- `Parser::parse_match`'s own arm
/// list ends in a `Dedent` that re-syncs with the enclosing block, so the
/// statement dispatcher must not also expect a trailing `Newline`/`Dedent`
/// of its own afterward (see `Parser::parse_match_stmt`).
#[test]
fn parses_match_stmt_followed_by_another_statement() {
    let src = "fn t(x: i32):\n    match x:\n        _ -> 1\n    println(\"after\")\n";
    let module = Driver::parse(src).expect("a match statement followed by another statement at the same indentation should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert_eq!(f.body.stmts.len(), 2, "expected the match statement plus the trailing println: {:?}", f.body.stmts);
    assert!(matches!(f.body.stmts[0], Stmt::Expr(Expr::Match { .. })));
    assert!(matches!(f.body.stmts[1], Stmt::Expr(Expr::Call { .. })));
}

/// A method call (`obj.method(args)`) type-checks even though `method`
/// isn't also a field on `obj`'s struct -- before this fix, `Expr::Call`
/// always ran its callee through the generic `Expr::Field` inference
/// (`resolve_field_type`), which only ever looks a name up in the struct's
/// *field* list and rejected any real method call with "no field `method`
/// on `Type`".
#[test]
fn checks_method_call_not_shadowed_by_field_type_checks() {
    let src = "struct Counter:\n    count: i32\n\nimpl Counter:\n    fn bump(self, by: i32) -> i32:\n        self.count + by\n\nfn t(c: Counter) -> i32:\n    c.bump(3)\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "a method call not shadowed by a same-named field should type-check");
}

/// Regression guard: a call naming neither a real field nor a declared
/// method must still be a type error (the method-call fix must not swallow
/// genuinely-undefined-name errors).
#[test]
fn rejects_call_to_undefined_method_or_field() {
    let src = "struct Counter:\n    count: i32\n\nfn t(c: Counter) -> i32:\n    c.nonexistent(3)\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "calling an undefined name on a struct should be a type error");
}

/// Runtime test: `examples/option_result.exe`'s `unwrap_or` uses `match` as
/// a value-producing expression (each arm's trailing expression, no
/// explicit `return`), and `describe_sign` uses `match` as a bare statement
/// immediately followed by another statement at the same indentation.
#[test]
fn runtime_match_value_and_statement_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/option_result.exe").output().expect("failed to execute option_result.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("unwrap_or(Some(7), -1) = 7"), "match used as a value, Some arm: {}", stdout);
    assert!(stdout.contains("unwrap_or(None, -1) = -1"), "match used as a value, None arm: {}", stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    let non_positive_at = lines.iter().position(|l| *l == "non-positive").expect("non-positive line");
    assert_eq!(lines[non_positive_at + 1], "done describing", "match statement followed by another statement, non-positive branch: {}", stdout);
    let positive_at = lines.iter().position(|l| *l == "positive").expect("positive line");
    assert_eq!(lines[positive_at + 1], "done describing", "match statement followed by another statement, positive branch: {}", stdout);
}

/// A `match` compare-pattern's rhs can be a negative integer literal
/// (`<= -5`), which parses as `Expr::Unary { op: Neg, operand: Expr::Int }`
/// rather than `Expr::Int` directly (the lexer has no dedicated
/// negative-literal token) -- `Codegen::emit_expr`'s `Pattern::Compare` arm
/// previously only recognized a bare `Expr::Int` rhs and fell into its
/// "unsupported match rhs expression" error for anything else, so this
/// perfectly ordinary, type-checked syntax failed at the codegen step with a
/// confusing internal error instead of compiling.
#[test]
fn runtime_match_compare_pattern_against_negative_literal_end_to_end() {
    let src = "fn classify(x: i32) -> str:\n    match x:\n        <= -5 ->\n            return \"very low\"\n        < 0 ->\n            return \"low\"\n        _ ->\n            return \"other\"\n\nfn main():\n    println(classify(-10))\n    println(classify(-1))\n    println(classify(5))\n";
    let output = compile_and_run("match_compare_negative_literal", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["very low", "low", "other"], "{}", stdout);
}

/// A `Pattern::Binding` match arm (`v -> ...`) binds the *whole* scrutinee
/// value to a fresh name, and per `check_match_exhaustive`'s own doc comment
/// is treated as an unconditional catch-all -- but nothing ever actually
/// inserted that name into the arm's scope, so any use of it failed
/// type-checking with "undefined name" on every single use, making this
/// entire documented pattern kind unusable. Exercises an `i32` scrutinee.
#[test]
fn runtime_match_binding_pattern_int_scrutinee_end_to_end() {
    let src = "fn classify(x: i32) -> i32:\n    match x:\n        v -> v + 1\n\nfn main():\n    println(f\"{classify(5)}\")\n    println(f\"{classify(-3)}\")\n";
    let output = compile_and_run("match_binding_pattern_int", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["6", "-2"], "{}", stdout);
}

/// Same `Pattern::Binding` fix, `str` scrutinee: exercises the codegen path
/// where the scrutinee has no ready-made storage pointer of its own (unlike
/// a struct/payload-enum scrutinee) and the binding must spill the loaded
/// value into a fresh alloca before it can be registered as a local.
#[test]
fn runtime_match_binding_pattern_str_scrutinee_end_to_end() {
    let src = "fn describe(s: str) -> str:\n    match s:\n        v -> v\n\nfn main():\n    println(describe(\"hello\"))\n";
    let output = compile_and_run("match_binding_pattern_str", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "hello", "{}", stdout);
}

/// `Pattern::Int`/`Pattern::Bool` (`43 -> ...`, `true -> ...`) type-checked
/// fine but had no codegen arm at all -- `Codegen::emit_expr`'s `TypedExpr::Match`
/// fell through to the catch-all "unsupported match pattern in codegen"
/// error for perfectly ordinary, exhaustively-covered literal match arms
/// (found while writing a Brainfuck interpreter in Star, examples/brainfuck.star,
/// whose opcode dispatch is exactly this shape: `match op: 43 -> ... 45 -> ...`).
/// Fixed by giving both patterns the same then/next branch-and-chain codegen
/// `Pattern::Compare`'s `Eq` case already used, and generalizing the match
/// scrutinee's own value-loading to use `Codegen::untag` (type-aware) instead
/// of an unconditional `strip_prefix("i32 ")` that silently left a `bool`
/// scrutinee's `i1` tag attached.
#[test]
fn runtime_match_int_literal_pattern_end_to_end() {
    let src = "fn name_of(op: i32) -> str:\n    match op:\n        43 -> \"plus\"\n        45 -> \"minus\"\n        _ -> \"other\"\n\nfn main():\n    println(name_of(43))\n    println(name_of(45))\n    println(name_of(1))\n";
    let output = compile_and_run("match_int_literal_pattern", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["plus", "minus", "other"], "{}", stdout);
}

/// Same bug, `bool` scrutinee -- also exercises the `bool` scrutinee value
/// actually being untagged correctly (`i1`, not the `i32` the old ad-hoc
/// strip assumed) now that both literal patterns and non-literal scrutinees
/// share `Codegen::untag`.
#[test]
fn runtime_match_bool_literal_pattern_end_to_end() {
    let src = "fn describe(b: bool) -> str:\n    match b:\n        true -> \"yes\"\n        false -> \"no\"\n\nfn main():\n    println(describe(true))\n    println(describe(false))\n";
    let output = compile_and_run("match_bool_literal_pattern", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["yes", "no"], "{}", stdout);
}

// ===== `if`/`match`-as-value phi-predecessor tracking =======================
//
// `TypedExpr::If`'s and `TypedExpr::Match`'s codegen merge each branch/arm's
// trailing value with a `phi` instruction at the join block, and previously
// hardcoded the *entry* label of that branch/arm (`if_then_N`/`match_then_N`)
// as the `phi`'s incoming-block operand. That's only correct if the branch's
// trailing value is computed with zero further control flow of its own --
// true for a literal or a plain scalar binop, but false for almost anything
// else: a short-circuit `&&`/`||`, a `list[i]`/`gen_ref[i]` bounds check, a
// `frame:` allocation, a nested `if`/`match`, all open their *own* basic
// blocks partway through evaluating the branch, so the block actually
// falling through to the join point is whichever of those was opened last,
// not the branch's original entry block. Using the stale label produced
// invalid LLVM IR ("PHI node entries do not match predecessors" / "Instruction
// does not dominate all uses"), rejected by `clang` at the very last pipeline
// stage, for any such branch value -- discovered while fixing a narrower,
// related gap (`Checker::trailing_value_ty` not recognizing a trailing
// `frame:` block, see the `frame_escape`/`trailing_value` tests below) that
// happened to unblock type-checking for the first repro case that exposed
// this. Fixed by threading `Codegen::current_label` (updated by the new
// `open_block` helper, the sole place any block is opened) through both
// `phi` sites instead of the stale entry labels.

/// The most common trigger: a short-circuit `&&`/`||` as the trailing value
/// of one arm of an `if` used as a value (via `return if ...`).
#[test]
fn runtime_if_value_branch_with_logical_and_end_to_end() {
    let src = "fn compute(cond: bool, a: bool, b: bool) -> bool:\n    return if cond:\n        a && b\n    else:\n        false\n\nfn main():\n    println(f\"{compute(true, true, true)}\")\n    println(f\"{compute(true, true, false)}\")\n    println(f\"{compute(false, true, true)}\")\n";
    let output = compile_and_run("if_value_logical_and", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "false", "false"], "{}", stdout);
}

/// Same bug, `list[idx]`'s own internal bounds-check block as the trigger.
#[test]
fn runtime_if_value_branch_with_list_index_end_to_end() {
    let src = "fn compute(cond: bool, nums: List<i32>) -> i32:\n    return if cond:\n        nums[0]\n    else:\n        -1\n\nfn main():\n    let mut nums = List<i32>()\n    nums.push(42)\n    println(f\"{compute(true, nums)}\")\n    println(f\"{compute(false, nums)}\")\n";
    let output = compile_and_run("if_value_list_index", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["42", "-1"], "{}", stdout);
}

/// Same bug, a trailing `frame:` block as the trigger -- exercises both the
/// codegen phi fix *and* the `Checker::trailing_value_ty`/`Expr::If` type
/// inference fix that made this construct type-check as `i32` (rather than
/// `void`) in the first place.
#[test]
fn runtime_if_value_branch_with_trailing_frame_end_to_end() {
    let src = "fn compute(cond: bool) -> i32:\n    return if cond:\n        frame:\n            let x = 5\n            x * 2\n    else:\n        0\n\nfn main():\n    println(f\"{compute(true)}\")\n    println(f\"{compute(false)}\")\n";
    let output = compile_and_run("if_value_trailing_frame", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["10", "0"], "{}", stdout);
}

/// Same bug, `match`-as-value side: a `Compare`-pattern arm's trailing value
/// opens its own blocks (`&&`), exercising the `Pattern::Compare`/
/// `Pattern::EnumVariant` arms' phi-predecessor fix.
#[test]
fn runtime_match_value_compare_arm_with_logical_and_end_to_end() {
    let src = "fn classify(x: i32, flag: bool) -> bool:\n    match x:\n        <= 0 -> flag && false\n        _ -> flag && true\n\nfn main():\n    println(f\"{classify(-1, true)}\")\n    println(f\"{classify(1, true)}\")\n";
    let output = compile_and_run("match_value_compare_logical_and", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "true"], "{}", stdout);
}

/// Same bug, `match`-as-value side: an `EnumVariant`-pattern arm's trailing
/// value opens its own blocks (`&&`), exercising the payload-enum path of
/// the same phi-predecessor fix.
#[test]
fn runtime_match_value_enum_variant_arm_with_logical_and_end_to_end() {
    let src = "enum IntOption:\n    None\n    Some(value: i32)\n\nfn describe(o: IntOption, flag: bool) -> bool:\n    match o:\n        IntOption::Some(v) -> flag && (v > 0)\n        IntOption::None -> false\n\nfn main():\n    println(f\"{describe(IntOption::Some(5), true)}\")\n    println(f\"{describe(IntOption::Some(-5), true)}\")\n    println(f\"{describe(IntOption::None, true)}\")\n";
    let output = compile_and_run("match_value_enum_variant_logical_and", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "false", "false"], "{}", stdout);
}

// ===== fieldless enum interpolated into an f-string (`NOTES.md` 1.5) ======

/// A fieldless enum interpolated directly into a `println(f"...")` argument
/// (the `emit_print_like` fast path) must print the variant's *name*, not a
/// garbage-looking hex "address". Previously neither `emit_print_like`'s
/// format-specifier table nor its arg-value/release logic had a `Ty::Enum`
/// arm, so the bare `i32` discriminant fell through to the `%p`
/// pointer catch-all -- no crash, no compile error, just a plausible-
/// looking but wrong `0000000000000001`-style value (confirmed live in
/// `projects/snake`, `NOTES.md` section 1.5).
#[test]
fn runtime_println_fieldless_enum_prints_variant_name_end_to_end() {
    let src = "enum Direction:\n    Up\n    Down\n    Left\n    Right\n\nfn main():\n    let d = Direction::Down\n    println(f\"dir: {d}\")\n    println(f\"dir: {Direction::Right}\")\n";
    let output = compile_and_run("println_fieldless_enum_prints_variant_name", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["dir: Down", "dir: Right"], "{}", stdout);
}

/// Same bug, the *general* f-string-as-value path (`codegen/expr.rs`'s
/// `TypedExpr::FStr` arm): an f-string interpolating a fieldless enum,
/// assigned to a `let` and printed separately rather than passed straight
/// to `println`, exercises the second of the two call sites `NOTES.md`
/// section 1.5 calls out as both missing a `Ty::Enum` arm.
#[test]
fn runtime_fstring_value_with_fieldless_enum_prints_variant_name_end_to_end() {
    let src = "enum Direction:\n    Up\n    Down\n    Left\n    Right\n\nfn describe(d: Direction) -> str:\n    f\"you're heading {d}\"\n\nfn main():\n    let s = describe(Direction::Left)\n    println(s)\n";
    let output = compile_and_run("fstring_value_with_fieldless_enum_prints_variant_name", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "you're heading Left");
}

// ===== bare trailing `if`/`else` as a value (`NOTES.md` 1.4) ==============

/// The compact single-line `if cond: a else: b` form only worked on a
/// `let`'s RHS before (routed through `parse_if_expr`); at *statement*
/// position it always went through `parse_if_stmt`, which only ever
/// accepted a full indented block per arm -- `if cond: a else: b` as a bare
/// statement failed to parse outright ("expected end of line, found
/// identifier `a`"). `parse_if_stmt` now reuses the same arm grammar
/// (`parse_if_expr_arm`) as the expression form.
#[test]
fn parses_compact_inline_if_else_at_statement_position() {
    let src = "fn t(cond: bool):\n    if cond: println(\"a\") else: println(\"b\")\n    println(\"done\")\n";
    Driver::parse(src).expect("a compact single-line if/else at statement position should parse");
}

/// A function body ending in a bare trailing `if`/`else` -- no `let`, no
/// explicit `return` -- is now a valid implicit return, exactly like the
/// equivalent `match` already was (`match`, unlike `if`, always parses to
/// `TypedStmt::Expr(TypedExpr::Match{..})`, never a dedicated statement
/// variant, so it never needed this fix). Compact single-line arm form.
#[test]
fn runtime_bare_trailing_compact_if_else_as_implicit_return_end_to_end() {
    let src = "fn classify(x: i32) -> str:\n    if x > 0: \"pos\" else: \"neg\"\n\nfn main():\n    println(classify(5))\n    println(classify(-5))\n";
    let output = compile_and_run("bare_trailing_compact_if_else_implicit_return", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["pos", "neg"], "{}", stdout);
}

/// Same fix, full-indented-block arm form -- the shape `NOTES.md` 1.4's
/// second confirmation used (a `frame:` block's own trailing statement
/// being a bare `if`/`else`, previously rejected by
/// `Checker::trailing_value_ty` even though `match` already worked there).
#[test]
fn runtime_frame_block_ending_in_bare_if_else_as_trailing_value_end_to_end() {
    let src = "fn classify(x: i32) -> i32:\n    frame:\n        let y = x + 1\n        if y > 0:\n            y * 2\n        else:\n            0 - y\n\nfn main():\n    println(f\"{classify(4)}\")\n    println(f\"{classify(-10)}\")\n";
    let output = compile_and_run("frame_block_ending_in_bare_if_else_trailing_value", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["10", "9"], "{}", stdout);
}

/// Nested case: a function's implicit return is a trailing `if`/`else`
/// whose own `then` arm is *itself* a nested trailing `if`/`else` -- guards
/// that `Checker::trailing_value_ty`/`Codegen::emit_stmts_value`'s new
/// `TypedStmt::If` arms recurse correctly rather than only handling one
/// level.
#[test]
fn runtime_nested_trailing_if_else_as_implicit_return_end_to_end() {
    let src = "fn classify(x: i32) -> str:\n    if x > 100:\n        \"big\"\n    else:\n        if x > 0:\n            \"small\"\n        else:\n            \"non-positive\"\n\nfn main():\n    println(classify(500))\n    println(classify(5))\n    println(classify(-5))\n";
    let output = compile_and_run("nested_trailing_if_else_implicit_return", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["big", "small", "non-positive"], "{}", stdout);
}

/// A trailing `if`/`else` whose arms produce *mismatched* types must still
/// be rejected (not silently accepted as `Ty::Named("unknown")` via
/// `types_compatible`'s placeholder wildcard) -- guards that the new
/// `TypedStmt::If` arm in `trailing_value_ty` didn't loosen this into
/// accepting genuinely unsound code.
#[test]
fn rejects_trailing_if_else_implicit_return_with_mismatched_arm_types() {
    let src = "fn t(cond: bool) -> i32:\n    if cond:\n        1\n    else:\n        \"nope\"\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("mismatched trailing if/else arms should not type-check as an implicit return");
    assert!(errs.iter().any(|d| d.message.contains("does not end in a value-producing expression")), "{:?}", errs);
}

/// A trailing `if`/`else` whose arms are both void calls (`println(..)`,
/// typed `unknown`) must be rejected as an implicit return too, not
/// silently accepted as "both sides produce a matching value" -- the
/// `unknown` placeholder that makes `types_compatible` treat two void arms
/// as "compatible" must not let this shape through
/// `Checker::trailing_value_ty`'s new `TypedStmt::If` arm.
#[test]
fn rejects_trailing_if_else_implicit_return_with_both_arms_void() {
    let src = "fn t(cond: bool) -> i32:\n    if cond:\n        println(\"a\")\n    else:\n        println(\"b\")\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("a trailing if/else with void arms should not type-check as an implicit return");
    assert!(errs.iter().any(|d| d.message.contains("does not end in a value-producing expression")), "{:?}", errs);
}

/// An ordinary imperative `if`/`else` whose arms are both void calls,
/// used purely for side effects (not as any function's implicit return --
/// `main` here has no declared return type) must keep compiling and running
/// exactly as before: `Codegen::emit_stmts_value`'s new `TypedStmt::If` arm
/// must not misfire on this shape just because it's structurally similar to
/// the value-producing case (this is `runtime_mixed_scalar_comparison_
/// still_works_end_to_end`'s exact original failure mode while developing
/// the 1.4 fix -- `println`'s codegen-level `"%undef"` placeholder has no
/// space to split a type off of, so treating it as a real value crashed
/// `clang` on a missing `if_else`/`if_end` block).
#[test]
fn runtime_trailing_if_else_with_void_arms_used_as_plain_statement_end_to_end() {
    let src = "fn main():\n    let a = 1\n    let b = 2\n    if a < b:\n        println(\"less\")\n    else:\n        println(\"not less\")\n";
    let output = compile_and_run("trailing_if_else_void_arms_plain_statement", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "less");
}

/// `Checker::check_frame_escapes`'s lookahead (`frame_escape_source_block`)
/// previously only recognized a bare trailing expression as a branch's
/// value, so a `frame:` block nested inside an `if`-expression's branch and
/// returned from the enclosing function silently skipped this whole safety
/// check -- a struct allocated inside that `frame:` block could be returned
/// with no diagnostic at all. Fixed alongside the type-inference gap above.
#[test]
fn rejects_frame_local_struct_escaping_through_if_value_branch() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\nfn make(cond: bool) -> Point:\n    return if cond:\n        frame:\n            let p = Point(1, 2)\n            p\n    else:\n        Point(0, 0)\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("returning a frame-local struct through an if-value branch should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("p") && d.message.contains("does not outlive")), "{:?}", errs);
}

// ===== bare identifier as a trailing if/else arm's value (found dogfooding
// ===== `projects/snake`'s `pick_color` helper while applying the 1.4 fix) ==

/// `emit_stmts_value`'s `TypedStmt::If` arm (the 1.4 fix) merges both arms'
/// values with a `phi`, reading the merged type off of whichever arm's own
/// tagged value comes back (`then_val.split_once(' ')` in
/// `emit_trailing_if_value`). Every `emit_expr` arm is supposed to tag its
/// result with its LLVM type (`"i32 %r"`, per `reg_of`'s own doc comment on
/// the convention) -- except `TypedExpr::Ident` used to return a bare
/// register with no type prefix at all, since every *other* consumer of an
/// `Ident`'s value only ever strips the type back off via `reg_of` and
/// never noticed the tag was already missing. A trailing `if cond: a else:
/// b` returning a struct-typed parameter directly -- exactly
/// `projects/snake/main.star`'s `pick_color(cond, a, b) -> Color32:\n    if
/// cond: a else: b` -- hit this: `split_once(' ')` on a bare `%t5` found no
/// space, `?`-propagated `None` out of `emit_trailing_if_value`, and the
/// enclosing function failed to compile with "function must end in a
/// value-producing expression or explicit return" even though `star check`
/// had already accepted it. A struct-*literal* arm (`Color32(1)`) never hit
/// this, since `TypedExpr::StructInit` already tagged its result -- only a
/// bare `Ident` arm did, which made it easy to miss.
#[test]
fn runtime_trailing_if_else_with_bare_struct_ident_arms_end_to_end() {
    let src = "struct Color32:\n    r: i32\n    g: i32\n\nfn pick(cond: bool, a: Color32, b: Color32) -> Color32:\n    if cond: a else: b\n\nfn main():\n    let x = pick(true, Color32(1, 2), Color32(3, 4))\n    let y = pick(false, Color32(1, 2), Color32(3, 4))\n    println(f\"{x.r} {x.g} {y.r} {y.g}\")\n";
    let output = compile_and_run("trailing_if_else_bare_struct_ident_arms", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "1 2 3 4");
}

/// Same bug, scalar-typed identifiers (`i32`) rather than a struct -- proves
/// the missing type tag was a property of `TypedExpr::Ident` itself, not
/// specific to aggregate types.
#[test]
fn runtime_trailing_if_else_with_bare_scalar_ident_arms_end_to_end() {
    let src = "fn pick(cond: bool, a: i32, b: i32) -> i32:\n    if cond: a else: b\n\nfn main():\n    println(f\"{pick(true, 11, 22)}\")\n    println(f\"{pick(false, 11, 22)}\")\n";
    let output = compile_and_run("trailing_if_else_bare_scalar_ident_arms", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["11", "22"]);
}

/// Mixed shape: one arm a bare identifier, the other a literal/expression --
/// guards that the fix isn't narrowly special-cased to "both arms are bare
/// idents" but actually fixes `TypedExpr::Ident`'s codegen in general.
#[test]
fn runtime_trailing_if_else_with_one_bare_ident_arm_end_to_end() {
    let src = "fn pick(cond: bool, a: i32) -> i32:\n    if cond: a else: a + 100\n\nfn main():\n    println(f\"{pick(true, 7)}\")\n    println(f\"{pick(false, 7)}\")\n";
    let output = compile_and_run("trailing_if_else_one_bare_ident_arm", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["7", "107"]);
}

/// A plain (non-trailing-if) use of an identifier's `emit_expr` value must
/// still work exactly as before -- guards that tagging the result with its
/// LLVM type didn't break any of the many call sites that already strip it
/// back off via `reg_of` (e.g. binary operators, call arguments, struct
/// field initializers, all reached through an ordinary local variable).
#[test]
fn runtime_ident_value_used_in_binop_and_call_arg_still_works_end_to_end() {
    let src = "fn add_one(n: i32) -> i32:\n    n + 1\n\nfn main():\n    let a = 5\n    let b = a + a\n    println(f\"{b}\")\n    println(f\"{add_one(a)}\")\n";
    let output = compile_and_run("ident_value_used_in_binop_and_call_arg_still_works", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["10", "6"]);
}

/// Runtime test: `examples/player.exe`'s `take_damage` method (called as a
/// bare statement) and `remaining_health` method (called as a value inside
/// an f-string interpolation) both type-check and run correctly.
#[test]
fn runtime_method_calls_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/player.exe").output().expect("failed to execute player.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("remaining: 100"), "method call used as a value: {}", stdout);
    assert!(stdout.contains("Hero has perished."), "method call used as a bare statement: {}", stdout);
}

// ===== `let x = if cond: <multi-stmt> else: <multi-stmt>` as a `let`
// ===== initializer (todo.md P3 #11) ========================================
//
// The trailing-`if`/`else`-as-a-value `phi` fix above (`Codegen::
// emit_trailing_if_value`'s `rsplit_once` fix, exercised by the bare-
// trailing-if/else tests just above) only ever runs for `TypedStmt::If` --
// an `if` in trailing *statement* position (a function's implicit return, or
// a `frame:` block's own trailing statement). `let x = if cond: .. else:
// ..`, by contrast, parses `if` as a full expression (`Expr::If` via
// `Parser::parse_if_expr`) and type-checks/codegens through the entirely
// separate `TypedExpr::If` arm (`Codegen::emit_expr`, `src/codegen/expr.rs`)
// -- which reads its merged `phi` type directly off the checker-computed
// `ty` field rather than splitting a tagged value string, so it was never
// susceptible to the `rsplit_once`/`split_once` bug in the first place.
// `projects/nova/NOTES.md` section 10 flagged this shape as suspect anyway
// ("a bare multi-statement if/else doesn't work as a let initializer") but
// never pinned down *why*, and P3 #11 asks to confirm rather than assume.
//
// Confirming it turned up a real, different bug in that same `TypedExpr::If`
// arm: unlike every other `if` codegen path in this compiler (`TypedStmt::
// If`'s own statement-form handling, `Codegen::emit_trailing_if_value`, the
// `while`/`match`/arena/closure/system bodies all listed at the top of
// `Codegen::push_scope`'s call sites), it never wrapped either arm in its
// own `push_scope`/`pop_scope` pair. Any RC-owning local declared inside an
// arm (a `str`, `List<T>`, etc. -- not necessarily the arm's own trailing
// value) was `track_owned`'d into whatever scope was already open *outside*
// the whole `if`, so that enclosing scope's eventual `pop_scope` released
// *both* arms' locals unconditionally -- including the arm that never ran,
// whose `alloca` was never stored to and so held uninitialized stack
// garbage. Calling `star_rc_release` on that garbage (dereferencing it as an
// RC header) segfaulted; confirmed with a real `star build`+run before this
// fix landed (`Codegen::emit_expr`'s `TypedExpr::If` arm now pushes/pops a
// scope around each arm exactly like the other paths already did).

/// The exact shape `projects/nova/flags.star` used successfully (a single
/// expression per arm) still works, now with each arm expanded to multiple
/// statements -- the base case P3 #11 asks to confirm, no RC types involved
/// so it never touched the scope bug above; guards the plain scalar path
/// stays correct alongside the fix below.
#[test]
fn runtime_let_initializer_if_else_multi_statement_arms_scalar_end_to_end() {
    let src = "fn classify(cond: bool) -> i32:\n    let x = if cond:\n        let a = 1\n        let b = 2\n        a + b\n    else:\n        let a = 10\n        let b = 20\n        a + b\n    x\n\nfn main():\n    println(f\"{classify(true)}\")\n    println(f\"{classify(false)}\")\n";
    let output = compile_and_run("let_if_multi_stmt_scalar", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["3", "30"], "{}", stdout);
}

/// Same shape with an aggregate (tuple) arm type -- guards that
/// `TypedExpr::If`'s `ty_str = self.llvm_ty(ty)` (reading the merged `phi`
/// type off the checker's own field) handles a type whose LLVM spelling
/// contains internal spaces (`{ i32, i1 }`) correctly for a multi-statement
/// `let`-initializer arm, the same aggregate-`phi` shape the
/// `rsplit_once` fix targeted for the statement-form sibling.
#[test]
fn runtime_let_initializer_if_else_multi_statement_arms_tuple_type_end_to_end() {
    let src = "fn pick(cond: bool) -> (i32, bool):\n    let x = if cond:\n        let a: i32 = 1\n        let b: bool = true\n        (a, b)\n    else:\n        let a: i32 = 10\n        let b: bool = false\n        (a, b)\n    x\n\nfn main():\n    let p = pick(true)\n    let q = pick(false)\n    println(f\"{p.0} {p.1} {q.0} {q.1}\")\n";
    let output = compile_and_run("let_if_multi_stmt_tuple", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "1 true 10 false");
}

/// Regression for the segfault described above: an RC-owning local (`str`)
/// declared inside each arm but *not* the arm's own trailing value. Before
/// the `push_scope`/`pop_scope` fix, this crashed with SIGSEGV on both
/// `cond` values (the untaken arm's own `alloca` was always uninitialized
/// garbage, regardless of which branch ran) -- confirmed via a real
/// `star build`+run repro before writing this test.
#[test]
fn runtime_let_initializer_if_else_multi_statement_arms_with_unused_rc_local_end_to_end() {
    let src = "fn pick(cond: bool) -> str:\n    let x = if cond:\n        let unused: str = \"alpha\"\n        \"then-value\"\n    else:\n        let unused: str = \"beta\"\n        \"else-value\"\n    x\n\nfn main():\n    println(pick(true))\n    println(pick(false))\n";
    let output = compile_and_run("let_if_multi_stmt_unused_rc_local", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["then-value", "else-value"], "{}", stdout);
}

/// Same bug, but the trailing value *is* one of the arm's own RC-owning
/// locals (read out, not a fresh literal) -- exercises the "read retains,
/// scope-exit releases" balance: `a`'s own arm-scope `pop_scope` must not
/// release the last reference out from under the value this `if`-expression
/// is about to hand back to its `let` binding.
#[test]
fn runtime_let_initializer_if_else_multi_statement_arms_trailing_rc_local_end_to_end() {
    let src = "fn pick(cond: bool) -> str:\n    let x = if cond:\n        let a: str = \"alpha\"\n        let b: str = \"beta\"\n        a\n    else:\n        let a: str = \"gamma\"\n        let b: str = \"delta\"\n        a\n    x\n\nfn main():\n    println(pick(true))\n    println(pick(false))\n";
    let output = compile_and_run("let_if_multi_stmt_trailing_rc_local", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["alpha", "gamma"], "{}", stdout);
}

/// Same bug, a collection type (`List<i32>`) rather than `str` -- exercises
/// the generated list-release thunk (`crate::codegen::list`) rather than the
/// plain `str` release path, guarding the scope fix isn't narrowly
/// specialized to one RC-owning type.
#[test]
fn runtime_let_initializer_if_else_multi_statement_arms_with_list_local_end_to_end() {
    let src = "fn pick(cond: bool) -> i32:\n    let x = if cond:\n        let mut lst: List<i32> = List<i32>()\n        lst.push(1)\n        lst.push(2)\n        42\n    else:\n        let mut lst: List<i32> = List<i32>()\n        lst.push(3)\n        -1\n    x\n\nfn main():\n    println(f\"{pick(true)}\")\n    println(f\"{pick(false)}\")\n";
    let output = compile_and_run("let_if_multi_stmt_list_local", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["42", "-1"], "{}", stdout);
}

/// An `elif` chain (which desugars to a nested `Expr::If` held in the outer
/// arm's `else_block`, per `Parser::parse_if_else_tail_expr`) as a `let`
/// initializer, each arm multi-statement with its own RC-owning local --
/// guards that the scope fix applies at every nesting level the desugaring
/// produces, not just a single top-level `if`/`else`.
#[test]
fn runtime_let_initializer_elif_chain_multi_statement_arms_with_rc_locals_end_to_end() {
    let src = "fn classify(x: i32) -> str:\n    let label = if x > 100:\n        let tag: str = \"big-tag\"\n        \"big\"\n    elif x > 0:\n        let tag: str = \"small-tag\"\n        \"small\"\n    else:\n        let tag: str = \"non-positive-tag\"\n        \"non-positive\"\n    label\n\nfn main():\n    println(classify(500))\n    println(classify(5))\n    println(classify(-5))\n";
    let output = compile_and_run("let_if_elif_multi_stmt_rc_locals", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["big", "small", "non-positive"], "{}", stdout);
}

/// Sustained-iteration leak check (same `assert_no_leak` Working-Set-delta
/// technique as the round-2/round-3 bug-hunt files): a `let`-initializer
/// `if`/`else` with a multi-statement, RC-owning-local-bearing arm on *both*
/// sides, alternating which branch runs every iteration, must not leak --
/// i.e. the per-arm `push_scope`/`pop_scope` fix releases the untaken arm's
/// (never-allocated-this-iteration) locals correctly and the taken arm's
/// locals exactly once, not zero or two times, across many iterations of
/// each branch.
#[test]
fn runtime_let_initializer_if_else_multi_statement_arms_rc_locals_sustained_no_leak_end_to_end() {
    let src = "fn main():\n    let mut i: i32 = 0\n    while i < 400000:\n        let cond = i % 2 == 0\n        let x = if cond:\n            let a: str = concat(\"hello\", \"-a\")\n            let b: str = concat(\"world\", \"-b\")\n            a\n        else:\n            let a: str = concat(\"foo\", \"-a\")\n            let b: str = concat(\"bar\", \"-b\")\n            b\n        i += 1\n    println(\"done\")\n";
    assert_no_leak("let_if_multi_stmt_rc_locals_sustained_leak", src, 20 * 1024 * 1024);
}
