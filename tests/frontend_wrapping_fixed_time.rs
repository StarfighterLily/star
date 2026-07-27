//! `Wrapping<T>` / `Fixed<Bits,Frac>` and `Tick`/`Duration`/`Instant`
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== `Wrapping<T>` / `Fixed<Bits, Frac>` (docs/design.md §2) =============

/// `Wrapping<u8>` silently wraps 250 + 10 -> 4, unlike a plain `u8` (which
/// would trap -- see `runtime_u8_add_overflow_traps_end_to_end`).
#[test]
fn runtime_wrapping_u8_add_overflow_wraps_silently_end_to_end() {
    let src = "fn main():\n    let a: Wrapping<u8> = Wrapping<u8>(250 as u8)\n    let b: Wrapping<u8> = Wrapping<u8>(10 as u8)\n    println(f\"{a + b}\")\n";
    let output = compile_and_run("wrapping_u8_add", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "4");
}

/// Signed wraparound: `i8::MAX + 1` wraps to `i8::MIN`.
#[test]
fn runtime_wrapping_i8_add_overflow_wraps_to_min_end_to_end() {
    let src = "fn main():\n    let a: Wrapping<i8> = Wrapping<i8>(127 as i8)\n    let b: Wrapping<i8> = Wrapping<i8>(1 as i8)\n    println(f\"{a + b}\")\n";
    let output = compile_and_run("wrapping_i8_add", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "-128");
}

/// `Wrapping<i8>` subtraction/multiplication wrap too, not just addition.
#[test]
fn runtime_wrapping_sub_and_mul_wrap_silently_end_to_end() {
    let src = "fn main():\n    let a: Wrapping<i8> = Wrapping<i8>(-128 as i8)\n    let b: Wrapping<i8> = Wrapping<i8>(1 as i8)\n    println(f\"{a - b}\")\n    \
               let c: Wrapping<u8> = Wrapping<u8>(200 as u8)\n    let d: Wrapping<u8> = Wrapping<u8>(2 as u8)\n    println(f\"{c * d}\")\n";
    let output = compile_and_run("wrapping_sub_mul", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["127", "144"], "{}", stdout);
}

/// A zero divisor still traps on `Wrapping<T>` -- division-by-zero isn't
/// "overflow" (matches Rust's own `Wrapping<T>`, and every other integer
/// division in this compiler).
#[test]
fn runtime_wrapping_division_by_zero_still_traps_end_to_end() {
    let src = "fn main():\n    println(\"before\")\n    let a: Wrapping<i32> = Wrapping<i32>(10)\n    let b: Wrapping<i32> = Wrapping<i32>(0)\n    \
               let x = a / b\n    println(f\"unreachable {x}\")\n";
    let output = compile_and_run("wrapping_div_zero", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(stdout.contains("integer `/` by zero"), "should print a diagnostic: {}", stdout);
    assert!(!stdout.contains("unreachable"), "the div must abort before its value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

/// The one true overflow case in signed division -- `MIN / -1` -- wraps to
/// `MIN` instead of trapping (unlike a plain `i32`'s own division guard).
#[test]
fn runtime_wrapping_i32_min_div_neg_one_wraps_instead_of_trapping_end_to_end() {
    let src = "fn main():\n    let a: Wrapping<i32> = Wrapping<i32>(-2147483648)\n    let b: Wrapping<i32> = Wrapping<i32>(-1)\n    println(f\"{a / b}\")\n    \
               println(f\"{a % b}\")\n";
    let output = compile_and_run("wrapping_min_div_neg1", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["-2147483648", "0"], "{}", stdout);
}

/// `Wrapping<T> as T` is a free bit-preserving relabel back to the plain
/// integer type.
#[test]
fn runtime_wrapping_cast_round_trip_end_to_end() {
    let src = "fn main():\n    let a: Wrapping<u8> = Wrapping<u8>(250 as u8)\n    let b: Wrapping<u8> = Wrapping<u8>(10 as u8)\n    \
               let wrapped = a + b\n    let plain: u8 = wrapped as u8\n    println(f\"{plain}\")\n";
    let output = compile_and_run("wrapping_cast_roundtrip", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "4");
}

#[test]
fn rejects_wrapping_of_a_non_integer_type() {
    let src = "fn main():\n    let a = Wrapping<Vec3>(Vec3(0, 0, 0))\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("`Wrapping<T>` requires `T` to be an integer type")), "{:?}", diags);
}

#[test]
fn rejects_binop_between_mismatched_wrapping_types() {
    let src = "fn main():\n    let a: Wrapping<u8> = Wrapping<u8>(1 as u8)\n    let b: Wrapping<i32> = Wrapping<i32>(1)\n    let c = a + b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("mismatched types")), "{:?}", diags);
}

/// `Fixed<32,16>` (Q16.16) construction from both a float literal (scaled)
/// and a plain int (exact `shl`), plus all four arithmetic operators.
#[test]
fn runtime_fixed_32_16_arithmetic_end_to_end() {
    let src = "fn main():\n    let a: Fixed<32, 16> = Fixed<32, 16>(3.5)\n    let b: Fixed<32, 16> = Fixed<32, 16>(2.0)\n    \
               println(f\"{a + b}\")\n    println(f\"{a - b}\")\n    println(f\"{a * b}\")\n    println(f\"{a / b}\")\n    \
               let whole: Fixed<32, 16> = Fixed<32, 16>(10)\n    println(f\"{whole}\")\n";
    let output = compile_and_run("fixed_32_16_arith", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["5.500000", "1.500000", "7.000000", "1.750000", "10.000000"], "{}", stdout);
}

/// A narrower `Fixed<8,4>` (Q3.4) exercises the same `i128`-widening
/// multiply/divide path at a much smaller width -- 3.5 * 1.5 = 5.25 is exact
/// at this precision.
#[test]
fn runtime_fixed_8_4_multiply_end_to_end() {
    let src = "fn main():\n    let a: Fixed<8, 4> = Fixed<8, 4>(3.5)\n    let b: Fixed<8, 4> = Fixed<8, 4>(1.5)\n    println(f\"{a * b}\")\n";
    let output = compile_and_run("fixed_8_4_mul", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "5.250000");
}

#[test]
fn runtime_fixed_comparisons_end_to_end() {
    let src = "fn main():\n    let a: Fixed<32, 16> = Fixed<32, 16>(3.5)\n    let b: Fixed<32, 16> = Fixed<32, 16>(10)\n    \
               println(f\"{a < b} {a > b} {a == a}\")\n";
    let output = compile_and_run("fixed_compare", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "true false true");
}

/// `Fixed<Bits,Frac> as f32` is a true scaled conversion (not a bit
/// reinterpret) -- round-trips back to the original float value.
#[test]
fn runtime_fixed_to_float_cast_round_trip_end_to_end() {
    let src = "fn main():\n    let a: Fixed<32, 16> = Fixed<32, 16>(3.5)\n    let back: f32 = a as f32\n    println(f\"{back}\")\n";
    let output = compile_and_run("fixed_to_float", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "3.500000");
}

/// A zero divisor traps on `Fixed<Bits,Frac>` division, same as any other
/// integer division in this compiler.
#[test]
fn runtime_fixed_division_by_zero_traps_end_to_end() {
    let src = "fn main():\n    println(\"before\")\n    let a: Fixed<32, 16> = Fixed<32, 16>(10.0)\n    let b: Fixed<32, 16> = Fixed<32, 16>(0.0)\n    \
               let x = a / b\n    println(f\"unreachable {x}\")\n";
    let output = compile_and_run("fixed_div_zero", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(stdout.contains("division by zero"), "should print a diagnostic: {}", stdout);
    assert!(!stdout.contains("unreachable"), "the div must abort before its value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

/// A multiplication whose result doesn't fit the narrow `Bits` width traps
/// rather than silently truncating -- deterministic-but-wrong is worse than
/// a loud abort for a type whose entire purpose is deterministic math.
#[test]
fn runtime_fixed_multiplication_overflow_traps_end_to_end() {
    let src = "fn main():\n    println(\"before\")\n    let a: Fixed<8, 4> = Fixed<8, 4>(7.0)\n    let b: Fixed<8, 4> = Fixed<8, 4>(7.0)\n    \
               let x = a * b\n    println(f\"unreachable {x}\")\n";
    let output = compile_and_run("fixed_mul_overflow", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(stdout.contains("multiplication overflow"), "should print a diagnostic: {}", stdout);
    assert!(!stdout.contains("unreachable"), "the mul must abort before its value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

#[test]
fn rejects_percent_operator_on_fixed_values() {
    let src = "fn main():\n    let a: Fixed<32, 16> = Fixed<32, 16>(1.0)\n    let b: Fixed<32, 16> = Fixed<32, 16>(2.0)\n    let c = a % b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("`%` is not supported on `Fixed")), "{:?}", diags);
}

#[test]
fn rejects_fixed_with_an_unsupported_bit_width() {
    let src = "fn main():\n    let a: Fixed<7, 3> = Fixed<7, 3>(1.0)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("bit width must be one of 8, 16, 32, 64")), "{:?}", diags);
}

#[test]
fn rejects_fixed_with_frac_not_less_than_bits() {
    let src = "fn main():\n    let a: Fixed<32, 32> = Fixed<32, 32>(1.0)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("fractional-bit count must be less than its bit width")), "{:?}", diags);
}

// ===== `Tick` / `Duration` / `Instant` (docs/design.md §6, "Time") =========

/// `Tick + i64 -> Tick` (advance by a step count) and `Tick - Tick -> i64`
/// (a tick delta) -- see `examples/time_types.star`.
#[test]
fn runtime_tick_advance_and_delta_end_to_end() {
    let src = "fn main():\n    let start: Tick = Tick(0)\n    let mut t = start\n    let mut i: i32 = 0\n    \
               while i < 5:\n        t = t + (1 as i64)\n        i += 1\n    \
               println(f\"{t}\")\n    let delta: i64 = t - start\n    println(f\"{delta}\")\n";
    let output = compile_and_run("tick_advance_delta", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.lines().collect::<Vec<_>>(), vec!["5", "5"], "{}", stdout);
}

/// `Duration + Duration -> Duration`, `Duration - Duration -> Duration`, and
/// comparisons between two `Duration`s.
#[test]
fn runtime_duration_add_sub_and_compare_end_to_end() {
    let src = "fn main():\n    let budget: Duration = Duration(1000 as i64)\n    let total = budget + budget\n    \
               println(f\"{total}\")\n    let remaining = total - budget\n    println(f\"{remaining}\")\n    \
               println(f\"{budget < total} {budget == remaining}\")\n";
    let output = compile_and_run("duration_add_sub_cmp", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.lines().collect::<Vec<_>>(), vec!["2000", "1000", "true true"], "{}", stdout);
}

/// `Instant - Instant -> Duration` (elapsed time) and `Instant +/- Duration
/// -> Instant`, mirroring Rust's own `std::time::Instant` operator set.
#[test]
fn runtime_instant_diff_and_shift_end_to_end() {
    let src = "fn main():\n    let t0: Instant = Instant(1000 as i64)\n    let t1: Instant = Instant(2500 as i64)\n    \
               let gap: Duration = t1 - t0\n    println(f\"{gap}\")\n    \
               let shifted = t0 + gap\n    println(f\"{shifted == t1}\")\n    \
               let rewound = t1 - gap\n    println(f\"{rewound == t0}\")\n";
    let output = compile_and_run("instant_diff_shift", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.lines().collect::<Vec<_>>(), vec!["1500", "true", "true"], "{}", stdout);
}

/// `Tick`/`Duration`/`Instant` <-> `i64` is a free bit-preserving relabel,
/// same as `Wrapping<T> <-> T` -- see `runtime_wrapping_cast_round_trip_end_to_end`.
#[test]
fn runtime_time_cast_round_trip_end_to_end() {
    let src = "fn main():\n    let a: Duration = Duration(4242 as i64)\n    let raw: i64 = a as i64\n    \
               let back: Duration = raw as Duration\n    println(f\"{raw} {back == a}\")\n";
    let output = compile_and_run("time_cast_roundtrip", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "4242 true");
}

/// `+`/`-` on `Tick`/`Duration`/`Instant` trap on `i64` overflow, exactly
/// like a plain `i64` -- see `runtime_wrapping_...` for the general pattern
/// this mirrors (minus the wrap).
#[test]
fn runtime_duration_add_overflow_traps_end_to_end() {
    let src = "fn main():\n    println(\"before\")\n    let a: Duration = Duration(9223372036854775807 as i64)\n    let b: Duration = Duration(1 as i64)\n    \
               let x = a + b\n    println(f\"unreachable {x}\")\n";
    let output = compile_and_run("duration_add_overflow", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(stdout.contains("integer overflow"), "should print a diagnostic: {}", stdout);
    assert!(!stdout.contains("unreachable"), "the add must abort before its value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

#[test]
fn rejects_binop_between_tick_and_duration() {
    let src = "fn main():\n    let a: Tick = Tick(0)\n    let b: Duration = Duration(0 as i64)\n    let c = a + b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("`+` is not supported between `Tick` and `Duration`")), "{:?}", diags);
}

/// `Tick + Tick` isn't a legal pairing (only `Tick + i64` is, per
/// `Checker::infer_time_binop_ty`'s table) -- unlike `Duration + Duration`,
/// summing two absolute tick counts has no sensible meaning.
#[test]
fn rejects_tick_plus_tick() {
    let src = "fn main():\n    let a: Tick = Tick(0)\n    let b: Tick = Tick(1)\n    let c = a + b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("`+` is not supported between `Tick` and `Tick`")), "{:?}", diags);
}

#[test]
fn rejects_time_construction_with_wrong_arg_count() {
    let src = "fn main():\n    let a = Tick(0, 1)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("Tick(..) expects 1 integer argument")), "{:?}", diags);
}

#[test]
fn rejects_time_construction_with_non_integer_arg() {
    let src = "fn main():\n    let a = Duration(1.5)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("Duration(..) expects 1 integer argument")), "{:?}", diags);
}

#[test]
fn rejects_multiply_on_duration_values() {
    let src = "fn main():\n    let a: Duration = Duration(1 as i64)\n    let b: Duration = Duration(2 as i64)\n    let c = a * b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("`*` is not supported between `Duration` and `Duration`")), "{:?}", diags);
}

/// Reflection metadata spells these fields by their own names, not their
/// bare `i64` backing representation -- see `Codegen::reflect_type_name`.
#[test]
fn reflect_metadata_names_time_types_distinctly_from_i64() {
    let src = "struct Clock:\n    @export t: Tick\n    @export d: Duration\n    @export i: Instant\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("t:0:Tick:export"), "{}", ir);
    assert!(ir.contains("d:8:Duration:export"), "{}", ir);
    assert!(ir.contains("i:16:Instant:export"), "{}", ir);
}

// ===== todo.md P2 #7: binop-dispatch unification (arithmetic-bearing types)
//
// `Wrapping<T>`/`Fixed<Bits,Frac>` are folded into one shared exact-type-
// match branch in `Checker::infer_binop_ty` (see that function's own doc
// comment for the full reasoning); `Tick`/`Duration`/`Instant` deliberately
// stay in their own dedicated `infer_time_binop_ty` table because their
// legal pairings are asymmetric per operator (`Tick + i64 -> Tick` but
// `Tick + Tick` is illegal; `Instant - Instant -> Duration` but `Instant +
// Instant` is illegal). The tests above already cover the "happy path" for
// both families end to end; the tests below close the remaining gaps this
// dispatch decision specifically hinges on: comparisons (not just
// arithmetic) sharing the same-type-match rule, the two families correctly
// rejecting each other despite being adjacent in the same source branch, and
// asymmetric pairings/operators the existing tests didn't already exercise
// for all three time types. ========================================

/// `Wrapping<T>` supports the full six-operator comparison set, not just
/// arithmetic -- the shared branch's `is_cmp` handling must return `bool`
/// for a same-type pair exactly like `Ty::Fixed`'s own comparison test
/// (`runtime_fixed_comparisons_end_to_end`) already covers for that sibling
/// type.
#[test]
fn runtime_wrapping_equality_and_ordering_end_to_end() {
    let src = "fn main():\n    let a: Wrapping<i32> = Wrapping<i32>(3)\n    let b: Wrapping<i32> = Wrapping<i32>(7)\n    \
               println(f\"{a == a} {a != b} {a < b} {b > a} {a <= a} {b >= a}\")\n";
    let output = compile_and_run("wrapping_eq_ord", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "true true true true true true");
}

/// The shared branch threads each `Wrapping<T>`'s own signedness through to
/// its comparison opcode (`slt`/`ult`) rather than defaulting to one or the
/// other -- `Wrapping<i8>(-1) < Wrapping<i8>(1)` is `true` under a signed
/// compare, but the same two bit patterns reinterpreted as `Wrapping<u8>`
/// (`255`/`1`) are `false` under an unsigned compare. A dispatch bug that
/// hardcoded (or dropped) the signedness flag would still type-check and
/// only surface here, at runtime.
#[test]
fn runtime_wrapping_signed_vs_unsigned_ordering_end_to_end() {
    let src = "fn main():\n    let a: Wrapping<i8> = Wrapping<i8>(-1 as i8)\n    let b: Wrapping<i8> = Wrapping<i8>(1 as i8)\n    println(f\"{a < b}\")\n    \
               let c: Wrapping<u8> = Wrapping<u8>(255 as u8)\n    let d: Wrapping<u8> = Wrapping<u8>(1 as u8)\n    println(f\"{c < d}\")\n";
    let output = compile_and_run("wrapping_signed_unsigned_ord", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.lines().collect::<Vec<_>>(), vec!["true", "false"], "{}", stdout);
}

/// `Wrapping<T>` and `Fixed<Bits,Frac>` sit right next to each other in the
/// same shared branch of `Checker::infer_binop_ty` -- a binop between one of
/// each must still fall through to the generic "mismatched types" diagnostic
/// (same as two different-width `Wrapping`s or two different-shape `Fixed`s
/// would), not be silently accepted just because both sides matched the
/// branch's outer `Wrapping(_) | Fixed(..)` guard.
#[test]
fn rejects_binop_between_wrapping_and_fixed() {
    let src = "fn main():\n    let a: Wrapping<i32> = Wrapping<i32>(1)\n    let b: Fixed<32, 16> = Fixed<32, 16>(1.0)\n    let c = a + b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("mismatched types") && d.message.contains("use `as` to cast")), "{:?}", diags);
}

/// `Fixed<Bits,Frac>` against its own bare backing-shaped operand (a plain
/// `int`) must still require an explicit `as`, the same "no implicit
/// anything" rule the shared branch enforces between two different
/// `Wrapping<T>` widths (`rejects_binop_between_mismatched_wrapping_types`).
#[test]
fn rejects_binop_between_fixed_and_bare_int() {
    let src = "fn main():\n    let a: Fixed<32, 16> = Fixed<32, 16>(1.0)\n    let b: int = 2\n    let c = a + b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("mismatched types") && d.message.contains("use `as` to cast")), "{:?}", diags);
}

/// The shared branch's mismatch check applies uniformly to comparisons, not
/// just arithmetic -- `Wrapping<u8> < Wrapping<i32>` must be rejected the
/// same way `Wrapping<u8> + Wrapping<i32>` already is
/// (`rejects_binop_between_mismatched_wrapping_types` only covers `+`).
#[test]
fn rejects_wrapping_comparison_between_mismatched_widths() {
    let src = "fn main():\n    let a: Wrapping<u8> = Wrapping<u8>(1 as u8)\n    let b: Wrapping<i32> = Wrapping<i32>(1)\n    let c = a < b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("mismatched types")), "{:?}", diags);
}

/// `Tick`/`Tick` supports the full comparison set (`infer_time_binop_ty`'s
/// `is_cmp && lhs_ty == rhs_ty` rule), not just the `Tick - Tick -> i64`
/// delta arithmetic the existing `runtime_tick_advance_and_delta_end_to_end`
/// test covers -- companion to `runtime_duration_add_sub_and_compare_end_to_end`
/// (`Duration`) and the `Instant` equality already checked in
/// `runtime_instant_diff_and_shift_end_to_end`, closing the last of the three
/// types' comparison coverage.
#[test]
fn runtime_tick_ordering_end_to_end() {
    let src = "fn main():\n    let a: Tick = Tick(3)\n    let b: Tick = Tick(7)\n    println(f\"{a < b} {b > a} {a == a} {a != b}\")\n";
    let output = compile_and_run("tick_ordering", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "true true true true");
}

/// The asymmetry that keeps `Tick`/`Duration`/`Instant` out of the shared
/// `Wrapping`/`Fixed` branch: `Tick + i64 -> Tick` is legal (already tested
/// via `runtime_tick_advance_and_delta_end_to_end`), but `Tick < i64` is not
/// -- comparisons require an exact same-type pair per
/// `infer_time_binop_ty`'s `is_cmp` rule, unlike its `Add`/`Sub` arm which
/// explicitly allows a bare `i64` on the other side.
#[test]
fn rejects_tick_comparison_against_i64() {
    let src = "fn main():\n    let a: Tick = Tick(0)\n    let b: i64 = 1 as i64\n    let c = a < b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("`<` is not supported between `Tick` and `I64`")), "{:?}", diags);
}

/// `Instant - Instant -> Duration` is legal (per
/// `runtime_instant_diff_and_shift_end_to_end`), but `Instant + Instant` has
/// no entry in `infer_time_binop_ty`'s table at all -- summing two absolute
/// timestamps is meaningless, the same reasoning `rejects_tick_plus_tick`
/// already covers for `Tick`.
#[test]
fn rejects_instant_plus_instant() {
    let src = "fn main():\n    let a: Instant = Instant(0 as i64)\n    let b: Instant = Instant(1 as i64)\n    let c = a + b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("`+` is not supported between `Instant` and `Instant`")), "{:?}", diags);
}

/// `Tick - Duration` has no entry in `infer_time_binop_ty`'s table (only
/// `Tick - Tick`/`Tick - i64` subtract from a `Tick`) -- companion to
/// `rejects_binop_between_tick_and_duration` (which covers `+`), closing the
/// same mismatched-family gap for `-`.
#[test]
fn rejects_tick_minus_duration() {
    let src = "fn main():\n    let a: Tick = Tick(0)\n    let b: Duration = Duration(1 as i64)\n    let c = a - b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("`-` is not supported between `Tick` and `Duration`")), "{:?}", diags);
}

/// `*`/`/`/`%` are illegal on `Tick`, the same as `rejects_multiply_on_
/// duration_values` already covers for `Duration` -- closes the matching gap
/// for `Tick` specifically (advancing a tick count by scaling it has no
/// sensible meaning any more than summing two of them does).
#[test]
fn rejects_tick_division() {
    let src = "fn main():\n    let a: Tick = Tick(10)\n    let b: Tick = Tick(2)\n    let c = a / b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("`/` is not supported between `Tick` and `Tick`")), "{:?}", diags);
}

/// Same "no `*`/`/`/`%`" rule as `rejects_tick_division`, exercised for
/// `Instant` (the third of the three time types) with `%` specifically.
#[test]
fn rejects_instant_modulo() {
    let src = "fn main():\n    let a: Instant = Instant(10 as i64)\n    let b: Instant = Instant(3 as i64)\n    let c = a % b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("`%` is not supported between `Instant` and `Instant`")), "{:?}", diags);
}
