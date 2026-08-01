//! Inclusive (`..=`) and stepped (`step <n>`) `for`-loop ranges
//! (`docs/requests.md` #4) -- parser (`Stmt::For::inclusive`/`::step`),
//! checker passthrough, and `Codegen::emit_for_stmt`'s comparison-predicate
//! selection. Shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Parsing ===============================================================

/// The original exclusive, implicit-step-1 form is unaffected.
#[test]
fn parses_plain_exclusive_range() {
    let src = "fn t():\n    for i in 0..10:\n        break\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::For { inclusive, step, .. } = &f.body.stmts[0] else { panic!("expected For") };
    assert!(!inclusive);
    assert_eq!(*step, None);
}

/// `..=` parses as an inclusive range.
#[test]
fn parses_inclusive_range() {
    let src = "fn t():\n    for i in 0..=10:\n        break\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::For { inclusive, step, .. } = &f.body.stmts[0] else { panic!("expected For") };
    assert!(inclusive);
    assert_eq!(*step, None);
}

/// A positive `step` clause on an exclusive range.
#[test]
fn parses_step_clause() {
    let src = "fn t():\n    for i in 0..10 step 2:\n        break\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::For { inclusive, step, .. } = &f.body.stmts[0] else { panic!("expected For") };
    assert!(!inclusive);
    assert_eq!(*step, Some(2));
}

/// A negative `step` clause (descending range), combined with `..=`.
#[test]
fn parses_negative_step_with_inclusive_range() {
    let src = "fn t():\n    for i in 10..=0 step -1:\n        break\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::For { inclusive, step, .. } = &f.body.stmts[0] else { panic!("expected For") };
    assert!(inclusive);
    assert_eq!(*step, Some(-1));
}

/// `step 0` is rejected at parse time (an infinite loop the counter can
/// never escape).
#[test]
fn rejects_step_zero() {
    let src = "fn t():\n    for i in 0..10 step 0:\n        break\n";
    assert!(Driver::parse(src).is_err(), "`step 0` should be a parse error");
}

/// `step` with no integer literal following is a parse error, not a panic.
#[test]
fn rejects_step_without_literal() {
    let src = "fn t():\n    for i in 0..10 step:\n        break\n";
    assert!(Driver::parse(src).is_err());
}

/// `step` still works as an ordinary identifier (method/variable name)
/// elsewhere -- it's a soft keyword recognized only right after a `for`
/// loop's range, not reserved globally (`projects/nova/cpu.star` has a real
/// `fn step(mut self):` method that must keep working).
#[test]
fn step_still_usable_as_an_identifier_elsewhere() {
    let src = "struct Cpu:\n    mut pc: i32\n\nimpl Cpu:\n    fn step(mut self):\n        self.pc += 1\n\nfn main():\n    let mut c = Cpu(pc = 0)\n    c.step()\n    let step = 5\n    println(f\"{step}\")\n";
    let module = Driver::parse(src).expect("`step` as an identifier should still parse");
    Driver::check(&module).expect("`step` as an identifier should still type-check");
}

// ===== Type-checking ==========================================================

/// An inclusive/stepped `for` loop still requires `i32` bounds, same as the
/// plain exclusive form.
#[test]
fn rejects_non_int_bound_with_inclusive_range() {
    let src = "fn t():\n    for i in \"a\"..=10:\n        break\n";
    assert!(Driver::check(&Driver::parse(src).expect("should parse")).is_err());
}

// ===== Runtime: inclusive range ==============================================

/// `0..=5` visits `0,1,2,3,4,5` -- one more iteration than the exclusive form.
#[test]
fn runtime_inclusive_range_includes_endpoint_end_to_end() {
    let src = "fn main():\n    let mut sum = 0\n    for i in 0..=5:\n        sum += i\n    println(f\"{sum}\")\n";
    let output = compile_and_run("for_inclusive_sum", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "15"); // 0+1+2+3+4+5
}

/// A single-element inclusive range (`5..=5`) runs exactly once.
#[test]
fn runtime_inclusive_range_single_element_end_to_end() {
    let src = "fn main():\n    let mut count = 0\n    for i in 5..=5:\n        count += 1\n    println(f\"{count}\")\n";
    let output = compile_and_run("for_inclusive_single", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "1");
}

/// The plain exclusive form is bit-for-bit unchanged: `0..5` still runs 5
/// times, not 6.
#[test]
fn runtime_exclusive_range_still_excludes_endpoint_end_to_end() {
    let src = "fn main():\n    let mut count = 0\n    for i in 0..5:\n        count += 1\n    println(f\"{count}\")\n";
    let output = compile_and_run("for_exclusive_unchanged", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "5");
}

// ===== Runtime: stepped range =================================================

/// `0..10 step 2` visits `0,2,4,6,8`.
// Each test below builds its output via `concat` into a `let`-bound `str`
// rather than `print(f"{i} ")` directly -- an f-string passed straight to
// `print`/`println` always bakes in a trailing newline regardless of which
// of the two builtins is used (`Codegen::emit_print_like`'s documented
// behavior), so accumulating with `print` per-iteration would interleave a
// `\n` after every number instead of producing one space-separated line.
// Assigning the f-string to a `let` first takes the general (no
// auto-newline) `str`-value codegen path instead (`codegen/expr.rs`'s
// `TypedExpr::FStr` arm).

#[test]
fn runtime_positive_step_end_to_end() {
    let src = "fn main():\n    let mut xs = \"\"\n    for i in 0..10 step 2:\n        let piece = f\"{i} \"\n        xs = concat(xs, piece)\n    println(xs)\n";
    let output = compile_and_run("for_step_positive", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "0 2 4 6 8");
}

/// `0..=10 step 2` visits `0,2,4,6,8,10` -- inclusive end lands exactly on
/// step boundary.
#[test]
fn runtime_positive_step_inclusive_end_to_end() {
    let src = "fn main():\n    let mut xs = \"\"\n    for i in 0..=10 step 2:\n        let piece = f\"{i} \"\n        xs = concat(xs, piece)\n    println(xs)\n";
    let output = compile_and_run("for_step_positive_inclusive", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "0 2 4 6 8 10");
}

/// A descending range with a negative step: `10..0 step -1` visits
/// `10,9,...,1` (exclusive of `0`).
#[test]
fn runtime_negative_step_descending_end_to_end() {
    let src = "fn main():\n    let mut xs = \"\"\n    for i in 10..0 step -1:\n        let piece = f\"{i} \"\n        xs = concat(xs, piece)\n    println(xs)\n";
    let output = compile_and_run("for_step_negative", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "10 9 8 7 6 5 4 3 2 1");
}

/// A descending inclusive range: `10..=0 step -1` visits `10,9,...,0`.
#[test]
fn runtime_negative_step_inclusive_descending_end_to_end() {
    let src = "fn main():\n    let mut xs = \"\"\n    for i in 10..=0 step -1:\n        let piece = f\"{i} \"\n        xs = concat(xs, piece)\n    println(xs)\n";
    let output = compile_and_run("for_step_negative_inclusive", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "10 9 8 7 6 5 4 3 2 1 0");
}

/// A step that doesn't evenly divide the range still stops at (not past) the
/// last value that satisfies the bound: `0..10 step 3` visits `0,3,6,9`.
#[test]
fn runtime_step_not_evenly_dividing_range_end_to_end() {
    let src = "fn main():\n    let mut xs = \"\"\n    for i in 0..10 step 3:\n        let piece = f\"{i} \"\n        xs = concat(xs, piece)\n    println(xs)\n";
    let output = compile_and_run("for_step_uneven", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "0 3 6 9");
}

/// A mismatched direction (ascending range, negative step) must be zero
/// iterations, not an infinite/huge loop.
#[test]
fn runtime_step_direction_mismatch_is_zero_iterations_end_to_end() {
    let src = "fn main():\n    let mut count = 0\n    for i in 0..10 step -1:\n        count += 1\n    println(f\"{count}\")\n";
    let output = compile_and_run("for_step_mismatch", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "0");
}

/// `continue` inside a stepped loop still advances the counter by `step`
/// before rechecking the condition (the classic "manual `while` + increment"
/// footgun this feature is meant to replace -- see `docs/requests.md` #4 --
/// would skip the increment on `continue` and loop forever; this must not).
#[test]
fn runtime_continue_inside_stepped_loop_still_advances_end_to_end() {
    let src = "fn main():\n    let mut xs = \"\"\n    for i in 0..10 step 2:\n        if i == 4:\n            continue\n        let piece = f\"{i} \"\n        xs = concat(xs, piece)\n    println(xs)\n";
    let output = compile_and_run("for_step_continue", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "0 2 6 8");
}

/// `break` inside a stepped/inclusive loop still exits immediately.
#[test]
fn runtime_break_inside_stepped_loop_end_to_end() {
    let src = "fn main():\n    let mut xs = \"\"\n    for i in 0..=10 step 2:\n        if i == 6:\n            break\n        let piece = f\"{i} \"\n        xs = concat(xs, piece)\n    println(xs)\n";
    let output = compile_and_run("for_step_break", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "0 2 4");
}
