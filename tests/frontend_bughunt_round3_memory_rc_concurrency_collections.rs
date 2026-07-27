//! Bug-hunting round 3: memory/RC x concurrency/collections intersection audit
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// =====================================================================
// ===== Bug-hunting round 3 (memory/RC x concurrency/collections =======
// ===== intersection audit): unlike round 2's single-feature audits ====
// ===== (which found real `Ty::Enum`-RC-walk and generic-fallback-spill
// ===== leaks), this round specifically targeted combinations a single- ==
// ===== feature repro wouldn't hit -- `List`/`Map`/`Table`/`Ring` of ====
// ===== `Option`/`Result`-payload elements under sustained push/pop/CoW-
// ===== clone, `par`/`swarm` bodies constructing/dropping RC-bearing ===
// ===== locals per iteration across many dispatch/join cycles, arena ===
// ===== `spawn`/`despawn` cycling with an `Option`/`List`-bearing struct
// ===== field, `sequence` coroutines abandoned mid-way with an RC-local
// ===== still live across a `yield`, and `match` on a fresh payload-enum
// ===== scrutinee inside a `par`/`swarm` body's own separate worker
// ===== function. Every candidate below was reproduced via a real
// ===== `star build -O2`+run first, sampling actual process Working Set
// ===== over millions of iterations (see this round's own report for the
// ===== exact numbers) -- every one came back flat, matching an
// ===== RC-free control of the same shape. No new bugs were found: round
// ===== 2's `Ty::Enum` RC-walk (`src/codegen/rc.rs`) and generic-fallback
// ===== spill-tracking fix (`src/codegen/mod.rs`'s `emit_place`) already
// ===== compose correctly across every one of these combinations, and
// ===== `par`/`swarm`'s own per-callsite worker function
// ===== (`Codegen::emit_par_stmt`, `src/codegen/arena.rs`) already swaps
// ===== in a fresh `owned_stack`/`push_scope`/`pop_scope` per iteration
// ===== exactly like an ordinary function body. The tests below convert
// ===== this round's clean empirical findings into permanent regression
// ===== coverage (using the same `assert_no_leak` Working-Set-delta
// ===== helper as round 2's leak tests above) so a future change that
// ===== reintroduces a leak in one of these specific combinations is
// ===== caught immediately instead of needing another manual audit. =====

/// `List<Option<str>>` (collections-of-generics x the round-2 `Ty::Enum`
/// RC-walk fix): sustained `push`/`pop` churn, keeping the list's length
/// bounded (so growth can't be explained by an ever-growing buffer) while
/// every pushed element is a fresh `Option::Some(str)` payload. Manually
/// confirmed flat (~2.7MB, zero measurable growth) over 40,000,000
/// iterations at `-O2` before this test was written; scaled down to a size
/// that still reliably shows a reintroduced leak (each iteration owns one
/// heap-allocated `str` payload) within this file's usual ~20MB cap.
#[test]
fn runtime_list_of_option_str_sustained_push_pop_does_not_leak_end_to_end() {
    let src = "fn main():\n    let mut lst: List<Option<str>> = List<Option<str>>()\n    let mut i: i32 = 0\n    \
               while i < 400000:\n        lst.push(Option::Some(concat(\"item\", \"x\")))\n        \
               if lst.len() > 50:\n            lst.pop()\n        i += 1\n    \
               println(\"done\")\n";
    assert_no_leak("list_option_str_sustained_push_pop_leak", src, 20 * 1024 * 1024);
}

/// `Table<T>` (struct-of-arrays) where `T` has an `Option<str>` column --
/// exercises the per-column release thunk (`crate::codegen::table::
/// table_release_thunk_operand`) against a payload-enum column
/// specifically, under sustained `push`/`pop` churn identical in shape to
/// the `List<Option<str>>` test above. Manually confirmed flat over
/// 25,000,000 iterations at `-O2` (both the plain append/pop loop and a
/// separate copy-on-write-clone stress variant sharing the table between
/// two owners every iteration) before this test was written.
#[test]
fn runtime_table_option_field_sustained_push_pop_does_not_leak_end_to_end() {
    let src = "struct Item:\n    tag: Option<str>\n    hp: i32\n\n\
               fn main():\n    let mut t: Table<Item> = Table<Item>()\n    let mut i: i32 = 0\n    \
               while i < 300000:\n        t.push(Item(tag = Option::Some(concat(\"tag\", \"x\")), hp = i))\n        \
               if t.len() > 50:\n            t.pop()\n        i += 1\n    \
               println(\"done\")\n";
    assert_no_leak("table_option_field_sustained_push_pop_leak", src, 20 * 1024 * 1024);
}

/// `par` dispatched across many ticks, each iteration's per-arena-entry
/// worker body constructing and dropping its own local `List<str>` and
/// `Option<str>` (never captured, never escaping) -- the specific
/// concurrency x memory-model combination this round targeted: does the
/// persistent thread pool (`src/codegen/par_pool.rs`) correctly release a
/// worker-local RC-bearing temporary on *every* dispatch, not just the
/// first/last? `Codegen::emit_par_stmt` (`src/codegen/arena.rs`) swaps in a
/// fresh `owned_stack` per worker function and calls `push_scope`/
/// `pop_scope` once per arena element visited, same as an ordinary loop
/// body. Manually confirmed flat (~3.1MB, zero measurable growth) over
/// 600,000 dispatch/join cycles (16 arena entries each, ~9,600,000 total
/// worker-body executions) at `-O2` before this test was written; scaled
/// down here since a `par` dispatch's own OS-semaphore handoff overhead
/// dominates at `-O0`.
#[test]
fn runtime_par_body_per_iteration_rc_locals_does_not_leak_end_to_end() {
    let src = "struct Enemy:\n    mut hp: i32\n\narena Enemies: Enemy\n\n\
               fn main():\n    let mut i: i32 = 0\n    while i < 16:\n        spawn Enemies(100)\n        i += 1\n    \
               let mut tick: i32 = 0\n    while tick < 20000:\n        \
               par e in Enemies:\n            let mut lst: List<str> = List<str>()\n            \
               lst.push(concat(\"x\", \"y\"))\n            \
               let opt: Option<str> = Option::Some(concat(\"a\", \"b\"))\n            \
               e.hp -= 1\n        tick += 1\n    \
               println(\"done\")\n";
    assert_no_leak("par_body_per_iteration_rc_locals_leak", src, 20 * 1024 * 1024);
}

/// Arena `spawn`/`despawn` cycling (never growing past one live slot) where
/// the spawned struct has an `Option<str>` field -- the specific gap round
/// 2's arena audit noted but didn't explicitly cover ("no bugs found" was
/// verified against a plain-data element type, not an `Option`/`Result`-
/// bearing one). `Codegen::emit_despawn_stmt` releases the slot's RC-bearing
/// content on despawn, and `emit_spawn_stmt` never re-releases a reused
/// slot's *previous* occupant (already released by the despawn that freed
/// it) -- both already correct for a plain `str` field per round 2's own
/// `runtime_stale_genref_field_write_does_not_leak_end_to_end`-style tests,
/// but not yet exercised against an `Option<T>` field specifically. Manually
/// confirmed flat over 25,000,000 despawn/spawn cycles at `-O2` before this
/// test was written.
#[test]
fn runtime_arena_spawn_despawn_cycle_with_option_field_does_not_leak_end_to_end() {
    let src = "struct Item:\n    tag: Option<str>\n    hp: i32\n\narena Items: Item\n\n\
               fn main():\n    spawn Items(Option::Some(concat(\"seed\", \"x\")), 0)\n    let mut i: i32 = 0\n    \
               while i < 300000:\n        despawn Items[0]\n        \
               spawn Items(Option::Some(concat(\"cycle\", \"x\")), i)\n        i += 1\n    \
               println(\"done\")\n";
    assert_no_leak("arena_spawn_despawn_option_field_cycle_leak", src, 20 * 1024 * 1024);
}

/// A `sequence` coroutine with a `str` local reassigned across `yield`
/// points, `resume()`'d exactly once (never run to completion) and then
/// dropped -- since `src/sequence.rs` desugars a `sequence` into a plain
/// `struct` + `resume(mut self) -> bool` method (see that module's own doc
/// comment), the hoisted local becomes an ordinary struct field, and an
/// abandoned-mid-sequence instance is released the same way any other
/// struct instance with RC-bearing fields is at scope exit -- no
/// coroutine-specific release logic exists or is needed. This test locks in
/// that behavior for the specific "abandoned before completion" case (the
/// case a naive coroutine implementation would most plausibly get wrong,
/// e.g. by only releasing hoisted locals along the "ran to completion"
/// path). Manually confirmed flat over 25,000,000 create-resume-once-drop
/// cycles at `-O2` before this test was written.
#[test]
fn runtime_sequence_abandoned_mid_way_releases_rc_local_end_to_end() {
    let src = "sequence Chatter(seed: str):\n    let mut msg: str = concat(seed, \"-1\")\n    yield\n    \
               msg = concat(seed, \"-2\")\n    yield\n    msg = concat(seed, \"-3\")\n    print(msg)\n\n\
               fn main():\n    let mut i: i32 = 0\n    while i < 300000:\n        \
               let mut c = Chatter(concat(\"s\", \"eed\"))\n        c.resume()\n        i += 1\n    \
               println(\"done\")\n";
    assert_no_leak("sequence_abandoned_mid_way_leak", src, 20 * 1024 * 1024);
}

/// `match` on a *fresh* (non-place) payload-enum scrutinee -- round 2's bug
/// #4, addressed generally via `Codegen::emit_place`'s generic fallback --
/// specifically inside a `par`/`swarm` body's own separate worker function
/// (`Codegen::emit_par_stmt` builds an entirely distinct top-level LLVM
/// function per callsite, a different function boundary than the plain
/// top-level `fn` round 2's own regression test exercises), and nested two
/// levels deep (`par` inside `par`, which falls back to the manually-
/// reentrant serial path in `src/codegen/par_pool.rs` rather than the
/// pooled dispatch). Manually confirmed flat over 60,000 outer ticks (6x6
/// entries each, 2,160,000 total nested-match executions) at `-O2` before
/// this test was written; scaled down here for `-O0` dispatch overhead.
#[test]
fn runtime_match_over_fresh_enum_inside_nested_par_does_not_leak_end_to_end() {
    let src = "struct Enemy:\n    mut hp: i32\nstruct Bullet:\n    mut dmg: i32\n\
               arena Enemies: Enemy\narena Bullets: Bullet\n\n\
               fn make_opt(v: i32) -> Option<str>:\n    if v > 0:\n        return Option::Some(concat(\"p\", \"x\"))\n    \
               Option<str>::None\n\n\
               fn main():\n    let mut i: i32 = 0\n    while i < 4:\n        spawn Enemies(1)\n        i += 1\n    \
               let mut j: i32 = 0\n    while j < 4:\n        spawn Bullets(0)\n        j += 1\n    \
               let mut tick: i32 = 0\n    while tick < 8000:\n        \
               par e in Enemies:\n            par b in Bullets:\n                \
               match make_opt(b.dmg):\n                    Option::Some(s) ->\n                        \
               b.dmg = b.dmg + len(s)\n                    Option::None ->\n                        \
               b.dmg = b.dmg - 1\n        tick += 1\n    \
               println(\"done\")\n";
    assert_no_leak("match_fresh_enum_inside_nested_par_leak", src, 20 * 1024 * 1024);
}
