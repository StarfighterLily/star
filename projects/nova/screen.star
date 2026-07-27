# Nova-16 video subsystem: a 256x256 8bpp-indexed screen (visible
# framebuffer) and a same-sized VRAM compose buffer, plus the 8x8 1bpp font.
# docs/VRAM Specification.md.
#
# Scope note (see NOTES.md "What's not implemented"): the real machine has 9
# compositing layers (0=base, 1-4=backgrounds, 5-8=sprites) selected by VL
# and blended together every frame. This port only implements layer 0's
# semantics (every draw op targets `screen`/`vram` directly, matching what
# the upstream reference's own `_set_pixel_fast` does when VL==0: write
# straight through to both the layer-0 buffer and the composited screen).
# Layers 1-8, sprites, and LSWAP/LMOVE/LCOPY are not yet ported.

import "font_data.star" as fontdata

const WIDTH: i32 = 256
const HEIGHT: i32 = 256

struct Screen:
    mut screen: [u8; 65536]
    mut vram: [u8; 65536]
    mut font: fontdata::FontData

# No `fn new_screen() -> Screen` constructor, for the same reason
# memory.star's Memory has none: returning a struct embedding two 64KB
# arrays by value hangs `clang` (confirmed -- see NOTES.md). Build
# `Screen(...)` directly inline inside cpu.star's top-level `let mut cpu =
# Cpu(...)`.

fn in_bounds(x: i32, y: i32) -> bool:
    x >= 0 and x < WIDTH and y >= 0 and y < HEIGHT

fn pixel_index(x: i32, y: i32) -> i32:
    y * WIDTH + x

impl Screen:
    fn get_screen(self, x: i32, y: i32) -> u8:
        if in_bounds(x, y):
            self.screen[pixel_index(x, y)]
        else:
            0 as u8

    fn set_screen(mut self, x: i32, y: i32, v: u8):
        if in_bounds(x, y):
            self.screen[pixel_index(x, y)] = v

    fn get_vram(self, x: i32, y: i32) -> u8:
        if in_bounds(x, y):
            self.vram[pixel_index(x, y)]
        else:
            0 as u8

    fn set_vram(mut self, x: i32, y: i32, v: u8):
        if in_bounds(x, y):
            self.vram[pixel_index(x, y)] = v

    # SBLIT: VRAM -> active layer (screen, in this port's layer-0-only scope).
    fn sblit(mut self):
        let mut i = 0
        while i < 65536:
            self.screen[i] = self.vram[i]
            i += 1

    # VBLIT: active layer -> VRAM.
    fn vblit(mut self):
        let mut i = 0
        while i < 65536:
            self.vram[i] = self.screen[i]
            i += 1

    fn sfill(mut self, color: u8):
        let mut i = 0
        while i < 65536:
            self.screen[i] = color
            i += 1

    fn sinv(mut self):
        let mut i = 0
        while i < 65536:
            self.screen[i] = bit_not(self.screen[i])
            i += 1

    fn sline(mut self, x0: i32, y0: i32, x1: i32, y1: i32, color: u8):
        let dx = abs_i32(x1 - x0)
        let dy = abs_i32(y1 - y0)
        let sx = if x0 < x1: 1 else: 0 - 1
        let sy = if y0 < y1: 1 else: 0 - 1
        let mut err = dx - dy
        let mut x = x0
        let mut y = y0
        let mut going = true
        while going:
            self.set_screen(x, y, color)
            if x == x1 and y == y1:
                going = false
            else:
                let e2 = 2 * err
                if e2 > (0 - dy):
                    err -= dy
                    x += sx
                if e2 < dx:
                    err += dx
                    y += sy

    fn srect(mut self, x0: i32, y0: i32, x1: i32, y1: i32, color: u8, filled: bool):
        let xa = clamp_i32(x0, 0, WIDTH - 1)
        let ya = clamp_i32(y0, 0, HEIGHT - 1)
        let xb = clamp_i32(x1, 0, WIDTH - 1)
        let yb = clamp_i32(y1, 0, HEIGHT - 1)
        let xlo = min_i32(xa, xb)
        let xhi = max_i32(xa, xb)
        let ylo = min_i32(ya, yb)
        let yhi = max_i32(ya, yb)
        if filled:
            let mut yy = ylo
            while yy <= yhi:
                let mut xx = xlo
                while xx <= xhi:
                    self.set_screen(xx, yy, color)
                    xx += 1
                yy += 1
        else:
            let mut xx = xlo
            while xx <= xhi:
                self.set_screen(xx, ylo, color)
                self.set_screen(xx, yhi, color)
                xx += 1
            let mut yy = ylo
            while yy <= yhi:
                self.set_screen(xlo, yy, color)
                self.set_screen(xhi, yy, color)
                yy += 1

    fn scirc(mut self, cx: i32, cy: i32, radius: i32, color: u8, filled: bool):
        let mut x = radius
        let mut y = 0
        let mut err = 0
        if filled:
            while x >= y:
                let mut i = cx - x
                while i <= cx + x:
                    self.set_screen(i, cy + y, color)
                    self.set_screen(i, cy - y, color)
                    i += 1
                let mut j = cx - y
                while j <= cx + y:
                    self.set_screen(j, cy + x, color)
                    self.set_screen(j, cy - x, color)
                    j += 1
                y += 1
                err += 1 + 2 * y
                if 2 * (err - x) + 1 > 0:
                    x -= 1
                    err += 1 - 2 * x
        else:
            while x >= y:
                self.set_screen(cx + x, cy + y, color)
                self.set_screen(cx - x, cy + y, color)
                self.set_screen(cx + x, cy - y, color)
                self.set_screen(cx - x, cy - y, color)
                self.set_screen(cx + y, cy + x, color)
                self.set_screen(cx - y, cy + x, color)
                self.set_screen(cx + y, cy - x, color)
                self.set_screen(cx - y, cy - x, color)
                y += 1
                err += 1 + 2 * y
                if 2 * (err - x) + 1 > 0:
                    x -= 1
                    err += 1 - 2 * x

    # CHAR: draw one 8x8 glyph at (x, y), MSB-first bit order (bit 7 = column 0).
    fn draw_char(mut self, code: u8, x: i32, y: i32, color: u8):
        let base = (code as i32) * 8
        let mut row = 0
        while row < 8:
            let rowbyte = self.font.glyphs[base + row]
            let mut col = 0
            while col < 8:
                if bit_get(rowbyte, 7 - col):
                    self.set_screen(x + col, y + row, color)
                col += 1
            row += 1

    # TEXT (the actual string-reading loop lives on `Cpu` instead, as
    # `Cpu::draw_text` -- see cpu.star. It needs to read bytes from `Memory`
    # one at a time while calling back into `draw_char` here; an ordinary,
    # non-`self` function parameter is passed *by value* in Star, and
    # `Memory` is a ~300KB struct -- taking one as a plain parameter (as
    # this method used to) forces exactly the same "materialize a huge
    # aggregate as one SSA value" crash/hang this whole port otherwise
    # routes around (confirmed: hung `clang` even at `-O0`, isolated via
    # `projects/nova/NOTES.md`'s bisection). `Cpu` already holds both `mem`
    # and `screen` as plain fields and reaches this method through `self`
    # (pointer-passed), so the fix is simply: do the memory-reading loop
    # where both are already reachable without crossing a by-value
    # parameter boundary.)

    # Every transform below snapshots `screen` into a same-sized local
    # (`let mut temp: [u8; 65536] = [0 as u8; 65536]` -- a fresh literal,
    # never `self.screen` copied via a value-returning helper or a bare
    # `self.screen = temp`/`return temp`) via an indexed copy loop, then
    # writes the transformed result back into `self.screen` one indexed
    # element at a time. Whole-array-as-one-value shapes -- a plain
    # assignment between two existing arrays, or a fixed-size array as a
    # function parameter/return type -- all force the same "materialize a
    # [65536 x u8] as one SSA value" codegen path that crashes/hangs `clang`
    # for a struct-literal field init (see `emit_array_repeat_into`'s doc
    # comment / NOTES.md); only the literal-initializer case was fixed at
    # the compiler level, so every one of those other shapes is avoided here
    # by hand, in favor of the per-element indexing every other read/write in
    # this file already uses.
    fn roll_x(mut self, amount: i32):
        let mut temp: [u8; 65536] = [0 as u8; 65536]
        let mut k = 0
        while k < 65536:
            temp[k] = self.screen[k]
            k += 1
        let m = ((amount % WIDTH) + WIDTH) % WIDTH
        let mut y = 0
        while y < HEIGHT:
            let mut x = 0
            while x < WIDTH:
                self.screen[pixel_index((x + m) % WIDTH, y)] = temp[pixel_index(x, y)]
                x += 1
            y += 1

    fn roll_y(mut self, amount: i32):
        let mut temp: [u8; 65536] = [0 as u8; 65536]
        let mut k = 0
        while k < 65536:
            temp[k] = self.screen[k]
            k += 1
        let m = ((amount % HEIGHT) + HEIGHT) % HEIGHT
        let mut y = 0
        while y < HEIGHT:
            let mut x = 0
            while x < WIDTH:
                self.screen[pixel_index(x, (y + m) % HEIGHT)] = temp[pixel_index(x, y)]
                x += 1
            y += 1

    fn shift_x(mut self, amount: i32):
        let mut temp: [u8; 65536] = [0 as u8; 65536]
        let mut k = 0
        while k < 65536:
            temp[k] = self.screen[k]
            k += 1
        self.sfill(0 as u8)
        let mut y = 0
        while y < HEIGHT:
            let mut x = 0
            while x < WIDTH:
                let nx = x + amount
                if nx >= 0 and nx < WIDTH:
                    self.screen[pixel_index(nx, y)] = temp[pixel_index(x, y)]
                x += 1
            y += 1

    fn shift_y(mut self, amount: i32):
        let mut temp: [u8; 65536] = [0 as u8; 65536]
        let mut k = 0
        while k < 65536:
            temp[k] = self.screen[k]
            k += 1
        self.sfill(0 as u8)
        let mut y = 0
        while y < HEIGHT:
            let mut x = 0
            while x < WIDTH:
                let ny = y + amount
                if ny >= 0 and ny < HEIGHT:
                    self.screen[pixel_index(x, ny)] = temp[pixel_index(x, y)]
                x += 1
            y += 1

    fn flip_x(mut self):
        let mut temp: [u8; 65536] = [0 as u8; 65536]
        let mut k = 0
        while k < 65536:
            temp[k] = self.screen[k]
            k += 1
        let mut y = 0
        while y < HEIGHT:
            let mut x = 0
            while x < WIDTH:
                self.screen[pixel_index(WIDTH - 1 - x, y)] = temp[pixel_index(x, y)]
                x += 1
            y += 1

    fn flip_y(mut self):
        let mut temp: [u8; 65536] = [0 as u8; 65536]
        let mut k = 0
        while k < 65536:
            temp[k] = self.screen[k]
            k += 1
        let mut y = 0
        while y < HEIGHT:
            let mut x = 0
            while x < WIDTH:
                self.screen[pixel_index(x, HEIGHT - 1 - y)] = temp[pixel_index(x, y)]
                x += 1
            y += 1

    # 90-degree rotations (times: number of quarter-turns, clockwise for
    # rotate_right / counter-clockwise for rotate_left). Square screen, so
    # every quarter-turn stays in bounds.
    fn rotate_right(mut self, times: i32):
        let mut n = ((times % 4) + 4) % 4
        while n > 0:
            let mut temp: [u8; 65536] = [0 as u8; 65536]
            let mut k = 0
            while k < 65536:
                temp[k] = self.screen[k]
                k += 1
            let mut y = 0
            while y < HEIGHT:
                let mut x = 0
                while x < WIDTH:
                    self.screen[pixel_index(HEIGHT - 1 - y, x)] = temp[pixel_index(x, y)]
                    x += 1
                y += 1
            n -= 1

    fn rotate_left(mut self, times: i32):
        let mut n = ((times % 4) + 4) % 4
        while n > 0:
            let mut temp: [u8; 65536] = [0 as u8; 65536]
            let mut k = 0
            while k < 65536:
                temp[k] = self.screen[k]
                k += 1
            let mut y = 0
            while y < HEIGHT:
                let mut x = 0
                while x < WIDTH:
                    self.screen[pixel_index(y, WIDTH - 1 - x)] = temp[pixel_index(x, y)]
                    x += 1
                y += 1
            n -= 1

fn abs_i32(x: i32) -> i32:
    if x < 0:
        0 - x
    else:
        x

fn clamp_i32(x: i32, lo: i32, hi: i32) -> i32:
    if x < lo:
        lo
    else:
        if x > hi:
            hi
        else:
            x

fn min_i32(a: i32, b: i32) -> i32:
    if a < b:
        a
    else:
        b

fn max_i32(a: i32, b: i32) -> i32:
    if a > b:
        a
    else:
        b
