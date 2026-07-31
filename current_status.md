# Star Language: A Technical Assessment

*Reviewed at commit `fbec0ec` (2026-07-31), one stage after the prior
review at `4082b7b` (archived as
[changelog/071_2026-07-31_fbec0ec_current_status.md](changelog/071_2026-07-31_fbec0ec_current_status.md)
and
[changelog/071_2026-07-31_fbec0ec_todo.md](changelog/071_2026-07-31_fbec0ec_todo.md)).
This stage's `todo.md` had every
item marked **Done.** across every tier, including a new `U0` "user-added"
tier this cycle introduced (a direct ask to populate `docs/requests.md`,
tracked outside the usual P0-P3 scheme) — full completion of a todo that
includes a non-P0-P3 tier is itself worth noting, since it's the first time
the automatic trigger has fired off something other than a P0-P3-only
board. It was also, separately, asked for directly, immediately after that
closeout — same two-ways-at-once trigger shape `070` itself named. The
working tree was clean going into this review (`git status` showed nothing
to commit) — no repeat of `070`'s own "two uncommitted files" finding.
`cargo +stable-x86_64-pc-windows-gnu test` was started before this document
was drafted, per `070`'s own P3 #6; see "The Good" #5 for what its result
does and doesn't cover by the time of writing.

## The pitch, then and now

Unchanged: *"a game programming language with Pythonic-Rust syntax and
unique memory management modes, targeting native executables via LLVM
IR."* This stage, unlike `070`'s, did no version/process work at all — its
five commits split between finishing `070`'s own carried-over P1/P2 items
(committing an already-written doc section, fixing one stale reference,
implementing the one standing UART gap) and a single new, small,
documentation-only ask (`docs/requests.md`) that doesn't touch the compiler
or `projects/nova/` at all.

---

## This stage (`4082b7b` → `fbec0ec`, 2026-07-31)

Five commits: `84f6021` (reassessment: archived `070`, reseeded
`current_status.md`/`todo.md`, and committed `docs/design.md`'s already-
written-but-uncommitted "Known Permanent Caveats" section alongside it),
`ac76b8b` (documentation cleanup: `070`'s P1 #2), `c7e1bed` (Nova project
expansion: `070`'s P2 #3, UART framed-mode parsing), `5543cc8` (fixed a
regression in `mouse_interrupt_test.star` found while touching adjacent
UART test infrastructure), and `fbec0ec` (this cycle's own `U0` #1,
`docs/requests.md`). In substance:

- **`070`'s own uncommitted work landed, and the reassessment named it
  explicitly rather than treating it as invisible.** `84f6021`'s diff
  includes `docs/design.md` (+55/-… lines) alongside the archival and
  reseed — the "Known Permanent Caveats" section `070`'s "The Bad" #1
  flagged as real-but-uncommitted is now in `git show HEAD:docs/design.md`
  (confirmed directly: `grep -n "Known Permanent Caveats" docs/design.md`
  and the equivalent `git show HEAD:...` both find it at the same line).
- **`projects/nova/NOTES.md`'s stale `0.1.0` reference, fixed as scoped.**
  Line 2150 now reads "...for the language-wide `0.1.0` gate, which has
  since been bumped to at least `0.2.0`" — matches `070`'s own P1 #2
  exactly (a fragment next to the stale reference, intentionally imprecise
  about the exact current number to avoid a second spot needing upkeep).
  Confirmed by direct grep; zero remaining bare `0.1.0`-as-current-version
  references in that file.
- **UART framed-mode protocol parsing, implemented and verified by
  actually running the new test, not just reading `todo.md`'s claim.**
  `SERCTRL`'s control bit 2 (`0x04`) now gates a real byte-at-a-time frame
  parser in `uart.star` (`parse_frame_byte`, driven from `host_push_rx`),
  and a new opcode, `SERFSTAT` (`0xB4` — checked against every opcode
  table, not just `cpu.star`'s dispatch switch, before landing on a number
  clear of the reserved-but-unimplemented `0xA6`-`0xAB` debugger
  pseudo-opcodes), exposes framed-mode-enabled and a latched, read-and-
  clear checksum-error bit `SERSTAT` never had. This review built nothing
  itself but **ran** `tests/uart_framed_test.exe` directly: all 10 printed
  checks read `PASS`, matching `todo.md`'s claim line for line (good
  frame's two payload bytes come back via `SERIN`, no false checksum error,
  a bad frame's checksum error latches and its payload never reaches the
  RX FIFO, `SERFSTAT` read-clears). `docs/UART_SYSTEM.md` and
  `projects/nova/docs/nova16_instruction_reference.md` were both updated in
  the same commit to describe `SERFSTAT`/`0xB4` — confirmed present in
  both, not just in the narrative `NOTES.md` prose (see "The Bad" #1-2 for
  where this same commit's own doc sweep still missed two spots).
- **A real, silent regression in `mouse_interrupt_test.star` found and
  fixed, not just claimed.** The file's inline `Cpu` struct literal had
  drifted against `cpu.star`'s current field set (missing
  `next_strig_channel`/`sound_channel_handles`/`sound_channel_last_wav`,
  added by an earlier sound-channel round) and was also missing the
  `cpu_*.star` op-table imports and `-L sdl/lib/x64 -l SDL2` build flags
  needed to rebuild at all — the checked-in `.exe` kept passing only
  because it predated the drift and was never rebuilt. This review ran the
  rebuilt `tests/mouse_interrupt_test.exe` directly: all 5 `PASS` lines
  print, confirming the fix is real, not just a "Done." marker sitting on
  top of an untested rebuild.
- **`docs/requests.md`, this cycle's own `U0` #1, checked against source
  rather than guessed.** Six niceties (multi-line/block comments, numeric
  digit separators, `if let`/`while let` pattern binding, inclusive/stepped
  `for` ranges, multi-line string literals, default parameter values) —
  this review independently re-derived each claim against `src/lexer.rs`
  and `src/parser/`: `Lexer::scan_number` only accepts bare
  `is_ascii_digit()` runs (no `_`), `parse_for_stmt` hardcodes an exclusive
  `<start>..<end>` via a bare `DotDot` with no `..=` sibling and no step,
  `Param` (`src/parser/items.rs`) has no default-value field, and no
  `TripleStr`/`RawStr`-shaped token exists in the lexer. All four spot-
  checked claims held up; the other two (block comments, `if let`) were
  confirmed by this cycle's own prior work rather than re-derived fresh
  here. Purely a scoping document — no implementation, no test surface, and
  it says so explicitly, matching the ask's own framing.

Net: this stage closed every carried-over item from `070`'s "Next steps"
with the same discipline `070` itself established (verify against real
files/tests, not against what `todo.md` claims), and added one small,
self-contained documentation deliverable that doesn't touch compiler or
runtime code at all.

---

## The Good

**1. Every claim in this cycle's `todo.md` was checked against something
outside `todo.md` itself, and held up.** All five of this stage's
substantive items name a concrete artifact to check (a committed file, a
specific line of prose, a test binary) rather than asking the reader to
trust the write-up — and in the two cases with an actual executable to
run (`uart_framed_test.exe`, the rebuilt `mouse_interrupt_test.exe`), this
review ran them directly instead of re-reading the source and assuming.
Both matched their claimed pass counts (10/10, 5/5) exactly.

**2. A real, previously-silent regression was caught and fixed as a side
effect of unrelated work, and the write-up said so plainly instead of
folding it into the UART item's own scope.** `mouse_interrupt_test.star`
had been silently broken (unbuildable, in fact — not just logically wrong)
since an earlier round added fields to `Cpu` that this one test's hand-
written struct literal never picked up, and nothing caught it because its
stale `.exe` kept "passing." This is exactly the failure mode `069`'s
own P0 process (checking for false "Done." markers) exists to catch, and
this time it surfaced from ordinary adjacent work rather than a dedicated
audit — worth naming as the system catching a real bug through normal
cycle activity, not just through the reassessment ritual itself.

**3. The `SERFSTAT` opcode-number choice was made carefully, with the
scars of a specific documented near-miss.** `0xA6`-`0xAB` looked free by
reading `cpu.star`'s dispatch switch alone (it's silent about them), but
are in fact reserved by the assembler for unimplemented debugger pseudo-
opcodes (`SETBP`/`CLRBP`/`ENABRK`/`DISBRK`/`ENATRAP`/`DISATRAP`) — caught
only by grepping the assembler/disassembler/debugger opcode tables
directly rather than trusting the one file that looked authoritative but
wasn't. This project has hit exactly this shape of bug before (`067`'s ten
operand-count documentation bugs); avoiding a repeat by checking multiple
sources instead of one is worth calling out as the right instinct, not
assumed.

**4. `docs/requests.md` re-derives its own claims rather than asserting
them.** Each of the six entries names the specific function/token/struct
checked (`Lexer::scan_number`, `parse_for_stmt`, `Param`, the absence of a
`TripleStr`/`RawStr` token) instead of a general "Star doesn't support X"
claim — this review independently re-checked four of the six against
current source and found no daylight between the doc's claims and the
code. A small thing, but it's the same discipline `069`'s own P2 #5 asked
for applied to a brand-new doc on day one, rather than something that has
to be re-taught next cycle.

**5. The full test suite was started before this document was drafted,
matching `070`'s own P3 #6, and finished clean.** `cargo +stable-x86_64-pc-
windows-gnu test` was kicked off at the top of this review, ran
concurrently with the verification work above, and completed with **exit
code 0**: every printed `test result: ok. N passed; 0 failed` block in the
captured output (frontend suites down to `frontend_wrapping_fixed_time.rs`'s
39, plus the doc-tests) confirms this, and a direct `grep` for
`FAILED`/`error[` across the full captured output returns zero matches —
not just relying on the tail, same caveat about long-run output truncation
`069`/`070` both noted, but this time cross-checked with a full-output grep
rather than the tail alone.

---

## The Bad

**1. `NOTES.md`'s "Ideas for future work" section contradicts its own
"UART" section, from the same commit.** Line 2938 still reads "Remaining
gap in this area: UART framed-mode parsing" — directly false as of the
same `c7e1bed` commit that added a full "Framed-mode parsing is now
implemented" paragraph earlier in the same file (the "UART" section,
confirmed present and accurate). This isn't drift across cycles like
`070`'s NOTES.md finding was; it's a single commit's own doc sweep missing
one of two places the old "still a gap" framing appeared. Small and
mechanical, but exactly the kind of same-file internal inconsistency this
project's own conventions ask to avoid.

**2. `NOTES.md`'s "What's implemented" opcode-count summary is now stale
by one.** Line 995 still reads "171 opcodes (of the 180 ... instructions",
a count this file itself describes as mechanically cross-checked against
`cpu.star`'s `decode_operands` call sites — but `SERFSTAT` is a genuinely
new, Star-original opcode (no upstream Python reference has it), added by
this same cycle's `c7e1bed`, and isn't reflected in either the numerator or
the denominator. Should read something like "172 opcodes (of the 181...)"
once someone re-derives the count rather than incrementing both numbers by
hand without re-checking. Same root cause as finding #1 above: one commit,
two places in one file describing opcode-set totals, one updated and one
not.

**3. The standing structural caveats are all still true, unchanged, and
untouched this stage** — Windows-only fonts, "special guest" type families
(documented, not unified in mechanism), non-dynamic monomorphized-only
traits, warning-only stack-budget checks. Not a regression; nothing in
this stage's scope touched any of them. Carried forward again, same as
every prior cycle.

**4. `docs/requests.md`'s six items are, by design, not yet acted on.**
Explicitly scoped rather than implemented, per the ask itself — noted here
only so a future cycle doesn't read the doc's existence as having closed
anything. None are blocking; see "Next steps" P2.

---

## Goals vs. reality, honestly

This cycle's central question is narrower than `070`'s ("was the version
decision executed faithfully") or `069`'s ("are the gate's conditions
really met") — it's simply "did every item `070` carried forward, plus one
new small ask, actually land, and does the evidence hold up under direct
re-checking rather than a re-read of `todo.md`'s own prose." Checked
directly against the current tree and, where an executable exists, by
running it:

- **`070`'s P1 #1 (commit the two outstanding working-tree changes).**
  Done — `docs/design.md`'s caveats section is in `git show HEAD`.
- **`070`'s P1 #2 (fix `NOTES.md`'s stale `0.1.0` reference).** Done, and
  the exact wording matches what was promised (an imprecise "at least
  `0.2.0`" fragment, not a hard-coded second spot to maintain).
- **`070`'s P2 #3 (UART framed-mode parsing).** Done, and independently
  re-verified by running the new test binary rather than trusting the
  write-up — 10/10 checks pass, matching the claim exactly.
- **`070`'s P2 #4 (permanent caveats' durable home).** Done as a
  consequence of P1 #1 landing `docs/design.md` in git.
- **This cycle's own `U0` #1 (`docs/requests.md`).** Done, and four of its
  six claims independently re-derived against current lexer/parser source
  by this review rather than taken on faith.

Two new, small, genuine findings surfaced by this review that weren't in
any prior cycle's list (see "The Bad" #1-2) — both same-commit doc-sweep
misses in `NOTES.md`, not regressions in behavior. This review found no
case of a `todo.md` "Done." claim describing work that isn't actually
present or doesn't actually pass when run — every substantive claim this
cycle made checked out against a real file, a real grep, or a real
executable run.

---

## Next steps, prioritized

**P0 — Nothing broken.** Full `cargo +stable-x86_64-pc-windows-gnu test`
re-run this cycle, exit code 0, zero `FAILED`/`error[` matches across the
full captured output (not just the tail). No false "Done." claims found —
every substantive item this cycle made was checked against a real file, a
real grep, or a real executable run (see "Goals vs. reality").

**P1 — Small, concrete, worth doing before new feature work.**
1. **Fix `NOTES.md`'s two stale spots found this cycle** (see "The Bad"
   #1-2): the "Ideas for future work" bullet still calling UART
   framed-mode parsing a "remaining gap" (line 2938), and the "What's
   implemented" opcode-count summary still reading "171 opcodes (of the
   180..." without `SERFSTAT` folded into either number (line 995). Both
   one-line, mechanical fixes in a single file, same shape as `070`'s own
   P1 #2.

**P2 — Real, standing items, none urgent, none blocking.**
2. **UART TCP transport** remains out of scope, unchanged — `net.rs`'s
   `tcp_recv` still has no non-blocking/timeout mode, so a TCP-backed
   bridge would freeze waiting on an idle peer. Not a regression; carried
   forward for visibility the same way framed-mode parsing itself was
   before this stage closed it.
3. **The permanent structural caveats** (Windows-only fonts, "special
   guest" types, non-dynamic traits, warning-only stack-budget check) —
   still just standing, documented design choices with a durable home in
   `docs/design.md`. Not gaps to close.
4. **`docs/requests.md`'s six niceties** are now a real backlog of small
   language-ergonomics work, distinct from the Nova-project-heavy cadence
   of the last several cycles. None are blocking or urgent; the two most
   self-contained (numeric digit separators — a lexer-only change with no
   type-system implications; multi-line block comments) would be the
   natural first pick if a future cycle wants compiler-side work instead of
   another `projects/nova/` round.

**P3 — Keep the cadence honest.**
5. **This cycle's trigger fired off a `todo.md` whose only remaining open
   items lived in a new `U0` tier, not the usual P0-P3 board** — the first
   time that's happened. Worth confirming explicitly: `CLAUDE.md`'s trigger
   language ("every item in `todo.md` is marked Done... no open P0-P3 items
   remain") reads naturally as covering any tier, and this cycle treated it
   that way without needing to special-case `U0`. No change needed to the
   convention; just naming that the broader reading was tested for the
   first time and held.
6. **Continue starting the full `cargo test` run before drafting this
   document** — this is now the fourth cycle running that adjustment; kept.
