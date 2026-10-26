# M5 boot regression test (todo.md HavokOS M5): boot Dead Souls 3.9 all the
# way -- simul_efun object, master, epilog() and all 43 preloads -- on the
# Star VM and compare what the boot left behind (every live object with its
# privs, environment, heart beat and living flags, and the object, clone,
# call_out and heart beat counts) against the live Pike driver's, frozen in
# fixtures/ds39_boot.expected.txt.
#
# The boot writes logs and save files, so it runs on a fresh copy of the
# mudlib in the temp directory, never on E:\ds3.9\lib itself.
#
# Usage: powershell -File projects/havokos/tests/run_boot_test.ps1 [-DsRoot E:\ds3.9]
# (rebuild tools/boot_ds.exe first if any compiler/VM .star file changed:
#   target/release/star.exe build projects/havokos/tools/boot_ds.star -o projects/havokos/tools/boot_ds.exe -l ws2_32 -L sqlite/lib/x64 -l sqlite3)
# Exits 0 when the reports match, 1 otherwise. About 3 s.
#
# Regenerating the fixture (only after confirming the *reference's* own
# behavior changed, or when the Star VM implements more efuns -- the stub list
# must then shrink with it, or the reference fails calls Star no longer does):
#   tools/boot_ds.exe -unimplemented > tests/fixtures/ds39_boot_stubs.txt
#   (copy E:\ds3.9\lib to a scratch directory first)
#   pike tools/ref_boot.pike <havokos>/pike E:/ds3.9/bin/mudos.cfg <scratch lib> tests/fixtures/ds39_boot_stubs.txt | findstr /v /b LOG > tests/fixtures/ds39_boot.expected.txt
# ref_boot.pike stubs the listed efuns -- the ones the Star VM can't run yet
# (verb parser, ed, sockets, network) -- with the reference's own "not
# implemented" error, so both drivers fail the same calls.

param([string]$DsRoot = "E:\ds3.9")

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$tool = Join-Path $root "tools\boot_ds.exe"
if (-not (Test-Path $tool)) {
    Write-Error "boot_ds.exe not found at $tool -- build it first (see this script's header)."
    exit 1
}

# the stub list the fixture was made with must still be what this VM lacks
$stubs = Get-Content (Join-Path $here "fixtures\ds39_boot_stubs.txt")
$now = @(& $tool -unimplemented)
if (Compare-Object $stubs $now) {
    Write-Host "FAIL: the VM's unimplemented efuns changed since the fixture was made -- regenerate it (see this script's header)"
    exit 1
}

$scratch = Join-Path ([IO.Path]::GetTempPath()) ("havokos_boot_" + [Guid]::NewGuid().ToString("N"))
Copy-Item -Recurse (Join-Path $DsRoot "lib") $scratch
try {
    $cfg = (Join-Path $DsRoot "bin\mudos.cfg") -replace "\\", "/"
    $out = @(& $tool $cfg ($scratch -replace "\\", "/") | Where-Object { $_ -notlike "LOG *" })
    $want = Get-Content (Join-Path $here "fixtures\ds39_boot.expected.txt")
    $diff = Compare-Object $want $out
    if ($diff) {
        $diff | Select-Object -First 20 | ForEach-Object { Write-Host "$($_.SideIndicator) $($_.InputObject)" }
        Write-Host "FAIL: the Star VM's DS3.9 boot differs from the reference's"
        exit 1
    }
    Write-Host "PASS: DS3.9 boot matches the reference ($(($out | Where-Object { $_ -like 'OBJ *' }).Count) objects)"
    exit 0
} finally {
    Remove-Item -Recurse -Force $scratch
}
