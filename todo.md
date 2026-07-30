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
1. **Done.** Added `projects/nova/tests/run_debugger_test.ps1` (+
   `debugger_test_commands.txt` / `debugger_test_expected.txt`), a
   checked-in, rerunnable scripted-stdin-in/captured-stdout-out regression
   test for `debugger.star`'s REPL command surface. See "Previous work"
   below for the full account, including a genuine dead end found along
   the way (live-pipe stdin silently corrupts the first line
   `read_line()` reads; real-file-redirected stdin doesn't).
2. **Done.** F8/Step confirmed genuinely working, both the hotkey and the
   toolbar button — but only after a false alarm along the way worth
   recording. See "Previous work" below for the full account: a first
   verification attempt against `gfxtest.bin`/`starfield.bin` looked like a
   real Step bug (PC unchanged across repeated Step presses, both via
   synthesized hardware mouse clicks and `keybd_event`), until disassembly
   showed both demos park in a deliberate `JMP $` self-loop within their
   first rendered frame (`running` defaults `true`, up to 20000 steps/frame)
   — a single step from a self-jump instruction correctly leaves PC
   unchanged, which is indistinguishable from "Step does nothing" without
   inspecting the disassembly. Confirmed via a temporary "start paused"
   build that single-stepping from the entry point does advance PC
   (`0x1000` -> `0x1001` -> `0x1005`). Independently re-verified for real by
   directly using the app against `projects/nova/asm/pixelfill.bin` (loading
   the program, pausing quickly, then stepping via both F8 and the GUI
   button) — chosen because it doesn't settle into a tight idle loop the way
   the earlier test binaries do, so genuine step-by-step progress was
   directly observable this time. This closes the "hotkeys rest on reasoning,
   not independent confirmation" gap `keybd_event` couldn't resolve from a
   background script.

**P2: Process debt that's been deferred past the point of being
defensible.**
3. **Done.** See "Previous work" below for the rationale.
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

P1 #1, checked-in `debugger.star` regression test (closed this session):
added `projects/nova/tests/run_debugger_test.ps1`, `debugger_test_
commands.txt`, and `debugger_test_expected.txt`. The commands file drives
`debugger.exe` against `tests/asm/write_width_test.bin` through `help`,
`regs`, a `disasm` listing, a single `step`, a `step 3`, more `regs`, a raw
`mem` dump, `stack`, `break`/`breakpoints`/`run`/`regs`/`clear`/
`breakpoints` around the program's `HLT` (found at `0x006C` via
`disasm.exe`), and `quit` — a real slice of the REPL's command surface,
not just one command. The golden file is that exact session's real
captured stdout, cross-checked against `write_width_test.asm`'s own
documented expected register values (`R1=0xD7 R2=0xCD R3=0x0C R4=0xCD
R5=0x34 R6=0xCD R7=0xCD R8=0xCD`) — both matched, confirming the debugger
correctly reports the same post-run state `run_bin.exe` already verified
for this binary.

A genuine dead end found while building this, worth recording per the
existing P3 #6 convention: the first attempt fed the commands file to
`debugger.exe` via a live stdin pipe -- both a `Get-Content | & $exe`
PowerShell pipeline and a raw .NET `Process.StandardInput.Write()`/
`Close()` -- and in every case the *first* line `read_line()` read back
came back corrupted (`help` silently became an unrecognized command; every
line after it read correctly). The identical command sequence read
correctly, byte-for-byte, every time when piped through a real disk file
instead (Bash `<` redirection while first capturing the golden output, and
PowerShell's `Start-Process -RedirectStandardInput <file>` for the
checked-in script) -- confirming this is specifically a live-pipe-vs-real-
file distinction, not a bug in the commands themselves. Root cause not
chased down (a plausible guess is a timing/buffering interaction between
the Star runtime's `read_line()` and an anonymous pipe whose first write
lands after the child's first read attempt, vs. a disk file that's fully
present from the start) since a real file was already the more robust
choice for a checked-in test regardless. Worth revisiting only if this
project ever needs genuinely live/interactive piped stdin for something.

Assessed the current status of the Nova project: aside from a few noted items
in the `NOTES.md` and some unimplemented opcodes the reference version itself
lacks, the bulk of work on the Nova-16 emulator is complete. No new systems or
tools need to be implemented to run the existing library of Nova-16 programs,
and the project and the language itself both have outgrown the "will the Nova-16
even work" stage to a point where further progress is increasingly unlikely
to uncover language gaps or issues; therefore the Nova project's end of version
gating should be considered upheld, leaving only the requisite bug hunting rounds.
`readme.md` update pending reassessment's consideration on the matter.

P1 #2, F5-F8 hotkey verification (closed this session): confirmed F8/Step
genuinely works, both the hotkey and the toolbar button, but only after a
false alarm that's worth recording in full since it nearly got misreported
as a real bug. First verification attempt: rebuilt `nova16.exe`, launched it
against `projects/nova/asm/gfxtest.bin`, paused it, and drove Step via both
genuinely synthesized hardware mouse clicks (`SetCursorPos` + `mouse_event`)
and `keybd_event` F8 presses -- PC (`0x106F`) never changed across repeated
presses of either. A temporary debug `println` around the `elif single_step
and !c.halted: c.step()` call confirmed the call really was executing (both
"before"/"after" prints fired) yet PC genuinely didn't move, which at that
point looked like a real, reproducible Step bug. Root cause, found via
`disassemble_program` over the Nova-16 MCP server against the same binary:
`0x106F` is `LOOP2: JMP 0x106F` -- gfxtest.bin's own deliberate "done
drawing, spin forever" idle loop, with the visible animation in other demos
(`starfield.bin`, same shape at a different address) actually driven by a
periodic timer interrupt handler, not the main instruction stream. A single
step *from* a self-jump instruction correctly leaves PC unchanged -- that's
not a malfunction, it's the only correct outcome, and it's indistinguishable
from "Step does nothing" unless you inspect the disassembly. The deeper
cause: `main.star`'s `running` local defaults `true` and the running branch
executes up to 20000 steps per frame, so these small demos reach their own
idle loop within the first rendered frame, before any external actor
(script or human) can possibly intervene earlier. Confirmed the underlying
mechanism is sound with a temporary "start paused" build (`running = false`
at init instead of `true`): single-stepping from the entry point advanced
PC for real (`0x1000` -> `0x1001` -> `0x1005`) before eventually reaching
the same kind of idle loop. Reverted both temporary changes (`git diff` on
`main.star` confirmed clean) and rebuilt the unmodified `nova16.exe`.
Independently re-verified for real afterward, this time by directly using
the app rather than scripting it: loaded `projects/nova/asm/pixelfill.bin`,
paused quickly, then stepped via both F8 and the GUI button -- pixelfill
doesn't settle into a tight idle loop the way the earlier test binaries do,
so genuine step-by-step progress was directly observable. Together this
closes the gap `keybd_event`-from-a-background-script couldn't resolve on
its own. Worth carrying forward as a general lesson for this project's own
GUI verification method: a demo binary that quickly parks in a `JMP $`
idle loop is a poor choice for verifying Step/pause behavior specifically,
since "no visible change" is ambiguous between "broken" and "correctly
executing a no-op instruction" without a disassembly cross-check.

More out-of-band work:
Copied over the Python reference's assembly programs to `projects/nova/asm/`
since they're user-written and tested programs worth moving locally for easier
reference given the Star Nova's status as the de-facto Nova standard.

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