//! `Symbol` codegen: an interned string with O(1) equality comparison,
//! lowered to a bare `i64` id into a single process-wide intern table
//! (`docs/design.md`'s "Text and bytes" section, `Ty::Symbol`'s doc comment).
//!
//! The table itself (`@sym.data`/`@sym.len`/`@sym.cap`, declared in
//! `Codegen::emit_builtins`) is a plain growable global array of owned `str`
//! object pointers, doubled on grow exactly the way `List<T>::push` doubles
//! its own backing buffer (see `crate::codegen::list`) -- the only
//! difference is the three fields are standalone globals rather than a heap
//! payload struct's fields, since there's exactly one intern table for the
//! whole process, never copied or reference-counted itself.
//!
//! Interning (`Symbol(s)`) does a linear `strcmp` scan against every
//! already-interned string to find (or assign) `s`'s id -- the same
//! "no hashing yet" honesty `Map`/`Set` already have (see
//! `crate::codegen::map`'s `emit_linear_find_key`, which this mirrors) --
//! so construction cost grows with the table size, but every *comparison*
//! between two already-constructed `Symbol` values is a single
//! `icmp eq i64` (`Codegen::emit_binop`'s `Ty::Symbol` arm), which is the
//! O(1) guarantee `docs/design.md` actually promises.

use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

impl Codegen {
    /// `Symbol(s)`: intern `s`, returning its id as a bare `i64`. When `s` is
    /// already present, its reference is released (the table's own,
    /// independent copy is what stays alive) and the existing id is
    /// returned; otherwise `s`'s reference transfers directly into the
    /// table (no retain/release needed -- ownership just moves), growing
    /// `@sym.data` first if it's full.
    pub(super) fn emit_symbol_intern(&mut self, str_expr: &TypedExpr) -> String {
        let s = self.emit_expr(str_expr);
        let s_raw = self.untag(&s, &Ty::Str);

        let len = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @sym.len", len));
        let data0 = self.tmp_name();
        self.line(&format!("  {} = load i8**, i8*** @sym.data", data0));

        // Linear scan for an existing entry equal to `s_raw` -- mirrors
        // `crate::codegen::map`'s `emit_linear_find_key` shape, just
        // comparing `i8*` strings via `strcmp` directly instead of a
        // generic per-key-type `eq_fn` (there's only ever one concrete
        // element type here, `str`).
        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));

        let cond_label = self.block_label("sym_find_cond");
        let body_label = self.block_label("sym_find_body");
        let next_label = self.block_label("sym_find_next");
        let end_label = self.block_label("sym_find_end");

        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&cond_label);
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
        let in_range = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", in_range, i_reg, len));
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_range, body_label, end_label));

        self.open_block(&body_label);
        let elem_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8*, i8** {}, i64 {}", elem_ptr, data0, i_reg));
        let candidate = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", candidate, elem_ptr));
        let scmp = self.tmp_name();
        self.line(&format!("  {} = call i32 @strcmp(i8* {}, i8* {})", scmp, candidate, s_raw));
        let is_eq = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 0", is_eq, scmp));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_eq, end_label, next_label));

        self.open_block(&next_label);
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&end_label);
        let final_i = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", final_i, i_ptr));
        let found = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", found, final_i, len));

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
        let cap = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @sym.cap", cap));
        let needs_grow = self.tmp_name();
        self.line(&format!("  {} = icmp sge i64 {}, {}", needs_grow, len, cap));
        let grow_label = self.block_label("sym_grow");
        let store_label = self.block_label("sym_store");
        self.line(&format!("  br i1 {}, label %{}, label %{}", needs_grow, grow_label, store_label));

        self.open_block(&grow_label);
        let doubled = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, 2", doubled, cap));
        let has_cap = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i64 {}, 0", has_cap, doubled));
        let new_cap = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i64 {}, i64 1", new_cap, has_cap, doubled));
        let new_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, 8", new_bytes, new_cap));
        let new_raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", new_raw, new_bytes));
        let new_data = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i8**", new_data, new_raw));
        let had_data = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i64 {}, 0", had_data, cap));
        let copy_label = self.block_label("sym_copy");
        let after_copy_label = self.block_label("sym_after_copy");
        self.line(&format!("  br i1 {}, label %{}, label %{}", had_data, copy_label, after_copy_label));

        self.open_block(&copy_label);
        let old_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, 8", old_bytes, len));
        let old_raw = self.tmp_name();
        self.line(&format!("  {} = bitcast i8** {} to i8*", old_raw, data0));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_raw, old_raw, old_bytes));
        self.line(&format!("  call void @free(i8* {})", old_raw));
        self.line(&format!("  br label %{}", after_copy_label));

        self.open_block(&after_copy_label);
        self.line(&format!("  store i8** {}, i8*** @sym.data", new_data));
        self.line(&format!("  store i64 {}, i64* @sym.cap", new_cap));
        self.line(&format!("  br label %{}", store_label));

        self.open_block(&store_label);
        let data_now = self.tmp_name();
        self.line(&format!("  {} = load i8**, i8*** @sym.data", data_now));
        let slot = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8*, i8** {}, i64 {}", slot, data_now, len));
        // `s_raw`'s reference transfers directly into the table -- it lives
        // for the remainder of the process, so no retain/release balances
        // this store.
        self.line(&format!("  store i8* {}, i8** {}", s_raw, slot));
        let new_len = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", new_len, len));
        self.line(&format!("  store i64 {}, i64* @sym.len", new_len));
        self.line(&format!("  br label %{}", done_label));

        self.open_block(&done_label);
        let result = self.tmp_name();
        self.line(&format!("  {} = phi i64 [ {}, %{} ], [ {}, %{} ]", result, final_i, found_label, len, store_label));
        format!("i64 {}", result)
    }

    /// `symbol_name(sym) -> str`: reverse lookup, returning a fresh, owned
    /// (retained) copy of the reference the intern table holds -- the table
    /// keeps its own permanent reference, so the caller needs an independent
    /// one to release on its own schedule, not the table's. Out of range (a
    /// `Symbol` value that never came from `Symbol(..)`, e.g. a raw
    /// `as`-cast integer) yields the same "safe zero value" empty `str`
    /// `List<T>::pop`'s empty-list case does.
    pub(super) fn emit_symbol_name(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("symbol_name(..) expects 1 argument", Span::dummy());
            return format!("i8* {}", self.zero_value(&Ty::Str));
        };
        let val = self.emit_expr(arg);
        let id = self.untag(&val, &Ty::Symbol);

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
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let zero = self.zero_value(&Ty::Str);
        let result = self.tmp_name();
        self.line(&format!("  {} = phi i8* [ {}, %{} ], [ {}, %{} ]", result, found, ok_label, zero, oob_label));
        format!("i8* {}", result)
    }
}
