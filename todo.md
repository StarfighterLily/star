# Star Compiler — Next Steps

**P0: Protect what Nova's stress-testing has already proven fragile.**
1. **Done.** Generalized the `MOV`-only write-width fix
   (`Cpu::write_width_for`) to every opcode handler in `cpu.star` that
   writes a result back to a memory destination — ~30 call sites across
   arithmetic/bitwise/BCD/math-library/string-conversion. Also found and
   fixed two more bugs the same live-reference-verification pass turned up:
   PUSH/POP always used a fixed 16-bit stack slot instead of the
   reference's actual operand-kind-dependent width, and BCDA/BCDS/BCDADD/
   BCDSUB checked their carry/borrow flag against the *masked* result
   instead of the raw pre-mask value (a previous NOTES.md entry had
   mis-documented this as intentional reference behavior). See
   `projects/nova/NOTES.md`'s "Generalizing the write-width fix" section
   for the full write-up, verification against the live Python reference,
   and what this means for the upstream Python emulator.
2. **Done.** Added `Checker::check_stack_budget` (`src/types/stack_budget.rs`):
   a `star check`-time (and `star build`-time) heuristic warning, run once a
   module has type-checked cleanly, that sums each function/method's own
   `let`-bound aggregate footprint plus the heaviest reachable static call
   chain's footprint on top of it, and warns (never errors — a new
   `Checker`/`Compilation`/`IrVerification`-style `warnings` side channel,
   entirely separate from the fatal `errors` path) at any function whose own
   footprint is non-zero and whose combined total reaches 1MiB — the exact
   "Windows' 1MiB linker-default stack overflowed" incident class
   `DEFAULT_STACK_SIZE_BYTES` already fixed after the fact for `star build`'s
   linked executables, now caught at compile time instead. Deliberately a
   heuristic (recomputes approximate byte sizes from the checker's own typed
   struct/enum field lists rather than chasing `Codegen::type_size`'s exact
   LLVM alignment/padding, and only traces a call graph edge it can resolve
   statically — a call through a closure/function value is a silent,
   accepted false-negative gap); recursion (direct or mutual) is bounded by a
   per-DFS-path visited set rather than memoized globally, so it can't hang
   the compiler on a recursive program. 11 new tests in
   `tests/frontend_stack_budget_warning.rs` cover: the core "neither function
   alone crosses budget, but the caller's combined total does" incident
   shape (and that only the true combination point, not the innocent callee,
   is named); method-call-graph resolution; nested-struct field summation;
   heap-backed `List<T>` never being flagged; direct and mutual recursion
   terminating promptly instead of hanging; and the finding's severity
   staying `Warning` (never blocking a clean compile).

**P1: Close the distance between "seam exists" and "port is actually cheap."**
 3. **Done.** Scoped every Windows-only codegen surface, not just text
   rendering: `docs/cross_platform_scope.md` (new) inventories text
   rendering (`system_font.rs`, GDI — hard, `stb_truetype` is the cheapest
   realistic vendor option, a real feature addition), networking (`net.rs`,
   Winsock — cheap, BSD sockets are Winsock's own ancestor API, needs one
   `Target::LinuxGnu` match arm per `emit_*` method plus a socket-handle
   sentinel change), environment variables (`os.rs`'s `env_set` —
   cheapest, a single match arm swapping `_putenv_s` for `setenv`), and
   SDL2 windowing/audio/gamepad (not a codegen gap at all — SDL2 already
   ships Linux builds, the gap is that this repo only vendors a Windows
   build). `platform.rs`'s own module doc comment, `net.rs`'s, and
   `os.rs`'s now each carry a pointer to the relevant section instead of
   `platform.rs` alone flagging fonts as the one uncovered thing.
   `readme.md`'s "Platform Support" section is rewritten to list all three
   Windows-only surfaces (not just fonts+SDL) and states plainly that
   cross-platform Linux support is a genuinely intended goal — gated on
   getting a real Linux devbox running, since every existing
   `--target=linux` claim in this repo is currently IR-shape-verified only
   (inspected by eye, never actually linked or run by a real Linux
   `clang`/`ld`). No code changes — this item was explicitly scope-first,
   matching the original "don't necessarily build yet" framing.
4. **Done.** Nova's audio synthesis and UART needs will be met next; these
   are new language additions that are genuinely desirable for games of all kinds:
   multiplayer support depends on access to a network somehow, stdin is essential
   for text-based games, and audio synthesis (not just audio playback) is crucial
   to any retrocomputer project or chiptune-bearing aesthetic. Getting these in
   is a win across the board.

**P2: Reduce the adoption barrier before this is shown to a second person.**
5. **Done.** Added `star lsp` (`src/lsp.rs`, new): a minimal Language
   Server Protocol server over stdio, exactly the scope this item asked for
   -- `textDocument/publishDiagnostics` on `didOpen`/`didSave`, re-running
   the identical `Driver::compile` pipeline `star check` already uses, no
   completions/hover/go-to-definition. Hand-rolled `Content-Length`-framed
   JSON-RPC over `serde_json` (the one new dependency this needed) rather
   than pulling in an LSP framework crate, since the message surface is
   deliberately tiny: `initialize`/`shutdown`/`exit`, `didOpen`/`didSave`/
   `didClose` (`didChange` accepted but a no-op -- diagnostics re-run from
   disk on save/open, not per-keystroke, so there's no client buffer to
   track), and a JSON-RPC "method not found" error for anything else so an
   unrecognized request doesn't hang a client waiting on a response. A
   diagnostic whose span originated inside an `import`ed file (rather than
   the open document) is still surfaced -- anchored at the top of the file
   with the origin file named in the message text, since
   `crate::modules::resolve` doesn't retain an imported file's canonical
   path today (a natural, additive follow-up). 17 new tests in `src/lsp.rs`
   cover message framing round-tripping, percent-decoding/drive-letter
   handling in `file://` URI-to-path conversion, UTF-16-code-unit position
   conversion (LSP's column unit regardless of this server's own UTF-8
   internals, verified against a real astral-plane emoji), the full
   `initialize`/`shutdown`/`exit` handshake, and `didOpen`/`didSave`/
   `didClose` against real temp files (an erroring file, a clean file, a
   missing file) -- plus a real subprocess smoke test (stdin/stdout piped to
   a built `star.exe`, not just in-process `handle_message` calls) confirming
   the wire format actually round-trips end to end. Wired into the one editor
   integration this project ships: `editors/vscode` gained `extension.js` (a
   `vscode-languageclient` client launching `star lsp`, plain CommonJS, no
   bundler -- matching the existing "cheap to keep in sync" philosophy) and
   a `star.serverPath` setting for a non-`PATH` install; `package.json`
   gained the `vscode-languageclient` dependency and a bumped
   `engines.vscode` (^1.60.0 -> ^1.67.0, the floor that dependency's stable
   line needs); the packaged `star-lang-0.2.0.vsix` replaces the old
   grammar-only `0.1.0` one. `readme.md`'s own "Platform Support"-adjacent
   editor story wasn't touched (no root-level mention of editor tooling
   existed to update) -- `editors/vscode/README.md` carries the full
   client-side write-up instead.
6. **Done.** `readme.md` specifies a vague "0.1.0" version and explicitly states
   that stability is not a guarantee, and provides conditions and means for moving
   forward to a reliable scheme.

**P3: Institutionalize the review cadence that has repeatedly proven valuable.**
7. This is the third full assessment in three stages, each
   finding real issues the day-to-day feature work didn't surface on its own.
   Consider tying the next one to a concrete trigger (e.g., "every N
   changelog entries" or "before any session that adds a new codegen module")
   rather than continuing to rely on someone remembering to ask.

# Previous work
src/lsp.rs (new): `star lsp`, a minimal Language Server Protocol server over stdio (todo.md P2 #5) -- `textDocument/publishDiagnostics` on `didOpen`/`didSave`, re-running the same `Driver::compile` pipeline `star check` uses. Hand-rolled `Content-Length`-framed JSON-RPC over `serde_json`; 17 new tests plus a real subprocess smoke test.
src/lib.rs, src/main.rs, Cargo.toml: `pub mod lsp`, the `star lsp` CLI subcommand, and the new `serde_json` dependency.
editors/vscode/extension.js (new), package.json, README.md: a `vscode-languageclient` client launching `star lsp`, a `star.serverPath` setting, and a rebuilt `star-lang-0.2.0.vsix` replacing the grammar-only `0.1.0` one.
todo.md: P2 #5 marked done with a pointer to this write-up.

docs/cross_platform_scope.md (new): full inventory of every Windows-only codegen surface (todo.md P1 #3) — text rendering (`system_font.rs`/GDI, hard, `stb_truetype` vendor plan), networking (`net.rs`/Winsock, cheap, BSD-socket-equivalence plan), env vars (`os.rs`'s `env_set`/`_putenv_s`, cheapest, `setenv` plan), and SDL2 windowing/audio/gamepad (not a codegen gap — packaging only, SDL2 already ships Linux builds). States plainly that cross-platform Linux support is a genuinely intended goal, gated on a real Linux devbox existing to build/link/run against rather than more IR-shape inspection.
src/codegen/platform.rs, net.rs, os.rs: each module's own doc comment now points to the new scoping doc — `platform.rs`'s "What's not here" section no longer names only fonts, and `net.rs`/`os.rs` each gained a "Windows-only today, but cheap to port" section.
readme.md: "Platform Support" section rewritten to list all three Windows-only surfaces (previously only mentioned fonts+SDL, and incorrectly implied audio/gamepad had no portable equivalent when SDL2 itself does), and to state the cross-platform intent plus the devbox gate explicitly.
todo.md: P1 #3 marked done with a pointer to this write-up. No code changes this round — this item was explicitly scope-first.

src/types/stack_budget.rs (new): `Checker::check_stack_budget`, a `star check`-time stack-budget heuristic warning (todo.md P0 #2) — per-function `let`-aggregate footprint plus deepest static call-chain footprint, warning at 1MiB combined.
src/types/mod.rs, src/driver.rs, src/main.rs: threaded a new non-fatal `warnings: Vec<Diagnostic>` channel through `Checker` → `Compilation` → `star check`/`star build`'s stderr output, parallel to the existing fatal `errors`/`diagnostics` path and mirroring how `IrVerification` already splits errors/warnings for codegen.
tests/frontend_stack_budget_warning.rs (new): 11 tests covering the combined-call-chain incident shape, method-call resolution, nested-struct sizing, heap-backed-container exclusion, recursion termination, and warning severity.
todo.md: P0 #2 marked done with a pointer to this write-up.

cpu.star: generalized write_width_for to ~30 handlers (todo.md P0 #1), fixed PUSH/POP's stack-slot width to match operand kind, and fixed a BCD read-width bug plus a BCD carry/borrow masking-order bug (the latter correcting a previously-wrong NOTES.md claim).
NOTES.md: full write-up of all three fixes with live-reference verification evidence, a correction of the prior incorrect BCD documentation, a new "Status: this port now supersedes the Python reference" section, and a "What to carry back to the Python emulator" section listing the two confirmed upstream bugs (stale PUSH/POP docs, easy-to-misread BCD statement order).
todo.md: P0 #1 marked done with a pointer to the NOTES.md write-up.
5 new checked-in regression tests in tests/asm/, each verified against the live Python reference before being added.

The full-suite background run finished with one failure: runtime_window_create_degenerate_dimensions_end_to_end (an SDL test creating windows with huge/degenerate dimensions), which crashed with an access violation. I reran it in isolation and it passed cleanly — this is a pre-existing flake from concurrent SDL/DLL contention when the whole suite runs in parallel (the codebase's own test helpers document this exact class of race), unrelated to my changes (which only touch the checker/driver/CLI, never SDL or codegen). Not a regression.

Summary: todo.md's P0 #2 is done. Checker::check_stack_budget (new src/types/stack_budget.rs) gives star check/star build a heuristic warning when a function's own aggregate let footprint combined with its deepest static call chain crosses 1MiB — turning the exact "combined stack usage across nested calls" incident class into a compile-time signal instead of a runtime crash. Warnings flow through a new non-fatal Checker/Compilation channel that never blocks a clean compile. 11 new tests in tests/frontend_stack_budget_warning.rs cover the core incident shape, method-call resolution, nested structs, heap-backed containers, and recursion safety — all passing, with the rest of the repo's test suite (1000+ tests) green aside from that one unrelated flake.

