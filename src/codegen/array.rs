//! Fixed-size array (`[T; N]`) codegen: the `[value; N]` repeat literal,
//! indexing, and `.len()` (resolved entirely by the checker as a compile-time
//! constant -- see `Checker::infer_array_method` -- so there's no codegen
//! for it at all).
//!
//! Unlike `List<T>`, an array has no separate heap allocation and no
//! copy-on-write uniqueness gate: it's stored inline as part of whatever
//! binding owns it, exactly like `Ty::Tuple`. Its "place" is just a GEP into
//! that same storage, gated by a runtime bounds check against its
//! compile-time-known length `N` (mirroring `List<T>`'s own out-of-bounds
//! convention: a zero-value fallback on read, a silent no-op on write).

use crate::types::{Ty, TypedExpr};

use super::Codegen;

impl Codegen {
    /// `[value; N]`: evaluate `value` once and copy its bytes into every
    /// slot (mirrors Rust's own `[expr; N]` evaluating `expr` exactly once).
    /// The first slot's store is a plain move of the original evaluation's
    /// own ownership; every additional slot needs its own retain, since one
    /// owned value became `N` independent owners (a no-op unless `elem_ty`
    /// is RC-bearing). Mirrors `TupleLit`'s codegen shape (an anonymous,
    /// no-`%name` aggregate built via alloca+GEP+store, then loaded back out
    /// as a value) against `[N x T]` instead of `{ T0, T1, ... }`.
    pub(super) fn emit_array_repeat(&mut self, value: &TypedExpr, count: u64, elem_ty: &Ty) -> String {
        let elem_llvm = self.llvm_ty(elem_ty);
        let arr_ty = format!("[{} x {}]", count, elem_llvm);
        let ptr = self.tmp_name();
        self.line(&format!("  {} = alloca {}", ptr, arr_ty));
        let val = self.emit_expr(value);
        let clean_val = self.untag(&val, elem_ty);
        for i in 0..count {
            let gep = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i64 {}", gep, arr_ty, arr_ty, ptr, i));
            self.line(&format!("  store {} {}, {}* {}", elem_llvm, clean_val, elem_llvm, gep));
            if i > 0 {
                self.emit_retain_at(&gep, elem_ty);
            }
        }
        let loaded = self.tmp_name();
        self.line(&format!("  {} = load {}, {}* {}", loaded, arr_ty, arr_ty, ptr));
        format!("{} {}", arr_ty, loaded)
    }

    /// Bounds-checked pointer to `base_ptr`'s element at `index`: a real GEP
    /// into the array's own storage when in bounds, or a fresh, zeroed,
    /// disconnected alloca when not (so a read through it sees a well-defined
    /// zero value, and a write through it is an observable no-op -- nothing
    /// else ever points at that dummy slot). Shared by every other function
    /// in this module so the read/write/place paths can never drift apart on
    /// bounds-check or out-of-bounds behavior.
    fn array_index_ptr(&mut self, base_ptr: &str, index: &TypedExpr, elem_ty: &Ty, count: u64, label_prefix: &str) -> String {
        let elem_llvm = self.llvm_ty(elem_ty);
        let arr_ty = format!("[{} x {}]", count, elem_llvm);

        let idx_val = self.emit_expr(index);
        let idx_bare = self.untag(&idx_val, &Ty::Int);
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, idx_bare));

        // Unsigned compare: a negative index sign-extends/wraps to a huge
        // unsigned value, so it safely fails this bounds check too (mirrors
        // `emit_list_index`'s identical trick).
        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, count));
        let ok_label = self.block_label(&format!("{}_ok", label_prefix));
        let oob_label = self.block_label(&format!("{}_oob", label_prefix));
        let end_label = self.block_label(&format!("{}_end", label_prefix));
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, ok_label, oob_label));

        self.open_block(&ok_label);
        let ok_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i64 {}", ok_ptr, arr_ty, arr_ty, base_ptr, idx64));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&oob_label);
        let dummy = self.tmp_name();
        self.line(&format!("  {} = alloca {}", dummy, elem_llvm));
        // `zero_value_rc`, not `zero_value` -- see `crate::codegen::list`'s
        // `emit_list_index_place`'s identical fix's doc comment: a bare
        // `zero_value(&Ty::Str)` null disguised as `str` segfaults the
        // moment a chained access off this dummy slot (e.g.
        // `arr[oob].some_str_method()`, or simply `len(arr[oob])` for an
        // `[str; N]`) reads through it. Confirmed via a real segfault
        // building and running `let a: [str; 3] = ["x"; 3]; len(a[99])`
        // before this fix.
        let zero = self.zero_value_rc(elem_ty);
        self.line(&format!("  store {} {}, {}* {}", elem_llvm, zero, elem_llvm, dummy));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!("  {} = phi {}* [ {}, %{} ], [ {}, %{} ]", result, elem_llvm, ok_ptr, ok_label, dummy, oob_label));
        result
    }

    /// Place resolution for an `arr[idx]` *base* of a further access
    /// (`arr[i].field = v`, nested indexing, a mutating method call on the
    /// element, ...).
    pub(super) fn emit_array_index_place(&mut self, base: &TypedExpr, index: &TypedExpr, elem_ty: &Ty, count: u64) -> String {
        let base_ptr = self.emit_place(base);
        self.array_index_ptr(&base_ptr, index, elem_ty, count, "arr_place")
    }

    /// Read-only counterpart to `emit_array_index_place`, mirroring
    /// `emit_list_index_read_place`: routes `base` through `emit_read_place`
    /// instead of `emit_place`, so a `list[i]`-based array doesn't trigger
    /// that list's copy-on-write clone-on-read bug for a pure read.
    pub(super) fn emit_array_index_read_place(&mut self, base: &TypedExpr, index: &TypedExpr, elem_ty: &Ty, count: u64) -> String {
        let base_ptr = self.emit_read_place(base);
        self.array_index_ptr(&base_ptr, index, elem_ty, count, "arr_rplace")
    }

    /// `arr[idx]`: bounds-checked element read, yielding the element type's
    /// zero value out of bounds instead of reading past the array (mirrors
    /// `emit_list_index`'s identical convention).
    pub(super) fn emit_array_index(&mut self, base: &TypedExpr, index: &TypedExpr, elem_ty: &Ty, count: u64) -> String {
        let ptr = self.emit_array_index_read_place(base, index, elem_ty, count);
        let elem_llvm = self.llvm_ty(elem_ty);
        let reg = self.tmp_name();
        self.line(&format!("  {} = load {}, {}* {}", reg, elem_llvm, elem_llvm, ptr));
        // Reading an element hands out an independent copy while the array
        // keeps its own (see `rc.rs`; a no-op unless `elem_ty` is
        // RC-bearing). The out-of-bounds fallback has no real backing
        // allocation, but retaining its zero-valued dummy slot is still a
        // safe no-op (a non-RC zero value, or the RC runtime's own null/no-op
        // convention -- see `rc.rs`'s module doc comment) -- so retain
        // unconditionally, regardless of whether `base` is real, persistent
        // storage or a freshly spilled temporary (`make_array()[0]`):
        // `Codegen::emit_place`'s generic fallback now tracks and releases
        // every such temporary exactly once at scope end (see that
        // fallback's doc comment), which balances this retain and also fixes
        // the leak of every *other* RC-bearing field of a multi-field
        // struct/tuple temporary this array might itself be nested inside.
        self.emit_retain_at(&ptr, elem_ty);
        format!("{} {}", elem_llvm, reg)
    }

    /// `arr[idx] = v`: bounds-checked element write; an out-of-bounds index
    /// is a silent no-op. Unlike `emit_array_index_place` (shared with
    /// reads, whose out-of-bounds fallback is a disconnected dummy nothing
    /// else ever points at), this runs its own bounds-check branch so the
    /// out-of-bounds path can release `val` -- already computed and
    /// retained by the caller before calling this -- instead of leaking it
    /// into that dummy the way storing through `emit_array_index_place`
    /// unconditionally did. Mirrors `store_list_index`'s identical
    /// `do`/`oob` branch shape.
    pub(super) fn store_array_index(&mut self, base: &TypedExpr, index: &TypedExpr, elem_ty: &Ty, count: u64, val: &str) {
        let elem_llvm = self.llvm_ty(elem_ty);
        let arr_ty = format!("[{} x {}]", count, elem_llvm);
        let base_ptr = self.emit_place(base);

        let idx_val = self.emit_expr(index);
        let idx_bare = self.untag(&idx_val, &Ty::Int);
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, idx_bare));

        // Unsigned compare: a negative index sign-extends/wraps to a huge
        // unsigned value, so it safely fails this bounds check too (mirrors
        // `array_index_ptr`'s identical trick).
        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, count));
        let do_label = self.block_label("arr_set_do");
        let oob_label = self.block_label("arr_set_oob");
        let end_label = self.block_label("arr_set_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, do_label, oob_label));

        self.open_block(&do_label);
        let ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i64 {}", ptr, arr_ty, arr_ty, base_ptr, idx64));
        let clean_val = self.untag(val, elem_ty);
        // Same reasoning as `Codegen::store_target`'s `Ident`/`Field` arms:
        // release the old element *after* `val` was already computed (and
        // retained, if it's a copy), right before overwriting it.
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
}
