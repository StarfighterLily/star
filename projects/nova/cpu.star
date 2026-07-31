# Nova-16 CPU core: registers, flags, the unified register-code address
# space (docs/CPU Specification.md / docs/nova16_instruction_reference.md),
# operand decoding, and the fetch-decode-execute cycle -- the machinery every
# opcode handler is built from. The ~90 opcode-handler methods themselves no
# longer live here (todo.md P2 #5): they're split across `cpu_data.star`
# (MOV/XCHNG/SWAP/LEA), `cpu_arith.star` (arithmetic + BCD), `cpu_math.star`
# (the transcendental/Q8.8 math library), `cpu_bitwise.star`,
# `cpu_stack.star`, `cpu_control.star` (JMP/BR/CALL/RET/LOOP/...),
# `cpu_mem.star` (bulk memory ops + RND), `cpu_graphics.star` (graphics +
# sprites), `cpu_io.star` (keyboard/serial/mouse), `cpu_sound.star`
# (SPLAY/SSTOP/STRIG), and `cpu_string.star` (the string library +
# integer/string conversion) -- one `impl cpu::Cpu:` block per file, each
# importing this file for the `Cpu` type. This was blocked for a long time
# by a real language gap (`impl` couldn't reach across a module boundary to
# extend a struct declared elsewhere -- see NOTES.md "Two Star compiler bugs
# found and fixed" / "Language gotchas"), then possible-but-undone once that
# gap was fixed, until this round. Every split-out file's own header comment
# explains why its `import "cpu.star" as cpu` isn't circular (the reverse
# direction -- this file's `execute()` calling `self.op_add()` etc. with no
# import of `cpu_arith.star` at all -- was confirmed to resolve correctly
# first, via a standalone three-file scratch repro, before touching this
# file for real: `Item::Impl` blocks are never mangled by file/alias, so
# method resolution doesn't care which physical file defines a callee, only
# that the ultimate build target imports every file that contributes one).
# `Memory`/`Screen`/`Keyboard`/`Flags` still stay in their own files and are
# reached as plain fields (composition, not inheritance) -- calling a method
# on `self.mem`/`self.screen`/`self.kbd`/`self.flags` works fine across the
# module boundary either way, proven the same way.
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
import "uart.star" as uart

struct Operand:
    mut kind: u8       # 0 = register, 1 = immediate, 2 = memory
    mut reg_code: u8
    mut imm: u16
    mut addr: u16
    mut imm_width: u8  # 8 or 16 -- which addressing mode (1 vs 2) produced
                       # an immediate operand's value; irrelevant (left at
                       # 16) for register/memory operands. See
                       # `Cpu::write_width_for`'s doc comment for why this
                       # exists.

fn zero_operand() -> Operand:
    Operand(kind = 0 as u8, reg_code = 0 as u8, imm = 0 as u16, addr = 0 as u16, imm_width = 16 as u8)

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
const SCB_START: i32 = 0xF000
const SCB_BLOCK_SIZE: i32 = 16
const SCB_COUNT: i32 = 16

struct Cpu:
    mut mem: mem::Memory
    mut screen: screen::Screen
    mut kbd: keyboard::Keyboard
    mut flags: flg::Flags
    mut uart: uart::Uart

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
    # Not a real ISA-visible register -- host-side bookkeeping only (see
    # `op_strig`'s doc comment): the next mixer channel (8-15) `STRIG`'s
    # rotating one-shot pool will use. Plain `i32` (not `Wrapping<u8>`)
    # since it's never read/written by any opcode and only ever cycles
    # through the small fixed range 8-15, never wrapping a full byte.
    mut next_strig_channel: i32
    # The `sound_load` handle (`todo.md` P2 #3) currently occupying each of
    # the 16 mixer channels this port ever addresses (0-7 the `SPLAY`
    # hardware voices, 8-15 `STRIG`'s rotating one-shot pool -- exactly
    # `crate::codegen::audio::NUM_CHANNELS`), or `null_ptr()` if that
    # channel has never played anything. `cpu_sound.star::op_splay`/
    # `op_strig` free a channel's previous handle the instant a new one
    # replaces it there; `op_sstop`/`Cpu::reinit` free every tracked handle
    # outright. See `sound.star`'s header comment for the full "why this is
    # safe with no per-channel completion callback" writeup.
    mut sound_channel_handles: [ptr; 16]
    # The raw, still-dry WAV buffer `op_splay` (`cpu_sound.star`) most
    # recently synthesized for each of Nova's 8 *addressable* hardware
    # channels (0-7 only -- `STRIG`'s 8-15 one-shot pool isn't cached here,
    # see `sound.star`'s "SMIX/SECHO/SREVERB/SFILTER" header section for
    # why). `todo.md` P2 #4: since neither the upstream reference nor this
    # port had a real handler for `SMIX`/`SECHO`/`SREVERB`/`SFILTER`, this
    # cache is what lets those four opcodes have *something real* to process
    # without a new "read back the live mixer buffer" native builtin --
    # `List<Bytes>` (dynamic, unlike `sound_channel_handles`'s fixed `[ptr;
    # 16]`) because a `Bytes`'s zero/default value isn't a usable "empty
    # buffer" the way `null_ptr()` already is for `ptr`; `new_channel_wav_cache`
    # below explicitly seeds all 8 slots with a real (empty) `Bytes()`.
    mut sound_channel_last_wav: List<Bytes>

    mut mx: Wrapping<u8>
    mut my: Wrapping<u8>
    mut mb: Wrapping<u8>
    mut mouse_enabled: bool
    mut mouse_pending_irq: bool
    mut c0: Wrapping<u16>
    mut c1: Wrapping<u16>

    mut halted: bool
    mut cycles: i64

# `Cpu::sound_channel_last_wav`'s only valid initial state -- 8 real empty
# `Bytes()` values (one per hardware channel), not a bare `List<Bytes>()`
# left to grow lazily, so every index 0-7 is always safe to read/write from
# construction onward. Shared by `new_cpu` (`main.star`) and
# `Cpu::reinit`/`cpu_sound.star::free_all_sound_handles` (`SSTOP`/`Reset`
# both need to clear this cache exactly like `sound_channel_handles`, since
# there's nothing left to apply `SECHO`/`SREVERB`/`SFILTER` to once
# everything's been stopped/reset).
fn new_channel_wav_cache() -> List<Bytes>:
    let mut l: List<Bytes> = List<Bytes>()
    let mut i = 0
    while i < 8:
        l.push(Bytes())
        i += 1
    l

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

    # PUSH/POP-only 8-bit stack ops -- see `push_pop_width` below for why
    # these exist at all (an R register or imm8 source pushes/pops only 1
    # byte, SP +-= 1, not the fixed 2-byte/SP +-= 2 every other stack op
    # here uses).
    fn push8(mut self, val: i32):
        let sp = (self.p[8] as u16) as i32
        let newsp = wrap_addr(sp - 1)
        self.mem.write_byte(newsp, val as u8)
        self.p[8] = Wrapping<u16>(newsp as u16)

    fn pop8(mut self) -> i32:
        let sp = (self.p[8] as u16) as i32
        let val = (self.mem.read_byte(sp)) as i32
        let newsp = wrap_addr(sp + 1)
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
                Operand(kind = 0 as u8, reg_code = code, imm = 0 as u16, addr = 0 as u16, imm_width = 16 as u8)
            1 ->
                let v = self.fetch_u8()
                Operand(kind = 1 as u8, reg_code = 0 as u8, imm = v as u16, addr = 0 as u16, imm_width = 8 as u8)
            2 ->
                let v = self.fetch_u16()
                Operand(kind = 1 as u8, reg_code = 0 as u8, imm = v, addr = 0 as u16, imm_width = 16 as u8)
            _ ->
                if !direct and !indexed:
                    # [reg]
                    let code = self.fetch_u8()
                    let base = self.get_reg_value(code)
                    Operand(kind = 2 as u8, reg_code = 0 as u8, imm = 0 as u16, addr = (wrap_addr(base)) as u16, imm_width = 16 as u8)
                elif !direct and indexed:
                    # [reg+offset]
                    let code = self.fetch_u8()
                    let off = self.fetch_u8()
                    let base = self.get_reg_value(code)
                    let addr = base + bits::sign_extend8(off)
                    Operand(kind = 2 as u8, reg_code = 0 as u8, imm = 0 as u16, addr = (wrap_addr(addr)) as u16, imm_width = 16 as u8)
                elif direct and !indexed:
                    # [addr16]
                    let a = self.fetch_u16()
                    Operand(kind = 2 as u8, reg_code = 0 as u8, imm = 0 as u16, addr = a, imm_width = 16 as u8)
                else:
                    # [addr16+offset]
                    let a = self.fetch_u16()
                    let off = self.fetch_u8()
                    let addr = (a as i32) + bits::sign_extend8(off)
                    Operand(kind = 2 as u8, reg_code = 0 as u8, imm = 0 as u16, addr = (wrap_addr(addr)) as u16, imm_width = 16 as u8)

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

    # A genuine port bug found via the sprite-test round (see NOTES.md
    # "MOV [mem], narrow-source write-width bug"), not a Star-compiler bug:
    # `core/exec_handlers.py::_write_result` determines how many bytes a
    # *memory* destination write actually spans from the **source**
    # operand's own width, not the destination-based `operand_width` hint
    # `_operand_width` (this method's model) uses for reads/flags --
    # `MOV [mem], imm8` writes one byte, `MOV [mem], imm16` writes two,
    # `MOV [mem], R0` (an 8-bit register source) writes one byte, and
    # anything else (a `P`/other 16-bit register, or copying from another
    # memory operand) writes two. A register destination is unaffected --
    # it always uses its own natural width regardless of the source, which
    # `operand_width(dest)` already gets right on its own.
    #
    # Originally wired into `MOV`/`MOVZ`/`MOVNZ` only (confirmed broken via
    # a real assembled program: a `MOV [addr], R0` sequence writing 16
    # sprite control block bytes silently produced all zeros, each write's
    # 16-bit default clobbering the next address' first byte -- see
    # NOTES.md for the full trace and live-Python-reference confirmation).
    # `_write_result`'s inference is called identically, with no per-opcode
    # override, from *every* handler in the reference that writes a result
    # back to its first operand -- so this is now wired into every such
    # handler in this file (`ADD`/`SUB`/`AND`/`XCHNG`/`LOOP`/`BSET`/...;
    # see NOTES.md "Generalizing the write-width fix" for the full list and
    # for the one genuinely surprising consequence found doing this: a
    # handler's *second* operand determines the write width even when that
    # operand isn't conceptually a "value source" at all -- e.g. `SHL
    # [addr], 3`'s shift-*amount* operand (an imm8) makes the shifted
    # result write only 1 byte, because `_write_result` always keys off
    # `cpu.operands[1]`'s own encoding regardless of what role it plays.
    # Confirmed intentional-if-odd reference behavior, not a transcription
    # slip, and ported the same "bug-for-bug" way this project already
    # treats `TAN`'s scaling and the BCDS masking-order quirk.
    fn write_width_for(self, dest: Operand, src: Operand) -> i32:
        if dest.kind != (2 as u8):
            self.operand_width(dest)
        elif src.kind == (1 as u8):
            src.imm_width as i32
        elif src.kind == (0 as u8) and self.reg_width(src.reg_code) == 8:
            8
        else:
            16

    # PUSH/POP's stack-slot width is a *separate* rule from `write_width_for`
    # above: it's the operand's own kind (not a paired dest/src), matching
    # `core/exec_handlers.py::_push_pop_width` exactly -- an R register or
    # imm8 operand pushes/pops 1 byte (SP +-= 1); a P register, imm16, or
    # memory operand pushes/pops 2 bytes (SP +-= 2). Confirmed against the
    # live reference over MCP (`PUSH R0` from SP=0x9000 left SP=0x8FFF, a
    # 1-byte push; `PUSH P0` from the same SP left SP=0x8FFE, a 2-byte
    # push) -- this contradicts `docs/nova16_instruction_reference.md`'s own
    # PUSH/POP entries, which both say the fixed "SP -= 2"/"SP += 2" this
    # port originally implemented (always calling `push16`/`pop16`
    # regardless of operand kind). The doc is stale against the actually-
    # running reference here, the same way `SPRITE_SYSTEM.md`'s opcode
    # section already turned out to be (see "Layer compositing and
    # sprites" below) -- this port now matches the live CPU, not the doc.
    fn push_pop_width(self, op: Operand) -> i32:
        if op.kind == (0 as u8):
            self.reg_width(op.reg_code)
        elif op.kind == (1 as u8):
            op.imm_width as i32
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

    # ── Interrupts (docs/CPU Specification.md interrupt vector table) ──
    # Timer (vector 0), Serial/UART (vector 1), Keyboard (vector 2), and
    # Mouse (vector 3) are all real hardware sources in this port; INT is
    # the software path, reaching every vector. Priority follows the docs'
    # own table (Timer highest, Serial high, Keyboard/Mouse medium) via
    # this `elif` cascade's own top-to-bottom order.

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
            elif self.uart.interrupt_enabled and self.uart.irq_pending():
                self.uart.clear_irq_pending()
                self.trigger_interrupt(1)
            elif self.kbd.irq_pending():
                self.trigger_interrupt(2)
            elif self.mouse_enabled and self.mouse_pending_irq:
                self.mouse_pending_irq = false
                self.trigger_interrupt(3)

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

    # `jump_if` stays here (not in `cpu_control.star` with `op_jmp`/
    # `op_br`/`op_brz`/`op_brnz`) because it has no dedicated `op_*` opcode
    # handler of its own: the whole JZ/JNZ/JO/JNO/JC/JNC/JS/JNS/JLE/JG/JGE/JL
    # conditional-jump family (`docs/nova16_instruction_reference.md`) calls
    # `self.jump_if(cond)` directly, inline, from `execute()`'s own dispatch
    # match below -- its one real call site lives in this file, so it does
    # too (todo.md P2 #5's opcode-handler split).
    fn jump_if(mut self, cond: bool):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let target = self.operand_read(op1, width)
        if cond:
            self.pc = Wrapping<u16>((wrap_addr(target)) as u16)

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
            0x4B ->
                self.flags.set_d(true)
            0x4C ->
                self.flags.set_d(false)
            0x4D ->
                self.flags.set_a(false)
            0x4E ->
                self.op_bcda()
            0x4F ->
                self.op_bcds()
            0x50 ->
                self.op_bcdcmp()
            0x51 ->
                self.op_bcd2bin()
            0x52 ->
                self.op_bin2bcd()
            0x53 ->
                self.op_bcdadd()
            0x54 ->
                self.op_bcdsub()
            0x55 ->
                self.op_spblit()
            0x56 ->
                self.op_spblitall()
            0x57 ->
                self.op_splay()
            0x58 ->
                self.op_sstop()
            0x59 ->
                self.op_strig()
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
            0x7F ->
                self.op_smix()
            0x80 ->
                self.op_secho()
            0x81 ->
                self.op_sreverb()
            0x82 ->
                self.op_sfilter()
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
            0xA2 ->
                self.op_serin()
            0xA3 ->
                self.op_serout()
            0xA4 ->
                self.op_serstat()
            0xA5 ->
                self.op_serctrl()
            0xAC ->
                self.op_fmul()
            0xAD ->
                self.op_fdiv()
            0xAE ->
                self.op_ftoi()
            0xAF ->
                self.op_itof()
            0xB0 ->
                self.op_lswap()
            0xB1 ->
                self.op_lmove()
            0xB2 ->
                self.op_lcopy()
            0xB3 ->
                self.op_mousectrl()
            _ ->
                self.unimplemented_opcode(opcode)
