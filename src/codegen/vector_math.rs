//! Scalar, vector (Vec2/Vec3/Vec4), and matrix (Mat4) arithmetic lowering.

use crate::ast::*;
use crate::diagnostics::Span;
use crate::types::*;

use super::{format_f32_literal, Codegen};

/// The minimum value of a signed `iN` integer, as an LLVM decimal literal --
/// `emit_checked_sized_int_div`'s generalization of `emit_checked_int_div`'s
/// hardcoded `-2147483648` (`i32::MIN`) to every signed width this compiler
/// now has.
pub(super) fn signed_min_literal(width: u32) -> &'static str {
    match width {
        8 => "-128",
        16 => "-32768",
        32 => "-2147483648",
        64 => "-9223372036854775808",
        _ => unreachable!("only 8/16/32/64-bit integer widths exist"),
    }
}

impl Codegen {
    /// Plain scalar (Int/Float, possibly mixed, or any single sized-integer/
    /// `F64` type) binary op — this is where the pre-existing i32-only bug
    /// was fixed: Float operands get `f`-opcodes, and mixed Int/Float
    /// operands are promoted to Float first. Every explicit-width integer
    /// type (`i8`/`u8`/`i16`/`u16`/`u32`/`i64`/`u64`) and `f64` added since
    /// then routes to its own generalized path below -- see
    /// `emit_sized_int_binop`/`emit_f64_binop`; `Checker::infer_binop_ty`
    /// already guarantees `lty == rty` for any pair that isn't the original
    /// `(Int, Float)` mix, so those are the only shapes this ever sees.
    fn emit_scalar_binop(&mut self, lhs: &str, lty: &Ty, rhs: &str, rty: &Ty, op: BinOp) -> String {
        let is_cmp = matches!(op, BinOp::Eq | BinOp::Ne | BinOp::Lt | BinOp::Gt | BinOp::Le | BinOp::Ge);
        if matches!(lty, Ty::Int) && matches!(rty, Ty::Int) {
            let l = self.untag(lhs, lty);
            let r = self.untag(rhs, rty);
            // `sdiv`/`srem` on `i32` are the one pair of opcodes here that
            // can trap the whole process (a hardware `#DE` exception, surfaced
            // as SIGFPE) instead of just producing a value: both a zero
            // divisor and the single overflow case `i32::MIN / -1` (its
            // mathematical result, `2147483648`, doesn't fit in `i32`) are
            // undefined behavior in LLVM and crash outright at runtime with
            // no diagnostic. Guarded the same way `emit_frame_alloc` guards
            // its bump allocator: check first, abort with a message instead
            // of letting the trap happen.
            if matches!(op, BinOp::Div | BinOp::Rem) {
                return self.emit_checked_int_div(&l, &r, op);
            }
            let reg = self.tmp_name();
            let opcode = match op {
                BinOp::Add => "add i32", BinOp::Sub => "sub i32", BinOp::Mul => "mul i32",
                BinOp::Eq => "icmp eq i32", BinOp::Ne => "icmp ne i32",
                BinOp::Lt => "icmp slt i32", BinOp::Gt => "icmp sgt i32",
                BinOp::Le => "icmp sle i32", BinOp::Ge => "icmp sge i32",
                // `&&`/`||` are intercepted in `Codegen::emit_expr`'s
                // `TypedExpr::Binary` arm (they need short-circuit,
                // branch-based lowering, not a plain opcode) and never
                // reach this generic scalar path.
                BinOp::And | BinOp::Or => { self.err("internal error: `&&`/`||` should be short-circuit lowered, not reach emit_scalar_binop", Span::dummy()); "add i32" }
                BinOp::BitAnd | BinOp::BitOr | BinOp::BitXor | BinOp::Shl | BinOp::Shr => {
                    self.err("internal error: `&`/`|`/`^`/`<<`/`>>` should be dispatched by emit_binop before emit_scalar_binop", Span::dummy());
                    "add i32"
                }
                BinOp::Div | BinOp::Rem => unreachable!("handled above"),
            };
            self.line(&format!("  {} = {} {}, {}", reg, opcode, l, r));
            return format!("{} {}", if is_cmp { "i1" } else { "i32" }, reg);
        }
        if lty == rty {
            if lty.int_shape().is_some() {
                return self.emit_sized_int_binop(lhs, lty, rhs, rty, op);
            }
            if matches!(lty, Ty::F64) {
                return self.emit_f64_binop(lhs, rhs, op);
            }
        }
        let l = self.promote_to_float(lhs, lty);
        let r = self.promote_to_float(rhs, rty);
        let reg = self.tmp_name();
        let opcode = match op {
            BinOp::Add => "fadd float", BinOp::Sub => "fsub float", BinOp::Mul => "fmul float",
            BinOp::Div => "fdiv float", BinOp::Rem => "frem float",
            BinOp::Eq => "fcmp oeq float", BinOp::Ne => "fcmp one float",
            BinOp::Lt => "fcmp olt float", BinOp::Gt => "fcmp ogt float",
            BinOp::Le => "fcmp ole float", BinOp::Ge => "fcmp oge float",
            BinOp::And | BinOp::Or => { self.err("internal error: `&&`/`||` should be short-circuit lowered, not reach emit_scalar_binop", Span::dummy()); "fadd float" }
            BinOp::BitAnd | BinOp::BitOr | BinOp::BitXor | BinOp::Shl | BinOp::Shr => {
                self.err("internal error: `&`/`|`/`^`/`<<`/`>>` are int-only and never reach the float scalar path", Span::dummy());
                "fadd float"
            }
        };
        self.line(&format!("  {} = {} {}, {}", reg, opcode, l, r));
        format!("{} {}", if is_cmp { "i1" } else { "float" }, reg)
    }

    /// Binary op between two same-width, same-signedness sized integers
    /// (`i8`/`u8`/`i16`/`u16`/`u32`/`i64`/`u64` -- every explicit width added
    /// since the original `i32`-only `Ty::Int`, see `Ty::int_shape`).
    /// `+`/`-`/`*` trap on overflow (`emit_checked_sized_int_arith`, via
    /// LLVM's `llvm.{s,u}{add,sub,mul}.with.overflow.iN` intrinsics) and `/`/
    /// `%` trap on a zero divisor (and, for a signed width, the lone
    /// `MIN / -1` overflow case) -- `docs/design.md`'s "Numeric widths and
    /// modes" keeps trap-on-overflow as the default rather than `Ty::Int`'s
    /// original silent two's-complement wraparound.
    fn emit_sized_int_binop(&mut self, lhs: &str, lty: &Ty, rhs: &str, rty: &Ty, op: BinOp) -> String {
        let (width, signed) = lty.int_shape().expect("caller guarantees lty is a sized integer type");
        let is_cmp = matches!(op, BinOp::Eq | BinOp::Ne | BinOp::Lt | BinOp::Gt | BinOp::Le | BinOp::Ge);
        let l = self.untag(lhs, lty);
        let r = self.untag(rhs, rty);
        let ity = format!("i{}", width);
        if matches!(op, BinOp::Div | BinOp::Rem) {
            return self.emit_checked_sized_int_div(&l, &r, width, signed, op);
        }
        if matches!(op, BinOp::Add | BinOp::Sub | BinOp::Mul) {
            return self.emit_checked_sized_int_arith(&l, &r, width, signed, op);
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
                self.err("internal error: `&&`/`||` should be short-circuit lowered, not reach emit_sized_int_binop", Span::dummy());
                format!("add {}", ity)
            }
            BinOp::BitAnd | BinOp::BitOr | BinOp::BitXor | BinOp::Shl | BinOp::Shr => {
                self.err("internal error: `&`/`|`/`^`/`<<`/`>>` should be dispatched by emit_binop before emit_sized_int_binop", Span::dummy());
                format!("add {}", ity)
            }
            BinOp::Add | BinOp::Sub | BinOp::Mul | BinOp::Div | BinOp::Rem => unreachable!("handled above"),
        };
        self.line(&format!("  {} = {} {}, {}", reg, opcode, l, r));
        format!("{} {}", if is_cmp { "i1" } else { &ity }, reg)
    }

    /// `+`/`-`/`*` on bare (untagged) `iN` registers/literals, trapping on
    /// overflow via LLVM's `llvm.{s,u}{add,sub,mul}.with.overflow.iN`
    /// intrinsics (declared unconditionally for every width/signedness/op
    /// combination this needs, see `Codegen::emit_builtins`) rather than
    /// `Ty::Int`'s original silent wraparound -- see `Ty::I8`'s doc comment
    /// for why this is the default for every explicit-width type. Mirrors
    /// `emit_checked_int_div`'s check-then-abort-with-a-message shape.
    pub(super) fn emit_checked_sized_int_arith(&mut self, l: &str, r: &str, width: u32, signed: bool, op: BinOp) -> String {
        let ity = format!("i{}", width);
        let kind = match op {
            BinOp::Add => "add",
            BinOp::Sub => "sub",
            BinOp::Mul => "mul",
            _ => unreachable!("caller only routes Add/Sub/Mul here"),
        };
        let sign_prefix = if signed { "s" } else { "u" };
        let intrinsic = format!("llvm.{}{}.with.overflow.{}", sign_prefix, kind, ity);
        let pair_ty = format!("{{ {}, i1 }}", ity);
        let pair = self.tmp_name();
        self.line(&format!("  {} = call {} @{}({} {}, {} {})", pair, pair_ty, intrinsic, ity, l, ity, r));
        let value = self.tmp_name();
        self.line(&format!("  {} = extractvalue {} {}, 0", value, pair_ty, pair));
        let overflow = self.tmp_name();
        self.line(&format!("  {} = extractvalue {} {}, 1", overflow, pair_ty, pair));

        let fail_label = self.block_label("int_overflow_fail");
        let ok_label = self.block_label("int_overflow_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", overflow, fail_label, ok_label));

        self.open_block(&fail_label);
        let opname = match op { BinOp::Add => "+", BinOp::Sub => "-", BinOp::Mul => "*", _ => unreachable!() };
        let signedness = if signed { "signed" } else { "unsigned" };
        let msg = format!("star runtime error: {} {}-bit integer overflow in `{}` operation\n", signedness, width, opname);
        self.emit_abort_with_message(&msg);

        self.open_block(&ok_label);
        format!("{} {}", ity, value)
    }

    /// `l / r` or `l % r` on bare (untagged) `iN` registers/literals for any
    /// sized integer width/signedness -- generalizes `emit_checked_int_div`'s
    /// `i32`-only guard (a zero divisor always traps; the signed `MIN / -1`
    /// overflow case only applies to a signed width, unsigned division has no
    /// equivalent trap).
    fn emit_checked_sized_int_div(&mut self, l: &str, r: &str, width: u32, signed: bool, op: BinOp) -> String {
        let ity = format!("i{}", width);
        let is_zero = self.tmp_name();
        self.line(&format!("  {} = icmp eq {} {}, 0", is_zero, ity, r));
        let is_bad = if signed {
            let min_lit = signed_min_literal(width);
            let is_min = self.tmp_name();
            self.line(&format!("  {} = icmp eq {} {}, {}", is_min, ity, l, min_lit));
            let is_neg1 = self.tmp_name();
            self.line(&format!("  {} = icmp eq {} {}, -1", is_neg1, ity, r));
            let is_overflow = self.tmp_name();
            self.line(&format!("  {} = and i1 {}, {}", is_overflow, is_min, is_neg1));
            let bad = self.tmp_name();
            self.line(&format!("  {} = or i1 {}, {}", bad, is_zero, is_overflow));
            bad
        } else {
            is_zero
        };

        let fail_label = self.block_label("int_div_fail");
        let ok_label = self.block_label("int_div_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_bad, fail_label, ok_label));

        self.open_block(&fail_label);
        let opname = if op == BinOp::Div { "/" } else { "%" };
        let overflow_note = if signed { format!(" (or i{}::MIN {} -1 overflow)", width, opname) } else { String::new() };
        let msg = format!("star runtime error: integer `{}` by zero{}\n", opname, overflow_note);
        self.emit_abort_with_message(&msg);

        self.open_block(&ok_label);
        let reg = self.tmp_name();
        let opcode = match (op, signed) {
            (BinOp::Div, true) => "sdiv", (BinOp::Div, false) => "udiv",
            (BinOp::Rem, true) => "srem", (BinOp::Rem, false) => "urem",
            _ => unreachable!("caller only routes Div/Rem here"),
        };
        self.line(&format!("  {} = {} {} {}, {}", reg, opcode, ity, l, r));
        format!("{} {}", ity, reg)
    }

    /// `f64`/`f64` binary op -- same opcode shape as the `float`/`float` path
    /// above, just at `double` width. Never traps: float arithmetic
    /// saturates to +/-inf per IEEE-754, matching `Ty::Float`'s existing
    /// behavior (only the sized *integer* types added alongside `f64` trap
    /// on overflow).
    fn emit_f64_binop(&mut self, lhs: &str, rhs: &str, op: BinOp) -> String {
        let is_cmp = matches!(op, BinOp::Eq | BinOp::Ne | BinOp::Lt | BinOp::Gt | BinOp::Le | BinOp::Ge);
        let l = self.untag(lhs, &Ty::F64);
        let r = self.untag(rhs, &Ty::F64);
        let reg = self.tmp_name();
        let opcode = match op {
            BinOp::Add => "fadd double", BinOp::Sub => "fsub double", BinOp::Mul => "fmul double",
            BinOp::Div => "fdiv double", BinOp::Rem => "frem double",
            BinOp::Eq => "fcmp oeq double", BinOp::Ne => "fcmp one double",
            BinOp::Lt => "fcmp olt double", BinOp::Gt => "fcmp ogt double",
            BinOp::Le => "fcmp ole double", BinOp::Ge => "fcmp oge double",
            BinOp::And | BinOp::Or => { self.err("internal error: `&&`/`||` should be short-circuit lowered, not reach emit_f64_binop", Span::dummy()); "fadd double" }
            BinOp::BitAnd | BinOp::BitOr | BinOp::BitXor | BinOp::Shl | BinOp::Shr => {
                self.err("internal error: `&`/`|`/`^`/`<<`/`>>` are int-only and never reach the f64 scalar path", Span::dummy());
                "fadd double"
            }
        };
        self.line(&format!("  {} = {} {}, {}", reg, opcode, l, r));
        format!("{} {}", if is_cmp { "i1" } else { "double" }, reg)
    }

    /// `==`/`!=`/`<`/`>`/`<=`/`>=` between two `char` values -- codepoints
    /// compare as plain unsigned 32-bit integers (see `Ty::Char`'s doc
    /// comment); no arithmetic (`+`/`-`/`*`/`/`/`%`) is supported (mirrors
    /// Rust's `char`, which isn't `Add`/`Sub`/etc.) -- `Checker::infer_binop_ty`
    /// already rejects any non-comparison `char` operator before this is
    /// ever reached, so the `_` arm here is unreachable in a checked program.
    fn emit_char_binop(&mut self, lhs: &str, rhs: &str, op: BinOp) -> String {
        let l = self.untag(lhs, &Ty::Char);
        let r = self.untag(rhs, &Ty::Char);
        let reg = self.tmp_name();
        let opcode = match op {
            BinOp::Eq => "icmp eq i32", BinOp::Ne => "icmp ne i32",
            BinOp::Lt => "icmp ult i32", BinOp::Gt => "icmp ugt i32",
            BinOp::Le => "icmp ule i32", BinOp::Ge => "icmp uge i32",
            _ => { self.err("only comparisons are supported on `char` values", Span::dummy()); "icmp eq i32" }
        };
        self.line(&format!("  {} = {} {}, {}", reg, opcode, l, r));
        format!("i1 {}", reg)
    }

    /// Emit a global message string, `puts` it, then `exit(1)`+`unreachable`
    /// -- the shared "check first, abort with a message" tail every runtime
    /// guard in this module (`emit_checked_sized_int_div`,
    /// `emit_checked_sized_int_arith`) ends with once its bad-input branch is
    /// taken. `msg` must already end in `\n` (matching every call site's
    /// existing convention).
    pub(super) fn emit_abort_with_message(&mut self, msg: &str) {
        let g = self.global_name();
        let escaped = msg.replace("\\", "\\\\").replace("\"", "\\22").replace("\n", "\\0A");
        self.global_defs.push(format!("{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"", g, msg.len() + 1, escaped));
        let msg_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", msg_ptr, msg.len() + 1, msg.len() + 1, g));
        self.line(&format!("  call i32 @puts(i8* {})", msg_ptr));
        self.line("  call void @exit(i32 1)");
        self.line("  unreachable");
    }

    /// `expr as ty` -- see `Expr::Cast`'s doc comment. Dispatches on whether
    /// each side is integer-shaped (`Ty::int_shape`, treating `Ty::Char` as
    /// an unsigned 32-bit int -- see its own doc comment) or float-shaped
    /// (`Ty::Float`/`Ty::F64`); `Checker::infer_expr`'s `Expr::Cast` arm has
    /// already restricted `target`/the source type to a legal numeric/`char`
    /// pairing, so every reachable combination is one of the four arms below.
    pub(super) fn emit_cast(&mut self, expr: &TypedExpr, target: &Ty) -> String {
        let src_ty = self.expr_ty(expr);
        let val = self.emit_expr(expr);
        let bare = self.untag(&val, &src_ty);
        let target_llty = self.llvm_ty(target);

        // `Wrapping<T> <-> T`: a free bit-preserving relabel -- both sides
        // are already the exact same LLVM integer type (see `Ty::Wrapping`'s
        // doc comment), so no instruction is emitted at all, mirroring the
        // same-width int/int case below.
        if matches!(&src_ty, Ty::Wrapping(w) if **w == *target) || matches!(target, Ty::Wrapping(w) if **w == src_ty) {
            return format!("{} {}", target_llty, bare);
        }
        // `Tick`/`Duration`/`Instant` <-> `i64`: same free bit-preserving
        // relabel as `Wrapping<T> <-> T` just above -- see `Ty::Tick`'s doc
        // comment.
        if matches!((&src_ty, target), (Ty::Tick | Ty::Duration | Ty::Instant, Ty::I64) | (Ty::I64, Ty::Tick | Ty::Duration | Ty::Instant)) {
            return format!("{} {}", target_llty, bare);
        }
        // `Symbol <-> i64`: same free bit-preserving relabel as
        // `Tick`/`Duration`/`Instant <-> i64` just above -- see
        // `Ty::Symbol`'s doc comment.
        if matches!((&src_ty, target), (Ty::Symbol, Ty::I64) | (Ty::I64, Ty::Symbol)) {
            return format!("{} {}", target_llty, bare);
        }
        // `BitField<N> <-> i{N}`/`u{N}`: same free bit-preserving relabel as
        // `Wrapping<T> <-> T` above -- see `Ty::BitField`'s doc comment.
        if matches!((&src_ty, target), (Ty::BitField(_), _) | (_, Ty::BitField(_))) {
            return format!("{} {}", target_llty, bare);
        }
        // `Flags<E> <-> i64`: same free bit-preserving relabel as `Symbol <->
        // i64` above -- see `Ty::Flags`'s doc comment.
        if matches!((&src_ty, target), (Ty::Flags(_), Ty::I64) | (Ty::I64, Ty::Flags(_))) {
            return format!("{} {}", target_llty, bare);
        }
        // `Color32 <-> i32`/`u32`: same free bit-preserving relabel -- see
        // `Ty::Color32`'s doc comment. Both `i32`/`u32` share the same bare
        // `i32` LLVM representation (see `llvm_ty`), so a single arm covers
        // either target/source signedness.
        if matches!((&src_ty, target), (Ty::Color32, Ty::Int | Ty::U32) | (Ty::Int | Ty::U32, Ty::Color32)) {
            return format!("{} {}", target_llty, bare);
        }
        // `PaletteIndex <-> u8`: same free bit-preserving relabel -- see
        // `Ty::PaletteIndex`'s doc comment.
        if matches!((&src_ty, target), (Ty::PaletteIndex, Ty::U8) | (Ty::U8, Ty::PaletteIndex)) {
            return format!("{} {}", target_llty, bare);
        }
        // `Fixed<Bits,Frac> <-> float/f64`: a true scaled conversion, not a
        // bit reinterpret -- see `Ty::Fixed`'s doc comment.
        if let Ty::Fixed(bits, frac) = &src_ty {
            if matches!(target, Ty::Float | Ty::F64) {
                return self.emit_fixed_to_float(&bare, *bits, *frac, matches!(target, Ty::F64));
            }
        }
        if let Ty::Fixed(bits, frac) = target {
            if matches!(src_ty, Ty::Float | Ty::F64) {
                return self.emit_float_to_fixed(&bare, matches!(src_ty, Ty::F64), *bits, *frac);
            }
        }

        let src_shape = if src_ty == Ty::Char { Some((32u32, false)) } else { src_ty.int_shape() };
        let tgt_shape = if *target == Ty::Char { Some((32u32, false)) } else { target.int_shape() };
        let src_is_float = matches!(src_ty, Ty::Float | Ty::F64);
        let tgt_is_float = matches!(target, Ty::Float | Ty::F64);

        match (src_shape, tgt_shape, src_is_float, tgt_is_float) {
            // int/char -> int/char: same width is a bit-preserving relabel
            // (e.g. `i32 as u32`, or `char`<->its underlying `i32`); a wider
            // target sign/zero-extends per the *source*'s own signedness; a
            // narrower target truncates.
            (Some((sw, ssigned)), Some((tw, _)), _, _) => {
                if sw == tw {
                    format!("{} {}", target_llty, bare)
                } else if tw > sw {
                    let reg = self.tmp_name();
                    let op = if ssigned { "sext" } else { "zext" };
                    self.line(&format!("  {} = {} i{} {} to i{}", reg, op, sw, bare, tw));
                    format!("{} {}", target_llty, reg)
                } else {
                    let reg = self.tmp_name();
                    self.line(&format!("  {} = trunc i{} {} to i{}", reg, sw, bare, tw));
                    format!("{} {}", target_llty, reg)
                }
            }
            // int/char -> float: `sitofp`/`uitofp` per the source's signedness.
            (Some((sw, ssigned)), None, _, true) => {
                let reg = self.tmp_name();
                let op = if ssigned { "sitofp" } else { "uitofp" };
                self.line(&format!("  {} = {} i{} {} to {}", reg, op, sw, bare, target_llty));
                format!("{} {}", target_llty, reg)
            }
            // float -> int/char: the saturating `llvm.fptosi.sat`/
            // `llvm.fptoui.sat` intrinsics (declared unconditionally in
            // `Codegen::emit_builtins`) per the *target*'s signedness,
            // rather than the plain `fptosi`/`fptoui` instructions --
            // those are undefined behavior (poison) whenever the source
            // value doesn't fit the destination width or is NaN, silently
            // producing a nonsense result instead of the well-defined,
            // Rust-`as`-matching clamp `Checker::infer_expr`'s `Expr::Cast`
            // doc comment already promises.
            (None, Some((tw, tsigned)), true, _) => {
                let src_llty = self.llvm_ty(&src_ty);
                let fty_suffix = if matches!(src_ty, Ty::F64) { "f64" } else { "f32" };
                let reg = self.tmp_name();
                let op = if tsigned { "fptosi" } else { "fptoui" };
                self.line(&format!(
                    "  {} = call i{} @llvm.{}.sat.i{}.{}({} {})",
                    reg, tw, op, tw, fty_suffix, src_llty, bare
                ));
                format!("{} {}", target_llty, reg)
            }
            // float -> float: `fpext` (f32 -> f64) or `fptrunc` (f64 -> f32);
            // same type is a no-op passthrough.
            (None, None, true, true) => {
                if src_ty == *target {
                    format!("{} {}", target_llty, bare)
                } else {
                    let src_llty = self.llvm_ty(&src_ty);
                    let reg = self.tmp_name();
                    let op = if matches!(target, Ty::F64) { "fpext" } else { "fptrunc" };
                    self.line(&format!("  {} = {} {} {} to {}", reg, op, src_llty, bare, target_llty));
                    format!("{} {}", target_llty, reg)
                }
            }
            _ => {
                self.err("internal error: unsupported cast combination reached codegen", Span::dummy());
                format!("{} {}", target_llty, bare)
            }
        }
    }

    /// `l / r` or `l % r` on bare (untagged) `i32` registers/literals, with
    /// a runtime guard against the two inputs that make `sdiv`/`srem i32`
    /// undefined behavior -- a zero divisor, and the lone overflowing case
    /// `i32::MIN / -1` (its true result, `2147483648`, doesn't fit in
    /// `i32`) -- both of which trap the process outright (SIGFPE) with no
    /// diagnostic if left unchecked. Mirrors `emit_frame_alloc`'s
    /// check-then-abort-with-a-message shape.
    fn emit_checked_int_div(&mut self, l: &str, r: &str, op: BinOp) -> String {
        let is_zero = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 0", is_zero, r));
        let is_min = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, -2147483648", is_min, l));
        let is_neg1 = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, -1", is_neg1, r));
        let is_overflow = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", is_overflow, is_min, is_neg1));
        let is_bad = self.tmp_name();
        self.line(&format!("  {} = or i1 {}, {}", is_bad, is_zero, is_overflow));

        let fail_label = self.block_label("int_div_fail");
        let ok_label = self.block_label("int_div_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_bad, fail_label, ok_label));

        self.open_block(&fail_label);
        let opname = if op == BinOp::Div { "/" } else { "%" };
        let msg = format!(
            "star runtime error: integer `{}` by zero (or `i32::MIN {} -1` overflow)\n",
            opname, opname
        );
        let g = self.global_name();
        let escaped = msg.replace("\\", "\\\\").replace("\"", "\\22").replace("\n", "\\0A");
        self.global_defs.push(format!("{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"", g, msg.len() + 1, escaped));
        let msg_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", msg_ptr, msg.len() + 1, msg.len() + 1, g));
        self.line(&format!("  call i32 @puts(i8* {})", msg_ptr));
        self.line("  call void @exit(i32 1)");
        self.line("  unreachable");

        self.open_block(&ok_label);
        let reg = self.tmp_name();
        let opcode = if op == BinOp::Div { "sdiv i32" } else { "srem i32" };
        self.line(&format!("  {} = {} {}, {}", reg, opcode, l, r));
        format!("i32 {}", reg)
    }

    /// Native-vector op between two same-arity Vec2/Vec3/Vec4 values.
    fn emit_vec_binop(&mut self, lhs: &str, rhs: &str, ty: &Ty, op: BinOp) -> String {
        let l = self.untag(lhs, ty);
        let r = self.untag(rhs, ty);
        let t = self.llvm_ty(ty);
        let reg = self.tmp_name();
        let opcode = match op {
            BinOp::Add => format!("fadd {}", t),
            BinOp::Sub => format!("fsub {}", t),
            BinOp::Mul => format!("fmul {}", t),
            BinOp::Div => format!("fdiv {}", t),
            _ => { self.err("unsupported vector operator", Span::dummy()); format!("fadd {}", t) }
        };
        self.line(&format!("  {} = {} {}, {}", reg, opcode, l, r));
        format!("{} {}", t, reg)
    }

    /// Vector (Vec2/Vec3/Vec4) `*`/`/` scalar (either operand order).
    fn emit_vec_scalar_binop(&mut self, vec_val: &str, vec_ty: &Ty, scalar_val: &str, scalar_ty: &Ty, op: BinOp, scalar_on_left: bool) -> String {
        let scalar = self.promote_to_float(scalar_val, scalar_ty);
        let vec_bare = self.untag(vec_val, vec_ty);
        let arity = vec_ty.vec_arity().unwrap();
        let mut b = "undef".to_string();
        for i in 0..arity as u32 {
            b = self.insert_component(&b, vec_ty, i, &scalar);
        }
        let t = self.llvm_ty(vec_ty);
        let reg = self.tmp_name();
        let opcode = match op { BinOp::Mul => format!("fmul {}", t), BinOp::Div => format!("fdiv {}", t), _ => unreachable!() };
        let (a, c) = if scalar_on_left { (b.clone(), vec_bare.clone()) } else { (vec_bare.clone(), b.clone()) };
        self.line(&format!("  {} = {} {}, {}", reg, opcode, a, c));
        format!("{} {}", t, reg)
    }

    /// Elementwise `+`/`-` between two same-dimension matrix values
    /// (row-by-row vector op) -- generalizes what used to be a `Mat4`-only
    /// `emit_mat4_addsub` to any of `Mat2`/`Mat3`/`Mat4` (`dim` is 2/3/4,
    /// from `Ty::mat_dim`), since `Mat2`/`Mat3` are the exact same
    /// `[N x <N x float>]` row-of-native-vectors layout at a smaller fixed
    /// size.
    fn emit_mat_addsub(&mut self, lhs: &str, rhs: &str, dim: u32, op: BinOp) -> String {
        let row_ty = Ty::vec_of_arity(dim as u8).expect("mat_dim is always 2, 3, or 4");
        let row_llty = self.llvm_ty(&row_ty);
        let mat_t = format!("[{} x {}]", dim, row_llty);
        let l = lhs.strip_prefix(&format!("{} ", mat_t)).unwrap_or(lhs).to_string();
        let r = rhs.strip_prefix(&format!("{} ", mat_t)).unwrap_or(rhs).to_string();
        let mut acc = "undef".to_string();
        for i in 0..dim {
            let lr = self.tmp_name();
            self.line(&format!("  {} = extractvalue {} {}, {}", lr, mat_t, l, i));
            let rr = self.tmp_name();
            self.line(&format!("  {} = extractvalue {} {}, {}", rr, mat_t, r, i));
            let reg = self.tmp_name();
            let opcode = match op {
                BinOp::Add => format!("fadd {}", row_llty),
                BinOp::Sub => format!("fsub {}", row_llty),
                _ => unreachable!(),
            };
            self.line(&format!("  {} = {} {}, {}", reg, opcode, lr, rr));
            let next = self.tmp_name();
            self.line(&format!("  {} = insertvalue {} {}, {} {}, {}", next, mat_t, acc, row_llty, reg, i));
            acc = next;
        }
        format!("{} {}", mat_t, acc)
    }

    /// Dot product of two already-untagged same-arity vector registers via
    /// elementwise multiply + horizontal add (straight-line, no loop over
    /// scalar registers -- one native vector `fmul` regardless of arity).
    fn emit_dot_vec(&mut self, a: &str, b: &str, ty: &Ty) -> String {
        let t = self.llvm_ty(ty);
        let arity = ty.vec_arity().unwrap();
        let p = self.tmp_name();
        self.line(&format!("  {} = fmul {} {}, {}", p, t, a, b));
        let mut sum: Option<String> = None;
        for i in 0..arity as u32 {
            let lane = self.tmp_name();
            self.line(&format!("  {} = extractelement {} {}, i32 {}", lane, t, p, i));
            sum = Some(match sum {
                None => lane,
                Some(s) => {
                    let r = self.tmp_name();
                    self.line(&format!("  {} = fadd float {}, {}", r, s, lane));
                    r
                }
            });
        }
        sum.unwrap()
    }

    /// Matrix-vector multiply: `result[i] = dot(row_i, v)`. Generalizes what
    /// used to be a `Mat4`/`Vec4`-only `emit_mat4_vec4_mul` to any dimension
    /// (2/3/4) -- see `emit_mat_addsub`'s doc comment.
    fn emit_mat_vec_mul(&mut self, mat_val: &str, vec_val: &str, dim: u32) -> String {
        let row_ty = Ty::vec_of_arity(dim as u8).expect("mat_dim is always 2, 3, or 4");
        let row_llty = self.llvm_ty(&row_ty);
        let mat_t = format!("[{} x {}]", dim, row_llty);
        let m = mat_val.strip_prefix(&format!("{} ", mat_t)).unwrap_or(mat_val).to_string();
        let v = self.untag(vec_val, &row_ty);
        let mut elems = Vec::with_capacity(dim as usize);
        for i in 0..dim {
            let row = self.tmp_name();
            self.line(&format!("  {} = extractvalue {} {}, {}", row, mat_t, m, i));
            elems.push(self.emit_dot_vec(&row, &v, &row_ty));
        }
        let mut acc = "undef".to_string();
        for (i, e) in elems.iter().enumerate() {
            acc = self.insert_component(&acc, &row_ty, i as u32, e);
        }
        format!("{} {}", row_llty, acc)
    }

    /// Full NxN matrix multiply, row-major (`A`/`B` both stored as `N` row
    /// vectors): gather `B`'s `N` columns once, then compute each output row
    /// as `N` dot products of `A`'s row against each precomputed column.
    /// Generalizes what used to be a `Mat4`-only `emit_mat4_mul` to any
    /// dimension (2/3/4) -- see `emit_mat_addsub`'s doc comment.
    fn emit_mat_mul(&mut self, a_val: &str, b_val: &str, dim: u32) -> String {
        let row_ty = Ty::vec_of_arity(dim as u8).expect("mat_dim is always 2, 3, or 4");
        let row_llty = self.llvm_ty(&row_ty);
        let mat_t = format!("[{} x {}]", dim, row_llty);
        let a = a_val.strip_prefix(&format!("{} ", mat_t)).unwrap_or(a_val).to_string();
        let b = b_val.strip_prefix(&format!("{} ", mat_t)).unwrap_or(b_val).to_string();
        let mut a_rows = Vec::with_capacity(dim as usize);
        let mut b_rows = Vec::with_capacity(dim as usize);
        for i in 0..dim {
            let ar = self.tmp_name();
            self.line(&format!("  {} = extractvalue {} {}, {}", ar, mat_t, a, i));
            a_rows.push(ar);
            let br = self.tmp_name();
            self.line(&format!("  {} = extractvalue {} {}, {}", br, mat_t, b, i));
            b_rows.push(br);
        }
        let mut b_cols = Vec::with_capacity(dim as usize);
        for j in 0..dim {
            let mut col = "undef".to_string();
            for (i, row) in b_rows.iter().enumerate() {
                let lane = self.tmp_name();
                self.line(&format!("  {} = extractelement {} {}, i32 {}", lane, row_llty, row, j));
                col = self.insert_component(&col, &row_ty, i as u32, &lane);
            }
            b_cols.push(col);
        }
        let mut acc_mat = "undef".to_string();
        for (i, a_row) in a_rows.iter().enumerate() {
            let mut row_acc = "undef".to_string();
            for (j, b_col) in b_cols.iter().enumerate() {
                let dot = self.emit_dot_vec(a_row, b_col, &row_ty);
                row_acc = self.insert_component(&row_acc, &row_ty, j as u32, &dot);
            }
            let next_mat = self.tmp_name();
            self.line(&format!("  {} = insertvalue {} {}, {} {}, {}", next_mat, mat_t, acc_mat, row_llty, row_acc, i));
            acc_mat = next_mat;
        }
        format!("{} {}", mat_t, acc_mat)
    }

    /// A single bare-`float` `fmul`/`fadd`/`fsub`, factored out so
    /// `emit_quat_mul`'s Hamilton-product formula below reads as plain
    /// arithmetic instead of repeated `tmp_name`/`line` boilerplate.
    pub(super) fn emit_fmul(&mut self, a: &str, b: &str) -> String {
        let reg = self.tmp_name();
        self.line(&format!("  {} = fmul float {}, {}", reg, a, b));
        reg
    }
    pub(super) fn emit_fadd(&mut self, a: &str, b: &str) -> String {
        let reg = self.tmp_name();
        self.line(&format!("  {} = fadd float {}, {}", reg, a, b));
        reg
    }
    pub(super) fn emit_fsub(&mut self, a: &str, b: &str) -> String {
        let reg = self.tmp_name();
        self.line(&format!("  {} = fsub float {}, {}", reg, a, b));
        reg
    }
    /// Negate a bare `float` register (`0.0 - x`) -- reused by
    /// `crate::codegen::geometry`'s `quat_conjugate`.
    pub(super) fn emit_fneg(&mut self, a: &str) -> String {
        let reg = self.tmp_name();
        self.line(&format!("  {} = fsub float {}, {}", reg, format_f32_literal(0.0), a));
        reg
    }
    /// A single bare-`float` `fdiv` -- reused by `crate::codegen::geometry`'s
    /// `quat_normalize`.
    pub(super) fn emit_fdiv(&mut self, a: &str, b: &str) -> String {
        let reg = self.tmp_name();
        self.line(&format!("  {} = fdiv float {}, {}", reg, a, b));
        reg
    }

    /// The true quaternion (Hamilton) product `a * b` -- see `Ty::Quat`'s
    /// doc comment for why this is special-cased ahead of the generic
    /// vector dispatch rather than falling out of `is_vec()` like `Quat`'s
    /// other operators do. Standard Hamilton product formula, with each
    /// side's lanes read via `extract_component`/built via
    /// `insert_component` exactly like every other vector op in this module.
    pub(super) fn emit_quat_mul(&mut self, lhs: &str, rhs: &str) -> String {
        let l = self.untag(lhs, &Ty::Quat);
        let r = self.untag(rhs, &Ty::Quat);
        let (ax, ay, az, aw) = (
            self.extract_component(&l, &Ty::Quat, 0),
            self.extract_component(&l, &Ty::Quat, 1),
            self.extract_component(&l, &Ty::Quat, 2),
            self.extract_component(&l, &Ty::Quat, 3),
        );
        let (bx, by, bz, bw) = (
            self.extract_component(&r, &Ty::Quat, 0),
            self.extract_component(&r, &Ty::Quat, 1),
            self.extract_component(&r, &Ty::Quat, 2),
            self.extract_component(&r, &Ty::Quat, 3),
        );
        // w = aw*bw - ax*bx - ay*by - az*bz
        let w1 = self.emit_fmul(&aw, &bw);
        let w2 = self.emit_fmul(&ax, &bx);
        let w3 = self.emit_fmul(&ay, &by);
        let w4 = self.emit_fmul(&az, &bz);
        let w12 = self.emit_fsub(&w1, &w2);
        let w123 = self.emit_fsub(&w12, &w3);
        let w = self.emit_fsub(&w123, &w4);
        // x = aw*bx + ax*bw + ay*bz - az*by
        let x1 = self.emit_fmul(&aw, &bx);
        let x2 = self.emit_fmul(&ax, &bw);
        let x3 = self.emit_fmul(&ay, &bz);
        let x4 = self.emit_fmul(&az, &by);
        let x12 = self.emit_fadd(&x1, &x2);
        let x123 = self.emit_fadd(&x12, &x3);
        let x = self.emit_fsub(&x123, &x4);
        // y = aw*by - ax*bz + ay*bw + az*bx
        let y1 = self.emit_fmul(&aw, &by);
        let y2 = self.emit_fmul(&ax, &bz);
        let y3 = self.emit_fmul(&ay, &bw);
        let y4 = self.emit_fmul(&az, &bx);
        let y12 = self.emit_fsub(&y1, &y2);
        let y123 = self.emit_fadd(&y12, &y3);
        let y = self.emit_fadd(&y123, &y4);
        // z = aw*bz + ax*by - ay*bx + az*bw
        let z1 = self.emit_fmul(&aw, &bz);
        let z2 = self.emit_fmul(&ax, &by);
        let z3 = self.emit_fmul(&ay, &bx);
        let z4 = self.emit_fmul(&az, &bw);
        let z12 = self.emit_fadd(&z1, &z2);
        let z123 = self.emit_fsub(&z12, &z3);
        let z = self.emit_fadd(&z123, &z4);

        let mut acc = "undef".to_string();
        acc = self.insert_component(&acc, &Ty::Quat, 0, &x);
        acc = self.insert_component(&acc, &Ty::Quat, 1, &y);
        acc = self.insert_component(&acc, &Ty::Quat, 2, &z);
        acc = self.insert_component(&acc, &Ty::Quat, 3, &w);
        format!("<4 x float> {}", acc)
    }

    pub(super) fn emit_binop(&mut self, lhs: &str, lty: &Ty, rhs: &str, rty: &Ty, op: BinOp) -> String {
        // `&`/`|`/`^` and `<<`/`>>` are dispatched to their own dedicated
        // lowering up front, the same way `Tick`/`Wrapping`/`Fixed` get their
        // own branch below rather than falling into the generic numeric
        // path: `Checker::infer_binop_ty` already restricted these five
        // operators to `Ty::bit_shape()`/`Ty::bitwise_combine_shape()`
        // operands (any integer width, `Wrapping<T>`, `BitField<N>`, and for
        // `&`/`|`/`^` also `Flags<E>`), a different legality rule than every
        // other operator below, so they never reach `emit_scalar_binop`/
        // `emit_sized_int_binop`/etc. at all (see `crate::codegen::bitfield`).
        if matches!(op, BinOp::BitAnd | BinOp::BitOr | BinOp::BitXor) {
            let opcode = match op {
                BinOp::BitAnd => "and",
                BinOp::BitOr => "or",
                BinOp::BitXor => "xor",
                _ => unreachable!("matched above"),
            };
            return self.emit_bitwise_binop(lhs, lty, rhs, rty, opcode);
        }
        if matches!(op, BinOp::Shl | BinOp::Shr) {
            return self.emit_shift_binop(lhs, lty, rhs, rty, op == BinOp::Shl);
        }
        // `Tick`/`Duration`/`Instant` all lower to a bare `i64` (see
        // `Ty::Tick`'s doc comment) -- `Checker::infer_time_binop_ty` already
        // restricted the reachable (type, op, type) combinations to a
        // checked `i64` add/sub or a signed `i64` comparison, so both
        // operands are untagged and handed to the one shared helper
        // regardless of which of the three (or a bare `i64`, on the other
        // side of a mixed pairing like `Tick - i64`) each side actually is.
        if matches!(lty, Ty::Tick | Ty::Duration | Ty::Instant) || matches!(rty, Ty::Tick | Ty::Duration | Ty::Instant) {
            let l = self.untag(lhs, lty);
            let r = self.untag(rhs, rty);
            return self.emit_time_binop(&l, &r, op);
        }
        // `Wrapping<T>`/`Fixed<Bits,Frac>` get their own dedicated dispatch
        // branch, the same way `char`/`ptr`/vector/matrix types do below --
        // neither is folded into `is_numeric()` (see their own `Ty` doc
        // comments), so they'd otherwise fall through to the "unsupported
        // operand types" error at the bottom of this function.
        // `Checker::infer_binop_ty` already guarantees `lty == rty` for any
        // operator that reaches codegen on either of these two types.
        if let Ty::Wrapping(inner) = lty {
            let (width, signed) = inner.int_shape().expect("Ty::Wrapping's inner type is always int-shaped");
            let l = self.untag(lhs, lty);
            let r = self.untag(rhs, rty);
            return self.emit_wrapping_binop(&l, &r, width, signed, op);
        }
        if let Ty::Fixed(bits, frac) = lty {
            let l = self.untag(lhs, lty);
            let r = self.untag(rhs, rty);
            return self.emit_fixed_binop(&l, &r, *bits, *frac, op);
        }
        if lty.is_numeric() && rty.is_numeric() {
            return self.emit_scalar_binop(lhs, lty, rhs, rty, op);
        }
        // `char == char` / ordering -- see `Ty::Char`'s doc comment;
        // `Checker::infer_binop_ty` already restricts this to the six
        // comparison operators.
        if matches!((lty, rty), (Ty::Char, Ty::Char)) {
            return self.emit_char_binop(lhs, rhs, op);
        }
        // `ptr == ptr` / `ptr != ptr` -- e.g. `is_null`-style handle checks
        // against a value other than the `null_ptr()` builtin.
        if matches!((lty, rty), (Ty::Ptr, Ty::Ptr)) {
            return match op {
                BinOp::Eq | BinOp::Ne => {
                    let l = self.untag(lhs, &Ty::Ptr);
                    let r = self.untag(rhs, &Ty::Ptr);
                    let pred = if op == BinOp::Eq { "eq" } else { "ne" };
                    let reg = self.tmp_name();
                    self.line(&format!("  {} = icmp {} i8* {}, {}", reg, pred, l, r));
                    format!("i1 {}", reg)
                }
                _ => {
                    self.err("only `==`/`!=` are supported on `ptr` values", Span::dummy());
                    "%undef".into()
                }
            };
        }
        // `bool == bool` / `!=` -- a single `i1` comparison. See
        // `Checker::infer_binop_ty`'s own doc comment on this arm for why
        // this was previously unreachable (`bool` isn't `is_numeric()`, so
        // the checker rejected `==`/`!=` on it outright before codegen ever
        // saw a chance to lower it).
        if matches!((lty, rty), (Ty::Bool, Ty::Bool)) {
            return match op {
                BinOp::Eq | BinOp::Ne => {
                    let l = self.untag(lhs, &Ty::Bool);
                    let r = self.untag(rhs, &Ty::Bool);
                    let pred = if op == BinOp::Eq { "eq" } else { "ne" };
                    let reg = self.tmp_name();
                    self.line(&format!("  {} = icmp {} i1 {}, {}", reg, pred, l, r));
                    format!("i1 {}", reg)
                }
                _ => {
                    self.err("only `==`/`!=` are supported between `bool` values", Span::dummy());
                    "%undef".into()
                }
            };
        }
        // `Symbol`/`BitField<N>`/`Flags<E>` == same type / `!=` -- a single
        // opaque-width `icmp`, no `strcmp`/RC involved at all (unlike
        // `str == str` just below) -- see `Ty::eq_only_scalar_shape`'s doc
        // comment for why this is one shared table instead of a hand-copied
        // block per type. `Checker::infer_binop_ty` already restricted every
        // reachable pairing here to an exact same-type match.
        if let Some((width, name)) = lty.eq_only_scalar_shape() {
            return match op {
                BinOp::Eq | BinOp::Ne => {
                    let l = self.untag(lhs, lty);
                    let r = self.untag(rhs, rty);
                    let pred = if op == BinOp::Eq { "eq" } else { "ne" };
                    let reg = self.tmp_name();
                    self.line(&format!("  {} = icmp {} i{} {}, {}", reg, pred, width, l, r));
                    format!("i1 {}", reg)
                }
                _ => {
                    self.err(&format!("only `==`/`!=` are supported between `{}` values", name), Span::dummy());
                    "%undef".into()
                }
            };
        }
        // `str == str` / `str != str` -- structural byte equality via the
        // same `strcmp` comparison `Map<str, V>` key lookup already uses
        // (see `eq.rs`'s `Ty::Str` arm). The comparison only reads the
        // bytes, so release what `emit_expr` left us owning on both sides
        // (a borrowed read's extra retain, or a fresh construction's sole
        // reference -- see `rc.rs`'s module doc comment), mirroring the
        // f-string `%s` hole's own unconditional release.
        if matches!((lty, rty), (Ty::Str, Ty::Str)) {
            return match op {
                BinOp::Eq | BinOp::Ne => {
                    let l = self.untag(lhs, &Ty::Str);
                    let r = self.untag(rhs, &Ty::Str);
                    let cmp = self.tmp_name();
                    self.line(&format!("  {} = call i32 @strcmp(i8* {}, i8* {})", cmp, l, r));
                    self.line(&format!("  call void @star_rc_release(i8* {})", l));
                    self.line(&format!("  call void @star_rc_release(i8* {})", r));
                    let pred = if op == BinOp::Eq { "eq" } else { "ne" };
                    let reg = self.tmp_name();
                    self.line(&format!("  {} = icmp {} i32 {}, 0", reg, pred, cmp));
                    format!("i1 {}", reg)
                }
                _ => {
                    self.err("only `==`/`!=` are supported between `str` values", Span::dummy());
                    "%undef".into()
                }
            };
        }
        // A fieldless `enum`, a `struct` composed entirely of
        // structurally-comparable fields, or a `Tuple`/`Array` of such --
        // structural comparison via the same `eq_fn_name`/`emit_eq_body`
        // machinery `Map`/`Set` key lookup already uses (see
        // `crate::codegen::eq`'s module doc comment). `Checker::infer_binop_ty`
        // already restricted this to a same-type pair that passed
        // `is_structurally_comparable_ty`, so generating `eq_fn_name` here is
        // always safe.
        if matches!(lty, Ty::Enum(_) | Ty::Named(_) | Ty::Tuple(_) | Ty::Array(..)) && lty == rty {
            return match op {
                BinOp::Eq | BinOp::Ne => {
                    let l = self.untag(lhs, lty);
                    let r = self.untag(rhs, rty);
                    let eq_fn = self.eq_fn_name(lty);
                    let llvm = self.llvm_ty(lty);
                    let is_eq = self.tmp_name();
                    self.line(&format!("  {} = call i1 @{}({} {}, {} {})", is_eq, eq_fn, llvm, l, llvm, r));
                    // Transiently compared then discarded, never stored --
                    // release whatever each side's `emit_expr` left it
                    // owning (see `rc.rs`'s module doc comment); a no-op for
                    // a plain fieldless enum or an RC-free struct/tuple/array.
                    self.emit_release_bare(&l, lty);
                    self.emit_release_bare(&r, rty);
                    let reg = if op == BinOp::Eq {
                        is_eq
                    } else {
                        let neg = self.tmp_name();
                        self.line(&format!("  {} = xor i1 {}, true", neg, is_eq));
                        neg
                    };
                    format!("i1 {}", reg)
                }
                _ => {
                    self.err("only `==`/`!=` are supported between enum/struct/tuple/array values", Span::dummy());
                    "%undef".into()
                }
            };
        }
        // `Quat * Quat`: the true quaternion (Hamilton) product -- see
        // `Ty::Quat`'s doc comment. Checked ahead of the generic vector
        // dispatch below (which would otherwise treat it as a componentwise
        // multiply, same as `Vec4 * Vec4`) since `Checker::infer_binop_ty`
        // already guarantees this is the only `(Quat, Mul, Quat)` shape that
        // reaches codegen.
        if matches!((lty, rty, op), (Ty::Quat, Ty::Quat, BinOp::Mul)) {
            return self.emit_quat_mul(lhs, rhs);
        }
        if matches!(op, BinOp::Rem | BinOp::Eq | BinOp::Ne | BinOp::Lt | BinOp::Gt | BinOp::Le | BinOp::Ge) {
            self.err("`%` and comparison operators are not supported on vector/matrix types", Span::dummy());
            return "%undef".into();
        }
        match (lty, rty) {
            // `Quat`/`Color` reuse `Vec4`'s exact layout and (outside the
            // `Quat * Quat` special case just above) its elementwise
            // arithmetic too -- see their own `Ty` doc comments.
            (Ty::Vec2, Ty::Vec2) | (Ty::Vec3, Ty::Vec3) | (Ty::Vec4, Ty::Vec4)
            | (Ty::Quat, Ty::Quat) | (Ty::Color, Ty::Color) => self.emit_vec_binop(lhs, rhs, lty, op),
            (l, r) if l.is_mat() && r.is_mat() => match op {
                BinOp::Add | BinOp::Sub => self.emit_mat_addsub(lhs, rhs, l.mat_dim().unwrap(), op),
                BinOp::Mul => self.emit_mat_mul(lhs, rhs, l.mat_dim().unwrap()),
                _ => { self.err("unsupported matrix operator", Span::dummy()); "%undef".into() }
            },
            (l, r) if l.is_mat() && Some(r) == l.mat_dim().and_then(|d| Ty::vec_of_arity(d as u8)).as_ref() && op == BinOp::Mul => {
                self.emit_mat_vec_mul(lhs, rhs, l.mat_dim().unwrap())
            }
            (l, r) if l.is_vec() && matches!(r, Ty::Int | Ty::Float) && matches!(op, BinOp::Mul | BinOp::Div) => {
                self.emit_vec_scalar_binop(lhs, l, rhs, r, op, false)
            }
            (l, r) if r.is_vec() && matches!(l, Ty::Int | Ty::Float) && matches!(op, BinOp::Mul | BinOp::Div) => {
                self.emit_vec_scalar_binop(rhs, r, lhs, l, op, true)
            }
            _ => {
                self.err("unsupported operand types for binary operator", Span::dummy());
                "%undef".into()
            }
        }
    }

    /// Dot product of two already-untagged Vec2/Vec3/Vec4 registers of the
    /// same type, returning a bare `float` register. Shared by the `dot`
    /// builtin and `length` (`length(v) == sqrt(dot(v, v))`).
    fn emit_dot_bare(&mut self, a_bare: &str, b_bare: &str, ty: &Ty) -> String {
        if ty.is_vec() {
            self.emit_dot_vec(a_bare, b_bare, ty)
        } else {
            self.err("dot(..)/length(..) expect a Vec2/Vec3/Vec4 argument", Span::dummy());
            "0.0".to_string()
        }
    }

    /// `dot(a, b) -> f32`.
    pub(super) fn emit_dot(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("dot(..) expects 2 arguments", Span::dummy());
            return "float 0.0".into();
        }
        let ty = self.expr_ty(&args[0]);
        let a = self.emit_expr(&args[0]);
        let b = self.emit_expr(&args[1]);
        let a_bare = self.untag(&a, &ty);
        let b_bare = self.untag(&b, &ty);
        let result = self.emit_dot_bare(&a_bare, &b_bare, &ty);
        format!("float {}", result)
    }

    /// `length(v) -> f32`.
    pub(super) fn emit_length(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("length(..) expects 1 argument", Span::dummy());
            return "float 0.0".into();
        };
        let ty = self.expr_ty(arg);
        let v = self.emit_expr(arg);
        let bare = self.untag(&v, &ty);
        let dot_bare = self.emit_dot_bare(&bare, &bare, &ty);
        let reg = self.tmp_name();
        self.line(&format!("  {} = call float @llvm.sqrt.f32(float {})", reg, dot_bare));
        format!("float {}", reg)
    }

    /// `lerp(a, b, t) -> same type as a`: `a + (b - a) * t`, generic over
    /// `f32`/`Vec2`/`Vec3`/`Vec4`.
    pub(super) fn emit_lerp(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 3 {
            self.err("lerp(..) expects 3 arguments", Span::dummy());
            return "float 0.0".into();
        }
        let ty = self.expr_ty(&args[0]);
        let a = self.emit_expr(&args[0]);
        let b = self.emit_expr(&args[1]);
        let t_val = self.emit_expr(&args[2]);
        let t_ty = self.expr_ty(&args[2]);
        let t = self.promote_to_float(&t_val, &t_ty);
        match ty {
            Ty::Float => {
                let a_bare = self.untag(&a, &Ty::Float);
                let b_bare = self.untag(&b, &Ty::Float);
                let diff = self.tmp_name();
                self.line(&format!("  {} = fsub float {}, {}", diff, b_bare, a_bare));
                let scaled = self.tmp_name();
                self.line(&format!("  {} = fmul float {}, {}", scaled, diff, t));
                let result = self.tmp_name();
                self.line(&format!("  {} = fadd float {}, {}", result, a_bare, scaled));
                format!("float {}", result)
            }
            Ty::Vec2 | Ty::Vec3 | Ty::Vec4 => {
                let a_bare = self.untag(&a, &ty);
                let b_bare = self.untag(&b, &ty);
                let arity = ty.vec_arity().unwrap();
                let mut acc = "undef".to_string();
                for i in 0..arity as u32 {
                    let ac = self.extract_component(&a_bare, &ty, i);
                    let bc = self.extract_component(&b_bare, &ty, i);
                    let diff = self.tmp_name();
                    self.line(&format!("  {} = fsub float {}, {}", diff, bc, ac));
                    let scaled = self.tmp_name();
                    self.line(&format!("  {} = fmul float {}, {}", scaled, diff, t));
                    let comp = self.tmp_name();
                    self.line(&format!("  {} = fadd float {}, {}", comp, ac, scaled));
                    acc = self.insert_component(&acc, &ty, i, &comp);
                }
                format!("{} {}", self.llvm_ty(&ty), acc)
            }
            _ => {
                self.err("lerp(..) expects f32/Vec2/Vec3/Vec4 arguments", Span::dummy());
                "float 0.0".into()
            }
        }
    }

    /// `clamp(x, lo, hi) -> same type as x`, generic over every numeric
    /// width `Checker::check_builtin_call_args`'s `"clamp"` arm accepts
    /// (`i8..u64`/`f32`/`f64`, via the fully-widened `is_numeric()`), not
    /// just `i32`/`f32` -- mirrors `emit_minmax`'s/`emit_abs`'s own
    /// width/signedness-generic dispatch (`ty.int_shape()`) plus a real
    /// `f32` vs. `f64` split, rather than this function's previous
    /// unconditional `i32`/`float` opcodes for every non-`Ty::Float` /
    /// non-`f32` case respectively -- confirmed to emit `clang`-rejected IR
    /// (an `i32`-tagged operand feeding an `icmp`/`select` that expected
    /// the real operand width, e.g. `i64`, and a bare `float`-tagged
    /// `maxnum.f32` result stored into an `f64` slot expecting `double`)
    /// for every numeric type this function didn't special-case before this
    /// fix.
    pub(super) fn emit_clamp(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 3 {
            self.err("clamp(..) expects 3 arguments", Span::dummy());
            return "i32 0".into();
        }
        let ty = self.expr_ty(&args[0]);
        let x = self.emit_expr(&args[0]);
        let lo = self.emit_expr(&args[1]);
        let hi = self.emit_expr(&args[2]);
        if matches!(ty, Ty::Float | Ty::F64) {
            let (fty, intrinsic_suffix) = if matches!(ty, Ty::F64) { ("double", "f64") } else { ("float", "f32") };
            let x_b = self.untag(&x, &ty);
            let lo_b = self.untag(&lo, &ty);
            let hi_b = self.untag(&hi, &ty);
            let m1 = self.tmp_name();
            self.line(&format!("  {} = call {} @llvm.maxnum.{}({} {}, {} {})", m1, fty, intrinsic_suffix, fty, x_b, fty, lo_b));
            let m2 = self.tmp_name();
            self.line(&format!("  {} = call {} @llvm.minnum.{}({} {}, {} {})", m2, fty, intrinsic_suffix, fty, m1, fty, hi_b));
            format!("{} {}", fty, m2)
        } else {
            let (width, signed) = ty.int_shape().unwrap_or((32, true));
            let ity = format!("i{}", width);
            let pred_gt = if signed { "sgt" } else { "ugt" };
            let pred_lt = if signed { "slt" } else { "ult" };
            let x_b = self.untag(&x, &ty);
            let lo_b = self.untag(&lo, &ty);
            let hi_b = self.untag(&hi, &ty);
            let c1 = self.tmp_name();
            self.line(&format!("  {} = icmp {} {} {}, {}", c1, pred_gt, ity, lo_b, x_b));
            let m1 = self.tmp_name();
            self.line(&format!("  {} = select i1 {}, {} {}, {} {}", m1, c1, ity, lo_b, ity, x_b));
            let c2 = self.tmp_name();
            self.line(&format!("  {} = icmp {} {} {}, {}", c2, pred_lt, ity, hi_b, m1));
            let m2 = self.tmp_name();
            self.line(&format!("  {} = select i1 {}, {} {}, {} {}", m2, c2, ity, hi_b, ity, m1));
            format!("{} {}", ity, m2)
        }
    }

    /// Advance the `rand`/`rand_range` xorshift32 generator by one step,
    /// persisting the new state back to `@rng.state` and returning a bare
    /// `i32` register holding it.
    ///
    /// Guarded by `@rng.lock` (see its own doc comment in
    /// `Codegen::emit_builtins`): unlike `Symbol`'s intern table, a plain
    /// `i32` load/store can't itself tear, but the load-xorshift-store
    /// sequence as a whole is still a real read-modify-write race across
    /// `par`/`swarm`'s 4 concurrent worker threads -- two threads both
    /// loading `@rng.state` before either stores back compute and store the
    /// *identical* next value (a lost update), producing statistically
    /// impossible duplicate "random" draws within the same tick. Confirmed
    /// via a real run showing dozens of arena entities converging on the
    /// same value in the same tick, 5/5 runs, before this lock was added.
    fn emit_rand_next(&mut self) -> String {
        let lock_h = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** @rng.lock", lock_h));
        self.emit_semaphore_wait(&lock_h);

        let x0 = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* @rng.state", x0));
        let s1 = self.tmp_name();
        self.line(&format!("  {} = shl i32 {}, 13", s1, x0));
        let x1 = self.tmp_name();
        self.line(&format!("  {} = xor i32 {}, {}", x1, x0, s1));
        let s2 = self.tmp_name();
        self.line(&format!("  {} = lshr i32 {}, 17", s2, x1));
        let x2 = self.tmp_name();
        self.line(&format!("  {} = xor i32 {}, {}", x2, x1, s2));
        let s3 = self.tmp_name();
        self.line(&format!("  {} = shl i32 {}, 5", s3, x2));
        let x3 = self.tmp_name();
        self.line(&format!("  {} = xor i32 {}, {}", x3, x2, s3));
        self.line(&format!("  store i32 {}, i32* @rng.state", x3));

        self.emit_semaphore_post(&lock_h);
        x3
    }

    /// `rand() -> f32` in `[0, 1)`.
    pub(super) fn emit_rand(&mut self) -> String {
        let x = self.emit_rand_next();
        // Mask to the low 24 bits (a full `f32` mantissa's worth of
        // precision) and scale to `[0, 1)`.
        let masked = self.tmp_name();
        self.line(&format!("  {} = and i32 {}, 16777215", masked, x));
        let as_f = self.tmp_name();
        self.line(&format!("  {} = uitofp i32 {} to float", as_f, masked));
        let reg = self.tmp_name();
        self.line(&format!("  {} = fdiv float {}, {}", reg, as_f, format_f32_literal(16777216.0)));
        format!("float {}", reg)
    }

    /// `rand_range(lo, hi) -> i32` in `[lo, hi)`.
    pub(super) fn emit_rand_range(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("rand_range(..) expects 2 arguments", Span::dummy());
            return "i32 0".into();
        }
        let lo_v = self.emit_expr(&args[0]);
        let hi_v = self.emit_expr(&args[1]);
        let lo = self.untag(&lo_v, &Ty::Int);
        let hi = self.untag(&hi_v, &Ty::Int);
        let range = self.tmp_name();
        self.line(&format!("  {} = sub i32 {}, {}", range, hi, lo));
        // Guard against a non-positive range (misuse, e.g. `hi <= lo`)
        // rather than dividing by zero/a negative modulus.
        let is_le0 = self.tmp_name();
        self.line(&format!("  {} = icmp sle i32 {}, 0", is_le0, range));
        let safe_range = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 1, i32 {}", safe_range, is_le0, range));
        let x = self.emit_rand_next();
        let unsigned = self.tmp_name();
        self.line(&format!("  {} = and i32 {}, 2147483647", unsigned, x));
        let m = self.tmp_name();
        self.line(&format!("  {} = urem i32 {}, {}", m, unsigned, safe_range));
        let result = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, {}", result, lo, m));
        format!("i32 {}", result)
    }

    /// `rand_seed(seed)`: reseed the generator (guarding against a `0` seed,
    /// which would make xorshift32 output `0` forever).
    ///
    /// Guarded by `@rng.lock` (see `emit_rand_next`'s doc comment) so a
    /// `rand_seed(..)` call racing a concurrent `rand`/`rand_range` call's
    /// load-xorshift-store sequence can't interleave with it and clobber/lose
    /// either side's update to `@rng.state`.
    pub(super) fn emit_rand_seed(&mut self, args: &[TypedExpr]) {
        let Some(arg) = args.first() else {
            self.err("rand_seed(..) expects 1 argument", Span::dummy());
            return;
        };
        let v = self.emit_expr(arg);
        let bare = self.untag(&v, &Ty::Int);
        let is_zero = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 0", is_zero, bare));
        let safe = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 1, i32 {}", safe, is_zero, bare));

        let lock_h = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** @rng.lock", lock_h));
        self.emit_semaphore_wait(&lock_h);
        self.line(&format!("  store i32 {}, i32* @rng.state", safe));
        self.emit_semaphore_post(&lock_h);
    }

    /// Shared by both f-string codegen paths (`emit_print_like` in
    /// `builtins.rs`, and the general `TypedExpr::FStr`-as-value path in
    /// `expr.rs`) to interpolate a builtin vector/matrix aggregate
    /// (`Vec2`/`Vec3`/`Vec4`/`Quat`/`Color`/`Mat2`/`Mat3`/`Mat4`) -- these all
    /// fell through both paths' `%p` catch-all before this (see this fix's
    /// changelog entry in `todo.md`), tagging a plain `<N x float>`/`[N x <N
    /// x float>]` aggregate register as a pointer vararg, an invalid-IR
    /// `clang` compile failure exactly like `Color32`/`PaletteIndex`'s
    /// earlier one-off fix (this generalizes that fix to every remaining
    /// bare-aggregate type instead of one-off `%p` arms). Formats as its own
    /// constructor call syntax (`Vec2(1.000000, 2.000000)`,
    /// `Mat2(Vec2(...), Vec2(...))`) so the printed form is valid Star source
    /// round-tripping the value, mirroring `examples/matrices.star`'s own
    /// `Mat2(Vec2(...), Vec2(...))` construction shape.
    ///
    /// Returns `(literal_format_fragment, bare_f32_lane_registers)` --
    /// `literal_format_fragment` is ordinary literal text (constructor name/
    /// parens/commas) plus one `%f` per lane, meant to be appended directly
    /// to the caller's running format string (no `%`-escaping needed, none of
    /// `Vec2(`/`, `/`)` contain a literal `%`); the lane registers are bare,
    /// unwidened `float` registers in constructor-argument order (row-major
    /// for matrices) -- the caller widens each to `double` for the `%f`
    /// vararg slot itself, since the two call sites do that widening through
    /// different mechanisms (`builtins.rs`'s two-pass `(val, Ty)` widening
    /// vs. `expr.rs`'s inline widening).
    pub(super) fn emit_agg_fstring_lanes(&mut self, ty: &Ty, bare_val: &str) -> (String, Vec<String>) {
        if let Some(arity) = ty.vec_arity() {
            let name = match ty {
                Ty::Vec2 => "Vec2",
                Ty::Vec3 => "Vec3",
                Ty::Vec4 => "Vec4",
                Ty::Quat => "Quat",
                Ty::Color => "Color",
                _ => unreachable!("vec_arity() only returns Some for Vec2/Vec3/Vec4/Quat/Color"),
            };
            let t = self.llvm_ty(ty);
            let mut lanes = Vec::with_capacity(arity as usize);
            for i in 0..arity as u32 {
                let lane = self.tmp_name();
                self.line(&format!("  {} = extractelement {} {}, i32 {}", lane, t, bare_val, i));
                lanes.push(lane);
            }
            let holes = vec!["%f"; arity as usize].join(", ");
            (format!("{}({})", name, holes), lanes)
        } else if let Some(dim) = ty.mat_dim() {
            let name = match ty {
                Ty::Mat2 => "Mat2",
                Ty::Mat3 => "Mat3",
                Ty::Mat4 => "Mat4",
                _ => unreachable!("mat_dim() only returns Some for Mat2/Mat3/Mat4"),
            };
            let row_ty = Ty::vec_of_arity(dim as u8).expect("mat_dim is always 2, 3, or 4");
            let row_name = match row_ty {
                Ty::Vec2 => "Vec2",
                Ty::Vec3 => "Vec3",
                Ty::Vec4 => "Vec4",
                _ => unreachable!("vec_of_arity(2/3/4) only returns Vec2/Vec3/Vec4"),
            };
            let row_llty = self.llvm_ty(&row_ty);
            let mat_t = self.llvm_ty(ty);
            let mut lanes = Vec::with_capacity((dim * dim) as usize);
            let mut row_fmts = Vec::with_capacity(dim as usize);
            for i in 0..dim {
                let row = self.tmp_name();
                self.line(&format!("  {} = extractvalue {} {}, {}", row, mat_t, bare_val, i));
                for j in 0..dim {
                    let lane = self.tmp_name();
                    self.line(&format!("  {} = extractelement {} {}, i32 {}", lane, row_llty, row, j));
                    lanes.push(lane);
                }
                let holes = vec!["%f"; dim as usize].join(", ");
                row_fmts.push(format!("{}({})", row_name, holes));
            }
            (format!("{}({})", name, row_fmts.join(", ")), lanes)
        } else {
            unreachable!("emit_agg_fstring_lanes only called for is_vec()/is_mat() types")
        }
    }

    pub(super) fn emit_assign_binop(&mut self, lhs: &str, lty: &Ty, rhs: &str, rty: &Ty, op: AssignOp) -> String {
        let bin_op = match op {
            AssignOp::Add => BinOp::Add,
            AssignOp::Sub => BinOp::Sub,
            AssignOp::Mul => BinOp::Mul,
            AssignOp::Div => BinOp::Div,
            AssignOp::BitAnd => BinOp::BitAnd,
            AssignOp::BitOr => BinOp::BitOr,
            AssignOp::BitXor => BinOp::BitXor,
            AssignOp::Shl => BinOp::Shl,
            AssignOp::Shr => BinOp::Shr,
            AssignOp::Eq => unreachable!("AssignOp::Eq is filtered out before reaching emit_assign_binop"),
        };
        self.emit_binop(lhs, lty, rhs, rty, bin_op)
    }
}
