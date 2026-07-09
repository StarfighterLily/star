# Star Compiler — Next Steps

## Immediate: M6 SIMD

## M6: SIMD Math Types

- [ ] **`vec2`/`vec3`/`vec4`/`mat4`**: These types are already in the `Ty` enum and parser. Implement:
  - Struct layouts in LLVM IR (already partially done)
  - GLSL-style swizzling (`.xyz`, `.xy`, etc.) in the parser and type checker
  - Operator overloading for vector/matrix arithmetic
  - Codegen using LLVM's `<4 x float>` vector type and appropriate shuffle/insert/extract instructions

## M7: Concurrency & Coroutines

- [ ] **`swarm`/`par` keyword**: Parallel iteration over arena component arrays. Requires read/write declaration analysis in the type checker to prove disjoint access. Codegen emits a loop that dispatches iterations across threads.
- [ ] **`sequence` keyword**: Tick-aware coroutines. The compiler hoists local variables into a struct, generates a state-machine switch statement, and allocates the struct into a lightweight arena. Implement the lowering in the parser → HIR → codegen pipeline.

## M8: Reflection

- [ ] **`@export`/`@tweakable` decorators**: During codegen, emit a metadata section containing `offsetof` and type info for decorated fields. The metadata is written as a global constant in the `.ll` file so an external editor can read it via shared memory or IPC.
- [ ] **Free functions**: Top-level `fn` items (outside impl blocks) are parsed and type-checked but codegen needs testing.
- [ ] **Standard library**: Built-in `print` is implemented (lowers to `@printf`). Still needed: `println`, basic math functions, string operations.
- [ ] **Error messages**: Improve diagnostic quality with suggestions and notes.

## Testing

- [ ] **Runtime tests**: Compile and run small `.star` programs, assert their output.
- [ ] **Fuzz testing**: Fuzz the lexer and parser with random inputs to find panics.

 LATEST:

 ### M5 Memory Model Implementation Complete