# Nova-16 CPU: bitwise opcode handlers (AND/OR/XOR/NOT/SHL/SHR/SAR/ROL/ROR/
# RCL/RCR/BTST/BSET/BCLR/BFLIP, docs/nova16_instruction_reference.md
# 0x2E-0x3C) -- split out of `cpu.star` (todo.md P2 #5). See `cpu_data.star`'s
# header comment for the full rationale (pure code motion, no behavior
# change) and why this `import "cpu.star" as cpu` isn't circular. The
# dynamic-shift-amount opcodes (SHL/SHR/SAR/ROL/ROR/RCL/RCR) route through
# `bits.star`'s hand-rolled shift/rotate helpers exactly as they always did
# -- see that file's own header comment for why they can't just use Star's
# native `<<`/`>>` operators (different out-of-range-amount clamping
# semantics).
import "cpu.star" as cpu
import "bits.star" as bits

impl cpu::Cpu:
    # ── Bitwise ──────────────────────────────────────────────────────────

    fn op_and(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let raw = (a & b)
        self.flags.apply_logic(raw, width)
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(raw, ww))

    fn op_or(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let raw = (a | b)
        self.flags.apply_logic(raw, width)
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(raw, ww))

    fn op_xor(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let raw = (a ^ b)
        self.flags.apply_logic(raw, width)
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(raw, ww))

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
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(raw, ww))

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
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(raw, ww))

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
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(raw, ww))

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
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(raw, ww))

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
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(raw, ww))

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
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(raw, ww))

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
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(raw, ww))

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
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(bit_set(a, bitidx), ww))

    fn op_bclr(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let bitidx = (self.operand_read(op2, width)) % width
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(bit_clear(a, bitidx), ww))

    fn op_bflip(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let bitidx = (self.operand_read(op2, width)) % width
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(bit_toggle(a, bitidx), ww))

