# Preprocessor edge-case regression test (todo.md HavokOS M1): the DS3.9
# sweep (`run_tokdump_test.ps1`) never exercises the harder macro rules --
# rescanning, self-reference, `#`/`##`, nested-bracket arguments, `#if`
# arithmetic -- so `fixtures/pplib/` is a tiny mudlib whose
# `/sub/pp_cases.c` does, and `fixtures/pp_cases.expected.txt` is the live
# Pike reference's dump of it (`tools/ref_tokdump.pike ... -v /sub/pp_cases.c`),
# frozen. Every one of those rules was pinned down against that reference,
# not taken from the C standard -- see `preprocess.star`'s header comment.
#
# Usage: powershell -File projects/havokos/tests/run_pp_cases_test.ps1
# (rebuild tools/tokdump.exe first -- see run_tokdump_test.ps1's header.)
# Exits 0 on match, 1 otherwise.

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$dumper = Join-Path $root "tools\tokdump.exe"
$lib = (Join-Path $here "fixtures\pplib") -replace "\\", "/"
$expectedFile = Join-Path $here "fixtures\pp_cases.expected.txt"

$actual = (& $dumper $lib "-v" "/sub/pp_cases.c" | Out-String) -replace "`r`n", "`n"
$expected = (Get-Content $expectedFile -Raw) -replace "`r`n", "`n"

if ($actual.TrimEnd("`n") -eq $expected.TrimEnd("`n")) {
    Write-Host "PASS: pp_cases.c token dump matches $expectedFile"
    exit 0
}
Write-Host "FAIL: pp_cases.c token dump differs from $expectedFile"
Compare-Object ($expected -split "`n") ($actual -split "`n") | Format-Table -AutoSize
exit 1
