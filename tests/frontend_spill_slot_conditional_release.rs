//! A field read off a by-value temporary (`f().field`) on a conditionally
//! evaluated path -- the right operand of `and`/`or` -- must not release an
//! uninitialized spill slot.
//!
//! `Codegen::emit_place` spills such a temporary into a fresh alloca and
//! tracks it for release at the end of the enclosing *scope*. When the
//! spill sat behind a short-circuit that skipped it, the scope-exit release
//! still ran and read whatever garbage was on the stack: a segfault that
//! depended on what the caller's frame had left there. Found by the
//! `projects/havokos` LPMUD parser port, where `self.peek(1).kind == ...`
//! behind a false `and` crashed `parse_toplevel` only when it was called
//! from inside a loop. Fixed by zeroing every RC-bearing spill slot in the
//! function's entry block (`ENTRY_INIT_MARK`, hoisted by
//! `hoist_allocas_to_entry`) and re-zeroing it after each scope-exit
//! release (`emit_scope_release`), so a loop iteration that skips the spill
//! doesn't release the previous iteration's value a second time.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

const TOK_PREFIX: &str = "struct Tok:\n    kind: i32\n    text: str\n\nfn mk(k: i32) -> Tok:\n    Tok(kind = k, text = concat(\"tok\", \"en\"))\n\n";

/// Skipping a `mk().kind` spill behind a false `and` doesn't release whatever stale value the uninitialized slot holds.
#[test]
fn runtime_skipped_and_rhs_spill_does_not_release_garbage() {
    let src = format!(
        "{}fn check(flag: bool) -> bool:
    flag and mk(1).kind == 1

fn main() -> i32:
    let mut n = 0
    for i in 0..1000:
        if check(i % 3 != 0):
            n += 1
    println(f\"{{n}}\")
    0
",
        TOK_PREFIX
    );
    let out = compile_and_run("spill_skipped_and_rhs", &src);
    assert!(out.status.success(), "should not crash: {:?}", out);
    assert_eq!(String::from_utf8_lossy(&out.stdout).trim(), "666");
}

/// The same skipped spill behind `or` (the right operand runs only when the left is false).
#[test]
fn runtime_skipped_or_rhs_spill_does_not_release_garbage() {
    let src = format!(
        "{}fn check(flag: bool) -> bool:\n    flag or mk(2).text == \"token\"\n\nfn main() -> i32:\n    let mut n = 0\n    for i in 0..1000:\n        if check(i % 3 == 0):\n            n += 1\n    println(f\"{{n}}\")\n    0\n",
        TOK_PREFIX
    );
    let out = compile_and_run("spill_skipped_or_rhs", &src);
    assert!(out.status.success(), "should not crash: {:?}", out);
    assert_eq!(String::from_utf8_lossy(&out.stdout).trim(), "1000");
}

/// A loop iteration that skips the spill after one that took it doesn't release the earlier iteration's value again.
#[test]
fn runtime_loop_iteration_skipping_spill_does_not_double_release() {
    // The spilled `Tok` shares `keep`'s string, so every extra release of
    // the stale slot frees (then corrupts) memory `keep` still owns; the
    // `junk` allocations reuse that block before `keep` is read back.
    let src = format!(
        "{}fn share(k: i32, s: str) -> Tok:
    Tok(kind = k, text = s)

fn main() -> i32:
    let keep = concat(\"kee\", \"p\")
    let mut hits = 0
    for round in 0..50:
        let mut i = 0
        while i < 4:
            if i == 0 and share(i, keep).kind == 0:
                hits += 1
            i += 1
    let mut junk: List<str> = List<str>()
    for j in 0..200:
        junk.push(concat(\"junk\", \"!!\"))
    println(f\"{{hits}} {{keep}} {{junk.len()}}\")
    0
",
        TOK_PREFIX
    );
    let out = compile_and_run("spill_loop_skip", &src);
    assert!(out.status.success(), "should not crash: {:?}", out);
    assert_eq!(String::from_utf8_lossy(&out.stdout).trim(), "50 keep 200");
}

/// The spill slot is zeroed in the entry block, and the hoisting marker never reaches the final IR.
#[test]
fn codegen_conditional_spill_slot_zeroed_in_entry_block() {
    let src = format!("{}fn check(flag: bool) -> bool:\n    flag and mk(1).kind == 1\n\nfn main() -> i32:\n    if check(false): 1 else: 0\n", TOK_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(!ir.contains('\u{1}'), "entry-init marker leaked into the IR");
    let body = extract_fn_body(&ir, "define i1 @check(");
    let entry: String = body
        .lines()
        .skip_while(|l| *l != "entry:")
        .skip(1)
        .take_while(|l| !l.ends_with(':'))
        .collect::<Vec<_>>()
        .join("\n");
    assert!(
        entry.lines().any(|l| l.contains("store %Tok zeroinitializer, %Tok* ")),
        "spill slot not zeroed in the entry block:\n{}",
        body
    );
}
