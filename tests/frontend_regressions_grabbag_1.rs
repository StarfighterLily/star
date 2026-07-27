//! Regression grab-bag: GenRef/Handle turbofish, negative-literal patterns, parse recovery, sequence hoisting, spawn double-release, binop operand validation, match RC leak, collection method staleness
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Regression: `GenRef`/`Handle` turbofish must backtrack like every
// ===== other generic-looking name (`List`, `Map`, `Set`, `Table`, `Box`,
// ===== `Option`, `Ring`) instead of hard-committing the instant it sees the
// ===== name followed by `<`. Unlike those, the `Lt` arm of `parse_postfix`
// ===== previously called `parse_type()` on the very next token with no
// ===== checkpoint at all, so a shadowed local literally named `GenRef`/
// ===== `Handle` compared with `<` (e.g. `if GenRef < 5:`) hard-errored
// ===== ("expected an identifier, found an integer literal") instead of
// ===== parsing as an ordinary comparison -- the exact same class of bug
// ===== `parses_shadowed_ring_identifier_as_comparison_not_turbofish` above
// ===== already regression-tests for `Ring`. =================================

/// A local named `GenRef` compared with `<` must parse as an ordinary
/// comparison expression, not misfire into `GenRef<T>(..)` turbofish parsing.
#[test]
fn parses_shadowed_genref_identifier_as_comparison_not_turbofish() {
    let src = "fn main():\n    let GenRef = 5\n    if GenRef < 3:\n        println(\"less\")\n    else:\n        println(\"not less\")\n";
    let module = Driver::parse(src).expect("`GenRef < 3` on a shadowed local should parse as a comparison, not a GenRef<T> turbofish");
    assert!(Driver::check(&module).is_ok(), "shadowed `GenRef` comparison should type-check cleanly");
}

/// Same regression as above, for `Handle` (the other turbofish-constructed
/// name that shares this code path via `is_handle`).
#[test]
fn parses_shadowed_handle_identifier_as_comparison_not_turbofish() {
    let src = "fn main():\n    let Handle = 5\n    if Handle < 3:\n        println(\"less\")\n    else:\n        println(\"not less\")\n";
    let module = Driver::parse(src).expect("`Handle < 3` on a shadowed local should parse as a comparison, not a Handle<T> turbofish");
    assert!(Driver::check(&module).is_ok(), "shadowed `Handle` comparison should type-check cleanly");
}

/// A genuine `GenRef<A, B>(..)` (wrong type-argument count, but immediately
/// followed by `(` so it's unambiguously a real turbofish attempt, not a
/// comparison) must still hard-error with a clear diagnostic rather than
/// silently backtracking into a nonsensical comparison parse -- the
/// speculative backtrack added for the shadowed-identifier case above must
/// only fire when `<...>` *isn't* followed by `(`.
#[test]
fn rejects_genref_turbofish_with_wrong_type_arg_count() {
    let src = "struct Point:\n    x: i32\n\nfn main():\n    let r = GenRef<Point, Point>(Point(1))\n";
    let Err(diags) = Driver::parse(src) else { panic!("GenRef<..> with 2 type arguments should be rejected") };
    assert!(diags.iter().any(|d| d.message.contains("expects exactly one type argument")), "{:?}", diags);
}

// ===== Regression: bare negative-literal match patterns (`-1 -> ...`)
// ===== previously failed to parse at all ("unexpected token in pattern:
// ===== Minus") -- `Parser::parse_pattern` handled `Underscore`, the
// ===== `<`/`<=`/`>`/`>=`/`==` comparison forms, positive `Int`, `True`/
// ===== `False`, and `Ident`, but had no `Minus` arm, even though ordinary
// ===== expressions handle unary `-` fine (so `== -1 -> ...` already worked
// ===== as a workaround). Mirrors `parse_unary_inner`'s `Minus` handling,
// ===== including its `i32::MIN` special case (see `Expr::Unary`'s identical
// ===== one in `types/expr.rs`). =============================================

/// `-1 -> ...` must parse as a negative-int-literal pattern, matching
/// exactly the scrutinee value `-1` (not requiring the `== -1` workaround).
#[test]
fn parses_negative_int_literal_match_pattern() {
    let src = "fn main():\n    let n: i32 = -1\n    match n:\n        -1 -> println(\"neg one\")\n        _ -> println(\"other\")\n";
    let module = Driver::parse(src).expect("`-1 -> ...` should parse as a negative-literal pattern");
    Driver::check(&module).expect("negative-literal match pattern should type-check");
}

/// A negative-literal pattern actually dispatches to the matching arm at
/// runtime (not just parses) -- distinct positive, negative, and default
/// arms must each fire for their own scrutinee value.
#[test]
fn runtime_negative_int_literal_match_pattern_end_to_end() {
    let src = "fn classify(n: i32) -> str:\n    match n:\n        -2 -> \"neg two\"\n        -1 -> \"neg one\"\n        0 -> \"zero\"\n        1 -> \"one\"\n        _ -> \"other\"\n\nfn main():\n    println(classify(-2))\n    println(classify(-1))\n    println(classify(0))\n    println(classify(1))\n    println(classify(99))\n";
    let output = compile_and_run("negative_int_literal_match_pattern", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["neg two", "neg one", "zero", "one", "other"], "{}", stdout);
}

/// `i32::MIN` (`-2147483648`) as a match pattern is the same "bare digit
/// magnitude `2147483648` is pre-negated by the lexer regardless of context"
/// edge case `checks_i32_min_literal_still_typechecks` (around line 6085)
/// exercises for ordinary expressions -- a pattern must not re-negate an
/// already-`i32::MIN`-valued token (which would overflow back out of `i32`
/// range) and must still match the actual `i32::MIN` scrutinee value.
#[test]
fn runtime_i32_min_negative_literal_match_pattern_end_to_end() {
    let src = "fn classify(n: i32) -> str:\n    match n:\n        -2147483648 -> \"min\"\n        _ -> \"other\"\n\nfn main():\n    println(classify(-2147483648))\n    println(classify(0))\n";
    let output = compile_and_run("i32_min_negative_literal_match_pattern", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["min", "other"], "{}", stdout);
}

// ===== Regression: a parse error inside a nested block (e.g. an `if`
// ===== missing its `:`) must not cascade into unrelated diagnostics for
// ===== every statement that follows. `Parser::recover_to_newline` skips to
// ===== the next `Newline`/`Dedent`/`Eof` and stops -- but a failed
// ===== compound statement (like `if x` with no `:`) can leave behind an
// ===== orphaned, never-claimed `Indent`/`Dedent` pair for the body the
// ===== lexer still tokenized. Previously recovery stopped at that
// ===== orphaned body's own closing `Dedent`, which the enclosing block's
// ===== loop couldn't tell apart from its own terminator -- so the
// ===== enclosing block (e.g. a whole `fn` body) ended early, stranding
// ===== every following sibling statement as cascading "unexpected token"/
// ===== "expected a top-level item" errors instead of one clean diagnostic
// ===== for the actual mistake. ===============================================

/// A single missing `:` on a nested `if` produces exactly one diagnostic --
/// the sibling statement after the malformed `if`'s (never-opened) body, and
/// an unrelated top-level `fn` after that, must both still parse cleanly.
#[test]
fn parse_error_in_nested_block_does_not_cascade_to_sibling_statements() {
    let src = "fn f():\n    if x\n        y = 1\n    z = 2\n\nfn g() -> i32:\n    return 42\n";
    let Err(diags) = Driver::parse(src) else { panic!("`if x` missing `:` should still be a parse error") };
    assert_eq!(diags.len(), 1, "a single malformed `if` header must not cascade into further diagnostics: {:?}", diags);
    assert!(diags[0].message.contains("expected ':'"), "{:?}", diags);
}

/// Same shape, but the nested malformed block is itself several statements
/// deep -- recovery must skip the *entire* orphaned body (nesting-aware),
/// not just past its first line, before resuming at the next real sibling.
#[test]
fn parse_error_in_deeply_nested_block_does_not_cascade_to_sibling_statements() {
    let src = "fn f():\n    if x\n        y = 1\n        if y\n            z = 2\n        w = 3\n    v = 4\n\nfn g() -> i32:\n    return 42\n";
    let Err(diags) = Driver::parse(src) else { panic!("`if x` missing `:` should still be a parse error") };
    assert_eq!(diags.len(), 1, "recovery must swallow the whole orphaned nested body, not cascade: {:?}", diags);
    assert!(diags[0].message.contains("expected ':'"), "{:?}", diags);
}

// ===== Regression: a `sequence` body that re-declares (shadows) a name
// ===== already claimed by a parameter or an earlier top-level `let` was
// ===== previously accepted by `sequence::desugar_sequence` with no check at
// ===== all -- both `let`s (or the param and the `let`) became separate
// ===== `FieldDef`s on the desugared struct sharing the same field name.
// ===== When the two agreed on type this "worked" only by accident (every
// ===== `self.<name> = ..`/`<name>` read resolves to whichever field a
// ===== linear name lookup finds first); when they disagreed it surfaced as
// ===== a baffling "cannot assign a value of type X to a target of type Y"
// ===== pointing at the second `let` as if it were an ordinary assignment.
// ===== Ordinary `fn` bodies allow re-`let`-ing a name with a new type
// ===== (plain shadowing, a fresh stack slot each time) -- reject the
// ===== `sequence` case outright with a clear diagnostic instead of
// ===== pretending it's supported. ============================================

/// Re-declaring a hoisted local's name with a second top-level `let` inside
/// a `sequence` body is rejected with a clear diagnostic, not a confusing
/// downstream type-mismatch error.
#[test]
fn rejects_duplicate_hoisted_local_in_sequence_body() {
    let src = "sequence S():\n    let mut x: i32 = 1\n    yield\n    let mut x: i32 = 2\n    yield\n\nfn main():\n    let mut s = S()\n";
    let module = Driver::parse(src).expect("should parse");
    let err = Driver::check(&module).expect_err("re-declaring `x` in a sequence body should be rejected");
    assert!(
        err.iter().any(|d| d.message.contains("already a parameter or an earlier hoisted local")),
        "{:?}",
        err
    );
}

/// A top-level `let` shadowing a `sequence` parameter's name is the same
/// underlying collision (one generated struct field, no renaming) and must
/// be rejected the same way.
#[test]
fn rejects_let_shadowing_sequence_param_name() {
    let src = "sequence S(x: i32):\n    print(f\"{x}\")\n    yield\n    let mut x: str = \"hi\"\n    print(x)\n    yield\n\nfn main():\n    let mut s = S(1)\n";
    let module = Driver::parse(src).expect("should parse");
    let err = Driver::check(&module).expect_err("a `let` shadowing a sequence param's name should be rejected");
    assert!(
        err.iter().any(|d| d.message.contains("already a parameter or an earlier hoisted local")),
        "{:?}",
        err
    );
}

// ===== Regression: every top-level `let` in a `sequence` body is hoisted
// ===== into a struct field up front (`hoist`, built by scanning the whole
// ===== body before any segment is rewritten), so a `let`'s own initializer
// ===== referencing a *later* top-level `let`'s name was already rewritten to
// ===== `self.<name>` regardless of program order -- silently reading that
// ===== field's zero-initialized value instead of getting a "used before
// ===== declaration" error the same reference would get in an ordinary `fn`
// ===== body. =================================================================

/// A hoisted local's own initializer referencing another hoisted local
/// declared *later* in the same sequence body must be a compile error, not a
/// silent read of that later local's zero-initialized value.
#[test]
fn rejects_sequence_forward_reference_to_later_hoisted_local() {
    let src = "sequence Counter():\n    let a: i32 = b + 1\n    yield\n    let mut b: i32 = 5\n    yield\n\nfn main():\n    let mut c = Counter()\n";
    let module = Driver::parse(src).expect("should parse");
    let err = Driver::check(&module).expect_err("referencing a later top-level local before its own `let` should be rejected");
    assert!(err.iter().any(|d| d.message.contains("used here before its own `let`")), "{:?}", err);
}

/// A forward reference nested one level inside an `if` (not directly in
/// another `let`'s initializer) is the same hazard and must also be caught --
/// the check walks the whole body, not just top-level `let` initializers.
#[test]
fn rejects_sequence_forward_reference_nested_inside_if() {
    let src = "sequence S(cond: bool):\n    if cond:\n        println(b)\n    yield\n    let mut b: i32 = 5\n    yield\n\nfn main():\n    let mut s = S(true)\n";
    let module = Driver::parse(src).expect("should parse");
    let err = Driver::check(&module).expect_err("a forward reference nested inside an `if` should be rejected");
    assert!(err.iter().any(|d| d.message.contains("used here before its own `let`")), "{:?}", err);
}

/// Sanity/no-false-positive guard: a `for` loop's own induction variable
/// legitimately shadows a same-named hoisted local declared later in the
/// body -- this must *not* be flagged as a forward reference, mirroring
/// `runtime_sequence_for_loop_var_shadowing_hoisted_field_end_to_end`'s
/// runtime coverage of the same shadowing rule.
#[test]
fn accepts_sequence_for_loop_var_shadowing_later_hoisted_local_no_false_positive() {
    let src = "sequence S():\n    let mut total: i32 = 0\n    for b in 0..3:\n        total = total + b\n    yield\n    let mut b: i32 = 99\n    print(f\"{b}\")\n    yield\n\nfn main():\n    let mut s = S()\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "a for-loop var shadowing a later hoisted local should not be flagged as a forward reference: {:?}", Driver::check(&module).err());
}

// ===== Regression: `emit_spawn_stmt`'s free-list slot-reuse path double-
// ===== released an RC-bearing element's content. `emit_despawn_stmt`
// ===== already releases a slot's content when it's freed (the only way a
// ===== slot ever reaches the free-list); `emit_spawn_stmt`'s reuse path
// ===== then released the *same* slot's content *again* before overwriting
// ===== it, since despawn never zeroes the slot's raw bytes -- a genuine
// ===== double-release (heap-UB, potential double-free/use-after-free) on
// ===== every despawn-then-respawn cycle of an arena element type
// ===== containing `str`/`List`/`Map`/`Set`/`Table`/a closure. Confirmed by
// ===== direct LLVM IR inspection before the fix: the exact same slot
// ===== field pointer reached `call void @star_rc_release` twice with no
// ===== intervening allocation. ===============================================

/// A despawn-then-respawn cycle on an arena slot whose element type carries
/// an RC-bearing field (`str`) must not double-release that field's content
/// -- exercised across several cycles (not just one) so a reintroduced
/// double-free is more likely to actually corrupt the heap and crash rather
/// than silently succeed by luck.
#[test]
fn runtime_arena_despawn_respawn_cycle_does_not_double_release_rc_field_end_to_end() {
    let src = "struct Entity:\n    name: str\n\narena Entities: Entity\n\nfn main():\n    let mut i = 0\n    while i < 200:\n        spawn Entities(concat(\"a\", \"b\"))\n        despawn Entities[0]\n        i += 1\n    spawn Entities(concat(\"final\", \"value\"))\n    let r = GenRef<Entity>(0)\n    println(f\"{r[0].name}\")\n";
    let output = compile_and_run("arena_despawn_respawn_no_double_release", src);
    assert!(output.status.success(), "heap corruption / abnormal exit from a double-release: {:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "finalvalue", "{}", stdout);
}

// ===== Regression: `compute_unsafe_par_fns` (the `par`/`swarm` transitive
// ===== `spawn`/`despawn`/`frame:` hazard scan) keyed its `bodies` map by
// ===== bare method name with a plain `HashMap::insert`, so two unrelated
// ===== structs declaring a same-named method silently overwrote each
// ===== other's entry -- if the *later*-declared struct's method happened
// ===== to be hazard-free, the *earlier* struct's real hazard was discarded
// ===== entirely, and a `par`/`swarm` body calling that method through a
// ===== value statically typed as the earlier struct wrongly type-checked.
// ===== A genuine soundness hole in the race-freedom guarantee `par`/`swarm`
// ===== is supposed to provide. =================================================

/// Two structs declaring a same-named method, where only the first one
/// opens a `frame:` block, must still have that hazard caught when a
/// `par`/`swarm` body calls the method through a value typed as the first
/// struct -- even though the second (hazard-free) struct's method of the
/// same name is declared later and would otherwise clobber the first's
/// entry in the hazard-scan's name-keyed map.
#[test]
fn rejects_par_call_to_hazardous_method_masked_by_same_named_safe_method_on_another_struct() {
    let src = "struct A:\n    mut x: i32\n\nimpl A:\n    fn tick(mut self):\n        frame:\n            let p: i32 = 1\n        self.x = self.x + 1\n\nstruct B:\n    mut y: i32\n\nimpl B:\n    fn tick(mut self):\n        self.y = self.y + 1\n\narena Entities: A\n\nfn t():\n    par e in Entities:\n        e.tick()\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("a real frame: hazard must not be masked by an unrelated same-named safe method declared later");
    assert!(errs.iter().any(|d| d.message.contains("tick")), "{:?}", errs);
}

// ===== Regression: `infer_binop_ty`'s arithmetic branch (`+ - * / %`)
// ===== never validated that its operands were actually numeric -- unlike
// ===== the sibling `is_cmp` branch, which was already hardened against
// ===== exactly this class of bug. `"a" + "b"`, two structs added together,
// ===== etc. type-checked cleanly (silently inferring `Int`), only to fail
// ===== with an unlocated "unsupported operand types for binary operator"
// ===== internal error once `Codegen::emit_binop` actually saw the real
// ===== (non-numeric) LLVM types. The identical gap existed in compound
// ===== assignment (`x += y`), which only checked type *compatibility*, not
// ===== operator legality. ====================================================

/// `"a" + "b"` (and other non-numeric operand pairs) must be rejected by
/// the checker with a clean, located diagnostic, not silently accepted and
/// left to fail as an internal codegen error.
#[test]
fn rejects_arithmetic_on_non_numeric_operands() {
    let src = "fn main():\n    let c = \"a\" + \"b\"\n    println(f\"{c}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("`\"a\" + \"b\"` should be a type error, not silently inferred as Int");
    assert!(errs.iter().any(|d| d.message.contains("`+` is not supported between")), "{:?}", errs);
}

/// Two struct values added together is the same non-numeric-operand gap as
/// `str + str`, just via a different offending type.
#[test]
fn rejects_arithmetic_between_two_struct_values() {
    let src = "struct Point:\n    x: i32\n\nfn main():\n    let a = Point(1)\n    let b = Point(2)\n    let c = a + b\n    println(f\"{c.x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("adding two structs should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("is not supported between")), "{:?}", errs);
}

/// The same operand-legality gap in compound assignment: `s += "b"` has
/// *compatible* types (`Str`, `Str`) by `types_compatible`'s own rules, but
/// `+=` still isn't a legal operator for `str` -- must be rejected exactly
/// like plain `"a" + "b"`, not silently accepted because the types happen
/// to match.
#[test]
fn rejects_compound_assign_add_on_str() {
    let src = "fn main():\n    let mut s: str = \"a\"\n    s += \"b\"\n    println(s)\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("`s += \"b\"` on a `str` should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("`+` is not supported between")), "{:?}", errs);
}

// ===== Regression: a `match` arm's `Pattern::Binding`/`Pattern::Wildcard`
// ===== over an RC-bearing scalar scrutinee (e.g. `str` -- the only pattern
// ===== kinds that ever type-check against one) leaked the scrutinee's own
// ===== retained reference. `scrut_val` is retained exactly once (evaluating
// ===== the scrutinee via `emit_expr`), and nothing released it: the
// ===== `Binding` arm span a fresh copy into a new local but never called
// ===== `track_owned` on it (unlike `Stmt::Let`'s identical shape, which
// ===== always does), and `Wildcard` discarded the value outright with no
// ===== release at all. Confirmed by manual refcount arithmetic over the
// ===== emitted IR before the fix: final refcount settled at 1 instead of 0
// ===== (a permanent leak of one reference per `match`). ======================

/// A `match` over a fresh `str` scrutinee, matched via a catch-all binding
/// pattern, must not leak the scrutinee's reference -- run many times in a
/// loop so a reintroduced single-reference leak would be a repeated,
/// compounding leak rather than a one-off.
#[test]
fn runtime_match_binding_over_str_scrutinee_does_not_leak_end_to_end() {
    let src = "fn main():\n    let mut i = 0\n    while i < 500:\n        let s: str = concat(\"a\", \"b\")\n        match s:\n            v -> println(v)\n        i += 1\n    println(\"done\")\n";
    let output = compile_and_run("match_binding_str_no_leak", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.trim_end().ends_with("done"), "{}", stdout);
    assert_eq!(stdout.matches("ab").count(), 500, "{}", stdout);
}

/// Same leak, `Pattern::Wildcard` instead of a catch-all binding -- the
/// scrutinee is discarded entirely rather than bound to a name, which was
/// the one path with *no* release at all (not even an incomplete one).
#[test]
fn runtime_match_wildcard_over_str_scrutinee_does_not_leak_end_to_end() {
    let src = "fn main():\n    let mut i = 0\n    while i < 500:\n        let s: str = concat(\"a\", \"b\")\n        match s:\n            _ -> println(\"matched\")\n        i += 1\n    println(\"done\")\n";
    let output = compile_and_run("match_wildcard_str_no_leak", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.trim_end().ends_with("done"), "{}", stdout);
    assert_eq!(stdout.matches("matched").count(), 500, "{}", stdout);
}

// ===== Regression: a bare (un-negated) `2147483648` pattern (`Pattern::Int`,
// ===== no `Minus` prefix) silently matched as `i32::MIN` with zero
// ===== diagnostic. `Expr::Int` catches an un-negated `2147483648` reaching
// ===== it (`types/expr.rs`'s `Expr::Int` arm) because `Expr::Unary{Neg,
// ===== Expr::Int}`'s AST shape still distinguishes "was there a directly-
// ===== enclosing `-`" -- but `Pattern::Int(i64)` has no such wrapper (this
// ===== parser folds the negation in immediately, see the `Minus`-prefixed
// ===== pattern arm above), so the same un-negated-literal check has to live
// ===== in the parser instead, at the bare `Int` pattern arm itself. =========

/// A bare `2147483648` match pattern (the `i32::MIN` magnitude with no
/// preceding `-`) must be rejected with the same diagnostic `let x =
/// 2147483648` already gets, not silently matched as `i32::MIN`.
#[test]
fn rejects_bare_i32_min_magnitude_match_pattern() {
    // The lexer no longer pre-negates this magnitude (or caps any literal
    // at `i32`'s range) -- see `Lexer::scan_number`'s doc comment -- so a
    // bare `2147483648` pattern now parses cleanly as `Pattern::Int(2147483648)`
    // and is instead rejected once its scrutinee's width (`i32` here) is
    // known, by `Checker::check_match_arm`'s `Pattern::Int` arm.
    let src = "fn main():\n    let x: i32 = -2147483648\n    match x:\n        2147483648 -> println(\"matched\")\n        _ -> println(\"other\")\n";
    let module = Driver::parse(src).expect("a bare `2147483648` pattern should parse fine on its own");
    let Err(diags) = Driver::check(&module) else { panic!("a `2147483648` pattern against an `i32` scrutinee should be a checker error") };
    assert!(diags.iter().any(|d| d.message.contains("does not fit")), "{:?}", diags);
}

// ===== Regression: `ListMethod::Push`/`MapMethod::Insert`/`SetMethod::Insert`/
// ===== `TableMethod::Push` each captured their collection's `len` (and, for
// ===== `Table<T>`, its per-column data pointers) *before* evaluating the
// ===== pushed/inserted argument expression(s) -- `cap`/`data` were already
// ===== (correctly) reloaded fresh *after* evaluating the arguments, but
// ===== `len` wasn't. When an argument expression mutates the same
// ===== collection as a side effect (e.g. `xs.push(xs.pop())`), the mutation
// ===== changes the real length in memory but the stale captured `len`
// ===== register doesn't see it, so the grow-check/copy-count/write-index
// ===== math that follows all operate on outdated bookkeeping -- observed as
// ===== `xs.push(xs.pop())` on `[1, 2, 3]` growing to length 4 with a
// ===== duplicated element instead of correctly ending at length 3. =========

/// `xs.push(xs.pop())` must round-trip to the exact same list, not grow by
/// one extra (stale-length) slot.
#[test]
fn runtime_list_push_of_own_pop_does_not_desync_length_end_to_end() {
    let src = "fn main():\n    let mut xs: List<i32> = List<i32>()\n    xs.push(1)\n    xs.push(2)\n    xs.push(3)\n    xs.push(xs.pop())\n    println(f\"len={xs.len()}\")\n    println(f\"{xs[0]} {xs[1]} {xs[2]}\")\n";
    let output = compile_and_run("list_push_of_own_pop", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["len=3", "1 2 3"], "{}", stdout);
}

/// Same stale-`len` class of bug in `Table<T>::push`, which has its own
/// extra per-column pointer indirection (`cols`) that also needed a fresh
/// post-argument-evaluation reload, not just `len`.
#[test]
fn runtime_table_push_of_own_pop_does_not_desync_length_end_to_end() {
    let src = "struct Enemy:\n    hp: i32\n\nfn main():\n    let mut t: Table<Enemy> = Table<Enemy>()\n    t.push(Enemy(10))\n    t.push(Enemy(20))\n    t.push(Enemy(30))\n    t.push(t.pop())\n    println(f\"len={t.len()}\")\n    println(f\"{t[0].hp} {t[1].hp} {t[2].hp}\")\n";
    let output = compile_and_run("table_push_of_own_pop", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["len=3", "10 20 30"], "{}", stdout);
}

/// Same stale-`len` bug in `Map<K,V>::insert`: inserting a value derived
/// from a nested `remove` call on the very same map (mutating it mid-
/// argument-evaluation) must not desync the map's bookkeeping.
#[test]
fn runtime_map_insert_of_own_remove_does_not_desync_length_end_to_end() {
    let src = "fn extract(o: Option<i32>) -> i32:\n    match o:\n        Option::Some(v) -> v\n        Option::None -> 0\n\nfn main():\n    let mut m: Map<i32, i32> = Map<i32, i32>()\n    m.insert(1, 10)\n    m.insert(2, 20)\n    m.insert(3, 30)\n    m.insert(4, extract(m.remove(2)))\n    println(f\"len={m.len()}\")\n    println(f\"{m.contains(1)} {m.contains(2)} {m.contains(3)} {m.contains(4)}\")\n";
    let output = compile_and_run("map_insert_of_own_remove", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["len=3", "true false true true"], "{}", stdout);
}

/// Same stale-`len` bug in `Set<T>::insert`: inserting a value derived from
/// a nested `remove` call on the very same set must not desync its
/// bookkeeping.
#[test]
fn runtime_set_insert_of_own_remove_does_not_desync_length_end_to_end() {
    let src = "fn pick(removed: bool) -> i32:\n    return if removed:\n        100\n    else:\n        200\n\nfn main():\n    let mut s: Set<i32> = Set<i32>()\n    s.insert(1)\n    s.insert(2)\n    s.insert(3)\n    s.insert(pick(s.remove(2)))\n    println(f\"len={s.len()}\")\n    println(f\"{s.contains(1)} {s.contains(2)} {s.contains(3)} {s.contains(100)}\")\n";
    let output = compile_and_run("set_insert_of_own_remove", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["len=3", "true false true true"], "{}", stdout);
}

// ===== Regression: `MapMethod::Contains`/`Get`/`Remove` and `SetMethod::
// ===== Contains`/`Remove` read their keys/values/length *before* evaluating
// ===== the key argument expression, unlike `Insert` (fixed earlier, see the
// ===== tests just above) -- so a key expression that itself mutates the same
// ===== map/set (e.g. a nested `.remove(..)`) desyncs membership/lookup
// ===== against the *pre*-mutation snapshot. `remove`'s swap-remove leaves
// ===== the vacated (now out-of-range) slot's bytes untouched, so a stale
// ===== length lets a phantom slot's leftover data resurface. ===============

/// `map.contains(..)` evaluated with a key expression that removes the very
/// key being queried must report `false` (the key is really gone), not
/// `true` from re-scanning the phantom vacated slot with a stale `len`.
#[test]
fn runtime_map_contains_of_own_remove_does_not_desync_end_to_end() {
    let src = "fn extract(o: Option<i32>) -> i32:\n    match o:\n        Option::Some(v) -> v\n        Option::None -> 0\n\nfn main():\n    let mut m: Map<i32, i32> = Map<i32, i32>()\n    m.insert(1, 100)\n    m.insert(2, 200)\n    m.insert(3, 3)\n    let r = m.contains(extract(m.remove(3)))\n    println(f\"{r}\")\n    println(f\"len={m.len()}\")\n";
    let output = compile_and_run("map_contains_of_own_remove", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "len=2"], "{}", stdout);
}

/// Same hazard in `map.get(..)`: querying the just-removed key must yield
/// `None`, not `Some(..)` read out of the stale phantom slot.
#[test]
fn runtime_map_get_of_own_remove_does_not_return_removed_value_end_to_end() {
    let src = "fn extract(o: Option<i32>) -> i32:\n    match o:\n        Option::Some(v) -> v\n        Option::None -> 0\n\nfn main():\n    let mut m: Map<i32, i32> = Map<i32, i32>()\n    m.insert(1, 100)\n    m.insert(2, 200)\n    m.insert(3, 3)\n    let got = m.get(extract(m.remove(3)))\n    match got:\n        Option::Some(v) -> println(f\"got {v}\")\n        Option::None -> println(\"got none\")\n    println(f\"len={m.len()}\")\n";
    let output = compile_and_run("map_get_of_own_remove", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["got none", "len=2"], "{}", stdout);
}

/// Same hazard in `set.contains(..)`.
#[test]
fn runtime_set_contains_of_own_remove_does_not_desync_end_to_end() {
    let src = "fn pick(removed: bool) -> i32:\n    return if removed:\n        3\n    else:\n        -1\n\nfn main():\n    let mut s: Set<i32> = Set<i32>()\n    s.insert(1)\n    s.insert(2)\n    s.insert(3)\n    let r = s.contains(pick(s.remove(3)))\n    println(f\"{r}\")\n    println(f\"len={s.len()}\")\n";
    let output = compile_and_run("set_contains_of_own_remove", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "len=2"], "{}", stdout);
}

/// `Ring<T,N>::push` had the same stale-snapshot bug as `List`/`Map`/`Set`'s
/// `push`/`insert` before those were fixed: `head`/`len` were read *before*
/// evaluating the pushed value, so `ring.push(ring.pop())` (a full ring: pop
/// the oldest, then push it back) used the pre-`pop` `head`/`len`, corrupting
/// the length and reintroducing a value into a slot the nested `pop` had
/// already zeroed (violating this module's "every non-live slot is zero"
/// invariant that its blanket RC release-walk relies on).
#[test]
fn runtime_ring_push_of_own_pop_does_not_desync_length_end_to_end() {
    let src = "fn main():\n    let mut r: Ring<i32, 3> = Ring<i32, 3>()\n    r.push(1)\n    r.push(2)\n    r.push(3)\n    r.push(r.pop())\n    println(f\"len={r.len()}\")\n    println(f\"{r[0]} {r[1]} {r[2]}\")\n";
    let output = compile_and_run("ring_push_of_own_pop", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["len=3", "2 3 1"], "{}", stdout);
}

/// `Table<T>` index read/write resolved columns/`len` before evaluating the
/// index expression, same class of bug: `t[t.pop().hp - 28]` shrinks the
/// table via the nested `pop` *while the index is being computed*, so the
/// resulting index (`2`) is out of bounds against the *post*-pop length (`2`)
/// and must read the zero value, not the stale (already-popped) row's
/// leftover data.
#[test]
fn runtime_table_index_read_of_own_pop_does_not_resurface_popped_element_end_to_end() {
    let src = "struct Enemy:\n    hp: i32\n\nfn main():\n    let mut t: Table<Enemy> = Table<Enemy>()\n    t.push(Enemy(10))\n    t.push(Enemy(20))\n    t.push(Enemy(30))\n    let e = t[t.pop().hp - 28]\n    println(f\"{e.hp}\")\n    println(f\"len={t.len()}\")\n";
    let output = compile_and_run("table_index_read_of_own_pop", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["0", "len=2"], "{}", stdout);
}

/// Same hazard in `Ring<T,N>` index reads: `r[r.pop()]`'s index expression
/// itself mutates `r`'s `head`/`len` via the nested `pop`, so the bounds
/// check and physical-slot mapping for the outer index must use the
/// *post*-pop `head`/`len`, not a snapshot taken before the index was
/// evaluated.
#[test]
fn runtime_ring_index_read_of_own_pop_does_not_use_stale_head_end_to_end() {
    let src = "fn main():\n    let mut r: Ring<i32, 3> = Ring<i32, 3>()\n    r.push(1)\n    r.push(2)\n    r.push(3)\n    let v = r[r.pop()]\n    println(f\"{v}\")\n    println(f\"len={r.len()}\")\n";
    let output = compile_and_run("ring_index_read_of_own_pop", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["3", "len=2"], "{}", stdout);
}
