//! `Symbol` codegen: an interned string with O(1) equality comparison,
//! lowered to a bare `i64` id into a single process-wide intern table
//! (`docs/design.md`'s "Text and bytes" section, `Ty::Symbol`'s doc comment).
//!
//! The append-only log itself (`@sym.data`/`@sym.len`/`@sym.cap`, declared in
//! `Codegen::emit_builtins`) is a plain growable global array of owned `str`
//! object pointers, doubled on grow exactly the way `List<T>::push` doubles
//! its own backing buffer (see `crate::codegen::list`) -- the only
//! difference is the three fields are standalone globals rather than a heap
//! payload struct's fields, since there's exactly one intern table for the
//! whole process, never copied or reference-counted itself. A `Symbol`
//! value's own id is just its index into `@sym.data`, so reverse lookup
//! (`symbol_name`) is a direct, already-O(1) array read -- nothing about
//! this pass needed to touch it.
//!
//! Interning (`Symbol(s)`) used to do a linear `strcmp` scan against every
//! already-interned string to find (or assign) `s`'s id, the same
//! "no hashing yet" honesty `Map`/`Set` used to have. It's now backed by a
//! separate open-addressing hash index (`@sym.tbl.ids`/`@sym.tbl.cap`) over
//! that same append-only log: `@sym.tbl.ids[slot]` holds an index into
//! `@sym.data` (`-1` = empty slot), probed by `s`'s hash
//! (`crate::codegen::hash`'s `Ty::Str` arm, reused as-is) exactly the way
//! `Map`/`Set` now probe their own tables (`Codegen::emit_ht_probe`) --
//! except this index needs neither tombstones nor `Map`/`Set`'s
//! `states`/`OCCUPIED` bookkeeping, since a `Symbol` is never un-interned:
//! once a slot holds a real id, it holds it forever, so a plain `-1`-empty
//! sentinel is enough, and grows always rebuild the index from scratch off
//! `@sym.data`/`@sym.len` directly (the source of truth) rather than
//! rehashing the old index's own slots.

use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

impl Codegen {
    /// Probe `@sym.tbl.ids` (`cap`-length, `mask = cap - 1`) starting at
    /// slot `start` for an entry whose `@sym.data[id]` string equals
    /// `needle` (`strcmp`), stopping at the first empty (`-1`) slot -- no
    /// tombstones exist for this table (see this module's doc comment), so
    /// unlike `Codegen::emit_ht_probe` there's no "skip past a tombstone"
    /// case to handle. Returns `(found: i1, id: i64, insert_slot: i64)`:
    /// `id` is the matching `@sym.data` index when `found`; `insert_slot`
    /// (the terminating empty slot itself, since there are no tombstones to
    /// prefer reusing) is meaningful when `!found`.
    fn emit_sym_probe(&mut self, ids: &str, cap: &str, mask: &str, start: &str, needle: &str) -> (String, String, String) {
        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));
        let slot_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", slot_ptr));
        self.line(&format!("  store i64 {}, i64* {}", start, slot_ptr));
        let found_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i1", found_ptr));
        self.line(&format!("  store i1 false, i1* {}", found_ptr));
        let id_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", id_ptr));
        self.line(&format!("  store i64 -1, i64* {}", id_ptr));

        let cond_label = self.block_label("sym_probe_cond");
        let body_label = self.block_label("sym_probe_body");
        let on_occ_label = self.block_label("sym_probe_on_occ");
        let on_match_label = self.block_label("sym_probe_on_match");
        let next_label = self.block_label("sym_probe_next");
        let end_label = self.block_label("sym_probe_end");

        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&cond_label);
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
        let in_range = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", in_range, i_reg, cap));
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_range, body_label, end_label));

        self.open_block(&body_label);
        let slot = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", slot, slot_ptr));
        let slot_ptr2 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i64, i64* {}, i64 {}", slot_ptr2, ids, slot));
        let cand_id = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", cand_id, slot_ptr2));
        let is_empty = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, -1", is_empty, cand_id));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_empty, end_label, on_occ_label));

        self.open_block(&on_occ_label);
        let data = self.tmp_name();
        self.line(&format!("  {} = load i8**, i8*** @sym.data", data));
        let cand_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8*, i8** {}, i64 {}", cand_ptr, data, cand_id));
        let cand_str = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", cand_str, cand_ptr));
        let scmp = self.tmp_name();
        self.line(&format!("  {} = call i32 @strcmp(i8* {}, i8* {})", scmp, cand_str, needle));
        let is_eq = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 0", is_eq, scmp));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_eq, on_match_label, next_label));

        self.open_block(&on_match_label);
        self.line(&format!("  store i1 true, i1* {}", found_ptr));
        self.line(&format!("  store i64 {}, i64* {}", cand_id, id_ptr));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&next_label);
        let slot2 = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", slot2, slot));
        let slot3 = self.tmp_name();
        self.line(&format!("  {} = and i64 {}, {}", slot3, slot2, mask));
        self.line(&format!("  store i64 {}, i64* {}", slot3, slot_ptr));
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&end_label);
        let found = self.tmp_name();
        self.line(&format!("  {} = load i1, i1* {}", found, found_ptr));
        let id = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", id, id_ptr));
        let islot = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", islot, slot_ptr));
        (found, id, islot)
    }

    /// `Symbol(s)`: intern `s`, returning its id as a bare `i64`. When `s` is
    /// already present, its reference is released (the table's own,
    /// independent copy is what stays alive) and the existing id is
    /// returned; otherwise `s`'s reference transfers directly into
    /// `@sym.data` (no retain/release needed -- ownership just moves),
    /// appended at `@sym.len`/growing `@sym.data` first if it's full, then
    /// indexed into `@sym.tbl.ids` (itself grown/rebuilt first if its own
    /// load factor is too high).
    pub(super) fn emit_symbol_intern(&mut self, str_expr: &TypedExpr) -> String {
        let s = self.emit_expr(str_expr);
        let s_raw = self.untag(&s, &Ty::Str);

        // Acquire the table lock before touching any of `@sym.len`/
        // `@sym.data`/`@sym.cap`/`@sym.tbl.ids`/`@sym.tbl.cap` -- see
        // `@sym.lock`'s doc comment in `Codegen::emit_builtins`. Held across
        // the whole probe-then-insert sequence (not just the grows) since a
        // lost update to `@sym.len` alone (two threads both computing
        // `old_len + 1`) is just as real a race as either grow's `malloc`/
        // `memcpy`/`free`.
        let lock_h = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** @sym.lock", lock_h));
        self.line(&format!("  call i32 @WaitForSingleObject(i8* {}, i32 -1)", lock_h));

        let len = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @sym.len", len));
        let tbl_cap = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @sym.tbl.cap", tbl_cap));

        // Grow/rebuild the hash index when it would cross 75% load after
        // this insert -- also naturally true when `tbl_cap == 0` (first
        // ever call), so no separate "allocate the first index" case is
        // needed. Rebuilds from `@sym.data`/`@sym.len` directly (every
        // already-interned string, source of truth) rather than migrating
        // the old index's own slots -- simpler, and just as correct, since
        // the index carries no data the log doesn't already have.
        let lhs = self.tmp_name();
        let len_plus_1 = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", len_plus_1, len));
        self.line(&format!("  {} = mul i64 {}, 4", lhs, len_plus_1));
        let rhs = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, 3", rhs, tbl_cap));
        let needs_grow = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i64 {}, {}", needs_grow, lhs, rhs));
        let grow_label = self.block_label("sym_tbl_grow");
        let after_grow_label = self.block_label("sym_tbl_after_grow");
        self.line(&format!("  br i1 {}, label %{}, label %{}", needs_grow, grow_label, after_grow_label));

        self.open_block(&grow_label);
        let new_cap = self.emit_ht_grown_cap(&tbl_cap);
        let new_mask = self.tmp_name();
        self.line(&format!("  {} = sub i64 {}, 1", new_mask, new_cap));
        let new_ids_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, 8", new_ids_bytes, new_cap));
        let new_ids_raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", new_ids_raw, new_ids_bytes));
        let new_ids = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i64*", new_ids, new_ids_raw));
        self.emit_fill_i64(&new_ids, &new_cap, -1);

        let data_for_rehash = self.tmp_name();
        self.line(&format!("  {} = load i8**, i8*** @sym.data", data_for_rehash));
        let hash_fn = self.hash_fn_name(&Ty::Str);

        let j_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", j_ptr));
        self.line(&format!("  store i64 0, i64* {}", j_ptr));
        let rcond_label = self.block_label("sym_tbl_rehash_cond");
        let rbody_label = self.block_label("sym_tbl_rehash_body");
        let rend_label = self.block_label("sym_tbl_rehash_end");
        self.line(&format!("  br label %{}", rcond_label));
        self.open_block(&rcond_label);
        let j_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", j_reg, j_ptr));
        let j_in_range = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", j_in_range, j_reg, len));
        self.line(&format!("  br i1 {}, label %{}, label %{}", j_in_range, rbody_label, rend_label));

        self.open_block(&rbody_label);
        let entry_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8*, i8** {}, i64 {}", entry_ptr, data_for_rehash, j_reg));
        let entry_str = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", entry_str, entry_ptr));
        let rh = self.tmp_name();
        self.line(&format!("  {} = call i64 @{}(i8* {})", rh, hash_fn, entry_str));
        let rstart = self.tmp_name();
        self.line(&format!("  {} = and i64 {}, {}", rstart, rh, new_mask));
        let rslot = self.emit_sym_first_empty(&new_ids, &new_cap, &new_mask, &rstart);
        let rslot_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i64, i64* {}, i64 {}", rslot_ptr, new_ids, rslot));
        self.line(&format!("  store i64 {}, i64* {}", j_reg, rslot_ptr));
        let j_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", j_next, j_reg));
        self.line(&format!("  store i64 {}, i64* {}", j_next, j_ptr));
        self.line(&format!("  br label %{}", rcond_label));

        self.open_block(&rend_label);
        let old_ids = self.tmp_name();
        self.line(&format!("  {} = load i64*, i64** @sym.tbl.ids", old_ids));
        let old_ids_i8 = self.tmp_name();
        self.line(&format!("  {} = bitcast i64* {} to i8*", old_ids_i8, old_ids));
        self.line(&format!("  call void @free(i8* {})", old_ids_i8));
        self.line(&format!("  store i64* {}, i64** @sym.tbl.ids", new_ids));
        self.line(&format!("  store i64 {}, i64* @sym.tbl.cap", new_cap));
        self.line(&format!("  br label %{}", after_grow_label));

        self.open_block(&after_grow_label);
        let ids = self.tmp_name();
        self.line(&format!("  {} = load i64*, i64** @sym.tbl.ids", ids));
        let cap = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @sym.tbl.cap", cap));
        let mask = self.tmp_name();
        self.line(&format!("  {} = sub i64 {}, 1", mask, cap));
        let hash_fn2 = self.hash_fn_name(&Ty::Str);
        let h = self.tmp_name();
        self.line(&format!("  {} = call i64 @{}(i8* {})", h, hash_fn2, s_raw));
        let start = self.tmp_name();
        self.line(&format!("  {} = and i64 {}, {}", start, h, mask));
        let (found, found_id, islot) = self.emit_sym_probe(&ids, &cap, &mask, &start, &s_raw);

        let found_label = self.block_label("sym_found");
        let notfound_label = self.block_label("sym_notfound");
        let done_label = self.block_label("sym_done");
        self.line(&format!("  br i1 {}, label %{}, label %{}", found, found_label, notfound_label));

        self.open_block(&found_label);
        // Already interned: the table's own copy is the one kept alive, so
        // release the reference `emit_expr` just gave us instead of leaking
        // it (see `rc.rs`'s module doc comment on this convention).
        self.line(&format!("  call void @star_rc_release(i8* {})", s_raw));
        self.line(&format!("  br label %{}", done_label));

        self.open_block(&notfound_label);
        // Not found: grow `@sym.data` if it's full -- the exact same
        // doubling/malloc/memcpy/free recipe `ListMethod::Push` uses (see
        // `crate::codegen::list::emit_list_method`), just against standalone
        // globals instead of a heap payload struct's fields.
        let data_cap = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @sym.cap", data_cap));
        let needs_data_grow = self.tmp_name();
        self.line(&format!("  {} = icmp sge i64 {}, {}", needs_data_grow, len, data_cap));
        let data_grow_label = self.block_label("sym_grow");
        let store_label = self.block_label("sym_store");
        self.line(&format!("  br i1 {}, label %{}, label %{}", needs_data_grow, data_grow_label, store_label));

        self.open_block(&data_grow_label);
        let doubled = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, 2", doubled, data_cap));
        let has_data_cap = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i64 {}, 0", has_data_cap, doubled));
        let new_data_cap = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i64 {}, i64 1", new_data_cap, has_data_cap, doubled));
        let new_data_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, 8", new_data_bytes, new_data_cap));
        let new_data_raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", new_data_raw, new_data_bytes));
        let new_data = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i8**", new_data, new_data_raw));
        let had_data = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i64 {}, 0", had_data, data_cap));
        let copy_label = self.block_label("sym_copy");
        let after_copy_label = self.block_label("sym_after_copy");
        self.line(&format!("  br i1 {}, label %{}, label %{}", had_data, copy_label, after_copy_label));

        self.open_block(&copy_label);
        let old_data_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, 8", old_data_bytes, len));
        let old_data0 = self.tmp_name();
        self.line(&format!("  {} = load i8**, i8*** @sym.data", old_data0));
        let old_data_raw = self.tmp_name();
        self.line(&format!("  {} = bitcast i8** {} to i8*", old_data_raw, old_data0));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_data_raw, old_data_raw, old_data_bytes));
        self.line(&format!("  call void @free(i8* {})", old_data_raw));
        self.line(&format!("  br label %{}", after_copy_label));

        self.open_block(&after_copy_label);
        self.line(&format!("  store i8** {}, i8*** @sym.data", new_data));
        self.line(&format!("  store i64 {}, i64* @sym.cap", new_data_cap));
        self.line(&format!("  br label %{}", store_label));

        self.open_block(&store_label);
        let data_now = self.tmp_name();
        self.line(&format!("  {} = load i8**, i8*** @sym.data", data_now));
        let slot_now = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8*, i8** {}, i64 {}", slot_now, data_now, len));
        // `s_raw`'s reference transfers directly into the table -- it lives
        // for the remainder of the process, so no retain/release balances
        // this store.
        self.line(&format!("  store i8* {}, i8** {}", s_raw, slot_now));
        let new_len = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", new_len, len));
        self.line(&format!("  store i64 {}, i64* @sym.len", new_len));
        // Index the freshly-appended entry into the (already
        // grown-if-needed) hash table at the empty slot the probe above
        // found.
        let ids_now = self.tmp_name();
        self.line(&format!("  {} = load i64*, i64** @sym.tbl.ids", ids_now));
        let islot_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i64, i64* {}, i64 {}", islot_ptr, ids_now, islot));
        self.line(&format!("  store i64 {}, i64* {}", len, islot_ptr));
        self.line(&format!("  br label %{}", done_label));

        self.open_block(&done_label);
        let result = self.tmp_name();
        self.line(&format!("  {} = phi i64 [ {}, %{} ], [ {}, %{} ]", result, found_id, found_label, len, store_label));
        // Both paths into here (found an existing entry, or just inserted a
        // new one) have finished every table mutation by this point, so it's
        // safe to release the lock acquired at the top of this function.
        // Must come *after* the phi above -- LLVM requires every phi in a
        // block to be grouped at the block's top, before any other
        // instruction.
        self.line(&format!("  call i32 @ReleaseSemaphore(i8* {}, i32 1, i32* null)", lock_h));
        format!("i64 {}", result)
    }

    /// `emit_ht_first_empty`'s counterpart for `@sym.tbl.ids`'s `i64`-array,
    /// `-1`-sentinel shape: probe `ids` (`cap`-length, `mask = cap - 1`)
    /// starting at `start` for the first `-1` slot, no equality check (used
    /// only to rehash into a fresh, all-empty index during grow, where
    /// every id being re-inserted is already known unique).
    fn emit_sym_first_empty(&mut self, ids: &str, cap: &str, mask: &str, start: &str) -> String {
        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));
        let slot_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", slot_ptr));
        self.line(&format!("  store i64 {}, i64* {}", start, slot_ptr));

        let cond_label = self.block_label("sym_fe_cond");
        let body_label = self.block_label("sym_fe_body");
        let next_label = self.block_label("sym_fe_next");
        let end_label = self.block_label("sym_fe_end");
        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&cond_label);
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
        let in_range = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", in_range, i_reg, cap));
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_range, body_label, end_label));

        self.open_block(&body_label);
        let slot = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", slot, slot_ptr));
        let slot_ptr2 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i64, i64* {}, i64 {}", slot_ptr2, ids, slot));
        let cand_id = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", cand_id, slot_ptr2));
        let is_empty = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, -1", is_empty, cand_id));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_empty, end_label, next_label));

        self.open_block(&next_label);
        let slot2 = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", slot2, slot));
        let slot3 = self.tmp_name();
        self.line(&format!("  {} = and i64 {}, {}", slot3, slot2, mask));
        self.line(&format!("  store i64 {}, i64* {}", slot3, slot_ptr));
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", result, slot_ptr));
        result
    }

    /// `symbol_name(sym) -> str`: reverse lookup, returning a fresh, owned
    /// (retained) copy of the reference the intern table holds -- the table
    /// keeps its own permanent reference, so the caller needs an independent
    /// one to release on its own schedule, not the table's. Out of range (a
    /// `Symbol` value that never came from `Symbol(..)`, e.g. a raw
    /// `as`-cast integer) yields a real, freshly-allocated empty `str`
    /// (`star_rc_alloc` + a lone NUL byte, the same recipe `env_get`'s
    /// missing-variable branch uses in `crate::codegen::os`) -- NOT
    /// `Codegen::zero_value(&Ty::Str)` (a bare null `i8*`), which an earlier
    /// version of this function used, matching a doc comment claiming it was
    /// "the same safe zero value empty `str` `List<T>::pop`'s empty-list
    /// case does". That claim was itself wrong: `zero_value`'s `Ty::Str` arm
    /// is `"null"`, not a real empty string, for *any* caller (`pop` on an
    /// empty `List<str>`/`Ring<str,N>` included) -- confirmed via a real
    /// segfault building and running `let mut l = List<str>(); l.pop();
    /// len(l.pop())` (`len`'s `strlen` dereferencing the null "empty string"
    /// `pop` actually returns) and via `symbol_name` on an out-of-range id
    /// printing the literal text `(null)` in an f-string instead of an empty
    /// string. This function's own out-of-range path is fixed here (in
    /// scope for this audit's Symbol coverage); `zero_value` itself and its
    /// other callers (`List`/`Ring`/`Array`/`Table` -- collections codegen)
    /// are left alone, out of this audit's scope. Untouched by the hash-index
    /// pass above: an id -> string reverse lookup was already a direct,
    /// O(1) array read into `@sym.data`, nothing to speed up.
    pub(super) fn emit_symbol_name(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("symbol_name(..) expects 1 argument", Span::dummy());
            return format!("i8* {}", self.zero_value(&Ty::Str));
        };
        let val = self.emit_expr(arg);
        let id = self.untag(&val, &Ty::Symbol);

        // Same lock `emit_symbol_intern` takes -- a concurrent `Symbol(..)`
        // growing the table (freeing the old `@sym.data` buffer) while this
        // reads `@sym.len`/`@sym.data` unsynchronized is a real
        // use-after-free/torn-read hazard, not just the insert path's own
        // race. See `@sym.lock`'s doc comment in `Codegen::emit_builtins`.
        let lock_h = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** @sym.lock", lock_h));
        self.line(&format!("  call i32 @WaitForSingleObject(i8* {}, i32 -1)", lock_h));

        let len = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @sym.len", len));
        let in_range_lo = self.tmp_name();
        self.line(&format!("  {} = icmp sge i64 {}, 0", in_range_lo, id));
        let in_range_hi = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", in_range_hi, id, len));
        let in_range = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", in_range, in_range_lo, in_range_hi));

        let ok_label = self.block_label("sym_name_ok");
        let oob_label = self.block_label("sym_name_oob");
        let end_label = self.block_label("sym_name_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_range, ok_label, oob_label));

        self.open_block(&ok_label);
        let data = self.tmp_name();
        self.line(&format!("  {} = load i8**, i8*** @sym.data", data));
        let elem_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8*, i8** {}, i64 {}", elem_ptr, data, id));
        let found = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", found, elem_ptr));
        // The table keeps its own permanent reference -- retain a fresh one
        // for the caller, mirroring any other shared-storage read's "hands
        // out an independent copy" convention (see `rc.rs`'s module doc
        // comment).
        self.line(&format!("  call void @star_rc_retain(i8* {})", found));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&oob_label);
        // A real, owned empty string -- not `zero_value(&Ty::Str)`'s bare
        // null `i8*` (see this function's own doc comment for the segfault
        // that produced downstream).
        let empty = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 1, i8* null)", empty));
        self.line(&format!("  store i8 0, i8* {}", empty));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!("  {} = phi i8* [ {}, %{} ], [ {}, %{} ]", result, found, ok_label, empty, oob_label));
        // Both paths (found or out-of-range) have finished reading the
        // table by this point, so it's safe to release. Must come *after*
        // the phi above -- see the identical note in `emit_symbol_intern`.
        self.line(&format!("  call i32 @ReleaseSemaphore(i8* {}, i32 1, i32* null)", lock_h));
        format!("i8* {}", result)
    }
}
