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
Bug-hunting round 4 (security-focused red-team, not a feature round): four parallel deep
audits, run as isolated git worktrees and merged back by hand afterward (source patches
applied cleanly with no overlapping hunks across all four -- `src/codegen/mod.rs` was
touched by three audits and `tests/frontend.rs` by all four, both at disjoint regions
every time), each required to reproduce every candidate via a real `star build`+run
before being reported, not just read from code. Unlike prior rounds' general-correctness
sweeps, this round explicitly targeted security-relevant bug classes: adversarial-input/
compiler-crash-DoS hardening, integer-overflow-to-memory-corruption plus handle/
generation-counter safety, FFI/pointer/string-boundary hardening, and a second sweep for
concurrency data races following round 3's Symbol-table fix. Two of the four audits were
interrupted mid-run by a session API limit and resumed from their saved worktree state to
finish; both completed cleanly on resume. 7 confirmed bugs fixed (one, a GenRef
generation-counter wraparound, a genuine use-after-free/ABA bypass); 23 new tests added
(939 total, all green, up from 916). All 56 buildable examples still `star build` cleanly
against the merged, fixed compiler (same pre-existing, unrelated
`examples/geometry_lib.star` no-`main`-by-design case as every prior round); every
example's `.exe`/`.ll` rebuilt against the fixed compiler.

Seven bugs fixed, grouped by audit:

**Concurrency (1, following up round 3's Symbol-table fix)**:
1. `@rng.state`, the global xorshift32 seed backing `rand`/`rand_range`/`rand_seed`
   (`src/codegen/vector_math.rs`), had no concurrency protection -- neither `rand`/
   `rand_range` nor `rand_seed` is in `Checker::unsafe_par_fns`'s ban list the way
   `spawn`/`despawn`/`frame:` are, so all three are freely callable from inside a `par`/
   `swarm` body across `par_pool.rs`'s 4 concurrent worker threads. `emit_rand_next`'s
   unsynchronized load-xorshift-store sequence is a lost-update race: two threads loading
   the same value before either stores back compute and store the identical next value.
   Confirmed via 64 arena entities x 200 ticks, each drawing an independent `rand_range`
   value inside a `par` body -- 10-30 duplicate-value ticks out of 200 per run,
   statistically impossible by chance for a 32-bit generator, 5/5 runs. Fixed with
   `@rng.lock`, a binary semaphore created unconditionally in `main`'s prologue (mirroring
   `@sym.lock`'s existing pattern) guarding `emit_rand_next`/`emit_rand_seed`'s critical
   sections (`src/codegen/mod.rs`, `stmt.rs`, `vector_math.rs`). 10/10 clean runs after the
   fix.

**Integer overflow / handle safety (1, severe -- a real use-after-free bypass)**:
2. The arena `GenRef<T>`/`Handle<T>` generation counter (`%GenRef = type { i32, i32 }`)
   was stored as `i32`. Since `spawn`/`despawn` bump it by exactly 1 with no reset, ~2^31
   despawn/spawn cycles on one arena slot wrap the counter back to a bit pattern a
   long-stale `GenRef` already captured, so the staleness check's equality+parity test
   incorrectly passes and the stale handle reads the new occupant's data instead of
   falling back to zero -- a genuine ABA use-after-free bypass, not just a design
   footnote. Confirmed via a real repro: spawn, capture a `GenRef`, loop despawn+respawn
   exactly 2^31 times, read through the old handle -- printed the new occupant's marker
   value before the fix (~12-19s wall-clock, not a forced timescale). Fixed by widening
   the generation field to `i64` everywhere it's declared/loaded/stored/compared
   (`%GenRef`'s LLVM type, `type_align`/`type_size`, every GEP/load/store/`icmp eq` site
   across arena spawn/despawn/GenRef-index/write-check) -- the identical attack now needs
   ~2^63 cycles (`src/codegen/arena.rs`, `mod.rs`). Post-fix re-run of the identical repro
   correctly reports the stale handle as dead.

**FFI/pointer/string boundary (1 root cause, 4 reachable sites)**:
3. Round 3's `symbol_name` null-deref fix flagged but left unfixed a sibling bug:
   `Codegen::zero_value(&Ty::Str)` (a bare null `i8*`) was reused as the "empty result"
   for `List<str>::pop()`/`list[oob]` on an empty/out-of-bounds list, `Ring<str,N>::pop()`/
   `ring[oob]`, `[str; N][oob]`, and `Table<T>::pop()`/`table[idx]` out of bounds where `T`
   has a `str` field -- any subsequent string op (e.g. `len()`) on the "empty" result then
   segfaulted on the disguised null pointer. Confirmed via real, reproducible segfaults
   building and running each of the four shapes before the fix. Fixed by adding
   `Codegen::zero_value_rc`, which allocates a real owned empty string
   (`star_rc_alloc(1)` + NUL) for `Ty::Str` specifically, mirroring `emit_symbol_name`'s
   existing fix, applied at all five call sites (`src/codegen/mod.rs`, `list.rs`,
   `ring.rs`, `array.rs`, `table.rs`). Verified no leak via a 20M-iteration
   sustained-pop-on-empty loop (flat ~3MB).

**Adversarial input / compiler-crash hardening (4, DoS-class)**:
4. A flat binary-operator chain (`1 + 1 + 1 + ...`, ~370+ operators) overflowed the
   native stack during both type-checking and codegen -- `Parser::parse_binary`'s
   iterative precedence-climbing loop still builds one more boxed `Expr::Binary` layer
   per iteration with no depth counter, and neither `Checker::infer_expr` nor
   `Codegen::emit_expr` guards recursion depth on the resulting linked-list-shaped AST.
   Confirmed via a real "thread 'main' has overflowed its stack" crash. Fixed with a
   `Parser::MAX_BINARY_CHAIN = 200` counter local to each `parse_binary` call, reporting a
   clean diagnostic instead (`src/parser/expr.rs`).
5. The identical stack-overflow shape reproduced independently via a flat postfix chain
   (`.field` chains, `f()()()...()` call chains) through `Parser::parse_postfix`'s equally
   unguarded loop. Fixed by reusing the same counter in `parse_postfix`
   (`src/parser/expr.rs`).
6. `[T; N]`/`Ring<T, N>` with a huge `N` (e.g. 999999999999) hung `star build` for 30+
   seconds with no output -- `Codegen::emit_array_repeat` emits two IR lines per element
   and `type_size`'s `element_size * count` silently overflows/wraps in a release build.
   Fixed with `Checker::MAX_INLINE_LEN = 1_000_000`, checked in `resolve_type` for
   `Type::Array`/`Type::Ring` and in `Expr::ArrayRepeat`/`Expr::RingNew` (whose literal
   `count` bypasses `resolve_type`) (`src/types/mod.rs`, `src/types/expr.rs`).
7. A long but genuinely acyclic module import chain (~700-800 files, each importing the
   next) overflowed the stack in `star check` -- the existing cycle guard only catches
   real cycles (every canonical path in a long acyclic chain is new, so it never trips),
   and does nothing to bound plain chain depth. Fixed with `MAX_IMPORT_DEPTH = 200`
   threaded through `modules::resolve_inner` (`src/modules.rs`).

**Areas audited with no bugs found** (see each audit's own report for the full list):
List/Map/Set/Table/Symbol-intern-table malloc/realloc/memcpy size arithmetic (already all
`i64`, unreachable overflow short of exabyte-scale allocation); boundary/negative-index
handling across List/Array/Ring/GenRef/str; `Ring<T,0>` (already rejected at type-check)
and `[T;0]`; every `ptr`/handle-consuming builtin's existing null guards (round 2/3 fixes
hold); `Bytes` boundary cases and non-UTF-8 round-tripping; `extern "C" fn` null/
scalar-width marshaling; `file_read`/`tcp_recv` huge/negative-length arguments (already
clamped); `env_get`/`env_set` under concurrent `par`/`swarm` stress (this runtime's UCRT
appears to serialize environment access internally, unlike the POSIX contract that would
otherwise make this a race); `@frame.buf`/arena globals/thread-pool machinery (already
banned or provably per-worker/not user-reachable); deeply nested parens/blocks/generics/
match (already guarded from earlier rounds); huge numeric literals across every width;
malformed/nested f-string interpolations; null bytes/invalid UTF-8 source; megabyte-scale
identifiers; self-referential structs/generics (already caught); direct 2-/3-file import
cycles.

Two real, reproduced findings noted but explicitly left unfixed as out of scope for this
round (each would need a larger redesign, not a minimal targeted fix): `[T; N]`
array-repeat literals fully unroll at compile time into N individual instructions --
N=50,000 already crashes `clang` itself (a stack overflow inside clang's own compilation)
and N=1,000,000 takes 2.5 minutes to fail; a proper fix needs a runtime-loop/memset-style
lowering instead of full unrolling. An f-string interpolation of an `i64` struct field
(`f"{e.id}"`) hits a `clang` vararg type mismatch (`i64` passed where `printf`-family's
vararg expects a pointer) -- noticed in passing during the concurrency audit's example
runs, not chased down.

---

### Previous round

Bug-hunting round 3 (not a feature round): four parallel deep audits, run as isolated
git worktrees and merged back by hand afterward (source patches applied cleanly with no
overlapping hunks; only `src/codegen/mod.rs` was touched by two audits, at disjoint
regions), each required to reproduce every candidate via a real `star build`+run before
being reported, not just read from code -- `Bytes`/`Symbol` (the two newest types),
time types (`Tick`/`Duration`/`Instant`)/vector-matrix math/numeric edge cases,
modules/FFI/parser-lexer/reflection, and a cross-cutting memory/concurrency sweep
targeting combinations a single-topic audit would miss (collections-of-payload-enums,
`par`/`swarm` per-iteration RC locals, arena spawn/despawn with RC-bearing fields,
abandoned `sequence`s). 4 confirmed bugs found and fixed, one of them a real data race;
14 new tests added (916 total, all green, up from 902); all 55 buildable examples still
`star build` cleanly (same pre-existing, unrelated `examples/geometry_lib.star`
no-`main`-by-design case as every prior round -- `examples/tcp_socket.star` now builds
clean too when given its documented `-l ws2_32` flag); every example's `.exe`/`.ll`
rebuilt against the fixed compiler.

Four bugs fixed, grouped by audit:

**Bytes/Symbol (1, severe -- a real data race)**:
1. `Symbol`'s process-wide intern table (`@sym.data`/`@sym.len`/`@sym.cap` in
   `src/codegen/symbol.rs`) had no concurrency protection, despite `Symbol(..)`/
   `symbol_name(..)` being fully reachable from inside a `par`/`swarm` body -- neither
   is in `Checker::unsafe_par_fns`'s ban list the way `spawn`/`despawn`/`frame:` are, and
   `par`/`swarm` genuinely dispatches across 4 concurrent OS worker threads
   (`src/codegen/par_pool.rs`). The intern table's grow path (unsynchronized `malloc`/
   `memcpy`/`free`) is a real shared-mutable-global, unlike `List<T>`/`Map<K,V>`, whose
   backing buffers are per-value and already disjoint across workers by the checker's own
   proof. Confirmed via a real, reproducible `STATUS_HEAP_CORRUPTION` (`0xC0000374`) crash,
   5/5 runs, from 64 arena entities across 200 ticks all interning the same tick-unique
   string concurrently from all 4 workers. Fixed by adding `@sym.lock`, a binary semaphore
   guarding every `Symbol(..)`/`symbol_name(..)` critical section, created once,
   unconditionally, in `main`'s prologue -- before any user code (and therefore any
   `par`/`swarm` dispatch) can run, avoiding the first-use race a lazy-init pattern would
   have here (`src/codegen/mod.rs`, `stmt.rs`, `symbol.rs`). 10/10 clean runs after the fix,
   with every entity converging on the identical id.

**Time types/vector math (1)**:
2. Field access on any fieldless builtin type (`Mat4`, `Tick`/`Duration`/`Instant`, `str`,
   `bool`, numeric widths, `List<T>`/`Map<K,V>`/... , enum values) type-checked silently
   with zero diagnostics, only failing later at codegen with an unlocated internal error
   ("field access on non-struct type", no source location or field/type name).
   `Checker::resolve_field_type`'s catch-all fallback (for any base type that isn't a
   struct or a swizzleable vector) silently returned a placeholder `unknown` type instead
   of reporting an error -- a pre-existing gap (predates this round's type additions) that
   directly affects `Mat4`, since this compiler has no field accessor for it at all
   (construct/multiply only). Confirmed via `let m = Mat4(...); let x = m.bogus_field`,
   which produced only the unlocated codegen error. Fixed by having the catch-all arm
   report a located "no field `x` on type" diagnostic before returning the placeholder,
   mirroring the existing struct-branch's own diagnostic (`src/types/expr.rs`).

**Modules/FFI/parser/reflection (2)**:
3. `extern "C" fn` could silently collide with an ordinary `fn` of the same name in the
   same file -- `Checker::check`'s pass-1 duplicate-name loop only checked
   `value_names_seen` for `Item::Fn`; `Item::ExternFn` unconditionally overwrote
   `self.functions` with no collision check at all (a gap already flagged in a pre-existing
   code comment as "left for a future round," never fixed until now). `star check` passed
   cleanly on `extern "C" fn myfunc(...)` plus `fn myfunc(...)` in one file, then failed
   opaquely at the `clang` step with "invalid redefinition of function." Fixed by adding a
   symmetric cross-check catching either declaration order with a clean "declared more than
   once" diagnostic at check time (`src/types/mod.rs`).
4. Reflection metadata (`@export`/`@tweakable`) showed the internal flat-mangled codegen
   name (`Box__i32`, `Option__i32`) instead of a real generic type spelling (`Box<i32>`,
   `Option<i32>`) for any monomorphized generic struct/enum field, since `Codegen` never
   had access to the `Checker`'s `mono_struct_of`/`mono_enum_of` tables (which don't
   survive past type-checking) mapping a mangled name back to its `(template, args)`. Byte
   offsets themselves were already correct (a prior round's padding/alignment fix holds) --
   this was purely a type-name-string bug. Fixed by threading a new
   `TypedModule::generic_instantiations` map through from `Checker::check` to `Codegen`,
   consulted by a new `generic_display_name` helper that recurses per type argument,
   correctly handling nested (`Box<Option<i32>>`) and multi-param (`Result<i32, str>`)
   generics too (`src/types/hir.rs`, `src/types/mod.rs`, `src/codegen/mod.rs`,
   `src/codegen/reflect.rs`).

**Areas audited with no bugs found** (see each audit's own report for the full list):
`Bytes` RC correctness under the generic-fallback-spill pattern (struct field and
direct-return-and-index, flat across 30M iterations) and in `List<Bytes>`/`Map<K,Bytes>`/
closures; `Bytes`/`Symbol` bounds/edge cases (empty, OOB, `Symbol("")`, long/non-ASCII
strings); `Symbol`/`i64` cast round-tripping incl. bogus ids; `Bytes`/`Symbol` structural
equality and as generic params/`Map`/`Set` keys; `@export`/`@tweakable` on `Symbol`/`Bytes`
fields; time-type operator legality (every intended-illegal pairing correctly rejected) and
overflow/edge values (trap-on-overflow holds at `i64::MAX`/`MIN` for `Duration`/`Instant`);
`Mat4`/`Vec4` non-identity transform and self-composition correctness, `Vec4 * Mat4`
wrong-order rejection, zero-vector `length`/`dot`; generics instantiated with time/vector
types as type parameters; module system (`../` imports, subdirectory imports, empty/
whitespace-only imports, no-`main` imports, self-import cycles, alias/local-name
collisions, diagnostic file-attribution); FFI boundary cases (zero-arg extern, extern-as-
value, same-file identical redeclaration, arg mismatch diagnostics, every scalar width);
f-string/lexer edge cases beyond round 2's coverage; reflection on zero-field/undecorated
structs; and the full cross-cutting memory/concurrency sweep -- `List<Option<str>>`/
`Table<T>` with an `Option`-field column/`Map<str,Result<str,str>>`/`Ring<Option<T>,N>`
sustained push/pop/CoW-clone (up to 40M iterations), `par`/`swarm` bodies constructing/
dropping RC-bearing locals per-dispatch (600K cycles), arena spawn/despawn cycling with an
`Option<str>`/`List<str>` struct field (25M/3M cycles), `GenRef` field-write cycling, a
`sequence` abandoned mid-way with a live-across-`yield` `str` local (25M cycles), and
`match` over a fresh payload-enum scrutinee inside nested `par`-in-`par` -- all flat,
confirming round 2's `Ty::Enum` RC-walk and generic-fallback-spill-tracking fixes compose
correctly everywhere reachable.

One minor non-bug diagnostic-noise observation, left unfixed as out of scope: a struct
field default expression referencing an undefined name gets independently re-type-checked
(and re-reports the identical diagnostic) once at struct-definition time and once per
construction call site using that default -- duplicate messages, not a wrong or missing
one, and not specific to any type added this round.

