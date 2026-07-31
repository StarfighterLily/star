# CLAUDE.md

Project rules for Claude Code (and other AI agents) working in this
repo. This is the condensed, agent-facing summary — the full rationale
and examples live in [docs/conventions.md](docs/conventions.md); read
that file when a rule here needs more context than a one-liner gives.
`.clinerules/general.md` and `.clinerules/workflows/todo` cover the same
ground for Cline; keep all three in sync if any changes.

## Build & test — always use the GNU toolchain

Plain `cargo build`/`cargo test` fails on this machine (no MSVC linker).
**Always** use:

```
cargo +stable-x86_64-pc-windows-gnu build
cargo +stable-x86_64-pc-windows-gnu test
cargo +stable-x86_64-pc-windows-gnu check --tests
```

Never drop the `+stable-x86_64-pc-windows-gnu` toolchain override unless
you've explicitly confirmed MSVC Build Tools are installed instead.

Shell is Windows PowerShell — give commands in PowerShell syntax, not
bash/`sh`.

## Working the todo list

`todo.md` is the live work queue (`P0`–`P3` tiers, lowest number =
highest priority). Default workflow when asked to "continue" or given no
other target:

1. Pick up the next undone item, lowest priority number first.
2. Implement it, adding/extending tests in `tests/` alongside the code
   change (see "Testing" below) — not as a follow-up step.
3. Confirm with `cargo +stable-x86_64-pc-windows-gnu check --tests` and
   the relevant test file(s) before calling it done.
4. Mark the item **Done.** in `todo.md` with a real summary (what
   changed, what was verified, any bug found along the way that wasn't
   in the original ask) and append to the **Previous work** section at
   the bottom — see existing entries for the expected level of detail.

## Reassessment trigger — do not skip this

**When every item in `todo.md` is marked Done (no open `P0`–`P3` items
remain), stop feature work and run a full reassessment before starting
anything new.** This has already surfaced real issues twice
(`changelog/060`, `changelog/062`) that day-to-day feature work missed,
and `todo.md`'s own P3 #7 asks for exactly this to become an automatic
trigger rather than something someone has to remember to request.

When the trigger fires:

1. **Archive first, before overwriting anything.** Copy the current
   `todo.md` and `current_status.md` into `changelog/` as:
   ```
   changelog/<NNN>_<YYYY-MM-DD>_<short-commit-hash>_todo.md
   changelog/<NNN>_<YYYY-MM-DD>_<short-commit-hash>_current_status.md
   ```
   `<NNN>` continues the existing sequential series (check the highest
   existing number in `changelog/` first). Use hyphenated ISO dates and
   include the short commit hash (`git rev-parse --short HEAD`) — this
   is the convention 59 of 65 existing entries follow; don't repeat the
   underscore-date/no-hash drift seen in entries `060`–`065`.
2. **Write a fresh `current_status.md`**, overwriting the old one: scope
   statement (what was reviewed, at which commit), a staged-history
   narrative, an honest goals-vs-reality section, and a "Next steps,
   prioritized" section using the same `P0`–`P3` scheme.
3. **Seed a fresh `todo.md`** from that "Next steps" section.
4. Only then resume normal `todo.md` work.

Do not silently skip this because it feels like a detour — it's a
required step of the loop, equally weighted with implementation work.

## Documentation style

Every source file's `//!` module doc comment should explain *why* (the
`todo.md` item it closes, the tradeoff actually taken, alternatives
considered), not just restate what the code does. See
`src/codegen/net.rs` or `src/codegen/system_font.rs` for the calibration
this project expects. Function-body comments stay rare — only for
genuinely non-obvious invariants or workarounds, matching this project's
general "don't explain what, explain why" standard.

## Testing

- One `tests/frontend_<topic>.rs` file per feature/topic; prefer a new
  file over growing an existing one indefinitely.
- Pull in the shared harness the same way every existing test file does:
  ```rust
  #[path = "frontend/common.rs"]
  #[allow(dead_code, unused_imports)]
  mod common;
  use common::*;
  ```
- Give each `#[test]` fn a one-line `///` doc comment naming the
  specific behavior/edge case it covers.

## Platform scope

See [docs/cross_platform_scope.md](docs/cross_platform_scope.md).
New OS-facing builtins should follow the existing thin-C-ABI-wrapper shape
(`net.rs`/`os.rs`/`file_io.rs`) and leave a `Target`-gated seam even if
the Linux arm isn't implemented yet, unless there's genuinely no cheap
POSIX equivalent (document that explicitly if so, as `system_font.rs`
does for GDI).

## Versioning
The official version has been bumped from `0.1.0` as the gated requirements
have been met, user-reviewed, and reassessed. From here on out, industry-standard
SemVer practices are to be observed as per the [readme.md](readme.md)'s versioning
section. Keep all instances of the Star language's version consistent across all
load-bearing files and documentation, taking time out to do so explicitly so no
staleness grows in some hidden corner.


## Things not to do
- Don't bump the version number
   as part of unrelated feature work — the `0.1.0` → `0.2.0` move happened only because
   a full reassessment cycle confirmed the gate's conditions, and any future
   bump (a `1.0.0` push, say) should get the same deliberate treatment, not
   be folded into other work.
- Don't `git push`, force-push, or amend published commits without
  explicit confirmation for that specific action.
- Don't skip the reassessment trigger above because the next feature
  feels more urgent — the whole point is that it isn't optional.
