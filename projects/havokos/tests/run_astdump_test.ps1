# M2 regression test (todo.md HavokOS M2): preprocess, lex and parse every
# `.c` file of the Dead Souls 3.9 mudlib with the Star front end + parser and
# compare each file's AST hash against `fixtures/ds39_ast.expected.txt`.
# That fixture was generated once from the live Pike reference
# (`tools/ref_astdump.pike`, driving HavokOS's own `preprocess.pike` ->
# `lexer.pike` -> `parser.pike`) and frozen -- the same shape as
# `run_tokdump_test.ps1`, one level further down the pipeline.
#
# Lines ending in `NOLINES` are the `@MARK` text-block files, compared with
# every "line" key left out (NOTES.md deviation #1).
#
# Usage: powershell -File projects/havokos/tests/run_astdump_test.ps1 [-MudlibRoot E:\ds3.9\lib]
# (rebuild tools/astdump.exe first if any front-end or parser .star file changed:
#   star build projects/havokos/tools/astdump.star -o projects/havokos/tools/astdump.exe)
# Exits 0 on a full match, 1 otherwise.
#
# Regenerating the fixture (only after confirming the *reference's* own
# output changed, never to paper over a Star-side diff):
#   pike tools/ref_astdump.pike <havokos>/pike/lpc <mudlib> <list>            -> all files
#   pike tools/ref_astdump.pike <havokos>/pike/lpc <mudlib> <list> -nolines   -> text-block files
# then splice the -nolines results in with a trailing " NOLINES".

param([string]$MudlibRoot = "E:\ds3.9\lib")

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$dumper = Join-Path $root "tools\astdump.exe"
$expectedFile = Join-Path $here "fixtures\ds39_ast.expected.txt"
$tmp = Join-Path $env:TEMP "havokos_astdump_test"
New-Item -ItemType Directory -Force $tmp | Out-Null

if (-not (Test-Path $dumper)) {
    Write-Error "astdump.exe not found at $dumper -- build it first (see this script's header)."
    exit 1
}

$expected = @{}
$plain = New-Object System.Collections.Generic.List[string]
$nolines = New-Object System.Collections.Generic.List[string]
foreach ($line in Get-Content $expectedFile) {
    if (-not $line.Trim()) { continue }
    $vpath = ($line -split " ")[0]
    if ($line.EndsWith(" NOLINES")) {
        $expected[$vpath] = $line.Substring(0, $line.Length - 8)
        $nolines.Add($vpath)
    } else {
        $expected[$vpath] = $line
        $plain.Add($vpath)
    }
}

$plainList = Join-Path $tmp "plain.txt"
$nolinesList = Join-Path $tmp "nolines.txt"
[System.IO.File]::WriteAllLines($plainList, $plain)
[System.IO.File]::WriteAllLines($nolinesList, $nolines)

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$actual = @(& $dumper ($MudlibRoot -replace "\\", "/") $plainList)
$actual += @(& $dumper ($MudlibRoot -replace "\\", "/") $nolinesList "-nolines")
$sw.Stop()

$failures = 0
$seen = @{}
foreach ($line in $actual) {
    $line = $line.TrimEnd()
    if (-not $line) { continue }
    $vpath = ($line -split " ")[0]
    $seen[$vpath] = $true
    if ($expected[$vpath] -ne $line) {
        $failures++
        if ($failures -le 20) { Write-Host "MISMATCH $vpath`n  expected: $($expected[$vpath])`n  actual:   $line" }
    }
}
foreach ($vpath in $expected.Keys) {
    if (-not $seen[$vpath]) {
        $failures++
        if ($failures -le 20) { Write-Host "MISSING  $vpath" }
    }
}

$total = $expected.Count
$secs = [math]::Round($sw.Elapsed.TotalSeconds, 1)
if ($failures -eq 0) {
    Write-Host "PASS: $total files match the reference ASTs ($($nolines.Count) without line numbers) in $secs s"
    exit 0
}
Write-Host "FAIL: $failures of $total files differ ($secs s)"
exit 1
