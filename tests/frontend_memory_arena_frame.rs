//! M5 memory model: `frame`/`arena`/`GenRef`/`Handle`, allocation and runtime verification, frame escape analysis
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== M5 Memory Model Tests ============================================

/// Parse `frame` statement with body.
#[test]
fn parses_frame_stmt() {
    let src = "fn test():\n    frame:\n        let x = 1\n        let y = 2\n";
    let module = Driver::parse(src).unwrap();
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn"); };
    assert!(matches!(&f.body.stmts[0], Stmt::Frame { .. }));
    let Stmt::Frame { body, .. } = &f.body.stmts[0] else { panic!("expected Frame"); };
    assert_eq!(body.stmts.len(), 2);
}

/// Parse `arena` declaration.
#[test]
fn parses_arena_decl() {
    let src = "arena MyArena: Point\n";
    let module = Driver::parse(src).unwrap();
    assert!(matches!(module.items[0], Item::Arena(_)));
}

/// Parse `GenRef<T>(value)` creation syntax.
#[test]
fn parses_genref_create() {
    let src = "fn test(id: i32):\n    GenRef<i32>(id)\n";
    let module = Driver::parse(src).unwrap();
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn"); };
    let Stmt::Expr(expr) = &f.body.stmts[0] else { panic!("expected expr"); };
    assert!(matches!(expr, Expr::GenRefCreate { .. }));
}

/// Codegen `frame` statement: IR should contain frame allocator operations.
#[test]
fn codegen_frame() {
    let src = "fn test():\n    frame:\n        let x = 1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    // Frame allocator globals should be emitted
    assert!(ir.contains("@frame.buf"), "frame buffer global should appear");
    assert!(ir.contains("@frame.off"), "frame offset global should appear");
}

/// Codegen `arena` declaration: IR should contain arena struct and globals.
#[test]
fn codegen_arena() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\narena Entities: Point\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    // Arena struct type should be emitted
    assert!(ir.contains("%Entities = type"), "arena struct type should appear");
    // Arena globals should be emitted
    assert!(ir.contains("@arena.Entities.data"), "arena data pointer should appear");
    assert!(ir.contains("@arena.Entities.count"), "arena count should appear");
}

/// Codegen `GenRef` type declaration: IR should contain GenRef struct.
#[test]
fn codegen_genref_type() {
    let src = "struct Point:\n    x: i32\n    y: i32\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    // GenRef type should be emitted at module level
    // Field 1 (slot index) is `i32`; field 2 (generation counter) is `i64`
    // -- widened from `i32` so ~2^31 despawn/spawn cycles on one slot can't
    // wrap the live generation back to a value a stale `GenRef` still
    // matches (see `codegen::arena`'s `%GenRef` decl doc comment and
    // `runtime_genref_generation_counter_does_not_alias_after_i32_would_have_wrapped`).
    assert!(ir.contains("%GenRef = type { i32, i64 }"), "GenRef type should appear with a 64-bit generation field");
}

// ===== Memory Allocation Verification Tests ===============================

/// Frame allocation uses bump pointer from frame buffer (not stack alloca).
#[test]
fn codegen_frame_alloc_uses_bump_allocator() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\nfn test() -> i32:\n    frame:\n        let p = Point(1, 2)\n        p.x + p.y\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    // Frame offset should be loaded for allocation (bump pointer)
    assert!(ir.contains("load i64, i64* @frame.off"), "frame offset should be loaded");
    // Frame offset should be stored (for O(1) deallocation)
    assert!(ir.contains("store i64"), "offset should be stored");
    // Should get buffer address for calculations -- the physical buffer is
    // always sized to `crate::types::MAX_FRAME_BUDGET` (16 MiB), not the
    // 4096-byte *default per-block budget* this un-overridden `frame:`
    // block happens to use (see `Codegen::FRAME_BUF_SIZE`'s doc comment).
    assert!(ir.contains("getelementptr inbounds [16777216 x i8]"), "buffer address should be computed");
}

/// Structs inside frame blocks use frame allocator, not stack allocation.
#[test]
fn codegen_struct_in_frame_uses_heap() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\nfn test() -> i32:\n    frame:\n        let p = Point(5, 10)\n        p.x\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    // StructLit in frame should allocate from frame buffer
    // Check that frame offset operations are present
    let has_frame_alloc = ir.contains("load i64, i64* @frame.off") && 
                          ir.contains("add i64") && 
                          ir.contains("getelementptr inbounds i8");
    assert!(has_frame_alloc, "Frame allocation code should be present for struct in frame");
}

/// Structs outside frame blocks use stack allocation (alloca).
#[test]
fn codegen_struct_outside_frame_uses_stack() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\nfn test() -> i32:\n    let p = Point(5, 10)\n    p.x\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    // StructLit outside frame should use alloca
    assert!(ir.contains("alloca %Point"), "struct outside frame should use alloca");
}

/// GenRef dereference reads the stored index/generation out of the GenRef
/// struct, then validates the stored generation against the arena's live
/// generation for that slot before trusting the data.
#[test]
fn codegen_genref_index_extracts_index() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\narena Entities: Point\n\nfn follow(gen_ref: GenRef<Point>) -> Point:\n    gen_ref[0]\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    // GenRef struct fields (index, generation) should be extracted via GEP.
    assert!(ir.contains("getelementptr inbounds %GenRef, %GenRef*"), "GenRef GEP should be present");
    assert!(ir.contains("i32 0, i32 0"), "index field offset should be 0");
    assert!(ir.contains("i32 0, i32 1"), "generation field offset should be 1");
    // A real slot-map lookup into the backing arena's generation array,
    // bounds-checked, then compared against the stored generation.
    assert!(ir.contains("@arena.Entities.gen"), "arena generation array should be read: {}", ir);
    assert!(ir.contains("icmp ult i64"), "bounds check should be emitted: {}", ir);
    assert!(ir.contains("icmp eq i64"), "generation comparison (64-bit generation counter) should be emitted: {}", ir);
    assert!(ir.contains("phi"), "result should merge live-data and stale-fallback paths: {}", ir);
}

/// Arena declaration includes malloc declaration for runtime allocation.
#[test]
fn codegen_arena_includes_malloc() {
    let src = "struct Point:\n    x: i32\narena EnemyArena: Point\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    // malloc should be declared (even if not called yet)
    assert!(ir.contains("declare noalias i8* @malloc"), "malloc should be declared");
}

// ===== Runtime Memory Verification Tests ================================

/// Runtime test: frame allocation offset resets correctly after function call.
#[test]
fn runtime_frame_offset_resets_after_call() {
    // This test verifies that the compiled memory_models.exe produces correct output
    // indicating frame offset management is working
    use std::process::Command;
    
    let output = Command::new("examples/memory_models.exe")
        .output()
        .expect("failed to execute memory_models.exe");
    
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Path calculation result: 10"), "expected correct path result");
    // MinGW uses exit code 0x1c instead of 0 for normal exit
}

/// GenRef creation/dereference through a struct-typed, arena-backed
/// `GenRef<Point>` compiles and lowers cleanly end to end (parse -> check ->
/// codegen) through free functions passing the handle around. The genuine
/// *runtime* proof that a stale reference is actually handled safely lives
/// in `runtime_genref_stale_after_despawn_falls_back_to_zero` below, which
/// runs a real compiled binary; this test only checks compilation.
#[test]
fn checks_genref_create_and_follow_through_arena() {
    let src = r#"struct Point:
    x: i32
    y: i32

arena Entities: Point

fn create_entity_reference(idx: i32) -> GenRef<Point>:
    GenRef<Point>(idx)

fn follow_reference(gen_ref: GenRef<Point>) -> i32:
    gen_ref[0].x

fn test() -> i32:
    frame:
        spawn Entities(42, 0)
        let ref_val = GenRef<Point>(0)
        follow_reference(ref_val)
"#;
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    // Verify GenRef index/generation field access in IR.
    assert!(ir.contains("i32 0, i32 0"), "GenRef should access index field");
    assert!(ir.contains("i32 0, i32 1"), "GenRef should access generation field");
}

// --- `Handle<T>` (design.md "Resource handles": GenRef's pattern reused
// for engine resources) ------------------------------------------------------

/// Parse `Handle<T>(value)` creation syntax -- the exact same grammar as
/// `GenRef<T>(value)`, tagged `is_handle: true`.
#[test]
fn parses_handle_create() {
    let src = "fn test(id: i32):\n    Handle<i32>(id)\n";
    let module = Driver::parse(src).unwrap();
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn"); };
    let Stmt::Expr(expr) = &f.body.stmts[0] else { panic!("expected expr"); };
    assert!(matches!(expr, Expr::GenRefCreate { is_handle: true, .. }));
}

/// `Handle<T>` reuses `GenRef`'s exact LLVM struct layout (see `Ty::Handle`'s
/// doc comment) -- no separate `%Handle` type is ever declared.
#[test]
fn codegen_handle_reuses_genref_struct_layout() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\narena Entities: Point\n\nfn follow(h: Handle<Point>) -> Point:\n    h[0]\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    assert!(ir.contains("%GenRef = type { i32, i64 }"), "Handle should reuse the %GenRef type, not declare its own");
    assert!(!ir.contains("%Handle ="), "no separate %Handle LLVM type should ever be declared");
    assert!(ir.contains("getelementptr inbounds %GenRef, %GenRef*"), "Handle dereference should GEP through %GenRef");
}

/// `Handle<T>` creation/dereference through a struct-typed, arena-backed
/// resource compiles and lowers cleanly end to end, mirroring
/// `checks_genref_create_and_follow_through_arena`.
#[test]
fn checks_handle_create_and_follow_through_arena() {
    let src = r#"struct Texture:
    width: i32
    height: i32

arena Textures: Texture

fn load(idx: i32) -> Handle<Texture>:
    Handle<Texture>(idx)

fn bind(h: Handle<Texture>) -> i32:
    h[0].width

fn test() -> i32:
    frame:
        spawn Textures(256, 256)
        let h = Handle<Texture>(0)
        bind(h)
"#;
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    assert!(ir.contains("i32 0, i32 0"), "Handle should access index field");
    assert!(ir.contains("i32 0, i32 1"), "Handle should access generation field");
}

/// `Handle<T>` and `GenRef<T>` are nominally distinct types even though they
/// share every byte of runtime representation -- a function declared to take
/// a `Handle<T>` must reject a `GenRef<T>` argument (and vice versa), so a
/// resource handle can never be silently swapped for an entity reference.
#[test]
fn rejects_genref_passed_where_handle_expected() {
    let src = "struct Point:\n    x: i32\n\narena Entities: Point\n\nfn bind(h: Handle<Point>) -> i32:\n    h[0].x\n\nfn t():\n    let r = GenRef<Point>(0)\n    bind(r)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(_) = Driver::check(&module) else { panic!("GenRef<T> should not satisfy a Handle<T> parameter") };
}

/// `Handle<T>` with no arena declared for `T` is a type error, worded with
/// `Handle` (not `GenRef`) so the diagnostic points at what the user
/// actually wrote.
#[test]
fn rejects_handle_without_backing_arena() {
    let src = "struct Texture:\n    w: i32\n\nfn t():\n    Handle<Texture>(0)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("Handle<T> with no backing arena should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("Handle<") && d.message.contains("no backing arena")), "got: {:?}", diags);
}

/// `Handle<T>` is ambiguous when two arenas both hold element type `T`.
#[test]
fn rejects_handle_with_ambiguous_backing_arena() {
    let src = "struct Texture:\n    w: i32\n\narena A: Texture\narena B: Texture\n\nfn t():\n    Handle<Texture>(0)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("Handle<T> with two backing arenas should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("Handle<") && d.message.contains("ambiguous")), "got: {:?}", diags);
}

/// Reflection metadata (`@export`/`@tweakable`) spells a `Handle<T>` field as
/// `Handle<T>`, not `GenRef<T>` -- see `Codegen::reflect_type_name`.
#[test]
fn reflect_metadata_names_handle_distinctly_from_genref() {
    let src = "struct Texture:\n    w: i32\n\narena Textures: Texture\n\nstruct Sprite:\n    @export tex: Handle<Texture>\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("Handle<Texture>"), "reflection metadata should spell the field's type as Handle<Texture>: {}", ir);
}

/// Runtime test: a `Handle` dereferenced after its backing resource is
/// unloaded (`despawn`) falls back to the element type's zero value instead
/// of returning stale data or segfaulting -- the same flagship safety
/// guarantee `GenRef` gives despawned entities, reused for resources,
/// proven end to end through a real compiled binary. See
/// `examples/handle_resource.star`.
#[test]
fn runtime_handle_stale_after_unload_falls_back_to_zero() {
    use std::process::Command;

    let output = Command::new("examples/handle_resource.exe").output().expect("failed to execute handle_resource.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before unload: 256x256"), "live handle should read real data: {}", stdout);
    assert!(stdout.contains("after unload: 0x0"), "stale handle should fall back to zero, not crash or read stale data: {}", stdout);
}

/// `Handle(value)` with no explicit type argument must be a clear parse
/// error, mirroring `rejects_genref_without_type_args`.
#[test]
fn rejects_handle_without_type_args() {
    let src = "arena Entities: i32\nfn main():\n    let g = Handle(0)\n";
    let module = Driver::parse(src);
    let Err(diags) = module else { panic!("bare Handle(..) should be a parse error") };
    assert!(
        diags.iter().any(|d| d.message.contains("requires an explicit type argument")),
        "got: {:?}",
        diags
    );
}

/// `Handle<i32>()` (missing the value argument) must be a clear parse error.
#[test]
fn rejects_handle_missing_value_arg() {
    let src = "arena Entities: i32\nfn main():\n    let g = Handle<i32>()\n";
    let module = Driver::parse(src);
    let Err(diags) = module else { panic!("Handle<T>() with no value should be a parse error") };
    assert!(
        diags.iter().any(|d| d.message.contains("expects exactly one argument")),
        "got: {:?}",
        diags
    );
}

/// Runtime test: nested frame scopes work correctly.
#[test]
fn runtime_nested_frame_scopes() {
    // Test that frame offset is saved and restored for nested frames
    let src = r#"struct Point:
    x: i32
    y: i32

fn test_nested() -> i32:
    frame:
        let outer = Point(10, 20)
        frame:
            let inner = Point(30, 40)
            outer.x
"#;
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    
    // Should have multiple load/store operations for nested frames
    let offset_loads = ir.matches("load i64, i64* @frame.off").count();
    assert!(offset_loads >= 2, "nested frames should save/restore offset multiple times");
}

// ===== Frame escape analysis ===============================================
//
// design.md's safety pitch for `frame` is that "frame pointers can never be
// assigned to lifetimes exceeding the current tick": a `frame:` block is a
// scoped bump allocator whose offset is rewound the instant the block ends,
// so a struct value declared inside one must never survive past it. Only
// struct (`Ty::Named`) identity is tracked -- scalars, Vec/Mat SIMD values,
// and `GenRef`s are plain data copied by value everywhere in this compiler
// and can never dangle, so deriving a scalar from a frame-local struct (or
// passing the struct itself into a synchronous function call) is fine; only
// returning/assigning/spawning the struct's own identity past its scope is
// rejected. See `Checker::check_frame_escapes` in `types.rs`.

/// Deriving a scalar (via field access/arithmetic) from a frame-local struct
/// and returning it explicitly is safe: the scalar is a plain value copied
/// out of frame memory, not the struct's identity.
#[test]
fn accepts_frame_local_scalar_derived_via_explicit_return() {
    let src = format!(
        "{}fn t() -> i32:\n    frame:\n        let p = Point(1, 2)\n        return p.x + p.y\n",
        FRAME_ESCAPE_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "returning a scalar derived from a frame-local struct should be allowed");
}

/// Passing a frame-local struct into a function call is safe: the callee
/// only borrows it for the duration of that synchronous call (and is itself
/// independently checked against leaking its own frame-locals back out), so
/// using the call's result in the enclosing function's tail position is fine.
#[test]
fn accepts_frame_local_struct_passed_to_call_in_tail_position() {
    let src = format!(
        "{}fn magnitude(p: Point) -> i32:\n    p.x + p.y\n\nfn t() -> i32:\n    frame:\n        let p = Point(3, 4)\n        magnitude(p)\n",
        FRAME_ESCAPE_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "passing a frame-local struct to a function call should be allowed");
}

/// Assigning a frame-local struct into another binding declared in the same
/// (or an enclosing) `frame:` scope doesn't escape -- both die with the
/// block together.
#[test]
fn accepts_frame_local_struct_assigned_to_frame_local_target() {
    let src = format!(
        "{}fn t() -> i32:\n    frame:\n        let a = Point(1, 2)\n        let mut b = Point(0, 0)\n        b = a\n        return b.x\n",
        FRAME_ESCAPE_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "assigning a frame-local struct to another frame-local should be allowed");
}

/// Explicitly `return`-ing a frame-local struct's own identity out of the
/// enclosing function is the classic escape design.md warns about: the
/// struct's memory is reclaimed the instant the `frame:` block ends, which
/// happens before the caller could ever observe it.
#[test]
fn rejects_returning_frame_local_struct() {
    let src = format!(
        "{}fn t() -> Point:\n    frame:\n        let p = Point(1, 2)\n        return p\n",
        FRAME_ESCAPE_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let errs = Driver::check(&module).expect_err("returning a frame-local struct should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("frame")), "error should mention the frame escape: {:?}", errs);
}

/// The same escape can happen implicitly: a `frame:` block in tail position
/// whose own trailing expression is the frame-local struct becomes the
/// function's return value with no explicit `return` at all.
#[test]
fn rejects_frame_local_struct_as_implicit_trailing_return() {
    let src = format!(
        "{}fn t() -> Point:\n    frame:\n        let p = Point(1, 2)\n        p\n",
        FRAME_ESCAPE_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let errs = Driver::check(&module).expect_err("an implicit trailing frame-local struct should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("frame")), "error should mention the frame escape: {:?}", errs);
}

/// Assigning a frame-local struct into a field of a struct that outlives the
/// `frame:` scope (here, a `mut` parameter passed in by the caller) is
/// exactly the "stored into a struct field" escape todo.md calls out.
#[test]
fn rejects_frame_local_struct_assigned_into_outer_struct_field() {
    let src = format!(
        "{}struct Holder:\n    mut p: Point\n\nfn t(mut h: Holder):\n    frame:\n        let temp = Point(9, 9)\n        h.p = temp\n",
        FRAME_ESCAPE_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let errs = Driver::check(&module).expect_err("assigning a frame-local struct into an outer struct field should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("frame")), "error should mention the frame escape: {:?}", errs);
}

/// Reassigning a frame-local struct into a variable declared *outside* the
/// `frame:` block (not just a struct field) is the same escape.
#[test]
fn rejects_frame_local_struct_assigned_to_outer_variable() {
    let src = format!(
        "{}fn t() -> i32:\n    let mut result = Point(0, 0)\n    frame:\n        let temp = Point(5, 6)\n        result = temp\n    return result.x\n",
        FRAME_ESCAPE_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let errs = Driver::check(&module).expect_err("assigning a frame-local struct to an outer variable should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("frame")), "error should mention the frame escape: {:?}", errs);
}

/// `spawn`-ing a frame-local struct into an arena is a third escape vector:
/// arenas are long-lived by design, definitely outliving the current tick.
#[test]
fn rejects_spawn_using_frame_local_struct() {
    let src = format!(
        "{}struct Enemy:\n    pos: Point\n\narena Enemies: Enemy\n\nfn t():\n    frame:\n        let temp = Point(1, 1)\n        spawn Enemies(temp)\n",
        FRAME_ESCAPE_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let errs = Driver::check(&module).expect_err("spawning with a frame-local struct argument should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("frame")), "error should mention the frame escape: {:?}", errs);
}

/// A struct declared *outside* any `frame:` block is never subject to escape
/// analysis, even when it's later mutated or returned from inside one.
#[test]
fn accepts_non_frame_struct_returned_from_inside_frame_block() {
    let src = format!(
        "{}fn t() -> Point:\n    let p = Point(7, 8)\n    frame:\n        let temp = Point(0, 0)\n    return p\n",
        FRAME_ESCAPE_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "returning a struct declared outside the frame block should be allowed");
}

// ===== `frame:` block ending in `return` (`projects/snake/NOTES.md` 1.3) ===

/// A `frame:` block whose only statement is an explicit `return` used to
/// emit invalid LLVM IR: `emit_frame_body` unconditionally appended the
/// frame-offset-restore `store` *after* the body's own `ret` terminator,
/// which LLVM rejects ("expected instruction opcode" -- no instruction,
/// especially not another terminator, may follow a block's first
/// terminator). Confirmed live in `projects/snake` (`NOTES.md` section 1.3)
/// while trying a trailing `return` as a fix for a different frame-capacity
/// bug. `emit_frame_body` now skips the restore entirely when the body
/// already terminates, since a terminated body never falls through to where
/// the restore would run anyway.
#[test]
fn runtime_frame_block_ending_in_return_compiles_and_runs_end_to_end() {
    let src = "fn pick() -> i32:\n    frame:\n        return 5\n\nfn main():\n    println(f\"{pick()}\")\n";
    let output = compile_and_run("frame_block_ending_in_return", src);
    assert!(output.status.success(), "{:?}", output);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "5");
}

/// Same bug, but with the `return` reached through both arms of an `if`
/// inside the `frame:` block -- the exact shape `projects/snake`'s
/// `spawn_food` hit (two branches, each ending in `return`, no trailing
/// value expression). Guards `body_terminates`'s `TypedStmt::If` arm, not
/// just a bare top-level `return`.
#[test]
fn runtime_frame_block_ending_in_if_else_both_returning_compiles_and_runs_end_to_end() {
    let src = "fn classify(x: i32) -> i32:\n    frame:\n        let y = x + 1\n        if y > 0:\n            return y\n        else:\n            return 0 - y\n\nfn main():\n    println(f\"{classify(4)}\")\n    println(f\"{classify(-10)}\")\n";
    let output = compile_and_run("frame_block_ending_in_if_else_both_returning", src);
    assert!(output.status.success(), "{:?}", output);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["5", "9"]);
}
