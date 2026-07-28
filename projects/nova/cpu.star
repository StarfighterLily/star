# Nova-16 CPU core: registers, flags, the unified register-code address
# space (docs/CPU Specification.md / docs/nova16_instruction_reference.md),
# operand decoding, and the fetch-decode-execute cycle. This is still the one
# file every mutating operation on the machine's state lives in: `Cpu`'s
# struct and all of its ~90 opcode-handler methods live together here even
# though the language gap that originally forced that (`impl` couldn't reach
# across a module boundary to extend a struct declared elsewhere) is fixed
# now -- see NOTES.md "Two Star compiler bugs found and fixed" / "Language
# gotchas". Splitting the opcode handlers across files by group (arithmetic/
# bitwise/stack/control-flow/graphics/...) is now possible but hasn't been
# done; would need each split-out `impl Cpu:` block to live in its own file
# and import `cpu.star` for the `Cpu` type. `Memory`/`Screen`/`Keyboard`/
# `Flags` still stay in their own files and are reached as plain fields
# (composition, not inheritance) -- calling a method on
# `self.mem`/`self.screen`/`self.kbd`/`self.flags` works fine across the
# module boundary either way.
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
# truth, built to mirror `core/regfile.py::_build_register_code_map` exactly.
# Register codes and opcode numbers are spelled as hex literals (`0xC2`,
# `0x10`, ...), matching docs/nova16_instruction_reference.md's own opcode
# table -- Star's lexer gained `0x`-prefixed integer literals since this file
# was first written decimal-only (see NOTES.md).

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
    mut flags: flg::Flags

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
            0xC2 ->
                self.mem.bank as i32
            0xC3 ->
                (self.c0 as u16) as i32
            0xC4 ->
                (self.c1 as u16) as i32
            0xC5 ->
                (self.mx as u8) as i32
            0xC6 ->
                (self.my as u8) as i32
            0xC7 ->
                (self.mb as u8) as i32
            0xC8 ->
                (self.vc as u8) as i32
            0xC9 ->
                let cur = self.p[0] as u16
                ((cur >> 8)) as i32
            0xCA ->
                let cur = self.p[1] as u16
                ((cur >> 8)) as i32
            0xCB ->
                let cur = self.p[2] as u16
                ((cur >> 8)) as i32
            0xCC ->
                let cur = self.p[3] as u16
                ((cur >> 8)) as i32
            0xCD ->
                let cur = self.p[4] as u16
                ((cur >> 8)) as i32
            0xCE ->
                let cur = self.p[5] as u16
                ((cur >> 8)) as i32
            0xCF ->
                let cur = self.p[6] as u16
                ((cur >> 8)) as i32
            0xD0 ->
                let cur = self.p[7] as u16
                ((cur >> 8)) as i32
            0xD1 ->
                let cur = self.p[8] as u16
                ((cur >> 8)) as i32
            0xD2 ->
                let cur = self.p[9] as u16
                ((cur >> 8)) as i32
            0xD3 ->
                let cur = self.p[0] as u16
                (cur as u8) as i32
            0xD4 ->
                let cur = self.p[1] as u16
                (cur as u8) as i32
            0xD5 ->
                let cur = self.p[2] as u16
                (cur as u8) as i32
            0xD6 ->
                let cur = self.p[3] as u16
                (cur as u8) as i32
            0xD7 ->
                let cur = self.p[4] as u16
                (cur as u8) as i32
            0xD8 ->
                let cur = self.p[5] as u16
                (cur as u8) as i32
            0xD9 ->
                let cur = self.p[6] as u16
                (cur as u8) as i32
            0xDA ->
                let cur = self.p[7] as u16
                (cur as u8) as i32
            0xDB ->
                let cur = self.p[8] as u16
                (cur as u8) as i32
            0xDC ->
                let cur = self.p[9] as u16
                (cur as u8) as i32
            0xDD ->
                (self.sa as u16) as i32
            0xDE ->
                (self.sf as u8) as i32
            0xDF ->
                (self.sv as u8) as i32
            0xE0 ->
                (self.sw as u8) as i32
            0xE1 ->
                self.vm as i32
            0xE2 ->
                self.vl as i32
            0xE3 ->
                (self.tt as u8) as i32
            0xE4 ->
                (self.tm as u8) as i32
            0xE5 ->
                (self.tc as u8) as i32
            0xE6 ->
                (self.ts as u8) as i32
            0xE7 ->
                (self.r[0] as u8) as i32
            0xE8 ->
                (self.r[1] as u8) as i32
            0xE9 ->
                (self.r[2] as u8) as i32
            0xEA ->
                (self.r[3] as u8) as i32
            0xEB ->
                (self.r[4] as u8) as i32
            0xEC ->
                (self.r[5] as u8) as i32
            0xED ->
                (self.r[6] as u8) as i32
            0xEE ->
                (self.r[7] as u8) as i32
            0xEF ->
                (self.r[8] as u8) as i32
            0xF0 ->
                (self.r[9] as u8) as i32
            0xF1 ->
                (self.p[0] as u16) as i32
            0xF2 ->
                (self.p[1] as u16) as i32
            0xF3 ->
                (self.p[2] as u16) as i32
            0xF4 ->
                (self.p[3] as u16) as i32
            0xF5 ->
                (self.p[4] as u16) as i32
            0xF6 ->
                (self.p[5] as u16) as i32
            0xF7 ->
                (self.p[6] as u16) as i32
            0xF8 ->
                (self.p[7] as u16) as i32
            0xF9 ->
                (self.p[8] as u16) as i32
            0xFA ->
                (self.p[9] as u16) as i32
            0xFB ->
                (self.p[8] as u16) as i32
            0xFC ->
                (self.p[9] as u16) as i32
            0xFD ->
                (self.vx as u8) as i32
            0xFE ->
                (self.vy as u8) as i32
            _ ->
                0

    fn set_reg_value(mut self, code: u8, val: i32):
        match code as i32:
            0xC2 ->
                self.mem.bank = val as u8
            0xC3 ->
                self.c0 = Wrapping<u16>(val as u16)
            0xC4 ->
                self.c1 = Wrapping<u16>(val as u16)
            0xC5 ->
                self.mx = Wrapping<u8>(val as u8)
            0xC6 ->
                self.my = Wrapping<u8>(val as u8)
            0xC7 ->
                self.mb = Wrapping<u8>(val as u8)
            0xC8 ->
                self.vc = Wrapping<u8>(val as u8)
            0xC9 ->
                let cur = self.p[0] as u16
                let newhigh = val as u8
                let combined = ((newhigh as u16 << 8) | (cur as u8) as u16)
                self.p[0] = Wrapping<u16>(combined)
            0xCA ->
                let cur = self.p[1] as u16
                let newhigh = val as u8
                let combined = ((newhigh as u16 << 8) | (cur as u8) as u16)
                self.p[1] = Wrapping<u16>(combined)
            0xCB ->
                let cur = self.p[2] as u16
                let newhigh = val as u8
                let combined = ((newhigh as u16 << 8) | (cur as u8) as u16)
                self.p[2] = Wrapping<u16>(combined)
            0xCC ->
                let cur = self.p[3] as u16
                let newhigh = val as u8
                let combined = ((newhigh as u16 << 8) | (cur as u8) as u16)
                self.p[3] = Wrapping<u16>(combined)
            0xCD ->
                let cur = self.p[4] as u16
                let newhigh = val as u8
                let combined = ((newhigh as u16 << 8) | (cur as u8) as u16)
                self.p[4] = Wrapping<u16>(combined)
            0xCE ->
                let cur = self.p[5] as u16
                let newhigh = val as u8
                let combined = ((newhigh as u16 << 8) | (cur as u8) as u16)
                self.p[5] = Wrapping<u16>(combined)
            0xCF ->
                let cur = self.p[6] as u16
                let newhigh = val as u8
                let combined = ((newhigh as u16 << 8) | (cur as u8) as u16)
                self.p[6] = Wrapping<u16>(combined)
            0xD0 ->
                let cur = self.p[7] as u16
                let newhigh = val as u8
                let combined = ((newhigh as u16 << 8) | (cur as u8) as u16)
                self.p[7] = Wrapping<u16>(combined)
            0xD1 ->
                let cur = self.p[8] as u16
                let newhigh = val as u8
                let combined = ((newhigh as u16 << 8) | (cur as u8) as u16)
                self.p[8] = Wrapping<u16>(combined)
            0xD2 ->
                let cur = self.p[9] as u16
                let newhigh = val as u8
                let combined = ((newhigh as u16 << 8) | (cur as u8) as u16)
                self.p[9] = Wrapping<u16>(combined)
            0xD3 ->
                let cur = self.p[0] as u16
                let newlow = val as u8
                let combined = ((cur >> 8) << 8) | newlow as u16
                self.p[0] = Wrapping<u16>(combined)
            0xD4 ->
                let cur = self.p[1] as u16
                let newlow = val as u8
                let combined = ((cur >> 8) << 8) | newlow as u16
                self.p[1] = Wrapping<u16>(combined)
            0xD5 ->
                let cur = self.p[2] as u16
                let newlow = val as u8
                let combined = ((cur >> 8) << 8) | newlow as u16
                self.p[2] = Wrapping<u16>(combined)
            0xD6 ->
                let cur = self.p[3] as u16
                let newlow = val as u8
                let combined = ((cur >> 8) << 8) | newlow as u16
                self.p[3] = Wrapping<u16>(combined)
            0xD7 ->
                let cur = self.p[4] as u16
                let newlow = val as u8
                let combined = ((cur >> 8) << 8) | newlow as u16
                self.p[4] = Wrapping<u16>(combined)
            0xD8 ->
                let cur = self.p[5] as u16
                let newlow = val as u8
                let combined = ((cur >> 8) << 8) | newlow as u16
                self.p[5] = Wrapping<u16>(combined)
            0xD9 ->
                let cur = self.p[6] as u16
                let newlow = val as u8
                let combined = ((cur >> 8) << 8) | newlow as u16
                self.p[6] = Wrapping<u16>(combined)
            0xDA ->
                let cur = self.p[7] as u16
                let newlow = val as u8
                let combined = ((cur >> 8) << 8) | newlow as u16
                self.p[7] = Wrapping<u16>(combined)
            0xDB ->
                let cur = self.p[8] as u16
                let newlow = val as u8
                let combined = ((cur >> 8) << 8) | newlow as u16
                self.p[8] = Wrapping<u16>(combined)
            0xDC ->
                let cur = self.p[9] as u16
                let newlow = val as u8
                let combined = ((cur >> 8) << 8) | newlow as u16
                self.p[9] = Wrapping<u16>(combined)
            0xDD ->
                self.sa = Wrapping<u16>(val as u16)
            0xDE ->
                self.sf = Wrapping<u8>(val as u8)
            0xDF ->
                self.sv = Wrapping<u8>(val as u8)
            0xE0 ->
                self.sw = Wrapping<u8>(val as u8)
            0xE1 ->
                self.vm = val as u8
            0xE2 ->
                self.vl = val as u8
            0xE3 ->
                self.tt = Wrapping<u8>(val as u8)
            0xE4 ->
                self.tm = Wrapping<u8>(val as u8)
            0xE5 ->
                self.tc = Wrapping<u8>(val as u8)
            0xE6 ->
                self.ts = Wrapping<u8>(val as u8)
            0xE7 ->
                self.r[0] = Wrapping<u8>(val as u8)
            0xE8 ->
                self.r[1] = Wrapping<u8>(val as u8)
            0xE9 ->
                self.r[2] = Wrapping<u8>(val as u8)
            0xEA ->
                self.r[3] = Wrapping<u8>(val as u8)
            0xEB ->
                self.r[4] = Wrapping<u8>(val as u8)
            0xEC ->
                self.r[5] = Wrapping<u8>(val as u8)
            0xED ->
                self.r[6] = Wrapping<u8>(val as u8)
            0xEE ->
                self.r[7] = Wrapping<u8>(val as u8)
            0xEF ->
                self.r[8] = Wrapping<u8>(val as u8)
            0xF0 ->
                self.r[9] = Wrapping<u8>(val as u8)
            0xF1 ->
                self.p[0] = Wrapping<u16>(val as u16)
            0xF2 ->
                self.p[1] = Wrapping<u16>(val as u16)
            0xF3 ->
                self.p[2] = Wrapping<u16>(val as u16)
            0xF4 ->
                self.p[3] = Wrapping<u16>(val as u16)
            0xF5 ->
                self.p[4] = Wrapping<u16>(val as u16)
            0xF6 ->
                self.p[5] = Wrapping<u16>(val as u16)
            0xF7 ->
                self.p[6] = Wrapping<u16>(val as u16)
            0xF8 ->
                self.p[7] = Wrapping<u16>(val as u16)
            0xF9 ->
                self.p[8] = Wrapping<u16>(val as u16)
            0xFA ->
                self.p[9] = Wrapping<u16>(val as u16)
            0xFB ->
                self.p[8] = Wrapping<u16>(val as u16)
            0xFC ->
                self.p[9] = Wrapping<u16>(val as u16)
            0xFD ->
                self.vx = Wrapping<u8>(val as u8)
            0xFE ->
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
        (hi as u16 << 8) | lo as u16

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
                elif !direct and indexed:
                    # [reg+offset]
                    let code = self.fetch_u8()
                    let off = self.fetch_u8()
                    let base = self.get_reg_value(code)
                    let addr = base + bits::sign_extend8(off)
                    Operand(kind = 2 as u8, reg_code = 0 as u8, imm = 0 as u16, addr = (wrap_addr(addr)) as u16)
                elif direct and !indexed:
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
            0xC2 -> 8
            0xC3 -> 16
            0xC4 -> 16
            0xC5 -> 8
            0xC6 -> 8
            0xC7 -> 8
            0xC8 -> 8
            0xC9 -> 8
            0xCA -> 8
            0xCB -> 8
            0xCC -> 8
            0xCD -> 8
            0xCE -> 8
            0xCF -> 8
            0xD0 -> 8
            0xD1 -> 8
            0xD2 -> 8
            0xD3 -> 8
            0xD4 -> 8
            0xD5 -> 8
            0xD6 -> 8
            0xD7 -> 8
            0xD8 -> 8
            0xD9 -> 8
            0xDA -> 8
            0xDB -> 8
            0xDC -> 8
            0xDD -> 16
            0xDE -> 8
            0xDF -> 8
            0xE0 -> 8
            0xE1 -> 8
            0xE2 -> 8
            0xE3 -> 8
            0xE4 -> 8
            0xE5 -> 8
            0xE6 -> 8
            0xE7 -> 8
            0xE8 -> 8
            0xE9 -> 8
            0xEA -> 8
            0xEB -> 8
            0xEC -> 8
            0xED -> 8
            0xEE -> 8
            0xEF -> 8
            0xF0 -> 8
            0xF1 -> 16
            0xF2 -> 16
            0xF3 -> 16
            0xF4 -> 16
            0xF5 -> 16
            0xF6 -> 16
            0xF7 -> 16
            0xF8 -> 16
            0xF9 -> 16
            0xFA -> 16
            0xFB -> 16
            0xFC -> 16
            0xFD -> 8
            0xFE -> 8
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
            elif self.kbd.irq_pending():
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
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let v = self.operand_read(op2, width)
        self.operand_write(op1, width, self.mask_to_width(v, width))

    fn op_movz(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        if self.flags.z():
            let v = self.operand_read(op2, width)
            self.operand_write(op1, width, self.mask_to_width(v, width))

    fn op_movnz(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        if !self.flags.z():
            let v = self.operand_read(op2, width)
            self.operand_write(op1, width, self.mask_to_width(v, width))

    fn op_xchng(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        self.operand_write(op1, width, b)
        self.operand_write(op2, width, a)

    fn op_swap(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        if width == 8:
            let au8 = a as u8
            let hi_n = bits::shr8(au8, 4)
            let lo_n = (au8 & 15 as u8)
            let swapped = ((lo_n << 4) | hi_n)
            self.operand_write(op1, 8, swapped as i32)
        else:
            let au16 = a as u16
            let hi_b = (au16 >> 8)
            let lo_b = (au16 & 255 as u16)
            let swapped = (lo_b << 8) | hi_b
            self.operand_write(op1, 16, swapped as i32)

    # LEA: dest = the *address* a memory-mode source operand resolved to,
    # not the value stored there (register/immediate sources fall back to
    # their ordinary resolved value, matching a degenerate `LEA reg, reg`).
    fn op_lea(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let mut addr_val = 0
        if op2.kind == (2 as u8):
            addr_val = op2.addr as i32
        else:
            addr_val = self.operand_read(op2, width)
        self.operand_write(op1, width, addr_val)

    # ── Arithmetic ───────────────────────────────────────────────────────

    fn op_add(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let raw = a + b
        self.flags.apply_arith(raw, a, b, width, false, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_adc(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
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
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let raw = a - b
        self.flags.apply_arith(raw, a, b, width, true, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_sbc(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
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
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let raw = a - b
        self.flags.apply_arith(raw, a, b, width, true, true)

    fn op_mul(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let raw = a * b
        self.flags.apply_arith(raw, a, b, width, false, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_mulh(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
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
        let (op1, op2, _op3) = self.decode_operands(2)
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
        let (op1, op2, _op3) = self.decode_operands(2)
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
        let (op1, op2, _op3) = self.decode_operands(2)
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
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let raw = a + 1
        self.flags.apply_arith(raw, a, 1, width, false, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_dec(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let raw = a - 1
        self.flags.apply_arith(raw, a, 1, width, true, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_neg(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let signed = self.to_signed(a, width)
        let raw = 0 - signed
        self.flags.apply_arith(raw, a, 0, width, true, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_abs(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let signed = self.to_signed(a, width)
        let mut raw = signed
        if signed < 0:
            raw = 0 - signed
        self.flags.apply_arith(raw, a, 0, width, false, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_min(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let mut raw = a
        if b < a:
            raw = b
        self.flags.apply_arith(raw, a, b, width, false, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_max(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let mut raw = a
        if b > a:
            raw = b
        self.flags.apply_arith(raw, a, b, width, false, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_clz(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let mut raw = 0
        if width == 8:
            raw = bits::clz8(a as u8)
        else:
            raw = bits::clz16(a as u16)
        self.operand_write(op1, width, raw)

    fn op_ctz(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let mut raw = 0
        if width == 8:
            raw = bits::ctz8(a as u8)
        else:
            raw = bits::ctz16(a as u16)
        self.operand_write(op1, width, raw)

    fn op_popcnt(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
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
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let raw = (a & b)
        self.flags.apply_logic(raw, width)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_or(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let raw = (a | b)
        self.flags.apply_logic(raw, width)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_xor(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let raw = (a ^ b)
        self.flags.apply_logic(raw, width)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_not(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let raw = (~a)
        self.flags.apply_logic(raw, width)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_shl(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
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
        let (op1, op2, _op3) = self.decode_operands(2)
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
        let (op1, op2, _op3) = self.decode_operands(2)
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
        let (op1, op2, _op3) = self.decode_operands(2)
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
        let (op1, op2, _op3) = self.decode_operands(2)
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
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let amt = self.operand_read(op2, width)
        let carry_in = self.flags.c()
        let (raw, carry_out) = if width == 8:
            let (r, c) = bits::rcl8(a as u8, carry_in, amt)
            (r as i32, c)
        else:
            let (r, c) = bits::rcl16(a as u16, carry_in, amt)
            (r as i32, c)
        self.flags.apply_rotate(raw, width, carry_out)
        self.operand_write(op1, width, raw)

    fn op_rcr(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let amt = self.operand_read(op2, width)
        let carry_in = self.flags.c()
        let (raw, carry_out) = if width == 8:
            let (r, c) = bits::rcr8(a as u8, carry_in, amt)
            (r as i32, c)
        else:
            let (r, c) = bits::rcr16(a as u16, carry_in, amt)
            (r as i32, c)
        self.flags.apply_rotate(raw, width, carry_out)
        self.operand_write(op1, width, raw)

    fn op_btst(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let bitidx = (self.operand_read(op2, width)) % width
        self.flags.set_z(!bit_get(a, bitidx))

    fn op_bset(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let bitidx = (self.operand_read(op2, width)) % width
        self.operand_write(op1, width, bit_set(a, bitidx))

    fn op_bclr(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let bitidx = (self.operand_read(op2, width)) % width
        self.operand_write(op1, width, bit_clear(a, bitidx))

    fn op_bflip(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let bitidx = (self.operand_read(op2, width)) % width
        self.operand_write(op1, width, bit_toggle(a, bitidx))

    # ── Stack ────────────────────────────────────────────────────────────

    fn op_push(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let v = self.operand_read(op1, width)
        self.push16(v)

    fn op_pop(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
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
        let (op1, _op2, _op3) = self.decode_operands(1)
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
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let target = self.operand_read(op1, width)
        self.pc = Wrapping<u16>((wrap_addr(target)) as u16)

    fn jump_if(mut self, cond: bool):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let target = self.operand_read(op1, width)
        if cond:
            self.pc = Wrapping<u16>((wrap_addr(target)) as u16)

    fn op_br(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let raw = self.operand_read(op1, width)
        let offset = self.to_signed16(raw)
        self.pc = Wrapping<u16>((wrap_addr(((self.pc as u16) as i32) + offset)) as u16)

    fn op_brz(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let raw = self.operand_read(op1, width)
        if self.flags.z():
            let offset = self.to_signed16(raw)
            self.pc = Wrapping<u16>((wrap_addr(((self.pc as u16) as i32) + offset)) as u16)

    fn op_brnz(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let raw = self.operand_read(op1, width)
        if !self.flags.z():
            let offset = self.to_signed16(raw)
            self.pc = Wrapping<u16>((wrap_addr(((self.pc as u16) as i32) + offset)) as u16)

    fn op_call(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let target = self.operand_read(op1, width)
        self.push16((self.pc as u16) as i32)
        self.pc = Wrapping<u16>((wrap_addr(target)) as u16)

    fn op_callz(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let target = self.operand_read(op1, width)
        if self.flags.z():
            self.push16((self.pc as u16) as i32)
            self.pc = Wrapping<u16>((wrap_addr(target)) as u16)

    fn op_callnz(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let target = self.operand_read(op1, width)
        if !self.flags.z():
            self.push16((self.pc as u16) as i32)
            self.pc = Wrapping<u16>((wrap_addr(target)) as u16)

    fn op_ret(mut self):
        let v = self.pop16()
        self.pc = Wrapping<u16>((wrap_addr(v)) as u16)

    fn op_retn(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
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
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let vector = self.operand_read(op1, width)
        if self.flags.i():
            self.trigger_interrupt(vector)

    fn op_loop(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let newval = self.mask_to_width(a - 1, width)
        self.operand_write(op1, width, newval)
        if newval != 0:
            let target = self.operand_read(op2, self.operand_width(op2))
            self.pc = Wrapping<u16>((wrap_addr(target)) as u16)

    fn op_loopz(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let newval = self.mask_to_width(a - 1, width)
        self.operand_write(op1, width, newval)
        if newval != 0 and self.flags.z():
            let target = self.operand_read(op2, self.operand_width(op2))
            self.pc = Wrapping<u16>((wrap_addr(target)) as u16)

    fn op_while(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        self.flags.apply_arith(a, 0, 0, width, false, false)

    # ── Memory bulk ops ──────────────────────────────────────────────────

    fn op_memcpy(mut self):
        let (op1, op2, op3) = self.decode_operands(3)
        let dest = self.operand_read(op1, 16)
        let src = self.operand_read(op2, 16)
        let len = self.operand_read(op3, 16)
        let mut i = 0
        while i < len:
            let b = self.mem.read_byte(wrap_addr(src + i))
            self.mem.write_byte(wrap_addr(dest + i), b)
            i += 1

    fn op_memset(mut self):
        let (op1, op2, op3) = self.decode_operands(3)
        let dest = self.operand_read(op1, 16)
        let value = self.operand_read(op2, 16)
        let len = self.operand_read(op3, 16)
        let mut i = 0
        while i < len:
            self.mem.write_byte(wrap_addr(dest + i), value as u8)
            i += 1

    fn op_memmove(mut self):
        let (op1, op2, op3) = self.decode_operands(3)
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
        let (op1, op2, op3) = self.decode_operands(3)
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
        let (op1, op2, op3) = self.decode_operands(3)
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
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let mut maxval = 256.0
        if width != 8:
            maxval = 65536.0
        let r = (rand() * maxval) as i32
        self.operand_write(op1, width, self.mask_to_width(r, width))

    fn op_rndr(mut self):
        let (op1, op2, op3) = self.decode_operands(3)
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
        let (op1, _op2, _op3) = self.decode_operands(1)
        let (x, y) = self.vxy()
        let v = self.screen.get_screen(x, y)
        self.operand_write(op1, 8, v as i32)

    fn op_swrite(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let v = self.operand_read(op1, 8)
        let (x, y) = self.vxy()
        self.screen.set_screen(x, y, v as u8)

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
        self.screen.sline(x0, y0, x1, y1, (self.vc as u8))

    fn op_srect(mut self):
        let (op1, op2, op3) = self.decode_operands(3)
        let x1 = self.operand_read(op1, 8)
        let y1 = self.operand_read(op2, 8)
        let filled = (self.operand_read(op3, 8)) != 0
        let (x0, y0) = self.vxy()
        self.screen.srect(x0, y0, x1, y1, (self.vc as u8), filled)

    fn op_scirc(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let radius = self.operand_read(op1, 8)
        let filled = (self.operand_read(op2, 8)) != 0
        let (cx, cy) = self.vxy()
        self.screen.scirc(cx, cy, radius, (self.vc as u8), filled)

    fn op_sinv(mut self):
        self.screen.sinv()

    fn op_sblit(mut self):
        self.screen.sblit()

    fn op_vblit(mut self):
        self.screen.vblit()

    fn op_sfill(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let v = self.operand_read(op1, 8)
        self.screen.sfill(v as u8)

    fn op_srol(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let axis = self.operand_read(op1, 8)
        let amount = self.operand_read(op2, 8)
        if axis == 0:
            self.screen.roll_x(0 - amount)
        else:
            self.screen.roll_y(0 - amount)

    fn op_srot(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let direction = self.operand_read(op1, 8)
        let amount = self.operand_read(op2, 8)
        if direction == 0:
            self.screen.rotate_left(amount)
        else:
            self.screen.rotate_right(amount)

    fn op_sshft(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let axis = self.operand_read(op1, 8)
        let amount = self.operand_read(op2, 8)
        if axis == 0:
            self.screen.shift_x(amount)
        else:
            self.screen.shift_y(amount)

    fn op_sflip(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let axis = self.operand_read(op1, 8)
        if axis == 0:
            self.screen.flip_x()
        else:
            self.screen.flip_y()

    fn op_char(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let code = self.operand_read(op1, 8)
        let (x, y) = self.vxy()
        self.screen.draw_char(code as u8, x, y, (self.vc as u8))
        self.vx = Wrapping<u8>(((x + 8) % 256) as u8)

    fn op_text(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let addr = self.operand_read(op1, 16)
        let (x, y) = self.vxy()
        let result = self.draw_text(addr, x, y, (self.vc as u8))
        self.vx = Wrapping<u8>((result.0 % 256) as u8)
        self.vy = Wrapping<u8>((result.1 % 256) as u8)

    # ── Keyboard ─────────────────────────────────────────────────────────

    fn op_keyin(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let (v, had) = self.kbd.pop_key()
        self.flags.set_z(!had)
        self.operand_write(op1, 8, v as i32)

    fn op_keystat(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        self.operand_write(op1, 8, (self.kbd.keystat()) as i32)

    fn op_keycount(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        self.operand_write(op1, 8, (self.kbd.keycount()) as i32)

    fn op_keyclear(mut self):
        self.kbd.keyclear()

    fn op_keyctrl(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
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
            0x00 ->
                self.halted = true
            0xFF ->
                self.halted = self.halted
            0x01 ->
                self.op_ret()
            0x02 ->
                self.op_iret()
            0x03 ->
                self.flags.set_i(false)
            0x04 ->
                self.flags.set_i(true)
            0x06 ->
                self.op_mov()
            0x07 ->
                self.op_add()
            0x08 ->
                self.op_sub()
            0x09 ->
                self.op_mul()
            0x0A ->
                self.op_div()
            0x0B ->
                self.op_inc()
            0x0C ->
                self.op_dec()
            0x0D ->
                self.op_mod()
            0x0E ->
                self.op_neg()
            0x0F ->
                self.op_abs()
            0x10 ->
                self.op_and()
            0x11 ->
                self.op_or()
            0x12 ->
                self.op_xor()
            0x13 ->
                self.op_not()
            0x14 ->
                self.op_shl()
            0x15 ->
                self.op_shr()
            0x16 ->
                self.op_rol()
            0x17 ->
                self.op_ror()
            0x18 ->
                self.op_push()
            0x19 ->
                self.op_pop()
            0x1A ->
                self.op_pushf()
            0x1B ->
                self.op_popf()
            0x1C ->
                self.op_pusha()
            0x1D ->
                self.op_popa()
            0x1E ->
                self.op_jmp()
            0x1F ->
                self.jump_if(self.flags.z())
            0x20 ->
                self.jump_if(!self.flags.z())
            0x21 ->
                self.jump_if(self.flags.o())
            0x22 ->
                self.jump_if(!self.flags.o())
            0x23 ->
                self.jump_if(self.flags.c())
            0x24 ->
                self.jump_if(!self.flags.c())
            0x25 ->
                self.jump_if(self.flags.s())
            0x26 ->
                self.jump_if(!self.flags.s())
            0x27 ->
                self.jump_if(!self.flags.z() and self.flags.s() == self.flags.o())
            0x28 ->
                self.jump_if(self.flags.s() != self.flags.o())
            0x29 ->
                self.jump_if(self.flags.s() == self.flags.o())
            0x2A ->
                self.jump_if(self.flags.z() or self.flags.s() != self.flags.o())
            0x2B ->
                self.op_br()
            0x2C ->
                self.op_brz()
            0x2D ->
                self.op_brnz()
            0x2E ->
                self.op_cmp()
            0x2F ->
                self.op_call()
            0x30 ->
                self.op_int()
            0x31 ->
                self.op_sblend()
            0x32 ->
                self.op_sread()
            0x33 ->
                self.op_swrite()
            0x34 ->
                self.op_srol()
            0x35 ->
                self.op_srot()
            0x36 ->
                self.op_sshft()
            0x37 ->
                self.op_sflip()
            0x38 ->
                self.op_sline()
            0x39 ->
                self.op_srect()
            0x3A ->
                self.op_scirc()
            0x3B ->
                self.op_sinv()
            0x3C ->
                self.op_sblit()
            0x3D ->
                self.op_sfill()
            0x3E ->
                self.op_vread()
            0x3F ->
                self.op_vwrite()
            0x40 ->
                self.op_vblit()
            0x41 ->
                self.op_char()
            0x42 ->
                self.op_text()
            0x43 ->
                self.op_keyin()
            0x44 ->
                self.op_keystat()
            0x45 ->
                self.op_keycount()
            0x46 ->
                self.op_keyclear()
            0x47 ->
                self.op_keyctrl()
            0x48 ->
                self.op_rnd()
            0x49 ->
                self.op_rndr()
            0x4A ->
                self.op_memcpy()
            0x5A ->
                self.op_loop()
            0x6D ->
                self.op_btst()
            0x6E ->
                self.op_bset()
            0x6F ->
                self.op_bclr()
            0x70 ->
                self.op_bflip()
            0x7C ->
                self.op_memset()
            0x7D ->
                self.op_memtest()
            0x7E ->
                self.op_memmove()
            0x87 ->
                self.op_adc()
            0x88 ->
                self.op_sbc()
            0x89 ->
                self.op_mulh()
            0x8A ->
                self.op_divh()
            0x8B ->
                self.op_min()
            0x8C ->
                self.op_max()
            0x8D ->
                self.op_clz()
            0x8E ->
                self.op_ctz()
            0x8F ->
                self.op_popcnt()
            0x90 ->
                self.op_sar()
            0x91 ->
                self.op_shl()
            0x92 ->
                self.op_rcl()
            0x93 ->
                self.op_rcr()
            0x94 ->
                self.op_swap()
            0x95 ->
                self.op_xchng()
            0x96 ->
                self.op_movz()
            0x97 ->
                self.op_movnz()
            0x98 ->
                self.op_lea()
            0x9A ->
                self.op_memswap()
            0x9B ->
                self.op_enter()
            0x9C ->
                self.op_leave()
            0x9D ->
                self.op_callz()
            0x9E ->
                self.op_callnz()
            0x9F ->
                self.op_retn()
            0xA0 ->
                self.op_loopz()
            0xA1 ->
                self.op_while()
            0xB3 ->
                self.op_mousectrl()
            _ ->
                self.unimplemented_opcode(opcode)
