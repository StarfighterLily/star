# Star Compiler — Next Steps
1. Complete Priority Roadmap

## Priority Roadmap (derived from current_status.md suitability analysis)

Ordered biggest win → smallest, where "win" = how much it unblocks writing useful
programs relative to implementation effort.

### 4. Graphics / audio / input bindings
Core to the "game language" pitch.
- ~~Window creation + framebuffer/pixel-blit as the minimal viable slice~~ --
  done: SDL2 (vendored under `sdl/` at the repo root) is bound as a fixed set
  of free-function builtins (`crate::codegen::sdl`), the same "hand-emit
  calls to an existing C API" shape `file_io.rs`/`net.rs` already
  established, rather than widening `extern "C" fn` to handle SDL's
  struct-by-value/callback parameters (a much larger, more general FFI lift
  the graphics need alone didn't justify). `window_create`/`window_destroy`
  reuse `Ty::Ptr` as an opaque `SDL_Window*` handle (null on failure, same
  convention as `file_open`/`tcp_connect`); `clear_screen`/`draw_pixel`/
  `draw_rect`/`draw_line`/`present` are a minimal immediate-mode 2D
  framebuffer surface using the existing `Color32` type for pixel color.
  Every drawing builtin re-derives its `SDL_Renderer*` from the window via
  `SDL_GetRenderer` rather than the caller juggling two handles. See
  `examples/graphics.star`.
- ~~Input polling (keyboard/mouse/gamepad)~~ -- keyboard/mouse done:
  `key_down(scancode)`/`mouse_x()`/`mouse_y()`/`mouse_button_down(button)`,
  backed by `SDL_GetKeyboardState`/`SDL_GetMouseState`. `window_should_close`
  doubles as the required per-frame `SDL_PollEvent` pump (an unpumped SDL
  event queue makes the OS mark the window "Not Responding" within a couple
  of seconds) -- draining the whole queue and reporting whether a global
  `SDL_QUIT` was seen; a per-window close button
  (`SDL_WINDOWEVENT_CLOSE`)/gamepad input are both a deliberate floor cut,
  left for later (the same kind of scope cut `net.rs`'s "no hostname
  resolution" already documents for `tcp_connect`).
- Audio playback -- still open, deferred as originally planned (least
  blocking for "useful program" broadly).
- ~~Text rendering / font loading~~ -- done: `crate::codegen::font` closes
  `projects/snake/NOTES.md` section 4's "no text/font rendering at all" gap
  (undocumented here previously; the "audio/gamepad" bullet above was only
  half of "game language I/O still missing"). SDL2 bundles no text renderer
  of its own (that's `SDL_ttf`, a separate library not vendored here), so
  this is a from-scratch bitmap-font renderer built on `draw_rect`'s own
  `SDL_RenderFillRect` primitive rather than a binding to a third-party text
  library: `default_font() -> ptr` (a compiled-in 5x7 monospace font),
  `font_load(path) -> ptr`/`font_free(font)` (a small custom on-disk bitmap
  format, `null` on failure), `draw_text(window, font, text, x, y, scale,
  color)`/`measure_text(font, text, scale) -> (int, int)`. Also added
  `get_pixel(window, x, y) -> Color32` (`SDL_RenderReadPixels`) as supporting
  infrastructure -- previously there was no way for a Star program (or a
  test) to read back a drawn pixel at all, so every SDL drawing builtin's
  own tests could only assert "didn't crash," never "drew the right thing."
  See `docs/language_reference.md`'s "Text Rendering / Font Loading" section
  and the new test section at the end of `tests/frontend.rs`.

Building a program that calls any of these needs SDL2 linked explicitly --
`star build foo.star -L sdl/lib/x64 -l SDL2` -- and `sdl/lib/x64/SDL2.dll`
discoverable at run time (next to the built `.exe`, or on `PATH`), the same
kind of extra-linking requirement `tcp_*`'s `-l ws2_32` already established.
28 new tests added, all passing end-to-end against a real, headless
`SDL_VIDEODRIVER=dummy` run (confirmed capable of a full init/create-window/
create-renderer/draw/read-back cycle before any of this was wired into the
compiler) rather than just IR-shape assertions -- covering the full window
lifecycle, a full clear/pixel/rect/line/present frame, keyboard/mouse state,
real measured `delay`/`ticks` timing, and the null-handle abort path every
other `ptr`-handle builtin in this codegen already has.

### 5. Module system: re-exports, search paths, manifest
Needed once any program grows past a few files. Current system only inlines one
relative-path file at a time with no transitive symbol visibility.
- ~~Transitive re-export so `a` importing `b` importing `c` can reach `c`'s symbols~~
  -- done: `a::b::c::item` (arbitrary depth, not just one extra hop) now resolves
  cleanly. Turned out to need no new resolution machinery at all: `modules::resolve`
  already inlines nested imports bottom-up, so by the time `b` gets `b__`-prefixed
  while `a` imports it, anything `b` itself imported from `c` is already a genuine
  top-level item of `b`'s own flattened module named `c__item` -- one more `b__`
  prefix lands exactly on `b__c__item`, and `mangle_name` (`src/modules.rs`) is pure
  string concatenation, so chaining it at parse time reproduces that name with no
  need to know what `b` actually imports. Fixed by generalizing the parser's
  single-hop `alias::name` qualified-path handling into an arbitrary-depth loop in
  the three places it's duplicated: `parser::expr::parse_primary` (expressions),
  the mirrored `parse_pattern` (match patterns), and `parser::parse_type_inner`
  (type annotations) -- each now walks `seg::seg::...::final`, chaining
  `mangle_name` per segment, with the terminal segment still told apart as a call/
  struct-literal/bare-ident by the pre-existing capitalization convention, and an
  `EnumName::Variant` pair only recognized as the *last* two segments (variants
  aren't themselves further indexable via `::`). This *replaces* the previous
  round's deliberate rejection of this exact shape (`"...not transitively
  re-exported..."`, added specifically to give a clean diagnostic instead of a
  fabricated undefined-symbol error) now that the shape is actually supported end
  to end. A wrong guess at an intermediate segment (typo, or a name that isn't
  really re-exported) still produces a clean, ordinary "undefined symbol"
  diagnostic from the checker on the unresolvable mangled name -- the same
  behavior a typo in a single-level qualified path already had, not a new failure
  mode. 12 new/updated tests (1111 total, up from 1107): parser-level chained-
  mangling assertions for expressions/patterns/types, and real `clang`-compiled
  end-to-end runs covering two hops (struct + free function), an enum variant
  reached transitively, three hops (guarding the loop genuinely generalizes past
  "one extra segment"), and a transitively-referenced nonexistent symbol still
  failing cleanly. New example `examples/reexport_main.star` (importing
  `examples/reexport_lib.star`, which itself imports the pre-existing
  `examples/geometry_lib.star`) mirrors `modules_main.star`'s single-hop coverage
  one level deeper, confirmed with a real run (`dot: 11` / `circle area: 12` /
  `unit circle area: 3`).
- Search-path resolution instead of hand-written relative paths everywhere.
- Minimal package manifest (name, version, entry point) — defer a full package
  manager/registry until there's more than one real multi-file project to learn from.

### 6. Expand core standard library
The current 28 builtins cover almost no string/collection manipulation beyond
`List<T>`. Grow incrementally as real programs (see #8) expose actual gaps
rather than speculatively.
- ~~String ops: split/join/trim/replace/contains/format beyond f-strings~~ --
  done: `str_contains`/`str_starts_with`/`str_ends_with`/`str_index_of`/
  `str_trim`/`str_replace`/`str_split`/`str_join` landed as free functions
  (`crate::codegen::builtins`/`crate::codegen::list`), the same free-function
  surface shape `bytes_from_str`/`symbol_name` already established rather
  than new method-call grammar. `str_split`/`str_join` reuse `List<str>`'s
  existing RC/copy-on-write object layout wholesale (no new type). Every
  argument is normalized through a new `Codegen::emit_str_or_empty` (a
  `select` against a shared `@str.empty` global constant) before reaching
  `strlen`/`strstr`/`strncmp`/`strcmp`, all undefined behavior on a genuine
  null pointer -- `str`'s zero value is `null` (a despawned arena slot's
  field, for instance), and a per-call-site branch the way
  `emit_str_index`/`emit_ord` already guard against this would have meant
  repeating that branch in eight new builtins instead of once. An empty
  `needle`/`prefix`/`suffix` always matches (mirroring C's `strstr`'s own
  convention); an empty `old` in `str_replace`/empty separator in
  `str_split` are each a documented, deliberate no-op (unmodified `s`, and a
  single-element list holding all of `s`) rather than looping forever with
  nothing to advance past. `str_split` builds its result list via a local
  growable buffer (`malloc`/`memcpy`/`free`, doubling on grow) since the
  element count isn't known ahead of the scan -- the same recipe `Symbol`'s
  intern table already uses, just against local `alloca`s instead of
  globals. 11 new tests added (1107 total, up from 1096, all green),
  including a real despawned-arena-slot null-`str` safety test across all
  eight builtins and a 200,000-iteration sustained-allocation leak check. One
  pre-existing test (`runtime_extern_ptr_round_trip_end_to_end`) had picked
  `strstr` as its example `extern "C" fn` precisely because it wasn't yet a
  reserved runtime symbol; updated to use `strpbrk` instead now that
  `str_contains`/`str_index_of`/`str_replace`/`str_split` declare `strstr`
  unconditionally. See `examples/strings.star`.
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
- ~~BitField<N> / Flags<E> (docs/design.md §8, "Bit-level types")~~ -- done:
  `BitField<N>` (a packed bit register, N in `{8,16,32,64}`, lowering to a
  bare `i{N}`) and `Flags<E>` (a typed bitflag set over a fieldless enum,
  lowering to a bare `i64` mask) landed, closing out §8 entirely. Both expose
  a free-function surface (`bit_get`/`bit_set`/`bit_clear`/`bit_toggle`/
  `bit_and`/`bit_or`/`bit_xor`/`bit_not`, `flags_has`/`flags_with`/
  `flags_without`/`flags_is_empty`) instead of new bitwise-operator grammar
  (`&`/`|`/`^`/`~` still don't exist in this language) -- see
  `docs/design.md`'s Type System plan and `examples/bitfield.star`/
  `examples/flags.star`.
- ~~Fill out math builtins as needed (trig, log/exp, etc.)~~ -- done:
  `sin`/`cos`/`tan`/`asin`/`acos`/`atan`/`atan2`/`exp`/`exp2`/`log`/`log2`/
  `log10` landed alongside the pre-existing `sqrt`/`pow`/`floor`/`ceil`, same
  shape: dispatched by name ahead of the ordinary function table, always
  `Float`-typed (an `int` argument is promoted, mirroring `sqrt`'s own
  `promote_to_float`), lowered to LLVM's target-independent float intrinsics
  (`llvm.sin.f32`/etc., `Codegen::emit_math_unary`/`emit_math_binary_f32` --
  already generic over any unary/binary float intrinsic, so no new codegen
  helper was needed) rather than libm symbols, so no extra `-l` linker flag
  is needed to resolve them, same as `sqrt`/`pow` already established.
  Confirmed live on this project's actual LLVM/clang version (22) that every
  one of these names -- including `tan`/`asin`/`acos`/`atan`/`atan2`, which
  weren't real LLVM intrinsics on older toolchains and would otherwise have
  needed libm's `tanf`/`asinf`/etc. instead -- assembles and links cleanly
  with no extra flag, before writing any lowering code against them. 8 new
  tests added (1119 total, up from 1111): arity/type-check validation for
  all 12 names (mirroring the pre-existing `sqrt`/`pow` checks),
  `is_builtin_name` collision coverage (an `extern "C" fn sin` is rejected,
  same as the pre-existing `abs` case), and five real `clang`-compiled
  end-to-end runs -- known trig/inverse-trig values including all four
  `atan2` quadrants plus the `(0, 0)` origin case, `exp`/`exp2`/`log`/`log2`/
  `log10` at exact powers of their respective base, out-of-domain inputs
  (`log` of a non-positive number, `asin`/`acos` past `[-1, 1]`) confirmed to
  produce IEEE-754 `-inf`/NaN rather than crashing or trapping, and `int`-
  argument promotion. New example `examples/trig_log.star`.

### 7. Wire up reflection into an actual runtime feature
~~`@export`/`@tweakable` currently only emit descriptive metadata strings —
there is no hot-reload runtime or file watcher consuming them yet.~~ -- an
in-process runtime consumer is now done: `reflect_get_i32`/`_f32`/`_bool`,
`reflect_set_i32`/`_f32`/`_bool`, and `reflect_has_field` (`crate::codegen::
reflect`) read/write a decorated field by a genuine *runtime* `str` name, not
just a compile-time-known one — the actual missing piece, since the
metadata-string emission alone had no consumer at all. Scoped to `i32`/
`float`/`bool` fields (none carry RC-managed content, so a write never needs
to release/retain anything); a name matching nothing decorated of the right
type is a safe fallback (`0`/`0.0`/`false` on read, a no-op on write), the
same convention an out-of-bounds `List<T>` index already uses. `reflect_set_*`
additionally only ever matches a field that's *also* `mut` (a plain, non-`mut`
`@export` field stays read-only through this path too, matching what an
ordinary `s.field = ...` assignment would already reject) and rejects a bare
`Table<T>` index as its first argument (the same `table[i].field = v` hazard
`Checker::writes_through_table_index` exists to catch elsewhere — `emit_place`'s
documented disconnected-copy fallback for a `TableIndex` would otherwise make
the write silently vanish). See `docs/language_reference.md`'s "Runtime field
access by name" section and `projects/snake/main.star`'s `Tuning::
load_from_file` for a full worked example (a plain-text `key=value` config
file applied to `@tweakable` fields at startup, no recompiling needed to try
a new value).

A full external-process hot-reload tool (`docs/features.md` §4's original
"IPC/shared-memory with a running game" pitch) is still open — this closes
the in-process half (a real way to read/write by name at all), not a file-
watcher or editor-side tooling, which was never this checker/codegen's job
to provide on its own.

### 8. Build one real, non-toy program in Star
Everything in `examples/` and `tests/` tops out around ~40 lines of
single-feature demos. FFI and file I/O are now done, which is enough to write
a small file-backed tool; dogfood the language on one program larger than a
toy — this will surface real gaps faster than speculative stdlib growth, and
is the best validation that the "useful programs today" bar has actually
been cleared.

## Last actions:
Feature round: reflection runtime (todo.md #7, "wire up reflection into an actual
runtime feature" — previously `@export`/`@tweakable` only ever emitted a
descriptive `name:offset:type:decorators` metadata string per struct
(`Codegen::emit_reflect_metadata`), with confirmed-zero in-process consumers
anywhere in the codebase before this round). See #7 above for the full
writeup. New surface: `reflect_get_i32`/`reflect_get_f32`/`reflect_get_bool`
(read a decorated field by a runtime `str` name, safe `0`/`0.0`/`false`
fallback on no match), `reflect_set_i32`/`reflect_set_f32`/`reflect_set_bool`
(write one, safe no-op on no match, `mut`-gated both on the receiver and on
the matched field itself), and `reflect_has_field` (probe whether a name is
reflectable at all before picking a typed getter/setter) — seven new
builtins total, touching every layer the same way a from-scratch builtin
family always does here (no lexer/parser/AST changes needed, since every one
is an ordinary `name(args...)` call): `Checker::builtin_return_ty` for name
registration, a new `check_reflect_struct_arg`/`struct_has_decorated_field_of_ty`
pair in `Checker::check_builtin_call_args` for arg validation (struct-typed
first argument, at least one matching decorated field of the right
primitive type actually existing — the one static half of "does this call
make sense" possible when the field itself is only named by a runtime
string), and a new `crate::codegen::reflect` lazily-generated-and-cached
per-`(struct, type)` `strcmp`-chain accessor function (mirroring
`Codegen::eq_fn_name`'s existing lazy-generate-and-cache shape from
`crate::codegen::eq` almost exactly), reusing `Codegen::emit_place` — already
capable of resolving any local/`self`/field-chain to a real pointer, just
never previously exposed to a builtin this way — as the "give me a pointer
to this struct" primitive rather than inventing new address-of syntax.
Deliberately scoped to `i32`/`float`/`bool` fields only (matching this
round's own MVP mandate): none of the three carry RC-managed content, so a
`reflect_set_*` write never needs to release an outgoing value or retain an
incoming one, sidestepping a real complication a future `str`/`List<T>`/...
extension of this same mechanism would have to solve properly.

This round found and fixed two real gaps in its own new surface before
either shipped (not pre-existing bugs — both are specific to the new
`reflect_set_*` write path, caught by design review before writing the
first test, then confirmed live):
1. **A decorated-but-not-`mut` field would otherwise have been silently
   writable through `reflect_set_*`, bypassing the same immutability an
   ordinary `s.field = value` assignment already enforces.** `@export`
   alone only promises hot-reload *visibility*, not writability (`@tweakable`
   is the one that implies "meant to be retuned") — but nothing before this
   fix distinguished the two once a name reached codegen's generated
   `strcmp` chain. Fixed by threading a `require_mut` flag through both
   halves of the field-matching logic (`Checker::struct_has_decorated_field_of_ty`,
   `Codegen::reflect_decorated_fields_of_ty`): `reflect_get_*` passes
   `false` (reading a non-`mut` field is always safe), `reflect_set_*`
   passes `true`, so a non-`mut` decorated field simply never gets a
   comparison branch in the generated setter at all — a name that happens
   to match one is indistinguishable from a name that matches nothing,
   both falling through to the safe no-op.
2. **`reflect_set_i32(t[i], "field", v)` (a bare `Table<T>` index as the
   first argument) would otherwise have silently done nothing, the exact
   `table[i].field = v` hazard `Checker::writes_through_table_index` exists
   to catch elsewhere.** `emit_place`'s documented disconnected-copy
   fallback for a `TableIndex` base (a `Table<T>` element's fields live in
   independent column buffers with no single addressable struct to project
   into) means a write through it always targets a throwaway temporary, not
   the real table. The existing `Checker::check_mut_receiver`'s own
   table-index hazard check doesn't catch this shape on its own — it was
   written for a *chain* bottoming out at a `TableIndex` (`t[i].field`), not
   a bare `t[i]` passed directly, which is exactly what `reflect_set_*`'s
   first argument legitimately can be. Fixed with an explicit, unconditional
   `Checker::writes_through_table_index(&args[0])` check ahead of the
   ordinary `mut`-receiver gate.

46 new tests added (all green): parser/checker-level arity/type/mut/
table-index validation (mirroring `get_pixel`/`str_join`'s own
`check_builtin_call_args` coverage style), two codegen IR-shape assertions
(accessor generation is cached/reused across call sites, exactly like
`eq_fn_name`; a non-`mut` field is excluded from the generated setter's
`strcmp` chain but still present in the getter's), and end-to-end runtime
round trips for all three primitive types, the safe-fallback path on both
read and write, the `mut`-field exclusion, `self`-based access from inside
an `impl` method, a `Field`-chain receiver (`container.stats`), two
unrelated structs sharing a field name not cross-contaminating (confirmed
the per-struct accessor-function cache is keyed correctly even though the
underlying field-name string constants are deliberately deduplicated and
shared across structs), a struct with several decorated fields of the same
type resolving each name correctly (not just "first" or "last"), and
`@export`/`@tweakable`/both-stacked all being equally reflectable.
`projects/snake/main.star` now dogfoods this for real: `move_interval_ms`
moved off `Stats` onto a new dedicated `Tuning` struct alongside two new
`@tweakable` knobs (`particle_gravity`, `particle_life`) and a new
`particles_enabled` toggle, and `Tuning::load_from_file` (a plain-text
`key=value` config file, `projects/snake/tweaks.txt`) applies them at
startup via these exact builtins — a real, if minimal, "edit a text file,
rerun, no recompile" workflow, confirmed live (`SDL_VIDEODRIVER=dummy`)
with a present tweaks file, a missing one (falls back to compiled-in
defaults, mirroring `save::load_high_score`'s own convention), and one
containing an unrecognized key (logged and skipped, not fatal). All
buildable examples still `star build` cleanly (same pre-existing
`examples/geometry_lib.star`/`examples/reexport_lib.star` no-`main`-by-design
exception, and the same pre-existing, unrelated `examples/extern_ffi.star`/
`strstr` collision noted every round since the string-builtins round).

### Previous round

Bug-hunting round 8 (not a feature round): targeted the newest feature commits landed since
round 7 that hadn't gone through a dedicated audit round of their own -- `const`, generic
struct methods, spawn-expression handles, configurable arena capacity, and fieldless-enum/
struct `==`/`!=` legalization, plus this round's own "reflection runtime" feature commit --
each had its own inline tests written alongside it, but (unlike every prior round's target)
none had been through a second pass looking specifically for gaps between what shipped and
what the surrounding type system actually promises. 3 confirmed bugs found and fixed -- one a
"the entire feature silently doesn't work outside its one demonstrated case" gap, the other
two a matched pair of cross-cutting checker-state corruption bugs reachable from any
generic-instantiation call site, not a crash in any case; 7 new tests added (1325 total, up
from 1318, all green). Full suite (`cargo +stable-x86_64-pc-windows-gnu test --release`)
passes clean.

**On-demand generic monomorphization mid-block silently corrupted the enclosing function's
`mut`-variable tracking (1, real, cross-cutting -- confirmed via a real `star check` run
before the fix)**: `Checker::check_block` -- the entry point for type-checking *any* function
body -- unconditionally called `self.mut_vars.clear()` at its start, on the unstated
assumption that it's only ever entered "fresh," once per top-level function, in an order that
never nests. That assumption is false: `instantiate_struct`/`instantiate_enum`/
`instantiate_generic_fn`/`instantiate_impl_methods` (the on-demand monomorphization paths
behind a generic struct/enum/function/method's *first* use anywhere in a module) all
eventually call `check_fn` -> `check_block` to type-check the freshly-synthesized item's own
body -- and that can happen *mid-statement*, while some unrelated enclosing block's own
statement loop is still in progress (e.g. the first call to a generic struct's method inside a
`while` loop's body). The nested `check_block` call's `.clear()` wiped out the *enclosing*
block's live `mut_vars` set (a single `Checker`-wide field, not scoped per call) for the rest
of that block, so a `mut` variable declared earlier in the very same block -- a loop counter,
critically -- would spuriously fail `` cannot assign to `i` -- it was not declared `mut` ``
on every assignment *after* the point where the first not-yet-instantiated generic use
appeared, with nothing about `i` itself having changed. Confirmed via a real repro: `let mut i
= 0` followed by a `while i < N:` body calling a generic struct's method before `i = i + 1`
failed to type-check at all. This is a plausible real-world footgun, not just a crafted edge
case -- "declare a mutable loop counter, then use a generic collection/helper type for the
first time later in the same loop body" is an extremely ordinary shape (every `Table<T>`/
`Map<K,V>`/`Set<T>`/`Option<T>`/`Result<T,E>` first-use inside a loop is exactly this
trigger, once *any* other generic use in the whole preceding module hasn't already forced the
same instantiation first). Fixed with the minimal, general, root-cause fix: `check_block` now
`std::mem::take`s (rather than `.clear()`s) `self.mut_vars` -- still handing the freshly
entered function body an empty set to populate from its own params, exactly as before -- and
restores the caller's original set once this function body is fully checked, so an
interruption partway through an enclosing block's own statement loop leaves that block's
tracking exactly as it was once control returns. 2 new tests: the exact generic-struct-method
repro, and the same shape triggered by a generic *function* instead (`instantiate_generic_fn`)
to confirm the fix is the shared root cause, not something that happened to only patch one
call site.

**Same root hazard, second field: on-demand generic monomorphization mid-loop also corrupted
`loop_depth`, spuriously rejecting a real `break`/`continue` (1, real -- confirmed via a real
`star check` run before the fix)**: `Checker::check_fn_with_self_ty` -- also, like
`check_block` above, the entry point for type-checking any function/method body, including one
entered on demand mid-statement -- unconditionally did `self.loop_depth = 0` at its start, with
a comment explicitly (and, it turns out, wrongly) calling this "defensive" on the assumption
loop nesting could only ever already be `0` there. The exact same nested-monomorphization-
mid-loop trigger as the `mut_vars` bug above (a generic struct's method called for the first
time inside a `while` loop) zeroed the *enclosing* loop's `loop_depth` once the nested,
loop-free method body finished checking, so a `break`/`continue` appearing later in that same
loop body was rejected with `` `break` outside of a loop `` even though it was textually
inside one. Confirmed via a real repro: a `while` loop calling a generic struct's method before
its own trailing `if ...: break` failed to type-check. Fixed the same way: save `loop_depth`
before resetting it for the freshly-entered function body, restore the caller's value once that
body is fully checked (placed alongside the pre-existing `current_ret_ty` save/restore
`check_fn_with_self_ty` already had -- confirming that one, at least, was already following the
correct pattern; `loop_depth`'s own reset was the one spot in this function that hadn't been).
2 new tests: the exact `break`-after-generic-method-call repro, and a bare `break` outside any
loop still correctly rejected (guarding the fix didn't also weaken the underlying check).

**Top-level `const` was completely unusable for every numeric type except `i32`/`f32` (1,
real -- confirmed via real `star check` runs before the fix)**: `const X: i8 = 100 as i8`
failed with "this cast is not supported in a constant expression", and even the more basic
`const X: i8 = 100` (no cast at all) failed with `` `const X: I8` but the value has type
`Int` `` -- despite `docs/language_reference.md`'s "Top-Level Constants" section explicitly
documenting "a numeric cast" as a supported constant-expression form, and despite the exact
same cast being legal everywhere else in the language. Root cause, two compounding gaps in
`src/types/mod.rs`: (1) `ConstValue::Int`/`Float` carried no width/type tag at all -- every
folded integer constant was implicitly `i32`, every float implicitly `f32` -- so
`ConstValue::into_typed_expr` always rebuilt a bare `Ty::Int`/`Ty::Float` literal regardless
of the `const`'s own declared type, guaranteeing a type mismatch for any narrower/wider
declared type even when the value obviously fit; (2) `fold_const_expr`'s `Cast` arm only
special-cased the `Int <-> Float` pairing (i.e. `i32 <-> f32`), rejecting every other numeric
cast (`as i8`/`as u8`/`as i16`/`as u16`/`as u32`/`as i64`/`as u64`/`as f64`) outright, so even
fixing (1) alone wouldn't have helped -- there was no way to *produce* a narrower/wider
`ConstValue` from an `i32`/`f32` literal to begin with. Fixed by threading the resolved `Ty`
through both `ConstValue` variants and rewriting the `Cast` arm to cover the full numeric
matrix (int/int of any width/signedness via `cast_int_to_ty`, a `Rust`-`as`-chain-based
canonicalization proven bit-identical to `Codegen::emit_cast`'s `trunc`/`sext`/`zext`
lowering; int<->float via signedness-aware `sitofp`/`uitofp`-equivalent conversion; float<->
float relabeling), and re-canonicalizing every arithmetic/unary-negation result to its
operand's width too (so `const X: u8 = (255 as u8) + (1 as u8)` wraps to `0` instead of
silently carrying an out-of-range value forward, matching real `Wrapping<T>`-shaped runtime
overflow behavior) -- `Ty::U64`'s comparison/division additionally needed an explicit unsigned
path (`int_cmp`, and unsigned `wrapping_div`/`wrapping_rem`) since its canonical `i64` storage
can be negative-looking for a value past `i64::MAX` (e.g. `(0 as u64) - (1 as u64)` folding to
`u64::MAX`), the one width where plain signed `i64` comparison/division would silently give
the wrong answer; every narrower unsigned width's canonical value is always non-negative, so
it doesn't matter there either way. `char` casts were deliberately left unfolded (a
documented, unchanged gap, not a regression) -- unlike every numeric pairing, a `char`
conversion can fail (not every `i32` is a valid Unicode scalar value) with no existing runtime
convention this compiler's own unchecked runtime `char` cast establishes to match. A
`Ty::F64`-typed `ConstValue` is deliberately never lowered straight to a bare
`TypedExpr::Float` (`Codegen::emit_expr`'s `Float` arm always renders `f32`-shaped literal
text regardless of the node's own `Ty` tag) -- instead wrapped in the identical `f32`-literal-
then-`fpext` `TypedExpr::Cast` shape a real `<literal> as f64` already produces, reusing
already-correct codegen instead of teaching it a new literal form. 3 new tests: every non-
default numeric width accepted via an explicit cast (checker-level), a bare un-cast literal
against a narrower declared type still rejected (guarding the fix doesn't also legalize
*implicit* literal narrowing, which the rest of the language doesn't support either), and a
runtime end-to-end round trip covering `u8`/`i8` wraparound, signed-vs-unsigned ordering, and
`u64` unsigned comparison/division computed from a wrapping subtraction that goes negative
internally.

**Areas audited with no bugs found**: the reflection runtime's struct-name/field-type cache
keying (generic struct instantiations register under their own mangled name, so no cross-
instantiation collision), `emit_place`'s rvalue-spill fallback composing correctly with
`reflect_get_*` called on a non-place struct expression (a fresh struct literal or a function
call's return value), fieldless-enum/struct `==`/`!=` codegen's transient-value release
composing with nested structs and `str` fields under sustained loop pressure (re-confirmed,
not just re-read), array/`Ring<T,N>` sizes rejecting a `const`-typed size expression with a
clean, specific diagnostic rather than a confusing fallback (a real, if narrow, unsupported-
combination gap -- `[i32; N]`/`Ring<i32, N>` require a literal, not a `const` reference --
left as documented out-of-scope rather than a bug, since neither the language reference nor
this round's own `const` feature ever claimed that combination was supported), and the
diamond-dependency/direct-duplicate `CallId` distinction in `crate::modules::dedupe_by_origin`
for `const` items specifically (both paths already had dedicated tests from the original
"Top-level `let`/`const`" commit; re-run and re-read, not re-litigated). After finding the
`mut_vars`/`loop_depth` pair, every other single-instance `Checker` field that looks like
per-call "current context" scratch state (`current_ret_ty`, plus the pre-existing lambda-body/
`frame:`-block `loop_depth` save/restore pairs in `src/types/expr.rs`/`stmt.rs`) was
specifically re-read for the same "reset with no restore, reachable from a nested `check_fn`
call" shape; none of the others had it -- `current_ret_ty` already saved/restored correctly,
and the other two `loop_depth` resets are both already paired with their own save/restore for
a different reason (a lambda/`frame:` body's own loop nesting must not let a `break`/`continue`
cross that boundary either direction). Configurable arena capacity and spawn-expression handles
were both read but not driven to a repro this round -- left genuinely unaudited (not
"audited, clean") pending a future round, since this round's time went to following the
`mut_vars`/`loop_depth` thread instead once it turned up.

### Previous round

Bug-hunting round 7 (not a feature round): targeted the three newest, least-audited feature
surfaces landed since round 6 -- the string builtins (`str_contains`/`str_starts_with`/
`str_ends_with`/`str_index_of`/`str_trim`/`str_replace`/`str_split`/`str_join`), transitive
module re-export (`a::b::c::item` arbitrary-depth chains), and the trig/log math builtins
(`sin`/`cos`/`tan`/`asin`/`acos`/`atan`/`atan2`/`exp`/`exp2`/`log`/`log2`/`log10`) -- plus a
cross-cutting pass combining all three with each other and with existing memory/generics
machinery. Four parallel audits were attempted as isolated git worktrees (this round's usual
shape), but all four were killed mid-run by a session API usage cap before committing any
work; rather than retry the same background-agent approach against the same cap, the round
continued as a single direct, sequential audit instead. 1 confirmed bug found and fixed; 3 new
tests added (1122 total, up from 1119, all green). Full suite
(`cargo +stable-x86_64-pc-windows-gnu test --release`) passes clean.

**Qualified-path generic turbofish silently misparsed as a comparison (1, real -- a silent
miscompile into a cascade of unrelated errors, not just a missing feature)**:
1. A generic struct or enum constructed through a qualified module path with an explicit
   turbofish (`lib::Box<i32>(5)`, `lib::Option<i32>::Some(5)`, and the same shape at any
   transitive chain depth) was silently misparsed as a chained comparison expression instead
   of a qualified generic construction. Root cause: `parse_primary`'s qualified-path loop
   (`src/parser/expr.rs`, the same loop round 6-era's "Modules expansion" round generalized to
   arbitrary depth) only ever checked for `(` or `::` immediately after each segment -- unlike
   the *unqualified* `name<T>(...)` case a few lines above it, which already probes for a
   turbofish via `try_parse_type_args()` (a speculative parse that only commits when the `<...>`
   is immediately followed by `(` or `::`, backing off cleanly to let `<` fall through to
   ordinary comparison parsing otherwise -- necessary since Star doesn't reserve capitalized
   identifiers, so `Foo < Bar` is exactly as legitimate as `Foo<Bar>(...)`). The qualified-path
   loop never got the equivalent probe, so `<i32>(5)` was left completely unconsumed and fell
   through to the caller's ordinary binary-operator parsing, turning `lib::Box<i32>(5)` into
   `(lib__Box < i32) > (5)`. Confirmed via a real pre-fix `star check`: this produced a cascade
   of unrelated diagnostics ("undefined name `i32`", "`<` is not supported between
   `Named(\"unknown\")` and `Named(\"unknown\")`", "no field `value` on type `Bool`") instead of
   either constructing the value or reporting one clean, on-topic error -- exactly the kind of
   silent-miscompile-into-noise failure mode this round's methodology is looking for, not a
   crash. Fixed by adding the identical speculative `try_parse_type_args()` probe right after
   each segment in the qualified-path loop (mirroring the unqualified case exactly), threading
   the parsed type args into both `Expr::StructLit` and `Expr::EnumVariant` (previously
   hardcoded to `Vec::new()` in this loop) so both the plain-struct and generic-enum-variant
   qualified shapes work, at any chain depth. `parse_pattern`'s mirrored qualified-path loop was
   checked and needs no equivalent fix: `<` is reserved for comparison *patterns* at the top of
   `parse_pattern` (`TokenKind::Lt => self.compare_pattern(...)`), so explicit turbofish syntax
   was never grammatically reachable in pattern position to begin with (a match arm's scrutinee
   type is already known, so it doesn't need one) -- confirmed by reading, not just assumed. 3
   new tests: a single-hop generic struct construction with turbofish (both positional and named
   args), a two-hop transitive generic enum variant construction with turbofish (guarding the
   fix composes with the chain-depth generalization, not just a single hop), and a same-shape
   construction *without* an explicit turbofish (guarding the new probe doesn't disturb the
   pre-existing, already-working inferred-type-argument path).

**Areas audited with no bugs found**: the eight string builtins' RC/allocation correctness
under aliasing (`str_replace(x, x, x)`), shrinking/growing replacements, overlapping-match
non-overlapping-replace semantics, a null `str` (a despawned arena slot's zero-valued field)
passed as the *non-`s`* argument (`old`/`new`/`sep`/needle) to all eight builtins (the existing
null-safety test only covered the `s` position), `str_split`'s growable-buffer growth path
under heavy fan-out plus subsequent user `.push()` onto the returned `List<str>`, and
`str_split`/`str_join`/`str_replace` composed in a 200K-iteration loop (pre-existing leak test,
re-confirmed); confirmed none of the eight touch any shared global state (unlike `Symbol`/
`rand`'s process-wide tables), so no `par`/`swarm` ban-list gap exists for them. All 12 trig/log
builtins' `extern "C" fn` name-collision rejection (previously only `sin` had a test; the other
11 confirmed individually), `Wrapping<T>` argument rejection with a clean diagnostic, NaN
propagation through a chained call (`sin(sqrt(-1.0))`), `log`/`log2`/`log10` of exactly `1.0`
(exactly `0.0`, no floating-point drift), `exp(log(1.0))` round-tripping to `1.0`, and a 5-deep
chained call (`sin(cos(tan(atan(atan2(...)))))`) for both correctness and stack safety; confirmed
by reading `emit_math_unary`/`emit_math_binary_f32` that none of the 12 touch shared state
either, so likewise no `par`/`swarm` gap. Cross-cutting: a 2-hop transitively-re-exported
generic struct (`Sample<T>`) constructed with an explicit turbofish through the chain, whose
constructing function's own body calls both a string builtin (`str_trim`) and a trig builtin
(`sin`) internally -- full composition confirmed correct end to end (mangling, monomorphization,
and both builtin call classes all compose cleanly with each other and with the transitive-import
machinery).

### Previous round

Feature round: math builtins (todo.md #6's last remaining bullet, closing out the "Expand core
standard library" tier entirely -- every other bullet in that section was already done). See #6
above for the full writeup. 8 new tests (1119 total, up from 1111), one new example
(`examples/trig_log.star`). All other buildable examples still `star build` cleanly (same
pre-existing `examples/geometry_lib.star`/`examples/reexport_lib.star` no-`main`-by-design exception
as every prior round, and the same pre-existing, still-unfixed `examples/extern_ffi.star` /
`strstr` collision noted last round -- unrelated to this one, touches strings/FFI not math).

### Previous round

Feature round: transitive module re-export (todo.md #5's first bullet, the module-system tier's
only item with any work done on it before this round). See #5 above for the full writeup. 12
new/updated tests (1111 total, up from 1107), one new example (`examples/reexport_main.star` +
`examples/reexport_lib.star`). All other buildable examples still `star build` cleanly (same
pre-existing `examples/geometry_lib.star`/now also `examples/reexport_lib.star` no-`main`-by-design
exception as every prior round) -- one pre-existing, unrelated failure noticed in passing and left
unfixed as out of scope: `examples/extern_ffi.star` declares `extern "C" fn strstr(...)`, which now
collides with a compiler-reserved symbol (`str_contains`/`str_index_of`/`str_replace`/`str_split`
declare `strstr` unconditionally as of the stdlib round, `todo.md` #6) -- predates this round and
touches strings/FFI, not modules.

### Previous round

Bug-hunting round 6: four parallel deep audits, run as isolated git worktrees and merged back by
hand afterward (three were pure test-file additions with zero source changes -- `tests/frontend.rs`
merge conflicts were trivial same-spot-append conflicts, resolved by concatenation), each required
to reproduce every candidate via a real compile+run before being reported, not just read from code.
Scope was deliberately the newest, least-audited surface: `BitField<N>`, the `Color`/`Color32`/
`PaletteIndex`/`Mat2`/`Mat3`/`Quat` geometry types, the SDL2 bindings (going deeper than round 5's
own SDL pass), and a fourth audit specifically targeting *combinations* of all of the above with
the existing generic/memory machinery (`List`/`Map`/`Set`/`Ring`/`Table`, generics, `arena`/
`GenRef`/`Handle`, closures, `par`/`swarm`, reflection) that no single-type audit would think to
try. 1 confirmed bug found and fixed, a real segfault; 47 new tests added (1096 total, all green,
up from 1049). Full suite (`cargo +stable-x86_64-pc-windows-gnu test --release`) passes clean after
the merge.

**Enum payload alignment (1, severe -- a real, reproducible segfault)**:
1. Any payload enum (`Option<T>`/`Result<T,E>`/a user `enum`) carrying a field of a wide-aligned
   aggregate type (`Vec3`/`Vec4`/`Mat2`/`Mat3`/`Mat4`/`Quat`/`Color` -- every one a native
   `<N x float>`/`[N x <N x float>]` LLVM vector/array, 16-byte-aligned on this target) crashed at
   runtime with `STATUS_ACCESS_VIOLATION`. Root cause: the tagged-union struct (`{ i32 tag,
   [W x i64] payload }`) is built entirely out of `i32`/`i64`, so LLVM's own struct-layout algorithm
   computes only 8-byte alignment for it; every `alloca`/heap use of that type therefore got 8-byte
   alignment, but constructing/reading the payload does an implicit-alignment
   `store <4 x float> .., <4 x float>* <bitcast>`, which assumes `<4 x float>`'s natural 16-byte
   alignment when no explicit `align N` is given -- undefined behavior that reliably faulted at
   `-O0` (this project's own test-harness compile path) but not at `-O2` (`star build`'s CLI
   default), making it invisible to any check only ever run through the default-optimized CLI.
   Found via `Map<str, Quat>::get(..)`, which constructs exactly this shape internally
   (`Codegen::emit_construct_enum_variant` in `map.rs`), confirmed with a real `clang -O0` compile
   and run before the fix. Fixed by adding `Codegen::enum_payload_needs_wide_align`/
   `enum_payload_elem_ty` (`src/codegen/mod.rs`): the payload buffer's array element type switches
   from `i64` to `<2 x i64>` (still 8 bytes/lane, but itself 16-byte-aligned) whenever any variant
   needs it, letting LLVM's own layout algorithm compute correct alignment/padding everywhere the
   type is used with no per-call-site `align` overrides needed. `enum_payload_words`/`type_align`/
   `type_size`'s `Ty::Enum` arms updated to match (`src/codegen/mod.rs`, `expr.rs`, `map.rs`,
   `rc.rs`, `reflect.rs`, the last so `@export`/`@tweakable` offsets stay consistent for structs
   containing such an enum field). 2 regression tests added: a direct `-O0` runtime repro and a
   reflection-offset check around a wide-aligned payload enum field.

**Areas audited with no bugs found** (see each audit's own report for the full list): `BitField<N>`
across boundary widths (`8`/`16`/`32`/`64`, confirmed no other width is accepted), negative/
out-of-range bit indices in `bit_get`/`bit_set` (masks via `idx & (width-1)`), sign/truncation
correctness on construction and casts, cross-width rejection for `bit_and`/`bit_or`/`bit_xor`/`==`/
ordering/arithmetic, and as a struct field/`List`/`Map`/`Ring`/`Table`/array element/generic
parameter/closure capture/`Option` payload/`par`-mutated field, plus f-string printing across all
widths through both codegen tables and reflection offsets; SDL2 multiple simultaneous windows (no
hidden shared window/renderer cache -- confirmed via `SDL_GetRenderer` re-derivation per call),
`window_create` with degenerate (negative/zero/huge) dimensions, `draw_rect` with negative/zero
width or height, a window `ptr` handle round-tripped through a struct field/`List<ptr>`/closure/fn
return, `key_down`/mouse polling before any `window_create` (before `SDL_Init` has run -- confirmed
`SDL_GetKeyboardState` still returns a safe zeroed array), double `window_destroy` (correctly hits
the null-handle abort path via the existing bare-variable-nulling convention), and confirmed
`swarm` shares `par`'s exact disjointness-check path so round 5's ban-list fix already covers both;
`Color32`/`PaletteIndex` boundary/truncation behavior, `Mat2`/`Mat3` non-permutation matrix-multiply
correctness and self-composition (hand-computed expected values), `Quat` Hamilton-product rotation
about a genuinely non-axis-aligned diagonal axis (hand-computed), `Mat3`'s real LLVM struct-field
alignment (empirically cross-checked against a standalone `.ll` GEP/ptrtoint probe), swizzle
read/write edge cases (out-of-order writes, duplicate-component-write rejection, reads on a
non-lvalue expression result); and the full cross-cutting sweep -- mixed-type structs (`str` +
`Mat3` + `BitField<16>` + `Color32` + `i32` in one struct) through `arena`/`GenRef`, `List`,
`Map<str,Color32>`, `Ring<Quat,4>` past capacity, `Table<T>` past growth, generic `fn<T>`/`struct
Box<T>` instantiated with the new types, closures capturing them by value (confirmed no spurious
RC-retain/release codegen misapplied to plain-value types), `par`/`swarm` over an arena field of
each new type under real 4-worker parallelism, `@export`/`@tweakable` reflection offsets across a
struct mixing all seven new types (hand-verified against real LLVM padding rules), and a struct of
three new types as a `Set<T>` key (structural-equality dedup).

### Previous round

Follow-up round (not a feature round, not a full audit): closed out the two findings round 5's
`todo.md` writeup explicitly left unfixed as out-of-scope, rather than opened new ground.

1. **F-string interpolation of aggregate vector/matrix types
   (`Vec2`/`Vec3`/`Vec4`/`Mat4`/`Quat`/`Color`/`Mat2`/`Mat3`), fixed**: both f-string codegen paths
   (`emit_print_like` in `src/codegen/builtins.rs`, and the general `TypedExpr::FStr`-as-value path
   in `src/codegen/expr.rs`) only ever special-cased bare scalar types -- every builtin aggregate
   fell through the `%p` catch-all in both, tagging a `<N x float>`/`[N x <N x float>]` register as
   a pointer vararg (confirmed via a real pre-fix `star build` failure, the identical invalid-IR
   `clang` vararg-type-mismatch bug class round 5's own `Color32`/`PaletteIndex` fix addressed, just
   for the much larger remaining set of non-scalar builtin types). Fixed with a new shared helper,
   `Codegen::emit_agg_fstring_lanes` (`src/codegen/vector_math.rs`), called from both paths: reads
   every lane of a vector (`extractelement`) or every row-then-lane of a matrix
   (`extractvalue`+`extractelement`), formats the result as that type's own constructor-call syntax
   (`Vec2(1.000000, 2.000000)`, `Mat2(Vec2(1.000000, 0.000000), Vec2(0.000000, 1.000000))`) so the
   printed form round-trips as valid Star source, and widens each lane to `double` per C's variadic
   promotion rule (mirroring every existing `Ty::Float` arm in both tables). 3 new tests (1049
   total, up from 1046, all green): an IR-shape assertion (format-fragment and vararg-type
   correctness for `Vec2`/`Mat2`), and two real `clang`-compiled runtime round trips covering all
   eight aggregate types across both the value path and the `println(f"...")` direct path,
   including a non-identity `Mat3` and an aggregate mixed with an ordinary scalar in one f-string.
2. **`window_create`/`window_destroy` cycling memory growth, root-caused further (still not a
   Star-codegen fix, but now a materially different, much narrower finding)**: round 5 confirmed
   the growth reproduces identically in a pure C program linked against the same vendored
   `SDL2.dll`, concluding it was "inherent to the vendored SDL2 library" without pinning down
   whether that was true of SDL2 generally or specific to the headless driver both the C repro and
   Star's own tests use (`SDL_VIDEODRIVER=dummy`). Isolated the variable directly: sampled real
   process working-set (`Get-Process`'s `WorkingSet64`, polled every 300ms) across 400
   `window_create`/`window_destroy` cycles of Star's own compiled output (not just the earlier C
   repro), once under `SDL_VIDEODRIVER=dummy` and once with no driver override (the real `windows`
   driver every actually-shipped Star program uses, since nothing sets `SDL_VIDEODRIVER` in normal
   operation). Under `dummy`, working-set climbed monotonically and unboundedly from ~2MB past
   ~207MB over the 400 cycles, matching round 5's finding exactly; under the real driver, it rose
   during the first few cycles and then plateaued, fluctuating in a ~20-36MB steady-state band with
   no sustained growth for the remaining ~390 cycles -- a real leak, but confined entirely to
   `SDL_VIDEODRIVER=dummy`'s own window-recreation path. Left unfixed for the same reason as
   before (no codegen change reaches into a vendored driver's internal accounting), but the
   practical conclusion is now materially better than round 5 left it: no actually-shipped Star
   program is affected, since none of them run under the dummy driver -- only a test process that
   itself cycled windows hundreds of times in a single headless run would be at risk, and nothing
   in this project's own test suite does that (every existing SDL test creates/destroys a small,
   fixed number of windows). Documented at the fix's natural home,
   `Codegen::emit_window_destroy`'s doc comment (`src/codegen/sdl.rs`), so a future round doesn't
   re-derive this from scratch or mistake it for a live risk to real programs.

All 65 buildable examples still `star build` cleanly (same pre-existing
`examples/geometry_lib.star` no-`main`-by-design exception as every prior round).

### Previous round

Bug-hunting round 5 (not a feature round): three parallel deep audits, run as isolated git
worktrees and merged back by hand afterward (source patches applied cleanly; two of the three
audits independently converged on the identical bug and both patched `src/types/
par_analysis.rs` -- reconciled by keeping one fix and dropping the duplicate, folding both
audits' regression tests in since they covered distinct call shapes). Scope was the two most
recently landed, previously unaudited feature surfaces -- SDL2 graphics/input (`todo.md`'s prior
round) and the geometry/vector-math/quaternion/matrix/palette additions ("Expanded types 8/9")
-- plus a dedicated cross-cutting sweep. Each audit was required to reproduce every candidate via
a real `star build`+run (or a real end-to-end `cargo test` case) before reporting it, not just
read from code. 2 confirmed bugs fixed; 6 new tests added (1046 total, up from 1040, all green).
Every buildable example still `star build`s cleanly (same pre-existing `examples/geometry_lib.
star` no-`main`-by-design exception as every prior round).

Two bugs fixed:

1. **SDL2 builtins were fully callable from inside `par`/`swarm` bodies (severe -- real crashes,
   not just a theoretical race)**: `Checker::unsafe_par_fns`'s ban mechanism (`compute_
   unsafe_par_fns`) only ever scans user-declared `fn`/`impl` bodies for `spawn`/`despawn`/
   `frame:`; a builtin free function can never land in that set at all, so nothing stopped a
   `par` body from calling `window_create`/`draw_pixel`/`clear_screen`/`present`/`window_should_
   close`/`key_down`/`mouse_x`/`mouse_y`/`mouse_button_down`/`window_destroy`/`draw_rect`/
   `draw_line` with a captured window handle -- the same blind spot `Symbol(..)`/`rand(..)` had
   before round 3/4's `@sym.lock`/`@rng.lock` fixes, just reached through a builtin instead of a
   user function. Confirmed via two independent real repros (`SDL_VIDEODRIVER=dummy`, 64 arena
   entities across hundreds of ticks all drawing to one shared window/renderer from a `par`
   body): one run hit SDL's own internal assertion failure (`SetDrawState`, `viewport != NULL`,
   `SDL_render_sw.c:644`) from concurrent renderer-state corruption; a narrower repro (`draw_
   pixel`+`clear_screen` racing on the same window) reliably deadlocked outright instead of
   crashing. Unlike `rand`/`Symbol`, a lock isn't the right fix here -- serializing draws to one
   shared canvas across 4 worker threads has no useful "each thread gets its own answer" property
   the way locked `rand_range` still does, and SDL2 itself documents this state as unsafe off the
   initializing thread. Fixed by banning the 12 hazardous builtins outright from `par`/`swarm`
   bodies, mirroring the existing `spawn`/`despawn`/`frame:` ban shape (`src/types/par_analysis.
   rs`); `delay`/`ticks` (`SDL_Delay`/`SDL_GetTicks`, no window/renderer/event state) were tested
   clean and deliberately left unbanned. 3 new tests.
2. **`Color32`/`PaletteIndex` f-string interpolation hit an invalid-IR vararg-type mismatch**:
   round 4's follow-up had ported `emit_print_like`'s full format-specifier/vararg-widening table
   into the general f-string-as-value path (`TypedExpr::FStr` in `codegen/expr.rs`) for every
   bare-scalar type, and the immediately-prior round's `BitField<N>`/`Flags<E>` did get arms --
   but this round's own two newest bare-scalar types, `Color32` (`i32`) and `PaletteIndex`
   (`u8`), fell through the `_ => "%p"` catch-all in both tables, an inconsistent oversight
   specific to this round. Confirmed via a real pre-fix `star build`: `f"color: {c}"` for a
   `Color32` local failed `clang` compilation outright (`'%tN' defined with type 'i32' but
   expected 'ptr'`, a genuine invalid-IR error, not just a wrong runtime value); the `println(f
   "...")` direct path compiled but printed the packed value in hex pointer notation instead of
   decimal, and `PaletteIndex`'s narrower `u8` printed outright garbage since `%p` reads a full
   pointer-width slot off an unwidened register. Fixed by adding both types' arms to both tables
   (`src/codegen/builtins.rs`, `src/codegen/expr.rs`). 3 new tests (IR-shape assertion plus two
   real `clang`-compiled runtime round trips, value path and print-direct path).

**Areas audited with no bugs found** (see each audit's own report for the full list): every SDL
builtin's null/closed/dangling-handle safety, double-`window_destroy`, `key_down`/`mouse_button_
down` boundary clamping (exact 511/512, `i32::MIN`/`MAX` edges), `draw_rect`/`draw_line`/`draw_
pixel`/`clear_screen` with huge/negative/zero-size coordinates, `Color32` out-of-range channel
construction, an SDL window `ptr` field through arena despawn/respawn cycling, `@export`
reflection on a `ptr` window-handle field, `window_should_close`'s event-pump correctness across
both multiple-calls-per-frame and zero-calls-for-many-frames; quaternion/matrix math correctness
against hand-computed expected values (Hamilton product, 90°-rotation composition, `Mat2`/`Mat3`
generalization), degenerate inputs (zero-length quaternion normalize produces NaN via plain
`fdiv`, consistent with this compiler's existing float-op convention), `Color32`/`PaletteIndex`/
`Palette` RC correctness under 40M-iteration stress, structural equality (including NaN
non-self-equality, consistent with pre-existing `Vec2`/`Vec3`/`Vec4`), generics (`List<Quat>`,
`Map<str, Mat4>`), reflection byte-offset/alignment correctness across a mixed-field struct,
dimension-mismatch rejection (`Mat2 * Mat3`, `Mat2 * Vec3`); a full `unsafe_par_fns` completeness
audit across every builtin in the codebase (only the SDL gap above was live -- `Symbol`/`rand`'s
existing locks and every geometry builtin's stateless codegen all verified still correct); mixed
SDL-`ptr`+`Mat4`+`Flags<E>`+`BitField<N>` struct reflection, `List<Entity>` holding `Mat4`+`str`+
`Quat` under 5M push/pop cycles, `Ring<Quat,4>`/`[Mat4;3]` OOB/construction, `Table<Row>` pop with
a mixed `Mat4`+`Option<str>`+`Quat` row, 120-level-deep generic nesting (clean `MAX_EXPR_DEPTH`
rejection), and an f-string mixing `i64`/`Vec3`/`Quat`/`ptr`/`Color32`/`BitField<64>` in one
format string.

One out-of-scope finding, explicitly left unfixed: repeated `window_create`/`window_destroy`
cycling shows unbounded process memory growth under `SDL_VIDEODRIVER=dummy` -- isolated with a
pure C program linked against the identical vendored `SDL2.dll` doing the same `SDL_Init`/
`SDL_CreateWindow`/`SDL_CreateRenderer`/`SDL_DestroyRenderer`/`SDL_DestroyWindow` cycle, which
showed the identical growth pattern, confirming the leak is inherent to the vendored SDL2
library/dummy-driver's window-recreation path, not Star's codegen (`window_destroy` already
correctly calls both `SDL_DestroyRenderer` and `SDL_DestroyWindow`). Also noted, also unfixed and
also pre-existing (not introduced this round): f-string interpolation of aggregate vector/matrix
types (`Vec2`/`Vec3`/`Vec4`/`Mat4`/`Quat`/`Color`/`Mat2`/`Mat3`) hits the same `%p` catch-all and
fails to compile identically -- a materially larger fix (real aggregate-value formatting) than
this round's targeted-fix mandate, and out of scope since it predates every type this round
touched.

### Previous round

Feature round: SDL2 graphics/input bindings (todo.md #4, "window creation + framebuffer/
pixel-blit" plus "input polling (keyboard/mouse)", deferring gamepad and audio), the item this
doc's own roadmap flagged as core to the "game language" pitch but 100% aspirational until now
(`draw_sprite`/`flash_screen`/`wait` were documented in `docs/language_reference.md` with no
backing implementation at all). A new `sdl/` directory vendored at the repo root (SDL2's
headers, x64 import lib, and runtime DLL) is bound as a fixed set of free-function builtins
(`crate::codegen::sdl`) rather than by widening `extern "C" fn` to handle SDL's struct-by-value/
callback parameters -- the same "hand-emit calls to an existing C API" shape `file_io.rs`/
`net.rs` already established for `fopen`/Winsock2, reusing `Ty::Ptr` as an opaque `SDL_Window*`
handle (null on failure, same convention as `file_open`/`tcp_connect`) and the existing
`Color32` type for pixel color, rather than adding a general struct/callback-passing FFI lift
the graphics work alone didn't justify.

14 new builtins: `window_create`/`window_destroy`/`window_should_close` (window lifecycle --
`window_should_close` doubles as the required per-frame `SDL_PollEvent` pump, draining the
whole queue and reporting whether a global `SDL_QUIT` was seen -- an unpumped SDL event queue
makes the OS mark a window "Not Responding" within seconds), `clear_screen`/`draw_pixel`/
`draw_rect`/`draw_line`/`present` (a minimal immediate-mode 2D framebuffer surface), `key_down`/
`mouse_x`/`mouse_y`/`mouse_button_down` (input polling, backed by `SDL_GetKeyboardState`/
`SDL_GetMouseState`), `delay`/`ticks` (frame timing, backed by `SDL_Delay`/`SDL_GetTicks`).
Every drawing/input builtin re-derives its `SDL_Renderer*` from the window handle via
`SDL_GetRenderer` (a real, cheap SDL2 API for exactly this "one renderer per window" case)
rather than the caller juggling a second handle. Every null/closed window handle passed to any
builtin but `window_create` aborts loudly with a diagnostic (`abort_if_null_window`), mirroring
`file_io.rs`'s `abort_if_null_handle`/`net.rs`'s `abort_if_null_socket`; an out-of-range
`key_down` scancode or `mouse_button_down` button number is clamped to a safe `false` instead of
indexing out of bounds or hitting an LLVM `shl` poison value, the same "safe, not panicking"
fix class `BitField<N>`'s own out-of-range bit index needed last round.

Confirmed via a real empirical spike before writing any codegen: a small hand-written C program
linked clean against `sdl/lib/x64/SDL2.lib` using this project's existing `x86_64-w64-windows-
gnu` mingw-target clang (SDL2's MSVC-format import lib links fine under LLD despite the
mingw target), and `SDL_VIDEODRIVER=dummy` (SDL2's own headless video driver) proved capable of
a full init/create-window/create-renderer/draw/read-back cycle with no real OS window --
confirmed by round-tripping a drawn pixel's color back through `SDL_RenderReadPixels` --
*before* any of this was wired into the compiler, derisking the whole approach up front rather
than discovering a linking or headless-testing blocker after the fact. 28 new tests added (1040
total, up from 1012, all green), including real runtime end-to-end coverage (not just IR-shape
assertions) run against that same `SDL_VIDEODRIVER=dummy` headless driver: the full window
lifecycle, a full clear/pixel/rect/line/present frame, keyboard/mouse state, a real measured
`delay(50)`/`ticks()` timing round trip (not a no-op stub), and the null-handle abort path.
`examples/graphics.star` (a bouncing filled square, quitting on close-request or Escape) is this
round's own "build one real, non-toy program" contribution to todo.md #8, alongside every prior
example -- confirmed to run indefinitely under `SDL_VIDEODRIVER=dummy` with no crash via a
timeout-bounded run. Building any program that calls these needs SDL2 linked explicitly
(`-L sdl/lib/x64 -l SDL2`, mirroring `tcp_*`'s pre-existing `-l ws2_32` requirement) and
`sdl/lib/x64/SDL2.dll` discoverable at run time (next to the built `.exe`, or on `PATH`).

Audio playback and gamepad input remain open, deferred as originally planned; a per-window
close button (`SDL_WINDOWEVENT_CLOSE`, as opposed to the global `SDL_QUIT` this round handles)
is a smaller, explicitly noted floor cut for a later round, the same kind of scope cut
`net.rs`'s "no hostname resolution" already documents for `tcp_connect`.

### Previous round

Feature round: `BitField<N>`/`Flags<E>` (docs/design.md §8, "Bit-level types"), closing out
that section entirely -- the smallest of this doc's remaining type-system tiers, and (per
§10's own "lowest-effort, highest-value slice" sequencing note) chosen over §5's much larger
math/geometry tier for this round. Touched every layer (lexer needed nothing new; parser got
one new dedicated `BitField<N>(value)` construction node mirroring `Fixed<Bits,Frac>`'s own
single-turbofish shape, while `Flags<E>(a, b, ...)` needed zero parser/AST work at all, riding
`List<T>`/`Table<T>`'s existing turbofish-plus-call grammar; checker got two new `Ty`
variants plus a dedicated free-function-call-validation surface; codegen got two new modules,
`src/codegen/bitfield.rs`/`src/codegen/flags.rs`). Deliberately built as a free-function
surface (`bit_get`/`bit_set`/`bit_clear`/`bit_toggle`/`bit_and`/`bit_or`/`bit_xor`/`bit_not`,
`flags_has`/`flags_with`/`flags_without`/`flags_is_empty`) rather than new bitwise-operator
grammar, since `&`/`|`/`^`/`~`/`<<`/`>>` don't exist anywhere in this language yet and adding
them would have been a much bigger, unrelated lift. 30 new tests added (975 total, all green,
up from 945); every buildable example still `star build`s cleanly (same two pre-existing,
documented exceptions as every prior round: `examples/geometry_lib.star`'s no-`main`-by-design
case, and `examples/tcp_socket.star` needing its documented `-l ws2_32` flag) -- two new ones,
`examples/bitfield.star`/`examples/flags.star`, added alongside them.

This round found two real bugs of its own, both caught by the new tests before either shipped:
1. **LLVM `shl`-poison on an out-of-range bit index (severe -- real undefined behavior, not
   just a wrong answer)**: `bit_get`/`bit_set`/`bit_clear`/`bit_toggle` computed a bit's mask
   as `1 << idx` with `idx` passed straight through, unmasked, to LLVM's `shl` -- an
   out-of-range shift amount (`idx >= width`, e.g. `bit_get(x, 99)` on an 8-bit `x`) is a
   *poison value* under LLVM's `shl` semantics, not a wrapped one the way x86 hardware `shl`
   (which masks the shift count itself in the CPU) would produce. Confirmed via a real,
   reproducible wrong-answer run before the fix (`bit_get(x, 9)` on an 8-bit register didn't
   reliably agree with `bit_get(x, 1)`, the two indices' 8-bit-mod-reduced values). Fixed by
   masking the shift amount mod the register's width (`idx & (width - 1)`, exact since `width`
   is always a power of two) before it ever reaches `shl`, keeping this in line with this
   compiler's existing "safe, not panicking" convention for other builtin edge cases like an
   out-of-bounds `List<T>` index (`src/codegen/bitfield.rs`'s `emit_bit_mask`). Caught by
   `runtime_bitfield_out_of_range_index_wraps_rather_than_traps_end_to_end`.
2. **A pre-existing stack-safety margin eroded by this round's own match-arm growth (not a
   bug this round introduced from nothing, but one it triggered for real)**: two existing
   regression tests --  `rejects_deeply_nested_parens_does_not_overflow_stack` (500 levels of
   nested parens, meant to fail cleanly well before that via `Parser::MAX_EXPR_DEPTH`) and
   `runtime_moderately_long_binary_chain_end_to_end` (150 chained `+` operators, well under
   `Parser::MAX_BINARY_CHAIN`'s 200-operator promise, meant to fully compile and run) -- both
   started overflowing the real stack for real (`STATUS_STACK_OVERFLOW`, not the intended
   diagnostic) once `BitField<N>`/`Flags<E>`'s new match arms grew `parse_primary`/
   `Checker::infer_expr`/`Codegen::emit_expr`'s already-large stack frames a little further in
   an unoptimized build -- every local a match arm declares counts against one shared frame
   size regardless of whether that arm is ever taken, so *any* feature round's match-arm growth
   erodes this same margin a little, not something specific to this round's own types.
   Confirmed the regression was real, not a test-harness artifact, via a standalone `star
   build` on a 150-operator chain crashing on the OS's own default main-thread stack too, not
   just under `cargo test`. Rather than keep shrinking `MAX_EXPR_DEPTH`/`MAX_BINARY_CHAIN` (a
   real, user-visible regression in how much legitimately-nested/long input compiles, and a
   fix that would only need re-doing again next round), fixed at the root: `src/main.rs`'s
   `main` now runs its actual work on a purpose-spawned 32MiB-stack thread (`MAIN_STACK_SIZE`,
   the same fix real compilers with deep AST recursion, e.g. `rustc`, already use), and
   `.cargo/config.toml` now sets `RUST_MIN_STACK` so `cargo test`'s own per-test threads get
   the same headroom -- a fix that scales with future match-arm growth instead of needing
   another constant retuned every round.

---

### Previous round

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

**Both since fixed, in a follow-up pass** (not part of round 4 itself): `Codegen::
emit_array_repeat` (`src/codegen/array.rs`) now fills slot 0 directly (the original
evaluation's own ownership) and lowers slots `1..N` to a genuine LLVM runtime loop (a
counter `alloca`, `br i1`/`icmp ult` back-edge, mirroring the `for`-loop/linear-scan idiom
used elsewhere in codegen) instead of a Rust-side `for i in 0..count` that emitted the
GEP/store/retain group N times -- emitted IR size and codegen time no longer scale with
`N` (confirmed: codegen for a 500,000-element array-repeat is sub-second, down from
`MAX_INLINE_LEN`'s own 1,000,000-element case previously taking minutes). The general
f-string-as-value codegen path (`TypedExpr::FStr` in `src/codegen/expr.rs`, used whenever
an f-string isn't `print`/`println`'s direct sole argument) only special-cased
`Int`/`Float`/`Str`/`Bool` and silently fell every other type -- `I64` included -- through
a `%p`/`i8*` catch-all that mistagged a plain integer vararg as a pointer; fixed by
porting `emit_print_like`'s (`src/codegen/builtins.rs`) full format-specifier/vararg-
widening table (`I8`/`I16`/`U8`/`U16`/`U32`/`I64`/`U64`/`F64`/`Char`/`Symbol`/`Tick`/
`Duration`/`Instant`/`Wrapping<T>`/`Fixed<Bits,Frac>`) into the value path too. 6 new tests
added covering both (IR-shape assertions plus real `clang`-compiled runtime round trips,
including an out-of-`i32`-range `i64` struct field and every wide integer type
interpolated through the value path).

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