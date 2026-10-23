# Parser edge-case regression test (todo.md HavokOS M2). The DS3.9 sweep
# (`run_astdump_test.ps1`) never exercises a fair part of the grammar -- case
# ranges, scoped function pointers, `parse_command`, default arguments,
# `ob->(expr)`, labelled inherits, ... -- so
# `fixtures/astlib/` is a tiny mudlib that does:
#   - `/ast_cases.c` must parse to exactly `fixtures/ast_cases.expected.txt`,
#     the live Pike reference's full dump of it
#     (`tools/ref_astdump.pike ... -v /ast_cases.c`), frozen.
#   - `/err/*.c` are one-mistake files; each must succeed or fail exactly as
#     it does under the reference (`fixtures/ast_errors.expected.txt`, the
#     reference's list-mode output over them).
#
# Usage: powershell -File projects/havokos/tests/run_ast_cases_test.ps1
# (rebuild tools/astdump.exe first -- see run_astdump_test.ps1's header.)
# Exits 0 on match, 1 otherwise.

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$dumper = Join-Path $root "tools\astdump.exe"
$libDir = Join-Path $here "fixtures\astlib"
$lib = $libDir -replace "\\", "/"
$failed = $false

$actual = (& $dumper $lib "-v" "/ast_cases.c" | Out-String) -replace "`r`n", "`n"
$expected = (Get-Content (Join-Path $here "fixtures\ast_cases.expected.txt") -Raw) -replace "`r`n", "`n"
if ($actual.TrimEnd("`n") -eq $expected.TrimEnd("`n")) {
    Write-Host "PASS: ast_cases.c AST dump matches the reference"
} else {
    Write-Host "FAIL: ast_cases.c AST dump differs from the reference"
    Compare-Object ($expected -split "`n") ($actual -split "`n") | Format-Table -AutoSize
    $failed = $true
}

$tmp = Join-Path $env:TEMP "havokos_ast_cases_test"
New-Item -ItemType Directory -Force $tmp | Out-Null
$list = Join-Path $tmp "errs.txt"
$errFiles = Get-ChildItem (Join-Path $libDir "err") -Filter *.c | Sort-Object Name | ForEach-Object { "/err/$($_.Name)" }
[System.IO.File]::WriteAllLines($list, [string[]]$errFiles)
$actualErr = (& $dumper $lib $list | Out-String) -replace "`r`n", "`n"
$expectedErr = (Get-Content (Join-Path $here "fixtures\ast_errors.expected.txt") -Raw) -replace "`r`n", "`n"
if ($actualErr.TrimEnd("`n") -eq $expectedErr.TrimEnd("`n")) {
    Write-Host "PASS: $($errFiles.Count) error-case files succeed/fail as the reference does"
} else {
    Write-Host "FAIL: error-case results differ from the reference"
    Compare-Object ($expectedErr -split "`n") ($actualErr -split "`n") | Format-Table -AutoSize
    $failed = $true
}

if ($failed) { exit 1 }
exit 0
