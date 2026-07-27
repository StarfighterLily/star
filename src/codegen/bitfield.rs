//! `BitField<N>` codegen: a packed bit register -- see `Ty::BitField`'s doc
//! comment. Lowers to a bare `i{N}`, so construction is just an int-shaped
//! widen/narrow (mirroring `Codegen::emit_time_new`'s "sign/zero-extend or
//! truncate per the source's own signedness" rule, generalized to also
//! truncate when the source is *wider* than `N`, which `Tick`/`Duration`/
//! `Instant`'s fixed `i64` target never needs to). The free-function surface
//! (`bit_get`/`bit_set`/`bit_clear`/`bit_toggle`/`bit_and`/`bit_or`/
//! `bit_xor`/`bit_not`) is plain `shl`/`and`/`or`/`xor`/`icmp`, dispatched by
//! name exactly like `symbol_name`/`bytes_from_str` (`Checker::infer_expr`'s
//! `Expr::Call` arm has already validated arity/types via `Ty::bit_shape`/
//! `Ty::bitwise_combine_shape`). The real `&`/`|`/`^`/`~`/`<<`/`>>` operator
//! grammar (`todo.md` P0 #3) reuses those exact same two shape queries --
//! `Codegen::emit_bitwise_binop`/`emit_shift_binop` below are `emit_binop`'s
//! (`crate::codegen::vector_math`) dedicated dispatch targets for them, the
//! operator-syntax counterpart of `emit_bit_combine`/`emit_bit_not` just
//! above; `Codegen::emit_unary`'s `UnOp::BitNot` arm calls `emit_bit_not`
//! directly rather than duplicating it, since `~x` and `bit_not(x)` are
//! identical operations.

use crate::types::*;

use super::Codegen;

impl Codegen {
    /// `BitField<N>(value)` -- see `Ty::BitField`'s doc comment.
    /// `Checker::infer_expr`'s `Expr::BitFieldNew` arm has already validated
    /// `value`'s type is int-shaped.
    pub(super) fn emit_bitfield_new(&mut self, value: &TypedExpr, bits: u32) -> String {
        let value_ty = self.expr_ty(value);
        let val = self.emit_expr(value);
        let bare = self.untag(&val, &value_ty);
        let (src_width, signed) = value_ty
            .int_shape()
            .expect("Checker::infer_expr guarantees an int-shaped BitField<N> constructor argument");
        format!("i{} {}", bits, self.emit_int_widen_narrow(&bare, src_width, signed, bits))
    }

    /// Sign/zero-extend (per `signed`) or truncate a bare `i{src_width}`
    /// register/literal to `i{dst_width}`, matching whichever direction is
    /// actually needed -- a no-op (returns `bare` unchanged) when the widths
    /// already match.
    fn emit_int_widen_narrow(&mut self, bare: &str, src_width: u32, signed: bool, dst_width: u32) -> String {
        if src_width == dst_width {
            return bare.to_string();
        }
        let reg = self.tmp_name();
        if src_width < dst_width {
            let op = if signed { "sext" } else { "zext" };
            self.line(&format!("  {} = {} i{} {} to i{}", reg, op, src_width, bare, dst_width));
        } else {
            self.line(&format!("  {} = trunc i{} {} to i{}", reg, src_width, bare, dst_width));
        }
        reg
    }

    /// `idx mod width`, widened/truncated to a bare `i{width}` register.
    /// `idx` (a bare `i32` register/literal) is first reduced mod `width` --
    /// `width` is always a power of two (`{8, 16, 32, 64}`,
    /// `Checker::resolve_type`'s restriction), so `idx & (width - 1)` is an
    /// exact, cheap modulo -- and *then* widened/truncated to `i{width}`, so
    /// the result is always a legal shift amount (`0..width`). This is a
    /// real correctness requirement, not just defensive polish: LLVM's
    /// `shl`/`lshr`/`ashr` are a poison value for a shift amount `>= width`
    /// (unlike x86 hardware, which masks the count itself), so an
    /// out-of-range count (e.g. `bit_get(x, 99)` on an `8`-bit `x`, or `x <<
    /// 99`) would otherwise be undefined behavior, not just a "wrong but
    /// safe" answer -- masking first keeps this in line with this
    /// compiler's existing "safe, not panicking" convention for other
    /// builtin edge cases like an out-of-bounds `List<T>` index, and
    /// doubles as the exact mod-width masking x86's own `SHL`/`SHR`/`SAR`
    /// hardware instructions perform on their count operand -- the real
    /// hardware semantics `Codegen::emit_shift_binop` needs to match for
    /// Nova's own opcode emulation.
    fn emit_shift_amount(&mut self, idx_i32: &str, width: u32) -> String {
        let masked = self.tmp_name();
        self.line(&format!("  {} = and i32 {}, {}", masked, idx_i32, width - 1));
        self.emit_int_widen_narrow(&masked, 32, false, width)
    }

    /// `1 << (idx mod width)` as a bare `i{width}` register -- see
    /// `emit_shift_amount`'s doc comment for why the masking step is a
    /// correctness requirement, not just polish.
    fn emit_bit_mask(&mut self, idx_i32: &str, width: u32) -> String {
        let idx = self.emit_shift_amount(idx_i32, width);
        let mask = self.tmp_name();
        self.line(&format!("  {} = shl i{} 1, {}", mask, width, idx));
        mask
    }

    /// `bit_get(x, i) -> bool`: `(x >> i) & 1 != 0`, computed as `x & (1 <<
    /// i) != 0` (one fewer instruction than a shift-then-mask-by-1).
    pub(super) fn emit_bit_get(&mut self, x: &TypedExpr, idx: &TypedExpr) -> String {
        let x_ty = self.expr_ty(x);
        let (width, _) = x_ty.bit_shape().expect("Checker::infer_expr guarantees a bit-shaped bit_get argument");
        let x_val = self.emit_expr(x);
        let x_bare = self.untag(&x_val, &x_ty);
        let idx_val = self.emit_expr(idx);
        let idx_bare = self.untag(&idx_val, &Ty::Int);
        let mask = self.emit_bit_mask(&idx_bare, width);
        let anded = self.tmp_name();
        self.line(&format!("  {} = and i{} {}, {}", anded, width, x_bare, mask));
        let reg = self.tmp_name();
        self.line(&format!("  {} = icmp ne i{} {}, 0", reg, width, anded));
        format!("i1 {}", reg)
    }

    /// `bit_set(x, i)` / `bit_clear(x, i)` / `bit_toggle(x, i)` -- `set` is
    /// `x | mask`, `clear` is `x & ~mask`, `toggle` is `x ^ mask`.
    pub(super) fn emit_bit_set_clear_toggle(&mut self, x: &TypedExpr, idx: &TypedExpr, kind: BitIndexOp) -> String {
        let x_ty = self.expr_ty(x);
        let (width, _) = x_ty.bit_shape().expect("Checker::infer_expr guarantees a bit-shaped argument");
        let x_val = self.emit_expr(x);
        let x_bare = self.untag(&x_val, &x_ty);
        let idx_val = self.emit_expr(idx);
        let idx_bare = self.untag(&idx_val, &Ty::Int);
        let mask = self.emit_bit_mask(&idx_bare, width);
        let reg = self.tmp_name();
        match kind {
            BitIndexOp::Set => self.line(&format!("  {} = or i{} {}, {}", reg, width, x_bare, mask)),
            BitIndexOp::Toggle => self.line(&format!("  {} = xor i{} {}, {}", reg, width, x_bare, mask)),
            BitIndexOp::Clear => {
                let notmask = self.tmp_name();
                self.line(&format!("  {} = xor i{} {}, -1", notmask, width, mask));
                self.line(&format!("  {} = and i{} {}, {}", reg, width, x_bare, notmask));
            }
        }
        format!("i{} {}", width, reg)
    }

    /// `bit_and(a, b)` / `bit_or(a, b)` / `bit_xor(a, b)`. `Checker::
    /// infer_expr` already guarantees `a`/`b` share the identical type (via
    /// `Ty::bitwise_combine_shape`), so both operands lower to the same
    /// `i{width}`.
    pub(super) fn emit_bit_combine(&mut self, a: &TypedExpr, b: &TypedExpr, opcode: &str) -> String {
        let a_ty = self.expr_ty(a);
        let (width, _) = a_ty.bitwise_combine_shape().expect("Checker::infer_expr guarantees a bitwise-combinable argument");
        let a_val = self.emit_expr(a);
        let a_bare = self.untag(&a_val, &a_ty);
        let b_ty = self.expr_ty(b);
        let b_val = self.emit_expr(b);
        let b_bare = self.untag(&b_val, &b_ty);
        let reg = self.tmp_name();
        self.line(&format!("  {} = {} i{} {}, {}", reg, opcode, width, a_bare, b_bare));
        format!("i{} {}", width, reg)
    }

    /// `bit_not(x)` -- `x ^ -1` (an all-ones mask of the matching width).
    pub(super) fn emit_bit_not(&mut self, x: &TypedExpr) -> String {
        let x_ty = self.expr_ty(x);
        let (width, _) = x_ty.bit_shape().expect("Checker::infer_expr guarantees a bit-shaped bit_not argument");
        let x_val = self.emit_expr(x);
        let x_bare = self.untag(&x_val, &x_ty);
        let reg = self.tmp_name();
        self.line(&format!("  {} = xor i{} {}, -1", reg, width, x_bare));
        format!("i{} {}", width, reg)
    }

    /// `a & b` / `a | b` / `a ^ b` -- `emit_binop`'s (`crate::codegen::
    /// vector_math`) dispatch target for `BinOp::BitAnd`/`BitOr`/`BitXor`.
    /// The operator-syntax counterpart of `emit_bit_combine` just above:
    /// same opcode/shape (`Checker::infer_binop_ty` guarantees `lty`/`rty`
    /// are the identical `bitwise_combine_shape()`-having type), just taking
    /// already-evaluated operand strings the way every other `emit_binop`
    /// dispatch target does, instead of re-evaluating a `TypedExpr` pair
    /// itself.
    pub(super) fn emit_bitwise_binop(&mut self, lhs: &str, lty: &Ty, rhs: &str, rty: &Ty, opcode: &str) -> String {
        let (width, _) = lty.bitwise_combine_shape().expect("Checker::infer_binop_ty guarantees a bitwise-combinable operand");
        let l = self.untag(lhs, lty);
        let r = self.untag(rhs, rty);
        let reg = self.tmp_name();
        self.line(&format!("  {} = {} i{} {}, {}", reg, opcode, width, l, r));
        format!("i{} {}", width, reg)
    }

    /// `a << b` / `a >> b` -- `emit_binop`'s dispatch target for
    /// `BinOp::Shl`/`Shr`. `lty` is any `Ty::bit_shape()` type (an integer of
    /// any width, `Wrapping<T>`, or `BitField<N>`); `rty` is always `Ty::Int`
    /// (`Checker::infer_shift_ty` restricts the shift count to a plain
    /// `int`, the same convention `bit_get`'s bit-index argument already
    /// uses). `b` is first reduced mod the *left* operand's own width via
    /// `emit_shift_amount` -- see that function's doc comment for why this
    /// is a real correctness requirement (an unmasked out-of-range shift
    /// amount is an LLVM poison value), and note it also happens to be
    /// exactly the mod-width masking x86's own hardware `SHL`/`SHR`/`SAR`
    /// perform on their count operand, which is what actually makes this a
    /// faithful primitive for Nova's own opcode emulation rather than just a
    /// safety patch. `>>` is arithmetic (`ashr`, sign-extending) on a signed
    /// left operand and logical (`lshr`, zero-filling) on unsigned -- `<<`
    /// is the same `shl` opcode either way (shifting in zero bits from the
    /// low end never depends on signedness).
    pub(super) fn emit_shift_binop(&mut self, lhs: &str, lty: &Ty, rhs: &str, rty: &Ty, is_shl: bool) -> String {
        let (width, signed) = lty.bit_shape().expect("Checker::infer_binop_ty guarantees a bit-shaped shift left operand");
        let l = self.untag(lhs, lty);
        let r = self.untag(rhs, rty);
        let amount = self.emit_shift_amount(&r, width);
        let reg = self.tmp_name();
        let opcode = if is_shl { "shl" } else if signed { "ashr" } else { "lshr" };
        self.line(&format!("  {} = {} i{} {}, {}", reg, opcode, width, l, amount));
        format!("i{} {}", width, reg)
    }
}

/// Which of `bit_set`/`bit_clear`/`bit_toggle` a call site is -- see
/// `Codegen::emit_bit_set_clear_toggle`.
#[derive(Clone, Copy)]
pub(super) enum BitIndexOp {
    Set,
    Clear,
    Toggle,
}
