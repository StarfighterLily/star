# Star Compiler — Next Steps

## Immediate:

What's missing or notably incomplete
1. ~~Generational references were a stub~~ — **fixed**. `GenRef<T>` now requires exactly one declared `arena Name: T`; creation (`GenRef<T>(idx)`) captures that slot's live generation, and dereference (`gen_ref[idx]`) bounds-checks and compares the stored generation against the arena's current one, falling back to the element type's zero value on any mismatch instead of reading stale/garbage data. A new minimal `despawn ArenaName[index]` statement bumps a slot's generation (no memory reuse/free-list yet — see item 3) so the safety guarantee is provable end to end; see `examples/genref_lifecycle.star` and `runtime_genref_stale_after_despawn_falls_back_to_zero` in `tests/frontend.rs`.

2. frame escape analysis doesn't exist. design.md calls this out as the safety requirement ("compiler enforces a strict escape analysis... frame pointers can never be assigned to lifetimes exceeding the current tick"), but types.rs:364 type-checks Stmt::Frame with no escape/lifetime checks at all. Nothing stops a frame-allocated value from being stored into a struct field or returned.

3. Arenas are still append-only for `data`/`count`. `spawn` grows an arena and `despawn` (new) bumps a slot's generation counter to invalidate `GenRef`s into it, but nothing reclaims/reuses that slot's memory — the "logical leak" mitigation design.md promises (§2, internal free-list for reuse) still isn't implemented. Every arena only grows.

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
6. todo.md was deleted in the last commit (e7d2ee3, "Reflection") with nothing replacing it, so there's no living milestone tracker — worth recreating if you want to keep planning against it.

Suggested priority
(1) generational references are now fixed (see above); (2) decide whether frame escape analysis is in scope soon, since shipping without it means the "no GC, but safe" pitch is currently just a bump allocator with no guardrails; (3) add an arena free-list so despawned slots' memory is actually reclaimed/reused, not just generation-invalidated; general control-flow gaps (for/break/continue) are lower risk and can follow once the memory model is trustworthy.