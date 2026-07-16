//! `Ring<T, N>` codegen: a fixed-capacity ring buffer lowered to an inline
//! `{ data: [N x T], head: i64, len: i64 }` -- like `Ty::Array`, stored as
//! part of whatever binding owns it (no RC header, no heap allocation of its
//! own, no copy-on-write uniqueness gate), unlike `List<T>`'s heap-backed,
//! shared, copy-on-write buffer.
//!
//! `push(v)` appends at the back (physical slot `(head + len) mod N`) and
//! grows `len` while `len < N`; once `len == N`, it evicts the oldest (front)
//! element instead -- overwrite the slot at `head`, then advance `head` by
//! one, keeping `len == N` -- so a full ring always holds a sliding window of
//! the most recent `N` pushes rather than silently no-op'ing (`List`'s
//! out-of-bounds-write convention) or growing (impossible: there is nowhere
//! to grow to). `pop()` removes and returns the oldest (front) element
//! (physical slot `head`), mirroring a FIFO queue.
//!
//! Invariant this whole module leans on for RC safety: every physical slot
//! *outside* the live circular window `[head, head+len)` (mod `N`) is always
//! the element type's zero value. This holds inductively --
//! `Codegen::zero_value`'s `Ty::Ring` case starts every slot zero; `pop`
//! zeroes the slot it vacates (transferring ownership of the popped value to
//! the caller with no retain, exactly like `ListMethod::Pop`, relying on the
//! zeroed slot rather than a shrunk `len` to keep a later release walk from
//! double-releasing it); `push`'s growth branch only ever writes into the
//! slot immediately past the current live window, which by this same
//! invariant is guaranteed zero; and `push`'s eviction branch overwrites a
//! slot that's already live (releasing the old value first), never
//! introducing a new non-live slot. This is what lets
//! `Codegen::emit_rc_walk`'s `Ty::Ring` arm safely retain/release *all* `N`
//! slots unconditionally on every copy/scope-exit, regardless of `head`/
//! `len` -- releasing an already-zero slot is always a safe no-op.

use crate::types::{RingMethod, Ty, TypedExpr};

use super::Codegen;

impl Codegen {
    /// The anonymous LLVM struct type for `Ring<elem_ty, count>`'s inline
    /// storage -- always routed through this helper (rather than formatted
    /// ad-hoc) so every call site agrees byte-for-byte on the type's textual
    /// spelling, mirroring `Codegen::llvm_ty`'s own `Ty::Ring` arm (which
    /// this must stay textually identical to).
    fn ring_payload_llvm_ty(&self, elem_ty: &Ty, count: u64) -> String {
        format!("{{ [{} x {}], i64, i64 }}", count, self.llvm_ty(elem_ty))
    }

    /// `Ring<T, N>()`: the zero value -- an all-zero `[N x T]` plus
    /// `head = 0, len = 0` -- satisfies this module's "every non-live slot is
    /// zero" invariant trivially (the whole buffer is non-live), so no
    /// per-slot initialization loop is needed, unlike `emit_array_repeat`.
    pub(super) fn emit_ring_new(&mut self, elem_ty: &Ty, count: u64) -> String {
        let t = self.ring_payload_llvm_ty(elem_ty, count);
        format!("{} zeroinitializer", t)
    }

    /// Resolve `base`'s own storage pointer (via `emit_place`, the *write*
    /// path -- see this function's callers) and split it into `(data_ptr,
    /// head_ptr, head, len_ptr, len)`. No copy-on-write/uniqueness gate is
    /// needed here (unlike `crate::codegen::list::list_fields_mut`) -- a ring
    /// is never shared behind a pointer, so `base`'s own storage is always
    /// already uniquely owned by its binding.
    fn ring_fields_mut(&mut self, base: &TypedExpr, elem_ty: &Ty, count: u64) -> (String, String, String, String, String) {
        let ring_ty = self.ring_payload_llvm_ty(elem_ty, count);
        let base_ptr = self.emit_place(base);
        self.ring_field_ptrs(&base_ptr, &ring_ty)
    }

    /// Read-only counterpart to `ring_fields_mut`: resolves `base` via
    /// `emit_read_place` instead of `emit_place`, so a ring reached through a
    /// `list[idx]`-based chain (`points[0].history.len()`) doesn't trigger
    /// that list's copy-on-write clone-on-read bug for a pure read -- mirrors
    /// `crate::codegen::array`'s identical `_place`/`_read_place` split.
    fn ring_fields_read(&mut self, base: &TypedExpr, elem_ty: &Ty, count: u64) -> (String, String, String) {
        let ring_ty = self.ring_payload_llvm_ty(elem_ty, count);
        let base_ptr = self.emit_read_place(base);
        let (data_ptr, _, head, _, len) = self.ring_field_ptrs(&base_ptr, &ring_ty);
        (data_ptr, head, len)
    }

    /// Shared tail end of `ring_fields_mut`/`ring_fields_read`: GEP out the
    /// three fields of an already-resolved ring storage pointer.
    fn ring_field_ptrs(&mut self, base_ptr: &str, ring_ty: &str) -> (String, String, String, String, String) {
        let data_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", data_ptr, ring_ty, ring_ty, base_ptr));
        let head_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", head_ptr, ring_ty, ring_ty, base_ptr));
        let head = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", head, head_ptr));
        let len_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", len_ptr, ring_ty, ring_ty, base_ptr));
        let len = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len, len_ptr));
        (data_ptr, head_ptr, head, len_ptr, len)
    }

    /// Evaluates `index` to a bare, sign-extended `i64` register -- factored
    /// out of `ring_index_ptr` so callers can evaluate the index expression
    /// *before* (re-)reading `head`/`len`: the index expression can itself
    /// mutate this same ring via a nested `push`/`pop` (e.g. `ring[ring.pop()
    /// as i32]`), and `head`/`len` read beforehand would then be a stale
    /// snapshot -- same hazard class as `RingMethod::Push`'s fix below.
    fn ring_index_to_i64(&mut self, index: &TypedExpr) -> String {
        let idx_val = self.emit_expr(index);
        let idx_bare = self.untag(&idx_val, &Ty::Int);
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, idx_bare));
        idx64
    }

    /// Bounds-checked (against the dynamic `len`, not the static capacity
    /// `count`) pointer to the logical `index`-th live element (`0` =
    /// oldest), mapping it to its physical slot `(head + index) mod count`.
    /// Out of bounds yields a pointer to a fresh, zeroed, disconnected
    /// alloca, mirroring `crate::codegen::array::array_index_ptr`'s identical
    /// convention. `idx64` must already be evaluated (see
    /// `ring_index_to_i64`) and `head`/`len` must already reflect any
    /// mutation that evaluation performed.
    fn ring_index_ptr(&mut self, data_ptr: &str, head: &str, len: &str, idx64: &str, elem_ty: &Ty, count: u64, label_prefix: &str) -> String {
        let elem_llvm = self.llvm_ty(elem_ty);

        // Unsigned compare: a negative index sign-extends/wraps to a huge
        // unsigned value, so it safely fails this bounds check too (mirrors
        // `emit_list_index`'s identical trick).
        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, len));
        let ok_label = self.block_label(&format!("{}_ok", label_prefix));
        let oob_label = self.block_label(&format!("{}_oob", label_prefix));
        let end_label = self.block_label(&format!("{}_end", label_prefix));
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, ok_label, oob_label));

        self.open_block(&ok_label);
        let sum = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, {}", sum, head, idx64));
        let phys = self.tmp_name();
        self.line(&format!("  {} = urem i64 {}, {}", phys, sum, count));
        let arr_ty = format!("[{} x {}]", count, elem_llvm);
        let ok_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i64 {}", ok_ptr, arr_ty, arr_ty, data_ptr, phys));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&oob_label);
        let dummy = self.tmp_name();
        self.line(&format!("  {} = alloca {}", dummy, elem_llvm));
        let zero = self.zero_value(elem_ty);
        self.line(&format!("  store {} {}, {}* {}", elem_llvm, zero, elem_llvm, dummy));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!("  {} = phi {}* [ {}, %{} ], [ {}, %{} ]", result, elem_llvm, ok_ptr, ok_label, dummy, oob_label));
        result
    }

    /// Place resolution for a `ring[idx]` *base* of a further access
    /// (`ring[i].field = v`, a mutating method call on the element, ...), or
    /// the direct target of `ring[idx] = v` -- see `Codegen::store_target`.
    pub(super) fn emit_ring_index_place(&mut self, base: &TypedExpr, index: &TypedExpr, elem_ty: &Ty, count: u64) -> String {
        let (data_ptr, head_ptr, _, len_ptr, _) = self.ring_fields_mut(base, elem_ty, count);
        let idx64 = self.ring_index_to_i64(index);
        // Reload `head`/`len` *after* evaluating `index` -- see
        // `ring_index_ptr`'s doc comment for why the values `ring_fields_mut`
        // loaded above can already be stale by this point.
        let head = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", head, head_ptr));
        let len = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len, len_ptr));
        self.ring_index_ptr(&data_ptr, &head, &len, &idx64, elem_ty, count, "ring_place")
    }

    /// Read-only counterpart to `emit_ring_index_place`, for a `ring[idx]`
    /// base being read through (not written through) by a further access --
    /// used directly for `ring[idx]`'s own value read too (see
    /// `Codegen::emit_expr`'s `TypedExpr::RingIndex` arm, which loads through
    /// the pointer this returns, mirroring `TypedExpr::TupleIndex`'s codegen
    /// shape rather than duplicating a separate value-level phi the way
    /// `crate::codegen::array::emit_array_index` does).
    pub(super) fn emit_ring_index_read_place(&mut self, base: &TypedExpr, index: &TypedExpr, elem_ty: &Ty, count: u64) -> String {
        let ring_ty = self.ring_payload_llvm_ty(elem_ty, count);
        let base_ptr = self.emit_read_place(base);
        let (data_ptr, head_ptr, _, len_ptr, _) = self.ring_field_ptrs(&base_ptr, &ring_ty);
        let idx64 = self.ring_index_to_i64(index);
        // Reload `head`/`len` *after* evaluating `index` -- same hazard and
        // fix as `emit_ring_index_place`.
        let head = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", head, head_ptr));
        let len = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len, len_ptr));
        self.ring_index_ptr(&data_ptr, &head, &len, &idx64, elem_ty, count, "ring_rplace")
    }

    /// `ring[idx] = v`: bounds-checked (against `len`) element write; an
    /// out-of-bounds index is a silent no-op. Does not touch `head`/`len` --
    /// only `push`/`pop` do. Unlike `emit_ring_index_place` (shared with
    /// reads, whose out-of-bounds fallback is a disconnected dummy nothing
    /// else ever points at), this runs its own bounds-check branch so the
    /// out-of-bounds path can release `val` -- already computed and
    /// retained by the caller before calling this -- instead of leaking it
    /// into that dummy the way storing through `emit_ring_index_place`
    /// unconditionally did. Mirrors `store_array_index`'s identical
    /// `do`/`oob` branch shape.
    pub(super) fn store_ring_index(&mut self, base: &TypedExpr, index: &TypedExpr, elem_ty: &Ty, count: u64, val: &str) {
        let elem_llvm = self.llvm_ty(elem_ty);
        let (data_ptr, head_ptr, _, len_ptr, _) = self.ring_fields_mut(base, elem_ty, count);
        let idx64 = self.ring_index_to_i64(index);
        // Reload `head`/`len` *after* evaluating `index` -- see
        // `ring_index_ptr`'s doc comment for why the values `ring_fields_mut`
        // loaded above can already be stale by this point.
        let head = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", head, head_ptr));
        let len = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len, len_ptr));

        // Unsigned compare: a negative index sign-extends/wraps to a huge
        // unsigned value, so it safely fails this bounds check too (mirrors
        // `ring_index_ptr`'s identical trick).
        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, len));
        let do_label = self.block_label("ring_set_do");
        let oob_label = self.block_label("ring_set_oob");
        let end_label = self.block_label("ring_set_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, do_label, oob_label));

        self.open_block(&do_label);
        let sum = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, {}", sum, head, idx64));
        let phys = self.tmp_name();
        self.line(&format!("  {} = urem i64 {}, {}", phys, sum, count));
        let arr_ty = format!("[{} x {}]", count, elem_llvm);
        let ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i64 {}", ptr, arr_ty, arr_ty, data_ptr, phys));
        let clean_val = self.untag(val, elem_ty);
        // The overwritten slot is always live (bounds-checked against `len`)
        // -- release it *after* `val` was already computed (and retained, if
        // it's a copy), right before overwriting, keeping `ring[i] = ring[i]`
        // safe (same reasoning as `Codegen::store_target`'s `Ident`/`Field`
        // arms).
        self.emit_release_at(&ptr, elem_ty);
        self.line(&format!("  store {} {}, {}* {}", elem_llvm, clean_val, elem_llvm, ptr));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&oob_label);
        // `emit_release_bare` expects a *bare* (untagged) value, unlike
        // `val` itself (see `store_list_index`'s identical fix's doc
        // comment for why) -- reuse the `clean_val` the `do_label` branch
        // above already computed.
        self.emit_release_bare(&clean_val, elem_ty);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
    }

    /// `ring.push(v)` / `ring.pop()` / `ring.len()`.
    pub(super) fn emit_ring_method(&mut self, base: &TypedExpr, method: RingMethod, args: &[TypedExpr], elem_ty: &Ty, count: u64) -> String {
        let elem_llvm = self.llvm_ty(elem_ty);

        match method {
            RingMethod::Len => {
                let (_, _, len) = self.ring_fields_read(base, elem_ty, count);
                let len32 = self.tmp_name();
                self.line(&format!("  {} = trunc i64 {} to i32", len32, len));
                format!("i32 {}", len32)
            }
            RingMethod::Push => {
                let val = self.emit_expr(&args[0]);
                let clean_val = self.untag(&val, elem_ty);
                // Read `head`/`len` *after* evaluating `args[0]` -- if it
                // mutates this same ring (e.g. `ring.push(ring.pop())`), a
                // snapshot taken beforehand would be stale, causing the
                // is-full/grow/eviction logic below to corrupt the length
                // and the "every non-live slot is zero" invariant (mirrors
                // `MapMethod::Insert`'s identical fix).
                let (data_ptr, head_ptr, head, len_ptr, len) = self.ring_fields_mut(base, elem_ty, count);

                let arr_ty = format!("[{} x {}]", count, elem_llvm);
                let is_full = self.tmp_name();
                self.line(&format!("  {} = icmp sge i64 {}, {}", is_full, len, count));
                let full_label = self.block_label("ring_push_full");
                let grow_label = self.block_label("ring_push_grow");
                let done_label = self.block_label("ring_push_done");
                self.line(&format!("  br i1 {}, label %{}, label %{}", is_full, full_label, grow_label));

                // Not yet full: write into the slot immediately past the
                // current live window -- guaranteed zero by this module's
                // invariant, so no release is needed before overwriting it.
                self.open_block(&grow_label);
                let sum = self.tmp_name();
                self.line(&format!("  {} = add i64 {}, {}", sum, head, len));
                let grow_idx = self.tmp_name();
                self.line(&format!("  {} = urem i64 {}, {}", grow_idx, sum, count));
                let grow_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i64 {}", grow_ptr, arr_ty, arr_ty, data_ptr, grow_idx));
                self.line(&format!("  store {} {}, {}* {}", elem_llvm, clean_val, elem_llvm, grow_ptr));
                let new_len = self.tmp_name();
                self.line(&format!("  {} = add i64 {}, 1", new_len, len));
                self.line(&format!("  store i64 {}, i64* {}", new_len, len_ptr));
                self.line(&format!("  br label %{}", done_label));

                // Full: evict the oldest (front) element at `head`, then
                // advance `head` -- `len` stays `count`.
                self.open_block(&full_label);
                let full_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i64 {}", full_ptr, arr_ty, arr_ty, data_ptr, head));
                self.emit_release_at(&full_ptr, elem_ty);
                self.line(&format!("  store {} {}, {}* {}", elem_llvm, clean_val, elem_llvm, full_ptr));
                let head_plus_1 = self.tmp_name();
                self.line(&format!("  {} = add i64 {}, 1", head_plus_1, head));
                let new_head = self.tmp_name();
                self.line(&format!("  {} = urem i64 {}, {}", new_head, head_plus_1, count));
                self.line(&format!("  store i64 {}, i64* {}", new_head, head_ptr));
                self.line(&format!("  br label %{}", done_label));

                self.open_block(&done_label);
                "%undef".into()
            }
            RingMethod::Pop => {
                let (data_ptr, head_ptr, head, len_ptr, len) = self.ring_fields_mut(base, elem_ty, count);

                let is_empty = self.tmp_name();
                self.line(&format!("  {} = icmp eq i64 {}, 0", is_empty, len));
                let empty_label = self.block_label("ring_pop_empty");
                let nonempty_label = self.block_label("ring_pop_nonempty");
                let end_label = self.block_label("ring_pop_end");
                self.line(&format!("  br i1 {}, label %{}, label %{}", is_empty, empty_label, nonempty_label));

                self.open_block(&nonempty_label);
                let arr_ty = format!("[{} x {}]", count, elem_llvm);
                let elem_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i64 {}", elem_ptr, arr_ty, arr_ty, data_ptr, head));
                let popped = self.tmp_name();
                self.line(&format!("  {} = load {}, {}* {}", popped, elem_llvm, elem_llvm, elem_ptr));
                // Ownership of `popped` transfers to the caller with no
                // retain (mirrors `ListMethod::Pop`) -- zero the vacated slot
                // (rather than relying on a shrunk cursor the way `List`'s
                // heap release thunk does) so this module's "every non-live
                // slot is zero" invariant holds for the blanket
                // `Codegen::emit_rc_walk` walk over all `count` slots.
                let zero = self.zero_value(elem_ty);
                self.line(&format!("  store {} {}, {}* {}", elem_llvm, zero, elem_llvm, elem_ptr));
                let head_plus_1 = self.tmp_name();
                self.line(&format!("  {} = add i64 {}, 1", head_plus_1, head));
                let new_head = self.tmp_name();
                self.line(&format!("  {} = urem i64 {}, {}", new_head, head_plus_1, count));
                self.line(&format!("  store i64 {}, i64* {}", new_head, head_ptr));
                let new_len = self.tmp_name();
                self.line(&format!("  {} = sub i64 {}, 1", new_len, len));
                self.line(&format!("  store i64 {}, i64* {}", new_len, len_ptr));
                self.line(&format!("  br label %{}", end_label));

                self.open_block(&empty_label);
                self.line(&format!("  br label %{}", end_label));

                self.open_block(&end_label);
                let zero_result = self.zero_value(elem_ty);
                let result = self.tmp_name();
                self.line(&format!("  {} = phi {} [ {}, %{} ], [ {}, %{} ]", result, elem_llvm, popped, nonempty_label, zero_result, empty_label));
                format!("{} {}", elem_llvm, result)
            }
        }
    }
}
