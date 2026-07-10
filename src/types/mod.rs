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
    /// Function signatures: maps function name -> (param_tys, ret_ty)
    functions: HashMap<String, (Vec<Ty>, Option<Ty>)>,
    errors: Vec<TypeError>,
}

impl Checker {
    pub fn new() -> Self {
        Self {
            structs: HashMap::new(),
            traits: HashMap::new(),
            arenas: HashMap::new(),
            functions: HashMap::new(),
            errors: Vec::new(),
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

        // First pass: collect all declarations
        for item in &module.items {
            match item {
                Item::Struct(s) => { self.structs.insert(s.name.clone(), s.clone()); }
                Item::Trait(t) => { self.traits.insert(t.name.clone(), t.clone()); }
                Item::Arena(a) => {
                    let ty = self.resolve_type(&a.ty).unwrap_or(Ty::Named("unknown".into()));
                    self.arenas.insert(a.name.clone(), ty);
                }
                Item::Fn(f) => {
                    let param_tys: Vec<Ty> = f.sig.params.iter().map(|p| {
                        p.ty.as_ref().and_then(|t| self.resolve_type(t)).unwrap_or(Ty::Named("infer".into()))
                    }).collect();
                    let ret_ty = f.sig.ret.as_ref().and_then(|t| self.resolve_type(t));
                    self.functions.insert(f.sig.name.clone(), (param_tys, ret_ty));
                }
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
            }
        }

        let mut typed_items = Vec::new();
        for item in &module.items {
            match self.check_item(item) {
                Some(item) => typed_items.push(item),
                None => {}
            }
        }

        if self.errors.is_empty() {
            Ok(TypedModule { items: typed_items })
        } else {
            Err(self.errors_to_diagnostics())
        }
    }

    fn check_item(&mut self, item: &Item) -> Option<TypedItem> {
        match item {
            Item::Struct(s) => Some(TypedItem::Struct(self.check_struct(s))),
            Item::Trait(t) => Some(TypedItem::Trait(TypedTraitDef {
                name: t.name.clone(),
                methods: t.methods.iter().filter_map(|sig| self.check_fn_sig(sig)).collect(),
                span: t.span,
            })),
            Item::Impl(impl_blk) => {
                let checked = self.check_impl(impl_blk)?;
                Some(TypedItem::Impl(checked))
            }
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
        let sig = self.check_fn_sig_with_self_ty(&f.sig, self_ty)?;
        let body = self.check_block(&f.body, &sig)?;
        self.check_frame_escapes(&body);
        Some(TypedFnDef { sig, body, span: f.span })
    }

    fn check_fn_sig(&self, sig: &FnSig) -> Option<TypedFnSig> {
        self.check_fn_sig_with_self_ty(sig, &Ty::Named("infer".into()))
    }

    fn check_fn_sig_with_self_ty(&self, sig: &FnSig, self_ty: &Ty) -> Option<TypedFnSig> {
        Some(TypedFnSig {
            name: sig.name.clone(),
            params: sig.params.iter().map(|p| self.check_param_with_self_ty(p, self_ty)).collect(),
            ret: sig.ret.as_ref().and_then(|t| self.resolve_type(t)),
            span: sig.span,
        })
    }

    fn check_param_with_self_ty(&self, p: &Param, self_ty: &Ty) -> TypedParam {
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

    fn resolve_type(&self, ty: &Type) -> Option<Ty> {
        match ty {
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
                None
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
