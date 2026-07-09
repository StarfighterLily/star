//! LLVM IR codegen: walks the typed AST and emits textual `.ll` IR.
//!
//! The emitted IR is written to a file and compiled with the installed
//! `clang.exe` to produce a native executable.

use std::fmt::Write;

use crate::ast::*;
use crate::diagnostics::{Diagnostic, Span};
use crate::types::*;

/// A codegen context that accumulates LLVM IR and tracks symbols.
pub struct Codegen {
    ir: String,
    global_defs: Vec<String>,
    tmp: u64,
    globals: u64,
    /// Counter for unique basic-block labels (if/while codegen).
    block_id: u64,
    symbols: Vec<(String, String, Ty)>,
    /// Field name lists per struct, populated from the typed module so field
    /// indices can be resolved for any struct (not just a hardcoded set).
    struct_fields: std::collections::HashMap<String, Vec<String>>,
    /// Field type lists per struct, used to compute accurate byte sizes for
    /// the frame bump allocator.
    struct_field_types: std::collections::HashMap<String, Vec<Ty>>,
    /// Maps `"Struct.method"` -> `@method` so method calls (`obj.method()`) can
    /// be lowered to a direct function call with the receiver as `self`.
    methods: std::collections::HashMap<String, String>,
    errors: Vec<Diagnostic>,
    in_frame: bool,
}

impl Codegen {
    pub fn new() -> Self {
        Self {
            ir: String::new(),
            global_defs: Vec::new(),
            tmp: 0,
            globals: 0,
            block_id: 0,
            symbols: Vec::new(),
            struct_fields: std::collections::HashMap::new(),
            struct_field_types: std::collections::HashMap::new(),
            methods: std::collections::HashMap::new(),
            errors: Vec::new(),
            in_frame: false,
        }
    }

    /// Generate LLVM IR from a checked module, returning the `.ll` source.
    pub fn emit(&mut self, module: &TypedModule) -> Result<String, Vec<Diagnostic>> {
        self.line("; Star compiler -- LLVM IR");
        self.line("target triple = \"x86_64-w64-windows-gnu\"");
        self.line("");

        self.emit_builtins();

        for item in &module.items {
            match item {
                TypedItem::Struct(s) => self.emit_struct_decl(s),
                TypedItem::Arena(a) => self.emit_arena_decl(a),
                _ => {}
            }
        }

        // Register method names so `obj.method()` can be resolved in codegen.
        for item in &module.items {
            if let TypedItem::Impl(blk) = item {
                for m in &blk.methods {
                    self.methods
                        .insert(format!("{}#{}", blk.type_name, m.sig.name), m.sig.name.clone());
                }
            }
        }

        for item in &module.items {
            match item {
                TypedItem::Impl(blk) => {
                    for m in &blk.methods { self.emit_fn(m); }
                }
                TypedItem::Fn(f) => self.emit_fn(f),
                _ => {}
            }
        }

        // Append global constant definitions at module-level (outside function bodies).
        if !self.global_defs.is_empty() {
            self.line("");
            self.line("; Global Constants");
            let defs = self.global_defs.clone();
            for g in &defs {
                self.line(g);
            }
        }

        if self.errors.is_empty() {
            Ok(std::mem::take(&mut self.ir))
        } else {
            Err(std::mem::take(&mut self.errors))
        }
    }

    fn emit_builtins(&mut self) {
        self.line("declare i32 @printf(i8*, ...)");
        self.line("declare i32 @puts(i8*)");
        self.line("declare noalias i8* @malloc(i64)");
        self.line("declare void @free(i8*)");
        self.line("declare i32 @strlen(i8*)");
        self.line("declare i8* @memcpy(i8*, i8*, i64)");
        self.line("");
        self.line("%GenRef = type { i32, i32 }");
        self.line("");
        self.line("@frame.buf = global [4096 x i8] zeroinitializer");
        self.line("@frame.off = global i64 0");
        self.line("");
    }

    fn emit_arena_decl(&mut self, a: &TypedArenaDecl) {
        let elem_ty = self.llvm_ty(&a.ty);
        self.line(&format!("%{} = type {{ {}*, i64 }}", a.name, elem_ty));
        self.line(&format!("@arena.{}.data = global {}* null", a.name, elem_ty));
        self.line(&format!("@arena.{}.count = global i64 0", a.name));
        self.line("");
    }

    fn emit_struct_decl(&mut self, s: &TypedStructDef) {
        self.struct_fields
            .insert(s.name.clone(), s.fields.iter().map(|f| f.name.clone()).collect());
        self.struct_field_types
            .insert(s.name.clone(), s.fields.iter().map(|f| f.ty.clone()).collect());
        self.write(&format!("%{} = type {{ ", s.name));
        let parts: Vec<String> = s.fields.iter().map(|f| self.llvm_ty(&f.ty)).collect();
        self.write(&parts.join(", "));
        self.line(" }");
    }

    /// Byte size of a type, used to advance the frame bump allocator's
    /// offset by the right amount for each allocation.
    fn type_size(&self, ty: &Ty) -> u32 {
        match ty {
            Ty::Int | Ty::Float => 4,
            Ty::Bool => 1,
            Ty::Str => 8,
            Ty::GenRef(_) => 8, // { i32, i32 }
            Ty::Vec2 => 8,
            Ty::Vec3 => 12,
            Ty::Vec4 => 16,
            Ty::Mat4 => 64,
            Ty::Named(n) => self
                .struct_field_types
                .get(n)
                .map(|fields| fields.iter().map(|f| self.type_size(f)).sum())
                .unwrap_or(8),
        }
    }

    fn llvm_ty(&self, ty: &Ty) -> String {
        match ty {
            Ty::Int => "i32".into(),
            Ty::Float => "float".into(),
            Ty::Str => "i8*".into(),
            Ty::Bool => "i1".into(),
            Ty::Vec2 => "{ float, float }".into(),
            Ty::Vec3 => "{ float, float, float }".into(),
            Ty::Vec4 => "<4 x float>".into(),
            Ty::Mat4 => "[4 x <4 x float>]".into(),
            Ty::Named(n) => format!("%{}", n),
            Ty::GenRef(_) => "%GenRef".into(),
        }
    }

    fn tmp_name(&mut self) -> String {
        let n = self.tmp;
        self.tmp += 1;
        format!("%t{}", n)
    }

    fn global_name(&mut self) -> String {
        let n = self.globals;
        self.globals += 1;
        format!("@.str.{}", n)
    }

    fn sym_ptr(&self, name: &str) -> Option<String> {
        self.symbols.iter().rev().find(|(n, _, _)| n == name).map(|(_, ptr, _)| ptr.clone())
    }

    /// Extract the variable name from a base expression used as a method
    /// receiver, so its alloca pointer can be passed as `self`.
    fn receiver_name(&self, base: &TypedExpr) -> String {
        match base {
            TypedExpr::Ident { name, .. } => name.clone(),
            _ => String::new(),
        }
    }

    /// Emit code that yields a *pointer* to the storage of `expr`, for use as
    /// the base operand of a `getelementptr`. This differs from `emit_expr`,
    /// which for an `Ident`/`Field` of aggregate type loads and returns the
    /// value itself; GEP-ing into that loaded value would be an LLVM type
    /// mismatch (the register's type is the aggregate, not a pointer to it).
    fn emit_place(&mut self, expr: &TypedExpr) -> String {
        match expr {
            TypedExpr::Ident { name, .. } => self.sym_ptr(name).unwrap_or_else(|| "%undef".into()),
            TypedExpr::SelfExpr(ty, _) => {
                let ptr = self.sym_ptr("self").unwrap_or_else(|| "%undef".into());
                let reg = self.tmp_name();
                let struct_ty = match ty {
                    Ty::Named(n) => format!("%{}", n),
                    _ => self.llvm_ty(ty),
                };
                self.line(&format!("  {} = load {}*, {}** {}", reg, struct_ty, struct_ty, ptr));
                reg
            }
            TypedExpr::Field { base, field, .. } => {
                let base_ptr = self.emit_place(base);
                let gep = self.tmp_name();
                let bty = self.llvm_ty(&self.expr_ty(base));
                let idx = self.field_index(&self.expr_ty(base), field);
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, bty, bty, base_ptr, idx));
                gep
            }
            _ => self.emit_expr(expr),
        }
    }

    fn field_index(&mut self, base_ty: &Ty, field: &str) -> u32 {
        let name = match base_ty {
            Ty::Named(n) => n.clone(),
            _ => { self.err("field access on non-struct type", Span::dummy()); return 0; }
        };
        // Resolve the field's position from the struct's declared field order.
        let pos = self
            .struct_fields
            .get(&name)
            .map(|fields| fields.iter().position(|f| f == field));
        match pos {
            Some(Some(i)) => i as u32,
            Some(None) => { self.err(&format!("no field `{}` on `{}`", field, name), Span::dummy()); 0 }
            None => { self.err(&format!("unknown struct `{}`", name), Span::dummy()); 0 }
        }
    }

    /// Map a swizzle character to its lane/component index.
    fn swizzle_index(&mut self, c: char) -> u32 {
        match c {
            'x' => 0,
            'y' => 1,
            'z' => 2,
            'w' => 3,
            _ => { self.err(&format!("invalid swizzle component `{}`", c), Span::dummy()); 0 }
        }
    }

    /// Read a GLSL-style swizzle access (`.x`, `.xyz`, `.zyx`, ...) off a
    /// vector base, producing a scalar `float` (single component) or a
    /// smaller/reordered vector value (multiple components). Loads the base
    /// once, then extracts via `extractvalue` (Vec2/Vec3) or
    /// `extractelement`/`shufflevector` (Vec4) as appropriate — no GEP is
    /// used since a swizzle result isn't a contiguous sub-object in general.
    fn emit_swizzle_read(&mut self, base: &TypedExpr, field: &str) -> String {
        let base_ty = self.expr_ty(base);
        let base_val = self.emit_expr(base);
        let bare = self.untag(&base_val, &base_ty);
        let indices: Vec<u32> = field.chars().map(|c| self.swizzle_index(c)).collect();

        if indices.len() == 1 {
            let reg = self.extract_component(&bare, &base_ty, indices[0]);
            return format!("float {}", reg);
        }

        if matches!(base_ty, Ty::Vec4) {
            let reg = self.tmp_name();
            let mask: Vec<String> = indices.iter().map(|i| format!("i32 {}", i)).collect();
            self.line(&format!(
                "  {} = shufflevector <4 x float> {}, <4 x float> undef, <{} x i32> <{}>",
                reg, bare, indices.len(), mask.join(", ")
            ));
            let result_ty = Ty::vec_of_arity(indices.len() as u8).unwrap();
            return format!("{} {}", self.llvm_ty(&result_ty), reg);
        }

        let result_ty = Ty::vec_of_arity(indices.len() as u8).unwrap();
        let mut acc = "undef".to_string();
        for (i, idx) in indices.iter().enumerate() {
            let comp = self.extract_component(&bare, &base_ty, *idx);
            acc = self.insert_component(&acc, &result_ty, i as u32, &comp);
        }
        format!("{} {}", self.llvm_ty(&result_ty), acc)
    }

    /// Write to a GLSL-style swizzle target on a vector base
    /// (`v.x = ...`, `v.xy = ...`), with full write-mask support: each named
    /// destination lane is updated independently, leaving any unnamed lanes
    /// untouched. `val_ty` is the swizzle's own resolved type (`Float` for a
    /// single component, `Vec2`/`Vec3`/`Vec4` for multiple).
    fn emit_swizzle_write(&mut self, base: &TypedExpr, field: &str, val_ty: &Ty, val: &str) {
        let base_ty = self.expr_ty(base);
        let val_bare = self.untag(val, val_ty);
        let indices: Vec<u32> = field.chars().map(|c| self.swizzle_index(c)).collect();
        let base_ptr = self.emit_place(base);

        if matches!(base_ty, Ty::Vec4) {
            let loaded = self.tmp_name();
            self.line(&format!("  {} = load <4 x float>, <4 x float>* {}", loaded, base_ptr));
            let mut acc = loaded;
            for (i, dest_idx) in indices.iter().enumerate() {
                let src = if indices.len() == 1 { val_bare.clone() } else { self.extract_component(&val_bare, val_ty, i as u32) };
                acc = self.insert_component(&acc, &Ty::Vec4, *dest_idx, &src);
            }
            self.line(&format!("  store <4 x float> {}, <4 x float>* {}", acc, base_ptr));
        } else {
            let bty = self.llvm_ty(&base_ty);
            for (i, dest_idx) in indices.iter().enumerate() {
                let src = if indices.len() == 1 { val_bare.clone() } else { self.extract_component(&val_bare, val_ty, i as u32) };
                let gep = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, bty, bty, base_ptr, dest_idx));
                self.line(&format!("  store float {}, float* {}", src, gep));
            }
        }
    }

    fn line(&mut self, s: &str) { writeln!(self.ir, "{}", s).unwrap(); }
    fn write(&mut self, s: &str) { write!(self.ir, "{}", s).unwrap(); }
    fn err(&mut self, msg: &str, span: Span) { self.errors.push(Diagnostic::error(msg, span)); }

    /// Produce a unique, readable basic-block label for control flow.
    fn block_label(&mut self, prefix: &str) -> String {
        let id = self.block_id;
        self.block_id += 1;
        format!("{}_{}", prefix, id)
    }

    /// Extract just the register name from an expression emission result such
    /// as `i1 %r` or `i32 %r`, discarding the leading type tag.
    fn reg_of(&self, s: &str) -> String {
        s.split_whitespace().next_back().unwrap_or(s).to_string()
    }

    /// Emit a block of typed statements. If the block ends with an expression
    /// statement (or a `frame` block whose own trailing statement produces a
    /// value), returns the value-register (with type tag) of that trailing
    /// expression; otherwise returns `None` (the block is used for side effects).
    fn emit_block_value(&mut self, block: &TypedBlock) -> Option<String> {
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
            _ => false,
        }
    }

    fn expr_ty(&self, e: &TypedExpr) -> Ty {
        match e {
            TypedExpr::Int(_, ty, _) | TypedExpr::Float(_, ty, _)
            | TypedExpr::Str(_, ty, _) | TypedExpr::Bool(_, ty, _)
            | TypedExpr::Field { ty, .. } | TypedExpr::Call { ty, .. }
            | TypedExpr::Binary { ty, .. } | TypedExpr::Unary { ty, .. }
            | TypedExpr::Match { ty, .. } | TypedExpr::StructLit { ty, .. }
            | TypedExpr::FStr(_, ty, _) | TypedExpr::GenRefIndex { ty, .. } | TypedExpr::Error(ty) => ty.clone(),
            TypedExpr::Ident { ty, .. } => ty.clone(),
            TypedExpr::GenRefCreate { inner_ty, .. } => Ty::GenRef(Box::new(inner_ty.clone())),
            TypedExpr::SelfExpr(ty, _) => ty.clone(),
            TypedExpr::If { ty, .. } => ty.clone(),
        }
    }

    fn emit_fn(&mut self, f: &TypedFnDef) {
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

    fn emit_stmt(&mut self, stmt: &TypedStmt) {
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
                    self.line(&format!("  ret {} {}", self.llvm_ty(&self.expr_ty(v)), reg));
                } else {
                    self.line("  ret void");
                }
            }
            TypedStmt::Expr(e) => { self.emit_expr(e); }
            TypedStmt::If { cond, then_block, else_block, .. } => {
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
                self.line(&format!("  br label %{}", end_label));
                self.line(&format!("{}:", else_label));
                if let Some(else_b) = else_block {
                    for stmt in &else_b.stmts {
                        self.emit_stmt(stmt);
                    }
                }
                self.line(&format!("  br label %{}", end_label));
                self.line(&format!("{}:", end_label));
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

    fn emit_expr(&mut self, expr: &TypedExpr) -> String {
        match expr {
            TypedExpr::Int(v, _, _) => format!("i32 {}", v),
            // `{:?}` (unlike `{}`) always renders a decimal point for whole
            // numbers (`1.0` not `1`), which LLVM's textual IR requires for
            // float constants.
            TypedExpr::Float(v, _, _) => format!("float {:?}", v),
            TypedExpr::Str(s, _, _) => {
                let var = self.tmp_name();
                let escaped = s.replace("\\", "\\\\").replace("\"", "\\22").replace("\n", "\\0A");
                let g = self.global_name();
                self.global_defs.push(format!("{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"", g, s.len() + 1, escaped));
                let gep = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", gep, s.len() + 1, s.len() + 1, g));
                self.line(&format!("  {} = alloca i8*", var));
                self.line(&format!("  store i8* {}, i8** {}", gep, var));
                var
            }
            TypedExpr::Bool(v, _, _) => format!("i1 {}", if *v { "true" } else { "false" }),
            TypedExpr::Ident { name, ty, .. } => {
                let ptr = self.sym_ptr(name).unwrap_or_else(|| "%undef".into());
                let reg = self.tmp_name();
                let ts = self.llvm_ty(ty);
                self.line(&format!("  {} = load {}, {}* {}", reg, ts, ts, ptr));
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
            TypedExpr::Field { base, field, ty, .. } => {
                if self.expr_ty(base).is_vec() {
                    return self.emit_swizzle_read(base, field);
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
            TypedExpr::Call { callee, args, .. } => {
                let is_print = matches!(callee.as_ref(), TypedExpr::Ident { name, .. } if name == "print");
                if is_print {
                    if let Some(arg) = args.first() {
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
                                            Ty::Str => { fmt_str.push_str("%s"); }
                                            _ => { fmt_str.push_str("%p"); }
                                        }
                                        // `emit_expr` may return either a bare register
                                        // or one already tagged with its LLVM type
                                        // (e.g. swizzle reads) — strip any existing tag
                                        // so it isn't double-tagged below.
                                        let bare_val = self.untag(&val, &ty);
                                        // For string arguments, `bare_val` is the alloca
                                        // holding the `i8*`; load it to get the pointer
                                        // that `%s` expects.
                                        let arg_val = if matches!(ty, Ty::Str) {
                                            let loaded = self.tmp_name();
                                            self.line(&format!("  {} = load i8*, i8** {}", loaded, bare_val));
                                            loaded
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
                                } else {
                                    call_args.push(format!("{} {}", self.llvm_ty(ty), val));
                                }
                            }
                            self.line(&format!("  call i32 (i8*, ...) @printf({})", call_args.join(", ")));
                        } else {
                            let fmt_ptr = self.emit_expr(arg);
                            let loaded = self.tmp_name();
                            self.line(&format!("  {} = load i8*, i8** {}", loaded, fmt_ptr));
                            self.line(&format!("  call i32 (i8*, ...) @printf(i8* {})", loaded));
                        }
                    }
                    "%undef".into()
                } else if let TypedExpr::Field { base, field, .. } = callee.as_ref() {
                    // Method call: `obj.method(args)` -> `@method(%Struct* obj, args...)`.
                    let base_ty = self.expr_ty(base);
                    let struct_name = match &base_ty {
                        Ty::Named(n) => n.clone(),
                        _ => { self.err("method call on non-struct receiver", Span::dummy()); String::new() }
                    };
                    let key = format!("{}#{}", struct_name, field);
                    let fn_name = match self.methods.get(&key) {
                        Some(m) => m.clone(),
                        None => { self.err(&format!("no method `{}` on `{}`", field, struct_name), Span::dummy()); field.clone() }
                    };
                    // The receiver is passed by pointer: use the alloca of the base value.
                    let recv_ptr = self.sym_ptr(&self.receiver_name(base));
                    let recv_ty = self.llvm_ty(&base_ty);
                    let mut call_args = vec![format!("{}* {}", recv_ty, recv_ptr.unwrap_or_else(|| "%undef".into()))];
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
                    let fn_name = match callee.as_ref() {
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
            TypedExpr::Binary { op, lhs, rhs, .. } => {
                let lty = self.expr_ty(lhs);
                let rty = self.expr_ty(rhs);
                let l = self.emit_expr(lhs);
                let r = self.emit_expr(rhs);
                self.emit_binop(&l, &lty, &r, &rty, *op)
            }
            TypedExpr::Unary { op, operand, .. } => {
                let o = self.emit_expr(operand);
                let reg = self.tmp_name();
                let ty = self.expr_ty(expr);
                match op {
                    UnOp::Neg => self.line(&format!("  {} = sub {} 0, {}", reg, self.llvm_ty(&ty), o)),
                    UnOp::Not => self.line(&format!("  {} = xor i1 true, {}", reg, o)),
                }
                reg
            }
            TypedExpr::Match { scrutinee, arms, ty: _, .. } => {
                let scrutinee_reg = self.emit_expr(scrutinee);
                let scrut_val = scrutinee_reg.strip_prefix("i32 ").unwrap_or(&scrutinee_reg);
                let end_label = format!("match_end_{}", self.tmp);
                self.tmp += 1;
                for (i, arm) in arms.iter().enumerate() {
                    let then_label = format!("match_then_{}", i);
                    let next_label = format!("match_next_{}", i);
                    match &arm.pattern {
                        Pattern::Compare(op, rhs) => {
                            let rhs_val = match rhs.as_ref() {
                                Expr::Int(v, _) => format!("i32 {}", v),
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
                            self.line(&format!("{}:", then_label));
                            for stmt in &arm.body.stmts {
                                self.emit_stmt(stmt);
                            }
                            self.line(&format!("  br label %{}", end_label));
                            self.line(&format!("{}:", next_label));
                        }
                        Pattern::Wildcard => {
                            for stmt in &arm.body.stmts {
                                self.emit_stmt(stmt);
                            }
                            self.line(&format!("  br label %{}", end_label));
                        }
                        _ => {
                            self.err("unsupported match pattern in codegen", Span::dummy());
                        }
                    }
                }
                self.line(&format!("{}:", end_label));
                "%undef".into()
            }
            TypedExpr::StructLit { name, args, ty, .. } => {
                match ty {
                    Ty::Vec2 | Ty::Vec3 => {
                        // Same alloca+GEP+store+load shape as a named struct, but
                        // using the anonymous LLVM struct type directly (no
                        // `%Name =` declaration exists or is needed for these).
                        let t = self.llvm_ty(ty);
                        let ptr = self.tmp_name();
                        self.line(&format!("  {} = alloca {}", ptr, t));
                        for (i, a) in args.iter().enumerate() {
                            let av = self.emit_expr(a);
                            let aty = self.expr_ty(a);
                            let bare = self.promote_to_float(&av, &aty);
                            let gep = self.tmp_name();
                            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, t, t, ptr, i as u32));
                            self.line(&format!("  store float {}, float* {}", bare, gep));
                        }
                        let loaded = self.tmp_name();
                        self.line(&format!("  {} = load {}, {}* {}", loaded, t, t, ptr));
                        format!("{} {}", t, loaded)
                    }
                    Ty::Vec4 => {
                        // No memory needed: build directly as an SSA vector value.
                        let mut acc = "undef".to_string();
                        for (i, a) in args.iter().enumerate() {
                            let av = self.emit_expr(a);
                            let aty = self.expr_ty(a);
                            let bare = self.promote_to_float(&av, &aty);
                            acc = self.insert_component(&acc, &Ty::Vec4, i as u32, &bare);
                        }
                        format!("<4 x float> {}", acc)
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
                        // Return the struct *value* (loaded from the alloca) so it can be
                        // stored into another aggregate or assigned, not the pointer.
                        let loaded = self.tmp_name();
                        self.line(&format!("  {} = load %{}, %{}* {}", loaded, name, name, ptr));
                        format!("%{} {}", name, loaded)
                    }
                }
            }
            TypedExpr::FStr(parts, _, _) => {
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
                            arg_vals.push((val, ty.clone()));
                            match ty {
                                Ty::Int => { fmt_str.push_str("%d"); }
                                Ty::Float => { fmt_str.push_str("%f"); }
                                Ty::Str => { fmt_str.push_str("%s"); }
                                _ => { fmt_str.push_str("%p"); }
                            }
                        }
                    }
                }
                fmt_str.push('\n');
                let g = self.global_name();
                let escaped = fmt_str.replace("\\", "\\\\").replace("\"", "\\22").replace("\n", "\\0A");
                self.global_defs.push(format!("{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"", g, fmt_str.len() + 1, escaped));
                
                let fmt_reg = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", fmt_reg, fmt_str.len() + 1, fmt_str.len() + 1, g));
                fmt_reg
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
                    self.line(&format!("{}:", then_label));
                    self.emit_block_value(then_block);
                    self.line(&format!("  br label %{}", end_label));
                    self.line(&format!("{}:", else_label));
                    if let Some(else_b) = else_block {
                        self.emit_block_value(else_b);
                    }
                    self.line(&format!("  br label %{}", end_label));
                    self.line(&format!("{}:", end_label));
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
                    self.line(&format!("{}:", then_label));
                    let then_val = self.emit_block_value(then_block);
                    let then_reg = then_val.map(|v| self.reg_of(&v)).unwrap_or_else(|| "%undef".to_string());
                    self.line(&format!("  br label %{}", end_label));
                    self.line(&format!("{}:", else_label));
                    let else_val = else_block.as_ref().and_then(|b| self.emit_block_value(b));
                    let else_reg = else_val.map(|v| self.reg_of(&v)).unwrap_or_else(|| "%undef".to_string());
                    self.line(&format!("  br label %{}", end_label));
                    self.line(&format!("{}:", end_label));
                    let phi = self.tmp_name();
                    self.line(&format!("  {} = phi {} [ {}, %{} ], [ {}, %{} ]", phi, ty_str, then_reg, then_label, else_reg, else_label));
                    format!("{} {}", ty_str, phi)
                }
            }
            TypedExpr::GenRefCreate { inner_ty, value, .. } => {
                let ptr = self.tmp_name();
                self.line(&format!("  {} = alloca %GenRef", ptr));
                let val = self.emit_expr(value);
                let inner_t = match inner_ty {
                    Ty::Int => "i32",
                    Ty::Float => "float",
                    Ty::Bool => "i1",
                    Ty::Str => "i8*",
                    _ => "i32",
                };
                let clean_val = val.strip_prefix(&format!("{} ", inner_t)).unwrap_or(&val);
                let field0 = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds %GenRef, %GenRef* {}, i32 0, i32 0", field0, ptr));
                self.line(&format!("  store {} {}, {}* {}", inner_t, clean_val, inner_t, field0));
                let gen_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds %GenRef, %GenRef* {}, i32 0, i32 1", gen_ptr, ptr));
                self.line(&format!("  store i32 0, i32* {}", gen_ptr));
                let loaded = self.tmp_name();
                self.line(&format!("  {} = load %GenRef, %GenRef* {}", loaded, ptr));
                format!("%GenRef {}", loaded)
            }
            TypedExpr::GenRefIndex { base, index: _, .. } => {
                let base_ptr = self.emit_place(base);
                let idx_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds %GenRef, %GenRef* {}, i32 0, i32 0", idx_ptr, base_ptr));
                let idx_val = self.tmp_name();
                self.line(&format!("  {} = load i32, i32* {}", idx_val, idx_ptr));
                format!("i32 {}", idx_val)
            }
            TypedExpr::Error(_) => "%undef".into(),
        }
    }

    /// Strip a value's leading `<llvm-type> ` tag, given its resolved `Ty`.
    fn untag(&self, s: &str, ty: &Ty) -> String {
        let t = self.llvm_ty(ty);
        s.strip_prefix(&format!("{} ", t)).unwrap_or(s).to_string()
    }

    /// Strip a bare `i32`/`float` tag and, if the operand is an `Int`,
    /// convert it to `float` via `sitofp` so it can be used in float
    /// arithmetic. Returns a bare (untagged) register.
    fn promote_to_float(&mut self, val: &str, ty: &Ty) -> String {
        let bare = self.untag(val, ty);
        if matches!(ty, Ty::Int) {
            let reg = self.tmp_name();
            self.line(&format!("  {} = sitofp i32 {} to float", reg, bare));
            reg
        } else {
            bare
        }
    }

    /// Extract lane/field `i` from an already-loaded vector value `val` of
    /// type `ty`, returning a bare `float` register.
    fn extract_component(&mut self, val: &str, ty: &Ty, i: u32) -> String {
        let reg = self.tmp_name();
        match ty {
            Ty::Vec4 => self.line(&format!("  {} = extractelement <4 x float> {}, i32 {}", reg, val, i)),
            _ => {
                let t = self.llvm_ty(ty);
                self.line(&format!("  {} = extractvalue {} {}, {}", reg, t, val, i));
            }
        }
        reg
    }

    /// Insert a bare `float` register into lane/field `i` of `acc` (an
    /// already-built or `undef` aggregate of type `ty`), returning the
    /// updated aggregate register.
    fn insert_component(&mut self, acc: &str, ty: &Ty, i: u32, scalar: &str) -> String {
        let reg = self.tmp_name();
        match ty {
            Ty::Vec4 => self.line(&format!("  {} = insertelement <4 x float> {}, float {}, i32 {}", reg, acc, scalar, i)),
            _ => {
                let t = self.llvm_ty(ty);
                self.line(&format!("  {} = insertvalue {} {}, float {}, {}", reg, t, acc, scalar, i));
            }
        }
        reg
    }

    /// Apply a scalar float arithmetic op to two bare `float` registers,
    /// returning a bare result register.
    fn emit_float_op(&mut self, l: &str, r: &str, op: BinOp) -> String {
        let reg = self.tmp_name();
        let opcode = match op {
            BinOp::Add => "fadd float",
            BinOp::Sub => "fsub float",
            BinOp::Mul => "fmul float",
            BinOp::Div => "fdiv float",
            BinOp::Rem => "frem float",
            _ => { self.err("unsupported component operator", Span::dummy()); "fadd float" }
        };
        self.line(&format!("  {} = {} {}, {}", reg, opcode, l, r));
        reg
    }

    /// Plain scalar (Int/Float, possibly mixed) binary op — this is where the
    /// pre-existing i32-only bug is fixed: Float operands now get `f`-opcodes,
    /// and mixed Int/Float operands are promoted to Float first.
    fn emit_scalar_binop(&mut self, lhs: &str, lty: &Ty, rhs: &str, rty: &Ty, op: BinOp) -> String {
        let is_cmp = matches!(op, BinOp::Eq | BinOp::Ne | BinOp::Lt | BinOp::Gt | BinOp::Le | BinOp::Ge);
        if matches!(lty, Ty::Int) && matches!(rty, Ty::Int) {
            let reg = self.tmp_name();
            let l = self.untag(lhs, lty);
            let r = self.untag(rhs, rty);
            let opcode = match op {
                BinOp::Add => "add i32", BinOp::Sub => "sub i32", BinOp::Mul => "mul i32",
                BinOp::Div => "sdiv i32", BinOp::Rem => "srem i32",
                BinOp::Eq => "icmp eq i32", BinOp::Ne => "icmp ne i32",
                BinOp::Lt => "icmp slt i32", BinOp::Gt => "icmp sgt i32",
                BinOp::Le => "icmp sle i32", BinOp::Ge => "icmp sge i32",
            };
            self.line(&format!("  {} = {} {}, {}", reg, opcode, l, r));
            return format!("{} {}", if is_cmp { "i1" } else { "i32" }, reg);
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
        };
        self.line(&format!("  {} = {} {}, {}", reg, opcode, l, r));
        format!("{} {}", if is_cmp { "i1" } else { "float" }, reg)
    }

    /// Componentwise op between two same-arity Vec2/Vec3 struct values.
    fn emit_vec_struct_binop(&mut self, lhs: &str, rhs: &str, ty: &Ty, op: BinOp) -> String {
        let arity = ty.vec_arity().unwrap();
        let l = self.untag(lhs, ty);
        let r = self.untag(rhs, ty);
        let mut acc = "undef".to_string();
        for i in 0..arity as u32 {
            let lc = self.extract_component(&l, ty, i);
            let rc = self.extract_component(&r, ty, i);
            let oc = self.emit_float_op(&lc, &rc, op);
            acc = self.insert_component(&acc, ty, i, &oc);
        }
        format!("{} {}", self.llvm_ty(ty), acc)
    }

    /// Native-vector op between two Vec4 values.
    fn emit_vec4_binop(&mut self, lhs: &str, rhs: &str, op: BinOp) -> String {
        let l = self.untag(lhs, &Ty::Vec4);
        let r = self.untag(rhs, &Ty::Vec4);
        let reg = self.tmp_name();
        let opcode = match op {
            BinOp::Add => "fadd <4 x float>",
            BinOp::Sub => "fsub <4 x float>",
            BinOp::Mul => "fmul <4 x float>",
            BinOp::Div => "fdiv <4 x float>",
            _ => { self.err("unsupported vec4 operator", Span::dummy()); "fadd <4 x float>" }
        };
        self.line(&format!("  {} = {} {}, {}", reg, opcode, l, r));
        format!("<4 x float> {}", reg)
    }

    /// Vector (Vec2/Vec3/Vec4) `*`/`/` scalar (either operand order).
    fn emit_vec_scalar_binop(&mut self, vec_val: &str, vec_ty: &Ty, scalar_val: &str, scalar_ty: &Ty, op: BinOp, scalar_on_left: bool) -> String {
        let scalar = self.promote_to_float(scalar_val, scalar_ty);
        let vec_bare = self.untag(vec_val, vec_ty);
        match vec_ty {
            Ty::Vec4 => {
                let mut b = "undef".to_string();
                for i in 0..4u32 {
                    b = self.insert_component(&b, &Ty::Vec4, i, &scalar);
                }
                let reg = self.tmp_name();
                let opcode = match op { BinOp::Mul => "fmul <4 x float>", BinOp::Div => "fdiv <4 x float>", _ => unreachable!() };
                let (a, c) = if scalar_on_left { (b.clone(), vec_bare.clone()) } else { (vec_bare.clone(), b.clone()) };
                self.line(&format!("  {} = {} {}, {}", reg, opcode, a, c));
                format!("<4 x float> {}", reg)
            }
            _ => {
                let arity = vec_ty.vec_arity().unwrap();
                let mut acc = "undef".to_string();
                for i in 0..arity as u32 {
                    let vc = self.extract_component(&vec_bare, vec_ty, i);
                    let (a, b) = if scalar_on_left { (scalar.clone(), vc) } else { (vc, scalar.clone()) };
                    let oc = self.emit_float_op(&a, &b, op);
                    acc = self.insert_component(&acc, vec_ty, i, &oc);
                }
                format!("{} {}", self.llvm_ty(vec_ty), acc)
            }
        }
    }

    /// Elementwise `+`/`-` between two Mat4 values (row-by-row vector op).
    fn emit_mat4_addsub(&mut self, lhs: &str, rhs: &str, op: BinOp) -> String {
        let l = self.untag(lhs, &Ty::Mat4);
        let r = self.untag(rhs, &Ty::Mat4);
        let mat_t = "[4 x <4 x float>]";
        let mut acc = "undef".to_string();
        for i in 0..4u32 {
            let lr = self.tmp_name();
            self.line(&format!("  {} = extractvalue {} {}, {}", lr, mat_t, l, i));
            let rr = self.tmp_name();
            self.line(&format!("  {} = extractvalue {} {}, {}", rr, mat_t, r, i));
            let reg = self.tmp_name();
            let opcode = match op { BinOp::Add => "fadd <4 x float>", BinOp::Sub => "fsub <4 x float>", _ => unreachable!() };
            self.line(&format!("  {} = {} {}, {}", reg, opcode, lr, rr));
            let next = self.tmp_name();
            self.line(&format!("  {} = insertvalue {} {}, <4 x float> {}, {}", next, mat_t, acc, reg, i));
            acc = next;
        }
        format!("{} {}", mat_t, acc)
    }

    /// Dot product of two already-loaded `<4 x float>` registers via
    /// elementwise multiply + horizontal add (straight-line, no loop).
    fn emit_dot4(&mut self, a: &str, b: &str) -> String {
        let p = self.tmp_name();
        self.line(&format!("  {} = fmul <4 x float> {}, {}", p, a, b));
        let p0 = self.tmp_name();
        self.line(&format!("  {} = extractelement <4 x float> {}, i32 0", p0, p));
        let p1 = self.tmp_name();
        self.line(&format!("  {} = extractelement <4 x float> {}, i32 1", p1, p));
        let s01 = self.tmp_name();
        self.line(&format!("  {} = fadd float {}, {}", s01, p0, p1));
        let p2 = self.tmp_name();
        self.line(&format!("  {} = extractelement <4 x float> {}, i32 2", p2, p));
        let s012 = self.tmp_name();
        self.line(&format!("  {} = fadd float {}, {}", s012, s01, p2));
        let p3 = self.tmp_name();
        self.line(&format!("  {} = extractelement <4 x float> {}, i32 3", p3, p));
        let dot = self.tmp_name();
        self.line(&format!("  {} = fadd float {}, {}", dot, s012, p3));
        dot
    }

    /// Matrix-vector multiply: `result[i] = dot(row_i, v)`.
    fn emit_mat4_vec4_mul(&mut self, mat_val: &str, vec_val: &str) -> String {
        let m = self.untag(mat_val, &Ty::Mat4);
        let v = self.untag(vec_val, &Ty::Vec4);
        let mat_t = "[4 x <4 x float>]";
        let mut elems = Vec::with_capacity(4);
        for i in 0..4u32 {
            let row = self.tmp_name();
            self.line(&format!("  {} = extractvalue {} {}, {}", row, mat_t, m, i));
            elems.push(self.emit_dot4(&row, &v));
        }
        let mut acc = "undef".to_string();
        for (i, e) in elems.iter().enumerate() {
            acc = self.insert_component(&acc, &Ty::Vec4, i as u32, e);
        }
        format!("<4 x float> {}", acc)
    }

    /// Full 4x4 matrix multiply, row-major (`A`/`B` both stored as 4 row
    /// vectors): gather `B`'s 4 columns once, then compute each output row
    /// as 4 dot products of `A`'s row against each precomputed column.
    fn emit_mat4_mul(&mut self, a_val: &str, b_val: &str) -> String {
        let a = self.untag(a_val, &Ty::Mat4);
        let b = self.untag(b_val, &Ty::Mat4);
        let mat_t = "[4 x <4 x float>]";
        let mut a_rows = Vec::with_capacity(4);
        let mut b_rows = Vec::with_capacity(4);
        for i in 0..4u32 {
            let ar = self.tmp_name();
            self.line(&format!("  {} = extractvalue {} {}, {}", ar, mat_t, a, i));
            a_rows.push(ar);
            let br = self.tmp_name();
            self.line(&format!("  {} = extractvalue {} {}, {}", br, mat_t, b, i));
            b_rows.push(br);
        }
        let mut b_cols = Vec::with_capacity(4);
        for j in 0..4u32 {
            let mut col = "undef".to_string();
            for (i, row) in b_rows.iter().enumerate() {
                let lane = self.tmp_name();
                self.line(&format!("  {} = extractelement <4 x float> {}, i32 {}", lane, row, j));
                col = self.insert_component(&col, &Ty::Vec4, i as u32, &lane);
            }
            b_cols.push(col);
        }
        let mut acc_mat = "undef".to_string();
        for (i, a_row) in a_rows.iter().enumerate() {
            let mut row_acc = "undef".to_string();
            for (j, b_col) in b_cols.iter().enumerate() {
                let dot = self.emit_dot4(a_row, b_col);
                row_acc = self.insert_component(&row_acc, &Ty::Vec4, j as u32, &dot);
            }
            let next_mat = self.tmp_name();
            self.line(&format!("  {} = insertvalue {} {}, <4 x float> {}, {}", next_mat, mat_t, acc_mat, row_acc, i));
            acc_mat = next_mat;
        }
        format!("{} {}", mat_t, acc_mat)
    }

    fn emit_binop(&mut self, lhs: &str, lty: &Ty, rhs: &str, rty: &Ty, op: BinOp) -> String {
        if matches!(lty, Ty::Int | Ty::Float) && matches!(rty, Ty::Int | Ty::Float) {
            return self.emit_scalar_binop(lhs, lty, rhs, rty, op);
        }
        if matches!(op, BinOp::Rem | BinOp::Eq | BinOp::Ne | BinOp::Lt | BinOp::Gt | BinOp::Le | BinOp::Ge) {
            self.err("`%` and comparison operators are not supported on vector/matrix types", Span::dummy());
            return "%undef".into();
        }
        match (lty, rty) {
            (Ty::Vec2, Ty::Vec2) | (Ty::Vec3, Ty::Vec3) => self.emit_vec_struct_binop(lhs, rhs, lty, op),
            (Ty::Vec4, Ty::Vec4) => self.emit_vec4_binop(lhs, rhs, op),
            (Ty::Mat4, Ty::Mat4) => match op {
                BinOp::Add | BinOp::Sub => self.emit_mat4_addsub(lhs, rhs, op),
                BinOp::Mul => self.emit_mat4_mul(lhs, rhs),
                _ => { self.err("unsupported Mat4 operator", Span::dummy()); "%undef".into() }
            },
            (Ty::Mat4, Ty::Vec4) if op == BinOp::Mul => self.emit_mat4_vec4_mul(lhs, rhs),
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

    fn emit_assign_binop(&mut self, lhs: &str, lty: &Ty, rhs: &str, rty: &Ty, op: AssignOp) -> String {
        let bin_op = match op {
            AssignOp::Add => BinOp::Add,
            AssignOp::Sub => BinOp::Sub,
            AssignOp::Mul => BinOp::Mul,
            AssignOp::Div => BinOp::Div,
            AssignOp::Eq => unreachable!("AssignOp::Eq is filtered out before reaching emit_assign_binop"),
        };
        self.emit_binop(lhs, lty, rhs, rty, bin_op)
    }
}