# Nova-16 CPU: graphics and sprite opcode handlers (SBLEND/SREAD/SWRITE/
# VREAD/VWRITE/SLINE/SRECT/SCIRC/SINV/SBLIT/VBLIT/SFILL/SROL/SROT/SSHFT/
# SFLIP/CHAR/LSWAP/LMOVE/LCOPY/SPBLIT/SPBLITALL/TEXT,
# docs/nova16_instruction_reference.md / docs/SPRITE_SYSTEM.md) -- split out
# of `cpu.star` (todo.md P2 #5). See `cpu_data.star`'s header comment for the
# full rationale (pure code motion, no behavior change) and why this
# `import "cpu.star" as cpu` isn't circular.
#
# `vxy`/`draw_text` move here too, even though they aren't themselves
# `op_*` opcode handlers: both are pure graphics-coordinate helpers used
# *only* by opcodes in this same file (`vxy` by SREAD/SWRITE/VREAD/VWRITE/
# SLINE/SRECT/SCIRC/CHAR/TEXT; `draw_text` only by TEXT) -- grouping them
# with their one real call site reads more naturally than leaving them
# behind in `cpu.star`'s core section for no caller there to ever reach.
# `blit_sprite` (SPBLIT/SPBLITALL's shared per-sprite-ID blit) stays right
# next to both of its own callers for the same reason.
#
# `cpu::SCB_START`/`cpu::SCB_BLOCK_SIZE`/`cpu::SCB_COUNT` are `cpu.star`'s
# own module-level sprite-control-block layout constants -- qualified here
# exactly like `cpu_math.star`'s `cpu::PI`/`cpu::MATH_OVERFLOW_GUARD` (a
# bare top-level `const` from another file needs its `alias::` prefix, since
# only `impl` blocks skip name-mangling).
import "cpu.star" as cpu
import "screen.star" as screen

impl cpu::Cpu:
    # (x, y) the graphics opcodes should draw at/read from, given VM's
    # coordinate (0) vs linear (1) addressing mode (docs/VRAM Specification.md).
    fn vxy(self) -> (i32, i32):
        if self.vm == (0 as u8):
            (((self.vx as u8) as i32), ((self.vy as u8) as i32))
        else:
            let addr = ((((self.vx as u8) as u16 << 8)) | (self.vy as u8) as u16) as i32
            (addr % 256, addr / 256)

    # TEXT: reads a null-terminated string starting at `addr` and draws it
    # via `self.screen.draw_char`, returning the cursor (x, y) after the
    # last character. Lives here rather than on `Screen` because it needs
    # `self.mem` too, and an ordinary (non-`self`) function parameter is
    # passed *by value* in Star -- taking `Memory` (a ~300KB struct) as a
    # plain parameter reproduces the exact aggregate-value crash/hang this
    # port otherwise avoids (confirmed; see NOTES.md).
    fn draw_text(mut self, addr: i32, x: i32, y: i32, color: u8) -> (i32, i32):
        let mut cx = x
        let mut cy = y
        let mut a = addr
        let mut going = true
        while going:
            let code = self.mem.read_byte(a)
            if code == (0 as u8):
                going = false
            elif code == (9 as u8):
                cx += 32
            elif code == (10 as u8):
                cx = 0
                cy += 8
            elif code == (13 as u8):
                cx = 0
            else:
                self.screen.draw_char(self.vl as i32, code, cx, cy, color)
                cx += 8
                if cx + 8 > 256:
                    cx = 0
                    cy += 8
            a += 1
        (cx, cy)

    # ── Graphics ─────────────────────────────────────────────────────────

    # SBLEND: recognized and its operand consumed, matching the reference
    # exactly -- confirmed by reading `nova/graphics/blitter.py` directly
    # that `blend_pixel`/`_set_pixel_to_layer` (the only blend-aware pixel
    # write) is dead code there too (never called from `SWRITE`'s real path
    # or any drawing primitive), so a real stub is a bug-for-bug match, not
    # a simplification. See screen.star's header comment.
    fn op_sblend(mut self):
        let ops = self.decode_operands(1)
        self.halted = self.halted

    # SREAD reads the *composited* screen (matching `GFX.get_screen_val` ->
    # `self.screen` -> the compositor's own composited property) --
    # deliberately not layer-`VL`-aware, unlike every other graphics opcode
    # below.
    fn op_sread(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let (x, y) = self.vxy()
        let v = self.screen.composite_pixel(x, y)
        self.operand_write(op1, 8, v as i32)

    # SWRITE writes layer `VL` (`GFX.set_screen_val` -> `_set_pixel_fast`,
    # which is VL-aware).
    fn op_swrite(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let v = self.operand_read(op1, 8)
        let (x, y) = self.vxy()
        self.screen.layer_set(self.vl as i32, x, y, v as u8)

    fn op_vread(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let (x, y) = self.vxy()
        let v = self.screen.get_vram(x, y)
        self.operand_write(op1, 8, v as i32)

    fn op_vwrite(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let v = self.operand_read(op1, 8)
        let (x, y) = self.vxy()
        self.screen.set_vram(x, y, v as u8)

    fn op_sline(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let x1 = self.operand_read(op1, 8)
        let y1 = self.operand_read(op2, 8)
        let (x0, y0) = self.vxy()
        self.screen.sline(self.vl as i32, x0, y0, x1, y1, (self.vc as u8))

    fn op_srect(mut self):
        let (op1, op2, op3) = self.decode_operands(3)
        let x1 = self.operand_read(op1, 8)
        let y1 = self.operand_read(op2, 8)
        let filled = (self.operand_read(op3, 8)) != 0
        let (x0, y0) = self.vxy()
        self.screen.srect(self.vl as i32, x0, y0, x1, y1, (self.vc as u8), filled)

    fn op_scirc(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let radius = self.operand_read(op1, 8)
        let filled = (self.operand_read(op2, 8)) != 0
        let (cx, cy) = self.vxy()
        self.screen.scirc(self.vl as i32, cx, cy, radius, (self.vc as u8), filled)

    fn op_sinv(mut self):
        self.screen.sinv(self.vl as i32)

    fn op_sblit(mut self):
        self.screen.sblit(self.vl as i32)

    fn op_vblit(mut self):
        self.screen.vblit()

    fn op_sfill(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let v = self.operand_read(op1, 8)
        self.screen.sfill(self.vl as i32, v as u8)

    fn op_srol(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let axis = self.operand_read(op1, 8)
        let amount = self.operand_read(op2, 8)
        if axis == 0:
            self.screen.roll_x(self.vl as i32, 0 - amount)
        else:
            self.screen.roll_y(self.vl as i32, 0 - amount)

    fn op_srot(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let direction = self.operand_read(op1, 8)
        let amount = self.operand_read(op2, 8)
        if direction == 0:
            self.screen.rotate_left(self.vl as i32, amount)
        else:
            self.screen.rotate_right(self.vl as i32, amount)

    fn op_sshft(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let axis = self.operand_read(op1, 8)
        let amount = self.operand_read(op2, 8)
        if axis == 0:
            self.screen.shift_x(self.vl as i32, amount)
        else:
            self.screen.shift_y(self.vl as i32, amount)

    fn op_sflip(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let axis = self.operand_read(op1, 8)
        if axis == 0:
            self.screen.flip_x(self.vl as i32)
        else:
            self.screen.flip_y(self.vl as i32)

    fn op_char(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let code = self.operand_read(op1, 8)
        let (x, y) = self.vxy()
        self.screen.draw_char(self.vl as i32, code as u8, x, y, (self.vc as u8))
        self.vx = Wrapping<u8>(((x + 8) % 256) as u8)

    # LSWAP/LMOVE/LCOPY (docs/nova16_instruction_reference.md 0xB0-0xB2):
    # swap/move/copy the current layer (`VL`) with/to a target layer given
    # by the operand.
    fn op_lswap(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let target = self.operand_read(op1, 8)
        self.screen.layer_swap(self.vl as i32, target)

    fn op_lmove(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let target = self.operand_read(op1, 8)
        self.screen.layer_move(self.vl as i32, target)

    fn op_lcopy(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let target = self.operand_read(op1, 8)
        self.screen.layer_copy(self.vl as i32, target)

    # ── Sprites (docs/SPRITE_SYSTEM.md's memory layout section is accurate;
    # its "Instructions"/opcode-numbering section is stale -- cross-checked
    # against `nova/graphics/sprites.py::SpriteEngine` directly instead, see
    # NOTES.md). 16 memory-mapped sprite control blocks (SCBs), 16 bytes
    # each, at 0xF000-0xF0FF:
    #   +0..1  data address (big-endian u16)
    #   +2     x (u8)          +3  y (u8)
    #   +4     width (u8)      +5  height (u8)
    #   +6     flags: bit0 active, bit1 transparency-enabled,
    #          bit7 target layer (0 -> layer 5, 1 -> layer 6)
    #   +7     transparency color (u8)
    # Sprite pixel data is `width * height` bytes at `data_addr`, row-major
    # (row `sy` starts at `data_addr + sy * width`). Lives on `Cpu` (not
    # `Screen`) because it needs `self.mem` too -- same by-value-parameter
    # reasoning as `draw_text` above.
    fn blit_sprite(mut self, sprite_id: i32):
        if sprite_id < 0 or sprite_id >= cpu::SCB_COUNT:
            return
        let base = cpu::SCB_START + sprite_id * cpu::SCB_BLOCK_SIZE
        let data_addr = ((self.mem.read_byte(base) as i32) << 8) | (self.mem.read_byte(base + 1) as i32)
        let x = self.mem.read_byte(base + 2) as i32
        let y = self.mem.read_byte(base + 3) as i32
        let width = self.mem.read_byte(base + 4) as i32
        let height = self.mem.read_byte(base + 5) as i32
        let flags = self.mem.read_byte(base + 6)
        let transparency_color = self.mem.read_byte(base + 7)

        let active = bit_get(flags, 0)
        let transparency_enabled = bit_get(flags, 1)
        let target_layer = if bit_get(flags, 7): 6 else: 5

        if !active or width == 0 or height == 0:
            return
        let sprite_size = width * height
        if data_addr + sprite_size > 65_536:
            return
        if x >= 256 or y >= 256 or x + width <= 0 or y + height <= 0:
            return

        let src_x_start = screen::max_i32(0, 0 - x)
        let src_y_start = screen::max_i32(0, 0 - y)
        let src_x_end = screen::min_i32(width, 256 - x)
        let src_y_end = screen::min_i32(height, 256 - y)

        let mut sy = src_y_start
        while sy < src_y_end:
            let mut sx = src_x_start
            while sx < src_x_end:
                let pixel = self.mem.read_byte(data_addr + sy * width + sx)
                if !transparency_enabled or pixel != transparency_color:
                    self.screen.layer_set(target_layer, x + sx, y + sy, pixel)
                sx += 1
            sy += 1

    # SPBLIT: blit one sprite by ID.
    fn op_spblit(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let sprite_id = self.operand_read(op1, 8)
        self.blit_sprite(sprite_id)

    # SPBLITALL: clear all 4 sprite layers, then blit every sprite 0-15 in
    # order (matches `SpriteEngine.blit_all_sprites`'s own "clear sprite
    # layers first" -- even though a single sprite can only ever target
    # layer 5 or 6, this clears 5-8 to match the reference exactly).
    fn op_spblitall(mut self):
        self.screen.sfill(5, 0 as u8)
        self.screen.sfill(6, 0 as u8)
        self.screen.sfill(7, 0 as u8)
        self.screen.sfill(8, 0 as u8)
        let mut i = 0
        while i < cpu::SCB_COUNT:
            self.blit_sprite(i)
            i += 1

    fn op_text(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let addr = self.operand_read(op1, 16)
        let (x, y) = self.vxy()
        let result = self.draw_text(addr, x, y, (self.vc as u8))
        self.vx = Wrapping<u8>((result.0 % 256) as u8)
        self.vy = Wrapping<u8>((result.1 % 256) as u8)

