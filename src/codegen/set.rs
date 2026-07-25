//! `Set<T>` codegen: a growable set lowered to a reference-counted,
//! copy-on-write `i8*` object pointer, same allocation scheme as `List<T>`
//! (see `crate::codegen::list`'s doc comment for the RC/CoW/growth scheme
//! this reuses), pointing past a `star_rc_alloc` header at a
//! `{ T* data, i8* states, i64 len, i64 cap, i64 tomb }` payload.
//!
//! Unlike the original linear-scan implementation, `data`/`states` are an
//! **open-addressing hash table**: `cap` (always a power of two) slots,
//! `states[i]` one of `HT_EMPTY`(0)/`HT_OCCUPIED`(1)/`HT_TOMBSTONE`(2)
//! (`crate::codegen::hashtable`), `data[i]` meaningful only when
//! `states[i] == HT_OCCUPIED`. `insert`/`remove`/`contains` hash the operand
//! (`crate::codegen::hash`) to pick a start slot, then linear-probe
//! (`Codegen::emit_ht_probe`) to either the matching entry or the first
//! non-`OCCUPIED` slot -- average `O(1)` instead of the previous `O(n)`
//! linear scan, at the standard open-addressing tradeoff of needing tombstones
//! (a removed slot can't just become `EMPTY` again, or a probe chain that
//! walked through it for a *different*, still-present key would wrongly stop
//! short) and periodic regrowth to bound the tombstone-plus-live load factor.
//!
//! `remove` no longer swap-removes: a tombstone marks the slot dead in place,
//! so element order was never meaningful here anyway (`docs/language_reference.md`
//! already documents "remaining element order is not preserved" from the old
//! swap-remove behavior, which still holds -- just via a different mechanism).

use crate::types::*;

use super::Codegen;

impl Codegen {
    fn set_payload_llvm_ty(&self, elem_ty: &Ty) -> String {
        format!("{{ {}*, i8*, i64, i64, i64 }}", self.llvm_ty(elem_ty))
    }

    /// Mirrors `Codegen::list_release_thunk_operand`; see its doc comment.
    /// Unlike the old linear-buffer version, this walks the full `cap`-length
    /// `states` array (not just `0..len`) releasing every `OCCUPIED` slot's
    /// element -- `len` alone no longer identifies which slots are live.
    fn set_release_thunk_operand(&mut self, elem_ty: &Ty) -> String {
        let key = self.mangle_ty(elem_ty);
        if let Some(name) = self.set_release_thunks.get(&key).cloned() {
            let reg = self.tmp_name();
            self.line(&format!("  {} = bitcast void (i8*)* @{} to i8*", reg, name));
            return reg;
        }

        let name = format!("set_release_{}", key);
        self.set_release_thunks.insert(key, name.clone());

        let elem_llvm = self.llvm_ty(elem_ty);
        let payload_ty = self.set_payload_llvm_ty(elem_ty);
        let elem_has_rc = self.contains_rc(elem_ty);

        let saved_ir = std::mem::take(&mut self.ir);
        self.line(&format!("define void @{}(i8* %objp) {{", name));
        self.open_block("entry");
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* %objp to {}*", payload, payload_ty));
        let data_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", data_field, payload_ty, payload_ty, payload));
        let data = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", data, elem_llvm, elem_llvm, data_field));
        let states_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", states_field, payload_ty, payload_ty, payload));
        let states = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", states, states_field));
        let cap_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 3", cap_field, payload_ty, payload_ty, payload));
        let cap = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", cap, cap_field));

        if elem_has_rc {
            let i_ptr = self.tmp_name();
            self.line(&format!("  {} = alloca i64", i_ptr));
            self.line(&format!("  store i64 0, i64* {}", i_ptr));

            let cond_label = self.block_label("set_release_cond");
            let body_label = self.block_label("set_release_body");
            let occ_label = self.block_label("set_release_occ");
            let next_label = self.block_label("set_release_next");
            let end_label = self.block_label("set_release_end");
            self.line(&format!("  br label %{}", cond_label));
            self.open_block(&cond_label);
            let i_reg = self.tmp_name();
            self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
            let cmp = self.tmp_name();
            self.line(&format!("  {} = icmp slt i64 {}, {}", cmp, i_reg, cap));
            self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, body_label, end_label));

            self.open_block(&body_label);
            let st_ptr = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", st_ptr, states, i_reg));
            let st = self.tmp_name();
            self.line(&format!("  {} = load i8, i8* {}", st, st_ptr));
            let is_occ = self.tmp_name();
            self.line(&format!("  {} = icmp eq i8 {}, 1", is_occ, st));
            self.line(&format!("  br i1 {}, label %{}, label %{}", is_occ, occ_label, next_label));

            self.open_block(&occ_label);
            let elem_ptr = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, data, i_reg));
            self.emit_release_at(&elem_ptr, elem_ty);
            self.line(&format!("  br label %{}", next_label));

            self.open_block(&next_label);
            let i_next = self.tmp_name();
            self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
            self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
            self.line(&format!("  br label %{}", cond_label));

            self.open_block(&end_label);
        }

        let data_i8 = self.tmp_name();
        self.line(&format!("  {} = bitcast {}* {} to i8*", data_i8, elem_llvm, data));
        self.line(&format!("  call void @free(i8* {})", data_i8));
        self.line(&format!("  call void @free(i8* {})", states));
        self.line("  ret void");
        self.line("}");
        self.line("");
        let fn_ir = std::mem::replace(&mut self.ir, saved_ir);
        self.pending_top.push(Self::hoist_allocas_to_entry(&fn_ir));

        let reg = self.tmp_name();
        self.line(&format!("  {} = bitcast void (i8*)* @{} to i8*", reg, name));
        reg
    }

    /// `Set<T>()`: the empty set is `null`, mirroring `List<T>()`.
    pub(super) fn emit_set_new(&mut self, _elem_ty: &Ty) -> String {
        "i8* null".into()
    }

    /// Copy-on-write gate for every mutating set operation. Mirrors
    /// `Codegen::emit_list_ensure_unique`'s alloc/check/clone three-way
    /// branch shape, just cloning the `states` array alongside `data` (same
    /// `cap`, same slot positions -- a CoW clone is a structural copy, not a
    /// rehash, so no probing is needed here at all) and gating each retain
    /// on `states[i] == OCCUPIED` instead of blindly retaining every index
    /// `0..len` (there is no single contiguous `0..len` run of live elements
    /// anymore).
    fn emit_set_ensure_unique(&mut self, slot_ptr: &str, elem_ty: &Ty) {
        let elem_llvm = self.llvm_ty(elem_ty);
        let elem_size = self.emit_sizeof_llvm_ty(&elem_llvm);
        let payload_ty = self.set_payload_llvm_ty(elem_ty);

        let obj = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", obj, slot_ptr));
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, obj));
        let alloc_label = self.block_label("set_cow_alloc");
        let check_label = self.block_label("set_cow_check");
        let done_label = self.block_label("set_cow_done");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, alloc_label, check_label));

        self.open_block(&alloc_label);
        let release_fn0 = self.set_release_thunk_operand(elem_ty);
        let raw0 = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 40, i8* {})", raw0, release_fn0));
        let payload0 = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload0, raw0, payload_ty));
        let d0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", d0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store {}* null, {}** {}", elem_llvm, elem_llvm, d0));
        let s0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", s0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store i8* null, i8** {}", s0));
        let l0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", l0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store i64 0, i64* {}", l0));
        let c0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 3", c0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store i64 0, i64* {}", c0));
        let tm0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 4", tm0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store i64 0, i64* {}", tm0));
        self.line(&format!("  store i8* {}, i8** {}", raw0, slot_ptr));
        self.line(&format!("  br label %{}", done_label));

        self.open_block(&check_label);
        let hdr_i8 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 -16", hdr_i8, obj));
        let hdr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i64*", hdr, hdr_i8));
        let rc = self.tmp_name();
        self.line(&format!("  {} = load atomic i64, i64* {} seq_cst, align 8", rc, hdr));
        let is_unique = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, 1", is_unique, rc));
        let clone_label = self.block_label("set_cow_clone");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_unique, done_label, clone_label));

        self.open_block(&clone_label);
        let old_payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", old_payload, obj, payload_ty));
        let od_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", od_field, payload_ty, payload_ty, old_payload));
        let od = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", od, elem_llvm, elem_llvm, od_field));
        let os_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", os_field, payload_ty, payload_ty, old_payload));
        let os = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", os, os_field));
        let ol_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", ol_field, payload_ty, payload_ty, old_payload));
        let ol = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", ol, ol_field));
        let oc_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 3", oc_field, payload_ty, payload_ty, old_payload));
        let oc = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", oc, oc_field));
        let otm_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 4", otm_field, payload_ty, payload_ty, old_payload));
        let otm = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", otm, otm_field));

        let release_fn1 = self.set_release_thunk_operand(elem_ty);
        let new_raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 40, i8* {})", new_raw, release_fn1));
        let new_payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", new_payload, new_raw, payload_ty));

        let new_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", new_bytes, oc, elem_size));
        let new_raw_data = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", new_raw_data, new_bytes));
        let new_data = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", new_data, new_raw_data, elem_llvm));
        let new_states = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", new_states, oc));

        let has_cap = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i64 {}, 0", has_cap, oc));
        let copy_label = self.block_label("set_cow_copy");
        let after_copy_label = self.block_label("set_cow_after_copy");
        self.line(&format!("  br i1 {}, label %{}, label %{}", has_cap, copy_label, after_copy_label));

        self.open_block(&copy_label);
        let old_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", old_bytes, oc, elem_size));
        let old_raw_data = self.tmp_name();
        self.line(&format!("  {} = bitcast {}* {} to i8*", old_raw_data, elem_llvm, od));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_raw_data, old_raw_data, old_bytes));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_states, os, oc));
        if self.contains_rc(elem_ty) {
            let i_ptr = self.tmp_name();
            self.line(&format!("  {} = alloca i64", i_ptr));
            self.line(&format!("  store i64 0, i64* {}", i_ptr));
            let cond_label = self.block_label("set_cow_retain_cond");
            let body_label = self.block_label("set_cow_retain_body");
            let occ_label = self.block_label("set_cow_retain_occ");
            let next_label = self.block_label("set_cow_retain_next");
            let retain_end_label = self.block_label("set_cow_retain_end");
            self.line(&format!("  br label %{}", cond_label));
            self.open_block(&cond_label);
            let i_reg = self.tmp_name();
            self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
            let cmp = self.tmp_name();
            self.line(&format!("  {} = icmp slt i64 {}, {}", cmp, i_reg, oc));
            self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, body_label, retain_end_label));
            self.open_block(&body_label);
            let st_ptr = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", st_ptr, new_states, i_reg));
            let st = self.tmp_name();
            self.line(&format!("  {} = load i8, i8* {}", st, st_ptr));
            let is_occ = self.tmp_name();
            self.line(&format!("  {} = icmp eq i8 {}, 1", is_occ, st));
            self.line(&format!("  br i1 {}, label %{}, label %{}", is_occ, occ_label, next_label));
            self.open_block(&occ_label);
            let elem_ptr = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, new_data, i_reg));
            self.emit_retain_at(&elem_ptr, elem_ty);
            self.line(&format!("  br label %{}", next_label));
            self.open_block(&next_label);
            let i_next = self.tmp_name();
            self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
            self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
            self.line(&format!("  br label %{}", cond_label));
            self.open_block(&retain_end_label);
        }
        self.line(&format!("  br label %{}", after_copy_label));

        self.open_block(&after_copy_label);
        let nd_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", nd_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store {}* {}, {}** {}", elem_llvm, new_data, elem_llvm, nd_field));
        let ns_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", ns_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store i8* {}, i8** {}", new_states, ns_field));
        let nl_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", nl_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store i64 {}, i64* {}", ol, nl_field));
        let nc_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 3", nc_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store i64 {}, i64* {}", oc, nc_field));
        let ntm_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 4", ntm_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store i64 {}, i64* {}", otm, ntm_field));

        self.line(&format!("  call void @star_rc_release(i8* {})", obj));
        self.line(&format!("  store i8* {}, i8** {}", new_raw, slot_ptr));
        self.line(&format!("  br label %{}", done_label));

        self.open_block(&done_label);
    }

    /// Read path: resolve `base`'s `(data, states, len, cap)`, no CoW check,
    /// `null` reading as all-zero/empty. Mirrors `Codegen::list_fields`.
    /// Resolves `base` through `Codegen::emit_read_place`, not `emit_place`
    /// -- see the original module doc comment (preserved from before this
    /// pass) for why a `Set`-typed value reached through a `List<Set<T>>`
    /// index or a struct field behind one must not spuriously CoW-clone the
    /// outer list as a side effect of a read.
    fn set_fields(&mut self, base: &TypedExpr, elem_ty: &Ty) -> (String, String, String, String) {
        let slot_ptr = self.emit_read_place(base);
        let obj = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", obj, slot_ptr));

        let elem_llvm = self.llvm_ty(elem_ty);
        let payload_ty = self.set_payload_llvm_ty(elem_ty);

        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, obj));
        let null_label = self.block_label("set_read_null");
        let real_label = self.block_label("set_read_real");
        let end_label = self.block_label("set_read_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, null_label, real_label));

        self.open_block(&null_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&real_label);
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload, obj, payload_ty));
        let data_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", data_field, payload_ty, payload_ty, payload));
        let data_real = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", data_real, elem_llvm, elem_llvm, data_field));
        let states_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", states_field, payload_ty, payload_ty, payload));
        let states_real = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", states_real, states_field));
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", len_field, payload_ty, payload_ty, payload));
        let len_real = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len_real, len_field));
        let cap_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 3", cap_field, payload_ty, payload_ty, payload));
        let cap_real = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", cap_real, cap_field));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let data = self.tmp_name();
        self.line(&format!("  {} = phi {}* [ null, %{} ], [ {}, %{} ]", data, elem_llvm, null_label, data_real, real_label));
        let states = self.tmp_name();
        self.line(&format!("  {} = phi i8* [ null, %{} ], [ {}, %{} ]", states, null_label, states_real, real_label));
        let len = self.tmp_name();
        self.line(&format!("  {} = phi i64 [ 0, %{} ], [ {}, %{} ]", len, null_label, len_real, real_label));
        let cap = self.tmp_name();
        self.line(&format!("  {} = phi i64 [ 0, %{} ], [ {}, %{} ]", cap, null_label, cap_real, real_label));

        (data, states, len, cap)
    }

    /// Mutating path: `emit_set_ensure_unique` first, so the returned
    /// `(data, ...)` is guaranteed uniquely owned. Mirrors
    /// `Codegen::list_fields_mut`.
    #[allow(clippy::type_complexity)]
    fn set_fields_mut(&mut self, base: &TypedExpr, elem_ty: &Ty) -> (String, String, String, String, String, String, String, String, String, String) {
        let elem_llvm = self.llvm_ty(elem_ty);
        let payload_ty = self.set_payload_llvm_ty(elem_ty);
        let slot_ptr = self.emit_place(base);
        self.emit_set_ensure_unique(&slot_ptr, elem_ty);

        let obj = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", obj, slot_ptr));
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload, obj, payload_ty));

        let data_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", data_field, payload_ty, payload_ty, payload));
        let data = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", data, elem_llvm, elem_llvm, data_field));
        let states_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", states_field, payload_ty, payload_ty, payload));
        let states = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", states, states_field));
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", len_field, payload_ty, payload_ty, payload));
        let len = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len, len_field));
        let cap_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 3", cap_field, payload_ty, payload_ty, payload));
        let cap = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", cap, cap_field));
        let tomb_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 4", tomb_field, payload_ty, payload_ty, payload));
        let tomb = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", tomb, tomb_field));

        (data, data_field, states, states_field, len, len_field, cap, cap_field, tomb, tomb_field)
    }

    /// Double `data`/`states` (or allocate an initial `cap = 8` table from
    /// empty) and rehash every currently-`OCCUPIED` slot into the fresh
    /// table -- called from `SetMethod::Insert` once its load-factor check
    /// (`(len + tomb + 1) * 4 > cap * 3`) trips. Rehashing (rather than a
    /// flat `memcpy`, which is all a CoW clone needs) is required here
    /// because growing changes `cap`, and therefore every element's
    /// `hash & (cap - 1)` bucket -- unlike `emit_set_ensure_unique`'s clone,
    /// which keeps `cap` fixed and so can copy slot-for-slot. Also always
    /// drops every tombstone (the fresh table starts all-`EMPTY`), which is
    /// what keeps the tombstone count from ever growing unbounded across
    /// repeated insert/remove churn.
    fn emit_set_grow(&mut self, data_field: &str, states_field: &str, cap_field: &str, tomb_field: &str, cap: &str, elem_ty: &Ty) {
        let elem_llvm = self.llvm_ty(elem_ty);
        let elem_size = self.emit_sizeof_llvm_ty(&elem_llvm);

        let new_cap = self.emit_ht_grown_cap(cap);
        let new_mask = self.tmp_name();
        self.line(&format!("  {} = sub i64 {}, 1", new_mask, new_cap));

        let new_data_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", new_data_bytes, new_cap, elem_size));
        let new_data_raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", new_data_raw, new_data_bytes));
        let new_data = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", new_data, new_data_raw, elem_llvm));
        let new_states = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", new_states, new_cap));
        self.emit_fill_i8(&new_states, &new_cap, 0);

        // Rehash every OCCUPIED old slot into the fresh table.
        let old_data = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", old_data, elem_llvm, elem_llvm, data_field));
        let old_states = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", old_states, states_field));

        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));
        let cond_label = self.block_label("set_grow_cond");
        let body_label = self.block_label("set_grow_body");
        let occ_label = self.block_label("set_grow_occ");
        let next_label = self.block_label("set_grow_next");
        let end_label = self.block_label("set_grow_end");
        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&cond_label);
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
        let in_range = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", in_range, i_reg, cap));
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_range, body_label, end_label));

        self.open_block(&body_label);
        let st_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", st_ptr, old_states, i_reg));
        let st = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", st, st_ptr));
        let is_occ = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8 {}, 1", is_occ, st));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_occ, occ_label, next_label));

        self.open_block(&occ_label);
        let elem_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, old_data, i_reg));
        let elem_val = self.tmp_name();
        self.line(&format!("  {} = load {}, {}* {}", elem_val, elem_llvm, elem_llvm, elem_ptr));
        let hash_fn = self.hash_fn_name(elem_ty);
        let h = self.tmp_name();
        self.line(&format!("  {} = call i64 @{}({} {})", h, hash_fn, elem_llvm, elem_val));
        let start = self.tmp_name();
        self.line(&format!("  {} = and i64 {}, {}", start, h, new_mask));
        let new_slot = self.emit_ht_first_empty(&new_states, &new_cap, &new_mask, &start);
        let new_st_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", new_st_ptr, new_states, new_slot));
        self.line(&format!("  store i8 1, i8* {}", new_st_ptr));
        let new_elem_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", new_elem_ptr, elem_llvm, elem_llvm, new_data, new_slot));
        self.line(&format!("  store {} {}, {}* {}", elem_llvm, elem_val, elem_llvm, new_elem_ptr));
        self.line(&format!("  br label %{}", next_label));

        self.open_block(&next_label);
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&end_label);
        let old_data_i8 = self.tmp_name();
        self.line(&format!("  {} = bitcast {}* {} to i8*", old_data_i8, elem_llvm, old_data));
        self.line(&format!("  call void @free(i8* {})", old_data_i8));
        self.line(&format!("  call void @free(i8* {})", old_states));

        self.line(&format!("  store {}* {}, {}** {}", elem_llvm, new_data, elem_llvm, data_field));
        self.line(&format!("  store i8* {}, i8** {}", new_states, states_field));
        self.line(&format!("  store i64 {}, i64* {}", new_cap, cap_field));
        self.line(&format!("  store i64 0, i64* {}", tomb_field));
    }

    /// `set.insert(v)` / `.remove(v)` / `.contains(v)` / `.len()`.
    pub(super) fn emit_set_method(&mut self, base: &TypedExpr, method: SetMethod, args: &[TypedExpr], elem_ty: &Ty) -> String {
        match method {
            SetMethod::Len => {
                let (_, _, len, _) = self.set_fields(base, elem_ty);
                let len32 = self.tmp_name();
                self.line(&format!("  {} = trunc i64 {} to i32", len32, len));
                format!("i32 {}", len32)
            }
            SetMethod::Contains => {
                let val = self.emit_expr(&args[0]);
                let needle = self.untag(&val, elem_ty);
                // Read fields *after* evaluating `args[0]` -- same
                // stale-snapshot hazard `MapMethod`/`SetMethod::Insert`'s own
                // comments document, applied uniformly here too.
                let (data, states, _len, cap) = self.set_fields(base, elem_ty);
                let mask = self.tmp_name();
                self.line(&format!("  {} = sub i64 {}, 1", mask, cap));
                let hash_fn = self.hash_fn_name(elem_ty);
                let h = self.tmp_name();
                self.line(&format!("  {} = call i64 @{}({} {})", h, hash_fn, self.llvm_ty(elem_ty), needle));
                let start = self.tmp_name();
                self.line(&format!("  {} = and i64 {}, {}", start, h, mask));
                let (found, _, _) = self.emit_ht_probe(&states, &data, &cap, &mask, &start, elem_ty, &needle);
                // `needle` is only ever compared against, never stored --
                // release whatever `emit_expr` left us owning (see
                // `rc.rs`'s module doc comment), or it leaks one reference
                // per call.
                self.emit_release_bare(&needle, elem_ty);
                format!("i1 {}", found)
            }
            SetMethod::Insert => {
                let (_, data_field, _, states_field, _stale_len, len_field, _stale_cap, cap_field, _stale_tomb, tomb_field) = self.set_fields_mut(base, elem_ty);
                let val = self.emit_expr(&args[0]);
                let clean_val = self.untag(&val, elem_ty);

                // Reload fresh (post-`args[0]` evaluation, same hazard/fix
                // as `ListMethod::Push`).
                let len = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", len, len_field));
                let cap = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", cap, cap_field));
                let tomb = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", tomb, tomb_field));

                // Grow when the table (including tombstones) would cross
                // 75% load after this insert -- also naturally true when
                // `cap == 0` (a fresh/empty table), so no separate
                // "allocate the first table" case is needed.
                let sum = self.tmp_name();
                self.line(&format!("  {} = add i64 {}, {}", sum, len, tomb));
                let sum1 = self.tmp_name();
                self.line(&format!("  {} = add i64 {}, 1", sum1, sum));
                let lhs = self.tmp_name();
                self.line(&format!("  {} = mul i64 {}, 4", lhs, sum1));
                let rhs = self.tmp_name();
                self.line(&format!("  {} = mul i64 {}, 3", rhs, cap));
                let needs_grow = self.tmp_name();
                self.line(&format!("  {} = icmp sgt i64 {}, {}", needs_grow, lhs, rhs));
                let grow_label = self.block_label("set_insert_grow");
                let after_grow_label = self.block_label("set_insert_after_grow");
                self.line(&format!("  br i1 {}, label %{}, label %{}", needs_grow, grow_label, after_grow_label));

                self.open_block(&grow_label);
                self.emit_set_grow(&data_field, &states_field, &cap_field, &tomb_field, &cap, elem_ty);
                self.line(&format!("  br label %{}", after_grow_label));

                self.open_block(&after_grow_label);
                let data = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", data, self.llvm_ty(elem_ty), self.llvm_ty(elem_ty), data_field));
                let states = self.tmp_name();
                self.line(&format!("  {} = load i8*, i8** {}", states, states_field));
                let cap2 = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", cap2, cap_field));
                let mask = self.tmp_name();
                self.line(&format!("  {} = sub i64 {}, 1", mask, cap2));
                let hash_fn = self.hash_fn_name(elem_ty);
                let h = self.tmp_name();
                self.line(&format!("  {} = call i64 @{}({} {})", h, hash_fn, self.llvm_ty(elem_ty), clean_val));
                let start = self.tmp_name();
                self.line(&format!("  {} = and i64 {}, {}", start, h, mask));
                let (found, _, islot) = self.emit_ht_probe(&states, &data, &cap2, &mask, &start, elem_ty, &clean_val);
                let inserted = self.tmp_name();
                self.line(&format!("  {} = xor i1 {}, true", inserted, found));

                let already_label = self.block_label("set_insert_already_present");
                let do_insert_label = self.block_label("set_insert_do");
                let end_label = self.block_label("set_insert_end");
                self.line(&format!("  br i1 {}, label %{}, label %{}", found, already_label, do_insert_label));

                self.open_block(&already_label);
                // The set already contains an equal element, so `clean_val`
                // itself is never stored -- release whatever `emit_expr`
                // left us owning, or it leaks one reference per no-op
                // `insert` call.
                self.emit_release_bare(&clean_val, elem_ty);
                self.line(&format!("  br label %{}", end_label));

                self.open_block(&do_insert_label);
                let st_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", st_ptr, states, islot));
                let was_tomb = self.tmp_name();
                self.line(&format!("  {} = load i8, i8* {}", was_tomb, st_ptr));
                let is_tomb = self.tmp_name();
                self.line(&format!("  {} = icmp eq i8 {}, 2", is_tomb, was_tomb));
                let dec_tomb_label = self.block_label("set_insert_dec_tomb");
                let store_label = self.block_label("set_insert_store");
                self.line(&format!("  br i1 {}, label %{}, label %{}", is_tomb, dec_tomb_label, store_label));

                self.open_block(&dec_tomb_label);
                let tomb_now = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", tomb_now, tomb_field));
                let tomb_new = self.tmp_name();
                self.line(&format!("  {} = sub i64 {}, 1", tomb_new, tomb_now));
                self.line(&format!("  store i64 {}, i64* {}", tomb_new, tomb_field));
                self.line(&format!("  br label %{}", store_label));

                self.open_block(&store_label);
                self.line(&format!("  store i8 1, i8* {}", st_ptr));
                let elem_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, self.llvm_ty(elem_ty), self.llvm_ty(elem_ty), data, islot));
                self.line(&format!("  store {} {}, {}* {}", self.llvm_ty(elem_ty), clean_val, self.llvm_ty(elem_ty), elem_ptr));
                let len_now = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", len_now, len_field));
                let len_new = self.tmp_name();
                self.line(&format!("  {} = add i64 {}, 1", len_new, len_now));
                self.line(&format!("  store i64 {}, i64* {}", len_new, len_field));
                self.line(&format!("  br label %{}", end_label));

                self.open_block(&end_label);
                format!("i1 {}", inserted)
            }
            SetMethod::Remove => {
                let (_, data_field, _, states_field, _stale_len, len_field, _stale_cap, cap_field, _stale_tomb, tomb_field) = self.set_fields_mut(base, elem_ty);
                let val = self.emit_expr(&args[0]);
                let needle = self.untag(&val, elem_ty);

                // Reload fresh (post-`args[0]` evaluation) -- same hazard as
                // `SetMethod::Insert`.
                let data = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", data, self.llvm_ty(elem_ty), self.llvm_ty(elem_ty), data_field));
                let states = self.tmp_name();
                self.line(&format!("  {} = load i8*, i8** {}", states, states_field));
                let cap = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", cap, cap_field));
                let mask = self.tmp_name();
                self.line(&format!("  {} = sub i64 {}, 1", mask, cap));
                let hash_fn = self.hash_fn_name(elem_ty);
                let h = self.tmp_name();
                self.line(&format!("  {} = call i64 @{}({} {})", h, hash_fn, self.llvm_ty(elem_ty), needle));
                let start = self.tmp_name();
                self.line(&format!("  {} = and i64 {}, {}", start, h, mask));
                let (found, idx, _) = self.emit_ht_probe(&states, &data, &cap, &mask, &start, elem_ty, &needle);
                // `needle` is only ever compared against here, never stored
                // (the element actually stored in the set is released
                // separately, below, when the removed slot itself is torn
                // down) -- same reasoning as `SetMethod::Contains`.
                self.emit_release_bare(&needle, elem_ty);

                let do_label = self.block_label("set_remove_do");
                let end_label = self.block_label("set_remove_end");
                self.line(&format!("  br i1 {}, label %{}, label %{}", found, do_label, end_label));

                self.open_block(&do_label);
                let elem_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, self.llvm_ty(elem_ty), self.llvm_ty(elem_ty), data, idx));
                self.emit_release_at(&elem_ptr, elem_ty);
                let st_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", st_ptr, states, idx));
                self.line(&format!("  store i8 2, i8* {}", st_ptr));
                let len_now = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", len_now, len_field));
                let len_new = self.tmp_name();
                self.line(&format!("  {} = sub i64 {}, 1", len_new, len_now));
                self.line(&format!("  store i64 {}, i64* {}", len_new, len_field));
                let tomb_now = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", tomb_now, tomb_field));
                let tomb_new = self.tmp_name();
                self.line(&format!("  {} = add i64 {}, 1", tomb_new, tomb_now));
                self.line(&format!("  store i64 {}, i64* {}", tomb_new, tomb_field));
                self.line(&format!("  br label %{}", end_label));

                self.open_block(&end_label);
                format!("i1 {}", found)
            }
        }
    }
}
