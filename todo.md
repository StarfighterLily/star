# Star Compiler — Next Steps

## Immediate — status as of this pass

11 of the 14 items below are **done**, each with a regression test (type-level
tests in `tests/frontend.rs`, plus a dedicated `examples/*.star` program and
an end-to-end runtime test for anything only observable by actually running a
compiled binary). 3 items are **deferred** — see "Deferred" below for why.

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

### Bonus fix found while testing #8

Printing a `bool` via an f-string (`print(f"{a and b}")`) previously hit
`emit_print_like`'s `_ => "%p"` fallback — formatting a bare `i1` as a
pointer is undefined behavior. `Ty::Bool` now formats as `%s` against a
selected `"true"`/`"false"` string constant (`Codegen::emit_bool_str`).

## Deferred (not attempted this pass)

These three needed a larger, riskier redesign than "fix the bug in place,"
so rather than ship a shallow/unsafe partial fix under time pressure they're
left for a dedicated pass:

- **Give `par`/`swarm` a real persistent thread pool (§3.5).** Needs an
  actual lifetime-managed global worker-thread pool with a work queue and
  synchronization primitives (semaphores/condition variables) built in raw
  LLVM IR — a real concurrency primitive that's hard to get right (deadlocks,
  lost wakeups) without iterative runtime debugging, and a correctness bug
  here is worse than the current (correct, just slow) per-call
  `CreateThread`/`WaitForSingleObject` cost.
- **Fix the two unbounded leaks in string `concat` and closure environments
  (§3.6).** Genuinely fixing this needs an ownership/lifetime or
  reference-counting story for heap-backed `Str`/`Closure` values, not a
  local patch. The one "free" idea (route the allocation through the frame
  bump allocator when created inside a `frame:` block) is actively unsafe:
  today a `Str`/closure escaping a `frame:` block is safe (its own storage
  is genuinely heap-permanent), and frame-backing it would turn that into a
  dangling-pointer bug the escape analysis doesn't track for `Str`/`Closure`
  values at all — trading a leak for a segfault. Needs a deliberate design
  decision, not a quick patch.
- **Route `Vec2`/`Vec3` through the same SSA/vector-register path `Vec4`
  already uses (§4.3).** `Vec2`/`Vec3` are lowered to plain `{ float, float
  [, float] }` aggregates throughout `src/codegen/vector_math.rs`, and a good
  chunk of the existing test suite (`codegen_vec3_add_uses_extractvalue_insertvalue`,
  `codegen_vec2_ctor_uses_anonymous_struct`, `codegen_vec2_swizzle_write_uses_gep_store`,
  ...) explicitly pins that struct-based codegen shape. Switching to
  `<2 x float>`/`<3 x float>` is a coordinated rewrite across construction,
  arithmetic, swizzle read/write, `type_size`/frame allocation, and the
  matching test updates — a real redesign, not a bug fix.

## Also discovered, not tracked as an "Immediate" item

While verifying #8's runtime test, found that a comment as the very first
line of an indented block (e.g. right after `fn main():`) breaks indentation
tracking in the lexer (`error: expected an indented block, found end of
line`). Pre-existing, unrelated to anything above — worth a follow-up lexer
fix (`Lexer::handle_line_start`'s comment-only-line handling likely needs to
not treat that as "no indentation seen yet").

Similarly, `let` bound to a lambda literal with a *block* body, followed by
another statement at the same indentation level as the `let`, fails to parse
(`error: expected end of line, found an integer literal`) — reproduced with
`fn t() -> i32:\n    let c = fn() -> i32:\n        let y = 1\n        y\n    0\n`.
Also pre-existing and unrelated; likely a `parse_block`/`Stmt::Let`
line-end-expectation interaction worth a follow-up.
