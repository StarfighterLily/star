//! Abstract syntax tree for Star.
//!
//! The AST mirrors the surface syntax closely; desugaring and type information
//! are added in later stages (resolver, type checker, HIR). Every node carries
//! a [`Span`] so diagnostics can point back at the source.

use crate::diagnostics::Span;

/// A complete parsed source file.
#[derive(Clone, Debug)]
pub struct Module {
    pub items: Vec<Item>,
}

/// A top-level declaration.
#[derive(Clone, Debug)]
pub enum Item {
    Struct(StructDef),
    Trait(TraitDef),
    Impl(ImplBlock),
    Fn(FnDef),
}

/// A data structure: named, typed fields with optional defaults.
#[derive(Clone, Debug)]
pub struct StructDef {
    pub name: String,
    pub fields: Vec<FieldDef>,
    pub span: Span,
}

/// A single struct field.
#[derive(Clone, Debug)]
pub struct FieldDef {
    /// `mut` fields may be reassigned after construction.
    pub is_mut: bool,
    pub name: String,
    pub ty: Type,
    /// Optional default initializer expression.
    pub default: Option<Expr>,
    /// Reflection decorators applied to this field (`@export`, `@tweakable`).
    pub decorators: Vec<String>,
    pub span: Span,
}

/// A trait: a set of required method signatures.
#[derive(Clone, Debug)]
pub struct TraitDef {
    pub name: String,
    pub methods: Vec<FnSig>,
    pub span: Span,
}

/// An `impl Trait for Type` or inherent `impl Type` block.
#[derive(Clone, Debug)]
pub struct ImplBlock {
    /// The implemented trait, if any (`None` for inherent impls).
    pub trait_name: Option<String>,
    /// The type the impl is attached to.
    pub type_name: String,
    pub methods: Vec<FnDef>,
    pub span: Span,
}

/// A function signature without a body (used in traits).
#[derive(Clone, Debug)]
pub struct FnSig {
    pub name: String,
    pub params: Vec<Param>,
    pub ret: Option<Type>,
    pub span: Span,
}

/// A function definition with a body.
#[derive(Clone, Debug)]
pub struct FnDef {
    pub sig: FnSig,
    pub body: Block,
    pub span: Span,
}

/// A function parameter.
#[derive(Clone, Debug)]
pub struct Param {
    /// True for the `self`/`mut self` receiver parameter.
    pub is_self: bool,
    /// True when the parameter (or receiver) is mutable.
    pub is_mut: bool,
    pub name: String,
    /// Declared type; `None` for `self` receivers.
    pub ty: Option<Type>,
    pub span: Span,
}

/// A syntactic type reference.
#[derive(Clone, Debug, PartialEq)]
pub enum Type {
    /// A named type such as `i32`, `String`, or `Player`.
    Named(String),
    /// A generic application like `Vec<i32>` (reserved for later use).
    Generic(String, Vec<Type>),
}

/// An indented block of statements.
#[derive(Clone, Debug)]
pub struct Block {
    pub stmts: Vec<Stmt>,
    pub span: Span,
}

/// A statement within a block.
#[derive(Clone, Debug)]
pub enum Stmt {
    /// `let [mut] name [: Type] = expr`.
    Let {
        is_mut: bool,
        name: String,
        ty: Option<Type>,
        value: Expr,
        span: Span,
    },
    /// An assignment such as `self.health -= amount`.
    Assign {
        target: Expr,
        op: AssignOp,
        value: Expr,
        span: Span,
    },
    /// `return [expr]`.
    Return { value: Option<Expr>, span: Span },
    /// A bare expression used for its side effects.
    Expr(Expr),
    /// `if cond: <block> [else: <block>]`.
    If {
        cond: Expr,
        then_block: Block,
        else_block: Option<Block>,
        span: Span,
    },
    /// `while cond: <block> [else: <block>]`.
    While {
        cond: Expr,
        body: Block,
        else_block: Option<Block>,
        span: Span,
    },
}

/// Assignment operators, including compound forms.
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum AssignOp {
    Eq,
    Add,
    Sub,
    Mul,
    Div,
}

/// An expression node.
#[derive(Clone, Debug)]
pub enum Expr {
    Int(i64, Span),
    Float(f64, Span),
    Str(String, Span),
    Bool(bool, Span),
    /// An f-string lowered to a list of literal/expression parts.
    FStr(Vec<FStrExpr>, Span),
    /// A variable or `self` reference.
    Ident(String, Span),
    /// The `self` receiver.
    SelfExpr(Span),
    /// Field access `obj.field`.
    Field {
        base: Box<Expr>,
        field: String,
        span: Span,
    },
    /// A function or method call.
    Call {
        callee: Box<Expr>,
        args: Vec<Expr>,
        span: Span,
    },
    /// A binary operation.
    Binary {
        op: BinOp,
        lhs: Box<Expr>,
        rhs: Box<Expr>,
        span: Span,
    },
    /// A unary operation such as `-x` or `!flag`.
    Unary {
        op: UnOp,
        operand: Box<Expr>,
        span: Span,
    },
    /// A `match` expression with lightweight arms.
    Match {
        scrutinee: Box<Expr>,
        arms: Vec<MatchArm>,
        span: Span,
    },
    /// Struct literal `Player(health = 100, ...)` or `Vec3(0, 0, 0)`.
    StructLit {
        name: String,
        args: Vec<Expr>,
        span: Span,
    },
    /// An `if` expression: `if cond: <block> [else: <block>]`.
    /// Used as a value (e.g. `let x = if cond: ...`), lowering to `phi`.
    If {
        cond: Box<Expr>,
        then_block: Block,
        else_block: Option<Block>,
        span: Span,
    },
}

impl Expr {
    /// The source span of this expression.
    pub fn span(&self) -> Span {
        match self {
            Expr::Int(_, s)
            | Expr::Float(_, s)
            | Expr::Str(_, s)
            | Expr::Bool(_, s)
            | Expr::FStr(_, s)
            | Expr::Ident(_, s)
            | Expr::SelfExpr(s)
            | Expr::Field { span: s, .. }
            | Expr::Call { span: s, .. }
            | Expr::Binary { span: s, .. }
            | Expr::Unary { span: s, .. }
            | Expr::Match { span: s, .. }
            | Expr::StructLit { span: s, .. }
            | Expr::If { span: s, .. } => *s,
        }
    }
}

/// A lowered f-string component.
#[derive(Clone, Debug)]
pub enum FStrExpr {
    Literal(String),
    Expr(Box<Expr>),
}

/// One arm of a `match` expression: `pattern -> body`.
#[derive(Clone, Debug)]
pub struct MatchArm {
    pub pattern: Pattern,
    pub body: Block,
    pub span: Span,
}

/// A lightweight match pattern.
#[derive(Clone, Debug)]
pub enum Pattern {
    /// Wildcard `_`.
    Wildcard,
    /// A literal value pattern.
    Int(i64),
    Bool(bool),
    /// A comparison pattern such as `<= 0` or `> 100`.
    Compare(BinOp, Box<Expr>),
    /// Bind the scrutinee to a name.
    Binding(String),
}

/// Binary operators.
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum BinOp {
    Add,
    Sub,
    Mul,
    Div,
    Rem,
    Eq,
    Ne,
    Lt,
    Gt,
    Le,
    Ge,
}

/// Unary operators.
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum UnOp {
    Neg,
    Not,
}