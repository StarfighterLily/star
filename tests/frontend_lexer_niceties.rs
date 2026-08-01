//! Lexer-only entries from `docs/requests.md`: digit separators (#2), block
//! comments (#1), and multi-line string literals (#5). All three are pure
//! `src/lexer.rs` changes -- no new `TokenKind`, no parser/checker/codegen
//! changes -- so these tests exercise the lexer directly (`Driver::lex`)
//! alongside a handful of real compile-and-run round-trips proving the
//! resulting tokens flow all the way through unchanged.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Digit separators (docs/requests.md #2) ==============================

/// `1_000_000` must lex to the same `Int` as `1000000`.
#[test]
fn digit_separator_in_decimal_int_literal() {
    let tokens = Driver::lex("1_000_000\n").expect("should lex");
    assert_eq!(tokens[0].kind, TokenKind::Int(1_000_000));
}

/// Multiple/consecutive underscores are just stripped, not an error.
#[test]
fn digit_separator_consecutive_underscores() {
    let tokens = Driver::lex("1__000\n").expect("should lex");
    assert_eq!(tokens[0].kind, TokenKind::Int(1000));
}

/// A trailing separator is tolerated the same way (the lexer is lenient --
/// no dedicated "invalid trailing underscore" diagnostic).
#[test]
fn digit_separator_trailing_underscore() {
    let tokens = Driver::lex("100_\n").expect("should lex");
    assert_eq!(tokens[0].kind, TokenKind::Int(100));
}

/// Digit separators inside a hex literal (`0x1_F4`).
#[test]
fn digit_separator_in_hex_literal() {
    let tokens = Driver::lex("0x1_F4\n").expect("should lex");
    assert_eq!(tokens[0].kind, TokenKind::Int(0x1F4));
}

/// Digit separators inside a float's integer part, fraction, and exponent.
#[test]
fn digit_separator_in_float_literal() {
    let tokens = Driver::lex("1_000.5_5\n").expect("should lex");
    assert_eq!(tokens[0].kind, TokenKind::Float(1000.55));
}

/// Digit separators inside a scientific-notation exponent (`1e1_0`).
#[test]
fn digit_separator_in_exponent() {
    let tokens = Driver::lex("1e1_0\n").expect("should lex");
    assert_eq!(tokens[0].kind, TokenKind::Float(1e10));
}

/// A tuple index (`t.0`) is untouched by digit-separator scanning -- it
/// never contains an underscore, but this pins down that the lexer's
/// member-access-dot exclusion logic still works with `scan_digit_run` in
/// place of the old bare `is_ascii_digit()` loop.
#[test]
fn digit_separator_does_not_break_tuple_index() {
    let src = "fn main():\n    let t = (1, 2)\n    let x = t.0\n    let y = t.1\n";
    Driver::check(&Driver::parse(src).expect("should parse")).expect("should type-check");
}

/// End-to-end: a digit-separated literal used in real arithmetic produces
/// the expected runtime result, not just the expected token.
#[test]
fn runtime_digit_separator_arithmetic_end_to_end() {
    let src = "fn main():\n    let x = 1_000_000 + 1\n    println(f\"{x}\")\n";
    let output = compile_and_run("digit_sep_arith", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "1000001");
}

// ===== Block comments (docs/requests.md #1) =================================

/// A block comment on its own line produces no tokens at all.
#[test]
fn block_comment_alone_on_a_line_emits_no_tokens() {
    let src = "fn main():\n    #* this is a comment *#\n    let x = 1\n";
    let tokens = Driver::lex(src).expect("should lex");
    let lets = tokens.iter().filter(|t| matches!(t.kind, TokenKind::Let)).count();
    assert_eq!(lets, 1);
    // Only the two real `Newline`s (`fn main():`, `let x = 1`) -- the
    // comment-only line contributes none, exactly like a `#` line comment.
    let newlines = tokens.iter().filter(|t| t.kind == TokenKind::Newline).count();
    assert_eq!(newlines, 2);
}

/// A block comment spanning several physical lines, with indented real code
/// resuming afterward -- the resumed code's indentation must be measured on
/// its own leading whitespace, not the comment's starting column.
#[test]
fn block_comment_spans_multiple_lines() {
    let src = "fn main():\n    #* first line\n    second line\n    third line *#\n    let x = 1\n";
    let module = Driver::parse(src).expect("multi-line block comment should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert_eq!(f.body.stmts.len(), 1);
}

/// A block comment can be balanced/nested: an inner `#*` doesn't close the
/// comment at the first `*#` it contains.
#[test]
fn block_comment_nests() {
    let src = "fn main():\n    #* outer #* inner *# still commented *#\n    let x = 1\n";
    let module = Driver::parse(src).expect("nested block comment should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert_eq!(f.body.stmts.len(), 1);
}

/// Real code may follow a block comment's close on the same physical line.
#[test]
fn block_comment_followed_by_code_on_same_line() {
    let src = "fn main():\n    #* comment *# let x = 1\n    let y = 2\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert_eq!(f.body.stmts.len(), 2);
}

/// A block comment can contain its own `#` line-comment-shaped text without
/// that text prematurely ending anything.
#[test]
fn block_comment_contains_hash_line_comment_syntax() {
    let src = "fn main():\n    #* # let z = 999 -- old code\n    let w = 1 *#\n    let x = 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert_eq!(f.body.stmts.len(), 1);
}

/// An unterminated block comment is a real lexer error, not a silent
/// swallow-to-EOF.
#[test]
fn unterminated_block_comment_is_an_error() {
    let src = "fn main():\n    #* never closed\n    let x = 1\n";
    let result = Driver::lex(src);
    assert!(result.is_err(), "unterminated block comment should be a lex error");
}

/// A block comment used inline, mid-expression, inside brackets where
/// newlines are already insignificant.
#[test]
fn block_comment_inline_inside_expression() {
    let src = "fn main():\n    let x = 1 + #* two *# 2\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    assert!(matches!(value, Expr::Binary { .. }));
}

/// End-to-end: a block comment around real, would-otherwise-run code
/// actually suppresses it.
#[test]
fn runtime_block_comment_suppresses_commented_code_end_to_end() {
    let src = "fn main():\n    let x = 1\n    #* let x = 999\n    println(f\"wrong: {x}\") *#\n    println(f\"{x}\")\n";
    let output = compile_and_run("block_comment_suppresses", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "1");
}

// ===== Multi-line string literals (docs/requests.md #5) =====================

/// A `"""..."""` literal spanning multiple physical lines lexes to a single
/// `Str` token containing a real embedded newline.
#[test]
fn triple_quoted_string_spans_lines() {
    let src = "\"\"\"line one\nline two\"\"\"\n";
    let tokens = Driver::lex(src).expect("should lex");
    assert_eq!(tokens[0].kind, TokenKind::Str("line one\nline two".to_string()));
}

/// An empty triple-quoted string.
#[test]
fn triple_quoted_string_empty() {
    let tokens = Driver::lex("\"\"\"\"\"\"\n").expect("should lex");
    assert_eq!(tokens[0].kind, TokenKind::Str(String::new()));
}

/// Escapes still work the same inside a triple-quoted literal.
#[test]
fn triple_quoted_string_supports_escapes() {
    let src = "\"\"\"tab:\\tend\"\"\"\n";
    let tokens = Driver::lex(src).expect("should lex");
    assert_eq!(tokens[0].kind, TokenKind::Str("tab:\tend".to_string()));
}

/// A single unescaped `"` inside a triple-quoted literal is just content --
/// only three in a row closes it.
#[test]
fn triple_quoted_string_allows_lone_quotes() {
    let src = "\"\"\"she said \"hi\" to me\"\"\"\n";
    let tokens = Driver::lex(src).expect("should lex");
    assert_eq!(tokens[0].kind, TokenKind::Str("she said \"hi\" to me".to_string()));
}

/// An unterminated triple-quoted string is a real lexer error.
#[test]
fn unterminated_triple_quoted_string_is_an_error() {
    let result = Driver::lex("\"\"\"never closed\n");
    assert!(result.is_err(), "unterminated triple-quoted string should be a lex error");
}

/// A triple-quoted string parses as an ordinary `str` expression, usable
/// anywhere a plain string literal is.
#[test]
fn triple_quoted_string_parses_as_str_expr() {
    let src = "fn main():\n    let x = \"\"\"hello\nworld\"\"\"\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    assert!(matches!(value, Expr::Str(s, _) if s == "hello\nworld"));
}

/// End-to-end: a multi-line string literal's embedded newline is preserved
/// through to real program output.
#[test]
fn runtime_triple_quoted_string_end_to_end() {
    let src = "fn main():\n    let msg = \"\"\"line one\nline two\"\"\"\n    println(msg)\n";
    let output = compile_and_run("triple_quoted_runtime", src);
    // Windows text-mode stdout translates each `\n` to `\r\n` (see other
    // split files' own `stdout.replace("\r\n", "\n")` convention), so the
    // embedded newline inside the literal itself round-trips as `\r\n` too.
    let stdout = String::from_utf8_lossy(&output.stdout).replace("\r\n", "\n");
    assert_eq!(stdout.trim(), "line one\nline two");
}
