//! Float math builtins (`sqrt`, `pow`, `sin`, `log`, ...) with `f64`
//! arguments.
//!
//! Every one of them used to be typed `Float` and lowered through the
//! `.f32` LLVM intrinsics regardless of its argument, so an `f64` was
//! narrowed to single precision on the way in and the result was only good
//! to about 7 digits -- and assigning it back to an `f64` was a type error
//! ("expects type `F64`, found `Float`"), which is how it surfaced: the
//! `projects/havokos` LPMUD driver's math efuns work on doubles. Fixed by
//! `crate::types::math_result_ty` (an `f64` argument makes the result
//! `F64`) and `Codegen::emit_math_unary`/`emit_math_binary_f32` calling the
//! `.f64` intrinsics for it. `Float` and integer arguments are unchanged.
//!
//! Reference values in the runtime tests are computed rather than written
//! as literals: a float literal is single precision before `as f64` widens
//! it, so `2.718281828459045 as f64` is only 2.7182817...

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

/// `sqrt` of an `f64` is typed `F64`, so it can initialise an `f64` variable.
#[test]
fn typecheck_sqrt_of_f64_is_f64() {
    let src = "fn f() -> f64:\n    let x = 2.0 as f64\n    sqrt(x)\n";
    assert_eq!(typed_fn_result_ty(src), Ty::F64);
}

/// `pow` of two `f64`s is `F64`.
#[test]
fn typecheck_pow_f64_is_f64() {
    let src = "fn f() -> f64:\n    let x = 2.0 as f64\n    pow(x, 0.5 as f64)\n";
    assert_eq!(typed_fn_result_ty(src), Ty::F64);
}

/// Mixing `f64` and `Float` in `pow` is still rejected, as before (the checker wants one numeric type).
#[test]
fn typecheck_pow_mixed_f64_float_still_rejected() {
    let src = "fn f() -> f64:\n    let x = 2.0 as f64\n    pow(x, 0.5)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("same numeric type")), "{:?}", diags);
}

/// A `Float` argument keeps the old single-precision `Float` result.
#[test]
fn typecheck_sqrt_of_float_stays_float() {
    let src = "fn f() -> f32:\n    sqrt(2.0)\n";
    assert_eq!(typed_fn_result_ty(src), Ty::Float);
}

/// `sqrt(2.0 as f64)` is accurate to double precision (it was ~1.41421354 before).
#[test]
fn runtime_sqrt_f64_full_precision() {
    let src = "fn main() -> i32:\n    let r = sqrt(2.0 as f64)\n    let err = r * r - (2.0 as f64)\n    let tiny = (1.0 as f64) / (1000000000000.0 as f64)\n    if err < tiny and err > (0.0 as f64) - tiny:\n        println(\"ok\")\n    else:\n        println(\"narrowed\")\n    0\n";
    let out = compile_and_run("math_f64_sqrt", src);
    assert!(out.status.success(), "should run: {:?}", out);
    assert_eq!(String::from_utf8_lossy(&out.stdout).replace("\r\n", "\n"), "ok\n");
}

/// The trig/exp/log family and `floor`/`ceil`/`pow`/`atan2`/`exp2` all run in double precision on `f64`.
#[test]
fn runtime_math_family_f64() {
    let src = concat!(
        "fn close(a: f64, b: f64) -> bool:\n",
        "    let d = a - b\n",
        "    let eps = (1.0 as f64) / (1000000000000.0 as f64)\n",
        "    d < eps and d > (0.0 as f64) - eps\n",
        "fn main() -> i32:\n",
        "    let one = 1.0 as f64\n",
        "    let x = (3.0 as f64) / (10.0 as f64)\n",
        "    let mut ok = true\n",
        "    ok = ok and close(log(exp(one)), one) and close(exp(log(x)), x)\n",
        "    ok = ok and close(log10(1000.0 as f64), 3.0 as f64)\n",
        "    ok = ok and close(log2(8.0 as f64), 3.0 as f64)\n",
        "    ok = ok and close(sin(x) * sin(x) + cos(x) * cos(x), one)\n",
        "    ok = ok and close(tan(atan(x)), x)\n",
        "    ok = ok and close(asin(one) + acos(one), (2.0 as f64) * atan(one))\n",
        "    ok = ok and close(atan2(one, one), atan(one))\n",
        "    ok = ok and close(pow(2.0 as f64, (1.0 as f64) / (2.0 as f64)), sqrt(2.0 as f64))\n",
        "    ok = ok and close(floor(-2.5 as f64), -3.0 as f64) and close(ceil(2.1 as f64), 3.0 as f64)\n",
        "    ok = ok and close(exp2(10.0 as f64), 1024.0 as f64)\n",
        "    ok = ok and close(asin(sin(x)), x)\n",
        "    if ok:\n",
        "        println(\"ok\")\n",
        "    else:\n",
        "        println(\"bad\")\n",
        "    0\n",
    );
    let out = compile_and_run("math_f64_family", src);
    assert!(out.status.success(), "should run: {:?}", out);
    assert_eq!(String::from_utf8_lossy(&out.stdout).replace("\r\n", "\n"), "ok\n");
}

/// The `Float` path still runs (and stays single precision): `sqrt(2.0)` squared is off by more than 1e-12.
#[test]
fn runtime_sqrt_float_unchanged() {
    let src = "fn main() -> i32:\n    let r = sqrt(2.0) as f64\n    let err = r * r - (2.0 as f64)\n    let tiny = (1.0 as f64) / (1000000000000.0 as f64)\n    if err < tiny and err > (0.0 as f64) - tiny:\n        println(\"double\")\n    else:\n        println(\"single\")\n    0\n";
    let out = compile_and_run("math_float_sqrt", src);
    assert!(out.status.success(), "should run: {:?}", out);
    assert_eq!(String::from_utf8_lossy(&out.stdout).replace("\r\n", "\n"), "single\n");
}
