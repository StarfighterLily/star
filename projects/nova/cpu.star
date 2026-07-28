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

# Floor division (Python `//` semantics: rounds toward -infinity), needed by
# FDIV/FLOOR/CEIL/ROUND below since Star's own `/` truncates toward zero
# instead (see NOTES.md gotcha #1). Standard trunc-to-floor adjustment: `/`
# and `%` already agree with `floor_div16` whenever `a`/`b` have the same
# sign or divide evenly; otherwise `floor_div16` is one less.
fn floor_div16(a: i32, b: i32) -> i32:
    let q = a / b
    let r = a % b
    if r != 0 and (a < 0) != (b < 0):
        q - 1
    else:
        q

# ASCII uppercase, used by STRFINDI's case-insensitive comparison (and
# STRUPR's in-place conversion inlines the same 97-122 range check directly).
fn ascii_upper(c: i32) -> i32:
    if c >= 97 and c <= 122:
        c - 32
    else:
        c

# No builtin `pi` constant (see examples/trig_log.star, which computes its
# own via `4.0 * atan(1.0)`); DEG/RAD need one, so it's defined once here.
const PI: f32 = 3.14159265

# ~3e38, just under `f32::MAX` (~3.4028e38) -- an EXP/TAN overflow-to-+inf
# guard threshold (see their comments below).
const MATH_OVERFLOW_GUARD: f32 = 3.0e38

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

    # ── Math library (docs/nova16_instruction_reference.md 0x5B-0x6C) ──
    # Ported from core/exec_handlers.py's _powr/_sqrt/_log/.../_intgr. Every
    # one of these treats its operand as a 16-bit *signed* value via
    # `to_signed(a, 16)` regardless of the destination's resolved width --
    # matching the reference's own hardcoded `_to_signed_16`, unlike this
    # port's usual "infer width from the destination register's real kind"
    # rule (see "Operand width is inferred..." in NOTES.md). Deliberate, not
    # an oversight: Q8.8 fixed-point is inherently a 16-bit format, real
    # Nova-16 programs always target a P register (or memory) with these,
    # and the one case where the distinction could matter -- targeting an
    # 8-bit R/VX/SF/... register -- already reads only 8 bits before the
    # signed reinterpretation ever runs, so `to_signed(a, 16)` is a no-op
    # there in both this port and the reference alike (an 8-bit read is
    # always < 0x8000). Flags are likewise always computed at width=16,
    # matching `_set_arith_flags(..., 16, ...)` in every handler below --
    # `apply_arith`'s `op1`/`op2` arguments are each handler's *raw* operand
    # read(s), not the signed-reinterpreted value used for the math itself,
    # again matching the reference exactly.
    #
    # SIN/COS/TAN/ATAN/ASIN/ACOS/LOG/EXP/SQRT/POWR route through Star's
    # builtin math functions, which compute in `f32` (single) precision --
    # the Python reference uses `f64` throughout. Deliberately accepted for
    # the fixed-point-scaled ones (SIN/COS/etc.): Q8.8 only needs 8 bits of
    # fractional precision, far inside `f32`'s ~23-bit mantissa, so it can
    # only matter at the very edge of an exact-tie rounding boundary.
    # POWR/EXP's overflow thresholds are a bigger, more visible consequence
    # of the same gap -- see their own comments below.

    fn op_powr(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let p = pow(a, b)
        # `_powr` catches Python's OverflowError and substitutes 0; `f32`
        # overflows to +inf at a far lower magnitude than `f64` (~3.4e38 vs
        # ~1.8e308), so this falls back to 0 across a visibly wider range of
        # (base, exponent) pairs than the reference does. Also inherent:
        # `f32` only represents integers exactly up to 2**24 (~16.8M), so a
        # POWR result between that and the ~9e15 cutoff below is a rounded
        # approximation of the reference's exact (arbitrary-precision,
        # then-truncated-to-16-bits) result, not a bit-exact match -- there
        # is no way to reproduce Python's exact low-16-bits-of-a-bignum
        # behavior through float math; flagged rather than silently wrong.
        let mut result: i32 = 0
        if p == p and p < 9000000000000000.0 and p > (0.0 - 9000000000000000.0):
            result = (p as i64) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, a, b, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    fn op_sqrt(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let mut result = 0
        if v >= 0:
            result = sqrt(v) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    fn op_log(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let mut result = 0
        if v > 0:
            result = (log((v as f32) / 256.0) * 256.0) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    fn op_exp(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let p = exp((v as f32) / 256.0)
        # `_exp` substitutes 0xFFFF (not 0) on overflow. `f32` overflows
        # around exp(88.7) where `f64` doesn't overflow until exp(709.8) --
        # a real, reachable gap here (v/256 can be up to ~128), unlike
        # SIN/COS/TAN/ATAN's inputs, whose result magnitude is bounded
        # regardless of precision.
        let mut result = 0xFFFF
        if p == p and p < MATH_OVERFLOW_GUARD and p > (0.0 - MATH_OVERFLOW_GUARD):
            result = self.mask_to_width((p * 256.0) as i32, 16)
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    fn op_sin(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let result = (sin((v as f32) / 256.0) * 256.0) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    fn op_cos(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let result = (cos((v as f32) / 256.0) * 256.0) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    # TAN (0x61) is a genuine reference quirk, not a transcription slip: the
    # Python handler uses `v` directly as radians (not `v / 256.0` like
    # every other trig op here) and scales its result by 1000 (not 256).
    # Ported bug-for-bug -- `core/exec_handlers.py::_tan`'s own docstring
    # ("tangent (scaled by 1000)") confirms it's intentional upstream, odd
    # as it looks next to its neighbors.
    fn op_tan(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let t = tan(v as f32)
        let mut result = 0
        if t == t and t < MATH_OVERFLOW_GUARD and t > (0.0 - MATH_OVERFLOW_GUARD):
            result = self.mask_to_width((t * 1000.0) as i32, 16)
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    fn op_atan(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let result = (atan((v as f32) / 256.0) * 256.0) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    fn op_asin(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let mut result = 0
        if v >= (0 - 256) and v <= 256:
            result = (asin((v as f32) / 256.0) * 256.0) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    fn op_acos(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let mut result = 0
        if v >= (0 - 256) and v <= 256:
            result = (acos((v as f32) / 256.0) * 256.0) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    # DEG (0x65): despite the name, converts a plain-integer *degree* value
    # to Q8.8 *radians* (docs: "Converts deg to rad") -- `v` itself is the
    # degree count, not `v / 256.0`.
    fn op_deg(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let result = (((v as f32) * PI / 180.0) * 256.0) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    # RAD (0x66): the inverse -- Q8.8 radians in, plain-integer degrees out.
    fn op_rad(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let result = (((v as f32) / 256.0) * 180.0 / PI) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    fn op_floor(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let result = floor_div16(v, 256)
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    fn op_ceil(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let q = floor_div16(v, 256)
        let r = v - q * 256
        let mut result = q
        if r != 0:
            result = q + 1
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    # Round-half-to-even (matches Python's `round()`), computed with pure
    # integer arithmetic rather than through float math at all: `v / 256.0`
    # is always *exact* in a double or float (256 is a power of 2 and `v`
    # is only ever 16 bits), so the "exactly .5" tie case is a genuine tie,
    # not a float-precision artifact, and happens exactly when the
    # floor-remainder (`v` mod 256, always in [0, 256)) is exactly 128.
    fn op_round(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let q = floor_div16(v, 256)
        let frac = v - q * 256
        let mut result = q
        if frac > 128:
            result = q + 1
        elif frac == 128:
            if q % 2 != 0:
                result = q + 1
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    # TRUNC (0x6A) and INTGR (0x6C) are the same operation in the
    # reference (`_intgr`'s own docstring: "alias of TRUNC") -- both opcodes
    # dispatch here directly (see `execute` below) rather than duplicating
    # this method under two names.
    fn op_trunc(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let result = v / 256
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    # FRAC: fractional part with the *same sign as the input* (unlike
    # FLOOR's remainder) -- `v == TRUNC(v) * 256 + FRAC(v)`. This is Star's
    # `%` directly (truncating remainder, sign follows the dividend), not
    # `floor_div16`'s remainder.
    fn op_frac(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let result = v % 256
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    # ── Fixed-point Q8.8 conversion (0xAC-0xAF) ─────────────────────────
    # Same "always 16-bit signed regardless of resolved width" rule as the
    # math library above -- ported from core/exec_handlers.py's
    # _fmul/_fdiv/_ftoi/_itof.

    fn op_fmul(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let da = self.to_signed(a, 16)
        let db = self.to_signed(b, 16)
        # Widest possible |da * db| is 32768*32768 (~1.07e9), comfortably
        # inside i32 -- no overflow-trap risk from the plain `*` below.
        # `>>` arithmetic-shifts (sign-extending), matching Python's `>>`
        # floor-toward-negative-infinity semantics on a negative product.
        let raw = (da * db) >> 8
        let masked = self.mask_to_width(raw, 16)
        self.flags.apply_arith(masked, a, b, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_fdiv(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        # Python's FDIV raises on division by zero (a hard error); this port
        # instead prints a diagnostic and skips the write, matching the
        # existing DIV/MOD/DIVH precedent above (see NOTES.md "Known
        # simplifications").
        if b == 0:
            println("[nova16] FDIV by zero -- ignored")
        else:
            let da = self.to_signed(a, 16)
            let db = self.to_signed(b, 16)
            let raw = floor_div16(da << 8, db)
            let masked = self.mask_to_width(raw, 16)
            self.flags.apply_arith(masked, a, b, 16, false, false)
            self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_ftoi(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let signed = self.to_signed(a, 16)
        let raw = signed >> 8
        let masked = self.mask_to_width(raw, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_itof(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let signed = self.to_signed(a, 16)
        let raw = signed << 8
        let masked = self.mask_to_width(raw, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

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

    # ── String operations (docs/nova16_instruction_reference.md 0x71-0x7B)
    # Ported from core/exec_handlers.py's _strcpy/_strcat/.../_strfindi. All
    # operands here resolve to raw 16-bit *addresses* via `operand_read(op,
    # 16)`, the same convention MEMCPY/MEMSET/etc. already use above -- a
    # register/immediate operand's own value is the address, a memory-mode
    # operand's contents are dereferenced once more as a 16-bit pointer,
    # matching `core/exec.py::_resolve_single_operand`'s `is_memory` case.
    # STREXT/STREXTI (0x75/0x76) are 4-operand opcodes and stay out of scope
    # (see "4-operand instructions are out of scope" in NOTES.md). STRCMP/
    # STRLEN/STRFIND/STRFINDI hardcode their result into R0 rather than an
    # operand -- not a bug, that's what the reference's own handlers do
    # (`cpu.regfile.set('R', 0, ...)` directly, bypassing `_write_result`
    # entirely) -- so none of their operands are a "destination" in the
    # usual sense, all are read-only addresses/lengths.

    fn op_strcpy(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let mut dest = self.operand_read(op1, 16)
        let mut src = self.operand_read(op2, 16)
        let mut going = true
        while going:
            let c = self.mem.read_byte(wrap_addr(src))
            self.mem.write_byte(wrap_addr(dest), c)
            if c == (0 as u8):
                going = false
            else:
                src = wrap_addr(src + 1)
                dest = wrap_addr(dest + 1)

    fn op_strcat(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let dest0 = self.operand_read(op1, 16)
        let src0 = self.operand_read(op2, 16)
        let mut dest = dest0
        while self.mem.read_byte(wrap_addr(dest)) != (0 as u8):
            dest = wrap_addr(dest + 1)
        let mut src = src0
        let mut going = true
        while going:
            let c = self.mem.read_byte(wrap_addr(src))
            self.mem.write_byte(wrap_addr(dest), c)
            if c == (0 as u8):
                going = false
            else:
                src = wrap_addr(src + 1)
                dest = wrap_addr(dest + 1)

    fn op_strcmp(mut self):
        let (op1, op2, op3) = self.decode_operands(3)
        let str1 = self.operand_read(op1, 16)
        let str2 = self.operand_read(op2, 16)
        let length = self.operand_read(op3, 16)
        let mut result = 0
        let mut i = 0
        let mut going = true
        while going and i < length:
            let c1 = self.mem.read_byte(wrap_addr(str1 + i))
            let c2 = self.mem.read_byte(wrap_addr(str2 + i))
            if c1 != c2:
                result = if c1 < c2: 0 - 1 else: 1
                going = false
            elif c1 == (0 as u8):
                going = false
            else:
                i += 1
        let masked = self.mask_to_width(result, 16)
        self.r[0] = Wrapping<u8>(masked as u8)
        self.flags.apply_arith(masked, 0, 0, 16, false, false)

    fn op_strlen(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let src = self.operand_read(op1, 16)
        let mut length = 0
        while self.mem.read_byte(wrap_addr(src + length)) != (0 as u8):
            length = wrap_addr(length + 1)
        let masked = self.mask_to_width(length, 16)
        self.r[0] = Wrapping<u8>(masked as u8)
        self.flags.apply_arith(masked, 0, 0, 16, false, false)

    fn op_strupr(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let mut addr = self.operand_read(op1, 16)
        let mut going = true
        while going:
            let c = self.mem.read_byte(wrap_addr(addr))
            if c == (0 as u8):
                going = false
            else:
                let mut cv = c as i32
                if cv >= 97 and cv <= 122:
                    cv -= 32
                self.mem.write_byte(wrap_addr(addr), cv as u8)
                addr = wrap_addr(addr + 1)

    fn op_strlwr(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let mut addr = self.operand_read(op1, 16)
        let mut going = true
        while going:
            let c = self.mem.read_byte(wrap_addr(addr))
            if c == (0 as u8):
                going = false
            else:
                let mut cv = c as i32
                if cv >= 65 and cv <= 90:
                    cv += 32
                self.mem.write_byte(wrap_addr(addr), cv as u8)
                addr = wrap_addr(addr + 1)

    fn op_strrev(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let src = self.operand_read(op1, 16)
        let mut length = 0
        while self.mem.read_byte(wrap_addr(src + length)) != (0 as u8):
            length += 1
        let mut i = 0
        while i < length / 2:
            let left = wrap_addr(src + i)
            let right = wrap_addr(src + length - 1 - i)
            let lc = self.mem.read_byte(left)
            let rc = self.mem.read_byte(right)
            self.mem.write_byte(left, rc)
            self.mem.write_byte(right, lc)
            i += 1

    fn op_strfind(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let haystack = self.operand_read(op1, 16)
        let needle = self.operand_read(op2, 16)
        let mut haystack_pos = 0
        let mut found = false
        let mut scanning = true
        while scanning:
            let hc = self.mem.read_byte(wrap_addr(haystack + haystack_pos))
            if hc == (0 as u8):
                scanning = false
            else:
                let mut needle_pos = 0
                let mut is_match = true
                let mut checking = true
                while checking:
                    let nc = self.mem.read_byte(wrap_addr(needle + needle_pos))
                    if nc == (0 as u8):
                        checking = false
                    else:
                        let h = self.mem.read_byte(wrap_addr(haystack + haystack_pos + needle_pos))
                        if h != nc:
                            is_match = false
                            checking = false
                        else:
                            needle_pos += 1
                if is_match:
                    found = true
                    scanning = false
                else:
                    haystack_pos += 1
        let result = if found: 1 else: 0
        self.r[0] = Wrapping<u8>(result as u8)
        self.flags.apply_arith(result, 0, 0, 16, false, false)

    fn op_strfindi(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let haystack = self.operand_read(op1, 16)
        let needle = self.operand_read(op2, 16)
        let mut haystack_pos = 0
        let mut found = false
        let mut scanning = true
        while scanning:
            let hc = self.mem.read_byte(wrap_addr(haystack + haystack_pos))
            if hc == (0 as u8):
                scanning = false
            else:
                let mut needle_pos = 0
                let mut is_match = true
                let mut checking = true
                while checking:
                    let nc = self.mem.read_byte(wrap_addr(needle + needle_pos))
                    if nc == (0 as u8):
                        checking = false
                    else:
                        let h = self.mem.read_byte(wrap_addr(haystack + haystack_pos + needle_pos))
                        if ascii_upper(h as i32) != ascii_upper(nc as i32):
                            is_match = false
                            checking = false
                        else:
                            needle_pos += 1
                if is_match:
                    found = true
                    scanning = false
                else:
                    haystack_pos += 1
        let result = if found: 1 else: 0
        self.r[0] = Wrapping<u8>(result as u8)
        self.flags.apply_arith(result, 0, 0, 16, false, false)

    # ── Integer/String conversion (docs/nova16_instruction_reference.md
    # 0x83-0x86) ── Ported from core/exec_handlers.py's _itob/_btoi/_itos/
    # _stoi. ITOB's operands are both plain addresses/values like the string
    # ops above (no destination-register write, no flags -- matches
    # `_itob` exactly); BTOI/ITOS/STOI write their result through op1 via
    # `operand_write` (mirroring `_write_result(cpu, 0, ...)`) and do set
    # flags.

    fn op_itob(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let dest = self.operand_read(op1, 16)
        let value = self.operand_read(op2, 16)
        let mut digits: [u8; 16] = [0 as u8; 16]
        let mut count = 0
        if value == 0:
            digits[0] = 48 as u8
            count = 1
        else:
            let mut temp = value
            while temp > 0:
                digits[count] = (48 + (temp % 2)) as u8
                temp = temp / 2
                count += 1
        let mut i = 0
        while i < count:
            # Bits were collected least-significant-first; `binary_str` in
            # the reference is built by prepending each new bit, so the
            # most-significant bit ends up first in the written-out string.
            let c = digits[count - 1 - i]
            self.mem.write_byte(wrap_addr(dest + i), c)
            i += 1
        self.mem.write_byte(wrap_addr(dest + count), 0 as u8)

    fn op_btoi(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let src = self.operand_read(op2, 16)
        let mut result = 0
        let mut i = 0
        let mut going = true
        while going:
            let c = (self.mem.read_byte(wrap_addr(src + i))) as i32
            if c == 48 or c == 49:
                result = result * 2 + (c - 48)
                i += 1
            else:
                going = false
        let masked = self.mask_to_width(result, 16)
        self.operand_write(op1, width, self.mask_to_width(result, width))
        self.flags.apply_arith(masked, 0, 0, 16, false, false)

    # ITOS always writes its decimal string to the fixed static buffer
    # 0xA000 (not wherever op1 points) -- matches `_itos` exactly, which
    # hardcodes `buffer_addr = 0xA000` rather than deriving it from an
    # operand. op1 only ever receives that fixed address back as a pointer.
    fn op_itos(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let raw = self.operand_read(op2, 16)
        let value = self.to_signed(raw, 16)
        let buffer_addr = 0xA000
        let mut n = value
        let mut negative = false
        if n < 0:
            negative = true
            n = 0 - n
        let mut digits: [u8; 6] = [0 as u8; 6]
        let mut count = 0
        if n == 0:
            digits[0] = 48 as u8
            count = 1
        else:
            while n > 0:
                digits[count] = (48 + (n % 10)) as u8
                n = n / 10
                count += 1
        let mut pos = 0
        if negative:
            self.mem.write_byte(wrap_addr(buffer_addr + pos), 45 as u8)
            pos += 1
        let mut i = 0
        while i < count:
            let c = digits[count - 1 - i]
            self.mem.write_byte(wrap_addr(buffer_addr + pos), c)
            pos += 1
            i += 1
        self.mem.write_byte(wrap_addr(buffer_addr + pos), 0 as u8)
        self.operand_write(op1, width, self.mask_to_width(buffer_addr, width))
        self.flags.apply_arith(self.mask_to_width(buffer_addr, 16), 0, value, 16, false, false)

    # STOI's decimal parser is a deliberate simplification of Python's
    # `int(str)`: an optional leading `+`/`-` then one or more ASCII digits,
    # with the *entire* string required to match (any other character
    # anywhere, or an empty string, yields 0) -- covers every string ITOS
    # itself can produce and anything a real assembler would encode, without
    # reproducing `int()`'s whitespace-stripping. See NOTES.md.
    fn op_stoi(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let src = self.operand_read(op2, 16)
        let mut len = 0
        while self.mem.read_byte(wrap_addr(src + len)) != (0 as u8):
            len += 1
        let mut pos = 0
        let mut negative = false
        if len > 0:
            let first = (self.mem.read_byte(wrap_addr(src))) as i32
            if first == 45:
                negative = true
                pos = 1
            elif first == 43:
                pos = 1
        let mut result = 0
        let mut valid = pos < len
        let mut i = pos
        while valid and i < len:
            let c = (self.mem.read_byte(wrap_addr(src + i))) as i32
            if c >= 48 and c <= 57:
                result = result * 10 + (c - 48)
                i += 1
            else:
                valid = false
        if negative:
            result = 0 - result
        let mut final_result = result
        if !valid:
            final_result = 0
        let masked = self.mask_to_width(final_result, 16)
        self.operand_write(op1, width, self.mask_to_width(final_result, width))
        self.flags.apply_arith(masked, 0, 0, 16, false, false)

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
            0x5B ->
                self.op_powr()
            0x5C ->
                self.op_sqrt()
            0x5D ->
                self.op_log()
            0x5E ->
                self.op_exp()
            0x5F ->
                self.op_sin()
            0x60 ->
                self.op_cos()
            0x61 ->
                self.op_tan()
            0x62 ->
                self.op_atan()
            0x63 ->
                self.op_asin()
            0x64 ->
                self.op_acos()
            0x65 ->
                self.op_deg()
            0x66 ->
                self.op_rad()
            0x67 ->
                self.op_floor()
            0x68 ->
                self.op_ceil()
            0x69 ->
                self.op_round()
            0x6A ->
                self.op_trunc()
            0x6B ->
                self.op_frac()
            0x6C ->
                self.op_trunc()
            0x6D ->
                self.op_btst()
            0x6E ->
                self.op_bset()
            0x6F ->
                self.op_bclr()
            0x70 ->
                self.op_bflip()
            0x71 ->
                self.op_strcpy()
            0x72 ->
                self.op_strcat()
            0x73 ->
                self.op_strcmp()
            0x74 ->
                self.op_strlen()
            0x77 ->
                self.op_strupr()
            0x78 ->
                self.op_strlwr()
            0x79 ->
                self.op_strrev()
            0x7A ->
                self.op_strfind()
            0x7B ->
                self.op_strfindi()
            0x7C ->
                self.op_memset()
            0x7D ->
                self.op_memtest()
            0x7E ->
                self.op_memmove()
            0x83 ->
                self.op_itob()
            0x84 ->
                self.op_btoi()
            0x85 ->
                self.op_itos()
            0x86 ->
                self.op_stoi()
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
            0xAC ->
                self.op_fmul()
            0xAD ->
                self.op_fdiv()
            0xAE ->
                self.op_ftoi()
            0xAF ->
                self.op_itof()
            0xB3 ->
                self.op_mousectrl()
            _ ->
                self.unimplemented_opcode(opcode)
