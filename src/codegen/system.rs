//! Codegen for `system`/`parallel`.
//!
//! A `system` compiles to exactly the `i32(i8*)` shape
//! `Codegen::emit_par_stmt`'s per-callsite `par_worker_N` chunk functions
//! already use (see `arena.rs`) -- the same shape `par_pool`'s mailbox
//! arrays (`@par.pool.job_fn`, sized `[NUM_WORKERS x i32 (i8*)*]`) expect.
//! That's deliberate: it lets `emit_parallel_stmt` dispatch a `system` to
//! the persistent worker pool by reusing `par_pool`'s existing globals and
//! lazy-init function completely unchanged, rather than building a second,
//! parallel (no pun intended) pool just for whole-system dispatch.
//!
//! `emit_parallel_stmt` never needs `par_pool::emit_par_dispatch`'s
//! reentrancy/serial-fallback branch: `system_analysis::check_parallel_stmt`
//! (by way of `par_analysis`'s and `system_analysis`'s own bans on nesting
//! `parallel:` inside a `system`/`par`/`swarm` body) guarantees a
//! `parallel:` statement is only ever reached from a thread that is *not*
//! already one of the pool's workers, so the plain fan-out-and-join half is
//! always the right one.
//!
//! A `par`/`swarm` loop nested *inside* a system's own body still works with
//! no new runtime code at all: once that system is running on a pool-worker
//! thread (dispatched here), `emit_par_dispatch`'s existing
//! `GetCurrentThreadId`-based reentrancy check already recognizes the
//! calling thread as one of the `NUM_WORKERS` pool workers and takes its
//! existing serial-fallback path -- the same path a `par` nested inside
//! another `par` already takes today.

use crate::types::*;

use super::par_pool;
use super::Codegen;

impl Codegen {
    /// Compile a `system Name(...): <body>` declaration to
    /// `define i32 @sys.Name(i8* %_unused) { ...body...; ret i32 0 }` --
    /// mechanically almost identical to `emit_fn`'s zero-parameter case,
    /// except the body is emitted through the *pool job* signature
    /// (`i32(i8*)`) rather than whatever the source declared (a system
    /// never declares a return type at all), so it can be stored directly
    /// into `@par.pool.job_fn` by `emit_parallel_stmt` with no wrapper.
    pub(super) fn emit_system(&mut self, s: &TypedSystemDef) {
        self.symbols.clear();
        self.owned_stack.clear();
        self.push_scope();
        self.tmp = 0;
        let fn_start = self.ir.len();

        let saved_in_frame = self.in_frame;
        self.in_frame = false;
        let was_in_main = self.in_main;
        // A system has no declared return type, so an ordinary bare
        // `return` would otherwise lower to `ret void` (see `emit_stmt`'s
        // `TypedStmt::Return` arm) -- but this function's real, compiled
        // LLVM signature is `i32`, to fit the pool's job-function shape.
        // `in_main` is the existing "a bare `return` here must produce
        // `ret i32 0`, not `ret void`" signal (`main` needs exactly the
        // same accommodation, for the same ABI-shape reason -- see
        // `emit_fn`'s own `is_main` handling), so reusing it here needs no
        // new codegen-side plumbing at all.
        self.in_main = true;

        self.line(&format!("define i32 @sys.{}(i8* %_unused) {{", s.name));
        self.open_block("entry");

        let terminated = Self::body_terminates(&s.body.stmts);
        self.emit_stmts_value(&s.body.stmts);
        self.pop_scope(!terminated);

        if !terminated {
            self.line("  ret i32 0");
        }
        self.line("}");
        self.line("");

        self.in_frame = saved_in_frame;
        self.in_main = was_in_main;

        let fn_ir = self.ir.split_off(fn_start);
        self.ir.push_str(&Self::hoist_allocas_to_entry(&fn_ir));
    }

    /// Emit `parallel: SystemA() SystemB() ...`: fan each already-compiled
    /// `@sys.Name` out to its own slot in the persistent `par`/`swarm`
    /// worker pool's mailbox arrays (reusing `par_pool`'s globals and
    /// lazy-init function verbatim -- see this module's doc comment), then
    /// wait for all of them to finish. `systems` is already validated by
    /// `Checker::check_parallel_stmt` to name real, non-conflicting,
    /// at-most-`NUM_WORKERS`-many systems, so no bounds/reentrancy handling
    /// is needed here at all.
    pub(super) fn emit_parallel_stmt(&mut self, systems: &[String]) {
        self.ensure_par_pool_emitted();
        self.line("  call void @par.pool.ensure_init()");

        for (t, name) in systems.iter().enumerate() {
            let t = t as u32;
            let fn_slot = self.tmp_name();
            self.line(&format!(
                "  {} = getelementptr inbounds [{} x i32 (i8*)*], [{} x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 {}",
                fn_slot,
                par_pool::NUM_WORKERS,
                par_pool::NUM_WORKERS,
                t
            ));
            self.line(&format!("  store i32 (i8*)* @sys.{}, i32 (i8*)** {}", name, fn_slot));

            let arg_slot = self.tmp_name();
            self.line(&format!(
                "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @par.pool.job_arg, i32 0, i32 {}",
                arg_slot,
                par_pool::NUM_WORKERS,
                par_pool::NUM_WORKERS,
                t
            ));
            self.line(&format!("  store i8* null, i8** {}", arg_slot));

            let start_slot = self.tmp_name();
            self.line(&format!(
                "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @par.pool.start_sem, i32 0, i32 {}",
                start_slot,
                par_pool::NUM_WORKERS,
                par_pool::NUM_WORKERS,
                t
            ));
            let start_h = self.tmp_name();
            self.line(&format!("  {} = load i8*, i8** {}", start_h, start_slot));
            let rel = self.tmp_name();
            self.line(&format!("  {} = call i32 @ReleaseSemaphore(i8* {}, i32 1, i32* null)", rel, start_h));
        }

        for t in 0..systems.len() as u32 {
            let done_slot = self.tmp_name();
            self.line(&format!(
                "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @par.pool.done_sem, i32 0, i32 {}",
                done_slot,
                par_pool::NUM_WORKERS,
                par_pool::NUM_WORKERS,
                t
            ));
            let done_h = self.tmp_name();
            self.line(&format!("  {} = load i8*, i8** {}", done_h, done_slot));
            let wait = self.tmp_name();
            self.line(&format!("  {} = call i32 @WaitForSingleObject(i8* {}, i32 -1)", wait, done_h));
        }
    }
}
