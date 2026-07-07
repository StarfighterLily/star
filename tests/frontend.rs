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
    // Expect three items: struct Player, trait Damageable, impl block.
    assert_eq!(module.items.len(), 3);
    assert!(matches!(module.items[0], Item::Struct(_)));
    assert!(matches!(module.items[1], Item::Trait(_)));
    assert!(matches!(module.items[2], Item::Impl(_)));
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