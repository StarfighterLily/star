Write industry-standard Rust code in conventional Rust formatting. Everything should be modular, showing clear separation of concerns to allow maintainability.
Use Windows 10 powershell commands and syntax, nothing *nix flavored.

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

Windows-only today, by construction — see `docs/cross_platform_scope.md`.
New OS-facing builtins should follow the existing thin-C-ABI-wrapper shape
(`net.rs`/`os.rs`/`file_io.rs`) and leave a `Target`-gated seam even if
the Linux arm isn't implemented yet, unless there's genuinely no cheap
POSIX equivalent (document that explicitly if so, as `system_font.rs`
does for GDI).

## Things not to do

- Don't bump the version past `0.1.0` as part of unrelated work — see
  `readme.md`'s "Versioning" section for the actual gate.
- Don't `git push`, force-push, or amend published commits without
  explicit confirmation for that specific action.
- Don't skip the reassessment trigger in `.clinerules/workflows/todo`
  because the next feature feels more urgent — the whole point is that
  it isn't optional.
