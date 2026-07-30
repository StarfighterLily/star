# Project Conventions

This document describes how Star is actually built, day to day — the
patterns that have emerged across 129+ commits and six documented
"stages" of work, not aspirational rules invented after the fact. If a
convention here stops matching what the code does, fix the convention
(or fix the code) rather than leaving them to drift apart.

See also: [../CLAUDE.md](../CLAUDE.md) for the condensed, agent-facing
version of these rules.

## Build toolchain

Two supported Rust paths — see `readme.md`'s "Requirements" section for
the full setup:

- **MSVC (`cargo build` as-is)** if MSVC Build Tools are installed.
- **GNU/mingw**, for a machine without MSVC: requires a one-time
  user-level `.cargo/config.toml` addition (LLVM-mingw + `vendor-libs/`
  link flags), then every build/test command is prefixed with the
  explicit toolchain:
  ```
  cargo +stable-x86_64-pc-windows-gnu build
  cargo +stable-x86_64-pc-windows-gnu test
  cargo +stable-x86_64-pc-windows-gnu check --tests
  ```
  Plain `cargo build`/`cargo test` fails on a GNU-only machine (no MSVC
  linker) — always use the `+stable-x86_64-pc-windows-gnu` form unless
  you've confirmed MSVC is present.

Clang/LLVM must also be on `PATH` (or `STAR_CLANG_PATH` set) for
`star build`'s `.ll` → `.exe` backend step — this is independent of
which Rust toolchain built the compiler itself.

## Code style

- Conventional, idiomatic Rust formatting (`cargo fmt` defaults).
- Modular by concern: `src/codegen/` is one file per builtin-area or
  subsystem (`net.rs`, `os.rs`, `sdl.rs`, `arena.rs`, ...), each with its
  own `impl Codegen` block, all re-exported through `src/codegen/mod.rs`.
  `src/types/` follows the same shape (`stack_budget.rs`,
  `frame_analysis.rs`, `par_analysis.rs`, ...). New builtin surfaces or
  analyses get their own file rather than growing an existing one
  indefinitely.
- Windows-first shell assumptions in tooling/docs: PowerShell syntax, not
  `sh`/bash-isms, when giving example commands (the project itself only
  targets Windows today — see "Platform scope" below).

## Documentation style — module doc comments are load-bearing

Every source file starts with a `//!` module doc comment that explains
**why**, not just what:

- What problem/gap this file closes, usually with a pointer back to the
  `todo.md` item that motivated it (e.g. `` `todo.md` P1 #4 ``).
- The design tradeoff actually taken and the alternatives considered —
  see `src/codegen/net.rs`'s doc comment (why raw sockets and not
  HTTP/DNS, why the error-sentinel convention matches `file_io.rs`
  instead of inventing a new one) or `src/codegen/system_font.rs` (why
  GDI has no cheap POSIX equivalent) as reference examples.
- Any subtlety a future reader would otherwise have to rediscover by
  reading the diff or asking someone — a workaround for a specific bug,
  a non-obvious invariant, why a `Target`-gated seam is or isn't in place
  yet.

Individual `#[test]` functions and public items get a one-to-few-line
`///` doc comment stating the specific behavior/edge case under test or
provided, not a restatement of the function name.

Default to **no** comments inside function bodies unless the *why* is
genuinely non-obvious (matches the general engineering guidance this
project is developed under) — the module-level doc comment is where the
narrative belongs, not scattered inline notes.

## Testing conventions

- Integration tests live in `tests/`, one file per feature/topic, named
  `frontend_<topic>.rs` (e.g. `frontend_hex_integer_literals.rs`,
  `frontend_bitwise_shift_operators.rs`). Prefer splitting a new topic
  into its own file over growing an existing one — `tests/frontend.rs`
  was deliberately split from a single 1,514-test monolith into 59
  topic-scoped files during Stage 5 for exactly this reason.
- Every test file imports the shared harness via:
  ```rust
  #[path = "frontend/common.rs"]
  #[allow(dead_code, unused_imports)]
  mod common;
  use common::*;
  ```
- Bug-hunting passes get their own explicitly numbered files
  (`frontend_bughunt_round2_...rs`, `..._round3_...rs`, ...) rather than
  being folded into topic files, so a specific hardening pass stays
  independently discoverable in the test tree.
- New behavior gets new tests in the same change, not a follow-up —
  confirm with `cargo ... test` before considering a `todo.md` item done.

## `todo.md` workflow

`todo.md` is the live work queue, organized into `P0`–`P3` priority
tiers (P0 = protect what's already proven fragile; higher numbers =
progressively lower urgency: closing scoped gaps, lowering the adoption
barrier, process/meta items). When resuming work:

1. Pick up the next undone item (usually the lowest-numbered `P0` item
   first).
2. Implement it.
3. Mark the item **Done.** in place with a short summary of what
   actually landed (including any bugs found along the way that weren't
   in the original ask — see existing `todo.md` entries for the level of
   detail expected: which files changed, what was verified, and any
   caveat the next reader needs).
4. Append to the **Previous work** section at the bottom of `todo.md`: a
   per-file bullet list of what changed and why, one paragraph block per
   completed item.
5. Confirm with `cargo +stable-x86_64-pc-windows-gnu check --tests` (or
   plain `cargo` if on an MSVC machine) before calling the item done.
6. Add/extend tests per "Testing conventions" above and run them.

This mirrors `.clinerules/workflows/todo` — that file is the
condensed instruction-following version of this same loop for
non-Claude tooling; keep the two in sync if either changes.

## Reassessment cycle: `current_status.md` and `changelog/`

The project has, twice already (`changelog/060`, `changelog/062`), found
that periodic full-codebase reassessments surface real issues day-to-day
feature work doesn't — `todo.md`'s own P3 #7 entry names this pattern
explicitly and asks for it to be tied to a concrete trigger instead of
depending on someone remembering to ask. The convention below **is**
that trigger:

- **Trigger: full completion of the current `todo.md` list.** When every
  item in `todo.md` is marked Done (no open P0–P3 items remain), that is
  the signal to stop and write a fresh reassessment — not to keep
  drifting into ad hoc feature work with a stale punch list.
- **The reassessment is written to `current_status.md`** at the repo
  root, overwriting the previous edition. It follows the shape already
  established by the existing document: a scope statement (what was
  read/reviewed, at which commit), a staged history section, an honest
  "goals vs. reality" section naming real caveats rather than hiding
  them, and a **"Next steps, prioritized"** section using the same
  `P0`–`P3` scheme as `todo.md`.
- **That "Next steps" section becomes the seed of the next `todo.md`.**
  The cycle is: `current_status.md`'s prioritized next steps → copied
  into a fresh `todo.md` → worked through to full completion → triggers
  the next `current_status.md` reassessment → repeat.
- **Before overwriting, archive both superseded files to `changelog/`**
  so the history of each reassessment/todo cycle stays inspectable.
  Naming convention (see the 59 existing entries following this
  pattern):
  ```
  changelog/<NNN>_<YYYY-MM-DD>_<short-commit-hash>_<original-filename>.md
  ```
  - `<NNN>` — zero-padded, sequential, continuing the existing series
    (next after `065` is `066`).
  - `<YYYY-MM-DD>` — hyphenated ISO date, matching the date format used
    everywhere else in this project's prose (not `YYYY_MM_DD`).
  - `<short-commit-hash>` — the short hash of the commit the snapshot was
    taken at (`git rev-parse --short HEAD`), so a changelog entry can be
    pinned back to an exact tree state.
  - `<original-filename>` — `todo.md` or `current_status.md`, preserving
    the source file's own name and extension.

    > **Note on drift:** entries `060`–`065` dropped the commit hash and
    > switched to underscore-separated dates (e.g.
    > `060_2026_07_26_ASSESSMENT.md`). That was a deviation from the
    > convention 59 prior entries established, not a new convention —
    > new entries should return to the full
    > `NNN_YYYY-MM-DD_<hash>_<filename>.md` form.
  - Copy (don't move) `todo.md` and `current_status.md` into `changelog/`
    under these names *before* overwriting either file in place, so the
    archived copy captures the exact pre-reassessment state.

## Platform scope

Star targets Windows only today, by construction in three specific
codegen surfaces (GDI text rendering, Winsock networking, `_putenv_s`
env vars) — see `docs/cross_platform_scope.md` for the full inventory
and per-surface porting plan, and `readme.md`'s "Platform Support"
section for the user-facing summary. When adding a new OS-facing
builtin:

- Default to the same "thin wrapper over an existing C ABI" shape
  `net.rs`/`os.rs`/`file_io.rs` already use, not a new abstraction.
- If a POSIX-equivalent exists and is cheap (most cases — see the
  networking/env-var write-ups in `cross_platform_scope.md`), leave a
  `Target`-gated seam even if you don't implement the Linux arm yet,
  following `codegen/platform.rs`'s existing pattern.
- If no cheap POSIX equivalent exists (the GDI text-rendering case),
  document that explicitly in the module's own doc comment rather than
  implying portability that isn't there.
- Update `docs/cross_platform_scope.md` and `readme.md`'s "Platform
  Support" section in the same change, not as a follow-up.

## Versioning

`0.2.0` as of the `82be6e2` reassessment (2026-07-30) — see `readme.md`'s
"Versioning" section and `changelog/069_2026-07-30_82be6e2_current_
status.md` for the condition-by-condition gate check. Standard SemVer
practice now applies from here. Don't bump the version number as part of
unrelated feature work — the `0.1.0` → `0.2.0` move happened only because
a full reassessment cycle confirmed the gate's conditions, and any future
bump (a `1.0.0` push, say) should get the same deliberate treatment, not
be folded into other work.
