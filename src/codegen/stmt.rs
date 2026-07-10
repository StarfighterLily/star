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
    fn emit_stmts_value(&mut self, stmts: &[TypedStmt]) -> Option<String> {
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

    /// Emit a `frame:` scope: save the bump-allocator offset, emit the body
    /// (allocations inside use the frame buffer instead of the stack), then
    /// restore the saved offset so the scope's allocations are reclaimed in
    /// O(1) when it ends. Returns the body's trailing value, if any.
    fn emit_frame_body(&mut self, body: &TypedBlock) -> Option<String> {
        let was_in_frame = self.in_frame;
        self.in_frame = true;
        let saved_off = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @frame.off", saved_off));
        let val = self.emit_stmts_value(&body.stmts);
        self.line(&format!("  store i64 {}, i64* @frame.off", saved_off));
        self.in_frame = was_in_frame;
        val
    }

    /// True if the last statement of `stmts` unconditionally terminates the
    /// block with an explicit `return` (looking through trailing `frame`
    /// scopes), so callers know not to append a synthetic terminator.
    fn body_ends_in_return(stmts: &[TypedStmt]) -> bool {
        match stmts.last() {
            Some(TypedStmt::Return { .. }) => true,
            Some(TypedStmt::Frame { body, .. }) => Self::body_ends_in_return(&body.stmts),
            // An `if` only terminates the enclosing block if *both* arms do
            // (an `if` with no `else`, or with a non-terminating branch,
            // falls through and still needs the synthetic join point).
            Some(TypedStmt::If { then_block, else_block: Some(else_block), .. }) => {
                Self::body_ends_in_return(&then_block.stmts) && Self::body_ends_in_return(&else_block.stmts)
            }
            _ => false,
        }
    }

    pub(super) fn emit_fn(&mut self, f: &TypedFnDef) {
        self.symbols.clear();
        self.tmp = 0;

        let ret_ty = match &f.sig.ret { Some(t) => self.llvm_ty(t), None => "void".into() };
        let func_name = &f.sig.name;

        self.write(&format!("define {} @{}(", ret_ty, func_name));
        let params: Vec<String> = f.sig.params.iter().map(|p| {
            let ty = if p.is_self {
                match &p.ty { Ty::Named(n) => format!("%{}*", n), t => format!("{}*", self.llvm_ty(t)) }
            } else { self.llvm_ty(&p.ty) };
            format!("{} %{}", ty, p.name)
        }).collect();
        self.write(&params.join(", "));
        self.line(") {");
        self.line("entry:");

        for p in &f.sig.params {
            let ptr_ty = if p.is_self {
                match &p.ty { Ty::Named(n) => format!("%{}*", n), t => format!("{}*", self.llvm_ty(t)) }
            } else { self.llvm_ty(&p.ty) };
            let alloca = self.tmp_name();
            self.line(&format!("  {} = alloca {}", alloca, ptr_ty));
            self.line(&format!("  store {} %{}, {}* {}", ptr_ty, p.name, ptr_ty, alloca));
            self.symbols.push((p.name.clone(), alloca, p.ty.clone()));
        }

        let terminated = Self::body_ends_in_return(&f.body.stmts);
        let trailing_val = self.emit_stmts_value(&f.body.stmts);

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
                None => self.line("  ret void"),
            }
        }
        self.line("}");
        self.line("");
    }

    pub(super) fn emit_stmt(&mut self, stmt: &TypedStmt) {
        match stmt {
            TypedStmt::Let { name, value, .. } => {
                let ty = self.llvm_ty(&self.expr_ty(value));
                let ptr = self.tmp_name();
                if self.in_frame {
                    // Frame allocation: bump-allocate `size` bytes from the frame
                    // buffer, advance (and persist) the offset, then bitcast the
                    // raw `i8*` slot to the value's actual pointer type so the
                    // subsequent store's operand types agree with the pointer's
                    // declared type.
                    self.line(&format!("  {} = load i64, i64* @frame.off", ptr));
                    let base = self.tmp_name();
                    self.line(&format!("  {} = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0", base));
                    let byte_ptr = self.tmp_name();
                    self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", byte_ptr, base, ptr));
                    let size = self.type_size(&self.expr_ty(value));
                    let store_offset = self.tmp_name();
                    self.line(&format!("  {} = add i64 {}, {}", store_offset, ptr, size));
                    self.line(&format!("  store i64 {}, i64* @frame.off", store_offset));
                    let typed_ptr = self.tmp_name();
                    self.line(&format!("  {} = bitcast i8* {} to {}*", typed_ptr, byte_ptr, ty));
                    let reg = self.emit_expr(value);
                    let clean_val = reg.strip_prefix(&format!("{} ", ty)).unwrap_or(&reg);
                    self.line(&format!("  store {} {}, {}* {}", ty, clean_val, ty, typed_ptr));
                    self.symbols.push((name.clone(), typed_ptr, self.expr_ty(value)));
                } else {
                    self.line(&format!("  {} = alloca {}", ptr, ty));
                    let reg = self.emit_expr(value);
                    let clean_val = reg.strip_prefix(&format!("{} ", ty)).unwrap_or(&reg);
                    self.line(&format!("  store {} {}, {}* {}", ty, clean_val, ty, ptr));
                    self.symbols.push((name.clone(), ptr, self.expr_ty(value)));
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
                    self.line(&format!("  ret {} {}", self.llvm_ty(&ty), clean));
                } else {
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
                let then_terminates = Self::body_ends_in_return(&then_block.stmts);
                let else_terminates = else_block.as_ref().map(|b| Self::body_ends_in_return(&b.stmts)).unwrap_or(false);
                let both_terminate = then_terminates && else_terminates;

                let cond_val = self.emit_expr(cond);
                let cond_reg = self.reg_of(&cond_val);
                let then_label = self.block_label("if_then");
                let else_label = self.block_label("if_else");
                let end_label = self.block_label("if_end");
                self.line(&format!("  br i1 {}, label %{}, label %{}", cond_reg, then_label, else_label));
                self.line(&format!("{}:", then_label));
                for stmt in &then_block.stmts {
                    self.emit_stmt(stmt);
                }
                if !then_terminates {
                    self.line(&format!("  br label %{}", end_label));
                }
                self.line(&format!("{}:", else_label));
                if let Some(else_b) = else_block {
                    for stmt in &else_b.stmts {
                        self.emit_stmt(stmt);
                    }
                }
                if !else_terminates {
                    self.line(&format!("  br label %{}", end_label));
                }
                if !both_terminate {
                    self.line(&format!("{}:", end_label));
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
                self.line(&format!("{}:", cond_label));
                let cond_val = self.emit_expr(cond);
                let cond_reg = self.reg_of(&cond_val);
                self.line(&format!("  br i1 {}, label %{}, label %{}", cond_reg, body_label, end_label));
                // Loop body: runs, then jumps back to the condition.
                self.line(&format!("{}:", body_label));
                for stmt in &then_block.stmts {
                    self.emit_stmt(stmt);
                }
                self.line(&format!("  br label %{}", cond_label));
                // Optional else clause runs once after the loop exits, then joins end.
                self.line(&format!("{}:", else_label));
                if let Some(else_b) = else_block {
                    for stmt in &else_b.stmts {
                        self.emit_stmt(stmt);
                    }
                }
                self.line(&format!("  br label %{}", end_label));
                self.line(&format!("{}:", end_label));
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
            _ => { self.err("cannot load from this expression", Span::dummy()); "%undef".into() }
        }
    }

    fn store_target(&mut self, target: &TypedExpr, val: &str) {
        match target {
            TypedExpr::Ident { name, ty, .. } => {
                let ptr = self.sym_ptr(name).unwrap_or_else(|| "%undef".into());
                let ts = self.llvm_ty(ty);
                let clean_val = val.strip_prefix(&format!("{} ", ts)).unwrap_or(val);
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
                self.line(&format!("  store {} {}, {}* {}", ts, clean_val, ts, gep));
            }
            _ => { self.err("cannot store to this expression", Span::dummy()); }
        }
    }
}
