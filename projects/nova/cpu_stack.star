# Nova-16 CPU: stack opcode handlers (PUSH/POP/PUSHF/POPF/PUSHA/POPA/ENTER/
# LEAVE, docs/nova16_instruction_reference.md) -- split out of `cpu.star`
# (todo.md P2 #5). See `cpu_data.star`'s header comment for the full
# rationale (pure code motion, no behavior change) and why this
# `import "cpu.star" as cpu` isn't circular. `self.push16`/`self.pop16`/
# `self.push8`/`self.pop8` (the actual SP-relative memory access) stay
# `cpu.star`'s own core methods -- called here exactly the same way as
# before, no different from any other core-helper call the rest of this
# opcode-handler split relies on.
import "cpu.star" as cpu

impl cpu::Cpu:
    # ── Stack ────────────────────────────────────────────────────────────

    fn op_push(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let v = self.operand_read(op1, width)
        if self.push_pop_width(op1) == 8:
            self.push8(v)
        else:
            self.push16(v)

    fn op_pop(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let mut v = 0
        if self.push_pop_width(op1) == 8:
            v = self.pop8()
        else:
            v = self.pop16()
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
        let newsp = cpu::wrap_addr(((self.p[8] as u16) as i32) - size)
        self.p[8] = Wrapping<u16>(newsp as u16)

    fn op_leave(mut self):
        self.p[8] = self.p[9]
        let v = self.pop16()
        self.p[9] = Wrapping<u16>(v as u16)

