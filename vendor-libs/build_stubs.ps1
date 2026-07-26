<#
.SYNOPSIS
Regenerates the stub libgcc.a/libgcc_eh.a archives in this directory, which
satisfy rustc's -lgcc_eh -lgcc when linking star for the
x86_64-pc-windows-gnu target against LLVM-mingw. Portable across checkout
location; the LLVM bin dir must still be supplied. See readme.md's
"Requirements" section. These stubs are x86_64-pc-windows-gnu
(COFF/mingw)-specific -- rerun this script for any other target triple.

.PARAMETER LlvmBinDir
Directory containing clang.exe/llvm-ar.exe (e.g. an LLVM-mingw install's
bin dir). Defaults to $env:STAR_LLVM_BIN_DIR if set.
#>
param(
    [string]$LlvmBinDir = $env:STAR_LLVM_BIN_DIR
)

$ErrorActionPreference = "Stop"
if (-not $LlvmBinDir) {
    throw "LLVM bin dir not specified: pass -LlvmBinDir <dir> or set `$env:STAR_LLVM_BIN_DIR."
}
$root = $PSScriptRoot
$llvm = $LlvmBinDir

# Create an empty object file to act as a valid archive member.
"x: .text" | Out-File -Encoding ascii "$root\empty.s"
& "$llvm\clang.exe" -c "$root\empty.s" -o "$root\empty.o"

# Build stub static archives libgcc.a and libgcc_eh.a.
& "$llvm\llvm-ar.exe" rcs "$root\libgcc.a" "$root\empty.o"
& "$llvm\llvm-ar.exe" rcs "$root\libgcc_eh.a" "$root\empty.o"

# Verify the linker can resolve -lgcc_eh -lgcc against this directory.
& "$llvm\clang.exe" -o "$root\test_link.exe" '-Wl,-Bstatic' -lgcc_eh -lgcc -L "$root" "$root\empty.o"
$exit = $LASTEXITCODE
if (Test-Path "$root\test_link.exe") { Remove-Item "$root\test_link.exe" }
Write-Host "LINK_TEST EXIT: $exit"