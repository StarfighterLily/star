//! M7: `par`/`swarm` parallel dispatch and thread pool
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// --- `par` / `swarm` (parallel arena iteration) ---------------------------

/// Parse a `par item in Arena:` loop.
#[test]
fn parses_par_stmt() {
    let src = "fn t():\n    par e in Enemies:\n        e.hp -= 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Par { var, arena, .. } = &f.body.stmts[0] else { panic!("expected Par") };
    assert_eq!(var, "e");
    assert_eq!(arena, "Enemies");
}

/// `swarm` is accepted as a spelling of the same statement as `par`.
#[test]
fn parses_swarm_stmt_as_par() {
    let src = "fn t():\n    swarm e in Enemies:\n        e.hp -= 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert!(matches!(f.body.stmts[0], Stmt::Par { .. }));
}

/// A `par` body that only mutates the loop variable's own field type-checks.
#[test]
fn accepts_par_mutating_loop_var() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "mutating the loop variable's own field should be allowed");
}

/// A `par` body that declares and mutates its own local is fine (it's
/// per-iteration state, not shared across threads).
#[test]
fn accepts_par_mutating_body_local() {
    let src = format!(
        "{}fn t():\n    par e in Enemies:\n        let mut tmp: i32 = e.hp\n        tmp -= 1\n        e.hp = tmp\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "mutating a body-local should be allowed");
}

/// A `par` body that mutates a captured outer variable is rejected: that
/// write can't be proven disjoint across worker threads.
#[test]
fn rejects_par_mutating_captured_var() {
    let src = format!(
        "{}fn t():\n    let mut total: i32 = 0\n    par e in Enemies:\n        total += e.hp\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "mutating a captured outer variable should be a type error");
}

/// A `par` body that calls a method on something other than the loop
/// variable is rejected (the call might mutate shared state internally).
#[test]
fn rejects_par_method_call_on_captured_receiver() {
    let src = format!(
        "{}impl Enemy:\n    fn reset(mut self):\n        self.hp = 0\n\nfn t():\n    let mut other = Enemy(1)\n    par e in Enemies:\n        other.reset()\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "calling a method on a captured receiver should be a type error");
}

/// `par` over an undefined arena is a type error.
#[test]
fn rejects_par_undefined_arena() {
    let module = Driver::parse("fn t():\n    par e in Nope:\n        e.hp -= 1\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "par over an undefined arena should be a type error");
}

/// Codegen for `par` dispatches to the persistent worker-thread pool: the
/// pool's static machinery (`par.pool.worker_main`/`par.pool.ensure_init`,
/// created via `CreateThread`/`CreateSemaphoreA`) is emitted alongside this
/// callsite's own `par_worker_` chunking function, and the dispatcher joins
/// via `WaitForSingleObject` on the pool's per-worker "done" semaphores
/// before continuing -- no `CloseHandle` anywhere, since pool threads are
/// persistent, not per-call.
#[test]
fn codegen_par_dispatches_threads() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("declare i8* @CreateThread"), "{}", ir);
    assert!(ir.contains("call i8* @CreateThread("), "{}", ir);
    assert!(ir.contains("call i32 @WaitForSingleObject("), "{}", ir);
    assert!(ir.contains("define i32 @par_worker_"), "a worker function should be emitted: {}", ir);
    assert!(ir.contains("define i32 @par.pool.worker_main"), "the pool's generic worker entry point should be emitted: {}", ir);
    assert!(ir.contains("define void @par.pool.ensure_init"), "the pool's lazy-init function should be emitted: {}", ir);
    assert!(ir.contains("call i32 @GetCurrentThreadId"), "{}", ir);
    assert!(ir.contains("call i8* @CreateSemaphoreA"), "{}", ir);
    assert!(ir.contains("call i32 @ReleaseSemaphore"), "{}", ir);
    // `ensure_init` creates however many persistent worker threads the
    // runtime-detected/overridden count calls for via a *runtime* loop
    // (`par_pool_thread_cond`/`par_pool_thread_body`), so the actual thread
    // count never appears as a repeated static IR pattern -- there is
    // exactly one `CreateThread` call site in the text, executed however
    // many times `@par.pool.num_workers` says at run time, not one
    // textually-unrolled call site per worker the way a compile-time-fixed
    // pool size would produce.
    assert_eq!(ir.matches("call i8* @CreateThread(").count(), 1, "{}", ir);
    assert!(ir.contains("@par.pool.num_workers"), "{}", ir);
}

/// A program with **two** separate `par`/`swarm` statements still only
/// creates the pool's worker threads once -- the second statement's
/// `ensure_init` call sees the pool already initialized and skips straight
/// to dispatch, proving the pool is genuinely reused rather than recreated
/// per statement.
#[test]
fn codegen_par_pool_reused_across_multiple_statements() {
    let src = format!(
        "{}fn t():\n    par e in Enemies:\n        e.hp -= 1\n    swarm e in Enemies:\n        e.hp = 0\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    // Still just the one `CreateThread` call site (inside `ensure_init`'s
    // runtime thread-creation loop -- see `codegen_par_dispatches_threads`),
    // not one per `par`/`swarm` statement.
    assert_eq!(ir.matches("call i8* @CreateThread(").count(), 1, "pool threads should be created once, not once per statement: {}", ir);
    assert_eq!(ir.matches("define i32 @par.pool.worker_main").count(), 1, "{}", ir);
    assert_eq!(ir.matches("define void @par.pool.ensure_init").count(), 1, "{}", ir);
    assert_eq!(ir.matches("define i32 @par_worker_").count(), 2, "each callsite still gets its own chunking function: {}", ir);
}

/// A `par`/`swarm` statement nested inside another `par`/`swarm` body
/// dispatches through the manually-reentrant serial lock (rather than
/// trying to re-enter the fixed 4-worker pool from a thread that's already
/// one of its own workers) -- see `par_pool`'s module doc comment for why a
/// bare inline fallback would race.
#[test]
fn codegen_par_reentrant_dispatch_uses_serial_lock() {
    let src = format!(
        "{}fn t():\n    par e in Enemies:\n        par e2 in Enemies:\n            e2.hp -= 1\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("@par.pool.serial_lock"), "{}", ir);
    assert!(ir.contains("@par.pool.serial_owner"), "{}", ir);
}

/// A program that never uses `par`/`swarm` never pays for the pool's
/// machinery -- it stays fully lazy, gated behind
/// `Codegen::ensure_par_pool_emitted`.
#[test]
fn codegen_par_pool_globals_absent_without_par() {
    let src = "fn t() -> i32:\n    1 + 1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(!ir.contains("@par.pool."), "no par/swarm pool globals should be emitted for a program that never uses par/swarm: {}", ir);
}

/// Runtime test: the compiled `swarm.exe` spawns and joins real worker
/// threads (both `par` and `swarm` spellings) without crashing, end to end
/// through a real clang-compiled executable.
#[test]
fn runtime_swarm_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/swarm.exe").output().expect("failed to execute swarm.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("swarm done"), "worker threads should run to completion: {}", stdout);
}

/// Runtime test: the persistent worker-thread pool correctly serves 5
/// sequential `par` dispatch/join cycles in a row, not just a single one --
/// the actual "is it really persistent" regression check (a correct
/// single-shot `par` would also pass under the old per-call-`CreateThread`
/// design). See `examples/par_pool_ticks.star`.
#[test]
fn runtime_par_pool_ticks_persists_across_cycles() {
    use std::process::Command;

    let output = Command::new("examples/par_pool_ticks.exe").output().expect("failed to execute par_pool_ticks.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(
        stdout.matches("hp: 95").count(),
        3,
        "all 3 enemies should show hp 95 (100 - 5 ticks) after 5 sequential par/swarm cycles: {}",
        stdout
    );
}

/// Runtime test: a `par`/`swarm` statement nested inside another one is
/// race-free under real concurrent execution -- every `Bullet` ends up
/// incremented exactly once per live `Enemy`, deterministically, every run.
/// Without the manually-reentrant serial lock this would be flaky (lost
/// updates from multiple outer workers concurrently running overlapping
/// passes over the same nested arena). See `examples/par_nested.star`.
#[test]
fn runtime_par_nested_serial_fallback_is_race_free() {
    use std::process::Command;

    let output = Command::new("examples/par_nested.exe").output().expect("failed to execute par_nested.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(
        stdout.matches("dmg: 3").count(),
        4,
        "all 4 bullets should show dmg 3 (one increment per live enemy, no lost updates): {}",
        stdout
    );
}

// --- `par`/`swarm` worker pool sizing (hardware core count + `STAR_WORKERS`) --

/// The pool's mailbox arrays are declared at `par_pool::MAX_WORKERS` (a
/// generous compile-time ceiling), not a small hardcoded worker count -- the
/// live count is a separate runtime global (`@par.pool.num_workers`)
/// computed by `ensure_init`, not baked into the array size itself.
#[test]
fn codegen_par_pool_mailbox_arrays_sized_to_max_workers_ceiling() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(
        ir.contains("@par.pool.job_fn = global [64 x i32 (i8*)*] zeroinitializer"),
        "mailbox arrays should be sized to the MAX_WORKERS ceiling, not a small fixed count: {}",
        ir
    );
    assert!(ir.contains("@par.pool.num_workers = global i32 0"), "{}", ir);
}

/// `ensure_init` determines the live worker count at runtime rather than
/// baking in a fixed number: it reads `STAR_WORKERS` via the same `getenv`
/// the `env_get` builtin uses, falls back to `GetSystemInfo`'s
/// `dwNumberOfProcessors` when unset, and parses an override with `atoi`.
#[test]
fn codegen_par_pool_init_detects_hardware_and_env_override() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let init_body = extract_fn_body(&ir, "define void @par.pool.ensure_init(");
    assert!(init_body.contains("call i8* @getenv("), "should check for a STAR_WORKERS override: {}", init_body);
    assert!(init_body.contains("call void @GetSystemInfo("), "should query the real hardware core count: {}", init_body);
    assert!(init_body.contains("call i32 @atoi("), "an override value should be parsed with atoi: {}", init_body);
    assert!(ir.contains("STAR_WORKERS"), "{}", ir);
}

/// However many workers `ensure_init` decides on, thread creation happens in
/// a genuine runtime loop (`par_pool_thread_cond`/`par_pool_thread_body`),
/// not a Rust-compile-time-unrolled sequence of `CreateThread` calls -- so
/// there is exactly one `CreateThread`/`CreateSemaphoreA`-pair call site in
/// the emitted text no matter how many threads it ends up creating at run
/// time.
#[test]
fn codegen_par_pool_thread_creation_is_a_runtime_loop_not_unrolled() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("par_pool_thread_cond:"), "{}", ir);
    assert!(ir.contains("par_pool_thread_body:"), "{}", ir);
    assert!(ir.contains("@par.pool.init_i"), "{}", ir);
    assert_eq!(ir.matches("call i8* @CreateThread(").count(), 1, "{}", ir);
    // Two `CreateSemaphoreA` call sites inside the loop body (start + done
    // per worker) plus one more, outside the loop, for the nested-`par`
    // serial-fallback lock -- three total, regardless of worker count.
    assert_eq!(ir.matches("call i8* @CreateSemaphoreA(").count(), 3, "{}", ir);
}

/// `emit_par_dispatch`'s fan-out (mailbox population) and join
/// (`WaitForSingleObject` on every done-semaphore) loops are also genuine
/// runtime loops over `@par.pool.num_workers`, each with exactly one static
/// call site -- mirroring `ensure_init`'s own thread-creation loop.
#[test]
fn codegen_par_dispatch_fanout_and_join_are_runtime_loops() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("par_fanout_cond"), "{}", ir);
    assert!(ir.contains("par_fanout_body"), "{}", ir);
    assert!(ir.contains("par_join_wait_cond"), "{}", ir);
    assert!(ir.contains("par_join_wait_body"), "{}", ir);
    // One `ReleaseSemaphore` in the fan-out loop body (releasing a worker's
    // start semaphore) + one in `par.pool.worker_main`'s own per-job loop
    // (signaling done, unconditional, textually once regardless of
    // workload) + one in the nested-`par` serial fallback's `release` block
    // (releasing the recursive lock) = 3.
    assert_eq!(ir.matches("call i32 @ReleaseSemaphore(").count(), 3, "{}", ir);
    // One `WaitForSingleObject` in the join loop body + one in
    // `par.pool.worker_main`'s own per-job loop + one in the serial
    // fallback's `acquire` block (taking the recursive lock) = 3.
    assert_eq!(ir.matches("call i32 @WaitForSingleObject(").count(), 3, "{}", ir);
}

/// End-to-end: a `par`/`swarm` dispatch over an arena whose live-element
/// count doesn't divide evenly by the worker count still visits every
/// element exactly once, across a range of explicit `STAR_WORKERS`
/// overrides -- including below the pool's own floor (clamped up to 4),
/// exactly at typical hardware counts, and above the `MAX_WORKERS` ceiling
/// (clamped down to 64). A single lost or double-counted chunk boundary in
/// the runtime chunk-math loop (`emit_par_dispatch`'s fan-out loop) would
/// show up here as a wrong total.
#[test]
fn runtime_par_dispatch_correct_across_star_workers_overrides_end_to_end() {
    let src = "struct Enemy:\n    mut hp: i32\n\narena Enemies: Enemy\n\nfn main():\n    let mut n: i32 = 0\n    while n < 37:\n        spawn Enemies(1)\n        n += 1\n    par e in Enemies:\n        e.hp -= 1\n    let mut total: i32 = 0\n    each e in Enemies:\n        total += e.hp\n    println(f\"{total}\")\n";
    for workers in ["1", "2", "3", "4", "5", "8", "37", "64", "100"] {
        let output = compile_and_run_with("par_dispatch_workers_override", src, &[], &[("STAR_WORKERS", workers)]);
        assert!(output.status.success(), "STAR_WORKERS={}: {:?}", workers, output.status);
        let stdout = String::from_utf8_lossy(&output.stdout);
        assert_eq!(
            stdout.trim_end(),
            "0",
            "STAR_WORKERS={}: all 37 enemies should be decremented exactly once (hp 1 -> 0): {}",
            workers,
            stdout
        );
    }
}

/// `STAR_WORKERS=0` (or any non-numeric/garbage value `atoi` parses as `<=
/// 0`) does not shrink the pool below its `MIN_WORKERS` floor or otherwise
/// break dispatch -- the clamp in `ensure_init` applies to an explicit
/// override exactly as it does to a detected hardware count.
#[test]
fn runtime_par_dispatch_star_workers_zero_clamps_to_floor_end_to_end() {
    let src = "struct Enemy:\n    mut hp: i32\n\narena Enemies: Enemy\n\nfn main():\n    let mut n: i32 = 0\n    while n < 10:\n        spawn Enemies(2)\n        n += 1\n    par e in Enemies:\n        e.hp -= 1\n    let mut total: i32 = 0\n    each e in Enemies:\n        total += e.hp\n    println(f\"{total}\")\n";
    let output = compile_and_run_with("par_dispatch_workers_zero", src, &[], &[("STAR_WORKERS", "0")]);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "10", "10 enemies at hp 2 each, decremented once, should total 10: {}", stdout);
}

/// A `parallel:` block listing exactly `MAX_PARALLEL_SYSTEMS` (4) systems
/// still dispatches all of them correctly even when `STAR_WORKERS` requests
/// fewer live workers than that -- the compile-time "at most 4 systems"
/// guarantee (`system_analysis::MAX_PARALLEL_SYSTEMS`) only holds if the
/// pool's runtime floor (`par_pool::MIN_WORKERS`) never actually drops that
/// low, regardless of what an explicit override asks for.
#[test]
fn runtime_parallel_four_systems_still_dispatch_with_star_workers_below_floor_end_to_end() {
    let mut src = String::new();
    for c in ['A', 'B', 'C', 'D'] {
        src.push_str(&format!(
            "struct E{c}:\n    mut hp: i32\n\narena Ar{c}: E{c}\n\nsystem S{c}(mut Ar{c}):\n    par e in Ar{c}:\n        e.hp -= 1\n\n"
        ));
    }
    src.push_str("fn main():\n");
    for c in ['A', 'B', 'C', 'D'] {
        src.push_str(&format!("    spawn Ar{c}(1)\n"));
    }
    src.push_str("    parallel:\n");
    for c in ['A', 'B', 'C', 'D'] {
        src.push_str(&format!("        S{c}()\n"));
    }
    for c in ['A', 'B', 'C', 'D'] {
        src.push_str(&format!("    each e in Ar{c}:\n        println(f\"{{e.hp}}\")\n"));
    }
    let output = compile_and_run_with("parallel_four_systems_workers_1", &src, &[], &[("STAR_WORKERS", "1")]);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.matches("0").count(), 4, "all 4 systems should have run (hp 1 -> 0): {}", stdout);
}

// --- cross-platform codegen (`crate::codegen::platform::Target`) --------

/// `Target::LinuxGnu` emits the same worker-pool IR *shape* as the default
/// `Target::WindowsGnu` (same block structure, same runtime loops -- see
/// `codegen_par_pool_thread_creation_is_a_runtime_loop_not_unrolled`/
/// `codegen_par_dispatch_fanout_and_join_are_runtime_loops`), just routed
/// through POSIX pthreads/`sem_t`/`sysconf` (`crate::codegen::platform`)
/// instead of Win32 primitives, and declares/calls none of the Win32
/// threading symbols at all.
#[test]
fn codegen_linux_target_uses_pthread_and_sem_not_win32() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let v =
        Driver::codegen_verified_for_target(&typed, star::codegen::Target::LinuxGnu).expect("should codegen");
    let ir = v.ir;

    assert!(ir.contains("target triple = \"x86_64-unknown-linux-gnu\""), "{}", ir);

    assert!(ir.contains("declare i32 @pthread_create("), "{}", ir);
    assert!(ir.contains("declare i64 @pthread_self()"), "{}", ir);
    assert!(ir.contains("declare i32 @sem_init("), "{}", ir);
    assert!(ir.contains("declare i32 @sem_wait("), "{}", ir);
    assert!(ir.contains("declare i32 @sem_post("), "{}", ir);
    assert!(ir.contains("declare i64 @sysconf("), "{}", ir);
    assert!(ir.contains("call i32 @pthread_create("), "{}", ir);
    assert!(ir.contains("call i64 @sysconf(i32 84)"), "should query _SC_NPROCESSORS_ONLN: {}", ir);
    assert!(ir.contains("call i64 @pthread_self()"), "{}", ir);

    for win32_sym in
        ["CreateThread", "WaitForSingleObject", "CreateSemaphoreA", "ReleaseSemaphore", "GetCurrentThreadId", "GetSystemInfo"]
    {
        assert!(!ir.contains(win32_sym), "Target::LinuxGnu IR should never mention `{}`: {}", win32_sym, ir);
    }
}

/// Exact call-site counts under `Target::LinuxGnu` mirror
/// `codegen_par_pool_thread_creation_is_a_runtime_loop_not_unrolled`'s
/// Windows-target counts one-for-one: one `pthread_create` (the
/// thread-creation loop still runs at runtime, not unrolled) and three
/// `sem_init` (two per-worker semaphores created inside that loop, plus one
/// more, outside it, for the nested-`par` serial-fallback lock).
#[test]
fn codegen_linux_target_thread_creation_is_a_runtime_loop_not_unrolled() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let v =
        Driver::codegen_verified_for_target(&typed, star::codegen::Target::LinuxGnu).expect("should codegen");
    let ir = v.ir;
    assert!(ir.contains("par_pool_thread_cond:"), "{}", ir);
    assert!(ir.contains("par_pool_thread_body:"), "{}", ir);
    assert_eq!(ir.matches("call i32 @pthread_create(").count(), 1, "{}", ir);
    assert_eq!(ir.matches("call i32 @sem_init(").count(), 3, "{}", ir);
}

/// Fan-out/join call counts under `Target::LinuxGnu` mirror
/// `codegen_par_dispatch_fanout_and_join_are_runtime_loops`'s Windows-target
/// counts one-for-one: 3 `sem_post` (the fan-out loop's release + `par.pool.
/// worker_main`'s own per-job done-signal + the serial-fallback lock's own
/// release) and 3 `sem_wait` (the join loop's wait + `worker_main`'s own
/// per-job start-wait + the serial-fallback lock's own acquire).
#[test]
fn codegen_linux_target_dispatch_fanout_and_join_call_counts_match_windows_shape() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let v =
        Driver::codegen_verified_for_target(&typed, star::codegen::Target::LinuxGnu).expect("should codegen");
    let ir = v.ir;
    assert_eq!(ir.matches("call i32 @sem_post(").count(), 3, "{}", ir);
    assert_eq!(ir.matches("call i32 @sem_wait(").count(), 3, "{}", ir);
}

/// `crate::ir_check`'s structural verifier (target-agnostic -- it never
/// inspects the `target triple` line) accepts `Target::LinuxGnu`'s IR just
/// as cleanly as the default target's: nothing about the pthread/`sem_t`
/// call shapes this compiler emits trips a false positive.
#[test]
fn codegen_linux_target_ir_passes_internal_verifier() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let v =
        Driver::codegen_verified_for_target(&typed, star::codegen::Target::LinuxGnu).expect("should codegen");
    assert!(
        v.errors.is_empty(),
        "Target::LinuxGnu IR should pass the internal verifier: {:?}",
        v.errors.iter().map(|d| &d.message).collect::<Vec<_>>()
    );
}

/// `Symbol(..)`/`symbol_name(..)`/`rand()`'s shared locks (`@sym.lock`/
/// `@rng.lock` -- see `Codegen::emit_sym_lock_init`/`emit_rng_lock_init` and
/// `crate::codegen::vector_math::emit_rand_next`) route through the same
/// platform seam as `par_pool.rs`, not a hand-rolled `CreateSemaphoreA` call
/// of their own: under `Target::LinuxGnu` they also become `sem_init`/
/// `sem_wait`/`sem_post`.
#[test]
fn codegen_linux_target_sym_and_rng_locks_use_sem_not_win32() {
    let src = "fn main():\n    let a = Symbol(\"hello\")\n    println(symbol_name(a))\n    println(f\"{rand()}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let v =
        Driver::codegen_verified_for_target(&typed, star::codegen::Target::LinuxGnu).expect("should codegen");
    let ir = v.ir;
    assert!(ir.contains("call i32 @sem_init("), "{}", ir);
    assert!(ir.contains("call i32 @sem_wait("), "{}", ir);
    assert!(ir.contains("call i32 @sem_post("), "{}", ir);
    assert!(!ir.contains("CreateSemaphoreA"), "{}", ir);
    assert!(!ir.contains("WaitForSingleObject"), "{}", ir);
    assert!(!ir.contains("ReleaseSemaphore"), "{}", ir);
}

/// The default target (no `--target` involved -- plain `Driver::codegen`,
/// exactly what every pre-existing par-pool test above already calls) is
/// untouched by the `Target::LinuxGnu` backend's existence: still Win32
/// primitives, still the `x86_64-w64-windows-gnu` triple, and -- regression
/// guard for the seam refactor itself -- the pool's tid-tracking array is
/// now `i64`-wide (widened so a Windows `i32` thread id and a Linux
/// `pthread_t` can share one array shape, see `crate::codegen::platform::
/// emit_current_thread_id64`), not the original `i32`.
#[test]
fn codegen_windows_target_default_unchanged_by_platform_seam() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("target triple = \"x86_64-w64-windows-gnu\""), "{}", ir);
    assert!(ir.contains("call i8* @CreateThread("), "{}", ir);
    assert!(ir.contains("@par.pool.tid = global [64 x i64] zeroinitializer"), "{}", ir);
    for posix_sym in ["pthread_create", "pthread_self", "sem_init", "sem_wait", "sem_post", "sysconf"] {
        assert!(!ir.contains(posix_sym), "Target::WindowsGnu IR should never mention `{}`: {}", posix_sym, ir);
    }
}
