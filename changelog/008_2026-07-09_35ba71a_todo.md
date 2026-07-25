# Star Compiler — Next Steps

## Immediate:

What's missing or notably incomplete


4. Missing general-purpose language features (not called out in the design doc, but needed for a usable language):

No for loop over ranges/collections (the for/in tokens exist but are only used for impl Trait for Type).
No break/continue.
No enums, no Option/Result, no arrays/lists/collections beyond arena slot arrays.
No modules/imports — everything is one file.
No user-defined generics (only the builtin GenRef<T> uses generic syntax).
No closures/lambdas.
Match patterns can't destructure structs or match on enums (since there are none).

5. Small but real bugs:

main.rs cmd_build hardcodes E:\LLVM\bin\clang.exe with no PATH fallback, contradicting the README's "Clang on PATH (or at E:\LLVM\bin\clang.exe)".
Indirect/function-pointer calls are rejected (codegen.rs:1303) — only direct calls work.