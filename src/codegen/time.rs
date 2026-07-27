//! `Tick`/`Duration`/`Instant` codegen -- see `Ty::Tick`'s doc comment.
//!
//! All three lower to a bare `i64`, so construction (`Tick(value)`/
//! `Duration(value)`/`Instant(value)`) is just an int-shaped widen/narrow to
//! `i64` (mirroring `Ty::Fixed`'s int-shaped construction path, minus the
//! `shl`-by-`Frac` rescale a fixed-point type needs), and their shared
//! arithmetic/comparison operator set (`Checker::infer_time_binop_ty`
//! guarantees only `+`/`-`/comparisons ever reach here, never `*`/`/`/`%`)
//! is exactly the same checked-`i64`-add/sub-plus-signed-comparison codegen
//! regardless of which of the three (or plain `i64`) the operator's *result*
//! is typed as at the checker level -- that distinction only matters for
//! type-checking, not for the bytes actually emitted.

use crate::ast::BinOp;
use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

impl Codegen {
    /// `Tick(value)`/`Duration(value)`/`Instant(value)` -- widen/narrow an
    /// int-shaped `value` to the underlying `i64`, sign/zero-extending per
    /// the source's own signedness (mirrors `Codegen::emit_cast`'s int/int
    /// widening rule). `Checker::check_builtin_ctor_arity` has already
    /// validated `value`'s type is int-shaped.
    pub(super) fn emit_time_new(&mut self, value: &TypedExpr) -> String {
        let value_ty = self.expr_ty(value);
        let val = self.emit_expr(value);
        let bare = self.untag(&val, &value_ty);
        let (width, signed) = value_ty
            .int_shape()
            .expect("Checker::check_builtin_ctor_arity guarantees an int-shaped constructor argument");
        if width == 64 {
            return format!("i64 {}", bare);
        }
        let reg = self.tmp_name();
        let op = if signed { "sext" } else { "zext" };
        self.line(&format!("  {} = {} i{} {} to i64", reg, op, width, bare));
        format!("i64 {}", reg)
    }

    /// Binary op between two bare (untagged) `i64` registers/literals coming
    /// from a `Tick`/`Duration`/`Instant` operand pair. `+`/`-` trap on
    /// overflow (reusing `Codegen::emit_checked_sized_int_arith`, same as
    /// `Ty::I64` itself); the six comparison operators are a plain signed
    /// `icmp`. `Checker::infer_time_binop_ty` guarantees no other operator
    /// ever reaches this.
    pub(super) fn emit_time_binop(&mut self, l: &str, r: &str, op: BinOp) -> String {
        if matches!(op, BinOp::Add | BinOp::Sub) {
            return self.emit_checked_sized_int_arith(l, r, 64, true, op);
        }
        let reg = self.tmp_name();
        let opcode = match op {
            BinOp::Eq => "icmp eq i64",
            BinOp::Ne => "icmp ne i64",
            BinOp::Lt => "icmp slt i64",
            BinOp::Gt => "icmp sgt i64",
            BinOp::Le => "icmp sle i64",
            BinOp::Ge => "icmp sge i64",
            BinOp::Mul | BinOp::Div | BinOp::Rem => {
                self.err("internal error: `*`/`/`/`%` are not supported on Tick/Duration/Instant", Span::dummy());
                "add i64"
            }
            BinOp::Add | BinOp::Sub => unreachable!("handled above"),
            BinOp::And | BinOp::Or => unreachable!("`&&`/`||` never reach a type-specific binop dispatch"),
            BinOp::BitAnd | BinOp::BitOr | BinOp::BitXor | BinOp::Shl | BinOp::Shr => {
                unreachable!("Checker::infer_binop_ty restricts these to Ty::bit_shape() types, which Tick/Duration/Instant are not")
            }
        };
        self.line(&format!("  {} = {} {}, {}", reg, opcode, l, r));
        format!("i1 {}", reg)
    }
}
