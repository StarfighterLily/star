# Nova-16 CPU: control-flow opcode handlers (JMP/BR/BRZ/BRNZ/CALL/CALLZ/
# CALLNZ/RET/RETN/IRET/INT/LOOP/LOOPZ/WHILE, docs/nova16_instruction_
# reference.md) -- split out of `cpu.star` (todo.md P2 #5). See
# `cpu_data.star`'s header comment for the full rationale (pure code motion,
# no behavior change) and why this `import "cpu.star" as cpu` isn't
# circular.
#
# `jump_if` -- the shared helper the much larger JZ/JNZ/JO/JNO/JC/JNC/JS/JNS/
# JLE/JG/JGE/JL family (`docs/nova16_instruction_reference.md`'s other
# conditional jumps) all call -- deliberately does *not* live here. Unlike
# every opcode below, that whole family has no dedicated `op_*` method at
# all: `execute()`'s own dispatch match calls `self.jump_if(cond)` directly,
# inline, once per condition code, so `jump_if` only has one real call site
# and it's inside `cpu.star`'s own `execute()` -- it stays there as a core
# helper rather than moving here with `op_jmp`/`op_br`/`op_brz`/`op_brnz`
# (which each have a real dedicated handler and *do* belong in this file).
import "cpu.star" as cpu

impl cpu::Cpu:
    # ── Control flow ─────────────────────────────────────────────────────

    fn op_jmp(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let target = self.operand_read(op1, width)
        self.pc = Wrapping<u16>((cpu::wrap_addr(target)) as u16)

    fn op_br(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let raw = self.operand_read(op1, width)
        let offset = self.to_signed16(raw)
        self.pc = Wrapping<u16>((cpu::wrap_addr(((self.pc as u16) as i32) + offset)) as u16)

    fn op_brz(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let raw = self.operand_read(op1, width)
        if self.flags.z():
            let offset = self.to_signed16(raw)
            self.pc = Wrapping<u16>((cpu::wrap_addr(((self.pc as u16) as i32) + offset)) as u16)

    fn op_brnz(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let raw = self.operand_read(op1, width)
        if !self.flags.z():
            let offset = self.to_signed16(raw)
            self.pc = Wrapping<u16>((cpu::wrap_addr(((self.pc as u16) as i32) + offset)) as u16)

    fn op_call(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let target = self.operand_read(op1, width)
        self.push16((self.pc as u16) as i32)
        self.pc = Wrapping<u16>((cpu::wrap_addr(target)) as u16)

    fn op_callz(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let target = self.operand_read(op1, width)
        if self.flags.z():
            self.push16((self.pc as u16) as i32)
            self.pc = Wrapping<u16>((cpu::wrap_addr(target)) as u16)

    fn op_callnz(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let target = self.operand_read(op1, width)
        if !self.flags.z():
            self.push16((self.pc as u16) as i32)
            self.pc = Wrapping<u16>((cpu::wrap_addr(target)) as u16)

    fn op_ret(mut self):
        let v = self.pop16()
        self.pc = Wrapping<u16>((cpu::wrap_addr(v)) as u16)

    fn op_retn(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let result = self.operand_read(op1, width)
        self.r[0] = Wrapping<u8>(result as u8)
        self.p[0] = Wrapping<u16>(result as u16)
        self.flags.apply_arith(result, 0, 0, 16, false, false)
        let v = self.pop16()
        self.pc = Wrapping<u16>((cpu::wrap_addr(v)) as u16)

    fn op_iret(mut self):
        let pcv = self.pop16()
        let flg = self.pop16()
        self.flags.unpack(flg as u16)
        self.pc = Wrapping<u16>((cpu::wrap_addr(pcv)) as u16)

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
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(newval, ww))
        if newval != 0:
            let target = self.operand_read(op2, self.operand_width(op2))
            self.pc = Wrapping<u16>((cpu::wrap_addr(target)) as u16)

    fn op_loopz(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let newval = self.mask_to_width(a - 1, width)
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(newval, ww))
        if newval != 0 and self.flags.z():
            let target = self.operand_read(op2, self.operand_width(op2))
            self.pc = Wrapping<u16>((cpu::wrap_addr(target)) as u16)

    fn op_while(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        self.flags.apply_arith(a, 0, 0, width, false, false)

