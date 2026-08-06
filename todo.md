# Star project todo

`P0`-`P3`, lowest number = highest priority. See `docs/conventions.md` for
the full workflow and `projects/nova/NOTES.md` for the Nova-16 port's own
round-by-round log (a separate document because it predates this board and
is long enough to want its own file).

## Current focus: porting NoBASIC to Star

New effort (started 2026-08-05): port the NoBASIC language compiler --
today a reference Python implementation living in a sibling project,
`c:\Code\projects\Nova\NoBASIC\compiler\` (lexer/parser/semantic/codegen,
~9,500 lines) plus its `nobasic_compiler.py` CLI driver (~660 lines) -- to
native Star, the same way `projects/nova/` already ported the Nova-16 CPU
emulator itself. Lands in the empty `projects/nova/NoBASIC/` stub already
checked into this repo. Scope for this effort is the compiler pipeline
only (source text in, Nova-16 assembly text out) -- NOT `nobasic_vm.py`
(a separate ~1,100-line NoBASIC-level interpreter), `nobasic_debugger.py`,
or `nobasic_profiler.py`/`nobasic_inspect.py`. Those are real, but are
their own later rounds if wanted, matching how `projects/nova/`'s own
assembler -> disassembler -> debugger progression staged one tool at a
time rather than attempting all of it in one pass.

Expect drift between `NoBASIC Design.md` (the reference project's own
design doc) and what `nobasic_compiler.py`/`compiler/` actually do --
confirmed at least once already (the lexer's `KEYWORDS` table registers
only the ~40 core statement/control-flow keywords, while the ~20
"built-in function" `TokenType` variants like `SIN`/`COS`/`SQRT` are never
actually mapped to a keyword by the lexer, so those function names lex as
plain `IDENTIFIER` tokens and must be recognized by name later in the
pipeline, not by token type). Any such gap found while porting a given
phase should be documented in that `.star` file's own header comment
(this project's established practice -- see `assembler.star`'s
"Deliberate deviations" section for the calibration), not silently
reconciled to match whichever of the two Python sources looks more
"correct."

- [x] **P0 #1: Lexer + tokens.** Done. Ported `compiler/lexer/tokens.py`
      (`TokenType` enum, `Token`, `KEYWORDS`/`SINGLE_CHAR_TOKENS`/
      `MULTI_CHAR_OPERATORS` tables) and `compiler/lexer/lexer.py`
      (`Lexer.tokenize`) to `projects/nova/NoBASIC/tokens.star`/`lexer.star`.
      Covers numbers (decimal/`0x`/`0b`), strings with `\n\r\t\"\\\0`
      escapes, `//` line comments, the two-character operators (`<>`, `<=`,
      `>=`, `<<`, `>>`, `++`, `--`), and the special `Asm ... End` raw-text
      block capture. Verified byte-for-byte against the live Python
      reference: `tests/lexer_dump.star` + `tests/run_lexer_test.ps1` diff
      a 332-line token dump of `tests/fixtures/lexer_sample.nobasic`
      against a frozen reference-generated fixture -- exact match on the
      first real run, including a genuine reference lexeme-tracking quirk
      this port deliberately preserves (see `NOTES.md`'s "Lexer + tokens"
      section for the two documented reference/implementation drifts found
      along the way). Also found and fixed a real Star **compiler** bug
      hit while building the test harness itself -- see `NOTES.md`'s "A
      genuine Star compiler bug found and fixed" section and
      `tests/frontend_terminating_match_midsequence.rs` in the main repo
      for the full writeup/regression test; full `cargo test` suite
      re-verified clean after the fix.
- [x] **P0 #2: Parser + AST.** Done. Ported `compiler/parser/ast.py` to
      `ast.star` as an index-based node arena (`Expr`/`Stmt` structs whose
      `ExprKind`/`StmtKind` payloads reference children by `i32` index into
      a flat `Ast.exprs`/`Ast.stmts` list, not by nesting a child node by
      value -- Star's recursive-struct-layout check rejects that outright;
      see `NOTES.md`'s "Parser + AST" section for the full reasoning) and
      `compiler/parser/parser.py` to `parser.star` as a `had_error`-flag
      recursive-descent parser (same propagation shape `lexer.star`
      established, for the same reason: no single `Result<T, E>`
      instantiation fits every method's return type). Verified byte-for-byte
      against the live Python reference: `tests/parser_dump.star` +
      `tests/run_parser_test.ps1` diff a 488-line indented AST dump of
      `tests/fixtures/parser_sample.nobasic` against a frozen
      reference-generated fixture -- exact match, after finding and fixing a
      second genuine Star **compiler** bug hit while building the test
      harness itself (a stale `phi` predecessor after an RC-retain call that
      opens its own conditional block -- see `NOTES.md`'s "A second genuine
      Star compiler bug found and fixed" section and
      `tests/frontend_list_index_rc_retain_phi.rs` in the main repo for the
      full writeup/regression test; full `cargo test` suite re-verified
      clean after the fix). Also found two real reference/implementation
      drifts (`LET` is a lexed-but-dead keyword; `_is_builtin_function_name`
      is dead code) -- see `NOTES.md` for both. Depends on #1.
- [x] **P0 #3: Semantic analyzer.** Done. Ported `compiler/semantic/
      analyzer.py` (779 lines) to `semantic.star` (`Scope`/`SymbolTable`/
      `SemanticAnalyzer` -> `Scope`/`SymbolTable`/`Analyzer`), same
      `had_error`-flag propagation as `lexer.star`/`parser.star`. Two
      representation choices forced by Star's `Map<K,V>` having no
      key/value iteration API (confirmed against `src/types/expr.rs`
      before committing): `SymbolTable.structs` is a `List<ast::
      StructType>` with linear-scan lookup instead of a `Dict[str,
      StructType]` (needed since `get_structs_with_field`/the
      "exactly one struct total" fallback both enumerate every
      definition, not just look one up by key), and the reference's four
      separate built-in-function tables (membership list + 3 dicts)
      consolidated into one `Map<str, BuiltinFn>`, cross-checked
      function-by-function against all four originals. Found two genuine
      reference quirks (`LN`/`POW` silently skip all arg validation; no
      `_is_matrix_name`-equivalent to `_is_list_name` exists) and one
      genuine reference **bug**, confirmed directly against the live
      Python reference, not just by reading source (the pending-`GOTO`
      check's `SemanticError` constructor call passes positional args in
      the wrong order, corrupting its own error message) -- this port
      deliberately does not reproduce the bug; see `NOTES.md`'s "Semantic
      analyzer" section for the full writeup of all three plus the
      reasoning. Verified against the live Python reference in a
      different shape than the lexer/parser rounds (no state to
      dump-and-diff without `Map`/`Set` iteration): `tests/
      semantic_dump.star` checks pass/fail + error message/line/column
      across `tests/fixtures/semantic_valid.nobasic` (one large clean
      program) plus 23 one-error-each snippets under `tests/fixtures/
      semantic_errors/`, every one individually confirmed against the
      live reference via a throwaway script before freezing; all 24
      matched (after accounting for the one deliberate non-match from the
      bug above). `tests/run_semantic_test.ps1` diffs the batch. Also
      found and fixed a third genuine Star **compiler** bug along the way
      -- see `NOTES.md`'s "A third genuine Star compiler bug found and
      fixed" section and `tests/frontend_match_void_arm_phi.rs` in the
      main repo for the full writeup/regression test; full `cargo test`
      suite re-verified clean after the fix. Depends on #2.
- [ ] **P1 #1: Codegen core.** Port `compiler/codegen/generator.py` (5,323
      lines -- by far the largest single file in the reference) to Star,
      emitting Nova-16 assembly text compatible with
      `projects/nova/assembler.star`. Depends on #3. **Substantial progress,
      not yet complete** -- split across `codegen.star`/`codegen_expr.star`/
      `codegen_stmt.star` the way `cpu.star` was split across `cpu_*.star`,
      as expected. Done: the `Codegen` struct and all its state; the full
      linear-scan/interference-graph register allocator (`allocate_
      register`/`allocate_p_register`/spill slots/liveness collection/
      `assign_registers`); load/store for variables (register-resident,
      spilled, function-local, function-parameter, and plain global-memory
      cases); constant folding and multiply-by-power-of-2 strength
      reduction; expression codegen for literals/variables/binary/unary
      (including pre/post `++`/`--`)/grouping/user-defined function calls/a
      ~30-function builtin subset (math, string, `MIN`/`MAX`, `GETKEY`/
      `SERIN`/`SERSTAT`/`PAUSE`); statement codegen for assignment (to a
      plain variable), `If`/`For`/`While`/`Repeat`/`Goto`/`Label`,
      `FunctionDef`/`Return`, `Disp`/`Pause`/`AsmBlock`/`VarDecl`/sound-and-
      serial statements; and the top-level `generate()` driver (function
      pre-pass, liveness, register assignment, prologue, statement walk,
      `HLT`, function bodies, string literals). Verified two ways: (1)
      `tests/codegen_dump.star` + `tests/run_codegen_test.ps1` diff a full
      program's emitted assembly against a fixture generated from, and
      cross-checked line-for-line against, the live Python reference run
      with `--disable-optimizations --disable-peephole --disable-live-range`
      -- exact match except one deliberate, documented fix (see below); (2)
      the emitted assembly was fed straight through the already-working
      `projects/nova/assembler.star`/`cpu.star`, assembling cleanly and
      executing real instructions on the CPU emulator. Along the way, found
      and did **not** reproduce three genuine reference bugs (a `LN`/`POW`
      builtin dispatch gap, a `GroupingExpr` case entirely missing from
      `generate_expression`'s dispatch so every parenthesized expression
      silently became the constant `0`, and confirmed -- though this one
      needed no fix, since the already-verified `parser.star` already
      matches it -- that function parameter names are lowercased by the
      parser while body references aren't, so a function body must
      reference its own parameters in lowercase to actually read them); see
      `NOTES.md`'s "Codegen core" section for the full writeup of all three
      plus the complete list of what's genuinely deferred (list/matrix/
      struct access and the dynamic list heap runtime, all 13 graphics
      statements, `Input`, and roughly two-thirds of the builtin-function
      table by name count -- bit/shift/memory/type-conversion/graphics-as-
      function/list-as-function ops). Every unported `StmtKind`/builtin name
      reaches an explicit `self.fail(...)`, never silent wrong output.
- [ ] **P1 #2: Codegen optimization passes.** Port
      `compiler/codegen/optimizations.py` (1,038 lines),
      `compiler/codegen/peephole.py` (592 lines), and
      `compiler/codegen/live_range_scheduler.py` (595 lines). Depends on
      #1.
- [ ] **P1 #3: CLI driver + `--headless`.** Port `nobasic_compiler.py`'s
      pipeline-wiring/CLI surface (include-file resolution, error
      remapping back to original source lines, output-file naming) to a
      `main.star` entry point for the `projects/nova/NoBASIC/` sub-project.
      Add a `--headless` flag: compile the given `.nobasic` file, assemble
      the result with `projects/nova/assembler.star`, run it for a fixed
      cycle budget on `cpu.star` with no window, and dump final
      register/memory state to stdout -- the same "deterministic dump a
      shell script can diff" shape `projects/nova/tests/run_bin.star`
      already established (this project has no in-language assertion
      facility -- see `NOTES.md`'s "Testing" section), letting a test
      script compile+run a `.nobasic` program and check its actual
      behavior end to end, not just that it compiles. Depends on #1-#4.

## Previous work

- 2026-08-05: P0 #1 (lexer + tokens) done -- see its own entry above and
  `projects/nova/NoBASIC/NOTES.md` for the full writeup, including a real
  Star compiler codegen bug (`Codegen::body_terminates`/statement-sequence
  emission only recognized a block-terminating `return`/`break`/`continue`
  as the *last* statement in a list, not a mid-sequence `match`/`if` where
  every arm/branch itself terminates) found and fixed along the way, with
  its own regression test (`tests/frontend_terminating_match_midsequence.rs`
  in the main repo). Also noticed but filed rather than fixed (out of
  scope for that bug): `docs/language_reference.md`'s "Generic Functions"
  example showing `return v` as an inline single-line match-arm body
  doesn't actually parse (`return` isn't reachable from
  `parse_match_arm`'s expression-position path) -- see `NOTES.md` for the
  repro.
- 2026-08-05: Reseeded this board for the NoBASIC-to-Star port above.
  `todo.md` was empty going into this cycle (the prior cycle's items had
  all shipped; see `changelog/072_2026_08_05_7491a70_todo.md` and its own
  "Previous work" trail for everything before this).
- 2026-08-05: P0 #2 (parser + AST) done -- see its own entry above and
  `projects/nova/NoBASIC/NOTES.md`'s "Parser + AST" section for the full
  writeup, including a second real Star compiler codegen bug
  (`Codegen::emit_list_index`/`Codegen::emit_genref_index` phi-merging a
  loaded value's block-predecessor name captured *before* a
  possibly-block-opening RC-retain call, instead of after) found and fixed
  along the way, with its own regression test
  (`tests/frontend_list_index_rc_retain_phi.rs` in the main repo).
- 2026-08-05: P0 #3 (semantic analyzer) done -- see its own entry above and
  `projects/nova/NoBASIC/NOTES.md`'s "Semantic analyzer" section for the
  full writeup, including a third real Star compiler codegen bug (a `match`
  arm whose own trailing statement is a void call fed its `"%undef"`
  no-value sentinel straight into a `phi` unchanged instead of the literal
  `undef`, malforming the IR whenever a sibling arm produces a real value)
  found and fixed along the way, with its own regression test
  (`tests/frontend_match_void_arm_phi.rs` in the main repo).
- 2026-08-05: P1 #1 (codegen core) started -- substantial progress, not
  marked done; see its own entry above and `projects/nova/NoBASIC/
  NOTES.md`'s "Codegen core" section for the full writeup. No new Star
  **compiler** bugs found this round (first phase of this port not to hit
  one). Remaining work for a future round: list/matrix/struct access +
  the dynamic list heap runtime, all 13 graphics statements, `Input`, and
  the bit/shift/memory/type-conversion/graphics-as-function/list-as-
  function slice of the builtin table -- see `codegen.star`'s own header
  comment for the precise remaining-work list, kept there rather than
  duplicated here since it's the file most likely to need updating as
  each piece lands.
