//! `extern "C"` FFI
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== extern "C" FFI =========================================================
//
// `extern "C" fn name(params) -> ret` declares a foreign C symbol (no body)
// that codegen lowers to a bare LLVM `declare`, letting Star bind existing C
// libraries instead of requiring every capability to be hand-implemented
// inside the compiler (see todo.md's "Next Steps" §1). Parameter/return
// types are restricted to `int`/`float`/`ptr` (plus `str`, parameter-only)
// -- see `Checker::check_extern_fn`.

/// `extern "C" fn abs(x: int) -> int` parses to a single `Item::ExternFn`
/// with the ABI string, name, params, and return type all captured.
#[test]
fn extern_fn_parses_signature() {
    let src = "extern \"C\" fn abs(x: int) -> int\n";
    let module = Driver::parse(src).expect("should parse");
    assert_eq!(module.items.len(), 1);
    match &module.items[0] {
        Item::ExternFn(e) => {
            assert_eq!(e.abi, "C");
            assert_eq!(e.sig.name, "abs");
            assert_eq!(e.sig.params.len(), 1);
            assert_eq!(e.sig.params[0].name, "x");
            assert_eq!(e.sig.params[0].ty, Some(Type::Named("int".into())));
            assert_eq!(e.sig.ret, Some(Type::Named("int".into())));
        }
        other => panic!("expected Item::ExternFn, found {:?}", other),
    }
}

/// A no-return-type, no-argument extern declaration (`extern "C" fn
/// foo()`) parses with an empty param list and no return type -- the same
/// shape a `void` C function needs.
#[test]
fn extern_fn_parses_no_args_no_return() {
    let src = "extern \"C\" fn foo()\n";
    let module = Driver::parse(src).expect("should parse");
    match &module.items[0] {
        Item::ExternFn(e) => {
            assert!(e.sig.params.is_empty());
            assert_eq!(e.sig.ret, None);
        }
        other => panic!("expected Item::ExternFn, found {:?}", other),
    }
}

/// Two extern declarations back to back parse as two separate items -- the
/// body-less grammar must end exactly at the line, not swallow (or get
/// confused by) whatever follows.
#[test]
fn extern_fn_two_declarations_back_to_back() {
    let src = "extern \"C\" fn abs(x: int) -> int\nextern \"C\" fn atoi(s: str) -> int\nfn main():\n    println(\"ok\")\n";
    let module = Driver::parse(src).expect("should parse");
    assert_eq!(module.items.len(), 3);
    assert!(matches!(&module.items[0], Item::ExternFn(e) if e.sig.name == "abs"));
    assert!(matches!(&module.items[1], Item::ExternFn(e) if e.sig.name == "atoi"));
    assert!(matches!(&module.items[2], Item::Fn(_)));
}

/// A missing ABI string literal (`extern fn foo()` instead of `extern "C"
/// fn foo()`) is a parse error naming what was expected.
#[test]
fn extern_fn_missing_abi_string_is_parse_error() {
    let src = "extern fn foo()\n";
    let Err(diags) = Driver::parse(src) else { panic!("missing ABI string should be a parse error") };
    assert!(diags.iter().any(|d| d.message.contains("ABI")), "{:?}", diags);
}

/// An extern fn bound to an uppercase-starting C symbol (e.g. a Win32 name
/// like `CreateThread`) is rejected at the declaration, not left to fail
/// confusingly at the call site -- see `Checker::check_extern_fn`'s doc
/// comment on why such a symbol is permanently uncallable under Star's
/// grammar (`Name(args)` always parses as a struct literal).
#[test]
fn extern_fn_rejects_uppercase_name() {
    let src = "extern \"C\" fn CreateThread(x: int) -> ptr\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("uppercase-starting extern fn name should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("struct-literal constructor")), "{:?}", diags);
}

/// An extern fn's signature is registered into the same call-checking path
/// as an ordinary `fn`: a wrong argument count against `toupper(x: int)` is
/// caught exactly like it would be for a user-defined function. Uses
/// `toupper` rather than `abs`/`min`/`max`/etc. deliberately -- those names
/// are already recognized standard-library builtins (see
/// `crate::types::builtin_return_ty`), which are dispatched *ahead* of the
/// user function table by design (matching `print`'s existing shadowing
/// precedent), so an extern fn declared under one of those names would
/// silently never be reachable.
#[test]
fn extern_fn_call_arity_is_checked() {
    let src = "extern \"C\" fn toupper(x: int) -> int\nfn main():\n    let y = toupper(1, 2)\n    println(f\"{y}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("wrong arity should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("this call expects 1 argument")), "{:?}", diags);
}

/// A well-formed extern fn declaration and call (int arg/return) type-checks
/// cleanly end to end.
#[test]
fn extern_fn_call_type_checks_ok() {
    let src = "extern \"C\" fn toupper(x: int) -> int\nfn main():\n    let y: int = toupper(97)\n    println(f\"{y}\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("should type-check");
}

/// Only `"C"` is accepted as the ABI string.
#[test]
fn extern_fn_rejects_non_c_abi() {
    let src = "extern \"stdcall\" fn foo()\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("non-\"C\" abi should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("unsupported extern ABI")), "{:?}", diags);
}

/// Extern fns can't be generic -- C has no notion of a type parameter.
#[test]
fn extern_fn_rejects_type_params() {
    let src = "extern \"C\" fn foo<T>(x: int)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("generic extern fn should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("cannot be generic")), "{:?}", diags);
}

/// `bool` is rejected in extern signatures (see `Checker::check_extern_fn`'s
/// doc comment: LLVM `i1` vs. C's `_Bool`-as-`i8` ABI mismatch risk).
#[test]
fn extern_fn_rejects_bool_param() {
    let src = "extern \"C\" fn foo(x: bool)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("bool param should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("unsupported type")), "{:?}", diags);
}

/// A struct parameter type is rejected -- no C-ABI struct-by-value layout
/// is modeled by this compiler.
#[test]
fn extern_fn_rejects_struct_param() {
    let src = "struct Player:\n    health: i32\n\nextern \"C\" fn foo(p: Player)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("struct param should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("unsupported type")), "{:?}", diags);
}

/// `str` is allowed as a parameter (a Star `Str`'s payload is already a
/// bare `i8*`, safe to pass read-only to C) but rejected as a return type
/// (a `char*` from C has no RC header and must be bridged via
/// `ptr_to_str` instead of forged into a `str` directly).
#[test]
fn extern_fn_rejects_str_return_type() {
    let src = "extern \"C\" fn foo() -> str\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("str return type should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("ptr_to_str")), "{:?}", diags);
}

/// `str` parameters, by contrast, type-check fine.
#[test]
fn extern_fn_accepts_str_param() {
    let src = "extern \"C\" fn atoi(s: str) -> int\nfn main():\n    let n: int = atoi(\"42\")\n    println(f\"{n}\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("should type-check");
}

/// `null_ptr()`/`is_null(..)`/`ptr_to_str(..)` all type-check with their
/// documented signatures.
#[test]
fn ptr_builtins_type_check() {
    let src = "extern \"C\" fn foo() -> ptr\nfn main():\n    let p: ptr = null_ptr()\n    let ok: bool = is_null(p)\n    println(f\"{ok}\")\n    let s: str = ptr_to_str(foo())\n    println(s)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("should type-check");
}

/// `ptr == ptr` / `ptr != ptr` type-check to `bool`.
#[test]
fn ptr_equality_type_checks() {
    let src = "fn main():\n    let a = null_ptr()\n    let b = null_ptr()\n    let same: bool = a == b\n    println(f\"{same}\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("should type-check");
}

/// Codegen for an extern fn is a bare `declare`, never a `define` -- there
/// is no body to emit. A call to it lowers to an ordinary `call`
/// instruction against that declared symbol.
#[test]
fn extern_fn_codegen_emits_bare_declare_no_define() {
    let src = "extern \"C\" fn toupper(x: int) -> int\nfn main():\n    println(f\"{toupper(97)}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("declare i32 @toupper(i32)"), "{}", ir);
    assert!(!ir.contains("define i32 @toupper("), "extern fn must not get a body: {}", ir);
    assert!(ir.contains("call i32 @toupper("), "{}", ir);
}

/// A `str` argument passed to an extern call must extract the raw `i8*`
/// (not the RC header) and, since the extern call never releases it,
/// balance any borrowed retain back out immediately, *before* the call
/// itself -- see `Codegen::emit_extern_call`'s doc comment. (`s` also gets
/// one further release when it goes out of scope at the end of `main`,
/// same as any other owned local -- that's unrelated bookkeeping for `s`'s
/// own original ownership, not part of this retain/release pair, so this
/// test pins the *ordering* of the pair rather than a raw occurrence count.)
#[test]
fn extern_fn_str_arg_balances_retain_with_release() {
    let src = "extern \"C\" fn atoi(s: str) -> int\nfn main():\n    let s = \"42\"\n    println(f\"{atoi(s)}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let main_body = extract_fn_body(&ir, "define i32 @main(");
    let retain_idx = main_body.find("call void @star_rc_retain").expect("reading `s` should retain");
    let call_idx = main_body.find("call i32 @atoi(").expect("should call atoi");
    let release_idx = main_body.find("call void @star_rc_release").expect("the transient extern-call read should be released back");
    // The release must come *after* the call, not before: `atoi` reads
    // through the raw pointer it's handed during the call itself, so
    // releasing any earlier would free a fresh (non-`Ident`) argument's
    // buffer before the call ever read it (see `Codegen::emit_extern_call`'s
    // doc comment). Releasing after is also correct for this borrowed-`s`
    // case -- `s`'s own slot keeps the string alive throughout regardless of
    // when the extra retain is balanced back out.
    assert!(
        retain_idx < call_idx && call_idx < release_idx,
        "expected retain, then the extern call itself, then a balancing release, in that order: {}",
        main_body
    );
}

/// `toupper('a')` through a real `extern "C" fn` linked against the C
/// runtime (always available on this target, no `-l` needed) prints the
/// correct uppercase result. Uses `toupper` rather than `abs` -- see
/// `extern_fn_call_arity_is_checked`'s doc comment for why `abs` itself is
/// unusable as an extern fn name (it collides with the existing builtin).
#[test]
fn runtime_extern_toupper_end_to_end() {
    let src = "extern \"C\" fn toupper(x: int) -> int\nfn main():\n    println(f\"{toupper(97)}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_extern_toupper.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");

    let output = std::process::Command::new(&exe).output().expect("failed to execute extern_toupper.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("65"), "expected toupper('a'=97) == 'A'=65: {}", stdout);
    assert!(output.status.success());

    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
}

/// `atoi("42")` through a real `extern "C" fn` (msvcrt, always linked)
/// called repeatedly in a loop with the same `str` variable -- exercises
/// the RC retain/release-balancing path in `emit_extern_call` under
/// repetition. A missing release would leak (silent, doesn't crash); a
/// spurious *extra* release would double-free the string literal's backing
/// allocation and crash the process, which this test would catch.
#[test]
fn runtime_extern_atoi_str_arg_end_to_end() {
    let src = "extern \"C\" fn atoi(s: str) -> int\nfn main():\n    let s = \"42\"\n    let mut i = 0\n    while i < 20:\n        println(f\"{atoi(s)}\")\n        i += 1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_extern_atoi.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");

    let output = std::process::Command::new(&exe).output().expect("failed to execute extern_atoi.exe");
    assert!(output.status.success(), "should exit cleanly (no crash/double-free): {:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines.len(), 20, "expected 20 lines of output: {}", stdout);
    assert!(lines.iter().all(|l| *l == "42"), "every call should parse to 42: {}", stdout);

    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
}

/// A `ptr` round trip through a real C runtime symbol (`strpbrk`, always
/// linked on this target, no `-l` needed) -- `null_ptr()`/`is_null`
/// correctly distinguish a null handle from a real one, exercising both a
/// `str` argument and a `ptr` return in the same call. (Previously used
/// `getenv`, then `strstr`, for this -- `getenv` became a reserved runtime
/// symbol once the `env_get`/`env_set` builtins started declaring it
/// unconditionally (`crate::codegen::os`), and `strstr` became one in turn
/// once `str_contains`/`str_index_of`/`str_replace`/`str_split` started
/// declaring *it* unconditionally (`crate::codegen::builtins`/
/// `crate::codegen::list`) -- so this picks yet another real CRT symbol
/// with the same `(str, str) -> ptr` shape, which also drops the dependency
/// on the host process's `PATH` actually being set.)
///
/// Deliberately avoids any Win32 API (`GetModuleHandleA`, `GlobalAlloc`,
/// ...) for two independent reasons that make them unsuitable extern-fn
/// test targets, not just inconvenient ones:
/// (1) Star's grammar reserves `Name(args)` for struct-literal construction
/// whenever `Name` starts with an uppercase letter (`Vec3(0, 0, 0)`,
/// `Player(health = 100)`, ...) -- see `Parser::parse_primary`'s
/// `starts_uppercase` check in `src/parser/expr.rs`. This is a deliberate,
/// load-bearing rule used throughout the language, not something this
/// FFI feature can special-case around -- so a call to `GetModuleHandleA(..)`
/// parses as an attempt to construct a (nonexistent) `GetModuleHandleA`
/// struct instead of a function call. Any extern-fn call site must name a
/// symbol that doesn't start with an uppercase letter.
/// (2) Separately, many Win32 signatures (e.g. `GlobalAlloc`'s `SIZE_T`
/// byte count) have a parameter wider than Star's 32-bit `int` on this
/// x86_64 target, which isn't ABI-safe to bind with the types this FFI
/// surface currently offers (see the plan's "Scope for v1" note).
#[test]
fn runtime_extern_ptr_round_trip_end_to_end() {
    let src = "extern \"C\" fn strpbrk(s: str, charset: str) -> ptr\nfn main():\n    println(f\"{is_null(null_ptr())}\")\n    let missing = strpbrk(\"hello world\", \"xyz\")\n    println(f\"{is_null(missing)}\")\n    let found = strpbrk(\"hello world\", \"wor\")\n    println(f\"{is_null(found)}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_extern_ptr_roundtrip.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");

    let output = std::process::Command::new(&exe).output().expect("failed to execute extern_ptr_roundtrip.exe");
    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec!["true", "true", "false"],
        "null_ptr() is null; a substring that isn't present yields null; one that is present doesn't: {}",
        stdout
    );

    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
}

/// An `extern "C" fn` sharing a name with a recognized standard-library
/// builtin (e.g. `abs`) is rejected at the declaration, not silently allowed
/// through to become permanently unreachable at every call site --
/// `builtin_return_ty`/`Codegen::emit_expr`'s `TypedExpr::Call` arm both
/// dispatch on name *ahead* of the user function table (see
/// `extern_fn_call_arity_is_checked`'s doc comment), so without this check
/// the extern declaration would compile clean, its `declare` would sit
/// unused in the IR, and every call would quietly run the builtin instead --
/// with no argument/type checking against the real foreign signature.
#[test]
fn extern_fn_rejects_builtin_name_collision() {
    let src = "extern \"C\" fn abs(x: int) -> int\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("extern fn colliding with a builtin name should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("collides with a built-in name")), "{:?}", diags);
}

/// An `extern "C" fn` reusing the name of a symbol `Codegen::emit_builtins`/
/// `emit_rc_runtime` already `declare`s or `define`s unconditionally in every
/// generated module (here, `puts` -- also used by `println`) is rejected at
/// the declaration. Without this check the checker accepts it, codegen
/// happily emits a second `declare i32 @puts(i8*)`, and only clang's LLVM
/// parser rejects it -- with "invalid redefinition of function", pointing at
/// generated IR the user never wrote, not at their `.star` source.
#[test]
fn extern_fn_rejects_reserved_runtime_symbol_name() {
    let src = "extern \"C\" fn puts(s: str) -> int\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("extern fn colliding with a reserved runtime symbol should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("compiler always declares internally")), "{:?}", diags);
}

/// `main` -- the reserved process entry point every program's `fn main()`
/// lowers to (see `Codegen::emit_fn`'s `is_main` special-casing) -- is also a
/// reserved runtime symbol name for this same reason: `extern "C" fn main`
/// would collide with the real, forced-`i32`-return `@main` definition.
#[test]
fn extern_fn_rejects_main_as_reserved_name() {
    let src = "extern \"C\" fn main() -> int\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("extern fn named `main` should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("compiler always declares internally")), "{:?}", diags);
}

/// Two `extern "C" fn` declarations under the same name -- even with
/// byte-for-byte identical signatures -- are rejected at the second
/// declaration. LLVM's textual IR parser refuses a duplicate `declare` for
/// the same global outright (confirmed directly: even two hand-written,
/// identical `declare i32 @puts(i8*)` lines back to back fail clang with
/// "invalid redefinition of function"), so without this check a copy-pasted
/// or accidentally repeated extern declaration would compile clean here and
/// only fail at the clang step.
#[test]
fn extern_fn_rejects_duplicate_declaration() {
    let src = "extern \"C\" fn atoi(s: str) -> int\nextern \"C\" fn atoi(s: str) -> int\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("a duplicate extern fn declaration should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("declared more than once")), "{:?}", diags);
}

/// An `extern "C" fn` and an ordinary `fn` sharing one name, in the *same*
/// file, must be rejected at check time -- both lower to the same plain
/// LLVM function symbol `@name` (the extern's `declare`, the ordinary fn's
/// `define`), which LLVM's textual IR parser refuses to redefine, same as
/// two identical extern declarations (`extern_fn_rejects_duplicate_declaration`
/// above) or two same-named ordinary `fn`s
/// (`rejects_duplicate_top_level_function_declaration`). This is distinct
/// from both of those and from the acknowledged cross-file extern-vs-extern
/// collision gap (`todo.md`'s roadmap item #5): it's a single file, and one
/// of the two colliding declarations isn't an extern fn at all, so neither
/// existing check (`extern_fn_names_seen`, scoped to extern-vs-extern; the
/// duplicate-name pass's own `value_names_seen`, previously populated only
/// by ordinary `fn`s) ever looked at it. Confirmed via a real `star build`:
/// `check` accepted this silently, and `clang` then failed on the generated
/// IR with "invalid redefinition of function 'myfunc'" -- an opaque error
/// pointing at generated code the user never wrote, with no diagnostic at
/// the actual source of the problem. Fixed in `Checker::check`'s pass-1
/// duplicate-name loop (`src/types/mod.rs`) by cross-checking each
/// `Item::Fn`/`Item::ExternFn` against the other kind's already-seen names,
/// symmetrically regardless of which one appears first in the source.
#[test]
fn extern_fn_rejects_collision_with_ordinary_fn_same_file_extern_first() {
    let src = "extern \"C\" fn myfunc(x: i32) -> i32\nfn myfunc(x: i32) -> i32:\n    return x + 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else {
        panic!("an extern fn colliding with an ordinary fn of the same name should be a type error")
    };
    assert!(diags.iter().any(|d| d.message.contains("declared more than once")), "{:?}", diags);
}

/// Same bug, opposite declaration order (the ordinary `fn` declared first,
/// the `extern "C" fn` second) -- see
/// `extern_fn_rejects_collision_with_ordinary_fn_same_file_extern_first`'s
/// doc comment. Both orders must be caught since `Checker::check`'s
/// duplicate-name pass is a single left-to-right loop over `module.items`.
#[test]
fn extern_fn_rejects_collision_with_ordinary_fn_same_file_fn_first() {
    let src = "fn myfunc(x: i32) -> i32:\n    return x + 1\nextern \"C\" fn myfunc(x: i32) -> i32\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else {
        panic!("an ordinary fn colliding with an extern fn of the same name should be a type error")
    };
    assert!(diags.iter().any(|d| d.message.contains("declared more than once")), "{:?}", diags);
}

/// Calling an `extern "C" fn` *indirectly* through a first-class function
/// value (`let g = some_extern_fn; g(s)`) must release a `str` argument's
/// reference exactly once per call, the same way a direct call
/// (`emit_extern_call`) already does -- see the fix's own doc comment in
/// `Codegen::emit_fn_value` (`src/codegen/closure.rs`). Before that fix, the
/// generated thunk forwarded the argument straight to the extern `declare`
/// and released nothing, leaking one refcount per call (confirmed with a
/// Working-Set memory sample over `examples/extern_fnvalue_stress.star`:
/// unbounded growth from ~15MB to ~146MB over 5,000,000 iterations before
/// the fix, flat at ~3MB after). This test checks the generated IR directly
/// rather than sampling memory (that's `runtime_rc_stress_memory_stays_bounded`'s
/// job for the general RC mechanism; this just needs to confirm the specific
/// release call is present in the specific thunk).
#[test]
fn codegen_extern_fn_value_thunk_releases_str_arg() {
    let src = "extern \"C\" fn atoi(s: str) -> int\nfn main():\n    let g = atoi\n    let s = concat(\"4\", \"2\")\n    g(s)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let thunk_ir = extract_fn_body(&ir, "define i32 @fnval_atoi(");
    assert!(thunk_ir.contains("call i32 @atoi(i8* %arg_0)"), "{}", thunk_ir);
    assert!(
        thunk_ir.contains("call void @star_rc_release(i8* %arg_0)"),
        "the thunk must release the str arg after forwarding the call, since the extern declaration itself never does: {}",
        thunk_ir
    );
}

/// A first-class value referencing an *ordinary* (non-extern) function must
/// not gain a release in its thunk -- that function's own `emit_fn`-generated
/// body already tracks and releases its own `str` params at its own scope
/// exit (see `track_owned`/`pop_scope` in `rc.rs`), so adding a second
/// release in the thunk would double-release (and, on the last reference,
/// double-free) the argument. Guards the `is_extern_target` gate in the
/// fix above -- it must trigger only for a thunk wrapping an extern
/// declaration, never for a thunk wrapping a real Star function.
#[test]
fn codegen_ordinary_fn_value_thunk_does_not_double_release_str_arg() {
    let src = "fn take(s: str) -> int:\n    len(s)\nfn main():\n    let g = take\n    let s = concat(\"4\", \"2\")\n    g(s)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let thunk_ir = extract_fn_body(&ir, "define i32 @fnval_take(");
    assert!(
        !thunk_ir.contains("star_rc_release"),
        "a thunk wrapping an ordinary Star fn must not release its own args -- `take`'s own body already does: {}",
        thunk_ir
    );
}
