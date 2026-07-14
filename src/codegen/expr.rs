//! Expression emission: the central `emit_expr` dispatcher, call lowering,
//! and GLSL-style swizzle read/write.

use crate::ast::*;
use crate::diagnostics::Span;
use crate::types::*;

use super::{format_f32_literal, Codegen};

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
        let call_args: Vec<String> = args.iter().map(|a| {
            let ty = self.expr_ty(a);
            if ty == Ty::Str {
                format!("i8* {}", self.emit_raw_str_ptr(a))
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
        if ret_ty == "void" {
            self.line(&format!("  call void @{}({})", name, call_args.join(", ")));
            "%undef".into()
        } else {
            let ret = self.tmp_name();
            self.line(&format!("  {} = call {} @{}({})", ret, ret_ty, name, call_args.join(", ")));
            format!("{} {}", ret_ty, ret)
        }
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
            TypedExpr::Int(v, _, _) => format!("i32 {}", v),
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
                reg
            }
            TypedExpr::SelfExpr(ty, _) => {
                let ptr = self.sym_ptr("self").unwrap_or_else(|| "%undef".into());
                let reg = self.tmp_name();
                let struct_ty = match ty {
                    Ty::Named(n) => format!("%{}", n),
                    _ => self.llvm_ty(&ty),
                };
                self.line(&format!("  {} = load {}*, {}** {}", reg, struct_ty, struct_ty, ptr));
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
                // an independent copy of its value.
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
                    Some("min") => self.emit_minmax(args, true),
                    Some("max") => self.emit_minmax(args, false),
                    Some("len") => self.emit_str_len(args),
                    Some("concat") => self.emit_str_concat(args),
                    Some("chr") => self.emit_chr(args),
                    Some("ord") => self.emit_ord(args),
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
                // `emit_expr` returns literals already tagged with their
                // LLVM type (e.g. `i32 5`) but loads/calls bare; strip any
                // existing tag so the opcode below never double-tags it.
                let bare = self.untag(&o, &operand_ty);
                let reg = self.tmp_name();
                match op {
                    UnOp::Neg => {
                        if matches!(operand_ty, Ty::Float) {
                            self.line(&format!("  {} = fsub float 0.0, {}", reg, bare));
                        } else {
                            self.line(&format!("  {} = sub i32 0, {}", reg, bare));
                        }
                    }
                    UnOp::Not => self.line(&format!("  {} = xor i1 true, {}", reg, bare)),
                }
                reg
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
                            let cmp = self.tmp_name();
                            self.line(&format!("  {} = icmp eq i32 {}, {}", cmp, scrut_val, v));
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
                            let rhs_val = match rhs.as_ref() {
                                Expr::Int(v, _) => format!("i32 {}", v),
                                // A negative literal (`<= -5`) parses as a
                                // unary negation of an int literal, not an
                                // `Expr::Int` directly (the lexer/parser have
                                // no negative-literal token) -- fold it here
                                // so this is still a compile-time constant
                                // rather than falling into the "unsupported"
                                // error below for perfectly ordinary syntax.
                                Expr::Unary { op: UnOp::Neg, operand, .. } => match operand.as_ref() {
                                    Expr::Int(v, _) => format!("i32 {}", -v),
                                    _ => { self.err("unsupported match rhs expression", Span::dummy()); "i32 0".into() }
                                },
                                _ => { self.err("unsupported match rhs expression", Span::dummy()); "i32 0".into() }
                            };
                            let cmp = self.tmp_name();
                            let llvm_op = match op {
                                BinOp::Le => "icmp sle",
                                BinOp::Ge => "icmp sge",
                                BinOp::Lt => "icmp slt",
                                BinOp::Gt => "icmp sgt",
                                BinOp::Eq => "icmp eq",
                                BinOp::Ne => "icmp ne",
                                _ => "icmp eq",
                            };
                            let rhs_val_clean = rhs_val.strip_prefix("i32 ").unwrap_or(&rhs_val);
                            self.line(&format!("  {} = {} i32 {}, {}", cmp, llvm_op, scrut_val, rhs_val_clean));
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
                                let payload_gep = self.tmp_name();
                                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", payload_gep, enum_ty, enum_ty, scrut_ptr));
                                let variant_ty = self.enum_variant_payload_llvm_ty(enum_name, idx);
                                let variant_ptr = self.tmp_name();
                                self.line(&format!("  {} = bitcast [{} x i64]* {} to {}*", variant_ptr, words, payload_gep, variant_ty));
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
                    Ty::Mat4 => {
                        // Args are 4 Vec4-typed row expressions; pack each row into
                        // the `[4 x <4 x float>]` aggregate.
                        let mat_t = "[4 x <4 x float>]";
                        let mut acc = "undef".to_string();
                        for (i, a) in args.iter().enumerate() {
                            let av = self.emit_expr(a);
                            let row = self.untag(&av, &Ty::Vec4);
                            let next = self.tmp_name();
                            self.line(&format!("  {} = insertvalue {} {}, <4 x float> {}, {}", next, mat_t, acc, row, i));
                            acc = next;
                        }
                        format!("{} {}", mat_t, acc)
                    }
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
                            let bare_val = self.untag(&val, &ty);
                            match ty {
                                Ty::Int => {
                                    fmt_str.push_str("%d");
                                    call_args.push(format!("i32 {}", bare_val));
                                }
                                Ty::Float => {
                                    fmt_str.push_str("%f");
                                    // Variadic calls always promote `float` to `double`.
                                    let widened = self.tmp_name();
                                    self.line(&format!("  {} = fpext float {} to double", widened, bare_val));
                                    call_args.push(format!("double {}", widened));
                                }
                                Ty::Str => {
                                    fmt_str.push_str("%s");
                                    // This hole only reads the bytes for
                                    // `snprintf`, it doesn't keep the
                                    // pointer around -- balance back out
                                    // whatever retain `emit_expr(e)` did on
                                    // `e`'s behalf (a no-op if `e` was a
                                    // fresh construction), same reasoning as
                                    // `emit_print_like`/`emit_raw_str_ptr`.
                                    if Self::is_rc_borrowing_read(e) {
                                        self.line(&format!("  call void @star_rc_release(i8* {})", bare_val));
                                    }
                                    call_args.push(format!("i8* {}", bare_val));
                                }
                                Ty::Bool => {
                                    fmt_str.push_str("%s");
                                    let bool_str = self.emit_bool_str(&bare_val);
                                    call_args.push(format!("i8* {}", bool_str));
                                }
                                _ => {
                                    fmt_str.push_str("%p");
                                    // Same reasoning as the `Str` arm above:
                                    // this hole only prints `bare_val`'s raw
                                    // address, it doesn't keep the value
                                    // around, so whatever retain `emit_expr(e)`
                                    // did on `e`'s behalf must be balanced
                                    // back out -- generalized to any
                                    // RC-bearing type (`List`/`Map`/`Set`/
                                    // `Closure`/struct/payload enum) via
                                    // `emit_release_bare`, since (unlike
                                    // `Str`) there's no single flat pointer to
                                    // release directly here. Previously
                                    // missing entirely, this leaked one
                                    // reference per interpolation of any such
                                    // value.
                                    if Self::is_rc_borrowing_read(e) {
                                        self.emit_release_bare(&bare_val, &ty);
                                    }
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
                    let payload_gep = self.tmp_name();
                    self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", payload_gep, enum_ty, enum_ty, ptr));
                    let variant_ty = self.enum_variant_payload_llvm_ty(enum_name, idx);
                    let variant_ptr = self.tmp_name();
                    self.line(&format!("  {} = bitcast [{} x i64]* {} to {}*", variant_ptr, words, payload_gep, variant_ty));
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
