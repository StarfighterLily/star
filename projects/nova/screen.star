# Nova-16 video subsystem: 9 compositing layers (0=base, 1-4=backgrounds,
# 5-8=sprites), each a 256x256 8bpp-indexed buffer, selected by the `VL`
# register; a same-sized VRAM staging buffer; and the 8x8 1bpp font.
# docs/VRAM Specification.md, docs/nova16_instruction_reference.md's `LSWAP`/
# `LMOVE`/`LCOPY` entries, and `nova/graphics/{compositor,blitter}.py` (the
# actual behavior port -- read directly, not guessed from
# docs/SPRITE_SYSTEM.md/TODO.md, which describe an earlier/aspirational
# design that doesn't match what the running reference actually does).
#
# Layer storage: 9 separate `[u8; 65_536]` fields (`screen`, `bg1`-`bg4`,
# `sp1`-`sp4`), not a `[[u8; 65_536]; 9]` nested array. A nested fixed array
# was deliberately avoided -- this project's own "Four Star compiler bugs
# found and fixed" history (NOTES.md) is a long list of exactly this shape
# (a large fixed aggregate constructed/returned/passed as one value) hitting
# real, previously-undiscovered `clang` crashes/hangs, and a *nested* array
# repeat/struct-literal-field-of-arrays is a combination the existing fixes
# (`emit_array_repeat_into`/`emit_struct_lit_fields_into`) were never
# specifically exercised against. Nine flat named fields plus an explicit
# `vl`-to-field dispatch (`layer_get_idx`/`layer_set_idx_raw` below) gets the
# same observable behavior without depending on an untested codegen path.
#
# Compositing model: back-to-front "overwrite where nonzero" -- `composite_
# pixel(_idx)` recomputes the visible pixel on demand from all 9 layers
# every time it's needed (`Compositor._composite_opaque_layer`'s own rule),
# rather than caching a composited buffer the way the reference's
# `Compositor` does. The reference's dirty-flag/pixel-count-tracking cache
# is a pure performance optimization with no observable effect on any
# opcode's result (confirmed by reading `composite()`/`mark_dirty`/`_pixel_
# counts` -- every path that mutates a layer already marks it dirty, and the
# cache is always rebuilt in full before being read), so this port skips it
# entirely and always recomputes -- same "don't chase the reference's own
# performance hacks, only its observable behavior" precedent this file
# already used for the opcode-fetch cache (see memory.star's header) and the
# timer's once-per-instruction tick (see NOTES.md "Known simplifications").
# One concrete consequence: `VBLIT`'s reference implementation copies the
# composite into VRAM and then `_screen.fill(0)`s the *cache* -- but
# immediately follows that with `mark_all_dirty()`, so the very next read of
# the composite recomputes it from the (untouched) individual layers, making
# the `fill(0)` entirely unobservable. This port's `vblit` therefore doesn't
# clear anything -- see its own comment.
#
# Blend modes (`SBLEND` mode, `SALPHA` intensity): the reference now blends
# for real (`nova/graphics/blitter.py::blend_pixel`, wired into `SWRITE`,
# `draw_line`, `draw_rectangle`, `draw_circle`, `fill_layer` and the
# character writer). This file used to keep `SBLEND` as a stub on the
# grounds that the reference's blend code was dead -- true when written,
# no longer true, so that note is withdrawn. `blend_pixel` below is a
# formula-for-formula port, including Python's floor (not truncating)
# division in mode 0, and every primitive keeps the reference's exact write
# sequence -- a blended pixel's value depends on how many times it is
# written, and the reference writes some pixels more than once (an outline
# rectangle's corners; the filled circle's repeated scanlines), so the loops
# below deliberately repeat those writes too. Sprites, blits, layer ops and
# SINV never blend, matching the reference. Mode 0 with alpha 255 (the reset
# state) is a plain overwrite, the reference's own fast path.

import "font_data.star" as fontdata

const WIDTH: i32 = 256
const HEIGHT: i32 = 256
const LAYER_COUNT: i32 = 9

struct Screen:
    mut screen: [u8; 65_536]   # layer 0 (base)
    mut bg1: [u8; 65_536]      # layer 1
    mut bg2: [u8; 65_536]      # layer 2
    mut bg3: [u8; 65_536]      # layer 3
    mut bg4: [u8; 65_536]      # layer 4
    mut sp1: [u8; 65_536]      # layer 5
    mut sp2: [u8; 65_536]      # layer 6
    mut sp3: [u8; 65_536]      # layer 7
    mut sp4: [u8; 65_536]      # layer 8
    mut vram: [u8; 65_536]
    mut font: fontdata::FontData
    mut blend_mode: i32     # SBLEND: 0 normal, 1 add, 2 sub, 3 multiply, 4 screen
    mut blend_alpha: i32    # SALPHA: 0-255

# `new_screen()` returns `Screen` (10 x 64KB arrays plus the font) by value
# -- same fix as `memory.star`'s `new_memory()`, see its comment and
# NOTES.md.
fn new_screen() -> Screen:
    Screen(
        screen = [0 as u8; 65_536],
        bg1 = [0 as u8; 65_536],
        bg2 = [0 as u8; 65_536],
        bg3 = [0 as u8; 65_536],
        bg4 = [0 as u8; 65_536],
        sp1 = [0 as u8; 65_536],
        sp2 = [0 as u8; 65_536],
        sp3 = [0 as u8; 65_536],
        sp4 = [0 as u8; 65_536],
        vram = [0 as u8; 65_536],
        font = fontdata::new_font_data(),
        blend_mode = 0,
        blend_alpha = 255,
    )

fn in_bounds(x: i32, y: i32) -> bool:
    x >= 0 and x < WIDTH and y >= 0 and y < HEIGHT

fn pixel_index(x: i32, y: i32) -> i32:
    y * WIDTH + x

fn valid_layer(vl: i32) -> bool:
    vl >= 0 and vl < LAYER_COUNT

# Python's `//`: floor division (rounds toward negative infinity), where
# Star's `/` truncates toward zero. Only blend mode 0 divides a value that
# can be negative.
fn floor_div(a: i32, b: i32) -> i32:
    let q = a / b
    let r = a % b
    if r != 0 and (a < 0) != (b < 0):
        q - 1
    else:
        q

impl Screen:
    # ── Layer access (flat pixel index, 0-65535) ─────────────────────────
    # The single source of truth for "which field does layer N live in" --
    # every other layer-aware method in this file routes through these two
    # rather than re-deriving the vl-to-field mapping.

    fn layer_get_idx(self, vl: i32, idx: i32) -> u8:
        if vl == 0:
            self.screen[idx]
        elif vl == 1:
            self.bg1[idx]
        elif vl == 2:
            self.bg2[idx]
        elif vl == 3:
            self.bg3[idx]
        elif vl == 4:
            self.bg4[idx]
        elif vl == 5:
            self.sp1[idx]
        elif vl == 6:
            self.sp2[idx]
        elif vl == 7:
            self.sp3[idx]
        elif vl == 8:
            self.sp4[idx]
        else:
            0 as u8

    fn layer_set_idx(mut self, vl: i32, idx: i32, v: u8):
        if vl == 0:
            self.screen[idx] = v
        elif vl == 1:
            self.bg1[idx] = v
        elif vl == 2:
            self.bg2[idx] = v
        elif vl == 3:
            self.bg3[idx] = v
        elif vl == 4:
            self.bg4[idx] = v
        elif vl == 5:
            self.sp1[idx] = v
        elif vl == 6:
            self.sp2[idx] = v
        elif vl == 7:
            self.sp3[idx] = v
        elif vl == 8:
            self.sp4[idx] = v

    # ── Blending (`Blitter.blend_pixel`, formula for formula) ─────────────

    fn set_blend_mode(mut self, mode: i32):
        self.blend_mode = clamp_i32(mode, 0, 4)

    fn set_blend_alpha(mut self, alpha: i32):
        self.blend_alpha = clamp_i32(alpha, 0, 255)

    fn blend_enabled(self) -> bool:
        not (self.blend_mode == 0 and self.blend_alpha == 255)

    fn blend_pixel(self, existing: u8, new: u8) -> u8:
        let e = existing as i32
        let n = new as i32
        let a = self.blend_alpha
        let mut r = n
        if self.blend_mode == 0:
            if a < 255:
                r = clamp_i32(e + floor_div((n - e) * a + 127, 255), 0, 255)
        elif self.blend_mode == 1:
            r = min_i32(255, e + (n * a + 127) / 255)
        elif self.blend_mode == 2:
            r = max_i32(0, e - (n * a + 127) / 255)
        elif self.blend_mode == 3:
            r = min_i32(255, (e * n * a + 32_512) / 65_025)
        elif self.blend_mode == 4:
            r = clamp_i32(255 - ((255 - e) * (255 - n) * a + 32_512) / 65_025, 0, 255)
        r as u8

    # draw_set: the blend-aware pixel write every drawing primitive and
    # SWRITE use (`Blitter._set_pixel_to_layer` / the primitives' own
    # `blend_pixel(target[y, x], color) if blend else color`).
    fn draw_set(mut self, vl: i32, x: i32, y: i32, v: u8):
        if in_bounds(x, y):
            let idx = pixel_index(x, y)
            if self.blend_enabled():
                self.layer_set_idx(vl, idx, self.blend_pixel(self.layer_get_idx(vl, idx), v))
            else:
                self.layer_set_idx(vl, idx, v)

    # ── Layer access (x, y) ───────────────────────────────────────────────

    fn layer_get(self, vl: i32, x: i32, y: i32) -> u8:
        if in_bounds(x, y):
            self.layer_get_idx(vl, pixel_index(x, y))
        else:
            0 as u8

    fn layer_set(mut self, vl: i32, x: i32, y: i32, v: u8):
        if in_bounds(x, y):
            self.layer_set_idx(vl, pixel_index(x, y), v)

    # ── Compositing: back-to-front "overwrite where nonzero", recomputed
    # on demand -- see the file header for why there's no cached buffer.

    fn composite_pixel_idx(self, idx: i32) -> u8:
        let mut v = self.screen[idx]
        if self.bg1[idx] != (0 as u8):
            v = self.bg1[idx]
        if self.bg2[idx] != (0 as u8):
            v = self.bg2[idx]
        if self.bg3[idx] != (0 as u8):
            v = self.bg3[idx]
        if self.bg4[idx] != (0 as u8):
            v = self.bg4[idx]
        if self.sp1[idx] != (0 as u8):
            v = self.sp1[idx]
        if self.sp2[idx] != (0 as u8):
            v = self.sp2[idx]
        if self.sp3[idx] != (0 as u8):
            v = self.sp3[idx]
        if self.sp4[idx] != (0 as u8):
            v = self.sp4[idx]
        v

    fn composite_pixel(self, x: i32, y: i32) -> u8:
        if in_bounds(x, y):
            self.composite_pixel_idx(pixel_index(x, y))
        else:
            0 as u8

    fn get_vram(self, x: i32, y: i32) -> u8:
        if in_bounds(x, y):
            self.vram[pixel_index(x, y)]
        else:
            0 as u8

    fn set_vram(mut self, x: i32, y: i32, v: u8):
        if in_bounds(x, y):
            self.vram[pixel_index(x, y)] = v

    # SBLIT: VRAM -> layer `vl`, then clear VRAM (`Blitter.blit`).
    fn sblit(mut self, vl: i32):
        for i in 0..65_536:
            self.layer_set_idx(vl, i, self.vram[i])
        for i in 0..65_536:
            self.vram[i] = 0 as u8

    # VBLIT: the composited screen -> VRAM (`Blitter.blit_vram`). Does not
    # clear anything afterward -- see the file header; the reference's own
    # "clear then immediately mark all dirty" has no observable effect once
    # there's no cache to go stale.
    fn vblit(mut self):
        for i in 0..65_536:
            self.vram[i] = self.composite_pixel_idx(i)

    # SFILL: fill layer `vl` (`GFX.fill_layer` -- `target.fill(value)`, or
    # `blend_array(target, value)` once per pixel while blending is active).
    fn sfill(mut self, vl: i32, color: u8):
        if self.blend_enabled():
            for i in 0..65_536:
                self.layer_set_idx(vl, i, self.blend_pixel(self.layer_get_idx(vl, i), color))
        else:
            for i in 0..65_536:
                self.layer_set_idx(vl, i, color)

    # SINV: bulk raw invert of layer `vl` (`GFX.invert_colors` -- `255 -
    # target`).
    fn sinv(mut self, vl: i32):
        for i in 0..65_536:
            self.layer_set_idx(vl, i, ~self.layer_get_idx(vl, i))

    # LSWAP/LMOVE/LCOPY (`Compositor`/`GFX` layer-to-layer ops). An
    # out-of-range layer index is a silent no-op, matching this project's
    # established "memory/graphics ops always bounds-check, never trap"
    # philosophy (memory.star's header) rather than the reference's own
    # `raise ValueError` -- there's no exception mechanism to reproduce that
    # with here anyway.
    fn layer_swap(mut self, a: i32, b: i32):
        if valid_layer(a) and valid_layer(b) and a != b:
            for i in 0..65_536:
                let va = self.layer_get_idx(a, i)
                let vb = self.layer_get_idx(b, i)
                self.layer_set_idx(a, i, vb)
                self.layer_set_idx(b, i, va)

    fn layer_move(mut self, current: i32, target: i32):
        if valid_layer(current) and valid_layer(target) and current != target:
            for i in 0..65_536:
                self.layer_set_idx(target, i, self.layer_get_idx(current, i))
                self.layer_set_idx(current, i, 0 as u8)

    fn layer_copy(mut self, current: i32, target: i32):
        if valid_layer(current) and valid_layer(target) and current != target:
            for i in 0..65_536:
                self.layer_set_idx(target, i, self.layer_get_idx(current, i))

    fn sline(mut self, vl: i32, x0: i32, y0: i32, x1: i32, y1: i32, color: u8):
        let dx = abs_i32(x1 - x0)
        let dy = abs_i32(y1 - y0)
        let sx = if x0 < x1: 1 else: 0 - 1
        let sy = if y0 < y1: 1 else: 0 - 1
        let mut err = dx - dy
        let mut x = x0
        let mut y = y0
        let mut going = true
        while going:
            self.draw_set(vl, x, y, color)
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

    # SRECT (`GFX.draw_rectangle`): each corner is clamped on screen but the
    # pair is NOT reordered -- the reference fills `target[y1:y2+1, x1:x2+1]`
    # with numpy slices, which are simply empty for a reversed range. So a
    # reversed filled rectangle draws nothing, and a reversed outline keeps
    # only its two edge runs whose range is still ascending. The outline is
    # four runs in the reference's order (top row, bottom row, left column,
    # right column), so corners are written twice -- which matters while
    # blending, and is deliberate.
    fn srect(mut self, vl: i32, x0: i32, y0: i32, x1: i32, y1: i32, color: u8, filled: bool):
        let xa = clamp_i32(x0, 0, WIDTH - 1)
        let ya = clamp_i32(y0, 0, HEIGHT - 1)
        let xb = clamp_i32(x1, 0, WIDTH - 1)
        let yb = clamp_i32(y1, 0, HEIGHT - 1)
        if filled:
            let mut yy = ya
            while yy <= yb:
                let mut xx = xa
                while xx <= xb:
                    self.draw_set(vl, xx, yy, color)
                    xx += 1
                yy += 1
        else:
            let mut xx = xa
            while xx <= xb:
                self.draw_set(vl, xx, ya, color)
                xx += 1
            xx = xa
            while xx <= xb:
                self.draw_set(vl, xx, yb, color)
                xx += 1
            let mut yy = ya
            while yy <= yb:
                self.draw_set(vl, xa, yy, color)
                yy += 1
            yy = ya
            while yy <= yb:
                self.draw_set(vl, xb, yy, color)
                yy += 1

    fn scirc(mut self, vl: i32, cx: i32, cy: i32, radius: i32, color: u8, filled: bool):
        let mut x = radius
        let mut y = 0
        let mut err = 0
        if filled:
            while x >= y:
                let mut i = cx - x
                while i <= cx + x:
                    self.draw_set(vl, i, cy + y, color)
                    self.draw_set(vl, i, cy - y, color)
                    i += 1
                let mut j = cx - y
                while j <= cx + y:
                    self.draw_set(vl, j, cy + x, color)
                    self.draw_set(vl, j, cy - x, color)
                    j += 1
                y += 1
                err += 1 + 2 * y
                if 2 * (err - x) + 1 > 0:
                    x -= 1
                    err += 1 - 2 * x
        else:
            while x >= y:
                self.draw_set(vl, cx + x, cy + y, color)
                self.draw_set(vl, cx - x, cy + y, color)
                self.draw_set(vl, cx + x, cy - y, color)
                self.draw_set(vl, cx - x, cy - y, color)
                self.draw_set(vl, cx + y, cy + x, color)
                self.draw_set(vl, cx - y, cy + x, color)
                self.draw_set(vl, cx + y, cy - x, color)
                self.draw_set(vl, cx - y, cy - x, color)
                y += 1
                err += 1 + 2 * y
                if 2 * (err - x) + 1 > 0:
                    x -= 1
                    err += 1 - 2 * x

    # CHAR: draw one 8x8 glyph at (x, y) on layer `vl`, MSB-first bit order
    # (bit 7 = column 0).
    fn draw_char(mut self, vl: i32, code: u8, x: i32, y: i32, color: u8):
        let base = (code as i32) * 8
        for row in 0..8:
            let rowbyte = self.font.glyphs[base + row]
            for col in 0..8:
                if bit_get(rowbyte, 7 - col):
                    self.draw_set(vl, x + col, y + row, color)

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

    # Every transform below reads layer `vl` into a same-sized local temp
    # (via `layer_get_idx`, one element at a time -- never a bulk array
    # copy) then writes the transformed result back via `layer_set_idx`.
    # Whole-array-as-one-value shapes -- a plain assignment between two
    # existing arrays, or a fixed-size array as a function parameter/return
    # type -- all force the same "materialize a [65_536 x u8] as one SSA
    # value" codegen path that crashes/hangs `clang` for a struct-literal
    # field init (see `emit_array_repeat_into`'s doc comment / NOTES.md);
    # only the literal-initializer case was fixed at the compiler level, so
    # every one of those other shapes is avoided here by hand, in favor of
    # the per-element indexing every other read/write in this file already
    # uses.
    fn roll_x(mut self, vl: i32, amount: i32):
        let mut temp: [u8; 65_536] = [0 as u8; 65_536]
        for k in 0..65_536:
            temp[k] = self.layer_get_idx(vl, k)
        let m = ((amount % WIDTH) + WIDTH) % WIDTH
        let mut y = 0
        while y < HEIGHT:
            let mut x = 0
            while x < WIDTH:
                self.layer_set_idx(vl, pixel_index((x + m) % WIDTH, y), temp[pixel_index(x, y)])
                x += 1
            y += 1

    fn roll_y(mut self, vl: i32, amount: i32):
        let mut temp: [u8; 65_536] = [0 as u8; 65_536]
        for k in 0..65_536:
            temp[k] = self.layer_get_idx(vl, k)
        let m = ((amount % HEIGHT) + HEIGHT) % HEIGHT
        let mut y = 0
        while y < HEIGHT:
            let mut x = 0
            while x < WIDTH:
                self.layer_set_idx(vl, pixel_index(x, (y + m) % HEIGHT), temp[pixel_index(x, y)])
                x += 1
            y += 1

    fn shift_x(mut self, vl: i32, amount: i32):
        let mut temp: [u8; 65_536] = [0 as u8; 65_536]
        for k in 0..65_536:
            temp[k] = self.layer_get_idx(vl, k)
        self.sfill(vl, 0 as u8)
        let mut y = 0
        while y < HEIGHT:
            let mut x = 0
            while x < WIDTH:
                let nx = x + amount
                if nx >= 0 and nx < WIDTH:
                    self.layer_set_idx(vl, pixel_index(nx, y), temp[pixel_index(x, y)])
                x += 1
            y += 1

    fn shift_y(mut self, vl: i32, amount: i32):
        let mut temp: [u8; 65_536] = [0 as u8; 65_536]
        for k in 0..65_536:
            temp[k] = self.layer_get_idx(vl, k)
        self.sfill(vl, 0 as u8)
        let mut y = 0
        while y < HEIGHT:
            let mut x = 0
            while x < WIDTH:
                let ny = y + amount
                if ny >= 0 and ny < HEIGHT:
                    self.layer_set_idx(vl, pixel_index(x, ny), temp[pixel_index(x, y)])
                x += 1
            y += 1

    fn flip_x(mut self, vl: i32):
        let mut temp: [u8; 65_536] = [0 as u8; 65_536]
        for k in 0..65_536:
            temp[k] = self.layer_get_idx(vl, k)
        let mut y = 0
        while y < HEIGHT:
            let mut x = 0
            while x < WIDTH:
                self.layer_set_idx(vl, pixel_index(WIDTH - 1 - x, y), temp[pixel_index(x, y)])
                x += 1
            y += 1

    fn flip_y(mut self, vl: i32):
        let mut temp: [u8; 65_536] = [0 as u8; 65_536]
        for k in 0..65_536:
            temp[k] = self.layer_get_idx(vl, k)
        let mut y = 0
        while y < HEIGHT:
            let mut x = 0
            while x < WIDTH:
                self.layer_set_idx(vl, pixel_index(x, HEIGHT - 1 - y), temp[pixel_index(x, y)])
                x += 1
            y += 1

    # 90-degree rotations (times: number of quarter-turns, clockwise for
    # rotate_right / counter-clockwise for rotate_left). Square screen, so
    # every quarter-turn stays in bounds.
    fn rotate_right(mut self, vl: i32, times: i32):
        let mut n = ((times % 4) + 4) % 4
        while n > 0:
            let mut temp: [u8; 65_536] = [0 as u8; 65_536]
            for k in 0..65_536:
                temp[k] = self.layer_get_idx(vl, k)
            let mut y = 0
            while y < HEIGHT:
                let mut x = 0
                while x < WIDTH:
                    self.layer_set_idx(vl, pixel_index(HEIGHT - 1 - y, x), temp[pixel_index(x, y)])
                    x += 1
                y += 1
            n -= 1

    fn rotate_left(mut self, vl: i32, times: i32):
        let mut n = ((times % 4) + 4) % 4
        while n > 0:
            let mut temp: [u8; 65_536] = [0 as u8; 65_536]
            for k in 0..65_536:
                temp[k] = self.layer_get_idx(vl, k)
            let mut y = 0
            while y < HEIGHT:
                let mut x = 0
                while x < WIDTH:
                    self.layer_set_idx(vl, pixel_index(y, WIDTH - 1 - x), temp[pixel_index(x, y)])
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
    elif x > hi:
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
