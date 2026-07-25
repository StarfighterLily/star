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

---

### Previous round

Bug-hunting round 2 (not a feature round): four parallel deep audits, run as isolated
git worktrees and merged back by hand afterward, each required to reproduce every
candidate via a real `star build`+run before being reported, not just read from code --
numeric types/casts/generics/Option-Result, collections/memory model (RC leak hunting
via sustained-iteration working-set growth), concurrency/control-flow (`par`/`swarm`/
`sequence`/closures/pattern-matching), and FFI/IO/modules/parser-lexer/vector-math/
time/misc types. 8 confirmed bugs found and fixed; 15 new tests in `tests/frontend.rs`
(902 total, all green); all 52 buildable examples still `star build` cleanly (the same
pre-existing, unrelated `examples/geometry_lib.star` no-`main`-by-design and
`examples/tcp_socket.star` `-l ws2_32` cases noted in every prior round); every
example's `.exe`/`.ll` rebuilt against the fixed compiler.

Eight bugs fixed, grouped by audit:

**Concurrency/control-flow (1)**:
1. A closure literal defined lexically inside a `while`/`for` loop silently inherited
   the enclosing loop's `Checker::loop_depth`, so a bare `break`/`continue` directly in
   the closure's own body (with no loop of its own) type-checked cleanly even though a
   closure lowers to its own independent top-level LLVM function (`Codegen::
   emit_closure_lit`) with no well-defined branch target for the outer loop's exit
   block. `Stmt::Par`'s body already resets `loop_depth` to `0` for the identical
   reason; the same reset was simply missing from `Expr::Lambda`. Confirmed via a real
   `star build` failure: `clang` rejected the generated IR with "use of undefined value
   '%while_end_3'" (a label that only exists in the enclosing function). Fixed by
   saving/resetting `self.loop_depth` around a closure body's type-checking, mirroring
   `Stmt::Par`'s existing pattern (`src/types/expr.rs`).

**Collections/memory model (1, but a broad one)**:
2. `Codegen::emit_place`'s generic fallback (reached whenever a struct-returning
   `Call`/`If`/`Match`/`TableIndex`/`Table::pop()` is used directly as a `Field`/
   `TupleIndex`/`ArrayIndex`/`RingIndex` base with no intervening `let`) leaked every
   RC-bearing field of the spilled temporary *except* the one actually read. A prior
   round's fix for the "double-retain via generic-fallback spill" bug
   (`Codegen::place_is_shared_storage`) correctly stopped double-retaining the one
   extracted field, but only released the spilled temporary itself when its type was
   `List`/`Map`/`Set`/`Table` -- any other RC-bearing type (a struct/tuple/array with
   2+ RC-bearing leaves) had nothing ever release it, so every un-accessed sibling
   field leaked permanently. Confirmed via real unbounded working-set growth: `make().a`
   (a two-`str`-field struct, only `a` ever read) grew ~3MB flat (control with a `let`
   binding) to ~790MB in under 4 seconds of 30,000,000 iterations; `t.pop().name` (a
   `Table<T>` element, `tag` field never read) grew ~3MB to ~96MB over 5,000,000
   iterations. Fixed by making `Field`/`TupleIndex`/`ArrayIndex`/`RingIndex` retain
   unconditionally on every read (removing `place_is_shared_storage` entirely, now
   obsolete) and always tracking the fallback's spilled temporary for release for any
   `contains_rc` type, not just the four collection types -- the two together exactly
   reproduce plain `Ident`-field-read semantics for a temporary (`src/codegen/rc.rs`,
   `mod.rs`, `expr.rs`, `array.rs`).

**Numeric/generics/Option-Result (3, one severe)**:
3. Any `Option<T>`/`Result<T,E>` (payload enum) local never explicitly matched leaked
   its payload forever: `Codegen::contains_rc`/`emit_rc_walk` had no arm at all for
   `Ty::Enum`, so `track_owned` never registered a payload-enum local for scope-exit
   release. Confirmed via `let o = make_some(s)` (never matched) growing working set
   ~83MB->390MB+ within 2s over 30M iterations, flat on a control without the
   `Option<str>` wrapper. Fixed by adding a `Ty::Enum` arm to both: `contains_rc` is
   true whenever any variant carries an RC-bearing field; `emit_rc_walk` loads the
   runtime tag and branches per RC-bearing variant, bitcasting the shared payload
   buffer the same way construction/pattern-matching already do (`src/codegen/rc.rs`).
4. `match`/`?` over a fresh (non-place) payload-enum scrutinee leaked the scrutinee's
   own reference -- addressed via `emit_place`'s generic fallback, which spills it into
   a scratch alloca. This is the same fallback bug #2 above generalized to release
   unconditionally, so the fix for #2 (tracking *any* `contains_rc` type in the
   fallback, not just collections) already covers this case once the two audits'
   overlapping `rc.rs`/`mod.rs`/`expr.rs` changes were reconciled during merge -- no
   separate call site needed. Confirmed independently via a hand-written
   `match Result::Ok(v)/Err(e) -> v/e` (no `?`) and via `?`-propagation itself (which
   desugars to the identical `Match` shape), both showing unbounded growth before the
   fix.
5. (Most severe) A struct with an `Option<T>`/`Result<T,E>`-typed field baked a corrupt
   LLVM layout, causing memory corruption/segfaults. `Codegen::emit`'s single
   interleaved struct/enum-declaration pass processed items in `module.items` order,
   but every monomorphized generic enum instantiation is appended after every source
   item (`Checker::check`'s `mono_items`), so a struct's own field-type computation
   (`llvm_ty` -> `enum_is_payload`) always ran before the referenced enum was
   registered -- silently mistagging the field as bare `i32` in the struct's
   *permanent* LLVM type text instead of the real tagged-union type. Confirmed via a
   real segfault (`0xC0000005`) on `struct Holder: opt: Option<str>` plus a single
   match, one iteration, no collections/generics-nesting involved. Fixed by splitting
   registration (`register_struct`/`register_enum`) from text emission
   (`emit_struct_decl`/`emit_enum_decl`) into two passes over every item
   (`src/codegen/mod.rs`, `reflect.rs`).

**FFI/IO/modules/parser (2)**:
6. `ptr_to_str` segfaulted on a null `ptr`. Unlike every other `ptr`-handle builtin in
   this codegen (`file_close`/`file_read`/`tcp_send`/...), which all abort loudly via
   `abort_if_null_handle`/`abort_if_null_socket` before dereferencing, `ptr_to_str`
   called `strlen` on its argument with no null check. Confirmed via a real, unguarded
   segfault building and running `ptr_to_str(null_ptr())` -- a realistic shape since
   `extern "C"` functions commonly return null on failure. Fixed by adding the same
   "check first, abort with a message" branch every sibling builtin already uses
   (`src/codegen/builtins.rs`).
7. `symbol_name` on an out-of-range `Symbol` id returned a null pointer disguised as
   `str`, not a real empty string -- it returned `Codegen::zero_value(&Ty::Str)`, which
   is literally a bare null `i8*`, documented (wrongly) as "safe" in a pre-existing
   comment. `len(symbol_name(bogus))` (`strlen` on that null) segfaulted for real.
   Fixed by allocating a real owned empty string (`star_rc_alloc(1)` + NUL byte, the
   same recipe `env_get`'s missing-variable branch uses) instead
   (`src/codegen/symbol.rs`). The same root cause (`zero_value(&Ty::Str)` used as a
   fake "empty string" elsewhere, e.g. `List<str>::pop()` on an empty list) was noted
   but left unfixed as out-of-scope collections codegen for this round.

**Areas audited with no bugs found** (see each audit's own report for the full list):
par/swarm disjointness proof and thread-pool nesting, sequence/yield nested-position
scanning, RC-release-on-break/continue/return, match exhaustiveness, `Map`/`Set`/
`Ring`/`Table` CoW invariants, arena spawn/despawn/`GenRef` generation checks,
structural equality codegen, frame escape analysis, FFI scalar/ptr/str marshaling
across every width, file/TCP I/O edge cases, module resolution (3-level nesting,
sibling imports, diamond imports), lexer/parser edge cases (f-strings, number
literals), Vec2/3/4/Mat4, Tick/Duration/Instant, overflow-trapping and
`Wrapping<T>`/`Fixed<Bits,Frac>` across every numeric width, multi-type-parameter
generic monomorphization independence.

Two real gaps noted but explicitly out of scope / not correctness bugs, left for a
future round: integer literals can't spell a `u64` value above `i64::MAX` (lexer caps
at `i64` regardless of target cast type); two independently-imported files that both
declare the same `extern "C" fn` collide as "declared more than once" when combined
into one program (a module-system re-export/dedup limitation already tracked by
roadmap item #5, not a new bug).
