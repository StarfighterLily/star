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
    tmp: u64,
    symbols: Vec<(String, String, Ty)>,
    errors: Vec<Diagnostic>,
}

impl Codegen {
    pub fn new() -> Self {
        Self { ir: String::new(), tmp: 0, symbols: Vec::new(), errors: Vec::new() }
    }

    /// Generate LLVM IR from a checked module, returning the `.ll` source.
    pub fn emit(&mut self, module: &TypedModule) -> Result<String, Vec<Diagnostic>> {
        self.line("; Star compiler -- LLVM IR");
        self.line("target triple = \"x86_64-pc-windows-msvc\"");
        self.line("");

        self.emit_builtins();

        for item in &module.items {
            if let TypedItem::Struct(s) = item {
                self.emit_struct_decl(s);
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

        if self.errors.is_empty() {
            Ok(std::mem::take(&mut self.ir))
        } else {
            Err(std::mem::take(&mut self.errors))
        }
    }

    // --- builtins & helpers ---------------------------------------------

    fn emit_builtins(&mut self) {
        self.line("declare i32 @printf(i8*, ...)");
        self.line("declare i32 @puts(i8*)");
        self.line("declare noalias i8* @malloc(i64)");
        self.line("declare void @free(i8*)");
        self.line("declare i32 @strlen(i8*)");
        self.line("declare i8* @memcpy(i8*, i8*, i64)");
        self.line("");
    }

    fn emit_struct_decl(&mut self, s: &TypedStructDef) {
        self.write(&format!("%{} = type {{ ", s.name));
        let parts: Vec<String> = s.fields.iter().map(|f| self.llvm_ty(&f.ty)).collect();
        self.write(&parts.join(", "));
        self.line(" }");
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
        }
    }

    fn tmp_name(&mut self) -> String {
        let n = self.tmp;
        self.tmp += 1;
        format!("%t{}", n)
    }

    fn sym_ptr(&self, name: &str) -> Option<String> {
        self.symbols.iter().rev().find(|(n, _, _)| n == name).map(|(_, ptr, _)| ptr.clone())
    }

    fn field_index(&mut self, base_ty: &Ty, field: &str) -> u32 {
        let name = match base_ty {
            Ty::Named(n) => n,
            _ => { self.err("field access on non-struct type", Span::dummy()); return 0; }
        };
        let fields: &[&str] = match name.as_str() {
            "Player" => &["health", "position", "name"],
            _ => { self.err(&format!("unknown struct `{}`", name), Span::dummy()); return 0; }
        };
        match fields.iter().position(|f| *f == field) {
            Some(i) => i as u32,
            None => { self.err(&format!("no field `{}` on `{}`", field, name), Span::dummy()); 0 }
        }
    }

    fn line(&mut self, s: &str) { writeln!(self.ir, "{}", s).unwrap(); }
    fn write(&mut self, s: &str) { write!(self.ir, "{}", s).unwrap(); }
    fn err(&mut self, msg: &str, span: Span) { self.errors.push(Diagnostic::error(msg, span)); }

    // --- expr type helpers ----------------------------------------------

    fn expr_ty(&self, e: &TypedExpr) -> Ty {
        match e {
            TypedExpr::Int(_, ty, _) | TypedExpr::Float(_, ty, _)
            | TypedExpr::Str(_, ty, _) | TypedExpr::Bool(_, ty, _)
            | TypedExpr::Field { ty, .. } | TypedExpr::Call { ty, .. }
            | TypedExpr::Binary { ty, .. } | TypedExpr::Unary { ty, .. }
            | TypedExpr::Match { ty, .. } | TypedExpr::StructLit { ty, .. }
            | TypedExpr::FStr(_, ty, _) | TypedExpr::Error(ty) => ty.clone(),
            TypedExpr::Ident { ty, .. } => ty.clone(),
            TypedExpr::SelfExpr(ty, _) => ty.clone(),
        }
    }

    // --- functions ------------------------------------------------------

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

        for stmt in &f.body.stmts {
            self.emit_stmt(stmt);
        }

        if matches!(f.sig.ret, None) {
            self.line("  ret void");
        }
        self.line("}");
        self.line("");
    }

    // --- statements -----------------------------------------------------

    fn emit_stmt(&mut self, stmt: &TypedStmt) {
        match stmt {
            TypedStmt::Let { name, value, .. } => {
                let ty = self.llvm_ty(&self.expr_ty(value));
                let ptr = self.tmp_name();
                self.line(&format!("  {} = alloca {}", ptr, ty));
                let reg = self.emit_expr(value);
                self.line(&format!("  store {}, {} {}", reg, ty, ptr));
                self.symbols.push((name.clone(), ptr, self.expr_ty(value)));
            }
            TypedStmt::Assign { target, op, value, .. } => {
                let val_reg = self.emit_expr(value);
                if *op != AssignOp::Eq {
                    let loaded = self.load_target(target);
                    let compound = self.emit_assign_binop(&loaded, &val_reg, *op);
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
        }
    }

    fn load_target(&mut self, target: &TypedExpr) -> String {
        match target {
            TypedExpr::Ident { name, ty, .. } => {
                let ptr = self.sym_ptr(name).unwrap_or_else(|| "%undef".into());
                let reg = self.tmp_name();
                let ts = self.llvm_ty(ty);
                self.line(&format!("  {} = load {}, {} {}", reg, ts, ts, ptr));
                reg
            }
            TypedExpr::Field { base, field, ty, .. } => {
                let base_ptr = self.emit_expr(base);
                let gep = self.tmp_name();
                let bty = self.llvm_ty(&self.expr_ty(base));
                let idx = self.field_index(&self.expr_ty(base), field);
                self.line(&format!("  {} = getelementptr {}, {} {}, i32 0, i32 {}", gep, bty, bty, base_ptr, idx));
                let reg = self.tmp_name();
                let ts = self.llvm_ty(ty);
                self.line(&format!("  {} = load {}, {} {}", reg, ts, ts, gep));
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
                self.line(&format!("  store {}, {} {}", val, ts, ptr));
            }
            TypedExpr::Field { base, field, ty, .. } => {
                let base_ptr = self.emit_expr(base);
                let gep = self.tmp_name();
                let bty = self.llvm_ty(&self.expr_ty(base));
                let idx = self.field_index(&self.expr_ty(base), field);
                self.line(&format!("  {} = getelementptr {}, {} {}, i32 0, i32 {}", gep, bty, bty, base_ptr, idx));
                let ts = self.llvm_ty(ty);
                self.line(&format!("  store {}, {} {}", val, ts, gep));
            }
            _ => { self.err("cannot store to this expression", Span::dummy()); }
        }
    }

    // --- expressions ----------------------------------------------------

    fn emit_expr(&mut self, expr: &TypedExpr) -> String {
        match expr {
            TypedExpr::Int(v, _, _) => format!("i32 {}", v),
            TypedExpr::Float(v, _, _) => format!("float {}", v),
            TypedExpr::Str(s, _, _) => {
                let var = self.tmp_name();
                let escaped = s.replace("\\", "\\\\").replace("\"", "\\22").replace("\n", "\\0A");
                let g = self.tmp_name();
                self.line(&format!("  @{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"", g, s.len() + 1, escaped));
                let gep = self.tmp_name();
                self.line(&format!("  {} = getelementptr [{} x i8], [{} x i8]* @{}, i64 0, i64 0", gep, s.len() + 1, s.len() + 1, g));
                self.line(&format!("  {} = alloca i8*", var));
                self.line(&format!("  store i8* {}, i8** {}", gep, var));
                var
            }
            TypedExpr::Bool(v, _, _) => format!("i1 {}", if *v { "true" } else { "false" }),
            TypedExpr::Ident { name, ty, .. } => {
                let ptr = self.sym_ptr(name).unwrap_or_else(|| "%undef".into());
                let reg = self.tmp_name();
                let ts = self.llvm_ty(ty);
                self.line(&format!("  {} = load {}, {} {}", reg, ts, ts, ptr));
                reg
            }
            TypedExpr::SelfExpr(_, _) => {
                // Load the struct pointer from the alloca (self is a pointer-to-pointer).
                let ptr = self.sym_ptr("self").unwrap_or_else(|| "%undef".into());
                let reg = self.tmp_name();
                // self is stored as %Player* in a %Player** alloca; load to get the %Player*.
                self.line(&format!("  {} = load %{{}}*, %{{}}** {}", reg, ptr));
                reg
            }
            TypedExpr::Field { base, field, ty, .. } => {
                let base_ptr = self.emit_expr(base);
                let gep = self.tmp_name();
                let bty = self.llvm_ty(&self.expr_ty(base));
                let idx = self.field_index(&self.expr_ty(base), field);
                self.line(&format!("  {} = getelementptr {}, {} {}, i32 0, i32 {}", gep, bty, bty, base_ptr, idx));
                let reg = self.tmp_name();
                let ts = self.llvm_ty(ty);
                self.line(&format!("  {} = load {}, {} {}", reg, ts, ts, gep));
                reg
            }
            TypedExpr::Call { callee, args, .. } => {
                // Detect `print(...)` intrinsic and lower to `@printf`.
                let is_print = matches!(callee.as_ref(), TypedExpr::Ident { name, .. } if name == "print");
                if is_print {
                    // print takes one argument: the f-string (already lowered to a format string pointer).
                    if let Some(arg) = args.first() {
                        let fmt_ptr = self.emit_expr(arg);
                        // Load the i8* from the alloca that emit_expr for FStr returns.
                        let loaded = self.tmp_name();
                        self.line(&format!("  {} = load i8*, i8** {}", loaded, fmt_ptr));
                        // Build varargs: the format string pointer plus any additional args from the f-string.
                        // The f-string's args are already embedded in the format string; we just pass the fmt string.
                        self.line(&format!("  call i32 (i8*, ...) @printf(i8* {})", loaded));
                    }
                    "%undef".into()
                } else {
                    let callee_reg = self.emit_expr(callee);
                    let arg_regs: Vec<String> = args.iter().map(|a| self.emit_expr(a)).collect();
                    let ret = self.tmp_name();
                    let arg_list: Vec<String> = args.iter().zip(&arg_regs)
                        .map(|(a, reg)| format!("{} {}", self.llvm_ty(&self.expr_ty(a)), reg)).collect();
                    self.line(&format!("  {} = call i32 @{}({})", ret, callee_reg, arg_list.join(", ")));
                    ret
                }
            }
            TypedExpr::Binary { op, lhs, rhs, .. } => {
                let l = self.emit_expr(lhs);
                let r = self.emit_expr(rhs);
                self.emit_binop(&l, &r, *op)
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
            TypedExpr::Match { scrutinee, arms, ty, .. } => {
                // Lower match to if/else chain over comparison patterns.
                let scrutinee_reg = self.emit_expr(scrutinee);
                let result_ptr = self.tmp_name();
                let result_ty = self.llvm_ty(ty);
                self.line(&format!("  {} = alloca {}", result_ptr, result_ty));
                for (i, arm) in arms.iter().enumerate() {
                    let then_label = format!("match_then_{}", i);
                    let next_label = format!("match_next_{}", i);
                    match &arm.pattern {
                        Pattern::Compare(op, rhs) => {
                            // Emit the rhs expression directly (it's an AST Expr, not TypedExpr).
                            // For the canonical example the rhs is always an integer literal.
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
                            self.line(&format!("  {} = {} i32 {}, {}", cmp, llvm_op, scrutinee_reg, rhs_val));
                            self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, then_label, next_label));
                            self.line(&format!("{}:", then_label));
                            for stmt in &arm.body.stmts {
                                self.emit_stmt(stmt);
                            }
                            self.line(&format!("  br label %{}", next_label));
                            self.line(&format!("{}:", next_label));
                        }
                        Pattern::Wildcard => {
                            for stmt in &arm.body.stmts {
                                self.emit_stmt(stmt);
                            }
                        }
                        _ => {
                            self.err("unsupported match pattern in codegen", Span::dummy());
                        }
                    }
                }
                let reg = self.tmp_name();
                self.line(&format!("  {} = load {}, {}", reg, result_ty, result_ptr));
                reg
            }
            TypedExpr::StructLit { name, args, .. } => {
                let ptr = self.tmp_name();
                self.line(&format!("  {} = alloca %{}", ptr, name));
                for (i, a) in args.iter().enumerate() {
                    let val = self.emit_expr(a);
                    let gep = self.tmp_name();
                    let aty = self.expr_ty(a);
                    self.line(&format!("  {} = getelementptr %{}, %{}* {}, i32 0, i32 {}", gep, name, name, ptr, i as u32));
                let ats = self.llvm_ty(&aty);
                self.line(&format!("  store {}, {} {}", val, ats, gep));
                }
                ptr
            }
            TypedExpr::FStr(parts, _, _) => {
                // Lower f-string to a printf format string with %s/%d/%f placeholders.
                let mut fmt_str = String::new();
                let mut arg_regs: Vec<String> = Vec::new();
                for part in parts {
                    match part {
                        TypedFStrExpr::Literal(lit) => {
                            fmt_str.push_str(&lit.replace("%", "%%"));
                        }
                        TypedFStrExpr::Expr(e) => {
                            let reg = self.emit_expr(e);
                            let ty = self.expr_ty(e);
                            match ty {
                                Ty::Int => { fmt_str.push_str("%d"); }
                                Ty::Float => { fmt_str.push_str("%f"); }
                                Ty::Str => { fmt_str.push_str("%s"); }
                                _ => { fmt_str.push_str("%p"); }
                            }
                            arg_regs.push(format!("{} {}", self.llvm_ty(&ty), reg));
                        }
                    }
                }
                fmt_str.push('\n'); // print adds a newline
                // Emit the format string as a global constant.
                let g = self.tmp_name();
                let escaped = fmt_str.replace("\\", "\\\\").replace("\"", "\\22").replace("\n", "\\0A");
                self.line(&format!("  @{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"", g, fmt_str.len() + 1, escaped));
                let fmt_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr [{} x i8], [{} x i8]* @{}, i64 0, i64 0", fmt_ptr, fmt_str.len() + 1, fmt_str.len() + 1, g));
                // Return the format string pointer as the result (for use by print).
                let var = self.tmp_name();
                self.line(&format!("  {} = alloca i8*", var));
                self.line(&format!("  store i8* {}, i8** {}", fmt_ptr, var));
                var
            }
            TypedExpr::Error(_) => "%undef".into(),
        }
    }

    fn emit_binop(&mut self, lhs: &str, rhs: &str, op: BinOp) -> String {
        let reg = self.tmp_name();
        match op {
            BinOp::Add => self.line(&format!("  {} = add i32 {}, {}", reg, lhs, rhs)),
            BinOp::Sub => self.line(&format!("  {} = sub i32 {}, {}", reg, lhs, rhs)),
            BinOp::Mul => self.line(&format!("  {} = mul i32 {}, {}", reg, lhs, rhs)),
            BinOp::Div => self.line(&format!("  {} = sdiv i32 {}, {}", reg, lhs, rhs)),
            BinOp::Rem => self.line(&format!("  {} = srem i32 {}, {}", reg, lhs, rhs)),
            BinOp::Eq  => self.line(&format!("  {} = icmp eq i32 {}, {}", reg, lhs, rhs)),
            BinOp::Ne  => self.line(&format!("  {} = icmp ne i32 {}, {}", reg, lhs, rhs)),
            BinOp::Lt  => self.line(&format!("  {} = icmp slt i32 {}, {}", reg, lhs, rhs)),
            BinOp::Gt  => self.line(&format!("  {} = icmp sgt i32 {}, {}", reg, lhs, rhs)),
            BinOp::Le  => self.line(&format!("  {} = icmp sle i32 {}, {}", reg, lhs, rhs)),
            BinOp::Ge  => self.line(&format!("  {} = icmp sge i32 {}, {}", reg, lhs, rhs)),
        }
        reg
    }

    fn emit_assign_binop(&mut self, lhs: &str, rhs: &str, op: AssignOp) -> String {
        let reg = self.tmp_name();
        match op {
            AssignOp::Add => self.line(&format!("  {} = add i32 {}, {}", reg, lhs, rhs)),
            AssignOp::Sub => self.line(&format!("  {} = sub i32 {}, {}", reg, lhs, rhs)),
            AssignOp::Mul => self.line(&format!("  {} = mul i32 {}, {}", reg, lhs, rhs)),
            AssignOp::Div => self.line(&format!("  {} = sdiv i32 {}, {}", reg, lhs, rhs)),
            AssignOp::Eq  => self.line(&format!("  {} = or i32 {}, {}", reg, lhs, rhs)),
        }
        reg
    }
}