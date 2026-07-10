//! Scalar, vector (Vec2/Vec3/Vec4), and matrix (Mat4) arithmetic lowering.

use crate::ast::*;
use crate::diagnostics::Span;
use crate::types::*;

use super::{format_f32_literal, Codegen};

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
                // `&&`/`||` are intercepted in `Codegen::emit_expr`'s
                // `TypedExpr::Binary` arm (they need short-circuit,
                // branch-based lowering, not a plain opcode) and never
                // reach this generic scalar path.
                BinOp::And | BinOp::Or => { self.err("internal error: `&&`/`||` should be short-circuit lowered, not reach emit_scalar_binop", Span::dummy()); "add i32" }
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
            BinOp::And | BinOp::Or => { self.err("internal error: `&&`/`||` should be short-circuit lowered, not reach emit_scalar_binop", Span::dummy()); "fadd float" }
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

    /// Dot product of two already-untagged Vec2/Vec3/Vec4 registers of the
    /// same type, returning a bare `float` register. Shared by the `dot`
    /// builtin and `length` (`length(v) == sqrt(dot(v, v))`).
    fn emit_dot_bare(&mut self, a_bare: &str, b_bare: &str, ty: &Ty) -> String {
        match ty {
            Ty::Vec4 => self.emit_dot4(a_bare, b_bare),
            Ty::Vec2 | Ty::Vec3 => {
                let arity = ty.vec_arity().unwrap();
                let mut sum: Option<String> = None;
                for i in 0..arity as u32 {
                    let ac = self.extract_component(a_bare, ty, i);
                    let bc = self.extract_component(b_bare, ty, i);
                    let p = self.tmp_name();
                    self.line(&format!("  {} = fmul float {}, {}", p, ac, bc));
                    sum = Some(match sum {
                        None => p,
                        Some(s) => {
                            let r = self.tmp_name();
                            self.line(&format!("  {} = fadd float {}, {}", r, s, p));
                            r
                        }
                    });
                }
                sum.unwrap_or_else(|| "0.0".to_string())
            }
            _ => {
                self.err("dot(..)/length(..) expect a Vec2/Vec3/Vec4 argument", Span::dummy());
                "0.0".to_string()
            }
        }
    }

    /// `dot(a, b) -> f32`.
    pub(super) fn emit_dot(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("dot(..) expects 2 arguments", Span::dummy());
            return "float 0.0".into();
        }
        let ty = self.expr_ty(&args[0]);
        let a = self.emit_expr(&args[0]);
        let b = self.emit_expr(&args[1]);
        let a_bare = self.untag(&a, &ty);
        let b_bare = self.untag(&b, &ty);
        let result = self.emit_dot_bare(&a_bare, &b_bare, &ty);
        format!("float {}", result)
    }

    /// `length(v) -> f32`.
    pub(super) fn emit_length(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("length(..) expects 1 argument", Span::dummy());
            return "float 0.0".into();
        };
        let ty = self.expr_ty(arg);
        let v = self.emit_expr(arg);
        let bare = self.untag(&v, &ty);
        let dot_bare = self.emit_dot_bare(&bare, &bare, &ty);
        let reg = self.tmp_name();
        self.line(&format!("  {} = call float @llvm.sqrt.f32(float {})", reg, dot_bare));
        format!("float {}", reg)
    }

    /// `lerp(a, b, t) -> same type as a`: `a + (b - a) * t`, generic over
    /// `f32`/`Vec2`/`Vec3`/`Vec4`.
    pub(super) fn emit_lerp(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 3 {
            self.err("lerp(..) expects 3 arguments", Span::dummy());
            return "float 0.0".into();
        }
        let ty = self.expr_ty(&args[0]);
        let a = self.emit_expr(&args[0]);
        let b = self.emit_expr(&args[1]);
        let t_val = self.emit_expr(&args[2]);
        let t_ty = self.expr_ty(&args[2]);
        let t = self.promote_to_float(&t_val, &t_ty);
        match ty {
            Ty::Float => {
                let a_bare = self.untag(&a, &Ty::Float);
                let b_bare = self.untag(&b, &Ty::Float);
                let diff = self.tmp_name();
                self.line(&format!("  {} = fsub float {}, {}", diff, b_bare, a_bare));
                let scaled = self.tmp_name();
                self.line(&format!("  {} = fmul float {}, {}", scaled, diff, t));
                let result = self.tmp_name();
                self.line(&format!("  {} = fadd float {}, {}", result, a_bare, scaled));
                format!("float {}", result)
            }
            Ty::Vec2 | Ty::Vec3 | Ty::Vec4 => {
                let a_bare = self.untag(&a, &ty);
                let b_bare = self.untag(&b, &ty);
                let arity = ty.vec_arity().unwrap();
                let mut acc = "undef".to_string();
                for i in 0..arity as u32 {
                    let ac = self.extract_component(&a_bare, &ty, i);
                    let bc = self.extract_component(&b_bare, &ty, i);
                    let diff = self.tmp_name();
                    self.line(&format!("  {} = fsub float {}, {}", diff, bc, ac));
                    let scaled = self.tmp_name();
                    self.line(&format!("  {} = fmul float {}, {}", scaled, diff, t));
                    let comp = self.tmp_name();
                    self.line(&format!("  {} = fadd float {}, {}", comp, ac, scaled));
                    acc = self.insert_component(&acc, &ty, i, &comp);
                }
                format!("{} {}", self.llvm_ty(&ty), acc)
            }
            _ => {
                self.err("lerp(..) expects f32/Vec2/Vec3/Vec4 arguments", Span::dummy());
                "float 0.0".into()
            }
        }
    }

    /// `clamp(x, lo, hi) -> same type as x`, for `i32`/`f32`.
    pub(super) fn emit_clamp(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 3 {
            self.err("clamp(..) expects 3 arguments", Span::dummy());
            return "i32 0".into();
        }
        let ty = self.expr_ty(&args[0]);
        let x = self.emit_expr(&args[0]);
        let lo = self.emit_expr(&args[1]);
        let hi = self.emit_expr(&args[2]);
        if matches!(ty, Ty::Float) {
            let x_b = self.untag(&x, &Ty::Float);
            let lo_b = self.untag(&lo, &Ty::Float);
            let hi_b = self.untag(&hi, &Ty::Float);
            let m1 = self.tmp_name();
            self.line(&format!("  {} = call float @llvm.maxnum.f32(float {}, float {})", m1, x_b, lo_b));
            let m2 = self.tmp_name();
            self.line(&format!("  {} = call float @llvm.minnum.f32(float {}, float {})", m2, m1, hi_b));
            format!("float {}", m2)
        } else {
            let x_b = self.untag(&x, &Ty::Int);
            let lo_b = self.untag(&lo, &Ty::Int);
            let hi_b = self.untag(&hi, &Ty::Int);
            let c1 = self.tmp_name();
            self.line(&format!("  {} = icmp sgt i32 {}, {}", c1, lo_b, x_b));
            let m1 = self.tmp_name();
            self.line(&format!("  {} = select i1 {}, i32 {}, i32 {}", m1, c1, lo_b, x_b));
            let c2 = self.tmp_name();
            self.line(&format!("  {} = icmp slt i32 {}, {}", c2, hi_b, m1));
            let m2 = self.tmp_name();
            self.line(&format!("  {} = select i1 {}, i32 {}, i32 {}", m2, c2, hi_b, m1));
            format!("i32 {}", m2)
        }
    }

    /// Advance the `rand`/`rand_range` xorshift32 generator by one step,
    /// persisting the new state back to `@rng.state` and returning a bare
    /// `i32` register holding it.
    fn emit_rand_next(&mut self) -> String {
        let x0 = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* @rng.state", x0));
        let s1 = self.tmp_name();
        self.line(&format!("  {} = shl i32 {}, 13", s1, x0));
        let x1 = self.tmp_name();
        self.line(&format!("  {} = xor i32 {}, {}", x1, x0, s1));
        let s2 = self.tmp_name();
        self.line(&format!("  {} = lshr i32 {}, 17", s2, x1));
        let x2 = self.tmp_name();
        self.line(&format!("  {} = xor i32 {}, {}", x2, x1, s2));
        let s3 = self.tmp_name();
        self.line(&format!("  {} = shl i32 {}, 5", s3, x2));
        let x3 = self.tmp_name();
        self.line(&format!("  {} = xor i32 {}, {}", x3, x2, s3));
        self.line(&format!("  store i32 {}, i32* @rng.state", x3));
        x3
    }

    /// `rand() -> f32` in `[0, 1)`.
    pub(super) fn emit_rand(&mut self) -> String {
        let x = self.emit_rand_next();
        // Mask to the low 24 bits (a full `f32` mantissa's worth of
        // precision) and scale to `[0, 1)`.
        let masked = self.tmp_name();
        self.line(&format!("  {} = and i32 {}, 16777215", masked, x));
        let as_f = self.tmp_name();
        self.line(&format!("  {} = uitofp i32 {} to float", as_f, masked));
        let reg = self.tmp_name();
        self.line(&format!("  {} = fdiv float {}, {}", reg, as_f, format_f32_literal(16777216.0)));
        format!("float {}", reg)
    }

    /// `rand_range(lo, hi) -> i32` in `[lo, hi)`.
    pub(super) fn emit_rand_range(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("rand_range(..) expects 2 arguments", Span::dummy());
            return "i32 0".into();
        }
        let lo_v = self.emit_expr(&args[0]);
        let hi_v = self.emit_expr(&args[1]);
        let lo = self.untag(&lo_v, &Ty::Int);
        let hi = self.untag(&hi_v, &Ty::Int);
        let range = self.tmp_name();
        self.line(&format!("  {} = sub i32 {}, {}", range, hi, lo));
        // Guard against a non-positive range (misuse, e.g. `hi <= lo`)
        // rather than dividing by zero/a negative modulus.
        let is_le0 = self.tmp_name();
        self.line(&format!("  {} = icmp sle i32 {}, 0", is_le0, range));
        let safe_range = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 1, i32 {}", safe_range, is_le0, range));
        let x = self.emit_rand_next();
        let unsigned = self.tmp_name();
        self.line(&format!("  {} = and i32 {}, 2147483647", unsigned, x));
        let m = self.tmp_name();
        self.line(&format!("  {} = urem i32 {}, {}", m, unsigned, safe_range));
        let result = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, {}", result, lo, m));
        format!("i32 {}", result)
    }

    /// `rand_seed(seed)`: reseed the generator (guarding against a `0` seed,
    /// which would make xorshift32 output `0` forever).
    pub(super) fn emit_rand_seed(&mut self, args: &[TypedExpr]) {
        let Some(arg) = args.first() else {
            self.err("rand_seed(..) expects 1 argument", Span::dummy());
            return;
        };
        let v = self.emit_expr(arg);
        let bare = self.untag(&v, &Ty::Int);
        let is_zero = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 0", is_zero, bare));
        let safe = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 1, i32 {}", safe, is_zero, bare));
        self.line(&format!("  store i32 {}, i32* @rng.state", safe));
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
