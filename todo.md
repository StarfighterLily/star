# Star Compiler — Next Steps

Seeded from `current_status.md`'s "Next steps, prioritized" section
(reviewed at commit `9b4e24c`, 2026-07-29). This reassessment's headline
finding: the prior `todo.md`'s P1 #4 was marked **Done.** with zero actual
implementation behind it, and `.clinerules/general.md`/`workflows/todo`
were never brought in sync with the same stage's own `CLAUDE.md` claim
that they were. Both are P0 here — fixing what a reassessment finds is
higher priority than new feature work, otherwise the reassessment cadence
itself loses credibility.

**P0: Fix what this review found, before it compounds.**
1. Either actually implement Nova's sound synthesis (waveform generation
   behind the already-dispatched `SPLAY`/`SSTOP`/`STRIG` opcodes, currently
   literal no-ops in `cpu.star`) and a real UART host bridge (stdin- or
   socket-backed, using the already-existing `file_io.rs`/`net.rs`
   builtins — no new language surface should be needed for a minimal
   version), or correct the record to accurately say "not started" and
   requeue it honestly. Marking it done a second time without the
   underlying work would be a second, compounding instance of the exact
   gap this reassessment exists to catch.
2. Bring `.clinerules/general.md` and `.clinerules/workflows/todo` into
   actual sync with `CLAUDE.md`/`docs/conventions.md` — at minimum the
   `+stable-x86_64-pc-windows-gnu` toolchain override (the single fact
   whose absence would send a Cline-based session down a "plain `cargo
   build` fails, why?" dead end) and the reassessment trigger.

**P1: Decide the versioning gate's own exit condition.**
3. Decide, concretely, what "Nova is complete" means for the versioning
   gate (`readme.md`'s "Versioning" section) — a fixed checklist of
   opcodes/subsystems, most plausibly — before `projects/nova/NOTES.md`'s
   "Ideas for future work" list grows further and makes the gate's target
   a moving one by default rather than by decision.

**P2: Genuinely new capability, once P0 is settled for real.**
4. If P0 #1 lands as real implementation work: sound synthesis and a UART
   bridge are still the right *next* stress test for Nova after the
   correction above — they're the two remaining items on Nova's own list
   needing genuinely new host-I/O-shaped capability rather than more
   opcode coverage.

**P3: Keep the cadence honest.**
5. Nothing structural to change in the reassessment mechanism itself — it
   fired correctly and the full test suite passed clean (exit 0, 0 failed
   across ~69 binaries) once it finished. The one adjustment worth
   carrying into the next cycle: start the full suite *first* and actually
   wait for its result before finalizing the reassessment document, rather
   than drafting concurrently with it.

# Previous work

See `changelog/066_2026-07-29_9b4e24c_todo.md` and
`changelog/066_2026-07-29_9b4e24c_current_status.md` for the full history
up to and including Stage 7 (write-width generalization, the stack-budget
checker, cross-platform scoping, `star lsp`, versioning policy, and
`CLAUDE.md`/`docs/conventions.md`) — archived per the reassessment
protocol before this file was reseeded from the fresh
`current_status.md`'s "Next steps" section above.
