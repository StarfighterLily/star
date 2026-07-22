# Star Snake — dev notes, gaps, and roadblocks

This game (`grid.star`, `snake_body.star`, `food.star`, `save.star`,
`main.star`) was written specifically to dogfood the Star compiler on a
small but real multi-module program — `todo.md` #8 / `gamedev_gaps.md` item
10's own suggestion. It deliberately touches modules, structs/enums/traits,
generics, closures, match, `frame`/`arena`/`GenRef`, `par`/`swarm`,
`sequence` coroutines, `List`/`Map`/`Set`/`Ring`/tuples/fixed arrays,
`Wrapping`/`BitField`/`Flags`, `Symbol`, file I/O, string/math builtins, a
minimal `extern "C"` FFI call, and SDL2 graphics/input. Every finding below
was hit for real (a genuine `star check`/`star build`/runtime failure), not
inferred from reading source — each entry says how it was confirmed and how
this project worked around it, if it shipped.

Build (from the repo root):
```
star build projects/snake/main.star -L sdl/lib/x64 -l SDL2 -o projects/snake/snake.exe
```
`sdl/lib/x64/SDL2.dll` must sit next to the built `.exe` (already copied
into this directory). Controls: arrows/WASD to steer, P to pause, F1 for a
console debug overlay, hold Left Shift to boost, R restarts after death,
Escape quits.

---

## 1. Confirmed compiler bugs (not missing features — genuine defects)

### 1.1 Module system: diamond dependencies don't unify types (the big one)

If module `main` imports both `A` and `B`, and `A` and `B` each
independently `import "grid.star" as grid`, then `A`'s `grid::Cell` and
`B`'s `grid::Cell` come out as two **different, mutually-incompatible**
types from `main`'s point of view — even though both are, in every
meaningful sense, `grid.star`'s one and only `Cell` struct.

Root cause: `src/modules.rs`'s `resolve` inlines every import bottom-up and
mangles names by literally concatenating the alias chain used to *reach* a
type (`todo.md`'s own description: "one more `b__` prefix lands exactly on
`b__c__item`"), not by the type's original source file. Two different alias
paths to the same file produce two different mangled names.

**Confirmed live**: the game's first draft had `main.star` importing
`grid.star`, `snake_body.star`, and `food.star` all directly (the "obvious"
structure — one shared geometry module, two feature modules, both used from
`main`). `star check` produced over a dozen errors like:
```
error: `sb__Snake`'s field `body` (argument 1) expects type `Ring(Named("sb__grid__Cell"), 768)`, found `Ring(Named("grid__Cell"), 768)`
error: argument 1 expected type `Ring(Named("food__grid__Cell"), 768)`, found `Ring(Named("sb__grid__Cell"), 768)`
```
Three distinct mangled `Cell` types (`grid__Cell`, `sb__grid__Cell`,
`food__grid__Cell`) for one struct, depending on which import path reached
it.

**Workaround shipped here**: collapse the dependency graph into a strict
linear chain instead of a diamond. `food.star` imports `snake_body.star`
(not `grid.star` directly) and spells everything as `sb::grid::Cell`;
`main.star` imports *only* `food.star` (not `snake_body.star` separately)
and spells everything as `food::sb::grid::Cell` / `food::sb::Snake` /
`food::sb::make_snake()`. Since `main` now reaches every grid/snake type
through exactly one alias path, there's no diamond. This is verbose (three-
segment qualified paths throughout `main.star`) and only scales to a
strictly linear module graph — a real project wanting two independent
feature modules that both build on a shared foundation (exactly this game's
first, more natural attempt) cannot express that today. This is the
single most load-bearing finding in this whole exercise: it directly
confirms and sharpens `gamedev_gaps.md` item 3 ("module system still can't
back a real multi-file project's file layout") with a concrete repro,
beyond that doc's own "no search-path resolution" framing — the deeper
issue is that even hand-written relative-path imports don't compose once
more than one module shares a common dependency.

One genuine positive confirmation that came out of chasing this: the
3-hop transitive chain (`food::sb::grid::X`) works correctly for struct
construction, free functions, enum variants, *and* method calls on a
transitively-reexported struct (`snake.queue_turn(...)`, `snake.advance()`
on a `food::sb::Snake`-typed value) — `todo.md`'s own round-7 write-up only
explicitly tested struct/function/enum-variant construction at depth, not
method dispatch. That part holds up.

### 1.2 `frame:` blocks only reclaim space once per block, not per loop iteration

`docs/language_reference.md` pitches `frame:` as "ephemeral... automatically
cleaned up" and its own worked example (`astar`, an open/closed-set
pathfinding loop) implies it's safe to use inside a loop. It isn't, for any
loop with a meaningful iteration count.

Root cause (`src/codegen/stmt.rs`, `emit_frame_body`/`emit_frame_alloc`):
`@frame.off`, the bump allocator's cursor, is saved once on entry to a
`frame:` block and restored once on exit. Every `let`-bound local declared
*inside* a loop that itself runs inside the frame block bump-allocates a
**fresh** region on every single pass — nothing is reclaimed until the
whole block ends, not per iteration.

**Confirmed live**: the original `food.star` built its list of free board
cells inside a `frame:` block, looping over all 32×24 = 768 cells and
`let`-binding a `Cell` (8 bytes) each pass. Running it hit:
```
star runtime error: a `frame:` block exceeded its 4096-byte capacity
```
768 × 8 = 6144 bytes against a hardcoded, non-configurable 4096-byte cap —
and the cap would be blown by as few as ~170 struct-typed loop iterations
even in the best case. The doc's own flagship A*-over-a-grid use case
cannot actually be written the way the doc implies.

**Workaround shipped here**: don't put loops inside `frame:` blocks at all
— `food.star`'s free-cell scan is now ordinary sequential code building an
ordinary (non-frame) `List<Cell>`, which needs no bump-allocator protection
in the first place (`List<T>` is independently heap-backed/RC'd — see
`frame_analysis.rs`'s own doc comment on what it tracks; the safety
guarantee is specifically about raw struct-pointer identity, and a `List`
element is copied out by value, never a dangling pointer). `main.star`'s
`frame_demo()` instead shows a `frame:` block correctly sized for its real
budget — two small struct locals, no loop.

### 1.3 A `frame:` block ending in an explicit `return` emits invalid LLVM IR

Tried as an intermediate fix for 1.2 before landing on the workaround
above: making both branches of `spawn_food` end with `return` from inside
the `frame:` block. This type-checks cleanly but fails to compile:
```
main.ll:1444:1: error: expected instruction opcode
1 error generated.
error: clang compilation failed
```
The generated IR was:
```llvm
  ret %food__sb__grid__Cell %t209
  store i64 %t6, i64* @frame.off
}
```
`emit_frame_body` unconditionally appends the frame-offset-restore `store`
after emitting the block body, with no check for whether the body's last
statement already terminated the block with a `ret`. LLVM (correctly)
rejects any instruction after a block's terminator. This is a genuine,
reproducible codegen bug, independent of 1.2 — it would trigger for *any*
`frame:` block whose only or last-reached statement is a `return`, even a
tiny one well under the byte cap.

**Workaround shipped here**: never let a `return` be the last statement
executed inside a `frame:` block. Write into a `let mut` declared *before*
the block and return it as an ordinary trailing expression afterward.

### 1.4 A bare trailing `if cond: a else: b` is never a value — only `if` on a `let`'s RHS is

`docs/language_reference.md` says "If can be used as an expression" and
shows `let result = if x > 0: "pos" else: "neg"`. True, but incomplete: a
bare `if` at statement position *always* parses via the imperative
if-**statement** grammar (each arm an indented block), never the compact
single-line expression form — regardless of whether it's in tail/return
position. Confirmed two ways:

- A function body ending in a bare `if cond: a else: b` (no `let`, meant as
  the implicit return value) fails to parse outright:
  ```
  error: expected end of line, found identifier `a`
    |     if cond: a else: b
    |              ^
  ```
- The *checker* (not just the parser) has a matching gap: a `frame:`
  block's last statement being a bare trailing `if`/`else` (again, no
  `let`) is not recognized as the block's value by
  `Checker::trailing_value_ty`/`stmts_terminate` (`src/types/mod.rs`) —
  hit `"does not end in a value-producing expression or explicit return"`
  — even though a trailing `match` in the *exact same position* **is**
  recognized (`trailing_value_ty` has no `TypedStmt::If` arm at all, only
  `TypedStmt::Frame` and `TypedStmt::Expr`; `match`, when used as a value,
  gets wrapped in `TypedStmt::Expr(TypedExpr::Match{..})`, which the bare
  `if` case apparently never does, since it's parsed as the imperative
  `TypedStmt::If` variant instead of `TypedStmt::Expr(TypedExpr::If{..})`).

**Workaround shipped here**: always bind an `if`/`else` expression to a
`let` before using its value (`main.star`'s `pick_color` helper), and
never end a `frame:` block with a bare conditional (see 1.2/1.3's fix).

### 1.5 A fieldless enum interpolated into an f-string silently prints garbage

Not a crash, not a compile error — a **silent wrong value**. Confirmed:
```star
enum Direction:
    Up
    Down
fn main():
    println(f"dir: {Direction::Down}")
```
compiles and runs clean, printing:
```
dir: 0000000000000001
```
instead of anything resembling `Down`. Root cause: neither
`Codegen::emit_print_like` (`src/codegen/builtins.rs`) nor the general
f-string-as-value path (`src/codegen/expr.rs`) has a `Ty::Enum` arm in
their format-specifier tables; a bare enum's `i32` discriminant falls
through to the `%p` (pointer) catch-all, which C varargs happily accepts
(no crash — the value just isn't a real pointer, so nothing gets
dereferenced) and prints as a zero-padded 16-hex-digit "address". This is
the exact same bug class `todo.md`'s bug-hunting rounds 5/6 found and fixed
for `Color32`/`PaletteIndex`/every aggregate vector/matrix type — it was
just never extended to cover plain user `enum`s (or the compiler's own
builtin fieldless enums). Given every other case of this bug class produced
either an invalid-IR compile failure or visibly-wrong output, and this one
produces a plausible-looking-but-wrong hex string, it's arguably the
easiest variant of this bug class to ship without noticing.

**Workaround shipped here**: `grid.star`'s `dir_name(d: Direction) -> str`
hand-written match, used everywhere the game needs to show a direction.

### 1.6 `docs/language_reference.md`'s own ECS render-system example doesn't compile

The reference doc's "Common Patterns → Entity Component System" section
shows, verbatim:
```star
swarm e in Entities:
    draw_rect(window, e.x as i32, e.y as i32, 16, 16, Color32(255, 255, 255, 255))
```
as the idiomatic "render system". Tried standalone — it fails:
```
error: cannot call `draw_rect` inside a par/swarm body: it touches SDL's
shared window/renderer state or its global input-event queue, which
cannot be proven disjoint across worker threads
```
This is a real regression, not a documentation typo: `todo.md`'s own
bug-hunting round 5 writeup confirms *why* — SDL calls were retroactively
banned inside `par`/`swarm` bodies (`src/types/par_analysis.rs`'s
`is_banned_sdl_builtin_in_par`, covering all of `window_create`,
`window_destroy`, `window_should_close`, `clear_screen`, `draw_pixel`,
`draw_rect`, `draw_line`, `present`, `key_down`, `mouse_x`, `mouse_y`,
`mouse_button_down`) after real crashes/deadlocks were found from calling
them concurrently across the 4-worker pool. That fix was correct and
necessary, but the reference doc's own flagship render-system snippet was
never updated to match, and — worse — **there is no other way to read an
arena's contents at all**: no `.len()`, no `Arena[i]` indexed read outside
`spawn`/`despawn` (which only accept a literal/known index), no plain
`for e in Entities:`. `par`/`swarm` are the *only* arena iteration
primitives that exist, and both now reject every SDL drawing call. The
practical upshot: **an arena's contents can never be drawn to the screen
directly, period**, with the language as it stands today — not "the docs
are stale," but a real capability gap for anything wanting an ECS-style
draw loop, which is squarely within this language's own stated pitch.

**Workaround shipped here**: `main.star`'s particle burst effect uses a
hand-rolled `ParticlePool` — a plain `[Particle; 32]` struct field mutated
through ordinary `mut self` methods and looped with a plain `while`, which
is free to call `draw_pixel` because it never goes through `par`/`swarm` at
all. A real `arena Particles: Particle` is *also* kept around purely to
demonstrate `spawn`/`par`/`swarm`/`GenRef` (ticked every frame via `par`,
dumped to the console via `swarm` on the F1 debug toggle — `println` isn't
SDL, so that part is legal) but is never rendered, and its dead slots can
never be reclaimed (see 2.1 below) — it's arena-shaped weight the game
carries purely for the exercise, not something a real game would want to
ship this way.

---

## 2. Confirmed design gaps (not bugs — real, working-as-designed limits)

### 2.1 No way to conditionally reclaim (despawn) arena slots during a scan

Combining 1.6's finding with `despawn`'s own restrictions: `despawn` is
also banned inside `par`/`swarm` bodies (the same ban list `spawn`/
`frame:` already had). Since `par`/`swarm` were, at the time this was
written, the *only* way to iterate an arena's contents at all, there was no
way to write "scan every entity, despawn the ones matching some runtime
condition" — the single most common object-pool/cleanup pattern in any real
game (expired particles, dead enemies, finished timers). This game's
`Particles` arena (see 1.6) demonstrated the consequence directly: dead
particles just sat in their slots forever, uncollectable, until the fixed
1024-element arena cap was exhausted and new spawns started silently
dropping (`docs/language_reference.md`'s own documented, if alarming,
overflow behavior).

**Fixed** (follow-up compiler pass, after this write-up): `each item, idx
in ArenaName:` now optionally binds a second name to the current element's
raw slot index (`i32`), alongside the existing single-binding `each item in
ArenaName:` form. Digging into `check_despawn_stmt` while fixing this
turned up that the original framing above was slightly off: `despawn
ArenaName[idx]` never actually required a literal — `Checker::infer_expr`
accepts any `i32`-typed expression there, and `Checker::check_par_disjoint`
only ever bans `despawn` inside `par`/`swarm` bodies, never inside `each`
(sequential, single-threaded, no disjointness to prove — see `each`'s own
doc comment). The real blocker was narrower than "despawn is restricted":
`each`'s only bound name was the element itself, so there was simply no
expression in scope that *named* the slot to reclaim. Binding the index
closes that gap without touching `despawn`, `par`, or `swarm` at all —
`despawn Particles[idx]` from inside `each` is exactly as safe as any other
statement in that sequential loop body, because it always was.

This game's `Particles` arena (`main.star`) now has a `reclaim_dead_particles()`
pass (`each p, i in Particles: if p.life <= 0.0: despawn Particles[i]`)
run once per tick alongside `tick_particle_arena`, so dead particles are
actually returned to the free-list instead of accumulating forever. See
`examples/each_index_despawn.star` for a standalone repro of the pattern.

Two related gaps closed in the same pass (`gamedev_gaps.md` #4): arena
capacity is no longer one hardcoded constant shared by every arena in every
program — `arena Name: Type = N` overrides the default 1024-element
capacity per arena (`Particles` above now declares `= 256`; see
`examples/arena_capacity_configurable.star`), bounded by a generous
1,000,000-element ceiling (`crate::types::MAX_ARENA_CAPACITY`, chosen so a
`GenRef`'s fixed `i32` slot-index field and the eager `malloc` of the whole
backing array on first spawn both stay sane). The overflow warning is also
louder in the specific way that matters — it now names the arena's *actual*
configured capacity rather than a stale shared number — while additionally
being quieter in the way that matters for a real running game: it latches
after printing once per arena, instead of flooding the console every single
tick a spawner keeps trying to populate an already-full pool.

### 2.2 `spawn` is fire-and-forget — no handle to what you just spawned

`spawn ArenaName(...)` is a statement with no return value. There is no way
to get the index or a `GenRef` for the entity that call just created —
only for a slot whose index you already know independently (typically 0,
right after the arena's first-ever spawn, as `arena_freelist.star`'s own
example does). Any pattern wanting "grab a live reference to the thing I
just spawned" (a projectile's owner reference, a UI element that should
track a specific new entity) has no supported path today.

**Fixed** (follow-up compiler pass, after this write-up): `let name = spawn
ArenaName(args...)` is now also legal, with `spawn` evaluating to the raw
`i32` index of the slot it just landed in (`-1` if the arena was full and
the spawn was silently dropped — the same "safe sentinel" convention as
`GenRef`'s stale/out-of-bounds reads falling back to a zero value rather
than crashing). Feed that index straight into `GenRef<T>(idx)` to get a live
handle to the entity a `spawn` call *just* created, closing exactly the gap
above — no more only-ever-knowing-slot-0.

The bare-statement form (`spawn ArenaName(...)`, no binding) is unchanged
and still legal wherever it already worked. The expression form is
deliberately narrow: the parser only recognizes `spawn` as a value-producing
expression directly on a `let`'s right-hand side (`Parser::parse_let`) —
never nested inside another expression (a call argument, a binary operand,
a `return`). That keeps every other pass that walks expressions generically
— `par`/`swarm` disjointness (`par_analysis.rs`) and `frame:` escape
analysis (`frame_analysis.rs`) — from ever having to reason about a `spawn`
arbitrarily deep inside some other expression; both were extended to treat
`let idx = spawn ...` exactly as hazardously as the existing bare-statement
form (arena population still isn't disjoint across `par`/`swarm` worker
threads, and a frame-local struct passed as a constructor argument still
can't outlive the arena it's spawned into — both confirmed rejected, plus
confirmed rejected transitively through a helper-function call the same way
the statement form already was). See `tests/frontend.rs`'s
`*_spawn_expr_*` tests.

### 2.3 Generic structs cannot have methods

`impl Box<T>:` is a hard parse error:
```
error: expected ':', found '<'
  |    impl Box<T>:
  |            ^
```
Confirmed directly (`src/parser/items.rs`'s `parse_impl` calls a plain
`expect_ident()` for the type name, with no type-parameter parsing at all
— unlike `parse_fn_sig`, which does support `<T>` on a free function). The
existing `examples/generics.star`'s `Box<T>` is field-access-only for
exactly this reason. This game's `pick_color`/`ParticlePool` are ordinary
non-generic helpers as a result — a generic `Stack<T>`/`History<T>` wrapper
(originally planned for an "undo last move" feature) was dropped once this
was confirmed, since it's simply not expressible.

### 2.4 Fieldless enums (and structs) don't support `==`/`!=` as an operator

Despite being legal `Map`/`Set` keys (which use their own, separately
generated structural-equality function per `docs/design.md`'s "structurally
hashable" section), a bare `Direction == Direction` or `Cell == Cell` is
rejected outright by `Checker::infer_binop_ty` — only `i32`/`f32`/`bool`/
`str`/`Symbol`/`BitField<N>`/`Flags<E>`/`ptr`/`char` get an explicit
equality arm; every user `enum` and `struct` falls through to `"== is not
supported between ... and ..."`. `grid.star`'s `cell_eq`/`Snake`'s
direction-reversal check (comparing movement deltas instead of directions
directly) both exist specifically to work around this. Slightly odd
inconsistency: the type is hashable enough to dedupe in a `Set`, but not
comparable enough to write `a == b` directly.

### 2.5 No top-level `const`/`let` — every "constant" is a zero-argument function

Only `struct`/`trait`/`impl`/`fn`/`arena`/`sequence`/`enum`/`import` are
legal top-level items (`src/parser/items.rs::parse_item`); a bare top-level
`let` is a parse error. `grid.star`'s `cols()`/`rows()`/`cell_size()` are
functions purely because there's no other way to share a named constant
across modules. Minor next to the findings above, but real friction for
anything wanting shared tunable/constant values (exactly `@tweakable`'s own
pitch, which only works on a struct field, not a bare value).

---

## 3. What worked well (worth recording as much as what didn't)

- **Transitive module re-export at 3 hops, including method dispatch** —
  see 1.1's positive note.
- `Ring<T,N>` as a hand-managed deque (push new head, conditionally pop old
  tail) worked exactly as documented, including under a qualified element
  type (`Ring<sb::grid::Cell, 768>`).
- `Set<T>`/`Map<K,V>` over a plain 2-field `i32` struct (`Cell`) worked with
  zero friction.
- `Wrapping<u8>`, `BitField<8>`, `Flags<E>`, `Symbol` all worked first try,
  including printing `BitField<8>`/`Wrapping<u8>` directly in f-strings
  (unlike plain enums — see 1.5) and `Symbol` round-tripping through
  `symbol_name`.
- `sequence` coroutines (`FlashOnEat`/`GameOverFlash`) worked exactly as
  `examples/sequence.star` shows, including being constructed fresh inside
  a loop rather than once at startup.
- `par`/`swarm` safety guarantees held up under real use — mutating a loop
  variable's own fields, calling `println` (not banned) from `swarm`.
- `GenRef` staleness (`demo_genref_staleness`) reproduced
  `arena_freelist.star`'s own result exactly: a stale reference reads back
  the zero value, a fresh one reads the new occupant.
- File I/O (`file_open`/`file_write`/`file_read_line`/`file_close`/
  `file_exists`), `str_split`/`str_trim`, and a minimal `extern "C" fn
  toupper`/`atoi` FFI pair all worked with no surprises.
- Math builtins (`sin`/`cos`/`clamp`/`rand`/`rand_range`/`rand_seed`) all
  behaved exactly as documented.
- Tuples (`(i32, i32)` for pixel coordinates) and fixed arrays (`[i32; 5]`
  leaderboard, insertion-sorted by hand) worked with no friction.

---

## 4. Nice-to-have / would-help-a-real-game (extends `gamedev_gaps.md`)

- **No text/font rendering at all** (`window_create`/`draw_pixel`/
  `draw_rect`/`draw_line`/`present` is the entire drawing surface — no
  `draw_text`, no font loading). This game's score/HUD can only be printed
  to the console, never shown in the game window itself. Not previously
  called out explicitly in `gamedev_gaps.md`, and a bigger practical gap
  for "shipping something a player can read" than it might sound —
  `gamedev_gaps.md` #1 (audio/gamepad) is the documented half of "game
  language I/O still missing"; this is the other, undocumented half.
  Confirmed absent by reading every builtin `src/codegen/sdl.rs` declares.
- ~~Arena capacity (1024, hardcoded, silent-drop on overflow — already
  flagged in `gamedev_gaps.md` #4) combines badly with 2.1 above~~ — fixed
  alongside 2.1: capacity is now per-arena (`arena Name: Type = N`), and the
  overflow warning names the arena's real capacity and prints only once per
  arena instead of flooding the console every tick a full spawner keeps
  retrying.
- ~~A per-arena selective-despawn/sweep primitive (2.1)~~ — fixed, see 2.1
  above. ~~A way to get a handle to a just-spawned entity (2.2)~~ — fixed,
  see 2.2 above: `let idx = spawn ArenaName(...)` now reports the slot index
  to feed straight into `GenRef<T>(idx)`. The module search-path gap
  `gamedev_gaps.md` #3 already flags (real, but this project's diamond-
  dependency finding, 1.1, is the sharper edge of that same gap) is the
  most significant gap from this exercise still open.
