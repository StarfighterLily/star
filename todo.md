# Star Compiler — Next Steps

Prioritized from [ASSESSMENT.md](ASSESSMENT.md)'s technical review. Ordered by
risk-to-the-language's-own-thesis and how much each item unblocks real
programs, biggest lever first within each tier.

## P0 — Structural risk (affects every future feature, not just one gap)

1. **Add an IR-validity check ahead of the `clang` boundary.** Several
   confirmed bugs (`frame:` block ending in `return`, trailing `if/else` with
   a bare-ident arm) were `star check`-clean but produced invalid LLVM IR
   that only `clang` caught. At minimum: assert every emitted basic block
   ends in exactly one terminator before handing `.ll` to `clang`, and assert
   every `emit_expr` return value carries its type tag (`reg_of`'s own
   documented convention) before it reaches a `phi`/merge site. This is the
   single highest-leverage fix — it closes an entire *class* of bug the
   hand-rolled textual-IR approach will otherwise keep re-discovering one
   feature at a time. -- Done: See previous work below for details.
2. **Audit every f-string/`print`-family format-specifier table for missing
   type arms.** The fieldless-enum-prints-as-garbage-hex bug (silent wrong
   output, no crash, no diagnostic) is the worst bug class this project has
   shipped, and it was only caught by a human reading console output. Write
   an exhaustive test that round-trips every `Ty` variant through `print`/
   f-string interpolation and fails loudly on any silent fallthrough to a
   catch-all specifier, so the next new type can't ship this bug again. --
   Done: See previous work below for details.
3. **Give `Map`/`Set`/`Symbol` real hash-table backing.** Currently O(n) on
   every operation, which directly contradicts the "AAA entity counts"
   framing used to justify `Symbol` in the first place. This is a purely
   internal change (docs already say so) — no syntax/semantics shift needed,
   just replacing the linear scan with a real hash table behind the existing
   API.

## P1 — Gaps that block realistic multi-file / at-scale programs

4. **Module search-path resolution + minimal manifest.** `projects/snake`'s
   own dogfooding notes call this "the most significant gap ... still open."
   Every import is a hand-written relative path with no project root, no
   search path, no package identity. Needed before any project bigger than a
   handful of files is comfortable to maintain.
5. **Make `frame:`'s bump-allocator budget configurable per block**, mirroring
   the fix already done for arena capacity (`arena Name: Type = N`). The
   hardcoded 4096-byte cap is easy to blow with unremarkable code (confirmed
   by the doc's own A*-pathfinding example) and there's currently no way to
   size it to the actual workload.
6. **Reconcile the `par`/`swarm` concurrency docs with what's implemented.**
   `docs/design.md`/`docs/features.md` describe cross-system "compile-time
   locks" resolving overlapping component-array access across a tick; the
   actual `par_analysis.rs` check is a single-loop-only capture-mutation
   rule. Either document the real (narrower, still-sound) guarantee
   accurately, or extend the analysis to actually match the pitch — but stop
   letting the docs promise a scheduler that doesn't exist.

## P2 — Real but lower-blast-radius feature gaps

7. **Trait-bounded generics** (`fn f<T: SomeTrait>(x: T)`). Today a generic
   function can only move/store/return a `T` — it can't call a trait method
   or use an operator on it. Fine for container-shaped generics (`Box<T>`,
   `Stack<T>`), a real ceiling for anything else.
8. **Audio playback and gamepad input.** Long-deferred, explicitly and
   honestly labeled as such — but "game programming language" without audio
   is a real, user-visible hole, not a nice-to-have.
9. **A proportional/lowercase-aware text renderer**, or a documented,
   supported path to bind `SDL_ttf` for anything beyond a debug HUD. The
   current 5x7 uppercase-only bitmap font is fine for a score counter, not
   for shippable UI text.
10. **General place-projection into `Table<T>`** (`table[i].field = v`),
    closing the one documented gap in that type's method surface.

## P3 — Process / maintainability (won't block a single feature, but compounds)

11. **Stop discarding `todo.md`/`current_status.md` history wholesale.**
    Current workflow rewrites/clears both after every session
    (`.clinerules/workflows/todo`), so the only durable record of *why* a
    decision was made lives in scattered doc prose and `git log -p`. Keep a
    real `CHANGELOG.md` (append-only) even if `todo.md` itself stays a
    living scratchpad. -- Done: `.\changelog` now acts as the long-term storage for implementation documentation.
12. **Give the checker/codegen binop-dispatch pattern a real abstraction
    before it grows further.** Every new scalar-ish type (`Wrapping`,
    `Fixed`, `Symbol`, `Color32`, `Tick`/`Duration`/`Instant`, `BitField`,
    `Flags`) adds its own dedicated dispatch branch rather than folding into
    a general predicate, by design (each has different legal-operator
    semantics). That's the right call per-type, but the growing list of
    one-off branches is a maintainability trend worth addressing with a
    shared table/trait rather than continuing to hand-add arms.
13. **Document and/or fix the Windows build story.** Building this compiler
    today requires `cargo +stable-x86_64-pc-windows-gnu` plus a hand-
    maintained `vendor-libs` stub directory — a plain `cargo build` fails
    outright on the reference machine. Fine for a solo project; a real
    barrier if outside contribution is ever a goal.

# Previous work:
Added an IR verification phase (src/ir_check.rs) that runs after LLVM IR codegen and before the IR is ever handed to clang, directly addressing the "Ugly #1" gap identified in ASSESSMENT.md: a hand-rolled textual IR emitter with no builder verifying well-formedness ahead of the clang boundary.

What it checks, grounded in reading the actual .ll dialect this emitter produces (not general LLVM IR):

Every basic block ends with exactly one terminator (ret/br/unreachable) and nothing follows it — this is the exact shape of the documented frame:-block-ending-in-return bug (store emitted after ret).
phi nodes are grouped at the top of their block, their incoming-label list matches the block's actual predecessors, and (best-effort) incoming value types agree with the phi's declared type — targets the documented "untagged register" bug.
No duplicate SSA register or function/global definitions (defense against the diamond-import mangling bug class).
Every branch target is a real label; every %register/@global reference resolves to something actually defined (skipping llvm.* intrinsics, which clang auto-declares from the call site).
ret types match the function's declared signature.
Wired into Driver::codegen (src/driver.rs) so every caller — star build, star emit llvm, and the test suite — gets it automatically rather than opt-in.

Validated it: scanned all 73 shipped .ll files plus the 7,900-line projects/snake/main.ll (zero false positives), ran it against all 1,331 existing tests (initially caught 3 real false positives from my own checker — a phi-type-parsing bug when the phi's type itself starts with [ — which I fixed and turned into regression tests), and added 16 targeted unit tests including direct reproductions of both historically-documented bug classes. Full end-to-end star build → clang → run still works correctly.

Robustness expansion (src/ir_check.rs):

Added Severity::{Error, Warning} to IrError — findings that clang genuinely rejects stay build-blocking Errors; findings that are legal-but-suspicious IR (e.g. an unreachable block) are non-blocking Warnings.
New checks: duplicate basic-block labels, unreachable/orphaned blocks (warning-only — validated against a real fixture, struct_destructure.ll's intentional unreachable catch-all block, confirming the severity split was necessary), and call-argument-count mismatches against in-module declare/define signatures (including correct handling of the call i32 (i8*, ...) @printf(...) explicit-signature syntax variadic calls actually use — caught and fixed a real bug in my first draft of that check).
Added a permanent regression test that runs verify() against all 74 shipped .ll fixtures and asserts zero Error-severity findings, plus a fuzz test (2000 random garbled inputs) and hand-written adversarial cases (unbalanced brackets, unterminated strings, huge integer literals) asserting the checker never panics.
Graceful failure (src/driver.rs, src/main.rs):

Driver::codegen_verified now wraps the call to ir_check::verify in catch_unwind: a bug in this best-effort heuristic checker degrades to a warning instead of crashing the whole compiler.
The generated IR is no longer discarded when verification fails — IrVerification { ir, errors, warnings } always carries the IR text. star build now writes the .ll file even on a verifier rejection (so a false positive isn't a dead end), and star emit llvm — the actual debugging tool — always prints the IR regardless of verifier findings.
Added star build --skip-ir-verify as an explicit escape hatch to let clang have the final word when the verifier is wrong.
Driver::codegen's signature (used by ~200 existing tests) is untouched — it's now a thin wrapper over codegen_verified.

Audited every f-string/print-family format-specifier table (todo.md P0 #2), directly targeting the fieldless-enum-prints-as-garbage-hex bug class. Found there are actually two independently-implemented specifier tables — println(f"...")'s direct-argument path (Codegen::emit_print_like, builtins.rs) and the general f-string-as-str-value path (TypedExpr::FStr, expr.rs) — each with its own `_ => %p` catch-all and its own history of missing arms.

Reproduced a new, worse instance of the bug class live: interpolating a struct/tuple/array/GenRef/Handle/closure/Ring value into an f-string compiled clean and ran clean, silently printing a garbage address (`println(f"point={p}")` for a two-i32-field struct printed `0000000000000001`) instead of erroring — worse than the enum case because these seven types lower to an LLVM aggregate passed *by value* (`%Name`/`{..}`/`[N x T]`/`%GenRef`/`{i8*,i8*}`), so tagging one as a vararg `%p` pointer is a real C-ABI mismatch, not just an unhelpful address.

Fixed two ways:
- Added `Ty::is_fstring_unprintable` (types/mod.rs) classifying `Named`/`GenRef`/`Handle`/`Tuple`/`Array`/`Ring`/`Closure` as having no defined print format; `Checker::infer_expr`'s `Expr::FStr` arm (types/expr.rs) now rejects interpolating one with a clean "cannot interpolate a `Ty` value into an f-string" diagnostic instead of letting it reach codegen.
- Made both codegen specifier matches exhaustive — removed the `_ => %p` wildcard entirely from both `emit_print_like` (builtins.rs) and `TypedExpr::FStr` (expr.rs), replacing it with explicit arms: the seven pointer-backed types (`List`/`Map`/`Set`/`Table`/`Palette`/`Bytes`/`Ptr`, all a bare `i8*`) keep `%p` as a deliberate, ABI-safe "print the address" arm; the seven aggregate-by-value types get `unreachable!()` (defense-in-depth — the checker should already have rejected them); the vector/matrix/`Fixed` types get `unreachable!()` too (they're filtered/substituted earlier in the same function). With no wildcard arm left, a future `Ty` variant that isn't sorted into one of these buckets now fails to *compile*, not just fails a test — the strongest form of "the next new type can't ship this bug again."

Added 4 new tests (tests/frontend.rs): two exhaustive round-trip tests (one per format-specifier table) covering all 32 printable `Ty` variants' exact expected output in one pass each, one smoke test confirming the 7 pointer-backed types still compile/run/print without crashing, and one confirming all 7 previously-silently-broken aggregate types now produce a clean diagnostic instead of miscompiled IR. Repurposed one obsolete pre-existing test (`codegen_println_fstring_interpolating_struct_releases_borrowed_reference`, which asserted RC-release behavior for a now-rejected pattern) into a checker-diagnostic test. Full suite (1335 tests) passes.