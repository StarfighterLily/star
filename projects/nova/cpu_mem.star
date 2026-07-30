# Nova-16 CPU: bulk-memory and random-number opcode handlers (MEMCPY/MEMSET/
# MEMMOVE/MEMSWAP/MEMTEST plus RND/RNDR, docs/nova16_instruction_
# reference.md) -- split out of `cpu.star` (todo.md P2 #5). See
# `cpu_data.star`'s header comment for the full rationale (pure code motion,
# no behavior change) and why this `import "cpu.star" as cpu` isn't
# circular.
import "cpu.star" as cpu

impl cpu::Cpu:
    # ── Memory bulk ops ──────────────────────────────────────────────────

    fn op_memcpy(mut self):
        let (op1, op2, op3) = self.decode_operands(3)
        let dest = self.operand_read(op1, 16)
        let src = self.operand_read(op2, 16)
        let len = self.operand_read(op3, 16)
        let mut i = 0
        while i < len:
            let b = self.mem.read_byte(cpu::wrap_addr(src + i))
            self.mem.write_byte(cpu::wrap_addr(dest + i), b)
            i += 1

    fn op_memset(mut self):
        let (op1, op2, op3) = self.decode_operands(3)
        let dest = self.operand_read(op1, 16)
        let value = self.operand_read(op2, 16)
        let len = self.operand_read(op3, 16)
        let mut i = 0
        while i < len:
            self.mem.write_byte(cpu::wrap_addr(dest + i), value as u8)
            i += 1

    fn op_memmove(mut self):
        let (op1, op2, op3) = self.decode_operands(3)
        let dest = self.operand_read(op1, 16)
        let src = self.operand_read(op2, 16)
        let len = self.operand_read(op3, 16)
        if dest <= src:
            let mut i = 0
            while i < len:
                let b = self.mem.read_byte(cpu::wrap_addr(src + i))
                self.mem.write_byte(cpu::wrap_addr(dest + i), b)
                i += 1
        else:
            let mut i = len - 1
            while i >= 0:
                let b = self.mem.read_byte(cpu::wrap_addr(src + i))
                self.mem.write_byte(cpu::wrap_addr(dest + i), b)
                i -= 1

    fn op_memswap(mut self):
        let (op1, op2, op3) = self.decode_operands(3)
        let a1 = self.operand_read(op1, 16)
        let a2 = self.operand_read(op2, 16)
        let len = self.operand_read(op3, 16)
        let mut i = 0
        while i < len:
            let tmp = self.mem.read_byte(cpu::wrap_addr(a1 + i))
            let v2 = self.mem.read_byte(cpu::wrap_addr(a2 + i))
            self.mem.write_byte(cpu::wrap_addr(a1 + i), v2)
            self.mem.write_byte(cpu::wrap_addr(a2 + i), tmp)
            i += 1

    fn op_memtest(mut self):
        let (op1, op2, op3) = self.decode_operands(3)
        let a1 = self.operand_read(op1, 16)
        let a2 = self.operand_read(op2, 16)
        let len = self.operand_read(op3, 16)
        let mut i = 0
        let mut equal = true
        while i < len:
            if self.mem.read_byte(cpu::wrap_addr(a1 + i)) != self.mem.read_byte(cpu::wrap_addr(a2 + i)):
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
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(r, ww))

