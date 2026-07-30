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
1. **Done.** Both halves are now real, working implementation, not stubs:
   - **Sound synthesis**: new `projects/nova/sound.star` generates actual
     PCM waveforms (square/sine/sawtooth/triangle/white-noise/pink-noise-
     approximation/memory-sample) in Star, wraps them as a canonical WAV
     file (`wav_header`), and round-trips them through the existing
     `crate::codegen::audio` mixer (`file_write_bytes` -> `sound_load` ->
     `sound_play`/`music_play`) — chosen specifically because `sound_load`
     only accepts a file, not raw in-memory samples, and this needed no new
     compiler builtin to close that gap. `cpu.star`'s `op_splay`/`op_sstop`/
     `op_strig` now call into it for real instead of the old `self.halted =
     self.halted` no-ops. Documented, deliberate simplifications: every
     generated WAV handle is leaked (no safe free point without a "channel
     finished" callback from the mixer), `SW`'s channel-select bits are
     decoded but collapsed onto the backend's one loop channel + one
     one-shot pool (not 8 independent voices), and "pink noise" is a 3-tap
     white-noise average, not a true 1/f filter. See `sound.star`'s header
     comment for the full rationale.
   - **UART host bridge**: `uart.star` gained `host_push_rx` (a real host
     byte lands in the data register and raises the serial interrupt if
     enabled — previously `SERIN` could only ever read back what `SEROUT`
     itself last wrote, an unreachable-from-outside loopback), and
     `cpu.star`'s `op_serout` now actually prints every transmitted byte to
     the process's own stdout (`print(chr(..))`, chosen over an f-string
     interpolation because `emit_print_like` always appends a trailing `\n`
     to an f-string argument regardless of `print`/`println`, which would
     have injected a spurious newline after every byte). A new headless
     entry point, `projects/nova/uart_bridge.star`, is the actual bridge
     driver: blocks on `read_line()` for host input the same way a real
     interactive terminal does, pushes each byte into `SERIN`'s path via
     `host_push_rx`, and lets `SEROUT` output appear inline on the same
     console. TCP was deliberately not used for the bridge transport —
     `net.rs`'s `tcp_recv` has no non-blocking/timeout mode, so it would
     freeze a bridge loop waiting on a peer with nothing to send; a
     terminal is *supposed* to block on the next line of input, which is
     exactly what `read_line()` already gives for free. This is also why
     the bridge is its own separate headless tool rather than wired into
     `main.star`'s real-time graphical loop.
   - Both required no new compiler-level builtins (`bytes_from_str`/`chr`/
     `file_write_bytes`/`sound_load`/`sound_play`/`music_play`/`read_line`
     already existed) — matches this item's original "no new language
     surface should be needed for a minimal version" framing exactly.
   - Verified: the existing `tests/asm/uart_integration_test.bin` still
     passes (`P0=0xBEEF`) with the real TX path live (visibly prints `A` to
     stdout before the register dump now, where it previously printed
     nothing); a throwaway headless harness (not checked in, matching this
     project's established "Testing" convention for one-off verification)
     exercised `host_push_rx`'s status-flag transitions, `sf_to_freq`'s
     endpoints, `wav_header`'s exact byte layout, and a live `op_splay`/
     `op_strig` trigger for all 8 `STRIG` effect ids end to end with no
     crashes and correctly-sized generated WAV files; full `cargo
     +stable-x86_64-pc-windows-gnu test` passed clean (every suite, 0
     failed) after the change, including the two Nova build targets
     (`tests/run_bin.exe`, `main.star`'s `nova16.exe`) needing `-l SDL2`
     linked now that `cpu.star` transitively pulls in the audio builtins —
     `tests/run_bin.star`'s own header comment ("no SDL linking needed")
     is now stale and should be corrected the next time that file is
     touched.
   - One incidental finding while implementing `sf_to_freq`:
     `docs/SOUND_SYSTEM.md`'s own worked example ("SF=128 -> ~440Hz (A4)")
     doesn't actually satisfy the formula given directly above it in the
     same doc (`55 * 32^(SF/255)` evaluates to ~313Hz at SF=128, not 440Hz)
     — implemented literally to the formula, not the example, and flagged
     in `sf_to_freq`'s own doc comment rather than silently picking one.
2. **Done.** `.clinerules/general.md` and `.clinerules/workflows/todo`
   were out of sync with `CLAUDE.md` in two different ways, not one:
   `general.md` still only had its original two lines (Rust formatting +
   PowerShell) — no toolchain override, no reassessment trigger, nothing
   from `CLAUDE.md` at all. Meanwhile `workflows/todo` had been given a
   verbatim copy of the *entire* `CLAUDE.md` file (title `# CLAUDE.md`
   and all), including sections that have nothing to do with the todo
   workflow (build toolchain, doc style, testing conventions, platform
   scope, "things not to do") — technically present, but dumped
   undifferentiated into the one file Cline actually invokes as the
   `/todo` workflow, which is not the same as being in sync with
   `CLAUDE.md`'s own two-file split (general rules vs. todo-workflow
   steps). Fixed by actually splitting content by relevance instead of
   duplicating everything into both files:
   - `.clinerules/general.md` now carries the general, always-applicable
     rules: the `+stable-x86_64-pc-windows-gnu` toolchain override,
     documentation style, testing conventions, platform scope, and
     "things not to do" — i.e. everything in `CLAUDE.md` *except* the
     todo-list-specific workflow steps.
   - `.clinerules/workflows/todo` now carries only "Working the todo
     list" and the "Reassessment trigger" section (with its full
     archive-naming/`changelog/` procedure) — the two sections that are
     actually specific to processing `todo.md`.
   - Preserved the CRLF line endings both files already used (the prior
     `workflows/todo` copy had introduced CRLF; `general.md` predates it
     and was already CRLF) rather than introducing a mixed-line-ending
     diff.
   - `CLAUDE.md` itself was not changed — its claim that the two Cline
     files "cover the same ground" still holds; they now do so by
     covering the relevant subset of that ground in the file Cline
     actually reads for each purpose, rather than by both containing an
     identical dump.

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

projects/nova/sound.star (new): real waveform synthesis (square/sine/
sawtooth/triangle/white-noise/pink-noise-approximation/memory-sample) for
`SPLAY`/`SSTOP`/`STRIG`, played back by round-tripping a generated WAV
buffer through the existing `sound_load`/`sound_play`/`music_play` mixer.
projects/nova/uart.star: added `host_push_rx` — a real host-bridge RX path
into the UART's data register/interrupt-pending state, previously only
reachable via `SEROUT`'s own loopback.
projects/nova/uart_bridge.star (new): headless stdin/stdout UART host
bridge entry point (`read_line()`-driven, blocking by design — see the
file's own header comment for why TCP was rejected for this).
projects/nova/cpu.star: `op_splay`/`op_sstop`/`op_strig` now call into
`sound.star` for real instead of the old `self.halted = self.halted`
no-ops; `op_serout` now prints every transmitted byte to stdout via
`print(chr(..))`.
todo.md: P0 #1 marked done with the summary above.

.clinerules/general.md: gained everything from `CLAUDE.md` that isn't
todo-workflow-specific — the `+stable-x86_64-pc-windows-gnu` toolchain
override, documentation style, testing conventions, platform scope, and
"things not to do" — on top of its original two lines (Rust formatting,
PowerShell-only shell). Previously had none of this.
.clinerules/workflows/todo: replaced a verbatim full-file copy of
`CLAUDE.md` (including its own `# CLAUDE.md` title) with just the two
sections actually specific to this workflow: "Working the todo list" and
the "Reassessment trigger" (with the full archive-naming/`changelog/`
procedure). The rest now lives only in `.clinerules/general.md`, so the
two Cline files no longer duplicate each other's content wholesale.
todo.md: P0 #2 marked done with the summary above.
