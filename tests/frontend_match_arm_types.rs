//! A `match` whose arms produce values of incompatible types.
//!
//! The checker used to type every `match` after its first value-producing
//! arm, so a statement like `match v: A -> make_payload_enum()  _ -> 0`
//! (the `0` only there to give the catch-all arm a body) reached codegen as
//! a match producing the enum, whose join `phi` then had an `int` flowing
//! in: malformed IR the build refused. It surfaced porting the LPMUD driver
//! in `projects/havokos` (`todo.md` HavokOS M5). Such a match now produces
//! no value: fine as a statement (each arm's discarded value released like
//! any statement expression's), a type error as a value. Integer-shaped arms
//! still share the first arm's type, since an integer literal is valid in
//! any integer `phi`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

const SRC_PREFIX: &str = concat!(
    "enum V:\n",
    "    Nothing\n",
    "    Text(s: str)\n",
    "\n",
    "fn make(s: str) -> V:\n",
    "    V::Text(concat(s, \"!\"))\n",
    "\n",
);

/// A statement `match` with an enum-valued arm beside an `int` arm builds and runs.
#[test]
fn runtime_statement_match_with_enum_and_int_arms_end_to_end() {
    let src = format!(
        "{}{}",
        SRC_PREFIX,
        concat!(
            "fn main() -> i32:\n",
            "    let mut n = 0\n",
            "    for i in 0..3:\n",
            "        let v = if i == 1: V::Nothing else: V::Text(\"x\")\n",
            "        match v:\n",
            "            V::Text(s) -> make(s)\n",
            "            _ -> 0\n",
            "        n += 1\n",
            "    println(f\"ran {n}\")\n",
            "    0\n",
        )
    );
    let out = compile_and_run("match_enum_int_arms", &src);
    assert!(out.status.success(), "should build and run: {:?}", out);
    assert_eq!(String::from_utf8_lossy(&out.stdout).replace("\r\n", "\n"), "ran 3\n");
}

/// The statement match's IR has no `phi` mixing the enum with an integer, and passes the internal verifier.
#[test]
fn codegen_statement_match_with_incompatible_arms_has_no_mixed_phi() {
    let src = format!(
        "{}{}",
        SRC_PREFIX,
        "fn main():\n    let v = V::Text(\"x\")\n    match v:\n        V::Text(s) -> make(s)\n        _ -> 0\n"
    );
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let v = Driver::codegen_verified_for_target(&typed, star::codegen::Target::WindowsGnu).expect("should codegen");
    assert!(v.errors.is_empty(), "{:?}", v.errors.iter().map(|d| &d.message).collect::<Vec<_>>());
    assert!(!v.ir.lines().any(|l| l.contains("= phi %V ")), "no value join for a match that produces none: {}", v.ir);
}

/// Using such a match as a value is a type error, not broken IR.
#[test]
fn incompatible_arms_used_as_a_value_is_a_type_error() {
    let src = format!(
        "{}{}",
        SRC_PREFIX,
        "fn main():\n    let v = V::Text(\"x\")\n    let w: V = match v:\n        V::Text(s) -> make(s)\n        _ -> 0\n"
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "binding a value-less match should not type-check");
}

/// So is returning one as a function's trailing value.
#[test]
fn incompatible_arms_as_a_trailing_return_value_is_a_type_error() {
    let src = format!(
        "{}{}",
        SRC_PREFIX,
        "fn f(v: V) -> V:\n    match v:\n        V::Text(s) -> make(s)\n        _ -> 0\n\nfn main():\n    let w = f(V::Nothing)\n"
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "a value-less match can't be a function's return value");
}

/// Integer-shaped arms keep working as a value: an `i64` arm beside a literal `0`.
#[test]
fn runtime_integer_arms_still_share_a_value_end_to_end() {
    let src = concat!(
        "fn pick(k: i32) -> i64:\n",
        "    match k:\n",
        "        1 -> (40 as i64) + (2 as i64)\n",
        "        _ -> 0\n",
        "\n",
        "fn main() -> i32:\n",
        "    println(f\"{pick(1)} {pick(2)}\")\n",
        "    0\n",
    );
    let out = compile_and_run("match_int_arms_value", src);
    assert!(out.status.success(), "should build and run: {:?}", out);
    assert_eq!(String::from_utf8_lossy(&out.stdout).replace("\r\n", "\n"), "42 0\n");
}
