//! Scalar, vector (Vec2/Vec3/Vec4), and matrix (Mat4) arithmetic lowering.

use crate::ast::*;
use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

impl Codegen {
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

    pub(super) fn emit_binop(&mut self, lhs: &str, lty: &Ty, rhs: &str, rty: &Ty, op: BinOp) -> String {
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

    pub(super) fn emit_assign_binop(&mut self, lhs: &str, lty: &Ty, rhs: &str, rty: &Ty, op: AssignOp) -> String {
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
