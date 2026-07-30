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
3. **Done.** A second, closer pass after the "Done-ish" first cut: built
   the concrete "what does 'Nova complete' mean" checklist `current_
   status.md`'s own P2 #3 asked for (three reviews running), checked it
   against `NOTES.md`'s "What's implemented"/"What's not implemented", and
   confirmed the readme's "minimal 4 rounds of bug hunts" clause separately.
   See "Previous work" below for the full checklist and citations. The
   `readme.md` Versioning-section/version-number update itself is
   deliberately left for the user to greenlight, not done here — see the
   note at the end of that entry.
4. **Done.** Root-caused and fixed as a genuine, previously-uncovered Star
   compiler bug — not a recurrence of "Seven Star compiler bugs found and
   fixed" #1's shape. See "Previous work" below for the full account.
5. **Done**, minus two items deliberately left out (see "Previous work"
   below for the full account and rationale): a new `sound_play_channel`/
   `sound_stop_channel` compiler builtin pair gives Nova's `SPLAY` a true
   per-8-hardware-channel voice model and waveform 6 a real one-pole
   pink-noise filter matching the Python reference's own; `cpu.star`'s
   ~100 opcode-handler methods are now split across 11 `cpu_*.star` files
   by group. Left out, per explicit instruction: `SMIX`/`SECHO`/`SREVERB`/
   `SFILTER` (still unimplemented, matching the reference itself) and
   `debugger.star`'s source-line (as opposed to numeric-address)
   breakpoints.

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

P2 #3, defining "Nova complete" concretely (closed this session, upgraded
from the first pass's "Done-ish"): `current_status.md`'s own P2 #3 had
named this the most overdue item across three reviews running ("should
not appear a fourth time without being acted on"), and the first pass at
it this cycle reached a real conclusion but left the follow-through
("`readme.md` update pending reassessment's consideration") for later
rather than either doing it or explicitly deferring it to the user. This
pass does the follow-through: a concrete checklist against `readme.md`'s
own gate text ("the Nova project is complete (full system implementation,
GUI+controls, and tooling to match Python reference, NoBASIC optional)
and minimal 4 rounds of bug hunts"), checked off item by item rather than
left as a qualitative impression:

- **Full system implementation**: CPU (all opcodes `NOTES.md`'s "What's
  implemented" lists, with only 4-operand opcodes and the reference's own
  unimplemented `SMIX`/`SECHO`/`SREVERB`/`SFILTER` left out — both
  explicitly scoped exclusions, not gaps), memory (incl. banking),
  screen/layer compositing + sprites, keyboard, UART (+ a real host
  bridge), sound (now with a true per-8-channel voice model and a real
  pink-noise filter as of this session's own P2 #5, closing the last two
  "known simplification" entries that weren't permanent), mouse (real
  host plumbing), and timer/interrupts. All present.
- **GUI+controls**: toolbar (Start/Pause, Stop, Reset, Step, Load) +
  status bar, matching `nova_gui.py`'s own toolbar, plus the `Load`
  button/`open_file_dialog` addition. Present (todo.md P2 #3's original
  close, this cycle's predecessor).
- **Tooling to match Python reference**: binary loader, disassembler,
  assembler, and debugger — all real, all cross-checked against the
  Python reference at least once (see NOTES.md's own "Verification"
  subsections for each). Present.
- **NoBASIC**: explicitly parenthetical-optional in the gate's own text —
  not required.
- **Minimal 4 rounds of bug hunts**: overwhelmingly cleared regardless of
  whether this means Nova-driven bug discovery specifically or the
  compiler's general bug-hunting-round cadence. Nova-driven alone:
  "Seven Star compiler bugs found and fixed" (7, `NOTES.md`), the
  repeated-f-string-call corruption bug, ten `nova16_instruction_
  reference.md` operand-count documentation bugs (changelog `067`), the
  Cpu SP/FP reset-value bug and the `clang` large-aggregate-reassignment
  pathology (both this reassessment's own cycle) — already several times
  past 4 distinct sessions, without even counting the compiler-wide
  "Thorough bug-hunting round" stages documented independently throughout
  `changelog/025` onward.

Every checklist item the gate names is satisfied. What this pass
deliberately does *not* do: touch `readme.md`'s Versioning section or the
crate's version number itself. `CLAUDE.md`'s own "Things not to do"
section is explicit that a version bump isn't something to fold into
unrelated work, and while this investigation is squarely *on-topic* (not
unrelated), actually flipping the language's own "not yet usable/stable"
public signal is a different order of consequential than confirming the
gate's conditions are met — raised to the user directly rather than
decided here.

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

P2 #4, the `clang` large-aggregate-reassignment build pathology (closed this
session): root-caused and fixed as a genuine, previously-uncovered Star
compiler bug in `TypedStmt::Assign` (`src/codegen/stmt.rs`) -- confirmed via
a minimal, project-independent repro to be a *different* gap from "Seven
Star compiler bugs found and fixed" #1's already-fixed shape, not a
recurrence of it. Repro construction: a straight-line `let a = f(); let b =
f(); let c = f()` (three separate fresh bindings, each a call returning a
1,000,000-byte struct) compiled in well under a second -- `TypedStmt::Let`'s
existing `is_large_aggregate_ty` branch already routes every one of those
through `emit_into_ptr`, so this shape was already covered by `todo.md`'s
prior P0 #2 fix. The real Nova shape -- one `let mut cpu = f()` followed by
`cpu = f()` *reassignments* inside `if` branches nested in a `while` loop,
mirroring `main.star`'s per-frame hotkey/toolbar-click `Reset` handling --
reliably reproduced the pathology: confirmed via `Get-Process` that
`clang-22` climbed past 3.4GB resident memory while compiling it, and the
build eventually failed outright after 11m19s wall time (`clang-22: error:
clang frontend command failed with exit code 2147483647`) rather than ever
completing -- worse than the original `main.star` draft's "several minutes"
account, though the same pathology.

Root cause: `TypedStmt::Assign`'s `Eq` branch (plain `=`, not `+=`/...) had
no large-aggregate special case at all, unlike `TypedStmt::Let` right above
it in the same file. `x = f()` fell through to `emit_expr(value)` +
`store_target`, and `emit_expr`'s generic `Call` handling for a large
struct/array return type has always had exactly one whole-aggregate
materialization left in it *by design* -- `emit_call_expr`'s own doc comment
at the time named it as reachable only by "a rarer generic value consumer
(e.g. a bare expression-statement discarding the result)". Reassignment to
an existing mutable binding turned out to be a second, much more consequential
consumer of that same fallback that the comment didn't anticipate: alloca a
temp, call into it via `sret`, `load` the *entire* struct into one SSA
value, hand that back to `store_target`, which then `store`s the whole thing
a second time into the target's real storage. Two copies of a giant
aggregate *value* (as opposed to two pointers and a `memcpy`) is exactly the
`clang` optimizer/instruction-selector shape "Seven Star compiler bugs found
and fixed" #1 first found and fixed for *construction*, and P0 #2 later
fixed for *return*/*parameter* passing -- reassignment was the one shape
neither round touched, because neither round's own repro ever reassigned an
existing large-aggregate binding, only bound fresh ones or passed/returned
them.

Fix: `TypedStmt::Assign`'s `Eq` branch now special-cases a large-aggregate
RHS (skipping only a bare `TypedExpr::TableIndex` target, which -- per
`Codegen::emit_place`'s own doc comment -- has no contiguous storage to
resolve a real pointer for): build the new value into a private scratch
`alloca` via `Codegen::emit_into_ptr` first (never straight into the
target's own storage -- keeps `x = x`/self-referential-RHS shapes safe,
since a fresh temp can never alias the place being overwritten, mirroring
why the ordinary scalar path's retain-before-release ordering already
matters), then resolve the target's real address via `Codegen::emit_place`,
release its old contents (`Codegen::emit_release_at`, for RC correctness),
and `Codegen::emit_memcpy_aggregate` the temp over it. Re-running the exact
repro above after the fix: 2.4 seconds, correct output (previously 11m19s
and a hard `clang` failure).

New regression coverage: `tests/frontend_large_aggregate_reassignment.rs`
(six tests) -- a codegen-shape/near-instant-compile-time assertion at
megabyte scale (no `clang`, same safety rationale the existing
`tests/frontend_large_aggregate_by_value.rs` already uses for its own
shape assertions), plus five real `clang -O0`-compiled runtime tests at
8192 bytes (safely above `Codegen::LARGE_AGGREGATE_THRESHOLD`, small enough
to run instantly even if a regression reintroduced the whole-value path):
plain reassignment actually replaces the value, the exact real-world
if/while-nested-reassignment shape, `b = b` self-assignment safety, an
RC-owning (`str`) field reassigned 20x in a loop (leak/double-release
check), and reassignment through a struct field (`h.inner = f()`, exercising
`emit_place`'s `Field` arm rather than a bare local). Full `cargo test`
suite re-run clean afterward (75 test binaries, 0 failures) and
`projects/nova/main.star` re-built end to end with the fixed compiler
(`star build ... -L sdl/lib/x64 -l SDL2 -l comdlg32`, 3.6s, unchanged from
before the fix -- expected, since `main.star`'s own `Reset` already uses
`Cpu::reinit` rather than the reassignment shape this fix targets, so this
was a no-behavior-change confirmation, not a fix verification, for Nova
itself). `Cpu::reinit` is not being reverted: `NOTES.md`'s own prior writeup
already judged it "arguably more correct" than repeated by-value
construction regardless of this compiler bug, matching `nova_gui.py::
CPUController.reset()`'s own mutate-in-place shape more closely -- this fix
closes the *investigation* `todo.md` asked for, not a request to change
Nova's design back.

P2 #5, Nova's own remaining scoped-out gap list (closed this session, two
items deliberately left out per explicit instruction -- `SMIX`/`SECHO`/
`SREVERB`/`SFILTER` unimplemented opcodes and `debugger.star` source-line
breakpoints, both still genuinely out of scope for the reasons already on
record in `NOTES.md`):

**A true per-8-channel sound voice model.** `SW`'s channel-select bits
(3-5) were decoded nowhere at all before this session -- `cpu.star::
op_splay`'s doc comment claimed they were "decoded but not respected,"
which turned out to be wrong on inspection: they were never read in the
first place. Closing the real gap needed a new compiler builtin pair,
`sound_play_channel(sound, channel, looped)`/`sound_stop_channel(channel)`
(`src/codegen/audio.rs`), since the existing `sound_play`/`music_play`
only offer an auto-scanned pool slot or a hardcoded channel 0 -- neither
lets a caller address one of Nova's 8 hardware channels directly. Both
mask their channel argument with `& 15` (`NUM_CHANNELS - 1`, a cheap
power-of-two bound rather than a branch) and are banned inside `par`/
`swarm` bodies for the same shared-unlocked-channel-table reason as the
rest of this family (`src/types/par_analysis.rs`). Covered by 10 new
tests in `tests/frontend_audio_gamepad.rs` (checker arity/type checks, a
par-ban regression test, two codegen-shape assertions confirming the `&
15` mask and the runtime loop-flag branch, and a real
`SDL_AUDIODRIVER=dummy` end-to-end test playing two independent channels
and stopping them individually).

Nova's own `sound.star`/`cpu.star` wiring: `cpu.star::op_splay` now
extracts `channel = (sw_val >> 3) & 7` and threads it through
`sound.star::play_tone`/`play_memory_sample` to a new
`play_pcm_wav_on_channel`, mapping Nova's 8 hardware channels directly
onto mixer channels 0-7 (matching `nova_sound.py::NovaSound.splay`'s own
`max_channels=8`/`channel = (SW >> 3) & 0x07` exactly, including "a new
`SPLAY` on a channel replaces whatever was already playing there").
`STRIG` has no channel-select bits in either the reference or this port's
ISA (`nova_sound.py::_play_sample_direct` bypasses the reference's own
per-channel state entirely), so it deliberately stays off the 8 hardware
channels: a new `Cpu::next_strig_channel` field round-robins mixer
channels 8-15 instead, one per `STRIG` call -- this closes a real
collision risk the naive version of this fix would have introduced
(reserving 0-7 for hardware channels while leaving `STRIG` on the old
1-15 auto-scan pool could have let an one-shot `STRIG` effect land on a
channel a `SPLAY` voice was actively using). Verified via a new
`projects/nova/asm/sound_channel_test.asm`/`.bin`, hand-assembled with
`assembler.exe`: two simultaneous channels (2 looping, 5 one-shot), a
retrigger of channel 2 with a different waveform, three `STRIG` effects
in a row, then `SSTOP` -- confirmed running clean to `HLT` via both
`tests/run_bin.exe` (`SDL_AUDIODRIVER=dummy` and real) and disassembly
cross-checked against the intended `SW` byte values (`0xD2`/`0xA9`/
`0xD4`).

**A real pink-noise filter.** Waveform 6 was a 3-tap running average of
white noise; it's now the same one-pole IIR low-pass filter over white
noise the reference's own `nova_sound.py::_generate_waveform_sample` uses
(`pink[i] = 0.99*pink[i-1] + 0.01*white[i]`, first sample `0.0`) -- a
bug-for-bug match with the reference's own "not a perfect 1/f filter but
adequate" implementation, not an attempt at spectral perfection beyond
it. This needed `waveform_sample` to thread a `(sample, next_pink_state)`
tuple through its callers (`synth_tone`/`synth_loop_tone`, plus three
other call sites that never hit waveform 6 but still had to update their
call shape) since pink noise -- unlike every other waveform -- needs
state that persists *across* samples, not just within generating one.
`synth_noise_decay` (`STRIG`'s Explosion effect, a *different* noise
shape -- the reference's own 10-tap moving-average convolution, not this
0.99/0.01 filter) was deliberately left untouched: todo.md only named
"pink noise" (waveform 6) as the gap.

**Splitting `cpu.star`'s opcode handlers across files.** `cpu.star` was
one ~3200-line file holding both the CPU's core fetch/decode/dispatch
machinery and every one of its ~100 `op_*` opcode-handler methods. Before
touching the real file, the exact "does the *reverse* direction resolve"
question -- would `cpu.star`'s own `execute()` correctly call
`self.op_add()` if `op_add` moved to a file `cpu.star` itself never
imports? -- was confirmed with a standalone three-file scratch repro
(`a.star` defines a type + method calling `self.g()`; `b.star` imports
`a.star` and defines `g` in a separate `impl a::S:` block; `main.star`
imports both and calls into `a`'s own method) before committing to the
real split: it resolved and ran correctly, confirming `Item::Impl` blocks
are never mangled by file/alias (`src/modules.rs`'s own doc comment) --
method resolution is keyed on the fully flattened module's item set, not
on which file a call site's text lives in, so it doesn't matter that
`cpu.star` can't "see" `cpu_arith.star`, only that every one of this
project's 4 build targets (`main.star`/`debugger.star`/
`tests/run_bin.star`/`uart_bridge.star`) imports both. A second scratch
repro confirmed the same for a struct field's type living in a *third*
file neither the core nor the extension file imports directly (method
calls through `self.mem`/`self.screen`/etc. don't need memory.star/
screen.star re-imported by every split file, only free functions/consts
qualified with `cpu::` do, since those aren't `impl` blocks).

Grouped along the exact lines `cpu.star`'s own header comment already
proposed (arithmetic/bitwise/stack/control-flow/graphics/...), aligned to
the file's own pre-existing `# ── Section ──` comment boundaries so no
group split disagreed with the original author's own organization:
`cpu_data.star` (MOV/XCHNG/SWAP/LEA), `cpu_arith.star` (arithmetic +
BCD), `cpu_math.star` (the transcendental/Q8.8 math library),
`cpu_bitwise.star`, `cpu_stack.star`, `cpu_control.star` (JMP/BR/CALL/
RET/LOOP/...), `cpu_mem.star` (bulk memory ops + RND), `cpu_graphics.star`
(graphics + sprites, plus `vxy`/`draw_text`/`blit_sprite` -- helpers used
only by opcodes in that same file), `cpu_io.star` (keyboard/serial/
mouse), `cpu_sound.star` (SPLAY/SSTOP/STRIG), and `cpu_string.star` (the
string library + integer/string conversion). `cpu.star` itself keeps only
the register-code address space, operand decoding, fetch/interrupt/timer
machinery, and `execute()`'s own dispatch -- plus `jump_if`, which
deliberately did *not* move with `op_jmp`/`op_br`/etc. to
`cpu_control.star` since it has no dedicated opcode handler of its own
and is only ever called inline from `execute()`'s conditional-jump
dispatch, its one real call site staying in the same file. Pure code
motion throughout -- every method's body, including its own doc comments,
copied verbatim, with only free-function/const references from `cpu.star`
(`wrap_addr`/`floor_div16`/`ascii_upper`/`PI`/`MATH_OVERFLOW_GUARD`/
`SCB_START`/`SCB_BLOCK_SIZE`/`SCB_COUNT`) requalified with a `cpu::`
prefix, exactly the same requalification any other cross-file free
function/const reference in this project already needs (unlike a method
call through `self`, a bare top-level name from another file isn't
exempt from mangling).

Verification: all four build targets rebuilt clean (no `clang` slowdown,
same ~5s each as before the split) and type-check with no errors; the
full `tests/asm/*.bin` regression suite re-run and confirmed byte-for-byte
identical register/`pc`/`cycles_run` output to the pre-split baseline for
every existing test, plus the new `sound_channel_test.bin`; the checked-in
`debugger.star` regression test (`tests/run_debugger_test.ps1`) still
passes unchanged. Full `cargo test` suite re-run clean (exit code 0,
every test binary passing). `cpu.star`'s own header comment, gotcha #6's
write-up, and the "Ideas for future work"/"What's implemented" sections in
`NOTES.md` all updated to describe the completed split rather than the
former "possible but not done" framing.

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