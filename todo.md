# Star Compiler — Next Steps
1. Complete Priority Roadmap

## Priority Roadmap (derived from current_status.md suitability analysis)

Ordered biggest win → smallest, where "win" = how much it unblocks writing useful
programs relative to implementation effort.

### 4. Graphics / audio / input bindings
Core to the "game language" pitch but currently 100% aspirational
(`draw_sprite`, `flash_screen`, `wait` are documented but not implemented).
Highest effort of the "unlock capability" items — best sequenced after FFI (#1)
so it's a binding to SDL/similar rather than a from-scratch renderer.
- Window creation + framebuffer/pixel-blit as the minimal viable slice.
- Input polling (keyboard/mouse/gamepad).
- Audio playback (defer to last — least blocking for "useful program" broadly).

### 5. Module system: re-exports, search paths, manifest
Needed once any program grows past a few files. Current system only inlines one
relative-path file at a time with no transitive symbol visibility.
- Transitive re-export so `a` importing `b` importing `c` can reach `c`'s symbols.
- Search-path resolution instead of hand-written relative paths everywhere.
- Minimal package manifest (name, version, entry point) — defer a full package
  manager/registry until there's more than one real multi-file project to learn from.

### 6. Expand core standard library
The current 28 builtins cover almost no string/collection manipulation beyond
`List<T>`. Grow incrementally as real programs (see #8) expose actual gaps
rather than speculatively.
- String ops: split/join/trim/replace/contains/format beyond f-strings
- ~~A `Map`/`Dict` and `Set` type to complement `List<T>`~~ -- done:
  `Map<K,V>`/`Set<T>` landed (linear-scan lookup plus a generated
  structural-equality function per key/element type, not a hash table yet --
  see `docs/design.md`'s Type System plan and `examples/map_set.star`).
- ~~Tuples and fixed-size arrays~~ -- done: `(T, U, ...)` and `[T; N]` landed
  (both stored inline, no RC header/heap allocation of their own -- see
  `docs/design.md`'s Type System plan and `examples/tuples_arrays.star`).
- ~~Ring<T,N> (fixed-capacity ring buffer)~~ -- done: `Ring<T, N>` landed
  (stored inline like `Array`, no RC header/heap allocation/copy-on-write of
  its own, but mutable via `push`/`pop` like `List` -- `push` evicts the
  oldest element once full instead of growing/no-op'ing -- see
  `docs/design.md`'s Type System plan and `examples/ring.star`).
- ~~Table<T> (struct-of-arrays)~~ -- done: `Table<T>` landed (heap-backed,
  RC'd, copy-on-write like `List<T>`/`Map<K,V>`/`Set<T>` -- one growable
  column per field of the struct `T`, all growing/shrinking in lockstep --
  see `docs/design.md`'s Type System plan and `examples/table.star`). This
  closes out the "indie connective tissue" tier entirely.
- Fill out math builtins as needed (trig, log/exp, etc.).

### 7. Wire up reflection into an actual runtime feature
`@export`/`@tweakable` currently only emit descriptive metadata strings — there
is no hot-reload runtime or file watcher consuming them yet. Lower priority
since it's a productivity/tooling win, not a capability unlock: nothing is
*impossible* without it, just slower to iterate on.

### 8. Build one real, non-toy program in Star
Everything in `examples/` and `tests/` tops out around ~40 lines of
single-feature demos. FFI and file I/O are now done, which is enough to write
a small file-backed tool; dogfood the language on one program larger than a
toy — this will surface real gaps faster than speculative stdlib growth, and
is the best validation that the "useful programs today" bar has actually
been cleared.

## Last actions:
Feature round tackling `docs/design.md` §2, "Numeric widths and modes" -- the largest
remaining lift the Type System section had left, per the previous round's own closing
note. Added `i8`/`u8`/`i16`/`u16`/`u32`/`i64`/`u64`/`f64` alongside the original `i32`/
`f32`, plus `char` (a Unicode scalar) and a new `expr as Type` cast expression -- the
width/`char`/cast part of §2 is now **done**; `Wrapping<T>`/`Fixed<Bits,Frac>` (the two
explicit opt-in modes) are not, and are now the largest remaining lift in that section.
New tests in `tests/frontend.rs` (734 total, all green, 26 new this round -- parser-shape,
checker positive/negative, and `compile_and_run` runtime tests, the latter covering real
overflow-trap/div-by-zero aborts per width/signedness, not just happy-path arithmetic);
all 48 pre-existing examples still `star check` cleanly (the same pre-existing, unrelated
`examples/player.star` failure noted in every prior round -- `Vec3(0, 0, 0)`'s int
literals vs. its `f32` fields -- confirmed present on a clean `main` checkout, not a
regression), plus a new `examples/numeric_widths.star` (49 total).

Nine new `Ty` variants (`I8`/`U8`/`I16`/`U16`/`U32`/`I64`/`U64`/`F64`/`Char`) sit alongside
the original `Int`/`Float` rather than replacing them -- `Ty::Int`/`Ty::Float` keep
meaning `i32`/`f32` exactly as before, so every one of the 708 pre-existing tests still
passes unmodified. `i64`/`f64` used to be accepted spellings that silently *aliased*
`Ty::Int`/`Ty::Float` in `Checker::resolve_type` (Star's only two widths until now); they
resolve to the real, distinct `Ty::I64`/`Ty::F64` now -- confirmed via a grep of
`tests/frontend.rs` that no existing test relied on the old alias behavior before making
the change. `Ty::is_numeric()`/`Ty::int_shape() -> Option<(bit_width, is_signed)>` are two
new helper methods (mirroring the existing `is_vec()`/`vec_arity()` pattern) that let every
downstream numeric-generic pass (arithmetic type-checking, arithmetic codegen, FFI-scalar/
hashable-key whitelists) dispatch on "any numeric type"/"this type's concrete integer
shape" instead of a hardcoded `Ty::Int | Ty::Float` match, without a per-width match arm at
every call site.

Numeric promotion is deliberately *not* generalized to a lattice: `Checker::infer_binop_ty`
still special-cases exactly one implicit mixed-pair promotion (`Int`/`Float`, preserved
byte-for-byte from before this round -- `1 + 1.5 == 2.5`), and requires an exact type match
for every other numeric pair (`lhs_ty == rhs_ty`) -- `i8 + i64`, `u32 + f64`, even
`i32 + i64`, are all hard type-mismatch errors pointing at `as` as the fix, not a silent
widening. This was a deliberate design choice over implementing full C-style integer
promotion rules: simpler to specify, and it matches this compiler's existing "no
implicit narrowing either" stance (`let a: Foo = 42` was already rejected pre-this-round if
`Foo != i32`'s inferred type -- see §1.1's fix, referenced in `types/stmt.rs`). `char`
supports `==`/`!=`/`<`/`>`/`<=`/`>=` against another `char` (codepoint comparison) but no
arithmetic at all (mirrors Rust's own `char`, which isn't `Add`/`Sub`).

`expr as Type` (`Expr::Cast`/`TypedExpr::Cast`) is a genuinely new grammar production, not
a repurposing of existing machinery -- `TokenKind::As` previously only appeared in
`import "path.star" as alias`. `Parser::parse_cast` sits as its own precedence tier between
`parse_binary` and `parse_unary` (`x as i64 + 1` is `(x as i64) + 1`; `-x as i64` is
`(-x) as i64`; casts chain left-to-right: `x as i64 as f64`), mirroring Rust's own `as`
precedence. `Checker::infer_expr`'s `Expr::Cast` arm accepts any numeric-to-numeric or
numeric-to-`char` (either direction) pairing and rejects everything else (`"hi" as i32` is
a checker error, not a codegen-time surprise). `Codegen::emit_cast` dispatches on
`Ty::int_shape()`/`Ty::Float`/`Ty::F64` (treating `Ty::Char` as an unsigned 32-bit int for
this purpose) to the right LLVM conversion op: same-width int/`char` <-> int/`char` is a
bit-preserving relabel (no instruction emitted at all), a wider target `sext`s/`zext`s per
the *source*'s signedness, a narrower target `trunc`s, int/`char` <-> float goes through
`sitofp`/`uitofp`/`fptosi`/`fptoui` per whichever side is the integer's own signedness, and
`float` <-> `f64` goes through `fpext`/`fptrunc`. No runtime validation that an int-to-
`char` cast produced a valid Unicode codepoint -- this is Rust's infallible truncating `as`,
not a `Result`-returning fallible conversion (this compiler has no such path for anything).

Trap-on-overflow (this section's stated *default*, not an opt-in) is genuinely new
behavior, not just new-type plumbing: no add/sub/mul overflow guard existed anywhere in
this compiler before this round (confirmed by grep -- the only prior runtime trap was the
`i32` division guard's zero-divisor/`MIN / -1` check). `Codegen::emit_checked_sized_int_arith`
guards `+`/`-`/`*` on every explicit-width integer type via LLVM's
`llvm.{s,u}{add,sub,mul}.with.overflow.iN` intrinsics (declared unconditionally for every
`(width, signedness, op)` combination those types use, in `Codegen::emit_builtins`),
branching to the same "print a message, `exit(1)`" abort shape `emit_checked_int_div`
already established (factored into a shared `emit_abort_with_message` helper).
`Codegen::emit_checked_sized_int_div` generalizes the pre-existing `i32`-only division
guard the same way, parameterized by bit width and signedness (the signed `MIN / -1`
overflow check only applies to signed widths -- unsigned division has no equivalent trap).
**Deliberately excluded: `Ty::Int` (`i32`) itself keeps its original silent two's-complement
wraparound** -- retrofitting a trap onto the one type every pre-existing program already
depends on was judged out of scope for this round (a behavior change, not a new-type
addition), confirmed safe to *not* do by grepping `tests/frontend.rs` for any test relying
on `i32` overflow wraparound (none exist) and locked in by a new
`runtime_i32_add_overflow_still_wraps_silently_unlike_new_sized_int_types` regression test.
This asymmetry (new widths trap, `i32` doesn't) is exactly the gap `Wrapping<T>` is meant
to close once it lands: an explicit opt-in for silent wraparound on *any* width, including
`i32`, rather than `i32` being a permanent special case.

Every exhaustive match over `Ty`/`TypedExpr` this compiler has (`type_align`, `type_size`,
`llvm_ty`, `mangle_ty` x2, `zero_value`, `expr_ty`, `reflect_type_name`, `ty_to_type`,
`subst_expr`/`subst_type`, `frame_analysis`'s untracked-expression bucket, `par_analysis`'s
`walk_par_expr`) needed a parallel arm for the nine new `Ty` variants and/or the two new
`Expr`/`TypedExpr::Char`/`Cast` node kinds, found the same mechanical way the `Table<T>`
round found its call sites: `rustup run stable-x86_64-pc-windows-gnu cargo check`'s
non-exhaustive-match errors (this repo's only working toolchain in a plain shell here --
see the previous round's note on why `x86_64-pc-windows-gnu`, not the default msvc host).
`Checker::check_hashable_ty`/`Checker::is_ffi_scalar_ty` (both non-exhaustive `matches!`
whitelists, so the compiler doesn't force new arms) were extended by hand instead: every
new numeric width and `char` is structurally hashable (a `Map`/`Set` key) and FFI-scalar
(an `extern "C" fn` parameter/return type) for the same reasons `Ty::Int`/`Ty::Float`
already were. `crate::codegen::eq`'s `emit_eq_body` and `crate::codegen::builtins`'s
`emit_print_like` format-specifier match are two more non-exhaustive whitelists that don't
force a compile error but *would* silently misbehave (`Map<u8, V>` comparing every key as
"always equal"; `println(f"{x}")` on a `u64` printing a garbage address via the `%p`
fallback) if left un-audited -- both got explicit new arms (`%d`/`%u`/`%lld`/`%llu`/`%c`
per width/signedness, with `i8`/`i16`/`u8`/`u16` explicitly `sext`/`zext`ed to `i32` before
the `printf` varargs call, matching C's own default-argument-promotion rule the pre-existing
`float`->`double` promotion already followed for the same reason). `modules.rs`/
`sequence.rs` needed a small, mechanical new arm each (`Expr::Char`/`Expr::Cast`) in their
own exhaustive `Expr` matches (`rename_expr`, `scan_expr_for_nested_yield`/`rewrite_expr`)
-- unlike `Table<T>`, this round *does* add new `ast.rs`/`Expr` nodes, so (unlike that
round's note) these weren't free.