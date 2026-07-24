//! Expression emission: the central `emit_expr` dispatcher, call lowering,
//! and GLSL-style swizzle read/write.

use crate::ast::*;
use crate::diagnostics::Span;
use crate::types::*;

use super::{format_f32_literal, Codegen};

/// Render an `i64`-held match-pattern literal (`Pattern::Int`'s payload, or
/// `Pattern::Compare`'s folded rhs) as a textual LLVM integer constant valid
/// for an `iN` operand of the given `width` -- LLVM's IR parser requires an
/// integer literal to be representable in the operand's own bit width, so a
/// pattern like `200 -> ...` against a `u8` scrutinee (`200` doesn't fit
/// signed `i8`'s `-128..=127`) would otherwise emit IR `clang` rejects with
/// an opaque "constant expression too wide" error instead of running.
/// Truncates to `width` bits, then renders through whichever of the two
/// representations (plain non-negative, or negative via the signed
/// interpretation) actually fits that bit width's literal syntax.
fn int_pattern_literal(v: i64, width: u32) -> String {
    if width >= 64 {
        return v.to_string();
    }
    let mask: i64 = (1i64 << width) - 1;
    let truncated = v & mask;
    let sign_bit = 1i64 << (width - 1);
    if truncated & sign_bit != 0 {
        (truncated - (1i64 << width)).to_string()
    } else {
        truncated.to_string()
    }
}

impl Codegen {
    /// Read a GLSL-style swizzle access (`.x`, `.xyz`, `.zyx`, ...) off a
    /// vector base, producing a scalar `float` (single component) or a
    /// smaller/reordered vector value (multiple components). Loads the base
    /// once, then extracts via `extractelement` (single component) or
    /// `shufflevector` (multiple) -- no GEP is used since a swizzle result
    /// isn't a contiguous sub-object in general.
    pub(super) fn emit_swizzle_read(&mut self, base: &TypedExpr, field: &str) -> String {
        let base_ty = self.expr_ty(base);
        let base_val = self.emit_expr(base);
        let bare = self.untag(&base_val, &base_ty);
        let indices: Vec<u32> = field.chars().map(|c| self.swizzle_index(c)).collect();

        if indices.len() == 1 {
            let reg = self.extract_component(&bare, &base_ty, indices[0]);
            return format!("float {}", reg);
        }

        if base_ty.is_vec() {
            let base_t = self.llvm_ty(&base_ty);
            let reg = self.tmp_name();
            let mask: Vec<String> = indices.iter().map(|i| format!("i32 {}", i)).collect();
            self.line(&format!(
                "  {} = shufflevector {} {}, {} undef, <{} x i32> <{}>",
                reg, base_t, bare, base_t, indices.len(), mask.join(", ")
            ));
            let result_ty = Ty::vec_of_arity(indices.len() as u8).unwrap();
            return format!("{} {}", self.llvm_ty(&result_ty), reg);
        }

        unreachable!("emit_swizzle_read is only reachable for vector base types")
    }

    /// Write to a GLSL-style swizzle target on a vector base
    /// (`v.x = ...`, `v.xy = ...`), with full write-mask support: each named
    /// destination lane is updated independently, leaving any unnamed lanes
    /// untouched. `val_ty` is the swizzle's own resolved type (`Float` for a
    /// single component, `Vec2`/`Vec3`/`Vec4` for multiple).
    pub(super) fn emit_swizzle_write(&mut self, base: &TypedExpr, field: &str, val_ty: &Ty, val: &str) {
        let base_ty = self.expr_ty(base);
        let val_bare = self.untag(val, val_ty);
        let indices: Vec<u32> = field.chars().map(|c| self.swizzle_index(c)).collect();
        let base_ptr = self.emit_place(base);

        if base_ty.is_vec() {
            let t = self.llvm_ty(&base_ty);
            let loaded = self.tmp_name();
            self.line(&format!("  {} = load {}, {}* {}", loaded, t, t, base_ptr));
            let mut acc = loaded;
            for (i, dest_idx) in indices.iter().enumerate() {
                let src = if indices.len() == 1 { val_bare.clone() } else { self.extract_component(&val_bare, val_ty, i as u32) };
                acc = self.insert_component(&acc, &base_ty, *dest_idx, &src);
            }
            self.line(&format!("  store {} {}, {}* {}", t, acc, t, base_ptr));
        } else {
            unreachable!("emit_swizzle_write is only reachable for vector base types");
        }
    }

    /// A method call (`obj.method(args)`) or a direct free-function call
    /// (`name(args)`), lowered to `call @method(%Struct* obj, args...)` or
    /// `call @name(args...)` respectively.
    fn emit_call_expr(&mut self, callee: &TypedExpr, args: &[TypedExpr], expr: &TypedExpr) -> String {
        // A call through a closure *value* (a `let`-bound lambda, a
        // closure-typed parameter/field, or a lambda literal called
        // immediately) is an indirect call, resolved from the callee's own
        // type rather than its syntactic shape -- checked first so a
        // closure stored in a struct field (`obj.callback(args)`, syntactically
        // identical to a method call) still routes here instead of being
        // mistaken for one.
        if let Ty::Closure(param_tys, ret_ty) = self.expr_ty(callee) {
            return self.emit_closure_call(callee, args, &param_tys, &ret_ty);
        }
        if let TypedExpr::Field { base, field, .. } = callee {
            // Method call: `obj.method(args)` -> `@method(%Struct* obj, args...)`.
            let base_ty = self.expr_ty(base);
            let struct_name = match &base_ty {
                Ty::Named(n) => n.clone(),
                _ => { self.err("method call on non-struct receiver", Span::dummy()); String::new() }
            };
            let key = format!("{}#{}", struct_name, field);
            let (fn_name, has_self) = match self.methods.get(&key) {
                Some(m) => m.clone(),
                None => { self.err(&format!("no method `{}` on `{}`", field, struct_name), Span::dummy()); (field.clone(), true) }
            };
            // The receiver is passed by pointer: `emit_place` resolves any
            // receiver shape (a bare local, `self`, a nested field access, or
            // an arbitrary rvalue spilled into a fresh alloca) to its storage
            // address. Previously this used a bespoke `receiver_name`+
            // `sym_ptr` combo that only recognized a bare local-variable
            // identifier and silently passed `%undef` as the receiver for
            // anything else -- breaking `self.other_method()`,
            // `obj.inner.method()`, and `list[i].method()`/`get_obj().method()`
            // style chained calls with invalid LLVM IR at the `clang` step.
            //
            // A method declaring no `self` at all (an "associated function"
            // still called via `obj.method(...)` syntax) takes no receiver
            // argument -- its LLVM signature (see `emit_fn`) has no leading
            // pointer parameter, so passing one here would be an arity
            // mismatch. The receiver expression is still evaluated for any
            // side effects it may have (it's written in the source even
            // though the callee can't observe it), just not threaded through
            // as an argument.
            let mut call_args = if has_self {
                let recv_ptr = self.emit_place(base);
                let recv_ty = self.llvm_ty(&base_ty);
                vec![format!("{}* {}", recv_ty, recv_ptr)]
            } else {
                self.emit_expr(base);
                Vec::new()
            };
            for a in args {
                let reg = self.emit_expr(a);
                let ats = self.llvm_ty(&self.expr_ty(a));
                let clean_val = reg.strip_prefix(&format!("{} ", ats)).unwrap_or(&reg);
                call_args.push(format!("{} {}", ats, clean_val));
            }
            let ret = self.tmp_name();
            // Methods without an explicit return type are typed `unknown`
            // by the checker; emit them as `void` calls.
            let ret_ty = match &self.expr_ty(expr) {
                Ty::Named(n) if n == "unknown" => "void".to_string(),
                other => self.llvm_ty(other),
            };
            if ret_ty == "void" {
                self.line(&format!("  call void @{}({})", fn_name, call_args.join(", ")));
                "%undef".into()
            } else {
                self.line(&format!("  {} = call {} @{}({})", ret, ret_ty, fn_name, call_args.join(", ")));
                format!("{} {}", ret_ty, ret)
            }
        } else {
            // A direct call to a named function: emit `call @name(args)`
            // straight away. `callee` must not be routed through
            // `emit_expr`/`emit_place` here — it names a global
            // function, not a local variable, so there is no alloca
            // to load from.
            let fn_name = match callee {
                TypedExpr::Ident { name, .. } => name.clone(),
                _ => { self.err("indirect calls are not supported", Span::dummy()); String::new() }
            };
            let call_args: Vec<String> = args.iter().map(|a| {
                let reg = self.emit_expr(a);
                let ats = self.llvm_ty(&self.expr_ty(a));
                let clean_val = reg.strip_prefix(&format!("{} ", ats)).unwrap_or(&reg).to_string();
                format!("{} {}", ats, clean_val)
            }).collect();
            // Free functions without an explicit return type are typed
            // `unknown` by the checker; emit them as `void` calls.
            let ret_ty = match &self.expr_ty(expr) {
                Ty::Named(n) if n == "unknown" => "void".to_string(),
                other => self.llvm_ty(other),
            };
            if ret_ty == "void" {
                self.line(&format!("  call void @{}({})", fn_name, call_args.join(", ")));
                "%undef".into()
            } else {
                let ret = self.tmp_name();
                self.line(&format!("  {} = call {} @{}({})", ret, ret_ty, fn_name, call_args.join(", ")));
                format!("{} {}", ret_ty, ret)
            }
        }
    }

    /// A call to a user-declared `extern "C" fn`: `call @name(args...)`,
    /// like `emit_call_expr`'s free-function path, but with a different
    /// convention for `str` arguments. `emit_call_expr` assumes the callee
    /// (an ordinary Star function) takes ownership of any RC'd argument and
    /// releases it at its own scope exit (see `emit_fn`'s `track_owned` in
    /// `stmt.rs`) -- an extern C function never calls `star_rc_release`, so
    /// passing a `str` straight through that convention would retain once
    /// (via `emit_expr` reading the argument) and never release it, leaking
    /// one refcount per call. `emit_raw_str_ptr` already implements exactly
    /// the right convention for a transient read (extract the raw `i8*`,
    /// balance any borrowed retain back out immediately) -- the same one
    /// `printf`/`len`/`concat` use -- so reuse it here instead of duplicating
    /// the retain/release bookkeeping.
    fn emit_extern_call(&mut self, name: &str, args: &[TypedExpr], expr: &TypedExpr) -> String {
        // Collect each `str` argument's raw pointer alongside `call_args`,
        // rather than releasing it inside the `.map()` below: the extern
        // call itself is the argument's actual last use, which only happens
        // *after* every `call_args` entry is built and the `call @{name}(...)`
        // line below is emitted -- releasing any earlier (as an inlined part
        // of building `call_args`) would free a fresh, non-borrowed `str`
        // argument's buffer (e.g. `my_extern_fn(concat("a", "b"))`) before
        // the extern function ever reads through the pointer it was handed.
        let mut str_ptrs: Vec<String> = Vec::new();
        let call_args: Vec<String> = args.iter().map(|a| {
            let ty = self.expr_ty(a);
            if ty == Ty::Str {
                let raw = self.emit_raw_str_ptr(a);
                str_ptrs.push(raw.clone());
                format!("i8* {}", raw)
            } else {
                let reg = self.emit_expr(a);
                let ats = self.llvm_ty(&ty);
                let clean_val = reg.strip_prefix(&format!("{} ", ats)).unwrap_or(&reg).to_string();
                format!("{} {}", ats, clean_val)
            }
        }).collect();
        let ret_ty = match &self.expr_ty(expr) {
            Ty::Named(n) if n == "unknown" => "void".to_string(),
            other => self.llvm_ty(other),
        };
        let result = if ret_ty == "void" {
            self.line(&format!("  call void @{}({})", name, call_args.join(", ")));
            "%undef".into()
        } else {
            let ret = self.tmp_name();
            self.line(&format!("  {} = call {} @{}({})", ret, ret_ty, name, call_args.join(", ")));
            format!("{} {}", ret_ty, ret)
        };
        // Every `str` argument is done being read now that the call has
        // executed -- release whatever `emit_raw_str_ptr` left us owning for
        // each (see its own doc comment).
        for ptr in &str_ptrs {
            self.line(&format!("  call void @star_rc_release(i8* {})", ptr));
        }
        result
    }

    /// Short-circuit lowering for `&&`/`and` and `||`/`or`: `rhs` is only
    /// evaluated when its value could actually change the result (mirrors
    /// every mainstream language's logical-operator semantics, and matters
    /// for real code -- e.g. `ref != null && ref.field` -- not just
    /// performance).
    fn emit_logical_binop(&mut self, op: BinOp, lhs: &TypedExpr, rhs: &TypedExpr) -> String {
        let l = self.emit_expr(lhs);
        let l_reg = self.reg_of(&l);
        let rhs_label = self.block_label("logic_rhs");
        let short_label = self.block_label("logic_short");
        let end_label = self.block_label("logic_end");
        // AND: short-circuit (skip rhs) when lhs is false. OR: short-circuit
        // when lhs is true. `br i1 cond, label %trueDest, label %falseDest`.
        let (true_dest, false_dest) = match op {
            BinOp::And => (rhs_label.clone(), short_label.clone()),
            BinOp::Or => (short_label.clone(), rhs_label.clone()),
            _ => unreachable!("emit_logical_binop is only called for And/Or"),
        };
        self.line(&format!("  br i1 {}, label %{}, label %{}", l_reg, true_dest, false_dest));

        self.open_block(&rhs_label);
        let r = self.emit_expr(rhs);
        let r_reg = self.reg_of(&r);
        // `rhs` may itself open further basic blocks (a list/`GenRef` index
        // bounds check, a nested logical op, an `if`/`match`-as-value), so
        // the block that actually falls through to `end_label` is whatever
        // `current_label` is now -- not the `rhs_label` opened above (see
        // `Codegen::current_label`'s doc comment; same fix as the `if`/
        // `match` phi merges).
        let rhs_pred = self.current_label.clone();
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&short_label);
        let short_val = if op == BinOp::And { "false" } else { "true" };
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let phi = self.tmp_name();
        self.line(&format!("  {} = phi i1 [ {}, %{} ], [ {}, %{} ]", phi, r_reg, rhs_pred, short_val, short_label));
        format!("i1 {}", phi)
    }

    pub(super) fn emit_expr(&mut self, expr: &TypedExpr) -> String {
        match expr {
            // Almost always `Ty::Int` (`i32`) -- the checker's `Expr::Int`
            // arm always types a bare literal that way -- but
            // `Checker::infer_expr`'s `Expr::Cast` literal fast path can
            // also produce one already typed as the cast's (wider) target,
            // for a literal whose magnitude doesn't fit `i32` on its own
            // (`5000000000 as i64`). Must respect `ty` here rather than
            // hardcoding `i32`, or that literal's own `i64` tag would be
            // silently discarded and reinterpreted as an out-of-range `i32`
            // constant -- invalid IR `clang` rejects outright.
            TypedExpr::Int(v, ty, _) => format!("{} {}", self.llvm_ty(ty), v),
            TypedExpr::Float(v, _, _) => format!("float {}", format_f32_literal(*v)),
            TypedExpr::Str(s, _, _) => {
                let escaped = s.replace("\\", "\\\\").replace("\"", "\\22").replace("\n", "\\0A");
                let g = self.global_name();
                let n = s.len() + 1;
                // Wrapped in the exact same 16-byte `[i64 refcount][i8*
                // release_fn]` header `star_rc_alloc` gives every heap
                // allocation (see `Codegen::emit_rc_runtime`), with the
                // refcount field set to the reserved `-1` sentinel
                // `star_rc_retain`/`release` treat as "immortal, never
                // free" -- a literal is backed by a permanent global, not a
                // heap block, so it must never actually be retained/freed,
                // but still needs to *look* like a valid RC'd allocation to
                // whatever generically retains/releases a `Str` value that
                // happens to hold this literal (see `rc.rs`).
                let struct_ty = format!("{{ i64, i8*, [{} x i8] }}", n);
                self.global_defs.push(format!(
                    "{} = private unnamed_addr constant {} {{ i64 -1, i8* null, [{} x i8] c\"{}\\00\" }}",
                    g, struct_ty, n, escaped
                ));
                let gep = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 0, i32 2, i64 0", gep, struct_ty, struct_ty, g));
                // A `Str` value is just the raw `i8*` bytes pointer directly
                // (matching `Int`/`Float`/`Bool` literals, which also return
                // their value tagged with its LLVM type) -- no extra
                // indirection through a stack-allocated "box". Boxing used
                // to wrap `gep` in a fresh `alloca i8*`, which dangled the
                // instant a function returning a freshly-constructed `str`
                // returned that alloca's address.
                format!("i8* {}", gep)
            }
            TypedExpr::Bool(v, _, _) => format!("i1 {}", if *v { "true" } else { "false" }),
            // A bare 32-bit codepoint constant -- see `Ty::Char`'s doc comment.
            TypedExpr::Char(c, _, _) => format!("i32 {}", *c as u32),
            TypedExpr::Cast { expr, ty, .. } => self.emit_cast(expr, ty),
            // Lowers to the exact same LLVM integer type as its inner type
            // -- see `Ty::Wrapping`'s doc comment -- so construction needs no
            // dedicated codegen beyond evaluating `value` itself.
            TypedExpr::WrappingNew { value, .. } => self.emit_expr(value),
            TypedExpr::FixedNew { value, bits, frac, .. } => self.emit_fixed_new(value, *bits, *frac),
            TypedExpr::BitFieldNew { value, bits, .. } => self.emit_bitfield_new(value, *bits),
            TypedExpr::FlagsNew { enum_name, args, .. } => self.emit_flags_new(enum_name, args),
            TypedExpr::Ident { name, ty, .. } => {
                // A plain top-level function name used as a value (never a
                // local, so no alloca to load from) rather than called
                // directly -- see `Codegen::emit_fn_value`.
                if let Ty::Closure(param_tys, ret_ty) = ty {
                    if self.sym_ptr(name).is_none() {
                        return self.emit_fn_value(name, param_tys, ret_ty);
                    }
                }
                let ptr = self.sym_ptr(name).unwrap_or_else(|| "%undef".into());
                let reg = self.tmp_name();
                let ts = self.llvm_ty(ty);
                self.line(&format!("  {} = load {}, {}* {}", reg, ts, ts, ptr));
                // Reading a variable hands the caller an independent copy of
                // whatever it holds while `name`'s own slot keeps its
                // reference -- retain so the duplicate is properly owned
                // (see `rc.rs`; a no-op unless `ty` is RC-bearing).
                self.emit_retain_at(&ptr, ty);
                // Every other `emit_expr` arm tags its result with its LLVM
                // type (`"i32 %r"`, not bare `"%r"` -- see `reg_of`'s doc
                // comment on the convention every caller relies on). This
                // arm used to return the bare register, which most callers
                // never noticed because they only ever strip the type back
                // off via `reg_of`: harmless on a bare register (nothing to
                // strip) and harmless on a tagged one (strips the tag). The
                // one caller that actually needs the tag *present* --
                // `emit_trailing_if_value`'s `split_once(' ')`, extracting
                // the phi's merged type from either arm's value -- silently
                // came back `None` whenever a trailing `if`/`else` arm was a
                // bare identifier (e.g. `if cond: a else: b` returning a
                // parameter directly), which `emit_stmts_value`'s `?`
                // propagated all the way out to "function must end in a
                // value-producing expression" even though the checker had
                // already accepted the exact same shape. Confirmed live
                // building `projects/snake`'s `pick_color` helper.
                format!("{} {}", ts, reg)
            }
            TypedExpr::SelfExpr(ty, _) => {
                // `self` is passed by pointer (see `emit_fn`'s `is_self`
                // special-casing) and its symbol slot holds a pointer *to*
                // that pointer, so a single load off the slot -- what
                // `emit_place`'s own `SelfExpr` arm does -- only ever
                // recovers the pointer to the caller's struct, not the
                // struct's value. That's exactly right for `emit_place`'s
                // job (a base pointer to GEP into for `self.field`), but
                // this arm's job is the opposite: yield `self` as an
                // ordinary *value* (`return self`, `let x = self`, passing
                // `self` to a function expecting the struct by value). This
                // used to return `emit_place`'s pointer verbatim, one load
                // short of a real value -- type-checked fine (both are
                // "some SSA register") but produced a genuine `ptr`-vs-
                // aggregate LLVM type mismatch at the `ret`/`store` that
                // consumed it, only ever caught at the `clang` step.
                let self_ptr = self.emit_place(expr);
                let reg = self.tmp_name();
                let struct_ty = self.llvm_ty(ty);
                self.line(&format!("  {} = load {}, {}* {}", reg, struct_ty, struct_ty, self_ptr));
                // Mirrors `Ident`'s own retain-on-read just above: handing
                // out a value copy of `self` must not let the copy alias
                // the original's owned fields without its own reference.
                self.emit_retain_at(&self_ptr, ty);
                reg
            }
            TypedExpr::TupleIndex { base, index, ty, .. } => {
                // Same reasoning as `Field` below: must not go via
                // `emit_place`'s `ListIndex` arm on a `list[idx]`-based
                // tuple, so route through the read-only `emit_read_place`.
                let base_ptr = self.emit_read_place(base);
                let struct_ty = self.llvm_ty(&self.expr_ty(base));
                let gep = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, struct_ty, struct_ty, base_ptr, index));
                let reg = self.tmp_name();
                let ts = self.llvm_ty(ty);
                self.line(&format!("  {} = load {}, {}* {}", reg, ts, ts, gep));
                // Retain unconditionally, regardless of whether `base`
                // bottoms out in real, persistent storage or a freshly
                // spilled temporary (`make_pair().0`) -- `Codegen::emit_place`'s
                // generic fallback now tracks and releases every such
                // temporary exactly once at scope end (any `contains_rc`
                // type, not just `List`/`Map`/`Set`/`Table`), so this retain
                // is always balanced. See that fallback's doc comment for the
                // sibling-field leak this replaces (skipping the retain here
                // for a spilled base, previously relying on nothing ever
                // releasing that base, leaked every other RC-bearing field of
                // a multi-field tuple/struct temporary that was never itself
                // read).
                self.emit_retain_at(&gep, ty);
                reg
            }
            TypedExpr::ArrayRepeat { value, count, elem_ty, .. } => self.emit_array_repeat(value, *count, elem_ty),
            TypedExpr::ArrayIndex { base, index, ty, .. } => {
                let Ty::Array(_, count) = self.expr_ty(base) else { unreachable!("ArrayIndex base must be Ty::Array") };
                self.emit_array_index(base, index, ty, count)
            }
            // `.len()` is resolved entirely by the checker to the array's
            // static `count` (see `Checker::infer_array_method`) -- `base`
            // is still evaluated here (discarding the result) purely so any
            // side effects computing it might have (e.g. a call expression
            // yielding the array) still happen.
            TypedExpr::ArrayLen { base, count, .. } => {
                self.emit_expr(base);
                format!("i32 {}", count)
            }
            TypedExpr::RingNew { elem_ty, count, .. } => self.emit_ring_new(elem_ty, *count),
            TypedExpr::RingIndex { base, index, ty, .. } => {
                // Same shape as `TupleIndex` above: route through the place
                // resolver (which already does the bounds-checked GEP), then
                // load + retain -- see `emit_ring_index_read_place`'s doc
                // comment for why this reuses the pointer path instead of
                // duplicating a separate value-level phi.
                let Ty::Ring(_, count) = self.expr_ty(base) else { unreachable!("RingIndex base must be Ty::Ring") };
                let ptr = self.emit_ring_index_read_place(base, index, ty, count);
                let elem_llvm = self.llvm_ty(ty);
                let reg = self.tmp_name();
                self.line(&format!("  {} = load {}, {}* {}", reg, elem_llvm, elem_llvm, ptr));
                // Retain unconditionally -- see `TupleIndex`'s identical
                // fix above and `Codegen::emit_place`'s generic fallback doc
                // comment: a freshly spilled temporary (`make_ring()[0]`) is
                // now always tracked and released once at scope end, so this
                // retain is always balanced regardless of whether `base` is
                // real, persistent storage.
                self.emit_retain_at(&ptr, ty);
                format!("{} {}", elem_llvm, reg)
            }
            TypedExpr::RingMethod { base, method, args, .. } => {
                let (elem_ty, count) = match self.expr_ty(base) {
                    Ty::Ring(inner, count) => (*inner, count),
                    other => { self.err("internal error: ring method receiver is not a Ring<T,N>", Span::dummy()); (other, 0) }
                };
                self.emit_ring_method(base, *method, args, &elem_ty, count)
            }
            TypedExpr::Field { base, field, ty, .. } => {
                if self.expr_ty(base).is_vec() {
                    return self.emit_swizzle_read(base, field);
                }
                // A `list[idx]` base being read through (not written
                // through), at any `Field`-chain nesting depth, must not go
                // via `emit_place`'s `ListIndex` arm -- that arm exists for
                // writes and unconditionally clones/un-aliases the list via
                // `emit_list_ensure_unique` first. Same bug class as the
                // already-fixed `list_fields`/`list_index_read_obj` (todo.md
                // item 6), just for a struct-element field read instead of a
                // scalar/nested-list element read. `emit_read_place` handles
                // this generally (see its doc comment).
                let base_ptr = self.emit_read_place(base);
                let gep = self.tmp_name();
                let bty = self.llvm_ty(&self.expr_ty(base));
                let idx = self.field_index(&self.expr_ty(base), field);
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, bty, bty, base_ptr, idx));
                let reg = self.tmp_name();
                let ts = self.llvm_ty(ty);
                self.line(&format!("  {} = load {}, {}* {}", reg, ts, ts, gep));
                // Same reasoning as `Ident` above: reading a field hands out
                // an independent copy of its value -- retain unconditionally,
                // regardless of whether `base` is real, persistent storage or
                // a freshly spilled temporary (`table[i].field`,
                // `make_struct().field`, ...). `Codegen::emit_place`'s
                // generic fallback now tracks and releases every such
                // temporary exactly once at scope end (see that fallback's
                // doc comment), which balances this retain and also fixes the
                // leak of every *other* RC-bearing field of a multi-field
                // struct temporary that this retain-skip guard previously
                // caused to leak silently (only the one field actually
                // accessed was ever correctly accounted for).
                self.emit_retain_at(&gep, ty);
                reg
            }
            TypedExpr::Call { callee, args, .. } => {
                // Standard-library builtins are recognized by name and
                // lowered directly, ahead of the generic free-function/method
                // call paths below (so a same-named user `fn` can never be
                // called instead — matches the pre-existing `print` behavior).
                let builtin_name = match callee.as_ref() {
                    TypedExpr::Ident { name, .. } => Some(name.as_str()),
                    _ => None,
                };
                match builtin_name {
                    Some("print") => { self.emit_print_like(args, false); "%undef".into() }
                    Some("println") => { self.emit_print_like(args, true); "%undef".into() }
                    Some("sqrt") => self.emit_math_unary(args, "llvm.sqrt.f32"),
                    Some("floor") => self.emit_math_unary(args, "llvm.floor.f32"),
                    Some("ceil") => self.emit_math_unary(args, "llvm.ceil.f32"),
                    Some("pow") => self.emit_math_binary_f32(args, "llvm.pow.f32"),
                    Some("abs") => self.emit_abs(args),
                    Some("sin") => self.emit_math_unary(args, "llvm.sin.f32"),
                    Some("cos") => self.emit_math_unary(args, "llvm.cos.f32"),
                    Some("tan") => self.emit_math_unary(args, "llvm.tan.f32"),
                    Some("asin") => self.emit_math_unary(args, "llvm.asin.f32"),
                    Some("acos") => self.emit_math_unary(args, "llvm.acos.f32"),
                    Some("atan") => self.emit_math_unary(args, "llvm.atan.f32"),
                    Some("atan2") => self.emit_math_binary_f32(args, "llvm.atan2.f32"),
                    Some("exp") => self.emit_math_unary(args, "llvm.exp.f32"),
                    Some("exp2") => self.emit_math_unary(args, "llvm.exp2.f32"),
                    Some("log") => self.emit_math_unary(args, "llvm.log.f32"),
                    Some("log2") => self.emit_math_unary(args, "llvm.log2.f32"),
                    Some("log10") => self.emit_math_unary(args, "llvm.log10.f32"),
                    Some("min") => self.emit_minmax(args, true),
                    Some("max") => self.emit_minmax(args, false),
                    Some("len") => self.emit_str_len(args),
                    Some("concat") => self.emit_str_concat(args),
                    Some("str_contains") => self.emit_str_contains(args),
                    Some("str_starts_with") => self.emit_str_starts_with(args),
                    Some("str_ends_with") => self.emit_str_ends_with(args),
                    Some("str_index_of") => self.emit_str_index_of(args),
                    Some("str_trim") => self.emit_str_trim(args),
                    Some("str_replace") => self.emit_str_replace(args),
                    Some("str_split") => self.emit_str_split(args),
                    Some("str_join") => self.emit_str_join(args),
                    Some("chr") => self.emit_chr(args),
                    Some("ord") => self.emit_ord(args),
                    Some("bytes_from_str") => self.emit_bytes_from_str(args),
                    Some("str_from_bytes") => self.emit_str_from_bytes(args),
                    Some("symbol_name") => self.emit_symbol_name(args),
                    Some("bit_get") => self.emit_bit_get(&args[0], &args[1]),
                    Some("bit_set") => self.emit_bit_set_clear_toggle(&args[0], &args[1], super::bitfield::BitIndexOp::Set),
                    Some("bit_clear") => self.emit_bit_set_clear_toggle(&args[0], &args[1], super::bitfield::BitIndexOp::Clear),
                    Some("bit_toggle") => self.emit_bit_set_clear_toggle(&args[0], &args[1], super::bitfield::BitIndexOp::Toggle),
                    Some("bit_and") => self.emit_bit_combine(&args[0], &args[1], "and"),
                    Some("bit_or") => self.emit_bit_combine(&args[0], &args[1], "or"),
                    Some("bit_xor") => self.emit_bit_combine(&args[0], &args[1], "xor"),
                    Some("bit_not") => self.emit_bit_not(&args[0]),
                    Some("flags_has") => self.emit_flags_has(&args[0], &args[1]),
                    Some("flags_with") => self.emit_flags_with_without(&args[0], &args[1], true),
                    Some("flags_without") => self.emit_flags_with_without(&args[0], &args[1], false),
                    Some("flags_is_empty") => self.emit_flags_is_empty(&args[0]),
                    Some("read_line") => self.emit_read_line(),
                    Some("dot") => self.emit_dot(args),
                    Some("length") => self.emit_length(args),
                    Some("lerp") => self.emit_lerp(args),
                    Some("clamp") => self.emit_clamp(args),
                    Some("rand") => self.emit_rand(),
                    Some("rand_range") => self.emit_rand_range(args),
                    Some("rand_seed") => { self.emit_rand_seed(args); "%undef".into() }
                    Some("null_ptr") => self.emit_null_ptr(),
                    Some("is_null") => self.emit_is_null(args),
                    Some("ptr_to_str") => self.emit_ptr_to_str(args),
                    Some("file_open") => self.emit_file_open(args),
                    Some("file_close") => { self.emit_file_close(args); "%undef".into() }
                    Some("file_read") => self.emit_file_read(args),
                    Some("file_read_line") => self.emit_file_read_line(args),
                    Some("file_write") => self.emit_file_write(args),
                    Some("file_exists") => self.emit_file_exists(args),
                    Some("args") => self.emit_args(),
                    Some("env_get") => self.emit_env_get(args),
                    Some("env_set") => self.emit_env_set(args),
                    Some("tcp_connect") => self.emit_tcp_connect(args),
                    Some("tcp_send") => self.emit_tcp_send(args),
                    Some("tcp_recv") => self.emit_tcp_recv(args),
                    Some("tcp_close") => { self.emit_tcp_close(args); "%undef".into() }
                    // `docs/design.md`'s "Math and geometry" section -- see
                    // `crate::codegen::geometry`.
                    Some("quat_identity") => self.emit_quat_identity(),
                    Some("quat_conjugate") => self.emit_quat_conjugate(args),
                    Some("quat_normalize") => self.emit_quat_normalize(args),
                    Some("quat_rotate") => self.emit_quat_rotate(args),
                    Some("rect_contains") => self.emit_rect_contains(args),
                    Some("rect_intersects") => self.emit_rect_intersects(args),
                    Some("aabb2_contains") => self.emit_aabb2_contains(args),
                    Some("aabb2_intersects") => self.emit_aabb2_intersects(args),
                    Some("aabb3_contains") => self.emit_aabb3_contains(args),
                    Some("aabb3_intersects") => self.emit_aabb3_intersects(args),
                    Some("ray_at") => self.emit_ray_at(args),
                    Some("plane_distance_to_point") => self.emit_plane_distance_to_point(args),
                    Some("frustum_contains_point") => self.emit_frustum_contains_point(args),
                    Some("transform_apply_point") => self.emit_transform_apply_point(args),
                    Some("color32_r") => self.emit_color32_channel(args, 0),
                    Some("color32_g") => self.emit_color32_channel(args, 1),
                    Some("color32_b") => self.emit_color32_channel(args, 2),
                    Some("color32_a") => self.emit_color32_channel(args, 3),
                    Some("color_to_color32") => self.emit_color_to_color32(args),
                    Some("color32_to_color") => self.emit_color32_to_color(args),
                    // SDL2-backed graphics/input builtins (`todo.md` #4) --
                    // see `crate::codegen::sdl`.
                    Some("window_create") => self.emit_window_create(args),
                    Some("window_destroy") => { self.emit_window_destroy(args); "%undef".into() }
                    Some("window_should_close") => self.emit_window_should_close(args),
                    Some("clear_screen") => { self.emit_clear_screen(args); "%undef".into() }
                    Some("draw_pixel") => { self.emit_draw_pixel(args); "%undef".into() }
                    Some("draw_rect") => { self.emit_draw_rect(args); "%undef".into() }
                    Some("draw_line") => { self.emit_draw_line(args); "%undef".into() }
                    Some("present") => { self.emit_present(args); "%undef".into() }
                    Some("key_down") => self.emit_key_down(args),
                    Some("mouse_x") => self.emit_mouse_x(),
                    Some("mouse_y") => self.emit_mouse_y(),
                    Some("mouse_button_down") => self.emit_mouse_button_down(args),
                    Some("delay") => { self.emit_delay(args); "%undef".into() }
                    Some("ticks") => self.emit_ticks(),
                    // Text-rendering/font-loading builtins -- see
                    // `crate::codegen::font`.
                    Some("font_load") => self.emit_font_load(args),
                    Some("font_free") => { self.emit_font_free(args); "%undef".into() }
                    Some("default_font") => self.emit_default_font(),
                    Some("draw_text") => { self.emit_draw_text(args); "%undef".into() }
                    Some("measure_text") => self.emit_measure_text(args),
                    Some("get_pixel") => self.emit_get_pixel(args),
                    // `todo.md` #7, "wire up reflection into an actual
                    // runtime feature" -- see `crate::codegen::reflect`.
                    Some("reflect_get_i32") => self.emit_reflect_get(args, &Ty::Int),
                    Some("reflect_get_f32") => self.emit_reflect_get(args, &Ty::Float),
                    Some("reflect_get_bool") => self.emit_reflect_get(args, &Ty::Bool),
                    Some("reflect_set_i32") => self.emit_reflect_set(args, &Ty::Int),
                    Some("reflect_set_f32") => self.emit_reflect_set(args, &Ty::Float),
                    Some("reflect_set_bool") => self.emit_reflect_set(args, &Ty::Bool),
                    Some("reflect_has_field") => self.emit_reflect_has_field(args),
                    Some(name) if self.extern_fns.contains(name) => self.emit_extern_call(name, args, expr),
                    _ => self.emit_call_expr(callee, args, expr),
                }
            }
            TypedExpr::Binary { op, lhs, rhs, .. } if matches!(op, BinOp::And | BinOp::Or) => {
                self.emit_logical_binop(*op, lhs, rhs)
            }
            TypedExpr::Binary { op, lhs, rhs, .. } => {
                let lty = self.expr_ty(lhs);
                let rty = self.expr_ty(rhs);
                let l = self.emit_expr(lhs);
                let r = self.emit_expr(rhs);
                self.emit_binop(&l, &lty, &r, &rty, *op)
            }
            TypedExpr::Unary { op, operand, .. } => {
                let operand_ty = self.expr_ty(operand);
                let o = self.emit_expr(operand);
                match op {
                    // Routed through the same width/signedness-generic
                    // scalar-binop path real binary `-` uses (`0 - x`)
                    // rather than a hardcoded `sub i32 0, ...`/`fsub float
                    // 0.0, ...` -- the operand's type is never restricted to
                    // `i32`/`float` by the checker (`-x` preserves whatever
                    // numeric type `x` has), so `-a` on any other numeric
                    // type (`i64`, `u8`, `f64`, ...) previously emitted an
                    // operand/opcode width mismatch `clang` rejects outright
                    // (e.g. `sub i32 0, %t` against an `i64` operand). This
                    // also picks up the same trap-on-overflow behavior every
                    // other sized-int arithmetic op already has (`-i8::MIN`
                    // traps, exactly like `0i8 - i8::MIN` would).
                    UnOp::Neg => {
                        // `zero_value` already knows the right zero constant
                        // for every type this can legally reach (checker-
                        // enforced via `infer_binop_ty`'s own `Sub` legality
                        // check) -- notably `Vec2`/`Vec3`/`Vec4`/`Mat4`, whose
                        // zero is `zeroinitializer`, not the bare `0` the
                        // previous unconditional `format!("{} 0", ...)`
                        // fallback produced (`fsub <2 x float> 0, %t11` is
                        // malformed IR `clang` rejects outright -- a scalar
                        // `0` literal has no vector type to infer).
                        let zero = format!("{} {}", self.llvm_ty(&operand_ty), self.zero_value(&operand_ty));
                        self.emit_binop(&zero, &operand_ty, &o, &operand_ty, BinOp::Sub)
                    }
                    UnOp::Not => {
                        // `emit_expr` returns literals already tagged with
                        // their LLVM type (e.g. `i32 5`) but loads/calls
                        // bare; strip any existing tag so the opcode below
                        // never double-tags it.
                        let bare = self.untag(&o, &operand_ty);
                        let reg = self.tmp_name();
                        self.line(&format!("  {} = xor i1 true, {}", reg, bare));
                        reg
                    }
                }
            }
            TypedExpr::Match { scrutinee, arms, ty, .. } => {
                let ty_str = self.llvm_ty(ty);
                // `unknown` is the established placeholder for "no value"
                // (see `check_match_arm`, and the same convention
                // `emit_call_expr`/`closure_ret_llvm` already use for a
                // function with no declared return type) -- checked against
                // the `Ty` itself rather than the stringified `ty_str`
                // because `llvm_ty` has no dedicated `void` case of its own
                // (every `Ty::Named` is rendered as `%name`, including this
                // one, so comparing the rendered string against `"void"`
                // would never match).
                let produces_value = !matches!(ty, Ty::Named(n) if n == "unknown");
                // One (value, predecessor-label) pair per arm that falls
                // through to `end_label` (an arm that terminates on its own
                // contributes no value, and control never reaches the join
                // block through it), collected for the `phi` that merges
                // arm values when this `match` is used as a value-producing
                // expression rather than purely for side effects.
                let mut arm_values: Vec<(String, String)> = Vec::new();
                let scrutinee_ty = self.expr_ty(scrutinee);
                let is_payload_enum = matches!(&scrutinee_ty, Ty::Enum(n) if self.enum_is_payload(n));
                let is_struct_scrutinee = matches!(&scrutinee_ty, Ty::Named(n) if self.struct_fields.contains_key(n));
                // A payload enum's fields (or a struct pattern's fields) are
                // only reachable through a pointer to their storage (for the
                // GEP dance below), so the scrutinee is addressed via
                // `emit_place` (which spills a by-value result into a fresh
                // alloca if needed) rather than loaded as a plain SSA value
                // like every other scrutinee kind.
                let needs_scrut_ptr = is_payload_enum || is_struct_scrutinee;
                let scrut_ptr = if needs_scrut_ptr { self.emit_place(scrutinee) } else { String::new() };
                let scrut_val = if needs_scrut_ptr {
                    String::new()
                } else {
                    let reg = self.emit_expr(scrutinee);
                    self.untag(&reg, &scrutinee_ty)
                };
                let end_label = format!("match_end_{}", self.tmp);
                self.tmp += 1;
                // A `Struct`/`Wildcard` arm (below) carries no tag to test,
                // so it never opens its own block -- it just runs in
                // whatever block is already current. That block needs a
                // name for the `phi` predecessor list, so one is opened
                // explicitly here (a plain unconditional jump, free of
                // semantic effect) instead of relying on whatever label
                // happened to be open before this `match` expression
                // started; `current_label` is kept up to date with
                // whichever block is open as each arm is processed.
                let entry_label = format!("match_scrutinee_{}", self.tmp);
                self.tmp += 1;
                self.line(&format!("  br label %{}", entry_label));
                self.open_block(&entry_label);
                let mut current_label = entry_label;
                // `Compare`/`EnumVariant` arms each open a "next" block for
                // the following arm to test against; the very last arm in
                // the list has no following arm to give that block a
                // terminator, so it's tracked here and closed explicitly
                // below (a `Wildcard` arm never opens one, since there's no
                // "no match" branch to chain to).
                let mut dangling_next_block = false;
                for (i, arm) in arms.iter().enumerate() {
                    // Suffixed with `self.tmp` (like `end_label`/`entry_label`
                    // just above), not just the arm index `i` alone -- a
                    // function with more than one `match` (or, previously,
                    // any second `match` reached at all after the first)
                    // would otherwise have every one of its arms' `then`/
                    // `next` blocks collide on the exact same label text
                    // (`match_then_0`, `match_next_0`, ...), corrupting the
                    // emitted IR into what LLVM's parser sees as one block
                    // holding two terminators instead of two distinct
                    // blocks -- see `runtime_multiple_matches_in_one_function_end_to_end`.
                    let then_label = format!("match_then_{}_{}", i, self.tmp);
                    self.tmp += 1;
                    let next_label = format!("match_next_{}_{}", i, self.tmp);
                    self.tmp += 1;
                    dangling_next_block = matches!(arm.pattern, Pattern::Compare(..) | Pattern::EnumVariant(..) | Pattern::Int(..) | Pattern::Bool(..));
                    match &arm.pattern {
                        // `Int`/`Bool` are plain equality patterns (`43 -> ...`,
                        // `true -> ...`) -- same then/next branch-and-chain
                        // shape as `Compare`'s `Eq` case, just without an rhs
                        // expression to evaluate first.
                        Pattern::Int(v) => {
                            // `scrutinee_ty` may be any integer-shaped type,
                            // not just the original `i32` `Ty::Int` (see
                            // `Checker::check_match_arm`'s widened
                            // `int_shape()` check) -- compare against its
                            // real LLVM width, not a hardcoded `i32`.
                            let (width, _) = scrutinee_ty.int_shape().unwrap_or((32, true));
                            let ity = format!("i{}", width);
                            let lit = int_pattern_literal(*v, width);
                            let cmp = self.tmp_name();
                            self.line(&format!("  {} = icmp eq {} {}, {}", cmp, ity, scrut_val, lit));
                            self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, then_label, next_label));
                            self.open_block(&then_label);
                            self.push_scope();
                            let val = self.emit_stmts_value(&arm.body.stmts);
                            let arm_terminates = Self::body_terminates(&arm.body.stmts);
                            self.pop_scope(!arm_terminates);
                            if !arm_terminates {
                                if produces_value {
                                    let reg = val.map(|v| self.reg_of(&v)).unwrap_or_else(|| "undef".to_string());
                                    arm_values.push((reg, self.current_label.clone()));
                                }
                                self.line(&format!("  br label %{}", end_label));
                            }
                            self.open_block(&next_label);
                            current_label = next_label.clone();
                        }
                        Pattern::Bool(b) => {
                            let cmp = self.tmp_name();
                            let bval = if *b { "true" } else { "false" };
                            self.line(&format!("  {} = icmp eq i1 {}, {}", cmp, scrut_val, bval));
                            self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, then_label, next_label));
                            self.open_block(&then_label);
                            self.push_scope();
                            let val = self.emit_stmts_value(&arm.body.stmts);
                            let arm_terminates = Self::body_terminates(&arm.body.stmts);
                            self.pop_scope(!arm_terminates);
                            if !arm_terminates {
                                if produces_value {
                                    let reg = val.map(|v| self.reg_of(&v)).unwrap_or_else(|| "undef".to_string());
                                    arm_values.push((reg, self.current_label.clone()));
                                }
                                self.line(&format!("  br label %{}", end_label));
                            }
                            self.open_block(&next_label);
                            current_label = next_label.clone();
                        }
                        Pattern::Compare(op, rhs) => {
                            // Same widening as `Pattern::Int` above: compare
                            // against the scrutinee's real integer width/
                            // signedness, not a hardcoded signed `i32`.
                            let (width, signed) = scrutinee_ty.int_shape().unwrap_or((32, true));
                            let ity = format!("i{}", width);
                            let rhs_i64 = match rhs.as_ref() {
                                Expr::Int(v, _) => *v,
                                // A negative literal (`<= -5`) parses as a
                                // unary negation of an int literal, not an
                                // `Expr::Int` directly (the lexer/parser have
                                // no negative-literal token) -- fold it here
                                // so this is still a compile-time constant
                                // rather than falling into the "unsupported"
                                // error below for perfectly ordinary syntax.
                                Expr::Unary { op: UnOp::Neg, operand, .. } => match operand.as_ref() {
                                    Expr::Int(v, _) => -v,
                                    _ => { self.err("unsupported match rhs expression", Span::dummy()); 0 }
                                },
                                _ => { self.err("unsupported match rhs expression", Span::dummy()); 0 }
                            };
                            let rhs_val_clean = int_pattern_literal(rhs_i64, width);
                            let cmp = self.tmp_name();
                            let llvm_op = match op {
                                BinOp::Le => if signed { "icmp sle" } else { "icmp ule" },
                                BinOp::Ge => if signed { "icmp sge" } else { "icmp uge" },
                                BinOp::Lt => if signed { "icmp slt" } else { "icmp ult" },
                                BinOp::Gt => if signed { "icmp sgt" } else { "icmp ugt" },
                                BinOp::Eq => "icmp eq",
                                BinOp::Ne => "icmp ne",
                                _ => "icmp eq",
                            };
                            self.line(&format!("  {} = {} {} {}, {}", cmp, llvm_op, ity, scrut_val, rhs_val_clean));
                            self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, then_label, next_label));
                            self.open_block(&then_label);
                            self.push_scope();
                            let val = self.emit_stmts_value(&arm.body.stmts);
                            let arm_terminates = Self::body_terminates(&arm.body.stmts);
                            self.pop_scope(!arm_terminates);
                            if !arm_terminates {
                                if produces_value {
                                    let reg = val.map(|v| self.reg_of(&v)).unwrap_or_else(|| "undef".to_string());
                                    // Not necessarily `then_label` anymore --
                                    // evaluating the arm's trailing value may
                                    // have opened further blocks of its own
                                    // (see `Codegen::current_label`'s doc
                                    // comment; same fix as `TypedExpr::If`'s
                                    // phi merge just below).
                                    arm_values.push((reg, self.current_label.clone()));
                                }
                                self.line(&format!("  br label %{}", end_label));
                            }
                            self.open_block(&next_label);
                            current_label = next_label.clone();
                        }
                        Pattern::EnumVariant(enum_name, variant, bindings) => {
                            let idx = self.enum_variant_index(enum_name, variant);
                            let cmp = self.tmp_name();
                            if is_payload_enum {
                                let enum_ty = format!("%{}", enum_name);
                                let tag_gep = self.tmp_name();
                                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", tag_gep, enum_ty, enum_ty, scrut_ptr));
                                let tag_reg = self.tmp_name();
                                self.line(&format!("  {} = load i32, i32* {}", tag_reg, tag_gep));
                                self.line(&format!("  {} = icmp eq i32 {}, {}", cmp, tag_reg, idx));
                            } else {
                                self.line(&format!("  {} = icmp eq i32 {}, {}", cmp, scrut_val, idx));
                            }
                            self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, then_label, next_label));
                            self.open_block(&then_label);
                            // Destructure the variant's payload fields into
                            // fresh symbol bindings (scoped to this arm's
                            // body only -- popped right after) by bitcasting
                            // the enum's shared payload buffer to this
                            // variant's own field layout and GEP-ing into it.
                            let mut bound = 0usize;
                            if is_payload_enum && !bindings.is_empty() {
                                let enum_ty = format!("%{}", enum_name);
                                let words = self.enum_payload_words(enum_name);
                                let elem = self.enum_payload_elem_ty(enum_name);
                                let payload_gep = self.tmp_name();
                                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", payload_gep, enum_ty, enum_ty, scrut_ptr));
                                let variant_ty = self.enum_variant_payload_llvm_ty(enum_name, idx);
                                let variant_ptr = self.tmp_name();
                                self.line(&format!("  {} = bitcast [{} x {}]* {} to {}*", variant_ptr, words, elem, payload_gep, variant_ty));
                                let field_tys = self.enum_variant_field_types(enum_name, idx);
                                for (fi, (bind_name, fty)) in bindings.iter().zip(field_tys.iter()).enumerate() {
                                    let field_gep = self.tmp_name();
                                    self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", field_gep, variant_ty, variant_ty, variant_ptr, fi as u32));
                                    self.symbols.push((bind_name.clone(), field_gep, fty.clone()));
                                    bound += 1;
                                }
                            }
                            self.push_scope();
                            let val = self.emit_stmts_value(&arm.body.stmts);
                            for _ in 0..bound {
                                self.symbols.pop();
                            }
                            let arm_terminates = Self::body_terminates(&arm.body.stmts);
                            self.pop_scope(!arm_terminates);
                            if !arm_terminates {
                                if produces_value {
                                    let reg = val.map(|v| self.reg_of(&v)).unwrap_or_else(|| "undef".to_string());
                                    arm_values.push((reg, self.current_label.clone()));
                                }
                                self.line(&format!("  br label %{}", end_label));
                            }
                            self.open_block(&next_label);
                            current_label = next_label.clone();
                        }
                        Pattern::Struct(struct_name, bindings) => {
                            // A struct pattern carries no tag to test, so it
                            // always matches: destructure each named field
                            // into a pointer binding via a direct GEP off the
                            // scrutinee's own storage (no bitcast needed,
                            // unlike a payload enum's shared payload buffer),
                            // then fall straight into the body like `Wildcard`.
                            let struct_ty = format!("%{}", struct_name);
                            let field_tys = self.struct_field_types.get(struct_name).cloned().unwrap_or_default();
                            let mut bound = 0usize;
                            for (fi, bind_name) in bindings.iter().enumerate() {
                                let field_gep = self.tmp_name();
                                self.line(&format!(
                                    "  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}",
                                    field_gep, struct_ty, struct_ty, scrut_ptr, fi as u32
                                ));
                                let fty = field_tys.get(fi).cloned().unwrap_or(Ty::Named("unknown".into()));
                                self.symbols.push((bind_name.clone(), field_gep, fty));
                                bound += 1;
                            }
                            self.push_scope();
                            let val = self.emit_stmts_value(&arm.body.stmts);
                            for _ in 0..bound {
                                self.symbols.pop();
                            }
                            let arm_terminates = Self::body_terminates(&arm.body.stmts);
                            self.pop_scope(!arm_terminates);
                            if !arm_terminates {
                                if produces_value {
                                    let reg = val.map(|v| self.reg_of(&v)).unwrap_or_else(|| "undef".to_string());
                                    // `self.current_label`, not the local
                                    // `current_label` (which only tracks
                                    // transitions *between* arms) -- this
                                    // arm's own body may have opened further
                                    // blocks while computing its trailing
                                    // value (see `Codegen::current_label`'s
                                    // doc comment).
                                    arm_values.push((reg, self.current_label.clone()));
                                }
                                self.line(&format!("  br label %{}", end_label));
                            }
                        }
                        Pattern::Wildcard => {
                            // A `_` arm discards the scrutinee entirely --
                            // for an RC-bearing scalar scrutinee (e.g. `str`,
                            // the only pattern kinds that ever type-check
                            // against one are `Wildcard`/`Binding`), `scrut_val`
                            // is still the one owned/retained value `emit_expr`
                            // produced above, and nothing else ever releases
                            // it (unlike `Pattern::Binding`, which now tracks
                            // its own spilled copy). Release it here, the same
                            // "balance the borrow back out" shape a discarded
                            // `Map`/`Set` key/element uses (`emit_release_bare`'s
                            // own doc comment). The `needs_scrut_ptr` case is a
                            // borrowed place, never retained, so nothing to do.
                            if !needs_scrut_ptr {
                                self.emit_release_bare(&scrut_val, &scrutinee_ty);
                            }
                            self.push_scope();
                            let val = self.emit_stmts_value(&arm.body.stmts);
                            let arm_terminates = Self::body_terminates(&arm.body.stmts);
                            self.pop_scope(!arm_terminates);
                            if !arm_terminates {
                                if produces_value {
                                    let reg = val.map(|v| self.reg_of(&v)).unwrap_or_else(|| "undef".to_string());
                                    arm_values.push((reg, self.current_label.clone()));
                                }
                                self.line(&format!("  br label %{}", end_label));
                            }
                        }
                        // `v -> ...` binds the *whole* scrutinee value to a
                        // fresh name and, like `Wildcard`, carries no tag to
                        // test -- an unconditional catch-all that runs in
                        // whatever block is already current. Needs a real
                        // storage pointer to register in `self.symbols`
                        // (every entry is a `(name, ptr, ty)` triple): reuse
                        // `scrut_ptr` directly when the scrutinee already has
                        // one (struct/payload-enum), otherwise spill the
                        // loaded `scrut_val` into a fresh alloca first.
                        Pattern::Binding(name) => {
                            self.push_scope();
                            let bind_ptr = if needs_scrut_ptr {
                                scrut_ptr.clone()
                            } else {
                                let bare = self.untag(&scrut_val, &scrutinee_ty);
                                let sty = self.llvm_ty(&scrutinee_ty);
                                let ptr = self.tmp_name();
                                self.line(&format!("  {} = alloca {}", ptr, sty));
                                self.line(&format!("  store {} {}, {}* {}", sty, bare, sty, ptr));
                                // `scrut_val` came from `self.emit_expr(scrutinee)`
                                // above, which already returned an owned
                                // (retained) value for an RC-bearing type --
                                // this spilled copy is that same owned value,
                                // not a borrow, so it must be released when
                                // this arm's scope ends (`Stmt::Let` tracks
                                // its spilled value identically). The
                                // `needs_scrut_ptr` branch above is a real
                                // borrow (a place into existing storage via
                                // `emit_place`, never retained), so it's
                                // deliberately left untracked.
                                self.track_owned(&ptr, &scrutinee_ty);
                                ptr
                            };
                            self.symbols.push((name.clone(), bind_ptr, scrutinee_ty.clone()));
                            let val = self.emit_stmts_value(&arm.body.stmts);
                            self.symbols.pop();
                            let arm_terminates = Self::body_terminates(&arm.body.stmts);
                            self.pop_scope(!arm_terminates);
                            if !arm_terminates {
                                if produces_value {
                                    let reg = val.map(|v| self.reg_of(&v)).unwrap_or_else(|| "undef".to_string());
                                    arm_values.push((reg, self.current_label.clone()));
                                }
                                self.line(&format!("  br label %{}", end_label));
                            }
                        }
                    }
                }
                if dangling_next_block {
                    // The last arm was a `Compare`/`EnumVariant`  with no
                    // trailing catch-all, so this final "next" block is the
                    // "no arm matched" case -- unreachable for a well-typed,
                    // exhaustive match, but still needs a value entry to keep
                    // the `phi` below well-formed (it must have exactly one
                    // entry per predecessor block that jumps to `end_label`).
                    if produces_value {
                        arm_values.push(("undef".to_string(), current_label.clone()));
                    }
                    self.line(&format!("  br label %{}", end_label));
                }
                self.open_block(&end_label);
                // If every arm terminates on its own (each ends in `return`/
                // `break`/`continue`), this join block is only ever reached
                // through the final "no arm matched" fallthrough of a
                // non-exhaustive dispatch, which can't happen for a
                // well-typed match; close it with `unreachable` rather than
                // leaving it open for a caller to append a value-producing
                // terminator to (there is no value to produce). Mirrors
                // `Codegen::body_terminates`'s `TypedExpr::Match` arm, which
                // tells callers to skip synthesizing their own terminator in
                // exactly this case.
                if !arms.is_empty() && arms.iter().all(|arm| Self::body_terminates(&arm.body.stmts)) {
                    self.line("  unreachable");
                    return "%undef".into();
                }
                if !produces_value || arm_values.is_empty() {
                    "%undef".into()
                } else {
                    let phi = self.tmp_name();
                    let incoming: Vec<String> = arm_values.iter()
                        .map(|(val, label)| format!("[ {}, %{} ]", val, label))
                        .collect();
                    self.line(&format!("  {} = phi {} {}", phi, ty_str, incoming.join(", ")));
                    format!("{} {}", ty_str, phi)
                }
            }
            TypedExpr::StructLit { name, args, ty, .. } => {
                match ty {
                    Ty::Vec2 | Ty::Vec3 | Ty::Vec4 => {
                        // No memory needed: build directly as an SSA vector value.
                        let mut acc = "undef".to_string();
                        for (i, a) in args.iter().enumerate() {
                            let av = self.emit_expr(a);
                            let aty = self.expr_ty(a);
                            let bare = self.promote_to_float(&av, &aty);
                            acc = self.insert_component(&acc, ty, i as u32, &bare);
                        }
                        format!("{} {}", self.llvm_ty(ty), acc)
                    }
                    Ty::Mat4 | Ty::Mat2 | Ty::Mat3 => {
                        // Args are `dim` row expressions of the matching
                        // vector type; pack each row into the
                        // `[dim x <dim x float>]` aggregate. Generalizes what
                        // used to be a `Mat4`-only literal case to `Mat2`/
                        // `Mat3` too -- see `Ty::Mat2`'s doc comment.
                        let dim = ty.mat_dim().expect("Mat2/Mat3/Mat4 all have a mat_dim");
                        let row_ty = Ty::vec_of_arity(dim as u8).expect("mat_dim is always 2, 3, or 4");
                        let row_llty = self.llvm_ty(&row_ty);
                        let mat_t = format!("[{} x {}]", dim, row_llty);
                        let mut acc = "undef".to_string();
                        for (i, a) in args.iter().enumerate() {
                            let av = self.emit_expr(a);
                            let row = self.untag(&av, &row_ty);
                            let next = self.tmp_name();
                            self.line(&format!("  {} = insertvalue {} {}, {} {}, {}", next, mat_t, acc, row_llty, row, i));
                            acc = next;
                        }
                        format!("{} {}", mat_t, acc)
                    }
                    // `Quat`/`Color` reuse `Vec4`'s exact construction --
                    // see their own `Ty` doc comments.
                    Ty::Quat | Ty::Color => {
                        let mut acc = "undef".to_string();
                        for (i, a) in args.iter().enumerate() {
                            let av = self.emit_expr(a);
                            let aty = self.expr_ty(a);
                            let bare = self.promote_to_float(&av, &aty);
                            acc = self.insert_component(&acc, ty, i as u32, &bare);
                        }
                        format!("{} {}", self.llvm_ty(ty), acc)
                    }
                    Ty::Tick | Ty::Duration | Ty::Instant => self.emit_time_new(&args[0]),
                    // `Bytes()` starts empty -- reuses `List<T>()`'s own
                    // "null object pointer" construction wholesale (see
                    // `Ty::Bytes`'s doc comment).
                    Ty::Bytes => self.emit_list_new(&Ty::U8),
                    // `Palette()` starts empty -- see `Ty::Palette`'s doc
                    // comment.
                    Ty::Palette => self.emit_list_new(&Ty::Color32),
                    // `Symbol(s)` interns `s` -- see `Ty::Symbol`'s doc
                    // comment and `crate::codegen::symbol`.
                    Ty::Symbol => self.emit_symbol_intern(&args[0]),
                    // `Color32(r, g, b, a)`/`PaletteIndex(value)` --
                    // `crate::codegen::geometry`.
                    Ty::Color32 => self.emit_color32_new(args),
                    Ty::PaletteIndex => self.emit_palette_index_new(&args[0]),
                    _ => {
                        let ptr = self.tmp_name();
                        self.line(&format!("  {} = alloca %{}", ptr, name));
                        for (i, a) in args.iter().enumerate() {
                            let val = self.emit_expr(a);
                            let gep = self.tmp_name();
                            let aty = self.expr_ty(a);
                            let ats = self.llvm_ty(&aty);
                            let clean_val = val.strip_prefix(&format!("{} ", ats)).unwrap_or(&val);
                            self.line(&format!("  {} = getelementptr inbounds %{}, %{}* {}, i32 0, i32 {}", gep, name, name, ptr, i as u32));
                            self.line(&format!("  store {} {}, {}* {}", ats, clean_val, ats, gep));
                        }
                        // Trailing fields the call site didn't supply are
                        // zero-initialized. This is what lets a `sequence`
                        // desugar to a struct whose `resume()` state and
                        // hoisted-local fields trail the constructor's own
                        // params: `Name(p1, p2)` only ever supplies `p1`/`p2`.
                        if let Some(field_tys) = self.struct_field_types.get(name).cloned() {
                            for (i, fty) in field_tys.iter().enumerate().skip(args.len()) {
                                let zero = self.zero_value(fty);
                                let fts = self.llvm_ty(fty);
                                let gep = self.tmp_name();
                                self.line(&format!("  {} = getelementptr inbounds %{}, %{}* {}, i32 0, i32 {}", gep, name, name, ptr, i as u32));
                                self.line(&format!("  store {} {}, {}* {}", fts, zero, fts, gep));
                            }
                        }
                        // Return the struct *value* (loaded from the alloca) so it can be
                        // stored into another aggregate or assigned, not the pointer.
                        let loaded = self.tmp_name();
                        self.line(&format!("  {} = load %{}, %{}* {}", loaded, name, name, ptr));
                        format!("%{} {}", name, loaded)
                    }
                }
            }
            TypedExpr::TupleLit { elems, ty, .. } => {
                // Mirrors `StructLit`'s generic (non-Vec/Mat4) branch above,
                // just against an anonymous literal struct type (no `%name`
                // to alloca) and with no trailing-field zero-fill -- a
                // tuple literal always supplies every element, unlike a
                // named struct constructor call that a `sequence` may
                // deliberately under-supply.
                let struct_ty = self.llvm_ty(ty);
                let ptr = self.tmp_name();
                self.line(&format!("  {} = alloca {}", ptr, struct_ty));
                for (i, e) in elems.iter().enumerate() {
                    let val = self.emit_expr(e);
                    let ety = self.expr_ty(e);
                    let ets = self.llvm_ty(&ety);
                    let clean_val = self.untag(&val, &ety);
                    let gep = self.tmp_name();
                    self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, struct_ty, struct_ty, ptr, i));
                    self.line(&format!("  store {} {}, {}* {}", ets, clean_val, ets, gep));
                }
                let loaded = self.tmp_name();
                self.line(&format!("  {} = load {}, {}* {}", loaded, struct_ty, struct_ty, ptr));
                format!("{} {}", struct_ty, loaded)
            }
            TypedExpr::FStr(parts, _, _) => {
                // Unlike `emit_print_like`'s special case for an f-string
                // passed directly as `print`/`println`'s sole argument (which
                // streams straight to `printf` and bakes in a trailing
                // newline), this is the general path for an f-string used as
                // an ordinary `str` value -- assigned, returned, passed to a
                // function, concatenated, nested inside another f-string,
                // etc. It must materialize an actual, fully-substituted,
                // owned `str` buffer (no trailing newline -- that's a
                // print/println-specific convention, not this value's).
                let mut fmt_str = String::new();
                // (value, llvm-type-for-the-vararg-slot) after any
                // widening/conversion `snprintf`'s varargs need.
                let mut call_args: Vec<String> = Vec::new();
                for part in parts {
                    match part {
                        TypedFStrExpr::Literal(lit) => {
                            fmt_str.push_str(&lit.replace("%", "%%"));
                        }
                        TypedFStrExpr::Expr(e) => {
                            let val = self.emit_expr(e);
                            let ty = self.expr_ty(e);
                            // A builtin vector/matrix aggregate has no single
                            // scalar format specifier -- see
                            // `emit_agg_fstring_lanes`'s doc comment (shared
                            // with `emit_print_like`'s identical up-front
                            // special case). Each lane is widened to `double`
                            // here directly (this path builds `call_args`
                            // inline in one pass, unlike `emit_print_like`'s
                            // two-pass `(val, Ty)` widening).
                            if ty.is_vec() || ty.is_mat() {
                                let bare_val = self.untag(&val, &ty);
                                let (frag, lanes) = self.emit_agg_fstring_lanes(&ty, &bare_val);
                                fmt_str.push_str(&frag);
                                for lane in lanes {
                                    let widened = self.tmp_name();
                                    self.line(&format!("  {} = fpext float {} to double", widened, lane));
                                    call_args.push(format!("double {}", widened));
                                }
                                continue;
                            }
                            // `Fixed<Bits,Frac>` has no format specifier of
                            // its own -- print it as a human-readable decimal
                            // via the same scaled-conversion the `as float`/
                            // `as f64` cast uses, reusing the `Ty::F64` arm
                            // below (mirrors `emit_print_like`'s identical
                            // handling).
                            let (val, ty) = if let Ty::Fixed(bits, frac) = ty {
                                let bare = self.untag(&val, &Ty::Fixed(bits, frac));
                                (self.emit_fixed_to_float(&bare, bits, frac, true), Ty::F64)
                            } else {
                                (val, ty)
                            };
                            let bare_val = self.untag(&val, &ty);
                            // Mirrors `emit_print_like`'s format-specifier/
                            // vararg-widening table (`builtins.rs`) -- this
                            // general (non-`print`/`println`) f-string path
                            // used to only special-case `Int`/`Float`/`Str`/
                            // `Bool` and silently fall every other numeric
                            // type (`I64` included) through the `%p`/`i8*`
                            // catch-all below, tagging a plain integer
                            // register as a pointer vararg -- a real
                            // `clang`/LLVM vararg type mismatch for e.g. an
                            // `i64` struct field interpolated into an
                            // f-string (`f"{e.id}"`).
                            match &ty {
                                Ty::Int | Ty::I8 | Ty::I16 => {
                                    fmt_str.push_str("%d");
                                    // C's variadic calling convention promotes
                                    // any integer type narrower than `int` up
                                    // to `int` -- `%d` reads a full 32-bit
                                    // slot off the varargs.
                                    if matches!(ty, Ty::I8 | Ty::I16) {
                                        let widened = self.tmp_name();
                                        self.line(&format!("  {} = sext {} {} to i32", widened, self.llvm_ty(&ty), bare_val));
                                        call_args.push(format!("i32 {}", widened));
                                    } else {
                                        call_args.push(format!("i32 {}", bare_val));
                                    }
                                }
                                // `PaletteIndex` lowers to a bare `u8` -- see
                                // its own `Ty` doc comment -- so it needs the
                                // exact same C variadic-promotion `U8`/`U16`
                                // need.
                                Ty::U8 | Ty::U16 | Ty::U32 | Ty::PaletteIndex => {
                                    fmt_str.push_str("%u");
                                    if matches!(ty, Ty::U8 | Ty::U16 | Ty::PaletteIndex) {
                                        let widened = self.tmp_name();
                                        self.line(&format!("  {} = zext {} {} to i32", widened, self.llvm_ty(&ty), bare_val));
                                        call_args.push(format!("i32 {}", widened));
                                    } else {
                                        call_args.push(format!("i32 {}", bare_val));
                                    }
                                }
                                // A bare unsigned `i32` packed color -- see
                                // `Ty::Color32`'s doc comment. Without this
                                // arm it fell through to the `%p` catch-all
                                // below, tagging a plain `i32` register as a
                                // pointer vararg -- a real `clang`/LLVM
                                // vararg type mismatch (confirmed: `f"{c}"`
                                // for a `Color32` local failed to compile
                                // with "defined with type 'i32' but expected
                                // 'ptr'" before this fix).
                                Ty::Color32 => {
                                    fmt_str.push_str("%u");
                                    call_args.push(format!("i32 {}", bare_val));
                                }
                                // All three lower to a bare signed `i64` --
                                // see `Ty::Tick`'s doc comment. `Symbol` is
                                // likewise a bare signed `i64` interned id --
                                // see `Ty::Symbol`'s doc comment.
                                Ty::I64 | Ty::Tick | Ty::Duration | Ty::Instant | Ty::Symbol => {
                                    fmt_str.push_str("%lld");
                                    call_args.push(format!("i64 {}", bare_val));
                                }
                                Ty::U64 => {
                                    fmt_str.push_str("%llu");
                                    call_args.push(format!("i64 {}", bare_val));
                                }
                                // Delegate to the inner integer type's own
                                // specifier/widening -- `Wrapping<T>` is the
                                // exact same LLVM value, just re-tagged (see
                                // `Ty::Wrapping`'s doc comment).
                                Ty::Wrapping(inner) => match inner.int_shape() {
                                    Some((64, true)) => {
                                        fmt_str.push_str("%lld");
                                        call_args.push(format!("i64 {}", bare_val));
                                    }
                                    Some((64, false)) => {
                                        fmt_str.push_str("%llu");
                                        call_args.push(format!("i64 {}", bare_val));
                                    }
                                    Some((w, signed)) if w < 32 => {
                                        fmt_str.push_str(if signed { "%d" } else { "%u" });
                                        let widened = self.tmp_name();
                                        let op = if signed { "sext" } else { "zext" };
                                        self.line(&format!("  {} = {} i{} {} to i32", widened, op, w, bare_val));
                                        call_args.push(format!("i32 {}", widened));
                                    }
                                    Some((_, signed)) => {
                                        fmt_str.push_str(if signed { "%d" } else { "%u" });
                                        call_args.push(format!("i32 {}", bare_val));
                                    }
                                    None => {
                                        fmt_str.push_str("%d");
                                        call_args.push(format!("i32 {}", bare_val));
                                    }
                                },
                                // A bare unsigned `i{N}` register -- see
                                // `Ty::BitField`'s doc comment. Same C
                                // variadic-promotion rule as the `U8`/`U16`
                                // arm above.
                                Ty::BitField(n) if *n < 32 => {
                                    fmt_str.push_str("%u");
                                    let widened = self.tmp_name();
                                    self.line(&format!("  {} = zext i{} {} to i32", widened, n, bare_val));
                                    call_args.push(format!("i32 {}", widened));
                                }
                                Ty::BitField(32) => {
                                    fmt_str.push_str("%u");
                                    call_args.push(format!("i32 {}", bare_val));
                                }
                                Ty::BitField(_) => {
                                    fmt_str.push_str("%llu");
                                    call_args.push(format!("i64 {}", bare_val));
                                }
                                // A bare unsigned `i64` bitmask -- see
                                // `Ty::Flags`'s doc comment.
                                Ty::Flags(_) => {
                                    fmt_str.push_str("%llu");
                                    call_args.push(format!("i64 {}", bare_val));
                                }
                                Ty::Float => {
                                    fmt_str.push_str("%f");
                                    // Variadic calls always promote `float` to `double`.
                                    let widened = self.tmp_name();
                                    self.line(&format!("  {} = fpext float {} to double", widened, bare_val));
                                    call_args.push(format!("double {}", widened));
                                }
                                Ty::F64 => {
                                    fmt_str.push_str("%f");
                                    call_args.push(format!("double {}", bare_val));
                                }
                                Ty::Char => {
                                    fmt_str.push_str("%c");
                                    call_args.push(format!("i32 {}", bare_val));
                                }
                                Ty::Str => {
                                    fmt_str.push_str("%s");
                                    // This hole only reads the bytes for
                                    // `snprintf`, it doesn't keep the
                                    // pointer around -- release whatever
                                    // `emit_expr(e)` left us owning, same
                                    // reasoning as
                                    // `emit_print_like`/`emit_raw_str_ptr`
                                    // (see `rc.rs`'s module doc comment for
                                    // why this is unconditional).
                                    self.line(&format!("  call void @star_rc_release(i8* {})", bare_val));
                                    call_args.push(format!("i8* {}", bare_val));
                                }
                                Ty::Bool => {
                                    fmt_str.push_str("%s");
                                    let bool_str = self.emit_bool_str(&bare_val);
                                    call_args.push(format!("i8* {}", bool_str));
                                }
                                // A fieldless enum's `i32` discriminant has
                                // no format specifier of its own -- printed
                                // as its variant's *name* instead, same as
                                // `emit_print_like`'s identical `Ty::Enum`
                                // handling (`projects/snake/NOTES.md`
                                // section 1.5; this path previously fell
                                // through to the `%p` catch-all below, same
                                // bug, different f-string call site).
                                Ty::Enum(enum_name) => {
                                    fmt_str.push_str("%s");
                                    let variant_str = self.emit_enum_variant_name(enum_name, &bare_val);
                                    call_args.push(format!("i8* {}", variant_str));
                                }
                                _ => {
                                    fmt_str.push_str("%p");
                                    // Same reasoning as the `Str` arm above:
                                    // this hole only prints `bare_val`'s raw
                                    // address, it doesn't keep the value
                                    // around, so whatever `emit_expr(e)` left
                                    // us owning must be released -- generalized
                                    // to any RC-bearing type (`List`/`Map`/
                                    // `Set`/`Closure`/struct/payload enum) via
                                    // `emit_release_bare`, since (unlike
                                    // `Str`) there's no single flat pointer to
                                    // release directly here.
                                    self.emit_release_bare(&bare_val, &ty);
                                    call_args.push(format!("i8* {}", bare_val));
                                }
                            }
                        }
                    }
                }
                let g = self.global_name();
                let escaped = fmt_str.replace("\\", "\\\\").replace("\"", "\\22").replace("\n", "\\0A");
                self.global_defs.push(format!("{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"", g, fmt_str.len() + 1, escaped));

                let fmt_reg = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", fmt_reg, fmt_str.len() + 1, fmt_str.len() + 1, g));

                let args_suffix = if call_args.is_empty() { String::new() } else { format!(", {}", call_args.join(", ")) };
                // First pass: `snprintf(null, 0, fmt, ...)` returns the
                // number of bytes the fully-substituted string would need
                // (excluding the NUL), per C99 -- sizes the real buffer
                // without guessing or growing.
                let needed = self.tmp_name();
                self.line(&format!("  {} = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* {}{})", needed, fmt_reg, args_suffix));
                let total = self.tmp_name();
                self.line(&format!("  {} = add i32 {}, 1", total, needed));
                let total64 = self.tmp_name();
                self.line(&format!("  {} = sext i32 {} to i64", total64, total));
                let buf = self.tmp_name();
                self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* null)", buf, total64));
                self.line(&format!("  call i32 (i8*, i64, i8*, ...) @snprintf(i8* {}, i64 {}, i8* {}{})", buf, total64, fmt_reg, args_suffix));
                buf
            }
            TypedExpr::If { cond, then_block, else_block, ty, .. } => {
                let ty_str = self.llvm_ty(ty);
                if ty_str == "void" {
                    // A value-less `if` (used for side effects): run both blocks
                    // without a phi merge, returning `%undef` as a value.
                    let cond_val = self.emit_expr(cond);
                    let cond_reg = self.reg_of(&cond_val);
                    let then_label = self.block_label("if_then");
                    let else_label = self.block_label("if_else");
                    let end_label = self.block_label("if_end");
                    self.line(&format!("  br i1 {}, label %{}, label %{}", cond_reg, then_label, else_label));
                    self.open_block(&then_label);
                    self.emit_block_value(then_block);
                    self.line(&format!("  br label %{}", end_label));
                    self.open_block(&else_label);
                    if let Some(else_b) = else_block {
                        self.emit_block_value(else_b);
                    }
                    self.line(&format!("  br label %{}", end_label));
                    self.open_block(&end_label);
                    "%undef".into()
                } else {
                    // A value-producing `if`: each branch computes its trailing
                    // expression value, then a `phi` merges them at the end.
                    let cond_val = self.emit_expr(cond);
                    let cond_reg = self.reg_of(&cond_val);
                    let then_label = self.block_label("if_then");
                    let else_label = self.block_label("if_else");
                    let end_label = self.block_label("if_end");
                    self.line(&format!("  br i1 {}, label %{}, label %{}", cond_reg, then_label, else_label));
                    self.open_block(&then_label);
                    let then_val = self.emit_block_value(then_block);
                    let then_reg = then_val.map(|v| self.reg_of(&v)).unwrap_or_else(|| "%undef".to_string());
                    // The block actually falling through to `end_label` isn't
                    // necessarily `then_label` itself anymore: evaluating the
                    // branch's trailing value may have opened further blocks
                    // of its own (a short-circuit `&&`/`||`, a list/`GenRef`
                    // index bounds check, a nested `if`/`match`, a `frame:`
                    // allocation, ...). `current_label` (updated by every
                    // `open_block` call, including ones nested inside
                    // `emit_block_value` above) names whichever block is
                    // actually current right now -- using the stale
                    // `then_label` here instead produced invalid LLVM IR
                    // ("PHI node entries do not match predecessors") for any
                    // branch value more complex than a literal/simple binop.
                    let then_pred = self.current_label.clone();
                    self.line(&format!("  br label %{}", end_label));
                    self.open_block(&else_label);
                    let else_val = else_block.as_ref().and_then(|b| self.emit_block_value(b));
                    let else_reg = else_val.map(|v| self.reg_of(&v)).unwrap_or_else(|| "%undef".to_string());
                    let else_pred = self.current_label.clone();
                    self.line(&format!("  br label %{}", end_label));
                    self.open_block(&end_label);
                    let phi = self.tmp_name();
                    self.line(&format!("  {} = phi {} [ {}, %{} ], [ {}, %{} ]", phi, ty_str, then_reg, then_pred, else_reg, else_pred));
                    format!("{} {}", ty_str, phi)
                }
            }
            TypedExpr::Spawn { arena, elem, .. } => self.emit_spawn_expr(arena, elem),
            TypedExpr::GenRefCreate { inner_ty, value, span, .. } => self.emit_genref_create(inner_ty, value, *span),
            TypedExpr::GenRefIndex { base, ty, span, .. } => self.emit_genref_index(base, ty, *span),
            TypedExpr::EnumVariant { enum_name, variant, args, .. } => {
                let idx = self.enum_variant_index(enum_name, variant);
                if !self.enum_is_payload(enum_name) {
                    return format!("i32 {}", idx);
                }
                // Payload variant construction: alloca the tagged-union
                // struct, store the discriminant, then bitcast the shared
                // `[W x i64]` payload buffer to this variant's own field
                // layout and store each argument (mirroring `StructLit`'s
                // alloca+GEP+store shape below).
                let enum_ty = format!("%{}", enum_name);
                let ptr = self.tmp_name();
                self.line(&format!("  {} = alloca {}", ptr, enum_ty));
                let tag_gep = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", tag_gep, enum_ty, enum_ty, ptr));
                self.line(&format!("  store i32 {}, i32* {}", idx, tag_gep));
                if !args.is_empty() {
                    let words = self.enum_payload_words(enum_name);
                    let elem = self.enum_payload_elem_ty(enum_name);
                    let payload_gep = self.tmp_name();
                    self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", payload_gep, enum_ty, enum_ty, ptr));
                    let variant_ty = self.enum_variant_payload_llvm_ty(enum_name, idx);
                    let variant_ptr = self.tmp_name();
                    self.line(&format!("  {} = bitcast [{} x {}]* {} to {}*", variant_ptr, words, elem, payload_gep, variant_ty));
                    for (i, a) in args.iter().enumerate() {
                        let val = self.emit_expr(a);
                        let aty = self.expr_ty(a);
                        let ats = self.llvm_ty(&aty);
                        let clean_val = self.untag(&val, &aty);
                        let field_gep = self.tmp_name();
                        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", field_gep, variant_ty, variant_ty, variant_ptr, i as u32));
                        self.line(&format!("  store {} {}, {}* {}", ats, clean_val, ats, field_gep));
                    }
                }
                let loaded = self.tmp_name();
                self.line(&format!("  {} = load {}, {}* {}", loaded, enum_ty, enum_ty, ptr));
                format!("{} {}", enum_ty, loaded)
            }
            TypedExpr::Closure { params, body, ty, .. } => self.emit_closure_lit(params, body, ty),
            TypedExpr::ListNew { elem_ty, .. } => self.emit_list_new(elem_ty),
            TypedExpr::ListLit { elems, elem_ty, .. } => self.emit_list_lit(elems, elem_ty),
            TypedExpr::ListIndex { base, index, ty, .. } => self.emit_list_index(base, index, ty),
            TypedExpr::StrIndex { base, index, .. } => self.emit_str_index(base, index),
            TypedExpr::ListMethod { base, method, args, .. } => {
                // `ty` on this node is the *method's return type* (`i32` for
                // `len`, the element type for `pop`, `unknown` for `push`),
                // not the list's element type codegen needs to know its
                // memory layout -- recover that from `base`'s own type.
                let elem_ty = match self.expr_ty(base) {
                    Ty::List(inner) => *inner,
                    // `Bytes` reuses `List<u8>`'s method codegen wholesale --
                    // see `Ty::Bytes`'s doc comment.
                    Ty::Bytes => Ty::U8,
                    // `Palette` reuses `List<Color32>`'s method codegen
                    // wholesale -- see `Ty::Palette`'s doc comment.
                    Ty::Palette => Ty::Color32,
                    other => { self.err("internal error: list method receiver is not a List<T>", Span::dummy()); other }
                };
                self.emit_list_method(base, *method, args, &elem_ty)
            }
            TypedExpr::MapNew { key_ty, val_ty, .. } => self.emit_map_new(key_ty, val_ty),
            TypedExpr::SetNew { elem_ty, .. } => self.emit_set_new(elem_ty),
            TypedExpr::TableNew { elem_ty, .. } => self.emit_table_new(elem_ty),
            TypedExpr::TableIndex { base, index, ty, .. } => self.emit_table_index(base, index, ty),
            TypedExpr::TableMethod { base, method, args, .. } => {
                // `ty` on this node is the *method's return type*, not the
                // table's element type codegen needs to know its column
                // layout -- recover that from `base`'s own type, mirroring
                // `ListMethod`'s identical dispatch just above.
                let elem_ty = match self.expr_ty(base) {
                    Ty::Table(inner) => *inner,
                    other => { self.err("internal error: table method receiver is not a Table<T>", Span::dummy()); other }
                };
                self.emit_table_method(base, *method, args, &elem_ty)
            }
            TypedExpr::MapMethod { base, method, args, ty, .. } => {
                let (key_ty, val_ty) = match self.expr_ty(base) {
                    Ty::Map(k, v) => (*k, *v),
                    other => { self.err("internal error: map method receiver is not a Map<K,V>", Span::dummy()); (other, Ty::Int) }
                };
                self.emit_map_method(base, *method, args, &key_ty, &val_ty, ty)
            }
            TypedExpr::SetMethod { base, method, args, .. } => {
                let elem_ty = match self.expr_ty(base) {
                    Ty::Set(inner) => *inner,
                    other => { self.err("internal error: set method receiver is not a Set<T>", Span::dummy()); other }
                };
                self.emit_set_method(base, *method, args, &elem_ty)
            }
            TypedExpr::Error(_) => "%undef".into(),
        }
    }
}
