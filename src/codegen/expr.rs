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
    /// once, then extracts via `extractvalue` (Vec2/Vec3) or
    /// `extractelement`/`shufflevector` (Vec4) as appropriate — no GEP is
    /// used since a swizzle result isn't a contiguous sub-object in general.
    pub(super) fn emit_swizzle_read(&mut self, base: &TypedExpr, field: &str) -> String {
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
    pub(super) fn emit_swizzle_write(&mut self, base: &TypedExpr, field: &str, val_ty: &Ty, val: &str) {
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

    /// A method call (`obj.method(args)`) or a direct free-function call
    /// (`name(args)`), lowered to `call @method(%Struct* obj, args...)` or
    /// `call @name(args...)` respectively.
    fn emit_call_expr(&mut self, callee: &TypedExpr, args: &[TypedExpr], expr: &TypedExpr) -> String {
        if let TypedExpr::Field { base, field, .. } = callee {
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

    pub(super) fn emit_expr(&mut self, expr: &TypedExpr) -> String {
        match expr {
            TypedExpr::Int(v, _, _) => format!("i32 {}", v),
            TypedExpr::Float(v, _, _) => format!("float {}", format_f32_literal(*v)),
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
                    _ => self.emit_call_expr(callee, args, expr),
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
            TypedExpr::GenRefCreate { inner_ty, value, span } => self.emit_genref_create(inner_ty, value, *span),
            TypedExpr::GenRefIndex { base, ty, span, .. } => self.emit_genref_index(base, ty, *span),
            TypedExpr::Error(_) => "%undef".into(),
        }
    }
}
