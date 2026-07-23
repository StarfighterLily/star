# `const NAME: Type = <expr>` -- a top-level, compile-time-evaluated
# constant (`projects/snake/NOTES.md` 2.5: previously the only way to share
# a named value across a module was a zero-argument function, since only
# `struct`/`trait`/`impl`/`fn`/`arena`/`sequence`/`enum`/`import` were legal
# top-level items). The type annotation is required -- there's no call site
# to infer it from, unlike `let`. `<expr>` may be a literal, a unary/binary
# operator over other constant expressions, a numeric cast, or a reference
# to another `const` (in any declaration order, including forward
# references -- see `GRID_CELLS` referencing `COLS`/`ROWS` below, both
# declared afterward).
const GRID_CELLS: i32 = COLS * ROWS
const COLS: i32 = 32
const ROWS: i32 = 24
const CELL_SIZE: i32 = 20
const TITLE: str = "top_level_const demo"
const GRAVITY: f32 = 9.8
const HALF_GRAVITY: f32 = GRAVITY / 2.0
const COLS_AS_FLOAT: f32 = COLS as f32
const IS_SQUARE: bool = COLS == ROWS

fn board_width() -> i32:
    COLS * CELL_SIZE

fn main():
    println(f"{TITLE}: {COLS}x{ROWS} grid, {GRID_CELLS} cells, board is {board_width()}px wide")
    println(f"half gravity = {HALF_GRAVITY}, cols as float = {COLS_AS_FLOAT}, square = {IS_SQUARE}")
