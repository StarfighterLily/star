# Star Language: Current State Assessment

## Context

Re-assessment of the Star language (this repo, `e:\Coding\Rust\star`), superseding the
previous version of this file. That version was written before several feature rounds
landed and was stale on its central claims (it said there was no FFI, no file/network I/O,
and a 17-function stdlib; all three are now false). This pass re-verifies everything from
current source, not from `todo.md`'s own summaries: line counts by `wc -l`, a clean
`cargo check` and a full `cargo test --release` run (both done live, both passing), direct
reads of `src/codegen/expr.rs`, `src/types/expr.rs`'s builtin arg-checking, `src/modules.rs`,
`src/codegen/reflect.rs`, `docs/design.md`, `docs/language_reference.md`, and the `examples/`
directory.

## What the language actually has

- **A real, growing compiler pipeline**: lexer → parser → AST → type checker → LLVM-IR
  codegen → `clang` link. `src/` (excluding `tests/`) is now **~23,700 lines of Rust**:
  lexer 861, parser 2,065, checker/types 6,908, codegen 11,303, plus `modules.rs`/
  `sequence.rs`/`driver.rs`/`ast.rs`/`main.rs` ~2,560. `tests/frontend.rs` alone is 12,464
  lines. Verified live: `cargo check` is clean and `cargo test --release` passes
  **798/798**.
- **A genuinely novel memory model** for its stated game-dev niche: `frame` bump allocators
  with compiler-enforced escape analysis, spatial `arena`s with generation-checked `GenRef`
  handles and an internal free-list, and reference-counted `str`/closures/`List`/`Map`/
  `Set`/`Table`. Overflow is a trap by default on every explicit-width integer type
  (`llvm.{s,u}{add,sub,mul}.with.overflow.iN`), with `Wrapping<T>` and `Fixed<Bits,Frac>` as
  explicit, zero-overhead opt-outs for retro-emulation wraparound and deterministic
  fixed-point sim respectively — a real design axis, not just two more numeric types bolted
  on.
- **A much wider type system than before**: `i8..i64`/`u8..u64`/`f32`/`f64`/`char` (all with
  real trap-on-overflow, not aliases of `i32`/`f32` anymore), `Vec2`/`Vec3`/`Vec4`/`Mat4`,
  `List<T>`/`Map<K,V>`/`Set<T>` (linear-scan, not hash-table-backed yet), `(T, U, ...)`
  tuples and `[T; N]` fixed arrays (both inline, no RC header), `Ring<T,N>` (fixed-capacity
  ring buffer), `Table<T>` (struct-of-arrays), `GenRef<T>`/`Handle<T>` (shared generation-
  check machinery), and `Option<T>`/`Result<T,E>` as true compiler-builtin generics with
  `?`-propagation. This closes essentially all of `docs/design.md`'s "indie connective
  tissue" tier; the AAA/retro tiers (quaternions, HDR color, `Bytes`/`Symbol`, time types,
  bitfields) are explicitly still open per that same doc.
- **`par`/`swarm` parallel ECS iteration** with a compiler-proved (conservatively — false
  rejections over false acceptances) disjointness check and a persistent thread pool
  (`src/codegen/par_pool.rs`), plus `sequence`/`yield` tick-based coroutines.
- **A real, if narrow, FFI**: `extern "C" fn` (`src/parser/items.rs`, `Checker::check_extern_fn`
  in `src/types/mod.rs:886`) binds directly to real C symbols — `examples/extern_ffi.star`
  calls libc's `toupper`/`atoi`/`strstr`; `examples/brainfuck.star` calls `putchar`.
  Parameters/returns are restricted to `is_ffi_scalar_ty` (any numeric width, `char`, `ptr`)
  plus a special-cased `str`; generic and uppercase-leading (would collide with Star's
  struct-constructor call syntax) extern names are rejected at the declaration with a
  located diagnostic, not a confusing failure at the call site.
- **Real OS/file/network I/O**, confirmed in `src/codegen/file_io.rs`, `net.rs`, `os.rs`:
  `file_open`/`file_read`/`file_read_line`/`file_write`/`file_close`/`file_exists`,
  `tcp_connect`/`tcp_send`/`tcp_recv`/`tcp_close`, `args()`/`env_get`/`env_set`. This closes
  the single biggest gap the previous version of this document reported.
- **Real rigor in engineering practice**: `todo.md`'s changelog shows a sustained pattern of
  structured, parallel-audit bug-hunting rounds (memory/RC, collections, concurrency,
  parser/lexer) where every candidate bug is reproduced via a real `star build`+run before
  being reported fixed, with a regression test added every time (798 tests now, up from 331
  at the last write-up). Recent finds are subtle and real: a stack overflow from
  never-hoisted `alloca`s inside loops, several "stale snapshot" bugs where a mutating
  argument expression (e.g. `m.contains(extract(m.remove(k)))`) was read before evaluation
  instead of after, an RC leak through a stale/OOB `GenRef` write, and a bug where every
  diagnostic inside an f-string interpolation hole pointed at the wrong source location.
  This is unusually careful engineering for a project this size.

## What still stands in the way of writing useful programs today

**1. The standard library is I/O-and-math-complete but string/collection-manipulation-thin.**
The full builtin surface (confirmed exhaustively from `Checker::check_builtin_call_args`,
`src/types/expr.rs:1521-1728`) is: `print`/`println`/`read_line`, `sqrt`/`floor`/`ceil`/`abs`/
`pow`/`min`/`max`/`clamp`/`lerp`, `dot`/`length` (vector), `rand`/`rand_range`/`rand_seed`,
`len`/`concat`, `is_null`/`ptr_to_str`/`null_ptr`, the file/net/env functions above. That's
still the entire *free-function* surface — there is no `split`/`join`/`trim`/`replace`/
`contains`/`to_upper`/`to_lower`/`format` beyond f-strings for `str`, and collection
operations are method calls on `List`/`Map`/`Set`/`Table`/`Ring` rather than a general
stdlib. A program doing real text processing still has to hand-roll string manipulation
byte-by-byte (as `brainfuck.star` does, deliberately, for its Brainfuck source).

**2. Zero graphics/audio/input, despite being pitched as a "game language."** Confirmed by
grep across `src/codegen/` — no window, framebuffer, GPU, input-device, or sound code exists
anywhere. `docs/language_reference.md`'s own "Common Patterns" section still shows
`draw_sprite(...)`/`flash_screen()`/`wait(30)` as example code with **no backing
implementation** — these are aspirational names in the docs, not real builtins, and (per the
FFI restriction above) there is no way for a user to bind SDL/OpenGL/etc. themselves either,
since `extern "C" fn` only accepts scalar/`ptr`/`str` args, not struct-by-value or callback
parameters a real graphics API needs. A Star program today cannot open a window or draw a
single pixel — this is unchanged from the prior assessment.

**3. The module system still can't support a real multi-file project.** `src/modules.rs`'s
own doc comment (lines 17-24) states the limitation directly: imports are resolved by
inlining one relative-path file at a time with textual `alias__name` mangling, and
transitive re-export doesn't exist — if `a` imports `b` which imports `c`, `a` cannot reach
`c`'s symbols (`b`'s own references to them get double-mangled to `b__c__foo`, which nothing
outside `b` can address). No package manifest, no search path, no versioning. This is
unchanged from the prior assessment and is now the most clearly-identified remaining
architectural gap, since FFI/file-I/O/stdlib breadth all saw real progress in the interim.

**4. FFI is real but narrow.** It reaches libc-shaped functions (scalar args/returns, or a
single `str`) cleanly, which is enough for `atoi`/`strstr`/`putchar`-style bindings, but not
enough to bind a struct-heavy or callback-based C API (SDL, OpenGL) without further FFI work
— relevant to point #2 above, since FFI was the previously-proposed path to graphics without
the compiler implementing a renderer itself.

**5. Programs written in the language are still small, but there's now one real data point.**
`examples/` has grown from 39 files (~40-line max) to 51, and now includes
`examples/brainfuck.star` (81 lines) — a genuine, non-trivial Brainfuck interpreter
exercising `List<i32>` as a 30,000-cell tape under sustained mutation, real FFI (`putchar`),
and string/byte indexing, explicitly built to satisfy `todo.md`'s "build one real, non-toy
program" item. It's a real result (todo.md's own audit rounds have used it to catch actual
bugs), but at 81 lines it's still an interpreter for a toy esoteric language, not evidence
Star can carry a program with real architecture (multiple modules, sustained state, a UI
loop). The other 49 examples remain single-feature demos/regression tests.

**6. Reflection is still metadata-only.** `@export`/`@tweakable` (`src/codegen/reflect.rs`)
emit descriptive offset/type-name metadata for an external tool to read; there is still no
hot-reload runtime, file watcher, or live-patching mechanism wired up. Unchanged from the
prior assessment.

**7. `Map`/`Set` are linear-scan, not hash tables.** Correct and RC-safe, but `docs/design.md`
flags this explicitly as a scaling gap the design owes rather than something the doc quietly
hopes nobody notices — at any real entity/save-data count this is an O(n) lookup, not O(1).

## Bottom line

Star has moved meaningfully since the last assessment: FFI, file I/O, and networking all
landed and are exercised end-to-end (not just declared and untested), the type system grew
from two numeric widths to a genuinely wide, trap-safe set plus a full "indie connective
tissue" collection tier, and the engineering discipline shown in `todo.md` — real repro
before every fix, a regression test for every bug, 798 passing tests, a clean build verified
live for this assessment — remains unusually strong for a project this size. The core
compiler (type checker, memory-safety guarantees, concurrency primitives) is a solid,
increasingly complete foundation.

What's still missing is specific and hasn't changed in kind, only in degree: no graphics/
audio/input of any kind (so the "game language" pitch is still entirely aspirational beyond
memory/concurrency plumbing), a module system that caps real project size at direct-import
depth with no re-exports, an FFI narrow enough that it can't yet reach a real graphics API to
work around the first gap, and a standard library still thin on string/text manipulation
despite now being solid on I/O and math. The most direct next step is still graphics: either
widen `extern "C" fn` to handle struct/callback parameters and bind SDL directly, or add a
minimal windowing/framebuffer builtin surface inside the compiler itself — until one of those
happens, Star can compute, do real file/network I/O, and interpret Brainfuck, but it still
cannot open a window or draw a pixel.
