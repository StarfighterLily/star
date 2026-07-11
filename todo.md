# Star Compiler — Next Steps
Complete Priority Roadmap

## Priority Roadmap (derived from current_status.md suitability analysis)

Ordered biggest win → smallest, where "win" = how much it unblocks writing useful
programs relative to implementation effort.

### 2. File I/O builtins
Lowest effort, unblocks the single most common "useful program" shape (read
config, save/load game state). Can ship before or independent of FFI.
- `file_open`, `file_read`, `file_read_line`, `file_write`, `file_close`, `file_exists`.
- Decide error model (return `Option`/`Result`-like sentinel vs. abort-on-error,
  consistent with existing bounds/overflow-check philosophy).

### 3. Minimal OS surface: argv + env vars
Small, cheap, and needed by almost any real CLI or config-driven program.
- `args()` → `List<str>` of command-line arguments.
- `env_get(name)` / `env_set(name, value)`.

### 4. Networking basics
Sockets/HTTP client — needed for anything client/server. Natural follow-on once
FFI (#1) exists (bind to existing socket libs) or as direct builtins otherwise.
- Raw TCP socket connect/send/recv as a floor.
- Defer HTTP parsing to a library (via FFI) rather than building it into the compiler.

### 5. Graphics / audio / input bindings
Core to the "game language" pitch but currently 100% aspirational
(`draw_sprite`, `flash_screen`, `wait` are documented but not implemented).
Highest effort of the "unlock capability" items — best sequenced after FFI (#1)
so it's a binding to SDL/similar rather than a from-scratch renderer.
- Window creation + framebuffer/pixel-blit as the minimal viable slice.
- Input polling (keyboard/mouse/gamepad).
- Audio playback (defer to last — least blocking for "useful program" broadly).

### 6. Module system: re-exports, search paths, manifest
Needed once any program grows past a few files. Current system only inlines one
relative-path file at a time with no transitive symbol visibility.
- Transitive re-export so `a` importing `b` importing `c` can reach `c`'s symbols.
- Search-path resolution instead of hand-written relative paths everywhere.
- Minimal package manifest (name, version, entry point) — defer a full package
  manager/registry until there's more than one real multi-file project to learn from.

### 7. Expand core standard library
The current 17 builtins cover almost no string/collection manipulation beyond
`List<T>`. Grow incrementally as real programs (see #9) expose actual gaps
rather than speculatively.
- String ops: split/join/trim/replace/contains/format beyond f-strings.
- A `Map`/`Dict` and `Set` type to complement `List<T>`.
- Fill out math builtins as needed (trig, log/exp, etc.).

### 8. Wire up reflection into an actual runtime feature
`@export`/`@tweakable` currently only emit descriptive metadata strings — there
is no hot-reload runtime or file watcher consuming them yet. Lower priority
since it's a productivity/tooling win, not a capability unlock: nothing is
*impossible* without it, just slower to iterate on.

### 9. Build one real, non-toy program in Star
Everything in `examples/` and `tests/` tops out around ~40 lines of
single-feature demos. Once enough of #1–#4 land, dogfood the language on one
program larger than a toy (e.g. a small file-backed tool or simple game) — this
will surface real gaps faster than speculative stdlib growth, and is the best
validation that the "useful programs today" bar has actually been cleared.

## Last actions:
`extern "C"` FFI:
Language: extern "C" fn name(params) -> ret declares a foreign C symbol (no body); a new opaque ptr type plus null_ptr()/is_null(p)/ptr_to_str(p) builtins round out real usage. Restricted to int/float/ptr everywhere and str as a parameter (not return, since a C char* has no RC header — must go through ptr_to_str); bool and struct/List/generic types are rejected with clear diagnostics, as is any uppercase-starting symbol name (discovered mid-implementation: Star's grammar always parses Name(args) as a struct literal when Name is capitalized, so a PascalCase C symbol like CreateThread would otherwise be silently uncallable — now caught at declaration time instead).

Codegen: extern fns lower to a bare LLVM declare; calls get a dedicated path (emit_extern_call) that correctly balances the RC retain/release for str arguments, since an extern call — unlike a Star function — never releases what it's handed.

CLI: star build gained repeatable -l/-L flags for linking user libraries.

Verified working end-to-end: examples/extern_ffi.star compiles and links against real msvcrt/kernel32 symbols (toupper, atoi, getenv) with no extra flags needed, producing correct output when run.