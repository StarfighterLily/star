//! M7: `system`/`parallel` ECS blocks
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// --- `system` / `parallel` (cross-system compile-time locks) -------------

/// Parse `system Name(mut ArenaA, ArenaB): <body>`.
#[test]
fn parses_system_decl() {
    let src = format!("{}system A(Enemies):\n    each e in Enemies:\n        print(f\"{{e.hp}}\")\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let Item::System(s) = module.items.last().expect("expected an item") else { panic!("expected system") };
    assert_eq!(s.name, "A");
    assert_eq!(s.accesses.len(), 1);
    assert_eq!(s.accesses[0].arena, "Enemies");
    assert!(!s.accesses[0].mutable, "bare `Enemies` should be read-only");
}

/// `mut ArenaName` in a system's access list is parsed as a mutable access.
#[test]
fn parses_system_decl_with_mut_arena() {
    let src = format!("{}system A(mut Enemies):\n    par e in Enemies:\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let Item::System(s) = module.items.last().expect("expected an item") else { panic!("expected system") };
    assert_eq!(s.accesses.len(), 1);
    assert!(s.accesses[0].mutable);
}

/// A system may declare a mix of `mut`/read-only accesses across several
/// arenas, comma-separated like a parameter list.
#[test]
fn parses_system_decl_multiple_mixed_accesses() {
    let src = "struct E:\n    mut hp: i32\n\narena A: E\narena B: E\n\nsystem S(mut A, B):\n    par e in A:\n        e.hp -= 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::System(s) = module.items.last().expect("expected an item") else { panic!("expected system") };
    assert_eq!(s.accesses.len(), 2);
    assert_eq!(s.accesses[0].arena, "A");
    assert!(s.accesses[0].mutable);
    assert_eq!(s.accesses[1].arena, "B");
    assert!(!s.accesses[1].mutable);
}

/// Parse a `parallel: SystemA() SystemB()` block.
#[test]
fn parses_parallel_stmt() {
    let src = format!(
        "{}system A(mut Enemies):\n    par e in Enemies:\n        e.hp -= 1\n\nfn t():\n    parallel:\n        A()\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let Item::Fn(f) = module.items.last().expect("expected an item") else { panic!("expected fn") };
    let Stmt::Parallel { systems, .. } = &f.body.stmts[0] else { panic!("expected Parallel") };
    assert_eq!(systems.len(), 1);
    assert_eq!(systems[0].0, "A");
}

/// A system touching every arena it declared (respecting `mut`) type-checks.
#[test]
fn accepts_system_touching_all_declared_arenas() {
    let src = format!(
        "{}system A(mut Enemies):\n    par e in Enemies:\n        e.hp -= 1\n\nfn t():\n    spawn Enemies(1)\n    parallel:\n        A()\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "a system touching only its declared (mut) arena should type-check");
}

/// Two systems that declare `mut` on two different arenas don't conflict --
/// the compiler can prove they're safe to run concurrently.
#[test]
fn accepts_parallel_block_disjoint_arenas() {
    let src = "struct E:\n    mut hp: i32\n\narena A: E\narena B: E\n\nsystem SA(mut A):\n    par e in A:\n        e.hp -= 1\n\nsystem SB(mut B):\n    par e in B:\n        e.hp -= 1\n\nfn t():\n    parallel:\n        SA()\n        SB()\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "systems declaring disjoint mutable arenas should be allowed to run concurrently");
}

/// Two systems that both declare the *same* arena read-only don't conflict
/// (concurrent reads never race).
#[test]
fn accepts_parallel_block_both_systems_readonly_same_arena() {
    let src = format!(
        "{}system SA(Enemies):\n    each e in Enemies:\n        print(f\"{{e.hp}}\")\nsystem SB(Enemies):\n    each e in Enemies:\n        print(f\"{{e.hp}}\")\n\nfn t():\n    parallel:\n        SA()\n        SB()\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "two systems reading the same arena read-only should not conflict");
}

/// An `each` loop over a read-only-declared arena that only reads its loop
/// variable (never mutates it) is allowed.
#[test]
fn accepts_system_readonly_each_without_mutation() {
    let src = format!(
        "{}system A(Enemies):\n    each e in Enemies:\n        let x: i32 = e.hp\n        print(f\"{{x}}\")\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "a read-only `each` that never mutates its loop variable should type-check");
}

/// A closure literal defined *and* invoked entirely within the same system
/// body (outside any nested `par`/`swarm` loop, which bans invoking a
/// closure value regardless -- that's `par_analysis`'s own long-standing,
/// unrelated rule) is allowed: unlike a `par`/`swarm` body, a system has no
/// enclosing scope to capture from, so the closure's statements are exactly
/// as inspectable as the rest of the body.
#[test]
fn accepts_system_closure_defined_and_invoked_locally() {
    let src = format!(
        "{}system A(mut Enemies):\n    let f = fn(x: i32) -> i32: x - 1\n    let y: i32 = f(5)\n    print(f\"{{y}}\")\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "a locally-defined-and-invoked closure should be allowed inside a system body: {:?}", Driver::check(&module).err());
}

/// A system referencing an arena it never declared is a type error.
#[test]
fn rejects_system_accessing_undeclared_arena() {
    let src = "struct E:\n    mut hp: i32\n\narena A: E\narena B: E\n\nsystem S(mut A):\n    par e in B:\n        e.hp -= 1\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "touching an undeclared arena should be a type error");
}

/// `spawn` into an arena a system declared read-only (not `mut`) is a type
/// error.
#[test]
fn rejects_system_spawning_into_readonly_declared_arena() {
    let src = format!("{}system A(Enemies):\n    spawn Enemies(5)\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "spawning into a read-only-declared arena should be a type error");
}

/// A `par` loop always requires `mut` on its arena, even if the body only
/// reads -- a system may not declare an arena read-only and then `par` over
/// it.
#[test]
fn rejects_system_par_over_readonly_declared_arena() {
    let src = format!("{}system A(Enemies):\n    par e in Enemies:\n        print(f\"{{e.hp}}\")\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "a `par` loop over a read-only-declared arena should be a type error");
}

/// An `each` loop over a read-only-declared arena may not mutate its loop
/// variable's own field.
#[test]
fn rejects_system_each_mutating_readonly_declared_arena_element() {
    let src = format!("{}system A(Enemies):\n    each e in Enemies:\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "mutating a read-only-declared arena's element should be a type error");
}

/// Calling another `fn` from inside a system body is not supported yet (v1
/// scope -- see `system_analysis`'s module doc comment).
#[test]
fn rejects_system_calling_helper_fn() {
    let src = format!(
        "{}fn helper(n: i32) -> i32:\n    n - 1\n\nsystem A(mut Enemies):\n    par e in Enemies:\n        e.hp = helper(e.hp)\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "calling a helper function from inside a system body should be a type error");
}

/// Writing through a `GenRef` index inside a system body is not supported
/// yet, regardless of declared access -- a `GenRef` doesn't carry which
/// specific arena it targets.
#[test]
fn rejects_system_writing_through_genref_index() {
    let src = format!(
        "{}system A(mut Enemies):\n    let g: GenRef<Enemy> = GenRef<Enemy>(0)\n    g[0].hp -= 1\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "writing through a GenRef index inside a system body should be a type error");
}

/// `frame:` is banned unconditionally inside a system body -- the frame
/// bump allocator's offset is a single shared global, unsafe when systems
/// run concurrently via `parallel:`.
#[test]
fn rejects_frame_inside_system_body() {
    let src = format!("{}system A(mut Enemies):\n    frame:\n        let x: i32 = 1\n    par e in Enemies:\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "`frame:` inside a system body should be a type error");
}

/// An SDL drawing builtin call is banned unconditionally inside a system
/// body, same reasoning as `par`/`swarm`.
#[test]
fn rejects_sdl_call_inside_system_body() {
    let src = format!(
        "{}system A(Enemies):\n    each e in Enemies:\n        clear_screen(0)\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "an SDL builtin call inside a system body should be a type error");
}

/// `parallel:` referencing an undeclared system name is a type error.
#[test]
fn rejects_parallel_call_to_undeclared_system() {
    let src = "fn t():\n    parallel:\n        Nope()\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "parallel: over an undeclared system should be a type error");
}

/// Two systems both declaring `mut` on the same arena conflict -- the
/// literal "compile-time lock" check.
#[test]
fn rejects_parallel_block_conflicting_mut_locks() {
    let src = format!(
        "{}system SA(mut Enemies):\n    par e in Enemies:\n        e.hp -= 1\nsystem SB(mut Enemies):\n    par e in Enemies:\n        e.hp -= 2\n\nfn t():\n    parallel:\n        SA()\n        SB()\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "two systems both requesting a mutable lock on the same arena should be a type error");
}

/// One system declaring `mut` and another declaring the same arena
/// read-only still conflict (the mutator could race the reader).
#[test]
fn rejects_parallel_block_one_mut_one_readonly_same_arena() {
    let src = format!(
        "{}system SA(mut Enemies):\n    par e in Enemies:\n        e.hp -= 1\nsystem SB(Enemies):\n    each e in Enemies:\n        print(f\"{{e.hp}}\")\n\nfn t():\n    parallel:\n        SA()\n        SB()\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "a mutator and a reader of the same arena should still conflict");
}

/// The same system named twice in one `parallel:` block is rejected.
#[test]
fn rejects_parallel_block_duplicate_system() {
    let src = format!(
        "{}system A(mut Enemies):\n    par e in Enemies:\n        e.hp -= 1\n\nfn t():\n    parallel:\n        A()\n        A()\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "listing the same system twice in one parallel: block should be a type error");
}

/// A `parallel:` block cannot list more systems than the worker pool has
/// slots (5 systems, each over its own disjoint arena so the only failure
/// is the capacity check, not a lock conflict).
#[test]
fn rejects_parallel_block_exceeding_worker_capacity() {
    let mut src = String::new();
    for c in ['A', 'B', 'C', 'D', 'E'] {
        src.push_str(&format!("struct E{c}:\n    mut hp: i32\n\narena Ar{c}: E{c}\n\nsystem S{c}(mut Ar{c}):\n    par e in Ar{c}:\n        e.hp -= 1\n\n"));
    }
    src.push_str("fn t():\n    parallel:\n");
    for c in ['A', 'B', 'C', 'D', 'E'] {
        src.push_str(&format!("        S{c}()\n"));
    }
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "a parallel: block listing more systems than the worker pool's fixed size should be a type error");
}

/// `parallel:` cannot be nested inside a `system` body.
#[test]
fn rejects_parallel_nested_inside_system_body() {
    let src = format!(
        "{}system B(mut Enemies):\n    par e in Enemies:\n        e.hp -= 1\n\nsystem A(mut Enemies):\n    parallel:\n        B()\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "nesting parallel: inside a system body should be a type error");
}

/// `parallel:` cannot be nested inside a `par`/`swarm` body.
#[test]
fn rejects_parallel_nested_inside_par_body() {
    let src = format!(
        "{}system A(mut Enemies):\n    par e in Enemies:\n        e.hp -= 1\n\nfn t():\n    par e in Enemies:\n        parallel:\n            A()\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "nesting parallel: inside a par/swarm body should be a type error");
}

/// A `system` compiles to the same `i32(i8*)` shape `par_worker_N` chunk
/// functions use, so it can be stored directly into the pool's `job_fn`
/// mailbox array with no wrapper.
#[test]
fn codegen_system_compiles_to_pool_job_shape() {
    let src = format!(
        "{}system A(mut Enemies):\n    par e in Enemies:\n        e.hp -= 1\n\nfn t():\n    parallel:\n        A()\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i32 @sys.A(i8* %_unused)"), "{}", ir);
}

/// `parallel:` dispatches each listed system to the pool's mailbox arrays
/// (reusing `par`/`swarm`'s existing globals/lazy-init verbatim) and waits
/// on one done-semaphore per listed system. Each system's body is a plain
/// `spawn` (not its own nested `par` loop) so the *only* `ReleaseSemaphore`/
/// `WaitForSingleObject` call sites in the emitted IR are the ones
/// `emit_parallel_stmt` itself emits, keeping the exact counts below
/// unambiguous (a nested `par` inside a dispatched system would add its own
/// pooled-fan-out and serial-fallback release/wait sites on top of these).
#[test]
fn codegen_parallel_dispatches_to_pool() {
    let src = "struct E:\n    mut hp: i32\n\narena A: E\narena B: E\n\nsystem SA(mut A):\n    spawn A(1)\n\nsystem SB(mut B):\n    spawn B(1)\n\nfn t():\n    parallel:\n        SA()\n        SB()\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define void @par.pool.ensure_init"), "{}", ir);
    assert!(ir.contains("call void @par.pool.ensure_init()"), "{}", ir);
    assert!(ir.contains("store i32 (i8*)* @sys.SA"), "{}", ir);
    assert!(ir.contains("store i32 (i8*)* @sys.SB"), "{}", ir);
    // 1 static call site in `par.pool.worker_main`'s own generic per-job
    // loop (releases/waits on its own semaphore once it's done, textually
    // once regardless of workload) + 1 dispatch-site release/wait per
    // listed system.
    assert_eq!(ir.matches("call i32 @ReleaseSemaphore(").count(), 3, "{}", ir);
    assert_eq!(ir.matches("call i32 @WaitForSingleObject(").count(), 3, "{}", ir);
}

/// A program using both a plain top-level `par` statement and a
/// `system`/`parallel` block still only creates the worker pool's static
/// machinery once -- both dispatch through the exact same pool.
#[test]
fn codegen_system_and_par_share_one_pool() {
    let src = format!(
        "{}system A(mut Enemies):\n    par e in Enemies:\n        e.hp -= 1\n\nfn t():\n    par e in Enemies:\n        e.hp = 0\n    parallel:\n        A()\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert_eq!(ir.matches("define i32 @par.pool.worker_main").count(), 1, "{}", ir);
    assert_eq!(ir.matches("define void @par.pool.ensure_init").count(), 1, "{}", ir);
}

/// End-to-end: two systems declaring `mut` on two disjoint arenas, run
/// concurrently via `parallel:`, both correctly mutate their own arena's
/// live elements with no corruption.
#[test]
fn runtime_parallel_two_systems_disjoint_arenas_end_to_end() {
    let src = "struct Enemy:\n    mut hp: i32\n\nstruct Particle:\n    mut life: i32\n\narena Enemies: Enemy\narena Particles: Particle\n\nsystem UpdateEnemies(mut Enemies):\n    par e in Enemies:\n        e.hp -= 1\n\nsystem UpdateParticles(mut Particles):\n    par p in Particles:\n        p.life -= 1\n\nfn main():\n    spawn Enemies(10)\n    spawn Enemies(20)\n    spawn Particles(5)\n    parallel:\n        UpdateEnemies()\n        UpdateParticles()\n    swarm e in Enemies:\n        print(f\"hp: {e.hp}\")\n    swarm p in Particles:\n        print(f\"life: {p.life}\")\n";
    let output = compile_and_run("parallel_two_systems", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.matches("hp: 9").count() + stdout.matches("hp: 19").count(), 2, "{}", stdout);
    assert_eq!(stdout.matches("life: 4").count(), 1, "{}", stdout);
}

/// End-to-end: a system containing its own nested `par` loop, dispatched
/// via `parallel:` alongside a sibling system, still produces correct
/// results -- the nested `par` takes the existing serial-fallback path
/// (this system's own dispatch thread is itself a pool worker) with no new
/// runtime code at all.
#[test]
fn runtime_parallel_system_containing_nested_par_end_to_end() {
    let src = "struct Enemy:\n    mut hp: i32\n\nstruct Particle:\n    mut life: i32\n\narena Enemies: Enemy\narena Particles: Particle\n\nsystem UpdateEnemies(mut Enemies):\n    par outer in Enemies:\n        par inner in Enemies:\n            inner.hp -= 1\n\nsystem UpdateParticles(mut Particles):\n    par p in Particles:\n        p.life -= 1\n\nfn main():\n    spawn Enemies(10)\n    spawn Particles(5)\n    parallel:\n        UpdateEnemies()\n        UpdateParticles()\n    swarm e in Enemies:\n        print(f\"hp: {e.hp}\")\n    swarm p in Particles:\n        print(f\"life: {p.life}\")\n";
    let output = compile_and_run("parallel_nested_par", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    // Enemies has 1 live element, so the nested `par` runs once per outer
    // iteration (also 1) -- one decrement, no lost updates from the
    // reentrant serial fallback racing with itself.
    assert_eq!(stdout.matches("hp: 9").count(), 1, "{}", stdout);
    assert_eq!(stdout.matches("life: 4").count(), 1, "{}", stdout);
}

/// End-to-end across a module boundary: a `system` (and the arena it
/// declares access to, and a plain `fn` that dispatches it via `parallel:`)
/// all defined in an imported file, invoked from the importing file through
/// an ordinary qualified function call -- exercises `modules::rename_item`'s
/// `Item::System` arm (mangling the system's own name and its declared
/// arena names) and `rename_stmt`'s `Stmt::Parallel` arm (mangling the
/// system name referenced in the `parallel:` block) end to end through a
/// real compiled binary, not just in isolation. (Arena/system names aren't
/// themselves referenceable via `alias::name` qualification from another
/// file -- only struct literals/fn calls/enum variants are, see
/// `parses_qualified_fn_call_as_mangled_name` -- so the whole demo lives in
/// `lib.star`, reached via one ordinary qualified call, `lib::run_demo()`.)
#[test]
fn runtime_imported_system_and_parallel_block_end_to_end() {
    let dir = test_scratch_dir("runtime_imported_system_and_parallel_block_end_to_end");
    write_test_file(
        &dir,
        "lib.star",
        "struct Enemy:\n    mut hp: i32\n\narena Enemies: Enemy\n\nsystem UpdateEnemies(mut Enemies):\n    par e in Enemies:\n        e.hp -= 1\n\nfn run_demo():\n    spawn Enemies(10)\n    parallel:\n        UpdateEnemies()\n    swarm e in Enemies:\n        print(f\"hp: {e.hp}\")\n",
    );
    let main_path = write_test_file(&dir, "main.star", "import \"lib.star\" as lib\n\nfn main():\n    lib::run_demo()\n");

    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_imported_system_and_parallel.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");
    let output = std::process::Command::new(&exe).output().expect("failed to execute compiled test binary");
    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "hp: 9");
}
