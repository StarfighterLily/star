# Star Compiler — Next Steps

Prioritized from [ASSESSMENT.md](ASSESSMENT.md)'s technical review. Ordered by
risk-to-the-language's-own-thesis and how much each item unblocks real
programs, biggest lever first within each tier.

## P0 — Structural risk (affects every future feature, not just one gap)

1. **Add an IR-validity check ahead of the `clang` boundary.** Several
   confirmed bugs (`frame:` block ending in `return`, trailing `if/else` with
   a bare-ident arm) were `star check`-clean but produced invalid LLVM IR
   that only `clang` caught. At minimum: assert every emitted basic block
   ends in exactly one terminator before handing `.ll` to `clang`, and assert
   every `emit_expr` return value carries its type tag (`reg_of`'s own
   documented convention) before it reaches a `phi`/merge site. This is the
   single highest-leverage fix — it closes an entire *class* of bug the
   hand-rolled textual-IR approach will otherwise keep re-discovering one
   feature at a time. -- Done: See previous work below for details.
2. **Audit every f-string/`print`-family format-specifier table for missing
   type arms.** The fieldless-enum-prints-as-garbage-hex bug (silent wrong
   output, no crash, no diagnostic) is the worst bug class this project has
   shipped, and it was only caught by a human reading console output. Write
   an exhaustive test that round-trips every `Ty` variant through `print`/
   f-string interpolation and fails loudly on any silent fallthrough to a
   catch-all specifier, so the next new type can't ship this bug again. --
   Done: See previous work below for details.
3. **Give `Map`/`Set`/`Symbol` real hash-table backing.** Currently O(n) on
   every operation, which directly contradicts the "AAA entity counts"
   framing used to justify `Symbol` in the first place. This is a purely
   internal change (docs already say so) — no syntax/semantics shift needed,
   just replacing the linear scan with a real hash table behind the existing
   API. -- Done: See previous work below for details.

## P1 — Gaps that block realistic multi-file / at-scale programs

4. **Module search-path resolution + minimal manifest.** `projects/snake`'s
   own dogfooding notes call this "the most significant gap ... still open."
   Every import is a hand-written relative path with no project root, no
   search path, no package identity. Needed before any project bigger than a
   handful of files is comfortable to maintain. -- Done: See previous work
   below for details.
5. **Make `frame:`'s bump-allocator budget configurable per block**, mirroring
   the fix already done for arena capacity (`arena Name: Type = N`). The
   hardcoded 4096-byte cap is easy to blow with unremarkable code (confirmed
   by the doc's own A*-pathfinding example) and there's currently no way to
   size it to the actual workload. -- Done: See previous work below for
   details.
6. **Reconcile the `par`/`swarm` concurrency docs with what's implemented.**
   `docs/design.md`/`docs/features.md` describe cross-system "compile-time
   locks" resolving overlapping component-array access across a tick; the
   actual `par_analysis.rs` check is a single-loop-only capture-mutation
   rule. Either document the real (narrower, still-sound) guarantee
   accurately, or extend the analysis to actually match the pitch — but stop
   letting the docs promise a scheduler that doesn't exist. -- Done: added
   `system`/`parallel` (`src/types/system_analysis.rs`,
   `src/codegen/system.rs`) — named systems declare an explicit per-arena
   read/write access list, and a `parallel:` block runs a set of them
   concurrently on the existing `par`/`swarm` worker pool after the checker
   proves no two listed systems hold a conflicting (>= 1 mutable) lock on
   the same arena, rejecting the block at compile time otherwise. See
   `docs/language_reference.md`'s "Cross-System Scheduling" section and
   `examples/parallel_systems.star`.

## P2 — Real but lower-blast-radius feature gaps

7. **Trait-bounded generics** (`fn f<T: SomeTrait>(x: T)`). Today a generic
   function can only move/store/return a `T` — it can't call a trait method
   or use an operator on it. Fine for container-shaped generics (`Box<T>`,
   `Stack<T>`), a real ceiling for anything else. -- Done: See previous work
   below for details. Both halves are now closed: the trait-method half, and
   (via operator overloading, see the later "Previous work" entry) the
   "or use an operator on it" half — a struct can implement `Add`/`Sub`/
   `Mul`/`Div`/`Rem`/`Eq`/`Ord`/`Neg` to give `+ - * / % == != < > <= >=`/
   unary `-` a custom meaning, and a trait-bounded generic body can now use
   an operator on its bounded type parameter, not just call a trait method.
8. **Audio playback and gamepad input.** Long-deferred, explicitly and
   honestly labeled as such — but "game programming language" without audio
   is a real, user-visible hole, not a nice-to-have. -- Done: See previous
   work below for details.
9. **A proportional/lowercase-aware text renderer**, or a documented,
   supported path to bind `SDL_ttf` for anything beyond a debug HUD. The
   current 5x7 uppercase-only bitmap font is fine for a score counter, not
   for shippable UI text.
10. **General place-projection into `Table<T>`** (`table[i].field = v`),
    closing the one documented gap in that type's method surface. -- Done:
    See previous work below for details.

## P3 — Process / maintainability (won't block a single feature, but compounds)

11. **Stop discarding `todo.md`/`current_status.md` history wholesale.**
    Current workflow rewrites/clears both after every session
    (`.clinerules/workflows/todo`), so the only durable record of *why* a
    decision was made lives in scattered doc prose and `git log -p`. Keep a
    real `CHANGELOG.md` (append-only) even if `todo.md` itself stays a
    living scratchpad. -- Done: `.\changelog` now acts as the long-term storage for implementation documentation.
12. **Give the checker/codegen binop-dispatch pattern a real abstraction
    before it grows further.** Every new scalar-ish type (`Wrapping`,
    `Fixed`, `Symbol`, `Color32`, `Tick`/`Duration`/`Instant`, `BitField`,
    `Flags`) adds its own dedicated dispatch branch rather than folding into
    a general predicate, by design (each has different legal-operator
    semantics). That's the right call per-type, but the growing list of
    one-off branches is a maintainability trend worth addressing with a
    shared table/trait rather than continuing to hand-add arms.
13. **Document and/or fix the Windows build story.** Building this compiler
    today requires `cargo +stable-x86_64-pc-windows-gnu` plus a hand-
    maintained `vendor-libs` stub directory — a plain `cargo build` fails
    outright on the reference machine. Fine for a solo project; a real
    barrier if outside contribution is ever a goal.

# Previous work:

Implemented general place-projection into `Table<T>` (todo.md P2 #10),
closing the one gap `docs/design.md`'s `Table<T>` write-up documented in its
own method surface: `table[i].field = v` (and any deeper chain rooted at
one -- `table[i].nested.x = v`, `table[i].tags.push(v)`, `table[i].cells[j]
= v`) previously type-checked cleanly under no rejection at all before this
round's `Checker::writes_through_table_index` existed, then (once that
checker-level guard was added) was rejected outright at type-check time
with a diagnostic pointing at the whole-element write instead. Both were
symptoms of the same root cause: unlike `List<T>`/`Array`/`Ring<T,N>`,
whose elements each live at one contiguous address, a `Table<T>` element's
fields live in independent per-column buffers, so `Codegen::emit_place`'s
generic `Field` arm (which GEPs a field offset out of a single base
pointer) had nothing valid to address.

- `src/codegen/table.rs`: new `Codegen::emit_table_field_place` (a *place*,
  for a further access like `table[i].nested.x = v`/`table[i].tags.push(v)`)
  and `Codegen::store_table_field` (a direct, single-level `table[i].field
  = v` write), both built on a shared `open_table_field_write_check` scaffold
  that CoW-uniques the table (mirroring every other mutating table
  operation) and bounds-checks the row before handing back a real pointer
  directly into the accessed field's own column at that row -- never
  materializing the whole element the way `emit_table_index`/
  `store_table_index` do. `emit_table_field_place`'s out-of-bounds branch
  still hands back a disconnected, zeroed dummy (mirroring
  `emit_list_index_place`'s identical convention), but `store_table_field`
  bounds-checks and branches itself so an out-of-bounds row *releases* the
  already-owned RHS value instead of orphaning it into that dummy -- the
  same leak class `crate::codegen::arena::store_genref_field` already
  closed for the identical `GenRef<T>` shape (found and fixed in this round
  before it ever shipped, confirmed via a real Working-Set-sampling leak
  test that would have failed without it).
- `src/codegen/mod.rs`: `Codegen::emit_place`'s `Field` arm now special-cases
  a `TableIndex` base, calling `emit_table_field_place` directly instead of
  its generic single-base-pointer GEP logic -- every other place-consuming
  call site (`Field`'s own recursive arm for a nested struct field,
  `list_fields_mut`/`array_index_ptr`/`emit_ring_index_place` for a
  collection- or array-typed field, mutating collection-method receivers)
  composes with the real pointer this hands back for free, with no
  `Table`-specific code needed anywhere else in the compiler.
  `src/codegen/stmt.rs`'s `store_target`'s own `Field` arm gained the
  identical `TableIndex`-base special case (routing to `store_table_field`
  instead), since it resolves its target's storage independently rather
  than delegating to `emit_place`.
- `src/types/mod.rs`/`src/types/stmt.rs`: `Checker::writes_through_table_index`
  no longer rejects `Stmt::Assign` targets or mutating collection-method
  receivers reached through a table index -- it's narrowed to its one
  remaining real gap, a *bare* table index passed somewhere a place is
  needed with no field projection yet applied (`reflect_set_i32(table[i],
  "field", v)`, which mutates a whole struct by runtime field name and
  still has no single contiguous address to target). Every pre-existing
  gate this bypassed nothing: `mut`-root gating (`assign_root_name`'s
  already-recursive `TableIndex` arm) and per-field `mut` gating
  (`field_is_mut`) both still apply unchanged, confirmed by dedicated
  regression tests.
- `docs/design.md`'s `Table<T>` write-up and `Ty::Table`'s own doc comment
  (`src/types/mod.rs`) updated to describe the closed gap instead of the
  accepted one.
- Added 15 new tests to `tests/frontend.rs` (and converted 7 pre-existing
  rejection tests into end-to-end runtime tests proving the write actually
  reaches the table, not just that it type-checks): single-field and
  nested-field writes, a mutating `List<T>`-field method call
  (`table[i].tags.push(x)`), a `List`/`Array`-field indexed one level
  further (plain and compound-assignment), copy-on-write correctness
  (a field write through one binding must not affect an aliased binding
  sharing the same table), row independence (writing one row's field must
  not disturb a neighboring row's own columns), `mut`-root and per-field
  `mut` gating regressions, `par`/`swarm` body-local-vs-captured coverage
  (mirroring the pre-existing whole-element-write coverage), and the
  out-of-bounds-write leak regression above. Full suite (1482 tests) passes.

Implemented audio playback and gamepad input (todo.md P2 #8), the last of
the long-deferred, honestly-labeled "game programming language" gaps
`ASSESSMENT.md`'s "The Bad" section called out by name ("no game ships
without audio, and controller input matters a lot for the genres this
language's memory model is obviously aimed at").

**Audio** (`src/codegen/audio.rs`, new): `sound_load(path) -> ptr` parses a
WAV file entirely by hand over a plain `fopen`/`fread` buffer -- mirroring
`font_load`'s own approach (`src/codegen/font.rs`) -- rather than going
through SDL's `SDL_LoadWAV_RW`/`SDL_AudioSpec`, so a program that only loads
sounds needs no SDL call at all. Only the canonical minimal-header shape is
accepted (16-bit/44100Hz/stereo PCM, `fmt ` chunk immediately followed by
`data`, the layout Audacity/`sox`/`ffmpeg -f wav` already produce by
default) -- every RIFF/WAVE/fmt/data tag and format field is checked against
a fixed offset, and anything else (wrong sample rate, wrong bit depth, wrong
channel count, extra chunks before `data`, or a truncated file) fails to
load, returning `null` (checked with `is_null`, same convention as
`window_create`/`file_open`) rather than being resampled or misread.
`sound_free` releases both the loaded byte buffer and the handle wrapper.

Playback is a small hand-rolled additive mixer, not a bare `SDL_QueueAudio`
FIFO: a fixed 16-slot channel table (four parallel globals -- base pointer,
byte length, playback position, loop flag -- plus a playing-flags array),
channel 0 reserved for looping "music" (`music_play`/`music_stop`), the
other 15 one-shot "sound effects" (`sound_play`, which scans for the first
free slot and silently drops the request if all 15 are busy -- a documented
fixed-voice-count floor cut, not a queue). `sound_stop_all()` stops
everything at once. `@star.audio.mix_callback` -- a hand-written LLVM IR
function emitted once per program (`ensure_audio_pool_emitted`, mirroring
`par_pool::ensure_par_pool_emitted`'s own guarded-emit-once shape exactly)
and registered as the real `SDL_AudioSpec.callback` -- zeros the requested
output buffer then additively mixes every currently-playing channel's
remaining samples into it via `SDL_MixAudioFormat` (which already does the
signed-16-bit saturating add, so this floor never hand-rolls clipping
math). Every loaded sound and the shared output device share one fixed
canonical format, so the mixer never resamples or converts at mix time.
`ensure_audio_device` lazily opens the shared device (guarded by
`@star.audio.device`, unlike `window_create`'s own "call `SDL_Init` every
time" convention -- audio has exactly one shared mixer device for the whole
program, not one instance per call) with `allowed_changes = 0`, so a
mismatched actual device format fails cleanly instead of silently desyncing
every channel's fixed-format assumption.

Concurrency is deliberately informal, and documented as such: the
channel-table globals are unguarded (no lock), read on SDL's own dedicated
audio-callback thread and written by whichever thread calls
`sound_play`/`music_play`/`music_stop`/`sound_stop_all`/`sound_free`.
Correctness leans on `emit_channel_start` always writing a channel's
`playing` flag *last* (the mixer checks `playing` *first*, so it never
observes a half-updated channel) plus x86/x64's own strong store ordering --
this compiler's only target. This is exactly why those five builtins (plus
every `gamepad_*` builtin below) were added to
`crate::types::par_analysis::is_banned_sdl_builtin_in_par`
(`src/types/par_analysis.rs`): concurrent *writers* to this same unlocked
table from multiple `par`/`swarm` worker threads is a real, unguarded race
the single-writer assumption doesn't cover. `sound_load` itself is *not*
banned, for the same reason `font_load` isn't -- it only touches its own
independently `malloc`'d buffer.

**Gamepad** (`src/codegen/gamepad.rs`, new): bound to SDL2's lower-level
`SDL_Joystick` API (raw, numbered buttons/axes) rather than
`SDL_GameController` -- the latter only recognizes a device as a "game
controller" at all if its exact USB vendor/product ID is present in SDL's
mapping database (normally loaded from an external `gamecontrollerdb.txt`
this floor doesn't bundle or fetch), so a real, physically-connected pad
would otherwise be invisible to it even though `SDL_Joystick` sees it fine.
`gamepad_count() -> int`/`gamepad_open(index) -> ptr` both call
`SDL_Init(SDL_INIT_JOYSTICK)` every time, mirroring `window_create`'s own
ref-counted-by-SDL `SDL_Init` convention; `gamepad_open` returns `null` on
an out-of-range index or unplugged device, checked with `is_null`.
`gamepad_button_down`/`gamepad_axis`/`gamepad_attached` all call
`SDL_JoystickUpdate` first -- unlike `key_down`/`mouse_x`/`mouse_y`, which
piggyback on `window_should_close`'s own event-queue drain, a gamepad-only
program with no window at all needs its own input pump.
`gamepad_axis` returns SDL's raw, unnormalized `-32768..32767` range
(sign-extended from `Sint16`), matching `mouse_x`/`mouse_y`'s own "raw
coordinates, no unit conversion" convention. `gamepad_attached` lets a game
detect a mid-session unplug explicitly, rather than only observing every
button/axis silently reading back as "not pressed"/`0` forever after (SDL's
own documented, never-crashing, never-signaling behavior for a stale
handle).

Wired through the same five places every existing SDL builtin already
threads through: `src/types/mod.rs` (return types + `RESERVED_RUNTIME_SYMBOLS`),
`src/types/expr.rs` (arity/argument-type checks), `src/codegen/mod.rs`
(the new `audio`/`gamepad` submodules, a new `Codegen::audio_pool_emitted`
field mirroring `par_pool_emitted`, and every new SDL/CRT `declare`),
`src/codegen/expr.rs` (call dispatch), and `src/types/par_analysis.rs` (the
ban list above). `docs/language_reference.md` gained a new "Audio Playback
/ Gamepad Input" section (with a documented "Limitations" list: no format
conversion, no volume/panning, a looping channel's restart can lag by up to
one callback buffer, 15 fixed one-shot channels with no queueing/stealing,
no controller-mapping database). Added `examples/audio.star`/
`examples/gamepad.star` plus a committed short WAV asset
(`examples/assets/beep.wav`, 0.25s/44100Hz/stereo/16-bit, generated with a
throwaway script, not hand-authored) that both the audio example and every
"real file" audio test load.

Added 37 new tests to `tests/frontend.rs`: checker tests covering every new
builtin's return type, arity, and argument-type validation (both accept and
reject cases); two `par`/`swarm`-ban regression tests (one per module) plus
a positive `sound_load`-stays-usable-inside-`par` sibling test, matching
`rejects_draw_text_and_get_pixel_inside_par_body`'s established shape;
codegen-shape tests confirming `sound_load` never calls into SDL at all,
`sound_play`/`music_play` pull in the channel-table globals and mixer
machinery, `music_play` targets channel `0` with its loop flag set (unlike
`sound_play`'s scanned free slot), the mixer's one-time machinery is
genuinely emitted exactly once regardless of call count, and
`gamepad_button_down`/`gamepad_axis`/`gamepad_count`/`gamepad_open` emit the
right `SDL_JoystickUpdate`/`SDL_JoystickGetButton`/`SDL_JoystickGetAxis`/
`SDL_Init(SDL_INIT_JOYSTICK)` calls; and runtime end-to-end tests under
`SDL_AUDIODRIVER=dummy`/`SDL_VIDEODRIVER=dummy` covering a real WAV load-
then-free cycle, a missing-file load returning `null`, all four
non-canonical WAV shapes (wrong rate/bits/channels/truncated) being
rejected, `sound_free` aborting on a null handle, a full
play/loop/layer/stop/free sequence running end to end with no crash, and --
the real proof `gamepad_*` reads live SDL state rather than just emitting
plausible IR -- attaching a genuine SDL2 *virtual* joystick
(`SDL_JoystickAttachVirtual`, no physical hardware needed) via a test-only
`extern "C" fn` declared straight from the compiled `.star` program itself,
then confirming `gamepad_open`/`gamepad_button_down`/`gamepad_axis`/
`gamepad_attached` observe exactly the button/axis state
`SDL_JoystickSetVirtualButton`/`SetVirtualAxis` set. Full suite (1480
tests) passes.

Made `frame:`'s bump-allocator budget configurable per block (todo.md P1 #5), mirroring the fix already done for arena capacity (`arena Name: Type = N`): the previously hardcoded 4096-byte cap on every `frame:` block's shared bump allocator is now overridable per block, closing the exact gap ASSESSMENT.md #4 named ("4096 bytes is easy to blow with unremarkable code ... the fixed ceiling itself remains a footgun with no compiler-facing way to size it to the workload").

- New grammar: `frame(N):` (an optional parenthesized byte-count literal directly after the `frame` keyword, mirroring `arena Name: Type = N`'s "= N" override rather than reusing that exact token sequence, since `frame:` has no name/type slot to attach `= N` after). A bare `frame:` keeps working unchanged and still gets the default budget.
- `src/ast.rs`: `Stmt::Frame` gained `budget: Option<u64>` (parallel to `ArenaDecl::capacity`). `src/parser/stmt.rs`'s `parse_frame_stmt` parses the optional `(N)`, rejecting a non-positive or non-integer-literal budget at parse time -- the exact same rule `parse_arena` already enforces for `= N`, for the same reason (a codegen-time bounds check has to know the value without evaluating anything).
- `src/types/mod.rs`: new `DEFAULT_FRAME_BUDGET: u64 = 4096` (the old fixed value, now just the default) and `MAX_FRAME_BUDGET: u64 = 16 * 1024 * 1024` (16 MiB -- unlike `MAX_ARENA_CAPACITY`, this isn't protecting a narrower-width field, just guarding against a typo'd budget reserving unreasonable address space). `src/types/stmt.rs`'s `Stmt::Frame` checker arm resolves `None` to the default and clamps-with-error anything over the max, producing `TypedStmt::Frame { budget: u64, .. }` (`src/types/hir.rs`) -- same clamp-not-abandon shape as `Item::Arena`'s own check, so one bad literal doesn't cascade into unrelated diagnostics.
- `src/codegen/mod.rs`/`src/codegen/stmt.rs`: unlike `arena` (a named top-level item that naturally gets a per-name `HashMap<String, u64>`), `frame:` is a bare, unnamed statement that can appear (and nest) anywhere, and every `frame:` block in a program shares one physical backing buffer (`@frame.buf`) rather than getting its own. Rather than trying to right-size that single buffer to the tightest bound actually used anywhere in the module (which would need an exhaustive scan of every `frame:` statement reachable from anywhere, including arbitrarily deep inside closure literals stored in lists/struct fields/call arguments, to stay sound), `@frame.buf` is now always allocated at the fixed `MAX_FRAME_BUDGET` size regardless of what any block requests -- cheap in practice since it's a `.bss`-resident zero-initialized global that costs nothing until a page inside it is actually touched. A new `Codegen::frame_budget: u64` field (saved/restored around `emit_frame_body` exactly like the existing `in_frame: bool` field, so nested `frame:` blocks with different budgets each enforce their own bound and the outer block's own budget is correctly restored once an inner one exits) is what `emit_frame_alloc`'s bounds check actually compares the running offset against, not the physical buffer's fixed capacity. The runtime abort message now names the block's own configured budget (baked in at compile time via Rust's own `format!`, exactly like `emit_arena_decl`'s dynamic-capacity overflow-warning message) instead of a hardcoded "4096-byte" string.
- Updated `docs/language_reference.md`'s "Frame Memory" section and added a new "Frame Limitations" section (mirroring "Arena Limitations") documenting the default/max/override grammar. Added `examples/frame_budget_configurable.star`, showing the exact 4480-byte allocation `examples/frame_overflow.star` proves aborts under the un-overridden default succeeding cleanly once its enclosing block raises its own budget with `frame(8192):`.
- Added 15 new tests to `tests/frontend.rs`: parse-shape tests (`frame(N):` sets `budget: Some(N)`, bare `frame:` sets `None`, non-positive/non-integer-literal budgets rejected at parse time), checker tests (over-max rejected, within-max accepted), codegen-shape tests (the physical buffer is always sized to the 16 MiB maximum; a `frame(64):` block's own bounds check and abort message use 64, not the buffer size or the old default), and five end-to-end runtime tests (an override allowing an allocation that aborts under the un-overridden default; the same allocation still aborting under the default to prove that contrast is real; the abort message naming the configured override; and nested `frame:` blocks with different budgets each enforcing their own bound independently, with the outer block's budget correctly restored after the inner one exits). Fixed one pre-existing test (`codegen_frame_alloc_uses_bump_allocator`) that had hardcoded the old fixed buffer size. Full suite (1371 tests) passes.

Implemented module search-path resolution and a minimal project manifest (todo.md P1 #4), closing `projects/snake/NOTES.md`'s own "most significant gap ... still open" finding: every `import` was a hand-written path relative only to the importing file, with no project root, no search path, no package identity.

- New `src/manifest.rs`: a hand-rolled parser (deliberately not a `toml`+`serde` dependency, consistent with this compiler's existing lexer/parser/codegen-everything-by-hand approach and its own documented aversion to a fragile build story, P3 #13) for a genuine subset of TOML -- `[section]` headers, `key = "string"`/`key = ["a", "b"]` values, `#` comments (honored inside neither kind of string literal), multi-line arrays. Two sections: `[package]` (`name`/`version`/`entry`, all optional) and `[paths]` (`search`, a list of extra import search directories relative to the manifest's own directory). Every field optional -- an empty `star.toml` is legal, useful purely to mark a directory as a project root. `find`/`load_from_dir`/`discover` cover both "look for a manifest directly in this exact directory" (an explicit directory CLI argument) and "walk up from here looking for the nearest one" (auto-augmenting an explicit file argument's search paths) -- deliberately different lookup shapes, since an explicit directory argument is a claim about exactly which project root is meant, while a file argument's manifest discovery is a purely additive convenience that must never silently change which file gets built.
- `src/modules.rs`: `resolve` (the existing 2-argument entry point, ~10 call sites across `driver.rs`/`main.rs`/`tests/frontend.rs`, all left untouched) is now a thin wrapper over a new `resolve_with_search_paths(module, root_path, search_paths)`, threaded through `resolve_inner`'s recursion so search paths reach arbitrarily-nested imports, not just the root file's own. An import resolves relative-to-the-importing-file first (unchanged, so it can never be shadowed by a same-named file reachable some other way -- mirrors a C compiler's `#include "foo.h"` checking the including file's own directory before any `-I` path), then each search-path directory in order, first match wins. A completely unresolvable import now lists every location actually tried in its diagnostic, instead of a bare single-path IO error.
- `src/driver.rs`: `Driver` gained `with_search_paths` (alongside the existing `new`, unchanged) and a new `resolve_input(file, extra_search_paths) -> Result<ResolvedInput, String>` that turns a CLI `file` argument plus explicit `-I`/`STAR_PATH` paths into a concrete entry file and the full ordered search-path list to compile with -- a directory argument must directly contain a `star.toml` (no ancestor walk: an explicit directory argument is an explicit claim about the project root) and resolves to the manifest's own `entry` (default `main.star`); a file argument is used verbatim (bit-for-bit identical behavior to every pre-existing single-file caller when no manifest is involved) with `star.toml` auto-discovered by walking up from its directory purely to augment the search-path list.
- `src/main.rs`: every subcommand that resolves imports (`check`/`build`/`emit`) gained `-I`/`--search-path <dir>` (repeatable, via a shared `#[command(flatten)] SearchPathArgs`) and now also honors a `STAR_PATH` environment variable (a `PATH`-style list), both routed through `resolve_input` before compiling -- `file` may now be a directory containing a `star.toml`.
- `projects/snake/star.toml` added (name/version/entry only, no extra search paths needed since that project's imports already sit flat in one directory) -- verified end to end with a real `star build projects/snake -L sdl/lib/x64 -l SDL2 -o ...` through the actual CLI binary, producing a working executable via the new directory-plus-manifest path.
- `docs/language_reference.md`'s "Modules" section and `readme.md`'s usage section documented the two-step resolution order and the manifest format/CLI flags.
- Added 16 new tests to `tests/frontend.rs` (search-path-directory resolution, relative-wins-over-search-path precedence, first-matching-directory-wins ordering, missing-import diagnostics listing every location tried, search-path propagation into nested/transitive imports, `resolve_input`'s file-vs-directory/manifest-vs-no-manifest/malformed-manifest matrix, and two full parse-check-codegen-clang-run end-to-end runtime tests proving the feature works for a real multi-file, manifest-rooted project, not just at the AST level), 44 new inline unit tests in `src/manifest.rs` (parser happy paths, string escapes, single/multi-line/trailing-comma array literals, a `]` inside a quoted path string not being mistaken for an array terminator, every parse-error diagnostic shape with correct line numbers, and `find`/`load_from_dir`/`discover`'s filesystem-walking behavior including the exact-directory-vs-walk-up distinction), and 4 new unit tests in `src/main.rs` for the `-I`/`STAR_PATH` merge-and-order logic. Full suite (1359 tests) passes.

Added an IR verification phase (src/ir_check.rs) that runs after LLVM IR codegen and before the IR is ever handed to clang, directly addressing the "Ugly #1" gap identified in ASSESSMENT.md: a hand-rolled textual IR emitter with no builder verifying well-formedness ahead of the clang boundary.

What it checks, grounded in reading the actual .ll dialect this emitter produces (not general LLVM IR):

Every basic block ends with exactly one terminator (ret/br/unreachable) and nothing follows it — this is the exact shape of the documented frame:-block-ending-in-return bug (store emitted after ret).
phi nodes are grouped at the top of their block, their incoming-label list matches the block's actual predecessors, and (best-effort) incoming value types agree with the phi's declared type — targets the documented "untagged register" bug.
No duplicate SSA register or function/global definitions (defense against the diamond-import mangling bug class).
Every branch target is a real label; every %register/@global reference resolves to something actually defined (skipping llvm.* intrinsics, which clang auto-declares from the call site).
ret types match the function's declared signature.
Wired into Driver::codegen (src/driver.rs) so every caller — star build, star emit llvm, and the test suite — gets it automatically rather than opt-in.

Validated it: scanned all 73 shipped .ll files plus the 7,900-line projects/snake/main.ll (zero false positives), ran it against all 1,331 existing tests (initially caught 3 real false positives from my own checker — a phi-type-parsing bug when the phi's type itself starts with [ — which I fixed and turned into regression tests), and added 16 targeted unit tests including direct reproductions of both historically-documented bug classes. Full end-to-end star build → clang → run still works correctly.

Robustness expansion (src/ir_check.rs):

Added Severity::{Error, Warning} to IrError — findings that clang genuinely rejects stay build-blocking Errors; findings that are legal-but-suspicious IR (e.g. an unreachable block) are non-blocking Warnings.
New checks: duplicate basic-block labels, unreachable/orphaned blocks (warning-only — validated against a real fixture, struct_destructure.ll's intentional unreachable catch-all block, confirming the severity split was necessary), and call-argument-count mismatches against in-module declare/define signatures (including correct handling of the call i32 (i8*, ...) @printf(...) explicit-signature syntax variadic calls actually use — caught and fixed a real bug in my first draft of that check).
Added a permanent regression test that runs verify() against all 74 shipped .ll fixtures and asserts zero Error-severity findings, plus a fuzz test (2000 random garbled inputs) and hand-written adversarial cases (unbalanced brackets, unterminated strings, huge integer literals) asserting the checker never panics.
Graceful failure (src/driver.rs, src/main.rs):

Driver::codegen_verified now wraps the call to ir_check::verify in catch_unwind: a bug in this best-effort heuristic checker degrades to a warning instead of crashing the whole compiler.
The generated IR is no longer discarded when verification fails — IrVerification { ir, errors, warnings } always carries the IR text. star build now writes the .ll file even on a verifier rejection (so a false positive isn't a dead end), and star emit llvm — the actual debugging tool — always prints the IR regardless of verifier findings.
Added star build --skip-ir-verify as an explicit escape hatch to let clang have the final word when the verifier is wrong.
Driver::codegen's signature (used by ~200 existing tests) is untouched — it's now a thin wrapper over codegen_verified.

Audited every f-string/print-family format-specifier table (todo.md P0 #2), directly targeting the fieldless-enum-prints-as-garbage-hex bug class. Found there are actually two independently-implemented specifier tables — println(f"...")'s direct-argument path (Codegen::emit_print_like, builtins.rs) and the general f-string-as-str-value path (TypedExpr::FStr, expr.rs) — each with its own `_ => %p` catch-all and its own history of missing arms.

Reproduced a new, worse instance of the bug class live: interpolating a struct/tuple/array/GenRef/Handle/closure/Ring value into an f-string compiled clean and ran clean, silently printing a garbage address (`println(f"point={p}")` for a two-i32-field struct printed `0000000000000001`) instead of erroring — worse than the enum case because these seven types lower to an LLVM aggregate passed *by value* (`%Name`/`{..}`/`[N x T]`/`%GenRef`/`{i8*,i8*}`), so tagging one as a vararg `%p` pointer is a real C-ABI mismatch, not just an unhelpful address.

Fixed two ways:
- Added `Ty::is_fstring_unprintable` (types/mod.rs) classifying `Named`/`GenRef`/`Handle`/`Tuple`/`Array`/`Ring`/`Closure` as having no defined print format; `Checker::infer_expr`'s `Expr::FStr` arm (types/expr.rs) now rejects interpolating one with a clean "cannot interpolate a `Ty` value into an f-string" diagnostic instead of letting it reach codegen.
- Made both codegen specifier matches exhaustive — removed the `_ => %p` wildcard entirely from both `emit_print_like` (builtins.rs) and `TypedExpr::FStr` (expr.rs), replacing it with explicit arms: the seven pointer-backed types (`List`/`Map`/`Set`/`Table`/`Palette`/`Bytes`/`Ptr`, all a bare `i8*`) keep `%p` as a deliberate, ABI-safe "print the address" arm; the seven aggregate-by-value types get `unreachable!()` (defense-in-depth — the checker should already have rejected them); the vector/matrix/`Fixed` types get `unreachable!()` too (they're filtered/substituted earlier in the same function). With no wildcard arm left, a future `Ty` variant that isn't sorted into one of these buckets now fails to *compile*, not just fails a test — the strongest form of "the next new type can't ship this bug again."

Added 4 new tests (tests/frontend.rs): two exhaustive round-trip tests (one per format-specifier table) covering all 32 printable `Ty` variants' exact expected output in one pass each, one smoke test confirming the 7 pointer-backed types still compile/run/print without crashing, and one confirming all 7 previously-silently-broken aggregate types now produce a clean diagnostic instead of miscompiled IR. Repurposed one obsolete pre-existing test (`codegen_println_fstring_interpolating_struct_releases_borrowed_reference`, which asserted RC-release behavior for a now-rejected pattern) into a checker-diagnostic test. Full suite (1335 tests) passes.

Gave `Map<K,V>`/`Set<T>`/`Symbol` real hash-table backing (todo.md P0 #3), replacing the linear-scan implementation with open addressing. Purely an internal codegen change — no syntax/semantics shift, `docs/language_reference.md`'s "no hashing/bucketing yet" note updated to describe the new O(1)-average behavior instead.

- New `src/codegen/hash.rs`: a structural-hash function generator (`hash_<mangled>(T) -> i64`, FNV-1a) mirroring `eq.rs`'s exact per-`Ty` coverage (same set `Checker::check_hashable_ty` accepts), so two structurally-equal keys always hash equal — including canonicalizing `-0.0`/`+0.0` for `Float`/`F64` before hashing, since `eq_fn_name`'s `fcmp oeq` already treats them equal but their raw bits differ. Threads a single `alloca`'d accumulator through recursive field/lane traversal rather than returning SSA values, sidestepping the `phi`-merging a `str` field's byte loop would otherwise need at arbitrary recursion depth.
- New `src/codegen/hashtable.rs`: shared open-addressing primitives — `emit_ht_probe` (linear-probe a `states`(`i8`: 0=empty/1=occupied/2=tombstone)+`keys` pair for a match or the first free-or-tombstone slot, `alloca`-based rather than `phi`-based across its several exit branches, mirroring `symbol.rs`'s pre-existing linear-scan shape), `emit_ht_first_empty` (rehash-only variant, no equality check), `emit_ht_grown_cap` (double-or-8 policy), and `emit_fill_i8`/`emit_fill_i64` (hand-rolled fill loops — this codegen never declares `@llvm.memset`).
- `Map<K,V>` (`src/codegen/map.rs`) and `Set<T>` (`src/codegen/set.rs`) payloads gained a `states: i8*` array (and `Map` a `tomb: i64` alongside `Set`'s) alongside the existing RC/CoW `i8*` object-pointer scheme; `insert`/`get`/`remove`/`contains` hash the key/element and probe instead of scanning. Growth (double capacity, starting at 8) trips at 75% load *including* tombstones, and always rehashes into a fresh all-empty table (clearing tombstones) rather than just copying, since capacity changes every element's bucket. `remove` now tombstones in place instead of swap-removing — element/key order was never a documented guarantee (the old swap-remove already said so), so this is a pure internal simplification, not a behavior change. CoW-clone (`emit_map/set_ensure_unique`) stays a flat same-capacity structural copy (states+keys+vals memcpy'd, then occupied slots retained), never a rehash, since cloning doesn't change `cap`.
- `Symbol` (`src/codegen/symbol.rs`) kept its append-only `@sym.data`/`@sym.len`/`@sym.cap` log (id = index, so `symbol_name`'s reverse lookup was already O(1) and untouched) and added a separate hash index (`@sym.tbl.ids`, `-1`-sentinel, no tombstones needed since interning never removes) accelerating the `string -> id` direction from a linear `strcmp` scan to an average-O(1) probe. Grows by rebuilding from `@sym.data` directly rather than migrating the old index's slots.
- Every `star_rc_alloc` byte-size argument and payload field-index literal (GEPs are positional) was updated for the new struct shapes; the generated release thunks now walk the full `cap`-length `states` array checking `== OCCUPIED` per slot instead of a contiguous `0..len` run, since live slots are no longer contiguous.
- Rebuilt and re-verified the two committed example binaries that exercise this path end to end (`examples/map_set.exe`, `examples/symbol_par_race.exe`) against the new codegen.
- Added 8 new tests (tests/frontend.rs): two codegen-shape tests confirming a `hash_<mangled>` function is now generated alongside the existing `eq_<mangled>`; a 300-key `Map<i32,i32>` stress test driving multiple grows, a full remove-half/tombstone/refill/re-verify cycle, and exact `len`/`contains`/`get` correctness at every stage; the `Set<i32>` equivalent (150 elements, dup-insert rejection, remove-a-third, refill); a `Set<Point>` test (100 distinct two-field-struct keys) pinning that the structural hash agrees with structural equality closely enough that no two distinct points collapse into one slot; a `Map<str,str>` growth/removal/refill test exercising RC-bearing key/value rehashing and release-thunk correctness; a `cap == 0` (never-inserted) `contains`/`remove` smoke test for both `Map` and `Set`, pinning the "probe loop's own bound skips the body, so an unguarded `mask = cap - 1 = -1` is never actually dereferenced" invariant; and a 300-string `Symbol` intern-index growth test confirming ids stay sequential and re-interning after several index rebuilds still dedups correctly. Full suite (1343 tests) passes.

Implemented trait-bounded generics (todo.md P2 #7): `fn f<T: SomeTrait>(x: T)`, plus the same bound syntax on a generic `struct`/`enum`'s own type parameters (`struct Cage<T: Speaker>: ...`). Only the trait-method half of the original gap was closed by this round — see the note at the end of this entry on the operator half, which was unchanged at the time; it's since been closed too, see the later "Implemented operator overloading" entry below.

- New `ast::TypeParam { name: String, bounds: Vec<String> }` replaces the bare `Vec<String>` every `type_params` field (`StructDef`/`EnumDef`/`ImplBlock`/`FnSig`) used to hold. `Parser::parse_opt_type_params` (shared by all four — struct/enum/impl-type-level declarations and `parse_fn_sig`, the latter also reused by trait method signatures and impl methods) now parses an optional `: Trait1 + Trait2` after each parameter name, mirroring `<T, U, ...>`'s existing comma-separated grammar.
- `Checker::trait_impls: HashMap<String, HashSet<String>>` (`src/types/mod.rs`) records which traits a struct implements, populated during pass 1 alongside `methods`/`generic_impls` from every `impl Trait for ...:` block — keyed by the struct's own name for a concrete impl, or by the generic template's name (never one specific mangled instantiation) for `impl Trait for Pair<A, B>:`, so the trait counts as implemented for *every* instantiation of `Pair`, not just one `A`/`B` pairing.
- `Checker::ty_implements_trait` resolves a (possibly monomorphized) `Ty::Named` back to its template name via the pre-existing `mono_struct_of` map before consulting `trait_impls` — anything that isn't `Ty::Named` (scalars, enums, collections, ...) can never satisfy a bound, matching `check_impl`'s own pre-existing restriction that `impl` blocks are struct-only. `Checker::check_type_bounds` then verifies every type parameter's declared bounds against its corresponding concrete type argument, reporting one located diagnostic per unsatisfied (or undefined-trait) bound and returning `false` so the caller skips instantiating the template against already-known-bad input — without that short-circuit, `announce(5)` against `fn announce<T: Speaker>(x: T): x.speak()` would cascade a second, confusing "no field `speak` on type `Int`" from checking the substituted body, on top of the real "does not satisfy the trait bound" diagnostic.
- Wired into the three call/construction sites that already resolve a generic template's concrete type arguments (`src/types/expr.rs`'s `infer_generic_call`/`infer_generic_struct_lit`/`infer_generic_enum_variant`), each with the call site's own `span` for an accurately-located diagnostic — deliberately *not* inside `instantiate_fn`/`instantiate_struct`/`instantiate_enum` themselves (which memoize by mangled name and would only fire the check once per distinct type argument, using a placeholder `Span::dummy()` the way their own internal arity checks already do) as trait-bound violations should be reported at every offending call site, the same way any other type error is.
- Checked **nominally**, not structurally, by design: a struct with a same-named, same-shaped inherent method but no matching `impl Trait for Type:` block does not satisfy a bound naming that trait, even though this compiler's plain (unbounded) generics are otherwise fully duck-typed — a generic template is never itself checked (see this module's own "Generics: monomorphization support" doc comment), only its call-site-driven concrete instantiations are, so a bounded `T` calling a trait method already "just worked" for any type that happened to have a matching method before this change, with no clean diagnostic when it didn't. The bound's real value is exactly this: a declared, checkable contract and a diagnostic naming the actual problem (the call site's type argument, the specific unsatisfied bound, and the generic function/struct/enum) instead of a raw "no method" error surfacing from deep inside a substituted body.
- `src/modules.rs`: a real, separate bug caught and fixed along the way — every `rename_*` helper cloned a declaration's `type_params` verbatim, so a bound's trait name (`Speaker` in `T: Speaker`) crossing an `import ... as alias` boundary was never mangled the way every other cross-item reference already is, silently failing every such bound with "undefined trait" regardless of whether the referenced type actually implemented it. Fixed by a new `rename_type_params` (mangles each bound name through the same `names` map `rename_type`'s `Type::Named` arm already uses; a type parameter's own name, e.g. `T`, is deliberately left alone — it's never a top-level declaration `collect_names` would register) threaded through all five `type_params` sites in `rename_item`/`rename_fn_sig`/`rename_fn`.
- Scope: only `fn`/`struct`/`enum` type-parameter bounds are enforced (covering the motivating case — calling a trait method inside a generic function/struct-method body). An `impl<T: Trait>`/trait-method-signature type parameter's bounds parse (for grammar consistency, since they share the same `parse_opt_type_params`/`parse_fn_sig` path) but aren't separately checked — in practice a narrow gap, since an impl block's own type parameters are already bound to whatever concrete type its owning struct's construction site already checked.
- **Not done at the time**: the "or use an operator on it" half of the original gap. This language had no user-defined operator overloading at all — `+`/`-`/`*`/`/`/`==`/... were hard-coded to a fixed table of builtin scalar/vector/`Fixed`/time types (`Checker::infer_binop_ty`), with no trait-dispatch mechanism for `+` on a struct regardless of whether it's generic or concrete. Closed in a later round — see "Implemented operator overloading" below.
- Added `examples/trait_bounded_generics.star` (with committed `.ll`/`.exe`, matching this project's existing example convention): a single-bound function calling a trait method, a multi-bound function (`T: Speaker + Named`) calling methods from two different traits, and a trait-bounded generic struct (`Cage<T: Speaker>`) whose own method calls a trait method on its bounded field.
- Added 19 new tests to `tests/frontend.rs`: parser tests (single bound, multiple `+`-separated bounds, a bound on a generic struct's own type parameter, mixed bounded/unbounded parameters in one list); checker accept tests (a satisfying type calling a bound's method, multiple bounds each satisfied, every instantiation of a generic-struct trait impl satisfying a bound naming it, a plain unbounded `<T>` still accepting anything); checker reject tests (a non-implementing type via fn call/struct construction/enum-variant construction, a structurally-matching-but-not-nominally-implementing type, one satisfied bound out of two not masking the other's violation, a bound naming an undefined trait); a codegen-shape test confirming the substituted body's trait-method call dispatches to the concrete type's own mangled `Type__method`; two cross-module tests (a bound resolving correctly through an import alias, and a bound violation still being caught through one — the two failure directions the `rename_type_params` fix above addresses); and two runtime end-to-end tests (the committed example binary, and an inline `compile_and_run` case). Full suite (1420 tests) passes.

Implemented operator overloading (todo.md P2 #7's remaining half): closes the "or use an operator on it" gap trait-bounded generics left open — a struct can now give `+ - * / % == != < > <= >=` and unary `-` a custom meaning, and (the actual motivating case) a trait-bounded generic body can use an operator on its bounded type parameter, not just call a trait method on it.

- Each overloadable operator maps to one canonical `(trait, method)` pair: `+` -> `Add::add`, `-` (binary) -> `Sub::sub`, `*` -> `Mul::mul`, `/` -> `Div::div`, `%` -> `Rem::rem`, `==`/`!=` -> `Eq::eq` (`!=` is `!eq(...)`, so implementing `Eq` gets both), `< > <= >=` -> `Ord::{lt,gt,le,ge}` (four independent methods, not derived from a single `cmp` — this language has no `Ordering`-shaped return type to build that around, and a trait declaring only `lt` correctly yields support for only `<`), unary `-` -> `Neg::neg`. None of these eight trait names are builtin/reserved — they are declared exactly like any other user trait (`trait Add: fn add(self, rhs: Self) -> Self`), which is what motivated the one other new piece of grammar this round needed: `Self` as a type.
- `Self` (`src/types/mod.rs`): previously unusable as a type anywhere (it already existed only as an internal error-placeholder sentinel string, `Checker::is_placeholder_ty`). Rather than make it resolve everywhere (which would let `Self` leak into a plain function/struct field with no concrete type to substitute, then fail invalid-IR-late at the `clang` step — the exact bug class `ir_check.rs`/P0 #1 exists to close off), a new `Checker::trait_sig_context: bool` field is set only around `Item::Trait`'s own `check_fn_sig` calls; `resolve_type` accepts the bare identifier `Self` only while that flag is set, resolving it to the `Ty::Named("Self")` placeholder sentinel (so it silently suppresses further cascading errors, consistent with what that sentinel already means everywhere else) rather than a real type — trait method signatures are otherwise pure record-keeping with no dynamic dispatch anywhere to give `Self` any other meaning. A new `Checker::subst_self_type` (recursive over `ast::Type`) replaces `Self` with the concrete implementing type before `check_impl_satisfies_trait` compares a trait's declared signature (written with `Self`) against an impl's provided one (which, the only way it is spellable, always writes the concrete type name instead) — without this, every operator-overload trait impl would be rejected as a parameter/return-type mismatch against its own trait's literal `Self` token.
- `Checker::try_operator_overload_call`/`try_neg_overload_call` (`src/types/expr.rs`), called from `Expr::Binary`/`Expr::Unary`'s own arms ahead of `infer_binop_ty`: desugar `a op b` into the ordinary method-call shape `a.add(b)` (`TypedExpr::Call` wrapping a `TypedExpr::Field` callee, exactly what a hand-written `.add(...)` call type-checks into) whenever the left (or, for unary `-`, the only) operand's type nominally implements the operator's mapped trait (`Checker::ty_implements_trait`, pre-existing from trait-bounded generics) and provides the canonical method. Because this happens at type-check time and produces the *same* `TypedExpr` shape an ordinary method call already produces, **zero codegen changes were needed** — `Codegen::emit_call_expr`'s existing `TypedExpr::Field` branch (mangled `{Type}__{method}` dispatch) handles it as-is. `!=` further wraps the `eq` call in `TypedExpr::Unary { op: UnOp::Not, .. }` (a boolean negation of the same call `==` makes) rather than requiring or generating a separate `ne` method. Only the left operand's type ever selects an implementation — no right-hand/`impl Add<Point> for i32`-style dispatch, so `5 + point` still hits `i32`'s own numeric-only rules. A struct with no matching trait impl is completely unaffected: `+`/`-`/`*`/`/`/`%` still hits the pre-existing "not supported" error, and `==`/`!=` still falls back to the pre-existing structural-comparison path (a fieldless enum or a struct/tuple/array of structurally-comparable fields) untouched.
- A real cross-feature hazard caught and fixed along the way: `Expr::Unary`'s pre-existing `UnOp::Neg` arm typed itself by delegating to `infer_binop_ty(Sub, ty, ty)` (`-x` is `0 - x`). Once `Sub` became an overloadable operator, that delegation would have let `-point` wrongly *type-check* for any `Point` merely implementing `Sub` (computing `point.sub(point)`, not a real negation) and then produce invalid LLVM IR at codegen (`Codegen::emit_unary`'s `Neg` case still unconditionally computes `zeroinitializer - x`, which is not a legal instruction against an aggregate struct value) — exactly the checker/codegen-divergence bug class P0 #1 exists to close off. Fixed by special-casing a struct operand out of that delegation entirely: `try_neg_overload_call` handles the one case where unary `-` on a struct has real meaning (implementing `Neg`), and any other struct gets a dedicated "implement the `Neg` trait" error instead of ever reaching `infer_binop_ty(Sub, ...)`.
- A comparison operator's backing method returning something other than `bool` (an unusual but not grammatically-prevented trait declaration) is a dedicated, located error naming the trait/method/operator — and forces the synthesized call's own type to `Ty::Bool` regardless (safe only because a checker error here always aborts before codegen ever runs, per `Driver::check`) purely so the diagnostic does not also cascade a confusing second "if condition must be bool" error from whatever consumes the comparison next.
- Updated `docs/language_reference.md`'s "Operators" section with a new "Operator Overloading" subsection (the trait/method mapping table, a worked example, and the same set of scoping rules — left-operand-only dispatch, `Eq`-derives-`!=`, `Ord`'s four independent methods, structural-comparison fallback preserved, compound assignment (`+=`/...) *not* covered by this mechanism) and a one-line clarifying addition to `docs/features.md`'s pre-existing "Operator Overloading" SIMD-vector bullet distinguishing that compiler-internal lowering from this new user-facing trait mechanism.
- Added `examples/operator_overloading.star` (with committed `.ll`/`.exe`): a `Point` struct implementing `Add`/`Sub`/`Eq`/`Ord`/`Neg`, plus a trait-bounded generic `total<T: Add>(a: T, b: T) -> T: return a + b` — the concrete tie-in to trait-bounded generics' own committed example.
- Added 26 new tests to `tests/frontend.rs`: a parser test (`Self` in a trait method signature parses as an ordinary `Type::Named("Self")`); checker accept tests (`+`/`==`+`!=`/all four `Ord` comparisons/unary `-` on a struct implementing the matching trait, an operator used inside a trait-bounded generic body, structural-`==` fallback still working with no `Eq` impl, a partial `Ord` trait — only `lt` declared — yielding support for only `<`, an impl whose concrete types correctly satisfy the trait's `Self`-substituted signature); checker reject tests (`+` on a struct with no `Add` impl, a mismatched right-hand operand type, dispatch never triggered from the right-hand operand, unary `-` on a struct implementing `Add`/`Sub` but not `Neg` (the cross-feature hazard above), an `Ord` method returning non-`bool` with no error cascade, an impl whose parameter type disagrees with the trait's substituted `Self`); two codegen-shape tests (`+` lowers to a `call` to the mangled `Point__add`, `!=` lowers to a `call` to `Point__eq` plus an `xor i1` negation); six runtime end-to-end tests (`Add`, `Eq`/`Ne`, all four `Ord` operators, `Neg`, the operator-inside-trait-bounded-generic-body case, and the committed example binary). Also updated one pre-existing test (`rejects_unary_negation_of_a_struct_value`) whose asserted error message this round deliberately replaced with a clearer, `Neg`-trait-naming one. Full suite (1443 tests) passes.