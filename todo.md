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
Bug-hunting round (not a feature round): four parallel deep audits, each required to
reproduce every candidate via a real `star build`+run before being reported, not just
read from code -- numeric types/casts/checker (`clamp`/`min`/`max`/`abs` math builtins),
collection codegen (`List`/`Map`/`Set`/`Table`/`Ring`/`Array`), the memory model (RC/
frame/arena/`GenRef`), and concurrency/modules/parser/lexer/file-IO. 9 confirmed bugs
found and fixed; 19 new tests in `tests/frontend.rs` (817 total, all green); all 51
buildable examples still `star build` cleanly (the same pre-existing, unrelated
`examples/geometry_lib.star` no-`main`-by-design and `examples/tcp_socket.star`
`-l ws2_32` cases noted in every prior round); every example's `.exe`/`.ll` rebuilt
against the fixed compiler.

Nine bugs fixed, grouped by audit:

**Numeric builtins (3)** -- all three were "checker widened to every numeric type,
codegen never fully followed" gaps in the same family as prior rounds' `sqrt`/`abs`/
`min`/`max`/`pow` fix, just missed spots:
1. `clamp(x, lo, hi)` (`Codegen::emit_clamp`, `src/codegen/vector_math.rs`) hardcoded
   `i32`/`float` opcodes regardless of the argument's real type -- any other numeric
   width (`i64`, `f64`, ...) produced a tagged `i32`/`float` operand feeding an opcode
   sized for a different width, malformed IR `clang` rejected outright. Confirmed via a
   real `star build` failure on `clamp(500 as i64, 0 as i64, 100 as i64)`. Fixed by
   generalizing to `ty.int_shape()`-driven dispatch plus a real `f32`/`f64` split,
   mirroring `emit_minmax`/`emit_abs`'s existing shape.
2. `min(a, b)`/`max(a, b)` on `f64` arguments (`Codegen::emit_minmax`) always narrowed
   through `promote_to_float` (down to `f32`) but still tagged the result `"float "`, so
   an `F64`-typed call site received a value tagged `float` -- untagging it as `Ty::F64`
   (expecting `"double "`) produced a double-tagged, `clang`-rejected store. Confirmed via
   a real `star build` failure on `min(3.5 as f64, 7.5 as f64)`. Fixed with a dedicated
   `f64` branch calling `llvm.minnum.f64`/`llvm.maxnum.f64` and tagging `double`.
3. `abs(x)` on a signed sized-int type never trapped on overflow -- its negation used a
   raw, untrapped `sub {ity} 0, {bare}` instead of the same checked-arithmetic path real
   binary `-`/unary `-` route through, so `abs(MIN)` (the one input where `0 - x`
   overflows) silently wrapped instead of trapping like every other signed-int arithmetic
   op in this codegen. Confirmed via `abs(-128 as i8)` printing `-128` with exit 0 (no
   trap) where the equivalent direct `(0 as i8) - (-128 as i8)` already correctly
   trapped. Fixed by routing the negation through `Codegen::emit_binop` (`BinOp::Sub`),
   the same fix already applied to unary `-` itself in a prior round.

**Memory/RC (3)**:
4. `[T; N]`/`Ring<T,N>` element reads leaked one reference on every *transient* use
   (`len(arr[i])`, `println(ring[i])`, an f-string hole, `concat(ring[i], ..)`) --
   `Codegen::is_rc_borrowing_read` (consulted by those consumer sites to decide whether
   to balance a read's retain back out with a release) omitted `ArrayIndex`/`RingIndex`
   from its match list even though both index-read paths already call `emit_retain_at`
   correctly. Confirmed via real unbounded working-set growth (~112MB -> 884MB over
   30,000,000 iterations of `len(ring[0])` on a `Ring<str,1>`, flat on an otherwise-
   identical control with the reads removed). Fixed by adding both to the match list.
5. `table[i].field` double-retained an RC-bearing field on every read: `TypedExpr::
   TableIndex` has no dedicated `emit_place` arm (a table element's fields live in
   independent columns with no single contiguous address), so it falls into the generic
   fallback, which spills `emit_table_index`'s result -- already fully retained while
   reassembling the struct copy, correctly treating it as a fresh owned value -- into a
   scratch alloca. The outer `Field` read then retained *again*, treating that
   already-owned copy as if it were a borrowed read of real persistent storage. Confirmed
   via real unbounded working-set growth (~58MB -> 283MB over 10,000,000 iterations),
   flat on a read-free control.
6. The same double-retain bug reached without `Table<T>` at all: any struct-returning
   call/`if`/`match` chained directly into a `.field` access (no `let` binding of its
   own) hits the identical generic-fallback spill. Confirmed via real unbounded
   working-set growth (~280MB -> 408MB in under a second) on `make(i).name`. Both #5 and
   #6 fixed together with one new helper, `Codegen::place_is_shared_storage` (`src/
   codegen/rc.rs`) -- true only for a place that bottoms out in an `Ident`/`self`/
   `GenRefIndex` (real, independently-owned storage), false for anything a
   scratch-alloca spill produced -- consulted by the `Field`/`TupleIndex`/`ArrayIndex`/
   `RingIndex` read arms before retaining.

**Collections (1)**:
7. `t[i].tags[j] = v` (a `List<i32>`/`[i32;N]` field of a `Table<T>` element, indexed one
   level further than the already-guarded `t[i].field = v`/`t[i].field.push(x)` shapes)
   silently no-op'd instead of being rejected: `Checker::writes_through_table_index` only
   peeled through `Field`/`TupleIndex` on its way to a `TableIndex` root, treating any
   `ListIndex`/`ArrayIndex`/`RingIndex` as unconditionally "real addressable storage"
   (correct for `list[i].some_table[j]`, wrong when that index's own base is itself
   already a disconnected `Table<T>`-index temporary). Confirmed via a real `star
   build`+run where `t[0].tags[0] = 99` compiled cleanly, ran to exit 0, and printed the
   pre-write value `1`. Fixed by widening `writes_through_table_index`'s recursion (and
   both call sites' `matches!` entry guards, `check_mut_receiver` and `Stmt::Assign`) to
   also peel through `ListIndex`/`ArrayIndex`/`RingIndex`.

**Concurrency/modules (2)**:
8. `par`/`swarm`'s disjointness proof (`Checker::walk_par_stmt`'s `Assign` arm) only ever
   extracted an assignment target's *root* identifier (`root_ident`) to prove a write is
   to a safe body-local -- it never walked any *index* sub-expression nested inside the
   target, so a hazardous call (one that transitively `spawn`s, unconditionally banned
   everywhere else in a par/swarm body) hidden inside a target's index
   (`arr[hazard()] = 1`) went completely unchecked: a soundness hole letting an
   unsynchronized-across-worker-threads race compile silently, even though the identical
   call in a `let` value position was already correctly rejected. Confirmed via a real
   `star check` accepting the program (exit 0) before this fix. Fixed with a new
   `walk_par_assign_target` walk (mirrors `root_ident`'s own recursion through `Field`/
   `TupleIndex`/`ListIndex`/`ArrayIndex`/`RingIndex`/`GenRefIndex`, but also runs
   `walk_par_expr` over each index-bearing node's index expression).
9. Every checker/codegen diagnostic whose root cause lives inside a *successfully
   inlined* imported file rendered at a wrong/garbled location in the *importing* file
   instead: `crate::modules::resolve`'s import-inlining pass preserves an imported file's
   own byte-offset spans verbatim, but `Span` had no notion of "which file," and
   `Compilation` stored only the root file's source text, rendering every diagnostic
   against it unconditionally. Confirmed via a real `star check` on a type error inside
   an imported file rendering at `main.star:1:25` -- mid-way through the `import`
   statement's own string literal -- instead of the real `lib.star:2` location (worse
   with a size mismatch between the two files: a byte offset from a 103-line imported
   file rendered as a nonsensical out-of-range line in a 4-line importing file). This is
   the same bug class as a prior round's f-string-interpolation-hole span fix, unfixed for
   the entire module system -- likely far higher real-world impact, since it hits every
   multi-file project's compile errors in library code. Fixed with a real (if minimal)
   multi-file span architecture: `Span` gained a `file_id: u32` field (default `0` for
   the root file), stamped by the lexer at the one place every span is constructed
   (`Lexer::span`, already the sole choke point from a prior round's `base_offset` fix);
   `crate::modules::resolve_inner` allocates a fresh id per distinct imported file
   *before* parsing it (`Parser::parse_source_with_file`), so every span its AST carries
   is correctly stamped from the moment it's lexed -- no separate span-rewriting pass
   needed. `Driver::compile` threads the resulting `(label, source)` file table through
   as `Compilation::imported_files`, and `render_diagnostics` looks up the correct file
   per diagnostic instead of assuming there's only ever one. Only 2 pre-existing
   `Span::new` call sites and 3 `Parser::new` call sites existed in the whole codebase,
   keeping the blast radius small despite `Span` being used pervasively everywhere else
   (every other span in the compiler flows forward from a token, never constructed
   fresh). Import-resolution-level failures (a missing file, a parse error, a cycle)
   were already correctly re-anchored on the importing file's own span and are
   unaffected by this fix -- a separate, already-working code path.

One diagnostic-quality-only fix found during the concurrency/modules audit, not
severity-ranked above since it's not a correctness bug (the program was already
correctly rejected either way): a `yield` hidden inside a `match`-as-expression used as
an `if`/`while` condition (or a `for` loop's range bounds) fell through to the generic
type-checker fallback message instead of `sequence.rs`'s own dedicated, more specific
diagnostic every sibling nested construct already gets -- `scan_for_nested_yield`'s
`If`/`While`/`For` arms scanned their body blocks but never their own header expression.
Fixed by also calling `scan_expr_for_nested_yield` on `cond`/`start`/`end`.