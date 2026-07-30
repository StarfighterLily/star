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
            // A `str` hole's pointer must stay valid until the `printf` call
            // below actually reads through it -- releasing it here in the
            // loop, as this used to, frees it while `arg_vals` still holds
            // the now-dangling pointer, and nothing stops some other
            // allocation later in this same function from reusing that
            // exact address before `printf` reads it. Same bug class
            // `emit_str_concat`'s own doc comment (this file, below)
            // documents and fixes for `concat`'s two arguments, and the
            // sibling `TypedExpr::FStr` codegen path (`expr.rs`) has the
            // identical fix. Collected here and released only after
            // `printf` runs.
            let mut str_hole_releases: Vec<String> = Vec::new();
            for part in parts {
                match part {
                    TypedFStrExpr::Literal(lit) => {
                        fmt_str.push_str(&lit.replace("%", "%%"));
                    }
                    TypedFStrExpr::Expr(e) => {
                        let val = self.emit_expr(e);
                        let ty = self.expr_ty(e);
                        // A builtin vector/matrix aggregate (`Vec2`/`Vec3`/
                        // `Vec4`/`Quat`/`Color`/`Mat2`/`Mat3`/`Mat4`) has no
                        // single scalar format specifier -- unlike every
                        // other arm here it expands into several `%f` holes
                        // plus literal constructor-syntax text, so it's
                        // handled up front and `continue`s past the
                        // one-hole-per-value logic below entirely (see
                        // `emit_agg_fstring_lanes`'s doc comment).
                        if ty.is_vec() || ty.is_mat() {
                            let bare_val = self.untag(&val, &ty);
                            let (frag, lanes) = self.emit_agg_fstring_lanes(&ty, &bare_val);
                            fmt_str.push_str(&frag);
                            for lane in lanes {
                                arg_vals.push((lane, Ty::Float));
                            }
                            continue;
                        }
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
                            // A bare unsigned `i{N}` register -- see
                            // `Ty::BitField`'s doc comment.
                            Ty::BitField(64) => { fmt_str.push_str("%llu"); }
                            Ty::BitField(_) => { fmt_str.push_str("%u"); }
                            // A bare unsigned `i64` bitmask -- see
                            // `Ty::Flags`'s doc comment.
                            Ty::Flags(_) => { fmt_str.push_str("%llu"); }
                            // A bare unsigned `i32` packed color -- see
                            // `Ty::Color32`'s doc comment. Without this arm
                            // it fell through to the `%p` catch-all below,
                            // tagging a plain `i32` register as a pointer
                            // vararg -- the same `clang`/LLVM vararg
                            // type-mismatch bug class round 4 fixed for
                            // `i64`/`Wrapping`/`BitField`/`Flags`, just never
                            // ported to this round's new bare-scalar types.
                            Ty::Color32 => { fmt_str.push_str("%u"); }
                            // A bare unsigned `u8` palette slot -- see
                            // `Ty::PaletteIndex`'s doc comment. Same
                            // reasoning as `Ty::Color32` just above.
                            Ty::PaletteIndex => { fmt_str.push_str("%u"); }
                            // A fieldless enum's `i32` discriminant has no
                            // format specifier of its own, printed as its
                            // variant's *name* instead (`Direction::Down`
                            // prints as `Down`) -- same `%s` treatment as
                            // `Bool` just below. Previously missing from
                            // this table entirely, so the discriminant fell
                            // through to the `%p` catch-all: a plausible-
                            // looking but nonsensical zero-padded 16-hex-
                            // digit "address" instead of a crash or type
                            // error (`projects/snake/NOTES.md` section 1.5;
                            // the same bug class bug-hunting rounds 5/6 fixed
                            // for `Color32`/`PaletteIndex`/every aggregate
                            // vector/matrix type just above, never ported to
                            // plain user `enum`s).
                            Ty::Enum(_) => { fmt_str.push_str("%s"); }
                            // A bare `i8*` object pointer (RC'd or, for
                            // `Ptr`, opaque foreign) -- see each type's own
                            // `Ty` doc comment. `%p` is ABI-safe here: the
                            // vararg genuinely *is* a pointer, unlike the
                            // aggregate-by-value types in the arm below.
                            // There's no dedicated "print the contents"
                            // format for any of these (that would need a
                            // recursive per-element/per-field formatter this
                            // compiler doesn't have) -- this deliberately
                            // prints the raw address instead, the same
                            // "opaque handle" debug convention `Ty::Ptr`
                            // already established.
                            Ty::Palette | Ty::List(_) | Ty::Map(..) | Ty::Set(_) | Ty::Table(_) | Ty::Bytes | Ty::Ptr => {
                                fmt_str.push_str("%p");
                            }
                            // Struct/tuple/array/`Ring`/closure/`GenRef`/
                            // `Handle` values are rejected before codegen by
                            // `Checker::infer_expr`'s `Expr::FStr` arm (see
                            // `Ty::is_fstring_unprintable`'s doc comment) --
                            // each lowers to an LLVM aggregate passed *by
                            // value* (`%Name`/`{ .. }`/`[N x T]`/`%GenRef`/
                            // `{ i8*, i8* }`, see `Codegen::llvm_ty`), so
                            // tagging one as a vararg `%p` pointer would be a
                            // C-ABI type mismatch -- the exact
                            // fieldless-enum-prints-as-garbage-hex bug class
                            // `Ty::Enum`'s own `%s` arm above fixed. No
                            // wildcard arm on this match at all: a future
                            // `Ty` variant that isn't sorted into one of the
                            // two buckets above fails to compile here rather
                            // than silently falling through to `%p`.
                            Ty::Named(_) | Ty::GenRef(_) | Ty::Handle(_) | Ty::Tuple(_) | Ty::Array(_, _) | Ty::Ring(_, _) | Ty::Closure(..) => {
                                unreachable!("f-string interpolation of {:?} should have been rejected by the checker", ty);
                            }
                            // Never actually reached as `ty`: the vector/
                            // matrix aggregates are filtered out (and lowered
                            // through `emit_agg_fstring_lanes` instead) by the
                            // `is_vec()`/`is_mat()` `continue` above, and
                            // `Fixed` is substituted for `Ty::F64` just above
                            // this match -- both listed here only so this
                            // match has no wildcard arm (see the comment on
                            // the aggregate-value arm above for why that
                            // matters).
                            Ty::Vec2 | Ty::Vec3 | Ty::Vec4 | Ty::Mat2 | Ty::Mat3 | Ty::Mat4 | Ty::Quat | Ty::Color | Ty::Fixed(_, _) => {
                                unreachable!("{:?} is filtered out before this match is ever reached", ty);
                            }
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
                            // unconditional and always safe). Deferred until
                            // after `printf` actually reads `bare_val` below
                            // -- see `str_hole_releases`'s doc comment above.
                            str_hole_releases.push(bare_val.clone());
                            bare_val
                        } else if matches!(ty, Ty::Bool) {
                            self.emit_bool_str(&bare_val)
                        } else if let Ty::Enum(enum_name) = &ty {
                            self.emit_enum_variant_name(enum_name, &bare_val)
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
                } else if matches!(ty, Ty::Enum(_)) {
                    // `emit_enum_variant_name` already turned this into an
                    // `i8*` (a variant-name string pointer), not the bare
                    // `i32` `llvm_ty(Ty::Enum(_))` would tag it as -- same
                    // reasoning as the `Bool` arm just above.
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
                } else if matches!(ty, Ty::U8 | Ty::U16 | Ty::PaletteIndex) {
                    // `PaletteIndex` lowers to a bare `u8` (see its own `Ty`
                    // doc comment) -- same C variadic-promotion rule as
                    // `U8`/`U16` just above.
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
                } else if let Ty::BitField(n) = ty {
                    // Same C variadic-promotion rule as the `U8`/`U16` arm
                    // above -- a register narrower than 32 bits needs
                    // zero-extending up to the `int` slot `%u` reads.
                    if *n < 32 {
                        let widened = self.tmp_name();
                        self.line(&format!("  {} = zext i{} {} to i32", widened, n, val));
                        call_args.push(format!("i32 {}", widened));
                    } else {
                        call_args.push(format!("i{} {}", n, val));
                    }
                } else {
                    call_args.push(format!("{} {}", self.llvm_ty(ty), val));
                }
            }
            self.line(&format!("  call i32 (i8*, ...) @printf({})", call_args.join(", ")));
            // Now that `printf` above has actually read every `str` hole's
            // bytes, it's safe to release them -- see
            // `str_hole_releases`'s doc comment above for why this can't
            // happen any earlier.
            for held in &str_hole_releases {
                self.line(&format!("  call void @star_rc_release(i8* {})", held));
            }
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
            self.line(&format!("  call i32 (i8*, ...) @printf(i8* {})", loaded));
            // Same reasoning as `emit_raw_str_ptr`/the f-string branch
            // above: release whatever `emit_expr(arg)` left us owning --
            // only now that `printf` above has actually read through
            // `loaded`. This used to release *before* the `printf` call
            // that reads it -- a real use-after-free whenever `arg` is a
            // fresh value (e.g. `println(some_fn_call())` where
            // `some_fn_call` returns a freshly-built `str`): nothing stops
            // a later allocation in the same program from reusing that
            // exact freed address before `printf` gets to read it,
            // corrupting the printed bytes. This is the general "release
            // whatever's owned" call site `emit_str_concat`'s own doc
            // comment (below) already documents and fixes this exact bug
            // class for; this call site never got the same fix.
            if matches!(self.expr_ty(arg), Ty::Str) {
                self.line(&format!("  call void @star_rc_release(i8* {})", loaded));
            }
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

    /// Select between a fieldless enum's variant-name string constants
    /// based on a bare `i32` discriminant register, returning an `i8*`
    /// suitable for a `%s` format hole -- `emit_bool_str` above, generalized
    /// from a fixed 2-way `true`/`false` choice to an N-way one over
    /// `enum_variants[enum_name]` (the same variant-index table
    /// `enum_variant_index`/`EnumVariant` literal codegen already builds
    /// off of, so this always agrees with how a variant's own tag was
    /// assigned). A `select` chain rather than a `switch`+block+`phi` since
    /// `printf`'s varargs already need every hole's value pre-computed as a
    /// single register in a straight line, and real fieldless enums have few
    /// enough variants that an N-way `select` chain is in no danger of
    /// being a real performance concern. The final (highest-index) variant
    /// is the chain's base case: assumes the discriminant is always one of
    /// the enum's own valid tags, which the type system guarantees for
    /// anything actually typed `Ty::Enum(enum_name)`.
    pub(super) fn emit_enum_variant_name(&mut self, enum_name: &str, discriminant: &str) -> String {
        let variants = self.enum_variants.get(enum_name).cloned().unwrap_or_default();
        let Some((last, rest)) = variants.split_last() else {
            // No known variant table -- shouldn't happen for a well-typed
            // fieldless enum, but emit a harmless placeholder rather than a
            // malformed `select` chain over zero arms.
            let g = self.global_name();
            self.global_defs.push(format!("{} = private unnamed_addr constant [2 x i8] c\"?\\00\"", g));
            let ptr = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds [2 x i8], [2 x i8]* {}, i64 0, i64 0", ptr, g));
            return ptr;
        };
        let variant_ptr = |cg: &mut Self, name: &str| -> String {
            let g = cg.global_name();
            cg.global_defs.push(format!("{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"", g, name.len() + 1, name));
            let ptr = cg.tmp_name();
            cg.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", ptr, name.len() + 1, name.len() + 1, g, ));
            ptr
        };
        let mut sel = variant_ptr(self, last);
        for (idx, name) in rest.iter().enumerate().rev() {
            let ptr = variant_ptr(self, name);
            let cmp = self.tmp_name();
            self.line(&format!("  {} = icmp eq i32 {}, {}", cmp, discriminant, idx));
            let next = self.tmp_name();
            self.line(&format!("  {} = select i1 {}, i8* {}, i8* {}", next, cmp, ptr, sel));
            sel = next;
        }
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
        // Tagged `"i8* <reg>"`, matching every other builtin's return
        // convention (`emit_str_join` right below already does this) --
        // this used to return a bare `buf`, which broke
        // `Codegen::emit_trailing_if_value`'s `rsplit_once(' ')` type
        // recovery the exact same way the sibling `TypedExpr::FStr` bug did
        // (`expr.rs`, see that fix's own comment) -- found via the same
        // Nova disassembler work, once its hex-formatting helpers were
        // rewritten to use `concat` instead of f-strings as a workaround for
        // *that* bug and immediately hit this one instead.
        format!("i8* {}", buf)
    }

    /// Normalizes a possibly-`null` `str` value (`Ty::Str`'s zero value, see
    /// `Codegen::zero_value` -- a struct field/local `str` never assigned
    /// still holds this) to a real, non-null pointer at the shared `@str.
    /// empty` global (see its own declaration comment in `Codegen::
    /// emit_builtins`) via a single `select`, so every `str_*` builtin below
    /// can pass the result straight to `strlen`/`strstr`/`strncmp`/`strcmp`
    /// without a per-call-site null branch -- all four are undefined
    /// behavior on a genuine null pointer, the same class of bug
    /// `emit_ptr_to_str`'s doc comment already documents for `strlen`.
    /// `raw`'s own ownership is untouched: the caller still releases exactly
    /// the value `emit_raw_str_ptr` handed back (releasing is a no-op on
    /// `null`, so this is safe regardless of which operand `select` picked).
    pub(super) fn emit_str_or_empty(&mut self, raw: &str) -> String {
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, raw));
        let norm = self.tmp_name();
        self.line(&format!(
            "  {} = select i1 {}, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* {}",
            norm, is_null, raw
        ));
        norm
    }

    /// `true` iff `byte_reg` (an `i8`) is ASCII whitespace (space/tab/
    /// newline/CR/vertical-tab/form-feed) -- the same six bytes C's own
    /// `isspace` recognizes in the "C" locale, used by `emit_str_trim`.
    fn emit_is_ascii_ws(&mut self, byte_reg: &str) -> String {
        let mut acc: Option<String> = None;
        for b in [32, 9, 10, 13, 11, 12] {
            let eq = self.tmp_name();
            self.line(&format!("  {} = icmp eq i8 {}, {}", eq, byte_reg, b));
            acc = Some(match acc {
                None => eq,
                Some(prev) => {
                    let combined = self.tmp_name();
                    self.line(&format!("  {} = or i1 {}, {}", combined, prev, eq));
                    combined
                }
            });
        }
        acc.expect("six literal iterations always produce a value")
    }

    /// `str_contains(s, needle) -> bool`: `true` iff `needle` occurs anywhere
    /// in `s` (an empty `needle` always matches, mirroring `strstr`'s own C
    /// semantics -- every string "contains" the empty string).
    pub(super) fn emit_str_contains(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("str_contains(..) expects 2 arguments", Span::dummy());
            return "i1 false".into();
        }
        let s_raw = self.emit_raw_str_ptr(&args[0]);
        let n_raw = self.emit_raw_str_ptr(&args[1]);
        let s = self.emit_str_or_empty(&s_raw);
        let n = self.emit_str_or_empty(&n_raw);
        let found = self.tmp_name();
        self.line(&format!("  {} = call i8* @strstr(i8* {}, i8* {})", found, s, n));
        let result = self.tmp_name();
        self.line(&format!("  {} = icmp ne i8* {}, null", result, found));
        self.line(&format!("  call void @star_rc_release(i8* {})", s_raw));
        self.line(&format!("  call void @star_rc_release(i8* {})", n_raw));
        format!("i1 {}", result)
    }

    /// `str_starts_with(s, prefix) -> bool`. An empty `prefix` always
    /// matches: `strncmp` comparing zero bytes trivially returns equal.
    pub(super) fn emit_str_starts_with(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("str_starts_with(..) expects 2 arguments", Span::dummy());
            return "i1 false".into();
        }
        let s_raw = self.emit_raw_str_ptr(&args[0]);
        let p_raw = self.emit_raw_str_ptr(&args[1]);
        let s = self.emit_str_or_empty(&s_raw);
        let p = self.emit_str_or_empty(&p_raw);
        let plen32 = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", plen32, p));
        let plen64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", plen64, plen32));
        let cmp = self.tmp_name();
        self.line(&format!("  {} = call i32 @strncmp(i8* {}, i8* {}, i64 {})", cmp, s, p, plen64));
        let result = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 0", result, cmp));
        self.line(&format!("  call void @star_rc_release(i8* {})", s_raw));
        self.line(&format!("  call void @star_rc_release(i8* {})", p_raw));
        format!("i1 {}", result)
    }

    /// `str_ends_with(s, suffix) -> bool`. A `suffix` longer than `s` never
    /// matches (checked up front, so the tail-offset computation below never
    /// goes negative); an empty `suffix` always matches for the same reason
    /// `str_starts_with`'s empty `prefix` does.
    pub(super) fn emit_str_ends_with(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("str_ends_with(..) expects 2 arguments", Span::dummy());
            return "i1 false".into();
        }
        let s_raw = self.emit_raw_str_ptr(&args[0]);
        let suf_raw = self.emit_raw_str_ptr(&args[1]);
        let s = self.emit_str_or_empty(&s_raw);
        let suf = self.emit_str_or_empty(&suf_raw);
        let slen32 = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", slen32, s));
        let suflen32 = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", suflen32, suf));
        let too_long = self.tmp_name();
        self.line(&format!("  {} = icmp ugt i32 {}, {}", too_long, suflen32, slen32));
        let cmp_label = self.block_label("ends_with_cmp");
        let false_label = self.block_label("ends_with_false");
        let end_label = self.block_label("ends_with_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", too_long, false_label, cmp_label));

        self.open_block(&cmp_label);
        let offset32 = self.tmp_name();
        self.line(&format!("  {} = sub i32 {}, {}", offset32, slen32, suflen32));
        let offset64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", offset64, offset32));
        let tail = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", tail, s, offset64));
        let cmp = self.tmp_name();
        self.line(&format!("  {} = call i32 @strcmp(i8* {}, i8* {})", cmp, tail, suf));
        let res_cmp = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 0", res_cmp, cmp));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&false_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!("  {} = phi i1 [ {}, %{} ], [ false, %{} ]", result, res_cmp, cmp_label, false_label));
        self.line(&format!("  call void @star_rc_release(i8* {})", s_raw));
        self.line(&format!("  call void @star_rc_release(i8* {})", suf_raw));
        format!("i1 {}", result)
    }

    /// `str_index_of(s, needle) -> int`: the byte offset of `needle`'s first
    /// occurrence in `s`, or `-1` if it doesn't occur at all (an empty
    /// `needle` always matches at offset `0`, `strstr`'s own convention).
    pub(super) fn emit_str_index_of(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("str_index_of(..) expects 2 arguments", Span::dummy());
            return "i32 -1".into();
        }
        let s_raw = self.emit_raw_str_ptr(&args[0]);
        let n_raw = self.emit_raw_str_ptr(&args[1]);
        let s = self.emit_str_or_empty(&s_raw);
        let n = self.emit_str_or_empty(&n_raw);
        let found = self.tmp_name();
        self.line(&format!("  {} = call i8* @strstr(i8* {}, i8* {})", found, s, n));
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, found));
        let found_label = self.block_label("index_of_found");
        let notfound_label = self.block_label("index_of_notfound");
        let end_label = self.block_label("index_of_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, notfound_label, found_label));

        self.open_block(&found_label);
        let found64 = self.tmp_name();
        self.line(&format!("  {} = ptrtoint i8* {} to i64", found64, found));
        let s64 = self.tmp_name();
        self.line(&format!("  {} = ptrtoint i8* {} to i64", s64, s));
        let diff64 = self.tmp_name();
        self.line(&format!("  {} = sub i64 {}, {}", diff64, found64, s64));
        let diff32 = self.tmp_name();
        self.line(&format!("  {} = trunc i64 {} to i32", diff32, diff64));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&notfound_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!("  {} = phi i32 [ {}, %{} ], [ -1, %{} ]", result, diff32, found_label, notfound_label));
        self.line(&format!("  call void @star_rc_release(i8* {})", s_raw));
        self.line(&format!("  call void @star_rc_release(i8* {})", n_raw));
        format!("i32 {}", result)
    }

    /// `str_trim(s) -> str`: a fresh, owned copy of `s` with leading/trailing
    /// ASCII whitespace (`emit_is_ascii_ws`'s six bytes) removed. An
    /// all-whitespace (or empty) `s` yields an empty `str`, not `null` --
    /// same "a fresh empty allocation, not the bare zero value" convention
    /// `Codegen::zero_value_rc` documents for `List<str>::pop()`/`s[oob]`.
    pub(super) fn emit_str_trim(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("str_trim(..) expects 1 argument", Span::dummy());
            return "i8* null".into();
        };
        let raw = self.emit_raw_str_ptr(arg);
        let s = self.emit_str_or_empty(&raw);
        let len32 = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", len32, s));
        let len64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", len64, len32));

        let start_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", start_ptr));
        self.line(&format!("  store i64 0, i64* {}", start_ptr));

        let start_cond = self.block_label("trim_start_cond");
        let start_body = self.block_label("trim_start_body");
        let start_incr = self.block_label("trim_start_incr");
        let start_done = self.block_label("trim_start_done");
        self.line(&format!("  br label %{}", start_cond));

        self.open_block(&start_cond);
        let st = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", st, start_ptr));
        let in_range = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", in_range, st, len64));
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_range, start_body, start_done));

        self.open_block(&start_body);
        let cptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", cptr, s, st));
        let c = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", c, cptr));
        let is_ws = self.emit_is_ascii_ws(&c);
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_ws, start_incr, start_done));

        self.open_block(&start_incr);
        let st2 = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", st2, st));
        self.line(&format!("  store i64 {}, i64* {}", st2, start_ptr));
        self.line(&format!("  br label %{}", start_cond));

        self.open_block(&start_done);
        let start_final = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", start_final, start_ptr));

        let end_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", end_ptr));
        self.line(&format!("  store i64 {}, i64* {}", len64, end_ptr));

        let end_cond = self.block_label("trim_end_cond");
        let end_body = self.block_label("trim_end_body");
        let end_decr = self.block_label("trim_end_decr");
        let end_done = self.block_label("trim_end_done");
        self.line(&format!("  br label %{}", end_cond));

        self.open_block(&end_cond);
        let en = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", en, end_ptr));
        let above_start = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i64 {}, {}", above_start, en, start_final));
        self.line(&format!("  br i1 {}, label %{}, label %{}", above_start, end_body, end_done));

        self.open_block(&end_body);
        let idx = self.tmp_name();
        self.line(&format!("  {} = sub i64 {}, 1", idx, en));
        let cptr2 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", cptr2, s, idx));
        let c2 = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", c2, cptr2));
        let is_ws2 = self.emit_is_ascii_ws(&c2);
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_ws2, end_decr, end_done));

        self.open_block(&end_decr);
        self.line(&format!("  store i64 {}, i64* {}", idx, end_ptr));
        self.line(&format!("  br label %{}", end_cond));

        self.open_block(&end_done);
        let end_final = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", end_final, end_ptr));

        let seg_len = self.tmp_name();
        self.line(&format!("  {} = sub i64 {}, {}", seg_len, end_final, start_final));
        let total = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", total, seg_len));
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* null)", buf, total));
        let src = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", src, s, start_final));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", buf, src, seg_len));
        let nul = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", nul, buf, seg_len));
        self.line(&format!("  store i8 0, i8* {}", nul));
        self.line(&format!("  call void @star_rc_release(i8* {})", raw));
        format!("i8* {}", buf)
    }

    /// `str_replace(s, old, new) -> str`: every non-overlapping occurrence of
    /// `old` in `s` replaced with `new`, scanned left to right. An empty
    /// `old` returns an unmodified copy of `s` rather than attempting to
    /// "replace between every character" (the behavior an unguarded
    /// `strstr(s, "")` scan would otherwise loop on forever, since it always
    /// matches at the current position without advancing) -- a deliberate,
    /// documented scope cut, the same "safe, not a footgun" stance this
    /// codebase already takes for other builtins' degenerate inputs.
    pub(super) fn emit_str_replace(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 3 {
            self.err("str_replace(..) expects 3 arguments", Span::dummy());
            return "i8* null".into();
        }
        let s_raw = self.emit_raw_str_ptr(&args[0]);
        let old_raw = self.emit_raw_str_ptr(&args[1]);
        let new_raw = self.emit_raw_str_ptr(&args[2]);
        let s = self.emit_str_or_empty(&s_raw);
        let old = self.emit_str_or_empty(&old_raw);
        let new = self.emit_str_or_empty(&new_raw);

        let old_len32 = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", old_len32, old));
        let old_len64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", old_len64, old_len32));
        let is_old_empty = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, 0", is_old_empty, old_len64));

        let empty_old_label = self.block_label("replace_empty_old");
        let real_label = self.block_label("replace_real");
        let done_label = self.block_label("replace_done");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_old_empty, empty_old_label, real_label));

        self.open_block(&empty_old_label);
        let s_len32 = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", s_len32, s));
        let s_len64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", s_len64, s_len32));
        let total0 = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", total0, s_len64));
        let buf0 = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* null)", buf0, total0));
        self.line(&format!("  call i8* @strcpy(i8* {}, i8* {})", buf0, s));
        self.line(&format!("  br label %{}", done_label));

        self.open_block(&real_label);
        let new_len32 = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", new_len32, new));
        let new_len64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", new_len64, new_len32));

        // Pass 1: count non-overlapping matches.
        let count_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", count_ptr));
        self.line(&format!("  store i64 0, i64* {}", count_ptr));
        let cur_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i8*", cur_ptr));
        self.line(&format!("  store i8* {}, i8** {}", s, cur_ptr));

        let count_cond = self.block_label("replace_count_cond");
        let count_body = self.block_label("replace_count_body");
        let count_done = self.block_label("replace_count_done");
        self.line(&format!("  br label %{}", count_cond));

        self.open_block(&count_cond);
        let cur = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", cur, cur_ptr));
        let found = self.tmp_name();
        self.line(&format!("  {} = call i8* @strstr(i8* {}, i8* {})", found, cur, old));
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, found));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, count_done, count_body));

        self.open_block(&count_body);
        let cnt = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", cnt, count_ptr));
        let cnt2 = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", cnt2, cnt));
        self.line(&format!("  store i64 {}, i64* {}", cnt2, count_ptr));
        let newcur = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", newcur, found, old_len64));
        self.line(&format!("  store i8* {}, i8** {}", newcur, cur_ptr));
        self.line(&format!("  br label %{}", count_cond));

        self.open_block(&count_done);
        let final_count = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", final_count, count_ptr));

        let s_len32b = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", s_len32b, s));
        let s_len64b = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", s_len64b, s_len32b));
        let delta = self.tmp_name();
        self.line(&format!("  {} = sub i64 {}, {}", delta, new_len64, old_len64));
        let extra = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", extra, final_count, delta));
        let total_len = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, {}", total_len, s_len64b, extra));
        let total_alloc = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", total_alloc, total_len));
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* null)", buf, total_alloc));

        // Pass 2: build the output, copying each pre-match segment plus
        // `new` in place of every match, then the unmatched tail.
        let cur2_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i8*", cur2_ptr));
        self.line(&format!("  store i8* {}, i8** {}", s, cur2_ptr));
        let write_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i8*", write_ptr));
        self.line(&format!("  store i8* {}, i8** {}", buf, write_ptr));

        let build_cond = self.block_label("replace_build_cond");
        let build_body = self.block_label("replace_build_body");
        let build_done = self.block_label("replace_build_done");
        self.line(&format!("  br label %{}", build_cond));

        self.open_block(&build_cond);
        let cur2 = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", cur2, cur2_ptr));
        let found2 = self.tmp_name();
        self.line(&format!("  {} = call i8* @strstr(i8* {}, i8* {})", found2, cur2, old));
        let is_null2 = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null2, found2));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null2, build_done, build_body));

        self.open_block(&build_body);
        let found2_64 = self.tmp_name();
        self.line(&format!("  {} = ptrtoint i8* {} to i64", found2_64, found2));
        let cur2_64 = self.tmp_name();
        self.line(&format!("  {} = ptrtoint i8* {} to i64", cur2_64, cur2));
        let seg_len = self.tmp_name();
        self.line(&format!("  {} = sub i64 {}, {}", seg_len, found2_64, cur2_64));
        let wptr = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", wptr, write_ptr));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", wptr, cur2, seg_len));
        let wptr2 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", wptr2, wptr, seg_len));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", wptr2, new, new_len64));
        let wptr3 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", wptr3, wptr2, new_len64));
        self.line(&format!("  store i8* {}, i8** {}", wptr3, write_ptr));
        let newcur2 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", newcur2, found2, old_len64));
        self.line(&format!("  store i8* {}, i8** {}", newcur2, cur2_ptr));
        self.line(&format!("  br label %{}", build_cond));

        self.open_block(&build_done);
        let cur2f = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", cur2f, cur2_ptr));
        let wptrf = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", wptrf, write_ptr));
        self.line(&format!("  call i8* @strcpy(i8* {}, i8* {})", wptrf, cur2f));
        self.line(&format!("  br label %{}", done_label));

        self.open_block(&done_label);
        let result = self.tmp_name();
        self.line(&format!("  {} = phi i8* [ {}, %{} ], [ {}, %{} ]", result, buf0, empty_old_label, buf, build_done));
        self.line(&format!("  call void @star_rc_release(i8* {})", s_raw));
        self.line(&format!("  call void @star_rc_release(i8* {})", old_raw));
        self.line(&format!("  call void @star_rc_release(i8* {})", new_raw));
        format!("i8* {}", result)
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
