//! `Map<K,V>` codegen: a growable key/value map lowered to a
//! reference-counted, copy-on-write `i8*` object pointer, same allocation
//! scheme as `List<T>`/`Set<T>` (see `crate::codegen::list`'s doc comment),
//! pointing past a `star_rc_alloc` header at a `{ K* keys, V* vals, i8*
//! states, i64 len, i64 cap, i64 tomb }` payload -- three parallel arrays
//! (keys/vals/states) grown/cloned/rehashed in lockstep instead of `Set<T>`'s
//! two (see `crate::codegen::set`'s doc comment for the open-addressing
//! scheme this shares verbatim: `states[i]` one of `HT_EMPTY`(0)/
//! `HT_OCCUPIED`(1)/`HT_TOMBSTONE`(2), `keys[i]`/`vals[i]` meaningful only
//! when `states[i] == HT_OCCUPIED`). `insert`/`get`/`remove`/`contains` hash
//! the key (`crate::codegen::hash`) and linear-probe
//! (`Codegen::emit_ht_probe`) for it -- average `O(1)` instead of the
//! previous `O(n)` linear scan.
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
        format!("{{ {}*, {}*, i8*, i64, i64, i64 }}", self.llvm_ty(key_ty), self.llvm_ty(val_ty))
    }

    /// Mirrors `Codegen::list_release_thunk_operand`/`set_release_thunk_operand`;
    /// releases every RC-bearing key *and* value stored in an `OCCUPIED`
    /// slot before freeing all three buffers -- walks the full `cap`-length
    /// `states` array, not `0..len` (see `set_release_thunk_operand`'s
    /// updated doc comment for why `len` alone no longer identifies which
    /// slots are live).
    fn map_release_thunk_operand(&mut self, key_ty: &Ty, val_ty: &Ty) -> String {
        // Length-prefixed the same way `Codegen::mangle_ty`'s own `Ty::Map`
        // arm is, and for the same reason: a bare `mangle_ty(key)_mangle_ty(val)`
        // join is ambiguous when a struct name contains `_` (see that arm's
        // doc comment) -- this cache key needs the identical fix
        // independently, since it's built directly here rather than by
        // calling `mangle_ty(&Ty::Map(key_ty, val_ty))`.
        let km = self.mangle_ty(key_ty);
        let key = format!("{}_{}{}", km.len(), km, self.mangle_ty(val_ty));
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
        let states_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", states_field, payload_ty, payload_ty, payload));
        let states = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", states, states_field));
        let cap_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 4", cap_field, payload_ty, payload_ty, payload));
        let cap = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", cap, cap_field));

        if key_has_rc || val_has_rc {
            let i_ptr = self.tmp_name();
            self.line(&format!("  {} = alloca i64", i_ptr));
            self.line(&format!("  store i64 0, i64* {}", i_ptr));

            let cond_label = self.block_label("map_release_cond");
            let body_label = self.block_label("map_release_body");
            let occ_label = self.block_label("map_release_occ");
            let next_label = self.block_label("map_release_next");
            let end_label = self.block_label("map_release_end");
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
            self.line(&format!("  br label %{}", next_label));

            self.open_block(&next_label);
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

    /// `Map<K,V>()`: the empty map is `null`, mirroring `List<T>()`.
    pub(super) fn emit_map_new(&mut self, _key_ty: &Ty, _val_ty: &Ty) -> String {
        "i8* null".into()
    }

    /// Copy-on-write gate for every mutating map operation. Mirrors
    /// `Codegen::emit_set_ensure_unique` exactly (see its updated doc
    /// comment for why a CoW clone is a same-`cap` structural copy, not a
    /// rehash), cloning all three parallel arrays together.
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
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 48, i8* {})", raw0, release_fn0));
        let payload0 = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload0, raw0, payload_ty));
        let k0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", k0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store {}* null, {}** {}", key_llvm, key_llvm, k0));
        let v0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", v0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store {}* null, {}** {}", val_llvm, val_llvm, v0));
        let s0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", s0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store i8* null, i8** {}", s0));
        let l0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 3", l0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store i64 0, i64* {}", l0));
        let c0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 4", c0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store i64 0, i64* {}", c0));
        let tm0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 5", tm0, payload_ty, payload_ty, payload0));
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
        let os_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", os_field, payload_ty, payload_ty, old_payload));
        let os = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", os, os_field));
        let ol_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 3", ol_field, payload_ty, payload_ty, old_payload));
        let ol = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", ol, ol_field));
        let oc_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 4", oc_field, payload_ty, payload_ty, old_payload));
        let oc = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", oc, oc_field));
        let otm_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 5", otm_field, payload_ty, payload_ty, old_payload));
        let otm = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", otm, otm_field));

        let release_fn1 = self.map_release_thunk_operand(key_ty, val_ty);
        let new_raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 48, i8* {})", new_raw, release_fn1));
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
        let new_states = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", new_states, oc));

        let has_cap = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i64 {}, 0", has_cap, oc));
        let copy_label = self.block_label("map_cow_copy");
        let after_copy_label = self.block_label("map_cow_after_copy");
        self.line(&format!("  br i1 {}, label %{}, label %{}", has_cap, copy_label, after_copy_label));

        self.open_block(&copy_label);
        let old_key_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", old_key_bytes, oc, key_size));
        let old_keys_raw = self.tmp_name();
        self.line(&format!("  {} = bitcast {}* {} to i8*", old_keys_raw, key_llvm, ok));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_keys_raw, old_keys_raw, old_key_bytes));
        let old_val_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", old_val_bytes, oc, val_size));
        let old_vals_raw = self.tmp_name();
        self.line(&format!("  {} = bitcast {}* {} to i8*", old_vals_raw, val_llvm, ov));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_vals_raw, old_vals_raw, old_val_bytes));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_states, os, oc));
        if self.contains_rc(key_ty) || self.contains_rc(val_ty) {
            let i_ptr = self.tmp_name();
            self.line(&format!("  {} = alloca i64", i_ptr));
            self.line(&format!("  store i64 0, i64* {}", i_ptr));
            let cond_label = self.block_label("map_cow_retain_cond");
            let body_label = self.block_label("map_cow_retain_body");
            let occ_label = self.block_label("map_cow_retain_occ");
            let next_label = self.block_label("map_cow_retain_next");
            let retain_end_label = self.block_label("map_cow_retain_end");
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
        let nk_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", nk_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store {}* {}, {}** {}", key_llvm, new_keys, key_llvm, nk_field));
        let nv_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", nv_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store {}* {}, {}** {}", val_llvm, new_vals, val_llvm, nv_field));
        let ns_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", ns_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store i8* {}, i8** {}", new_states, ns_field));
        let nl_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 3", nl_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store i64 {}, i64* {}", ol, nl_field));
        let nc_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 4", nc_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store i64 {}, i64* {}", oc, nc_field));
        let ntm_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 5", ntm_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store i64 {}, i64* {}", otm, ntm_field));

        self.line(&format!("  call void @star_rc_release(i8* {})", obj));
        self.line(&format!("  store i8* {}, i8** {}", new_raw, slot_ptr));
        self.line(&format!("  br label %{}", done_label));

        self.open_block(&done_label);
    }

    /// Read path: resolve `base`'s `(keys, vals, states, len, cap)`, no CoW
    /// check, `null` reading as empty. Mirrors `Codegen::set_fields`.
    /// Resolves `base` through `Codegen::emit_read_place`, not `emit_place`,
    /// so a receiver reached through a list index (`maps[0].get(k)`,
    /// `points[0].my_map.get(k)`) never spuriously CoW-clones the outer list
    /// as a side effect of this read (same bug class as the already-fixed
    /// `list_fields`/`list_index_read_obj`).
    fn map_fields(&mut self, base: &TypedExpr, key_ty: &Ty, val_ty: &Ty) -> (String, String, String, String, String) {
        let slot_ptr = self.emit_read_place(base);
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
        let states_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", states_field, payload_ty, payload_ty, payload));
        let states_real = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", states_real, states_field));
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 3", len_field, payload_ty, payload_ty, payload));
        let len_real = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len_real, len_field));
        let cap_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 4", cap_field, payload_ty, payload_ty, payload));
        let cap_real = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", cap_real, cap_field));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let keys = self.tmp_name();
        self.line(&format!("  {} = phi {}* [ null, %{} ], [ {}, %{} ]", keys, key_llvm, null_label, keys_real, real_label));
        let vals = self.tmp_name();
        self.line(&format!("  {} = phi {}* [ null, %{} ], [ {}, %{} ]", vals, val_llvm, null_label, vals_real, real_label));
        let states = self.tmp_name();
        self.line(&format!("  {} = phi i8* [ null, %{} ], [ {}, %{} ]", states, null_label, states_real, real_label));
        let len = self.tmp_name();
        self.line(&format!("  {} = phi i64 [ 0, %{} ], [ {}, %{} ]", len, null_label, len_real, real_label));
        let cap = self.tmp_name();
        self.line(&format!("  {} = phi i64 [ 0, %{} ], [ {}, %{} ]", cap, null_label, cap_real, real_label));

        (keys, vals, states, len, cap)
    }

    /// Mutating path: `emit_map_ensure_unique` first. Mirrors
    /// `Codegen::set_fields_mut`.
    #[allow(clippy::type_complexity)]
    fn map_fields_mut(&mut self, base: &TypedExpr, key_ty: &Ty, val_ty: &Ty) -> (String, String, String, String, String, String, String, String, String, String, String, String) {
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
        let states_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", states_field, payload_ty, payload_ty, payload));
        let states = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", states, states_field));
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 3", len_field, payload_ty, payload_ty, payload));
        let len = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len, len_field));
        let cap_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 4", cap_field, payload_ty, payload_ty, payload));
        let cap = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", cap, cap_field));
        let tomb_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 5", tomb_field, payload_ty, payload_ty, payload));
        let tomb = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", tomb, tomb_field));

        (keys, keys_field, vals, vals_field, states, states_field, len, len_field, cap, cap_field, tomb, tomb_field)
    }

    /// Double `keys`/`vals`/`states` (or allocate an initial `cap = 8` table
    /// from empty) and rehash every currently-`OCCUPIED` slot into the fresh
    /// table. Mirrors `Codegen::emit_set_grow` (see its doc comment for why
    /// this must rehash rather than `memcpy`), just moving a key *and* its
    /// paired value together instead of one bare element.
    #[allow(clippy::too_many_arguments)]
    fn emit_map_grow(&mut self, keys_field: &str, vals_field: &str, states_field: &str, cap_field: &str, tomb_field: &str, cap: &str, key_ty: &Ty, val_ty: &Ty) {
        let key_llvm = self.llvm_ty(key_ty);
        let val_llvm = self.llvm_ty(val_ty);
        let key_size = self.emit_sizeof_llvm_ty(&key_llvm);
        let val_size = self.emit_sizeof_llvm_ty(&val_llvm);

        let new_cap = self.emit_ht_grown_cap(cap);
        let new_mask = self.tmp_name();
        self.line(&format!("  {} = sub i64 {}, 1", new_mask, new_cap));

        let new_key_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", new_key_bytes, new_cap, key_size));
        let new_keys_raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", new_keys_raw, new_key_bytes));
        let new_keys = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", new_keys, new_keys_raw, key_llvm));
        let new_val_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", new_val_bytes, new_cap, val_size));
        let new_vals_raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", new_vals_raw, new_val_bytes));
        let new_vals = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", new_vals, new_vals_raw, val_llvm));
        let new_states = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", new_states, new_cap));
        self.emit_fill_i8(&new_states, &new_cap, 0);

        let old_keys = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", old_keys, key_llvm, key_llvm, keys_field));
        let old_vals = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", old_vals, val_llvm, val_llvm, vals_field));
        let old_states = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", old_states, states_field));

        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));
        let cond_label = self.block_label("map_grow_cond");
        let body_label = self.block_label("map_grow_body");
        let occ_label = self.block_label("map_grow_occ");
        let next_label = self.block_label("map_grow_next");
        let end_label = self.block_label("map_grow_end");
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
        let key_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", key_ptr, key_llvm, key_llvm, old_keys, i_reg));
        let key_val = self.tmp_name();
        self.line(&format!("  {} = load {}, {}* {}", key_val, key_llvm, key_llvm, key_ptr));
        let val_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", val_ptr, val_llvm, val_llvm, old_vals, i_reg));
        let val_val = self.tmp_name();
        self.line(&format!("  {} = load {}, {}* {}", val_val, val_llvm, val_llvm, val_ptr));
        let hash_fn = self.hash_fn_name(key_ty);
        let h = self.tmp_name();
        self.line(&format!("  {} = call i64 @{}({} {})", h, hash_fn, key_llvm, key_val));
        let start = self.tmp_name();
        self.line(&format!("  {} = and i64 {}, {}", start, h, new_mask));
        let new_slot = self.emit_ht_first_empty(&new_states, &new_cap, &new_mask, &start);
        let new_st_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", new_st_ptr, new_states, new_slot));
        self.line(&format!("  store i8 1, i8* {}", new_st_ptr));
        let new_key_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", new_key_ptr, key_llvm, key_llvm, new_keys, new_slot));
        self.line(&format!("  store {} {}, {}* {}", key_llvm, key_val, key_llvm, new_key_ptr));
        let new_val_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", new_val_ptr, val_llvm, val_llvm, new_vals, new_slot));
        self.line(&format!("  store {} {}, {}* {}", val_llvm, val_val, val_llvm, new_val_ptr));
        self.line(&format!("  br label %{}", next_label));

        self.open_block(&next_label);
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&end_label);
        let old_keys_i8 = self.tmp_name();
        self.line(&format!("  {} = bitcast {}* {} to i8*", old_keys_i8, key_llvm, old_keys));
        self.line(&format!("  call void @free(i8* {})", old_keys_i8));
        let old_vals_i8 = self.tmp_name();
        self.line(&format!("  {} = bitcast {}* {} to i8*", old_vals_i8, val_llvm, old_vals));
        self.line(&format!("  call void @free(i8* {})", old_vals_i8));
        self.line(&format!("  call void @free(i8* {})", old_states));

        self.line(&format!("  store {}* {}, {}** {}", key_llvm, new_keys, key_llvm, keys_field));
        self.line(&format!("  store {}* {}, {}** {}", val_llvm, new_vals, val_llvm, vals_field));
        self.line(&format!("  store i8* {}, i8** {}", new_states, states_field));
        self.line(&format!("  store i64 {}, i64* {}", new_cap, cap_field));
        self.line(&format!("  store i64 0, i64* {}", tomb_field));
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
            let elem = self.enum_payload_elem_ty(enum_name);
            let payload_gep = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", payload_gep, enum_ty, enum_ty, ptr));
            let variant_ty = self.enum_variant_payload_llvm_ty(enum_name, idx);
            let variant_ptr = self.tmp_name();
            self.line(&format!("  {} = bitcast [{} x {}]* {} to {}*", variant_ptr, words, elem, payload_gep, variant_ty));
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
                let (_, _, _, len, _) = self.map_fields(base, key_ty, val_ty);
                let len32 = self.tmp_name();
                self.line(&format!("  {} = trunc i64 {} to i32", len32, len));
                format!("i32 {}", len32)
            }
            MapMethod::Contains => {
                let val = self.emit_expr(&args[0]);
                let needle = self.untag(&val, key_ty);
                // Read fields *after* evaluating `args[0]` -- if it mutates
                // this same map (e.g. `m.contains(pick(m.remove(k)))`), a
                // snapshot taken beforehand would be stale (mirrors
                // `MapMethod::Insert`'s identical fix).
                let (keys, _, states, _, cap) = self.map_fields(base, key_ty, val_ty);
                let mask = self.tmp_name();
                self.line(&format!("  {} = sub i64 {}, 1", mask, cap));
                let hash_fn = self.hash_fn_name(key_ty);
                let h = self.tmp_name();
                self.line(&format!("  {} = call i64 @{}({} {})", h, hash_fn, key_llvm, needle));
                let start = self.tmp_name();
                self.line(&format!("  {} = and i64 {}, {}", start, h, mask));
                let (found, _, _) = self.emit_ht_probe(&states, &keys, &cap, &mask, &start, key_ty, &needle);
                // `needle` is only ever compared against, never stored --
                // release whatever `emit_expr` left us owning (a borrowed
                // read's extra retain, or a fresh construction's sole
                // reference -- see `rc.rs`'s module doc comment for why this
                // is unconditional), or it leaks one reference per call.
                self.emit_release_bare(&needle, key_ty);
                format!("i1 {}", found)
            }
            MapMethod::Get => {
                let Ty::Enum(mangled) = ret_ty.clone() else {
                    self.err("internal error: Map::get return type is not Option<V>", crate::diagnostics::Span::dummy());
                    return "%undef".into();
                };
                let key_val = self.emit_expr(&args[0]);
                let needle = self.untag(&key_val, key_ty);
                // Read fields *after* evaluating `args[0]` -- same
                // stale-snapshot hazard and fix as `MapMethod::Contains`.
                let (keys, vals, states, _len, cap) = self.map_fields(base, key_ty, val_ty);
                let mask = self.tmp_name();
                self.line(&format!("  {} = sub i64 {}, 1", mask, cap));
                let hash_fn = self.hash_fn_name(key_ty);
                let h = self.tmp_name();
                self.line(&format!("  {} = call i64 @{}({} {})", h, hash_fn, key_llvm, needle));
                let start = self.tmp_name();
                self.line(&format!("  {} = and i64 {}, {}", start, h, mask));
                let (found, idx, _) = self.emit_ht_probe(&states, &keys, &cap, &mask, &start, key_ty, &needle);
                // Same reasoning as `MapMethod::Contains` above: `needle` is
                // only ever compared against here, never stored.
                self.emit_release_bare(&needle, key_ty);

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
                let (_, keys_field, _, vals_field, _, states_field, _stale_len, len_field, _stale_cap, cap_field, _stale_tomb, tomb_field) = self.map_fields_mut(base, key_ty, val_ty);
                let key_val = self.emit_expr(&args[0]);
                let needle = self.untag(&key_val, key_ty);

                // Reload fresh (post-`args[0]` evaluation) -- same
                // stale-snapshot hazard `MapMethod::Insert` documents.
                let keys = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", keys, key_llvm, key_llvm, keys_field));
                let vals = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", vals, val_llvm, val_llvm, vals_field));
                let states = self.tmp_name();
                self.line(&format!("  {} = load i8*, i8** {}", states, states_field));
                let cap = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", cap, cap_field));
                let mask = self.tmp_name();
                self.line(&format!("  {} = sub i64 {}, 1", mask, cap));
                let hash_fn = self.hash_fn_name(key_ty);
                let h = self.tmp_name();
                self.line(&format!("  {} = call i64 @{}({} {})", h, hash_fn, key_llvm, needle));
                let start = self.tmp_name();
                self.line(&format!("  {} = and i64 {}, {}", start, h, mask));
                let (found, idx, _) = self.emit_ht_probe(&states, &keys, &cap, &mask, &start, key_ty, &needle);
                // Same reasoning as `MapMethod::Contains` above: `needle` is
                // only ever compared against here, never stored (the key
                // actually stored in the map is released separately, below,
                // when the removed slot itself is torn down).
                self.emit_release_bare(&needle, key_ty);

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
                // Only the removed key's storage slot is released here (its
                // RC content, if any, has no further use once removed).
                // `removed_val` was already loaded above into a register
                // (unaffected by anything below) and moves straight into the
                // returned `Some(v)` with no retain -- the map's own
                // reference to it is being extinguished by this removal, so
                // ownership transfers to the caller net-zero, exactly like
                // `ListMethod::Pop`'s convention.
                self.emit_release_at(&key_ptr, key_ty);
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
                let (_, keys_field, _, vals_field, _, states_field, _stale_len, len_field, _stale_cap, cap_field, _stale_tomb, tomb_field) = self.map_fields_mut(base, key_ty, val_ty);
                let key_val = self.emit_expr(&args[0]);
                let clean_key = self.untag(&key_val, key_ty);
                let val_val = self.emit_expr(&args[1]);
                let clean_val = self.untag(&val_val, val_ty);

                // `_stale_len`/`_stale_cap`/`_stale_tomb` (from
                // `map_fields_mut`, above) were captured *before* evaluating
                // `args[0]`/`args[1]` -- if either argument expression
                // mutates this same map, the real fields in memory have
                // already changed by the time we get here. Reload fresh
                // (mirrors `ListMethod::Push`'s identical fix), or the
                // grow-check/probe/insert below would all use stale values.
                let len = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", len, len_field));
                let cap = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", cap, cap_field));
                let tomb = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", tomb, tomb_field));

                // Grow when the table (including tombstones) would cross
                // 75% load after this insert -- also naturally true when
                // `cap == 0` (a fresh/empty map), so no separate "allocate
                // the first table" case is needed.
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
                let grow_label = self.block_label("map_insert_grow");
                let after_grow_label = self.block_label("map_insert_after_grow");
                self.line(&format!("  br i1 {}, label %{}, label %{}", needs_grow, grow_label, after_grow_label));

                self.open_block(&grow_label);
                self.emit_map_grow(&keys_field, &vals_field, &states_field, &cap_field, &tomb_field, &cap, key_ty, val_ty);
                self.line(&format!("  br label %{}", after_grow_label));

                self.open_block(&after_grow_label);
                let keys = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", keys, key_llvm, key_llvm, keys_field));
                let vals = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", vals, val_llvm, val_llvm, vals_field));
                let states = self.tmp_name();
                self.line(&format!("  {} = load i8*, i8** {}", states, states_field));
                let cap2 = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", cap2, cap_field));
                let mask = self.tmp_name();
                self.line(&format!("  {} = sub i64 {}, 1", mask, cap2));
                let hash_fn = self.hash_fn_name(key_ty);
                let h = self.tmp_name();
                self.line(&format!("  {} = call i64 @{}({} {})", h, hash_fn, key_llvm, clean_key));
                let start = self.tmp_name();
                self.line(&format!("  {} = and i64 {}, {}", start, h, mask));
                let (found, idx, islot) = self.emit_ht_probe(&states, &keys, &cap2, &mask, &start, key_ty, &clean_key);

                let overwrite_label = self.block_label("map_insert_overwrite");
                let insert_label = self.block_label("map_insert_new");
                let after_label = self.block_label("map_insert_after");
                self.line(&format!("  br i1 {}, label %{}, label %{}", found, overwrite_label, insert_label));

                self.open_block(&overwrite_label);
                // The map already has an equal key in this slot, so
                // `clean_key` itself is never stored (only `clean_val`
                // replaces the old value below) -- release whatever
                // `emit_expr` left us owning, same reasoning as
                // `MapMethod::Contains`, or it leaks one reference per
                // overwriting `insert` call. Scoped to just this branch: the
                // sibling `insert_label` branch below does store `clean_key`
                // into a fresh slot, transferring that same reference to the
                // map instead of releasing it.
                self.emit_release_bare(&clean_key, key_ty);
                let old_val_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", old_val_ptr, val_llvm, val_llvm, vals, idx));
                // Release the overwritten value *after* the new value is
                // already computed (mirrors `Codegen::store_list_index`'s
                // release-then-store ordering), so `m.insert(k, m.get(k))`
                // (an unlikely but legal shape) stays safe.
                self.emit_release_at(&old_val_ptr, val_ty);
                self.line(&format!("  store {} {}, {}* {}", val_llvm, clean_val, val_llvm, old_val_ptr));
                self.line(&format!("  br label %{}", after_label));

                self.open_block(&insert_label);
                let st_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", st_ptr, states, islot));
                let was_tomb = self.tmp_name();
                self.line(&format!("  {} = load i8, i8* {}", was_tomb, st_ptr));
                let is_tomb = self.tmp_name();
                self.line(&format!("  {} = icmp eq i8 {}, 2", is_tomb, was_tomb));
                let dec_tomb_label = self.block_label("map_insert_dec_tomb");
                let store_label = self.block_label("map_insert_store");
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
                let new_key_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", new_key_ptr, key_llvm, key_llvm, keys, islot));
                self.line(&format!("  store {} {}, {}* {}", key_llvm, clean_key, key_llvm, new_key_ptr));
                let new_val_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", new_val_ptr, val_llvm, val_llvm, vals, islot));
                self.line(&format!("  store {} {}, {}* {}", val_llvm, clean_val, val_llvm, new_val_ptr));
                let len_now = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", len_now, len_field));
                let len_new = self.tmp_name();
                self.line(&format!("  {} = add i64 {}, 1", len_new, len_now));
                self.line(&format!("  store i64 {}, i64* {}", len_new, len_field));
                self.line(&format!("  br label %{}", after_label));

                self.open_block(&after_label);
                "%undef".into()
            }
        }
    }
}
