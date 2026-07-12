# Star Compiler — Next Steps
1. Complete Priority Roadmap

## Priority Roadmap (derived from current_status.md suitability analysis)

Ordered biggest win → smallest, where "win" = how much it unblocks writing useful
programs relative to implementation effort.

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

Bug-checking round (2026-07-11):

Fixed — method calls on any non-`Ident` receiver produced invalid IR: `Codegen::emit_call_expr`'s method-call path resolved its receiver pointer through a bespoke `receiver_name`+`sym_ptr` combo that only recognized a bare local-variable identifier; every other receiver shape (`self`, a nested field access, a list-index/call-result rvalue) fell through to the literal string `"%undef"`, which only failed at the `clang` step ("use of undefined value '%undef'"). This broke the ordinary OO idiom of one method calling another through `self` (`self.bump()` from inside another method), plus `obj.inner.method()` and `list[i].method()`-style chained calls — nothing in `tests/frontend.rs` exercised any of these. Fixed by routing through the existing `Codegen::emit_place`, which already correctly resolves all of these receiver shapes (including spilling an arbitrary rvalue into a fresh alloca). Regression tests: `runtime_method_call_through_self_end_to_end`, `runtime_method_call_on_nested_field_receiver_end_to_end`, `runtime_method_call_on_list_index_receiver_end_to_end`.

Fixed — builtin calls had no argument count/type validation: unlike ordinary/extern-fn calls (`Checker::check_call_args`), builtin calls (`file_open`, `dot`, `clamp`, `is_null`, ...) are dispatched by name via `builtin_return_ty` and previously had zero argument validation beyond `print`/`println`'s own special case. Several builtin codegen functions (`emit_abs`/`emit_dot`/`emit_clamp`/`emit_lerp`/`emit_file_open`/...) `untag` one argument's register using *another* argument's inferred type, so a caller passing an unexpected type (`file_open(42, 3.5)`, `clamp("x", 1, 5)`, `dot(v2, v3)`) type-checked cleanly and only failed at the `clang` step with a confusing, mislocated error. Added `Checker::check_builtin_call_args`, covering every builtin's real arity/type expectations (permissive where the codegen genuinely is, e.g. `min`/`max`'s per-argument int-or-float promotion). Also converted two existing file-I/O arity tests (`codegen_file_open_reports_missing_argument`/`codegen_file_write_reports_missing_argument`) from "caught only at codegen" to `checker_rejects_*` now that they're caught earlier, and added new tests for the type-mismatch cases this closes.

Fixed — `List<T>` had no memory ownership model (copy-on-write RC, 2026-07-11):

`Ty::List`'s value used to be a plain `{data, len, cap}` struct copied by bit value on every `let`/reassignment (no RC indirection, unlike `Str`), so `let b = a` made `a`/`b` alias the same `malloc`'d buffer; `push`'s grow path freed the old buffer and repointed only the pushed-into variable's fields, leaving the other alias's `data` pointer dangling (a real, confirmed use-after-free). Separately, `contains_rc(List<T>)` only recursed into the *element* type, so a list of non-RC elements (`List<i32>`, ...) was never `track_owned` and its buffer leaked unconditionally.

Decision: after weighing RC-sharing (like `Str`, reference semantics), deep-copy-on-assignment (value semantics, O(n) copies), and copy-on-write against each other, went with **copy-on-write**: `List<T>` now lowers to a reference-counted `i8*` object pointer, the same allocation shape `Str` already uses (`star_rc_alloc`/`retain`/`release`, reused verbatim), pointing at a heap payload `{ T* data, i64 len, i64 cap }`. `let b = a` is an O(1) refcount bump; any *mutation* (`push`, `pop`, index-assignment) goes through a new `Codegen::emit_list_ensure_unique` gate first, which clones the buffer (mallocing a fresh one, `memcpy`ing the live prefix, retaining any RC-bearing elements) whenever the refcount shows more than one owner — so mutating one binding is never observable through another, while non-mutating copies stay free. This matches the ownership semantics the type already documented, without `List<T>` overlapping what `GenRef<T>`'s shared arena is for.

`contains_rc(Ty::List(_))` is now unconditionally `true` (was gated on the element type), fixing the leak for non-RC element types too — a `List<T>`'s own buffer is always released now, via a lazily-generated, per-element-type `list_release_<mangled>` thunk (`Codegen::list_release_thunk_operand`, mirrors the closure `_release_env` thunk pattern) that frees the buffer and, only if the element type carries RC content, loops releasing each element first.

One bug caught only by manually rebuilding and running the example binaries (the pre-existing `runtime_lists_end_to_end` test was silently running a *stale* checked-in `.exe` that predated this change): reading `.len()`/`[i]` on a list that was constructed but never mutated (`List<i32>()`, still `null`) dereferenced through the null object pointer and segfaulted. Fixed by giving the read path (`Codegen::list_fields`) its own null-guarded branch (`data = null, len = 0` via `phi` when the object pointer is null), distinct from the mutating path (`list_fields_mut`), which already gets a guaranteed-non-null object from `emit_list_ensure_unique`.

Regression tests: `runtime_list_cow_push_does_not_corrupt_alias_end_to_end` (the original UAF repro), `runtime_list_cow_index_assignment_diverges_end_to_end`, `runtime_list_cow_pop_diverges_end_to_end`, `runtime_list_cow_clone_retains_str_elements_end_to_end`, `codegen_list_of_int_is_released_at_scope_exit`. Rewrote the codegen-IR-shape tests that asserted on the old inline-struct representation (`codegen_list_new_is_null` (renamed), `codegen_list_of_str_release_uses_runtime_loop`, `codegen_list_of_vec2_uses_native_vector_element`). Rebuilt and manually re-verified all four `List<T>`-using example binaries (`lists.exe`, `rc_strings.exe`, `str_fixes.exe`, `rc_closures.exe`) against the new codegen, not just the test suite.

Fixed — closures capturing `self` by pointer could dangle from any local struct, not just `frame:`-scoped ones (2026-07-11):

`src/types/frame_analysis.rs`'s escape analysis previously only tracked `let`-bindings declared inside a `frame:` block (`frame_locals`); a method returning a closure that captures `self` (always by pointer — `Codegen::captured_value_llvm_ty`) called on an ordinary function-local struct or a by-value parameter had the exact same dangling-pointer problem once that closure escaped the function, but sailed straight past the check since neither kind of local was tracked at all.

Investigated whether any receiver shape *is* safe to exempt (the "arena `GenRef`" concern the bug write-up raised) by reading `Codegen::emit_place`: every receiver shape other than a bare local/`self`/nested field access — including a `GenRef` dereference — is spilled into a *fresh, function-scoped* alloca before its address is handed to the callee, so there is no receiver shape in the current codegen whose pointer outlives the enclosing function. That ruled out a narrower exemption-based fix.

Fix: added a second, broader tracking set (`local_structs`) alongside the existing `frame_locals`, seeded with every by-value `Ty::Named` parameter (`self` itself excluded — its safety is the *caller's* responsibility, independently checked when the caller's own body is analyzed) and every `let`-bound struct local regardless of frame-ness. Deliberately kept `local_structs` separate from `frame_locals` rather than merging them: the existing `Assign`/`Return`/tail/`Spawn` checks for a *plain* (non-closure) struct value stay scoped to `frame_locals` only, since an ordinary struct's value is always a safe, independent copy when returned/assigned — broadening those to ordinary locals would have rejected sound, extremely common code (`let p = Point(1,2); return p`). Only the closure-escaping-through-a-method-call check (the `TypedExpr::Call` arm) consults the broader `local_structs` set.

Regression tests: `rejects_closure_capturing_plain_local_self_escaping_via_return` (the todo.md repro), `rejects_closure_capturing_by_value_param_self_escaping_via_return`, `accepts_closure_capturing_plain_local_self_used_within_same_function` (using the closure without escaping stays legal), `accepts_returning_plain_local_struct_by_value` (guards against the over-rejection risk the write-up flagged).

Minimal OS surface: argv + env vars (2026-07-11):

Three new builtins -- `args() -> List<str>`, `env_get(name: str) -> str`, `env_set(name: str, value: str) -> bool`.

`args()`: the OS/CRT always calls the real, linked `main` with `argc`/`argv` regardless of what Star's own `fn main()` declares (every existing program declares it with no parameters) -- tried reading them via mingw's documented `__argc`/`__argv` CRT globals first (would have needed zero changes to `main`'s own codegen), but confirmed by hand-compiling a standalone `.ll` that this toolchain's linker doesn't export them (`undefined symbol: __argc`/`__argv`). Went with the other standard approach instead: `Codegen::emit_fn`'s `is_main` special case now always emits `i32 @main(i32 %.argc, i8** %.argv)` (overriding Star `fn main()`'s own, always-empty declared parameter list) and stores both into new globals `@star.argc`/`@star.argv` in `main`'s entry block, confirmed working the same way. `emit_args` (`src/codegen/list.rs`, alongside the rest of `List<T>`'s construction logic since it needs the same private payload/release-thunk helpers `emit_list_lit` uses) then builds an ordinary `List<str>` from them at call time, duplicating each `argv[i]` into a fresh owned `str` (argv's C strings have no RC header) the same way `emit_ptr_to_str` bridges any other foreign `char*`. Includes `argv[0]` (the program path), matching the OS/CRT's own argv convention. This only changes `main`'s own generated IR -- every other function's codegen, and every existing example's compiled behavior, is unaffected (confirmed: the full pre-existing test suite, including every `Command::new("examples/*.exe")` test that runs a *pre-built, checked-in* binary rather than recompiling, still passes unmodified).

`env_get`/`env_set` (`src/codegen/os.rs`, new module): thin wrappers over `getenv`/`_putenv` (both hand-verified linkable via a standalone `.ll` first, alongside the `__argc`/`__argv` experiment above). `env_get` copies `getenv`'s result into a fresh owned `str` (same bridging reasoning as `args()`), yielding `""` for an unset variable rather than a null `ptr` -- extends `file_read`/`read_line`'s established "empty value on nothing to read" EOF convention to "variable absent" rather than introducing an Option/Result type Star doesn't have. `env_set` builds a transient `"NAME=VALUE"` buffer (plain `malloc`, freed right after the call -- not `star_rc_alloc`'d, since nothing keeps a reference to it once `_putenv` returns, per its documented copy-into-the-process-environment-block behavior) and returns whether the call reported success.

Since `getenv`/`_putenv` are now unconditionally `declare`d by `Codegen::emit_builtins` (same as every other CRT symbol a builtin might need), both were added to `RESERVED_RUNTIME_SYMBOLS` -- an `extern "C" fn getenv` would otherwise collide with the compiler's own `declare`. This broke `examples/extern_ffi.star`'s pre-existing FFI demo (it used `extern "C" fn getenv` to show a `str -> ptr` foreign call) and two tests in `tests/frontend.rs` that also declared `getenv` directly; all three were switched to `strstr` (haystack/needle `str` args, `ptr` return -- same demonstration shape, and incidentally drops a test dependency on the host's `PATH` env var being meaningfully set).

Regression tests: checker coverage for all three builtins' return types and arg-count/type validation (`checks_os_surface_builtin_return_types`, `checker_rejects_args_with_arguments`, `checker_rejects_env_get_wrong_arg_count`, `checker_rejects_env_get_non_str_arg`, `checker_rejects_env_set_wrong_arg_count`, `checker_rejects_env_set_non_str_args`, `extern_fn_rejects_getenv_as_reserved_name`), a codegen-shape test for `main`'s forced `argc`/`argv` signature (`codegen_main_accepts_argc_argv_params`), and end-to-end runtime tests covering `args()` with/without extra argv entries (`runtime_args_includes_program_path_and_extra_args_end_to_end`, `runtime_args_has_only_program_path_when_no_extra_args_end_to_end`), `env_get` against both a missing and a preset-in-the-real-environment variable (`runtime_env_get_missing_var_returns_empty_string_end_to_end`, `runtime_env_get_reads_preset_environment_variable_end_to_end`), and `env_set` round-tripping and overwriting an existing value (`runtime_env_set_round_trip_end_to_end`, `runtime_env_set_overwrites_existing_value_end_to_end`). New example `examples/os_surface.star` (built/verified against a real run with extra argv entries) exercises all three builtins together end to end.
