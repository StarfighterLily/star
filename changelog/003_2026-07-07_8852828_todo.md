# Star Compiler — Next Steps

## Immediate: M5 Memory Model

## M5: Memory Model

- [ ] **`frame` keyword**: Implement the frame bump allocator. The `frame` keyword introduces a scope whose allocations are reset at the end of each tick. Requires escape analysis in the type checker to prevent frame pointers from escaping their scope.
- [ ] **Spatial `arena`s**: First-class arena types. `arena MyArena: Type` declares a named allocation space. Entire arenas can be dropped in O(1). Implement arena declarations in the parser, type checker, and codegen (emit as a bump allocator struct with a free-list).
- [ ] **Generational references**: `GenRef<T>` type backed by a slot-map. Implement the generational ID pair (index + generation counter) and the validation check on dereference. Add syntax for creating and dereferencing gen refs.

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
- [ ] **Runtime tests**: Compile and run small `.star` programs, assert their output.
- [ ] **Fuzz testing**: Fuzz the lexer and parser with random inputs to find panics.

LATEST:
### M9 Control Flow Implementation Complete
- Fixed `reg_of` in codegen to return `String` instead of `&str` to resolve borrow checker issues.
- Added `TypedExpr::If` case to `expr_ty` match in codegen.
- Updated borrow patterns in `emit_stmt` (If/While) and `emit_expr` (If) to avoid borrowing `self` immutably while calling mutable methods.
- Added `Driver::check` function for tests to access type checking.
- Added 4 new tests in `tests/frontend.rs`:
  - `parses_if_else`: Verifies `Stmt::If` parses with both branches.
  - `parses_while`: Verifies `Stmt::While` parses with optional else.
  - `parses_if_expr`: Verifies `Expr::If` parses as a value (used in `let`).
  - `codegen_if_while`: Full pipeline test asserting `br i1`, block labels (`if_then`, `if_else`, `while_cond`, `while_body`) appear in emitted LLVM IR.
- All 10 tests pass.