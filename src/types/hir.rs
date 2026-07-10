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
    Error(Ty),
}

impl TypedExpr {
    pub fn into_ty(self) -> Ty {
        match self {
            TypedExpr::Int(_, ty, _) | TypedExpr::Float(_, ty, _) | TypedExpr::Str(_, ty, _) | TypedExpr::Bool(_, ty, _)
            | TypedExpr::Field { ty, .. } | TypedExpr::Call { ty, .. } | TypedExpr::Binary { ty, .. }
            | TypedExpr::Unary { ty, .. } | TypedExpr::Match { ty, .. } | TypedExpr::StructLit { ty, .. }
            | TypedExpr::FStr(_, ty, _) | TypedExpr::GenRefIndex { ty, .. } | TypedExpr::Error(ty) => ty,
            TypedExpr::Ident { ty, .. } => ty,
            TypedExpr::SelfExpr(ty, _) => ty,
            TypedExpr::If { ty, .. } => ty.clone(),
            TypedExpr::GenRefCreate { inner_ty, .. } => Ty::GenRef(Box::new(inner_ty)),
        }
    }

    pub fn span(&self) -> Span {
        match self {
            TypedExpr::Int(_, _, s) | TypedExpr::Float(_, _, s) | TypedExpr::Str(_, _, s) | TypedExpr::Bool(_, _, s)
            | TypedExpr::FStr(_, _, s) => *s,
            TypedExpr::Ident { span, .. } | TypedExpr::Field { span, .. } | TypedExpr::Call { span, .. }
            | TypedExpr::Binary { span, .. } | TypedExpr::Unary { span, .. } | TypedExpr::Match { span, .. }
            | TypedExpr::StructLit { span, .. } | TypedExpr::If { span, .. } | TypedExpr::GenRefCreate { span, .. }
            | TypedExpr::GenRefIndex { span, .. } => *span,
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
