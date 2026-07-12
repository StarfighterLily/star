//! Closure/lambda codegen: capture-by-value environment construction, the
//! deferred top-level function a closure literal's body lowers to, and the
//! indirect-call codegen a closure *value* is invoked through.
//!
//! A closure value is a fixed-shape "fat pointer" `{ i8* fn_ptr, i8* env_ptr }`
//! (see `Codegen::llvm_ty`'s `Ty::Closure` arm). Every local visible at a
//! lambda literal's definition site (`self.symbols`, exactly like
//! `Codegen::emit_par_stmt`'s capture snapshot) is captured *by value* into a
//! heap-allocated (`malloc`'d, never freed) environment struct -- not by
//! pointer into the current stack frame, unlike `par`. `par` can get away
//! with pointer capture only because it blocks (`WaitForSingleObject`)
//! before returning, so the captured stack frame is guaranteed to still be
//! alive for the whole time any worker thread might dereference it. A
//! closure has no such guarantee: it can be returned from the function that
//! created it, stored, and called long after that stack frame is gone, so
//! capturing by value (copying each variable's current value into
//! independent heap memory) is what makes an escaping closure safe here.

use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

impl Codegen {
    /// The LLVM type of one captured variable's *value* (what you get after
    /// exactly one load from its `sym_ptr`), used both for the environment
    /// struct's field type and for the type of the local alloca a closure
    /// body reconstructs on entry. `self` is special: its `Ty` is the
    /// receiver struct's own type, but its runtime representation is always
    /// a pointer to that struct (see `Codegen::sym_ptr_llvm_ty`), so its
    /// captured "value" is that pointer, not the struct itself -- capturing
    /// it by value still just copies the pointer (a shallow copy of a
    /// reference), which is the correct, ordinary behavior.
    fn captured_value_llvm_ty(&self, name: &str, ty: &Ty) -> String {
        if name == "self" {
            format!("{}*", self.llvm_ty(ty))
        } else {
            self.llvm_ty(ty)
        }
    }

    /// A closure's return type as an LLVM type, treating the `unknown`
    /// placeholder (a body with no trailing value, see
    /// `Checker::infer_expr`'s `Expr::Lambda` arm) as `void` -- the same
    /// convention `emit_call_expr` already uses for ordinary function calls.
    fn closure_ret_llvm(&self, ret_ty: &Ty) -> String {
        match ret_ty {
            Ty::Named(n) if n == "unknown" => "void".into(),
            other => self.llvm_ty(other),
        }
    }

    /// Emit a closure literal: a deferred top-level function for its body
    /// (pushed onto `self.pending_top`, spliced into the module once every
    /// ordinary item has been emitted -- see `Codegen::emit`) plus, at the
    /// definition site, the environment snapshot and `{ fn_ptr, env_ptr }`
    /// value construction. Returns that value, tagged with its LLVM type
    /// (mirroring every other aggregate-producing `emit_expr` arm).
    pub(super) fn emit_closure_lit(&mut self, params: &[TypedParam], body: &TypedBlock, ty: &Ty) -> String {
        let (param_tys, ret_ty) = match ty {
            Ty::Closure(p, r) => (p.clone(), (**r).clone()),
            _ => {
                self.err("internal error: closure literal without a closure type", Span::dummy());
                return "%undef".into();
            }
        };

        let id = self.block_id;
        self.block_id += 1;
        let fn_name = format!("closure_{}", id);

        let captured: Vec<(String, String, Ty)> = self.symbols.clone();
        let env_field_tys: Vec<String> = captured.iter().map(|(name, _, cty)| self.captured_value_llvm_ty(name, cty)).collect();
        let env_ty = format!("{{ {} }}", env_field_tys.join(", "));
        let ret_llvm = self.closure_ret_llvm(&ret_ty);

        // --- the closure body, as a deferred top-level function ---
        let saved_ir = std::mem::take(&mut self.ir);
        let saved_symbols = std::mem::take(&mut self.symbols);
        let saved_owned_stack = std::mem::take(&mut self.owned_stack);
        let saved_in_frame = self.in_frame;
        self.in_frame = false; // the frame bump allocator's offset is a single shared global, scoped to the defining call, not a detached closure body
        // A closure literal is its own independent LLVM function with its
        // own (possibly non-`i32`, possibly void) return type -- a bare
        // `return` inside its body must lower to that function's own
        // convention, never `main`'s forced `ret i32 0`, even when the
        // closure is defined lexically inside `main`'s body.
        let saved_in_main = self.in_main;
        self.in_main = false;

        self.write(&format!("define {} @{}(i8* %envp", ret_llvm, fn_name));
        for p in params {
            self.write(&format!(", {} %arg_{}", self.llvm_ty(&p.ty), p.name));
        }
        self.line(") {");
        self.line("entry:");
        self.push_scope();

        if !captured.is_empty() {
            let env_ptr = self.tmp_name();
            self.line(&format!("  {} = bitcast i8* %envp to {}*", env_ptr, env_ty));
            for (i, (name, _, cty)) in captured.iter().enumerate() {
                let field_ty = self.captured_value_llvm_ty(name, cty);
                let field_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", field_ptr, env_ty, env_ty, env_ptr, i));
                let loaded = self.tmp_name();
                self.line(&format!("  {} = load {}, {}* {}", loaded, field_ty, field_ty, field_ptr));
                // Reconstruct the ordinary "pointer to storage" convention
                // every other local uses (`sym_ptr_llvm_ty`): an alloca of
                // the value type, holding this captured copy.
                let local_ptr = self.tmp_name();
                self.line(&format!("  {} = alloca {}", local_ptr, field_ty));
                self.line(&format!("  store {} {}, {}* {}", field_ty, loaded, field_ty, local_ptr));
                // Deliberately never `track_owned` here, for *every* captured
                // variable, not just `self`: the environment already holds
                // exactly one retained reference per RC-bearing capture (see
                // `emit_closure_lit`'s env-population loop below), released
                // exactly once -- via the generated `..._release_env` thunk
                // -- when the environment's own refcount reaches zero. This
                // reconstructed `local_ptr` is only a *borrowed* view into
                // that single owned reference for the duration of one call,
                // not a fresh owner of its own; nothing here retained a new
                // reference on this call's behalf. Previously every captured
                // field *other than* `self` was `track_owned`'d exactly like
                // an ordinary local, so `pop_scope`'s normal end-of-body
                // release ran on it too -- over-releasing the *same* single
                // reference once per call to the closure (not once total),
                // hitting zero and freeing the environment while other
                // owners (the original binding, another closure that also
                // captured it, ...) still held it, then double-freeing (or
                // corrupting the heap) once those other owners were released
                // in turn. Confirmed as a real Windows STATUS_HEAP_CORRUPTION
                // crash: a closure capturing another RC-bearing closure,
                // called even once, corrupted the heap the moment either
                // one's last reference was later released.
                self.symbols.push((name.clone(), local_ptr, cty.clone()));
            }
        }

        for p in params {
            let ptr_ty = self.llvm_ty(&p.ty);
            let alloca = self.tmp_name();
            self.line(&format!("  {} = alloca {}", alloca, ptr_ty));
            self.line(&format!("  store {} %arg_{}, {}* {}", ptr_ty, p.name, ptr_ty, alloca));
            self.track_owned(&alloca, &p.ty);
            self.symbols.push((p.name.clone(), alloca, p.ty.clone()));
        }

        let terminated = Self::body_terminates(&body.stmts);
        let trailing_val = self.emit_stmts_value(&body.stmts);
        self.pop_scope(!terminated);
        if !terminated {
            if ret_llvm == "void" {
                self.line("  ret void");
            } else {
                match trailing_val {
                    Some(v) => {
                        let clean = v.strip_prefix(&format!("{} ", ret_llvm)).unwrap_or(&v).to_string();
                        self.line(&format!("  ret {} {}", ret_llvm, clean));
                    }
                    None => {
                        self.err("closure body must end in a value-producing expression or explicit return", Span::dummy());
                        self.line(&format!("  ret {} undef", ret_llvm));
                    }
                }
            }
        }
        self.line("}");
        self.line("");

        let fn_ir = std::mem::replace(&mut self.ir, saved_ir);
        self.pending_top.push(fn_ir);
        self.symbols = saved_symbols;
        self.owned_stack = saved_owned_stack;
        self.in_frame = saved_in_frame;
        self.in_main = saved_in_main;

        // --- back at the definition site: snapshot captures by value into a
        // heap-allocated environment, then pack `{ fn_ptr, env_ptr }`. ---
        let env_i8 = if captured.is_empty() {
            "null".to_string()
        } else {
            // The classic LLVM "sizeof" idiom: GEP one past a null pointer of
            // the target type, then ptrtoint -- gives the type's exact
            // (alignment-correct) byte size straight from LLVM's own layout,
            // rather than manually summing field sizes (which could
            // undercount padding for a heterogeneous struct like this one).
            let size_gep = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* null, i32 1", size_gep, env_ty, env_ty));
            let size = self.tmp_name();
            self.line(&format!("  {} = ptrtoint {}* {} to i64", size, env_ty, size_gep));
            // If any captured field owns RC content of its own (e.g. a `str`
            // captured by value), that reference would otherwise leak
            // forever once this environment block is finally released --
            // `self` is excluded, it's captured *by pointer* (a borrow, see
            // `captured_value_llvm_ty`), not an owned copy. Generate a
            // dedicated per-closure-literal thunk that releases just those
            // fields, and hand it to `star_rc_alloc` as this block's nested
            // cleanup callback (see `Codegen::emit_rc_runtime`).
            let rc_fields: Vec<(usize, Ty)> = captured.iter().enumerate()
                .filter(|(_, (name, _, cty))| name != "self" && self.contains_rc(cty))
                .map(|(i, (_, _, cty))| (i, cty.clone()))
                .collect();
            let release_fn_operand = if rc_fields.is_empty() {
                "null".to_string()
            } else {
                let release_fn_name = format!("closure_{}_release_env", id);
                let saved_ir2 = std::mem::take(&mut self.ir);
                self.line(&format!("define void @{}(i8* %envp) {{", release_fn_name));
                self.line("entry:");
                let env_ptr2 = self.tmp_name();
                self.line(&format!("  {} = bitcast i8* %envp to {}*", env_ptr2, env_ty));
                for (i, fty) in &rc_fields {
                    let gep = self.tmp_name();
                    self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, env_ty, env_ty, env_ptr2, i));
                    self.emit_release_at(&gep, fty);
                }
                self.line("  ret void");
                self.line("}");
                self.line("");
                let fn_ir2 = std::mem::replace(&mut self.ir, saved_ir2);
                self.pending_top.push(fn_ir2);
                let reg = self.tmp_name();
                self.line(&format!("  {} = bitcast void (i8*)* @{} to i8*", reg, release_fn_name));
                reg
            };
            let raw = self.tmp_name();
            self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* {})", raw, size, release_fn_operand));
            let env_ptr = self.tmp_name();
            self.line(&format!("  {} = bitcast i8* {} to {}*", env_ptr, raw, env_ty));
            for (i, (name, _, cty)) in captured.iter().enumerate() {
                let field_ty = self.captured_value_llvm_ty(name, cty);
                let synthetic = if name == "self" {
                    TypedExpr::SelfExpr(cty.clone(), Span::dummy())
                } else {
                    TypedExpr::Ident { name: name.clone(), ty: cty.clone(), span: Span::dummy() }
                };
                let val = self.emit_expr(&synthetic);
                let bare = val.strip_prefix(&format!("{} ", field_ty)).unwrap_or(&val).to_string();
                let field_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", field_ptr, env_ty, env_ty, env_ptr, i));
                self.line(&format!("  store {} {}, {}* {}", field_ty, bare, field_ty, field_ptr));
            }
            raw
        };

        let param_llvm: Vec<String> = param_tys.iter().map(|t| self.llvm_ty(t)).collect();
        let fnptr_ty = format!(
            "{} (i8*{})*",
            ret_llvm,
            if param_llvm.is_empty() { String::new() } else { format!(", {}", param_llvm.join(", ")) }
        );
        let fnptr_i8 = self.tmp_name();
        self.line(&format!("  {} = bitcast {} @{} to i8*", fnptr_i8, fnptr_ty, fn_name));

        let acc1 = self.tmp_name();
        self.line(&format!("  {} = insertvalue {{ i8*, i8* }} undef, i8* {}, 0", acc1, fnptr_i8));
        let acc2 = self.tmp_name();
        self.line(&format!("  {} = insertvalue {{ i8*, i8* }} {}, i8* {}, 1", acc2, acc1, env_i8));
        format!("{{ i8*, i8* }} {}", acc2)
    }

    /// Emit a plain top-level function *name* used as a first-class value
    /// (passed as an argument, `let`-bound, stored in a field, ...) rather
    /// than called directly -- the checker widens its type to
    /// `Ty::Closure` (see `Checker::fn_value_ty`) so it can flow anywhere a
    /// lambda value can, but the underlying `@name` function was emitted by
    /// `emit_fn` with the ordinary (no `i8* %envp` prefix) signature every
    /// direct call uses. Bitcasting `@name` itself to the `(i8*, args...)*`
    /// shape a closure call expects would silently misalign every argument
    /// (the callee would read the caller's env-pointer argument as its first
    /// real parameter), so instead a small thunk that drops the incoming
    /// envp and forwards to `@name` is generated once per function name and
    /// reused -- the closure value's `fn_ptr` points at the thunk, `env_ptr`
    /// is `null` since there is nothing to capture.
    pub(super) fn emit_fn_value(&mut self, name: &str, param_tys: &[Ty], ret_ty: &Ty) -> String {
        let ret_llvm = self.closure_ret_llvm(ret_ty);
        let param_llvm: Vec<String> = param_tys.iter().map(|t| self.llvm_ty(t)).collect();

        let thunk_name = if let Some(existing) = self.fn_value_thunks.get(name) {
            existing.clone()
        } else {
            let thunk_name = format!("fnval_{}", name);

            let saved_ir = std::mem::take(&mut self.ir);
            let saved_symbols = std::mem::take(&mut self.symbols);
            let saved_in_frame = self.in_frame;
            self.in_frame = false;
            let saved_in_main = self.in_main;
            self.in_main = false;

            self.write(&format!("define {} @{}(i8* %envp", ret_llvm, thunk_name));
            for (i, ty) in param_llvm.iter().enumerate() {
                self.write(&format!(", {} %arg_{}", ty, i));
            }
            self.line(") {");
            self.line("entry:");
            let fwd_args: Vec<String> = param_llvm.iter().enumerate().map(|(i, ty)| format!("{} %arg_{}", ty, i)).collect();
            // The call site that produced this closure value (`emit_closure_call`)
            // retains each `str` argument before the call, on the assumption that
            // whatever gets called owns it and releases it once done -- true for
            // an ordinary Star function (its own `emit_fn`-generated body tracks
            // and releases its params at scope exit) but not for an `extern "C"
            // fn`: `@name` here is a bodyless `declare`, so nothing on the other
            // side of this thunk ever calls `star_rc_release`. Release it here
            // instead, exactly once, after the forwarded call -- the same
            // retain-then-release-right-back balancing `emit_extern_call` already
            // does for a *direct* extern call (see its own doc comment); without
            // this, calling an extern fn through a first-class value (`let g =
            // some_extern_fn`) leaks one reference per `str` argument per call.
            let is_extern_target = self.extern_fns.contains(name);
            if ret_llvm == "void" {
                self.line(&format!("  call void @{}({})", name, fwd_args.join(", ")));
                if is_extern_target {
                    for (i, ty) in param_tys.iter().enumerate() {
                        if *ty == Ty::Str {
                            self.line(&format!("  call void @star_rc_release(i8* %arg_{})", i));
                        }
                    }
                }
                self.line("  ret void");
            } else {
                let reg = self.tmp_name();
                self.line(&format!("  {} = call {} @{}({})", reg, ret_llvm, name, fwd_args.join(", ")));
                if is_extern_target {
                    for (i, ty) in param_tys.iter().enumerate() {
                        if *ty == Ty::Str {
                            self.line(&format!("  call void @star_rc_release(i8* %arg_{})", i));
                        }
                    }
                }
                self.line(&format!("  ret {} {}", ret_llvm, reg));
            }
            self.line("}");
            self.line("");

            let fn_ir = std::mem::replace(&mut self.ir, saved_ir);
            self.pending_top.push(fn_ir);
            self.symbols = saved_symbols;
            self.in_frame = saved_in_frame;
            self.in_main = saved_in_main;

            self.fn_value_thunks.insert(name.to_string(), thunk_name.clone());
            thunk_name
        };

        let fnptr_ty = format!(
            "{} (i8*{})*",
            ret_llvm,
            if param_llvm.is_empty() { String::new() } else { format!(", {}", param_llvm.join(", ")) }
        );
        let fnptr_i8 = self.tmp_name();
        self.line(&format!("  {} = bitcast {} @{} to i8*", fnptr_i8, fnptr_ty, thunk_name));
        let acc1 = self.tmp_name();
        self.line(&format!("  {} = insertvalue {{ i8*, i8* }} undef, i8* {}, 0", acc1, fnptr_i8));
        let acc2 = self.tmp_name();
        self.line(&format!("  {} = insertvalue {{ i8*, i8* }} {}, i8* null, 1", acc2, acc1));
        format!("{{ i8*, i8* }} {}", acc2)
    }

    /// Emit an indirect call through a closure *value* (as opposed to
    /// `emit_call_expr`'s direct `call @name(...)` for a plain named
    /// function/method): unpack `{ fn_ptr, env_ptr }`, bitcast the raw
    /// `i8*` function pointer back to its real signature, and call it with
    /// the environment pointer prepended to the ordinary arguments.
    pub(super) fn emit_closure_call(&mut self, callee: &TypedExpr, args: &[TypedExpr], param_tys: &[Ty], ret_ty: &Ty) -> String {
        let closure_ty = Ty::Closure(param_tys.to_vec(), Box::new(ret_ty.clone()));
        let closure_val = self.emit_expr(callee);
        let bare = self.untag(&closure_val, &closure_ty);
        let fnptr_i8 = self.tmp_name();
        self.line(&format!("  {} = extractvalue {{ i8*, i8* }} {}, 0", fnptr_i8, bare));
        let envptr = self.tmp_name();
        self.line(&format!("  {} = extractvalue {{ i8*, i8* }} {}, 1", envptr, bare));
        // If `callee` reads an existing owned slot, `emit_expr` above
        // already retained a fresh reference to the closure's environment
        // on its behalf (see `rc.rs`) -- but *calling* a closure is a
        // transient use (unpack `fn_ptr`/`env_ptr`, call through, done),
        // not a new persistent owner, so that retain must be released
        // right back or every call through a bare closure variable would
        // leak one reference to its environment (same reasoning as
        // `crate::codegen::builtins::emit_raw_str_ptr`).
        if Self::is_rc_borrowing_read(callee) {
            self.line(&format!("  call void @star_rc_release(i8* {})", envptr));
        }

        let ret_llvm = self.closure_ret_llvm(ret_ty);
        let param_llvm: Vec<String> = param_tys.iter().map(|t| self.llvm_ty(t)).collect();
        let fnty = format!(
            "{} (i8*{})*",
            ret_llvm,
            if param_llvm.is_empty() { String::new() } else { format!(", {}", param_llvm.join(", ")) }
        );
        let real_fnptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}", real_fnptr, fnptr_i8, fnty));

        let mut call_args = vec![format!("i8* {}", envptr)];
        for a in args {
            let reg = self.emit_expr(a);
            let ats = self.llvm_ty(&self.expr_ty(a));
            let clean_val = reg.strip_prefix(&format!("{} ", ats)).unwrap_or(&reg);
            call_args.push(format!("{} {}", ats, clean_val));
        }
        if ret_llvm == "void" {
            self.line(&format!("  call void {}({})", real_fnptr, call_args.join(", ")));
            "%undef".into()
        } else {
            let ret_reg = self.tmp_name();
            self.line(&format!("  {} = call {} {}({})", ret_reg, ret_llvm, real_fnptr, call_args.join(", ")));
            format!("{} {}", ret_llvm, ret_reg)
        }
    }
}
