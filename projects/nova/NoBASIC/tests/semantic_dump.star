# Star-side half of the semantic analyzer's Python-cross-checked
# regression test (todo.md P0 #3) -- lexes, parses, then semantically
# analyzes every `.nobasic` fixture path named on the command line with
# `../lexer.star`/`../parser.star`/`../semantic.star`, printing one
# deterministic `<path>: OK` or `<path>: <formatted error>` line per
# fixture so a shell script can diff the whole batch against output
# generated from the live Python reference (`run_semantic_test.ps1` in this
# directory) -- same "no in-language assertion facility, so dump and diff
# instead" shape `lexer_dump.star`/`parser_dump.star` already established
# (see `NOTES.md`'s "Testing" section).
#
# Unlike the lexer/parser rounds' single big fixture, semantic analysis is
# tested as one clean "everything should pass" program
# (`fixtures/semantic_valid.nobasic`) plus a battery of small
# one-error-each snippets under `fixtures/semantic_errors/` -- a full
# internal-symbol-table dump isn't practical here the way a token/AST dump
# was: `SymbolTable`'s `Map<str, ..>`/`Set<str>` fields have no iteration
# API in Star at all (see `../semantic.star`'s own header comment), so the
# only externally observable, byte-for-byte-comparable behavior left is
# exactly what the reference's own `analyze()` exposes to a caller: does it
# raise, and with what message/line/column. That is what this dumps.
#
# One deliberate, documented non-match against a raw run of the live
# reference: `fixtures/semantic_errors/undefined_label_goto.nobasic`'s
# frozen expected line does NOT match what the live Python reference
# literally prints for that file. The reference has a real positional-
# argument bug in its pending-GOTO check (passes `line` where `filename`
# belongs and `column` where `line` belongs -- see `../semantic.star`'s
# header comment, "Deliberate fix" section, for the full writeup); this
# port's `analyze()` deliberately does not reproduce that bug (Star's typed
# `SemanticError` struct would make the same mistake a compile error, not
# a silent mix-up), so its output for that one fixture is the *correct*
# message/line/column, confirmed to differ from the live reference's own
# output by direct comparison before freezing.
#
# Usage: semantic_dump.exe path/to/one.nobasic [path/to/two.nobasic ...]
# (built via:
#   star build projects/nova/NoBASIC/tests/semantic_dump.star -o projects/nova/NoBASIC/tests/semantic_dump.exe
# -- a plain text-in/text-out tool, no SDL2 link needed.)

import "../lexer.star" as lex
import "../parser.star" as psr
import "../semantic.star" as sem

fn check_one(path: str) -> str:
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

    match sem::analyze(program, path):
        Result::Ok(_p) -> "OK"
        Result::Err(e) -> sem::format_semantic_error(e)

fn main() -> i32:
    let cli = args()
    if cli.len() < 2:
        println("usage: semantic_dump <path.nobasic> [path.nobasic ...]")
        return 1
    let mut i = 1
    while i < cli.len():
        let path = cli[i]
        let result = check_one(path)
        println(f"{path}: {result}")
        i += 1
    0
