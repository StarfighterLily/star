//! Default parameter values (`docs/requests.md` #6): `fn f(x: i32 = 0):`,
//! plus making the existing named-argument call syntax (`f(x = 1)`,
//! previously rejected outright for ordinary calls -- see
//! `Checker::resolve_call_arg_exprs`) actually useful for omitting
//! defaulted trailing parameters, in any order. Shared helpers live in
//! `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Parsing ================================================================

/// A parameter's default expression is stored on `Param`.
#[test]
fn parses_param_default() {
    let src = "fn f(x: i32 = 5):\n    x\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert!(matches!(&f.sig.params[0].default, Some(Expr::Int(5, _))));
}

/// A parameter with no `=` has no default.
#[test]
fn parses_param_without_default() {
    let src = "fn f(x: i32):\n    x\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert!(f.sig.params[0].default.is_none());
}

/// A default may be an arbitrary expression, not just a literal.
#[test]
fn parses_param_default_as_expression() {
    let src = "fn f(x: i32 = 1 + 2):\n    x\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert!(matches!(&f.sig.params[0].default, Some(Expr::Binary { .. })));
}

/// A non-defaulted parameter after a defaulted one is a parse error --
/// defaults must trail.
#[test]
fn rejects_non_default_param_after_default_param() {
    let src = "fn f(x: i32 = 0, y: i32):\n    x + y\n";
    assert!(Driver::parse(src).is_err());
}

/// Every parameter defaulted is fine (trivially "trailing").
#[test]
fn accepts_all_params_defaulted() {
    let src = "fn f(x: i32 = 1, y: i32 = 2):\n    x + y\n";
    Driver::parse(src).expect("should parse");
}

/// `self` doesn't need a default even though it always comes first --
/// unaffected by the trailing-defaults rule.
#[test]
fn self_param_unaffected_by_defaults_trail_rule() {
    let src = "struct P:\n    v: i32\n\nimpl P:\n    fn get(self, add: i32 = 0) -> i32:\n        self.v + add\n";
    Driver::parse(src).expect("should parse");
}

/// `extern \"C\" fn` signatures share the same grammar (`Parser::
/// parse_fn_sig`), so the trailing-defaults rule applies there too.
#[test]
fn rejects_non_default_param_after_default_in_extern_fn() {
    let src = "extern \"C\" fn foo(x: i32 = 0, y: i32) -> i32\n";
    assert!(Driver::parse(src).is_err());
}

// ===== Type-checking ==========================================================

/// Omitting a trailing defaulted parameter type-checks fine.
#[test]
fn omitting_defaulted_trailing_arg_type_checks() {
    let src = "fn f(x: i32, y: i32 = 10) -> i32:\n    x + y\n\nfn main():\n    let r = f(1)\n    println(f\"{r}\")\n";
    Driver::check(&Driver::parse(src).expect("should parse")).expect("should type-check");
}

/// Omitting a required (non-defaulted) argument is still an error.
#[test]
fn rejects_omitting_a_required_arg() {
    let src = "fn f(x: i32, y: i32 = 10) -> i32:\n    x + y\n\nfn main():\n    let r = f()\n    println(f\"{r}\")\n";
    assert!(Driver::check(&Driver::parse(src).expect("should parse")).is_err());
}

/// Named arguments may reorder freely at an ordinary call site now.
#[test]
fn named_args_may_reorder_at_call_site() {
    let src = "fn sub(a: i32, b: i32) -> i32:\n    a - b\n\nfn main():\n    let r = sub(b = 1, a = 10)\n    println(f\"{r}\")\n";
    Driver::check(&Driver::parse(src).expect("should parse")).expect("should type-check");
}

/// An unknown named argument is a clear error.
#[test]
fn rejects_unknown_named_arg() {
    let src = "fn f(x: i32 = 0):\n    x\n\nfn main():\n    f(z = 1)\n";
    assert!(Driver::check(&Driver::parse(src).expect("should parse")).is_err());
}

/// A named argument given more than once is an error.
#[test]
fn rejects_duplicate_named_arg() {
    let src = "fn f(x: i32, y: i32 = 0) -> i32:\n    x + y\n\nfn main():\n    let r = f(x = 1, x = 2)\n    println(f\"{r}\")\n";
    assert!(Driver::check(&Driver::parse(src).expect("should parse")).is_err());
}

/// A positional argument after a named one is an error.
#[test]
fn rejects_positional_after_named() {
    let src = "fn f(x: i32, y: i32 = 0) -> i32:\n    x + y\n\nfn main():\n    let r = f(x = 1, 2)\n    println(f\"{r}\")\n";
    assert!(Driver::check(&Driver::parse(src).expect("should parse")).is_err());
}

/// A named argument's value must still match the declared parameter's type.
#[test]
fn rejects_named_arg_type_mismatch() {
    let src = "fn f(x: i32, y: i32 = 0) -> i32:\n    x + y\n\nfn main():\n    let r = f(x = \"nope\")\n    println(f\"{r}\")\n";
    assert!(Driver::check(&Driver::parse(src).expect("should parse")).is_err());
}

/// A method call may also omit a defaulted trailing argument.
#[test]
fn method_call_may_omit_defaulted_arg() {
    let src = "struct P:\n    v: i32\n\nimpl P:\n    fn add(self, n: i32 = 1) -> i32:\n        self.v + n\n\nfn main():\n    let p = P(v = 10)\n    let r = p.add()\n    println(f\"{r}\")\n";
    Driver::check(&Driver::parse(src).expect("should parse")).expect("should type-check");
}

/// A method call may also use named arguments.
#[test]
fn method_call_may_use_named_args() {
    let src = "struct P:\n    v: i32\n\nimpl P:\n    fn combine(self, a: i32, b: i32) -> i32:\n        self.v + a - b\n\nfn main():\n    let p = P(v = 10)\n    let r = p.combine(b = 1, a = 2)\n    println(f\"{r}\")\n";
    Driver::check(&Driver::parse(src).expect("should parse")).expect("should type-check");
}

/// Named arguments on a call whose receiver is a compound expression (not a
/// bare identifier/`self`) are still rejected -- a documented, narrow scope
/// limit (`Checker::try_resolve_call_defaults`'s doc comment): resolving
/// that call's target would require evaluating the receiver expression
/// twice.
#[test]
fn rejects_named_args_on_compound_receiver_call() {
    let src = "struct P:\n    v: i32\n\nimpl P:\n    fn combine(self, a: i32, b: i32) -> i32:\n        self.v + a - b\n\nfn make_p() -> P:\n    P(v = 1)\n\nfn main():\n    let r = make_p().combine(b = 1, a = 2)\n    println(f\"{r}\")\n";
    assert!(Driver::check(&Driver::parse(src).expect("should parse")).is_err());
}

/// Named arguments on a closure call are still rejected -- closures have no
/// declared parameter *names* available to a caller (`Ty::Closure` only
/// carries types), so there's nothing for this feature to resolve against.
#[test]
fn rejects_named_args_on_closure_call() {
    let src = "fn main():\n    let f = fn(x: i32) -> i32: x + 1\n    let r = f(x = 5)\n    println(f\"{r}\")\n";
    assert!(Driver::check(&Driver::parse(src).expect("should parse")).is_err());
}

/// A purely positional, exact-arity call to a defaulted-param function is
/// completely unaffected -- the override still applies.
#[test]
fn positional_call_can_still_override_default() {
    let src = "fn f(x: i32 = 100) -> i32:\n    x\n\nfn main():\n    let r = f(5)\n    println(f\"{r}\")\n";
    Driver::check(&Driver::parse(src).expect("should parse")).expect("should type-check");
}

// ===== Runtime =================================================================

/// Calling with the trailing defaulted argument omitted uses the default.
#[test]
fn runtime_omitted_default_arg_end_to_end() {
    let src = "fn add(a: i32, b: i32 = 10) -> i32:\n    a + b\n\nfn main():\n    println(f\"{add(1)}\")\n";
    let output = compile_and_run("default_param_omit", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "11");
}

/// Calling with an explicit value overrides the default.
#[test]
fn runtime_explicit_arg_overrides_default_end_to_end() {
    let src = "fn add(a: i32, b: i32 = 10) -> i32:\n    a + b\n\nfn main():\n    println(f\"{add(1, 2)}\")\n";
    let output = compile_and_run("default_param_override", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "3");
}

/// Multiple trailing defaults can all be omitted at once.
#[test]
fn runtime_multiple_omitted_defaults_end_to_end() {
    let src = "fn combine(a: i32, b: i32 = 10, c: i32 = 100) -> i32:\n    a + b + c\n\nfn main():\n    println(f\"{combine(1)}\")\n";
    let output = compile_and_run("default_param_multi_omit", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "111");
}

/// Only the last of several defaults is omitted -- the middle one is
/// overridden positionally, the last one falls back.
#[test]
fn runtime_partial_omission_of_multiple_defaults_end_to_end() {
    let src = "fn combine(a: i32, b: i32 = 10, c: i32 = 100) -> i32:\n    a + b + c\n\nfn main():\n    println(f\"{combine(1, 2)}\")\n";
    let output = compile_and_run("default_param_partial_omit", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "103"); // 1 + 2 + 100
}

/// Named arguments reorder the call, unaffected by declaration order.
#[test]
fn runtime_named_args_reorder_end_to_end() {
    let src = "fn sub(a: i32, b: i32) -> i32:\n    a - b\n\nfn main():\n    println(f\"{sub(b = 3, a = 10)}\")\n";
    let output = compile_and_run("default_param_named_reorder", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "7");
}

/// Named arguments combined with an omitted default.
#[test]
fn runtime_named_arg_with_omitted_default_end_to_end() {
    let src = "fn greet(name: str, times: i32 = 1) -> i32:\n    times\n\nfn main():\n    let n = \"hi\"\n    println(f\"{greet(name = n)}\")\n";
    let output = compile_and_run("default_param_named_with_default", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "1");
}

/// A default expression can reference another value in the *caller's*
/// scope (it's spliced into the caller's own argument list and evaluated
/// there, not in the callee's parameter scope -- `Checker::
/// resolve_call_arg_exprs` splices the raw declared default expression
/// directly, mirroring how `resolve_ctor_arg_exprs` already does the same
/// for struct field defaults).
#[test]
fn runtime_default_expression_evaluated_in_callers_scope_end_to_end() {
    let src = "fn base() -> i32:\n    42\n\nfn f(x: i32 = base()) -> i32:\n    x\n\nfn main():\n    println(f\"{f()}\")\n";
    let output = compile_and_run("default_param_caller_scope", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "42");
}

/// A defaulted parameter on a method, omitted at the call site.
#[test]
fn runtime_method_omitted_default_end_to_end() {
    let src = "struct Counter:\n    mut n: i32\n\nimpl Counter:\n    fn bump(mut self, by: i32 = 1):\n        self.n += by\n\nfn main():\n    let mut c = Counter(n = 0)\n    c.bump()\n    c.bump(5)\n    println(f\"{c.n}\")\n";
    let output = compile_and_run("default_param_method", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "6");
}

/// A method call using named arguments, reordered.
#[test]
fn runtime_method_named_args_end_to_end() {
    let src = "struct P:\n    v: i32\n\nimpl P:\n    fn combine(self, a: i32, b: i32) -> i32:\n        self.v + a - b\n\nfn main():\n    let p = P(v = 100)\n    println(f\"{p.combine(b = 1, a = 2)}\")\n";
    let output = compile_and_run("default_param_method_named", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "101"); // 100 + 2 - 1
}

/// A recursive call can still omit its own trailing default each time.
#[test]
fn runtime_recursive_call_with_default_end_to_end() {
    let src = "fn countdown(n: i32, floor: i32 = 0) -> i32:\n    if n <= floor:\n        return n\n    return countdown(n - 1)\n\nfn main():\n    println(f\"{countdown(5)}\")\n";
    let output = compile_and_run("default_param_recursive", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "0");
}
