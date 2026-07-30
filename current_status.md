# Star Language: A Technical Assessment

*Reviewed at commit `cacd569` (2026-07-30) plus uncommitted work from this
same session (this review's own trigger — see below), one stage after the
prior review at `45382cc` (archived as
[changelog/067_2026-07-29_45382cc_current_status.md](changelog/067_2026-07-29_45382cc_current_status.md)).
This stage's own `todo.md` (archived as
[changelog/068_2026-07-30_cacd569_todo.md](changelog/068_2026-07-30_cacd569_todo.md))
had its one open item, P2 #3 (a debugger and GUI+controls parity for
`projects/nova`), marked **Done.** with real, interactively-verified work
behind it — the trigger condition per `CLAUDE.md`'s reassessment rule.
`cargo +stable-x86_64-pc-windows-gnu check --tests` is clean. The full
`cargo +stable-x86_64-pc-windows-gnu test` run was started in the
background before this document was drafted (not concurrently with it —
the adjustment the last review's own "Next steps" P3 asked for) and its
result is folded into "The Good"/"The Bad" below rather than assumed.*

## The pitch, then and now

Unchanged: *"a game programming language with Pythonic-Rust syntax and
unique memory management modes, targeting native executables via LLVM
IR."* This stage touched **zero files under `src/`** — the first stage in
several reviews where the Star compiler itself wasn't modified at all. All
of this stage's work is in `projects/nova/` (two new/extended `.star`
files, four small identical bug-fix edits) plus this project's own
process files (`NOTES.md`, `todo.md`). That's not a gap; it's what "the
last two named-tooling gaps in the versioning gate are closed" actually
looks like when the language underneath them was already capable enough to
build both without needing a new fix first.

---

## This stage (`45382cc` → `cacd569` + uncommitted, 2026-07-29 to 07-30)

The prior review's "Next steps, prioritized" P2 #3 became this stage's
only `todo.md` item (P0/P1 were already closed by the two commits between
`45382cc` and `cacd569`, `de3af92`/the f-string fix and the assembler
respectively, both already reflected in `068`'s incoming `todo.md`):

- **`projects/nova/debugger.star` (new).** A headless CLI REPL matching
  `nova_debugger.py`'s command set (`step`/`s`, `run`/`continue`/`cont`,
  `regs`/`r`, `mem`, `stack`, `disasm`/`d`, `break`/`b`, `breakpoints`/`bp`,
  `clear`/`c`, `load`, `help`, `quit`) closely enough to be a genuine
  drop-in replacement for interactive use, not a partial gesture at one.
  Reuses `disasm.star`'s disassembly tables (duplicated, not imported —
  see below) and `assembler.star`'s `.sym` sidecar format for symbol-
  labeled output. Verified against `tests/asm/write_width_test.bin` via a
  scripted stdin session (disasm/step/regs/stack/mem/break/breakpoints/run/
  clear all exercised) and cross-checked against a live
  `debugger_init`/`cpu_step`/`get_cpu_state` sequence on the Python
  reference over MCP — registers and `pc` matched exactly.
- **A genuine, previously-unknown port bug found by that first real use of
  the debugger.** Every Nova build target's `Cpu` construction initialized
  SP/FP (P8/P9) to `0x0000`; the live reference initializes them to
  `0xFFFF` (`core/regfile.py::RegisterFile.__init__`). Every existing
  checked-in `.asm` test happens to set SP explicitly before touching the
  stack, which is exactly why this was never caught until the debugger's
  `stack` command showed the raw, un-set-by-any-program post-reset state.
  Fixed in all four places a `Cpu` is constructed (`main.star`,
  `debugger.star`, `tests/run_bin.star`, `uart_bridge.star`); the full
  `tests/asm/*.bin` suite was re-run against `tests/run_bin.exe` afterward
  with no change to any test's documented expected register values
  (a stack push/pop round-trip returns SP to wherever it started,
  regardless of what that starting value was, so this fix couldn't have
  silently broken anything already passing).
- **A real `main.star` GUI extension**: a toolbar (Start/Pause, Stop,
  Reset, Step) and status bar (PC, run state, F5-F8 hotkey legend),
  matching the useful-without-a-file-dialog slice of `nova_gui.py`'s own
  toolbar. Verified interactively, not just by inspection: built
  `nova16.exe`, launched it, and drove the toolbar with synthesized
  hardware-level mouse input (`SetCursorPos` + `mouse_event`) while
  screenshotting the live window — confirmed Start/Pause toggling both the
  button label and the status bar's run-state text, Step advancing `PC` by
  exactly the expected two-instruction delta while stopped, and Reset
  reloading and resuming. See "The Bad" below for what this verification
  pass did *not* manage to confirm (the F5-F8 hotkeys specifically).
- **A real `clang` build-time pathology found and worked around, not
  root-caused.** An early draft of the `Reset` control called a function
  that constructs-and-returns a fresh, megabyte-plus `Cpu` by value a
  second and third time (once per `Reset` trigger, on top of the one call
  every other build target in this project already uses safely). That
  build took several minutes and multiple gigabytes of `clang` memory just
  to reach the link step — different enough in degree from this project's
  one proven-safe call-site shape to be worth naming as a real, if
  unconfirmed, instance of the same general "`clang` chokes on repeated
  large-aggregate construction" pathology class `NOTES.md`'s "Seven Star
  compiler bugs found and fixed" #1 already describes fixing for a
  different shape. Not chased to a minimal repro or a compiler-level fix
  this stage; worked around instead by giving `main.star` a `Cpu::reinit`
  method (ordinary loop-driven field/array writes into the *existing*
  `Cpu`, no repeated struct-literal-returning call), which both builds
  normally and is arguably a closer match to `nova_gui.py`'s own
  `CPUController.reset()` (which also mutates in place, not "makes a new
  object") than the original draft was.
- **`NOTES.md`/`todo.md` brought current.** New "Debugger" and
  "GUI+controls parity" sections; the file's own top-of-document framing
  note updated (both named-tooling gaps in the versioning gate are now
  built, not "still missing"); "Ideas for future work" and "What's not
  implemented" both had stale "still genuinely unstarted" language for the
  debugger/assembler corrected; a new upstream-issue entry added to "What
  to carry back to the Python emulator" for `nova_debugger.py`'s own
  re-hits-a-breakpoint-on-resume quirk (found, and deliberately *not*
  matched, while building `debugger.star`'s `run`/`continue`).

Net: the one item in this stage's incoming `todo.md` has real, verified
work behind it — interactive screenshot-based verification for the GUI
half, a live cross-check against the Python reference over MCP for the
debugger half, and a genuine port bug found and fixed as a direct result of
building the tool rather than a separate, unrelated finding.

---

## The Good

**1. The debugger's very first real use paid for itself immediately, the
same pattern this project's disassembler and assembler rounds both already
established.** The SP/FP reset bug wasn't found by a dedicated bug hunt —
it fell out of literally the first cross-check against the live reference
this stage ran. That's now three tools in a row (disassembler, assembler,
debugger) where "build the tool, then use it for real once" surfaced a
genuine, previously-unnoticed correctness gap. This is worth naming as a
pattern, not a coincidence: this project's own checked-in test corpus
apparently has a systematic blind spot (every test sets up its own state
explicitly before exercising the opcode under test) that only a tool doing
raw, unscripted inspection exposes.

**2. GUI verification was done the hard way, not asserted.** It would have
been easy to report "added a toolbar, looks right in the code" and move on
— SDL windows are exactly the kind of thing that's tedious to verify
end-to-end in this environment. Instead this stage built real screenshot-
based verification (`GetWindowRect` + `CopyFromScreen`) and, after
discovering that `SendMessage`-posted window messages don't register with
SDL's own mouse-state tracking, switched to genuine synthesized hardware
input (`mouse_event`) and re-verified from scratch rather than accepting
the first (silently wrong) verification method's non-result. That
discovery is itself recorded in `NOTES.md` so a future session doesn't
re-spend time on the same dead end.

**3. The `clang` build pathology was flagged rather than quietly worked
around and forgotten.** The workaround (`Cpu::reinit`) is a legitimate,
independently-motivated design choice, not just a pathology dodge — but
the pathology itself is still named explicitly, in both `NOTES.md` and
this document, as unconfirmed and unresolved at the compiler level, with
enough detail (three call sites vs. one, megabyte-plus aggregate, minutes
not seconds to link) that a future session chasing it doesn't have to
rediscover the shape from scratch.

**4. This stage found and deliberately did *not* port a real upstream bug**
(`nova_debugger.py`'s re-hits-a-breakpoint-on-resume quirk), matching this
project's established "port bug-for-bug only when there's no defensible
reading of intent otherwise" standard (the `BR`/`BRZ`/`BRNZ` relative-
offset precedent from the assembler round) rather than reflexively
mirroring the reference in every particular.

---

## The Bad

**1. The F5-F8 hotkeys were not actually verified to work, only argued to
be equivalent to code that was verified.** This document's own "This
stage" section is honest about this, but it's still a real gap: synthetic
`keybd_event` key presses sent from this session's own automation were
inconclusive (plausibly due to Windows' foreground-lock restrictions on a
background process's simulated input), so the hotkeys currently rest on
"the same `running`/`single_step` variables the verified mouse clicks also
set" rather than on independent, direct confirmation. That's a reasonable
inference, not a substitute for actually seeing F6 stop the emulator. Worth
closing out with a different verification technique (a foreground-safe
input-injection method, or a small in-`main.star` self-test hook) before
this is treated as fully confirmed.

**2. Neither `debugger.star` nor `main.star`'s new toolbar has a checked-in
regression test.** Every other Nova build target this project has added in
recent rounds (`disasm.star`, `assembler.star`) shipped with real,
automatable verification against `tests/asm/*` — this stage's debugger was
verified once, interactively, in this session, and that verification
doesn't persist as something a future `cargo`/`star`-level check can re-run
to catch a regression. The GUI toolbar is harder to make headlessly
testable (real window, real mouse state) but the debugger's REPL is not —
a scripted-stdin-in, captured-stdout-out comparison against a fixed
`tests/asm/*.bin` would be straightforward to check in and should happen
before this is considered fully done rather than "verified once by a
person (or agent) who happened to be looking."

**3. The versioning gate's exit condition is still undefined, for the
third review in a row.** `067`'s own "The Bad" #4 raised this; it wasn't
addressed last stage either (that stage's own P1 #4 was the sound/UART
work, not this). "Nova is complete" still isn't defined anywhere as a
concrete checklist, and this stage just closed the last two *named*
tooling gaps (debugger, GUI+controls) without ever pinning down whether
those were the *only* things "complete" requires. This is the most
overdue item across the last three reviews specifically because it keeps
getting reasonably deprioritized behind more concrete work each time —
that reasoning runs out now that the named list is empty.

**4. Every prior stage's unchanged structural caveats still stand.** The
Windows-only-by-construction scope, the "special guest" type families, the
big-aggregate stack-budget risk (warning-only), and traits as permanently-
non-dynamic monomorphized sugar are all carried forward unchanged. None
regressed this stage; none were the focus of it.

---

## Goals vs. reality, honestly

Unchanged in the broad strokes: the original design goals are largely
achieved on their own terms, with the same permanent, self-named caveats
(static-only dispatch, Windows-only runtime target). What's different this
stage is that Nova's own versioning-gate checklist — binary loader,
disassembler, assembler, debugger, GUI+controls — is now fully built for
the first time since the gate was written down at all (`067`'s own
review). Whether that means Nova, and by extension the language's `0.1.0`
gate, is actually *done* is exactly the open question "The Bad" #3 names:
this review can confirm the named list is empty, not that the list was
complete in the first place.

---

## Next steps, prioritized

**P0 — Nothing broken needs fixing before new work starts.** No false
"Done." markers this cycle (unlike two reviews ago), and the one genuine
bug found this stage (SP/FP reset) was fixed within the same stage that
found it, not left for this review to catch.

**P1 — Close this stage's own two honestly-flagged gaps.**
1. **Add a checked-in regression test for `debugger.star`** (see "The Bad"
   #2): a scripted-stdin-in/captured-stdout-out comparison against a fixed
   `tests/asm/*.bin`, the same spirit as `tests/run_bin.star` but exercising
   the REPL's command surface instead of a headless run-to-completion.
2. **Actually verify the F5-F8 hotkeys** (see "The Bad" #1) with a
   verification method that isn't subject to background-process foreground-
   lock restrictions — either a foreground-safe input-injection technique,
   or a small temporary self-test hook in `main.star` itself that can be
   removed afterward.

**P2 — Process debt that's been deferred past the point of being
defensible.**
3. **Define what "Nova is complete" means, concretely**, for `readme.md`'s
   versioning gate — a fixed checklist (opcode/feature completeness, most
   plausibly building on `NOTES.md`'s own "What's implemented"/"What's not
   implemented" split) rather than an open-ended qualitative gate. Third
   review in a row naming this; it should not appear a fourth time without
   being acted on.
4. **Investigate the `clang` large-aggregate-returned-repeatedly build
   pathology for real** (see "The Bad" — well, "The Good" #3's flip side):
   a minimal, project-independent repro (a function returning a >512KB
   struct, called 2-3 times from within one enclosing function) would
   confirm or rule out whether this is the same root cause as "Seven Star
   compiler bugs found and fixed" #1's already-fixed shape, or a genuinely
   new one.
5. Nova's own remaining, deliberately-scoped-out gaps, unchanged from
   before this stage: splitting `cpu.star`'s opcode handlers across files,
   `SMIX`/`SECHO`/`SREVERB`/`SFILTER` (unimplemented, matching the
   reference), a true per-8-channel sound voice model, a real pink-noise
   filter, and source-line (as opposed to numeric-address) breakpoints in
   `debugger.star` once/if `assembler.star` grows debug-line-mapping
   output.

**P3 — Keep the cadence honest.**
6. This cycle's trigger fired for a genuine reason (the one real `todo.md`
   item was actually done, verified two different ways for its two
   halves), and the full test suite was started before this document was
   drafted rather than concurrently with it, per the last review's own
   stated adjustment. Carry that forward. One new adjustment worth adding:
   when a stage's own verification pass discovers its *method* doesn't work
   (this stage's `SendMessage`-doesn't-register-with-SDL finding), record
   the dead end explicitly rather than only the eventual working method —
   this document and `NOTES.md` both did that this time; keep doing it.
