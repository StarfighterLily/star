# Nova-16 CPU core: registers, flags, the unified register-code address
# space (docs/CPU Specification.md / docs/nova16_instruction_reference.md),
# operand decoding, and the fetch-decode-execute cycle. This is the one file
# every mutating operation on the machine's state lives in: `impl` blocks
# can't reach across a module boundary to extend a struct declared
# elsewhere (`impl cpu::Cpu:` from another file is a parse error -- confirmed
# empirically, see NOTES.md "Language gotchas"), so `Cpu`'s struct and all
# of its methods have to live together in one file. `Memory`/`Screen`/
# `Keyboard`/`StatusFlags` stay in their own files and are reached as plain
# fields (composition, not inheritance) -- calling a method on
# `self.mem`/`self.screen`/`self.kbd`/`self.flags` works fine across the
# module boundary; only *defining new methods* on an imported type doesn't.
#
# Register storage widths: every register that participates in arithmetic
# is `Wrapping<u8>`/`Wrapping<u16>`, not a plain `u8`/`u16` -- explicit-width
# integer types trap (process abort) on overflow in Star, which is exactly
# backwards for CPU registers, where wraparound on overflow is the entire
# point of the Carry/Overflow flags. `Wrapping<T>` is the opt-in for silent
# wraparound arithmetic at a fixed width (see NOTES.md / examples/wrapping.star).
#
# Every register (R0-R9, P0-P9, SP/FP, VX/VY/VM/VC, BANK, timer/sound/mouse/
# RTC regs, and P0:-P9:/:P0-:P9 byte-halves) is reachable through the same
# flat 8-bit register-code space (0x00-0xFF) the operand decoder uses --
# `get_reg_value`/`set_reg_value` below are that space's single source of
# truth, built to mirror `core/regfile.py::_build_register_code_map` exactly
# (register codes are spelled as decimal, not hex: Star's lexer has no `0x`
# literal syntax at all -- see NOTES.md).

import "memory.star" as mem
import "screen.star" as screen
import "keyboard.star" as keyboard
import "flags.star" as flg
import "bits.star" as bits

struct Operand:
    mut kind: u8       # 0 = register, 1 = immediate, 2 = memory
    mut reg_code: u8
    mut imm: u16
    mut addr: u16

fn zero_operand() -> Operand:
    Operand(kind = 0 as u8, reg_code = 0 as u8, imm = 0 as u16, addr = 0 as u16)

fn wrap_addr(a: i32) -> i32:
    ((a % 65536) + 65536) % 65536

# Interrupt vector table: 8 vectors x 4 bytes at 0x0100-0x011F.
const IVT_BASE: i32 = 256

struct Cpu:
    mut mem: mem::Memory
    mut screen: screen::Screen
    mut kbd: keyboard::Keyboard
    mut flags: flg::StatusFlags

    mut r: [Wrapping<u8>; 10]
    mut p: [Wrapping<u16>; 10]
    mut pc: Wrapping<u16>

    mut vx: Wrapping<u8>
    mut vy: Wrapping<u8>
    mut vc: Wrapping<u8>
    mut vm: u8
    mut vl: u8

    mut tt: Wrapping<u8>
    mut tm: Wrapping<u8>
    mut tc: Wrapping<u8>
    mut ts: Wrapping<u8>
    mut timer_subcycle: i32
    mut pending_timer_irq: bool

    mut sa: Wrapping<u16>
    mut sf: Wrapping<u8>
    mut sv: Wrapping<u8>
    mut sw: Wrapping<u8>

    mut mx: Wrapping<u8>
    mut my: Wrapping<u8>
    mut mb: Wrapping<u8>
    mut c0: Wrapping<u16>
    mut c1: Wrapping<u16>

    mut halted: bool
    mut cycles: i64

impl Cpu:
    # ── Register-code address space ────────────────────────────────────

    fn get_reg_value(self, code: u8) -> i32:
        match code as i32:
            194 ->
                self.mem.bank as i32
            195 ->
                (self.c0 as u16) as i32
            196 ->
                (self.c1 as u16) as i32
            197 ->
                (self.mx as u8) as i32
            198 ->
                (self.my as u8) as i32
            199 ->
                (self.mb as u8) as i32
            200 ->
                (self.vc as u8) as i32
            201 ->
                let cur = self.p[0] as u16
                (bits::shr16(cur, 8)) as i32
            202 ->
                let cur = self.p[1] as u16
                (bits::shr16(cur, 8)) as i32
            203 ->
                let cur = self.p[2] as u16
                (bits::shr16(cur, 8)) as i32
            204 ->
                let cur = self.p[3] as u16
                (bits::shr16(cur, 8)) as i32
            205 ->
                let cur = self.p[4] as u16
                (bits::shr16(cur, 8)) as i32
            206 ->
                let cur = self.p[5] as u16
                (bits::shr16(cur, 8)) as i32
            207 ->
                let cur = self.p[6] as u16
                (bits::shr16(cur, 8)) as i32
            208 ->
                let cur = self.p[7] as u16
                (bits::shr16(cur, 8)) as i32
            209 ->
                let cur = self.p[8] as u16
                (bits::shr16(cur, 8)) as i32
            210 ->
                let cur = self.p[9] as u16
                (bits::shr16(cur, 8)) as i32
            211 ->
                let cur = self.p[0] as u16
                (cur as u8) as i32
            212 ->
                let cur = self.p[1] as u16
                (cur as u8) as i32
            213 ->
                let cur = self.p[2] as u16
                (cur as u8) as i32
            214 ->
                let cur = self.p[3] as u16
                (cur as u8) as i32
            215 ->
                let cur = self.p[4] as u16
                (cur as u8) as i32
            216 ->
                let cur = self.p[5] as u16
                (cur as u8) as i32
            217 ->
                let cur = self.p[6] as u16
                (cur as u8) as i32
            218 ->
                let cur = self.p[7] as u16
                (cur as u8) as i32
            219 ->
                let cur = self.p[8] as u16
                (cur as u8) as i32
            220 ->
                let cur = self.p[9] as u16
                (cur as u8) as i32
            221 ->
                (self.sa as u16) as i32
            222 ->
                (self.sf as u8) as i32
            223 ->
                (self.sv as u8) as i32
            224 ->
                (self.sw as u8) as i32
            225 ->
                self.vm as i32
            226 ->
                self.vl as i32
            227 ->
                (self.tt as u8) as i32
            228 ->
                (self.tm as u8) as i32
            229 ->
                (self.tc as u8) as i32
            230 ->
                (self.ts as u8) as i32
            231 ->
                (self.r[0] as u8) as i32
            232 ->
                (self.r[1] as u8) as i32
            233 ->
                (self.r[2] as u8) as i32
            234 ->
                (self.r[3] as u8) as i32
            235 ->
                (self.r[4] as u8) as i32
            236 ->
                (self.r[5] as u8) as i32
            237 ->
                (self.r[6] as u8) as i32
            238 ->
                (self.r[7] as u8) as i32
            239 ->
                (self.r[8] as u8) as i32
            240 ->
                (self.r[9] as u8) as i32
            241 ->
                (self.p[0] as u16) as i32
            242 ->
                (self.p[1] as u16) as i32
            243 ->
                (self.p[2] as u16) as i32
            244 ->
                (self.p[3] as u16) as i32
            245 ->
                (self.p[4] as u16) as i32
            246 ->
                (self.p[5] as u16) as i32
            247 ->
                (self.p[6] as u16) as i32
            248 ->
                (self.p[7] as u16) as i32
            249 ->
                (self.p[8] as u16) as i32
            250 ->
                (self.p[9] as u16) as i32
            251 ->
                (self.p[8] as u16) as i32
            252 ->
                (self.p[9] as u16) as i32
            253 ->
                (self.vx as u8) as i32
            254 ->
                (self.vy as u8) as i32
            _ ->
                0

    fn set_reg_value(mut self, code: u8, val: i32):
        match code as i32:
            194 ->
                self.mem.bank = val as u8
            195 ->
                self.c0 = Wrapping<u16>(val as u16)
            196 ->
                self.c1 = Wrapping<u16>(val as u16)
            197 ->
                self.mx = Wrapping<u8>(val as u8)
            198 ->
                self.my = Wrapping<u8>(val as u8)
            199 ->
                self.mb = Wrapping<u8>(val as u8)
            200 ->
                self.vc = Wrapping<u8>(val as u8)
            201 ->
                let cur = self.p[0] as u16
                let newhigh = val as u8
                let combined = bit_or(bits::shl16(newhigh as u16, 8), (cur as u8) as u16)
                self.p[0] = Wrapping<u16>(combined)
            202 ->
                let cur = self.p[1] as u16
                let newhigh = val as u8
                let combined = bit_or(bits::shl16(newhigh as u16, 8), (cur as u8) as u16)
                self.p[1] = Wrapping<u16>(combined)
            203 ->
                let cur = self.p[2] as u16
                let newhigh = val as u8
                let combined = bit_or(bits::shl16(newhigh as u16, 8), (cur as u8) as u16)
                self.p[2] = Wrapping<u16>(combined)
            204 ->
                let cur = self.p[3] as u16
                let newhigh = val as u8
                let combined = bit_or(bits::shl16(newhigh as u16, 8), (cur as u8) as u16)
                self.p[3] = Wrapping<u16>(combined)
            205 ->
                let cur = self.p[4] as u16
                let newhigh = val as u8
                let combined = bit_or(bits::shl16(newhigh as u16, 8), (cur as u8) as u16)
                self.p[4] = Wrapping<u16>(combined)
            206 ->
                let cur = self.p[5] as u16
                let newhigh = val as u8
                let combined = bit_or(bits::shl16(newhigh as u16, 8), (cur as u8) as u16)
                self.p[5] = Wrapping<u16>(combined)
            207 ->
                let cur = self.p[6] as u16
                let newhigh = val as u8
                let combined = bit_or(bits::shl16(newhigh as u16, 8), (cur as u8) as u16)
                self.p[6] = Wrapping<u16>(combined)
            208 ->
                let cur = self.p[7] as u16
                let newhigh = val as u8
                let combined = bit_or(bits::shl16(newhigh as u16, 8), (cur as u8) as u16)
                self.p[7] = Wrapping<u16>(combined)
            209 ->
                let cur = self.p[8] as u16
                let newhigh = val as u8
                let combined = bit_or(bits::shl16(newhigh as u16, 8), (cur as u8) as u16)
                self.p[8] = Wrapping<u16>(combined)
            210 ->
                let cur = self.p[9] as u16
                let newhigh = val as u8
                let combined = bit_or(bits::shl16(newhigh as u16, 8), (cur as u8) as u16)
                self.p[9] = Wrapping<u16>(combined)
            211 ->
                let cur = self.p[0] as u16
                let newlow = val as u8
                let combined = bit_or(bits::shl16(bits::shr16(cur,8), 8), newlow as u16)
                self.p[0] = Wrapping<u16>(combined)
            212 ->
                let cur = self.p[1] as u16
                let newlow = val as u8
                let combined = bit_or(bits::shl16(bits::shr16(cur,8), 8), newlow as u16)
                self.p[1] = Wrapping<u16>(combined)
            213 ->
                let cur = self.p[2] as u16
                let newlow = val as u8
                let combined = bit_or(bits::shl16(bits::shr16(cur,8), 8), newlow as u16)
                self.p[2] = Wrapping<u16>(combined)
            214 ->
                let cur = self.p[3] as u16
                let newlow = val as u8
                let combined = bit_or(bits::shl16(bits::shr16(cur,8), 8), newlow as u16)
                self.p[3] = Wrapping<u16>(combined)
            215 ->
                let cur = self.p[4] as u16
                let newlow = val as u8
                let combined = bit_or(bits::shl16(bits::shr16(cur,8), 8), newlow as u16)
                self.p[4] = Wrapping<u16>(combined)
            216 ->
                let cur = self.p[5] as u16
                let newlow = val as u8
                let combined = bit_or(bits::shl16(bits::shr16(cur,8), 8), newlow as u16)
                self.p[5] = Wrapping<u16>(combined)
            217 ->
                let cur = self.p[6] as u16
                let newlow = val as u8
                let combined = bit_or(bits::shl16(bits::shr16(cur,8), 8), newlow as u16)
                self.p[6] = Wrapping<u16>(combined)
            218 ->
                let cur = self.p[7] as u16
                let newlow = val as u8
                let combined = bit_or(bits::shl16(bits::shr16(cur,8), 8), newlow as u16)
                self.p[7] = Wrapping<u16>(combined)
            219 ->
                let cur = self.p[8] as u16
                let newlow = val as u8
                let combined = bit_or(bits::shl16(bits::shr16(cur,8), 8), newlow as u16)
                self.p[8] = Wrapping<u16>(combined)
            220 ->
                let cur = self.p[9] as u16
                let newlow = val as u8
                let combined = bit_or(bits::shl16(bits::shr16(cur,8), 8), newlow as u16)
                self.p[9] = Wrapping<u16>(combined)
            221 ->
                self.sa = Wrapping<u16>(val as u16)
            222 ->
                self.sf = Wrapping<u8>(val as u8)
            223 ->
                self.sv = Wrapping<u8>(val as u8)
            224 ->
                self.sw = Wrapping<u8>(val as u8)
            225 ->
                self.vm = val as u8
            226 ->
                self.vl = val as u8
            227 ->
                self.tt = Wrapping<u8>(val as u8)
            228 ->
                self.tm = Wrapping<u8>(val as u8)
            229 ->
                self.tc = Wrapping<u8>(val as u8)
            230 ->
                self.ts = Wrapping<u8>(val as u8)
            231 ->
                self.r[0] = Wrapping<u8>(val as u8)
            232 ->
                self.r[1] = Wrapping<u8>(val as u8)
            233 ->
                self.r[2] = Wrapping<u8>(val as u8)
            234 ->
                self.r[3] = Wrapping<u8>(val as u8)
            235 ->
                self.r[4] = Wrapping<u8>(val as u8)
            236 ->
                self.r[5] = Wrapping<u8>(val as u8)
            237 ->
                self.r[6] = Wrapping<u8>(val as u8)
            238 ->
                self.r[7] = Wrapping<u8>(val as u8)
            239 ->
                self.r[8] = Wrapping<u8>(val as u8)
            240 ->
                self.r[9] = Wrapping<u8>(val as u8)
            241 ->
                self.p[0] = Wrapping<u16>(val as u16)
            242 ->
                self.p[1] = Wrapping<u16>(val as u16)
            243 ->
                self.p[2] = Wrapping<u16>(val as u16)
            244 ->
                self.p[3] = Wrapping<u16>(val as u16)
            245 ->
                self.p[4] = Wrapping<u16>(val as u16)
            246 ->
                self.p[5] = Wrapping<u16>(val as u16)
            247 ->
                self.p[6] = Wrapping<u16>(val as u16)
            248 ->
                self.p[7] = Wrapping<u16>(val as u16)
            249 ->
                self.p[8] = Wrapping<u16>(val as u16)
            250 ->
                self.p[9] = Wrapping<u16>(val as u16)
            251 ->
                self.p[8] = Wrapping<u16>(val as u16)
            252 ->
                self.p[9] = Wrapping<u16>(val as u16)
            253 ->
                self.vx = Wrapping<u8>(val as u8)
            254 ->
                self.vy = Wrapping<u8>(val as u8)
            _ ->
                self.halted = self.halted

    # ── Stack (SP = P8, grows downward, 16-bit big-endian words) ───────

    fn push16(mut self, val: i32):
        let sp = (self.p[8] as u16) as i32
        let newsp = wrap_addr(sp - 2)
        self.mem.write_word(newsp, val as u16)
        self.p[8] = Wrapping<u16>(newsp as u16)

    fn pop16(mut self) -> i32:
        let sp = (self.p[8] as u16) as i32
        let val = (self.mem.read_word(sp)) as i32
        let newsp = wrap_addr(sp + 2)
        self.p[8] = Wrapping<u16>(newsp as u16)
        val

    # ── Fetch ────────────────────────────────────────────────────────────

    fn fetch_u8(mut self) -> u8:
        let addr = (self.pc as u16) as i32
        let v = self.mem.read_byte(addr)
        self.pc = Wrapping<u16>((wrap_addr(addr + 1)) as u16)
        v

    fn fetch_u16(mut self) -> u16:
        let hi = self.fetch_u8()
        let lo = self.fetch_u8()
        bit_or(bits::shl16(hi as u16, 8), lo as u16)

    # ── Operand decoding (docs/Operand prefix system.md) ────────────────
    # Mode byte: bits0-1 = op1 mode, bits2-3 = op2 mode, bits4-5 = op3 mode,
    # bit6 = indexed (applies to every memory-mode operand in the
    # instruction), bit7 = direct (ditto). Mode values: 0=register direct,
    # 1=imm8, 2=imm16, 3=memory (direct/indexed bits pick which of the 4
    # memory forms).

    fn decode_operand(mut self, mode: i32, direct: bool, indexed: bool) -> Operand:
        match mode:
            0 ->
                let code = self.fetch_u8()
                Operand(kind = 0 as u8, reg_code = code, imm = 0 as u16, addr = 0 as u16)
            1 ->
                let v = self.fetch_u8()
                Operand(kind = 1 as u8, reg_code = 0 as u8, imm = v as u16, addr = 0 as u16)
            2 ->
                let v = self.fetch_u16()
                Operand(kind = 1 as u8, reg_code = 0 as u8, imm = v, addr = 0 as u16)
            _ ->
                if !direct and !indexed:
                    # [reg]
                    let code = self.fetch_u8()
                    let base = self.get_reg_value(code)
                    Operand(kind = 2 as u8, reg_code = 0 as u8, imm = 0 as u16, addr = (wrap_addr(base)) as u16)
                else:
                    if !direct and indexed:
                        # [reg+offset]
                        let code = self.fetch_u8()
                        let off = self.fetch_u8()
                        let base = self.get_reg_value(code)
                        let addr = base + bits::sign_extend8(off)
                        Operand(kind = 2 as u8, reg_code = 0 as u8, imm = 0 as u16, addr = (wrap_addr(addr)) as u16)
                    else:
                        if direct and !indexed:
                            # [addr16]
                            let a = self.fetch_u16()
                            Operand(kind = 2 as u8, reg_code = 0 as u8, imm = 0 as u16, addr = a)
                        else:
                            # [addr16+offset]
                            let a = self.fetch_u16()
                            let off = self.fetch_u8()
                            let addr = (a as i32) + bits::sign_extend8(off)
                            Operand(kind = 2 as u8, reg_code = 0 as u8, imm = 0 as u16, addr = (wrap_addr(addr)) as u16)

    # Decodes exactly `count` operands (0-3; every base-machine opcode this
    # port implements fits, see NOTES.md on the 4-operand string ops this
    # skips) sharing one mode byte, per the encoding above.
    fn decode_operands(mut self, count: i32) -> (Operand, Operand, Operand):
        if count == 0:
            (zero_operand(), zero_operand(), zero_operand())
        else:
            let mode_byte = self.fetch_u8()
            let b = mode_byte as i32
            let mode1 = b % 4
            let mode2 = (b / 4) % 4
            let mode3 = (b / 16) % 4
            let indexed = bit_get(mode_byte, 6)
            let direct = bit_get(mode_byte, 7)
            let op1 = self.decode_operand(mode1, direct, indexed)
            let mut op2 = zero_operand()
            if count >= 2:
                op2 = self.decode_operand(mode2, direct, indexed)
            let mut op3 = zero_operand()
            if count >= 3:
                op3 = self.decode_operand(mode3, direct, indexed)
            (op1, op2, op3)

    # ── Operand read/write, register width ──────────────────────────────

    fn reg_width(self, code: u8) -> i32:
        match code as i32:
            194 -> 8
            195 -> 16
            196 -> 16
            197 -> 8
            198 -> 8
            199 -> 8
            200 -> 8
            201 -> 8
            202 -> 8
            203 -> 8
            204 -> 8
            205 -> 8
            206 -> 8
            207 -> 8
            208 -> 8
            209 -> 8
            210 -> 8
            211 -> 8
            212 -> 8
            213 -> 8
            214 -> 8
            215 -> 8
            216 -> 8
            217 -> 8
            218 -> 8
            219 -> 8
            220 -> 8
            221 -> 16
            222 -> 8
            223 -> 8
            224 -> 8
            225 -> 8
            226 -> 8
            227 -> 8
            228 -> 8
            229 -> 8
            230 -> 8
            231 -> 8
            232 -> 8
            233 -> 8
            234 -> 8
            235 -> 8
            236 -> 8
            237 -> 8
            238 -> 8
            239 -> 8
            240 -> 8
            241 -> 16
            242 -> 16
            243 -> 16
            244 -> 16
            245 -> 16
            246 -> 16
            247 -> 16
            248 -> 16
            249 -> 16
            250 -> 16
            251 -> 16
            252 -> 16
            253 -> 8
            254 -> 8
            _ ->
                16

    fn operand_width(self, op: Operand) -> i32:
        if op.kind == (0 as u8):
            self.reg_width(op.reg_code)
        else:
            16

    fn operand_read(mut self, op: Operand, width: i32) -> i32:
        match op.kind as i32:
            0 ->
                self.get_reg_value(op.reg_code)
            1 ->
                op.imm as i32
            _ ->
                if width == 8:
                    (self.mem.read_byte(op.addr as i32)) as i32
                else:
                    (self.mem.read_word(op.addr as i32)) as i32

    fn operand_write(mut self, op: Operand, width: i32, value: i32):
        match op.kind as i32:
            0 ->
                self.set_reg_value(op.reg_code, value)
            2 ->
                if width == 8:
                    self.mem.write_byte(op.addr as i32, value as u8)
                else:
                    self.mem.write_word(op.addr as i32, value as u16)
            _ ->
                self.halted = self.halted

    fn mask_to_width(self, value: i32, width: i32) -> i32:
        if width == 8:
            (value as u8) as i32
        else:
            (value as u16) as i32

    # Reinterprets an unsigned width-bit register value (how every register
    # is stored -- 0..255 / 0..65535) as a signed two's-complement value of
    # that same width, for NEG/ABS and signed-magnitude ops.
    fn to_signed(self, val: i32, width: i32) -> i32:
        if width == 8:
            if val >= 128:
                val - 256
            else:
                val
        else:
            if val >= 32768:
                val - 65536
            else:
                val

    # BR/BRZ/BRNZ's relative offset is always a 16-bit signed quantity
    # regardless of which addressing mode encoded it (matches the upstream
    # reference's `_br`/`_brz`/`_brnz`: it checks bit 0x8000 unconditionally).
    fn to_signed16(self, val: i32) -> i32:
        let v = wrap_addr(val)
        if v >= 32768:
            v - 65536
        else:
            v

    # (x, y) the graphics opcodes should draw at/read from, given VM's
    # coordinate (0) vs linear (1) addressing mode (docs/VRAM Specification.md).
    fn vxy(self) -> (i32, i32):
        if self.vm == (0 as u8):
            (((self.vx as u8) as i32), ((self.vy as u8) as i32))
        else:
            let addr = (bit_or(bits::shl16((self.vx as u8) as u16, 8), (self.vy as u8) as u16)) as i32
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
            else:
                if code == (9 as u8):
                    cx += 32
                else:
                    if code == (10 as u8):
                        cx = 0
                        cy += 8
                    else:
                        if code == (13 as u8):
                            cx = 0
                        else:
                            self.screen.draw_char(code, cx, cy, color)
                            cx += 8
                            if cx + 8 > 256:
                                cx = 0
                                cy += 8
                a += 1
        (cx, cy)

    # ── Interrupts (docs/CPU Specification.md interrupt vector table) ──
    # Only Timer (vector 0) and Keyboard (vector 2) are real hardware
    # sources in this port (no UART/mouse event generation -- see
    # NOTES.md); INT is the software path, reaching every vector.

    fn trigger_interrupt(mut self, vector: i32):
        let flags_word = self.flags.pack()
        self.push16(flags_word as i32)
        self.push16((self.pc as u16) as i32)
        self.flags.set_i(false)
        let vec_addr = wrap_addr(IVT_BASE + vector * 4)
        self.pc = Wrapping<u16>(self.mem.read_word(vec_addr))

    fn check_interrupts(mut self):
        if self.flags.i():
            if self.pending_timer_irq:
                self.pending_timer_irq = false
                self.trigger_interrupt(0)
            else:
                if self.kbd.irq_pending():
                    self.trigger_interrupt(2)

    # ── Timer (docs/CPU Specification.md; TC bit0 enable, bit1 IRQ-enable,
    # divisor = TS+1). Ticked once per instruction rather than once per
    # host-clock-cycle -- a deliberate simplification (this is an
    # interpreter, not a cycle-accurate simulator); see NOTES.md.

    fn timer_tick(mut self):
        if bit_get(self.tc as u8, 0):
            self.timer_subcycle += 1
            let divisor = ((self.ts as u8) as i32) + 1
            if self.timer_subcycle >= divisor:
                self.timer_subcycle = 0
                let mut newtt = ((self.tt as u8) as i32) + 1
                if newtt > 255:
                    newtt = 255
                self.tt = Wrapping<u8>(newtt as u8)
                if bit_get(self.tc as u8, 1) and ((self.tm as u8) as i32) > 0 and newtt >= ((self.tm as u8) as i32):
                    self.tt = Wrapping<u8>(0 as u8)
                    self.pending_timer_irq = true
        else:
            self.timer_subcycle = 0
            self.tt = Wrapping<u8>(0 as u8)

    # ── Fetch-decode-execute ────────────────────────────────────────────

    fn step(mut self):
        if self.halted:
            self.halted = self.halted
        else:
            self.timer_tick()
            let opcode = self.fetch_u8()
            self.execute(opcode)
            self.cycles += 1 as i64
            self.check_interrupts()

    fn unimplemented_opcode(mut self, opcode: u8):
        println(f"[nova16] unimplemented opcode {opcode} at pc={self.pc} -- halting")
        self.halted = true

    # ── Data movement ────────────────────────────────────────────────────

    fn op_mov(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let v = self.operand_read(op2, width)
        self.operand_write(op1, width, self.mask_to_width(v, width))

    fn op_movz(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        if self.flags.z():
            let v = self.operand_read(op2, width)
            self.operand_write(op1, width, self.mask_to_width(v, width))

    fn op_movnz(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        if !self.flags.z():
            let v = self.operand_read(op2, width)
            self.operand_write(op1, width, self.mask_to_width(v, width))

    fn op_xchng(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        self.operand_write(op1, width, b)
        self.operand_write(op2, width, a)

    fn op_swap(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        if width == 8:
            let au8 = a as u8
            let hi_n = bits::shr8(au8, 4)
            let lo_n = bit_and(au8, 15 as u8)
            let swapped = bit_or(bits::shl8(lo_n, 4), hi_n)
            self.operand_write(op1, 8, swapped as i32)
        else:
            let au16 = a as u16
            let hi_b = bits::shr16(au16, 8)
            let lo_b = bit_and(au16, 255 as u16)
            let swapped = bit_or(bits::shl16(lo_b, 8), hi_b)
            self.operand_write(op1, 16, swapped as i32)

    # LEA: dest = the *address* a memory-mode source operand resolved to,
    # not the value stored there (register/immediate sources fall back to
    # their ordinary resolved value, matching a degenerate `LEA reg, reg`).
    fn op_lea(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let mut addr_val = 0
        if op2.kind == (2 as u8):
            addr_val = op2.addr as i32
        else:
            addr_val = self.operand_read(op2, width)
        self.operand_write(op1, width, addr_val)

    # ── Arithmetic ───────────────────────────────────────────────────────

    fn op_add(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let raw = a + b
        self.flags.apply_arith(raw, a, b, width, false, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_adc(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let mut carry_in = 0
        if self.flags.c():
            carry_in = 1
        let raw = a + b + carry_in
        self.flags.apply_arith(raw, a, b, width, false, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_sub(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let raw = a - b
        self.flags.apply_arith(raw, a, b, width, true, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_sbc(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let mut carry_in = 0
        if self.flags.c():
            carry_in = 1
        let raw = a - b - carry_in
        self.flags.apply_arith(raw, a, b, width, true, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_cmp(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let raw = a - b
        self.flags.apply_arith(raw, a, b, width, true, true)

    fn op_mul(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let raw = a * b
        self.flags.apply_arith(raw, a, b, width, false, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_mulh(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let product: i64 = (a as i64) * (b as i64)
        let mut hi: i64 = 0 as i64
        if width == 8:
            hi = product / (256 as i64)
        else:
            hi = product / (65536 as i64)
        self.operand_write(op1, width, self.mask_to_width(hi as i32, width))

    fn op_div(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        if b == 0:
            println("[nova16] DIV by zero -- ignored")
        else:
            let raw = a / b
            self.flags.apply_arith(raw, a, b, width, false, false)
            self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_divh(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        if b == 0:
            println("[nova16] DIVH by zero -- ignored")
        else:
            let ai: i64 = a as i64
            let bi: i64 = b as i64
            let mut shifted: i64 = ai
            if width == 8:
                shifted = ai * (256 as i64)
            else:
                shifted = ai * (65536 as i64)
            let q = shifted / bi
            self.operand_write(op1, width, self.mask_to_width(q as i32, width))

    fn op_mod(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        if b == 0:
            println("[nova16] MOD by zero -- ignored")
        else:
            let raw = a % b
            self.flags.apply_arith(raw, a, b, width, false, false)
            self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_inc(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let raw = a + 1
        self.flags.apply_arith(raw, a, 1, width, false, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_dec(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let raw = a - 1
        self.flags.apply_arith(raw, a, 1, width, true, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_neg(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let signed = self.to_signed(a, width)
        let raw = 0 - signed
        self.flags.apply_arith(raw, a, 0, width, true, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_abs(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let signed = self.to_signed(a, width)
        let mut raw = signed
        if signed < 0:
            raw = 0 - signed
        self.flags.apply_arith(raw, a, 0, width, false, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_min(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let mut raw = a
        if b < a:
            raw = b
        self.flags.apply_arith(raw, a, b, width, false, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_max(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let mut raw = a
        if b > a:
            raw = b
        self.flags.apply_arith(raw, a, b, width, false, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_clz(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let mut raw = 0
        if width == 8:
            raw = bits::clz8(a as u8)
        else:
            raw = bits::clz16(a as u16)
        self.operand_write(op1, width, raw)

    fn op_ctz(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let mut raw = 0
        if width == 8:
            raw = bits::ctz8(a as u8)
        else:
            raw = bits::ctz16(a as u16)
        self.operand_write(op1, width, raw)

    fn op_popcnt(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let mut raw = 0
        if width == 8:
            raw = bits::popcount8(a as u8)
        else:
            raw = bits::popcount16(a as u16)
        self.operand_write(op1, width, raw)

    # ── Bitwise ──────────────────────────────────────────────────────────

    fn op_and(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let raw = bit_and(a, b)
        self.flags.apply_logic(raw, width)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_or(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let raw = bit_or(a, b)
        self.flags.apply_logic(raw, width)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_xor(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let raw = bit_xor(a, b)
        self.flags.apply_logic(raw, width)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_not(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let raw = bit_not(a)
        self.flags.apply_logic(raw, width)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_shl(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let amt = self.operand_read(op2, width)
        let mut raw = 0
        if width == 8:
            raw = (bits::shl8(a as u8, amt)) as i32
        else:
            raw = (bits::shl16(a as u16, amt)) as i32
        self.flags.apply_logic(raw, width)
        self.operand_write(op1, width, raw)

    fn op_shr(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let amt = self.operand_read(op2, width)
        let mut raw = 0
        if width == 8:
            raw = (bits::shr8(a as u8, amt)) as i32
        else:
            raw = (bits::shr16(a as u16, amt)) as i32
        self.flags.apply_logic(raw, width)
        self.operand_write(op1, width, raw)

    fn op_sar(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let amt = self.operand_read(op2, width)
        let mut raw = 0
        if width == 8:
            raw = (bits::sar8(a as u8, amt)) as i32
        else:
            raw = (bits::sar16(a as u16, amt)) as i32
        self.flags.apply_logic(raw, width)
        self.operand_write(op1, width, raw)

    fn op_rol(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let amt = self.operand_read(op2, width)
        let mut raw = 0
        if width == 8:
            raw = (bits::rol8(a as u8, amt)) as i32
        else:
            raw = (bits::rol16(a as u16, amt)) as i32
        self.flags.apply_logic(raw, width)
        self.operand_write(op1, width, raw)

    fn op_ror(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let amt = self.operand_read(op2, width)
        let mut raw = 0
        if width == 8:
            raw = (bits::ror8(a as u8, amt)) as i32
        else:
            raw = (bits::ror16(a as u16, amt)) as i32
        self.flags.apply_logic(raw, width)
        self.operand_write(op1, width, raw)

    fn op_rcl(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let amt = self.operand_read(op2, width)
        let carry_in = self.flags.c()
        let mut raw = 0
        let mut carry_out = carry_in
        if width == 8:
            let pair = bits::rcl8(a as u8, carry_in, amt)
            raw = pair.0 as i32
            carry_out = pair.1
        else:
            let pair = bits::rcl16(a as u16, carry_in, amt)
            raw = pair.0 as i32
            carry_out = pair.1
        self.flags.apply_rotate(raw, width, carry_out)
        self.operand_write(op1, width, raw)

    fn op_rcr(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let amt = self.operand_read(op2, width)
        let carry_in = self.flags.c()
        let mut raw = 0
        let mut carry_out = carry_in
        if width == 8:
            let pair = bits::rcr8(a as u8, carry_in, amt)
            raw = pair.0 as i32
            carry_out = pair.1
        else:
            let pair = bits::rcr16(a as u16, carry_in, amt)
            raw = pair.0 as i32
            carry_out = pair.1
        self.flags.apply_rotate(raw, width, carry_out)
        self.operand_write(op1, width, raw)

    fn op_btst(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let bitidx = (self.operand_read(op2, width)) % width
        self.flags.set_z(!bit_get(a, bitidx))

    fn op_bset(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let bitidx = (self.operand_read(op2, width)) % width
        self.operand_write(op1, width, bit_set(a, bitidx))

    fn op_bclr(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let bitidx = (self.operand_read(op2, width)) % width
        self.operand_write(op1, width, bit_clear(a, bitidx))

    fn op_bflip(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let bitidx = (self.operand_read(op2, width)) % width
        self.operand_write(op1, width, bit_toggle(a, bitidx))

    # ── Stack ────────────────────────────────────────────────────────────

    fn op_push(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let v = self.operand_read(op1, width)
        self.push16(v)

    fn op_pop(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let v = self.pop16()
        self.operand_write(op1, width, self.mask_to_width(v, width))

    fn op_pushf(mut self):
        self.push16((self.flags.pack()) as i32)

    fn op_popf(mut self):
        let v = self.pop16()
        self.flags.unpack(v as u16)

    fn op_pusha(mut self):
        self.push16(((self.vc as u8) as i32))
        self.push16(((self.vy as u8) as i32))
        self.push16(((self.vx as u8) as i32))
        let mut i = 9
        while i >= 0:
            self.push16(((self.p[i] as u16) as i32))
            i -= 1
        i = 9
        while i >= 0:
            self.push16(((self.r[i] as u8) as i32))
            i -= 1

    fn op_popa(mut self):
        let mut i = 0
        while i < 10:
            let v = self.pop16()
            self.r[i] = Wrapping<u8>(v as u8)
            i += 1
        i = 0
        while i < 10:
            let v = self.pop16()
            self.p[i] = Wrapping<u16>(v as u16)
            i += 1
        let vxv = self.pop16()
        self.vx = Wrapping<u8>(vxv as u8)
        let vyv = self.pop16()
        self.vy = Wrapping<u8>(vyv as u8)
        let vcv = self.pop16()
        self.vc = Wrapping<u8>(vcv as u8)

    fn op_enter(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let size = self.operand_read(op1, width)
        self.push16((self.p[9] as u16) as i32)
        self.p[9] = self.p[8]
        let newsp = wrap_addr(((self.p[8] as u16) as i32) - size)
        self.p[8] = Wrapping<u16>(newsp as u16)

    fn op_leave(mut self):
        self.p[8] = self.p[9]
        let v = self.pop16()
        self.p[9] = Wrapping<u16>(v as u16)

    # ── Control flow ─────────────────────────────────────────────────────

    fn op_jmp(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let target = self.operand_read(op1, width)
        self.pc = Wrapping<u16>((wrap_addr(target)) as u16)

    fn jump_if(mut self, cond: bool):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let target = self.operand_read(op1, width)
        if cond:
            self.pc = Wrapping<u16>((wrap_addr(target)) as u16)

    fn op_br(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let raw = self.operand_read(op1, width)
        let offset = self.to_signed16(raw)
        self.pc = Wrapping<u16>((wrap_addr(((self.pc as u16) as i32) + offset)) as u16)

    fn op_brz(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let raw = self.operand_read(op1, width)
        if self.flags.z():
            let offset = self.to_signed16(raw)
            self.pc = Wrapping<u16>((wrap_addr(((self.pc as u16) as i32) + offset)) as u16)

    fn op_brnz(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let raw = self.operand_read(op1, width)
        if !self.flags.z():
            let offset = self.to_signed16(raw)
            self.pc = Wrapping<u16>((wrap_addr(((self.pc as u16) as i32) + offset)) as u16)

    fn op_call(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let target = self.operand_read(op1, width)
        self.push16((self.pc as u16) as i32)
        self.pc = Wrapping<u16>((wrap_addr(target)) as u16)

    fn op_callz(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let target = self.operand_read(op1, width)
        if self.flags.z():
            self.push16((self.pc as u16) as i32)
            self.pc = Wrapping<u16>((wrap_addr(target)) as u16)

    fn op_callnz(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let target = self.operand_read(op1, width)
        if !self.flags.z():
            self.push16((self.pc as u16) as i32)
            self.pc = Wrapping<u16>((wrap_addr(target)) as u16)

    fn op_ret(mut self):
        let v = self.pop16()
        self.pc = Wrapping<u16>((wrap_addr(v)) as u16)

    fn op_retn(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let result = self.operand_read(op1, width)
        self.r[0] = Wrapping<u8>(result as u8)
        self.p[0] = Wrapping<u16>(result as u16)
        self.flags.apply_arith(result, 0, 0, 16, false, false)
        let v = self.pop16()
        self.pc = Wrapping<u16>((wrap_addr(v)) as u16)

    fn op_iret(mut self):
        let pcv = self.pop16()
        let flg = self.pop16()
        self.flags.unpack(flg as u16)
        self.pc = Wrapping<u16>((wrap_addr(pcv)) as u16)

    fn op_int(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let vector = self.operand_read(op1, width)
        if self.flags.i():
            self.trigger_interrupt(vector)

    fn op_loop(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let newval = self.mask_to_width(a - 1, width)
        self.operand_write(op1, width, newval)
        if newval != 0:
            let target = self.operand_read(op2, self.operand_width(op2))
            self.pc = Wrapping<u16>((wrap_addr(target)) as u16)

    fn op_loopz(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let newval = self.mask_to_width(a - 1, width)
        self.operand_write(op1, width, newval)
        if newval != 0 and self.flags.z():
            let target = self.operand_read(op2, self.operand_width(op2))
            self.pc = Wrapping<u16>((wrap_addr(target)) as u16)

    fn op_while(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        self.flags.apply_arith(a, 0, 0, width, false, false)

    # ── Memory bulk ops ──────────────────────────────────────────────────

    fn op_memcpy(mut self):
        let ops = self.decode_operands(3)
        let op1 = ops.0
        let op2 = ops.1
        let op3 = ops.2
        let dest = self.operand_read(op1, 16)
        let src = self.operand_read(op2, 16)
        let len = self.operand_read(op3, 16)
        let mut i = 0
        while i < len:
            let b = self.mem.read_byte(wrap_addr(src + i))
            self.mem.write_byte(wrap_addr(dest + i), b)
            i += 1

    fn op_memset(mut self):
        let ops = self.decode_operands(3)
        let op1 = ops.0
        let op2 = ops.1
        let op3 = ops.2
        let dest = self.operand_read(op1, 16)
        let value = self.operand_read(op2, 16)
        let len = self.operand_read(op3, 16)
        let mut i = 0
        while i < len:
            self.mem.write_byte(wrap_addr(dest + i), value as u8)
            i += 1

    fn op_memmove(mut self):
        let ops = self.decode_operands(3)
        let op1 = ops.0
        let op2 = ops.1
        let op3 = ops.2
        let dest = self.operand_read(op1, 16)
        let src = self.operand_read(op2, 16)
        let len = self.operand_read(op3, 16)
        if dest <= src:
            let mut i = 0
            while i < len:
                let b = self.mem.read_byte(wrap_addr(src + i))
                self.mem.write_byte(wrap_addr(dest + i), b)
                i += 1
        else:
            let mut i = len - 1
            while i >= 0:
                let b = self.mem.read_byte(wrap_addr(src + i))
                self.mem.write_byte(wrap_addr(dest + i), b)
                i -= 1

    fn op_memswap(mut self):
        let ops = self.decode_operands(3)
        let op1 = ops.0
        let op2 = ops.1
        let op3 = ops.2
        let a1 = self.operand_read(op1, 16)
        let a2 = self.operand_read(op2, 16)
        let len = self.operand_read(op3, 16)
        let mut i = 0
        while i < len:
            let tmp = self.mem.read_byte(wrap_addr(a1 + i))
            let v2 = self.mem.read_byte(wrap_addr(a2 + i))
            self.mem.write_byte(wrap_addr(a1 + i), v2)
            self.mem.write_byte(wrap_addr(a2 + i), tmp)
            i += 1

    fn op_memtest(mut self):
        let ops = self.decode_operands(3)
        let op1 = ops.0
        let op2 = ops.1
        let op3 = ops.2
        let a1 = self.operand_read(op1, 16)
        let a2 = self.operand_read(op2, 16)
        let len = self.operand_read(op3, 16)
        let mut i = 0
        let mut equal = true
        while i < len:
            if self.mem.read_byte(wrap_addr(a1 + i)) != self.mem.read_byte(wrap_addr(a2 + i)):
                equal = false
            i += 1
        self.flags.set_z(equal)

    # ── Random ───────────────────────────────────────────────────────────

    fn op_rnd(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let width = self.operand_width(op1)
        let mut maxval = 256.0
        if width != 8:
            maxval = 65536.0
        let r = (rand() * maxval) as i32
        self.operand_write(op1, width, self.mask_to_width(r, width))

    fn op_rndr(mut self):
        let ops = self.decode_operands(3)
        let op1 = ops.0
        let op2 = ops.1
        let op3 = ops.2
        let width = self.operand_width(op1)
        let lo = self.operand_read(op2, width)
        let hi = self.operand_read(op3, width)
        let range = hi - lo + 1
        let mut r = lo
        if range > 0:
            r = lo + ((rand() * (range as f32)) as i32)
        self.operand_write(op1, width, self.mask_to_width(r, width))

    # ── Graphics ─────────────────────────────────────────────────────────

    fn op_sblend(mut self):
        let ops = self.decode_operands(1)
        self.halted = self.halted

    fn op_sread(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let xy = self.vxy()
        let x = xy.0
        let y = xy.1
        let v = self.screen.get_screen(x, y)
        self.operand_write(op1, 8, v as i32)

    fn op_swrite(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let v = self.operand_read(op1, 8)
        let xy = self.vxy()
        let x = xy.0
        let y = xy.1
        self.screen.set_screen(x, y, v as u8)

    fn op_vread(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let xy = self.vxy()
        let x = xy.0
        let y = xy.1
        let v = self.screen.get_vram(x, y)
        self.operand_write(op1, 8, v as i32)

    fn op_vwrite(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let v = self.operand_read(op1, 8)
        let xy = self.vxy()
        let x = xy.0
        let y = xy.1
        self.screen.set_vram(x, y, v as u8)

    fn op_sline(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let x1 = self.operand_read(op1, 8)
        let y1 = self.operand_read(op2, 8)
        let xy0 = self.vxy()
        let x0 = xy0.0
        let y0 = xy0.1
        self.screen.sline(x0, y0, x1, y1, (self.vc as u8))

    fn op_srect(mut self):
        let ops = self.decode_operands(3)
        let op1 = ops.0
        let op2 = ops.1
        let op3 = ops.2
        let x1 = self.operand_read(op1, 8)
        let y1 = self.operand_read(op2, 8)
        let filled = (self.operand_read(op3, 8)) != 0
        let xy0 = self.vxy()
        let x0 = xy0.0
        let y0 = xy0.1
        self.screen.srect(x0, y0, x1, y1, (self.vc as u8), filled)

    fn op_scirc(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let radius = self.operand_read(op1, 8)
        let filled = (self.operand_read(op2, 8)) != 0
        let cxy = self.vxy()
        let cx = cxy.0
        let cy = cxy.1
        self.screen.scirc(cx, cy, radius, (self.vc as u8), filled)

    fn op_sinv(mut self):
        self.screen.sinv()

    fn op_sblit(mut self):
        self.screen.sblit()

    fn op_vblit(mut self):
        self.screen.vblit()

    fn op_sfill(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let v = self.operand_read(op1, 8)
        self.screen.sfill(v as u8)

    fn op_srol(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let axis = self.operand_read(op1, 8)
        let amount = self.operand_read(op2, 8)
        if axis == 0:
            self.screen.roll_x(0 - amount)
        else:
            self.screen.roll_y(0 - amount)

    fn op_srot(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let direction = self.operand_read(op1, 8)
        let amount = self.operand_read(op2, 8)
        if direction == 0:
            self.screen.rotate_left(amount)
        else:
            self.screen.rotate_right(amount)

    fn op_sshft(mut self):
        let ops = self.decode_operands(2)
        let op1 = ops.0
        let op2 = ops.1
        let axis = self.operand_read(op1, 8)
        let amount = self.operand_read(op2, 8)
        if axis == 0:
            self.screen.shift_x(amount)
        else:
            self.screen.shift_y(amount)

    fn op_sflip(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let axis = self.operand_read(op1, 8)
        if axis == 0:
            self.screen.flip_x()
        else:
            self.screen.flip_y()

    fn op_char(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let code = self.operand_read(op1, 8)
        let xy = self.vxy()
        let x = xy.0
        let y = xy.1
        self.screen.draw_char(code as u8, x, y, (self.vc as u8))
        self.vx = Wrapping<u8>(((x + 8) % 256) as u8)

    fn op_text(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let addr = self.operand_read(op1, 16)
        let xy = self.vxy()
        let x = xy.0
        let y = xy.1
        let result = self.draw_text(addr, x, y, (self.vc as u8))
        self.vx = Wrapping<u8>((result.0 % 256) as u8)
        self.vy = Wrapping<u8>((result.1 % 256) as u8)

    # ── Keyboard ─────────────────────────────────────────────────────────

    fn op_keyin(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let vh = self.kbd.pop_key()
        let v = vh.0
        let had = vh.1
        self.flags.set_z(!had)
        self.operand_write(op1, 8, v as i32)

    fn op_keystat(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        self.operand_write(op1, 8, (self.kbd.keystat()) as i32)

    fn op_keycount(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        self.operand_write(op1, 8, (self.kbd.keycount()) as i32)

    fn op_keyclear(mut self):
        self.kbd.keyclear()

    fn op_keyctrl(mut self):
        let ops = self.decode_operands(1)
        let op1 = ops.0
        let v = self.operand_read(op1, 8)
        self.kbd.keyctrl(v as u8)

    # MOUSECTRL: enable/disable host mouse input+interrupts. Stubbed -- this
    # port doesn't generate mouse events/interrupts yet (MX/MY/MB are still
    # plain readable/writable registers via MOV, just never updated by a
    # real host mouse) -- see NOTES.md. Consumes its operand and no-ops.
    fn op_mousectrl(mut self):
        let ops = self.decode_operands(1)
        self.halted = self.halted

    # ── Dispatch ─────────────────────────────────────────────────────────

    fn execute(mut self, opcode: u8):
        match opcode as i32:
            0 ->
                self.halted = true
            255 ->
                self.halted = self.halted
            1 ->
                self.op_ret()
            2 ->
                self.op_iret()
            3 ->
                self.flags.set_i(false)
            4 ->
                self.flags.set_i(true)
            6 ->
                self.op_mov()
            7 ->
                self.op_add()
            8 ->
                self.op_sub()
            9 ->
                self.op_mul()
            10 ->
                self.op_div()
            11 ->
                self.op_inc()
            12 ->
                self.op_dec()
            13 ->
                self.op_mod()
            14 ->
                self.op_neg()
            15 ->
                self.op_abs()
            16 ->
                self.op_and()
            17 ->
                self.op_or()
            18 ->
                self.op_xor()
            19 ->
                self.op_not()
            20 ->
                self.op_shl()
            21 ->
                self.op_shr()
            22 ->
                self.op_rol()
            23 ->
                self.op_ror()
            24 ->
                self.op_push()
            25 ->
                self.op_pop()
            26 ->
                self.op_pushf()
            27 ->
                self.op_popf()
            28 ->
                self.op_pusha()
            29 ->
                self.op_popa()
            30 ->
                self.op_jmp()
            31 ->
                self.jump_if(self.flags.z())
            32 ->
                self.jump_if(!self.flags.z())
            33 ->
                self.jump_if(self.flags.o())
            34 ->
                self.jump_if(!self.flags.o())
            35 ->
                self.jump_if(self.flags.c())
            36 ->
                self.jump_if(!self.flags.c())
            37 ->
                self.jump_if(self.flags.s())
            38 ->
                self.jump_if(!self.flags.s())
            39 ->
                self.jump_if(!self.flags.z() and self.flags.s() == self.flags.o())
            40 ->
                self.jump_if(self.flags.s() != self.flags.o())
            41 ->
                self.jump_if(self.flags.s() == self.flags.o())
            42 ->
                self.jump_if(self.flags.z() or self.flags.s() != self.flags.o())
            43 ->
                self.op_br()
            44 ->
                self.op_brz()
            45 ->
                self.op_brnz()
            46 ->
                self.op_cmp()
            47 ->
                self.op_call()
            48 ->
                self.op_int()
            49 ->
                self.op_sblend()
            50 ->
                self.op_sread()
            51 ->
                self.op_swrite()
            52 ->
                self.op_srol()
            53 ->
                self.op_srot()
            54 ->
                self.op_sshft()
            55 ->
                self.op_sflip()
            56 ->
                self.op_sline()
            57 ->
                self.op_srect()
            58 ->
                self.op_scirc()
            59 ->
                self.op_sinv()
            60 ->
                self.op_sblit()
            61 ->
                self.op_sfill()
            62 ->
                self.op_vread()
            63 ->
                self.op_vwrite()
            64 ->
                self.op_vblit()
            65 ->
                self.op_char()
            66 ->
                self.op_text()
            67 ->
                self.op_keyin()
            68 ->
                self.op_keystat()
            69 ->
                self.op_keycount()
            70 ->
                self.op_keyclear()
            71 ->
                self.op_keyctrl()
            72 ->
                self.op_rnd()
            73 ->
                self.op_rndr()
            74 ->
                self.op_memcpy()
            90 ->
                self.op_loop()
            109 ->
                self.op_btst()
            110 ->
                self.op_bset()
            111 ->
                self.op_bclr()
            112 ->
                self.op_bflip()
            124 ->
                self.op_memset()
            125 ->
                self.op_memtest()
            126 ->
                self.op_memmove()
            135 ->
                self.op_adc()
            136 ->
                self.op_sbc()
            137 ->
                self.op_mulh()
            138 ->
                self.op_divh()
            139 ->
                self.op_min()
            140 ->
                self.op_max()
            141 ->
                self.op_clz()
            142 ->
                self.op_ctz()
            143 ->
                self.op_popcnt()
            144 ->
                self.op_sar()
            145 ->
                self.op_shl()
            146 ->
                self.op_rcl()
            147 ->
                self.op_rcr()
            148 ->
                self.op_swap()
            149 ->
                self.op_xchng()
            150 ->
                self.op_movz()
            151 ->
                self.op_movnz()
            152 ->
                self.op_lea()
            154 ->
                self.op_memswap()
            155 ->
                self.op_enter()
            156 ->
                self.op_leave()
            157 ->
                self.op_callz()
            158 ->
                self.op_callnz()
            159 ->
                self.op_retn()
            160 ->
                self.op_loopz()
            161 ->
                self.op_while()
            179 ->
                self.op_mousectrl()
            _ ->
                self.unimplemented_opcode(opcode)
