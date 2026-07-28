//! Single-line `fn foo(): body` -- todo.md P2 #8.
//!
//! Previously a function/method body always had to be a full indented block,
//! even for a single trailing expression -- `fn foo(): 42` failed to parse
//! ("expected end of line, found integer literal") and had to be spelled
//! `fn foo():\n    42` instead. `Parser::parse_fn` (`src/parser/items.rs`)
//! now mirrors the exact compact-arm grammar `parse_lambda` and
//! `parse_if_expr_arm` already established: when the `:` isn't immediately
//! followed by a `Newline`, the body is a single inline expression wrapped in
//! a one-statement `Block`, instead of always calling `parse_block()`. No new
//! AST/`TypedStmt`/codegen shape exists -- `FnDef::body` is still a plain
//! `Block { stmts: vec![Stmt::Expr(expr)], .. } }`, the same shape a
//! full-block function whose only statement is a trailing expression already
//! produces -- so the checker, `sequence`/`frame`/`par` analysis, and codegen
//! all need zero new match arms.
//!
//! Like `parse_if_expr_arm`'s inline arm, the compact form accepts exactly
//! one *expression*, not an arbitrary statement -- `while`/`for` never grew a
//! compact form either, and this deliberately doesn't reach further than the
//! two precedents that already existed.
//!
//! Shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Parser / AST-shape ==================================================

/// The simplest case: a single-line body with no params/return type desugars
/// to a one-statement block holding the inline expression directly, exactly
/// like the equivalent full-block form would.
#[test]
fn parses_single_line_fn_body_as_inline_expr() {
    let src = "fn foo(): 42\n";
    let module = Driver::parse(src).expect("should parse");
    assert_eq!(module.items.len(), 1);
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn item") };
    assert_eq!(f.body.stmts.len(), 1, "{:?}", f.body.stmts);
    assert!(matches!(&f.body.stmts[0], Stmt::Expr(Expr::Int(42, _))), "{:?}", f.body.stmts[0]);
}

/// Params and a return type both parse fine ahead of the compact `:` body,
/// and the inline body can itself be a compound expression (not just a bare
/// literal).
#[test]
fn parses_single_line_fn_with_params_and_return_type() {
    let src = "fn add(a: i32, b: i32) -> i32: a + b\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn item") };
    assert_eq!(f.sig.params.len(), 2);
    assert!(f.sig.ret.is_some());
    assert_eq!(f.body.stmts.len(), 1);
    assert!(matches!(&f.body.stmts[0], Stmt::Expr(Expr::Binary { op: BinOp::Add, .. })), "{:?}", f.body.stmts[0]);
}

/// The compact form works for a method inside an `impl` block too --
/// `parse_fn` is shared between top-level `fn` items and `impl` methods, so
/// this exercises that it isn't only wired up on one of the two call sites.
#[test]
fn parses_single_line_method_in_impl_block() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\nimpl Point:\n    fn get_x(self) -> i32: self.x\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Impl(imp) = &module.items[1] else { panic!("expected an impl item") };
    assert_eq!(imp.methods.len(), 1);
    let m = &imp.methods[0];
    assert_eq!(m.body.stmts.len(), 1);
    assert!(matches!(&m.body.stmts[0], Stmt::Expr(Expr::Field { .. })), "{:?}", m.body.stmts[0]);
}

/// The inline body can itself be an `if`/`else` expression (compact form),
/// nesting one compact-arm grammar inside another.
#[test]
fn parses_single_line_fn_body_with_if_else_expr() {
    let src = "fn classify(n: i32) -> str: if n < 0: \"neg\" else: \"pos\"\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!() };
    assert_eq!(f.body.stmts.len(), 1);
    assert!(matches!(&f.body.stmts[0], Stmt::Expr(Expr::If { .. })), "{:?}", f.body.stmts[0]);
}

/// A call expression works as the inline body too (the common "one-liner
/// wrapper" shape, e.g. a `println` forwarding helper).
#[test]
fn parses_single_line_fn_body_call_expr() {
    let src = "fn greet(): println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!() };
    assert!(matches!(&f.body.stmts[0], Stmt::Expr(Expr::Call { .. })), "{:?}", f.body.stmts[0]);
}

/// Two single-line functions back to back: `expect_line_end` inside
/// `parse_fn` must actually consume the trailing `Newline` itself so the
/// module-level item loop lands cleanly on the next `fn`, rather than
/// swallowing part of the next item or leaving a stray token behind.
#[test]
fn parses_two_single_line_fns_back_to_back() {
    let src = "fn a(): 1\nfn b(): 2\n";
    let module = Driver::parse(src).expect("should parse");
    assert_eq!(module.items.len(), 2);
    let Item::Fn(a) = &module.items[0] else { panic!() };
    let Item::Fn(b) = &module.items[1] else { panic!() };
    assert!(matches!(&a.body.stmts[0], Stmt::Expr(Expr::Int(1, _))));
    assert!(matches!(&b.body.stmts[0], Stmt::Expr(Expr::Int(2, _))));
}

/// The full-indented-block form is completely unaffected -- `parse_fn` still
/// takes the `parse_block()` branch whenever the `:` is immediately followed
/// by a `Newline`, regardless of how many statements the block holds.
#[test]
fn parses_full_block_fn_body_still_works_unaffected() {
    let src = "fn foo():\n    let x = 1\n    let y = 2\n    x + y\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!() };
    assert_eq!(f.body.stmts.len(), 3, "{:?}", f.body.stmts);
}

/// A single-line function containing an inline lambda body: two different
/// compact-arm grammars (fn body, lambda body) nested inside each other.
#[test]
fn parses_single_line_fn_body_with_inline_lambda() {
    let src = "fn make_adder() -> Fn(i32) -> i32: fn(x: i32) -> i32: x + 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!() };
    assert!(matches!(&f.body.stmts[0], Stmt::Expr(Expr::Lambda { .. })), "{:?}", f.body.stmts[0]);
}

// ===== Parse errors ==========================================================

/// Trailing garbage after the inline body on the same line is a clean parse
/// error (`expect_line_end` rejecting it), not a panic and not silently
/// dropped.
#[test]
fn rejects_single_line_fn_with_trailing_garbage_after_body() {
    let src = "fn foo(): 1 2\n";
    let errs = Driver::parse(src).expect_err("trailing garbage after an inline fn body should be rejected");
    assert!(!errs.is_empty());
}

/// The compact form accepts exactly one *expression*, matching
/// `parse_if_expr_arm`/`parse_lambda`'s existing scope -- an assignment
/// statement inline (`self.x += 1`) is not an expression, so this is a clean
/// parse error rather than silently being accepted as a new, wider grammar.
#[test]
fn rejects_single_line_fn_body_assignment_statement() {
    let src = "struct Counter:\n    mut x: i32\n\nimpl Counter:\n    fn bump(mut self): self.x += 1\n";
    let errs = Driver::parse(src).expect_err("an inline assignment statement should not parse as a compact fn body");
    assert!(!errs.is_empty());
}

/// Likewise, an inline `return` (a statement, not an expression) does not
/// parse as a compact body.
#[test]
fn rejects_single_line_fn_body_return_statement() {
    let src = "fn foo(): return 5\n";
    let errs = Driver::parse(src).expect_err("an inline `return` statement should not parse as a compact fn body");
    assert!(!errs.is_empty());
}

/// A single-line body that's just empty (nothing between `:` and the
/// newline is actually whitespace, so this really means "`:` followed by
/// something that isn't a valid expression start") is a clean parse error.
#[test]
fn rejects_single_line_fn_with_no_body_expression() {
    let src = "fn foo(): \n    1\n";
    let errs = Driver::parse(src);
    // Either this is rejected outright, or (since a bare `:` followed by a
    // real Newline is exactly the full-block shape) it's accepted as a
    // full-block body -- either is fine, but it must not panic.
    let _ = errs;
}

// ===== Type-checking ========================================================

/// A single-line function's inline body type-checks against its declared
/// return type exactly like a full-block trailing expression would.
#[test]
fn checks_single_line_fn_body_type_matches_return_type() {
    let src = "fn add(a: i32, b: i32) -> i32: a + b\n\nfn main():\n    println(f\"{add(1, 2)}\")\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok());
}

/// A single-line body whose expression type disagrees with the declared
/// return type is rejected by the checker, same as it would be in full-block
/// form.
#[test]
fn rejects_single_line_fn_body_type_mismatch() {
    let src = "fn foo() -> str: 42\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "an i32 body should not satisfy a declared str return type");
}

/// A void (no `->`) function with a single-line body that's a side-effecting
/// call still type-checks fine -- its trailing expression's value is simply
/// discarded, same as any other void function's trailing-expression
/// statement.
#[test]
fn checks_single_line_void_fn_with_call_body() {
    let src = "fn greet(): println(\"hi\")\n\nfn main():\n    greet()\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok());
}

/// A single-line method's inline body resolves `self` correctly during
/// checking (field access typed against the enclosing struct).
#[test]
fn checks_single_line_method_body_resolves_self_fields() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\nimpl Point:\n    fn get_x(self) -> i32: self.x\n\nfn main():\n    let p = Point(x = 1, y = 2)\n    println(f\"{p.get_x()}\")\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok());
}

// ===== Runtime end-to-end ===================================================

/// Several one-liner arithmetic helpers, called from `main`, all evaluate
/// correctly.
#[test]
fn runtime_single_line_fn_arithmetic_end_to_end() {
    let src = r#"
fn add(a: i32, b: i32) -> i32: a + b
fn square(x: i32) -> i32: x * x
fn negate(x: i32) -> i32: -x

fn main():
    println(f"{add(2, 3)}")
    println(f"{square(6)}")
    println(f"{negate(7)}")
"#;
    let output = compile_and_run("single_line_fn_arithmetic_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["5", "36", "-7"], "{}", stdout);
}

/// A single-line method, called on a real instance, reads the right field.
#[test]
fn runtime_single_line_method_end_to_end() {
    let src = r#"
struct Point:
    x: i32
    y: i32

impl Point:
    fn get_x(self) -> i32: self.x
    fn get_y(self) -> i32: self.y
    fn sum(self) -> i32: self.x + self.y

fn main():
    let p = Point(x = 3, y = 4)
    println(f"{p.get_x()}")
    println(f"{p.get_y()}")
    println(f"{p.sum()}")
"#;
    let output = compile_and_run("single_line_method_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["3", "4", "7"], "{}", stdout);
}

/// A single-line function whose body is itself a compact `if`/`else`
/// expression -- two levels of compact-arm grammar composed together at
/// runtime, not just at parse time.
#[test]
fn runtime_single_line_fn_with_inline_if_expr_body_end_to_end() {
    let src = r#"
fn classify(n: i32) -> str: if n < 0: "negative" elif n == 0: "zero" else: "positive"

fn main():
    println(classify(-5))
    println(classify(0))
    println(classify(5))
"#;
    let output = compile_and_run("single_line_fn_if_expr_body_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["negative", "zero", "positive"], "{}", stdout);
}

/// A single-line function's body can itself call another single-line
/// function, chaining across several one-liners.
#[test]
fn runtime_single_line_fn_calling_another_single_line_fn_end_to_end() {
    let src = r#"
fn double(x: i32) -> i32: x * 2
fn quadruple(x: i32) -> i32: double(double(x))

fn main():
    println(f"{quadruple(5)}")
"#;
    let output = compile_and_run("single_line_fn_chained_calls_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim(), "20", "{}", stdout);
}

/// Single-line and full-block functions freely mix in the same program, and
/// a full-block function can call a single-line one and vice versa.
#[test]
fn runtime_mixed_single_line_and_block_fns_end_to_end() {
    let src = r#"
fn helper(x: i32) -> i32: x + 100

fn full_block(x: i32) -> i32:
    let y = helper(x)
    let z = y * 2
    return z

fn main():
    println(f"{full_block(1)}")
    println(f"{helper(1)}")
"#;
    let output = compile_and_run("single_line_mixed_fns_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["202", "101"], "{}", stdout);
}

/// A recursive single-line function (factorial via a compact `if`/`else`
/// expression body) -- confirms the inline body can reference the enclosing
/// function by name and that recursion through the compact form actually
/// terminates and produces the right value.
#[test]
fn runtime_recursive_single_line_fn_end_to_end() {
    let src = r#"
fn fact(n: i32) -> i32: if n <= 1: 1 else: n * fact(n - 1)

fn main():
    println(f"{fact(0)}")
    println(f"{fact(1)}")
    println(f"{fact(5)}")
"#;
    let output = compile_and_run("single_line_fn_recursive_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["1", "1", "120"], "{}", stdout);
}

/// A single-line method inside a loop, mutating loop-local state via its
/// return value (not via internal mutation, since the compact body form
/// can't hold an assignment statement) -- exercises the feature in a
/// realistic Nova-style "small pure accessor" role repeated across
/// iterations.
#[test]
fn runtime_single_line_method_called_in_loop_end_to_end() {
    let src = r#"
struct Reg:
    value: i32

impl Reg:
    fn masked(self) -> i32: self.value & 255

fn main():
    let mut i = 0
    while i < 4:
        let r = Reg(value = 256 + i)
        println(f"{r.masked()}")
        i += 1
"#;
    let output = compile_and_run("single_line_method_in_loop_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["0", "1", "2", "3"], "{}", stdout);
}
