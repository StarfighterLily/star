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
    symbols: Vec<(String, String, Ty)>,
    /// Field name lists per struct, populated from the typed module so field
    /// indices can be resolved for any struct (not just a hardcoded set).
    struct_fields: std::collections::HashMap<String, Vec<String>>,
    /// Maps `"Struct.method"` -> `@method` so method calls (`obj.method()`) can
    /// be lowered to a direct function call with the receiver as `self`.
    methods: std::collections::HashMap<String, String>,
    errors: Vec<Diagnostic>,
}

impl Codegen {
    pub fn new() -> Self {
        Self {
            ir: String::new(),
            global_defs: Vec::new(),
            tmp: 0,
            globals: 0,
            symbols: Vec::new(),
            struct_fields: std::collections::HashMap::new(),
            methods: std::collections::HashMap::new(),
            errors: Vec::new(),
        }
    }

    /// Generate LLVM IR from a checked module, returning the `.ll` source.
    pub fn emit(&mut self, module: &TypedModule) -> Result<String, Vec<Diagnostic>> {
        self.line("; Star compiler -- LLVM IR");
        self.line("target triple = \"x86_64-w64-windows-gnu\"");
        self.line("");

        self.emit_builtins();

        for item in &module.items {
            if let TypedItem::Struct(s) = item {
                self.emit_struct_decl(s);
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
    }

    fn emit_struct_decl(&mut self, s: &TypedStructDef) {
        self.struct_fields
            .insert(s.name.clone(), s.fields.iter().map(|f| f.name.clone()).collect());
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

    fn line(&mut self, s: &str) { writeln!(self.ir, "{}", s).unwrap(); }
    fn write(&mut self, s: &str) { write!(self.ir, "{}", s).unwrap(); }
    fn err(&mut self, msg: &str, span: Span) { self.errors.push(Diagnostic::error(msg, span)); }

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

    fn emit_stmt(&mut self, stmt: &TypedStmt) {
        match stmt {
            TypedStmt::Let { name, value, .. } => {
                let ty = self.llvm_ty(&self.expr_ty(value));
                let ptr = self.tmp_name();
                self.line(&format!("  {} = alloca {}", ptr, ty));
                let reg = self.emit_expr(value);
                let clean_val = reg.strip_prefix(&format!("{} ", ty)).unwrap_or(&reg);
                self.line(&format!("  store {} {}, {}* {}", ty, clean_val, ty, ptr));
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
                self.line(&format!("  {} = load {}, {}* {}", reg, ts, ts, ptr));
                reg
            }
            TypedExpr::Field { base, field, ty, .. } => {
                let base_ptr = self.emit_expr(base);
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
                let base_ptr = self.emit_expr(base);
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
            TypedExpr::Float(v, _, _) => format!("float {}", v),
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
                let base_ptr = self.emit_expr(base);
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
                                        // For string arguments, `val` is the alloca
                                        // holding the `i8*`; load it to get the pointer
                                        // that `%s` expects.
                                        let arg_val = if matches!(ty, Ty::Str) {
                                            let loaded = self.tmp_name();
                                            self.line(&format!("  {} = load i8*, i8** {}", loaded, val));
                                            loaded
                                        } else {
                                            val
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
                                call_args.push(format!("{} {}", self.llvm_ty(ty), val));
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
            TypedExpr::StructLit { name, args, .. } => {
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
                self.line(&format!("  {} = load %{}, ptr {}", loaded, name, ptr));
                format!("%{} {}", name, loaded)
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
            TypedExpr::Error(_) => "%undef".into(),
        }
    }

    fn emit_binop(&mut self, lhs: &str, rhs: &str, op: BinOp) -> String {
        let reg = self.tmp_name();
        let l_reg = lhs.strip_prefix("i32 ").unwrap_or(lhs);
        let r_reg = rhs.strip_prefix("i32 ").unwrap_or(rhs);
        match op {
            BinOp::Add => self.line(&format!("  {} = add i32 {}, {}", reg, l_reg, r_reg)),
            BinOp::Sub => self.line(&format!("  {} = sub i32 {}, {}", reg, l_reg, r_reg)),
            BinOp::Mul => self.line(&format!("  {} = mul i32 {}, {}", reg, l_reg, r_reg)),
            BinOp::Div => self.line(&format!("  {} = sdiv i32 {}, {}", reg, l_reg, r_reg)),
            BinOp::Rem => self.line(&format!("  {} = srem i32 {}, {}", reg, l_reg, r_reg)),
            BinOp::Eq  => self.line(&format!("  {} = icmp eq i32 {}, {}", reg, l_reg, r_reg)),
            BinOp::Ne  => self.line(&format!("  {} = icmp ne i32 {}, {}", reg, l_reg, r_reg)),
            BinOp::Lt  => self.line(&format!("  {} = icmp slt i32 {}, {}", reg, l_reg, r_reg)),
            BinOp::Gt  => self.line(&format!("  {} = icmp sgt i32 {}, {}", reg, l_reg, r_reg)),
            BinOp::Le  => self.line(&format!("  {} = icmp sle i32 {}, {}", reg, l_reg, r_reg)),
            BinOp::Ge  => self.line(&format!("  {} = icmp sge i32 {}, {}", reg, l_reg, r_reg)),
        }
        format!("i32 {}", reg)
    }

    fn emit_assign_binop(&mut self, lhs: &str, rhs: &str, op: AssignOp) -> String {
        let reg = self.tmp_name();
        let l_reg = lhs.strip_prefix("i32 ").unwrap_or(lhs);
        let r_reg = rhs.strip_prefix("i32 ").unwrap_or(rhs);
        match op {
            AssignOp::Add => self.line(&format!("  {} = add i32 {}, {}", reg, l_reg, r_reg)),
            AssignOp::Sub => self.line(&format!("  {} = sub i32 {}, {}", reg, l_reg, r_reg)),
            AssignOp::Mul => self.line(&format!("  {} = mul i32 {}, {}", reg, l_reg, r_reg)),
            AssignOp::Div => self.line(&format!("  {} = sdiv i32 {}, {}", reg, l_reg, r_reg)),
            AssignOp::Eq  => self.line(&format!("  {} = or i32 {}, {}", reg, l_reg, r_reg)),
        }
        format!("i32 {}", reg)
    }
}
