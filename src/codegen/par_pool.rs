//! The persistent `par`/`swarm` worker-thread pool: a fixed set of OS
//! threads created once (lazily, on first dispatch) and reused for the
//! process's lifetime, replacing the old per-`par`-statement
//! `CreateThread`/`WaitForSingleObject`/`CloseHandle` cycle. See
//! `Codegen::emit_par_stmt` (`arena.rs`) for the per-callsite worker
//! function this dispatches to.
//!
//! Each of the `NUM_WORKERS` threads has its own dedicated "mailbox" (a
//! slot in four parallel global arrays) rather than pulling from a shared
//! queue: every dispatch always fans out to exactly `NUM_WORKERS` chunks,
//! one per worker, so a generic multi-producer/multi-consumer queue would
//! only add deadlock/lost-wakeup surface area for no behavioral benefit.
//! Handoff in both directions (dispatcher -> worker "go", worker ->
//! dispatcher "done") uses a Win32 counting semaphore rather than a
//! condition variable: a `ReleaseSemaphore` that happens before the
//! matching `WaitForSingleObject` is reached still leaves the semaphore's
//! count at 1, so there is no lost-wakeup window on either side of the
//! handoff -- a condition variable would need an auxiliary mutex-guarded
//! predicate to get the same guarantee.
//!
//! Nested `par`/`swarm` (a `par` body containing another `par` statement,
//! which the checker's disjointness proof allows -- see
//! `types::par_analysis::walk_par_stmt`'s `TypedStmt::Par` arm) can't
//! dispatch to this same fixed 4-worker pool: a worker that hits a nested
//! `par` is itself busy, so it runs the nested loop serially, inline, on
//! its own thread instead. That fallback is guarded by a manually
//! reentrant lock (`serial_lock` + `serial_owner`), not run bare: if it
//! were run without a lock, every outer worker concurrently reaches the
//! same nested statement (the outer `par` is genuinely running on multiple
//! workers at once) and each would independently run a full, overlapping
//! pass over the same nested arena -- a real data race. The lock is
//! manually reentrant (a bare Win32 semaphore is not) so that a thread
//! already holding it for an outer nested `par` doesn't self-deadlock when
//! it reaches a *deeper* nested `par` on the same thread.

use crate::types::*;

use super::Codegen;

/// Fixed pool size, matching the number of chunks a dispatch always splits
/// an arena's live range into (see `emit_par_dispatch`'s pooled-path chunk
/// math, unchanged from the old per-call design).
const NUM_WORKERS: u32 = 4;

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

        self.line(&format!("@par.pool.job_fn = global [{} x i32 (i8*)*] zeroinitializer", NUM_WORKERS));
        self.line(&format!("@par.pool.job_arg = global [{} x i8*] zeroinitializer", NUM_WORKERS));
        self.line(&format!("@par.pool.start_sem = global [{} x i8*] zeroinitializer", NUM_WORKERS));
        self.line(&format!("@par.pool.done_sem = global [{} x i8*] zeroinitializer", NUM_WORKERS));
        self.line(&format!("@par.pool.tid = global [{} x i32] zeroinitializer", NUM_WORKERS));
        self.line("@par.pool.inited = global i1 false");
        // Recursive-mutex pair backing the nested-`par` serial fallback --
        // see this module's header comment.
        self.line("@par.pool.serial_lock = global i8* null");
        self.line("@par.pool.serial_owner = global i32 -1");
        self.line("");

        // --- generic worker-thread entry point, run by all NUM_WORKERS ---
        // persistent threads. `%idx_arg` is the worker's own index (0..4),
        // smuggled through the `LPTHREAD_START_ROUTINE`-shaped `i8*` param
        // as if it were a pointer (see `ensure_init`'s `inttoptr`).
        self.line("define i32 @par.pool.worker_main(i8* %idx_arg) {");
        self.line("entry:");
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = ptrtoint i8* %idx_arg to i64", idx64));
        let idx = self.tmp_name();
        self.line(&format!("  {} = trunc i64 {} to i32", idx, idx64));
        // Record this thread's own OS thread id before ever waiting on a
        // job, so `emit_par_dispatch`'s reentrancy check can always trust
        // that a job running on worker `idx` has already published its tid.
        let tid = self.tmp_name();
        self.line(&format!("  {} = call i32 @GetCurrentThreadId()", tid));
        let tid_slot = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i32], [{} x i32]* @par.pool.tid, i32 0, i32 {}",
            tid_slot, NUM_WORKERS, NUM_WORKERS, idx
        ));
        self.line(&format!("  store i32 {}, i32* {}", tid, tid_slot));
        self.line("  br label %loop");
        self.line("loop:");
        let start_slot = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @par.pool.start_sem, i32 0, i32 {}",
            start_slot, NUM_WORKERS, NUM_WORKERS, idx
        ));
        let start_h = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", start_h, start_slot));
        let wres = self.tmp_name();
        self.line(&format!("  {} = call i32 @WaitForSingleObject(i8* {}, i32 -1)", wres, start_h));
        let fn_slot = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i32 (i8*)*], [{} x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 {}",
            fn_slot, NUM_WORKERS, NUM_WORKERS, idx
        ));
        let fn_reg = self.tmp_name();
        self.line(&format!("  {} = load i32 (i8*)*, i32 (i8*)** {}", fn_reg, fn_slot));
        let arg_slot = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @par.pool.job_arg, i32 0, i32 {}",
            arg_slot, NUM_WORKERS, NUM_WORKERS, idx
        ));
        let arg_reg = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", arg_reg, arg_slot));
        let call_res = self.tmp_name();
        self.line(&format!("  {} = call i32 {}(i8* {})", call_res, fn_reg, arg_reg));
        let done_slot = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @par.pool.done_sem, i32 0, i32 {}",
            done_slot, NUM_WORKERS, NUM_WORKERS, idx
        ));
        let done_h = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", done_h, done_slot));
        let rel = self.tmp_name();
        self.line(&format!("  {} = call i32 @ReleaseSemaphore(i8* {}, i32 1, i32* null)", rel, done_h));
        self.line("  br label %loop");
        self.line("}");
        self.line("");

        // --- one-time lazy init: create the recursive-lock semaphore, each ---
        // worker's start/done semaphore pair, and the NUM_WORKERS persistent
        // threads themselves. Guarded by a plain (non-atomic) bool: this is
        // only ever called from a non-pool-worker thread (a pool worker
        // takes the serial-fallback path in `emit_par_dispatch` instead,
        // never re-entering this function), and the language has no feature
        // that creates an OS thread outside this pool -- so at most one
        // thread of control ever reaches this function, ever, making a
        // plain load/store race-free (no concurrent write is possible).
        self.line("define void @par.pool.ensure_init() {");
        self.line("entry:");
        let inited = self.tmp_name();
        self.line(&format!("  {} = load i1, i1* @par.pool.inited", inited));
        self.line(&format!("  br i1 {}, label %par_pool_already, label %par_pool_init", inited));
        self.line("par_pool_init:");
        let lock = self.tmp_name();
        self.line(&format!("  {} = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)", lock));
        self.line(&format!("  store i8* {}, i8** @par.pool.serial_lock", lock));
        for t in 0..NUM_WORKERS {
            let ss = self.tmp_name();
            self.line(&format!("  {} = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)", ss));
            let ss_slot = self.tmp_name();
            self.line(&format!(
                "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @par.pool.start_sem, i32 0, i32 {}",
                ss_slot, NUM_WORKERS, NUM_WORKERS, t
            ));
            self.line(&format!("  store i8* {}, i8** {}", ss, ss_slot));

            let ds = self.tmp_name();
            self.line(&format!("  {} = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)", ds));
            let ds_slot = self.tmp_name();
            self.line(&format!(
                "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @par.pool.done_sem, i32 0, i32 {}",
                ds_slot, NUM_WORKERS, NUM_WORKERS, t
            ));
            self.line(&format!("  store i8* {}, i8** {}", ds, ds_slot));

            // The persistent worker thread's own handle is intentionally
            // never `CloseHandle`'d: it lives for the process's lifetime,
            // same as the pool itself -- matching the codebase's existing
            // "no cleanup needed for main-lifetime global state" precedent
            // (arenas are never freed either).
            let h = self.tmp_name();
            self.line(&format!(
                "  {} = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 {} to i8*), i32 0, i32* null)",
                h, t
            ));
        }
        self.line("  store i1 true, i1* @par.pool.inited");
        self.line("  br label %par_pool_already");
        self.line("par_pool_already:");
        self.line("  ret void");
        self.line("}");
        self.line("");

        let pool_ir = std::mem::replace(&mut self.ir, saved_ir);
        self.pending_top.push(pool_ir);
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

        // Reentrancy check: does this thread's own id match one of the
        // pool's NUM_WORKERS worker slots? `my_idx` ends up `>= 0` (the
        // matching slot) if so, `-1` otherwise.
        let my_tid = self.tmp_name();
        self.line(&format!("  {} = call i32 @GetCurrentThreadId()", my_tid));
        let mut idx_reg = "-1".to_string();
        for t in 0..NUM_WORKERS {
            let slot = self.tmp_name();
            self.line(&format!(
                "  {} = getelementptr inbounds [{} x i32], [{} x i32]* @par.pool.tid, i32 0, i32 {}",
                slot, NUM_WORKERS, NUM_WORKERS, t
            ));
            let tid_t = self.tmp_name();
            self.line(&format!("  {} = load i32, i32* {}", tid_t, slot));
            let eq = self.tmp_name();
            self.line(&format!("  {} = icmp eq i32 {}, {}", eq, my_tid, tid_t));
            let sel = self.tmp_name();
            self.line(&format!("  {} = select i1 {}, i32 {}, i32 {}", sel, eq, t, idx_reg));
            idx_reg = sel;
        }
        let my_idx = idx_reg;

        let is_worker = self.tmp_name();
        self.line(&format!("  {} = icmp sge i32 {}, 0", is_worker, my_idx));

        let pooled_label = self.block_label("par_pooled");
        let serial_label = self.block_label("par_serial");
        let acquire_label = self.block_label("par_acquire");
        let run_label = self.block_label("par_run");
        let release_label = self.block_label("par_release");
        let join_label = self.block_label("par_join");

        self.line(&format!("  br i1 {}, label %{}, label %{}", is_worker, serial_label, pooled_label));

        // --- ordinary top-level dispatch: fan out to all NUM_WORKERS mailboxes ---
        self.line(&format!("{}:", pooled_label));
        let count_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @arena.{}.count", count_reg, arena));
        for t in 0..NUM_WORKERS {
            let start_mul = self.tmp_name();
            self.line(&format!("  {} = mul i64 {}, {}", start_mul, count_reg, t));
            let start_div = self.tmp_name();
            self.line(&format!("  {} = sdiv i64 {}, {}", start_div, start_mul, NUM_WORKERS));
            let end_mul = self.tmp_name();
            self.line(&format!("  {} = mul i64 {}, {}", end_mul, count_reg, t + 1));
            let end_div = self.tmp_name();
            self.line(&format!("  {} = sdiv i64 {}, {}", end_div, end_mul, NUM_WORKERS));

            let args_ptr = self.tmp_name();
            self.line(&format!("  {} = alloca {}", args_ptr, args_ty));
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
                arg_slot, NUM_WORKERS, NUM_WORKERS, t
            ));
            self.line(&format!("  store i8* {}, i8** {}", args_i8, arg_slot));
            let fn_slot = self.tmp_name();
            self.line(&format!(
                "  {} = getelementptr inbounds [{} x i32 (i8*)*], [{} x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 {}",
                fn_slot, NUM_WORKERS, NUM_WORKERS, t
            ));
            self.line(&format!("  store i32 (i8*)* @{}, i32 (i8*)** {}", worker_name, fn_slot));

            let start_slot = self.tmp_name();
            self.line(&format!(
                "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @par.pool.start_sem, i32 0, i32 {}",
                start_slot, NUM_WORKERS, NUM_WORKERS, t
            ));
            let start_h = self.tmp_name();
            self.line(&format!("  {} = load i8*, i8** {}", start_h, start_slot));
            let relr = self.tmp_name();
            self.line(&format!("  {} = call i32 @ReleaseSemaphore(i8* {}, i32 1, i32* null)", relr, start_h));
        }
        for t in 0..NUM_WORKERS {
            let done_slot = self.tmp_name();
            self.line(&format!(
                "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @par.pool.done_sem, i32 0, i32 {}",
                done_slot, NUM_WORKERS, NUM_WORKERS, t
            ));
            let done_h = self.tmp_name();
            self.line(&format!("  {} = load i8*, i8** {}", done_h, done_slot));
            let wait = self.tmp_name();
            self.line(&format!("  {} = call i32 @WaitForSingleObject(i8* {}, i32 -1)", wait, done_h));
        }
        self.line(&format!("  br label %{}", join_label));

        // --- nested `par`/`swarm`: this thread is itself a pool worker, so ---
        // it can't dispatch to the pool it belongs to; run the whole range
        // serially inline instead, behind the manually-reentrant lock.
        self.line(&format!("{}:", serial_label));
        let owner_reg = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* @par.pool.serial_owner", owner_reg));
        let already_mine = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, {}", already_mine, owner_reg, my_idx));
        self.line(&format!("  br i1 {}, label %{}, label %{}", already_mine, run_label, acquire_label));

        self.line(&format!("{}:", acquire_label));
        let lock_h = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** @par.pool.serial_lock", lock_h));
        let wait2 = self.tmp_name();
        self.line(&format!("  {} = call i32 @WaitForSingleObject(i8* {}, i32 -1)", wait2, lock_h));
        self.line(&format!("  store i32 {}, i32* @par.pool.serial_owner", my_idx));
        self.line(&format!("  br label %{}", run_label));

        self.line(&format!("{}:", run_label));
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

        self.line(&format!("{}:", release_label));
        self.line("  store i32 -1, i32* @par.pool.serial_owner");
        let lock_h2 = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** @par.pool.serial_lock", lock_h2));
        let rel2 = self.tmp_name();
        self.line(&format!("  {} = call i32 @ReleaseSemaphore(i8* {}, i32 1, i32* null)", rel2, lock_h2));
        self.line(&format!("  br label %{}", join_label));

        self.line(&format!("{}:", join_label));
    }
}
