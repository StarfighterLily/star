//! `todo.md` P2 #9: `struct Flags:` previously collided with the builtin
//! `Flags<E>` bitset generic with a misleading error -- `Checker::
//! infer_expr`'s `Expr::StructLit` arm unconditionally hijacked any call
//! named `Flags` to `infer_flags_new` (`src/types/expr.rs`) *before* ever
//! consulting `self.structs`, so the declaration itself produced no
//! diagnostic at all and the confusing `` `Flags<E>(..)` needs an explicit
//! type argument `` message only appeared later, at the construction call
//! site, pointing nowhere near the real problem. Fixed the same way an
//! earlier bug-hunting round already fixed the analogous collision with
//! builtin *scalar* types (`Tick`, `Vec2`, ... -- see
//! `tests/frontend_bughunt_shadowing_generic_ctor_rc_import_diag.rs`'s
//! `struct_named_after_a_builtin_scalar_type_shadows_it_end_to_end`): a
//! user's non-generic `struct Flags:` now takes priority over the
//! hardcoded `"Flags"` dispatch, so it constructs, field-accesses, and
//! reports its own arity/field-type errors exactly like any other
//! user-declared struct, while `Flags<E>` continues to work normally in
//! any module that never declares a colliding struct.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

/// The declaration alone -- no construction anywhere -- previously slipped
/// through pass 0's duplicate-name registration with zero complaint (the
/// bug was silent at the declaration site, confusing only at use), and
/// under the shadowing fix it still type-checks cleanly: a bare
/// non-generic `struct Flags:` is exactly as legal as `struct Tick:`.
#[test]
fn struct_named_flags_declares_with_no_diagnostic() {
    let src = "struct Flags:\n    value: i32\n\nfn main():\n    return\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("a non-generic `struct Flags:` should declare cleanly, matching `Tick`/`Vec2`");
}

/// Core regression: constructing and field-reading a single-field
/// `struct Flags:` end to end, mirroring `struct_named_after_a_builtin_
/// scalar_type_shadows_it_end_to_end`'s exact shape for `Tick`.
#[test]
fn struct_named_flags_shadows_the_builtin_end_to_end() {
    let src = "struct Flags:\n    value: i32\n\nfn main():\n    let f = Flags(5)\n    println(f\"{f.value}\")\n";
    let output = compile_and_run("struct_named_flags_shadows_builtin", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "5");
}

/// Multiple positional fields -- guards that the fix falls all the way
/// through to the ordinary multi-field struct-literal codegen path, not
/// just a single-argument coincidence that happens to also satisfy the
/// builtin's own arity expectations.
#[test]
fn struct_named_flags_with_multiple_fields_shadows_the_builtin_end_to_end() {
    let src = "struct Flags:\n    a: i32\n    b: i32\n\nfn main():\n    let f = Flags(3, 4)\n    println(f\"{f.a} {f.b}\")\n";
    let output = compile_and_run("struct_named_flags_multi_field_shadows_builtin", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "3 4");
}

/// Named-argument construction (`Flags(value = 5)`) -- guards that
/// `ctor_field_list` (which already consulted `self.structs` first, even
/// before this fix) and the now-shadowed dispatch agree on the same field
/// list, so named args resolve against the user's declared field, not any
/// builtin notion of `Flags`'s shape.
#[test]
fn struct_named_flags_named_arg_construction_shadows_the_builtin_end_to_end() {
    let src = "struct Flags:\n    value: i32\n\nfn main():\n    let f = Flags(value = 7)\n    println(f\"{f.value}\")\n";
    let output = compile_and_run("struct_named_flags_named_arg_shadows_builtin", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "7");
}

/// The heart of the todo item: once `Flags` is shadowed, a *wrong* argument
/// count at the construction site must report the user struct's own
/// arity error (`` `Flags(..)` expects 1 argument(s), found 2 ``) -- not the
/// old misleading builtin message (`` `Flags<E>(..)` needs an explicit type
/// argument ``), which named the wrong problem entirely and pointed a
/// confused user at generic-type-argument syntax that has nothing to do
/// with their actual mistake.
#[test]
fn struct_named_flags_ctor_arity_error_reports_the_struct_not_the_builtin() {
    let src = "struct Flags:\n    value: i32\n\nfn main():\n    let f = Flags(1, 2)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("wrong arity against the user struct should be a type error");
    assert!(
        diags.iter().any(|d| d.message.contains("`Flags(..)` expects 1 argument(s), found 2")),
        "{:?}", diags
    );
    assert!(
        !diags.iter().any(|d| d.message.contains("needs an explicit type argument")),
        "the misleading builtin-generic diagnostic must not fire once `Flags` is shadowed: {:?}", diags
    );
}

/// Field-type mismatches against a shadowed `Flags` struct go through the
/// same `check_field_ctor_types` path every other struct's fields do --
/// confirms the shadow isn't just arity-deep.
#[test]
fn struct_named_flags_ctor_field_type_error_reports_the_struct_field() {
    let src = "struct Flags:\n    value: i8\n\nfn main():\n    let f = Flags(1.5)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("a float literal against a declared `i8` field should be a type error");
    assert!(
        diags.iter().any(|d| d.message.contains("`Flags`'s field `value`")),
        "{:?}", diags
    );
}

/// Regression guard on the fix's own scope: a module that never declares a
/// colliding `struct Flags:` must keep getting the real builtin's own
/// diagnostic when a type argument is omitted -- the shadowing check must
/// not accidentally suppress this message unconditionally.
#[test]
fn builtin_flags_without_a_colliding_struct_still_needs_an_explicit_type_argument() {
    let src = "fn main():\n    let f = Flags()\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("`Flags()` with no type argument and no colliding struct should still be rejected");
    assert!(
        diags.iter().any(|d| d.message.contains("needs an explicit type argument")),
        "{:?}", diags
    );
}

/// Full end-to-end regression on the builtin bitset itself, in a module
/// with no colliding struct: construction, `flags_has` on a present vs.
/// absent variant -- confirms the shadow-priority fix left the ordinary,
/// non-colliding case completely unaffected.
#[test]
fn builtin_flags_bitset_without_a_colliding_struct_still_works_end_to_end() {
    let src = concat!(
        "enum Direction:\n    North\n    South\n    East\n    West\n\n",
        "fn main():\n",
        "    let f: Flags<Direction> = Flags<Direction>(Direction::North, Direction::East)\n",
        "    println(f\"{flags_has(f, Direction::North)} {flags_has(f, Direction::South)}\")\n",
    );
    let output = compile_and_run("builtin_flags_bitset_unaffected_by_shadow_fix", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "true false");
}
