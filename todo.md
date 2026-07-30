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
2. Once a number is chosen: update `readme.md`'s Versioning section,
   `Cargo.toml`'s `version` field, and `docs/conventions.md`'s own
   "Versioning" section together in the same change (the last of these
   currently still says "`0.1.0`, explicitly no stability guarantee" and
   would otherwise immediately contradict the new `readme.md` text).

**P2: Real, still-open gaps — none block the version question above,
since the gate never named them.**
3. `sound.star`'s leaked WAV handles — the one remaining named audio
   simplification (see `current_status.md` "The Bad" #2).
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
P1 #1: Bumped version to an honest `0.2.0` across `cargo.toml` and `readme.md`, 
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
