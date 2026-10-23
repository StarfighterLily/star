# Star project todo

`P0`-`P3`, lowest number = highest priority. See `docs/conventions.md` for
the full workflow and `projects/nova/NOTES.md` for the Nova-16 port's own
round-by-round log (a separate document because it predates this board and
is long enough to want its own file).

## Current focus: porting HavokOS (LPMUD driver) to Star

New effort (started 2026-10-22, see `projects/havokos/havokos.md` for the
charter): a native Star port of HavokOS, the clean-room Pike LPMUD driver at
`E:\dsdev\havokos`. MVP: boot the stock Dead Souls 3.9 mudlib
(`E:\ds3.9\lib`) and let a player log in. **Never open FluffOS source**,
including the `E:\ds3.9\fluffos-2.23-ds03\` tree that ships next to the
mudlib. The reference *transpiles* LPC to Pike and relies on Pike's runtime
compiler, and Star can't compile code at runtime, so from the parser on this
is an LPC bytecode compiler + VM rather than a line-by-line port. See
`projects/havokos/NOTES.md` for the architecture, the Star constraints that
shape it (probed, not assumed), and the milestone plan. Each milestone is
verified against the live Pike driver (Pike is installed) on the real
mudlib before it's marked done.

- [x] **HavokOS P0 #1 (M1): LPC front end.** Done. `projects/havokos/
      lexer.star` + `preprocess.star` (a from-scratch token-level
      preprocessor replacing both `preprocess.pike` and the Pike `cpp()` it
      wraps) reproduce the reference front end's post-preprocessing token
      stream on every DS3.9 `.c` file:
      - All 2378 match a frozen fixture generated from the live reference
        (`tests/run_tokdump_test.ps1`), about 20 s per run.
      - 2376 succeed and the same 2 fail.
      - 9 files with `@MARK` text blocks are compared without line numbers.
        The reference reports wrong lines there, and this port deliberately
        doesn't reproduce that bug (NOTES.md "Deliberate deviations").
      - Macro edge cases DS3.9 never exercises are pinned against Pike
        `cpp()` by `tests/run_pp_cases_test.ps1`. Two of those rules
        differ from ISO C: no rescanning into the following text, and no
        permanent blue paint.
      Found and fixed a genuine Star **compiler** bug along the way:
      `print`/`println` of a non-f-string `str` passed it to `printf` as
      the format, so `%` in the data was interpreted (`"%^RED%^"` printed
      as `"^RED^"`, `"%s"` segfaulted). Fix in
      `src/codegen/builtins.rs::emit_print_like`, regression test
      `tests/frontend_print_percent.rs`.
- [x] **HavokOS P0 #2 (M2): parser.** Done. `projects/havokos/ast.star`
      (a `Node` arena with one `NodeKind` variant per reference node kind)
      + `parser.star` (`parser.pike` ported method for method) reproduce
      the reference parser's AST exactly:
      - All 2378 DS3.9 files match a frozen fixture of the live
        reference's canonical AST dumps (`tests/run_astdump_test.ps1`),
        about 21 s per run. The same 2376 parse and the same 2 fail.
      - The 9 `@MARK` files are compared without line numbers, as in M1.
      - Grammar DS3.9 never uses (case ranges, scoped function pointers,
        `parse_command`, default arguments, `ob->(expr)`, labelled
        inherits) is pinned by `tests/fixtures/astlib/ast_cases.c`, and 12
        one-mistake files check success/failure parity
        (`tests/run_ast_cases_test.ps1`).
      Found and fixed a genuine Star **compiler** bug along the way: a
      field read off a struct-returning call (`f().field`) on the
      right-hand side of `and`/`or` spilled into a slot that was released
      at scope exit even when the short-circuit skipped it. That released
      uninitialized stack and segfaulted the parser on its first file.
      Fix in `src/codegen/mod.rs` (`emit_place`) and `src/codegen/rc.rs`
      (`emit_scope_release`), regression test
      `tests/frontend_spill_slot_conditional_release.rs`. Full suite
      re-run: 2093 pass, and the only failures are the 5 pre-existing
      `@fgetc` ones below.
- [x] **HavokOS P0 #3 (M3): bytecode compiler + VM core.** Done.
      `projects/havokos/compiler.star` (AST -> stack-machine bytecode,
      `program.star`) + `vm.star` (interpreter, programs, objects,
      loading/cloning, call_other, the driver object stack) + `efuns.star`
      (the M3 subset). The value model is handle-based, as planned
      (`value.star`). Checked against the live Pike driver three ways:
      - All 76 language-semantics cases of the reference's own
        `pike/tests/run_tests.pike` table give the reference's results,
        including its two check_error cases (`tests/run_cases_test.ps1`,
        selection `tests/fixtures/cases/m3_selection.txt`). The fixture is
        what the live driver returned, cross-checked against the table's
        expected column. Efun-library cases are M4's, object-model ones
        M5's.
      - 92 edge cases of this port's own (`m3_extra_cases.txt`: closures
        sharing locals by reference, nested lvalue chains, varargs/spreads,
        switch fallthrough/ranges, catch in loops, dispatch rules, float
        printing) match the reference's results too. They turned up two
        Pike semantics the table never shows: `3 == 3.0` is false, and the
        empty array is one shared object.
      - Compile sweep of all 2378 DS3.9 files against the reference's
        `transpile()` (`tests/run_compile_sweep_test.ps1`, about 21 s): the
        same 2373 compile, with identical inheritance tables (hashed
        `all_funcs`/`all_vars`), and the same 5 fail on missing files.
        Doing this found that the reference driver predefines
        config-derived macros (`MUD_NAME`, `__HAVOKOS__`, ...), which M1's
        front-end comparison never saw. `Vm.configure()` adds them now.
      Speed is already comparable with the reference: `fib(25)` plus a 1M
      loop take 0.48 s including boot, against 1.28 s.
      Found and fixed a genuine Star **compiler** bug along the way: an
      `extern "C" fn` reached through a diamond import (a file imported
      along two paths) wasn't deduplicated, so the checker rejected it as
      "declared more than once". Fix in `src/modules.rs`, regression test
      `tests/frontend_extern_diamond_import.rs` (its positive tests fail
      without the fix).
      Deliberately left for later milestones (NOTES.md "2026-10-23: M3"):
      runtime line numbers in errors, the eval cost limit, GC, destruct
      (M5); `sscanf`/`parse_command` lvalue arguments (M4). Four new
      deliberate deviations are documented in NOTES.md (#3-#6: double
      floats, negative-constant switch, per-declaration closure cells,
      64-bit int wrap).
- [x] **HavokOS P1 #1 (M4): efuns.** Done. The efun library, one file per
      area (`efuns_str`/`efuns_arr`/`efuns_file`, `sprintf`, `sscanf`,
      `regex`, `md5`, `tcolour`, `saveformat`, `numfmt`, `buf`.star), plus
      `sscanf` lvalues compiled the emitter's way and the master loaded at
      boot for valid_read/valid_write. Checked against the live Pike driver
      (`tests/run_cases_test.ps1`, now all six fixtures, 458 cases):
      - The reference table's 20 efun-library cases (`m4_selection.txt`).
      - 204 edge cases of this port's own (`m4_cases.txt`). `sprintf`/
        `sscanf` are Pike's built-ins in the reference, so their rules were
        probed against Pike: strict types (`sprintf("%f", 3)` returns the
        format), precision 3 by default, `%:N`, `%Nc`, %O's layout, column
        mode. Every file efun runs on a scratch area of the test mudlib,
        and all of the reference's FluffOS-derived `terminal_colour` cases
        run in one case.
      - The 740 `query_num`/`pluralize` golden values (FluffOS output).
      - 36 calls to Dead Souls 3.9's own simul_efuns on the real mudlib,
        both drivers booted to DS3.9's simul_efun object (`-ds`). That
        needed `get_config()`, added.
      The DS3.9 compile sweep and the M1/M2 token/AST sweeps still pass,
      with the tools rebuilt on the changed compiler.
      Found and fixed along the way:
      - A genuine Star **compiler** bug: math builtins (`sqrt`/`pow`/
        `sin`/`log`/...) narrowed an `f64` argument to `f32`. Fix in
        `src/types/mod.rs` (`math_result_ty`) and
        `src/codegen/builtins.rs`, regression test
        `tests/frontend_math_f64.rs` (4 of its 7 tests fail without it).
      - An M3 bug in the port: LPC int `+`/`-`/`*`/`/`/`%`/shifts used
        Star's trapping `i64` ops, so an overflow aborted the whole driver.
        They now wrap (`vm.star` `wadd`/.../`wshr`).
      New Star compiler surface: filesystem and calendar builtins
      (`dir_list`, `path_kind`, `file_size`, `file_mtime`, `dir_create`,
      `dir_remove`, `file_remove`, `file_rename`, `local_time`;
      `src/codegen/fs.rs`, `tests/frontend_fs.rs`), because the FFI can't
      read a C struct out-parameter. The Linux arm is IR/object-verified
      only (`docs/cross_platform_scope.md`).
      Four new deliberate deviations are documented in NOTES.md (#7 no NUL
      bytes in strings, #8 map/filter over strings work, #9 insertion-order
      mappings, plus #3's float-printing note).
- [ ] **HavokOS P1 #2 (M5): object model.** Master/sefun loading, load/
      clone/destruct, environment/move, add_action/commands, call_outs,
      heart beats, reset/clean_up.
- [ ] **HavokOS P1 #3 (M6): network + boot (MVP).** Needs new Star
      `tcp_listen`/`tcp_accept` builtins in `src/codegen/net.rs`, since
      today only client sockets exist and FFI can't build a `sockaddr_in`.
      Then telnet and login, and DS3.9 boots.
- [ ] **HavokOS P2 #1: Star compiler, capitalized `extern "C"` names.**
      `extern "C" fn Sleep(ms: i32)` / `GetTickCount()` fail with
      "undefined type `Sleep`": a capitalized name is resolved as a type,
      which blocks binding most of the Win32 API. Repro in
      `projects/havokos/NOTES.md`, constraint #7.
- [ ] **HavokOS P2 #2: Star compiler, O(1) `str` indexing.** `s[i]` runs
      `strlen` for its bounds check, so a char-at-a-time scan is quadratic:
      about 70 s for 1 MB, against about 1 ms over `Bytes`. Fixing it
      likely means storing the length in the `str` RC header. Worked around
      in HavokOS by using `Bytes` everywhere hot.
- [ ] **HavokOS P2 #3: Star compiler, float literals are single
      precision.** `2.718281828459045 as f64` is 2.7182817...: a float
      literal is typed `f32` and only then widened, so an `f64` constant
      silently loses everything past the 7th digit. Found in M4 while
      writing `tests/frontend_math_f64.rs`. Worked around in HavokOS by
      computing constants (`(1.0 as f64) / (3.0 as f64)`). A fix probably
      means typing a literal from its `as f64` / `f64` context, the way
      integer literals already get `as i64`.

- [ ] **P0: pre-existing test failures at HEAD `84d14e7`.**
      `file_read_line`'s codegen references `@fgetc` without declaring it
      ("internal compiler error: malformed LLVM IR ... undefined global
      `@fgetc`"). Five tests fail, all on that root cause:
      `frontend_file_io` (`codegen_file_read_line_uses_fgetc_not_getchar`,
      `runtime_file_read_line_end_to_end`,
      `..._truncates_oversized_line_end_to_end`,
      `..._without_trailing_newline_end_to_end`) and
      `frontend_bughunt_transient_rc_release`
      (`runtime_file_and_env_builtins_with_fresh_str_arguments_end_to_end`).
      Found 2026-10-22 during the HavokOS M1 full-suite run and confirmed
      to fail identically with that round's changes stashed. Not
      investigated further. The other 2089 tests pass. Same 5 still
      failing on 2026-10-23 after the M2 compiler fix (2093 others pass),
      and again after the M3 `src/modules.rs` fix (2097 others pass,
      including M3's 4 new tests), and after M4's compiler changes (2111
      others pass, including M4's 14 new tests in `frontend_math_f64.rs`
      and `frontend_fs.rs`).

## Previous focus: porting NoBASIC to Star

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
- 2026-10-22: Started the HavokOS port (new "Current focus" section above;
  the NoBASIC items are now "Previous focus" and stay open). HavokOS P0 #1
  (M1, LPC front end) is done. See its entry above and
  `projects/havokos/NOTES.md`, which also covers:
  - the Star capability probes behind the design: `List` copy-on-write
    value semantics, `mut` free-function params being copies,
    O(n) `str` indexing, and no server sockets;
  - the two deliberate deviations from the reference;
  - the Star compiler `print`/`println` format-string bug found and fixed
    (`tests/frontend_print_percent.rs`).
  Filed two Star compiler issues as HavokOS P2 #1/#2 rather than fixing
  them in this round.
- 2026-10-23: HavokOS P0 #2 (M2, parser) is done. See its entry above and
  `projects/havokos/NOTES.md` ("2026-10-23: M2 parser" and Star compiler
  bug #4), which also covers:
  - the canonical AST dump format and why the Star side hand-sorts keys
    (Star has no ordering on `str`);
  - the reference's Pike-evaluation-order line numbers this port keeps
    (a `for` init expression reports the line of its `;`);
  - the conditional spill-slot release bug found and fixed
    (`tests/frontend_spill_slot_conditional_release.rs`; each half of the
    fix has a test that fails without it).
  The `star` on `PATH` here is a stale Sep 8 debug build, so the HavokOS
  tools are built with `target/release/star.exe`.
- 2026-10-23: HavokOS P0 #3 (M3, bytecode compiler + VM core) is done. See
  its entry above and `projects/havokos/NOTES.md` ("2026-10-23: M3
  compiler + VM core", deviations #3-#6, Star compiler bug #5), which also
  covers:
  - why LPC calls push frames on one interpreter loop instead of
    recursing in Star, and how errors unwind without exceptions;
  - the closure design: captured locals are boxed into cells, found by
    compiling a capturing function twice;
  - the three verification layers: the reference's case table, 92 edge
    cases recorded from the live driver, and a full-mudlib compile sweep
    comparing inheritance tables;
  - the `extern "C"` diamond-import bug found and fixed
    (`tests/frontend_extern_diamond_import.rs`).
  The editor's language server keeps `target/debug/star.exe` locked on
  this machine, so this round ran the Star test suite with
  `CARGO_TARGET_DIR=target/alt`.
- 2026-10-23: HavokOS P1 #1 (M4, efuns) is done. See its entry above and
  `projects/havokos/NOTES.md` ("2026-10-23: M4 efuns", constraints #9-#13,
  deviations #7-#9, Star compiler bug #6), which also covers:
  - how Pike's sprintf/sscanf rules were pinned down (probes against the
    live interpreter, then frozen as fixture cases);
  - why floats are formatted from their exact decimal expansion
    (`numfmt.star`), and why string building goes through `buf.star`
    (`x = f(x)` on a `Bytes` copies the whole buffer every call);
  - the new Star compiler builtins for files and local time
    (`src/codegen/fs.rs`), and the `f64` math builtin fix
    (`tests/frontend_math_f64.rs`);
  - running real Dead Souls 3.9 simul_efuns on both drivers (`-ds`).
  Filed the single-precision float literal issue as HavokOS P2 #3. Known
  slow spot left for M5: `a += ({ x })` in a long loop.
