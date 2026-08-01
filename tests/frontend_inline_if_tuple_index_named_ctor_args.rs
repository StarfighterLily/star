//! Inline if-expressions, chained tuple indexing, named constructor arguments and field defaults
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== inline if-expressions ================================================

/// The language reference's inline `if`-expression form -- `let result =
/// if x > 0: "pos" else: "neg"`, both arms on the same line -- must parse.
/// Previously `Parser::parse_if_expr` unconditionally demanded an indented
/// block after each `:`, so the documented one-liner failed with "expected
/// end of line".
#[test]
fn parses_inline_if_expression() {
    let src = "fn main():\n    let v = if 3 > 2: 10 else: 20\n";
    let module = Driver::parse(src).expect("inline if-expression should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    assert!(matches!(value, Expr::If { .. }), "{:?}", value);
}

/// Inline `if`-expression arms evaluate to the right values end to end,
/// including one nested inside an f-string hole.
#[test]
fn runtime_inline_if_expression_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let v = if 3 > 2: 10 else: 20\n",
        "    let w = if 3 < 2: 10 else: 20\n",
        "    let s = if v < w: \"lt\" else: \"ge\"\n",
        "    println(f\"{v} {w} {s} {if 1 < 2: 7 else: 8}\")\n",
    );
    let output = compile_and_run("inline_if_expression", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "10 20 lt 7");
}

/// An inline `then` arm may still pair with an indented-block `else` arm --
/// the two arms decide their form independently.
#[test]
fn parses_inline_then_arm_with_block_else_arm() {
    let src = "fn main():\n    let v = if 3 > 2: 10 else:\n        20\n    let w = v\n";
    Driver::parse(src).expect("mixed inline/block if-expression arms should parse");
}

// ===== chained tuple indexing ===============================================

/// `t.0.1` -- a tuple index chained on another tuple index -- must lex as
/// two integer indexes, not fold `0.1` into a float literal. The lexer now
/// suppresses float-fraction folding for a number that immediately follows
/// a member-access `.` (Star has no leading-dot `.5` float spelling, so no
/// real float literal can begin there).
#[test]
fn parses_chained_tuple_index() {
    let src = "fn main():\n    let t = ((1, 2), (3, 4))\n    let x = t.0.1\n";
    let module = Driver::parse(src).expect("chained tuple index should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[1] else { panic!("expected let") };
    let Expr::TupleIndex { base, index: 1, .. } = value else { panic!("expected outer .1: {:?}", value) };
    assert!(matches!(base.as_ref(), Expr::TupleIndex { index: 0, .. }), "{:?}", base);
}

/// Chained tuple indexing reads the right elements end to end, three levels
/// deep -- and ordinary float literals (which share the `digits.digits`
/// shape the lexer fix discriminates on) still work right next to it.
#[test]
fn runtime_chained_tuple_index_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let pair = ((1, (2, 3)), 4)\n",
        "    let f = 0.5\n",
        "    println(f\"{pair.0.1.0} {pair.0.1.1} {pair.1} {f + 0.25}\")\n",
    );
    let output = compile_and_run("chained_tuple_index", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "2 3 4 0.750000");
}

// ===== named constructor arguments and field defaults =======================

/// Named struct-literal arguments match their *named* field, in any order.
/// Previously the parser dropped the names outright and matched every
/// argument positionally, so `Pair(b = 1, a = 2)` silently compiled to
/// `a = 1, b = 2` -- a wrong-values miscompile with no diagnostic.
#[test]
fn runtime_named_struct_args_reorder_end_to_end() {
    let src = concat!(
        "struct Pair:\n    a: i32\n    b: i32\n",
        "fn main():\n",
        "    let p = Pair(b = 1, a = 2)\n",
        "    println(f\"{p.a} {p.b}\")\n",
    );
    let output = compile_and_run("named_struct_args_reorder", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "2 1");
}

/// A field omitted from a construction falls back to its declared default:
/// all-defaults `Config()`, one named override, and a positional prefix
/// (which fills fields in declaration order) with defaults completing the
/// rest. Previously field defaults were parsed but never applied anywhere.
#[test]
fn runtime_struct_field_defaults_end_to_end() {
    let src = concat!(
        "struct Config:\n    width: i32 = 640\n    height: i32 = 480\n    title: str = \"game\"\n",
        "fn main():\n",
        "    let c0 = Config()\n",
        "    let c1 = Config(height = 720)\n",
        "    let c2 = Config(800, title = \"demo\")\n",
        "    println(f\"{c0.width} {c0.height} {c0.title}\")\n",
        "    println(f\"{c1.width} {c1.height} {c1.title}\")\n",
        "    println(f\"{c2.width} {c2.height} {c2.title}\")\n",
    );
    let output = compile_and_run("struct_field_defaults", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["640 480 game", "640 720 game", "800 480 demo"], "{}", stdout);
}

/// Named arguments and defaults work through the generic-struct
/// monomorphization path too (resolution happens at the AST level, before
/// type-parameter unification, so a reordered/omitted argument can't skew
/// the inferred type arguments).
#[test]
fn runtime_named_args_generic_struct_end_to_end() {
    let src = concat!(
        "struct BoxG<T>:\n    value: T\n    tag: i32 = 7\n",
        "fn main():\n",
        "    let a = BoxG(value = 5)\n",
        "    let b = BoxG<str>(tag = 9, value = \"hi\")\n",
        "    println(f\"{a.value} {a.tag} {b.value} {b.tag}\")\n",
    );
    let output = compile_and_run("named_args_generic_struct", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "5 7 hi 9");
}

/// Named arguments match an enum variant's payload fields by name too.
#[test]
fn runtime_named_args_enum_variant_end_to_end() {
    let src = concat!(
        "enum Msg:\n    Move(dx: i32, dy: i32)\n    Quit\n",
        "fn main():\n",
        "    let m = Msg::Move(dy = 3, dx = 4)\n",
        "    match m:\n",
        "        Msg::Move(dx, dy) -> println(f\"{dx} {dy}\")\n",
        "        Msg::Quit -> println(\"quit\")\n",
    );
    let output = compile_and_run("named_args_enum_variant", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "4 3");
}

/// `spawn` constructs the arena's element struct, so named arguments and
/// field defaults apply there exactly like an ordinary struct literal.
#[test]
fn runtime_spawn_named_args_with_defaults_end_to_end() {
    let src = concat!(
        "struct Thing:\n    hp: i32 = 100\n    tag: i32 = 5\n",
        "arena Things: Thing\n",
        "fn main():\n",
        "    spawn Things(tag = 9)\n",
        "    let r = GenRef<Thing>(0)\n",
        "    let t = r[0]\n",
        "    println(f\"{t.hp} {t.tag}\")\n",
    );
    let output = compile_and_run("spawn_named_args_defaults", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "100 9");
}

/// An unknown field name in a struct construction is a clean checker error.
#[test]
fn rejects_unknown_named_ctor_argument() {
    let src = "struct Pair:\n    a: i32\n    b: i32\nfn main():\n    let p = Pair(a = 1, c = 2)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("unknown field name should be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("has no field `c`")), "{:?}", errs);
}

/// The same field given twice (positionally and then again by name) is a
/// clean checker error, not a silent overwrite.
#[test]
fn rejects_duplicate_named_ctor_argument() {
    let src = "struct Pair:\n    a: i32\n    b: i32\nfn main():\n    let p = Pair(1, a = 2)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("duplicate field should be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("given more than once")), "{:?}", errs);
}

/// A positional argument after a named one is ambiguous (which field does
/// it fill?) and is rejected outright, mirroring Python's rule.
#[test]
fn rejects_positional_ctor_argument_after_named() {
    let src = "struct Pair:\n    a: i32\n    b: i32\nfn main():\n    let p = Pair(b = 1, 2)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("positional-after-named should be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("positional argument after a named argument")), "{:?}", errs);
}

/// Omitting a field that has no declared default is a clean checker error
/// naming the missing field.
#[test]
fn rejects_named_ctor_call_missing_field_without_default() {
    let src = "struct Pair:\n    a: i32\n    b: i32\nfn main():\n    let p = Pair(a = 1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("missing defaultless field should be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("missing a value for field `b`")), "{:?}", errs);
}

/// A purely positional construction that undersupplies a struct with *no*
/// defaults keeps the original arity diagnostic (nothing about missing
/// fields or names).
#[test]
fn rejects_positional_ctor_undersupply_with_original_arity_error() {
    let src = "struct Pair:\n    a: i32\n    b: i32\nfn main():\n    let p = Pair(1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("positional undersupply should be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("expects 2 argument(s), found 1")), "{:?}", errs);
}

/// Ordinary function calls *do* now support named arguments, reordered
/// freely (`docs/requests.md` #6, `Checker::resolve_call_arg_exprs`) --
/// previously `name = expr` here was rejected outright (silently dropping
/// the name would have let `f(b = 1, a = 2)` *look* reordered while
/// matching purely positionally instead). See `tests/
/// frontend_default_params.rs` for the fuller test suite covering this
/// (defaults, unknown/duplicate names, positional-after-named, method
/// calls, ...); this one just pins down that this exact call -- the very
/// shape this test used to assert was rejected -- now type-checks and
/// actually reorders.
#[test]
fn accepts_named_arguments_on_ordinary_call() {
    let src = "fn add(a: i32, b: i32) -> i32:\n    a + b\nfn main():\n    let x = add(b = 1, a = 2)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("named args on an ordinary fn call should now type-check");
}

/// Builtin constructors (`Vec3`, `List`, ...) have no user-declared field
/// list to match names against, so named arguments there are rejected.
#[test]
fn rejects_named_arguments_on_builtin_constructor() {
    let src = "fn main():\n    let v = Vec3(x = 1.0, y = 2.0, z = 3.0)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("named args on Vec3(..) should be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("named arguments are not supported")), "{:?}", errs);
}

/// All-named construction sites in declaration order -- the pre-existing
/// examples' style -- still work unchanged through the new resolution.
#[test]
fn runtime_named_args_in_declaration_order_end_to_end() {
    let src = concat!(
        "struct Player:\n    name: str\n    hp: i32\n",
        "fn main():\n",
        "    let p = Player(name = \"Hero\", hp = 100)\n",
        "    println(f\"{p.name} {p.hp}\")\n",
    );
    let output = compile_and_run("named_args_declaration_order", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "Hero 100");
}

// === `Bytes` (docs/design.md's "Text and bytes" section) ===================

/// `Bytes()` starts empty; `push`/`len`/`[i]` behave exactly like `List<u8>`
/// (`Ty::Bytes` reuses that codegen wholesale -- see `Ty::Bytes`'s doc
/// comment).
#[test]
fn runtime_bytes_construct_push_len_index_end_to_end() {
    let src = "fn main():\n    let mut b = Bytes()\n    println(f\"{b.len()}\")\n    \
               b.push(10 as u8)\n    b.push(20 as u8)\n    b.push(30 as u8)\n    \
               println(f\"{b.len()}\")\n    println(f\"{b[0]} {b[1]} {b[2]}\")\n";
    let output = compile_and_run("bytes_construct_push_len_index", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["0", "3", "10 20 30"], "{}", stdout);
}

/// `bytes[i] = v` writes through in place, and a `u8` value wider than one
/// byte (via `as u8`) truncates, matching `List<u8>`'s own element-store
/// convention.
#[test]
fn runtime_bytes_index_write_end_to_end() {
    let src = "fn main():\n    let mut b = Bytes()\n    b.push(1 as u8)\n    b.push(2 as u8)\n    \
               b[0] = 250 as u8\n    b[1] = 321 as u8\n    println(f\"{b[0]} {b[1]}\")\n";
    let output = compile_and_run("bytes_index_write", src);
    assert!(output.status.success(), "{:?}", output.status);
    // 321 truncated to u8 is 321 - 256 = 65.
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "250 65");
}

/// `pop()` removes the last-pushed byte, LIFO.
#[test]
fn runtime_bytes_pop_end_to_end() {
    let src = "fn main():\n    let mut b = Bytes()\n    b.push(1 as u8)\n    b.push(2 as u8)\n    b.push(3 as u8)\n    \
               println(f\"{b.pop()}\")\n    println(f\"{b.pop()}\")\n    println(f\"{b.len()}\")\n";
    let output = compile_and_run("bytes_pop", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["3", "2", "1"], "{}", stdout);
}

/// An out-of-bounds read/pop on an empty (never-pushed) `Bytes` yields `0`,
/// the element type's zero value -- the same "safe null equivalent"
/// convention `List<T>` uses, not a crash or trap.
#[test]
fn runtime_bytes_out_of_bounds_reads_are_safe_end_to_end() {
    let src = "fn main():\n    let mut b = Bytes()\n    println(f\"{b[0]}\")\n    println(f\"{b.pop()}\")\n    \
               b.push(9 as u8)\n    println(f\"{b[5]}\")\n";
    let output = compile_and_run("bytes_oob_safe", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["0", "0", "0"], "{}", stdout);
}

/// `let b = a` is an O(1) refcount bump sharing one buffer; mutating one
/// binding (`push`) must not be visible through the other -- the same
/// copy-on-write guarantee `List<T>` gives (`Ty::Bytes`'s doc comment: it
/// reuses that exact codegen).
#[test]
fn runtime_bytes_copy_on_write_end_to_end() {
    let src = "fn main():\n    let mut a = Bytes()\n    a.push(1 as u8)\n    a.push(2 as u8)\n    \
               let b = a\n    a.push(3 as u8)\n    println(f\"{a.len()} {b.len()}\")\n";
    let output = compile_and_run("bytes_cow", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "3 2");
}

/// `bytes_from_str`/`str_from_bytes` round-trip a `str`'s bytes exactly,
/// including the empty string (a real `malloc(0)`, not special-cased).
#[test]
fn runtime_bytes_from_str_round_trip_end_to_end() {
    let src = "fn main():\n    let b = bytes_from_str(\"Hi!\")\n    println(f\"{b.len()}\")\n    println(f\"{b[0]} {b[1]} {b[2]}\")\n    \
               println(str_from_bytes(b))\n    let empty = bytes_from_str(\"\")\n    println(f\"{empty.len()}\")\n    \
               println(f\"[{str_from_bytes(empty)}]\")\n";
    let output = compile_and_run("bytes_from_str_round_trip", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["3", "72 105 33", "Hi!", "0", "[]"], "{}", stdout);
}

/// `Bytes` is a nominally distinct type from `List<u8>`, even though they
/// share an identical runtime layout (mirrors `Handle<T>` vs. `GenRef<T>`).
#[test]
fn rejects_bytes_passed_where_list_u8_expected() {
    let src = "fn take(xs: List<u8>) -> i32:\n    xs.len()\nfn main():\n    let b = Bytes()\n    take(b)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("Bytes should not satisfy a List<u8> parameter");
    assert!(!diags.is_empty(), "{:?}", diags);
}

#[test]
fn rejects_bytes_constructor_with_arguments() {
    let src = "fn main():\n    let b = Bytes(1 as u8)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("Bytes() should take no arguments");
    assert!(diags.iter().any(|d| d.message.contains("takes no arguments")), "{:?}", diags);
}

/// `Bytes` has no structural-equality story (mirrors `List<T>`), so it can't
/// be used as a `Map`/`Set` key.
#[test]
fn rejects_bytes_used_as_map_key() {
    let src = "fn main():\n    let m: Map<Bytes, i32> = Map<Bytes, i32>()\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("Bytes should not be a legal Map key type");
    assert!(diags.iter().any(|d| d.message.contains("cannot be used as a `Map`/`Set` key")), "{:?}", diags);
}

/// Repeated push/pop churn well past the initial capacity doubles -- a
/// regression guard on `emit_bytes_from_str`/`ListMethod::Push`'s grow path
/// leaking the buffer it replaces every time it doubles.
#[test]
fn runtime_bytes_push_growth_does_not_leak_end_to_end() {
    let src = "fn main():\n    let mut b = Bytes()\n    let mut i: i32 = 0\n    let mut total: i32 = 0\n    \
               while i < 400000:\n        b.push((i as u8))\n        total = total + (b[b.len() - 1] as i32)\n        \
               if b.len() > 1000:\n            b.pop()\n        i += 1\n    println(\"done\")\n";
    assert_no_leak("bytes_push_growth_leak", src, 20 * 1024 * 1024);
}

// === `Symbol` (docs/design.md's "Text and bytes" section) ==================

/// Two `Symbol(..)` constructions of equal strings intern to the same id,
/// so `==` between them is `true` -- the core guarantee this type exists
/// for (`docs/design.md`: "comparing tags... every frame is a real cost").
#[test]
fn runtime_symbol_equal_strings_intern_to_same_id_end_to_end() {
    let src = "fn main():\n    let a = Symbol(\"player\")\n    let b = Symbol(\"player\")\n    println(f\"{a == b}\")\n";
    let output = compile_and_run("symbol_equal_strings_same_id", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "true");
}

/// Distinct strings intern to distinct ids.
#[test]
fn runtime_symbol_distinct_strings_differ_end_to_end() {
    let src = "fn main():\n    let a = Symbol(\"player\")\n    let b = Symbol(\"enemy\")\n    println(f\"{a == b}\")\n    println(f\"{a != b}\")\n";
    let output = compile_and_run("symbol_distinct_strings_differ", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "true"], "{}", stdout);
}

/// `Symbol <-> i64` is a free bit-preserving relabel; interning order is
/// deterministic (first-seen order) within one run, so ids are stable.
#[test]
fn runtime_symbol_cast_round_trip_end_to_end() {
    let src = "fn main():\n    let a = Symbol(\"first\")\n    let b = Symbol(\"second\")\n    \
               let a_id = a as i64\n    let b_id = b as i64\n    println(f\"{a_id} {b_id}\")\n    \
               let back = b_id as Symbol\n    println(f\"{back == b}\")\n";
    let output = compile_and_run("symbol_cast_round_trip", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["0 1", "true"], "{}", stdout);
}

/// `symbol_name` reverses the interning lookup, returning the original
/// string -- and a fresh, independently-owned copy (a second call, or
/// releasing the caller's copy, must not corrupt the table's own entry).
#[test]
fn runtime_symbol_name_round_trip_end_to_end() {
    let src = "fn main():\n    let a = Symbol(\"hello world\")\n    println(symbol_name(a))\n    println(symbol_name(a))\n";
    let output = compile_and_run("symbol_name_round_trip", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["hello world", "hello world"], "{}", stdout);
}

/// A `Symbol` id that never came from `Symbol(..)` (here, an out-of-range
/// `as`-cast integer) is a safe out-of-bounds read rather than a crash:
/// `symbol_name` returns a real, freshly-allocated empty `str`.
///
/// Previously this returned `Codegen::zero_value(&Ty::Str)` -- a bare `null`
/// `i8*` -- instead of a real empty string, on the theory (this test used to
/// assert it directly) that it was "the same safe zero value `List<T>::pop`'s
/// empty-list case does" and therefore harmless; `println`'s f-string `%s`
/// hole happens to tolerate a null argument on this libc (rendering the
/// literal text `(null)`), which masked the actual problem. Confirmed as a
/// real, separate bug (not just a cosmetic one) via `runtime_symbol_name_out_
/// of_range_result_is_usable_as_a_real_string_end_to_end` below: passing that
/// same null "empty string" to `len(..)` (`strlen` on a null pointer)
/// segfaulted outright -- a null `str` is not actually interchangeable with
/// an empty one anywhere except that one lucky `printf` call. Fixed in
/// `Codegen::emit_symbol_name` (`src/codegen/symbol.rs`) by building a real
/// owned empty string (`star_rc_alloc` + a lone NUL byte, `env_get`'s
/// missing-variable convention) on the out-of-range path instead.
#[test]
fn runtime_symbol_name_out_of_range_returns_zero_value_end_to_end() {
    let src = "fn main():\n    let a = Symbol(\"only one\")\n    let bogus = (999999 as i64) as Symbol\n    println(f\"[{symbol_name(bogus)}]\")\n";
    let output = compile_and_run("symbol_name_out_of_range", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "[]");
}

/// Companion to `runtime_symbol_name_out_of_range_returns_zero_value_end_to_
/// end` above: an out-of-range `symbol_name` result must be a real,
/// independently-owned empty `str` any other string builtin can safely
/// operate on, not just something `println`'s f-string hole happens to
/// tolerate. Before the fix documented there, `len(..)` on this result
/// (`strlen` dereferencing a bare `null` `i8*`) segfaulted the whole
/// process.
#[test]
fn runtime_symbol_name_out_of_range_result_is_usable_as_a_real_string_end_to_end() {
    let src = "fn main():\n    let bogus = (999999 as i64) as Symbol\n    let n = symbol_name(bogus)\n    println(f\"{len(n)}\")\n";
    let output = compile_and_run("symbol_name_out_of_range_usable", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "0");
}

/// `List<str>::pop()` on an empty list is a safe out-of-bounds read rather
/// than a crash: it returns a real, freshly-allocated empty `str`.
///
/// Previously this returned `Codegen::zero_value(&Ty::Str)` -- a bare `null`
/// `i8*` -- exactly the same root cause `symbol_name`'s out-of-range fix
/// above addresses (see `runtime_symbol_name_out_of_range_returns_zero_value_
/// end_to_end`'s doc comment), just for `List<T>`'s own OOB/empty-pop
/// convention instead of `Symbol`'s. Confirmed as a real, separate segfault
/// (not just symbol.rs's already-fixed case) via a real `star build`+run of
/// `let mut l: List<str> = List<str>(); len(l.pop())` before this fix (`len`'s
/// `strlen` dereferencing the null "empty string" `pop` actually returned).
/// Fixed in `Codegen::zero_value_rc` (`src/codegen/mod.rs`), used by
/// `ListMethod::Pop`'s empty-list fallback (`src/codegen/list.rs`).
#[test]
fn runtime_list_pop_empty_result_is_usable_as_a_real_string_end_to_end() {
    let src = "fn main():\n    let mut l: List<str> = List<str>()\n    let s = l.pop()\n    println(f\"{len(s)}\")\n";
    let output = compile_and_run("list_pop_empty_str_usable", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "0");
}

/// Companion to `runtime_list_pop_empty_result_is_usable_as_a_real_string_end_
/// to_end` above, for `List<str>`'s other out-of-bounds-read path:
/// `list[idx]` past the end. Same fix (`Codegen::zero_value_rc`), same
/// `List<T>` module, different call site (`Codegen::emit_list_index`).
#[test]
fn runtime_list_index_out_of_bounds_str_result_is_usable_as_a_real_string_end_to_end() {
    let src = "fn main():\n    let l: List<str> = List<str>()\n    let s = l[5]\n    println(f\"{len(s)}\")\n";
    let output = compile_and_run("list_index_oob_str_usable", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "0");
}

/// `Ring<str,N>::pop()` on an empty ring is the same "safe zero-value read"
/// bug class as `List<str>::pop()` above (`Codegen::zero_value_rc`'s other
/// caller, `RingMethod::Pop` in `src/codegen/ring.rs`), confirmed via a real
/// segfault building and running `let mut r: Ring<str,4> = Ring<str,4>();
/// len(r.pop())` before this fix.
#[test]
fn runtime_ring_pop_empty_result_is_usable_as_a_real_string_end_to_end() {
    let src = "fn main():\n    let mut r: Ring<str, 4> = Ring<str, 4>()\n    let s = r.pop()\n    println(f\"{len(s)}\")\n";
    let output = compile_and_run("ring_pop_empty_str_usable", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "0");
}

/// Companion to `runtime_ring_pop_empty_result_is_usable_as_a_real_string_end_
/// to_end` above, for `Ring<str,N>`'s other out-of-bounds-read path:
/// `ring[idx]` past the current (dynamic) length. Same fix
/// (`Codegen::zero_value_rc`), different call site (`ring_index_ptr`).
#[test]
fn runtime_ring_index_out_of_bounds_str_result_is_usable_as_a_real_string_end_to_end() {
    let src = "fn main():\n    let r: Ring<str, 4> = Ring<str, 4>()\n    let s = r[2]\n    println(f\"{len(s)}\")\n";
    let output = compile_and_run("ring_index_oob_str_usable", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "0");
}

/// `[str; N]` (a fixed-size array) indexed out of bounds is the same "safe
/// zero-value read" bug class as `List<str>[idx]` above, just for
/// `crate::codegen::array`'s own `array_index_ptr` fallback -- confirmed via
/// a real segfault building and running `let a: [str; 3] = ["x"; 3];
/// len(a[99])` before this fix.
#[test]
fn runtime_array_index_out_of_bounds_str_result_is_usable_as_a_real_string_end_to_end() {
    let src = "fn main():\n    let a: [str; 3] = [\"x\"; 3]\n    let s = a[99]\n    println(f\"{len(s)}\")\n";
    let output = compile_and_run("array_index_oob_str_usable", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "0");
}

/// `Table<T>::pop()` on an empty table, and `table[idx]` out of bounds, hand
/// back `T`'s zero value -- but `T` is always a struct (`Table<T>` requires
/// it), so `Codegen::zero_value`'s flat `zeroinitializer` would leave any
/// `str`-typed *field* of that zeroed struct as the same bare-null-disguised-
/// as-`str` hazard `List<str>::pop()` had, just one level of field-access
/// deeper. Confirmed via a real segfault building and running
/// `Table<Enemy>().pop()` (`Enemy` having a `name: str` field) then reading
/// `len(popped.name)`, and separately `Table<Enemy>()[99]` then
/// `len(oob.name)`, before this fix. Fixed in `Codegen::emit_table_index`'s
/// out-of-bounds branch and `TableMethod::Pop`'s empty branch
/// (`src/codegen/table.rs`), building the zero struct field-by-field via
/// `Codegen::zero_value_rc` instead of one flat `zero_value(ty)` store.
#[test]
fn runtime_table_pop_and_index_empty_struct_str_field_is_usable_as_a_real_string_end_to_end() {
    let src = "struct Enemy:\n    mut hp: i32\n    name: str\n\nfn main():\n    let mut t: Table<Enemy> = Table<Enemy>()\n    let popped = t.pop()\n    println(f\"{len(popped.name)}\")\n    let mut t2: Table<Enemy> = Table<Enemy>()\n    t2.push(Enemy(hp = 1, name = \"a\"))\n    let oob = t2[99]\n    println(f\"{len(oob.name)}\")\n";
    let output = compile_and_run("table_pop_and_index_empty_str_field_usable", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["0", "0"], "{}", stdout);
}

/// `Symbol` is a legal `Map`/`Set` key (`Checker::check_hashable_ty`) --
/// comparison is a single `i64` compare, so re-inserting an equal `Symbol`
/// overwrites rather than duplicating.
#[test]
fn runtime_symbol_as_map_key_end_to_end() {
    let src = "fn main():\n    let mut hp: Map<Symbol, i32> = Map<Symbol, i32>()\n    \
               hp.insert(Symbol(\"player\"), 100)\n    hp.insert(Symbol(\"enemy\"), 40)\n    hp.insert(Symbol(\"player\"), 80)\n    \
               println(f\"{hp.len()}\")\n    \
               match hp.get(Symbol(\"player\")):\n        Option::Some(v) -> println(f\"{v}\")\n        Option::None -> println(\"missing\")\n";
    let output = compile_and_run("symbol_as_map_key", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["2", "80"], "{}", stdout);
}

/// `Set<Symbol>` dedups equal-string `Symbol`s -- this is the regression
/// this section's `eq.rs` fix guards: before adding a dedicated
/// `Ty::Symbol` arm to `emit_eq_body`, its `_ => "true".into()` fallback
/// made every `Symbol` compare equal to every other one inside a
/// `Map`/`Set`, silently collapsing all keys/elements to one.
#[test]
fn runtime_symbol_as_set_key_dedups_end_to_end() {
    let src = "fn main():\n    let mut tags: Set<Symbol> = Set<Symbol>()\n    \
               tags.insert(Symbol(\"flying\"))\n    tags.insert(Symbol(\"flying\"))\n    tags.insert(Symbol(\"armored\"))\n    \
               println(f\"{tags.len()}\")\n    println(f\"{tags.contains(Symbol(\"flying\"))}\")\n    println(f\"{tags.contains(Symbol(\"stealth\"))}\")\n";
    let output = compile_and_run("symbol_as_set_key_dedups", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["2", "true", "false"], "{}", stdout);
}

#[test]
fn rejects_symbol_constructor_with_non_str_argument() {
    let src = "fn main():\n    let a = Symbol(1)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("Symbol(..) should require a str argument");
    assert!(diags.iter().any(|d| d.message.contains("expects 1 `str` argument")), "{:?}", diags);
}

/// Only `==`/`!=` are supported between `Symbol` values -- interning order
/// is an implementation detail, not a meaningful sort.
#[test]
fn rejects_symbol_ordering_comparison() {
    let src = "fn main():\n    let a = Symbol(\"a\")\n    let b = Symbol(\"b\")\n    let c = a < b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("`<` between Symbols should be rejected");
    assert!(diags.iter().any(|d| d.message.contains("only `==`/`!=` are supported between `Symbol` values")), "{:?}", diags);
}

/// `Symbol` never implicitly mixes with a bare `i64` -- same "no implicit
/// anything" rule every other explicit-width/nominal type in this section
/// follows (an explicit `as` cast is always required).
#[test]
fn rejects_binop_between_symbol_and_bare_i64() {
    let src = "fn main():\n    let a = Symbol(\"a\")\n    let n: i64 = 0\n    let c = a == n\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("Symbol == i64 without a cast should be rejected");
    assert!(!diags.is_empty(), "{:?}", diags);
}

/// Repeatedly re-interning the *same* string exercises the "already
/// present" path (release-then-return-existing-id) in a loop -- a
/// regression guard on that path leaking the freshly-constructed `str`
/// argument instead of releasing it once its id is found.
#[test]
fn runtime_symbol_repeated_interning_of_same_string_does_not_leak_end_to_end() {
    let src = "fn main():\n    let mut i: i32 = 0\n    let mut total: i64 = 0 as i64\n    \
               while i < 400000:\n        let s = Symbol(\"same tag every time\")\n        total = total + (s as i64)\n        i += 1\n    \
               println(\"done\")\n";
    assert_no_leak("symbol_repeated_intern_leak", src, 20 * 1024 * 1024);
}

/// A closure literal lowers to its own independent top-level LLVM function
/// (see `Codegen::emit_closure_lit`), not an inline block of whatever
/// function it happens to be lexically written inside -- so a `break`/
/// `continue` in its body has no well-defined target even when the closure
/// literal sits lexically inside an enclosing `while`/`for` loop.
/// `Checker::loop_depth` was previously left untouched while checking a
/// closure body (unlike `Stmt::Par`'s body, which already resets it to `0`
/// for exactly this reason -- a `par`/`swarm` body also lowers to its own
/// separate function), so a closure defined inside a loop silently inherited
/// that loop's nonzero depth and a bare `break` directly in the closure's own
/// body type-checked cleanly. Confirmed via a real `star build` failure: the
/// closure still lowers to its own deferred `closure_N` function, but
/// codegen's `TypedStmt::Break` arm (which never needed to save/restore
/// `loop_stack` itself, since this checker gap was the only way a closure
/// body could ever contain a `break`/`continue` at all) emitted `br label
/// %while_end_3` -- a block label that only exists in the *enclosing*
/// `main` function -- and `clang` rejected the resulting IR with "use of
/// undefined value '%while_end_3'". Fixed by resetting `self.loop_depth` to
/// `0` around a closure body's type-checking, mirroring `Stmt::Par`'s own
/// `saved_loop_depth` handling.
#[test]
fn rejects_break_inside_closure_defined_in_loop() {
    let src = "fn main():\n    let mut i: i32 = 0\n    while i < 3:\n        let f = fn():\n            break\n        f()\n        i = i + 1\n    println(\"done\")\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module)
        .expect_err("a bare `break` inside a closure body must be rejected even when the closure is lexically inside a loop");
    assert!(errs.iter().any(|d| d.message.contains("break") && d.message.contains("outside of a loop")), "{:?}", errs);
}

/// Same bug as above, `continue` instead of `break`.
#[test]
fn rejects_continue_inside_closure_defined_in_loop() {
    let src = "fn main():\n    let mut i: i32 = 0\n    while i < 3:\n        let f = fn():\n            continue\n        f()\n        i = i + 1\n    println(\"done\")\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module)
        .expect_err("a bare `continue` inside a closure body must be rejected even when the closure is lexically inside a loop");
    assert!(errs.iter().any(|d| d.message.contains("continue") && d.message.contains("outside of a loop")), "{:?}", errs);
}

/// Companion control for the fix above: a closure with its *own* internal
/// loop must still be able to use `break`/`continue` normally inside that
/// loop -- only a `break`/`continue` with no loop of its own (only reachable
/// by inheriting an outer, lexically-enclosing loop's depth) is rejected.
/// Guards against an overly-blunt fix (e.g. unconditionally banning
/// `break`/`continue` anywhere inside a closure) breaking this legitimate case.
#[test]
fn runtime_closure_with_own_loop_break_still_works_end_to_end() {
    let src = "fn main():\n    let f = fn() -> i32:\n        let mut i: i32 = 0\n        while i < 10:\n            if i == 3:\n                break\n            i = i + 1\n        i\n    println(f\"{f()}\")\n";
    let output = compile_and_run("closure_own_loop_break", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim(), "3", "{}", stdout);
}
