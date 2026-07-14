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

/// An arena declaration: `arena MyArena: Player` creates a named allocation space.
#[derive(Clone, Debug)]
pub struct ArenaDecl {
    pub name: String,
    pub ty: Type,
    pub span: Span,
}

/// A top-level declaration.
#[derive(Clone, Debug)]
pub enum Item {
    Struct(StructDef),
    Trait(TraitDef),
    Impl(ImplBlock),
    Fn(FnDef),
    /// `arena Name: Type` - declares a spatial arena for long-lived allocations.
    Arena(ArenaDecl),
    /// `sequence Name(params): <body with `yield`s>` - a tick-aware coroutine.
    /// Desugared (see [`crate::sequence`]) into a state-holding struct plus a
    /// `resume(mut self) -> bool` method before type checking ever sees it.
    Sequence(SequenceDef),
    /// `enum Name: Variant1, Variant2(field: Type, ...), ...` - each variant
    /// is assigned a dense `i32` discriminant in declaration order and may
    /// optionally carry named, typed payload fields.
    Enum(EnumDef),
    /// `import "path.star" as alias` - see [`ImportDecl`].
    Import(ImportDecl),
    /// `extern "C" fn ...` - a foreign function declaration with no body,
    /// see [`ExternFnDecl`].
    ExternFn(ExternFnDecl),
}

/// `extern "C" fn name(params) -> ret` - declares a symbol implemented
/// elsewhere (a C library) rather than by a Star function body. `abi` is the
/// string literal naming the calling convention (`"C"` is the only one the
/// checker currently accepts; see `crate::types::Checker::check_item`).
/// `sig` is reused from ordinary function declarations since the shape
/// (name/type params/params/return type) is identical -- only the (absent)
/// body differs.
#[derive(Clone, Debug)]
pub struct ExternFnDecl {
    pub abi: String,
    pub sig: FnSig,
    pub span: Span,
}

/// An `import "path.star" as alias` declaration: brings another file's
/// top-level items into scope, reachable as `alias::item`. Resolved (parsed,
/// recursively expanded, and renamed to globally-unique mangled names) by
/// [`crate::modules`] before the type checker ever sees more than one file --
/// by the time [`Item::Import`] reaches [`crate::types::Checker`], it has
/// always already been stripped out of the module.
#[derive(Clone, Debug)]
pub struct ImportDecl {
    pub alias: String,
    /// The imported file's path, resolved relative to the importing file's
    /// own directory.
    pub path: String,
    pub span: Span,
}

/// An enum declaration: `enum Name:` followed by one variant per indented
/// line, each either a bare name (fieldless) or `Name(field: Type, ...)`.
/// `type_params` holds `<T, U, ...>` for a generic enum (empty otherwise);
/// see [`crate::types::Checker`]'s monomorphization of generic declarations.
#[derive(Clone, Debug)]
pub struct EnumDef {
    pub name: String,
    pub type_params: Vec<String>,
    pub variants: Vec<EnumVariantDef>,
    pub span: Span,
}

/// A single enum variant: `Name` or `Name(field: Type, ...)`.
#[derive(Clone, Debug)]
pub struct EnumVariantDef {
    pub name: String,
    pub fields: Vec<EnumFieldDef>,
    pub span: Span,
}

/// A single named, typed field of a payload-carrying enum variant.
#[derive(Clone, Debug)]
pub struct EnumFieldDef {
    pub name: String,
    pub ty: Type,
}

/// `sequence Name(params): <body>` - see [`Item::Sequence`].
#[derive(Clone, Debug)]
pub struct SequenceDef {
    pub name: String,
    pub params: Vec<Param>,
    pub body: Block,
    pub span: Span,
}

/// A data structure: named, typed fields with optional defaults.
/// `type_params` holds `<T, U, ...>` for a generic struct (empty otherwise);
/// see [`crate::types::Checker`]'s monomorphization of generic declarations.
#[derive(Clone, Debug)]
pub struct StructDef {
    pub name: String,
    pub type_params: Vec<String>,
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
/// `type_params` holds `<T, U, ...>` for a generic function (empty
/// otherwise); its type parameters are solved by unifying each argument's
/// inferred type against the corresponding (possibly parameterized) declared
/// parameter type at each call site -- see `Checker::instantiate_fn`.
#[derive(Clone, Debug)]
pub struct FnSig {
    pub name: String,
    pub type_params: Vec<String>,
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
    /// A generic application like `Vec<i32>` or `GenRef<T>`.
    Generic(String, Vec<Type>),
    /// A closure/function type: `Fn(T1, T2, ...) -> Ret`, e.g. the
    /// declared type of a callback parameter (`f: Fn(i32) -> i32`). Only
    /// ever produced by [`crate::parser::Parser::parse_type`] recognizing
    /// the pseudo-keyword `Fn` (a plain, capitalized identifier -- `fn` the
    /// keyword is reserved for declarations and lambda literals).
    Fn(Vec<Type>, Box<Type>),
    /// A tuple type `(T, U, ...)` of two or more elements, e.g. the declared
    /// type of a `let` binding holding a multi-return. Only ever produced by
    /// [`crate::parser::Parser::parse_type`] parsing a parenthesized,
    /// comma-separated type list -- a single parenthesized type with no
    /// comma is just that type (grouping), not a 1-tuple.
    Tuple(Vec<Type>),
    /// A fixed-size inline array type `[T; N]`: tile grids, palettes,
    /// register files, vertex layouts -- a compile-time-constant element
    /// count, unlike `List<T>`'s runtime-growable length. Lowers to an
    /// LLVM `[N x T]` array laid out inline (no RC header, no heap
    /// allocation of its own), see `Ty::Array`.
    Array(Box<Type>, u64),
    /// A fixed-capacity ring buffer `Ring<T, N>`: input replay, frame-time
    /// history, netcode rollback buffers -- a sliding window over the most
    /// recent `N` pushed elements. Written `Ring<T, N>` (angle brackets, not
    /// `Array`'s `[T; N]`) since `N` sits alongside a type argument rather
    /// than after a `;`; parsed by a dedicated special case in
    /// `crate::parser::Parser::parse_type_inner` (mirroring `Type::Array`'s
    /// own bracket special case) since this compiler has no general
    /// const-generic parameter machinery. Lowers to an inline
    /// `{ [N x T], i64, i64 }` (data, head, len) -- no RC header, no heap
    /// allocation of its own, like `Ty::Array` -- see `Ty::Ring`.
    Ring(Box<Type>, u64),
}

impl Type {
    /// Check if this type is a GenRef<T>.
    pub fn is_genref(&self) -> bool {
        match self {
            Type::Named(name) => name == "GenRef",
            Type::Generic(name, _) => name == "GenRef",
            Type::Fn(..) | Type::Tuple(..) | Type::Array(..) | Type::Ring(..) => false,
        }
    }
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
    /// `for var in start..end: <block>` - exclusive-range iteration over
    /// `i32` bounds.
    For {
        var: String,
        start: Expr,
        end: Expr,
        body: Block,
        span: Span,
    },
    /// `break` - exits the innermost enclosing `while`/`for` loop.
    Break { span: Span },
    /// `continue` - skips to the next iteration of the innermost enclosing
    /// `while`/`for` loop.
    Continue { span: Span },
    /// `frame: <block>` - temporal allocation scope that resets at end of tick.
    Frame {
        body: Block,
        span: Span,
    },
    /// `par item in ArenaName: <body>` (also spelled `swarm`) - parallel
    /// iteration over an arena's live elements, dispatched across worker
    /// threads. The checker proves iterations are disjoint by requiring the
    /// body to only mutate `item`'s own fields (or locals declared inside
    /// the loop body itself).
    Par {
        var: String,
        arena: String,
        body: Block,
        span: Span,
    },
    /// `yield` - suspends a `sequence` coroutine until the next `resume()`
    /// tick. Only valid at the top level of a `sequence` body (see
    /// [`crate::sequence`]); rejected elsewhere by the desugaring pass.
    Yield { span: Span },
    /// `spawn ArenaName(args...)` - constructs a new element of the arena's
    /// declared struct type. Reclaims a slot off the arena's free-list
    /// (populated by `despawn`) if one is available, otherwise appends to
    /// the backing array and grows its live `count` by one. See
    /// [`crate::codegen::Codegen::emit_spawn_stmt`].
    Spawn {
        arena: String,
        args: Vec<Expr>,
        span: Span,
    },
    /// `despawn ArenaName[index]` - invalidates a slot by bumping its
    /// generation counter and pushes it onto the arena's free-list so a
    /// later `spawn` can reclaim its memory; it exists so a `GenRef` into
    /// that slot can be observed going stale. See
    /// [`crate::codegen::Codegen::emit_despawn_stmt`].
    Despawn {
        arena: String,
        index: Expr,
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
    /// Struct literal `Player(health = 100, ...)` or `Vec3(0, 0, 0)`. For a
    /// generic struct, `type_args` optionally carries an explicit turbofish
    /// (`Box<i32>(value = 5)`); when empty the checker infers each type
    /// parameter by unifying the declared field types against the arguments'
    /// inferred types (see `Checker::instantiate_struct`).
    StructLit {
        name: String,
        type_args: Vec<Type>,
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
    /// GenRef creation: `GenRef<T>(expr)` creates a generational reference.
    GenRefCreate {
        inner_ty: Type,
        value: Box<Expr>,
        span: Span,
    },
    /// A bracketed index `base[idx]`. Despite the name (kept for
    /// historical/backward-compatible reasons -- this predates `List<T>`),
    /// this is the *general* `[..]` index syntax: the checker resolves it to
    /// either a `GenRef<T>` generation-checked dereference or a `List<T>`
    /// bounds-checked element access based on `base`'s resolved type (see
    /// `Checker::infer_expr`'s `Expr::GenRefIndex` arm), lowering to a
    /// distinct `TypedExpr::GenRefIndex`/`TypedExpr::ListIndex` node either
    /// way.
    GenRefIndex {
        base: Box<Expr>,
        index: Box<Expr>,
        span: Span,
    },
    /// An enum variant literal: `EnumName::Variant` or, for a payload
    /// variant, `EnumName::Variant(args...)`. For a generic enum, `type_args`
    /// optionally carries an explicit turbofish (`Option<i32>::Some(5)`,
    /// required when the variant has no payload to infer from, e.g.
    /// `Option<i32>::None`); see `Checker::instantiate_enum`.
    EnumVariant {
        enum_name: String,
        type_args: Vec<Type>,
        variant: String,
        args: Vec<Expr>,
        span: Span,
    },
    /// A lambda/closure literal: `fn(params) [-> RetType]: <body>`, where
    /// `<body>` is either an indented block or (mirroring a `match` arm) a
    /// single inline trailing expression. Every local variable visible at
    /// the definition site is captured *by value* (a snapshot taken at
    /// creation time, not a live reference) -- see
    /// `crate::codegen::Codegen::emit_closure_lit` for why: the closure's
    /// environment is heap-allocated so it can safely outlive the stack
    /// frame that created it, and copying values (rather than capturing
    /// pointers into that soon-to-be-popped frame) is what makes that safe.
    Lambda {
        params: Vec<Param>,
        ret: Option<Type>,
        body: Block,
        span: Span,
    },
    /// A non-empty list literal: `[e1, e2, ...]`. Its element type is
    /// inferred from the first element (see `Checker::infer_expr`); an empty
    /// `[]` has no element to infer from and is rejected -- use
    /// `List<T>()` (parsed as an ordinary `Expr::StructLit` naming the
    /// builtin `List` type, see `Checker::infer_list_new`) to construct an
    /// empty list.
    ListLit(Vec<Expr>, Span),
    /// `expr?` - propagates an `Option<T>`/`Result<T,E>`'s "empty" variant
    /// (`None`/`Err(e)`) out of the enclosing function via an early `return`,
    /// otherwise evaluating to the wrapped value (`T`). Desugared entirely in
    /// the checker (see `Checker::infer_expr`'s `Expr::Try` arm) into a
    /// `TypedExpr::Match` over the existing `Some`/`None` (or `Ok`/`Err`)
    /// variants -- there is no dedicated codegen path for this node at all.
    Try {
        inner: Box<Expr>,
        span: Span,
    },
    /// A tuple literal `(e1, e2, ...)` of two or more elements (a single
    /// parenthesized expression with no comma is just grouping, and stays
    /// `parse_primary`'s ordinary unwrap -- see its `LParen` arm). A trailing
    /// comma after exactly one element (`(e1,)`) makes a 1-tuple.
    TupleLit(Vec<Expr>, Span),
    /// A tuple index `base.0`, `base.1`, ... -- distinct from `Field` (which
    /// looks a name up in a *declared* struct's field list) since a tuple's
    /// "fields" are purely positional and never named.
    TupleIndex {
        base: Box<Expr>,
        index: usize,
        span: Span,
    },
    /// A fixed-size array repeat literal `[value; N]` -- `value` is
    /// evaluated exactly once (mirrors Rust's own `[expr; N]`) and copied
    /// into all `N` slots. This is the *only* array literal form (see
    /// `Type::Array`'s doc comment for why a `[e1, e2, ...]` distinct-
    /// elements form isn't supported: that syntax is already `ListLit`, and
    /// there's no expected-type propagation in this checker to
    /// disambiguate the two by context).
    ArrayRepeat {
        value: Box<Expr>,
        count: u64,
        span: Span,
    },
    /// `Ring<T, N>()` -- an empty, fixed-capacity ring buffer construction,
    /// the `Ring<T,N>` counterpart to `List<T>()`/`Map<K,V>()`/`Set<T>()`.
    /// Unlike those (parsed as an ordinary `Expr::StructLit` naming the
    /// builtin type, since their turbofish is a plain comma-separated
    /// `Type` list), `Ring<T, N>`'s second argument is a bare integer
    /// literal, not a `Type` -- `try_parse_type_args` can't parse it, so
    /// this gets its own dedicated AST node and parser special case (see
    /// `Parser::parse_ring_new`).
    RingNew {
        elem_ty: Type,
        count: u64,
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
            | Expr::If { span: s, .. }
            | Expr::GenRefCreate { span: s, .. }
            | Expr::GenRefIndex { span: s, .. }
            | Expr::EnumVariant { span: s, .. }
            | Expr::Lambda { span: s, .. }
            | Expr::Try { span: s, .. }
            | Expr::TupleIndex { span: s, .. }
            | Expr::ArrayRepeat { span: s, .. }
            | Expr::RingNew { span: s, .. }
            | Expr::ListLit(_, s) => *s,
            Expr::TupleLit(_, s) => *s,
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
    /// An enum variant pattern: `EnumName::Variant` or, for a payload
    /// variant, `EnumName::Variant(binding, ...)` which destructures each
    /// field into a fresh local binding in declaration order.
    EnumVariant(String, String, Vec<String>),
    /// A struct destructuring pattern: `StructName(binding, ...)`, which
    /// destructures each of the struct's fields into a fresh local binding
    /// in declaration order. Carries no tag to test, so it always matches.
    Struct(String, Vec<String>),
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
    /// `&&` / `and` - short-circuiting logical AND (see
    /// `crate::codegen::Codegen::emit_expr`'s `TypedExpr::Binary` arm for the
    /// branch-based short-circuit lowering).
    And,
    /// `||` / `or` - short-circuiting logical OR.
    Or,
}

/// Unary operators.
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum UnOp {
    Neg,
    Not,
}