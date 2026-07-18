//! The typed tree (HIR) `Checker::check` produces: every node from
//! [`crate::ast`]'s surface syntax mirrored with a resolved [`super::Ty`]
//! attached to each expression.

use std::collections::HashMap;

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
    /// Maps a monomorphized generic struct/enum's mangled name (e.g.
    /// `Box__i32`, `Option__str`, the flat `alias__name`-style symbol every
    /// codegen-facing `Ty::Named`/`Ty::Enum` actually carries) back to the
    /// `(template_name, type_args)` it was instantiated from -- so a
    /// consumer that needs a human-readable spelling (`Box<i32>`) rather
    /// than the internal mangled one can reconstruct it, recursively for
    /// nested generics too, without needing to parse the mangled string
    /// (which is ambiguous in general: a struct's own plain name can
    /// already contain `__` from module-import mangling, see
    /// `crate::modules::mangle_name`). Currently consulted by
    /// `Codegen::reflect_type_name` for `@export`/`@tweakable` metadata;
    /// see its own doc comment for the concrete bug this closes (a
    /// generic-typed reflected field's metadata showed the raw mangled
    /// name, e.g. `Box__i32`/`Option__i32`, instead of `Box<i32>`/
    /// `Option<i32>`). Populated once, at the end of `Checker::check`, from
    /// `Checker::mono_struct_of`/`Checker::mono_enum_of` (which don't
    /// themselves survive past type-checking -- `Codegen` never sees the
    /// `Checker` that produced its input).
    pub generic_instantiations: HashMap<String, (String, Vec<Ty>)>,
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
    /// A char literal, see [`crate::ast::Expr::Char`]. `ty` is always `Ty::Char`.
    Char(char, Ty, Span),
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
    /// See `Expr::GenRefCreate`'s doc comment: `is_handle` selects
    /// `Ty::Handle` over `Ty::GenRef` in `into_ty` below; codegen
    /// (`Codegen::emit_genref_create`) doesn't care either way.
    GenRefCreate { inner_ty: Ty, value: Box<TypedExpr>, is_handle: bool, span: Span },
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
    /// `Map<K,V>()` -- an empty map construction, see `Checker::infer_map_new`.
    MapNew { key_ty: Ty, val_ty: Ty, span: Span },
    /// `Set<T>()` -- an empty set construction, see `Checker::infer_set_new`.
    SetNew { elem_ty: Ty, span: Span },
    /// `map.insert(k,v)` / `.get(k)` / `.remove(k)` / `.contains(k)` /
    /// `.len()`, see `Checker::infer_map_method`.
    MapMethod { base: Box<TypedExpr>, method: MapMethod, args: Vec<TypedExpr>, ty: Ty, span: Span },
    /// `set.insert(v)` / `.remove(v)` / `.contains(v)` / `.len()`, see
    /// `Checker::infer_set_method`.
    SetMethod { base: Box<TypedExpr>, method: SetMethod, args: Vec<TypedExpr>, ty: Ty, span: Span },
    /// A tuple literal `(e1, e2, ...)`, see [`crate::ast::Expr::TupleLit`].
    /// `ty` is always `Ty::Tuple(elems.map(into_ty))`.
    TupleLit { elems: Vec<TypedExpr>, ty: Ty, span: Span },
    /// `tuple.0`, `tuple.1`, ..., see [`crate::ast::Expr::TupleIndex`]. `ty`
    /// is the indexed element's type, already bounds-checked at compile time
    /// against the tuple's arity (unlike `ListIndex`, there's no runtime
    /// bounds check to lower -- the index is a literal, and the tuple's
    /// arity is part of its static type).
    TupleIndex { base: Box<TypedExpr>, index: usize, ty: Ty, span: Span },
    /// `[value; N]`, see [`crate::ast::Expr::ArrayRepeat`]. `elem_ty` is
    /// `value`'s own inferred type; `ty` is always `Ty::Array(elem_ty, count)`.
    ArrayRepeat { value: Box<TypedExpr>, count: u64, elem_ty: Ty, span: Span },
    /// `arr[idx]`: a bounds-checked fixed-size array element access, sharing
    /// `Expr::GenRefIndex`'s syntax the same way `ListIndex`/`GenRefIndex`/
    /// `StrIndex` already do (see `Checker::infer_expr`'s dispatch on the
    /// base's resolved type). Unlike `List<T>`, there's no copy-on-write
    /// uniqueness gate -- an array is stored inline as part of its own
    /// binding's storage, not behind a shared heap pointer.
    ArrayIndex { base: Box<TypedExpr>, index: Box<TypedExpr>, ty: Ty, span: Span },
    /// `arr.len()` -- always `count` (the array's compile-time-constant
    /// size), resolved entirely by the checker with no runtime read of the
    /// array's storage at all (unlike `ListMethod::Len`, which reads a
    /// runtime-tracked length out of the list's heap buffer). `base` is
    /// still carried and still evaluated by codegen (for any side effects
    /// evaluating it might have -- e.g. a call expression yielding the
    /// array), just never used to compute the result.
    ArrayLen { base: Box<TypedExpr>, count: u64, span: Span },
    /// `Ring<T, N>()` -- an empty, fixed-capacity ring buffer construction,
    /// see [`crate::ast::Expr::RingNew`].
    RingNew { elem_ty: Ty, count: u64, span: Span },
    /// `ring.push(v)` / `.pop()` / `.len()`, see `Checker::infer_ring_method`.
    RingMethod { base: Box<TypedExpr>, method: RingMethod, args: Vec<TypedExpr>, ty: Ty, span: Span },
    /// `ring[idx]`: a bounds-checked (against the ring's current `len`, not
    /// its static capacity `N`) element read, `0` = the oldest live element.
    /// `ty` is the element type. See `crate::ast::Expr::GenRefIndex`'s doc
    /// comment for why this shares that AST node with `GenRef<T>`/`List<T>`/
    /// `[T; N]` indexing.
    RingIndex { base: Box<TypedExpr>, index: Box<TypedExpr>, ty: Ty, span: Span },
    /// `Table<T>()` -- an empty struct-of-arrays table construction, see
    /// `Checker::infer_table_new`. `elem_ty` is always `Ty::Named(struct)`.
    TableNew { elem_ty: Ty, span: Span },
    /// `table.push(v)` / `.pop()` / `.len()`, see `Checker::infer_table_method`.
    TableMethod { base: Box<TypedExpr>, method: TableMethod, args: Vec<TypedExpr>, ty: Ty, span: Span },
    /// `table[idx]`: a bounds-checked `Table<T>` element read/write,
    /// reassembling (or decomposing) the whole struct value from (into)
    /// every column at `idx`. `ty` is the element type `T`. See
    /// `crate::ast::Expr::GenRefIndex`'s doc comment for why this shares
    /// that AST node with `GenRef<T>`/`List<T>`/`[T; N]`/`Ring<T,N>` indexing.
    TableIndex { base: Box<TypedExpr>, index: Box<TypedExpr>, ty: Ty, span: Span },
    /// `expr as Type`, see [`crate::ast::Expr::Cast`]. `ty` is the resolved
    /// target type (already validated as a legal numeric/`char` conversion
    /// by `Checker::infer_expr`'s `Expr::Cast` arm).
    Cast { expr: Box<TypedExpr>, ty: Ty, span: Span },
    /// `Wrapping<T>(value)`, see [`crate::ast::Expr::WrappingNew`]. `ty` is
    /// always `Ty::Wrapping(inner_ty)`.
    WrappingNew { inner_ty: Ty, value: Box<TypedExpr>, span: Span },
    /// `Fixed<Bits, Frac>(value)`, see [`crate::ast::Expr::FixedNew`]. `ty`
    /// is always `Ty::Fixed(bits, frac)`.
    FixedNew { bits: u32, frac: u32, value: Box<TypedExpr>, span: Span },
    /// `BitField<N>(value)`, see [`crate::ast::Expr::BitFieldNew`]. `ty` is
    /// always `Ty::BitField(bits)`.
    BitFieldNew { bits: u32, value: Box<TypedExpr>, span: Span },
    /// `Flags<E>(a, b, ...)`, see `Checker::infer_flags_new`. Unlike
    /// `Expr::BitFieldNew`, there is no dedicated raw `Expr` node -- parsing
    /// produces an ordinary `Expr::StructLit` naming the builtin `Flags`
    /// type (same turbofish-plus-call grammar `List<T>`/`Table<T>` already
    /// use), so this HIR-only node is synthesized by the checker once it
    /// knows `enum_name` and has type-checked each argument to be `E`-typed.
    /// `args` is zero or more `E`-typed values, OR'd together bit-by-bit at
    /// codegen time (`1i64 << variant_tag` per argument, evaluated at
    /// runtime so a non-literal enum-typed expression works too, not just a
    /// literal `EnumName::Variant`). `ty` is always `Ty::Flags(Ty::Enum(enum_name))`.
    FlagsNew { enum_name: String, args: Vec<TypedExpr>, span: Span },
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

/// The builtin `Map<K,V>` methods -- see `TypedExpr::MapMethod`.
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum MapMethod {
    /// `map.insert(k, v)` -- inserts or overwrites the value for `k`.
    Insert,
    /// `map.get(k) -> Option<V>` -- `Some(v)` if present, `None` otherwise.
    Get,
    /// `map.remove(k) -> Option<V>` -- removes and returns the value if
    /// present (via swap-remove, so remaining key order is not preserved).
    Remove,
    /// `map.contains(k) -> bool`.
    Contains,
    /// `map.len() -> i32`.
    Len,
}

/// The builtin `Set<T>` methods -- see `TypedExpr::SetMethod`.
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum SetMethod {
    /// `set.insert(v) -> bool` -- `true` if newly inserted, `false` if `v`
    /// was already present.
    Insert,
    /// `set.remove(v) -> bool` -- `true` if `v` was present and removed
    /// (via swap-remove, so remaining element order is not preserved).
    Remove,
    /// `set.contains(v) -> bool`.
    Contains,
    /// `set.len() -> i32`.
    Len,
}

/// The builtin `Ring<T,N>` methods -- see `TypedExpr::RingMethod`.
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum RingMethod {
    /// `ring.push(v)` -- appends `v` at the back; once `len` reaches the
    /// ring's static capacity `N`, this evicts the oldest (front) element
    /// instead of growing (there is nowhere to grow to) or no-op'ing, so a
    /// full ring always holds a sliding window of the most recent `N` pushes.
    Push,
    /// `ring.pop()` -- removes and returns the oldest (front) element, or
    /// the element type's zero value if the ring is empty (mirrors
    /// `ListMethod::Pop`'s "safe null equivalent" convention).
    Pop,
    /// `ring.len()` -- the current element count as an `i32` (`0..=N`).
    Len,
}

/// The builtin `Table<T>` methods -- see `TypedExpr::TableMethod`.
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum TableMethod {
    /// `table.push(v)` -- appends `v`'s fields, one per column, growing
    /// every column's backing buffer in lockstep if needed.
    Push,
    /// `table.pop()` -- removes and returns the last element (reassembled
    /// from every column), or the element type's zero value if the table is
    /// empty (mirrors `ListMethod::Pop`'s "safe null equivalent" convention).
    Pop,
    /// `table.len()` -- the current element count as an `i32`.
    Len,
}

impl TypedExpr {
    pub fn into_ty(self) -> Ty {
        match self {
            TypedExpr::Int(_, ty, _) | TypedExpr::Float(_, ty, _) | TypedExpr::Str(_, ty, _) | TypedExpr::Bool(_, ty, _)
            | TypedExpr::Char(_, ty, _) | TypedExpr::Cast { ty, .. }
            | TypedExpr::Field { ty, .. } | TypedExpr::Call { ty, .. } | TypedExpr::Binary { ty, .. }
            | TypedExpr::Unary { ty, .. } | TypedExpr::Match { ty, .. } | TypedExpr::StructLit { ty, .. }
            | TypedExpr::FStr(_, ty, _) | TypedExpr::GenRefIndex { ty, .. } | TypedExpr::EnumVariant { ty, .. }
            | TypedExpr::Closure { ty, .. } | TypedExpr::ListIndex { ty, .. } | TypedExpr::ListMethod { ty, .. }
            | TypedExpr::StrIndex { ty, .. } | TypedExpr::Error(ty) => ty,
            TypedExpr::Ident { ty, .. } => ty,
            TypedExpr::SelfExpr(ty, _) => ty,
            TypedExpr::If { ty, .. } => ty.clone(),
            TypedExpr::GenRefCreate { inner_ty, is_handle, .. } => {
                if is_handle { Ty::Handle(Box::new(inner_ty)) } else { Ty::GenRef(Box::new(inner_ty)) }
            }
            TypedExpr::WrappingNew { inner_ty, .. } => Ty::Wrapping(Box::new(inner_ty)),
            TypedExpr::FixedNew { bits, frac, .. } => Ty::Fixed(bits, frac),
            TypedExpr::BitFieldNew { bits, .. } => Ty::BitField(bits),
            TypedExpr::FlagsNew { enum_name, .. } => Ty::Flags(Box::new(Ty::Enum(enum_name))),
            TypedExpr::ListNew { elem_ty, .. } => Ty::List(Box::new(elem_ty)),
            TypedExpr::ListLit { elem_ty, .. } => Ty::List(Box::new(elem_ty)),
            TypedExpr::MapNew { key_ty, val_ty, .. } => Ty::Map(Box::new(key_ty), Box::new(val_ty)),
            TypedExpr::SetNew { elem_ty, .. } => Ty::Set(Box::new(elem_ty)),
            TypedExpr::MapMethod { ty, .. } => ty,
            TypedExpr::SetMethod { ty, .. } => ty,
            TypedExpr::TupleLit { ty, .. } => ty,
            TypedExpr::TupleIndex { ty, .. } => ty,
            TypedExpr::ArrayIndex { ty, .. } => ty,
            TypedExpr::ArrayRepeat { count, elem_ty, .. } => Ty::Array(Box::new(elem_ty), count),
            TypedExpr::ArrayLen { .. } => Ty::Int,
            TypedExpr::RingNew { elem_ty, count, .. } => Ty::Ring(Box::new(elem_ty), count),
            TypedExpr::RingMethod { ty, .. } => ty,
            TypedExpr::RingIndex { ty, .. } => ty,
            TypedExpr::TableNew { elem_ty, .. } => Ty::Table(Box::new(elem_ty)),
            TypedExpr::TableMethod { ty, .. } => ty,
            TypedExpr::TableIndex { ty, .. } => ty,
        }
    }

    pub fn span(&self) -> Span {
        match self {
            TypedExpr::Int(_, _, s) | TypedExpr::Float(_, _, s) | TypedExpr::Str(_, _, s) | TypedExpr::Bool(_, _, s)
            | TypedExpr::Char(_, _, s)
            | TypedExpr::FStr(_, _, s) => *s,
            TypedExpr::Cast { span, .. } |
            TypedExpr::Ident { span, .. } | TypedExpr::Field { span, .. } | TypedExpr::Call { span, .. }
            | TypedExpr::Binary { span, .. } | TypedExpr::Unary { span, .. } | TypedExpr::Match { span, .. }
            | TypedExpr::StructLit { span, .. } | TypedExpr::If { span, .. } | TypedExpr::GenRefCreate { span, .. }
            | TypedExpr::GenRefIndex { span, .. } | TypedExpr::EnumVariant { span, .. }
            | TypedExpr::Closure { span, .. } | TypedExpr::ListNew { span, .. } | TypedExpr::ListLit { span, .. }
            | TypedExpr::ListIndex { span, .. } | TypedExpr::ListMethod { span, .. }
            | TypedExpr::StrIndex { span, .. } | TypedExpr::MapNew { span, .. } | TypedExpr::SetNew { span, .. }
            | TypedExpr::MapMethod { span, .. } | TypedExpr::SetMethod { span, .. }
            | TypedExpr::TupleLit { span, .. } | TypedExpr::TupleIndex { span, .. }
            | TypedExpr::ArrayRepeat { span, .. } | TypedExpr::ArrayIndex { span, .. }
            | TypedExpr::ArrayLen { span, .. } | TypedExpr::RingNew { span, .. }
            | TypedExpr::RingMethod { span, .. } | TypedExpr::RingIndex { span, .. }
            | TypedExpr::TableNew { span, .. } | TypedExpr::TableMethod { span, .. }
            | TypedExpr::TableIndex { span, .. }
            | TypedExpr::WrappingNew { span, .. } | TypedExpr::FixedNew { span, .. }
            | TypedExpr::BitFieldNew { span, .. } | TypedExpr::FlagsNew { span, .. } => *span,
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
