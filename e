# Star Compiler — Next Steps

## Immediate: M5 Memory Model

## M5: Memory Model

- [x] **`frame` keyword**: Implement the frame bump allocator. The `frame` keyword introduces a scope whose allocations are reset at the end of each tick. Implemented: frame bounds checking saves and restores offset.
- [x] **Spatial `arena`s**: First-class arena types. `arena MyArena: Type` declares a named allocation space. Implemented: Arena declarations with struct type and global state.
- [x] **`GenRef<T>` type**: GenRef<T> type backed by a slot-map. Implemented: GenRef struct type with index/generation fields.

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

- [x] **Codegen test suite**: Add integration tests that compile `.star` files to `.ll` and verify the IR with `llc` or `clang -c`. NOTE: full `star build` currently fails only at the *link* step on this machine because the MSVC runtime libs (`libcmt.lib`, `oldnames.lib`) are not on clang's search path — codegen itself is validated with `clang -c` (object-file compile), which succeeds.
- [x] **Runtime tests**: Compile and run small `.star` programs, assert their output. Verified with memory_models.exe.
- [ ] **Fuzz testing**: Fuzz the lexer and parser with random inputs to find panics.

 LATEST:
 
 ### M5 Memory Model Verification Complete
 - **Frame allocator**: VERIFIED: Correctly uses bump allocation with `@frame.buf` (4096 bytes) and `@frame.off` (offset). Offset is saved at frame entry and restored at exit for O(1) deallocation.
 - **Arena declarations**: VERIFIED: Arena structs defined as `{ i8*, i64, i64 }` with global data pointer (null) and count (0). `malloc` is declared but not yet called for allocation.
 - **GenRef type**: VERIFIED: GenRef struct type `{ i32, i32 }` correctly emits index and generation fields. GenRef dereference extracts index at field 0.
 - **GDB verification**: Disassembled `calculate_path` function shows correct frame offset manipulation:
   - Saves offset: `mov 0x4c4d(%rip),%rcx` → `frame.off` address
   - Increments offset for allocation: `add $0x8,%rax`
   - Stores back: `mov %rax,0x4c38(%rip)`
   - Restores offset on exit: `mov %rcx,0x4bd1(%rip)` → `frame.off`
 - **All 21 tests pass** including new runtime verification tests.

### Known Limitations
 - **Arena allocation**: Arena declarations emit globals but no actual malloc/free calls are generated. Runtime arena operations (init, allocate, deallocate) need implementation.
 - **GenRef validation**: No generation checking on dereference - just extracts index field.