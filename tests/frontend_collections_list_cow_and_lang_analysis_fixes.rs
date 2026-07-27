//! List copy-on-write ownership; LANGUAGE_ANALYSIS.md fixes
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== List<T> copy-on-write ownership (todo.md's memory-ownership fix) ===

/// The use-after-free `todo.md` originally flagged, "confirmed empirically":
/// `let b = a` used to alias the same buffer, and growing `b` past `a`'s
/// original capacity would `free` that buffer and repoint only `b`'s own
/// fields, leaving `a` holding a dangling pointer. Under copy-on-write,
/// growing `b` first clones the (now-shared) buffer, so `a`'s original
/// elements must still read back correctly -- and, since this is
/// copy-on-write (value semantics), `a`'s length must NOT have grown along
/// with `b`'s.
#[test]
fn runtime_list_cow_push_does_not_corrupt_alias_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let a: List<i32> = [1, 2, 3]\n",
        "    let mut b = a\n",
        "    let mut i: i32 = 0\n",
        "    while i < 20:\n",
        "        b.push(i)\n",
        "        i += 1\n",
        "    println(f\"a0={a[0]} a1={a[1]} a2={a[2]} alen={a.len()} blen={b.len()}\")\n",
    );
    let output = compile_and_run("list_cow_push", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "a0=1 a1=2 a2=3 alen=3 blen=23", "{}", stdout);
}

/// `let b = a; b[i] = v` (index-assignment) must not be visible through
/// `a` -- covers the copy-on-write gate on `store_list_index` specifically,
/// distinct from `push`'s grow path above.
#[test]
fn runtime_list_cow_index_assignment_diverges_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let a: List<i32> = [1, 2, 3]\n",
        "    let mut b = a\n",
        "    b[0] = 99\n",
        "    println(f\"a0={a[0]} b0={b[0]}\")\n",
    );
    let output = compile_and_run("list_cow_index_assign", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "a0=1 b0=99", "{}", stdout);
}

/// `let b = a; b.pop()` must not be visible through `a` -- the case most
/// likely to be missed by a copy-on-write implementation, since `pop` only
/// mutates `len` and never touches `data`, so it's easy to assume (wrongly)
/// that it needs no uniqueness check.
#[test]
fn runtime_list_cow_pop_diverges_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let a: List<i32> = [1, 2, 3]\n",
        "    let mut b = a\n",
        "    let popped = b.pop()\n",
        "    println(f\"alen={a.len()} blen={b.len()} popped={popped} a2={a[2]}\")\n",
    );
    let output = compile_and_run("list_cow_pop", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "alen=3 blen=2 popped=3 a2=3", "{}", stdout);
}

/// A `List<i32>` (a non-RC element type) local used to leak unconditionally
/// -- `contains_rc(List(elem))` only recursed into the element type, so a
/// list of non-RC elements was never `track_owned` and nothing but `push`'s
/// realloc ever freed its buffer. `contains_rc(List(_))` is now
/// unconditionally `true`, so this parameter should now be released (and,
/// transitively, its buffer freed by the generated `list_release_i32`
/// thunk) at scope exit, same as a `List<str>` already was.
#[test]
fn codegen_list_of_int_is_released_at_scope_exit() {
    let src = "fn t(nums: List<i32>) -> i32:\n    1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    assert!(fn_ir.contains("call void @star_rc_release"), "a List<i32> parameter should now be released at scope exit: {}", fn_ir);
}

/// A copy-on-write clone (triggered here by `push` on a shared `List<str>`)
/// must retain each copied element -- otherwise the original and the clone
/// would both believe they solely own the same string, and whichever is
/// released last would read already-freed memory. Both aliases' string
/// elements must still print correctly after the clone.
#[test]
fn runtime_list_cow_clone_retains_str_elements_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let a: List<str> = [\"alpha\", \"beta\"]\n",
        "    let mut b = a\n",
        "    b.push(\"gamma\")\n",
        "    println(f\"a0={a[0]} a1={a[1]} alen={a.len()}\")\n",
        "    println(f\"b0={b[0]} b1={b[1]} b2={b[2]} blen={b.len()}\")\n",
    );
    let output = compile_and_run("list_cow_clone_str", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let mut lines = stdout.lines();
    assert_eq!(lines.next(), Some("a0=alpha a1=beta alen=2"), "{}", stdout);
    assert_eq!(lines.next(), Some("b0=alpha b1=beta b2=gamma blen=3"), "{}", stdout);
}

/// Regression test: `Codegen::emit_place` previously had no `ListIndex` arm,
/// so a mutating operation whose *receiver* was itself a `list[i]`
/// expression (`outer[i].push(v)`, chaining a `List<T>` method call onto an
/// index) fell into `emit_place`'s generic fallback -- evaluate the
/// expression, spill the resulting *value* into a fresh, disconnected
/// alloca, and mutate that instead of the real buffer. The write silently
/// vanished: `outer[0].push(99)` type-checked, compiled, and ran with zero
/// observable effect on `outer`. Fixed by giving `emit_place` a dedicated
/// `ListIndex` arm (`Codegen::emit_list_index_place`) that resolves a real
/// pointer into the (copy-on-write-uniqued) buffer.
#[test]
fn runtime_nested_list_index_receiver_push_mutates_through_index_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let mut outer: List<List<i32>> = [[1, 2], [3, 4]]\n",
        "    outer[0].push(99)\n",
        "    println(f\"len0={outer[0].len()} last={outer[0][2]} len1={outer[1].len()}\")\n",
    );
    let output = compile_and_run("nested_list_index_push", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "len0=3 last=99 len1=2", "{}", stdout);
}

/// Same root-cause bug as above (`emit_place`'s missing `ListIndex` arm),
/// but through the `store_target`/`store_list_index` path instead of a
/// method-call receiver: `m[i][j] = v` -- a nested nested index-assignment
/// where the *outer* target's own `base` (`m[i]`) is itself a `ListIndex`
/// that must resolve to real storage in `m`'s buffer, not a throwaway copy.
#[test]
fn runtime_nested_list_index_assignment_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let mut m: List<List<i32>> = [[1, 2], [3, 4]]\n",
        "    m[0][1] = 999\n",
        "    println(f\"m00={m[0][0]} m01={m[0][1]} m10={m[1][0]}\")\n",
    );
    let output = compile_and_run("nested_list_index_assign", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "m00=1 m01=999 m10=3", "{}", stdout);
}

/// The same `emit_place` gap also applied to `GenRefIndex` (`gen_ref[0]`
/// used as the base of a further access): `r[0].field = v`/`r[0].field -= v`
/// silently no-op'd on the arena, since `emit_place`'s generic fallback
/// mutated a disconnected copy of the dereferenced struct rather than a
/// pointer into the live slot. Fixed by `Codegen::emit_genref_index_place`,
/// mirroring `emit_list_index_place`'s fix for the identical root cause.
#[test]
fn runtime_genref_field_write_mutates_arena_slot_end_to_end() {
    let src = concat!(
        "struct Entity:\n",
        "    mut hp: i32\n",
        "arena Entities: Entity\n",
        "fn main():\n",
        "    spawn Entities(100)\n",
        "    let r = GenRef<Entity>(0)\n",
        "    r[0].hp -= 10\n",
        "    let after = r[0]\n",
        "    println(f\"after: {after.hp}\")\n",
    );
    let output = compile_and_run("genref_field_write", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "after: 90", "{}", stdout);
}

// ===== LANGUAGE_ANALYSIS.md fixes =========================================
//
// Regression tests for the bugs identified in `LANGUAGE_ANALYSIS.md` and
// tracked in `todo.md`'s "Immediate" list, in the same priority order.

// --- §0: `main`'s exit code -------------------------------------------------

/// Every compiled program's exit code must be deterministic (`0` on normal
/// completion), not whatever garbage happened to be left in `eax` by the
/// last instruction before a `ret void` in a `void @main()` -- the flagship
/// bug reproduced on every single example in `examples/`.
#[test]
fn runtime_main_exit_code_is_zero_not_garbage() {
    use std::process::Command;

    let output = Command::new("examples/player.exe").output().expect("failed to execute player.exe");
    assert_eq!(output.status.code(), Some(0), "main with no declared return type must exit 0, not garbage");
}

/// `main` declared with an explicit, non-`i32` return type is rejected: it
/// can never actually be honored, since `main` is always forced to lower to
/// `i32 @main(...)` (a hosted C entry point's signature is an OS/CRT ABI
/// requirement).
#[test]
fn rejects_main_with_non_i32_return_type() {
    let module = Driver::parse("fn main() -> str:\n    return \"hi\"\n").expect("should parse");
    let errs = Driver::check(&module).expect_err("main declared to return str should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("main") && d.message.contains("i32")), "{:?}", errs);
}

/// `main` with no declared return type at all still type-checks fine (the
/// ordinary, common case) and lowers to `i32 @main(...)` with an implicit
/// `ret i32 0`.
#[test]
fn codegen_main_lowers_to_i32_with_implicit_ret_zero() {
    let module = Driver::parse("fn main():\n    print(\"hi\")\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i32 @main("), "main should always lower to i32: {}", ir);
    assert!(ir.contains("ret i32 0"), "implicit fallthrough should return 0: {}", ir);
}

/// A bare `return` (no value) inside `main` must still produce an
/// `i32`-typed terminator (`ret i32 0`), not the ordinary `ret void` a
/// no-return-type function gets elsewhere -- otherwise the function body
/// would contain a terminator disagreeing with `main`'s own forced `i32`
/// signature (invalid IR).
#[test]
fn codegen_bare_return_inside_main_returns_i32_zero() {
    let module = Driver::parse("fn main():\n    if true:\n        return\n    print(\"after\")\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let main_ir = extract_fn_body(&ir, "define i32 @main(");
    assert!(!main_ir.contains("ret void"), "main must never emit `ret void`: {}", main_ir);
    assert_eq!(main_ir.matches("ret i32 0").count(), 2, "both the early bare return and the implicit fallthrough should return i32 0: {}", main_ir);
}

// --- §3.1: frame bump-allocator capacity bounds check -----------------------

/// A `frame:` block allocating more than the 4096-byte backing buffer's
/// capacity must abort the process loudly with a diagnostic message rather
/// than segfaulting or silently corrupting whatever global data happens to
/// sit right after `@frame.buf`.
#[test]
fn runtime_frame_overflow_aborts_loudly_instead_of_segfaulting() {
    use std::process::Command;

    let output = Command::new("examples/frame_overflow.exe").output().expect("failed to execute frame_overflow.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("frame:` block exceeded its 4096-byte capacity"), "should print a diagnostic: {}", stdout);
    assert!(!stdout.contains("should not reach here"), "the frame allocation must abort before its value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "should exit cleanly with code 1, not crash/segfault: {:?}", output.status);
}

/// Codegen for a frame `let` includes a capacity check against
/// `FRAME_BUF_SIZE` before advancing `@frame.off`, with a call to `@exit` on
/// the overflow path.
#[test]
fn codegen_frame_alloc_includes_capacity_check() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\nfn test():\n    frame:\n        let p = Point(1, 2)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("icmp ugt i64"), "should compare the new offset against the buffer capacity: {}", ir);
    assert!(ir.contains("call void @exit(i32 1)"), "should abort on overflow: {}", ir);
}

// --- `frame(N):` makes the bump-allocator budget configurable, mirroring
// the fix already done for arena capacity (`arena Name: Type = N`) --------

/// `frame(N):` parses to `Stmt::Frame` with `budget: Some(N)`; a bare
/// `frame:` (already covered by `parses_frame_stmt`) parses to `budget:
/// None` -- resolved to the default only later, by the checker.
#[test]
fn parses_frame_stmt_with_budget() {
    let src = "fn test():\n    frame(8192):\n        let x = 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Frame { budget, body, .. } = &f.body.stmts[0] else { panic!("expected Frame") };
    assert_eq!(*budget, Some(8192));
    assert_eq!(body.stmts.len(), 1);
}

/// A bare `frame:` (no override) parses with `budget: None` -- the
/// counterpart to `parses_frame_stmt_with_budget` above, pinning that the
/// new optional grammar doesn't change the no-override parse shape.
#[test]
fn parses_frame_stmt_without_budget_is_none() {
    let src = "fn test():\n    frame:\n        let x = 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Frame { budget, .. } = &f.body.stmts[0] else { panic!("expected Frame") };
    assert_eq!(*budget, None);
}

/// `frame(N):` rejects a non-positive budget literal outright at parse
/// time, mirroring `parses_arena_rejects_non_positive_capacity` -- there's
/// no such thing as a zero- or negative-byte frame budget.
#[test]
fn parses_frame_rejects_non_positive_budget() {
    let src = "fn test():\n    frame(0):\n        let x = 1\n";
    assert!(Driver::parse(src).is_err(), "`frame(0):` must be rejected at parse time");
}

/// `frame(N):` rejects a non-integer-literal budget (an arbitrary
/// expression), mirroring the same rule for `arena Name: Type = N`: the
/// budget has to be known without evaluating anything, since it sizes a
/// codegen-time bounds check.
#[test]
fn parses_frame_rejects_non_integer_budget() {
    let src = "fn test():\n    let n = 4096\n    frame(n):\n        let x = 1\n";
    assert!(Driver::parse(src).is_err(), "`frame(n):` (an identifier, not a literal) must be rejected at parse time");
}

/// `frame(N):` rejects a budget above `crate::types::MAX_FRAME_BUDGET` at
/// check time, mirroring `checks_arena_capacity_above_max_is_rejected`.
#[test]
fn checks_frame_budget_above_max_is_rejected() {
    let src = "fn test():\n    frame(20000000):\n        let x = 1\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "a `frame` budget above MAX_FRAME_BUDGET must be rejected");
}

/// A `frame(N):` budget within bounds must check cleanly -- the positive
/// counterpart to `checks_frame_budget_above_max_is_rejected`.
#[test]
fn checks_frame_budget_within_max_is_accepted() {
    let src = "fn test():\n    frame(1000000):\n        let x = 1\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "a `frame` budget within MAX_FRAME_BUDGET must be accepted");
}

/// The physical `@frame.buf` backing buffer is always sized to
/// `crate::types::MAX_FRAME_BUDGET` (16 MiB) regardless of what any
/// individual `frame:` block in the program requests -- see
/// `Codegen::FRAME_BUF_SIZE`'s doc comment for why a single shared,
/// worst-case-sized buffer is used instead of a program-specific tight fit.
#[test]
fn codegen_frame_buffer_is_sized_to_the_fixed_maximum() {
    let src = "fn test():\n    frame:\n        let x = 1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(
        ir.contains("@frame.buf = global [16777216 x i8] zeroinitializer"),
        "the shared frame buffer should always be allocated at the 16 MiB maximum: {}",
        ir
    );
}

/// The bounds check inside a `frame(N):` block's own bump-allocator codegen
/// compares against that block's *own* configured budget, not the physical
/// buffer's fixed 16 MiB capacity -- i.e. `frame(64):` still aborts after 64
/// bytes even though the shared buffer underneath it is far larger.
#[test]
fn codegen_frame_alloc_bounds_check_uses_configured_budget_not_buffer_size() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\nfn test():\n    frame(64):\n        let p = Point(1, 2)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let icmp_line = ir.lines().find(|l| l.contains("icmp ugt i64")).unwrap_or_else(|| panic!("no `icmp ugt i64` bounds check found: {}", ir));
    assert!(
        icmp_line.trim_end().ends_with(", 64"),
        "the bounds check should compare against this block's own 64-byte budget, not the buffer's 16 MiB capacity: {}",
        icmp_line
    );
    assert!(!ir.contains("exceeded its 4096-byte capacity"), "the abort message must name this block's own budget, not the old default: {}", ir);
    assert!(ir.contains("exceeded its 64-byte capacity"), "the abort message should name the configured 64-byte budget: {}", ir);
}

/// End-to-end: the exact allocation `examples/frame_overflow.star` proves
/// aborts under the un-overridden 4096-byte default succeeds cleanly when
/// its enclosing `frame:` block raises its own budget with `frame(N):`.
/// This is the actual motivating case from todo.md/ASSESSMENT.md -- a
/// program that needs more than 4096 bytes of per-tick scratch space
/// (path-finding nodes, a modest fixed-size grid, ...) no longer has to
/// restructure its allocations around a hardcoded ceiling.
#[test]
fn runtime_frame_budget_override_allows_a_larger_allocation_end_to_end() {
    let src = "struct Big:\n    a: [i32; 1200]\n\nfn main():\n    frame(8192):\n        let b = Big([0; 1200])\n        println(f\"{b.a[0]}\")\n";
    let output = compile_and_run("frame_budget_override_allows_larger_allocation", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "0", "the program should run to completion under the raised budget: {}", stdout);
}

/// The same allocation as the previous test, but wrapped in a bare `frame:`
/// (no override) instead -- proving the *default* budget is still 4096
/// bytes and this exact 4800-byte allocation (`[i32; 1200]`) still aborts
/// without an explicit override, so the previous test's success is really
/// due to the override and not some unrelated change in default behavior.
#[test]
fn runtime_frame_default_budget_still_aborts_on_the_same_allocation_end_to_end() {
    let src = "struct Big:\n    a: [i32; 1200]\n\nfn main():\n    frame:\n        let b = Big([0; 1200])\n        println(f\"{b.a[0]}\")\n";
    let output = compile_and_run("frame_default_budget_still_aborts", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("exceeded its 4096-byte capacity"), "should still abort under the un-overridden default: {}", stdout);
    assert_eq!(output.status.code(), Some(1));
}

/// The overflow-abort message names *this block's own* configured budget,
/// not the old hardcoded 4096 -- the direct counterpart to
/// `runtime_configurable_arena_capacity_overflow_warns_with_actual_capacity_end_to_end`.
#[test]
fn runtime_frame_budget_override_abort_message_names_configured_budget_end_to_end() {
    let src = "struct Pair:\n    a: i32\n    b: i32\n\nfn main():\n    frame(16):\n        let p1 = Pair(1, 2)\n        let p2 = Pair(3, 4)\n        let p3 = Pair(5, 6)\n        println(f\"{p3.a}\")\n";
    let output = compile_and_run("frame_budget_override_abort_names_configured_budget", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("exceeded its 16-byte capacity"), "the abort message should name this block's own configured 16-byte budget: {}", stdout);
    assert!(!stdout.contains("4096"), "the abort message must not mention the unrelated default: {}", stdout);
    assert_eq!(output.status.code(), Some(1));
}

/// Nested `frame:` blocks with *different* budgets each enforce their own
/// bound independently, and the outer block's budget is correctly restored
/// once the inner block exits (mirroring how `in_frame` itself is
/// saved/restored around `emit_frame_body`): an outer `frame(4096):` first
/// makes a small allocation, then a nested `frame(65536):` block makes a
/// large allocation that would have aborted under the outer block's own
/// budget (proving the inner budget, not the outer one, is what's actually
/// enforced inside it), and after the inner block exits, the outer block's
/// own 4096-byte budget is enforced again -- a further allocation back in
/// the outer scope that only fits because the inner block's bytes were
/// never charged against the outer budget in the first place.
#[test]
fn runtime_nested_frame_blocks_enforce_independent_budgets_end_to_end() {
    let src = concat!(
        "struct Small:\n",
        "    x: i32\n",
        "struct Grid:\n",
        "    cells: [i32; 8000]\n",
        "fn main():\n",
        "    frame(4096):\n",
        "        let s1 = Small(1)\n",
        "        frame(65536):\n",
        "            let g = Grid([7; 8000])\n",
        "            println(f\"{g.cells[0]}\")\n",
        "        let s2 = Small(2)\n",
        "        println(f\"{s1.x + s2.x}\")\n",
    );
    let output = compile_and_run("nested_frame_blocks_independent_budgets", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.trim_end().lines().collect();
    assert_eq!(lines, vec!["7", "3"], "both the inner large allocation and the outer post-inner allocation should succeed: {}", stdout);
}
