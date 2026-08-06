# Star-side half of the lexer's Python-cross-checked regression test
# (todo.md P0 #1) -- reads a `.nobasic` source file named on the command
# line, tokenizes it with `../lexer.star`, and prints one deterministic
# line per token so a shell script can diff it against a fixture generated
# from the live Python reference (`run_lexer_test.ps1` in this directory)
# -- the same "no in-language assertion facility, so dump and diff instead"
# shape `projects/nova/tests/run_bin.star` already established for the CPU
# port (see NOTES.md's "Testing" section).
#
# Usage: lexer_dump.exe path/to/source.nobasic
# (built via:
#   star build projects/nova/NoBASIC/tests/lexer_dump.star -o projects/nova/NoBASIC/tests/lexer_dump.exe
# -- a plain text-in/text-out tool, no SDL2 link needed.)

import "../lexer.star" as lex
import "../tokens.star" as tok

fn dump_escape(s: str) -> str:
    let s1 = str_replace(s, "\\", "\\\\")
    let s2 = str_replace(s1, "\n", "\\n")
    let s3 = str_replace(s2, "\r", "\\r")
    str_replace(s3, "\t", "\\t")

# Fixed 2-decimal-place formatter -- lets this dump's float output diff
# byte-for-byte against a Python `f"{sign}{whole}.{frac}"`-formatted
# fixture without fighting each language's own default float-to-string
# formatting. `fixtures/lexer_sample.nobasic`'s own numeric literals are
# deliberately chosen to have exact binary quarter-cent fractions (`.25`/
# `.5`/`.75`) so this rounds with no representation error either side.
fn format_amount(v: f64) -> str:
    let sign = if v < 0 as f64: "-" else: ""
    let av = if v < 0 as f64: -v else: v
    let scaled = (av * (100.0 as f64) + (0.5 as f64)) as i64
    let whole = scaled / (100 as i64)
    let frac = scaled % (100 as i64)
    let frac_str = if frac < (10 as i64): concat("0", f"{frac}") else: f"{frac}"
    concat(sign, concat(f"{whole}", concat(".", frac_str)))

fn dump_token(t: tok::Token) -> str:
    let kind_name = tok::token_type_name(t.kind)
    let num_str = if t.kind == tok::TokenType::NumberLiteral: format_amount(t.num_value) else: "0.00"
    let isf_str = if t.is_float: "1" else: "0"
    let str_str = dump_escape(t.str_value)
    let lexeme_str = dump_escape(t.lexeme)
    f"{t.line}:{t.column} {kind_name} lexeme=\"{lexeme_str}\" num={num_str} isf={isf_str} str=\"{str_str}\""

fn main() -> i32:
    let cli = args()
    if cli.len() < 2:
        println("usage: lexer_dump <path.nobasic>")
        return 1
    let path = cli[1]
    let h = file_open(path, "r")
    if is_null(h):
        println(concat("could not open '", concat(path, "'")))
        return 1
    let source = file_read(h)
    file_close(h)

    match lex::lex(source, path):
        Result::Ok(tokens) ->
            let mut i = 0
            while i < tokens.len():
                println(dump_token(tokens[i]))
                i += 1
            return 0
        Result::Err(e) ->
            println(concat("LEX ERROR: ", lex::format_lex_error(e)))
            return 1
    0
