$ErrorActionPreference = "Stop"
$root = "E:\Coding\Rust\star\vendor-libs"
$llvm = "E:\LLVM\bin"

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