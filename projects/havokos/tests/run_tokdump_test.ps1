# M1 regression test (todo.md HavokOS M1): preprocess + lex every `.c` file
# of the Dead Souls 3.9 mudlib with the Star front end and compare each
# file's token-stream hash against `fixtures/ds39_tokens.expected.txt`. That
# fixture was generated once from the live Pike reference
# (`tools/ref_tokdump.pike`, driving HavokOS's own `preprocess.pike` +
# `lexer.pike`) and frozen, the same "dump and diff against a frozen
# reference fixture" shape as `projects/nova/NoBASIC/tests/run_lexer_test.ps1`.
#
# Lines ending in `NOLINES` are files containing `@MARK` text blocks, where
# the reference reports wrong line numbers (a reference bug this port
# deliberately doesn't reproduce -- see `lexer.star`'s "Deliberate
# deviation" note). Those are compared with line numbers left out of the
# hash, so their tokens are still checked exactly.
#
# Usage: powershell -File projects/havokos/tests/run_tokdump_test.ps1 [-MudlibRoot E:\ds3.9\lib]
# (rebuild tools/tokdump.exe first if any front-end .star file changed:
#   star build projects/havokos/tools/tokdump.star -o projects/havokos/tools/tokdump.exe)
# Exits 0 on a full match, 1 otherwise.
#
# Regenerating the fixture (only after confirming the *reference's* own
# output changed, never to paper over a Star-side diff):
#   pike tools/ref_tokdump.pike <havokos>/pike/lpc <mudlib> <list>            -> all files
#   pike tools/ref_tokdump.pike <havokos>/pike/lpc <mudlib> <list> -nolines   -> text-block files
# then splice the -nolines results in with a trailing " NOLINES".

param([string]$MudlibRoot = "E:\ds3.9\lib")

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$dumper = Join-Path $root "tools\tokdump.exe"
$expectedFile = Join-Path $here "fixtures\ds39_tokens.expected.txt"
$tmp = Join-Path $env:TEMP "havokos_tokdump_test"
New-Item -ItemType Directory -Force $tmp | Out-Null

if (-not (Test-Path $dumper)) {
    Write-Error "tokdump.exe not found at $dumper -- build it first (see this script's header)."
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
    Write-Host "PASS: $total files match the reference token streams ($($nolines.Count) without line numbers) in $secs s"
    exit 0
}
Write-Host "FAIL: $failures of $total files differ ($secs s)"
exit 1
