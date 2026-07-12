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

use crate::types::{Ty, TypedExpr};

use super::Codegen;

impl Codegen {
    /// True for the expression kinds `emit_expr` retains on (`Ident`, a
    /// non-swizzle `Field`, `ListIndex`, `GenRefIndex` -- see their arms in
    /// `expr.rs`/`list.rs`/`arena.rs`), i.e. a *read of an existing owned
    /// slot* rather than a fresh construction. Used by the couple of call
    /// sites (`emit_raw_str_ptr`, `emit_print_like`) that consume a `Str`
    /// value *transiently* -- extracting its raw bytes for a synchronous
    /// library call or `printf`, never keeping the pointer around -- to
    /// know whether `emit_expr` just retained a reference on their behalf
    /// that needs balancing back out, or whether nothing was retained
    /// (a fresh construction like a literal or a `concat` call) and
    /// there's nothing to release.
    pub(super) fn is_rc_borrowing_read(e: &TypedExpr) -> bool {
        matches!(e, TypedExpr::Ident { .. } | TypedExpr::Field { .. } | TypedExpr::ListIndex { .. } | TypedExpr::GenRefIndex { .. })
    }

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
            Ty::Str | Ty::Closure(..) | Ty::List(_) => true,
            Ty::Named(n) => self
                .struct_field_types
                .get(n)
                .map(|fields| fields.iter().any(|f| self.contains_rc(f)))
                .unwrap_or(false),
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
            Ty::List(_) => {
                // Same shape as `Ty::Str`: `ptr` is a storage address
                // holding the object pointer directly, no extra boxing.
                // Releasing the elements *inside* the buffer (when the last
                // reference goes away) is the generated release thunk's job
                // (`Codegen::list_release_thunk_operand`), not this walker's
                // -- that keeps retain/release here O(1) regardless of list
                // length, since only the object pointer's own refcount
                // changes on every read/scope-exit.
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
