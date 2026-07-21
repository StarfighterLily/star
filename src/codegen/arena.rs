//! Arena declarations and the `spawn`/`despawn`/`par`/`GenRef` slot-map
//! machinery backing them: a fixed-capacity backing array plus a parallel
//! generation array (liveness + ABA protection) and a free-list stack for
//! slot reuse.

use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

impl Codegen {
    pub(super) fn emit_arena_decl(&mut self, a: &TypedArenaDecl) {
        let elem_ty = self.llvm_ty(&a.ty);
        self.line(&format!("%{} = type {{ {}*, i64 }}", a.name, elem_ty));
        self.line(&format!("@arena.{}.data = global {}* null", a.name, elem_ty));
        self.line(&format!("@arena.{}.count = global i64 0", a.name));
        // Per-slot generation counters backing `GenRef<T>` where `T` is this
        // arena's element type: 0 means "never spawned". Every `spawn` and
        // `despawn` of a slot bumps its generation by exactly 1 (never resets
        // it to a fixed value), so parity encodes liveness -- odd is live,
        // even is dead/never-spawned -- and no two spawns of the same slot
        // ever share a generation. That's what prevents the ABA problem once
        // slots are reused via the free-list below. A `GenRef` captures a
        // slot's generation at creation time and a dereference is only
        // trusted if it still matches this array's live value -- see
        // `emit_despawn_stmt`/`GenRefCreate`/`GenRefIndex`.
        //
        // `i64`, not `i32`: a 32-bit counter wraps after only ~2^31
        // despawn/spawn cycles on one slot -- a few seconds of a tight loop,
        // confirmed via a real repro (a `GenRef` captured before the wrap
        // matching the post-wrap live generation and reading the new
        // occupant's data instead of being caught as stale). `i64` needs
        // ~2^63 cycles for the same attack -- not reachable in any
        // realistic program's lifetime.
        //
        // `a.capacity` is this arena's own resolved element count (defaults
        // to `crate::types::DEFAULT_ARENA_CAPACITY` when the source didn't
        // override it via `arena Name: Type = N`) -- every array below is
        // sized per-arena rather than against one shared constant, and
        // `self.arena_capacity` records it so every other emitter touching
        // this arena by name (`spawn`/`despawn`/`each`/`par`/`GenRef`) can
        // look the same number back up.
        self.arena_capacity.insert(a.name.clone(), a.capacity);
        self.line(&format!("@arena.{}.gen = global [{} x i64] zeroinitializer", a.name, a.capacity));
        // Free-list stack of despawned slot indices, so `spawn` can reclaim a
        // slot's memory instead of only ever growing `count` -- this is the
        // "internal free-list to manage fragmentation" design.md promises.
        // See `emit_despawn_stmt` (push) and `emit_spawn_stmt` (pop).
        self.line(&format!("@arena.{}.free = global [{} x i64] zeroinitializer", a.name, a.capacity));
        self.line(&format!("@arena.{}.free_top = global i64 0", a.name));
        // Once-only overflow-warning latch (see `emit_spawn_stmt`'s
        // `capacity_warn_label`): without this, a body that keeps trying to
        // `spawn` into a full arena every tick (an enemy spawner that never
        // notices the pool is full, say) would print the same warning once
        // per attempt for the rest of the program's run.
        self.line(&format!("@arena.{}.warned = global i1 0", a.name));
        self.line("");
        self.arena_by_elem.push((a.ty.clone(), a.name.clone()));
    }

    /// Resolve the arena backing `GenRef<ty>`. The checker has already
    /// proven exactly one exists (`Checker::require_backing_arena`); this is
    /// a defensive fallback only, matching the codebase's existing
    /// defensive-error convention (e.g. `emit_scalar_binop`'s `&&`/`||` arm).
    fn arena_for_elem_ty(&mut self, ty: &Ty, span: Span) -> String {
        match self.arena_by_elem.iter().find(|(t, _)| t == ty) {
            Some((_, name)) => name.clone(),
            None => {
                self.err("GenRef<T> has no backing arena", span);
                String::new()
            }
        }
    }

    /// Emit a `par`/`swarm item in ArenaName: <body>` statement: builds this
    /// callsite's own `par_worker_N` function (walking a `[start, end)`
    /// chunk of the arena's live elements), then hands it off to the
    /// persistent worker-thread pool (`par_pool::emit_par_dispatch`) for
    /// dispatch. The checker has already proven the body only mutates
    /// `item` (or its own locals), so handing each pool worker a disjoint
    /// `[start, end)` range is safe.
    ///
    /// Everything currently in scope (locals, `self`) is captured by
    /// pointer into a small per-call argument struct; the dispatcher blocks
    /// on every pool worker finishing before continuing (see
    /// `emit_par_dispatch`), so the outer stack frame backing those
    /// captured pointers is guaranteed to outlive the workers that
    /// reference it.
    pub(super) fn emit_par_stmt(&mut self, var: &str, elem_ty: &Ty, arena: &str, body: &TypedBlock) {
        let cap = self.arena_capacity(arena);
        let id = self.block_id;
        self.block_id += 1;
        let worker_name = format!("par_worker_{}", id);

        let captured: Vec<(String, String, Ty)> = self.symbols.clone();

        // The argument struct `{ i64, i64, T1*, T2*, ... }` (chunk
        // `[start, end)` followed by one pointer field per captured outer
        // variable) is spelled out as an *anonymous* struct type rather than
        // a named `%ParArgsN`. LLVM resolves named types only after seeing
        // their declaration textually, but the worker function's `define`
        // must be deferred past the end of the enclosing function (see
        // `pending_top` below) while the call site's `alloca` needs the type
        // right here -- an anonymous type is structural, so both spellings
        // resolve to the same type without needing a forward declaration.
        let mut field_tys = vec!["i64".to_string(), "i64".to_string()];
        for (name, _, ty) in &captured {
            field_tys.push(self.sym_ptr_llvm_ty(name, ty));
        }
        let args_ty = format!("{{ {} }}", field_tys.join(", "));

        // --- worker function: walks [start, end) over the arena's backing array ---
        let saved_ir = std::mem::take(&mut self.ir);
        let saved_symbols = std::mem::take(&mut self.symbols);
        let saved_in_frame = self.in_frame;
        self.in_frame = false; // the frame bump allocator's offset is a single shared global, not thread-safe
        let saved_in_main = self.in_main;
        self.in_main = false; // the worker function is its own `i32`-returning function, not `main` itself
        // `self.owned_stack` tracks pointers to release at scope exit (see
        // `rc.rs`), keyed by register names -- those names are only
        // meaningful within the LLVM function they were emitted into. Like
        // `self.ir`/`self.symbols` above, this must be swapped out for the
        // worker function's own, empty stack rather than shared with the
        // caller: previously an RC-owned local declared inside the loop
        // body (`let t: str = e.name`) called `track_owned`, which pushed
        // onto *the caller's* still-open scope frame (nothing here ever
        // swapped it), so once codegen returned to the caller and that
        // frame was eventually popped, it tried to release a register that
        // was never defined in the caller's function at all -- invalid IR
        // ("use of undefined value"), not just a leak.
        let saved_owned_stack = std::mem::take(&mut self.owned_stack);

        self.line(&format!("define i32 @{}(i8* %argp) {{", worker_name));
        self.open_block("entry");
        let typed_arg = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* %argp to {}*", typed_arg, args_ty));
        let start_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", start_ptr, args_ty, args_ty, typed_arg));
        let start_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", start_reg, start_ptr));
        let end_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", end_ptr, args_ty, args_ty, typed_arg));
        let end_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", end_reg, end_ptr));

        for (i, (name, _, ty)) in captured.iter().enumerate() {
            let field_ptr = self.tmp_name();
            self.line(&format!(
                "  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}",
                field_ptr, args_ty, args_ty, typed_arg, i + 2
            ));
            let ptr_ty = self.sym_ptr_llvm_ty(name, ty);
            let loaded = self.tmp_name();
            self.line(&format!("  {} = load {}, {}* {}", loaded, ptr_ty, ptr_ty, field_ptr));
            self.symbols.push((name.clone(), loaded, ty.clone()));
        }

        let elem_llvm_ty = self.llvm_ty(elem_ty);
        let data_reg = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** @arena.{}.data", data_reg, elem_llvm_ty, elem_llvm_ty, arena));

        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 {}, i64* {}", start_reg, i_ptr));
        let cond_label = self.block_label("par_cond");
        let body_label = self.block_label("par_body");
        let live_label = self.block_label("par_live");
        let incr_label = self.block_label("par_incr");
        let end_label = self.block_label("par_end");
        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&cond_label);
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
        let cmp = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", cmp, i_reg, end_reg));
        self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, body_label, end_label));
        self.open_block(&body_label);
        // `@arena.{arena}.count` is a high-water mark of ever-allocated
        // slots, not a live count -- `despawn` never decrements it (see
        // `emit_despawn_stmt`), only bumps the slot's generation and pushes
        // it onto the free-list. Without this check, a `par`/`swarm` walking
        // `[0, count)` would visit a despawned "hole" exactly like a live
        // slot: for an RC-bearing element type, `despawn` already released
        // that slot's content (see `emit_despawn_stmt`'s own `emit_release_at`
        // call), so reading/retaining it here is a use-after-free; even for a
        // plain-data element it's a stale/logically-nonexistent entity that
        // shouldn't be visited at all. Live slots always carry an odd
        // generation (see `emit_arena_decl`), so a parity check is enough to
        // skip every despawned/never-spawned slot in this chunk.
        let gen_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @arena.{}.gen, i64 0, i64 {}",
            gen_ptr, cap, cap, arena, i_reg
        ));
        let gen_val = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", gen_val, gen_ptr));
        let parity = self.tmp_name();
        self.line(&format!("  {} = and i64 {}, 1", parity, gen_val));
        let is_live = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, 1", is_live, parity));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_live, live_label, incr_label));
        self.open_block(&live_label);
        let elem_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds {}, {}* {}, i64 {}",
            elem_ptr, elem_llvm_ty, elem_llvm_ty, data_reg, i_reg
        ));
        self.symbols.push((var.to_string(), elem_ptr, elem_ty.clone()));
        // Each iteration is its own scope: an RC-owned local declared in
        // the body (`let t: str = ...`) must be released at the end of
        // *that* iteration, not accumulate across the whole chunk this
        // worker walks or (as this call was missing entirely before) leak
        // into the caller's own scope bookkeeping -- see `saved_owned_stack`
        // above.
        self.push_scope();
        for stmt in &body.stmts {
            self.emit_stmt(stmt);
        }
        self.pop_scope(true);
        self.symbols.pop();
        self.line(&format!("  br label %{}", incr_label));
        self.open_block(&incr_label);
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&end_label);
        self.line("  ret i32 0");
        self.line("}");
        self.line("");

        let worker_ir = std::mem::replace(&mut self.ir, saved_ir);
        self.pending_top.push(Self::hoist_allocas_to_entry(&worker_ir));
        self.symbols = saved_symbols;
        self.in_frame = saved_in_frame;
        self.in_main = saved_in_main;
        self.owned_stack = saved_owned_stack;

        // --- back in the caller: hand off to the persistent worker pool ---
        self.emit_par_dispatch(&worker_name, &args_ty, &captured, arena);
    }

    /// Emit `each item in ArenaName: <body>` (or `each item, idx in
    /// ArenaName:`): an ordinary sequential loop over `[0, count)` of the
    /// arena's backing array, inline in the caller's own function -- no
    /// worker-pool dispatch, no argument-struct capture, no per-iteration
    /// scratch function (contrast `emit_par_stmt` just above). Since the
    /// body runs on the calling thread alone, there's nothing to prove
    /// disjoint: it may freely read/write anything already in scope and
    /// call any function, including SDL drawing builtins that `par`/`swarm`
    /// ban outright (`Checker::check_par_disjoint`'s
    /// `is_banned_sdl_builtin_in_par` never runs against an `each` body --
    /// see `Stmt::Each`'s own doc comment and `projects/snake/NOTES.md`
    /// section 1.6). `count` is snapshotted once up front (mirrors
    /// `emit_par_stmt`'s own `[start, end)` chunk, computed once before any
    /// worker starts): a `spawn` from inside the body grows `count` but
    /// won't be visited by this same scan, matching `par`/`swarm`'s existing
    /// "walks a fixed range" semantics rather than risking an unbounded loop
    /// from a body that spawns into the very arena it's scanning.
    ///
    /// `index_var`, when bound, gives the body the current slot's raw index
    /// as a plain `i32` local -- the missing piece that made `NOTES.md`
    /// section 2.1's "no way to conditionally reclaim arena slots during a
    /// scan" true: `despawn` was never actually banned inside `each` (only
    /// inside `par`/`swarm`), but without a bound index there was no
    /// expression to hand it. `despawn ArenaName[idx]` is an ordinary,
    /// sequential mutation of `@arena.{arena}.gen`/`.free`/`.free_top`, no
    /// different from any other statement in this loop body, so allowing it
    /// here needed no new disjointness proof -- just a name for the index.
    pub(super) fn emit_each_stmt(&mut self, var: &str, index_var: &Option<String>, elem_ty: &Ty, arena: &str, body: &TypedBlock) {
        let cap = self.arena_capacity(arena);
        let elem_llvm_ty = self.llvm_ty(elem_ty);
        let data_reg = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** @arena.{}.data", data_reg, elem_llvm_ty, elem_llvm_ty, arena));
        let count_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @arena.{}.count", count_reg, arena));

        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));

        // Same per-iteration frame-reclaim snapshot as `emit_for_stmt`/
        // `TypedStmt::While` (`NOTES.md` section 1.2) -- a `frame:` block
        // wrapping an `each` loop must reclaim each iteration's bump
        // allocations, not just the whole loop's at once.
        let loop_frame_off = if self.in_frame {
            let saved = self.tmp_name();
            self.line(&format!("  {} = load i64, i64* @frame.off", saved));
            Some(saved)
        } else {
            None
        };

        let cond_label = self.block_label("each_cond");
        let body_label = self.block_label("each_body");
        let live_label = self.block_label("each_live");
        let step_label = self.block_label("each_step");
        let end_label = self.block_label("each_end");

        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&cond_label);
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
        let cmp = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", cmp, i_reg, count_reg));
        self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, body_label, end_label));

        self.open_block(&body_label);
        // Skip despawned/never-spawned slots -- same generation-parity check
        // as `emit_par_stmt`'s worker body (see its own comment on why
        // `count` alone isn't a live count).
        let gen_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @arena.{}.gen, i64 0, i64 {}",
            gen_ptr, cap, cap, arena, i_reg
        ));
        let gen_val = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", gen_val, gen_ptr));
        let parity = self.tmp_name();
        self.line(&format!("  {} = and i64 {}, 1", parity, gen_val));
        let is_live = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, 1", is_live, parity));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_live, live_label, step_label));

        self.open_block(&live_label);
        let elem_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds {}, {}* {}, i64 {}",
            elem_ptr, elem_llvm_ty, elem_llvm_ty, data_reg, i_reg
        ));
        self.symbols.push((var.to_string(), elem_ptr, elem_ty.clone()));
        // `idx`: a plain `i32` local holding this iteration's raw slot index
        // -- truncated from the loop counter's `i64` (bounded by `cap`,
        // itself always well under `i32::MAX`, so no value is lost) and
        // stored into its own alloca like any other `let`-bound scalar, so
        // it reads/passes to `despawn ArenaName[idx]` exactly like a normal
        // local rather than needing special-cased codegen of its own.
        if let Some(idx_name) = index_var {
            let idx32 = self.tmp_name();
            self.line(&format!("  {} = trunc i64 {} to i32", idx32, i_reg));
            let idx_ptr = self.tmp_name();
            self.line(&format!("  {} = alloca i32", idx_ptr));
            self.line(&format!("  store i32 {}, i32* {}", idx32, idx_ptr));
            self.symbols.push((idx_name.clone(), idx_ptr, Ty::Int));
        }
        let depth_at_entry = self.owned_stack.len();
        self.push_scope();
        self.loop_stack.push((step_label.clone(), end_label.clone(), depth_at_entry, loop_frame_off.clone()));
        for stmt in &body.stmts {
            self.emit_stmt(stmt);
        }
        self.loop_stack.pop();
        if index_var.is_some() {
            self.symbols.pop();
        }
        self.symbols.pop();
        let body_terminates = Self::body_terminates(&body.stmts);
        self.pop_scope(!body_terminates);
        if !body_terminates {
            self.line(&format!("  br label %{}", step_label));
        }

        self.open_block(&step_label);
        if let Some(saved) = &loop_frame_off {
            self.line(&format!("  store i64 {}, i64* @frame.off", saved));
        }
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&end_label);
    }

    /// Emit `spawn ArenaName(args...)`. Arenas start out empty (`data` is
    /// `null`, `count` is `0` -- see `emit_arena_decl`), so the first spawn
    /// into a given arena lazily `malloc`s a fixed-capacity backing array;
    /// every spawn after that reuses it. A slot is claimed by first popping
    /// the arena's free-list (slots reclaimed by `despawn`); only when it's
    /// empty does spawn fall back to growing `count`, so spawn/despawn churn
    /// doesn't monotonically grow the arena -- the "logical leak" design.md
    /// calls out. The element is constructed (via the same codegen path as
    /// any other struct literal) directly into the claimed slot, and that
    /// slot's generation is bumped by one either way (never reset to a fixed
    /// value -- see `emit_arena_decl` on why that matters for reused slots).
    /// A spawn past this arena's own resolved capacity (see
    /// `TypedArenaDecl::capacity`, default `crate::types::DEFAULT_ARENA_CAPACITY`)
    /// live elements is silently dropped rather than writing out of bounds
    /// -- a fixed backing store never reallocs/moves, which matters because
    /// `par`/`swarm` workers may be reading it concurrently from other
    /// threads.
    pub(super) fn emit_spawn_stmt(&mut self, arena: &str, elem: &TypedExpr) {
        let cap = self.arena_capacity(arena);
        let elem_ty = self.expr_ty(elem);
        let elem_llvm_ty = self.llvm_ty(&elem_ty);

        let data_reg = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** @arena.{}.data", data_reg, elem_llvm_ty, elem_llvm_ty, arena));
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq {}* {}, null", is_null, elem_llvm_ty, data_reg));
        let init_label = self.block_label("spawn_init");
        let ready_label = self.block_label("spawn_ready");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, init_label, ready_label));

        self.open_block(&init_label);
        // Ask LLVM itself for `elem_llvm_ty`'s real (alignment-padded) size
        // rather than trusting a Rust-side estimate -- this buffer is later
        // indexed via `getelementptr` against `elem_llvm_ty` directly (see
        // `emit_genref_index`/`emit_despawn_stmt`), so its allocated size
        // must agree byte-for-byte with whatever stride LLVM's own GEP
        // arithmetic uses, or a struct type needing internal padding
        // (mixing a sub-8-byte field with an 8-or-16-byte-aligned one)
        // would silently overflow this `malloc`'d buffer once enough
        // elements are spawned.
        let elem_size = self.emit_sizeof_llvm_ty(&elem_llvm_ty);
        let bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", bytes, elem_size, cap));
        let raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", raw, bytes));
        let casted = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", casted, raw, elem_llvm_ty));
        self.line(&format!("  store {}* {}, {}** @arena.{}.data", elem_llvm_ty, casted, elem_llvm_ty, arena));
        self.line(&format!("  br label %{}", ready_label));

        self.open_block(&ready_label);
        let data_ready = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** @arena.{}.data", data_ready, elem_llvm_ty, elem_llvm_ty, arena));

        // Prefer reclaiming a despawned slot off the free-list over growing
        // `count`.
        let free_top_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @arena.{}.free_top", free_top_reg, arena));
        let has_free = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i64 {}, 0", has_free, free_top_reg));
        let reuse_label = self.block_label("spawn_reuse");
        let grow_label = self.block_label("spawn_grow");
        self.line(&format!("  br i1 {}, label %{}, label %{}", has_free, reuse_label, grow_label));

        self.open_block(&reuse_label);
        let new_free_top = self.tmp_name();
        self.line(&format!("  {} = sub i64 {}, 1", new_free_top, free_top_reg));
        self.line(&format!("  store i64 {}, i64* @arena.{}.free_top", new_free_top, arena));
        let free_slot_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @arena.{}.free, i64 0, i64 {}",
            free_slot_ptr, cap, cap, arena, new_free_top
        ));
        let reused_idx = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", reused_idx, free_slot_ptr));
        // A reused slot's previous RC-bearing contents were already released
        // by `emit_despawn_stmt` when this slot was freed (the only way a
        // slot ever reaches the free-list) -- releasing them *again* here
        // would be a double-release: the slot's raw bytes still hold that
        // same now-dangling pointer (despawn never zeroes the slot), so a
        // second `emit_release_at` would use-after-free/double-free the
        // exact same heap block instead of touching a fresh, valid value.
        let store_label = self.block_label("spawn_store");
        let end_label = self.block_label("spawn_end");
        self.line(&format!("  br label %{}", store_label));

        self.open_block(&grow_label);
        let count_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @arena.{}.count", count_reg, arena));
        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", in_bounds, count_reg, cap));
        let grow_ok_label = self.block_label("spawn_grow_ok");
        let capacity_warn_label = self.block_label("spawn_capacity_warn");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, grow_ok_label, capacity_warn_label));

        // Past-capacity spawns are still silently dropped (a fixed backing
        // store never reallocs/moves, which matters since `par`/`swarm`
        // workers may be reading it concurrently from other threads -- see
        // this function's own doc comment) but that silent data loss is now
        // at least loud: a warning identifying the offending arena (and its
        // actual, possibly-configured capacity, not one shared hardcoded
        // number) is printed the *first* time it happens. Only the first:
        // `@arena.{arena}.warned` latches after one print so a body that
        // keeps calling `spawn` into an already-full arena every tick (an
        // enemy spawner that never checks back, a burst effect outliving
        // its pool) doesn't flood the console with the same line forever --
        // the caller already got the signal it was missing before.
        self.open_block(&capacity_warn_label);
        let already_warned = self.tmp_name();
        self.line(&format!("  {} = load i1, i1* @arena.{}.warned", already_warned, arena));
        let warn_label = self.block_label("spawn_warn_print");
        self.line(&format!("  br i1 {}, label %{}, label %{}", already_warned, end_label, warn_label));

        self.open_block(&warn_label);
        self.line(&format!("  store i1 1, i1* @arena.{}.warned", arena));
        let msg = format!("star runtime warning: arena `{}` is full ({} live elements) -- spawn dropped (further overflows on this arena will not be reported)\n", arena, cap);
        let g = self.global_name();
        let escaped = msg.replace("\\", "\\\\").replace("\"", "\\22").replace("\n", "\\0A");
        self.global_defs.push(format!("{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"", g, msg.len() + 1, escaped));
        let msg_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", msg_ptr, msg.len() + 1, msg.len() + 1, g));
        self.line(&format!("  call i32 @puts(i8* {})", msg_ptr));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&grow_ok_label);
        let next_count = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", next_count, count_reg));
        self.line(&format!("  store i64 {}, i64* @arena.{}.count", next_count, arena));
        self.line(&format!("  br label %{}", store_label));

        self.open_block(&store_label);
        let slot_idx = self.tmp_name();
        self.line(&format!(
            "  {} = phi i64 [ {}, %{} ], [ {}, %{} ]",
            slot_idx, reused_idx, reuse_label, count_reg, grow_ok_label
        ));
        let val = self.emit_expr(elem);
        let clean_val = self.untag(&val, &elem_ty);
        let slot_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds {}, {}* {}, i64 {}",
            slot_ptr, elem_llvm_ty, elem_llvm_ty, data_ready, slot_idx
        ));
        self.line(&format!("  store {} {}, {}* {}", elem_llvm_ty, clean_val, elem_llvm_ty, slot_ptr));
        // Bump this slot's generation by one rather than resetting it to a
        // fixed value: a reused slot's generation was already advanced by
        // `emit_despawn_stmt`, and re-stamping a constant here would let a
        // stale `GenRef` captured before that despawn incorrectly match
        // again (the ABA problem design.md calls out).
        let gen_slot_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @arena.{}.gen, i64 0, i64 {}",
            gen_slot_ptr, cap, cap, arena, slot_idx
        ));
        let cur_gen = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", cur_gen, gen_slot_ptr));
        let next_gen = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", next_gen, cur_gen));
        self.line(&format!("  store i64 {}, i64* {}", next_gen, gen_slot_ptr));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
    }

    /// Emit `despawn ArenaName[index]`: if the slot is currently live (odd
    /// generation -- see `emit_arena_decl`), bumps its generation by 1
    /// (invalidating any `GenRef` created against the old value) and pushes
    /// the slot onto the arena's free-list so a later `spawn` can reclaim
    /// its memory instead of only ever growing `count`. An out-of-bounds
    /// `index`, or one that's already dead (never spawned, or already
    /// despawned), is a silent no-op -- this also guards against a
    /// double-despawn pushing the same slot onto the free-list twice, which
    /// would otherwise let two later spawns alias the same memory.
    pub(super) fn emit_despawn_stmt(&mut self, arena: &str, index: &TypedExpr) {
        let cap = self.arena_capacity(arena);
        let idx_val = self.emit_expr(index);
        let idx_bare = self.untag(&idx_val, &Ty::Int);
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, idx_bare));
        // Unsigned compare: a negative index sign-extends/wraps to a huge
        // unsigned value, so it safely fails this bounds check too instead
        // of aliasing a valid slot.
        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, cap));
        let do_label = self.block_label("despawn_do");
        let end_label = self.block_label("despawn_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, do_label, end_label));

        self.open_block(&do_label);
        let gen_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @arena.{}.gen, i64 0, i64 {}",
            gen_ptr, cap, cap, arena, idx64
        ));
        let gen_val = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", gen_val, gen_ptr));
        let parity = self.tmp_name();
        self.line(&format!("  {} = and i64 {}, 1", parity, gen_val));
        let is_live = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, 1", is_live, parity));
        let live_label = self.block_label("despawn_live");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_live, live_label, end_label));

        self.open_block(&live_label);
        // Releases the slot's own RC-bearing content (if any) now that it's
        // being marked dead -- otherwise a struct field/element spawned in
        // and later despawned without ever being overwritten by a later
        // respawn (the only other release point, in `emit_spawn_stmt`)
        // would leak for the rest of the process's lifetime.
        if let Some(elem_ty) = self.arena_by_elem.iter().find(|(_, n)| n == arena).map(|(t, _)| t.clone()) {
            if self.contains_rc(&elem_ty) {
                let elem_llvm_ty = self.llvm_ty(&elem_ty);
                let data_ptr = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** @arena.{}.data", data_ptr, elem_llvm_ty, elem_llvm_ty, arena));
                let slot_ptr = self.tmp_name();
                self.line(&format!(
                    "  {} = getelementptr inbounds {}, {}* {}, i64 {}",
                    slot_ptr, elem_llvm_ty, elem_llvm_ty, data_ptr, idx64
                ));
                self.emit_release_at(&slot_ptr, &elem_ty);
            }
        }
        let next_gen = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", next_gen, gen_val));
        self.line(&format!("  store i64 {}, i64* {}", next_gen, gen_ptr));
        let free_top_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @arena.{}.free_top", free_top_reg, arena));
        let free_slot_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @arena.{}.free, i64 0, i64 {}",
            free_slot_ptr, cap, cap, arena, free_top_reg
        ));
        self.line(&format!("  store i64 {}, i64* {}", idx64, free_slot_ptr));
        let next_free_top = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", next_free_top, free_top_reg));
        self.line(&format!("  store i64 {}, i64* @arena.{}.free_top", next_free_top, arena));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
    }

    /// `GenRef<T>(idx)`: creates a handle to slot `idx` of the arena
    /// backing `T`, capturing that slot's *live* generation right now
    /// (rather than hardcoding 0) so a later dereference can detect
    /// whether the slot has since been despawned/replaced. Known
    /// limitation: a never-spawned slot's live generation is also 0,
    /// so a GenRef created against one is indistinguishable from a
    /// freshly-valid reference -- orthogonal to the stale-after-
    /// despawn guarantee this implements; closing it is future work.
    pub(super) fn emit_genref_create(&mut self, inner_ty: &Ty, value: &TypedExpr, span: Span) -> String {
        let arena = self.arena_for_elem_ty(inner_ty, span);
        let cap = self.arena_capacity(&arena);
        let val = self.emit_expr(value);
        let idx_i32 = self.untag(&val, &Ty::Int);
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, idx_i32));

        // Bounds-check before reading the gen array: `idx` is an
        // arbitrary (possibly bug/attacker-controlled) expression,
        // not an internally-generated counter, so it can't be
        // trusted the way `spawn`'s `count` can.
        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, cap));
        let ok_label = self.block_label("genref_create_ok");
        let oob_label = self.block_label("genref_create_oob");
        let end_label = self.block_label("genref_create_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, ok_label, oob_label));

        self.open_block(&ok_label);
        let gen_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @arena.{}.gen, i64 0, i64 {}",
            gen_ptr, cap, cap, arena, idx64
        ));
        let gen_ok = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", gen_ok, gen_ptr));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&oob_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let gen_val = self.tmp_name();
        self.line(&format!(
            "  {} = phi i64 [ {}, %{} ], [ 0, %{} ]",
            gen_val, gen_ok, ok_label, oob_label
        ));

        let ptr = self.tmp_name();
        self.line(&format!("  {} = alloca %GenRef", ptr));
        let field0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds %GenRef, %GenRef* {}, i32 0, i32 0", field0, ptr));
        self.line(&format!("  store i32 {}, i32* {}", idx_i32, field0));
        let gen_field_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds %GenRef, %GenRef* {}, i32 0, i32 1", gen_field_ptr, ptr));
        self.line(&format!("  store i64 {}, i64* {}", gen_val, gen_field_ptr));
        let loaded = self.tmp_name();
        self.line(&format!("  {} = load %GenRef, %GenRef* {}", loaded, ptr));
        format!("%GenRef {}", loaded)
    }

    /// `genref[N]`: `N` is vestigial (kept for backward-compatible
    /// `expr[idx]` deref syntax) -- the real slot index lives in the
    /// GenRef's own stored `index` field from creation time. Validates
    /// bounds and the stored generation against the arena's *live*
    /// generation for that slot; a mismatch (or an out-of-bounds
    /// index) yields the element type's zero value instead of reading
    /// stale/garbage data.
    pub(super) fn emit_genref_index(&mut self, base: &TypedExpr, ty: &Ty, span: Span) -> String {
        let elem_ty = ty.clone();
        let elem_llvm_ty = self.llvm_ty(&elem_ty);
        let arena = self.arena_for_elem_ty(&elem_ty, span);
        let cap = self.arena_capacity(&arena);

        let base_ptr = self.emit_place(base);
        let idx_field_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds %GenRef, %GenRef* {}, i32 0, i32 0", idx_field_ptr, base_ptr));
        let stored_idx = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", stored_idx, idx_field_ptr));
        let gen_field_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds %GenRef, %GenRef* {}, i32 0, i32 1", gen_field_ptr, base_ptr));
        let stored_gen = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", stored_gen, gen_field_ptr));
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, stored_idx));

        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, cap));
        let check_label = self.block_label("genref_check");
        let ok_label = self.block_label("genref_ok");
        let stale_label = self.block_label("genref_stale");
        let end_label = self.block_label("genref_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, check_label, stale_label));

        self.open_block(&check_label);
        let gen_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @arena.{}.gen, i64 0, i64 {}",
            gen_ptr, cap, cap, arena, idx64
        ));
        let live_gen = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", live_gen, gen_ptr));
        let gen_match = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, {}", gen_match, stored_gen, live_gen));
        // A never-spawned slot's generation is `0` (see `emit_arena_decl`),
        // which is indistinguishable from a freshly-created `GenRef`'s own
        // captured generation for that same slot -- `gen_match` alone would
        // pass for both. Odd/even parity is what actually encodes liveness
        // (every `spawn`/`despawn` bumps by exactly 1), and a live slot is
        // only ever odd *after* `spawn` has both allocated the arena's
        // backing storage and written the element into it -- so requiring
        // the live generation to be odd here also guarantees `data` below is
        // non-null and the slot holds real, initialized data, closing the
        // segfault/uninitialized-read hole for a `GenRef` dereferenced
        // before anything was ever spawned into this arena.
        let parity = self.tmp_name();
        self.line(&format!("  {} = and i64 {}, 1", parity, live_gen));
        let is_live = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, 1", is_live, parity));
        let ok = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", ok, gen_match, is_live));
        self.line(&format!("  br i1 {}, label %{}, label %{}", ok, ok_label, stale_label));

        self.open_block(&ok_label);
        let data_ptr = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** @arena.{}.data", data_ptr, elem_llvm_ty, elem_llvm_ty, arena));
        let elem_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds {}, {}* {}, i64 {}",
            elem_ptr, elem_llvm_ty, elem_llvm_ty, data_ptr, idx64
        ));
        let elem_val = self.tmp_name();
        self.line(&format!("  {} = load {}, {}* {}", elem_val, elem_llvm_ty, elem_llvm_ty, elem_ptr));
        // Same reasoning as `Ident`/`Field`/`ListIndex` reads: this hands
        // out an independent copy while the arena slot keeps its own
        // reference (see `rc.rs`; a no-op unless `elem_ty` is RC-bearing).
        self.emit_retain_at(&elem_ptr, &elem_ty);
        self.line(&format!("  br label %{}", end_label));

        // Both failure paths (out-of-bounds, stale generation) funnel
        // through this one block so the `phi` below sees exactly two
        // incoming edges.
        self.open_block(&stale_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let zero = self.zero_value(&elem_ty);
        let result = self.tmp_name();
        self.line(&format!(
            "  {} = phi {} [ {}, %{} ], [ {}, %{} ]",
            result, elem_llvm_ty, elem_val, ok_label, zero, stale_label
        ));
        format!("{} {}", elem_llvm_ty, result)
    }

    /// Place resolution for a `gen_ref[N]` *base* of a further access --
    /// `gen_ref[0].field = v`, `gen_ref[0].push(x)` on a `List<T>` field,
    /// a mutating method call on `gen_ref[0]`, etc. Returns a real pointer
    /// into the arena's live slot, so a write through the returned pointer
    /// actually lands in the arena -- mirrors `emit_list_index_place`'s
    /// identical fix for the same root cause: `Codegen::emit_place` had no
    /// `GenRefIndex` arm, so any such chained access fell into its generic
    /// fallback (spill the *read* value into a throwaway alloca), silently
    /// discarding every write (`r[0].hp -= 10` compiled and ran with zero
    /// effect on the arena).
    ///
    /// A stale generation or out-of-bounds index yields a pointer to a
    /// fresh, zeroed, disconnected alloca -- same "safe no-op, well-defined
    /// zero value on read-back" convention as `emit_genref_index`'s own
    /// stale/OOB fallback and `emit_list_index_place`'s OOB fallback.
    pub(super) fn emit_genref_index_place(&mut self, base: &TypedExpr, ty: &Ty, span: Span) -> String {
        let elem_ty = ty.clone();
        let elem_llvm_ty = self.llvm_ty(&elem_ty);
        let arena = self.arena_for_elem_ty(&elem_ty, span);
        let cap = self.arena_capacity(&arena);

        let base_ptr = self.emit_place(base);
        let idx_field_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds %GenRef, %GenRef* {}, i32 0, i32 0", idx_field_ptr, base_ptr));
        let stored_idx = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", stored_idx, idx_field_ptr));
        let gen_field_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds %GenRef, %GenRef* {}, i32 0, i32 1", gen_field_ptr, base_ptr));
        let stored_gen = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", stored_gen, gen_field_ptr));
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, stored_idx));

        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, cap));
        let check_label = self.block_label("genref_place_check");
        let ok_label = self.block_label("genref_place_ok");
        let stale_label = self.block_label("genref_place_stale");
        let end_label = self.block_label("genref_place_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, check_label, stale_label));

        self.open_block(&check_label);
        let gen_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @arena.{}.gen, i64 0, i64 {}",
            gen_ptr, cap, cap, arena, idx64
        ));
        let live_gen = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", live_gen, gen_ptr));
        let gen_match = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, {}", gen_match, stored_gen, live_gen));
        let parity = self.tmp_name();
        self.line(&format!("  {} = and i64 {}, 1", parity, live_gen));
        let is_live = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, 1", is_live, parity));
        let ok = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", ok, gen_match, is_live));
        self.line(&format!("  br i1 {}, label %{}, label %{}", ok, ok_label, stale_label));

        self.open_block(&ok_label);
        let data_ptr = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** @arena.{}.data", data_ptr, elem_llvm_ty, elem_llvm_ty, arena));
        let elem_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds {}, {}* {}, i64 {}",
            elem_ptr, elem_llvm_ty, elem_llvm_ty, data_ptr, idx64
        ));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&stale_label);
        let dummy = self.tmp_name();
        self.line(&format!("  {} = alloca {}", dummy, elem_llvm_ty));
        let zero = self.zero_value(&elem_ty);
        self.line(&format!("  store {} {}, {}* {}", elem_llvm_ty, zero, elem_llvm_ty, dummy));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!(
            "  {} = phi {}* [ {}, %{} ], [ {}, %{} ]",
            result, elem_llvm_ty, elem_ptr, ok_label, dummy, stale_label
        ));
        result
    }

    /// Shared generation-check emission for a `GenRef<T>` used directly as a
    /// write target (whole-element `r[0] = v` or a field `r[0].f = v`) --
    /// duplicates `emit_genref_index_place`'s check/branch shape but, unlike
    /// that function, does *not* phi-merge the ok/stale paths into one
    /// pointer. A stale/OOB write must be a true no-op (matching every
    /// sibling collection's "out-of-bounds write is a silent no-op"
    /// contract -- see `store_list_index` etc.), which requires the RHS
    /// value (already owned/retained by the caller) to be *released* on
    /// that path rather than stored into a disconnected dummy and leaked.
    /// Leaves `ok_label` open with `elem_ptr` valid for the caller to GEP
    /// off of and finish (ending in `br label %{end_label}`); the caller
    /// must then `open_block(&stale_label)`, release `val`, jump to
    /// `end_label`, and finally `open_block(&end_label)` itself.
    fn open_genref_write_check(
        &mut self,
        base: &TypedExpr,
        elem_ty: &Ty,
        span: Span,
    ) -> (String, String, String, String) {
        let elem_llvm_ty = self.llvm_ty(elem_ty);
        let arena = self.arena_for_elem_ty(elem_ty, span);
        let cap = self.arena_capacity(&arena);

        let base_ptr = self.emit_place(base);
        let idx_field_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds %GenRef, %GenRef* {}, i32 0, i32 0", idx_field_ptr, base_ptr));
        let stored_idx = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", stored_idx, idx_field_ptr));
        let gen_field_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds %GenRef, %GenRef* {}, i32 0, i32 1", gen_field_ptr, base_ptr));
        let stored_gen = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", stored_gen, gen_field_ptr));
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, stored_idx));

        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, cap));
        let check_label = self.block_label("genref_wcheck");
        let ok_label = self.block_label("genref_wok");
        let stale_label = self.block_label("genref_wstale");
        let end_label = self.block_label("genref_wend");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, check_label, stale_label));

        self.open_block(&check_label);
        let gen_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @arena.{}.gen, i64 0, i64 {}",
            gen_ptr, cap, cap, arena, idx64
        ));
        let live_gen = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", live_gen, gen_ptr));
        let gen_match = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, {}", gen_match, stored_gen, live_gen));
        let parity = self.tmp_name();
        self.line(&format!("  {} = and i64 {}, 1", parity, live_gen));
        let is_live = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, 1", is_live, parity));
        let ok = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", ok, gen_match, is_live));
        self.line(&format!("  br i1 {}, label %{}, label %{}", ok, ok_label, stale_label));

        self.open_block(&ok_label);
        let data_ptr = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** @arena.{}.data", data_ptr, elem_llvm_ty, elem_llvm_ty, arena));
        let elem_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds {}, {}* {}, i64 {}",
            elem_ptr, elem_llvm_ty, elem_llvm_ty, data_ptr, idx64
        ));

        (elem_ptr, ok_label, stale_label, end_label)
    }

    /// Whole-element write through a `GenRef<T>` (`r[0] = value`). A stale
    /// handle or out-of-bounds index releases `val` and otherwise does
    /// nothing, matching every sibling indexed-collection's silent-no-op
    /// write contract instead of leaking `val`'s ownership (see
    /// `open_genref_write_check`'s doc comment).
    pub(super) fn store_genref_whole(&mut self, base: &TypedExpr, elem_ty: &Ty, val: &str, span: Span) {
        let (elem_ptr, _ok_label, stale_label, end_label) = self.open_genref_write_check(base, elem_ty, span);
        self.emit_release_at(&elem_ptr, elem_ty);
        let ts = self.llvm_ty(elem_ty);
        let clean_val = val.strip_prefix(&format!("{} ", ts)).unwrap_or(val);
        self.line(&format!("  store {} {}, {}* {}", ts, clean_val, ts, elem_ptr));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&stale_label);
        // `emit_release_bare` expects a *bare* (untagged) value -- reuse
        // `clean_val` (already untagged above), not `val` itself, which is
        // whatever `emit_expr` handed the caller and isn't consistently
        // tagged or bare across expression kinds (a struct-literal
        // construction like `Item(1)` is tagged; a call/load result isn't).
        // Releasing the tagged form directly would double-tag the `store`
        // this emits (`store %Item %Item %t9, ...`, which `clang` rejects).
        self.emit_release_bare(clean_val, elem_ty);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
    }

    /// Field write through a `GenRef<T>` (`r[0].field = value`). Same
    /// silent-no-op-on-stale contract as `store_genref_whole`, one field
    /// deep -- fixes the RC leak where `store_target`'s generic `Field` arm
    /// would GEP into `emit_genref_index_place`'s disconnected stale-path
    /// dummy and store (and thus permanently orphan) an already-owned `val`
    /// there.
    pub(super) fn store_genref_field(
        &mut self,
        base: &TypedExpr,
        elem_ty: &Ty,
        field: &str,
        field_ty: &Ty,
        val: &str,
        span: Span,
    ) {
        let idx = self.field_index(elem_ty, field);
        self.store_genref_field_index(base, elem_ty, idx, field_ty, val, span);
    }

    /// Tuple-index write through a `GenRef<T>` (`r[0].0 = value`, where `T`
    /// is a tuple type). Same fix, one numeric index deep, as
    /// `store_genref_field`.
    pub(super) fn store_genref_tuple_index(
        &mut self,
        base: &TypedExpr,
        elem_ty: &Ty,
        index: u32,
        field_ty: &Ty,
        val: &str,
        span: Span,
    ) {
        self.store_genref_field_index(base, elem_ty, index, field_ty, val, span);
    }

    fn store_genref_field_index(
        &mut self,
        base: &TypedExpr,
        elem_ty: &Ty,
        idx: u32,
        field_ty: &Ty,
        val: &str,
        span: Span,
    ) {
        let (elem_ptr, _ok_label, stale_label, end_label) = self.open_genref_write_check(base, elem_ty, span);
        let bty = self.llvm_ty(elem_ty);
        let gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, bty, bty, elem_ptr, idx));
        let ts = self.llvm_ty(field_ty);
        let clean_val = val.strip_prefix(&format!("{} ", ts)).unwrap_or(val);
        self.emit_release_at(&gep, field_ty);
        self.line(&format!("  store {} {}, {}* {}", ts, clean_val, ts, gep));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&stale_label);
        // Same reasoning as `store_genref_whole`'s identical fix: release
        // the already-untagged `clean_val`, not the possibly-tagged `val`.
        self.emit_release_bare(clean_val, field_ty);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
    }
}
