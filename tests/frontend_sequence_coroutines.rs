//! M7: `sequence`/`yield` coroutines
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== M7 Concurrency & Coroutines Tests ==================================

// --- `sequence` / `yield` (coroutines) ------------------------------------

/// Parse a `sequence` item with params and multiple `yield`s.
#[test]
fn parses_sequence_def() {
    let src = "sequence Countdown(start: i32):\n    let mut n: i32 = start\n    yield\n    n -= 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Sequence(seq) = &module.items[0] else { panic!("expected a sequence item") };
    assert_eq!(seq.name, "Countdown");
    assert_eq!(seq.params.len(), 1);
    assert!(matches!(seq.body.stmts[1], Stmt::Yield { .. }));
}

/// A bare `yield` statement parses on its own (e.g. inside any block).
#[test]
fn parses_yield_stmt() {
    let src = "sequence S():\n    yield\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Sequence(seq) = &module.items[0] else { panic!("expected a sequence item") };
    assert!(matches!(seq.body.stmts[0], Stmt::Yield { .. }));
}

/// Desugaring turns one `sequence` into a `struct` + `impl` pair: fields are
/// params + hoisted locals + a trailing `state`, and there's a single
/// `resume` method.
#[test]
fn desugars_sequence_to_struct_and_impl() {
    let src = "sequence Countdown(start: i32):\n    let mut n: i32 = start\n    yield\n    n -= 1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    // 2 (Countdown's own struct + impl) + 7 always-present builtin geometry
    // structs (`docs/design.md`'s "Math and geometry" section --
    // `Rect`/`Aabb2`/`Aabb3`/`Transform`/`Ray`/`Plane`/`Frustum`), appended
    // after every user item regardless of source -- see `Checker::check`'s
    // `builtin_struct_items`. User items always come first, so `items[0]`/
    // `items[1]` below are unaffected.
    assert_eq!(typed.items.len(), 9, "sequence should desugar to exactly struct + impl, plus 7 builtin geometry structs");

    let TypedItem::Struct(s) = &typed.items[0] else { panic!("expected a struct") };
    assert_eq!(s.name, "Countdown");
    let field_names: Vec<&str> = s.fields.iter().map(|f| f.name.as_str()).collect();
    assert_eq!(field_names, vec!["start", "n", "state"]);

    let TypedItem::Impl(i) = &typed.items[1] else { panic!("expected an impl") };
    assert_eq!(i.type_name, "Countdown");
    assert_eq!(i.methods.len(), 1);
    assert_eq!(i.methods[0].sig.name, "resume");
    assert_eq!(i.methods[0].sig.ret, Some(Ty::Bool));
}

/// `yield` outside any `sequence` body is a type error.
#[test]
fn rejects_yield_outside_sequence() {
    let module = Driver::parse("fn t():\n    yield\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "bare yield should be a type error");
}

/// `yield` nested inside `if`/`while`/`frame` inside a sequence is rejected
/// (only top-level yield is supported by this desugaring).
#[test]
fn rejects_nested_yield_in_sequence() {
    let module = Driver::parse("sequence S(x: i32):\n    if x > 0:\n        yield\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "nested yield should be a type error");
}

/// A hoisted sequence local without an explicit type annotation is rejected
/// (its type can't be inferred at desugar time, before type checking runs).
#[test]
fn rejects_untyped_sequence_local() {
    let module = Driver::parse("sequence S(x: i32):\n    let n = x\n    yield\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "untyped hoisted local should be a type error");
}

/// A hoisted sequence local named `state` must be rejected -- `state: i32`
/// is unconditionally appended as the desugared struct's own resume-dispatch
/// counter field (`Sequence::desugar_sequence`), so a user-declared local of
/// the same name previously shared that one struct field with no renaming:
/// the coroutine's own "advance to next segment" write silently clobbered
/// whatever value the user's `state` local held, and vice versa, with no
/// diagnostic anywhere.
#[test]
fn rejects_sequence_local_named_state() {
    let module = Driver::parse("sequence S(x: i32):\n    let mut state: i32 = 5\n    yield\n    state += 1\n    yield\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("a sequence local named `state` should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("reserved field name")), "{:?}", diags);
}

/// Same fix, parameter side: a sequence parameter named `state` collides
/// with the same reserved dispatch field.
#[test]
fn rejects_sequence_param_named_state() {
    let module = Driver::parse("sequence S(state: i32):\n    yield\n    println(f\"{state}\")\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("a sequence parameter named `state` should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("reserved parameter name")), "{:?}", diags);
}

/// Codegen for the desugared `resume` uses a nested `if`/`else` chain that
/// compares against `state` and returns a bool per segment.
#[test]
fn codegen_sequence_uses_state_machine() {
    let src = "sequence Countdown(start: i32):\n    let mut n: i32 = start\n    yield\n    n -= 1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("%Countdown = type"), "{}", ir);
    assert!(ir.contains("define i1 @Countdown__resume(%Countdown* %self)"), "{}", ir);
    assert!(ir.contains("icmp eq i32"), "state comparison should appear: {}", ir);
    assert!(ir.matches("ret i1").count() >= 2, "each segment should be able to return a bool: {}", ir);
}

/// Runtime test: the compiled `sequence.exe` ticks through a 3-step
/// coroutine (two `yield`s) via repeated `resume()` calls until it reports
/// done, end to end through a real clang-compiled executable.
#[test]
fn runtime_sequence_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/sequence.exe").output().expect("failed to execute sequence.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    // Windows text-mode stdout translates the `\n` in each `print` to `\r\n`,
    // so check ordering by byte offset rather than matching a literal
    // multi-line substring.
    let pos = |needle: &str| stdout.find(needle).unwrap_or_else(|| panic!("missing {:?} in: {}", needle, stdout));
    let (p3, p2, p1, lift, done) =
        (pos("tick: 3"), pos("tick: 2"), pos("tick: 1"), pos("liftoff"), pos("sequence done"));
    assert!(p3 < p2 && p2 < p1 && p1 < lift && lift < done, "coroutine should tick in order: {}", stdout);
}
