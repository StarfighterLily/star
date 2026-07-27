//! `each item in ArenaName:` sequential arena iteration
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== `each item in ArenaName:` -- ordinary sequential (single-threaded)
// ===== arena iteration, added to close `projects/snake/NOTES.md` section
// ===== 1.6: `par`/`swarm` correctly ban any call that touches SDL's shared
// ===== window/renderer state or its global input-event queue (real crashes
// ===== otherwise), but before `each` existed there was no *other* way to
// ===== iterate an arena's contents at all -- so an arena could never be
// ===== drawn to the screen, directly contradicting the reference doc's own
// ===== flagship "Entity Component System" render-system example. `each`
// ===== runs its body once per live element inline on the calling thread, so
// ===== none of `par`/`swarm`'s disjointness restrictions apply. ============

const EACH_SRC_PREFIX: &str = "struct Enemy:\n    mut hp: i32\n\narena Enemies: Enemy\n\n";

/// `each item in ArenaName:` parses to a dedicated `Stmt::Each`, distinct
/// from `Stmt::Par` (unlike `swarm`, which is just an alternate spelling of
/// the same `Stmt::Par` node -- see `parses_swarm_stmt_as_par`).
#[test]
fn parses_each_stmt() {
    let src = "fn t():\n    each e in Enemies:\n        e.hp -= 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Each { var, arena, .. } = &f.body.stmts[0] else { panic!("expected Each") };
    assert_eq!(var, "e");
    assert_eq!(arena, "Enemies");
}

/// `each` over an undefined arena is a type error, mirroring
/// `rejects_par_undefined_arena`.
#[test]
fn rejects_each_undefined_arena() {
    let module = Driver::parse("fn t():\n    each e in Nope:\n        e.hp -= 1\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "each over an undefined arena should be a type error");
}

/// Unlike `par`/`swarm` (`rejects_par_mutating_captured_var`), `each` runs
/// on a single thread, so there's nothing to prove disjoint: mutating a
/// captured outer variable from inside the body must type-check cleanly.
#[test]
fn accepts_each_mutating_captured_outer_var() {
    let src = format!(
        "{}fn t():\n    let mut total: i32 = 0\n    each e in Enemies:\n        total += e.hp\n",
        EACH_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "each should allow mutating a captured outer variable, unlike par/swarm");
}

/// Unlike `par`/`swarm` (`rejects_sdl_render_calls_inside_par_body`), `each`
/// never dispatches across worker threads, so calling SDL's drawing
/// builtins from inside its body must type-check cleanly -- this is the
/// capability `projects/snake/NOTES.md` section 1.6 found missing.
#[test]
fn accepts_each_calling_sdl_draw_builtins() {
    let src = concat!(
        "struct Entity:\n    mut idx: i32\n\n",
        "arena Entities: Entity\n\n",
        "fn main():\n",
        "    let w = window_create(\"race\", 64, 48)\n",
        "    each e in Entities:\n",
        "        clear_screen(w, Color32(1, 2, 3, 255))\n",
        "        draw_pixel(w, e.idx, e.idx, Color32(4, 5, 6, 255))\n",
        "        present(w)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    assert!(
        Driver::check(&module).is_ok(),
        "each should permit SDL drawing builtins, unlike par/swarm"
    );
}

/// `each` cannot be nested directly inside a `par`/`swarm` body: doing so
/// would run its whole sequential scan (and whatever SDL calls/captured-state
/// mutation its body performs, both safe only because `each` never
/// dispatches across threads on its own) concurrently on every worker.
#[test]
fn rejects_each_inside_par_body() {
    let src = format!(
        "{}fn t():\n    par e in Enemies:\n        each e2 in Enemies:\n            e.hp -= e2.hp\n",
        EACH_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("each nested inside a par/swarm body should be rejected") };
    assert!(
        diags.iter().any(|d| d.message.contains("`each` cannot be used inside a par/swarm body")),
        "{:?}",
        diags
    );
}

/// The nesting ban must also catch `each` reached *transitively*, through a
/// helper function called from inside a `par`/`swarm` body -- mirrors the
/// existing `spawn`/`despawn`/`frame:` transitive-hazard tests
/// (`compute_unsafe_par_fns`).
#[test]
fn rejects_par_call_to_fn_containing_each() {
    let src = format!(
        "{}fn scan_all():\n    each e in Enemies:\n        e.hp -= 1\n\nfn t():\n    par e in Enemies:\n        scan_all()\n",
        EACH_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let Err(diags) = Driver::check(&module) else {
        panic!("calling a helper fn that (transitively) contains `each` from inside a par/swarm body should be rejected")
    };
    assert!(
        diags.iter().any(|d| d.message.contains("cannot call `scan_all`") && d.message.contains("each")),
        "{:?}",
        diags
    );
}

/// Codegen for `each` never touches the `par`/`swarm` worker-thread pool
/// machinery at all (no `CreateThread`, no separate `par_worker_N`
/// function) -- it's a plain sequential loop inline in the caller, skipping
/// despawned slots via the same generation-parity check `par`/`swarm`'s
/// worker body uses (`codegen_par_worker_skips_despawned_slots`).
#[test]
fn codegen_each_runs_sequentially_with_no_worker_pool() {
    let src = format!("{}fn t():\n    each e in Enemies:\n        e.hp -= 1\n", EACH_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    // `declare i8* @CreateThread(...)` is an unconditional extern declaration
    // (like every other Win32 import) -- what would prove a dispatch is an
    // actual *call* site or the pool's own globals, mirroring
    // `codegen_par_pool_globals_absent_without_par`.
    assert!(!ir.contains("call i8* @CreateThread("), "each must not dispatch to the par/swarm worker pool: {}", ir);
    assert!(!ir.contains("@par.pool."), "each must not touch the par/swarm pool's own globals: {}", ir);
    assert!(!ir.contains("define i32 @par_worker_"), "each must not emit a separate worker function: {}", ir);
    assert!(ir.contains("each_cond"), "{}", ir);
    assert!(ir.contains("each_live"), "each should branch around despawned slots, mirroring par_live: {}", ir);
    assert!(ir.contains("@arena.Enemies.gen"), "each should check each slot's generation before visiting it: {}", ir);
}

/// Runtime test: `each` visits every live element exactly once, in slot
/// order, printing each one's field -- the basic sequential-scan behavior
/// the whole statement exists for.
#[test]
fn runtime_each_iterates_all_live_elements_in_order_end_to_end() {
    let src = format!(
        "{}fn main():\n    spawn Enemies(10)\n    spawn Enemies(20)\n    spawn Enemies(30)\n    each e in Enemies:\n        println(f\"hp: {{e.hp}}\")\n",
        EACH_SRC_PREFIX
    );
    let output = compile_and_run("each_iterates_all_live_elements", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["hp: 10", "hp: 20", "hp: 30"], "{}", stdout);
}

/// Runtime test: a despawned slot is skipped, not visited with stale/
/// released data -- mirrors `runtime_par_skips_despawned_slot_end_to_end`
/// but for the sequential `each` scan.
#[test]
fn runtime_each_skips_despawned_slot_end_to_end() {
    let src = format!(
        "{}fn main():\n    spawn Enemies(10)\n    spawn Enemies(20)\n    spawn Enemies(30)\n    despawn Enemies[1]\n    each e in Enemies:\n        println(f\"hp: {{e.hp}}\")\n",
        EACH_SRC_PREFIX
    );
    let output = compile_and_run("each_skips_despawned_slot", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["hp: 10", "hp: 30"], "the despawned middle slot must not be visited: {}", stdout);
}

/// Runtime test: `each` can freely mutate a captured outer variable --
/// summing every live element's field into a running total -- exactly the
/// pattern `rejects_par_mutating_captured_var` shows `par`/`swarm` must
/// reject.
#[test]
fn runtime_each_mutates_captured_outer_variable_end_to_end() {
    let src = format!(
        "{}fn main():\n    spawn Enemies(10)\n    spawn Enemies(20)\n    spawn Enemies(30)\n    let mut total: i32 = 0\n    each e in Enemies:\n        total += e.hp\n    println(f\"total: {{total}}\")\n",
        EACH_SRC_PREFIX
    );
    let output = compile_and_run("each_mutates_captured_outer_variable", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "total: 60", "{}", stdout);
}

/// Runtime test: `break`/`continue` work inside `each` exactly like any
/// other loop -- `continue` skips the 20-hp entity's print, `break` stops
/// the scan before the 30-hp entity is ever reached (and the 40-hp entity
/// is never visited at all).
#[test]
fn runtime_each_break_and_continue_end_to_end() {
    let src = format!(
        "{}fn main():\n    spawn Enemies(10)\n    spawn Enemies(20)\n    spawn Enemies(30)\n    spawn Enemies(40)\n    each e in Enemies:\n        if e.hp == 30:\n            break\n        if e.hp == 20:\n            continue\n        println(f\"hp: {{e.hp}}\")\n",
        EACH_SRC_PREFIX
    );
    let output = compile_and_run("each_break_and_continue", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "hp: 10", "{}", stdout);
}

/// Runtime test: `each` can actually call SDL drawing builtins end to end --
/// not just type-check (`accepts_each_calling_sdl_draw_builtins`) -- proving
/// the render-system pattern `docs/language_reference.md`'s ECS example now
/// shows (`each e in Entities: draw_rect(...)`) really runs, closing
/// `projects/snake/NOTES.md` section 1.6's "an arena's contents can never be
/// drawn to the screen directly" gap.
#[test]
fn runtime_each_calls_sdl_draw_builtin_end_to_end() {
    let src = "struct Entity:\n    mut x: i32\n    mut y: i32\n\narena Entities: Entity\n\nfn main():\n    \
               let w = window_create(\"each draw\", 64, 48)\n    \
               spawn Entities(1, 2)\n    \
               spawn Entities(3, 4)\n    \
               each e in Entities:\n        \
               draw_rect(w, e.x, e.y, 4, 4, Color32(9, 9, 9, 255))\n    \
               present(w)\n    \
               window_destroy(w)\n    \
               println(\"each draw ok\")\n";
    let output = compile_and_run_sdl("each_calls_sdl_draw_builtin", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "each draw ok", "{}", stdout);
}
