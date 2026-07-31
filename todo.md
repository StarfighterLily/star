# Star Compiler — Next Steps

Seeded from `current_status.md`'s "Next steps, prioritized" section
(reviewed at commit `82be6e2`, 2026-07-30). This cycle's headline finding:
`readme.md`'s versioning-gate conditions are, independently re-checked
condition by condition, satisfied — but whether and to what version the
project actually moves is a call for the user, not this document, per
`CLAUDE.md`'s own "Things not to do" and three prior reviews' precedent.
See `current_status.md`'s "Goals vs. reality, honestly" for the full
checklist and "The Bad" #1 for why that decision isn't executed here.

**P0: Nothing to fix — no false "Done." markers last cycle, and the one
genuine bug found mid-stage (the `clang` large-aggregate-reassignment
pathology) was root-caused and fixed within the same stage that found
it, with new regression coverage.**

**P1: The one decision this whole cycle has been building toward.**
1. **Done.** The version has been bumped to `0.2.0`. See below for details.
2. **Done.** See `P1 #1 & #2` for details.

**P2: Real, still-open gaps — none block the version question above,
since the gate never named them.**
3. **Done.** `sound.star`'s leaked WAV handles. See below for details.
4. `SMIX`/`SECHO`/`SREVERB`/`SFILTER` and `debugger.star` source-line
   breakpoints — both still genuinely out of scope, carried forward for
   visibility, not active work items.
5. The permanent structural caveats (Windows-only-by-construction scope,
   "special guest" types unified in docs not mechanism, non-dynamic
   monomorphized-only traits, warning-only stack-budget check) — not gaps
   to close, but worth keeping as a standing line item so a future
   version decision doesn't have to rediscover them from scratch.

**P3: Keep the cadence honest.**
6. This cycle was triggered two ways at once — `todo.md`'s own full
   completion, and the user asking for it directly — both converging on
   the same underlying question. Worth naming as a healthy sign, not a
   coincidence.
7. Continue starting the full `cargo test` run before drafting
   `current_status.md` rather than concurrently with it — two reviews
   running have now made this adjustment; keep doing it.

# Previous work
P2 #3: Fixed `sound.star`'s leaked WAV handles, the one remaining named
audio simplification. Every `SPLAY`/`STRIG` trigger built a fresh WAV
buffer, `sound_load`d it, and played it, but the returned handle was
discarded — `crate::codegen::audio`'s `sound_load` `malloc`s a fresh copy
of the whole file per call, so this leaked real heap memory on every
retrigger with no bound, growing without limit under sustained play (e.g.
a looping `SPLAY` retriggered every frame, or a `STRIG` sound effect fired
repeatedly). Fix: `sound.star`'s `play_pcm_wav_on_channel`/`play_tone`/
`play_memory_sample`/`trigger_effect` now return the new `ptr` handle
(`null_ptr()` on failure) instead of a bare `bool`; a new `Cpu` field,
`sound_channel_handles: [ptr; 16]` (`cpu.star`), tracks the one handle
currently occupying each of the 16 mixer channels this port addresses (0-7
`SPLAY`'s hardware voices, 8-15 `STRIG`'s round-robin pool); and
`cpu_sound.star`'s new `replace_channel_handle`/`free_all_sound_handles`
free a channel's previous occupant the instant a new one replaces it
there (safe with no per-channel "finished playing" callback, since
`sound_play_channel` has already overwritten that channel's `chan_base` to
the new buffer by the time the old one is freed — `sound_free`'s own
"stop any channel still using this buffer" scan finds no match for the
outgoing handle) or `SSTOP`/`Cpu::reinit` (`Reset`) free every tracked
handle outright. Every `Cpu`-constructing site (`main.star`,
`tests/run_bin.star`, `debugger.star`, `uart_bridge.star`) updated for the
new field. Verified with a new checked-in regression test,
`projects/nova/asm/sound_leak_test.asm`/`.bin` (retriggers the same
`SPLAY` hardware channel 20 times in a row with no wait for real playback
to finish, then saturates `STRIG`'s 8-slot round-robin pool twice over,
then `SSTOP`), run via `tests/run_bin.exe` — confirmed running clean to
`HLT` (exit code 0). Confirmed the test actually has teeth by temporarily
removing the null-handle guard in `replace_channel_handle`: the same test
then aborted immediately with `sound_free`'s own "null/freed sound handle"
runtime error, as expected, before the guard was restored. The existing
`sound_channel_test.bin` (todo.md P2 #5's own retrigger-a-looping-channel
scenario) and the full `tests/asm/*.bin` suite were re-run and still halt
clean. `main.star`/`debugger.star`/`uart_bridge.star` all rebuilt
successfully with the new field (`main.star`'s build needed `-l comdlg32`
in addition to `-l SDL2`, a pre-existing requirement for its native
"Open File" dialog, not a regression). `NOTES.md`'s "What's implemented"/
"What's not implemented"/"Known simplifications" sections and
`sound.star`/`cpu_sound.star`'s own header comments updated to describe
the fix rather than the former "intentionally leaked" framing.

Also surveyed the rest of the Nova project for any other undocumented
simplifications per this cycle's direct ask, cross-referencing `NOTES.md`'s
curated "What's not implemented"/"Known simplifications" sections (and a
fresh grep of every `.star` file under `projects/nova` for `leak`/`race`/
`stub`/`TODO`/`silently drop`/etc.) against what's already tracked here.
Nothing new surfaced: every remaining item is either already carried
forward as P2 #4/#5 above, or is explicitly documented as a deliberate,
justified design choice rather than a shortcut — e.g. `SBLEND` being a
stub is a confirmed bug-for-bug match with the Python reference (it never
calls its own blend-aware pixel write either), the timer ticking once per
instruction rather than per host clock cycle is inherent to writing an
interpreter rather than a cycle-accurate simulator, and the math library's
`f32`-vs-reference's-`f64` precision gap (reachable only in `POWR`/`EXP`'s
overflow thresholds) is already fully traced and accepted in `NOTES.md`'s
"Math library / Q8.8 fixed-point" section. No new P2 item warranted from
this pass.

P1 #1 & #2: Bumped version to an honest `0.2.0` across `cargo.toml` and `readme.md`, 
modified both `CLAUDE.md` and `.clinerules/general.md` to reflect the unbounded
version bump while raising the point to keep the version in sync across load-bearing
files and documentation alike to avoid stale version numbers anywhere, and 
updated `docs/conventions.md` to reflect the bump and further define incremental
policy (also reflected in Claude and Cline files).

See `changelog/069_2026-07-30_82be6e2_todo.md` and
`changelog/069_2026-07-30_82be6e2_current_status.md` for the full history
up to and including this cycle: a checked-in `debugger.star` regression
test (with a genuine live-pipe-vs-real-file stdin dead end recorded along
the way), F5-F8 hotkey verification closed for real (including a false
alarm from a demo binary's own deliberate `JMP $` idle loop), a concrete
"what does 'Nova complete' mean" checklist built and checked against
`NOTES.md`, a genuine new Star compiler bug (`clang` large-aggregate-
reassignment) root-caused and fixed, a true per-8-channel sound voice
model and real pink-noise filter for Nova's `SPLAY`, and `cpu.star`'s
opcode handlers split across 11 files by group — archived per the
reassessment protocol before this file was reseeded from the fresh
`current_status.md`'s "Next steps" section above.

See `changelog/068_2026-07-30_cacd569_todo.md` and
`changelog/068_2026-07-30_cacd569_current_status.md` for the cycle before
that (the repeated-f-string-call corruption bug root-caused and fixed, a
real assembler for `projects/nova`, and a real debugger plus GUI+controls
parity, a genuine Cpu SP/FP reset-value port bug found via the debugger's
first real use, and the `clang` build-time pathology first surfaced and
worked around) — also archived under the same reassessment protocol.
