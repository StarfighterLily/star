//! String ops builtins
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// =====================================================================
// ===== `todo.md` #6 "String ops": `str_contains`/`str_starts_with`/
// ===== `str_ends_with`/`str_index_of`/`str_trim`/`str_replace`/`str_split`/
// ===== `str_join` -- split/join/trim/replace/contains beyond what `len`/
// ===== `concat` already covered. Every argument is normalized through
// ===== `Codegen::emit_str_or_empty` before reaching `strlen`/`strstr`/
// ===== `strncmp`/`strcmp` (all undefined behavior on a genuine null `str`),
// ===== so a dedicated end-to-end test below drives every one of these
// ===== eight builtins against a real, reachable null `str` (a despawned
// ===== arena slot's zero-valued field, the same pattern
// ===== `runtime_handle_and_genref_despawn_respawn_cycle_...` above already
// ===== establishes) rather than only ever exercising the ordinary non-null
// ===== path. See `examples/strings.star`.
// =====================================================================

/// `str_contains(s, needle) -> bool`: a real match, no match at all, and the
/// "empty needle always matches" convention `strstr` itself already
/// guarantees.
#[test]
fn runtime_str_contains_end_to_end() {
    let src = "fn main():\n    \
                   let a: bool = str_contains(\"hello world\", \"wor\")\n    \
                   let b: bool = str_contains(\"hello world\", \"xyz\")\n    \
                   let c: bool = str_contains(\"hello\", \"\")\n    \
                   let d: bool = str_contains(\"\", \"x\")\n    \
                   println(f\"{a},{b},{c},{d}\")\n";
    let output = compile_and_run("str_contains", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "true,false,true,false");
}

/// `str_starts_with(s, prefix) -> bool`: a real prefix, a substring that
/// isn't a *prefix*, a `prefix` longer than `s` itself (must not read past
/// `s`'s own NUL, `strncmp` handles this by stopping at the first mismatch),
/// and an empty `prefix` (always matches).
#[test]
fn runtime_str_starts_with_end_to_end() {
    let src = "fn main():\n    \
                   let a: bool = str_starts_with(\"hello\", \"he\")\n    \
                   let b: bool = str_starts_with(\"hello\", \"lo\")\n    \
                   let c: bool = str_starts_with(\"hi\", \"hello\")\n    \
                   let d: bool = str_starts_with(\"hello\", \"\")\n    \
                   let e: bool = str_starts_with(\"hello\", \"hello\")\n    \
                   println(f\"{a},{b},{c},{d},{e}\")\n";
    let output = compile_and_run("str_starts_with", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "true,false,false,true,true");
}

/// `str_ends_with(s, suffix) -> bool`: mirrors `str_starts_with`'s coverage
/// but at the tail, including the `suffix` longer than `s` case (guarded up
/// front so the tail-offset computation never goes negative -- see
/// `Codegen::emit_str_ends_with`'s doc comment).
#[test]
fn runtime_str_ends_with_end_to_end() {
    let src = "fn main():\n    \
                   let a: bool = str_ends_with(\"hello\", \"lo\")\n    \
                   let b: bool = str_ends_with(\"hello\", \"he\")\n    \
                   let c: bool = str_ends_with(\"hi\", \"hello\")\n    \
                   let d: bool = str_ends_with(\"hello\", \"\")\n    \
                   let e: bool = str_ends_with(\"hello\", \"hello\")\n    \
                   println(f\"{a},{b},{c},{d},{e}\")\n";
    let output = compile_and_run("str_ends_with", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "true,false,false,true,true");
}

/// `str_index_of(s, needle) -> int`: a match part-way through `s`, no match
/// at all (`-1`), a match at offset `0`, and the empty-needle convention
/// (always matches at `0`).
#[test]
fn runtime_str_index_of_end_to_end() {
    let src = "fn main():\n    \
                   let a: i32 = str_index_of(\"hello world\", \"wor\")\n    \
                   let b: i32 = str_index_of(\"hello world\", \"xyz\")\n    \
                   let c: i32 = str_index_of(\"hello\", \"hello\")\n    \
                   let d: i32 = str_index_of(\"hello\", \"\")\n    \
                   println(f\"{a},{b},{c},{d}\")\n";
    let output = compile_and_run("str_index_of", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "6,-1,0,0");
}

/// `str_trim(s) -> str`: leading/trailing spaces, a mix of tab/newline/CR
/// whitespace, a string with no whitespace to trim, and an all-whitespace
/// string (must yield an empty `str`, not crash on an empty result).
#[test]
fn runtime_str_trim_end_to_end() {
    let src = "fn main():\n    \
                   println(str_trim(\"   padded text   \"))\n    \
                   println(str_trim(\"\\t\\n mixed \\r\\n\"))\n    \
                   println(str_trim(\"nopad\"))\n    \
                   let empty: str = str_trim(\"    \")\n    \
                   let elen: i32 = len(empty)\n    \
                   println(f\"[{empty}]{elen}\")\n";
    let output = compile_and_run("str_trim", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["padded text", "mixed", "nopad", "[]0"], "{}", stdout);
}

/// `str_replace(s, old, new) -> str`: multiple non-overlapping occurrences,
/// no match at all (unmodified copy, not the same pointer necessarily but
/// the same content), a replacement wider than the pattern (buffer grows) and
/// narrower (buffer shrinks), and adjacent/overlapping-looking matches
/// (`"aaaa"`/`"aa"` must consume non-overlapping pairs left to right, not
/// slide one byte at a time).
#[test]
fn runtime_str_replace_end_to_end() {
    let src = "fn main():\n    \
                   println(str_replace(\"aXbXc\", \"X\", \"--\"))\n    \
                   println(str_replace(\"abc\", \"z\", \"q\"))\n    \
                   println(str_replace(\"a-b-c\", \"-\", \"\"))\n    \
                   println(str_replace(\"aaaa\", \"aa\", \"b\"))\n    \
                   println(str_replace(\"aaaaa\", \"aa\", \"b\"))\n    \
                   println(str_replace(\"abc\", \"\", \"Z\"))\n";
    let output = compile_and_run("str_replace", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["a--b--c", "abc", "abc", "bb", "bba", "abc"], "{}", stdout);
}

/// `str_split(s, sep) -> List<str>`: a basic multi-part split, empty
/// segments from a leading/trailing/doubled separator (kept, not filtered),
/// no occurrence of `sep` at all (the whole string as a single element), a
/// multi-character separator (must advance by the separator's own length,
/// not one byte), and the documented empty-`sep` scope cut (whole string as
/// a single element, since scanning for `""` would never advance).
#[test]
fn runtime_str_split_end_to_end() {
    let src = "fn main():\n    \
                   let a = str_split(\"a,b,c\", \",\")\n    \
                   println(f\"{a.len()}\")\n    \
                   let mut i: i32 = 0\n    \
                   while i < a.len():\n        \
                       println(a[i])\n        \
                       i += 1\n    \
                   let b = str_split(\",a,,b,\", \",\")\n    \
                   println(f\"{b.len()}\")\n    \
                   let mut j: i32 = 0\n    \
                   while j < b.len():\n        \
                       let e: str = b[j]\n        \
                       let elen: i32 = len(e)\n        \
                       println(f\"[{e}]{elen}\")\n        \
                       j += 1\n    \
                   let c = str_split(\"nosep\", \",\")\n    \
                   println(f\"{c.len()}\")\n    \
                   println(c[0])\n    \
                   let d = str_split(\"whole\", \"\")\n    \
                   println(f\"{d.len()}\")\n    \
                   println(d[0])\n    \
                   let e = str_split(\"a::b:::c\", \"::\")\n    \
                   println(f\"{e.len()}\")\n    \
                   let mut k: i32 = 0\n    \
                   while k < e.len():\n        \
                       println(e[k])\n        \
                       k += 1\n";
    let output = compile_and_run("str_split", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec![
            "3", "a", "b", "c",
            "5", "[]0", "[a]1", "[]0", "[b]1", "[]0",
            "1", "nosep",
            "1", "whole",
            "3", "a", "b", ":c",
        ],
        "{}", stdout
    );
}

/// `str_join(parts, sep) -> str`: a normal multi-element join, an empty list
/// (yields an empty `str`), a single-element list (no separator inserted at
/// all), and a multi-character separator -- together with
/// `runtime_str_split_end_to_end`'s coverage, confirms `str_join` really is
/// `str_split`'s inverse for a non-empty separator.
#[test]
fn runtime_str_join_end_to_end() {
    let src = "fn main():\n    \
                   let a = str_split(\"a,b,,c\", \",\")\n    \
                   println(str_join(a, \"|\"))\n    \
                   let empty: List<str> = List<str>()\n    \
                   let joined_empty: str = str_join(empty, \",\")\n    \
                   let jlen: i32 = len(joined_empty)\n    \
                   println(f\"[{joined_empty}]{jlen}\")\n    \
                   let mut one: List<str> = List<str>()\n    \
                   one.push(\"solo\")\n    \
                   println(str_join(one, \"++\"))\n    \
                   let multi = str_split(\"x::y::z\", \"::\")\n    \
                   println(str_join(multi, \"::\"))\n";
    let output = compile_and_run("str_join", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["a|b||c", "[]0", "solo", "x::y::z"], "{}", stdout);
}

/// Every one of these eight builtins against a genuinely `null` `str` --
/// not just an empty-but-allocated one -- via the same "read a despawned
/// arena slot through a stale `Handle<T>`" pattern
/// `runtime_handle_and_genref_despawn_respawn_cycle_...` above already
/// establishes to reach a real zero-valued field. `Codegen::emit_str_or_empty`
/// normalizes every one of these to the shared `@str.empty` constant before
/// `strlen`/`strstr`/`strncmp`/`strcmp` ever see it, so none of this should
/// crash -- confirmed via a real run rather than just reading the codegen.
#[test]
fn runtime_str_ops_null_str_safety_end_to_end() {
    let src = "struct Holder:\n    val: str\n\n\
               arena Holders: Holder\n\n\
               fn main():\n    \
                   spawn Holders(\"present\")\n    \
                   let h = Handle<Holder>(0)\n    \
                   despawn Holders[0]\n    \
                   let n: str = h[0].val\n    \
                   let a: bool = str_contains(n, \"x\")\n    \
                   let b: bool = str_starts_with(n, \"\")\n    \
                   let c: bool = str_ends_with(n, \"\")\n    \
                   let d: i32 = str_index_of(n, \"x\")\n    \
                   println(f\"{a},{b},{c},{d}\")\n    \
                   let trimmed: str = str_trim(n)\n    \
                   let tlen: i32 = len(trimmed)\n    \
                   println(f\"{tlen}\")\n    \
                   let replaced: str = str_replace(n, \"a\", \"b\")\n    \
                   let rlen: i32 = len(replaced)\n    \
                   println(f\"{rlen}\")\n    \
                   let parts = str_split(n, \",\")\n    \
                   println(f\"{parts.len()}\")\n    \
                   let joined: str = str_join(parts, \",\")\n    \
                   let jlen: i32 = len(joined)\n    \
                   println(f\"{jlen}\")\n    \
                   println(\"done\")\n";
    let output = compile_and_run("str_ops_null_safety", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false,true,true,-1", "0", "0", "1", "0", "done"], "{}", stdout);
}

/// The checker rejects wrong arity/types for the new `str_*` builtins with a
/// clean diagnostic (rather than smuggling a non-`str` value through to
/// `emit_raw_str_ptr`, which assumes its argument is already a `str`) --
/// mirrors `checker_rejects_env_get_non_str_arg`'s existing coverage of this
/// bug class for an older builtin.
#[test]
fn checker_rejects_str_builtins_wrong_arity_and_types() {
    let cases: &[(&str, &str)] = &[
        ("fn t():\n    str_contains(\"a\")\n", "`str_contains` expects 2 argument(s), found 1"),
        ("fn t():\n    str_contains(42, \"a\")\n", "`str_contains` argument 1 expected `str`"),
        ("fn t():\n    str_starts_with(\"a\", 42)\n", "`str_starts_with` argument 2 expected `str`"),
        ("fn t():\n    str_ends_with(\"a\", 42)\n", "`str_ends_with` argument 2 expected `str`"),
        ("fn t():\n    str_index_of(\"a\")\n", "`str_index_of` expects 2 argument(s), found 1"),
        ("fn t():\n    str_trim(42)\n", "`str_trim` expects a `str` argument"),
        ("fn t():\n    str_replace(\"a\", \"b\")\n", "`str_replace` expects 3 argument(s), found 2"),
        ("fn t():\n    str_replace(\"a\", 42, \"b\")\n", "`str_replace` argument 2 expected `str`"),
        ("fn t():\n    str_split(\"a\", 42)\n", "`str_split` argument 2 expected `str`"),
        ("fn t():\n    str_join(42, \",\")\n", "`str_join` argument 1 expected `List<str>`"),
        ("fn t():\n    let l: List<i32> = List<i32>()\n    str_join(l, \",\")\n", "`str_join` argument 1 expected `List<str>`"),
        ("fn t():\n    str_join([\"a\"], 42)\n", "`str_join` argument 2 expected `str`"),
    ];
    for (src, expected) in cases {
        let module = Driver::parse(src).expect("should parse");
        let Err(diags) = Driver::check(&module) else { panic!("{:?} should fail to type-check", src) };
        assert!(diags.iter().any(|d| d.message.contains(expected)), "source {:?}: {:?}", src, diags);
    }
}

/// A sustained `str_replace`/`str_split`/`str_join` loop (each iteration
/// allocates and discards several fresh `str`/`List<str>` objects) stays
/// flat rather than leaking -- every intermediate buffer this trio's codegen
/// allocates (`star_rc_alloc` results, the dynamic `List<str>` growth buffer)
/// must actually be released once its owning `let` goes out of scope.
#[test]
fn runtime_str_ops_sustained_loop_does_not_leak() {
    let src = "fn main():\n    \
                   let mut i: i32 = 0\n    \
                   while i < 200000:\n        \
                       let r: str = str_replace(\"the quick brown fox\", \"o\", \"00\")\n        \
                       let parts = str_split(r, \" \")\n        \
                       let joined: str = str_join(parts, \"-\")\n        \
                       let l: i32 = len(joined)\n        \
                       i += 1\n    \
                   println(\"done\")\n";
    assert_no_leak("str_ops_sustained_loop_leak", src, 20 * 1024 * 1024);
}
