//! `docs/design.md`'s "Math and geometry" section: free-function codegen for
//! `Quat` (`quat_identity`/`quat_conjugate`/`quat_normalize`/`quat_rotate`),
//! the builtin geometry structs (`rect_contains`/`rect_intersects`/
//! `aabb2_contains`/`aabb2_intersects`/`aabb3_contains`/`aabb3_intersects`/
//! `ray_at`/`plane_distance_to_point`/`frustum_contains_point`/
//! `transform_apply_point`), and `Color`/`Color32` conversion
//! (`color32_r`/`color32_g`/`color32_b`/`color32_a`/`color_to_color32`/
//! `color32_to_color`).
//!
//! `Rect`/`Aabb2`/`Aabb3`/`Transform`/`Ray`/`Plane`/`Frustum` themselves need
//! no codegen at all beyond what an ordinary user-declared `struct` already
//! gets (see `crate::types::builtin_structs`'s doc comment) -- every function
//! here just reads their already-laid-out fields via a plain `extractvalue`,
//! the same mechanism `crate::codegen::eq`'s `Ty::Named` structural-equality
//! arm already uses.

use crate::types::*;

use super::{format_f32_literal, Codegen};

impl Codegen {
    /// `extractvalue` one field of an already-loaded, already-untagged
    /// builtin-struct value by name, resolving its position the same way an
    /// ordinary `obj.field` read does (`Codegen::field_index`).
    fn extract_named_field(&mut self, base_bare: &str, struct_name: &str, field: &str) -> String {
        let idx = self.field_index(&Ty::Named(struct_name.into()), field);
        let struct_llty = format!("%{}", struct_name);
        let reg = self.tmp_name();
        self.line(&format!("  {} = extractvalue {} {}, {}", reg, struct_llty, base_bare, idx));
        reg
    }

    /// `fcmp <pred> float a, b`, returning a bare `i1`.
    fn emit_fcmp(&mut self, pred: &str, a: &str, b: &str) -> String {
        let reg = self.tmp_name();
        self.line(&format!("  {} = fcmp {} float {}, {}", reg, pred, a, b));
        reg
    }

    /// `and i1 a, b`.
    fn emit_and_bool(&mut self, a: &str, b: &str) -> String {
        let reg = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", reg, a, b));
        reg
    }

    /// Dot product of two already-untagged, same-arity bare vector registers,
    /// component-by-component (`extract_component` + `fmul`/`fadd`) rather
    /// than `crate::codegen::vector_math`'s native-vector `emit_dot_vec`
    /// (private to that module) -- used by `plane_distance_bare` below.
    fn dot_bare(&mut self, a: &str, b: &str, ty: &Ty, arity: u32) -> String {
        let mut sum: Option<String> = None;
        for i in 0..arity {
            let ac = self.extract_component(a, ty, i);
            let bc = self.extract_component(b, ty, i);
            let prod = self.emit_fmul(&ac, &bc);
            sum = Some(match sum {
                None => prod,
                Some(s) => self.emit_fadd(&s, &prod),
            });
        }
        sum.unwrap_or_else(|| format_f32_literal(0.0))
    }

    /// `quat_identity() -> Quat`: the identity rotation `(0, 0, 0, 1)`.
    pub(super) fn emit_quat_identity(&mut self) -> String {
        let zero = format_f32_literal(0.0);
        let one = format_f32_literal(1.0);
        let mut acc = "undef".to_string();
        acc = self.insert_component(&acc, &Ty::Quat, 0, &zero);
        acc = self.insert_component(&acc, &Ty::Quat, 1, &zero);
        acc = self.insert_component(&acc, &Ty::Quat, 2, &zero);
        acc = self.insert_component(&acc, &Ty::Quat, 3, &one);
        format!("{} {}", self.llvm_ty(&Ty::Quat), acc)
    }

    /// The conjugate of an already-untagged bare `Quat` register:
    /// `(-x, -y, -z, w)`. Factored out of `emit_quat_conjugate` (the public
    /// `quat_conjugate(q)` builtin) so `quat_rotate_bare` below can reuse it
    /// without re-evaluating/re-untagging its argument.
    fn quat_conjugate_bare(&mut self, q: &str) -> String {
        let x = self.extract_component(q, &Ty::Quat, 0);
        let y = self.extract_component(q, &Ty::Quat, 1);
        let z = self.extract_component(q, &Ty::Quat, 2);
        let w = self.extract_component(q, &Ty::Quat, 3);
        let nx = self.emit_fneg(&x);
        let ny = self.emit_fneg(&y);
        let nz = self.emit_fneg(&z);
        let mut acc = "undef".to_string();
        acc = self.insert_component(&acc, &Ty::Quat, 0, &nx);
        acc = self.insert_component(&acc, &Ty::Quat, 1, &ny);
        acc = self.insert_component(&acc, &Ty::Quat, 2, &nz);
        acc = self.insert_component(&acc, &Ty::Quat, 3, &w);
        acc
    }

    pub(super) fn emit_quat_conjugate(&mut self, args: &[TypedExpr]) -> String {
        let q_val = self.emit_expr(&args[0]);
        let q = self.untag(&q_val, &Ty::Quat);
        let acc = self.quat_conjugate_bare(&q);
        format!("{} {}", self.llvm_ty(&Ty::Quat), acc)
    }

    /// `quat_normalize(q) -> Quat`: `q / length(q)`, computed directly
    /// (rather than reusing `dot`/`length`'s codegen, which operate on a
    /// `TypedExpr` argument list, not an already-evaluated bare register).
    pub(super) fn emit_quat_normalize(&mut self, args: &[TypedExpr]) -> String {
        let q_val = self.emit_expr(&args[0]);
        let q = self.untag(&q_val, &Ty::Quat);
        let x = self.extract_component(&q, &Ty::Quat, 0);
        let y = self.extract_component(&q, &Ty::Quat, 1);
        let z = self.extract_component(&q, &Ty::Quat, 2);
        let w = self.extract_component(&q, &Ty::Quat, 3);
        let sum = self.dot_bare(&q, &q, &Ty::Quat, 4);
        let len = self.tmp_name();
        self.line(&format!("  {} = call float @llvm.sqrt.f32(float {})", len, sum));
        let nx = self.emit_fdiv(&x, &len);
        let ny = self.emit_fdiv(&y, &len);
        let nz = self.emit_fdiv(&z, &len);
        let nw = self.emit_fdiv(&w, &len);
        let mut acc = "undef".to_string();
        acc = self.insert_component(&acc, &Ty::Quat, 0, &nx);
        acc = self.insert_component(&acc, &Ty::Quat, 1, &ny);
        acc = self.insert_component(&acc, &Ty::Quat, 2, &nz);
        acc = self.insert_component(&acc, &Ty::Quat, 3, &nw);
        format!("{} {}", self.llvm_ty(&Ty::Quat), acc)
    }

    /// Rotate an already-untagged bare `Vec3` register `v` by an
    /// already-untagged bare `Quat` register `q`, via `q * (v, 0) * conj(q)`
    /// (dropping the resulting quaternion's `w`, which is always `0` for a
    /// unit `q`) -- reuses `crate::codegen::vector_math::emit_quat_mul`
    /// wholesale rather than re-deriving the equivalent cross-product
    /// formula. Shared by the public `quat_rotate(q, v)` builtin and
    /// `transform_apply_point`.
    fn quat_rotate_bare(&mut self, q: &str, v: &str) -> String {
        let vx = self.extract_component(v, &Ty::Vec3, 0);
        let vy = self.extract_component(v, &Ty::Vec3, 1);
        let vz = self.extract_component(v, &Ty::Vec3, 2);
        let zero = format_f32_literal(0.0);
        let mut qv = "undef".to_string();
        qv = self.insert_component(&qv, &Ty::Quat, 0, &vx);
        qv = self.insert_component(&qv, &Ty::Quat, 1, &vy);
        qv = self.insert_component(&qv, &Ty::Quat, 2, &vz);
        qv = self.insert_component(&qv, &Ty::Quat, 3, &zero);
        let q_conj = self.quat_conjugate_bare(q);

        let q_tagged = format!("{} {}", self.llvm_ty(&Ty::Quat), q);
        let qv_tagged = format!("{} {}", self.llvm_ty(&Ty::Quat), qv);
        let tmp = self.emit_quat_mul(&q_tagged, &qv_tagged);
        let tmp_bare = self.untag(&tmp, &Ty::Quat);

        let tmp_tagged = format!("{} {}", self.llvm_ty(&Ty::Quat), tmp_bare);
        let qconj_tagged = format!("{} {}", self.llvm_ty(&Ty::Quat), q_conj);
        let result = self.emit_quat_mul(&tmp_tagged, &qconj_tagged);
        let result_bare = self.untag(&result, &Ty::Quat);

        let rx = self.extract_component(&result_bare, &Ty::Quat, 0);
        let ry = self.extract_component(&result_bare, &Ty::Quat, 1);
        let rz = self.extract_component(&result_bare, &Ty::Quat, 2);
        let mut acc = "undef".to_string();
        acc = self.insert_component(&acc, &Ty::Vec3, 0, &rx);
        acc = self.insert_component(&acc, &Ty::Vec3, 1, &ry);
        acc = self.insert_component(&acc, &Ty::Vec3, 2, &rz);
        acc
    }

    pub(super) fn emit_quat_rotate(&mut self, args: &[TypedExpr]) -> String {
        let q_val = self.emit_expr(&args[0]);
        let q = self.untag(&q_val, &Ty::Quat);
        let v_val = self.emit_expr(&args[1]);
        let v = self.untag(&v_val, &Ty::Vec3);
        let result = self.quat_rotate_bare(&q, &v);
        format!("{} {}", self.llvm_ty(&Ty::Vec3), result)
    }

    /// `rect_contains(r, p) -> bool`.
    pub(super) fn emit_rect_contains(&mut self, args: &[TypedExpr]) -> String {
        let r_val = self.emit_expr(&args[0]);
        let r = self.untag(&r_val, &Ty::Named("Rect".into()));
        let p_val = self.emit_expr(&args[1]);
        let p = self.untag(&p_val, &Ty::Vec2);
        let rx = self.extract_named_field(&r, "Rect", "x");
        let ry = self.extract_named_field(&r, "Rect", "y");
        let rw = self.extract_named_field(&r, "Rect", "width");
        let rh = self.extract_named_field(&r, "Rect", "height");
        let px = self.extract_component(&p, &Ty::Vec2, 0);
        let py = self.extract_component(&p, &Ty::Vec2, 1);
        let x_max = self.emit_fadd(&rx, &rw);
        let y_max = self.emit_fadd(&ry, &rh);
        let c1 = self.emit_fcmp("oge", &px, &rx);
        let c2 = self.emit_fcmp("ole", &px, &x_max);
        let c3 = self.emit_fcmp("oge", &py, &ry);
        let c4 = self.emit_fcmp("ole", &py, &y_max);
        let a1 = self.emit_and_bool(&c1, &c2);
        let a2 = self.emit_and_bool(&a1, &c3);
        let result = self.emit_and_bool(&a2, &c4);
        format!("i1 {}", result)
    }

    /// `rect_intersects(a, b) -> bool`.
    pub(super) fn emit_rect_intersects(&mut self, args: &[TypedExpr]) -> String {
        let a_val = self.emit_expr(&args[0]);
        let a = self.untag(&a_val, &Ty::Named("Rect".into()));
        let b_val = self.emit_expr(&args[1]);
        let b = self.untag(&b_val, &Ty::Named("Rect".into()));
        let ax = self.extract_named_field(&a, "Rect", "x");
        let ay = self.extract_named_field(&a, "Rect", "y");
        let aw = self.extract_named_field(&a, "Rect", "width");
        let ah = self.extract_named_field(&a, "Rect", "height");
        let bx = self.extract_named_field(&b, "Rect", "x");
        let by = self.extract_named_field(&b, "Rect", "y");
        let bw = self.extract_named_field(&b, "Rect", "width");
        let bh = self.extract_named_field(&b, "Rect", "height");
        let a_xmax = self.emit_fadd(&ax, &aw);
        let a_ymax = self.emit_fadd(&ay, &ah);
        let b_xmax = self.emit_fadd(&bx, &bw);
        let b_ymax = self.emit_fadd(&by, &bh);
        let c1 = self.emit_fcmp("ole", &ax, &b_xmax);
        let c2 = self.emit_fcmp("ole", &bx, &a_xmax);
        let c3 = self.emit_fcmp("ole", &ay, &b_ymax);
        let c4 = self.emit_fcmp("ole", &by, &a_ymax);
        let r1 = self.emit_and_bool(&c1, &c2);
        let r2 = self.emit_and_bool(&r1, &c3);
        let result = self.emit_and_bool(&r2, &c4);
        format!("i1 {}", result)
    }

    /// `aabb2_contains(a, p) -> bool`.
    pub(super) fn emit_aabb2_contains(&mut self, args: &[TypedExpr]) -> String {
        let a_val = self.emit_expr(&args[0]);
        let a = self.untag(&a_val, &Ty::Named("Aabb2".into()));
        let p_val = self.emit_expr(&args[1]);
        let p = self.untag(&p_val, &Ty::Vec2);
        let min = self.extract_named_field(&a, "Aabb2", "min");
        let max = self.extract_named_field(&a, "Aabb2", "max");
        let min_x = self.extract_component(&min, &Ty::Vec2, 0);
        let min_y = self.extract_component(&min, &Ty::Vec2, 1);
        let max_x = self.extract_component(&max, &Ty::Vec2, 0);
        let max_y = self.extract_component(&max, &Ty::Vec2, 1);
        let px = self.extract_component(&p, &Ty::Vec2, 0);
        let py = self.extract_component(&p, &Ty::Vec2, 1);
        let c1 = self.emit_fcmp("oge", &px, &min_x);
        let c2 = self.emit_fcmp("ole", &px, &max_x);
        let c3 = self.emit_fcmp("oge", &py, &min_y);
        let c4 = self.emit_fcmp("ole", &py, &max_y);
        let a1 = self.emit_and_bool(&c1, &c2);
        let a2 = self.emit_and_bool(&a1, &c3);
        let result = self.emit_and_bool(&a2, &c4);
        format!("i1 {}", result)
    }

    /// `aabb2_intersects(a, b) -> bool`.
    pub(super) fn emit_aabb2_intersects(&mut self, args: &[TypedExpr]) -> String {
        let a_val = self.emit_expr(&args[0]);
        let a = self.untag(&a_val, &Ty::Named("Aabb2".into()));
        let b_val = self.emit_expr(&args[1]);
        let b = self.untag(&b_val, &Ty::Named("Aabb2".into()));
        let a_min = self.extract_named_field(&a, "Aabb2", "min");
        let a_max = self.extract_named_field(&a, "Aabb2", "max");
        let b_min = self.extract_named_field(&b, "Aabb2", "min");
        let b_max = self.extract_named_field(&b, "Aabb2", "max");
        let a_min_x = self.extract_component(&a_min, &Ty::Vec2, 0);
        let a_min_y = self.extract_component(&a_min, &Ty::Vec2, 1);
        let a_max_x = self.extract_component(&a_max, &Ty::Vec2, 0);
        let a_max_y = self.extract_component(&a_max, &Ty::Vec2, 1);
        let b_min_x = self.extract_component(&b_min, &Ty::Vec2, 0);
        let b_min_y = self.extract_component(&b_min, &Ty::Vec2, 1);
        let b_max_x = self.extract_component(&b_max, &Ty::Vec2, 0);
        let b_max_y = self.extract_component(&b_max, &Ty::Vec2, 1);
        let c1 = self.emit_fcmp("ole", &a_min_x, &b_max_x);
        let c2 = self.emit_fcmp("ole", &b_min_x, &a_max_x);
        let c3 = self.emit_fcmp("ole", &a_min_y, &b_max_y);
        let c4 = self.emit_fcmp("ole", &b_min_y, &a_max_y);
        let r1 = self.emit_and_bool(&c1, &c2);
        let r2 = self.emit_and_bool(&r1, &c3);
        let result = self.emit_and_bool(&r2, &c4);
        format!("i1 {}", result)
    }

    /// `aabb3_contains(a, p) -> bool` -- same shape as `aabb2_contains`, one
    /// more axis.
    pub(super) fn emit_aabb3_contains(&mut self, args: &[TypedExpr]) -> String {
        let a_val = self.emit_expr(&args[0]);
        let a = self.untag(&a_val, &Ty::Named("Aabb3".into()));
        let p_val = self.emit_expr(&args[1]);
        let p = self.untag(&p_val, &Ty::Vec3);
        let min = self.extract_named_field(&a, "Aabb3", "min");
        let max = self.extract_named_field(&a, "Aabb3", "max");
        let mut acc: Option<String> = None;
        for i in 0u32..3 {
            let lo = self.extract_component(&min, &Ty::Vec3, i);
            let hi = self.extract_component(&max, &Ty::Vec3, i);
            let c = self.extract_component(&p, &Ty::Vec3, i);
            let c1 = self.emit_fcmp("oge", &c, &lo);
            let c2 = self.emit_fcmp("ole", &c, &hi);
            let both = self.emit_and_bool(&c1, &c2);
            acc = Some(match acc {
                None => both,
                Some(prev) => self.emit_and_bool(&prev, &both),
            });
        }
        format!("i1 {}", acc.expect("Vec3 has 3 components"))
    }

    /// `aabb3_intersects(a, b) -> bool` -- same shape as `aabb2_intersects`,
    /// one more axis.
    pub(super) fn emit_aabb3_intersects(&mut self, args: &[TypedExpr]) -> String {
        let a_val = self.emit_expr(&args[0]);
        let a = self.untag(&a_val, &Ty::Named("Aabb3".into()));
        let b_val = self.emit_expr(&args[1]);
        let b = self.untag(&b_val, &Ty::Named("Aabb3".into()));
        let a_min = self.extract_named_field(&a, "Aabb3", "min");
        let a_max = self.extract_named_field(&a, "Aabb3", "max");
        let b_min = self.extract_named_field(&b, "Aabb3", "min");
        let b_max = self.extract_named_field(&b, "Aabb3", "max");
        let mut acc: Option<String> = None;
        for i in 0u32..3 {
            let amin = self.extract_component(&a_min, &Ty::Vec3, i);
            let amax = self.extract_component(&a_max, &Ty::Vec3, i);
            let bmin = self.extract_component(&b_min, &Ty::Vec3, i);
            let bmax = self.extract_component(&b_max, &Ty::Vec3, i);
            let c1 = self.emit_fcmp("ole", &amin, &bmax);
            let c2 = self.emit_fcmp("ole", &bmin, &amax);
            let both = self.emit_and_bool(&c1, &c2);
            acc = Some(match acc {
                None => both,
                Some(prev) => self.emit_and_bool(&prev, &both),
            });
        }
        format!("i1 {}", acc.expect("Vec3 has 3 components"))
    }

    /// `ray_at(r, t) -> Vec3`: `origin + direction * t`.
    pub(super) fn emit_ray_at(&mut self, args: &[TypedExpr]) -> String {
        let r_val = self.emit_expr(&args[0]);
        let r = self.untag(&r_val, &Ty::Named("Ray".into()));
        let t_ty = self.expr_ty(&args[1]);
        let t_val = self.emit_expr(&args[1]);
        let t = self.promote_to_float(&t_val, &t_ty);
        let origin = self.extract_named_field(&r, "Ray", "origin");
        let direction = self.extract_named_field(&r, "Ray", "direction");
        let mut acc = "undef".to_string();
        for i in 0u32..3 {
            let o = self.extract_component(&origin, &Ty::Vec3, i);
            let d = self.extract_component(&direction, &Ty::Vec3, i);
            let scaled = self.emit_fmul(&d, &t);
            let sum = self.emit_fadd(&o, &scaled);
            acc = self.insert_component(&acc, &Ty::Vec3, i, &sum);
        }
        format!("{} {}", self.llvm_ty(&Ty::Vec3), acc)
    }

    /// `dot(plane.normal, p) - plane.distance`, on already-untagged bare
    /// registers. Factored out so `frustum_contains_point` can reuse it
    /// against each of a `Frustum`'s six planes without re-evaluating/
    /// re-untagging its arguments six times.
    fn plane_distance_bare(&mut self, plane_bare: &str, p_bare: &str) -> String {
        let normal = self.extract_named_field(plane_bare, "Plane", "normal");
        let distance = self.extract_named_field(plane_bare, "Plane", "distance");
        let dot = self.dot_bare(&normal, p_bare, &Ty::Vec3, 3);
        self.emit_fsub(&dot, &distance)
    }

    /// `plane_distance_to_point(pl, p) -> f32`.
    pub(super) fn emit_plane_distance_to_point(&mut self, args: &[TypedExpr]) -> String {
        let pl_val = self.emit_expr(&args[0]);
        let pl = self.untag(&pl_val, &Ty::Named("Plane".into()));
        let p_val = self.emit_expr(&args[1]);
        let p = self.untag(&p_val, &Ty::Vec3);
        let result = self.plane_distance_bare(&pl, &p);
        format!("float {}", result)
    }

    /// `frustum_contains_point(f, p) -> bool`: `p` is inside every one of
    /// `f`'s six half-spaces (`plane_distance_to_point(plane, p) >= 0`).
    pub(super) fn emit_frustum_contains_point(&mut self, args: &[TypedExpr]) -> String {
        let f_val = self.emit_expr(&args[0]);
        let f = self.untag(&f_val, &Ty::Named("Frustum".into()));
        let p_val = self.emit_expr(&args[1]);
        let p = self.untag(&p_val, &Ty::Vec3);
        let planes = self.extract_named_field(&f, "Frustum", "planes");
        let array_ty = "[6 x %Plane]";
        let mut acc: Option<String> = None;
        for i in 0u32..6 {
            let plane = self.tmp_name();
            self.line(&format!("  {} = extractvalue {} {}, {}", plane, array_ty, planes, i));
            let dist = self.plane_distance_bare(&plane, &p);
            let zero = format_f32_literal(0.0);
            let nonneg = self.emit_fcmp("oge", &dist, &zero);
            acc = Some(match acc {
                None => nonneg,
                Some(prev) => self.emit_and_bool(&prev, &nonneg),
            });
        }
        format!("i1 {}", acc.expect("Frustum always has exactly 6 planes"))
    }

    /// `transform_apply_point(t, p) -> Vec3`: `t.position + quat_rotate(t.rotation, p * t.scale)`.
    pub(super) fn emit_transform_apply_point(&mut self, args: &[TypedExpr]) -> String {
        let t_val = self.emit_expr(&args[0]);
        let t = self.untag(&t_val, &Ty::Named("Transform".into()));
        let p_val = self.emit_expr(&args[1]);
        let p = self.untag(&p_val, &Ty::Vec3);
        let position = self.extract_named_field(&t, "Transform", "position");
        let rotation = self.extract_named_field(&t, "Transform", "rotation");
        let scale = self.extract_named_field(&t, "Transform", "scale");
        let mut scaled = "undef".to_string();
        for i in 0u32..3 {
            let pc = self.extract_component(&p, &Ty::Vec3, i);
            let sc = self.extract_component(&scale, &Ty::Vec3, i);
            let m = self.emit_fmul(&pc, &sc);
            scaled = self.insert_component(&scaled, &Ty::Vec3, i, &m);
        }
        let rotated = self.quat_rotate_bare(&rotation, &scaled);
        let mut acc = "undef".to_string();
        for i in 0u32..3 {
            let pos_c = self.extract_component(&position, &Ty::Vec3, i);
            let rot_c = self.extract_component(&rotated, &Ty::Vec3, i);
            let sum = self.emit_fadd(&pos_c, &rot_c);
            acc = self.insert_component(&acc, &Ty::Vec3, i, &sum);
        }
        format!("{} {}", self.llvm_ty(&Ty::Vec3), acc)
    }

    /// `Color32(r, g, b, a)`: pack four 0-255 channel values (any int-shaped
    /// type, widened/narrowed to `i32` per `Codegen::emit_time_new`'s own
    /// int-shaped-widen convention) into `r | g<<8 | b<<16 | a<<24`. Each
    /// channel is masked to a single byte first so an out-of-range value
    /// (e.g. a negative `i8`, or an `i32` above 255) can't corrupt a
    /// neighboring channel's bits once shifted into position.
    pub(super) fn emit_color32_new(&mut self, args: &[TypedExpr]) -> String {
        let mut packed: Option<String> = None;
        for (i, a) in args.iter().enumerate() {
            let ty = self.expr_ty(a);
            let val = self.emit_expr(a);
            let bare = self.untag(&val, &ty);
            let (width, signed) = ty.int_shape().expect("Checker::check_builtin_ctor_arity guarantees an int-shaped Color32 channel argument");
            let as_i32 = if width == 32 {
                bare
            } else if width < 32 {
                let reg = self.tmp_name();
                let op = if signed { "sext" } else { "zext" };
                self.line(&format!("  {} = {} i{} {} to i32", reg, op, width, bare));
                reg
            } else {
                let reg = self.tmp_name();
                self.line(&format!("  {} = trunc i{} {} to i32", reg, width, bare));
                reg
            };
            let masked = self.tmp_name();
            self.line(&format!("  {} = and i32 {}, 255", masked, as_i32));
            let shifted = if i == 0 {
                masked
            } else {
                let reg = self.tmp_name();
                self.line(&format!("  {} = shl i32 {}, {}", reg, masked, i * 8));
                reg
            };
            packed = Some(match packed {
                None => shifted,
                Some(prev) => {
                    let reg = self.tmp_name();
                    self.line(&format!("  {} = or i32 {}, {}", reg, prev, shifted));
                    reg
                }
            });
        }
        format!("i32 {}", packed.unwrap_or_else(|| "0".to_string()))
    }

    /// `color32_r`/`color32_g`/`color32_b`/`color32_a`: unpack one 0-255
    /// channel (`channel` is 0/1/2/3) from a `Color32`'s packed `i32`.
    pub(super) fn emit_color32_channel(&mut self, args: &[TypedExpr], channel: u32) -> String {
        let val = self.emit_expr(&args[0]);
        let bare = self.untag(&val, &Ty::Color32);
        let shifted = if channel == 0 {
            bare
        } else {
            let reg = self.tmp_name();
            self.line(&format!("  {} = lshr i32 {}, {}", reg, bare, channel * 8));
            reg
        };
        let masked = self.tmp_name();
        self.line(&format!("  {} = and i32 {}, 255", masked, shifted));
        format!("i32 {}", masked)
    }

    /// `color_to_color32(c) -> Color32`: each `f32` channel (an HDR `Color`
    /// may exceed `[0, 1]`) is clamped to `[0, 1]` via the same
    /// `llvm.maxnum.f32`/`llvm.minnum.f32` intrinsics `Codegen::emit_clamp`
    /// already declares unconditionally, scaled to `[0, 255]`, then rounded
    /// via the saturating `llvm.fptoui.sat.i32.f32` intrinsic (also declared
    /// unconditionally, see `Codegen::emit_builtins`) -- safe from the
    /// undefined-behavior hazard a plain `fptoui` would have on an
    /// out-of-range/NaN input, mirroring `Codegen::emit_cast`'s own
    /// float-to-int rule.
    pub(super) fn emit_color_to_color32(&mut self, args: &[TypedExpr]) -> String {
        let val = self.emit_expr(&args[0]);
        let c = self.untag(&val, &Ty::Color);
        let zero = format_f32_literal(0.0);
        let one = format_f32_literal(1.0);
        let scale = format_f32_literal(255.0);
        let mut packed: Option<String> = None;
        for i in 0u32..4 {
            let lane = self.extract_component(&c, &Ty::Color, i);
            let clamped_lo = self.tmp_name();
            self.line(&format!("  {} = call float @llvm.maxnum.f32(float {}, float {})", clamped_lo, lane, zero));
            let clamped = self.tmp_name();
            self.line(&format!("  {} = call float @llvm.minnum.f32(float {}, float {})", clamped, clamped_lo, one));
            let scaled = self.emit_fmul(&clamped, &scale);
            let byte = self.tmp_name();
            self.line(&format!("  {} = call i32 @llvm.fptoui.sat.i32.f32(float {})", byte, scaled));
            let shifted = if i == 0 {
                byte
            } else {
                let reg = self.tmp_name();
                self.line(&format!("  {} = shl i32 {}, {}", reg, byte, i * 8));
                reg
            };
            packed = Some(match packed {
                None => shifted,
                Some(prev) => {
                    let reg = self.tmp_name();
                    self.line(&format!("  {} = or i32 {}, {}", reg, prev, shifted));
                    reg
                }
            });
        }
        format!("i32 {}", packed.expect("Color always has exactly 4 channels"))
    }

    /// `color32_to_color(c) -> Color`: unpack each 0-255 byte and rescale to
    /// `[0, 1]`.
    pub(super) fn emit_color32_to_color(&mut self, args: &[TypedExpr]) -> String {
        let val = self.emit_expr(&args[0]);
        let c32 = self.untag(&val, &Ty::Color32);
        let scale = format_f32_literal(255.0);
        let mut acc = "undef".to_string();
        for i in 0u32..4 {
            let shifted = if i == 0 {
                c32.clone()
            } else {
                let reg = self.tmp_name();
                self.line(&format!("  {} = lshr i32 {}, {}", reg, c32, i * 8));
                reg
            };
            let byte = self.tmp_name();
            self.line(&format!("  {} = and i32 {}, 255", byte, shifted));
            let as_f = self.tmp_name();
            self.line(&format!("  {} = uitofp i32 {} to float", as_f, byte));
            let scaled = self.emit_fdiv(&as_f, &scale);
            acc = self.insert_component(&acc, &Ty::Color, i, &scaled);
        }
        format!("{} {}", self.llvm_ty(&Ty::Color), acc)
    }

    /// `PaletteIndex(value)`: narrow an int-shaped `value` to `u8` (mirrors
    /// `Codegen::emit_time_new`'s widen/narrow rule, minus the widen case --
    /// `int_shape()`'s narrowest width is already 8).
    pub(super) fn emit_palette_index_new(&mut self, value: &TypedExpr) -> String {
        let value_ty = self.expr_ty(value);
        let val = self.emit_expr(value);
        let bare = self.untag(&val, &value_ty);
        let (width, _signed) = value_ty
            .int_shape()
            .expect("Checker::check_builtin_ctor_arity guarantees an int-shaped constructor argument");
        if width == 8 {
            return format!("i8 {}", bare);
        }
        let reg = self.tmp_name();
        self.line(&format!("  {} = trunc i{} {} to i8", reg, width, bare));
        format!("i8 {}", reg)
    }
}
