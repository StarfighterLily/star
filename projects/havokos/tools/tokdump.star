# Post-preprocessing token dump, Star side of the M1 golden comparison
# (todo.md HavokOS M1). `ref_tokdump.pike` in this directory produces the
# same format from the live Pike reference (`preprocess.pike` ->
# `lexer.pike::tokenize`); `run_tokdump_test.ps1` diffs the two.
#
# Usage:
#   tokdump.exe <mudlib_root> <file_list.txt>   one summary line per vpath:
#       "<vpath> OK <ntokens> <fnv32>" or "<vpath> FAIL"
#   tokdump.exe <mudlib_root> -v <vpath>        every token of one file
# A trailing `-nolines` drops line numbers from the canonical lines (see
# lexer.star's "Deliberate deviation" note for which files need it).
#
# Canonical token line: "<file>:<line> <kind> <value>", where `value` is the
# identifier/operator text, decimal int, `(int)(float * 1e6)`, `$` number, or
# a string with `\\`, `\n`, `\t`, `\r` and `\xNN` (any other byte < 32 or
# >= 127) escapes. Adjacent string tokens are merged first (keeping the
# first's position): the reference splits a string containing a raw newline
# into adjacent literals, this port doesn't, and the parser joins adjacent
# literals either way. The summary hash is FNV-1a (32-bit) over every
# canonical line plus "\n", end-of-file token included.
#
# Build: star build projects/havokos/tools/tokdump.star -o projects/havokos/tools/tokdump.exe

import "../preprocess.star" as pre
import "../token.star" as tk

fn hex2(v: i32) -> str:
    let digits = "0123456789abcdef"
    let d = bytes_from_str(digits)
    let mut w: Bytes = Bytes()
    w.push(d[v / 16])
    w.push(d[v % 16])
    str_from_bytes(w)

fn escape(s: str) -> str:
    let b = bytes_from_str(s)
    let mut w: Bytes = Bytes()
    for i in 0..b.len():
        let c = b[i] as i32
        if c == 92:
            w.push(92 as u8)
            w.push(92 as u8)
        elif c == 10:
            w.push(92 as u8)
            w.push(110 as u8)
        elif c == 9:
            w.push(92 as u8)
            w.push(116 as u8)
        elif c == 13:
            w.push(92 as u8)
            w.push(114 as u8)
        elif c < 32 or c >= 127:
            let h = bytes_from_str(concat("\\x", hex2(c)))
            for k in 0..h.len():
                w.push(h[k])
        else:
            w.push(b[i])
    str_from_bytes(w)

fn value_of(t: tk::Token) -> str:
    match t.kind:
        tk::Tk::Int -> f"{t.ival}"
        tk::Tk::Float -> f"{(t.fval * (1000000.0 as f64)) as i64}"
        tk::Tk::Str -> escape(t.text)
        tk::Tk::Dollar -> f"{t.ival}"
        tk::Tk::Eof -> "0"
        _ -> t.text

# Canonical lines for a token stream, adjacent strings merged.
fn dump_lines(pp: pre::Pp, toks: List<tk::Token>, with_lines: bool) -> List<str>:
    let mut lines: List<str> = List<str>()
    let mut i = 0
    while i < toks.len():
        let t = toks[i]
        let mut text = t.text
        if t.kind == tk::Tk::Str:
            let mut parts: List<str> = [t.text]
            while i + 1 < toks.len() and toks[i + 1].kind == tk::Tk::Str:
                i += 1
                parts.push(toks[i].text)
            text = str_join(parts, "")
        let shown = tk::Token(kind = t.kind, text = text, ival = t.ival, fval = t.fval)
        let pos = if with_lines: f"{pp.files[t.file]}:{t.line}" else: pp.files[t.file]
        lines.push(f"{pos} {tk::tk_name(t.kind)} {value_of(shown)}")
        i += 1
    lines

fn fnv(lines: List<str>) -> i64:
    let mask = (65536 as i64) * (65536 as i64) - (1 as i64)
    let mut h = 2166136261 as i64
    for i in 0..lines.len():
        let b = bytes_from_str(lines[i])
        for k in 0..b.len():
            h = ((h ^ (b[k] as i64)) * (16777619 as i64)) & mask
        h = ((h ^ (10 as i64)) * (16777619 as i64)) & mask
    h

fn first_bad(toks: List<tk::Token>) -> i32:
    for i in 0..toks.len():
        if toks[i].kind == tk::Tk::Bad:
            return i
    -1

fn main() -> i32:
    let cli = args()
    if cli.len() < 3:
        println("usage: tokdump <mudlib_root> <file_list.txt> | <mudlib_root> -v <vpath>")
        return 2
    let mut pp = pre::new_pp(cli[1])
    let with_lines = cli[cli.len() - 1] != "-nolines"
    if cli[2] == "-v":
        pp.preprocess(cli[3])
        if pp.had_error:
            println(f"FAIL {pp.error}")
            return 1
        let lines = dump_lines(pp, pp.out, with_lines)
        for i in 0..lines.len():
            println(lines[i])
        let b = first_bad(pp.out)
        if b >= 0:
            println(f"FAIL lex {pp.out[b].text} at line {pp.out[b].line}")
        return 0
    let f = file_open(cli[2], "rb")
    if is_null(f):
        println("cannot open file list")
        return 2
    let list = str_split(str_from_bytes(file_read_bytes(f)), "\n")
    file_close(f)
    for i in 0..list.len():
        let vpath = str_trim(list[i])
        if vpath == "":
            continue
        pp.preprocess(vpath)
        if pp.had_error or first_bad(pp.out) >= 0:
            println(f"{vpath} FAIL")
            continue
        let lines = dump_lines(pp, pp.out, with_lines)
        println(f"{vpath} OK {lines.len()} {fnv(lines)}")
    0
