//! `if let`/`while let` pattern binding (`docs/requests.md` #3) --
//! `Parser::parse_if_let_stmt`/`Parser::parse_while_let_stmt` desugar
//! straight into the existing `match`/`while` AST nodes (reusing
//! `Parser::parse_pattern` and `Checker::check_match_exhaustive`), so there's
//! no new `Stmt`/`TypedStmt` variant to test in isolation -- these tests
//! exercise the desugared shape end to end instead. Shared helpers live in
//! `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

const INT_OPTION_ENUM_SRC: &str = "enum IntOption:\n    None\n    Some(value: i32)\n\n";
const INT_RESULT_ENUM_SRC: &str = "enum IntResult:\n    Ok(value: i32)\n    Err(code: i32)\n\n";

// ===== `if let` parsing/desugaring ===========================================

/// `if let` desugars to a `Stmt::Expr(Expr::Match)` with exactly two arms:
/// the user's pattern, then a synthesized wildcard.
#[test]
fn if_let_desugars_to_two_arm_match() {
    let src = format!(
        "{}fn t(o: IntOption):\n    if let IntOption::Some(v) = o:\n        println(f\"{{v}}\")\n",
        INT_OPTION_ENUM_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    let Item::Fn(f) = module.items.last().unwrap() else { panic!("expected fn") };
    let Stmt::Expr(Expr::Match { arms, .. }) = &f.body.stmts[0] else { panic!("expected a desugared match") };
    assert_eq!(arms.len(), 2);
    assert!(matches!(&arms[0].pattern, Pattern::EnumVariant(enum_name, variant, bindings) if enum_name == "IntOption" && variant == "Some" && bindings == &["v".to_string()]));
    assert!(matches!(&arms[1].pattern, Pattern::Wildcard));
}

/// With no `else`, the wildcard arm's body is empty (not absent -- there's
/// always exactly two arms).
#[test]
fn if_let_without_else_has_empty_wildcard_body() {
    let src = format!(
        "{}fn t(o: IntOption):\n    if let IntOption::Some(v) = o:\n        println(f\"{{v}}\")\n",
        INT_OPTION_ENUM_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    let Item::Fn(f) = module.items.last().unwrap() else { panic!("expected fn") };
    let Stmt::Expr(Expr::Match { arms, .. }) = &f.body.stmts[0] else { panic!("expected a desugared match") };
    assert!(arms[1].body.stmts.is_empty());
}

/// `if let ... else: ...` puts the `else` block's statements into the
/// synthesized wildcard arm.
#[test]
fn if_let_with_else_populates_wildcard_body() {
    let src = format!(
        "{}fn t(o: IntOption):\n    if let IntOption::Some(v) = o:\n        println(f\"{{v}}\")\n    else:\n        println(\"none\")\n",
        INT_OPTION_ENUM_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    let Item::Fn(f) = module.items.last().unwrap() else { panic!("expected fn") };
    let Stmt::Expr(Expr::Match { arms, .. }) = &f.body.stmts[0] else { panic!("expected a desugared match") };
    assert_eq!(arms[1].body.stmts.len(), 1);
}

/// The compact inline-arm form (`if let ...: expr` on one line) is accepted,
/// mirroring plain `if`'s own compact form (`Parser::parse_if_expr_arm`).
#[test]
fn if_let_supports_compact_inline_arm() {
    let src = format!("{}fn t(o: IntOption) -> i32:\n    if let IntOption::Some(v) = o: v else: 0\n", INT_OPTION_ENUM_SRC);
    Driver::parse(&src).expect("compact inline `if let` arm should parse");
}

// ===== `while let` parsing/desugaring ========================================

/// `while let` desugars to `while true: match <expr>: <pattern> -> <body>
/// _ -> break`.
#[test]
fn while_let_desugars_to_while_true_with_match() {
    let src = format!(
        "{}fn t(o: IntOption):\n    while let IntOption::Some(v) = o:\n        break\n",
        INT_OPTION_ENUM_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    let Item::Fn(f) = module.items.last().unwrap() else { panic!("expected fn") };
    let Stmt::While { cond, body, else_block, .. } = &f.body.stmts[0] else { panic!("expected While") };
    assert!(matches!(cond, Expr::Bool(true, _)));
    assert!(else_block.is_none());
    assert_eq!(body.stmts.len(), 1);
    let Stmt::Expr(Expr::Match { arms, .. }) = &body.stmts[0] else { panic!("expected a desugared match") };
    assert_eq!(arms.len(), 2);
    assert!(matches!(&arms[1].pattern, Pattern::Wildcard));
    assert!(matches!(arms[1].body.stmts.as_slice(), [Stmt::Break { .. }]));
}

// ===== Type-checking ==========================================================

/// `if let`'s scrutinee must actually be the pattern's enum type -- the
/// desugared `match`'s ordinary type errors surface here too.
#[test]
fn rejects_if_let_pattern_enum_mismatch() {
    let src = format!(
        "{}enum OtherEnum:\n    A\n\nfn t(e: OtherEnum):\n    if let IntOption::Some(v) = e:\n        println(f\"{{v}}\")\n",
        INT_OPTION_ENUM_SRC
    );
    assert!(Driver::check(&Driver::parse(&src).expect("should parse")).is_err());
}

/// `break`/`continue` inside a `while let` body refer to the loop itself,
/// same as an ordinary `while`.
#[test]
fn while_let_body_break_and_continue_type_check() {
    let src = format!(
        "{}fn t(o: IntOption):\n    while let IntOption::Some(v) = o:\n        if v == 0:\n            break\n        continue\n",
        INT_OPTION_ENUM_SRC
    );
    Driver::check(&Driver::parse(&src).expect("should parse")).expect("should type-check");
}

/// `break`/`continue` outside any loop is still rejected even when the only
/// syntactic loop-shaped thing around is an `if let` (which is not a loop).
#[test]
fn rejects_break_inside_if_let_with_no_enclosing_loop() {
    let src = format!(
        "{}fn t(o: IntOption):\n    if let IntOption::Some(v) = o:\n        break\n",
        INT_OPTION_ENUM_SRC
    );
    assert!(Driver::check(&Driver::parse(&src).expect("should parse")).is_err());
}

// ===== Runtime: `if let` =====================================================

/// `if let` binds the payload and runs the `then` arm on a match.
#[test]
fn runtime_if_let_matches_and_binds_payload_end_to_end() {
    let src = format!(
        "{}fn main():\n    let o = IntOption::Some(42)\n    if let IntOption::Some(v) = o:\n        println(f\"got {{v}}\")\n    else:\n        println(\"none\")\n",
        INT_OPTION_ENUM_SRC
    );
    let output = compile_and_run("if_let_match", &src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "got 42");
}

/// `if let` falls through to `else` when the scrutinee doesn't match.
#[test]
fn runtime_if_let_falls_through_to_else_end_to_end() {
    let src = format!(
        "{}fn main():\n    let o = IntOption::None\n    if let IntOption::Some(v) = o:\n        println(f\"got {{v}}\")\n    else:\n        println(\"none\")\n",
        INT_OPTION_ENUM_SRC
    );
    let output = compile_and_run("if_let_none", &src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "none");
}

/// `if let` with no `else` and no match simply does nothing.
#[test]
fn runtime_if_let_without_else_no_match_is_a_no_op_end_to_end() {
    let src = format!(
        "{}fn main():\n    let o = IntOption::None\n    if let IntOption::Some(v) = o:\n        println(f\"got {{v}}\")\n    println(\"done\")\n",
        INT_OPTION_ENUM_SRC
    );
    let output = compile_and_run("if_let_no_else", &src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "done");
}

/// `if let` over a `Result`-shaped enum's `Ok`/`Err` variants (a second,
/// distinct enum -- not special-cased in any way, just an ordinary enum).
#[test]
fn runtime_if_let_over_result_shaped_enum_end_to_end() {
    let src = format!(
        "{}fn main():\n    let r = IntResult::Err(7)\n    if let IntResult::Ok(v) = r:\n        println(f\"ok {{v}}\")\n    else:\n        println(\"err\")\n",
        INT_RESULT_ENUM_SRC
    );
    let output = compile_and_run("if_let_result", &src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "err");
}

// ===== Runtime: `while let` ===================================================

/// `while let` loops as long as a repeatedly-called function keeps
/// returning a match, and stops the moment it returns `None` -- the classic
/// "loop until `None`/`Err`" shape (`docs/requests.md` #3).
#[test]
fn runtime_while_let_loops_until_none_end_to_end() {
    let src = format!(
        "{}fn next(mut n: i32) -> IntOption:\n    if n <= 0:\n        return IntOption::None\n    return IntOption::Some(n)\n\nfn main():\n    let mut n = 3\n    while let IntOption::Some(v) = next(n):\n        println(f\"{{v}}\")\n        n -= 1\n    println(\"done\")\n",
        INT_OPTION_ENUM_SRC
    );
    let output = compile_and_run("while_let_countdown", &src);
    let stdout = String::from_utf8_lossy(&output.stdout).replace("\r\n", "\n");
    assert_eq!(stdout.trim(), "3\n2\n1\ndone");
}

/// A `while let` whose scrutinee never matches runs zero times.
#[test]
fn runtime_while_let_never_matches_runs_zero_times_end_to_end() {
    let src = format!(
        "{}fn main():\n    while let IntOption::Some(v) = IntOption::None:\n        println(f\"{{v}}\")\n    println(\"done\")\n",
        INT_OPTION_ENUM_SRC
    );
    let output = compile_and_run("while_let_zero", &src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "done");
}

/// `break` inside a `while let` body exits the loop early, before its
/// natural "stops matching" end.
#[test]
fn runtime_while_let_break_exits_early_end_to_end() {
    let src = format!(
        "{}fn next(mut n: i32) -> IntOption:\n    if n <= 0:\n        return IntOption::None\n    return IntOption::Some(n)\n\nfn main():\n    let mut n = 5\n    while let IntOption::Some(v) = next(n):\n        if v == 3:\n            break\n        println(f\"{{v}}\")\n        n -= 1\n    println(\"done\")\n",
        INT_OPTION_ENUM_SRC
    );
    let output = compile_and_run("while_let_break", &src);
    let stdout = String::from_utf8_lossy(&output.stdout).replace("\r\n", "\n");
    assert_eq!(stdout.trim(), "5\n4\ndone");
}

/// `continue` inside a `while let` body re-evaluates the scrutinee
/// expression again (it lives inside the loop, re-run every iteration --
/// see `Parser::parse_while_let_stmt`'s doc comment), not an infinite loop
/// on the same stale value.
#[test]
fn runtime_while_let_continue_reevaluates_scrutinee_end_to_end() {
    let src = format!(
        "{}fn next(mut n: i32) -> IntOption:\n    if n <= 0:\n        return IntOption::None\n    return IntOption::Some(n)\n\nfn main():\n    let mut n = 5\n    while let IntOption::Some(v) = next(n):\n        n -= 1\n        if v % 2 == 0:\n            continue\n        println(f\"{{v}}\")\n    println(\"done\")\n",
        INT_OPTION_ENUM_SRC
    );
    let output = compile_and_run("while_let_continue", &src);
    let stdout = String::from_utf8_lossy(&output.stdout).replace("\r\n", "\n");
    assert_eq!(stdout.trim(), "5\n3\n1\ndone");
}
