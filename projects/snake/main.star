# Star Snake -- a small, real, multi-module program (todo.md #8/gamedev_gaps.md
# item 10's own suggested "write one small real game" step) meant to exercise
# as much of the language surface as one program can reasonably reach:
# modules, structs/enums/traits/generics, closures, match, `frame`/`arena`/
# `GenRef`, `par`/`swarm`, `sequence` coroutines, `List`/`Map`/`Set`/`Ring`/
# tuples/fixed arrays, `Wrapping`/`BitField`/`Flags`, `Symbol`, file I/O,
# string/math builtins, a minimal `extern "C"` FFI call, and SDL2 graphics/
# input. See NOTES.md (this directory) for every gap/roadblock this surfaced
# -- most notably a module-diamond-dependency limitation (worked around
# below by importing `food.star` as the *only* path down to `grid`/`Snake`
# types, never `snake_body.star` directly -- see food.star's own comment)
# and a confirmed regression in `docs/language_reference.md`'s own ECS
# render-system example (SDL drawing builtins are banned inside `par`/
# `swarm` bodies, so an arena's contents can never be drawn directly --
# worked around below with a plain fixed-array particle pool instead).
#
# Build (from the repo root, SDL2 must be linked explicitly):
#   star build projects/snake/main.star -L sdl/lib/x64 -l SDL2 -o projects/snake/snake.exe
# `sdl/lib/x64/SDL2.dll` must be next to the built .exe (or on PATH) to run.
#
# Controls: arrow keys or WASD to steer, P to pause, F1 toggles a debug
# overlay printed to the console, hold Left Shift to boost, R restarts after
# a game over, Escape quits.

import "food.star" as food
import "save.star" as save

enum GameFlag:
    Paused
    Debug

# ---- Particle burst effect: a fixed-capacity, hand-rolled object pool ----
# (dead slots, `life <= 0.0`, are just overwritten by the next spawn) rather
# than an `arena`. An `arena`'s *only* iteration primitives are `par`/
# `swarm`, and every SDL drawing builtin is banned inside both (confirmed --
# see this file's own header comment and NOTES.md), so there is no way to
# draw an arena's contents at all today. `ParticlePool` below is ordinary
# sequential code instead: a `[Particle; N]` field mutated through `mut
# self` methods, looped with a plain `while`, free to call `draw_pixel`
# because it never goes through `par`/`swarm`.
struct Particle:
    mut x: f32 = 0.0
    mut y: f32 = 0.0
    mut vx: f32 = 0.0
    mut vy: f32 = 0.0
    mut life: f32 = 0.0

struct ParticlePool:
    mut items: [Particle; 32]

impl ParticlePool:
    fn spawn_burst(mut self, cx: f32, cy: f32):
        let mut placed = 0
        let mut i = 0
        while i < 32 and placed < 6:
            if self.items[i].life <= 0.0:
                let angle = rand() * 6.2831853
                let speed = 1.0 + rand() * 2.0
                self.items[i] = Particle(x = cx, y = cy, vx = cos(angle) * speed, vy = sin(angle) * speed, life = 0.45)
                placed += 1
            i += 1

    fn update(mut self, dt: f32):
        let mut i = 0
        while i < 32:
            if self.items[i].life > 0.0:
                self.items[i].life -= dt
                self.items[i].x += self.items[i].vx
                self.items[i].y += self.items[i].vy
                self.items[i].vy += 0.12
            i += 1

    fn draw(self, w: ptr):
        let mut i = 0
        while i < 32:
            if self.items[i].life > 0.0:
                let alpha = clamp(self.items[i].life * 255.0 / 0.45, 0.0, 255.0)
                draw_pixel(w, self.items[i].x as i32, self.items[i].y as i32, Color32(255, 210, 90, alpha as i32))
            i += 1

# ---- A genuine arena, purely to demonstrate spawn/par/swarm/GenRef -------
# (not rendered -- see the header comment/NOTES.md for why an arena's
# contents can't be drawn). Fed the exact same burst events as
# `ParticlePool` above, ticked by `par` every frame, and dumped to the
# console via `swarm` (println isn't in the SDL/rand/Symbol ban list, so
# this one's legal) when the debug overlay is toggled on.
arena Particles: Particle

fn tick_particle_arena(dt: f32):
    par p in Particles:
        p.life -= dt

fn dump_particle_arena():
    println("[arena] live particles (life > 0):")
    swarm p in Particles:
        if p.life > 0.0:
            println(f"  x={p.x} y={p.y} life={p.life}")

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

fn cell_px(c: food::sb::grid::Cell) -> (i32, i32):
    (c.x * food::sb::grid::cell_size(), c.y * food::sb::grid::cell_size())

fn draw_cell(w: ptr, c: food::sb::grid::Cell, color: Color32):
    let px = cell_px(c)
    draw_rect(w, px.0, px.1, food::sb::grid::cell_size() - 1, food::sb::grid::cell_size() - 1, color)

# A tiny generic-flavored helper (no generic `impl` needed -- see NOTES.md's
# "generic structs can't have methods" finding) to pick a color by a
# boolean condition, exercising `Fn(...) -> T`-shaped code reuse a little
# further.
# A `frame:` block correctly sized for its real 4096-byte capacity (see
# food.star's `spawn_food` header comment for the loop-shaped version of
# this that isn't) -- mirrors `docs/language_reference.md`'s own `astar`
# snippet almost exactly: a couple of small, genuinely ephemeral struct
# locals, added together and returned as a plain `i32` (which trivially
# escapes the frame scope safely, since only `Ty::Named` values are ever
# escape-tracked).
fn frame_demo() -> i32:
    frame:
        let node1 = food::sb::grid::Cell(x = 3, y = 4)
        let node2 = food::sb::grid::Cell(x = 10, y = 20)
        node1.x + node2.y

fn pick_color(cond: bool, a: Color32, b: Color32) -> Color32:
    # A bare statement-position `if` always parses via the imperative
    # if-STATEMENT grammar (an indented block on each arm), never the
    # compact single-line `if c: a else: b` expression form -- that form
    # only parses when it appears in an expression context (e.g. a `let`'s
    # RHS, confirmed working a few lines below and throughout this file).
    # Confirmed by a real parse error here: "expected end of line, found
    # identifier `a`" when this was written as a bare trailing
    # `if cond: a else: b`. See NOTES.md.
    let result = if cond: a else: b
    result

fn main():
    let width = food::sb::grid::cols() * food::sb::grid::cell_size()
    let height = food::sb::grid::rows() * food::sb::grid::cell_size()
    let w = window_create("Star Snake", width, height)
    if is_null(w):
        println("window_create failed")
        return

    demo_genref_staleness()
    println(f"[frame demo] node1.x + node2.y = {frame_demo()}")

    let save_path = "snake_save.txt"
    let loaded = save::load_high_score(save_path)
    let mut stats = Stats(score = 0, high_score = loaded.0, move_interval_ms = 120)
    println(f"[save] loaded high score {stats.high_score}, difficulty tag \"{loaded.1}\"")

    rand_seed(ticks())

    let mut snake = food::sb::make_snake()
    let mut food_cell = food::spawn_food(snake.body, snake.length())

    let mut flags: Flags<GameFlag> = Flags<GameFlag>()
    let mut achievements: BitField<8> = BitField<8>(0)
    let mut events: List<Symbol> = List<Symbol>()
    let mut pulse: Wrapping<u8> = Wrapping<u8>(0 as u8)
    let mut leaderboard: [i32; 5] = [0; 5]
    let mut pool = ParticlePool(items = [Particle(); 32])

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
                snake = food::sb::make_snake()
                food_cell = food::spawn_food(snake.body, snake.length())
                stats.score = 0
                events = List<Symbol>()
            last_key_r = r_now
        else:
            if key_down(up_sc) or key_down(w_sc):
                snake.queue_turn(food::sb::grid::Direction::Up)
            if key_down(down_sc) or key_down(s_sc):
                snake.queue_turn(food::sb::grid::Direction::Down)
            if key_down(left_sc) or key_down(a_sc):
                snake.queue_turn(food::sb::grid::Direction::Left)
            if key_down(right_sc) or key_down(d_sc):
                snake.queue_turn(food::sb::grid::Direction::Right)

            boosting = key_down(shift_sc)
            let effective_interval = if boosting: stats.move_interval_ms / 2 else: stats.move_interval_ms

            let now = ticks()
            if !flags_has(flags, GameFlag::Paused) and now - last_move >= effective_interval:
                last_move = now
                let prev_score = stats.score
                let new_head = snake.advance()
                events.push(Symbol("move"))

                if snake.alive and food::sb::grid::cell_eq(new_head, food_cell):
                    snake.grow(1)
                    stats.score += 10
                    events.push(Symbol("eat"))
                    let px = cell_px(food_cell)
                    let burst_x = (px.0 + food::sb::grid::cell_size() / 2) as f32
                    let burst_y = (px.1 + food::sb::grid::cell_size() / 2) as f32
                    pool.spawn_burst(burst_x, burst_y)
                    spawn Particles(burst_x, burst_y, 0.0, 0.0, 0.45)
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
            food::sb::grid::cell_size() - 1 + food_grow * 2,
            food::sb::grid::cell_size() - 1 + food_grow * 2,
            Color32(230, 90, 90, 255),
        )

        let mut i = 0
        while i < snake.length():
            let is_head = i == snake.length() - 1
            draw_cell(w, snake.body[i], pick_color(is_head, Color32(140, 230, 160, 255), Color32(80, 190, 120, 255)))
            i += 1

        pool.update(0.016)
        pool.draw(w)
        tick_particle_arena(0.016)

        if flags_has(flags, GameFlag::Debug):
            println(f"[debug] score={stats.score} high={stats.high_score} len={snake.length()} paused={flags_has(flags, GameFlag::Paused)} dir={food::sb::grid::dir_name(snake.dir)} boost={boosting}")

        present(w)
        delay(16)

    println(f"[stats] final score={stats.score} high_score={stats.high_score}")
    println(f"[stats] achievements bitfield={achievements}")
    window_destroy(w)
