//! Bitwise/shift operator grammar (`todo.md` P0 #3): `& | ^ ~ << >>` as real
//! infix/prefix operators, not just the pre-existing `bit_get`/`bit_set`/
//! `bit_clear`/`bit_toggle`/`bit_and`/`bit_or`/`bit_xor`/`bit_not` free-
//! function surface (`tests/frontend_bitfield_flags.rs`). New lexer tokens
//! (`Amp`/`Pipe`/`Caret`/`Tilde`/`Shl`/`Shr` plus their `=`-suffixed compound-
//! assignment forms), new `BinOp::BitAnd`/`BitOr`/`BitXor`/`Shl`/`Shr` and
//! `UnOp::BitNot` AST variants, a new precedence tier in
//! `Parser::peek_binop`, and dedicated type-checking (`Checker::
//! infer_bitwise_combine_ty`/`infer_shift_ty`, `src/types/expr.rs`) and
//! codegen (`Codegen::emit_bitwise_binop`/`emit_shift_binop`,
//! `src/codegen/bitfield.rs`) dispatch that reuse the exact same `Ty::
//! bit_shape()`/`Ty::bitwise_combine_shape()` legality the free functions
//! already established.
//!
//! Adding real `<`/`>`-adjacent tokens (`<<`, `>>`) also reopened the classic
//! "nested generic closing bracket" ambiguity C++/Rust parsers hit
//! (`List<List<i32>>`'s trailing `>>` now lexes as one `Shr` token, not two
//! `Gt`s) -- `Parser::at_close_generic`/`eat_close_generic`/
//! `expect_close_generic` (`src/parser/mod.rs`) transparently split it back
//! apart, with a `split_gt_pending` flag (not a token-stream mutation) so
//! every existing speculative/backtracking turbofish parse
//! (`try_parse_type_args`/`parse_ring_new`/`parse_fixed_new`/
//! `parse_bitfield_new`/the `GenRef`/`Handle`/`Wrapping` probe) stays sound.
//! Several tests below are dedicated regressions for that split, not just
//! the operators themselves.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Lexer ================================================================

/// `&`/`|`/`^`/`~`/`<<`/`>>` each lex as their own distinct single token --
/// not confused with `&&`/`||` (which must still win when doubled) or with a
/// pair of separate `<`/`>` tokens.
#[test]
fn lexes_bitwise_and_shift_operator_tokens() {
    let src = "fn main():\n    let x = a & b | c ^ d << e >> f\n    let y = ~g\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert!(kinds.contains(&TokenKind::Amp), "{:?}", kinds);
    assert!(kinds.contains(&TokenKind::Pipe), "{:?}", kinds);
    assert!(kinds.contains(&TokenKind::Caret), "{:?}", kinds);
    assert!(kinds.contains(&TokenKind::Tilde), "{:?}", kinds);
    assert!(kinds.contains(&TokenKind::Shl), "{:?}", kinds);
    assert!(kinds.contains(&TokenKind::Shr), "{:?}", kinds);
    // None of the bitwise tokens should ever appear as a byproduct of
    // mis-scanning `&&`/`||`/comparisons.
    assert_eq!(kinds.iter().filter(|k| **k == TokenKind::AndAnd).count(), 0);
    assert_eq!(kinds.iter().filter(|k| **k == TokenKind::OrOr).count(), 0);
}

/// `&&`/`||` must still lex as one token each, not two `Amp`/`Pipe` tokens --
/// a regression guard for the two-char match table ordering now that `&`/`|`
/// are also legal single-char tokens.
#[test]
fn lexes_double_amp_and_pipe_as_logical_and_or_not_bitwise_pairs() {
    let src = "fn main():\n    let x = a && b || c\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert_eq!(kinds.iter().filter(|k| **k == TokenKind::AndAnd).count(), 1, "{:?}", kinds);
    assert_eq!(kinds.iter().filter(|k| **k == TokenKind::OrOr).count(), 1, "{:?}", kinds);
    assert_eq!(kinds.iter().filter(|k| **k == TokenKind::Amp).count(), 0, "{:?}", kinds);
    assert_eq!(kinds.iter().filter(|k| **k == TokenKind::Pipe).count(), 0, "{:?}", kinds);
}

/// `>>` lexes as a single `Shr` token in an ordinary expression context, not
/// two separate `Gt` tokens.
#[test]
fn lexes_shr_as_one_token_not_two_gt_tokens() {
    let src = "fn main():\n    let x = a >> b\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert_eq!(kinds.iter().filter(|k| **k == TokenKind::Shr).count(), 1, "{:?}", kinds);
    assert_eq!(kinds.iter().filter(|k| **k == TokenKind::Gt).count(), 0, "{:?}", kinds);
}

/// The five compound-assignment forms (`&=`, `|=`, `^=`, `<<=`, `>>=`) each
/// lex as one token -- in particular `<<=`/`>>=` must win over the shorter
/// `<<`/`>>` two-char match (the three-char lookahead added ahead of it).
#[test]
fn lexes_compound_assignment_bitwise_shift_tokens() {
    let src = "fn main():\n    a &= 1\n    b |= 2\n    c ^= 3\n    d <<= 4\n    e >>= 5\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert!(kinds.contains(&TokenKind::AmpEq), "{:?}", kinds);
    assert!(kinds.contains(&TokenKind::PipeEq), "{:?}", kinds);
    assert!(kinds.contains(&TokenKind::CaretEq), "{:?}", kinds);
    assert!(kinds.contains(&TokenKind::ShlEq), "{:?}", kinds);
    assert!(kinds.contains(&TokenKind::ShrEq), "{:?}", kinds);
    // Never split into `Shl`/`Shr` plus a trailing `Assign`.
    assert_eq!(kinds.iter().filter(|k| **k == TokenKind::Shl).count(), 0, "{:?}", kinds);
    assert_eq!(kinds.iter().filter(|k| **k == TokenKind::Shr).count(), 0, "{:?}", kinds);
}

// ===== Parser: precedence and AST shape ====================================

/// `&` binds tighter than `^`, which binds tighter than `|` -- `a & b ^ c |
/// d` must parse as `((a & b) ^ c) | d`, the same relative ordering C/Rust
/// give the three bitwise operators.
#[test]
fn parses_bitwise_precedence_and_over_xor_over_or() {
    let src = "fn main():\n    let x = a & b ^ c | d\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    let Expr::Binary { op: BinOp::BitOr, lhs, .. } = value else { panic!("outermost op should be `|`, got {:?}", value) };
    let Expr::Binary { op: BinOp::BitXor, lhs: xor_lhs, .. } = lhs.as_ref() else { panic!("next op should be `^`, got {:?}", lhs) };
    assert!(matches!(xor_lhs.as_ref(), Expr::Binary { op: BinOp::BitAnd, .. }), "innermost op should be `&`, got {:?}", xor_lhs);
}

/// `<<`/`>>` bind tighter than `&` -- `a & b << c` is `a & (b << c)`.
#[test]
fn parses_shift_binds_tighter_than_bitwise_and() {
    let src = "fn main():\n    let x = a & b << c\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    let Expr::Binary { op: BinOp::BitAnd, rhs, .. } = value else { panic!("outermost op should be `&`, got {:?}", value) };
    assert!(matches!(rhs.as_ref(), Expr::Binary { op: BinOp::Shl, .. }), "rhs should be `b << c`, got {:?}", rhs);
}

/// `<<`/`>>` bind looser than `+`/`-` -- `a + b << c` is `(a + b) << c`.
#[test]
fn parses_shift_binds_looser_than_additive() {
    let src = "fn main():\n    let x = a + b << c\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    let Expr::Binary { op: BinOp::Shl, lhs, .. } = value else { panic!("outermost op should be `<<`, got {:?}", value) };
    assert!(matches!(lhs.as_ref(), Expr::Binary { op: BinOp::Add, .. }), "lhs should be `a + b`, got {:?}", lhs);
}

/// Unary `~` binds tighter than any binary operator, matching `-`/`!`'s own
/// precedence -- `~a + 1` is `(~a) + 1`, not `~(a + 1)`.
#[test]
fn parses_unary_bitnot_binds_tighter_than_binary_ops() {
    let src = "fn main():\n    let x = ~a + 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    let Expr::Binary { op: BinOp::Add, lhs, .. } = value else { panic!("outermost op should be `+`, got {:?}", value) };
    assert!(matches!(lhs.as_ref(), Expr::Unary { op: UnOp::BitNot, .. }), "lhs should be `~a`, got {:?}", lhs);
}

/// Each of the five new compound-assignment operators parses as a
/// `Stmt::Assign` carrying the matching `AssignOp` variant.
#[test]
fn parses_compound_bitwise_shift_assignment_ops() {
    for (src_op, expect) in [
        ("&=", AssignOp::BitAnd),
        ("|=", AssignOp::BitOr),
        ("^=", AssignOp::BitXor),
        ("<<=", AssignOp::Shl),
        (">>=", AssignOp::Shr),
    ] {
        let src = format!("fn main():\n    a {} 1\n", src_op);
        let module = Driver::parse(&src).unwrap_or_else(|e| panic!("`{}` should parse: {:?}", src_op, e));
        let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
        let Stmt::Assign { op, .. } = &f.body.stmts[0] else { panic!("expected assign, got {:?}", f.body.stmts[0]) };
        assert_eq!(*op, expect, "operator `{}`", src_op);
    }
}

// ===== Parser: nested-generic `>>` splitting regressions ===================

/// `List<List<i32>>`'s trailing `>>` must still close both levels of
/// nesting, not get consumed whole as a shift operator.
#[test]
fn parses_doubly_nested_generic_type_annotation() {
    let src = "fn main():\n    let x: List<List<i32>> = List<List<i32>>()\n    println(f\"{x.len()}\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("should type-check");
}

/// Three levels deep (`List<List<List<i32>>>`) exercises the `Shr`+`Gt`
/// two-token split (`>>>` lexes as one `Shr` plus one trailing `Gt`), not
/// just the single-`Shr`-token two-level case above.
#[test]
fn parses_triply_nested_generic_type_annotation() {
    let src = "fn main():\n    let x: List<List<List<i32>>> = List<List<List<i32>>>()\n    println(f\"{x.len()}\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("should type-check");
}

/// A real end-to-end run confirming the nested-generic construction/`len()`
/// actually works, not just type-checks.
#[test]
fn runtime_nested_generic_list_end_to_end() {
    let src = "fn main():\n    let mut x: List<List<i32>> = List<List<i32>>()\n    let mut inner: List<i32> = List<i32>()\n    \
               inner.push(1)\n    inner.push(2)\n    x.push(inner)\n    println(f\"{x.len()}\")\n    println(f\"{x[0].len()}\")\n";
    let output = compile_and_run("bitwise_ops_nested_generic_list", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["1", "2"], "{}", stdout);
}

/// Regression for the `split_gt_pending` checkpoint/restore fix
/// (`Parser::try_parse_type_args`): a capitalized identifier followed by `<`
/// always speculatively attempts a turbofish parse first (`Foo < Bar >> 1`
/// looks exactly like the start of `Foo<Bar>(...)` until the parser sees
/// what follows the closing bracket isn't `(`/`::`). That speculative
/// attempt parses `Bar` as a type argument and then has to close it against
/// the `>>` that follows -- which means `eat_close_generic` flips
/// `split_gt_pending` on *before* the attempt is abandoned and backtracked.
/// If that flag weren't restored alongside `self.pos` on backtrack, it would
/// leak into the *next* real generic-closing bracket elsewhere in the same
/// file and silently eat one `>` too few. `List<List<i32>>` appearing later
/// in the same function is the canary: it must still close cleanly.
#[test]
fn runtime_abandoned_turbofish_speculation_does_not_corrupt_a_later_nested_generic_end_to_end() {
    let src = "fn main():\n    let Foo: i32 = 20\n    let Bar: i32 = 3\n    let r = Foo < Bar >> 1\n    println(f\"{r}\")\n    \
               let mut xs: List<List<i32>> = List<List<i32>>()\n    let mut inner: List<i32> = List<i32>()\n    inner.push(9)\n    \
               xs.push(inner)\n    println(f\"{xs.len()}\")\n    println(f\"{xs[0][0]}\")\n";
    let output = compile_and_run("bitwise_ops_turbofish_backtrack_then_nested_generic", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    // `Bar >> 1` == `3 >> 1` == 1; `Foo < 1` == `20 < 1` == false.
    assert_eq!(lines, vec!["false", "1", "9"], "{}", stdout);
}

// ===== Type-checking =========================================================

/// `&`/`|`/`^` require both operands to be the exact same type -- mismatched
/// integer widths are rejected, mirroring `bit_and`'s own free-function rule.
#[test]
fn rejects_bitand_between_mismatched_widths() {
    let src = "fn main():\n    let a: u8 = 1 as u8\n    let b: u16 = 1\n    let c = a & b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("operands must be the same type")), "{:?}", diags);
}

/// `&`/`|`/`^`/`~` reject a non-integer-shaped operand (e.g. `str`).
#[test]
fn rejects_bitwise_and_on_a_str_operand() {
    let src = "fn main():\n    let a: str = \"x\"\n    let b: str = \"y\"\n    let c = a & b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("left operand expected an integer")), "{:?}", diags);
}

/// The shift count (right operand) must be `int`, regardless of the left
/// operand's own type -- a `float`/`str`/mismatched-int count is rejected.
#[test]
fn rejects_shift_count_of_non_int_type() {
    let src = "fn main():\n    let a: i32 = 4\n    let b: f32 = 1.5\n    let c = a << b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("shift count) expected `int`")), "{:?}", diags);
}

/// `<<`/`>>` reject a non-integer-shaped left operand (e.g. `bool`).
#[test]
fn rejects_shift_on_a_bool_operand() {
    let src = "fn main():\n    let a: bool = true\n    let c = a << 1\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("left operand expected an integer")), "{:?}", diags);
}

/// `~` rejects a non-integer-shaped operand.
#[test]
fn rejects_bitnot_on_a_bool_operand() {
    let src = "fn main():\n    let a: bool = true\n    let b = ~a\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("`~` operand expected an integer")), "{:?}", diags);
}

/// `&`/`|`/`^` are shared with `Flags<E>`, the same as `bit_and`/`bit_or`/
/// `bit_xor` -- union/intersect/symmetric-difference of two valid masks
/// never gains an undefined bit, so it's safe to expose as operator syntax.
#[test]
fn accepts_bitwise_combine_ops_on_flags_type() {
    let src = "enum Dir:\n    Up\n    Down\n\nfn main():\n    let f: Flags<Dir> = Flags<Dir>(Dir::Up)\n    \
               let g: Flags<Dir> = Flags<Dir>(Dir::Down)\n    let h = f & g\n    let i = f | g\n    let j = f ^ g\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("`&`/`|`/`^` on Flags<E> should type-check");
}

/// Unlike `&`/`|`/`^`, `<<`/`>>` deliberately exclude `Flags<E>` -- shifting
/// a flag mask bit-by-bit isn't a meaningful set operation the way union/
/// intersect/symmetric-difference are (same exclusion `bit_not`/`bit_get`
/// already apply to `Flags<E>`).
#[test]
fn rejects_shift_on_a_flags_value() {
    let src = "enum Dir:\n    Up\n    Down\n\nfn main():\n    let f: Flags<Dir> = Flags<Dir>(Dir::Up)\n    let g = f << 1\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("left operand expected an integer")), "{:?}", diags);
}

/// `~` also excludes `Flags<E>`, for the same reason `<<`/`>>` do.
#[test]
fn rejects_bitnot_on_a_flags_value() {
    let src = "enum Dir:\n    Up\n    Down\n\nfn main():\n    let f: Flags<Dir> = Flags<Dir>(Dir::Up)\n    let g = ~f\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("`~` operand expected an integer")), "{:?}", diags);
}

/// `&`/`|`/`^`/`~`/`<<`/`>>` all also work on `Wrapping<T>`/`BitField<N>`,
/// the same `Ty::bit_shape()`/`bitwise_combine_shape()` set the free
/// functions already accept -- not just plain integer types.
#[test]
fn accepts_bitwise_and_shift_ops_on_wrapping_and_bitfield() {
    let src = "fn main():\n    let w: Wrapping<u8> = Wrapping<u8>(1 as u8)\n    let w2: Wrapping<u8> = Wrapping<u8>(2 as u8)\n    \
               let a = w & w2\n    let b = w | w2\n    let c = w ^ w2\n    let d = ~w\n    let e = w << 1\n    let f = w >> 1\n    \
               let bf: BitField<16> = BitField<16>(10)\n    let bf2: BitField<16> = BitField<16>(20)\n    \
               let g = bf & bf2\n    let h = ~bf\n    let i = bf << 2\n    let j = bf >> 2\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("bitwise/shift ops on Wrapping<T>/BitField<N> should type-check");
}

/// `Fixed<Bits,Frac>` has nothing resembling `&`/`|`/`^`/`~`/`<<`/`>>` to
/// offer (it isn't `Ty::bit_shape()`-having) -- rejected the same way `str`/
/// `bool` are, not silently accepted via some other numeric-looking path.
#[test]
fn rejects_bitwise_op_on_a_fixed_point_value() {
    let src = "fn main():\n    let a: Fixed<16,8> = Fixed<16,8>(1.0)\n    let b: Fixed<16,8> = Fixed<16,8>(2.0)\n    let c = a & b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("left operand expected an integer")), "{:?}", diags);
}

/// `a & b`/`a << b` both preserve the *left* operand's own type as the
/// result type (never the right operand's, which for a shift is always
/// `int` regardless of what's being shifted).
#[test]
fn bitwise_and_shift_result_type_matches_left_operand_type() {
    let src = "fn f(a: u8, b: u8) -> u8:\n    a & b\nfn main():\n    println(\"x\")\n";
    assert_eq!(typed_fn_result_ty(src), Ty::U8);

    let src2 = "fn f(a: u8, n: i32) -> u8:\n    a << n\nfn main():\n    println(\"x\")\n";
    assert_eq!(typed_fn_result_ty(src2), Ty::U8);
}

/// `~a` preserves the operand's own type too.
#[test]
fn bitnot_result_type_matches_operand_type() {
    let src = "fn f(a: i64) -> i64:\n    ~a\nfn main():\n    println(\"x\")\n";
    assert_eq!(typed_fn_result_ty(src), Ty::I64);
}

// ===== Codegen IR shape ======================================================

/// `&`/`|`/`^` lower directly to `and`/`or`/`xor` LLVM opcodes -- not a call
/// out to the `bit_and`/`bit_or`/`bit_xor` builtins (those still exist as a
/// separate call-based surface, but the operator spelling must never round-
/// trip through a function call it doesn't need).
#[test]
fn codegen_bitwise_combine_ops_lower_to_llvm_opcodes_not_calls() {
    let src = "fn main():\n    let a: i32 = 6\n    let b: i32 = 3\n    let c = a & b\n    let d = a | b\n    let e = a ^ b\n    \
               println(f\"{c}{d}{e}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let body = extract_fn_body(&ir, "define i32 @main(");
    assert!(body.contains("= and i32"), "{}", body);
    assert!(body.contains("= or i32"), "{}", body);
    assert!(body.contains("= xor i32"), "{}", body);
}

/// `>>` lowers to `ashr` for a signed left operand and `lshr` for unsigned
/// -- the actual arithmetic-vs-logical distinction, not just "some shift
/// opcode". `<<` uses the same `shl` opcode either way.
#[test]
fn codegen_shift_right_dispatches_ashr_for_signed_lshr_for_unsigned() {
    let src = "fn main():\n    let a: i32 = -8\n    let b: u32 = 8 as u32\n    let c = a >> 1\n    let d = b >> 1\n    let e = a << 1\n    \
               println(f\"{c}{d}{e}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let body = extract_fn_body(&ir, "define i32 @main(");
    assert!(body.contains("= ashr i32"), "signed `>>` should use ashr: {}", body);
    assert!(body.contains("= lshr i32"), "unsigned `>>` should use lshr: {}", body);
    assert!(body.contains("= shl i32"), "{}", body);
}

// ===== Runtime end-to-end ====================================================

/// `&`/`|`/`^`/`~` on plain `i32` values.
#[test]
fn runtime_bitwise_and_or_xor_not_end_to_end() {
    let src = "fn main():\n    let a: i32 = 12\n    let b: i32 = 10\n    println(f\"{a & b}\")\n    println(f\"{a | b}\")\n    \
               println(f\"{a ^ b}\")\n    println(f\"{~a}\")\n";
    let output = compile_and_run("bitwise_and_or_xor_not", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["8", "14", "6", "-13"], "{}", stdout);
}

/// `>>` is arithmetic (sign-extending) on a signed type, logical (zero-
/// filling) on unsigned -- the same bit pattern shifted two different ways.
#[test]
fn runtime_shift_right_arithmetic_vs_logical_end_to_end() {
    let src = "fn main():\n    let neg: i32 = -8\n    println(f\"{neg >> 1}\")\n    let pos: u32 = neg as u32\n    println(f\"{pos >> 1}\")\n";
    let output = compile_and_run("shift_right_arith_vs_logical", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["-4", "2147483644"], "{}", stdout);
}

/// A shift amount `>=` the operand's own width is masked mod width, matching
/// x86 hardware `SHL`/`SHR` semantics (and `bit_get`'s own existing masked-
/// index precedent) instead of being an LLVM poison value.
#[test]
fn runtime_shift_amount_masks_mod_width_end_to_end() {
    let src = "fn main():\n    let a: i32 = 1\n    println(f\"{a << 33}\")\n    let b: u8 = 1 as u8\n    println(f\"{b << 9}\")\n";
    let output = compile_and_run("shift_amount_masks_mod_width", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    // 33 mod 32 == 1, so `1 << 33` == `1 << 1` == 2; 9 mod 8 == 1, so
    // `1u8 << 9` == `1u8 << 1` == 2.
    assert_eq!(lines, vec!["2", "2"], "{}", stdout);
}

/// The five compound-assignment forms (`&=`, `|=`, `^=`, `<<=`, `>>=`)
/// mutate in place with the correct semantics.
#[test]
fn runtime_compound_bitwise_shift_assignment_end_to_end() {
    let src = "fn main():\n    let mut x: i32 = 6\n    x &= 3\n    println(f\"{x}\")\n    x |= 8\n    println(f\"{x}\")\n    \
               x ^= 5\n    println(f\"{x}\")\n    x <<= 2\n    println(f\"{x}\")\n    x >>= 1\n    println(f\"{x}\")\n";
    let output = compile_and_run("compound_bitwise_shift_assign", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["2", "10", "15", "60", "30"], "{}", stdout);
}

/// A compound shift assignment on a target narrower than `int` (`u8 <<=`)
/// exercises the "rhs is always `int`, independent of the target's own
/// type" special case in `Checker::check_stmt`'s `Stmt::Assign` arm (the
/// generic `types_compatible` gate every other compound op uses would
/// otherwise wrongly reject this, since `int != u8`).
#[test]
fn runtime_compound_shift_assignment_on_narrow_target_type_end_to_end() {
    let src = "fn main():\n    let mut reg: u8 = 1 as u8\n    reg <<= 4\n    println(f\"{reg}\")\n";
    let output = compile_and_run("compound_shift_assign_narrow_target", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "16");
}

/// Operator precedence end to end (not just at the AST-shape level): mixed
/// `|`/`&`/`^`/`<<`/`>>` expressions evaluate with the real C-family
/// precedence, not left-to-right or some other grouping.
#[test]
fn runtime_operator_precedence_end_to_end() {
    let src = "fn main():\n    println(f\"{1 | 2 & 3}\")\n    println(f\"{4 ^ 2 | 1}\")\n    println(f\"{1 << 2 + 1}\")\n    \
               println(f\"{8 >> 1 & 3}\")\n";
    let output = compile_and_run("bitwise_operator_precedence", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    // `1 | (2 & 3)` == 3; `(4 ^ 2) | 1` == 7; `1 << (2 + 1)` == 8;
    // `(8 >> 1) & 3` == 0.
    assert_eq!(lines, vec!["3", "7", "8", "0"], "{}", stdout);
}

/// `const MASK: i32 = 1 << 3` -- shift/bitwise ops fold at compile time in a
/// top-level `const` initializer, not just as a runtime instruction.
#[test]
fn runtime_const_bitwise_and_shift_expression_end_to_end() {
    let src = "const MASK: i32 = 1 << 3\nconst COMBINED: i32 = MASK | 1\nfn main():\n    println(f\"{MASK}\")\n    println(f\"{COMBINED}\")\n";
    let output = compile_and_run("const_bitwise_shift_expr", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["8", "9"], "{}", stdout);
}

/// `~(~x) == x` -- a double bitwise-not round trip.
#[test]
fn runtime_double_bitnot_round_trips_end_to_end() {
    let src = "fn main():\n    let a: i32 = 12345\n    println(f\"{~(~a) == a}\")\n";
    let output = compile_and_run("double_bitnot_round_trip", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "true");
}

/// `&`/`|`/`^`/`<<`/`>>` on `Wrapping<u8>`/`BitField<16>` values, and on
/// `i64` (a width other than the default `i32`) -- width/type coverage
/// beyond the plain-`i32` cases above.
#[test]
fn runtime_bitwise_and_shift_on_wrapping_bitfield_and_i64_end_to_end() {
    let src = "fn main():\n    let c: i64 = 123456789012 as i64\n    let d: i64 = 987654321098 as i64\n    println(f\"{c ^ d}\")\n    \
               let w: Wrapping<u8> = Wrapping<u8>(200 as u8)\n    let w2: Wrapping<u8> = Wrapping<u8>(170 as u8)\n    \
               println(f\"{w & w2}\")\n    let bf: BitField<16> = BitField<16>(1000)\n    println(f\"{bf << 2}\")\n    \
               println(f\"{bf >> 3}\")\n";
    let output = compile_and_run("bitwise_shift_wrapping_bitfield_i64", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["1070693738974", "136", "4000", "125"], "{}", stdout);
}

/// A realistic Nova-style use case: an 8-bit rotate-left built entirely out
/// of the new operators (`<<`/`>>`/`|`), the exact "general shift by N
/// primitive" `todo.md` P0 #3 cites as missing (Nova's `bits.star` had to
/// hand-build this bit-by-bit before).
#[test]
fn runtime_rotate_left_8_built_from_shift_and_or_operators_end_to_end() {
    let src = "fn rotate_left_8(x: u8, n: i32) -> u8:\n    return (x << n) | (x >> (8 - n))\n\n\
               fn main():\n    let v: u8 = 129 as u8\n    println(f\"{rotate_left_8(v, 1)}\")\n";
    let output = compile_and_run("rotate_left_8_operators", src);
    assert!(output.status.success(), "{:?}", output.status);
    // 129 == 0b10000001; rotated left by 1 == 0b00000011 == 3.
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "3");
}
