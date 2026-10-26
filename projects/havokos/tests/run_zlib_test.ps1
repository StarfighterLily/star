# zlib regression test (todo.md HavokOS P1 #8): MCCP's compressor
# (`zlib.star`) is this port's own, so it is checked against a real zlib --
# Pike's Gz, the one the reference's MCCP uses -- in both directions:
#   - every corpus file compressed by tools/zlib_check.exe in MCCP-style
#     writes (sync-flushed chunks of several sizes, then the end of the
#     stream) must inflate back to itself under Pike's Gz.inflate, and under
#     zlib.star's own inflater;
#   - streams Pike's Gz.deflate makes (levels 1, 6 and 9, whole and
#     chunked) must inflate to the original under zlib.star's inflater.
# The corpus: Dead Souls source text, a binary, incompressible random bytes
# (stored blocks, including ones split at 65535 bytes), long runs (the
# longest matches), a one-line MCCP-sized write, and an empty file.
#
# Usage: powershell -File projects/havokos/tests/run_zlib_test.ps1 [-DsLib E:\ds3.9\lib]
# (rebuild tools/zlib_check.exe first if zlib.star changed:
#   target/release/star.exe build projects/havokos/tools/zlib_check.star -o projects/havokos/tools/zlib_check.exe)
# Exits 0 when every round trip matches, 1 otherwise. About 10 s.

param([string]$DsLib = "E:\ds3.9\lib")

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$tool = Join-Path $root "tools\zlib_check.exe"
$refz = Join-Path $root "tools\ref_zlib.pike"
$pike = "C:\Program Files (x86)\Pike\bin\pike.exe"
if (-not (Test-Path $tool)) {
    Write-Error "zlib_check.exe not found at $tool -- build it first (see this script's header)."
    exit 1
}

$work = Join-Path ([IO.Path]::GetTempPath()) "havokos_zlib_test"
if (Test-Path $work) { Remove-Item -Recurse -Force $work }
New-Item -ItemType Directory -Force $work | Out-Null

# --- the corpus ------------------------------------------------------------------
$text = New-Object System.IO.MemoryStream
Get-ChildItem $DsLib -Recurse -Filter *.c | Sort-Object FullName | Select-Object -First 600 | ForEach-Object {
    $b = [IO.File]::ReadAllBytes($_.FullName)
    $text.Write($b, 0, $b.Length)
}
[IO.File]::WriteAllBytes((Join-Path $work "text.bin"), $text.ToArray())
$slice = New-Object byte[] 3000
[Array]::Copy($text.ToArray(), $slice, 3000)
[IO.File]::WriteAllBytes((Join-Path $work "slice.bin"), $slice)
[IO.File]::WriteAllBytes((Join-Path $work "binary.bin"), [IO.File]::ReadAllBytes($tool))
& $pike $refz random (Join-Path $work "random.bin") 300000 7
$runs = New-Object System.IO.MemoryStream
$a = [Text.Encoding]::ASCII.GetBytes("a" * 70000 + "ab" * 40000 + "xyz" * 30000)
$runs.Write($a, 0, $a.Length)
for ($k = 0; $k -lt 2000; $k++) { $runs.WriteByte([byte]($k % 7)); $runs.WriteByte(255) }
[IO.File]::WriteAllBytes((Join-Path $work "runs.bin"), $runs.ToArray())
[IO.File]::WriteAllBytes((Join-Path $work "small.bin"), [Text.Encoding]::ASCII.GetBytes("compressed hello`r`n"))
[IO.File]::WriteAllBytes((Join-Path $work "empty.bin"), (New-Object byte[] 0))

function Same($x, $y) {
    (Get-FileHash $x).Hash -eq (Get-FileHash $y).Hash
}

$failed = 0
$checks = 0
$files = @("text", "slice", "binary", "random", "runs", "small", "empty")
foreach ($f in $files) {
    $src = Join-Path $work "$f.bin"
    $size = (Get-Item $src).Length
    # chunk sizes: whole, then MCCP-like writes; byte-at-a-time only where small
    $chunks = @(0, 1000, 100000)
    if ($size -le 3000) { $chunks += @(1, 7) }
    foreach ($c in $chunks) {
        $z = Join-Path $work "$f.$c.z"
        $null = & $tool deflate $src $z $c
        & $pike $refz inflate $z "$z.pike"
        $self = & $tool inflate $z "$z.self"
        $checks++
        $ok = (Same $src "$z.pike") -and (Same $src "$z.self") -and ($self -eq "ended")
        $ratio = "{0} -> {1}" -f $size, (Get-Item $z).Length
        if (-not $ok) { $failed++; Write-Host "FAIL star deflate $f chunk $c ($ratio, self: $self)" }
    }
    foreach ($lvl in @(1, 6, 9)) {
        foreach ($c in @(0, 1000)) {
            $z = Join-Path $work "$f.p$lvl.$c.z"
            & $pike $refz deflate $src $z $lvl $c
            $self = & $tool inflate $z "$z.out"
            $checks++
            if (-not ((Same $src "$z.out") -and ($self -eq "ended"))) {
                $failed++
                Write-Host "FAIL zlib level $lvl chunk $c -> star inflate $f (self: $self)"
            }
        }
    }
    $whole = Join-Path $work "$f.0.z"
    $pz = Join-Path $work "$f.p6.0.z"
    Write-Host ("{0,-7} {1,8} bytes: star {2,8}, zlib -6 {3,8}" -f $f, $size, (Get-Item $whole).Length, (Get-Item $pz).Length)
}
Remove-Item -Recurse -Force $work
if ($failed -eq 0) {
    Write-Host "PASS: $checks round trips match"
    exit 0
}
Write-Host "FAIL: $failed of $checks round trips"
exit 1
