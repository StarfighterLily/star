# Heresy -- level data, grid geometry, and level parsing.
#
# Why this module exists (beyond natural separation): the level is authored
# as ASCII art in a top-level `const` multiline string, not as a data table
# literal. A fixed-array/comma-literal (`[e1, e2, e3]`) collides with
# `List<T>`'s bracket syntax, and a `const` initializer may only be a
# literal/operator/cast/reference -- both classic Star constraints this
# dogfood deliberately leans on. A multiline string literal *is* const-valid,
# and parsing it at startup exercises `bytes_from_str` indexing, `str_split`,
# and `List<i32>` as a cheap-to-copy grid handle all at once. It also keeps
# the level visible and editable as 90s-style character-map text, which is
# exactly the aesthetic this project is about.
#
# Grid legend:
#   '#'  wall kind 1 (gray stone)
#   'B'  wall kind 2 (brick)
#   'G'  wall kind 3 (slime-green stone)
#   'P'  player start (empty cell; records its index + facing)
#   'E'  imp spawn (empty cell)
#   'X'  brute spawn (empty cell)
#   'h'  health-vial spawn (empty cell)
#   'm'  mana-orb spawn (empty cell)
#   '.' / ' '  empty

const MAP_W: i32 = 16
const MAP_H: i32 = 16

const MAP_ART: str = """BBBBBBBBBBBBBBBB
B..............B
B....m......h.B
B.P..........B
B......G..E..B
B..E...G......B
B......GGGG..B
B..............B
B..B..B..B..B.B
B..B..B..B..B.B
B..............B
B..h....m.....B
B......BBBB...B
B..E.....B..X.B
B..........h..B
BBBBBBBBBBBBBBBB"""

struct Level:
    map: List<i32>
    imps: List<i32>
    brutes: List<i32>
    healths: List<i32>
    manas: List<i32>
    player_idx: i32
    player_angle: f32

# The parsed grid; each entry is 0 (empty) or a wall-kind 1..3.
fn parse_level() -> Level:
    let rows = str_split(MAP_ART, "\n")
    let mut grid: List<i32> = List<i32>()
    let mut imps: List<i32> = List<i32>()
    let mut brutes: List<i32> = List<i32>()
    let mut healths: List<i32> = List<i32>()
    let mut manas: List<i32> = List<i32>()
    let mut player_idx = 0
    let mut y = 0
    while y < MAP_H:
        let row = rows[y]
        let row_bytes = bytes_from_str(row)
        let mut x = 0
        while x < MAP_W:
            let ch = (row_bytes[x] as i32)
            let idx = y * MAP_W + x
            if ch == 35:
                grid.push(1)
            elif ch == 66:
                grid.push(2)
            elif ch == 71:
                grid.push(3)
            else:
                grid.push(0)
                if ch == 80:
                    player_idx = idx
                elif ch == 69:
                    imps.push(idx)
                elif ch == 88:
                    brutes.push(idx)
                elif ch == 104:
                    healths.push(idx)
                elif ch == 109:
                    manas.push(idx)
            x += 1
        y += 1
    return Level(
        map = grid,
        imps = imps,
        brutes = brutes,
        healths = healths,
        manas = manas,
        player_idx = player_idx,
        player_angle = 0.0,
    )

# Wall kind at integer cell coordinates. Out of bounds is a wall (kind 1)
# so the raycaster never walks off the edge of the grid.
fn cell_at(map: List<i32>, cx: i32, cy: i32) -> i32:
    if cx < 0 or cy < 0 or cx >= MAP_W or cy >= MAP_H:
        return 1
    return map[cy * MAP_W + cx]

# World-space center of a cell given its grid index.
fn cell_center_x(idx: i32) -> f32:
    return ((idx % MAP_W) + 0.5) as f32

fn cell_center_y(idx: i32) -> f32:
    return ((idx / MAP_W) + 0.5) as f32

# Base palette (R, G, B) for a wall kind, before distance/fog shading.
fn wall_base(kind: i32) -> (i32, i32, i32):
    if kind == 2:
        return (150, 70, 50)
    if kind == 3:
        return (70, 115, 65)
    return (120, 112, 104)