//! Structural equality codegen for `Map<K,V>`/`Set<T>` keys and elements.
//!
//! `Map`/`Set` have no hashing/bucketing story yet (see `crate::codegen::map`'s
//! doc comment) -- membership is a linear scan comparing each stored key/
//! element against the query with a generated `eq_<mangled_ty>` function,
//! lazily created once per concrete key/element type and cached the same way
//! `crate::codegen::list`'s release thunks are. Only the types
//! `Checker::check_hashable_ty` accepts ever reach this module: `i32`/`f32`/
//! `bool`/`str`/a fieldless `enum`/`Vec2`/`Vec3`/`Vec4`, or a `struct`
//! composed entirely of such fields, recursively.

use crate::types::*;

use super::Codegen;

impl Codegen {
    /// Lazily generate (and cache, keyed by `Codegen::mangle_ty`) a
    /// structural-equality function `@eq_<mangled>(T %a, T %b) -> i1` for
    /// `ty`, returning its bare `@`-prefixed name. Unlike a list release
    /// thunk (passed around as an opaque `i8*` operand), every call site
    /// here knows `ty` statically, so callers just `call i1 @name(...)`
    /// directly.
    pub(super) fn eq_fn_name(&mut self, ty: &Ty) -> String {
        let key = self.mangle_ty(ty);
        if let Some(name) = self.eq_fns.get(&key).cloned() {
            return name;
        }
        let name = format!("eq_{}", key);
        // Reserve the name before generating the body -- cheap insurance
        // against infinite recursion through a self-referential struct
        // field, even though `Checker::check_no_recursive_structs` already
        // rejects those outright.
        self.eq_fns.insert(key, name.clone());

        let llvm = self.llvm_ty(ty);
        let saved_ir = std::mem::take(&mut self.ir);
        self.line(&format!("define i1 @{}({} %a, {} %b) {{", name, llvm, llvm));
        self.open_block("entry");
        let result = self.emit_eq_body("%a", "%b", ty);
        self.line(&format!("  ret i1 {}", result));
        self.line("}");
        self.line("");
        let fn_ir = std::mem::replace(&mut self.ir, saved_ir);
        self.pending_top.push(fn_ir);
        name
    }

    /// Emit the comparison body for `eq_fn_name`, given two already-loaded
    /// values of type `ty` (bare registers or literals, no `<llvm-ty> `
    /// tag), returning a bare `i1` register or literal. Recurses inline
    /// (not through another `eq_fn_name`/`call`) for `Vec2`/`Vec3`/`Vec4`
    /// lanes and `Named` struct fields, since those are only ever reached
    /// once per top-level `eq_fn_name` generation, not once per comparison
    /// at a call site.
    fn emit_eq_body(&mut self, a: &str, b: &str, ty: &Ty) -> String {
        match ty {
            // A fieldless enum is a bare `i32` discriminant -- same
            // comparison as `Ty::Int`. (A payload enum never reaches here:
            // `Checker::check_hashable_ty` rejects it before this module
            // ever sees it.)
            Ty::Int | Ty::Enum(_) => {
                let r = self.tmp_name();
                self.line(&format!("  {} = icmp eq i32 {}, {}", r, a, b));
                r
            }
            Ty::Bool => {
                let r = self.tmp_name();
                self.line(&format!("  {} = icmp eq i1 {}, {}", r, a, b));
                r
            }
            Ty::Float => {
                let r = self.tmp_name();
                self.line(&format!("  {} = fcmp oeq float {}, {}", r, a, b));
                r
            }
            Ty::Str => {
                let cmp = self.tmp_name();
                self.line(&format!("  {} = call i32 @strcmp(i8* {}, i8* {})", cmp, a, b));
                let r = self.tmp_name();
                self.line(&format!("  {} = icmp eq i32 {}, 0", r, cmp));
                r
            }
            Ty::Vec2 | Ty::Vec3 | Ty::Vec4 => {
                let n = ty.vec_arity().expect("vector Ty always has an arity");
                let mut acc: Option<String> = None;
                for i in 0..n as u32 {
                    let av = self.extract_component(a, ty, i);
                    let bv = self.extract_component(b, ty, i);
                    let cmp = self.tmp_name();
                    self.line(&format!("  {} = fcmp oeq float {}, {}", cmp, av, bv));
                    acc = Some(self.and_acc(acc, &cmp));
                }
                acc.unwrap_or_else(|| "true".into())
            }
            Ty::Named(name) => {
                let field_tys = self.struct_field_types.get(name).cloned().unwrap_or_default();
                let struct_ty = format!("%{}", name);
                let mut acc: Option<String> = None;
                for (i, fty) in field_tys.iter().enumerate() {
                    let av = self.tmp_name();
                    self.line(&format!("  {} = extractvalue {} {}, {}", av, struct_ty, a, i));
                    let bv = self.tmp_name();
                    self.line(&format!("  {} = extractvalue {} {}, {}", bv, struct_ty, b, i));
                    let cmp = self.emit_eq_body(&av, &bv, fty);
                    acc = Some(self.and_acc(acc, &cmp));
                }
                acc.unwrap_or_else(|| "true".into())
            }
            // Unreachable in practice -- `Checker::check_hashable_ty` rejects
            // every other `Ty` (GenRef/List/Map/Set/Closure/Ptr/Mat4) as a
            // Map/Set key/element type before codegen ever sees one here.
            _ => "true".into(),
        }
    }

    /// `acc = acc AND cmp` (or just `cmp`, the first time), factored out
    /// since every multi-lane/multi-field comparison above needs the exact
    /// same accumulate-with-and shape.
    fn and_acc(&mut self, acc: Option<String>, cmp: &str) -> String {
        match acc {
            None => cmp.to_string(),
            Some(prev) => {
                let r = self.tmp_name();
                self.line(&format!("  {} = and i1 {}, {}", r, prev, cmp));
                r
            }
        }
    }
}
