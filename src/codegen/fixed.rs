//! `Fixed<Bits, Frac>` codegen: deterministic fixed-point arithmetic -- see
//! `Ty::Fixed`'s doc comment.
//!
//! Lowers to a bare `i{Bits}` (Q format, signed). `+`/`-` reuse
//! `Codegen::emit_checked_sized_int_arith` as-is (no rescaling needed at
//! that precision); `*`/`/` rescale by widening through `i128`
//! unconditionally, so a narrow `Fixed<8,4>` constructed from/computed with
//! a wider source is never a correctness hazard (see `Ty::Fixed`'s doc
//! comment for why a fixed `i128` scratch width beats doubling `Bits`
//! itself -- LLVM natively supports `i128` `mul`/`sdiv`, clang links
//! whatever compiler-rt libcall the target needs, so this needs no new
//! intrinsic declarations). Construction accepts either an int-shaped value
//! (an exact, deterministic `shl` by `Frac`) or a `float`/`f64` (scaled by
//! `2^Frac` then the pre-existing saturating `llvm.fptosi.sat` intrinsic --
//! `Codegen::emit_builtins` already declares every width/source-float
//! combination this needs for `as`, so no new declarations are needed here).

use crate::ast::BinOp;
use crate::types::*;

use super::{format_f32_literal, Codegen};

/// Hex-encode an `f64` as an LLVM IR `double` constant -- the `double`
/// counterpart to `format_f32_literal` (no rounding step needed, since the
/// value is already `f64`-precision).
fn format_f64_literal(v: f64) -> String {
    format!("0x{:016X}", v.to_bits())
}

impl Codegen {
    /// `Fixed<Bits, Frac>(value)` -- see `Ty::Fixed`'s doc comment.
    /// `Checker::infer_expr`'s `Expr::FixedNew` arm has already validated
    /// `value`'s type is either int-shaped or `Float`/`F64`.
    pub(super) fn emit_fixed_new(&mut self, value: &TypedExpr, bits: u32, frac: u32) -> String {
        let value_ty = self.expr_ty(value);
        let val = self.emit_expr(value);
        let bare = self.untag(&val, &value_ty);
        if let Some((src_width, src_signed)) = value_ty.int_shape() {
            let wide = self.emit_widen_i128(&bare, src_width, src_signed);
            let shifted = self.tmp_name();
            self.line(&format!("  {} = shl i128 {}, {}", shifted, wide, frac));
            let narrow = self.emit_checked_narrow_i128(&shifted, bits, "Fixed<Bits,Frac> construction overflow");
            return format!("i{} {}", bits, narrow);
        }
        self.emit_float_to_fixed(&bare, matches!(value_ty, Ty::F64), bits, frac)
    }

    /// Sign/zero-extend a bare `i{width}` register/literal to `i128`.
    fn emit_widen_i128(&mut self, bare: &str, width: u32, signed: bool) -> String {
        let reg = self.tmp_name();
        let op = if signed { "sext" } else { "zext" };
        self.line(&format!("  {} = {} i{} {} to i128", reg, op, width, bare));
        reg
    }

    /// Truncate a bare `i128` register back down to `i{bits}`, aborting if
    /// the value doesn't actually fit (`sext(trunc(x)) == x`) -- shared by
    /// construction-from-int, `*`, and `/`.
    fn emit_checked_narrow_i128(&mut self, wide: &str, bits: u32, what: &str) -> String {
        let narrow = self.tmp_name();
        self.line(&format!("  {} = trunc i128 {} to i{}", narrow, wide, bits));
        let back = self.tmp_name();
        self.line(&format!("  {} = sext i{} {} to i128", back, bits, narrow));
        let fits = self.tmp_name();
        self.line(&format!("  {} = icmp eq i128 {}, {}", fits, back, wide));

        let fail_label = self.block_label("fixed_overflow_fail");
        let ok_label = self.block_label("fixed_overflow_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", fits, ok_label, fail_label));

        self.open_block(&fail_label);
        let msg = format!("star runtime error: {}\n", what);
        self.emit_abort_with_message(&msg);

        self.open_block(&ok_label);
        narrow
    }

    /// Binary op between two `Fixed<Bits, Frac>` operands
    /// (`Checker::infer_binop_ty` already guarantees an exact `(Bits, Frac)`
    /// match, and rejects `%` before this is ever reached). `l`/`r` are bare
    /// (untagged) `i{bits}` registers/literals.
    pub(super) fn emit_fixed_binop(&mut self, l: &str, r: &str, bits: u32, frac: u32, op: BinOp) -> String {
        match op {
            BinOp::Add | BinOp::Sub => self.emit_checked_sized_int_arith(l, r, bits, true, op),
            BinOp::Mul => self.emit_fixed_mul(l, r, bits, frac),
            BinOp::Div => self.emit_fixed_div(l, r, bits, frac),
            BinOp::Eq | BinOp::Ne | BinOp::Lt | BinOp::Gt | BinOp::Le | BinOp::Ge => {
                let ity = format!("i{}", bits);
                let reg = self.tmp_name();
                let opcode = match op {
                    BinOp::Eq => "icmp eq",
                    BinOp::Ne => "icmp ne",
                    BinOp::Lt => "icmp slt",
                    BinOp::Gt => "icmp sgt",
                    BinOp::Le => "icmp sle",
                    BinOp::Ge => "icmp sge",
                    _ => unreachable!("matched by the outer arm"),
                };
                self.line(&format!("  {} = {} {} {}, {}", reg, opcode, ity, l, r));
                format!("i1 {}", reg)
            }
            BinOp::Rem => unreachable!("Checker::infer_binop_ty rejects `%` on Fixed<Bits,Frac>"),
            BinOp::And | BinOp::Or => unreachable!("`&&`/`||` never reach a type-specific binop dispatch"),
        }
    }

    /// `a * b` in `Q(bits-frac).frac` format: widen both to `i128`, multiply
    /// (always exact -- the product of two `bits`-bit signed values always
    /// fits in `2*bits <= 128` bits), arithmetic-shift right by `frac`
    /// (floor rounding, matching two's complement `ashr`), then narrow back
    /// with an overflow check.
    fn emit_fixed_mul(&mut self, l: &str, r: &str, bits: u32, frac: u32) -> String {
        let wl = self.emit_widen_i128(l, bits, true);
        let wr = self.emit_widen_i128(r, bits, true);
        let prod = self.tmp_name();
        self.line(&format!("  {} = mul i128 {}, {}", prod, wl, wr));
        let shifted = self.tmp_name();
        self.line(&format!("  {} = ashr i128 {}, {}", shifted, prod, frac));
        let narrow = self.emit_checked_narrow_i128(&shifted, bits, "Fixed<Bits,Frac> multiplication overflow");
        format!("i{} {}", bits, narrow)
    }

    /// `a / b` in `Q(bits-frac).frac` format: widen both to `i128`, shift the
    /// dividend left by `frac` *before* dividing (always safe at this width
    /// -- `i128 >= bits + frac` always holds since `frac < bits <= 64`),
    /// zero-check the divisor, `sdiv`, then narrow back with an overflow
    /// check.
    fn emit_fixed_div(&mut self, l: &str, r: &str, bits: u32, frac: u32) -> String {
        let wl = self.emit_widen_i128(l, bits, true);
        let wr = self.emit_widen_i128(r, bits, true);
        let shifted_l = self.tmp_name();
        self.line(&format!("  {} = shl i128 {}, {}", shifted_l, wl, frac));

        let is_zero = self.tmp_name();
        self.line(&format!("  {} = icmp eq i128 {}, 0", is_zero, wr));
        let fail_label = self.block_label("fixed_div_zero_fail");
        let ok_label = self.block_label("fixed_div_zero_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_zero, fail_label, ok_label));

        self.open_block(&fail_label);
        self.emit_abort_with_message("star runtime error: `Fixed<Bits,Frac>` division by zero\n");

        self.open_block(&ok_label);
        let quotient = self.tmp_name();
        self.line(&format!("  {} = sdiv i128 {}, {}", quotient, shifted_l, wr));
        let narrow = self.emit_checked_narrow_i128(&quotient, bits, "Fixed<Bits,Frac> division overflow");
        format!("i{} {}", bits, narrow)
    }

    /// `Fixed<Bits, Frac> as float/f64` -- a true scaled conversion (not a
    /// bit reinterpret): `sitofp` the raw `i{bits}` value (exact for any
    /// magnitude representable at `bits <= 64`, since `double` has a 52-bit
    /// mantissa -- the same precision limit any float already has) then
    /// `fdiv` by the constant `2^frac`. `bare` must already be untagged.
    /// Also backs `Codegen::emit_print_like`'s human-readable `Fixed`
    /// formatting.
    pub(super) fn emit_fixed_to_float(&mut self, bare: &str, bits: u32, frac: u32, target_f64: bool) -> String {
        let target_llty = if target_f64 { "double" } else { "float" };
        let as_float = self.tmp_name();
        self.line(&format!("  {} = sitofp i{} {} to {}", as_float, bits, bare, target_llty));
        let scale = 2f64.powi(frac as i32);
        let scale_lit = if target_f64 { format_f64_literal(scale) } else { format_f32_literal(scale) };
        let reg = self.tmp_name();
        self.line(&format!("  {} = fdiv {} {}, {}", reg, target_llty, as_float, scale_lit));
        format!("{} {}", target_llty, reg)
    }

    /// `float/f64 as Fixed<Bits, Frac>` -- the construction path (`fmul` by
    /// `2^frac` then the saturating `fptosi.sat`), shared with
    /// `emit_fixed_new`'s float branch. `bare` must already be untagged.
    pub(super) fn emit_float_to_fixed(&mut self, bare: &str, src_is_f64: bool, bits: u32, frac: u32) -> String {
        let src_llty = if src_is_f64 { "double" } else { "float" };
        let scale = 2f64.powi(frac as i32);
        let scale_lit = if src_is_f64 { format_f64_literal(scale) } else { format_f32_literal(scale) };
        let scaled = self.tmp_name();
        self.line(&format!("  {} = fmul {} {}, {}", scaled, src_llty, bare, scale_lit));
        let fty_suffix = if src_is_f64 { "f64" } else { "f32" };
        let reg = self.tmp_name();
        self.line(&format!(
            "  {} = call i{} @llvm.fptosi.sat.i{}.{}({} {})",
            reg, bits, bits, fty_suffix, src_llty, scaled
        ));
        format!("i{} {}", bits, reg)
    }
}
