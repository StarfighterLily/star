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

# A fieldless enum used to print as garbage hex (`0000000000000001`-style)
# when interpolated straight into an f-string -- neither `emit_print_like`
# nor the general f-string-as-value codegen path had a `Ty::Enum` arm in
# their format-specifier tables, so the bare `i32` discriminant fell through
# to the `%p` pointer catch-all (NOTES.md section 1.5; the same bug class
# `Color32`/aggregate-vector f-strings hit before those got fixed). Both call
# sites now have that arm, so `f"{d}"` prints the variant's real name
# (`Down`, `Right`, ...) directly -- see
# `runtime_println_fieldless_enum_prints_variant_name_end_to_end` /
# `runtime_fstring_value_with_fieldless_enum_prints_variant_name_end_to_end`
# in `tests/frontend.rs`. `dir_name`'s hand-written match is gone; callers
# just write `f"{d}"`.

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
