//! `print`/`println` with a non-f-string argument containing `%`.
//!
//! The non-f-string path used to hand its argument to `printf` *as the
//! format string*, so any runtime `str` holding `%` was parsed for
//! conversion specifiers: `"%^RED%^"` (a MUD colour code) printed as
//! `"^RED^"`, and `"%s"` read a garbage vararg and segfaulted. Found by the
//! `projects/havokos` LPMUD driver port, whose token dumps print LPC string
//! literals verbatim. Fixed in `Codegen::emit_print_like` by always printing
//! through a constant `"%s"` format.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

/// `println(s)` prints `%` sequences in a runtime string literally, including `%s`/`%d` that used to crash.
#[test]
fn runtime_println_str_with_percent_is_literal() {
    let src = "fn main() -> i32:\n    let s = \"a%^RED%^b %d %s 100%\"\n    println(s)\n    0\n";
    let out = compile_and_run("println_percent_literal", src);
    assert!(out.status.success(), "should not crash: {:?}", out);
    let stdout = String::from_utf8_lossy(&out.stdout).replace("\r\n", "\n");
    assert_eq!(stdout, "a%^RED%^b %d %s 100%\n");
}

/// `print(s)` (no trailing newline) takes the same constant-format path as `println`.
#[test]
fn runtime_print_str_with_percent_is_literal() {
    let src = "fn main() -> i32:\n    let s = concat(\"50\", \"%n%%\")\n    print(s)\n    0\n";
    let out = compile_and_run("print_percent_literal", src);
    assert!(out.status.success(), "should not crash: {:?}", out);
    assert_eq!(String::from_utf8_lossy(&out.stdout), "50%n%%");
}

/// The f-string path still escapes its literal `%` and formats holes as before.
#[test]
fn runtime_println_fstring_percent_unchanged() {
    let src = "fn main() -> i32:\n    let s = \"%d\"\n    let n = 7\n    println(f\"{n}% {s}\")\n    0\n";
    let out = compile_and_run("println_fstring_percent", src);
    assert!(out.status.success(), "should not crash: {:?}", out);
    let stdout = String::from_utf8_lossy(&out.stdout).replace("\r\n", "\n");
    assert_eq!(stdout, "7% %d\n");
}
