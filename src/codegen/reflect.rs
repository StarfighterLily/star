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
            let elem = self.enum_payload_elem_ty(&e.name);
            self.line(&format!("%{} = type {{ i32, [{} x {}] }}", e.name, words, elem));
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
        self.struct_field_decorators
            .insert(s.name.clone(), s.fields.iter().map(|f| f.decorators.clone()).collect());
        self.struct_field_mut
            .insert(s.name.clone(), s.fields.iter().map(|f| f.is_mut).collect());
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

    /// Get/create the `[N x i8]` global constant holding `s` (deduplicated
    /// by content -- a field name like `"health"` is likely to repeat
    /// across a struct's own get/set/has_field trio, and even across
    /// unrelated structs), then emit a fresh per-call GEP down to a bare
    /// `i8*` in whatever function body is currently being written (`self.ir`
    /// at the time of the call -- the global itself is shared, but the GEP
    /// instruction that reads it is always local to one function).
    fn reflect_name_ptr(&mut self, s: &str) -> String {
        let g = if let Some(g) = self.reflect_name_consts.get(s) {
            g.clone()
        } else {
            let escaped = s.replace('\\', "\\\\").replace('"', "\\22");
            let g = self.global_name();
            let n = s.len() + 1;
            self.global_defs.push(format!(
                "{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"",
                g, n, escaped
            ));
            self.reflect_name_consts.insert(s.to_string(), g.clone());
            g
        };
        let n = s.len() + 1;
        let ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", ptr, n, n, g));
        ptr
    }

    /// Every field of `struct_name`, in declaration order, carrying at
    /// least one `@export`/`@tweakable` decorator whose resolved type is
    /// exactly `field_ty` -- the set `reflect_get_fn_name`/
    /// `reflect_set_fn_name` each generate one `strcmp` comparison for.
    /// Returns `(field index, field name)` pairs; the index is read
    /// straight out of `struct_field_types`' own position rather than going
    /// through `Codegen::field_index` (which would just re-derive the same
    /// index by re-scanning the same `struct_fields` list).
    ///
    /// `require_mut` additionally restricts the set to fields declared
    /// `mut` -- `reflect_set_fn_name` passes `true` (a decorated-but-not-
    /// `mut` field, legitimate for `@export`-only visibility, must stay
    /// unwritable, the same field-level gate an ordinary `s.field = value`
    /// assignment already enforces via `Checker::field_is_mut`), while
    /// `reflect_get_fn_name` passes `false` (reading is always safe
    /// regardless of mutability).
    fn reflect_decorated_fields_of_ty(&self, struct_name: &str, field_ty: &Ty, require_mut: bool) -> Vec<(u32, String)> {
        let names = self.struct_fields.get(struct_name).cloned().unwrap_or_default();
        let tys = self.struct_field_types.get(struct_name).cloned().unwrap_or_default();
        let decos = self.struct_field_decorators.get(struct_name).cloned().unwrap_or_default();
        let muts = self.struct_field_mut.get(struct_name).cloned().unwrap_or_default();
        names
            .into_iter()
            .enumerate()
            .filter_map(|(i, n)| {
                let ty_ok = tys.get(i) == Some(field_ty);
                let deco_ok = decos.get(i).map(|d| !d.is_empty()).unwrap_or(false);
                let mut_ok = !require_mut || muts.get(i).copied().unwrap_or(false);
                (ty_ok && deco_ok && mut_ok).then_some((i as u32, n))
            })
            .collect()
    }

    /// Every field of `struct_name` carrying at least one decorator,
    /// regardless of type -- `reflect_has_field_fn_name`'s field set (unlike
    /// the getters/setters, which are each scoped to one primitive type).
    fn reflect_all_decorated_field_names(&self, struct_name: &str) -> Vec<String> {
        let names = self.struct_fields.get(struct_name).cloned().unwrap_or_default();
        let decos = self.struct_field_decorators.get(struct_name).cloned().unwrap_or_default();
        names
            .into_iter()
            .enumerate()
            .filter_map(|(i, n)| decos.get(i).map(|d| !d.is_empty()).unwrap_or(false).then_some(n))
            .collect()
    }

    /// Lazily generate (and cache, keyed by `(struct name, field LLVM
    /// type)`) `@__star_reflect_get_<ty>_<Struct>(%Struct* %s, i8* %name) ->
    /// <ty>`: a straight-line `strcmp` chain against every `@export`/
    /// `@tweakable` field of `struct_name` whose resolved type is exactly
    /// `field_ty`, returning that field's current value on the first match,
    /// or `field_ty`'s zero value if `name` doesn't match any of them -- the
    /// same "safe fallback instead of a crash" convention an out-of-bounds
    /// `List<T>` index or a stale `GenRef` already use for a runtime-keyed
    /// lookup that misses. Mirrors `Codegen::eq_fn_name`'s (`crate::codegen::
    /// eq`) own lazy-generate-and-cache shape: isolate a fresh function's IR
    /// in a swapped-out `self.ir`, then hand it to `pending_top` to be
    /// appended at module scope once the caller's own function is done.
    /// `Checker::check_reflect_struct_arg` has already guaranteed at least
    /// one matching field exists, so this is only ever generated for a
    /// struct that truly has one.
    fn reflect_get_fn_name(&mut self, struct_name: &str, field_ty: &Ty) -> String {
        let llvm = self.llvm_ty(field_ty);
        let key = (struct_name.to_string(), llvm.clone());
        if let Some(name) = self.reflect_get_fns.get(&key).cloned() {
            return name;
        }
        let name = format!("__star_reflect_get_{}_{}", self.mangle_ty(field_ty), struct_name);
        self.reflect_get_fns.insert(key, name.clone());

        let fields = self.reflect_decorated_fields_of_ty(struct_name, field_ty, false);
        let zero = self.zero_value(field_ty);

        let saved_ir = std::mem::take(&mut self.ir);
        self.line(&format!("define {} @{}(%{}* %s, i8* %name) {{", llvm, name, struct_name));
        self.open_block("entry");
        for (idx, fname) in &fields {
            let name_ptr = self.reflect_name_ptr(fname);
            let cmp = self.tmp_name();
            self.line(&format!("  {} = call i32 @strcmp(i8* %name, i8* {})", cmp, name_ptr));
            let eqreg = self.tmp_name();
            self.line(&format!("  {} = icmp eq i32 {}, 0", eqreg, cmp));
            let hit = self.block_label("reflect_hit");
            let next = self.block_label("reflect_next");
            self.line(&format!("  br i1 {}, label %{}, label %{}", eqreg, hit, next));
            self.open_block(&hit);
            let gep = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds %{}, %{}* %s, i32 0, i32 {}", gep, struct_name, struct_name, idx));
            let val = self.tmp_name();
            self.line(&format!("  {} = load {}, {}* {}", val, llvm, llvm, gep));
            self.line(&format!("  ret {} {}", llvm, val));
            self.open_block(&next);
        }
        self.line(&format!("  ret {} {}", llvm, zero));
        self.line("}");
        self.line("");
        let fn_ir = std::mem::replace(&mut self.ir, saved_ir);
        self.pending_top.push(Self::hoist_allocas_to_entry(&fn_ir));
        name
    }

    /// Setter counterpart of `reflect_get_fn_name`:
    /// `@__star_reflect_set_<ty>_<Struct>(%Struct* %s, i8* %name, <ty> %val)
    /// -> void`, storing `%val` into the first matching field or silently
    /// doing nothing if `name` doesn't match any of them (mirroring an
    /// out-of-bounds `List<T>` write's own "no-op, not a crash" convention).
    /// `field_ty` is always `i32`/`float`/`i1` for this MVP scope (see
    /// `docs/language_reference.md`'s "Reflection Decorators" section) --
    /// none of the three carry any RC-managed content, so unlike an
    /// ordinary `self.field = value` assignment this never needs to
    /// release an outgoing value or retain an incoming one.
    fn reflect_set_fn_name(&mut self, struct_name: &str, field_ty: &Ty) -> String {
        let llvm = self.llvm_ty(field_ty);
        let key = (struct_name.to_string(), llvm.clone());
        if let Some(name) = self.reflect_set_fns.get(&key).cloned() {
            return name;
        }
        let name = format!("__star_reflect_set_{}_{}", self.mangle_ty(field_ty), struct_name);
        self.reflect_set_fns.insert(key, name.clone());

        let fields = self.reflect_decorated_fields_of_ty(struct_name, field_ty, true);

        let saved_ir = std::mem::take(&mut self.ir);
        self.line(&format!("define void @{}(%{}* %s, i8* %name, {} %val) {{", name, struct_name, llvm));
        self.open_block("entry");
        for (idx, fname) in &fields {
            let name_ptr = self.reflect_name_ptr(fname);
            let cmp = self.tmp_name();
            self.line(&format!("  {} = call i32 @strcmp(i8* %name, i8* {})", cmp, name_ptr));
            let eqreg = self.tmp_name();
            self.line(&format!("  {} = icmp eq i32 {}, 0", eqreg, cmp));
            let hit = self.block_label("reflect_hit");
            let next = self.block_label("reflect_next");
            self.line(&format!("  br i1 {}, label %{}, label %{}", eqreg, hit, next));
            self.open_block(&hit);
            let gep = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds %{}, %{}* %s, i32 0, i32 {}", gep, struct_name, struct_name, idx));
            self.line(&format!("  store {} %val, {}* {}", llvm, llvm, gep));
            self.line("  ret void");
            self.open_block(&next);
        }
        self.line("  ret void");
        self.line("}");
        self.line("");
        let fn_ir = std::mem::replace(&mut self.ir, saved_ir);
        self.pending_top.push(Self::hoist_allocas_to_entry(&fn_ir));
        name
    }

    /// `@__star_reflect_has_field_<Struct>(i8* %name) -> i1`: `strcmp`
    /// against *every* decorated field of `struct_name` regardless of type
    /// (unlike the type-scoped getter/setter pair above), so a caller can
    /// probe whether a runtime name is reflectable at all before picking
    /// which typed getter/setter to call.
    fn reflect_has_field_fn_name(&mut self, struct_name: &str) -> String {
        if let Some(name) = self.reflect_has_field_fns.get(struct_name).cloned() {
            return name;
        }
        let name = format!("__star_reflect_has_field_{}", struct_name);
        self.reflect_has_field_fns.insert(struct_name.to_string(), name.clone());

        let fields = self.reflect_all_decorated_field_names(struct_name);

        let saved_ir = std::mem::take(&mut self.ir);
        self.line(&format!("define i1 @{}(i8* %name) {{", name));
        self.open_block("entry");
        for fname in &fields {
            let name_ptr = self.reflect_name_ptr(fname);
            let cmp = self.tmp_name();
            self.line(&format!("  {} = call i32 @strcmp(i8* %name, i8* {})", cmp, name_ptr));
            let eqreg = self.tmp_name();
            self.line(&format!("  {} = icmp eq i32 {}, 0", eqreg, cmp));
            let hit = self.block_label("reflect_hit");
            let next = self.block_label("reflect_next");
            self.line(&format!("  br i1 {}, label %{}, label %{}", eqreg, hit, next));
            self.open_block(&hit);
            self.line("  ret i1 1");
            self.open_block(&next);
        }
        self.line("  ret i1 0");
        self.line("}");
        self.line("");
        let fn_ir = std::mem::replace(&mut self.ir, saved_ir);
        self.pending_top.push(Self::hoist_allocas_to_entry(&fn_ir));
        name
    }

    /// `reflect_get_i32`/`_f32`/`_bool` builtin call codegen: resolve
    /// argument 1's static struct type, get/generate that struct's
    /// `field_ty`-scoped accessor, and call it with a real pointer to
    /// argument 1's storage (`emit_place`, the same primitive `player.field`
    /// read codegen itself GEPs through) plus argument 2 evaluated as a
    /// plain `i8*`.
    pub(super) fn emit_reflect_get(&mut self, args: &[TypedExpr], field_ty: &Ty) -> String {
        let Ty::Named(struct_name) = self.expr_ty(&args[0]) else {
            unreachable!("Checker::check_reflect_struct_arg guarantees argument 1 is a struct value");
        };
        let fn_name = self.reflect_get_fn_name(&struct_name, field_ty);
        let base_ptr = self.emit_place(&args[0]);
        let name_val = self.emit_expr(&args[1]);
        let name_bare = self.untag(&name_val, &Ty::Str);
        let llvm = self.llvm_ty(field_ty);
        let reg = self.tmp_name();
        self.line(&format!("  {} = call {} @{}(%{}* {}, i8* {})", reg, llvm, fn_name, struct_name, base_ptr, name_bare));
        format!("{} {}", llvm, reg)
    }

    /// `reflect_set_i32`/`_f32`/`_bool` builtin call codegen -- setter
    /// counterpart of `emit_reflect_get`. `Checker::check_mut_receiver` has
    /// already validated argument 1 is a genuine, mutable place (not a
    /// `Table<T>` index or an rvalue that would silently write through a
    /// disconnected temporary), so `emit_place` always resolves to real,
    /// writable storage here.
    pub(super) fn emit_reflect_set(&mut self, args: &[TypedExpr], field_ty: &Ty) -> String {
        let Ty::Named(struct_name) = self.expr_ty(&args[0]) else {
            unreachable!("Checker::check_reflect_struct_arg guarantees argument 1 is a struct value");
        };
        let fn_name = self.reflect_set_fn_name(&struct_name, field_ty);
        let base_ptr = self.emit_place(&args[0]);
        let name_val = self.emit_expr(&args[1]);
        let name_bare = self.untag(&name_val, &Ty::Str);
        let val_val = self.emit_expr(&args[2]);
        let val_bare = self.untag(&val_val, field_ty);
        let llvm = self.llvm_ty(field_ty);
        self.line(&format!("  call void @{}(%{}* {}, i8* {}, {} {})", fn_name, struct_name, base_ptr, name_bare, llvm, val_bare));
        "%undef".into()
    }

    /// `reflect_has_field(s, name)` builtin call codegen. Argument 1 is only
    /// used for static type inference (which struct's field-name table to
    /// consult) -- still routed through `emit_place` so any side effect and
    /// RC bookkeeping in evaluating it happens exactly once, same as every
    /// other place-taking builtin, even though the resulting pointer itself
    /// is never read.
    pub(super) fn emit_reflect_has_field(&mut self, args: &[TypedExpr]) -> String {
        let Ty::Named(struct_name) = self.expr_ty(&args[0]) else {
            unreachable!("Checker::check_reflect_struct_arg guarantees argument 1 is a struct value");
        };
        let fn_name = self.reflect_has_field_fn_name(&struct_name);
        let _ = self.emit_place(&args[0]);
        let name_val = self.emit_expr(&args[1]);
        let name_bare = self.untag(&name_val, &Ty::Str);
        let reg = self.tmp_name();
        self.line(&format!("  {} = call i1 @{}(i8* {})", reg, fn_name, name_bare));
        format!("i1 {}", reg)
    }
}
