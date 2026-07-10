//! Struct type declarations and `@export`/`@tweakable` reflection metadata.

use crate::types::*;

use super::Codegen;

impl Codegen {
    pub(super) fn emit_struct_decl(&mut self, s: &TypedStructDef) {
        self.struct_fields
            .insert(s.name.clone(), s.fields.iter().map(|f| f.name.clone()).collect());
        self.struct_field_types
            .insert(s.name.clone(), s.fields.iter().map(|f| f.ty.clone()).collect());
        self.write(&format!("%{} = type {{ ", s.name));
        let parts: Vec<String> = s.fields.iter().map(|f| self.llvm_ty(&f.ty)).collect();
        self.write(&parts.join(", "));
        self.line(" }");
        self.emit_reflect_metadata(s);
    }

    /// A human-readable spelling of `ty` for reflection metadata (distinct
    /// from `llvm_ty`, which an external tool reading the `.ll` wouldn't
    /// want to parse LLVM IR syntax to understand).
    fn reflect_type_name(&self, ty: &Ty) -> String {
        match ty {
            Ty::Int => "i32".into(),
            Ty::Float => "float".into(),
            Ty::Bool => "bool".into(),
            Ty::Str => "str".into(),
            Ty::Vec2 => "Vec2".into(),
            Ty::Vec3 => "Vec3".into(),
            Ty::Vec4 => "Vec4".into(),
            Ty::Mat4 => "Mat4".into(),
            Ty::Named(n) => n.clone(),
            Ty::GenRef(inner) => format!("GenRef<{}>", self.reflect_type_name(inner)),
        }
    }

    /// `@export`/`@tweakable` reflection metadata: for every field carrying
    /// at least one decorator, emit `name:byte_offset:type:decorators` into a
    /// single semicolon-separated global string constant per struct. An
    /// external editor can read this string out of the compiled `.ll` (or a
    /// loaded module's data section) to discover which fields it's allowed
    /// to inspect/mutate live, without needing a separate reflection format.
    /// Byte offsets run over *every* field in declaration order (not just
    /// decorated ones), matching the struct's actual memory layout.
    fn emit_reflect_metadata(&mut self, s: &TypedStructDef) {
        if !s.fields.iter().any(|f| !f.decorators.is_empty()) {
            return;
        }
        let mut entries = Vec::new();
        let mut offset: u32 = 0;
        for f in &s.fields {
            if !f.decorators.is_empty() {
                entries.push(format!(
                    "{}:{}:{}:{}",
                    f.name,
                    offset,
                    self.reflect_type_name(&f.ty),
                    f.decorators.join(",")
                ));
            }
            offset += self.type_size(&f.ty);
        }
        let blob = format!("{};", entries.join(";"));
        let escaped = blob.replace("\\", "\\\\").replace("\"", "\\22");
        let name = format!("@__star_reflect_{}", s.name);
        self.global_defs.push(format!(
            "{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"",
            name,
            blob.len() + 1,
            escaped
        ));
    }
}
