//! A `str` holding its zero value passed to an `extern "C" fn` reaches C as
//! a real empty string, not a null pointer.
//!
//! `str`'s zero value (`Codegen::zero_value`, what a field never assigned
//! holds) is a null pointer, and both extern call paths
//! (`Codegen::emit_extern_call` for a direct call, the `fnval_` thunk in
//! `Codegen::emit_fn_value` for one through a function value) forwarded it
//! as is, so C saw "no string": a `strlen`-style callee crashed, and
//! `sqlite3_bind_text` would have bound SQL NULL where the Star value reads
//! as "" (found writing the `projects/havokos` SQLite efuns, `todo.md`
//! HavokOS P1 #7). Every `str` builtin already normalizes such a value
//! (`Codegen::emit_str_or_empty`); both extern paths now do too.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

/// Reports what C received: -1 for a null pointer, else the length.
const HELPER: &str = "#include <string.h>\nint star_probe_str(const char *s) { return s ? (int)strlen(s) : -1; }\n";

fn run_with_helper(name: &str, src: &str) -> String {
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let dir = std::env::temp_dir().join(format!("star_test_extern_empty_{}", name));
    std::fs::create_dir_all(&dir).unwrap();
    let ll = dir.join("t.ll");
    let c = dir.join("helper.c");
    let exe = dir.join("t.exe");
    std::fs::write(&ll, &ir).unwrap();
    std::fs::write(&c, HELPER).unwrap();
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

/// A null `str`: a despawned arena slot's field read through a stale handle
/// (the pattern `frontend_string_ops.rs` uses to reach a zero-valued
/// field). The tests then pass `str_from_bytes` of an empty `Bytes` and a
/// literal "" (both already real empty strings) and a non-empty string,
/// for contrast.
const NULL_STRS: &str = "struct Holder:
    val: str

arena Holders: Holder

";

/// A direct call gets an empty string, never a null pointer.
#[test]
fn runtime_direct_extern_call_gets_empty_string_not_null() {
    let out = run_with_helper("direct", &format!("{}extern \"C\" fn star_probe_str(s: str) -> i32
fn main():
    spawn Holders(\"present\")
    let h = Handle<Holder>(0)
    despawn Holders[0]
    let n: str = h[0].val
    println(f\"{{star_probe_str(n)}}\")
    println(f\"{{star_probe_str(str_from_bytes(Bytes()))}}\")
    println(f\"{{star_probe_str(\"\")}}\")
    println(f\"{{star_probe_str(\"abc\")}}\")
", NULL_STRS));
    assert_eq!(out, "0
0
0
3
");
}

/// A call through a function value goes through the extern's thunk, which
/// gets the same treatment.
#[test]
fn runtime_extern_call_through_fn_value_gets_empty_string_not_null() {
    let out = run_with_helper("fnvalue", &format!("{}extern \"C\" fn star_probe_str(s: str) -> i32
fn main():
    spawn Holders(\"present\")
    let h = Handle<Holder>(0)
    despawn Holders[0]
    let n: str = h[0].val
    let g = star_probe_str
    println(f\"{{g(n)}}\")
    println(f\"{{g(str_from_bytes(Bytes()))}}\")
    println(f\"{{g(\"ab\")}}\")
", NULL_STRS));
    assert_eq!(out, "0
0
2
");
}

/// The IR of a direct call: the argument is `select`ed against null, and
/// the release still names the original value.
#[test]
fn codegen_direct_extern_call_normalizes_and_releases_original() {
    let src = "extern \"C\" fn star_probe_str(s: str) -> i32\nfn main():\n    let s = concat(\"a\", \"b\")\n    let n = star_probe_str(s)\n";
    let ir = Driver::codegen(&Driver::check(&Driver::parse(src).unwrap()).unwrap()).unwrap();
    let main = extract_fn_body(&ir, "define i32 @main(");
    assert!(main.contains("@str.empty"), "{}", main);
    let call = main.find("call i32 @star_probe_str(").expect("the call");
    assert!(main[call..].contains("call void @star_rc_release("), "{}", main);
}
