//! Statement and function-body emission: control flow (`if`/`while`),
//! `let`/assignment, and the frame bump-allocator scope.

use crate::ast::*;
use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

impl Codegen {
    /// Emit a block of typed statements. If the block ends with an expression
    /// statement (or a `frame` block whose own trailing statement produces a
    /// value), returns the value-register (with type tag) of that trailing
    /// expression; otherwise returns `None` (the block is used for side effects).
    pub(super) fn emit_block_value(&mut self, block: &TypedBlock) -> Option<String> {
        self.emit_stmts_value(&block.stmts)
    }

    /// Shared implementation behind `emit_block_value` and function bodies:
    /// emit every statement but the last normally, then special-case the last
    /// statement so a trailing expression's value (possibly nested inside a
    /// `frame:` scope) propagates out instead of being silently discarded.
    pub(super) fn emit_stmts_value(&mut self, stmts: &[TypedStmt]) -> Option<String> {
        let (init, last) = match stmts.split_last() {
            Some((last, init)) => (init, last),
            None => return None,
        };
        for stmt in init {
            self.emit_stmt(stmt);
        }
        match last {
            TypedStmt::Expr(e) => Some(self.emit_expr(e)),
            TypedStmt::Frame { body, .. } => self.emit_frame_body(body),
            other => {
                self.emit_stmt(other);
                None
            }
        }
    }

    /// Bump-allocate `size` bytes from the `frame:` scope's backing buffer
    /// (`@frame.buf`), returning an `i8*` to the claimed region. This is the
    /// bounds check a bump allocator needs and previously had none of: if
    /// the allocation would advance `@frame.off` past `FRAME_BUF_SIZE`, the
    /// process aborts with a diagnostic message instead of silently
    /// producing an out-of-bounds `getelementptr` that segfaults or
    /// corrupts whatever global data happens to sit right after the buffer.
    fn emit_frame_alloc(&mut self, size: &str) -> String {
        let off = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @frame.off", off));
        let new_off = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, {}", new_off, off, size));
        let overflow = self.tmp_name();
        self.line(&format!("  {} = icmp ugt i64 {}, {}", overflow, new_off, Self::FRAME_BUF_SIZE));
        let fail_label = self.block_label("frame_alloc_fail");
        let ok_label = self.block_label("frame_alloc_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", overflow, fail_label, ok_label));

        self.open_block(&fail_label);
        let msg = "star runtime error: a `frame:` block exceeded its 4096-byte capacity\n";
        let g = self.global_name();
        let escaped = msg.replace("\\", "\\\\").replace("\"", "\\22").replace("\n", "\\0A");
        self.global_defs.push(format!("{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"", g, msg.len() + 1, escaped));
        let msg_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", msg_ptr, msg.len() + 1, msg.len() + 1, g));
        self.line(&format!("  call i32 @puts(i8* {})", msg_ptr));
        self.line("  call void @exit(i32 1)");
        self.line("  unreachable");

        self.open_block(&ok_label);
        self.line(&format!("  store i64 {}, i64* @frame.off", new_off));
        let base = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0", base));
        let byte_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", byte_ptr, base, off));
        byte_ptr
    }

    /// Emit a `frame:` scope: save the bump-allocator offset, emit the body
    /// (allocations inside use the frame buffer instead of the stack), then
    /// restore the saved offset so the scope's allocations are reclaimed in
    /// O(1) when it ends. Returns the body's trailing value, if any.
    fn emit_frame_body(&mut self, body: &TypedBlock) -> Option<String> {
        let was_in_frame = self.in_frame;
        self.in_frame = true;
        let saved_off = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @frame.off", saved_off));
        self.push_scope();
        let val = self.emit_stmts_value(&body.stmts);
        self.pop_scope(!Self::body_terminates(&body.stmts));
        self.line(&format!("  store i64 {}, i64* @frame.off", saved_off));
        self.in_frame = was_in_frame;
        val
    }

    /// True if the last statement of `stmts` unconditionally terminates the
    /// block with an explicit `return`/`break`/`continue` (looking through
    /// trailing `frame` scopes), so callers know not to append a synthetic
    /// terminator of their own (LLVM rejects any instruction, including
    /// another terminator, after a block's first terminator).
    pub(super) fn body_terminates(stmts: &[TypedStmt]) -> bool {
        match stmts.last() {
            Some(TypedStmt::Return { .. } | TypedStmt::Break { .. } | TypedStmt::Continue { .. }) => true,
            Some(TypedStmt::Frame { body, .. }) => Self::body_terminates(&body.stmts),
            // An `if` only terminates the enclosing block if *both* arms do
            // (an `if` with no `else`, or with a non-terminating branch,
            // falls through and still needs the synthetic join point).
            Some(TypedStmt::If { then_block, else_block: Some(else_block), .. }) => {
                Self::body_terminates(&then_block.stmts) && Self::body_terminates(&else_block.stmts)
            }
            // A `match` terminates the enclosing block if every one of its
            // arms does (each ends in its own `return`/`break`/`continue`),
            // matching `emit_expr`'s `TypedExpr::Match` codegen, which closes
            // its own join block with `unreachable` in exactly this case
            // instead of leaving it open for a value to flow through.
            Some(TypedStmt::Expr(TypedExpr::Match { arms, .. })) => {
                !arms.is_empty() && arms.iter().all(|arm| Self::body_terminates(&arm.body.stmts))
            }
            _ => false,
        }
    }

    /// `extern "C" fn name(params) -> ret`: a bare LLVM `declare`, no body.
    /// Parameter names aren't needed in a `declare` (LLVM's textual IR only
    /// requires them on `define`), so this is just a type-signature dump --
    /// contrast with `emit_fn` below, which allocas/stores every parameter
    /// and walks a real body.
    pub(super) fn emit_extern_fn_decl(&mut self, sig: &TypedFnSig) {
        let ret_ty = match &sig.ret { Some(t) => self.llvm_ty(t), None => "void".into() };
        let params: Vec<String> = sig.params.iter().map(|p| self.llvm_ty(&p.ty)).collect();
        self.line(&format!("declare {} @{}({})", ret_ty, sig.name, params.join(", ")));
    }

    /// `owner`: `Some(struct_name)` for an impl method, `None` for a free
    /// function. A method's emitted LLVM function name is mangled as
    /// `{struct}__{method}` (looked up via `Codegen::methods` at call sites,
    /// see `emit_call_expr`) rather than the bare method name, since two
    /// unrelated structs may declare a same-named method with a different
    /// signature -- emitting both under the bare name would be a duplicate
    /// `define @name` global, rejected by clang as an "invalid redefinition
    /// of function" on otherwise valid source.
    pub(super) fn emit_fn(&mut self, f: &TypedFnDef, owner: Option<&str>) {
        self.symbols.clear();
        self.owned_stack.clear();
        self.push_scope();
        self.tmp = 0;

        // `main` is the process's real C entry point once linked by clang: a
        // hosted `int main(void)` is a hard ABI requirement, since the OS/CRT
        // startup thunk always reads a return value out of `eax`/`al` after
        // calling it. Lowering a bare `fn main():` to `define void @main()`
        // (the ordinary no-return-type rule below) leaves that register
        // holding whatever garbage the last instruction before `ret void`
        // happened to write -- typically the last `printf`'s return value --
        // so every compiled program's exit code becomes non-deterministic
        // garbage despite otherwise-correct output. `main` is therefore
        // special-cased to always lower to `i32 @main(...)`, with an
        // implicit `ret i32 0` appended when the user's body doesn't already
        // return a value, mirroring what `rustc`/`clang` do for a bare `fn
        // main()`/`void main()`.
        let is_main = owner.is_none() && f.sig.name == "main";
        let ret_ty = if is_main {
            "i32".to_string()
        } else {
            match &f.sig.ret { Some(t) => self.llvm_ty(t), None => "void".into() }
        };
        let func_name = match owner {
            Some(struct_name) => format!("{}__{}", struct_name, f.sig.name),
            None => f.sig.name.clone(),
        };

        self.write(&format!("define {} @{}(", ret_ty, func_name));
        // `main`'s real, OS-called LLVM signature always accepts `argc`/
        // `argv` regardless of Star `fn main()`'s own (always empty in
        // practice) declared parameter list -- see `args()`'s doc comment
        // above `@star.argc`/`@star.argv` in `crate::codegen::Codegen::emit_builtins`.
        let params: Vec<String> = if is_main {
            vec!["i32 %.argc".to_string(), "i8** %.argv".to_string()]
        } else {
            f.sig.params.iter().map(|p| {
                let ty = if p.is_self {
                    match &p.ty { Ty::Named(n) => format!("%{}*", n), t => format!("{}*", self.llvm_ty(t)) }
                } else { self.llvm_ty(&p.ty) };
                format!("{} %{}", ty, p.name)
            }).collect()
        };
        self.write(&params.join(", "));
        self.line(") {");
        self.open_block("entry");

        if is_main {
            self.line("  store i32 %.argc, i32* @star.argc");
            self.line("  store i8** %.argv, i8*** @star.argv");
        }

        for p in &f.sig.params {
            let ptr_ty = if p.is_self {
                match &p.ty { Ty::Named(n) => format!("%{}*", n), t => format!("{}*", self.llvm_ty(t)) }
            } else { self.llvm_ty(&p.ty) };
            let alloca = self.tmp_name();
            self.line(&format!("  {} = alloca {}", alloca, ptr_ty));
            self.line(&format!("  store {} %{}, {}* {}", ptr_ty, p.name, ptr_ty, alloca));
            // `self` is passed *by pointer* (a borrow of the caller's own
            // struct, see the `is_self` special-casing above), not an
            // owned copy -- unlike every other parameter, `alloca` here is
            // one indirection level deeper than `track_owned`/`contains_rc`
            // assume for an ordinary local of type `p.ty`, so it must not
            // be tracked (mirrors the same exception in
            // `crate::codegen::closure::emit_closure_lit`'s capture loop).
            if !p.is_self {
                self.track_owned(&alloca, &p.ty);
            }
            self.symbols.push((p.name.clone(), alloca, p.ty.clone()));
        }

        let was_in_main = self.in_main;
        self.in_main = is_main;
        let terminated = Self::body_terminates(&f.body.stmts);
        let trailing_val = self.emit_stmts_value(&f.body.stmts);
        self.pop_scope(!terminated);
        self.in_main = was_in_main;

        if !terminated {
            match &f.sig.ret {
                Some(rty) => {
                    let rty_s = self.llvm_ty(rty);
                    match trailing_val {
                        Some(v) => {
                            let clean = v.strip_prefix(&format!("{} ", rty_s)).unwrap_or(&v).to_string();
                            self.line(&format!("  ret {} {}", rty_s, clean));
                        }
                        None => {
                            self.err("function must end in a value-producing expression or explicit return", Span::dummy());
                            self.line(&format!("  ret {} undef", rty_s));
                        }
                    }
                }
                None => {
                    if is_main {
                        self.line("  ret i32 0");
                    } else {
                        self.line("  ret void");
                    }
                }
            }
        }
        self.line("}");
        self.line("");
    }

    pub(super) fn emit_stmt(&mut self, stmt: &TypedStmt) {
        match stmt {
            TypedStmt::Let { name, value, .. } => {
                let vty = self.expr_ty(value);
                let ty = self.llvm_ty(&vty);
                if self.in_frame {
                    // Frame allocation: bump-allocate `size` bytes from the
                    // frame buffer (bounds-checked -- see `emit_frame_alloc`),
                    // then bitcast the raw `i8*` slot to the value's actual
                    // pointer type so the subsequent store's operand types
                    // agree with the pointer's declared type. `size` is
                    // LLVM's own real (alignment-padded) size for `ty`, not
                    // a Rust-side estimate -- the `store` below writes a
                    // full `ty`-typed aggregate, so an undersized estimate
                    // for a struct needing internal padding would silently
                    // corrupt whatever the *next* frame-allocated value
                    // occupies, without ever tripping the bounds check above.
                    let size = self.emit_sizeof_llvm_ty(&ty);
                    let byte_ptr = self.emit_frame_alloc(&size);
                    let typed_ptr = self.tmp_name();
                    self.line(&format!("  {} = bitcast i8* {} to {}*", typed_ptr, byte_ptr, ty));
                    let reg = self.emit_expr(value);
                    let clean_val = reg.strip_prefix(&format!("{} ", ty)).unwrap_or(&reg);
                    self.line(&format!("  store {} {}, {}* {}", ty, clean_val, ty, typed_ptr));
                    self.symbols.push((name.clone(), typed_ptr.clone(), vty.clone()));
                    self.track_owned(&typed_ptr, &vty);
                } else {
                    let ptr = self.tmp_name();
                    self.line(&format!("  {} = alloca {}", ptr, ty));
                    let reg = self.emit_expr(value);
                    let clean_val = reg.strip_prefix(&format!("{} ", ty)).unwrap_or(&reg);
                    self.line(&format!("  store {} {}, {}* {}", ty, clean_val, ty, ptr));
                    self.symbols.push((name.clone(), ptr.clone(), vty.clone()));
                    self.track_owned(&ptr, &vty);
                }
            }
            TypedStmt::Assign { target, op, value, .. } => {
                let val_reg = self.emit_expr(value);
                if *op != AssignOp::Eq {
                    let loaded = self.load_target(target);
                    let tty = self.expr_ty(target);
                    let vty = self.expr_ty(value);
                    let compound = self.emit_assign_binop(&loaded, &tty, &val_reg, &vty, *op);
                    self.store_target(target, &compound);
                } else {
                    self.store_target(target, &val_reg);
                }
            }
            TypedStmt::Return { value, .. } => {
                if let Some(v) = value {
                    let reg = self.emit_expr(v);
                    let ty = self.expr_ty(v);
                    // `emit_expr` returns some values already tagged with
                    // their LLVM type (literals) and others bare (loads,
                    // calls); strip any existing tag so it's never doubled.
                    let clean = self.untag(&reg, &ty);
                    // `emit_expr(v)` above already retained a fresh
                    // reference if `v` reads an existing owned slot (see
                    // `rc.rs`); releasing every currently-open scope *now*,
                    // before the `ret`, nets out to "the caller ends up
                    // owning exactly one reference" whether `v` is a bare
                    // local or a fresh construction.
                    self.emit_releases_for_return();
                    self.line(&format!("  ret {} {}", self.llvm_ty(&ty), clean));
                } else if self.in_main {
                    // `main` is always forced to `i32 @main(...)` (see
                    // `emit_fn`'s `is_main` special case) regardless of its
                    // declared return type, so a bare `return` here must
                    // still produce an `i32`-typed terminator -- `ret void`
                    // would disagree with the function's own declared
                    // signature and be rejected as invalid IR.
                    self.emit_releases_for_return();
                    self.line("  ret i32 0");
                } else {
                    self.emit_releases_for_return();
                    self.line("  ret void");
                }
            }
            TypedStmt::Expr(e) => { self.emit_expr(e); }
            TypedStmt::If { cond, then_block, else_block, .. } => {
                // Each arm may itself end in an unconditional `return` (e.g.
                // the state-machine chain a `sequence` desugars to); a `ret`
                // is a terminator, so the synthetic `br %end` below must be
                // skipped for any arm that already terminated -- LLVM
                // rejects instructions following a terminator in the same
                // block. The `end` block itself is only emitted if at least
                // one arm can still reach it.
                let then_terminates = Self::body_terminates(&then_block.stmts);
                let else_terminates = else_block.as_ref().map(|b| Self::body_terminates(&b.stmts)).unwrap_or(false);
                let both_terminate = then_terminates && else_terminates;

                let cond_val = self.emit_expr(cond);
                let cond_reg = self.reg_of(&cond_val);
                let then_label = self.block_label("if_then");
                let else_label = self.block_label("if_else");
                let end_label = self.block_label("if_end");
                self.line(&format!("  br i1 {}, label %{}, label %{}", cond_reg, then_label, else_label));
                self.open_block(&then_label);
                self.push_scope();
                for stmt in &then_block.stmts {
                    self.emit_stmt(stmt);
                }
                self.pop_scope(!then_terminates);
                if !then_terminates {
                    self.line(&format!("  br label %{}", end_label));
                }
                self.open_block(&else_label);
                self.push_scope();
                if let Some(else_b) = else_block {
                    for stmt in &else_b.stmts {
                        self.emit_stmt(stmt);
                    }
                }
                self.pop_scope(!else_terminates);
                if !else_terminates {
                    self.line(&format!("  br label %{}", end_label));
                }
                if !both_terminate {
                    self.open_block(&end_label);
                }
            }
            TypedStmt::Frame { body, .. } => { self.emit_frame_body(body); }
            TypedStmt::While { cond, then_block, else_block, .. } => {
                let cond_label = self.block_label("while_cond");
                let body_label = self.block_label("while_body");
                let else_label = self.block_label("while_else");
                let end_label = self.block_label("while_end");
                // Loop header: evaluate the condition and branch.
                self.line(&format!("  br label %{}", cond_label));
                self.open_block(&cond_label);
                let cond_val = self.emit_expr(cond);
                let cond_reg = self.reg_of(&cond_val);
                // The condition's false branch must go to `else_label`, not
                // straight to `end_label` -- `else_label` falls through to
                // `end_label` on its own a few lines down, so this is the
                // *only* predecessor that ever reaches it. Previously this
                // branched directly to `end_label`, making the `else` clause
                // a permanently unreachable orphan block: `while cond: ...
                // else: ...` silently never ran its `else` body, even though
                // it's documented to run whenever the loop exits normally
                // (not via `break`).
                self.line(&format!("  br i1 {}, label %{}, label %{}", cond_reg, body_label, else_label));
                // Loop body: runs, then jumps back to the condition. `break`
                // targets `end_label` and `continue` targets `cond_label`
                // directly (re-evaluating the condition has no side effects).
                self.open_block(&body_label);
                let depth_at_entry = self.owned_stack.len();
                self.push_scope();
                self.loop_stack.push((cond_label.clone(), end_label.clone(), depth_at_entry));
                for stmt in &then_block.stmts {
                    self.emit_stmt(stmt);
                }
                self.loop_stack.pop();
                let body_terminates = Self::body_terminates(&then_block.stmts);
                self.pop_scope(!body_terminates);
                if !body_terminates {
                    self.line(&format!("  br label %{}", cond_label));
                }
                // Optional else clause runs once after the loop exits, then joins end.
                self.open_block(&else_label);
                self.push_scope();
                if let Some(else_b) = else_block {
                    for stmt in &else_b.stmts {
                        self.emit_stmt(stmt);
                    }
                }
                // Same reasoning as the `if`-statement's `else` branch above
                // (and the loop body just above it): an else-clause ending in
                // `return`/`break`/`continue` already emitted its own
                // terminator, so falling through to `end_label` unconditionally
                // here would place further instructions after it -- invalid
                // LLVM IR.
                let else_terminates = else_block.as_ref().is_some_and(|b| Self::body_terminates(&b.stmts));
                self.pop_scope(!else_terminates);
                if !else_terminates {
                    self.line(&format!("  br label %{}", end_label));
                }
                self.open_block(&end_label);
            }
            TypedStmt::For { var, start, end, body, .. } => {
                self.emit_for_stmt(var, start, end, body);
            }
            TypedStmt::Break { .. } => {
                let target = self.loop_stack.last().cloned();
                let break_label = target.as_ref().map(|(_, b, _)| b.clone()).unwrap_or_else(|| {
                    self.err("`break` outside of a loop", Span::dummy());
                    "undef".into()
                });
                if let Some((_, _, depth)) = target {
                    self.emit_releases_since(depth);
                }
                self.line(&format!("  br label %{}", break_label));
            }
            TypedStmt::Continue { .. } => {
                let target = self.loop_stack.last().cloned();
                let continue_label = target.as_ref().map(|(c, _, _)| c.clone()).unwrap_or_else(|| {
                    self.err("`continue` outside of a loop", Span::dummy());
                    "undef".into()
                });
                if let Some((_, _, depth)) = target {
                    self.emit_releases_since(depth);
                }
                self.line(&format!("  br label %{}", continue_label));
            }
            TypedStmt::Par { var, elem_ty, arena, body, .. } => {
                self.emit_par_stmt(var, elem_ty, arena, body);
            }
            TypedStmt::Spawn { arena, elem, .. } => {
                self.emit_spawn_stmt(arena, elem);
            }
            TypedStmt::Despawn { arena, index, .. } => {
                self.emit_despawn_stmt(arena, index);
            }
        }
    }

    /// Emit `for var in start..end: <body>`: an `i32` counter alloca,
    /// incremented in a dedicated step block so `continue` can jump straight
    /// to the increment without re-running the loop body.
    fn emit_for_stmt(&mut self, var: &str, start: &TypedExpr, end: &TypedExpr, body: &TypedBlock) {
        let start_val = self.emit_expr(start);
        let start_bare = self.untag(&start_val, &Ty::Int);
        let end_val = self.emit_expr(end);
        let end_bare = self.untag(&end_val, &Ty::Int);

        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", i_ptr));
        self.line(&format!("  store i32 {}, i32* {}", start_bare, i_ptr));

        let cond_label = self.block_label("for_cond");
        let body_label = self.block_label("for_body");
        let step_label = self.block_label("for_step");
        let end_label = self.block_label("for_end");

        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&cond_label);
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", i_reg, i_ptr));
        let cmp = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, {}", cmp, i_reg, end_bare));
        self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, body_label, end_label));

        self.open_block(&body_label);
        self.symbols.push((var.to_string(), i_ptr.clone(), Ty::Int));
        let depth_at_entry = self.owned_stack.len();
        self.push_scope();
        self.loop_stack.push((step_label.clone(), end_label.clone(), depth_at_entry));
        for stmt in &body.stmts {
            self.emit_stmt(stmt);
        }
        self.loop_stack.pop();
        self.symbols.pop();
        let body_terminates = Self::body_terminates(&body.stmts);
        self.pop_scope(!body_terminates);
        if !body_terminates {
            self.line(&format!("  br label %{}", step_label));
        }

        self.open_block(&step_label);
        let i_reg2 = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", i_reg2, i_ptr));
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", i_next, i_reg2));
        self.line(&format!("  store i32 {}, i32* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&end_label);
    }

    fn load_target(&mut self, target: &TypedExpr) -> String {
        match target {
            TypedExpr::Ident { name, ty, .. } => {
                let ptr = self.sym_ptr(name).unwrap_or_else(|| "%undef".into());
                let reg = self.tmp_name();
                let ts = self.llvm_ty(ty);
                self.line(&format!("  {} = load {}, {}* {}", reg, ts, ts, ptr));
                reg
            }
            TypedExpr::Field { base, field, ty, .. } => {
                if self.expr_ty(base).is_vec() {
                    let val = self.emit_swizzle_read(base, field);
                    return self.reg_of(&val);
                }
                let base_ptr = self.emit_place(base);
                let gep = self.tmp_name();
                let bty = self.llvm_ty(&self.expr_ty(base));
                let idx = self.field_index(&self.expr_ty(base), field);
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, bty, bty, base_ptr, idx));
                let reg = self.tmp_name();
                let ts = self.llvm_ty(ty);
                self.line(&format!("  {} = load {}, {}* {}", reg, ts, ts, gep));
                reg
            }
            TypedExpr::ListIndex { base, index, ty, .. } => {
                let val = self.emit_list_index(base, index, ty);
                self.reg_of(&val)
            }
            TypedExpr::ArrayIndex { base, index, ty, .. } => {
                let Ty::Array(_, count) = self.expr_ty(base) else { unreachable!("ArrayIndex base must be Ty::Array") };
                let val = self.emit_array_index(base, index, ty, count);
                self.reg_of(&val)
            }
            TypedExpr::RingIndex { base, index, ty, .. } => {
                let Ty::Ring(_, count) = self.expr_ty(base) else { unreachable!("RingIndex base must be Ty::Ring") };
                let ptr = self.emit_ring_index_read_place(base, index, ty, count);
                let elem_llvm = self.llvm_ty(ty);
                let reg = self.tmp_name();
                self.line(&format!("  {} = load {}, {}* {}", reg, elem_llvm, elem_llvm, ptr));
                reg
            }
            TypedExpr::TupleIndex { base, index, ty, .. } => {
                let base_ptr = self.emit_place(base);
                let gep = self.tmp_name();
                let bty = self.llvm_ty(&self.expr_ty(base));
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, bty, bty, base_ptr, index));
                let reg = self.tmp_name();
                let ts = self.llvm_ty(ty);
                self.line(&format!("  {} = load {}, {}* {}", reg, ts, ts, gep));
                reg
            }
            TypedExpr::TableIndex { base, index, ty, .. } => {
                let val = self.emit_table_index(base, index, ty);
                self.reg_of(&val)
            }
            _ => { self.err("cannot load from this expression", Span::dummy()); "%undef".into() }
        }
    }

    fn store_target(&mut self, target: &TypedExpr, val: &str) {
        match target {
            TypedExpr::Ident { name, ty, .. } => {
                let ptr = self.sym_ptr(name).unwrap_or_else(|| "%undef".into());
                let ts = self.llvm_ty(ty);
                let clean_val = val.strip_prefix(&format!("{} ", ts)).unwrap_or(val);
                // The new value was already computed (and retained, if it's
                // a copy -- see `rc.rs`) above; releasing the slot's old
                // contents *after* that, right before overwriting it, keeps
                // `x = x` self-assignment safe (the fresh retain balances
                // the matching release instead of releasing first and
                // storing a stale, already-freed pointer).
                self.emit_release_at(&ptr, ty);
                self.line(&format!("  store {} {}, {}* {}", ts, clean_val, ts, ptr));
            }
            TypedExpr::Field { base, field, ty, .. } => {
                if self.expr_ty(base).is_vec() {
                    self.emit_swizzle_write(base, field, ty, val);
                    return;
                }
                let base_ptr = self.emit_place(base);
                let gep = self.tmp_name();
                let bty = self.llvm_ty(&self.expr_ty(base));
                let idx = self.field_index(&self.expr_ty(base), field);
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, bty, bty, base_ptr, idx));
                let ts = self.llvm_ty(ty);
                let clean_val = val.strip_prefix(&format!("{} ", ts)).unwrap_or(val);
                self.emit_release_at(&gep, ty);
                self.line(&format!("  store {} {}, {}* {}", ts, clean_val, ts, gep));
            }
            TypedExpr::ListIndex { base, index, ty, .. } => {
                self.store_list_index(base, index, ty, val);
            }
            TypedExpr::ArrayIndex { base, index, ty, .. } => {
                let Ty::Array(_, count) = self.expr_ty(base) else { unreachable!("ArrayIndex base must be Ty::Array") };
                self.store_array_index(base, index, ty, count, val);
            }
            TypedExpr::RingIndex { base, index, ty, .. } => {
                let Ty::Ring(_, count) = self.expr_ty(base) else { unreachable!("RingIndex base must be Ty::Ring") };
                self.store_ring_index(base, index, ty, count, val);
            }
            TypedExpr::TableIndex { base, index, ty, .. } => {
                self.store_table_index(base, index, ty, val);
            }
            TypedExpr::TupleIndex { base, index, ty, .. } => {
                let base_ptr = self.emit_place(base);
                let gep = self.tmp_name();
                let bty = self.llvm_ty(&self.expr_ty(base));
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, bty, bty, base_ptr, index));
                let ts = self.llvm_ty(ty);
                let clean_val = val.strip_prefix(&format!("{} ", ts)).unwrap_or(val);
                self.emit_release_at(&gep, ty);
                self.line(&format!("  store {} {}, {}* {}", ts, clean_val, ts, gep));
            }
            _ => { self.err("cannot store to this expression", Span::dummy()); }
        }
    }
}
