//! `List<T>` codegen: a growable, heap-allocated dynamic array lowered to a
//! reference-counted, copy-on-write `i8*` object pointer -- the same
//! allocation scheme `Ty::Str` uses (`Codegen::llvm_ty`'s `Ty::List` arm),
//! pointing past a `star_rc_alloc` header at a `{ T* data, i64 len, i64 cap }`
//! payload.
//!
//! `let b = a` is an O(1) refcount bump (both bindings share the same
//! object), but every *mutating* operation (`push`, `pop`, index-assignment)
//! first calls `Codegen::emit_list_ensure_unique`, which clones the buffer if
//! it isn't the sole owner -- so mutating through one alias is never visible
//! through another, even though non-mutating copies are free. Growth still
//! doubles (`malloc` a bigger buffer, `memcpy` the old contents, `free` the
//! old buffer) whenever `push` finds `len == cap`, same as before, but now
//! safely: copy-on-write has already guaranteed the buffer being grown has
//! exactly one owner. Every out-of-bounds read/removal on an empty list
//! yields the element type's zero value rather than erroring at runtime,
//! mirroring `GenRef`'s "safe null equivalent" convention (see design.md);
//! an out-of-bounds *write* is a silent no-op, mirroring `despawn`'s
//! already-dead-slot handling in `crate::codegen::arena`.

use crate::types::*;

use super::Codegen;

impl Codegen {
    /// The anonymous LLVM struct type for `List<elem_ty>`'s heap *payload*
    /// (as opposed to `Codegen::llvm_ty`'s `i8*` object-pointer type) --
    /// what a `List<T>` object pointer points at, past its `star_rc_alloc`
    /// header. Always routed through this helper (rather than formatted
    /// ad-hoc) so every call site agrees byte-for-byte on the type's
    /// textual spelling.
    fn list_payload_llvm_ty(&self, elem_ty: &Ty) -> String {
        format!("{{ {}*, i64, i64 }}", self.llvm_ty(elem_ty))
    }

    /// Lazily generate (and cache, keyed by `Codegen::mangle_ty`) the
    /// `list_release_<mangled_elem>` thunk for `elem_ty`, returning the
    /// bitcast-to-`i8*` operand to pass as `star_rc_alloc`'s `release_fn`
    /// argument. Every `List<elem_ty>` allocation site (a list literal,
    /// `push`'s grow, a copy-on-write clone) shares one thunk instead of
    /// each emitting a duplicate `define` -- mirrors the per-closure
    /// `closure_N_release_env` thunk in `crate::codegen::closure`, except
    /// keyed by element type rather than by call-site id, since many list
    /// allocations of the same element type are expected.
    ///
    /// Unlike a closure's `release_fn` (`null` when no captured field needs
    /// releasing), a list's release thunk is never `null`: it always owns a
    /// separately `malloc`'d `data` buffer that must be `free`d once the
    /// object's last reference goes away, regardless of whether `elem_ty`
    /// itself carries any RC content.
    fn list_release_thunk_operand(&mut self, elem_ty: &Ty) -> String {
        let key = self.mangle_ty(elem_ty);
        if let Some(name) = self.list_release_thunks.get(&key).cloned() {
            let reg = self.tmp_name();
            self.line(&format!("  {} = bitcast void (i8*)* @{} to i8*", reg, name));
            return reg;
        }

        let name = format!("list_release_{}", key);
        self.list_release_thunks.insert(key, name.clone());

        let elem_llvm = self.llvm_ty(elem_ty);
        let payload_ty = self.list_payload_llvm_ty(elem_ty);
        let elem_has_rc = self.contains_rc(elem_ty);

        let saved_ir = std::mem::take(&mut self.ir);
        self.line(&format!("define void @{}(i8* %objp) {{", name));
        self.line("entry:");
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* %objp to {}*", payload, payload_ty));
        let data_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", data_field, payload_ty, payload_ty, payload));
        let data = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", data, elem_llvm, elem_llvm, data_field));

        if elem_has_rc {
            let len_field = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", len_field, payload_ty, payload_ty, payload));
            let len = self.tmp_name();
            self.line(&format!("  {} = load i64, i64* {}", len, len_field));

            let i_ptr = self.tmp_name();
            self.line(&format!("  {} = alloca i64", i_ptr));
            self.line(&format!("  store i64 0, i64* {}", i_ptr));

            let cond_label = self.block_label("list_release_cond");
            let body_label = self.block_label("list_release_body");
            let end_label = self.block_label("list_release_end");
            self.line(&format!("  br label %{}", cond_label));
            self.line(&format!("{}:", cond_label));
            let i_reg = self.tmp_name();
            self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
            let cmp = self.tmp_name();
            self.line(&format!("  {} = icmp slt i64 {}, {}", cmp, i_reg, len));
            self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, body_label, end_label));

            self.line(&format!("{}:", body_label));
            let elem_ptr = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, data, i_reg));
            self.emit_release_at(&elem_ptr, elem_ty);
            let i_next = self.tmp_name();
            self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
            self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
            self.line(&format!("  br label %{}", cond_label));

            self.line(&format!("{}:", end_label));
        }

        let data_i8 = self.tmp_name();
        self.line(&format!("  {} = bitcast {}* {} to i8*", data_i8, elem_llvm, data));
        self.line(&format!("  call void @free(i8* {})", data_i8));
        self.line("  ret void");
        self.line("}");
        self.line("");
        let fn_ir = std::mem::replace(&mut self.ir, saved_ir);
        self.pending_top.push(fn_ir);

        let reg = self.tmp_name();
        self.line(&format!("  {} = bitcast void (i8*)* @{} to i8*", reg, name));
        reg
    }

    /// `List<T>()`: the empty list is `null` -- no allocation up front (a
    /// real, uniquely-owned empty object is lazily allocated the first time
    /// `emit_list_ensure_unique` sees it, i.e. on first mutation), mirroring
    /// how a `Str` value's "nothing yet" state is also `null`.
    pub(super) fn emit_list_new(&mut self, _elem_ty: &Ty) -> String {
        "i8* null".into()
    }

    /// A non-empty list literal `[e1, e2, ...]`: `malloc` a tightly-sized
    /// buffer up front (`len == cap`, so the first `push` after this
    /// immediately grows it -- acceptable, this isn't a hot path), then
    /// allocate a fresh, uniquely-owned (refcount 1) RC object around it.
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

        let payload_ty = self.list_payload_llvm_ty(elem_ty);
        let release_fn = self.list_release_thunk_operand(elem_ty);
        let obj_raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 24, i8* {})", obj_raw, release_fn));
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload, obj_raw, payload_ty));
        let data_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", data_field, payload_ty, payload_ty, payload));
        self.line(&format!("  store {}* {}, {}** {}", elem_llvm, data, elem_llvm, data_field));
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", len_field, payload_ty, payload_ty, payload));
        self.line(&format!("  store i64 {}, i64* {}", n, len_field));
        let cap_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", cap_field, payload_ty, payload_ty, payload));
        self.line(&format!("  store i64 {}, i64* {}", n, cap_field));

        format!("i8* {}", obj_raw)
    }

    /// Copy-on-write gate for every *mutating* list operation (`push`,
    /// `pop`, index-assignment). `slot_ptr` is the address of the
    /// variable's own storage (an `i8**`, from `emit_place`) holding a
    /// `List<elem_ty>` object pointer. After this call, the object pointer
    /// stored at `slot_ptr` (which callers must reload) is guaranteed
    /// uniquely owned -- safe to mutate its `data` buffer or `len`/`cap`
    /// fields in place without that mutation becoming visible through any
    /// other alias.
    fn emit_list_ensure_unique(&mut self, slot_ptr: &str, elem_ty: &Ty) {
        let elem_llvm = self.llvm_ty(elem_ty);
        let elem_size = self.type_size(elem_ty) as u64;
        let payload_ty = self.list_payload_llvm_ty(elem_ty);

        let obj = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", obj, slot_ptr));
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, obj));
        let alloc_label = self.block_label("list_cow_alloc");
        let check_label = self.block_label("list_cow_check");
        let done_label = self.block_label("list_cow_done");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, alloc_label, check_label));

        // Never-allocated list (the zero value): allocate a fresh, empty,
        // uniquely-owned object rather than treating `null` as a special
        // "shared empty" sentinel.
        self.line(&format!("{}:", alloc_label));
        let release_fn0 = self.list_release_thunk_operand(elem_ty);
        let raw0 = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 24, i8* {})", raw0, release_fn0));
        let payload0 = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload0, raw0, payload_ty));
        let d0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", d0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store {}* null, {}** {}", elem_llvm, elem_llvm, d0));
        let l0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", l0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store i64 0, i64* {}", l0));
        let c0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", c0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store i64 0, i64* {}", c0));
        self.line(&format!("  store i8* {}, i8** {}", raw0, slot_ptr));
        self.line(&format!("  br label %{}", done_label));

        // Already allocated: peek the refcount (same header offset math
        // `star_rc_retain`/`star_rc_release` use, inlined here since it's
        // only needed for this uniqueness check) to decide unique vs.
        // shared.
        self.line(&format!("{}:", check_label));
        let hdr_i8 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 -16", hdr_i8, obj));
        let hdr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i64*", hdr, hdr_i8));
        let rc = self.tmp_name();
        self.line(&format!("  {} = load atomic i64, i64* {} seq_cst, align 8", rc, hdr));
        let is_unique = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, 1", is_unique, rc));
        let clone_label = self.block_label("list_cow_clone");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_unique, done_label, clone_label));

        // Shared: clone into a fresh object before this operation is
        // allowed to mutate anything.
        self.line(&format!("{}:", clone_label));
        let old_payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", old_payload, obj, payload_ty));
        let od_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", od_field, payload_ty, payload_ty, old_payload));
        let od = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", od, elem_llvm, elem_llvm, od_field));
        let ol_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", ol_field, payload_ty, payload_ty, old_payload));
        let ol = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", ol, ol_field));
        let oc_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", oc_field, payload_ty, payload_ty, old_payload));
        let oc = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", oc, oc_field));

        let release_fn1 = self.list_release_thunk_operand(elem_ty);
        let new_raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 24, i8* {})", new_raw, release_fn1));
        let new_payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", new_payload, new_raw, payload_ty));

        let new_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", new_bytes, oc, elem_size));
        let new_raw_data = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", new_raw_data, new_bytes));
        let new_data = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", new_data, new_raw_data, elem_llvm));

        // Only copy/retain when there's actually a live prefix (`cap` may
        // exceed `len`, and either may be zero on a list that was never
        // pushed onto after a prior pop-to-empty).
        let has_len = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i64 {}, 0", has_len, ol));
        let copy_label = self.block_label("list_cow_copy");
        let after_copy_label = self.block_label("list_cow_after_copy");
        self.line(&format!("  br i1 {}, label %{}, label %{}", has_len, copy_label, after_copy_label));

        self.line(&format!("{}:", copy_label));
        let old_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", old_bytes, ol, elem_size));
        let old_raw_data = self.tmp_name();
        self.line(&format!("  {} = bitcast {}* {} to i8*", old_raw_data, elem_llvm, od));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_raw_data, old_raw_data, old_bytes));
        if self.contains_rc(elem_ty) {
            // The clone now holds an additional reference to every shared
            // sub-object its elements point at -- retain each one, same
            // shape as the release thunk's element loop above.
            let i_ptr = self.tmp_name();
            self.line(&format!("  {} = alloca i64", i_ptr));
            self.line(&format!("  store i64 0, i64* {}", i_ptr));
            let cond_label = self.block_label("list_cow_retain_cond");
            let body_label = self.block_label("list_cow_retain_body");
            let retain_end_label = self.block_label("list_cow_retain_end");
            self.line(&format!("  br label %{}", cond_label));
            self.line(&format!("{}:", cond_label));
            let i_reg = self.tmp_name();
            self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
            let cmp = self.tmp_name();
            self.line(&format!("  {} = icmp slt i64 {}, {}", cmp, i_reg, ol));
            self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, body_label, retain_end_label));
            self.line(&format!("{}:", body_label));
            let elem_ptr = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, new_data, i_reg));
            self.emit_retain_at(&elem_ptr, elem_ty);
            let i_next = self.tmp_name();
            self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
            self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
            self.line(&format!("  br label %{}", cond_label));
            self.line(&format!("{}:", retain_end_label));
        }
        self.line(&format!("  br label %{}", after_copy_label));

        self.line(&format!("{}:", after_copy_label));
        let nd_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", nd_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store {}* {}, {}** {}", elem_llvm, new_data, elem_llvm, nd_field));
        let nl_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", nl_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store i64 {}, i64* {}", ol, nl_field));
        let nc_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", nc_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store i64 {}, i64* {}", oc, nc_field));

        // Drop this binding's reference to the old (still-shared-by-others)
        // object; safe to route through the ordinary release call rather
        // than hand-rolling the decrement, since we already know it won't
        // hit zero here (refcount was > 1).
        self.line(&format!("  call void @star_rc_release(i8* {})", obj));
        self.line(&format!("  store i8* {}, i8** {}", new_raw, slot_ptr));
        self.line(&format!("  br label %{}", done_label));

        self.line(&format!("{}:", done_label));
    }

    /// Read path: resolve `base`'s `(data, len)`, with no copy-on-write
    /// check (reading never needs to unshare a buffer) and no crash on the
    /// zero value -- `null` (a list that was constructed but never
    /// mutated) reads as `data = null, len = 0` rather than dereferencing
    /// through a null object pointer.
    fn list_fields(&mut self, base: &TypedExpr, elem_ty: &Ty) -> (String, String) {
        let elem_llvm = self.llvm_ty(elem_ty);
        let payload_ty = self.list_payload_llvm_ty(elem_ty);
        let slot_ptr = self.emit_place(base);

        let obj = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", obj, slot_ptr));
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, obj));
        let null_label = self.block_label("list_read_null");
        let real_label = self.block_label("list_read_real");
        let end_label = self.block_label("list_read_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, null_label, real_label));

        self.line(&format!("{}:", null_label));
        self.line(&format!("  br label %{}", end_label));

        self.line(&format!("{}:", real_label));
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload, obj, payload_ty));
        let data_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", data_field, payload_ty, payload_ty, payload));
        let data_real = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", data_real, elem_llvm, elem_llvm, data_field));
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", len_field, payload_ty, payload_ty, payload));
        let len_real = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len_real, len_field));
        self.line(&format!("  br label %{}", end_label));

        self.line(&format!("{}:", end_label));
        let data = self.tmp_name();
        self.line(&format!("  {} = phi {}* [ null, %{} ], [ {}, %{} ]", data, elem_llvm, null_label, data_real, real_label));
        let len = self.tmp_name();
        self.line(&format!("  {} = phi i64 [ 0, %{} ], [ {}, %{} ]", len, null_label, len_real, real_label));

        (data, len)
    }

    /// Mutating path: ensure `base`'s object is uniquely owned (allocating
    /// or cloning it as needed) via `emit_list_ensure_unique`, which
    /// guarantees a real, non-null object by the time this returns -- so,
    /// unlike `list_fields`, no null guard is needed here.
    fn list_fields_mut(&mut self, base: &TypedExpr, elem_ty: &Ty) -> (String, String, String, String, String) {
        let elem_llvm = self.llvm_ty(elem_ty);
        let payload_ty = self.list_payload_llvm_ty(elem_ty);
        let slot_ptr = self.emit_place(base);
        self.emit_list_ensure_unique(&slot_ptr, elem_ty);

        let obj = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", obj, slot_ptr));
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload, obj, payload_ty));

        let data_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", data_field, payload_ty, payload_ty, payload));
        let data = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", data, elem_llvm, elem_llvm, data_field));
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", len_field, payload_ty, payload_ty, payload));
        let len = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len, len_field));
        let cap_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", cap_field, payload_ty, payload_ty, payload));

        (data, data_field, len, len_field, cap_field)
    }

    /// `list[idx]`: bounds-checked element read, yielding the element
    /// type's zero value out of bounds instead of reading garbage/OOB
    /// memory (mirrors `emit_genref_index`'s stale/OOB fallback).
    pub(super) fn emit_list_index(&mut self, base: &TypedExpr, index: &TypedExpr, elem_ty: &Ty) -> String {
        let elem_llvm = self.llvm_ty(elem_ty);
        let (data, len) = self.list_fields(base, elem_ty);

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
        // Reading an element hands out an independent copy while the list
        // keeps its own reference -- retain (see `rc.rs`; a no-op unless
        // `elem_ty` is RC-bearing). The out-of-bounds branch below produces
        // a zero value with no real backing allocation, so there's nothing
        // to retain there.
        self.emit_retain_at(&elem_ptr, elem_ty);
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
    /// handling) rather than writing out of bounds. Mutates, so this goes
    /// through the copy-on-write gate first.
    pub(super) fn store_list_index(&mut self, base: &TypedExpr, index: &TypedExpr, elem_ty: &Ty, val: &str) {
        let elem_llvm = self.llvm_ty(elem_ty);
        let (data, _, len, _, _) = self.list_fields_mut(base, elem_ty);

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
        // `val` was already computed (and retained, if it's a copy) by the
        // caller before calling this; release the old element *after* that,
        // right before overwriting it -- keeps `list[i] = list[i]` safe, same
        // reasoning as `Codegen::store_target`'s `Ident`/`Field` arms.
        self.emit_release_at(&elem_ptr, elem_ty);
        self.line(&format!("  store {} {}, {}* {}", elem_llvm, clean_val, elem_llvm, elem_ptr));
        self.line(&format!("  br label %{}", end_label));

        self.line(&format!("{}:", end_label));
    }

    /// `list.push(v)` / `list.pop()` / `list.len()`.
    pub(super) fn emit_list_method(&mut self, base: &TypedExpr, method: ListMethod, args: &[TypedExpr], elem_ty: &Ty) -> String {
        let elem_llvm = self.llvm_ty(elem_ty);
        let elem_size = self.type_size(elem_ty) as u64;

        match method {
            ListMethod::Len => {
                let (_, len) = self.list_fields(base, elem_ty);
                let len32 = self.tmp_name();
                self.line(&format!("  {} = trunc i64 {} to i32", len32, len));
                format!("i32 {}", len32)
            }
            ListMethod::Push => {
                let (_, data_field, len, len_field, cap_field) = self.list_fields_mut(base, elem_ty);

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
                // avoided even at zero length. Safe to unconditionally
                // `free` the old buffer here (unlike a bit-copied alias
                // scenario) since `list_fields_mut` already guaranteed this
                // object -- and therefore this buffer -- has exactly one
                // owner.
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
                let (_, data_field, len, len_field, _) = self.list_fields_mut(base, elem_ty);

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
