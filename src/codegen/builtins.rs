//! The `print`/`println`, math (`sqrt`/`pow`/`abs`/`min`/`max`/...), and
//! string (`len`/`concat`) standard-library builtins.

use crate::ast::BinOp;
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
                        // `Fixed<Bits,Frac>` has no format specifier of its
                        // own -- print it as a human-readable decimal via the
                        // same scaled-conversion the `as float`/`as f64` cast
                        // uses, reusing the `Ty::F64` path below rather than
                        // adding a dedicated specifier arm.
                        let (val, ty) = if let Ty::Fixed(bits, frac) = ty {
                            let bare = self.untag(&val, &Ty::Fixed(bits, frac));
                            (self.emit_fixed_to_float(&bare, bits, frac, true), Ty::F64)
                        } else {
                            (val, ty)
                        };
                        match &ty {
                            Ty::Int | Ty::I8 | Ty::I16 => { fmt_str.push_str("%d"); }
                            Ty::U8 | Ty::U16 | Ty::U32 => { fmt_str.push_str("%u"); }
                            Ty::I64 => { fmt_str.push_str("%lld"); }
                            // All three lower to a bare signed `i64` -- see
                            // `Ty::Tick`'s doc comment.
                            Ty::Tick | Ty::Duration | Ty::Instant => { fmt_str.push_str("%lld"); }
                            // A bare signed `i64` id -- see `Ty::Symbol`'s
                            // doc comment. Prints the raw interned id (use
                            // `symbol_name(sym)` to print the original
                            // string instead).
                            Ty::Symbol => { fmt_str.push_str("%lld"); }
                            Ty::U64 => { fmt_str.push_str("%llu"); }
                            Ty::Float | Ty::F64 => { fmt_str.push_str("%f"); }
                            Ty::Char => { fmt_str.push_str("%c"); }
                            Ty::Str | Ty::Bool => { fmt_str.push_str("%s"); }
                            // Delegate to the inner integer type's own
                            // specifier -- `Wrapping<T>` is the exact same
                            // LLVM value, just re-tagged (see `Ty::Wrapping`'s
                            // doc comment).
                            Ty::Wrapping(inner) => match inner.int_shape() {
                                Some((64, true)) => fmt_str.push_str("%lld"),
                                Some((64, false)) => fmt_str.push_str("%llu"),
                                Some((_, false)) => fmt_str.push_str("%u"),
                                _ => fmt_str.push_str("%d"),
                            },
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
                            // This f-string hole only formats the bytes for
                            // `printf`, it doesn't keep the pointer around --
                            // release whatever `emit_expr(e)` above left us
                            // owning (a borrowed read's extra retain, or a
                            // fresh construction's sole reference; see
                            // `rc.rs`'s module doc comment for why this is
                            // unconditional and always safe).
                            self.line(&format!("  call void @star_rc_release(i8* {})", bare_val));
                            bare_val
                        } else if matches!(ty, Ty::Bool) {
                            self.emit_bool_str(&bare_val)
                        } else {
                            // Same reasoning as the `Str` arm above,
                            // generalized to any other RC-bearing type
                            // (`List`/`Map`/`Set`/`Closure`/struct/payload
                            // enum) via `emit_release_bare`, since there's no
                            // single flat pointer to release directly here --
                            // this `%p` hole only prints the value's raw
                            // address, it doesn't keep it around. A no-op for
                            // `Int`/`Float` (neither carries RC content).
                            self.emit_release_bare(&bare_val, &ty);
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
                } else if matches!(ty, Ty::I8 | Ty::I16) {
                    // C's variadic calling convention promotes any integer
                    // type narrower than `int` up to `int` -- `%d`/`%u`
                    // read a full 32-bit slot off the varargs, so an
                    // un-widened `i8`/`i16` register would leave the upper
                    // bits of that slot garbage.
                    let widened = self.tmp_name();
                    self.line(&format!("  {} = sext {} {} to i32", widened, self.llvm_ty(ty), val));
                    call_args.push(format!("i32 {}", widened));
                } else if matches!(ty, Ty::U8 | Ty::U16) {
                    let widened = self.tmp_name();
                    self.line(&format!("  {} = zext {} {} to i32", widened, self.llvm_ty(ty), val));
                    call_args.push(format!("i32 {}", widened));
                } else if let Ty::Wrapping(inner) = ty {
                    // Same C variadic-promotion rule as the `I8`/`I16`/`U8`/
                    // `U16` arms above, just indirected through the inner
                    // type -- `Wrapping<T>` is tagged/laid out identically to
                    // `T` (see `Ty::Wrapping`'s doc comment), so it needs the
                    // exact same promotion `T` alone would.
                    match inner.int_shape() {
                        Some((w, signed)) if w < 32 => {
                            let widened = self.tmp_name();
                            let op = if signed { "sext" } else { "zext" };
                            self.line(&format!("  {} = {} i{} {} to i32", widened, op, w, val));
                            call_args.push(format!("i32 {}", widened));
                        }
                        _ => call_args.push(format!("{} {}", self.llvm_ty(ty), val)),
                    }
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
            // above: release whatever `emit_expr(arg)` left us owning.
            if matches!(self.expr_ty(arg), Ty::Str) {
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
    pub(super) fn emit_bool_str(&mut self, bare_bool: &str) -> String {
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
        } else if matches!(ty, Ty::F64) {
            let reg = self.tmp_name();
            self.line(&format!("  {} = call double @llvm.fabs.f64(double {})", reg, bare));
            format!("double {}", reg)
        } else {
            // Any integer type -- `int_shape` covers `Ty::Int` (`i32`) and
            // every explicit-width addition (`i8`/`u8`/.../`u64`) alike.
            let (width, signed) = ty.int_shape().unwrap_or((32, true));
            let ity = format!("i{}", width);
            if !signed {
                // Already non-negative by construction -- an unsigned
                // value's `abs` is itself, no computation needed.
                return format!("{} {}", ity, bare);
            }
            // Route the negation through the same width/signedness-generic
            // scalar-binop path real binary `-`/unary `-` use (`0 - x`,
            // `Codegen::emit_unary`'s `UnOp::Neg` case) rather than a bare,
            // untrapped `sub` opcode -- every explicit-width signed integer
            // type traps on overflow by default (`docs/design.md`'s
            // "Numeric widths and modes", `Ty::Int`/i32 excepted), and
            // `abs(MIN)` is exactly the one input where `0 - x` overflows.
            // Previously this used a raw `sub {ity} 0, {bare}` that silently
            // wrapped instead of trapping -- confirmed via `abs(-128 as
            // i8)` printing `-128` with exit 0 (no trap) where the
            // equivalent direct `(0 as i8) - (-128 as i8)` correctly traps,
            // the one signed-int overflow gap `abs` didn't inherit from the
            // rest of this codegen's trap-on-overflow machinery.
            let tagged = format!("{} {}", ity, bare);
            let zero = format!("{} 0", ity);
            let neg = self.emit_binop(&zero, &ty, &tagged, &ty, BinOp::Sub);
            let neg_bare = self.untag(&neg, &ty);
            let is_neg = self.tmp_name();
            self.line(&format!("  {} = icmp slt {} {}, 0", is_neg, ity, bare));
            let reg = self.tmp_name();
            self.line(&format!("  {} = select i1 {}, {} {}, {} {}", reg, is_neg, ity, neg_bare, ity, bare));
            format!("{} {}", ity, reg)
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
        if matches!(lty, Ty::F64) || matches!(rty, Ty::F64) {
            // `min`/`max` preserve their operands' numeric type
            // (`Checker::builtin_return_ty`) rather than always narrowing
            // to `f32` -- an `f64` pair must stay `double` all the way
            // through, both the intrinsic call and this function's own
            // returned tag. Previously this always went through
            // `promote_to_float` (which narrows an `f64` operand down to
            // `f32`) and always tagged the result `"float "`, so a
            // `min`/`max(f64, f64)` call site (whose checker-assigned type
            // is `F64`) received a value tagged `float` -- any consumer
            // that untags it as `Ty::F64` (expecting a `"double "` prefix)
            // failed to strip the wrong tag, producing malformed,
            // `clang`-rejected IR. Confirmed via a real `star build`
            // failure on `min(3.5 as f64, 7.5 as f64)` before this fix.
            let l = self.untag(&lval, &lty);
            let r = self.untag(&rval, &rty);
            let reg = self.tmp_name();
            let intrinsic = if is_min { "llvm.minnum.f64" } else { "llvm.maxnum.f64" };
            self.line(&format!("  {} = call double @{}(double {}, double {})", reg, intrinsic, l, r));
            format!("double {}", reg)
        } else if matches!(lty, Ty::Float) || matches!(rty, Ty::Float) {
            // Same "one legacy mixed pair, otherwise an exact match" rule
            // as the integer branch below -- an `Int`/`Float` pair is the
            // one case `Checker::check_builtin_call_args` tolerates a type
            // mismatch for, so promoting both to `f32` here is safe (and
            // matches `pow`/`sqrt`/etc.'s own always-`f32` precision, per
            // `promote_to_float`'s doc comment).
            let l = self.promote_to_float(&lval, &lty);
            let r = self.promote_to_float(&rval, &rty);
            let reg = self.tmp_name();
            let intrinsic = if is_min { "llvm.minnum.f32" } else { "llvm.maxnum.f32" };
            self.line(&format!("  {} = call float @{}(float {}, float {})", reg, intrinsic, l, r));
            format!("float {}", reg)
        } else {
            // Any integer pair -- the checker requires `lty == rty` here
            // (no legacy mixed pair applies once floats are ruled out), so
            // either type's shape describes both operands.
            let (width, signed) = lty.int_shape().unwrap_or((32, true));
            let ity = format!("i{}", width);
            let l = self.untag(&lval, &lty);
            let r = self.untag(&rval, &rty);
            let cmp = self.tmp_name();
            let pred = if is_min {
                if signed { "slt" } else { "ult" }
            } else if signed {
                "sgt"
            } else {
                "ugt"
            };
            self.line(&format!("  {} = icmp {} {} {}, {}", cmp, pred, ity, l, r));
            let reg = self.tmp_name();
            self.line(&format!("  {} = select i1 {}, {} {}, {} {}", reg, cmp, ity, l, ity, r));
            format!("{} {}", ity, reg)
        }
    }

    /// Get the real `i8*` out of a `Str`-typed expression. A `Str` value's
    /// `emit_expr` result *is* the raw string pointer (tagged for a literal,
    /// bare for a load/call), so this is just a tag-stripping pass-through.
    ///
    /// Deliberately does *not* release here, unlike an earlier version of
    /// this function -- every caller still needs to release whatever
    /// `emit_expr` left it owning (a borrowed read's extra retain, or a
    /// fresh construction's sole reference; see `rc.rs`'s module doc
    /// comment) once it's truly done reading through the returned pointer,
    /// but releasing *inside* this function, before the caller has actually
    /// used it, is a real use-after-free for a fresh (mortal, refcount-1)
    /// string: `Codegen::emit_str_concat` calls this once per argument and
    /// then reads *both* returned pointers afterward (`strlen`, then
    /// `strcpy`/`strcat`) -- confirmed via a real, wrong runtime result
    /// (`concat(f"a{1}", f"b{2}")` produced `"b2b2"` instead of `"a1b2"`,
    /// its first argument's freshly-`star_rc_alloc`'d buffer freed the
    /// instant its length was taken, then reused by the very next
    /// allocation before `strcpy` ever read it). Each caller below now
    /// releases explicitly, after its own last use of the pointer.
    pub(super) fn emit_raw_str_ptr(&mut self, e: &TypedExpr) -> String {
        let val = self.emit_expr(e);
        self.untag(&val, &Ty::Str)
    }

    /// `read_line() -> str`: reads one line from stdin a character at a time
    /// via `getchar`, stopping at `\n` (discarded) or EOF, into a
    /// fixed-capacity buffer -- the same fixed-capacity-buffer convention
    /// `ARENA_CAPACITY`/`FRAME_BUF_SIZE` already use elsewhere in this
    /// codegen, chosen over a `realloc`-growable buffer for the same reason:
    /// no dynamic growth machinery to get wrong. The buffer is allocated via
    /// `star_rc_alloc` (refcount 1, no release callback) so it's a fresh,
    /// already-owned `Str` value exactly like `emit_str_concat`'s result --
    /// no extra retain needed at this call site, only a release once its
    /// owner goes out of scope (see `rc.rs`).
    pub(super) fn emit_read_line(&mut self) -> String {
        // Capacity includes the trailing NUL, so at most `CAP - 1` characters
        // of input are kept; anything beyond that is left unread on stdin
        // (matches `frame:`'s bounded-buffer-over-unbounded-growth choice).
        const CAP: u64 = 1024;
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* null)", buf, CAP));
        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));

        let cond_label = self.block_label("read_line_cond");
        let body_label = self.block_label("read_line_body");
        let store_label = self.block_label("read_line_store");
        let end_label = self.block_label("read_line_end");

        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&cond_label);
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
        let has_room = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", has_room, i_reg, CAP - 1));
        self.line(&format!("  br i1 {}, label %{}, label %{}", has_room, body_label, end_label));

        self.open_block(&body_label);
        let c = self.tmp_name();
        self.line(&format!("  {} = call i32 @getchar()", c));
        let is_eof = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, -1", is_eof, c));
        let is_nl = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 10", is_nl, c));
        let stop = self.tmp_name();
        self.line(&format!("  {} = or i1 {}, {}", stop, is_eof, is_nl));
        self.line(&format!("  br i1 {}, label %{}, label %{}", stop, end_label, store_label));

        self.open_block(&store_label);
        let dest = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", dest, buf, i_reg));
        let c8 = self.tmp_name();
        self.line(&format!("  {} = trunc i32 {} to i8", c8, c));
        self.line(&format!("  store i8 {}, i8* {}", c8, dest));
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&end_label);
        let final_i = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", final_i, i_ptr));
        let nul = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", nul, buf, final_i));
        self.line(&format!("  store i8 0, i8* {}", nul));

        buf
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
        // `raw` is done being read -- release whatever `emit_raw_str_ptr`
        // left us owning (see its own doc comment for why this can't happen
        // inside that function itself).
        self.line(&format!("  call void @star_rc_release(i8* {})", raw));
        format!("i32 {}", reg)
    }

    /// `s[idx] -> i32`: a bounds-checked byte read, yielding the byte's
    /// value (0-255, `zext`ed rather than `sext`ed so a high-bit-set byte
    /// reads as e.g. 200, not -56) rather than a length-1 substring -- see
    /// `TypedExpr::StrIndex`'s doc comment. `null` (the zero value a `str`
    /// field/binding can hold, e.g. a struct field never assigned) and an
    /// out-of-range `idx` both yield `0`, mirroring `List<T>`'s "safe
    /// null-equivalent" OOB-read convention (`Codegen::emit_list_index`)
    /// rather than crashing on a null `strlen`/`getelementptr`. A negative
    /// `idx` is safe for the same reason `emit_list_index` is: the unsigned
    /// compare against `len` sign-extends/wraps it to a huge value, so it
    /// always fails the bounds check rather than reading before the buffer.
    pub(super) fn emit_str_index(&mut self, base: &TypedExpr, index: &TypedExpr) -> String {
        let raw = self.emit_raw_str_ptr(base);

        let idx_val = self.emit_expr(index);
        let idx_bare = self.untag(&idx_val, &Ty::Int);
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, idx_bare));

        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, raw));
        let chk_label = self.block_label("str_idx_chk");
        let ok_label = self.block_label("str_idx_ok");
        let oob_label = self.block_label("str_idx_oob");
        let end_label = self.block_label("str_idx_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, oob_label, chk_label));

        self.open_block(&chk_label);
        let len32 = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", len32, raw));
        let len64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", len64, len32));
        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, len64));
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, ok_label, oob_label));

        self.open_block(&ok_label);
        let byte_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", byte_ptr, raw, idx64));
        let byte = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", byte, byte_ptr));
        let byte32 = self.tmp_name();
        self.line(&format!("  {} = zext i8 {} to i32", byte32, byte));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&oob_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!("  {} = phi i32 [ {}, %{} ], [ 0, %{} ]", result, byte32, ok_label, oob_label));
        // `raw` is done being read on every path that reaches here -- release
        // whatever `emit_raw_str_ptr` left us owning (see its own doc comment
        // for why this can't happen inside that function itself). Safe even
        // on the null path: `star_rc_release` no-ops on a null pointer.
        self.line(&format!("  call void @star_rc_release(i8* {})", raw));
        format!("i32 {}", result)
    }

    /// `chr(b) -> str`: a fresh, owned length-1 string holding byte `b`
    /// (truncated to `i8`, so e.g. `chr(321)` wraps to `chr(65)` = `"A"` --
    /// same "no runtime error for a scalar out of its usual range" stance
    /// `List<T>`'s zero-value OOB reads take). Allocates a 2-byte buffer
    /// (byte + null terminator) via `star_rc_alloc` with no release thunk,
    /// same shape `emit_ptr_to_str`'s owned-copy allocation uses -- a
    /// `str`'s only heap content is its own byte buffer, nothing further to
    /// release when it's freed.
    pub(super) fn emit_chr(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("chr(..) expects 1 argument", Span::dummy());
            return "i8* null".into();
        };
        let val = self.emit_expr(arg);
        let bare = self.untag(&val, &Ty::Int);
        let byte = self.tmp_name();
        self.line(&format!("  {} = trunc i32 {} to i8", byte, bare));
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 2, i8* null)", buf));
        self.line(&format!("  store i8 {}, i8* {}", byte, buf));
        let nul_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 1", nul_ptr, buf));
        self.line(&format!("  store i8 0, i8* {}", nul_ptr));
        format!("i8* {}", buf)
    }

    /// `ord(s) -> i32`: `s[0]` -- the first byte's value, or `0` for a
    /// `null`/empty `str` (same convention `emit_str_index` uses; this is
    /// deliberately just that logic evaluated at a fixed index 0 rather
    /// than a separate implementation).
    pub(super) fn emit_ord(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("ord(..) expects 1 argument", Span::dummy());
            return "i32 0".into();
        };
        let raw = self.emit_raw_str_ptr(arg);
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, raw));
        let ok_label = self.block_label("ord_ok");
        let oob_label = self.block_label("ord_oob");
        let end_label = self.block_label("ord_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, oob_label, ok_label));

        self.open_block(&ok_label);
        let len32 = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", len32, raw));
        let has_len = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i32 {}, 0", has_len, len32));
        let read_label = self.block_label("ord_read");
        self.line(&format!("  br i1 {}, label %{}, label %{}", has_len, read_label, oob_label));

        self.open_block(&read_label);
        let byte = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", byte, raw));
        let byte32 = self.tmp_name();
        self.line(&format!("  {} = zext i8 {} to i32", byte32, byte));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&oob_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!("  {} = phi i32 [ {}, %{} ], [ 0, %{} ]", result, byte32, read_label, oob_label));
        // `raw` is done being read on every path that reaches here -- release
        // whatever `emit_raw_str_ptr` left us owning. Safe even on the null
        // path: `star_rc_release` no-ops on a null pointer.
        self.line(&format!("  call void @star_rc_release(i8* {})", raw));
        format!("i32 {}", result)
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
        // `a`/`b` are done being read -- release whatever `emit_raw_str_ptr`
        // left us owning for each (see its own doc comment for why this
        // can't happen inside that function itself, before `strcpy`/`strcat`
        // above have actually read through the pointer).
        self.line(&format!("  call void @star_rc_release(i8* {})", a));
        self.line(&format!("  call void @star_rc_release(i8* {})", b));
        buf
    }

    /// `null_ptr() -> ptr`: the constant `i8* null`.
    pub(super) fn emit_null_ptr(&mut self) -> String {
        "i8* null".into()
    }

    /// `is_null(p: ptr) -> bool`.
    pub(super) fn emit_is_null(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("is_null(..) expects 1 argument", Span::dummy());
            return "i1 false".into();
        };
        let val = self.emit_expr(arg);
        let p = self.untag(&val, &Ty::Ptr);
        let reg = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", reg, p));
        format!("i1 {}", reg)
    }

    /// `ptr_to_str(p: ptr) -> str`: copies a NUL-terminated C string at `p`
    /// into a fresh, properly RC'd Star `str` (`strlen` + `star_rc_alloc` +
    /// `strcpy`, mirroring `emit_str_concat`'s buffer-allocation pattern
    /// above). The safe bridge for a `char*` handed back by an `extern "C"`
    /// function -- `p` itself has no RC header (see `Ty::Ptr`'s doc comment
    /// in `crate::types`), so it must never be treated as a Star `Str`
    /// directly.
    ///
    /// Aborts loudly (rather than segfaulting) on a null `p`, the same
    /// "check first, abort with a message" convention every other builtin
    /// that dereferences a `ptr` handle already follows (`file_io.rs`'s
    /// `abort_if_null_handle`, `net.rs`'s `abort_if_null_socket`) -- an
    /// earlier version of this function had no such guard and called
    /// `strlen` directly on `p`, undefined behavior (a null-pointer
    /// dereference) whenever `p` is null. Confirmed via a real, unguarded
    /// segfault building and running `ptr_to_str(null_ptr())` -- a real,
    /// realistic call shape (`extern "C"` functions commonly return a null
    /// `char*` to signal "not found"/failure, exactly the `strstr` shape
    /// `examples/extern_ffi.star` demonstrates checking with `is_null`
    /// *before* calling `ptr_to_str` -- but nothing enforced that check
    /// actually happens first).
    pub(super) fn emit_ptr_to_str(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("ptr_to_str(..) expects 1 argument", Span::dummy());
            return "i8* null".into();
        };
        let val = self.emit_expr(arg);
        let p = self.untag(&val, &Ty::Ptr);
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, p));
        let fail_label = self.block_label("ptr_to_str_null");
        let ok_label = self.block_label("ptr_to_str_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, fail_label, ok_label));

        self.open_block(&fail_label);
        self.emit_abort_with_message("star runtime error: ptr_to_str(..) called with a null ptr\n");

        self.open_block(&ok_label);
        let len = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", len, p));
        let total = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", total, len));
        let total64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", total64, total));
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* null)", buf, total64));
        self.line(&format!("  call i8* @strcpy(i8* {}, i8* {})", buf, p));
        format!("i8* {}", buf)
    }
}
