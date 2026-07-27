//! M7: `spawn`/`despawn`, arena capacity, `each` iteration
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// --- `spawn` (arena population) -------------------------------------------

/// Parse `spawn ArenaName(args...)`.
#[test]
fn parses_spawn_stmt() {
    let src = "fn t():\n    spawn Enemies(10)\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Spawn { arena, args, .. } = &f.body.stmts[0] else { panic!("expected Spawn") };
    assert_eq!(arena, "Enemies");
    assert!(matches!(args[0], Expr::Int(10, _)));
}

/// `spawn` into a struct-typed arena with the right argument count type-checks.
#[test]
fn accepts_spawn_valid() {
    let src = format!("{}fn t():\n    spawn Enemies(10)\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "valid spawn should type-check: {:?}", Driver::check(&module).err());
}

/// `spawn` into an undefined arena is a type error.
#[test]
fn rejects_spawn_undefined_arena() {
    let module = Driver::parse("fn t():\n    spawn Nope(10)\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "spawn into an undefined arena should be a type error");
}

/// `spawn` with the wrong number of constructor arguments is a type error.
#[test]
fn rejects_spawn_wrong_arity() {
    let src = format!("{}fn t():\n    spawn Enemies(1, 2)\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "wrong spawn arity should be a type error");
}

/// `spawn` inside a `par`/`swarm` body is rejected: every worker thread
/// would race on the same arena's `count`/`data` globals, so population
/// can't be proven disjoint the way loop-variable field writes can.
#[test]
fn rejects_spawn_inside_par() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        spawn Enemies(5)\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "spawn inside a par/swarm body should be a type error");
}

/// Codegen for `spawn`: lazily `malloc`s the arena's backing array on first
/// use, appends the constructed element at `data[count]`, and bumps `count`.
#[test]
fn codegen_spawn_allocates_and_appends() {
    let src = format!("{}fn t():\n    spawn Enemies(10)\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    assert!(ir.contains("icmp eq %Enemy* "), "should check for a null backing array: {}", ir);
    assert!(ir.contains("call i8* @malloc("), "should lazily malloc the backing array: {}", ir);
    assert!(ir.contains("load i64, i64* @arena.Enemies.count"), "should read the live count: {}", ir);
    assert!(
        ir.contains("getelementptr inbounds %Enemy, %Enemy*") && ir.contains("store %Enemy "),
        "should store the constructed element into the backing array: {}",
        ir
    );
    assert!(ir.contains("add i64"), "count should be incremented: {}", ir);
    assert!(ir.contains("store i64"), "incremented count should be stored back: {}", ir);
}

/// Runtime test: the compiled `spawn.exe` populates an arena via `spawn`,
/// mutates every live element in parallel via `par`, then reads the results
/// back via `swarm` -- proving arena population actually feeds real data to
/// `par`/`swarm` iteration, end to end through a real clang-compiled binary.
#[test]
fn runtime_spawn_populates_arena_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/spawn.exe").output().expect("failed to execute spawn.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("hp: 9"), "first spawned enemy should read back decremented: {}", stdout);
    assert!(stdout.contains("hp: 19"), "second spawned enemy should read back decremented: {}", stdout);
    assert!(stdout.contains("hp: 29"), "third spawned enemy should read back decremented: {}", stdout);
}

// --- `spawn` as an expression: `let name = spawn ArenaName(args...)` ------
// (`projects/snake/NOTES.md` section 2.2, "`spawn` is fire-and-forget -- no
// handle to what you just spawned")

/// `let idx = spawn ArenaName(args...)` parses `value` as `Expr::Spawn`,
/// distinct from the bare-statement `Stmt::Spawn` form parsed above.
#[test]
fn parses_spawn_expr_as_let_initializer() {
    let src = "fn t():\n    let idx = spawn Enemies(10)\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected Let") };
    let Expr::Spawn { arena, args, .. } = value else { panic!("expected Expr::Spawn") };
    assert_eq!(arena, "Enemies");
    assert!(matches!(args[0], Expr::Int(10, _)));
}

/// `spawn` is only recognized as an expression directly on a `let`'s RHS --
/// everywhere else (`return`, a call argument) it's still just the bare-
/// statement keyword, so it's a parse error in those positions (see
/// `Expr::Spawn`'s doc comment for why this is scoped this narrowly: it
/// keeps every pass that walks `Expr`/`TypedExpr` generically, like
/// par/swarm disjointness and frame-escape analysis, from ever having to
/// handle this node nested arbitrarily deep inside another expression).
#[test]
fn rejects_spawn_expr_outside_let_initializer() {
    let module = Driver::parse("fn t() -> i32:\n    return spawn Enemies(10)\n");
    assert!(module.is_err(), "`spawn` in return position should be a parse error");
}

/// Same restriction, a different non-`let` expression position.
#[test]
fn rejects_spawn_expr_as_call_argument() {
    let module = Driver::parse("fn t():\n    print(spawn Enemies(10))\n");
    assert!(module.is_err(), "`spawn` as a call argument should be a parse error");
}

/// A valid `let idx = spawn ArenaName(args...)` type-checks.
#[test]
fn accepts_spawn_expr_valid() {
    let src = format!("{}fn t():\n    let idx = spawn Enemies(10)\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "valid spawn-expr should type-check: {:?}", Driver::check(&module).err());
}

/// `let idx: i32 = spawn Enemies(10)` type-checks (confirming the checker
/// really infers `Ty::Int` for `Expr::Spawn`, not an unconstrained/wildcard
/// type that would happen to satisfy any annotation).
#[test]
fn accepts_spawn_expr_result_annotated_as_int() {
    let src = format!("{}fn t():\n    let idx: i32 = spawn Enemies(10)\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "spawn-expr's result should satisfy an `i32` annotation: {:?}", Driver::check(&module).err());
}

/// `let idx: str = spawn Enemies(10)` is a type mismatch -- the other half
/// of the same confirmation: `Expr::Spawn` is concretely `i32`, not `str`.
#[test]
fn rejects_spawn_expr_result_used_as_wrong_type() {
    let src = format!("{}fn t():\n    let idx: str = spawn Enemies(10)\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "spawn-expr's result is i32, not str");
}

/// `spawn`-as-expression into an undefined arena is a type error, same as
/// the statement form.
#[test]
fn rejects_spawn_expr_undefined_arena() {
    let module = Driver::parse("fn t():\n    let idx = spawn Nope(10)\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "spawn-expr into an undefined arena should be a type error");
}

/// `spawn`-as-expression with the wrong constructor arity is a type error,
/// same as the statement form.
#[test]
fn rejects_spawn_expr_wrong_arity() {
    let src = format!("{}fn t():\n    let idx = spawn Enemies(1, 2)\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "wrong spawn-expr arity should be a type error");
}

/// `spawn` used as an expression inside a `par`/`swarm` body is banned for
/// the same reason the statement form is (`rejects_spawn_inside_par`):
/// population isn't disjoint across worker threads.
#[test]
fn rejects_spawn_expr_inside_par() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        let idx = spawn Enemies(5)\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "spawn-expr inside a par/swarm body should be a type error");
}

/// The same transitive-hazard-through-a-helper-call ban already proven for
/// the statement form (`rejects_spawn_hidden_behind_helper_function_call_inside_par`)
/// must also catch the expression form -- otherwise rewriting a hidden
/// `spawn Enemies(5)` to `let _ = spawn Enemies(5)` inside a helper would
/// have silently punched a hole straight through an existing safety ban.
#[test]
fn rejects_spawn_expr_hidden_behind_helper_function_call_inside_par() {
    let src = format!(
        "{}fn sneaky_spawn() -> i32:\n    let idx = spawn Enemies(5)\n    return idx\n\nfn t():\n    par e in Enemies:\n        sneaky_spawn()\n        e.hp -= 1\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let errs = Driver::check(&module).expect_err("spawn-expr hidden behind a helper function call should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("sneaky_spawn")), "{:?}", errs);
}

/// `let idx = spawn ArenaName(frame_local)` is the same frame-escape hazard
/// as the statement form (`rejects_spawn_using_frame_local_struct`): the
/// arena outlives the `frame:` scope the constructor argument was allocated
/// in.
#[test]
fn rejects_spawn_expr_using_frame_local_struct() {
    let src = format!(
        "{}struct Enemy:\n    pos: Point\n\narena Enemies: Enemy\n\nfn t():\n    frame:\n        let temp = Point(1, 1)\n        let idx = spawn Enemies(temp)\n",
        FRAME_ESCAPE_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let errs = Driver::check(&module).expect_err("spawn-expr with a frame-local struct argument should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("frame")), "error should mention the frame escape: {:?}", errs);
}

/// Codegen for `spawn`-as-expression: same allocate/store/bump-generation
/// machinery as the statement form (`codegen_spawn_allocates_and_appends`),
/// plus a final `phi i32` merging the real (truncated) slot index with the
/// `-1` dropped-spawn sentinel used when the arena was full.
#[test]
fn codegen_spawn_expr_returns_phi_of_index_and_drop_sentinel() {
    let src = format!("{}fn t():\n    let idx = spawn Enemies(10)\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("call i8* @malloc("), "should lazily malloc the backing array: {}", ir);
    assert!(ir.contains("trunc i64") && ir.contains("to i32"), "should truncate the i64 slot index to i32: {}", ir);
    assert!(ir.contains("phi i32") && ir.contains("-1"), "should phi the real index against the -1 drop sentinel: {}", ir);
}

/// Runtime test: three successive `let idx = spawn ...` calls report the
/// arena's actual sequential slot indices (0, 1, 2) -- the core promise of
/// this feature (`NOTES.md` 2.2): the caller finally learns *which* slot it
/// just populated, instead of only ever being able to assume index 0 (as
/// `examples/arena_freelist.star` was forced to before this).
#[test]
fn runtime_spawn_expr_returns_sequential_indices_end_to_end() {
    let src = concat!(
        "struct Enemy:\n",
        "    mut hp: i32\n",
        "arena Enemies: Enemy\n",
        "fn main():\n",
        "    let a = spawn Enemies(10)\n",
        "    let b = spawn Enemies(20)\n",
        "    let c = spawn Enemies(30)\n",
        "    println(f\"{a} {b} {c}\")\n",
    );
    let output = compile_and_run("spawn_expr_sequential_indices", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.replace("\r\n", "\n").trim_end(), "0 1 2", "{}", stdout);
}

/// Runtime test: after a `despawn`, the freed slot's index is reused by the
/// next `spawn` (see `emit_spawn_inner`'s free-list preference) -- `let idx
/// = spawn ...` must report the entity's *actual* landing slot, not just an
/// ever-incrementing counter, or the index it hands back would be useless
/// for building a `GenRef` to the right slot.
#[test]
fn runtime_spawn_expr_reports_reused_freed_slot_index_end_to_end() {
    let src = concat!(
        "struct Enemy:\n",
        "    mut hp: i32\n",
        "arena Enemies: Enemy\n",
        "fn main():\n",
        "    let a = spawn Enemies(10)\n",
        "    let b = spawn Enemies(20)\n",
        "    despawn Enemies[a]\n",
        "    let c = spawn Enemies(30)\n",
        "    println(f\"{a} {b} {c}\")\n",
    );
    let output = compile_and_run("spawn_expr_reused_slot_index", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(
        stdout.replace("\r\n", "\n").trim_end(),
        "0 1 0",
        "reusing a freed slot should report that slot's own index, not a fresh one: {}",
        stdout
    );
}

/// Runtime test: spawning past a full arena reports the `-1` drop sentinel
/// instead of a garbage/uninitialized value or a crash -- the same "safe
/// sentinel on failure" convention as `GenRef`'s stale/out-of-bounds reads.
#[test]
fn runtime_spawn_expr_returns_negative_one_when_arena_full_end_to_end() {
    let src = concat!(
        "struct Enemy:\n",
        "    mut hp: i32\n",
        "arena Enemies: Enemy = 2\n",
        "fn main():\n",
        "    let a = spawn Enemies(1)\n",
        "    let b = spawn Enemies(2)\n",
        "    let c = spawn Enemies(3)\n",
        "    println(f\"{a} {b} {c}\")\n",
    );
    let output = compile_and_run("spawn_expr_overflow_sentinel", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    // The once-only overflow warning (`emit_spawn_inner`'s
    // `capacity_warn_label`) also prints to stdout ahead of our own
    // `println` -- only the last line is this test's own output.
    let last_line = stdout.replace("\r\n", "\n").trim_end().lines().last().unwrap_or("").to_string();
    assert_eq!(
        last_line,
        "0 1 -1",
        "the third spawn should report -1 once the arena is full, not a garbage index: {}",
        stdout
    );
}

/// End-to-end test of the actual motivating use case from `NOTES.md` 2.2:
/// grab a live `GenRef` handle to the entity a `spawn` call just created.
/// Previously impossible for anything but slot 0 (right after an arena's
/// first-ever spawn) -- `examples/arena_freelist.star`'s own example leaned
/// on that one hardcoded case. Spawns three enemies, keeps the *second*
/// one's reported index, builds a `GenRef` from it, mutates through that
/// handle, then reads the mutation back through an independently
/// constructed second `GenRef` to the same slot -- proving the index
/// `spawn` reported really does name the live slot those constructor
/// arguments landed in, not some other one.
#[test]
fn runtime_spawn_expr_index_feeds_genref_to_just_spawned_entity_end_to_end() {
    let src = concat!(
        "struct Enemy:\n",
        "    mut hp: i32\n",
        "arena Enemies: Enemy\n",
        "fn main():\n",
        "    spawn Enemies(1)\n",
        "    let target = spawn Enemies(50)\n",
        "    spawn Enemies(3)\n",
        "    let handle = GenRef<Enemy>(target)\n",
        "    handle[0].hp -= 5\n",
        "    let check = GenRef<Enemy>(target)\n",
        "    println(f\"hp={check[0].hp}\")\n",
    );
    let output = compile_and_run("spawn_expr_genref_to_just_spawned", src);
    assert!(output.status.success(), "{:?}\nstderr: {}", output.status, String::from_utf8_lossy(&output.stderr));
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(
        stdout.replace("\r\n", "\n").trim_end(),
        "hp=45",
        "the GenRef built from spawn's reported index should reach the entity actually just constructed: {}",
        stdout
    );
}

// --- `despawn` / `GenRef` lifecycle ----------------------------------------

/// Parse `despawn ArenaName[index]`.
#[test]
fn parses_despawn_stmt() {
    let src = "fn t():\n    despawn Enemies[0]\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Despawn { arena, index, .. } = &f.body.stmts[0] else { panic!("expected Despawn") };
    assert_eq!(arena, "Enemies");
    assert!(matches!(index, Expr::Int(0, _)));
}

/// `despawn` on an undefined arena is a type error.
#[test]
fn rejects_despawn_undefined_arena() {
    let module = Driver::parse("fn t():\n    despawn Nope[0]\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "despawn on an undefined arena should be a type error");
}

/// `despawn` inside a `par`/`swarm` body is rejected: every worker thread
/// would race on the same arena's `gen` global, just like `spawn` races on
/// `count`/`data`.
#[test]
fn rejects_despawn_inside_par() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        despawn Enemies[0]\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "despawn inside a par/swarm body should be a type error");
}

/// `GenRef<T>` with no arena declared for `T` is a type error -- there's no
/// slot-map storage to back the reference.
#[test]
fn rejects_genref_without_backing_arena() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\nfn t():\n    GenRef<Point>(0)\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "GenRef<T> with no backing arena should be a type error");
}

/// `GenRef<T>` is ambiguous when two arenas both hold element type `T`.
#[test]
fn rejects_genref_with_ambiguous_backing_arena() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\narena A: Point\narena B: Point\n\nfn t():\n    GenRef<Point>(0)\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "GenRef<T> with two backing arenas should be a type error");
}

/// Runtime test: a `GenRef` dereferenced after its slot is despawned falls
/// back to the element type's zero value instead of returning stale data or
/// crashing -- the flagship safety guarantee generational references exist
/// for, proven end to end through a real compiled binary.
#[test]
fn runtime_genref_stale_after_despawn_falls_back_to_zero() {
    use std::process::Command;

    let output = Command::new("examples/genref_lifecycle.exe").output().expect("failed to execute genref_lifecycle.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before: 100"), "live reference should read real data: {}", stdout);
    assert!(stdout.contains("after: 0"), "stale reference should fall back to zero, not crash or read stale data: {}", stdout);
}

/// Regression test for a real, reproduced ABA bypass: with a 32-bit
/// generation counter (the width this codegen used before this fix), one
/// arena slot cycled through despawn+spawn exactly 2^31 times returns its
/// live generation to the exact bit pattern a `GenRef` captured *before*
/// that churn still holds -- `2^31` cycles at +2 generation/cycle (+1 for
/// despawn, +1 for the reclaiming spawn) wraps a 32-bit counter by exactly
/// one full lap back to the same value. A stale handle would then pass both
/// the equality *and* liveness-parity checks in `emit_genref_index` and
/// read the new, unrelated occupant's data instead of being caught as
/// stale -- confirmed for real (before this fix) via this exact program:
/// `old_ref[0].hp` read back `777`, the marker written by the final spawn
/// of the wraparound cycle, not `0`. `codegen::arena` now stores the
/// generation counter as `i64` (see `%GenRef`'s decl in `Codegen::emit`),
/// so the identical attack needs `2^63` cycles instead of `2^31` -- not
/// reachable in any realistic program's lifetime. This test runs the exact
/// `2^31`-cycle wraparound point a 32-bit counter would have failed at and
/// asserts the handle is still correctly detected as stale (reads back `0`,
/// not `777`) -- takes on the order of 30 seconds since it's a real
/// 2.1-billion-iteration loop, not a shortcut simulation of the bug.
#[test]
fn runtime_genref_generation_counter_does_not_alias_after_i32_would_have_wrapped() {
    let src = "struct Entity:\n    hp: i32\n\narena Entities: Entity\n\nfn main():\n    spawn Entities(100)\n    let old_ref = GenRef<Entity>(0)\n    let total: i64 = 2147483648 as i64\n    let mut i: i64 = 0 as i64\n    while i < (total - (1 as i64)):\n        despawn Entities[0]\n        spawn Entities(200)\n        i = i + (1 as i64)\n    despawn Entities[0]\n    spawn Entities(777)\n    let via_old = old_ref[0]\n    print(f\"via_old.hp: {via_old.hp}\")\n";
    let output = compile_and_run("genref_generation_wrap", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(
        stdout.contains("via_old.hp: 0"),
        "a stale GenRef captured before a 2^31-cycle generation wraparound must still read back the zero value, not alias the new occupant's data (777) -- a 32-bit generation counter would fail this: {}",
        stdout
    );
}

// --- arena free-list (slot reclamation) ------------------------------------

/// Codegen for `despawn`: pushes the freed slot onto the arena's free-list
/// (guarded by a generation-parity liveness check) instead of only bumping
/// the generation counter, so a later `spawn` can reclaim the slot's memory.
#[test]
fn codegen_despawn_pushes_freed_slot_onto_freelist() {
    let src = format!("{}fn t():\n    despawn Enemies[0]\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    assert!(ir.contains("@arena.Enemies.free ="), "arena should declare a free-list global: {}", ir);
    assert!(ir.contains("@arena.Enemies.free_top ="), "arena should declare a free-list top-of-stack counter: {}", ir);
    assert!(ir.contains("and i64"), "despawn should check generation parity (64-bit generation counter) before freeing: {}", ir);
    assert!(
        ir.contains("getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free"),
        "despawn should write the freed index into the free-list: {}",
        ir
    );
}

/// Codegen for `spawn`: pops a slot off the arena's free-list when one is
/// available instead of unconditionally growing `count`.
#[test]
fn codegen_spawn_reuses_freed_slot_before_growing() {
    let src = format!("{}fn t():\n    spawn Enemies(10)\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    assert!(ir.contains("load i64, i64* @arena.Enemies.free_top"), "spawn should check the free-list before growing: {}", ir);
    assert!(ir.contains("icmp sgt i64"), "spawn should branch on whether the free-list is non-empty: {}", ir);
    assert!(ir.contains("spawn_reuse"), "spawn should have a slot-reuse path: {}", ir);
    assert!(ir.contains("spawn_grow"), "spawn should have a count-growing fallback path: {}", ir);
}

/// Regression test: `@arena.{name}.count` is a high-water mark of
/// ever-allocated slots, not a live count -- `despawn` never decrements it,
/// only bumps the slot's generation and pushes it onto the free-list (see
/// `codegen_despawn_pushes_freed_slot_onto_freelist`). Before this fix, the
/// `par`/`swarm` worker loop walked `[start, end)` over that raw index range
/// with no liveness check at all, so it visited despawned "holes" exactly
/// like live slots -- for an RC-bearing element type this reads/retains a
/// pointer `despawn` already released (a use-after-free), and even for
/// plain data it processes an entity that's supposed to no longer exist.
/// The generated worker must gate each slot on its generation's parity
/// before running the loop body.
#[test]
fn codegen_par_worker_skips_despawned_slots() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let worker_ir = extract_fn_body(&ir, "define i32 @par_worker_0(");
    assert!(
        worker_ir.contains("@arena.Enemies.gen"),
        "par worker should check the slot's generation before visiting it: {}",
        worker_ir
    );
    assert!(worker_ir.contains("par_live"), "par worker should branch around despawned slots: {}", worker_ir);
    assert!(worker_ir.contains("par_incr"), "the increment/next-iteration path must be reachable whether or not a slot is skipped: {}", worker_ir);
}

/// Runtime test: `despawn` pushes a slot onto the arena's free-list and the
/// next `spawn` reclaims that same slot rather than growing the arena, while
/// the generation bump still keeps a `GenRef` taken before the despawn from
/// aliasing the slot's new occupant (no ABA bug on reuse).
#[test]
fn runtime_spawn_reuses_despawned_slot_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/arena_freelist.exe").output().expect("failed to execute arena_freelist.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("via_old: 0"), "GenRef captured before despawn must not alias the slot's new occupant: {}", stdout);
    assert!(stdout.contains("via_new: 200"), "GenRef captured after the slot is reused should read the new occupant: {}", stdout);
}

/// Runtime test: despawning an already-despawned slot must not push it onto
/// the free-list twice -- otherwise two later spawns would both reclaim the
/// same slot, aliasing each other's memory, instead of one reusing the freed
/// slot and the other growing the arena.
#[test]
fn runtime_double_despawn_does_not_double_free_slot() {
    use std::process::Command;

    let output = Command::new("examples/arena_freelist_double_despawn.exe")
        .output()
        .expect("failed to execute arena_freelist_double_despawn.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("slot0: 200"), "reused slot should hold the second spawn's value: {}", stdout);
    assert!(stdout.contains("slot1: 300"), "third spawn should grow into a fresh slot, not alias slot 0: {}", stdout);
}

/// Runtime regression test for the same bug `codegen_par_worker_skips_despawned_slots`
/// checks at the IR level, but exercised end to end against an RC-bearing
/// element field (`str`), where the consequence isn't just "wrong
/// results" but an actual use-after-free: `despawn` releases a dead slot's
/// `str` field (see `emit_despawn_stmt`), so a `par` body that reads it
/// (retaining an already-released/possibly-freed pointer, then releasing it
/// again at the end of that iteration) would previously crash or corrupt
/// the heap. Also verifies the still-live entities are correctly visited
/// and mutated, so the despawned-slot skip doesn't accidentally skip real
/// work too.
///
/// This test also caught a second, independent bug while it was being
/// written: `emit_par_stmt` swapped out `self.ir`/`self.symbols` for the
/// worker function's own but never did the same for `self.owned_stack`
/// (the release-at-scope-exit bookkeeping, see `rc.rs`), and never wrapped
/// the loop body in its own `push_scope`/`pop_scope` at all. An RC-owned
/// local declared inside the body (`let t: str = e.name`, right below) got
/// `track_owned`'d onto whatever scope frame happened to be open in the
/// *caller* at the time `par` was codegen'd, rather than the worker's own
/// -- so once codegen returned and the caller's frame was eventually
/// popped, it tried to release a register (`%tN`) that was only ever
/// defined in the worker function's separate IR buffer, producing invalid
/// IR ("use of undefined value") at the `clang` step regardless of the
/// despawn/generation-parity fix above. Fixed alongside it.
#[test]
fn runtime_par_skips_despawned_slot_end_to_end() {
    let src = concat!(
        "struct Enemy:\n",
        "    mut hp: i32\n",
        "    name: str\n",
        "arena Enemies: Enemy\n",
        "fn main():\n",
        "    spawn Enemies(1, \"keep-a\")\n",
        "    spawn Enemies(2, \"keep-b\")\n",
        "    spawn Enemies(3, \"dead-c\")\n",
        "    despawn Enemies[2]\n",
        "    par e in Enemies:\n",
        "        let t: str = e.name\n",
        "        e.hp -= 100\n",
        "    let r0 = GenRef<Enemy>(0)\n",
        "    let r1 = GenRef<Enemy>(1)\n",
        "    println(f\"hp0={r0[0].hp} hp1={r1[0].hp}\")\n",
    );
    let output = compile_and_run("par_skips_despawned", src);
    assert!(
        output.status.success(),
        "reading a despawned slot's already-released str field from inside par must not crash: {:?}\nstdout: {}\nstderr: {}",
        output.status,
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "hp0=-99 hp1=-98", "both still-live entities should still be visited and mutated: {}", stdout);
}

// --- gap 2.1: `each item, idx in Arena:` binds the slot index, so a scan --
// --- can now conditionally `despawn` -------------------------------------

/// `each item, idx in ArenaName:` binds a second, plain `i32` local holding
/// the current element's raw slot index -- the missing piece that made
/// "scan every entity, despawn the ones matching a runtime condition"
/// (`projects/snake/NOTES.md` section 2.1) impossible: `despawn` was never
/// actually banned inside `each` (only inside `par`/`swarm`), but there was
/// no expression naming the slot to reclaim. Confirms the whole pattern end
/// to end: two of four spawned entities are marked dead, a second `each`
/// scan conditionally despawns them by their bound index, a third scan
/// shows only the two survivors remain, and a follow-up `spawn` reuses one
/// of the freed slots via the ordinary free-list (`emit_spawn_stmt`).
#[test]
fn runtime_each_index_conditional_despawn_end_to_end() {
    let src = concat!(
        "struct Particle:\n",
        "    mut hp: i32\n",
        "    mut dead: bool\n",
        "arena Particles: Particle\n",
        "fn main():\n",
        "    spawn Particles(1, false)\n",
        "    spawn Particles(2, false)\n",
        "    spawn Particles(3, false)\n",
        "    spawn Particles(4, false)\n",
        "    each p, i in Particles:\n",
        "        if p.hp == 2 or p.hp == 4:\n",
        "            p.dead = true\n",
        "    each p, i in Particles:\n",
        "        if p.dead:\n",
        "            despawn Particles[i]\n",
        "    each p, i in Particles:\n",
        "        println(f\"slot {i}: hp={p.hp}\")\n",
        "    spawn Particles(99, false)\n",
        "    each p, i in Particles:\n",
        "        println(f\"slot {i}: hp={p.hp}\")\n",
    );
    let output = compile_and_run("each_index_despawn", src);
    assert!(
        output.status.success(),
        "conditionally despawning during an `each` scan must not crash: {:?}\nstderr: {}",
        output.status,
        String::from_utf8_lossy(&output.stderr)
    );
    let stdout = String::from_utf8_lossy(&output.stdout);
    // Windows text-mode stdout translates each `\n` to `\r\n` (see
    // `runtime_sequence_end_to_end`'s identical note), so normalize before
    // comparing rather than embedding literal `\r\n` in the expected string.
    assert_eq!(
        stdout.replace("\r\n", "\n").trim_end(),
        "slot 0: hp=1\nslot 2: hp=3\nslot 0: hp=1\nslot 2: hp=3\nslot 3: hp=99",
        "hp=2/hp=4 slots should be gone after the conditional despawn, and the respawn should reuse a freed slot off the free-list: {}",
        stdout
    );
}

/// `each item, idx in Arena:` rejects binding the same name to both the
/// element and the index -- otherwise one of the two bindings would
/// silently shadow the other inside the body with no diagnostic at all.
#[test]
fn checks_each_rejects_same_name_element_and_index_binding() {
    let src = "struct P:\n    hp: i32\narena Foo: P\nfn main():\n    each p, p in Foo:\n        print(\"x\")\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "`each p, p in Foo:` must be rejected: the index binding needs a distinct name");
}

// --- arena capacity is now configurable, not one shared hardcoded constant -

/// `arena Name: Type = N` overrides the default 1024-element capacity.
/// Spawning past the *configured* capacity (not the old fixed default)
/// still warns instead of silently dropping -- and the warning names the
/// arena's own real capacity, not a stale constant.
#[test]
fn runtime_configurable_arena_capacity_overflow_warns_with_actual_capacity_end_to_end() {
    let src = concat!(
        "struct Bullet:\n",
        "    hp: i32\n",
        "arena Bullets: Bullet = 4\n",
        "fn main():\n",
        "    for i in 0..6:\n",
        "        spawn Bullets(i)\n",
        "    println(\"done\")\n",
    );
    let output = compile_and_run("small_arena_capacity", src);
    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("arena `Bullets` is full (4 live elements)"), "warning should report this arena's own configured capacity, not the old fixed 1024: {}", stdout);
    assert!(stdout.contains("done"), "the program should still run to completion: {}", stdout);
}

/// The overflow warning latches after the first print per arena, so a body
/// that keeps `spawn`-ing into an already-full arena (an enemy spawner that
/// never checks back, say) doesn't flood the console with the same line
/// forever -- confirmed by triggering the overflow path many times over and
/// counting exactly one occurrence of the warning in the output.
#[test]
fn runtime_arena_overflow_warning_prints_only_once_end_to_end() {
    let src = concat!(
        "struct Bullet:\n",
        "    hp: i32\n",
        "arena Bullets: Bullet = 2\n",
        "fn main():\n",
        "    for i in 0..40:\n",
        "        spawn Bullets(i)\n",
        "    println(\"done\")\n",
    );
    let output = compile_and_run("dedup_arena_capacity_warning", src);
    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    let occurrences = stdout.matches("is full").count();
    assert_eq!(occurrences, 1, "the overflow warning should print exactly once no matter how many further spawns overflow the same arena: {}", stdout);
}

/// `arena Name: Type = N` rejects a capacity above
/// `crate::types::MAX_ARENA_CAPACITY` -- an unreasonably large per-arena
/// capacity would `malloc` a correspondingly huge backing array the moment
/// anything is first spawned into it (see `emit_spawn_stmt`).
#[test]
fn checks_arena_capacity_above_max_is_rejected() {
    let src = "struct P:\n    hp: i32\narena Big: P = 5000000\nfn main():\n    spawn Big(1)\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "an arena capacity above MAX_ARENA_CAPACITY must be rejected");
}

/// `arena Name: Type = N` rejects a non-positive capacity literal outright
/// at parse time (there's no such thing as a zero- or negative-element
/// arena).
#[test]
fn parses_arena_rejects_non_positive_capacity() {
    let src = "struct P:\n    hp: i32\narena Bad: P = 0\nfn main():\n    spawn Bad(1)\n";
    assert!(Driver::parse(src).is_err(), "`arena Bad: P = 0` must be rejected at parse time");
}

/// `each item, idx in ArenaName:` parses to a dedicated `Stmt::Each` with
/// `index_var` set, distinct from the single-binding `each item in
/// ArenaName:` form (`index_var: None`) that already existed (see
/// `parses_each_stmt`).
#[test]
fn parses_each_with_index_binding() {
    let src = "fn t():\n    each item, idx in Foo:\n        print(\"x\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Each { var, index_var, arena, .. } = &f.body.stmts[0] else { panic!("expected Each") };
    assert_eq!(var, "item");
    assert_eq!(index_var.as_deref(), Some("idx"));
    assert_eq!(arena, "Foo");
}
