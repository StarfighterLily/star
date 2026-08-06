# Star-side driver for the codegen core's verification (todo.md P1 #1) --
# compiles one `.nobasic` file all the way through lex -> parse -> semantic
# analysis -> codegen with `../lexer.star`/`../parser.star`/`../semantic.
# star`/`../codegen.star`/`../codegen_expr.star`/`../codegen_stmt.star`, and
# prints the resulting Nova-16 assembly text to stdout (or a single `LEX
# ERROR:`/`PARSE ERROR:`/`SEMANTIC ERROR:`/`CODEGEN ERROR:` line). Same
# "no in-language assertion facility, so dump and diff instead" shape
# `lexer_dump.star`/`parser_dump.star`/`semantic_dump.star` already
# established -- unlike those, this dumps real Nova-16 assembly text
# (line-for-line comparable to the live Python reference's own output when
# run with `--disable-optimizations --disable-peephole --disable-live-range`,
# matching `codegen.star`'s header comment on why that flag combination is
# the fair comparison point for what this file's `Codegen` implements).
#
# Usage: codegen_dump.exe path/to/one.nobasic
# (built via:
#   star build projects/nova/NoBASIC/tests/codegen_dump.star -o projects/nova/NoBASIC/tests/codegen_dump.exe
# -- a plain text-in/text-out tool, no SDL2 link needed.)

import "../lexer.star" as lex
import "../parser.star" as psr
import "../semantic.star" as sem
import "../codegen.star" as cg
import "../codegen_expr.star" as cg_expr
import "../codegen_stmt.star" as cg_stmt

fn compile_one(path: str) -> str:
    let h = file_open(path, "r")
    if is_null(h):
        return concat("could not open '", concat(path, "'"))
    let source = file_read(h)
    file_close(h)

    let tokens = match lex::lex(source, path):
        Result::Ok(toks) -> toks
        Result::Err(e) ->
            return concat("LEX ERROR: ", lex::format_lex_error(e))

    let program = match psr::parse(tokens, path):
        Result::Ok(p) -> p
        Result::Err(e) ->
            return concat("PARSE ERROR: ", psr::format_parse_error(e))

    let analyzed = match sem::analyze(program, path):
        Result::Ok(p) -> p
        Result::Err(e) ->
            return concat("SEMANTIC ERROR: ", sem::format_semantic_error(e))

    let mut gen = cg::new_codegen(analyzed.exprs, analyzed.stmts, path)
    let asm = gen.generate(analyzed.program)
    if gen.had_error:
        return f"CODEGEN ERROR: {gen.error_message} (line {gen.error_line}, column {gen.error_column})"
    asm

fn main() -> i32:
    let cli = args()
    if cli.len() < 2:
        println("usage: codegen_dump <path.nobasic>")
        return 1
    println(compile_one(cli[1]))
    0
