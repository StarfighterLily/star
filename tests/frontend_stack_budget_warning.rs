//! Regression tests for `todo.md` P0 #2: "Give the compiler *some* notion of
//! stack budget for large-aggregate `let`s ... even a `star check`-time
//! warning when a function's local aggregate footprint plus its call depth
//! crosses a threshold."
//!
//! Implemented by `Checker::check_stack_budget`
//! (`src/types/stack_budget.rs`): once a module checks cleanly, it computes
//! each function/method's own `let`-bound aggregate footprint plus the
//! heaviest reachable static call chain's own footprint on top of it, and
//! warns (never errors -- see `typecheck_with_warnings`) at any function
//! whose own footprint is non-zero and whose combined total reaches
//! `1MiB` -- the same "Windows' 1MiB linker-default stack overflowed" real
//! incident `crate::main`'s `DEFAULT_STACK_SIZE_BYTES` doc comment
//! documents fixing for `star build`'s linked executables, given a
//! compile-time signal here instead of only a post-hoc runtime crash.
//!
//! `Ty::Array(u8, N)` is used throughout as the large-local shape (its
//! `approx_stack_size` is exactly `N` bytes -- no struct-field padding to
//! account for), so each test's byte-count math is exact and legible.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

/// One megabyte, matching `stack_budget::STACK_BUDGET_WARN_BYTES` -- kept as
/// its own named constant here (rather than a magic `1048576` sprinkled
/// through every test) purely for readability at each call site below.
const ONE_MIB: usize = 1024 * 1024;

/// A source with no large aggregates at all produces no stack-budget
/// warning -- the common case (every existing example/test program in this
/// repo) must stay silent.
#[test]
fn no_warning_for_ordinary_small_locals() {
    let src = "fn helper() -> i32:\n    let x: i32 = 1\n    let y: i32 = 2\n    x + y\n\n\
               fn main():\n    let r = helper()\n    println(f\"{r}\")\n";
    let (_typed, warnings) = typecheck_with_warnings(src);
    assert!(warnings.is_empty(), "expected no stack-budget warnings, got: {:?}", warnings.iter().map(|w| &w.message).collect::<Vec<_>>());
}

/// A single function whose own local aggregate already crosses the budget
/// on its own (no call chain needed) is flagged directly. Split across two
/// struct fields (each comfortably under `Checker::MAX_INLINE_LEN`'s
/// 1,000,000-element cap on any one `[T; N]`) rather than one giant array,
/// since a single array big enough to cross the 1MiB stack budget alone
/// would itself exceed that unrelated, separately-enforced limit.
#[test]
fn warns_when_a_single_function_own_local_alone_crosses_budget() {
    let a = 600_000;
    let b = 600_000;
    assert!(a + b >= ONE_MIB);
    let src = format!(
        "struct Big:\n    a: [u8; {a}]\n    b: [u8; {b}]\n\n\
         fn main():\n    let big: Big = Big(a = [0 as u8; {a}], b = [0 as u8; {b}])\n    println(\"hi\")\n",
        a = a,
        b = b
    );
    let (_typed, warnings) = typecheck_with_warnings(&src);
    assert_eq!(warnings.len(), 1, "expected exactly one warning, got: {:?}", warnings.iter().map(|w| &w.message).collect::<Vec<_>>());
    assert!(warnings[0].message.contains("main"), "warning should name the offending function: {}", warnings[0].message);
    assert!(warnings[0].message.contains(&(a + b).to_string()), "warning should cite the actual combined byte count: {}", warnings[0].message);
}

/// A local well under the budget produces no warning even alone -- confirms
/// this is a threshold, not "any aggregate local at all."
#[test]
fn no_warning_for_a_large_but_under_threshold_local() {
    let n = 200_000;
    let src = format!("fn main():\n    let a: [u8; {n}] = [0 as u8; {n}]\n    println(\"hi\")\n", n = n);
    let (_typed, warnings) = typecheck_with_warnings(&src);
    assert!(warnings.is_empty(), "a single 200,000-byte local should stay under the 1MiB budget: {:?}", warnings.iter().map(|w| &w.message).collect::<Vec<_>>());
}

/// The core incident this check exists for: neither function's own local
/// crosses the budget in isolation, but `main`'s own local *combined with*
/// what its call to `helper` adds on top does. Only `main` -- the function
/// that actually owns the data held live across the call -- is warned about;
/// `helper` (whose own footprint alone stays under budget) is not, since a
/// warning at a pure "happens to be called from something heavy" leaf would
/// misdirect a reader looking for what to restructure.
#[test]
fn warns_at_the_caller_whose_combined_footprint_crosses_budget_not_the_innocent_callee() {
    let main_local = 900_000;
    let helper_local = 200_000;
    assert!(main_local + helper_local >= ONE_MIB, "test fixture should actually cross the budget combined");
    assert!(main_local < ONE_MIB && helper_local < ONE_MIB, "neither local should cross the budget alone");
    let src = format!(
        "fn helper():\n    let h: [u8; {hl}] = [0 as u8; {hl}]\n    println(f\"{{h[0]}}\")\n\n\
         fn main():\n    let m: [u8; {ml}] = [0 as u8; {ml}]\n    helper()\n    println(f\"{{m[0]}}\")\n",
        hl = helper_local,
        ml = main_local
    );
    let (_typed, warnings) = typecheck_with_warnings(&src);
    assert_eq!(warnings.len(), 1, "expected exactly one warning (at `main` only), got: {:?}", warnings.iter().map(|w| &w.message).collect::<Vec<_>>());
    assert!(warnings[0].message.contains("main"), "the warning should name `main`: {}", warnings[0].message);
    assert!(!warnings[0].message.contains("`helper`"), "the innocent callee should not itself be named as the offender: {}", warnings[0].message);
}

/// Two separate large-but-under-threshold locals in unrelated, never-calling
/// functions must not be summed together -- confirms the analysis is
/// call-graph-based, not "sum every large local in the whole module."
#[test]
fn does_not_combine_footprints_across_unrelated_non_calling_functions() {
    let n = 700_000;
    let src = format!(
        "fn a():\n    let x: [u8; {n}] = [0 as u8; {n}]\n    println(f\"{{x[0]}}\")\n\n\
         fn b():\n    let y: [u8; {n}] = [0 as u8; {n}]\n    println(f\"{{y[0]}}\")\n\n\
         fn main():\n    a()\n    b()\n",
        n = n
    );
    let (_typed, warnings) = typecheck_with_warnings(&src);
    assert!(warnings.is_empty(), "`a` and `b` never call each other, so their 700,000-byte locals must not combine: {:?}", warnings.iter().map(|w| &w.message).collect::<Vec<_>>());
}

/// A method call (`obj.method()`) must be resolved into the call graph the
/// same way a free-function call is -- `Checker::check_stack_budget`'s
/// `callee_key` has a dedicated `Field`-callee arm for exactly this, keyed
/// `"{struct}#{method}"`. Regression coverage for that resolution actually
/// firing: if it silently failed to resolve the method call, `main`'s
/// cumulative footprint would fall back to just its own local (900,000
/// bytes, under budget) and this test would see no warning at all.
#[test]
fn resolves_method_calls_into_the_call_graph() {
    let main_local = 900_000;
    let method_local = 200_000;
    let src = format!(
        "struct Widget:\n    tag: i32\n\n\
         impl Widget:\n    fn render(self):\n        let buf: [u8; {ml}] = [0 as u8; {ml}]\n        println(f\"{{buf[0]}}\")\n\n\
         fn main():\n    let big: [u8; {main}] = [0 as u8; {main}]\n    let w = Widget(tag = 1)\n    w.render()\n    println(f\"{{big[0]}}\")\n",
        ml = method_local,
        main = main_local
    );
    let (_typed, warnings) = typecheck_with_warnings(&src);
    assert_eq!(warnings.len(), 1, "expected exactly one warning (at `main`), got: {:?}", warnings.iter().map(|w| &w.message).collect::<Vec<_>>());
    assert!(warnings[0].message.contains("main"), "warning should name `main`: {}", warnings[0].message);
}

/// A struct field that is itself another struct must contribute its own
/// fields' sizes recursively (`approx_stack_size`'s `Ty::Named` arm) -- not
/// just the outer struct's directly-declared fields.
#[test]
fn nested_struct_field_sizes_are_summed_recursively() {
    let inner_n = 400_000;
    let outer_n = 700_000;
    // Neither field alone crosses the budget, but summed (inner struct's
    // field plus the outer struct's own array field) they do.
    assert!(inner_n + outer_n >= ONE_MIB);
    let src = format!(
        "struct Inner:\n    a: [u8; {inner_n}]\n\n\
         struct Outer:\n    inner: Inner\n    b: [u8; {outer_n}]\n\n\
         fn main():\n    let o: Outer = Outer(inner = Inner(a = [0 as u8; {inner_n}]), b = [0 as u8; {outer_n}])\n    println(\"hi\")\n",
        inner_n = inner_n,
        outer_n = outer_n
    );
    let (_typed, warnings) = typecheck_with_warnings(&src);
    assert_eq!(warnings.len(), 1, "nested struct field sizes should sum to cross budget, got: {:?}", warnings.iter().map(|w| &w.message).collect::<Vec<_>>());
}

/// A heap-backed `List<T>` is just an 8-byte object pointer on the stack
/// (`approx_stack_size`'s `Ty::List` arm) regardless of how many elements it
/// might hold at runtime -- must never be treated as a large aggregate the
/// way a fixed-size `[T; N]` array is.
#[test]
fn heap_backed_list_local_is_never_flagged() {
    let src = "fn main():\n    let xs: List<i32> = List<i32>()\n    println(f\"{xs.len()}\")\n";
    let (_typed, warnings) = typecheck_with_warnings(src);
    assert!(warnings.is_empty(), "a `List<T>` local is heap-backed and must never be flagged: {:?}", warnings.iter().map(|w| &w.message).collect::<Vec<_>>());
}

/// Direct self-recursion with a large local must not hang or infinitely
/// recurse the compiler itself (`cumulative_footprint`'s `path` guard) --
/// it should still produce exactly one warning (the function's own local
/// alone already crosses budget) and return promptly. Uses a two-field
/// struct rather than one giant array for the same `MAX_INLINE_LEN` reason
/// as `warns_when_a_single_function_own_local_alone_crosses_budget`.
#[test]
fn self_recursive_function_with_large_local_does_not_hang_and_still_warns() {
    let a = 600_000;
    let b = 600_000;
    assert!(a + b >= ONE_MIB);
    let src = format!(
        "struct Big:\n    a: [u8; {a}]\n    b: [u8; {b}]\n\n\
         fn recurse(n: i32):\n    let buf: Big = Big(a = [0 as u8; {a}], b = [0 as u8; {b}])\n    println(f\"{{buf.a[0]}}\")\n    if n > 0:\n        recurse(n - 1)\n\n\
         fn main():\n    recurse(3)\n",
        a = a,
        b = b
    );
    let start = std::time::Instant::now();
    let (_typed, warnings) = typecheck_with_warnings(&src);
    assert!(start.elapsed().as_secs() < 5, "self-recursive call-graph traversal should terminate promptly, took {:?}", start.elapsed());
    assert_eq!(warnings.len(), 1, "expected exactly one warning (at `recurse`), got: {:?}", warnings.iter().map(|w| &w.message).collect::<Vec<_>>());
    assert!(warnings[0].message.contains("recurse"), "warning should name `recurse`: {}", warnings[0].message);
}

/// Mutual recursion (`a` calls `b` calls `a`) must likewise terminate rather
/// than looping forever through the call graph.
#[test]
fn mutually_recursive_functions_do_not_hang() {
    let n = 200_000;
    let src = format!(
        "fn a(n: i32):\n    let x: [u8; {n}] = [0 as u8; {n}]\n    println(f\"{{x[0]}}\")\n    if n > 0:\n        b(n - 1)\n\n\
         fn b(n: i32):\n    let y: [u8; {n}] = [0 as u8; {n}]\n    println(f\"{{y[0]}}\")\n    if n > 0:\n        a(n - 1)\n\n\
         fn main():\n    a(3)\n",
        n = n
    );
    let start = std::time::Instant::now();
    let (_typed, _warnings) = typecheck_with_warnings(&src);
    assert!(start.elapsed().as_secs() < 5, "mutual-recursion call-graph traversal should terminate promptly, took {:?}", start.elapsed());
}

/// A warning is a `Diagnostic::warning` (not `error`) severity, and must
/// never turn a clean module into a failing check -- `typecheck_with_warnings`
/// itself already `.expect()`s a successful `Checker::check`, but this test
/// asserts the severity explicitly too, since a caller (`star check`) tells
/// the two apart by exactly this field to decide the process exit code.
#[test]
fn stack_budget_finding_is_warning_severity_not_error() {
    let a = 600_000;
    let b = 600_000;
    let src = format!(
        "struct Big:\n    a: [u8; {a}]\n    b: [u8; {b}]\n\n\
         fn main():\n    let big: Big = Big(a = [0 as u8; {a}], b = [0 as u8; {b}])\n    println(\"hi\")\n",
        a = a,
        b = b
    );
    let (_typed, warnings) = typecheck_with_warnings(&src);
    assert_eq!(warnings.len(), 1);
    assert_eq!(warnings[0].severity, star::diagnostics::Severity::Warning, "a stack-budget finding must never be error severity");
}
