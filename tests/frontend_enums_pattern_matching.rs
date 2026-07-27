//! `for`/`break`/`continue`, enums, payload enums, Option/Result, struct destructuring
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== `for`/`break`/`continue` + `enum` ====================================

/// Parse `for var in start..end:` into a `Stmt::For`.
#[test]
fn parses_for_stmt() {
    let src = "fn t():\n    for i in 0..10:\n        break\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::For { var, start, end, body, .. } = &f.body.stmts[0] else { panic!("expected For") };
    assert_eq!(var, "i");
    assert!(matches!(start, Expr::Int(0, _)));
    assert!(matches!(end, Expr::Int(10, _)));
    assert_eq!(body.stmts.len(), 1);
}

/// Parse a bare `break` statement.
#[test]
fn parses_break_stmt() {
    let src = "fn t():\n    while true:\n        break\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::While { body, .. } = &f.body.stmts[0] else { panic!("expected While") };
    assert!(matches!(body.stmts[0], Stmt::Break { .. }));
}

/// Parse a bare `continue` statement.
#[test]
fn parses_continue_stmt() {
    let src = "fn t():\n    while true:\n        continue\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::While { body, .. } = &f.body.stmts[0] else { panic!("expected While") };
    assert!(matches!(body.stmts[0], Stmt::Continue { .. }));
}

/// Parse an `enum` declaration into its ordered variant names.
#[test]
fn parses_enum_decl() {
    let src = "enum Direction:\n    North\n    South\n    East\n    West\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Enum(EnumDef { name, variants, .. }) = &module.items[0] else { panic!("expected enum") };
    assert_eq!(name, "Direction");
    let names: Vec<&str> = variants.iter().map(|v| v.name.as_str()).collect();
    assert_eq!(names, vec!["North", "South", "East", "West"]);
    assert!(variants.iter().all(|v| v.fields.is_empty()), "all variants should be fieldless: {:?}", variants);
}

/// Parse an `EnumName::Variant` expression.
#[test]
fn parses_enum_variant_expr() {
    let src = "enum Direction:\n    North\n\nfn t():\n    Direction::North\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Expr(Expr::EnumVariant { enum_name, variant, .. }) = &f.body.stmts[0] else {
        panic!("expected EnumVariant expr, got {:?}", f.body.stmts[0])
    };
    assert_eq!(enum_name, "Direction");
    assert_eq!(variant, "North");
}

/// Parse an `EnumName::Variant` match pattern.
#[test]
fn parses_enum_variant_pattern() {
    let src = "enum Direction:\n    North\n    South\n\nfn t(d: Direction):\n    match d:\n        Direction::North -> 1\n        _ -> 2\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Expr(Expr::Match { arms, .. }) = &f.body.stmts[0] else { panic!("expected match") };
    match &arms[0].pattern {
        Pattern::EnumVariant(enum_name, variant, bindings) => {
            assert_eq!(enum_name, "Direction");
            assert_eq!(variant, "North");
            assert!(bindings.is_empty());
        }
        other => panic!("expected EnumVariant pattern, got {:?}", other),
    }
    assert!(matches!(arms[1].pattern, Pattern::Wildcard));
}

const DIRECTION_ENUM_SRC: &str = "enum Direction:\n    North\n    South\n    East\n    West\n\n";

/// A `for` loop's variable is bound as `i32` inside its body.
#[test]
fn checks_for_loop_var_is_int() {
    let src = "fn t() -> i32:\n    for i in 0..5:\n        return i\n    return -1\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "for loop variable should be usable as i32");
}

/// A `for` loop whose range bound isn't `i32` is a type error.
#[test]
fn rejects_for_range_non_int_bound() {
    let src = "fn t():\n    for i in 0..2.0:\n        let x: i32 = i\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "non-i32 range bound should be a type error");
}

/// `break` outside of any loop is a type error.
#[test]
fn rejects_break_outside_loop() {
    let module = Driver::parse("fn t():\n    break\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "break outside a loop should be a type error");
}

/// `continue` outside of any loop is a type error.
#[test]
fn rejects_continue_outside_loop() {
    let module = Driver::parse("fn t():\n    continue\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "continue outside a loop should be a type error");
}

/// `break` inside a `while` loop type-checks.
#[test]
fn accepts_break_inside_while() {
    let module = Driver::parse("fn t():\n    while true:\n        break\n").expect("should parse");
    assert!(Driver::check(&module).is_ok(), "break inside a while loop should be allowed");
}

/// `continue` inside a `for` loop type-checks.
#[test]
fn accepts_continue_inside_for() {
    let module = Driver::parse("fn t():\n    for i in 0..5:\n        continue\n").expect("should parse");
    assert!(Driver::check(&module).is_ok(), "continue inside a for loop should be allowed");
}

/// `break` inside a `par`/`swarm` body is rejected even when the `par`
/// statement is lexically nested inside an outer loop: a worker-thread
/// dispatch has no well-defined `break` target.
#[test]
fn rejects_break_inside_par_even_when_nested_in_loop() {
    let src = format!(
        "{}fn t():\n    while true:\n        par e in Enemies:\n            break\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "break inside a par body should be a type error even inside an outer loop");
}

/// `EnumName::Variant` infers to that enum's type.
#[test]
fn checks_enum_variant_type() {
    let src = format!("{}fn t() -> Direction:\n    Direction::North\n", DIRECTION_ENUM_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let f = typed.items.iter().find_map(|i| if let TypedItem::Fn(f) = i { Some(f) } else { None }).expect("expected a fn item");
    let ty = match f.body.stmts.last().expect("body should have a statement") {
        TypedStmt::Expr(e) => e.clone().into_ty(),
        other => panic!("expected trailing expr statement, got {:?}", other),
    };
    assert_eq!(ty, Ty::Enum("Direction".into()));
}

/// An undefined variant on a known enum is a type error with a "did you
/// mean" suggestion.
#[test]
fn rejects_undefined_enum_variant_with_suggestion() {
    let src = format!("{}fn t():\n    Direction::Norht\n", DIRECTION_ENUM_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("undefined variant should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("no variant `Norht`")), "{:?}", diags);
    assert!(
        diags.iter().any(|d| d.note.as_deref().unwrap_or("").contains("North")),
        "expected a `did you mean North?` note: {:?}",
        diags
    );
}

/// An undefined enum name is a type error.
#[test]
fn rejects_undefined_enum_name() {
    let module = Driver::parse("fn t():\n    Nope::Foo\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "undefined enum should be a type error");
}

/// A match pattern naming a different enum than the scrutinee's type is a
/// type error.
#[test]
fn rejects_match_pattern_enum_mismatch() {
    let src = format!(
        "{}enum Color:\n    Red\n    Blue\n\nfn t(d: Direction):\n    match d:\n        Color::Red -> 1\n        _ -> 2\n",
        DIRECTION_ENUM_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "mismatched enum pattern should be a type error");
}

/// Codegen for `for`: an `i32` counter alloca, an `icmp slt` bound check,
/// and an increment-by-one step distinct from the condition/body blocks
/// (so `continue` can target the increment without re-running the body).
#[test]
fn codegen_for_loop_uses_counter_and_increment() {
    let src = "fn t() -> i32:\n    let mut total: i32 = 0\n    for i in 0..5:\n        total += i\n    total\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("for_cond"), "{}", ir);
    assert!(ir.contains("for_body"), "{}", ir);
    assert!(ir.contains("for_step"), "{}", ir);
    assert!(ir.contains("for_end"), "{}", ir);
    assert!(ir.contains("icmp slt i32"), "{}", ir);
    assert!(ir.contains("add i32"), "{}", ir);
}

/// Codegen for `break`: branches directly to the loop's end block.
#[test]
fn codegen_break_branches_to_loop_end() {
    let src = "fn t():\n    while true:\n        break\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("br label %while_end_"), "{}", ir);
}

/// Codegen for `continue` inside a `for` loop: branches to the step block,
/// not straight back to the condition (so the counter still increments).
#[test]
fn codegen_continue_branches_to_for_step() {
    let src = "fn t():\n    for i in 0..5:\n        continue\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("br label %for_step_"), "{}", ir);
}

/// Codegen for an enum variant literal: lowers straight to its
/// declaration-order `i32` discriminant, no runtime work involved.
#[test]
fn codegen_enum_variant_lowers_to_discriminant_constant() {
    let src = format!("{}fn t() -> Direction:\n    Direction::East\n", DIRECTION_ENUM_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    // East is the third variant (North=0, South=1, East=2).
    assert!(ir.contains("ret i32 2"), "{}", ir);
}

/// Codegen for `match` on an enum: each arm compares the scrutinee against
/// its variant's discriminant via `icmp eq`, and an exhaustive match (no
/// wildcard arm) still produces well-formed IR (every block has a
/// terminator) even though the last arm has no following arm to close its
/// "no match" branch.
#[test]
fn codegen_match_enum_variant_uses_icmp_eq_and_terminates_last_arm() {
    let src = format!(
        "{}fn print_dir(d: Direction):\n    match d:\n        Direction::North -> println(\"n\")\n        Direction::South -> println(\"s\")\n        Direction::East -> println(\"e\")\n        Direction::West -> println(\"w\")\n",
        DIRECTION_ENUM_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert_eq!(ir.matches("icmp eq i32").count(), 4, "one comparison per variant: {}", ir);
    // The last arm's "next" block must be closed with a branch to the
    // match's end block, not left dangling before the next label.
    assert!(!ir.contains("match_next_3:\nmatch_end_"), "last arm's next-block must not be left without a terminator: {}", ir);
}

/// Runtime test: `examples/control_flow.exe` exercises `for`/`break`/
/// `continue` (including a `continue`+`break` combo, nested loops, and a
/// `while` loop) and matching on every variant of a fieldless `enum`, end
/// to end through a real clang-compiled executable.
#[test]
fn runtime_control_flow_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/control_flow.exe").output().expect("failed to execute control_flow.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("sum: 23"), "continue+break in a for loop: {}", stdout);
    assert!(stdout.contains("nested: 3"), "break in a nested for loop: {}", stdout);
    assert!(stdout.contains("while: 4"), "break in a while loop: {}", stdout);
    assert!(stdout.contains("dir: north"), "match on first enum variant: {}", stdout);
    assert!(stdout.contains("dir: west"), "match on last enum variant: {}", stdout);
}

// ===== payload-carrying enums (`Option`/`Result`-style) ====================

const INT_OPTION_ENUM_SRC: &str = "enum IntOption:\n    None\n    Some(value: i32)\n\n";

/// Parse an enum with a fieldless variant and a payload variant.
#[test]
fn parses_enum_variant_with_payload_fields() {
    let src = "enum IntOption:\n    None\n    Some(value: i32)\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Enum(EnumDef { name, variants, .. }) = &module.items[0] else { panic!("expected enum") };
    assert_eq!(name, "IntOption");
    assert_eq!(variants.len(), 2);
    assert_eq!(variants[0].name, "None");
    assert!(variants[0].fields.is_empty());
    assert_eq!(variants[1].name, "Some");
    assert_eq!(variants[1].fields.len(), 1);
    assert_eq!(variants[1].fields[0].name, "value");
    assert_eq!(variants[1].fields[0].ty, Type::Named("i32".into()));
}

/// Parse a multi-field payload variant: `Rect(width: i32, height: i32)`.
#[test]
fn parses_enum_variant_with_multiple_payload_fields() {
    let src = "enum Shape:\n    Circle(radius: i32)\n    Rect(width: i32, height: i32)\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Enum(EnumDef { variants, .. }) = &module.items[0] else { panic!("expected enum") };
    assert_eq!(variants[1].name, "Rect");
    let field_names: Vec<&str> = variants[1].fields.iter().map(|f| f.name.as_str()).collect();
    assert_eq!(field_names, vec!["width", "height"]);
}

/// Parse a payload variant constructor: `IntOption::Some(5)`.
#[test]
fn parses_enum_variant_ctor_expr_with_args() {
    let src = format!("{}fn t():\n    IntOption::Some(5)\n", INT_OPTION_ENUM_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Expr(Expr::EnumVariant { enum_name, variant, args, .. }) = &f.body.stmts[0] else {
        panic!("expected EnumVariant expr, got {:?}", f.body.stmts[0])
    };
    assert_eq!(enum_name, "IntOption");
    assert_eq!(variant, "Some");
    assert_eq!(args.len(), 1);
    assert!(matches!(args[0], Expr::Int(5, _)));
}

/// Parse a payload variant match pattern's destructuring bindings:
/// `IntOption::Some(v) -> ...`.
#[test]
fn parses_enum_variant_pattern_with_bindings() {
    let src = format!(
        "{}fn t(o: IntOption) -> i32:\n    match o:\n        IntOption::Some(v) -> v\n        IntOption::None -> 0\n",
        INT_OPTION_ENUM_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Expr(Expr::Match { arms, .. }) = &f.body.stmts[0] else { panic!("expected match") };
    match &arms[0].pattern {
        Pattern::EnumVariant(enum_name, variant, bindings) => {
            assert_eq!(enum_name, "IntOption");
            assert_eq!(variant, "Some");
            assert_eq!(bindings, &vec!["v".to_string()]);
        }
        other => panic!("expected EnumVariant pattern, got {:?}", other),
    }
    match &arms[1].pattern {
        Pattern::EnumVariant(_, _, bindings) => assert!(bindings.is_empty(), "fieldless variant pattern should have no bindings"),
        other => panic!("expected EnumVariant pattern, got {:?}", other),
    }
}

/// A payload pattern's binding is usable at its field's declared type.
#[test]
fn checks_payload_pattern_binding_has_field_type() {
    let src = format!(
        "{}fn t(o: IntOption) -> i32:\n    match o:\n        IntOption::Some(v) ->\n            return v + 1\n        IntOption::None ->\n            return 0\n",
        INT_OPTION_ENUM_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "payload binding should be usable as its field's `i32` type");
}

/// `EnumName::Variant(args...)` still infers to that enum's type.
#[test]
fn checks_payload_enum_variant_ctor_type() {
    let src = format!("{}fn t() -> IntOption:\n    IntOption::Some(5)\n", INT_OPTION_ENUM_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let f = typed.items.iter().find_map(|i| if let TypedItem::Fn(f) = i { Some(f) } else { None }).expect("expected a fn item");
    let ty = match f.body.stmts.last().expect("body should have a statement") {
        TypedStmt::Expr(e) => e.clone().into_ty(),
        other => panic!("expected trailing expr statement, got {:?}", other),
    };
    assert_eq!(ty, Ty::Enum("IntOption".into()));
}

/// A payload variant constructor called with the wrong number of arguments
/// is a type error.
#[test]
fn rejects_payload_enum_ctor_wrong_arity() {
    let src = format!("{}fn t():\n    IntOption::Some(1, 2)\n", INT_OPTION_ENUM_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("wrong ctor arity should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("expects 1 argument")), "{:?}", diags);
}

/// A payload match pattern with the wrong number of bindings is a type error.
#[test]
fn rejects_payload_pattern_binding_arity_mismatch() {
    let src = format!(
        "{}fn t(o: IntOption):\n    match o:\n        IntOption::Some(a, b) -> 1\n        IntOption::None -> 0\n",
        INT_OPTION_ENUM_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("wrong binding arity should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("expects 1 binding")), "{:?}", diags);
}

/// A payload-carrying enum lowers to a tagged-union LLVM struct (`{ i32
/// tag, [W x i64] payload }`), unlike a fieldless enum's bare `i32`.
#[test]
fn codegen_payload_enum_emits_tagged_union_struct_type() {
    let src = format!("{}fn t() -> IntOption:\n    IntOption::Some(5)\n", INT_OPTION_ENUM_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("%IntOption = type { i32, [1 x i64] }"), "{}", ir);
}

/// A fieldless enum coexisting with a payload enum in the same module still
/// lowers straight to `i32` (no struct declaration of its own) -- the two
/// representations must not interfere with each other.
#[test]
fn codegen_fieldless_enum_stays_i32_alongside_payload_enum() {
    let src = format!("{}{}fn t() -> Direction:\n    Direction::East\n", DIRECTION_ENUM_SRC, INT_OPTION_ENUM_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(!ir.contains("%Direction = type"), "fieldless enum should not get a struct decl: {}", ir);
    assert!(ir.contains("ret i32 2"), "{}", ir);
}

/// Constructing a payload variant stores the dense discriminant into the
/// tagged union's first field, then bitcasts the shared payload buffer to
/// the variant's own field layout to store each argument.
#[test]
fn codegen_payload_enum_ctor_stores_tag_and_bitcasts_payload() {
    let src = format!("{}fn t() -> IntOption:\n    IntOption::Some(5)\n", INT_OPTION_ENUM_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    // Some is the second declared variant (None=0, Some=1).
    assert!(ir.contains("store i32 1,"), "tag store: {}", ir);
    assert!(ir.contains("bitcast [1 x i64]* "), "payload bitcast: {}", ir);
}

/// Matching a payload variant destructures its fields by bitcasting the
/// scrutinee's shared payload buffer to that variant's own field layout and
/// GEP-ing each bound field out of it.
#[test]
fn codegen_match_payload_variant_binds_field_via_bitcast_gep() {
    let src = format!(
        "{}fn t(o: IntOption) -> i32:\n    match o:\n        IntOption::Some(v) ->\n            return v\n        IntOption::None ->\n            return 0\n",
        INT_OPTION_ENUM_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("bitcast [1 x i64]* "), "{}", ir);
    // Every arm returns, so the match's join block is provably unreachable
    // rather than needing a value merged into it.
    assert!(ir.contains("unreachable"), "exhaustive all-return match should close its join block with `unreachable`: {}", ir);
}

/// Runtime test: `examples/option_result.exe` exercises the builtin
/// `Option<T>`/`Result<T,E>` generic enums end to end -- constructing
/// `Ok`/`Err`/`Some`/`None` variants, destructuring their payload fields
/// through `match`, a multi-field variant (`Rect(width, height)`), and
/// `?`-propagation over both `Result` (short-circuiting `Err`) and `Option`
/// (short-circuiting `None`) -- through a real clang-compiled executable.
#[test]
fn runtime_option_result_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/option_result.exe").output().expect("failed to execute option_result.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("ok: 5"), "Ok(value) payload extraction: {}", stdout);
    assert!(stdout.contains("err: 1"), "Err(code) payload extraction: {}", stdout);
    assert!(stdout.contains("found: 4"), "Some(value) payload extraction: {}", stdout);
    assert!(stdout.contains("found: -1"), "None fallback: {}", stdout);
    assert!(stdout.contains("circle area: 12"), "single-field variant: {}", stdout);
    assert!(stdout.contains("rect area: 12"), "multi-field variant: {}", stdout);
    assert!(stdout.contains("checked_double ok: 10"), "`?` unwraps a `Result::Ok` payload and keeps executing: {}", stdout);
    assert!(stdout.contains("checked_double err: 1"), "`?` short-circuits a `Result::Err` straight out of the function: {}", stdout);
    assert!(stdout.contains("first_even_doubled: 8"), "`?` unwraps an `Option::Some` payload and keeps executing: {}", stdout);
    assert!(stdout.contains("first_even_doubled: none"), "`?` short-circuits an `Option::None` straight out of the function: {}", stdout);
}

// ===== Option/Result builtins and `?`-propagation ==========================

/// `expr?` parses as a postfix `Expr::Try` wrapping the inner expression, at
/// the same precedence tier as `.field`/call/index (binds tighter than any
/// binary operator: `f()? + 1` is `(f()?) + 1`, not `f()?(+1)`).
#[test]
fn parses_try_operator_postfix() {
    let src = "fn t() -> Result<i32, i32>:\n    let v = safe_div(1, 2)?\n    Result<i32, i32>::Ok(v)\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    match value {
        Expr::Try { inner, .. } => assert!(matches!(inner.as_ref(), Expr::Call { .. }), "expected Call inside Try, found {:?}", inner),
        other => panic!("expected Expr::Try, found {:?}", other),
    }
}

/// `Option<T>`/`Result<T,E>` are pre-registered compiler builtins: a user
/// module is free to *use* them (construct/match/`?`) without declaring them
/// itself, and a user module that *does* redeclare `enum Option<T>` hits the
/// same "declared more than once" diagnostic as any other name collision,
/// rather than silently shadowing the builtin.
#[test]
fn rejects_user_redeclaration_of_builtin_option() {
    let src = "enum Option<T>:\n    None\n    Some(value: T)\n\nfn t():\n    Option::Some(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("redeclaring the builtin `Option<T>` should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("declared more than once")), "{:?}", diags);
}

/// `?` requires its operand to be an `Option<T>`/`Result<T,E>` -- using it on
/// an ordinary payload enum is a clear type error, not a confusing downstream
/// codegen failure.
#[test]
fn rejects_try_on_non_option_result_enum() {
    let src = "enum Shape:\n    Circle(radius: i32)\n\nfn t(s: Shape) -> i32:\n    let r = s?\n    r\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("`?` on a non-Option/Result enum should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("requires an `Option<T>` or `Result<T,E>`")), "{:?}", diags);
}

/// `?`'s enum type must exactly match the enclosing function's declared
/// return type -- Star has no `From`/`Into` conversion machinery to reconcile
/// e.g. a `Result<i32,i32>` being propagated out of an `Option<i32>`-returning
/// function.
#[test]
fn rejects_try_return_type_family_mismatch() {
    let src = "fn safe_div(a: i32, b: i32) -> Result<i32, i32>:\n    Result<i32, i32>::Ok(a)\n\nfn t(a: i32, b: i32) -> Option<i32>:\n    let v = safe_div(a, b)?\n    Option::Some(v)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("`?` on a `Result` inside an `Option`-returning function should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("requires the enclosing function to return")), "{:?}", diags);
}

/// `?` desugars entirely to the existing tagged-union `match` codegen (no
/// dedicated codegen path of its own): the emitted IR for a `Result<i32,i32>`
/// `?` looks exactly like a hand-written `match` over `Ok`/`Err` -- a tag
/// load/compare, a branch, and (on the `Err` path) an early `ret`.
#[test]
fn codegen_try_desugars_to_match_over_ok_err() {
    let src = "fn safe_div(a: i32, b: i32) -> Result<i32, i32>:\n    Result<i32, i32>::Ok(a)\n\nfn t(a: i32, b: i32) -> Result<i32, i32>:\n    let v = safe_div(a, b)?\n    Result<i32, i32>::Ok(v)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let body = extract_fn_body(&ir, "@t(");
    assert!(body.contains("icmp"), "`?` should lower to the same tag-compare a hand-written `match` emits: {}", body);
    assert!(body.contains("br "), "`?` should lower to a branch between the unwrap/propagate arms: {}", body);
    assert!(body.contains("ret "), "the `Err` arm should `ret` the propagated variant straight out of the function: {}", body);
}

// ===== struct destructuring in match patterns ==============================

const POINT_STRUCT_SRC: &str = "struct Point:\n    x: i32\n    y: i32\n\n";

/// Parse a struct destructuring match pattern's bindings: `Point(x, y) -> ...`.
#[test]
fn parses_struct_pattern_with_bindings() {
    let src = format!("{}fn t(p: Point) -> i32:\n    match p:\n        Point(a, b) -> a\n", POINT_STRUCT_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Expr(Expr::Match { arms, .. }) = &f.body.stmts[0] else { panic!("expected match") };
    match &arms[0].pattern {
        Pattern::Struct(name, bindings) => {
            assert_eq!(name, "Point");
            assert_eq!(bindings, &vec!["a".to_string(), "b".to_string()]);
        }
        other => panic!("expected Struct pattern, got {:?}", other),
    }
}

/// A struct pattern's binding is usable at its field's declared type.
#[test]
fn checks_struct_pattern_binding_has_field_type() {
    let src = format!(
        "{}fn t(p: Point) -> i32:\n    match p:\n        Point(x, y) ->\n            return x + y\n",
        POINT_STRUCT_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "struct pattern bindings should be usable as their field's `i32` type");
}

/// A struct pattern with the wrong number of bindings is a type error.
#[test]
fn rejects_struct_pattern_binding_arity_mismatch() {
    let src = format!("{}fn t(p: Point):\n    match p:\n        Point(a) -> 1\n", POINT_STRUCT_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("wrong binding arity should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("expects 2 binding")), "{:?}", diags);
}

/// A struct pattern naming a different struct than the scrutinee's type is a
/// type error.
#[test]
fn rejects_match_pattern_struct_mismatch() {
    let src = format!(
        "{}struct Other:\n    z: i32\n\nfn t(p: Point):\n    match p:\n        Other(z) -> 1\n",
        POINT_STRUCT_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "mismatched struct pattern should be a type error");
}

/// A struct pattern naming an undefined struct is a type error.
#[test]
fn rejects_undefined_struct_pattern() {
    let src = format!("{}fn t(p: Point):\n    match p:\n        Ponit(a, b) -> 1\n", POINT_STRUCT_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("undefined struct pattern should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("undefined struct")), "{:?}", diags);
}

/// A struct pattern matched against a scrutinee whose type isn't `Ty::Named`
/// at all (an `i32` here) must still be rejected -- previously
/// `check_match_arm`'s mismatch check only ever fired inside an `if let
/// Ty::Named(..) = scrutinee_ty`, so any non-`Named` scrutinee shape (`i32`,
/// `bool`, `Ty::Enum`, `List<T>`, a vector, ...) skipped the check entirely
/// and this type-checked cleanly, only failing later at the `clang` step
/// (a GEP into a struct type the scrutinee was never laid out as).
#[test]
fn rejects_struct_pattern_against_non_named_scrutinee() {
    let src = format!("{}fn main() -> i32:\n    let n = 5\n    match n:\n        Point(a, b) -> a + b\n        _ -> 0\n    return 0\n", POINT_STRUCT_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("struct pattern against a non-struct scrutinee should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("does not match scrutinee type")), "{:?}", diags);
}

/// Same fix, enum-pattern side: an enum pattern matched against a scrutinee
/// whose type isn't `Ty::Enum` at all must also be rejected rather than
/// silently skipping the mismatch check.
#[test]
fn rejects_enum_pattern_against_non_enum_scrutinee() {
    let src = "enum Color:\n    Red\n    Blue\n\nfn main() -> i32:\n    let n = 5\n    match n:\n        Color::Red -> 1\n        _ -> 0\n    return 0\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("enum pattern against a non-enum scrutinee should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("does not match scrutinee type")), "{:?}", diags);
}

/// A bare reference to an identifier that names no local variable, no
/// declared top-level function, and no builtin must be a type error --
/// previously `Checker::infer_expr`'s `Expr::Ident` arm fell back to the
/// `unknown` placeholder type with zero diagnostics for any unrecognized
/// name, so a typo'd variable/function name type-checked cleanly and only
/// broke at the `clang` step against generated IR referencing `%unknown`.
#[test]
fn rejects_undefined_identifier() {
    let src = "fn main() -> i32:\n    let x = totally_undefined_function(1, 2)\n    return 0\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("undefined identifier should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("undefined name")), "{:?}", diags);
}

/// Same fix as above, exercised through an f-string interpolation hole
/// rather than a direct call -- confirms the check applies uniformly
/// regardless of where the identifier is read from.
#[test]
fn rejects_undefined_identifier_in_fstring_interpolation() {
    let src = "fn main() -> i32:\n    println(f\"{undefined_var}\")\n    return 0\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("undefined identifier in an f-string hole should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("undefined name")), "{:?}", diags);
}

/// `self` used outside of any method with a `self` parameter (a bare
/// top-level `fn`) must be a type error -- previously it silently fell back
/// to the `Self` placeholder type and only failed at the `clang` step
/// ("unknown struct `Self`") once codegen tried to resolve a receiver type
/// that never existed.
#[test]
fn rejects_self_outside_method() {
    let src = "fn main() -> i32:\n    return self.x\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("`self` outside a method should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("`self` is not valid outside of a method")), "{:?}", diags);
}

/// An ordinary, valid call to a declared top-level function is unaffected by
/// the new undefined-identifier check (a regression guard against the fix
/// above being too aggressive).
#[test]
fn accepts_call_to_declared_function() {
    let src = "fn helper(x: i32) -> i32:\n    return x + 1\n\nfn main() -> i32:\n    return helper(5)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("a call to a declared function should type-check");
}

/// A bare, un-negated integer literal whose magnitude is exactly
/// `i32::MAX + 1` (`2147483648`) must be rejected -- previously the lexer
/// unconditionally reinterpreted this exact magnitude as `i32::MIN`'s bit
/// pattern regardless of whether a unary `-` preceded it, so `let x =
/// 2147483648` (with no negation at all) type-checked cleanly and silently
/// produced the value `-2147483648` at runtime with zero diagnostics.
#[test]
fn rejects_bare_i32_max_plus_one_literal() {
    let src = "fn main():\n    let x = 2147483648\n    println(f\"{x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("a bare, un-negated `2147483648` literal should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("too large for a 32-bit integer")), "{:?}", diags);
}

/// Matching a struct pattern destructures its fields by GEP-ing directly
/// into the scrutinee's own storage (no bitcast/tag dance, unlike a payload
/// enum's shared payload buffer, since a struct pattern always matches).
#[test]
fn codegen_match_struct_pattern_binds_field_via_gep() {
    let src = format!(
        "{}fn t(p: Point) -> i32:\n    match p:\n        Point(x, y) ->\n            return x + y\n",
        POINT_STRUCT_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    assert_eq!(
        fn_ir.matches("getelementptr inbounds %Point, %Point* %t0, i32 0, i32").count(),
        2,
        "one GEP per destructured field: {}",
        fn_ir
    );
    // The arm always matches (no tag to test), so it falls straight through
    // to its body with no conditional branch guarding it.
    assert!(!fn_ir.contains("icmp"), "a struct pattern should not emit a tag comparison: {}", fn_ir);
}

/// Runtime test: `examples/struct_destructure.exe` exercises struct
/// destructuring in match patterns end to end -- a flat struct (`Point`) and
/// a struct with struct-typed fields (`Line`, whose `Point` fields are
/// further field-accessed after being bound), through a real
/// clang-compiled executable.
#[test]
fn runtime_struct_destructure_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/struct_destructure.exe").output().expect("failed to execute struct_destructure.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("sum: 7"), "flat struct field destructuring: {}", stdout);
    assert!(stdout.contains("length_sq: 25"), "struct-typed field destructuring + further field access: {}", stdout);
}
