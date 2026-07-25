# Star Compiler — Next Steps

## Immediate: M9 Control Flow — Add `if`/`else` and `while` End-to-End
Contrary to an earlier note, the AST has **no** `If`, `While`, or `For` nodes (see `src/ast.rs` `Expr`/`Stmt`), and the parser does not produce them. Control flow must be threaded through the whole pipeline:

- [ ] **AST**: Add `Stmt::While { cond, body, span }` and an `Expr::If { cond, then_block, else_block, span }` (or `Stmt::If`). Update `Expr::span`.
- [ ] **Lexer**: Confirm `if`/`else`/`while` keyword tokens exist (add if missing).
- [ ] **Parser**: Parse `if cond: <block> [else: <block>]` and `while cond: <block>` into the new nodes.
- [ ] **Type checker**: Add `TypedStmt::While` / `TypedExpr::If`; check the condition is `Ty::Bool` and infer the block/branch types.
- [ ] **Codegen**: Lower `while` to a header/body/exit branch pattern; lower `if` to `br` + basic blocks (and phi when used as an expression). Note: `emit_fn` currently emits all instructions into a single `entry:` block, so codegen needs a basic-block/label helper.

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

## M9: Language Completeness

- [ ] **`if`/`else` expressions**: See the Immediate section — needs AST/parser/checker/codegen. Lower to `select` or branch/phi.
- [ ] **`for`/`while` loops**: `while` first (see Immediate); `for` → desugar to `while`.
- [ ] **Free functions**: Top-level `fn` items (outside impl blocks) are parsed and type-checked but codegen needs testing.
- [ ] **Standard library**: Built-in `print` is implemented (lowers to `@printf`). Still needed: `println`, basic math functions, string operations.
- [ ] **Error messages**: Improve diagnostic quality with suggestions and notes.

## Testing

- [ ] **Codegen test suite**: Add integration tests that compile `.star` files to `.ll` and verify the IR with `llc` or `clang -c`. NOTE: full `star build` currently fails only at the *link* step on this machine because the MSVC runtime libs (`libcmt.lib`, `oldnames.lib`) are not on clang's search path — codegen itself is validated with `clang -c` (object-file compile), which succeeds.
- [ ] **Runtime tests**: Compile and run small `.star` programs, assert their output.
- [ ] **Fuzz testing**: Fuzz the lexer and parser with random inputs to find panics.

LATEST:
### Verified the codegen fixes from the previous `LATEST:` section
- `star build examples/player.star` now emits IR that `clang.exe -c` compiles to an object file cleanly (exit 0). The `SelfExpr` pointer-load, f-string printf lowering, `print` intrinsic, and `load`/`store`/`getelementptr` formatting are all confirmed valid. The only remaining `star build` failure is the linker being unable to find MSVC system libs — an environment/toolchain issue, not a codegen defect.
- `cargo build` is warning-free (the dead `check_param`/`sym_ty` methods are gone) and all 6 tests pass.

### Generalized struct field-index resolution in `src/codegen.rs`
- Added a `struct_fields: HashMap<String, Vec<String>>` map to `Codegen`, populated in `emit_struct_decl` from each `TypedStructDef`'s declared field order.
- Rewrote `field_index` to look up a field's position from that map instead of the previously hardcoded `"Player" => ["health", "position", "name"]` table. Field access (`obj.field`) now works for **any** declared struct, and reports `no field ... on ...` / `unknown struct ...` errors correctly.
- Verified: `cargo build` clean, 6 tests pass, regenerated `examples/player.ll` still compiles with `clang -c` (exit 0).