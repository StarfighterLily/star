//! `Wrapping<T>` codegen: silent-overflow arithmetic on any integer width,
//! the explicit opt-in for the wraparound behavior every other numeric type
//! now traps on by default -- see `Ty::Wrapping`'s doc comment.
//!
//! Lowers to the exact same LLVM integer type as `T` (no tag, no boxing), so
//! construction (`Wrapping<T>(value)`) needs no dedicated codegen at all --
//! `Codegen::emit_expr`'s `TypedExpr::WrappingNew` arm just evaluates
//! `value` directly and reuses its (already correctly-tagged) result. Only
//! arithmetic is genuinely new: `+`/`-`/`*` are plain (untrapped) opcodes,
//! and `/`/`%` still trap on a zero divisor but wrap the one true overflow
//! case (`MIN / -1`, `MIN % -1`) instead of trapping, since LLVM's
//! `sdiv`/`srem` instructions are undefined behavior on that exact input
//! regardless of the desired wrap semantics.

use crate::ast::BinOp;
use crate::diagnostics::Span;

use super::vector_math::signed_min_literal;
use super::Codegen;

impl Codegen {
    /// Binary op between two same-width, same-signedness `Wrapping<T>`
    /// operands (`Checker::infer_binop_ty` already guarantees an exact type
    /// match between the two operands). `l`/`r` are bare (untagged) `iN`
    /// registers/literals.
    pub(super) fn emit_wrapping_binop(&mut self, l: &str, r: &str, width: u32, signed: bool, op: BinOp) -> String {
        let ity = format!("i{}", width);
        let is_cmp = matches!(op, BinOp::Eq | BinOp::Ne | BinOp::Lt | BinOp::Gt | BinOp::Le | BinOp::Ge);
        if matches!(op, BinOp::Div | BinOp::Rem) {
            return self.emit_wrapping_sized_int_div(l, r, width, signed, op);
        }
        if matches!(op, BinOp::Add | BinOp::Sub | BinOp::Mul) {
            // Plain, untrapped opcodes -- exactly what `Ty::Int` (`i32`)
            // already uses for its own permanent silent-wraparound exception
            // (see `Ty::I8`'s doc comment), just generalized to every width.
            let reg = self.tmp_name();
            let opcode = match op {
                BinOp::Add => "add",
                BinOp::Sub => "sub",
                BinOp::Mul => "mul",
                _ => unreachable!("caller only routes Add/Sub/Mul here"),
            };
            self.line(&format!("  {} = {} {} {}, {}", reg, opcode, ity, l, r));
            return format!("{} {}", ity, reg);
        }
        let reg = self.tmp_name();
        let opcode = match op {
            BinOp::Eq => format!("icmp eq {}", ity),
            BinOp::Ne => format!("icmp ne {}", ity),
            BinOp::Lt => format!("icmp {} {}", if signed { "slt" } else { "ult" }, ity),
            BinOp::Gt => format!("icmp {} {}", if signed { "sgt" } else { "ugt" }, ity),
            BinOp::Le => format!("icmp {} {}", if signed { "sle" } else { "ule" }, ity),
            BinOp::Ge => format!("icmp {} {}", if signed { "sge" } else { "uge" }, ity),
            BinOp::And | BinOp::Or => {
                self.err("internal error: `&&`/`||` should be short-circuit lowered, not reach emit_wrapping_binop", Span::dummy());
                format!("add {}", ity)
            }
            BinOp::BitAnd | BinOp::BitOr | BinOp::BitXor | BinOp::Shl | BinOp::Shr => unreachable!(
                "`&`/`|`/`^`/`<<`/`>>` on Wrapping<T> are dispatched straight to emit_bitwise_binop/emit_shift_binop by emit_binop, before emit_wrapping_binop is ever reached"
            ),
            BinOp::Add | BinOp::Sub | BinOp::Mul | BinOp::Div | BinOp::Rem => unreachable!("handled above"),
        };
        self.line(&format!("  {} = {} {}, {}", reg, opcode, l, r));
        format!("{} {}", if is_cmp { "i1" } else { &ity }, reg)
    }

    /// `l / r` or `l % r` on two `Wrapping<T>` operands. A zero divisor
    /// still traps (matching Rust's own `Wrapping<T>`, and every other
    /// integer division in this compiler -- division-by-zero isn't
    /// "overflow"), but the signed `MIN / -1` case wraps to `MIN` (`MIN % -1`
    /// wraps to `0`, mathematically exact -- `-1` always divides evenly)
    /// instead of trapping, since that's the one genuine overflow case
    /// wrapping semantics are supposed to make silent. Unsigned division has
    /// no such case at all.
    fn emit_wrapping_sized_int_div(&mut self, l: &str, r: &str, width: u32, signed: bool, op: BinOp) -> String {
        let ity = format!("i{}", width);
        let is_zero = self.tmp_name();
        self.line(&format!("  {} = icmp eq {} {}, 0", is_zero, ity, r));
        let zero_fail = self.block_label("wrap_div_zero_fail");
        let zero_ok = self.block_label("wrap_div_zero_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_zero, zero_fail, zero_ok));

        self.open_block(&zero_fail);
        let opname = if op == BinOp::Div { "/" } else { "%" };
        let msg = format!("star runtime error: integer `{}` by zero\n", opname);
        self.emit_abort_with_message(&msg);

        self.open_block(&zero_ok);
        if !signed {
            let reg = self.tmp_name();
            let opcode = if op == BinOp::Div { "udiv" } else { "urem" };
            self.line(&format!("  {} = {} {} {}, {}", reg, opcode, ity, l, r));
            return format!("{} {}", ity, reg);
        }

        let min_lit = signed_min_literal(width);
        let is_min = self.tmp_name();
        self.line(&format!("  {} = icmp eq {} {}, {}", is_min, ity, l, min_lit));
        let is_neg1 = self.tmp_name();
        self.line(&format!("  {} = icmp eq {} {}, -1", is_neg1, ity, r));
        let is_overflow = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", is_overflow, is_min, is_neg1));

        let overflow_label = self.block_label("wrap_div_overflow");
        let normal_label = self.block_label("wrap_div_normal");
        let join_label = self.block_label("wrap_div_join");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_overflow, overflow_label, normal_label));

        self.open_block(&overflow_label);
        let wrapped = if op == BinOp::Div { min_lit.to_string() } else { "0".to_string() };
        self.line(&format!("  br label %{}", join_label));

        self.open_block(&normal_label);
        let normal_reg = self.tmp_name();
        let opcode = if op == BinOp::Div { "sdiv" } else { "srem" };
        self.line(&format!("  {} = {} {} {}, {}", normal_reg, opcode, ity, l, r));
        self.line(&format!("  br label %{}", join_label));

        self.open_block(&join_label);
        let reg = self.tmp_name();
        self.line(&format!(
            "  {} = phi {} [ {}, %{} ], [ {}, %{} ]",
            reg, ity, wrapped, overflow_label, normal_reg, normal_label
        ));
        format!("{} {}", ity, reg)
    }
}
