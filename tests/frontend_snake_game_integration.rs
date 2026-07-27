//! `projects/snake` game-logic coverage (incl. particle system)
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== `projects/snake` game-logic coverage ================================
//
// The tests above exercise individual language features in isolation; the
// ones below exercise the actual shapes `projects/snake`'s modules ship --
// board wraparound, turn-reversal rejection, self-collision, food placement
// avoiding occupied cells, and the arena-backed particle system -- as
// standalone, directly-assertable repros of the real game logic, run
// through the compiler and executed for real rather than just read by eye.
// Where a snippet is close enough to a real module's function to keep in
// sync, its body is copied verbatim from `projects/snake/{grid,snake_body,
// food,main}.star` rather than paraphrased.

/// `grid::wrap`'s four edge cases (off each side by exactly one) and one
/// interior point that should pass through unchanged. Board is 32x24
/// (`grid::COLS`/`grid::ROWS`), matching the shipped game exactly.
#[test]
fn runtime_snake_grid_wrap_handles_all_four_edges_end_to_end() {
    let src = "\
struct Cell:\n    x: i32\n    y: i32\n\n\
const COLS: i32 = 32\n\
const ROWS: i32 = 24\n\n\
fn wrap(c: Cell) -> Cell:\n    \
    let mut x = c.x\n    \
    let mut y = c.y\n    \
    if x < 0:\n        x = COLS - 1\n    \
    if x >= COLS:\n        x = 0\n    \
    if y < 0:\n        y = ROWS - 1\n    \
    if y >= ROWS:\n        y = 0\n    \
    Cell(x = x, y = y)\n\n\
fn main():\n    \
    let a = wrap(Cell(x = 0 - 1, y = 5))\n    \
    let b = wrap(Cell(x = 32, y = 5))\n    \
    let c = wrap(Cell(x = 5, y = 0 - 1))\n    \
    let d = wrap(Cell(x = 5, y = 24))\n    \
    let e = wrap(Cell(x = 16, y = 12))\n    \
    println(f\"{a.x},{a.y} {b.x},{b.y} {c.x},{c.y} {d.x},{d.y} {e.x},{e.y}\")\n";
    let output = compile_and_run("snake_grid_wrap_handles_all_four_edges", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "31,5 0,5 5,23 5,0 16,12");
}

/// `grid::opposite` composed with itself must be the identity for every
/// direction (turning around twice faces the original way), and no
/// direction is its own opposite -- the exact property `Snake::queue_turn`'s
/// reversal check relies on.
#[test]
fn runtime_snake_grid_opposite_is_involution_end_to_end() {
    let src = "enum Direction:\n    Up\n    Down\n    Left\n    Right\n\nfn opposite(d: Direction) -> Direction:\n    match d:\n        Direction::Up -> Direction::Down\n        Direction::Down -> Direction::Up\n        Direction::Left -> Direction::Right\n        Direction::Right -> Direction::Left\n\nfn main():\n    println(f\"{opposite(opposite(Direction::Up)) == Direction::Up}\")\n    println(f\"{opposite(opposite(Direction::Left)) == Direction::Left}\")\n    println(f\"{opposite(Direction::Up) == Direction::Up}\")\n";
    let output = compile_and_run("snake_grid_opposite_is_involution", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "true", "false"]);
}

const SNAKE_BODY_SRC_PREFIX: &str = "\
struct Cell:\n    x: i32\n    y: i32\n\n\
enum Direction:\n    Up\n    Down\n    Left\n    Right\n\n\
fn delta(d: Direction) -> Cell:\n    \
    match d:\n        \
        Direction::Up -> Cell(x = 0, y = 0 - 1)\n        \
        Direction::Down -> Cell(x = 0, y = 1)\n        \
        Direction::Left -> Cell(x = 0 - 1, y = 0)\n        \
        Direction::Right -> Cell(x = 1, y = 0)\n\n\
fn opposite(d: Direction) -> Direction:\n    \
    match d:\n        \
        Direction::Up -> Direction::Down\n        \
        Direction::Down -> Direction::Up\n        \
        Direction::Left -> Direction::Right\n        \
        Direction::Right -> Direction::Left\n\n\
fn wrap(c: Cell) -> Cell:\n    \
    let mut x = c.x\n    \
    let mut y = c.y\n    \
    if x < 0:\n        x = 31\n    \
    if x >= 32:\n        x = 0\n    \
    if y < 0:\n        y = 23\n    \
    if y >= 24:\n        y = 0\n    \
    Cell(x = x, y = y)\n\n\
fn cell_add(a: Cell, b: Cell) -> Cell:\n    Cell(x = a.x + b.x, y = a.y + b.y)\n\n\
struct Snake:\n    \
    mut body: Ring<Cell, 768>\n    \
    mut dir: Direction\n    \
    mut pending_dir: Direction\n    \
    mut grow_pending: i32\n    \
    mut alive: bool\n\n\
impl Snake:\n    \
    fn head(self) -> Cell:\n        self.body[self.body.len() - 1]\n\n    \
    fn length(self) -> i32:\n        self.body.len()\n\n    \
    fn contains(self, c: Cell) -> bool:\n        \
        let mut i = 0\n        \
        let mut found = false\n        \
        while i < self.body.len():\n            \
            if self.body[i] == c:\n                found = true\n            \
            i += 1\n        \
        found\n\n    \
    fn queue_turn(mut self, d: Direction):\n        \
        let is_reversal = d == opposite(self.dir)\n        \
        if !is_reversal:\n            self.pending_dir = d\n\n    \
    fn grow(mut self, amount: i32):\n        self.grow_pending += amount\n\n    \
    fn advance(mut self) -> Cell:\n        \
        self.dir = self.pending_dir\n        \
        let new_head = wrap(cell_add(self.head(), delta(self.dir)))\n        \
        if self.contains(new_head):\n            self.alive = false\n        \
        self.body.push(new_head)\n        \
        if self.grow_pending > 0:\n            self.grow_pending -= 1\n        \
        else:\n            self.body.pop()\n        \
        new_head\n\n\
fn make_snake() -> Snake:\n    \
    let mut s = Snake(\n        \
        body = Ring<Cell, 768>(),\n        \
        dir = Direction::Right,\n        \
        pending_dir = Direction::Right,\n        \
        grow_pending = 2,\n        \
        alive = true,\n    \
    )\n    \
    s.body.push(Cell(x = 5, y = 12))\n    \
    s.body.push(Cell(x = 6, y = 12))\n    \
    s.body.push(Cell(x = 7, y = 12))\n    \
    s\n\n";

/// `Snake::queue_turn` ignores a direct reversal (turning `Left` while
/// already moving `Right`) but accepts every non-reversal turn, exactly
/// `snake_body.star`'s own reversal-prevention rule -- and relies on
/// `Direction == Direction` (NOTES.md section 2.4) compiling directly.
#[test]
fn runtime_snake_body_queue_turn_ignores_direct_reversal_end_to_end() {
    let src = format!(
        "{}fn main():\n    let mut s = make_snake()\n    s.queue_turn(Direction::Left)\n    println(f\"{{s.pending_dir == Direction::Right}}\")\n    s.queue_turn(Direction::Up)\n    println(f\"{{s.pending_dir == Direction::Up}}\")\n",
        SNAKE_BODY_SRC_PREFIX
    );
    let output = compile_and_run("snake_body_queue_turn_ignores_direct_reversal", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "true"], "reversal must be rejected, non-reversal turns must be accepted");
}

/// `Snake::advance` grows the body by exactly `grow_pending` ticks' worth of
/// segments and then stops growing -- `make_snake()` starts with
/// `grow_pending = 2` and a 3-segment body, so after 2 ticks it should be
/// length 5, and after a 3rd (non-growing) tick still length 5, not 6.
#[test]
fn runtime_snake_body_advance_grows_exactly_grow_pending_ticks_end_to_end() {
    let src = format!(
        "{}fn main():\n    let mut s = make_snake()\n    s.advance()\n    println(f\"{{s.length()}}\")\n    s.advance()\n    println(f\"{{s.length()}}\")\n    s.advance()\n    println(f\"{{s.length()}}\")\n",
        SNAKE_BODY_SRC_PREFIX
    );
    let output = compile_and_run("snake_body_advance_grows_exactly_grow_pending_ticks", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["4", "5", "5"]);
}

/// Self-collision: a snake long enough to double back on itself must die
/// (`alive` flips to `false`) the tick its new head lands on an existing
/// body segment, and must stay alive on every tick before that.
///
/// `grow_pending` is set high enough that the body never pops its tail
/// across this whole sequence, so the body set only ever grows -- makes the
/// self-collision deterministic by construction: starting body
/// (5,12)-(6,12)-(7,12), heading Right, tracing a tight Right/Down/Left/Up
/// square re-enters (7,12) (still present, since nothing was ever popped)
/// on exactly the 4th move, and nowhere before it.
#[test]
fn runtime_snake_body_advance_dies_on_self_collision_end_to_end() {
    let src = format!(
        "{}fn main():\n    let mut s = make_snake()\n    s.grow_pending = 100\n    s.advance()\n    println(f\"{{s.alive}}\")\n    s.queue_turn(Direction::Down)\n    s.advance()\n    println(f\"{{s.alive}}\")\n    s.queue_turn(Direction::Left)\n    s.advance()\n    println(f\"{{s.alive}}\")\n    s.queue_turn(Direction::Up)\n    s.advance()\n    println(f\"{{s.alive}}\")\n",
        SNAKE_BODY_SRC_PREFIX
    );
    let output = compile_and_run("snake_body_advance_dies_on_self_collision", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "true", "true", "false"], "snake should stay alive until the exact tick the head re-enters its own body");
}

/// `food::occupied_cells`/`spawn_food`: on a tiny 2x1 board fully occupied
/// except one cell, `spawn_food` must deterministically return that one
/// free cell every time (no free-cell choice to randomize over), and must
/// never return a cell the snake's body occupies.
#[test]
fn runtime_snake_food_spawn_food_avoids_occupied_cells_end_to_end() {
    let src = "\
struct Cell:\n    x: i32\n    y: i32\n\n\
fn occupied_cells(body: Ring<Cell, 4>, len: i32) -> Set<Cell>:\n    \
    let mut occ: Set<Cell> = Set<Cell>()\n    \
    let mut i = 0\n    \
    while i < len:\n        occ.insert(body[i])\n        i += 1\n    \
    occ\n\n\
fn spawn_food(body: Ring<Cell, 4>, len: i32, cols: i32, rows: i32) -> Cell:\n    \
    let occ = occupied_cells(body, len)\n    \
    let mut free_cells: List<Cell> = List<Cell>()\n    \
    let mut y = 0\n    \
    while y < rows:\n        \
        let mut x = 0\n        \
        while x < cols:\n            \
            if !occ.contains(Cell(x = x, y = y)):\n                free_cells.push(Cell(x = x, y = y))\n            \
            x += 1\n        \
        y += 1\n    \
    if free_cells.len() == 0:\n        return Cell(x = 0 - 1, y = 0 - 1)\n    \
    let idx = rand_range(0, free_cells.len())\n    \
    free_cells[idx]\n\n\
fn main():\n    \
    rand_seed(1)\n    \
    let mut body: Ring<Cell, 4> = Ring<Cell, 4>()\n    \
    body.push(Cell(x = 0, y = 0))\n    \
    let mut n = 0\n    \
    while n < 5:\n        \
        let f = spawn_food(body, 1, 2, 1)\n        \
        println(f\"{f.x},{f.y}\")\n        \
        n += 1\n";
    let output = compile_and_run("snake_food_spawn_food_avoids_occupied_cells", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    // Board is 2x1 ((0,0) and (1,0)); (0,0) is occupied, so the only free
    // cell is (1,0) -- every one of the 5 repeated picks must land there.
    for line in stdout.lines() {
        assert_eq!(line, "1,0", "spawn_food must never return the occupied cell {:?}", stdout);
    }
    assert_eq!(stdout.lines().count(), 5);
}

/// `food::spawn_food`'s documented full-board fallback: with every cell
/// occupied, it must return the `(-1, -1)` sentinel rather than looping
/// forever or picking an occupied cell.
#[test]
fn runtime_snake_food_spawn_food_returns_sentinel_when_board_full_end_to_end() {
    let src = "\
struct Cell:\n    x: i32\n    y: i32\n\n\
fn occupied_cells(body: Ring<Cell, 2>, len: i32) -> Set<Cell>:\n    \
    let mut occ: Set<Cell> = Set<Cell>()\n    \
    let mut i = 0\n    \
    while i < len:\n        occ.insert(body[i])\n        i += 1\n    \
    occ\n\n\
fn spawn_food(body: Ring<Cell, 2>, len: i32, cols: i32, rows: i32) -> Cell:\n    \
    let occ = occupied_cells(body, len)\n    \
    let mut free_cells: List<Cell> = List<Cell>()\n    \
    let mut y = 0\n    \
    while y < rows:\n        \
        let mut x = 0\n        \
        while x < cols:\n            \
            if !occ.contains(Cell(x = x, y = y)):\n                free_cells.push(Cell(x = x, y = y))\n            \
            x += 1\n        \
        y += 1\n    \
    if free_cells.len() == 0:\n        return Cell(x = 0 - 1, y = 0 - 1)\n    \
    let idx = rand_range(0, free_cells.len())\n    \
    free_cells[idx]\n\n\
fn main():\n    \
    rand_seed(1)\n    \
    let mut body: Ring<Cell, 2> = Ring<Cell, 2>()\n    \
    body.push(Cell(x = 0, y = 0))\n    \
    body.push(Cell(x = 1, y = 0))\n    \
    let f = spawn_food(body, 2, 2, 1)\n    \
    println(f\"{f.x},{f.y}\")\n";
    let output = compile_and_run("snake_food_spawn_food_returns_sentinel_when_board_full", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "-1,-1");
}

// ===== `projects/snake/main.star`'s particle system (arena + `par`/`each`) =

const SNAKE_PARTICLE_SRC_PREFIX: &str = "\
struct Particle:\n    \
    mut x: f32 = 0.0\n    \
    mut y: f32 = 0.0\n    \
    mut vx: f32 = 0.0\n    \
    mut vy: f32 = 0.0\n    \
    mut life: f32 = 0.0\n\n\
arena Particles: Particle = 256\n\n\
fn tick_particle_arena(dt: f32):\n    \
    par p in Particles:\n        \
        if p.life > 0.0:\n            \
            p.life -= dt\n            \
            p.x += p.vx\n            \
            p.y += p.vy\n            \
            p.vy += 0.12\n\n\
fn reclaim_dead_particles():\n    \
    each p, i in Particles:\n        \
        if p.life <= 0.0:\n            despawn Particles[i]\n\n\
fn count_live_particles() -> i32:\n    \
    let mut n = 0\n    \
    each p in Particles:\n        \
        if p.life > 0.0:\n            n += 1\n    \
    n\n\n";

/// `main.star`'s `spawn_particle_burst`: `let idx = spawn Particles(...)`
/// (NOTES.md section 2.2's spawn-handle form) reports the slot a spawn just
/// landed in, and a `GenRef<Particle>(idx)` built from that index reads back
/// exactly the constructor arguments just passed -- the real gameplay use
/// this closes (grabbing a live handle to the entity a call *just*
/// created), not just the isolated `Scratch`-arena demo.
#[test]
fn runtime_snake_particle_spawn_handle_reads_back_via_genref_end_to_end() {
    let src = format!(
        "{}fn main():\n    let idx = spawn Particles(1.0, 2.0, 0.5, 0.0 - 0.5, 0.45)\n    let handle = GenRef<Particle>(idx)\n    println(f\"{{idx}} {{handle[0].x}} {{handle[0].y}} {{handle[0].life}}\")\n",
        SNAKE_PARTICLE_SRC_PREFIX
    );
    let output = compile_and_run("snake_particle_spawn_handle_reads_back_via_genref", &src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "0 1.000000 2.000000 0.450000");
}

/// `tick_particle_arena` (`par`, decrementing `life` and integrating
/// position every frame) composed with `reclaim_dead_particles` (`each` +
/// `despawn`, NOTES.md section 2.1): a short-lived particle should vanish
/// from the live count after enough ticks, while a long-lived one survives.
#[test]
fn runtime_snake_particle_tick_and_reclaim_removes_only_dead_particles_end_to_end() {
    let src = format!(
        "{}fn main():\n    spawn Particles(0.0, 0.0, 0.0, 0.0, 0.05)\n    spawn Particles(0.0, 0.0, 0.0, 0.0, 10.0)\n    println(f\"{{count_live_particles()}}\")\n    tick_particle_arena(0.1)\n    reclaim_dead_particles()\n    println(f\"{{count_live_particles()}}\")\n",
        SNAKE_PARTICLE_SRC_PREFIX
    );
    let output = compile_and_run("snake_particle_tick_and_reclaim_removes_only_dead_particles", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["2", "1"], "one 0.05s-life particle should die from a 0.1s tick; the 10s one should survive");
}

/// `draw_particle_arena`'s real shape (`each p in Particles: ... draw_pixel
/// ...`) -- the capability NOTES.md section 1.6 found completely missing
/// (an arena's contents could never be drawn to the screen at all, since
/// `par`/`swarm` were the only iteration primitives and both ban every SDL
/// drawing builtin). Run against a real, dummy-driver SDL window so this is
/// the actual drawing call, not just a type-check.
#[test]
fn runtime_snake_particle_each_draws_live_particles_via_sdl_end_to_end() {
    let src = format!(
        "{}fn main():\n    spawn Particles(4.0, 5.0, 0.0, 0.0, 0.45)\n    spawn Particles(9.0, 9.0, 0.0, 0.0, 0.0)\n    let w = window_create(\"t\", 64, 48)\n    clear_screen(w, Color32(0, 0, 0, 255))\n    let mut drawn = 0\n    each p in Particles:\n        if p.life > 0.0:\n            draw_pixel(w, p.x as i32, p.y as i32, Color32(255, 210, 90, 255))\n            drawn += 1\n    present(w)\n    println(f\"{{drawn}}\")\n    window_destroy(w)\n",
        SNAKE_PARTICLE_SRC_PREFIX
    );
    let output = compile_and_run_sdl("snake_particle_each_draws_live_particles_via_sdl", &src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "1", "only the live (life > 0) particle should be drawn");
}
