# Food placement: builds the set of currently-free cells fresh every time
# food needs to respawn (only once per eat, so an O(board size) scan per
# spawn is cheap) and picks one at random.
#
# Imports `grid.star` directly -- the "obvious" thing to do, since this
# file's own logic has nothing to do with `Snake`. That used to be
# impossible: `main.star` also needs `snake_body.star` (which itself imports
# `grid.star`), and reaching `grid::Cell` through two independent alias
# paths (`food::grid::Cell` vs `sb::grid::Cell`) used to come out as two
# *different*, mutually-incompatible mangled types (`src/modules.rs` inlined
# and mangled by literal alias chain, not source-file identity) -- a real
# module-diamond-dependency bug this project's first draft hit directly (see
# NOTES.md section 1.1). The only workaround at the time was collapsing the
# whole dependency graph into one linear chain (this file importing
# `snake_body.star` just to reach `grid` through it, spelling everything
# `sb::grid::X`). `crate::modules::dedupe_by_origin` now tags every
# top-level item with its true source-file provenance and collapses
# same-provenance duplicates regardless of how many alias paths reach them,
# so the diamond `main -> {food, snake_body} -> grid` shape below just works
# -- see NOTES.md 1.1 for the fix writeup and
# `resolve_collapses_diamond_dependency_to_one_struct_definition` /
# `runtime_diamond_dependency_import_unifies_shared_struct_type_end_to_end`
# in `tests/frontend.rs` for the standalone repro.
import "grid.star" as grid

fn occupied_cells(body: Ring<grid::Cell, 768>, len: i32) -> Set<grid::Cell>:
    let mut occ: Set<grid::Cell> = Set<grid::Cell>()
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
# example make for exactly this shape). It didn't work at the time: `@frame.off`
# (the bump allocator's cursor, `src/codegen/stmt.rs`) was only saved/
# restored once, around the *entire* `frame:` block -- never per loop
# iteration -- so a `let`-bound struct local declared inside a loop that ran
# inside a `frame:` block kept consuming fresh bump-allocator bytes on every
# single pass, with nothing reclaimed until the whole block exited. A `let c
# = Cell(x=x, y=y)` on every one of this board's 768 cells (8 bytes each)
# needed 6144 bytes against a hardcoded, non-configurable 4096-byte cap --
# and reliably crashed with the runtime's own "a `frame:` block exceeded its
# 4096-byte capacity" abort well before the scan finished (NOTES.md section
# 1.2). That's now fixed too -- `frame:` reclaims each loop iteration's bytes
# before the next one starts, so the original loop-inside-`frame:` shape
# would work today (see `runtime_for_loop_inside_frame_block_reclaims_
# space_per_iteration_end_to_end` in `tests/frontend.rs`). Left as plain
# sequential code building an ordinary `List<Cell>` anyway: `List<T>` never
# needed `frame:`'s safety net in the first place (it's independently
# heap-backed/RC'd, not a raw struct pointer -- see `frame_analysis.rs`'s own
# doc comment on what it tracks), so reaching for `frame:` here would only
# add a byte-budget to think about for zero benefit.
fn spawn_food(body: Ring<grid::Cell, 768>, len: i32) -> grid::Cell:
    let occ = occupied_cells(body, len)
    let mut free_cells: List<grid::Cell> = List<grid::Cell>()
    let mut y = 0
    while y < grid::ROWS:
        let mut x = 0
        while x < grid::COLS:
            if !occ.contains(grid::Cell(x = x, y = y)):
                free_cells.push(grid::Cell(x = x, y = y))
            x += 1
        y += 1
    if free_cells.len() == 0:
        # Board full -- the snake has eaten literally every cell.
        return grid::Cell(x = 0 - 1, y = 0 - 1)
    let idx = rand_range(0, free_cells.len())
    free_cells[idx]
