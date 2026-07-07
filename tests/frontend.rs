//! Integration tests for the Star front-end (lexer + parser).
//!
//! These drive the public `star` library API over small `.star` snippets and
//! the canonical example, guarding against regressions in tokenization,
//! indentation handling, and parsing.

use star::ast::{Expr, Item, Stmt};
use star::driver::Driver;
use star::lexer::TokenKind;

/// Lexing a struct should emit INDENT/DEDENT around the field block.
#[test]
fn lexes_indentation_markers() {
    let src = "struct P:\n    health: i32\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert!(kinds.contains(&TokenKind::Indent));
    assert!(kinds.contains(&TokenKind::Dedent));
    assert_eq!(kinds.last(), Some(&TokenKind::Eof));
}

/// Blank and comment-only lines must not produce structural tokens.
#[test]
fn ignores_blank_and_comment_lines() {
    let src = "struct P:\n\n    # a comment\n    health: i32\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let indents = tokens.iter().filter(|t| t.kind == TokenKind::Indent).count();
    assert_eq!(indents, 1, "only one real indentation level expected");
}

/// The canonical example from the docs must parse without diagnostics.
#[test]
fn parses_canonical_example() {
    let src = include_str!("../examples/player.star");
    let module = Driver::parse(src).expect("canonical example should parse");
    // The example is a complete, runnable program:
    //   0: struct Vec3
    //   1: struct Player
    //   2: trait Damageable
    //   3: impl Damageable for Player
    //   4: fn main()
    assert_eq!(module.items.len(), 5);
    assert!(matches!(module.items[0], Item::Struct(_)));
    assert!(matches!(module.items[1], Item::Struct(_)));
    assert!(matches!(module.items[2], Item::Trait(_)));
    assert!(matches!(module.items[3], Item::Impl(_)));
    assert!(matches!(module.items[4], Item::Fn(_)));
}

/// A struct field with a default should retain its initializer expression.
#[test]
fn parses_field_default() {
    let src = "struct P:\n    mut health: i32 = 100\n";
    let module = Driver::parse(src).unwrap();
    let Item::Struct(def) = &module.items[0] else {
        panic!("expected a struct");
    };
    let field = &def.fields[0];
    assert!(field.is_mut);
    assert_eq!(field.name, "health");
    assert!(matches!(field.default, Some(Expr::Int(100, _))));
}

/// Compound assignment inside a method body should parse as an `Assign` stmt.
#[test]
fn parses_compound_assignment() {
    let src = concat!(
        "impl Damageable for Player:\n",
        "    fn take_damage(mut self, amount: i32):\n",
        "        self.health -= amount\n",
    );
    let module = Driver::parse(src).unwrap();
    let Item::Impl(block) = &module.items[0] else {
        panic!("expected an impl block");
    };
    let body = &block.methods[0].body;
    assert!(matches!(body.stmts[0], Stmt::Assign { .. }));
}

/// Inconsistent indentation must be reported as an error rather than panic.
#[test]
fn rejects_inconsistent_indentation() {
    // Second field is indented to a column that matches no enclosing level.
    let src = "struct P:\n    a: i32\n  b: i32\n";
    let result = Driver::lex(src);
    assert!(result.is_err(), "misaligned dedent should be an error");
}

// ===== M9 Control Flow Tests ==============================================

/// Parse `if` statement with both branches.
#[test]
fn parses_if_else() {
    let src = "fn test(x: i32):\n    if x > 0:\n        let a = 1\n    else:\n        let b = 2\n";
    let module = Driver::parse(src).unwrap();
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn"); };
    assert!(matches!(&f.body.stmts[0], Stmt::If { else_block: Some(_), .. }));
    let Stmt::If { cond, then_block, else_block, .. } = &f.body.stmts[0] else { panic!("expected If"); };
    assert!(matches!(cond, Expr::Binary { op, .. } if *op == star::ast::BinOp::Gt));
    assert_eq!(then_block.stmts.len(), 1);
    assert_eq!(else_block.as_ref().unwrap().stmts.len(), 1);
}

/// Parse `while` loop with optional else.
#[test]
fn parses_while() {
    let src = "fn test(x: i32):\n    while x > 0:\n        x -= 1\n    else:\n        pass\n";
    let module = Driver::parse(src).unwrap();
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn"); };
    assert!(matches!(&f.body.stmts[0], Stmt::While { else_block: Some(_), .. }));
    let Stmt::While { cond, .. } = &f.body.stmts[0] else { panic!("expected While"); };
    assert!(matches!(cond, Expr::Binary { op, .. } if *op == star::ast::BinOp::Gt));
}

/// Parse `if` expression used as a value.
#[test]
fn parses_if_expr() {
    let src = "fn test(x: i32):\n    let r = if x > 0:\n        1\n    else:\n        2\n";
    let module = Driver::parse(src).unwrap();
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn"); };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected Let"); };
    assert!(matches!(value, Expr::If { .. }));
    match value {
        Expr::If { then_block, else_block, .. } => {
            assert!(matches!(then_block.stmts[0], Stmt::Expr(Expr::Int(1, _))));
            assert!(matches!(else_block.as_ref().unwrap().stmts[0], Stmt::Expr(Expr::Int(2, _))));
        }
        _ => panic!("expected Expr::If"),
    }
}

/// Codegen for if/while: IR should contain `br i1`, `phi`, and block labels.
#[test]
fn codegen_if_while() {
    let src = concat!(
        "fn main():\n",
        "    let x = 5\n",
        "    if x > 0:\n",
        "        print(f\"then\")\n",
        "    else:\n",
        "        print(f\"else\")\n",
        "    x = 0\n",
        "    while x < 3:\n",
        "        x += 1\n",
        "    x\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    // Assert if/else uses conditional branch.
    assert!(ir.contains("br i1"), "if should use conditional branch");
    // Assert both if and while generate block labels.
    assert!(ir.contains("if_then"), "if then block label should appear");
    assert!(ir.contains("if_else"), "if else block label should appear");
    assert!(ir.contains("while_cond"), "while cond block label should appear");
    assert!(ir.contains("while_body"), "while body block label should appear");
}