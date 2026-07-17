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
use std::collections::{HashMap, HashSet};

/// A resolved type.
#[derive(Clone, Debug, PartialEq)]
pub enum Ty {
    Int,
    Float,
    /// 8-bit signed integer -- retro CPU registers, PSG audio channels, and
    /// other exact-width hardware state. Unlike `Ty::Int`, arithmetic
    /// (`+`/`-`/`*`) traps on overflow rather than wrapping (see
    /// `Codegen::emit_sized_int_binop`); no implicit widening to/from any
    /// other numeric type -- an explicit `as` cast (`Expr::Cast`) is always
    /// required, matching `docs/design.md`'s "Numeric widths and modes".
    I8,
    /// 8-bit unsigned integer -- see `Ty::I8`'s doc comment (same rules,
    /// unsigned arithmetic/comparisons).
    U8,
    /// 16-bit signed integer -- see `Ty::I8`'s doc comment.
    I16,
    /// 16-bit unsigned integer -- see `Ty::I8`'s doc comment.
    U16,
    /// 32-bit unsigned integer -- see `Ty::I8`'s doc comment. Distinct from
    /// `Ty::Int` (32-bit *signed*, Star's original/default integer type)
    /// purely in signedness: same bit width, but `/`/`%`/comparisons use
    /// unsigned opcodes and overflow traps on the unsigned range `[0,
    /// u32::MAX]` rather than `i32`'s signed range.
    U32,
    /// 64-bit signed integer -- see `Ty::I8`'s doc comment. Large-world
    /// coordinates, timestamps, and other AAA-scale counters that overflow
    /// `i32`.
    I64,
    /// 64-bit unsigned integer -- see `Ty::I8`'s doc comment.
    U64,
    /// 64-bit IEEE-754 float -- see `Ty::I8`'s doc comment for the "no
    /// implicit conversion" rule; unlike the sized integers, `F64` never
    /// traps (float arithmetic saturates to +/-inf per IEEE-754, same as
    /// `Ty::Float` today).
    F64,
    /// A Unicode scalar value (not a raw `str` byte -- see `Ty::Str`'s
    /// `s[i]` byte-index convention). Lowered to a bare `i32` holding the
    /// codepoint (see `Codegen::llvm_ty`); supports equality/ordering
    /// comparisons but not arithmetic (mirrors Rust's `char`, which is not
    /// `Add`/`Sub`/etc.) -- convert to/from an integer type via `as` to do
    /// codepoint arithmetic.
    Char,
    Str,
    Bool,
    Vec2,
    Vec3,
    Vec4,
    Mat4,
    Named(String),
    /// A generational reference backed by a slot-map: GenRef<T>.
    GenRef(Box<Ty>),
    /// A growable, heap-allocated dynamic array: `List<T>`. Lowers to a
    /// reference-counted `i8*` pointing at a heap object holding
    /// `{ T* data, i64 len, i64 cap }`, the same RC header/allocation scheme
    /// as `Ty::Str` -- see `Codegen::llvm_ty`/`crate::codegen::list`.
    /// Storage is shared copy-on-write: `let b = a` is an O(1) refcount
    /// bump, but any mutation (`push`, `pop`, index-assignment) clones the
    /// buffer first if it isn't uniquely owned, so mutating one binding
    /// never affects another -- each `List<T>` *value* still observably owns
    /// an independent buffer, unlike `GenRef<T>`'s shared fixed-capacity
    /// arena, even though the underlying storage may be shared under the
    /// hood until a mutation forces a copy.
    List(Box<Ty>),
    /// A growable key/value map: `Map<K, V>`. Lowers to the same kind of
    /// reference-counted, copy-on-write `i8*` object pointer as `List<T>`
    /// (see `crate::codegen::map`), holding two parallel arrays searched
    /// linearly via a generated structural-equality function -- there is no
    /// hashing/bucketing yet (see that module's doc comment for the
    /// rationale). `K` must be a "hashable" type per
    /// `Checker::check_hashable_ty`: `i32`/`f32`/`bool`/`str`/a fieldless
    /// `enum`/`Vec2`/`Vec3`/`Vec4`, or a `struct` composed entirely of such
    /// fields (recursively) -- payload enums, `GenRef`/`List`/`Map`/`Set`/
    /// closures/`ptr` are rejected as key types.
    Map(Box<Ty>, Box<Ty>),
    /// A growable set: `Set<T>`, same representation/search strategy as
    /// `Map<K, V>` (see `crate::codegen::set`) minus the parallel value
    /// array -- structurally identical to `List<T>`'s payload shape, with
    /// `insert`/`remove`/`contains` doing a linear structural-equality scan
    /// instead of index-based access. `T` is subject to the same
    /// hashability restriction as `Map`'s `K`.
    Set(Box<Ty>),
    /// A tuple `(T, U, ...)` of two or more elements. Lowered to an
    /// anonymous LLVM literal struct type (`{ T, U, ... }`, no `%name`
    /// declaration) laid out inline exactly like a nominal struct's
    /// fields -- no RC header, no heap allocation of its own -- see
    /// `Codegen::llvm_ty`. Positional elements are accessed by
    /// `TypedExpr::TupleIndex`, never by name.
    Tuple(Vec<Ty>),
    /// A fixed-size inline array `[T; N]`: tile grids, palettes, register
    /// files, vertex layouts. Lowers to an LLVM `[N x T]` array laid out
    /// inline exactly like `Ty::Tuple` -- no RC header, no heap allocation
    /// of its own, `N` a compile-time constant (unlike `List<T>`'s
    /// runtime-growable length).
    Array(Box<Ty>, u64),
    /// A fixed-capacity ring buffer `Ring<T, N>`: input replay, frame-time
    /// history, netcode rollback buffers. Lowers to an inline
    /// `{ [N x T], i64, i64 }` (data, head, len) -- like `Ty::Array`, no RC
    /// header, no heap allocation of its own, `N` a compile-time constant.
    /// Unlike `Ty::Array`, it's mutable through dedicated `push`/`pop`
    /// methods (`RingMethod`) rather than being fully populated up front:
    /// `push` appends at the back, evicting the oldest element once `len`
    /// reaches `N` (a sliding window over the most recent `N` pushes,
    /// matching the "history buffer" use case) rather than silently no-op'ing
    /// like an out-of-bounds `List` write; `pop` removes and returns the
    /// oldest (front) element, mirroring a FIFO queue. `ring[i]` reads the
    /// `i`-th-oldest live element (`0` = oldest), bounds-checked against the
    /// current `len`, not the static capacity `N` -- see
    /// `crate::codegen::ring`'s module doc comment for the full invariant
    /// (every slot outside the live `[head, head+len)` window is always the
    /// element type's zero value) that keeps this RC-safe under the same
    /// blanket retain/release walk `Ty::Array` uses.
    Ring(Box<Ty>, u64),
    /// A struct-of-arrays table `Table<T>`: complements an arena's
    /// array-of-structs layout for cache-batch AAA systems -- `T` must be a
    /// plain (non-generic-template) declared `struct`; its *fields*, not
    /// `T` itself, are what get stored, one parallel growable column per
    /// field (`Codegen::table_payload_llvm_ty`: `{ i64 len, i64 cap, F0*,
    /// F1*, ... }`). Lowers to the same reference-counted, copy-on-write
    /// `i8*` object pointer scheme as `Ty::List`/`Ty::Map`/`Ty::Set` -- see
    /// `crate::codegen::table` -- just with `N` parallel data buffers
    /// (growing/shrinking in lockstep) instead of one. `table[i]`/
    /// `table[i] = v` read/write the whole element, reassembling it from (or
    /// decomposing it into) every column at index `i`; there is no
    /// dedicated `Codegen::emit_place` support for projecting a single
    /// field through a table index -- a single field's storage in this
    /// layout is a real, independently addressable column slot, but reaching
    /// it correctly would need its own dedicated place path, left for a
    /// future round; in the meantime `Checker::writes_through_table_index`
    /// rejects `table[i].field = v` (and any mutating collection-method call
    /// reached the same way) at type-check time rather than let it silently
    /// target a disconnected temporary, the naive fallback's behavior (and
    /// still what happens for any other rvalue struct base with no
    /// addressable storage of its own).
    Table(Box<Ty>),
    /// A generation-checked resource handle: `Handle<T>`. Nominally distinct
    /// from `Ty::GenRef` (so a function expecting `Handle<Texture>` rejects
    /// a `GenRef<Player>`-shaped argument, and vice versa) but otherwise a
    /// full reuse of the exact same arena/slot-map machinery -- same `%GenRef`
    /// LLVM layout, same generation-check codegen (`Codegen::emit_genref_create`/
    /// `emit_genref_index`/`emit_genref_index_place`), same `arena Name: T`
    /// backing declaration. Where `GenRef<T>` models references between
    /// spatial-arena entities (the "Game Graph"), `Handle<T>` models engine
    /// resources (`Handle<Texture>`, `Handle<Mesh>`, `Handle<Shader>`,
    /// `Handle<Sound>`): a freed resource's handle fails the same safe
    /// generation-check path instead of segfaulting on a dangling GPU/audio
    /// pointer -- see design.md's "Resource handles" section.
    Handle(Box<Ty>),
    /// A fieldless enum type, lowered to a plain `i32` discriminant.
    Enum(String),
    /// A closure/lambda's type: declared parameter types and return type.
    /// Lowered to a `{ i8* fn_ptr, i8* env_ptr }` "fat pointer" pair -- see
    /// `crate::codegen::Codegen::emit_closure_lit`.
    Closure(Vec<Ty>, Box<Ty>),
    /// An opaque foreign pointer (`ptr`), lowered to a bare `i8*` with no RC
    /// header -- unlike `Ty::Str`, a `Ty::Ptr` value is never
    /// retained/released (see `contains_rc`). Exists for `extern "C"` FFI:
    /// C handles/buffers/`char*` results that don't fit any other Star type.
    /// See `crate::codegen::builtins`'s `null_ptr`/`is_null`/`ptr_to_str`.
    Ptr,
    /// `Wrapping<T>`: silent-overflow arithmetic, the explicit opt-in for
    /// wraparound behavior (register/audio-counter emulation) that every
    /// other numeric type now traps on by default (see `Ty::I8`'s doc
    /// comment) -- `docs/design.md`'s "Numeric widths and modes". `T` is
    /// restricted to any `int_shape()`-having type (validated in
    /// `Checker::resolve_type`). Lowers to the *exact same* LLVM integer type
    /// as `T` -- zero overhead, no tag -- mirroring how `Ty::Handle` reuses
    /// `Ty::GenRef`'s layout (see `crate::codegen::wrapping`). Deliberately
    /// excluded from `is_numeric()`/`int_shape()`: those also gate
    /// `sqrt`/`abs`/`pow`/FFI-scalar eligibility, none of which make sense
    /// for a "wrapping register" -- instead `+`/`-`/`*`/`/`/`%`/comparisons
    /// get their own dedicated dispatch branch (`Checker::infer_binop_ty`,
    /// `Codegen::emit_binop`), the same way `Vec2`/`Vec3`/`Vec4`/`Mat4`/
    /// `char`/`ptr` each already do rather than piggybacking on the numeric
    /// fast path.
    Wrapping(Box<Ty>),
    /// Deterministic fixed-point `Fixed<Bits, Frac>` (e.g. `Fixed<32,16>`):
    /// lockstep simulation/rollback netcode where float non-determinism is a
    /// correctness bug, not a rounding nit -- `docs/design.md`'s "Numeric
    /// widths and modes". `Bits` is restricted to `{8, 16, 32, 64}` (the
    /// widths this compiler's int codegen already understands) and `Frac` to
    /// `0..Bits` (validated in `Checker::resolve_type`). Lowers to a bare
    /// `i{Bits}` (Q format, signed) -- zero overhead, like `Ty::I8` -- see
    /// `crate::codegen::fixed`. `+`/`-` are plain checked (trapping)
    /// `i{Bits}` add/sub (no rescaling needed at that precision); `*`/`/`
    /// rescale by widening through `i128` unconditionally (sign-extend,
    /// multiply-or-shift-then-divide, truncate back with an overflow check)
    /// rather than doubling `Bits` itself, so constructing/computing a
    /// narrow `Fixed<8,4>` from a wider source int is never a correctness
    /// hazard. Like `Ty::Wrapping`, deliberately excluded from
    /// `is_numeric()`/`int_shape()` -- gets its own dedicated dispatch
    /// branch instead. No `%` (rejected by the checker -- not a meaningful
    /// fixed-point op) and no int<->`Fixed` cast (only `Fixed<->Float`/`F64`,
    /// a true scaled conversion, not a bit-reinterpret); construction is the
    /// only int entry point.
    Fixed(u32, u32),
    /// An integer simulation-step counter, matching `sequence`'s existing
    /// tick model -- `docs/design.md`'s "Time" section. Lowers to a bare
    /// `i64` -- zero overhead, like `Ty::I64` -- see `crate::codegen::time`.
    /// Deliberately a distinct nominal type from `Ty::I64` itself (not just
    /// an alias), same reasoning as `Ty::Handle` vs `Ty::GenRef`: a `Tick`
    /// value can't be silently swapped for an arbitrary 64-bit integer (a
    /// frame-time delta, an entity count, ...) at a call boundary. Supports
    /// `Tick + i64 -> Tick`/`Tick - i64 -> Tick` (advance/rewind by a step
    /// count), `Tick - Tick -> i64` (a tick delta), and comparisons against
    /// another `Tick` -- see `Checker::infer_time_binop_ty`. Construction
    /// (`Tick(value)`) accepts any `int_shape()`-having value, widened/
    /// narrowed to `i64`. Like `Ty::Wrapping`/`Ty::Fixed`, deliberately
    /// excluded from `is_numeric()`/`int_shape()` -- it gets its own
    /// dedicated binop dispatch branch instead.
    Tick,
    /// A wall-clock time span, e.g. `i64` nanoseconds -- `docs/design.md`'s
    /// "Time" section. Lowers to a bare `i64`, same reasoning as `Ty::Tick`.
    /// Keeping this distinct from a bare `f32`/`i64` delta-time avoids the
    /// drift and non-determinism bugs that break replay recording and
    /// rollback netcode (mixing a raw tick count with a raw nanosecond count
    /// at a call site is a real correctness hazard the type system can catch
    /// for free). Supports `Duration + Duration -> Duration`/
    /// `Duration - Duration -> Duration` and comparisons against another
    /// `Duration`. Construction (`Duration(value)`) accepts any
    /// `int_shape()`-having value, widened/narrowed to `i64` (the
    /// nanosecond count). See `Ty::Tick`'s doc comment for why this isn't
    /// folded into `is_numeric()`/`int_shape()`.
    Duration,
    /// A monotonic timestamp -- `docs/design.md`'s "Time" section. Lowers to
    /// a bare `i64`, same reasoning as `Ty::Tick`/`Ty::Duration`. Supports
    /// `Instant - Instant -> Duration` (elapsed time), `Instant + Duration
    /// -> Instant`/`Instant - Duration -> Instant`, and comparisons against
    /// another `Instant` -- mirrors Rust's own `std::time::Instant` operator
    /// set. Construction (`Instant(value)`) accepts any `int_shape()`-having
    /// value, widened/narrowed to `i64`. See `Ty::Tick`'s doc comment for why
    /// this isn't folded into `is_numeric()`/`int_shape()`.
    Instant,
    /// An owned, growable byte buffer -- `docs/design.md`'s "Text and bytes"
    /// section: asset formats, binary save data, and network payloads that
    /// aren't text, distinct from `Ty::Str` (which is always a null-terminated
    /// UTF-8-ish C string used by `strlen`/`strcmp`/`printf`'s `%s`). Rather
    /// than invent a new heap layout, `Bytes` reuses `List<u8>`'s exact
    /// reference-counted, copy-on-write `i8*` object-pointer scheme wholesale
    /// (same `{ u8*, i64, i64 }` payload, same `push`/`pop`/`len`/`[i]`
    /// method surface, routed through the very same `crate::codegen::list`
    /// functions called with `elem_ty = Ty::U8`) -- the only difference is
    /// `Ty::Bytes` is a nominally distinct type from `Ty::List(Ty::U8)` (so a
    /// function declared to take `Bytes` rejects a `List<u8>` argument and
    /// vice versa, mirroring `Ty::Handle` vs. `Ty::GenRef`), and it's
    /// constructed as a plain non-generic `Bytes()` literal rather than
    /// through `List<T>`'s turbofish. `bytes_from_str`/`str_from_bytes`
    /// (`crate::codegen::list`) convert to/from `Ty::Str` by copying bytes,
    /// since the two have different heap representations (a `Bytes` isn't
    /// null-terminated and is never passed to `strlen`/`%s`).
    Bytes,
    /// An interned string with O(1) equality comparison -- `docs/design.md`'s
    /// "Text and bytes" section: at AAA entity counts, comparing tags/event
    /// names with a byte-for-byte `str` compare every frame is a real cost.
    /// Lowers to a bare `i64` id into a single process-wide intern table
    /// (`crate::codegen::symbol`, `@sym.data`/`@sym.len`/`@sym.cap`) --
    /// zero overhead beyond the one table, like `Ty::Tick`. `Symbol(s)`
    /// interns `s` (a linear `strcmp` scan against every already-interned
    /// string -- the same "no hashing yet" honesty `Map`/`Set` already have,
    /// see `crate::codegen::map`'s doc comment -- so *construction* cost
    /// grows with the table size), returning its id; every *comparison*
    /// between two already-constructed `Symbol` values is then a single
    /// `icmp eq i64`, which is the O(1) guarantee this type actually
    /// promises. Deliberately excluded from `is_numeric()`/`int_shape()`
    /// (same reasoning as `Ty::Tick`) -- only `==`/`!=` are supported
    /// (no ordering: interning order is an implementation detail, not a
    /// meaningful sort), dispatched through their own dedicated branch
    /// rather than the numeric fast path. `Symbol <-> i64` is a free
    /// bit-preserving relabel via `as`, same as `Ty::Tick <-> i64`, for
    /// interop/debugging (e.g. printing the raw id). `symbol_name(sym) ->
    /// str` (`crate::codegen::symbol`) reverses the lookup, retaining a
    /// fresh, independently-owned copy of the table's permanent string
    /// reference. A legal `Map`/`Set` key (`Checker::check_hashable_ty`),
    /// unlike `Bytes`/`List<T>` -- comparison is just an integer compare.
    Symbol,
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

    /// True for every scalar numeric type -- the original `Int`/`Float`
    /// pair plus every explicit-width addition from `docs/design.md`'s
    /// "Numeric widths and modes". `Ty::Char` is deliberately excluded (it
    /// supports comparisons but not arithmetic, mirroring Rust's `char`).
    pub fn is_numeric(&self) -> bool {
        matches!(
            self,
            Ty::Int | Ty::Float | Ty::I8 | Ty::U8 | Ty::I16 | Ty::U16 | Ty::U32 | Ty::I64 | Ty::U64 | Ty::F64
        )
    }

    /// `Some((bit_width, is_signed))` for every integer type (the original
    /// `Ty::Int` -- Star's default 32-bit signed integer -- plus every
    /// explicit sized-width addition); `None` for `Ty::Float`/`Ty::F64`
    /// (no integer bit-width/signedness) and every non-numeric type.
    /// Drives `Codegen::emit_sized_int_binop`'s width/signedness-generic
    /// arithmetic lowering (opcodes, overflow-trap intrinsics, comparison
    /// predicates) so there's exactly one place that maps a `Ty` to its
    /// concrete LLVM integer shape, instead of one hardcoded `i32` path per
    /// type.
    pub fn int_shape(&self) -> Option<(u32, bool)> {
        match self {
            Ty::Int => Some((32, true)),
            Ty::I8 => Some((8, true)),
            Ty::U8 => Some((8, false)),
            Ty::I16 => Some((16, true)),
            Ty::U16 => Some((16, false)),
            Ty::U32 => Some((32, false)),
            Ty::I64 => Some((64, true)),
            Ty::U64 => Some((64, false)),
            _ => None,
        }
    }
}

/// Synthesizes the `Option<T>`/`Result<T,E>` generic-enum templates as if
/// they'd been parsed from source (`enum Option<T>: None / Some(value: T)`,
/// `enum Result<T,E>: Ok(value: T) / Err(error: E)`), so `Checker::check` can
/// register them into `generic_enums` before any user code is scanned. See
/// that call site's doc comment for why this makes them true compiler
/// builtins rather than user-space library code.
fn builtin_generic_enums() -> Vec<EnumDef> {
    vec![
        EnumDef {
            name: "Option".into(),
            type_params: vec!["T".into()],
            variants: vec![
                EnumVariantDef { name: "None".into(), fields: Vec::new(), span: Span::dummy() },
                EnumVariantDef {
                    name: "Some".into(),
                    fields: vec![EnumFieldDef { name: "value".into(), ty: Type::Named("T".into()) }],
                    span: Span::dummy(),
                },
            ],
            span: Span::dummy(),
        },
        EnumDef {
            name: "Result".into(),
            type_params: vec!["T".into(), "E".into()],
            variants: vec![
                EnumVariantDef {
                    name: "Ok".into(),
                    fields: vec![EnumFieldDef { name: "value".into(), ty: Type::Named("T".into()) }],
                    span: Span::dummy(),
                },
                EnumVariantDef {
                    name: "Err".into(),
                    fields: vec![EnumFieldDef { name: "error".into(), ty: Type::Named("E".into()) }],
                    span: Span::dummy(),
                },
            ],
            span: Span::dummy(),
        },
    ]
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
        // `chr`/`ord`: byte <-> length-1-`str` conversions, the natural
        // complement to `s[i]` (`Expr::GenRefIndex`'s `Ty::Str` case)
        // returning a byte rather than a substring -- see
        // `crate::codegen::builtins::emit_chr`/`emit_ord`.
        "chr" => Some(Ty::Str),
        "ord" => Some(Ty::Int),
        // `docs/design.md`'s "Text and bytes" section: `Bytes`/`Str`
        // conversion (a real byte copy, since the two have different heap
        // representations -- see `Ty::Bytes`'s doc comment) and `Symbol`'s
        // reverse-interning lookup -- see `crate::codegen::list`/
        // `crate::codegen::symbol`.
        "bytes_from_str" => Some(Ty::Bytes),
        "str_from_bytes" => Some(Ty::Str),
        "symbol_name" => Some(Ty::Str),
        // Reads one line of text from stdin (trailing newline stripped, EOF
        // yielding whatever was read so far -- possibly empty). See
        // `crate::codegen::builtins::emit_read_line`.
        "read_line" => Some(Ty::Str),
        // `dot`/`length`: Vec2/Vec3/Vec4 math the codegen already had the
        // primitives for (`emit_dot4` existed internally to implement
        // `Mat4 * Vec4`) but exposed to no user-callable builtin.
        "dot" | "length" => Some(Ty::Float),
        // `lerp`/`clamp` preserve their first argument's type (Float or a
        // Vec2/Vec3/Vec4 for `lerp`; Int or Float for `clamp`).
        "lerp" | "clamp" => Some(args.first().map(|a| a.clone().into_ty()).unwrap_or(Ty::Float)),
        // Deterministic, seeded PRNG (xorshift32) -- matters specifically
        // for a tick-based engine where determinism/replay is often a
        // design goal (see `@rng.state`'s own doc comment).
        "rand" => Some(Ty::Float),
        "rand_range" => Some(Ty::Int),
        "rand_seed" => Some(Ty::Named("unknown".into())),
        // `extern "C"` FFI helpers -- see `crate::codegen::builtins` for
        // their lowering and `Checker::check_extern_fn` for why a returned
        // `char*` must be bridged through `ptr_to_str` rather than treated
        // as `str` directly.
        "null_ptr" => Some(Ty::Ptr),
        "is_null" => Some(Ty::Bool),
        "ptr_to_str" => Some(Ty::Str),
        // File I/O builtins -- see `crate::codegen::file_io`. `file_open`
        // reuses `Ty::Ptr` as an opaque file handle (null on failure, same
        // convention as `getenv`); `file_read`/`file_read_line` return an
        // empty `str` on EOF (same convention as `read_line`).
        "file_open" => Some(Ty::Ptr),
        "file_close" => Some(Ty::Named("unknown".into())),
        "file_read" | "file_read_line" => Some(Ty::Str),
        "file_write" | "file_exists" => Some(Ty::Bool),
        // Minimal OS surface (todo.md #2) -- see `crate::codegen::list::emit_args`
        // and `crate::codegen::os`. `args()` includes `argv[0]` (the program
        // path/name), same convention the underlying OS argv itself uses.
        // `env_get` yields `""` for an unset variable rather than a null
        // `ptr`, matching `file_read`/`read_line`'s established EOF
        // convention instead of introducing an Option/Result type Star
        // doesn't have.
        "args" => Some(Ty::List(Box::new(Ty::Str))),
        "env_get" => Some(Ty::Str),
        "env_set" => Some(Ty::Bool),
        // Raw TCP socket builtins (todo.md #3 "Networking basics") -- see
        // `crate::codegen::net`. `tcp_connect` reuses `Ty::Ptr` as an
        // opaque socket handle (null on failure, same convention as
        // `file_open`); `tcp_recv` returns an empty `str` on a closed
        // connection/error (same convention as `file_read`).
        "tcp_connect" => Some(Ty::Ptr),
        "tcp_send" => Some(Ty::Bool),
        "tcp_recv" => Some(Ty::Str),
        "tcp_close" => Some(Ty::Named("unknown".into())),
        _ => None,
    }
}

/// True for any name `builtin_return_ty` recognizes -- shared with
/// `Checker::check_extern_fn`'s reserved-name check so the two lists can
/// never drift apart. A real argument list isn't needed to answer "is this
/// name a builtin at all", so an empty slice is always safe to pass here:
/// every arm of `builtin_return_ty` only inspects `args` to pick a *type*
/// (e.g. `abs`'s int-vs-float result), never to decide whether to return
/// `None` in the first place.
fn is_builtin_name(name: &str) -> bool {
    builtin_return_ty(name, &[]).is_some()
}

/// Every symbol name `Codegen::emit_builtins`/`emit_rc_runtime` unconditionally
/// `declare`s or `define`s at the top of *every* generated module (the CRT/
/// Win32 imports backing `print`/math/file-I/O/`par`/`swarm`, plus the RC
/// runtime's own three functions), and the reserved entry point `main`.
/// LLVM's textual IR parser (unlike, say, C's own header-guard-tolerant
/// redeclaration rules) rejects a *second* `declare`/`define` for the same
/// global name outright -- even one that's byte-for-byte identical to the
/// first -- so an `extern "C" fn` reusing one of these names always fails at
/// the clang step with an opaque "invalid redefinition of function" pointing
/// at generated IR the user never wrote, regardless of whether their
/// declared signature happens to match. Kept as one flat list (rather than
/// deriving it from `emit_builtins` itself) since the two are in different
/// crate modules and the set rarely changes; see `check_extern_fn`.
const RESERVED_RUNTIME_SYMBOLS: &[&str] = &[
    "main",
    "printf", "puts", "malloc", "free", "exit", "strlen", "getchar", "memcpy", "strcpy", "strcat",
    "fopen", "fclose", "fread", "fwrite", "fseek", "ftell", "fgetc",
    // `str`-keyed `Map`/`Set` structural equality -- see `crate::codegen::eq`.
    "strcmp",
    "CreateThread", "WaitForSingleObject", "CloseHandle",
    "CreateSemaphoreA", "ReleaseSemaphore", "GetCurrentThreadId",
    "star_rc_alloc", "star_rc_retain", "star_rc_release",
    // `env_get`/`env_set` builtins -- see `crate::codegen::os`.
    "getenv", "_putenv_s",
    // `tcp_connect`/`tcp_send`/`tcp_recv`/`tcp_close` builtins -- see
    // `crate::codegen::net`.
    "WSAStartup", "socket", "connect", "send", "recv", "closesocket", "htons", "inet_addr",
    // Materializes a non-print f-string value (`let s = f"..."`) into an
    // owned `str` buffer -- see `Codegen::emit_expr`'s `TypedExpr::FStr` arm.
    "snprintf",
];

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
    /// Impl-method signatures: maps `"{struct_name}#{method_name}"` ->
    /// (param_tys including the receiver, ret_ty). Kept separate from
    /// `functions` (which used to also hold methods, keyed by bare method
    /// name) because two unrelated structs can declare a method with the
    /// same name and different signature -- with a single flat table, the
    /// second `impl` block's registration silently overwrote the first,
    /// so `a.area()` on a struct `A` could get argument/return-type checked
    /// against a same-named method on an unrelated struct `B`, and codegen
    /// (which *does* dispatch per-struct, via its own analogous
    /// `Codegen::methods` map) emitted two colliding `define @area(...)`
    /// globals for the same LLVM function name, failing at the `clang` step
    /// with "invalid redefinition of function". See `check_impl` for
    /// population and `Expr::Call`'s method-call arm for lookup.
    /// The `bool` is whether the method actually declares `self` as its
    /// first parameter -- a method is free to omit it entirely (an
    /// "associated function" with no receiver, callable only via
    /// `obj.method(...)` syntax like any other method), so callers must not
    /// assume the call's syntactic shape alone tells them whether to skip a
    /// `self` argument (see `check_call_args`'s call sites).
    methods: HashMap<String, (Vec<Ty>, Option<Ty>, bool)>,
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
    /// Mangled instantiated-function name (`sneaky__i32`) -> its generic
    /// template name (`sneaky`), mirroring `mono_struct_of`/`mono_enum_of`
    /// above. Needed so `par_analysis::walk_par_expr`'s `unsafe_par_fns`
    /// hazard check (keyed by the *template's* declared name, computed
    /// up front from the raw AST -- see `compute_unsafe_par_fns`) can still
    /// recognize a call to a generic function/method by its mangled,
    /// monomorphized name: without this, `self.unsafe_par_fns.contains(name)`
    /// always misses for any generic hazard, since the call site only ever
    /// sees the mangled name, never the template name the hazard set was
    /// built from.
    mono_fn_of: HashMap<String, String>,
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
    /// Names, within the function currently being checked, of every binding
    /// (parameter or `let`) declared `mut` -- `Stmt::Assign`'s target must
    /// resolve back to one of these (see `assign_root_name`) or it's an
    /// assignment into an immutable binding. Reset per-function in
    /// `check_block` (mirrors `vars`' own per-function reset), since `mut`
    /// is a property of one specific binding, never global.
    mut_vars: HashSet<String>,
    /// Names of every free function/method whose body -- directly, or
    /// transitively through any call it makes -- contains a `spawn`,
    /// `despawn`, or `frame:` statement. Computed once, up front, from the
    /// raw (untyped) AST before any item is checked (see
    /// `compute_unsafe_par_fns`), so `par`/`swarm` disjointness checking
    /// (`par_analysis::walk_par_expr`) can reject a call to one of these
    /// regardless of declaration order or how many calls deep the hazard is
    /// nested -- closing the "move the `spawn` one level into a helper
    /// function" hole in the textual-ban approach.
    unsafe_par_fns: HashSet<String>,
    /// The enclosing function/method's declared return type, used to
    /// type-check `return` statements (§1.3's hole: previously `return`'s
    /// value was never compared against the function's declared return
    /// type at all, and codegen emitted `ret <ty-of-the-returned-expr>`
    /// rather than `ret <declared-ty>`, so a mismatch reached codegen as a
    /// function whose declared LLVM signature and actual terminator
    /// disagree). Three states:
    /// - `None`: not currently checking a `return`-checkable body (e.g.
    ///   inside a closure literal, whose own return type is inferred *from*
    ///   its body -- checking `return` against it would be circular, so
    ///   it's simplest and safest to just suspend checking there).
    /// - `Some(None)`: inside a function with no declared return type (a
    ///   bare `return` is fine; `return <value>` is not).
    /// - `Some(Some(ty))`: inside a function declared to return `ty`.
    current_ret_ty: Option<Option<Ty>>,
    /// Names of every `extern "C" fn` already checked, so a second
    /// declaration under the same name is caught here with a clear
    /// diagnostic instead of surfacing as clang's opaque "invalid
    /// redefinition of function" once the (byte-for-byte identical, in this
    /// case) duplicate `declare` reaches the LLVM parser -- see
    /// `check_extern_fn`.
    extern_fn_names_seen: HashSet<String>,
    /// Current nesting depth of generic struct/enum/fn monomorphization
    /// (`instantiate_struct`/`instantiate_enum`/`instantiate_fn`), each of
    /// which increments this for the duration of instantiating one
    /// template and checking its (substituted) body. A *literal*
    /// self-referential generic (`struct Wrap<T>: v: Wrap<T>`) is already
    /// caught by memoizing on the mangled name before recursing -- but a
    /// field/call that wraps the type parameter in another generic each
    /// step (`struct Node<T>: next: Node<Box<T>>`, or a generic function
    /// that recursively calls itself with a wrapped argument type) produces
    /// a *new* mangled name every time, so the memo check never fires and
    /// the checker recurses through Rust's own call stack forever --
    /// previously an unguarded stack-overflow ICE on four lines of valid-
    /// looking source, with no diagnostic at all. This bounds that
    /// recursion to a clean error instead (see `MAX_MONO_DEPTH`).
    mono_depth: u32,
    /// Struct name -> declared parameter count, for every `sequence`
    /// (before `crate::sequence::desugar_module` turns it into a plain
    /// `struct`+`impl` pair -- see that module's doc comment). A sequence's
    /// desugared struct also carries its hoisted top-level locals and a
    /// trailing `state: i32` field, none of which the `Name(...)` call site
    /// ever supplies (codegen zero-fills them, see `Codegen::zero_value`), so
    /// `check_struct_ctor_args` needs this to validate only the leading
    /// parameter fields' types/arity against a sequence constructor call
    /// rather than the full desugared field list.
    sequence_param_counts: HashMap<String, usize>,
}

impl Checker {
    pub fn new() -> Self {
        Self {
            structs: HashMap::new(),
            traits: HashMap::new(),
            arenas: HashMap::new(),
            enums: HashMap::new(),
            functions: HashMap::new(),
            methods: HashMap::new(),
            generic_structs: HashMap::new(),
            generic_enums: HashMap::new(),
            generic_fns: HashMap::new(),
            mono_struct_of: HashMap::new(),
            mono_enum_of: HashMap::new(),
            mono_fn_of: HashMap::new(),
            mono_items: Vec::new(),
            errors: Vec::new(),
            loop_depth: 0,
            mut_vars: HashSet::new(),
            unsafe_par_fns: HashSet::new(),
            current_ret_ty: None,
            extern_fn_names_seen: HashSet::new(),
            mono_depth: 0,
            sequence_param_counts: HashMap::new(),
        }
    }

    /// A generous bound on nested generic monomorphization -- see
    /// `mono_depth`'s doc comment. High enough that no real, terminating
    /// generic usage (including deliberately nested wrappers a few levels
    /// deep) should ever hit it, but low enough to fail fast with a clean
    /// diagnostic well before exhausting the real Rust call stack.
    const MAX_MONO_DEPTH: u32 = 64;

    /// The largest element count a single `[T; N]`/`Ring<T, N>` node may
    /// declare. Both are stored inline (no RC header, no heap allocation of
    /// their own -- see `Ty::Array`/`Ty::Ring`'s doc comments), so `N` flows
    /// unchecked into: `Codegen::emit_array_repeat`'s `for i in 0..count`
    /// loop, which emits one GEP+store *pair of LLVM IR text lines* per
    /// element (confirmed hanging for 30+ seconds and counting, with no
    /// `.ll` file ever written, on `[0; 999999999999]` -- a single line of
    /// otherwise-valid source); and `Codegen::type_size`'s
    /// `self.type_size(elem) * *count as u32`, a plain (unchecked, silently
    /// wrapping in a release build) `u32` multiply that can under-report a
    /// huge array's real size once `count` no longer fits `u32`. A million
    /// elements is already far beyond any realistic inline fixed-size
    /// buffer (particle systems, tile grids, input-replay ring buffers) --
    /// anything larger belongs in a heap-backed `List<T>`/`Table<T>`
    /// instead, which has no per-element codegen loop or fixed-size LLVM
    /// array type at all.
    const MAX_INLINE_LEN: u64 = 1_000_000;

    pub fn check(&mut self, module: &Module) -> Result<TypedModule, Vec<Diagnostic>> {
        // Record each `sequence`'s declared parameter count from the raw
        // AST *before* desugaring erases the distinction between a sequence's
        // struct and an ordinary one (see `sequence_param_counts`'s own doc
        // comment) -- `check_struct_ctor_args` needs this to validate a
        // sequence constructor call correctly.
        for item in &module.items {
            if let Item::Sequence(seq) = item {
                self.sequence_param_counts.insert(seq.name.clone(), seq.params.len());
            }
        }
        // `sequence` items are pure syntax sugar over struct+impl (see
        // `crate::sequence`); desugar them before any of the checks below
        // ever see an `Item::Sequence`.
        let (module, desugar_errors) = crate::sequence::desugar_module(module);
        if !desugar_errors.is_empty() {
            return Err(desugar_errors);
        }

        // Precompute, from the raw AST, every function/method that
        // (transitively) performs an operation `par`/`swarm`'s disjointness
        // proof can't see through -- see `compute_unsafe_par_fns` and
        // `unsafe_par_fns`'s own doc comment. Must happen before any item is
        // checked so a `par` body can reject a call to a not-yet-checked
        // function declared later in the file.
        self.unsafe_par_fns = compute_unsafe_par_fns(&module);

        // Duplicate-name detection for the two namespaces a top-level
        // declaration's mangled name is emitted into at codegen time: every
        // struct/enum (generic or not) becomes (or, once monomorphized,
        // instantiates into) an LLVM named type `%Name`, and every
        // (non-generic) `fn` becomes an LLVM function symbol `@Name`. Two
        // declarations landing on the same name within a namespace -- most
        // commonly two different files imported under the *same* alias that
        // each declare a same-named item, since `crate::modules::rename_module`
        // mangles both to the identical `alias__name` (but equally reachable
        // by just writing the same top-level name twice in one file) --
        // previously went undetected here entirely: `HashMap::insert` below
        // silently let the second declaration win, and the collision only
        // ever surfaced once both reached the LLVM parser as clang's opaque
        // "invalid redefinition of type/function", pointing at generated IR
        // the user never wrote rather than at their own source. An
        // `extern "C" fn` colliding with an ordinary `fn`'s name in the same
        // file shares this exact namespace (both land on the plain LLVM
        // function symbol `@name`, an extern's `declare` and a plain fn's
        // `define`), so it's folded into the same `value_names_seen` check
        // below rather than left as a gap -- confirmed via a real `star
        // build`: `extern "C" fn myfunc(x: i32) -> i32` plus `fn myfunc(x:
        // i32) -> i32: ...` in one file both type-checked cleanly with no
        // diagnostic at all, then failed at the `clang` step with "invalid
        // redefinition of function 'myfunc'" pointing at generated IR the
        // user never wrote. extern-fn-vs-extern-fn (the identical-signature,
        // same-name, same-file case) is already caught separately by
        // `extern_fn_names_seen`, which also supplies its own, more specific
        // diagnostic -- so `RESERVED_RUNTIME_SYMBOLS`-collisions and
        // extern-vs-extern duplicates recorded in `extern_fn_names_seen`
        // below are *not* also double-reported through `value_names_seen`.
        let mut type_names_seen: HashSet<String> = HashSet::new();
        let mut value_names_seen: HashSet<String> = HashSet::new();
        let mut arena_names_seen: HashSet<String> = HashSet::new();
        // Tracks `extern "C" fn` names seen so far in pass 1, purely to
        // detect a collision with an ordinary `fn` of the same name (see the
        // `value_names_seen` doc comment above) regardless of which one
        // appears first in the source. Deliberately *not* used to detect an
        // extern-vs-extern name collision -- `check_extern_fn`'s own
        // `extern_fn_names_seen` (populated in the later per-item checking
        // pass) already reports that case with a more specific diagnostic,
        // and folding it in here too would double-report it.
        let mut extern_fn_names_seen_pass1: HashSet<String> = HashSet::new();

        // Pre-register `Option<T>`/`Result<T,E>` as compiler builtins (see
        // docs/design.md's "Type System" §9): ordinary generic-enum
        // templates, synthesized here in Rust instead of parsed from source,
        // so they share 100% of the existing generic-enum monomorphization
        // (`instantiate_enum`) and tagged-union codegen machinery -- no new
        // mechanism at all. Seeding `type_names_seen` up front means a user
        // module that also declares `enum Option<T>`/`enum Result<T,E>` hits
        // the ordinary "declared more than once" diagnostic below (pass 0)
        // instead of silently shadowing or overwriting the builtin.
        for def in builtin_generic_enums() {
            type_names_seen.insert(def.name.clone());
            self.generic_enums.insert(def.name.clone(), def);
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
                Item::Struct(s) if !s.type_params.is_empty() => {
                    if !type_names_seen.insert(s.name.clone()) {
                        self.error(format!("the type `{}` is declared more than once", s.name), s.span);
                    }
                    self.generic_structs.insert(s.name.clone(), s.clone());
                }
                Item::Struct(s) => {
                    if !type_names_seen.insert(s.name.clone()) {
                        self.error(format!("the type `{}` is declared more than once", s.name), s.span);
                    }
                    self.structs.insert(s.name.clone(), s.clone());
                }
                Item::Enum(e) if !e.type_params.is_empty() => {
                    if !type_names_seen.insert(e.name.clone()) {
                        self.error(format!("the type `{}` is declared more than once", e.name), e.span);
                    }
                    self.generic_enums.insert(e.name.clone(), e.clone());
                }
                Item::Enum(e) => {
                    if !type_names_seen.insert(e.name.clone()) {
                        self.error(format!("the type `{}` is declared more than once", e.name), e.span);
                    }
                    self.enums.insert(e.name.clone(), e.clone());
                }
                Item::Fn(f) if !f.sig.type_params.is_empty() => {
                    if !value_names_seen.insert(f.sig.name.clone()) {
                        self.error(format!("the function `{}` is declared more than once", f.sig.name), f.span);
                    }
                    self.generic_fns.insert(f.sig.name.clone(), f.clone());
                }
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
                    if !arena_names_seen.insert(a.name.clone()) {
                        self.error(format!("the arena `{}` is declared more than once", a.name), a.span);
                    }
                    let ty = self.resolve_type(&a.ty).unwrap_or(Ty::Named("unknown".into()));
                    self.arenas.insert(a.name.clone(), ty);
                }
                Item::Fn(f) if f.sig.type_params.is_empty() => {
                    // The second half of this check (`extern_fn_names_seen_pass1`)
                    // catches an ordinary `fn` colliding with an `extern "C"
                    // fn` of the same name declared *earlier* in this file --
                    // see the `value_names_seen` doc comment above for why
                    // that's a real, reproduced bug (a clean diagnostic here
                    // instead of clang's opaque "invalid redefinition of
                    // function" at the very end of the pipeline).
                    if !value_names_seen.insert(f.sig.name.clone()) || extern_fn_names_seen_pass1.contains(&f.sig.name) {
                        self.error(format!("the function `{}` is declared more than once", f.sig.name), f.span);
                    }
                    let param_tys: Vec<Ty> = f.sig.params.iter().map(|p| {
                        p.ty.as_ref().and_then(|t| self.resolve_type(t)).unwrap_or(Ty::Named("infer".into()))
                    }).collect();
                    let ret_ty = f.sig.ret.as_ref().and_then(|t| self.resolve_type(t));
                    self.functions.insert(f.sig.name.clone(), (param_tys, ret_ty));
                }
                Item::Fn(_) => {}
                Item::ExternFn(e) => {
                    // Mirror of the check above for the opposite declaration
                    // order (an ordinary `fn` declared *before* the `extern
                    // "C" fn` of the same name). `value_names_seen` at this
                    // point holds every generic-or-not ordinary `fn` name
                    // seen so far (pass 0 already ran fully, and pass 1 is a
                    // single left-to-right loop), so this also naturally
                    // catches a collision with a generic `fn`.
                    if value_names_seen.contains(&e.sig.name) {
                        self.error(format!("the function `{}` is declared more than once", e.sig.name), e.span);
                    }
                    extern_fn_names_seen_pass1.insert(e.sig.name.clone());
                    let param_tys: Vec<Ty> = e.sig.params.iter().map(|p| {
                        p.ty.as_ref().and_then(|t| self.resolve_type(t)).unwrap_or(Ty::Named("infer".into()))
                    }).collect();
                    let ret_ty = e.sig.ret.as_ref().and_then(|t| self.resolve_type(t));
                    self.functions.insert(e.sig.name.clone(), (param_tys, ret_ty));
                }
                Item::Impl(blk) => {
                    for m in &blk.methods {
                        let param_tys: Vec<Ty> = m.sig.params.iter().map(|p| {
                            p.ty.as_ref().and_then(|t| self.resolve_type(t)).unwrap_or(Ty::Named("infer".into()))
                        }).collect();
                        let ret_ty = m.sig.ret.as_ref().and_then(|t| self.resolve_type(t));
                        let has_self = m.sig.params.first().map(|p| p.is_self).unwrap_or(false);
                        let key = format!("{}#{}", blk.type_name, m.sig.name);
                        self.methods.insert(key, (param_tys, ret_ty, has_self));
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

        // Must run after monomorphized structs are appended above -- a
        // cycle can run entirely through a generic wrapper's instantiation
        // (e.g. `Box<Node>`, since `struct Box<T>: value: T` is a plain
        // by-value wrapper in this language, not a heap indirection) and
        // codegen never monomorphizes anything further after this point.
        self.check_no_recursive_structs(&typed_items);

        if self.errors.is_empty() {
            // Combine both mono-instantiation tables into the one map
            // `TypedModule` carries onward -- see its `generic_instantiations`
            // doc comment for why `Codegen` needs this at all (it never sees
            // `self`, only the `TypedModule` this function returns).
            // `mono_struct_of`/`mono_enum_of` are keyed from disjoint
            // namespaces in practice (a struct and enum can never share a
            // name -- both draw from the same `type_names_seen` duplicate
            // check earlier in this function), so a plain `extend` can't
            // silently drop either table's entries.
            let mut generic_instantiations = std::mem::take(&mut self.mono_struct_of);
            generic_instantiations.extend(std::mem::take(&mut self.mono_enum_of));
            Ok(TypedModule { items: typed_items, generic_instantiations })
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
            Item::ExternFn(e) => self.check_extern_fn(e),
        }
    }

    /// The types an `extern "C"` signature may use, in either parameter or
    /// return position -- everything else (struct/`List`/`GenRef`/`Enum`/
    /// `Closure`) has no defined C-ABI layout in this compiler and is
    /// rejected outright rather than silently emitting IR whose calling
    /// convention doesn't match the real foreign symbol.
    fn is_ffi_scalar_ty(ty: &Ty) -> bool {
        // Every explicit-width integer/float (`int8_t`/`uint32_t`/`double`/
        // ... in C terms) and `char` (a plain 4-byte codepoint, `i32`-shaped
        // at the ABI level) are as legitimate an FFI scalar as the original
        // `Ty::Int`/`Ty::Float` -- LLVM lowers a fixed (non-variadic)
        // `declare`'s narrow-integer parameters to the platform C ABI's
        // register-passing convention with no extra annotation needed.
        ty.is_numeric() || matches!(ty, Ty::Char | Ty::Ptr)
    }

    /// Type-check an `extern "C" fn` declaration: register (already done in
    /// `check`'s pass 1) and validate its signature, producing a body-less
    /// `TypedItem::ExternFn`. Unlike `check_fn`, this never calls
    /// `check_block` -- there is no body to check.
    fn check_extern_fn(&mut self, e: &ExternFnDecl) -> Option<TypedItem> {
        if e.abi != "C" {
            self.error(format!("unsupported extern ABI \"{}\"; only \"C\" is supported", e.abi), e.span);
        }
        if !e.sig.type_params.is_empty() {
            self.error("extern \"C\" functions cannot be generic", e.span);
        }
        // Star's grammar always parses `Name(args)` as a struct-literal
        // constructor when `Name` starts with an uppercase letter
        // (`Vec3(0, 0, 0)`, `Player(health = 100)`, ... -- see
        // `Parser::parse_primary`'s `starts_uppercase` check in
        // `src/parser/expr.rs`), regardless of whether any such struct is
        // actually declared. Since the declared name here must exactly
        // match the real foreign symbol (there's no rename/alias syntax),
        // an extern fn bound to an uppercase-starting C symbol (common in
        // the Win32 API, e.g. `CreateThread`) would parse at every call
        // site as an attempt to construct a nonexistent struct instead of
        // a call -- reported at the *call* site as a confusing "unknown
        // struct" error with no hint of the real cause. Catching it here,
        // at the declaration, gives an immediate and actionable diagnostic
        // instead.
        if e.sig.name.chars().next().is_some_and(|c| c.is_uppercase()) {
            self.error(
                format!(
                    "extern \"C\" fn `{}` starts with an uppercase letter, which Star always parses as a struct-literal constructor at the call site (`Name(args)`); this symbol cannot be called directly under the current grammar",
                    e.sig.name
                ),
                e.span,
            );
        }
        // Standard-library builtins are recognized by name ahead of any
        // user/extern declaration at every call site (see
        // `Codegen::emit_expr`'s `TypedExpr::Call` arm and
        // `builtin_return_ty` above) -- so an extern fn named e.g. `abs` or
        // `len` compiles (its `declare` is emitted) but is never actually
        // called: every call site silently resolves to the builtin instead,
        // with no diagnostic and no argument/type checking against the real
        // foreign signature. An ordinary same-named `fn` has this same
        // shadowing but its dead body is visible right above the call site;
        // an extern fn's "body" is a symbol in another library, so there is
        // nothing for the reader to notice something is wrong. Reject the
        // collision here instead, matching the uppercase-name check above.
        if is_builtin_name(&e.sig.name) {
            self.error(
                format!(
                    "extern \"C\" fn `{}` collides with a built-in name; built-ins always take priority over user declarations at the call site, so this symbol could never actually be called",
                    e.sig.name
                ),
                e.span,
            );
        }
        // See `RESERVED_RUNTIME_SYMBOLS`'s own doc comment: reusing one of
        // these names would emit a second `declare`/`define` for a symbol
        // this compiler already declares internally, which LLVM's parser
        // rejects even when the signature matches exactly -- caught here
        // with a real diagnostic instead of clang's opaque one.
        if RESERVED_RUNTIME_SYMBOLS.contains(&e.sig.name.as_str()) {
            self.error(
                format!(
                    "extern \"C\" fn `{}` collides with a symbol this compiler always declares internally (CRT/OS import or runtime helper); redeclaring it under the same name would fail to compile regardless of the signature given here",
                    e.sig.name
                ),
                e.span,
            );
        } else if !self.extern_fn_names_seen.insert(e.sig.name.clone()) {
            self.error(
                format!("extern \"C\" fn `{}` is declared more than once", e.sig.name),
                e.span,
            );
        }
        let sig = self.check_fn_sig(&e.sig)?;
        for p in &sig.params {
            // `str` is allowed as a parameter (a Star `Str`'s payload is
            // already a bare `i8*`, directly ABI-compatible with `const
            // char*` for read-only use -- see `Codegen::emit_extern_call`)
            // but not as a return type (see the check below): a `char*`
            // handed back from C has no RC header, so it must go through
            // the `ptr_to_str` builtin rather than being treated as `str`.
            if p.ty == Ty::Str || Self::is_ffi_scalar_ty(&p.ty) {
                continue;
            }
            self.error(
                format!("extern \"C\" parameter `{}` has unsupported type `{:?}`; only a numeric type (any width)/char/ptr/str are allowed", p.name, p.ty),
                p.span,
            );
        }
        if let Some(ret) = &sig.ret {
            if !Self::is_ffi_scalar_ty(ret) {
                self.error(
                    format!("extern \"C\" return type `{:?}` is unsupported; only a numeric type (any width)/char/ptr are allowed (use `ptr_to_str` to bridge a returned `char*`)", ret),
                    e.span,
                );
            }
        }
        Some(TypedItem::ExternFn(sig))
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

    /// Reject a struct whose layout directly or transitively contains itself
    /// by value (e.g. `struct Node: next: Node`), which has no finite size.
    /// Left unchecked, this either crashes the compiler with a stack
    /// overflow in `Codegen::type_size`'s unbounded recursion (if a
    /// reflection decorator touches the field) or reaches `clang` as
    /// unrepresentable LLVM IR with a confusing, mislocated error. A struct
    /// wanting self-reference needs an indirection that doesn't inline the
    /// referenced value -- `GenRef<T>` (a fixed-size arena handle) rather
    /// than nesting the struct directly or via another by-value wrapper
    /// like `Box<T>`.
    fn check_no_recursive_structs(&mut self, items: &[TypedItem]) {
        let mut fields_of: HashMap<String, Vec<(Ty, Span)>> = HashMap::new();
        for item in items {
            if let TypedItem::Struct(s) = item {
                fields_of.insert(s.name.clone(), s.fields.iter().map(|f| (f.ty.clone(), f.span)).collect());
            }
        }
        let names: Vec<String> = fields_of.keys().cloned().collect();
        let mut state: HashMap<String, u8> = HashMap::new();
        for name in &names {
            if state.get(name).copied().unwrap_or(0) == 0 {
                let mut stack = Vec::new();
                self.visit_struct_cycle(name, &fields_of, &mut state, &mut stack);
            }
        }
    }

    /// DFS helper for [`check_no_recursive_structs`]: `0` = unvisited, `1` =
    /// on the current path (in progress), `2` = fully explored, no cycle.
    fn visit_struct_cycle(
        &mut self,
        name: &str,
        fields_of: &HashMap<String, Vec<(Ty, Span)>>,
        state: &mut HashMap<String, u8>,
        stack: &mut Vec<String>,
    ) {
        state.insert(name.to_string(), 1);
        stack.push(name.to_string());
        if let Some(fields) = fields_of.get(name) {
            for (ty, span) in fields.clone() {
                // Only a by-value struct field is an inclusion edge --
                // `GenRef<T>`/`List<T>`/`Closure`/primitives are all
                // fixed-size handles regardless of the type they name, so
                // they can't themselves cause unbounded size.
                let Ty::Named(other) = &ty else { continue };
                if !fields_of.contains_key(other) {
                    continue;
                }
                match state.get(other).copied().unwrap_or(0) {
                    0 => self.visit_struct_cycle(other, fields_of, state, stack),
                    1 => {
                        let mut cycle: Vec<String> =
                            stack.iter().skip_while(|s| *s != other).cloned().collect();
                        cycle.push(other.clone());
                        self.error(
                            format!(
                                "recursive struct layout `{}` has infinite size -- use `GenRef<{}>` instead of nesting by value",
                                cycle.join(" -> "),
                                other
                            ),
                            span,
                        );
                    }
                    _ => {}
                }
            }
        }
        stack.pop();
        state.insert(name.to_string(), 2);
    }

    /// Report a checker error for each method `impl trait_name for
    /// impl_blk.type_name` fails to faithfully provide -- previously nothing
    /// checked this at all: a genuinely missing method, or one present under
    /// the right name but with the wrong arity/self-ness/parameter or return
    /// type, silently "implemented" the trait with no diagnostic. There's no
    /// dynamic dispatch through a trait anywhere in codegen to catch this
    /// later either (traits are purely nominal here, see `check_impl`'s call
    /// site) -- this was the only place such a mismatch could ever be
    /// caught. `is_mut` is deliberately not compared: requiring exact
    /// mutability agreement is a stricter rule than this check aims for.
    fn check_impl_satisfies_trait(&mut self, trait_name: &str, impl_blk: &ImplBlock) {
        let Some(tdef) = self.traits.get(trait_name).cloned() else { return };
        for req in &tdef.methods {
            let Some(provided) = impl_blk.methods.iter().find(|m| m.sig.name == req.name) else {
                self.error(
                    format!(
                        "`impl {} for {}` is missing method `{}` required by trait `{}`",
                        trait_name, impl_blk.type_name, req.name, trait_name
                    ),
                    impl_blk.span,
                );
                continue;
            };
            if provided.sig.params.len() != req.params.len() {
                self.error(
                    format!(
                        "method `{}` in `impl {} for {}` has {} parameter(s), but trait `{}` declares {}",
                        req.name, trait_name, impl_blk.type_name, provided.sig.params.len(), trait_name, req.params.len()
                    ),
                    provided.sig.span,
                );
                continue;
            }
            for (rp, pp) in req.params.iter().zip(provided.sig.params.iter()) {
                if rp.is_self != pp.is_self {
                    self.error(
                        format!(
                            "method `{}` in `impl {} for {}` disagrees with trait `{}` on whether `{}` is the `self` receiver",
                            req.name, trait_name, impl_blk.type_name, trait_name, pp.name
                        ),
                        provided.sig.span,
                    );
                } else if !rp.is_self && rp.ty != pp.ty {
                    self.error(
                        format!(
                            "parameter `{}` of method `{}` in `impl {} for {}` has type `{:?}`, but trait `{}` declares `{:?}`",
                            pp.name, req.name, impl_blk.type_name, trait_name, pp.ty, trait_name, rp.ty
                        ),
                        provided.sig.span,
                    );
                }
            }
            if req.ret != provided.sig.ret {
                self.error(
                    format!(
                        "method `{}` in `impl {} for {}` returns `{:?}`, but trait `{}` declares `{:?}`",
                        req.name, impl_blk.type_name, trait_name, provided.sig.ret, trait_name, req.ret
                    ),
                    provided.sig.span,
                );
            }
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
        if let Some(trait_name) = &impl_blk.trait_name {
            self.check_impl_satisfies_trait(trait_name, impl_blk);
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
        // `main` is always lowered to `i32 @main(...)` regardless of its
        // declared return type (see `Codegen::emit_fn`), since a hosted C
        // entry point's signature is an OS/CRT ABI requirement, not a
        // stylistic choice -- so a declared type other than `i32` (or no
        // declared type at all, which is fine: it becomes an implicit `ret
        // i32 0`) can never actually be honored and must be rejected here
        // rather than silently producing a `ret <declared-ty>` that
        // disagrees with `main`'s forced `i32` signature.
        if sig.name == "main" {
            if let Some(ret_ty) = &sig.ret {
                if *ret_ty != Ty::Int {
                    self.error(
                        format!("`main` must return `i32` (or have no declared return type), found `{:?}`", ret_ty),
                        sig.span,
                    );
                }
            }
        }
        let saved_ret_ty = std::mem::replace(&mut self.current_ret_ty, Some(sig.ret.clone()));
        let body = self.check_block(&f.body, &sig)?;
        self.current_ret_ty = saved_ret_ty;
        // §1.3's other half: `return`-statement checking above only catches
        // an *explicit* `return <expr>`. Star also allows an *implicit*
        // trailing-expression return (`fn get_val() -> i32:\n    "not an
        // int"`, no `return` keyword at all) -- codegen's `emit_fn` lowers
        // that trailing value straight to `ret <ty-of-the-expr>` with no
        // comparison against the declared return type either, so this needs
        // its own check, mirroring exactly which statement shapes
        // `Codegen::body_terminates`/`emit_stmts_value` treat as
        // "terminated" / "produces a trailing value".
        if let Some(ret_ty) = &sig.ret {
            if !Self::stmts_terminate(&body.stmts) {
                match Self::trailing_value_ty(&body.stmts) {
                    Some(actual) => {
                        if !Self::types_compatible(ret_ty, &actual) {
                            self.error(
                                format!(
                                    "function `{}` is declared to return `{:?}`, but its trailing expression has type `{:?}`",
                                    sig.name, ret_ty, actual
                                ),
                                sig.span,
                            );
                        }
                    }
                    None => self.error(
                        format!(
                            "function `{}` is declared to return `{:?}` but does not end in a value-producing expression or explicit `return`",
                            sig.name, ret_ty
                        ),
                        sig.span,
                    ),
                }
            }
        }
        self.check_frame_escapes(&body, &sig);
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
        self.mut_vars.clear();
        for p in &fn_sig.params {
            vars.insert(p.name.clone(), p.ty.clone());
            if p.is_mut {
                self.mut_vars.insert(p.name.clone());
            }
        }
        Some(self.check_block_inner(block, &mut vars))
    }

    /// Type-check a block reusing an inherited variable table. Used for nested
    /// `if`/`while` bodies and `else` branches so bindings from the enclosing
    /// scope remain visible.
    fn check_block_inner(&mut self, block: &Block, vars: &mut HashMap<String, Ty>) -> TypedBlock {
        // `mut_vars` needs the same scoping `vars` gets via the `vars.clone()`
        // every nested-block call site (then/else, while/frame/par/for
        // bodies) already passes in: a `let mut`/re-`let` inside this block
        // must not leak its mutability change out to whatever scope called
        // this block, or a later, unrelated binding reusing the same name
        // could wrongly inherit an inner block's stale mutability.
        let saved_mut_vars = self.mut_vars.clone();
        let mut stmts = Vec::new();
        for stmt in &block.stmts {
            if let Some(typed) = self.check_stmt(stmt, vars) {
                stmts.push(typed);
            }
        }
        self.mut_vars = saved_mut_vars;
        TypedBlock { stmts, span: block.span }
    }

    /// Arenas whose declared element type is `ty`. Zero means "no backing
    /// arena", more than one means "ambiguous" -- both are errors at any
    /// `GenRef<T>` creation/dereference site (see `require_backing_arena`).
    fn arenas_of_elem_ty(&self, ty: &Ty) -> Vec<&String> {
        self.arenas.iter().filter(|(_, t)| *t == ty).map(|(n, _)| n).collect()
    }

    /// Validate that exactly one arena backs `GenRef<inner_ty>`/`Handle<inner_ty>`
    /// (`kind` is `"GenRef"` or `"Handle"`, purely for the diagnostic's
    /// wording), emitting a diagnostic otherwise. Codegen independently
    /// re-resolves the arena name from `inner_ty` (see
    /// `Codegen::arena_for_elem_ty`); this check only exists to turn a
    /// missing/ambiguous backing arena into a friendly type error instead of
    /// a defensive codegen-time failure.
    fn require_backing_arena(&mut self, inner_ty: &Ty, kind: &str, span: Span) {
        match self.arenas_of_elem_ty(inner_ty).len() {
            1 => {}
            0 => self.error(
                format!("`{}<{:?}>` has no backing arena -- declare `arena Name: {:?}`", kind, inner_ty, inner_ty),
                span,
            ),
            _ => self.error(
                format!("`{}<{:?}>` is ambiguous: multiple arenas hold `{:?}`", kind, inner_ty, inner_ty),
                span,
            ),
        }
    }

    /// True if `ty` is structurally hashable/comparable, i.e. legal as a
    /// `Map<K,V>` key or `Set<T>` element: `i32`/`f32`/`bool`/`str`/a
    /// fieldless `enum`/`Vec2`/`Vec3`/`Vec4`, or a `struct` composed
    /// entirely of such fields, recursively. Rejects (with a diagnostic)
    /// payload-carrying enums, and anything owning a `GenRef`/`List`/`Map`/
    /// `Set`/closure/`ptr` -- `Map`/`Set` have no hashing/equality story for
    /// those today (see `crate::codegen::map`'s doc comment on the current
    /// linear-scan-plus-structural-equality implementation strategy).
    /// `visited` guards against infinite recursion on a struct that (would)
    /// contain itself by value -- `check_no_recursive_structs` catches that
    /// as its own error only *after* every item has been checked, so this
    /// must not assume that pass has already run.
    fn check_hashable_ty(&mut self, ty: &Ty, visited: &mut HashSet<String>) -> bool {
        match ty {
            Ty::Int | Ty::Bool | Ty::Str | Ty::Float | Ty::Vec2 | Ty::Vec3 | Ty::Vec4 => true,
            // A bare `i64` id comparison -- see `Ty::Symbol`'s doc comment.
            // Unlike `Ty::Bytes`/`Ty::List`, there's no heap buffer to hash
            // structurally: the id itself is the comparable value.
            Ty::Symbol => true,
            // Every explicit-width integer/float plus `char` is a plain
            // fixed-size scalar, structurally comparable exactly like
            // `Ty::Int`/`Ty::Float` above.
            Ty::I8 | Ty::U8 | Ty::I16 | Ty::U16 | Ty::U32 | Ty::I64 | Ty::U64 | Ty::F64 | Ty::Char => true,
            // Every element's own type is already fully concrete here (no
            // named type to recurse-guard against, unlike `Ty::Named` below
            // -- a tuple can't be self-referential without going through a
            // named struct, which already carries its own guard).
            Ty::Tuple(elems) => elems.iter().all(|t| self.check_hashable_ty(t, visited)),
            // Same reasoning: an array is stored inline (like a tuple), so
            // it's structurally comparable exactly when its element type is.
            Ty::Array(elem, _) => self.check_hashable_ty(elem, visited),
            // Both lower to a plain fixed-size scalar under the hood (see
            // their own doc comments) -- structurally comparable exactly
            // like any other sized integer.
            Ty::Wrapping(inner) => self.check_hashable_ty(inner, visited),
            Ty::Fixed(..) => true,
            Ty::Enum(name) => {
                let fieldless = self.enums.get(name).map(|e| e.variants.iter().all(|v| v.fields.is_empty())).unwrap_or(true);
                if !fieldless {
                    self.error(
                        format!("`{}` cannot be used as a `Map`/`Set` key: payload-carrying enums are not yet supported", name),
                        Span::dummy(),
                    );
                }
                fieldless
            }
            Ty::Named(name) => {
                if !visited.insert(name.clone()) {
                    // Already on the current path -- a self-referential
                    // struct will be reported separately by
                    // `check_no_recursive_structs`; just stop recursing.
                    return false;
                }
                let ok = match self.structs.get(name).cloned() {
                    // Not found is already reported elsewhere (undefined
                    // type); don't cascade a second diagnostic here.
                    None => true,
                    Some(sdef) => sdef.fields.iter().all(|f| {
                        let fty = self.resolve_type(&f.ty).unwrap_or(Ty::Named("unknown".into()));
                        self.check_hashable_ty(&fty, visited)
                    }),
                };
                visited.remove(name);
                ok
            }
            _ => {
                self.error(
                    format!(
                        "`{:?}` cannot be used as a `Map`/`Set` key -- only a numeric type (any width)/bool/str/char/fieldless-enum/Vec2/Vec3/Vec4, \
                         or a struct composed entirely of such fields, are supported",
                        ty
                    ),
                    Span::dummy(),
                );
                false
            }
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
            Type::Tuple(elems) => {
                let resolved: Vec<Ty> = elems.iter().filter_map(|e| self.resolve_type(e)).collect();
                if resolved.len() != elems.len() {
                    return None;
                }
                Some(Ty::Tuple(resolved))
            }
            Type::Array(elem, count) => {
                let elem_ty = self.resolve_type(elem)?;
                if *count > Self::MAX_INLINE_LEN {
                    self.error(
                        format!(
                            "array size `{}` is too large (max {}) -- `[T; N]` is stored inline with no heap allocation of its own, so an enormous `N` either hangs the compiler emitting one instruction per element or bakes a multi-gigabyte type into the generated code; use a heap-backed `List<T>`/`Table<T>` instead",
                            count, Self::MAX_INLINE_LEN
                        ),
                        Span::dummy(),
                    );
                    return None;
                }
                Some(Ty::Array(Box::new(elem_ty), *count))
            }
            Type::Ring(elem, count) => {
                let elem_ty = self.resolve_type(elem)?;
                if *count > Self::MAX_INLINE_LEN {
                    self.error(
                        format!(
                            "`Ring<T, N>` capacity `{}` is too large (max {}) -- like `[T; N]`, a `Ring` is stored inline with no heap allocation of its own, so an enormous `N` bakes a multi-gigabyte type into the generated code",
                            count, Self::MAX_INLINE_LEN
                        ),
                        Span::dummy(),
                    );
                    return None;
                }
                Some(Ty::Ring(Box::new(elem_ty), *count))
            }
            Type::Fixed(bits, frac) => {
                if !matches!(bits, 8 | 16 | 32 | 64) {
                    self.error(
                        format!("`Fixed<{}, {}>`'s bit width must be one of 8, 16, 32, 64", bits, frac),
                        Span::dummy(),
                    );
                    return None;
                }
                if *frac >= *bits {
                    self.error(
                        format!(
                            "`Fixed<{}, {}>`'s fractional-bit count must be less than its bit width",
                            bits, frac
                        ),
                        Span::dummy(),
                    );
                    return None;
                }
                Some(Ty::Fixed(*bits, *frac))
            }
            Type::Fn(params, ret) => {
                let param_tys: Vec<Ty> = params.iter().filter_map(|p| self.resolve_type(p)).collect();
                if param_tys.len() != params.len() {
                    return None;
                }
                let ret_ty = self.resolve_type(ret)?;
                Some(Ty::Closure(param_tys, Box::new(ret_ty)))
            }
            Type::Named(name) if self.enums.contains_key(name) => Some(Ty::Enum(name.clone())),
            // A user struct takes priority over a same-named builtin scalar
            // (`Vec2`, `Tick`, ...) below, mirroring the `enums` guard just
            // above -- previously a `struct Tick: ...` (or `Vec2`/`Mat4`/...)
            // type-checked with no error at all (the "declared more than
            // once" duplicate-name check only ever covered the builtin
            // *generic* enums `Option`/`Result`, seeded into
            // `type_names_seen` up front), silently registered into
            // `self.structs`, and then every reference to `Tick`/`Vec2`/...
            // kept resolving to the builtin scalar anyway since the matches
            // below fired first -- so the user's struct was permanently
            // inert. That surfaced downstream as thoroughly confusing
            // failures: `Tick(5)` construction passed `check_builtin_ctor_arity`
            // (an int-shaped arg satisfies "expects 1 integer argument")
            // instead of the user's actual field list, and a later `.x`
            // field access on the resulting bare-`i64`-typed value crashed
            // codegen with an unlocated "field access on non-struct type"
            // instead of any diagnostic pointing at the real problem.
            Type::Named(name) if self.structs.contains_key(name) => Some(Ty::Named(name.clone())),
            Type::Named(name) if self.generic_structs.contains_key(name) || self.generic_enums.contains_key(name) => {
                self.error(format!("generic type `{}` used without type arguments", name), Span::dummy());
                None
            }
            Type::Named(name) => match name.as_str() {
                "i32" | "int" => Some(Ty::Int),
                "f32" | "float" => Some(Ty::Float),
                // `docs/design.md`'s "Numeric widths and modes": every
                // explicit-width integer/float, plus `char` (a Unicode
                // scalar, distinct from a raw `str` byte). `i64`/`f64`
                // previously aliased to `Ty::Int`/`Ty::Float` (Star's only
                // widths until now) -- they're real, distinct 64-bit types
                // as of this addition; no test/example in this repo relied
                // on the old alias behavior.
                "i8" => Some(Ty::I8),
                "u8" => Some(Ty::U8),
                "i16" => Some(Ty::I16),
                "u16" => Some(Ty::U16),
                "u32" => Some(Ty::U32),
                "i64" => Some(Ty::I64),
                "u64" => Some(Ty::U64),
                "f64" => Some(Ty::F64),
                "char" => Some(Ty::Char),
                "String" | "str" => Some(Ty::Str),
                "bool" => Some(Ty::Bool),
                "Vec2" => Some(Ty::Vec2),
                "Vec3" => Some(Ty::Vec3),
                "Vec4" => Some(Ty::Vec4),
                "Mat4" => Some(Ty::Mat4),
                "ptr" => Some(Ty::Ptr),
                // `docs/design.md`'s "Time" section -- see `Ty::Tick`'s doc
                // comment.
                "Tick" => Some(Ty::Tick),
                "Duration" => Some(Ty::Duration),
                "Instant" => Some(Ty::Instant),
                // `docs/design.md`'s "Text and bytes" section -- see
                // `Ty::Bytes`/`Ty::Symbol`'s doc comments.
                "Bytes" => Some(Ty::Bytes),
                "Symbol" => Some(Ty::Symbol),
                // Every other candidate is undeclared by this point: a
                // declared struct, enum, or generic template is already
                // caught by the guarded arms above this one. Previously this
                // fell through to a blind `Ty::Named(name.clone())` with no
                // lookup at all, so a typo'd/undeclared type name in a
                // parameter, field, or return position silently "resolved"
                // to a bogus `Ty::Named`, which downstream code (e.g.
                // `resolve_field_type`) treats as "already reported
                // elsewhere" and quietly widens to the `unknown` placeholder
                // -- masking what should be a real, clean diagnostic here.
                _ => {
                    let candidates: Vec<&str> = self.structs.keys().map(String::as_str).collect();
                    match suggest(name, candidates) {
                        Some(close) => self.error_note(
                            format!("undefined type `{}`", name),
                            Span::dummy(),
                            format!("did you mean `{}`?", close),
                        ),
                        None => self.error(format!("undefined type `{}`", name), Span::dummy()),
                    }
                    None
                }
            },
            Type::Generic(name, args) => {
                // Handle GenRef<T>
                if name == "GenRef" {
                    let inner = args.first().and_then(|a| self.resolve_type(a)).unwrap_or(Ty::Int);
                    return Some(Ty::GenRef(Box::new(inner)));
                }
                // `Handle<T>` -- same arena-backed construction as `GenRef<T>`
                // (see `Ty::Handle`'s doc comment), just a nominally distinct
                // wrapper type.
                if name == "Handle" {
                    let inner = args.first().and_then(|a| self.resolve_type(a)).unwrap_or(Ty::Int);
                    return Some(Ty::Handle(Box::new(inner)));
                }
                if name == "List" {
                    let inner = args.first().and_then(|a| self.resolve_type(a)).unwrap_or(Ty::Int);
                    return Some(Ty::List(Box::new(inner)));
                }
                if name == "Map" {
                    let key_ty = args.first().and_then(|a| self.resolve_type(a)).unwrap_or(Ty::Int);
                    let val_ty = args.get(1).and_then(|a| self.resolve_type(a)).unwrap_or(Ty::Int);
                    let mut visited = HashSet::new();
                    if !self.check_hashable_ty(&key_ty, &mut visited) {
                        return None;
                    }
                    return Some(Ty::Map(Box::new(key_ty), Box::new(val_ty)));
                }
                if name == "Set" {
                    let inner = args.first().and_then(|a| self.resolve_type(a)).unwrap_or(Ty::Int);
                    let mut visited = HashSet::new();
                    if !self.check_hashable_ty(&inner, &mut visited) {
                        return None;
                    }
                    return Some(Ty::Set(Box::new(inner)));
                }
                if name == "Table" {
                    let inner = args.first().and_then(|a| self.resolve_type(a))?;
                    let Ty::Named(struct_name) = &inner else {
                        self.error(format!("`Table<T>` requires `T` to be a struct type, found `{:?}`", inner), Span::dummy());
                        return None;
                    };
                    if !self.structs.contains_key(struct_name) {
                        self.error(format!("`Table<T>` requires `T` to be a struct type, found `{:?}`", inner), Span::dummy());
                        return None;
                    }
                    return Some(Ty::Table(Box::new(inner)));
                }
                // `Wrapping<T>` -- see `Ty::Wrapping`'s doc comment. `T` must
                // be a plain integer type (anything `int_shape()` recognizes,
                // including `Ty::Int` itself -- this is exactly the opt-in
                // `docs/design.md` describes for wraparound on a width that
                // otherwise traps by default).
                if name == "Wrapping" {
                    let inner = args.first().and_then(|a| self.resolve_type(a))?;
                    if inner.int_shape().is_none() {
                        self.error(
                            format!("`Wrapping<T>` requires `T` to be an integer type, found `{:?}`", inner),
                            Span::dummy(),
                        );
                        return None;
                    }
                    return Some(Ty::Wrapping(Box::new(inner)));
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
        if self.mono_depth >= Self::MAX_MONO_DEPTH {
            self.error(
                format!(
                    "generic type `{}` nests too deeply while instantiating `{}` -- likely a field whose type wraps its own type parameter in another generic (e.g. `struct Node<T>: next: Node<Box<T>>`), which grows a new instantiation forever",
                    template_name, mangled
                ),
                Span::dummy(),
            );
            return mangled;
        }
        self.mono_depth += 1;
        let result = self.instantiate_struct_inner(template_name, args, mangled);
        self.mono_depth -= 1;
        result
    }

    fn instantiate_struct_inner(&mut self, template_name: &str, args: &[Ty], mangled: String) -> String {
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
    /// `instantiate_struct`; see its doc comment (including `mono_depth`'s
    /// recursion guard).
    fn instantiate_enum(&mut self, template_name: &str, args: &[Ty]) -> String {
        let mangled = mangle_generic(template_name, args);
        if self.enums.contains_key(&mangled) {
            return mangled;
        }
        if self.mono_depth >= Self::MAX_MONO_DEPTH {
            self.error(
                format!(
                    "generic type `{}` nests too deeply while instantiating `{}` -- likely a variant field whose type wraps its own type parameter in another generic, which grows a new instantiation forever",
                    template_name, mangled
                ),
                Span::dummy(),
            );
            return mangled;
        }
        self.mono_depth += 1;
        let result = self.instantiate_enum_inner(template_name, args, mangled);
        self.mono_depth -= 1;
        result
    }

    fn instantiate_enum_inner(&mut self, template_name: &str, args: &[Ty], mangled: String) -> String {
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
    /// mangled name instead of instantiating forever -- but a recursive call
    /// that wraps its argument in another generic each time (`fn wrap<T>(x:
    /// T) -> Wrapped<T> { wrap(Box(x)) }`) produces a *different* mangled
    /// name on every call, so that memoization doesn't help; see
    /// `mono_depth`'s doc comment for the shared recursion guard that does.
    fn instantiate_fn(&mut self, template_name: &str, args: &[Ty]) -> String {
        let mangled = mangle_generic(template_name, args);
        if self.functions.contains_key(&mangled) {
            return mangled;
        }
        if self.mono_depth >= Self::MAX_MONO_DEPTH {
            self.error(
                format!(
                    "generic function `{}` nests too deeply while instantiating `{}` -- likely a recursive call that wraps its argument in another generic each time, which grows a new instantiation forever",
                    template_name, mangled
                ),
                Span::dummy(),
            );
            return mangled;
        }
        self.mono_depth += 1;
        let result = self.instantiate_fn_inner(template_name, args, mangled);
        self.mono_depth -= 1;
        result
    }

    fn instantiate_fn_inner(&mut self, template_name: &str, args: &[Ty], mangled: String) -> String {
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
        self.mono_fn_of.insert(mangled.clone(), template_name.to_string());
        let Some(typed) = self.check_fn(&concrete) else { return mangled; };
        self.mono_items.push(TypedItem::Fn(typed));
        mangled
    }

    /// True for the placeholder types that stand in for an expression whose
    /// real type couldn't be determined because an error was already
    /// reported for it elsewhere (an undefined name, an unresolved field,
    /// ...) -- shared by [`Checker::types_compatible`] and [`Checker::unify_ty`]
    /// so neither cascades a second diagnostic on top of the real one.
    fn is_placeholder_ty(t: &Ty) -> bool {
        matches!(t, Ty::Named(n) if matches!(n.as_str(), "unknown" | "infer_error" | "infer" | "Self"))
    }

    /// Unify a (possibly type-parameterized) declared syntactic type against
    /// a concrete inferred `Ty`, recording any type parameter it binds into
    /// `subst`. Used both to infer a generic function call's type arguments
    /// from its call-site arguments, and to infer a generic struct/enum
    /// construction's type arguments from its constructor arguments, when no
    /// explicit turbofish was given. The first binding found for a given
    /// parameter wins; any later occurrence that disagrees with it is
    /// recorded into `conflicts` (skipped if the offending argument was
    /// already a placeholder from an earlier error) so the caller can report
    /// a single, located diagnostic instead of silently keeping the first
    /// guess.
    fn unify_ty(&self, param_ty: &Type, arg_ty: &Ty, type_params: &[String], subst: &mut HashMap<String, Ty>, conflicts: &mut Vec<(String, Ty, Ty)>) {
        match param_ty {
            Type::Named(n) if type_params.iter().any(|p| p == n) => {
                if Self::is_placeholder_ty(arg_ty) {
                    return;
                }
                match subst.get(n) {
                    Some(existing) if existing != arg_ty => {
                        conflicts.push((n.clone(), existing.clone(), arg_ty.clone()));
                    }
                    Some(_) => {}
                    None => {
                        subst.insert(n.clone(), arg_ty.clone());
                    }
                }
            }
            Type::Named(_) => {}
            // A closure-typed generic parameter has nothing to unify against
            // today (no generic template's field/param declares one in a
            // way that binds a type parameter); a no-op, like `Type::Named`
            // naming a non-type-parameter type above.
            Type::Fn(..) => {}
            Type::Tuple(elems) => {
                if let Ty::Tuple(arg_elems) = arg_ty {
                    if elems.len() == arg_elems.len() {
                        for (pe, ae) in elems.iter().zip(arg_elems.iter()) {
                            self.unify_ty(pe, ae, type_params, subst, conflicts);
                        }
                    }
                }
            }
            Type::Array(elem, count) => {
                if let Ty::Array(arg_elem, arg_count) = arg_ty {
                    if count == arg_count {
                        self.unify_ty(elem, arg_elem, type_params, subst, conflicts);
                    }
                }
            }
            Type::Ring(elem, count) => {
                if let Ty::Ring(arg_elem, arg_count) = arg_ty {
                    if count == arg_count {
                        self.unify_ty(elem, arg_elem, type_params, subst, conflicts);
                    }
                }
            }
            // `Bits`/`Frac` are bare integer literals, never a type
            // parameter to bind -- a no-op, like `Type::Named` naming a
            // non-type-parameter type above.
            Type::Fixed(..) => {}
            Type::Generic(name, args) => {
                if name == "GenRef" {
                    if let (Some(a0), Ty::GenRef(inner)) = (args.first(), arg_ty) {
                        self.unify_ty(a0, inner, type_params, subst, conflicts);
                    }
                    return;
                }
                if name == "List" {
                    if let (Some(a0), Ty::List(inner)) = (args.first(), arg_ty) {
                        self.unify_ty(a0, inner, type_params, subst, conflicts);
                    }
                    return;
                }
                if name == "Map" {
                    if let Ty::Map(k, v) = arg_ty {
                        if let Some(a0) = args.first() {
                            self.unify_ty(a0, k, type_params, subst, conflicts);
                        }
                        if let Some(a1) = args.get(1) {
                            self.unify_ty(a1, v, type_params, subst, conflicts);
                        }
                    }
                    return;
                }
                if name == "Set" {
                    if let (Some(a0), Ty::Set(inner)) = (args.first(), arg_ty) {
                        self.unify_ty(a0, inner, type_params, subst, conflicts);
                    }
                    return;
                }
                if name == "Table" {
                    if let (Some(a0), Ty::Table(inner)) = (args.first(), arg_ty) {
                        self.unify_ty(a0, inner, type_params, subst, conflicts);
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
                            self.unify_ty(pa, ta, type_params, subst, conflicts);
                        }
                    }
                }
            }
        }
    }

    /// True if `declared` and `actual` should be treated as the same type
    /// for assignability purposes (`let`/`return`/`Assign`/call-argument
    /// checking). Exact equality, with one carve-out: either side being a
    /// placeholder (`unknown`/`infer_error`/`infer`/`Self`) means an error
    /// was already reported for that sub-expression elsewhere (an undefined
    /// name, an unresolved field, ...), so staying silent here avoids
    /// cascading a second, less useful diagnostic on top of the real one.
    fn types_compatible(declared: &Ty, actual: &Ty) -> bool {
        declared == actual || Self::is_placeholder_ty(declared) || Self::is_placeholder_ty(actual)
    }

    /// The root binding an assignment target ultimately writes through --
    /// `x`, `x.f`, `x.f.g`, `x[i].f`, `self.f` all root at `x`/`self`.
    /// `None` for any other target shape (nothing in `mut_vars` to check
    /// against, e.g. a target expression that already failed to type-check).
    /// Used to enforce that `mut` is required to change state (`docs/design.md`):
    /// previously `is_mut` was parsed and threaded everywhere but never once
    /// read by any check, so every binding -- `let`, parameter, or struct
    /// field -- was silently mutable regardless of the keyword.
    fn assign_root_name(target: &TypedExpr) -> Option<&str> {
        match target {
            TypedExpr::Ident { name, .. } => Some(name.as_str()),
            TypedExpr::SelfExpr(..) => Some("self"),
            TypedExpr::Field { base, .. } => Self::assign_root_name(base),
            TypedExpr::ListIndex { base, .. } => Self::assign_root_name(base),
            // Same rule as `Field` above: a tuple has no per-element `mut`
            // declaration to independently gate (there's no field
            // declaration at all, positional or otherwise), so mutating any
            // element is gated purely by the root binding's own `mut`.
            TypedExpr::TupleIndex { base, .. } => Self::assign_root_name(base),
            // Same rule as `ListIndex`: an array element has no per-slot
            // `mut` declaration of its own, so mutating any element is
            // gated purely by the root binding's own `mut`.
            TypedExpr::ArrayIndex { base, .. } => Self::assign_root_name(base),
            // Same rule as `ArrayIndex`: a ring element has no per-slot
            // `mut` declaration of its own, so mutating any element (or
            // calling `push`/`pop` via `check_mut_receiver`, which also
            // calls this) is gated purely by the root binding's own `mut`.
            TypedExpr::RingIndex { base, .. } => Self::assign_root_name(base),
            // Same rule as `ListIndex`: a `Table<T>` element has no per-slot
            // `mut` declaration of its own (`Table`'s whole-element write
            // decomposes into every column, see `Ty::Table`'s doc comment),
            // so mutating any element (or calling `push`/`pop` via
            // `check_mut_receiver`, which also calls this) is gated purely
            // by the root binding's own `mut`.
            TypedExpr::TableIndex { base, .. } => Self::assign_root_name(base),
            // Deliberately *not* recursed into, unlike `ListIndex` above: a
            // `GenRef<T>` is a handle into arena-owned storage, not a value
            // the binding itself owns (mirrors a Rust `&mut T` reference --
            // `let r = &mut x; *r = v;` needs no `mut` on `r` itself, only
            // on what it points to). Mutating through one is instead gated
            // purely by the pointed-to struct's own per-field `mut`
            // declaration (see the `field_is_mut` check below), independent
            // of whether the local binding holding the `GenRef` is `mut`.
            TypedExpr::GenRefIndex { .. } => None,
            _ => None,
        }
    }

    /// Whether `target`, if used as a place (an assignment target or a
    /// mutating method-call receiver), would ultimately resolve through
    /// `Codegen::emit_place`'s generic rvalue fallback because a `Table<T>`
    /// index sits somewhere in its unbroken `Field`/`TupleIndex` projection
    /// chain -- see `Ty::Table`'s doc comment: a table element's fields live
    /// in independent columns, not one contiguous address, so there is no
    /// real place to project a field out of, and a write through that
    /// fallback's disconnected alloca silently vanishes. Only `Field`/
    /// `TupleIndex`/`ListIndex`/`ArrayIndex`/`RingIndex` hops are all peeled
    /// through (mirroring `assign_root_name`'s recursion) -- `Ident` (or
    /// anything else with genuine, independently-addressable storage of its
    /// own that never bottoms out at a `TableIndex`) is unaffected, so
    /// `list[i].some_table[j]` (a real `List<Table<T>>` element) is still
    /// correctly left alone. But a `ListIndex`/`ArrayIndex`/`RingIndex`
    /// *itself* only has real addressable storage when its own `base` does
    /// -- `t[i].tags[j] = v` (`tags: List<i32>` a field of a `Table<T>`
    /// element) first reads `t[i].tags` through exactly the same
    /// disconnected-temporary fallback as `t[i].tags = v` before indexing
    /// into *that*, so the write is just as silently lost. Previously these
    /// three index kinds were treated as unconditionally "real storage" and
    /// never recursed into, letting `t[i].tags[j] = v`,
    /// `t[i].cells[j] = v` (an array field), and `t[i].tags[j] += v` all
    /// silently no-op instead of being rejected -- confirmed via a real
    /// `star build`+run where the write compiled cleanly, ran to exit 0,
    /// and printed the pre-write value. Callers only invoke this once
    /// `target`/`base` is already known to be one of these five kinds (a
    /// bare `table[i] = v` -- the one supported whole-element write -- must
    /// not be rejected).
    fn writes_through_table_index(target: &TypedExpr) -> bool {
        match target {
            TypedExpr::TableIndex { .. } => true,
            TypedExpr::Field { base, .. }
            | TypedExpr::TupleIndex { base, .. }
            | TypedExpr::ListIndex { base, .. }
            | TypedExpr::ArrayIndex { base, .. }
            | TypedExpr::RingIndex { base, .. } => Self::writes_through_table_index(base),
            _ => false,
        }
    }

    /// `mut` gate for a mutating collection method call (`List::push`/`pop`,
    /// `Map::insert`/`remove`, `Set::insert`/`remove`) -- the exact same rule
    /// `Stmt::Assign` enforces on `x = ...` via `assign_root_name`/`mut_vars`
    /// above, just for a receiver mutated through a method call instead of
    /// through `=`. Previously unchecked entirely: `fn f(m: Map<str,i32>):
    /// m.insert("k", 1)` type-checked cleanly with no `mut` required
    /// anywhere on `m`, the exact gap `docs/design.md`'s "mut is required to
    /// change state" rule exists to close for a plain assignment.
    fn check_mut_receiver(&mut self, base: &TypedExpr, method: &str, span: Span) {
        if matches!(
            base,
            TypedExpr::Field { .. } | TypedExpr::TupleIndex { .. } | TypedExpr::ListIndex { .. } | TypedExpr::ArrayIndex { .. } | TypedExpr::RingIndex { .. }
        ) && Self::writes_through_table_index(base)
        {
            self.error(
                format!(
                    "cannot call `{}(..)` through a `Table<T>` index -- a table element's fields live in independent columns with no addressable storage of their own; assign or read the whole element instead (`table[i] = ...`)",
                    method
                ),
                span,
            );
        }
        if let Some(root) = Self::assign_root_name(base) {
            if !self.mut_vars.contains(root) {
                let subject = if root == "self" { "self".to_string() } else { format!("`{}`", root) };
                self.error(
                    format!("cannot call `{}(..)` on {} -- it was not declared `mut`", method, subject),
                    span,
                );
            }
        }
        // Mirror `Stmt::Assign`'s own `field_is_mut` check: a struct field can
        // independently be declared without `mut` (`items: List<i32>` vs `mut
        // items: List<i32>`), so even a `mut`-bound receiver can still have
        // specific fields that may only ever be set once (at construction).
        // Previously only a plain `self.items = ...` assignment enforced
        // this -- `self.items.push(x)` (or `Map`/`Set`'s `insert`/`remove`)
        // reached only the root-binding check above and silently skipped the
        // field-level one entirely, letting a non-`mut` field's contents be
        // mutated through its collection methods.
        if let TypedExpr::Field { base: inner_base, field, .. } = base {
            if self.field_is_mut(&inner_base.clone().into_ty(), field) == Some(false) {
                self.error(
                    format!("field `{}` is not mutable -- declare it `mut {}: ...` to call `{}(..)`", field, field, method),
                    span,
                );
            }
        }
    }

    /// Whether `field` is declared `mut` on `base_ty`'s struct -- `None` if
    /// `base_ty` isn't a plain struct or doesn't declare that field (e.g. a
    /// vector's swizzle "field", or an already-errored unknown type), in
    /// which case there's nothing to enforce here.
    fn field_is_mut(&self, base_ty: &Ty, field: &str) -> Option<bool> {
        match base_ty {
            Ty::Named(n) => self.structs.get(n).and_then(|s| s.fields.iter().find(|f| f.name == *field).map(|f| f.is_mut)),
            _ => None,
        }
    }

    /// True if the last statement of `stmts` unconditionally terminates the
    /// block with an explicit `return`/`break`/`continue` (looking through
    /// trailing `frame` scopes and fully-covering `if`/`match`), mirroring
    /// `crate::codegen::Codegen::body_terminates` exactly -- kept in sync
    /// with it so `check_fn_with_self_ty`'s implicit-trailing-return check
    /// agrees with what codegen will actually do with the same body.
    fn stmts_terminate(stmts: &[TypedStmt]) -> bool {
        match stmts.last() {
            Some(TypedStmt::Return { .. } | TypedStmt::Break { .. } | TypedStmt::Continue { .. }) => true,
            Some(TypedStmt::Frame { body, .. }) => Self::stmts_terminate(&body.stmts),
            Some(TypedStmt::If { then_block, else_block: Some(else_block), .. }) => {
                Self::stmts_terminate(&then_block.stmts) && Self::stmts_terminate(&else_block.stmts)
            }
            Some(TypedStmt::Expr(TypedExpr::Match { arms, .. })) => {
                !arms.is_empty() && arms.iter().all(|arm| Self::stmts_terminate(&arm.body.stmts))
            }
            _ => false,
        }
    }

    /// The type of `stmts`' implicit trailing value, if any -- mirrors
    /// `crate::codegen::Codegen::emit_stmts_value`'s notion of which
    /// statement shapes contribute a value (a trailing bare expression, or a
    /// `frame:` scope whose own trailing statement does) versus which don't
    /// (every other statement kind, including a statement-form `if`/`match`
    /// used only for side effects).
    fn trailing_value_ty(stmts: &[TypedStmt]) -> Option<Ty> {
        match stmts.last() {
            Some(TypedStmt::Expr(e)) => Some(e.clone().into_ty()),
            Some(TypedStmt::Frame { body, .. }) => Self::trailing_value_ty(&body.stmts),
            _ => None,
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
        Ty::I8 => "i8".into(),
        Ty::U8 => "u8".into(),
        Ty::I16 => "i16".into(),
        Ty::U16 => "u16".into(),
        Ty::U32 => "u32".into(),
        Ty::I64 => "i64".into(),
        Ty::U64 => "u64".into(),
        Ty::F64 => "f64".into(),
        Ty::Char => "char".into(),
        Ty::Str => "str".into(),
        Ty::Bool => "bool".into(),
        Ty::Vec2 => "Vec2".into(),
        Ty::Vec3 => "Vec3".into(),
        Ty::Vec4 => "Vec4".into(),
        Ty::Mat4 => "Mat4".into(),
        Ty::Named(n) => n.clone(),
        Ty::Enum(n) => n.clone(),
        Ty::GenRef(inner) => format!("GenRef_{}", mangle_ty(inner)),
        Ty::Handle(inner) => format!("Handle_{}", mangle_ty(inner)),
        Ty::List(inner) => format!("List_{}", mangle_ty(inner)),
        // Length-prefix the key segment so the K/V boundary is unambiguous
        // even when a name contains `_` -- see `Codegen::mangle_ty`'s `Ty::Map`
        // arm (src/codegen/mod.rs) for the identical fix and full rationale;
        // this is a separate mangling scheme (used for generic monomorphization
        // names) with the same two-argument join, so it needs the same fix
        // independently.
        Ty::Map(k, v) => {
            let km = mangle_ty(k);
            format!("Map_{}_{}{}", km.len(), km, mangle_ty(v))
        }
        Ty::Set(inner) => format!("Set_{}", mangle_ty(inner)),
        // Length-prefix every element so arity/boundaries are unambiguous
        // regardless of what any element's own mangled form contains --
        // same defensive reasoning as `Ty::Map`'s fix just above (a plain
        // join could collide two differently-shaped tuples onto the same
        // mangled name).
        Ty::Tuple(elems) => {
            let mut s = format!("Tuple{}", elems.len());
            for e in elems {
                let m = mangle_ty(e);
                s.push_str(&format!("_{}_{}", m.len(), m));
            }
            s
        }
        // A single wrapped type plus one integer count has no ambiguous
        // boundary to confuse (same reasoning as `List`/`Set` just above),
        // unlike `Map`/`Tuple`'s multi-argument join.
        Ty::Array(elem, count) => format!("Array{}_{}", count, mangle_ty(elem)),
        // Same reasoning as `Array` just above.
        Ty::Ring(elem, count) => format!("Ring{}_{}", count, mangle_ty(elem)),
        // `T` is always `Ty::Named`, whose own mangling has no ambiguous
        // boundary to confuse -- same reasoning as `List`/`Set` above.
        Ty::Table(inner) => format!("Table_{}", mangle_ty(inner)),
        // Closures are never used as a generic type argument today (no
        // syntax constructs a generic struct/enum/fn call site with a
        // closure-typed turbofish argument); this arm exists purely for
        // match exhaustiveness.
        Ty::Closure(params, ret) => {
            let param_str: Vec<String> = params.iter().map(mangle_ty).collect();
            format!("Fn_{}_{}", param_str.join("_"), mangle_ty(ret))
        }
        // Like `Closure` above: `ptr` is never used as a generic type
        // argument (extern fns can't be generic, see
        // `Checker::check_extern_fn`); exists for match exhaustiveness.
        Ty::Ptr => "ptr".into(),
        Ty::Wrapping(inner) => format!("Wrapping_{}", mangle_ty(inner)),
        Ty::Fixed(bits, frac) => format!("Fixed{}_{}", bits, frac),
        // Never used as a generic type argument today (no generic struct/
        // enum in this codebase is parameterized over a time type); exists
        // for match exhaustiveness, same reasoning as `Closure`/`Ptr` above.
        Ty::Tick => "Tick".into(),
        Ty::Duration => "Duration".into(),
        Ty::Instant => "Instant".into(),
        // Never used as a generic type argument today, same reasoning as
        // `Tick`/`Duration`/`Instant` above -- exists for match exhaustiveness.
        Ty::Bytes => "Bytes".into(),
        Ty::Symbol => "Symbol".into(),
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
        Ty::I8 => Type::Named("i8".into()),
        Ty::U8 => Type::Named("u8".into()),
        Ty::I16 => Type::Named("i16".into()),
        Ty::U16 => Type::Named("u16".into()),
        Ty::U32 => Type::Named("u32".into()),
        Ty::I64 => Type::Named("i64".into()),
        Ty::U64 => Type::Named("u64".into()),
        Ty::F64 => Type::Named("f64".into()),
        Ty::Char => Type::Named("char".into()),
        Ty::Str => Type::Named("str".into()),
        Ty::Bool => Type::Named("bool".into()),
        Ty::Vec2 => Type::Named("Vec2".into()),
        Ty::Vec3 => Type::Named("Vec3".into()),
        Ty::Vec4 => Type::Named("Vec4".into()),
        Ty::Mat4 => Type::Named("Mat4".into()),
        Ty::Named(n) => Type::Named(n.clone()),
        Ty::Enum(n) => Type::Named(n.clone()),
        Ty::GenRef(inner) => Type::Generic("GenRef".into(), vec![ty_to_type(inner)]),
        Ty::Handle(inner) => Type::Generic("Handle".into(), vec![ty_to_type(inner)]),
        Ty::List(inner) => Type::Generic("List".into(), vec![ty_to_type(inner)]),
        Ty::Map(k, v) => Type::Generic("Map".into(), vec![ty_to_type(k), ty_to_type(v)]),
        Ty::Set(inner) => Type::Generic("Set".into(), vec![ty_to_type(inner)]),
        Ty::Tuple(elems) => Type::Tuple(elems.iter().map(ty_to_type).collect()),
        Ty::Array(elem, count) => Type::Array(Box::new(ty_to_type(elem)), *count),
        Ty::Ring(elem, count) => Type::Ring(Box::new(ty_to_type(elem)), *count),
        Ty::Table(inner) => Type::Generic("Table".into(), vec![ty_to_type(inner)]),
        Ty::Closure(params, ret) => Type::Fn(params.iter().map(ty_to_type).collect(), Box::new(ty_to_type(ret))),
        Ty::Ptr => Type::Named("ptr".into()),
        Ty::Wrapping(inner) => Type::Generic("Wrapping".into(), vec![ty_to_type(inner)]),
        Ty::Fixed(bits, frac) => Type::Fixed(*bits, *frac),
        Ty::Tick => Type::Named("Tick".into()),
        Ty::Duration => Type::Named("Duration".into()),
        Ty::Instant => Type::Named("Instant".into()),
        Ty::Bytes => Type::Named("Bytes".into()),
        Ty::Symbol => Type::Named("Symbol".into()),
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
        Type::Tuple(elems) => Type::Tuple(elems.iter().map(|e| subst_type(e, subst)).collect()),
        Type::Array(elem, count) => Type::Array(Box::new(subst_type(elem, subst)), *count),
        Type::Ring(elem, count) => Type::Ring(Box::new(subst_type(elem, subst)), *count),
        // No type parameters inside to substitute -- `Bits`/`Frac` are bare
        // integer literals, not `Type`s.
        Type::Fixed(bits, frac) => Type::Fixed(*bits, *frac),
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
        Stmt::Spawn { arena, args, arg_names, span } => Stmt::Spawn {
            arena: arena.clone(),
            args: args.iter().map(|a| subst_expr(a, subst)).collect(),
            arg_names: arg_names.clone(),
            span: *span,
        },
        Stmt::Despawn { arena, index, span } => {
            Stmt::Despawn { arena: arena.clone(), index: subst_expr(index, subst), span: *span }
        }
    }
}

fn subst_expr(expr: &Expr, subst: &HashMap<String, Type>) -> Expr {
    match expr {
        Expr::Int(..) | Expr::Float(..) | Expr::Str(..) | Expr::Bool(..) | Expr::Char(..) | Expr::Ident(..) | Expr::SelfExpr(..) => expr.clone(),
        Expr::FStr(parts, span) => Expr::FStr(
            parts.iter().map(|p| match p {
                FStrExpr::Literal(s) => FStrExpr::Literal(s.clone()),
                FStrExpr::Expr(inner) => FStrExpr::Expr(Box::new(subst_expr(inner, subst))),
            }).collect(),
            *span,
        ),
        Expr::Field { base, field, span } => Expr::Field { base: Box::new(subst_expr(base, subst)), field: field.clone(), span: *span },
        Expr::Call { callee, args, arg_names, span } => Expr::Call {
            callee: Box::new(subst_expr(callee, subst)),
            args: args.iter().map(|a| subst_expr(a, subst)).collect(),
            arg_names: arg_names.clone(),
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
        Expr::StructLit { name, type_args, args, arg_names, span } => Expr::StructLit {
            name: name.clone(),
            type_args: type_args.iter().map(|t| subst_type(t, subst)).collect(),
            args: args.iter().map(|a| subst_expr(a, subst)).collect(),
            arg_names: arg_names.clone(),
            span: *span,
        },
        Expr::If { cond, then_block, else_block, span } => Expr::If {
            cond: Box::new(subst_expr(cond, subst)),
            then_block: subst_block(then_block, subst),
            else_block: else_block.as_ref().map(|b| subst_block(b, subst)),
            span: *span,
        },
        Expr::GenRefCreate { inner_ty, value, is_handle, span } => Expr::GenRefCreate {
            inner_ty: subst_type(inner_ty, subst),
            value: Box::new(subst_expr(value, subst)),
            is_handle: *is_handle,
            span: *span,
        },
        Expr::GenRefIndex { base, index, span } => {
            Expr::GenRefIndex { base: Box::new(subst_expr(base, subst)), index: Box::new(subst_expr(index, subst)), span: *span }
        }
        Expr::EnumVariant { enum_name, type_args, variant, args, arg_names, span } => Expr::EnumVariant {
            enum_name: enum_name.clone(),
            type_args: type_args.iter().map(|t| subst_type(t, subst)).collect(),
            variant: variant.clone(),
            args: args.iter().map(|a| subst_expr(a, subst)).collect(),
            arg_names: arg_names.clone(),
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
        Expr::Try { inner, span } => Expr::Try { inner: Box::new(subst_expr(inner, subst)), span: *span },
        Expr::TupleLit(elems, span) => Expr::TupleLit(elems.iter().map(|e| subst_expr(e, subst)).collect(), *span),
        Expr::TupleIndex { base, index, span } => {
            Expr::TupleIndex { base: Box::new(subst_expr(base, subst)), index: *index, span: *span }
        }
        Expr::ArrayRepeat { value, count, span } => {
            Expr::ArrayRepeat { value: Box::new(subst_expr(value, subst)), count: *count, span: *span }
        }
        Expr::RingNew { elem_ty, count, span } => {
            Expr::RingNew { elem_ty: subst_type(elem_ty, subst), count: *count, span: *span }
        }
        Expr::Cast { expr, ty, span } => {
            Expr::Cast { expr: Box::new(subst_expr(expr, subst)), ty: subst_type(ty, subst), span: *span }
        }
        Expr::WrappingNew { inner_ty, value, span } => Expr::WrappingNew {
            inner_ty: subst_type(inner_ty, subst),
            value: Box::new(subst_expr(value, subst)),
            span: *span,
        },
        Expr::FixedNew { bits, frac, value, span } => {
            Expr::FixedNew { bits: *bits, frac: *frac, value: Box::new(subst_expr(value, subst)), span: *span }
        }
    }
}

// ===== `par`/`swarm` transitive hazard detection ============================

/// Compute the set of free-function/method names whose body -- directly, or
/// transitively through any named function/method it calls -- contains a
/// `spawn`, `despawn`, or `frame:` statement. Operates on the raw (untyped)
/// AST so it can run once, up front, before any item is type-checked (see
/// `Checker::check`); keyed by name only (methods share the free-function
/// namespace here, mirroring `Checker::functions`' own pre-existing flat
/// keying -- see §1.7's note on that design elsewhere in this codebase).
///
/// This is a sound over-approximation, not a precise one: an indirect call
/// through a closure/function value can't be resolved to a name here, so it
/// contributes no edge to the call graph (the closure literal itself is
/// separately banned outright inside a `par`/`swarm` body, see
/// `par_analysis::walk_par_expr`'s `TypedExpr::Closure` arm) -- so it can
/// occasionally reject a call to a function name that happens to share a
/// name with a hazardous one on an unrelated struct, but it never misses a
/// real hazard reachable through an ordinary named call chain. That
/// soundness claim requires every same-named method (methods share the
/// free-function namespace here) to be scanned, not just one of them --
/// `bodies` therefore collects *all* bodies sharing a name rather than
/// letting a later `impl` block's method silently overwrite an earlier
/// one's entry, which previously could discard a real hazard entirely
/// (e.g. `struct A::tick` opening a `frame:` and `struct B::tick` not,
/// declared in that order, would leave `"tick"` unmarked since `B::tick`'s
/// insert clobbered `A::tick`'s in the map -- a call through a value
/// statically typed `A` inside a `par`/`swarm` body would then wrongly
/// type-check).
fn compute_unsafe_par_fns(module: &Module) -> HashSet<String> {
    let mut bodies: HashMap<String, Vec<&Block>> = HashMap::new();
    for item in &module.items {
        match item {
            Item::Fn(f) => bodies.entry(f.sig.name.clone()).or_default().push(&f.body),
            Item::Impl(blk) => {
                for m in &blk.methods {
                    bodies.entry(m.sig.name.clone()).or_default().push(&m.body);
                }
            }
            _ => {}
        }
    }

    let mut unsafe_set: HashSet<String> = HashSet::new();
    let mut call_graph: HashMap<String, HashSet<String>> = HashMap::new();
    for (name, name_bodies) in &bodies {
        let mut direct_hazard = false;
        let mut called = HashSet::new();
        for body in name_bodies {
            scan_block_for_par_hazards(body, &mut direct_hazard, &mut called);
        }
        if direct_hazard {
            unsafe_set.insert(name.clone());
        }
        call_graph.insert(name.clone(), called);
    }

    // Fixed-point propagation: a function that calls an unsafe function is
    // itself unsafe, however many calls deep the original hazard is nested.
    loop {
        let mut changed = false;
        for (name, callees) in &call_graph {
            if !unsafe_set.contains(name) && callees.iter().any(|c| unsafe_set.contains(c)) {
                unsafe_set.insert(name.clone());
                changed = true;
            }
        }
        if !changed {
            break;
        }
    }
    unsafe_set
}

/// Scan a block for `spawn`/`despawn`/`frame:` (setting `hazard` if found)
/// and collect the names of every function/method it calls (by bare `Ident`
/// callee or `Field`-based method callee) into `called`, recursing into every
/// nested block (`if`/`while`/`for`/`frame`/`par`/`match` arms) so a hazard
/// nested arbitrarily deep in ordinary control flow is still found. Does not
/// recurse into a lambda literal's body: whether that body ever executes
/// depends on whether/when the closure value it produces is later called,
/// which this purely-syntactic, per-function scan can't determine.
fn scan_block_for_par_hazards(block: &Block, hazard: &mut bool, called: &mut HashSet<String>) {
    for stmt in &block.stmts {
        scan_stmt_for_par_hazards(stmt, hazard, called);
    }
}

fn scan_stmt_for_par_hazards(stmt: &Stmt, hazard: &mut bool, called: &mut HashSet<String>) {
    match stmt {
        Stmt::Let { value, .. } => scan_expr_for_par_hazards(value, hazard, called),
        Stmt::Assign { target, value, .. } => {
            scan_expr_for_par_hazards(target, hazard, called);
            scan_expr_for_par_hazards(value, hazard, called);
            // Writing through a `[..]` index (`Expr::GenRefIndex` -- see its
            // own doc comment for why this one AST node covers every
            // bracketed index syntax, `GenRef`/`List`/`Array`/`Ring`/`Table`
            // alike, until the checker later disambiguates it by type) can
            // reach a `GenRef` dereference into *another*, shared arena slot
            // -- e.g. `self.target[0].hp -= dmg` where `self.target:
            // GenRef<Player>` -- rather than the receiver's own disjoint-
            // per-iteration fields. Two different loop items' `target`
            // fields can point at the same arena slot, so this races across
            // worker threads exactly like `spawn`/`despawn`/`frame:` above,
            // but was previously undetected: `par_analysis.rs`'s typed
            // disjointness proof only ever looks at the `par`/`swarm` body's
            // *own* statements, not at what a called function does. This
            // syntactic pre-pass has no type information yet (it runs on the
            // raw AST before any body is checked -- see
            // `compute_unsafe_par_fns`'s own doc comment), so it can't tell
            // a genuinely-safe index write (into a `List`/`Array`/`Ring`/
            // `Table` this function built and owns outright) apart from an
            // unsafe `GenRef` dereference -- so, like those three, *any*
            // index write reached through a called function is
            // conservatively treated as unprovable disjoint.
            if contains_index_write(target) {
                *hazard = true;
            }
        }
        Stmt::Return { value, .. } => {
            if let Some(v) = value {
                scan_expr_for_par_hazards(v, hazard, called);
            }
        }
        Stmt::Expr(e) => scan_expr_for_par_hazards(e, hazard, called),
        Stmt::If { cond, then_block, else_block, .. } => {
            scan_expr_for_par_hazards(cond, hazard, called);
            scan_block_for_par_hazards(then_block, hazard, called);
            if let Some(b) = else_block {
                scan_block_for_par_hazards(b, hazard, called);
            }
        }
        Stmt::While { cond, body, else_block, .. } => {
            scan_expr_for_par_hazards(cond, hazard, called);
            scan_block_for_par_hazards(body, hazard, called);
            if let Some(b) = else_block {
                scan_block_for_par_hazards(b, hazard, called);
            }
        }
        Stmt::For { start, end, body, .. } => {
            scan_expr_for_par_hazards(start, hazard, called);
            scan_expr_for_par_hazards(end, hazard, called);
            scan_block_for_par_hazards(body, hazard, called);
        }
        Stmt::Break { .. } | Stmt::Continue { .. } | Stmt::Yield { .. } => {}
        // Opening a `frame:` block is itself a hazard: `@frame.off`/
        // `@frame.buf` are single shared globals, so a callee that opens one
        // races the same way a callee that `spawn`s/`despawn`s does -- see
        // `Codegen::emit_par_stmt`'s doc comment on why `in_frame` being a
        // codegen-time-only flag doesn't protect a nested `frame:` inside a
        // called function.
        Stmt::Frame { body, .. } => {
            *hazard = true;
            scan_block_for_par_hazards(body, hazard, called);
        }
        Stmt::Par { body, .. } => scan_block_for_par_hazards(body, hazard, called),
        Stmt::Spawn { args, .. } => {
            *hazard = true;
            for a in args {
                scan_expr_for_par_hazards(a, hazard, called);
            }
        }
        Stmt::Despawn { index, .. } => {
            *hazard = true;
            scan_expr_for_par_hazards(index, hazard, called);
        }
    }
}

/// True if `expr` (an assignment target's place-expression, e.g. `self.a.b`,
/// `x[0].y`, `x.y[0]`) writes through a `[..]` index anywhere in its base
/// chain -- see `Expr::GenRefIndex`'s doc comment for why the same untyped
/// AST node covers every bracketed index syntax regardless of what it turns
/// out to mean once the checker resolves `base`'s type. Used by
/// `scan_stmt_for_par_hazards`'s `Stmt::Assign` arm above.
fn contains_index_write(expr: &Expr) -> bool {
    match expr {
        Expr::GenRefIndex { .. } => true,
        Expr::Field { base, .. } | Expr::TupleIndex { base, .. } => contains_index_write(base),
        _ => false,
    }
}

fn scan_expr_for_par_hazards(expr: &Expr, hazard: &mut bool, called: &mut HashSet<String>) {
    match expr {
        Expr::Int(..) | Expr::Float(..) | Expr::Str(..) | Expr::Bool(..) | Expr::Char(..) | Expr::Ident(..) | Expr::SelfExpr(..) => {}
        Expr::FStr(parts, _) => {
            for p in parts {
                if let FStrExpr::Expr(e) = p {
                    scan_expr_for_par_hazards(e, hazard, called);
                }
            }
        }
        Expr::Field { base, .. } => scan_expr_for_par_hazards(base, hazard, called),
        Expr::Call { callee, args, .. } => {
            match callee.as_ref() {
                Expr::Ident(name, _) => { called.insert(name.clone()); }
                Expr::Field { field, .. } => { called.insert(field.clone()); }
                _ => {}
            }
            scan_expr_for_par_hazards(callee, hazard, called);
            for a in args {
                scan_expr_for_par_hazards(a, hazard, called);
            }
        }
        Expr::Binary { lhs, rhs, .. } => {
            scan_expr_for_par_hazards(lhs, hazard, called);
            scan_expr_for_par_hazards(rhs, hazard, called);
        }
        Expr::Unary { operand, .. } => scan_expr_for_par_hazards(operand, hazard, called),
        Expr::Match { scrutinee, arms, .. } => {
            scan_expr_for_par_hazards(scrutinee, hazard, called);
            for arm in arms {
                scan_block_for_par_hazards(&arm.body, hazard, called);
            }
        }
        Expr::StructLit { args, .. } => {
            for a in args {
                scan_expr_for_par_hazards(a, hazard, called);
            }
        }
        Expr::If { cond, then_block, else_block, .. } => {
            scan_expr_for_par_hazards(cond, hazard, called);
            scan_block_for_par_hazards(then_block, hazard, called);
            if let Some(b) = else_block {
                scan_block_for_par_hazards(b, hazard, called);
            }
        }
        Expr::GenRefCreate { value, .. } => scan_expr_for_par_hazards(value, hazard, called),
        Expr::GenRefIndex { base, index, .. } => {
            scan_expr_for_par_hazards(base, hazard, called);
            scan_expr_for_par_hazards(index, hazard, called);
        }
        Expr::EnumVariant { args, .. } => {
            for a in args {
                scan_expr_for_par_hazards(a, hazard, called);
            }
        }
        // Not recursed into -- see `scan_block_for_par_hazards`'s doc comment.
        Expr::Lambda { .. } => {}
        Expr::ListLit(elems, _) => {
            for e in elems {
                scan_expr_for_par_hazards(e, hazard, called);
            }
        }
        Expr::Try { inner, .. } => scan_expr_for_par_hazards(inner, hazard, called),
        Expr::TupleLit(elems, _) => {
            for e in elems {
                scan_expr_for_par_hazards(e, hazard, called);
            }
        }
        Expr::TupleIndex { base, .. } => scan_expr_for_par_hazards(base, hazard, called),
        Expr::ArrayRepeat { value, .. } => scan_expr_for_par_hazards(value, hazard, called),
        // `Ring<T, N>()` has no sub-expressions to recurse into (mirrors
        // `List<T>()`/`Map<K,V>()`/`Set<T>()`, which are plain `StructLit`s
        // with only an (already-scanned, via the `StructLit` arm above)
        // empty `args` list).
        Expr::RingNew { .. } => {}
        Expr::Cast { expr, .. } => scan_expr_for_par_hazards(expr, hazard, called),
        Expr::WrappingNew { value, .. } => scan_expr_for_par_hazards(value, hazard, called),
        Expr::FixedNew { value, .. } => scan_expr_for_par_hazards(value, hazard, called),
    }
}

/// The root identifier a place expression (`x`, `x.a.b`, `self.a`, `x.0`,
/// `x[0]`) writes through, or `None` if it isn't a simple identifier/
/// field/tuple-index/array-index chain. Deliberately ungated on any
/// intermediate expression's own type (unlike `frame_analysis`'s
/// `frame_escape_source`/`local_struct_receiver`, which only care about
/// `Ty::Named` values) -- a tuple/array projection's *base* is never itself
/// `Ty::Named` (it's `Ty::Tuple`/`Ty::Array`), so this just needs to find
/// the ultimate root binding, leaving any type-relevance gating to the caller.
fn root_ident(expr: &TypedExpr) -> Option<String> {
    match expr {
        TypedExpr::Ident { name, .. } => Some(name.clone()),
        TypedExpr::SelfExpr(..) => Some("self".to_string()),
        TypedExpr::Field { base, .. } => root_ident(base),
        TypedExpr::TupleIndex { base, .. } => root_ident(base),
        TypedExpr::ArrayIndex { base, .. } => root_ident(base),
        TypedExpr::RingIndex { base, .. } => root_ident(base),
        // Same rule as `ArrayIndex`/`RingIndex`/`TableIndex` above -- a
        // body-local `List<T>` write (`t[0] = v` where `t` is declared
        // inside the `par`/`swarm` body) was previously rejected as an
        // "unsupported mutation target" even though it's exactly as safe as
        // the other three inline/heap collection index-write cases (see
        // `accepts_table_index_write_on_body_local_table_inside_par_body`
        // for the identical bug already fixed for `Table<T>`).
        TypedExpr::ListIndex { base, .. } => root_ident(base),
        // Same rule as `ArrayIndex`/`RingIndex` above -- needed so
        // `table[i] = v` (the one supported `Table<T>` write path, see
        // `Ty::Table`'s doc comment) inside a `par`/`swarm` body resolves to
        // the table's own root binding instead of falling into this
        // function's `_ => None` catch-all, which `walk_par_stmt`'s
        // `TypedStmt::Assign` arm treats as an unconditionally-rejected
        // "unsupported mutation target" regardless of whether the table is
        // actually body-local and safe to mutate.
        TypedExpr::TableIndex { base, .. } => root_ident(base),
        _ => None,
    }
}
