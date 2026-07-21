# Shared grid geometry: cell coordinates, compass directions, and the board
# dimensions every other module needs to agree on. No `main` -- a pure
# library file, imported via `import "grid.star" as grid`.
#
# NOTE: Star has no top-level `let`/`const` -- only `struct`/`enum`/`trait`/
# `impl`/`fn`/`arena`/`sequence` are legal top-level items (confirmed via
# `src/parser/items.rs::parse_item`). Board-size "constants" are therefore
# zero-argument functions instead of shared globals.

struct Cell:
    x: i32
    y: i32

enum Direction:
    Up
    Down
    Left
    Right

fn cols() -> i32:
    32

fn rows() -> i32:
    24

fn cell_size() -> i32:
    20

# Fieldless enums do NOT support `==`/`!=` directly (only `i32`/`f32`/`bool`/
# `str`/`Symbol`/`BitField`/`Flags`/`ptr`/`char` get an equality arm in
# `Checker::infer_binop_ty` -- a bare user `enum` falls through to the
# generic "not supported between" error). Structs have the same gap. Both
# need a hand-written field/variant comparison helper instead.
fn cell_eq(a: Cell, b: Cell) -> bool:
    a.x == b.x and a.y == b.y

fn delta(d: Direction) -> Cell:
    match d:
        Direction::Up -> Cell(x = 0, y = 0 - 1)
        Direction::Down -> Cell(x = 0, y = 1)
        Direction::Left -> Cell(x = 0 - 1, y = 0)
        Direction::Right -> Cell(x = 1, y = 0)

fn opposite(d: Direction) -> Direction:
    match d:
        Direction::Up -> Direction::Down
        Direction::Down -> Direction::Up
        Direction::Left -> Direction::Right
        Direction::Right -> Direction::Left

# Fieldless enums also can't be interpolated into an f-string (no `Ty::Enum`
# arm in the f-string/print formatting tables -- falls through to the `%p`
# vararg catch-all, the same invalid-IR bug class the historical
# Color32/aggregate-vector f-string bugs were, per todo.md's bug-hunting
# rounds 5/6). Route any HUD/console text through this instead of `f"{d}"`.
fn dir_name(d: Direction) -> str:
    match d:
        Direction::Up -> "Up"
        Direction::Down -> "Down"
        Direction::Left -> "Left"
        Direction::Right -> "Right"

# Wrap a cell around the board edges (borderless/classic-arcade mode) --
# self-collision is the only death condition in this build.
fn wrap(c: Cell) -> Cell:
    let mut x = c.x
    let mut y = c.y
    if x < 0:
        x = cols() - 1
    if x >= cols():
        x = 0
    if y < 0:
        y = rows() - 1
    if y >= rows():
        y = 0
    Cell(x = x, y = y)

fn cell_add(a: Cell, b: Cell) -> Cell:
    Cell(x = a.x + b.x, y = a.y + b.y)
