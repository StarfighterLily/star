//! Exhaustive f-string/print-family format-specifier audit
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== todo.md P0 #2: exhaustive audit of every f-string/`print`-family ====
// ===== format-specifier table for missing `Ty` arms ========================
//
// `Codegen::emit_print_like` (`builtins.rs`, `println`/`print`'s direct
// sole-argument path) and the general f-string-as-`str`-value path
// (`TypedExpr::FStr` in `expr.rs`) are two independently-implemented
// format-specifier tables, and each has separately shipped the identical
// bug class before: an unhandled `Ty` silently falls through to a `%p`
// catch-all, tagging whatever LLVM value it actually is (a plain `i32`
// discriminant, a packed `Color32`, a bare `u8` `PaletteIndex`, ...) as a
// vararg *pointer* -- a C-ABI vararg-slot mismatch that reads garbage bytes
// off the stack/register and prints a plausible-looking but meaningless
// value instead of crashing or erroring (`projects/snake/NOTES.md` section
// 1.5's fieldless-enum-prints-as-garbage-hex bug is the worst-known
// instance). This round's audit found the same gap for a whole new class of
// types this catch-all was never actually safe for at all: `Named`
// (struct)/`GenRef`/`Handle`/`Tuple`/`Array`/`Ring`/`Closure` all lower to
// an LLVM *aggregate* passed by value (not a pointer), so `%p` was doubly
// wrong for them -- not just an unhelpful address, an outright ABI
// mismatch (confirmed live: `println(f"point={p}")` for a two-field struct
// printed `0000000000000001` instead of failing to compile). Fixed two
// ways: `Ty::is_fstring_unprintable` types are now rejected with a clean
// diagnostic in `Checker::infer_expr`'s `Expr::FStr` arm (see
// `checks_fstring_rejects_every_unprintable_ty_variant_end_to_end` below),
// and both codegen match statements were made exhaustive (no wildcard `_`
// arm at all) so a *future* unclassified `Ty` variant fails to compile here
// rather than silently reintroducing this bug class.

/// Every `Ty` variant with a defined print/f-string format specifier,
/// paired with a source expression constructing a representative value and
/// that value's exact expected printed text. Shared by the two round-trip
/// tests below (one per format-specifier table) so both tables are checked
/// against the same expectations. Deliberately does *not* cover
/// `List`/`Map`/`Set`/`Table`/`Palette`/`Bytes`/`Ptr` (a real `i8*`, so
/// `%p`'s raw-address output can't be pinned to an exact string -- see
/// `runtime_fstring_prints_pointer_backed_types_without_crashing_end_to_end`)
/// or the seven `Ty::is_fstring_unprintable` types (rejected at check time,
/// never reach codegen at all -- see
/// `checks_fstring_rejects_every_unprintable_ty_variant_end_to_end`).
fn fstring_printable_cases() -> Vec<(&'static str, &'static str)> {
    vec![
        ("5", "5"),
        ("5 as i8", "5"),
        ("5 as i16", "5"),
        ("5 as u8", "5"),
        ("5 as u16", "5"),
        ("5 as u32", "5"),
        ("5 as i64", "5"),
        ("5 as u64", "5"),
        ("5.0", "5.000000"),
        ("5.0 as f64", "5.000000"),
        ("'a'", "a"),
        ("\"hi\"", "hi"),
        ("true", "true"),
        ("Wrapping<i32>(5)", "5"),
        ("BitField<8>(5 as u8)", "5"),
        ("Flags<Direction>(Direction::Up)", "1"),
        ("Color32(10, 20, 30, 40)", "673059850"),
        ("PaletteIndex(7)", "7"),
        ("Direction::Left", "Left"),
        ("Tick(5)", "5"),
        ("Duration(5 as i64)", "5"),
        ("Instant(5 as i64)", "5"),
        ("Symbol(\"the only symbol interned in this program\")", "0"),
        ("Fixed<32, 16>(5)", "5.000000"),
        ("Vec2(1.0, 2.0)", "Vec2(1.000000, 2.000000)"),
        ("Vec3(1.0, 2.0, 3.0)", "Vec3(1.000000, 2.000000, 3.000000)"),
        ("Vec4(1.0, 2.0, 3.0, 4.0)", "Vec4(1.000000, 2.000000, 3.000000, 4.000000)"),
        ("Quat(0.0, 0.0, 0.0, 1.0)", "Quat(0.000000, 0.000000, 0.000000, 1.000000)"),
        ("Color(1.0, 0.0, 0.0, 1.0)", "Color(1.000000, 0.000000, 0.000000, 1.000000)"),
        ("Mat2(Vec2(1.0, 0.0), Vec2(0.0, 1.0))", "Mat2(Vec2(1.000000, 0.000000), Vec2(0.000000, 1.000000))"),
        (
            "Mat3(Vec3(1.0, 0.0, 0.0), Vec3(0.0, 1.0, 0.0), Vec3(0.0, 0.0, 1.0))",
            "Mat3(Vec3(1.000000, 0.000000, 0.000000), Vec3(0.000000, 1.000000, 0.000000), Vec3(0.000000, 0.000000, 1.000000))",
        ),
        (
            "Mat4(Vec4(1.0, 0.0, 0.0, 0.0), Vec4(0.0, 1.0, 0.0, 0.0), Vec4(0.0, 0.0, 1.0, 0.0), Vec4(0.0, 0.0, 0.0, 1.0))",
            "Mat4(Vec4(1.000000, 0.000000, 0.000000, 0.000000), Vec4(0.000000, 1.000000, 0.000000, 0.000000), Vec4(0.000000, 0.000000, 1.000000, 0.000000), Vec4(0.000000, 0.000000, 0.000000, 1.000000))",
        ),
    ]
}

/// `println(f"...")`'s direct-sole-argument path -- every printable `Ty`
/// variant, exercised through `Codegen::emit_print_like`'s specifier table.
#[test]
fn runtime_fstring_prints_every_printable_ty_variant_end_to_end() {
    let cases = fstring_printable_cases();
    let mut src = String::from("enum Direction:\n    Up\n    Down\n    Left\n    Right\n\nfn main():\n");
    for (expr, _) in &cases {
        src.push_str(&format!("    println(f\"{{{}}}\")\n", expr));
    }
    let output = compile_and_run("fstring_printable_direct", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    let expected: Vec<&str> = cases.iter().map(|(_, out)| *out).collect();
    assert_eq!(lines, expected, "{}", stdout);
}

/// The general f-string-as-`str`-value path (assigned to a `let`, printed
/// separately) -- the same cases, exercised through the *other*
/// format-specifier table (`TypedExpr::FStr` in `expr.rs`), which is
/// implemented completely separately from `emit_print_like` and has its own
/// independent history of missing arms (see this section's header comment).
#[test]
fn runtime_fstring_value_prints_every_printable_ty_variant_end_to_end() {
    let cases = fstring_printable_cases();
    let mut src = String::from("enum Direction:\n    Up\n    Down\n    Left\n    Right\n\nfn main():\n");
    for (i, (expr, _)) in cases.iter().enumerate() {
        src.push_str(&format!("    let v{} = f\"{{{}}}\"\n    println(v{})\n", i, expr, i));
    }
    let output = compile_and_run("fstring_printable_value", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    let expected: Vec<&str> = cases.iter().map(|(_, out)| *out).collect();
    assert_eq!(lines, expected, "{}", stdout);
}

/// The seven pointer-backed types (`List`/`Map`/`Set`/`Table`/`Palette`/
/// `Bytes`/`Ptr`, every one a bare `i8*`) all deliberately keep the `%p`
/// address-print behavior (see the arm's doc comment in both
/// `emit_print_like` and `TypedExpr::FStr`) -- there's no per-element/
/// per-field pretty-printer, so this only asserts the program compiles,
/// runs, and produces one non-empty line per value, not any particular
/// address text.
#[test]
fn runtime_fstring_prints_pointer_backed_types_without_crashing_end_to_end() {
    let src = "struct Enemy:\n    hp: i32\n\nfn main():\n    \
               let lst: List<i32> = List<i32>()\n    println(f\"{lst}\")\n    \
               let mp: Map<i32, i32> = Map<i32, i32>()\n    println(f\"{mp}\")\n    \
               let st: Set<i32> = Set<i32>()\n    println(f\"{st}\")\n    \
               let tbl: Table<Enemy> = Table<Enemy>()\n    println(f\"{tbl}\")\n    \
               let pal: Palette = Palette()\n    println(f\"{pal}\")\n    \
               let by: Bytes = Bytes()\n    println(f\"{by}\")\n    \
               let p: ptr = null_ptr()\n    println(f\"{p}\")\n";
    let output = compile_and_run("fstring_pointer_backed_no_crash", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines.len(), 7, "one line per pointer-backed value: {}", stdout);
    assert!(lines.iter().all(|l| !l.trim().is_empty()), "every line should have printed something: {}", stdout);
}

/// The seven `Ty::is_fstring_unprintable` types (`Named`/struct, `GenRef`,
/// `Handle`, `Tuple`, `Array`, `Ring`, `Closure`) all lower to an LLVM
/// aggregate passed *by value* -- interpolating one used to silently
/// compile down to a vararg `%p` pointer tag on a non-pointer register (a
/// C-ABI mismatch, confirmed live: a two-`i32`-field struct printed
/// `0000000000000001` instead of its actual field values or a diagnostic).
/// Now a clean `Checker` diagnostic instead, for every one of the seven.
#[test]
fn checks_fstring_rejects_every_unprintable_ty_variant_end_to_end() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\narena Points: Point\n\nfn main():\n    \
               spawn Points(1, 2)\n    \
               let p = Point(1, 2)\n    println(f\"{p}\")\n    \
               let t = (1, 2)\n    println(f\"{t}\")\n    \
               let arr: [i32; 3] = [1; 3]\n    println(f\"{arr}\")\n    \
               let r = GenRef<Point>(0)\n    println(f\"{r}\")\n    \
               let h = Handle<Point>(0)\n    println(f\"{h}\")\n    \
               let c = fn(x: i32) -> i32:\n        x\n    println(f\"{c}\")\n    \
               let ring = Ring<i32, 4>()\n    println(f\"{ring}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("f-string interpolation of every unprintable type should fail to type-check") };
    let messages: Vec<&str> = diags.iter().map(|d| d.message.as_str()).collect();
    assert_eq!(diags.len(), 7, "one diagnostic per unprintable value, none silently accepted: {:?}", messages);
    for needle in ["Named", "Tuple", "Array", "GenRef", "Handle", "Closure", "Ring"] {
        assert!(
            messages.iter().any(|m| m.contains("cannot interpolate") && m.contains(needle)),
            "expected a 'cannot interpolate' diagnostic naming {}: {:?}", needle, messages
        );
    }
}
