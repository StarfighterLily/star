# M6 verb-parser regression test on the real mudlib (todo.md HavokOS M6):
# boot Dead Souls 3.9, let its timers run 5 s, then run the reference's own
# parser golden script (fixtures/ds39_parser_transcript.lpc, a copy of
# havokos/pike/tests/ds_parser_golden.lpc): an NPC runs 50 commands in a room
# of stock items -- get/drop/put/give/wield/wear/look/smile/light, plurals,
# ordinals, "all", containers, errors -- and the transcript of every message
# and the inventory after each command is compared with the live Pike
# driver's, frozen in fixtures/ds39_parser_transcript.expected.txt.
#
# One normalization, for NOTES.md deviation #9 (mappings iterate in
# insertion order here, in Pike's hash order there): Dead Souls builds two
# kinds of sentence from a mapping's keys -- a room's "X, Y, and Z are
# here." and a living's "<name> is carrying:" item lines -- so their items
# are sorted before comparing. Everything else, the inventory lines (raw
# all_inventory() order) included, must match byte for byte.
#
# The run writes into the mudlib, so it uses a fresh copy in the temp
# directory, never E:\ds3.9\lib itself.
#
# Usage: powershell -File projects/havokos/tests/run_parser_transcript_test.ps1 [-DsRoot E:\ds3.9]
# (rebuild tools/boot_ds.exe first if any VM .star file changed:
#   target/release/star.exe build projects/havokos/tools/boot_ds.star -o projects/havokos/tools/boot_ds.exe -l ws2_32)
# Exits 0 when the transcripts match, 1 otherwise. About 10 s.
#
# Regenerating the fixture (only after confirming the *reference's* own
# behavior changed; same stubs as the boot test):
#   (copy E:\ds3.9\lib to a scratch directory first)
#   pike tools/ref_eval.pike <havokos>/pike E:/ds3.9/bin/mudos.cfg <scratch lib> tests/fixtures/ds39_boot_stubs.txt 5 tests/fixtures/ds39_parser_transcript.lpc
#   copy <scratch lib>/tmp/havok_vp_transcript.txt tests/fixtures/ds39_parser_transcript.expected.txt

param([string]$DsRoot = "E:\ds3.9")

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$tool = Join-Path $root "tools\boot_ds.exe"
if (-not (Test-Path $tool)) {
    Write-Error "boot_ds.exe not found at $tool -- build it first (see this script's header)."
    exit 1
}

# Sort what deviation #9 orders differently (see the header).
function Normalize([string[]]$lines) {
    $out = New-Object System.Collections.Generic.List[string]
    $i = 0
    while ($i -lt $lines.Count) {
        $l = $lines[$i]
        if ($l -match " are here\.") {
            $plain = ($l -replace "%\^[A-Z_]*%\^", "") -replace " are here\.$", ""
            $items = @($plain -split ", and |, | and " | ForEach-Object { $_.Trim().ToLower() } | Sort-Object)
            $out.Add("HERE: " + ($items -join " | "))
            $i++
            continue
        }
        if ($l -match " is carrying:$") {
            $out.Add($l)
            $i++
            $block = New-Object System.Collections.Generic.List[string]
            while ($i -lt $lines.Count -and -not $lines[$i].StartsWith("  [inv:")) {
                $block.Add($lines[$i])
                $i++
            }
            $block | Sort-Object | ForEach-Object { $out.Add($_) }
            continue
        }
        $out.Add($l)
        $i++
    }
    return $out
}

$scratch = Join-Path ([IO.Path]::GetTempPath()) ("havokos_vp_" + [Guid]::NewGuid().ToString("N"))
Copy-Item -Recurse (Join-Path $DsRoot "lib") $scratch
try {
    $cfg = (Join-Path $DsRoot "bin\mudos.cfg") -replace "\\", "/"
    $script = Join-Path $here "fixtures\ds39_parser_transcript.lpc"
    $res = @(& $tool $cfg ($scratch -replace "\\", "/") -wait 5 -eval $script | Where-Object { $_ -like "EVAL *" })
    if ($res.Count -ne 1 -or $res[0] -ne "EVAL 50") {
        Write-Host "FAIL: the script did not run all 50 commands: $res"
        exit 1
    }
    $got = Normalize @(Get-Content (Join-Path $scratch "tmp\havok_vp_transcript.txt"))
    $want = Normalize @(Get-Content (Join-Path $here "fixtures\ds39_parser_transcript.expected.txt"))
    $diff = Compare-Object $want $got -SyncWindow 0
    if ($diff) {
        $diff | Select-Object -First 20 | ForEach-Object { Write-Host "$($_.SideIndicator) $($_.InputObject)" }
        Write-Host "FAIL: the Star VM's parser transcript differs from the reference's"
        exit 1
    }
    Write-Host "PASS: DS3.9 parser transcript matches the reference ($($want.Count) lines, 50 commands)"
    exit 0
} finally {
    Remove-Item -Recurse -Force $scratch
}
