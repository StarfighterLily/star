//! `elif` -- todo.md P2 #7.
//!
//! Previously only `if`/`else` existed; a multi-way branch needed a `match`
//! with comparison-guard arms or hand-nested `else:` + `if`. `elif <cond>:`
//! is pure parser-level sugar for exactly that hand-nested shape: `Parser::
//! parse_if_else_tail` (statement form, `src/parser/stmt.rs`) and `Parser::
//! parse_if_else_tail_expr` (expression form, `src/parser/expr.rs`) desugar
//! an `elif` arm into a synthetic nested `Stmt::If`/`Expr::If` held inside
//! the enclosing arm's `else_block`, recursing for further `elif`/`else`
//! tail. No new AST/`TypedStmt`/`TypedExpr` variant exists anywhere, and no
//! new lexer keyword reaches past the parser -- so the checker, `sequence`/
//! `frame`/`par` analysis, and codegen all need zero new match arms; they
//! see the identical nested-if shape the manual workaround already produced.
//!
//! Shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Parser / AST-shape ==================================================

/// `if a: .. elif b: ..` (statement form, no trailing `else`) desugars to an
/// outer `Stmt::If` whose `else_block` holds exactly one statement: a nested
/// `Stmt::If` for `b`, itself with no `else_block`.
#[test]
fn parses_elif_desugars_to_nested_if_in_else_block() {
    let src = "fn main():\n    if 1 == 1:\n        println(\"a\")\n    elif 2 == 2:\n        println(\"b\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn item") };
    let Stmt::If { else_block: outer_else, .. } = &f.body.stmts[0] else { panic!("expected the outer if") };
    let outer_else = outer_else.as_ref().expect("elif should produce a synthetic else_block");
    assert_eq!(outer_else.stmts.len(), 1, "elif's else_block should hold exactly the nested if: {:?}", outer_else.stmts);
    let Stmt::If { cond: inner_cond, else_block: inner_else, .. } = &outer_else.stmts[0] else {
        panic!("expected a nested Stmt::If, got {:?}", outer_else.stmts[0])
    };
    assert!(matches!(inner_cond, Expr::Binary { .. }), "{:?}", inner_cond);
    assert!(inner_else.is_none(), "no trailing else was written, so the innermost if should have none");
}

/// A full `if`/`elif`/`elif`/`else` chain nests three levels deep, in order,
/// with the final `else`'s block landing on the innermost `if`.
#[test]
fn parses_if_elif_elif_else_chain_nests_in_order() {
    let src = concat!(
        "fn main():\n",
        "    if 1 == 1:\n",
        "        println(\"a\")\n",
        "    elif 2 == 2:\n",
        "        println(\"b\")\n",
        "    elif 3 == 3:\n",
        "        println(\"c\")\n",
        "    else:\n",
        "        println(\"d\")\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!() };
    let Stmt::If { else_block: e1, .. } = &f.body.stmts[0] else { panic!("expected outer if") };
    let e1 = e1.as_ref().expect("first elif");
    let Stmt::If { else_block: e2, .. } = &e1.stmts[0] else { panic!("expected first nested if") };
    let e2 = e2.as_ref().expect("second elif");
    let Stmt::If { else_block: e3, .. } = &e2.stmts[0] else { panic!("expected second nested if") };
    let e3 = e3.as_ref().expect("trailing else");
    // The innermost `else_block` is the plain `else:` body itself (a
    // `println("d")` statement), not another synthetic nested if.
    assert!(matches!(&e3.stmts[0], Stmt::Expr(_)), "expected the else body directly, got {:?}", e3.stmts[0]);
}

/// The compact single-line form works for `elif` exactly like it already did
/// for plain `if`/`else`: `if a: 1 elif b: 2 else: 3` all on one line, with
/// each arm a one-statement inline block rather than a full indented one.
#[test]
fn parses_compact_inline_elif_chain() {
    let src = "fn main():\n    let x = if 1 == 2: 10 elif 2 == 2: 20 else: 30\n    println(f\"{x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!() };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let x = ...") };
    let Expr::If { then_block, else_block, .. } = value else { panic!("expected an if-expression, got {:?}", value) };
    assert!(matches!(&then_block.stmts[0], Stmt::Expr(Expr::Int(10, _))), "{:?}", then_block.stmts);
    let else_block = else_block.as_ref().expect("elif should produce an else_block");
    let Stmt::Expr(Expr::If { .. }) = &else_block.stmts[0] else { panic!("expected nested if expr, got {:?}", else_block.stmts[0]) };
}

/// Expression-form `elif` (used on a `let`'s RHS) desugars the same way as
/// the statement form, but wraps the nested `Expr::If` in a `Stmt::Expr`
/// (the same shape an ordinary trailing-expression block already uses) so it
/// remains a value.
#[test]
fn parses_expr_form_elif_wraps_nested_if_in_stmt_expr() {
    let src = "fn main():\n    let x = if 1 == 2:\n        10\n    elif 2 == 2:\n        20\n    else:\n        30\n    println(f\"{x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!() };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let x = ...") };
    let Expr::If { else_block, .. } = value else { panic!("expected an if-expression, got {:?}", value) };
    let else_block = else_block.as_ref().expect("elif should produce an else_block");
    assert_eq!(else_block.stmts.len(), 1);
    assert!(matches!(&else_block.stmts[0], Stmt::Expr(Expr::If { .. })), "expected a nested if-expression: {:?}", else_block.stmts[0]);
}

/// A malformed `elif` (missing its `:`) is a clean parse error, not a panic,
/// and doesn't corrupt recovery for the rest of the function.
#[test]
fn rejects_elif_missing_colon() {
    let src = "fn main():\n    if 1 == 1:\n        println(\"a\")\n    elif 2 == 2\n        println(\"b\")\n";
    let errs = Driver::parse(src).expect_err("a missing ':' after an elif condition should be rejected");
    assert!(!errs.is_empty());
}

/// `elif` with no condition at all is a clean parse error.
#[test]
fn rejects_elif_missing_condition() {
    let src = "fn main():\n    if 1 == 1:\n        println(\"a\")\n    elif :\n        println(\"b\")\n";
    let errs = Driver::parse(src).expect_err("an elif with no condition should be rejected");
    assert!(!errs.is_empty());
}

// ===== Type-checking ========================================================

/// A non-`bool` `elif` condition is rejected exactly like a non-`bool` `if`
/// condition -- the desugared nested `Stmt::If` goes through the exact same
/// condition-typing rule.
#[test]
fn rejects_non_bool_elif_condition() {
    let src = "fn main():\n    if true:\n        println(\"a\")\n    elif 5:\n        println(\"b\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("a non-bool elif condition must be rejected") };
    assert!(errs.iter().any(|d| d.message.to_lowercase().contains("bool")), "{:?}", errs);
}

/// A full `if`/`elif`/`else` chain in expression position, with every arm
/// agreeing on type, type-checks to that common type.
#[test]
fn checks_elif_expr_chain_infers_common_type() {
    let src = "fn main():\n    let x = if 1 == 2: 10 elif 2 == 2: 20 else: 30\n    println(f\"{x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok());
}

/// `elif` without a trailing `else`, in statement position, still
/// type-checks fine -- same as a plain `if` with no `else`.
#[test]
fn checks_elif_without_trailing_else() {
    let src = "fn main():\n    if false:\n        println(\"a\")\n    elif true:\n        println(\"b\")\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok());
}

// ===== Runtime end-to-end ===================================================

/// A multi-way `elif` chain picks exactly the first matching branch, leaving
/// every later one (including a later condition that would also be true)
/// unevaluated for output purposes.
#[test]
fn runtime_elif_chain_picks_first_matching_branch_end_to_end() {
    let src = r#"
fn classify(n: i32) -> str:
    if n < 0:
        "negative"
    elif n == 0:
        "zero"
    elif n < 10:
        "small"
    elif n < 100:
        "medium"
    else:
        "large"

fn main():
    println(classify(-5))
    println(classify(0))
    println(classify(3))
    println(classify(42))
    println(classify(1000))
"#;
    let output = compile_and_run("elif_chain_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["negative", "zero", "small", "medium", "large"], "{}", stdout);
}

/// An `elif` chain with no trailing `else` simply falls through with no
/// output when nothing matches, and executes the one matching branch
/// otherwise -- exercised inside a loop so it runs across several inputs
/// including the no-match case.
#[test]
fn runtime_elif_chain_without_else_falls_through_end_to_end() {
    let src = r#"
fn main():
    let mut i = 0
    while i < 5:
        if i == 1:
            println("one")
        elif i == 3:
            println("three")
        i += 1
"#;
    let output = compile_and_run("elif_no_else_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["one", "three"], "{}", stdout);
}

/// `elif` used as a value on a `let`'s RHS -- a multi-way expression chain,
/// not just a statement -- picks the right branch's value.
#[test]
fn runtime_elif_expression_chain_end_to_end() {
    let src = r#"
fn main():
    let mut i = 0
    while i < 4:
        let label = if i == 0: "zero" elif i == 1: "one" elif i == 2: "two" else: "many"
        println(label)
        i += 1
"#;
    let output = compile_and_run("elif_expr_chain_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["zero", "one", "two", "many"], "{}", stdout);
}

/// A realistic Nova-style opcode dispatch: a long `elif` chain over an
/// integer selecting between several multi-statement handler bodies --
/// mirrors the motivating "multi-way branch" use case from todo.md P2 #7,
/// including a handler that itself mutates outer state (not just returns a
/// value).
#[test]
fn runtime_elif_opcode_dispatch_style_chain_end_to_end() {
    let src = r#"
fn main():
    let mut acc = 0
    let mut opcode = 0
    while opcode < 5:
        if opcode == 0:
            acc += 1
        elif opcode == 1:
            acc += 10
        elif opcode == 2:
            acc += 100
        elif opcode == 3:
            acc -= 5
        else:
            acc *= 2
        println(f"{opcode} {acc}")
        opcode += 1
"#;
    let output = compile_and_run("elif_opcode_dispatch_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    // acc: 0+1=1, 1+10=11, 11+100=111, 111-5=106, 106*2=212
    assert_eq!(lines, vec!["0 1", "1 11", "2 111", "3 106", "4 212"], "{}", stdout);
}

/// `elif` nests correctly even when an inner branch itself contains a plain
/// `if`/`else` (not `elif`) -- the desugaring must not confuse the two, and
/// the ordinary nested `if` should still see its own, unrelated `else`.
#[test]
fn runtime_elif_with_nested_plain_if_inside_a_branch_end_to_end() {
    let src = r#"
fn main():
    let mut n = 0
    while n < 3:
        if n == 0:
            println("zero")
        elif n == 1:
            if n > 0:
                println("one-positive")
            else:
                println("one-nonpositive")
        else:
            println("other")
        n += 1
"#;
    let output = compile_and_run("elif_nested_plain_if_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["zero", "one-positive", "other"], "{}", stdout);
}
