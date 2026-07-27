//! Math builtins: trig/exponential/logarithm
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Math builtins: trig/exponential/logarithm (todo.md #6 "Fill out math
// builtins as needed") ========================================================
//
// `sin`/`cos`/`tan`/`asin`/`acos`/`atan`/`atan2`/`exp`/`exp2`/`log`/`log2`/
// `log10` land alongside the pre-existing `sqrt`/`pow`/`floor`/`ceil`, same
// shape: dispatched by name ahead of the ordinary function table
// (`builtin_return_ty`/`Codegen::emit_expr`'s `TypedExpr::Call` arm), always
// `Float`-typed, lowered to LLVM's target-independent float intrinsics
// (`llvm.sin.f32`/etc.) rather than libm symbols so no extra linker flag is
// needed -- confirmed these particular names (unlike, say, older LLVM
// versions where `tan`/`asin`/`acos`/`atan`/`atan2` weren't real intrinsics)
// assemble and link cleanly on this toolchain before writing any of the
// tests below.

/// Every new unary builtin rejects a non-numeric argument and a wrong arity,
/// exactly like the pre-existing `sqrt`/`floor`/`ceil` check
/// (`checker_rejects_sqrt_non_numeric_arg`); `atan2` is checked separately
/// since it takes two arguments and shares `pow`/`min`/`max`'s arity-2 rule.
#[test]
fn checker_rejects_trig_log_builtins_wrong_arity_and_types() {
    let unary: &[&str] = &["sin", "cos", "tan", "asin", "acos", "atan", "exp", "exp2", "log", "log2", "log10"];
    for name in unary {
        let bad_type_src = format!("fn t():\n    {}(\"nope\")\n", name);
        let module = Driver::parse(&bad_type_src).expect("should parse");
        let Err(diags) = Driver::check(&module) else { panic!("{}(\"nope\") should fail to type-check", name) };
        assert!(
            diags.iter().any(|d| d.message.contains(&format!("`{}`", name)) && d.message.contains("numeric")),
            "{}: {:?}",
            name,
            diags
        );

        let bad_arity_src = format!("fn t():\n    {}(1.0, 2.0)\n", name);
        let module = Driver::parse(&bad_arity_src).expect("should parse");
        let Err(diags) = Driver::check(&module) else { panic!("{}(1.0, 2.0) should fail to type-check (arity)", name) };
        assert!(
            diags.iter().any(|d| d.message.contains(&format!("`{}` expects 1 argument(s), found 2", name))),
            "{}: {:?}",
            name,
            diags
        );
    }

    let module = Driver::parse("fn t():\n    atan2(1.0)\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("atan2(1.0) should fail to type-check (arity)") };
    assert!(diags.iter().any(|d| d.message.contains("`atan2` expects 2 argument(s), found 1")), "{:?}", diags);

    let module = Driver::parse("fn t():\n    atan2(\"a\", 1.0)\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("atan2(\"a\", 1.0) should fail to type-check") };
    assert!(
        diags.iter().any(|d| d.message.contains("`atan2` argument 1 expected a numeric") ),
        "{:?}",
        diags
    );
}

/// `sin(0.0)`/`atan2(1.0, 1.0)` and friends all resolve to `Float` through the
/// checker, same as the pre-existing `checks_builtin_return_types` test for
/// `sqrt`/`abs`/`len`/`concat` -- these are new names entirely, so nothing
/// previously exercised that `builtin_return_ty` recognizes them at all.
#[test]
fn checks_trig_log_builtin_return_types() {
    let src = "fn t():\n    \
                   let a: float = sin(0.0)\n    \
                   let b: float = cos(0.0)\n    \
                   let c: float = tan(0.0)\n    \
                   let d: float = asin(1.0)\n    \
                   let e: float = acos(1.0)\n    \
                   let f: float = atan(1.0)\n    \
                   let g: float = atan2(1.0, 1.0)\n    \
                   let h: float = exp(1.0)\n    \
                   let i: float = exp2(1.0)\n    \
                   let j: float = log(1.0)\n    \
                   let k: float = log2(1.0)\n    \
                   let l: float = log10(1.0)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(fun) = &typed.items[0] else { panic!("expected fn") };
    for i in 0..12 {
        let TypedStmt::Let { value, .. } = &fun.body.stmts[i] else { panic!("expected let, got {:?}", fun.body.stmts[i]) };
        assert_eq!(value.clone().into_ty(), Ty::Float, "stmt {} should be Float-typed", i);
    }
}

/// An `extern "C" fn` reusing one of the new names collides with the builtin
/// name, exactly like the pre-existing `extern_fn_rejects_builtin_name_collision`
/// test for `abs` -- `is_builtin_name` (shared with `builtin_return_ty`) is
/// the single source of truth for both, so a newly-added builtin is
/// automatically covered with no separate reserved-name list to update.
#[test]
fn extern_fn_rejects_sin_as_builtin_name_collision() {
    let src = "extern \"C\" fn sin(x: float) -> float\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("extern fn colliding with the `sin` builtin name should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("collides with a built-in name")), "{:?}", diags);
}

/// `sin`/`cos`/`tan` at `0`, `pi/2`, and `pi` (`pi` itself derived from
/// `4.0 * atan(1.0)`, not a hardcoded literal, so this also exercises `atan`)
/// -- hand-verified expected values, run for real through `clang` rather than
/// just asserted at the IR-shape level.
#[test]
fn runtime_trig_functions_end_to_end() {
    let src = "fn main():\n    \
                   let pi = 4.0 * atan(1.0)\n    \
                   let half_pi = 2.0 * atan(1.0)\n    \
                   println(f\"{sin(0.0)}\")\n    \
                   println(f\"{cos(0.0)}\")\n    \
                   println(f\"{tan(0.0)}\")\n    \
                   println(f\"{sin(half_pi)}\")\n    \
                   println(f\"{cos(half_pi)}\")\n    \
                   println(f\"{cos(pi)}\")\n";
    let output = compile_and_run("trig_functions", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec!["0.000000", "1.000000", "0.000000", "1.000000", "-0.000000", "-1.000000"],
        "{}",
        stdout
    );
}

/// `asin`/`acos`/`atan` at known values, plus `atan2` across all four
/// quadrants (the sign of both arguments together picks the quadrant, unlike
/// plain `atan`'s single-argument, two-quadrant range) -- hand-verified
/// against the standard `atan2(y, x)` convention.
#[test]
fn runtime_inverse_trig_and_atan2_end_to_end() {
    let src = "fn main():\n    \
                   println(f\"{asin(0.5)}\")\n    \
                   println(f\"{acos(0.5)}\")\n    \
                   println(f\"{atan(1.0)}\")\n    \
                   println(f\"{atan2(1.0, 1.0)}\")\n    \
                   println(f\"{atan2(1.0, -1.0)}\")\n    \
                   println(f\"{atan2(-1.0, -1.0)}\")\n    \
                   println(f\"{atan2(-1.0, 1.0)}\")\n    \
                   println(f\"{atan2(0.0, 0.0)}\")\n";
    let output = compile_and_run("inverse_trig_atan2", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec!["0.523599", "1.047198", "0.785398", "0.785398", "2.356194", "-2.356194", "-0.785398", "0.000000"],
        "quadrant order is (Q1, Q2, Q3, Q4, origin): {}",
        stdout
    );
}

/// `exp`/`exp2`/`log`/`log2`/`log10` at values with exact, hand-verifiable
/// results (powers of the respective base, and `log` composed with its own
/// inverse `exp`), run for real rather than just asserted at the IR level.
#[test]
fn runtime_exp_log_functions_end_to_end() {
    let src = "fn main():\n    \
                   println(f\"{exp(0.0)}\")\n    \
                   println(f\"{exp(1.0)}\")\n    \
                   println(f\"{exp2(10.0)}\")\n    \
                   println(f\"{log(1.0)}\")\n    \
                   println(f\"{log(exp(1.0))}\")\n    \
                   println(f\"{log2(1024.0)}\")\n    \
                   println(f\"{log10(1000.0)}\")\n";
    let output = compile_and_run("exp_log_functions", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec!["1.000000", "2.718282", "1024.000000", "0.000000", "1.000000", "10.000000", "3.000000"],
        "{}",
        stdout
    );
}

/// Out-of-domain inputs (`log` of a non-positive number, `asin`/`acos` past
/// `[-1, 1]`) produce IEEE-754 `-inf`/NaN rather than trapping or crashing --
/// unlike, say, `abs`'s deliberate trap-on-overflow for `MIN`, there is no
/// "undefined behavior" floor cut here to guard: the underlying LLVM
/// intrinsics are plain float ops with well-defined NaN/infinity results, so
/// this just confirms the lowering doesn't accidentally introduce a crash or
/// a spurious trap on these edges. `log(-1.0)` and `asin`/`acos(2.0)` render
/// as different NaN spellings on this libc (`nan` vs `-nan(ind)`) -- matched
/// case-insensitively on the `nan` substring rather than pinned to one exact
/// spelling, since that particular formatting is a libc/platform quirk, not
/// behavior this compiler controls.
#[test]
fn runtime_trig_log_domain_edge_cases_end_to_end() {
    let src = "fn main():\n    \
                   println(f\"{log(0.0)}\")\n    \
                   println(f\"{log(-1.0)}\")\n    \
                   println(f\"{asin(2.0)}\")\n    \
                   println(f\"{acos(2.0)}\")\n";
    let output = compile_and_run("trig_log_domain_edge_cases", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines.len(), 4, "{}", stdout);
    assert_eq!(lines[0], "-inf", "log(0.0) should be -infinity: {}", stdout);
    assert!(lines[1].to_lowercase().contains("nan"), "log(-1.0) should be NaN: {}", stdout);
    assert!(lines[2].to_lowercase().contains("nan"), "asin(2.0) should be NaN (out of [-1,1] domain): {}", stdout);
    assert!(lines[3].to_lowercase().contains("nan"), "acos(2.0) should be NaN (out of [-1,1] domain): {}", stdout);
}

/// An `int` argument is promoted to `float` first (`emit_math_unary`'s
/// existing `promote_to_float` call, shared with `sqrt`/`floor`/`ceil`) --
/// `sin(1)`/`log(1)` with a bare `int` literal must produce the same result
/// as the `float`-literal call, not a type error or truncated-to-zero
/// result.
#[test]
fn runtime_trig_log_int_argument_promotion_end_to_end() {
    let src = "fn main():\n    \
                   println(f\"{sin(1)}\")\n    \
                   println(f\"{log(1)}\")\n    \
                   println(f\"{exp2(10)}\")\n";
    let output = compile_and_run("trig_log_int_promotion", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["0.841471", "0.000000", "1024.000000"], "{}", stdout);
}
