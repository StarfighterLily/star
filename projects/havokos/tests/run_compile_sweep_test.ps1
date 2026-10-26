# M3 compile sweep (todo.md HavokOS M3): compile every `.c` file of the Dead
# Souls 3.9 mudlib with the Star bytecode compiler and compare each file's
# result -- OK plus hashes of its inheritance tables (function names
# defined/prototyped, visible variable names), or FAIL -- against
# `fixtures/ds39_compile.expected.txt`. That fixture was generated once from
# the live Pike reference (`tools/ref_compile_sweep.pike`, driving HavokOS's
# own compiler.pike `transpile()`) and frozen, like the M1/M2 sweeps.
#
# Usage: powershell -File projects/havokos/tests/run_compile_sweep_test.ps1 [-MudlibRoot E:\ds3.9\lib]
# (rebuild tools/compile_sweep.exe first if any compiler .star file changed:
#   target/release/star.exe build projects/havokos/tools/compile_sweep.star -o projects/havokos/tools/compile_sweep.exe -l ws2_32 -L sqlite/lib/x64 -l sqlite3)
# Exits 0 on a full match, 1 otherwise.
#
# Regenerating the fixture (only after confirming the *reference's* own
# output changed, never to paper over a Star-side diff):
#   pike tools/ref_compile_sweep.pike <havokos>/pike <mudlib> <list> <scratch_cache_dir>

param([string]$MudlibRoot = "E:\ds3.9\lib")

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$sweeper = Join-Path $root "tools\compile_sweep.exe"
$expectedFile = Join-Path $here "fixtures\ds39_compile.expected.txt"
$tmp = Join-Path $env:TEMP "havokos_compile_sweep_test"
New-Item -ItemType Directory -Force $tmp | Out-Null

if (-not (Test-Path $sweeper)) {
    Write-Error "compile_sweep.exe not found at $sweeper -- build it first (see this script's header)."
    exit 1
}

$expected = @{}
$list = New-Object System.Collections.Generic.List[string]
foreach ($line in Get-Content $expectedFile) {
    if (-not $line.Trim()) { continue }
    $vpath = ($line -split " ")[0]
    $expected[$vpath] = $line
    $list.Add($vpath)
}
$listFile = Join-Path $tmp "files.txt"
[System.IO.File]::WriteAllLines($listFile, $list)

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$actual = @(& $sweeper ($MudlibRoot -replace "\\", "/") $listFile)
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
$ok = @($actual | Where-Object { $_ -match " OK " }).Count
$secs = [math]::Round($sw.Elapsed.TotalSeconds, 1)
if ($failures -eq 0) {
    Write-Host "PASS: $total files match the reference ($ok compile) in $secs s"
    exit 0
}
Write-Host "FAIL: $failures of $total files differ ($secs s)"
exit 1
