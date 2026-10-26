//! `extern "C" fn` names that start with an uppercase letter can be
//! declared and called (todo.md HavokOS P2 #1).
//!
//! Star's parser reads `Name(args)` with an uppercase `Name` as a struct
//! literal, so a call to `GetTickCount()` or OpenSSL's `SSL_new(ctx)`
//! reached the checker as the construction of a struct that doesn't exist,
//! and `Checker::check_extern_fn` rejected every such declaration outright.
//! That blocked most of the Win32 API and all of OpenSSL, which the
//! `projects/havokos` TLS layer (todo.md HavokOS P1 #8) binds. The checker
//! now records every extern name in pass 1 (`Checker::extern_fn_decls`) and
//! checks a struct literal naming one -- with no struct of that name and no
//! turbofish -- as the call it is; only an extern sharing its name with a
//! struct is still an error, since that struct's literal always wins.
//!
//! The alternative considered was making the *parser* decide, but it can't:
//! whether `Foo(..)` is a constructor depends on declarations it hasn't
//! seen (an extern may be declared after its first call, or in another
//! module), which only the checker knows.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

/// Builds `src` with a C helper defining uppercase-named functions, runs it.
fn run_with_helper(name: &str, src: &str, helper: &str) -> String {
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let dir = std::env::temp_dir().join(format!("star_test_extern_upper_{}", name));
    std::fs::create_dir_all(&dir).unwrap();
    let ll = dir.join("t.ll");
    let c = dir.join("helper.c");
    let exe = dir.join("t.exe");
    std::fs::write(&ll, &ir).unwrap();
    std::fs::write(&c, helper).unwrap();
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), c.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should build the IR and the helper");
    let out = std::process::Command::new(&exe).output().expect("failed to run");
    let _ = std::fs::remove_dir_all(&dir);
    assert!(out.status.success(), "exit {:?}", out.status);
    String::from_utf8_lossy(&out.stdout).replace("\r\n", "\n")
}

const HELPER: &str = "#include <string.h>\n\
int Star_Add(int a, int b) { return a + b; }\n\
int Star_Len(const char *s) { return (int)strlen(s); }\n\
static int counter;\n\
void Star_Bump(void) { counter++; }\n\
int Star_Count(void) { return counter; }\n";

/// An uppercase extern with arguments and a result is called, not constructed.
#[test]
fn runtime_uppercase_extern_call_with_args_and_result_end_to_end() {
    let out = run_with_helper(
        "args",
        "extern \"C\" fn Star_Add(a: i32, b: i32) -> i32\nextern \"C\" fn Star_Len(s: str) -> i32\nfn main():\n    println(f\"{Star_Add(40, 2)} {Star_Len(\"hello\")}\")\n",
        HELPER,
    );
    assert_eq!(out, "42 5\n");
}

/// A void, argument-less uppercase extern works as a statement.
#[test]
fn runtime_uppercase_extern_void_statement_call_end_to_end() {
    let out = run_with_helper(
        "void",
        "extern \"C\" fn Star_Bump()\nextern \"C\" fn Star_Count() -> i32\nfn main():\n    Star_Bump()\n    Star_Bump()\n    Star_Bump()\n    println(f\"{Star_Count()}\")\n",
        HELPER,
    );
    assert_eq!(out, "3\n");
}

/// The extern may be declared after the function that calls it.
#[test]
fn runtime_uppercase_extern_declared_after_its_caller_end_to_end() {
    let out = run_with_helper(
        "later",
        "fn main():\n    println(f\"{Star_Add(1, 2)}\")\nextern \"C\" fn Star_Add(a: i32, b: i32) -> i32\n",
        HELPER,
    );
    assert_eq!(out, "3\n");
}

/// Real Win32 symbols, the motivating case: `GetTickCount()` and `Sleep(ms)`.
#[cfg(windows)]
#[test]
fn runtime_win32_uppercase_externs_end_to_end() {
    let out = compile_and_run(
        "extern_upper_win32",
        "extern \"C\" fn GetTickCount() -> i32\nextern \"C\" fn Sleep(ms: i32)\nfn main():\n    let a = GetTickCount()\n    Sleep(20)\n    let b = GetTickCount()\n    println(f\"{b - a >= 0}\")\n",
    );
    assert!(out.status.success(), "{:?}", out);
    assert_eq!(String::from_utf8_lossy(&out.stdout).trim(), "true");
}

/// An uppercase extern declared and called inside an imported module.
#[test]
fn uppercase_extern_inside_imported_module_type_checks() {
    let dir = test_scratch_dir("uppercase_extern_inside_imported_module_type_checks");
    write_test_file(&dir, "lib.star", "extern \"C\" fn GetTickCount() -> i32\nfn ticks() -> i32:\n    GetTickCount()\n");
    let main_path = write_test_file(&dir, "main.star", "import \"lib.star\" as lib\nfn main():\n    println(f\"{lib::ticks() >= 0}\")\n");
    let c = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(c.is_ok(), "{}", c.render_diagnostics());
    let _ = std::fs::remove_dir_all(&dir);
}

/// A call's arguments are checked against the extern's signature, like any call.
#[test]
fn uppercase_extern_call_with_wrong_arity_is_a_type_error() {
    let src = "extern \"C\" fn Star_Add(a: i32, b: i32) -> i32\nfn main():\n    println(f\"{Star_Add(1)}\")\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "one argument to a two-parameter extern should be rejected");
}

/// An extern named like a struct is rejected: the struct literal would always win.
#[test]
fn uppercase_extern_sharing_a_struct_name_is_rejected() {
    let src = "struct Point:\n    x: i32\nextern \"C\" fn Point(x: i32) -> i32\nfn main():\n    let p = Point(1)\n    println(f\"{p.x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("an extern named like a struct should be rejected") };
    assert!(diags.iter().any(|d| d.message.contains("same name as a struct")), "{:?}", diags);
}

/// Struct literals are untouched: an uppercase call with no extern is still a constructor.
#[test]
fn runtime_struct_literal_still_constructs_beside_uppercase_externs_end_to_end() {
    let out = run_with_helper(
        "struct",
        "struct Pair:\n    a: i32\n    b: i32\nextern \"C\" fn Star_Add(a: i32, b: i32) -> i32\nfn main():\n    let p = Pair(3, 4)\n    println(f\"{Star_Add(p.a, p.b)}\")\n",
        HELPER,
    );
    assert_eq!(out, "7\n");
}

/// An uppercase call naming neither a struct nor an extern is still "undefined type".
#[test]
fn uppercase_call_of_nothing_is_still_undefined_type() {
    let src = "fn main():\n    let x = Nothing(1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("an undeclared uppercase name should be rejected") };
    assert!(diags.iter().any(|d| d.message.contains("Nothing")), "{:?}", diags);
}
