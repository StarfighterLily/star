# NoBASIC-in-Star -- implementation notes

Port of NoBASIC (a TI-BASIC-inspired language that compiles to Nova-16
assembly) from its reference Python implementation to native Star,
`todo.md`'s current-focus item. The reference lives in a sibling project,
`c:\Code\projects\Nova\NoBASIC\` -- `compiler/lexer/`, `compiler/parser/`,
`compiler/semantic/`, `compiler/codegen/` (lexer through codegen, ~9,500
lines) plus `nobasic_compiler.py` (~660 lines, the CLI/pipeline driver).
Scope is the compiler pipeline only -- `.nobasic` source text in, Nova-16
assembly text out, consumable by `projects/nova/assembler.star` -- not
`nobasic_vm.py`/`nobasic_debugger.py`/`nobasic_profiler.py`/
`nobasic_inspect.py`, which are real but separate, later-round tools if
ever wanted (see `todo.md`'s "Current focus" note for the full scope
writeup).

## Lexer + tokens (todo.md P0 #1)

`tokens.star`/`lexer.star` port `compiler/lexer/tokens.py`/`lexer.py`
variant-for-variant and method-for-method. Verified byte-for-byte against
the live Python reference: `tests/lexer_dump.star` tokenizes
`tests/fixtures/lexer_sample.nobasic` (a synthetic fixture exercising
every keyword family, operator, delimiter, number-literal form, string
escape, and the `Asm ... End` block) and prints one deterministic line per
token; `tests/fixtures/lexer_sample.expected.txt` is that exact dump
generated once from the reference `Lexer` via a throwaway script (not
checked in anywhere -- it lives outside both projects) and frozen.
`tests/run_lexer_test.ps1` diffs the two -- see its own header comment for
the regeneration procedure. All 332 lines matched on the first real
end-to-end run, including a real reference quirk this port deliberately
preserves rather than "fixing": an `Asm ... End` block's `AsmBlock` and
`End` tokens both end up with an oversized `lexeme` spanning all the way
back to the original `Asm` keyword, because the reference's `start_position`
tracking is only ever reset once per `scan_token` call (see `lexer.star`'s
own header comment for the full explanation).

Two real, documented reference/implementation drifts found while porting
(not bugs in this port -- the Python lexer genuinely behaves this way):

- The ~20 "built-in function" `TokenType` variants (`SIN`/`COS`/`SQRT`/...)
  are declared but never registered in the reference's own `KEYWORDS`
  dict, so those names lex as plain `IDENTIFIER` tokens, not their own
  token kind. `tokens.star`'s `keyword_lookup` matches this (not the
  variants' apparent intent) -- see its header comment.
- A NoBASIC `\0` string escape produces a real NUL byte in the reference's
  Python `str`. Star strings are null-terminated C strings underneath, so
  the equivalent `Token.str_value` would likely truncate at that byte if
  it ever crossed a C-interop boundary. No checked-in `.nobasic` source
  uses `\0`, so left as a documented, not-yet-hit limitation (`tokens.star`
  header comment) rather than worked around.

### A genuine Star compiler bug found and fixed

Building `tests/lexer_dump.star` -- whose `main` matches on `lex()`'s
`Result`, with both arms `return`-ing, followed by more code (a `while`
loop and a trailing value) -- made `star build` fail: "internal compiler
error: malformed LLVM IR emitted ... has a `unreachable` terminator before
its last instruction". Root cause: `Codegen::body_terminates`
(`src/codegen/stmt.rs`) only asked whether the **last** statement of a
block terminates it, and every plain statement-sequence emitter
(`emit_stmts_value`'s non-trailing-statement loop, plus raw `for stmt in
body.stmts { emit_stmt(stmt) }` loops in `if`/`while`/`for` bodies and
`spawn`/`each` bodies in `arena.rs`) walked every statement unconditionally
regardless of whether an *earlier* one already closed the block with a
terminator. A bare `return`/`break`/`continue` can only legally be the
last statement in a reachable sequence, so this never surfaced before --
but a mid-sequence `match`/`if` where *every* arm/branch itself terminates
is perfectly ordinary, legal source with more code after it (only the
reachable arm/branch's own continuation ever runs that code), and its own
codegen already closes with `unreachable` in exactly that case. Once that
happened, every subsequent statement in the same list got appended to the
same already-terminated block.

Fixed by redefining `body_terminates` as "does *any* statement in the list
terminate" (not just the last one) and adding a single shared
`Codegen::emit_stmt_seq` helper (stops emitting the moment a statement
terminates) that every one of those raw loops now goes through, plus
teaching `emit_stmts_value` to skip its own trailing statement entirely
when the statements before it already terminated the block. Regression
test: `tests/frontend_terminating_match_midsequence.rs` (three end-to-end
cases -- a top-level terminating match, one nested inside a `while` body,
and terminating matches nested inside both arms of an `if`/`else` -- each
compiled, run, and checked against real stdout, not just "does it build").
Full `cargo test` suite re-verified clean after the fix.

Separately noticed but **not** fixed (out of scope for this bug, filed
here for whoever next touches match-arm parsing): `docs/language_reference.md`'s
own "Generic Functions" section shows `match o: Option::Some(v) -> return
v  Option::None -> return default` as a single-line match-arm body, but
`return <expr>` doesn't actually parse there (`return` is
statement-only, not reachable from `parse_match_arm`'s inline-expression
path) -- confirmed with a direct `star check` repro. This port's own
`lexer.star`/`tests/lexer_dump.star` and the regression test above all use
the (working) multi-line block-arm form (`pattern ->` newline `return
...`) instead.

## Parser + AST (todo.md P0 #2)

`ast.star`/`parser.star` port `compiler/parser/ast.py`/`parser.py`. Two
representation choices forced by real Star language constraints (not
stylistic preferences), both confirmed empirically before committing to
them and both documented at length in the files' own header comments --
summarized here for anyone scanning this log first:

- **Index-based AST arena, not an object tree.** The reference's
  `BinaryExpr.left: Expression` nests a child node by value; a Star
  `struct`/`enum` field naming its own (or a mutually recursive) type by
  value is a hard compile-time error ("has infinite size -- use `GenRef<T>`
  instead of nesting by value", `src/types/mod.rs`'s
  `check_no_recursive_structs`). `GenRef<T>` itself was ruled out too (an
  arena-`spawn`/generational-handle mechanism for runtime ECS entities, not
  a fixed compile-time tree). `Expr`/`Stmt` are flat structs whose
  `ExprKind`/`StmtKind` payloads reference children by `i32` index into a
  flat `Ast.exprs`/`Ast.stmts` list instead -- confirmed empirically to
  compile and work (a `List<T>` field is always a fixed-size handle
  regardless of `T`, so it never trips the recursive-layout check).
- **`had_error`-flag error propagation, not `Result<T, E>` chains.**
  `lexer.star`'s own header comment already explains why for this project:
  a postfix `?` requires the *enclosing function's* declared return type to
  be the exact same `Result<T, E>` instantiation as whatever it propagates,
  not merely a compatible success type. This parser's methods don't share
  one success type (`consume` hands back a `Token`; every expression/
  statement parser hands back an `i32` arena index) and call into each
  other in both directions, so `Parser` carries `had_error` plus the
  failure's message/line/column as ordinary mutable fields, exactly like
  `Lexer` does. See `parser.star`'s header comment for the corollary this
  raised that the lexer never had to deal with: every raw `while <cond>:
  body.append(self.statement())`-shaped scanning loop needed an explicit
  `and not self.had_error` guard, since (unlike the reference's
  exception-unwind) `statement()`'s generic "no matching case" failure
  doesn't consume a token before failing -- a real infinite-loop hazard,
  confirmed by inspection, not defensive boilerplate for its own sake.

Two more reference/implementation drifts found while porting (both
confirmed by direct inspection of `parser.py`, not assumed):

- `LET` is a real lexed keyword (`tokens.star`'s `KEYWORDS` table already
  had it) but `Parser.statement()` never has a case for it -- `Let X = 5`
  is not valid syntax in the live reference parser at all (falls through to
  "Expected statement"). Only bare `X = 5` (`assignment_statement`) works.
  This port's own `tests/fixtures/parser_sample.nobasic` uses bare
  assignment throughout for exactly this reason (confirmed the fixture
  parses against the live Python reference before freezing it).
- `Parser._is_builtin_function_name` (a ~70-entry table) is dead code: its
  one call site in `statement()` is always preceded by a `check_next(COLON)`
  label-statement branch that takes priority regardless of the identifier's
  name, and is itself followed by a plain `elif token.type == IDENTIFIER`
  branch with byte-identical behavior. `parser.star` collapses all three
  reference branches into one `Identifier` match arm and never builds the
  table -- see `parser.star`'s header comment.

Verified byte-for-byte against the live Python reference, same shape as
the lexer's own test: `tests/parser_dump.star` parses
`tests/fixtures/parser_sample.nobasic` (hand-written, but confirmed to
actually parse against the live reference `Parser` before freezing --
unlike the lexer's fixture, this one must be syntactically valid, not just
lexically thorough) and prints one deterministic, indented line per AST
node; `tests/fixtures/parser_sample.expected.txt` is that exact dump from
the reference `Parser`, generated via a throwaway script (not checked in,
same as the lexer's). `tests/run_parser_test.ps1` diffs the two. All 488
lines matched -- but only after finding and fixing a second genuine Star
compiler bug along the way (below); the very first attempt failed to build
at all.

### A second genuine Star compiler bug found and fixed

Building `tests/parser_dump.star` -- whose `dump_expr`/`dump_stmt` read
`a.exprs[id]`/`a.stmts[id]` out of a `List<Expr>`/`List<Stmt>` (each
wrapping a payload-carrying `enum` with `str` fields) and then `match` on
the result's `.kind` -- made `star build` fail: "internal compiler error:
malformed LLVM IR emitted ... `phi` ... lists incoming blocks
[list_idx_ok_N, list_idx_oob_N] but the actual predecessors are
[enum_rc_next_N, list_idx_oob_N]". Root cause:
`Codegen::emit_list_index`/`Codegen::emit_genref_index`
(`src/codegen/list.rs`/`src/codegen/arena.rs`) each captured their own
`ok_label` block-name *before* calling `emit_retain_at` on the freshly
loaded element, then reused that captured name as the `phi`'s predecessor
once execution reached the shared `end_label`. But `emit_retain_at` isn't
straight-line code when the element type is RC-bearing and
payload-carrying: retaining an `enum`'s active variant needs a runtime tag
check, which opens its own conditional block(s)
(`enum_rc_variant_N`/`enum_rc_next_N`) -- so the block that actually falls
through to `end_label` is whichever one `emit_retain_at` left current, not
the original `ok_label`, and the `phi`'s declared predecessor silently went
stale. A non-RC element type (`i32`, ...) never triggers this
(`emit_retain_at` is a no-op and never opens a block), which is why it went
unnoticed until a real `List<Struct-with-str-field>` was indexed and
matched on. `MapMethod::Get` (`src/codegen/map.rs`) already had the correct
fix in place for the identical hazard (captures `self.current_label.clone()`
*after* its own `emit_retain_at` call) -- both new fixes just apply that
same already-established pattern. Every other `emit_retain_at`/
`emit_release_at` call site in the codebase was individually audited for
the same shape (either loops back unconditionally with no phi, or writes
into a pre-allocated scratch `alloca` instead of phi-merging an SSA
value) -- these two were the only affected sites.

Minimal repro (confirmed reproduces on the pre-fix compiler, confirmed
fixed after):

```star
enum K:
    A(name: str)

struct Node:
    kind: K

fn walk(nodes: List<Node>, id: i32) -> str:
    let n = nodes[id]
    match n.kind:
        K::A(name) -> name
```

Regression test: `tests/frontend_list_index_rc_retain_phi.rs` in the main
repo (two end-to-end cases -- `List<T>` indexing and `GenRef<T>`
dereferencing, both through a `struct` wrapping a `str`-carrying `enum`).
Full `cargo test` suite (82 test binaries, 0 failures) re-verified clean
after the fix.

**Environment note, not a code issue:** rebuilding `star.exe` itself
mid-session repeatedly failed with "Access is denied" removing
`target/debug/star.exe` -- caused by this workspace's VS Code Star LSP
extension (`star lsp --stdio`) holding the previous binary open; it
auto-restarts under the same lock the moment it's killed, so the fix was
building to an alternate `--target-dir target-fix` instead of fighting the
lock (now gitignored). Anyone hitting the identical "Access is denied"
message rebuilding this compiler from inside an editor session with the
Star LSP active should do the same rather than repeatedly killing/
retrying.

## Semantic analyzer (todo.md P0 #3)

`semantic.star` ports `compiler/semantic/analyzer.py` (779 lines) --
`Scope`/`SymbolTable`/`SemanticAnalyzer` become `Scope`/`SymbolTable`/
`Analyzer`, walking the same `ast::Ast` arena `parser.star` builds. Same
`had_error`-flag propagation as `lexer.star`/`parser.star`, for the same
reason (no single `Result<T, E>` fits every method's return type here
either). Two representation choices forced by real Star constraints, both
confirmed empirically and documented at length in the file's own header
comment:

- **`SymbolTable.structs` is a `List<ast::StructType>` with linear-scan
  lookup, not a `Map<str, StructType>`.** Confirmed against
  `src/types/expr.rs`'s `infer_map_method` before committing to this:
  Star's `Map<K, V>` supports only `insert`/`get`/`remove`/`contains`/
  `len` -- no key/value iteration at all. `get_structs_with_field` (used
  by `infer_struct_instance_type` to guess which struct a bare
  `player.hp`-style member access refers to) and the "exactly one struct
  total" fallback both need to enumerate *every* struct definition, which
  a `Map` alone can't do.
- **One `Map<str, BuiltinFn>` built-in-function table, not the reference's
  four separate ones** (`is_builtin_function`'s membership list,
  `get_function_arg_count`'s dict, `get_function_arg_types`'s dict,
  `get_function_return_type`'s dict). Porting that shape verbatim would
  repeat each of the ~107 function-name string literals up to four times
  across four hand-synced tables -- `register_builtins` instead builds one
  row per function (`reg(name, count_a, count_b, arg_types, return_type)`),
  cross-checked against all four reference tables function-by-function
  while writing it.

Two genuine reference quirks confirmed while doing that cross-check (not
assumed, not "fixed" -- reproduced exactly, via `BuiltinFn.has_count =
false` for the first one):

- `LN`/`POW` are listed in `is_builtin_function`'s membership check but
  have **no entry at all** in `get_function_arg_count`/
  `get_function_arg_types` -- so the reference silently skips both
  argument-count and argument-type validation for exactly these two
  functions, unlike every other same-shape math function (`LOG`, `EXP`,
  ...), which does get `expected 1 arg, NUMBER` checking. Looks like an
  oversight, but is the actual live behavior.
- There is no `_is_matrix_name`-equivalent to `_is_list_name`: a bare `L1`
  auto-vivifies as a list purely from its name shape in *both*
  `analyze_expression`'s `Variable` case and `analyze_assignable_
  expression`'s `ListAccess` case, but a matrix is only ever auto-vivified
  through the "this name isn't defined as anything yet" fallback inside
  `MatrixAccess` assignment -- confirmed no `_is_matrix_name` function
  exists in `analyzer.py` at all. Already true of the reference itself, not
  a gap this port introduced.

One genuine reference **bug**, found and deliberately not reproduced
(documented per `todo.md`'s "any such gap ... should be documented ...
not silently reconciled" guidance, applied here even though it's a bug in
the implementation rather than a design-doc/implementation drift): the
pending-`GOTO` undefined-label check constructs `SemanticError(f"Undefined
label '{label_name}'", line, column)` -- only 3 positional args against
`CompilerError.__init__(self, message, filename="<stdin>", line=0,
column=0)`. That silently passes the goto's own `line` as `filename` and
`column` as `line`, leaving the real `column` at its default `0`. Confirmed
directly against the live reference (not just by reading source): running
it on a one-line `Goto Nowhere` fixture prints "Error in 1 at line 1,
column 0: Undefined label 'Nowhere'" -- `1` is the goto's real *line*
misplaced into the filename slot, the second `1` is its real *column*
misplaced into the line slot, and the real column is lost to the default.
Star's `SemanticError` is a typed struct, so the identical mistake would be
a compile error here, not a silent mix-up -- `analyze`'s equivalent check
constructs it with the correct field order instead. This is the one place
this port's own test fixture (`tests/fixtures/semantic_errors/
undefined_label_goto.nobasic`) deliberately freezes output that differs
from a raw run of the live Python reference; `semantic_dump.star`'s and
`run_semantic_test.ps1`'s own header comments both flag this explicitly so
a future regenerator doesn't "fix" it back to match the buggy reference.

Verified against the live Python reference, but in a different shape than
the lexer/parser rounds' single big token/AST dump: `SymbolTable`'s
`Map`/`Set` fields have no iteration API at all (see above), so there's no
way to dump-and-diff its full internal state the way a token stream or AST
naturally can be. Instead, `tests/semantic_dump.star` exercises the one
externally observable behavior the reference itself exposes -- does
`analyze()` raise, and with what message/line/column -- across
`tests/fixtures/semantic_valid.nobasic` (one large program, every
statement kind, exercised together and confirmed to `analyze()` cleanly
against the live reference before freezing) plus 23 small one-error-each
snippets under `tests/fixtures/semantic_errors/` (each confirmed
individually against the live reference via a throwaway
`run_semantic_ref.py`-style driver script, not checked in -- lives outside
both projects, same as the lexer/parser rounds' own generators). All 24
outputs matched on the first real run once the one deliberate non-match
above was accounted for. `tests/run_semantic_test.ps1` diffs the whole
batch, same "no in-language assertion facility, so dump and diff instead"
shape as `run_lexer_test.ps1`/`run_parser_test.ps1`.

### A third genuine Star compiler bug found and fixed

Building a test program with a `match` used as a bare statement (result
never read) where one arm's own trailing statement was itself a void call
(`println(..)`) sitting side-by-side with sibling arms that end in a real
value (an int literal, or a call returning one) -- exactly
`Analyzer::analyze_statement`'s own dispatch shape, where some match arms
call `self.analyze_expression(..)` (returns `ast::DataType`) next to
purely-side-effecting arms, followed by more statements later in the same
function body -- made `star build` fail: "internal compiler error:
malformed LLVM IR emitted ... use of undefined value `%undef`". Root
cause: `Checker::infer_expr`'s `TypedExpr::Match` case infers the whole
match's type from just its value-producing arms (the same `is_unknown`
exclusion `Checker::trailing_value_ty` already uses for a trailing
`if`/`else`), so a void-typed sibling arm doesn't stop the match's overall
`produces_value` flag from being `true` -- but `Codegen::emit_expr`'s own
`TypedExpr::Match` case had no matching exclusion when collecting each
arm's contribution to the shared `phi`: it called `emit_stmts_value` on
the void arm's body, got back `Some("%undef")` (`emit_call_expr`'s own
bare-sentinel result for a call with no declared return type), and fed
that string through `reg_of` unchanged instead of recognizing it as "no
value". The result: `[ %undef, %block ]` in the emitted `phi` -- a
reference to an SSA register literally *named* `undef`, never defined
anywhere, rather than the LLVM literal `undef` keyword every other "arm
contributes no value" case already emits correctly.

Fixed by `Codegen::arm_phi_reg` (`src/codegen/mod.rs`), a shared helper
replacing all seven duplicated `val.map(|v| self.reg_of(&v)).unwrap_or_else(||
"undef".to_string())` call sites (one per `Pattern` kind in the
match-arm-emission loop): it treats the exact bare string `"%undef"` the
same as `None`, since a real value's `emit_expr` result always carries a
type tag and a space (e.g. `"i32 %t5"`) and can never collide with the
sentinel's distinct no-tag-no-space shape. Regression test:
`tests/frontend_match_void_arm_phi.rs` in the main repo (two cases -- the
match used as a bare statement, and its result bound via `let`, covering
two of the seven duplicated call sites). Full `cargo test` suite
re-verified clean after the fix.

**Environment note, not a code issue:** running several `star check`/`star
build` invocations concurrently on this machine made each one appear to
hang past a 120s timeout -- not an infinite loop, just CPU contention
between multiple debug-build compiler processes (confirmed: a backgrounded
invocation that looked stuck past 120s completed successfully once given
room to run without competing invocations). Anyone hitting an apparent
hang checking/building a `.star` file in this project should retry
sequentially, one invocation at a time, before assuming a compiler bug.

## Codegen core (todo.md P1 #1)

`codegen.star`/`codegen_expr.star`/`codegen_stmt.star` port `compiler/
codegen/generator.py` (5,323 lines -- by far the largest single file in the
reference). Same `impl`-block-per-file split `projects/nova/cpu.star`/
`cpu_*.star` established for the CPU emulator port (confirmed the pattern
still applies to a from-scratch three-way split, not just an
already-written file being carved up): `codegen.star` holds the `Codegen`
struct, register allocation/liveness/spill machinery, and small helpers;
`codegen_expr.star` holds expression codegen; `codegen_stmt.star` holds
statement codegen and the `generate()` driver. All three `impl codegen::
Codegen:` the same type from separate files -- confirmed this works for
brand-new files the same way it worked for `cpu_*.star`'s pre-existing
split, as long as every entry point (`tests/codegen_dump.star` here)
imports all three, even the ones it never references by alias directly.

**Scope, and why it's deliberately not 100% of `generator.py`:** see
`codegen.star`'s own header comment for the complete, itemized breakdown
(kept there rather than duplicated here so it stays next to the code it
describes) -- the short version is every genuine correctness-affecting
piece of "core" codegen is ported (the full linear-scan/interference-graph
register allocator, constant folding, all arithmetic/comparison/logical
operators, function calls both user-defined and a ~30-function builtin
subset, `If`/`For`/`While`/`Repeat`/`Goto`/`Label`, variable assignment),
while list/matrix/struct access, the dynamic list heap runtime, all 13
graphics statements, `Input`, and roughly two-thirds of the builtin table
by name count are not yet ported -- genuinely deferred work, not
simplifications, and every one of those reaches an explicit `self.fail(...)`
in `codegen_stmt.star`'s statement dispatch or `codegen_expr.star`'s
builtin dispatch, never silent wrong output. Separately, six `Optional[
<optimizations.py class>]` fields and their driving `apply_*_optimizations`
methods, plus `expr_constant_values`/`variable_access_counts`/per-point
`register_pressure` (all three confirmed write-only once the six
optimization-pass fields are gone -- see `codegen.star`'s header comment
for the grep-confirmed reasoning behind each) and the two genuinely dead
`@contextmanager` methods, are not ported at all.

**Verification, in the same "dump and diff against the live reference"
shape as every earlier phase**, but with a twist this phase is the first to
need: `tests/codegen_dump.star` + `tests/run_codegen_test.ps1` compile
`tests/fixtures/codegen/arith_control_functions.nobasic` (a program
exercising every statement/expression kind this round ports) all the way to
Nova-16 assembly text and diff it against `tests/fixtures/codegen/
arith_control_functions.expected.txt`, generated from this port and
cross-checked line-for-line against a real run of the live Python
reference (`python nobasic_compiler.py <file> --output <out>
--disable-optimizations --disable-peephole --disable-live-range` --
that flag combination is the fair comparison point, since this port
implements none of the three optimization passes those flags gate, and
`apply_pre_allocation_optimizations`/`apply_post_allocation_optimizations`
both no-op via their own `if not self.enable_optimizations: return` guards
under it). Result: **exact match**, line for line, except one deliberate,
documented divergence (the `GroupingExpr` bug fix below) and a trailing-
newline artifact of the comparison script itself. Additionally verified in
a way no earlier phase could be (there was no assembler/CPU to hand output
to before this phase existed): the emitted assembly was fed straight
through the already-working `projects/nova/assembler.star`, which
assembled it cleanly with zero errors, and the resulting `.bin` was loaded
into `projects/nova/tests/run_bin.exe` (the CPU emulator's own headless
runner), which executed real instructions from it before halting on an
unrelated unimplemented opcode unrelated to anything this round emits
(confirms the emitted assembly is not just textually plausible but
actually valid, loadable, executable Nova-16 machine code).

Three genuine reference **bugs** found and confirmed directly against the
live reference (not just by reading source), matching this project's
established "reproduce quirks, fix genuine bugs, always document either
way" standard:

- **`LN`/`POW` builtin dispatch gap.** `semantic.star`'s builtin table
  (mirroring the reference's own `is_builtin_function` list) recognizes
  `LN`/`POW` as valid builtin names, but `generate_function_call`'s
  ~1,000-line `elif` chain has no branch for either -- confirmed by
  grepping the whole method. A call to either passes semantic analysis
  cleanly, then silently falls through to the reference's own bare `return
  target_reg` with whatever was already in that register: no error, no
  code emitted, a silently wrong runtime value. This port's builtin dispatch
  deliberately leaves `LN`/`POW` out of its named arms too, so they fall
  into the same catch-all `self.fail(...)` every genuinely-unported builtin
  does -- a loud compile-time failure, strictly safer than the reference's
  silent bad value, not a byte-for-byte mismatch worth chasing.
- **`GroupingExpr` missing from `generate_expression`'s dispatch.**
  `generate_expression`'s `isinstance` chain has cases for every other
  expression kind but none for `GroupingExpr`, even though the parser
  genuinely constructs one for any parenthesized expression
  (`parser.py:774`). Every parenthesized expression falls through to the
  chain's final `else: self.current_output.append(f"MOV {target_reg}, 0")`
  -- the grouped expression is silently discarded and replaced with the
  constant `0`. Confirmed by compiling `Disp (2+3)*4` against the live
  reference with the same three `--disable-*` flags: emitted assembly is
  `MOV P0, 0` / `SHL R1, 2` (the `*4` strength-reduced, the `(2+3)` operand
  entirely ignored) -- the program displays `0`, not `20`. Severe enough
  (parentheses are common; this makes every one of them silently wrong)
  that this port does not reproduce it: `codegen_expr.star`'s
  `generate_expression` has a real `ast::ExprKind::Grouping(inner) -> ...`
  arm recursing into `inner` with `target_reg` as its register preference.
  This is the one place `tests/fixtures/codegen/
  arith_control_functions.expected.txt` deliberately freezes output that
  differs from a raw run of the live reference (`GY = (1 + 2) * 3` folds to
  `9` here, `0` there) -- flagged in both `codegen.star`'s header comment
  and `run_codegen_test.ps1`'s own header comment so a future regenerator
  doesn't "fix" it back to match the buggy reference.
- **Function parameter names are lowercased by the parser; body references
  aren't.** `parser.py`'s `function_declaration` calls `.lexeme.lower()` on
  both the function name and every parameter name (`parser.py:900,907,914`)
  when building `FunctionDefStmt`/`Param`, but `primary()`'s plain-
  identifier case building a `VariableExpr` does not lowercase
  (`parser.py:763`). So `Function Add(A, B = 10)\n  Return A + B\nEnd`
  parses `params = ["a", "b"]` while the body's own references stay
  `VariableExpr("A")`/`VariableExpr("B")` -- and both the reference's
  `load_variable`/`store_variable` (`if name in params: ...`, exact-case)
  and this port's `Codegen::function_param_index` do an exact-case lookup
  that can never match. The parameter silently reads back as an
  uninitialized global instead of the caller's argument. This is not a
  porting bug to fix -- `parser.star` was already verified byte-for-byte
  against the reference back in P0 #2, so this port reproduces the bug for
  free, confirmed by compiling the exact program above against the live
  reference and getting the identical `MOV P1, 288` / `MOV P0, [P1]`
  (plain global-memory load, never touching the pushed argument) shape
  this port's own `codegen_dump.exe` produces. Recorded here because it's
  an easy trap when debugging a `Function` whose parameters read as zero:
  the fix, in either implementation, is writing NoBASIC function bodies
  that reference their own parameters in lowercase (this port's own
  fixture uses `Function Add(a, b = 10) ... Return a + b ... End` for
  exactly this reason).

No new Star **compiler** bugs found this round -- the first phase of this
port not to hit one. One real, if minor, Star **language** friction
confirmed and worked around, extending the "single-line match-arm body"
finding from the parser/semantic rounds below: a bare assignment
(`Option::Some(x) -> some_var = value`) is *also* unusable as a single-line
match-arm body, not just `return`/compound-assignment -- same fix
(multi-line block-arm form) applied throughout both new files.

## Ideas for future work

- Codegen core's remaining scope (`todo.md` P1 #1, itemized in
  `codegen.star`'s own header comment): list/matrix/struct access + the
  dynamic list heap runtime, all 13 graphics statements, `Input`, and the
  bit/shift/memory/type-conversion/graphics-as-function/list-as-function
  slice of the builtin table. Then codegen's optimization passes (P1 #2),
  then the CLI driver + `--headless` flag (P1 #3) -- see `todo.md` for the
  full breakdown.
- The `return`-as-inline-match-arm-expression doc/parser drift noted above
  (found during the lexer round, still unaddressed) turned out to have a
  second face: `return` *and* compound assignment (`+=`) are both also
  unusable as a single-line `match`-arm body anywhere, not just after
  `return` specifically -- hit twice more while writing `semantic.star`
  (`Option::Some(t) -> return t`, `Option::None -> min_args += 1`), both
  worked around the same way (multi-line block-arm form). The codegen round
  above found a third face of the same issue (plain `=` assignment, not
  just `return`/`+=`). Still unaddressed upstream; worth fixing all at once
  alongside the original finding.
- The `LET`-keyword-is-dead-code drift and `_is_builtin_function_name`
  dead-code drift noted above -- worth flagging upstream to the Python
  reference project, same as the lexer round's own KEYWORDS gap.
