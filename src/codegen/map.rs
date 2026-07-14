//! `Map<K,V>` codegen: a growable key/value map lowered to a
//! reference-counted, copy-on-write `i8*` object pointer, same allocation
//! scheme as `List<T>`/`Set<T>` (see `crate::codegen::list`'s doc comment),
//! pointing past a `star_rc_alloc` header at a `{ K* keys, V* vals, i64 len,
//! i64 cap }` payload -- two parallel arrays grown/cloned in lockstep
//! instead of `List`'s one. `insert`/`get`/`remove`/`contains` locate a key
//! by the same linear structural-equality scan `Set<T>` uses (see
//! `crate::codegen::eq` and `crate::codegen::set`'s doc comment for the
//! rationale/scope cut this shares).
//!
//! `get`/`remove` return a real `Option<V>` (the compiler-builtin generic
//! enum from `docs/design.md`'s Type System §9, already proven by
//! `Checker::instantiate_enum`) -- `emit_construct_enum_variant` below
//! mirrors `TypedExpr::EnumVariant`'s own construction codegen
//! (`crate::codegen::expr`) exactly, just taking already-evaluated operands
//! instead of `TypedExpr` arguments to run `emit_expr` on.

use crate::types::*;

use super::Codegen;

impl Codegen {
    fn map_payload_llvm_ty(&self, key_ty: &Ty, val_ty: &Ty) -> String {
        format!("{{ {}*, {}*, i64, i64 }}", self.llvm_ty(key_ty), self.llvm_ty(val_ty))
    }

    /// Mirrors `Codegen::list_release_thunk_operand`/`set_release_thunk_operand`;
    /// releases every RC-bearing key *and* value before freeing both buffers.
    fn map_release_thunk_operand(&mut self, key_ty: &Ty, val_ty: &Ty) -> String {
        let key = format!("{}_{}", self.mangle_ty(key_ty), self.mangle_ty(val_ty));
        if let Some(name) = self.map_release_thunks.get(&key).cloned() {
            let reg = self.tmp_name();
            self.line(&format!("  {} = bitcast void (i8*)* @{} to i8*", reg, name));
            return reg;
        }

        let name = format!("map_release_{}", key);
        self.map_release_thunks.insert(key, name.clone());

        let key_llvm = self.llvm_ty(key_ty);
        let val_llvm = self.llvm_ty(val_ty);
        let payload_ty = self.map_payload_llvm_ty(key_ty, val_ty);
        let key_has_rc = self.contains_rc(key_ty);
        let val_has_rc = self.contains_rc(val_ty);

        let saved_ir = std::mem::take(&mut self.ir);
        self.line(&format!("define void @{}(i8* %objp) {{", name));
        self.open_block("entry");
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* %objp to {}*", payload, payload_ty));
        let keys_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", keys_field, payload_ty, payload_ty, payload));
        let keys = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", keys, key_llvm, key_llvm, keys_field));
        let vals_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", vals_field, payload_ty, payload_ty, payload));
        let vals = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", vals, val_llvm, val_llvm, vals_field));

        if key_has_rc || val_has_rc {
            let len_field = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", len_field, payload_ty, payload_ty, payload));
            let len = self.tmp_name();
            self.line(&format!("  {} = load i64, i64* {}", len, len_field));

            let i_ptr = self.tmp_name();
            self.line(&format!("  {} = alloca i64", i_ptr));
            self.line(&format!("  store i64 0, i64* {}", i_ptr));

            let cond_label = self.block_label("map_release_cond");
            let body_label = self.block_label("map_release_body");
            let end_label = self.block_label("map_release_end");
            self.line(&format!("  br label %{}", cond_label));
            self.open_block(&cond_label);
            let i_reg = self.tmp_name();
            self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
            let cmp = self.tmp_name();
            self.line(&format!("  {} = icmp slt i64 {}, {}", cmp, i_reg, len));
            self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, body_label, end_label));

            self.open_block(&body_label);
            if key_has_rc {
                let key_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", key_ptr, key_llvm, key_llvm, keys, i_reg));
                self.emit_release_at(&key_ptr, key_ty);
            }
            if val_has_rc {
                let val_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", val_ptr, val_llvm, val_llvm, vals, i_reg));
                self.emit_release_at(&val_ptr, val_ty);
            }
            let i_next = self.tmp_name();
            self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
            self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
            self.line(&format!("  br label %{}", cond_label));

            self.open_block(&end_label);
        }

        let keys_i8 = self.tmp_name();
        self.line(&format!("  {} = bitcast {}* {} to i8*", keys_i8, key_llvm, keys));
        self.line(&format!("  call void @free(i8* {})", keys_i8));
        let vals_i8 = self.tmp_name();
        self.line(&format!("  {} = bitcast {}* {} to i8*", vals_i8, val_llvm, vals));
        self.line(&format!("  call void @free(i8* {})", vals_i8));
        self.line("  ret void");
        self.line("}");
        self.line("");
        let fn_ir = std::mem::replace(&mut self.ir, saved_ir);
        self.pending_top.push(fn_ir);

        let reg = self.tmp_name();
        self.line(&format!("  {} = bitcast void (i8*)* @{} to i8*", reg, name));
        reg
    }

    /// `Map<K,V>()`: the empty map is `null`, mirroring `List<T>()`.
    pub(super) fn emit_map_new(&mut self, _key_ty: &Ty, _val_ty: &Ty) -> String {
        "i8* null".into()
    }

    /// Copy-on-write gate for every mutating map operation. Mirrors
    /// `Codegen::emit_list_ensure_unique`/`emit_set_ensure_unique`, cloning
    /// both parallel arrays together.
    fn emit_map_ensure_unique(&mut self, slot_ptr: &str, key_ty: &Ty, val_ty: &Ty) {
        let key_llvm = self.llvm_ty(key_ty);
        let val_llvm = self.llvm_ty(val_ty);
        let key_size = self.emit_sizeof_llvm_ty(&key_llvm);
        let val_size = self.emit_sizeof_llvm_ty(&val_llvm);
        let payload_ty = self.map_payload_llvm_ty(key_ty, val_ty);

        let obj = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", obj, slot_ptr));
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, obj));
        let alloc_label = self.block_label("map_cow_alloc");
        let check_label = self.block_label("map_cow_check");
        let done_label = self.block_label("map_cow_done");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, alloc_label, check_label));

        self.open_block(&alloc_label);
        let release_fn0 = self.map_release_thunk_operand(key_ty, val_ty);
        let raw0 = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 32, i8* {})", raw0, release_fn0));
        let payload0 = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload0, raw0, payload_ty));
        let k0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", k0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store {}* null, {}** {}", key_llvm, key_llvm, k0));
        let v0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", v0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store {}* null, {}** {}", val_llvm, val_llvm, v0));
        let l0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", l0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store i64 0, i64* {}", l0));
        let c0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 3", c0, payload_ty, payload_ty, payload0));
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
        let clone_label = self.block_label("map_cow_clone");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_unique, done_label, clone_label));

        self.open_block(&clone_label);
        let old_payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", old_payload, obj, payload_ty));
        let ok_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", ok_field, payload_ty, payload_ty, old_payload));
        let ok = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", ok, key_llvm, key_llvm, ok_field));
        let ov_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", ov_field, payload_ty, payload_ty, old_payload));
        let ov = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", ov, val_llvm, val_llvm, ov_field));
        let ol_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", ol_field, payload_ty, payload_ty, old_payload));
        let ol = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", ol, ol_field));
        let oc_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 3", oc_field, payload_ty, payload_ty, old_payload));
        let oc = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", oc, oc_field));

        let release_fn1 = self.map_release_thunk_operand(key_ty, val_ty);
        let new_raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 32, i8* {})", new_raw, release_fn1));
        let new_payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", new_payload, new_raw, payload_ty));

        let new_key_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", new_key_bytes, oc, key_size));
        let new_keys_raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", new_keys_raw, new_key_bytes));
        let new_keys = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", new_keys, new_keys_raw, key_llvm));
        let new_val_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", new_val_bytes, oc, val_size));
        let new_vals_raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", new_vals_raw, new_val_bytes));
        let new_vals = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", new_vals, new_vals_raw, val_llvm));

        let has_len = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i64 {}, 0", has_len, ol));
        let copy_label = self.block_label("map_cow_copy");
        let after_copy_label = self.block_label("map_cow_after_copy");
        self.line(&format!("  br i1 {}, label %{}, label %{}", has_len, copy_label, after_copy_label));

        self.open_block(&copy_label);
        let old_key_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", old_key_bytes, ol, key_size));
        let old_keys_raw = self.tmp_name();
        self.line(&format!("  {} = bitcast {}* {} to i8*", old_keys_raw, key_llvm, ok));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_keys_raw, old_keys_raw, old_key_bytes));
        let old_val_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", old_val_bytes, ol, val_size));
        let old_vals_raw = self.tmp_name();
        self.line(&format!("  {} = bitcast {}* {} to i8*", old_vals_raw, val_llvm, ov));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_vals_raw, old_vals_raw, old_val_bytes));
        if self.contains_rc(key_ty) || self.contains_rc(val_ty) {
            let i_ptr = self.tmp_name();
            self.line(&format!("  {} = alloca i64", i_ptr));
            self.line(&format!("  store i64 0, i64* {}", i_ptr));
            let cond_label = self.block_label("map_cow_retain_cond");
            let body_label = self.block_label("map_cow_retain_body");
            let retain_end_label = self.block_label("map_cow_retain_end");
            self.line(&format!("  br label %{}", cond_label));
            self.open_block(&cond_label);
            let i_reg = self.tmp_name();
            self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
            let cmp = self.tmp_name();
            self.line(&format!("  {} = icmp slt i64 {}, {}", cmp, i_reg, ol));
            self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, body_label, retain_end_label));
            self.open_block(&body_label);
            if self.contains_rc(key_ty) {
                let key_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", key_ptr, key_llvm, key_llvm, new_keys, i_reg));
                self.emit_retain_at(&key_ptr, key_ty);
            }
            if self.contains_rc(val_ty) {
                let val_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", val_ptr, val_llvm, val_llvm, new_vals, i_reg));
                self.emit_retain_at(&val_ptr, val_ty);
            }
            let i_next = self.tmp_name();
            self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
            self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
            self.line(&format!("  br label %{}", cond_label));
            self.open_block(&retain_end_label);
        }
        self.line(&format!("  br label %{}", after_copy_label));

        self.open_block(&after_copy_label);
        let nk_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", nk_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store {}* {}, {}** {}", key_llvm, new_keys, key_llvm, nk_field));
        let nv_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", nv_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store {}* {}, {}** {}", val_llvm, new_vals, val_llvm, nv_field));
        let nl_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", nl_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store i64 {}, i64* {}", ol, nl_field));
        let nc_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 3", nc_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store i64 {}, i64* {}", oc, nc_field));

        self.line(&format!("  call void @star_rc_release(i8* {})", obj));
        self.line(&format!("  store i8* {}, i8** {}", new_raw, slot_ptr));
        self.line(&format!("  br label %{}", done_label));

        self.open_block(&done_label);
    }

    /// Read path: resolve `base`'s `(keys, vals, len)`, no CoW check, `null`
    /// reading as empty. Mirrors `Codegen::set_fields`.
    fn map_fields(&mut self, base: &TypedExpr, key_ty: &Ty, val_ty: &Ty) -> (String, String, String) {
        let slot_ptr = self.emit_place(base);
        let obj = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", obj, slot_ptr));

        let key_llvm = self.llvm_ty(key_ty);
        let val_llvm = self.llvm_ty(val_ty);
        let payload_ty = self.map_payload_llvm_ty(key_ty, val_ty);

        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, obj));
        let null_label = self.block_label("map_read_null");
        let real_label = self.block_label("map_read_real");
        let end_label = self.block_label("map_read_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, null_label, real_label));

        self.open_block(&null_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&real_label);
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload, obj, payload_ty));
        let keys_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", keys_field, payload_ty, payload_ty, payload));
        let keys_real = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", keys_real, key_llvm, key_llvm, keys_field));
        let vals_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", vals_field, payload_ty, payload_ty, payload));
        let vals_real = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", vals_real, val_llvm, val_llvm, vals_field));
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", len_field, payload_ty, payload_ty, payload));
        let len_real = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len_real, len_field));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let keys = self.tmp_name();
        self.line(&format!("  {} = phi {}* [ null, %{} ], [ {}, %{} ]", keys, key_llvm, null_label, keys_real, real_label));
        let vals = self.tmp_name();
        self.line(&format!("  {} = phi {}* [ null, %{} ], [ {}, %{} ]", vals, val_llvm, null_label, vals_real, real_label));
        let len = self.tmp_name();
        self.line(&format!("  {} = phi i64 [ 0, %{} ], [ {}, %{} ]", len, null_label, len_real, real_label));

        (keys, vals, len)
    }

    /// Mutating path: `emit_map_ensure_unique` first. Mirrors
    /// `Codegen::set_fields_mut`.
    fn map_fields_mut(&mut self, base: &TypedExpr, key_ty: &Ty, val_ty: &Ty) -> (String, String, String, String, String, String, String) {
        let key_llvm = self.llvm_ty(key_ty);
        let val_llvm = self.llvm_ty(val_ty);
        let payload_ty = self.map_payload_llvm_ty(key_ty, val_ty);
        let slot_ptr = self.emit_place(base);
        self.emit_map_ensure_unique(&slot_ptr, key_ty, val_ty);

        let obj = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", obj, slot_ptr));
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload, obj, payload_ty));

        let keys_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", keys_field, payload_ty, payload_ty, payload));
        let keys = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", keys, key_llvm, key_llvm, keys_field));
        let vals_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", vals_field, payload_ty, payload_ty, payload));
        let vals = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", vals, val_llvm, val_llvm, vals_field));
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", len_field, payload_ty, payload_ty, payload));
        let len = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len, len_field));
        let cap_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 3", cap_field, payload_ty, payload_ty, payload));

        (keys, keys_field, vals, vals_field, len, len_field, cap_field)
    }

    /// Mirrors `Codegen::set`'s private `emit_linear_find`, scanning `keys`
    /// instead of a single element array.
    fn emit_linear_find_key(&mut self, keys: &str, len: &str, key_ty: &Ty, needle: &str) -> (String, String) {
        let key_llvm = self.llvm_ty(key_ty);
        let eq_fn = self.eq_fn_name(key_ty);

        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));

        let cond_label = self.block_label("map_find_cond");
        let body_label = self.block_label("map_find_body");
        let eq_check_label = self.block_label("map_find_eq_check");
        let next_label = self.block_label("map_find_next");
        let end_label = self.block_label("map_find_end");

        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&cond_label);
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
        let in_range = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", in_range, i_reg, len));
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_range, body_label, end_label));

        self.open_block(&body_label);
        let key_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", key_ptr, key_llvm, key_llvm, keys, i_reg));
        let key_val = self.tmp_name();
        self.line(&format!("  {} = load {}, {}* {}", key_val, key_llvm, key_llvm, key_ptr));
        self.line(&format!("  br label %{}", eq_check_label));

        self.open_block(&eq_check_label);
        let is_eq = self.tmp_name();
        self.line(&format!("  {} = call i1 @{}({} {}, {} {})", is_eq, eq_fn, key_llvm, key_val, key_llvm, needle));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_eq, end_label, next_label));

        self.open_block(&next_label);
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&end_label);
        // Same reasoning as `Codegen::set`'s `emit_linear_find`: re-loading
        // `i_ptr` here is correct regardless of which predecessor branch was
        // taken (loop-exhausted vs. found-a-match), with no `phi` needed.
        let final_i = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", final_i, i_ptr));
        let found = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", found, final_i, len));
        (found, final_i)
    }

    /// Construct a payload/fieldless enum value from already-evaluated
    /// `(tagged-value-string, Ty)` operands -- shared by `get`/`remove`'s
    /// `Option<V>` construction. Mirrors `TypedExpr::EnumVariant`'s codegen
    /// shape in `crate::codegen::expr` exactly; kept as its own copy (rather
    /// than refactoring that arm to delegate here) to avoid touching
    /// already-proven enum-construction codegen for this pass.
    fn emit_construct_enum_variant(&mut self, enum_name: &str, variant: &str, payload: &[(String, Ty)]) -> String {
        let idx = self.enum_variant_index(enum_name, variant);
        if !self.enum_is_payload(enum_name) {
            return format!("i32 {}", idx);
        }
        let enum_ty = format!("%{}", enum_name);
        let ptr = self.tmp_name();
        self.line(&format!("  {} = alloca {}", ptr, enum_ty));
        let tag_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", tag_gep, enum_ty, enum_ty, ptr));
        self.line(&format!("  store i32 {}, i32* {}", idx, tag_gep));
        if !payload.is_empty() {
            let words = self.enum_payload_words(enum_name);
            let payload_gep = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", payload_gep, enum_ty, enum_ty, ptr));
            let variant_ty = self.enum_variant_payload_llvm_ty(enum_name, idx);
            let variant_ptr = self.tmp_name();
            self.line(&format!("  {} = bitcast [{} x i64]* {} to {}*", variant_ptr, words, payload_gep, variant_ty));
            for (i, (val, ty)) in payload.iter().enumerate() {
                let ats = self.llvm_ty(ty);
                let clean_val = self.untag(val, ty);
                let field_gep = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", field_gep, variant_ty, variant_ty, variant_ptr, i as u32));
                self.line(&format!("  store {} {}, {}* {}", ats, clean_val, ats, field_gep));
            }
        }
        let loaded = self.tmp_name();
        self.line(&format!("  {} = load {}, {}* {}", loaded, enum_ty, enum_ty, ptr));
        format!("{} {}", enum_ty, loaded)
    }

    /// `map.insert(k,v)` / `.get(k)` / `.remove(k)` / `.contains(k)` /
    /// `.len()`. `ret_ty` is the method's checked return type -- for
    /// `get`/`remove` this is `Ty::Enum(mangled_option)`, needed to know
    /// which concrete `Option<V>` instantiation to construct.
    pub(super) fn emit_map_method(&mut self, base: &TypedExpr, method: MapMethod, args: &[TypedExpr], key_ty: &Ty, val_ty: &Ty, ret_ty: &Ty) -> String {
        let key_llvm = self.llvm_ty(key_ty);
        let val_llvm = self.llvm_ty(val_ty);

        match method {
            MapMethod::Len => {
                let (_, _, len) = self.map_fields(base, key_ty, val_ty);
                let len32 = self.tmp_name();
                self.line(&format!("  {} = trunc i64 {} to i32", len32, len));
                format!("i32 {}", len32)
            }
            MapMethod::Contains => {
                let (keys, _, len) = self.map_fields(base, key_ty, val_ty);
                let val = self.emit_expr(&args[0]);
                let needle = self.untag(&val, key_ty);
                let (found, _) = self.emit_linear_find_key(&keys, &len, key_ty, &needle);
                format!("i1 {}", found)
            }
            MapMethod::Get => {
                let Ty::Enum(mangled) = ret_ty.clone() else {
                    self.err("internal error: Map::get return type is not Option<V>", crate::diagnostics::Span::dummy());
                    return "%undef".into();
                };
                let (keys, vals, len) = self.map_fields(base, key_ty, val_ty);
                let key_val = self.emit_expr(&args[0]);
                let needle = self.untag(&key_val, key_ty);
                let (found, idx) = self.emit_linear_find_key(&keys, &len, key_ty, &needle);

                let some_label = self.block_label("map_get_some");
                let none_label = self.block_label("map_get_none");
                let end_label = self.block_label("map_get_end");
                self.line(&format!("  br i1 {}, label %{}, label %{}", found, some_label, none_label));

                self.open_block(&some_label);
                let val_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", val_ptr, val_llvm, val_llvm, vals, idx));
                let val_val = self.tmp_name();
                self.line(&format!("  {} = load {}, {}* {}", val_val, val_llvm, val_llvm, val_ptr));
                // A read hands out an independent copy while the map keeps
                // its own reference -- retain (no-op unless `val_ty` is
                // RC-bearing), same convention as `Codegen::emit_list_index`.
                self.emit_retain_at(&val_ptr, val_ty);
                let some_val = self.emit_construct_enum_variant(&mangled, "Some", &[(format!("{} {}", val_llvm, val_val), val_ty.clone())]);
                let some_reg = self.reg_of(&some_val);
                let some_pred = self.current_label.clone();
                self.line(&format!("  br label %{}", end_label));

                self.open_block(&none_label);
                let none_val = self.emit_construct_enum_variant(&mangled, "None", &[]);
                let none_reg = self.reg_of(&none_val);
                let none_pred = self.current_label.clone();
                self.line(&format!("  br label %{}", end_label));

                self.open_block(&end_label);
                let opt_ty = self.llvm_ty(&Ty::Enum(mangled));
                let result = self.tmp_name();
                self.line(&format!("  {} = phi {} [ {}, %{} ], [ {}, %{} ]", result, opt_ty, some_reg, some_pred, none_reg, none_pred));
                format!("{} {}", opt_ty, result)
            }
            MapMethod::Remove => {
                let Ty::Enum(mangled) = ret_ty.clone() else {
                    self.err("internal error: Map::remove return type is not Option<V>", crate::diagnostics::Span::dummy());
                    return "%undef".into();
                };
                let (keys, _, vals, _, len, len_field, _) = self.map_fields_mut(base, key_ty, val_ty);
                let key_val = self.emit_expr(&args[0]);
                let needle = self.untag(&key_val, key_ty);
                let (found, idx) = self.emit_linear_find_key(&keys, &len, key_ty, &needle);

                let some_label = self.block_label("map_remove_some");
                let none_label = self.block_label("map_remove_none");
                let end_label = self.block_label("map_remove_end");
                self.line(&format!("  br i1 {}, label %{}, label %{}", found, some_label, none_label));

                self.open_block(&some_label);
                let key_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", key_ptr, key_llvm, key_llvm, keys, idx));
                let val_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", val_ptr, val_llvm, val_llvm, vals, idx));
                let removed_val = self.tmp_name();
                self.line(&format!("  {} = load {}, {}* {}", removed_val, val_llvm, val_llvm, val_ptr));
                self.emit_release_at(&key_ptr, key_ty);
                let new_len = self.tmp_name();
                self.line(&format!("  {} = sub i64 {}, 1", new_len, len));
                let last_key_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", last_key_ptr, key_llvm, key_llvm, keys, new_len));
                let last_key_val = self.tmp_name();
                self.line(&format!("  {} = load {}, {}* {}", last_key_val, key_llvm, key_llvm, last_key_ptr));
                let last_val_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", last_val_ptr, val_llvm, val_llvm, vals, new_len));
                let last_val_val = self.tmp_name();
                self.line(&format!("  {} = load {}, {}* {}", last_val_val, val_llvm, val_llvm, last_val_ptr));
                // Swap-remove both parallel arrays in lockstep (harmless
                // self-store when `idx == new_len`); key/value order is not
                // preserved. The removed value's own reference (retained
                // just below into the returned `Some(v)`) is handed to the
                // caller, so it is *not* released here -- only the removed
                // key's storage slot is (its RC content, if any, has no
                // further use once removed).
                self.line(&format!("  store {} {}, {}* {}", key_llvm, last_key_val, key_llvm, key_ptr));
                self.line(&format!("  store {} {}, {}* {}", val_llvm, last_val_val, val_llvm, val_ptr));
                self.line(&format!("  store i64 {}, i64* {}", new_len, len_field));
                self.emit_retain_at(&val_ptr, val_ty);
                let some_val = self.emit_construct_enum_variant(&mangled, "Some", &[(format!("{} {}", val_llvm, removed_val), val_ty.clone())]);
                let some_reg = self.reg_of(&some_val);
                let some_pred = self.current_label.clone();
                self.line(&format!("  br label %{}", end_label));

                self.open_block(&none_label);
                let none_val = self.emit_construct_enum_variant(&mangled, "None", &[]);
                let none_reg = self.reg_of(&none_val);
                let none_pred = self.current_label.clone();
                self.line(&format!("  br label %{}", end_label));

                self.open_block(&end_label);
                let opt_ty = self.llvm_ty(&Ty::Enum(mangled));
                let result = self.tmp_name();
                self.line(&format!("  {} = phi {} [ {}, %{} ], [ {}, %{} ]", result, opt_ty, some_reg, some_pred, none_reg, none_pred));
                format!("{} {}", opt_ty, result)
            }
            MapMethod::Insert => {
                let (_, keys_field, _, vals_field, len, len_field, cap_field) = self.map_fields_mut(base, key_ty, val_ty);
                let key_val = self.emit_expr(&args[0]);
                let clean_key = self.untag(&key_val, key_ty);
                let val_val = self.emit_expr(&args[1]);
                let clean_val = self.untag(&val_val, val_ty);

                let keys0 = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", keys0, key_llvm, key_llvm, keys_field));
                let (found, idx) = self.emit_linear_find_key(&keys0, &len, key_ty, &clean_key);

                let overwrite_label = self.block_label("map_insert_overwrite");
                let insert_label = self.block_label("map_insert_new");
                let after_label = self.block_label("map_insert_after");
                self.line(&format!("  br i1 {}, label %{}, label %{}", found, overwrite_label, insert_label));

                self.open_block(&overwrite_label);
                let vals0 = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", vals0, val_llvm, val_llvm, vals_field));
                let old_val_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", old_val_ptr, val_llvm, val_llvm, vals0, idx));
                // Release the overwritten value *after* the new value is
                // already computed (mirrors `Codegen::store_list_index`'s
                // release-then-store ordering), so `m.insert(k, m.get(k))`
                // (an unlikely but legal shape) stays safe.
                self.emit_release_at(&old_val_ptr, val_ty);
                self.line(&format!("  store {} {}, {}* {}", val_llvm, clean_val, val_llvm, old_val_ptr));
                self.line(&format!("  br label %{}", after_label));

                self.open_block(&insert_label);
                let cap = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", cap, cap_field));
                let needs_grow = self.tmp_name();
                self.line(&format!("  {} = icmp sge i64 {}, {}", needs_grow, len, cap));
                let grow_label = self.block_label("map_insert_grow");
                let store_label = self.block_label("map_insert_store");
                self.line(&format!("  br i1 {}, label %{}, label %{}", needs_grow, grow_label, store_label));

                self.open_block(&grow_label);
                let doubled = self.tmp_name();
                self.line(&format!("  {} = mul i64 {}, 2", doubled, cap));
                let has_cap = self.tmp_name();
                self.line(&format!("  {} = icmp sgt i64 {}, 0", has_cap, doubled));
                let new_cap = self.tmp_name();
                self.line(&format!("  {} = select i1 {}, i64 {}, i64 1", new_cap, has_cap, doubled));

                let key_size = self.emit_sizeof_llvm_ty(&key_llvm);
                let new_key_bytes = self.tmp_name();
                self.line(&format!("  {} = mul i64 {}, {}", new_key_bytes, new_cap, key_size));
                let new_keys_raw = self.tmp_name();
                self.line(&format!("  {} = call i8* @malloc(i64 {})", new_keys_raw, new_key_bytes));
                let new_keys = self.tmp_name();
                self.line(&format!("  {} = bitcast i8* {} to {}*", new_keys, new_keys_raw, key_llvm));

                let val_size = self.emit_sizeof_llvm_ty(&val_llvm);
                let new_val_bytes = self.tmp_name();
                self.line(&format!("  {} = mul i64 {}, {}", new_val_bytes, new_cap, val_size));
                let new_vals_raw = self.tmp_name();
                self.line(&format!("  {} = call i8* @malloc(i64 {})", new_vals_raw, new_val_bytes));
                let new_vals = self.tmp_name();
                self.line(&format!("  {} = bitcast i8* {} to {}*", new_vals, new_vals_raw, val_llvm));

                let had_data = self.tmp_name();
                self.line(&format!("  {} = icmp sgt i64 {}, 0", had_data, cap));
                let copy_label = self.block_label("map_insert_copy");
                let after_copy_label = self.block_label("map_insert_after_copy");
                self.line(&format!("  br i1 {}, label %{}, label %{}", had_data, copy_label, after_copy_label));

                self.open_block(&copy_label);
                let old_keys = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", old_keys, key_llvm, key_llvm, keys_field));
                let old_key_bytes = self.tmp_name();
                self.line(&format!("  {} = mul i64 {}, {}", old_key_bytes, len, key_size));
                let old_keys_raw = self.tmp_name();
                self.line(&format!("  {} = bitcast {}* {} to i8*", old_keys_raw, key_llvm, old_keys));
                self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_keys_raw, old_keys_raw, old_key_bytes));
                self.line(&format!("  call void @free(i8* {})", old_keys_raw));

                let old_vals = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", old_vals, val_llvm, val_llvm, vals_field));
                let old_val_bytes = self.tmp_name();
                self.line(&format!("  {} = mul i64 {}, {}", old_val_bytes, len, val_size));
                let old_vals_raw = self.tmp_name();
                self.line(&format!("  {} = bitcast {}* {} to i8*", old_vals_raw, val_llvm, old_vals));
                self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_vals_raw, old_vals_raw, old_val_bytes));
                self.line(&format!("  call void @free(i8* {})", old_vals_raw));
                self.line(&format!("  br label %{}", after_copy_label));

                self.open_block(&after_copy_label);
                self.line(&format!("  store {}* {}, {}** {}", key_llvm, new_keys, key_llvm, keys_field));
                self.line(&format!("  store {}* {}, {}** {}", val_llvm, new_vals, val_llvm, vals_field));
                self.line(&format!("  store i64 {}, i64* {}", new_cap, cap_field));
                self.line(&format!("  br label %{}", store_label));

                self.open_block(&store_label);
                let keys_now = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", keys_now, key_llvm, key_llvm, keys_field));
                let vals_now = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", vals_now, val_llvm, val_llvm, vals_field));
                let new_key_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", new_key_ptr, key_llvm, key_llvm, keys_now, len));
                self.line(&format!("  store {} {}, {}* {}", key_llvm, clean_key, key_llvm, new_key_ptr));
                let new_val_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", new_val_ptr, val_llvm, val_llvm, vals_now, len));
                self.line(&format!("  store {} {}, {}* {}", val_llvm, clean_val, val_llvm, new_val_ptr));
                let new_len = self.tmp_name();
                self.line(&format!("  {} = add i64 {}, 1", new_len, len));
                self.line(&format!("  store i64 {}, i64* {}", new_len, len_field));
                self.line(&format!("  br label %{}", after_label));

                self.open_block(&after_label);
                "%undef".into()
            }
        }
    }
}
