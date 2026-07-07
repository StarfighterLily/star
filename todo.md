# Star Compiler — Next Steps

## Immediate: Verify: Fix Codegen to Produce Valid LLVM IR
The `LATEST:` section below claims to have fixed this issue but requires verification. Below is the issue reported:

The canonical example emits IR that is structurally correct but has several semantic errors that prevent `clang.exe` from compiling it.

- [ ] **`SelfExpr` type resolution**: `self` in a method body should resolve to the concrete struct type (e.g., `Player`) rather than `Self`. The type checker now passes the struct type down to method parameters, but codegen's `expr_ty` for `SelfExpr` reads from the symbol table which stores the parameter's declared type. Fix: use the receiver parameter's type directly.
- [ ] **LLVM `load`/`store` formatting**: The IR currently emits `load %unknown, %unknown %ptr` because `llvm_ty` returns `%unknown` for `Ty::Named("unknown")`. Fix: ensure all type lookups resolve correctly so the type string is valid (e.g., `load i32, i32* %ptr`).
- [ ] **`getelementptr` on `self` pointer**: `self` is already a pointer to the struct, but `emit_expr` for `SelfExpr` returns the alloca pointer (pointer-to-pointer). The GEP then operates on the wrong level of indirection. Fix: load the struct pointer from the alloca first, then GEP into it.
- [ ] **Match arm body codegen**: The match lowering emits `print(f"...")` calls but the `print` function and f-string printf lowering are not implemented. Add a `print` intrinsic that calls `printf` with the formatted string.
- [ ] **`check_param` dead code warning**: Remove the unused `check_param` method from `types.rs`.

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

- [ ] **`if`/`else` expressions**: Parser support exists but codegen is missing. Lower to `select` or branch/phi.
- [ ] **`for`/`while` loops**: Parser support exists. Codegen: `while` → branch-to-header pattern; `for` → desugar to `while`.
- [ ] **Free functions**: Top-level `fn` items (outside impl blocks) are parsed and type-checked but codegen needs testing.
- [ ] **Standard library**: Built-in `print`, `println`, basic math functions, string operations.
- [ ] **Error messages**: Improve diagnostic quality with suggestions and notes.

## Testing

- [ ] **Codegen test suite**: Add integration tests that compile `.star` files to `.ll` and verify the IR with `llc` or `clang -c`.
- [ ] **Runtime tests**: Compile and run small `.star` programs, assert their output.
- [ ] **Fuzz testing**: Fuzz the lexer and parser with random inputs to find panics.

LATEST:
### Changes to `src/types.rs`:

1. __Added `TypedFStrExpr` enum__ with `Literal(String)` and `Expr(Box<TypedExpr>)` variants for typed f-string components
2. __Changed `TypedExpr::SelfExpr`__ from `SelfExpr(Span)` to `SelfExpr(Ty, Span)` to carry the concrete struct type
3. __Added `FStr(Vec<TypedFStrExpr>, Ty, Span)`__ variant to `TypedExpr` for typed f-strings
4. __Updated `into_ty`__ to handle the new variants
5. __Fixed `infer_expr`__ to pass `vars` context through to nested expressions, enabling `SelfExpr` to resolve to the concrete struct type via `vars.get("self")`
6. __Updated `resolve_field_type`__ to match on `SelfExpr(Ty::Named(n), _)` for field resolution on self
7. __Removed dead `check_param` method__

### Changes to `src/codegen.rs`:

1. __Fixed `SelfExpr` emission__ to load the struct pointer from the alloca (fixes the pointer-to-pointer issue in GEP)
2. __Added f-string `FStr` emission__ that creates printf-compatible format strings with `%d`/`%f`/`%s` placeholders
3. __Added `print(...)` intrinsic handling__ that lowers to `@printf` calls in LLVM IR
4. __Removed dead `sym_ty` method__
