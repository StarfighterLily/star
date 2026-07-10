//! LLVM IR codegen: walks the typed AST and emits textual `.ll` IR.
//!
//! The emitted IR is written to a file and compiled with the installed
//! `clang.exe` to produce a native executable.

use std::fmt::Write;

use crate::ast::*;
use crate::diagnostics::{Diagnostic, Span};
use crate::types::*;

/// Render an `f64` as an LLVM IR literal for a 32-bit `float` constant.
///
/// LLVM's textual IR only accepts a plain decimal literal (`3.5`) for a
/// `float`-typed constant when that decimal is *exactly* representable as
/// the target's 32-bit value; almost any literal with a non-power-of-two
/// fraction (`3.7`, `0.1`, ...) fails to parse ("floating point constant
/// invalid for type"). The hexadecimal form sidesteps this: round to the
/// nearest `f32`, widen that back to `f64` bit-for-bit, and print the
/// resulting 16-hex-digit double bit pattern — which is always exactly
/// representable by construction, per the LLVM language reference.
fn format_f32_literal(v: f64) -> String {
    let rounded = (v as f32) as f64;
    format!("0x{:016X}", rounded.to_bits())
}

/// A codegen context that accumulates LLVM IR and tracks symbols.
pub struct Codegen {
    ir: String,
    global_defs: Vec<String>,
    tmp: u64,
    globals: u64,
    /// Counter for unique basic-block labels (if/while codegen).
    block_id: u64,
    symbols: Vec<(String, String, Ty)>,
    /// Field name lists per struct, populated from the typed module so field
    /// indices can be resolved for any struct (not just a hardcoded set).
    struct_fields: std::collections::HashMap<String, Vec<String>>,
    /// Field type lists per struct, used to compute accurate byte sizes for
    /// the frame bump allocator.
    struct_field_types: std::collections::HashMap<String, Vec<Ty>>,
    /// Maps `"Struct.method"` -> `@method` so method calls (`obj.method()`) can
    /// be lowered to a direct function call with the receiver as `self`.
    methods: std::collections::HashMap<String, String>,
    errors: Vec<Diagnostic>,
    in_frame: bool,
    /// Top-level LLVM text (worker functions and their argument-struct type
    /// declarations) generated mid-function by `par`/`swarm` statements.
    /// These can't be written directly into `self.ir` at the point they're
    /// discovered (that would nest a `define` inside the enclosing
    /// function's body), so they're collected here and appended to the
    /// module after every ordinary item has been emitted.
    pending_top: Vec<String>,
    /// Maps an arena's declared element type -> its name, so `GenRef<T>`
    /// codegen can find the arena backing `T` (the checker has already
    /// proven exactly one exists). Populated while arena decls are emitted,
    /// which happens before any function body -- see `emit()`.
    arena_by_elem: Vec<(Ty, String)>,
}

impl Codegen {
    /// Fixed capacity (element count) of every arena's backing array and its
    /// parallel generation array. See `emit_spawn_stmt`/`emit_arena_decl`.
    const ARENA_CAPACITY: u64 = 1024;

    pub fn new() -> Self {
        Self {
            ir: String::new(),
            global_defs: Vec::new(),
            tmp: 0,
            globals: 0,
            block_id: 0,
            symbols: Vec::new(),
            struct_fields: std::collections::HashMap::new(),
            struct_field_types: std::collections::HashMap::new(),
            methods: std::collections::HashMap::new(),
            errors: Vec::new(),
            in_frame: false,
            pending_top: Vec::new(),
            arena_by_elem: Vec::new(),
        }
    }

    /// Generate LLVM IR from a checked module, returning the `.ll` source.
    pub fn emit(&mut self, module: &TypedModule) -> Result<String, Vec<Diagnostic>> {
        self.line("; Star compiler -- LLVM IR");
        self.line("target triple = \"x86_64-w64-windows-gnu\"");
        self.line("");

        self.emit_builtins();

        for item in &module.items {
            match item {
                TypedItem::Struct(s) => self.emit_struct_decl(s),
                TypedItem::Arena(a) => self.emit_arena_decl(a),
                _ => {}
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

        // Worker functions (and their argument-struct types) spawned by
        // `par`/`swarm` statements, deferred until now since they must sit
        // at module scope, not nested inside the function that triggered them.
        if !self.pending_top.is_empty() {
            self.line("");
            self.line("; par/swarm worker functions");
            let defs = self.pending_top.clone();
            for d in &defs {
                self.line(d);
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
        self.line("declare i8* @strcpy(i8*, i8*)");
        self.line("declare i8* @strcat(i8*, i8*)");
        self.line("declare i8* @CreateThread(i8*, i64, i8*, i8*, i32, i32*)");
        self.line("declare i32 @WaitForSingleObject(i8*, i32)");
        self.line("declare i32 @CloseHandle(i8*)");
        // `math` builtins: lowered to LLVM's target-independent float
        // intrinsics rather than libm symbols, so no extra linker flags are
        // needed to resolve them.
        self.line("declare float @llvm.sqrt.f32(float)");
        self.line("declare float @llvm.pow.f32(float, float)");
        self.line("declare float @llvm.fabs.f32(float)");
        self.line("declare float @llvm.floor.f32(float)");
        self.line("declare float @llvm.ceil.f32(float)");
        self.line("declare float @llvm.minnum.f32(float, float)");
        self.line("declare float @llvm.maxnum.f32(float, float)");
        self.line("");
        self.line("%GenRef = type { i32, i32 }");
        self.line("");
        self.line("@frame.buf = global [4096 x i8] zeroinitializer");
        self.line("@frame.off = global i64 0");
        self.line("");
    }

    fn emit_arena_decl(&mut self, a: &TypedArenaDecl) {
        let elem_ty = self.llvm_ty(&a.ty);
        self.line(&format!("%{} = type {{ {}*, i64 }}", a.name, elem_ty));
        self.line(&format!("@arena.{}.data = global {}* null", a.name, elem_ty));
        self.line(&format!("@arena.{}.count = global i64 0", a.name));
        // Per-slot generation counters backing `GenRef<T>` where `T` is this
        // arena's element type: 0 means "never spawned". Every `spawn` and
        // `despawn` of a slot bumps its generation by exactly 1 (never resets
        // it to a fixed value), so parity encodes liveness -- odd is live,
        // even is dead/never-spawned -- and no two spawns of the same slot
        // ever share a generation. That's what prevents the ABA problem once
        // slots are reused via the free-list below. A `GenRef` captures a
        // slot's generation at creation time and a dereference is only
        // trusted if it still matches this array's live value -- see
        // `emit_despawn_stmt`/`GenRefCreate`/`GenRefIndex`.
        self.line(&format!("@arena.{}.gen = global [{} x i32] zeroinitializer", a.name, Self::ARENA_CAPACITY));
        // Free-list stack of despawned slot indices, so `spawn` can reclaim a
        // slot's memory instead of only ever growing `count` -- this is the
        // "internal free-list to manage fragmentation" design.md promises.
        // See `emit_despawn_stmt` (push) and `emit_spawn_stmt` (pop).
        self.line(&format!("@arena.{}.free = global [{} x i64] zeroinitializer", a.name, Self::ARENA_CAPACITY));
        self.line(&format!("@arena.{}.free_top = global i64 0", a.name));
        self.line("");
        self.arena_by_elem.push((a.ty.clone(), a.name.clone()));
    }

    /// Resolve the arena backing `GenRef<ty>`. The checker has already
    /// proven exactly one exists (`Checker::require_backing_arena`); this is
    /// a defensive fallback only, matching the codebase's existing
    /// defensive-error convention (e.g. `emit_float_op`).
    fn arena_for_elem_ty(&mut self, ty: &Ty, span: Span) -> String {
        match self.arena_by_elem.iter().find(|(t, _)| t == ty) {
            Some((_, name)) => name.clone(),
            None => {
                self.err("GenRef<T> has no backing arena", span);
                String::new()
            }
        }
    }

    fn emit_struct_decl(&mut self, s: &TypedStructDef) {
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

    /// Byte size of a type, used to advance the frame bump allocator's
    /// offset by the right amount for each allocation.
    fn type_size(&self, ty: &Ty) -> u32 {
        match ty {
            Ty::Int | Ty::Float => 4,
            Ty::Bool => 1,
            Ty::Str => 8,
            Ty::GenRef(_) => 8, // { i32, i32 }
            Ty::Vec2 => 8,
            Ty::Vec3 => 12,
            Ty::Vec4 => 16,
            Ty::Mat4 => 64,
            Ty::Named(n) => self
                .struct_field_types
                .get(n)
                .map(|fields| fields.iter().map(|f| self.type_size(f)).sum())
                .unwrap_or(8),
        }
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
            Ty::GenRef(_) => "%GenRef".into(),
        }
    }

    /// A constant zero value of the given type, for zero-initializing struct
    /// fields the constructor call site didn't supply an argument for.
    fn zero_value(&self, ty: &Ty) -> String {
        match ty {
            Ty::Int => "0".into(),
            Ty::Float => "0.0".into(),
            Ty::Bool => "false".into(),
            Ty::Str => "null".into(),
            Ty::Vec2 | Ty::Vec3 | Ty::Vec4 | Ty::Mat4 | Ty::Named(_) | Ty::GenRef(_) => "zeroinitializer".into(),
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

    /// Emit code that yields a *pointer* to the storage of `expr`, for use as
    /// the base operand of a `getelementptr`. This differs from `emit_expr`,
    /// which for an `Ident`/`Field` of aggregate type loads and returns the
    /// value itself; GEP-ing into that loaded value would be an LLVM type
    /// mismatch (the register's type is the aggregate, not a pointer to it).
    fn emit_place(&mut self, expr: &TypedExpr) -> String {
        match expr {
            TypedExpr::Ident { name, .. } => self.sym_ptr(name).unwrap_or_else(|| "%undef".into()),
            TypedExpr::SelfExpr(ty, _) => {
                let ptr = self.sym_ptr("self").unwrap_or_else(|| "%undef".into());
                let reg = self.tmp_name();
                let struct_ty = match ty {
                    Ty::Named(n) => format!("%{}", n),
                    _ => self.llvm_ty(ty),
                };
                self.line(&format!("  {} = load {}*, {}** {}", reg, struct_ty, struct_ty, ptr));
                reg
            }
            TypedExpr::Field { base, field, .. } => {
                let base_ptr = self.emit_place(base);
                let gep = self.tmp_name();
                let bty = self.llvm_ty(&self.expr_ty(base));
                let idx = self.field_index(&self.expr_ty(base), field);
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, bty, bty, base_ptr, idx));
                gep
            }
            // Any other expression (e.g. `gen_ref[idx].field`, chaining a
            // field access directly onto a struct returned *by value*) has
            // no existing storage to address -- spill it into a fresh
            // alloca so the `Field` arm above has a pointer to GEP into.
            _ => {
                let val = self.emit_expr(expr);
                let ty = self.expr_ty(expr);
                let ty_str = self.llvm_ty(&ty);
                let bare = self.untag(&val, &ty);
                let ptr = self.tmp_name();
                self.line(&format!("  {} = alloca {}", ptr, ty_str));
                self.line(&format!("  store {} {}, {}* {}", ty_str, bare, ty_str, ptr));
                ptr
            }
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

    /// Map a swizzle character to its lane/component index.
    fn swizzle_index(&mut self, c: char) -> u32 {
        match c {
            'x' => 0,
            'y' => 1,
            'z' => 2,
            'w' => 3,
            _ => { self.err(&format!("invalid swizzle component `{}`", c), Span::dummy()); 0 }
        }
    }

    /// Read a GLSL-style swizzle access (`.x`, `.xyz`, `.zyx`, ...) off a
    /// vector base, producing a scalar `float` (single component) or a
    /// smaller/reordered vector value (multiple components). Loads the base
    /// once, then extracts via `extractvalue` (Vec2/Vec3) or
    /// `extractelement`/`shufflevector` (Vec4) as appropriate — no GEP is
    /// used since a swizzle result isn't a contiguous sub-object in general.
    fn emit_swizzle_read(&mut self, base: &TypedExpr, field: &str) -> String {
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
    fn emit_swizzle_write(&mut self, base: &TypedExpr, field: &str, val_ty: &Ty, val: &str) {
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

    fn line(&mut self, s: &str) { writeln!(self.ir, "{}", s).unwrap(); }
    fn write(&mut self, s: &str) { write!(self.ir, "{}", s).unwrap(); }
    fn err(&mut self, msg: &str, span: Span) { self.errors.push(Diagnostic::error(msg, span)); }

    /// Produce a unique, readable basic-block label for control flow.
    fn block_label(&mut self, prefix: &str) -> String {
        let id = self.block_id;
        self.block_id += 1;
        format!("{}_{}", prefix, id)
    }

    /// Extract just the register name from an expression emission result such
    /// as `i1 %r` or `i32 %r`, discarding the leading type tag.
    fn reg_of(&self, s: &str) -> String {
        s.split_whitespace().next_back().unwrap_or(s).to_string()
    }

    /// Emit a block of typed statements. If the block ends with an expression
    /// statement (or a `frame` block whose own trailing statement produces a
    /// value), returns the value-register (with type tag) of that trailing
    /// expression; otherwise returns `None` (the block is used for side effects).
    fn emit_block_value(&mut self, block: &TypedBlock) -> Option<String> {
        self.emit_stmts_value(&block.stmts)
    }

    /// Shared implementation behind `emit_block_value` and function bodies:
    /// emit every statement but the last normally, then special-case the last
    /// statement so a trailing expression's value (possibly nested inside a
    /// `frame:` scope) propagates out instead of being silently discarded.
    fn emit_stmts_value(&mut self, stmts: &[TypedStmt]) -> Option<String> {
        let (init, last) = match stmts.split_last() {
            Some((last, init)) => (init, last),
            None => return None,
        };
        for stmt in init {
            self.emit_stmt(stmt);
        }
        match last {
            TypedStmt::Expr(e) => Some(self.emit_expr(e)),
            TypedStmt::Frame { body, .. } => self.emit_frame_body(body),
            other => {
                self.emit_stmt(other);
                None
            }
        }
    }

    /// Emit a `frame:` scope: save the bump-allocator offset, emit the body
    /// (allocations inside use the frame buffer instead of the stack), then
    /// restore the saved offset so the scope's allocations are reclaimed in
    /// O(1) when it ends. Returns the body's trailing value, if any.
    fn emit_frame_body(&mut self, body: &TypedBlock) -> Option<String> {
        let was_in_frame = self.in_frame;
        self.in_frame = true;
        let saved_off = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @frame.off", saved_off));
        let val = self.emit_stmts_value(&body.stmts);
        self.line(&format!("  store i64 {}, i64* @frame.off", saved_off));
        self.in_frame = was_in_frame;
        val
    }

    /// True if the last statement of `stmts` unconditionally terminates the
    /// block with an explicit `return` (looking through trailing `frame`
    /// scopes), so callers know not to append a synthetic terminator.
    fn body_ends_in_return(stmts: &[TypedStmt]) -> bool {
        match stmts.last() {
            Some(TypedStmt::Return { .. }) => true,
            Some(TypedStmt::Frame { body, .. }) => Self::body_ends_in_return(&body.stmts),
            // An `if` only terminates the enclosing block if *both* arms do
            // (an `if` with no `else`, or with a non-terminating branch,
            // falls through and still needs the synthetic join point).
            Some(TypedStmt::If { then_block, else_block: Some(else_block), .. }) => {
                Self::body_ends_in_return(&then_block.stmts) && Self::body_ends_in_return(&else_block.stmts)
            }
            _ => false,
        }
    }

    fn expr_ty(&self, e: &TypedExpr) -> Ty {
        match e {
            TypedExpr::Int(_, ty, _) | TypedExpr::Float(_, ty, _)
            | TypedExpr::Str(_, ty, _) | TypedExpr::Bool(_, ty, _)
            | TypedExpr::Field { ty, .. } | TypedExpr::Call { ty, .. }
            | TypedExpr::Binary { ty, .. } | TypedExpr::Unary { ty, .. }
            | TypedExpr::Match { ty, .. } | TypedExpr::StructLit { ty, .. }
            | TypedExpr::FStr(_, ty, _) | TypedExpr::GenRefIndex { ty, .. } | TypedExpr::Error(ty) => ty.clone(),
            TypedExpr::Ident { ty, .. } => ty.clone(),
            TypedExpr::GenRefCreate { inner_ty, .. } => Ty::GenRef(Box::new(inner_ty.clone())),
            TypedExpr::SelfExpr(ty, _) => ty.clone(),
            TypedExpr::If { ty, .. } => ty.clone(),
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

        let terminated = Self::body_ends_in_return(&f.body.stmts);
        let trailing_val = self.emit_stmts_value(&f.body.stmts);

        if !terminated {
            match &f.sig.ret {
                Some(rty) => {
                    let rty_s = self.llvm_ty(rty);
                    match trailing_val {
                        Some(v) => {
                            let clean = v.strip_prefix(&format!("{} ", rty_s)).unwrap_or(&v).to_string();
                            self.line(&format!("  ret {} {}", rty_s, clean));
                        }
                        None => {
                            self.err("function must end in a value-producing expression or explicit return", Span::dummy());
                            self.line(&format!("  ret {} undef", rty_s));
                        }
                    }
                }
                None => self.line("  ret void"),
            }
        }
        self.line("}");
        self.line("");
    }

    fn emit_stmt(&mut self, stmt: &TypedStmt) {
        match stmt {
            TypedStmt::Let { name, value, .. } => {
                let ty = self.llvm_ty(&self.expr_ty(value));
                let ptr = self.tmp_name();
                if self.in_frame {
                    // Frame allocation: bump-allocate `size` bytes from the frame
                    // buffer, advance (and persist) the offset, then bitcast the
                    // raw `i8*` slot to the value's actual pointer type so the
                    // subsequent store's operand types agree with the pointer's
                    // declared type.
                    self.line(&format!("  {} = load i64, i64* @frame.off", ptr));
                    let base = self.tmp_name();
                    self.line(&format!("  {} = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0", base));
                    let byte_ptr = self.tmp_name();
                    self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", byte_ptr, base, ptr));
                    let size = self.type_size(&self.expr_ty(value));
                    let store_offset = self.tmp_name();
                    self.line(&format!("  {} = add i64 {}, {}", store_offset, ptr, size));
                    self.line(&format!("  store i64 {}, i64* @frame.off", store_offset));
                    let typed_ptr = self.tmp_name();
                    self.line(&format!("  {} = bitcast i8* {} to {}*", typed_ptr, byte_ptr, ty));
                    let reg = self.emit_expr(value);
                    let clean_val = reg.strip_prefix(&format!("{} ", ty)).unwrap_or(&reg);
                    self.line(&format!("  store {} {}, {}* {}", ty, clean_val, ty, typed_ptr));
                    self.symbols.push((name.clone(), typed_ptr, self.expr_ty(value)));
                } else {
                    self.line(&format!("  {} = alloca {}", ptr, ty));
                    let reg = self.emit_expr(value);
                    let clean_val = reg.strip_prefix(&format!("{} ", ty)).unwrap_or(&reg);
                    self.line(&format!("  store {} {}, {}* {}", ty, clean_val, ty, ptr));
                    self.symbols.push((name.clone(), ptr, self.expr_ty(value)));
                }
            }
            TypedStmt::Assign { target, op, value, .. } => {
                let val_reg = self.emit_expr(value);
                if *op != AssignOp::Eq {
                    let loaded = self.load_target(target);
                    let tty = self.expr_ty(target);
                    let vty = self.expr_ty(value);
                    let compound = self.emit_assign_binop(&loaded, &tty, &val_reg, &vty, *op);
                    self.store_target(target, &compound);
                } else {
                    self.store_target(target, &val_reg);
                }
            }
            TypedStmt::Return { value, .. } => {
                if let Some(v) = value {
                    let reg = self.emit_expr(v);
                    let ty = self.expr_ty(v);
                    // `emit_expr` returns some values already tagged with
                    // their LLVM type (literals) and others bare (loads,
                    // calls); strip any existing tag so it's never doubled.
                    let clean = self.untag(&reg, &ty);
                    self.line(&format!("  ret {} {}", self.llvm_ty(&ty), clean));
                } else {
                    self.line("  ret void");
                }
            }
            TypedStmt::Expr(e) => { self.emit_expr(e); }
            TypedStmt::If { cond, then_block, else_block, .. } => {
                // Each arm may itself end in an unconditional `return` (e.g.
                // the state-machine chain a `sequence` desugars to); a `ret`
                // is a terminator, so the synthetic `br %end` below must be
                // skipped for any arm that already terminated -- LLVM
                // rejects instructions following a terminator in the same
                // block. The `end` block itself is only emitted if at least
                // one arm can still reach it.
                let then_terminates = Self::body_ends_in_return(&then_block.stmts);
                let else_terminates = else_block.as_ref().map(|b| Self::body_ends_in_return(&b.stmts)).unwrap_or(false);
                let both_terminate = then_terminates && else_terminates;

                let cond_val = self.emit_expr(cond);
                let cond_reg = self.reg_of(&cond_val);
                let then_label = self.block_label("if_then");
                let else_label = self.block_label("if_else");
                let end_label = self.block_label("if_end");
                self.line(&format!("  br i1 {}, label %{}, label %{}", cond_reg, then_label, else_label));
                self.line(&format!("{}:", then_label));
                for stmt in &then_block.stmts {
                    self.emit_stmt(stmt);
                }
                if !then_terminates {
                    self.line(&format!("  br label %{}", end_label));
                }
                self.line(&format!("{}:", else_label));
                if let Some(else_b) = else_block {
                    for stmt in &else_b.stmts {
                        self.emit_stmt(stmt);
                    }
                }
                if !else_terminates {
                    self.line(&format!("  br label %{}", end_label));
                }
                if !both_terminate {
                    self.line(&format!("{}:", end_label));
                }
            }
            TypedStmt::Frame { body, .. } => { self.emit_frame_body(body); }
            TypedStmt::While { cond, then_block, else_block, .. } => {
                let cond_label = self.block_label("while_cond");
                let body_label = self.block_label("while_body");
                let else_label = self.block_label("while_else");
                let end_label = self.block_label("while_end");
                // Loop header: evaluate the condition and branch.
                self.line(&format!("  br label %{}", cond_label));
                self.line(&format!("{}:", cond_label));
                let cond_val = self.emit_expr(cond);
                let cond_reg = self.reg_of(&cond_val);
                self.line(&format!("  br i1 {}, label %{}, label %{}", cond_reg, body_label, end_label));
                // Loop body: runs, then jumps back to the condition.
                self.line(&format!("{}:", body_label));
                for stmt in &then_block.stmts {
                    self.emit_stmt(stmt);
                }
                self.line(&format!("  br label %{}", cond_label));
                // Optional else clause runs once after the loop exits, then joins end.
                self.line(&format!("{}:", else_label));
                if let Some(else_b) = else_block {
                    for stmt in &else_b.stmts {
                        self.emit_stmt(stmt);
                    }
                }
                self.line(&format!("  br label %{}", end_label));
                self.line(&format!("{}:", end_label));
            }
            TypedStmt::Par { var, elem_ty, arena, body, .. } => {
                self.emit_par_stmt(var, elem_ty, arena, body);
            }
            TypedStmt::Spawn { arena, elem, .. } => {
                self.emit_spawn_stmt(arena, elem);
            }
            TypedStmt::Despawn { arena, index, .. } => {
                self.emit_despawn_stmt(arena, index);
            }
        }
    }

    /// The LLVM type of the pointer used to reach a symbol's storage. `self`
    /// receivers are spilled into a local alloca-of-pointer (see `emit_fn`),
    /// so reaching them takes one extra level of indirection versus a plain
    /// value local.
    fn sym_ptr_llvm_ty(&self, name: &str, ty: &Ty) -> String {
        if name == "self" {
            format!("{}**", self.llvm_ty(ty))
        } else {
            format!("{}*", self.llvm_ty(ty))
        }
    }

    /// Emit a `par`/`swarm item in ArenaName: <body>` statement: a fixed
    /// pool of worker threads, each processing a contiguous chunk of the
    /// arena's live elements. The checker has already proven the body only
    /// mutates `item` (or its own locals), so handing each thread a disjoint
    /// `[start, end)` range is safe.
    ///
    /// Everything currently in scope (locals, `self`) is captured by
    /// pointer into a small per-call argument struct and handed to
    /// `CreateThread`; the parent thread blocks on all of them via
    /// `WaitForSingleObject` before continuing, so the outer stack frame
    /// backing those captured pointers is guaranteed to outlive the threads
    /// that reference it.
    fn emit_par_stmt(&mut self, var: &str, elem_ty: &Ty, arena: &str, body: &TypedBlock) {
        const NUM_THREADS: u32 = 4;

        let id = self.block_id;
        self.block_id += 1;
        let worker_name = format!("par_worker_{}", id);

        let captured: Vec<(String, String, Ty)> = self.symbols.clone();

        // The argument struct `{ i64, i64, T1*, T2*, ... }` (chunk
        // `[start, end)` followed by one pointer field per captured outer
        // variable) is spelled out as an *anonymous* struct type rather than
        // a named `%ParArgsN`. LLVM resolves named types only after seeing
        // their declaration textually, but the worker function's `define`
        // must be deferred past the end of the enclosing function (see
        // `pending_top` below) while the call site's `alloca` needs the type
        // right here -- an anonymous type is structural, so both spellings
        // resolve to the same type without needing a forward declaration.
        let mut field_tys = vec!["i64".to_string(), "i64".to_string()];
        for (name, _, ty) in &captured {
            field_tys.push(self.sym_ptr_llvm_ty(name, ty));
        }
        let args_ty = format!("{{ {} }}", field_tys.join(", "));

        // --- worker function: walks [start, end) over the arena's backing array ---
        let saved_ir = std::mem::take(&mut self.ir);
        let saved_symbols = std::mem::take(&mut self.symbols);
        let saved_in_frame = self.in_frame;
        self.in_frame = false; // the frame bump allocator's offset is a single shared global, not thread-safe

        self.line(&format!("define i32 @{}(i8* %argp) {{", worker_name));
        self.line("entry:");
        let typed_arg = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* %argp to {}*", typed_arg, args_ty));
        let start_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", start_ptr, args_ty, args_ty, typed_arg));
        let start_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", start_reg, start_ptr));
        let end_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", end_ptr, args_ty, args_ty, typed_arg));
        let end_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", end_reg, end_ptr));

        for (i, (name, _, ty)) in captured.iter().enumerate() {
            let field_ptr = self.tmp_name();
            self.line(&format!(
                "  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}",
                field_ptr, args_ty, args_ty, typed_arg, i + 2
            ));
            let ptr_ty = self.sym_ptr_llvm_ty(name, ty);
            let loaded = self.tmp_name();
            self.line(&format!("  {} = load {}, {}* {}", loaded, ptr_ty, ptr_ty, field_ptr));
            self.symbols.push((name.clone(), loaded, ty.clone()));
        }

        let elem_llvm_ty = self.llvm_ty(elem_ty);
        let data_reg = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** @arena.{}.data", data_reg, elem_llvm_ty, elem_llvm_ty, arena));

        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 {}, i64* {}", start_reg, i_ptr));
        let cond_label = self.block_label("par_cond");
        let body_label = self.block_label("par_body");
        let end_label = self.block_label("par_end");
        self.line(&format!("  br label %{}", cond_label));
        self.line(&format!("{}:", cond_label));
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
        let cmp = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", cmp, i_reg, end_reg));
        self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, body_label, end_label));
        self.line(&format!("{}:", body_label));
        let elem_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds {}, {}* {}, i64 {}",
            elem_ptr, elem_llvm_ty, elem_llvm_ty, data_reg, i_reg
        ));
        self.symbols.push((var.to_string(), elem_ptr, elem_ty.clone()));
        for stmt in &body.stmts {
            self.emit_stmt(stmt);
        }
        self.symbols.pop();
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));
        self.line(&format!("{}:", end_label));
        self.line("  ret i32 0");
        self.line("}");
        self.line("");

        let worker_ir = std::mem::replace(&mut self.ir, saved_ir);
        self.pending_top.push(worker_ir);
        self.symbols = saved_symbols;
        self.in_frame = saved_in_frame;

        // --- back in the caller: divide the arena's live count into NUM_THREADS chunks ---
        let count_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @arena.{}.count", count_reg, arena));
        let handles = self.tmp_name();
        self.line(&format!("  {} = alloca [{} x i8*]", handles, NUM_THREADS));
        for t in 0..NUM_THREADS {
            let start_mul = self.tmp_name();
            self.line(&format!("  {} = mul i64 {}, {}", start_mul, count_reg, t));
            let start_div = self.tmp_name();
            self.line(&format!("  {} = sdiv i64 {}, {}", start_div, start_mul, NUM_THREADS));
            let end_mul = self.tmp_name();
            self.line(&format!("  {} = mul i64 {}, {}", end_mul, count_reg, t + 1));
            let end_div = self.tmp_name();
            self.line(&format!("  {} = sdiv i64 {}, {}", end_div, end_mul, NUM_THREADS));

            let args_ptr = self.tmp_name();
            self.line(&format!("  {} = alloca {}", args_ptr, args_ty));
            let sfield = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", sfield, args_ty, args_ty, args_ptr));
            self.line(&format!("  store i64 {}, i64* {}", start_div, sfield));
            let efield = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", efield, args_ty, args_ty, args_ptr));
            self.line(&format!("  store i64 {}, i64* {}", end_div, efield));
            for (i, (name, _, ty)) in captured.iter().enumerate() {
                let cfield = self.tmp_name();
                self.line(&format!(
                    "  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}",
                    cfield, args_ty, args_ty, args_ptr, i + 2
                ));
                let ptr_ty = self.sym_ptr_llvm_ty(name, ty);
                let src_ptr = self.sym_ptr(name).unwrap_or_else(|| "%undef".into());
                self.line(&format!("  store {} {}, {}* {}", ptr_ty, src_ptr, ptr_ty, cfield));
            }
            let args_i8 = self.tmp_name();
            self.line(&format!("  {} = bitcast {}* {} to i8*", args_i8, args_ty, args_ptr));
            let handle = self.tmp_name();
            self.line(&format!(
                "  {} = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @{} to i8*), i8* {}, i32 0, i32* null)",
                handle, worker_name, args_i8
            ));
            let hslot = self.tmp_name();
            self.line(&format!(
                "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* {}, i32 0, i32 {}",
                hslot, NUM_THREADS, NUM_THREADS, handles, t
            ));
            self.line(&format!("  store i8* {}, i8** {}", handle, hslot));
        }
        for t in 0..NUM_THREADS {
            let hslot = self.tmp_name();
            self.line(&format!(
                "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* {}, i32 0, i32 {}",
                hslot, NUM_THREADS, NUM_THREADS, handles, t
            ));
            let handle = self.tmp_name();
            self.line(&format!("  {} = load i8*, i8** {}", handle, hslot));
            let wait = self.tmp_name();
            self.line(&format!("  {} = call i32 @WaitForSingleObject(i8* {}, i32 -1)", wait, handle));
            let close = self.tmp_name();
            self.line(&format!("  {} = call i32 @CloseHandle(i8* {})", close, handle));
        }
    }

    /// Emit `spawn ArenaName(args...)`. Arenas start out empty (`data` is
    /// `null`, `count` is `0` -- see `emit_arena_decl`), so the first spawn
    /// into a given arena lazily `malloc`s a fixed-capacity backing array;
    /// every spawn after that reuses it. A slot is claimed by first popping
    /// the arena's free-list (slots reclaimed by `despawn`); only when it's
    /// empty does spawn fall back to growing `count`, so spawn/despawn churn
    /// doesn't monotonically grow the arena -- the "logical leak" design.md
    /// calls out. The element is constructed (via the same codegen path as
    /// any other struct literal) directly into the claimed slot, and that
    /// slot's generation is bumped by one either way (never reset to a fixed
    /// value -- see `emit_arena_decl` on why that matters for reused slots).
    /// A spawn past `ARENA_CAPACITY` live elements is silently dropped rather
    /// than writing out of bounds -- a fixed backing store never
    /// reallocs/moves, which matters because `par`/`swarm` workers may be
    /// reading it concurrently from other threads.
    fn emit_spawn_stmt(&mut self, arena: &str, elem: &TypedExpr) {
        let elem_ty = self.expr_ty(elem);
        let elem_llvm_ty = self.llvm_ty(&elem_ty);

        let data_reg = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** @arena.{}.data", data_reg, elem_llvm_ty, elem_llvm_ty, arena));
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq {}* {}, null", is_null, elem_llvm_ty, data_reg));
        let init_label = self.block_label("spawn_init");
        let ready_label = self.block_label("spawn_ready");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, init_label, ready_label));

        self.line(&format!("{}:", init_label));
        let bytes = self.type_size(&elem_ty) as u64 * Self::ARENA_CAPACITY;
        let raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", raw, bytes));
        let casted = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", casted, raw, elem_llvm_ty));
        self.line(&format!("  store {}* {}, {}** @arena.{}.data", elem_llvm_ty, casted, elem_llvm_ty, arena));
        self.line(&format!("  br label %{}", ready_label));

        self.line(&format!("{}:", ready_label));
        let data_ready = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** @arena.{}.data", data_ready, elem_llvm_ty, elem_llvm_ty, arena));

        // Prefer reclaiming a despawned slot off the free-list over growing
        // `count`.
        let free_top_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @arena.{}.free_top", free_top_reg, arena));
        let has_free = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i64 {}, 0", has_free, free_top_reg));
        let reuse_label = self.block_label("spawn_reuse");
        let grow_label = self.block_label("spawn_grow");
        self.line(&format!("  br i1 {}, label %{}, label %{}", has_free, reuse_label, grow_label));

        self.line(&format!("{}:", reuse_label));
        let new_free_top = self.tmp_name();
        self.line(&format!("  {} = sub i64 {}, 1", new_free_top, free_top_reg));
        self.line(&format!("  store i64 {}, i64* @arena.{}.free_top", new_free_top, arena));
        let free_slot_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @arena.{}.free, i64 0, i64 {}",
            free_slot_ptr, Self::ARENA_CAPACITY, Self::ARENA_CAPACITY, arena, new_free_top
        ));
        let reused_idx = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", reused_idx, free_slot_ptr));
        let store_label = self.block_label("spawn_store");
        let end_label = self.block_label("spawn_end");
        self.line(&format!("  br label %{}", store_label));

        self.line(&format!("{}:", grow_label));
        let count_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @arena.{}.count", count_reg, arena));
        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", in_bounds, count_reg, Self::ARENA_CAPACITY));
        let grow_ok_label = self.block_label("spawn_grow_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, grow_ok_label, end_label));

        self.line(&format!("{}:", grow_ok_label));
        let next_count = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", next_count, count_reg));
        self.line(&format!("  store i64 {}, i64* @arena.{}.count", next_count, arena));
        self.line(&format!("  br label %{}", store_label));

        self.line(&format!("{}:", store_label));
        let slot_idx = self.tmp_name();
        self.line(&format!(
            "  {} = phi i64 [ {}, %{} ], [ {}, %{} ]",
            slot_idx, reused_idx, reuse_label, count_reg, grow_ok_label
        ));
        let val = self.emit_expr(elem);
        let clean_val = self.untag(&val, &elem_ty);
        let slot_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds {}, {}* {}, i64 {}",
            slot_ptr, elem_llvm_ty, elem_llvm_ty, data_ready, slot_idx
        ));
        self.line(&format!("  store {} {}, {}* {}", elem_llvm_ty, clean_val, elem_llvm_ty, slot_ptr));
        // Bump this slot's generation by one rather than resetting it to a
        // fixed value: a reused slot's generation was already advanced by
        // `emit_despawn_stmt`, and re-stamping a constant here would let a
        // stale `GenRef` captured before that despawn incorrectly match
        // again (the ABA problem design.md calls out).
        let gen_slot_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i32], [{} x i32]* @arena.{}.gen, i64 0, i64 {}",
            gen_slot_ptr, Self::ARENA_CAPACITY, Self::ARENA_CAPACITY, arena, slot_idx
        ));
        let cur_gen = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", cur_gen, gen_slot_ptr));
        let next_gen = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", next_gen, cur_gen));
        self.line(&format!("  store i32 {}, i32* {}", next_gen, gen_slot_ptr));
        self.line(&format!("  br label %{}", end_label));

        self.line(&format!("{}:", end_label));
    }

    /// Emit `despawn ArenaName[index]`: if the slot is currently live (odd
    /// generation -- see `emit_arena_decl`), bumps its generation by 1
    /// (invalidating any `GenRef` created against the old value) and pushes
    /// the slot onto the arena's free-list so a later `spawn` can reclaim
    /// its memory instead of only ever growing `count`. An out-of-bounds
    /// `index`, or one that's already dead (never spawned, or already
    /// despawned), is a silent no-op -- this also guards against a
    /// double-despawn pushing the same slot onto the free-list twice, which
    /// would otherwise let two later spawns alias the same memory.
    fn emit_despawn_stmt(&mut self, arena: &str, index: &TypedExpr) {
        let idx_val = self.emit_expr(index);
        let idx_bare = self.untag(&idx_val, &Ty::Int);
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, idx_bare));
        // Unsigned compare: a negative index sign-extends/wraps to a huge
        // unsigned value, so it safely fails this bounds check too instead
        // of aliasing a valid slot.
        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, Self::ARENA_CAPACITY));
        let do_label = self.block_label("despawn_do");
        let end_label = self.block_label("despawn_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, do_label, end_label));

        self.line(&format!("{}:", do_label));
        let gen_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i32], [{} x i32]* @arena.{}.gen, i64 0, i64 {}",
            gen_ptr, Self::ARENA_CAPACITY, Self::ARENA_CAPACITY, arena, idx64
        ));
        let gen_val = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", gen_val, gen_ptr));
        let parity = self.tmp_name();
        self.line(&format!("  {} = and i32 {}, 1", parity, gen_val));
        let is_live = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 1", is_live, parity));
        let live_label = self.block_label("despawn_live");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_live, live_label, end_label));

        self.line(&format!("{}:", live_label));
        let next_gen = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", next_gen, gen_val));
        self.line(&format!("  store i32 {}, i32* {}", next_gen, gen_ptr));
        let free_top_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @arena.{}.free_top", free_top_reg, arena));
        let free_slot_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @arena.{}.free, i64 0, i64 {}",
            free_slot_ptr, Self::ARENA_CAPACITY, Self::ARENA_CAPACITY, arena, free_top_reg
        ));
        self.line(&format!("  store i64 {}, i64* {}", idx64, free_slot_ptr));
        let next_free_top = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", next_free_top, free_top_reg));
        self.line(&format!("  store i64 {}, i64* @arena.{}.free_top", next_free_top, arena));
        self.line(&format!("  br label %{}", end_label));

        self.line(&format!("{}:", end_label));
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
                if self.expr_ty(base).is_vec() {
                    let val = self.emit_swizzle_read(base, field);
                    return self.reg_of(&val);
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
                if self.expr_ty(base).is_vec() {
                    self.emit_swizzle_write(base, field, ty, val);
                    return;
                }
                let base_ptr = self.emit_place(base);
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

    /// Shared lowering for the `print`/`println` builtins: an f-string
    /// argument is flattened into a single `printf` format string
    /// (interpolations become `%d`/`%f`/`%s` holes); any other argument is
    /// passed straight through as a format-string pointer. `println` differs
    /// from `print` only in that it guarantees a trailing newline even when
    /// the argument isn't an f-string (an f-string argument already gets one
    /// baked into its format string either way).
    fn emit_print_like(&mut self, args: &[TypedExpr], println: bool) {
        let Some(arg) = args.first() else { return };
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
                        // `emit_expr` may return either a bare register
                        // or one already tagged with its LLVM type
                        // (e.g. swizzle reads) — strip any existing tag
                        // so it isn't double-tagged below.
                        let bare_val = self.untag(&val, &ty);
                        // For string arguments, `bare_val` is the alloca
                        // holding the `i8*`; load it to get the pointer
                        // that `%s` expects.
                        let arg_val = if matches!(ty, Ty::Str) {
                            let loaded = self.tmp_name();
                            self.line(&format!("  {} = load i8*, i8** {}", loaded, bare_val));
                            loaded
                        } else {
                            bare_val
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
                if matches!(ty, Ty::Float) {
                    // C's variadic calling convention always
                    // promotes `float` to `double`; printf's
                    // `%f` reads a `double` off the varargs.
                    let widened = self.tmp_name();
                    self.line(&format!("  {} = fpext float {} to double", widened, val));
                    call_args.push(format!("double {}", widened));
                } else {
                    call_args.push(format!("{} {}", self.llvm_ty(ty), val));
                }
            }
            self.line(&format!("  call i32 (i8*, ...) @printf({})", call_args.join(", ")));
        } else {
            let fmt_ptr = self.emit_expr(arg);
            let loaded = self.tmp_name();
            self.line(&format!("  {} = load i8*, i8** {}", loaded, fmt_ptr));
            self.line(&format!("  call i32 (i8*, ...) @printf(i8* {})", loaded));
            if println {
                let g = self.global_name();
                self.global_defs.push(format!("{} = private unnamed_addr constant [2 x i8] c\"\\0A\\00\"", g));
                let nl_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds [2 x i8], [2 x i8]* {}, i64 0, i64 0", nl_ptr, g));
                self.line(&format!("  call i32 (i8*, ...) @printf(i8* {})", nl_ptr));
            }
        }
    }

    /// Call a unary LLVM float intrinsic (`sqrt`, `floor`, `ceil`),
    /// promoting an `i32` argument to `float` first if needed.
    fn emit_math_unary(&mut self, args: &[TypedExpr], intrinsic: &str) -> String {
        let Some(arg) = args.first() else {
            self.err(&format!("{}(..) expects 1 argument", intrinsic), Span::dummy());
            return "float 0.0".into();
        };
        let ty = self.expr_ty(arg);
        let val = self.emit_expr(arg);
        let bare = self.promote_to_float(&val, &ty);
        let reg = self.tmp_name();
        self.line(&format!("  {} = call float @{}(float {})", reg, intrinsic, bare));
        format!("float {}", reg)
    }

    /// Call a binary LLVM float intrinsic (`pow`), promoting `i32` arguments
    /// to `float` first if needed.
    fn emit_math_binary_f32(&mut self, args: &[TypedExpr], intrinsic: &str) -> String {
        if args.len() < 2 {
            self.err(&format!("{}(..) expects 2 arguments", intrinsic), Span::dummy());
            return "float 0.0".into();
        }
        let lty = self.expr_ty(&args[0]);
        let rty = self.expr_ty(&args[1]);
        let lval = self.emit_expr(&args[0]);
        let rval = self.emit_expr(&args[1]);
        let lbare = self.promote_to_float(&lval, &lty);
        let rbare = self.promote_to_float(&rval, &rty);
        let reg = self.tmp_name();
        self.line(&format!("  {} = call float @{}(float {}, float {})", reg, intrinsic, lbare, rbare));
        format!("float {}", reg)
    }

    /// `abs(x)`: dispatches on the argument's resolved type, preserving
    /// Int-vs-Float rather than always widening to float.
    fn emit_abs(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("abs(..) expects 1 argument", Span::dummy());
            return "i32 0".into();
        };
        let ty = self.expr_ty(arg);
        let val = self.emit_expr(arg);
        let bare = self.untag(&val, &ty);
        if matches!(ty, Ty::Float) {
            let reg = self.tmp_name();
            self.line(&format!("  {} = call float @llvm.fabs.f32(float {})", reg, bare));
            format!("float {}", reg)
        } else {
            let neg = self.tmp_name();
            self.line(&format!("  {} = sub i32 0, {}", neg, bare));
            let is_neg = self.tmp_name();
            self.line(&format!("  {} = icmp slt i32 {}, 0", is_neg, bare));
            let reg = self.tmp_name();
            self.line(&format!("  {} = select i1 {}, i32 {}, i32 {}", reg, is_neg, neg, bare));
            format!("i32 {}", reg)
        }
    }

    /// `min(a, b)`/`max(a, b)`: dispatches on the arguments' resolved type
    /// (Int uses `icmp`+`select`, Float uses the `minnum`/`maxnum`
    /// intrinsics), preserving Int-vs-Float rather than always widening.
    fn emit_minmax(&mut self, args: &[TypedExpr], is_min: bool) -> String {
        if args.len() < 2 {
            self.err("min/max(..) expects 2 arguments", Span::dummy());
            return "i32 0".into();
        }
        let lty = self.expr_ty(&args[0]);
        let rty = self.expr_ty(&args[1]);
        let lval = self.emit_expr(&args[0]);
        let rval = self.emit_expr(&args[1]);
        if matches!(lty, Ty::Float) || matches!(rty, Ty::Float) {
            let l = self.promote_to_float(&lval, &lty);
            let r = self.promote_to_float(&rval, &rty);
            let reg = self.tmp_name();
            let intrinsic = if is_min { "llvm.minnum.f32" } else { "llvm.maxnum.f32" };
            self.line(&format!("  {} = call float @{}(float {}, float {})", reg, intrinsic, l, r));
            format!("float {}", reg)
        } else {
            let l = self.untag(&lval, &lty);
            let r = self.untag(&rval, &rty);
            let cmp = self.tmp_name();
            let pred = if is_min { "slt" } else { "sgt" };
            self.line(&format!("  {} = icmp {} i32 {}, {}", cmp, pred, l, r));
            let reg = self.tmp_name();
            self.line(&format!("  {} = select i1 {}, i32 {}, i32 {}", reg, cmp, l, r));
            format!("i32 {}", reg)
        }
    }

    /// Load the real `i8*` out of a `Str`-typed expression. Every `Str`-typed
    /// value in this codegen is represented as a pointer to a slot holding
    /// the actual string pointer (see `TypedExpr::Str`'s own codegen below),
    /// so getting the real bytes always takes one more `load` than the
    /// expression's own emitted register.
    fn emit_raw_str_ptr(&mut self, e: &TypedExpr) -> String {
        let val = self.emit_expr(e);
        let bare = self.untag(&val, &Ty::Str);
        let reg = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", reg, bare));
        reg
    }

    /// Box a raw `i8*` into the same "pointer to a slot holding the string
    /// pointer" representation `TypedExpr::Str` produces, so a builtin's
    /// `Str`-typed result composes with the rest of the codegen (`let`,
    /// further `print`/`concat` calls, ...) exactly like a literal would.
    fn box_str_ptr(&mut self, raw_ptr: &str) -> String {
        let slot = self.tmp_name();
        self.line(&format!("  {} = alloca i8*", slot));
        self.line(&format!("  store i8* {}, i8** {}", raw_ptr, slot));
        slot
    }

    /// `len(s) -> i32`.
    fn emit_str_len(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("len(..) expects 1 argument", Span::dummy());
            return "i32 0".into();
        };
        let raw = self.emit_raw_str_ptr(arg);
        let reg = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", reg, raw));
        format!("i32 {}", reg)
    }

    /// `concat(a, b) -> str`: allocates a new buffer sized for both strings
    /// plus a null terminator, then copies `a` followed by `b` into it.
    fn emit_str_concat(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("concat(..) expects 2 arguments", Span::dummy());
            return "i8* null".into();
        }
        let a = self.emit_raw_str_ptr(&args[0]);
        let b = self.emit_raw_str_ptr(&args[1]);
        let len_a = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", len_a, a));
        let len_b = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", len_b, b));
        let total = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, {}", total, len_a, len_b));
        let total_plus_nul = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", total_plus_nul, total));
        let total64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", total64, total_plus_nul));
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", buf, total64));
        self.line(&format!("  call i8* @strcpy(i8* {}, i8* {})", buf, a));
        self.line(&format!("  call i8* @strcat(i8* {}, i8* {})", buf, b));
        self.box_str_ptr(&buf)
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

    fn emit_expr(&mut self, expr: &TypedExpr) -> String {
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
            // `GenRef<T>(idx)`: creates a handle to slot `idx` of the arena
            // backing `T`, capturing that slot's *live* generation right now
            // (rather than hardcoding 0) so a later dereference can detect
            // whether the slot has since been despawned/replaced. Known
            // limitation: a never-spawned slot's live generation is also 0,
            // so a GenRef created against one is indistinguishable from a
            // freshly-valid reference -- orthogonal to the stale-after-
            // despawn guarantee this implements; closing it is future work.
            TypedExpr::GenRefCreate { inner_ty, value, span } => {
                let arena = self.arena_for_elem_ty(inner_ty, *span);
                let val = self.emit_expr(value);
                let idx_i32 = self.untag(&val, &Ty::Int);
                let idx64 = self.tmp_name();
                self.line(&format!("  {} = sext i32 {} to i64", idx64, idx_i32));

                // Bounds-check before reading the gen array: `idx` is an
                // arbitrary (possibly bug/attacker-controlled) expression,
                // not an internally-generated counter, so it can't be
                // trusted the way `spawn`'s `count` can.
                let in_bounds = self.tmp_name();
                self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, Self::ARENA_CAPACITY));
                let ok_label = self.block_label("genref_create_ok");
                let oob_label = self.block_label("genref_create_oob");
                let end_label = self.block_label("genref_create_end");
                self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, ok_label, oob_label));

                self.line(&format!("{}:", ok_label));
                let gen_ptr = self.tmp_name();
                self.line(&format!(
                    "  {} = getelementptr inbounds [{} x i32], [{} x i32]* @arena.{}.gen, i64 0, i64 {}",
                    gen_ptr, Self::ARENA_CAPACITY, Self::ARENA_CAPACITY, arena, idx64
                ));
                let gen_ok = self.tmp_name();
                self.line(&format!("  {} = load i32, i32* {}", gen_ok, gen_ptr));
                self.line(&format!("  br label %{}", end_label));

                self.line(&format!("{}:", oob_label));
                self.line(&format!("  br label %{}", end_label));

                self.line(&format!("{}:", end_label));
                let gen_val = self.tmp_name();
                self.line(&format!(
                    "  {} = phi i32 [ {}, %{} ], [ 0, %{} ]",
                    gen_val, gen_ok, ok_label, oob_label
                ));

                let ptr = self.tmp_name();
                self.line(&format!("  {} = alloca %GenRef", ptr));
                let field0 = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds %GenRef, %GenRef* {}, i32 0, i32 0", field0, ptr));
                self.line(&format!("  store i32 {}, i32* {}", idx_i32, field0));
                let gen_field_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds %GenRef, %GenRef* {}, i32 0, i32 1", gen_field_ptr, ptr));
                self.line(&format!("  store i32 {}, i32* {}", gen_val, gen_field_ptr));
                let loaded = self.tmp_name();
                self.line(&format!("  {} = load %GenRef, %GenRef* {}", loaded, ptr));
                format!("%GenRef {}", loaded)
            }
            // `genref[N]`: `N` is vestigial (kept for backward-compatible
            // `expr[idx]` deref syntax) -- the real slot index lives in the
            // GenRef's own stored `index` field from creation time. Validates
            // bounds and the stored generation against the arena's *live*
            // generation for that slot; a mismatch (or an out-of-bounds
            // index) yields the element type's zero value instead of reading
            // stale/garbage data.
            TypedExpr::GenRefIndex { base, ty, span, .. } => {
                let elem_ty = ty.clone();
                let elem_llvm_ty = self.llvm_ty(&elem_ty);
                let arena = self.arena_for_elem_ty(&elem_ty, *span);

                let base_ptr = self.emit_place(base);
                let idx_field_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds %GenRef, %GenRef* {}, i32 0, i32 0", idx_field_ptr, base_ptr));
                let stored_idx = self.tmp_name();
                self.line(&format!("  {} = load i32, i32* {}", stored_idx, idx_field_ptr));
                let gen_field_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds %GenRef, %GenRef* {}, i32 0, i32 1", gen_field_ptr, base_ptr));
                let stored_gen = self.tmp_name();
                self.line(&format!("  {} = load i32, i32* {}", stored_gen, gen_field_ptr));
                let idx64 = self.tmp_name();
                self.line(&format!("  {} = sext i32 {} to i64", idx64, stored_idx));

                let in_bounds = self.tmp_name();
                self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, Self::ARENA_CAPACITY));
                let check_label = self.block_label("genref_check");
                let ok_label = self.block_label("genref_ok");
                let stale_label = self.block_label("genref_stale");
                let end_label = self.block_label("genref_end");
                self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, check_label, stale_label));

                self.line(&format!("{}:", check_label));
                let gen_ptr = self.tmp_name();
                self.line(&format!(
                    "  {} = getelementptr inbounds [{} x i32], [{} x i32]* @arena.{}.gen, i64 0, i64 {}",
                    gen_ptr, Self::ARENA_CAPACITY, Self::ARENA_CAPACITY, arena, idx64
                ));
                let live_gen = self.tmp_name();
                self.line(&format!("  {} = load i32, i32* {}", live_gen, gen_ptr));
                let gen_match = self.tmp_name();
                self.line(&format!("  {} = icmp eq i32 {}, {}", gen_match, stored_gen, live_gen));
                self.line(&format!("  br i1 {}, label %{}, label %{}", gen_match, ok_label, stale_label));

                self.line(&format!("{}:", ok_label));
                let data_ptr = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** @arena.{}.data", data_ptr, elem_llvm_ty, elem_llvm_ty, arena));
                let elem_ptr = self.tmp_name();
                self.line(&format!(
                    "  {} = getelementptr inbounds {}, {}* {}, i64 {}",
                    elem_ptr, elem_llvm_ty, elem_llvm_ty, data_ptr, idx64
                ));
                let elem_val = self.tmp_name();
                self.line(&format!("  {} = load {}, {}* {}", elem_val, elem_llvm_ty, elem_llvm_ty, elem_ptr));
                self.line(&format!("  br label %{}", end_label));

                // Both failure paths (out-of-bounds, stale generation) funnel
                // through this one block so the `phi` below sees exactly two
                // incoming edges.
                self.line(&format!("{}:", stale_label));
                self.line(&format!("  br label %{}", end_label));

                self.line(&format!("{}:", end_label));
                let zero = self.zero_value(&elem_ty);
                let result = self.tmp_name();
                self.line(&format!(
                    "  {} = phi {} [ {}, %{} ], [ {}, %{} ]",
                    result, elem_llvm_ty, elem_val, ok_label, zero, stale_label
                ));
                format!("{} {}", elem_llvm_ty, result)
            }
            TypedExpr::Error(_) => "%undef".into(),
        }
    }

    /// Strip a value's leading `<llvm-type> ` tag, given its resolved `Ty`.
    fn untag(&self, s: &str, ty: &Ty) -> String {
        let t = self.llvm_ty(ty);
        s.strip_prefix(&format!("{} ", t)).unwrap_or(s).to_string()
    }

    /// Strip a bare `i32`/`float` tag and, if the operand is an `Int`,
    /// convert it to `float` via `sitofp` so it can be used in float
    /// arithmetic. Returns a bare (untagged) register.
    fn promote_to_float(&mut self, val: &str, ty: &Ty) -> String {
        let bare = self.untag(val, ty);
        if matches!(ty, Ty::Int) {
            let reg = self.tmp_name();
            self.line(&format!("  {} = sitofp i32 {} to float", reg, bare));
            reg
        } else {
            bare
        }
    }

    /// Extract lane/field `i` from an already-loaded vector value `val` of
    /// type `ty`, returning a bare `float` register.
    fn extract_component(&mut self, val: &str, ty: &Ty, i: u32) -> String {
        let reg = self.tmp_name();
        match ty {
            Ty::Vec4 => self.line(&format!("  {} = extractelement <4 x float> {}, i32 {}", reg, val, i)),
            _ => {
                let t = self.llvm_ty(ty);
                self.line(&format!("  {} = extractvalue {} {}, {}", reg, t, val, i));
            }
        }
        reg
    }

    /// Insert a bare `float` register into lane/field `i` of `acc` (an
    /// already-built or `undef` aggregate of type `ty`), returning the
    /// updated aggregate register.
    fn insert_component(&mut self, acc: &str, ty: &Ty, i: u32, scalar: &str) -> String {
        let reg = self.tmp_name();
        match ty {
            Ty::Vec4 => self.line(&format!("  {} = insertelement <4 x float> {}, float {}, i32 {}", reg, acc, scalar, i)),
            _ => {
                let t = self.llvm_ty(ty);
                self.line(&format!("  {} = insertvalue {} {}, float {}, {}", reg, t, acc, scalar, i));
            }
        }
        reg
    }

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

    fn emit_binop(&mut self, lhs: &str, lty: &Ty, rhs: &str, rty: &Ty, op: BinOp) -> String {
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

    fn emit_assign_binop(&mut self, lhs: &str, lty: &Ty, rhs: &str, rty: &Ty, op: AssignOp) -> String {
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