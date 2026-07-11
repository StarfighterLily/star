//! The `print`/`println`, math (`sqrt`/`pow`/`abs`/`min`/`max`/...), and
//! string (`len`/`concat`) standard-library builtins.

use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

impl Codegen {
    /// Shared lowering for the `print`/`println` builtins: an f-string
    /// argument is flattened into a single `printf` format string
    /// (interpolations become `%d`/`%f`/`%s` holes); any other argument is
    /// passed straight through as a format-string pointer. `println` differs
    /// from `print` only in that it guarantees a trailing newline even when
    /// the argument isn't an f-string (an f-string argument already gets one
    /// baked into its format string either way).
    pub(super) fn emit_print_like(&mut self, args: &[TypedExpr], println: bool) {
        let Some(arg) = args.first() else { return };
        if let TypedExpr::FStr(parts, _, _) = arg {
            let mut fmt_str = String::new();
            let mut arg_vals: Vec<(String, Ty)> = Vec::new();
            for part in parts {
                match part {
                    TypedFStrExpr::Literal(lit) => {
                        fmt_str.push_str(&lit.replace("%", "%%"));
                    }
                    TypedFStrExpr::Expr(e) => {
                        let val = self.emit_expr(e);
                        let ty = self.expr_ty(e);
                        match ty {
                            Ty::Int => { fmt_str.push_str("%d"); }
                            Ty::Float => { fmt_str.push_str("%f"); }
                            Ty::Str | Ty::Bool => { fmt_str.push_str("%s"); }
                            _ => { fmt_str.push_str("%p"); }
                        }
                        // `emit_expr` may return either a bare register
                        // or one already tagged with its LLVM type
                        // (e.g. swizzle reads) — strip any existing tag
                        // so it isn't double-tagged below. For a `Str`
                        // value this already *is* the raw `i8*` pointer
                        // `%s` expects (no boxing indirection to unwrap).
                        let bare_val = self.untag(&val, &ty);
                        // A `bool` isn't a pointer at all -- printing it via
                        // `%p` on a bare `i1` is undefined behavior (varargs
                        // promotion reads a pointer-sized value off the
                        // stack/register that was never written); select
                        // between "true"/"false" string constants instead,
                        // same as any other `%s`.
                        let arg_val = if matches!(ty, Ty::Str) {
                            // Same reasoning as `emit_raw_str_ptr`: balance
                            // back out whatever retain `emit_expr(e)` above
                            // did on `e`'s behalf (a no-op if `e` was a
                            // fresh construction, since nothing was
                            // retained) -- this f-string hole only formats
                            // the bytes for `printf`, it doesn't keep the
                            // pointer around.
                            if Self::is_rc_borrowing_read(e) {
                                self.line(&format!("  call void @star_rc_release(i8* {})", bare_val));
                            }
                            bare_val
                        } else if matches!(ty, Ty::Bool) {
                            self.emit_bool_str(&bare_val)
                        } else {
                            bare_val
                        };
                        arg_vals.push((arg_val, ty));
                    }
                }
            }
            fmt_str.push('\n');
            let g = self.global_name();
            let escaped = fmt_str.replace("\\", "\\\\").replace("\"", "\\22").replace("\n", "\\0A");
            self.global_defs.push(format!("{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"", g, fmt_str.len() + 1, escaped));

            let fmt_reg = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", fmt_reg, fmt_str.len() + 1, fmt_str.len() + 1, g));

            let mut call_args = vec![format!("i8* {}", fmt_reg)];
            for (val, ty) in &arg_vals {
                if matches!(ty, Ty::Float) {
                    // C's variadic calling convention always
                    // promotes `float` to `double`; printf's
                    // `%f` reads a `double` off the varargs.
                    let widened = self.tmp_name();
                    self.line(&format!("  {} = fpext float {} to double", widened, val));
                    call_args.push(format!("double {}", widened));
                } else if matches!(ty, Ty::Bool) {
                    // `emit_bool_str` already turned this into an `i8*`
                    // (a "true"/"false" string pointer), not the bare
                    // `i1` `llvm_ty(Ty::Bool)` would tag it as.
                    call_args.push(format!("i8* {}", val));
                } else {
                    call_args.push(format!("{} {}", self.llvm_ty(ty), val));
                }
            }
            self.line(&format!("  call i32 (i8*, ...) @printf({})", call_args.join(", ")));
        } else {
            let val = self.emit_expr(arg);
            // `emit_expr` may return either a bare register or one already
            // tagged with its LLVM type (e.g. a `ListIndex`/closure-call
            // result) -- strip any existing tag so it isn't double-tagged
            // below (previously missing here, this produced malformed IR
            // like `load i8*, i8** i8* %reg` for anything but a plain
            // `Ident`/`Field` argument). This is already the raw `i8*`
            // pointer `printf` expects, no boxing indirection to unwrap.
            let loaded = self.untag(&val, &Ty::Str);
            // Same reasoning as `emit_raw_str_ptr`/the f-string branch
            // above: balance back out whatever retain `emit_expr(arg)`
            // did on `arg`'s behalf.
            if matches!(self.expr_ty(arg), Ty::Str) && Self::is_rc_borrowing_read(arg) {
                self.line(&format!("  call void @star_rc_release(i8* {})", loaded));
            }
            self.line(&format!("  call i32 (i8*, ...) @printf(i8* {})", loaded));
            if println {
                let g = self.global_name();
                self.global_defs.push(format!("{} = private unnamed_addr constant [2 x i8] c\"\\0A\\00\"", g));
                let nl_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds [2 x i8], [2 x i8]* {}, i64 0, i64 0", nl_ptr, g));
                self.line(&format!("  call i32 (i8*, ...) @printf(i8* {})", nl_ptr));
            }
        }
    }

    /// Select between `"true"`/`"false"` string constants based on a bare
    /// `i1` register, returning an `i8*` suitable for a `%s` format hole.
    fn emit_bool_str(&mut self, bare_bool: &str) -> String {
        let true_g = self.global_name();
        self.global_defs.push(format!("{} = private unnamed_addr constant [5 x i8] c\"true\\00\"", true_g));
        let false_g = self.global_name();
        self.global_defs.push(format!("{} = private unnamed_addr constant [6 x i8] c\"false\\00\"", false_g));
        let true_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [5 x i8], [5 x i8]* {}, i64 0, i64 0", true_ptr, true_g));
        let false_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [6 x i8], [6 x i8]* {}, i64 0, i64 0", false_ptr, false_g));
        let sel = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i8* {}, i8* {}", sel, bare_bool, true_ptr, false_ptr));
        sel
    }

    /// Call a unary LLVM float intrinsic (`sqrt`, `floor`, `ceil`),
    /// promoting an `i32` argument to `float` first if needed.
    pub(super) fn emit_math_unary(&mut self, args: &[TypedExpr], intrinsic: &str) -> String {
        let Some(arg) = args.first() else {
            self.err(&format!("{}(..) expects 1 argument", intrinsic), Span::dummy());
            return "float 0.0".into();
        };
        let ty = self.expr_ty(arg);
        let val = self.emit_expr(arg);
        let bare = self.promote_to_float(&val, &ty);
        let reg = self.tmp_name();
        self.line(&format!("  {} = call float @{}(float {})", reg, intrinsic, bare));
        format!("float {}", reg)
    }

    /// Call a binary LLVM float intrinsic (`pow`), promoting `i32` arguments
    /// to `float` first if needed.
    pub(super) fn emit_math_binary_f32(&mut self, args: &[TypedExpr], intrinsic: &str) -> String {
        if args.len() < 2 {
            self.err(&format!("{}(..) expects 2 arguments", intrinsic), Span::dummy());
            return "float 0.0".into();
        }
        let lty = self.expr_ty(&args[0]);
        let rty = self.expr_ty(&args[1]);
        let lval = self.emit_expr(&args[0]);
        let rval = self.emit_expr(&args[1]);
        let lbare = self.promote_to_float(&lval, &lty);
        let rbare = self.promote_to_float(&rval, &rty);
        let reg = self.tmp_name();
        self.line(&format!("  {} = call float @{}(float {}, float {})", reg, intrinsic, lbare, rbare));
        format!("float {}", reg)
    }

    /// `abs(x)`: dispatches on the argument's resolved type, preserving
    /// Int-vs-Float rather than always widening to float.
    pub(super) fn emit_abs(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("abs(..) expects 1 argument", Span::dummy());
            return "i32 0".into();
        };
        let ty = self.expr_ty(arg);
        let val = self.emit_expr(arg);
        let bare = self.untag(&val, &ty);
        if matches!(ty, Ty::Float) {
            let reg = self.tmp_name();
            self.line(&format!("  {} = call float @llvm.fabs.f32(float {})", reg, bare));
            format!("float {}", reg)
        } else {
            let neg = self.tmp_name();
            self.line(&format!("  {} = sub i32 0, {}", neg, bare));
            let is_neg = self.tmp_name();
            self.line(&format!("  {} = icmp slt i32 {}, 0", is_neg, bare));
            let reg = self.tmp_name();
            self.line(&format!("  {} = select i1 {}, i32 {}, i32 {}", reg, is_neg, neg, bare));
            format!("i32 {}", reg)
        }
    }

    /// `min(a, b)`/`max(a, b)`: dispatches on the arguments' resolved type
    /// (Int uses `icmp`+`select`, Float uses the `minnum`/`maxnum`
    /// intrinsics), preserving Int-vs-Float rather than always widening.
    pub(super) fn emit_minmax(&mut self, args: &[TypedExpr], is_min: bool) -> String {
        if args.len() < 2 {
            self.err("min/max(..) expects 2 arguments", Span::dummy());
            return "i32 0".into();
        }
        let lty = self.expr_ty(&args[0]);
        let rty = self.expr_ty(&args[1]);
        let lval = self.emit_expr(&args[0]);
        let rval = self.emit_expr(&args[1]);
        if matches!(lty, Ty::Float) || matches!(rty, Ty::Float) {
            let l = self.promote_to_float(&lval, &lty);
            let r = self.promote_to_float(&rval, &rty);
            let reg = self.tmp_name();
            let intrinsic = if is_min { "llvm.minnum.f32" } else { "llvm.maxnum.f32" };
            self.line(&format!("  {} = call float @{}(float {}, float {})", reg, intrinsic, l, r));
            format!("float {}", reg)
        } else {
            let l = self.untag(&lval, &lty);
            let r = self.untag(&rval, &rty);
            let cmp = self.tmp_name();
            let pred = if is_min { "slt" } else { "sgt" };
            self.line(&format!("  {} = icmp {} i32 {}, {}", cmp, pred, l, r));
            let reg = self.tmp_name();
            self.line(&format!("  {} = select i1 {}, i32 {}, i32 {}", reg, cmp, l, r));
            format!("i32 {}", reg)
        }
    }

    /// Get the real `i8*` out of a `Str`-typed expression. A `Str` value's
    /// `emit_expr` result *is* the raw string pointer (tagged for a literal,
    /// bare for a load/call), so this is just a tag-stripping pass-through --
    /// kept as its own function since every caller also needs the
    /// `is_rc_borrowing_read` release-balancing below.
    fn emit_raw_str_ptr(&mut self, e: &TypedExpr) -> String {
        let val = self.emit_expr(e);
        let reg = self.untag(&val, &Ty::Str);
        // If `e` reads an existing owned slot, `emit_expr` above already
        // retained a fresh reference on its behalf (see `rc.rs`) -- but
        // this function only extracts the raw bytes for a synchronous
        // library call (`strlen`/`strcpy`/...) and never keeps the pointer
        // around, so that retain must be released right back or `s`'s
        // refcount would grow by one on every `len(s)`/`concat(s, ..)`
        // call, never balanced by a matching release.
        if Self::is_rc_borrowing_read(e) {
            self.line(&format!("  call void @star_rc_release(i8* {})", reg));
        }
        reg
    }

    /// `len(s) -> i32`.
    pub(super) fn emit_str_len(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("len(..) expects 1 argument", Span::dummy());
            return "i32 0".into();
        };
        let raw = self.emit_raw_str_ptr(arg);
        let reg = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", reg, raw));
        format!("i32 {}", reg)
    }

    /// `concat(a, b) -> str`: allocates a new buffer sized for both strings
    /// plus a null terminator, then copies `a` followed by `b` into it.
    pub(super) fn emit_str_concat(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("concat(..) expects 2 arguments", Span::dummy());
            return "i8* null".into();
        }
        let a = self.emit_raw_str_ptr(&args[0]);
        let b = self.emit_raw_str_ptr(&args[1]);
        let len_a = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", len_a, a));
        let len_b = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", len_b, b));
        let total = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, {}", total, len_a, len_b));
        let total_plus_nul = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", total_plus_nul, total));
        let total64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", total64, total_plus_nul));
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* null)", buf, total64));
        self.line(&format!("  call i8* @strcpy(i8* {}, i8* {})", buf, a));
        self.line(&format!("  call i8* @strcat(i8* {}, i8* {})", buf, b));
        buf
    }
}
