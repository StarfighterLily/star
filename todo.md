# Star Compiler — Next Steps

Seeded from `current_status.md`'s "Next steps, prioritized" section
(reviewed at commit `45382cc`, 2026-07-29). This reassessment's headline
finding: unlike the last two cycles, nothing in the incoming `todo.md`
needed correcting — every item held up under a real re-verification (full
`cargo +stable-x86_64-pc-windows-gnu test` re-run, not just trusted). See
`current_status.md`'s own "Next steps, prioritized" P0 note for why that's
worth recording rather than skipping straight to new work.

**P0: Nothing to fix — see `current_status.md` for why this cycle's review
didn't find one.**

**P1: The two most concrete, already-scoped gaps.**
1. **Root-cause the repeated-f-string-call corruption bug.** Found this
   cycle while building `projects/nova/disasm.star` (see
   `projects/nova/NOTES.md`'s "Seven Star compiler bugs found and fixed",
   the note right after bug #7): calling a function that itself
   materializes its return value via an f-string, more than once in the
   same running program, corrupts the result — `hex_word(0x1234)` came back
   `"444"` instead of `"1234"` in the minimal repro; a wrapper function
   returned correctly on its first call and wrong on its second/third. This
   is **not** the same bug as #6/#7 (both already fixed this cycle,
   untagged `FStr`/`concat` codegen returns) — it reproduces after those
   fixes, and even when the *inner* function is `concat`-based rather than
   f-string-based, as long as an f-string appears somewhere in the call
   chain more than once. Not Nova-specific — any Star project could hit
   this. Recorded hypothesis (unconfirmed): a `star_rc_alloc`-backed buffer
   from a first f-string call isn't retained/protected correctly before a
   later call reuses its address. Start by reading
   `Codegen::emit_expr`'s `TypedExpr::FStr` arm (`src/codegen/expr.rs`)
   and its RC-tracking (`push_scope`/`pop_scope`/`track_owned`/retain-
   release calls) directly, the same way bugs #6/#7 were actually
   diagnosed (reading the codegen, not guessing) rather than assumed.
2. **An actual assembler** for `projects/nova`, so a `.bin` can be produced
   from Star-authored (or at least locally-authored) source instead of only
   loaded from the upstream Python toolchain's output. Now the single
   biggest named-tooling gap left in `readme.md`'s versioning gate — the
   disassembler this cycle built (`projects/nova/disasm.star`, see
   `projects/nova/NOTES.md`'s "Disassembler" section) gives an assembler's
   output somewhere to be checked immediately (assemble, then disassemble,
   then diff against the source), which wasn't true before this cycle.

**P2: Bigger, still-unscoped tooling gaps.**
3. A debugger and GUI+controls parity with the Python reference's own
   tooling — both still genuinely unstarted, both still only named
   qualitatively by `readme.md`'s versioning gate. Lower priority than P1
   above: a debugger benefits from an assembler existing first
   (source-line breakpoints need something to map back to), and
   "GUI+controls parity" needs its own scoping pass (what does the Python
   reference's own GUI actually offer beyond what `main.star`'s SDL window
   already does?) before it's actionable rather than aspirational.

**P3: Keep the cadence honest.**
4. Nothing structural to change in the reassessment mechanism this time —
   it fired correctly, the full test suite ran *before* finalizing
   `current_status.md` rather than concurrently with it, and it caught a
   real (if minor) would-be documentation error before shipping (a
   suspected doc gap in `docs/nova16_instruction_reference.md`'s "Special
   Registers" section that turned out to be a `grep`-pattern artifact, not
   a real gap — corrected before it was written down anywhere permanent).
   Carry the same discipline forward.

# Previous work

See `changelog/067_2026-07-29_45382cc_todo.md` and
`changelog/067_2026-07-29_45382cc_current_status.md` for the full history
up to and including this cycle (sound synthesis + UART host bridge landing
for real, `.clinerules` sync, the versioning-gate adequacy judgment, the
Nova disassembler, two genuine Star compiler bugs found and fixed via that
disassembler work, ten operand-count documentation bugs found and fixed in
`docs/nova16_instruction_reference.md`, and `projects/nova/NOTES.md`'s
reframing from "language exercise" to "de facto Nova-16 emulator") —
archived per the reassessment protocol before this file was reseeded from
the fresh `current_status.md`'s "Next steps" section above.

projects/nova/disasm.star (new): a real disassembler — decodes a compiled
`.bin` back into readable Nova-16 assembly text, independent of `Cpu`/
`cpu.star` entirely (no SDL2 link dependency, unlike every other Nova build
target). Verified against four independently-produced `.bin` files
(`write_width_test.bin`, `bcd_width_test.bin`, `push_pop_width_test.bin`,
and `uart_integration_test.bin`, the last copied verbatim from the upstream
Python repo), every decoded mnemonic/operand/byte-length matching the
source `.asm` exactly.

src/codegen/expr.rs: `TypedExpr::FStr`'s codegen arm now returns a tagged
`"i8* <reg>"` value instead of a bare untagged register — fixes a real bug
where an f-string used as a bare trailing `if`/`else` value (no explicit
`return`) failed to compile with a generic "function must end in a
value-producing expression" error, because
`Codegen::emit_trailing_if_value`'s `rsplit_once(' ')` type-recovery had no
space to split on. Found via `projects/nova/disasm.star`'s
`format_offset` helper.
src/codegen/builtins.rs: `Codegen::emit_str_concat` had the identical bug
(bare untagged return) and got the identical one-line fix. Its sibling
`Codegen::emit_str_join` was already correct.
Both fixes verified against a minimal repro each and the full
`cargo +stable-x86_64-pc-windows-gnu test` suite (72/72 binaries, 0 failed,
twice — once per fix).

docs/nova16_instruction_reference.md: fixed ten real operand-count errors
found by cross-checking every documented opcode against `cpu.star`'s actual
`decode_operands(N)` call sites while building the disassembler above:
SFLIP (doc said 2, actually 1), KEYCLEAR/SED/CLD/CLA (doc said 1, actually
0 -- all four handled with no operand decode at all), and
BCDA/BCDS/BCDCMP/BCDADD/BCDSUB (doc said 1, actually 2 -- the most
consequential, since a wrong operand count desyncs every following byte in
a disassembled stream).

projects/nova/NOTES.md: added a framing note at the top of the file
declaring the shift from "language exercise" to "de facto Nova-16
emulator" as this project's stated goal going forward; added a
"Disassembler" section documenting `disasm.star`, the ten doc fixes above,
and the two confirmed-intentional same-byte opcode aliases (SAL/SHL,
INTGR/TRUNC) found while building it; renamed "Five Star compiler bugs
found and fixed" to "Seven" and added the two fixed bugs above plus a
write-up of a third, related bug that was found but NOT fixed (repeated
f-string-producing-function calls can corrupt output -- see todo.md P1 #1
above); fixed several stale claims found along the way (the "Sound" bullet
under "What's implemented" still called SPLAY/SSTOP/STRIG "register-model
stubs" a stage after they became real; the "Testing" section's own
`tests/run_bin.star` build instructions still said "no SDL needed" a stage
after that file's own header comment was corrected to say the opposite;
`sound.star`/`uart_bridge.star` were missing from the "Contents" index
entirely); updated "What's implemented"/"What's not implemented"/"Ideas for
future work" to move the disassembler from not-started to done and
correct the opcode count from an approximate "roughly 140" to a verified
167 (of 180 documented, the 13-opcode gap being exactly the still-
unimplemented set already listed under "What's not implemented").
current_status.md / todo.md: this reassessment.
