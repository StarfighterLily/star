# Star Language: A Technical Assessment

*Reviewed at commit `4082b7b` (2026-07-30), one stage after the prior
review at `82be6e2` (archived as
[changelog/070_2026-07-30_4082b7b_current_status.md](changelog/070_2026-07-30_4082b7b_current_status.md)
and
[changelog/070_2026-07-30_4082b7b_todo.md](changelog/070_2026-07-30_4082b7b_todo.md)).
This stage's own `todo.md` had every item across every tier marked
**Done.**, including its P3 items — closed out explicitly this cycle as
process/cadence notes rather than concrete asks, per the user's own
framing — which is this cycle's trigger per `CLAUDE.md`/`docs/
conventions.md`. It was also, separately, called for by name: the user
asked to run the reassessment directly right after that P3 closeout. Two
files were left uncommitted in the working tree going into this review
(`docs/design.md`, `todo.md`) — see "The Bad" #1 below; this review reads
and evaluates them as they stand on disk, since that's the real state of
the project regardless of git's index. `cargo +stable-x86_64-pc-windows-gnu
test` was run fresh for this review (not inherited from the last pass) and
finished with exit code 0; see "The Good" #3 for what that claim does and
doesn't cover.*

## The pitch, then and now

Unchanged: *"a game programming language with Pythonic-Rust syntax and
unique memory management modes, targeting native executables via LLVM
IR."* This stage is the first since the version moved off `0.1.0` — the
work itself, per the five commits since `82be6e2`, stayed entirely in the
same two lanes the last several stages have: closing `projects/nova/`'s
remaining named gaps, and the process/documentation work of executing the
version decision the last review recommended rather than made.

---

## This stage (`82be6e2` → `4082b7b`, 2026-07-30)

Five commits: `5791bf0` (reassessment and version bump), `15c5ccc`
(version-relevant docs updates), `c07d13a` (Nova fixes/expansion),
`690562b` (cross-platform expansion), `4082b7b` (Nova expansion). In
substance, this closed every item the prior review's "Next steps" P1/P2
named:

- **The version decision was made and executed, not just recommended.**
  `Cargo.toml`, `readme.md`'s Versioning section, and `docs/
  conventions.md`'s own Versioning section all now read `0.2.0`,
  consistently. `CLAUDE.md` and `.clinerules/general.md` both gained the
  same new "Versioning" and "Things not to do" language (verified
  line-for-line identical in substance; a raw `diff` flags every line as
  changed only because of a pre-existing CRLF/LF mismatch between the two
  files, not a real content divergence).
- **`sound.star`'s leaked WAV handles, closed.** A new `Cpu.
  sound_channel_handles: [ptr; 16]` (confirmed present in `cpu.star`)
  tracks the one handle occupying each of the 16 addressable mixer
  channels and frees the outgoing one the instant a new one replaces it,
  or on `SSTOP`/reset.
- **`SMIX`/`SECHO`/`SREVERB`/`SFILTER` and `debugger.star` source-line
  breakpoints, both closed.** `projects/nova/NOTES.md`'s own opcode count
  moved from 167/180 to **171/180** (confirmed by direct read), and
  `cpu.star` gained `sound_channel_last_wav: List<Bytes>` backing the new
  DSP opcodes. `debugger.star` confirmed to have real `load_line_table`/
  `parse_break_location` functions and `break`/`clear` now accept `:<line>`
  — a genuine addition with no upstream Python-debugger behavior to match,
  since `nova_debugger.py`'s own breakpoints are address-only too.
- **The permanent structural caveats given a durable home.** `docs/
  design.md` gained a new "Known Permanent Caveats" section consolidating
  the "special guest" types / non-dynamic traits / warning-only
  stack-budget caveats that previously only lived in `current_status.md`
  (overwritten every cycle). Confirmed present and reads as described —
  **but this change is not committed**; see "The Bad" #1.
- **The Linux devbox came online and closed out `docs/
  cross_platform_scope.md`'s entire priority order except the
  deliberately-unstarted fonts gap.** Confirmed by direct read of that
  doc: `codegen/net.rs` (`tcp_connect`/`tcp_send`/`tcp_recv`/`tcp_close`),
  `codegen/os.rs` (`env_set`), `codegen/platform.rs` (the `par`/`swarm`
  thread pool, previously only IR-shape-tested), and SDL2/gamepad
  packaging are all now stated as devbox-link-verified, each with a
  concrete verification story (a real ELF binary built and run on the
  devbox, a `par` program run repeatedly under contention with no races,
  a real SDL2 window/pixel round-trip under `SDL_VIDEODRIVER=dummy`).
  `readme.md`'s "Platform Support" section matches this: only
  `font_load_system`/`font_load_ttf`/`draw_text_ttf` remain Windows-only
  by construction.

Net: every item the prior review hedged on ("recommended, not decided")
got executed, and every item it deferred as future work got closed. This
is the first stage in several where "Next steps" and "what actually
happened" match exactly, rather than partially rolling over.

---

## The Good

**1. The version decision stopped being deferred.** Three prior reviews
(`067`, `068`, `069`) all independently confirmed the gate's conditions
were met and all three routed the actual number/edit decision back to the
user rather than deciding it themselves, per `CLAUDE.md`'s own "Things not
to do." This stage is the first where that decision was actually made and
executed in the same cycle it was asked for — `0.2.0`, matching `069`'s
own recommendation, applied consistently across every load-bearing file
this review checked.

**2. The Linux-port claims are now backed by real execution, not just
plausible-looking IR.** Every item in `docs/cross_platform_scope.md`'s
priority order that this stage touched was verified by actually linking
and running a binary on the devbox — a `tcp_connect`/send/recv round trip
against a live Python echo server, a `par`-spawned 200-entity concurrent
job repeated at multiple worker counts with no races, a real SDL2 pixel
round-trip. This project's own history (`067`'s ten operand-count
documentation bugs, this stage's own catch of `069`'s Known Permanent
Caveats section going uncommitted) is that "looks right on paper" and "is
right" diverge here more often than a casual read would suggest, so an
actually-executed verification story is worth naming explicitly as a
strength rather than assumed by default.

**3. The full test suite was re-run fresh for this review and finished
clean.** `cargo +stable-x86_64-pc-windows-gnu test` was started before
this document was drafted (matching the practice `069`'s own P3 #7 asked
to keep) and completed with **exit code 0**. As `069` itself noted, this
session's own tooling truncates captured output from long-running test
binaries to the tail — the last 4 of the (many) top-level test binaries'
own "test result: ok. N passed; 0 failed" lines are directly visible in
this run's captured output, and the run's exit code, not a full
transcript, is the authoritative signal, same caveat as last cycle.

**4. The permanent-caveats consolidation did what it set out to do.**
`docs/design.md`'s new section (once committed — see "The Bad" #1) gives
the "special guest" types / non-dynamic traits / stack-budget caveats a
home that survives reassessment cycles instead of being rewritten from
`current_status.md`'s memory each time, which is exactly the gap `069`'s
own P2 #5 named.

---

## The Bad

**1. Two pieces of this cycle's own described work are not actually
committed.** `docs/design.md`'s "Known Permanent Caveats" section (P2 #5's
deliverable, per the committed `todo.md`'s own "Previous work" writeup)
and this cycle's `todo.md` P3 closeout both exist only in the working
tree, not in git history — `git show HEAD:docs/design.md` has none of the
new section. This is exactly the failure mode `CLAUDE.md`'s own
Versioning section warns about in spirit ("taking time out to do so
explicitly so no staleness grows in some hidden corner") applied to git
state rather than version strings: a `todo.md` entry that reads as
"Done." and describes a doc change in detail, sitting on top of a repo
where that change was never actually recorded. Nothing is lost — the
content is present and correct on disk — but the repo's committed history
currently doesn't match its own `todo.md`'s claims. Not fixed unilaterally
here: committing is a shared-state action this session's own operating
rules ask to confirm before taking, not something to fold into a
reassessment document. See "Next steps" P1 #1.

**2. `projects/nova/NOTES.md` has one stale version-gate reference.** Line
2143 still reads "the language-wide `0.1.0` gate," describing the
debugger's tooling-parity role in a gate that closed and moved to `0.2.0`
this same cycle. A `grep` for `0.2.0` across `NOTES.md` returns zero
matches — the file's ~3000 lines of detailed, otherwise-accurate history
were never touched by the version-sync pass that updated `readme.md`/
`CLAUDE.md`/`.clinerules`/`docs/conventions.md`. Small, mechanical, and
exactly the kind of drift `CLAUDE.md`'s versioning section exists to
prevent — it just missed a file outside the four the version-bump commit
explicitly listed.

**3. UART framed-mode protocol parsing remains the one deliberately
out-of-scope Nova gap.** `NOTES.md`'s own "Ideas for future work" names it
directly after listing `SMIX`/`SECHO`/`SREVERB`/`SFILTER` as closed —
same shape those four opcodes had before this stage (no opcode drives it,
so implementing it has no observable effect without also inventing a
reason to exercise it), not a regression, but this project's own recent
precedent (P2 #4 closing SMIX/etc. on request, with no reference to port
from) shows a "deliberately unimplemented" tag isn't permanent by default
here the way the Windows-only-fonts caveat is.

**4. Every prior stage's structural caveats still stand, unchanged.** The
Windows-only-fonts gap, the "special guest" type families (documented,
not unified in mechanism), non-dynamic monomorphized-only traits, and the
warning-only stack-budget check are all still true and still just
documented design choices, not regressions. None were the focus of this
stage.

---

## Goals vs. reality, honestly

Unlike the last three cycles, this one's central question isn't whether
the gate's conditions are met (`069` already re-derived that from first
principles) — it's whether the *decision* that followed was executed
faithfully. Checked directly against the current tree:

- **Version number.** `0.2.0` in `Cargo.toml` (`version = "0.2.0"`),
  `readme.md`'s Versioning section, and `docs/conventions.md`'s Versioning
  section — all three read, all three match. `CLAUDE.md`'s and
  `.clinerules/general.md`'s new Versioning/Things-not-to-do language
  matches between the two files (content-identical past a line-ending
  artifact). The one place version language went stale is `NOTES.md` (see
  "The Bad" #2) — a Nova-project-internal doc, not one of the four
  load-bearing files the bump commit targeted, but still a real instance
  of exactly the drift `CLAUDE.md` asks to watch for.
- **`readme.md`'s Versioning section prose itself.** Reads "There is no
  guarantee of stability or usability" replaced with gate-cleared language
  and a pointer to `changelog/069`'s condition-by-condition check — matches
  what `069`'s own "Next steps" P1 #2 asked for verbatim.
- **The prior review's P2 items (real, still-open gaps).** All three
  closed: the sound-handle leak (fixed, regression-tested per `todo.md`'s
  own writeup), `SMIX`/`SECHO`/`SREVERB`/`SFILTER` plus debugger line
  breakpoints (fixed, both confirmed present in source), and the permanent
  caveats given a durable doc home (present on disk, not yet committed).

This review found no case of a `todo.md` "Done." claim describing work
that isn't actually present in the tree — every item checked against real
files. The one process gap is narrower than that: work that's real and
correct on disk but not yet handed to git, which is a different failure
mode than a false "Done." marker (`069`'s own P0 explicitly checked for
and ruled out that latter case; this review's version of the same check
comes out the same way, with the added git-state caveat above).

---

## Next steps, prioritized

**P0 — Nothing broken.** Full `cargo +stable-x86_64-pc-windows-gnu test`
re-run this cycle, exit code 0, no failures in the captured tail output
(same truncation caveat as `069`; the exit code is the authoritative
signal). No false "Done." markers found in this cycle's `todo.md`.

**P1 — Small, concrete, and worth doing before new feature work.**
1. **Decide whether to commit the two outstanding working-tree changes**
   (`docs/design.md`'s "Known Permanent Caveats" section, and this cycle's
   `todo.md` P3 closeout) — both are real, correct, already-described-as-
   done work sitting uncommitted. This is a call for the user per this
   session's own git safety rules (committing is not something to do
   unprompted), not something this document decides.
2. **Fix `projects/nova/NOTES.md`'s stale `0.1.0` reference** (line 2143,
   "the language-wide `0.1.0` gate") to reflect the `0.2.0` move — a
   one-line, mechanical doc fix, small enough to be the natural first pick
   from a freshly seeded `todo.md`.

**P2 — Real, standing items, none urgent.**
3. **UART framed-mode protocol parsing** (see "The Bad" #3) — carried
   forward for visibility, matching how `SMIX`/etc. were tracked before
   this stage closed them. Not an active ask; no opcode currently drives
   it, so there is nothing to observably test yet without also deciding to
   invent that opcode surface, which is a bigger, separate design
   question.
4. **The permanent structural caveats** (Windows-only fonts, "special
   guest" types, non-dynamic traits, warning-only stack-budget check) —
   not gaps to close, a standing line item so a future version decision
   (a `1.0.0` push) doesn't have to rediscover them. Now has a durable home
   in `docs/design.md` once P1 #1 lands it in git.

**P3 — Keep the cadence honest.**
5. This cycle was triggered by full `todo.md` completion (including the
   P3 items themselves, closed out this cycle specifically because they
   were process notes rather than concrete asks) and a direct user request
   for the reassessment, arriving back to back. Worth naming again: the
   automatic trigger and a direct ask converging is the system working as
   intended, not a coincidence to explain away.
6. Continue starting the full `cargo test` run before drafting this
   document rather than concurrently with it — three reviews running have
   now made this adjustment; keep doing it.
