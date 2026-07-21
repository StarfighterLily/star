# The snake itself: a `Ring<Cell, N>` used as an explicit deque rather than
# relying on its auto-eviction. `Ring<T,N>` normally evicts the oldest
# (front) element the moment `push` goes past capacity N -- fine for a
# fixed-length sliding window, but the snake's length changes over the
# game's lifetime, so `advance()` below manages growth itself: `push` a new
# head every tick, and only `pop` the old tail when the snake did *not* eat
# this tick. N is set to every cell on the board (`cols() * rows()`), the
# worst case where the snake fills the entire grid, so the ring's own
# capacity-eviction path is never actually exercised in normal play.

import "grid.star" as grid

struct Snake:
    mut body: Ring<grid::Cell, 768>
    mut dir: grid::Direction
    mut pending_dir: grid::Direction
    mut grow_pending: i32
    mut alive: bool

impl Snake:
    fn head(self) -> grid::Cell:
        self.body[self.body.len() - 1]

    fn length(self) -> i32:
        self.body.len()

    # O(n) self-overlap test -- exactly the linear-scan shape `Map`/`Set`
    # already document as a known scaling gap, just spelled out by hand here
    # since `grid::Cell` participation as a `Set<Cell>` element is exercised
    # separately over in food.star.
    fn contains(self, c: grid::Cell) -> bool:
        let mut i = 0
        let mut found = false
        while i < self.body.len():
            if grid::cell_eq(self.body[i], c):
                found = true
            i += 1
        found

    # Queue a turn, ignoring a reversal directly onto the segment behind the
    # head (compared via the resulting movement delta, since `Direction`
    # itself isn't `==`-comparable -- see grid.star's `cell_eq` comment).
    fn queue_turn(mut self, d: grid::Direction):
        let next = grid::delta(d)
        let cur = grid::delta(self.dir)
        let is_reversal = next.x == 0 - cur.x and next.y == 0 - cur.y
        if !is_reversal:
            self.pending_dir = d

    fn grow(mut self, amount: i32):
        self.grow_pending += amount

    # Advances one tick: commits the queued turn, computes the new head,
    # and returns (new_head, ate_self). The caller is responsible for
    # checking the new head against the food cell (food.star doesn't know
    # about Snake, and Snake doesn't know about food -- kept decoupled).
    fn advance(mut self) -> grid::Cell:
        self.dir = self.pending_dir
        let new_head = grid::wrap(grid::cell_add(self.head(), grid::delta(self.dir)))
        if self.contains(new_head):
            self.alive = false
        self.body.push(new_head)
        if self.grow_pending > 0:
            self.grow_pending -= 1
        else:
            self.body.pop()
        new_head

# A fresh 3-segment snake in its starting position/direction. Lives here
# (rather than in main.star) so callers reached through a deep import chain
# (see food.star's/main.star's own comments on the module-diamond
# workaround) never need to spell out this file's `grid::Cell`/`Direction`
# construction directly -- they just call `sb::make_snake()` and let
# inference carry the fully-qualified type through.
fn make_snake() -> Snake:
    let mut s = Snake(
        body = Ring<grid::Cell, 768>(),
        dir = grid::Direction::Right,
        pending_dir = grid::Direction::Right,
        grow_pending = 2,
        alive = true,
    )
    s.body.push(grid::Cell(x = 5, y = 12))
    s.body.push(grid::Cell(x = 6, y = 12))
    s.body.push(grid::Cell(x = 7, y = 12))
    s
