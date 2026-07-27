//! Per-iteration `frame:` reclaim inside loops; alloca-hoisting regression
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== per-iteration `frame:` reclaim inside a loop (`NOTES.md` 1.2) ======

/// The exact shape `projects/snake/NOTES.md` section 1.2 confirmed live: a
/// `for` loop inside a `frame:` block, `let`-binding a small struct on every
/// pass, run for more iterations than `FRAME_BUF_SIZE` (4096 bytes) could
/// possibly hold if nothing were reclaimed until the whole `frame:` block
/// exits (700 iterations x 8 bytes = 5600 > 4096; the real game's own
/// repro was 768 iterations over the same 8-byte `Cell` shape). Previously
/// this reliably hit "a `frame:` block exceeded its 4096-byte capacity";
/// now each iteration's allocation is reclaimed before the next one starts,
/// so the loop runs to completion regardless of iteration count. Sums the
/// allocated structs' fields (not just "didn't crash") to prove the loop
/// still ran every iteration correctly, not just silently short-circuited.
#[test]
fn runtime_for_loop_inside_frame_block_reclaims_space_per_iteration_end_to_end() {
    let src = "struct Cell:\n    x: i32\n    y: i32\n\nfn main():\n    let mut total = 0\n    frame:\n        for i in 0..700:\n            let c = Cell(i, i)\n            total = total + c.x\n    println(f\"{total}\")\n";
    let output = compile_and_run("for_loop_inside_frame_block_reclaims_per_iteration", src);
    assert!(output.status.success(), "{:?}", output.status);
    // sum(0..699) = 699*700/2 = 244650
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "244650");
}

/// Same fix, `while`-loop side, with a `continue` partway through each
/// iteration (before reaching the loop's normal fallthrough) -- guards that
/// `continue`'s target block (`while_cond`, which `TypedStmt::Continue`
/// jumps to directly) is where the per-iteration restore actually lives, so
/// `continue` reclaims exactly like normal fallthrough does, not just the
/// non-`continue` path.
#[test]
fn runtime_while_loop_inside_frame_block_with_continue_reclaims_space_per_iteration_end_to_end() {
    let src = "struct Cell:\n    x: i32\n    y: i32\n\nfn main():\n    let mut total = 0\n    let mut i = 0\n    frame:\n        while i < 700:\n            let c = Cell(i, i)\n            i = i + 1\n            if c.x % 2 == 0:\n                continue\n            total = total + c.x\n    println(f\"{total}\")\n";
    let output = compile_and_run("while_loop_inside_frame_block_continue_reclaims_per_iteration", src);
    assert!(output.status.success(), "{:?}", output.status);
    // sum of odd i in 0..699 = 1+3+...+699 = 350^2 = 122500
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "122500");
}

/// `break` bypasses the loop's own continue-target block (where the
/// per-iteration restore normally lives) entirely, jumping straight to the
/// loop's `end_label` -- so it needs its own copy of that same restore
/// (`TypedStmt::Break`'s own `frame_off` check). Proven indirectly via a
/// tight byte budget rather than a loop-iteration count: 400 passes each
/// allocate one 8-byte `Cell` before the last one `break`s; if `break`
/// leaves that final iteration's 8 bytes unreclaimed, the *next* allocation
/// in the same `frame:` block (a 4092-byte array, comfortably under 4096
/// bytes on its own but not with 8 leaked bytes already ahead of it) tips
/// over the 4096-byte cap and aborts. If `break` restores correctly, the
/// array allocation starts from a clean offset and fits.
#[test]
fn runtime_break_inside_frame_loop_reclaims_space_before_exiting_end_to_end() {
    let src = "struct Cell:\n    x: i32\n    y: i32\n\nfn main():\n    frame:\n        let mut i = 0\n        while i < 400:\n            let c = Cell(i, i)\n            i = i + 1\n            if i == 400:\n                break\n        let big: [i32; 1023] = [0; 1023]\n    println(\"ok\")\n";
    let output = compile_and_run("break_inside_frame_loop_reclaims_before_exiting", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "ok");
}

// --- §3.1: closure capturing a frame-local `self` by pointer ---------------

/// A method returning a closure that captures `self` by pointer, called on
/// a frame-local receiver and then returned out of the enclosing function,
/// smuggles a dangling frame pointer past the escape check -- this is the
/// exact bug class the escape analysis exists to prevent.
#[test]
fn rejects_closure_capturing_frame_local_self_escaping_via_return() {
    let src = r#"struct Holder:
    val: i32

impl Holder:
    fn get_closure(self) -> Fn() -> i32:
        fn(): self.val

fn make() -> Fn() -> i32:
    frame:
        let h = Holder(777)
        return h.get_closure()
"#;
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("a closure escaping with a frame-local self pointer should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("frame") && d.message.contains("h")), "{:?}", errs);
}

/// The same closure, called and used *before* the `frame:` block ends
/// (never escaping it), is safe: the receiver's memory is still valid for
/// every use.
#[test]
fn accepts_closure_capturing_frame_local_self_used_within_frame_scope() {
    let src = r#"struct Holder:
    val: i32

impl Holder:
    fn get_closure(self) -> Fn() -> i32:
        fn(): self.val

fn t() -> i32:
    frame:
        let h = Holder(777)
        let c = h.get_closure()
        return c()
"#;
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "using the closure entirely within the frame scope should be allowed");
}

// --- §3.1b: closure capturing self by pointer from *any* local struct, not
// just a `frame:`-scoped one -- see `Checker::check_frame_escapes` /
// `src/types/frame_analysis.rs`'s `local_structs` tracking. -----------------

/// The exact todo.md repro: a method returning a closure that captures
/// `self` by pointer, called on a plain (non-`frame`) local struct, then
/// returned out of its enclosing function. Before this fix, `frame_locals`
/// only tracked `let`-bindings inside a `frame:` block, so an ordinary
/// stack-local receiver's dangling `self` pointer sailed straight past the
/// escape check and printed a garbage value at runtime instead of failing
/// to compile.
#[test]
fn rejects_closure_capturing_plain_local_self_escaping_via_return() {
    let src = r#"struct Holder:
    val: i32

impl Holder:
    fn get_closure(self) -> Fn() -> i32:
        fn(): self.val

fn make() -> Fn() -> i32:
    let h = Holder(777)
    return h.get_closure()
"#;
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("a closure escaping with a plain local's self pointer should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("h")), "{:?}", errs);
}

/// The same bug shape, but the dangling receiver is a by-value function
/// *parameter* rather than a `let`-bound local -- todo.md explicitly calls
/// this case out too, since a parameter's storage is just as scoped to the
/// enclosing function as an ordinary local's.
#[test]
fn rejects_closure_capturing_by_value_param_self_escaping_via_return() {
    let src = r#"struct Holder:
    val: i32

impl Holder:
    fn get_closure(self) -> Fn() -> i32:
        fn(): self.val

fn make(h: Holder) -> Fn() -> i32:
    return h.get_closure()
"#;
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("a closure escaping with a by-value parameter's self pointer should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("h")), "{:?}", errs);
}

/// The same closure, called and used *before* the enclosing function
/// returns (never escaping it), is safe: the plain local's storage is still
/// valid for the whole call. This is the over-rejection risk todo.md flags
/// when broadening `frame_locals` -- confirms the fix stays scoped to actual
/// escapes, not merely calling a self-capturing-closure method at all.
#[test]
fn accepts_closure_capturing_plain_local_self_used_within_same_function() {
    let src = r#"struct Holder:
    val: i32

impl Holder:
    fn get_closure(self) -> Fn() -> i32:
        fn(): self.val

fn t() -> i32:
    let h = Holder(777)
    let c = h.get_closure()
    return c()
"#;
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "using the closure entirely within its defining function should be allowed");
}

/// Returning a plain local struct *by value* (no closure involved at all)
/// must stay accepted -- broadening the escape tracking to ordinary locals
/// must not reject this extremely common, entirely sound pattern just
/// because the local's name is now tracked for the closure-capture check.
#[test]
fn accepts_returning_plain_local_struct_by_value() {
    let src = r#"struct Point:
    x: i32
    y: i32

fn make() -> Point:
    let p = Point(1, 2)
    return p
"#;
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "returning an ordinary local struct by value is always safe and must not be rejected");
}

// --- §3.2: arena-capacity overflow is loud, not silent ----------------------

/// Spawning past `ARENA_CAPACITY` (1024) live elements still drops the
/// spawn (a fixed backing store never reallocs/moves, since `par`/`swarm`
/// workers may read it concurrently), but now prints a runtime warning
/// identifying the offending arena instead of failing completely silently.
#[test]
fn runtime_arena_overflow_warns_instead_of_silently_dropping() {
    use std::process::Command;

    let output = Command::new("examples/arena_capacity.exe").output().expect("failed to execute arena_capacity.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("arena `Enemies` is full"), "should warn about the specific arena: {}", stdout);
    assert!(stdout.contains("done spawning"), "the program should still run to completion: {}", stdout);
    assert_eq!(output.status.code(), Some(0));
}

// --- §3.3: GenRef dereference of a never-spawned slot -----------------------

/// Dereferencing a `GenRef` against a slot that was never spawned into --
/// either before any spawn into the arena at all (backing storage still
/// null) or a distinct slot in an otherwise-populated arena (uninitialized
/// heap garbage) -- must fall back to the zero value, never segfault or
/// read garbage. This directly falsifies the "never a segfault" guarantee
/// `docs/design.md` documents if it regresses.
#[test]
fn runtime_genref_never_spawned_falls_back_to_zero_not_segfault() {
    use std::process::Command;

    let output = Command::new("examples/genref_never_spawned.exe").output().expect("failed to execute genref_never_spawned.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before any spawn: x=0 y=0"), "deref before any spawn into the arena: {}", stdout);
    assert!(stdout.contains("other slot live, this slot never spawned: x=0 y=0"), "deref of an unspawned slot in a live arena: {}", stdout);
    assert_eq!(output.status.code(), Some(0), "must not crash: {:?}", output.status);
}

/// Codegen for a `GenRef` dereference requires the live generation to be
/// *odd* (the parity that encodes liveness), not just equal to the stored
/// generation -- closing the hole where a never-spawned slot's generation
/// (`0`) is indistinguishable from a freshly-created `GenRef`'s own
/// captured generation for that same slot.
#[test]
fn codegen_genref_index_checks_liveness_parity_not_just_generation_equality() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\narena Entities: Point\n\nfn follow(r: GenRef<Point>) -> Point:\n    r[0]\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("and i64"), "should mask the live generation (64-bit) to check odd/even parity: {}", ir);
    assert!(ir.contains("icmp eq i64") && ir.matches("icmp eq i64").count() >= 2, "should check both generation equality and liveness parity: {}", ir);
    assert!(ir.contains("and i1"), "the ok path should require both conditions together: {}", ir);
}

// --- §3.5: `par`/`swarm` ban transitive through function calls -------------

/// Moving a `spawn` one level into a helper function, then calling that
/// helper from inside a `par`/`swarm` body, must still be rejected -- the
/// same unsynchronized data race the direct-`spawn` ban exists to prevent.
#[test]
fn rejects_spawn_hidden_behind_helper_function_call_inside_par() {
    let src = format!(
        "{}fn sneaky_spawn():\n    spawn Enemies(5)\n\nfn t():\n    par e in Enemies:\n        sneaky_spawn()\n        e.hp -= 1\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let errs = Driver::check(&module).expect_err("spawn hidden behind a helper function call should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("sneaky_spawn")), "{:?}", errs);
}

/// The same hazard nested two calls deep (not just one level) is still
/// caught, via the transitive fixed-point propagation over the call graph.
#[test]
fn rejects_spawn_hidden_two_calls_deep_inside_par() {
    let src = format!(
        "{}fn innermost():\n    spawn Enemies(5)\n\nfn middle():\n    innermost()\n\nfn t():\n    par e in Enemies:\n        middle()\n        e.hp -= 1\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let errs = Driver::check(&module).expect_err("spawn hidden two calls deep should still be a type error");
    assert!(errs.iter().any(|d| d.message.contains("middle")), "{:?}", errs);
}

/// A `frame:` block hidden behind a helper function call is the same
/// hazard: `@frame.off`/`@frame.buf` are single shared globals racing
/// across every worker thread, and `in_frame` being a codegen-time-only
/// flag doesn't scope to the callee.
#[test]
fn rejects_frame_hidden_behind_helper_function_call_inside_par() {
    let src = format!(
        "{}fn sneaky_frame():\n    frame:\n        let x = 1\n\nfn t():\n    par e in Enemies:\n        sneaky_frame()\n        e.hp -= 1\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let errs = Driver::check(&module).expect_err("frame hidden behind a helper function call should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("sneaky_frame")), "{:?}", errs);
}

/// An ordinary helper function that doesn't spawn/despawn/open a `frame:`
/// block anywhere in its call graph is still perfectly callable from inside
/// a `par`/`swarm` body -- the transitive ban must not become a blanket ban
/// on all function calls.
#[test]
fn accepts_harmless_helper_function_call_inside_par() {
    let src = format!(
        "{}fn double(n: i32) -> i32:\n    n * 2\n\nfn t():\n    par e in Enemies:\n        e.hp = double(e.hp)\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "a harmless helper call should still be allowed: {:?}", Driver::check(&module).err());
}

/// A `frame:` block written *directly* inside a `par`/`swarm` body (not
/// hidden behind a helper call) is the same shared-global race as
/// `rejects_frame_hidden_behind_helper_function_call_inside_par` -- but
/// `walk_par_stmt`'s own `TypedStmt::Frame` arm previously just recursed
/// into the body with no check at all (unlike the `Spawn`/`Despawn`/
/// `Closure` arms right next to it), so this exact, more obvious case of the
/// hazard was the one actually left unguarded.
#[test]
fn rejects_frame_directly_inside_par() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        frame:\n            let x = e.hp\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let errs = Driver::check(&module).expect_err("frame: directly inside a par/swarm body should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("frame")), "{:?}", errs);
}

/// The transitive spawn/despawn/`frame:` ban is keyed by each hazardous
/// function's *declared* (template) name (`compute_unsafe_par_fns` walks the
/// raw, pre-monomorphization AST) -- but a generic function's call site
/// names its *mangled* monomorphized form instead (`sneaky__i32`, via
/// `Checker::instantiate_fn`), which was never in that set, so any generic
/// function/method opening a `frame:` block silently bypassed the ban simply
/// by being generic.
#[test]
fn rejects_generic_function_hazard_hidden_behind_monomorphization() {
    let src = format!(
        "{}fn sneaky<T>(x: T):\n    frame:\n        let tmp = x\n\nfn t():\n    par e in Enemies:\n        sneaky(e.hp)\n        e.hp -= 1\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let errs = Driver::check(&module).expect_err("a generic function hiding a frame: hazard should still be a type error");
    assert!(errs.iter().any(|d| d.message.contains("sneaky")), "{:?}", errs);
}

/// A `Pattern::Binding` match arm (`v -> ...`, binding the whole scrutinee
/// to a fresh name rather than destructuring it) is safe to mutate/use
/// inside a `par`/`swarm` body -- it's a fresh per-arm local exactly like a
/// destructured payload-enum/struct-pattern binding, which `walk_par_expr`'s
/// `TypedExpr::Match` arm already treated as safe. Previously only
/// `Pattern::EnumVariant`/`Pattern::Struct` bindings were added to `locals`,
/// so this pattern kind's binding was incorrectly rejected as "cannot mutate
/// a captured value" -- a false positive (usability bug, not a caught
/// safety hole), fixed alongside the (separately far more broken)
/// `Pattern::Binding` bugs covered by `runtime_match_binding_pattern_*`.
#[test]
fn accepts_binding_pattern_local_mutation_inside_par() {
    let src = format!(
        "{}fn t():\n    par e in Enemies:\n        match e.hp:\n            v ->\n                let mut local = v\n                local = local + 1\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "mutating a Pattern::Binding local inside par should be allowed: {:?}", Driver::check(&module).err());
}

// --- §1.1-1.4: type-checking holes ------------------------------------------

/// A `let` annotation that disagrees with the value's actual inferred type
/// is now a type error, instead of the annotation being resolved and used
/// as the tracked type with no comparison against the value at all (which
/// previously reached codegen as a `load %Foo, %Foo* %t0` where `%t0` was
/// really an `alloca i32`).
#[test]
fn rejects_let_annotation_mismatched_with_value_type() {
    let src = "struct Foo:\n    x: i32\n\nfn t():\n    let a: Foo = 42\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("let annotation mismatched with the value's type should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("Foo") && d.message.contains("Int")), "{:?}", errs);
}

/// A `let` with a correctly-matching annotation still type-checks fine.
#[test]
fn accepts_let_annotation_matching_value_type() {
    let module = Driver::parse("fn t():\n    let a: i32 = 42\n").expect("should parse");
    assert!(Driver::check(&module).is_ok());
}

/// An ordinary assignment whose value's type doesn't match the target's is
/// now a type error -- previously `Stmt::Assign` only ever checked for
/// duplicate swizzle write-target components, with no general "is `value`
/// assignable to `target`" check at all.
#[test]
fn rejects_assign_value_type_mismatched_with_target() {
    let module = Driver::parse("fn t():\n    let mut x: i32 = 1\n    x = \"not an int\"\n").expect("should parse");
    let errs = Driver::check(&module).expect_err("assigning a mismatched type should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("Str") && d.message.contains("Int")), "{:?}", errs);
}

/// An explicit `return <expr>` whose type disagrees with the function's
/// declared return type is now a type error. Previously codegen emitted
/// `ret <ty-of-the-returned-expr>` rather than `ret <declared-ty>`, so a
/// mismatch reached codegen as a function whose declared LLVM signature and
/// actual terminator disagreed.
#[test]
fn rejects_explicit_return_type_mismatch() {
    let module = Driver::parse("fn get_val() -> i32:\n    if true:\n        return \"nope\"\n    return 0\n").expect("should parse");
    let errs = Driver::check(&module).expect_err("returning a mismatched type should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("Int") && d.message.contains("Str")), "{:?}", errs);
}

/// The *implicit* trailing-expression return form (no `return` keyword at
/// all) is checked too -- the exact repro from LANGUAGE_ANALYSIS.md §1.3:
/// `star check` previously passed this cleanly.
#[test]
fn rejects_implicit_trailing_return_type_mismatch() {
    let module = Driver::parse("fn get_val() -> i32:\n    \"not an int\"\n").expect("should parse");
    let errs = Driver::check(&module).expect_err("an implicit trailing return of the wrong type should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("get_val") && d.message.contains("Int") && d.message.contains("Str")), "{:?}", errs);
}

/// A bare `return` (no value) inside a function declared to return a value
/// is a type error -- the other direction of the same hole, and the one
/// that used to reach codegen as a `ret void` inside a non-`void`-declared
/// function (invalid IR).
#[test]
fn rejects_bare_return_in_function_with_declared_return_type() {
    let module = Driver::parse("fn t() -> i32:\n    if true:\n        return\n    return 0\n").expect("should parse");
    let errs = Driver::check(&module).expect_err("a bare return where a value is expected should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("expected a return value")), "{:?}", errs);
}

/// A function whose every `return` (explicit and implicit) matches its
/// declared return type still checks cleanly.
#[test]
fn accepts_return_type_matching_declaration() {
    let module = Driver::parse("fn get_val() -> i32:\n    if true:\n        return 1\n    2\n").expect("should parse");
    assert!(Driver::check(&module).is_ok(), "{:?}", Driver::check(&module).err());
}

/// `return` inside a closure body is not checked against the *enclosing*
/// function's return type (a closure's own return type is inferred from
/// its body, independent of whatever function it's lexically defined in).
/// The outer function here returns a `Fn() -> str` (a closure), while the
/// inner `return` produces a bare `str` -- if closure bodies weren't
/// exempted from the enclosing function's `current_ret_ty`, this would be
/// flagged as a mismatch even though it's perfectly valid.
#[test]
fn accepts_return_inside_closure_regardless_of_enclosing_fn_return_type() {
    let module = Driver::parse("fn t() -> Fn() -> str:\n    fn() -> str:\n        return \"hi\"\n").expect("should parse");
    assert!(Driver::check(&module).is_ok(), "{:?}", Driver::check(&module).err());
}

/// An ordinary function call with mismatched argument types is now a type
/// error -- previously a plain call to a plain function skipped argument
/// count/type validation entirely (only generic calls, struct literals,
/// enum-variant construction, `List` methods, and `spawn` were checked).
#[test]
fn rejects_call_with_mismatched_argument_types() {
    let module = Driver::parse("fn add(a: i32, b: i32) -> i32:\n    a + b\n\nfn t():\n    let x = add(\"foo\", \"bar\")\n").expect("should parse");
    let errs = Driver::check(&module).expect_err("mismatched call argument types should be a type error");
    assert!(errs.iter().filter(|d| d.message.contains("argument") && d.message.contains("Str")).count() == 2, "{:?}", errs);
}

/// An ordinary function call with the wrong argument count is a type error.
#[test]
fn rejects_call_with_wrong_argument_count() {
    let module = Driver::parse("fn add(a: i32, b: i32) -> i32:\n    a + b\n\nfn t():\n    let x = add(1)\n").expect("should parse");
    let errs = Driver::check(&module).expect_err("wrong call argument count should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("expects 2 argument")), "{:?}", errs);
}

/// A method call (`obj.method(args)`) with mismatched argument types is
/// caught the same way as a free-function call -- the `self` receiver
/// (present in the stored signature but never in the call-site argument
/// list) is correctly excluded from the comparison.
#[test]
fn rejects_method_call_with_mismatched_argument_types() {
    let src = r#"struct Counter:
    mut n: i32

impl Counter:
    fn add(mut self, amount: i32):
        self.n += amount

fn t(mut c: Counter):
    c.add("not an int")
"#;
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("mismatched method call argument type should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("argument") && d.message.contains("Str")), "{:?}", errs);
}

/// An ordinary call with matching argument count/types still checks
/// cleanly (both free functions and methods).
#[test]
fn accepts_call_with_matching_argument_types() {
    let src = r#"struct Counter:
    mut n: i32

impl Counter:
    fn add(mut self, amount: i32):
        self.n += amount

fn add_free(a: i32, b: i32) -> i32:
    a + b

fn t(mut c: Counter):
    c.add(5)
    let x = add_free(1, 2)
    print(f"{x}")
"#;
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "{:?}", Driver::check(&module).err());
}

// --- §4.1: `-O2` by default, `--release`/`-O` toggle ------------------------
//
// `opt_flag`'s own precedence/clamping logic is covered directly by unit
// tests in `src/main.rs` (`opt_flag_defaults_to_o2`,
// `opt_flag_honors_explicit_o0`, `opt_flag_release_overrides_opt_level`,
// `opt_flag_clamps_out_of_range_level`), since it's a `main.rs`-private
// binary concern with no library-level surface to exercise here.

// --- §2.1: `&&`/`||`/`and`/`or`/`not` ---------------------------------------

/// Both symbolic (`&&`/`||`) and word (`and`/`or`) spellings parse to the
/// same `BinOp::And`/`BinOp::Or`, and `and` binds tighter than `or`
/// (mirroring Python's own logical-operator precedence).
#[test]
fn parses_and_or_both_spellings_with_correct_precedence() {
    let src = "fn t(a: bool, b: bool, c: bool):\n    a and b or c\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Expr(Expr::Binary { op, lhs, .. }) = &f.body.stmts[0] else { panic!("expected a binary expr") };
    assert_eq!(*op, BinOp::Or, "or should be the outermost (lowest-precedence) operator");
    assert!(matches!(lhs.as_ref(), Expr::Binary { op: BinOp::And, .. }), "and should bind tighter, forming the left operand");

    let src2 = "fn t(a: bool, b: bool):\n    a && b\n";
    let module2 = Driver::parse(src2).expect("should parse");
    let Item::Fn(f2) = &module2.items[0] else { panic!("expected fn") };
    assert!(matches!(&f2.body.stmts[0], Stmt::Expr(Expr::Binary { op: BinOp::And, .. })), "&& should parse to the same BinOp::And as `and`");
}

/// `not`/`!` both parse to the same `UnOp::Not`.
#[test]
fn parses_not_keyword_same_as_bang() {
    let module = Driver::parse("fn t(a: bool):\n    not a\n").expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert!(matches!(&f.body.stmts[0], Stmt::Expr(Expr::Unary { op: UnOp::Not, .. })));
}

/// `&&`/`||` require both operands to be `bool`.
#[test]
fn rejects_logical_and_with_non_bool_operand() {
    let module = Driver::parse("fn t(a: i32):\n    a and true\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "a non-bool operand to `and` should be a type error");
}

/// Codegen for `&&`/`||` short-circuits via branches (skipping the
/// right-hand side entirely when the left already determines the result)
/// rather than always evaluating both operands eagerly.
#[test]
fn codegen_logical_and_short_circuits_via_branch() {
    let module = Driver::parse("fn t(a: bool, b: bool) -> bool:\n    a and b\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("br i1"), "should branch on the left operand rather than unconditionally evaluating both: {}", ir);
    assert!(ir.contains("phi i1"), "should merge the short-circuit and evaluated-rhs paths: {}", ir);
}

/// Runtime test: both operator spellings, `not`, and short-circuit
/// evaluation (the right-hand side's side effect must never run when the
/// left-hand side already determines the result), end to end through a
/// real compiled binary.
#[test]
fn runtime_logic_ops_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/logic_ops.exe").output().expect("failed to execute logic_ops.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("not both positive"), "{}", stdout);
    assert!(stdout.contains("at least one positive"), "{}", stdout);
    assert!(stdout.contains("negated and works"), "{}", stdout);
    assert!(stdout.contains("symbolic && works"), "{}", stdout);
    assert!(stdout.contains("symbolic || works"), "{}", stdout);
    assert!(stdout.contains("false-and short-circuited"), "{}", stdout);
    assert!(stdout.contains("true-or short-circuited"), "{}", stdout);
    assert!(!stdout.contains("called: and-rhs"), "short-circuited `and` must never evaluate its rhs: {}", stdout);
    assert!(!stdout.contains("called: or-rhs"), "short-circuited `or` must never evaluate its rhs: {}", stdout);
    assert_eq!(output.status.code(), Some(0));
}

// --- §4.6, §5: `dot`/`length`/`lerp`/`clamp`/RNG builtins ------------------

/// `dot`/`length` type as `f32`; `lerp`/`clamp` preserve their first
/// argument's type.
#[test]
fn checks_math_builtin_return_types() {
    assert_eq!(typed_fn_result_ty("fn t(a: Vec3, b: Vec3) -> f32:\n    dot(a, b)\n"), Ty::Float);
    assert_eq!(typed_fn_result_ty("fn t(a: Vec3) -> f32:\n    length(a)\n"), Ty::Float);
    assert_eq!(typed_fn_result_ty("fn t(a: f32, b: f32, t: f32) -> f32:\n    lerp(a, b, t)\n"), Ty::Float);
    assert_eq!(typed_fn_result_ty("fn t(a: Vec3, b: Vec3, k: f32) -> Vec3:\n    lerp(a, b, k)\n"), Ty::Vec3);
    assert_eq!(typed_fn_result_ty("fn t(x: i32) -> i32:\n    clamp(x, 0, 10)\n"), Ty::Int);
    assert_eq!(typed_fn_result_ty("fn t() -> f32:\n    rand()\n"), Ty::Float);
    assert_eq!(typed_fn_result_ty("fn t() -> i32:\n    rand_range(0, 10)\n"), Ty::Int);
}

/// Runtime test: `dot`, `length`, `lerp` (both float and `Vec3` forms),
/// `clamp` (both `i32` and `f32` forms), and a seeded, reproducible
/// `rand`/`rand_range`, end to end through a real compiled binary.
#[test]
fn runtime_math_builtins_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/math_builtins.exe").output().expect("failed to execute math_builtins.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("dot: 0.000000"), "perpendicular unit vectors: {}", stdout);
    assert!(stdout.contains("length: 5.000000"), "3-4-5 triangle: {}", stdout);
    assert!(stdout.contains("lerp float: 5.000000"), "{}", stdout);
    assert!(stdout.contains("lerp vec: 2.000000 2.000000 0.000000"), "{}", stdout);
    assert!(stdout.contains("clamp int: 10"), "clamp above the range: {}", stdout);
    assert!(stdout.contains("clamp float: 0.000000"), "clamp below the range: {}", stdout);
    assert!(stdout.contains("rand in [0,1): true true"), "{}", stdout);
    assert!(stdout.contains("rand_range in bounds: true"), "{}", stdout);
    assert!(stdout.contains("reseeding reproduces the same sequence: true"), "rand_seed should be deterministic: {}", stdout);
    assert_eq!(output.status.code(), Some(0));
}

// --- §3.7: early `return` inside `sequence` bodies --------------------------

/// A `sequence` containing an early `return` before its next `yield` now
/// compiles (previously produced invalid LLVM IR -- `ret void` inside the
/// synthesized `bool`-returning `resume` -- caught only by the backend with
/// no Star diagnostic).
#[test]
fn checks_sequence_with_early_return_compiles() {
    let src = "sequence S(n: i32):\n    if n < 0:\n        return\n    yield\n    n -= 1\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "{:?}", Driver::check(&module).err());
}

/// Codegen for a bare `return` inside a `sequence` body rewrites it to
/// `return false` (the same "fully done" value the sequence's own final
/// segment already returns on normal completion), producing a valid `ret
/// i1 false` rather than an invalid `ret void`.
#[test]
fn codegen_sequence_early_return_becomes_ret_false() {
    let src = "sequence S(n: i32):\n    if n < 0:\n        return\n    yield\n    n -= 1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let resume_ir = extract_fn_body(&ir, "define i1 @S__resume(");
    assert!(resume_ir.contains("ret i1 false"), "early return should lower to ret i1 false: {}", resume_ir);
    assert!(!resume_ir.contains("ret void"), "resume() must never contain a ret void: {}", resume_ir);
}

/// Runtime test: a `sequence` that ticks normally to completion, and a
/// second instance that aborts immediately via an early `return` before its
/// first `yield` (reporting `resume() == false`, matching normal
/// completion's own "done" signal), end to end through a real compiled
/// binary.
#[test]
fn runtime_sequence_early_return_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/sequence_early_return.exe").output().expect("failed to execute sequence_early_return.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("ticks: 3"), "normal countdown should tick 3 times: {}", stdout);
    assert!(stdout.contains("early return reports done: false"), "an aborted sequence should report done: {}", stdout);
    assert_eq!(output.status.code(), Some(0));
}

// --- §3.6: reference-counted `Str`/`Closure` heap values ---------------------
//
// `concat` and a closure literal's captured environment used to `malloc` and
// never `free`, leaking unboundedly (every call/every closure creation grew
// the process's heap forever). Both now allocate through a shared
// `star_rc_alloc`/`star_rc_retain`/`star_rc_release` runtime (see
// `Codegen::emit_rc_runtime` in `src/codegen/mod.rs`), with retain/release
// calls threaded through variable reads, scope exits, reassignment, structs,
// lists, closures, and arena spawn/despawn (`src/codegen/rc.rs`).

/// `concat`'s buffer is allocated through `star_rc_alloc` (which frees it once
/// the last reference is released), not directly through `@malloc`.
#[test]
fn codegen_concat_uses_rc_alloc_not_raw_malloc() {
    let src = "fn t(a: str, b: str) -> str:\n    concat(a, b)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i8* @t(");
    assert!(fn_ir.contains("call i8* @star_rc_alloc"), "concat should allocate via star_rc_alloc: {}", fn_ir);
    assert!(!fn_ir.contains("call i8* @malloc"), "concat should not call @malloc directly: {}", fn_ir);
}

/// `read_line`'s line buffer is allocated through `star_rc_alloc` (freed once
/// the last reference is released), not directly through `@malloc`, and reads
/// characters one at a time via `@getchar` rather than assuming a `stdin`
/// `FILE*` symbol is resolvable (its representation varies across CRT
/// versions on Windows).
#[test]
fn codegen_read_line_uses_rc_alloc_and_getchar() {
    let src = "fn t() -> str:\n    read_line()\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i8* @t(");
    assert!(fn_ir.contains("call i8* @star_rc_alloc"), "read_line should allocate via star_rc_alloc: {}", fn_ir);
    assert!(!fn_ir.contains("call i8* @malloc"), "read_line should not call @malloc directly: {}", fn_ir);
    assert!(fn_ir.contains("call i32 @getchar()"), "read_line should read via @getchar: {}", fn_ir);
}

/// A closure literal that captures an outer local allocates its environment
/// through `star_rc_alloc`, not directly through `@malloc`.
#[test]
fn codegen_closure_capturing_local_uses_rc_alloc() {
    let src = "fn t() -> i32:\n    let base = 10\n    let f = fn(x: i32) -> i32: x + base\n    f(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    assert!(fn_ir.contains("call i8* @star_rc_alloc"), "closure env should allocate via star_rc_alloc: {}", fn_ir);
    assert!(!fn_ir.contains("call i8* @malloc"), "closure env should not call @malloc directly: {}", fn_ir);
}

/// A `let`-bound `str` local that's never returned is released before the
/// function's own implicit-fallthrough `ret`, closing the leak for the
/// common case (a `concat` result that goes out of scope normally).
#[test]
fn codegen_unused_let_bound_str_is_released_before_fn_exit() {
    let src = "fn t(a: str, b: str) -> i32:\n    let s = concat(a, b)\n    1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    let release_pos = fn_ir.find("call void @star_rc_release").expect("should release the unused local");
    let ret_pos = fn_ir.find("ret i32 1").expect("should return 1");
    assert!(release_pos < ret_pos, "release must happen before the fallthrough ret: {}", fn_ir);
}

/// Reassigning a `mut str` local releases the old value before storing the
/// new one (rather than only ever releasing at scope exit, which would leak
/// every value a variable held before its *last* assignment).
#[test]
fn codegen_str_reassignment_releases_old_value_before_store() {
    let src = "fn t() -> str:\n    let mut s = concat(\"a\", \"b\")\n    s = concat(\"c\", \"d\")\n    s\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i8* @t(");
    // The new value is computed first (the second concat's own
    // `star_rc_alloc`), then the reassignment releases `s`'s old value,
    // then stores the new one -- a release immediately followed by a
    // `store` is exactly that release-before-overwrite sequencing, and
    // register numbers aren't stable across incidental codegen changes so
    // this checks the *shape* rather than exact register names.
    let lines: Vec<&str> = fn_ir.lines().map(|l| l.trim()).collect();
    let release_then_store = lines.windows(2).any(|w| w[0].contains("call void @star_rc_release") && w[1].starts_with("store i8*"));
    assert!(release_then_store, "a release must immediately precede the reassignment's store: {}", fn_ir);
    assert_eq!(fn_ir.matches("call i8* @star_rc_alloc").count(), 2, "both concat calls should allocate: {}", fn_ir);
}

/// An explicit `return` from inside a nested `if` still releases an
/// RC-owning local declared in an *outer* scope (the function root), not
/// just the immediately-enclosing block.
#[test]
fn codegen_early_return_releases_outer_scope_str_local() {
    let src = "fn t(cond: bool) -> i32:\n    let s = concat(\"a\", \"b\")\n    if cond:\n        return 1\n    0\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    let ret1_pos = fn_ir.find("ret i32 1").expect("should have the early return");
    let release_before_ret1 = fn_ir[..ret1_pos].contains("call void @star_rc_release");
    assert!(release_before_ret1, "the early return must release `s`, declared in the outer (function-root) scope: {}", fn_ir);
}

/// `break` only releases the scopes opened *since* the loop was entered --
/// an RC-owning local declared before the loop must still be alive (and
/// therefore only released once, at the function's own scope exit), not
/// released a second time by every `break` inside the loop.
#[test]
fn codegen_break_does_not_release_outer_scope_str_local() {
    let src = "fn t() -> i32:\n    let s = concat(\"a\", \"b\")\n    let mut i = 0\n    while i < 10:\n        if i == 5:\n            break\n        i += 1\n    1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    // Three releases total: `concat`'s own two internal `emit_raw_str_ptr`
    // extractions of its literal `"a"`/`"b"` arguments (harmless no-ops at
    // runtime -- a literal's global constant carries the immortal `-1`
    // sentinel `star_rc_release` checks for, see `rc.rs`'s module doc
    // comment -- but still emitted unconditionally now, unlike before that
    // fix), plus exactly one release of `s` itself at the function's own
    // fallthrough exit. If `break` also released `s`, this would be 4 (or
    // more, once per loop iteration's worth of `break` sites).
    assert_eq!(fn_ir.matches("call void @star_rc_release").count(), 3, "`s` should be released exactly once, at function exit, not by `break`: {}", fn_ir);
}

/// Copying a struct that has a `str` field (`let p2 = p1`) retains the
/// nested field -- both `p1` and `p2` now alias the same backing buffer,
/// and releasing one must not invalidate the other's reference.
#[test]
fn codegen_struct_copy_retains_nested_str_field() {
    let src = "struct P:\n    name: str\n\nfn t(p1: P) -> i32:\n    let p2 = p1\n    1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    assert!(fn_ir.contains("call void @star_rc_retain"), "copying a struct with a str field should retain that field: {}", fn_ir);
}

/// A `List<str>` local's release is a single `star_rc_release` call on the
/// list's object pointer (O(1) regardless of length, like `Ty::Str`) --
/// element release only happens once, inside the generated
/// `list_release_str` thunk (`Codegen::list_release_thunk_operand`), which
/// walks the elements via a runtime loop (element count isn't known at
/// compile time), not a fixed unrolled sequence of releases.
#[test]
fn codegen_list_of_str_release_uses_runtime_loop() {
    // `make` actually allocates a `List<str>` (a literal), which is what
    // triggers the `list_release_str` thunk to be generated at all; `t`
    // merely accepts one as a parameter and drops it, to check the release
    // call site itself stays O(1).
    let src = "fn make() -> List<str>:\n    [\"a\", \"b\"]\n\nfn t(words: List<str>) -> i32:\n    1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    assert!(!fn_ir.contains("rc_walk_cond"), "the call site itself should not inline an element loop: {}", fn_ir);
    assert!(fn_ir.contains("call void @star_rc_release"), "{}", fn_ir);

    let thunk_ir = extract_fn_body(&ir, "define void @list_release_str(");
    assert!(thunk_ir.contains("list_release_cond"), "the release thunk should walk elements via a runtime loop: {}", thunk_ir);
    assert!(thunk_ir.contains("call void @star_rc_release"), "each str element should itself be released: {}", thunk_ir);
    assert!(thunk_ir.contains("call void @free"), "the thunk should free the list's own data buffer: {}", thunk_ir);
}

/// A closure that captures a `str` local by value gets its own dedicated
/// `_release_env` thunk (passed to `star_rc_alloc` as the environment
/// block's nested-cleanup callback), so that captured string is actually
/// freed once the closure itself is released -- otherwise it would leak
/// forever even after fixing the top-level environment block's own leak.
#[test]
fn codegen_closure_capturing_str_emits_release_env_thunk() {
    let src = "fn t(name: str) -> str:\n    let f = fn() -> str: name\n    f()\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("_release_env"), "a closure capturing a str should emit its own release-env thunk: {}", ir);
    let thunk_ir = extract_fn_body(&ir, "define void @closure_0_release_env(");
    assert!(thunk_ir.contains("call void @star_rc_release"), "{}", thunk_ir);
}

/// A closure capturing only non-RC locals (e.g. `i32`) passes `null` as its
/// nested-cleanup callback -- no `_release_env` thunk is generated at all.
#[test]
fn codegen_closure_capturing_non_rc_local_has_no_release_env_thunk() {
    let src = "fn t() -> i32:\n    let base = 10\n    let f = fn(x: i32) -> i32: x + base\n    f(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(!ir.contains("_release_env"), "a capture-free-of-RC-content closure needs no release-env thunk: {}", ir);
}

/// `despawn`ing an arena slot whose element struct has a `str` field
/// releases that field, so a spawn/despawn cycle doesn't leak the spawned
/// element's string content.
#[test]
fn codegen_despawn_releases_arena_slot_str_field() {
    let src = "struct Entity:\n    name: str\n\narena Entities: Entity\n\nfn t(idx: i32):\n    despawn Entities[idx]\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define void @t(");
    assert!(fn_ir.contains("call void @star_rc_release"), "despawn should release the slot's str field: {}", fn_ir);
}

/// Regression test for a bug caught while implementing §3.6: `self` is
/// passed *by pointer* (a borrow of the caller's own struct -- see
/// `Codegen::captured_value_llvm_ty`'s doc comment), not an owned copy, so
/// a method on a struct with a `str` field must never release `self` at its
/// own scope exit -- doing so corrupted memory (retaining/releasing the
/// caller's raw struct pointer as if it were a `star_rc_alloc`'d block).
#[test]
fn codegen_method_self_param_is_not_released_at_scope_exit() {
    let src = "struct P:\n    name: str\n\nimpl P:\n    fn greet(self) -> i32:\n        42\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @P__greet(");
    assert!(!fn_ir.contains("star_rc_release"), "a method must never release its own `self` pointer: {}", fn_ir);
}

/// A string literal's backing global constant is wrapped in the same
/// 16-byte `[i64 refcount][i8* release_fn]` header every `star_rc_alloc`
/// allocation gets, with the refcount set to the reserved `-1` "immortal"
/// sentinel `star_rc_retain`/`release` skip -- a literal is a permanent
/// global, not a heap block, and must never actually be freed even though
/// it flows through the same retain/release paths a heap-allocated `str`
/// does (e.g. when copied into a struct field or `let`-bound variable).
#[test]
fn codegen_string_literal_uses_immortal_rc_header() {
    let src = "fn t() -> str:\n    \"hi\"\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("{ i64, i8*, ["), "a string literal's global should carry the RC header shape: {}", ir);
    assert!(ir.contains("{ i64 -1, i8* null,"), "a string literal's refcount should be the immortal sentinel: {}", ir);
}

/// Runtime test: `examples/rc_strings.exe` exercises `concat`, reassignment,
/// struct fields, list elements, and passing a `str` into a function all
/// together, end to end through a real compiled binary. The regression risk
/// this guards against is retain/release firing at the wrong point and
/// corrupting/truncating/use-after-freeing a string still in use -- every
/// value below must still print exactly right despite the reference
/// counting inserted around it.
#[test]
fn runtime_rc_strings_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/rc_strings.exe").output().expect("failed to execute rc_strings.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("foobar"), "{}", stdout);
    assert!(stdout.contains("foobarbaz"), "{}", stdout);
    assert!(stdout.contains("hello world"), "struct field and its copy should both print correctly: {}", stdout);
    assert!(stdout.contains("alpha-1"), "{}", stdout);
    assert!(stdout.contains("beta-2"), "{}", stdout);
    assert!(stdout.contains("gamma-3"), "list literal + pushed element should all survive: {}", stdout);
    assert!(stdout.contains("words len = 3"), "{}", stdout);
    assert!(stdout.contains("shout_len(go) = 5"), "a str passed into a function and used there should still be valid: {}", stdout);
    assert!(stdout.contains("start-x-x-x-x-x"), "repeated reassignment should never corrupt the accumulator: {}", stdout);
    assert_eq!(output.status.code(), Some(0));
}

/// A function returning a freshly-constructed `str` (a bare literal or a
/// `concat` result) no longer boxes it in a per-call stack `alloca` --
/// previously this dangled the instant the function returned. With the box
/// removed, the returned value is just the raw `i8*` pointer computed
/// in-function (a GEP into an immortal global, or a `star_rc_alloc`'d
/// buffer), neither of which depend on this function's own stack frame.
#[test]
fn codegen_fn_returning_fresh_str_does_not_box_on_stack() {
    let src = "fn lit() -> str:\n    \"hi\"\n\nfn built(a: str, b: str) -> str:\n    concat(a, b)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let lit_ir = extract_fn_body(&ir, "define i8* @lit(");
    assert!(!lit_ir.contains("alloca"), "a fresh string literal (no params to box either) must not allocate anything: {}", lit_ir);
    // `built`'s two `str` parameters each still get their own ordinary
    // parameter-storage alloca (unrelated to the bug) -- exactly 2, not 3,
    // confirms no *extra* box alloca wraps the concat result being returned.
    let built_ir = extract_fn_body(&ir, "define i8* @built(");
    assert_eq!(built_ir.matches("alloca").count(), 2, "only the 2 parameter allocas should remain, no extra box alloca for the returned concat result: {}", built_ir);
}

/// Runtime test: `examples/str_fixes.exe` exercises a function returning a
/// freshly-constructed `str` (both a bare literal and a `concat` result),
/// printed from the caller -- the direct empirical proof the returned
/// pointer isn't dangling, since a dangling read would print garbage or
/// crash rather than the exact expected text.
#[test]
fn runtime_str_return_fresh_value_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/str_fixes.exe").output().expect("failed to execute str_fixes.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("fresh literal return"), "a function returning a bare literal must not dangle: {}", stdout);
    assert!(stdout.contains("fresh concat return"), "a function returning a concat result must not dangle: {}", stdout);
    assert_eq!(output.status.code(), Some(0));
}

/// `s[i]` (`TypedExpr::StrIndex`, added alongside `chr`/`ord` while writing
/// examples/brainfuck.star -- see that file's own doc comment): a
/// bounds-checked byte read yielding an `i32` (0-255), not a Python-style
/// length-1 substring. Covers the in-bounds case, an out-of-range index, and
/// a negative index -- the latter two must read as `0` (mirroring
/// `List<T>`'s zero-value OOB-read convention) rather than crashing.
#[test]
fn runtime_str_index_reads_byte_end_to_end() {
    let src = "fn main():\n    let s = \"Hi\"\n    println(f\"{s[0]}\")\n    println(f\"{s[1]}\")\n    println(f\"{s[50]}\")\n    println(f\"{s[-1]}\")\n";
    let output = compile_and_run("str_index_reads_byte", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["72", "105", "0", "0"], "{}", stdout);
}

/// `chr(i32) -> str` / `ord(str) -> i32`, the byte<->string conversions that
/// complement `s[i]`. Covers the round trip through `s[i]`, `ord` on an empty
/// string (must read `0`, not crash on a zero-length buffer), and `chr`
/// truncating an out-of-`u8`-range input rather than erroring (`chr(321)` ==
/// `chr(65)`, mirroring `tape[ptr]`'s own wraparound in the Brainfuck
/// interpreter this was written for).
#[test]
fn runtime_chr_ord_round_trip_end_to_end() {
    let src = "fn main():\n    println(chr(72))\n    let a = \"A\"\n    println(f\"{ord(a)}\")\n    let empty = \"\"\n    println(f\"{ord(empty)}\")\n    println(chr(321))\n    let s = \"Hi\"\n    let mut rebuilt = \"\"\n    let mut i: i32 = 0\n    while i < len(s):\n        rebuilt = concat(rebuilt, chr(s[i]))\n        i += 1\n    println(rebuilt)\n";
    let output = compile_and_run("chr_ord_round_trip", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["H", "65", "0", "A", "Hi"], "{}", stdout);
}

/// `str` has no mutating methods -- `s[i] = ...` must be rejected at
/// type-check time rather than silently compiling into a no-op (`Codegen::
/// emit_place`'s generic fallback would otherwise spill the assigned value
/// into a dead alloca with no error at all).
#[test]
fn rejects_assignment_into_str_index() {
    let src = "fn main():\n    let s = \"Hi\"\n    s[0] = 65\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("assigning into a str index should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("cannot assign into a `str` index")), "{:?}", errs);
}

/// `println`/`print` with a non-f-string argument that isn't a plain
/// `Ident`/`Field` (here, a `List` index) must not double-tag the value --
/// previously `emit_print_like`'s bare-argument branch used `emit_expr`'s
/// result directly as an untagged register, producing malformed IR like
/// `load i8*, i8** i8* %reg` for a `ListIndex`/closure-call result (both of
/// which return a tagged register), which clang rejects.
#[test]
fn codegen_println_of_list_index_does_not_double_tag() {
    let src = "fn t(words: List<str>):\n    println(words[0])\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define void @t(");
    assert!(!fn_ir.contains("i8** i8*"), "the ListIndex result must be untagged before use, not double-tagged: {}", fn_ir);
}

/// Runtime test: `examples/str_fixes.exe` also prints a `List<str>` index
/// and a closure-call result directly through `println` (not routed through
/// an f-string interpolation, which every pre-existing example used to
/// route around this exact bug) -- confirming the fix compiles *and* runs.
#[test]
fn runtime_println_of_list_index_and_closure_call_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/str_fixes.exe").output().expect("failed to execute str_fixes.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("beta"), "println(list[i]) directly (no f-string) must print correctly: {}", stdout);
    assert!(stdout.contains("hello from a closure call"), "println(closure()) directly (no f-string) must print correctly: {}", stdout);
    assert_eq!(output.status.code(), Some(0));
}

/// Runtime test: `examples/rc_closures.exe` exercises a closure capturing a
/// `str` by value and escaping its defining function, stored in a struct
/// field and in a `List`, called long after the local binding that created
/// it went out of scope, plus a closure capturing another closure. The
/// regression risk this guards against: a captured value released too
/// early would read corrupted/freed memory when the closure is finally
/// called; never releasing it is the leak todo.md flags in the first place.
#[test]
fn runtime_rc_closures_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/rc_closures.exe").output().expect("failed to execute rc_closures.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Alice"), "a closure capturing a str param, called after its own function returned: {}", stdout);
    assert!(stdout.contains("Bob"), "same, called through a struct field: {}", stdout);
    assert!(stdout.contains("Carol"), "{}", stdout);
    assert!(stdout.contains("Dave"), "closures stored in a List and called by index: {}", stdout);
    assert!(stdout.contains("apply_add5(10) = 15"), "a closure capturing another closure: {}", stdout);
    assert!(stdout.contains("tick 0: Alice"), "{}", stdout);
    assert!(stdout.contains("tick 1: Alice"), "{}", stdout);
    assert!(stdout.contains("tick 2: Alice"), "calling the same escaped closure repeatedly should keep working: {}", stdout);
    assert_eq!(output.status.code(), Some(0));
}

/// A closure capturing another RC-bearing closure (`Ty::Closure` is itself
/// `contains_rc`) and then actually *called* -- as opposed to merely
/// constructed and released unused -- must not corrupt the heap.
///
/// Root cause (found via a real Windows `STATUS_HEAP_CORRUPTION`
/// (`0xC0000374`) crash reproduced from `examples/closures.star`, confirmed
/// gone once fixed): `Codegen::emit_closure_lit`'s body-reconstruction loop
/// `track_owned`'d every captured variable *except* `self`, so a captured
/// RC-bearing value (a `str`, or -- as here -- another closure) was treated
/// as a fresh owned local that `pop_scope` released at the end of *every
/// call* to the closure. But the environment holds exactly one retained
/// reference per RC-bearing capture, taken once at construction and meant to
/// be released exactly once (via the generated `..._release_env` thunk) when
/// the environment's own refcount reaches zero -- not once per call. Calling
/// a closure that captured another closure even a single time over-released
/// that captured closure's environment by one, so it hit zero and was freed
/// while its original binding (or another closure that also captured it)
/// still held a live reference to it, corrupting the heap the moment that
/// other owner was later released in turn. This didn't corrupt *stdout* --
/// the printed output was entirely correct -- only the process's exit
/// status, which is exactly why this needs an explicit `status.success()`
/// check rather than only asserting on `stdout` (the pre-existing
/// `runtime_rc_closures_end_to_end` test above already does check exit
/// status, but its specific call pattern happened not to trip this bug).
#[test]
fn runtime_closure_capturing_another_closure_called_once_does_not_corrupt_heap_end_to_end() {
    let src = "fn make_adder(n: i32) -> Fn(i32) -> i32:\n    fn(x: i32) -> i32: x + n\nfn main():\n    let adder = make_adder(100)\n    let bump = fn() -> i32: adder(1)\n    println(f\"{bump()}\")\n";
    let output = compile_and_run("closure_capturing_closure_called_once", src);
    assert!(output.status.success(), "heap corruption / abnormal exit: {:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "101", "{}", stdout);
}

/// Same fix, exercised via the exact multi-closure shape (`add1`/`adder`/
/// `bump`/`say_hi`) that was first found to crash in `examples/closures.star`
/// -- a closure (`say_hi`) capturing several prior locals including two
/// other RC-bearing closures (`adder`, `bump`), with every closure actually
/// called at least once before the whole set is released at scope exit.
#[test]
fn runtime_multiple_closures_capturing_each_other_called_then_released_end_to_end() {
    let src = "fn make_adder(n: i32) -> Fn(i32) -> i32:\n    fn(x: i32) -> i32: x + n\nfn main():\n    let add1 = fn(x: i32) -> i32: x + 1\n    println(f\"{add1(5)}\")\n    let adder = make_adder(100)\n    println(f\"{adder(5)}\")\n    let mut counter = 0\n    let bump = fn() -> i32: counter + 1\n    counter = 50\n    println(f\"{bump()}\")\n    let say_hi = fn(): println(\"hi\")\n    say_hi()\n";
    let output = compile_and_run("multiple_closures_capturing_each_other", src);
    assert!(output.status.success(), "heap corruption / abnormal exit: {:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["6", "105", "1", "hi"], "{}", stdout);
}

/// Runtime test: `examples/rc_stress.exe` runs 10,000,000 iterations, each
/// creating a fresh `concat` result and a closure capturing it that
/// immediately go out of scope -- before the fix, every single iteration
/// permanently leaked both allocations. This is the direct empirical proof
/// the "unbounded" leak todo.md describes is now bounded: while the process
/// runs, its Working Set is sampled every ~120ms via a single PowerShell
/// `Get-Process` polling loop (one PowerShell startup, not one per sample --
/// that alone would dominate the sampling interval), and the samples must
/// stay flat across the run rather than growing with iteration count.
#[test]
fn runtime_rc_stress_memory_stays_bounded() {
    use std::process::Command;

    let exe = std::env::current_dir().unwrap().join("examples/rc_stress.exe");
    let stdout_file = std::env::temp_dir().join("rc_stress_stdout.txt");
    let script = format!(
        "$p = Start-Process -FilePath '{}' -PassThru -RedirectStandardOutput '{}'; \
         $samples = New-Object System.Collections.ArrayList; \
         while (-not $p.HasExited) {{ try {{ $p.Refresh(); [void]$samples.Add($p.WorkingSet64) }} catch {{}}; Start-Sleep -Milliseconds 120 }}; \
         $samples -join ','",
        exe.display(),
        stdout_file.display()
    );
    let output = Command::new("powershell")
        .args(["-NoProfile", "-NonInteractive", "-Command", &script])
        .output()
        .expect("failed to run the PowerShell memory-sampling script");
    assert!(output.status.success(), "sampling script failed: {}", String::from_utf8_lossy(&output.stderr));

    let program_stdout = std::fs::read_to_string(&stdout_file).unwrap_or_default();
    assert!(program_stdout.contains("done, total ="), "rc_stress.exe should finish normally: {}", program_stdout);

    let samples_raw = String::from_utf8_lossy(&output.stdout);
    let samples: Vec<i64> = samples_raw.trim().split(',').filter_map(|s| s.trim().parse().ok()).collect();
    assert!(samples.len() >= 3, "expected several Working Set samples over the run, got {}: {:?}", samples.len(), samples_raw);

    // Skip the first sample (process/DLL-load startup transient) and compare
    // the rest: an unbounded leak growing by ~70 bytes/iteration over
    // 10,000,000 iterations would add hundreds of megabytes over the run,
    // dwarfing any legitimate one-time startup cost -- a bounded run stays
    // within a small, flat band throughout.
    let settled = &samples[1..];
    let min = *settled.iter().min().unwrap();
    let max = *settled.iter().max().unwrap();
    const CAP_BYTES: i64 = 50 * 1024 * 1024;
    assert!(max < CAP_BYTES, "Working Set exceeded the 50MB bound (samples: {:?}) -- looks like a real leak", samples);
    assert!(
        (max - min) < 20 * 1024 * 1024,
        "Working Set grew by {}MB across the run (samples: {:?}) -- looks like a leak, not noise",
        (max - min) / (1024 * 1024),
        samples
    );

    let _ = std::fs::remove_file(&stdout_file);
}

/// Regression test for the RC leak fixed in `Codegen::emit_stmt`'s
/// `TypedStmt::Expr` arm: a bare-statement expression whose value is a
/// fresh, already-owned RC reference (`List<str>::pop()`, here) was never
/// released, since nothing else held onto it -- every `.pop()`-and-discard
/// leaked one heap block. Mirrors `runtime_rc_stress_memory_stays_bounded`'s
/// Working-Set-sampling technique just above, but builds its own throwaway
/// executable (1,000,000,000 push-then-discarded-pop iterations) instead of
/// relying on a checked-in example.
#[test]
fn runtime_discarded_list_pop_statement_does_not_leak_end_to_end() {
    use std::process::Command;

    let src = "fn main():\n    let mut xs: List<str> = List<str>()\n    xs.push(\"seed\")\n    let mut i: i32 = 0\n    while i < 1000000000:\n        xs.push(\"x\")\n        xs.pop()\n        i += 1\n    println(\"done\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_discarded_pop_leak.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");

    let stdout_file = std::env::temp_dir().join("discarded_pop_leak_stdout.txt");
    let script = format!(
        "$p = Start-Process -FilePath '{}' -PassThru -RedirectStandardOutput '{}'; \
         $samples = New-Object System.Collections.ArrayList; \
         while (-not $p.HasExited) {{ try {{ $p.Refresh(); [void]$samples.Add($p.WorkingSet64) }} catch {{}}; Start-Sleep -Milliseconds 100 }}; \
         $samples -join ','",
        exe.display(),
        stdout_file.display()
    );
    let output = Command::new("powershell")
        .args(["-NoProfile", "-NonInteractive", "-Command", &script])
        .output()
        .expect("failed to run the PowerShell memory-sampling script");
    assert!(output.status.success(), "sampling script failed: {}", String::from_utf8_lossy(&output.stderr));

    let program_stdout = std::fs::read_to_string(&stdout_file).unwrap_or_default();
    assert!(program_stdout.contains("done"), "program should finish normally: {}", program_stdout);

    let samples_raw = String::from_utf8_lossy(&output.stdout);
    let samples: Vec<i64> = samples_raw.trim().split(',').filter_map(|s| s.trim().parse().ok()).collect();

    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
    let _ = std::fs::remove_file(&stdout_file);

    if samples.len() < 3 {
        // Ran too fast to sample meaningfully on this machine -- a
        // successful, fast exit over 1,000,000,000 iterations is itself
        // still strong evidence against an unbounded per-iteration leak.
        return;
    }
    let settled = &samples[1..];
    let min = *settled.iter().min().unwrap();
    let max = *settled.iter().max().unwrap();
    assert!(
        (max - min) < 20 * 1024 * 1024,
        "Working Set grew by {}MB across the run (samples: {:?}) -- a discarded `list.pop()` statement is leaking",
        (max - min) / (1024 * 1024),
        samples
    );
}

// ===== Regression: this codegen emits every local's/temporary's `alloca`
// ===== inline, wherever it's first needed (not hoisted to the function's
// ===== own entry block the way a typical C frontend like Clang always
// ===== does). An `alloca` inside a loop body is not free of runtime cost
// ===== the way a fixed-size stack slot declared once at entry is: at `-O0`
// ===== (which this whole test suite always builds at, via `compile_and_run`),
// ===== each pass through that loop iteration's block consumed *more* stack
// ===== space, so a long-running loop containing so much as one `let`/
// ===== temporary eventually overflowed the stack -- confirmed via a real
// ===== `STATUS_STACK_OVERFLOW` after ~100,000 iterations of a trivial `let
// ===== s: str = concat("a", "b")` inside a `while` loop, discovered on a
// ===== clean checkout with none of this round's other fixes applied (a
// ===== pre-existing bug, not introduced by them) while writing a stress
// ===== test for the `TypedStmt::Expr` RC-release fix above. Fixed by
// ===== `Codegen::hoist_allocas_to_entry`, a per-function textual pass that
// ===== moves every `alloca` line to immediately follow its `entry:` label. ==

/// Every `alloca` in a function containing a `while` loop must appear
/// *before* the loop's own block label in the emitted IR -- confirms
/// `hoist_allocas_to_entry` actually moved the loop-body `let`'s `alloca`
/// out of the repeatedly-executed block, rather than merely masking the
/// problem some other way.
#[test]
fn codegen_hoists_loop_local_allocas_to_entry_block() {
    let src = "fn main():\n    let mut i: i32 = 0\n    while i < 3:\n        let s: str = concat(\"a\", \"b\")\n        i += 1\n    println(\"done\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let body = extract_fn_body(&ir, "define i32 @main(");
    let loop_start = body.find("while_cond").expect("function should contain a while-loop block");
    let after_loop_starts = &body[loop_start..];
    assert!(
        !after_loop_starts.contains("= alloca"),
        "found an `alloca` at or after the loop's own block -- it wasn't hoisted to entry: {}",
        body
    );
}

/// Full runtime round trip: 200,000 iterations of a `while` loop each
/// containing a `let` (comfortably above the ~100,000-iteration threshold
/// that reproduced the stack overflow pre-fix, while staying fast enough to
/// run as an ordinary, non-memory-sampling test) must complete normally.
#[test]
fn runtime_loop_with_many_local_lets_does_not_overflow_stack_end_to_end() {
    let src = "fn main():\n    let mut i: i32 = 0\n    while i < 200000:\n        let s: str = concat(\"a\", \"b\")\n        i += 1\n    println(\"done\")\n";
    let output = compile_and_run("loop_with_many_local_lets", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "done", "{}", stdout);
}
