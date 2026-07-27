//! Regression tests for `todo.md` P0 #2: "Struct/array by-value return and
//! by-value parameters still hang or crash `clang` for large aggregates."
//!
//! The array-repeat/struct-literal fix already in `src/codegen/stmt.rs`
//! (`emit_array_repeat_into`/`emit_struct_lit_fields_into`) only ever covered
//! `let x = <array-repeat-or-struct-literal>` built directly into its own
//! binding. Two shapes stayed open: a function *returning* a struct/array by
//! value, and an ordinary (non-`self`) parameter of a struct/array type --
//! both still materialized a whole-aggregate `load`/`store`/`ret`/by-value
//! argument, exactly the shape that reproduces a real `clang` hang/crash
//! once the aggregate is large enough (see `crate::codegen::array::
//! emit_array_repeat_into`'s doc comment for the empirical thresholds).
//!
//! Fixed by `Codegen::is_large_aggregate_ty` gating a pointer-passing
//! convention (mirroring how `self` was already always pointer-passed):
//! a large struct/array parameter arrives as a pointer and is `memcpy`'d
//! into a private local copy (`emit_fn`'s prologue); a large struct/array
//! return type gets a hidden trailing `sret`-style out-pointer (`%.sret`)
//! instead of an ordinary by-value `ret`, and the trailing/`return`ed value
//! is built directly into it via `Codegen::emit_into_ptr` (which itself
//! special-cases a fresh literal, an existing readable place, and a nested
//! call forwarding `%.sret` straight through -- never a whole-aggregate SSA
//! value for any of the three). Ordinary small structs (below
//! `Codegen::LARGE_AGGREGATE_THRESHOLD`) are completely unaffected -- see
//! `is_large_aggregate_ty`'s own doc comment -- which is what keeps e.g.
//! `codegen_self_returned_by_value_loads_struct_not_pointer`
//! (`tests/frontend_generics_monomorphization.rs`) passing unchanged.
//!
//! The codegen-shape/timing tests below use `Driver::codegen` only (no
//! `clang` invocation) with a genuinely huge type (`[u8; 1_000_000]`,
//! mirroring `Checker::MAX_INLINE_LEN`'s own boundary) so a regression shows
//! up as a wrong/missing IR shape or a slow compile, never an actual `clang`
//! hang -- the same safety rationale `codegen_array_repeat_large_n_uses_
//! runtime_loop_not_unrolled` (`tests/frontend_compiler_audit_regressions.rs`)
//! already uses. The runtime (`compile_and_run`) tests use a much smaller
//! but still comfortably-above-threshold size (8192 bytes) so they run fast
//! even if a regression reintroduces a whole-value copy.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Codegen-shape / compile-time-budget tests (no clang) =================

/// A bare trailing struct literal (no `return` keyword -- the natural
/// "constructor function" shape Nova's own motivating use case wants, see
/// `todo.md` P0 #2's own description) with a huge fixed-array field must
/// lower to the `sret` convention: `void`-returning, a trailing `%Big*
/// %.sret` parameter, and the literal built directly into `%.sret` (through
/// `emit_struct_lit_fields_into`, reached via `Codegen::emit_into_ptr`'s
/// `StructLit` arm) -- never a whole-aggregate `ret %Big %v`. Also asserts
/// codegen itself stays near-instant despite the `N=1,000,000` field, the
/// same regression shape `codegen_array_repeat_large_n_uses_runtime_loop_
/// not_unrolled` guards for the array-repeat fix this one extends.
#[test]
fn codegen_large_struct_trailing_literal_return_uses_sret_not_by_value() {
    let src = "struct Big:\n    data: [u8; 1000000]\n    tag: i32\n\n\
               fn make() -> Big:\n    Big(data = [7 as u8; 1000000], tag = 42)\n\
               fn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let start = std::time::Instant::now();
    let ir = Driver::codegen(&typed).expect("should codegen");
    let elapsed = start.elapsed();
    assert!(elapsed.as_secs() < 5, "codegen for a 1,000,000-byte struct return took {:?} -- should be near-instant", elapsed);

    let body = extract_fn_body(&ir, "define void @make(");
    assert!(body.contains("%.sret"), "expected a hidden `%.sret` out-pointer parameter: {}", body);
    assert!(body.contains("ret void"), "an aggregate-returning function must `ret void`: {}", body);
    assert!(!body.contains("ret %Big"), "must never `ret` the struct by value: {}", body);
    assert!(!body.contains("load %Big"), "must never load the whole struct into an SSA value: {}", body);
    assert!(
        !ir.contains("define void @make(%Big %"),
        "the by-value signature shape must not appear anywhere: {}",
        ir
    );
}

/// `return b` where `b` is an existing local (not a fresh literal) must
/// still avoid a whole-aggregate load: `Codegen::emit_into_ptr`'s `Ident`
/// arm resolves `b`'s real storage address and `memcpy`s it into `%.sret`
/// (`Codegen::emit_memcpy_aggregate`) -- a single intrinsic call regardless
/// of size, instead of `load %Big, %Big* ...` + `ret %Big %v`.
#[test]
fn codegen_large_struct_return_of_existing_local_uses_memcpy_not_whole_load() {
    let src = "struct Big:\n    data: [u8; 1000000]\n    tag: i32\n\n\
               fn make() -> Big:\n    let b = Big(data = [7 as u8; 1000000], tag = 42)\n    return b\n\
               fn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let body = extract_fn_body(&ir, "define void @make(");
    assert!(body.contains("@memcpy"), "expected the return-of-an-existing-local path to `memcpy` into `%.sret`: {}", body);
    assert!(body.contains("ret void"), "{}", body);
    assert!(!body.contains("ret %Big"), "must never `ret` the struct by value: {}", body);
    assert!(!body.contains("load %Big,"), "must never load the whole struct into an SSA value: {}", body);
}

/// An ordinary (non-`self`) parameter of a large struct type must be
/// pointer-passed (`%Big* %b`, not `%Big %b`) and copied in via a single
/// `memcpy` in the prologue -- never a whole-aggregate `load`. A plain
/// scalar field read off it (`b.tag`) still works exactly as before (a
/// small, per-field GEP+load, not a whole-struct load).
#[test]
fn codegen_large_struct_param_passed_by_pointer_with_memcpy_copy_in() {
    let src = "struct Big:\n    data: [u8; 1000000]\n    tag: i32\n\n\
               fn touch(b: Big) -> i32:\n    b.tag\n\
               fn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(
        ir.contains("define i32 @touch(%Big* %b)"),
        "expected a pointer-typed parameter, not by-value: {}",
        ir
    );
    let body = extract_fn_body(&ir, "define i32 @touch(");
    assert!(body.contains("@memcpy"), "expected a `memcpy` copy-in for the by-value parameter: {}", body);
    assert!(!body.contains("load %Big,"), "must never load the whole struct into an SSA value: {}", body);
}

/// The same pointer-passing convention applies to a bare `[T; N]` array type
/// used directly as a parameter/return type (not wrapped in a struct) --
/// `Codegen::is_large_aggregate_ty` matches `Ty::Array` directly, and
/// `emit_into_ptr`'s `Ident` arm handles a bare-array trailing value the
/// same way a struct's does.
#[test]
fn codegen_large_array_param_and_return_use_pointers_not_by_value() {
    let src = "fn touch(a: [u8; 1000000]) -> [u8; 1000000]:\n    a\n\
               fn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(
        ir.contains("define void @touch([1000000 x i8]* %a, [1000000 x i8]* %.sret)"),
        "expected both the parameter and the hidden return slot to be pointer-typed: {}",
        ir
    );
    let body = extract_fn_body(&ir, "define void @touch(");
    assert!(body.matches("@memcpy").count() >= 2, "expected a `memcpy` for both the parameter copy-in and the return: {}", body);
    assert!(!body.contains("load [1000000 x i8]"), "must never load the whole array into an SSA value: {}", body);
}

/// A chain of constructor-style calls (`fn make_outer() -> Big: make_inner()`)
/// must forward the caller's `%.sret` straight through as `make_inner`'s own
/// hidden out-pointer argument (`Codegen::emit_into_ptr`'s `Call` arm calling
/// `emit_call_into`) -- zero copies anywhere in `make_outer`'s own body, not
/// even one `alloca %Big`. This is the exact "free-function constructor
/// helper" pattern `todo.md` P0 #2 says Nova's `Memory`/`Screen`/`Cpu`
/// architecture was blocked from using.
#[test]
fn codegen_chained_constructor_calls_forward_sret_with_zero_copies() {
    let src = "struct Big:\n    data: [u8; 1000000]\n    tag: i32\n\n\
               fn make_inner(t: i32) -> Big:\n    Big(data = [7 as u8; 1000000], tag = t)\n\
               fn make_outer(t: i32) -> Big:\n    make_inner(t)\n\
               fn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let body = extract_fn_body(&ir, "define void @make_outer(");
    assert!(
        body.contains("call void @make_inner(") && body.contains("%Big* %.sret)"),
        "expected `%.sret` forwarded directly as `make_inner`'s own out-pointer argument: {}",
        body
    );
    assert!(!body.contains("alloca %Big"), "expected zero copies -- no temp `%Big` alloca at all: {}", body);
    assert!(!body.contains("@memcpy"), "expected zero copies -- no `memcpy` either: {}", body);
}

/// Regression guard for the threshold gate itself: an ordinary small struct
/// returned directly from a *free function* (not just a `self`-returning
/// method, already covered by `codegen_self_returned_by_value_loads_struct_
/// not_pointer` in `tests/frontend_generics_monomorphization.rs`) must keep
/// the pre-existing by-value convention untouched -- no `%.sret`, no
/// `memcpy`. Locks in that `Codegen::is_large_aggregate_ty`'s size gate
/// really does leave everything below `LARGE_AGGREGATE_THRESHOLD` alone.
#[test]
fn codegen_small_struct_return_from_free_function_stays_by_value() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\n\
               fn make() -> Point:\n    Point(x = 1, y = 2)\n\
               fn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define %Point @make()"), "small struct return should stay by-value, unmodified: {}", ir);
    let body = extract_fn_body(&ir, "define %Point @make(");
    assert!(body.contains("ret %Point %"), "{}", body);
    assert!(!body.contains(".sret"), "a small struct return must not gain a hidden out-pointer: {}", body);
}

// ===== Runtime end-to-end tests (real clang compile + run) ==================
//
// All use an 8192-byte array field: comfortably above `LARGE_AGGREGATE_
// THRESHOLD` (proving the fix's pointer-passing path is what actually runs),
// but small enough to compile and run instantly even if a regression
// reintroduced a whole-value copy at this size.

const BIG_SRC_PREFIX: &str = "struct Big:\n    mut data: [u8; 8192]\n    mut tag: i32\n\n";

/// A free-function "constructor" returning a large struct by value, then
/// read back through an ordinary local -- the core motivating scenario from
/// `todo.md` P0 #2 (Nova wanting a real constructor function instead of one
/// giant literal at a single call site). Checks the first and last array
/// slots plus the scalar field, so an off-by-one in the `memcpy`/`sret`
/// wiring would be caught.
#[test]
fn runtime_large_struct_returned_by_value_from_constructor_fn_end_to_end() {
    let src = format!(
        "{}fn make(t: i32) -> Big:\n    return Big(data = [7 as u8; 8192], tag = t)\n\
         fn main():\n    let b = make(42)\n    println(f\"{{b.tag}} {{b.data[0]}} {{b.data[8191]}}\")\n",
        BIG_SRC_PREFIX
    );
    let output = compile_and_run("large_struct_returned_by_value", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "42 7 7", "{}", stdout);
}

/// A large struct passed as an ordinary (`mut`) by-value parameter: mutating
/// it inside the callee must *not* be observable through the caller's own
/// binding afterward -- proving the pointer-passing convention still gives
/// real by-value copy semantics (a private `memcpy`'d local), not an
/// accidental aliasing reference, now that the parameter arrives as a
/// pointer instead of a by-value SSA aggregate.
#[test]
fn runtime_large_struct_param_mutation_does_not_affect_caller_end_to_end() {
    let src = format!(
        "{}fn bump(mut b: Big) -> i32:\n    b.tag = b.tag + 1\n    b.data[0] = 99 as u8\n    b.tag\n\
         fn main():\n    let b = Big(data = [7 as u8; 8192], tag = 10)\n    let r = bump(b)\n    \
         println(f\"{{r}} {{b.tag}} {{b.data[0]}}\")\n",
        BIG_SRC_PREFIX
    );
    let output = compile_and_run("large_struct_param_independent_copy", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "11 10 7", "{}", stdout);
}

/// `let b = a` for an existing large-struct local `a` must be a real,
/// independent copy (`TypedStmt::Let`'s new large-aggregate branch, routed
/// through `Codegen::emit_into_ptr`'s `Ident` arm -- a `memcpy`, not a
/// pointer alias): mutating `b` afterward must leave `a` untouched.
#[test]
fn runtime_large_struct_let_copy_of_existing_local_is_independent_end_to_end() {
    let src = format!(
        "{}fn main():\n    let mut a = Big(data = [7 as u8; 8192], tag = 1)\n    let mut b = a\n    \
         b.tag = 99\n    b.data[0] = 55 as u8\n    \
         println(f\"{{a.tag}} {{a.data[0]}} {{b.tag}} {{b.data[0]}}\")\n",
        BIG_SRC_PREFIX
    );
    let output = compile_and_run("large_struct_let_copy_independent", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "1 7 99 55", "{}", stdout);
}

/// A method (not just a free function) returning a large struct by value --
/// `Codegen::emit_call_into`'s method-call branch, exercising the receiver
/// pointer *and* the `sret` out-pointer together in one call.
#[test]
fn runtime_large_struct_method_call_returns_by_value_end_to_end() {
    let src = format!(
        "{}struct Factory:\n    seed: i32\n\n\
         impl Factory:\n    fn make(self) -> Big:\n        return Big(data = [self.seed as u8; 8192], tag = self.seed)\n\n\
         fn main():\n    let f = Factory(seed = 5)\n    let b = f.make()\n    \
         println(f\"{{b.tag}} {{b.data[0]}} {{b.data[8191]}}\")\n",
        BIG_SRC_PREFIX
    );
    let output = compile_and_run("large_struct_method_call_return", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "5 5 5", "{}", stdout);
}

/// A large struct that *also* carries an RC-bearing (`str`) field, round
/// tripped through both a by-value return (constructor) and a by-value
/// parameter (reader), repeated several times -- exercises
/// `Codegen::emit_retain_at`/`track_owned`'s interaction with the new
/// pointer-passing convention (the caller must retain before handing off a
/// pointer, the callee must still release its own private copy at scope
/// exit). A refcounting mistake here (a missing retain, a double release)
/// would surface as a crash or corrupted string content, not just a wrong
/// number, so this also doubles as a memory-safety check for the fix.
#[test]
fn runtime_large_struct_with_rc_field_round_trips_through_return_and_param_end_to_end() {
    let src = "struct Big:\n    data: [u8; 8192]\n    tag: i32\n    label: str\n\n\
               fn make(s: str) -> Big:\n    return Big(data = [1 as u8; 8192], tag = 1, label = s)\n\
               fn read_label(b: Big) -> str:\n    b.label\n\
               fn main():\n    let mut i = 0\n    while i < 20:\n        let b = make(\"hello\")\n        \
               println(read_label(b))\n        i = i + 1\n"
        .to_string();
    let output = compile_and_run("large_struct_rc_field_round_trip", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.trim_end().lines().collect();
    assert_eq!(lines.len(), 20, "{}", stdout);
    assert!(lines.iter().all(|l| *l == "hello"), "every iteration should read back the same label: {}", stdout);
}
