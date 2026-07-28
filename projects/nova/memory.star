# Nova-16 memory model: a 64KB unified, byte-addressable, big-endian address
# space (0x0000-0xFFFF), plus the optional bank-switched 16KB expansion
# window at 0x8000-0xBFFF (docs/CPU Specification.md, docs/nova16_instruction_reference.md).
# Bank 0 is a pass-through to base RAM (byte-identical to no banking at all);
# banks 1-15 are independent 16KB pages of extra RAM, selected by the `BANK`
# register (0-15) and otherwise invisible outside that address window.
#
# Deliberately NOT ported from the Python reference (see projects/nova/NOTES.md
# "Python-only speed hacks skipped"): the opcode-fetch instruction cache, the
# `read_byte`/`read_byte_fast` bounds-checked-vs-not split, and any
# dirty-region tracking. This always bounds-checks (for free: `[T; N]`
# indexing in Star is itself safe -- out-of-range is a zero-value read / a
# silent no-op write, never a crash) and always goes through the same single
# read/write path regardless of whether the caller is the CPU's own
# fetch-decode loop or a running program's data access.

import "bits.star" as bits

const BANK_WINDOW_START: i32 = 32768   # 0x8000
const BANK_WINDOW_END: i32 = 49152     # 0xC000 (exclusive)
const BANK_SIZE: i32 = 16384           # 0x4000

struct Memory:
    mut ram: [u8; 65536]
    mut bank_ram: [u8; 245760]   # 15 banks * 16384 bytes (banks 1-15; bank 0 has no storage here)
    mut bank: u8

# `new_memory()` returns `Memory` (~300KB: two fixed arrays plus the bank
# byte) by value. This used to be impossible -- a plain function returning a
# large struct/array by value hung `clang` outright, the exact bug NOTES.md
# documents under "Two Star compiler bugs found and fixed" -- so `Memory(...)`
# had to be built directly inline at the one `let mut cpu = Cpu(mem =
# Memory(...), ...)` call site in main.star. Fixed at the compiler level by
# todo.md P0 #2 (large struct/array return now uses a hidden `sret`
# out-pointer instead of a by-value `ret`, so this constructor's body -- a
# fresh struct literal -- gets built directly into the caller's storage, zero
# copies of the whole aggregate). Confirmed with a real `star build`.
fn new_memory() -> Memory:
    Memory(ram = [0 as u8; 65536], bank_ram = [0 as u8; 245760], bank = 0 as u8)

impl Memory:
    fn read_byte(self, addr: i32) -> u8:
        let a = ((addr % 65536) + 65536) % 65536
        if self.bank != (0 as u8) and a >= BANK_WINDOW_START and a < BANK_WINDOW_END:
            let bank_num = (self.bank as i32) - 1
            let offset = bank_num * BANK_SIZE + (a - BANK_WINDOW_START)
            self.bank_ram[offset]
        else:
            self.ram[a]

    fn write_byte(mut self, addr: i32, v: u8):
        let a = ((addr % 65536) + 65536) % 65536
        if self.bank != (0 as u8) and a >= BANK_WINDOW_START and a < BANK_WINDOW_END:
            let bank_num = (self.bank as i32) - 1
            let offset = bank_num * BANK_SIZE + (a - BANK_WINDOW_START)
            self.bank_ram[offset] = v
        else:
            self.ram[a] = v

    # Big-endian: most-significant byte at the lower address.
    fn read_word(self, addr: i32) -> u16:
        let hi = self.read_byte(addr) as u16
        let lo = self.read_byte(addr + 1) as u16
        (hi << 8) | lo

    fn write_word(mut self, addr: i32, v: u16):
        let hi = (v >> 8) as u8
        let lo = v as u8
        self.write_byte(addr, hi)
        self.write_byte(addr + 1, lo)
