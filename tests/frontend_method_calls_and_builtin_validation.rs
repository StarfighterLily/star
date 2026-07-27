//! Method-call resolution/mangling, builtin arg validation, OS args/env surface
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Method-call receiver resolution =====================================
//
// `Codegen::emit_call_expr`'s method-call path used to resolve a call's
// receiver pointer via a bespoke `receiver_name`+`sym_ptr` combo that only
// recognized a bare local-variable identifier as `base`
// (`obj.method(args)`) -- any other receiver shape silently fell back to
// `String::new()` -> `sym_ptr("")` -> `None` -> the literal string
// `"%undef"` used as the receiver pointer operand, producing invalid LLVM
// IR ("use of undefined value '%undef'") at the `clang` step. This broke
// the very ordinary OO idiom of one method calling another through `self`,
// plus any other non-bare-identifier receiver. Fixed by routing through
// `Codegen::emit_place`, which already correctly resolves `Ident`, `self`,
// nested `Field` accesses, and arbitrary rvalues (spilled into a fresh
// alloca) to a real storage address.

/// A method calling a sibling method through `self` -- the single most
/// ordinary receiver shape after a bare local, and the one that previously
/// produced `%undef` and failed to compile at all.
#[test]
fn runtime_method_call_through_self_end_to_end() {
    let src = concat!(
        "struct Counter:\n",
        "    val: i32\n",
        "impl Counter:\n",
        "    fn bump(self) -> i32:\n",
        "        self.val + 1\n",
        "    fn double_bump(self) -> i32:\n",
        "        self.bump() + self.bump()\n",
        "fn main():\n",
        "    let c = Counter(val = 10)\n",
        "    println(f\"{c.double_bump()}\")\n",
    );
    let output = compile_and_run("method_call_through_self", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "22", "self.bump() + self.bump() on val=10 should be 22: {}", stdout);
}

/// A method call on a nested field access (`obj.inner.method()`) -- another
/// receiver shape `receiver_name` previously couldn't resolve (a `Field`
/// base, not a bare `Ident`).
#[test]
fn runtime_method_call_on_nested_field_receiver_end_to_end() {
    let src = concat!(
        "struct Inner:\n",
        "    val: i32\n",
        "struct Outer:\n",
        "    inner: Inner\n",
        "impl Inner:\n",
        "    fn get(self) -> i32:\n",
        "        self.val\n",
        "fn main():\n",
        "    let o = Outer(inner = Inner(val = 42))\n",
        "    println(f\"{o.inner.get()}\")\n",
    );
    let output = compile_and_run("method_call_on_nested_field", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "42", "{}", stdout);
}

/// A method call chained directly onto a list-index expression
/// (`list[i].method()`) -- a receiver that is neither a bare `Ident` nor a
/// `Field`, so it exercises `emit_place`'s dedicated `ListIndex` arm
/// (`Codegen::emit_list_index_place`) rather than either of its
/// named-storage arms. (Before that arm existed, this fell into the generic
/// fallback -- fine for this particular test since `get` never mutates, but
/// see `runtime_nested_list_index_receiver_push_mutates_through_index_end_to_end`
/// for the mutating case that fallback got wrong.)
#[test]
fn runtime_method_call_on_list_index_receiver_end_to_end() {
    let src = concat!(
        "struct Counter:\n",
        "    val: i32\n",
        "impl Counter:\n",
        "    fn get(self) -> i32:\n",
        "        self.val\n",
        "fn main():\n",
        "    let mut list = List<Counter>()\n",
        "    list.push(Counter(val = 7))\n",
        "    list.push(Counter(val = 9))\n",
        "    println(f\"{list[1].get()}\")\n",
    );
    let output = compile_and_run("method_call_on_list_index", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "9", "{}", stdout);
}

// ===== Method name mangling (per-struct method tables) =====================
//
// Both `Checker::check`'s registration pass and `Codegen::emit_fn` used to
// key every impl method by its *bare* method name alone -- `self.functions`
// (checker) and the emitted LLVM function itself (codegen: `define @{name}`)
// -- shared with every other function/method in the module. Two unrelated
// structs declaring a same-named method (`impl A: fn area(self) -> i32`,
// `impl B: fn area(self, scale: i32) -> i32`) collided: the checker
// type-checked every `.area()` call site against whichever impl happened to
// be registered last (wrong argument/return-type validation, or a
// false-positive arity error on perfectly valid code), and codegen emitted
// two `define @area(...)` globals under the identical LLVM name, which
// clang rejected outright ("invalid redefinition of function") even when
// both methods' signatures happened to agree. Fixed by keying methods
// per-struct: `Checker::methods`/`Codegen::methods`, both keyed by
// `"{struct}#{method}"`, with the emitted LLVM function itself mangled to
// `{struct}__{method}` (`Codegen::emit_fn`'s `owner` parameter).

/// Two unrelated structs declaring a same-named method with *different*
/// arity must not collide: previously this was rejected by the checker with
/// a bogus "expects 1 argument(s), found 0" (validated against whichever
/// impl was registered last in the flat, name-keyed table) even though
/// `a.area()` supplies exactly the right number of arguments for `A::area`.
#[test]
fn checks_same_named_methods_on_different_structs_with_different_arity() {
    let src = concat!(
        "struct A:\n",
        "    x: i32\n",
        "struct B:\n",
        "    y: i32\n",
        "impl A:\n",
        "    fn area(self) -> i32:\n",
        "        return 1\n",
        "impl B:\n",
        "    fn area(self, scale: i32) -> i32:\n",
        "        return scale\n",
        "fn main():\n",
        "    let a = A(5)\n",
        "    println(f\"{a.area()}\")\n",
    );
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "{:?}", Driver::check(&module).err());
}

/// Two unrelated structs declaring a same-named method with the *same*
/// arity/signature shape must still dispatch to the correct implementation
/// (not just type-check) and must not collide as duplicate LLVM globals --
/// previously this failed at the `clang` step with "invalid redefinition of
/// function 'area'" regardless of whether the checker accepted the source.
#[test]
fn runtime_same_named_methods_on_different_structs_dispatch_correctly_end_to_end() {
    let src = concat!(
        "struct A:\n",
        "    x: i32\n",
        "struct B:\n",
        "    y: i32\n",
        "impl A:\n",
        "    fn area(self) -> i32:\n",
        "        return self.x * 2\n",
        "impl B:\n",
        "    fn area(self) -> i32:\n",
        "        return self.y * 100\n",
        "fn main():\n",
        "    let a = A(5)\n",
        "    let b = B(3)\n",
        "    println(f\"a.area={a.area()} b.area={b.area()}\")\n",
    );
    let output = compile_and_run("method_name_collision", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "a.area=10 b.area=300", "{}", stdout);
}

/// Codegen-shape check: an impl method's emitted LLVM function is mangled
/// as `{struct}__{method}`, not the bare method name, so two structs'
/// same-named methods never collide as duplicate `define`s regardless of
/// what a runtime test's specific call sites happen to exercise.
#[test]
fn codegen_impl_method_llvm_name_is_mangled_by_struct() {
    let src = concat!(
        "struct A:\n",
        "    x: i32\n",
        "impl A:\n",
        "    fn area(self) -> i32:\n",
        "        return self.x\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i32 @A__area(%A* %self)"), "{}", ir);
    assert!(!ir.contains("define i32 @area("), "the bare, unmangled method name must never be emitted as a global: {}", ir);
}

// ===== Builtin call argument validation =====================================
//
// `Checker::check_builtin_call_args` validates argument count and types for
// every builtin call -- previously, builtins (dispatched via
// `builtin_return_ty` ahead of the ordinary function table) had *no*
// argument validation at all beyond `print`/`println`'s own special case,
// so a call like `file_open(42, 3.5)` or `clamp("x", 1, 5)` type-checked
// cleanly and only failed later at the `clang` step with a confusing
// "expected value token"/"use of undefined value" error pointing at
// generated IR the user never wrote, since several builtin codegen
// functions (`emit_abs`/`emit_dot`/`emit_clamp`/`emit_lerp`/
// `emit_file_open`/...) `untag` an argument's register using *another*
// argument's inferred type rather than a type of their own choosing.

/// A scalar builtin (`sqrt`) rejects a non-numeric argument at type-check
/// time instead of producing invalid IR at the `clang` step.
#[test]
fn checker_rejects_sqrt_non_numeric_arg() {
    let src = "fn t():\n    sqrt(\"nope\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("sqrt(\"nope\") should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("sqrt") && d.message.contains("numeric")), "{:?}", diags);
}

/// `dot`/`length` are the two "own type" `untag` calls `emit_dot`/
/// `emit_length` make against a single argument's inferred type -- `dot`
/// additionally assumes both arguments share the very same vector type
/// (`emit_dot` untags `b` using `a`'s type), so a `Vec2`/`Vec3` mismatch is
/// exactly the case previously invisible to the checker.
#[test]
fn checker_rejects_dot_with_mismatched_vector_types() {
    let src = "fn t():\n    dot(Vec2(1.0, 2.0), Vec3(1.0, 2.0, 3.0))\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("dot(..) with mismatched vector types should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`dot`") && d.message.contains("same vector type")), "{:?}", diags);
}

/// `clamp(x, lo, hi)` assumes `lo`/`hi` share `x`'s type (`emit_clamp`
/// dispatches on `x`'s type alone, then `untag`s all three the same way) --
/// a `float` bound against an `int` value is exactly the mismatch that
/// previously slipped through to a codegen-level type mismatch.
#[test]
fn checker_rejects_clamp_with_mismatched_bound_types() {
    let src = "fn t():\n    clamp(3, 1.0, 5.0)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("clamp(..) with mismatched bound types should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`clamp`")), "{:?}", diags);
}

/// `min`/`max` are the one deliberately-polymorphic case that must stay
/// permissive: `emit_minmax` promotes whichever operand is `int` to `float`
/// via each argument's own inferred type (not a shared expected type), so a
/// mixed `int`/`float` call is valid and must still type-check.
#[test]
fn checker_accepts_min_with_mixed_int_and_float_args() {
    // `min`/`max` preserve the *first* argument's type (see
    // `builtin_return_ty`), so `min(3, 2.5)` is `int`-typed even though its
    // second argument is `float` -- that's the pre-existing, deliberate
    // polymorphism this test guards against becoming over-strict, not a
    // claim about the result's own type.
    let src = "fn t() -> i32:\n    min(3, 2.5)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("min(int, float) is valid and should type-check");
}

/// `is_null`/`ptr_to_str`/`file_close`/`file_read`/`file_read_line` all
/// expect a `ptr` argument -- passing an ordinary `int` is exactly the
/// misuse `Codegen::untag`'s silent no-op fallback (`unwrap_or(s)`, see its
/// doc comment) would otherwise smuggle through as invalid IR.
#[test]
fn checker_rejects_is_null_non_ptr_arg() {
    let src = "fn t():\n    is_null(42)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("is_null(42) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`is_null`") && d.message.contains("ptr")), "{:?}", diags);
}

/// `file_open(path, mode)` expects both arguments to be `str` -- this is
/// the concrete repro that motivated adding builtin argument validation at
/// all: `file_open(42, 3.5)` previously type-checked cleanly and only
/// failed at the `clang` step with "expected value token" pointing at
/// `call i8* @fopen(i8* i32 42, i8* float ...)`.
#[test]
fn checker_rejects_file_open_wrong_arg_types() {
    let src = "fn t():\n    file_open(42, 3.5)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("file_open(42, 3.5) should fail to type-check") };
    assert_eq!(diags.iter().filter(|d| d.message.contains("`file_open`")).count(), 2, "both arguments are wrong: {:?}", diags);
}

/// `file_write(handle, data)` expects `ptr` then `str` -- swapping them
/// (a plausible mistake, both are single-argument-shaped) should be
/// rejected rather than silently misdirecting `fwrite`'s buffer/length
/// operands.
#[test]
fn checker_rejects_file_write_swapped_arg_types() {
    let src = "fn t():\n    let h = file_open(\"x.txt\", \"w\")\n    file_write(\"data\", h)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("file_write with swapped argument types should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`file_write`")), "{:?}", diags);
}

/// Every valid file-I/O call shape still type-checks cleanly -- a sanity
/// check that `check_builtin_call_args` didn't become so strict it rejects
/// legitimate use, run alongside the existing `runtime_file_*_end_to_end`
/// tests that already exercise these calls end-to-end.
#[test]
fn checker_accepts_well_typed_file_io_calls() {
    let src = "fn t():\n    let h = file_open(\"x.txt\", \"w\")\n    file_write(h, \"data\")\n    file_close(h)\n    let r = file_open(\"x.txt\", \"r\")\n    let a = file_read(r)\n    let b = file_read_line(r)\n    let e = file_exists(\"x.txt\")\n    file_close(r)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("well-typed file I/O calls should type-check");
}

// ===== Minimal OS surface: args()/env_get/env_set (todo.md #2) =============

/// `args()`/`env_get`/`env_set` resolve to proper (non-`unknown`) types
/// through the checker, same as every other builtin -- `args()` returns
/// `List<str>` (not just `str`/`bool`), so this also exercises
/// `builtin_return_ty` producing a `Ty::List` for a builtin with no
/// arguments to infer an element type from.
#[test]
fn checks_os_surface_builtin_return_types() {
    let src = "fn t():\n    let a: List<str> = args()\n    let s: str = env_get(\"PATH\")\n    let b: bool = env_set(\"X\", \"Y\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("well-typed args()/env_get/env_set calls should type-check");
}

/// `args()` takes no arguments -- passing any is rejected by
/// `Checker::check_builtin_call_args`, same as `read_line()`/`rand()`.
#[test]
fn checker_rejects_args_with_arguments() {
    let src = "fn t():\n    args(1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("args(1) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`args` expects 0 argument(s), found 1")), "{:?}", diags);
}

/// `env_get(name)` expects exactly 1 `str` argument.
#[test]
fn checker_rejects_env_get_wrong_arg_count() {
    let src = "fn t():\n    env_get()\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("env_get() should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`env_get` expects 1 argument(s), found 0")), "{:?}", diags);
}

/// `env_get(42)` -- a non-`str` argument -- is rejected rather than
/// smuggled through to `emit_env_get`'s `emit_raw_str_ptr`, which assumes
/// its argument is already a `str`.
#[test]
fn checker_rejects_env_get_non_str_arg() {
    let src = "fn t():\n    env_get(42)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("env_get(42) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`env_get` expects a `str` argument")), "{:?}", diags);
}

/// `env_set(name, value)` expects exactly 2 arguments.
#[test]
fn checker_rejects_env_set_wrong_arg_count() {
    let src = "fn t():\n    env_set(\"X\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("env_set(\"X\") should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`env_set` expects 2 argument(s), found 1")), "{:?}", diags);
}

/// `env_set(name, value)` expects both arguments to be `str` -- swapping in
/// an `int` for either is rejected rather than reaching `emit_env_set`'s
/// `strlen`/`strcpy` calls with the wrong operand type.
#[test]
fn checker_rejects_env_set_non_str_args() {
    let src = "fn t():\n    env_set(1, 2)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("env_set(1, 2) should fail to type-check") };
    assert_eq!(diags.iter().filter(|d| d.message.contains("`env_set`")).count(), 2, "both arguments are wrong: {:?}", diags);
}

/// `getenv`/`_putenv` -- the real CRT symbols `env_get`/`env_set` lower to
/// (see `crate::codegen::os`) -- are reserved runtime symbol names, same as
/// `puts`/`malloc`/etc: an `extern "C" fn getenv` would collide with the
/// `declare i8* @getenv(i8*)` `Codegen::emit_builtins` always emits.
#[test]
fn extern_fn_rejects_getenv_as_reserved_name() {
    let src = "extern \"C\" fn getenv(name: str) -> ptr\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("extern fn named `getenv` should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("compiler always declares internally")), "{:?}", diags);
}

/// `pthread_create`/`sem_wait` -- the `Target::LinuxGnu` counterparts of
/// `CreateThread`/`WaitForSingleObject` (see `crate::codegen::platform`) --
/// are reserved runtime symbol names too, even though this check runs at
/// type-check time, before a build's `--target` is known: a program checked
/// once and later built for either target must not be able to declare an
/// `extern "C" fn` that collides with either backend's internal `declare`s.
#[test]
fn extern_fn_rejects_pthread_create_as_reserved_name() {
    let src = "extern \"C\" fn pthread_create(a: ptr, b: ptr, c: ptr, d: ptr) -> int\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("extern fn named `pthread_create` should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("compiler always declares internally")), "{:?}", diags);
}

#[test]
fn extern_fn_rejects_sem_wait_as_reserved_name() {
    let src = "extern \"C\" fn sem_wait(s: ptr) -> int\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("extern fn named `sem_wait` should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("compiler always declares internally")), "{:?}", diags);
}

/// `main`'s real, OS-called LLVM signature always accepts `i32 %.argc, i8**
/// %.argv` -- regardless of Star `fn main()`'s own declared (empty)
/// parameter list -- so `args()` can read the real process argv from
/// anywhere, not just from an explicitly-threaded parameter. See
/// `Codegen::emit_fn`'s `is_main` special case.
#[test]
fn codegen_main_accepts_argc_argv_params() {
    let src = "fn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i32 @main(i32 %.argc, i8** %.argv)"), "{}", ir);
    let main_body = extract_fn_body(&ir, "define i32 @main(");
    assert!(main_body.contains("store i32 %.argc, i32* @star.argc"), "{}", main_body);
    assert!(main_body.contains("store i8** %.argv, i8*** @star.argv"), "{}", main_body);
}

/// `args()` includes `argv[0]` (the program path) plus every extra
/// command-line argument the process was actually launched with, in order
/// -- the same convention the underlying OS/CRT argv itself uses (see
/// `Codegen::emit_args`'s doc comment).
#[test]
fn runtime_args_includes_program_path_and_extra_args_end_to_end() {
    let src = "fn main():\n    let a = args()\n    println(f\"{a.len()}\")\n    println(a[1])\n    println(a[2])\n";
    let output = compile_and_run_with("args_extra", src, &["alpha", "beta"], &[]);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["3", "alpha", "beta"], "argv[0] + 2 extra args: {}", stdout);
}

/// With no extra command-line arguments, `args()` still has exactly one
/// element -- `argv[0]`, the program's own path -- never an empty list.
#[test]
fn runtime_args_has_only_program_path_when_no_extra_args_end_to_end() {
    let src = "fn main():\n    let a = args()\n    println(f\"{a.len()}\")\n";
    let output = compile_and_run_with("args_none", src, &[], &[]);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "1", "argv[0] alone: {}", stdout);
}

/// `env_get` on a variable that was never set yields `""` (empty `str`),
/// matching `read_line`/`file_read`'s established EOF convention, rather
/// than a null `ptr` or a crash.
#[test]
fn runtime_env_get_missing_var_returns_empty_string_end_to_end() {
    let src = "fn main():\n    let missing = env_get(\"STAR_TEST_DEFINITELY_UNSET_VAR_ABC123\")\n    println(f\"[{missing}]\")\n";
    let output = compile_and_run_with("env_get_missing", src, &[], &[]);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "[]", "{}", stdout);
}

/// `env_get` reads a variable that was actually set in the process's
/// environment before it started (not just one `env_set` from within the
/// same run) -- exercises the real `getenv` round trip end to end, not just
/// the same-process `env_set` -> `env_get` path.
#[test]
fn runtime_env_get_reads_preset_environment_variable_end_to_end() {
    let src = "fn main():\n    println(env_get(\"STAR_TEST_PRESET_VAR\"))\n";
    let output = compile_and_run_with("env_get_preset", src, &[], &[("STAR_TEST_PRESET_VAR", "hello from the environment")]);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "hello from the environment", "{}", stdout);
}

/// `env_set` reports success (`true`) and the variable it just set is
/// immediately visible to `env_get` within the same process -- the
/// `_putenv`-backed round trip `emit_env_set`'s doc comment describes.
#[test]
fn runtime_env_set_round_trip_end_to_end() {
    let src = "fn main():\n    let ok = env_set(\"STAR_TEST_ROUND_TRIP_VAR\", \"round trip value\")\n    println(f\"{ok}\")\n    println(env_get(\"STAR_TEST_ROUND_TRIP_VAR\"))\n";
    let output = compile_and_run_with("env_set_round_trip", src, &[], &[]);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "round trip value"], "{}", stdout);
}

/// `env_set` on an already-set variable overwrites its value (rather than,
/// say, silently failing or appending) -- distinguishes "set" from
/// "set-if-absent" semantics.
#[test]
fn runtime_env_set_overwrites_existing_value_end_to_end() {
    let src = "fn main():\n    let ok = env_set(\"STAR_TEST_OVERWRITE_VAR\", \"new value\")\n    println(f\"{ok}\")\n    println(env_get(\"STAR_TEST_OVERWRITE_VAR\"))\n";
    let output = compile_and_run_with("env_set_overwrite", src, &[], &[("STAR_TEST_OVERWRITE_VAR", "old value")]);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "new value"], "{}", stdout);
}

/// Regression test for a use-after-free previously in `emit_env_set`: it
/// built a `"NAME=VALUE"` buffer, handed it to `_putenv`, then immediately
/// `free`d it -- but (unlike `_putenv_s`) `_putenv` stores the exact pointer
/// it's given directly in the process's environment block rather than
/// copying it, so any later heap activity reusing that freed block corrupted
/// the environment entry silently. Calls `env_set` on 20 different
/// variables, each followed by unrelated heap churn (building/filling a
/// fresh `List<str>`) that would be likely to reuse a freed `env_set` buffer
/// if the bug were still present, then reads every variable back -- every
/// value must still be exactly what was set.
#[test]
fn runtime_env_set_survives_heap_churn_after_repeated_calls_end_to_end() {
    let src = "fn main():\n    let mut i: i32 = 0\n    while i < 20:\n        let name = f\"STAR_TEST_ENV_STRESS_{i}\"\n        let val = f\"value_{i}\"\n        env_set(name, val)\n        let mut xs: List<str> = List<str>()\n        let mut j: i32 = 0\n        while j < 50:\n            xs.push(f\"churn_{j}\")\n            j += 1\n        i += 1\n    i = 0\n    while i < 20:\n        let name = f\"STAR_TEST_ENV_STRESS_{i}\"\n        println(env_get(name))\n        i += 1\n";
    let output = compile_and_run("env_set_survives_heap_churn", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    let expected: Vec<String> = (0..20).map(|i| format!("value_{}", i)).collect();
    assert_eq!(lines, expected, "{}", stdout);
}

/// An f-string used as an ordinary value (bound to a `let`, not passed
/// directly as `print`/`println`'s sole argument) must actually substitute
/// its interpolated values, not just return the raw, unformatted
/// `"...%d...\0"`-style template pointer. Before this was fixed,
/// `Codegen::emit_expr`'s `TypedExpr::FStr` arm built the format string and
/// evaluated each hole's expression into `arg_vals` but never consumed
/// `arg_vals` at all -- it returned the bare format-string pointer, so `s`
/// held literal `%d` bytes and printing it later fed `printf` a format
/// string with unsupplied varargs, segfaulting. This only affected the
/// non-print-argument path; `println(f"...")`/`print(f"...")` directly had
/// their own separate, correct codegen in `emit_print_like` all along.
#[test]
fn runtime_fstring_bound_to_let_then_printed_end_to_end() {
    let src = "fn main():\n    let x = 42\n    let s = f\"x is {x}!\"\n    print(s)\n";
    let output = compile_and_run("fstring_let_then_print", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout, "x is 42!", "f-string bound to a `let` must substitute its hole and add no extra newline: {}", stdout);
}

/// The same bug, reached via a function return instead of a `let` --
/// confirms the fix isn't specific to one particular non-print consumer of
/// an f-string value.
#[test]
fn runtime_fstring_returned_from_function_end_to_end() {
    let src = "fn make_msg(x: i32) -> str:\n    return f\"value={x}\"\n\nfn main():\n    let s = make_msg(7)\n    println(s)\n";
    let output = compile_and_run("fstring_returned_from_fn", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "value=7", "{}", stdout);
}

/// Every interpolation-hole type this codegen path supports (`i32`, `float`,
/// `bool`, `str`) substitutes correctly when the f-string is materialized as
/// a value rather than printed directly -- `bool` in particular needs
/// `emit_bool_str`'s "true"/"false" conversion, not a raw `%p`-formatted `i1`.
#[test]
fn runtime_fstring_value_all_hole_types_end_to_end() {
    let src = "fn main():\n    let b = true\n    let f = 3.5\n    let name = \"star\"\n    let s = f\"b={b} f={f} name={name}\"\n    println(s)\n";
    let output = compile_and_run("fstring_value_all_hole_types", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "b=true f=3.500000 name=star", "{}", stdout);
}
