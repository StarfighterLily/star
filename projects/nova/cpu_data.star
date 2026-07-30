# Nova-16 CPU: data-movement opcode handlers (MOV/MOVZ/MOVNZ/XCHNG/SWAP/LEA,
# docs/nova16_instruction_reference.md) -- split out of `cpu.star` (todo.md
# P2 #5) now that `impl` can cross a module boundary (see `cpu.star`'s own
# header comment / NOTES.md "Two Star compiler bugs found and fixed"). Pure
# code motion: every method here is copied verbatim from `cpu.star`'s former
# "Data movement" section, only its `bits::shr8` call (`op_swap`'s nibble
# swap) already qualified exactly as it always was -- no behavior changes.
#
# `import "cpu.star" as cpu` below is *not* circular: `cpu.star` itself never
# imports this file (or any of its `cpu_*.star` siblings) back -- Star's
# import resolver flat-out rejects that (`crate::modules::resolve`'s cycle
# guard). Instead, every one of this project's four build targets
# (`main.star`/`debugger.star`/`tests/run_bin.star`/`uart_bridge.star`)
# imports both `cpu.star` and every `cpu_*.star` split file directly, and
# `cpu.star`'s own `execute()` dispatch calls `self.op_mov()` etc. with no
# qualification at all and no import of this file -- proven to resolve fine
# regardless of which file defines the callee, since `Item::Impl` blocks are
# never mangled by file/alias (see `crate::modules::resolve`'s own doc
# comment on `Item::Impl`, keyed on the impl block's own byte span rather
# than a name, precisely so two genuinely different `impl Cpu:` blocks
# across files merge into one method set instead of colliding or requiring
# either side to know about the other).
import "cpu.star" as cpu
import "bits.star" as bits

impl cpu::Cpu:
    # ── Data movement ────────────────────────────────────────────────────

    fn op_mov(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let v = self.operand_read(op2, width)
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(v, ww))

    fn op_movz(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        if self.flags.z():
            let v = self.operand_read(op2, width)
            let ww = self.write_width_for(op1, op2)
            self.operand_write(op1, ww, self.mask_to_width(v, ww))

    fn op_movnz(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        if !self.flags.z():
            let v = self.operand_read(op2, width)
            let ww = self.write_width_for(op1, op2)
            self.operand_write(op1, ww, self.mask_to_width(v, ww))

    fn op_xchng(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        self.operand_write(op1, self.write_width_for(op1, op2), b)
        self.operand_write(op2, self.write_width_for(op2, op1), a)

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
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(addr_val, ww))

