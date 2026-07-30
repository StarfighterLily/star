//! Native "Open File" common dialog builtin
//!
//! `open_file_dialog(filter_pattern: str) -> str` (`crate::codegen::dialog`)
//! wraps Windows' `GetOpenFileNameA` -- see that module's own doc comment
//! for the full `OPENFILENAMEA` field-offset derivation and the filter-
//! string construction. Only type-checking and link-time coverage live
//! here, deliberately: unlike `window_create`/`clear_screen`/etc (runtime-
//! tested under `SDL_VIDEODRIVER=dummy` in
//! `tests/frontend_sdl_graphics_input_and_geometry_audit.rs`), there is no
//! headless mode for a real Win32 common dialog -- actually calling
//! `GetOpenFileNameA` shows a genuine modal window and blocks the calling
//! thread until a human dismisses it. A `cargo test` run has no one to do
//! that, so a runtime test here would simply hang (confirmed once,
//! manually, outside the suite: the compiled smoke-test binary ran to
//! completion in well under a second when built, but sat blocked -- not
//! crashed, not returned -- for the full duration of an external `timeout`
//! wrapper once actually launched, exactly the "dialog is open and waiting"
//! signature). A real (non-`dummy`) window-station-less CI runner might
//! also make `GetOpenFileNameA` fail outright rather than hang; either way,
//! this isn't a distinction worth chasing to automate.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

/// `open_file_dialog` type-checks to `str`, the same "empty string means
/// nothing here" convention `file_read`/`tcp_recv` already use for their own
/// no-result case.
#[test]
fn checks_open_file_dialog_returns_str() {
    let src = "fn t():\n    let p: str = open_file_dialog(\"*.bin\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("open_file_dialog(..) should type-check as str");
}

/// An empty filter pattern is legal input (falls back to "all files" at
/// runtime, per `crate::codegen::dialog`'s own doc comment) -- not rejected
/// at type-check time.
#[test]
fn checks_open_file_dialog_accepts_empty_filter() {
    let src = "fn t():\n    let p: str = open_file_dialog(\"\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("open_file_dialog(\"\") should type-check as str");
}

/// A wrong argument count is caught at type-check time, not left to fail
/// confusingly at the `clang` step -- mirrors
/// `checker_rejects_file_open_wrong_arg_count`.
#[test]
fn checker_rejects_open_file_dialog_wrong_arg_count() {
    let src = "fn t():\n    open_file_dialog()\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("open_file_dialog() with 0 arguments should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`open_file_dialog` expects 1 argument(s)")), "{:?}", diags);
}

/// A non-`str` argument is rejected at type-check time.
#[test]
fn checker_rejects_open_file_dialog_wrong_arg_type() {
    let src = "fn t():\n    open_file_dialog(42)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("open_file_dialog(42) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`open_file_dialog` expects a `str` argument")), "{:?}", diags);
}

/// The generated IR actually compiles and *links* against `comdlg32`
/// (`-l comdlg32`, per `crate::codegen::dialog`'s own linking note) --
/// exercises the whole `OPENFILENAMEA` struct-layout/filter-string codegen
/// path for real byte offsets clang would reject if malformed (e.g. a
/// `bitcast` to the wrong pointee type, or a `getelementptr` on a stale
/// SSA name), without ever actually invoking `GetOpenFileNameA` (see this
/// file's own module doc comment for why a real run isn't attempted here).
#[test]
fn runtime_open_file_dialog_compiles_and_links() {
    let src = "fn t() -> str:\n    open_file_dialog(\"*.bin\")\n\nfn main():\n    let p = t()\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_open_file_dialog_link.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap(), "-lcomdlg32"])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile and link the generated IR against comdlg32");
    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
}
