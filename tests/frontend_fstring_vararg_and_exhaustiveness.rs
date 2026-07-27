//! f-string vararg bugfix, match exhaustiveness, generic type-param consistency
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Bug-fix round: f-string value path i64 vararg mismatch ==============

/// The general f-string-as-value path (`TypedExpr::FStr` in `expr.rs`, used
/// whenever an f-string isn't `print`/`println`'s direct sole argument) only
/// special-cased `Ty::Int`/`Ty::Float`/`Ty::Str`/`Ty::Bool`; every other
/// type -- `Ty::I64` included -- fell through the `%p` catch-all, which
/// tagged the `snprintf` vararg `i8*` even though an `I64` value's own LLVM
/// type is `i64` (see `Codegen::llvm_ty`), a real `clang`/LLVM vararg type
/// mismatch noticed via interpolating an `i64` struct field
/// (`f"{e.id}"`). Fixed by mirroring `emit_print_like`'s
/// (`builtins.rs`) format-specifier/vararg-widening table. Asserts the fix
/// at the IR level: an interpolated `i64` field must use `%lld`, and the
/// `snprintf` call's vararg for it must be tagged `i64`, not `i8*`.
#[test]
fn codegen_fstring_value_interpolates_i64_field_with_correct_specifier_and_vararg_type() {
    let src = "struct Entity:\n    id: i64\nfn t(e: Entity) -> str:\n    f\"id={e.id}\"\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    // The format string itself lives in a global constant (`Codegen::
    // global_defs`, emitted ahead of every `define`), not inside the
    // function body `extract_fn_body` slices out -- check the full module
    // text for the specifier, and just the function body for the vararg's
    // own type tag.
    assert!(ir.contains("%lld"), "an interpolated `i64` should use `%lld`, not fall through to `%p`: {}", ir);
    let fn_ir = extract_fn_body(&ir, "define i8* @t(");
    assert!(
        fn_ir.contains("@snprintf(i8* null, i64 0, i8* ") && fn_ir.contains(", i64 %"),
        "the `snprintf` sizing call's vararg for an `i64` field must itself be tagged `i64`, not `i8*`: {}",
        fn_ir
    );
}

/// Runtime companion to the IR-shape assertion above: actually compiling
/// (via `clang`) and running an f-string value that interpolates an `i64`
/// struct field must produce the exact decimal value -- using a value
/// outside `i32`'s range means a truncating/mistyped vararg would either
/// fail to compile at all or print a wrong/garbage number instead of this.
#[test]
fn runtime_fstring_value_interpolates_i64_struct_field_end_to_end() {
    let src = "struct Entity:\n    id: i64\nfn describe(e: Entity) -> str:\n    return f\"id={e.id}\"\n\
               fn main():\n    let e = Entity(id = 123456789012 as i64)\n    println(describe(e))\n";
    let output = compile_and_run("fstring_value_i64_struct_field", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "id=123456789012", "{}", stdout);
}

/// Broader width/signedness coverage for the same fixed path (`I64` was the
/// specific reported bug, but `U8`/`I16`/`U32`/`U64`/`Char` shared the
/// identical gap in the same `match` before this fix) -- every non-`i32`
/// integer-ish hole type this general f-string-as-value path now supports
/// substitutes to its correct decimal (or character) form in one pass.
#[test]
fn runtime_fstring_value_wide_integer_types_end_to_end() {
    let src = "fn main():\n    let a: u8 = 200 as u8\n    let b: i16 = -1234 as i16\n    let c: u32 = 4000000000 as u32\n    \
               let d: i64 = -9000000000 as i64\n    let e: u64 = 9111222333444555666 as u64\n    let f: char = 'Q'\n    \
               let s = f\"a={a} b={b} c={c} d={d} e={e} f={f}\"\n    println(s)\n";
    let output = compile_and_run("fstring_value_wide_integer_types", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "a=200 b=-1234 c=4000000000 d=-9000000000 e=9111222333444555666 f=Q", "{}", stdout);
}

/// An f-string value built from a `str` binding (a borrowing read, not a
/// fresh construction) must not corrupt or prematurely release the original
/// binding -- the interpolation hole only reads the bytes for `snprintf`.
#[test]
fn runtime_fstring_value_borrowing_str_read_does_not_corrupt_original_end_to_end() {
    let src = "fn main():\n    let name = \"world\"\n    let s = f\"hello {name}\"\n    println(s)\n    println(name)\n";
    let output = compile_and_run("fstring_value_borrowing_read", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["hello world", "world"], "{}", stdout);
}

/// A non-print f-string value can be built from another non-print f-string
/// value's result (nested interpolation) and passed through `concat` --
/// confirms the materialized buffer is an ordinary, fully-usable `str`.
#[test]
fn runtime_fstring_value_nested_and_concat_end_to_end() {
    let src = "fn main():\n    let name = \"star\"\n    let s2 = f\"nested: {f\"{name}!\"}\"\n    println(s2)\n    let s3 = concat(f\"a{1}\", f\"b{2}\")\n    println(s3)\n";
    let output = compile_and_run("fstring_value_nested_concat", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["nested: star!", "a1b2"], "{}", stdout);
}

// ===== match exhaustiveness ==================================================

/// A `match` over an enum that neither covers every variant nor has a
/// wildcard/binding catch-all must be rejected -- previously nothing checked
/// this at all, and the generated code fell through to an `undef` value at
/// runtime (see `Codegen::emit_expr`'s `TypedExpr::Match` arm's "no arm
/// matched" fallthrough path, which assumes this was already validated).
#[test]
fn rejects_non_exhaustive_match_over_enum() {
    let src = "enum Dir:\n    North\n    South\n    East\n    West\nfn describe(d: Dir) -> i32:\n    match d:\n        Dir::North -> 1\n        Dir::South -> 2\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("a match missing enum variants with no wildcard should be rejected")
    };
    assert!(
        errs.iter().any(|d| d.message.contains("non-exhaustive") && d.message.contains("East") && d.message.contains("West")),
        "{:?}",
        errs
    );
}

/// A `match` over an enum that covers every variant explicitly (no wildcard
/// needed) must still type-check -- guards against the exhaustiveness check
/// above being so aggressive it rejects sound, ordinary code (this is
/// exactly the shape `examples/control_flow.star`'s `Dir` match already
/// uses).
#[test]
fn accepts_exhaustive_match_over_enum_covering_every_variant_without_wildcard() {
    let src = "enum Dir:\n    North\n    South\nfn describe(d: Dir) -> i32:\n    match d:\n        Dir::North -> 1\n        Dir::South -> 2\nfn main():\n    println(f\"{describe(Dir::North)}\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("a match covering every enum variant should type-check without a wildcard");
}

/// Same bug, `bool` scrutinee: only `true` is covered, `false` isn't, and
/// there's no wildcard.
#[test]
fn rejects_non_exhaustive_match_over_bool() {
    let src = "fn describe(b: bool) -> i32:\n    match b:\n        true -> 1\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("a bool match missing `false` and no wildcard should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("non-exhaustive") && d.message.contains("bool")), "{:?}", errs);
}

/// Same bug, an unbounded scalar domain (`i32`): a finite set of
/// `Compare`/literal patterns can never be proven to cover every `i32`, so
/// this always requires an explicit wildcard.
#[test]
fn rejects_non_exhaustive_match_over_int_without_wildcard() {
    let src = "fn describe(x: i32) -> i32:\n    match x:\n        <= 0 -> 1\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("an int match with no wildcard catch-all should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("non-exhaustive")), "{:?}", errs);
}

// ===== generic type-parameter consistency ===================================

/// A generic function whose type parameter `T` appears in more than one
/// parameter position must infer the *same* concrete type from every
/// argument -- previously `Checker::unify_ty` kept only the first binding
/// found for a parameter and silently ignored any later, conflicting one, so
/// `pick(5, "hello")` against `fn pick<T>(a: T, b: T) -> T` type-checked
/// cleanly.
#[test]
fn rejects_generic_fn_call_with_inconsistent_type_parameter() {
    let src = "fn pick<T>(a: T, b: T) -> T:\n    return a\nfn main():\n    let x = pick(5, \"hello\")\n    println(f\"{x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("a generic call binding the same type parameter to two different types should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("inconsistently") && d.message.contains("pick")), "{:?}", errs);
}

/// Same bug, reached through generic struct construction (`Checker::unify_ty`
/// is shared by `infer_generic_call` and `resolve_generic_ctor_args`).
#[test]
fn rejects_generic_struct_ctor_with_inconsistent_type_parameter() {
    let src = "struct Pair<T>:\n    a: T\n    b: T\nfn main():\n    let p = Pair(5, \"hello\")\n    println(f\"{p.a}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("a generic struct literal binding the same type parameter to two different types should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("inconsistently") && d.message.contains("Pair")), "{:?}", errs);
}

/// Consistent use of a repeated type parameter must still work -- guards
/// against the check above being so aggressive it rejects sound, ordinary
/// generic calls.
#[test]
fn runtime_generic_fn_call_with_consistent_type_parameter_end_to_end() {
    let src = "fn pick<T>(a: T, b: T) -> T:\n    return a\nfn main():\n    let x = pick(5, 6)\n    println(f\"{x}\")\n";
    let output = compile_and_run("generic_consistent_type_param", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "5", "{}", stdout);
}
