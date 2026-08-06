//! Regression: a `match`/`if` used as a *non-trailing* statement, where
//! every arm/branch itself terminates (`return`/`break`/`continue`),
//! followed by further statements in the same block.
//!
//! Found while porting `projects/nova/NoBASIC`'s lexer to Star: `lex()`'s
//! caller pattern -- `match result: Ok(v) -> ... return  Err(e) -> ...
//! return` followed by unrelated trailing code -- previously made `star
//! build` fail with "internal compiler error: malformed LLVM IR emitted
//! ... has a `unreachable` terminator before its last instruction". Root
//! cause: `Codegen::body_terminates` (`src/codegen/stmt.rs`) only ever
//! asked whether the *last* statement of a block terminates it, and every
//! plain statement-sequence emitter (`emit_stmts_value`'s non-trailing
//! loop, `if`/`while`/`for`/`spawn`/`each` body loops) walked every
//! statement unconditionally regardless of whether an earlier one already
//! closed the current block with a terminator/`unreachable`. A `return`/
//! `break`/`continue` can only legally be the last statement in a reachable
//! sequence, so this went unnoticed -- but a mid-sequence `match`/`if`
//! whose *every* arm/branch returns is ordinary, legal source with more
//! code after it (only reachable arms/branches ever ran the code that came
//! next), and its own codegen already closes with `unreachable` in that
//! case. Fixed by teaching `body_terminates` to ask "does *any* statement
//! terminate" (not just the last one) and adding `Codegen::emit_stmt_seq`
//! (stops emitting the moment a statement terminates) as the one shared
//! implementation every raw statement-sequence loop now goes through.
//!
//! Shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

/// A `match` on a `Result` mid-function-body, both arms ending in `return`,
/// followed by unrelated trailing statements and a trailing value -- the
/// exact shape that produced malformed IR before the fix. Both the
/// success and failure paths must actually run (not just compile), so
/// this checks output for each, not merely that the binary builds.
#[test]
fn match_where_every_arm_returns_followed_by_more_code_end_to_end() {
    let src = "\
struct MyErr:
    message: str

fn risky(fail: bool) -> Result<i32, MyErr>:
    if fail:
        return Result<i32, MyErr>::Err(MyErr(message = \"bad\"))
    Result<i32, MyErr>::Ok(5)

fn run(fail: bool) -> i32:
    match risky(fail):
        Result::Ok(v) ->
            println(f\"ok {v}\")
            return 0
        Result::Err(e) ->
            println(f\"err {e.message}\")
            return 1
    println(\"unreachable\")
    99

fn main():
    println(f\"{run(false)}\")
    println(f\"{run(true)}\")
";
    let output = compile_and_run("terminating_match_midseq_result", src);
    assert!(output.status.success(), "compiled binary should run cleanly: {:?}", output);
    let stdout = String::from_utf8_lossy(&output.stdout).replace("\r\n", "\n");
    assert_eq!(stdout, "ok 5\n0\nerr bad\n1\n", "both the Ok and Err arms must actually execute and return, not fall into the dead code after the match: {stdout:?}");
}

/// Same shape, but the terminating `match` is nested inside a `while` loop
/// body rather than directly in the function body -- exercises the
/// `while`-body statement-sequence emitter's own raw loop, not just
/// `emit_stmts_value`'s.
#[test]
fn match_where_every_arm_terminates_inside_while_body_end_to_end() {
    let src = "\
fn classify(n: i32) -> i32:
    match n:
        0 ->
            return 100
        _ ->
            return 200

fn main():
    let mut i = 0
    while i < 3:
        match classify(i):
            100 -> println(\"zero\")
            _ -> println(\"other\")
        println(f\"tick {i}\")
        i += 1
";
    let output = compile_and_run("terminating_match_midseq_while", src);
    assert!(output.status.success(), "compiled binary should run cleanly: {:?}", output);
    let stdout = String::from_utf8_lossy(&output.stdout).replace("\r\n", "\n");
    assert_eq!(stdout, "zero\ntick 0\nother\ntick 1\nother\ntick 2\n", "the while body's own trailing statements after the match must still run every iteration: {stdout:?}");
}

/// An `if`/`else` (not a `match`) mid-function-body where both branches
/// return, followed by more code -- `body_terminates`'s `TypedStmt::If`
/// arm has the identical "only checks the block's last statement"
/// susceptibility if the branch bodies themselves bury their `return`
/// behind an earlier terminating `match`, so this nests one to cover that
/// combination specifically.
#[test]
fn if_else_both_branches_terminate_via_nested_match_followed_by_more_code() {
    let src = "\
fn pick(n: i32) -> i32:
    if n > 0:
        match n:
            1 ->
                return 10
            _ ->
                return 20
    else:
        match n:
            0 ->
                return 30
            _ ->
                return 40
    println(\"unreachable\")
    99

fn main():
    println(f\"{pick(1)}\")
    println(f\"{pick(5)}\")
    println(f\"{pick(0)}\")
    println(f\"{pick(-5)}\")
";
    let output = compile_and_run("terminating_match_midseq_if_else", src);
    assert!(output.status.success(), "compiled binary should run cleanly: {:?}", output);
    let stdout = String::from_utf8_lossy(&output.stdout).replace("\r\n", "\n");
    assert_eq!(stdout, "10\n20\n30\n40\n", "every branch's nested match must resolve to its own return, not fall through: {stdout:?}");
}
