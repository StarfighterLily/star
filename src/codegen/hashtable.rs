//! Shared open-addressing primitives for `Map<K,V>`/`Set<T>`'s hash-table
//! backing (`crate::codegen::map`/`crate::codegen::set`) -- linear-probing
//! helpers over a `states: i8*` control array (`0` = empty, `1` = occupied,
//! `2` = tombstone) parallel to a `keys`/elements array. Shared verbatim
//! between `Map`/`Set` since neither of these two primitives cares about a
//! `Map`'s second (`vals`) array -- probing only ever compares/relocates
//! keys/elements, never values (a matching value has nothing to do with
//! finding a slot).
//!
//! Every capacity here is a power of two, so `slot mod cap` is always
//! `slot AND (cap - 1)` -- every caller precomputes `mask = cap - 1` once
//! and passes it in rather than this module re-deriving it from `cap` on
//! every probe step.

use crate::types::*;

use super::Codegen;

impl Codegen {
    /// Probe `states`/`keys` (both `cap`-length, `mask = cap - 1`) starting
    /// at slot `start` for an existing entry structurally equal to `needle`
    /// (a bare, already-loaded `key_ty` value), stopping at the first
    /// `EMPTY` (`state == 0`) slot -- a tombstone (`state == 2`) never
    /// terminates a probe: an entry inserted after a tombstone appeared
    /// earlier in its own probe chain must still be reachable past it, or a
    /// `remove` immediately followed by an unrelated `insert`/`remove` could
    /// make an existing key spuriously unfindable.
    ///
    /// Returns `(found: i1, idx: i64, insert_slot: i64)`: `idx` is the
    /// matching slot when `found`. `insert_slot` is the first `EMPTY`-or-
    /// `TOMBSTONE` slot seen along the way (preferring the earliest
    /// tombstone, to reclaim it instead of growing the table sooner than
    /// needed), meaningful whenever `!found` -- the slot a caller should
    /// write a new entry into. Bounded to at most `cap` probe steps
    /// (defensive: correct capacity management -- see
    /// `Codegen::emit_set_ensure_capacity`/`Codegen::emit_map_ensure_capacity`
    /// -- guarantees at least one non-`OCCUPIED` slot exists before this is
    /// ever called, so the bound is never actually hit in practice).
    ///
    /// Uses a handful of `alloca`'d locals (`i`/`slot`/`found`/`idx`/
    /// `insert_slot`/`have_insert_slot`), reloaded once at the very end,
    /// rather than `phi`-merging across the probe loop's several exit
    /// branches -- the same pragmatic shape `crate::codegen::symbol`'s
    /// `emit_symbol_intern` scan already uses for its own linear search, and
    /// far simpler to get right than threading `phi` incoming-value lists
    /// through this many predecessors by hand. Every `alloca` this emits
    /// gets hoisted to the enclosing function's `entry:` block by the
    /// top-level `hoist_allocas_to_entry` pass every ordinary function body
    /// already runs (`crate::codegen::stmt::emit_fn`), so its SSA names
    /// still dominate every block that reads them regardless of where in
    /// the function this helper is actually called from.
    pub(super) fn emit_ht_probe(&mut self, states: &str, keys: &str, cap: &str, mask: &str, start: &str, key_ty: &Ty, needle: &str) -> (String, String, String) {
        let key_llvm = self.llvm_ty(key_ty);
        let eq_fn = self.eq_fn_name(key_ty);

        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));
        let slot_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", slot_ptr));
        self.line(&format!("  store i64 {}, i64* {}", start, slot_ptr));
        let found_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i1", found_ptr));
        self.line(&format!("  store i1 false, i1* {}", found_ptr));
        let idx_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", idx_ptr));
        self.line(&format!("  store i64 -1, i64* {}", idx_ptr));
        let islot_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", islot_ptr));
        self.line(&format!("  store i64 -1, i64* {}", islot_ptr));
        let have_islot_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i1", have_islot_ptr));
        self.line(&format!("  store i1 false, i1* {}", have_islot_ptr));

        let cond_label = self.block_label("ht_probe_cond");
        let body_label = self.block_label("ht_probe_body");
        let check_occ_label = self.block_label("ht_probe_check_occ");
        let on_empty_label = self.block_label("ht_probe_on_empty");
        let set_islot_empty_label = self.block_label("ht_probe_set_islot_empty");
        let after_islot_empty_label = self.block_label("ht_probe_after_islot_empty");
        let on_occ_label = self.block_label("ht_probe_on_occ");
        let on_match_label = self.block_label("ht_probe_on_match");
        let on_tomb_label = self.block_label("ht_probe_on_tomb");
        let set_islot_tomb_label = self.block_label("ht_probe_set_islot_tomb");
        let next_label = self.block_label("ht_probe_next");
        let end_label = self.block_label("ht_probe_end");

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
        let st_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", st_ptr, states, slot));
        let st = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", st, st_ptr));
        let is_empty = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8 {}, 0", is_empty, st));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_empty, on_empty_label, check_occ_label));

        self.open_block(&check_occ_label);
        let is_occ = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8 {}, 1", is_occ, st));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_occ, on_occ_label, on_tomb_label));

        self.open_block(&on_empty_label);
        let have0 = self.tmp_name();
        self.line(&format!("  {} = load i1, i1* {}", have0, have_islot_ptr));
        self.line(&format!("  br i1 {}, label %{}, label %{}", have0, after_islot_empty_label, set_islot_empty_label));
        self.open_block(&set_islot_empty_label);
        self.line(&format!("  store i64 {}, i64* {}", slot, islot_ptr));
        self.line(&format!("  store i1 true, i1* {}", have_islot_ptr));
        self.line(&format!("  br label %{}", after_islot_empty_label));
        self.open_block(&after_islot_empty_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&on_occ_label);
        let key_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", key_ptr, key_llvm, key_llvm, keys, slot));
        let key_val = self.tmp_name();
        self.line(&format!("  {} = load {}, {}* {}", key_val, key_llvm, key_llvm, key_ptr));
        let is_eq = self.tmp_name();
        self.line(&format!("  {} = call i1 @{}({} {}, {} {})", is_eq, eq_fn, key_llvm, key_val, key_llvm, needle));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_eq, on_match_label, next_label));
        self.open_block(&on_match_label);
        self.line(&format!("  store i1 true, i1* {}", found_ptr));
        self.line(&format!("  store i64 {}, i64* {}", slot, idx_ptr));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&on_tomb_label);
        let have1 = self.tmp_name();
        self.line(&format!("  {} = load i1, i1* {}", have1, have_islot_ptr));
        self.line(&format!("  br i1 {}, label %{}, label %{}", have1, next_label, set_islot_tomb_label));
        self.open_block(&set_islot_tomb_label);
        self.line(&format!("  store i64 {}, i64* {}", slot, islot_ptr));
        self.line(&format!("  store i1 true, i1* {}", have_islot_ptr));
        self.line(&format!("  br label %{}", next_label));

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
        let idx = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", idx, idx_ptr));
        let islot = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", islot, islot_ptr));
        (found, idx, islot)
    }

    /// Probe `states` (`cap`-length, `mask = cap - 1`) starting at slot
    /// `start` for the first `EMPTY` slot, with no equality check against
    /// any existing entry -- used only while rehashing into a *fresh*
    /// (all-`EMPTY`, no tombstones) table during grow, where every key being
    /// re-inserted is already known unique (it came from the table being
    /// replaced). Bounded to at most `cap` probe steps, guaranteed to
    /// terminate before that: a grow always sizes the new table so the
    /// element count being rehashed is well under `cap`, so an `EMPTY` slot
    /// always exists.
    pub(super) fn emit_ht_first_empty(&mut self, states: &str, cap: &str, mask: &str, start: &str) -> String {
        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));
        let slot_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", slot_ptr));
        self.line(&format!("  store i64 {}, i64* {}", start, slot_ptr));

        let cond_label = self.block_label("ht_fe_cond");
        let body_label = self.block_label("ht_fe_body");
        let next_label = self.block_label("ht_fe_next");
        let end_label = self.block_label("ht_fe_end");

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
        let st_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", st_ptr, states, slot));
        let st = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", st, st_ptr));
        let is_empty = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8 {}, 0", is_empty, st));
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

    /// Fill `count` consecutive `i8` slots at `ptr` with `value` via an
    /// explicit store loop -- this codegen never declares `@llvm.memset`, so
    /// a hand-rolled loop is this module's zero/fill primitive, the same
    /// "a small store loop is simpler than pulling in a new declared
    /// intrinsic" tradeoff every other growable buffer here already makes.
    pub(super) fn emit_fill_i8(&mut self, ptr: &str, count: &str, value: u8) {
        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));
        let cond_label = self.block_label("ht_fill8_cond");
        let body_label = self.block_label("ht_fill8_body");
        let end_label = self.block_label("ht_fill8_end");
        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&cond_label);
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
        let in_range = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", in_range, i_reg, count));
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_range, body_label, end_label));
        self.open_block(&body_label);
        let p = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", p, ptr, i_reg));
        self.line(&format!("  store i8 {}, i8* {}", value, p));
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&end_label);
    }

    /// `emit_fill_i8`'s `i64` counterpart, used for `Symbol`'s intern hash
    /// index (`@sym.tbl.ids`, `-1`-sentinel-filled on grow -- see
    /// `crate::codegen::symbol`).
    pub(super) fn emit_fill_i64(&mut self, ptr: &str, count: &str, value: i64) {
        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));
        let cond_label = self.block_label("ht_fill64_cond");
        let body_label = self.block_label("ht_fill64_body");
        let end_label = self.block_label("ht_fill64_end");
        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&cond_label);
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
        let in_range = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", in_range, i_reg, count));
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_range, body_label, end_label));
        self.open_block(&body_label);
        let p = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i64, i64* {}, i64 {}", p, ptr, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", value, p));
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&end_label);
    }

    /// `new_cap` for a table currently at `cap` (already loaded, `i64`):
    /// `8` if empty (`cap == 0`), else `cap * 2`. Shared growth-doubling
    /// policy for `Map`/`Set`/the `Symbol` intern index.
    pub(super) fn emit_ht_grown_cap(&mut self, cap: &str) -> String {
        let doubled = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, 2", doubled, cap));
        let has_cap = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i64 {}, 0", has_cap, doubled));
        let new_cap = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i64 {}, i64 8", new_cap, has_cap, doubled));
        new_cap
    }
}
