//! `Flags<E>` codegen: a typed bitflag set -- see `Ty::Flags`'s doc comment.
//! Lowers to a bare `i64` bitmask, one bit per `E` variant in declaration
//! order. A fieldless enum value is already just its bare `i32` declaration-
//! order discriminant at runtime (see `Codegen::llvm_ty`'s `Ty::Enum` arm),
//! so turning an *arbitrary* `E`-typed expression (not just a literal
//! `EnumName::Variant`) into its bit is always `1i64 << zext(discriminant)` --
//! no compile-time variant-name lookup needed, unlike
//! `Codegen::enum_variant_index` (which `EnumVariant` literal codegen uses
//! instead, since *that* node carries a variant name rather than an
//! already-evaluated expression).

use crate::types::*;

use super::Codegen;

impl Codegen {
    /// `Flags<E>(a, b, ...)` -- OR every argument's bit together, starting
    /// from an empty (`0`) mask. See `Checker::infer_flags_new`. `enum_name`
    /// isn't needed here -- unlike `Codegen::enum_variant_index` (used by
    /// `EnumVariant` literal codegen, which only carries a variant *name*),
    /// each argument here is an already-evaluated `E`-typed expression whose
    /// bare runtime value already *is* the discriminant (see this module's
    /// doc comment) -- but it's threaded through anyway to mirror `Checker::
    /// infer_flags_new`'s signature and keep the call site self-documenting.
    pub(super) fn emit_flags_new(&mut self, _enum_name: &str, args: &[TypedExpr]) -> String {
        let mut acc = "0".to_string();
        for a in args {
            let bit = self.emit_flags_variant_bit(a);
            let next = self.tmp_name();
            self.line(&format!("  {} = or i64 {}, {}", next, acc, bit));
            acc = next;
        }
        format!("i64 {}", acc)
    }

    /// Evaluate an `E`-typed expression and return `1i64 << discriminant` as
    /// a bare `i64` register.
    fn emit_flags_variant_bit(&mut self, e: &TypedExpr) -> String {
        let e_ty = self.expr_ty(e);
        let e_val = self.emit_expr(e);
        let e_bare = self.untag(&e_val, &e_ty);
        let ext = self.tmp_name();
        self.line(&format!("  {} = zext i32 {} to i64", ext, e_bare));
        let mask = self.tmp_name();
        self.line(&format!("  {} = shl i64 1, {}", mask, ext));
        mask
    }

    /// `flags_has(f, e) -> bool`: `f & (1 << e) != 0`.
    pub(super) fn emit_flags_has(&mut self, f: &TypedExpr, e: &TypedExpr) -> String {
        let f_ty = self.expr_ty(f);
        let f_val = self.emit_expr(f);
        let f_bare = self.untag(&f_val, &f_ty);
        let mask = self.emit_flags_variant_bit(e);
        let anded = self.tmp_name();
        self.line(&format!("  {} = and i64 {}, {}", anded, f_bare, mask));
        let reg = self.tmp_name();
        self.line(&format!("  {} = icmp ne i64 {}, 0", reg, anded));
        format!("i1 {}", reg)
    }

    /// `flags_with(f, e) -> Flags<E>` / `flags_without(f, e) -> Flags<E>` --
    /// `with` is `f | (1 << e)`, `without` is `f & ~(1 << e)`.
    pub(super) fn emit_flags_with_without(&mut self, f: &TypedExpr, e: &TypedExpr, with: bool) -> String {
        let f_ty = self.expr_ty(f);
        let f_val = self.emit_expr(f);
        let f_bare = self.untag(&f_val, &f_ty);
        let mask = self.emit_flags_variant_bit(e);
        let reg = self.tmp_name();
        if with {
            self.line(&format!("  {} = or i64 {}, {}", reg, f_bare, mask));
        } else {
            let notmask = self.tmp_name();
            self.line(&format!("  {} = xor i64 {}, -1", notmask, mask));
            self.line(&format!("  {} = and i64 {}, {}", reg, f_bare, notmask));
        }
        format!("i64 {}", reg)
    }

    /// `flags_is_empty(f) -> bool`: `f == 0`.
    pub(super) fn emit_flags_is_empty(&mut self, f: &TypedExpr) -> String {
        let f_ty = self.expr_ty(f);
        let f_val = self.emit_expr(f);
        let f_bare = self.untag(&f_val, &f_ty);
        let reg = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, 0", reg, f_bare));
        format!("i1 {}", reg)
    }
}
