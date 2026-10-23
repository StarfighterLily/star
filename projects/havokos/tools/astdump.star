# AST dump, Star side of the M2 golden comparison (todo.md HavokOS M2).
# `ref_astdump.pike` in this directory produces the same format from the
# live Pike reference (`preprocess.pike` -> `lexer.pike` -> `parser.pike`);
# `tests/run_astdump_test.ps1` diffs the two. The canonical node format is
# documented in `ast.star` ("Canonical dump").
#
# Usage:
#   astdump.exe <mudlib_root> <file_list.txt>   one summary line per vpath:
#       "<vpath> OK <ntoplevel> <fnv32>" or "<vpath> FAIL"
#   astdump.exe <mudlib_root> -v <vpath>        every top-level node of one file
# A trailing `-nolines` drops every "line" key.
#
# The summary hash is FNV-1a (32-bit) over each top-level node's line plus
# "\n", the same hash `tokdump.star` uses.
#
# Build: star build projects/havokos/tools/astdump.star -o projects/havokos/tools/astdump.exe

import "../preprocess.star" as pre
import "../token.star" as tk
import "../parser.star" as ps
import "../ast.star" as ast

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
        println("usage: astdump <mudlib_root> <file_list.txt> | <mudlib_root> -v <vpath>")
        return 2
    let mut pp = pre::new_pp(cli[1])
    let with_lines = cli[cli.len() - 1] != "-nolines"
    if cli[2] == "-v":
        pp.preprocess(cli[3])
        if pp.had_error:
            println(f"FAIL {pp.error}")
            return 1
        let b = first_bad(pp.out)
        if b >= 0:
            println(f"FAIL lex {pp.out[b].text} at line {pp.out[b].line}")
            return 1
        let p = ps::parse_tokens(pp.out, pp.files)
        if p.had_error:
            println(f"FAIL {p.error}")
            return 1
        let lines = ast::dump_program(p.nodes, p.top, pp.files, with_lines)
        for i in 0..lines.len():
            println(lines[i])
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
        let p = ps::parse_tokens(pp.out, pp.files)
        if p.had_error:
            println(f"{vpath} FAIL")
            continue
        let lines = ast::dump_program(p.nodes, p.top, pp.files, with_lines)
        println(f"{vpath} OK {lines.len()} {fnv(lines)}")
    0
