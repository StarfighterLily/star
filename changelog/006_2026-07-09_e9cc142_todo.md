# Star Compiler — Next Steps

## Immediate: M7

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

 ### M6 SIMD Math Types Implementation Complete

 - Vec2/Vec3/Vec4/Mat4 arithmetic (`+`, `-`, `*`, `/`, matrix multiply), GLSL swizzle read/write (including full multi-component write masking), and constructors all implemented and tested.
 - Fixed two pre-existing latent bugs uncovered along the way: `emit_binop` was hardcoded to always emit `i32` opcodes (float arithmetic silently produced invalid IR), and float literals/printf varargs were mishandled (`1.0` formatted as `"1"`, and `float` args to `printf` need `fpext` to `double` per the C variadic calling convention).
 - New `examples/vecmath.star` + committed `.ll`/`.exe` exercise the whole feature end-to-end via a real compiled binary (`runtime_vecmath_end_to_end` test).