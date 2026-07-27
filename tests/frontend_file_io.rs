//! File I/O builtins
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== File I/O builtins (todo.md "Next Steps" #2) =========================
//
// `file_open` returns `ptr` (null on failure, same convention as `getenv`);
// `file_read`/`file_read_line` return `str` (empty on EOF, same convention as
// `read_line`); `file_write`/`file_exists` return `bool`; a null/closed
// handle passed to `file_read`/`file_read_line`/`file_write`/`file_close` is
// a programmer error and aborts loudly (same convention as frame overflow /
// integer division by zero). See `crate::codegen::file_io`.

/// `file_open` type-checks to `ptr`.
#[test]
fn checks_file_open_returns_ptr() {
    let src = "fn t():\n    let h: ptr = file_open(\"x.txt\", \"r\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("file_open(..) should type-check as ptr");
}

/// `file_read`/`file_read_line` type-check to `str`.
#[test]
fn checks_file_read_and_read_line_return_str() {
    let src = "fn t():\n    let h = file_open(\"x.txt\", \"r\")\n    let a: str = file_read(h)\n    let b: str = file_read_line(h)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("file_read/file_read_line should type-check as str");
}

/// `file_write`/`file_exists` type-check to `bool`.
#[test]
fn checks_file_write_and_exists_return_bool() {
    let src = "fn t():\n    let h = file_open(\"x.txt\", \"w\")\n    let ok: bool = file_write(h, \"data\")\n    let e: bool = file_exists(\"x.txt\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("file_write/file_exists should type-check as bool");
}

/// `file_read` sizes its buffer via `ftell`/`fseek` and allocates through
/// `star_rc_alloc` (a fresh owned `str`), not a bare `malloc`.
#[test]
fn codegen_file_read_uses_ftell_fseek_and_rc_alloc() {
    let src = "fn t() -> str:\n    let h = file_open(\"x.txt\", \"r\")\n    file_read(h)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i8* @t(");
    assert!(fn_ir.contains("call i32 @ftell"), "{}", fn_ir);
    assert!(fn_ir.contains("call i32 @fseek"), "{}", fn_ir);
    assert!(fn_ir.contains("call i8* @star_rc_alloc"), "{}", fn_ir);
    assert!(fn_ir.contains("call i64 @fread"), "{}", fn_ir);
}

/// `file_read_line` reads from the given handle via `@fgetc`, not the
/// stdin-only `@getchar` `read_line()` uses.
#[test]
fn codegen_file_read_line_uses_fgetc_not_getchar() {
    let src = "fn t() -> str:\n    let h = file_open(\"x.txt\", \"r\")\n    file_read_line(h)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i8* @t(");
    assert!(fn_ir.contains("call i32 @fgetc"), "{}", fn_ir);
    assert!(!fn_ir.contains("@getchar"), "file_read_line must not read from stdin: {}", fn_ir);
}

/// `file_close` on a possibly-null handle checks for null and aborts (`exit`
/// + `unreachable`) before ever calling `@fclose`, matching the frame
/// overflow / division-by-zero abort shape elsewhere in this codegen.
#[test]
fn codegen_file_close_aborts_on_null_handle() {
    let src = "fn t():\n    let h = file_open(\"x.txt\", \"r\")\n    file_close(h)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define void @t(");
    assert!(fn_ir.contains("icmp eq i8* "), "should compare the handle against null: {}", fn_ir);
    assert!(fn_ir.contains("call void @exit(i32 1)"), "should abort on a null handle: {}", fn_ir);
    assert!(fn_ir.contains("unreachable"), "{}", fn_ir);
    assert!(fn_ir.contains("call i32 @fclose"), "the ok path should still call fclose: {}", fn_ir);
}

/// Opens a file for writing, writes two `file_write` calls, closes it,
/// reopens for reading, and reads the exact content back via `file_read` --
/// the basic round trip the whole feature exists for (todo.md: "read config,
/// save/load game state").
#[test]
fn runtime_file_write_then_read_end_to_end() {
    let path = scratch_file_path("star_test_file_write_then_read.txt");
    let src = format!(
        "fn main():\n    let p = \"{p}\"\n    let w = file_open(p, \"w\")\n    file_write(w, \"hello \")\n    file_write(w, \"world\")\n    file_close(w)\n    let r = file_open(p, \"r\")\n    let content = file_read(r)\n    file_close(r)\n    println(content)\n",
        p = path
    );
    let output = compile_and_run("file_write_then_read", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "hello world", "file_read should return exactly what file_write wrote: {}", stdout);
    let _ = std::fs::remove_file(&path);
}

/// Writes a 3-line file, then reads it back one line at a time with
/// `file_read_line`; a fourth call past the last line yields an empty `str`
/// rather than crashing or hanging -- the same EOF convention `read_line()`
/// already established for stdin.
#[test]
fn runtime_file_read_line_end_to_end() {
    let path = scratch_file_path("star_test_file_read_line.txt");
    let src = format!(
        "fn main():\n    let p = \"{p}\"\n    let w = file_open(p, \"w\")\n    file_write(w, \"alpha\\nbeta\\ngamma\\n\")\n    file_close(w)\n    let r = file_open(p, \"r\")\n    println(file_read_line(r))\n    println(file_read_line(r))\n    println(file_read_line(r))\n    let last = file_read_line(r)\n    println(f\"last:{{last}}\")\n    file_close(r)\n",
        p = path
    );
    let output = compile_and_run("file_read_line", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["alpha", "beta", "gamma", "last:"], "{}", stdout);
}

/// `file_exists` is `true` for a file that was just created and `false` for
/// a path that was never created.
#[test]
fn runtime_file_exists_end_to_end() {
    let real_path = scratch_file_path("star_test_file_exists_real.txt");
    let missing_path = scratch_file_path("star_test_file_exists_missing.txt");
    let _ = std::fs::remove_file(&missing_path);
    let src = format!(
        "fn main():\n    let real = \"{real}\"\n    let missing = \"{missing}\"\n    let w = file_open(real, \"w\")\n    file_write(w, \"x\")\n    file_close(w)\n    println(f\"{{file_exists(real)}}\")\n    println(f\"{{file_exists(missing)}}\")\n",
        real = real_path,
        missing = missing_path
    );
    let output = compile_and_run("file_exists", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "false"], "{}", stdout);
    let _ = std::fs::remove_file(&real_path);
}

/// `file_open` on a path that doesn't exist (opened for reading) returns a
/// null `ptr`, checked with the existing `is_null(..)` builtin -- the exact
/// convention `getenv` already established for a foreign call that can fail.
#[test]
fn runtime_file_open_missing_file_returns_null_end_to_end() {
    let missing_path = scratch_file_path("star_test_file_open_missing.txt");
    let _ = std::fs::remove_file(&missing_path);
    let src = format!(
        "fn main():\n    let h = file_open(\"{p}\", \"r\")\n    println(f\"{{is_null(h)}}\")\n",
        p = missing_path
    );
    let output = compile_and_run("file_open_missing", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "true", "{}", stdout);
}

/// `file_write` reports `true` on an ordinary successful write.
#[test]
fn runtime_file_write_reports_true_on_success_end_to_end() {
    let path = scratch_file_path("star_test_file_write_success.txt");
    let src = format!(
        "fn main():\n    let w = file_open(\"{p}\", \"w\")\n    let ok = file_write(w, \"data\")\n    file_close(w)\n    println(f\"{{ok}}\")\n",
        p = path
    );
    let output = compile_and_run("file_write_success", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "true", "{}", stdout);
    let _ = std::fs::remove_file(&path);
}

/// Calling `file_read` on a null handle (from a failed `file_open`, used
/// without an `is_null(..)` check) aborts loudly with a diagnostic and a
/// nonzero exit code instead of crashing/segfaulting or hanging -- mirrors
/// `runtime_frame_overflow_aborts_loudly_instead_of_segfaulting` and
/// `runtime_int_division_by_zero_aborts_loudly_instead_of_trapping`'s "trap
/// loudly instead of corrupting/crashing unpredictably" guarantee.
#[test]
fn runtime_file_read_aborts_on_null_handle_end_to_end() {
    let missing_path = scratch_file_path("star_test_file_read_null_handle.txt");
    let _ = std::fs::remove_file(&missing_path);
    let src = format!(
        "fn main():\n    let h = file_open(\"{p}\", \"r\")\n    println(\"before\")\n    let content = file_read(h)\n    println(\"should not reach here\")\n",
        p = missing_path
    );
    let output = compile_and_run("file_read_null_handle", &src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "must abort before the null handle is ever read: {}", stdout);
    assert!(stdout.contains("null/closed file handle"), "should print a diagnostic: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "should exit cleanly with code 1, not crash/segfault: {:?}", output.status);
}

/// Calling `ptr_to_str` on a null `ptr` (e.g. an `extern "C"` function's
/// null-on-failure return, read without an `is_null(..)` check first --
/// exactly the shape `examples/extern_ffi.star` demonstrates checking
/// *before* calling `ptr_to_str`, but nothing enforced that check actually
/// happens) aborts loudly with a diagnostic and a nonzero exit code, instead
/// of segfaulting: `Codegen::emit_ptr_to_str` (`src/codegen/builtins.rs`)
/// used to call `strlen` on its argument with no null check at all, an
/// unguarded null-pointer dereference, unlike every other `ptr`-handle
/// builtin in this codegen (`file_close`/`file_read`/`tcp_send`/...), all of
/// which already abort loudly on a null handle via their own
/// `abort_if_null_handle`/`abort_if_null_socket` guards. Confirmed via a
/// real, unguarded segfault building and running `ptr_to_str(null_ptr())`
/// before this fix. Mirrors `runtime_file_read_aborts_on_null_handle_end_to_
/// end`'s shape.
#[test]
fn runtime_ptr_to_str_aborts_on_null_ptr_end_to_end() {
    let src = "fn main():\n    let p = null_ptr()\n    println(\"before\")\n    let s = ptr_to_str(p)\n    println(\"should not reach here\")\n";
    let output = compile_and_run("ptr_to_str_null_ptr", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "must abort before the null ptr is ever read: {}", stdout);
    assert!(stdout.contains("ptr_to_str(..) called with a null ptr"), "should print a diagnostic: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "should exit cleanly with code 1, not crash/segfault: {:?}", output.status);
}

/// Every builtin call (not just ordinary/extern-fn calls) now has its
/// argument count and types validated by `Checker::check_builtin_call_args`,
/// ahead of `crate::codegen::file_io`'s own `args.len() < N` codegen-time
/// checks -- so a wrong argument count is now caught cleanly at type-check
/// time instead of surfacing only once codegen runs (previously the only
/// place this was caught at all; see `checker_rejects_file_open_wrong_arg_count`
/// for the same case one stage earlier, and `checker_rejects_file_open_wrong_arg_types`
/// for the argument-type checks this also added). `file_io.rs`'s own
/// `args.len() < N` guards stay in place as a defense-in-depth fallback.
#[test]
fn checker_rejects_file_open_wrong_arg_count() {
    let src = "fn t():\n    file_open(\"x.txt\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("file_open with 1 argument should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`file_open` expects 2 argument(s)")), "{:?}", diags);
}

/// Same check for `file_write`, which also takes 2 arguments.
#[test]
fn checker_rejects_file_write_wrong_arg_count() {
    let src = "fn t():\n    let h = file_open(\"x.txt\", \"w\")\n    file_write(h)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("file_write with 1 argument should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`file_write` expects 2 argument(s)")), "{:?}", diags);
}

/// `file_write` reports `false` (not a crash, not a thrown exception) when
/// the underlying `fwrite` genuinely can't write -- here, a handle opened
/// read-only. Distinguishes this from the null-handle *abort* path: a
/// non-null but unwritable handle is exactly the "real runtime condition a
/// program can react to" case `emit_file_write`'s own doc comment describes,
/// not a programmer error.
#[test]
fn runtime_file_write_on_read_only_handle_reports_false_end_to_end() {
    let path = scratch_file_path("star_test_file_write_read_only.txt");
    let src = format!(
        "fn main():\n    let w = file_open(\"{p}\", \"w\")\n    file_write(w, \"seed\")\n    file_close(w)\n    let r = file_open(\"{p}\", \"r\")\n    let ok = file_write(r, \"nope\")\n    println(f\"{{ok}}\")\n    file_close(r)\n",
        p = path
    );
    let output = compile_and_run("file_write_read_only", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "false", "writing through a read-mode handle should report false, not abort: {}", stdout);
    let _ = std::fs::remove_file(&path);
}

/// A file whose last line has no trailing newline still yields that line's
/// full content from `file_read_line` (not truncated/lost by the EOF
/// check) -- a subsequent call past it then yields `""`, same EOF
/// convention as every other case. Distinguishes "stopped because of `\n`"
/// from "stopped because of EOF" inside `emit_file_read_line`'s loop, which
/// share a single `stop` flag (`is_eof or is_nl`).
#[test]
fn runtime_file_read_line_without_trailing_newline_end_to_end() {
    let path = scratch_file_path("star_test_file_read_line_no_trailing_nl.txt");
    let src = format!(
        "fn main():\n    let p = \"{p}\"\n    let w = file_open(p, \"w\")\n    file_write(w, \"onlyline\")\n    file_close(w)\n    let r = file_open(p, \"r\")\n    println(f\"a:{{file_read_line(r)}}\")\n    println(f\"b:{{file_read_line(r)}}\")\n    file_close(r)\n",
        p = path
    );
    let output = compile_and_run("file_read_line_no_trailing_nl", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["a:onlyline", "b:"], "{}", stdout);
    let _ = std::fs::remove_file(&path);
}

/// `file_read_line`'s fixed 1024-byte buffer truncates an oversized line at
/// 1023 characters (capacity minus the trailing NUL), leaving the rest
/// unread on the handle -- mirrors `runtime_read_line_truncates_oversized_input`'s
/// guarantee for the stdin-only `read_line()`, applied to the file-backed
/// sibling that reuses the exact same fixed-capacity loop shape (see
/// `emit_file_read_line`'s doc comment).
#[test]
fn runtime_file_read_line_truncates_oversized_line_end_to_end() {
    let path = scratch_file_path("star_test_file_read_line_truncate.txt");
    let long_line = "a".repeat(2000);
    let src = format!(
        "fn main():\n    let p = \"{p}\"\n    let w = file_open(p, \"w\")\n    file_write(w, \"{long}\\nshort\\n\")\n    file_close(w)\n    let r = file_open(p, \"r\")\n    println(file_read_line(r))\n    file_close(r)\n",
        p = path,
        long = long_line
    );
    let output = compile_and_run("file_read_line_truncate", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains(&"a".repeat(1023)), "truncated line should keep its first 1023 bytes: {}", stdout);
    assert!(!stdout.contains(&"a".repeat(1024)), "truncated line should not exceed 1023 bytes: {}", stdout);
    let _ = std::fs::remove_file(&path);
}

/// `file_read` on a file with zero bytes remaining (opened, then
/// immediately read again after already consuming everything) returns `""`
/// rather than a stray byte or a crash -- the `remaining == 0` edge of
/// `emit_file_read`'s `ftell`/`fseek` buffer sizing (`cap64 = 1`, `fread`
/// asked for 0 bytes).
#[test]
fn runtime_file_read_twice_second_call_returns_empty_end_to_end() {
    let path = scratch_file_path("star_test_file_read_twice.txt");
    let src = format!(
        "fn main():\n    let p = \"{p}\"\n    let w = file_open(p, \"w\")\n    file_write(w, \"all\")\n    file_close(w)\n    let r = file_open(p, \"r\")\n    println(f\"first:{{file_read(r)}}\")\n    println(f\"second:{{file_read(r)}}\")\n    file_close(r)\n",
        p = path
    );
    let output = compile_and_run("file_read_twice", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["first:all", "second:"], "{}", stdout);
    let _ = std::fs::remove_file(&path);
}

/// `file_read` on a handle to a non-seekable stream (the `NUL` device, which
/// `fopen` happily opens but which fails `ftell`/`fseek`, returning `-1`)
/// must return `""` instead of corrupting memory -- `emit_file_read` sizes
/// its buffer as `sext(ftell(end) - ftell(start))`, and without clamping a
/// negative result, `-1` sign-extended to `i64` and treated as an unsigned
/// byte count would request a `star_rc_alloc`/`fread` of roughly
/// `u64::MAX` bytes instead of failing cleanly.
#[test]
fn runtime_file_read_on_non_seekable_handle_returns_empty_end_to_end() {
    let src = "fn main():\n    let h = file_open(\"NUL\", \"r\")\n    println(f\"len={len(file_read(h))}\")\n    file_close(h)\n    println(\"done\")\n";
    let output = compile_and_run("file_read_non_seekable", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["len=0", "done"], "{}", stdout);
}

/// Opening a file in append mode (`"a"`) and writing to it adds to the
/// existing content rather than truncating it -- exercises a third `fopen`
/// mode beyond the `"r"`/`"w"` combinations every other test uses, since
/// `file_open` passes its `mode` argument straight through with no
/// validation or special-casing (see `emit_file_open`'s doc comment).
#[test]
fn runtime_file_append_mode_preserves_existing_content_end_to_end() {
    let path = scratch_file_path("star_test_file_append_mode.txt");
    let src = format!(
        "fn main():\n    let p = \"{p}\"\n    let w = file_open(p, \"w\")\n    file_write(w, \"first-\")\n    file_close(w)\n    let a = file_open(p, \"a\")\n    file_write(a, \"second\")\n    file_close(a)\n    let r = file_open(p, \"r\")\n    println(file_read(r))\n    file_close(r)\n",
        p = path
    );
    let output = compile_and_run("file_append_mode", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "first-second", "append mode should add to, not replace, existing content: {}", stdout);
    let _ = std::fs::remove_file(&path);
}
