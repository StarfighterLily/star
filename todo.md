# Star Compiler — Next Steps

Seeded from `current_status.md`'s "Next steps, prioritized" section
(reviewed at commit `cacd569` plus uncommitted work, 2026-07-30). This
reassessment's headline finding: the incoming `todo.md`'s one open item
(P2 #3, a debugger and GUI+controls parity for `projects/nova`) was
genuinely done — verified two different ways for its two halves (a live
MCP cross-check against the Python reference for the debugger, real
screenshot-based interaction for the GUI) — closing out every named
tooling gap in `readme.md`'s versioning gate for the first time since that
gate was written down. See `current_status.md`'s own "The Bad" for what
that verification pass didn't manage to confirm, and why "the list is
empty" isn't the same claim as "the list was complete."

**P0: Nothing to fix — no false "Done." markers this cycle, and the one
genuine bug found this stage (a Cpu SP/FP reset-value bug) was fixed
within the same stage that found it.**

**P1: Close this stage's own two honestly-flagged verification gaps.**
1. Add a checked-in regression test for `debugger.star` — every other
   recent Nova build target (`disasm.star`, `assembler.star`) shipped with
   real, automatable verification against `tests/asm/*`; the debugger was
   only verified once, interactively, in the session that built it. A
   scripted-stdin-in/captured-stdout-out comparison against a fixed
   `tests/asm/*.bin`, same spirit as `tests/run_bin.star` but exercising
   the REPL's command surface, is the natural shape.
2. Actually verify the F5-F8 hotkeys in `main.star`'s GUI. This stage's own
   synthetic `keybd_event` attempt was inconclusive (plausibly Windows'
   foreground-lock restrictions on a background process's simulated
   input) — the mouse-click equivalents were verified for real, but the
   hotkeys currently rest on "same underlying `running`/`single_step`
   variables" reasoning, not independent confirmation. Needs either a
   foreground-safe input-injection technique or a small temporary
   self-test hook.

**P2: Process debt that's been deferred past the point of being
defensible.**
3. Define what "Nova is complete" means, concretely, for `readme.md`'s
   versioning gate. Third reassessment in a row naming this
   (`067`'s "The Bad" #4, `068`'s "The Bad" #3, this one) — a fixed
   checklist (opcode/feature completeness, most plausibly building on
   `projects/nova/NOTES.md`'s own "What's implemented"/"What's not
   implemented" split) rather than an open-ended qualitative gate. Should
   not appear a fourth time without being acted on.
4. Investigate the `clang` large-aggregate-returned-repeatedly build
   pathology this stage found and worked around (not root-caused): an
   early `main.star` draft called a function returning a fresh, megabyte-
   plus `Cpu` by value a second/third time (for the `Reset` control), and
   that build took several minutes and multiple gigabytes of `clang`
   memory just to link, before being replaced with an in-place
   `Cpu::reinit`. Worth a minimal, project-independent repro (a function
   returning a >512KB struct, called 2-3 times from within one enclosing
   function) to confirm or rule out whether this is the same root cause as
   `projects/nova/NOTES.md`'s "Seven Star compiler bugs found and fixed"
   #1's already-fixed shape, or a genuinely new one.
5. Nova's own remaining, deliberately-scoped-out gaps (unchanged from
   before this stage): splitting `cpu.star`'s opcode handlers across
   files; `SMIX`/`SECHO`/`SREVERB`/`SFILTER` (unimplemented, matching the
   reference); a true per-8-channel sound voice model; a real pink-noise
   filter; source-line (as opposed to numeric-address) breakpoints in
   `debugger.star`, once/if `assembler.star` grows debug-line-mapping
   output.

**P3: Keep the cadence honest.**
6. This cycle's trigger fired for a genuine reason and the full test suite
   was started before this reassessment's `current_status.md` was drafted
   rather than concurrently with it, per the prior review's own stated
   adjustment — carry that forward. One new adjustment worth adding: when a
   verification pass discovers its own *method* doesn't work (this stage's
   `SendMessage`-doesn't-register-with-SDL finding, worked around by
   switching to genuine synthesized hardware input), record the dead end
   explicitly, not just the eventual working method — both `NOTES.md` and
   `current_status.md` did that this time; keep doing it.

# Previous work

Out-of-band feature request (not from the P0-P3 list above, worked ahead
of the next reassessment): a `Load` button for `projects/nova/main.star`'s
GUI, requested directly, plus removal of the baked-in demo program so a
no-argument launch waits idle for a real binary instead. This needed a new
compiler builtin (`open_file_dialog`, `src/codegen/dialog.rs`) wrapping
Windows' `GetOpenFileNameA` -- the "GUI+controls parity" stage two cycles
ago had explicitly scoped `Load`/`UART` buttons out for exactly this reason
("no file-dialog builtin anywhere in this language's surface"). See
`projects/nova/NOTES.md`'s new "Load button and `open_file_dialog`"
section for the full struct-layout/filter-string design writeup. Covered
by `tests/frontend_open_file_dialog.rs` (type-checking plus a real
clang-link-only test against `-lcomdlg32`; a genuine runtime invocation
isn't automatable -- see that file's own doc comment for why) and verified
manually, once, for real: built `nova16.exe`, confirmed a no-argument
launch shows a blank `HALTED` screen with no demo gradient, then drove the
new `LOAD` toolbar button with genuinely synthesized hardware mouse input
(the same technique the prior GUI+controls-parity round's own verification
used, since synthetic `keybd_event`/F9 was tried first and, consistent
with that round's own already-recorded finding, didn't register from a
background script) — the real Windows "Open" dialog appeared correctly
filtered to `*.bin`, and selecting a real test program made the emulator
reset and start running it end to end. `main.star`'s `Reset` now reloads
whichever binary is currently active (the original CLI argument, or the
most recent `Load`) rather than only ever the process's original argument,
since it no longer has a "fall back to the demo" option to lean on. Full
`cargo test` suite re-run clean afterward (74 binaries, 0 failures).

See `changelog/068_2026-07-30_cacd569_todo.md` and
`changelog/068_2026-07-30_cacd569_current_status.md` for the full history
up to and including this cycle (the repeated-f-string-call corruption bug
root-caused and fixed, a real assembler for `projects/nova`, and — this
session — a real debugger (`projects/nova/debugger.star`) and GUI+controls
parity (`projects/nova/main.star`'s toolbar/status bar/hotkeys), a genuine
Cpu SP/FP reset-value port bug found via the debugger's first real use and
fixed across all four build targets that construct a `Cpu`, and a `clang`
build-time pathology found and worked around via `Cpu::reinit`) — archived
per the reassessment protocol before this file was reseeded from the fresh
`current_status.md`'s "Next steps" section above.

projects/nova/debugger.star (new): a real debugger -- a headless CLI REPL
matching `nova_debugger.py`'s command set (`step`/`s`, `run`/`continue`/
`cont`, `regs`/`r`, `mem`, `stack`, `disasm`/`d`, `break`/`b`,
`breakpoints`/`bp`, `clear`/`c`, `load`, `help`, `quit`). Reuses
`disasm.star`'s disassembly tables (duplicated, not imported -- both are
standalone build targets with their own `fn main()`, and this compiler
lowers every top-level `fn main()` to the same `@main` symbol regardless of
source file, so importing either into the other would collide two `@main`
definitions) and `assembler.star`'s `.sym` sidecar format for symbol-
labeled disassembly/breakpoint output. One deliberate improvement over the
Python reference: `run`/`continue` steps at least once before its first
breakpoint check (Python's own `run_until_breakpoint` re-hits an
already-current breakpoint instantly on every resume, a real upstream quirk
found and filed under `projects/nova/NOTES.md`'s "What to carry back to the
Python emulator", not matched here). Verified against
`tests/asm/write_width_test.bin` via a scripted stdin session and
cross-checked against a live `debugger_init`/`cpu_step`/`get_cpu_state`
sequence on the Python reference over MCP (registers and `pc` matched
exactly after 10 steps). That cross-check is what surfaced the SP/FP reset
bug below.

A genuine port bug, found via the debugger's first real use: every Nova
build target's `Cpu` construction initialized SP/FP (P8/P9) to `0x0000`;
the live Python reference initializes them to `0xFFFF`
(`core/regfile.py::RegisterFile.__init__`). Every existing checked-in
`.asm` test happens to set SP explicitly before touching the stack, which
is exactly why this went unnoticed until the debugger's `stack` command
exposed the raw post-reset state. Fixed in all four places a `Cpu` is
constructed (`main.star`, `debugger.star`, `tests/run_bin.star`,
`uart_bridge.star`); re-verified the full `tests/asm/*.bin` suite against
`tests/run_bin.exe` afterward with no change to any test's documented
expected register values.

projects/nova/main.star (extended): GUI+controls parity -- a toolbar
(Start/Pause, Stop, Reset, Step) and status bar (PC, run state, F5-F8
hotkey legend), matching the useful-without-a-file-dialog slice of
`nova_gui.py`'s own toolbar (no file-dialog/Tk-dialog builtin exists in
this language at all, so "Load"/"UART config" buttons are a deliberate,
documented scope cut -- loading stays command-line-argument-only,
`uart_bridge.star` stays the separate UART tool). Verified interactively:
built `nova16.exe`, launched it, and drove the toolbar with genuinely
synthesized hardware-level mouse input (`SetCursorPos` + `mouse_event`)
while screenshotting the live window -- confirmed Start/Pause toggling the
button label and status-bar run-state text, Step advancing `PC` by exactly
the expected two-instruction delta while stopped, and Reset reloading and
resuming. `SendMessage`-posted window messages did *not* register with
SDL's own mouse-state tracking during this verification (a dead end worth
recording, per `current_status.md`'s own P3 #6), which is why genuine
synthesized input was used instead. The F5-F8 hotkeys share the exact same
edge-triggered `running`/`single_step` state the verified mouse clicks
already exercise, but were not independently confirmed working this
session (synthetic `keybd_event` presses from a background script were
inconclusive) -- see todo.md P1 #2 above.

A real `clang` build-time pathology, found and worked around (not
root-caused): an early draft implemented `Reset` by calling a
`build_cpu`-style function (constructing and returning a fresh,
megabyte-plus `Cpu` by value) a second and third time, on top of the one
call already needed at startup -- that build took several minutes and
multiple gigabytes of `clang` memory just to reach the link step. Worked
around with `Cpu::reinit`, a method that resets every field via ordinary
loop-driven writes into the *existing* `Cpu` rather than a repeated
struct-literal-returning call -- builds and links in the same normal time
as every other file in this project, and is arguably a closer match to
`nova_gui.py::CPUController.reset()`'s own "mutate in place" shape than the
original draft was anyway. See todo.md P2 #4 above for the follow-up this
deserves.

current_status.md / todo.md: this reassessment.

See `changelog/067_2026-07-29_45382cc_todo.md` and
`changelog/067_2026-07-29_45382cc_current_status.md` for the prior cycle's
full history (sound synthesis + UART host bridge landing for real,
`.clinerules` sync, the versioning-gate adequacy judgment, the Nova
disassembler, two genuine Star compiler bugs found and fixed via that
disassembler work, ten operand-count documentation bugs found and fixed in
`docs/nova16_instruction_reference.md`, and `projects/nova/NOTES.md`'s
reframing from "language exercise" to "de facto Nova-16 emulator") and the
cycle before that (the repeated-f-string-call corruption bug root-caused
and fixed, and a real assembler for `projects/nova`) -- both archived under
the same reassessment protocol.

Copied over the Python reference's assembly programs to `projects/nova/asm/`
since they're user-written and tested programs worth moving locally for easier
reference given the Star Nova's status as the de-facto Nova standard.