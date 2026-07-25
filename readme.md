# Star

A game programming language with Pythonic-Rust syntax and unique memory management modes, targeting native executables via LLVM IR.

## Design

- **Syntax**: Python-style indentation, Rust-style type inference, pattern matching, and immutability-by-default.
- **Memory**: Three-tier model — `frame` bump allocators for ephemeral data, spatial `arena`s for level-scoped state, and generational references for cross-arena communication.
- **Concurrency**: `swarm`/`par` for safe parallel ECS iteration; `sequence` for tick-aware coroutines.
- **Math**: Native `vec2`/`vec3`/`vec4`/`mat4` types with GLSL-style swizzling.
- **Graphics/input**: SDL2-backed windowing, 2D framebuffer drawing, and keyboard/mouse polling (`window_create`, `draw_pixel`/`draw_rect`/`draw_line`, `key_down`, ...) — see `examples/graphics.star`.
- **Reflection**: `@export`/`@tweakable` decorators for hot-reloading.

See [docs/design.md](docs/design.md) and [docs/features.md](docs/features.md) for the full language specification.

## Compilation Toolchain

Star compiles via a two-stage pipeline:

1. **Front-end** (Rust): lexes, parses, type-checks, and emits textual LLVM IR (`.ll`).
2. **Back-end** (Clang/LLVM): the `.ll` file is compiled to a native `.exe` by the installed `clang.exe`.

This approach avoids linking against LLVM development libraries directly, removes version constraints (any Clang that accepts modern LLVM IR works), and still produces fully optimized native code.

### Requirements

- **Rust toolchain** (edition 2024) for building the compiler.
- **Clang/LLVM** on `PATH` (or at `E:\LLVM\bin\clang.exe`) for the back-end.

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