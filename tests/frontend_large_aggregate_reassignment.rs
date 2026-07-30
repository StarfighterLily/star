//! Regression tests for `todo.md` P2 #4: reassigning an *existing* large
//! struct/array binding (`x = <call returning a large aggregate>`, as
//! opposed to a fresh `let x = ...`) used to fall through to the generic
//! `TypedStmt::Assign` path -- `emit_expr(value)` then `store_target`,
//! neither of which `TypedStmt::Let`'s own `is_large_aggregate_ty` branch
//! (`tests/frontend_large_aggregate_by_value.rs`) special-cases. That
//! generic path still materializes the whole aggregate as one SSA value
//! (`emit_call_expr`'s own "rarer generic value consumer" fallback: alloca a
//! temp, call into it via `sret`, then `load` the entire thing back out) and
//! then `store`s that whole value a second time -- exactly the two-copies-
//! of-a-giant-aggregate-value shape `NOTES.md`'s "Seven Star compiler bugs
//! found and fixed" #1 fixed for construction, and `todo.md` P0 #2 fixed for
//! return/parameter passing, but neither ever covered reassignment.
//!
//! Found via a minimal, project-independent repro built for `todo.md` P2 #4
//! (which asked to confirm or rule out whether the `clang` build-time
//! pathology found while wiring up `projects/nova/main.star`'s `Reset`
//! button -- "several minutes and multiple gigabytes of `clang` memory just
//! to reach the link step", `NOTES.md`'s "A real build-time finding along
//! the way" -- was this same gap or a new one). A straight-line `let a = f()
//! ; let b = f() ; let c = f()` with a 1,000,000-byte struct compiled in
//! under a second (three separate `Let`s, each hitting the already-fixed
//! branch); the *real* Nova shape -- one `let mut cpu = f()` followed by
//! `cpu = f()` reassignments inside `if` branches of a `while` loop, mirroring
//! `main.star`'s per-frame `Reset`-on-hotkey/toolbar-click logic -- reliably
//! reproduced it: 11m19s of wall time before `clang-22` itself crashed
//! (exit code `2147483647`), peaking above 3.4GB of resident memory. This is
//! confirmed to be *this* gap, not a recurrence of the already-fixed
//! construction/return/parameter shapes.
//!
//! Fixed in `TypedStmt::Assign` (`src/codegen/stmt.rs`): a plain (`=`, not
//! `+=`/...) assignment whose RHS type is a large aggregate (and whose
//! target isn't a bare `TypedExpr::TableIndex`, which has no contiguous
//! storage for `Codegen::emit_place` to resolve -- see its own doc comment)
//! now builds the new value into a private temp via `Codegen::emit_into_ptr`
//! (safe for `x = x`/self-referential RHS, since a fresh temp can never
//! alias the place being overwritten), releases the target's old contents,
//! then `memcpy`s the temp over the target's real storage -- never a
//! whole-aggregate `load`/`store` pair. Re-running the exact repro above
//! after the fix: 2.4 seconds, correct output.
//!
//! The codegen-shape test below uses `Driver::codegen` only (no `clang`), the
//! same safety rationale `tests/frontend_large_aggregate_by_value.rs` already
//! uses for its own megabyte-scale shape assertion. The runtime tests use an
//! 8192-byte field -- comfortably above `Codegen::LARGE_AGGREGATE_THRESHOLD`
//! (proving the fix's memcpy path is what actually runs) but small enough to
//! compile and run instantly even if a regression reintroduced a whole-value
//! copy at this size.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

/// `x = f()` where `f` returns a huge (`1,000,000`-byte) struct must lower to
/// the temp-alloca/`emit_into_ptr`/`memcpy` shape, never a whole-aggregate
/// `load`/`store` pair -- also asserts codegen itself stays near-instant
/// despite the size, mirroring
/// `codegen_large_struct_trailing_literal_return_uses_sret_not_by_value`
/// (`tests/frontend_large_aggregate_by_value.rs`) for the reassignment shape.
#[test]
fn codegen_large_struct_reassignment_uses_memcpy_not_whole_value_store() {
    let src = "struct Big:\n    data: [u8; 1000000]\n    tag: i32\n\n\
               fn make(t: i32) -> Big:\n    Big(data = [7 as u8; 1000000], tag = t)\n\
               fn main():\n    let mut b = make(1)\n    b = make(2)\n    println(f\"{b.tag}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let start = std::time::Instant::now();
    let ir = Driver::codegen(&typed).expect("should codegen");
    let elapsed = start.elapsed();
    assert!(elapsed.as_secs() < 5, "codegen for a reassigned 1,000,000-byte struct took {:?} -- should be near-instant", elapsed);

    let body = extract_fn_body(&ir, "define i32 @main(");
    assert!(body.matches("@memcpy").count() >= 1, "expected the reassignment to `memcpy` into the target's storage: {}", body);
    assert!(!body.contains("store %Big"), "must never `store` the whole struct by value: {}", body);
    assert!(!body.contains("load %Big,"), "must never load the whole struct into an SSA value: {}", body);
}

const BIG_SRC_PREFIX: &str = "struct Big:\n    mut data: [u8; 8192]\n    mut tag: i32\n\n";

/// The core motivating scenario: reassigning an existing large-struct
/// binding to a fresh constructor call's result must actually replace the
/// value (not silently no-op, alias, or corrupt it).
#[test]
fn runtime_large_struct_reassignment_replaces_value_end_to_end() {
    let src = format!(
        "{}fn make(t: i32) -> Big:\n    Big(data = [t as u8; 8192], tag = t)\n\
         fn main():\n    let mut b = make(1)\n    b = make(2)\n    println(f\"{{b.tag}} {{b.data[0]}} {{b.data[8191]}}\")\n",
        BIG_SRC_PREFIX
    );
    let output = compile_and_run("large_struct_reassignment_replaces_value", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "2 2 2", "{}", stdout);
}

/// The exact real-world shape this bug was found in: a large-struct local
/// reassigned from inside `if` branches nested in a `while` loop (mirroring
/// `projects/nova/main.star`'s per-frame hotkey/toolbar-click `Reset`
/// handling) -- not just a straight-line sequence of reassignments.
#[test]
fn runtime_large_struct_reassignment_inside_conditional_in_loop_end_to_end() {
    let src = format!(
        "{}fn make(t: i32) -> Big:\n    Big(data = [t as u8; 8192], tag = t)\n\
         fn main():\n    let mut cpu = make(0)\n    let mut i = 0\n    let mut running = true\n    \
         while running:\n        if i == 1:\n            cpu = make(1)\n        if i == 2:\n            cpu = make(2)\n        \
         i = i + 1\n        if i > 3:\n            running = false\n    \
         println(f\"{{cpu.tag}} {{cpu.data[0]}}\")\n",
        BIG_SRC_PREFIX
    );
    let output = compile_and_run("large_struct_reassignment_conditional_loop", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "2 2", "{}", stdout);
}

/// `b = b` (self-assignment of a large struct) must not corrupt or crash --
/// the fix builds the RHS into a private temp *before* releasing/overwriting
/// the target specifically so this stays safe (a fresh temp can never alias
/// the place being overwritten, unlike writing straight into the target and
/// releasing around it).
#[test]
fn runtime_large_struct_self_assignment_is_safe_end_to_end() {
    let src = format!(
        "{}fn main():\n    let mut b = Big(data = [9 as u8; 8192], tag = 7)\n    b = b\n    \
         println(f\"{{b.tag}} {{b.data[0]}} {{b.data[8191]}}\")\n",
        BIG_SRC_PREFIX
    );
    let output = compile_and_run("large_struct_self_assignment", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "7 9 9", "{}", stdout);
}

/// Reassigning a large struct that also carries an RC-owning (`str`) field,
/// repeatedly in a loop -- exercises `Codegen::emit_release_at`'s interaction
/// with the new memcpy-based reassignment path (the old label must be
/// released on every reassignment, not leaked, and never double-released).
/// Mirrors `runtime_large_struct_with_rc_field_round_trips_through_return_
/// and_param_end_to_end` (`tests/frontend_large_aggregate_by_value.rs`), but
/// through repeated `Assign` into one binding instead of a fresh `let` each
/// iteration.
#[test]
fn runtime_large_struct_reassignment_with_rc_field_in_loop_end_to_end() {
    let src = "struct Big:\n    mut data: [u8; 8192]\n    mut tag: i32\n    mut label: str\n\n\
               fn make(s: str) -> Big:\n    Big(data = [1 as u8; 8192], tag = 1, label = s)\n\
               fn main():\n    let mut b = make(\"start\")\n    let mut i = 0\n    \
               while i < 20:\n        b = make(\"hello\")\n        println(b.label)\n        i = i + 1\n"
        .to_string();
    let output = compile_and_run("large_struct_reassignment_rc_field_loop", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.trim_end().lines().collect();
    assert_eq!(lines.len(), 20, "{}", stdout);
    assert!(lines.iter().all(|l| *l == "hello"), "every iteration should read back the freshly assigned label: {}", stdout);
}

/// A large struct field *inside another struct*, reassigned through
/// `container.big = f()` -- exercises `Codegen::emit_place`'s `Field` arm
/// (a GEP into the container, not a bare local lookup) rather than the
/// simpler `Ident` case every other test here uses.
#[test]
fn runtime_large_struct_field_reassignment_end_to_end() {
    let src = format!(
        "{}struct Holder:\n    mut inner: Big\n\n\
         fn make(t: i32) -> Big:\n    Big(data = [t as u8; 8192], tag = t)\n\
         fn main():\n    let mut h = Holder(inner = make(1))\n    h.inner = make(2)\n    \
         println(f\"{{h.inner.tag}} {{h.inner.data[0]}} {{h.inner.data[8191]}}\")\n",
        BIG_SRC_PREFIX
    );
    let output = compile_and_run("large_struct_field_reassignment", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "2 2 2", "{}", stdout);
}
