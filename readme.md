# Star

A game programming language with Pythonic-Rust syntax and unique memory management modes, targeting native executables via LLVM IR.

## Design

- **Syntax**: Python-style indentation, Rust-style type inference, pattern matching, and immutability-by-default.
- **Memory**: Three-tier model — `frame` bump allocators for ephemeral data, spatial `arena`s for level-scoped state, and generational references for cross-arena communication.
- **Concurrency**: `swarm`/`par` for safe parallel ECS iteration; `sequence` for tick-aware coroutines.
- **Math**: Native `vec2`/`vec3`/`vec4`/`mat4` types with GLSL-style swizzling.
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

### Example

```bash
# Check the canonical example
star check examples/player.star

# Build it to a native executable
star build examples/player.star

# Inspect the generated IR
star emit llvm examples/player.star
```

## Project Status

The compiler front-end (lexer, parser, type checker, LLVM IR emitter) is functional. The canonical `Player`/`Damageable` example from the design doc parses, type-checks, and produces LLVM IR. See [todo.md](todo.md) for the remaining milestones.

## Development

```bash
cargo build
cargo test
cargo run -- check examples/player.star