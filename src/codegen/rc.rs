//! Reference-counting support for heap-backed `Str`/`Closure` values (see
//! `Codegen::emit_rc_runtime` in `mod.rs` for the runtime side): a generic
//! pointer-to-storage walker that retains on every read of an existing
//! owned slot and releases at scope exit/reassignment, so `concat` results
//! and closure environments (`crate::codegen::builtins::emit_str_concat`,
//! `crate::codegen::closure::emit_closure_lit`) are freed once their last
//! owner goes away instead of leaking unboundedly (todo.md §3.6).
//!
//! The ownership rule this all composes from: a *fresh* value (a `concat`
//! call, a closure literal, a `StructLit`, a list literal, `list.pop()`)
//! starts at refcount 1 with a single owner and needs no extra retain. A
//! *read* of an existing owned slot (`Ident`, a non-swizzle `Field`, an
//! in-bounds `ListIndex`) hands out a duplicate reference and must retain.
//! Every duplication point elsewhere in this codegen -- `let`, reassignment,
//! a call argument, a `return`, a struct-field store, a list-literal
//! element, a closure's by-value capture snapshot -- is *always* just
//! `emit_expr` evaluating some expression, so retaining at the read alone
//! is sufficient; no other call site needs special-casing.
//!
//! The flip side of that rule, for a value consumed *transiently* and never
//! stored anywhere (a `println`/f-string interpolation argument, a
//! `Map`/`Set` lookup key compared via `eq_fn` and discarded, a closure
//! invoked and never bound): whichever of the two states above `emit_expr`
//! left it in, exactly one release is owed once it's done being read --
//! a borrowed read's extra retain must be balanced back out, or a fresh
//! value's sole owning reference leaks forever with nothing else to free it.
//! There is no "nothing to release" case: `Codegen::emit_release_bare`
//! already no-ops for a non-RC-bearing type, and the `star_rc_release`
//! runtime itself no-ops on a null pointer or the immortal (`-1`-sentinel)
//! refcount a string literal's global constant carries -- so releasing
//! unconditionally is always safe, whether the value being discarded came
//! from a borrow or a fresh construction. Every transient-consumption call
//! site used to gate its release on `is_rc_borrowing_read(expr)` (true only
//! for a borrowing read), skipping it entirely for a fresh construction --
//! so `println(concat(a, b))`, `map.contains(concat(a, b))`, an f-string
//! hole holding a fresh value, and an immediately-invoked closure literal
//! each leaked their fresh operand on every single evaluation, confirmed via
//! real unbounded working-set growth. Fixed by dropping the guard and
//! releasing unconditionally at every one of those call sites.

use crate::types::Ty;

use super::Codegen;

impl Codegen {
    /// True if a value of this type owns, directly or transitively (through
    /// struct fields), a `star_rc_alloc`'d heap block that needs a matching
    /// retain/release. Everything else (`Int`, `Float`, `Bool`, vectors,
    /// `GenRef`, a non-payload `Enum`) is copied by ordinary value semantics
    /// and needs no tracking.
    ///
    /// `List<T>` is always `true`, regardless of `T` -- unlike a struct
    /// field, a list's own backing buffer is *always* a heap allocation that
    /// needs releasing, even when `T` itself carries no RC content (e.g.
    /// `List<i32>`). Whether the buffer's *elements* also need releasing is
    /// decided separately, inside the generated release thunk (see
    /// `Codegen::list_release_thunk_operand`), not here.
    pub(super) fn contains_rc(&self, ty: &Ty) -> bool {
        match ty {
            // Same reasoning as `Ty::List` -- `Map`/`Set` always own a
            // separately heap-allocated backing buffer (or two, for `Map`)
            // that needs releasing, regardless of whether `K`/`V`/`T`
            // themselves carry RC content (that's decided separately, inside
            // the generated release thunk -- see
            // `crate::codegen::map::map_release_thunk_operand`/
            // `crate::codegen::set::set_release_thunk_operand`).
            // Same reasoning as `Ty::List`/`Ty::Map`/`Ty::Set` -- a `Table<T>`
            // always owns `N` separately heap-allocated column buffers that
            // need releasing, regardless of whether any of `T`'s own fields
            // carry RC content (decided separately, inside the generated
            // release thunk -- see `crate::codegen::table::table_release_thunk_operand`).
            // Same reasoning as `Ty::List` -- `Bytes` reuses `List<u8>`'s
            // exact heap layout (see `Ty::Bytes`'s doc comment), so it always
            // owns a separately heap-allocated backing buffer too.
            // Same reasoning as `Ty::Bytes` just above -- `Palette` reuses
            // `List<Color32>`'s exact heap layout (see `Ty::Palette`'s doc
            // comment).
            Ty::Str | Ty::Closure(..) | Ty::List(_) | Ty::Map(..) | Ty::Set(_) | Ty::Table(_) | Ty::Bytes | Ty::Palette => true,
            Ty::Named(n) => self
                .struct_field_types
                .get(n)
                .map(|fields| fields.iter().any(|f| self.contains_rc(f)))
                .unwrap_or(false),
            Ty::Tuple(elems) => elems.iter().any(|f| self.contains_rc(f)),
            // A payload enum (`Option<str>`, `Result<str, str>`, any
            // user-defined enum with RC-bearing variant fields) shares one
            // `[W x i64]` payload buffer across every variant (see
            // `Codegen::enum_variant_payload_llvm_ty`'s doc comment) -- true
            // whenever *any* variant carries an RC-bearing field, since the
            // active variant is only known at runtime (the tag). A fieldless
            // enum (`enum_variant_fields`'s per-variant lists all empty, e.g.
            // a plain `enum Color: Red, Green, Blue`) correctly falls out to
            // `false` here with no separate `enum_is_payload` check needed.
            Ty::Enum(n) => self
                .enum_variant_fields
                .get(n)
                .map(|variants| variants.iter().any(|fields| fields.iter().any(|f| self.contains_rc(f))))
                .unwrap_or(false),
            Ty::Array(elem, count) => *count > 0 && self.contains_rc(elem),
            // A ring always has `count > 0` (rejected at parse time -- see
            // `Parser::parse_type_inner`/`parse_ring_new`), so this is just
            // whether the element type itself carries RC content -- the two
            // `i64` head/len fields never do.
            Ty::Ring(elem, _) => self.contains_rc(elem),
            // Both lower to a plain scalar `iN` with no RC header of its own
            // (see their own `Ty` doc comments) -- `Wrapping<T>` delegates
            // for completeness even though `T` is always itself RC-free.
            Ty::Wrapping(inner) => self.contains_rc(inner),
            _ => false,
        }
    }

    /// Retain every RC-bearing leaf reachable from `ptr` (a pointer to
    /// storage of type `ty`). A no-op if `ty` doesn't `contains_rc`.
    pub(super) fn emit_retain_at(&mut self, ptr: &str, ty: &Ty) {
        self.emit_rc_walk(ptr, ty, true);
    }

    /// Release every RC-bearing leaf reachable from `ptr`. A no-op if `ty`
    /// doesn't `contains_rc`.
    pub(super) fn emit_release_at(&mut self, ptr: &str, ty: &Ty) {
        self.emit_rc_walk(ptr, ty, false);
    }

    /// Release every RC-bearing leaf reachable from a bare (untagged) value
    /// register that isn't backed by any existing storage slot -- spills it
    /// into a fresh, scratch `alloca` first so `emit_release_at`'s
    /// pointer-walking shape has somewhere to read from. For a value that's
    /// only used transiently (a `Map`/`Set` key/element compared against
    /// with `eq_fn` and then discarded, never stored into the collection) --
    /// the same "release whatever `emit_expr` left us owning" shape
    /// `emit_raw_str_ptr`/`emit_print_like` already use for a bare `Str`,
    /// generalized to any RC-bearing type via the same walker `emit_release_at`
    /// uses for a real slot. A no-op if `ty` doesn't `contains_rc`, so it's
    /// always safe to call unconditionally (see `rc.rs`'s module doc comment).
    pub(super) fn emit_release_bare(&mut self, val: &str, ty: &Ty) {
        if !self.contains_rc(ty) {
            return;
        }
        let llvm_ty = self.llvm_ty(ty);
        let tmp = self.tmp_name();
        self.line(&format!("  {} = alloca {}", tmp, llvm_ty));
        self.line(&format!("  store {} {}, {}* {}", llvm_ty, val, llvm_ty, tmp));
        self.emit_release_at(&tmp, ty);
    }

    /// Shared retain/release walker: descend a value's storage exactly the
    /// same way for both (only the runtime helper called on each leaf
    /// differs), so the two can never drift out of sync on which leaves
    /// they visit.
    fn emit_rc_walk(&mut self, ptr: &str, ty: &Ty, retain: bool) {
        if !self.contains_rc(ty) {
            return;
        }
        let helper = if retain { "@star_rc_retain" } else { "@star_rc_release" };
        match ty {
            Ty::Str => {
                // `ptr` is a storage address holding the real `i8*` backing
                // pointer directly (see `Codegen::emit_raw_str_ptr`'s doc
                // comment -- a `Str` value has no extra boxing indirection),
                // so one load reaches the pointer this call needs to
                // retain/release.
                let real = self.tmp_name();
                self.line(&format!("  {} = load i8*, i8** {}", real, ptr));
                self.line(&format!("  call void {}(i8* {})", helper, real));
            }
            Ty::Closure(..) => {
                let cty = self.llvm_ty(ty);
                let loaded = self.tmp_name();
                self.line(&format!("  {} = load {}, {}* {}", loaded, cty, cty, ptr));
                let envp = self.tmp_name();
                self.line(&format!("  {} = extractvalue {} {}, 1", envp, cty, loaded));
                self.line(&format!("  call void {}(i8* {})", helper, envp));
            }
            Ty::Named(n) => {
                let field_tys = self.struct_field_types.get(n).cloned().unwrap_or_default();
                let struct_ty = format!("%{}", n);
                for (i, fty) in field_tys.iter().enumerate() {
                    if !self.contains_rc(fty) {
                        continue;
                    }
                    let gep = self.tmp_name();
                    self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, struct_ty, struct_ty, ptr, i));
                    self.emit_rc_walk(&gep, fty, retain);
                }
            }
            Ty::Tuple(elems) => {
                // Same walk as `Ty::Named` above, just with the element
                // types already in hand instead of a `struct_field_types`
                // lookup, and the anonymous literal struct type from
                // `llvm_ty` instead of a `%name`.
                let struct_ty = self.llvm_ty(ty);
                for (i, fty) in elems.iter().enumerate() {
                    if !self.contains_rc(fty) {
                        continue;
                    }
                    let gep = self.tmp_name();
                    self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, struct_ty, struct_ty, ptr, i));
                    self.emit_rc_walk(&gep, fty, retain);
                }
            }
            Ty::Array(elem, count) => {
                // Same walk as `Ty::Tuple` above, unrolled at codegen time
                // over the compile-time-known `count` instead of a
                // per-field list.
                let elem_llvm = self.llvm_ty(elem);
                let arr_ty = format!("[{} x {}]", count, elem_llvm);
                for i in 0..*count {
                    let gep = self.tmp_name();
                    self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i64 {}", gep, arr_ty, arr_ty, ptr, i));
                    self.emit_rc_walk(&gep, elem, retain);
                }
            }
            Ty::Ring(elem, count) => {
                // Same walk as `Ty::Array` above, just GEP-ing into field 0
                // (`data`) of the `{ [N x T], i64, i64 }` aggregate first --
                // see `crate::codegen::ring`'s module doc comment for why
                // walking every one of the `N` slots unconditionally
                // (regardless of `head`/`len`) is safe: every slot outside
                // the live `[head, head+len)` window is always the element
                // type's zero value, so retaining/releasing it is a no-op.
                let ring_ty = self.llvm_ty(ty);
                let data_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", data_ptr, ring_ty, ring_ty, ptr));
                let elem_llvm = self.llvm_ty(elem);
                let arr_ty = format!("[{} x {}]", count, elem_llvm);
                for i in 0..*count {
                    let gep = self.tmp_name();
                    self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i64 {}", gep, arr_ty, arr_ty, data_ptr, i));
                    self.emit_rc_walk(&gep, elem, retain);
                }
            }
            // A payload enum's active variant is only known at runtime (the
            // tag) -- load it, then branch per variant that actually carries
            // an RC-bearing field (skipping the rest at codegen time, same
            // "only emit a check for what can possibly need it" shape
            // `emit_rc_walk`'s other arms already use), bitcasting the shared
            // payload buffer to that variant's own field layout exactly the
            // way `TypedExpr::EnumVariant` construction and `Pattern::
            // EnumVariant` destructuring already do, then recursing into each
            // RC-bearing field. Previously this whole arm was missing --
            // `Ty::Enum` fell through to the `_ => {}` no-op below, and
            // `contains_rc` (before its own fix, just above) always returned
            // `false` for any enum, so an `Option<str>`/`Result<str,str>`/...
            // local that was never explicitly matched (e.g. a `let o =
            // make_some(s)` never consumed) leaked its payload's RC content
            // unboundedly at every scope exit -- confirmed via real unbounded
            // working-set growth (~83MB -> 390MB+ in under 2 seconds).
            Ty::Enum(n) => {
                let variants = self.enum_variant_fields.get(n).cloned().unwrap_or_default();
                if variants.iter().all(|fields| !fields.iter().any(|f| self.contains_rc(f))) {
                    return;
                }
                let enum_ty = format!("%{}", n);
                let words = self.enum_payload_words(n);
                let elem = self.enum_payload_elem_ty(n);
                let tag_gep = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", tag_gep, enum_ty, enum_ty, ptr));
                let tag = self.tmp_name();
                self.line(&format!("  {} = load i32, i32* {}", tag, tag_gep));
                let payload_gep = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", payload_gep, enum_ty, enum_ty, ptr));
                for (idx, fields) in variants.iter().enumerate() {
                    if !fields.iter().any(|f| self.contains_rc(f)) {
                        continue;
                    }
                    let match_label = self.block_label("enum_rc_variant");
                    let next_label = self.block_label("enum_rc_next");
                    let is_variant = self.tmp_name();
                    self.line(&format!("  {} = icmp eq i32 {}, {}", is_variant, tag, idx));
                    self.line(&format!("  br i1 {}, label %{}, label %{}", is_variant, match_label, next_label));
                    self.open_block(&match_label);
                    let variant_ty = self.enum_variant_payload_llvm_ty(n, idx as u32);
                    let variant_ptr = self.tmp_name();
                    self.line(&format!("  {} = bitcast [{} x {}]* {} to {}*", variant_ptr, words, elem, payload_gep, variant_ty));
                    for (fi, fty) in fields.iter().enumerate() {
                        if !self.contains_rc(fty) {
                            continue;
                        }
                        let field_gep = self.tmp_name();
                        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", field_gep, variant_ty, variant_ty, variant_ptr, fi));
                        self.emit_rc_walk(&field_gep, fty, retain);
                    }
                    self.line(&format!("  br label %{}", next_label));
                    self.open_block(&next_label);
                }
            }
            Ty::List(_) | Ty::Map(..) | Ty::Set(_) | Ty::Table(_) | Ty::Bytes | Ty::Palette => {
                // Same shape as `Ty::Str`: `ptr` is a storage address
                // holding the object pointer directly, no extra boxing.
                // Releasing the elements/keys/values *inside* the buffer
                // (when the last reference goes away) is the generated
                // release thunk's job (`Codegen::list_release_thunk_operand`/
                // `crate::codegen::map`/`crate::codegen::set`/
                // `crate::codegen::table`'s own release-thunk generators),
                // not this walker's -- that keeps retain/release here O(1)
                // regardless of collection size, since only the object
                // pointer's own refcount changes on every read/scope-exit.
                let real = self.tmp_name();
                self.line(&format!("  {} = load i8*, i8** {}", real, ptr));
                self.line(&format!("  call void {}(i8* {})", helper, real));
            }
            _ => {}
        }
    }

    /// Push a fresh, empty scope frame for tracking RC-owning locals
    /// declared directly in the block about to be emitted (function body,
    /// closure body, `if`/`while`/`for`/`frame` body, `match` arm body).
    pub(super) fn push_scope(&mut self) {
        self.owned_stack.push(Vec::new());
    }

    /// Pop the innermost scope frame. If `emit_release` is true (the block
    /// fell through normally, so this is still a live, un-terminated basic
    /// block), emits a release for every RC-owning local it tracked; if the
    /// block already ended in an explicit `return`/`break`/`continue` (see
    /// `emit_releases_for_return`/`emit_releases_since`, which already
    /// emitted the right releases into that now-dead branch), pass `false`
    /// so this only does the structural pop -- emitting here too would
    /// place instructions after a terminator, which LLVM rejects.
    pub(super) fn pop_scope(&mut self, emit_release: bool) {
        if let Some(frame) = self.owned_stack.pop() {
            if emit_release {
                for (ptr, ty) in frame.iter().rev() {
                    self.emit_release_at(ptr, ty);
                }
            }
        }
    }

    /// Record a freshly `let`/parameter-bound local as owned by the
    /// current (innermost) scope, if its type carries any RC content, so
    /// it's released when that scope ends (normally or via an early exit).
    pub(super) fn track_owned(&mut self, ptr: &str, ty: &Ty) {
        if self.contains_rc(ty) {
            if let Some(frame) = self.owned_stack.last_mut() {
                frame.push((ptr.to_string(), ty.clone()));
            }
        }
    }

    /// Release every RC-owning local in every scope frame currently open,
    /// without popping any of them (Rust-side recursion still needs to
    /// unwind and pop each one structurally later) -- for an unconditional
    /// `return`, which exits every open scope up to the function root at once.
    pub(super) fn emit_releases_for_return(&mut self) {
        for frame in self.owned_stack.clone().iter().rev() {
            for (ptr, ty) in frame.iter().rev() {
                self.emit_release_at(ptr, ty);
            }
        }
    }

    /// Release every RC-owning local in scope frames opened since `depth`
    /// (the `owned_stack` length recorded when the innermost enclosing loop
    /// was entered, via `loop_stack`), without popping -- for `break`/
    /// `continue`, which only exits the scopes opened inside that loop.
    pub(super) fn emit_releases_since(&mut self, depth: usize) {
        for frame in self.owned_stack.clone()[depth..].iter().rev() {
            for (ptr, ty) in frame.iter().rev() {
                self.emit_release_at(ptr, ty);
            }
        }
    }
}
