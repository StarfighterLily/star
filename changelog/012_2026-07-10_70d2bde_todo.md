# Star Compiler — Next Steps

## Immediate

a comment as the very first line of an indented block (e.g. right after `fn main():`) breaks indentation
tracking in the lexer (`error: expected an indented block, found end of line`).

Similarly, `let` bound to a lambda literal with a *block* body, followed by
another statement at the same indentation level as the `let`, fails to parse
(`error: expected end of line, found an integer literal`) — reproduced with
`fn t() -> i32:\n    let c = fn() -> i32:\n        let y = 1\n        y\n    0\n`.
Also pre-existing and unrelated; likely a `parse_block`/`Stmt::Let`
line-end-expectation interaction worth a follow-up.

While implementing #13 below, found two more pre-existing, unrelated bugs
(confirmed present in the last commit before that work, not introduced by
it) in how a `Str` value's "box" (the `alloca i8*` wrapper every `Str`
expression's `emit_expr` result points to — see `Codegen::emit_raw_str_ptr`'s
doc comment) is represented — both are dangling-pointer bugs, not leaks, so
orthogonal to #13's fix, and out of scope for it:
- A function that returns a **freshly constructed** `str` (e.g. `fn f() ->
  str: concat(a, b)`, or even a bare string literal) returns the address of
  an `alloca` *inside that function's own stack frame* — valid until the
  function returns, dangling immediately after. Returning an *existing*
  value (a parameter, a field read) is fine (the box lives in the caller's
  frame instead); it's specifically returning something built fresh inside
  the callee that's broken. `Codegen::box_str_ptr`/`TypedExpr::Str`'s
  literal codegen would need the outer box itself heap-allocated (not just
  the string bytes) to fix this — a representation change, not a local patch.
- `println`/`print` (and by extension any bare, non-f-string argument) only
  works correctly when passed a plain `Ident`/`Field` expression — passing
  anything whose `emit_expr` result is *tagged* (e.g. `println(list[i])` or
  `println(closure())`) produces malformed IR (`load i8*, i8** i8* %reg`,
  a double-tagged operand) that clang rejects. Every existing example
  routes list/call results through an f-string interpolation instead
  (`println(f"{list[i]}")`), which takes a different, working code path —
  so this was never exercised. Likely needs `emit_print_like`'s non-f-string
  branch to call `Codegen::untag` before using the value, matching the
  f-string branch's own handling.

Last actions:
All 14 items below are **done**, each with a regression test (type-level
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