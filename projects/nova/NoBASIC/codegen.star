# NoBASIC code generator core -- ported from the reference Python
# `compiler/codegen/generator.py` (`c:\Code\projects\Nova\NoBASIC\compiler\
# codegen\generator.py`, 5,323 lines -- by far the largest single file in
# the reference), todo.md P1 #1. Walks the `ast::Ast` `parser.star` built
# (already confirmed valid by `semantic.star`'s `analyze`) and emits Nova-16
# assembly text consumable by `projects/nova/assembler.star`, the same
# `CodeGenerator` -> `Codegen` rename this port's earlier phases already
# used (`SemanticAnalyzer` -> `Analyzer`, etc.).
#
# Same `impl`-block-per-file split `projects/nova/cpu.star`/`cpu_*.star`
# established for the Nova-16 CPU emulator port (see that file's own header
# comment, and `NOTES.md`'s "Codegen core" section for the writeup here):
# this file (`codegen.star`) holds the `Codegen` struct, its state, register
# allocation/liveness/spill machinery, and small helpers; `codegen_expr.star`
# holds expression codegen (literals/binary/unary/variables/function calls);
# `codegen_stmt.star` holds statement codegen (dispatch + the `generate()`
# driver). All three `impl codegen::Codegen:` the same type -- Star resolves
# methods globally across files once both are imported into one compilation
# unit (confirmed by `cpu.star`'s own precedent), so the split is purely
# organizational, not a dependency boundary.
#
# ============================================================================
# SCOPE OF THIS ROUND -- read this before assuming a missing case is a bug.
# ============================================================================
#
# `todo.md` already splits "codegen core" (P1 #1, this round) from "codegen
# optimization passes" (P1 #2: `optimizations.py`, `peephole.py`,
# `live_range_scheduler.py`) -- this port draws that line a little further
# in, at genuine correctness-vs-throughput boundaries, all confirmed by
# direct inspection of the reference before being cut, not guessed:
#
# - The six `Optional[<optimizations.py class>]` fields
#   (`graph_coloring`/`hot_spill_analyzer`/`pressure_monitor`/
#   `spill_allocator`/`expr_simplifier`/`function_inliner`) and every
#   `apply_*_optimizations` orchestration method that drives them are not
#   ported -- confirmed dead weight for a from-scratch port: every one of
#   those fields is `None` unless `optimizations.py` code sets it, and no
#   code in this file's ported scope ever does (that only happens inside the
#   deferred `apply_*` methods themselves). Running the reference with
#   `--disable-optimizations` (which this port's own verification does, see
#   `tests/codegen_dump.star`) makes `apply_pre_allocation_optimizations`/
#   `apply_post_allocation_optimizations` both no-ops via their own
#   `if not self.enable_optimizations: return` guards, so comparing against
#   that invocation is a fair, like-for-like check of exactly what this file
#   implements.
# - `expr_constant_values: Dict[str, int]` is written throughout the
#   reference (`generate_assignment`, `generate_statement`) but its *only*
#   read site is `context={"constants": self.expr_constant_values}`, passed
#   into `self.expr_simplifier.simplify_expression(...)` -- which never runs
#   this round (`expr_simplifier` is always `None`, see above). Confirmed by
#   grep across the whole file: every other reference to
#   `expr_constant_values` is a write. Not ported; has zero effect on
#   emitted assembly with optimizations disabled.
# - `variable_access_counts: Counter[str]` (hot-variable tracking) is
#   written by `collect_lifetimes_stmt`/`collect_lifetimes_expr` but only
#   ever read by `apply_hot_spill_migration`'s `HotSpillAnalyzer` (deferred).
#   Not ported for the same reason.
# - `register_pressure: Dict[int, int]` (per-point pressure, as opposed to
#   `max_register_pressure`) is populated by `calculate_register_pressure`
#   but never read back anywhere except its own debug `print` block. Only
#   `max_register_pressure` (which `assign_registers` genuinely consults) is
#   kept; `calculate_register_pressure` here computes the max directly
#   without retaining the per-point map.
# - `var_lifetime`/`statement_counter` are the reference's *own* words
#   "DEPRECATED - use live_ranges"/"DEPRECATED - use program_counter"
#   (see `generator.py`'s `__init__` comments) -- genuinely dead legacy
#   fields even in the reference. Not ported.
# - `with_temporary_register`/`temporary_registers` (the two
#   `@contextmanager` methods) and `generate_and_free_args`/`free_args` have
#   **zero real call sites** in the reference -- confirmed by grepping the
#   whole file: the only two hits for the context managers are inside their
#   own docstrings' usage examples, and `generate_and_free_args`/`free_args`
#   are never called either. Genuine dead code in the reference itself, not
#   a gap this port introduces. Not ported.
# - Debug-only output: every `if self.debug_allocation: print(...)` block
#   (register-allocator tracing) is display-only and never affects the
#   emitted assembly (`debug_allocation` defaults `False` and nothing reads
#   its own output programmatically) -- not ported, and the `debug_allocation`
#   field itself is dropped since nothing else consults it once its prints
#   are gone.
# - Struct types/instances (`struct_types`/`struct_bases`/`struct_instances`,
#   `generate_member_access`/`generate_member_store`/
#   `allocate_struct_instance`), list/matrix access+store
#   (`generate_list_access`/`generate_list_store`/`generate_matrix_access`/
#   `generate_matrix_store`), the dynamic list heap runtime
#   (`_collect_dynamic_list_descriptors`/`_emit_list_runtime_init`/
#   `_emit_list_runtime_helper`/`_get_or_create_list_descriptor`), the
#   `INPUT` statement, and all 13 graphics statements (`PxlOn`/`PxlOff`/
#   `Line`/`Circle`/`Text`/`SetLayer`/`SRol`/`SRot`/`SShft`/`SFlip`/
#   `SpriteOn`/`SpriteOff`) are **not yet ported** -- genuinely out of scope
#   for this pass, not simplifications; see `NOTES.md`'s "Codegen core"
#   section for the precise remaining-work list. `generate_statement`'s
#   dispatch match has an explicit `_ -> self.fail(...)` catch-all (not a
#   silent no-op) for every `StmtKind` variant not yet implemented, so an
#   unported statement kind fails loudly with a clear message rather than
#   emitting wrong/missing code silently.
# - Builtin function coverage: `generate_function_call` ports user-defined
#   function calls in full, plus the reference's `unary_math_ops` table (18
#   functions), `RND`/`RNDR`/`RANDOMIZE`, the string-function family
#   (`LEN`/`LENGTH`/`STRLEN`/`STRCPY`/`STRCAT`/`STRCMP`/`STRUPR`/`STRLWR`/
#   `LOWSTRING`/`UPSTRING`/`LENSTRING`/`INSTRING`/`STRREV`/`STRFIND`/
#   `STRFINDI`/`STREXT`/`STREXTI`), `MIN`/`MAX`, the extended-math family
#   (`ATAN`/`ASIN`/`ACOS`/`DEG`/`RAD`/`FLOOR`/`CEIL`/`ROUND`/`TRUNC`/`FRAC`/
#   `INTGR`/`POWR`/`LOG`/`EXP`), and `GETKEY`/`SERIN`/`SERSTAT`/`PAUSE` as
#   functions. Not yet ported: bit-manipulation (`BTST`/`BSET`/`BCLR`/
#   `BFLIP`/`CLZ`/`CTZ`/`POPCNT`), shift/rotate-as-function (`SHL`/`SHR`/
#   `SAL`/`SAR`/`ROL`/`ROR`/`RCL`/`RCR`), bitwise logic (`BAND`/`BOR`/`BXOR`/
#   `BNOT`), memory ops (`MEMREAD`/.../`MEMSWAP`), enhanced arithmetic
#   (`ADC`/`SBC`/`MULH`/`DIVH`/`SWAP`/`XCHNG`/`MOVZ`/`MOVNZ`/`LEA`), type
#   conversion (`ITOB`/`BTOI`/`ITOS`/`STOI`/`STR`), graphics-as-function
#   (`CLRDRAW`/`SETLAYER`/`PXLON`/.../`RECT`), and list/array-as-function
#   (`FILL`/`SORTA`/`SORTD`/`SEQ`/`REVERSE`/`SUM`/`MEAN`/`DIM` -- these also
#   depend on the deferred dynamic list runtime). `generate_function_call`
#   ends with an explicit `_ -> self.fail(...)` default arm, so an unported
#   builtin name also fails loudly rather than silently emitting nothing.
#
# One genuine reference **bug**, confirmed by direct inspection (not
# reproduced -- flagged loudly instead, per todo.md's "any such gap ...
# should be documented ... not silently reconciled" guidance, applied here
# the same way `semantic.star` applied it to the pending-GOTO bug): `LN` and
# `POW` are registered as valid builtin function *names* by
# `semantic.star`'s `Analyzer.register_builtins` (`reg_uncounted("LN")`/
# `reg_uncounted("POW")`, matching the reference `analyzer.py`'s own
# `is_builtin_function` membership list) -- but `generator.py`'s
# `generate_function_call` has **no `elif func_name == "LN"` or `"POW"`
# branch at all** (confirmed: grepped the whole ~1,000-line method, present
# neighbors like `LOG`/`EXP`/`POWR` all have branches, `LN`/`POW` do not).
# A NoBASIC program calling `LN(x)` or `POW(x, y)` passes semantic analysis
# cleanly, then silently falls through the reference's `elif` chain to its
# final `return target_reg` with the register's pre-existing (uninitialized)
# contents -- no error, no code emitted, a silently wrong runtime value.
# This port's `generate_function_call` reproduces the *symptom* honestly
# rather than inventing a fix the reference never had: `LN`/`POW` are
# deliberately left out of the builtin-call `match`'s named arms, so they
# fall into the same catch-all `_ -> self.fail(...)` as a genuinely unported
# builtin -- a loud compile-time failure here, which is strictly *safer*
# than the reference's silent bad-value bug, not a mismatch worth chasing
# byte-for-byte. Documented here so a future implementer of these two
# doesn't "restore" reference behavior that was never actually correct.
#
# A second genuine reference **bug**, confirmed against the live reference
# directly (not just by reading source, same standard the `NOTES.md`
# "genuine reference bug" writeups from earlier phases hold themselves to):
# `generate_expression`'s `isinstance` dispatch chain (~3251-3267 in
# `generator.py`) has cases for `LiteralExpr`/`VariableExpr`/
# `MemberAccessExpr`/`ListAccessExpr`/`MatrixAccessExpr`/`BinaryExpr`/
# `UnaryExpr`/`FunctionCallExpr` -- but **no case for `GroupingExpr`**,
# even though the parser genuinely constructs one for any parenthesized
# expression (`parser.py:774`, `return self._mark_node(GroupingExpr(expr),
# ...)`). Every parenthesized expression therefore falls through to the
# chain's final `else: self.current_output.append(f"MOV {target_reg}, 0")`
# -- silently discarding the grouped expression and using the constant `0`
# in its place. Confirmed by compiling `Disp (2+3)*4` against the live
# reference with `--disable-optimizations --disable-peephole
# --disable-live-range`: the emitted assembly is `MOV P0, 0` / `MOV R1, P0`
# / `SHL R1, 2` (`*4` strength-reduced to a left-shift-by-2) -- the `(2+3)`
# operand is entirely ignored, so the program displays `0`, not `20`. This
# is severe enough (parentheses are common, and this makes every one of
# them silently wrong) that this port does not reproduce it:
# `codegen_expr.star`'s `generate_expression` has a real
# `ast::ExprKind::Grouping(inner) -> ...` arm that recurses into `inner`
# with `target_reg` as its register preference, exactly the "pass through
# transparently" behavior parentheses are supposed to have. Flagged loudly
# here (not silently fixed) per the same `todo.md` guidance the `LN`/`POW`
# writeup above already cites.
#
# A third genuine reference **bug** -- this one predates codegen entirely
# (lives in `parser.star`/`parser.py`, both already verified byte-for-byte
# against the live reference back in todo.md P0 #2) but only became
# *observable* once codegen made it possible to actually run a compiled
# function, so it's recorded here rather than retroactively editing that
# already-frozen writeup. `parser.py`'s `function_declaration` lowercases
# both the function name and every parameter name when constructing
# `FunctionDefStmt`/`Param` (`parser.py:900,907,914`, all `.lexeme.lower()`)
# -- but `primary()`'s plain-identifier case constructing a `VariableExpr`
# does **not** lowercase (`name = self.previous().lexeme`, `parser.py:763`,
# no `.lower()`). So `Function Add(A, B = 10) ... Return A + B ... End`
# parses `params = ["a", "b"]` but the body's own `A`/`B` references stay
# `VariableExpr("A")`/`VariableExpr("B")` -- and both `generator.py`'s
# `load_variable`/`store_variable` (`if name in params: idx =
# params.index(name)`) and this port's `Codegen::function_param_index` do
# an exact-case lookup, so neither ever matches. The parameter is silently
# treated as an ordinary (never-initialized) global variable instead --
# confirmed directly against the live reference: compiling `Function
# Add(A, B = 10)\n  Return A + B\nEnd\nN6 = Add(5, 20)` with
# `--disable-optimizations --disable-peephole --disable-live-range`
# produces `MOV P1, 288` / `MOV P0, [P1]` (plain global-memory loads at
# freshly-allocated addresses, never touching the caller's pushed 5/20)
# inside `_func_add_0`, byte-for-byte the same shape this port's own
# `codegen_dump.exe` produces for the identical program. Not a mismatch to
# fix -- this port already reproduces it faithfully (for free, via the
# already-verified `parser.star`), and is recorded here because it's easy
# to mistake for a *codegen* bug when first debugging a `Function` whose
# parameters read back as zero: the real fix, in either implementation, is
# writing NoBASIC function bodies that reference parameters in lowercase
# (`Return a + b`), which resolves correctly in both.

import "ast.star" as ast

# ---------------------------------------------------------------------------
# Byte/string/number helpers -- duplicated locally rather than imported,
# matching `lexer.star`/`parser.star`/`semantic.star`'s own "self-contained
# tool" convention (see `lexer.star`'s header comment).
# ---------------------------------------------------------------------------

fn to_upper_byte(c: i32) -> i32:
    if c >= 97 and c <= 122:
        c - 32
    else:
        c

fn str_upper(s: str) -> str:
    let mut parts: List<str> = List<str>()
    let mut i = 0
    while i < len(s):
        parts.push(chr(to_upper_byte(s[i])))
        i += 1
    str_join(parts, "")

fn to_lower_byte(c: i32) -> i32:
    if c >= 65 and c <= 90:
        c + 32
    else:
        c

fn str_lower(s: str) -> str:
    let mut parts: List<str> = List<str>()
    let mut i = 0
    while i < len(s):
        parts.push(chr(to_lower_byte(s[i])))
        i += 1
    str_join(parts, "")

fn list_contains_str(items: List<str>, target: str) -> bool:
    let mut i = 0
    while i < items.len():
        if items[i] == target:
            return true
        i += 1
    false

fn str_starts_with(s: str, prefix: str) -> bool:
    if len(prefix) > len(s):
        return false
    let mut i = 0
    while i < len(prefix):
        if s[i] != prefix[i]:
            return false
        i += 1
    true

# One hex digit (0-15) as an uppercase nibble character -- used only for
# human-readable assembly *comments* (`; GLOBAL variable: x @ 0x0120`); the
# actual emitted operands are always plain decimal integers, exactly like
# the reference's own bare `f"{addr}"` sites (Python's `:04X` format spec is
# only used in a handful of comment/debug strings, never in a real operand --
# confirmed by inspection). Comments never affect assembled/run behavior, so
# this port doesn't need to match the reference's comment text byte-for-byte,
# only spell addresses in *some* readable hex form.
fn hex_digit(n: i32) -> str:
    if n < 10:
        chr(48 + n)
    else:
        chr(55 + n)

fn hex4(v: i32) -> str:
    let mut parts: List<str> = List<str>()
    parts.push(hex_digit((v >> 12) & 15))
    parts.push(hex_digit((v >> 8) & 15))
    parts.push(hex_digit((v >> 4) & 15))
    parts.push(hex_digit(v & 15))
    str_join(parts, "")

# `+2`/`-4`-style signed offset, matching the reference's `f"{offset:+d}"`
# comment formatting (see `generate_var_declaration`).
fn signed_str(v: i32) -> str:
    if v >= 0:
        f"+{v}"
    else:
        f"{v}"

# `Option<T>` has no `unwrap_or`-style helper method (confirmed: no method
# dispatch for `Option` at all in `src/types/expr.rs` -- every reference
# `dict.get(key, default)`/`Optional[...] or default` site becomes an
# explicit `match`, same as `semantic.star` does throughout). These three
# tiny wrappers stand in for the reference's repeated `.get(x, default)`
# calls against `register_usage`/`interference_graph`/spill-slot lookups,
# rather than spelling out a 4-line `match` at each of the ~12 call sites.
fn opt_bool_or(o: Option<bool>, default: bool) -> bool:
    match o:
        Option::Some(v) -> v
        Option::None -> default

fn opt_i32_or(o: Option<i32>, default: i32) -> i32:
    match o:
        Option::Some(v) -> v
        Option::None -> default

fn opt_list_str_or(o: Option<List<str>>, default: List<str>) -> List<str>:
    match o:
        Option::Some(v) -> v
        Option::None -> default

fn opt_str_or(o: Option<str>, default: str) -> str:
    match o:
        Option::Some(v) -> v
        Option::None -> default

# ---------------------------------------------------------------------------
# Small named structs replacing the reference's dict/tuple/set fields --
# same rationale as `ast::Param`/`semantic.star`'s `PendingGoto`/`BuiltinFn`:
# Star has no tuple-as-field type, and `Map<K,V>` has no key/value iteration
# (confirmed against `src/types/expr.rs`'s `infer_map_method` before
# committing to this, same as `semantic.star`'s header comment) -- every
# reference dict that needs enumeration (not just point lookup) becomes a
# `List<...>` here with linear-scan helpers, the same substitution
# `SymbolTable.structs` already established for the semantic phase, applied
# far more heavily here since register allocation is much more
# iteration-heavy than symbol-table lookups ever were.
# ---------------------------------------------------------------------------

# `var_reg: Dict[str, str]` (variable name -> assigned register). Needs both
# point lookup (constant, throughout codegen) and full iteration (saving/
# restoring variable-backed registers across a user function call, and
# scanning for an evictable P-register-resident variable) -- a `Map<str,str>`
# alone can't do the second, so this is a flat list with linear-scan helper
# methods below (`var_reg_get`/`var_reg_set`/`var_reg_remove`/...).
struct VarReg:
    name: str
    reg: str

# `live_ranges: Dict[str, Tuple[int,int]]` (name -> (start,end) program
# points). Same iteration requirement as `var_reg` (`assign_registers` sorts
# every entry by start time; `build_interference_graph` walks every entry).
struct LiveRange:
    name: str
    start: i32
    end: i32

# `live_at_point: Dict[int, Set[str]]` (program point -> live variable
# names). `vars` acts as a small linear-scanned set (duplicates avoided by
# `record_live_range`'s own insert-if-absent logic, mirroring the
# reference's `set.add`).
struct LiveAtPoint:
    point: i32
    mut vars: List<str>

# `spill_slots`/`hot_spills: Dict[str, int]` (name -> memory address). Only
# ever point-looked-up or fully rebuilt on reset in the reference -- never
# iterated by key/value together -- so this could have been a `Map<str,i32>`
# instead; kept as a list anyway for exact structural symmetry with
# `var_reg`/`live_ranges` above and because `allocate_spill_slot`'s "already
# spilled?" check and the spill-exhaustion error message both want the
# *count*, which `List.len()` gives directly.
struct SpillSlot:
    name: str
    addr: i32

# `strings: List[Tuple[str,str]]` (label, literal value) pairs.
struct StringLiteral:
    label: str
    value: str

# ---------------------------------------------------------------------------
# Codegen
# ---------------------------------------------------------------------------

struct Codegen:
    exprs: List<ast::Expr> = List<ast::Expr>()
    stmts: List<ast::Stmt> = List<ast::Stmt>()
    filename: str = "<stdin>"

    # A single buffer for "wherever code is currently being emitted" --
    # global scope by default, redirected to a fresh per-function buffer
    # while generating a function body (see `generate_function_def` in
    # `codegen_stmt.star`). The reference's `self.output`/`self.current_
    # output` pair relies on Python list *aliasing*: `self.current_output =
    # self.output` makes both names point at the same mutable object, so
    # appending through either is visible through both, and swapping
    # `self.current_output` to a function's own list and back later "just
    # works". Star's `List<T>` is reference-counted but **copy-on-write**
    # (confirmed in `src/codegen/list.rs`'s own header comment: "every
    # *mutating* operation ... clones the buffer if it isn't the sole
    # owner -- so mutating through one alias is never visible through
    # another") -- so that trick does not carry over unchanged. This port
    # uses one field instead of two: `generate_function_def` saves the
    # current buffer to a local `let`, swaps in a *fresh* empty list,
    # generates the function body into that fresh list, captures it, then
    # restores the saved buffer -- since the saved buffer is never mutated
    # while swapped out (only the fresh replacement is), restoring it later
    # sees exactly the lines it had before, with no aliasing required.
    mut current_output: List<str> = List<str>()
    mut label_counter: i32 = 0
    mut variable_addresses: Map<str, i32> = Map<str, i32>()
    mut next_address: i32 = 288
    mut strings: List<StringLiteral> = List<StringLiteral>()
    mut loop_nesting_level: i32 = 0

    mut next_spill_address: i32 = 28672
    mut spill_slots: List<SpillSlot> = List<SpillSlot>()
    mut hot_spills: List<SpillSlot> = List<SpillSlot>()

    mut register_usage: Map<str, bool> = Map<str, bool>()
    mut live_ranges: List<LiveRange> = List<LiveRange>()
    mut live_at_point: List<LiveAtPoint> = List<LiveAtPoint>()
    mut program_counter: i32 = 0
    mut interference_graph: Map<str, List<str>> = Map<str, List<str>>()
    mut max_register_pressure: i32 = 0

    mut allocation_order: List<str> = List<str>()
    mut var_allocation_order: List<str> = List<str>()
    mut var_allocation_fallback: List<str> = List<str>()

    mut var_reg: List<VarReg> = List<VarReg>()
    mut var_register_hints: Map<str, List<str>> = Map<str, List<str>>()

    # `functions`: def-name (lowercased) -> `ast.stmts` index of its
    # `StmtKind::FunctionDef`. `function_labels`: def-name (lowercased) ->
    # generated assembly label. Both point-lookup only (never iterated),
    # so plain `Map<str,...>` suffices -- unlike `var_reg`/`live_ranges`
    # above. Mirrors `semantic.star`'s `Analyzer.functions: Map<str, i32>`.
    mut functions: Map<str, i32> = Map<str, i32>()
    mut function_labels: Map<str, str> = Map<str, str>()
    mut function_counter: i32 = 0
    mut current_function: Option<str> = Option<str>::None
    mut function_outputs: List<List<str>> = List<List<str>>()

    # `function_locals: Dict[str, Dict[str,int]]` flattened to a single
    # `Map<str,i32>` keyed by `"<func_key>::<var_name>"` -- both reference
    # lookups are always by the full (function, variable) pair together, so
    # a nested `Map<str, Map<str,i32>>` would add a layer of indirection
    # this port has no other use for.
    mut function_locals: Map<str, i32> = Map<str, i32>()

    mut auto_free_registers: Set<str> = Set<str>()

    mut total_allocations: i32 = 0
    mut total_deallocations: i32 = 0
    mut allocation_failures: i32 = 0
    mut max_simultaneous_allocated: i32 = 0

    mut had_error: bool = false
    mut error_message: str = ""
    mut error_line: i32 = 0
    mut error_column: i32 = 0

# All 33 CPU registers `register_usage` tracks, in the reference dict's own
# insertion order. `Map<str,bool>` has no key iteration (see header comment),
# so anywhere the reference enumerates every register (allocation-failure
# diagnostics, the "max simultaneously allocated" stat) walks this constant
# list instead, checking `register_usage.get(name)` per entry.
fn all_register_names() -> List<str>:
    [
        "R0", "R1", "R2", "R3", "R4", "R5", "R6", "R7", "R8", "R9",
        "P0", "P1", "P2", "P3", "P4", "P5", "P6", "P7", "SP", "FP",
        "VX", "VY", "VM", "VL", "VC",
        "SA", "SF", "SV", "SW",
        "TT", "TM", "TC", "TS",
    ]

# Builtins whose CPU opcode operates on fixed-point (x256) or otherwise
# routinely-wide values -- see `generator.py`'s own `WIDE_RESULT_MATH_
# BUILTINS` class constant for the full rationale (forces a 16-bit P
# register instead of the generic allocator's default 8-bit R register, to
# avoid silently truncating e.g. `DEG(90)`). Must be kept in sync with
# `codegen_expr.star`'s `generate_function_call` builtin dispatch.
fn wide_result_math_builtins() -> List<str>:
    [
        "SIN", "COS", "TAN", "SQRT", "ABS", "ATAN", "ASIN", "ACOS",
        "DEG", "RAD", "FLOOR", "CEIL", "ROUND", "TRUNC", "FRAC",
        "INTGR", "INT", "LOG", "EXP",
    ]

fn new_codegen(exprs: List<ast::Expr>, stmts: List<ast::Stmt>, filename: str) -> Codegen:
    let mut cg = Codegen(exprs = exprs, stmts = stmts, filename = filename)
    cg.reset()
    cg

impl Codegen:
    # ------------------------------------------------------------------
    # Error reporting -- same `had_error`-flag propagation as `lexer.star`/
    # `parser.star`/`semantic.star`, for the same reason (no single
    # `Result<T,E>` instantiation fits every method here either: some
    # return `str` register names, some return nothing, some return `i32`).
    # Every reference `raise RuntimeError(...)`/`raise CodeGenError(...)`
    # internal-invariant-violation site becomes a `self.fail(...)` call
    # here, checked immediately by the caller. Unlike the reference's
    # exception unwind, a `fail()`'d `Codegen` keeps running with harmless
    # placeholder values (mirroring `semantic.star`'s "return
    # `DataType::Number` on error" sentinel convention) rather than
    # aborting outright -- callers that care check `had_error` and stop
    # doing further work, exactly like every earlier phase in this port.
    # ------------------------------------------------------------------

    fn fail(mut self, message: str, line: i32, column: i32):
        if !self.had_error:
            self.had_error = true
            self.error_message = message
            self.error_line = line
            self.error_column = column

    # ------------------------------------------------------------------
    # State init / reset -- mirrors `__init__`/`_reset_generation_state`.
    # A single `Codegen` is meant to be reused across `generate()` calls
    # only within one process's lifetime (matches the reference); this
    # port's own driver (`main.star`, todo.md P1 #3) will construct one
    # fresh `Codegen` per compile instead, so `reset` only needs to be
    # correct, not necessarily ever called twice in practice.
    # ------------------------------------------------------------------

    fn reset(mut self):
        self.current_output = List<str>()
        self.label_counter = 0
        self.variable_addresses = Map<str, i32>()
        self.next_address = 288
        self.strings = List<StringLiteral>()
        self.loop_nesting_level = 0

        self.next_spill_address = 28672
        self.spill_slots = List<SpillSlot>()
        self.hot_spills = List<SpillSlot>()

        self.register_usage = Map<str, bool>()
        let names = all_register_names()
        let mut i = 0
        while i < names.len():
            self.register_usage.insert(names[i], false)
            i += 1

        self.live_ranges = List<LiveRange>()
        self.live_at_point = List<LiveAtPoint>()
        self.program_counter = 0
        self.interference_graph = Map<str, List<str>>()
        self.max_register_pressure = 0

        self.allocation_order = [
            "P0", "P1", "P2", "P3", "P4", "P5", "P6",
            "R0", "R1", "R2", "R3", "R4", "R5", "R6", "R7", "R8", "R9",
        ]
        self.var_allocation_order = ["P2", "P3", "P4", "P5", "P6"]
        self.var_allocation_fallback = List<str>()

        self.var_reg = List<VarReg>()
        self.var_register_hints = Map<str, List<str>>()

        self.functions = Map<str, i32>()
        self.function_labels = Map<str, str>()
        self.function_counter = 0
        self.current_function = Option<str>::None
        self.function_outputs = List<List<str>>()
        self.function_locals = Map<str, i32>()

        self.auto_free_registers = Set<str>()

        self.total_allocations = 0
        self.total_deallocations = 0
        self.allocation_failures = 0
        self.max_simultaneous_allocated = 0

    fn reserve_data_memory(mut self, byte_count: i32, purpose: str) -> i32:
        let start_addr = self.next_address
        let end_addr = start_addr + byte_count
        if end_addr > 28672:
            self.fail(f"Data memory overflow while allocating {purpose}: requested {byte_count} bytes at 0x{hex4(start_addr)}, but spill storage starts at 0x{hex4(28672)}", 0, 0)
            return start_addr
        self.next_address = end_addr
        start_addr

    # ------------------------------------------------------------------
    # `var_reg` linear-scan helpers (see `VarReg`'s own doc comment).
    # ------------------------------------------------------------------

    fn var_reg_index(self, name: str) -> i32:
        let mut i = 0
        while i < self.var_reg.len():
            if self.var_reg[i].name == name:
                return i
            i += 1
        -1

    fn var_reg_get(self, name: str) -> Option<str>:
        let idx = self.var_reg_index(name)
        if idx < 0:
            Option<str>::None
        else:
            Option<str>::Some(self.var_reg[idx].reg)

    fn var_reg_contains(self, name: str) -> bool:
        self.var_reg_index(name) >= 0

    fn var_reg_set(mut self, name: str, reg: str):
        let idx = self.var_reg_index(name)
        if idx < 0:
            self.var_reg.push(VarReg(name = name, reg = reg))
        else:
            self.var_reg[idx] = VarReg(name = name, reg = reg)

    fn var_reg_remove(mut self, name: str):
        let idx = self.var_reg_index(name)
        if idx < 0:
            return
        let mut rebuilt: List<VarReg> = List<VarReg>()
        let mut i = 0
        while i < self.var_reg.len():
            if i != idx:
                rebuilt.push(self.var_reg[i])
            i += 1
        self.var_reg = rebuilt

    # `sorted(set(self.var_reg.values()))` -- dedup, in this port's own
    # insertion order rather than the reference's ascending-name sort.
    # `str` only supports `==`/`!=` in Star (confirmed: no `<`/`>` ordering
    # for strings in `src/types/expr.rs`), so an ascending sort isn't
    # directly portable -- but it doesn't need to be: every call site
    # (`generate_function_call`'s caller-saved-register save/restore around
    # a user-function `CALL`) only relies on *some* fixed order being pushed
    # and popped symmetrically (`PUSH` in this order, `POP` in the exact
    # reverse), never on the order being alphabetical. Dedup order is a
    # legitimate substitute.
    fn var_reg_distinct_regs(self) -> List<str>:
        let mut out: List<str> = List<str>()
        let mut i = 0
        while i < self.var_reg.len():
            let r = self.var_reg[i].reg
            if !list_contains_str(out, r):
                out.push(r)
            i += 1
        out

    # ------------------------------------------------------------------
    # `live_ranges` linear-scan helpers.
    # ------------------------------------------------------------------

    fn live_range_index(self, name: str) -> i32:
        let mut i = 0
        while i < self.live_ranges.len():
            if self.live_ranges[i].name == name:
                return i
            i += 1
        -1

    # ------------------------------------------------------------------
    # `live_at_point` linear-scan helpers.
    # ------------------------------------------------------------------

    fn live_at_point_index(self, point: i32) -> i32:
        let mut i = 0
        while i < self.live_at_point.len():
            if self.live_at_point[i].point == point:
                return i
            i += 1
        -1

    fn live_vars_at(self, point: i32) -> List<str>:
        let idx = self.live_at_point_index(point)
        if idx < 0:
            List<str>()
        else:
            self.live_at_point[idx].vars

    # Register of a variable that is live at `point`, if it has one.
    # Mirrors the reference's repeated
    # `{self.var_reg.get(v) for v in live_vars if v in self.var_reg}`
    # comprehension (collapsed into a single-name check, since every call
    # site only ever tests "is *this* register blocked").
    fn is_reg_live_at(self, point: i32, reg: str) -> bool:
        let live = self.live_vars_at(point)
        let mut i = 0
        while i < live.len():
            match self.var_reg_get(live[i]):
                Option::Some(r) ->
                    if r == reg:
                        return true
                Option::None -> 0
            i += 1
        false

    fn record_live_range(mut self, name: str, program_point: i32):
        let idx = self.live_range_index(name)
        if idx < 0:
            self.live_ranges.push(LiveRange(name = name, start = program_point, end = program_point))
        else:
            let cur = self.live_ranges[idx]
            let new_start = if cur.start < program_point: cur.start else: program_point
            let new_end = if cur.end > program_point: cur.end else: program_point
            self.live_ranges[idx] = LiveRange(name = name, start = new_start, end = new_end)

        let pidx = self.live_at_point_index(program_point)
        if pidx < 0:
            let mut vars: List<str> = List<str>()
            vars.push(name)
            self.live_at_point.push(LiveAtPoint(point = program_point, vars = vars))
        else:
            if !list_contains_str(self.live_at_point[pidx].vars, name):
                self.live_at_point[pidx].vars.push(name)

    fn mark_temp_live(mut self, reg: str):
        let temp_name = f"_temp_{reg}_{self.program_counter}"
        self.record_live_range(temp_name, self.program_counter)

    fn mark_temp_dead(mut self, reg: str):
        let temp_name = f"_temp_{reg}_{self.program_counter}"
        let idx = self.live_range_index(temp_name)
        if idx >= 0:
            let cur = self.live_ranges[idx]
            self.live_ranges[idx] = LiveRange(name = temp_name, start = cur.start, end = self.program_counter)

    # ------------------------------------------------------------------
    # Interference graph -- `Map<str, List<str>>` adjacency lists, built by
    # point lookup + reinsert (no map iteration needed -- see this file's
    # header comment).
    # ------------------------------------------------------------------

    fn interference_add_edge(mut self, a: str, b: str):
        let mut neighbors_a = opt_list_str_or(self.interference_graph.get(a), List<str>())
        if !list_contains_str(neighbors_a, b):
            neighbors_a.push(b)
        self.interference_graph.insert(a, neighbors_a)

        let mut neighbors_b = opt_list_str_or(self.interference_graph.get(b), List<str>())
        if !list_contains_str(neighbors_b, a):
            neighbors_b.push(a)
        self.interference_graph.insert(b, neighbors_b)

    fn interference_neighbors(self, name: str) -> List<str>:
        opt_list_str_or(self.interference_graph.get(name), List<str>())

    fn build_interference_graph(mut self):
        self.interference_graph = Map<str, List<str>>()
        let mut i = 0
        while i < self.live_ranges.len():
            self.interference_graph.insert(self.live_ranges[i].name, List<str>())
            i += 1

        let mut p = 0
        while p < self.live_at_point.len():
            let live_list = self.live_at_point[p].vars
            let mut a = 0
            while a < live_list.len():
                let mut b = a + 1
                while b < live_list.len():
                    self.interference_add_edge(live_list[a], live_list[b])
                    b += 1
                a += 1
            p += 1

    fn calculate_register_pressure(mut self):
        self.max_register_pressure = 0
        let mut p = 0
        while p < self.live_at_point.len():
            let pressure = self.live_at_point[p].vars.len()
            if pressure > self.max_register_pressure:
                self.max_register_pressure = pressure
            p += 1

    # ------------------------------------------------------------------
    # Register allocation.
    # ------------------------------------------------------------------

    fn update_allocation_stats(mut self):
        let names = all_register_names()
        let mut count = 0
        let mut i = 0
        while i < names.len():
            if opt_bool_or(self.register_usage.get(names[i]), false):
                count += 1
            i += 1
        if count > self.max_simultaneous_allocated:
            self.max_simultaneous_allocated = count

    fn allocate_register(mut self, preferred_reg: Option<str>) -> str:
        self.total_allocations += 1

        let live_vars = self.live_vars_at(self.program_counter)

        match preferred_reg:
            Option::Some(pref) ->
                if !opt_bool_or(self.register_usage.get(pref), true) and !self.is_reg_live_at(self.program_counter, pref):
                    self.register_usage.insert(pref, true)
                    self.auto_free_registers.insert(pref)
                    self.update_allocation_stats()
                    self.mark_temp_live(pref)
                    return pref
            Option::None -> 0

        let order = self.allocation_order
        let mut i = 0
        while i < order.len():
            let reg = order[i]
            if !opt_bool_or(self.register_usage.get(reg), true) and !self.is_reg_live_at(self.program_counter, reg):
                self.register_usage.insert(reg, true)
                self.auto_free_registers.insert(reg)
                self.update_allocation_stats()
                self.mark_temp_live(reg)
                return reg
            i += 1

        self.allocation_failures += 1
        self.fail("Register exhaustion: No available registers (no free registers available)", 0, 0)
        "R0"

    fn allocate_p_register(mut self, preferred_regs: List<str>) -> str:
        self.total_allocations += 1
        let mut i = 0
        while i < preferred_regs.len():
            let reg = preferred_regs[i]
            if self.register_usage.contains(reg) and !opt_bool_or(self.register_usage.get(reg), true):
                self.register_usage.insert(reg, true)
                self.auto_free_registers.insert(reg)
                self.update_allocation_stats()
                self.mark_temp_live(reg)
                return reg
            i += 1

        match self.evict_dead_variable_for_p_register(preferred_regs):
            Option::Some(evicted) ->
                self.register_usage.insert(evicted, true)
                self.auto_free_registers.insert(evicted)
                self.update_allocation_stats()
                self.mark_temp_live(evicted)
                return evicted
            Option::None -> 0

        self.allocation_failures += 1
        self.fail("Register exhaustion: No available P registers for 16-bit operation", 0, 0)
        "P1"

    # Free a P register by spilling a register-resident variable that is
    # provably not live going forward -- see `generator.py`'s own
    # `_evict_dead_variable_for_p_register` doc comment for the full safety
    # argument (reused verbatim; unchanged by the port).
    fn evict_dead_variable_for_p_register(mut self, preferred_regs: List<str>) -> Option<str>:
        let mut i = 0
        while i < self.var_reg.len():
            let entry = self.var_reg[i]
            if str_starts_with(entry.reg, "P") and list_contains_str(preferred_regs, entry.reg) and !self.is_reg_live_at(self.program_counter, entry.reg):
                let name = entry.name
                let reg = entry.reg
                self.allocate_spill_slot(name)
                self.var_reg_remove(name)
                self.store_variable(name, reg)
                self.deallocate_register(reg)
                return Option<str>::Some(reg)
            i += 1
        Option<str>::None

    fn deallocate_register(mut self, reg: str):
        if self.register_usage.contains(reg):
            if self.auto_free_registers.contains(reg):
                self.mark_temp_dead(reg)
            self.register_usage.insert(reg, false)
            self.auto_free_registers.remove(reg)
            self.total_deallocations += 1

    fn smart_deallocate(mut self, reg: str, is_last_use: bool):
        if is_last_use and opt_bool_or(self.register_usage.get(reg), false):
            if !self.var_reg_contains_reg(reg):
                if self.auto_free_registers.contains(reg):
                    self.deallocate_register(reg)
                    self.current_output.push(f"; Free {reg} (last use)")

    fn var_reg_contains_reg(self, reg: str) -> bool:
        let mut i = 0
        while i < self.var_reg.len():
            if self.var_reg[i].reg == reg:
                return true
            i += 1
        false

    # `Set<T>` has no iteration API (same "no key/value iteration"
    # limitation as `Map<K,V>` -- confirmed against `src/types/expr.rs`).
    # `auto_free_registers` only ever holds names from the fixed 33-register
    # universe, so walking `all_register_names()` and checking membership
    # per name stands in for "iterate the set" here.
    fn clear_temp_registers(mut self):
        let names = all_register_names()
        let mut to_free: List<str> = List<str>()
        let mut i = 0
        while i < names.len():
            let reg = names[i]
            if self.auto_free_registers.contains(reg) and !self.var_reg_contains_reg(reg):
                to_free.push(reg)
            i += 1
        i = 0
        while i < to_free.len():
            self.deallocate_register(to_free[i])
            i += 1

    fn get_loop_registers(self) -> List<str>:
        let base_reg_num = 1 + (self.loop_nesting_level * 3)
        let cur = if base_reg_num < 7: base_reg_num else: 7
        let end_n = if base_reg_num + 1 < 7: base_reg_num + 1 else: 7
        let step_n = if base_reg_num + 2 < 7: base_reg_num + 2 else: 7
        [f"P{cur}", f"P{end_n}", f"P{step_n}"]

    # ------------------------------------------------------------------
    # Spill slots.
    # ------------------------------------------------------------------

    fn spill_slot_index(self, name: str) -> i32:
        let mut i = 0
        while i < self.spill_slots.len():
            if self.spill_slots[i].name == name:
                return i
            i += 1
        -1

    fn allocate_spill_slot(mut self, name: str) -> i32:
        let idx = self.spill_slot_index(name)
        if idx >= 0:
            return self.spill_slots[idx].addr
        if self.spill_slots.len() >= 128:
            self.fail(f"Spill slot exhaustion: Cannot allocate spill slot for '{name}' (already spilled: {self.spill_slots.len()}, maximum: 128)", 0, 0)
            return self.next_spill_address
        let addr = self.next_spill_address
        self.spill_slots.push(SpillSlot(name = name, addr = addr))
        self.next_spill_address += 2
        addr

    fn get_spill_slot(self, name: str) -> Option<i32>:
        let idx = self.spill_slot_index(name)
        if idx < 0:
            Option<i32>::None
        else:
            Option<i32>::Some(self.spill_slots[idx].addr)

    fn is_spilled(self, name: str) -> bool:
        self.spill_slot_index(name) >= 0

    fn hot_spill_index(self, name: str) -> i32:
        let mut i = 0
        while i < self.hot_spills.len():
            if self.hot_spills[i].name == name:
                return i
            i += 1
        -1

    fn get_hot_spill(self, name: str) -> Option<i32>:
        let idx = self.hot_spill_index(name)
        if idx < 0:
            Option<i32>::None
        else:
            Option<i32>::Some(self.hot_spills[idx].addr)

    # ------------------------------------------------------------------
    # `assign_registers` -- enhanced linear-scan allocation w/ interference.
    # See `generator.py`'s own doc comment; ported 1:1 modulo the Map/List
    # substitutions this file's header comment explains.
    # ------------------------------------------------------------------

    fn is_allocatable_variable(self, name: str) -> bool:
        if str_starts_with(name, "_temp_"):
            return false
        let upper = str_upper(name)
        !str_starts_with(upper, "STR")

    fn assign_registers(mut self):
        let mut alloc_names: List<str> = List<str>()
        let mut alloc_starts: List<i32> = List<i32>()
        let mut alloc_ends: List<i32> = List<i32>()
        let mut i = 0
        while i < self.live_ranges.len():
            let lr = self.live_ranges[i]
            if self.is_allocatable_variable(lr.name):
                alloc_names.push(lr.name)
                alloc_starts.push(lr.start)
                alloc_ends.push(lr.end)
            i += 1

        # Recompute pressure for allocatable vars only.
        let mut max_pressure = 0
        let mut p = 0
        while p < self.live_at_point.len():
            let mut count = 0
            let vars = self.live_at_point[p].vars
            let mut v = 0
            while v < vars.len():
                if self.is_allocatable_variable(vars[v]):
                    count += 1
                v += 1
            if count > max_pressure:
                max_pressure = count
            p += 1
        self.max_register_pressure = max_pressure

        let mut allocation_pool: List<str> = List<str>()
        i = 0
        while i < self.var_allocation_order.len():
            allocation_pool.push(self.var_allocation_order[i])
            i += 1
        if self.max_register_pressure <= self.var_allocation_order.len():
            i = 0
            while i < self.var_allocation_fallback.len():
                allocation_pool.push(self.var_allocation_fallback[i])
                i += 1

        # Sort variables by start time (stable insertion sort; counts are
        # always small for a NoBASIC program).
        let mut a = 1
        while a < alloc_names.len():
            let kn = alloc_names[a]
            let ks = alloc_starts[a]
            let ke = alloc_ends[a]
            let mut b = a - 1
            while b >= 0 and alloc_starts[b] > ks:
                alloc_names[b + 1] = alloc_names[b]
                alloc_starts[b + 1] = alloc_starts[b]
                alloc_ends[b + 1] = alloc_ends[b]
                b -= 1
            alloc_names[b + 1] = kn
            alloc_starts[b + 1] = ks
            alloc_ends[b + 1] = ke
            a += 1

        let mut active_end: List<i32> = List<i32>()
        let mut active_var: List<str> = List<str>()
        let mut active_reg: List<str> = List<str>()

        let mut vi = 0
        while vi < alloc_names.len():
            let var = alloc_names[vi]
            let start = alloc_starts[vi]
            let end = alloc_ends[vi]

            # Expire intervals whose live range has ended.
            let mut nend: List<i32> = List<i32>()
            let mut nvar: List<str> = List<str>()
            let mut nreg: List<str> = List<str>()
            let mut e = 0
            while e < active_end.len():
                if active_end[e] > start:
                    nend.push(active_end[e])
                    nvar.push(active_var[e])
                    nreg.push(active_reg[e])
                e += 1
            active_end = nend
            active_var = nvar
            active_reg = nreg

            let mut used_regs: List<str> = List<str>()
            e = 0
            while e < active_reg.len():
                used_regs.push(active_reg[e])
                e += 1

            let interfering_vars = self.interference_neighbors(var)
            let mut blocked: List<str> = List<str>()
            e = 0
            while e < used_regs.len():
                if !list_contains_str(blocked, used_regs[e]):
                    blocked.push(used_regs[e])
                e += 1
            e = 0
            while e < interfering_vars.len():
                match self.var_reg_get(interfering_vars[e]):
                    Option::Some(r) ->
                        if !list_contains_str(blocked, r):
                            blocked.push(r)
                    Option::None -> 0
                e += 1

            let mut available: List<str> = List<str>()
            e = 0
            while e < allocation_pool.len():
                if !list_contains_str(blocked, allocation_pool[e]):
                    available.push(allocation_pool[e])
                e += 1

            match self.var_register_hints.get(var):
                Option::Some(hints) ->
                    let mut h = 0
                    while h < hints.len():
                        if list_contains_str(available, hints[h]):
                            let hinted = hints[h]
                            let mut reordered: List<str> = List<str>()
                            reordered.push(hinted)
                            let mut r2 = 0
                            while r2 < available.len():
                                if available[r2] != hinted:
                                    reordered.push(available[r2])
                                r2 += 1
                            available = reordered
                            h = hints.len()
                        h += 1
                Option::None -> 0

            if available.len() > 0:
                let reg = available[0]
                self.var_reg_set(var, reg)
                active_end.push(end)
                active_var.push(var)
                active_reg.push(reg)
                self.register_usage.insert(reg, true)
            else:
                # Spill heuristic: prefer evicting the active interval that
                # ends soonest, if it ends before the current one.
                let mut max_active_end = -1
                e = 0
                while e < active_end.len():
                    if active_end[e] > max_active_end:
                        max_active_end = active_end[e]
                    e += 1

                if active_end.len() > 0 and end < max_active_end:
                    let mut soonest_i = 0
                    e = 1
                    while e < active_end.len():
                        if active_end[e] < active_end[soonest_i]:
                            soonest_i = e
                        e += 1
                    let spill_var = active_var[soonest_i]
                    let spill_reg = active_reg[soonest_i]

                    let mut rend: List<i32> = List<i32>()
                    let mut rvar: List<str> = List<str>()
                    let mut rreg: List<str> = List<str>()
                    e = 0
                    while e < active_end.len():
                        if e != soonest_i:
                            rend.push(active_end[e])
                            rvar.push(active_var[e])
                            rreg.push(active_reg[e])
                        e += 1
                    active_end = rend
                    active_var = rvar
                    active_reg = rreg

                    self.var_reg_remove(spill_var)
                    self.allocate_spill_slot(spill_var)

                    self.var_reg_set(var, spill_reg)
                    active_end.push(end)
                    active_var.push(var)
                    active_reg.push(spill_reg)
                else:
                    self.allocate_spill_slot(var)
            vi += 1

    # ------------------------------------------------------------------
    # Address-scratch-register selection (used by `load_variable`/
    # `store_variable`/`evict_dead_variable_for_p_register` to pick a P
    # register for address computation without clobbering a live variable).
    # ------------------------------------------------------------------

    fn select_address_scratch_reg(self, exclude: List<str>) -> str:
        let candidates = ["P1", "P2", "P3", "P4", "P5", "P6"]

        let mut i = 0
        while i < candidates.len():
            let reg = candidates[i]
            if !list_contains_str(exclude, reg) and !opt_bool_or(self.register_usage.get(reg), false) and !self.is_reg_live_at(self.program_counter, reg):
                return reg
            i += 1

        i = 0
        while i < candidates.len():
            let reg = candidates[i]
            if !list_contains_str(exclude, reg) and !self.is_reg_live_at(self.program_counter, reg):
                return reg
            i += 1

        if !list_contains_str(exclude, "P1"):
            "P1"
        else:
            "P2"

    # ------------------------------------------------------------------
    # Variable addresses, load/store.
    # ------------------------------------------------------------------

    fn get_variable_address(mut self, name: str) -> i32:
        match self.variable_addresses.get(name):
            Option::Some(addr) -> addr
            Option::None ->
                let addr = self.reserve_data_memory(2, f"variable '{name}'")
                self.variable_addresses.insert(name, addr)
                addr

    fn function_local_key(self, func_key: str, var_name: str) -> str:
        concat(func_key, concat("::", var_name))

    fn function_local_offset(self, func_key: str, var_name: str) -> Option<i32>:
        self.function_locals.get(self.function_local_key(func_key, var_name))

    # Index of `name` within a user function's parameter list, or -1.
    # Mirrors the reference's repeated `params.index(name)` lookups.
    fn function_param_index(self, func_key: str, name: str) -> i32:
        match self.functions.get(func_key):
            Option::Some(stmt_id) ->
                match self.stmts[stmt_id].kind:
                    ast::StmtKind::FunctionDef(fname, params, body) ->
                        let mut i = 0
                        while i < params.len():
                            if params[i].name == name:
                                return i
                            i += 1
                        -1
                    _ -> -1
            Option::None -> -1

    fn function_param_count(self, func_key: str) -> i32:
        match self.functions.get(func_key):
            Option::Some(stmt_id) ->
                match self.stmts[stmt_id].kind:
                    ast::StmtKind::FunctionDef(fname, params, body) -> params.len()
                    _ -> 0
            Option::None -> 0

    fn load_variable(mut self, name: str, target_reg: str) -> str:
        match self.current_function:
            Option::Some(func_key) ->
                match self.function_local_offset(func_key, name):
                    Option::Some(offset) ->
                        let mut dest_reg = target_reg
                        if str_starts_with(dest_reg, "R"):
                            dest_reg = self.allocate_p_register(["P1", "P2", "P3"])
                        self.current_output.push("MOV P0, FP")
                        self.current_output.push(f"ADD P0, {offset}")
                        self.current_output.push(f"MOV {dest_reg}, [P0]")
                        return dest_reg
                    Option::None -> 0

                let pidx = self.function_param_index(func_key, name)
                if pidx >= 0:
                    let count = self.function_param_count(func_key)
                    let offset = 4 + (count - 1 - pidx) * 2
                    let mut dest_reg = target_reg
                    if str_starts_with(dest_reg, "R"):
                        dest_reg = self.allocate_p_register(["P1", "P2", "P3"])
                    self.current_output.push("MOV P0, FP")
                    self.current_output.push(f"ADD P0, {offset}")
                    self.current_output.push(f"MOV {dest_reg}, [P0]")
                    return dest_reg
            Option::None -> 0

        let mut effective_target = target_reg
        if str_starts_with(str_upper(name), "STR") and str_starts_with(effective_target, "R"):
            effective_target = "P1"

        match self.var_reg_get(name):
            Option::Some(reg) ->
                if str_starts_with(reg, "P") and str_starts_with(effective_target, "R"):
                    return reg
                if reg != effective_target:
                    self.current_output.push(f"MOV {effective_target}, {reg}")
                return effective_target
            Option::None -> 0

        if self.is_spilled(name):
            let spill_addr = match self.get_hot_spill(name):
                Option::Some(a) -> a
                Option::None -> opt_i32_or(self.get_spill_slot(name), 0)

            if str_starts_with(effective_target, "R"):
                let addr_reg = self.select_address_scratch_reg(List<str>())
                self.current_output.push(f"MOV {addr_reg}, {spill_addr}")
                let value_reg = self.allocate_p_register(["P0", "P1", "P2", "P3", "P4", "P5", "P6"])
                self.current_output.push(f"MOV {value_reg}, [{addr_reg}]")
                return value_reg
            else:
                let addr_reg = self.select_address_scratch_reg([effective_target])
                self.current_output.push(f"MOV {addr_reg}, {spill_addr}")
                self.current_output.push(f"MOV {effective_target}, [{addr_reg}]")
            return effective_target

        let addr = self.get_variable_address(name)
        if str_starts_with(effective_target, "R"):
            let addr_reg = self.select_address_scratch_reg(List<str>())
            self.current_output.push(f"MOV {addr_reg}, {addr}")
            let value_reg = self.allocate_p_register(["P0", "P1", "P2", "P3", "P4", "P5", "P6"])
            self.current_output.push(f"MOV {value_reg}, [{addr_reg}]")
            return value_reg
        else:
            let addr_reg = self.select_address_scratch_reg([effective_target])
            self.current_output.push(f"MOV {addr_reg}, {addr}")
            self.current_output.push(f"MOV {effective_target}, [{addr_reg}]")
        effective_target

    fn store_variable(mut self, name: str, source_reg: str):
        match self.current_function:
            Option::Some(func_key) ->
                match self.function_local_offset(func_key, name):
                    Option::Some(offset) ->
                        self.current_output.push("MOV P0, FP")
                        self.current_output.push(f"ADD P0, {offset}")
                        self.current_output.push(f"MOV [P0], {source_reg}")
                        return
                    Option::None -> 0

                let pidx = self.function_param_index(func_key, name)
                if pidx >= 0:
                    let count = self.function_param_count(func_key)
                    let offset = 4 + (count - 1 - pidx) * 2
                    self.current_output.push("MOV P0, FP")
                    self.current_output.push(f"ADD P0, {offset}")
                    self.current_output.push(f"MOV [P0], {source_reg}")
                    return
            Option::None -> 0

        match self.var_reg_get(name):
            Option::Some(reg) ->
                if reg != source_reg:
                    self.current_output.push(f"MOV {reg}, {source_reg}")
                return
            Option::None -> 0

        if self.is_spilled(name):
            let spill_addr = match self.get_hot_spill(name):
                Option::Some(a) -> a
                Option::None -> opt_i32_or(self.get_spill_slot(name), 0)

            if str_starts_with(source_reg, "R"):
                let value_reg = self.select_address_scratch_reg([source_reg])
                let addr_reg = self.select_address_scratch_reg([source_reg, value_reg])
                self.current_output.push(f"MOV {value_reg}, 0")
                self.current_output.push(f"MOV :{value_reg}, {source_reg}")
                self.current_output.push(f"MOV {addr_reg}, {spill_addr}")
                self.current_output.push(f"MOV [{addr_reg}], {value_reg}")
            else:
                let addr_reg = self.select_address_scratch_reg([source_reg])
                self.current_output.push(f"MOV {addr_reg}, {spill_addr}")
                self.current_output.push(f"MOV [{addr_reg}], {source_reg}")
            return

        let addr = self.get_variable_address(name)
        if str_starts_with(source_reg, "R"):
            let value_reg = self.select_address_scratch_reg([source_reg])
            let addr_reg = self.select_address_scratch_reg([source_reg, value_reg])
            self.current_output.push(f"MOV {value_reg}, 0")
            self.current_output.push(f"MOV :{value_reg}, {source_reg}")
            self.current_output.push(f"MOV {addr_reg}, {addr}")
            self.current_output.push(f"MOV [{addr_reg}], {value_reg}")
        else:
            let addr_reg = self.select_address_scratch_reg([source_reg])
            self.current_output.push(f"MOV {addr_reg}, {addr}")
            self.current_output.push(f"MOV [{addr_reg}], {source_reg}")

    # ------------------------------------------------------------------
    # Liveness collection -- pre-pass over the AST, populating
    # `live_ranges`/`live_at_point` before `assign_registers` runs.
    # ------------------------------------------------------------------

    fn collect_lifetimes(mut self, program: List<i32>):
        self.program_counter = 0
        let mut i = 0
        while i < program.len():
            self.collect_lifetimes_stmt(program[i])
            i += 1
        self.build_interference_graph()
        self.calculate_register_pressure()

    fn collect_lifetimes_stmt(mut self, stmt_id: i32):
        self.program_counter += 1
        let current_point = self.program_counter
        let stmt = self.stmts[stmt_id]

        match stmt.kind:
            ast::StmtKind::Assignment(variable, expr) ->
                match self.exprs[variable].kind:
                    ast::ExprKind::Variable(name) ->
                        self.record_live_range(name, current_point)
                    _ -> 0
                self.collect_lifetimes_expr(expr)
            ast::StmtKind::For(variable, start, end, step, body) ->
                self.record_live_range(variable, current_point)
                self.collect_lifetimes_expr(start)
                self.collect_lifetimes_expr(end)
                match step:
                    Option::Some(s) -> self.collect_lifetimes_expr(s)
                    Option::None -> 0
                let mut bi = 0
                while bi < body.len():
                    self.collect_lifetimes_stmt(body[bi])
                    bi += 1
                let loop_end_point = self.program_counter
                self.record_live_range(variable, loop_end_point)
            ast::StmtKind::If(condition, then_branch, else_branch) ->
                self.collect_lifetimes_expr(condition)
                let mut ti = 0
                while ti < then_branch.len():
                    self.collect_lifetimes_stmt(then_branch[ti])
                    ti += 1
                match else_branch:
                    Option::Some(eb) ->
                        let mut ei = 0
                        while ei < eb.len():
                            self.collect_lifetimes_stmt(eb[ei])
                            ei += 1
                    Option::None -> 0
            ast::StmtKind::While(condition, body) ->
                self.collect_lifetimes_expr(condition)
                let mut wi = 0
                while wi < body.len():
                    self.collect_lifetimes_stmt(body[wi])
                    wi += 1
            ast::StmtKind::Repeat(body, condition) ->
                let mut ri = 0
                while ri < body.len():
                    self.collect_lifetimes_stmt(body[ri])
                    ri += 1
                self.collect_lifetimes_expr(condition)
            ast::StmtKind::Disp(text) ->
                self.collect_lifetimes_expr(text)
            ast::StmtKind::SerOut(value) ->
                self.collect_lifetimes_expr(value)
            ast::StmtKind::SerCtrl(value) ->
                self.collect_lifetimes_expr(value)
            # Deliberately NOT collected, matching a genuine reference
            # quirk confirmed by direct inspection of `collect_lifetimes_
            # stmt`/`collect_lifetimes_expr_from_stmt` (`generator.py`
            # 823-970): `FunctionCallStmt`/`ExpressionStmt`/`ReturnStmt`/
            # `FunctionDefStmt` are absent from **both** isinstance chains,
            # so a bare `Foo(x)` call statement, an `x++` expression
            # statement, and a `Return expr` statement's own expression
            # never get their variable uses recorded into `live_ranges` --
            # only `Disp`/`SerOut`/`SerCtrl`/the graphics statements (not
            # yet ported) and the five explicitly-handled kinds above do.
            # This costs those variables a chance at a register (they fall
            # through to plain global-memory access instead, still
            # correct, just not register-optimized) -- not a value-
            # corruption bug, so reproduced here rather than "improved"
            # into recursing further than the reference actually does.
            # Function bodies are excluded for a different, structural
            # reason: `generate()`'s function-definition pre-pass emits
            # every function body's assembly (via ordinary `generate_
            # statement` calls, which bump `self.program_counter` the
            # same as any other statement) *before* `collect_lifetimes`
            # ever runs and resets `program_counter` back to 0 -- so
            # function-local variables are never candidates for `var_reg`
            # in the first place, confirmed by `generate_for`'s own
            # `is_register_allocated = ... and self.current_function is
            # None` guard (register allocation is unconditionally skipped
            # whenever `current_function` is set). Recursing into a
            # `FunctionDef`'s body here would just double-count program
            # points that can never affect a real allocation decision.
            _ -> 0

    fn collect_lifetimes_expr(mut self, expr_id: i32):
        let current_point = self.program_counter
        let expr = self.exprs[expr_id]
        match expr.kind:
            ast::ExprKind::Variable(name) ->
                self.record_live_range(name, current_point)
            ast::ExprKind::ListAccess(list_name, index) ->
                self.collect_lifetimes_expr(index)
            ast::ExprKind::MemberAccess(object, member) ->
                self.collect_lifetimes_expr(object)
            ast::ExprKind::MatrixAccess(matrix_name, row, col) ->
                self.collect_lifetimes_expr(row)
                self.collect_lifetimes_expr(col)
            ast::ExprKind::Binary(left, operator, right) ->
                self.collect_lifetimes_expr(left)
                self.collect_lifetimes_expr(right)
            ast::ExprKind::Unary(operator, inner, is_post) ->
                self.collect_lifetimes_expr(inner)
            ast::ExprKind::Call(name, arguments) ->
                let mut i = 0
                while i < arguments.len():
                    self.collect_lifetimes_expr(arguments[i])
                    i += 1
            ast::ExprKind::Grouping(inner) ->
                self.collect_lifetimes_expr(inner)
            _ -> 0

    # ------------------------------------------------------------------
    # Constant folding.
    # ------------------------------------------------------------------

    fn fold_constants(self, operator: str, left_val: i32, right_val: i32) -> Option<i32>:
        if operator == "+":
            Option<i32>::Some(left_val + right_val)
        elif operator == "-":
            Option<i32>::Some(left_val - right_val)
        elif operator == "*":
            Option<i32>::Some(left_val * right_val)
        elif operator == "/":
            if right_val == 0:
                Option<i32>::None
            else:
                Option<i32>::Some(left_val / right_val)
        elif operator == "%" or operator == "MOD":
            if right_val == 0:
                Option<i32>::None
            else:
                Option<i32>::Some(left_val % right_val)
        elif operator == "&" or operator == "AND":
            Option<i32>::Some(left_val & right_val)
        elif operator == "|" or operator == "OR":
            Option<i32>::Some(left_val | right_val)
        elif operator == "^" or operator == "XOR":
            Option<i32>::Some(left_val ^ right_val)
        elif operator == "<<" or operator == "SHL":
            Option<i32>::Some(left_val << right_val)
        elif operator == ">>" or operator == "SHR":
            Option<i32>::Some(left_val >> right_val)
        elif operator == "<":
            Option<i32>::Some(if left_val < right_val: 1 else: 0)
        elif operator == ">":
            Option<i32>::Some(if left_val > right_val: 1 else: 0)
        elif operator == "=":
            Option<i32>::Some(if left_val == right_val: 1 else: 0)
        elif operator == "<>":
            Option<i32>::Some(if left_val != right_val: 1 else: 0)
        elif operator == "<=":
            Option<i32>::Some(if left_val <= right_val: 1 else: 0)
        elif operator == ">=":
            Option<i32>::Some(if left_val >= right_val: 1 else: 0)
        else:
            Option<i32>::None

    fn fold_unary_constant(self, operator: str, value: i32) -> Option<i32>:
        if operator == "-":
            Option<i32>::Some(-value)
        elif operator == "NOT":
            Option<i32>::Some(~value)
        elif operator == "ABS":
            Option<i32>::Some(if value < 0: -value else: value)
        else:
            Option<i32>::None

    # Whether `expr` will produce a string address (16-bit) rather than a
    # numeric value -- string variables are named `Str...` by convention,
    # matching `is_string_expression`'s own reference doc comment.
    fn is_string_expression(self, expr_id: i32) -> bool:
        let expr = self.exprs[expr_id]
        match expr.kind:
            ast::ExprKind::Literal(data_type, num_value, is_float, str_value) ->
                data_type == ast::DataType::String
            ast::ExprKind::Variable(name) ->
                str_starts_with(str_upper(name), "STR")
            ast::ExprKind::Binary(left, operator, right) ->
                if operator == "+":
                    self.is_string_expression(left) or self.is_string_expression(right)
                else:
                    false
            _ -> false

    # ------------------------------------------------------------------
    # Label / string-literal helpers.
    # ------------------------------------------------------------------

    fn new_label(mut self) -> str:
        self.label_counter += 1
        f"L{self.label_counter}"

    fn add_string_literal(mut self, string_value: str) -> str:
        let mut i = 0
        while i < self.strings.len():
            if self.strings[i].value == string_value:
                return self.strings[i].label
            i += 1
        let label = f"STR{self.label_counter}"
        self.label_counter += 1
        self.strings.push(StringLiteral(label = label, value = string_value))
        label

    fn escape_assembly_string(self, string_value: str) -> str:
        let mut parts: List<str> = List<str>()
        let mut i = 0
        while i < len(string_value):
            let c = string_value[i]
            if c == 92:
                parts.push("\\\\")
            elif c == 34:
                parts.push("\\\"")
            elif c == 10:
                parts.push("\\n")
            elif c == 13:
                parts.push("\\r")
            elif c == 9:
                parts.push("\\t")
            elif c == 0:
                parts.push("\\0")
            else:
                parts.push(chr(c))
            i += 1
        str_join(parts, "")
