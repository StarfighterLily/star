//! `clock_ms()` (`crate::codegen::clock`): monotonic milliseconds.
//!
//! Added for the `projects/havokos` LPMUD driver's call_outs, heart beats
//! and evaluation time limit (`todo.md` HavokOS M5), which need a wall clock
//! that keeps running for a MUD's whole uptime: C's `clock()` stops after
//! about 24.8 days on msvcrt and is CPU time on glibc, and the OS calls
//! that do it right can't be declared or read from Star.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

fn run_ok(name: &str, src: &str) -> String {
    let out = compile_and_run(name, src);
    assert!(out.status.success(), "should run: {:?}", out);
    String::from_utf8_lossy(&out.stdout).replace("\r\n", "\n")
}

/// `clock_ms()` is an `i64`.
#[test]
fn typecheck_clock_ms_is_i64() {
    assert_eq!(typed_fn_result_ty("fn f() -> i64:\n    clock_ms()\n"), Ty::I64);
}

/// Passing an argument is a checker error, not a codegen crash.
#[test]
fn rejects_clock_ms_with_an_argument() {
    let module = Driver::parse("fn main():\n    let t = clock_ms(5)\n").expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("expect")), "{:?}", diags);
}

/// An extern redeclaring the C symbol `clock_ms` calls gets a real diagnostic.
#[test]
fn rejects_extern_redeclaring_clock_runtime_symbol() {
    let src = "extern \"C\" fn clock_gettime(c: i32, p: ptr) -> i32\nfn main():\n    let r = clock_gettime(1, null_ptr())\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("declares internally")), "{:?}", diags);
}

/// The Windows arm calls `GetTickCount64` and nothing POSIX.
#[test]
fn codegen_windows_target_uses_get_tick_count64() {
    let module = Driver::parse("fn main():\n    let t = clock_ms()\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let v = Driver::codegen_verified_for_target(&typed, star::codegen::Target::WindowsGnu).expect("should codegen");
    assert!(v.ir.contains("call i64 @GetTickCount64()"), "{}", v.ir);
    assert!(!v.ir.contains("@clock_gettime"), "{}", v.ir);
}

/// The Linux arm reads `CLOCK_MONOTONIC` (1) through `clock_gettime` and passes the internal IR verifier.
#[test]
fn codegen_linux_target_uses_clock_gettime_monotonic() {
    let module = Driver::parse("fn main():\n    let t = clock_ms()\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let v = Driver::codegen_verified_for_target(&typed, star::codegen::Target::LinuxGnu).expect("should codegen");
    assert!(v.ir.contains("declare i32 @clock_gettime(i32, i8*)"), "{}", v.ir);
    assert!(v.ir.contains("call i32 @clock_gettime(i32 1, "), "{}", v.ir);
    assert!(!v.ir.contains("GetTickCount64"), "{}", v.ir);
    assert!(v.errors.is_empty(), "{:?}", v.errors.iter().map(|d| &d.message).collect::<Vec<_>>());
}

/// At runtime the clock is positive, never runs backwards, and a 200 ms sleep advances it by about that much.
#[test]
fn runtime_clock_ms_advances_monotonically_end_to_end() {
    let src = concat!(
        "extern \"C\" fn _sleep(ms: i32)\n",
        "fn main() -> i32:\n",
        "    let a = clock_ms()\n",
        "    let mut prev = a\n",
        "    let mut back = false\n",
        "    for i in 0..100000:\n",
        "        let t = clock_ms()\n",
        "        if t < prev:\n",
        "            back = true\n",
        "        prev = t\n",
        "    let b = clock_ms()\n",
        "    _sleep(200)\n",
        "    let c = clock_ms()\n",
        "    let d = c - b\n",
        "    println(f\"pos:{a > (0 as i64)} back:{back} slept:{d >= (150 as i64) and d < (2000 as i64)}\")\n",
        "    0\n",
    );
    assert_eq!(run_ok("clock_ms_advances", src), "pos:true back:false slept:true\n");
}
