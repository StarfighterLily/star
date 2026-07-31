# Star Compiler — Next Steps

Seeded from `current_status.md`'s "Next steps, prioritized" section
(reviewed at commit `fbec0ec`, 2026-07-31). This cycle's headline finding:
every item `070` carried forward closed cleanly and re-verified directly
(two new test binaries run for real — `uart_framed_test.exe` 10/10,
rebuilt `mouse_interrupt_test.exe` 5/5 — not just re-read from `todo.md`'s
own prose), plus this cycle's own new `U0` #1 (`docs/requests.md`) landed
with its claims independently re-derived against current lexer/parser
source rather than taken on faith. The open items below are two small,
same-commit doc-staleness spots this review found in `NOTES.md`, not
another round of deferred decisions — see `current_status.md`'s "The Bad"
#1-2 for the detail and "Goals vs. reality, honestly" for the full
verification.

**P0: Nothing to fix.** Full `cargo +stable-x86_64-pc-windows-gnu test`
re-run this cycle, exit code 0 (confirmed by a full-output grep for
`FAILED`/`error[`, not just the tail). No false "Done." markers found.

**P1: Small, concrete, worth doing before new feature work.**
1. **Done.** Simple one-line replacement with pointer to relevant info.
2. **Done.** Trimmed the whole explanatory parenthetical and provided
   a simple "180+" count; accurate, and leaves headroom for expansion.

**P2: Real, standing items — none urgent, none blocking.**
3. UART TCP transport remains out of scope — `net.rs`'s `tcp_recv` has no
   non-blocking/timeout mode, so a TCP-backed bridge would freeze waiting
   on an idle peer. Not a regression; carried forward for visibility.
8. `draw_pixels`/`texture_create`/`texture_update`/`texture_draw`/
   `texture_destroy` (`src/codegen/sdl.rs`, added since this reseed — see
   "Previous work" below) have no dedicated `tests/frontend_*.rs` file of
   their own yet, unlike every other SDL builtin in this compiler. Existing
   SDL test files didn't regress, but that's coverage-by-absence, not
   coverage — the natural next step is a `frontend_sdl_bulk_pixel_blit.rs`
   (or similar) covering arg-type checks, the `par`/`swarm` ban, and a real
   `SDL_VIDEODRIVER=dummy` round-trip for both the one-shot and
   cached-handle forms.
4. The permanent structural caveats (Windows-only fonts, "special guest"
   types unified in docs not mechanism, non-dynamic monomorphized-only
   traits, warning-only stack-budget check) — not gaps to close, a
   standing line item with a durable home in `docs/design.md`'s "Known
   Permanent Caveats" section.
5. `docs/requests.md`'s six niceties (multi-line/block comments, numeric
   digit separators, `if let`/`while let` pattern binding, inclusive/
   stepped `for` ranges, multi-line string literals, default parameter
   values) are a real backlog now, distinct from the Nova-heavy cadence of
   recent cycles. None blocking. The two most self-contained — numeric
   digit separators (lexer-only, no type-system implications) and
   multi-line block comments — are the natural first pick if a future
   cycle wants compiler-side work instead of another `projects/nova/`
   round.

**P3: Keep the cadence honest.**
6. This cycle's trigger fired off a `todo.md` whose only remaining open
   items lived in a new `U0` tier, not the usual P0-P3 board — the first
   time that's happened. `CLAUDE.md`'s trigger language ("every item in
   `todo.md` is marked Done... no open P0-P3 items remain") read naturally
   as covering any tier, and held without needing to special-case `U0`. No
   convention change needed; just naming that the broader reading was
   tested for the first time.
7. Continue starting the full `cargo test` run before drafting
   `current_status.md` rather than concurrently with it — four reviews
   running have now made this adjustment; keep doing it.

# Previous work

**Since this reseed** (not from the seeded board above — real compiler work
that came up live, driven by a `projects/nova/` performance investigation,
not a planned P-item): added two new SDL builtin families to the compiler
itself — `draw_pixels(handle, pixels: Bytes, width, height, dst_x, dst_y,
dst_w, dst_h)` and the cached-handle sibling `texture_create`/
`texture_update`/`texture_draw`/`texture_destroy` (`src/codegen/sdl.rs`).
Both replace a per-pixel `draw_rect` render-loop pattern (up to 65,536 real
`SDL_SetRenderDrawColor`+`SDL_RenderFillRect` calls a frame — confirmed via
direct measurement to be the actual bottleneck behind a Nova-16
pixel-fill benchmark barely outrunning a Python reference) with a single
bulk-texture-upload call. The two families share internal helpers
(`emit_texture_create_raw`/`emit_texture_update_raw`) so their actual
`SDL_CreateTexture`/`SDL_UpdateTexture` shape can't drift apart, and reuse
`crate::codegen::system_font`'s existing `emit_build_rect` (widened from
private to `pub(super)`) rather than re-deriving the `SDL_Rect`-building
dance a third time. Registered through all five of this compiler's builtin
touchpoints (`types/mod.rs`'s return-type table, `types/expr.rs`'s
arg-type checks, `types/par_analysis.rs`'s `par`/`swarm` ban list,
`codegen/expr.rs`'s dispatch, and the `sdl.rs` implementation itself). Full
`cargo test` suite (75 binaries) re-verified clean, twice, after these
changes and again after `main.star`'s own subsequent frame-pacing fixes —
no regressions in the existing SDL/font/audio/snake test files, though see
P2 #8 above for the real gap this left (no dedicated test file of the new
builtins' own). See `projects/nova/NOTES.md`'s new "Render-loop performance
and frame pacing" section for the full investigation this came out of
(four distinct findings, two of them genuine bugs introduced by this
round's own follow-on tuning) — the Nova-side half of that work
(`main.star`'s `STEPS_PER_FRAME`/`STEP_TIME_BUDGET_MS` frame-pacing model)
lives entirely in that project and doesn't touch the compiler.

P1 #1: Corrected the stale UART frame mode claims and directed the reader
to the file and line number (`uart.star`:13) of the comment section describing
the implementation.

This cycle (seeded from `070`'s "Next steps", closed before this reseed):
committed `docs/design.md`'s already-written "Known Permanent Caveats"
section alongside the reassessment itself, fixed `NOTES.md`'s stale
`0.1.0` version-gate reference, implemented UART framed-mode protocol
parsing (`SERCTRL` bit 2 gates a real frame parser; new opcode `SERFSTAT`
`0xB4`, checked against every opcode table before allocating the number to
avoid the reserved-but-unimplemented `0xA6`-`0xAB` debugger pseudo-opcodes)
with a new checked-in test (`tests/asm/uart_framed_test.asm` +
`tests/uart_framed_test.star`, 10/10 checks passing, independently
re-run by this cycle's own reassessment), found and fixed a real silent
regression in `mouse_interrupt_test.star` (stale `Cpu` struct literal and
missing build flags/imports — the file couldn't even rebuild before the
fix; rebuilt `.exe` now passes 5/5, also independently re-run), and
populated a new `docs/requests.md` with six scoped-but-unimplemented
language niceties, each checked against `src/lexer.rs`/`src/parser/`
rather than guessed. See `changelog/071_2026-07-31_fbec0ec_todo.md` and
`changelog/071_2026-07-31_fbec0ec_current_status.md` for the full
before-reseed state and this cycle's own detailed write-up.

See `changelog/070_2026-07-30_4082b7b_todo.md` and
`changelog/070_2026-07-30_4082b7b_current_status.md` for the cycle before
that (the version decision `069` recommended finally made and executed
(`0.2.0` across `Cargo.toml`/`readme.md`/`docs/conventions.md`/
`CLAUDE.md`/`.clinerules`), `sound.star`'s leaked WAV handles fixed,
`SMIX`/`SECHO`/`SREVERB`/`SFILTER` plus `debugger.star` source-line
breakpoints implemented from scratch, the permanent structural caveats
consolidated into a new `docs/design.md` section, and a real Linux devbox
coming online to devbox-link-verify `codegen/net.rs`/`os.rs`/`platform.rs`
and SDL2/gamepad packaging) — archived per the reassessment protocol.

See `changelog/069_2026-07-30_82be6e2_todo.md` and
`changelog/069_2026-07-30_82be6e2_current_status.md` for the cycle before
that (a checked-in `debugger.star` regression test, F5-F8 hotkey
verification closed for real, a concrete "what does 'Nova complete' mean"
checklist built and checked against `NOTES.md`, the `clang`
large-aggregate-reassignment compiler bug root-caused and fixed, a true
per-8-channel sound voice model and real pink-noise filter, and
`cpu.star`'s opcode handlers split across 11 files by group) — also
archived under the same reassessment protocol.

See `changelog/068_2026-07-30_cacd569_todo.md` and
`changelog/068_2026-07-30_cacd569_current_status.md` for the cycle before
that (the repeated-f-string-call corruption bug root-caused and fixed, a
real assembler for `projects/nova`, and a real debugger plus GUI+controls
parity, a genuine Cpu SP/FP reset-value port bug found via the debugger's
first real use, and the `clang` build-time pathology first surfaced and
worked around) — also archived under the same reassessment protocol.
