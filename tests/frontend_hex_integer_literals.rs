//! Hex integer literals (`todo.md` P1 #4): `0x1F`/`0X1f`-style literals in
//! the lexer. Previously every register code, opcode number, and address
//! constant in a project like Nova had to be written in decimal with a
//! `# 0x..` comment for readability -- there was no hex literal syntax at
//! all.
//!
//! `Lexer::scan_number` now special-cases a `0x`/`0X` prefix ahead of the
//! plain decimal scan (both start on a `0` byte) and parses the following
//! hex digits as a `u64` bit pattern, bit-reinterpreted via `as i64` into
//! the same `TokenKind::Int(i64)` a decimal literal produces -- so every
//! downstream stage (parser, checker, const-folding, codegen) needs zero
//! changes: a hex literal is just another spelling for `Expr::Int`, subject
//! to the exact same default-`i32`/widening-cast-fast-path rules already
//! covered for decimal literals in `tests/frontend_numeric_widths_and_char.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Lexer =================================================================

/// A basic lowercase-prefix, lowercase-digit hex literal lexes to the same
/// `TokenKind::Int` a decimal literal would.
#[test]
fn lexes_hex_literal_as_int_token() {
    let src = "fn main():\n    let x = 0xff\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert!(kinds.contains(&TokenKind::Int(255)), "{:?}", kinds);
}

/// Uppercase hex digits (`A`-`F`) are accepted, not just lowercase.
#[test]
fn lexes_uppercase_hex_digits() {
    let src = "fn main():\n    let x = 0xDEADBEEF\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert!(kinds.contains(&TokenKind::Int(0xDEADBEEFu32 as i64)), "{:?}", kinds);
}

/// Mixed-case digits (`0xdEaD`) and an uppercase `0X` prefix both work --
/// the prefix/digit checks aren't accidentally case-sensitive in only one
/// direction.
#[test]
fn lexes_mixed_case_digits_and_uppercase_x_prefix() {
    let src = "fn main():\n    let a = 0xdEaD\n    let b = 0X1f\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert!(kinds.contains(&TokenKind::Int(0xDEAD)), "{:?}", kinds);
    assert!(kinds.contains(&TokenKind::Int(31)), "{:?}", kinds);
}

/// `0x0` is a legal (zero-valued) hex literal, not an off-by-one edge case
/// that the "at least one digit" check rejects.
#[test]
fn lexes_hex_zero() {
    let src = "fn main():\n    let x = 0x0\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert!(kinds.contains(&TokenKind::Int(0)), "{:?}", kinds);
}

/// A hex literal immediately followed by an operator (no whitespace) stops
/// scanning exactly at the last hex digit -- `0xFF+1` must lex as `Int(255)`
/// `Plus` `Int(1)`, not swallow the `+` or misparse the boundary.
#[test]
fn lexes_hex_literal_stops_at_non_hex_digit_boundary() {
    let src = "fn main():\n    let x = 0xFF+1\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    let pos = kinds.iter().position(|k| *k == TokenKind::Int(255)).expect("expected Int(255)");
    assert_eq!(kinds[pos + 1], TokenKind::Plus, "{:?}", kinds);
    assert_eq!(kinds[pos + 2], TokenKind::Int(1), "{:?}", kinds);
}

/// `0x` with no digits after the prefix is a lexer error, not a silent
/// `Int(0)`/panic -- guards the `digits.is_empty()` branch.
#[test]
fn rejects_hex_literal_with_no_digits() {
    let src = "fn main():\n    let x = 0x\n";
    let result = Driver::lex(src);
    let errs = result.expect_err("a bare '0x' with no digits should be a lexer error");
    assert!(errs.iter().any(|d| d.message.contains("hex literal must have at least one digit after '0x'")), "{:?}", errs);
}

/// `0x` followed immediately by a non-hex-digit, non-identifier character
/// (rather than end-of-line) hits the same empty-digits error path.
#[test]
fn rejects_hex_literal_with_no_digits_before_operator() {
    let src = "fn main():\n    let x = 0x + 1\n";
    let result = Driver::lex(src);
    let errs = result.expect_err("'0x' followed by a space should still be an empty-digits error");
    assert!(errs.iter().any(|d| d.message.contains("hex literal must have at least one digit after '0x'")), "{:?}", errs);
}

/// A hex literal with more than 16 hex digits doesn't fit any `u64` bit
/// pattern -- must be a clean diagnostic, not a panic or silent truncation.
#[test]
fn rejects_hex_literal_too_large_for_u64() {
    let src = "fn main():\n    let x = 0x123456789ABCDEF01\n"; // 17 hex digits
    let result = Driver::lex(src);
    let errs = result.expect_err("a 17-hex-digit literal should be too large for u64");
    assert!(errs.iter().any(|d| d.message.contains("is too large")), "{:?}", errs);
}

/// The full 16-hex-digit `u64::MAX` bit pattern (`0xFFFFFFFFFFFFFFFF`) must
/// still lex successfully -- the boundary case just inside the limit the
/// previous test sits just outside of. Its `i64` bit-reinterpretation is
/// `-1`.
#[test]
fn lexes_max_u64_hex_literal_as_negative_one_bit_pattern() {
    let src = "fn main():\n    let x = 0xFFFFFFFFFFFFFFFF\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert!(kinds.contains(&TokenKind::Int(-1)), "{:?}", kinds);
}

/// A leading `0` that is *not* followed by `x`/`X` must still lex as a plain
/// decimal literal -- the new hex-prefix check must not misfire on every
/// number starting with `0`.
#[test]
fn lexes_plain_zero_and_leading_zero_decimals_unaffected() {
    let src = "fn main():\n    let a = 0\n    let b = 07\n    let c = 0.5\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert!(kinds.contains(&TokenKind::Int(0)), "{:?}", kinds);
    assert!(kinds.contains(&TokenKind::Int(7)), "{:?}", kinds);
    assert!(kinds.contains(&TokenKind::Float(0.5)), "{:?}", kinds);
}

/// A decimal literal that merely *contains* `x`-adjacent digits, or an
/// identifier starting right after a non-zero digit, must not be mistaken
/// for a hex literal -- the `0x`/`0X` check only fires when the leading
/// digit is exactly `0`.
#[test]
fn does_not_treat_non_zero_leading_digit_as_hex_prefix() {
    let src = "fn main():\n    let x = 1\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert!(kinds.contains(&TokenKind::Int(1)), "{:?}", kinds);
}

// ===== Parser =================================================================

/// A hex literal parses to a plain `Expr::Int` carrying its decoded value --
/// exactly the same AST node a decimal literal produces, so every existing
/// consumer of `Expr::Int` (checker, const-folding, codegen) works
/// unmodified.
#[test]
fn parses_hex_literal_expression() {
    let src = "fn main():\n    let x = 0x2A\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected Let") };
    assert!(matches!(value, Expr::Int(42, _)), "{:?}", value);
}

/// A hex literal is legal wherever a decimal one is -- here, as a fixed
/// array's repeat count (`[value; N]`).
#[test]
fn parses_hex_literal_as_fixed_array_repeat_count() {
    let src = "fn main():\n    let xs = [0; 0x4]\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected Let") };
    let Expr::ArrayRepeat { count, .. } = value else { panic!("expected ArrayRepeat, got {:?}", value) };
    assert_eq!(*count, 4);
}

// ===== Checker ================================================================

/// A hex literal within `i32` range defaults to `Ty::Int`, exactly like a
/// decimal one.
#[test]
fn hex_literal_within_i32_range_defaults_to_int_ty() {
    let ty = typed_fn_result_ty("fn main():\n    0xFF\n");
    assert_eq!(ty, Ty::Int);
}

/// A hex literal whose magnitude exceeds `i32::MAX` without a widening cast
/// hits the exact same "too large for a 32-bit integer" diagnostic a
/// decimal literal of the same magnitude would (`Checker::infer_expr`'s
/// `Expr::Int` arm) -- this fix does not special-case hex literals into
/// their own, more permissive default-type rule.
#[test]
fn rejects_oversized_hex_literal_without_widening_cast() {
    let src = "fn main():\n    let x = 0x100000000\n"; // 4294967296, > i32::MAX
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("too large for a 32-bit integer")), "{:?}", diags);
}

/// The same oversized hex literal *does* type-check once directly widened
/// by an `as i64` cast -- reusing `Expr::Cast`'s literal fast path
/// (`cast_literal_magnitude`), the same mechanism that already lets
/// `5000000000 as i64` through for decimal literals.
#[test]
fn accepts_oversized_hex_literal_widened_by_cast() {
    let ty = typed_fn_result_ty("fn main():\n    0x100000000 as i64\n");
    assert_eq!(ty, Ty::I64);
}

/// `0xFFFFFFFF` (all 32 bits set) cast to `u32` fits exactly at the top of
/// `u32`'s range -- the boundary case for `int_shape_range`'s unsigned-width
/// branch.
#[test]
fn accepts_all_bits_set_hex_literal_cast_to_u32() {
    let ty = typed_fn_result_ty("fn main():\n    0xFFFFFFFF as u32\n");
    assert_eq!(ty, Ty::U32);
}

/// A hex literal combined with the bitwise operators (`todo.md` P0 #3) type-
/// checks the same as decimal operands of the same type.
#[test]
fn hex_literal_type_checks_with_bitwise_operators() {
    let ty = typed_fn_result_ty("fn main():\n    let a: i32 = 0xF0\n    let b: i32 = 0x0F\n    a | b\n");
    assert_eq!(ty, Ty::Int);
}

// ===== Const folding ==========================================================

/// A top-level `const` initializer built entirely from hex literals and the
/// bitwise operators folds at compile time via `eval_const_binop`, the same
/// path a decimal-literal `const` expression already uses.
#[test]
fn const_initializer_folds_hex_literals_with_bitwise_ops() {
    let src = "const MASK: i32 = 0xF0 & 0xFF\nfn main():\n    println(f\"{MASK}\")\n";
    let output = compile_and_run("hex_const_fold", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim(), "240");
}

// ===== Codegen (IR shape) =====================================================

/// A hex literal lowers to the exact same LLVM constant a decimal literal of
/// the same value would -- no separate "hex" representation survives past
/// the lexer.
#[test]
fn codegen_hex_literal_lowers_to_plain_i32_constant() {
    let src = "fn main():\n    let x: i32 = 0xFF\n    println(f\"{x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let body = extract_fn_body(&ir, "define i32 @main(");
    assert!(body.contains("i32 255"), "{}", body);
}

// ===== Runtime end-to-end =====================================================

/// A realistic Nova-style register/mask-manipulation program written with
/// hex literals throughout: masking, combining, and shifting a 16-bit-style
/// value using `&`/`|`/`<<`, plus a large hex constant widened via `as i64`
/// and an all-bits-set `u32` cast -- exercising hex literals through the
/// exact operators/casts this fix is meant to make ergonomic for that kind
/// of code.
#[test]
fn runtime_hex_literals_in_register_style_arithmetic_end_to_end() {
    let src = "fn main():\n    \
               let reg: i32 = 0x1234\n    let mask: i32 = 0xFF\n    println(f\"{reg & mask}\")\n    \
               println(f\"{reg | 0xFF00}\")\n    \
               println(f\"{0x10 << 4}\")\n    \
               let big: i64 = 0x100000000 as i64\n    println(f\"{big}\")\n    \
               let full: u32 = 0xFFFFFFFF as u32\n    println(f\"{full}\")\n";
    let output = compile_and_run("hex_literal_register_arith", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["52", "65332", "256", "4294967296", "4294967295"], "{}", stdout);
}

/// Hex and decimal literals of equal value are interchangeable at runtime --
/// `0x2A` and `42` must compare equal and produce identical arithmetic
/// results, confirming the hex path is genuinely just an alternate spelling
/// with no divergent representation.
#[test]
fn runtime_hex_and_decimal_literals_of_equal_value_are_interchangeable() {
    let src = "fn main():\n    let a = 0x2A\n    let b = 42\n    println(f\"{a == b}\")\n    println(f\"{a + b}\")\n";
    let output = compile_and_run("hex_decimal_equivalence", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "84"], "{}", stdout);
}
