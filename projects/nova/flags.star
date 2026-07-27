# Nova-16's 12-bit flags register (docs/CPU Specification.md). Bit order
# confirmed against the upstream reference's core/flags.py (the docs and the
# code agree here):
#   0 T  trap (single-step)      6  C  carry / borrow
#   1 S  sign                    7  Z  zero
#   2 O  overflow                8  P  parity (even, low byte)
#   3 B  break                   9  H  direction (documented, never set by the CPU)
#   4 D  decimal (BCD mode)      10 A  BCD adjust carry
#   5 I  interrupt enable        11 E  "hacker" flag, user-owned, CPU never touches it
#
# Flag *values* (Z/S/P/C/O) are genuine machine architecture and are ported
# faithfully from core/flags.py's `set_from_operation` (read directly, not
# guessed from the higher-level docs, which don't spell out the CMP-vs-SUB
# carry distinction below). What's deliberately NOT ported: the 256-entry
# parity lookup table (`core/flags.py::PARITY_TABLE`) -- a Python-speed
# micro-optimization, see NOTES.md -- replaced here with `bits::parity8`'s
# plain popcount.

import "bits.star" as bits

const T_BIT: i32 = 0
const S_BIT: i32 = 1
const O_BIT: i32 = 2
const B_BIT: i32 = 3
const D_BIT: i32 = 4
const I_BIT: i32 = 5
const C_BIT: i32 = 6
const Z_BIT: i32 = 7
const P_BIT: i32 = 8
const H_BIT: i32 = 9
const A_BIT: i32 = 10
const E_BIT: i32 = 11

struct StatusFlags:
    mut bits: BitField<16>

fn new_flags() -> StatusFlags:
    StatusFlags(bits = BitField<16>(0))

impl StatusFlags:
    fn get(self, i: i32) -> bool:
        bit_get(self.bits, i)

    fn set_bit(mut self, i: i32, v: bool):
        if v:
            self.bits = bit_set(self.bits, i)
        else:
            self.bits = bit_clear(self.bits, i)

    fn t(self) -> bool:
        self.get(T_BIT)
    fn s(self) -> bool:
        self.get(S_BIT)
    fn o(self) -> bool:
        self.get(O_BIT)
    fn b(self) -> bool:
        self.get(B_BIT)
    fn d(self) -> bool:
        self.get(D_BIT)
    fn i(self) -> bool:
        self.get(I_BIT)
    fn c(self) -> bool:
        self.get(C_BIT)
    fn z(self) -> bool:
        self.get(Z_BIT)
    fn p(self) -> bool:
        self.get(P_BIT)
    fn h(self) -> bool:
        self.get(H_BIT)
    fn a(self) -> bool:
        self.get(A_BIT)
    fn e(self) -> bool:
        self.get(E_BIT)

    fn set_t(mut self, v: bool):
        self.set_bit(T_BIT, v)
    fn set_s(mut self, v: bool):
        self.set_bit(S_BIT, v)
    fn set_o(mut self, v: bool):
        self.set_bit(O_BIT, v)
    fn set_b(mut self, v: bool):
        self.set_bit(B_BIT, v)
    fn set_d(mut self, v: bool):
        self.set_bit(D_BIT, v)
    fn set_i(mut self, v: bool):
        self.set_bit(I_BIT, v)
    fn set_c(mut self, v: bool):
        self.set_bit(C_BIT, v)
    fn set_z(mut self, v: bool):
        self.set_bit(Z_BIT, v)
    fn set_p(mut self, v: bool):
        self.set_bit(P_BIT, v)
    fn set_a(mut self, v: bool):
        self.set_bit(A_BIT, v)

    fn pack(self) -> u16:
        self.bits as u16

    fn unpack(mut self, v: u16):
        self.bits = v as BitField<16>

    # Unified flag-setting for arithmetic ops (ADD/ADC/SUB/SBC/CMP/INC/DEC/...).
    # `result`/`op1`/`op2` are the *raw*, unmasked values (op2 defaults to 0
    # for a 1-operand op like INC/NEG): e.g. ADD passes result = op1 + op2
    # with no truncation, so overflow past `width` bits is still visible to
    # the carry/overflow computation below. `is_subtraction` covers SUB/SBC/
    # CMP/DEC; `is_cmp` narrows further to just CMP (whose carry rule is
    # simpler: a plain borrow check, not "did it leave the width's range").
    fn apply_arith(mut self, result: i32, op1: i32, op2: i32, width: i32, is_subtraction: bool, is_cmp: bool):
        let sign_idx = if width == 8: 7 else: 15
        let mask = if width == 8: 255 else: 65535

        let signs_differ = bit_get(bit_xor(op1, op2), sign_idx)
        let result_sign_flip = bit_get(bit_xor(op1, result), sign_idx)
        let overflow = if is_cmp or is_subtraction:
            signs_differ and result_sign_flip
        else:
            (!signs_differ) and result_sign_flip

        let masked = if width == 8: (result as u8) as i32 else: (result as u16) as i32

        self.set_z(masked == 0)
        self.set_s(bit_get(masked, sign_idx))
        self.set_p(bits::parity8(masked as u8))
        if is_cmp:
            self.set_c(result < 0)
        else:
            self.set_c(result > mask or result < 0)
        self.set_o(overflow)

    # Rotate-through-carry (RCL/RCR): Z/S/P from the result same as any
    # logic op, but C is the bit that rotated out (supplied by the caller,
    # which already computed it alongside the rotated value in bits.star),
    # not unconditionally cleared like every other logic op.
    fn apply_rotate(mut self, result: i32, width: i32, carry_out: bool):
        let sign_idx = if width == 8: 7 else: 15
        let masked = if width == 8: (result as u8) as i32 else: (result as u16) as i32
        self.set_z(masked == 0)
        self.set_s(bit_get(masked, sign_idx))
        self.set_p(bits::parity8(masked as u8))
        self.set_c(carry_out)

    # Logic ops (AND/OR/XOR/NOT/SHL/SHR/ROL/ROR/...): Z/S/P from the result,
    # carry and overflow unconditionally cleared (core/exec.py's
    # `_flags_logic_8bit`/`_16bit` -- no borrow/overflow concept applies).
    fn apply_logic(mut self, result: i32, width: i32):
        let sign_idx = if width == 8: 7 else: 15
        let masked = if width == 8: (result as u8) as i32 else: (result as u16) as i32
        self.set_z(masked == 0)
        self.set_s(bit_get(masked, sign_idx))
        self.set_p(bits::parity8(masked as u8))
        self.set_c(false)
        self.set_o(false)
