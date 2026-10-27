//! A float literal cast `as f64` keeps its full double-precision value.
//!
//! A float literal was always typed `float` (single precision) and only
//! then widened, so `2.718281828459045 as f64` was 2.7182817... (found in
//! the HavokOS port, which computed constants as `(1.0 as f64) / (3.0 as
//! f64)` to get around it; `todo.md` HavokOS P2 #3). `const`s typed `f64`
//! went the same way, because codegen had no `double` literal. Now
//! `<literal> as f64` (and `-<literal> as f64`) is an `f64` literal, the
//! way an integer literal under `as i64` already is, and an `f64` literal
//! is emitted as an LLVM `double`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

fn run(name: &str, src: &str) -> String {
    let out = compile_and_run(name, src);
    assert!(out.status.success(), "exit {:?}, stderr {}", out.status, String::from_utf8_lossy(&out.stderr));
    String::from_utf8_lossy(&out.stdout).replace("\r\n", "\n")
}

fn ir_of(src: &str) -> String {
    Driver::codegen(&Driver::check(&Driver::parse(src).unwrap()).unwrap()).unwrap()
}

/// `<literal> as f64` is typed `f64` and emitted as a `double` constant
/// with the literal's own bits, not an `fpext` of a rounded `float`.
#[test]
fn codegen_literal_as_f64_is_a_double_constant() {
    let ir = ir_of("fn f() -> f64:\n    2.718281828459045 as f64\n\nfn main():\n    let x = f()\n");
    let body = extract_fn_body(&ir, "define double @f(");
    assert!(body.contains(&format!("double 0x{:016X}", 2.718281828459045f64.to_bits())), "{}", body);
    assert!(!body.contains("fpext"), "{}", body);
}

/// Negated literals take the same path (`-x as T` parses as `(-x) as T`).
#[test]
fn typecheck_negated_literal_as_f64_is_an_f64_literal() {
    let module = Driver::parse("fn f() -> f64:\n    -0.1 as f64\n").unwrap();
    let typed = Driver::check(&module).unwrap();
    let ir = Driver::codegen(&typed).unwrap();
    let body = extract_fn_body(&ir, "define double @f(");
    assert!(body.contains(&format!("double 0x{:016X}", (-0.1f64).to_bits())), "{}", body);
}

/// The value at run time: `e` and `0.1` compare equal to the same value
/// computed in double precision, and differ from their `float` roundings.
#[test]
fn runtime_literal_as_f64_has_double_precision() {
    let out = run("f64_literal_precision", "fn main():
    let e = 2.718281828459045 as f64
    let tenth = 0.1 as f64
    let computed = (1.0 as f64) / (10.0 as f64)
    if tenth == computed:
        println(\"tenth exact\")
    else:
        println(\"tenth rounded\")
    let narrowed = (2.718281828459045 as float) as f64
    if e == narrowed:
        println(\"e rounded\")
    else:
        println(\"e exact\")
    let err = e * (1000000000000.0 as f64) - (2718281828459.045 as f64)
    if err < (0.01 as f64) and err > (-0.01 as f64):
        println(\"e digits ok\")
    else:
        println(\"e digits lost\")
");
    assert_eq!(out, "tenth exact\ne exact\ne digits ok\n");
}

/// An `f64` `const` keeps every digit too, while one narrowed through
/// `float` inside the initializer is still rounded.
#[test]
fn runtime_f64_const_has_double_precision() {
    let out = run("f64_literal_const", "const TENTH: f64 = 0.1 as f64
const NARROW: f64 = (0.1 as float) as f64
const NEG: f64 = -0.1 as f64

fn main():
    let computed = (1.0 as f64) / (10.0 as f64)
    if TENTH == computed:
        println(\"const exact\")
    else:
        println(\"const rounded\")
    if NARROW == computed:
        println(\"narrow exact\")
    else:
        println(\"narrow rounded\")
    if NEG == (0.0 as f64) - computed:
        println(\"neg exact\")
    else:
        println(\"neg rounded\")
");
    assert_eq!(out, "const exact\nnarrow rounded\nneg exact\n");
}

/// A plain float literal, and one cast to `float`, are still single
/// precision `float` constants.
#[test]
fn codegen_plain_float_literal_unchanged() {
    let ir = ir_of("fn f() -> float:\n    0.1\n\nfn g() -> float:\n    0.1 as float\n\nfn main():\n    let x = f()\n");
    let rounded = format!("float 0x{:016X}", (0.1f32 as f64).to_bits());
    assert!(extract_fn_body(&ir, "define float @f(").contains(&rounded), "{}", ir);
    assert!(extract_fn_body(&ir, "define float @g(").contains(&rounded), "{}", ir);
}

/// A literal cast to an integer type, or a non-literal cast to `f64`,
/// still goes through the ordinary cast.
#[test]
fn runtime_other_casts_unchanged() {
    let out = run("f64_literal_other_casts", "fn main():
    let i = 2.75 as i32
    let x = 1.5
    let w = x as f64
    let back = w as float
    println(f\"{i} {back}\")
");
    assert_eq!(out, "2 1.500000\n");
}
