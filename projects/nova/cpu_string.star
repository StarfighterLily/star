# Nova-16 CPU: string-library and integer/string-conversion opcode handlers
# (STRCPY/STRCAT/STRCMP/STRLEN/STRUPR/STRLWR/STRREV/STRFIND/STRFINDI plus
# ITOB/BTOI/ITOS/STOI, docs/nova16_instruction_reference.md 0x71-0x7B /
# 0x83-0x86) -- split out of `cpu.star` (todo.md P2 #5). See
# `cpu_data.star`'s header comment for the full rationale (pure code motion,
# no behavior change) and why this `import "cpu.star" as cpu` isn't
# circular. `cpu::wrap_addr`/`cpu::ascii_upper` are `cpu.star`'s own
# module-level free functions -- qualified here exactly like
# `cpu_math.star`'s `cpu::PI`/`cpu::floor_div16` (a bare top-level name from
# another file needs its `alias::` prefix, since only `impl` blocks skip
# name-mangling).
import "cpu.star" as cpu

impl cpu::Cpu:
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
            let c = self.mem.read_byte(cpu::wrap_addr(src))
            self.mem.write_byte(cpu::wrap_addr(dest), c)
            if c == (0 as u8):
                going = false
            else:
                src = cpu::wrap_addr(src + 1)
                dest = cpu::wrap_addr(dest + 1)

    fn op_strcat(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let dest0 = self.operand_read(op1, 16)
        let src0 = self.operand_read(op2, 16)
        let mut dest = dest0
        while self.mem.read_byte(cpu::wrap_addr(dest)) != (0 as u8):
            dest = cpu::wrap_addr(dest + 1)
        let mut src = src0
        let mut going = true
        while going:
            let c = self.mem.read_byte(cpu::wrap_addr(src))
            self.mem.write_byte(cpu::wrap_addr(dest), c)
            if c == (0 as u8):
                going = false
            else:
                src = cpu::wrap_addr(src + 1)
                dest = cpu::wrap_addr(dest + 1)

    fn op_strcmp(mut self):
        let (op1, op2, op3) = self.decode_operands(3)
        let str1 = self.operand_read(op1, 16)
        let str2 = self.operand_read(op2, 16)
        let length = self.operand_read(op3, 16)
        let mut result = 0
        let mut i = 0
        let mut going = true
        while going and i < length:
            let c1 = self.mem.read_byte(cpu::wrap_addr(str1 + i))
            let c2 = self.mem.read_byte(cpu::wrap_addr(str2 + i))
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
        while self.mem.read_byte(cpu::wrap_addr(src + length)) != (0 as u8):
            length = cpu::wrap_addr(length + 1)
        let masked = self.mask_to_width(length, 16)
        self.r[0] = Wrapping<u8>(masked as u8)
        self.flags.apply_arith(masked, 0, 0, 16, false, false)

    fn op_strupr(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let mut addr = self.operand_read(op1, 16)
        let mut going = true
        while going:
            let c = self.mem.read_byte(cpu::wrap_addr(addr))
            if c == (0 as u8):
                going = false
            else:
                let mut cv = c as i32
                if cv >= 97 and cv <= 122:
                    cv -= 32
                self.mem.write_byte(cpu::wrap_addr(addr), cv as u8)
                addr = cpu::wrap_addr(addr + 1)

    fn op_strlwr(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let mut addr = self.operand_read(op1, 16)
        let mut going = true
        while going:
            let c = self.mem.read_byte(cpu::wrap_addr(addr))
            if c == (0 as u8):
                going = false
            else:
                let mut cv = c as i32
                if cv >= 65 and cv <= 90:
                    cv += 32
                self.mem.write_byte(cpu::wrap_addr(addr), cv as u8)
                addr = cpu::wrap_addr(addr + 1)

    fn op_strrev(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let src = self.operand_read(op1, 16)
        let mut length = 0
        while self.mem.read_byte(cpu::wrap_addr(src + length)) != (0 as u8):
            length += 1
        let mut i = 0
        while i < length / 2:
            let left = cpu::wrap_addr(src + i)
            let right = cpu::wrap_addr(src + length - 1 - i)
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
            let hc = self.mem.read_byte(cpu::wrap_addr(haystack + haystack_pos))
            if hc == (0 as u8):
                scanning = false
            else:
                let mut needle_pos = 0
                let mut is_match = true
                let mut checking = true
                while checking:
                    let nc = self.mem.read_byte(cpu::wrap_addr(needle + needle_pos))
                    if nc == (0 as u8):
                        checking = false
                    else:
                        let h = self.mem.read_byte(cpu::wrap_addr(haystack + haystack_pos + needle_pos))
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
            let hc = self.mem.read_byte(cpu::wrap_addr(haystack + haystack_pos))
            if hc == (0 as u8):
                scanning = false
            else:
                let mut needle_pos = 0
                let mut is_match = true
                let mut checking = true
                while checking:
                    let nc = self.mem.read_byte(cpu::wrap_addr(needle + needle_pos))
                    if nc == (0 as u8):
                        checking = false
                    else:
                        let h = self.mem.read_byte(cpu::wrap_addr(haystack + haystack_pos + needle_pos))
                        if cpu::ascii_upper(h as i32) != cpu::ascii_upper(nc as i32):
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
            self.mem.write_byte(cpu::wrap_addr(dest + i), c)
            i += 1
        self.mem.write_byte(cpu::wrap_addr(dest + count), 0 as u8)

    fn op_btoi(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let src = self.operand_read(op2, 16)
        let mut result = 0
        let mut i = 0
        let mut going = true
        while going:
            let c = (self.mem.read_byte(cpu::wrap_addr(src + i))) as i32
            if c == 48 or c == 49:
                result = result * 2 + (c - 48)
                i += 1
            else:
                going = false
        let masked = self.mask_to_width(result, 16)
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(result, ww))
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
            self.mem.write_byte(cpu::wrap_addr(buffer_addr + pos), 45 as u8)
            pos += 1
        let mut i = 0
        while i < count:
            let c = digits[count - 1 - i]
            self.mem.write_byte(cpu::wrap_addr(buffer_addr + pos), c)
            pos += 1
            i += 1
        self.mem.write_byte(cpu::wrap_addr(buffer_addr + pos), 0 as u8)
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(buffer_addr, ww))
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
        while self.mem.read_byte(cpu::wrap_addr(src + len)) != (0 as u8):
            len += 1
        let mut pos = 0
        let mut negative = false
        if len > 0:
            let first = (self.mem.read_byte(cpu::wrap_addr(src))) as i32
            if first == 45:
                negative = true
                pos = 1
            elif first == 43:
                pos = 1
        let mut result = 0
        let mut valid = pos < len
        let mut i = pos
        while valid and i < len:
            let c = (self.mem.read_byte(cpu::wrap_addr(src + i))) as i32
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
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(final_result, ww))
        self.flags.apply_arith(masked, 0, 0, 16, false, false)

