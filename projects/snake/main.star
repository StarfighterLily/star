# Star Snake -- a small, real, multi-module program (todo.md #8/gamedev_gaps.md
# item 10's own suggested "write one small real game" step) meant to exercise
# as much of the language surface as one program can reasonably reach:
# modules, structs/enums/traits/generics, closures, match, `frame`/`arena`/
# `GenRef`, `par`/`swarm`/`each`, `sequence` coroutines, `List`/`Map`/`Set`/
# `Ring`/tuples/fixed arrays, `Wrapping`/`BitField`/`Flags`, `Symbol`, file
# I/O, string/math builtins, a minimal `extern "C"` FFI call, and SDL2
# graphics/input/text rendering. See NOTES.md (this directory) for every
# gap/roadblock this surfaced along the way and how each was ultimately
# closed at the compiler level -- most notably a module-diamond-dependency
# limitation (section 1.1;
# `main` imports `grid.star`, `snake_body.star`, and `food.star` directly
# below, the "obvious" diamond-shaped module graph that used to fail to
# type-check at all) and a confirmed regression in
# `docs/language_reference.md`'s own ECS render-system example (section 1.6;
# SDL drawing builtins are banned inside `par`/`swarm` bodies, but `each`
# -- added afterward -- runs sequentially and isn't, so the `Particles`
# arena below is drawn directly through it instead of the hand-rolled
# object-pool workaround this file used to carry).
#
# Build (from the repo root, SDL2 must be linked explicitly):
#   star build projects/snake/main.star -L sdl/lib/x64 -l SDL2 -o projects/snake/snake.exe
# `sdl/lib/x64/SDL2.dll` must be next to the built .exe (or on PATH) to run.
#
# Controls: arrow keys or WASD to steer, P to pause, F1 toggles a debug
# overlay printed to the console, hold Left Shift to boost, R restarts after
# a game over, Escape quits.

import "grid.star" as grid
import "snake_body.star" as sb
import "food.star" as food
import "save.star" as save

enum GameFlag:
    Paused
    Debug

# ---- Particle burst effect: a real `arena`, drawn directly via `each` -----
# This used to be two parallel systems: a hand-rolled `[Particle; 32]` pool
# (mutated with a plain `while` loop, free to call `draw_pixel` because it
# never went through `par`/`swarm`) that actually got drawn, plus a genuine
# `Particles` arena kept around only to demonstrate `spawn`/`par`/`swarm`/
# `GenRef` -- never rendered, because `par`/`swarm` were the *only* arena
# iteration primitives that existed and both ban every SDL drawing builtin
# (NOTES.md section 1.6: an arena's contents could never be drawn to the
# screen, full stop, contradicting `docs/language_reference.md`'s own
# flagship ECS render-system example). `each` closed that: it runs its body
# once per live element sequentially on the calling thread, so none of
# `par`/`swarm`'s cross-thread disjointness restrictions apply, and SDL
# drawing calls type-check fine inside it (see
# `accepts_each_calling_sdl_draw_builtins` in `tests/frontend.rs`). The
# `Particles` arena below is now the *only* particle system -- `par` still
# ticks physics every frame (mutating each loop variable's own fields, the
# exact safe pattern NOTES.md section 3 already confirmed), `each` draws and
# reclaims dead slots, and `swarm` still dumps live particles to the console
# on the F1 debug toggle.
struct Particle:
    mut x: f32 = 0.0
    mut y: f32 = 0.0
    mut vx: f32 = 0.0
    mut vy: f32 = 0.0
    mut life: f32 = 0.0

# NOTES.md section 2.1: arena capacity is per-arena now (`= 256` here),
# rather than one hardcoded 1024-element constant shared by every arena in
# the program.
arena Particles: Particle = 256

fn tick_particle_arena(dt: f32):
    par p in Particles:
        if p.life > 0.0:
            p.life -= dt
            p.x += p.vx
            p.y += p.vy
            p.vy += 0.12

fn draw_particle_arena(w: ptr):
    each p in Particles:
        if p.life > 0.0:
            let alpha = clamp(p.life * 255.0 / 0.45, 0.0, 255.0)
            draw_pixel(w, p.x as i32, p.y as i32, Color32(255, 210, 90, alpha as i32))

# NOTES.md section 2.1's own motivating pattern: scan every entity, despawn
# the ones matching a runtime condition -- impossible before `each item,
# idx in ArenaName:` existed to name the slot to reclaim (`despawn` itself
# was never actually banned outside `par`/`swarm`, there was just no
# expression naming which slot to despawn).
fn reclaim_dead_particles():
    each p, i in Particles:
        if p.life <= 0.0:
            despawn Particles[i]

fn dump_particle_arena():
    println("[arena] live particles (life > 0):")
    swarm p in Particles:
        if p.life > 0.0:
            println(f"  x={p.x} y={p.y} life={p.life}")

# NOTES.md section 2.2: `let idx = spawn ArenaName(...)` reports the raw
# slot index a spawn just landed in (`-1` if the arena was full and the
# spawn was silently dropped), closing the old "only ever knowing slot 0"
# gap -- feed it straight into `GenRef<T>(idx)` for a live handle to the
# entity that call just created. Returns the last spawned slot's index so
# `main`'s eat-handling can grab a real handle to it below, instead of only
# ever exercising this on the throwaway `Scratch` arena the way
# `demo_genref_staleness` does.
fn spawn_particle_burst(cx: f32, cy: f32) -> i32:
    let mut last_idx = 0 - 1
    let mut n = 0
    while n < 6:
        let angle = rand() * 6.2831853
        let speed = 1.0 + rand() * 2.0
        let idx = spawn Particles(cx, cy, cos(angle) * speed, sin(angle) * speed, 0.45)
        last_idx = idx
        n += 1
    last_idx

struct ScratchSlot:
    mut tag: i32

arena Scratch: ScratchSlot

struct Stats:
    @export mut score: i32 = 0
    @export mut high_score: i32 = 0
    @tweakable mut move_interval_ms: i32 = 120

sequence FlashOnEat(w: ptr):
    clear_screen(w, Color32(235, 235, 245, 255))
    present(w)
    delay(35)
    yield

sequence GameOverFlash(w: ptr):
    clear_screen(w, Color32(170, 25, 25, 255))
    present(w)
    delay(110)
    yield
    clear_screen(w, Color32(60, 10, 10, 255))
    present(w)
    delay(110)
    yield

# A self-contained, one-shot echo of arena_freelist.star/genref_lifecycle.star's
# own demonstration: spawn, capture a GenRef, despawn+respawn the same slot,
# and show the stale reference reads back a zero value while a freshly taken
# one reads the new occupant. Uses its own throwaway arena (`Scratch`) rather
# than `Particles` so this diagnostic never interacts with real gameplay
# state.
fn demo_genref_staleness():
    spawn Scratch(111)
    let stale_ref = GenRef<ScratchSlot>(0)
    despawn Scratch[0]
    spawn Scratch(222)
    let fresh_ref = GenRef<ScratchSlot>(0)
    println(f"[genref demo] stale ref reads tag={stale_ref[0].tag} (expect 0 -- despawned generation)")
    println(f"[genref demo] fresh ref reads tag={fresh_ref[0].tag} (expect 222)")

fn cell_px(c: grid::Cell) -> (i32, i32):
    (c.x * grid::CELL_SIZE, c.y * grid::CELL_SIZE)

fn draw_cell(w: ptr, c: grid::Cell, color: Color32):
    let px = cell_px(c)
    draw_rect(w, px.0, px.1, grid::CELL_SIZE - 1, grid::CELL_SIZE - 1, color)

# A tiny generic-flavored helper (no generic `impl` needed for something
# this small -- see NOTES.md section 2.3: generic struct methods now work,
# but retrofitting a one-line helper like this onto a `Box<T>`-style wrapper
# would be churn for its own sake, not something anything still blocks).
#
# The body below is now a bare trailing `if`/`else` expression -- NOTES.md
# section 1.4 confirmed a bare statement-position `if cond: a else: b` never
# parsed as a value (only `let x = if ... else ...` did), so this used to
# need a throwaway `let result = ...` binding just to return it on the next
# line. `parse_if_stmt` now reuses the same compact-arm grammar the
# expression form always had, and the checker's `trailing_value_ty` gained a
# matching `TypedStmt::If` arm, so this is a plain one-line implicit return.
fn pick_color(cond: bool, a: Color32, b: Color32) -> Color32:
    if cond: a else: b

# A `frame:` block correctly sized for its real 4096-byte capacity (see
# food.star's `spawn_food` header comment for the loop-shaped version of
# this that isn't) -- mirrors `docs/language_reference.md`'s own `astar`
# snippet almost exactly: a couple of small, genuinely ephemeral struct
# locals, added together and returned as a plain `i32` (which trivially
# escapes the frame scope safely, since only `Ty::Named` values are ever
# escape-tracked).
fn frame_demo() -> i32:
    frame:
        let node1 = grid::Cell(x = 3, y = 4)
        let node2 = grid::Cell(x = 10, y = 20)
        node1.x + node2.y

fn main():
    let width = grid::COLS * grid::CELL_SIZE
    let height = grid::ROWS * grid::CELL_SIZE
    let w = window_create("Star Snake", width, height)
    if is_null(w):
        println("window_create failed")
        return

    demo_genref_staleness()
    println(f"[frame demo] node1.x + node2.y = {frame_demo()}")

    # NOTES.md section 4's "no text/font rendering at all" gap: the score/
    # HUD used to only ever reach the console (`println`) -- `default_font`/
    # `draw_text`/`measure_text` (`crate::codegen::font`) now put it in the
    # game window itself, where a player watching it run can actually read
    # it. Loaded once (not per-frame) purely to skip the trivial per-call
    # `default_font_global` lookup every frame -- `default_font()` itself is
    # memoized and safe to call every frame regardless.
    let font = default_font()

    let save_path = "snake_save.txt"
    let loaded = save::load_high_score(save_path)
    let mut stats = Stats(score = 0, high_score = loaded.0, move_interval_ms = 120)
    println(f"[save] loaded high score {stats.high_score}, difficulty tag \"{loaded.1}\"")

    rand_seed(ticks())

    let mut snake = sb::make_snake()
    let mut food_cell = food::spawn_food(snake.body, snake.length())

    let mut flags: Flags<GameFlag> = Flags<GameFlag>()
    let mut achievements: BitField<8> = BitField<8>(0)
    let mut events: List<Symbol> = List<Symbol>()
    let mut pulse: Wrapping<u8> = Wrapping<u8>(0 as u8)
    let mut leaderboard: [i32; 5] = [0; 5]

    let mut last_move = ticks()
    let mut last_key_p = false
    let mut last_key_f1 = false
    let mut last_key_r = false
    let mut boosting = false

    let escape_sc = 41
    let p_sc = 19
    let f1_sc = 58
    let r_sc = 21
    let shift_sc = 225
    let up_sc = 82
    let down_sc = 81
    let left_sc = 80
    let right_sc = 79
    let w_sc = 26
    let s_sc = 22
    let a_sc = 4
    let d_sc = 7

    while true:
        if window_should_close(w):
            break
        if key_down(escape_sc):
            break

        let p_now = key_down(p_sc)
        if p_now and !last_key_p:
            if flags_has(flags, GameFlag::Paused):
                flags = flags_without(flags, GameFlag::Paused)
            else:
                flags = flags_with(flags, GameFlag::Paused)
        last_key_p = p_now

        let f1_now = key_down(f1_sc)
        if f1_now and !last_key_f1:
            if flags_has(flags, GameFlag::Debug):
                flags = flags_without(flags, GameFlag::Debug)
            else:
                flags = flags_with(flags, GameFlag::Debug)
                dump_particle_arena()
        last_key_f1 = f1_now

        if !snake.alive:
            let r_now = key_down(r_sc)
            if r_now and !last_key_r:
                snake = sb::make_snake()
                food_cell = food::spawn_food(snake.body, snake.length())
                stats.score = 0
                events = List<Symbol>()
            last_key_r = r_now
        else:
            if key_down(up_sc) or key_down(w_sc):
                snake.queue_turn(grid::Direction::Up)
            if key_down(down_sc) or key_down(s_sc):
                snake.queue_turn(grid::Direction::Down)
            if key_down(left_sc) or key_down(a_sc):
                snake.queue_turn(grid::Direction::Left)
            if key_down(right_sc) or key_down(d_sc):
                snake.queue_turn(grid::Direction::Right)

            boosting = key_down(shift_sc)
            let effective_interval = if boosting: stats.move_interval_ms / 2 else: stats.move_interval_ms

            let now = ticks()
            if !flags_has(flags, GameFlag::Paused) and now - last_move >= effective_interval:
                last_move = now
                let prev_score = stats.score
                let new_head = snake.advance()
                events.push(Symbol("move"))

                if snake.alive and new_head == food_cell:
                    snake.grow(1)
                    stats.score += 10
                    events.push(Symbol("eat"))
                    let px = cell_px(food_cell)
                    let burst_x = (px.0 + grid::CELL_SIZE / 2) as f32
                    let burst_y = (px.1 + grid::CELL_SIZE / 2) as f32
                    let last_particle_idx = spawn_particle_burst(burst_x, burst_y)
                    if flags_has(flags, GameFlag::Debug) and last_particle_idx >= 0:
                        let handle = GenRef<Particle>(last_particle_idx)
                        println(f"[spawn handle] particle just spawned at slot {last_particle_idx}, life={handle[0].life}")
                    let mut flash = FlashOnEat(w)
                    let mut flashing = true
                    while flashing:
                        flashing = flash.resume()
                    food_cell = food::spawn_food(snake.body, snake.length())
                    if stats.score / 50 > prev_score / 50:
                        let milestone = stats.score / 50
                        if milestone >= 1 and milestone <= 8:
                            achievements = bit_set(achievements, milestone - 1)
                            println(f"[achievement] unlocked milestone {milestone} -- badges now {achievements}")
                    if stats.score > stats.high_score:
                        stats.high_score = stats.score

                if !snake.alive:
                    events.push(Symbol("die"))
                    println(f"[events] final event: {symbol_name(events[events.len() - 1])}")
                    save::save_high_score(save_path, stats.high_score, "normal")

                    let mut slot = 4
                    while slot >= 0:
                        if slot == 0 or stats.score <= leaderboard[slot - 1]:
                            leaderboard[slot] = stats.score
                            break
                        leaderboard[slot] = leaderboard[slot - 1]
                        slot -= 1

                    println(f"[leaderboard] {leaderboard[0]}, {leaderboard[1]}, {leaderboard[2]}, {leaderboard[3]}, {leaderboard[4]}")

                    let mut over = GameOverFlash(w)
                    let mut over_running = true
                    while over_running:
                        over_running = over.resume()

        pulse = pulse + Wrapping<u8>(1 as u8)
        let pulse_f = (pulse as u8) as f32
        let food_scale = sin(pulse_f * 0.15) * 2.0

        clear_screen(w, Color32(18, 18, 24, 255))

        let food_px = cell_px(food_cell)
        let food_grow = food_scale as i32
        draw_rect(
            w,
            food_px.0 - food_grow,
            food_px.1 - food_grow,
            grid::CELL_SIZE - 1 + food_grow * 2,
            grid::CELL_SIZE - 1 + food_grow * 2,
            Color32(230, 90, 90, 255),
        )

        let mut i = 0
        while i < snake.length():
            let is_head = i == snake.length() - 1
            draw_cell(w, snake.body[i], pick_color(is_head, Color32(140, 230, 160, 255), Color32(80, 190, 120, 255)))
            i += 1

        tick_particle_arena(0.016)
        draw_particle_arena(w)
        reclaim_dead_particles()

        draw_text(w, font, f"SCORE: {stats.score}", 6, 6, 2, Color32(240, 240, 245, 255))
        draw_text(w, font, f"HIGH: {stats.high_score}", 6, 24, 2, Color32(190, 190, 200, 255))

        if flags_has(flags, GameFlag::Paused):
            let msg = "PAUSED"
            let sz = measure_text(font, msg, 3)
            draw_text(w, font, msg, (width - sz.0) / 2, (height - sz.1) / 2, 3, Color32(255, 220, 90, 255))

        if !snake.alive:
            let line1 = "GAME OVER"
            let line2 = "PRESS R TO RESTART"
            let sz1 = measure_text(font, line1, 3)
            let sz2 = measure_text(font, line2, 2)
            let y1 = height / 2 - sz1.1 - 6
            draw_text(w, font, line1, (width - sz1.0) / 2, y1, 3, Color32(230, 90, 90, 255))
            draw_text(w, font, line2, (width - sz2.0) / 2, height / 2 + 6, 2, Color32(230, 230, 235, 255))

        if flags_has(flags, GameFlag::Debug):
            println(f"[debug] score={stats.score} high={stats.high_score} len={snake.length()} paused={flags_has(flags, GameFlag::Paused)} dir={snake.dir} boost={boosting}")

        present(w)
        delay(16)

    println(f"[stats] final score={stats.score} high_score={stats.high_score}")
    println(f"[stats] achievements bitfield={achievements}")
    window_destroy(w)
