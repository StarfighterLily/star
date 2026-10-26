# M6/M7 end-to-end login test (todo.md HavokOS M6, M7): the Star driver
# (tools/havokos.exe) boots Dead Souls 3.9 and serves telnet; a scripted
# client (tools/telnet_script.exe) connects over a real socket and
#   1. creates a new character and plays a few commands
#      (fixtures/ds39_login_new.script: the whole creation dialogue, the
#      news pagers, look, inventory, who, get, read, say, score, smile, an
#      unknown command, a creator-only command, movement, drop/get, quit),
#   2. logs back in as that character, a wrong password first
#      (fixtures/ds39_login_again.script),
#   3. logs in again and edits through Dead Souls' own editor (M7,
#      fixtures/ds39_login_edit.script): `praise` in input mode, then
#      command mode, a print, s///, line numbers, the help pager, a
#      restricted command, undo, x and the command's callback; then
#      `bug -r`, a `!` mud command from inside the editor, and quitting
#      mid-edit,
# and each transcript -- every byte the driver sent, telnet negotiation
# included -- is compared with what the live Pike driver sent for the same
# script, frozen in fixtures/ds39_login_{new,again}.expected.txt (recorded
# with tools/ref_serve.pike: the same efun stubs as the boot test, and
# `havok mccp : 0`).
#
# What is normalized, and why:
# - Dead Souls rolls a new character's stats with random(), and the two
#   drivers' generators differ, so the hp/mp/sp numbers in the prompt
#   (every `N/N`) are masked.
# - `score` prints the character's birthday in the mud's calendar, which
#   follows the real clock: that line is masked.
# - `inventory` lists items from a mapping's keys (NOTES.md deviation #9):
#   its item lines are sorted.
# Everything else must match byte for byte.
#
# Usage: powershell -File projects/havokos/tests/run_login_test.ps1 [-DsRoot E:\ds3.9]
# (rebuild the tools first if any .star file changed:
#   target/release/star.exe build projects/havokos/boot.star -o projects/havokos/tools/havokos.exe -l ws2_32 -L sqlite/lib/x64 -l sqlite3
#   target/release/star.exe build projects/havokos/tools/telnet_script.star -o projects/havokos/tools/telnet_script.exe -l ws2_32)
# Exits 0 when all three transcripts match, 1 otherwise. About 25 s.
#
# Regenerating the fixtures (only after confirming the *reference's* own
# behavior changed), on a fresh copy of the mudlib:
#   pike tools/ref_serve.pike <havokos>/pike <scratch>/bin/mudos.cfg <scratch>/lib tests/fixtures/ds39_boot_stubs.txt 7801
#   tools/telnet_script.exe 7801 tests/fixtures/ds39_login_new.script > tests/fixtures/ds39_login_new.expected.txt
#   tools/telnet_script.exe 7801 tests/fixtures/ds39_login_again.script > tests/fixtures/ds39_login_again.expected.txt
#   tools/telnet_script.exe 7801 tests/fixtures/ds39_login_edit.script > tests/fixtures/ds39_login_edit.expected.txt
# (the three in that order, on one server: each needs the character the
# first one made)

param([string]$DsRoot = "E:\ds3.9")

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$driver = Join-Path $root "tools\havokos.exe"
$client = Join-Path $root "tools\telnet_script.exe"
foreach ($t in @($driver, $client)) {
    if (-not (Test-Path $t)) {
        Write-Error "$t not found -- build it first (see this script's header)."
        exit 1
    }
}

function Normalize([string[]]$lines) {
    $out = New-Object System.Collections.Generic.List[string]
    $i = 0
    while ($i -lt $lines.Count) {
        $l = $lines[$i] -replace "\d+/\d+", "#/#"
        if ($l -match "You were born on ") {
            $out.Add("< (birthday)")
            $i++
            continue
        }
        $out.Add($l)
        $i++
        if ($l -match "You are carrying the following items:") {
            $block = New-Object System.Collections.Generic.List[string]
            while ($i -lt $lines.Count -and $lines[$i] -notmatch "hp: ") {
                $block.Add($lines[$i])
                $i++
            }
            $block | Sort-Object | ForEach-Object { $out.Add($_) }
        }
    }
    return $out
}

$scratch = Join-Path ([IO.Path]::GetTempPath()) ("havokos_login_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force (Join-Path $scratch "bin") | Out-Null
Copy-Item -Recurse (Join-Path $DsRoot "lib") (Join-Path $scratch "lib")
Copy-Item (Join-Path $DsRoot "bin\mudos.cfg") (Join-Path $scratch "bin")
# a free port
$probe = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
$probe.Start()
$port = $probe.LocalEndpoint.Port
$probe.Stop()
$log = Join-Path $scratch "driver.log"
$proc = Start-Process -FilePath $driver -ArgumentList @((Join-Path $scratch "bin\mudos.cfg"), $port) -RedirectStandardOutput $log -PassThru -NoNewWindow
try {
    $deadline = (Get-Date).AddSeconds(60)
    while (-not ((Test-Path $log) -and (Select-String -Path $log -Pattern "Accepting connections" -Quiet))) {
        if ((Get-Date) -gt $deadline -or $proc.HasExited) {
            Write-Host "FAIL: the driver did not start listening"
            exit 1
        }
        Start-Sleep -Milliseconds 200
    }
    $failed = 0
    foreach ($part in @("new", "again", "edit")) {
        $got = @(& $client $port (Join-Path $here "fixtures\ds39_login_$part.script"))
        $want = @(Get-Content (Join-Path $here "fixtures\ds39_login_$part.expected.txt"))
        $diff = Compare-Object (Normalize $want) (Normalize $got) -SyncWindow 0
        if ($diff) {
            $diff | Select-Object -First 20 | ForEach-Object { Write-Host "$($_.SideIndicator) $($_.InputObject)" }
            Write-Host "FAIL: ds39_login_$part differs from the reference"
            $failed++
        } else {
            Write-Host "ds39_login_$part`: $($want.Count) lines match"
        }
    }
    if ($failed -eq 0) {
        Write-Host "PASS: all three logins match the reference"
        exit 0
    }
    exit 1
} finally {
    if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force }
    $proc.WaitForExit()
    Remove-Item -Recurse -Force $scratch
}
