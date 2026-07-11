# Star Compiler — Next Steps

## Immediate

Last actions:
All 18 items below are **done**, each with a regression test (type-level
tests in `tests/frontend.rs`, plus a dedicated `examples/*.star` program and
an end-to-end runtime test for anything only observable by actually running a
compiled binary).

1. **DONE — Bounds-check the frame bump buffer (§3.1).** `emit_frame_alloc`
   (`src/codegen/stmt.rs`) now compares the bump pointer against
   `FRAME_BUF_SIZE` before advancing `@frame.off`; an over-capacity `frame:`
   block aborts the process with a diagnostic message (`@exit(1)`) instead of
   segfaulting or corrupting adjacent global state. See
   `examples/frame_overflow.star` /
   `runtime_frame_overflow_aborts_loudly_instead_of_segfaulting`.
2. **DONE — Close the closure/`self`-pointer escape hole in frame analysis
   (§3.1).** `frame_analysis.rs`'s `frame_escape_source` now treats a method
   call returning a `Closure` type, on a frame-local receiver, as an escape
   source (the receiver's `self` pointer is captured *by pointer*, not by
   value — see `Codegen::captured_value_llvm_ty`'s doc comment). See
   `rejects_closure_capturing_frame_local_self_escaping_via_return`.
3. **DONE — Null/liveness-check `GenRef` dereference against a never-spawned
   slot (§3.3).** `emit_genref_index` (`src/codegen/arena.rs`) now requires
   the live generation to be *odd* (the parity that encodes liveness), not
   just equal to the stored generation — closing the hole where a
   never-spawned slot's generation (`0`) was indistinguishable from a
   freshly-created `GenRef`'s own captured generation. See
   `examples/genref_never_spawned.star` /
   `runtime_genref_never_spawned_falls_back_to_zero_not_segfault`.
4. **DONE — Make the `par`/`swarm` `spawn`/`despawn`/`frame` ban transitive
   through function calls (§3.5).** `Checker::compute_unsafe_par_fns`
   (`src/types/mod.rs`) precomputes, from the raw AST and via fixed-point
   propagation over the whole call graph, every function/method that
   directly or transitively spawns/despawns/opens a `frame:` block;
   `par_analysis::walk_par_expr` rejects any call (free-function or method)
   to one of them. See `rejects_spawn_hidden_behind_helper_function_call_inside_par`,
   `rejects_spawn_hidden_two_calls_deep_inside_par`,
   `rejects_frame_hidden_behind_helper_function_call_inside_par`.
5. **DONE — Fix `main`'s exit code (§0).** `main` always lowers to
   `i32 @main(...)` regardless of its declared return type, with an implicit
   `ret i32 0` on fallthrough and on a bare `return` (the checker separately
   rejects a `main` explicitly declared to return anything other than
   `i32`). Every example in `examples/` now exits `0`. See
   `runtime_main_exit_code_is_zero_not_garbage`,
   `codegen_main_lowers_to_i32_with_implicit_ret_zero`,
   `codegen_bare_return_inside_main_returns_i32_zero`.
6. **DONE — Close the `let`/`return`/`Assign`/call-argument type-checking
   holes (§1.1–1.4).** `let` annotations, assignments (including compound
   assignment), both explicit and *implicit trailing-expression* `return`s,
   and ordinary free-function/method call arguments (count and per-argument
   type) are now all checked against their declared/inferred types. See the
   `rejects_let_annotation_mismatched_with_value_type`,
   `rejects_assign_value_type_mismatched_with_target`,
   `rejects_explicit_return_type_mismatch`,
   `rejects_implicit_trailing_return_type_mismatch`,
   `rejects_bare_return_in_function_with_declared_return_type`,
   `rejects_call_with_mismatched_argument_types`,
   `rejects_call_with_wrong_argument_count`,
   `rejects_method_call_with_mismatched_argument_types` tests (and their
   `accepts_*` counterparts, so legitimate code isn't newly rejected).
7. **DONE — Pass `-O2` by default in `cmd_build`, add a `--release`/`-O`
   toggle (§4.1).** `star build` now passes `-O2` to clang by default;
   `-O <0-3>`/`--opt-level` picks an explicit level (clamped to `0..=3`), and
   `--release` is shorthand for `-O3`. See the `opt_flag_*` unit tests in
   `src/main.rs`.
8. **DONE — Add `&&`/`||`/`and`/`or`/`not` (§2.1).** Both symbolic and word
   spellings lex/parse to the same `BinOp::And`/`BinOp::Or`/`UnOp::Not`
   (`not`/`!` already shared `UnOp::Not`); codegen short-circuits via
   branches (the right-hand side is only evaluated when it can actually
   change the result), not eager double-evaluation. See
   `examples/logic_ops.star` / `runtime_logic_ops_end_to_end`,
   `codegen_logical_and_short_circuits_via_branch`.
9. **DONE — Make arena-capacity overflow loud (§3.2).** A spawn past
   `ARENA_CAPACITY` still drops silently (a fixed backing store can't
   realloc/move while `par`/`swarm` workers may be reading it concurrently —
   that part is a deliberate, correct design choice, not a bug), but now
   prints a runtime warning naming the offending arena. See
   `examples/arena_capacity.star` /
   `runtime_arena_overflow_warns_instead_of_silently_dropping`.
10. **DONE — Expose `dot`/`length`/`lerp`/`clamp`/RNG as builtins (§4.6,
    §5).** `dot`/`length` (Vec2/Vec3/Vec4), `lerp` (f32 and
    Vec2/Vec3/Vec4), `clamp` (i32/f32), and a seeded xorshift32
    `rand`/`rand_range`/`rand_seed` are now callable builtins
    (`src/codegen/vector_math.rs`). See `examples/math_builtins.star` /
    `runtime_math_builtins_end_to_end`.
11. **DONE — Rewrite early `return` inside `sequence` bodies (§3.7).** A
    bare `return` before a sequence's next `yield` now desugars to
    `return false` (the same "fully done" value the final segment's own
    implicit fallthrough already returns), producing valid `ret i1 false`
    instead of an invalid `ret void` inside the synthesized
    `bool`-returning `resume`. See `examples/sequence_early_return.star` /
    `runtime_sequence_early_return_end_to_end`.
12. **DONE — Give `par`/`swarm` a real persistent thread pool (§3.5).**
    `Codegen::emit_par_stmt` (`src/codegen/arena.rs`) now hands its
    per-callsite chunking function off to `par_pool::emit_par_dispatch`
    (`src/codegen/par_pool.rs`, new) instead of issuing a fresh
    `CreateThread`/`WaitForSingleObject`/`CloseHandle` cycle on every
    `par`/`swarm` execution. Four persistent OS worker threads are created
    once (lazily, `@par.pool.ensure_init`) and reused for the process's
    lifetime; each has its own dedicated mailbox (`job_fn`/`job_arg` slot
    plus a `start`/`done` `CreateSemaphoreA` pair) rather than pulling from
    a shared queue, since every dispatch always fans out to exactly 4
    chunks. A `par`/`swarm` nested inside another one (allowed by the
    checker's disjointness proof) can't dispatch to the same fixed pool it's
    already running on, so it falls back to a serial, full-range pass
    guarded by a manually-reentrant lock (`serial_lock`/`serial_owner`) —
    a bare inline fallback would race, since every concurrently-running
    outer worker hits the nested statement at once. See
    `examples/par_pool_ticks.star` /
    `runtime_par_pool_ticks_persists_across_cycles` (proves the pool
    survives repeated dispatch/join cycles), `examples/par_nested.star` /
    `runtime_par_nested_serial_fallback_is_race_free` (proves the nested
    fallback is race-free under real concurrent execution — checked
    deterministic across 15 manual runs), and the
    `codegen_par_pool_reused_across_multiple_statements`,
    `codegen_par_reentrant_dispatch_uses_serial_lock`,
    `codegen_par_pool_globals_absent_without_par` codegen tests.

13. **DONE — Fix the two unbounded leaks in string `concat` and closure
    environments (§3.6).** Both now allocate through a shared
    reference-counting runtime (`Codegen::emit_rc_runtime`, `src/codegen/mod.rs`):
    a 16-byte `[i64 refcount][i8* release_fn]` header ahead of every
    `star_rc_alloc`'d block, with `star_rc_retain`/`star_rc_release`
    incrementing/decrementing it and freeing (calling the optional nested
    `release_fn` first, for a closure env that itself captured RC-bearing
    values) at zero. A string literal's global constant is wrapped in the
    same header shape with the refcount set to a reserved `-1` "immortal"
    sentinel both retain/release skip, so it's never actually freed despite
    flowing through the same paths a heap-allocated `str` does. One generic
    recursive walker (`src/codegen/rc.rs`, new) retains on every read of an
    existing owned slot (`Ident`/`Field`/`ListIndex`/`GenRefIndex`) and
    releases at scope exit/`return`/`break`/`continue`/reassignment,
    recursing through struct fields and `List` elements so a `str`/closure
    nested inside either is tracked too — this composes automatically
    through every duplication point (`let`, a call argument, a struct
    field, ...) without needing a retain at each one individually, since
    they're all just `emit_expr` evaluating some expression. Arena
    `spawn`/`despawn`/respawn hook into the same walker. See
    `examples/rc_strings.star` / `runtime_rc_strings_end_to_end`,
    `examples/rc_closures.star` / `runtime_rc_closures_end_to_end`, and
    `examples/rc_stress.star` / `runtime_rc_stress_memory_stays_bounded`
    (the direct empirical proof: 10,000,000 iterations sampled for Working
    Set growth while running, not just IR inspection), plus the
    `codegen_concat_uses_rc_alloc_not_raw_malloc`,
    `codegen_closure_capturing_str_emits_release_env_thunk`,
    `codegen_despawn_releases_arena_slot_str_field`, and related
    `codegen_*`/`runtime_*` tests in `tests/frontend.rs`.

    Three bugs caught while implementing this (all fixed, all covered by a
    regression test): a method's `self` parameter was being tracked/released
    as if it were an owned value rather than the borrowed pointer it
    actually is, corrupting the caller's stack (`codegen_method_self_param_is_not_released_at_scope_exit`);
    a `Str` value needs *two* loads from its storage to reach the real
    backing pointer, not one (`Codegen::emit_raw_str_ptr`'s own
    documented convention), which the retain/release walker initially
    missed; and reading a `Str`/closure purely to hand it to a transient,
    non-owning consumer (`len`/`concat`'s internal `strlen`/`strcpy`,
    `printf` formatting, calling a closure through a bare variable) was
    retaining a reference that nothing ever released, leaking exactly one
    reference per such use — fixed by releasing it right back in
    `emit_raw_str_ptr`, `emit_print_like`, and `emit_closure_call`.

14. **DONE — Route `Vec2`/`Vec3` through the same SSA/vector-register path
    `Vec4` already uses (§4.3).** `llvm_ty` (`src/codegen/mod.rs`) now lowers
    `Vec2`/`Vec3` to native `<2 x float>`/`<3 x float>` instead of anonymous
    `{ float, float [, float] }` structs; `extract_component`/`insert_component`
    dispatch on `Ty::is_vec()` (all three arities) rather than singling out
    `Vec4`, which alone made `emit_lerp`'s already-arity-generic implementation
    correct for Vec2/Vec3 with zero changes to that function. The former
    struct-shaped code paths were deleted outright rather than kept
    alongside the vector path: `emit_vec_struct_binop`/`emit_vec4_binop`
    merged into one `emit_vec_binop` (a single native `fadd`/`fsub`/`fmul`/
    `fdiv` per arity), `emit_vec_scalar_binop`'s two branches collapsed into
    one arity-generic broadcast-then-multiply, `emit_dot4`/`emit_dot_bare`'s
    struct arm merged into one `emit_dot_vec`, `StructLit`'s Vec2/Vec3
    `alloca`+GEP+store+load arm merged into Vec4's pure-SSA
    `insertelement`-chain arm, and `emit_swizzle_read`/`emit_swizzle_write`'s
    `Ty::Vec4`-only guards widened to `is_vec()` (the now-unreachable
    `extractvalue`/`insertvalue`/GEP-store fallback branches replaced with
    `unreachable!()` rather than silently deleted). Single-lane swizzle
    writes on Vec2/Vec3 now go through the same load-whole-vector/
    `insertelement`/store-whole-vector shape Vec4 already used, rather than
    a separate direct-GEP fast path — a deliberate consistency call, since
    `star build`'s default `-O2` erases the extra-instruction cost anyway.
    `arena.rs`/`list.rs`/`closure.rs`/`par_analysis.rs`/`frame_analysis.rs`
    needed no changes at all, confirmed representation-agnostic via
    `llvm_ty`/`type_size` alone. See the rewritten
    `codegen_vec3_add_uses_vector_fadd`,
    `codegen_vec2_swizzle_write_uses_insertelement_store`,
    `codegen_vec2_ctor_uses_insertelement_no_alloca`,
    `codegen_compound_assign_vec3_uses_vector_fadd` tests (former
    struct-shape pins), the new arity-2/3 counterparts of every existing
    Vec4 codegen test, `codegen_vec2_dot_uses_vector_fmul_and_extractelement`/
    `codegen_vec2_length_uses_sqrt`/`codegen_vec2_lerp_uses_extractelement_insertelement`
    (dot/length/lerp specifically at arity 2, untested by the Vec4-only
    suite), and the new
    `codegen_struct_field_of_vec2_type_uses_native_vector`/
    `codegen_list_of_vec2_uses_native_vector_element`/
    `codegen_arena_of_vec3_uses_native_vector`/
    `codegen_closure_capturing_vec2_local_uses_native_vector` tests locking
    in the representation-agnostic paths. `examples/vecmath.star`,
    `examples/math_builtins.star`, and `examples/player.star` (the three
    examples using Vec2/Vec3) were all rebuilt through the new codegen and
    their stdout verified byte-identical to the pre-redesign output before
    refreshing the checked-in `.ll`/`.exe` artifacts.

### Bonus fix found while working on #12

`par_analysis.rs`'s nested-`Stmt::Par` disjointness check never added the
nested loop's own variable to its locals set before recursing, so *any*
nested `par`/`swarm` whose body mutated its own loop variable's fields (the
only thing a `par` body is ever meaningfully used for) was unconditionally
rejected as an unproven capture write. One-line fix in
`Checker::walk_par_stmt`'s `TypedStmt::Par` arm.

### Bonus fix found while testing #8

Printing a `bool` via an f-string (`print(f"{a and b}")`) previously hit
`emit_print_like`'s `_ => "%p"` fallback — formatting a bare `i1` as a
pointer is undefined behavior. `Ty::Bool` now formats as `%s` against a
selected `"true"`/`"false"` string constant (`Codegen::emit_bool_str`).

All four items below (found as pre-existing, unrelated bugs while doing
earlier work) are now **done**, each with a regression test.

15. **DONE — A comment as the very first line of an indented block broke
    lexer indentation tracking.** `Lexer::handle_line_start` (`src/lexer.rs`)
    measured a blank/comment-only line's indentation, discarded it, and
    returned *without* consuming the line's own trailing `\n` — left for
    `scan_line_content` to turn into a spurious `Newline` token, which broke
    `parse_block`'s bare `expect(Newline); expect(Indent)` whenever a
    block's first line was a comment (`error: expected an indented block,
    found end of line`). Fixed by turning the blank/comment skip into a loop
    that consumes each such line (including its `\n`) and re-checks the next
    physical line before falling through to measure real indentation, so
    `scan_line_content` is still called exactly once per real line. See
    `ignores_blank_and_comment_lines`, `parses_comment_as_first_line_of_block`,
    `parses_consecutive_comments_as_first_lines_of_block`.
16. **DONE — `let` bound to a block-bodied lambda, followed by a sibling
    statement at the same indentation, failed to parse.** A value
    expression ending in an indented block (a block-bodied lambda, an
    `if`-expression, a `match`-expression) already consumes, via its own
    nested `parse_block`, the `Newline`/`Dedent` that re-syncs with the
    *enclosing* block — the same one `parse_let` (and the generic
    bare-expression/assign arm) then tried to consume again via
    `expect_line_end()`, choking on the next statement's first token instead
    (`error: expected end of line, found an integer literal`). Fixed
    generically rather than per-expression-kind: a new `Parser::
    block_just_closed` flag (`src/parser/mod.rs`) is set right after
    `parse_block`/`parse_match` consume their closing `Dedent`, cleared at
    the top of every `advance()`, and accepted by `expect_line_end()` as an
    already-satisfied terminator. See
    `parses_let_bound_block_lambda_followed_by_sibling_statement`,
    `parses_let_bound_if_expr_followed_by_sibling_statement`.
17. **DONE — A function returning a freshly-constructed `str` dangled.**
    Every `Str`-typed value's `emit_expr` result used to be a pointer to a
    "box" (an `alloca i8*` wrapper) rather than the raw `i8*` bytes pointer
    itself; returning a value built fresh in the current function (a
    literal, a `concat` result) returned that box's address, an `alloca` in
    the current function's own dead stack frame. Fixed by eliminating the
    box indirection entirely rather than heap-allocating it (which would
    have needed its own cascading refcount/release-fn machinery to avoid
    leaking one box per `Str` production, risking a regression against
    `runtime_rc_stress_memory_stays_bounded`): a `Str` value is now just the
    raw `i8*` pointer directly, matching `Int`/`Float`/`Bool`. Touched
    `TypedExpr::Str` (`src/codegen/expr.rs`), `emit_raw_str_ptr`/
    `emit_str_concat`/`emit_print_like` (`src/codegen/builtins.rs`, and
    removed `box_str_ptr` outright), and `emit_rc_walk`'s `Str` arm
    (`src/codegen/rc.rs`, now one load instead of two) — retain/release
    already targeted the real bytes pointer, so this changes where that
    pointer comes from, not what gets retained/released. See
    `examples/str_fixes.star` /
    `codegen_fn_returning_fresh_str_does_not_box_on_stack`,
    `runtime_str_return_fresh_value_end_to_end`.
18. **DONE — `println`/`print` double-tagged a non-`Ident`/`Field`
    argument.** `emit_print_like`'s non-f-string branch used `emit_expr`'s
    result directly as an untagged register, which works for `Ident`/
    `Field`/`Str`-literal arguments but broke for a `ListIndex` or
    closure-call result (both return a *tagged* register), producing
    malformed IR (`load i8*, i8** i8* %reg`) that clang rejected. Every
    existing example had routed list/call results through an f-string
    interpolation instead, so this path was never exercised. Fixed by
    calling `Codegen::untag` on the argument before use, matching the
    f-string branch's own handling (and, with item 17's box removed, the
    branch no longer needs a `load` at all). See `examples/str_fixes.star` /
    `codegen_println_of_list_index_does_not_double_tag`,
    `runtime_println_of_list_index_and_closure_call_end_to_end`.

## Full lexer/parser/checker/codegen audit (item 19)

**DONE.** A dedicated pass over the whole pipeline (not triggered by a
specific bug report) turned up nine issues, each fixed with a regression
test in `tests/frontend.rs`:

- **RC retain/release raced under `par`/`swarm` (correctness, codegen).**
  `star_rc_retain`/`star_rc_release` (`src/codegen/mod.rs`) did a plain
  (non-atomic) load/add-or-sub/store on the shared 16-byte refcount header.
  `par`/`swarm`'s disjointness proof only restricts *writes* to captured
  state (`crate::types::par_analysis`), so a `Str`/closure merely *read*
  inside a worker body still retains/releases the same header from up to 4
  concurrent OS threads with no synchronization — a lost-update race that
  can free a still-live block (use-after-free) or leak it. Fixed with
  `load atomic ... seq_cst` and `atomicrmw add`/`atomicrmw sub` (the latter
  compared against its *pre*-decrement return value, since `atomicrmw sub`
  doesn't hand back the post-decrement result the old code's local `%rc1`
  did). See `examples/par_rc_race.star` /
  `runtime_par_rc_race_reads_captured_str_without_corruption`.
- **Two lexer panics on non-ASCII bytes outside a string/comment
  (correctness, robustness).** `scan_operator`'s fallback arm and
  `scan_escape` both advanced by exactly one raw byte on an unrecognized
  byte, splitting a multi-byte UTF-8 codepoint across two tokens and
  producing a `Span` that isn't a valid `str` slice boundary — panicking
  later in `diagnostics::line_text` (or, for the escape case, in
  `current_char()` while rescanning). Both now decode the full codepoint via
  `current_char`/`current_char_len` before advancing. See
  `rejects_non_ascii_source_does_not_panic`,
  `rejects_non_ascii_escape_does_not_panic`.
- **Unrecognized escape sequences were silently accepted (correctness).**
  `"bad\qescape"` silently became `"badqescape"` with zero diagnostics
  (`scan_escape`'s catch-all just returned the raw byte). Now a clean lexer
  error. See `rejects_unknown_escape_sequence`.
- **Integer literals outside `i32`'s range silently corrupted
  (correctness).** `scan_number` parsed straight into `i64` and defaulted
  any parse failure to `0`; since `Ty::Int` is a 32-bit `i32` everywhere in
  codegen, anything in `(i32::MAX, i64::MAX]` silently reinterpreted as a
  negative `i32` and anything past `i64::MAX` silently became `0`, both with
  no diagnostic. Now a clean lexer error, with a magnitude special-case so
  `-2147483648` (`i32::MIN`, whose positive magnitude alone exceeds
  `i32::MAX`) still parses. See `rejects_oversized_integer_literal`,
  `accepts_i32_min_literal`.
- **A real `<` comparison between two capitalized identifiers misparsed
  (correctness, parser).** `if Foo < Bar:` eagerly committed to a turbofish
  parse on seeing a capitalized identifier followed by `<`, cascading into
  unrelated parse errors when it turned out to just be a comparison. Fixed
  with `Parser::try_parse_type_args`, which speculatively parses the
  turbofish and backtracks (cursor and diagnostics both) unless it's
  immediately followed by `(` or `::`, the only two continuations a real
  turbofish can have. See `accepts_comparison_between_capitalized_identifiers`,
  `accepts_turbofish_generic_constructions_after_backtracking_fix`.
- **`GenRef` construction silently defaulted malformed input instead of
  erroring (correctness, parser).** `GenRef(value)` with no type argument
  fell through to construct a nonexistent `GenRef` struct literal;
  `GenRef<T>()`/`GenRef<>(0)` (missing value/type argument) silently
  synthesized a placeholder `Int(0)`/`Type::Named("unknown")` instead of
  reporting the mistake. All three are now clean parse errors. See
  `rejects_genref_without_type_args`, `rejects_genref_missing_value_arg`,
  `rejects_genref_missing_type_arg`.
- **A struct recursive by value had no cycle detection (correctness,
  checker).** `struct Node: next: Node` (directly, or transitively through
  a by-value generic wrapper like `struct Box<T>: value: T`) has no finite
  size; left unchecked this either stack-overflowed the compiler in
  `Codegen::type_size`'s unbounded recursion or reached `clang` as
  unrepresentable LLVM IR. `Checker::check_no_recursive_structs`
  (`src/types/mod.rs`) now DFS-walks every struct's by-value fields (a
  `GenRef<T>`/`List<T>`/`Closure`/primitive field is a fixed-size handle,
  not an inclusion edge, so `GenRef<Self>` — the language's actual
  self-reference pattern — is unaffected) and reports any cycle. See
  `rejects_directly_recursive_struct`,
  `rejects_struct_recursive_through_generic_wrapper`,
  `accepts_struct_with_genref_self_reference`.
- **`print`/`println`'s non-f-string form accepted non-`str` arguments
  (correctness, checker).** This form passes its argument straight through
  as `printf`'s raw format string (`Codegen::emit_print_like`), never doing
  `%s` substitution; `print(5)` type-checked cleanly and only failed later
  at the `clang` step with a confusing, mislocated backend error (a raw
  `i32` reaching an `i8*` parameter). Now a clean checker error pointing at
  the call. See `rejects_print_of_non_str_argument`.
- **`diagnostics::line_text` trusted its `Span` offset to be a char
  boundary (robustness).** A defensive fix alongside the lexer panics above:
  even though every `Span` should already land on a boundary, `line_text`
  now clamps backward to the nearest one before slicing, so a future
  span-producing bug degrades to a slightly-off error location instead of a
  panic.

## Item 20: integer division/modulo by zero trapped the process

**DONE.** `emit_scalar_binop` (`src/codegen/vector_math.rs`) emitted a bare
`sdiv i32`/`srem i32` for `/`/`%` on `i32` operands. Both are undefined
behavior in LLVM on a zero divisor, *and* on the one non-zero case that still
overflows, `i32::MIN / -1` (its true result, `2147483648`, doesn't fit in
`i32`) — on x86 both trap the whole process with a hardware `#DE` exception
(SIGFPE) and no diagnostic whatsoever, strictly worse than the silent-corruption
bugs item 19 fixed (at least those produced a wrong value instead of killing
the process). `f32` division/modulo needed no change: IEEE 754 defines
`x / 0.0` as `inf`/`nan`/no trap, so only the integer path was affected.
Fixed with a new `Codegen::emit_checked_int_div`, following
`emit_frame_alloc`'s check-then-abort-with-a-message shape: a runtime branch
compares the divisor against `0` and the `(dividend == i32::MIN) & (divisor
== -1)` overflow case, aborting via `puts`+`@exit(1)` on either before the
`sdiv`/`srem` would otherwise execute. See `examples/int_div_by_zero.star` /
`runtime_int_division_by_zero_aborts_loudly_instead_of_trapping`,
`runtime_int_modulo_by_zero_aborts_loudly_instead_of_trapping`,
`runtime_int_min_divided_by_negative_one_aborts_loudly_instead_of_trapping`,
`codegen_ordinary_int_division_still_computes_correct_values` (the
not-just-crashing-on-the-happy-path regression guard),
`codegen_int_division_includes_zero_and_overflow_guard`.