//! Name and type resolution for Star.
//!
//! The checker performs Hindley-Milner-style inference with explicit type
//! annotations where required (struct fields, parameters, return types). Every
//! expression is given an inferred [`Ty`] after resolution.
//!
//! The `Checker` struct and its declaration/item-level checks live here;
//! each area of analysis has its own `impl Checker` block in a sibling
//! submodule: `hir` (the typed tree `Checker::check` produces), `stmt`
//! (statement checking), `expr` (expression inference), `par_analysis`
//! (the `par`/`swarm` disjoint-mutation proof), and `frame_analysis` (the
//! `frame:` escape analysis).

mod expr;
mod frame_analysis;
mod hir;
mod par_analysis;
mod stmt;

pub use hir::*;

use crate::ast::*;
use crate::diagnostics::{suggest, Diagnostic, Span};
use std::collections::HashMap;

/// A resolved type.
#[derive(Clone, Debug, PartialEq)]
pub enum Ty {
    Int,
    Float,
    Str,
    Bool,
    Vec2,
    Vec3,
    Vec4,
    Mat4,
    Named(String),
    /// A generational reference backed by a slot-map: GenRef<T>.
    GenRef(Box<Ty>),
    /// A growable, heap-allocated dynamic array: `List<T>`. Lowers to
    /// `{ T* data, i64 len, i64 cap }` -- see `Codegen::llvm_ty`. Unlike
    /// `GenRef<T>`'s fixed-capacity arena, each `List<T>` value owns an
    /// independent, individually `malloc`/`realloc`'d buffer (see
    /// `crate::codegen::list`).
    List(Box<Ty>),
    /// A fieldless enum type, lowered to a plain `i32` discriminant.
    Enum(String),
    /// A closure/lambda's type: declared parameter types and return type.
    /// Lowered to a `{ i8* fn_ptr, i8* env_ptr }` "fat pointer" pair -- see
    /// `crate::codegen::Codegen::emit_closure_lit`.
    Closure(Vec<Ty>, Box<Ty>),
}

impl Ty {
    /// True for the builtin SIMD vector types (Vec2/Vec3/Vec4).
    pub fn is_vec(&self) -> bool {
        matches!(self, Ty::Vec2 | Ty::Vec3 | Ty::Vec4)
    }

    /// True for the builtin SIMD matrix type (Mat4).
    pub fn is_mat(&self) -> bool {
        matches!(self, Ty::Mat4)
    }

    /// The component count of a builtin vector type, or `None` for anything else.
    pub fn vec_arity(&self) -> Option<u8> {
        match self {
            Ty::Vec2 => Some(2),
            Ty::Vec3 => Some(3),
            Ty::Vec4 => Some(4),
            _ => None,
        }
    }

    /// The vector type with the given component count (1 -> scalar Float).
    pub fn vec_of_arity(n: u8) -> Option<Ty> {
        match n {
            1 => Some(Ty::Float),
            2 => Some(Ty::Vec2),
            3 => Some(Ty::Vec3),
            4 => Some(Ty::Vec4),
            _ => None,
        }
    }
}

/// Names and return-type rules for the compiler's built-in standard library
/// (see `crate::codegen` for their lowering). These aren't declared by any
/// `fn` item, so the checker special-cases them instead of consulting the
/// user-defined function table. Returns `None` for anything that isn't a
/// recognized builtin name, so ordinary user functions/methods fall through
/// to the normal lookup unaffected.
fn builtin_return_ty(name: &str, args: &[TypedExpr]) -> Option<Ty> {
    match name {
        // No return value; `Ty::Named("unknown")` is the established
        // convention codegen already treats as a `void` call (see
        // `crate::codegen::Codegen::emit_expr`'s `TypedExpr::Call` arm).
        "print" | "println" => Some(Ty::Named("unknown".into())),
        "sqrt" | "pow" | "floor" | "ceil" => Some(Ty::Float),
        // `abs`/`min`/`max` preserve the numeric type (Int or Float) of
        // their first argument rather than always widening to Float.
        "abs" | "min" | "max" => Some(args.first().map(|a| a.clone().into_ty()).unwrap_or(Ty::Float)),
        "len" => Some(Ty::Int),
        "concat" => Some(Ty::Str),
        _ => None,
    }
}

/// The error type for type checking.
#[derive(Clone, Debug)]
pub struct TypeError {
    pub message: String,
    pub span: Span,
    /// An optional "did you mean `x`?" style hint.
    pub note: Option<String>,
}

/// The checker holds symbol tables and the current error list.
pub struct Checker {
    structs: HashMap<String, StructDef>,
    traits: HashMap<String, TraitDef>,
    arenas: HashMap<String, Ty>,
    enums: HashMap<String, EnumDef>,
    /// Function signatures: maps function name -> (param_tys, ret_ty)
    functions: HashMap<String, (Vec<Ty>, Option<Ty>)>,
    /// Generic struct/enum/fn templates -- declarations with a non-empty
    /// `type_params` list, kept separate from `structs`/`enums`/`functions`
    /// since they have no concrete layout of their own until instantiated
    /// (see `instantiate_struct`/`instantiate_enum`/`instantiate_fn`).
    generic_structs: HashMap<String, StructDef>,
    generic_enums: HashMap<String, EnumDef>,
    generic_fns: HashMap<String, FnDef>,
    /// Reverse map from a monomorphized struct/enum's mangled name back to
    /// the generic template it was instantiated from and the concrete type
    /// arguments used, so a match pattern written against the generic
    /// template name (`Option::Some(v)`) can be resolved to whichever
    /// concrete instantiation the scrutinee actually has (see
    /// `resolve_pattern_enum_name`) and so a generic function call can
    /// unify a parameter type like `Box<T>` against an already-monomorphized
    /// argument (see `unify_ty`).
    mono_struct_of: HashMap<String, (String, Vec<Ty>)>,
    mono_enum_of: HashMap<String, (String, Vec<Ty>)>,
    /// Monomorphized struct/enum/fn items generated on demand while checking
    /// (e.g. the first time `Box<i32>` or `identity(5)` is used), appended to
    /// the module's typed items once checking finishes (see `check`).
    mono_items: Vec<TypedItem>,
    errors: Vec<TypeError>,
    /// Nesting depth of enclosing `while`/`for` loops, used to reject
    /// `break`/`continue` outside of a loop. Explicitly reset to `0` while
    /// checking a `par`/`swarm` body (see `check_stmt`'s `Stmt::Par` arm),
    /// since a worker-thread dispatch has no well-defined `break`/`continue`
    /// target even when nested inside an outer loop.
    loop_depth: u32,
}

impl Checker {
    pub fn new() -> Self {
        Self {
            structs: HashMap::new(),
            traits: HashMap::new(),
            arenas: HashMap::new(),
            enums: HashMap::new(),
            functions: HashMap::new(),
            generic_structs: HashMap::new(),
            generic_enums: HashMap::new(),
            generic_fns: HashMap::new(),
            mono_struct_of: HashMap::new(),
            mono_enum_of: HashMap::new(),
            mono_items: Vec::new(),
            errors: Vec::new(),
            loop_depth: 0,
        }
    }

    pub fn check(&mut self, module: &Module) -> Result<TypedModule, Vec<Diagnostic>> {
        // `sequence` items are pure syntax sugar over struct+impl (see
        // `crate::sequence`); desugar them before any of the checks below
        // ever see an `Item::Sequence`.
        let (module, desugar_errors) = crate::sequence::desugar_module(module);
        if !desugar_errors.is_empty() {
            return Err(desugar_errors);
        }

        // First pass (0): register every struct/enum/fn *name* -- generic
        // templates into `generic_structs`/`generic_enums`/`generic_fns`,
        // everything else into `structs`/`enums` -- before any type is
        // resolved. This has to happen as its own pass, ahead of the arena/
        // function-signature resolution below, so a forward reference to a
        // generic type (or another struct declared later in the file) always
        // sees it regardless of declaration order.
        for item in &module.items {
            match item {
                Item::Struct(s) if !s.type_params.is_empty() => { self.generic_structs.insert(s.name.clone(), s.clone()); }
                Item::Struct(s) => { self.structs.insert(s.name.clone(), s.clone()); }
                Item::Enum(e) if !e.type_params.is_empty() => { self.generic_enums.insert(e.name.clone(), e.clone()); }
                Item::Enum(e) => { self.enums.insert(e.name.clone(), e.clone()); }
                Item::Fn(f) if !f.sig.type_params.is_empty() => { self.generic_fns.insert(f.sig.name.clone(), f.clone()); }
                _ => {}
            }
        }

        // Pass 1: collect the remaining declarations (traits, arenas,
        // concrete function/method signatures). A generic `fn` has no
        // concrete signature to register here -- its type parameters are
        // solved per call site (see `infer_generic_call`) -- so it's skipped;
        // it was already registered into `generic_fns` above.
        for item in &module.items {
            match item {
                Item::Struct(_) | Item::Enum(_) => {}
                Item::Trait(t) => { self.traits.insert(t.name.clone(), t.clone()); }
                Item::Arena(a) => {
                    let ty = self.resolve_type(&a.ty).unwrap_or(Ty::Named("unknown".into()));
                    self.arenas.insert(a.name.clone(), ty);
                }
                Item::Fn(f) if f.sig.type_params.is_empty() => {
                    let param_tys: Vec<Ty> = f.sig.params.iter().map(|p| {
                        p.ty.as_ref().and_then(|t| self.resolve_type(t)).unwrap_or(Ty::Named("infer".into()))
                    }).collect();
                    let ret_ty = f.sig.ret.as_ref().and_then(|t| self.resolve_type(t));
                    self.functions.insert(f.sig.name.clone(), (param_tys, ret_ty));
                }
                Item::Fn(_) => {}
                Item::Impl(blk) => {
                    for m in &blk.methods {
                        let param_tys: Vec<Ty> = m.sig.params.iter().map(|p| {
                            p.ty.as_ref().and_then(|t| self.resolve_type(t)).unwrap_or(Ty::Named("infer".into()))
                        }).collect();
                        let ret_ty = m.sig.ret.as_ref().and_then(|t| self.resolve_type(t));
                        self.functions.insert(m.sig.name.clone(), (param_tys, ret_ty));
                    }
                }
                // Desugared away above; never present past this point.
                Item::Sequence(_) => {}
                // Resolved (and stripped) by `crate::modules` before the
                // checker ever runs; never present past this point.
                Item::Import(_) => {}
            }
        }

        let mut typed_items = Vec::new();
        for item in &module.items {
            match self.check_item(item) {
                Some(item) => typed_items.push(item),
                None => {}
            }
        }
        // Monomorphized copies of generic structs/enums/fns, instantiated on
        // demand while checking the items above (e.g. the first time
        // `Box<i32>` or `identity(5)` was used). Codegen doesn't care about
        // item order (it pre-registers every struct/enum layout in one pass
        // before emitting any function body, see `Codegen::emit`), so
        // appending them at the end is fine even though a mono item's own
        // *declaration* text never appears anywhere in the source module.
        typed_items.append(&mut self.mono_items);

        if self.errors.is_empty() {
            Ok(TypedModule { items: typed_items })
        } else {
            Err(self.errors_to_diagnostics())
        }
    }

    fn check_item(&mut self, item: &Item) -> Option<TypedItem> {
        match item {
            // A generic template has no concrete layout of its own -- only
            // its monomorphized instantiations (generated on demand into
            // `self.mono_items`, if any use ever instantiated it) are ever
            // emitted; see the two-phase collection in `check`.
            Item::Struct(s) if !s.type_params.is_empty() => None,
            Item::Struct(s) => Some(TypedItem::Struct(self.check_struct(s))),
            Item::Enum(e) if !e.type_params.is_empty() => None,
            Item::Enum(e) => Some(TypedItem::Enum(self.check_enum(e))),
            Item::Trait(t) => Some(TypedItem::Trait(TypedTraitDef {
                name: t.name.clone(),
                methods: t.methods.iter().filter_map(|sig| self.check_fn_sig(sig)).collect(),
                span: t.span,
            })),
            Item::Impl(impl_blk) => {
                let checked = self.check_impl(impl_blk)?;
                Some(TypedItem::Impl(checked))
            }
            Item::Fn(f) if !f.sig.type_params.is_empty() => None,
            Item::Fn(f) => {
                let checked = self.check_fn(f)?;
                Some(TypedItem::Fn(checked))
            }
            Item::Arena(a) => {
                let ty = self.resolve_type(&a.ty).unwrap_or(Ty::Named("unknown".into()));
                // If arena contains GenRef<T>, extract the inner type
                let element_ty = match &a.ty {
                    Type::Generic(name, args) if name == "GenRef" && !args.is_empty() => {
                        self.resolve_type(&args[0]).unwrap_or(Ty::Int)
                    }
                    _ => ty.clone(),
                };
                Some(TypedItem::Arena(TypedArenaDecl {
                    name: a.name.clone(),
                    ty: element_ty,
                    span: a.span,
                }))
            }
            // Desugared away in `check` before this point is ever reached.
            Item::Sequence(_) => None,
            // Resolved (and stripped) by `crate::modules` before the checker
            // ever runs; never present past this point.
            Item::Import(_) => None,
        }
    }

    fn check_enum(&mut self, e: &EnumDef) -> TypedEnumDef {
        TypedEnumDef {
            name: e.name.clone(),
            variants: e.variants.iter().map(|v| TypedEnumVariantDef {
                name: v.name.clone(),
                fields: v.fields.iter().map(|f| TypedEnumFieldDef {
                    name: f.name.clone(),
                    ty: self.resolve_type(&f.ty).unwrap_or(Ty::Named("unknown".into())),
                }).collect(),
                span: v.span,
            }).collect(),
            span: e.span,
        }
    }

    fn check_struct(&mut self, s: &StructDef) -> TypedStructDef {
        TypedStructDef {
            name: s.name.clone(),
            fields: s.fields.iter().map(|f| {
                let resolved = self.resolve_type(&f.ty).unwrap_or(Ty::Named("unknown".into()));
                TypedFieldDef {
                    is_mut: f.is_mut,
                    name: f.name.clone(),
                    ty: resolved,
                    default: f.default.as_ref().map(|e| self.check_expr_infer(e)),
                    decorators: f.decorators.clone(),
                    span: f.span,
                }
            }).collect(),
            span: s.span,
        }
    }

    fn check_impl(&mut self, impl_blk: &ImplBlock) -> Option<TypedImplBlock> {
        if let Some(trait_name) = &impl_blk.trait_name {
            if !self.traits.contains_key(trait_name) {
                let candidates: Vec<&str> = self.traits.keys().map(String::as_str).collect();
                match suggest(trait_name, candidates) {
                    Some(close) => self.error_note(
                        format!("undefined trait `{}`", trait_name),
                        impl_blk.span,
                        format!("did you mean `{}`?", close),
                    ),
                    None => self.error(format!("undefined trait `{}`", trait_name), impl_blk.span),
                }
                return None;
            }
        }
        if !self.structs.contains_key(&impl_blk.type_name) {
            let candidates: Vec<&str> = self.structs.keys().map(String::as_str).collect();
            match suggest(&impl_blk.type_name, candidates) {
                Some(close) => self.error_note(
                    format!("undefined type `{}`", impl_blk.type_name),
                    impl_blk.span,
                    format!("did you mean `{}`?", close),
                ),
                None => self.error(format!("undefined type `{}`", impl_blk.type_name), impl_blk.span),
            }
            return None;
        }
        let struct_ty = Ty::Named(impl_blk.type_name.clone());
        let methods: Vec<TypedFnDef> = impl_blk.methods.iter().filter_map(|m| self.check_fn_with_self_ty(m, &struct_ty)).collect();
        Some(TypedImplBlock {
            trait_name: impl_blk.trait_name.clone(),
            type_name: impl_blk.type_name.clone(),
            methods,
            span: impl_blk.span,
        })
    }

    fn check_fn(&mut self, f: &FnDef) -> Option<TypedFnDef> {
        self.check_fn_with_self_ty(f, &Ty::Named("infer".into()))
    }

    fn check_fn_with_self_ty(&mut self, f: &FnDef, self_ty: &Ty) -> Option<TypedFnDef> {
        // Defensive reset: `loop_depth` should already be balanced back to 0
        // by the previous item's checks, but resetting here guarantees one
        // function's loop nesting can never leak into the next.
        self.loop_depth = 0;
        let sig = self.check_fn_sig_with_self_ty(&f.sig, self_ty)?;
        let body = self.check_block(&f.body, &sig)?;
        self.check_frame_escapes(&body);
        Some(TypedFnDef { sig, body, span: f.span })
    }

    fn check_fn_sig(&mut self, sig: &FnSig) -> Option<TypedFnSig> {
        self.check_fn_sig_with_self_ty(sig, &Ty::Named("infer".into()))
    }

    fn check_fn_sig_with_self_ty(&mut self, sig: &FnSig, self_ty: &Ty) -> Option<TypedFnSig> {
        let params: Vec<TypedParam> = sig.params.iter().map(|p| self.check_param_with_self_ty(p, self_ty)).collect();
        Some(TypedFnSig {
            name: sig.name.clone(),
            params,
            ret: sig.ret.as_ref().and_then(|t| self.resolve_type(t)),
            span: sig.span,
        })
    }

    fn check_param_with_self_ty(&mut self, p: &Param, self_ty: &Ty) -> TypedParam {
        let ty = if p.is_self {
            self_ty.clone()
        } else {
            p.ty.as_ref().and_then(|t| self.resolve_type(t)).unwrap_or(Ty::Named("infer".into()))
        };
        TypedParam {
            is_self: p.is_self,
            is_mut: p.is_mut,
            name: p.name.clone(),
            ty,
            span: p.span,
        }
    }

    fn check_block(&mut self, block: &Block, fn_sig: &TypedFnSig) -> Option<TypedBlock> {
        let mut vars: HashMap<String, Ty> = HashMap::new();
        for p in &fn_sig.params {
            vars.insert(p.name.clone(), p.ty.clone());
        }
        Some(self.check_block_inner(block, &mut vars))
    }

    /// Type-check a block reusing an inherited variable table. Used for nested
    /// `if`/`while` bodies and `else` branches so bindings from the enclosing
    /// scope remain visible.
    fn check_block_inner(&mut self, block: &Block, vars: &mut HashMap<String, Ty>) -> TypedBlock {
        let mut stmts = Vec::new();
        for stmt in &block.stmts {
            if let Some(typed) = self.check_stmt(stmt, vars) {
                stmts.push(typed);
            }
        }
        TypedBlock { stmts, span: block.span }
    }

    /// Arenas whose declared element type is `ty`. Zero means "no backing
    /// arena", more than one means "ambiguous" -- both are errors at any
    /// `GenRef<T>` creation/dereference site (see `require_backing_arena`).
    fn arenas_of_elem_ty(&self, ty: &Ty) -> Vec<&String> {
        self.arenas.iter().filter(|(_, t)| *t == ty).map(|(n, _)| n).collect()
    }

    /// Validate that exactly one arena backs `GenRef<inner_ty>`, emitting a
    /// diagnostic otherwise. Codegen independently re-resolves the arena
    /// name from `inner_ty` (see `Codegen::arena_for_elem_ty`); this check
    /// only exists to turn a missing/ambiguous backing arena into a friendly
    /// type error instead of a defensive codegen-time failure.
    fn require_backing_arena(&mut self, inner_ty: &Ty, span: Span) {
        match self.arenas_of_elem_ty(inner_ty).len() {
            1 => {}
            0 => self.error(
                format!("`GenRef<{:?}>` has no backing arena -- declare `arena Name: {:?}`", inner_ty, inner_ty),
                span,
            ),
            _ => self.error(
                format!("`GenRef<{:?}>` is ambiguous: multiple arenas hold `{:?}`", inner_ty, inner_ty),
                span,
            ),
        }
    }

    /// Resolve a syntactic [`Type`] to a [`Ty`]. A `Type::Generic` naming a
    /// generic struct/enum template (`Box<i32>`) triggers monomorphization
    /// on demand (see `instantiate_struct`/`instantiate_enum`), memoized by
    /// mangled name so the same `(template, type args)` pair is only ever
    /// instantiated once. `Type` nodes belonging to the *inside* of a generic
    /// template's own declaration are never passed here directly -- they're
    /// substituted to concrete `Type`s first (see `subst_type`) before the
    /// resulting concrete copy is checked like any ordinary declaration.
    fn resolve_type(&mut self, ty: &Type) -> Option<Ty> {
        match ty {
            Type::Fn(params, ret) => {
                let param_tys: Vec<Ty> = params.iter().filter_map(|p| self.resolve_type(p)).collect();
                if param_tys.len() != params.len() {
                    return None;
                }
                let ret_ty = self.resolve_type(ret)?;
                Some(Ty::Closure(param_tys, Box::new(ret_ty)))
            }
            Type::Named(name) if self.enums.contains_key(name) => Some(Ty::Enum(name.clone())),
            Type::Named(name) if self.generic_structs.contains_key(name) || self.generic_enums.contains_key(name) => {
                self.error(format!("generic type `{}` used without type arguments", name), Span::dummy());
                None
            }
            Type::Named(name) => Some(match name.as_str() {
                "i32" | "i64" | "int" => Ty::Int,
                "f32" | "f64" | "float" => Ty::Float,
                "String" | "str" => Ty::Str,
                "bool" => Ty::Bool,
                "Vec2" => Ty::Vec2,
                "Vec3" => Ty::Vec3,
                "Vec4" => Ty::Vec4,
                "Mat4" => Ty::Mat4,
                _ => Ty::Named(name.clone()),
            }),
            Type::Generic(name, args) => {
                // Handle GenRef<T>
                if name == "GenRef" {
                    let inner = args.first().and_then(|a| self.resolve_type(a)).unwrap_or(Ty::Int);
                    return Some(Ty::GenRef(Box::new(inner)));
                }
                if name == "List" {
                    let inner = args.first().and_then(|a| self.resolve_type(a)).unwrap_or(Ty::Int);
                    return Some(Ty::List(Box::new(inner)));
                }
                if self.generic_structs.contains_key(name) {
                    let resolved_args: Vec<Ty> = args.iter().filter_map(|a| self.resolve_type(a)).collect();
                    if resolved_args.len() != args.len() {
                        return None;
                    }
                    return Some(Ty::Named(self.instantiate_struct(name, &resolved_args)));
                }
                if self.generic_enums.contains_key(name) {
                    let resolved_args: Vec<Ty> = args.iter().filter_map(|a| self.resolve_type(a)).collect();
                    if resolved_args.len() != args.len() {
                        return None;
                    }
                    return Some(Ty::Enum(self.instantiate_enum(name, &resolved_args)));
                }
                self.error(format!("unknown generic type `{}`", name), Span::dummy());
                None
            }
        }
    }

    /// Instantiate generic struct `template_name` with concrete `args`,
    /// memoized by mangled name (`Box__i32`) so repeated uses of the same
    /// `(template, args)` pair share one monomorphized copy. Registers the
    /// mangled name into `self.structs` *before* checking its (substituted)
    /// field types, so a self-referential field (e.g. through a `GenRef` to
    /// the same instantiation) resolves back to this same mangled name
    /// instead of recursing into another `instantiate_struct` call.
    fn instantiate_struct(&mut self, template_name: &str, args: &[Ty]) -> String {
        let mangled = mangle_generic(template_name, args);
        if self.structs.contains_key(&mangled) {
            return mangled;
        }
        let Some(template) = self.generic_structs.get(template_name).cloned() else {
            self.error(format!("undefined generic struct `{}`", template_name), Span::dummy());
            return mangled;
        };
        if template.type_params.len() != args.len() {
            self.error(
                format!("`{}` expects {} type argument(s), found {}", template_name, template.type_params.len(), args.len()),
                Span::dummy(),
            );
        }
        let subst: HashMap<String, Type> = template.type_params.iter().cloned().zip(args.iter().map(ty_to_type)).collect();
        let fields: Vec<FieldDef> = template.fields.iter().map(|f| FieldDef {
            is_mut: f.is_mut,
            name: f.name.clone(),
            ty: subst_type(&f.ty, &subst),
            default: f.default.as_ref().map(|e| subst_expr(e, &subst)),
            decorators: f.decorators.clone(),
            span: f.span,
        }).collect();
        let concrete = StructDef { name: mangled.clone(), type_params: Vec::new(), fields, span: template.span };
        self.structs.insert(mangled.clone(), concrete.clone());
        self.mono_struct_of.insert(mangled.clone(), (template_name.to_string(), args.to_vec()));
        let typed = self.check_struct(&concrete);
        self.mono_items.push(TypedItem::Struct(typed));
        mangled
    }

    /// Instantiate generic enum `template_name` with concrete `args`. Mirrors
    /// `instantiate_struct`; see its doc comment.
    fn instantiate_enum(&mut self, template_name: &str, args: &[Ty]) -> String {
        let mangled = mangle_generic(template_name, args);
        if self.enums.contains_key(&mangled) {
            return mangled;
        }
        let Some(template) = self.generic_enums.get(template_name).cloned() else {
            self.error(format!("undefined generic enum `{}`", template_name), Span::dummy());
            return mangled;
        };
        if template.type_params.len() != args.len() {
            self.error(
                format!("`{}` expects {} type argument(s), found {}", template_name, template.type_params.len(), args.len()),
                Span::dummy(),
            );
        }
        let subst: HashMap<String, Type> = template.type_params.iter().cloned().zip(args.iter().map(ty_to_type)).collect();
        let variants: Vec<EnumVariantDef> = template.variants.iter().map(|v| EnumVariantDef {
            name: v.name.clone(),
            fields: v.fields.iter().map(|f| EnumFieldDef { name: f.name.clone(), ty: subst_type(&f.ty, &subst) }).collect(),
            span: v.span,
        }).collect();
        let concrete = EnumDef { name: mangled.clone(), type_params: Vec::new(), variants, span: template.span };
        self.enums.insert(mangled.clone(), concrete.clone());
        self.mono_enum_of.insert(mangled.clone(), (template_name.to_string(), args.to_vec()));
        let typed = self.check_enum(&concrete);
        self.mono_items.push(TypedItem::Enum(typed));
        mangled
    }

    /// Instantiate generic function `template_name` with concrete `args`,
    /// returning its mangled name. Registers the mangled signature into
    /// `self.functions` *before* checking the (substituted) body, so a
    /// recursive call back to the same instantiation resolves to this same
    /// mangled name instead of instantiating forever.
    fn instantiate_fn(&mut self, template_name: &str, args: &[Ty]) -> String {
        let mangled = mangle_generic(template_name, args);
        if self.functions.contains_key(&mangled) {
            return mangled;
        }
        let Some(template) = self.generic_fns.get(template_name).cloned() else {
            self.error(format!("undefined generic function `{}`", template_name), Span::dummy());
            return mangled;
        };
        let subst: HashMap<String, Type> = template.sig.type_params.iter().cloned().zip(args.iter().map(ty_to_type)).collect();
        let sig = FnSig {
            name: mangled.clone(),
            type_params: Vec::new(),
            params: template.sig.params.iter().map(|p| Param {
                is_self: p.is_self,
                is_mut: p.is_mut,
                name: p.name.clone(),
                ty: p.ty.as_ref().map(|t| subst_type(t, &subst)),
                span: p.span,
            }).collect(),
            ret: template.sig.ret.as_ref().map(|t| subst_type(t, &subst)),
            span: template.sig.span,
        };
        let body = subst_block(&template.body, &subst);
        let concrete = FnDef { sig, body, span: template.span };
        let param_tys: Vec<Ty> = concrete.sig.params.iter().map(|p| {
            p.ty.as_ref().and_then(|t| self.resolve_type(t)).unwrap_or(Ty::Named("infer".into()))
        }).collect();
        let ret_ty = concrete.sig.ret.as_ref().and_then(|t| self.resolve_type(t));
        self.functions.insert(mangled.clone(), (param_tys, ret_ty));
        let Some(typed) = self.check_fn(&concrete) else { return mangled; };
        self.mono_items.push(TypedItem::Fn(typed));
        mangled
    }

    /// Unify a (possibly type-parameterized) declared syntactic type against
    /// a concrete inferred `Ty`, recording any type parameter it binds into
    /// `subst`. Used both to infer a generic function call's type arguments
    /// from its call-site arguments, and to infer a generic struct/enum
    /// construction's type arguments from its constructor arguments, when no
    /// explicit turbofish was given. The first binding found for a given
    /// parameter wins; later, conflicting bindings are silently ignored
    /// (this compiler does no cross-argument consistency check today).
    fn unify_ty(&self, param_ty: &Type, arg_ty: &Ty, type_params: &[String], subst: &mut HashMap<String, Ty>) {
        match param_ty {
            Type::Named(n) if type_params.iter().any(|p| p == n) => {
                subst.entry(n.clone()).or_insert_with(|| arg_ty.clone());
            }
            Type::Named(_) => {}
            // A closure-typed generic parameter has nothing to unify against
            // today (no generic template's field/param declares one in a
            // way that binds a type parameter); a no-op, like `Type::Named`
            // naming a non-type-parameter type above.
            Type::Fn(..) => {}
            Type::Generic(name, args) => {
                if name == "GenRef" {
                    if let (Some(a0), Ty::GenRef(inner)) = (args.first(), arg_ty) {
                        self.unify_ty(a0, inner, type_params, subst);
                    }
                    return;
                }
                if name == "List" {
                    if let (Some(a0), Ty::List(inner)) = (args.first(), arg_ty) {
                        self.unify_ty(a0, inner, type_params, subst);
                    }
                    return;
                }
                let instantiated = match arg_ty {
                    Ty::Named(mangled) => self.mono_struct_of.get(mangled),
                    Ty::Enum(mangled) => self.mono_enum_of.get(mangled),
                    _ => None,
                };
                if let Some((tmpl, ty_args)) = instantiated {
                    if tmpl == name {
                        for (pa, ta) in args.iter().zip(ty_args.iter()) {
                            self.unify_ty(pa, ta, type_params, subst);
                        }
                    }
                }
            }
        }
    }

    fn error(&mut self, msg: impl Into<String>, span: Span) {
        self.errors.push(TypeError { message: msg.into(), span, note: None });
    }

    /// Like [`Checker::error`], but attaches a secondary "did you mean `x`?"
    /// style hint rendered as a trailing note.
    fn error_note(&mut self, msg: impl Into<String>, span: Span, note: impl Into<String>) {
        self.errors.push(TypeError { message: msg.into(), span, note: Some(note.into()) });
    }

    fn errors_to_diagnostics(&self) -> Vec<Diagnostic> {
        self.errors
            .iter()
            .map(|e| match &e.note {
                Some(note) => Diagnostic::error_with_note(&e.message, e.span, note.clone()),
                None => Diagnostic::error(&e.message, e.span),
            })
            .collect()
    }
}

// ===== Generics: monomorphization support ===================================
//
// User-defined generics (`struct Box<T>: ...`, `enum Option<T>: ...`, `fn
// identity<T>(...)`) are implemented by monomorphization: a generic template
// is never itself checked or emitted (see `Checker::check_item`'s early
// `None` for a non-empty `type_params`), only concrete instantiations
// produced on demand by substituting each type parameter for a concrete
// `Type` throughout a syntactic copy of the declaration (fields/params/
// return type/body), then checking that copy exactly like an ordinary
// hand-written concrete declaration -- see `Checker::instantiate_struct`/
// `instantiate_enum`/`instantiate_fn`. Every instantiation is named by
// mangling the template name with its concrete type arguments (`Box__i32`),
// which doubles as memoization: the same `(template, args)` pair always
// produces the same name, so it's only ever instantiated once.

/// A resolved `Ty`'s name fragment for mangled instantiation names --
/// `mangle_generic("Box", [Ty::Int])` produces `"Box__i32"`.
fn mangle_ty(ty: &Ty) -> String {
    match ty {
        Ty::Int => "i32".into(),
        Ty::Float => "f32".into(),
        Ty::Str => "str".into(),
        Ty::Bool => "bool".into(),
        Ty::Vec2 => "Vec2".into(),
        Ty::Vec3 => "Vec3".into(),
        Ty::Vec4 => "Vec4".into(),
        Ty::Mat4 => "Mat4".into(),
        Ty::Named(n) => n.clone(),
        Ty::Enum(n) => n.clone(),
        Ty::GenRef(inner) => format!("GenRef_{}", mangle_ty(inner)),
        Ty::List(inner) => format!("List_{}", mangle_ty(inner)),
        // Closures are never used as a generic type argument today (no
        // syntax constructs a generic struct/enum/fn call site with a
        // closure-typed turbofish argument); this arm exists purely for
        // match exhaustiveness.
        Ty::Closure(params, ret) => {
            let param_str: Vec<String> = params.iter().map(mangle_ty).collect();
            format!("Fn_{}_{}", param_str.join("_"), mangle_ty(ret))
        }
    }
}

/// The mangled name for `template` instantiated with `args`, e.g.
/// `mangle_generic("Pair", [Ty::Int, Ty::Str])` -> `"Pair__i32__str"`. Reuses
/// the `__` separator `crate::modules` already uses for `alias__name`
/// mangling, so both stay within one "double underscore means generated
/// name" convention.
fn mangle_generic(template: &str, args: &[Ty]) -> String {
    let mut s = template.to_string();
    for a in args {
        s.push_str("__");
        s.push_str(&mangle_ty(a));
    }
    s
}

/// Convert a resolved `Ty` back to a syntactic `Type`, so a generic
/// template's type parameters (bound to concrete `Ty`s, e.g. by unifying
/// call-site argument types) can be substituted into the template's own
/// syntactic field/param/return `Type` nodes via `subst_type`.
fn ty_to_type(ty: &Ty) -> Type {
    match ty {
        Ty::Int => Type::Named("i32".into()),
        Ty::Float => Type::Named("f32".into()),
        Ty::Str => Type::Named("str".into()),
        Ty::Bool => Type::Named("bool".into()),
        Ty::Vec2 => Type::Named("Vec2".into()),
        Ty::Vec3 => Type::Named("Vec3".into()),
        Ty::Vec4 => Type::Named("Vec4".into()),
        Ty::Mat4 => Type::Named("Mat4".into()),
        Ty::Named(n) => Type::Named(n.clone()),
        Ty::Enum(n) => Type::Named(n.clone()),
        Ty::GenRef(inner) => Type::Generic("GenRef".into(), vec![ty_to_type(inner)]),
        Ty::List(inner) => Type::Generic("List".into(), vec![ty_to_type(inner)]),
        Ty::Closure(params, ret) => Type::Fn(params.iter().map(ty_to_type).collect(), Box::new(ty_to_type(ret))),
    }
}

/// Replace every type parameter named in `subst` with its bound concrete
/// `Type` throughout a syntactic type, recursing into `Type::Generic`'s own
/// arguments (e.g. `GenRef<T>` -> `GenRef<i32>`). Names not in `subst`
/// (concrete types, or an outer generic's own type constructor name) pass
/// through unchanged.
fn subst_type(ty: &Type, subst: &HashMap<String, Type>) -> Type {
    match ty {
        Type::Named(n) => subst.get(n).cloned().unwrap_or_else(|| ty.clone()),
        Type::Generic(n, args) => Type::Generic(n.clone(), args.iter().map(|a| subst_type(a, subst)).collect()),
        Type::Fn(params, ret) => Type::Fn(params.iter().map(|p| subst_type(p, subst)).collect(), Box::new(subst_type(ret, subst))),
    }
}

/// Deep-clone `block`, substituting every embedded `Type` node (`let`
/// annotations, `GenRef<T>(..)` type args, generic construction turbofish)
/// via `subst_type`. Used to produce a fully concrete copy of a generic
/// function's body before checking it like an ordinary function.
fn subst_block(block: &Block, subst: &HashMap<String, Type>) -> Block {
    Block { stmts: block.stmts.iter().map(|s| subst_stmt(s, subst)).collect(), span: block.span }
}

fn subst_stmt(stmt: &Stmt, subst: &HashMap<String, Type>) -> Stmt {
    match stmt {
        Stmt::Let { is_mut, name, ty, value, span } => Stmt::Let {
            is_mut: *is_mut,
            name: name.clone(),
            ty: ty.as_ref().map(|t| subst_type(t, subst)),
            value: subst_expr(value, subst),
            span: *span,
        },
        Stmt::Assign { target, op, value, span } => Stmt::Assign {
            target: subst_expr(target, subst),
            op: *op,
            value: subst_expr(value, subst),
            span: *span,
        },
        Stmt::Return { value, span } => Stmt::Return { value: value.as_ref().map(|v| subst_expr(v, subst)), span: *span },
        Stmt::Expr(e) => Stmt::Expr(subst_expr(e, subst)),
        Stmt::If { cond, then_block, else_block, span } => Stmt::If {
            cond: subst_expr(cond, subst),
            then_block: subst_block(then_block, subst),
            else_block: else_block.as_ref().map(|b| subst_block(b, subst)),
            span: *span,
        },
        Stmt::While { cond, body, else_block, span } => Stmt::While {
            cond: subst_expr(cond, subst),
            body: subst_block(body, subst),
            else_block: else_block.as_ref().map(|b| subst_block(b, subst)),
            span: *span,
        },
        Stmt::For { var, start, end, body, span } => Stmt::For {
            var: var.clone(),
            start: subst_expr(start, subst),
            end: subst_expr(end, subst),
            body: subst_block(body, subst),
            span: *span,
        },
        Stmt::Break { span } => Stmt::Break { span: *span },
        Stmt::Continue { span } => Stmt::Continue { span: *span },
        Stmt::Frame { body, span } => Stmt::Frame { body: subst_block(body, subst), span: *span },
        Stmt::Par { var, arena, body, span } => {
            Stmt::Par { var: var.clone(), arena: arena.clone(), body: subst_block(body, subst), span: *span }
        }
        Stmt::Yield { span } => Stmt::Yield { span: *span },
        Stmt::Spawn { arena, args, span } => Stmt::Spawn {
            arena: arena.clone(),
            args: args.iter().map(|a| subst_expr(a, subst)).collect(),
            span: *span,
        },
        Stmt::Despawn { arena, index, span } => {
            Stmt::Despawn { arena: arena.clone(), index: subst_expr(index, subst), span: *span }
        }
    }
}

fn subst_expr(expr: &Expr, subst: &HashMap<String, Type>) -> Expr {
    match expr {
        Expr::Int(..) | Expr::Float(..) | Expr::Str(..) | Expr::Bool(..) | Expr::Ident(..) | Expr::SelfExpr(..) => expr.clone(),
        Expr::FStr(parts, span) => Expr::FStr(
            parts.iter().map(|p| match p {
                FStrExpr::Literal(s) => FStrExpr::Literal(s.clone()),
                FStrExpr::Expr(inner) => FStrExpr::Expr(Box::new(subst_expr(inner, subst))),
            }).collect(),
            *span,
        ),
        Expr::Field { base, field, span } => Expr::Field { base: Box::new(subst_expr(base, subst)), field: field.clone(), span: *span },
        Expr::Call { callee, args, span } => Expr::Call {
            callee: Box::new(subst_expr(callee, subst)),
            args: args.iter().map(|a| subst_expr(a, subst)).collect(),
            span: *span,
        },
        Expr::Binary { op, lhs, rhs, span } => Expr::Binary {
            op: *op,
            lhs: Box::new(subst_expr(lhs, subst)),
            rhs: Box::new(subst_expr(rhs, subst)),
            span: *span,
        },
        Expr::Unary { op, operand, span } => Expr::Unary { op: *op, operand: Box::new(subst_expr(operand, subst)), span: *span },
        Expr::Match { scrutinee, arms, span } => Expr::Match {
            scrutinee: Box::new(subst_expr(scrutinee, subst)),
            arms: arms.iter().map(|a| MatchArm { pattern: a.pattern.clone(), body: subst_block(&a.body, subst), span: a.span }).collect(),
            span: *span,
        },
        Expr::StructLit { name, type_args, args, span } => Expr::StructLit {
            name: name.clone(),
            type_args: type_args.iter().map(|t| subst_type(t, subst)).collect(),
            args: args.iter().map(|a| subst_expr(a, subst)).collect(),
            span: *span,
        },
        Expr::If { cond, then_block, else_block, span } => Expr::If {
            cond: Box::new(subst_expr(cond, subst)),
            then_block: subst_block(then_block, subst),
            else_block: else_block.as_ref().map(|b| subst_block(b, subst)),
            span: *span,
        },
        Expr::GenRefCreate { inner_ty, value, span } => {
            Expr::GenRefCreate { inner_ty: subst_type(inner_ty, subst), value: Box::new(subst_expr(value, subst)), span: *span }
        }
        Expr::GenRefIndex { base, index, span } => {
            Expr::GenRefIndex { base: Box::new(subst_expr(base, subst)), index: Box::new(subst_expr(index, subst)), span: *span }
        }
        Expr::EnumVariant { enum_name, type_args, variant, args, span } => Expr::EnumVariant {
            enum_name: enum_name.clone(),
            type_args: type_args.iter().map(|t| subst_type(t, subst)).collect(),
            variant: variant.clone(),
            args: args.iter().map(|a| subst_expr(a, subst)).collect(),
            span: *span,
        },
        Expr::Lambda { params, ret, body, span } => Expr::Lambda {
            params: params.iter().map(|p| Param {
                is_self: p.is_self,
                is_mut: p.is_mut,
                name: p.name.clone(),
                ty: p.ty.as_ref().map(|t| subst_type(t, subst)),
                span: p.span,
            }).collect(),
            ret: ret.as_ref().map(|t| subst_type(t, subst)),
            body: subst_block(body, subst),
            span: *span,
        },
        Expr::ListLit(elems, span) => Expr::ListLit(elems.iter().map(|e| subst_expr(e, subst)).collect(), *span),
    }
}

/// The root identifier a place expression (`x`, `x.a.b`, `self.a`) writes
/// through, or `None` if it isn't a simple identifier/field chain.
fn root_ident(expr: &TypedExpr) -> Option<String> {
    match expr {
        TypedExpr::Ident { name, .. } => Some(name.clone()),
        TypedExpr::SelfExpr(..) => Some("self".to_string()),
        TypedExpr::Field { base, .. } => root_ident(base),
        _ => None,
    }
}
