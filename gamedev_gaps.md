# Star for Game Dev: Where It Still Falls Short

Analysis of `docs/design.md`, `docs/language_reference.md`, `todo.md`, `current_status.md`,
and the current `src/`/`examples/` tree, focused specifically on what stands between Star
and being *useful for building and managing a real game*. Verified live against source,
not just prose — where a claim could be tested, it was (`cargo +stable-x86_64-pc-windows-gnu
check`/`build`).

`current_status.md` (last updated before the graphics round) is now stale on its single
biggest claim — SDL2 windowing/input landed since — but everything else in this doc is
re-verified against current source, not copied from it.

## Headline: the type system and memory model are essentially done; the "make a game" layer is not

`docs/design.md`'s entire Type System section (§1–§9: numeric widths, `Wrapping`/`Fixed`,
collections, text/bytes, math/geometry, time, resource handles, bit-level types,
`Option`/`Result`) is marked **done** and the doc explicitly says it's "kept as a record...
rather than a live plan." The memory model (`frame`/`arena`/`GenRef`) and concurrency
(`par`/`swarm`/`sequence`) are real and load-bearing. That part of the pitch is solid.

What's *not* done clusters into a much smaller, much more game-shaped list below, roughly
ordered by how much it blocks actually shipping something.

---

## 1. No audio, no gamepad — half the "game language" input/output story is missing

Confirmed by grep: there is no `sound_*`/`audio_*`/`mixer` codegen anywhere in `src/codegen/`.
`docs/language_reference.md:861` says it outright: *"Audio playback and gamepad input are
still open (`todo.md` #4)."* `Handle<Sound>` exists as a *type* (§7 of design.md) but nothing
constructs one — there's no backing resource system to hand it a real sound.

Graphics/keyboard/mouse did land (SDL2, vendored under `sdl/`, bound as a fixed free-function
surface — `window_create`, `clear_screen`/`draw_pixel`/`draw_rect`/`draw_line`/`present`,
`key_down`/`mouse_x`/`mouse_y`/`mouse_button_down`), which closes the biggest historical gap.
But a game with no sound and no controller support is a hard sell for "management" of a real
project — this is the most concrete, highest-value remaining slice of `todo.md` #4.

**Why it matters for game dev**: feedback (hit sounds, music, UI blips) and gamepad support
are table stakes even for a jam game. Right now Star can draw a bouncing square and read a
keyboard, and that's it.

## 2. FFI can't reach a real C API on its own — SDL was hand-bound, nothing else will be

`extern "C" fn` only accepts `is_ffi_scalar_ty` types — numeric widths, `char`, `ptr` — plus a
special-cased `str` (`src/types/mod.rs:1455-1463`). No struct-by-value parameters, no callback
(function-pointer) parameters. That's enough for libc-shaped calls (`atoi`, `toupper`,
`strstr`) but not enough for a user to bind *any* struct-heavy or callback-based C library
(their own physics engine, a networking lib, a different audio backend) themselves.

SDL2's graphics/input surface got in only because the compiler team hand-wrote dedicated
codegen for each SDL call (`src/codegen/sdl.rs`) — the same shape as `file_io.rs`/`net.rs` — not
because `extern "C" fn` became more general. **This means every future C dependency (physics,
audio, a scripting bridge, Steam/platform SDKs) needs the same bespoke compiler-side binding
work; users have no self-service path.** For a language pitching itself as a systems language
for games, this is a real ceiling — it's fine as long as the compiler authors keep hand-binding
things, but it doesn't scale to what a real project will eventually want to link against.

## 3. Module system still can't back a real multi-file project's file layout

Transitive re-export (`a::b::c::item` at arbitrary depth) *did* land and works — this closes
the worst part of the old gap. What's still missing (`todo.md` #5):

- **No search-path resolution** — imports are still hand-written relative file paths, not a
  configured source root or `use`-style logical path. Every file has to know the exact
  relative disk location of everything it imports.
- **No package manifest** — no name/version/entry-point file, so there's no notion of "this
  directory is a Star project" beyond "there's a `.star` file with a `main`."

**Why it matters for game management specifically**: a real game project is dozens to
hundreds of files organized by system (rendering, ai, input, save data, level scripts). Without
a search path, every import in every file is a relative-path landmine that breaks the moment
you reorganize directories — which is exactly the kind of refactor a growing game project does
constantly.

## 4. ~~Arena capacity is a hardcoded, silent constant~~ — fixed: now per-arena, configurable

**Fixed.** `arena Name: Type = N` now overrides the default 1024-element capacity on a
per-arena basis (`ArenaDecl::capacity` / `TypedArenaDecl::capacity`, resolved by the checker
and looked up per-arena-name in `Codegen::arena_capacity` — see `src/codegen/arena.rs`). Every
arena's backing/generation/free-list array is sized for what its own declaration asked for,
bounded by `crate::types::MAX_ARENA_CAPACITY` (1,000,000 — chosen so `GenRef`'s fixed `i32`
slot-index field stays well inside range, and so an unreasonable literal can't `malloc` an
absurd backing array the moment the arena's first entity is spawned). See
`examples/arena_capacity_configurable.star`.

Originally: `Codegen::ARENA_CAPACITY` was a compile-time constant **1024**, applied to *every*
arena in *every* program, with no per-arena override anywhere in the grammar. Spawning past
capacity didn't error — it "silently drops the entity but warns at runtime"
(`docs/language_reference.md:907-908`), confirmed in `src/codegen/arena.rs:316-326` ("Past-
capacity spawns are still silently dropped"). 1024 was a reasonable default for
enemies-on-screen but exactly the kind of number a real game blows past — a bullet-hell's
projectile pool, a large open-world's active props, a particle system — and the only
workaround was spreading state across multiple arenas by hand.

The failure mode itself is also better now, in both directions: the overflow warning names
the arena's *actual* configured capacity (not one shared hardcoded number), and it now
latches after printing once per arena instead of flooding the console every single tick a
spawner keeps retrying against an already-full pool (`@arena.{name}.warned` in
`src/codegen/arena.rs`) — a real concern once `projects/snake/NOTES.md` section 2.1's arena
slot reclamation gap is also fixed and a game is actively spawning/despawning every frame.

## 5. No hot-reload runtime — `@export`/`@tweakable` are metadata-only

`src/codegen/reflect.rs` only emits descriptive offset/type-name metadata
(`offsetof`-equivalent info for an external tool). There's no file watcher, no IPC/shared-memory
runtime, no live-patching mechanism — `todo.md` #7 confirms this is still just a "productivity
win," fully unbuilt.

**Why it matters**: this is the single biggest promised productivity feature for iterating on
gameplay values (`docs/features.md` #4 pitches exactly this — tweak a value, see it update
without restarting). Right now a Star developer gets zero iteration-speed benefit over any
other compiled language; the metadata exists but nothing reads it.

## 6. `sequence` coroutines: yield can't appear inside control flow

`docs/language_reference.md:899-903`: `yield` is only legal at the top level of a `sequence`
body — not inside `if`/`while`/`frame`. That rules out the single most common coroutine
pattern in real gameplay code: *"wait until some condition becomes true, checking every
frame"* (e.g., `while !player.grounded: yield`), or *"flash red 3 times"* via a loop containing
a `yield`. Every conditional multi-frame wait has to be hand-unrolled or restructured around
this restriction, which undercuts the pitch (`docs/features.md` #2: "automates manual state
machines... into a clean coroutine syntax") — the exact thing this feature exists to avoid.

## 7. `Map`/`Set` are linear-scan, not hash tables

Confirmed still true (`src/codegen/set.rs:6`, `docs/design.md:100`): every lookup is an O(n)
structural-equality scan. Correct and RC-safe, but at any real entity count (a tag index, a
save-data dictionary, an asset lookup table — exactly the use cases `docs/features.md` names
for these types) this is a genuine scaling cliff, not a micro-optimization nit. `docs/design.md`
flags it candidly as an owed gap rather than hiding it, but it's still open.

## 8. `Table<T>` can't assign through a single field via an index

`table[i].field = v` is rejected outright by the checker (`Checker::writes_through_table_index`)
because a `Table<T>` element's fields live in independent parallel column buffers with no
single addressable struct to project into. `table[i] = v` (whole-element replace) and
`table[i].field` (read) both work. This is a narrow, well-understood gap (not a bug — a
documented, deliberate scope cut) but it means "mutate one column of one row" — an extremely
common ECS/struct-of-arrays operation — requires reading the whole element out, mutating the
copy, and writing it back, rather than a direct in-place field write.

## 9. A real, live regression: `examples/extern_ffi.star` currently fails to build

Verified live:

```
$ cargo +stable-x86_64-pc-windows-gnu run --release -- check examples/extern_ffi.star
error: extern "C" fn `strstr` collides with a symbol this compiler always declares
internally (CRT/OS import or runtime helper); redeclaring it under the same name would
fail to compile regardless of the signature given here
```

The string-builtins round (`str_contains`/`str_index_of`/`str_replace`/`str_split`) made
`strstr` a compiler-reserved symbol, but the example still declares `extern "C" fn strstr`
explicitly to demonstrate FFI. This has been called out as "unrelated, left unfixed" across
at least two subsequent `todo.md` rounds. It's a two-line fix (swap the demo symbol, the same
move already made once for `getenv`) but it currently means one of the ~70 example programs
does not compile — worth cleaning up before anyone new evaluates the language via `examples/`.

## 10. No non-toy program has actually been written in Star yet

`todo.md` #8 remains open. The largest example is `examples/brainfuck.star` at 81 lines — a
genuine, non-trivial interpreter (real sustained mutation of a 30,000-cell tape, real FFI), but
still a single-file, single-system toy, not evidence of a multi-module program with sustained
state and a real update loop. Every other example tops out around 40-90 lines and demonstrates
one feature in isolation. Nothing in the repo has yet exercised: multiple modules working
together via the module system, an actual game loop combining graphics + input + arena/ECS +
sequence coroutines + save/load, or any of the friction a real project surfaces (the module
search-path gap in particular, since a toy single-file program can't hit it).

**This is the highest-leverage next step, and it's cheap**: writing even a small real game
(e.g., a Breakout or Snake clone using the now-complete SDL2 graphics/input, `arena`/`par` for
entities, `sequence` for hit-flash/respawn timers) would simultaneously validate the graphics
round, surface the next real gap organically (as every prior stdlib-growth round explicitly
says it should), and produce the first genuine "yes, you can build a game in this" proof point.

---

## Suggested priority order

1. **Write one small real game** (#10) — cheapest, and it's the thing that will tell you which
   of the gaps below actually matter in practice versus which are theoretical.
2. **Fix `examples/extern_ffi.star`** (#9) — trivial, but a broken example undermines trust in
   everything else on first look.
3. **Audio + gamepad** (#1) — the other half of "game language," and the SDL groundwork
   (vendoring, linking convention, null-handle patterns) is already established, so this is
   more of the same shape of work already proven out for graphics.
4. **Arena capacity** (#4) — either make it configurable per-arena or make the failure mode
   loud (compile-time bound check or a hard trap) instead of a silent runtime drop; low
   implementation cost, high risk-reduction for anyone shipping with it as-is.
5. **Module search paths** (#3) — becomes actively necessary the moment #10 grows past a
   couple of files.
6. **Hash `Map`/`Set`** (#7) and **hot-reload runtime** (#5) — both real, both "known and
   candidly documented" debts, lower urgency than the above until a real project's profiler or
   iteration-speed complaints actually point at them.
7. **Wider FFI** (#2) and **`sequence` nested yield** (#6) — larger, more architectural lifts;
   worth scoping only once a concrete program needs them (e.g., #10 wanting to bind a physics
   lib, or wanting a "wait until grounded" coroutine).
