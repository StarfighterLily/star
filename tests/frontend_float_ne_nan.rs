//! `!=` on floats is IEEE 754's unordered not-equal.
//!
//! `Codegen::emit_scalar_binop`/`emit_f64_binop` lowered `!=` to LLVM's
//! `fcmp one` (ordered and not equal), which is false whenever either side
//! is NaN, so `nan != nan` was false and the usual `x != x` NaN test never
//! fired. C, Rust and IEEE 754 all say `!=` is true there (`fcmp une`). It
//! surfaced in the `projects/havokos` LPMUD driver: its float printer tests
//! `v != v` for NaN and `x - x != 0.0` for infinity, and on infinity both
//! were false, so a scaling loop never ended and an LPC
//! `json_decode("1e400")` hung the whole driver. `==`, `<`, `<=`, `>` and
//! `>=` stay ordered (false against NaN), as IEEE 754 has them.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

fn run_lines(name: &str, src: &str) -> String {
    let out = compile_and_run(name, src);
    assert!(out.status.success(), "should run: {:?}", out);
    String::from_utf8_lossy(&out.stdout).replace("\r\n", "\n")
}

/// `!=` on two `f64`s lowers to `fcmp une double`, never `fcmp one`.
#[test]
fn codegen_f64_ne_is_unordered() {
    let src = "fn t(a: f64, b: f64) -> bool:\n    a != b\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i1 @t(");
    assert!(fn_ir.contains("fcmp une double"), "{}", fn_ir);
    assert!(!fn_ir.contains("fcmp one"), "{}", fn_ir);
}

/// `!=` on two `f32`s lowers to `fcmp une float`.
#[test]
fn codegen_f32_ne_is_unordered() {
    let src = "fn t(a: f32, b: f32) -> bool:\n    a != b\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i1 @t(");
    assert!(fn_ir.contains("fcmp une float"), "{}", fn_ir);
    assert!(!fn_ir.contains("fcmp one"), "{}", fn_ir);
}

/// An `f64` NaN is `!=` itself (and not `==`), so `x != x` detects it.
#[test]
fn runtime_f64_nan_ne_itself() {
    let src = "fn main() -> i32:\n    let big = (1.0 as f64) * pow(10.0 as f64, 300.0 as f64)\n    let inf = big * big\n    let nan = inf - inf\n    println(f\"{nan != nan} {nan == nan} {nan < nan}\")\n    0\n";
    assert_eq!(run_lines("float_ne_nan_f64", src), "true false false\n");
}

/// `inf - inf != 0.0` holds, the infinity test the HavokOS float printer uses.
#[test]
fn runtime_f64_infinity_minus_itself_ne_zero() {
    let src = "fn main() -> i32:\n    let big = (1.0 as f64) * pow(10.0 as f64, 300.0 as f64)\n    let inf = big * big\n    let zero = 0.0 as f64\n    println(f\"{inf - inf != zero} {big - big != zero}\")\n    0\n";
    assert_eq!(run_lines("float_ne_inf_f64", src), "true false\n");
}

/// An `f32` NaN is `!=` itself too, and ordinary values compare as before.
#[test]
fn runtime_f32_nan_ne_itself_and_plain_values_unchanged() {
    let src = "fn main() -> i32:\n    let big = 1.0e30\n    let inf = big * big * big\n    let nan = inf - inf\n    let a = 1.5\n    println(f\"{nan != nan} {a != 1.5} {a != 2.5} {a == 1.5}\")\n    0\n";
    assert_eq!(run_lines("float_ne_nan_f32", src), "true false true true\n");
}
