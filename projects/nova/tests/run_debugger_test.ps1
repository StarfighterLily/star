# Regression test for debugger.star (todo.md P1 #1) -- a scripted-stdin-
# in/captured-stdout-out comparison against a fixed tests/asm/*.bin, same
# spirit as run_bin.star's register-comparison tests (see NOTES.md
# "Testing") but exercising the REPL's own command surface (help/regs/
# disasm/step/step N/mem/stack/break/breakpoints/run/clear) rather than
# just the underlying Cpu. debugger.star was previously verified only
# once, interactively, in the session that built it -- this makes that
# verification checked-in and rerunnable.
#
# debugger_test_commands.txt drives tests/asm/write_width_test.bin (whose
# own header comment documents its expected final R1-R8 values) through:
# help, regs, a disasm listing, a single step, a multi-step, more regs,
# a raw memory dump, a stack dump, setting/listing/hitting/clearing a
# breakpoint at its HLT (0x006C, found via disasm.exe), and quit.
# debugger_test_expected.txt is that exact session's real captured output,
# not hand-derived -- regenerate it (see bottom of this file) only when a
# deliberate debugger.star change is expected to alter REPL output.
#
# Usage: powershell -File projects/nova/tests/run_debugger_test.ps1
# (rebuild debugger.exe first if debugger.star changed -- see debugger.star's
# own header comment for the build command.) Exits 0 on match, 1 otherwise.
#
# Dead end recorded here per this project's own convention (NOTES.md /
# todo.md P3 #6): feeding stdin via a live pipe -- either a .NET
# `Process.StandardInput.Write`/`Close()` (PowerShell) or piping a
# `Get-Content` array into the exe -- reliably corrupts the *first* line
# `read_line()` sees (e.g. "help" silently becomes an unrecognized
# command), even though the exact same command script piped through a
# real disk file (Bash `<` redirection, or `Start-Process
# -RedirectStandardInput <file>` here) reads back correctly every time.
# Root cause not chased down (likely a timing/buffering interaction
# between the Star runtime's `read_line()` and an anonymous pipe with a
# delayed first write, as opposed to a disk-file-backed handle) -- worth
# revisiting if `read_line()` ever needs to support live/interactive pipe
# input for real, but irrelevant here since `-RedirectStandardInput` is a
# real file the whole time. This is why this script uses `Start-Process
# -RedirectStandardInput`/`-RedirectStandardOutput` (both real files)
# rather than a `Get-Content | & $exe` pipeline.

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$novaRoot = Split-Path -Parent $here
$debugger = Join-Path $novaRoot "debugger.exe"
$commandsFile = Join-Path $here "debugger_test_commands.txt"
$expectedFile = Join-Path $here "debugger_test_expected.txt"
$binArg = "tests/asm/write_width_test.bin"

if (-not (Test-Path $debugger)) {
    Write-Error "debugger.exe not found at $debugger -- build it first (see debugger.star's own header comment for the build command)."
    exit 1
}

$actualFile = Join-Path ([System.IO.Path]::GetTempPath()) "nova_debugger_test_actual.txt"
Start-Process -FilePath $debugger -ArgumentList $binArg -WorkingDirectory $novaRoot `
    -RedirectStandardInput $commandsFile -RedirectStandardOutput $actualFile -NoNewWindow -Wait

$actual = Get-Content $actualFile -Raw
$expected = Get-Content $expectedFile -Raw
Remove-Item $actualFile -Force -ErrorAction SilentlyContinue

if ($actual -eq $expected) {
    Write-Host "PASS: debugger.star REPL output matches $expectedFile"
    exit 0
} else {
    Write-Host "FAIL: debugger.star REPL output differs from $expectedFile"
    $actualLines = $actual -split "`r?`n"
    $expectedLines = $expected -split "`r?`n"
    Compare-Object $expectedLines $actualLines | Format-Table -AutoSize
    exit 1
}

# To regenerate debugger_test_expected.txt after a deliberate output change:
#   Start-Process -FilePath projects/nova/debugger.exe `
#       -ArgumentList "tests/asm/write_width_test.bin" `
#       -WorkingDirectory projects/nova `
#       -RedirectStandardInput projects/nova/tests/debugger_test_commands.txt `
#       -RedirectStandardOutput projects/nova/tests/debugger_test_expected.txt `
#       -NoNewWindow -Wait
