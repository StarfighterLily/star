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
Feature round closing out the type-system expansion `docs/design.md` laid out: added
`Table<T>`, a struct-of-arrays table -- the last remaining "indie connective tissue" gap
(§10). New tests in `tests/frontend.rs` (658 total, all green); all 42 pre-existing
examples still `star check` cleanly (the same pre-existing, unrelated `examples/player.star`
failure noted in every prior round -- `Vec3(0, 0, 0)`'s int literals vs. its `f32` fields
-- confirmed present on a clean `main` checkout, not a regression), plus a new
`examples/table.star` (43 total).

`Ty::Table(Box<Ty>)` lowers to the same reference-counted, copy-on-write `i8*` object
pointer scheme `List<T>`/`Map<K,V>`/`Set<T>` already use (unlike `Ring<T,N>`'s inline
storage), pointing past a `star_rc_alloc` header at a `{ i64 len, i64 cap, F0*, F1*, ... }`
payload -- one parallel growable column per field of the struct `T` (in declaration
order, from `Codegen::struct_field_types`), all growing/shrinking in lockstep behind one
shared `len`/`cap` pair, rather than `List<T>`'s single `{ T*, i64, i64 }` buffer. Unlike
`Ring<T,N>` (whose second argument `N` is a bare integer literal, needing dedicated parser/
AST special cases), `Table<T>` has only one type argument, a plain `Type` -- so
`Table<T>()`/`.push`/`.pop`/`.len`/`table[i]`/`table[i] = v` all piggyback on the exact
same generic-turbofish-plus-`StructLit`/`Expr::Call`/`Expr::GenRefIndex` machinery
`List<T>`/`Map<K,V>`/`Set<T>` already established, with *zero* parser or `ast.rs` changes
-- only new `TypedExpr::TableNew`/`TableMethod`/`TableIndex` nodes (`TableMethod::{Push,
Pop, Len}`) produced by the checker (`Checker::infer_table_new`/`infer_table_method`,
mirroring `infer_list_new`/`infer_list_method` almost exactly). `Checker::resolve_type`'s
new `"Table"` branch requires `T` to already be a declared, non-generic `struct` (erroring
otherwise, mirroring `Map`'s key-hashability check) -- but that branch only fires for a
`Table<T>` *type annotation*; `Table<T>()`'s own turbofish resolves its single type
argument directly, so `infer_table_new` needed its own copy of the same "is this a
struct?" check (`rejects_table_of_non_struct_element` covers both).

`push` grows every column in lockstep (each with its own `malloc`/`memcpy`/`free`, sized
by that column's own element type, not a single shared element size), then writes each
of the pushed struct value's fields (via `extractvalue`) into the slot at `len` in its own
column; `pop` reads each column's slot at `len - 1` (via `getelementptr`/`load`) and
reassembles them into a `%Struct` value (an `alloca`+`GEP`+`store`+`load`, the same shape
`Codegen::emit_expr`'s ordinary `StructLit` construction already uses) -- mirrors
`ListMethod::Pop`'s "no zeroing, ownership transfers with no retain, the shrunk `len`
already keeps `Codegen::emit_rc_walk`'s release-thunk loop from re-visiting it" convention,
just per-column. `table[i]`/`table[i] = v` (`TableIndex`, sharing `Expr::GenRefIndex`'s
`[..]` syntax with `GenRef<T>`/`List<T>`/`[T; N]`/`Ring<T,N>`) read/write the whole element
the same reassemble-per-column/decompose-per-column way, bounds-checked against the shared
`len`, yielding/discarding the zero value out of bounds exactly like `ListIndex`. The
copy-on-write uniqueness gate (`emit_table_ensure_unique`, gating every mutating op just
like `emit_list_ensure_unique`) clones *every* column (not just one buffer) when the table
object isn't uniquely owned -- confirmed by a `runtime_table_end_to_end` scenario where
mutating a `let clone = original` must not affect `original`.

One deliberately accepted gap, documented on `Ty::Table` and `crate::codegen::table`'s own
module doc comment: there is no dedicated `Codegen::emit_place` support for projecting a
single *field* through a table index (`table[i].field = v`) -- unlike `List<T>`'s element
(one contiguous value at one address `emit_list_index_place` can hand out a real pointer
into), a `Table<T>` element's fields live at independent addresses in independent columns,
so `emit_place`'s generic `Field`-base resolution (which GEPs a field offset out of a
single base pointer) cannot address it without inventing a new place representation. This
falls through to the existing generic fallback instead (spill a materialized copy into a
fresh alloca) -- correct for a *read* (`table[i].field`, since materializing a temporary to
read a field out of is what an ordinary value read does anyway) but silently targets a
disconnected temporary for a *write*, the same accepted gap this compiler already has for
any other rvalue struct base with no addressable storage of its own (e.g. a function's
returned-by-value struct). `table[i] = v` (the whole element) is unaffected and fully
supported, via a dedicated `store_target`/`store_table_index` arm.

Every other exhaustive match over `Ty`/`TypedExpr` this compiler has (`type_align`,
`type_size`, `llvm_ty`, `mangle_ty` x2, `zero_value`, `contains_rc`, `emit_rc_walk`,
`expr_ty`, reflection naming, `assign_root_name`, `frame_analysis`'s untracked-expression
bucket (`Table` stores by value into its own `malloc`'d columns, same as `List`/`Map`/
`Set`, so it needs no escape-analysis tracking, unlike `Ring<T,N>`'s inline-storage
`RingIndex`), par/swarm's `walk_par_expr`) needed a parallel `Table`/`TableNew`/
`TableMethod`/`TableIndex` arm, found mechanically by
`rustup run stable-x86_64-pc-windows-gnu cargo check`'s non-exhaustive-match errors
against this repo's actual working toolchain (the default `stable-x86_64-pc-windows-msvc`
host has no linker available in a plain shell here; `x86_64-pc-windows-gnu` needs the
gnu-hosted toolchain, not just `--target`, since a msvc-hosted `cargo` still tries to
compile build-script/proc-macro crates for the msvc host and hits the same missing
linker) rather than by grepping for every call site by hand. `modules.rs`/`sequence.rs`
needed *no* changes at all (unlike `Ring<T,N>`'s `Type::Ring`/`Expr::RingNew`): `Table<T>`
introduces no new `ast.rs` node, so its cross-file rename and yield/hoisting scans are
already covered generically by the existing `Type::Generic`/`Expr::StructLit` arms.