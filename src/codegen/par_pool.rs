//! The persistent `par`/`swarm` worker-thread pool: a set of OS threads
//! created once (lazily, on first dispatch) and reused for the process's
//! lifetime, replacing the old per-`par`-statement create/wait/close cycle.
//! See `Codegen::emit_par_stmt` (`arena.rs`) for the per-callsite worker
//! function this dispatches to.
//!
//! Every thread/semaphore/core-count primitive this module needs goes
//! through `crate::codegen::platform` rather than a raw Win32 (or POSIX)
//! call inline -- see that module's own doc comment for why, and for the
//! `Target::LinuxGnu` pthread/`sem_t`/`sysconf` implementations this
//! module's IR shape stays identical under either backend for.
//!
//! The pool's *live* size is computed once at runtime, in
//! `@par.pool.ensure_init`: the platform's own core-count query
//! (`platform::emit_detect_core_count`), an explicit `STAR_WORKERS`
//! environment-variable override if set, clamped into `[MIN_WORKERS,
//! MAX_WORKERS]` and stored in `@par.pool.num_workers`. `MAX_WORKERS` only
//! bounds how large the mailbox arrays below are declared (a
//! compile-time-fixed LLVM array size is unavoidable); every dispatch loop
//! below reads the real, runtime `@par.pool.num_workers` value rather than
//! either constant, so the actual thread count -- and thus how finely a
//! `par`/`swarm` chunk splits -- tracks the hardware it runs on instead of
//! always assuming a fixed number of cores.
//!
//! Each of the pool's `num_workers` threads has its own dedicated "mailbox"
//! (a slot in four parallel global arrays) rather than pulling from a
//! shared queue: every dispatch always fans out to exactly `num_workers`
//! chunks, one per worker, so a generic multi-producer/multi-consumer queue
//! would only add deadlock/lost-wakeup surface area for no behavioral
//! benefit. Handoff in both directions (dispatcher -> worker "go", worker ->
//! dispatcher "done") uses a counting semaphore (`platform::
//! emit_alloc_semaphore`/`emit_semaphore_wait`/`emit_semaphore_post`) rather
//! than a condition variable: a "post" that happens before the matching
//! "wait" is reached still leaves the semaphore's count at 1, so there is no
//! lost-wakeup window on either side of the handoff -- a condition variable
//! would need an auxiliary mutex-guarded predicate to get the same
//! guarantee.
//!
//! Nested `par`/`swarm` (a `par` body containing another `par` statement,
//! which the checker's disjointness proof allows -- see
//! `types::par_analysis::walk_par_stmt`'s `TypedStmt::Par` arm) can't
//! dispatch to this same pool: a worker that hits a nested `par` is itself
//! busy, so it runs the nested loop serially, inline, on its own thread
//! instead. That fallback is guarded by a manually reentrant lock
//! (`serial_lock` + `serial_owner`), not run bare: if it were run without a
//! lock, every outer worker concurrently reaches the same nested statement
//! (the outer `par` is genuinely running on multiple workers at once) and
//! each would independently run a full, overlapping pass over the same
//! nested arena -- a real data race. The lock is manually reentrant (a bare
//! semaphore is not) so that a thread already holding it for an outer
//! nested `par` doesn't self-deadlock when it reaches a *deeper* nested
//! `par` on the same thread.

use crate::types::*;

use super::Codegen;

/// Compile-time ceiling on the worker pool's size: the LLVM global arrays
/// backing the pool's mailboxes (and the per-dispatch argument-struct
/// storage in `emit_par_dispatch`) are declared with this many slots, since
/// an LLVM array type needs a size known at codegen time. The *live* worker
/// count is a runtime value (`@par.pool.num_workers`, computed in
/// `ensure_par_pool_emitted`'s `@par.pool.ensure_init`) that is always
/// `<= MAX_WORKERS` -- everything that actually dispatches work loops over
/// that runtime value, never this constant. 64 is generous headroom past
/// any real consumer desktop/workstation core count at time of writing.
pub(super) const MAX_WORKERS: u32 = 64;

/// Floor on the runtime worker count -- matches the old hardcoded pool size
/// this replaces. `system`/`parallel` (`system.rs`) reuses this same pool
/// for whole-system dispatch, and `types::system_analysis`'s
/// `MAX_PARALLEL_SYSTEMS` is a *compile-time* bound on how many systems one
/// `parallel:` block may list, checked before any hardware is known. That
/// compile-time guarantee only holds if the pool never has *fewer* live
/// workers than `MAX_PARALLEL_SYSTEMS` at runtime -- so this floor must
/// never drop below it (a contributor raising `MAX_PARALLEL_SYSTEMS` must
/// raise this to match), or a machine with fewer real cores than systems
/// listed in one `parallel:` block would deadlock waiting on a mailbox slot
/// no thread is listening on. An explicit `STAR_WORKERS` override is
/// clamped to this same floor for the same reason -- see `ensure_init`.
pub(super) const MIN_WORKERS: u32 = 4;

impl Codegen {
    /// Emit the pool's one-time static machinery (globals, the generic
    /// worker-thread entry point, and the lazy-init function) exactly once
    /// per program, the first time any `par`/`swarm` statement is
    /// codegen'd. A program that never uses `par`/`swarm` never calls this,
    /// so it never pays for any of this machinery.
    pub(super) fn ensure_par_pool_emitted(&mut self) {
        if self.par_pool_emitted {
            return;
        }
        self.par_pool_emitted = true;

        let saved_ir = std::mem::take(&mut self.ir);

        self.line(&format!("@par.pool.job_fn = global [{} x i32 (i8*)*] zeroinitializer", MAX_WORKERS));
        self.line(&format!("@par.pool.job_arg = global [{} x i8*] zeroinitializer", MAX_WORKERS));
        self.line(&format!("@par.pool.start_sem = global [{} x i8*] zeroinitializer", MAX_WORKERS));
        self.line(&format!("@par.pool.done_sem = global [{} x i8*] zeroinitializer", MAX_WORKERS));
        // `i64`, not a platform-native width, so a Windows `i32` thread id
        // (zero-extended) and a Linux `pthread_t` (already 64-bit) can share
        // one array shape -- see `crate::codegen::platform::
        // emit_current_thread_id64`.
        self.line(&format!("@par.pool.tid = global [{} x i64] zeroinitializer", MAX_WORKERS));
        self.line("@par.pool.inited = global i1 false");
        // The pool's live worker count, computed once by `ensure_init` --
        // see this module's doc comment.
        self.line("@par.pool.num_workers = global i32 0");
        // Scratch storage `ensure_init` alone ever touches, while the
        // process has at most one thread of control (see its own doc
        // comment on `@par.pool.inited`'s race-freedom) -- kept as plain
        // globals rather than `alloca`s because `ensure_init`'s IR is
        // concatenated with `worker_main`'s below before being handed to
        // `hoist_allocas_to_entry` as one blob, and that pass hoists every
        // `alloca` it finds to the *first* `entry:` label in the blob
        // (`worker_main`'s, not `ensure_init`'s own) -- an `alloca` here
        // would silently produce a register defined in the wrong function,
        // which the LLVM verifier rejects.
        self.line(&format!("@par.pool.sysinfo_buf = global [{} x i8] zeroinitializer", SYSTEM_INFO_SIZE));
        self.line("@par.pool.init_i = global i32 0");
        // `pthread_create`'s required `pthread_t*` out-param, on
        // `Target::LinuxGnu` only -- its value is written once per thread
        // created and never read back (this pool never joins a worker
        // thread), so one shared scratch slot reused across every iteration
        // of the thread-creation loop below is fine; unused, but harmless,
        // under `Target::WindowsGnu`. Must be a global rather than an
        // `alloca` for the same reason `sysinfo_buf`/`init_i` are -- see
        // this function's earlier comment on `hoist_allocas_to_entry`.
        self.line("@platform.pthread_out = global i64 0");
        self.line("@par.pool.env_name = private unnamed_addr constant [13 x i8] c\"STAR_WORKERS\\00\"");
        // Recursive-mutex pair backing the nested-`par` serial fallback --
        // see this module's header comment.
        self.line("@par.pool.serial_lock = global i8* null");
        self.line("@par.pool.serial_owner = global i32 -1");
        self.line("");

        // --- generic worker-thread entry point, run by every live worker ---
        // thread. `%idx_arg` is the worker's own index (0..num_workers),
        // smuggled through the `LPTHREAD_START_ROUTINE`-shaped `i8*` param
        // as if it were a pointer (see `ensure_init`'s `inttoptr`).
        self.line("define i32 @par.pool.worker_main(i8* %idx_arg) {");
        self.open_block("entry");
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = ptrtoint i8* %idx_arg to i64", idx64));
        let idx = self.tmp_name();
        self.line(&format!("  {} = trunc i64 {} to i32", idx, idx64));
        // Record this thread's own OS thread id before ever waiting on a
        // job, so `emit_par_dispatch`'s reentrancy check can always trust
        // that a job running on worker `idx` has already published its tid.
        let tid = self.emit_current_thread_id64();
        let tid_slot = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @par.pool.tid, i32 0, i32 {}",
            tid_slot, MAX_WORKERS, MAX_WORKERS, idx
        ));
        self.line(&format!("  store i64 {}, i64* {}", tid, tid_slot));
        self.line("  br label %loop");
        self.line("loop:");
        let start_slot = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @par.pool.start_sem, i32 0, i32 {}",
            start_slot, MAX_WORKERS, MAX_WORKERS, idx
        ));
        let start_h = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", start_h, start_slot));
        self.emit_semaphore_wait(&start_h);
        let fn_slot = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i32 (i8*)*], [{} x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 {}",
            fn_slot, MAX_WORKERS, MAX_WORKERS, idx
        ));
        let fn_reg = self.tmp_name();
        self.line(&format!("  {} = load i32 (i8*)*, i32 (i8*)** {}", fn_reg, fn_slot));
        let arg_slot = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @par.pool.job_arg, i32 0, i32 {}",
            arg_slot, MAX_WORKERS, MAX_WORKERS, idx
        ));
        let arg_reg = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", arg_reg, arg_slot));
        let call_res = self.tmp_name();
        self.line(&format!("  {} = call i32 {}(i8* {})", call_res, fn_reg, arg_reg));
        let done_slot = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @par.pool.done_sem, i32 0, i32 {}",
            done_slot, MAX_WORKERS, MAX_WORKERS, idx
        ));
        let done_h = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", done_h, done_slot));
        self.emit_semaphore_post(&done_h);
        self.line("  br label %loop");
        self.line("}");
        self.line("");

        // --- one-time lazy init: determine the live worker count, create ---
        // the recursive-lock semaphore, then each active worker's
        // start/done semaphore pair and its persistent thread. Guarded by a
        // plain (non-atomic) bool: this is only ever called from a
        // non-pool-worker thread (a pool worker takes the serial-fallback
        // path in `emit_par_dispatch` instead, never re-entering this
        // function), and the language has no feature that creates an OS
        // thread outside this pool -- so at most one thread of control ever
        // reaches this function, ever, making a plain load/store race-free
        // (no concurrent write is possible).
        self.line("define void @par.pool.ensure_init() {");
        self.open_block("entry");
        let inited = self.tmp_name();
        self.line(&format!("  {} = load i1, i1* @par.pool.inited", inited));
        self.line(&format!("  br i1 {}, label %par_pool_already, label %par_pool_init", inited));
        self.line("par_pool_init:");

        // Explicit override: `STAR_WORKERS=<n>` in the environment, read
        // via the same `getenv` already declared for the `env_get` builtin
        // (see `crate::codegen::os`).
        let env_name_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [13 x i8], [13 x i8]* @par.pool.env_name, i64 0, i64 0",
            env_name_ptr
        ));
        let env_ptr = self.tmp_name();
        self.line(&format!("  {} = call i8* @getenv(i8* {})", env_ptr, env_name_ptr));
        let env_is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", env_is_null, env_ptr));
        self.line(&format!("  br i1 {}, label %par_pool_detect, label %par_pool_override", env_is_null));

        self.line("par_pool_override:");
        let override_raw = self.tmp_name();
        self.line(&format!("  {} = call i32 @atoi(i8* {})", override_raw, env_ptr));
        self.line("  br label %par_pool_clamp");

        // No override: ask the OS -- `GetSystemInfo` or `sysconf`, whichever
        // `crate::codegen::platform::emit_detect_core_count` picked for this
        // `Codegen`'s `Target`.
        self.line("par_pool_detect:");
        let detected_raw = self.emit_detect_core_count();
        self.line("  br label %par_pool_clamp");

        self.line("par_pool_clamp:");
        let count_raw = self.tmp_name();
        self.line(&format!(
            "  {} = phi i32 [ {}, %par_pool_override ], [ {}, %par_pool_detect ]",
            count_raw, override_raw, detected_raw
        ));
        let below_min = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, {}", below_min, count_raw, MIN_WORKERS));
        let count_floor = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 {}, i32 {}", count_floor, below_min, MIN_WORKERS, count_raw));
        let above_max = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i32 {}, {}", above_max, count_floor, MAX_WORKERS));
        let count_final = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 {}, i32 {}", count_final, above_max, MAX_WORKERS, count_floor));
        self.line(&format!("  store i32 {}, i32* @par.pool.num_workers", count_final));

        let lock = self.emit_alloc_semaphore(1);
        self.line(&format!("  store i8* {}, i8** @par.pool.serial_lock", lock));

        self.line("  store i32 0, i32* @par.pool.init_i");
        self.line("  br label %par_pool_thread_cond");

        self.line("par_pool_thread_cond:");
        let ti = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* @par.pool.init_i", ti));
        let ti_cont = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, {}", ti_cont, ti, count_final));
        self.line(&format!("  br i1 {}, label %par_pool_thread_body, label %par_pool_init_done", ti_cont));

        self.line("par_pool_thread_body:");
        let ss = self.emit_alloc_semaphore(0);
        let ss_slot = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @par.pool.start_sem, i32 0, i32 {}",
            ss_slot, MAX_WORKERS, MAX_WORKERS, ti
        ));
        self.line(&format!("  store i8* {}, i8** {}", ss, ss_slot));

        let ds = self.emit_alloc_semaphore(0);
        let ds_slot = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @par.pool.done_sem, i32 0, i32 {}",
            ds_slot, MAX_WORKERS, MAX_WORKERS, ti
        ));
        self.line(&format!("  store i8* {}, i8** {}", ds, ds_slot));

        let ti64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", ti64, ti));
        let idx_as_ptr = self.tmp_name();
        self.line(&format!("  {} = inttoptr i64 {} to i8*", idx_as_ptr, ti64));
        // The persistent worker thread's own handle/id is intentionally
        // never closed/joined: it lives for the process's lifetime, same as
        // the pool itself -- matching the codebase's existing "no cleanup
        // needed for main-lifetime global state" precedent (arenas are
        // never freed either).
        self.emit_create_persistent_thread("par.pool.worker_main", &idx_as_ptr);
        let ti_next = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", ti_next, ti));
        self.line(&format!("  store i32 {}, i32* @par.pool.init_i", ti_next));
        self.line("  br label %par_pool_thread_cond");

        self.line("par_pool_init_done:");
        self.line("  store i1 true, i1* @par.pool.inited");
        self.line("  br label %par_pool_already");
        self.line("par_pool_already:");
        self.line("  ret void");
        self.line("}");
        self.line("");

        let pool_ir = std::mem::replace(&mut self.ir, saved_ir);
        self.pending_top.push(Self::hoist_allocas_to_entry(&pool_ir));
    }

    /// Dispatch one `par`/`swarm` statement's already-built per-callsite
    /// `worker_name` (the `par_worker_N` function `emit_par_stmt` just
    /// finished defining, of the generic `i32(i8*)` shape) to the
    /// persistent pool -- or, if this call is itself running on a pool
    /// worker thread (a nested `par`/`swarm`), run it serially inline
    /// instead (see this module's header comment for why).
    ///
    /// `args_ty` is the anonymous `{ i64, i64, T1*, ... }` argument-struct
    /// type `emit_par_stmt` already built; `captured` is the parallel list
    /// of captured `(name, _, ty)` triples used to fill its pointer fields.
    pub(super) fn emit_par_dispatch(&mut self, worker_name: &str, args_ty: &str, captured: &[(String, String, Ty)], arena: &str) {
        self.ensure_par_pool_emitted();

        self.line("  call void @par.pool.ensure_init()");

        let num_workers = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* @par.pool.num_workers", num_workers));
        let num_workers64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", num_workers64, num_workers));

        // Reentrancy check: does this thread's own id match one of the
        // pool's (runtime-many) live worker slots? `my_idx` ends up `>= 0`
        // (the matching slot) if so, `-1` otherwise. `num_workers` is a
        // runtime value, so this scans in a real loop rather than the fixed
        // chain of compile-time-unrolled comparisons a constant slot count
        // would allow.
        let my_tid = self.emit_current_thread_id64();

        let my_idx_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", my_idx_ptr));
        self.line(&format!("  store i32 -1, i32* {}", my_idx_ptr));
        let scan_i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", scan_i_ptr));
        self.line(&format!("  store i32 0, i32* {}", scan_i_ptr));

        let scan_cond = self.block_label("par_reentry_cond");
        let scan_body = self.block_label("par_reentry_body");
        let scan_match = self.block_label("par_reentry_match");
        let scan_step = self.block_label("par_reentry_step");
        let scan_end = self.block_label("par_reentry_end");

        self.line(&format!("  br label %{}", scan_cond));
        self.open_block(&scan_cond);
        let si = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", si, scan_i_ptr));
        let scan_cont = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, {}", scan_cont, si, num_workers));
        self.line(&format!("  br i1 {}, label %{}, label %{}", scan_cont, scan_body, scan_end));

        self.open_block(&scan_body);
        let tid_slot = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @par.pool.tid, i32 0, i32 {}",
            tid_slot, MAX_WORKERS, MAX_WORKERS, si
        ));
        let tid_t = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", tid_t, tid_slot));
        let eq = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, {}", eq, my_tid, tid_t));
        self.line(&format!("  br i1 {}, label %{}, label %{}", eq, scan_match, scan_step));

        self.open_block(&scan_match);
        self.line(&format!("  store i32 {}, i32* {}", si, my_idx_ptr));
        self.line(&format!("  br label %{}", scan_step));

        self.open_block(&scan_step);
        let si_next = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", si_next, si));
        self.line(&format!("  store i32 {}, i32* {}", si_next, scan_i_ptr));
        self.line(&format!("  br label %{}", scan_cond));

        self.open_block(&scan_end);
        let my_idx = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", my_idx, my_idx_ptr));

        let is_worker = self.tmp_name();
        self.line(&format!("  {} = icmp sge i32 {}, 0", is_worker, my_idx));

        let pooled_label = self.block_label("par_pooled");
        let serial_label = self.block_label("par_serial");
        let acquire_label = self.block_label("par_acquire");
        let run_label = self.block_label("par_run");
        let release_label = self.block_label("par_release");
        let join_label = self.block_label("par_join");

        self.line(&format!("  br i1 {}, label %{}, label %{}", is_worker, serial_label, pooled_label));

        // --- ordinary top-level dispatch: fan out to all live-worker mailboxes ---
        self.open_block(&pooled_label);
        let count_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @arena.{}.count", count_reg, arena));

        // Independent, stable-address argument-struct storage for each of
        // the (runtime-many, up to `MAX_WORKERS`) workers this dispatch
        // fans out to: one `alloca` of an array, indexed per iteration,
        // rather than a fresh `alloca` inside the loop below -- the latter
        // would only ever reserve one slot that every iteration reuses
        // (see `hoist_allocas_to_entry`'s own doc comment on why a loop-body
        // `alloca` doesn't accumulate distinct storage), silently aliasing
        // every concurrently-running worker's arguments onto the same
        // memory instead of giving each its own.
        let args_arr_ty = format!("[{} x {}]", MAX_WORKERS, args_ty);
        let args_arr = self.tmp_name();
        self.line(&format!("  {} = alloca {}", args_arr, args_arr_ty));

        let fanout_i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", fanout_i_ptr));
        self.line(&format!("  store i32 0, i32* {}", fanout_i_ptr));

        let fanout_cond = self.block_label("par_fanout_cond");
        let fanout_body = self.block_label("par_fanout_body");
        let fanout_step = self.block_label("par_fanout_step");
        let fanout_end = self.block_label("par_fanout_end");

        self.line(&format!("  br label %{}", fanout_cond));
        self.open_block(&fanout_cond);
        let fi = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", fi, fanout_i_ptr));
        let fanout_cont = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, {}", fanout_cont, fi, num_workers));
        self.line(&format!("  br i1 {}, label %{}, label %{}", fanout_cont, fanout_body, fanout_end));

        self.open_block(&fanout_body);
        let fi64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", fi64, fi));
        let start_mul = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", start_mul, count_reg, fi64));
        let start_div = self.tmp_name();
        self.line(&format!("  {} = sdiv i64 {}, {}", start_div, start_mul, num_workers64));
        let fi_plus1 = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", fi_plus1, fi));
        let fi_plus1_64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", fi_plus1_64, fi_plus1));
        let end_mul = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", end_mul, count_reg, fi_plus1_64));
        let end_div = self.tmp_name();
        self.line(&format!("  {} = sdiv i64 {}, {}", end_div, end_mul, num_workers64));

        let args_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}",
            args_ptr, args_arr_ty, args_arr_ty, args_arr, fi
        ));
        let sfield = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", sfield, args_ty, args_ty, args_ptr));
        self.line(&format!("  store i64 {}, i64* {}", start_div, sfield));
        let efield = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", efield, args_ty, args_ty, args_ptr));
        self.line(&format!("  store i64 {}, i64* {}", end_div, efield));
        for (i, (name, _, ty)) in captured.iter().enumerate() {
            let cfield = self.tmp_name();
            self.line(&format!(
                "  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}",
                cfield, args_ty, args_ty, args_ptr, i + 2
            ));
            let ptr_ty = self.sym_ptr_llvm_ty(name, ty);
            let src_ptr = self.sym_ptr(name).unwrap_or_else(|| "%undef".into());
            self.line(&format!("  store {} {}, {}* {}", ptr_ty, src_ptr, ptr_ty, cfield));
        }
        let args_i8 = self.tmp_name();
        self.line(&format!("  {} = bitcast {}* {} to i8*", args_i8, args_ty, args_ptr));

        let arg_slot = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @par.pool.job_arg, i32 0, i32 {}",
            arg_slot, MAX_WORKERS, MAX_WORKERS, fi
        ));
        self.line(&format!("  store i8* {}, i8** {}", args_i8, arg_slot));
        let fn_slot = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i32 (i8*)*], [{} x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 {}",
            fn_slot, MAX_WORKERS, MAX_WORKERS, fi
        ));
        self.line(&format!("  store i32 (i8*)* @{}, i32 (i8*)** {}", worker_name, fn_slot));

        let start_slot = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @par.pool.start_sem, i32 0, i32 {}",
            start_slot, MAX_WORKERS, MAX_WORKERS, fi
        ));
        let start_h = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", start_h, start_slot));
        self.emit_semaphore_post(&start_h);

        self.line(&format!("  br label %{}", fanout_step));
        self.open_block(&fanout_step);
        let fi_next = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", fi_next, fi));
        self.line(&format!("  store i32 {}, i32* {}", fi_next, fanout_i_ptr));
        self.line(&format!("  br label %{}", fanout_cond));

        self.open_block(&fanout_end);

        let join_i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", join_i_ptr));
        self.line(&format!("  store i32 0, i32* {}", join_i_ptr));

        let join_wait_cond = self.block_label("par_join_wait_cond");
        let join_wait_body = self.block_label("par_join_wait_body");
        let join_wait_step = self.block_label("par_join_wait_step");
        let join_wait_end = self.block_label("par_join_wait_end");

        self.line(&format!("  br label %{}", join_wait_cond));
        self.open_block(&join_wait_cond);
        let ji = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", ji, join_i_ptr));
        let join_cont = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, {}", join_cont, ji, num_workers));
        self.line(&format!("  br i1 {}, label %{}, label %{}", join_cont, join_wait_body, join_wait_end));

        self.open_block(&join_wait_body);
        let done_slot = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @par.pool.done_sem, i32 0, i32 {}",
            done_slot, MAX_WORKERS, MAX_WORKERS, ji
        ));
        let done_h = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", done_h, done_slot));
        self.emit_semaphore_wait(&done_h);
        self.line(&format!("  br label %{}", join_wait_step));
        self.open_block(&join_wait_step);
        let ji_next = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", ji_next, ji));
        self.line(&format!("  store i32 {}, i32* {}", ji_next, join_i_ptr));
        self.line(&format!("  br label %{}", join_wait_cond));

        self.open_block(&join_wait_end);
        self.line(&format!("  br label %{}", join_label));

        // --- nested `par`/`swarm`: this thread is itself a pool worker, so ---
        // it can't dispatch to the pool it belongs to; run the whole range
        // serially inline instead, behind the manually-reentrant lock.
        self.open_block(&serial_label);
        let owner_reg = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* @par.pool.serial_owner", owner_reg));
        let already_mine = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, {}", already_mine, owner_reg, my_idx));
        self.line(&format!("  br i1 {}, label %{}, label %{}", already_mine, run_label, acquire_label));

        self.open_block(&acquire_label);
        let lock_h = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** @par.pool.serial_lock", lock_h));
        self.emit_semaphore_wait(&lock_h);
        self.line(&format!("  store i32 {}, i32* @par.pool.serial_owner", my_idx));
        self.line(&format!("  br label %{}", run_label));

        self.open_block(&run_label);
        let count_reg2 = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @arena.{}.count", count_reg2, arena));
        let args_ptr2 = self.tmp_name();
        self.line(&format!("  {} = alloca {}", args_ptr2, args_ty));
        let sfield2 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", sfield2, args_ty, args_ty, args_ptr2));
        self.line(&format!("  store i64 0, i64* {}", sfield2));
        let efield2 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", efield2, args_ty, args_ty, args_ptr2));
        self.line(&format!("  store i64 {}, i64* {}", count_reg2, efield2));
        for (i, (name, _, ty)) in captured.iter().enumerate() {
            let cfield = self.tmp_name();
            self.line(&format!(
                "  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}",
                cfield, args_ty, args_ty, args_ptr2, i + 2
            ));
            let ptr_ty = self.sym_ptr_llvm_ty(name, ty);
            let src_ptr = self.sym_ptr(name).unwrap_or_else(|| "%undef".into());
            self.line(&format!("  store {} {}, {}* {}", ptr_ty, src_ptr, ptr_ty, cfield));
        }
        let args_i8_2 = self.tmp_name();
        self.line(&format!("  {} = bitcast {}* {} to i8*", args_i8_2, args_ty, args_ptr2));
        let call_res = self.tmp_name();
        self.line(&format!("  {} = call i32 @{}(i8* {})", call_res, worker_name, args_i8_2));
        self.line(&format!("  br i1 {}, label %{}, label %{}", already_mine, join_label, release_label));

        self.open_block(&release_label);
        self.line("  store i32 -1, i32* @par.pool.serial_owner");
        let lock_h2 = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** @par.pool.serial_lock", lock_h2));
        self.emit_semaphore_post(&lock_h2);
        self.line(&format!("  br label %{}", join_label));

        self.open_block(&join_label);
    }
}

/// `SYSTEM_INFO`'s total size on x86-64: a leading 4-byte anonymous union,
/// `dwPageSize` (4 bytes), two 8-byte-aligned `LPVOID` fields (8 bytes
/// each), `dwActiveProcessorMask` (a `DWORD_PTR`, 8 bytes on this target),
/// `dwNumberOfProcessors`/`dwProcessorType`/`dwAllocationGranularity` (4
/// bytes each), and two trailing `WORD` fields (2 bytes each) -- 48 bytes
/// total. Only `dwNumberOfProcessors` is ever read (see
/// `SYSTEM_INFO_NUM_PROCESSORS_OFFSET`); the buffer is sized to the whole
/// struct because `GetSystemInfo` writes it in full. `pub(super)`: read by
/// `crate::codegen::platform::emit_detect_core_count`'s `Target::WindowsGnu`
/// arm, the only other place this layout needs to be known.
pub(super) const SYSTEM_INFO_SIZE: u32 = 48;

/// Byte offset of `SYSTEM_INFO.dwNumberOfProcessors` -- see
/// `SYSTEM_INFO_SIZE`'s doc comment for the field layout this falls out of.
pub(super) const SYSTEM_INFO_NUM_PROCESSORS_OFFSET: u32 = 32;
