# Star Language: A Technical Assessment

*Reviewed at commit `82be6e2` (2026-07-30), one stage after the prior
review at `cacd569` (archived as
[changelog/068_2026-07-30_cacd569_current_status.md](changelog/068_2026-07-30_cacd569_current_status.md)).
This stage's own `todo.md` (archived as
[changelog/069_2026-07-30_82be6e2_todo.md](changelog/069_2026-07-30_82be6e2_todo.md))
had every one of its six items marked **Done.**, which is this cycle's
trigger per `CLAUDE.md`/`docs/conventions.md`. It was also, separately,
called for by name: the user asked for this reassessment explicitly, to
settle the one question every review since `067` has flagged as the most
overdue open item and then deferred — whether the `readme.md` versioning
gate is actually satisfied, and whether the version number should move —
and volunteered a personal read ("Nova is complete plus random bug fixes
as encountered; Star is reliable and useful") for this review to check
against the evidence rather than adopt on say-so. `cargo
+stable-x86_64-pc-windows-gnu check --tests` is clean. A full `cargo
+stable-x86_64-pc-windows-gnu test` run was started before this document
was drafted; see the note at the end of "The Good" for its result.*

## The pitch, then and now

Unchanged: *"a game programming language with Pythonic-Rust syntax and
unique memory management modes, targeting native executables via LLVM
IR."* This stage, like the one before it, touched no compiler-internals
files for their own sake except one real bug fix (the `clang`
large-aggregate-reassignment pathology, root-caused this time rather than
merely worked around) — the bulk of the work is in `projects/nova/`
finishing off its own deliberately-scoped-out gap list, plus the
process/documentation work this reassessment itself is part of.

---

## This stage (`cacd569` → `82be6e2`, 2026-07-30)

The prior review's "Next steps, prioritized" became this stage's five real
`todo.md` items (P0 was empty going in):

- **A checked-in `debugger.star` regression test**
  (`projects/nova/tests/run_debugger_test.ps1` +
  `debugger_test_commands.txt`/`debugger_test_expected.txt`) — a real
  scripted-stdin-in/captured-stdout-out session against
  `write_width_test.bin`, cross-checked against that test's own documented
  expected register values. A genuine dead end surfaced and recorded along
  the way: live-piped stdin (`Get-Content | & $exe`, and a raw .NET
  `Process.StandardInput.Write()`) silently corrupts the *first* line
  `read_line()` reads back, while a real disk-file redirect reads
  correctly every time — root cause not chased down since a real file was
  already the right choice for a checked-in test regardless.
- **F5-F8 hotkey verification, closed for real.** The prior stage's own
  "Bad" #1 named this unconfirmed. This stage hit a false alarm worth
  recording in full because it looked, briefly, like a real bug: PC
  appeared frozen across repeated Step presses against `gfxtest.bin`, with
  a temporary debug `println` confirming the step call really was
  executing — until `disassemble_program` over the Nova-16 MCP server
  showed the PC sat on a deliberate `JMP $` idle-loop instruction the demo
  reaches within its first rendered frame, where "step does nothing" is
  the *correct* output, not a symptom. Re-verified for real against
  `pixelfill.bin` (which doesn't park in a tight idle loop as quickly),
  confirming genuine step-by-step PC advancement via both F8 and the GUI
  button.
- **"Nova is complete" defined concretely, and checked off item by item**
  against `readme.md`'s own gate text — see "Goals vs. reality" below for
  why this is this stage's central finding rather than a routine
  checklist.
- **The `clang` large-aggregate-reassignment pathology, root-caused and
  fixed** (`TypedStmt::Assign`'s `Eq` branch in `src/codegen/stmt.rs`,
  which had no large-aggregate special case, unlike `TypedStmt::Let` right
  above it). Confirmed via a minimal repro to be a genuinely different gap
  from "Seven Star compiler bugs found and fixed" #1's already-fixed
  construction-time shape: reassignment to an existing mutable binding hit
  a `emit_call_expr` whole-aggregate-materialization fallback the original
  bug hunt's own repro never exercised. Fix mirrors the existing
  construction-time fix's shape (build into a scratch alloca, resolve the
  real target's address, release-then-memcpy) and cut the exact real-world
  repro (a `let mut cpu = f()` reassigned inside `if`/`while` nesting) from
  an 11m19s hard `clang` failure to 2.4 seconds. Six new codegen-shape
  tests plus five real `clang`-compiled runtime tests in
  `tests/frontend_large_aggregate_reassignment.rs`.
- **Nova's remaining scoped-out gap list, closed except two items left out
  by explicit instruction** (`SMIX`/`SECHO`/`SREVERB`/`SFILTER`, still
  unimplemented in the Python reference itself, and `debugger.star`
  source-line breakpoints): a true per-8-hardware-channel sound voice
  model (new `sound_play_channel`/`sound_stop_channel` compiler builtins,
  `SW`'s channel-select bits 3-5 now actually decoded), a real one-pole
  pink-noise filter matching the reference's own
  `_generate_waveform_sample` bug-for-bug, and `cpu.star`'s ~100
  opcode-handler methods split across 11 `cpu_*.star` files by group (a
  pure code-motion refactor, confirmed byte-for-byte identical regression
  output across the full `tests/asm/*.bin` suite before and after).

Net: every named item closed, one genuine new Star compiler bug found and
fixed along the way (not left for this review to catch), and the process
debt named across three reviews running — an undefined "done" gate — was
finally resolved with a checklist rather than deferred a fourth time.

---

## The Good

**1. The versioning gate got an actual checklist instead of a fourth
deferral.** `067`'s "Bad" #4, `068`'s "Bad" #3, and this stage's own
`todo.md` P2 #3 all named the same thing: `readme.md` says the version
moves once "the Nova project is complete (full system implementation,
GUI+controls, and tooling to match Python reference, NoBASIC optional) and
minimal 4 rounds of bug hunts," with no fixed definition of what that
means concretely. This stage built one and checked it item by item — see
"Goals vs. reality" below, where this review re-runs that check
independently rather than taking the prior pass's word for it.

**2. The `clang` reassignment bug is a real, previously-uncovered compiler
bug, not a rediscovery.** The repro work explicitly tested the
*construction*-only shape first (three fresh `let` bindings, each a
1MB-struct-returning call) and confirmed it was already fast — ruling out
"this is just #1 again" before concluding reassignment was a genuinely
uncovered third shape (after construction and return/parameter-passing).
That discipline — falsifying the easy explanation before accepting the
harder one — is worth naming.

**3. The `cpu.star` split was de-risked before being applied for real.**
Before touching the actual ~3200-line file, two standalone scratch repros
confirmed the specific cross-file `impl`/free-function resolution
semantics the split depends on (a method calling `self.g()` where `g` is
defined in a different file than the type, and a struct field whose type
lives in a *third* file neither the core nor extension file imports). Only
after both resolved correctly was the real split done — and it was then
verified byte-for-byte identical against the pre-split regression
baseline, not just "it compiled."

**4. The full suite was actually re-run for this review, not assumed
clean from the last pass's word.** `cargo +stable-x86_64-pc-windows-gnu
test` (72 top-level `tests/*.rs` files) finished with exit code 0 — every
test binary passing, 0 failures anywhere in the run, consistent with the
"clean full-suite re-run" every stage in this project's history has
reported after its own changes. Captured output for the long-running
binaries was truncated by this session's own tooling before this document
was drafted; the authoritative signal is the run's own exit code, not a
transcript of every individual assertion.

---

## The Bad

**1. The version-bump decision itself is still not this document's to
make, and isn't made here.** This review confirms the gate's *conditions*
are met (see "Goals vs. reality" below) — that is a checkable, falsifiable
claim, verified independently in this cycle rather than inherited from the
last one. Whether to actually flip `readme.md`'s Versioning section and
`Cargo.toml`'s version number, and to what number, is a different kind of
call: a public-facing signal, explicitly named in `CLAUDE.md`'s "Things
not to do" as something not to fold into other work, and one three prior
reviews have all consistently routed to the user rather than decided
unilaterally. This review does not break that pattern — it hands over a
completed checklist and a recommendation instead of an executed edit. See
"Next steps" P1 #1.

**2. `sound.star`'s leaked WAV handles are the one named audio
simplification that's still standing.** Both other "known simplification"
audio entries this project tracked (the shared-channel model, the
approximate pink noise) were closed this stage; the leaked-handle issue
was explicitly out of scope for todo.md P2 #5 and remains genuinely open,
not newly discovered.

**3. Every prior stage's unchanged structural caveats still stand.** The
Windows-only-by-construction scope (GDI text, Winsock, `_putenv_s`), the
"special guest" type families (`Wrapping`/`Fixed`/`Tick`/`Duration`/
`Instant` — unified in documentation, not in mechanism), traits as
permanently non-dynamic monomorphized sugar, and the big-aggregate
stack-budget risk (diagnosable at compile time via a warning, never a hard
block) are all carried forward unchanged. None regressed this stage; none
were the focus of it. None of these are gaps in an unfinished feature —
each is a named, documented design choice — but "documented" isn't the
same claim as "gone," and a version bump doesn't erase them from being
true.

---

## Goals vs. reality, honestly

This is the central question this cycle exists to answer, so it gets
checked here independently rather than summarized from the last pass.
`readme.md`'s own gate text, checked condition by condition against the
current tree:

- **"Full system implementation."** `projects/nova/NOTES.md`'s own
  "What's implemented" lists 167 of the 180 opcodes
  `docs/nova16_instruction_reference.md` documents as real instructions.
  The 13-opcode gap resolves to three separately-justified categories, not
  one undifferentiated shortfall: `STREXT`/`STREXTI`/`MEMCMP` (4-operand
  opcodes, out of scope by a named language limitation — this compiler's
  builtin-call ABI doesn't carry more than 3 operands cleanly, see
  "4-operand instructions are out of scope" in `NOTES.md`); `SMIX`/
  `SECHO`/`SREVERB`/`SFILTER` (unimplemented in the Python reference's own
  `opcodes.py` too — a bug-for-bug match, not a gap); and six
  hardware-debugging opcodes (`SETBP`/`CLRBP`/`ENABRK`/`DISBRK`/
  `ENATRAP`/`DISATRAP`, superseded by `debugger.star`'s host-side
  breakpoint implementation, the same architecture `nova_debugger.py`
  itself uses). Memory banking, screen/layer compositing, sprites,
  keyboard, UART (with a real host bridge), sound (now with the per-8-
  channel voice model and real pink-noise filter this stage added), mouse,
  and timer/interrupts are all present per that same list.
- **"GUI+controls."** `main.star`'s toolbar (Start/Pause, Stop, Reset,
  Step, Load) plus status bar and F5-F9 hotkeys — this stage's own P1 #2
  confirmed the hotkeys for real, closing the one piece of this condition
  the prior review had only inferred rather than observed.
- **"Tooling to match Python reference."** Binary loader, disassembler,
  assembler, and debugger — all four real, all cross-checked against the
  live Python reference over MCP at least once (`NOTES.md`'s own
  "Verification" subsections), not merely modeled on its source.
- **"NoBASIC optional."** Explicitly parenthetical in the gate's own
  wording — not a requirement either way.
- **"Minimal 4 rounds of bug hunts."** Overwhelmingly cleared under any
  reading of "round": the "Seven Star compiler bugs found and fixed"
  writeup, the repeated-f-string-call corruption bug, ten operand-count
  documentation bugs (`changelog/067`), the Cpu SP/FP reset-value bug, and
  this stage's own `clang` large-aggregate-reassignment bug are five
  Nova-driven discoveries alone, before counting the compiler-wide
  bug-hunting stages `changelog/025` onward document independently.

Every condition the gate names, read as written, is satisfied. That is a
stronger claim than "the prior review said so" — this review re-derived
it from `NOTES.md`'s own lists and this stage's own new evidence (the
hotkey re-verification, the checklist walk above) rather than inheriting
the conclusion. The caveats in "The Bad" #2 and #3 are real, but none of
them are conditions the gate's own text actually names — the gate asks
for a complete system, matching tooling, and a bug-hunt cadence, not
"free of every documented simplification" or "portable to other
platforms." Conflating those would be moving the goalposts the gate itself
never set.

**What this review will not do unilaterally: decide the version number,
or edit `readme.md`/`Cargo.toml` to reflect it.** That stays a call for
the user — see "Next steps" P1 #1 for the concrete question this review
is handing back, including this reviewer's own recommendation on it.

---

## Next steps, prioritized

**P0 — Nothing broken needs fixing before new work starts.** No false
"Done." markers this cycle; the one thing found mid-stage (the `clang`
reassignment bug) was root-caused and fixed within the same stage that
found it, with new regression coverage, not left for this review to
catch.

**P1 — The one decision this whole cycle has been building toward.**
1. **Decide whether, and to what version, `readme.md`'s Versioning
   section and `Cargo.toml`'s version number move**, now that this review
   has independently confirmed the gate's own stated conditions are met
   (see "Goals vs. reality" above). This reviewer's recommendation, for
   what it's worth: move to `0.2.0`, not straight to `1.0.0`. The gate's
   own text ties the *next* version to "usable and a semblance of
   stability can be expected," not to a SemVer-1.0-style public-API
   stability commitment — and the project's only real-world exercise so
   far is one (admittedly demanding) consumer, `projects/nova`, not
   independent third-party usage. `1.0.0` is a defensible destination
   eventually; `0.2.0` is the more honest signal for "the named gate is
   cleared" specifically, leaving `1.0.0` for whenever there's evidence
   beyond a single in-repo project exercising the surface. This is a
   recommendation, not a decision made here — the user asked for this
   review explicitly to weigh in on exactly this question, and named a
   personal read that leans the same direction on the underlying
   "is it ready" judgment, but never specified a number or asked for the
   file edit itself to happen unprompted.
2. Once a number is chosen: update `readme.md`'s Versioning section
   (replacing "There is no guarantee of stability or usability" with
   language reflecting the gate having been cleared) and `Cargo.toml`'s
   `version` field together, in the same change — and update
   `docs/conventions.md`'s own "Versioning" section (currently still
   says "`0.1.0`, explicitly no stability guarantee") to match, since it
   would otherwise immediately contradict the new `readme.md` text.

**P2 — Real, still-open gaps, none blocking the version question above
(the gate never named them).**
3. `sound.star`'s leaked WAV handles (see "The Bad" #2) — the one
   remaining named audio simplification.
4. `SMIX`/`SECHO`/`SREVERB`/`SFILTER` and `debugger.star` source-line
   breakpoints — both still genuinely out of scope, unchanged from
   before this stage, carried forward for visibility rather than as
   active work items.
5. The permanent structural caveats from "The Bad" #3 (Windows-only
   scope, "special guest" types, non-dynamic traits, warning-only
   stack-budget check) — not gaps to close, but worth a standing line
   item so a future version-number decision (a `1.0.0` push, say) doesn't
   have to rediscover them from scratch.

**P3 — Keep the cadence honest.**
6. This cycle was triggered two ways at once — `todo.md`'s own full
   completion, and the user asking for it directly — and both pointed at
   the same underlying question. Worth naming as a healthy sign rather
   than a coincidence: the automatic trigger and a direct human ask
   converging on the same "is this actually done" question is exactly
   what the trigger is supposed to catch even when nobody asks.
7. Continue starting the full `cargo test` run before drafting this
   document rather than concurrently with it (the adjustment two reviews
   running have now made) — this cycle followed that adjustment; the
   next one should too.
