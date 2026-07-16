//! Struct type declarations and `@export`/`@tweakable` reflection metadata.

use crate::types::*;

use super::Codegen;

impl Codegen {
    /// Register an enum's variant names/payload field types and, for a
    /// payload-carrying enum, emit its tagged-union LLVM struct type
    /// declaration: `{ i32 tag, [W x i64] payload }`, where `W` is sized to
    /// the largest variant's fields (see `enum_payload_words`). A fully
    /// fieldless enum (every variant has no fields) gets no struct
    /// declaration at all -- it stays a bare `i32` (see `llvm_ty`).
    pub(super) fn emit_enum_decl(&mut self, e: &TypedEnumDef) {
        let names: Vec<String> = e.variants.iter().map(|v| v.name.clone()).collect();
        let field_tys: Vec<Vec<Ty>> = e.variants.iter().map(|v| v.fields.iter().map(|f| f.ty.clone()).collect()).collect();
        self.enum_variants.insert(e.name.clone(), names);
        self.enum_variant_fields.insert(e.name.clone(), field_tys);
        if self.enum_is_payload(&e.name) {
            let words = self.enum_payload_words(&e.name);
            self.line(&format!("%{} = type {{ i32, [{} x i64] }}", e.name, words));
        }
    }

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
            Ty::I8 => "i8".into(),
            Ty::U8 => "u8".into(),
            Ty::I16 => "i16".into(),
            Ty::U16 => "u16".into(),
            Ty::U32 => "u32".into(),
            Ty::I64 => "i64".into(),
            Ty::U64 => "u64".into(),
            Ty::F64 => "f64".into(),
            Ty::Char => "char".into(),
            Ty::Bool => "bool".into(),
            Ty::Str => "str".into(),
            Ty::Vec2 => "Vec2".into(),
            Ty::Vec3 => "Vec3".into(),
            Ty::Vec4 => "Vec4".into(),
            Ty::Mat4 => "Mat4".into(),
            Ty::Named(n) => n.clone(),
            Ty::GenRef(inner) => format!("GenRef<{}>", self.reflect_type_name(inner)),
            Ty::Handle(inner) => format!("Handle<{}>", self.reflect_type_name(inner)),
            Ty::List(inner) => format!("List<{}>", self.reflect_type_name(inner)),
            Ty::Map(k, v) => format!("Map<{}, {}>", self.reflect_type_name(k), self.reflect_type_name(v)),
            Ty::Set(inner) => format!("Set<{}>", self.reflect_type_name(inner)),
            Ty::Tuple(elems) => format!("({})", elems.iter().map(|e| self.reflect_type_name(e)).collect::<Vec<_>>().join(", ")),
            Ty::Array(elem, count) => format!("[{}; {}]", self.reflect_type_name(elem), count),
            Ty::Ring(elem, count) => format!("Ring<{}, {}>", self.reflect_type_name(elem), count),
            Ty::Table(elem) => format!("Table<{}>", self.reflect_type_name(elem)),
            Ty::Enum(n) => n.clone(),
            Ty::Closure(params, ret) => format!(
                "Fn({}) -> {}",
                params.iter().map(|p| self.reflect_type_name(p)).collect::<Vec<_>>().join(", "),
                self.reflect_type_name(ret)
            ),
            Ty::Ptr => "ptr".into(),
            Ty::Wrapping(inner) => format!("Wrapping<{}>", self.reflect_type_name(inner)),
            Ty::Fixed(bits, frac) => format!("Fixed<{}, {}>", bits, frac),
            Ty::Tick => "Tick".into(),
            Ty::Duration => "Duration".into(),
            Ty::Instant => "Instant".into(),
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
            // Pad up to this field's own alignment before recording its
            // offset -- matching real LLVM struct layout (see
            // `Codegen::type_size`'s doc comment). Previously this summed
            // each field's size with no padding at all, so any struct mixing
            // a sub-8-byte field with a pointer-or-wider one reported wrong
            // offsets for every field after the first mismatch.
            let align = self.type_align(&f.ty);
            offset = offset.div_ceil(align) * align;
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
