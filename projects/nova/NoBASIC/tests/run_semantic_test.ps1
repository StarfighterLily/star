# Regression test for semantic.star (todo.md P0 #3) -- runs
# semantic_dump.exe against fixtures/semantic_valid.nobasic plus every
# fixtures/semantic_errors/*.nobasic snippet, and diffs the whole batch's
# output against fixtures/semantic_expected.txt, generated once against the
# live Python reference (`compiler/semantic/analyzer.py`) and frozen. Same
# "no in-language assertion facility, so dump and diff instead" shape
# `run_lexer_test.ps1`/`run_parser_test.ps1` already established -- see
# `semantic_dump.star`'s own header comment for why this dumps pass/fail +
# error message rather than a full symbol-table state dump, and for the one
# fixture (`undefined_label_goto.nobasic`) whose frozen line is a
# deliberate, documented non-match against a raw reference run.
#
# Usage: powershell -File projects/nova/NoBASIC/tests/run_semantic_test.ps1
# (rebuild semantic_dump.exe first if semantic.star/ast.star/parser.star/
# lexer.star/tokens.star changed -- see semantic_dump.star's own header
# comment for the build command.) Exits 0 on match, 1 otherwise.
#
# To regenerate fixtures/semantic_expected.txt after a deliberate
# semantic.star change (only if the reference's own behavior also changed
# to match, or a new fixture was added and confirmed against the live
# reference -- otherwise a diff here means a real regression, not a stale
# fixture): from this directory, run
#   .\semantic_dump.exe fixtures/semantic_valid.nobasic fixtures/semantic_errors/*.nobasic > fixtures/semantic_expected.txt
# then re-verify every changed/new line against the live Python reference
# (`run_semantic_ref.py`-style throwaway script, not checked in -- see
# `NOTES.md`'s "Semantic analyzer" section) before committing the refreshed
# fixture -- except `undefined_label_goto.nobasic`'s line, which is
# expected to differ from a raw reference run (see above).

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dumper = Join-Path $here "semantic_dump.exe"
$expectedFile = Join-Path $here "fixtures\semantic_expected.txt"

if (-not (Test-Path $dumper)) {
    Write-Error "semantic_dump.exe not found at $dumper -- build it first (see semantic_dump.star's own header comment for the build command)."
    exit 1
}

Push-Location $here
try {
    $errorFixtures = Get-ChildItem -Path "fixtures\semantic_errors\*.nobasic" | ForEach-Object { $_.FullName.Substring($here.Length + 1).Replace('\', '/') } | Sort-Object
    $fixtureArgs = @("fixtures/semantic_valid.nobasic") + $errorFixtures
    $actual = & $dumper @fixtureArgs | Out-String
} finally {
    Pop-Location
}
$expected = Get-Content $expectedFile -Raw

# Normalize line endings -- semantic_dump.exe's own `println` emits the
# host platform's line ending (CRLF on Windows); the checked-in fixture is
# plain LF.
$actualNorm = $actual -replace "`r`n", "`n"
$expectedNorm = $expected -replace "`r`n", "`n"

if ($actualNorm.TrimEnd("`n") -eq $expectedNorm.TrimEnd("`n")) {
    Write-Host "PASS: semantic.star analysis output matches $expectedFile"
    exit 0
} else {
    Write-Host "FAIL: semantic.star analysis output differs from $expectedFile"
    $actualLines = $actualNorm -split "`n"
    $expectedLines = $expectedNorm -split "`n"
    Compare-Object $expectedLines $actualLines | Format-Table -AutoSize
    exit 1
}
