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
3. **Done, then superseded (see "Since this reseed" below).** Originally
   closed as "still genuinely out of scope" with a regression test pinning
   down *blocking*-mode `tcp_recv`'s no-timeout behavior
   (`runtime_tcp_recv_on_idle_open_connection_blocks_forever_end_to_end`,
   `tests/frontend_networking.rs`: a real `TcpListener` peer accepts the
   connection, sends nothing, doesn't close it, and the test polls
   `Child::try_wait` for 1.5s confirming the compiled binary is still
   blocked). That test still exists and still passes unchanged — blocking
   mode (no `tcp_set_nonblocking` call) is still genuinely blocking, by
   design. What's no longer true: "no code change... adding one is a real
   feature, not a test-writing task" — a real feature request landed this
   cycle and added exactly that non-blocking mode as opt-in. See "Since
   this reseed" below for the actual implementation.
8. **Done.** New `tests/frontend_sdl_bulk_pixel_blit.rs`, 29 tests: arg-type/
   arity checks for all five builtins (including the easy `Bytes`-vs-`str`
   mixup `texture_update`/`draw_pixels` share with `file_write_bytes`), a
   `par`/`swarm` ban-list rejection test (mirroring the existing SDL-hazard
   tests), two structural null-handle-abort codegen checks, and six real
   `SDL_VIDEODRIVER=dummy` runtime round-trips covering both the one-shot
   (`draw_pixels`) and cached-handle (`texture_create`/`update`/`draw`)
   forms — including a row-major-layout check (2x1 buffer, distinct colors
   per pixel, catches a column/row mixup a uniform-fill test can't), a
   destination-offset-vs-background-isolation check for both forms, and a
   handle-reuse check (`texture_update` called twice on the same handle,
   confirming the second draw shows the *new* upload rather than stale data
   from the first). Also found and fixed a bug in the two structural codegen
   tests themselves along the way: the abort message text is a global
   constant defined outside the function body, so asserting it against
   `extract_fn_body`'s slice always failed — moved those two assertions to
   check the whole-module `ir` instead (matches `frontend_networking.rs`'s
   own `codegen_tcp_close_aborts_on_null_handle`, which only checks
   fn-body-local control flow, not message text). Full `cargo test` (76
   binaries) reconfirmed clean after both additions.
4. **Done.** The permanent structural caveats (Windows-only fonts, "special guest"
   types unified in docs not mechanism, non-dynamic monomorphized-only
   traits, warning-only stack-budget check) — not gaps to close, a
   standing line item with a durable home in `docs/design.md`'s "Known
   Permanent Caveats" section.
5. **Done.** `docs/requests.md`'s six niceties (multi-line/block comments, numeric
   digit separators, `if let`/`while let` pattern binding, inclusive/
   stepped `for` ranges, multi-line string literals, default parameter
   values) are a real backlog now, distinct from the Nova-heavy cadence of
   recent cycles. None blocking. The two most self-contained — numeric
   digit separators (lexer-only, no type-system implications) and
   multi-line block comments — are the natural first pick if a future
   cycle wants compiler-side work instead of another `projects/nova/`
   round.

**P3: Keep the cadence honest.**
6. **Done.** This cycle's trigger fired off a `todo.md` whose only remaining open
   items lived in a new `U0` tier, not the usual P0-P3 board — the first
   time that's happened. `CLAUDE.md`'s trigger language ("every item in
   `todo.md` is marked Done... no open P0-P3 items remain") read naturally
   as covering any tier, and held without needing to special-case `U0`. No
   convention change needed; just naming that the broader reading was
   tested for the first time.
7. **Done.** Continue starting the full `cargo test` run before drafting
   `current_status.md` rather than concurrently with it — four reviews
   running have now made this adjustment; keep doing it.

# Previous work

**Since this reseed** (not from the seeded board above — a direct feature
request, not a planned P-item, and the pick-up of P2 #5's own "natural
first pick" pointer): implemented all six of `docs/requests.md`'s scoped
language niceties in one pass, each with its own new test file. Three are
pure `src/lexer.rs` changes reusing the existing `TokenKind::Str` (no
parser/checker/codegen involvement at all): `#* ... *#` balanced/nesting
block comments (`Lexer::skip_block_comment`, called from both
`scan_line_content` and `handle_line_start`), `_` digit separators in
decimal/hex/float/exponent literals (`Lexer::scan_digit_run`/
`strip_digit_separators`), and `"""..."""` multi-line string literals
(`Lexer::scan_triple_string`, an embedded raw newline is ordinary content
instead of the plain form's "unterminated string literal" error). Two
desugar entirely at parse time into existing AST shapes: `if let`/`while
let` (`Parser::parse_if_let_stmt`/`parse_while_let_stmt`, straight into
`Expr::Match`/`Stmt::While`, reusing `Parser::parse_pattern` — widened from
private to `pub(super)` — and `Checker::check_match_exhaustive` for free,
no new AST node or checker rule), and inclusive/stepped `for` ranges (a new
`DotDotEq` token for `..=`, plus a `step <n>` soft keyword — checked as a
plain identifier spelled `step`, deliberately *not* added to
`crate::lexer::keyword_or_ident`, since `projects/nova/cpu.star` already
declares a real `fn step(mut self):` method that would otherwise break;
`n` is a parse-time literal so `Codegen::emit_for_stmt` can pick its
`icmp` predicate once at codegen time from the step's known sign rather
than a runtime check every iteration — `Stmt::For`/`TypedStmt::For` gained
`inclusive`/`step` fields threaded through every call site that names all
of a `For`'s fields explicitly, not just `..`-tolerant ones). The sixth,
default parameter values, is the one with real checker-level machinery:
`Param` gained a `default: Option<Expr>` (parser-enforced to trail every
non-defaulted parameter), and two new `Checker` tables
(`fn_param_meta`/`method_param_meta`) let a new `resolve_call_arg_exprs` —
the call-site counterpart of the pre-existing `resolve_ctor_arg_exprs`
struct/enum-construction resolver — match named arguments by name and
splice in a still-missing trailing default *before* any arity/type check
runs, for a plain free-function call or a `recv.method(..)` call with a
simple (identifier/`self`) receiver; a compound receiver, a closure call,
and a generic-function call all keep their previous positional-only
behavior (documented, not silently degraded) since none has declared-name
metadata available without either double-evaluating a sub-expression or
not existing at all. Four new test files (`tests/frontend_lexer_niceties.rs`
23 tests, `tests/frontend_for_loop_ranges.rs` 19, `tests/
frontend_if_let_while_let.rs` 16, `tests/frontend_default_params.rs` 29 —
87 new tests total). Found one real regression along the way: `tests/
frontend_inline_if_tuple_index_named_ctor_args.rs`'s own
`rejects_named_arguments_on_ordinary_call` pinned down the *old*
restriction this feature deliberately lifts (`add(b = 1, a = 2)` used to
be a checker error; it's exactly the shape #6 asks to support) -- flipped
to `accepts_named_arguments_on_ordinary_call`, asserting it now
type-checks instead. A full-repo grep for the old rejection message
confirmed no other test depended on it. Full `cargo test --no-fail-fast`
(the `--no-fail-fast` flag mattering this time: a first full run stopped
after 42 of the suite's ~80-odd binaries at exactly this one failure,
so the "no other regressions" claim needed a real complete run, not an
assumption from a fail-fast-truncated one) reconfirmed clean afterward.
`docs/language_reference.md` and `docs/requests.md` updated to match
(every entry in the latter marked "Done." with its mechanism and test
file).

**Since this reseed** (not from the seeded board above — a direct feature
request, not a planned P-item): added non-blocking TCP mode to the
compiler and wired it into `projects/nova`'s UART host bridge.
`src/codegen/net.rs` gained `tcp_set_nonblocking(handle: ptr, enabled: bool)
-> bool` (`ioctlsocket`/`WSAGetLastError` on Windows, a real
`fcntl(F_GETFL)`/`fcntl(F_SETFL)` read-modify-write pair plus
`__errno_location` on Linux), and `tcp_recv` now returns a null `ptr`
(instead of `""`) specifically when a non-blocking socket's `recv()` fails
with `WSAEWOULDBLOCK`/`EAGAIN` — distinguishable from a real closed
connection (still `""`) via the existing `is_null` builtin, which had to be
widened to also accept a `str` argument (previously `ptr`-only) since both
share the identical `i8*` runtime representation and `tcp_recv` is
declared `Str`. Blocking-mode `tcp_recv` (the default, no
`tcp_set_nonblocking` call) is bit-for-bit unchanged — confirmed by the
pre-existing `runtime_tcp_recv_on_idle_open_connection_blocks_forever_
end_to_end` test (P2 #3, above) still passing untouched. Registered
through every builtin touchpoint (`types/mod.rs`, `types/expr.rs`,
`codegen/expr.rs`); 14 new tests added to `tests/frontend_networking.rs`
(checker arity/type checks, structural null-handle-abort and would-block
codegen checks for both targets, and real runtime round-trips: returns
true on a live socket, aborts on a null handle, returns null immediately
on an idle-but-open connection instead of blocking, still returns `""` on
a genuinely closed peer, and eventually returns real data once the peer
sends it). Full `cargo test` (76 binaries) reconfirmed clean.

On the `projects/nova` side: `uart.star::write_data` (the `SEROUT`
handler) now also queues every transmitted byte into a new `tx_queue` FIFO
(`queue_tx_byte`/`drain_tx_byte`, tuple return mirroring
`keyboard.star::pop_key`), additive alongside the pre-existing stdout
`print(chr(..))` path. New `projects/nova/uart_tcp_bridge.star` is the
TCP-client sibling of `uart_bridge.star` (this language has no
`listen`/`accept` builtins, so it dials out rather than accepting inbound
connections): same `Cpu`/`run_burst` shape, but polls a non-blocking
`tcp_recv` instead of blocking on `read_line()`, and drains `tx_queue` to
`tcp_send` every transmitted byte. Hand-verified against a real
`System.Net.Sockets.TcpListener` peer (not part of the automated suite —
no way to drive a real inbound TCP connection from inside a headless
`.star` test); the first run caught two real bugs before this landed: a
missing per-byte `run_burst` in the RX-injection loop (raw mode's
single-register `host_push_rx` silently drops all but the last byte of a
multi-byte poll without one), and a smoke-test design mistake (a `0x00`
sentinel byte is indistinguishable from a true EOF through a `str`-typed
`tcp_recv`, since `str` truncates at the first NUL) — fixed by switching
the smoke test to `0xFF` and documenting the `str`/NUL limitation in the
bridge's own header comment rather than trying to work around it (a
pre-existing, already-documented gap, not new here). Also fixed in
passing: `uart_bridge.star`'s own usage comment was missing the `-L
sdl/lib/x64 -l SDL2` flags `cpu_sound.star`'s transitive SDL_mixer
dependency actually requires to link — confirmed by trying the old command
line and watching it fail with undefined `SDL_Init`/etc. symbols. See
`projects/nova/NOTES.md`'s "UART" section (new "TCP transport"
subsection) for the full design and test-by-test detail.

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

P2 #8: Closed the gap the paragraph above flagged — added
`tests/frontend_sdl_bulk_pixel_blit.rs` (29 tests: arg-type/arity checks,
`par`/`swarm` ban-list rejection, two structural null-handle-abort codegen
checks, and six real `SDL_VIDEODRIVER=dummy` runtime round-trips for both
the one-shot `draw_pixels` and cached-handle `texture_*` forms). Along the
way, fixed a bug in the two structural codegen tests' own assertions (the
abort message text lives in a global constant outside the function body,
so `extract_fn_body`-scoped assertions on it always failed regardless of
the codegen's correctness) before either test was ever committed. See
P2 #8's own entry above for the fuller test-by-test breakdown.

P2 #3: Confirmed and pinned down as a real regression test, not just
prose — `runtime_tcp_recv_on_idle_open_connection_blocks_forever_end_to_end`
(`tests/frontend_networking.rs`) spawns a real listener that accepts the
connection and then stays silent and open, then polls the compiled Star
binary for 1.5s confirming `tcp_recv` is still blocked, before killing it.
No code change — the no-timeout limitation is real and still out of scope.

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
