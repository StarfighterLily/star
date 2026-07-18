//! Struct type declarations and `@export`/`@tweakable` reflection metadata.

use crate::types::*;

use super::Codegen;

impl Codegen {
    /// Register an enum's variant names/payload field types into
    /// `enum_variants`/`enum_variant_fields`, with no LLVM text emitted --
    /// split out of `emit_enum_decl` (which now only emits text) so
    /// `Codegen::emit` can run this for *every* struct/enum first, before
    /// any type's textual declaration is emitted. `llvm_ty(Ty::Enum(n))`
    /// (consulted by `emit_struct_decl` for any field of a payload-enum
    /// type, e.g. `struct Holder: opt: Option<str>`) depends on
    /// `enum_is_payload`, which reads `enum_variant_fields` -- if that
    /// lookup misses because this enum's own registration hadn't run yet,
    /// `enum_is_payload` silently (and wrongly) returns `false`, mistagging
    /// the field as a bare `i32` instead of `%Option__str` in the *struct's
    /// own* permanent `%Holder = type { .. }` text. See `register_struct`'s
    /// doc comment for the full ordering hazard this was closing.
    pub(super) fn register_enum(&mut self, e: &TypedEnumDef) {
        let names: Vec<String> = e.variants.iter().map(|v| v.name.clone()).collect();
        let field_tys: Vec<Vec<Ty>> = e.variants.iter().map(|v| v.fields.iter().map(|f| f.ty.clone()).collect()).collect();
        self.enum_variants.insert(e.name.clone(), names);
        self.enum_variant_fields.insert(e.name.clone(), field_tys);
    }

    /// For a payload-carrying enum, emit its tagged-union LLVM struct type
    /// declaration: `{ i32 tag, [W x i64] payload }`, where `W` is sized to
    /// the largest variant's fields (see `enum_payload_words`). A fully
    /// fieldless enum (every variant has no fields) gets no struct
    /// declaration at all -- it stays a bare `i32` (see `llvm_ty`). Requires
    /// `register_enum` (this enum's own) and `register_struct` (any struct
    /// referenced, directly or transitively, by a variant field) to have
    /// already run for every item in the module -- see `Codegen::emit`.
    pub(super) fn emit_enum_decl(&mut self, e: &TypedEnumDef) {
        if self.enum_is_payload(&e.name) {
            let words = self.enum_payload_words(&e.name);
            self.line(&format!("%{} = type {{ i32, [{} x i64] }}", e.name, words));
        }
    }

    /// Register a struct's field names/types into `struct_fields`/
    /// `struct_field_types`, with no LLVM text emitted -- see
    /// `register_enum`'s doc comment for why this needs to be a separate
    /// pass from `emit_struct_decl`'s text emission.
    ///
    /// The hazard this closes, concretely: `Codegen::emit`'s original single
    /// interleaved pass called `emit_struct_decl`/`emit_enum_decl` in
    /// `module.items` order -- but every monomorphized generic enum
    /// instantiation (`Option<str>` -> `Option__str`, `Result<i32,str>` ->
    /// ..., anything instantiated on demand while type-checking, including
    /// the builtin `Option`/`Result` templates) is appended to the item list
    /// *after* every item that appears in the source (`Checker::check`'s
    /// `typed_items.append(&mut self.mono_items)`), regardless of where in
    /// the source it was first used. A struct declared *anywhere* in the
    /// source with an `Option<T>`/`Result<T,E>`-typed field (e.g. `struct
    /// Holder: opt: Option<str>`) therefore always had its own `%Holder =
    /// type { .. }` text emitted *before* `Option__str`'s registration ever
    /// ran, so `llvm_ty(Ty::Enum("Option__str"))` (reached while computing
    /// `Holder`'s field list) always saw a not-yet-populated
    /// `enum_variant_fields`, `enum_is_payload` always returned `false`, and
    /// `Holder`'s permanent LLVM struct type baked in a bare `i32` for that
    /// field instead of the real `%Option__str` tagged-union type -- every
    /// later `store %Option__str .., %Option__str* <gep into a %Holder>`
    /// wrote a multi-word payload into a slot LLVM/`clang` had only sized
    /// for one `i32`, corrupting adjacent stack memory. Confirmed via a real
    /// `star build`+run segfaulting (`ExitStatus` `0xC0000005`, access
    /// violation) on exactly this minimal shape -- `struct Holder: opt:
    /// Option<str>` plus a `let v = match h.opt: ...` -- with as few as one
    /// loop iteration, no `Table`/`Ring`/generics-nesting involved at all.
    /// Fixed by having `Codegen::emit` run `register_struct`/`register_enum`
    /// for *every* item first, in one pass, before emitting any type's text
    /// in a second pass -- LLVM's textual IR allows named struct types to
    /// reference each other regardless of which is declared first (unlike
    /// SSA values, which need dominance), so only the *data* (`enum_is_payload`,
    /// `enum_payload_words`, a field's `llvm_ty`) needs to be fully
    /// registered first, not the text itself in any particular order.
    pub(super) fn register_struct(&mut self, s: &TypedStructDef) {
        self.struct_fields
            .insert(s.name.clone(), s.fields.iter().map(|f| f.name.clone()).collect());
        self.struct_field_types
            .insert(s.name.clone(), s.fields.iter().map(|f| f.ty.clone()).collect());
    }

    /// Emit a struct's LLVM type declaration and reflection metadata.
    /// Requires `register_struct`/`register_enum` to have already run for
    /// every item in the module -- see `register_struct`'s doc comment.
    pub(super) fn emit_struct_decl(&mut self, s: &TypedStructDef) {
        self.write(&format!("%{} = type {{ ", s.name));
        let parts: Vec<String> = s.fields.iter().map(|f| self.llvm_ty(&f.ty)).collect();
        self.write(&parts.join(", "));
        self.line(" }");
        self.emit_reflect_metadata(s);
    }

    /// A human-readable spelling of `ty` for reflection metadata (distinct
    /// from `llvm_ty`, which an external tool reading the `.ll` wouldn't
    /// want to parse LLVM IR syntax to understand).
    ///
    /// A field typed as a monomorphized *user-defined* generic struct/enum
    /// (`struct Box<T>: value: T`, used as `Box<i32>`) or as the
    /// compiler-builtin `Option<T>`/`Result<T,E>` generics all reach this
    /// function as a bare `Ty::Named`/`Ty::Enum` carrying the flat mangled
    /// symbol codegen actually uses (`Box__i32`, `Option__i32`) -- unlike
    /// `List<T>`/`Map<K,V>`/... below, which have a dedicated `Ty` variant
    /// that already carries its own element type(s) to recurse into.
    /// Previously this fell straight to the catch-all `n.clone()` arm for
    /// both, so a decorated field's emitted metadata read e.g.
    /// `boxed:16:Box__i32:export`/`opt:32:Option__i32:export` -- an internal
    /// mangling artifact, not a name any external tool or human reading the
    /// metadata could make sense of (confirmed via a real `star emit llvm`
    /// on `struct Everything: @export boxed: Box<i32> = Box(1)  @export
    /// opt: Option<i32> = Option<i32>::None`). Fixed by consulting
    /// `self.generic_instantiations` (threaded through from `Checker` via
    /// `TypedModule`, see its own doc comment) first, recursing into this
    /// same function for each type argument so a nested generic
    /// (`Box<Option<i32>>`) renders correctly too; a `Ty::Named`/`Ty::Enum`
    /// for an ordinary, non-generic struct/enum isn't in that map at all
    /// and falls through to the plain `n.clone()` exactly as before.
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
            Ty::Mat2 => "Mat2".into(),
            Ty::Mat3 => "Mat3".into(),
            Ty::Quat => "Quat".into(),
            Ty::Color => "Color".into(),
            Ty::Color32 => "Color32".into(),
            Ty::PaletteIndex => "PaletteIndex".into(),
            Ty::Palette => "Palette".into(),
            Ty::Named(n) => self.generic_display_name(n),
            Ty::GenRef(inner) => format!("GenRef<{}>", self.reflect_type_name(inner)),
            Ty::Handle(inner) => format!("Handle<{}>", self.reflect_type_name(inner)),
            Ty::List(inner) => format!("List<{}>", self.reflect_type_name(inner)),
            Ty::Map(k, v) => format!("Map<{}, {}>", self.reflect_type_name(k), self.reflect_type_name(v)),
            Ty::Set(inner) => format!("Set<{}>", self.reflect_type_name(inner)),
            Ty::Tuple(elems) => format!("({})", elems.iter().map(|e| self.reflect_type_name(e)).collect::<Vec<_>>().join(", ")),
            Ty::Array(elem, count) => format!("[{}; {}]", self.reflect_type_name(elem), count),
            Ty::Ring(elem, count) => format!("Ring<{}, {}>", self.reflect_type_name(elem), count),
            Ty::Table(elem) => format!("Table<{}>", self.reflect_type_name(elem)),
            Ty::Enum(n) => self.generic_display_name(n),
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
            Ty::Bytes => "Bytes".into(),
            Ty::Symbol => "Symbol".into(),
            Ty::BitField(n) => format!("BitField<{}>", n),
            Ty::Flags(inner) => format!("Flags<{}>", self.reflect_type_name(inner)),
        }
    }

    /// Render a flat, possibly-mangled struct/enum name (`n`, as carried by
    /// `Ty::Named`/`Ty::Enum`) for reflection metadata: `Base<Arg1, Arg2>`
    /// if `n` is a monomorphized generic instantiation known to
    /// `self.generic_instantiations`, otherwise `n` verbatim (an ordinary,
    /// non-generic struct/enum, including one that reached this compiler
    /// already `alias__`-mangled by `crate::modules` -- there's no separate
    /// table for that mangling, so it's simply shown as-is, matching every
    /// other codegen-facing use of a module-qualified name). See
    /// `reflect_type_name`'s doc comment for the concrete bug this closes.
    fn generic_display_name(&self, n: &str) -> String {
        match self.generic_instantiations.get(n) {
            Some((base, args)) => format!(
                "{}<{}>",
                base,
                args.iter().map(|a| self.reflect_type_name(a)).collect::<Vec<_>>().join(", ")
            ),
            None => n.to_string(),
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
