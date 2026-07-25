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
   feature at a time.
2. **Audit every f-string/`print`-family format-specifier table for missing
   type arms.** The fieldless-enum-prints-as-garbage-hex bug (silent wrong
   output, no crash, no diagnostic) is the worst bug class this project has
   shipped, and it was only caught by a human reading console output. Write
   an exhaustive test that round-trips every `Ty` variant through `print`/
   f-string interpolation and fails loudly on any silent fallthrough to a
   catch-all specifier, so the next new type can't ship this bug again.
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
    living scratchpad.
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
