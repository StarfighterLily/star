//! A parameter whose name looks like a compiler temporary.
//!
//! `Codegen::emit_fn` named each parameter's incoming LLVM value after the
//! parameter (`i64 %t0`), and temporaries are `%t<N>` (`Codegen::tmp_name`),
//! so `fn f(mut self, t0: i64)` defined `%t0` twice -- the parameter and the
//! first temporary, `self`'s stack slot -- and clang rejected the module
//! ("multiple definition of local value named 't0'"). It surfaced in the
//! `projects/havokos` LPMUD driver's sampling profiler (`sample_compile(t0)`,
//! a start time). Parameters are now `%arg.<name>`, which no temporary,
//! label or `%.sret` can spell, since `.` can't occur in a Star identifier.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

/// A method whose parameter is `t0` (the first temporary's name) compiles and runs.
#[test]
fn runtime_method_param_named_t0() {
    let src = "struct S:\n    mut n: i64 = 0 as i64\n\nimpl S:\n    fn add(mut self, t0: i64, t1: i64):\n        self.n = self.n + t0 + t1\n\nfn main() -> i32:\n    let mut s = S()\n    s.add(3 as i64, 4 as i64)\n    println(f\"{s.n}\")\n    0\n";
    let out = compile_and_run("param_named_t0", src);
    assert!(out.status.success(), "should run: {:?}", out);
    assert_eq!(String::from_utf8_lossy(&out.stdout).replace("\r\n", "\n"), "7\n");
}

/// A free function with parameters spelled like later temporaries (`t2`, `t7`) runs too.
#[test]
fn runtime_free_fn_params_named_like_temporaries() {
    let src = "fn mix(t2: i32, t7: str) -> str:\n    f\"{t7}{t2 * 2}\"\n\nfn main() -> i32:\n    println(mix(21, \"x\"))\n    0\n";
    let out = compile_and_run("param_named_t7", src);
    assert!(out.status.success(), "should run: {:?}", out);
    assert_eq!(String::from_utf8_lossy(&out.stdout).replace("\r\n", "\n"), "x42\n");
}

/// Parameters reach the IR as `%arg.<name>`.
#[test]
fn codegen_params_are_prefixed() {
    let src = "fn f(t0: i32, x: i32) -> i32:\n    t0 + x\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i32 @f(i32 %arg.t0, i32 %arg.x)"), "{}", ir);
}
