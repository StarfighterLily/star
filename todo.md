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

**P0: Nothing to fix.** Full `cargo +stable-x86_64-pc-windows-gnu test`
re-run this cycle, exit code 0. No false "Done." markers found.

**P1: Small, concrete, worth doing before new feature work.**
1. Decide whether to commit the two outstanding working-tree changes —
   `docs/design.md`'s "Known Permanent Caveats" section (P2 #5 from the
   `069` cycle, real and correct on disk but never committed) and this
   cycle's own `todo.md` P3 closeout. A call for the user, not something
   to do unprompted.
2. Fix `projects/nova/NOTES.md`'s stale `0.1.0` reference (line 2143,
   "the language-wide `0.1.0` gate") to reflect the `0.2.0` move.
   One-line, mechanical.

**P2: Real, standing items — none urgent, none blocking.**
3. UART framed-mode protocol parsing (start byte + length + payload +
   checksum) — still deliberately out of scope, same shape `SMIX`/
   `SECHO`/`SREVERB`/`SFILTER` had before a prior cycle closed them: no
   opcode currently drives it, so there's nothing to observably test
   without first deciding to invent that opcode surface. Carried forward
   for visibility, not as an active ask.
4. The permanent structural caveats (Windows-only fonts, "special guest"
   types unified in docs not mechanism, non-dynamic monomorphized-only
   traits, warning-only stack-budget check) — not gaps to close, a
   standing line item so a future version decision (a `1.0.0` push)
   doesn't have to rediscover them from scratch. Durable home is `docs/
   design.md`'s "Known Permanent Caveats" section once P1 #1 lands it in
   git.

**P3: Keep the cadence honest.**
5. This cycle triggered two ways at once again — `todo.md`'s own full
   completion (including its P3 items, closed out specifically because
   they were process notes rather than concrete asks) and a direct user
   request for the reassessment, back to back. The automatic trigger and
   a direct ask converging is the system working as intended.
6. Continue starting the full `cargo test` run before drafting
   `current_status.md` rather than concurrently with it — three reviews
   running have now made this adjustment; keep doing it.

# Previous work

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
