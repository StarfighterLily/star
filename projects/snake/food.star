# Food placement: builds the set of currently-free cells fresh every time
# food needs to respawn (only once per eat, so an O(board size) scan per
# spawn is cheap) and picks one at random.
#
# NOTE: imports `snake_body.star` (not `grid.star` directly) purely to reach
# `grid::Cell`/`grid::Direction` through the SAME import chain `main.star`
# will also use for `sb::Snake`. Importing `grid.star` directly here (the
# "obvious" thing to do, since this file's own logic has nothing to do with
# `Snake`) creates a diamond: two independent import paths from `main.star`
# down to what should be one shared type. Star's module system inlines and
# mangles types by the literal alias chain used to reach them
# (`src/modules.rs`), not by original source file identity, so
# `food::grid::Cell` (reached via a direct import here) and `sb::grid::Cell`
# (reached via `snake_body.star`) come out as two *different*,
# mutually-incompatible mangled types -- `Named("food__grid__Cell")` vs
# `Named("sb__grid__Cell")` -- even though both are, in every other sense,
# `grid.star`'s exact same `Cell` struct. Confirmed live: the first version
# of this file imported `grid.star` directly and every call site in
# `main.star` passing a `sb::Snake`'s `Ring<Cell,768>` body into
# `spawn_food` failed to type-check with exactly that mismatch. See
# NOTES.md's "module diamond dependency" finding for the full writeup --
# this workaround (route every dependent module through one linear chain)
# is the only one available given the current module system, and it's the
# reason this file reaches grid types as `sb::grid::X` throughout instead of
# a plain `grid::X`.
import "snake_body.star" as sb

fn occupied_cells(body: Ring<sb::grid::Cell, 768>, len: i32) -> Set<sb::grid::Cell>:
    let mut occ: Set<sb::grid::Cell> = Set<sb::grid::Cell>()
    let mut i = 0
    while i < len:
        occ.insert(body[i])
        i += 1
    occ

# Picks a uniformly random free cell.
#
# NOTE: this was ORIGINALLY written with the whole free-cell scan inside a
# `frame:` block (the textbook "ephemeral, tick-scoped allocation" pitch
# `docs/language_reference.md`'s own Frame Memory section and `astar`
# example make for exactly this shape). It doesn't work: `@frame.off` (the
# bump allocator's cursor, `src/codegen/stmt.rs`) is only saved/restored
# once, around the *entire* `frame:` block -- never per loop iteration. Any
# `let`-bound struct local declared inside a loop that runs inside a
# `frame:` block keeps consuming fresh bump-allocator bytes on every single
# pass, with nothing reclaimed until the whole block exits. A `let c = Cell
# (x=x, y=y)` on every one of this board's 768 cells (8 bytes each) needs
# 6144 bytes against a hardcoded, non-configurable 4096-byte cap -- and it
# reliably crashed with the runtime's own "a `frame:` block exceeded its
# 4096-byte capacity" abort well before the scan finished. This isn't a
# tuning nit: 4096 bytes divided across a real per-frame allocation pattern
# (a handful of small structs) is fine, but the doc's own flagship "A*
# open/closed set" use case is exactly a loop like this one, and it can't
# actually fit. See NOTES.md for the full writeup and `main.star`'s
# `frame_demo` for a `frame:` use small enough to actually stay in budget.
# `List<Cell>` doesn't need `frame:` for safety in the first place (it's
# independently heap-backed/RC'd, not a raw struct pointer -- see
# `frame_analysis.rs`'s own doc comment on what it tracks), so the fix here
# is simply: don't put a real loop inside a `frame:` block at all.
fn spawn_food(body: Ring<sb::grid::Cell, 768>, len: i32) -> sb::grid::Cell:
    let occ = occupied_cells(body, len)
    let mut free_cells: List<sb::grid::Cell> = List<sb::grid::Cell>()
    let mut y = 0
    while y < sb::grid::rows():
        let mut x = 0
        while x < sb::grid::cols():
            if !occ.contains(sb::grid::Cell(x = x, y = y)):
                free_cells.push(sb::grid::Cell(x = x, y = y))
            x += 1
        y += 1
    if free_cells.len() == 0:
        # Board full -- the snake has eaten literally every cell.
        return sb::grid::Cell(x = 0 - 1, y = 0 - 1)
    let idx = rand_range(0, free_cells.len())
    free_cells[idx]
