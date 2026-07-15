//! `Set<T>` codegen: a growable set lowered to the exact same
//! reference-counted, copy-on-write `i8*` object pointer/payload shape as
//! `List<T>` (`{ T* data, i64 len, i64 cap }`, see `crate::codegen::list`'s
//! doc comment for the RC/CoW/growth scheme this mirrors verbatim) -- the
//! only real difference is that `insert`/`remove`/`contains` locate an
//! element by a linear scan using a generated structural-equality function
//! (`crate::codegen::eq`) instead of by index.
//!
//! There is no hashing/bucketing here: every operation is `O(n)` in the
//! set's current size. This is a deliberate scope cut for the first cut of
//! `Set<T>` (see `docs/design.md`'s Type System plan) -- it fully supports
//! arbitrary structurally-hashable-per-`Checker::check_hashable_ty` element
//! types (including nested structs) without needing a hash function at all,
//! at the cost of `O(n)` operations instead of `O(1)`. Swapping in a real
//! hash table later is a purely internal codegen change; it would not affect
//! `Set<T>`'s observable language semantics at all.

use crate::types::*;

use super::Codegen;

impl Codegen {
    fn set_payload_llvm_ty(&self, elem_ty: &Ty) -> String {
        format!("{{ {}*, i64, i64 }}", self.llvm_ty(elem_ty))
    }

    /// Mirrors `Codegen::list_release_thunk_operand`; see its doc comment.
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

        if elem_has_rc {
            let len_field = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", len_field, payload_ty, payload_ty, payload));
            let len = self.tmp_name();
            self.line(&format!("  {} = load i64, i64* {}", len, len_field));

            let i_ptr = self.tmp_name();
            self.line(&format!("  {} = alloca i64", i_ptr));
            self.line(&format!("  store i64 0, i64* {}", i_ptr));

            let cond_label = self.block_label("set_release_cond");
            let body_label = self.block_label("set_release_body");
            let end_label = self.block_label("set_release_end");
            self.line(&format!("  br label %{}", cond_label));
            self.open_block(&cond_label);
            let i_reg = self.tmp_name();
            self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
            let cmp = self.tmp_name();
            self.line(&format!("  {} = icmp slt i64 {}, {}", cmp, i_reg, len));
            self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, body_label, end_label));

            self.open_block(&body_label);
            let elem_ptr = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, data, i_reg));
            self.emit_release_at(&elem_ptr, elem_ty);
            let i_next = self.tmp_name();
            self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
            self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
            self.line(&format!("  br label %{}", cond_label));

            self.open_block(&end_label);
        }

        let data_i8 = self.tmp_name();
        self.line(&format!("  {} = bitcast {}* {} to i8*", data_i8, elem_llvm, data));
        self.line(&format!("  call void @free(i8* {})", data_i8));
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
    /// `Codegen::emit_list_ensure_unique` exactly (same shape, `T` in place
    /// of `List<T>`'s element type) -- see its doc comment.
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
        let ol_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", ol_field, payload_ty, payload_ty, old_payload));
        let ol = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", ol, ol_field));
        let oc_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", oc_field, payload_ty, payload_ty, old_payload));
        let oc = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", oc, oc_field));

        let release_fn1 = self.set_release_thunk_operand(elem_ty);
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

        let has_len = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i64 {}, 0", has_len, ol));
        let copy_label = self.block_label("set_cow_copy");
        let after_copy_label = self.block_label("set_cow_after_copy");
        self.line(&format!("  br i1 {}, label %{}, label %{}", has_len, copy_label, after_copy_label));

        self.open_block(&copy_label);
        let old_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", old_bytes, ol, elem_size));
        let old_raw_data = self.tmp_name();
        self.line(&format!("  {} = bitcast {}* {} to i8*", old_raw_data, elem_llvm, od));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_raw_data, old_raw_data, old_bytes));
        if self.contains_rc(elem_ty) {
            let i_ptr = self.tmp_name();
            self.line(&format!("  {} = alloca i64", i_ptr));
            self.line(&format!("  store i64 0, i64* {}", i_ptr));
            let cond_label = self.block_label("set_cow_retain_cond");
            let body_label = self.block_label("set_cow_retain_body");
            let retain_end_label = self.block_label("set_cow_retain_end");
            self.line(&format!("  br label %{}", cond_label));
            self.open_block(&cond_label);
            let i_reg = self.tmp_name();
            self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
            let cmp = self.tmp_name();
            self.line(&format!("  {} = icmp slt i64 {}, {}", cmp, i_reg, ol));
            self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, body_label, retain_end_label));
            self.open_block(&body_label);
            let elem_ptr = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, new_data, i_reg));
            self.emit_retain_at(&elem_ptr, elem_ty);
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
        let nl_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", nl_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store i64 {}, i64* {}", ol, nl_field));
        let nc_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", nc_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store i64 {}, i64* {}", oc, nc_field));

        self.line(&format!("  call void @star_rc_release(i8* {})", obj));
        self.line(&format!("  store i8* {}, i8** {}", new_raw, slot_ptr));
        self.line(&format!("  br label %{}", done_label));

        self.open_block(&done_label);
    }

    /// Read path: resolve `base`'s `(data, len)`, no CoW check, `null`
    /// reading as `data = null, len = 0`. Mirrors `Codegen::list_fields`.
    /// Resolves `base` through `Codegen::emit_read_place`, not `emit_place`:
    /// `Set<T>` has no `[..]` indexing syntax of its own, but a `Set`-typed
    /// value can still be *reached* through one, as a `List<Set<T>>`
    /// element (`sets[0].contains(x)`) or a struct field behind one
    /// (`points[0].my_set.contains(x)`) -- `emit_place`'s `ListIndex` arm is
    /// a write path that would spuriously CoW-clone the outer list as a
    /// side effect of this read (same bug class as the already-fixed
    /// `list_fields`/`list_index_read_obj`).
    fn set_fields(&mut self, base: &TypedExpr, elem_ty: &Ty) -> (String, String) {
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
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", len_field, payload_ty, payload_ty, payload));
        let len_real = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len_real, len_field));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let data = self.tmp_name();
        self.line(&format!("  {} = phi {}* [ null, %{} ], [ {}, %{} ]", data, elem_llvm, null_label, data_real, real_label));
        let len = self.tmp_name();
        self.line(&format!("  {} = phi i64 [ 0, %{} ], [ {}, %{} ]", len, null_label, len_real, real_label));

        (data, len)
    }

    /// Mutating path: `emit_set_ensure_unique` first, so the returned
    /// `(data, ...)` is guaranteed uniquely owned. Mirrors
    /// `Codegen::list_fields_mut`.
    fn set_fields_mut(&mut self, base: &TypedExpr, elem_ty: &Ty) -> (String, String, String, String, String) {
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
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", len_field, payload_ty, payload_ty, payload));
        let len = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len, len_field));
        let cap_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", cap_field, payload_ty, payload_ty, payload));

        (data, data_field, len, len_field, cap_field)
    }

    /// Linear scan `data[0..len)` for the first index whose element
    /// structurally equals `needle` (an already-loaded, bare register of
    /// type `elem_ty`), via the generated `eq_<mangled>` function. Returns
    /// `(found: i1, index: i64)` -- `index` is only meaningful when `found`
    /// is true (`-1` otherwise, purely so it's a well-defined SSA value).
    fn emit_linear_find(&mut self, data: &str, len: &str, elem_ty: &Ty, needle: &str) -> (String, String) {
        let elem_llvm = self.llvm_ty(elem_ty);
        let eq_fn = self.eq_fn_name(elem_ty);

        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));
        let found_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i1", found_ptr));
        self.line(&format!("  store i1 false, i1* {}", found_ptr));

        let cond_label = self.block_label("find_cond");
        let body_label = self.block_label("find_body");
        let eq_check_label = self.block_label("find_eq_check");
        let next_label = self.block_label("find_next");
        let end_label = self.block_label("find_end");

        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&cond_label);
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
        let in_range = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", in_range, i_reg, len));
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_range, body_label, end_label));

        self.open_block(&body_label);
        let elem_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, data, i_reg));
        let elem_val = self.tmp_name();
        self.line(&format!("  {} = load {}, {}* {}", elem_val, elem_llvm, elem_llvm, elem_ptr));
        self.line(&format!("  br label %{}", eq_check_label));

        self.open_block(&eq_check_label);
        let is_eq = self.tmp_name();
        self.line(&format!("  {} = call i1 @{}({} {}, {} {})", is_eq, eq_fn, elem_llvm, elem_val, elem_llvm, needle));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_eq, end_label, next_label));

        self.open_block(&next_label);
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&end_label);
        // Re-load `i` here rather than reusing `i_reg`/`is_eq` directly:
        // this block is reached from both `cond_label` (not-found, loop
        // exhausted) and `eq_check_label` (found) -- `i_ptr` was last
        // written to the *matching* index in the found case (the `next_label`
        // increment never runs before jumping here), and still holds the
        // loop-exit value `len` in the not-found case, so a fresh load is
        // correct either way without needing a `phi` across two predecessors
        // for `i` itself.
        let final_i = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", final_i, i_ptr));
        let found = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", found, final_i, len));
        (found, final_i)
    }

    /// `set.insert(v)` / `.remove(v)` / `.contains(v)` / `.len()`.
    pub(super) fn emit_set_method(&mut self, base: &TypedExpr, method: SetMethod, args: &[TypedExpr], elem_ty: &Ty) -> String {
        let elem_llvm = self.llvm_ty(elem_ty);

        match method {
            SetMethod::Len => {
                let (_, len) = self.set_fields(base, elem_ty);
                let len32 = self.tmp_name();
                self.line(&format!("  {} = trunc i64 {} to i32", len32, len));
                format!("i32 {}", len32)
            }
            SetMethod::Contains => {
                let val = self.emit_expr(&args[0]);
                let needle = self.untag(&val, elem_ty);
                // Read data/len *after* evaluating `args[0]` -- if it
                // mutates this same set (e.g. `s.contains(pick(s.remove(k)))`),
                // a snapshot taken beforehand would be stale (mirrors
                // `SetMethod::Insert`'s identical fix for `len`/`data0`).
                let (data, len) = self.set_fields(base, elem_ty);
                let (found, _) = self.emit_linear_find(&data, &len, elem_ty, &needle);
                // `needle` is only ever compared against, never stored --
                // release the borrow `emit_expr` retained on `args[0]`'s
                // behalf (a no-op if `args[0]` was a fresh construction, see
                // `is_rc_borrowing_read`), or it leaks one reference per call.
                if Self::is_rc_borrowing_read(&args[0]) {
                    self.emit_release_bare(&needle, elem_ty);
                }
                format!("i1 {}", found)
            }
            SetMethod::Insert => {
                let (_, data_field, _stale_len, len_field, cap_field) = self.set_fields_mut(base, elem_ty);
                let val = self.emit_expr(&args[0]);
                let clean_val = self.untag(&val, elem_ty);

                // `_stale_len` (from `set_fields_mut`, above) was captured
                // *before* evaluating `args[0]` -- if that argument
                // expression mutates this same set, the real `len_field` in
                // memory has already changed by the time we get here.
                // Reload it fresh (mirrors `ListMethod::Push`'s identical
                // fix), or the membership search/grow-check/write-index
                // below would all use a stale value.
                let len = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", len, len_field));

                let data0 = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", data0, elem_llvm, elem_llvm, data_field));
                let (found, _) = self.emit_linear_find(&data0, &len, elem_ty, &clean_val);

                let already_label = self.block_label("set_insert_already_present");
                let insert_label = self.block_label("set_insert_do");
                let end_label = self.block_label("set_insert_end");
                self.line(&format!("  br i1 {}, label %{}, label %{}", found, already_label, insert_label));

                self.open_block(&already_label);
                // The set already contains an equal element, so `clean_val`
                // itself is never stored -- release the borrow `emit_expr`
                // retained on `args[0]`'s behalf above (a no-op if `args[0]`
                // was a fresh construction), or it leaks one reference per
                // no-op `insert` call. The sibling `insert_label` branch below
                // does store `clean_val` into a fresh slot instead, transferring
                // that same retained reference to the set rather than releasing it.
                if Self::is_rc_borrowing_read(&args[0]) {
                    self.emit_release_bare(&clean_val, elem_ty);
                }
                let found_pred = self.current_label.clone();
                self.line(&format!("  br label %{}", end_label));

                self.open_block(&insert_label);
                let cap = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", cap, cap_field));
                let data = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", data, elem_llvm, elem_llvm, data_field));

                let needs_grow = self.tmp_name();
                self.line(&format!("  {} = icmp sge i64 {}, {}", needs_grow, len, cap));
                let grow_label = self.block_label("set_insert_grow");
                let store_label = self.block_label("set_insert_store");
                self.line(&format!("  br i1 {}, label %{}, label %{}", needs_grow, grow_label, store_label));

                self.open_block(&grow_label);
                let doubled = self.tmp_name();
                self.line(&format!("  {} = mul i64 {}, 2", doubled, cap));
                let has_cap = self.tmp_name();
                self.line(&format!("  {} = icmp sgt i64 {}, 0", has_cap, doubled));
                let new_cap = self.tmp_name();
                self.line(&format!("  {} = select i1 {}, i64 {}, i64 1", new_cap, has_cap, doubled));
                let elem_size = self.emit_sizeof_llvm_ty(&elem_llvm);
                let new_bytes = self.tmp_name();
                self.line(&format!("  {} = mul i64 {}, {}", new_bytes, new_cap, elem_size));
                let new_raw = self.tmp_name();
                self.line(&format!("  {} = call i8* @malloc(i64 {})", new_raw, new_bytes));
                let new_data = self.tmp_name();
                self.line(&format!("  {} = bitcast i8* {} to {}*", new_data, new_raw, elem_llvm));

                let had_data = self.tmp_name();
                self.line(&format!("  {} = icmp sgt i64 {}, 0", had_data, cap));
                let copy_label = self.block_label("set_insert_copy");
                let after_copy_label = self.block_label("set_insert_after_copy");
                self.line(&format!("  br i1 {}, label %{}, label %{}", had_data, copy_label, after_copy_label));

                self.open_block(&copy_label);
                let old_bytes = self.tmp_name();
                self.line(&format!("  {} = mul i64 {}, {}", old_bytes, len, elem_size));
                let old_raw = self.tmp_name();
                self.line(&format!("  {} = bitcast {}* {} to i8*", old_raw, elem_llvm, data));
                self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_raw, old_raw, old_bytes));
                self.line(&format!("  call void @free(i8* {})", old_raw));
                self.line(&format!("  br label %{}", after_copy_label));

                self.open_block(&after_copy_label);
                self.line(&format!("  store {}* {}, {}** {}", elem_llvm, new_data, elem_llvm, data_field));
                self.line(&format!("  store i64 {}, i64* {}", new_cap, cap_field));
                self.line(&format!("  br label %{}", store_label));

                self.open_block(&store_label);
                let data_now = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", data_now, elem_llvm, elem_llvm, data_field));
                let elem_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, data_now, len));
                self.line(&format!("  store {} {}, {}* {}", elem_llvm, clean_val, elem_llvm, elem_ptr));
                let new_len = self.tmp_name();
                self.line(&format!("  {} = add i64 {}, 1", new_len, len));
                self.line(&format!("  store i64 {}, i64* {}", new_len, len_field));
                let store_pred = self.current_label.clone();
                self.line(&format!("  br label %{}", end_label));

                self.open_block(&end_label);
                let inserted = self.tmp_name();
                self.line(&format!("  {} = phi i1 [ false, %{} ], [ true, %{} ]", inserted, found_pred, store_pred));
                format!("i1 {}", inserted)
            }
            SetMethod::Remove => {
                let (_, data_field, _stale_len, len_field, _) = self.set_fields_mut(base, elem_ty);
                let val = self.emit_expr(&args[0]);
                let needle = self.untag(&val, elem_ty);
                // `_stale_len` was captured *before* evaluating `args[0]` --
                // reload it fresh, same hazard and fix as `SetMethod::Insert`.
                // `data` is already (correctly) reloaded from `data_field`
                // below, after `args[0]`.
                let len = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", len, len_field));
                let data = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", data, elem_llvm, elem_llvm, data_field));
                let (found, idx) = self.emit_linear_find(&data, &len, elem_ty, &needle);
                // `needle` is only ever compared against here, never stored
                // (the element actually stored in the set is released
                // separately, below, when the removed slot itself is torn
                // down) -- same reasoning as `SetMethod::Contains`.
                if Self::is_rc_borrowing_read(&args[0]) {
                    self.emit_release_bare(&needle, elem_ty);
                }

                let do_label = self.block_label("set_remove_do");
                let end_label = self.block_label("set_remove_end");
                self.line(&format!("  br i1 {}, label %{}, label %{}", found, do_label, end_label));

                self.open_block(&do_label);
                let removed_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", removed_ptr, elem_llvm, elem_llvm, data, idx));
                self.emit_release_at(&removed_ptr, elem_ty);
                let new_len = self.tmp_name();
                self.line(&format!("  {} = sub i64 {}, 1", new_len, len));
                let last_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", last_ptr, elem_llvm, elem_llvm, data, new_len));
                let last_val = self.tmp_name();
                self.line(&format!("  {} = load {}, {}* {}", last_val, elem_llvm, elem_llvm, last_ptr));
                // Swap-remove: overwrite the removed slot with the last
                // element (a harmless self-store when `idx == new_len`) and
                // shrink `len` by one. Element order is not preserved.
                self.line(&format!("  store {} {}, {}* {}", elem_llvm, last_val, elem_llvm, removed_ptr));
                self.line(&format!("  store i64 {}, i64* {}", new_len, len_field));
                self.line(&format!("  br label %{}", end_label));

                self.open_block(&end_label);
                format!("i1 {}", found)
            }
        }
    }
}
