//! LLVM IR codegen: walks the typed AST and emits textual `.ll` IR.
//!
//! The emitted IR is written to a file and compiled with the installed
//! `clang.exe` to produce a native executable.
//!
//! The `Codegen` struct and its core helpers (type lowering, symbol table,
//! register/label allocation, "place" addressing) live here; each area of
//! the emitter has its own `impl Codegen` block in a sibling submodule:
//! `reflect` (struct decls + reflection metadata), `arena` (arena decls,
//! `spawn`/`despawn`/`par`, `GenRef`), `stmt` (statement/function
//! emission), `expr` (expression emission), `vector_math` (vector/matrix
//! arithmetic), and `builtins` (the `print`/math/string standard library).

mod arena;
mod array;
mod bitfield;
mod builtins;
mod closure;
mod eq;
mod expr;
mod file_io;
mod fixed;
mod flags;
mod list;
mod map;
mod net;
mod os;
mod par_pool;
mod rc;
mod reflect;
mod ring;
mod set;
mod stmt;
mod symbol;
mod table;
mod time;
mod vector_math;
mod wrapping;

use std::fmt::Write;

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
    /// The `bool` is whether this method actually declares `self` as its
    /// first parameter -- a method may omit it entirely (an "associated
    /// function" with no receiver, still called via `obj.method(...)`
    /// syntax), in which case the call site must not pass a receiver
    /// pointer as its first argument (see `emit_call_expr`'s `Field`-callee
    /// branch).
    methods: std::collections::HashMap<String, (String, bool)>,
    errors: Vec<Diagnostic>,
    in_frame: bool,
    /// True while emitting `main`'s body. `main` is always forced to lower
    /// to `i32 @main(...)` regardless of its declared return type (see
    /// `emit_fn`'s `is_main` special case) -- a bare `return` (no value)
    /// inside it must therefore emit `ret i32 0`, not the ordinary `ret
    /// void`, or the function body would contain a terminator whose type
    /// disagrees with the function's own declared signature (invalid IR).
    in_main: bool,
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
    /// Variant name lists per enum, in declaration order, so an
    /// `EnumName::Variant` literal or match pattern can be lowered to its
    /// dense `i32` discriminant.
    enum_variants: std::collections::HashMap<String, Vec<String>>,
    /// Per-variant payload field types (in declaration order), parallel to
    /// `enum_variants`. An empty inner `Vec` means a fieldless variant; an
    /// enum where every variant is fieldless is lowered directly to `i32`
    /// (see `llvm_ty`), otherwise to a tagged-union struct (see
    /// `emit_enum_decl`).
    enum_variant_fields: std::collections::HashMap<String, Vec<Vec<Ty>>>,
    /// Stack of `(continue_label, break_label, owned_stack depth at loop
    /// entry)` for the innermost enclosing loops, so `break`/`continue`
    /// codegen can jump to the right block (without threading loop context
    /// through every statement emitter) and release exactly the RC-owning
    /// locals declared since the loop was entered -- see `rc.rs`.
    loop_stack: Vec<(String, String, usize)>,
    /// Stack of scope frames, one per currently-open lexical block (function
    /// body, closure body, `if`/`while`/`for`/`frame` body, `match` arm
    /// body), each holding the `(sym_ptr, Ty)` of every RC-owning local
    /// (`Str`/`Closure`, or a struct/`List` transitively containing one)
    /// `let`-bound or parameter-bound directly in that block. Consumed by
    /// `rc.rs`'s `push_scope`/`pop_scope`/`track_owned` to emit a matching
    /// `star_rc_release` when each scope ends (normally or via an early
    /// `return`/`break`/`continue`), closing the leaks documented in
    /// todo.md §3.6.
    owned_stack: Vec<Vec<(String, Ty)>>,
    /// Maps a top-level function name -> the name of the no-capture,
    /// envp-ignoring thunk generated the first time that function is used as
    /// a first-class value (see `Codegen::emit_fn_value`), so referencing the
    /// same function as a value more than once reuses one thunk instead of
    /// emitting a duplicate `define`.
    fn_value_thunks: std::collections::HashMap<String, String>,
    /// Maps a mangled element-type key (`Codegen::mangle_ty`) -> the name of
    /// the `list_release_<mangled>` thunk generated the first time a
    /// `List<T>` of that element type is allocated (list literal, `push`
    /// grow, or a copy-on-write clone), so every allocation of the same
    /// element type reuses one thunk instead of emitting a duplicate
    /// `define` (see `Codegen::list_release_thunk_operand`,
    /// `crate::codegen::list`).
    list_release_thunks: std::collections::HashMap<String, String>,
    /// Same purpose as `list_release_thunks`, keyed by `Codegen::mangle_ty`
    /// of the element type, for `Set<T>` (see `crate::codegen::set`).
    set_release_thunks: std::collections::HashMap<String, String>,
    /// Same purpose as `list_release_thunks`, keyed by
    /// `"{mangled_key}_{mangled_val}"`, for `Map<K,V>` (see
    /// `crate::codegen::map`).
    map_release_thunks: std::collections::HashMap<String, String>,
    /// Same purpose as `list_release_thunks`, keyed by `Codegen::mangle_ty`
    /// of `Ty::Named(struct_name)`, for `Table<T>` (see
    /// `crate::codegen::table`).
    table_release_thunks: std::collections::HashMap<String, String>,
    /// Maps a mangled key/element-type key -> the name of the
    /// `eq_<mangled>` structural-equality function generated the first time
    /// a `Map<K,_>`/`Set<T>` of that key/element type is used (see
    /// `crate::codegen::eq`), so every `Map`/`Set` sharing a key/element
    /// type reuses one generated function instead of each emitting a
    /// duplicate `define`.
    eq_fns: std::collections::HashMap<String, String>,
    /// True once the persistent `par`/`swarm` worker-thread pool's static
    /// machinery (globals, `@par.pool.worker_main`, `@par.pool.ensure_init`)
    /// has been pushed to `pending_top`. Guards against re-emitting it for a
    /// program with more than one `par`/`swarm` statement -- see
    /// `par_pool::ensure_par_pool_emitted`.
    par_pool_emitted: bool,
    /// Names of every `extern "C" fn` declared in the module, populated
    /// before any function body is emitted (see `emit`). Consulted by
    /// `TypedExpr::Call` codegen (`expr.rs`) to route a call through
    /// `emit_extern_call` instead of the ordinary `emit_call_expr` --
    /// they need different argument-passing conventions for RC'd (`str`)
    /// arguments, see `emit_extern_call`'s own doc comment.
    extern_fns: std::collections::HashSet<String>,
    /// Copied from `TypedModule::generic_instantiations` at the start of
    /// `emit` -- see that field's own doc comment. Consulted by
    /// `reflect_type_name` to render a monomorphized generic struct/enum's
    /// mangled `Ty::Named`/`Ty::Enum` name (`Box__i32`) as a real generic
    /// spelling (`Box<i32>`) in `@export`/`@tweakable` metadata.
    generic_instantiations: std::collections::HashMap<String, (String, Vec<Ty>)>,
    /// The label of the basic block most recently opened via `open_block`
    /// (reset to `"entry"` at the start of every function/worker/thunk).
    /// A `TypedExpr::If`/`TypedExpr::Match` branch's `phi` merge needs to
    /// name the block it's actually jumping to `end_label` *from* -- but
    /// that isn't necessarily the branch's own entry label (`if_then_N`)
    /// anymore by the time its trailing value has been computed, if
    /// evaluating that value itself opened further blocks of its own (a
    /// short-circuit `&&`/`||`, a list/`GenRef` index bounds check, a
    /// `frame:` allocation, a nested `if`/`match`, ...). Using the stale
    /// entry label there produced invalid LLVM IR ("PHI node entries do not
    /// match predecessors" / "instruction does not dominate all uses") for
    /// almost any nontrivial expression used as one arm of a value-producing
    /// `if`/`match` -- this field is threaded through `open_block` (the sole
    /// place every basic block in this codegen is opened) so those two call
    /// sites can ask "what block are we actually in right now" instead of
    /// assuming it never changed.
    current_label: String,
}

impl Codegen {
    /// Fixed capacity (element count) of every arena's backing array and its
    /// parallel generation array. See `emit_spawn_stmt`/`emit_arena_decl`.
    const ARENA_CAPACITY: u64 = 1024;

    /// Fixed byte capacity of the `frame:` bump allocator's backing buffer
    /// (`@frame.buf`). See `emit_frame_alloc_bytes`.
    const FRAME_BUF_SIZE: u64 = 4096;

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
            in_main: false,
            pending_top: Vec::new(),
            arena_by_elem: Vec::new(),
            enum_variants: std::collections::HashMap::new(),
            enum_variant_fields: std::collections::HashMap::new(),
            loop_stack: Vec::new(),
            owned_stack: Vec::new(),
            fn_value_thunks: std::collections::HashMap::new(),
            list_release_thunks: std::collections::HashMap::new(),
            set_release_thunks: std::collections::HashMap::new(),
            map_release_thunks: std::collections::HashMap::new(),
            table_release_thunks: std::collections::HashMap::new(),
            eq_fns: std::collections::HashMap::new(),
            par_pool_emitted: false,
            extern_fns: std::collections::HashSet::new(),
            generic_instantiations: std::collections::HashMap::new(),
            current_label: "entry".to_string(),
        }
    }

    /// Generate LLVM IR from a checked module, returning the `.ll` source.
    pub fn emit(&mut self, module: &TypedModule) -> Result<String, Vec<Diagnostic>> {
        self.line("; Star compiler -- LLVM IR");
        self.line("target triple = \"x86_64-w64-windows-gnu\"");
        self.line("");

        // Needed by `reflect_type_name` (via `emit_struct_decl` below), so
        // populate before any struct/enum text is emitted -- see
        // `generic_instantiations`'s own doc comment.
        self.generic_instantiations = module.generic_instantiations.clone();

        self.emit_builtins();

        // Register every extern fn's name before any function body is
        // emitted, so a call to one (from anywhere in the module,
        // regardless of declaration order) is recognized by
        // `TypedExpr::Call` codegen -- see `extern_fns`'s own doc comment.
        for item in &module.items {
            if let TypedItem::ExternFn(sig) = item {
                self.extern_fns.insert(sig.name.clone());
            }
        }

        // Register every struct's field list and every enum's variant/field
        // list *before* emitting any type's LLVM text below -- a struct
        // field's `llvm_ty` (specifically `enum_is_payload`, for a field
        // typed as a payload enum like `Option<T>`/`Result<T,E>`) needs the
        // referenced enum's registration to have already happened,
        // regardless of item order. This matters in practice because every
        // monomorphized generic enum instantiation is appended to
        // `module.items` *after* every item from the source (see
        // `Checker::check`'s `mono_items` doc comment), so a struct
        // declared anywhere in the source with an `Option<T>`/`Result<T,E>`-
        // typed field would otherwise always see that enum's registration
        // run too late. See `Codegen::register_struct`'s doc comment for the
        // real segfault this closes.
        for item in &module.items {
            match item {
                TypedItem::Struct(s) => self.register_struct(s),
                TypedItem::Enum(e) => self.register_enum(e),
                _ => {}
            }
        }

        for item in &module.items {
            match item {
                TypedItem::Struct(s) => self.emit_struct_decl(s),
                TypedItem::Arena(a) => self.emit_arena_decl(a),
                TypedItem::Enum(e) => self.emit_enum_decl(e),
                TypedItem::ExternFn(sig) => self.emit_extern_fn_decl(sig),
                _ => {}
            }
        }

        // Register method names so `obj.method()` can be resolved in codegen.
        // The LLVM function itself is emitted under a struct-mangled name
        // (`{struct}__{method}`, see `emit_fn`'s `owner` parameter) rather
        // than the bare method name -- two unrelated structs can declare a
        // method with the same name, and emitting both as `define @method`
        // is a duplicate global-symbol definition that clang rejects
        // ("invalid redefinition of function") on ordinary, correctly
        // type-checked source.
        for item in &module.items {
            if let TypedItem::Impl(blk) = item {
                for m in &blk.methods {
                    let has_self = m.sig.params.first().map(|p| p.is_self).unwrap_or(false);
                    self.methods.insert(
                        format!("{}#{}", blk.type_name, m.sig.name),
                        (format!("{}__{}", blk.type_name, m.sig.name), has_self),
                    );
                }
            }
        }

        for item in &module.items {
            match item {
                TypedItem::Impl(blk) => {
                    for m in &blk.methods { self.emit_fn(m, Some(&blk.type_name)); }
                }
                TypedItem::Fn(f) => self.emit_fn(f, None),
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
        // Materializes a non-print f-string value into an owned `str`
        // buffer -- see `Codegen::emit_expr`'s `TypedExpr::FStr` arm.
        self.line("declare i32 @snprintf(i8*, i64, i8*, ...)");
        self.line("declare i32 @puts(i8*)");
        self.line("declare noalias i8* @malloc(i64)");
        self.line("declare void @free(i8*)");
        // Used to abort loudly (rather than segfault or silently corrupt
        // adjacent global state) when a `frame:` block's bump allocator
        // would overflow its fixed backing buffer -- see
        // `Codegen::emit_frame_alloc`.
        self.line("declare void @exit(i32) noreturn");
        self.line("declare i32 @strlen(i8*)");
        // `read_line` builtin -- see `crate::codegen::builtins::emit_read_line`.
        self.line("declare i32 @getchar()");
        self.line("declare i8* @memcpy(i8*, i8*, i64)");
        self.line("declare i8* @strcpy(i8*, i8*)");
        self.line("declare i8* @strcat(i8*, i8*)");
        // `str`-keyed `Map`/`Set` structural equality -- see
        // `crate::codegen::eq`.
        self.line("declare i32 @strcmp(i8*, i8*)");
        // `file_open`/`file_read`/`file_read_line`/`file_write`/
        // `file_close`/`file_exists` builtins -- see `crate::codegen::file_io`.
        self.line("declare i8* @fopen(i8*, i8*)");
        self.line("declare i32 @fclose(i8*)");
        self.line("declare i64 @fread(i8*, i64, i64, i8*)");
        self.line("declare i64 @fwrite(i8*, i64, i64, i8*)");
        self.line("declare i32 @fseek(i8*, i32, i32)");
        self.line("declare i32 @ftell(i8*)");
        self.line("declare i32 @fgetc(i8*)");
        // `env_get`/`env_set` builtins -- see `crate::codegen::os`.
        self.line("declare i8* @getenv(i8*)");
        self.line("declare i32 @_putenv_s(i8*, i8*)");
        // `tcp_connect`/`tcp_send`/`tcp_recv`/`tcp_close` builtins -- see
        // `crate::codegen::net`. Winsock2 (`ws2_32.dll`) isn't part of this
        // target's implicitly-linked default libraries the way libc/
        // kernel32 are, so a Star program calling any of these needs
        // `-l ws2_32` passed explicitly at build time.
        self.line("declare i32 @WSAStartup(i16, i8*)");
        self.line("declare i8* @socket(i32, i32, i32)");
        self.line("declare i32 @connect(i8*, i8*, i32)");
        self.line("declare i32 @send(i8*, i8*, i32, i32)");
        self.line("declare i32 @recv(i8*, i8*, i32, i32)");
        self.line("declare i32 @closesocket(i8*)");
        self.line("declare i16 @htons(i16)");
        self.line("declare i32 @inet_addr(i8*)");
        self.line("declare i8* @CreateThread(i8*, i64, i8*, i8*, i32, i32*)");
        self.line("declare i32 @WaitForSingleObject(i8*, i32)");
        self.line("declare i32 @CloseHandle(i8*)");
        // Synchronization primitives backing the persistent `par`/`swarm`
        // worker-thread pool -- see `par_pool.rs`.
        self.line("declare i8* @CreateSemaphoreA(i8*, i32, i32, i8*)");
        self.line("declare i32 @ReleaseSemaphore(i8*, i32, i32*)");
        self.line("declare i32 @GetCurrentThreadId()");
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
        // Saturating float->int casts backing `expr as <int type>`
        // (`Codegen::emit_cast`'s float->int arm): plain `fptosi`/`fptoui`
        // are undefined behavior (poison) whenever the source value
        // doesn't fit the destination width or is NaN, unlike Rust's own
        // `as` (saturating since Rust 1.45 -- clamps to the destination's
        // min/max, and NaN becomes `0`), which `Checker::infer_expr`'s
        // `Expr::Cast` doc comment already claims to match. Declared for
        // every (width, signedness, source float type) combination a
        // cast's target/source pair can produce.
        for width in [8u32, 16, 32, 64] {
            for op in ["fptosi", "fptoui"] {
                for (fty, llfty) in [("f32", "float"), ("f64", "double")] {
                    self.line(&format!("declare i{w} @llvm.{op}.sat.i{w}.{fty}({llfty})", w = width, op = op, fty = fty, llfty = llfty));
                }
            }
        }
        // Overflow-checked integer arithmetic backing every explicit-width
        // integer type's `+`/`-`/`*` (`Codegen::emit_checked_sized_int_arith`)
        // -- declared for every (width, signedness, op) combination those
        // types actually use; `Ty::Int` (i32, signed) is deliberately excluded
        // since it keeps its original silent-wraparound behavior (see
        // `Ty::I8`'s doc comment for why every *other* width traps instead).
        for width in [8u32, 16, 64] {
            for sign in ["s", "u"] {
                for op in ["add", "sub", "mul"] {
                    self.line(&format!(
                        "declare {{ i{w}, i1 }} @llvm.{sign}{op}.with.overflow.i{w}(i{w}, i{w})",
                        w = width, sign = sign, op = op
                    ));
                }
            }
        }
        // `u32` shares `i32`'s bit width with `Ty::Int` but traps on the
        // *unsigned* overflow range instead -- only the unsigned intrinsics
        // are needed at 32 bits (the signed ones are `Ty::Int`'s domain,
        // which doesn't use this trap).
        for op in ["add", "sub", "mul"] {
            self.line(&format!("declare {{ i32, i1 }} @llvm.u{op}.with.overflow.i32(i32, i32)", op = op));
        }
        self.line("");
        // Field 1 (the slot index) stays `i32` -- bounded by `ARENA_CAPACITY`
        // (1024), nowhere near that width's range. Field 2 (the generation
        // counter) is `i64`, not `i32`: a narrower counter is reachable in
        // practice. Confirmed via a real, reproducible ABA bypass -- with a
        // 32-bit counter, ~2^31 despawn/spawn cycles on one arena slot (a
        // few seconds of a tight loop) wrap the live generation back to a
        // value a `GenRef` captured *before* the wraparound still matches,
        // so a stale handle is incorrectly treated as valid and reads the
        // new, unrelated occupant's data instead of being caught by
        // `emit_genref_index`'s staleness check. `i64` makes the identical
        // attack need ~2^63 cycles -- not reachable in any realistic
        // program's lifetime, closing the hole for real rather than just
        // raising the bar to a still-reachable number.
        self.line("%GenRef = type { i32, i64 }");
        self.line("");
        self.line("@frame.buf = global [4096 x i8] zeroinitializer");
        self.line("@frame.off = global i64 0");
        self.line("");
        // `args()` builtin -- see `crate::codegen::list::emit_args`. A
        // hosted `main` may be declared with no parameters at the Star
        // level (every program's always has been so far), but the process's
        // real C entry point always receives `argc`/`argv` from the OS/CRT
        // startup thunk -- `Codegen::emit_fn`'s `is_main` special case
        // always accepts them and stores them here once, at process start,
        // so `args()` can read them from any function without needing
        // `main` to thread them through explicitly.
        self.line("@star.argc = global i32 0");
        self.line("@star.argv = global i8** null");
        self.line("");
        // Seed state for the `rand`/`rand_range` builtins' xorshift32
        // generator -- a fixed nonzero default so runs are deterministic
        // (matters for a tick-based engine's replay/debugging story) unless
        // explicitly reseeded via `rand_seed(..)`.
        self.line("@rng.state = global i32 123456789");
        // Binary semaphore guarding every read/mutation of `@rng.state` --
        // same shape and same root cause as `@sym.lock` above: `rand`/
        // `rand_range`/`rand_seed` are *not* in `Checker::unsafe_par_fns`'s
        // ban list the way `spawn`/`despawn`/`frame:` are, so a `par`/
        // `swarm` body really can call them, and `emit_rand_next`'s
        // load-xorshift-store sequence (`crate::codegen::vector_math`) races
        // for real across the 4 concurrent worker threads with no lock:
        // confirmed via a real, reproducible run showing dozens of entities
        // within the same tick converging on the *identical* "random" value
        // (a lost-update race -- two threads both load the same `@rng.state`
        // before either stores, so both compute and store the same next
        // value), 5/5 runs. Unlike `Symbol`'s table (whose grow path can
        // heap-corrupt), a plain `i32` load/store can't itself tear, so this
        // is a silent wrong-answer race rather than a crash -- but the same
        // fix shape applies: a lock created once, unconditionally, in
        // `main`'s prologue (see `Codegen::emit_fn`'s `is_main` case),
        // before any user/`par`/`swarm` code can run.
        self.line("@rng.lock = global i8* null");
        self.line("");
        // The `Symbol` intern table -- see `crate::codegen::symbol` and
        // `Ty::Symbol`'s doc comment. A plain growable global array of owned
        // `str` object pointers (doubled on grow, the same recipe
        // `List<T>::push` uses -- see `crate::codegen::list`), since there's
        // exactly one intern table for the whole process, never copied or
        // reference-counted itself.
        self.line("@sym.data = global i8** null");
        self.line("@sym.len = global i64 0");
        self.line("@sym.cap = global i64 0");
        // Binary semaphore guarding every read/mutation of the three globals
        // above -- unlike `List<T>`/`Map<K,V>`, whose backing buffers are
        // per-value and therefore already disjoint across `par`/`swarm`
        // worker threads by the checker's own disjointness proof (see
        // `types::par_analysis`), the intern table is a single process-wide
        // shared mutable structure that `Symbol(..)`/`symbol_name(..)` are
        // *not* barred from calling inside a `par`/`swarm` body (neither is
        // in `Checker::unsafe_par_fns`'s ban list, unlike `spawn`/`despawn`/
        // `frame:`), so multiple worker threads really can call
        // `emit_symbol_intern`/`emit_symbol_name` concurrently. Without a
        // lock, `emit_symbol_intern`'s grow path (`malloc`/`memcpy`/`free`
        // against `@sym.data`) races for real: confirmed via a real
        // `STATUS_HEAP_CORRUPTION` (`0xC0000374`) crash, 5/5 runs, from a
        // `par` body where every worker thread interns the same growing set
        // of `Symbol` strings concurrently. `@sym.lock` is created once, up
        // front, in `main`'s prologue (see `Codegen::emit_fn`'s `is_main`
        // case) -- *before* user code runs and therefore before any
        // `par`/`swarm` dispatch could possibly spin up the worker pool, so
        // there is no first-use race in creating the lock itself (unlike
        // `par.pool.ensure_init`, which can safely stay lazy precisely
        // because dispatch ordering guarantees only the top-level caller
        // ever reaches its init branch -- no such ordering guarantee exists
        // for `Symbol`, since its first-ever call in a program could itself
        // be inside a `par` body).
        self.line("@sym.lock = global i8* null");
        self.line("");
        self.emit_rc_runtime();
    }

    /// One-time, single-threaded initialization of `@sym.lock` -- called
    /// unconditionally from `main`'s prologue (see `Codegen::emit_fn`),
    /// before any user code (and therefore before any `par`/`swarm`
    /// dispatch) can run. See `@sym.lock`'s own declaration comment above
    /// for why this can't safely be lazy the way `par.pool.ensure_init` is.
    pub(super) fn emit_sym_lock_init(&mut self) {
        let lock = self.tmp_name();
        self.line(&format!("  {} = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)", lock));
        self.line(&format!("  store i8* {}, i8** @sym.lock", lock));
    }

    /// One-time, single-threaded initialization of `@rng.lock` -- called
    /// unconditionally from `main`'s prologue (see `Codegen::emit_fn`),
    /// before any user code (and therefore before any `par`/`swarm`
    /// dispatch) can run. Mirrors `emit_sym_lock_init` exactly, for exactly
    /// the same reason: `@rng.state`'s first-ever access in a program could
    /// itself be inside a `par` body, so this can't safely be a lazy
    /// first-use init the way `par.pool.ensure_init` is.
    pub(super) fn emit_rng_lock_init(&mut self) {
        let lock = self.tmp_name();
        self.line(&format!("  {} = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)", lock));
        self.line(&format!("  store i8* {}, i8** @rng.lock", lock));
    }

    /// Emit the reference-counting runtime `concat`/closure environments
    /// (and, transitively, struct fields / list elements that hold either)
    /// use to be freed once their last owner goes away instead of leaking
    /// unboundedly -- see `todo.md` §3.6 and `crate::codegen::rc`.
    ///
    /// Every allocation gets a fixed 16-byte header
    /// `[i64 refcount][i8* release_fn]` immediately before the pointer the
    /// rest of the codegen treats as "the value" (so no *use* site of a
    /// `Str`/closure-env pointer needs to change, only creation/destruction).
    /// `release_fn` is an optional callback invoked just before the block is
    /// freed, given the same data pointer, to release any RC-bearing content
    /// nested *inside* the block (e.g. a closure's captured `str` fields) --
    /// `null` for an allocation with no such content (e.g. a plain `concat`
    /// result).
    fn emit_rc_runtime(&mut self) {
        self.line("define i8* @star_rc_alloc(i64 %size, i8* %release_fn) {");
        self.line("entry:");
        self.line("  %total = add i64 %size, 16");
        self.line("  %raw = call i8* @malloc(i64 %total)");
        self.line("  %hdr = bitcast i8* %raw to i64*");
        self.line("  store i64 1, i64* %hdr");
        self.line("  %relfn_slot_i8 = getelementptr inbounds i8, i8* %raw, i64 8");
        self.line("  %relfn_slot = bitcast i8* %relfn_slot_i8 to i8**");
        self.line("  store i8* %release_fn, i8** %relfn_slot");
        self.line("  %data = getelementptr inbounds i8, i8* %raw, i64 16");
        self.line("  ret i8* %data");
        self.line("}");
        self.line("");

        self.line("define void @star_rc_retain(i8* %p) {");
        self.line("entry:");
        self.line("  %isnull = icmp eq i8* %p, null");
        self.line("  br i1 %isnull, label %done, label %do");
        self.line("do:");
        self.line("  %hdr_i8 = getelementptr inbounds i8, i8* %p, i64 -16");
        self.line("  %hdr = bitcast i8* %hdr_i8 to i64*");
        // `par`/`swarm` dispatches the same generated code across several
        // real OS threads (see `crate::codegen::par_pool`), and its
        // disjointness proof only restricts *writes* to captured state (see
        // `crate::types::par_analysis`) -- a captured `Str`/closure merely
        // *read* inside a worker body still retains/releases this same
        // header concurrently, so every access here must be atomic to avoid
        // a lost-update race that can free a still-referenced block or leak
        // it.
        self.line("  %rc = load atomic i64, i64* %hdr seq_cst, align 8");
        // `-1` is the reserved "immortal" sentinel a string literal's
        // permanent global constant is given instead of a real refcount
        // (see `TypedExpr::Str`'s codegen) -- it must never be incremented
        // (or it would stop being distinguishable from a real count).
        self.line("  %is_immortal = icmp eq i64 %rc, -1");
        self.line("  br i1 %is_immortal, label %done, label %incr");
        self.line("incr:");
        self.line("  %rc1 = atomicrmw add i64* %hdr, i64 1 seq_cst");
        self.line("  br label %done");
        self.line("done:");
        self.line("  ret void");
        self.line("}");
        self.line("");

        self.line("define void @star_rc_release(i8* %p) {");
        self.line("entry:");
        self.line("  %isnull = icmp eq i8* %p, null");
        self.line("  br i1 %isnull, label %done, label %do");
        self.line("do:");
        self.line("  %hdr_i8 = getelementptr inbounds i8, i8* %p, i64 -16");
        self.line("  %hdr = bitcast i8* %hdr_i8 to i64*");
        self.line("  %rc = load atomic i64, i64* %hdr seq_cst, align 8");
        // Same immortal sentinel as `star_rc_retain` -- must never be
        // decremented or (worse) freed once it hits some unrelated value.
        self.line("  %is_immortal = icmp eq i64 %rc, -1");
        self.line("  br i1 %is_immortal, label %done, label %decr");
        self.line("decr:");
        // `atomicrmw sub` returns the *pre*-decrement value, so the block
        // becomes the last owner exactly when that value was `1`.
        self.line("  %rc_old = atomicrmw sub i64* %hdr, i64 1 seq_cst");
        self.line("  %iszero = icmp eq i64 %rc_old, 1");
        self.line("  br i1 %iszero, label %free, label %done");
        self.line("free:");
        self.line("  %relfn_slot_i8 = getelementptr inbounds i8, i8* %p, i64 -8");
        self.line("  %relfn_slot = bitcast i8* %relfn_slot_i8 to i8**");
        self.line("  %relfn = load i8*, i8** %relfn_slot");
        self.line("  %relfn_isnull = icmp eq i8* %relfn, null");
        self.line("  br i1 %relfn_isnull, label %dofree, label %callrelfn");
        self.line("callrelfn:");
        self.line("  %relfn_typed = bitcast i8* %relfn to void (i8*)*");
        self.line("  call void %relfn_typed(i8* %p)");
        self.line("  br label %dofree");
        self.line("dofree:");
        self.line("  call void @free(i8* %hdr_i8)");
        self.line("  br label %done");
        self.line("done:");
        self.line("  ret void");
        self.line("}");
        self.line("");
    }

    /// The LLVM ABI alignment (bytes) of a type on this compiler's sole
    /// `x86_64-w64-windows-gnu` target -- empirically confirmed via a
    /// standalone `.ll` probe (`getelementptr`+`ptrtoint` against a synthetic
    /// struct pairing each candidate type with a trailing `i64`, compiled
    /// and run for real) rather than assumed, since a wrong guess here would
    /// silently reproduce the exact padding bug this function exists to fix.
    /// Confirmed: `<2 x float>` aligns to 8 (its own size); `<3 x float>` and
    /// `<4 x float>` both align to 16 (LLVM stores a 3-wide float vector
    /// padded to a 4-wide vector's footprint); `[4 x <4 x float>]` (`Mat4`)
    /// inherits its element's 16-byte alignment; `{ i32, i64 }` (`GenRef`)
    /// aligns to 8, its widest (generation) field's alignment -- see
    /// `mod.rs`'s `%GenRef` decl doc comment for why the generation field is
    /// `i64`, not `i32`.
    fn type_align(&self, ty: &Ty) -> u32 {
        match ty {
            Ty::Int | Ty::Float => 4,
            Ty::I8 | Ty::U8 => 1,
            Ty::I16 | Ty::U16 => 2,
            Ty::U32 | Ty::Char => 4,
            Ty::I64 | Ty::U64 | Ty::F64 => 8,
            Ty::Bool => 1,
            Ty::Str | Ty::Ptr | Ty::List(_) | Ty::Map(..) | Ty::Set(_) | Ty::Table(_) | Ty::Closure(..) => 8,
            // Same layout as `Ty::GenRef` -- see `Ty::Handle`'s doc comment.
            Ty::GenRef(_) | Ty::Handle(_) => 8,
            Ty::Vec2 => 8,
            Ty::Vec3 | Ty::Vec4 | Ty::Mat4 => 16,
            Ty::Named(n) => self
                .struct_field_types
                .get(n)
                .map(|fields| fields.iter().map(|f| self.type_align(f)).max().unwrap_or(1))
                .unwrap_or(8),
            // Same rule as `Ty::Named` above, just with the element types
            // already in hand instead of a `struct_field_types` lookup.
            Ty::Tuple(elems) => elems.iter().map(|f| self.type_align(f)).max().unwrap_or(1),
            // An array's alignment is just its element's -- LLVM never pads
            // an array's own alignment wider than its element type's.
            Ty::Array(elem, _) => self.type_align(elem),
            // `{ [N x T], i64, i64 }` -- the two trailing `i64` fields (head,
            // len) need 8-byte alignment, same as any other `i64`-bearing
            // aggregate; wider only if the element type itself needs more.
            Ty::Ring(elem, _) => self.type_align(elem).max(8),
            // A fieldless enum lowers to a bare `i32` discriminant (align 4,
            // see `llvm_ty`); only a payload enum is the `{ i32, [W x i64] }`
            // tagged union that needs 8-byte alignment.
            Ty::Enum(n) => if self.enum_is_payload(n) { 8 } else { 4 },
            // Same LLVM integer type as `T` -- see `Ty::Wrapping`'s doc comment.
            Ty::Wrapping(inner) => self.type_align(inner),
            // `i{bits}` -- same alignment table as the sized-int arms above.
            Ty::Fixed(bits, _) => bits / 8,
            // Bare `i64` -- see `Ty::Tick`'s doc comment.
            Ty::Tick | Ty::Duration | Ty::Instant => 8,
            // Same RC'd `i8*` object-pointer bucket as `Ty::List` -- see
            // `Ty::Bytes`'s doc comment.
            Ty::Bytes => 8,
            // Bare `i64` -- see `Ty::Symbol`'s doc comment.
            Ty::Symbol => 8,
            // `i{N}` -- same alignment table as the sized-int arms above,
            // and `Ty::Fixed` just above.
            Ty::BitField(n) => n / 8,
            // Bare `i64` -- see `Ty::Flags`'s doc comment.
            Ty::Flags(_) => 8,
        }
    }

    /// Byte size of a type -- used both by `emit_reflect_metadata` (which
    /// needs a real, alignment-correct *compile-time* offset for its
    /// baked-in metadata string, so there's no way around modeling LLVM's
    /// struct layout algorithm here) and as a fallback estimate elsewhere.
    /// Any call site where getting this wrong would mean memory corruption
    /// rather than just cosmetically-wrong metadata (arena/list buffer
    /// sizing, the frame bump allocator) instead asks LLVM itself for the
    /// real size at codegen time via `emit_sizeof_llvm_ty`'s
    /// `getelementptr`-on-`null`-plus-`ptrtoint` trick, rather than trusting
    /// this Rust-side model to have anticipated every nested-type shape.
    ///
    /// Correctly pads each field to its own alignment and the whole struct's
    /// final size up to its widest field's alignment (matching real LLVM
    /// struct layout) -- previously this naively summed each field's size
    /// with no padding at all, silently *undersizing* any struct mixing a
    /// sub-8-byte field (`bool`/`i32`/`float`) with an 8-or-16-byte-aligned
    /// one (`str`/`List<T>`/a named struct/`ptr`/a vector), corrupting
    /// reflection metadata offsets for every field after the first such
    /// mismatch.
    /// The padded size (bytes) of a struct-like sequence of fields laid out
    /// in order, matching real LLVM struct layout (each field padded to its
    /// own alignment, the whole thing padded up to its widest field's
    /// alignment). Shared by `type_size`'s `Ty::Named` case and by
    /// `enum_payload_words` -- a payload enum variant's fields bitcast to
    /// exactly this same `{ f1, f2, ... }` struct shape (see
    /// `enum_variant_payload_llvm_ty`), so it must be sized identically or
    /// the shared `[W x i64]` payload buffer silently undersizes any variant
    /// whose fields need inter-field alignment padding.
    fn padded_struct_size(&self, fields: &[Ty]) -> u32 {
        let mut offset: u32 = 0;
        let mut max_align: u32 = 1;
        for f in fields {
            let align = self.type_align(f);
            max_align = max_align.max(align);
            offset = offset.div_ceil(align) * align;
            offset += self.type_size(f);
        }
        offset.div_ceil(max_align) * max_align
    }

    fn type_size(&self, ty: &Ty) -> u32 {
        match ty {
            Ty::Int | Ty::Float => 4,
            Ty::I8 | Ty::U8 => 1,
            Ty::I16 | Ty::U16 => 2,
            Ty::U32 | Ty::Char => 4,
            Ty::I64 | Ty::U64 | Ty::F64 => 8,
            Ty::Bool => 1,
            Ty::Str => 8,
            // `{ i32, i64 }`: the `i32` index field pads up to the trailing
            // `i64` generation field's 8-byte alignment (4 bytes of padding),
            // then 8 bytes for the generation field itself -- 16 total.
            Ty::GenRef(_) | Ty::Handle(_) => 16,
            Ty::Vec2 => 8,
            // `<3 x float>`/`<4 x float>` both occupy 16 bytes of struct
            // layout space on this target (see `type_align`'s doc comment).
            Ty::Vec3 => 16,
            Ty::Vec4 => 16,
            Ty::Mat4 => 64,
            Ty::Named(n) => match self.struct_field_types.get(n) {
                Some(fields) => self.padded_struct_size(fields),
                None => 8,
            },
            // Same struct-layout algorithm as `Ty::Named` above, just with
            // the element types already in hand instead of a
            // `struct_field_types` lookup.
            Ty::Tuple(elems) => self.padded_struct_size(elems),
            // `N` copies of the element's own (already alignment-padded)
            // size, tightly packed -- LLVM arrays have no inter-element
            // padding beyond each element's own natural size.
            Ty::Array(elem, count) => self.type_size(elem) * *count as u32,
            // `{ [N x T], i64, i64 }`: the inline `[N x T]` array (padded up
            // to 8-byte alignment for the `i64` head/len fields that follow
            // it, mirroring `padded_struct_size`'s general algorithm), plus
            // those two `i64` fields (8 bytes each, already 8-aligned), the
            // whole thing padded up to its own overall alignment.
            Ty::Ring(elem, count) => {
                let arr_size = self.type_size(elem) * *count as u32;
                let align = self.type_align(ty);
                let after_arr = arr_size.div_ceil(8) * 8;
                (after_arr + 16).div_ceil(align) * align
            }
            // A reference-counted object pointer, same as `Ty::Str` -- the
            // `{ T*, i64, i64 }` payload lives on the heap, not inline (see
            // `crate::codegen::list`).
            Ty::List(_) => 8,
            // Same reasoning as `Ty::List` above: the `{ K*, V*, i64, i64 }`
            // (`Map`) / `{ T*, i64, i64 }` (`Set`) payload lives on the heap,
            // this is just the object pointer's own size.
            Ty::Map(..) | Ty::Set(_) => 8,
            // Same reasoning as `Ty::List`/`Ty::Map` above -- `Table<T>`'s
            // `{ i64, i64, F0*, F1*, ... }` payload lives on the heap too;
            // this is just the object pointer's own size.
            Ty::Table(_) => 8,
            // A fieldless enum is a bare `i32` discriminant. A payload
            // enum is `{ i32 tag, [W x i64] payload }`; the `[W x i64]`
            // array forces 8-byte alignment, so the tag field is padded out
            // to 8 bytes before it (matching the LLVM struct's actual
            // layout), giving `8 + 8*W` total.
            Ty::Enum(n) => {
                let words = self.enum_payload_words(n);
                if words > 0 { 8 + words * 8 } else { 4 }
            }
            // `{ i8*, i8* }`: two pointers, 8 bytes each on this compiler's
            // sole `x86_64-w64-windows-gnu` target.
            Ty::Closure(..) => 16,
            Ty::Ptr => 8,
            // Same LLVM integer type as `T` -- see `Ty::Wrapping`'s doc comment.
            Ty::Wrapping(inner) => self.type_size(inner),
            Ty::Fixed(bits, _) => bits / 8,
            // Bare `i64` -- see `Ty::Tick`'s doc comment.
            Ty::Tick | Ty::Duration | Ty::Instant => 8,
            // A reference-counted `i8*` object pointer, same as `Ty::List`
            // -- see `Ty::Bytes`'s doc comment.
            Ty::Bytes => 8,
            // Bare `i64` -- see `Ty::Symbol`'s doc comment.
            Ty::Symbol => 8,
            // `i{N}` -- same size table as the sized-int arms above, and
            // `Ty::Fixed` just above.
            Ty::BitField(n) => n / 8,
            // Bare `i64` -- see `Ty::Flags`'s doc comment.
            Ty::Flags(_) => 8,
        }
    }

    /// The real byte size of `llvm_ty` (an already-formatted LLVM type
    /// string, e.g. `"%Player"` or `"<3 x float>"`), computed by LLVM's own
    /// layout rules at codegen time via the standard `getelementptr`-on-a-
    /// `null`-pointer-plus-`ptrtoint` idiom, rather than a Rust-side model
    /// that would need to keep re-deriving LLVM's ABI alignment/padding
    /// rules by hand (see `type_size`'s doc comment on why that's fragile).
    /// Used at every allocation site where an undersized buffer would be a
    /// real memory-safety bug (arena spawn, `List<T>` malloc/`memcpy`
    /// sizing, the frame bump allocator) rather than just cosmetically-wrong
    /// metadata.
    pub(super) fn emit_sizeof_llvm_ty(&mut self, llvm_ty: &str) -> String {
        let gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr {}, {}* null, i32 1", gep, llvm_ty, llvm_ty));
        let sz = self.tmp_name();
        self.line(&format!("  {} = ptrtoint {}* {} to i64", sz, llvm_ty, gep));
        sz
    }

    fn llvm_ty(&self, ty: &Ty) -> String {
        match ty {
            Ty::Int => "i32".into(),
            Ty::Float => "float".into(),
            Ty::I8 | Ty::U8 => "i8".into(),
            Ty::I16 | Ty::U16 => "i16".into(),
            Ty::U32 => "i32".into(),
            Ty::I64 | Ty::U64 => "i64".into(),
            Ty::F64 => "double".into(),
            // A bare 32-bit codepoint -- see `Ty::Char`'s doc comment.
            Ty::Char => "i32".into(),
            Ty::Str => "i8*".into(),
            Ty::Bool => "i1".into(),
            Ty::Vec2 => "<2 x float>".into(),
            Ty::Vec3 => "<3 x float>".into(),
            Ty::Vec4 => "<4 x float>".into(),
            Ty::Mat4 => "[4 x <4 x float>]".into(),
            Ty::Named(n) => format!("%{}", n),
            // `Handle<T>` reuses the exact same `%GenRef` layout as
            // `Ty::GenRef` -- see `Ty::Handle`'s doc comment.
            Ty::GenRef(_) | Ty::Handle(_) => "%GenRef".into(),
            // A reference-counted, copy-on-write object pointer -- same
            // shape as `Ty::Str`, no extra boxing beyond the one pointer.
            // The payload struct `{ T*, i64, i64 }` it points past a
            // `star_rc_alloc` header lives at `Codegen::list_payload_llvm_ty`
            // (see `crate::codegen::list`).
            Ty::List(_) => "i8*".into(),
            // Same RC'd opaque-object-pointer scheme as `List<T>` -- see
            // `crate::codegen::map`/`crate::codegen::set` for the payload
            // shape each points past its `star_rc_alloc` header.
            Ty::Map(..) => "i8*".into(),
            Ty::Set(_) => "i8*".into(),
            // Same RC'd opaque-object-pointer scheme as `List<T>`/`Map<K,V>`/
            // `Set<T>` -- see `crate::codegen::table` for the payload shape
            // (`{ i64 len, i64 cap, F0*, F1*, ... }`, one column per field of
            // the struct `T`) it points past its `star_rc_alloc` header.
            Ty::Table(_) => "i8*".into(),
            // An anonymous LLVM literal struct type -- no `%name`
            // declaration needed (unlike a nominal `struct`), since a tuple
            // is never referred to by name at the source level; LLVM
            // supports `getelementptr`/`extractvalue`/`load`/`store` against
            // a literal struct type exactly like a named one.
            Ty::Tuple(elems) => format!("{{ {} }}", elems.iter().map(|e| self.llvm_ty(e)).collect::<Vec<_>>().join(", ")),
            Ty::Array(elem, count) => format!("[{} x {}]", count, self.llvm_ty(elem)),
            // `{ data: [N x T], head: i64, len: i64 }` -- an anonymous LLVM
            // literal struct, same reasoning as `Ty::Tuple` above (no `%name`
            // declaration needed). See `crate::codegen::ring`'s module doc
            // comment for the field layout and invariants.
            Ty::Ring(elem, count) => format!("{{ [{} x {}], i64, i64 }}", count, self.llvm_ty(elem)),
            // A fieldless enum has no LLVM struct declaration of its own --
            // it's just a dense discriminant, so it's represented directly
            // as `i32` (see `enum_variant_index`). A payload enum lowers to
            // its own tagged-union struct type (see `emit_enum_decl`).
            Ty::Enum(n) => if self.enum_is_payload(n) { format!("%{}", n) } else { "i32".into() },
            // A closure value is a fixed-shape "fat pointer" regardless of
            // its actual parameter/return types (those are only needed to
            // build the real function-pointer type at a call site, via
            // `closure_fn_ptr_ty` -- see `crate::codegen::closure`).
            Ty::Closure(..) => "{ i8*, i8* }".into(),
            Ty::Ptr => "i8*".into(),
            // The *exact same* LLVM integer type as `T` -- see
            // `Ty::Wrapping`'s doc comment for why this is zero-overhead.
            Ty::Wrapping(inner) => self.llvm_ty(inner),
            Ty::Fixed(bits, _) => format!("i{}", bits),
            // A bare `i64` -- see `Ty::Tick`'s doc comment.
            Ty::Tick | Ty::Duration | Ty::Instant => "i64".into(),
            // The exact same RC'd object-pointer scheme as `Ty::List` -- see
            // `Ty::Bytes`'s doc comment.
            Ty::Bytes => "i8*".into(),
            // A bare `i64` id -- see `Ty::Symbol`'s doc comment.
            Ty::Symbol => "i64".into(),
            // A bare `i{N}` -- see `Ty::BitField`'s doc comment.
            Ty::BitField(n) => format!("i{}", n),
            // A bare `i64` bitmask -- see `Ty::Flags`'s doc comment.
            Ty::Flags(_) => "i64".into(),
        }
    }

    /// A valid-LLVM-identifier-fragment encoding of a type, used to key
    /// per-element-type generated helpers (currently just
    /// `Codegen::list_release_thunk_operand`) so two `List<T>` instantiations
    /// with the same `T` share one generated function instead of each
    /// emitting a duplicate `define`.
    pub(super) fn mangle_ty(&self, ty: &Ty) -> String {
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
            Ty::Vec2 => "vec2".into(),
            Ty::Vec3 => "vec3".into(),
            Ty::Vec4 => "vec4".into(),
            Ty::Mat4 => "mat4".into(),
            Ty::Named(n) => format!("s_{}", n),
            Ty::GenRef(inner) => format!("genref_{}", self.mangle_ty(inner)),
            Ty::Handle(inner) => format!("handle_{}", self.mangle_ty(inner)),
            Ty::List(inner) => format!("list_{}", self.mangle_ty(inner)),
            // Length-prefix the key segment so the K/V boundary is
            // unambiguous even when a struct name contains the `_`
            // separator itself (`Ty::Named` mangles as `s_<name>`, and Star
            // identifiers may contain `_` freely) -- otherwise, e.g.
            // `Map<a_s_b, c>` and `Map<a, b_s_c>` both mangle to the plain
            // join `map_s_a_s_b_s_c`, so one's cached release-thunk/eq-fn
            // would be silently reused for the other's, generated-for-a-
            // different-layout function. A plain single-argument wrapper
            // (`List`/`Set`/`GenRef`) has no such boundary to confuse -- the
            // entire remainder of the string is unambiguously the one inner
            // type's mangled form, so only the two-argument `Map` needs this.
            Ty::Map(k, v) => {
                let km = self.mangle_ty(k);
                format!("map_{}_{}{}", km.len(), km, self.mangle_ty(v))
            }
            Ty::Set(inner) => format!("set_{}", self.mangle_ty(inner)),
            // `T` is always `Ty::Named`, which mangles with no ambiguous
            // boundary of its own -- same reasoning as `List`/`Set` above.
            Ty::Table(inner) => format!("table_{}", self.mangle_ty(inner)),
            // Same length-prefixing reasoning as `Ty::Map` just above --
            // arity plus a length prefix on every element makes the whole
            // string unambiguous regardless of what any element's own
            // mangled form contains.
            Ty::Tuple(elems) => {
                let mut s = format!("tuple{}", elems.len());
                for e in elems {
                    let m = self.mangle_ty(e);
                    s.push_str(&format!("_{}_{}", m.len(), m));
                }
                s
            }
            // No ambiguous boundary to confuse (a single wrapped type plus
            // one integer count), same reasoning as `List`/`Set` above.
            Ty::Array(elem, count) => format!("arr{}_{}", count, self.mangle_ty(elem)),
            // Same reasoning as `Array` just above.
            Ty::Ring(elem, count) => format!("ring{}_{}", count, self.mangle_ty(elem)),
            Ty::Enum(n) => format!("e_{}", n),
            Ty::Closure(..) => "closure".into(),
            Ty::Ptr => "ptr".into(),
            Ty::Wrapping(inner) => format!("wrap_{}", self.mangle_ty(inner)),
            Ty::Fixed(bits, frac) => format!("fixed{}_{}", bits, frac),
            Ty::Tick => "tick".into(),
            Ty::Duration => "duration".into(),
            Ty::Instant => "instant".into(),
            // `Bytes`'s own generated helpers (`push`/`pop`/`len`'s release
            // thunk) are always reached by calling `crate::codegen::list`'s
            // functions with `elem_ty = Ty::U8` directly -- see `Ty::Bytes`'s
            // doc comment -- so this arm (like `Tick`/`Duration`/`Instant`
            // above) is never actually reached today; it exists for match
            // exhaustiveness.
            Ty::Bytes => "bytes".into(),
            Ty::Symbol => "symbol".into(),
            Ty::BitField(n) => format!("bitfield{}", n),
            Ty::Flags(inner) => format!("flags_{}", self.mangle_ty(inner)),
        }
    }

    /// Resolve `enum_name::variant` to its dense declaration-order
    /// discriminant. The checker has already validated the name/variant
    /// pair exists (see `Checker::check_enum_variant_name`); a lookup miss
    /// here means an internal inconsistency, not user error.
    fn enum_variant_index(&mut self, enum_name: &str, variant: &str) -> u32 {
        match self.enum_variants.get(enum_name).and_then(|vs| vs.iter().position(|v| v == variant)) {
            Some(i) => i as u32,
            None => {
                self.err(&format!("unknown enum variant `{}::{}`", enum_name, variant), Span::dummy());
                0
            }
        }
    }

    /// True if any variant of `enum_name` carries payload fields -- such an
    /// enum lowers to a tagged-union struct rather than a bare `i32`.
    fn enum_is_payload(&self, enum_name: &str) -> bool {
        self.enum_variant_fields.get(enum_name).map(|vs| vs.iter().any(|f| !f.is_empty())).unwrap_or(false)
    }

    /// The field types (in declaration order) of one variant of an enum, or
    /// an empty list if the enum/variant/index is unknown (an internal
    /// inconsistency past the checker, not user error).
    fn enum_variant_field_types(&self, enum_name: &str, variant_idx: u32) -> Vec<Ty> {
        self.enum_variant_fields
            .get(enum_name)
            .and_then(|vs| vs.get(variant_idx as usize))
            .cloned()
            .unwrap_or_default()
    }

    /// Number of `i64` words needed to hold the largest variant's payload
    /// fields for `enum_name`, `0` if the enum is fieldless. Every variant
    /// shares this one word count so the enum's tagged-union struct has a
    /// single fixed layout regardless of which variant is active.
    fn enum_payload_words(&self, enum_name: &str) -> u32 {
        let max_bytes: u64 = self
            .enum_variant_fields
            .get(enum_name)
            .map(|vs| vs.iter().map(|fields| self.padded_struct_size(fields) as u64).max().unwrap_or(0))
            .unwrap_or(0);
        ((max_bytes + 7) / 8) as u32
    }

    /// The LLVM struct type text for one variant's payload fields (e.g.
    /// `{ i32, float }`), used to bitcast into/out of the enum's shared
    /// `[W x i64]` payload buffer when constructing or matching that variant.
    fn enum_variant_payload_llvm_ty(&self, enum_name: &str, variant_idx: u32) -> String {
        let parts: Vec<String> = self.enum_variant_field_types(enum_name, variant_idx).iter().map(|t| self.llvm_ty(t)).collect();
        format!("{{ {} }}", parts.join(", "))
    }

    /// A constant zero value of the given type, for zero-initializing struct
    /// fields the constructor call site didn't supply an argument for.
    fn zero_value(&self, ty: &Ty) -> String {
        match ty {
            Ty::Int => "0".into(),
            Ty::Float => "0.0".into(),
            Ty::I8 | Ty::U8 | Ty::I16 | Ty::U16 | Ty::U32 | Ty::I64 | Ty::U64 | Ty::Char => "0".into(),
            Ty::F64 => "0.0".into(),
            // Bare `i64` zero -- see `Ty::Tick`'s doc comment.
            Ty::Tick | Ty::Duration | Ty::Instant => "0".into(),
            Ty::Bool => "false".into(),
            Ty::Str => "null".into(),
            Ty::Ptr => "null".into(),
            Ty::List(_) => "null".into(),
            Ty::Map(..) => "null".into(),
            Ty::Set(_) => "null".into(),
            Ty::Table(_) => "null".into(),
            Ty::Enum(n) if !self.enum_is_payload(n) => "0".into(),
            Ty::Vec2 | Ty::Vec3 | Ty::Vec4 | Ty::Mat4 | Ty::Named(_) | Ty::GenRef(_) | Ty::Handle(_) | Ty::Enum(_) | Ty::Closure(..) | Ty::Tuple(_)
            // `zeroinitializer` gives `{ data: [N x T] zeroinitializer, head:
            // 0, len: 0 }` -- exactly an empty ring, per `crate::codegen::ring`'s
            // invariant that every slot outside the (here, empty) live window
            // is the element type's zero value.
            | Ty::Array(..) | Ty::Ring(..) => "zeroinitializer".into(),
            Ty::Wrapping(inner) => self.zero_value(inner),
            Ty::Fixed(..) => "0".into(),
            // Same "never-allocated" null object pointer as `Ty::List` --
            // see `Ty::Bytes`'s doc comment.
            Ty::Bytes => "null".into(),
            // Bare `i64` zero -- see `Ty::Symbol`'s doc comment.
            Ty::Symbol => "0".into(),
            // Bare `i{N}`/`i64` zero -- see `Ty::BitField`/`Ty::Flags`'s doc
            // comments (an all-clear register / an empty flag set).
            Ty::BitField(..) => "0".into(),
            Ty::Flags(_) => "0".into(),
        }
    }

    /// Like `zero_value`, but for `Ty::Str` specifically emits a real,
    /// freshly-allocated, owned empty string (`star_rc_alloc` + a lone NUL
    /// byte -- the same recipe `emit_symbol_name`'s out-of-range branch and
    /// `emit_env_get`'s missing-variable branch already use) instead of
    /// `zero_value`'s bare `null` `i8*`.
    ///
    /// `zero_value(&Ty::Str)` is `"null"` -- a legitimate "nothing allocated
    /// yet" sentinel for a *fresh binding never assigned*, but every
    /// out-of-bounds-read/pop-on-empty fallback in `List<T>`/`Ring<T,N>`/
    /// `[T; N]`/`Table<T>` reuses that same `zero_value` call to hand the
    /// *caller* a value indistinguishable from a real element -- exactly the
    /// same root cause `emit_symbol_name`'s doc comment documents in detail
    /// (`src/codegen/symbol.rs`): a null `i8*` disguised as `str` segfaults
    /// the instant any string builtin (`len`, `concat`, ...) calls `strlen`
    /// on it. Confirmed via real, reproducible segfaults building and running
    /// `List<str>::pop()`/`list[oob]`/`Ring<str,N>::pop()`/`ring[oob]`/
    /// `[str; N][oob]` before this fix existed. Used by every call site that
    /// hands its "zero" result directly back to Star code as a `str` value
    /// (not by `Ring`'s own internal "zero the vacated slot" bookkeeping
    /// store, which never becomes a caller-visible value and is left as a
    /// bare `null` -- see `RingMethod::Pop`'s own comment).
    fn zero_value_rc(&mut self, ty: &Ty) -> String {
        if matches!(ty, Ty::Str) {
            let empty = self.tmp_name();
            self.line(&format!("  {} = call i8* @star_rc_alloc(i64 1, i8* null)", empty));
            self.line(&format!("  store i8 0, i8* {}", empty));
            empty
        } else {
            self.zero_value(ty)
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

    /// Emit code that yields a *pointer* to the storage of `expr`, for use as
    /// the base operand of a `getelementptr`. This differs from `emit_expr`,
    /// which for an `Ident`/`Field` of aggregate type loads and returns the
    /// value itself; GEP-ing into that loaded value would be an LLVM type
    /// mismatch (the register's type is the aggregate, not a pointer to it).
    pub(super) fn emit_place(&mut self, expr: &TypedExpr) -> String {
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
            TypedExpr::TupleIndex { base, index, .. } => {
                let base_ptr = self.emit_place(base);
                let gep = self.tmp_name();
                let bty = self.llvm_ty(&self.expr_ty(base));
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, bty, bty, base_ptr, index));
                gep
            }
            // `list[idx]`/`gen_ref[idx]` used as the *base* of a further
            // access (`list[i].field = v`, `list[i].push(x)`,
            // `gen_ref[0].hp -= 10`, `m[i][j] = v`, ...): resolve to a real
            // pointer into the underlying buffer/arena slot rather than
            // falling into the generic fallback below, which would spill a
            // disconnected *copy* of the read value and silently discard
            // any write through it. See `emit_list_index_place`/
            // `emit_genref_index_place`'s own doc comments for the bug this
            // closes.
            TypedExpr::ListIndex { base, index, ty, .. } => self.emit_list_index_place(base, index, ty),
            TypedExpr::ArrayIndex { base, index, ty, .. } => {
                let Ty::Array(_, count) = self.expr_ty(base) else { unreachable!("ArrayIndex base must be Ty::Array") };
                self.emit_array_index_place(base, index, ty, count)
            }
            TypedExpr::RingIndex { base, index, ty, .. } => {
                let Ty::Ring(_, count) = self.expr_ty(base) else { unreachable!("RingIndex base must be Ty::Ring") };
                self.emit_ring_index_place(base, index, ty, count)
            }
            // `TypedExpr::TableIndex` is deliberately *not* matched here: a
            // `Table<T>` element has no single contiguous storage location
            // to hand out a real pointer into (its fields live in separate
            // columns -- see `Ty::Table`'s doc comment), so it falls through
            // to the generic fallback below, which materializes it (via
            // `emit_expr`, reassembling every column) into a fresh,
            // disconnected alloca. Correct for a *read* through it
            // (`table[i].field`, an argument, ...); a *write* through that
            // pointer (`table[i].field = v`, or a mutating collection method
            // reached the same way) would silently target the disconnected
            // copy instead of the real column, so `Checker::
            // writes_through_table_index` rejects those at type-check time
            // instead -- this fallback never actually sees one for a write
            // (see `store_table_index` for the one write path -- `table[i] =
            // v` -- that *is* supported).
            TypedExpr::GenRefIndex { base, ty, span, .. } => self.emit_genref_index_place(base, ty, *span),
            // Any other expression (e.g. chaining a field access directly
            // onto a struct returned *by value*) has no existing storage to
            // address -- spill it into a fresh alloca so the `Field` arm
            // above has a pointer to GEP into.
            _ => {
                let val = self.emit_expr(expr);
                let ty = self.expr_ty(expr);
                let ty_str = self.llvm_ty(&ty);
                let bare = self.untag(&val, &ty);
                let ptr = self.tmp_name();
                self.line(&format!("  {} = alloca {}", ptr, ty_str));
                self.line(&format!("  store {} {}, {}* {}", ty_str, bare, ty_str, ptr));
                // This spilled pointer is the *only* reference to whatever
                // `expr` evaluated to (a `List`/`Map`/`Set`/`Table` object
                // pointer, or a struct/tuple/array/ring value that may itself
                // carry RC-bearing fields at any nesting depth) -- track it so
                // it's released once the current scope ends, exactly like a
                // real `let`-bound local (`Codegen::track_owned` already
                // no-ops for a non-RC-bearing type, so this is always safe to
                // call unconditionally). Paired with `Field`/`TupleIndex`/
                // `ArrayIndex`/`RingIndex`'s read arms now retaining
                // unconditionally on every read (see those arms' doc
                // comments) rather than skipping the retain for a spilled
                // base: the two together reproduce plain `Ident`-field-read
                // semantics for a temporary exactly -- the one field actually
                // extracted ends up retained-then-released-back to a single
                // net owning reference for its new owner, while every
                // *un*-extracted sibling field gets properly released here
                // instead of silently leaking. Previously this was only
                // tracked for `List`/`Map`/`Set`/`Table` (whose elements are
                // always retained on read regardless, from their own separate
                // heap buffer, so only the container pointer itself needed
                // tracking) paired with a no-retain convention for every other
                // type -- correct only when the spilled value carried at most
                // one RC-bearing leaf. A struct/tuple returned by a bare
                // `Call`/`If`/`Match` (no intervening `let`) with *two or
                // more* RC-bearing fields leaked every field except the one
                // actually accessed, confirmed via real unbounded working-set
                // growth (~3MB flat control vs. ~800MB in under 4 seconds of
                // 30,000,000 iterations of `make().a` where `make()` returns
                // a two-`str`-field struct and only field `a` is read) --
                // `Table<T>`'s own `TableIndex` (which also falls into this
                // same generic fallback, see its own doc comment above) had
                // the identical latent gap for any `T` with 2+ RC fields.
                self.track_owned(&ptr, &ty);
                ptr
            }
        }
    }

    /// Read-only counterpart to `emit_place`: resolves a place pointer
    /// without ever routing through `emit_place`'s `ListIndex` arm, which is
    /// a write path that unconditionally CoW-clones the base list via
    /// `emit_list_ensure_unique` -- correct for a write (`list[i].push(x)`,
    /// `list[i].field = v`), but a bug for a pure read: `list_fields`'s own
    /// nested-`ListIndex`-base fast path and `emit_list_index_read_place`
    /// exist for exactly this reason (see their doc comments), but
    /// `map_fields`/`set_fields` (`crate::codegen::map`/`crate::codegen::set`)
    /// and the `TypedExpr::Field` read arm (`crate::codegen::expr`) each need
    /// the same guard for a receiver reached through a list index, at
    /// arbitrary `Field` nesting depth (`points[0].my_map.get(k)`,
    /// `a[i].b.c[j].d`, ...). Delegates to `emit_list_index_read_place` for a
    /// `ListIndex` base (retain-free, no clone) and recurses through `Field`
    /// so a chain bottoms out through the read path at every level; anything
    /// else (`Ident`, `SelfExpr`, `GenRefIndex`, ...) has no CoW-on-read
    /// hazard, so it's identical to `emit_place`.
    pub(super) fn emit_read_place(&mut self, expr: &TypedExpr) -> String {
        match expr {
            TypedExpr::Field { base, field, .. } => {
                let base_ptr = self.emit_read_place(base);
                let gep = self.tmp_name();
                let bty = self.llvm_ty(&self.expr_ty(base));
                let idx = self.field_index(&self.expr_ty(base), field);
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, bty, bty, base_ptr, idx));
                gep
            }
            TypedExpr::TupleIndex { base, index, .. } => {
                let base_ptr = self.emit_read_place(base);
                let gep = self.tmp_name();
                let bty = self.llvm_ty(&self.expr_ty(base));
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, bty, bty, base_ptr, index));
                gep
            }
            TypedExpr::ListIndex { base, index, ty, .. } => self.emit_list_index_read_place(base, index, ty),
            TypedExpr::ArrayIndex { base, index, ty, .. } => {
                let Ty::Array(_, count) = self.expr_ty(base) else { unreachable!("ArrayIndex base must be Ty::Array") };
                self.emit_array_index_read_place(base, index, ty, count)
            }
            TypedExpr::RingIndex { base, index, ty, .. } => {
                let Ty::Ring(_, count) = self.expr_ty(base) else { unreachable!("RingIndex base must be Ty::Ring") };
                self.emit_ring_index_read_place(base, index, ty, count)
            }
            _ => self.emit_place(expr),
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

    fn line(&mut self, s: &str) { writeln!(self.ir, "{}", s).unwrap(); }
    fn write(&mut self, s: &str) { write!(self.ir, "{}", s).unwrap(); }
    fn err(&mut self, msg: &str, span: Span) { self.errors.push(Diagnostic::error(msg, span)); }

    /// Rewrites one just-generated function's complete IR text (from
    /// `define ... {` through its closing `}`) so every `alloca` instruction
    /// is hoisted to immediately follow its `entry:` label, regardless of
    /// which block originally contained it. Every `alloca` this codegen
    /// emits is fixed-size (a concrete LLVM type, never a runtime element
    /// count -- confirmed there is no `alloca TYPE, iN %count` shape
    /// anywhere in this codebase), so moving its *definition* earlier is
    /// always valid: `entry:` dominates every other block, and an `alloca`
    /// reads nothing but its own static type, never a previously computed
    /// SSA value that could still be out of scope at the new position.
    ///
    /// This matters because every other call site in this codegen emits a
    /// local's `alloca` inline, in whatever block it's first needed in --
    /// not hoisted to the function's own entry block the way a typical C
    /// frontend (e.g. Clang) always does. An `alloca` inside a loop body is
    /// *not* free of runtime cost the way a fixed-size stack slot declared
    /// once at entry is: unless the backend's own optimizer proves it's
    /// safe to promote/reuse (an `-O1`+ pass -- never runs at `-O0`), each
    /// pass through that loop iteration's block consumes *more* stack space,
    /// so a long-running loop containing so much as one `let`/temporary
    /// eventually overflows the stack. Confirmed via a real
    /// `STATUS_STACK_OVERFLOW` after ~500,000 iterations of a trivial `let
    /// s: str = concat("a", "b")` inside a `while` loop compiled at `-O0`
    /// (this compiler's own test suite always builds at `-O0` -- see
    /// `tests/frontend.rs`'s `compile_and_run`) -- reproducible on a clean
    /// checkout with none of this round's other fixes applied, so this is a
    /// pre-existing bug, not something introduced by them. Discovered while
    /// writing a stress-test regression for the `TypedStmt::Expr` RC-release
    /// fix (see `emit_stmt`), which happened to be the first codegen path
    /// exercised at a high enough iteration count to trigger it.
    fn hoist_allocas_to_entry(func_ir: &str) -> String {
        let mut entry_idx = None;
        let mut alloca_lines: Vec<&str> = Vec::new();
        let mut rest: Vec<&str> = Vec::new();
        for line in func_ir.lines() {
            let trimmed = line.trim_start();
            if entry_idx.is_none() && line == "entry:" {
                entry_idx = Some(rest.len());
                rest.push(line);
                continue;
            }
            if entry_idx.is_some() && trimmed.starts_with('%') && trimmed.contains("= alloca ") {
                alloca_lines.push(line);
                continue;
            }
            rest.push(line);
        }
        let Some(idx) = entry_idx else {
            // No `entry:` label found -- not a real function body (shouldn't
            // happen for anything this is called on); return unchanged
            // rather than acting on a wrong assumption.
            return func_ir.to_string();
        };
        let mut out = String::with_capacity(func_ir.len());
        for (i, line) in rest.iter().enumerate() {
            out.push_str(line);
            out.push('\n');
            if i == idx {
                for a in &alloca_lines {
                    out.push_str(a);
                    out.push('\n');
                }
            }
        }
        out
    }

    /// Produce a unique, readable basic-block label for control flow.
    fn block_label(&mut self, prefix: &str) -> String {
        let id = self.block_id;
        self.block_id += 1;
        format!("{}_{}", prefix, id)
    }

    /// Open a new basic block: emit its label line and record it as
    /// `current_label` (see that field's doc comment). This is the sole
    /// place a block label is ever written into `self.ir` -- every other
    /// call site goes through this instead of writing `"{}:"` directly, so
    /// `current_label` can never drift out of sync with what block is
    /// actually being appended to.
    fn open_block(&mut self, label: &str) {
        self.line(&format!("{}:", label));
        self.current_label = label.to_string();
    }

    /// Extract just the register name from an expression emission result such
    /// as `i1 %r` or `i32 %r`, discarding the leading type tag.
    fn reg_of(&self, s: &str) -> String {
        s.split_whitespace().next_back().unwrap_or(s).to_string()
    }

    fn expr_ty(&self, e: &TypedExpr) -> Ty {
        match e {
            TypedExpr::Int(_, ty, _) | TypedExpr::Float(_, ty, _)
            | TypedExpr::Str(_, ty, _) | TypedExpr::Bool(_, ty, _)
            | TypedExpr::Char(_, ty, _) | TypedExpr::Cast { ty, .. }
            | TypedExpr::Field { ty, .. } | TypedExpr::Call { ty, .. }
            | TypedExpr::Binary { ty, .. } | TypedExpr::Unary { ty, .. }
            | TypedExpr::Match { ty, .. } | TypedExpr::StructLit { ty, .. }
            | TypedExpr::FStr(_, ty, _) | TypedExpr::GenRefIndex { ty, .. } | TypedExpr::EnumVariant { ty, .. }
            | TypedExpr::Closure { ty, .. } | TypedExpr::ListIndex { ty, .. } | TypedExpr::ListMethod { ty, .. }
            | TypedExpr::StrIndex { ty, .. } | TypedExpr::Error(ty) => ty.clone(),
            TypedExpr::Ident { ty, .. } => ty.clone(),
            TypedExpr::GenRefCreate { inner_ty, is_handle, .. } => {
                if *is_handle { Ty::Handle(Box::new(inner_ty.clone())) } else { Ty::GenRef(Box::new(inner_ty.clone())) }
            }
            TypedExpr::ListNew { elem_ty, .. } => Ty::List(Box::new(elem_ty.clone())),
            TypedExpr::ListLit { elem_ty, .. } => Ty::List(Box::new(elem_ty.clone())),
            TypedExpr::MapNew { key_ty, val_ty, .. } => Ty::Map(Box::new(key_ty.clone()), Box::new(val_ty.clone())),
            TypedExpr::SetNew { elem_ty, .. } => Ty::Set(Box::new(elem_ty.clone())),
            TypedExpr::MapMethod { ty, .. } => ty.clone(),
            TypedExpr::SetMethod { ty, .. } => ty.clone(),
            TypedExpr::SelfExpr(ty, _) => ty.clone(),
            TypedExpr::If { ty, .. } => ty.clone(),
            TypedExpr::TupleLit { ty, .. } => ty.clone(),
            TypedExpr::TupleIndex { ty, .. } => ty.clone(),
            TypedExpr::ArrayRepeat { count, elem_ty, .. } => Ty::Array(Box::new(elem_ty.clone()), *count),
            TypedExpr::ArrayIndex { ty, .. } => ty.clone(),
            TypedExpr::ArrayLen { .. } => Ty::Int,
            TypedExpr::RingNew { elem_ty, count, .. } => Ty::Ring(Box::new(elem_ty.clone()), *count),
            TypedExpr::RingMethod { ty, .. } => ty.clone(),
            TypedExpr::RingIndex { ty, .. } => ty.clone(),
            TypedExpr::TableNew { elem_ty, .. } => Ty::Table(Box::new(elem_ty.clone())),
            TypedExpr::TableMethod { ty, .. } => ty.clone(),
            TypedExpr::TableIndex { ty, .. } => ty.clone(),
            TypedExpr::WrappingNew { inner_ty, .. } => Ty::Wrapping(Box::new(inner_ty.clone())),
            TypedExpr::FixedNew { bits, frac, .. } => Ty::Fixed(*bits, *frac),
            TypedExpr::BitFieldNew { bits, .. } => Ty::BitField(*bits),
            TypedExpr::FlagsNew { enum_name, .. } => Ty::Flags(Box::new(Ty::Enum(enum_name.clone()))),
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

    /// Strip a value's leading `<llvm-type> ` tag, given its resolved `Ty`.
    fn untag(&self, s: &str, ty: &Ty) -> String {
        let t = self.llvm_ty(ty);
        s.strip_prefix(&format!("{} ", t)).unwrap_or(s).to_string()
    }

    /// Strip a bare type tag and, if the operand isn't already `float`,
    /// convert it to one so it can be used in `float` arithmetic (every
    /// math builtin backing this -- `sqrt`/`floor`/`ceil`/`pow` -- always
    /// computes in `f32`, regardless of its argument's width). Handles
    /// every numeric type (`Ty::is_numeric()`), not just the original
    /// `Ty::Int`: an `f64` narrows via `fptrunc`, a signed sized int
    /// widens/narrows its *bit width* via `sitofp`, an unsigned one via
    /// `uitofp`. Returns a bare (untagged) `float` register.
    fn promote_to_float(&mut self, val: &str, ty: &Ty) -> String {
        let bare = self.untag(val, ty);
        match ty {
            Ty::Int => {
                let reg = self.tmp_name();
                self.line(&format!("  {} = sitofp i32 {} to float", reg, bare));
                reg
            }
            Ty::Float => bare,
            Ty::F64 => {
                let reg = self.tmp_name();
                self.line(&format!("  {} = fptrunc double {} to float", reg, bare));
                reg
            }
            _ => match ty.int_shape() {
                Some((width, signed)) => {
                    let reg = self.tmp_name();
                    let op = if signed { "sitofp" } else { "uitofp" };
                    self.line(&format!("  {} = {} i{} {} to float", reg, op, width, bare));
                    reg
                }
                None => bare,
            },
        }
    }

    /// Extract lane/field `i` from an already-loaded vector value `val` of
    /// type `ty`, returning a bare `float` register.
    fn extract_component(&mut self, val: &str, ty: &Ty, i: u32) -> String {
        let reg = self.tmp_name();
        let t = self.llvm_ty(ty);
        if ty.is_vec() {
            self.line(&format!("  {} = extractelement {} {}, i32 {}", reg, t, val, i));
        } else {
            self.line(&format!("  {} = extractvalue {} {}, {}", reg, t, val, i));
        }
        reg
    }

    /// Insert a bare `float` register into lane/field `i` of `acc` (an
    /// already-built or `undef` aggregate of type `ty`), returning the
    /// updated aggregate register.
    fn insert_component(&mut self, acc: &str, ty: &Ty, i: u32, scalar: &str) -> String {
        let reg = self.tmp_name();
        let t = self.llvm_ty(ty);
        if ty.is_vec() {
            self.line(&format!("  {} = insertelement {} {}, float {}, i32 {}", reg, t, acc, scalar, i));
        } else {
            self.line(&format!("  {} = insertvalue {} {}, float {}, {}", reg, t, acc, scalar, i));
        }
        reg
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// `Ty::Map`'s mangle arm previously joined its key/value segments with
    /// a bare `_`, ambiguous whenever a struct name itself contains `_`
    /// (`Ty::Named` mangles as `s_<name>`): `Map<a_s_b, c>` and
    /// `Map<a, b_s_c>` both mangled to the identical string
    /// `map_s_a_s_b_s_c` under the old formula. Star's surface syntax
    /// requires a struct name to start uppercase to be usable as a
    /// constructor call, so this can't be reproduced by parsing real source
    /// (see `tests/frontend.rs`'s
    /// `codegen_map_release_thunk_names_dont_collide_across_underscore_ambiguous_structs`
    /// for the parseable end-to-end version of this same fix) -- exercised
    /// directly here instead, against `Ty` values built by hand, so the
    /// exact colliding names from the bug report can be used verbatim.
    #[test]
    fn mangle_ty_map_key_value_boundary_is_unambiguous_across_underscore_names() {
        let cg = Codegen::new();
        let m1 = Ty::Map(Box::new(Ty::Named("a_s_b".into())), Box::new(Ty::Named("c".into())));
        let m2 = Ty::Map(Box::new(Ty::Named("a".into())), Box::new(Ty::Named("b_s_c".into())));
        let mangled1 = cg.mangle_ty(&m1);
        let mangled2 = cg.mangle_ty(&m2);
        assert_ne!(
            mangled1, mangled2,
            "Map<a_s_b, c> and Map<a, b_s_c> must not mangle to the same cache key: both got {:?}",
            mangled1
        );
    }
}
