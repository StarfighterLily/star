//! Regression tests for todo.md P1 #1: repeated-f-string-call corruption.
//!
//! Root cause (found while root-causing that item): three separate codegen
//! call sites released a `str`-typed f-string interpolation hole's owned
//! pointer via `star_rc_release` *before* the `snprintf`/`printf` call that
//! actually reads through it -- `Codegen::emit_expr`'s general
//! `TypedExpr::FStr` arm (`src/codegen/expr.rs`), and both branches of
//! `Codegen::emit_print_like` (`src/codegen/builtins.rs`, one for an
//! f-string argument, one for a plain non-f-string argument). Releasing a
//! fresh (refcount-1) value frees its backing `malloc` block immediately;
//! nothing then stops a *later* allocation in the same expression (e.g. a
//! second interpolation hole's own call, itself materializing its return
//! value via concat/another f-string) from reusing that exact address
//! before the pending `snprintf`/`printf` reads it -- corrupting the
//! output. This is the exact same bug class `Codegen::emit_str_concat`'s
//! own doc comment (`builtins.rs`) already documents and fixes for
//! `concat`'s two arguments (confirmed there via `concat(f"a{1}", f"b{2}")`
//! producing `"b2b2"` instead of `"a1b2"`) -- it just never got ported to
//! these three other call sites. Confirmed as a real, wrong runtime result
//! here too (not just suspected) by reverting the fix and re-running these
//! tests before writing them up.
//!
//! Matches `projects/nova/disasm.star`'s own confirmed minimal repro
//! (`hex_word(0x1234)` coming back `"444"` instead of `"1234"` once an
//! inner helper was implemented via a nested `f"{hex_digit(..)}{hex_digit(..)}"`)
//! and `projects/nova/NOTES.md`'s "Not yet root-caused" write-up.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== IR-shape assertions: pin the fixed release ordering ==================

/// The general f-string-as-value path (`TypedExpr::FStr` in `expr.rs`) must
/// not emit a `str`-hole's `star_rc_release` until after *both* `snprintf`
/// calls (the C99 sizing pass included -- it reads every `%s` argument's
/// bytes too, not just the final fill pass) have read through it. Regression
/// guard for the fix: this used to release right after building each hole,
/// before either `snprintf` call existed in the emitted instruction stream
/// at all.
#[test]
fn codegen_fstring_value_str_hole_release_comes_after_both_snprintf_calls() {
    let src = "fn inner(n: i32) -> str:\n    f\"{n}\"\nfn outer(a: i32) -> str:\n    f\"{inner(a)}\"\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i8* @outer(");

    let release_pos = fn_ir.find("call void @star_rc_release").expect("should release the str hole somewhere");
    let sizing_snprintf_pos = fn_ir.find("@snprintf(i8* null, i64 0,").expect("should have a sizing snprintf call");
    let fill_snprintf_pos = fn_ir.rfind("@snprintf(i8*").expect("should have a fill snprintf call");

    assert!(
        release_pos > sizing_snprintf_pos,
        "the str hole must not be released before the sizing `snprintf` call reads it:\n{}",
        fn_ir
    );
    assert!(
        release_pos > fill_snprintf_pos,
        "the str hole must not be released before the fill `snprintf` call reads it:\n{}",
        fn_ir
    );
}

/// Same invariant, `emit_print_like`'s f-string-argument branch
/// (`println(f"...")`/`print(f"...")`): a `str` hole's release must come
/// after the single `printf` call that reads it.
#[test]
fn codegen_println_fstring_arg_str_hole_release_comes_after_printf() {
    let src = "fn inner(n: i32) -> str:\n    f\"{n}\"\nfn main():\n    println(f\"{inner(1)}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @main(");

    let release_pos = fn_ir.find("call void @star_rc_release").expect("should release the str hole somewhere");
    let printf_pos = fn_ir.find("@printf(").expect("should have a printf call");
    assert!(release_pos > printf_pos, "the str hole must not be released before `printf` reads it:\n{}", fn_ir);
}

/// Same invariant, `emit_print_like`'s plain (non-f-string) argument branch
/// (`println(some_str_expr)`): the release of whatever `emit_expr(arg)` left
/// owned must come after the `printf` call that reads it, not before.
#[test]
fn codegen_println_plain_str_arg_release_comes_after_printf() {
    let src = "fn wrap(v: i32) -> str:\n    f\"{v}\"\nfn main():\n    println(wrap(1))\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @main(");

    let release_pos = fn_ir.find("call void @star_rc_release").expect("should release the returned str somewhere");
    let printf_pos = fn_ir.find("@printf(").expect("should have a printf call");
    assert!(release_pos > printf_pos, "the plain str arg must not be released before `printf` reads it:\n{}", fn_ir);
}

// ===== Runtime end-to-end repros =============================================

/// The exact bug shape `projects/nova/disasm.star` found and routed around:
/// an outer f-string with *two* `str`-typed holes, each calling a helper
/// that itself materializes its own return value via an f-string. Before
/// the fix, the first hole's fresh buffer was released (freed) immediately
/// after being built, and the second hole's own f-string construction
/// (itself calling `star_rc_alloc`) reliably reused that exact freed
/// address before the outer `snprintf` calls ever read the first hole --
/// corrupting the first half of the output. Looped, matching todo.md's own
/// framing ("more than once in the same running program").
#[test]
fn runtime_nested_fstring_holes_both_inner_fstring_based_end_to_end() {
    let src = "fn inner_f(n: i32) -> str:\n    f\"{n}\"\n\
               fn outer_f(a: i32, b: i32) -> str:\n    f\"{inner_f(a)}-{inner_f(b)}\"\n\
               fn main():\n    let mut i = 0\n    while i < 6:\n        println(outer_f(100 + i, 900 - i))\n        i += 1\n";
    let output = compile_and_run("fstring_nested_holes_inner_fstring", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["100-900", "101-899", "102-898", "103-897", "104-896", "105-895"], "{}", stdout);
}

/// Same shape, but the inner helper builds its return value via `concat`
/// rather than an f-string -- matches todo.md's explicit note that the bug
/// reproduces "even when the *inner* function is `concat`-based ... as long
/// as an f-string appears somewhere in the call chain more than once" (here,
/// the *outer* expression is the f-string, evaluated twice per call via its
/// two holes). The corrupting reuse comes from the outer f-string's own
/// buffer allocation and the second hole's `concat` call, not from any
/// nested f-string inside `inner_c` itself.
#[test]
fn runtime_nested_fstring_holes_inner_concat_based_end_to_end() {
    let src = "fn inner_c(n: i32) -> str:\n    concat(\"v\", chr(65 + n))\n\
               fn outer_c(a: i32, b: i32) -> str:\n    f\"{inner_c(a)}-{inner_c(b)}\"\n\
               fn main():\n    let mut i = 0\n    while i < 6:\n        println(outer_c(i, i + 1))\n        i += 1\n";
    let output = compile_and_run("fstring_nested_holes_inner_concat", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["vA-vB", "vB-vC", "vC-vD", "vD-vE", "vE-vF", "vF-vG"], "{}", stdout);
}

/// Same shape again, but the two nested calls appear directly inside
/// `println(f"...")` itself rather than inside an intermediate wrapper
/// function's own returned f-string -- exercises `emit_print_like`'s
/// f-string branch specifically (as opposed to the general
/// `TypedExpr::FStr`-as-value path the two tests above exercise via
/// `outer_f`/`outer_c`'s own body).
#[test]
fn runtime_println_fstring_with_two_str_returning_holes_end_to_end() {
    let src = "fn inner_p(n: i32) -> str:\n    f\"{n}\"\n\
               fn main():\n    let mut i = 0\n    while i < 6:\n        println(f\"{inner_p(i)}-{inner_p(i + 500)}\")\n        i += 1\n";
    let output = compile_and_run("fstring_println_two_holes", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["0-500", "1-501", "2-502", "3-503", "4-504", "5-505"], "{}", stdout);
}

/// A three-hole variant (more interpolations than the minimal two-hole
/// repro above) to guard against a fix that happens to work for exactly two
/// holes but not more -- every hole's release must be deferred, not just
/// the first.
#[test]
fn runtime_fstring_three_str_returning_holes_end_to_end() {
    let src = "fn inner(n: i32) -> str:\n    f\"{n}\"\n\
               fn triple(a: i32, b: i32, c: i32) -> str:\n    f\"{inner(a)}:{inner(b)}:{inner(c)}\"\n\
               fn main():\n    let mut i = 0\n    while i < 5:\n        println(triple(i, i + 10, i + 20))\n        i += 1\n";
    let output = compile_and_run("fstring_three_holes", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["0:10:20", "1:11:21", "2:12:22", "3:13:23", "4:14:24"], "{}", stdout);
}

/// The exact historical repro recorded in `projects/nova/NOTES.md` ("A
/// related, deliberately unfixed runtime bug" section, right after bug #7):
/// a *single*-hole f-string wrapper (`fn wrap(v: i32) -> str: f"0x{hex_word(v)}"`,
/// `hex_word`/`hex_byte`/`hex_digit` all `concat`-based, no nested
/// f-string anywhere) returned the correct value on its *first* call and a
/// corrupted one -- a literal duplicated `"0x"` fragment (`"0x0x00"`
/// instead of `"0x0000"`) -- on a later call to the same call site.
/// Explained by the same root cause: `wrap`'s own `star_rc_alloc`'d result
/// buffer used to be allocated (in `TypedExpr::FStr`'s codegen) *before*
/// the hole's already-released `hex_word(v)` buffer was read by the fill
/// `snprintf` -- confirmed empirically (not just by this reasoning) while
/// writing this test: reverting the fix and looping `wrap` over just 3
/// values didn't reproduce it (nothing to reuse yet on a mostly-empty
/// heap), but looping over 30 sequential values reliably hit it at two
/// separate iterations, both showing the exact predicted `"0x0x0N"`
/// duplicated-fragment pattern rather than random garbage -- which is why
/// this test loops 30 times rather than the 2-3 calls the original
/// hand-observed repro happened to need.
#[test]
fn runtime_nested_single_hole_fstring_wrapper_matches_notes_md_historical_repro_end_to_end() {
    let src = "fn hex_digit(n: i32) -> str:\n    if n < 10:\n        chr(48 + n)\n    else:\n        chr(65 + (n - 10))\n\
               fn hex_byte(v: i32) -> str:\n    let b = v & 0xFF\n    concat(hex_digit((b / 16) % 16), hex_digit(b % 16))\n\
               fn hex_word(v: i32) -> str:\n    let w = v & 0xFFFF\n    concat(hex_byte((w / 256) % 256), hex_byte(w % 256))\n\
               fn wrap(v: i32) -> str:\n    f\"0x{hex_word(v)}\"\n\
               fn main():\n    let mut i = 0\n    while i < 30:\n        println(wrap(0x1000 + i))\n        i += 1\n";
    let output = compile_and_run("fstring_notes_md_historical_repro", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    let expected: Vec<String> = (0..30).map(|i| format!("0x{:04X}", 0x1000 + i)).collect();
    assert_eq!(lines, expected, "{}", stdout);
}
