# Star Compiler — Next Steps

Seeded from `current_status.md`'s "Next steps, prioritized" section
(reviewed at commit `4082b7b`, 2026-07-30). This cycle's headline finding:
the version decision `069`'s review recommended but declined to make
unilaterally was actually made and executed this stage (`0.2.0`,
consistent across `Cargo.toml`/`readme.md`/`docs/conventions.md`) — the
open items below are small process/doc cleanup, not another round of
deferred decisions. See `current_status.md`'s "Goals vs. reality,
honestly" for the full verification and "The Bad" for where this cycle's
own work still has loose ends (two uncommitted files, one stale doc
reference).

**U0: User-added items**
1. Multi-line comments and other niceties would be worth scoping out.
   Populate a `docs/requests.md` file with such features that might be
   worth adding to the language that won't neccessarily unblock anything
   but would be useful/easier/etc.

**P0: Nothing to fix.** Full `cargo +stable-x86_64-pc-windows-gnu test`
re-run this cycle, exit code 0. No false "Done." markers found.

**P1: Small, concrete, worth doing before new feature work.**
1. **Done.** I had simply forgotten to do so before the reassessment triggered.
   Now committed along with the fresh reassessment and todo.
2. **Done.** Added a fragment next to the stale `0.1.0` reference indicating
   the version bump to "at least `0.2.0`", indicating advancement
   but intentionally imprecise to avoid having to update another spot continuously.

**P2: Real, standing items — none urgent, none blocking.**
3. **Done.** Framed-mode UART protocol parsing (start byte + length +
   payload + checksum), implemented in `uart.star`: `SERCTRL`'s control
   bit 2 (`0x04`, already documented in `docs/UART_SYSTEM.md` but
   previously inert in this port) now gates a byte-at-a-time frame parser
   (`parse_frame_byte`, driven from `host_push_rx`), and a genuinely new
   opcode, `SERFSTAT` (`0xB4` — `0xA6`-`0xAB` turned out to already be
   taken by unimplemented `SETBP`/`CLRBP`/`ENABRK`/`DISBRK`/`ENATRAP`/
   `DISATRAP` debugger pseudo-opcodes, found by grepping the assembler/
   disasm/debugger opcode tables before picking a number rather than
   trusting `cpu.star`'s dispatch switch, which was misleadingly silent
   about them), exposes framed-mode-enabled and a latched checksum-error
   bit that `SERSTAT`'s own two low bits never did. Good frames queue their
   payload into a real RX FIFO for `SERIN` to drain (raw mode's own
   single-register model is untouched — framed mode is additive); bad
   frames latch a read-and-clear checksum-error bit and fire the pending
   interrupt if enabled. New test: `tests/asm/uart_framed_test.asm` (a
   real assembled program exercising `SERCTRL`/`SERFSTAT`/`SERIN`/`SERSTAT`
   as actual opcodes) run through `tests/uart_framed_test.star`, a
   headless harness that steps the CPU for real and only reaches for
   `host_push_rx` directly to inject the frame bytes themselves (no opcode
   can do that, same as raw mode's own host bridge and `mouse_pending_irq`
   — see `mouse_interrupt_test.star`). Feeds one good frame and one
   checksum-mismatched frame; all 10 checks pass. Bug found along the way,
   not fixed at the time (out of scope for this item): `mouse_interrupt_test.star`'s
   own inline `Cpu` construction was stale against the current `Cpu` struct
   (missing `sound_channel_last_wav`/etc. added by a later round) and no
   longer rebuilt from source — its checked-in `.exe` still ran (compiled
   before the drift), so the regression was silent until someone touched
   that file next. Fixed in a follow-up direct ask: added the three missing
   fields (`next_strig_channel`/`sound_channel_handles`/
   `sound_channel_last_wav`), plus the `cpu_*.star` op-table imports and
   `-L sdl/lib/x64 -l SDL2` build flags the file was also missing (same
   requirement `uart_framed_test.star` documents) — it wasn't just the
   struct literal that had drifted, the file couldn't rebuild at all before
   this fix. Rebuilt `.exe` checked in; all 5 checks pass.
4. **Done.** The permanent structural caveats (Windows-only fonts, "special guest"
   types unified in docs not mechanism, non-dynamic monomorphized-only
   traits, warning-only stack-budget check) — not gaps to close, a
   standing line item so a future version decision (a `1.0.0` push)
   doesn't have to rediscover them from scratch. Durable home is `docs/
   design.md`'s "Known Permanent Caveats" section once P1 #1 lands it in
   git. --Now done.

**P3: Keep the cadence honest.**
5. **Done.** This cycle triggered two ways at once again — `todo.md`'s own full
   completion (including its P3 items, closed out specifically because
   they were process notes rather than concrete asks) and a direct user
   request for the reassessment, back to back. The automatic trigger and
   a direct ask converging is the system working as intended.
6. **Done.** Continue starting the full `cargo test` run before drafting
   `current_status.md` rather than concurrently with it — three reviews
   running have now made this adjustment; keep doing it.

# Previous work
P3: Marked off as done now so a task that closes out the todo can trigger a reassessment.
Worth keeping this convention: having visible items get marked as done in acknowledgement
instead of starting off as such ensures the items get seen and considered at least once.

Out-of-band: Updated Claude/Cline files to check the `docs/cross_platform_scope.md`
document for cross-platform reference without the "Windows only" statements preceding it.

P1: The uncommitted changes called out were committed alongside this round's
reassessment.

P2: Item 3 (UART framed-mode parsing) implemented after a direct user ask to
work it despite its own "not an active ask" framing — the ask included
deciding the previously-missing opcode surface, so `SERCTRL` bit 2 now gates
a real frame parser and a new opcode, `SERFSTAT` (`0xB4`), exposes the
framed-mode/checksum-error state `SERSTAT` never did. New checked-in test:
`tests/asm/uart_framed_test.asm` + `tests/uart_framed_test.star`, all 10
checks passing. See item 3's own summary above for the full design and the
stale-`mouse_interrupt_test.star` bug noticed but left unfixed as out of
scope.

See `changelog/070_2026-07-30_4082b7b_todo.md` and
`changelog/070_2026-07-30_4082b7b_current_status.md` for the full history
up to and including the cycle before this one: the version decision
`069` recommended finally made and executed (`0.2.0` across `Cargo.toml`/
`readme.md`/`docs/conventions.md`/`CLAUDE.md`/`.clinerules`), `sound.star`'s
leaked WAV handles fixed, `SMIX`/`SECHO`/`SREVERB`/`SFILTER` plus
`debugger.star` source-line breakpoints implemented from scratch (no
upstream reference for either), the permanent structural caveats
consolidated into a new `docs/design.md` section, and a real Linux devbox
coming online to devbox-link-verify `codegen/net.rs`/`os.rs`/`platform.rs`
and SDL2/gamepad packaging — archived per the reassessment protocol before
this file was reseeded from the fresh `current_status.md`'s "Next steps"
section above.

See `changelog/069_2026-07-30_82be6e2_todo.md` and
`changelog/069_2026-07-30_82be6e2_current_status.md` for the cycle before
that (a checked-in `debugger.star` regression test, F5-F8 hotkey
verification closed for real, a concrete "what does 'Nova complete' mean"
checklist built and checked against `NOTES.md`, the `clang`
large-aggregate-reassignment compiler bug root-caused and fixed, a true
per-8-channel sound voice model and real pink-noise filter, and
`cpu.star`'s opcode handlers split across 11 files by group) — also
archived under the same reassessment protocol.

See `changelog/068_2026-07-30_cacd569_todo.md` and
`changelog/068_2026-07-30_cacd569_current_status.md` for the cycle before
that (the repeated-f-string-call corruption bug root-caused and fixed, a
real assembler for `projects/nova`, and a real debugger plus GUI+controls
parity, a genuine Cpu SP/FP reset-value port bug found via the debugger's
first real use, and the `clang` build-time pathology first surfaced and
worked around) — also archived under the same reassessment protocol.
