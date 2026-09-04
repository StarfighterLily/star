# Nova-16 CPU: arithmetic and BCD opcode handlers (ADD/ADC/SUB/SBC/CMP/MUL/
# MULH/DIV/DIVH/MOD/INC/DEC/NEG/ABS/MIN/MAX/CLZ/CTZ/POPCNT plus the BCD family
# BCDA/BCDS/BCDCMP/BCD2BIN/BIN2BCD/BCDADD/BCDSUB,
# docs/nova16_instruction_reference.md 0x07-0x2D / 0x4B-0x54) -- split out of
# `cpu.star` (todo.md P2 #5). See `cpu_data.star`'s header comment for the
# full rationale (pure code motion, no behavior change) and why this
# `import "cpu.star" as cpu` isn't circular. `CLZ`/`CTZ`/`POPCNT` route
# through `bits.star`'s bit-counting helpers exactly as they always did.
import "cpu.star" as cpu
import "bits.star" as bits

impl cpu::Cpu:
    # ── Arithmetic ───────────────────────────────────────────────────────

    fn op_add(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let raw = a + b
        self.flags.apply_arith(raw, a, b, width, false, false)
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(raw, ww))

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
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(raw, ww))

    fn op_sub(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let raw = a - b
        self.flags.apply_arith(raw, a, b, width, true, false)
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(raw, ww))

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
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(raw, ww))

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
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(raw, ww))

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
            hi = product / (65_536 as i64)
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(hi as i32, ww))

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
            let ww = self.write_width_for(op1, op2)
            self.operand_write(op1, ww, self.mask_to_width(raw, ww))
            # DIV also deposits the remainder in P3 (register code 0xF4), exactly
            # like core/exec_handlers.py::_div's `cpu.regfile.set('P', 3,
            # remainder & 0xFFFF)`.  The reference writes the destination FIRST
            # and then P3, so even `DIV P3, src` ends with P3 == remainder; this
            # ordering is preserved here.  Without this, any program reading P3
            # after DIV saw stale/zero data -- in particular Astrid's unsigned
            # ->string conversion (`MOV digit, P3` per loop) rendered 65476 as
            # "00000" on the compiled emulator while Python showed "65476".
            self.set_reg_value(0xF4 as u8, a % b)

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
                shifted = ai * (65_536 as i64)
            let q = shifted / bi
            let ww = self.write_width_for(op1, op2)
            self.operand_write(op1, ww, self.mask_to_width(q as i32, ww))

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
            let ww = self.write_width_for(op1, op2)
            self.operand_write(op1, ww, self.mask_to_width(raw, ww))

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
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(raw, ww))

    fn op_max(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let mut raw = a
        if b > a:
            raw = b
        self.flags.apply_arith(raw, a, b, width, false, false)
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(raw, ww))

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

    # ── BCD operations (docs/nova16_instruction_reference.md 0x4B-0x54) ──
    # Ported from core/exec_handlers.py's _sed/_cld/_cla/_bcda/.../_bcdsub.
    # A BCD byte packs two decimal digits per byte (one per nibble), but
    # BCDA/BCDS/BCDCMP/BCDADD/BCDSUB do NOT read at a fixed 8-bit width --
    # an earlier draft of this port assumed they did (matching only
    # `_write_result`'s unconditional `result & 0xFF` value mask) and
    # hardcoded `operand_read(op, 8)` for both operands. Confirmed wrong
    # against the live reference over MCP: `_resolve_single_operand` applies
    # the same "8 if op1 is an R register, else 16" rule to BCD operands as
    # every other instruction (`BCDA P0, P1` with P0=0x1234, P1=0x0006 reads
    # the *full* 16-bit P-register values -- sum 0x123A, not 0x3A -- so the
    # reference's carry flag comes out set where an 8-bit-only read would
    # have left it clear). Only the final *value* written back is always
    # masked to a byte (`result & 0xFF`, matching `_write_result`'s mask);
    # the read width (and therefore the carry/borrow check, which happens
    # against the unmasked `raw`) follows the usual destination-kind rule
    # via `operand_width(op1)` like every other two-operand arithmetic op
    # here. SED/CLD/CLA are handled directly in `execute` (no operand at
    # all, same as CLI/STI at 0x03/0x04) rather than as their own `op_*`
    # methods.
    #
    # BCDA/BCDS are ported bug-for-bug: the "add/subtract 1 when the A
    # flag is set but D (decimal mode) is *not*" step in `_bcda`/`_bcds`
    # looks backwards for a carry-in (you'd expect it gated on D being
    # set, or not gated on D at all) but that's what the reference
    # actually does, confirmed against the live reference over MCP -- see
    # NOTES.md.
    fn op_bcda(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let mut raw = a + b
        if !self.flags.d() and self.flags.a():
            raw += 1
        if self.flags.d():
            if (raw & 0x0F) > 9:
                raw += 0x06
            if ((raw >> 4) & 0x0F) > 9:
                raw += 0x60
        # `carry = result > 0x99` is checked *before* `result &= 0xFF` in
        # the reference (`core/exec_handlers.py::_bcda`, statement order:
        # `carry = result > 0x99` on the line directly above `result &=
        # 0xFF`) -- an earlier draft of this port had this backwards
        # (checking the *masked* byte against 0x99, which can only ever be
        # 0-255 and so only fires for 154-255) and documented the bug as
        # if it were the reference's own behavior. Confirmed wrong against
        # the live reference over MCP: `BCDA R0, R1` with R0=R1=0x89 (raw
        # sum 0x112/274, masked result 0x12) comes back with C set, which
        # is only possible if the carry check runs against the *unmasked*
        # 274, not the masked 18. Fixed to check `raw` before masking.
        let carry = raw > 0x99
        let result = raw & 0xFF
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, result)
        self.flags.apply_bcd(result, carry)

    fn op_bcds(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let mut raw = a - b
        if !self.flags.d() and self.flags.a():
            raw -= 1
        if self.flags.d():
            if (raw & 0x0F) > 9:
                raw -= 0x06
            if ((raw >> 4) & 0x0F) > 9:
                raw -= 0x60
        # `borrow = result < 0` is likewise checked *before* `result &=
        # 0xFF` in the reference. An earlier draft of this port had this
        # backwards too (checking the masked byte, which Star's and
        # Python's bitwise `&` both always reduce to 0-255 regardless of
        # sign, so `< 0` could never be true) and documented BCDS's borrow
        # flag as "always cleared" -- confirmed wrong against the live
        # reference over MCP: `BCDS R0, R1` with R0=0x15, R1=0x42 (a genuine
        # borrow, op1 < op2; raw diff -45) comes back with C set. Fixed to
        # check `raw` before masking, same as BCDA above.
        let carry = raw < 0
        let result = raw & 0xFF
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, result)
        self.flags.apply_bcd(result, carry)

    # Compares op1/op2 as plain numbers (no decimal-digit adjustment at
    # all), setting Z on equality and, when op1 < op2, both S and C --
    # ported exactly from `_bcdcmp`, which never touches S/C/Z the usual
    # "sign of the result" way (e.g. S is 0 whenever op1 >= op2, even
    # though op1 - op2 could still be read as "negative" if you squint at
    # it as an 8-bit result -- this op just doesn't compute it that way).
    fn op_bcdcmp(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        if a == b:
            self.flags.set_z(true)
            self.flags.set_s(false)
            self.flags.set_c(false)
        elif a < b:
            self.flags.set_z(false)
            self.flags.set_s(true)
            self.flags.set_c(true)
        else:
            self.flags.set_z(false)
            self.flags.set_s(false)
            self.flags.set_c(false)
        self.flags.set_o(false)

    # BCD2BIN/BIN2BCD convert op1 in place (same operand read as source and
    # written as destination, like INC/DEC/NEG). Unlike BCDA/BCDS/BCDCMP/
    # BCDADD/BCDSUB above, these use the *destination's own* width (8 or
    # 16), matching this port's usual "infer width from the destination
    # register's real kind" rule -- the reference always treats the value
    # as 16-bit (4 nibbles) for both the digit walk and its flag
    # computation, but since a valid packed-BCD result never exceeds 9999
    # (well under the 15-bit sign threshold either width would check), an
    # 8-bit destination register never observably differs: its top two
    # nibbles are always 0, so this port's destination-driven width is
    # "genuine machine architecture" here the same way the deviation
    # in "Operand width is inferred..." above already reasoned -- confirmed
    # with a dedicated equivalence check, see NOTES.md.
    fn op_bcd2bin(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let bcd = self.operand_read(op1, width)
        let mut valid = true
        let mut i = 0
        while i < 4:
            let digit = (bcd >> (i * 4)) & 0x0F
            if digit > 9:
                valid = false
            i += 1
        let mut result = bcd
        if valid:
            result = 0
            let mut pow10 = 1
            let mut j = 0
            while j < 4:
                let digit = (bcd >> (j * 4)) & 0x0F
                result += digit * pow10
                pow10 *= 10
                j += 1
        let masked = self.mask_to_width(result, width)
        self.operand_write(op1, width, masked)
        self.flags.apply_logic(masked, width)

    fn op_bin2bcd(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let bin_val = self.operand_read(op1, width)
        let mut result = 0
        let mut pow10 = 1
        let mut i = 0
        while i < 4:
            let digit = (bin_val / pow10) % 10
            result = result | (digit << (i * 4))
            pow10 *= 10
            i += 1
        let masked = self.mask_to_width(result, width)
        self.operand_write(op1, width, masked)
        self.flags.apply_logic(masked, width)

    # BCDADD/BCDSUB: like BCDA/BCDS but without the A-flag carry-in step
    # (no "carry with"/"borrow with" -- these are the plain, non-chaining
    # BCD add/subtract).
    fn op_bcdadd(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let mut raw = a + b
        if self.flags.d():
            if (raw & 0x0F) > 9:
                raw += 0x06
            if ((raw >> 4) & 0x0F) > 9:
                raw += 0x60
        # Carry checked before masking, same fix as op_bcda above.
        let carry = raw > 0x99
        let result = raw & 0xFF
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, result)
        self.flags.apply_bcd(result, carry)

    fn op_bcdsub(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let mut raw = a - b
        if self.flags.d():
            if (raw & 0x0F) > 9:
                raw -= 0x06
            if ((raw >> 4) & 0x0F) > 9:
                raw -= 0x60
        # Borrow checked before masking, same fix as op_bcds above.
        let carry = raw < 0
        let result = raw & 0xFF
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, result)
        self.flags.apply_bcd(result, carry)

