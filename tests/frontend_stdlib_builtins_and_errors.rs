//! M8 standard library builtins and checker error messages
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== M8 Standard library ==================================================

/// `print`/`println` calls, and the math/string builtins, resolve to proper
/// (non-`unknown`) types through the checker even though none of them are
/// declared by any `fn` item.
#[test]
fn checks_builtin_return_types() {
    let src = "fn t():\n    let a: i32 = abs(-5)\n    let b: float = sqrt(4.0)\n    let c: i32 = len(\"hi\")\n    let d: str = concat(\"a\", \"b\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[0] else { panic!("expected fn") };
    let get_value_ty = |i: usize| match &f.body.stmts[i] {
        TypedStmt::Let { value, .. } => value.clone().into_ty(),
        other => panic!("expected let, got {:?}", other),
    };
    assert_eq!(get_value_ty(0), Ty::Int);
    assert_eq!(get_value_ty(1), Ty::Float);
    assert_eq!(get_value_ty(2), Ty::Int);
    assert_eq!(get_value_ty(3), Ty::Str);
}

/// `read_line()` (no arguments) resolves to `str` through the checker, same
/// as `concat`'s return type.
#[test]
fn checks_read_line_return_type() {
    let src = "fn t():\n    let line: str = read_line()\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[0] else { panic!("expected fn") };
    let TypedStmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    assert_eq!(value.clone().into_ty(), Ty::Str);
}

/// `abs`/`min`/`max` preserve the numeric type of their arguments (Int stays
/// Int) rather than always widening to Float.
#[test]
fn checks_abs_min_max_preserve_int_type() {
    let src = "fn t():\n    let a: i32 = abs(-5)\n    let b: i32 = min(1, 2)\n    let c: i32 = max(1, 2)\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "int-typed abs/min/max should type-check as i32");
}

/// `println` guarantees a trailing newline even for a plain (non-f-string)
/// argument, unlike `print`, which passes such an argument straight through
/// to `printf` with no newline appended.
#[test]
fn codegen_println_appends_newline_for_plain_string() {
    let src = "fn t():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    // One `printf` call for the literal itself, and a second for the
    // guaranteed trailing newline byte.
    let printf_calls = ir.matches("call i32 (i8*, ...) @printf(").count();
    assert_eq!(printf_calls, 2, "println should emit the string then a newline: {}", ir);
}

/// `print` with a plain (non-f-string) argument does *not* append a newline
/// -- only one `printf` call is emitted.
#[test]
fn codegen_print_does_not_append_newline_for_plain_string() {
    let src = "fn t():\n    print(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let printf_calls = ir.matches("call i32 (i8*, ...) @printf(").count();
    assert_eq!(printf_calls, 1, "print should not append a newline: {}", ir);
}

/// Runtime test: `examples/stdlib.exe` exercises `println`, every math
/// builtin, `len`/`concat`, and a non-`main` free function calling another
/// free function, end to end through a real compiled binary.
#[test]
fn runtime_stdlib_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/stdlib.exe").output().expect("failed to execute stdlib.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("sum: 5"), "free function call result: {}", stdout);
    assert!(stdout.contains("sqrt: 4.000000"), "{}", stdout);
    assert!(stdout.contains("pow: 1024.000000"), "{}", stdout);
    assert!(stdout.contains("abs int: 5"), "{}", stdout);
    assert!(stdout.contains("abs float: 5.500000"), "{}", stdout);
    assert!(stdout.contains("floor: 3.000000"), "{}", stdout);
    assert!(stdout.contains("ceil: 4.000000"), "{}", stdout);
    assert!(stdout.contains("clamped: 100"), "min/max clamp result: {}", stdout);
    assert!(stdout.contains("name len: 4"), "{}", stdout);
    assert!(stdout.contains("greeting: hello, Hero"), "concat result: {}", stdout);
}

/// Runtime test: `examples/stdin.exe` exercises `read_line()` end to end
/// through a real compiled binary fed piped stdin, including reading past
/// the last available line (EOF), which should yield an empty `str` rather
/// than crashing or hanging.
#[test]
fn runtime_read_line_end_to_end() {
    use std::io::Write;
    use std::process::{Command, Stdio};

    let mut child = Command::new("examples/stdin.exe")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .expect("failed to spawn stdin.exe");
    child
        .stdin
        .take()
        .expect("child stdin should be piped")
        .write_all(b"Alice\nBob\n")
        .expect("failed to write to child stdin");
    let output = child.wait_with_output().expect("failed to wait on stdin.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("hello, Alice"), "first read_line() call: {}", stdout);
    assert!(stdout.contains("again: Bob"), "second read_line() call: {}", stdout);
    assert!(stdout.contains("last: "), "read_line() past EOF should yield an empty str, not crash: {}", stdout);
    assert_eq!(output.status.code(), Some(0));
}

/// A `read_line()` call whose input line is longer than the builtin's fixed
/// 1024-byte capacity is truncated rather than overflowing the buffer or
/// crashing -- same bounded-buffer trade-off `frame:` blocks already make
/// (see `Codegen::emit_read_line`).
#[test]
fn runtime_read_line_truncates_oversized_input() {
    use std::io::Write;
    use std::process::{Command, Stdio};

    let mut child = Command::new("examples/stdin.exe")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .expect("failed to spawn stdin.exe");
    let long_line = "a".repeat(2000);
    let input = format!("{}\nshort\n", long_line);
    child
        .stdin
        .take()
        .expect("child stdin should be piped")
        .write_all(input.as_bytes())
        .expect("failed to write to child stdin");
    let output = child.wait_with_output().expect("failed to wait on stdin.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains(&"a".repeat(1023)), "truncated line should keep its first 1023 bytes: {}", stdout);
    assert!(!stdout.contains(&"a".repeat(1024)), "truncated line should not exceed 1023 bytes: {}", stdout);
    assert_eq!(output.status.code(), Some(0));
}

// ===== M8 Error messages ====================================================

/// An unknown field access on a known struct is now caught at type-check
/// time (with the access's own span, not a codegen-time dummy span), and
/// carries a "did you mean" note when a field name is a close typo.
#[test]
fn rejects_unknown_field_with_suggestion() {
    let src = "struct Player:\n    health: i32\n\nfn t(p: Player):\n    p.helth\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("unknown field should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("no field `helth`")), "{:?}", diags);
    assert!(
        diags.iter().any(|d| d.note.as_deref().unwrap_or("").contains("health")),
        "expected a `did you mean health?` note: {:?}",
        diags
    );
}

/// Field access on a type that has no fields at all -- `Mat4` (a builtin
/// SIMD matrix with no named-field accessor, unlike `Vec2`/`Vec3`/`Vec4`'s
/// GLSL-style swizzles), here -- must be caught at type-check time with a
/// located diagnostic, the same as an unknown field on a real struct just
/// above. `Checker::resolve_field_type`'s catch-all for any non-`Named`,
/// non-vector base type used to silently return the `unknown` placeholder
/// type with *no* diagnostic at all, letting `m.anything` type-check
/// cleanly and only fail much later at codegen with an unlocated "field
/// access on non-struct type" that names neither the field nor its type.
/// Confirmed via a real `star build`: before the fix, `target/release/
/// star.exe build` on this exact source produced only that unlocated
/// codegen error and no earlier diagnostic; after the fix, `Driver::check`
/// itself rejects it with a proper span. The same catch-all also covers
/// `Tick`/`Duration`/`Instant`, every numeric width, `str`, `bool`,
/// `List<T>`/`Map<K,V>`/`Set<T>`/`Table<T>`, and enum values -- `Mat4` is
/// the representative case for this audit's vector/matrix focus.
#[test]
fn rejects_field_access_on_fieldless_builtin_type() {
    let src = "fn t():\n    let m = Mat4(\n        Vec4(1.0, 0.0, 0.0, 0.0),\n        Vec4(0.0, 1.0, 0.0, 0.0),\n        Vec4(0.0, 0.0, 1.0, 0.0),\n        Vec4(0.0, 0.0, 0.0, 1.0),\n    )\n    m.bogus_field\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("field access on Mat4 should be a type error") };
    assert!(
        diags.iter().any(|d| d.message.contains("no field `bogus_field`") && d.message.contains("Mat4")),
        "{:?}",
        diags
    );
}

/// Same bug, exercised on `Instant` (this audit's other headline type):
/// field access on a nominal `i64`-backed time type has no legitimate
/// meaning and must be a located type error, not a silent pass-through
/// that only fails at codegen.
#[test]
fn rejects_field_access_on_time_type() {
    let src = "fn t():\n    let i = Instant(5 as i64)\n    i.nanos\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("field access on Instant should be a type error") };
    assert!(
        diags.iter().any(|d| d.message.contains("no field `nanos`") && d.message.contains("Instant")),
        "{:?}",
        diags
    );
}

/// An `impl` for an undefined type gets a "did you mean" note when a struct
/// name is a close typo.
#[test]
fn rejects_undefined_impl_type_with_suggestion() {
    let src = "struct Player:\n    health: i32\n\nimpl Playr:\n    fn reset(mut self):\n        self.health = 100\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("undefined impl type should be a type error") };
    assert!(
        diags.iter().any(|d| d.note.as_deref().unwrap_or("").contains("Player")),
        "expected a `did you mean Player?` note: {:?}",
        diags
    );
}

/// A parser error for a missing token now names the token in friendly
/// syntax (`':'`) rather than the raw Rust enum spelling (`Colon`).
#[test]
fn parser_error_uses_friendly_token_names() {
    let src = "struct Player\n    health: i32\n";
    let Err(diags) = Driver::parse(src) else { panic!("missing ':' should be a parse error") };
    assert!(diags.iter().any(|d| d.message.contains("':'")), "{:?}", diags);
}
