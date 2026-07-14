//! `Table<T>` codegen: a struct-of-arrays table lowered to a
//! reference-counted, copy-on-write `i8*` object pointer -- the same
//! allocation scheme `List<T>`/`Map<K,V>`/`Set<T>` use (see
//! `crate::codegen::list`), pointing past a `star_rc_alloc` header at a
//! `{ i64 len, i64 cap, F0*, F1*, ..., FN-1* }` payload, one parallel
//! growable column per field of `T` (in declaration order) instead of
//! `List<T>`'s single `{ T*, i64, i64 }` buffer.
//!
//! Every mutating operation (`push`, `pop`, index-assignment) grows/shrinks
//! every column in lockstep, sharing one `len`/`cap` pair -- there is no way
//! for one column to observably disagree with another in element count.
//! `let b = a` is an O(1) refcount bump exactly like `List<T>`; every
//! mutating operation first calls `emit_table_ensure_unique`, which clones
//! all `N` column buffers (not just one) if the object isn't uniquely owned.
//!
//! `table[i]`/`table[i] = v` read/write the *whole* element, reassembling it
//! from (or decomposing it into) every column at index `i` via
//! `getelementptr`/`load`/`store` into a scratch `%Struct` alloca -- the same
//! shape `Codegen::emit_expr`'s `StructLit` arm already uses to construct an
//! ordinary struct literal. There is deliberately no dedicated
//! `Codegen::emit_place` support for projecting a single field through a
//! table index (`table[i].field = v`): unlike `List<T>`'s element (one
//! contiguous value at one address), a `Table<T>` element's fields live at
//! independent addresses in independent columns, so `emit_place`'s generic
//! `Field`-base resolution (which assumes a single base pointer to GEP a
//! field offset out of) cannot address it without inventing a new place
//! representation. `table[i].field = v` therefore silently targets a
//! disconnected temporary instead of the real column -- the same accepted
//! gap as any other rvalue struct base with no addressable storage of its
//! own (e.g. a function call's returned-by-value struct) -- while
//! `table[i].field` (a *read*) still works correctly, since materializing a
//! temporary copy to read a field out of is exactly what an ordinary value
//! read does anyway.

use crate::types::{TableMethod, Ty, TypedExpr};

use super::Codegen;

impl Codegen {
    /// Every field type of `struct_name`, in declaration order -- the
    /// column types for `Table<struct_name>`'s payload.
    fn table_field_types(&self, struct_name: &str) -> Vec<Ty> {
        self.struct_field_types.get(struct_name).cloned().unwrap_or_default()
    }

    /// The anonymous LLVM struct type for `Table<T>`'s heap *payload* (as
    /// opposed to `Codegen::llvm_ty`'s `i8*` object-pointer type): `{ i64
    /// len, i64 cap, F0*, F1*, ... }`, one pointer field per column. Always
    /// routed through this helper so every call site agrees byte-for-byte
    /// on the type's textual spelling.
    fn table_payload_llvm_ty(&self, struct_name: &str) -> String {
        let mut parts = vec!["i64".to_string(), "i64".to_string()];
        for f in self.table_field_types(struct_name) {
            parts.push(format!("{}*", self.llvm_ty(&f)));
        }
        format!("{{ {} }}", parts.join(", "))
    }

    /// Lazily generate (and cache, keyed by `Codegen::mangle_ty` of
    /// `Ty::Named(struct_name)`) the `table_release_<mangled>` thunk,
    /// mirroring `Codegen::list_release_thunk_operand` -- just freeing (and,
    /// if the column's field type carries RC content, releasing every live
    /// element of) each of the `N` column buffers instead of one.
    fn table_release_thunk_operand(&mut self, struct_name: &str) -> String {
        let key = self.mangle_ty(&Ty::Named(struct_name.to_string()));
        if let Some(name) = self.table_release_thunks.get(&key).cloned() {
            let reg = self.tmp_name();
            self.line(&format!("  {} = bitcast void (i8*)* @{} to i8*", reg, name));
            return reg;
        }

        let name = format!("table_release_{}", key);
        self.table_release_thunks.insert(key, name.clone());

        let fields = self.table_field_types(struct_name);
        let payload_ty = self.table_payload_llvm_ty(struct_name);

        let saved_ir = std::mem::take(&mut self.ir);
        self.line(&format!("define void @{}(i8* %objp) {{", name));
        self.open_block("entry");
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* %objp to {}*", payload, payload_ty));
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", len_field, payload_ty, payload_ty, payload));
        let len = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len, len_field));

        for (j, fty) in fields.iter().enumerate() {
            let f_llvm = self.llvm_ty(fty);
            let col_field = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", col_field, payload_ty, payload_ty, payload, 2 + j));
            let col = self.tmp_name();
            self.line(&format!("  {} = load {}*, {}** {}", col, f_llvm, f_llvm, col_field));

            if self.contains_rc(fty) {
                let i_ptr = self.tmp_name();
                self.line(&format!("  {} = alloca i64", i_ptr));
                self.line(&format!("  store i64 0, i64* {}", i_ptr));
                let cond_label = self.block_label("table_release_cond");
                let body_label = self.block_label("table_release_body");
                let end_label = self.block_label("table_release_end");
                self.line(&format!("  br label %{}", cond_label));
                self.open_block(&cond_label);
                let i_reg = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
                let cmp = self.tmp_name();
                self.line(&format!("  {} = icmp slt i64 {}, {}", cmp, i_reg, len));
                self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, body_label, end_label));
                self.open_block(&body_label);
                let elem_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, f_llvm, f_llvm, col, i_reg));
                self.emit_release_at(&elem_ptr, fty);
                let i_next = self.tmp_name();
                self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
                self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
                self.line(&format!("  br label %{}", cond_label));
                self.open_block(&end_label);
            }

            let col_i8 = self.tmp_name();
            self.line(&format!("  {} = bitcast {}* {} to i8*", col_i8, f_llvm, col));
            self.line(&format!("  call void @free(i8* {})", col_i8));
        }

        self.line("  ret void");
        self.line("}");
        self.line("");
        let fn_ir = std::mem::replace(&mut self.ir, saved_ir);
        self.pending_top.push(fn_ir);

        let reg = self.tmp_name();
        self.line(&format!("  {} = bitcast void (i8*)* @{} to i8*", reg, name));
        reg
    }

    /// `Table<T>()`: the empty table is `null`, mirroring `List<T>()` --
    /// lazily allocated on first mutation (see `emit_table_ensure_unique`).
    pub(super) fn emit_table_new(&mut self, _elem_ty: &Ty) -> String {
        "i8* null".into()
    }

    /// Read path: resolve `base`'s column pointers and `len`, with no
    /// copy-on-write check and no crash on the zero value (`null`, a table
    /// that was constructed but never mutated, reads as every column `null`
    /// and `len = 0`) -- mirrors `crate::codegen::list::list_fields`, minus
    /// that function's nested-index fast path (a `Table<T>` never appears
    /// as the base of another index the way `m[0][1]` chains through
    /// `List<T>`, since `Table<T>`'s own index yields a whole struct value,
    /// not another indexable collection).
    fn table_fields(&mut self, base: &TypedExpr, struct_name: &str) -> (Vec<String>, String) {
        let slot_ptr = self.emit_read_place(base);
        let obj = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", obj, slot_ptr));

        let fields = self.table_field_types(struct_name);
        let payload_ty = self.table_payload_llvm_ty(struct_name);

        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, obj));
        let null_label = self.block_label("table_read_null");
        let real_label = self.block_label("table_read_real");
        let end_label = self.block_label("table_read_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, null_label, real_label));

        self.open_block(&null_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&real_label);
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload, obj, payload_ty));
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", len_field, payload_ty, payload_ty, payload));
        let len_real = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len_real, len_field));
        let mut col_reals = Vec::with_capacity(fields.len());
        for (j, fty) in fields.iter().enumerate() {
            let f_llvm = self.llvm_ty(fty);
            let col_field = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", col_field, payload_ty, payload_ty, payload, 2 + j));
            let col_real = self.tmp_name();
            self.line(&format!("  {} = load {}*, {}** {}", col_real, f_llvm, f_llvm, col_field));
            col_reals.push(col_real);
        }
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let len = self.tmp_name();
        self.line(&format!("  {} = phi i64 [ 0, %{} ], [ {}, %{} ]", len, null_label, len_real, real_label));
        let mut cols = Vec::with_capacity(fields.len());
        for (j, fty) in fields.iter().enumerate() {
            let f_llvm = self.llvm_ty(fty);
            let col = self.tmp_name();
            self.line(&format!("  {} = phi {}* [ null, %{} ], [ {}, %{} ]", col, f_llvm, null_label, col_reals[j], real_label));
            cols.push(col);
        }
        (cols, len)
    }

    /// Mutating path: ensure `base`'s object is uniquely owned (allocating
    /// or cloning it, and every one of its columns, as needed) via
    /// `emit_table_ensure_unique`, which guarantees a real, non-null object
    /// by the time this returns -- so, unlike `table_fields`, no null guard
    /// is needed here. Returns `(columns, len, len_field, cap_field,
    /// col_fields)`: `col_fields[j]` is the address of column `j`'s own
    /// pointer field (needed by `push`'s grow branch to store a freshly
    /// `malloc`'d replacement buffer back into the payload).
    fn table_fields_mut(&mut self, base: &TypedExpr, struct_name: &str) -> (Vec<String>, String, String, String, Vec<String>) {
        let payload_ty = self.table_payload_llvm_ty(struct_name);
        let slot_ptr = self.emit_place(base);
        self.emit_table_ensure_unique(&slot_ptr, struct_name);

        let obj = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", obj, slot_ptr));
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload, obj, payload_ty));

        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", len_field, payload_ty, payload_ty, payload));
        let len = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len, len_field));
        let cap_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", cap_field, payload_ty, payload_ty, payload));

        let fields = self.table_field_types(struct_name);
        let mut cols = Vec::with_capacity(fields.len());
        let mut col_fields = Vec::with_capacity(fields.len());
        for (j, fty) in fields.iter().enumerate() {
            let f_llvm = self.llvm_ty(fty);
            let col_field = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", col_field, payload_ty, payload_ty, payload, 2 + j));
            let col = self.tmp_name();
            self.line(&format!("  {} = load {}*, {}** {}", col, f_llvm, f_llvm, col_field));
            cols.push(col);
            col_fields.push(col_field);
        }
        (cols, len, len_field, cap_field, col_fields)
    }

    /// Copy-on-write gate for every *mutating* table operation (`push`,
    /// `pop`, index-assignment) -- mirrors
    /// `crate::codegen::list::Codegen::emit_list_ensure_unique`, cloning
    /// every one of the `N` column buffers (instead of just one) when the
    /// object isn't uniquely owned.
    fn emit_table_ensure_unique(&mut self, slot_ptr: &str, struct_name: &str) {
        let payload_ty = self.table_payload_llvm_ty(struct_name);
        let fields = self.table_field_types(struct_name);

        let obj = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", obj, slot_ptr));
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, obj));
        let alloc_label = self.block_label("table_cow_alloc");
        let check_label = self.block_label("table_cow_check");
        let done_label = self.block_label("table_cow_done");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, alloc_label, check_label));

        // Never-allocated table (the zero value): allocate a fresh, empty,
        // uniquely-owned object with every column `null`.
        self.open_block(&alloc_label);
        let release_fn0 = self.table_release_thunk_operand(struct_name);
        let payload_size0 = self.emit_sizeof_llvm_ty(&payload_ty);
        let raw0 = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* {})", raw0, payload_size0, release_fn0));
        let payload0 = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload0, raw0, payload_ty));
        let l0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", l0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store i64 0, i64* {}", l0));
        let c0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", c0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store i64 0, i64* {}", c0));
        for (j, fty) in fields.iter().enumerate() {
            let f_llvm = self.llvm_ty(fty);
            let col_field0 = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", col_field0, payload_ty, payload_ty, payload0, 2 + j));
            self.line(&format!("  store {}* null, {}** {}", f_llvm, f_llvm, col_field0));
        }
        self.line(&format!("  store i8* {}, i8** {}", raw0, slot_ptr));
        self.line(&format!("  br label %{}", done_label));

        // Already allocated: peek the refcount to decide unique vs. shared,
        // same as `emit_list_ensure_unique`.
        self.open_block(&check_label);
        let hdr_i8 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 -16", hdr_i8, obj));
        let hdr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i64*", hdr, hdr_i8));
        let rc = self.tmp_name();
        self.line(&format!("  {} = load atomic i64, i64* {} seq_cst, align 8", rc, hdr));
        let is_unique = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, 1", is_unique, rc));
        let clone_label = self.block_label("table_cow_clone");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_unique, done_label, clone_label));

        // Shared: clone every column into a fresh object before this
        // operation is allowed to mutate anything.
        self.open_block(&clone_label);
        let old_payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", old_payload, obj, payload_ty));
        let ol_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", ol_field, payload_ty, payload_ty, old_payload));
        let ol = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", ol, ol_field));
        let oc_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", oc_field, payload_ty, payload_ty, old_payload));
        let oc = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", oc, oc_field));

        let release_fn1 = self.table_release_thunk_operand(struct_name);
        let payload_size1 = self.emit_sizeof_llvm_ty(&payload_ty);
        let new_raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* {})", new_raw, payload_size1, release_fn1));
        let new_payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", new_payload, new_raw, payload_ty));
        let nl_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", nl_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store i64 {}, i64* {}", ol, nl_field));
        let nc_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", nc_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store i64 {}, i64* {}", oc, nc_field));

        for (j, fty) in fields.iter().enumerate() {
            let f_llvm = self.llvm_ty(fty);
            let f_size = self.emit_sizeof_llvm_ty(&f_llvm);

            let od_field = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", od_field, payload_ty, payload_ty, old_payload, 2 + j));
            let od = self.tmp_name();
            self.line(&format!("  {} = load {}*, {}** {}", od, f_llvm, f_llvm, od_field));

            let new_bytes = self.tmp_name();
            self.line(&format!("  {} = mul i64 {}, {}", new_bytes, oc, f_size));
            let new_raw_col = self.tmp_name();
            self.line(&format!("  {} = call i8* @malloc(i64 {})", new_raw_col, new_bytes));
            let new_col = self.tmp_name();
            self.line(&format!("  {} = bitcast i8* {} to {}*", new_col, new_raw_col, f_llvm));

            let has_len = self.tmp_name();
            self.line(&format!("  {} = icmp sgt i64 {}, 0", has_len, ol));
            let copy_label = self.block_label("table_cow_copy");
            let after_copy_label = self.block_label("table_cow_after_copy");
            self.line(&format!("  br i1 {}, label %{}, label %{}", has_len, copy_label, after_copy_label));

            self.open_block(&copy_label);
            let old_bytes = self.tmp_name();
            self.line(&format!("  {} = mul i64 {}, {}", old_bytes, ol, f_size));
            let old_raw_col = self.tmp_name();
            self.line(&format!("  {} = bitcast {}* {} to i8*", old_raw_col, f_llvm, od));
            self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_raw_col, old_raw_col, old_bytes));
            if self.contains_rc(fty) {
                let i_ptr = self.tmp_name();
                self.line(&format!("  {} = alloca i64", i_ptr));
                self.line(&format!("  store i64 0, i64* {}", i_ptr));
                let cond_label = self.block_label("table_cow_retain_cond");
                let body_label = self.block_label("table_cow_retain_body");
                let retain_end_label = self.block_label("table_cow_retain_end");
                self.line(&format!("  br label %{}", cond_label));
                self.open_block(&cond_label);
                let i_reg = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
                let cmp = self.tmp_name();
                self.line(&format!("  {} = icmp slt i64 {}, {}", cmp, i_reg, ol));
                self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, body_label, retain_end_label));
                self.open_block(&body_label);
                let elem_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, f_llvm, f_llvm, new_col, i_reg));
                self.emit_retain_at(&elem_ptr, fty);
                let i_next = self.tmp_name();
                self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
                self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
                self.line(&format!("  br label %{}", cond_label));
                self.open_block(&retain_end_label);
            }
            self.line(&format!("  br label %{}", after_copy_label));

            self.open_block(&after_copy_label);
            let ncf = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", ncf, payload_ty, payload_ty, new_payload, 2 + j));
            self.line(&format!("  store {}* {}, {}** {}", f_llvm, new_col, f_llvm, ncf));
        }

        // Drop this binding's reference to the old (still-shared-by-others)
        // object; safe to route through the ordinary release call since we
        // already know it won't hit zero here (refcount was > 1).
        self.line(&format!("  call void @star_rc_release(i8* {})", obj));
        self.line(&format!("  store i8* {}, i8** {}", new_raw, slot_ptr));
        self.line(&format!("  br label %{}", done_label));

        self.open_block(&done_label);
    }

    /// `table[idx]`: bounds-checked whole-element read, reassembling `T`
    /// from every column at `idx`; yields `T`'s zero value out of bounds.
    pub(super) fn emit_table_index(&mut self, base: &TypedExpr, index: &TypedExpr, ty: &Ty) -> String {
        let Ty::Named(struct_name) = ty else { unreachable!("Table<T> element type must be Ty::Named") };
        let struct_name = struct_name.clone();
        let struct_llvm = format!("%{}", struct_name);
        let fields = self.table_field_types(&struct_name);
        let (cols, len) = self.table_fields(base, &struct_name);

        let idx_val = self.emit_expr(index);
        let idx_bare = self.untag(&idx_val, &Ty::Int);
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, idx_bare));

        // Allocated up front (before branching) so both arms can store into
        // the same scratch slot -- mirrors `Codegen::emit_expr`'s ordinary
        // `StructLit` construction's own alloca+GEP+store shape.
        let result_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca {}", result_ptr, struct_llvm));

        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, len));
        let ok_label = self.block_label("table_idx_ok");
        let oob_label = self.block_label("table_idx_oob");
        let end_label = self.block_label("table_idx_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, ok_label, oob_label));

        self.open_block(&ok_label);
        for (j, fty) in fields.iter().enumerate() {
            let f_llvm = self.llvm_ty(fty);
            let col_ptr = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", col_ptr, f_llvm, f_llvm, cols[j], idx64));
            // Reading an element hands out an independent copy while the
            // table keeps its own reference -- retain (a no-op unless `fty`
            // is RC-bearing), mirrors `emit_list_index`.
            self.emit_retain_at(&col_ptr, fty);
            let val = self.tmp_name();
            self.line(&format!("  {} = load {}, {}* {}", val, f_llvm, f_llvm, col_ptr));
            let dest = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", dest, struct_llvm, struct_llvm, result_ptr, j));
            self.line(&format!("  store {} {}, {}* {}", f_llvm, val, f_llvm, dest));
        }
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&oob_label);
        let zero = self.zero_value(ty);
        self.line(&format!("  store {} {}, {}* {}", struct_llvm, zero, struct_llvm, result_ptr));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let reg = self.tmp_name();
        self.line(&format!("  {} = load {}, {}* {}", reg, struct_llvm, struct_llvm, result_ptr));
        format!("{} {}", struct_llvm, reg)
    }

    /// `table[idx] = v`: bounds-checked whole-element write, decomposing the
    /// new struct value into every column at `idx`; an out-of-bounds index
    /// is a silent no-op (mirrors `store_list_index`). Mutates, so this goes
    /// through the copy-on-write gate first.
    pub(super) fn store_table_index(&mut self, base: &TypedExpr, index: &TypedExpr, ty: &Ty, val: &str) {
        let Ty::Named(struct_name) = ty else { unreachable!("Table<T> element type must be Ty::Named") };
        let struct_name = struct_name.clone();
        let struct_llvm = format!("%{}", struct_name);
        let fields = self.table_field_types(&struct_name);
        let (cols, len, _len_field, _cap_field, _col_fields) = self.table_fields_mut(base, &struct_name);

        let idx_val = self.emit_expr(index);
        let idx_bare = self.untag(&idx_val, &Ty::Int);
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, idx_bare));

        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, len));
        let do_label = self.block_label("table_set_do");
        let end_label = self.block_label("table_set_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, do_label, end_label));

        self.open_block(&do_label);
        let clean_val = self.untag(val, ty);
        for (j, fty) in fields.iter().enumerate() {
            let f_llvm = self.llvm_ty(fty);
            let new_field_val = self.tmp_name();
            self.line(&format!("  {} = extractvalue {} {}, {}", new_field_val, struct_llvm, clean_val, j));
            let col_ptr = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", col_ptr, f_llvm, f_llvm, cols[j], idx64));
            // `val` was already computed (and retained, if it's a copy) by
            // the caller before calling this; release the old field value
            // *after* that, right before overwriting it -- keeps `table[i]
            // = table[i]` safe, same reasoning as `store_list_index`.
            self.emit_release_at(&col_ptr, fty);
            self.line(&format!("  store {} {}, {}* {}", f_llvm, new_field_val, f_llvm, col_ptr));
        }
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
    }

    /// `table.push(v)` / `table.pop()` / `table.len()`.
    pub(super) fn emit_table_method(&mut self, base: &TypedExpr, method: TableMethod, args: &[TypedExpr], elem_ty: &Ty) -> String {
        let Ty::Named(struct_name) = elem_ty else { unreachable!("Table<T> element type must be Ty::Named") };
        let struct_name = struct_name.clone();
        let struct_llvm = format!("%{}", struct_name);
        let fields = self.table_field_types(&struct_name);

        match method {
            TableMethod::Len => {
                let (_, len) = self.table_fields(base, &struct_name);
                let len32 = self.tmp_name();
                self.line(&format!("  {} = trunc i64 {} to i32", len32, len));
                format!("i32 {}", len32)
            }
            TableMethod::Push => {
                let (cols, len, len_field, cap_field, col_fields) = self.table_fields_mut(base, &struct_name);

                let val = self.emit_expr(&args[0]);
                let clean_val = self.untag(&val, elem_ty);

                let cap = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", cap, cap_field));

                let needs_grow = self.tmp_name();
                self.line(&format!("  {} = icmp sge i64 {}, {}", needs_grow, len, cap));
                let grow_label = self.block_label("table_push_grow");
                let store_label = self.block_label("table_push_store");
                self.line(&format!("  br i1 {}, label %{}, label %{}", needs_grow, grow_label, store_label));

                self.open_block(&grow_label);
                let doubled = self.tmp_name();
                self.line(&format!("  {} = mul i64 {}, 2", doubled, cap));
                let has_cap = self.tmp_name();
                self.line(&format!("  {} = icmp sgt i64 {}, 0", has_cap, doubled));
                let new_cap = self.tmp_name();
                self.line(&format!("  {} = select i1 {}, i64 {}, i64 1", new_cap, has_cap, doubled));

                for (j, fty) in fields.iter().enumerate() {
                    let f_llvm = self.llvm_ty(fty);
                    let f_size = self.emit_sizeof_llvm_ty(&f_llvm);
                    let new_bytes = self.tmp_name();
                    self.line(&format!("  {} = mul i64 {}, {}", new_bytes, new_cap, f_size));
                    let new_raw = self.tmp_name();
                    self.line(&format!("  {} = call i8* @malloc(i64 {})", new_raw, new_bytes));
                    let new_col = self.tmp_name();
                    self.line(&format!("  {} = bitcast i8* {} to {}*", new_col, new_raw, f_llvm));

                    let had_data = self.tmp_name();
                    self.line(&format!("  {} = icmp sgt i64 {}, 0", had_data, cap));
                    let copy_label = self.block_label("table_push_copy");
                    let after_copy_label = self.block_label("table_push_after_copy");
                    self.line(&format!("  br i1 {}, label %{}, label %{}", had_data, copy_label, after_copy_label));

                    self.open_block(&copy_label);
                    let old_bytes = self.tmp_name();
                    self.line(&format!("  {} = mul i64 {}, {}", old_bytes, len, f_size));
                    let old_raw = self.tmp_name();
                    self.line(&format!("  {} = bitcast {}* {} to i8*", old_raw, f_llvm, cols[j]));
                    self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_raw, old_raw, old_bytes));
                    self.line(&format!("  call void @free(i8* {})", old_raw));
                    self.line(&format!("  br label %{}", after_copy_label));

                    self.open_block(&after_copy_label);
                    self.line(&format!("  store {}* {}, {}** {}", f_llvm, new_col, f_llvm, col_fields[j]));
                }
                self.line(&format!("  store i64 {}, i64* {}", new_cap, cap_field));
                self.line(&format!("  br label %{}", store_label));

                self.open_block(&store_label);
                // Reload every column pointer from its field slot -- if we
                // grew, that slot now holds the freshly `malloc`'d
                // replacement; otherwise it's still the original `cols[j]`.
                // Correct regardless of which branch was taken, mirroring
                // `ListMethod::Push`'s own post-grow `data_now` reload.
                for (j, fty) in fields.iter().enumerate() {
                    let f_llvm = self.llvm_ty(fty);
                    let data_now = self.tmp_name();
                    self.line(&format!("  {} = load {}*, {}** {}", data_now, f_llvm, f_llvm, col_fields[j]));
                    let field_val = self.tmp_name();
                    self.line(&format!("  {} = extractvalue {} {}, {}", field_val, struct_llvm, clean_val, j));
                    let elem_ptr = self.tmp_name();
                    self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, f_llvm, f_llvm, data_now, len));
                    self.line(&format!("  store {} {}, {}* {}", f_llvm, field_val, f_llvm, elem_ptr));
                }
                let new_len = self.tmp_name();
                self.line(&format!("  {} = add i64 {}, 1", new_len, len));
                self.line(&format!("  store i64 {}, i64* {}", new_len, len_field));
                "%undef".into()
            }
            TableMethod::Pop => {
                let (cols, len, len_field, _cap_field, _col_fields) = self.table_fields_mut(base, &struct_name);

                let result_ptr = self.tmp_name();
                self.line(&format!("  {} = alloca {}", result_ptr, struct_llvm));

                let is_empty = self.tmp_name();
                self.line(&format!("  {} = icmp eq i64 {}, 0", is_empty, len));
                let empty_label = self.block_label("table_pop_empty");
                let nonempty_label = self.block_label("table_pop_nonempty");
                let end_label = self.block_label("table_pop_end");
                self.line(&format!("  br i1 {}, label %{}, label %{}", is_empty, empty_label, nonempty_label));

                self.open_block(&nonempty_label);
                let new_len = self.tmp_name();
                self.line(&format!("  {} = sub i64 {}, 1", new_len, len));
                self.line(&format!("  store i64 {}, i64* {}", new_len, len_field));
                for (j, fty) in fields.iter().enumerate() {
                    let f_llvm = self.llvm_ty(fty);
                    let elem_ptr = self.tmp_name();
                    self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, f_llvm, f_llvm, cols[j], new_len));
                    let popped = self.tmp_name();
                    self.line(&format!("  {} = load {}, {}* {}", popped, f_llvm, f_llvm, elem_ptr));
                    let dest = self.tmp_name();
                    self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", dest, struct_llvm, struct_llvm, result_ptr, j));
                    self.line(&format!("  store {} {}, {}* {}", f_llvm, popped, f_llvm, dest));
                }
                self.line(&format!("  br label %{}", end_label));

                self.open_block(&empty_label);
                let zero = self.zero_value(elem_ty);
                self.line(&format!("  store {} {}, {}* {}", struct_llvm, zero, struct_llvm, result_ptr));
                self.line(&format!("  br label %{}", end_label));

                self.open_block(&end_label);
                let reg = self.tmp_name();
                self.line(&format!("  {} = load {}, {}* {}", reg, struct_llvm, struct_llvm, result_ptr));
                format!("{} {}", struct_llvm, reg)
            }
        }
    }
}
