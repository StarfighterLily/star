# Star Language: A Technical Assessment

*Reviewed at commit `45382cc` (2026-07-29), one stage after the prior
review at `9b4e24c` (archived as
[changelog/066_2026-07-29_9b4e24c_current_status.md](changelog/066_2026-07-29_9b4e24c_current_status.md)).
This stage's own `todo.md` (archived as
[changelog/067_2026-07-29_45382cc_todo.md](changelog/067_2026-07-29_45382cc_todo.md))
had every P0-P2 item genuinely marked **Done.** with real, verified work
behind each one before this review started — the trigger condition per
`CLAUDE.md`'s reassessment rule. Unlike the *previous* review's own
triggering stage (which found a false "Done." with zero implementation
behind it), this review's own audit of those claims held up under scrutiny:
full `cargo +stable-x86_64-pc-windows-gnu test` was re-run twice during
this stage (once to confirm the incoming state, once after two new
compiler fixes made this same stage) and passed clean both times, 72/72
binaries, 0 failed. `cargo +stable-x86_64-pc-windows-gnu check --tests` is
also clean.*

## The pitch, then and now

Unchanged: *"a game programming language with Pythonic-Rust syntax and
unique memory management modes, targeting native executables via LLVM
IR."* What changed this stage is smaller in code-surface terms (two
one-line codegen fixes) but larger in what it means for the language's
flagship stress-test project: `projects/nova`'s own framing shifted, for
the first time, from "a demanding exercise to find compiler bugs" to "a
project that intends to become the de facto Nova-16 emulator, full stop" —
see `projects/nova/NOTES.md`'s new framing note at the very top of that
file. That shift is a documentation change, not a code change, but it's
the kind of thing a reassessment exists to notice and record: it resets
what "good enough" means for that project going forward.

---

## This stage (`9b4e24c` → `45382cc`, 2026-07-29)

The prior review's "Next steps, prioritized" became this stage's `todo.md`.
Three items closed for real (P0 #1 sound/UART, P0 #2 `.clinerules` sync, P1
#3 versioning-gate adequacy) before this review's own session picked up
the thread and added a fourth round of work not yet captured in any prior
`todo.md`:

- **Nova's disassembler, `projects/nova/disasm.star`.** A real, working
  disassembler — decodes a compiled `.bin` back into readable Nova-16
  assembly text, independent of `Cpu`/`cpu.star` entirely (pure byte-stream
  decode, no SDL2 link dependency, unlike every other Nova build target
  here). Verified against four independently-produced `.bin` files,
  including one copied verbatim from the upstream Python repo, with every
  decoded mnemonic/operand/byte-length matching the source `.asm` exactly.
  See `projects/nova/NOTES.md`'s new "Disassembler" section.
- **Two genuine, previously-unknown Star compiler bugs, found, fixed, and
  regression-tested.** Building the disassembler's own string-formatting
  helpers hit `codegen error: function must end in a value-producing
  expression or explicit return` on code that type-checked cleanly — a
  function whose entire body was a trailing `if`/`else` with each arm a
  bare f-string (or, after switching away from f-strings to work around
  that, a bare `concat(..)` call) as its value. Root cause in both cases:
  `Codegen::emit_expr`'s `TypedExpr::FStr` arm (`src/codegen/expr.rs`) and
  `Codegen::emit_str_concat` (`src/codegen/builtins.rs`) each returned a
  *bare, untagged* SSA register instead of the `"<llvm-type> <value>"`
  tagged string every sibling arm/builtin returns — which
  `Codegen::emit_trailing_if_value`'s `rsplit_once(' ')` type-recovery
  (`src/codegen/stmt.rs`, the exact same function a prior stage's bug #2
  fixed a *different* bug in) silently choked on. Both are now one-line
  fixes (`format!("i8* {}", buf)` instead of bare `buf`), each verified
  against a minimal repro and the full test suite. See
  `projects/nova/NOTES.md`'s "Seven Star compiler bugs found and fixed" #6
  and #7.
- **A third, related bug found but *not* fixed.** Calling a function that
  itself materializes its return value via an f-string, more than once in
  the same running program, can corrupt the result (`hex_word(0x1234)` came
  back `"444"` instead of `"1234"` in one repro; a wrapper function
  returned the correct value on its first call and a corrupted one on its
  second/third). This reproduces even after the two fixes above, and even
  when the *inner* function being called is `concat`-based rather than
  f-string-based, as long as an f-string appears *somewhere* in the call
  chain more than once. Not root-caused — `disasm.star` routes around it
  by using no f-strings anywhere in its own source, which was sufficient to
  ship correct, verified output, but the underlying compiler bug is still
  live and could affect any other project. Flagged in `NOTES.md` and in
  this review's own "Next steps" below, not silently dropped.
- **Ten real operand-count errors found and fixed in
  `docs/nova16_instruction_reference.md`.** Building the disassembler
  required knowing every opcode's exact operand count, so the doc's own
  table was mechanically cross-checked against `cpu.star`'s actual
  `decode_operands(N)` call sites rather than trusted at face value — the
  same "the code is ground truth, not the doc" standard this project's own
  `NOTES.md` had already established for `PUSH`/`POP` and
  `SPRITE_SYSTEM.md`. The cross-check found `SFLIP` (doc said 2 operands,
  code says 1), `KEYCLEAR`/`SED`/`CLD`/`CLA` (doc said 1, code says 0 — all
  four handled with no operand decode at all), and
  `BCDA`/`BCDS`/`BCDCMP`/`BCDADD`/`BCDSUB` (doc said 1, code says 2 — the
  most consequential of the ten, and one `NOTES.md`'s own BCD section had
  already implicitly contradicted with a worked two-operand example without
  anyone tracing it back to the doc). All ten fixed directly in the doc.
- **Several stale claims found and fixed in `projects/nova/NOTES.md`
  itself**, independent of the disassembler work: the "Sound" bullet in
  "What's implemented" still called `SPLAY`/`SSTOP`/`STRIG` "register-model
  stubs" two stages after `sound.star` made them real; the "Testing"
  section's own build instructions for `tests/run_bin.star` still said "no
  SDL needed" a stage after `run_bin.star`'s *own* header comment was
  corrected to say the opposite (todo.md's own prior-stage note flagged
  this as owed and it hadn't been paid yet); `sound.star`/`uart_bridge.star`
  were missing from the file's own "Contents" index entirely.
- **One suspected doc gap that turned out not to be real, caught before it
  became a permanent claim.** An early pass suspected
  `docs/nova16_instruction_reference.md`'s "Special Registers" section was
  missing the `P0:`-`P9:`/`:P0`-`:P9` byte-half register codes — it wasn't;
  a `grep` pattern that happened to exclude `:`-containing mnemonics was
  the actual cause. Corrected in `disasm.star`'s own comment before this
  document was written, rather than propagating a second false claim into
  a fixed file.

Net: every item in this stage's `todo.md` that carries a **Done.** marker
has real, verified work behind it, including a live re-run of the full
test suite after the two compiler fixes specifically (not just trusted
from before those fixes landed). No `todo.md` item this stage was closed
on intent alone.

---

## The Good

**1. The disassembler round is the first time this project explicitly
worked *as* a de facto emulator project rather than *for* the language.**
Every prior Nova round's stated purpose was "exercise the compiler, write
down what broke" — genuinely valuable, but it meant correctness work was
justified by what it taught about Star, not by what a Nova-16 program's
author would need. This stage's disassembler was justified the other way:
it's a real, useful tool an actual Nova-16 developer would want, and the
two compiler bugs it turned up were a *side effect* of building it, not
the point of building it. `NOTES.md`'s new framing note makes this
explicit rather than leaving it to be inferred from one round's tone.

**2. A self-caught false lead is itself evidence the underlying process is
sound.** Suspecting, then disproving, the "Special Registers" doc gap
(above) is a small thing, but it's the right shape of small thing: a
plausible-looking claim was checked against the actual mechanism (why did
the earlier `grep` not match those lines) rather than accepted because it
fit a pattern ("docs drift, therefore this drifted too"). This project has
a real prior incident (`NOTES.md`'s BCD section, "this file is not immune
to stating [a claim] while having done [something else]") of exactly the
opposite failure mode; catching this one before it shipped is the standard
working as intended.

**3. Both compiler bugs were fixed at the root, not patched around, and
each is now backed by a minimal, independently-reproducible test case
described in `NOTES.md` well enough that a future regression would be easy
to re-diagnose.** Neither fix required guessing — both were traced to the
exact line (`buf` vs. `format!("i8* {}", buf)`) by reading the actual
codegen function, confirmed against a two-line repro before and after, and
re-verified against the full suite. This matches the standard the five
prior compiler-bug fixes in this project's history set, not a lower bar
for a "just documentation-adjacent" bug.

**4. The third bug (repeated f-string-call corruption) was reported rather
than hidden.** It would have been easy to ship `disasm.star`'s f-string-free
workaround silently and move on — the tool works, the output is correct,
nobody reviewing the diff would necessarily notice anything was avoided.
Instead it's written up in `NOTES.md` with the exact repro, a stated
hypothesis for the root cause, and an explicit note that the hypothesis is
unconfirmed. This is the same "document rather than hand-wave" standard
this project holds itself to elsewhere, applied to an *unglamorous*
finding (a bug the reviewer didn't have time to fully solve) rather than
only to the wins.

---

## The Bad

**1. The repeated-f-string-call corruption bug is a real, live, unfixed
compiler defect with a blast radius wider than Nova.** Any Star project
that calls an f-string-producing function more than once from within
another f-string-adjacent context could hit this — it isn't Nova-specific,
it just happened to be found there. It's flagged in two places (`NOTES.md`
and this review's "Next steps" below) but genuinely not fixed, and no
timeline exists for when it will be. Worth escalating to its own P1 item
rather than letting it ride along as a Nova footnote indefinitely.

**2. `docs/nova16_instruction_reference.md` was wrong for an unknown but
plausibly long time, and the mechanism that caught it (building an
unrelated tool that happened to need ground-truth operand counts) is not
something that would trigger routinely.** Ten real errors, including one
(the BCD group) that `NOTES.md`'s own text had already implicitly
contradicted without anyone connecting the two documents. There's no
standing process that re-derives this doc from `cpu.star` on a cadence —
it took a disassembler needing the same data to notice. Not urgent to fix
structurally (the doc is fixed now, and this project doesn't currently
have machinery to auto-generate documentation from source), but worth
naming: the next drift in this doc will again go unnoticed until something
else needs the same ground truth.

**3. Every prior stage's unchanged structural caveats still stand.** The
Windows-only-by-construction scope, the "special guest" type families,
the big-aggregate stack-budget risk (warning-only, never a hard block),
and traits as permanently-non-dynamic monomorphized sugar are all carried
forward unchanged. None regressed this stage; none were the focus of it.

---

## Goals vs. reality, honestly

Unchanged in the broad strokes: the original design goals are largely
achieved on their own terms, with the same permanent, self-named caveats
(static-only dispatch, Windows-only runtime target). What's different this
stage is that Nova's own goalposts moved — not because the language grew,
but because the *project* decided what it's for. That's a legitimate kind
of progress a purely-code-focused review would miss entirely, which is
part of why this document's scope has always included Nova's own `NOTES.md`
rather than treating it as out of band.

---

## Next steps, prioritized

**P0 — Nothing this review found needs fixing before new work starts.**
This is itself worth recording: the last two reviews each found a P0 (a
false "Done." marker, then a `.clinerules` sync gap) before anything else
could proceed. This one didn't. Don't read that as the process getting
lax — it's the first review where the incoming `todo.md` was independently
re-verified (full test suite re-run, not just trusted) before this
document was drafted, which is exactly the discipline the last review's
own "Next steps" P3 asked for.

**P1 — The two most concrete, already-scoped gaps.**
1. **Root-cause the repeated-f-string-call corruption bug** (see "The Bad"
   #1, and `NOTES.md`'s "Seven Star compiler bugs" write-up for the fullest
   repro). Independent of any further Nova work — this deserves its own
   session, not a fold-in to the next feature round. Start from the
   hypothesis already recorded (a `star_rc_alloc` buffer from a first
   f-string call not being retained/protected before a second call reuses
   its address) and confirm or rule it out by reading
   `Codegen::emit_expr`'s `TypedExpr::FStr` arm's RC-tracking calls
   directly, the same way bugs #6/#7 were actually diagnosed rather than
   guessed at.
2. **An actual assembler** for `projects/nova`, so a `.bin` can be produced
   from Star-authored (or at least locally-authored) source instead of only
   loaded from the upstream Python toolchain's output. This is now the
   single biggest named-tooling gap left in `readme.md`'s versioning gate
   — the disassembler this stage built gives an assembler's output
   somewhere to be checked immediately (assemble, then disassemble, then
   diff against the source), which wasn't true before this stage.

**P2 — Bigger, still-unscoped tooling gaps.**
3. A debugger and GUI+controls parity with the Python reference's own
   tooling — both still genuinely unstarted, both still only named
   qualitatively by `readme.md`'s versioning gate. Lower priority than P1
   above: a debugger benefits from an assembler existing first (source-line
   breakpoints need something to map back to), and "GUI+controls parity"
   needs its own scoping pass (what does the Python reference's own GUI
   actually offer beyond what `main.star`'s SDL window already does?)
   before it's actionable rather than aspirational.

**P3 — Keep the cadence honest.**
4. Nothing structural to change in the reassessment mechanism itself this
   time — it fired correctly (every `todo.md` item genuinely done), the
   full test suite was run *before* finalizing this document rather than
   concurrently with it (the previous review's own stated adjustment), and
   it caught a real, if minor, would-be documentation error before this
   file shipped (see "The Good" #2). Carry the same discipline forward:
   verify, don't trust, before drafting the next one of these.
