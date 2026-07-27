# Star

A game programming language with Pythonic-Rust syntax and unique memory management modes, targeting native executables via LLVM IR.

## Design

- **Syntax**: Python-style indentation, Rust-style type inference, pattern matching, and immutability-by-default.
- **Memory**: Three-tier model — `frame` bump allocators for ephemeral data, spatial `arena`s for level-scoped state, and generational references for cross-arena communication.
- **Concurrency**: `swarm`/`par` for safe parallel ECS iteration, `system`/`parallel` for compiler-checked cross-system scheduling; `sequence` for tick-aware coroutines.
- **Math**: Native `vec2`/`vec3`/`vec4`/`mat4` types with GLSL-style swizzling.
- **Graphics/input**: SDL2-backed windowing, 2D framebuffer drawing, and keyboard/mouse polling (`window_create`, `draw_pixel`/`draw_rect`/`draw_line`, `key_down`, ...) — see `examples/graphics.star`.
- **Reflection**: `@export`/`@tweakable` decorators for hot-reloading.

See [docs/design.md](docs/design.md) and [docs/features.md](docs/features.md) for the full language specification.

## Platform Support

A compiled Star program only runs on Windows today: `window_create`/audio/
gamepad (`crate::codegen::sdl`/`audio`/`gamepad`) bind SDL2, and
`font_load_system`/`font_load_ttf`/`draw_text_ttf` (`crate::codegen::
system_font`) bind Windows GDI directly, with no portable equivalent bound
in either case. That's an explicit, acknowledged scope decision, not an
oversight — see `crate::codegen::system_font`'s module doc comment for why
GDI text rendering in particular isn't a cheap retrofit (there's no POSIX
syscall that rasterizes a TrueType glyph).

One piece *is* target-abstracted: the `par`/`swarm` worker-thread pool
(`crate::codegen::platform`) has a real second implementation using POSIX
threads/semaphores instead of Win32 primitives, selectable with `--target
linux` on `star build`/`star emit llvm`. This is best-effort cross-*emission*
of that one subsystem, not a supported cross-compile story: nothing in this
repo vendors, detects, or verifies a Linux sysroot/libc, and any program
touching a window/audio/gamepad/font builtin still won't link under that
target regardless. Use it to inspect the generated IR shape or hand it to a
real Linux toolchain, not to expect `star build --target=linux` to produce a
working binary out of the box.

## Compilation Toolchain

Star compiles via a two-stage pipeline:

1. **Front-end** (Rust): lexes, parses, type-checks, and emits textual LLVM IR (`.ll`).
2. **Back-end** (Clang/LLVM): the `.ll` file is compiled to a native `.exe` by the installed `clang.exe`.

This approach avoids linking against LLVM development libraries directly, removes version constraints (any Clang that accepts modern LLVM IR works), and still produces fully optimized native code.

### Requirements

- **Rust toolchain** (edition 2024) for building the compiler. Two supported paths:
  - **Standard (MSVC) Rust — recommended.** `cargo build` works with no extra configuration; nothing GNU-specific below ever applies to this path.
  - **GNU/mingw Rust (`x86_64-pc-windows-gnu`)**, for a machine without MSVC Build Tools installed. The GNU-ABI Windows target expects a mingw-w64 GCC-style static runtime (`libgcc_eh.a`/`libgcc.a`) that stock `rustup` Rust doesn't ship, whereas the MSVC target just links against the Windows SDK/`link.exe` every Rust-for-Windows install already has — hence this extra setup only on the GNU side:
    1. Install [LLVM-mingw](https://github.com/mstorsjo/llvm-mingw) (it supplies compiler-rt/libunwind, which `vendor-libs/`'s stub archives are built to work against).
    2. Add the block below to your **own** `%USERPROFILE%\.cargo\config.toml` (`~/.cargo/config.toml` on other platforms) — machine-local, not part of this repo, so it never needs to match anyone else's install layout. This has to be user-level rather than a per-project `build.rs`: the flags need to apply to *every* crate linked for this target, including dependencies' own build scripts (e.g. `proc-macro2`/`quote`), which a project-local build script can't reach.
       ```toml
       [target.x86_64-pc-windows-gnu]
       rustflags = [
           "-L", "<path to this checkout>/vendor-libs",
           "-L", "<LLVM-mingw install>/x86_64-w64-mingw32/lib",
           "-C", "link-arg=-fuse-ld=lld",
           "-C", "link-arg=-lunwind",
       ]
       ```
    3. Build/test with `cargo +stable-x86_64-pc-windows-gnu build` / `... test`.
- **Clang/LLVM on `PATH`** for the back-end (`star build`'s `.ll` → `.exe` step; unrelated to which Rust toolchain built the compiler itself). If clang isn't on `PATH`, set `STAR_CLANG_PATH` to its full path — LLVM-mingw's own `clang.exe` works fine here too.

## Usage

```
star check <file>       # Lex, parse, type-check, report diagnostics
star build <file>       # Full pipeline → native executable
star emit tokens <file> # Dump the token stream
star emit ast <file>    # Dump the parsed AST
star emit llvm <file>   # Dump the generated LLVM IR
```

`<file>` may also be a directory containing a `star.toml` manifest (see
below) -- `check`/`build`/`emit` then operate on the manifest's declared
`entry` file. Every subcommand also accepts `-I`/`--search-path <dir>`
(repeatable) to add an `import` search directory, and honors a `STAR_PATH`
environment variable (a `PATH`-style list) the same way.

### Example

```bash
# Check the canonical example
star check examples/player.star

# Build it to a native executable
star build examples/player.star

# Inspect the generated IR
star emit llvm examples/player.star

# Build a manifest-rooted project by directory instead of by file
star build projects/snake -L sdl/lib/x64 -l SDL2 -o projects/snake/snake.exe
```

### Project manifests

A `star.toml` in a directory marks it as a project root and lets `import`
resolve against a configured search path instead of only hand-written
relative paths -- see [docs/language_reference.md](docs/language_reference.md)'s
"Project manifests" section for the full format.

## Project Status

The compiler front-end (lexer, parser, type checker, LLVM IR emitter) is functional. The canonical `Player`/`Damageable` example from the design doc parses, type-checks, produces LLVM IR, and compiles to executable. See [todo.md](todo.md) for the remaining milestones.

## Development

```bash
cargo build
cargo test
cargo run -- check examples/player.star
```

Building for the GNU/mingw target instead (after the one-time user-level
`.cargo/config.toml` setup in "Requirements" above):

```bash
cargo +stable-x86_64-pc-windows-gnu build
cargo +stable-x86_64-pc-windows-gnu test
```