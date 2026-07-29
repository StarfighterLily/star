# Star Compiler — Next Steps

**P0: Protect what Nova's stress-testing has already proven fragile.**
1. **Done.** Generalized the `MOV`-only write-width fix
   (`Cpu::write_width_for`) to every opcode handler in `cpu.star` that
   writes a result back to a memory destination — ~30 call sites across
   arithmetic/bitwise/BCD/math-library/string-conversion. Also found and
   fixed two more bugs the same live-reference-verification pass turned up:
   PUSH/POP always used a fixed 16-bit stack slot instead of the
   reference's actual operand-kind-dependent width, and BCDA/BCDS/BCDADD/
   BCDSUB checked their carry/borrow flag against the *masked* result
   instead of the raw pre-mask value (a previous NOTES.md entry had
   mis-documented this as intentional reference behavior). See
   `projects/nova/NOTES.md`'s "Generalizing the write-width fix" section
   for the full write-up, verification against the live Python reference,
   and what this means for the upstream Python emulator.
2. **Done.** Added `Checker::check_stack_budget` (`src/types/stack_budget.rs`):
   a `star check`-time (and `star build`-time) heuristic warning, run once a
   module has type-checked cleanly, that sums each function/method's own
   `let`-bound aggregate footprint plus the heaviest reachable static call
   chain's footprint on top of it, and warns (never errors — a new
   `Checker`/`Compilation`/`IrVerification`-style `warnings` side channel,
   entirely separate from the fatal `errors` path) at any function whose own
   footprint is non-zero and whose combined total reaches 1MiB — the exact
   "Windows' 1MiB linker-default stack overflowed" incident class
   `DEFAULT_STACK_SIZE_BYTES` already fixed after the fact for `star build`'s
   linked executables, now caught at compile time instead. Deliberately a
   heuristic (recomputes approximate byte sizes from the checker's own typed
   struct/enum field lists rather than chasing `Codegen::type_size`'s exact
   LLVM alignment/padding, and only traces a call graph edge it can resolve
   statically — a call through a closure/function value is a silent,
   accepted false-negative gap); recursion (direct or mutual) is bounded by a
   per-DFS-path visited set rather than memoized globally, so it can't hang
   the compiler on a recursive program. 11 new tests in
   `tests/frontend_stack_budget_warning.rs` cover: the core "neither function
   alone crosses budget, but the caller's combined total does" incident
   shape (and that only the true combination point, not the innocent callee,
   is named); method-call-graph resolution; nested-struct field summation;
   heap-backed `List<T>` never being flagged; direct and mutual recursion
   terminating promptly instead of hanging; and the finding's severity
   staying `Warning` (never blocking a clean compile).

**P1: Close the distance between "seam exists" and "port is actually cheap."**
 3. Scope (don't necessarily build yet) what a portable text-
   rendering path would need — `stb_truetype` is the cheapest realistic vendor
   option — so that if cross-platform ever becomes a real goal, the one
   component `platform.rs`'s own doc comment flags as *not* covered by the
   seam has a plan rather than a shrug.
4. Consider whether Nova's UART host bridge and sound synthesis
   (both explicitly scoped out, both requiring realhost I/O) are worth
   pulling forward as the *next* stress test — they are the two remaining
   places Nova's own "Ideas for future work" list identifies as needing 
   genuinely new language-level I/O capability (sockets, audio mixing)
   rather than more opcode coverage.

**P2: Reduce the adoption barrier before this is shown to a second person.**
5. A minimal LSP (even just diagnostics-on-save via `star check`,
   no autocomplete) would do more for a first impression than any single
   language feature at this point, now that the TextMate grammar has already
   solved the cheaper half of "can someone read this in an editor."
6. Pick a versioning policy now, while it's still cheap: even a one-paragraph
   "pre-1.0, no stability guarantee, breaking changes land in `changelog/`" is
   better than silence, and is a five-minute fix relative to everything else
   on this list.

**P3: Institutionalize the review cadence that has repeatedly proven valuable.**
7. This is the third full assessment in three stages, each
   finding real issues the day-to-day feature work didn't surface on its own.
   Consider tying the next one to a concrete trigger (e.g., "every N
   changelog entries" or "before any session that adds a new codegen module")
   rather than continuing to rely on someone remembering to ask.

# Previous work
src/types/stack_budget.rs (new): `Checker::check_stack_budget`, a `star check`-time stack-budget heuristic warning (todo.md P0 #2) — per-function `let`-aggregate footprint plus deepest static call-chain footprint, warning at 1MiB combined.
src/types/mod.rs, src/driver.rs, src/main.rs: threaded a new non-fatal `warnings: Vec<Diagnostic>` channel through `Checker` → `Compilation` → `star check`/`star build`'s stderr output, parallel to the existing fatal `errors`/`diagnostics` path and mirroring how `IrVerification` already splits errors/warnings for codegen.
tests/frontend_stack_budget_warning.rs (new): 11 tests covering the combined-call-chain incident shape, method-call resolution, nested-struct sizing, heap-backed-container exclusion, recursion termination, and warning severity.
todo.md: P0 #2 marked done with a pointer to this write-up.

cpu.star: generalized write_width_for to ~30 handlers (todo.md P0 #1), fixed PUSH/POP's stack-slot width to match operand kind, and fixed a BCD read-width bug plus a BCD carry/borrow masking-order bug (the latter correcting a previously-wrong NOTES.md claim).
NOTES.md: full write-up of all three fixes with live-reference verification evidence, a correction of the prior incorrect BCD documentation, a new "Status: this port now supersedes the Python reference" section, and a "What to carry back to the Python emulator" section listing the two confirmed upstream bugs (stale PUSH/POP docs, easy-to-misread BCD statement order).
todo.md: P0 #1 marked done with a pointer to the NOTES.md write-up.
5 new checked-in regression tests in tests/asm/, each verified against the live Python reference before being added.

The full-suite background run finished with one failure: runtime_window_create_degenerate_dimensions_end_to_end (an SDL test creating windows with huge/degenerate dimensions), which crashed with an access violation. I reran it in isolation and it passed cleanly — this is a pre-existing flake from concurrent SDL/DLL contention when the whole suite runs in parallel (the codebase's own test helpers document this exact class of race), unrelated to my changes (which only touch the checker/driver/CLI, never SDL or codegen). Not a regression.

Summary: todo.md's P0 #2 is done. Checker::check_stack_budget (new src/types/stack_budget.rs) gives star check/star build a heuristic warning when a function's own aggregate let footprint combined with its deepest static call chain crosses 1MiB — turning the exact "combined stack usage across nested calls" incident class into a compile-time signal instead of a runtime crash. Warnings flow through a new non-fatal Checker/Compilation channel that never blocks a clean compile. 11 new tests in tests/frontend_stack_budget_warning.rs cover the core incident shape, method-call resolution, nested structs, heap-backed containers, and recursion safety — all passing, with the rest of the repo's test suite (1000+ tests) green aside from that one unrelated flake.

