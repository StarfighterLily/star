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
    "CreateThread", "WaitForSingleObject", "CloseHandle",
    "CreateSemaphoreA", "ReleaseSemaphore", "GetCurrentThreadId",
    "star_rc_alloc", "star_rc_retain", "star_rc_release",
    // `env_get`/`env_set` builtins -- see `crate::codegen::os`.
    "getenv", "_putenv",
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
    methods: HashMap<String, (Vec<Ty>, Option<Ty>)>,
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
            mono_items: Vec::new(),
            errors: Vec::new(),
            loop_depth: 0,
            unsafe_par_fns: HashSet::new(),
            current_ret_ty: None,
            extern_fn_names_seen: HashSet::new(),
            mono_depth: 0,
        }
    }

    /// A generous bound on nested generic monomorphization -- see
    /// `mono_depth`'s doc comment. High enough that no real, terminating
    /// generic usage (including deliberately nested wrappers a few levels
    /// deep) should ever hit it, but low enough to fail fast with a clean
    /// diagnostic well before exhausting the real Rust call stack.
    const MAX_MONO_DEPTH: u32 = 64;

    pub fn check(&mut self, module: &Module) -> Result<TypedModule, Vec<Diagnostic>> {
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
        // the user never wrote rather than at their own source. Doesn't cover
        // an `extern "C" fn` colliding with an ordinary `fn`'s name -- that
        // narrower gap is left for a future round -- extern-fn-vs-extern-fn
        // is already caught separately by `extern_fn_names_seen`.
        let mut type_names_seen: HashSet<String> = HashSet::new();
        let mut value_names_seen: HashSet<String> = HashSet::new();
        let mut arena_names_seen: HashSet<String> = HashSet::new();

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
                    if !value_names_seen.insert(f.sig.name.clone()) {
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
                        let key = format!("{}#{}", blk.type_name, m.sig.name);
                        self.methods.insert(key, (param_tys, ret_ty));
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
            Item::ExternFn(e) => self.check_extern_fn(e),
        }
    }

    /// The types an `extern "C"` signature may use, in either parameter or
    /// return position -- everything else (struct/`List`/`GenRef`/`Enum`/
    /// `Closure`) has no defined C-ABI layout in this compiler and is
    /// rejected outright rather than silently emitting IR whose calling
    /// convention doesn't match the real foreign symbol.
    fn is_ffi_scalar_ty(ty: &Ty) -> bool {
        matches!(ty, Ty::Int | Ty::Float | Ty::Ptr)
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
                format!("extern \"C\" parameter `{}` has unsupported type `{:?}`; only int, float, ptr, and str are allowed", p.name, p.ty),
                p.span,
            );
        }
        if let Some(ret) = &sig.ret {
            if !Self::is_ffi_scalar_ty(ret) {
                self.error(
                    format!("extern \"C\" return type `{:?}` is unsupported; only int, float, and ptr are allowed (use `ptr_to_str` to bridge a returned `char*`)", ret),
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
                "ptr" => Ty::Ptr,
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
        // Like `Closure` above: `ptr` is never used as a generic type
        // argument (extern fns can't be generic, see
        // `Checker::check_extern_fn`); exists for match exhaustiveness.
        Ty::Ptr => "ptr".into(),
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
        Ty::Ptr => Type::Named("ptr".into()),
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
/// real hazard reachable through an ordinary named call chain.
fn compute_unsafe_par_fns(module: &Module) -> HashSet<String> {
    let mut bodies: HashMap<String, &Block> = HashMap::new();
    for item in &module.items {
        match item {
            Item::Fn(f) => { bodies.insert(f.sig.name.clone(), &f.body); }
            Item::Impl(blk) => {
                for m in &blk.methods {
                    bodies.insert(m.sig.name.clone(), &m.body);
                }
            }
            _ => {}
        }
    }

    let mut unsafe_set: HashSet<String> = HashSet::new();
    let mut call_graph: HashMap<String, HashSet<String>> = HashMap::new();
    for (name, body) in &bodies {
        let mut direct_hazard = false;
        let mut called = HashSet::new();
        scan_block_for_par_hazards(body, &mut direct_hazard, &mut called);
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

fn scan_expr_for_par_hazards(expr: &Expr, hazard: &mut bool, called: &mut HashSet<String>) {
    match expr {
        Expr::Int(..) | Expr::Float(..) | Expr::Str(..) | Expr::Bool(..) | Expr::Ident(..) | Expr::SelfExpr(..) => {}
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
