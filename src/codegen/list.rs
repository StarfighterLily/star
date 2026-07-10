//! `List<T>` codegen: a growable, heap-allocated dynamic array lowered to
//! `{ T* data, i64 len, i64 cap }` (see `Codegen::llvm_ty`'s `Ty::List` arm).
//!
//! Unlike an arena's fixed-capacity backing array (shared by every element
//! of a given type, capacity fixed at `Codegen::ARENA_CAPACITY`), each
//! `List<T>` *value* owns its own independently `malloc`'d buffer, grown by
//! doubling (`malloc` a bigger buffer, `memcpy` the old contents, `free` the
//! old buffer) whenever `push` finds `len == cap` -- an ordinary growable
//! vector, not a slot-map. Every out-of-bounds read/removal on an empty list
//! yields the element type's zero value rather than erroring at runtime,
//! mirroring `GenRef`'s "safe null equivalent" convention (see design.md);
//! an out-of-bounds *write* is a silent no-op, mirroring `despawn`'s
//! already-dead-slot handling in `crate::codegen::arena`.

use crate::types::*;

use super::Codegen;

impl Codegen {
    /// The anonymous LLVM struct type for `List<elem_ty>`. Always routed
    /// through `Codegen::llvm_ty` (rather than formatted ad-hoc here) so
    /// every call site agrees byte-for-byte on the type's textual spelling --
    /// callers elsewhere (e.g. `TypedStmt::Let`) strip this exact string as a
    /// prefix tag off an emitted value.
    fn list_llvm_ty(&self, elem_ty: &Ty) -> String {
        self.llvm_ty(&Ty::List(Box::new(elem_ty.clone())))
    }

    /// `List<T>()`: the empty list is just the zero value of its struct
    /// type (`null` data, `0` len, `0` cap) -- no instructions needed.
    pub(super) fn emit_list_new(&mut self, elem_ty: &Ty) -> String {
        format!("{} zeroinitializer", self.list_llvm_ty(elem_ty))
    }

    /// A non-empty list literal `[e1, e2, ...]`: `malloc` a tightly-sized
    /// buffer up front (`len == cap`, so the first `push` after this
    /// immediately grows it -- acceptable, this isn't a hot path) and store
    /// each element into it.
    pub(super) fn emit_list_lit(&mut self, elems: &[TypedExpr], elem_ty: &Ty) -> String {
        let elem_llvm = self.llvm_ty(elem_ty);
        let n = elems.len() as u64;
        let elem_size = self.type_size(elem_ty) as u64;
        let bytes = elem_size * n;

        let raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", raw, bytes));
        let data = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", data, raw, elem_llvm));
        for (i, e) in elems.iter().enumerate() {
            let val = self.emit_expr(e);
            let clean = self.untag(&val, elem_ty);
            let gep = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", gep, elem_llvm, elem_llvm, data, i));
            self.line(&format!("  store {} {}, {}* {}", elem_llvm, clean, elem_llvm, gep));
        }

        let list_ty = self.list_llvm_ty(elem_ty);
        let ptr = self.tmp_name();
        self.line(&format!("  {} = alloca {}", ptr, list_ty));
        let data_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", data_field, list_ty, list_ty, ptr));
        self.line(&format!("  store {}* {}, {}** {}", elem_llvm, data, elem_llvm, data_field));
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", len_field, list_ty, list_ty, ptr));
        self.line(&format!("  store i64 {}, i64* {}", n, len_field));
        let cap_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", cap_field, list_ty, list_ty, ptr));
        self.line(&format!("  store i64 {}, i64* {}", n, cap_field));

        let loaded = self.tmp_name();
        self.line(&format!("  {} = load {}, {}* {}", loaded, list_ty, list_ty, ptr));
        format!("{} {}", list_ty, loaded)
    }

    /// Load the `(data_ptr, data_ptr_field, len_reg, len_field, cap_field)`
    /// tuple off a list's storage, addressed via `emit_place(base)`. Shared
    /// by every list operation below (`emit_list_index`, `store_list_index`,
    /// `emit_list_method`), each of which needs some subset of these.
    fn list_fields(&mut self, base: &TypedExpr, elem_ty: &Ty) -> (String, String, String, String, String) {
        let elem_llvm = self.llvm_ty(elem_ty);
        let list_ty = self.list_llvm_ty(elem_ty);
        let base_ptr = self.emit_place(base);

        let data_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", data_field, list_ty, list_ty, base_ptr));
        let data = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", data, elem_llvm, elem_llvm, data_field));
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", len_field, list_ty, list_ty, base_ptr));
        let len = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len, len_field));
        let cap_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", cap_field, list_ty, list_ty, base_ptr));

        (data, data_field, len, len_field, cap_field)
    }

    /// `list[idx]`: bounds-checked element read, yielding the element
    /// type's zero value out of bounds instead of reading garbage/OOB
    /// memory (mirrors `emit_genref_index`'s stale/OOB fallback).
    pub(super) fn emit_list_index(&mut self, base: &TypedExpr, index: &TypedExpr, elem_ty: &Ty) -> String {
        let elem_llvm = self.llvm_ty(elem_ty);
        let (data, _, len, _, _) = self.list_fields(base, elem_ty);

        let idx_val = self.emit_expr(index);
        let idx_bare = self.untag(&idx_val, &Ty::Int);
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, idx_bare));

        // Unsigned compare: a negative index sign-extends/wraps to a huge
        // unsigned value, so it safely fails this bounds check too (mirrors
        // `emit_despawn_stmt`'s identical trick).
        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, len));
        let ok_label = self.block_label("list_idx_ok");
        let oob_label = self.block_label("list_idx_oob");
        let end_label = self.block_label("list_idx_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, ok_label, oob_label));

        self.line(&format!("{}:", ok_label));
        let elem_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, data, idx64));
        let elem_val = self.tmp_name();
        self.line(&format!("  {} = load {}, {}* {}", elem_val, elem_llvm, elem_llvm, elem_ptr));
        self.line(&format!("  br label %{}", end_label));

        self.line(&format!("{}:", oob_label));
        self.line(&format!("  br label %{}", end_label));

        self.line(&format!("{}:", end_label));
        let zero = self.zero_value(elem_ty);
        let result = self.tmp_name();
        self.line(&format!("  {} = phi {} [ {}, %{} ], [ {}, %{} ]", result, elem_llvm, elem_val, ok_label, zero, oob_label));
        format!("{} {}", elem_llvm, result)
    }

    /// `list[idx] = v`: bounds-checked element write; an out-of-bounds
    /// index is a silent no-op (mirrors `emit_despawn_stmt`'s dead-slot
    /// handling) rather than writing out of bounds.
    pub(super) fn store_list_index(&mut self, base: &TypedExpr, index: &TypedExpr, elem_ty: &Ty, val: &str) {
        let elem_llvm = self.llvm_ty(elem_ty);
        let (data, _, len, _, _) = self.list_fields(base, elem_ty);

        let idx_val = self.emit_expr(index);
        let idx_bare = self.untag(&idx_val, &Ty::Int);
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, idx_bare));

        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, len));
        let do_label = self.block_label("list_set_do");
        let end_label = self.block_label("list_set_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, do_label, end_label));

        self.line(&format!("{}:", do_label));
        let elem_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, data, idx64));
        let clean_val = self.untag(val, elem_ty);
        self.line(&format!("  store {} {}, {}* {}", elem_llvm, clean_val, elem_llvm, elem_ptr));
        self.line(&format!("  br label %{}", end_label));

        self.line(&format!("{}:", end_label));
    }

    /// `list.push(v)` / `list.pop()` / `list.len()`.
    pub(super) fn emit_list_method(&mut self, base: &TypedExpr, method: ListMethod, args: &[TypedExpr], elem_ty: &Ty) -> String {
        let elem_llvm = self.llvm_ty(elem_ty);
        let elem_size = self.type_size(elem_ty) as u64;
        let (_, data_field, len, len_field, cap_field) = self.list_fields(base, elem_ty);

        match method {
            ListMethod::Len => {
                let len32 = self.tmp_name();
                self.line(&format!("  {} = trunc i64 {} to i32", len32, len));
                format!("i32 {}", len32)
            }
            ListMethod::Push => {
                let val = self.emit_expr(&args[0]);
                let clean_val = self.untag(&val, elem_ty);

                let cap = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", cap, cap_field));
                let data = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", data, elem_llvm, elem_llvm, data_field));

                let needs_grow = self.tmp_name();
                self.line(&format!("  {} = icmp sge i64 {}, {}", needs_grow, len, cap));
                let grow_label = self.block_label("list_push_grow");
                let store_label = self.block_label("list_push_store");
                self.line(&format!("  br i1 {}, label %{}, label %{}", needs_grow, grow_label, store_label));

                self.line(&format!("{}:", grow_label));
                let doubled = self.tmp_name();
                self.line(&format!("  {} = mul i64 {}, 2", doubled, cap));
                let has_cap = self.tmp_name();
                self.line(&format!("  {} = icmp sgt i64 {}, 0", has_cap, doubled));
                let new_cap = self.tmp_name();
                self.line(&format!("  {} = select i1 {}, i64 {}, i64 1", new_cap, has_cap, doubled));
                let new_bytes = self.tmp_name();
                self.line(&format!("  {} = mul i64 {}, {}", new_bytes, new_cap, elem_size));
                let new_raw = self.tmp_name();
                self.line(&format!("  {} = call i8* @malloc(i64 {})", new_raw, new_bytes));
                let new_data = self.tmp_name();
                self.line(&format!("  {} = bitcast i8* {} to {}*", new_data, new_raw, elem_llvm));

                // Only copy/free the old buffer when one actually exists
                // (`cap == 0` means `data` is still the initial `null`);
                // `memcpy`/`free` on a null pointer is unnecessary and best
                // avoided even at zero length.
                let had_data = self.tmp_name();
                self.line(&format!("  {} = icmp sgt i64 {}, 0", had_data, cap));
                let copy_label = self.block_label("list_push_copy");
                let after_copy_label = self.block_label("list_push_after_copy");
                self.line(&format!("  br i1 {}, label %{}, label %{}", had_data, copy_label, after_copy_label));

                self.line(&format!("{}:", copy_label));
                let old_bytes = self.tmp_name();
                self.line(&format!("  {} = mul i64 {}, {}", old_bytes, len, elem_size));
                let old_raw = self.tmp_name();
                self.line(&format!("  {} = bitcast {}* {} to i8*", old_raw, elem_llvm, data));
                self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_raw, old_raw, old_bytes));
                self.line(&format!("  call void @free(i8* {})", old_raw));
                self.line(&format!("  br label %{}", after_copy_label));

                self.line(&format!("{}:", after_copy_label));
                self.line(&format!("  store {}* {}, {}** {}", elem_llvm, new_data, elem_llvm, data_field));
                self.line(&format!("  store i64 {}, i64* {}", new_cap, cap_field));
                self.line(&format!("  br label %{}", store_label));

                self.line(&format!("{}:", store_label));
                let data_now = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", data_now, elem_llvm, elem_llvm, data_field));
                let elem_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, data_now, len));
                self.line(&format!("  store {} {}, {}* {}", elem_llvm, clean_val, elem_llvm, elem_ptr));
                let new_len = self.tmp_name();
                self.line(&format!("  {} = add i64 {}, 1", new_len, len));
                self.line(&format!("  store i64 {}, i64* {}", new_len, len_field));
                "%undef".into()
            }
            ListMethod::Pop => {
                let is_empty = self.tmp_name();
                self.line(&format!("  {} = icmp eq i64 {}, 0", is_empty, len));
                let empty_label = self.block_label("list_pop_empty");
                let nonempty_label = self.block_label("list_pop_nonempty");
                let end_label = self.block_label("list_pop_end");
                self.line(&format!("  br i1 {}, label %{}, label %{}", is_empty, empty_label, nonempty_label));

                self.line(&format!("{}:", nonempty_label));
                let new_len = self.tmp_name();
                self.line(&format!("  {} = sub i64 {}, 1", new_len, len));
                self.line(&format!("  store i64 {}, i64* {}", new_len, len_field));
                let data = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", data, elem_llvm, elem_llvm, data_field));
                let elem_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, data, new_len));
                let popped = self.tmp_name();
                self.line(&format!("  {} = load {}, {}* {}", popped, elem_llvm, elem_llvm, elem_ptr));
                self.line(&format!("  br label %{}", end_label));

                self.line(&format!("{}:", empty_label));
                self.line(&format!("  br label %{}", end_label));

                self.line(&format!("{}:", end_label));
                let zero = self.zero_value(elem_ty);
                let result = self.tmp_name();
                self.line(&format!("  {} = phi {} [ {}, %{} ], [ {}, %{} ]", result, elem_llvm, popped, nonempty_label, zero, empty_label));
                format!("{} {}", elem_llvm, result)
            }
        }
    }
}
