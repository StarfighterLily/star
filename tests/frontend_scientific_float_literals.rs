//! Scientific-notation float literals (`todo.md` P3 #12): `1e10`/`3.0e38`-
//! style literals in the lexer.
//!
//! Found porting Nova's math-library opcodes: `Lexer::scan_number`'s float
//! path only ever scanned digits, an optional `.`, then more digits -- no
//! `e`/`E` exponent suffix at all, so `3.0e38` lexed as the two tokens
//! `Float(3.0)` and the bare identifier `e38` rather than one float token.
//! Nova's `op_exp`/`op_tan` overflow-guard constant had to be spelled out in
//! full (`300000000000000000000000000000000000000.0`, 39 zeros) as a
//! workaround.
//!
//! `Lexer::scan_number` now recognizes an optional `[eE][+-]?[0-9]+`
//! exponent suffix after the existing integer-and-optional-fraction scan,
//! mirroring Rust's own float-literal grammar -- and, like the fraction's
//! own `.` check, only consumes it when a digit genuinely follows (`1e`/
//! `1eXYZ` leave the `e` to be lexed as its own identifier token, exactly
//! like an unfollowed `.` already falls through to being its own `Dot`).
//! Because the token produced is still the same `TokenKind::Float(f64)` a
//! plain decimal float produces, every downstream stage -- parser, checker,
//! const-folding, codegen -- needed no changes at all: a scientific-notation
//! literal is simply an alternate spelling of `Expr::Float`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Lexer =================================================================

/// A bare integer mantissa with a lowercase `e` exponent (no `.`, no sign)
/// lexes as one `Float` token, not an int followed by a stray identifier.
#[test]
fn lexes_integer_mantissa_with_exponent_as_float_token() {
    let src = "fn main():\n    let x = 1e10\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert!(kinds.contains(&TokenKind::Float(1e10)), "{:?}", kinds);
}

/// A decimal mantissa with an exponent -- the exact `3.0e38` shape this
/// item's motivating Nova case needed.
#[test]
fn lexes_decimal_mantissa_with_exponent_as_float_token() {
    let src = "fn main():\n    let x = 3.0e38\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert!(kinds.contains(&TokenKind::Float(3.0e38)), "{:?}", kinds);
}

/// An uppercase `E` exponent marker works identically to lowercase `e`.
#[test]
fn lexes_uppercase_e_exponent() {
    let src = "fn main():\n    let x = 1E5\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert!(kinds.contains(&TokenKind::Float(1e5)), "{:?}", kinds);
}

/// An explicit `+` sign on the exponent is accepted.
#[test]
fn lexes_explicit_plus_sign_exponent() {
    let src = "fn main():\n    let x = 1e+5\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert!(kinds.contains(&TokenKind::Float(1e5)), "{:?}", kinds);
}

/// A negative exponent is accepted and produces the correctly-scaled-down
/// value.
#[test]
fn lexes_negative_exponent() {
    let src = "fn main():\n    let x = 1e-5\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert!(kinds.contains(&TokenKind::Float(1e-5)), "{:?}", kinds);
}

/// A scientific literal immediately followed by an operator (no whitespace)
/// stops scanning exactly at the last exponent digit -- `1e10+1` must lex as
/// `Float(1e10)` `Plus` `Int(1)`, not swallow the `+` or misparse the
/// boundary (mirrors the equivalent hex-literal boundary regression).
#[test]
fn lexes_scientific_literal_stops_at_non_digit_boundary() {
    let src = "fn main():\n    let x = 1e10+1\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    let pos = kinds.iter().position(|k| *k == TokenKind::Float(1e10)).expect("expected Float(1e10)");
    assert_eq!(kinds[pos + 1], TokenKind::Plus, "{:?}", kinds);
    assert_eq!(kinds[pos + 2], TokenKind::Int(1), "{:?}", kinds);
}

/// `e` with no digits after it (and no valid sign-then-digits either) is
/// left completely unconsumed -- the mantissa lexes as a plain `Int`, and
/// the bare `e` becomes its own identifier token, exactly like an
/// unfollowed `.` already falls through to being its own `Dot` rather than
/// starting a float.
#[test]
fn no_digits_after_e_leaves_int_and_separate_identifier() {
    let src = "fn main():\n    let x = 1e\n    let y = 2\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    let pos = kinds.iter().position(|k| *k == TokenKind::Int(1)).expect("expected Int(1)");
    assert_eq!(kinds[pos + 1], TokenKind::Ident("e".into()), "{:?}", kinds);
}

/// `e` followed by a sign but still no digits (`1e+` with nothing after)
/// also leaves the mantissa as a plain `Int` and doesn't consume the sign
/// either -- the sign gets its own `Plus` token right after the bare `e`
/// identifier.
#[test]
fn no_digits_after_e_and_sign_leaves_both_unconsumed() {
    let src = "fn main():\n    let x = 1e+\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    let pos = kinds.iter().position(|k| *k == TokenKind::Int(1)).expect("expected Int(1)");
    assert_eq!(kinds[pos + 1], TokenKind::Ident("e".into()), "{:?}", kinds);
    assert_eq!(kinds[pos + 2], TokenKind::Plus, "{:?}", kinds);
}

/// `e` immediately followed by non-digit identifier characters (`1eXYZ`) is
/// an integer mantissa followed by a separate, ordinary identifier -- not a
/// malformed exponent.
#[test]
fn identifier_starting_with_e_after_int_is_not_confused_for_exponent() {
    let src = "fn main():\n    let x = 1eXYZ\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    let pos = kinds.iter().position(|k| *k == TokenKind::Int(1)).expect("expected Int(1)");
    assert_eq!(kinds[pos + 1], TokenKind::Ident("eXYZ".into()), "{:?}", kinds);
}

/// A tuple index immediately followed by `e`+digits (`t.0e3`) must still be
/// read as the plain index `0` followed by a separate identifier `e3` --
/// Star has no leading-dot float spelling, so nothing right after a member-
/// access `.` can ever be a float literal, exponent suffix included.
#[test]
fn tuple_index_followed_by_e_digits_is_not_treated_as_exponent() {
    let src = "fn main():\n    let x = t.0e3\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    let dot_pos = kinds.iter().position(|k| *k == TokenKind::Dot).expect("expected Dot");
    assert_eq!(kinds[dot_pos + 1], TokenKind::Int(0), "{:?}", kinds);
    assert_eq!(kinds[dot_pos + 2], TokenKind::Ident("e3".into()), "{:?}", kinds);
}

/// A large-magnitude literal that overflows even `f64` parses to `f64`'s own
/// `INFINITY` rather than erroring or panicking -- `f64::from_str` itself
/// treats this as legitimate IEEE-754 overflow-to-infinity, not a parse
/// failure, so the lexer's existing `unwrap_or(0.0)` fallback is never hit.
#[test]
fn lexes_exponent_overflowing_f64_as_infinity() {
    let src = "fn main():\n    let x = 1e400\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert!(kinds.contains(&TokenKind::Float(f64::INFINITY)), "{:?}", kinds);
}

/// Plain decimal floats (no exponent) and plain integers are unaffected --
/// the new exponent check never misfires when there's no `e`/`E` present.
#[test]
fn lexes_plain_decimal_and_integer_literals_unaffected() {
    let src = "fn main():\n    let a = 0.5\n    let b = 42\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert!(kinds.contains(&TokenKind::Float(0.5)), "{:?}", kinds);
    assert!(kinds.contains(&TokenKind::Int(42)), "{:?}", kinds);
}

// ===== Parser =================================================================

/// A scientific-notation literal parses to a plain `Expr::Float` carrying
/// its decoded value -- exactly the same AST node a plain decimal float
/// produces, so every existing consumer of `Expr::Float` (checker,
/// const-folding, codegen) works unmodified.
#[test]
fn parses_scientific_literal_expression() {
    let src = "fn main():\n    let x = 1e10\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected Let") };
    assert!(matches!(value, Expr::Float(v, _) if *v == 1e10), "{:?}", value);
}

/// A negated scientific-notation literal (`-1e-5`) parses as ordinary unary
/// negation wrapping the float literal -- the exponent suffix doesn't
/// interfere with the surrounding unary-operator grammar at all.
#[test]
fn parses_negated_scientific_literal() {
    let src = "fn main():\n    let x = -1e-5\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected Let") };
    let Expr::Unary { op: UnOp::Neg, operand: inner, .. } = value else { panic!("expected Unary Neg, got {:?}", value) };
    assert!(matches!(inner.as_ref(), Expr::Float(v, _) if (*v - 1e-5).abs() < 1e-15), "{:?}", inner);
}

// ===== Checker ================================================================

/// A scientific-notation literal defaults to `Ty::Float` (`f32`), exactly
/// like a plain decimal float literal.
#[test]
fn scientific_literal_defaults_to_float_ty() {
    let ty = typed_fn_result_ty("fn main():\n    1e10\n");
    assert_eq!(ty, Ty::Float);
}

/// A scientific-notation literal widened via `as f64` type-checks the same
/// way a plain decimal float literal already does.
#[test]
fn scientific_literal_widened_by_cast_to_f64() {
    let ty = typed_fn_result_ty("fn main():\n    1e10 as f64\n");
    assert_eq!(ty, Ty::F64);
}

/// A scientific-notation literal assigned where an `i32` is expected is a
/// clean type mismatch, not accidentally treated as an integer because it
/// lacks a `.`.
#[test]
fn rejects_scientific_literal_assigned_to_int_typed_let() {
    let src = "fn main():\n    let x: i32 = 1e10\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("Float")), "{:?}", diags);
}

/// A malformed `1e` with no exponent digits is a clean parse error (not a
/// panic, and not silently accepted as `Int(1)` followed by garbage) --
/// confirms the lexer's "leave `e` unconsumed" fallback surfaces as an
/// ordinary "expected end of line" diagnostic once the parser sees the
/// stray identifier token trailing the statement.
#[test]
fn rejects_malformed_trailing_e_with_no_exponent_digits() {
    let src = "fn main():\n    let x = 1e\n";
    let result = Driver::parse(src);
    let errs = result.expect_err("a bare '1e' with no exponent digits should be a parse error");
    assert!(errs.iter().any(|d| d.message.contains("identifier")), "{:?}", errs);
}

// ===== Const folding ==========================================================

/// A top-level `const` initializer written as a scientific-notation literal
/// folds and prints correctly at runtime -- exactly the `MATH_OVERFLOW_GUARD`
/// shape Nova's math library needed, now spelled `3.0e38` instead of the
/// 39-zero decimal expansion.
#[test]
fn const_initializer_with_scientific_literal_runs_end_to_end() {
    let src = "const MATH_OVERFLOW_GUARD: f32 = 3.0e38\nfn main():\n    println(f\"{MATH_OVERFLOW_GUARD}\")\n";
    let output = compile_and_run("sci_const_fold", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim(), "300000000549775575777803994281145270272.000000");
}

// ===== Codegen (IR shape) =====================================================

/// A scientific-notation literal lowers to the exact same LLVM `f32`
/// constant bit pattern the equivalent plain decimal literal would -- no
/// separate "scientific" representation survives past the lexer.
#[test]
fn codegen_scientific_literal_lowers_to_same_constant_as_plain_decimal() {
    let scientific = {
        let src = "fn main():\n    let x: f32 = 1e1\n    println(f\"{x}\")\n";
        let module = Driver::parse(src).expect("should parse");
        let typed = Driver::check(&module).expect("should type-check");
        let ir = Driver::codegen(&typed).expect("should codegen");
        extract_fn_body(&ir, "define i32 @main(").to_string()
    };
    let plain = {
        let src = "fn main():\n    let x: f32 = 10.0\n    println(f\"{x}\")\n";
        let module = Driver::parse(src).expect("should parse");
        let typed = Driver::check(&module).expect("should type-check");
        let ir = Driver::codegen(&typed).expect("should codegen");
        extract_fn_body(&ir, "define i32 @main(").to_string()
    };
    let extract_const = |body: &str| -> String {
        let idx = body.find("store float ").expect("expected a float store");
        body[idx..].splitn(2, ',').next().unwrap().to_string()
    };
    assert_eq!(extract_const(&scientific), extract_const(&plain), "scientific: {}\nplain: {}", scientific, plain);
}

// ===== Runtime end-to-end =====================================================

/// A realistic Nova-style overflow-guard check, written the way `cpu.star`'s
/// `op_exp`/`op_tan` now can: a scientific-notation `const` guard compared
/// against a value that legitimately overflows `f32` (spelled as another
/// scientific literal), and one that stays comfortably inside range.
#[test]
fn runtime_scientific_literal_overflow_guard_end_to_end() {
    let src = "const MATH_OVERFLOW_GUARD: f32 = 3.0e38\n\
               fn main():\n    \
               let overflowed: f32 = 1e40\n    \
               let in_range: f32 = 100.0\n    \
               println(f\"{overflowed > MATH_OVERFLOW_GUARD}\")\n    \
               println(f\"{in_range > MATH_OVERFLOW_GUARD}\")\n    \
               println(f\"{overflowed}\")\n";
    let output = compile_and_run("sci_overflow_guard", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "false", "inf"], "{}", stdout);
}

/// Scientific and plain-decimal spellings of the same magnitude are
/// interchangeable at runtime -- `1e1` and `10.0` must compare equal and
/// produce identical arithmetic results, confirming the exponent path is
/// genuinely just an alternate spelling with no divergent representation.
#[test]
fn runtime_scientific_and_decimal_literals_of_equal_value_are_interchangeable() {
    let src = "fn main():\n    \
               let a: f32 = 1e1\n    let b: f32 = 10.0\n    \
               println(f\"{a == b}\")\n    println(f\"{a + b}\")\n";
    let output = compile_and_run("sci_decimal_equivalence", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "20.000000"], "{}", stdout);
}

/// A negative-exponent literal (`1e-5`) is usable directly in arithmetic at
/// runtime, not just as a standalone value.
#[test]
fn runtime_negative_exponent_literal_arithmetic_end_to_end() {
    let src = "fn main():\n    let x: f32 = 1e-5\n    println(f\"{x * 100000.0}\")\n";
    let output = compile_and_run("sci_negative_exponent_arith", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim(), "1.000000");
}
