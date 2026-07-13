//! The typed tree (HIR) `Checker::check` produces: every node from
//! [`crate::ast`]'s surface syntax mirrored with a resolved [`super::Ty`]
//! attached to each expression.

use crate::ast::*;
use crate::diagnostics::Span;

use super::Ty;

/// A typed arena declaration.
#[derive(Clone, Debug)]
pub struct TypedArenaDecl {
    pub name: String,
    pub ty: Ty,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedModule {
    pub items: Vec<TypedItem>,
}

#[derive(Clone, Debug)]
pub enum TypedItem {
    Struct(TypedStructDef),
    Trait(TypedTraitDef),
    Impl(TypedImplBlock),
    Fn(TypedFnDef),
    Arena(TypedArenaDecl),
    Enum(TypedEnumDef),
    /// A checked `extern "C" fn` declaration -- signature only, no body
    /// (see `crate::ast::ExternFnDecl`). `codegen` lowers this to a bare
    /// `declare` rather than a `define` (see `Codegen::emit`).
    ExternFn(TypedFnSig),
}

/// A type-checked enum declaration.
#[derive(Clone, Debug)]
pub struct TypedEnumDef {
    pub name: String,
    pub variants: Vec<TypedEnumVariantDef>,
    pub span: Span,
}

/// A type-checked enum variant, with its payload fields (if any) resolved.
#[derive(Clone, Debug)]
pub struct TypedEnumVariantDef {
    pub name: String,
    pub fields: Vec<TypedEnumFieldDef>,
    pub span: Span,
}

/// A type-checked enum variant payload field.
#[derive(Clone, Debug)]
pub struct TypedEnumFieldDef {
    pub name: String,
    pub ty: Ty,
}

#[derive(Clone, Debug)]
pub struct TypedStructDef {
    pub name: String,
    pub fields: Vec<TypedFieldDef>,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedFieldDef {
    pub is_mut: bool,
    pub name: String,
    pub ty: Ty,
    pub default: Option<TypedExpr>,
    pub decorators: Vec<String>,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedTraitDef {
    pub name: String,
    pub methods: Vec<TypedFnSig>,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedImplBlock {
    pub trait_name: Option<String>,
    pub type_name: String,
    pub methods: Vec<TypedFnDef>,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedFnSig {
    pub name: String,
    pub params: Vec<TypedParam>,
    pub ret: Option<Ty>,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedFnDef {
    pub sig: TypedFnSig,
    pub body: TypedBlock,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedParam {
    pub is_self: bool,
    pub is_mut: bool,
    pub name: String,
    pub ty: Ty,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedBlock {
    pub stmts: Vec<TypedStmt>,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub enum TypedStmt {
    Let { is_mut: bool, name: String, ty: Ty, value: TypedExpr, span: Span },
    Assign { target: TypedExpr, op: AssignOp, value: TypedExpr, span: Span },
    Return { value: Option<TypedExpr>, span: Span },
    Expr(TypedExpr),
    If {
        cond: TypedExpr,
        then_block: TypedBlock,
        else_block: Option<TypedBlock>,
        span: Span,
    },
    While {
        cond: TypedExpr,
        then_block: TypedBlock,
        else_block: Option<TypedBlock>,
        span: Span,
    },
    /// `for var in start..end: <body>` - see [`crate::ast::Stmt::For`].
    For {
        var: String,
        start: TypedExpr,
        end: TypedExpr,
        body: TypedBlock,
        span: Span,
    },
    /// `break` - see [`crate::ast::Stmt::Break`].
    Break { span: Span },
    /// `continue` - see [`crate::ast::Stmt::Continue`].
    Continue { span: Span },
    Frame {
        body: TypedBlock,
        span: Span,
    },
    /// `par`/`swarm item in ArenaName: <body>` - see [`crate::ast::Stmt::Par`].
    Par {
        var: String,
        elem_ty: Ty,
        arena: String,
        body: TypedBlock,
        span: Span,
    },
    /// `spawn ArenaName(args...)` - see [`crate::ast::Stmt::Spawn`]. `elem`
    /// is the constructed element (a `StructLit`); codegen only has to
    /// append it to the arena's backing array and bump `count`.
    Spawn {
        arena: String,
        elem: TypedExpr,
        span: Span,
    },
    /// `despawn ArenaName[index]` - see [`crate::ast::Stmt::Despawn`].
    Despawn {
        arena: String,
        index: TypedExpr,
        span: Span,
    },
}

/// A type-checked f-string component.
#[derive(Clone, Debug)]
pub enum TypedFStrExpr {
    Literal(String),
    Expr(Box<TypedExpr>),
}

/// A type-checked expression with its resolved type attached.
/// Literal variants carry their original value for codegen.
#[derive(Clone, Debug)]
pub enum TypedExpr {
    Int(i64, Ty, Span),
    Float(f64, Ty, Span),
    Str(String, Ty, Span),
    Bool(bool, Ty, Span),
    Ident { name: String, ty: Ty, span: Span },
    SelfExpr(Ty, Span),
    Field { base: Box<TypedExpr>, field: String, ty: Ty, span: Span },
    Call { callee: Box<TypedExpr>, args: Vec<TypedExpr>, ty: Ty, span: Span },
    Binary { op: BinOp, lhs: Box<TypedExpr>, rhs: Box<TypedExpr>, ty: Ty, span: Span },
    Unary { op: UnOp, operand: Box<TypedExpr>, ty: Ty, span: Span },
    Match { scrutinee: Box<TypedExpr>, arms: Vec<TypedMatchArm>, ty: Ty, span: Span },
    StructLit { name: String, args: Vec<TypedExpr>, ty: Ty, span: Span },
    FStr(Vec<TypedFStrExpr>, Ty, Span),
    If {
        cond: Box<TypedExpr>,
        then_block: TypedBlock,
        else_block: Option<TypedBlock>,
        ty: Ty,
        span: Span,
    },
    GenRefCreate { inner_ty: Ty, value: Box<TypedExpr>, span: Span },
    GenRefIndex { base: Box<TypedExpr>, index: Box<TypedExpr>, ty: Ty, span: Span },
    /// An enum variant literal: `EnumName::Variant`, see [`crate::ast::Expr::EnumVariant`].
    EnumVariant { enum_name: String, variant: String, args: Vec<TypedExpr>, ty: Ty, span: Span },
    /// A lambda/closure literal, see [`crate::ast::Expr::Lambda`]. `ty` is
    /// always a `Ty::Closure(param_tys, ret_ty)`.
    Closure { params: Vec<TypedParam>, body: TypedBlock, ty: Ty, span: Span },
    /// `List<T>()` -- an empty list construction, see
    /// `Checker::infer_list_new`.
    ListNew { elem_ty: Ty, span: Span },
    /// A non-empty list literal `[e1, e2, ...]`, see
    /// [`crate::ast::Expr::ListLit`].
    ListLit { elems: Vec<TypedExpr>, elem_ty: Ty, span: Span },
    /// `list[idx]`: a bounds-checked `List<T>` element read. `ty` is the
    /// element type `T`. See [`crate::ast::Expr::GenRefIndex`]'s doc comment
    /// for why this shares that AST node with `GenRef<T>` dereferencing.
    ListIndex { base: Box<TypedExpr>, index: Box<TypedExpr>, ty: Ty, span: Span },
    /// `list.push(v)` / `list.pop()` / `list.len()`, see
    /// `Checker::infer_list_method`.
    ListMethod { base: Box<TypedExpr>, method: ListMethod, args: Vec<TypedExpr>, ty: Ty, span: Span },
    /// `s[idx]`: a bounds-checked `str` byte read, yielding the byte's value
    /// (0-255) as an `i32` -- Star has no dedicated `char` type, so this is
    /// the C-like "index a string, get a byte" convention rather than
    /// Python's "index a string, get a length-1 string". `ty` is always
    /// `Ty::Int`; carried as a field anyway (rather than hardcoded in
    /// `into_ty`) purely for uniformity with every other index/method node
    /// here. See `Codegen::emit_str_index`'s doc comment for the null/OOB
    /// convention (0, matching `ListIndex`'s zero-value read). Read-only:
    /// `str` has no mutating methods, so unlike `ListIndex`/`GenRefIndex`
    /// this never appears as an assignment target (rejected in
    /// `Checker::check_stmt`'s `Stmt::Assign` arm).
    StrIndex { base: Box<TypedExpr>, index: Box<TypedExpr>, ty: Ty, span: Span },
    Error(Ty),
}

/// The builtin `List<T>` methods -- see `TypedExpr::ListMethod`.
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum ListMethod {
    /// `list.push(v)` -- appends `v`, growing the backing buffer if needed.
    Push,
    /// `list.pop()` -- removes and returns the last element, or the element
    /// type's zero value if the list is empty (mirrors `GenRef`'s "safe
    /// null equivalent" convention rather than a `Result`/`Option` type).
    Pop,
    /// `list.len()` -- the current element count as an `i32`.
    Len,
}

impl TypedExpr {
    pub fn into_ty(self) -> Ty {
        match self {
            TypedExpr::Int(_, ty, _) | TypedExpr::Float(_, ty, _) | TypedExpr::Str(_, ty, _) | TypedExpr::Bool(_, ty, _)
            | TypedExpr::Field { ty, .. } | TypedExpr::Call { ty, .. } | TypedExpr::Binary { ty, .. }
            | TypedExpr::Unary { ty, .. } | TypedExpr::Match { ty, .. } | TypedExpr::StructLit { ty, .. }
            | TypedExpr::FStr(_, ty, _) | TypedExpr::GenRefIndex { ty, .. } | TypedExpr::EnumVariant { ty, .. }
            | TypedExpr::Closure { ty, .. } | TypedExpr::ListIndex { ty, .. } | TypedExpr::ListMethod { ty, .. }
            | TypedExpr::StrIndex { ty, .. } | TypedExpr::Error(ty) => ty,
            TypedExpr::Ident { ty, .. } => ty,
            TypedExpr::SelfExpr(ty, _) => ty,
            TypedExpr::If { ty, .. } => ty.clone(),
            TypedExpr::GenRefCreate { inner_ty, .. } => Ty::GenRef(Box::new(inner_ty)),
            TypedExpr::ListNew { elem_ty, .. } => Ty::List(Box::new(elem_ty)),
            TypedExpr::ListLit { elem_ty, .. } => Ty::List(Box::new(elem_ty)),
        }
    }

    pub fn span(&self) -> Span {
        match self {
            TypedExpr::Int(_, _, s) | TypedExpr::Float(_, _, s) | TypedExpr::Str(_, _, s) | TypedExpr::Bool(_, _, s)
            | TypedExpr::FStr(_, _, s) => *s,
            TypedExpr::Ident { span, .. } | TypedExpr::Field { span, .. } | TypedExpr::Call { span, .. }
            | TypedExpr::Binary { span, .. } | TypedExpr::Unary { span, .. } | TypedExpr::Match { span, .. }
            | TypedExpr::StructLit { span, .. } | TypedExpr::If { span, .. } | TypedExpr::GenRefCreate { span, .. }
            | TypedExpr::GenRefIndex { span, .. } | TypedExpr::EnumVariant { span, .. }
            | TypedExpr::Closure { span, .. } | TypedExpr::ListNew { span, .. } | TypedExpr::ListLit { span, .. }
            | TypedExpr::ListIndex { span, .. } | TypedExpr::ListMethod { span, .. }
            | TypedExpr::StrIndex { span, .. } => *span,
            TypedExpr::SelfExpr(_, s) => *s,
            TypedExpr::Error(_) => Span::dummy(),
        }
    }
}

#[derive(Clone, Debug)]
pub struct TypedMatchArm {
    pub pattern: Pattern,
    pub body: TypedBlock,
    pub ty: Ty,
    pub span: Span,
}
