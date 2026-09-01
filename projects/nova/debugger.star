# Nova-16 debugger -- a headless CLI REPL (step/breakpoints/register-and-
# memory inspection/disassembly), matching a piece of the upstream Python
# toolchain's own tooling (`nova_debugger.py`) that `readme.md`'s "Versioning"
# section names as part of "tooling to match Python reference" for the
# language-wide `0.1.0` gate (todo.md P2 #3). The other named-tooling gap,
# GUI+controls parity, is addressed separately in `main.star`.
#
# Command set is a deliberate, close port of `nova_debugger.py::NovaDebugger
# ::handle_command` -- step/s, run/continue/cont, regs/r, mem, stack,
# disasm/d, break/b, breakpoints/bp, clear/c, load, help/h/?, quit/q/exit --
# see each command's own comment below for anywhere this port's behavior
# deliberately differs. Not ported: the Python CLI's `--steps N` startup
# flag (auto-step N instructions before entering the REPL) -- the REPL's own
# `step N` command already covers this interactively, and argument-parsing
# machinery for one convenience flag isn't worth its own surface here.
#
# Deliberately duplicates a handful of small helpers from `disasm.star`
# (`hex_digit`/`hex_byte`/`hex_word`/`dec_str`/`format_offset`/`reg_name`/
# `opcode_info`/`format_operand`/`disassemble_one`) and `assembler.star`
# (`is_ws_byte`/`ltrim`/`split_first_token`) rather than importing either
# file directly -- both are themselves standalone build targets with their
# own `fn main()`, and this project's codegen lowers every top-level `fn
# main()` to the single, real `@main` LLVM symbol regardless of which
# source file declares it (`src/codegen/stmt.rs`'s `is_main` check only
# looks at the function's own name, not which file is the build's actual
# entry point) -- importing either file here would collide two `@main`
# definitions in one linked program. `disasm.star`'s own header comment
# already established the same "keep this tool's own link/dependency
# footprint independent" precedent for a smaller case (duplicating
# `loader.star`'s `parse_org_line`); this is the same call, just for a
# bigger table, and for a real structural reason (the double-`main` hazard)
# rather than just footprint hygiene. The disassembly tables below are
# transcribed verbatim from `disasm.star`, not re-derived -- see that file's
# own header comment for how they were originally cross-checked against
# `cpu.star`.
#
# Build (needs SDL2 linked even though this tool never opens a window --
# `cpu.star` transitively pulls in `sound.star`'s audio builtins for
# SPLAY/SSTOP/STRIG, the same reason `tests/run_bin.star`/`uart_bridge.star`
# both need it too):
#   star build projects/nova/debugger.star -L sdl/lib/x64 -l SDL2 -o projects/nova/debugger.exe
#
# Usage: debugger.exe [path/to/program.bin]
# A `.sym` sidecar next to the given `.bin` (produced by `assembler.star`,
# see its own "Assembler" section in NOTES.md) is loaded automatically, if
# present, to label addresses in disassembly/breakpoint output by symbol
# name -- matching `nova_debugger.py::load_symbol_table`'s own behavior.
#
# `break`/`b`/`clear`/`c` also accept `:<line>` (`todo.md` P2 #4, "source-
# line breakpoints") -- a source line number instead of a raw address,
# resolved through a `.lines` sidecar next to the `.bin` (also produced by
# `assembler.star`, `write_lines`, loaded the same automatic way as `.sym`).
# There is no upstream `nova_debugger.py` behavior to match here (its own
# breakpoints are address-only too) -- this is a genuine addition, not a
# port. `breakpoints`/`bp` and a breakpoint hit during `run`/`continue` both
# label their address with `[line N]` when the `.lines` table has one,
# alongside the existing `(symbol)` label.

import "bits.star" as bits
import "cpu.star" as cpu
import "cpu_data.star" as cpu_data
import "cpu_arith.star" as cpu_arith
import "cpu_math.star" as cpu_math
import "cpu_bitwise.star" as cpu_bitwise
import "cpu_stack.star" as cpu_stack
import "cpu_control.star" as cpu_control
import "cpu_mem.star" as cpu_mem
import "cpu_graphics.star" as cpu_graphics
import "cpu_io.star" as cpu_io
import "cpu_sound.star" as cpu_sound
import "cpu_string.star" as cpu_string
import "memory.star" as mem
import "screen.star" as screen
import "keyboard.star" as keyboard
import "flags.star" as flg
import "loader.star" as loader
import "uart.star" as uart

# `atoi`/`strtol` come from `loader.star`'s own `extern "C"` declarations --
# already visible transitively through the `import "loader.star"` above,
# matching `uart_bridge.star`/`disasm.star`'s identical reuse (a second
# declaration here would conflict with theirs).
extern "C" fn fflush(stream: ptr) -> i32

# Identical to `tests/run_bin.star::new_cpu` / `uart_bridge.star::new_cpu` /
# `main.star::main`'s inline `Cpu` construction -- see `loader.star`'s header
# comment for why this project never factors this into a shared constructor
# (a large struct deliberately never passed around by value; each of this
# project's four build targets that construct one duplicates the literal
# instead).
fn new_cpu() -> cpu::Cpu:
    cpu::Cpu(
        mem = mem::new_memory(),
        screen = screen::new_screen(),
        kbd = keyboard::Keyboard(buffer = [0 as u8; 64], head = 0, tail = 0, count = 0, status = 0 as u8, control = 0 as u8, debounce_ms = keyboard::DEFAULT_DEBOUNCE_MS, last_press = [-1; 256], repeat_armed = [false; 256], repeat_down_time = [0; 256], repeat_last = [0; 256]),
        flags = flg::Flags(bits = BitField<16>(0)),
        uart = uart::new_uart(),
        r = [Wrapping<u8>(0 as u8); 10],
        # SP (P8)/FP (P9) reset to 0xFFFF, matching `main.star`'s identical
        # fix -- see its own comment on this same field for the full bug
        # writeup (found via this file's own `stack` command).
        p = [
            Wrapping<u16>(0 as u16), Wrapping<u16>(0 as u16), Wrapping<u16>(0 as u16),
            Wrapping<u16>(0 as u16), Wrapping<u16>(0 as u16), Wrapping<u16>(0 as u16),
            Wrapping<u16>(0 as u16), Wrapping<u16>(0 as u16),
            Wrapping<u16>(0xFFFF as u16), Wrapping<u16>(0xFFFF as u16),
        ],
        pc = Wrapping<u16>(0 as u16),
        vx = Wrapping<u8>(0 as u8),
        vy = Wrapping<u8>(0 as u8),
        vc = Wrapping<u8>(0 as u8),
        vm = 0 as u8,
        vl = 0 as u8,
        tt = Wrapping<u8>(0 as u8),
        tm = Wrapping<u8>(0 as u8),
        tc = Wrapping<u8>(0 as u8),
        ts = Wrapping<u8>(0 as u8),
        timer_subcycle = 0,
        pending_timer_irq = false,
        sa = Wrapping<u16>(0 as u16),
        sf = Wrapping<u8>(0 as u8),
        sv = Wrapping<u8>(0 as u8),
        sw = Wrapping<u8>(0 as u8),
        next_strig_channel = 8,
        sound_channel_handles = [null_ptr(); 16],
        sound_channel_last_wav = cpu::new_channel_wav_cache(),
        mx = Wrapping<u8>(0 as u8),
        my = Wrapping<u8>(0 as u8),
        mb = Wrapping<u8>(0 as u8),
        mouse_enabled = false,
        mouse_pending_irq = false,
        c0 = Wrapping<u16>(0 as u16),
        c1 = Wrapping<u16>(0 as u16),
        halted = false,
        cycles = 0 as i64,
    )

# ---------------------------------------------------------------------------
# String helpers, duplicated from `assembler.star` (see this file's header
# comment for why). Only what the REPL's own command-line tokenizing needs.
# ---------------------------------------------------------------------------

fn is_ws_byte(c: i32) -> bool:
    c == 32 or c == 9 or c == 13

fn substr(s: str, start: i32, end: i32) -> str:
    let mut parts: List<str> = List<str>()
    let mut i = start
    while i < end:
        parts.push(chr(s[i]))
        i += 1
    str_join(parts, "")

fn ltrim(s: str) -> str:
    let mut i = 0
    while i < len(s) and is_ws_byte(s[i]):
        i += 1
    substr(s, i, len(s))

# Splits off the first whitespace-delimited token. Returns (token, rest),
# `rest` trimmed of its own leading/trailing whitespace.
fn split_first_token(s: str) -> (str, str):
    let t = ltrim(s)
    let mut i = 0
    while i < len(t) and !is_ws_byte(t[i]):
        i += 1
    let token = substr(t, 0, i)
    let rest = str_trim(substr(t, i, len(t)))
    (token, rest)

# ---------------------------------------------------------------------------
# Disassembly tables, transcribed verbatim from `disasm.star` (see this
# file's header comment for why they're duplicated rather than imported).
# ---------------------------------------------------------------------------

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

fn format_offset(off: i32) -> str:
    if off < 0:
        concat("-", dec_str(0 - off))
    else:
        concat("+", dec_str(off))

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
    let operand_text = str_join(parts, ", ")
    let whole: List<str> = [mnem, operand_text]
    (str_join(whole, " "), p, true)

# ---------------------------------------------------------------------------
# Symbol table (.sym sidecar, written by `assembler.star`'s `write_sym`) --
# only the address -> name reverse direction is needed here (labeling
# disassembly/breakpoint output); nothing in this tool looks a symbol up by
# name (there's no "break <label>" command, matching `nova_debugger.py`,
# which only ever breaks by numeric address too).
# ---------------------------------------------------------------------------

fn load_symbol_table(sym_path: str) -> Map<i32, str>:
    let mut reverse: Map<i32, str> = Map<i32, str>()
    let h = file_open(sym_path, "r")
    if is_null(h):
        return reverse
    let content = file_read(h)
    file_close(h)
    let lines = str_split(content, "\n")
    let mut li = 0
    while li < lines.len():
        let line = str_trim(lines[li])
        if len(line) > 0 and !str_starts_with(line, "#"):
            let (name, rest) = split_first_token(line)
            if len(rest) > 0:
                let value = strtol(rest, null_ptr(), 0)
                reverse.insert(value, name)
        li += 1
    reverse

fn symbol_suffix(addr: i32, reverse_syms: Map<i32, str>) -> str:
    if let Option::Some(name) = reverse_syms.get(addr):
        return f" ({name})"
    ""

# ---------------------------------------------------------------------------
# Line table (.lines sidecar, written by `assembler.star`'s `write_lines`,
# `todo.md` P2 #4 "source-line breakpoints") -- unlike the symbol table
# above, *both* directions are needed: `line_to_addr` turns a `break :N`
# command into a real address, `addr_to_line` labels a hit/listed breakpoint
# (and the current instruction) with its source line the same way
# `symbol_suffix` already labels one with its symbol name.
# ---------------------------------------------------------------------------

fn load_line_table(lines_path: str) -> (Map<i32, i32>, Map<i32, i32>):
    let mut line_to_addr: Map<i32, i32> = Map<i32, i32>()
    let mut addr_to_line: Map<i32, i32> = Map<i32, i32>()
    let h = file_open(lines_path, "r")
    if is_null(h):
        return (line_to_addr, addr_to_line)
    let content = file_read(h)
    file_close(h)
    let lines = str_split(content, "\n")
    let mut li = 0
    while li < lines.len():
        let line = str_trim(lines[li])
        if len(line) > 0 and !str_starts_with(line, "#"):
            let (num_tok, rest) = split_first_token(line)
            if len(rest) > 0:
                let line_num = atoi(num_tok)
                let addr = strtol(rest, null_ptr(), 0)
                line_to_addr.insert(line_num, addr)
                addr_to_line.insert(addr, line_num)
        li += 1
    (line_to_addr, addr_to_line)

fn line_suffix(addr: i32, addr_to_line: Map<i32, i32>) -> str:
    if let Option::Some(n) = addr_to_line.get(addr):
        return f" [line {n}]"
    ""

# Resolves a `break`/`clear` command's location argument: `:N` looks up
# source line `N` in `line_to_addr` (`ok=false` if that line never emitted
# an instruction -- e.g. a label-only or data-directive line, or a line
# number outside the source entirely); anything else is a plain address,
# parsed and wrapped into `[0, 65_536)` exactly like this command's own
# address-only parsing always has.
fn parse_break_location(rest: str, line_to_addr: Map<i32, i32>) -> (i32, bool):
    if str_starts_with(rest, ":"):
        let line_num = atoi(substr(rest, 1, len(rest)))
        match line_to_addr.get(line_num):
            Option::Some(addr) -> (addr, true)
            Option::None -> (0, false)
    else:
        let addr = ((strtol(rest, null_ptr(), 0) % 65_536) + 65_536) % 65_536
        (addr, true)

# ---------------------------------------------------------------------------
# Cpu-inspecting commands, as methods (via a cross-module `impl`, matching
# `loader.star`/`uart_bridge.star`'s own precedent) rather than free
# functions taking `Cpu` as an ordinary parameter -- `Cpu` is the one large
# struct this project deliberately never passes around by value (see
# `loader.star`'s header comment), and `print_disasm`/`step` below are called
# once per instruction in a multi-step "step N" loop, where a real per-call
# whole-struct copy would actually matter.
# ---------------------------------------------------------------------------

impl cpu::Cpu:
    # Snapshots exactly `length` bytes starting at `start` into a fresh
    # `Bytes` -- `disassemble_one` needs a `Bytes`, not a live `Memory`
    # view, but there's no reason to ever snapshot the whole 64KB address
    # space just to disassemble a handful of instructions around one
    # address, so callers size this to what they actually need (a small
    # fixed window per instruction shown) rather than `self.mem`'s full
    # width -- the difference matters directly for "step N": snapshotting
    # 64KB per single-instruction print would make an N-instruction step
    # O(N * 65_536) instead of O(N * window).
    fn mem_window(self, start: i32, length: i32) -> Bytes:
        let mut b: Bytes = Bytes()
        let mut i = 0
        while i < length:
            b.push(self.mem.read_byte(start + i))
            i += 1
        b

    # Disassembles and prints up to `count` instructions starting at
    # `start`, labeling each address with its symbol name if `reverse_syms`
    # has one -- shared by the `disasm`/`d` command and by every "show me
    # the current instruction" spot (single-step, `run`/breakpoint-hit,
    # `load`) that `nova_debugger.py` calls a separate `print_current_
    # instruction` for; there's no behavioral difference here between
    # "the current instruction" and "a 1-instruction disassembly listing
    # starting at PC", so this port doesn't duplicate the two.
    fn print_disasm(self, start: i32, count: i32, reverse_syms: Map<i32, str>):
        let window_len = count * 12 + 16
        let window = self.mem_window(start, window_len)
        let mut pos = 0
        let mut addr = start
        let mut i = 0
        while i < count and pos < window.len():
            let start_pos = pos
            let (text, new_pos, ok) = disassemble_one(window, pos)
            let mut raw = ""
            let mut k = start_pos
            while k < new_pos:
                raw = f"{raw}{hex_byte(window[k] as i32)} "
                k += 1
            println(f"0x{hex_word(addr)}:{symbol_suffix(addr, reverse_syms)}  {raw}{text}")
            if !ok:
                break
            addr = addr + (new_pos - start_pos)
            pos = new_pos
            i += 1

    fn dump_registers(self):
        println(f"PC: 0x{hex_word((self.pc as u16) as i32)}")
        let mut r_line = "R0-R9:"
        let mut i = 0
        while i < 10:
            r_line = f"{r_line} R{i}:0x{hex_byte((self.r[i] as u8) as i32)}"
            i += 1
        println(r_line)
        let mut p_line = "P0-P9:"
        i = 0
        while i < 10:
            p_line = f"{p_line} P{i}:0x{hex_word((self.p[i] as u16) as i32)}"
            i += 1
        println(p_line)
        println(f"VM: 0x{hex_byte(self.vm as i32)} VX: 0x{hex_byte((self.vx as u8) as i32)} VY: 0x{hex_byte((self.vy as u8) as i32)} VL: 0x{hex_byte(self.vl as i32)} VC: 0x{hex_byte((self.vc as u8) as i32)}")
        println(f"SA: 0x{hex_word((self.sa as u16) as i32)} SF: 0x{hex_byte((self.sf as u8) as i32)} SV: 0x{hex_byte((self.sv as u8) as i32)} SW: 0x{hex_byte((self.sw as u8) as i32)}")
        println(f"TT: 0x{hex_byte((self.tt as u8) as i32)} TM: 0x{hex_byte((self.tm as u8) as i32)} TC: 0x{hex_byte((self.tc as u8) as i32)} TS: 0x{hex_byte((self.ts as u8) as i32)}")
        println(f"FLAGS: T={self.flags.t()} S={self.flags.s()} O={self.flags.o()} B={self.flags.b()} D={self.flags.d()} I={self.flags.i()} C={self.flags.c()} Z={self.flags.z()} P={self.flags.p()} H={self.flags.h()} A={self.flags.a()} E={self.flags.e()}")

    # SP/FP are P8/P9 under different names, not separate storage --
    # `cpu.star::get_reg_value`/`set_reg_value`'s 0xFB/0xFC arms both read/
    # write `self.p[8]`/`self.p[9]` directly (NOTES.md "One flat register-
    # code address space"), matching `core/regfile.py`'s own aliasing and
    # `nova_debugger.py::print_stack`'s own `self.cpu.Pregisters[8]`/`[9]`.
    fn dump_stack(self):
        let sp = (self.p[8] as u16) as i32
        let fp = (self.p[9] as u16) as i32
        println("Stack:")
        println(f"  SP: 0x{hex_word(sp)} (stack pointer)")
        println(f"  FP: 0x{hex_word(fp)} (frame pointer)")
        let mut entries: List<str> = List<str>()
        let mut addr = sp
        let mut i = 0
        while i < 16 and addr <= 0xFFFF:
            let val = self.mem.read_word(addr) as i32
            entries.push(concat("0x", hex_word(val)))
            addr = addr + 2
            i += 1
        if entries.len() > 0:
            println("  Stack contents (top to bottom):")
            println(concat("  ", str_join(entries, " ")))
        else:
            println("  (empty or invalid SP)")

    fn print_mem_dump(self, addr: i32, count: i32):
        println(f"Memory dump at 0x{hex_word(addr)}:")
        let mut i = 0
        while i < count:
            let mut hex_line = ""
            let mut ascii_line = ""
            let mut j = 0
            while j < 8:
                if i + j < count:
                    let b = self.mem.read_byte(addr + i + j) as i32
                    hex_line = f"{hex_line}{hex_byte(b)} "
                    if b >= 32 and b <= 126:
                        ascii_line = concat(ascii_line, chr(b))
                    else:
                        ascii_line = concat(ascii_line, ".")
                else:
                    hex_line = concat(hex_line, "   ")
                    ascii_line = concat(ascii_line, " ")
                j += 1
            println(f"  0x{hex_word(addr + i)}: {hex_line} {ascii_line}")
            i += 8

# NOTE: a single `println` call with an embedded `"""..."""` triple-quoted
# literal (new in Star after this file was written) was tried here in place
# of the 14 separate calls below, and reverted. It reproduced a real bug:
# in the *full* debugger.exe binary (not in an isolated one-function repro
# of the exact same string), each embedded newline in the ~670-byte string
# constant came out as `\r\r\n` (doubled CR) instead of `\r\n` when printed
# -- confirmed via a raw byte dump of captured stdout, and independent of
# how the binary is invoked (PowerShell `Start-Process` file redirection
# and a plain Bash pipe both show it). The generated LLVM IR's own string
# constant is correct (single `\0A` per line); the corruption happens at
# runtime, after `printf`, right where the compiler emits a
# `star_rc_release` call on the (statically-tagged, refcount-header `-1`)
# format-string pointer passed straight to `printf` for a non-f-string
# `println` argument -- consistent with a use-after-free/lifetime bug
# specific to large triple-quoted string constants in that code path, not
# something this file can work around. Left as 14 plain calls, each
# reliably one `\r\n`-terminated line; worth a dedicated compiler-side
# investigation (`src/codegen/builtins.rs::emit_print_like`) before trying
# a triple-quoted literal here again.
fn print_help():
    println("Commands:")
    println("  step, s           Step one instruction")
    println("  step <n>, s <n>   Step <n> instructions")
    println("  run, continue     Run until breakpoint or halt")
    println("  disasm [addr] [n] Show disassembly (default: PC, 5 instructions)")
    println("  break <addr>, b   Set breakpoint at address (hex/decimal), or :<line> for a source line")
    println("  clear <addr>, c   Clear breakpoint at address, or :<line> for a source line")
    println("  breakpoints, bp   List all breakpoints")
    println("  regs, r           Show CPU registers")
    println("  mem <addr>        Show memory at <addr>")
    println("  stack             Show stack contents")
    println("  load <file>       Load a binary file into memory")
    println("  quit, q, exit     Exit debugger")
    println("  help, h, ?        Show this help")

fn main():
    let cli = args()
    let mut c = new_cpu()
    let mut reverse_symbols: Map<i32, str> = Map<i32, str>()
    let mut line_to_addr: Map<i32, i32> = Map<i32, i32>()
    let mut addr_to_line: Map<i32, i32> = Map<i32, i32>()
    let mut breakpoints: [bool; 65_536] = [false; 65_536]

    if cli.len() > 1:
        let bin_path = cli[1]
        let (ep, ok) = c.load_program(bin_path)
        if ok:
            c.pc = Wrapping<u16>(ep as u16)
            println(f"Loaded '{bin_path}' at entry point 0x{hex_word(ep)}")
            reverse_symbols = load_symbol_table(str_replace(bin_path, ".bin", ".sym"))
            let (l2a, a2l) = load_line_table(str_replace(bin_path, ".bin", ".lines"))
            line_to_addr = l2a
            addr_to_line = a2l
        else:
            println(f"nova-debugger: could not open '{bin_path}'")
    else:
        println("No program loaded. You can still inspect/step the CPU.")

    println("Nova-16 Debugger CLI. Type 'help' for commands.")

    let mut running = true
    while running:
        print("(nova-debug) ")
        fflush(null_ptr())
        let line = read_line()
        if len(line) == 0:
            println("")
            running = false
        else:
            let (cmd, rest) = split_first_token(line)
            if cmd == "q" or cmd == "quit" or cmd == "exit":
                running = false
            elif cmd == "s" or cmd == "step":
                if len(rest) == 0:
                    c.step()
                    c.print_disasm((c.pc as u16) as i32, 1, reverse_symbols)
                    c.dump_registers()
                    c.dump_stack()
                    println("Stepped one instruction.")
                else:
                    let n = atoi(rest)
                    println(f"Stepping {n} instructions...")
                    let mut i = 0
                    while i < n:
                        c.step()
                        println(f"Step {i + 1}/{n}: PC=0x{hex_word((c.pc as u16) as i32)}")
                        c.print_disasm((c.pc as u16) as i32, 1, reverse_symbols)
                        i += 1
                    c.dump_registers()
                    c.dump_stack()
            elif cmd == "r" or cmd == "regs" or cmd == "registers":
                c.dump_registers()
            elif cmd == "mem":
                if len(rest) == 0:
                    println("Usage: mem <address>")
                else:
                    let addr = strtol(rest, null_ptr(), 0)
                    c.print_mem_dump(addr, 16)
            elif cmd == "stack":
                c.dump_stack()
            elif cmd == "disasm" or cmd == "d":
                let mut addr = (c.pc as u16) as i32
                let mut count = 5
                if len(rest) > 0:
                    let (a1, rest2) = split_first_token(rest)
                    addr = strtol(a1, null_ptr(), 0)
                    if len(rest2) > 0:
                        count = atoi(rest2)
                c.print_disasm(addr, count, reverse_symbols)
            elif cmd == "break" or cmd == "b":
                if len(rest) == 0:
                    println("Usage: break <address> or b <address>, or break :<line>")
                else:
                    let (addr, ok) = parse_break_location(rest, line_to_addr)
                    if ok:
                        breakpoints[addr] = true
                        println(f"Breakpoint set at 0x{hex_word(addr)}{symbol_suffix(addr, reverse_symbols)}{line_suffix(addr, addr_to_line)}")
                    else:
                        println(f"No code at line {rest}")
            elif cmd == "breakpoints" or cmd == "bp":
                let mut any_bp = false
                for scan in 0..65_536:
                    if breakpoints[scan]:
                        any_bp = true
                if any_bp:
                    println("Breakpoints:")
                    for addr in 0..65_536:
                        if breakpoints[addr]:
                            println(f"  0x{hex_word(addr)}{symbol_suffix(addr, reverse_symbols)}{line_suffix(addr, addr_to_line)}")
                else:
                    println("No breakpoints set")
            elif cmd == "clear" or cmd == "c":
                if len(rest) == 0:
                    println("Usage: clear <address> or c <address>, or clear :<line>")
                else:
                    let (addr, ok) = parse_break_location(rest, line_to_addr)
                    if !ok:
                        println(f"No code at line {rest}")
                    elif breakpoints[addr]:
                        breakpoints[addr] = false
                        println(f"Breakpoint cleared at 0x{hex_word(addr)}{symbol_suffix(addr, reverse_symbols)}{line_suffix(addr, addr_to_line)}")
                    else:
                        println(f"No breakpoint at 0x{hex_word(addr)}")
            elif cmd == "run" or cmd == "continue" or cmd == "cont":
                # Deliberate improvement over `nova_debugger.py::run_until_
                # breakpoint`, which checks its own just-hit breakpoint
                # *before* stepping on every call -- resuming from a
                # breakpoint with "run" re-hits the same address
                # immediately, without ever executing anything, unless the
                # user manually "step"s off it first. Stepping at least
                # once before the first breakpoint check (matching what
                # every real debugger's "continue" does) fixes that; see
                # NOTES.md's "What to carry back to the Python emulator"
                # for this filed as an upstream issue.
                println("Running until breakpoint...")
                let mut steps = 0
                let max_steps = 1_000_000
                let mut going = true
                while going:
                    c.step()
                    steps += 1
                    if breakpoints[(c.pc as u16) as i32]:
                        let hit_addr = (c.pc as u16) as i32
                        println(f"Breakpoint hit at 0x{hex_word(hit_addr)}{symbol_suffix(hit_addr, reverse_symbols)}{line_suffix(hit_addr, addr_to_line)}")
                        c.print_disasm(hit_addr, 1, reverse_symbols)
                        going = false
                    elif c.halted:
                        println("Program halted")
                        going = false
                    elif steps >= max_steps:
                        println(f"Stopped after {max_steps} steps (possible infinite loop)")
                        going = false
                c.dump_registers()
                c.dump_stack()
            elif cmd == "load":
                if len(rest) == 0:
                    println("Usage: load <filename>")
                else:
                    let (ep, ok) = c.load_program(rest)
                    if ok:
                        c.pc = Wrapping<u16>(ep as u16)
                        println(f"Loaded {rest} at entry point 0x{hex_word(ep)}")
                        reverse_symbols = load_symbol_table(str_replace(rest, ".bin", ".sym"))
                        let (l2a, a2l) = load_line_table(str_replace(rest, ".bin", ".lines"))
                        line_to_addr = l2a
                        addr_to_line = a2l
                        c.print_disasm((c.pc as u16) as i32, 1, reverse_symbols)
                        c.dump_registers()
                    else:
                        println(f"Error loading file: could not open '{rest}'")
            elif cmd == "h" or cmd == "help" or cmd == "?":
                print_help()
            else:
                println("Unknown command. Type 'help' for a list of commands.")
