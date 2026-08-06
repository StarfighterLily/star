# Regression test for the codegen core (todo.md P1 #1) -- runs
# codegen_dump.exe against fixtures/codegen/arith_control_functions.nobasic
# and diffs the emitted Nova-16 assembly against
# fixtures/codegen/arith_control_functions.expected.txt, generated once and
# cross-checked line-for-line against the live Python reference
# (`compiler/codegen/generator.py`, run via `python nobasic_compiler.py
# <file> --output <out> --disable-optimizations --disable-peephole
# --disable-live-range` -- that flag combination is the fair comparison
# point, since this port doesn't yet implement any of the three optimization
# passes those flags gate; see codegen.star's header comment). Same "no
# in-language assertion facility, so dump and diff instead" shape
# `run_lexer_test.ps1`/`run_parser_test.ps1`/`run_semantic_test.ps1` already
# established.
#
# One deliberate, documented non-match against a raw run of the live
# reference: this port's output folds `(1 + 2) * 3` to `MOV P0, 3` /
# `MUL ... 3` (i.e. 9), where the live reference emits `MOV P0, 0` (i.e. 0)
# for the same expression -- a confirmed, genuine reference bug
# (`generate_expression`'s `isinstance` dispatch has no case for
# `GroupingExpr` at all, so every parenthesized expression silently becomes
# the constant `0`; see codegen.star's header comment for the full writeup
# and the live-reference repro that confirmed it). This port's `Codegen`
# deliberately does not reproduce that bug, so its output for the `GY = (1 +
# 2) * 3` line is the *correct* constant-folded result, confirmed to differ
# from the live reference's own output by direct comparison before freezing.
#
# Usage: powershell -File projects/nova/NoBASIC/tests/run_codegen_test.ps1
# (rebuild codegen_dump.exe first if codegen.star/codegen_expr.star/
# codegen_stmt.star/semantic.star/parser.star/lexer.star/tokens.star/ast.star
# changed -- see codegen_dump.star's own header comment for the build
# command.) Exits 0 on match, 1 otherwise.
#
# To regenerate fixtures/codegen/arith_control_functions.expected.txt after
# a deliberate codegen change (only if the reference's own behavior also
# changed to match, or a new fixture was added and confirmed against the
# live reference -- otherwise a diff here means a real regression, not a
# stale fixture): from this directory, run
#   .\codegen_dump.exe fixtures\codegen\arith_control_functions.nobasic > fixtures\codegen\arith_control_functions.expected.txt
# then re-verify the changed/new lines against the live Python reference
# (`python nobasic_compiler.py <file> --output <out> --disable-optimizations
# --disable-peephole --disable-live-range`, from the reference project's own
# directory) before committing the refreshed fixture -- except the
# Grouping-expression line noted above, which is expected to differ from a
# raw reference run.

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dumper = Join-Path $here "codegen_dump.exe"
$fixture = Join-Path $here "fixtures\codegen\arith_control_functions.nobasic"
$expectedFile = Join-Path $here "fixtures\codegen\arith_control_functions.expected.txt"

if (-not (Test-Path $dumper)) {
    Write-Error "codegen_dump.exe not found at $dumper -- build it first (see codegen_dump.star's own header comment for the build command)."
    exit 1
}

Push-Location $here
try {
    $actual = & $dumper $fixture | Out-String
} finally {
    Pop-Location
}
$expected = Get-Content $expectedFile -Raw

# Normalize line endings -- codegen_dump.exe's own `println` emits the host
# platform's line ending (CRLF on Windows); the checked-in fixture is plain
# LF.
$actualNorm = $actual -replace "`r`n", "`n"
$expectedNorm = $expected -replace "`r`n", "`n"

if ($actualNorm.TrimEnd("`n") -eq $expectedNorm.TrimEnd("`n")) {
    Write-Host "PASS: codegen.star assembly output matches $expectedFile"
    exit 0
} else {
    Write-Host "FAIL: codegen.star assembly output differs from $expectedFile"
    $actualLines = $actualNorm -split "`n"
    $expectedLines = $expectedNorm -split "`n"
    Compare-Object $expectedLines $actualLines | Format-Table -AutoSize
    exit 1
}
