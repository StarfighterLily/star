//! Value-producing `if`/`match` arms whose value is the first thing of its
//! kind in a function to need an out-of-line helper (a list/map/set release
//! thunk, a closure body). Those helpers emit a whole function with its own
//! `entry:` block in the middle of the arm, and until `todo.md` HavokOS M6
//! none restored `Codegen::current_label` afterwards, so the arm's `phi`
//! named `entry` as its predecessor and the IR verifier rejected the build.
//! Found writing `tcp_wait`'s codegen (`crate::codegen::net_server`), which
//! builds its `Bytes` result the same way.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

fn run(name: &str, src: &str) -> String {
    let output = compile_and_run(name, src);
    assert!(output.status.success(), "{:?}", output.status);
    String::from_utf8_lossy(&output.stdout).trim_end().replace("\r", "")
}

/// A list literal as the first list of its element type inside an `if` expression arm.
#[test]
fn runtime_if_arm_first_list_literal_end_to_end() {
    let src = "fn main():\n    let c = args().len() > 0\n    let x = if c: [1, 2] else: [3]\n    println(f\"{x.len()}\")\n";
    assert_eq!(run("ool_if_list", src), "2");
}

/// The same in the `else` arm, with the `then` arm a plain variable.
#[test]
fn runtime_else_arm_first_list_literal_end_to_end() {
    let src = "fn main():\n    let c = args().len() > 5\n    let e: List<str> = List<str>()\n    let x = if c: e else: [\"a\", \"b\", \"c\"]\n    println(f\"{x.len()}\")\n";
    assert_eq!(run("ool_else_list", src), "3");
}

/// A match arm whose value is a list literal.
#[test]
fn runtime_match_arm_first_list_literal_end_to_end() {
    let src = "fn main():\n    let n = args().len()\n    let x = match n:\n        1 -> [10, 20, 30]\n        _ -> [0]\n    println(f\"{x.len()} {x[0]}\")\n";
    assert_eq!(run("ool_match_list", src), "3 10");
}

/// A closure literal (whose body is emitted out of line) as an `if` arm's value.
#[test]
fn runtime_if_arm_closure_literal_end_to_end() {
    let src = "fn main():\n    let c = args().len() > 0\n    let k = 5\n    let f = if c: (fn(x: i32) -> i32: x + k) else: (fn(x: i32) -> i32: x - k)\n    println(f\"{f(1)}\")\n";
    assert_eq!(run("ool_if_closure", src), "6");
}
