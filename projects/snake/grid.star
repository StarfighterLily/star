# Shared grid geometry: cell coordinates, compass directions, and the board
# dimensions every other module needs to agree on. No `main` -- a pure
# library file, imported via `import "grid.star" as grid`.
#
# Board-size "constants" are genuine top-level `const`s (NOTES.md 2.5 --
# previously the only way to share a named value across a module was a
# zero-argument function; a real repro of that gap sat here until the
# compiler grew `const NAME: Type = <constant expr>` as a top-level item).

struct Cell:
    x: i32
    y: i32

enum Direction:
    Up
    Down
    Left
    Right

const COLS: i32 = 32
const ROWS: i32 = 24
const CELL_SIZE: i32 = 20

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
        x = COLS - 1
    if x >= COLS:
        x = 0
    if y < 0:
        y = ROWS - 1
    if y >= ROWS:
        y = 0
    Cell(x = x, y = y)

fn cell_add(a: Cell, b: Cell) -> Cell:
    Cell(x = a.x + b.x, y = a.y + b.y)
