# Nova-16 disassembler -- decodes a compiled `.bin` (see loader.star) back
# into readable Nova-16 assembly text. Named in NOTES.md's "Ideas for future
# work" since the binary loader round and now picked up for real: an actual
# disassembler, matching a piece of the upstream Python toolchain's own
# tooling (`nova_disassembler.py`) that this project's own versioning gate
# (readme.md's "Versioning" section, "tooling to match Python reference")
# names as one of the still-open, concrete gate components.
#
# Deliberately independent of `cpu.star`/`Cpu`: disassembly is a pure,
# static byte-stream decode (opcode -> mnemonic/operand-count, mode byte ->
# addressing modes, no register *values* or machine state involved at all),
# so this file imports only `bits.star` (for `sign_extend8`) and needs no
# `Cpu`, no `Memory`/`Screen`/`Uart`/`sound.star`, and -- unlike every other
# Nova build target in this project -- links with **no SDL2 dependency**
# (`sound.star`'s audio builtins are the reason `tests/run_bin.star`/
# `main.star`/`uart_bridge.star` all need `-l SDL2`; this tool never touches
# that import chain at all). Build as its own standalone executable:
#   star build projects/nova/disasm.star -o projects/nova/disasm.exe
#
# Usage: disasm.exe <path/to/program.bin> [start_addr] [length]
# With no `start_addr`/`length`, disassembles the whole file starting at the
# `.org` sidecar's first segment address if one exists (mirrors loader.star's
# "first segment sets entry point" convention for consistent addresses in
# the printed output), or address 0 if there's no `.org` sidecar.
#
# Opcode mnemonic/operand-count table below: mechanically cross-checked
# `docs/nova16_instruction_reference.md`'s own opcode table against
# `cpu.star`'s *actual* `decode_operands(N)` call sites, opcode by opcode,
# rather than trusting the doc outright -- this project's own established
# precedent (NOTES.md's "Status: this port now supersedes the Python
# reference" / the PUSH-POP and SPRITE_SYSTEM.md staleness findings) is that
# a doc can silently drift from the code it describes, and a disassembler
# that decoded operand counts wrong would misparse every following
# instruction in the stream, not just the one opcode. That cross-check
# turned up **ten real operand-count errors in the doc itself**, now fixed
# there directly (see NOTES.md): SFLIP (doc said 2, actually 1), KEYCLEAR/
# SED/CLD/CLA (doc said 1, actually 0 -- all four are handled with no operand
# decode at all), and BCDA/BCDS/BCDCMP/BCDADD/BCDSUB (doc said 1, actually 2
# -- confirmed against `op_bcda`/etc.'s own `decode_operands(2)` calls,
# consistent with NOTES.md's BCD section already showing `BCDA P0, P1` as a
# real two-operand example). Wherever `cpu.star` has a real handler, that
# handler's own `decode_operands` call is what's encoded below; the doc is
# only trusted for opcodes with no handler at all (hardware debugging,
# STREXT/STREXTI/MEMCMP -- see NOTES.md "What's not implemented") since
# there's no running code to check those against -- each is commented below
# as doc-only/unverified. SMIX/SECHO/SREVERB/SFILTER used to be in that same
# doc-only bucket; `todo.md` P2 #4 gave them real `cpu.star` handlers, so
# they're now verified like everything else.
#
# Two same-byte aliases, confirmed intentional (not bugs) by reading the
# Python reference's own handlers directly rather than assuming: `INTGR`
# (0x6C) and `TRUNC` (0x6A) both dispatch to `cpu.star`'s `op_trunc` --
# `core/exec_handlers.py::_intgr`'s own docstring says "alias of TRUNC" and
# its body is byte-for-byte identical to `_trunc`'s. `SAL` (0x91) and `SHL`
# (0x14) both dispatch to `op_shl` the same way -- `_sal`'s own body is
# `return _shl(cpu, values)`. Both opcodes still get their own correct
# mnemonic in the table below (disassembly is about the byte encoding, not
# which handler function happens to implement it), so this has no effect on
# the table itself -- noted here so a future reader who spots the shared
# handler in `cpu.star` doesn't mistake it for a missing-opcode bug.

import "bits.star" as bits

extern "C" fn atoi(s: str) -> i32
extern "C" fn strtol(s: str, endptr: ptr, base: i32) -> i32

# `hex_digit`/`hex_byte`/`hex_word`/`dec_str`/`format_offset` all build their
# result with `concat()`, never an f-string, and deliberately never call each
# other from *inside* an f-string's `{...}` interpolation either (see every
# call site below in `reg_name`/`format_operand`) -- a genuine Star compiler
# bug, found while writing this file: a function whose own body materializes
# its return value via an f-string, when called from *inside* another
# f-string's interpolation, silently corrupted the outer string (confirmed
# with a minimal repro: `hex_word(0x1234)` came back `"444"` instead of
# `"1234"` once `hex_byte` was implemented via a nested
# `f"{hex_digit(..)}{hex_digit(..)}"`; switching every layer to `concat()`
# instead of nesting f-strings fixed it immediately). Root-caused and fixed
# at the compiler level since (`todo.md` P1 #1, and NOTES.md's "A related
# runtime bug, since fixed" section) -- a `str`-typed f-string hole's value
# used to be released before the `snprintf` that reads it, so a later hole's
# own allocation could reuse and corrupt it first. This file's helpers are
# left exactly as they were (routing around the bug still works fine and
# costs nothing), not reverted to nesting f-strings again just to prove the
# fix -- the one related bug this same investigation *did* find and fix at
# the time (an untagged `FStr` codegen return value breaking
# `emit_trailing_if_value`) is unaffected either way.
fn hex_digit(n: i32) -> str:
    if n < 10:
        chr(48 + n)
    else:
        chr(65 + (n - 10))

fn hex_byte(v: i32) -> str:
    let b = v & 0xFF
    concat(hex_digit((b / 16) % 16), hex_digit(b % 16))

fn hex_word(v: i32) -> str:
    let w = v & 0xFFFF
    concat(hex_byte((w / 256) % 256), hex_byte(w % 256))

fn dec_str(v: i32) -> str:
    if v == 0:
        "0"
    else:
        let mut n = v
        let mut s = ""
        while n > 0:
            s = concat(hex_digit(n % 10), s)
            n = n / 10
        s

# Formats a signed indexed-addressing offset as `+N`/`-N`, matching
# `docs/Operand prefix system.md`'s own `[P2 + 8]`-style examples.
fn format_offset(off: i32) -> str:
    if off < 0:
        concat("-", dec_str(0 - off))
    else:
        concat("+", dec_str(off))

# Register-code -> display name, mirroring `cpu.star::get_reg_value`'s own
# match exactly (the single source of truth per NOTES.md "One flat
# register-code address space" -- every register, general-purpose or
# special, is reached through this same 8-bit code whether it appears as a
# direct register operand or as the base register of `[REG]`/`[REG+off]`
# indexed addressing). Cross-checked against
# `docs/nova16_instruction_reference.md`'s own "Special Registers" section
# (which does cover the full 0xC2-0xFE range, including the `P0:`-`P9:`/
# `:P0`-`:P9` byte-half codes -- an early pass over this file suspected a gap
# there and was wrong; a stricter `grep` pattern that happened to exclude the
# `:`-containing mnemonics was the actual cause, not a real doc omission) and
# matches exactly; still sourced from `cpu.star` directly here rather than
# transcribed from the doc, consistent with this file's general "the code is
# the source of truth" stance for everything operand-count-related above.
fn reg_name(code: u8) -> str:
    match code as i32:
        0xC2 -> "BANK"
        0xC3 -> "C0"
        0xC4 -> "C1"
        0xC5 -> "MX"
        0xC6 -> "MY"
        0xC7 -> "MB"
        0xC8 -> "VC"
        0xC9 -> "P0:"
        0xCA -> "P1:"
        0xCB -> "P2:"
        0xCC -> "P3:"
        0xCD -> "P4:"
        0xCE -> "P5:"
        0xCF -> "P6:"
        0xD0 -> "P7:"
        0xD1 -> "P8:"
        0xD2 -> "P9:"
        0xD3 -> ":P0"
        0xD4 -> ":P1"
        0xD5 -> ":P2"
        0xD6 -> ":P3"
        0xD7 -> ":P4"
        0xD8 -> ":P5"
        0xD9 -> ":P6"
        0xDA -> ":P7"
        0xDB -> ":P8"
        0xDC -> ":P9"
        0xDD -> "SA"
        0xDE -> "SF"
        0xDF -> "SV"
        0xE0 -> "SW"
        0xE1 -> "VM"
        0xE2 -> "VL"
        0xE3 -> "TT"
        0xE4 -> "TM"
        0xE5 -> "TC"
        0xE6 -> "TS"
        0xE7 -> "R0"
        0xE8 -> "R1"
        0xE9 -> "R2"
        0xEA -> "R3"
        0xEB -> "R4"
        0xEC -> "R5"
        0xED -> "R6"
        0xEE -> "R7"
        0xEF -> "R8"
        0xF0 -> "R9"
        0xF1 -> "P0"
        0xF2 -> "P1"
        0xF3 -> "P2"
        0xF4 -> "P3"
        0xF5 -> "P4"
        0xF6 -> "P5"
        0xF7 -> "P6"
        0xF8 -> "P7"
        0xF9 -> "P8"
        0xFA -> "P9"
        0xFB -> "SP"
        0xFC -> "FP"
        0xFD -> "VX"
        0xFE -> "VY"
        _ -> concat("0x", hex_byte(code as i32))

# Opcode -> (mnemonic, operand count, verified-against-a-real-handler).
# `verified=false` entries (hardware debugging, STREXT/STREXTI/MEMCMP) have
# no `cpu.star` handler to cross-check at all -- their operand count is the
# doc's own claim, unverified, matching NOTES.md's own "What's not
# implemented" list. SMIX/SECHO/SREVERB/SFILTER (0x7F/0x80/0x81/0x82) *are*
# verified now (`todo.md` P2 #4, `cpu_sound.star::op_smix`/`op_secho`/
# `op_sreverb`/`op_sfilter`) -- their operand counts were always right (the
# doc happened to match `cpu.star`'s own `decode_operands` calls once those
# existed), only `verified` itself needed flipping.
fn opcode_info(op: u8) -> (str, i32, bool):
    match op as i32:
        0x00 -> ("HLT", 0, true)
        0xFF -> ("NOP", 0, true)
        0x01 -> ("RET", 0, true)
        0x02 -> ("IRET", 0, true)
        0x03 -> ("CLI", 0, true)
        0x04 -> ("STI", 0, true)
        0x06 -> ("MOV", 2, true)
        0x94 -> ("SWAP", 1, true)
        0x95 -> ("XCHNG", 2, true)
        0x96 -> ("MOVZ", 2, true)
        0x97 -> ("MOVNZ", 2, true)
        0x98 -> ("LEA", 2, true)
        0x07 -> ("ADD", 2, true)
        0x08 -> ("SUB", 2, true)
        0x09 -> ("MUL", 2, true)
        0x0A -> ("DIV", 2, true)
        0x0B -> ("INC", 1, true)
        0x0C -> ("DEC", 1, true)
        0x0D -> ("MOD", 2, true)
        0x0E -> ("NEG", 1, true)
        0x0F -> ("ABS", 1, true)
        0x87 -> ("ADC", 2, true)
        0xAC -> ("FMUL", 2, true)
        0xAD -> ("FDIV", 2, true)
        0xAE -> ("FTOI", 1, true)
        0xAF -> ("ITOF", 1, true)
        0x88 -> ("SBC", 2, true)
        0x89 -> ("MULH", 2, true)
        0x8A -> ("DIVH", 2, true)
        0x8B -> ("MIN", 2, true)
        0x8C -> ("MAX", 2, true)
        0x8D -> ("CLZ", 1, true)
        0x8E -> ("CTZ", 1, true)
        0x8F -> ("POPCNT", 1, true)
        0xA2 -> ("SERIN", 1, true)
        0xA3 -> ("SEROUT", 1, true)
        0xA4 -> ("SERSTAT", 1, true)
        0xA5 -> ("SERCTRL", 1, true)
        0xA6 -> ("SETBP", 2, false)
        0xA7 -> ("CLRBP", 1, false)
        0xA8 -> ("ENABRK", 0, false)
        0xA9 -> ("DISBRK", 0, false)
        0xAA -> ("ENATRAP", 0, false)
        0xAB -> ("DISATRAP", 0, false)
        0xB0 -> ("LSWAP", 1, true)
        0xB1 -> ("LMOVE", 1, true)
        0xB2 -> ("LCOPY", 1, true)
        0xB3 -> ("MOUSECTRL", 1, true)
        0xB4 -> ("SERFSTAT", 1, true)
        0x10 -> ("AND", 2, true)
        0x11 -> ("OR", 2, true)
        0x12 -> ("XOR", 2, true)
        0x13 -> ("NOT", 1, true)
        0x14 -> ("SHL", 2, true)
        0x15 -> ("SHR", 2, true)
        0x16 -> ("ROL", 2, true)
        0x17 -> ("ROR", 2, true)
        0x90 -> ("SAR", 2, true)
        0x91 -> ("SAL", 2, true)
        0x92 -> ("RCL", 2, true)
        0x93 -> ("RCR", 2, true)
        0x6D -> ("BTST", 2, true)
        0x6E -> ("BSET", 2, true)
        0x6F -> ("BCLR", 2, true)
        0x70 -> ("BFLIP", 2, true)
        0x18 -> ("PUSH", 1, true)
        0x19 -> ("POP", 1, true)
        0x1A -> ("PUSHF", 0, true)
        0x1B -> ("POPF", 0, true)
        0x1C -> ("PUSHA", 0, true)
        0x1D -> ("POPA", 0, true)
        0x9B -> ("ENTER", 1, true)
        0x9C -> ("LEAVE", 0, true)
        0x1E -> ("JMP", 1, true)
        0x1F -> ("JZ", 1, true)
        0x20 -> ("JNZ", 1, true)
        0x21 -> ("JO", 1, true)
        0x22 -> ("JNO", 1, true)
        0x23 -> ("JC", 1, true)
        0x24 -> ("JNC", 1, true)
        0x25 -> ("JS", 1, true)
        0x26 -> ("JNS", 1, true)
        0x27 -> ("JGT", 1, true)
        0x28 -> ("JLT", 1, true)
        0x29 -> ("JGE", 1, true)
        0x2A -> ("JLE", 1, true)
        0x2B -> ("BR", 1, true)
        0x2C -> ("BRZ", 1, true)
        0x2D -> ("BRNZ", 1, true)
        0x2E -> ("CMP", 2, true)
        0x2F -> ("CALL", 1, true)
        0x30 -> ("INT", 1, true)
        0x9D -> ("CALLZ", 1, true)
        0x9E -> ("CALLNZ", 1, true)
        0x9F -> ("RETN", 1, true)
        0xA0 -> ("LOOPZ", 2, true)
        0xA1 -> ("WHILE", 1, true)
        0x5A -> ("LOOP", 2, true)
        0x31 -> ("SBLEND", 1, true)
        0x32 -> ("SREAD", 1, true)
        0x33 -> ("SWRITE", 1, true)
        0x34 -> ("SROL", 2, true)
        0x35 -> ("SROT", 2, true)
        0x36 -> ("SSHFT", 2, true)
        0x37 -> ("SFLIP", 1, true)
        0x38 -> ("SLINE", 2, true)
        0x39 -> ("SRECT", 3, true)
        0x3A -> ("SCIRC", 2, true)
        0x3B -> ("SINV", 0, true)
        0x3C -> ("SBLIT", 0, true)
        0x3D -> ("SFILL", 1, true)
        0x3E -> ("VREAD", 1, true)
        0x3F -> ("VWRITE", 1, true)
        0x40 -> ("VBLIT", 0, true)
        0x41 -> ("CHAR", 1, true)
        0x42 -> ("TEXT", 1, true)
        0x43 -> ("KEYIN", 1, true)
        0x44 -> ("KEYSTAT", 1, true)
        0x45 -> ("KEYCOUNT", 1, true)
        0x46 -> ("KEYCLEAR", 0, true)
        0x47 -> ("KEYCTRL", 1, true)
        0x48 -> ("RND", 1, true)
        0x49 -> ("RNDR", 3, true)
        0x4A -> ("MEMCPY", 3, true)
        0x7C -> ("MEMSET", 3, true)
        0x7D -> ("MEMTEST", 3, true)
        0x7E -> ("MEMMOVE", 3, true)
        0x99 -> ("MEMCMP", 4, false)
        0x9A -> ("MEMSWAP", 3, true)
        0x71 -> ("STRCPY", 2, true)
        0x72 -> ("STRCAT", 2, true)
        0x73 -> ("STRCMP", 3, true)
        0x74 -> ("STRLEN", 1, true)
        0x75 -> ("STREXT", 4, false)
        0x76 -> ("STREXTI", 4, false)
        0x77 -> ("STRUPR", 1, true)
        0x78 -> ("STRLWR", 1, true)
        0x79 -> ("STRREV", 1, true)
        0x7A -> ("STRFIND", 2, true)
        0x7B -> ("STRFINDI", 2, true)
        0x83 -> ("ITOB", 2, true)
        0x84 -> ("BTOI", 2, true)
        0x85 -> ("ITOS", 2, true)
        0x86 -> ("STOI", 2, true)
        0x4B -> ("SED", 0, true)
        0x4C -> ("CLD", 0, true)
        0x4D -> ("CLA", 0, true)
        0x4E -> ("BCDA", 2, true)
        0x4F -> ("BCDS", 2, true)
        0x50 -> ("BCDCMP", 2, true)
        0x51 -> ("BCD2BIN", 1, true)
        0x52 -> ("BIN2BCD", 1, true)
        0x53 -> ("BCDADD", 2, true)
        0x54 -> ("BCDSUB", 2, true)
        0x5B -> ("POWR", 2, true)
        0x5C -> ("SQRT", 1, true)
        0x5D -> ("LOG", 1, true)
        0x5E -> ("EXP", 1, true)
        0x5F -> ("SIN", 1, true)
        0x60 -> ("COS", 1, true)
        0x61 -> ("TAN", 1, true)
        0x62 -> ("ATAN", 1, true)
        0x63 -> ("ASIN", 1, true)
        0x64 -> ("ACOS", 1, true)
        0x65 -> ("DEG", 1, true)
        0x66 -> ("RAD", 1, true)
        0x67 -> ("FLOOR", 1, true)
        0x68 -> ("CEIL", 1, true)
        0x69 -> ("ROUND", 1, true)
        0x6A -> ("TRUNC", 1, true)
        0x6B -> ("FRAC", 1, true)
        0x6C -> ("INTGR", 1, true)
        0x55 -> ("SPBLIT", 1, true)
        0x56 -> ("SPBLITALL", 0, true)
        0x57 -> ("SPLAY", 0, true)
        0x58 -> ("SSTOP", 0, true)
        0x59 -> ("STRIG", 1, true)
        0x7F -> ("SMIX", 1, true)
        0x80 -> ("SECHO", 2, true)
        0x81 -> ("SREVERB", 2, true)
        0x82 -> ("SFILTER", 2, true)
        _ -> ("???", 0, false)

# Formats one operand starting at `data[pos]` per `cpu.star::decode_operand`'s
# own encoding (mode 0=register, 1=imm8, 2=imm16, 3=memory, with `direct`/
# `indexed` picking which of the four memory sub-forms) -- returns
# (formatted text, new position). Memory-mode syntax mirrors
# `docs/Operand prefix system.md`'s own examples (`[P2]`, `[P2 + 8]`,
# `[0x2000]`, `[0x2000 + 4]`) and the assembler-accepted hex-immediate style
# every checked-in `tests/asm/*.asm` source already uses.
fn format_operand(data: Bytes, pos: i32, mode: i32, direct: bool, indexed: bool) -> (str, i32):
    match mode:
        0 ->
            let code = data[pos]
            (reg_name(code), pos + 1)
        1 ->
            let v = data[pos] as i32
            (concat("0x", hex_byte(v)), pos + 1)
        2 ->
            let hi = data[pos] as i32
            let lo = data[pos + 1] as i32
            (concat("0x", hex_word((hi << 8) | lo)), pos + 2)
        _ ->
            if !direct and !indexed:
                let code = data[pos]
                let text: List<str> = ["[", reg_name(code), "]"]
                (str_join(text, ""), pos + 1)
            elif !direct and indexed:
                let code = data[pos]
                let off = bits::sign_extend8(data[pos + 1])
                let text: List<str> = ["[", reg_name(code), format_offset(off), "]"]
                (str_join(text, ""), pos + 2)
            elif direct and !indexed:
                let hi = data[pos] as i32
                let lo = data[pos + 1] as i32
                let text: List<str> = ["[0x", hex_word((hi << 8) | lo), "]"]
                (str_join(text, ""), pos + 2)
            else:
                let hi = data[pos] as i32
                let lo = data[pos + 1] as i32
                let off = bits::sign_extend8(data[pos + 2])
                let text: List<str> = ["[0x", hex_word((hi << 8) | lo), format_offset(off), "]"]
                (str_join(text, ""), pos + 3)

# Decodes exactly one instruction at `data[pos]`. Returns (formatted text,
# new position, ok) -- `ok` is false either at end of buffer, on a genuinely
# unknown opcode byte (the CPU itself would halt with a diagnostic here, see
# NOTES.md "Known simplifications" -- a disassembler has nothing safe to do
# either, since it can't know how many bytes to skip), or on a truncated
# final instruction (mode byte or operand bytes run past the buffer end).
fn disassemble_one(data: Bytes, pos: i32) -> (str, i32, bool):
    if pos >= data.len():
        return ("", pos, false)
    let op = data[pos]
    let mut p = pos + 1
    let (mnem, arity, _verified) = opcode_info(op)
    if mnem == "???":
        let unk: List<str> = ["??? (0x", hex_byte(op as i32), ")"]
        return (str_join(unk, ""), p, false)
    if arity == 0:
        return (mnem, p, true)
    if p >= data.len():
        return (concat(mnem, " <truncated>"), p, false)
    let mode_byte = data[p]
    p = p + 1
    let b = mode_byte as i32
    let mode1 = b % 4
    let mode2 = (b / 4) % 4
    let mode3 = (b / 16) % 4
    let indexed = bit_get(mode_byte, 6)
    let direct = bit_get(mode_byte, 7)

    let mut parts: List<str> = List<str>()
    let (t1, p1) = format_operand(data, p, mode1, direct, indexed)
    p = p1
    parts.push(t1)
    if arity >= 2:
        let (t2, p2) = format_operand(data, p, mode2, direct, indexed)
        p = p2
        parts.push(t2)
    if arity >= 3:
        let (t3, p3) = format_operand(data, p, mode3, direct, indexed)
        p = p3
        parts.push(t3)
    # 4-operand opcodes (STREXT/STREXTI/MEMCMP) can't be fully decoded: the
    # mode byte only encodes 3 operand slots at all (NOTES.md "4-operand
    # instructions are out of scope"), so only the first 3 are shown -- the
    # same structural ceiling `cpu.star` itself hits, not a shortcut taken
    # here specifically.
    let operand_text = str_join(parts, ", ")
    let whole: List<str> = [mnem, operand_text]
    (str_join(whole, " "), p, true)

# Parses one `.org` segment line the same way `loader.star::parse_org_line`
# does, duplicated rather than imported to keep this file's own import list
# (and therefore its link requirements) independent of `cpu.star` entirely.
fn first_org_addr(org_path: str) -> (i32, bool):
    let oh = file_open(org_path, "r")
    if is_null(oh):
        return (0, false)
    let content = file_read(oh)
    file_close(oh)
    let lines = str_split(content, "\n")
    let mut li = 0
    while li < lines.len():
        let line = str_trim(lines[li])
        if len(line) > 0 and !str_starts_with(line, "#"):
            let parts = str_split(line, " ")
            if parts.len() == 3:
                let addr = strtol(parts[0], null_ptr(), 0)
                return (addr, true)
        li = li + 1
    (0, false)

fn main():
    let cli = args()
    if cli.len() < 2:
        println("usage: disasm <path.bin> [start_addr] [length]")
        return

    let bh = file_open(cli[1], "r")
    if is_null(bh):
        let msg: List<str> = ["could not open '", cli[1], "'"]
        println(str_join(msg, ""))
        return
    let data = file_read_bytes(bh)
    file_close(bh)

    let org_path = str_replace(cli[1], ".bin", ".org")
    let (org_addr, has_org) = first_org_addr(org_path)
    let base_addr = if has_org: org_addr else: 0

    let mut start = 0
    if cli.len() > 2:
        start = atoi(cli[2])
    let mut length = data.len()
    if cli.len() > 3:
        length = atoi(cli[3])
    let end = if start + length < data.len(): start + length else: data.len()

    let mut pos = start
    while pos < end:
        let addr = base_addr + pos
        let start_pos = pos
        let (text, new_pos, ok) = disassemble_one(data, pos)
        let mut raw = ""
        let mut k = start_pos
        while k < new_pos:
            let step: List<str> = [raw, hex_byte(data[k] as i32), " "]
            raw = str_join(step, "")
            k = k + 1
        let line: List<str> = [hex_word(addr), ": ", raw, text]
        println(str_join(line, ""))
        if !ok:
            break
        pos = new_pos
