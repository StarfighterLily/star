//! `process_memory()` (`crate::codegen::procmem`): the resident bytes of the
//! running process, -1 when the OS won't say.
//!
//! Added for the `projects/havokos` LPMUD driver's `memory_info()` and
//! `malloc_status()` (`todo.md` HavokOS P1 #6): Windows answers through a
//! `PROCESS_MEMORY_COUNTERS` out-parameter, which Star's FFI can't read.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

/// `process_memory()` is typed `i64`.
#[test]
fn typecheck_process_memory_is_i64() {
    assert_eq!(typed_fn_result_ty("fn f() -> i64:\n    process_memory()\n"), Ty::I64);
}

/// It takes no arguments.
#[test]
fn rejects_an_argument() {
    let module = Driver::parse("fn main():\n    let m = process_memory(1)\n").expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("expect")), "{:?}", diags);
}

/// The answer is a plausible size, and it grows by about what the program
/// touches: 64 MB of written bytes.
#[test]
fn runtime_process_memory_tracks_allocation() {
    let src = concat!(
        "fn main() -> i32:\n",
        "    let before = process_memory()\n",
        "    let mut b: Bytes = Bytes()\n",
        "    for i in 0..67108864:\n",
        "        b.push((i % 251) as u8)\n",
        "    let after = process_memory()\n",
        "    let mb = (1048576 as i64)\n",
        "    println(f\"{before > mb} {before < mb * (65536 as i64)} {after - before > mb * (48 as i64)} {b.len()}\")\n",
        "    0\n",
    );
    let out = compile_and_run("process_memory_grows", src);
    assert!(out.status.success(), "should run: {:?}", out);
    assert_eq!(String::from_utf8_lossy(&out.stdout).replace("\r\n", "\n"), "true true true 67108864\n");
}

/// An extern redeclaring `fscanf` (what it calls on Linux) gets the internal-symbol diagnostic.
#[test]
fn rejects_extern_redeclaring_its_runtime_symbol() {
    let src = "extern \"C\" fn fscanf(f: ptr, s: str) -> i32\nfn main():\n    let r = 0\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("declares internally")), "{:?}", diags);
}

/// The Linux arm (`/proc/self/statm` through `fscanf`, times the page size)
/// passes the IR verifier and compiles to an x86-64 Linux object.
#[test]
fn codegen_linux_arm_verifies_and_compiles_to_object() {
    let src = "fn main():\n    let m = process_memory()\n    let ok = file_set_mtime(\"x\", m)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let v = Driver::codegen_verified_for_target(&typed, star::codegen::Target::LinuxGnu).expect("should codegen");
    assert!(v.errors.is_empty(), "{:?}", v.errors.iter().map(|d| &d.message).collect::<Vec<_>>());
    assert!(v.ir.contains("@fscanf(") && v.ir.contains("@sysconf(i32 30)"), "{}", v.ir);
    assert!(v.ir.contains("call i32 @utime("), "file_set_mtime's Linux arm:\n{}", v.ir);
    assert!(!v.ir.contains("K32GetProcessMemoryInfo") && !v.ir.contains("_utime64"), "{}", v.ir);
    let dir = std::env::temp_dir();
    let ll = dir.join("star_test_procmem_linux.ll");
    let obj = dir.join("star_test_procmem_linux.o");
    std::fs::write(&ll, &v.ir).unwrap();
    let status = std::process::Command::new("clang")
        .args(["-c", "--target=x86_64-unknown-linux-gnu", ll.to_str().unwrap(), "-o", obj.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&obj);
    assert!(status.success(), "the Linux IR should compile to an object");
}
