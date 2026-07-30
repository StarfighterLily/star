# Star Language: A Technical Assessment

*Reviewed at commit `9b4e24c` (2026-07-29), one stage after the prior
review at `34c7fea` (archived as
[changelog/066_2026-07-29_9b4e24c_current_status.md](changelog/066_2026-07-29_9b4e24c_current_status.md)).
Based on a full read of that prior assessment, `todo.md`'s "Previous work"
log, every file the intervening five commits touched (`git log --stat
34c7fea..9b4e24c`), `docs/conventions.md` and `CLAUDE.md` (both new this
stage), `docs/cross_platform_scope.md`, `src/lsp.rs`, `projects/nova/NOTES.md`'s
new sections, and the `.clinerules/` directory the new `CLAUDE.md` claims to
mirror. `cargo +stable-x86_64-pc-windows-gnu check --tests` is clean with
zero warnings at this commit. The full `cargo +stable-x86_64-pc-windows-gnu
test` run, started in the background at the top of this review, finished
clean (exit code 0, every one of ~69 test binaries reporting `0 failed`)
by the time this document was ready to finalize — see "A process note on
this review itself" below for why that took long enough to be worth
naming, even though it ultimately passed.

## The pitch, then and now

Unchanged from the last review, and still true: *"a game programming
language with Pythonic-Rust syntax and unique memory management modes,
targeting native executables via LLVM IR."* This stage didn't add language
surface — it closed process debt instead. That's a legitimate thing for a
stage to do (three prior assessments all flagged process gaps: no LSP, no
stated versioning policy, no automatic reassessment trigger), and this
stage closed all three in one sitting. The interesting finding this round
isn't a new compiler bug — it's that the closing process itself wasn't done
as cleanly as the "Done." markers in `todo.md` claim (see "The Bad" #1 and
#2 below), which is exactly the kind of thing a reassessment is supposed to
catch and exactly why the cadence is worth keeping.

---

## History: Stage 7 (`34c7fea` → `9b4e24c`, 2026-07-28 to 07-29)

The previous review's own "Next steps, prioritized" section became this
stage's `todo.md` verbatim, and every one of its seven items now reads
**Done.**:

- **P0 #1 — write-width generalization.** The single-opcode `MOV`-only fix
  from Stage 5 was generalized to ~30 call sites across `cpu.star`
  (arithmetic/bitwise/BCD/math-library/string-conversion), and the same
  live-reference-verification pass turned up two more real bugs along the
  way: `PUSH`/`POP` used a fixed 16-bit stack slot instead of the operand's
  actual width, and the BCD carry/borrow opcodes checked their flag against
  the *masked* result instead of the raw pre-mask value — the latter
  correcting a previous `NOTES.md` entry that had mis-documented this as
  intentional. Five new checked-in regression tests in `projects/nova/tests/asm/`,
  each independently verified against the live Python reference over the
  Nova-16 MCP bridge before being added.
- **P0 #2 — stack-budget warning.** New `Checker::check_stack_budget`
  (`src/types/stack_budget.rs`, 426 lines): a `star check`/`star build`-time
  heuristic that sums a function's own `let`-aggregate footprint plus its
  deepest statically-resolvable call chain's footprint, and warns (never
  errors, via a new `Checker`/`Compilation` `warnings` side-channel
  threaded through `src/driver.rs` and `src/main.rs`, parallel to the
  existing fatal `errors` path) at a 1MiB combined total — turning the
  exact incident class that forced Stage 5's 16MiB linker-flag bump into a
  compile-time signal. 11 new tests in
  `tests/frontend_stack_budget_warning.rs`.
- **P1 #3 — cross-platform scope, fully inventoried.** New
  `docs/cross_platform_scope.md` covers all three Windows-only codegen
  surfaces (not just fonts): networking and env-vars are scoped as cheap
  `Target`-gated match-arm additions with concrete per-line porting notes;
  GDI text rendering is scoped as genuinely hard with a concrete two-option
  vendor plan (`stb_truetype` preferred). `readme.md`'s "Platform Support"
  section, and `platform.rs`/`net.rs`/`os.rs`'s own module doc comments,
  all point at it. This is real, complete scoping work — the font-vendor
  plan the prior review asked to be sketched now has one, in enough detail
  that "add a `Target::LinuxGnu` arm" is close to a checklist for
  networking/env-vars specifically.
- **P2 #5 — `star lsp`.** New `src/lsp.rs` (638 lines): a minimal LSP
  server over stdio, hand-rolled `Content-Length`-framed JSON-RPC over the
  one new dependency this needed (`serde_json`), re-running the same
  `Driver::compile` pipeline `star check` already uses on `didOpen`/
  `didSave`. 17 new tests plus a real subprocess smoke test (stdin/stdout
  piped to a built `star.exe`, not just in-process calls). Wired into
  `editors/vscode`: a new `extension.js` (`vscode-languageclient`, plain
  CommonJS, no bundler), a `star.serverPath` setting, `package.json`
  bumped to `0.2.0` with `engines.vscode` raised to `^1.67.0` (the floor
  that dependency needs), and a rebuilt `star-lang-0.2.0.vsix` replacing
  the grammar-only `0.1.0` one.
- **P1 #4 — Nova audio/UART.** Marked **Done.** in `todo.md`. It isn't —
  see "The Bad" #1, the most consequential finding of this review.
- **P2 #6 — versioning policy.** `readme.md`'s "Versioning" section now
  states the actual gate explicitly: `0.1.0` until Nova is complete and has
  survived four bug-hunt rounds, then standard SemVer. A real, if informal
  by nature, improvement over the prior review's "no stated policy at all"
  gap — see "The Bad" #4 for a caveat on the gate's own definition.
- **P3 #7 — institutionalize the reassessment cadence.** New `CLAUDE.md`
  (root, agent-facing) and `docs/conventions.md` (the fuller human-facing
  version) both now state the trigger explicitly: full `todo.md` completion
  *is* the signal to stop and reassess, no one has to remember to ask. This
  document is the first reassessment produced under that written trigger
  rather than an ad hoc request — the mechanism this stage built is, right
  now, being exercised for the first time. See "The Bad" #2 for a gap in
  how completely that formalization actually landed.

Net: five of seven items are real, verified, tested work matching their
`todo.md` descriptions. Two (P1 #4, and the "keep `.clinerules` in sync"
clause of P3 #7) are not, in ways only visible by actually checking rather
than trusting the "Done." marker — which is precisely the failure mode a
reassessment exists to catch.

---

## The Good

**1. The reassessment cadence is now load-bearing, not aspirational —
including catching its own stage's shortfalls.** `CLAUDE.md`/
`docs/conventions.md` turned "someone remembered to ask for a review
twice" into a written, mechanical trigger (full `todo.md` completion), and
this document is that trigger firing for the first time. That it
immediately surfaced two real gaps in the very stage that wrote the
trigger (see The Bad #1, #2) is the strongest possible evidence the
mechanism works as intended, rather than being self-congratulatory
process theater.

**2. Verification rigor on the Nova side keeps improving, not just
accumulating.** The write-width generalization pass didn't just fix the
known bug wider — it re-verified prior documentation against the live
reference and found that document wrong (the BCD carry/borrow masking
order). `NOTES.md`'s new "Status: this port now supersedes the Python
reference" section draws the correct, non-obvious conclusion from this:
future discrepancies should no longer default to "assume Python is right."
That's a mature, evidence-backed position, not overconfidence — it's
explicitly scoped to what's actually been re-verified.

**3. `star lsp` is a genuinely complete minimal implementation, not a
stub.** Real `Content-Length` framing, real percent-decoding and
UTF-16-code-unit column conversion (verified against an astral-plane
emoji, not just ASCII), and — notably — an actual subprocess smoke test
that pipes stdin/stdout to a built `star.exe` rather than only calling
`handle_message` in-process. That last detail matters: a hand-rolled
JSON-RPC framer is exactly the kind of code where "the unit tests pass"
and "the wire protocol actually round-trips" can diverge, and this stage
tested the harder, more honest claim.

**4. The stack-budget checker is a well-scoped heuristic that names its
own gaps rather than overselling.** `src/types/stack_budget.rs`'s module
doc comment explicitly lists what it doesn't cover (calls through
closures/function values, a closure's own separate stack frame, deep
non-mutual recursion's per-call cost) and states each is an accepted,
warning-can-only-under-fire gap — the same "best-effort, not a soundness
proof" honesty `ir_check.rs` set the precedent for.

**5. Cross-platform scoping is now complete enough to be closer to a
checklist than a shrug.** `docs/cross_platform_scope.md` gives networking
and env-vars concrete per-line porting notes (down to which POSIX call
replaces which Win32 call and what sentinel-comparison change is needed)
and gives text rendering a real two-option vendor decision
(`stb_truetype` preferred, reasons given) rather than leaving it as "hard,
unscoped." The only remaining blocker for all of it is external (a Linux
devbox), not a documentation or planning gap.

---

## The Bad

**1. `todo.md`'s P1 #4 is marked "Done." and isn't — this is the most
important finding this review turned up.** The entry's own text ("Nova's
audio synthesis and UART needs *will be met next*... Getting these in is a
win across the board") is future-tense intent, not a completed-work
summary, and it's the only one of the seven closed items with no
corresponding "Previous work" paragraph and no file changes in either
`34c7fea..9b4e24c` commit. Checked directly against the code: `cpu.star`'s
`op_splay`/`op_sstop`/`op_strig` are still literal no-ops
(`self.halted = self.halted`), and `NOTES.md`'s own "Ideas for future
work" section — *written this same stage* — still lists "sound synthesis"
and "a UART host bridge" as not-yet-done. Nothing was implemented; the
`todo.md` line was marked complete anyway. This is worth taking seriously
precisely because the last four stages' credibility rests on "Done." always
meaning done — one false marker doesn't undo that track record, but left
uncorrected it would be the first crack in it. (Note also: the two
building blocks this item's own justification cited as blockers —
"multiplayer... network" and "stdin... text-based games" — already exist
at the language level, `tcp_connect`/`tcp_send`/`tcp_recv`/`tcp_close` in
`net.rs` and stdin support in `file_io.rs` both predate this stage. The
only genuinely new capability this item's premise needed was real audio
waveform synthesis/mixing and a real UART *host* bridge, and neither was
built.)

**2. `CLAUDE.md` claims a cross-tool sync that doesn't hold up.**
`CLAUDE.md`'s header states "`.clinerules/general.md` and
`.clinerules/workflows/todo` cover the same ground for Cline; keep all
three in sync if any changes." Checked directly: `.clinerules/general.md`
is 2 generic lines ("write industry-standard Rust... use PowerShell") and
`.clinerules/workflows/todo` is 4 generic lines with no mention of the
`+stable-x86_64-pc-windows-gnu` toolchain override (the single most
load-bearing rule in `CLAUDE.md` — plain `cargo build` fails outright on
this machine), no mention of the reassessment trigger, and none of
`docs/conventions.md`'s specificity. Both predate this stage and were
never touched by it. This is a small, mechanical fix (update two short
files), but it's a concrete, checkable claim in a checked-in file that is
false today — the kind of drift that compounds silently if a Cline-based
session ever relies on it.

**3. Traits remain structural sugar over monomorphization, permanently,
by explicit decision.** Unchanged from every prior review — no vtable, no
`dyn Trait`, no heterogeneous `List<SomeTrait>`, still fully documented as
intentional rather than a gap. Carried forward for completeness, not
because anything changed this stage.

**4. The versioning gate's exit condition isn't itself well-defined.**
`readme.md` now states the gate ("until Nova is complete and has survived
4 bug-hunt rounds") explicitly, which is real progress over having no
stated gate at all — but "Nova is complete" isn't defined anywhere, and
Nova's own `NOTES.md` "Ideas for future work" list has *grown* this stage
(sound synthesis, UART bridge, an assembler, splitting `cpu.star` further),
not shrunk. A gate whose target keeps growing risks never being reached
by its own definition rather than by the language's actual readiness. This
isn't urgent, but it's worth deciding what "complete" means concretely
(a fixed opcode/feature checklist, most plausibly) before the list grows
again.

**5. The review cadence's first automatic firing took noticeably longer to
confirm than an ad hoc review would.** The full `cargo test` run (started
in the background at the top of this review) took long enough that this
document's drafting finished first — it did pass cleanly once it
completed, but a reassessment that fires mid-session rather than at a
point of someone's choosing needs to actually budget for that wait rather
than assume `check --tests` alone is enough, or risk finalizing before the
real confirmation lands. This time it worked out; the process gap (see
"A process note on this review itself") is worth naming regardless.

---

## The Ugly

**1. The full test suite took long enough to look stuck before it didn't
be.** Partway through this review, the background `cargo test` run showed
two idle `cargo` processes with near-zero CPU and no active `rustc` for a
long stretch — indistinguishable, from the outside, from the SDL/window-
contention hang-or-crash class the project's own test helpers already
document from prior full-parallel runs. It was, in fact, just slow (69
test binaries, many spawning real SDL windows/subprocesses) — the run
finished at exit code 0 with every binary reporting `0 failed` before this
document was finalized. Worth recording anyway: this stage doesn't have a
way to distinguish "slow" from "hung" from the outside other than waiting
it out, and the next automatically-triggered review should expect the same
uncertainty rather than assume either outcome by default.

**2. Every prior stage's unchanged structural caveats still stand.** The
Windows-only-by-construction scope (now fully documented, still not
retrofitted), the "special guest" type families (`Wrapping`/`Fixed`/
`Tick`/`Duration`/`Instant`, unified in documentation, not in mechanism),
and the big-aggregate stack-budget risk (now diagnosable at compile time
via a warning, but still only a warning, never a hard block) are all
carried forward unchanged from the last review. None regressed this stage;
none were the focus of it either.

---

## A process note on this review itself

This reassessment was triggered automatically (per `CLAUDE.md`/
`docs/conventions.md`'s new trigger) at the start of a session, rather
than requested at a point of someone's choosing. That surfaced two real
findings (The Bad #1, #2) a less adversarial pass might have accepted at
face value from the "Done." markers alone — which is the mechanism working
as designed. It also meant drafting this document ran concurrently with,
rather than strictly after, the full-test-suite confirmation every prior
review had time to obtain before writing anything (The Ugly #1) — it
finished clean, but the sequencing was closer than it should have been.
Both of those facts belong in the same document: the trigger is already
earning its keep, and it has a real, nameable cost. Neither should be
quietly dropped from the next cycle's memory of how this one went.

---

## Goals vs. reality, honestly

Unchanged from the last review's framing, which still holds: the original
design goals are largely achieved on their own terms, with the same two
permanent, self-named caveats (static-only dispatch, Windows-only runtime
target). What's different this stage is smaller and more procedural than
architectural — the project spent a cycle on tooling and process debt
rather than language surface, closed most of it well, and this review's
job was to check that "well" against "claimed," which is exactly where the
two real gaps above were found.

---

## Next steps, prioritized

**P0 — Fix what this review found, before it compounds.**
1. Either actually implement Nova's sound synthesis (waveform generation
   behind the already-dispatched `SPLAY`/`SSTOP`/`STRIG` opcodes) and a
   real UART host bridge (stdin- or socket-backed, using the
   already-existing `file_io.rs`/`net.rs` builtins — no new language
   surface should be needed for a minimal version), or correct `todo.md`'s
   P1 #4 to accurately read "not started" and requeue it honestly. Marking
   it done a second time without the underlying work would be a second,
   compounding instance of the exact gap this review exists to catch.
2. Bring `.clinerules/general.md` and `.clinerules/workflows/todo` into
   actual sync with `CLAUDE.md`/`docs/conventions.md` — at minimum the
   `+stable-x86_64-pc-windows-gnu` toolchain override (the single fact
   whose absence would send a Cline-based session down a "plain `cargo
   build` fails, why?" dead end) and the reassessment trigger.

**P1 — Close the distance between "seam exists" and "port is actually
cheap" — carried forward, still gated externally.**
3. No code action here today: the only remaining blocker across
   networking/env-vars/fonts is a real Linux devbox to build and link
   against (`docs/cross_platform_scope.md`'s own "What 'devbox' unblocks
   specifically" section already says this). Nothing to prioritize until
   that hardware exists.
4. Decide, concretely, what "Nova is complete" means for the versioning
   gate (readme.md's "Versioning" section) — a fixed checklist of
   opcodes/subsystems, most plausibly — before `NOTES.md`'s "Ideas for
   future work" list grows further and makes the gate's target a moving
   one by default rather than by decision.

**P2 — Genuinely new capability, once P0/P1 are settled.**
5. If P0 #1 lands as real implementation work: sound synthesis and a UART
   bridge are still the right *next* stress test for Nova after the
   correction above, for the same reasons the last review gave (they're
   the two remaining items on Nova's own list needing genuinely new
   host-I/O-shaped capability rather than more opcode coverage) — this
   isn't a new idea, just the same one, done for real this time.

**P3 — Keep the cadence honest.**
6. Nothing structural to change here — the trigger fired correctly this
   cycle, and the full suite did pass. The one adjustment worth carrying
   forward: when the trigger fires mid-session rather than being
   requested, start the full test suite first and actually wait for its
   result before finalizing the document, rather than drafting concurrently
   with it and patching the conclusion in after the fact the way this
   review had to.
