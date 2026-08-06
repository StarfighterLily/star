//! Regression: a `match` used as a bare statement (result never read) where
//! some arms end in a real value (an int literal, or a call returning one)
//! and at least one sibling arm ends in a *void* call (`println(..)`,
//! declared with no return type) -- followed by more code after the match.
//!
//! Found while porting `projects/nova/NoBASIC`'s semantic analyzer to Star:
//! `analyze_statement`'s dispatch match has arms that call
//! `self.analyze_expression(..)` (returns a `DataType`) side by side with
//! arms that are pure side effects, with more statements after the match in
//! the same function body -- the same shape as `Counter::visit` below, minus
//! the flavor text. `star build` failed with "internal compiler error:
//! malformed LLVM IR emitted ... use of undefined value `%undef`". Root
//! cause: `Checker::infer_expr`'s `TypedExpr::Match` case infers the whole
//! match's type from just its value-producing arms (the same `is_unknown`
//! exclusion `Checker::trailing_value_ty` already uses for a trailing
//! `if`/`else`), so a void-typed sibling arm doesn't stop `produces_value`
//! from being `true` -- but `Codegen::emit_expr`'s own `TypedExpr::Match`
//! case had no matching exclusion when collecting each arm's contribution to
//! the shared `phi`: it called `emit_stmts_value` on the void arm's body,
//! got back `Some("%undef")` (`emit_call_expr`'s own bare-sentinel result
//! for a call with no declared return type -- see its doc comment), and fed
//! that string through `reg_of` unchanged instead of recognizing it as "no
//! value". The result: `[ %undef, %block ]` in the emitted `phi` -- a
//! reference to an SSA register literally *named* `undef`, which is never
//! defined anywhere, rather than the LLVM literal `undef` keyword (`[ undef,
//! %block ]`) every other "arm contributes no value" case already emits
//! correctly (e.g. the "no arm matched" fallback block for a non-exhaustive
//! dispatch). Fixed by `Codegen::arm_phi_reg` (`src/codegen/mod.rs`), a
//! shared helper replacing all seven duplicated
//! `val.map(|v| self.reg_of(&v)).unwrap_or_else(|| "undef".to_string())`
//! call sites (one per `Pattern` kind in the match-arm-emission loop): it
//! treats the exact bare string `"%undef"` the same as `None`, since a real
//! value's `emit_expr` result always carries a type tag and a space (e.g.
//! `"i32 %t5"`) and can never collide with the sentinel's distinct
//! no-tag-no-space shape.
//!
//! Shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

/// A `match` statement (result discarded) mixing two int-producing arms
/// (a literal, and a call whose return value is genuinely used elsewhere)
/// with one void-call arm, followed by more code in the same method body
/// that must still run for every variant -- exercises the exact
/// `Pattern::EnumVariant`-with-binding phi-collection site that produced
/// the malformed IR, and checks real output across all four calls, not
/// just that the binary builds.
#[test]
fn match_void_arm_mixed_with_value_arm_phi_end_to_end() {
    let src = "\
enum K:
    A(x: i32)
    B(y: str)
    C

struct Counter:
    mut total: i32 = 0

impl Counter:
    fn add(mut self, n: i32) -> i32:
        self.total += n
        self.total

    fn visit(mut self, k: K):
        match k:
            K::A(x) ->
                self.add(x)
            K::B(y) ->
                println(y)
            K::C ->
                0
        println(f\"tick total={self.total}\")

fn main():
    let mut c = Counter()
    c.visit(K::A(3))
    c.visit(K::B(\"side-effect\"))
    c.visit(K::A(4))
    c.visit(K::C)
    println(f\"final total={c.total}\")
";
    let output = compile_and_run("match_void_arm_phi_visit", src);
    assert!(output.status.success(), "compiled binary should run cleanly: {:?}", output);
    let stdout = String::from_utf8_lossy(&output.stdout).replace("\r\n", "\n");
    assert_eq!(
        stdout,
        "tick total=3\nside-effect\ntick total=3\ntick total=7\ntick total=7\nfinal total=7\n",
        "the void arm must neither crash codegen nor corrupt the running total from the value-producing arms: {stdout:?}"
    );
}

/// Same hazard, but the match's value is actually bound via `let` rather
/// than discarded as a bare statement -- confirms the fix also covers the
/// `Pattern::Struct`/`Wildcard` (no-tag) arm-collection site, and that a
/// value-producing arm's real result still flows out correctly when a
/// sibling arm is void.
#[test]
fn match_void_arm_result_bound_via_let_end_to_end() {
    let src = "\
enum Msg:
    Num(n: i32)
    Log(text: str)

fn handle(m: Msg) -> i32:
    let v = match m:
        Msg::Num(n) ->
            n * 2
        Msg::Log(text) ->
            println(text)
        _ ->
            -1
    if v < 0:
        return 0
    v

fn main():
    println(f\"{handle(Msg::Num(21))}\")
    handle(Msg::Log(\"logged\"))
    println(\"done\")
";
    let output = compile_and_run("match_void_arm_phi_let", src);
    assert!(output.status.success(), "compiled binary should run cleanly: {:?}", output);
    let stdout = String::from_utf8_lossy(&output.stdout).replace("\r\n", "\n");
    assert_eq!(stdout, "42\nlogged\ndone\n", "the Num arm's real value must survive the fix, and the Log call's side effect must still run: {stdout:?}");
}
