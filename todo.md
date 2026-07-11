# Star Compiler — Next Steps
Complete Priority Roadmap

## Priority Roadmap (derived from current_status.md suitability analysis)

Ordered biggest win → smallest, where "win" = how much it unblocks writing useful
programs relative to implementation effort.

### 2. Minimal OS surface: argv + env vars
Small, cheap, and needed by almost any real CLI or config-driven program.
- `args()` → `List<str>` of command-line arguments.
- `env_get(name)` / `env_set(name, value)`.

### 3. Networking basics
Sockets/HTTP client — needed for anything client/server. Natural follow-on once
FFI (#1) exists (bind to existing socket libs) or as direct builtins otherwise.
- Raw TCP socket connect/send/recv as a floor.
- Defer HTTP parsing to a library (via FFI) rather than building it into the compiler.

### 4. Graphics / audio / input bindings
Core to the "game language" pitch but currently 100% aspirational
(`draw_sprite`, `flash_screen`, `wait` are documented but not implemented).
Highest effort of the "unlock capability" items — best sequenced after FFI (#1)
so it's a binding to SDL/similar rather than a from-scratch renderer.
- Window creation + framebuffer/pixel-blit as the minimal viable slice.
- Input polling (keyboard/mouse/gamepad).
- Audio playback (defer to last — least blocking for "useful program" broadly).

### 5. Module system: re-exports, search paths, manifest
Needed once any program grows past a few files. Current system only inlines one
relative-path file at a time with no transitive symbol visibility.
- Transitive re-export so `a` importing `b` importing `c` can reach `c`'s symbols.
- Search-path resolution instead of hand-written relative paths everywhere.
- Minimal package manifest (name, version, entry point) — defer a full package
  manager/registry until there's more than one real multi-file project to learn from.

### 6. Expand core standard library
The current 28 builtins cover almost no string/collection manipulation beyond
`List<T>`. Grow incrementally as real programs (see #8) expose actual gaps
rather than speculatively.
- String ops: split/join/trim/replace/contains/format beyond f-strings.
- A `Map`/`Dict` and `Set` type to complement `List<T>`.
- Fill out math builtins as needed (trig, log/exp, etc.).

### 7. Wire up reflection into an actual runtime feature
`@export`/`@tweakable` currently only emit descriptive metadata strings — there
is no hot-reload runtime or file watcher consuming them yet. Lower priority
since it's a productivity/tooling win, not a capability unlock: nothing is
*impossible* without it, just slower to iterate on.

### 8. Build one real, non-toy program in Star
Everything in `examples/` and `tests/` tops out around ~40 lines of
single-feature demos. FFI and file I/O are now done, which is enough to write
a small file-backed tool; dogfood the language on one program larger than a
toy — this will surface real gaps faster than speculative stdlib growth, and
is the best validation that the "useful programs today" bar has actually
been cleared.

## Last actions:
File I/O builtins:
Language: six new builtins — file_open(path, mode) -> ptr, file_close(handle), file_read(handle) -> str, file_read_line(handle) -> str, file_write(handle, data) -> bool, file_exists(path) -> bool — reusing the extern-FFI ptr type as the file handle rather than adding a new type. Error model: file_open returns a null ptr on failure (checked with the existing is_null()/null_ptr(), exactly like getenv); a null/closed handle passed to file_read/file_read_line/file_write/file_close is treated as a programmer error and aborts loudly (diagnostic + exit(1)), matching the existing frame-overflow/div-by-zero abort philosophy rather than inventing an Option/Result type Star doesn't have; file_read/file_read_line yield an empty str on EOF, matching read_line()'s own EOF convention.

Codegen: new src/codegen/file_io.rs module wrapping fopen/fclose/fread/fwrite/fseek/ftell/fgetc (all core CRT symbols, no extra link flags needed, same as the extern-FFI CRT calls). file_read sizes its buffer up front via ftell/fseek rather than growing incrementally, since the remaining byte count is cheap to compute ahead of a single fread; file_read_line is structurally identical to the existing read_line()'s fixed-buffer char-at-a-time loop, just sourced from fgetc(handle) instead of the stdin-only getchar().

Verified working end-to-end: examples/file_io.star writes a file, checks file_exists on a real and a missing path, then reopens and reads it back with both file_read_line and file_read, producing correct output when run (confirmed against the real file written to disk, not just captured stdout).