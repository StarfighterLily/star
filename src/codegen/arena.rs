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
        self.line(&format!("@arena.{}.gen = global [{} x i32] zeroinitializer", a.name, Self::ARENA_CAPACITY));
        // Free-list stack of despawned slot indices, so `spawn` can reclaim a
        // slot's memory instead of only ever growing `count` -- this is the
        // "internal free-list to manage fragmentation" design.md promises.
        // See `emit_despawn_stmt` (push) and `emit_spawn_stmt` (pop).
        self.line(&format!("@arena.{}.free = global [{} x i64] zeroinitializer", a.name, Self::ARENA_CAPACITY));
        self.line(&format!("@arena.{}.free_top = global i64 0", a.name));
        self.line("");
        self.arena_by_elem.push((a.ty.clone(), a.name.clone()));
    }

    /// Resolve the arena backing `GenRef<ty>`. The checker has already
    /// proven exactly one exists (`Checker::require_backing_arena`); this is
    /// a defensive fallback only, matching the codebase's existing
    /// defensive-error convention (e.g. `emit_float_op`).
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

        self.line(&format!("define i32 @{}(i8* %argp) {{", worker_name));
        self.line("entry:");
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
        let end_label = self.block_label("par_end");
        self.line(&format!("  br label %{}", cond_label));
        self.line(&format!("{}:", cond_label));
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
        let cmp = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", cmp, i_reg, end_reg));
        self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, body_label, end_label));
        self.line(&format!("{}:", body_label));
        let elem_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds {}, {}* {}, i64 {}",
            elem_ptr, elem_llvm_ty, elem_llvm_ty, data_reg, i_reg
        ));
        self.symbols.push((var.to_string(), elem_ptr, elem_ty.clone()));
        for stmt in &body.stmts {
            self.emit_stmt(stmt);
        }
        self.symbols.pop();
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));
        self.line(&format!("{}:", end_label));
        self.line("  ret i32 0");
        self.line("}");
        self.line("");

        let worker_ir = std::mem::replace(&mut self.ir, saved_ir);
        self.pending_top.push(worker_ir);
        self.symbols = saved_symbols;
        self.in_frame = saved_in_frame;
        self.in_main = saved_in_main;

        // --- back in the caller: hand off to the persistent worker pool ---
        self.emit_par_dispatch(&worker_name, &args_ty, &captured, arena);
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
    /// A spawn past `ARENA_CAPACITY` live elements is silently dropped rather
    /// than writing out of bounds -- a fixed backing store never
    /// reallocs/moves, which matters because `par`/`swarm` workers may be
    /// reading it concurrently from other threads.
    pub(super) fn emit_spawn_stmt(&mut self, arena: &str, elem: &TypedExpr) {
        let elem_ty = self.expr_ty(elem);
        let elem_llvm_ty = self.llvm_ty(&elem_ty);

        let data_reg = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** @arena.{}.data", data_reg, elem_llvm_ty, elem_llvm_ty, arena));
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq {}* {}, null", is_null, elem_llvm_ty, data_reg));
        let init_label = self.block_label("spawn_init");
        let ready_label = self.block_label("spawn_ready");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, init_label, ready_label));

        self.line(&format!("{}:", init_label));
        let bytes = self.type_size(&elem_ty) as u64 * Self::ARENA_CAPACITY;
        let raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", raw, bytes));
        let casted = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", casted, raw, elem_llvm_ty));
        self.line(&format!("  store {}* {}, {}** @arena.{}.data", elem_llvm_ty, casted, elem_llvm_ty, arena));
        self.line(&format!("  br label %{}", ready_label));

        self.line(&format!("{}:", ready_label));
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

        self.line(&format!("{}:", reuse_label));
        let new_free_top = self.tmp_name();
        self.line(&format!("  {} = sub i64 {}, 1", new_free_top, free_top_reg));
        self.line(&format!("  store i64 {}, i64* @arena.{}.free_top", new_free_top, arena));
        let free_slot_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @arena.{}.free, i64 0, i64 {}",
            free_slot_ptr, Self::ARENA_CAPACITY, Self::ARENA_CAPACITY, arena, new_free_top
        ));
        let reused_idx = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", reused_idx, free_slot_ptr));
        if self.contains_rc(&elem_ty) {
            // A reused slot's previous contents are a validly-constructed
            // element from before its `despawn` (unlike a brand-new slot
            // from the `grow` path below, whose backing memory is
            // uninitialized `malloc` garbage, never safe to walk) --
            // release them before this spawn overwrites the slot, or any
            // RC-bearing field they held would leak forever.
            let old_slot_ptr = self.tmp_name();
            self.line(&format!(
                "  {} = getelementptr inbounds {}, {}* {}, i64 {}",
                old_slot_ptr, elem_llvm_ty, elem_llvm_ty, data_ready, reused_idx
            ));
            self.emit_release_at(&old_slot_ptr, &elem_ty);
        }
        let store_label = self.block_label("spawn_store");
        let end_label = self.block_label("spawn_end");
        self.line(&format!("  br label %{}", store_label));

        self.line(&format!("{}:", grow_label));
        let count_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @arena.{}.count", count_reg, arena));
        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", in_bounds, count_reg, Self::ARENA_CAPACITY));
        let grow_ok_label = self.block_label("spawn_grow_ok");
        let capacity_warn_label = self.block_label("spawn_capacity_warn");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, grow_ok_label, capacity_warn_label));

        // Past-capacity spawns are still silently dropped (a fixed backing
        // store never reallocs/moves, which matters since `par`/`swarm`
        // workers may be reading it concurrently from other threads -- see
        // this function's own doc comment) but that silent data loss is now
        // at least loud: a warning identifying the offending arena is
        // printed every time it happens, rather than the caller having no
        // signal at all that a `spawn` it believes succeeded never happened.
        self.line(&format!("{}:", capacity_warn_label));
        let msg = format!("star runtime warning: arena `{}` is full ({} live elements) -- spawn dropped\n", arena, Self::ARENA_CAPACITY);
        let g = self.global_name();
        let escaped = msg.replace("\\", "\\\\").replace("\"", "\\22").replace("\n", "\\0A");
        self.global_defs.push(format!("{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"", g, msg.len() + 1, escaped));
        let msg_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", msg_ptr, msg.len() + 1, msg.len() + 1, g));
        self.line(&format!("  call i32 @puts(i8* {})", msg_ptr));
        self.line(&format!("  br label %{}", end_label));

        self.line(&format!("{}:", grow_ok_label));
        let next_count = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", next_count, count_reg));
        self.line(&format!("  store i64 {}, i64* @arena.{}.count", next_count, arena));
        self.line(&format!("  br label %{}", store_label));

        self.line(&format!("{}:", store_label));
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
            "  {} = getelementptr inbounds [{} x i32], [{} x i32]* @arena.{}.gen, i64 0, i64 {}",
            gen_slot_ptr, Self::ARENA_CAPACITY, Self::ARENA_CAPACITY, arena, slot_idx
        ));
        let cur_gen = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", cur_gen, gen_slot_ptr));
        let next_gen = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", next_gen, cur_gen));
        self.line(&format!("  store i32 {}, i32* {}", next_gen, gen_slot_ptr));
        self.line(&format!("  br label %{}", end_label));

        self.line(&format!("{}:", end_label));
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
        let idx_val = self.emit_expr(index);
        let idx_bare = self.untag(&idx_val, &Ty::Int);
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, idx_bare));
        // Unsigned compare: a negative index sign-extends/wraps to a huge
        // unsigned value, so it safely fails this bounds check too instead
        // of aliasing a valid slot.
        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, Self::ARENA_CAPACITY));
        let do_label = self.block_label("despawn_do");
        let end_label = self.block_label("despawn_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, do_label, end_label));

        self.line(&format!("{}:", do_label));
        let gen_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i32], [{} x i32]* @arena.{}.gen, i64 0, i64 {}",
            gen_ptr, Self::ARENA_CAPACITY, Self::ARENA_CAPACITY, arena, idx64
        ));
        let gen_val = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", gen_val, gen_ptr));
        let parity = self.tmp_name();
        self.line(&format!("  {} = and i32 {}, 1", parity, gen_val));
        let is_live = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 1", is_live, parity));
        let live_label = self.block_label("despawn_live");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_live, live_label, end_label));

        self.line(&format!("{}:", live_label));
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
        self.line(&format!("  {} = add i32 {}, 1", next_gen, gen_val));
        self.line(&format!("  store i32 {}, i32* {}", next_gen, gen_ptr));
        let free_top_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @arena.{}.free_top", free_top_reg, arena));
        let free_slot_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @arena.{}.free, i64 0, i64 {}",
            free_slot_ptr, Self::ARENA_CAPACITY, Self::ARENA_CAPACITY, arena, free_top_reg
        ));
        self.line(&format!("  store i64 {}, i64* {}", idx64, free_slot_ptr));
        let next_free_top = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", next_free_top, free_top_reg));
        self.line(&format!("  store i64 {}, i64* @arena.{}.free_top", next_free_top, arena));
        self.line(&format!("  br label %{}", end_label));

        self.line(&format!("{}:", end_label));
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
        let val = self.emit_expr(value);
        let idx_i32 = self.untag(&val, &Ty::Int);
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, idx_i32));

        // Bounds-check before reading the gen array: `idx` is an
        // arbitrary (possibly bug/attacker-controlled) expression,
        // not an internally-generated counter, so it can't be
        // trusted the way `spawn`'s `count` can.
        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, Self::ARENA_CAPACITY));
        let ok_label = self.block_label("genref_create_ok");
        let oob_label = self.block_label("genref_create_oob");
        let end_label = self.block_label("genref_create_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, ok_label, oob_label));

        self.line(&format!("{}:", ok_label));
        let gen_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i32], [{} x i32]* @arena.{}.gen, i64 0, i64 {}",
            gen_ptr, Self::ARENA_CAPACITY, Self::ARENA_CAPACITY, arena, idx64
        ));
        let gen_ok = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", gen_ok, gen_ptr));
        self.line(&format!("  br label %{}", end_label));

        self.line(&format!("{}:", oob_label));
        self.line(&format!("  br label %{}", end_label));

        self.line(&format!("{}:", end_label));
        let gen_val = self.tmp_name();
        self.line(&format!(
            "  {} = phi i32 [ {}, %{} ], [ 0, %{} ]",
            gen_val, gen_ok, ok_label, oob_label
        ));

        let ptr = self.tmp_name();
        self.line(&format!("  {} = alloca %GenRef", ptr));
        let field0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds %GenRef, %GenRef* {}, i32 0, i32 0", field0, ptr));
        self.line(&format!("  store i32 {}, i32* {}", idx_i32, field0));
        let gen_field_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds %GenRef, %GenRef* {}, i32 0, i32 1", gen_field_ptr, ptr));
        self.line(&format!("  store i32 {}, i32* {}", gen_val, gen_field_ptr));
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

        let base_ptr = self.emit_place(base);
        let idx_field_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds %GenRef, %GenRef* {}, i32 0, i32 0", idx_field_ptr, base_ptr));
        let stored_idx = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", stored_idx, idx_field_ptr));
        let gen_field_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds %GenRef, %GenRef* {}, i32 0, i32 1", gen_field_ptr, base_ptr));
        let stored_gen = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", stored_gen, gen_field_ptr));
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, stored_idx));

        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, Self::ARENA_CAPACITY));
        let check_label = self.block_label("genref_check");
        let ok_label = self.block_label("genref_ok");
        let stale_label = self.block_label("genref_stale");
        let end_label = self.block_label("genref_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, check_label, stale_label));

        self.line(&format!("{}:", check_label));
        let gen_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i32], [{} x i32]* @arena.{}.gen, i64 0, i64 {}",
            gen_ptr, Self::ARENA_CAPACITY, Self::ARENA_CAPACITY, arena, idx64
        ));
        let live_gen = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", live_gen, gen_ptr));
        let gen_match = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, {}", gen_match, stored_gen, live_gen));
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
        self.line(&format!("  {} = and i32 {}, 1", parity, live_gen));
        let is_live = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 1", is_live, parity));
        let ok = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", ok, gen_match, is_live));
        self.line(&format!("  br i1 {}, label %{}, label %{}", ok, ok_label, stale_label));

        self.line(&format!("{}:", ok_label));
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
        self.line(&format!("{}:", stale_label));
        self.line(&format!("  br label %{}", end_label));

        self.line(&format!("{}:", end_label));
        let zero = self.zero_value(&elem_ty);
        let result = self.tmp_name();
        self.line(&format!(
            "  {} = phi {} [ {}, %{} ], [ {}, %{} ]",
            result, elem_llvm_ty, elem_val, ok_label, zero, stale_label
        ));
        format!("{} {}", elem_llvm_ty, result)
    }
}
