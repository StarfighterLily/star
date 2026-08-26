# Nova-16 assembler -- turns a `.asm` source file into a compiled `.bin` (plus
# a `.org` segment sidecar and a `.sym` symbol-table file), the missing piece
# named in NOTES.md's "Ideas for future work" and todo.md P1 #2: until this
# file existed, a `.bin` could only ever be loaded (`loader.star`) or decoded
# back to text (`disasm.star`) -- never produced from Star-authored source.
# Matches the upstream Python `nova_assembler.py`'s own accepted syntax and
# output-file conventions closely enough that either assembler can consume
# the other's inputs and (mostly -- see "Deliberate deviations from the
# Python assembler" below) produce byte-identical output, verified directly
# against the live Python reference (not just hand-derived) -- see this
# file's own header comment continuing below and NOTES.md's "Assembler"
# section for the actual verification record.
#
# Like `disasm.star`, this is a pure text-in/bytes-out tool with no `Cpu`
# dependency and no SDL2 link requirement:
#   star build projects/nova/assembler.star -o projects/nova/assembler.exe
#   projects/nova/assembler.exe path/to/program.asm
#
# Opcode/register tables below are transcribed directly from `disasm.star`'s
# own already-cross-checked-against-`cpu.star` `opcode_info`/`reg_name`
# tables (not re-derived independently from the doc or from Python's
# `opcodes.py`), so encode and decode stay provably consistent with each
# other and with what `cpu.star` actually executes -- an assemble-then-
# disassemble round trip is exactly this file's own primary correctness
# check (see NOTES.md).
#
# Scope, and deliberate deviations from the Python assembler:
# - No MACRO/INCLUDE/IF-IFDEF-IFNDEF-ELSE-ENDIF preprocessing. None of this
#   project's own checked-in `tests/asm/*.asm` sources (the ones the Python
#   assembler actually produced the checked-in `.bin`/`.org` files from) use
#   any of these, so there is nothing in this project's own real corpus that
#   needs them; a future session can add a preprocessing pass here without
#   disturbing anything below if a real source ever needs one.
# - Directives: `ORG`/`EQU`/`DB`/`DW`/`DEFSTR`/`DS`, matching the Python
#   assembler's own directive set exactly (minus the preprocessing-only ones
#   above).
# - The 12 "dual-purpose" mnemonics the Python assembler accepts as
#   standalone one-operand instructions (`SA`/`SF`/`SV`/`SW`/`TT`/`TM`/`TC`/
#   `TS`/`VM`/`VL`/`VX`/`VY` -- e.g. Python's assembler happily encodes a
#   bare `TT 5` line) are NOT accepted here as instructions, only as register
#   operands. Reason: `cpu.star`'s own `execute` dispatch has no opcode-table
#   entry for any of these bytes as standalone opcodes at all (confirmed by
#   grepping every register-code match in `cpu.star` -- `get_reg_value`/
#   `set_reg_value`/`reg_width` all have arms for these codes, `execute`
#   does not), matching NOTES.md's own "What's implemented" note that this
#   port reaches every one of these registers "via MOV/arithmetic/etc, not
#   just as dedicated opcodes" -- i.e. this is a real, already-documented
#   capability gap in this port's CPU, not something newly discovered here.
#   Encoding them anyway would silently produce a `.bin` this port's own
#   `cpu.star` cannot run (an "unknown opcode" halt partway through), so
#   this assembler rejects them at assembly time instead.
# - `SMIX`/`SECHO`/`SREVERB`/`SFILTER` assemble normally (`todo.md` P2 #4) --
#   previously rejected here, mirroring the Python assembler's own
#   `UNIMPLEMENTED_INSTRUCTIONS` check, back when neither CPU had a handler
#   for them. `cpu_sound.star` now does; see its header comment for the
#   real (Star-original, no reference to match) DSP behind them.
# - `BR`/`BRZ`/`BRNZ` symbol operands encode a signed 16-bit PC-relative
#   offset -- target minus the address *after* the instruction (opcode +
#   mode byte + imm16 = 4 bytes) -- not an absolute address; hex/decimal/
#   char-literal operands still encode their raw value. This now matches
#   the fixed Python assembler exactly: `nova_assembler.py` upstream
#   finished its previously-dead `_parse_immediate_value` relative-offset
#   branch (`ebbbcaa`/`955452b`, Aug 2026 -- it used to be `val = val - 0
#   # Would need location_counter passed in`, a no-op this port had already
#   matched deliberately and filed under NOTES.md's "What to carry back"),
#   threading `location_counter`/mnemonic through `encode_operand` and
#   converting *only* symbol-resolved operands inside that branch. Byte
#   parity requires mirroring that shape here, asymmetry included: `BR`
#   over a label gets a real delta, `BR 0x0040` keeps encoding `0x0040`,
#   exactly as Python does today.
# - `[0xADDR + off]` (direct-indexed addressing, the fourth combination of
#   the direct/indexed mode bits) is supported here even though the Python
#   assembler cannot produce it at all (its own `direct`/`indexed` regexes
#   don't compose, confirmed empirically: `[0x2000+4]` raises "Unknown base
#   register: 0x2000" in the Python assembler, since it falls through into
#   the general register-indexed path with "0x2000" as an attempted register
#   name). `cpu.star`'s `decode_operand` and `disasm.star`'s own
#   `format_operand` both handle this addressing mode correctly (it's a real
#   CPU capability, not a wrong guess), so this is a deliberate superset, not
#   a divergence that could ever show up in a byte-for-byte comparison
#   against real Python-assembled output (Python can't generate an input
#   that would exercise it). Verified separately via this file's own
#   disassemble-round-trip check -- see NOTES.md.
# - Fail-fast, not collect-all-errors: the Python assembler collects every
#   line's errors and reports them together at the end; this file reports
#   the first error and exits immediately. Simpler, and this project's other
#   tools (`disasm.star`, `loader.star`) already follow the same "stop at
#   the first problem" convention rather than Python's own error-accumulation
#   style.
# - Register-name and mnemonic matching is case-insensitive here (tokens are
#   upper-cased before lookup); the Python assembler is case-sensitive for
#   registers specifically (an accident of its classifier comparing the raw
#   token against an all-uppercase set without upper-casing first -- reading
#   `OperandClassifier.classify_operand` confirms `operand in valid_registers`
#   never upper-cases `operand`). Every real `.asm` source in this project
#   (and every one Python could have produced test `.bin`s from) already
#   writes registers in upper case, so this is strictly more lenient and
#   never changes output for any source Python could already assemble.

import "bits.star" as bits

extern "C" fn atoi(s: str) -> i32
extern "C" fn strtol(s: str, endptr: ptr, base: i32) -> i32

# ---------------------------------------------------------------------------
# String/byte helpers -- Star's `str` has no substring/slice operator (only
# `s[i] -> i32` single-byte indexing, per `docs/language_reference.md`), so
# every substring this file needs is built up one byte at a time via `chr`
# and `str_join`, the same approach `disasm.star`'s `dec_str` already uses
# for building strings up from digits.
# ---------------------------------------------------------------------------

fn substr(s: str, start: i32, end: i32) -> str:
    let mut parts: List<str> = List<str>()
    let mut i = start
    while i < end:
        parts.push(chr(s[i]))
        i += 1
    str_join(parts, "")

fn is_ws_byte(c: i32) -> bool:
    c == 32 or c == 9 or c == 13

fn ltrim(s: str) -> str:
    let mut i = 0
    while i < len(s) and is_ws_byte(s[i]):
        i += 1
    substr(s, i, len(s))

# Splits off the first whitespace-delimited token. Returns (token, rest),
# `rest` trimmed of its own leading/trailing whitespace -- mirrors
# `nova_assembler.py::Parser.parse_line`'s local `split_head` helper.
fn split_first_token(s: str) -> (str, str):
    let t = ltrim(s)
    let mut i = 0
    while i < len(t) and !is_ws_byte(t[i]):
        i += 1
    let token = substr(t, 0, i)
    let rest = str_trim(substr(t, i, len(t)))
    (token, rest)

fn is_digit_byte(c: i32) -> bool:
    c >= 48 and c <= 57

# A plain (optionally negative) decimal integer token: `-?[0-9]+`.
fn is_decimal_token(s: str) -> bool:
    if len(s) == 0:
        return false
    let mut i = 0
    if s[0] == 45:
        i = 1
    if i >= len(s):
        return false
    while i < len(s):
        if !is_digit_byte(s[i]):
            return false
        i += 1
    true

fn str_upper(s: str) -> str:
    let mut parts: List<str> = List<str>()
    let mut i = 0
    while i < len(s):
        let c = s[i]
        if c >= 97 and c <= 122:
            parts.push(chr(c - 32))
        else:
            parts.push(chr(c))
        i += 1
    str_join(parts, "")

# Index of the first top-level `+` or `-` in an indexed-addressing bracket's
# interior (`P2+8` -> 2, `0x2000-4` -> 6), or -1 if there isn't one. Callers
# always strip spaces first, so no whitespace-skipping is needed here.
fn find_sign(s: str) -> i32:
    let mut i = 0
    while i < len(s):
        if s[i] == 43 or s[i] == 45:
            return i
        i += 1
    -1

# There is no user-callable process-abort/exit builtin in this language --
# `exit` is reserved (the compiler already declares it internally for its
# own runtime traps; redeclaring it via `extern "C" fn exit` is a hard
# compile error, confirmed empirically) -- so this can only print a
# diagnostic, not actually terminate the process. That's fine in practice:
# `main` runs `validate_lines` right after the symbol table is complete and
# before any bytes are emitted, and reports every realistic failure through
# a real nonzero `return` from `main` there. These calls are a defense-in-
# depth fallback for a code path validation didn't anticipate, not the
# primary error-reporting mechanism.
fn fatal(msg: str):
    println(concat("assembler error: ", msg))

# Parses a decimal or `0x`-prefixed hex literal. Deliberately does NOT use
# `strtol(..., base=0)` for the decimal case: base-0 `strtol` treats a
# leading-zero decimal string (`"010"`) as octal, which C99 in general -- and
# nothing in `nova_assembler.py`, which only ever does plain `int(value)` for
# its own decimal branch -- would ever do here.
fn parse_numeric(token: str) -> i32:
    if str_starts_with(token, "0x") or str_starts_with(token, "0X"):
        strtol(token, null_ptr(), 0)
    else:
        atoi(token)

# ---------------------------------------------------------------------------
# Register table -- transcribed from `disasm.star::reg_name`'s match, which
# was itself cross-checked against `cpu.star::get_reg_value`'s own register-
# code match (NOTES.md "One flat register-code address space" -- the single
# source of truth for every register, general-purpose or special).
# ---------------------------------------------------------------------------

fn build_registers() -> Map<str, i32>:
    let mut r: Map<str, i32> = Map<str, i32>()
    r.insert("BANK", 0xC2)
    r.insert("C0", 0xC3)
    r.insert("C1", 0xC4)
    r.insert("MX", 0xC5)
    r.insert("MY", 0xC6)
    r.insert("MB", 0xC7)
    r.insert("VC", 0xC8)
    r.insert("P0:", 0xC9)
    r.insert("P1:", 0xCA)
    r.insert("P2:", 0xCB)
    r.insert("P3:", 0xCC)
    r.insert("P4:", 0xCD)
    r.insert("P5:", 0xCE)
    r.insert("P6:", 0xCF)
    r.insert("P7:", 0xD0)
    r.insert("P8:", 0xD1)
    r.insert("P9:", 0xD2)
    r.insert(":P0", 0xD3)
    r.insert(":P1", 0xD4)
    r.insert(":P2", 0xD5)
    r.insert(":P3", 0xD6)
    r.insert(":P4", 0xD7)
    r.insert(":P5", 0xD8)
    r.insert(":P6", 0xD9)
    r.insert(":P7", 0xDA)
    r.insert(":P8", 0xDB)
    r.insert(":P9", 0xDC)
    r.insert("SA", 0xDD)
    r.insert("SF", 0xDE)
    r.insert("SV", 0xDF)
    r.insert("SW", 0xE0)
    r.insert("VM", 0xE1)
    r.insert("VL", 0xE2)
    r.insert("TT", 0xE3)
    r.insert("TM", 0xE4)
    r.insert("TC", 0xE5)
    r.insert("TS", 0xE6)
    r.insert("R0", 0xE7)
    r.insert("R1", 0xE8)
    r.insert("R2", 0xE9)
    r.insert("R3", 0xEA)
    r.insert("R4", 0xEB)
    r.insert("R5", 0xEC)
    r.insert("R6", 0xED)
    r.insert("R7", 0xEE)
    r.insert("R8", 0xEF)
    r.insert("R9", 0xF0)
    r.insert("P0", 0xF1)
    r.insert("P1", 0xF2)
    r.insert("P2", 0xF3)
    r.insert("P3", 0xF4)
    r.insert("P4", 0xF5)
    r.insert("P5", 0xF6)
    r.insert("P6", 0xF7)
    r.insert("P7", 0xF8)
    r.insert("P8", 0xF9)
    r.insert("P9", 0xFA)
    r.insert("SP", 0xFB)
    r.insert("FP", 0xFC)
    r.insert("VX", 0xFD)
    r.insert("VY", 0xFE)
    r

# ---------------------------------------------------------------------------
# Instruction table -- transcribed from `disasm.star::opcode_info`'s match
# (mnemonic, opcode, operand count), which itself was mechanically cross-
# checked against `cpu.star`'s own `decode_operands(N)` call sites (NOTES.md
# "Disassembler" -- ten real operand-count doc errors were found this way).
# Reusing that exact table here means an assemble-then-disassemble round
# trip is a genuine end-to-end check, not two independently-guessed tables
# happening to agree.
# ---------------------------------------------------------------------------

fn build_instructions() -> (Map<str, i32>, Map<str, i32>):
    let mut op: Map<str, i32> = Map<str, i32>()
    let mut ar: Map<str, i32> = Map<str, i32>()

    op.insert("HLT", 0x00)
    ar.insert("HLT", 0)
    op.insert("NOP", 0xFF)
    ar.insert("NOP", 0)
    op.insert("RET", 0x01)
    ar.insert("RET", 0)
    op.insert("IRET", 0x02)
    ar.insert("IRET", 0)
    op.insert("CLI", 0x03)
    ar.insert("CLI", 0)
    op.insert("STI", 0x04)
    ar.insert("STI", 0)
    op.insert("MOV", 0x06)
    ar.insert("MOV", 2)
    op.insert("SWAP", 0x94)
    ar.insert("SWAP", 1)
    op.insert("XCHNG", 0x95)
    ar.insert("XCHNG", 2)
    op.insert("MOVZ", 0x96)
    ar.insert("MOVZ", 2)
    op.insert("MOVNZ", 0x97)
    ar.insert("MOVNZ", 2)
    op.insert("LEA", 0x98)
    ar.insert("LEA", 2)
    op.insert("ADD", 0x07)
    ar.insert("ADD", 2)
    op.insert("SUB", 0x08)
    ar.insert("SUB", 2)
    op.insert("MUL", 0x09)
    ar.insert("MUL", 2)
    op.insert("DIV", 0x0A)
    ar.insert("DIV", 2)
    op.insert("INC", 0x0B)
    ar.insert("INC", 1)
    op.insert("DEC", 0x0C)
    ar.insert("DEC", 1)
    op.insert("MOD", 0x0D)
    ar.insert("MOD", 2)
    op.insert("NEG", 0x0E)
    ar.insert("NEG", 1)
    op.insert("ABS", 0x0F)
    ar.insert("ABS", 1)
    op.insert("ADC", 0x87)
    ar.insert("ADC", 2)
    op.insert("FMUL", 0xAC)
    ar.insert("FMUL", 2)
    op.insert("FDIV", 0xAD)
    ar.insert("FDIV", 2)
    op.insert("FTOI", 0xAE)
    ar.insert("FTOI", 1)
    op.insert("ITOF", 0xAF)
    ar.insert("ITOF", 1)
    op.insert("SBC", 0x88)
    ar.insert("SBC", 2)
    op.insert("MULH", 0x89)
    ar.insert("MULH", 2)
    op.insert("DIVH", 0x8A)
    ar.insert("DIVH", 2)
    op.insert("MIN", 0x8B)
    ar.insert("MIN", 2)
    op.insert("MAX", 0x8C)
    ar.insert("MAX", 2)
    op.insert("CLZ", 0x8D)
    ar.insert("CLZ", 1)
    op.insert("CTZ", 0x8E)
    ar.insert("CTZ", 1)
    op.insert("POPCNT", 0x8F)
    ar.insert("POPCNT", 1)
    op.insert("SERIN", 0xA2)
    ar.insert("SERIN", 1)
    op.insert("SEROUT", 0xA3)
    ar.insert("SEROUT", 1)
    op.insert("SERSTAT", 0xA4)
    ar.insert("SERSTAT", 1)
    op.insert("SERCTRL", 0xA5)
    ar.insert("SERCTRL", 1)
    op.insert("SETBP", 0xA6)
    ar.insert("SETBP", 2)
    op.insert("CLRBP", 0xA7)
    ar.insert("CLRBP", 1)
    op.insert("ENABRK", 0xA8)
    ar.insert("ENABRK", 0)
    op.insert("DISBRK", 0xA9)
    ar.insert("DISBRK", 0)
    op.insert("ENATRAP", 0xAA)
    ar.insert("ENATRAP", 0)
    op.insert("DISATRAP", 0xAB)
    ar.insert("DISATRAP", 0)
    op.insert("LSWAP", 0xB0)
    ar.insert("LSWAP", 1)
    op.insert("LMOVE", 0xB1)
    ar.insert("LMOVE", 1)
    op.insert("LCOPY", 0xB2)
    ar.insert("LCOPY", 1)
    op.insert("MOUSECTRL", 0xB3)
    ar.insert("MOUSECTRL", 1)
    op.insert("SERFSTAT", 0xB4)
    ar.insert("SERFSTAT", 1)
    op.insert("AND", 0x10)
    ar.insert("AND", 2)
    op.insert("OR", 0x11)
    ar.insert("OR", 2)
    op.insert("XOR", 0x12)
    ar.insert("XOR", 2)
    op.insert("NOT", 0x13)
    ar.insert("NOT", 1)
    op.insert("SHL", 0x14)
    ar.insert("SHL", 2)
    op.insert("SHR", 0x15)
    ar.insert("SHR", 2)
    op.insert("ROL", 0x16)
    ar.insert("ROL", 2)
    op.insert("ROR", 0x17)
    ar.insert("ROR", 2)
    op.insert("SAR", 0x90)
    ar.insert("SAR", 2)
    op.insert("SAL", 0x91)
    ar.insert("SAL", 2)
    op.insert("RCL", 0x92)
    ar.insert("RCL", 2)
    op.insert("RCR", 0x93)
    ar.insert("RCR", 2)
    op.insert("BTST", 0x6D)
    ar.insert("BTST", 2)
    op.insert("BSET", 0x6E)
    ar.insert("BSET", 2)
    op.insert("BCLR", 0x6F)
    ar.insert("BCLR", 2)
    op.insert("BFLIP", 0x70)
    ar.insert("BFLIP", 2)
    op.insert("PUSH", 0x18)
    ar.insert("PUSH", 1)
    op.insert("POP", 0x19)
    ar.insert("POP", 1)
    op.insert("PUSHF", 0x1A)
    ar.insert("PUSHF", 0)
    op.insert("POPF", 0x1B)
    ar.insert("POPF", 0)
    op.insert("PUSHA", 0x1C)
    ar.insert("PUSHA", 0)
    op.insert("POPA", 0x1D)
    ar.insert("POPA", 0)
    op.insert("ENTER", 0x9B)
    ar.insert("ENTER", 1)
    op.insert("LEAVE", 0x9C)
    ar.insert("LEAVE", 0)
    op.insert("JMP", 0x1E)
    ar.insert("JMP", 1)
    op.insert("JZ", 0x1F)
    ar.insert("JZ", 1)
    op.insert("JNZ", 0x20)
    ar.insert("JNZ", 1)
    op.insert("JO", 0x21)
    ar.insert("JO", 1)
    op.insert("JNO", 0x22)
    ar.insert("JNO", 1)
    op.insert("JC", 0x23)
    ar.insert("JC", 1)
    op.insert("JNC", 0x24)
    ar.insert("JNC", 1)
    op.insert("JS", 0x25)
    ar.insert("JS", 1)
    op.insert("JNS", 0x26)
    ar.insert("JNS", 1)
    op.insert("JGT", 0x27)
    ar.insert("JGT", 1)
    op.insert("JLT", 0x28)
    ar.insert("JLT", 1)
    op.insert("JGE", 0x29)
    ar.insert("JGE", 1)
    op.insert("JLE", 0x2A)
    ar.insert("JLE", 1)
    op.insert("BR", 0x2B)
    ar.insert("BR", 1)
    op.insert("BRZ", 0x2C)
    ar.insert("BRZ", 1)
    op.insert("BRNZ", 0x2D)
    ar.insert("BRNZ", 1)
    op.insert("CMP", 0x2E)
    ar.insert("CMP", 2)
    op.insert("CALL", 0x2F)
    ar.insert("CALL", 1)
    op.insert("INT", 0x30)
    ar.insert("INT", 1)
    op.insert("CALLZ", 0x9D)
    ar.insert("CALLZ", 1)
    op.insert("CALLNZ", 0x9E)
    ar.insert("CALLNZ", 1)
    op.insert("RETN", 0x9F)
    ar.insert("RETN", 1)
    op.insert("LOOPZ", 0xA0)
    ar.insert("LOOPZ", 2)
    op.insert("WHILE", 0xA1)
    ar.insert("WHILE", 1)
    op.insert("LOOP", 0x5A)
    ar.insert("LOOP", 2)
    op.insert("SBLEND", 0x31)
    ar.insert("SBLEND", 1)
    op.insert("SREAD", 0x32)
    ar.insert("SREAD", 1)
    op.insert("SWRITE", 0x33)
    ar.insert("SWRITE", 1)
    op.insert("SROL", 0x34)
    ar.insert("SROL", 2)
    op.insert("SROT", 0x35)
    ar.insert("SROT", 2)
    op.insert("SSHFT", 0x36)
    ar.insert("SSHFT", 2)
    op.insert("SFLIP", 0x37)
    ar.insert("SFLIP", 1)
    op.insert("SLINE", 0x38)
    ar.insert("SLINE", 2)
    op.insert("SRECT", 0x39)
    ar.insert("SRECT", 3)
    op.insert("SCIRC", 0x3A)
    ar.insert("SCIRC", 2)
    op.insert("SINV", 0x3B)
    ar.insert("SINV", 0)
    op.insert("SBLIT", 0x3C)
    ar.insert("SBLIT", 0)
    op.insert("SFILL", 0x3D)
    ar.insert("SFILL", 1)
    op.insert("VREAD", 0x3E)
    ar.insert("VREAD", 1)
    op.insert("VWRITE", 0x3F)
    ar.insert("VWRITE", 1)
    op.insert("VBLIT", 0x40)
    ar.insert("VBLIT", 0)
    op.insert("CHAR", 0x41)
    ar.insert("CHAR", 1)
    op.insert("TEXT", 0x42)
    ar.insert("TEXT", 1)
    op.insert("KEYIN", 0x43)
    ar.insert("KEYIN", 1)
    op.insert("KEYSTAT", 0x44)
    ar.insert("KEYSTAT", 1)
    op.insert("KEYCOUNT", 0x45)
    ar.insert("KEYCOUNT", 1)
    op.insert("KEYCLEAR", 0x46)
    ar.insert("KEYCLEAR", 0)
    op.insert("KEYCTRL", 0x47)
    ar.insert("KEYCTRL", 1)
    op.insert("RND", 0x48)
    ar.insert("RND", 1)
    op.insert("RNDR", 0x49)
    ar.insert("RNDR", 3)
    op.insert("MEMCPY", 0x4A)
    ar.insert("MEMCPY", 3)
    op.insert("MEMSET", 0x7C)
    ar.insert("MEMSET", 3)
    op.insert("MEMTEST", 0x7D)
    ar.insert("MEMTEST", 3)
    op.insert("MEMMOVE", 0x7E)
    ar.insert("MEMMOVE", 3)
    op.insert("MEMCMP", 0x99)
    ar.insert("MEMCMP", 4)
    op.insert("MEMSWAP", 0x9A)
    ar.insert("MEMSWAP", 3)
    op.insert("STRCPY", 0x71)
    ar.insert("STRCPY", 2)
    op.insert("STRCAT", 0x72)
    ar.insert("STRCAT", 2)
    op.insert("STRCMP", 0x73)
    ar.insert("STRCMP", 3)
    op.insert("STRLEN", 0x74)
    ar.insert("STRLEN", 1)
    op.insert("STREXT", 0x75)
    ar.insert("STREXT", 4)
    op.insert("STREXTI", 0x76)
    ar.insert("STREXTI", 4)
    op.insert("STRUPR", 0x77)
    ar.insert("STRUPR", 1)
    op.insert("STRLWR", 0x78)
    ar.insert("STRLWR", 1)
    op.insert("STRREV", 0x79)
    ar.insert("STRREV", 1)
    op.insert("STRFIND", 0x7A)
    ar.insert("STRFIND", 2)
    op.insert("STRFINDI", 0x7B)
    ar.insert("STRFINDI", 2)
    op.insert("ITOB", 0x83)
    ar.insert("ITOB", 2)
    op.insert("BTOI", 0x84)
    ar.insert("BTOI", 2)
    op.insert("ITOS", 0x85)
    ar.insert("ITOS", 2)
    op.insert("STOI", 0x86)
    ar.insert("STOI", 2)
    op.insert("SED", 0x4B)
    ar.insert("SED", 0)
    op.insert("CLD", 0x4C)
    ar.insert("CLD", 0)
    op.insert("CLA", 0x4D)
    ar.insert("CLA", 0)
    op.insert("BCDA", 0x4E)
    ar.insert("BCDA", 2)
    op.insert("BCDS", 0x4F)
    ar.insert("BCDS", 2)
    op.insert("BCDCMP", 0x50)
    ar.insert("BCDCMP", 2)
    op.insert("BCD2BIN", 0x51)
    ar.insert("BCD2BIN", 1)
    op.insert("BIN2BCD", 0x52)
    ar.insert("BIN2BCD", 1)
    op.insert("BCDADD", 0x53)
    ar.insert("BCDADD", 2)
    op.insert("BCDSUB", 0x54)
    ar.insert("BCDSUB", 2)
    op.insert("POWR", 0x5B)
    ar.insert("POWR", 2)
    op.insert("SQRT", 0x5C)
    ar.insert("SQRT", 1)
    op.insert("LOG", 0x5D)
    ar.insert("LOG", 1)
    op.insert("EXP", 0x5E)
    ar.insert("EXP", 1)
    op.insert("SIN", 0x5F)
    ar.insert("SIN", 1)
    op.insert("COS", 0x60)
    ar.insert("COS", 1)
    op.insert("TAN", 0x61)
    ar.insert("TAN", 1)
    op.insert("ATAN", 0x62)
    ar.insert("ATAN", 1)
    op.insert("ASIN", 0x63)
    ar.insert("ASIN", 1)
    op.insert("ACOS", 0x64)
    ar.insert("ACOS", 1)
    op.insert("DEG", 0x65)
    ar.insert("DEG", 1)
    op.insert("RAD", 0x66)
    ar.insert("RAD", 1)
    op.insert("FLOOR", 0x67)
    ar.insert("FLOOR", 1)
    op.insert("CEIL", 0x68)
    ar.insert("CEIL", 1)
    op.insert("ROUND", 0x69)
    ar.insert("ROUND", 1)
    op.insert("TRUNC", 0x6A)
    ar.insert("TRUNC", 1)
    op.insert("FRAC", 0x6B)
    ar.insert("FRAC", 1)
    op.insert("INTGR", 0x6C)
    ar.insert("INTGR", 1)
    op.insert("SPBLIT", 0x55)
    ar.insert("SPBLIT", 1)
    op.insert("SPBLITALL", 0x56)
    ar.insert("SPBLITALL", 0)
    op.insert("SPLAY", 0x57)
    ar.insert("SPLAY", 0)
    op.insert("SSTOP", 0x58)
    ar.insert("SSTOP", 0)
    op.insert("STRIG", 0x59)
    ar.insert("STRIG", 1)
    op.insert("SMIX", 0x7F)
    ar.insert("SMIX", 1)
    op.insert("SECHO", 0x80)
    ar.insert("SECHO", 2)
    op.insert("SREVERB", 0x81)
    ar.insert("SREVERB", 2)
    op.insert("SFILTER", 0x82)
    ar.insert("SFILTER", 2)
    (op, ar)

fn build_unimplemented() -> Set<str>:
    # `SMIX`/`SECHO`/`SREVERB`/`SFILTER` used to be rejected here (mirroring
    # the Python assembler's own `UNIMPLEMENTED_INSTRUCTIONS` check) because
    # neither CPU had a handler for them. `cpu.star` now does -- see
    # `cpu_sound.star`'s header comment for the real, Star-original DSP
    # design behind them (`todo.md` P2 #4; there's no upstream reference
    # implementation to match, since `opcodes.py` leaves these four
    # unimplemented too) -- so this set is empty and these mnemonics assemble
    # like any other real instruction.
    Set<str>()

fn get_i32_or(m: Map<str, i32>, key: str, default: i32) -> i32:
    match m.get(key):
        Option::Some(v) -> v
        Option::None -> default

# ---------------------------------------------------------------------------
# Operand classification/encoding -- mirrors `nova_assembler.py`'s
# `OperandClassifier`/`CodeGenerator.encode_operand`, and (for the memory
# forms) `disasm.star::format_operand`'s addressing-mode structure, since
# encoding must produce exactly what that function decodes.
# ---------------------------------------------------------------------------

const OP_REG: i32 = 0
const OP_IMM8: i32 = 1
const OP_IMM16: i32 = 2
const OP_INDIRECT: i32 = 3
const OP_INDEXED: i32 = 4
const OP_DIRECT: i32 = 5
const OP_DIRECT_INDEXED: i32 = 6

fn is_char_literal(s: str) -> bool:
    if len(s) < 3:
        return false
    if s[0] != 39 or s[len(s) - 1] != 39:
        return false
    if len(s) == 3:
        return true
    len(s) == 4 and s[1] == 92

fn char_literal_value(s: str) -> i32:
    if len(s) == 3:
        return s[1]
    let e = s[2]
    if e == 110:
        10
    elif e == 116:
        9
    elif e == 114:
        13
    elif e == 92:
        92
    elif e == 39:
        39
    elif e == 48:
        0
    else:
        e

# Strips brackets and internal spaces from a memory-operand token
# (`"[P2 + 8]"` -> `"P2+8"`), the shared prep step every bracket-form
# classifier/encoder below starts from.
fn bracket_inner(token: str) -> str:
    str_replace(substr(token, 1, len(token) - 1), " ", "")

fn classify_bracket(inner: str) -> i32:
    let sign_idx = find_sign(inner)
    if sign_idx == -1:
        if str_starts_with(inner, "0x"):
            OP_DIRECT
        else:
            OP_INDIRECT
    else:
        let base = substr(inner, 0, sign_idx)
        if str_starts_with(base, "0x"):
            OP_DIRECT_INDEXED
        else:
            OP_INDEXED

fn classify_operand(token: str, registers: Map<str, i32>) -> i32:
    let up = str_upper(token)
    if registers.contains(up):
        return OP_REG
    if len(token) >= 2 and token[0] == 91 and token[len(token) - 1] == 93:
        return classify_bracket(bracket_inner(token))
    if is_char_literal(token):
        return OP_IMM8
    if str_starts_with(token, "0x") or str_starts_with(token, "0X"):
        let hexdigits = substr(token, 2, len(token))
        if len(hexdigits) <= 2:
            return OP_IMM8
        let val = strtol(token, null_ptr(), 0)
        if val > 127:
            return OP_IMM16
        else:
            return OP_IMM8
    if is_decimal_token(token):
        let val = atoi(token)
        if val < 0 or val > 127:
            return OP_IMM16
        else:
            return OP_IMM8
    OP_IMM16

fn operand_size(kind: i32) -> i32:
    if kind == OP_REG or kind == OP_IMM8 or kind == OP_INDIRECT:
        1
    elif kind == OP_IMM16 or kind == OP_DIRECT or kind == OP_INDEXED:
        2
    else:
        3

# Resolves a scalar (non-memory, non-register) operand token to its integer
# value: a char literal, a hex/decimal literal, or (falling through, matching
# `nova_assembler.py`'s own "default to a symbol" behavior for anything that
# isn't a recognized literal shape) a label/`EQU` name looked up in `symbols`.
# Only the *symbol* path ever converts to a branch-relative delta
# (`is_branch`, `branch_loc` are ignored for every literal shape), because
# `nova_assembler.py::_parse_immediate_value` reaches its conversion via the
# same fall-through ordering -- literals short-circuit first.
fn resolve_imm(token: str, symbols: Map<str, i32>, is_branch: bool, branch_loc: i32) -> i32:
    if is_char_literal(token):
        return char_literal_value(token)
    if str_starts_with(token, "0x") or str_starts_with(token, "0X"):
        return strtol(token, null_ptr(), 0)
    if is_decimal_token(token):
        return atoi(token)
    if let Option::Some(v) = symbols.get(token):
        # Same arithmetic `nova_assembler.py` uses since its fix: target
        # minus the address after the instruction (opcode + mode byte +
        # imm16 = 4 bytes); negatives wrap to two's-complement, positives
        # pass through unmasked so the caller's own shifts slice them.
        if is_branch:
            let offset = v - (branch_loc + 4)
            if offset < 0:
                return offset & 0xFFFF
            return offset
        return v
    fatal(concat("undefined symbol: ", token))
    0

fn parse_offset_byte(sign_and_num: str) -> i32:
    parse_numeric(sign_and_num) & 0xFF

# Encodes one already-classified operand to its byte sequence. `symbols` is
# only consulted for a bare label/`EQU` reference (`OP_IMM8`/`OP_IMM16` whose
# token isn't itself a literal) -- every other kind is fully determined by
# the token text alone. `is_branch`/`branch_loc` thread the current
# instruction's identity/location down to that symbol lookup (see
# `resolve_imm`); directives never need them.
fn encode_operand_bytes(token: str, kind: i32, registers: Map<str, i32>, symbols: Map<str, i32>, is_branch: bool, branch_loc: i32) -> List<i32>:
    let mut out: List<i32> = List<i32>()
    if kind == OP_REG:
        out.push(get_i32_or(registers, str_upper(token), -1))
    elif kind == OP_IMM8:
        out.push(resolve_imm(token, symbols, is_branch, branch_loc) & 0xFF)
    elif kind == OP_IMM16:
        let v = resolve_imm(token, symbols, is_branch, branch_loc)
        out.push((v >> 8) & 0xFF)
        out.push(v & 0xFF)
    elif kind == OP_INDIRECT:
        let inner = bracket_inner(token)
        let code = get_i32_or(registers, str_upper(inner), -1)
        if code == -1:
            fatal(concat("unknown register in indirect operand: ", inner))
        out.push(code)
    elif kind == OP_INDEXED:
        let inner = bracket_inner(token)
        let sidx = find_sign(inner)
        let base = substr(inner, 0, sidx)
        let offs = substr(inner, sidx, len(inner))
        let code = get_i32_or(registers, str_upper(base), -1)
        if code == -1:
            fatal(concat("unknown register in indexed operand: ", base))
        out.push(code)
        out.push(parse_offset_byte(offs))
    elif kind == OP_DIRECT:
        let inner = bracket_inner(token)
        let addr = strtol(inner, null_ptr(), 0)
        out.push((addr >> 8) & 0xFF)
        out.push(addr & 0xFF)
    else:
        let inner = bracket_inner(token)
        let sidx = find_sign(inner)
        let base = substr(inner, 0, sidx)
        let offs = substr(inner, sidx, len(inner))
        let addr = strtol(base, null_ptr(), 0)
        out.push((addr >> 8) & 0xFF)
        out.push(addr & 0xFF)
        out.push(parse_offset_byte(offs))
    out

# Builds the shared mode byte for up to 3 operands -- bits 0-1/2-3/4-5 pick
# each operand's addressing mode (0=register, 1=imm8, 2=imm16, 3=memory);
# bit 6/7 are a single INSTRUCTION-WIDE indexed/direct flag pair, not
# per-operand (NOTES.md "4-operand instructions are out of scope" explains
# why the encoding only has room for 3 addressing-mode slots plus one shared
# sub-form selector) -- sets bit 6 if any operand is `OP_INDEXED`/
# `OP_DIRECT_INDEXED`, bit 7 if any is `OP_DIRECT`/`OP_DIRECT_INDEXED`,
# mirroring `nova_assembler.py::CodeGenerator.calculate_mode_byte` exactly.
fn calculate_mode_byte(kinds: List<i32>) -> i32:
    let mut mode_byte = 0
    let mut indexed = false
    let mut direct = false
    let mut i = 0
    while i < kinds.len() and i < 3:
        let k = kinds[i]
        let mut mv = 0
        if k == OP_REG:
            mv = 0
        elif k == OP_IMM8:
            mv = 1
        elif k == OP_IMM16:
            mv = 2
        else:
            mv = 3
        mode_byte = mode_byte | (mv << (i * 2))
        if k == OP_INDEXED or k == OP_DIRECT_INDEXED:
            indexed = true
        if k == OP_DIRECT or k == OP_DIRECT_INDEXED:
            direct = true
        i += 1
    if indexed:
        mode_byte = mode_byte | 0x40
    if direct:
        mode_byte = mode_byte | 0x80
    mode_byte

# ---------------------------------------------------------------------------
# Line parsing -- mirrors `nova_assembler.py::Parser.parse_line`'s label /
# directive / instruction structure (minus macro/include/conditional
# preprocessing -- see this file's header comment).
# ---------------------------------------------------------------------------

struct AsmLine:
    blank: bool = false
    has_label: bool = false
    label: str = ""
    has_directive: bool = false
    directive: str = ""
    directive_args: List<str> = List<str>()
    has_instruction: bool = false
    instruction: str = ""
    operands: List<str> = List<str>()
    # 1-indexed line number in the original `.asm` source (`todo.md` P2 #4,
    # "source-line breakpoints"). Threaded through `parse_line`/
    # `finish_directive_line`/`finish_instruction_line` from `main`'s own
    # `raw_lines` loop index rather than tracked separately, so it can never
    # drift out of sync with which raw line actually produced this `AsmLine`.
    # Only `has_instruction` lines end up in the `.lines` sidecar (see
    # `second_pass`/`write_lines` below) -- that's what a debugger breakpoint
    # conceptually targets, not a bare label or data directive line.
    source_line: i32 = 0

fn is_directive_name(s: str) -> bool:
    s == "ORG" or s == "EQU" or s == "DB" or s == "DW" or s == "DEFSTR" or s == "DS"

# Splits a comma-separated operand list for an ordinary instruction. No
# string-literal awareness needed here (unlike directive args below) --
# instruction operands never contain quoted strings.
fn split_operands(s: str) -> List<str>:
    let mut result: List<str> = List<str>()
    if len(str_trim(s)) == 0:
        return result
    let parts = str_split(s, ",")
    let mut i = 0
    while i < parts.len():
        result.push(str_trim(parts[i]))
        i += 1
    result

# Splits directive arguments on top-level commas while respecting `"..."`
# string literals (so a `DB`/`DEFSTR` string argument's own content can
# contain a comma) -- mirrors
# `nova_assembler.py::Parser._parse_operands_with_strings`.
fn split_args_string_aware(s: str) -> List<str>:
    let mut result: List<str> = List<str>()
    let mut current: List<str> = List<str>()
    let mut in_string = false
    let mut i = 0
    while i < len(s):
        let c = s[i]
        if c == 34:
            in_string = !in_string
            current.push(chr(c))
        elif c == 44 and !in_string:
            let piece = str_trim(str_join(current, ""))
            if len(piece) > 0:
                result.push(piece)
            current = List<str>()
        else:
            current.push(chr(c))
        i += 1
    let piece = str_trim(str_join(current, ""))
    if len(piece) > 0:
        result.push(piece)
    result

fn parse_line(raw: str, source_line: i32) -> AsmLine:
    let line = str_trim(str_split(raw, ";")[0])
    if len(line) == 0:
        return AsmLine(blank = true, source_line = source_line)

    let (first_token, remainder) = split_first_token(line)
    if len(first_token) == 0:
        return AsmLine(blank = true, source_line = source_line)

    let first_upper = str_upper(first_token)

    if is_directive_name(first_upper):
        return finish_directive_line("", false, first_upper, remainder, source_line)
    if is_instruction_name(first_upper):
        return finish_instruction_line("", false, first_upper, remainder, source_line)

    let label = if str_ends_with(first_token, ":"): substr(first_token, 0, len(first_token) - 1) else: first_token
    let (tok2, rem2) = split_first_token(remainder)
    if len(tok2) == 0:
        return AsmLine(has_label = true, label = label, source_line = source_line)

    let tok2_upper = str_upper(tok2)
    if is_directive_name(tok2_upper):
        return finish_directive_line(label, true, tok2_upper, rem2, source_line)
    finish_instruction_line(label, true, tok2_upper, rem2, source_line)

fn finish_directive_line(label: str, has_label: bool, directive: str, arg_str: str, source_line: i32) -> AsmLine:
    let mut args: List<str> = List<str>()
    if len(str_trim(arg_str)) > 0:
        if directive == "DB" or directive == "DW" or directive == "DEFSTR" or directive == "DS":
            args = split_args_string_aware(arg_str)
        else:
            args.push(str_trim(arg_str))
    AsmLine(has_label = has_label, label = label, has_directive = true, directive = directive, directive_args = args, source_line = source_line)

fn finish_instruction_line(label: str, has_label: bool, instruction: str, operand_str: str, source_line: i32) -> AsmLine:
    AsmLine(has_label = has_label, label = label, has_instruction = true, instruction = instruction, operands = split_operands(operand_str), source_line = source_line)

fn is_instruction_name(s: str) -> bool:
    let (op, _ar) = build_instructions()
    op.contains(s)

fn read_lines(path: str) -> (List<str>, bool):
    let h = file_open(path, "r")
    if is_null(h):
        return (List<str>(), false)
    let content = file_read(h)
    file_close(h)
    (str_split(content, "\n"), true)

# ---------------------------------------------------------------------------
# String-literal byte decoding (DB/DEFSTR arguments) -- mirrors
# `nova_assembler.py::OperandClassifier.parse_string_literal`'s escapes.
# ---------------------------------------------------------------------------

fn parse_string_literal(lit: str) -> List<i32>:
    let content = substr(lit, 1, len(lit) - 1)
    let mut result: List<i32> = List<i32>()
    let mut i = 0
    while i < len(content):
        if content[i] == 92 and i + 1 < len(content):
            let nc = content[i + 1]
            if nc == 110:
                result.push(10)
            elif nc == 116:
                result.push(9)
            elif nc == 114:
                result.push(13)
            elif nc == 92:
                result.push(92)
            elif nc == 34:
                result.push(34)
            elif nc == 48:
                result.push(0)
            else:
                result.push(nc)
            i += 2
        else:
            result.push(content[i])
            i += 1
    result

fn is_string_literal(s: str) -> bool:
    len(s) >= 2 and s[0] == 34 and s[len(s) - 1] == 34

# ---------------------------------------------------------------------------
# Two-pass assembly.
# ---------------------------------------------------------------------------

fn instruction_size(line: AsmLine, registers: Map<str, i32>, arity: Map<str, i32>) -> i32:
    let ar = get_i32_or(arity, line.instruction, 0)
    if ar == 0:
        return 1
    let mut size = 2
    let mut i = 0
    while i < line.operands.len():
        size += operand_size(classify_operand(line.operands[i], registers))
        i += 1
    size

fn directive_size(line: AsmLine) -> i32:
    if line.directive == "DB":
        let mut size = 0
        let mut i = 0
        while i < line.directive_args.len():
            let a = line.directive_args[i]
            if is_string_literal(a):
                size += parse_string_literal(a).len()
            else:
                size += 1
            i += 1
        size
    elif line.directive == "DW":
        line.directive_args.len() * 2
    elif line.directive == "DEFSTR":
        if line.directive_args.len() > 0:
            parse_string_literal(line.directive_args[0]).len() + 1
        else:
            1
    elif line.directive == "DS":
        if line.directive_args.len() > 0:
            parse_numeric(line.directive_args[0])
        else:
            0
    else:
        0

fn first_pass(lines: List<AsmLine>, registers: Map<str, i32>, arity: Map<str, i32>) -> Map<str, i32>:
    let mut symbols: Map<str, i32> = Map<str, i32>()
    let mut loc = 0
    let mut i = 0
    while i < lines.len():
        let line = lines[i]
        if line.has_label:
            symbols.insert(line.label, loc)
        if line.has_directive:
            if line.directive == "ORG":
                if line.directive_args.len() > 0:
                    loc = strtol(line.directive_args[0], null_ptr(), 16)
            elif line.directive == "EQU":
                if line.has_label and line.directive_args.len() > 0:
                    symbols.insert(line.label, resolve_imm(str_trim(line.directive_args[0]), symbols, false, 0))
            else:
                loc += directive_size(line)
        elif line.has_instruction:
            if line.instruction != "" and !build_unimplemented().contains(line.instruction):
                loc += instruction_size(line, registers, arity)
        i += 1
    symbols

fn emit_instruction(line: AsmLine, registers: Map<str, i32>, opcodes: Map<str, i32>, arity: Map<str, i32>, unimplemented: Set<str>, symbols: Map<str, i32>, location_counter: i32, mut code: Bytes) -> Bytes:
    if unimplemented.contains(line.instruction):
        fatal(concat(line.instruction, " is not implemented on this CPU"))
    if !opcodes.contains(line.instruction):
        fatal(concat("unknown instruction: ", line.instruction))
    code.push(get_i32_or(opcodes, line.instruction, 0) as u8)
    let ar = get_i32_or(arity, line.instruction, 0)
    if ar == 0:
        return code

    # Branch-relative context for this instruction's operand encoding:
    # mnemonic identity decides *whether* symbol operands convert, the
    # absolute address of the opcode byte decides the delta base (see
    # `resolve_imm`). This mirrors `nova_assembler.py::generate_instruction`,
    # which threads `location_counter`/mnemonic through every `encode_operand`
    # call. The caller supplies the same address it records in `line_addrs`
    # so labels and PC-relative deltas agree across any number of `.org`
    # segments -- `code.len()` alone would be wrong past the first one.
    let up = str_upper(line.instruction)
    let is_branch = up == "BR" or up == "BRZ" or up == "BRNZ"
    let branch_loc = location_counter

    let mut kinds: List<i32> = List<i32>()
    let mut i = 0
    while i < line.operands.len():
        kinds.push(classify_operand(line.operands[i], registers))
        i += 1
    code.push(calculate_mode_byte(kinds) as u8)

    i = 0
    while i < line.operands.len():
        let bytes = encode_operand_bytes(line.operands[i], kinds[i], registers, symbols, is_branch, branch_loc)
        let mut j = 0
        while j < bytes.len():
            code.push(bytes[j] as u8)
            j += 1
        i += 1
    code

fn emit_directive_bytes(line: AsmLine, symbols: Map<str, i32>, mut code: Bytes) -> Bytes:
    if line.directive == "DB":
        let mut i = 0
        while i < line.directive_args.len():
            let a = line.directive_args[i]
            if is_string_literal(a):
                let vals = parse_string_literal(a)
                let mut j = 0
                while j < vals.len():
                    code.push(vals[j] as u8)
                    j += 1
            else:
                code.push(resolve_imm(a, symbols, false, 0) as u8)
            i += 1
    elif line.directive == "DW":
        let mut i = 0
        while i < line.directive_args.len():
            let v = resolve_imm(line.directive_args[i], symbols, false, 0)
            code.push(((v >> 8) & 0xFF) as u8)
            code.push((v & 0xFF) as u8)
            i += 1
    elif line.directive == "DEFSTR":
        if line.directive_args.len() > 0:
            let vals = parse_string_literal(line.directive_args[0])
            let mut j = 0
            while j < vals.len():
                code.push(vals[j] as u8)
                j += 1
        code.push(0 as u8)
    elif line.directive == "DS":
        let n = if line.directive_args.len() > 0: parse_numeric(line.directive_args[0]) else: 0
        let mut k = 0
        while k < n:
            code.push(0 as u8)
            k += 1
    code

# Returns (code, seg_starts, seg_lens, seg_offs, line_nums, line_addrs) --
# parallel lists (one entry per contiguous `ORG` segment for the first three,
# one entry per `has_instruction` source line for the last two) rather than
# a `List<(i32,i32,i32)>` of packed tuples, since this compiler's `List<T>`
# support for a tuple element type is untested territory this file has no
# reason to be the first to rely on. `seg_starts`/`seg_lens`/`seg_offs` mirror
# `nova_assembler.py::Assembler.second_pass`'s segment tracking, which
# `loader.star`'s own `.org` sidecar format directly consumes. `line_nums`/
# `line_addrs` are new (`todo.md` P2 #4, "source-line breakpoints"): for
# every `has_instruction` line, the source line number and the load address
# its first opcode byte ends up at (`seg_start + (code.len() - seg_bin_off)`,
# computed *before* that line's own bytes are emitted) -- exactly what
# `write_lines`/`debugger.star`'s new `.lines` sidecar needs to turn a
# `break :N` command into a real address. Data-only lines (`DB`/`DW`/etc.)
# and blank/label-only lines aren't recorded -- there's no instruction there
# to break *at*.
fn second_pass(lines: List<AsmLine>, registers: Map<str, i32>, opcodes: Map<str, i32>, arity: Map<str, i32>, unimplemented: Set<str>, symbols: Map<str, i32>) -> (Bytes, List<i32>, List<i32>, List<i32>, List<i32>, List<i32>):
    let mut code: Bytes = Bytes()
    let mut seg_starts: List<i32> = List<i32>()
    let mut seg_lens: List<i32> = List<i32>()
    let mut seg_offs: List<i32> = List<i32>()
    let mut line_nums: List<i32> = List<i32>()
    let mut line_addrs: List<i32> = List<i32>()
    let mut seg_start = 0
    let mut seg_bin_off = 0
    let mut i = 0
    while i < lines.len():
        let line = lines[i]
        if line.has_directive:
            if line.directive == "ORG":
                if code.len() > seg_bin_off:
                    seg_starts.push(seg_start)
                    seg_lens.push(code.len() - seg_bin_off)
                    seg_offs.push(seg_bin_off)
                if line.directive_args.len() > 0:
                    seg_start = strtol(line.directive_args[0], null_ptr(), 16)
                seg_bin_off = code.len()
            elif line.directive == "EQU":
                # already resolved in the first pass
                0
            else:
                code = emit_directive_bytes(line, symbols, code)
        elif line.has_instruction:
            line_nums.push(line.source_line)
            line_addrs.push(seg_start + (code.len() - seg_bin_off))
            code = emit_instruction(line, registers, opcodes, arity, unimplemented, symbols, seg_start + (code.len() - seg_bin_off), code)
        i += 1
    if code.len() > seg_bin_off:
        seg_starts.push(seg_start)
        seg_lens.push(code.len() - seg_bin_off)
        seg_offs.push(seg_bin_off)
    (code, seg_starts, seg_lens, seg_offs, line_nums, line_addrs)

# ---------------------------------------------------------------------------
# Output writers -- `.bin` (raw code, binary-safe via `file_write_bytes`),
# `.org` (segment table, same 3-field-per-line format `loader.star`/
# `disasm.star` already parse), `.sym` (symbol table, human-inspection only
# -- nothing in this project reads it back), `.lines` (source line ->
# address table, `todo.md` P2 #4 -- `debugger.star`'s new `break :N`
# source-line breakpoint syntax reads this back, unlike `.sym`).
# ---------------------------------------------------------------------------

fn write_bin(path: str, code: Bytes) -> bool:
    let h = file_open(path, "wb")
    if is_null(h):
        return false
    let ok = file_write_bytes(h, code)
    file_close(h)
    ok

fn write_org(path: str, seg_starts: List<i32>, seg_lens: List<i32>, seg_offs: List<i32>) -> bool:
    let h = file_open(path, "w")
    if is_null(h):
        return false
    file_write(h, "# ORG segment information\n")
    file_write(h, "# Format: <start_address> <length> <binary_offset>\n")
    let mut i = 0
    while i < seg_starts.len():
        let line: List<str> = ["0x", hex_word_str(seg_starts[i]), " ", dec_str(seg_lens[i]), " ", dec_str(seg_offs[i]), "\n"]
        file_write(h, str_join(line, ""))
        i += 1
    file_close(h)
    true

fn write_sym(path: str, symbols: Map<str, i32>, order: List<str>) -> bool:
    let h = file_open(path, "w")
    if is_null(h):
        return false
    file_write(h, "# Symbol table\n")
    file_write(h, "# Format: <symbol> <value>\n")
    for i in 0..order.len():
        let name = order[i]
        if let Option::Some(v) = symbols.get(name):
            let line: List<str> = [name, " 0x", hex_word_str(v), "\n"]
            file_write(h, str_join(line, ""))
    file_close(h)
    true

# `.lines` sidecar (`todo.md` P2 #4, "source-line breakpoints") -- one row
# per `has_instruction` source line, same plain-text/human-inspectable shape
# as `.org`/`.sym` above: `<source_line> 0x<address>`. `debugger.star`'s new
# `load_line_table` reads this back into a line->address map (`break :N`)
# and its reverse (labeling a hit/listed breakpoint with its source line),
# exactly mirroring how `load_symbol_table` already reads `.sym`.
fn write_lines(path: str, line_nums: List<i32>, line_addrs: List<i32>) -> bool:
    let h = file_open(path, "w")
    if is_null(h):
        return false
    file_write(h, "# Source line -> address table\n")
    file_write(h, "# Format: <source_line> <address>\n")
    let mut i = 0
    while i < line_nums.len():
        let line: List<str> = [dec_str(line_nums[i]), " 0x", hex_word_str(line_addrs[i]), "\n"]
        file_write(h, str_join(line, ""))
        i += 1
    file_close(h)
    true

fn hex_digit(n: i32) -> str:
    if n < 10:
        chr(48 + n)
    else:
        chr(65 + (n - 10))

fn hex_byte_str(v: i32) -> str:
    let b = v & 0xFF
    concat(hex_digit((b / 16) % 16), hex_digit(b % 16))

fn hex_word_str(v: i32) -> str:
    let w = v & 0xFFFF
    concat(hex_byte_str((w / 256) % 256), hex_byte_str(w % 256))

fn dec_str(v: i32) -> str:
    if v == 0:
        return "0"
    let mut n = v
    let mut s = ""
    while n > 0:
        s = concat(hex_digit(n % 10), s)
        n = n / 10
    s

# ---------------------------------------------------------------------------
# Validation -- run once the symbol table is complete (after `first_pass`)
# and before any bytes are emitted, so every realistic failure (an unknown
# mnemonic, an unimplemented one, an unresolvable register/symbol operand)
# is reported through a real nonzero exit code from `main` rather than
# relying on `fatal`'s print-only fallback deep inside code generation (see
# `fatal`'s own doc comment for why this two-tier design exists at all).
# ---------------------------------------------------------------------------

fn check_operand(token: str, registers: Map<str, i32>, symbols: Map<str, i32>, mut errors: List<str>) -> List<str>:
    let kind = classify_operand(token, registers)
    if kind == OP_INDIRECT or kind == OP_INDEXED:
        let inner = bracket_inner(token)
        let base = if kind == OP_INDEXED: substr(inner, 0, find_sign(inner)) else: inner
        if !registers.contains(str_upper(base)):
            errors.push(concat("unknown register in memory operand: ", token))
    elif kind == OP_IMM8 or kind == OP_IMM16:
        let is_literal = is_char_literal(token) or str_starts_with(token, "0x") or str_starts_with(token, "0X") or is_decimal_token(token)
        if !is_literal and !symbols.contains(token):
            errors.push(concat("undefined symbol: ", token))
    errors

fn check_directive_arg(a: str, symbols: Map<str, i32>, mut errors: List<str>) -> List<str>:
    let is_literal = str_starts_with(a, "0x") or str_starts_with(a, "0X") or is_decimal_token(a) or is_string_literal(a) or is_char_literal(a)
    if !is_literal and !symbols.contains(a):
        errors.push(concat("undefined symbol: ", a))
    errors

fn validate_lines(lines: List<AsmLine>, registers: Map<str, i32>, opcodes: Map<str, i32>, unimplemented: Set<str>, symbols: Map<str, i32>) -> List<str>:
    let mut errors: List<str> = List<str>()
    let mut i = 0
    while i < lines.len():
        let line = lines[i]
        if line.has_instruction:
            if unimplemented.contains(line.instruction):
                errors.push(concat(line.instruction, " is not implemented on this CPU"))
            elif !opcodes.contains(line.instruction):
                errors.push(concat("unknown instruction: ", line.instruction))
            else:
                let mut j = 0
                while j < line.operands.len():
                    errors = check_operand(line.operands[j], registers, symbols, errors)
                    j += 1
        elif line.has_directive and (line.directive == "DB" or line.directive == "DW"):
            let mut j = 0
            while j < line.directive_args.len():
                errors = check_directive_arg(line.directive_args[j], symbols, errors)
                j += 1
        i += 1
    errors

fn main() -> i32:
    let cli = args()
    if cli.len() < 2:
        println("usage: assembler <path.asm>")
        return 0

    let asm_path = cli[1]
    let (raw_lines, ok) = read_lines(asm_path)
    if !ok:
        let msg: List<str> = ["could not open '", asm_path, "'"]
        println(str_join(msg, ""))
        return 1

    let registers = build_registers()
    let (opcodes, arity) = build_instructions()
    let unimplemented = build_unimplemented()

    let mut lines: List<AsmLine> = List<AsmLine>()
    let mut label_order: List<str> = List<str>()
    let mut i = 0
    while i < raw_lines.len():
        let parsed = parse_line(raw_lines[i], i + 1)
        if !parsed.blank:
            lines.push(parsed)
            if parsed.has_label:
                label_order.push(parsed.label)
        i += 1

    let symbols = first_pass(lines, registers, arity)

    let errors = validate_lines(lines, registers, opcodes, unimplemented, symbols)
    if errors.len() > 0:
        let mut k = 0
        while k < errors.len():
            println(concat("assembler error: ", errors[k]))
            k += 1
        return 1

    let (code, seg_starts, seg_lens, seg_offs, line_nums, line_addrs) = second_pass(lines, registers, opcodes, arity, unimplemented, symbols)

    let base = str_replace(asm_path, ".asm", "")
    let bin_path = concat(base, ".bin")
    let org_path = concat(base, ".org")
    let sym_path = concat(base, ".sym")
    let lines_path = concat(base, ".lines")

    if !write_bin(bin_path, code):
        fatal(concat("could not write ", bin_path))
        return 1
    if seg_starts.len() > 0:
        write_org(org_path, seg_starts, seg_lens, seg_offs)
    write_sym(sym_path, symbols, label_order)
    write_lines(lines_path, line_nums, line_addrs)

    let summary: List<str> = ["assembled ", dec_str(code.len()), " bytes -> ", bin_path]
    println(str_join(summary, ""))
    0
