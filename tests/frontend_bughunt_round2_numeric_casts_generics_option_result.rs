//! Bug-hunting round 2: numeric types/casts/generics/Option/Result audit
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// =====================================================================
// ===== Bug-hunting round 2 (numeric types/casts/generics/Option/Result
// ===== audit): every fix below this marker was confirmed via a real
// ===== `star build`+run (an unbounded-working-set-growth reproduction for
// ===== the leaks, or direct stdout/exit-code inspection) before being
// ===== fixed, matching this file's existing convention. =================

/// `Codegen::contains_rc`/`emit_rc_walk` (`src/codegen/rc.rs`) had no arm
/// at all for `Ty::Enum` -- every payload enum (`Option<T>`, `Result<T,E>`,
/// or any user-defined enum with an RC-bearing variant field) silently fell
/// through `contains_rc`'s `_ => false` catch-all, so `Codegen::track_owned`
/// never registered an `Option<str>`/`Result<str,E>` local for release at
/// its scope's exit: a `let o = Option::Some(some_str)` that's never
/// explicitly matched/unwrapped leaked its payload's RC content on every
/// single evaluation. Confirmed via real unbounded working-set growth
/// (~83MB -> 390MB+ within 2 seconds of 30,000,000 iterations of `let o =
/// make_some(f"item{i}")`, flat on an otherwise-identical control with the
/// `Option<str>` wrapper removed) before this fix. Fixed by adding a
/// `Ty::Enum` arm to both functions: `contains_rc` is true whenever *any*
/// variant of the enum carries an RC-bearing field (the active variant is
/// only known at runtime); `emit_rc_walk` loads the runtime tag and
/// branches per RC-bearing variant, bitcasting the shared `[W x i64]`
/// payload buffer to that variant's own field layout exactly the way
/// `TypedExpr::EnumVariant` construction and `Pattern::EnumVariant`
/// destructuring already do, then recursing into each RC-bearing field.
#[test]
fn runtime_option_some_local_never_matched_does_not_leak_end_to_end() {
    let src = "fn make_some(s: str) -> Option<str>:\n    return Option::Some(s)\n\n\
               fn main():\n    let mut i: i32 = 0\n    \
               while i < 400000:\n        let o = make_some(concat(\"item\", \"x\"))\n        i += 1\n    \
               println(\"done\")\n";
    assert_no_leak("option_some_never_matched_leak", src, 20 * 1024 * 1024);
}

/// Same fix, exercised through a nested generic: `Option<Box<T>>` where
/// `Box<T>` is a plain user struct wrapping `T` -- `contains_rc(Ty::Enum)`
/// must recurse into a variant's field types via the ordinary `contains_rc`
/// walk (already correct for `Ty::Named`/struct fields), not just handle a
/// directly RC-bearing payload type like `str` itself.
#[test]
fn runtime_option_of_struct_wrapping_str_never_matched_does_not_leak_end_to_end() {
    let src = "struct Box<T>:\n    value: T\n\n\
               fn make(s: str) -> Option<Box<str>>:\n    return Option::Some(Box(value = s))\n\n\
               fn main():\n    let mut i: i32 = 0\n    \
               while i < 400000:\n        let b = make(concat(\"item\", \"x\"))\n        i += 1\n    \
               println(\"done\")\n";
    assert_no_leak("option_of_boxed_str_never_matched_leak", src, 20 * 1024 * 1024);
}

/// A `match` over a *fresh* (non-place) payload-enum scrutinee -- a function
/// call result, not an `Ident`/`Field`/other real storage --
/// `TypedExpr::Match`'s codegen (`src/codegen/expr.rs`) addresses such a
/// scrutinee via `Codegen::emit_place`, whose generic fallback spills the
/// already-owned call result into a scratch alloca. Every arm that binds
/// and reads a payload field (`Result::Ok(v) -> v`) reads that binding as
/// an ordinary `Ident`, which retains its own independent duplicate on
/// every use -- but the scrutinee's *own* reference needs the fallback's
/// spilled temporary to be tracked for release, exactly like any other
/// RC-bearing value spilled through that path (see `Codegen::emit_place`'s
/// generic-fallback doc comment in `src/codegen/mod.rs`, generalized in the
/// same bug-hunting round to track *every* RC-bearing type, not just
/// `List`/`Map`/`Set`/`Table` -- which already covers this scrutinee case
/// without a dedicated call site of its own). Confirmed via real unbounded
/// working-set growth (~40MB -> 270MB+ within 3 seconds of 30,000,000
/// iterations) on a hand-written `match Result::Ok(v)/Err(e) -> v/e` with no
/// `?` involved, before that generalization landed.
#[test]
fn runtime_match_over_fresh_result_scrutinee_does_not_leak_end_to_end() {
    let src = "fn first_ok(a: str, b: str) -> Result<str, str>:\n    \
               if len(a) > 0:\n        return Result<str, str>::Ok(a)\n    Result<str, str>::Err(b)\n\n\
               fn unwrap_str(a: str) -> str:\n    \
               match first_ok(a, \"fallback\"):\n        Result::Ok(v) -> v\n        Result::Err(e) -> e\n\n\
               fn main():\n    let mut i: i32 = 0\n    \
               while i < 400000:\n        let r = unwrap_str(concat(\"item\", \"x\"))\n        i += 1\n    \
               println(\"done\")\n";
    assert_no_leak("match_fresh_result_scrutinee_leak", src, 20 * 1024 * 1024);
}

/// The same fix, exercised through `expr?` specifically -- `Checker::
/// infer_try` desugars `?` into exactly the `TypedExpr::Match` shape the
/// test above targets directly (see its own doc comment), so `?`-
/// propagation through a nested call leaked identically before this round's
/// fix. Confirmed via real unbounded working-set growth (~27MB -> 210MB+
/// within 3 seconds) before this fix.
#[test]
fn runtime_try_operator_propagation_does_not_leak_end_to_end() {
    let src = "fn first_ok(a: str, b: str) -> Result<str, str>:\n    \
               if len(a) > 0:\n        return Result<str, str>::Ok(a)\n    Result<str, str>::Err(b)\n\n\
               fn double_wrap(a: str) -> Result<str, str>:\n    \
               let h = first_ok(a, \"fallback\")?\n    Result<str, str>::Ok(concat(h, \"!\"))\n\n\
               fn main():\n    let mut i: i32 = 0\n    \
               while i < 400000:\n        let r = double_wrap(concat(\"item\", \"x\"))\n        i += 1\n    \
               println(\"done\")\n";
    assert_no_leak("try_operator_propagation_leak", src, 20 * 1024 * 1024);
}

/// Control for the `match`-scrutinee-leak fix above: a `match` over a
/// *real* place scrutinee (a struct field, not a fresh call result) must
/// still work correctly and must NOT be double-tracked/double-released --
/// `h.opt`'s own storage is already owned by `h`'s own scope-exit release,
/// so `Codegen::emit_place`'s dedicated `Field` arm (not its generic
/// fallback) resolves it, and no extra tracking happens. This test's
/// oracle is correct *output* across many iterations (not just flat
/// memory), so a double-free corrupting the string would show up as a
/// wrong/garbled result or a crash instead of just a leak.
#[test]
fn runtime_match_over_struct_field_option_scrutinee_still_correct_end_to_end() {
    let src = "struct Holder:\n    opt: Option<str>\n\n\
               fn main():\n    let mut i: i32 = 0\n    let mut last: i32 = -1\n    \
               while i < 200000:\n        let h = Holder(opt = Option::Some(concat(\"item\", \"x\")))\n        \
               let v = match h.opt:\n            Option::Some(s) -> len(s)\n            Option::None -> -1\n        \
               last = v\n        i += 1\n    println(f\"{last}\")\n";
    let output = compile_and_run("match_struct_field_option_scrutinee_control", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "5", "concat(\"item\", \"x\") == \"itemx\" is 5 bytes long: {:?}", output.stdout);
}

/// A struct declared *anywhere* in the source with an `Option<T>`/
/// `Result<T,E>`-typed field (a payload enum) previously baked a
/// permanently wrong LLVM struct type declaration for itself:
/// `Codegen::emit` registered and emitted every struct's/enum's LLVM type
/// in one interleaved pass, in `module.items` order -- but every
/// monomorphized generic enum instantiation (`Option<str>` -> the concrete
/// `Option__str`, appended to the item list by `Checker::check` *after*
/// every item that appears in the source, regardless of where in the
/// source it was first used) is always ordered after a struct that
/// references it. So `Holder`'s own field-type computation
/// (`llvm_ty(Ty::Enum("Option__str"))`, which depends on `enum_is_payload`
/// reading `enum_variant_fields`) always ran before `Option__str`'s own
/// registration, silently defaulting `enum_is_payload` to `false` and
/// mistagging the field as a bare `i32` in `Holder`'s permanent `%Holder =
/// type { .. }` text instead of the real multi-word `%Option__str` tagged
/// union. Every later store of a full `Option<str>` value into that field
/// then wrote past the single `i32` slot LLVM/`clang` had actually sized
/// for it, corrupting adjacent stack memory. Confirmed via a real `star
/// build`+run segfaulting (`ExitStatus` `0xC0000005`, an access violation)
/// on exactly this minimal shape -- one loop iteration, no `Table`/`Ring`/
/// nested-generics involved at all -- before this fix. Fixed by splitting
/// registration (`Codegen::register_struct`/`register_enum`, populating
/// `struct_field_types`/`enum_variant_fields` with no LLVM text emitted)
/// out of text emission (`emit_struct_decl`/`emit_enum_decl`) into two
/// separate passes over every item, so every enum a struct field might
/// reference (and vice versa) is fully registered before any type's text
/// is emitted -- LLVM's textual IR allows named struct types to reference
/// each other regardless of which is declared first, so only the
/// *registration data* needed reordering, not the emitted text itself.
#[test]
fn runtime_struct_field_typed_as_generic_payload_enum_end_to_end() {
    let src = "struct Holder:\n    opt: Option<str>\n\n\
               fn main():\n    let h = Holder(opt = Option::Some(concat(\"hello\", \" world\")))\n    \
               match h.opt:\n        Option::Some(s) -> println(s)\n        Option::None -> println(\"none\")\n";
    let output = compile_and_run("struct_field_generic_payload_enum", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "hello world");
}

/// Same bug, `Result<T,E>` instead of `Option<T>` (a two-type-argument
/// generic enum, wider payload than `Option`'s single-field `Some`) as a
/// struct field, plus a second, unrelated struct declared *after* it in
/// source order -- guards against the fix only working for the first
/// struct/enum pair in the module or only for the single-type-argument
/// case.
#[test]
fn runtime_struct_field_typed_as_generic_result_end_to_end() {
    let src = "struct Holder:\n    res: Result<i32, str>\n\nstruct Other:\n    tag: i32\n\n\
               fn main():\n    let h = Holder(res = Result<i32, str>::Ok(42))\n    let o = Other(tag = 7)\n    \
               match h.res:\n        Result::Ok(v) -> println(f\"ok:{v}\")\n        Result::Err(e) -> println(f\"err:{e}\")\n    \
               println(f\"other:{o.tag}\")\n";
    let output = compile_and_run("struct_field_generic_result", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.lines().collect::<Vec<_>>(), vec!["ok:42", "other:7"], "{}", stdout);
}
