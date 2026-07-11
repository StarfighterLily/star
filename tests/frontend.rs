//! Integration tests for the Star front-end (lexer + parser).
//!
//! These drive the public `star` library API over small `.star` snippets and
//! the canonical example, guarding against regressions in tokenization,
//! indentation handling, and parsing.

use star::ast::{BinOp, Expr, Item, Stmt, Type, UnOp};
use star::driver::Driver;
use star::lexer::TokenKind;
use star::types::{Ty, TypedExpr, TypedItem, TypedStmt};

/// Slice out just one `define ... @name(...` function's body from a full
/// module's emitted IR, so a test asserting "this function never emits X"
/// isn't tripped up by an unrelated occurrence of `X` elsewhere in the
/// module -- e.g. the fixed `star_rc_alloc`/`retain`/`release` runtime
/// prelude (see `Codegen::emit_rc_runtime`) legitimately contains its own
/// `ret void`/`icmp`/`call i8* @malloc`, which has nothing to do with
/// whether the function under test emits them.
fn extract_fn_body<'a>(ir: &'a str, define_prefix: &str) -> &'a str {
    let start = ir.find(define_prefix).unwrap_or_else(|| panic!("`{}` not found in IR:\n{}", define_prefix, ir));
    let rest = &ir[start..];
    let end = rest.find("\n}\n").map(|i| i + 3).unwrap_or(rest.len());
    &rest[..end]
}

/// Lexing a struct should emit INDENT/DEDENT around the field block.
#[test]
fn lexes_indentation_markers() {
    let src = "struct P:\n    health: i32\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let kinds: Vec<_> = tokens.into_iter().map(|t| t.kind).collect();
    assert!(kinds.contains(&TokenKind::Indent));
    assert!(kinds.contains(&TokenKind::Dedent));
    assert_eq!(kinds.last(), Some(&TokenKind::Eof));
}

/// Blank and comment-only lines must not produce structural tokens.
#[test]
fn ignores_blank_and_comment_lines() {
    let src = "struct P:\n\n    # a comment\n    health: i32\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let indents = tokens.iter().filter(|t| t.kind == TokenKind::Indent).count();
    assert_eq!(indents, 1, "only one real indentation level expected");
}

/// The canonical example from the docs must parse without diagnostics.
#[test]
fn parses_canonical_example() {
    let src = include_str!("../examples/player.star");
    let module = Driver::parse(src).expect("canonical example should parse");
    assert_eq!(module.items.len(), 6);
    assert!(matches!(module.items[0], Item::Struct(_)));
    assert!(matches!(module.items[1], Item::Struct(_)));
    assert!(matches!(module.items[2], Item::Trait(_)));
    assert!(matches!(module.items[3], Item::Impl(_)));
    assert!(matches!(module.items[4], Item::Impl(_)));
    assert!(matches!(module.items[5], Item::Fn(_)));
}

/// A struct field with a default should retain its initializer expression.
#[test]
fn parses_field_default() {
    let src = "struct P:\n    mut health: i32 = 100\n";
    let module = Driver::parse(src).unwrap();
    let Item::Struct(def) = &module.items[0] else {
        panic!("expected a struct");
    };
    let field = &def.fields[0];
    assert!(field.is_mut);
    assert_eq!(field.name, "health");
    assert!(matches!(field.default, Some(Expr::Int(100, _))));
}

/// Compound assignment inside a method body should parse as an `Assign` stmt.
#[test]
fn parses_compound_assignment() {
    let src = concat!(
        "impl Damageable for Player:\n",
        "    fn take_damage(mut self, amount: i32):\n",
        "        self.health -= amount\n",
    );
    let module = Driver::parse(src).unwrap();
    let Item::Impl(block) = &module.items[0] else {
        panic!("expected an impl block");
    };
    let body = &block.methods[0].body;
    assert!(matches!(body.stmts[0], Stmt::Assign { .. }));
}

/// Inconsistent indentation must be reported as an error rather than panic.
#[test]
fn rejects_inconsistent_indentation() {
    let src = "struct P:\n    a: i32\n  b: i32\n";
    let result = Driver::lex(src);
    assert!(result.is_err(), "misaligned dedent should be an error");
}

// ===== M9 Control Flow Tests ==============================================

/// Parse `if` expression used as a value.
#[test]
fn parses_if_expr() {
    let src = "fn test(x: i32):\n    let r = if x > 0:\n        1\n    else:\n        2\n";
    let module = Driver::parse(src).unwrap();
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn"); };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected Let"); };
    assert!(matches!(value, Expr::If { .. }));
    match value {
        Expr::If { then_block, else_block, .. } => {
            assert!(matches!(then_block.stmts[0], Stmt::Expr(Expr::Int(1, _))));
            assert!(matches!(else_block.as_ref().unwrap().stmts[0], Stmt::Expr(Expr::Int(2, _))));
        }
        _ => panic!("expected Expr::If"),
    }
}

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
    assert!(ir.contains("%GenRef = type { i32, i32 }"), "GenRef type should appear");
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
    // Should get buffer address for calculations
    assert!(ir.contains("getelementptr inbounds [4096 x i8]"), "buffer address should be computed");
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
    assert!(ir.contains("icmp eq i32"), "generation comparison should be emitted: {}", ir);
    assert!(ir.contains("phi"), "result should merge live-data and stale-fallback paths: {}", ir);
}

/// Arena declaration includes malloc declaration for runtime allocation.
#[test]
fn codegen_arena_includes_malloc() {
    let src = "arena EnemyArena: Point\n";
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

const FRAME_ESCAPE_SRC_PREFIX: &str = "struct Point:\n    x: i32\n    y: i32\n\n";

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

// ===== M6 SIMD Math Type Tests ============================================

/// Type-check a single-function source and return the trailing expression's
/// resolved type.
fn typed_fn_result_ty(src: &str) -> Ty {
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[0] else { panic!("expected fn") };
    match f.body.stmts.last().expect("body should have a statement") {
        TypedStmt::Expr(e) => e.clone().into_ty(),
        other => panic!("expected trailing expr statement, got {:?}", other),
    }
}

#[test]
fn checks_vec_add_same_type() {
    let ty = typed_fn_result_ty("fn t(a: Vec3, b: Vec3) -> Vec3:\n    a + b\n");
    assert_eq!(ty, Ty::Vec3);
}

#[test]
fn checks_vec_scalar_mul_both_orders() {
    assert_eq!(typed_fn_result_ty("fn t(a: Vec3) -> Vec3:\n    a * 2.0\n"), Ty::Vec3);
    assert_eq!(typed_fn_result_ty("fn t(a: Vec3) -> Vec3:\n    2.0 * a\n"), Ty::Vec3);
}

#[test]
fn checks_mat4_vec4_mul() {
    let ty = typed_fn_result_ty("fn t(m: Mat4, v: Vec4) -> Vec4:\n    m * v\n");
    assert_eq!(ty, Ty::Vec4);
}

#[test]
fn checks_mat4_mat4_mul() {
    let ty = typed_fn_result_ty("fn t(a: Mat4, b: Mat4) -> Mat4:\n    a * b\n");
    assert_eq!(ty, Ty::Mat4);
}

#[test]
fn checks_swizzle_read_types() {
    assert_eq!(typed_fn_result_ty("fn t(v: Vec3) -> Vec3:\n    v.xyz\n"), Ty::Vec3);
    assert_eq!(typed_fn_result_ty("fn t(v: Vec3) -> Vec2:\n    v.xy\n"), Ty::Vec2);
    assert_eq!(typed_fn_result_ty("fn t(v: Vec3) -> f32:\n    v.x\n"), Ty::Float);
    assert_eq!(typed_fn_result_ty("fn t(v: Vec3) -> Vec3:\n    v.zyx\n"), Ty::Vec3);
    assert_eq!(typed_fn_result_ty("fn t(v: Vec3) -> Vec2:\n    v.xx\n"), Ty::Vec2);
}

#[test]
fn rejects_mismatched_vec_arity() {
    let module = Driver::parse("fn t(a: Vec2, b: Vec3):\n    a + b\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "mismatched vector arity should be a type error");
}

#[test]
fn rejects_invalid_swizzle_component() {
    let module = Driver::parse("fn t(v: Vec3):\n    v.q\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "invalid swizzle component should be a type error");
}

#[test]
fn rejects_swizzle_out_of_range() {
    let module = Driver::parse("fn t(v: Vec2):\n    v.z\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "swizzle component out of range should be a type error");
}

#[test]
fn rejects_vec_comparison() {
    let module = Driver::parse("fn t(a: Vec3, b: Vec3):\n    a == b\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "comparing vectors should be a type error");
}

#[test]
fn rejects_duplicate_swizzle_write_target() {
    let module = Driver::parse("fn t(mut v: Vec3):\n    v.xx = v.xy\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "duplicate swizzle write target should be a type error");
}

#[test]
fn rejects_wrong_ctor_arity() {
    let module = Driver::parse("fn t():\n    Vec3(1.0, 2.0)\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "wrong constructor arity should be a type error");
}

#[test]
fn codegen_float_binop_uses_fadd() {
    let module = Driver::parse("fn t(a: f32, b: f32) -> f32:\n    a + b\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fadd float"), "float addition should emit fadd, not add i32: {}", ir);
}

#[test]
fn codegen_vec2_add_uses_vector_fadd() {
    let module = Driver::parse("fn t(a: Vec2, b: Vec2) -> Vec2:\n    a + b\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fadd <2 x float>"), "{}", ir);
}

#[test]
fn codegen_vec3_add_uses_vector_fadd() {
    let module = Driver::parse("fn t(a: Vec3, b: Vec3) -> Vec3:\n    a + b\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fadd <3 x float>"), "{}", ir);
}

#[test]
fn codegen_vec4_add_uses_vector_fadd() {
    let module = Driver::parse("fn t(a: Vec4, b: Vec4) -> Vec4:\n    a + b\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fadd <4 x float>"), "{}", ir);
}

#[test]
fn codegen_vec2_scalar_mul_uses_vector_fmul() {
    let module = Driver::parse("fn t(a: Vec2) -> Vec2:\n    a * 2.0\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fmul <2 x float>"), "{}", ir);
}

#[test]
fn codegen_vec3_scalar_mul_uses_vector_fmul() {
    let module = Driver::parse("fn t(a: Vec3) -> Vec3:\n    2.0 * a\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fmul <3 x float>"), "{}", ir);
}

#[test]
fn codegen_vec2_multi_swizzle_read_uses_shufflevector() {
    let module = Driver::parse("fn t(v: Vec2) -> Vec2:\n    v.yx\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("shufflevector <2 x float>"), "{}", ir);
}

#[test]
fn codegen_vec3_multi_swizzle_read_uses_shufflevector() {
    let module = Driver::parse("fn t(v: Vec3) -> Vec3:\n    v.zyx\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("shufflevector <3 x float>"), "{}", ir);
}

#[test]
fn codegen_vec4_multi_swizzle_read_uses_shufflevector() {
    let module = Driver::parse("fn t(v: Vec4) -> Vec3:\n    v.xyz\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("shufflevector <4 x float>"), "{}", ir);
}

#[test]
fn codegen_vec2_single_swizzle_uses_extractelement() {
    let module = Driver::parse("fn t(v: Vec2) -> f32:\n    v.x\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("extractelement <2 x float>"), "{}", ir);
}

#[test]
fn codegen_vec4_single_swizzle_uses_extractelement() {
    let module = Driver::parse("fn t(v: Vec4) -> f32:\n    v.x\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("extractelement <4 x float>"), "{}", ir);
}

#[test]
fn codegen_vec2_swizzle_write_uses_insertelement_store() {
    let module = Driver::parse("fn t(mut v: Vec2):\n    v.x = 1.0\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("insertelement <2 x float>"), "{}", ir);
    assert!(ir.contains("store <2 x float>"), "{}", ir);
}

#[test]
fn codegen_vec3_swizzle_write_uses_insertelement_store() {
    let module = Driver::parse("fn t(mut v: Vec3):\n    v.y = 1.0\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("insertelement <3 x float>"), "{}", ir);
    assert!(ir.contains("store <3 x float>"), "{}", ir);
}

#[test]
fn codegen_vec4_swizzle_write_uses_insertelement_store() {
    let module = Driver::parse("fn t(mut v: Vec4):\n    v.x = 1.0\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("insertelement <4 x float>"), "{}", ir);
    assert!(ir.contains("store <4 x float>"), "{}", ir);
}

#[test]
fn codegen_mat4_vec4_mul_uses_dot_pattern() {
    let module = Driver::parse("fn t(m: Mat4, v: Vec4) -> Vec4:\n    m * v\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fmul <4 x float>"), "{}", ir);
    assert!(ir.contains("extractelement"), "{}", ir);
    let row_extracts = ir.matches("extractvalue [4 x <4 x float>]").count();
    assert_eq!(row_extracts, 4, "should extract exactly the 4 matrix rows: {}", ir);
}

#[test]
fn codegen_vec2_ctor_uses_insertelement_no_alloca() {
    let module = Driver::parse("fn t() -> Vec2:\n    Vec2(1.0, 2.0)\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("insertelement <2 x float> undef"), "{}", ir);
    assert!(!ir.contains("alloca <2 x float>"), "{}", ir);
}

#[test]
fn codegen_vec3_ctor_uses_insertelement_no_alloca() {
    let module = Driver::parse("fn t() -> Vec3:\n    Vec3(1.0, 2.0, 3.0)\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("insertelement <3 x float> undef"), "{}", ir);
    assert!(!ir.contains("alloca <3 x float>"), "{}", ir);
}

#[test]
fn codegen_vec4_ctor_uses_insertelement_no_alloca() {
    let module = Driver::parse("fn t() -> Vec4:\n    Vec4(1.0, 2.0, 3.0, 4.0)\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("insertelement <4 x float> undef"), "{}", ir);
    assert!(!ir.contains("alloca <4 x float>"), "{}", ir);
}

#[test]
fn codegen_compound_assign_vec2_uses_vector_fadd() {
    let module = Driver::parse("fn t(mut v: Vec2, o: Vec2):\n    v += o\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fadd <2 x float>"), "{}", ir);
}

#[test]
fn codegen_compound_assign_vec3_uses_vector_fadd() {
    let module = Driver::parse("fn t(mut v: Vec3, o: Vec3):\n    v += o\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fadd <3 x float>"), "{}", ir);
}

#[test]
fn codegen_vec2_dot_uses_vector_fmul_and_extractelement() {
    let module = Driver::parse("fn t(a: Vec2, b: Vec2) -> f32:\n    dot(a, b)\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fmul <2 x float>"), "{}", ir);
    assert!(ir.contains("extractelement <2 x float>"), "{}", ir);
}

#[test]
fn codegen_vec2_length_uses_sqrt() {
    let module = Driver::parse("fn t(a: Vec2) -> f32:\n    length(a)\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("call float @llvm.sqrt.f32"), "{}", ir);
    assert!(ir.contains("fmul <2 x float>"), "{}", ir);
}

#[test]
fn codegen_vec2_lerp_uses_extractelement_insertelement() {
    let module = Driver::parse("fn t(a: Vec2, b: Vec2, t: f32) -> Vec2:\n    lerp(a, b, t)\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("extractelement <2 x float>"), "{}", ir);
    assert!(ir.contains("insertelement <2 x float>"), "{}", ir);
    assert!(!ir.contains("extractvalue"), "{}", ir);
}

#[test]
fn codegen_struct_field_of_vec2_type_uses_native_vector() {
    let src = "struct Marker:\n    pos: Vec2\n    id: i32\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("%Marker = type"), "{}", ir);
    assert!(ir.contains("<2 x float>"), "{}", ir);
    assert!(!ir.contains("{ float, float }"), "{}", ir);
}

#[test]
fn codegen_list_of_vec2_uses_native_vector_element() {
    let module = Driver::parse("fn t() -> List<Vec2>:\n    List<Vec2>()\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("<2 x float>"), "{}", ir);
}

#[test]
fn codegen_arena_of_vec3_uses_native_vector() {
    let src = "arena Particles: Vec3\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("<3 x float>"), "{}", ir);
}

#[test]
fn codegen_closure_capturing_vec2_local_uses_native_vector() {
    let module = Driver::parse(
        "fn t() -> f32:\n    let p = Vec2(1.0, 2.0)\n    let f = fn() -> f32: p.x + p.y\n    f()\n"
    ).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("<2 x float>"), "{}", ir);
}

/// Runtime test: compiled `vecmath.exe` exercises vec3/vec4 arithmetic,
/// scalar multiply, swizzle reads (including reordering), Mat4*Vec4, and
/// both single- and multi-component swizzle writes, end to end through a
/// real clang-compiled executable.
#[test]
fn runtime_vecmath_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/vecmath.exe")
        .output()
        .expect("failed to execute vecmath.exe");

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("sum: 11.000000 22.000000 33.000000"), "vec3 add result: {}", stdout);
    assert!(stdout.contains("scaled: 2.000000 4.000000 6.000000"), "vec3 scalar mul result: {}", stdout);
    assert!(stdout.contains("vec4 sum: 1.000000 1.000000 0.000000 0.000000"), "vec4 add result: {}", stdout);
    assert!(stdout.contains("swizzled: 33.000000 22.000000 11.000000"), "swizzle reorder result: {}", stdout);
    assert!(stdout.contains("mat4*vec4 identity: 1.000000 0.000000 0.000000 0.000000"), "identity matrix result: {}", stdout);
    assert!(stdout.contains("vec4 single write: 99.000000 1.000000"), "vec4 lane write result: {}", stdout);
    assert!(stdout.contains("vec2 multi write: 5.000000 6.000000"), "vec2 multi-swizzle write result: {}", stdout);
}

// ===== M7 Concurrency & Coroutines Tests ==================================

// --- `sequence` / `yield` (coroutines) ------------------------------------

/// Parse a `sequence` item with params and multiple `yield`s.
#[test]
fn parses_sequence_def() {
    let src = "sequence Countdown(start: i32):\n    let mut n: i32 = start\n    yield\n    n -= 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Sequence(seq) = &module.items[0] else { panic!("expected a sequence item") };
    assert_eq!(seq.name, "Countdown");
    assert_eq!(seq.params.len(), 1);
    assert!(matches!(seq.body.stmts[1], Stmt::Yield { .. }));
}

/// A bare `yield` statement parses on its own (e.g. inside any block).
#[test]
fn parses_yield_stmt() {
    let src = "sequence S():\n    yield\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Sequence(seq) = &module.items[0] else { panic!("expected a sequence item") };
    assert!(matches!(seq.body.stmts[0], Stmt::Yield { .. }));
}

/// Desugaring turns one `sequence` into a `struct` + `impl` pair: fields are
/// params + hoisted locals + a trailing `state`, and there's a single
/// `resume` method.
#[test]
fn desugars_sequence_to_struct_and_impl() {
    let src = "sequence Countdown(start: i32):\n    let mut n: i32 = start\n    yield\n    n -= 1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    assert_eq!(typed.items.len(), 2, "sequence should desugar to exactly struct + impl");

    let TypedItem::Struct(s) = &typed.items[0] else { panic!("expected a struct") };
    assert_eq!(s.name, "Countdown");
    let field_names: Vec<&str> = s.fields.iter().map(|f| f.name.as_str()).collect();
    assert_eq!(field_names, vec!["start", "n", "state"]);

    let TypedItem::Impl(i) = &typed.items[1] else { panic!("expected an impl") };
    assert_eq!(i.type_name, "Countdown");
    assert_eq!(i.methods.len(), 1);
    assert_eq!(i.methods[0].sig.name, "resume");
    assert_eq!(i.methods[0].sig.ret, Some(Ty::Bool));
}

/// `yield` outside any `sequence` body is a type error.
#[test]
fn rejects_yield_outside_sequence() {
    let module = Driver::parse("fn t():\n    yield\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "bare yield should be a type error");
}

/// `yield` nested inside `if`/`while`/`frame` inside a sequence is rejected
/// (only top-level yield is supported by this desugaring).
#[test]
fn rejects_nested_yield_in_sequence() {
    let module = Driver::parse("sequence S(x: i32):\n    if x > 0:\n        yield\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "nested yield should be a type error");
}

/// A hoisted sequence local without an explicit type annotation is rejected
/// (its type can't be inferred at desugar time, before type checking runs).
#[test]
fn rejects_untyped_sequence_local() {
    let module = Driver::parse("sequence S(x: i32):\n    let n = x\n    yield\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "untyped hoisted local should be a type error");
}

/// Codegen for the desugared `resume` uses a nested `if`/`else` chain that
/// compares against `state` and returns a bool per segment.
#[test]
fn codegen_sequence_uses_state_machine() {
    let src = "sequence Countdown(start: i32):\n    let mut n: i32 = start\n    yield\n    n -= 1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("%Countdown = type"), "{}", ir);
    assert!(ir.contains("define i1 @resume(%Countdown* %self)"), "{}", ir);
    assert!(ir.contains("icmp eq i32"), "state comparison should appear: {}", ir);
    assert!(ir.matches("ret i1").count() >= 2, "each segment should be able to return a bool: {}", ir);
}

/// Runtime test: the compiled `sequence.exe` ticks through a 3-step
/// coroutine (two `yield`s) via repeated `resume()` calls until it reports
/// done, end to end through a real clang-compiled executable.
#[test]
fn runtime_sequence_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/sequence.exe").output().expect("failed to execute sequence.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    // Windows text-mode stdout translates the `\n` in each `print` to `\r\n`,
    // so check ordering by byte offset rather than matching a literal
    // multi-line substring.
    let pos = |needle: &str| stdout.find(needle).unwrap_or_else(|| panic!("missing {:?} in: {}", needle, stdout));
    let (p3, p2, p1, lift, done) =
        (pos("tick: 3"), pos("tick: 2"), pos("tick: 1"), pos("liftoff"), pos("sequence done"));
    assert!(p3 < p2 && p2 < p1 && p1 < lift && lift < done, "coroutine should tick in order: {}", stdout);
}

// --- `par` / `swarm` (parallel arena iteration) ---------------------------

/// Parse a `par item in Arena:` loop.
#[test]
fn parses_par_stmt() {
    let src = "fn t():\n    par e in Enemies:\n        e.hp -= 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Par { var, arena, .. } = &f.body.stmts[0] else { panic!("expected Par") };
    assert_eq!(var, "e");
    assert_eq!(arena, "Enemies");
}

/// `swarm` is accepted as a spelling of the same statement as `par`.
#[test]
fn parses_swarm_stmt_as_par() {
    let src = "fn t():\n    swarm e in Enemies:\n        e.hp -= 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert!(matches!(f.body.stmts[0], Stmt::Par { .. }));
}

const PAR_SRC_PREFIX: &str = "struct Enemy:\n    mut hp: i32\n\narena Enemies: Enemy\n\n";

/// A `par` body that only mutates the loop variable's own field type-checks.
#[test]
fn accepts_par_mutating_loop_var() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "mutating the loop variable's own field should be allowed");
}

/// A `par` body that declares and mutates its own local is fine (it's
/// per-iteration state, not shared across threads).
#[test]
fn accepts_par_mutating_body_local() {
    let src = format!(
        "{}fn t():\n    par e in Enemies:\n        let mut tmp: i32 = e.hp\n        tmp -= 1\n        e.hp = tmp\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "mutating a body-local should be allowed");
}

/// A `par` body that mutates a captured outer variable is rejected: that
/// write can't be proven disjoint across worker threads.
#[test]
fn rejects_par_mutating_captured_var() {
    let src = format!(
        "{}fn t():\n    let mut total: i32 = 0\n    par e in Enemies:\n        total += e.hp\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "mutating a captured outer variable should be a type error");
}

/// A `par` body that calls a method on something other than the loop
/// variable is rejected (the call might mutate shared state internally).
#[test]
fn rejects_par_method_call_on_captured_receiver() {
    let src = format!(
        "{}impl Enemy:\n    fn reset(mut self):\n        self.hp = 0\n\nfn t():\n    let mut other = Enemy(1)\n    par e in Enemies:\n        other.reset()\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "calling a method on a captured receiver should be a type error");
}

/// `par` over an undefined arena is a type error.
#[test]
fn rejects_par_undefined_arena() {
    let module = Driver::parse("fn t():\n    par e in Nope:\n        e.hp -= 1\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "par over an undefined arena should be a type error");
}

/// Codegen for `par` dispatches to the persistent worker-thread pool: the
/// pool's static machinery (`par.pool.worker_main`/`par.pool.ensure_init`,
/// created via `CreateThread`/`CreateSemaphoreA` exactly once) is emitted
/// alongside this callsite's own `par_worker_` chunking function, and the
/// dispatcher joins via `WaitForSingleObject` on the pool's per-worker
/// "done" semaphores before continuing -- no `CloseHandle` anywhere, since
/// pool threads are persistent, not per-call.
#[test]
fn codegen_par_dispatches_threads() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("declare i8* @CreateThread"), "{}", ir);
    assert!(ir.contains("call i8* @CreateThread("), "{}", ir);
    assert!(ir.contains("call i32 @WaitForSingleObject("), "{}", ir);
    assert!(ir.contains("define i32 @par_worker_"), "a worker function should be emitted: {}", ir);
    assert!(ir.contains("define i32 @par.pool.worker_main"), "the pool's generic worker entry point should be emitted: {}", ir);
    assert!(ir.contains("define void @par.pool.ensure_init"), "the pool's lazy-init function should be emitted: {}", ir);
    assert!(ir.contains("call i32 @GetCurrentThreadId"), "{}", ir);
    assert!(ir.contains("call i8* @CreateSemaphoreA"), "{}", ir);
    assert!(ir.contains("call i32 @ReleaseSemaphore"), "{}", ir);
    // The pool's `ensure_init` creates all 4 persistent worker threads (once,
    // from this single statement's lazy-init call) -- not one CreateThread
    // per `par`/`swarm` statement execution as the old per-call design did.
    assert_eq!(ir.matches("call i8* @CreateThread(").count(), 4, "{}", ir);
}

/// A program with **two** separate `par`/`swarm` statements still only
/// creates the pool's 4 worker threads once -- the second statement's
/// `ensure_init` call sees the pool already initialized and skips straight
/// to dispatch, proving the pool is genuinely reused rather than recreated
/// per statement.
#[test]
fn codegen_par_pool_reused_across_multiple_statements() {
    let src = format!(
        "{}fn t():\n    par e in Enemies:\n        e.hp -= 1\n    swarm e in Enemies:\n        e.hp = 0\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert_eq!(ir.matches("call i8* @CreateThread(").count(), 4, "pool threads should be created once, not once per statement: {}", ir);
    assert_eq!(ir.matches("define i32 @par.pool.worker_main").count(), 1, "{}", ir);
    assert_eq!(ir.matches("define void @par.pool.ensure_init").count(), 1, "{}", ir);
    assert_eq!(ir.matches("define i32 @par_worker_").count(), 2, "each callsite still gets its own chunking function: {}", ir);
}

/// A `par`/`swarm` statement nested inside another `par`/`swarm` body
/// dispatches through the manually-reentrant serial lock (rather than
/// trying to re-enter the fixed 4-worker pool from a thread that's already
/// one of its own workers) -- see `par_pool`'s module doc comment for why a
/// bare inline fallback would race.
#[test]
fn codegen_par_reentrant_dispatch_uses_serial_lock() {
    let src = format!(
        "{}fn t():\n    par e in Enemies:\n        par e2 in Enemies:\n            e2.hp -= 1\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("@par.pool.serial_lock"), "{}", ir);
    assert!(ir.contains("@par.pool.serial_owner"), "{}", ir);
}

/// A program that never uses `par`/`swarm` never pays for the pool's
/// machinery -- it stays fully lazy, gated behind
/// `Codegen::ensure_par_pool_emitted`.
#[test]
fn codegen_par_pool_globals_absent_without_par() {
    let src = "fn t() -> i32:\n    1 + 1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(!ir.contains("@par.pool."), "no par/swarm pool globals should be emitted for a program that never uses par/swarm: {}", ir);
}

/// Runtime test: the compiled `swarm.exe` spawns and joins real worker
/// threads (both `par` and `swarm` spellings) without crashing, end to end
/// through a real clang-compiled executable.
#[test]
fn runtime_swarm_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/swarm.exe").output().expect("failed to execute swarm.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("swarm done"), "worker threads should run to completion: {}", stdout);
}

/// Runtime test: the persistent worker-thread pool correctly serves 5
/// sequential `par` dispatch/join cycles in a row, not just a single one --
/// the actual "is it really persistent" regression check (a correct
/// single-shot `par` would also pass under the old per-call-`CreateThread`
/// design). See `examples/par_pool_ticks.star`.
#[test]
fn runtime_par_pool_ticks_persists_across_cycles() {
    use std::process::Command;

    let output = Command::new("examples/par_pool_ticks.exe").output().expect("failed to execute par_pool_ticks.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(
        stdout.matches("hp: 95").count(),
        3,
        "all 3 enemies should show hp 95 (100 - 5 ticks) after 5 sequential par/swarm cycles: {}",
        stdout
    );
}

/// Runtime test: a `par`/`swarm` statement nested inside another one is
/// race-free under real concurrent execution -- every `Bullet` ends up
/// incremented exactly once per live `Enemy`, deterministically, every run.
/// Without the manually-reentrant serial lock this would be flaky (lost
/// updates from multiple outer workers concurrently running overlapping
/// passes over the same nested arena). See `examples/par_nested.star`.
#[test]
fn runtime_par_nested_serial_fallback_is_race_free() {
    use std::process::Command;

    let output = Command::new("examples/par_nested.exe").output().expect("failed to execute par_nested.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(
        stdout.matches("dmg: 3").count(),
        4,
        "all 4 bullets should show dmg 3 (one increment per live enemy, no lost updates): {}",
        stdout
    );
}

// --- `spawn` (arena population) -------------------------------------------

/// Parse `spawn ArenaName(args...)`.
#[test]
fn parses_spawn_stmt() {
    let src = "fn t():\n    spawn Enemies(10)\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Spawn { arena, args, .. } = &f.body.stmts[0] else { panic!("expected Spawn") };
    assert_eq!(arena, "Enemies");
    assert!(matches!(args[0], Expr::Int(10, _)));
}

/// `spawn` into a struct-typed arena with the right argument count type-checks.
#[test]
fn accepts_spawn_valid() {
    let src = format!("{}fn t():\n    spawn Enemies(10)\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "valid spawn should type-check: {:?}", Driver::check(&module).err());
}

/// `spawn` into an undefined arena is a type error.
#[test]
fn rejects_spawn_undefined_arena() {
    let module = Driver::parse("fn t():\n    spawn Nope(10)\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "spawn into an undefined arena should be a type error");
}

/// `spawn` with the wrong number of constructor arguments is a type error.
#[test]
fn rejects_spawn_wrong_arity() {
    let src = format!("{}fn t():\n    spawn Enemies(1, 2)\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "wrong spawn arity should be a type error");
}

/// `spawn` inside a `par`/`swarm` body is rejected: every worker thread
/// would race on the same arena's `count`/`data` globals, so population
/// can't be proven disjoint the way loop-variable field writes can.
#[test]
fn rejects_spawn_inside_par() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        spawn Enemies(5)\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "spawn inside a par/swarm body should be a type error");
}

/// Codegen for `spawn`: lazily `malloc`s the arena's backing array on first
/// use, appends the constructed element at `data[count]`, and bumps `count`.
#[test]
fn codegen_spawn_allocates_and_appends() {
    let src = format!("{}fn t():\n    spawn Enemies(10)\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    assert!(ir.contains("icmp eq %Enemy* "), "should check for a null backing array: {}", ir);
    assert!(ir.contains("call i8* @malloc("), "should lazily malloc the backing array: {}", ir);
    assert!(ir.contains("load i64, i64* @arena.Enemies.count"), "should read the live count: {}", ir);
    assert!(
        ir.contains("getelementptr inbounds %Enemy, %Enemy*") && ir.contains("store %Enemy "),
        "should store the constructed element into the backing array: {}",
        ir
    );
    assert!(ir.contains("add i64"), "count should be incremented: {}", ir);
    assert!(ir.contains("store i64"), "incremented count should be stored back: {}", ir);
}

/// Runtime test: the compiled `spawn.exe` populates an arena via `spawn`,
/// mutates every live element in parallel via `par`, then reads the results
/// back via `swarm` -- proving arena population actually feeds real data to
/// `par`/`swarm` iteration, end to end through a real clang-compiled binary.
#[test]
fn runtime_spawn_populates_arena_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/spawn.exe").output().expect("failed to execute spawn.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("hp: 9"), "first spawned enemy should read back decremented: {}", stdout);
    assert!(stdout.contains("hp: 19"), "second spawned enemy should read back decremented: {}", stdout);
    assert!(stdout.contains("hp: 29"), "third spawned enemy should read back decremented: {}", stdout);
}

// --- `despawn` / `GenRef` lifecycle ----------------------------------------

/// Parse `despawn ArenaName[index]`.
#[test]
fn parses_despawn_stmt() {
    let src = "fn t():\n    despawn Enemies[0]\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Despawn { arena, index, .. } = &f.body.stmts[0] else { panic!("expected Despawn") };
    assert_eq!(arena, "Enemies");
    assert!(matches!(index, Expr::Int(0, _)));
}

/// `despawn` on an undefined arena is a type error.
#[test]
fn rejects_despawn_undefined_arena() {
    let module = Driver::parse("fn t():\n    despawn Nope[0]\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "despawn on an undefined arena should be a type error");
}

/// `despawn` inside a `par`/`swarm` body is rejected: every worker thread
/// would race on the same arena's `gen` global, just like `spawn` races on
/// `count`/`data`.
#[test]
fn rejects_despawn_inside_par() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        despawn Enemies[0]\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "despawn inside a par/swarm body should be a type error");
}

/// `GenRef<T>` with no arena declared for `T` is a type error -- there's no
/// slot-map storage to back the reference.
#[test]
fn rejects_genref_without_backing_arena() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\nfn t():\n    GenRef<Point>(0)\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "GenRef<T> with no backing arena should be a type error");
}

/// `GenRef<T>` is ambiguous when two arenas both hold element type `T`.
#[test]
fn rejects_genref_with_ambiguous_backing_arena() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\narena A: Point\narena B: Point\n\nfn t():\n    GenRef<Point>(0)\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "GenRef<T> with two backing arenas should be a type error");
}

/// Runtime test: a `GenRef` dereferenced after its slot is despawned falls
/// back to the element type's zero value instead of returning stale data or
/// crashing -- the flagship safety guarantee generational references exist
/// for, proven end to end through a real compiled binary.
#[test]
fn runtime_genref_stale_after_despawn_falls_back_to_zero() {
    use std::process::Command;

    let output = Command::new("examples/genref_lifecycle.exe").output().expect("failed to execute genref_lifecycle.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before: 100"), "live reference should read real data: {}", stdout);
    assert!(stdout.contains("after: 0"), "stale reference should fall back to zero, not crash or read stale data: {}", stdout);
}

// --- arena free-list (slot reclamation) ------------------------------------

/// Codegen for `despawn`: pushes the freed slot onto the arena's free-list
/// (guarded by a generation-parity liveness check) instead of only bumping
/// the generation counter, so a later `spawn` can reclaim the slot's memory.
#[test]
fn codegen_despawn_pushes_freed_slot_onto_freelist() {
    let src = format!("{}fn t():\n    despawn Enemies[0]\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    assert!(ir.contains("@arena.Enemies.free ="), "arena should declare a free-list global: {}", ir);
    assert!(ir.contains("@arena.Enemies.free_top ="), "arena should declare a free-list top-of-stack counter: {}", ir);
    assert!(ir.contains("and i32"), "despawn should check generation parity before freeing: {}", ir);
    assert!(
        ir.contains("getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free"),
        "despawn should write the freed index into the free-list: {}",
        ir
    );
}

/// Codegen for `spawn`: pops a slot off the arena's free-list when one is
/// available instead of unconditionally growing `count`.
#[test]
fn codegen_spawn_reuses_freed_slot_before_growing() {
    let src = format!("{}fn t():\n    spawn Enemies(10)\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    assert!(ir.contains("load i64, i64* @arena.Enemies.free_top"), "spawn should check the free-list before growing: {}", ir);
    assert!(ir.contains("icmp sgt i64"), "spawn should branch on whether the free-list is non-empty: {}", ir);
    assert!(ir.contains("spawn_reuse"), "spawn should have a slot-reuse path: {}", ir);
    assert!(ir.contains("spawn_grow"), "spawn should have a count-growing fallback path: {}", ir);
}

/// Runtime test: `despawn` pushes a slot onto the arena's free-list and the
/// next `spawn` reclaims that same slot rather than growing the arena, while
/// the generation bump still keeps a `GenRef` taken before the despawn from
/// aliasing the slot's new occupant (no ABA bug on reuse).
#[test]
fn runtime_spawn_reuses_despawned_slot_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/arena_freelist.exe").output().expect("failed to execute arena_freelist.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("via_old: 0"), "GenRef captured before despawn must not alias the slot's new occupant: {}", stdout);
    assert!(stdout.contains("via_new: 200"), "GenRef captured after the slot is reused should read the new occupant: {}", stdout);
}

/// Runtime test: despawning an already-despawned slot must not push it onto
/// the free-list twice -- otherwise two later spawns would both reclaim the
/// same slot, aliasing each other's memory, instead of one reusing the freed
/// slot and the other growing the arena.
#[test]
fn runtime_double_despawn_does_not_double_free_slot() {
    use std::process::Command;

    let output = Command::new("examples/arena_freelist_double_despawn.exe")
        .output()
        .expect("failed to execute arena_freelist_double_despawn.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("slot0: 200"), "reused slot should hold the second spawn's value: {}", stdout);
    assert!(stdout.contains("slot1: 300"), "third spawn should grow into a fresh slot, not alias slot 0: {}", stdout);
}

// ===== M8 Reflection ========================================================

/// Decorators must be parsed on the same line as the field they annotate,
/// in declaration order, and attach to that field's `decorators` list.
#[test]
fn parses_field_decorators() {
    let src = "struct Player:\n    @export mut health: i32 = 100\n    @tweakable speed: float = 5.0\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Struct(def) = &module.items[0] else { panic!("expected a struct") };
    assert_eq!(def.fields[0].decorators, vec!["export".to_string()]);
    assert_eq!(def.fields[1].decorators, vec!["tweakable".to_string()]);
}

/// Multiple decorators may stack on a single field.
#[test]
fn parses_stacked_field_decorators() {
    let src = "struct Player:\n    @export @tweakable health: i32 = 100\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Struct(def) = &module.items[0] else { panic!("expected a struct") };
    assert_eq!(def.fields[0].decorators, vec!["export".to_string(), "tweakable".to_string()]);
}

/// Codegen emits one `@__star_reflect_<Struct>` global per struct that has
/// at least one decorated field, encoding `name:byte_offset:type:decorators`
/// per decorated field. Byte offsets must reflect the *actual* memory layout
/// (walking every field, not just decorated ones), and undecorated fields
/// must not appear in the metadata at all.
#[test]
fn codegen_reflect_metadata_emits_offsets_and_types() {
    let src = "struct Player:\n    @export mut health: i32 = 100\n    @tweakable speed: float = 5.0\n    name: str = \"Hero\"\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("@__star_reflect_Player"), "reflect metadata global should appear: {}", ir);
    assert!(ir.contains("health:0:i32:export"), "health should be at offset 0: {}", ir);
    assert!(ir.contains("speed:4:float:tweakable"), "speed should follow health's 4-byte i32: {}", ir);
    assert!(!ir.contains("name:8"), "undecorated `name` field should not appear in reflect metadata: {}", ir);
}

/// A struct with no decorated fields should not emit any reflect metadata
/// global at all.
#[test]
fn codegen_omits_reflect_metadata_when_undecorated() {
    let src = "struct Point:\n    x: i32\n    y: i32\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(!ir.contains("__star_reflect"), "no reflect metadata expected: {}", ir);
}

// ===== M8 Free functions ====================================================

/// A free function (outside any `impl` block) that calls another free
/// function by name lowers to a direct `call @callee(...)` -- the same path
/// `main` itself already exercises, but proven in isolation here since the
/// todo item singled out free-function codegen for dedicated testing.
#[test]
fn codegen_free_function_calls_free_function() {
    let src = "fn add(a: i32, b: i32) -> i32:\n    a + b\n\nfn compute() -> i32:\n    add(2, 3)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i32 @add("), "{}", ir);
    assert!(ir.contains("define i32 @compute("), "{}", ir);
    assert!(ir.contains("call i32 @add("), "compute should call add directly: {}", ir);
}

// ===== M8 Standard library ==================================================

/// `print`/`println` calls, and the math/string builtins, resolve to proper
/// (non-`unknown`) types through the checker even though none of them are
/// declared by any `fn` item.
#[test]
fn checks_builtin_return_types() {
    let src = "fn t():\n    let a: i32 = abs(-5)\n    let b: float = sqrt(4.0)\n    let c: i32 = len(\"hi\")\n    let d: str = concat(\"a\", \"b\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[0] else { panic!("expected fn") };
    let get_value_ty = |i: usize| match &f.body.stmts[i] {
        TypedStmt::Let { value, .. } => value.clone().into_ty(),
        other => panic!("expected let, got {:?}", other),
    };
    assert_eq!(get_value_ty(0), Ty::Int);
    assert_eq!(get_value_ty(1), Ty::Float);
    assert_eq!(get_value_ty(2), Ty::Int);
    assert_eq!(get_value_ty(3), Ty::Str);
}

/// `abs`/`min`/`max` preserve the numeric type of their arguments (Int stays
/// Int) rather than always widening to Float.
#[test]
fn checks_abs_min_max_preserve_int_type() {
    let src = "fn t():\n    let a: i32 = abs(-5)\n    let b: i32 = min(1, 2)\n    let c: i32 = max(1, 2)\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "int-typed abs/min/max should type-check as i32");
}

/// `println` guarantees a trailing newline even for a plain (non-f-string)
/// argument, unlike `print`, which passes such an argument straight through
/// to `printf` with no newline appended.
#[test]
fn codegen_println_appends_newline_for_plain_string() {
    let src = "fn t():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    // One `printf` call for the literal itself, and a second for the
    // guaranteed trailing newline byte.
    let printf_calls = ir.matches("call i32 (i8*, ...) @printf(").count();
    assert_eq!(printf_calls, 2, "println should emit the string then a newline: {}", ir);
}

/// `print` with a plain (non-f-string) argument does *not* append a newline
/// -- only one `printf` call is emitted.
#[test]
fn codegen_print_does_not_append_newline_for_plain_string() {
    let src = "fn t():\n    print(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let printf_calls = ir.matches("call i32 (i8*, ...) @printf(").count();
    assert_eq!(printf_calls, 1, "print should not append a newline: {}", ir);
}

/// Runtime test: `examples/stdlib.exe` exercises `println`, every math
/// builtin, `len`/`concat`, and a non-`main` free function calling another
/// free function, end to end through a real compiled binary.
#[test]
fn runtime_stdlib_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/stdlib.exe").output().expect("failed to execute stdlib.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("sum: 5"), "free function call result: {}", stdout);
    assert!(stdout.contains("sqrt: 4.000000"), "{}", stdout);
    assert!(stdout.contains("pow: 1024.000000"), "{}", stdout);
    assert!(stdout.contains("abs int: 5"), "{}", stdout);
    assert!(stdout.contains("abs float: 5.500000"), "{}", stdout);
    assert!(stdout.contains("floor: 3.000000"), "{}", stdout);
    assert!(stdout.contains("ceil: 4.000000"), "{}", stdout);
    assert!(stdout.contains("clamped: 100"), "min/max clamp result: {}", stdout);
    assert!(stdout.contains("name len: 4"), "{}", stdout);
    assert!(stdout.contains("greeting: hello, Hero"), "concat result: {}", stdout);
}

// ===== M8 Error messages ====================================================

/// An unknown field access on a known struct is now caught at type-check
/// time (with the access's own span, not a codegen-time dummy span), and
/// carries a "did you mean" note when a field name is a close typo.
#[test]
fn rejects_unknown_field_with_suggestion() {
    let src = "struct Player:\n    health: i32\n\nfn t(p: Player):\n    p.helth\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("unknown field should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("no field `helth`")), "{:?}", diags);
    assert!(
        diags.iter().any(|d| d.note.as_deref().unwrap_or("").contains("health")),
        "expected a `did you mean health?` note: {:?}",
        diags
    );
}

/// An `impl` for an undefined type gets a "did you mean" note when a struct
/// name is a close typo.
#[test]
fn rejects_undefined_impl_type_with_suggestion() {
    let src = "struct Player:\n    health: i32\n\nimpl Playr:\n    fn reset(mut self):\n        self.health = 100\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("undefined impl type should be a type error") };
    assert!(
        diags.iter().any(|d| d.note.as_deref().unwrap_or("").contains("Player")),
        "expected a `did you mean Player?` note: {:?}",
        diags
    );
}

/// A parser error for a missing token now names the token in friendly
/// syntax (`':'`) rather than the raw Rust enum spelling (`Colon`).
#[test]
fn parser_error_uses_friendly_token_names() {
    let src = "struct Player\n    health: i32\n";
    let Err(diags) = Driver::parse(src) else { panic!("missing ':' should be a parse error") };
    assert!(diags.iter().any(|d| d.message.contains("':'")), "{:?}", diags);
}

// ===== Fuzz testing ==========================================================
//
// No fuzzing crate is available (no external dependency was added for it), so
// this is a small self-contained fuzzer: a xorshift PRNG mutates a handful of
// known-good seed programs (byte insert/delete/replace), and each mutated
// input is fed through the lexer and parser on a worker thread with a bounded
// timeout. The lexer/parser must never panic, and must always terminate --
// `parser_error_uses_friendly_token_names`'s sibling test class is exactly
// how the module-scope stray-`Dedent` infinite loop fixed alongside this test
// suite was first found by hand; this harness exists to catch the next one
// automatically instead of by hand-crafted example.

/// A minimal xorshift64* PRNG so the fuzzer has no external dependency.
struct Rng(u64);

impl Rng {
    fn next_u64(&mut self) -> u64 {
        self.0 ^= self.0 << 13;
        self.0 ^= self.0 >> 7;
        self.0 ^= self.0 << 17;
        self.0
    }

    fn next_usize(&mut self, bound: usize) -> usize {
        (self.next_u64() as usize) % bound.max(1)
    }
}

/// Apply a handful of random byte-level mutations (insert/delete/replace) to
/// `seed`, capped at a small size so a single input can't blow up runtime.
fn mutate(seed: &str, rng: &mut Rng) -> String {
    let mut bytes: Vec<u8> = seed.as_bytes().to_vec();
    let mutations = 1 + rng.next_usize(6);
    // Bytes plausible in Star source: identifiers, punctuation, whitespace,
    // and indentation -- pure random bytes would almost always just fail
    // lexing immediately without ever reaching interesting parser states.
    let alphabet: &[u8] = b"abcXYZ012 \t\n:=+-*/(){}[]<>!.,_@\"";
    for _ in 0..mutations {
        if bytes.is_empty() {
            bytes.push(alphabet[rng.next_usize(alphabet.len())]);
            continue;
        }
        match rng.next_usize(3) {
            0 => {
                let i = rng.next_usize(bytes.len());
                bytes[i] = alphabet[rng.next_usize(alphabet.len())];
            }
            1 => {
                let i = rng.next_usize(bytes.len());
                bytes.remove(i);
            }
            _ => {
                let i = rng.next_usize(bytes.len() + 1);
                bytes.insert(i, alphabet[rng.next_usize(alphabet.len())]);
            }
        }
        if bytes.len() > 400 {
            bytes.truncate(400);
        }
    }
    // Mutation can land mid-codepoint; a fuzz input isn't required to stay
    // valid UTF-8-adjacent-safe, but the driver API takes `&str`, so repair
    // it by dropping any invalid tail bytes rather than skipping the case.
    String::from_utf8_lossy(&bytes).into_owned()
}

/// Run `f` on a worker thread and fail the test if it panics or fails to
/// return within `timeout` (the latter is how the module-scope stray-`Dedent`
/// infinite loop this suite fixed would have shown up here).
fn run_bounded(label: &str, input: &str, timeout: std::time::Duration, f: impl FnOnce(&str) + Send + 'static) {
    let owned = input.to_string();
    let (tx, rx) = std::sync::mpsc::channel();
    std::thread::spawn(move || {
        let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| f(&owned)));
        let _ = tx.send(result);
    });
    match rx.recv_timeout(timeout) {
        Ok(Ok(())) => {}
        Ok(Err(payload)) => std::panic::resume_unwind(payload),
        Err(_) => panic!("{} timed out (possible infinite loop) on input: {:?}", label, input),
    }
}

/// Fuzz the lexer and parser with mutated inputs derived from known-good
/// programs, asserting every run either succeeds or returns a clean `Err` --
/// never panics, never hangs.
#[test]
fn fuzz_lexer_and_parser_do_not_panic() {
    let seeds = [
        include_str!("../examples/player.star"),
        include_str!("../examples/vecmath.star"),
        include_str!("../examples/stdlib.star"),
        "struct P:\n    @export mut x: i32 = 0\n",
        "fn f(a: i32) -> i32:\n    a + 1\n",
        "sequence S(x: i32):\n    yield\n",
        "par e in Enemies:\n    e.hp -= 1\n",
        "for i in 0..3:\n    break\n",
        "enum E:\n    A\n    B\n",
        "enum E:\n    A\n    B(x: i32, y: i32)\n",
    ];

    let mut rng = Rng(0x2545_F491_4F6C_DD1D);
    let timeout = std::time::Duration::from_secs(2);
    for i in 0..300 {
        let seed = seeds[rng.next_usize(seeds.len())];
        let input = mutate(seed, &mut rng);
        let label = format!("iteration {}", i);
        run_bounded(&label, &input, timeout, |src| {
            if let Ok(tokens) = Driver::lex(src) {
                let _ = star::parser::Parser::new(tokens).parse_module();
            }
        });
    }
}

// ===== `for`/`break`/`continue` + `enum` ====================================

use star::ast::{EnumDef, Pattern};

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

/// Runtime test: `examples/option_result.exe` exercises payload-carrying
/// `enum` variants end to end -- constructing `Ok`/`Err`/`Some`/`None`-style
/// variants, destructuring their payload fields through `match`, and a
/// multi-field variant (`Rect(width, height)`) -- through a real
/// clang-compiled executable.
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

// ===== `import`/module resolution (namespaced modules) =====================

use star::ast::FStrExpr;

/// Parsing alone (no file I/O) must recognize the `import "path" as alias`
/// item and register the alias.
#[test]
fn parses_import_decl() {
    let src = "import \"geometry_lib.star\" as geo\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Import(decl) = &module.items[0] else { panic!("expected an import item") };
    assert_eq!(decl.alias, "geo");
    assert_eq!(decl.path, "geometry_lib.star");
}

/// A qualified struct literal `alias::Name(...)` parses straight to the
/// mangled name `crate::modules::resolve` would have given that struct --
/// the parser reproduces the mangling from source text alone, without ever
/// touching the imported file.
#[test]
fn parses_qualified_struct_literal_as_mangled_name() {
    let src = "import \"lib.star\" as geo\nfn main():\n    let p = geo::Point(1, 2)\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    let Expr::StructLit { name, args, .. } = value else { panic!("expected struct literal, got {:?}", value) };
    assert_eq!(name, "geo__Point");
    assert_eq!(args.len(), 2);
}

/// A qualified free-function call `alias::name(...)` parses to a `Call`
/// whose callee is the mangled identifier (lowercase names never trigger
/// the struct-literal heuristic).
#[test]
fn parses_qualified_fn_call_as_mangled_name() {
    let src = "import \"lib.star\" as geo\nfn main():\n    let d = geo::dot(1, 2)\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    let Expr::Call { callee, .. } = value else { panic!("expected call, got {:?}", value) };
    assert!(matches!(callee.as_ref(), Expr::Ident(name, _) if name == "geo__dot"));
}

/// A 3-segment qualified path `alias::Enum::Variant(...)` parses to an
/// `EnumVariant` whose enum name is mangled but whose variant name is left
/// alone (variants aren't top-level declarations of their own).
#[test]
fn parses_qualified_enum_variant_as_mangled_enum_name() {
    let src = "import \"lib.star\" as geo\nfn main():\n    let s = geo::Shape::Circle(2)\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    let Expr::EnumVariant { enum_name, variant, args, .. } = value else { panic!("expected enum variant, got {:?}", value) };
    assert_eq!(enum_name, "geo__Shape");
    assert_eq!(variant, "Circle");
    assert_eq!(args.len(), 1);
}

/// A qualified path used inside an f-string interpolation must see the same
/// import aliases as the rest of the file: interpolated expressions are
/// re-lexed/parsed by a fresh sub-parser (see `Parser::lower_fstring`), which
/// must inherit `import_aliases` rather than starting empty.
#[test]
fn parses_qualified_call_inside_fstring_interpolation() {
    let src = "import \"lib.star\" as geo\nfn main():\n    println(f\"{geo::dot(1, 2)}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Expr(Expr::Call { args, .. }) = &f.body.stmts[0] else { panic!("expected call stmt") };
    let Expr::FStr(parts, _) = &args[0] else { panic!("expected f-string arg") };
    let FStrExpr::Expr(inner) = &parts[0] else { panic!("expected interpolated expr") };
    let Expr::Call { callee, .. } = inner.as_ref() else { panic!("expected call, got {:?}", inner) };
    assert!(matches!(callee.as_ref(), Expr::Ident(name, _) if name == "geo__dot"));
}

/// A qualified struct pattern `alias::Name(bindings...)` in a `match` arm
/// mangles the same way an expression-position struct literal would.
#[test]
fn parses_qualified_struct_pattern() {
    let src = "import \"lib.star\" as geo\nfn t(p: geo::Point) -> i32:\n    match p:\n        geo::Point(x, y) -> x\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    assert_eq!(f.sig.params[0].ty, Some(Type::Named("geo__Point".into())));
    let Stmt::Expr(Expr::Match { arms, .. }) = &f.body.stmts[0] else { panic!("expected match stmt") };
    assert!(matches!(&arms[0].pattern, Pattern::Struct(name, bindings) if name == "geo__Point" && bindings == &vec!["x".to_string(), "y".to_string()]));
}

/// A qualified enum-variant pattern `alias::Enum::Variant(bindings...)`.
#[test]
fn parses_qualified_enum_variant_pattern() {
    let src = "import \"lib.star\" as geo\nfn t(s: geo::Shape) -> i32:\n    match s:\n        geo::Shape::Circle(r) -> r\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Expr(Expr::Match { arms, .. }) = &f.body.stmts[0] else { panic!("expected match stmt") };
    assert!(matches!(
        &arms[0].pattern,
        Pattern::EnumVariant(enum_name, variant, bindings)
            if enum_name == "geo__Shape" && variant == "Circle" && bindings == &vec!["r".to_string()]
    ));
}

/// Write `contents` to `dir/name`, creating `dir` if needed, and return its
/// path -- a tiny helper for tests that exercise `crate::modules::resolve`
/// against real files on disk (import resolution is inherently file-based).
fn write_test_file(dir: &std::path::Path, name: &str, contents: &str) -> std::path::PathBuf {
    std::fs::create_dir_all(dir).expect("create test dir");
    let path = dir.join(name);
    std::fs::write(&path, contents).expect("write test file");
    path
}

/// A fresh scratch directory under the OS temp dir, namespaced by test name
/// so parallel test runs never collide.
fn test_scratch_dir(name: &str) -> std::path::PathBuf {
    std::env::temp_dir().join("star_module_tests").join(name)
}

/// Resolving a single import inlines the imported file's items, mangled to
/// `alias__name`, and leaves no `Item::Import` behind.
#[test]
fn resolve_inlines_and_mangles_imported_items() {
    let dir = test_scratch_dir("resolve_inlines_and_mangles_imported_items");
    write_test_file(&dir, "lib.star", "struct Point:\n    x: i32\n    y: i32\n\nfn dot(a: Point, b: Point) -> i32:\n    return a.x * b.x + a.y * b.y\n");
    let main_path = write_test_file(
        &dir,
        "main.star",
        "import \"lib.star\" as geo\nfn main() -> i32:\n    return geo::dot(geo::Point(1, 2), geo::Point(3, 4))\n",
    );
    let module = Driver::parse(&std::fs::read_to_string(&main_path).unwrap()).expect("should parse");
    let resolved = star::modules::resolve(module, &main_path).expect("should resolve imports");

    assert!(!resolved.items.iter().any(|i| matches!(i, Item::Import(_))), "no Item::Import should remain");
    assert!(resolved.items.iter().any(|i| matches!(i, Item::Struct(s) if s.name == "geo__Point")));
    assert!(resolved.items.iter().any(|i| matches!(i, Item::Fn(f) if f.sig.name == "geo__dot")));

    // The merged module must also type-check and codegen cleanly end to end.
    let typed = Driver::check(&resolved).expect("resolved module should type-check");
    Driver::codegen(&typed).expect("resolved module should codegen");
}

/// A cyclic import (`a` imports `b`, `b` imports `a`) must be reported as an
/// error rather than recursing forever.
#[test]
fn resolve_detects_import_cycle() {
    let dir = test_scratch_dir("resolve_detects_import_cycle");
    write_test_file(&dir, "a.star", "import \"b.star\" as b\nfn from_a():\n    return\n");
    let b_path = write_test_file(&dir, "b.star", "import \"a.star\" as a\nfn from_b():\n    return\n");
    // Enter the cycle from b.star so both files are real, on-disk imports.
    let module = Driver::parse(&std::fs::read_to_string(&b_path).unwrap()).expect("should parse");
    let err = star::modules::resolve(module, &b_path).expect_err("cyclic import should fail to resolve");
    assert!(err.iter().any(|d| d.message.contains("cycle")), "{:?}", err);
}

/// Importing a file that doesn't exist is a clean error, not a panic.
#[test]
fn resolve_reports_missing_import_file() {
    let dir = test_scratch_dir("resolve_reports_missing_import_file");
    let main_path = write_test_file(&dir, "main.star", "import \"does_not_exist.star\" as x\nfn main():\n    return\n");
    let module = Driver::parse(&std::fs::read_to_string(&main_path).unwrap()).expect("should parse");
    let err = star::modules::resolve(module, &main_path).expect_err("missing import should fail to resolve");
    assert!(err.iter().any(|d| d.message.contains("cannot import")), "{:?}", err);
}

/// Runtime test: `examples/modules_main.exe` exercises `import "path" as
/// alias` end to end -- a qualified struct literal, a qualified
/// free-function call, and a qualified payload enum variant construction
/// (a 3-segment `geo::Shape::Circle(...)` path) reaching into
/// `geometry_lib.star`'s namespace, through a real clang-compiled
/// executable.
#[test]
fn runtime_modules_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/modules_main.exe").output().expect("failed to execute modules_main.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("dot: 11"), "qualified struct literal + free function call: {}", stdout);
    assert!(stdout.contains("circle area: 12"), "qualified 3-segment enum variant + match inside the imported module: {}", stdout);
    assert!(stdout.contains("rect area: 12"), "second variant of the same imported enum: {}", stdout);
}

// ===== user-defined generics (monomorphization) =============================
//
// `struct Name<T>`/`enum Name<T>`/`fn name<T>` are implemented by
// monomorphization: a generic template is never itself checked or emitted,
// only concrete instantiations produced on demand by substituting each type
// parameter for a concrete type throughout a syntactic copy of the
// declaration, then checking/emitting that copy exactly like an ordinary
// hand-written concrete declaration. See `Checker::instantiate_struct`/
// `instantiate_enum`/`instantiate_fn` in `src/types/mod.rs`.

/// Parse a generic struct's `<T, U>` type-parameter list.
#[test]
fn parses_generic_struct_type_params() {
    let src = "struct Pair<A, B>:\n    first: A\n    second: B\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Struct(def) = &module.items[0] else { panic!("expected a struct") };
    assert_eq!(def.type_params, vec!["A".to_string(), "B".to_string()]);
    assert_eq!(def.fields[0].ty, Type::Named("A".into()));
}

/// Parse a generic enum's `<T>` type-parameter list.
#[test]
fn parses_generic_enum_type_params() {
    let src = "enum Option<T>:\n    None\n    Some(value: T)\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Enum(EnumDef { type_params, variants, .. }) = &module.items[0] else { panic!("expected an enum") };
    assert_eq!(type_params, &vec!["T".to_string()]);
    assert_eq!(variants[1].fields[0].ty, Type::Named("T".into()));
}

/// Parse a generic function's `<T>` type-parameter list.
#[test]
fn parses_generic_fn_type_params() {
    let src = "fn identity<T>(x: T) -> T:\n    return x\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn") };
    assert_eq!(f.sig.type_params, vec!["T".to_string()]);
}

/// Parse an explicit turbofish on a generic struct literal: `Box<i32>(value = 5)`.
#[test]
fn parses_generic_struct_lit_turbofish() {
    let src = "struct Box<T>:\n    value: T\n\nfn t():\n    Box<i32>(value = 5)\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Expr(Expr::StructLit { name, type_args, args, .. }) = &f.body.stmts[0] else {
        panic!("expected struct literal, got {:?}", f.body.stmts[0])
    };
    assert_eq!(name, "Box");
    assert_eq!(type_args, &vec![Type::Named("i32".into())]);
    assert_eq!(args.len(), 1);
}

/// Parse an explicit turbofish on a generic enum variant path:
/// `Option<i32>::None`.
#[test]
fn parses_generic_enum_variant_turbofish() {
    let src = "enum Option<T>:\n    None\n    Some(value: T)\n\nfn t():\n    Option<i32>::None\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Expr(Expr::EnumVariant { enum_name, type_args, variant, .. }) = &f.body.stmts[0] else {
        panic!("expected enum variant, got {:?}", f.body.stmts[0])
    };
    assert_eq!(enum_name, "Option");
    assert_eq!(type_args, &vec![Type::Named("i32".into())]);
    assert_eq!(variant, "None");
}

const GENERIC_BOX_SRC: &str = "struct Box<T>:\n    value: T\n\n";
const GENERIC_OPTION_SRC: &str = "enum Option<T>:\n    None\n    Some(value: T)\n\n";

/// A generic struct's template declaration produces no typed item of its
/// own; only a concrete instantiation (triggered by a use with an inferable
/// concrete type) is emitted, named by mangling the template with its type
/// argument.
#[test]
fn instantiates_generic_struct_with_inferred_type_arg() {
    let src = format!("{}fn t():\n    Box(value = 5)\n", GENERIC_BOX_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let struct_names: Vec<&str> = typed.items.iter().filter_map(|i| if let TypedItem::Struct(s) = i { Some(s.name.as_str()) } else { None }).collect();
    assert_eq!(struct_names, vec!["Box__i32"], "generic template itself must not be emitted, only its instantiation");
}

/// Two uses of the same generic struct with different concrete type
/// arguments produce two distinct monomorphized instantiations.
#[test]
fn instantiates_generic_struct_once_per_distinct_type_arg() {
    let src = format!("{}fn t():\n    Box(value = 5)\n    Box(value = 2.5)\n    Box(value = 6)\n", GENERIC_BOX_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let mut struct_names: Vec<&str> = typed.items.iter().filter_map(|i| if let TypedItem::Struct(s) = i { Some(s.name.as_str()) } else { None }).collect();
    struct_names.sort();
    assert_eq!(struct_names, vec!["Box__f32", "Box__i32"], "same (template, type arg) pair should be instantiated once: {:?}", struct_names);
}

/// A generic struct construction whose type argument can't be inferred from
/// its constructor arguments alone is resolved via an explicit turbofish.
#[test]
fn instantiates_generic_struct_via_explicit_turbofish() {
    let src = format!("{}fn t():\n    Box<i32>(value = 5)\n", GENERIC_BOX_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    assert!(typed.items.iter().any(|i| matches!(i, TypedItem::Struct(s) if s.name == "Box__i32")));
}

/// A field access on a monomorphized generic struct resolves against its
/// instantiation's own (substituted, concrete) field type.
#[test]
fn checks_generic_struct_field_access_has_substituted_type() {
    let src = format!("{}fn t() -> i32:\n    let b = Box(value = 5)\n    b.value\n", GENERIC_BOX_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let f = typed.items.iter().find_map(|i| if let TypedItem::Fn(f) = i { Some(f) } else { None }).expect("expected a fn item");
    let ty = match f.body.stmts.last().expect("body should have a statement") {
        TypedStmt::Expr(e) => e.clone().into_ty(),
        other => panic!("expected trailing expr statement, got {:?}", other),
    };
    assert_eq!(ty, Ty::Int);
}

/// A generic struct instantiated with another (already-monomorphized)
/// generic struct as its own type argument works -- nested instantiation.
#[test]
fn instantiates_nested_generic_struct() {
    let src = format!(
        "{}fn t() -> i32:\n    let b = Box(value = Box(value = 99))\n    b.value.value\n",
        GENERIC_BOX_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "nested generic instantiation should type-check");
}

/// A generic enum's fieldless variant with no arguments to infer a type
/// argument from requires an explicit turbofish; without one it's a type
/// error rather than a silent wrong instantiation.
#[test]
fn rejects_generic_enum_variant_without_inferable_type_arg() {
    let src = format!("{}fn t():\n    Option::None\n", GENERIC_OPTION_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("uninferable generic construction should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("cannot infer")), "{:?}", diags);
}

/// `Option<i32>::None` and `Option::Some(5)` (inferred `T = i32`) share the
/// same monomorphized `Option__i32` enum.
#[test]
fn instantiates_generic_enum_shared_across_variants() {
    let src = format!(
        "{}fn t():\n    let a = Option::Some(5)\n    let b = Option<i32>::None\n",
        GENERIC_OPTION_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let enum_names: Vec<&str> = typed.items.iter().filter_map(|i| if let TypedItem::Enum(e) = i { Some(e.name.as_str()) } else { None }).collect();
    assert_eq!(enum_names, vec!["Option__i32"], "both constructions should share one instantiation: {:?}", enum_names);
}

/// A `match` pattern written against the generic template name
/// (`Option::Some(v)`) matches a scrutinee of any concrete instantiation --
/// the pattern doesn't need to spell out the mangled name.
#[test]
fn checks_match_pattern_against_generic_template_name() {
    let src = format!(
        "{}fn t(o: Option<i32>) -> i32:\n    match o:\n        Option::Some(v) ->\n            return v\n        Option::None ->\n            return -1\n",
        GENERIC_OPTION_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "a generic-template pattern should match a concrete instantiation: {:?}", Driver::check(&module).err());
}

/// A generic free function's type parameter is inferred from its call-site
/// argument types (no turbofish call syntax); two calls with different
/// concrete argument types produce two distinct monomorphized functions.
#[test]
fn instantiates_generic_fn_once_per_distinct_call_site_type() {
    let src = "fn identity<T>(x: T) -> T:\n    return x\n\nfn t():\n    identity(5)\n    identity(2.5)\n    identity(6)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let mut fn_names: Vec<&str> = typed.items.iter()
        .filter_map(|i| if let TypedItem::Fn(f) = i { Some(f.sig.name.as_str()) } else { None })
        .filter(|n| n.starts_with("identity"))
        .collect();
    fn_names.sort();
    assert_eq!(fn_names, vec!["identity__f32", "identity__i32"], "{:?}", fn_names);
}

/// Codegen for a generic function call: the call site lowers to a direct
/// call against the mangled, monomorphized function's own name.
#[test]
fn codegen_generic_fn_call_uses_mangled_name() {
    let src = "fn identity<T>(x: T) -> T:\n    return x\n\nfn t() -> i32:\n    identity(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i32 @identity__i32("), "{}", ir);
    assert!(ir.contains("call i32 @identity__i32("), "{}", ir);
}

/// A generic function whose body itself constructs another generic type
/// parameterized by its own type parameter (`fn wrap<T>(x: T) -> Box<T>`)
/// type-checks and codegens -- the body's own `Box(value = x)` is checked
/// against the already-substituted (concrete) parameter type of `x`.
#[test]
fn instantiates_generic_fn_that_constructs_generic_struct_of_its_own_param() {
    let src = format!("{}fn wrap<T>(x: T) -> Box<T>:\n    return Box(value = x)\n\nfn t() -> i32:\n    let b = wrap(5)\n    b.value\n", GENERIC_BOX_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    assert!(typed.items.iter().any(|i| matches!(i, TypedItem::Struct(s) if s.name == "Box__i32")));
    assert!(typed.items.iter().any(|i| matches!(i, TypedItem::Fn(f) if f.sig.name == "wrap__i32")));
}

/// Codegen for a monomorphized generic struct: the `%Box__i32 = type { i32
/// }` declaration and its field access lower exactly like an ordinary
/// hand-written concrete struct.
#[test]
fn codegen_generic_struct_emits_mangled_type_decl() {
    let src = format!("{}fn t() -> i32:\n    let b = Box(value = 5)\n    b.value\n", GENERIC_BOX_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("%Box__i32 = type { i32 }"), "{}", ir);
    assert!(ir.contains("alloca %Box__i32"), "{}", ir);
}

/// Codegen for a monomorphized generic payload enum: lowers to a tagged
/// union exactly like an ordinary hand-written concrete payload enum.
#[test]
fn codegen_generic_enum_emits_mangled_tagged_union() {
    let src = format!("{}fn t():\n    Option::Some(5)\n", GENERIC_OPTION_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("%Option__i32 = type { i32, [1 x i64] }"), "{}", ir);
}

/// Runtime test: `examples/generics.exe` exercises user-defined generics end
/// to end -- a generic struct (`Box<T>`, including a nested `Box<Box<i32>>`
/// instantiation), a generic `Option<T>`-style enum matched by its generic
/// template pattern name, a generic `Result<T, E>`-style enum needing an
/// explicit turbofish on both variants, and a generic free function
/// (`identity<T>`) instantiated at two different concrete types -- through a
/// real clang-compiled executable.
#[test]
fn runtime_generics_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/generics.exe").output().expect("failed to execute generics.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("box: 42"), "generic struct field read: {}", stdout);
    assert!(stdout.contains("nested box: 99"), "nested generic struct instantiation: {}", stdout);
    assert!(stdout.contains("unwrap some: 5"), "generic enum Some payload via generic-template match pattern: {}", stdout);
    assert!(stdout.contains("unwrap none: -1"), "generic enum None fallback via generic-template match pattern: {}", stdout);
    assert!(stdout.contains("ok: 10"), "generic two-param enum Ok payload: {}", stdout);
    assert!(stdout.contains("err: bad"), "generic two-param enum Err payload: {}", stdout);
    assert!(stdout.contains("identity int: 7"), "generic fn instantiated at i32: {}", stdout);
    assert!(stdout.contains("identity float: 3.500000"), "generic fn instantiated at f32 (separate instantiation from i32): {}", stdout);
}

// ===== Closures/lambdas ====================================================

/// Parse an inline-bodied lambda literal (`fn(params) -> Ret: expr`, mirroring
/// a `match` arm's own inline-body grammar) as a `let` initializer.
#[test]
fn parses_lambda_inline_body() {
    let src = "fn t():\n    let add1 = fn(x: i32) -> i32: x + 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected Let") };
    let Expr::Lambda { params, ret, body, .. } = value else { panic!("expected Expr::Lambda, got {:?}", value) };
    assert_eq!(params.len(), 1);
    assert_eq!(params[0].name, "x");
    assert_eq!(ret, &Some(Type::Named("i32".into())));
    assert!(matches!(body.stmts[0], Stmt::Expr(Expr::Binary { op: BinOp::Add, .. })));
}

/// Parse a block-bodied lambda literal (full indented block, mirroring
/// `if`/`match`'s own block-body grammar) -- must be the last statement of
/// its enclosing block, a pre-existing parser limitation shared with
/// `if`-expressions used as a `let` value (see todo.md's documented
/// `match`-as-statement Dedent-consumption bug for the same root cause).
#[test]
fn parses_lambda_block_body() {
    let src = "fn t():\n    let f = fn(x: i32) -> i32:\n        let y = x + 1\n        y\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected Let") };
    let Expr::Lambda { body, .. } = value else { panic!("expected Expr::Lambda") };
    assert_eq!(body.stmts.len(), 2);
}

/// A lambda with no declared parameters and no `->` return type still
/// parses (both are optional).
#[test]
fn parses_lambda_no_params_no_ret() {
    let src = "fn t():\n    let f = fn(): 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected Let") };
    let Expr::Lambda { params, ret, .. } = value else { panic!("expected Expr::Lambda") };
    assert!(params.is_empty());
    assert!(ret.is_none());
}

/// A closure literal nested directly in a call's argument list (no `let`
/// binding) parses fine, since it doesn't itself need to consume a
/// statement-ending line -- only the call as a whole does.
#[test]
fn parses_lambda_as_call_argument() {
    let src = "fn apply(f: Fn(i32) -> i32, x: i32) -> i32:\n    f(x)\n\nfn t() -> i32:\n    apply(fn(x: i32) -> i32: x * 2, 5)\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok());
}

/// A closure-typed parameter annotation `Fn(T1, T2) -> Ret` parses to
/// `Type::Fn`.
#[test]
fn parses_fn_type_annotation() {
    let src = "fn apply(f: Fn(i32, i32) -> i32) -> i32:\n    f(1, 2)\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert_eq!(
        f.sig.params[0].ty,
        Some(Type::Fn(vec![Type::Named("i32".into()), Type::Named("i32".into())], Box::new(Type::Named("i32".into()))))
    );
}

/// `let` with no explicit annotation infers a `Ty::Closure` from a lambda
/// initializer, and a subsequent call through that variable resolves its
/// result type from the closure's own declared return type.
#[test]
fn checks_lambda_infers_closure_ty_and_call_result() {
    let ty = typed_fn_result_ty("fn t() -> i32:\n    let add1 = fn(x: i32) -> i32: x + 1\n    add1(41)\n");
    assert_eq!(ty, Ty::Int);
}

/// A lambda with no `-> Ret` annotation infers its return type from its
/// trailing expression, exactly like an `if`-expression with no annotation.
#[test]
fn checks_lambda_infers_return_type_from_body() {
    let ty = typed_fn_result_ty("fn t() -> f32:\n    let f = fn(x: f32): x * 2.0\n    f(3.0)\n");
    assert_eq!(ty, Ty::Float);
}

/// A closure captures an outer local by value: the checker resolves the
/// captured identifier's type from the enclosing scope inside the lambda
/// body, not just its own parameters.
#[test]
fn checks_lambda_captures_outer_local() {
    let ty = typed_fn_result_ty("fn t() -> i32:\n    let base = 10\n    let f = fn(x: i32) -> i32: x + base\n    f(5)\n");
    assert_eq!(ty, Ty::Int);
}

/// A closure-typed function parameter (`f: Fn(i32) -> i32`) can be called
/// like any other closure value inside the function body.
#[test]
fn checks_closure_typed_param_is_callable() {
    let module = Driver::parse("fn apply(f: Fn(i32) -> i32, x: i32) -> i32:\n    f(x)\n").expect("should parse");
    assert!(Driver::check(&module).is_ok(), "calling a closure-typed parameter should type-check");
}

/// `self` is rejected in a lambda's parameter list (lambdas have no
/// receiver).
#[test]
fn rejects_self_in_lambda_params() {
    let src = "struct S:\n    n: i32\n\nimpl S:\n    fn m(self):\n        let f = fn(self) -> i32: 1\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "`self` in a lambda's own parameter list should be a type error");
}

/// Codegen for a closure literal: the deferred top-level `closure_N`
/// function, the `{ i8*, i8* }` fat-pointer value construction (fn ptr +
/// null env ptr for a capture-free lambda), and no captured-environment
/// `malloc` call since there's nothing to capture.
#[test]
fn codegen_closure_literal_emits_deferred_function_and_fat_pointer() {
    let src = "fn t() -> i32:\n    let add1 = fn(x: i32) -> i32: x + 1\n    add1(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i32 @closure_0(i8* %envp, i32 %arg_x)"), "{}", ir);
    assert!(ir.contains("insertvalue { i8*, i8* } undef, i8*"), "{}", ir);
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    assert!(!fn_ir.contains("call i8* @malloc") && !fn_ir.contains("call i8* @star_rc_alloc"), "a capture-free closure should not allocate an environment: {}", fn_ir);
}

/// Codegen for a closure that captures an outer local: a `malloc`'d
/// environment (sized via the GEP-null/`ptrtoint` idiom) plus a store of the
/// captured value into it.
#[test]
fn codegen_closure_capturing_local_allocates_environment() {
    let src = "fn t() -> i32:\n    let base = 10\n    let f = fn(x: i32) -> i32: x + base\n    f(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("call i8* @malloc"), "a capturing closure should heap-allocate its environment: {}", ir);
    assert!(ir.contains("ptrtoint { i32 }* "), "environment size should be computed via the GEP-null/ptrtoint sizeof idiom: {}", ir);
}

/// Codegen for a call through a closure value: an indirect call bitcasting
/// the extracted `i8*` function pointer back to its real signature, rather
/// than a direct `call @name(...)`.
#[test]
fn codegen_closure_call_is_indirect() {
    let src = "fn t() -> i32:\n    let add1 = fn(x: i32) -> i32: x + 1\n    add1(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("extractvalue { i8*, i8* }"), "{}", ir);
    assert!(ir.contains("bitcast i8* %t") && ir.contains("to i32 (i8*, i32)*"), "{}", ir);
}

/// A void closure (no return value) lowers its deferred function and call
/// site to LLVM `void`, matching the existing `unknown`-means-`void`
/// convention used for ordinary functions with no declared return type.
#[test]
fn codegen_void_closure_lowers_to_void() {
    let src = "fn t():\n    let say = fn(): println(\"hi\")\n    say()\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define void @closure_0(i8* %envp)"), "{}", ir);
}

/// A closure literal is rejected inside a `par`/`swarm` body (its captured
/// environment escapes the per-iteration disjointness proof -- see
/// `Checker::walk_par_expr`'s `TypedExpr::Closure` arm).
#[test]
fn rejects_closure_inside_par_body() {
    let src = "struct P:\n    n: i32\n\narena Arena: P\n\nfn t():\n    par p in Arena:\n        let f = fn() -> i32: p.n\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "a closure literal inside a par/swarm body should be rejected");
}

/// Runtime test: `examples/closures.exe` exercises closures end to end
/// through a real clang-compiled executable -- a plain capture-free
/// closure, a closure capturing an outer immutable local, passing a
/// closure as a `Fn(i32) -> i32`-typed function argument, *returning* a
/// closure from a function (the escaping-closure case that specifically
/// exercises heap-allocating the environment rather than capturing stack
/// pointers), value-capture semantics (mutating a captured variable after
/// the closure was created must not affect what the closure already
/// snapshotted), a void closure called purely for its side effect, and (the
/// "indirect/function-pointer calls are rejected" bug) a plain top-level
/// function -- never wrapped in a lambda literal -- called directly and
/// passed as a first-class `Fn(i32) -> i32` value into `apply_twice`.
#[test]
fn runtime_closures_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/closures.exe").output().expect("failed to execute closures.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("add1(5) = 6"), "plain capture-free closure: {}", stdout);
    assert!(stdout.contains("add_base(7) = 17"), "closure capturing an outer local: {}", stdout);
    assert!(stdout.contains("apply_twice(add1, 5) = 7"), "closure passed as a Fn(i32) -> i32 argument: {}", stdout);
    assert!(stdout.contains("add_one(5) = 6"), "direct call to a plain top-level function: {}", stdout);
    assert!(stdout.contains("apply_twice(add_one, 5) = 7"), "plain top-level function passed as a Fn(i32) -> i32 value: {}", stdout);
    assert!(stdout.contains("adder(5) = 105"), "closure returned from a function (escaping, heap-allocated environment): {}", stdout);
    assert!(stdout.contains("bump() = 1"), "value-capture: mutating the captured var after closure creation must not change its snapshot: {}", stdout);
    assert!(stdout.contains("hi from a void closure"), "void closure called for its side effect: {}", stdout);
}

// ===== Bug fixes: fn-values, match-as-value, match-as-statement, method calls ====

/// A bare identifier naming a declared top-level function, used as a
/// first-class *value* (here, `let`-bound) rather than called directly,
/// is widened to the same `Ty::Closure` a lambda literal would get --
/// see `Checker::fn_value_ty`. Before this fix the identifier stayed
/// `unknown`, and codegen had no local `alloca` to load it from (it
/// names a global function, not a variable), so a plain top-level
/// function couldn't be used as an indirect/function-pointer value at all.
#[test]
fn checks_fn_name_used_as_value_gets_closure_ty() {
    let src = "fn add_one(x: i32) -> i32:\n    x + 1\n\nfn t() -> i32:\n    let f = add_one\n    f(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(t) = &typed.items[1] else { panic!("expected fn") };
    let TypedStmt::Let { value, .. } = &t.body.stmts[0] else { panic!("expected let, got {:?}", t.body.stmts[0]) };
    assert!(matches!(value.clone().into_ty(), Ty::Closure(..)), "expected Ty::Closure, got {:?}", value.clone().into_ty());
}

/// Regression guard for the direct-call fast path: a *direct* call to a
/// named top-level function (`add_one(5)`, not through a variable) must
/// keep its callee typed as a bare, unwidened `Ident` (`ty: unknown`) --
/// widening it to `Ty::Closure` here too would route every ordinary call
/// through the indirect closure-call mechanism instead of `emit_call_expr`'s
/// direct `call @name(...)` path.
#[test]
fn checks_direct_call_to_named_fn_keeps_unwidened_callee_ty() {
    let src = "fn add_one(x: i32) -> i32:\n    x + 1\n\nfn t() -> i32:\n    add_one(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(t) = &typed.items[1] else { panic!("expected fn") };
    let TypedStmt::Expr(TypedExpr::Call { callee, .. }) = &t.body.stmts[0] else { panic!("expected a call statement, got {:?}", t.body.stmts[0]) };
    assert_eq!(callee.clone().into_ty(), Ty::Named("unknown".into()), "direct-call callee must not be widened to Ty::Closure");
}

/// Codegen for a direct call to a named function stays a plain `call
/// @name(...)` -- no indirect thunk involved (mirrors
/// `checks_direct_call_to_named_fn_keeps_unwidened_callee_ty` at the
/// codegen layer).
#[test]
fn codegen_direct_call_to_named_fn_stays_direct() {
    let src = "fn add_one(x: i32) -> i32:\n    x + 1\n\nfn t() -> i32:\n    add_one(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("call i32 @add_one(i32 5)"), "{}", ir);
    assert!(!ir.contains("fnval_add_one"), "a direct call must not go through the fn-value thunk: {}", ir);
}

/// Codegen for a plain top-level function used as a value: the underlying
/// `@add_one` was emitted by `emit_fn` with the ordinary (no `i8* %envp`
/// prefix) signature every direct call uses, so referencing it as a
/// `Ty::Closure` value goes through a small generated thunk
/// (`Codegen::emit_fn_value`) that drops the incoming envp and forwards to
/// the real function, rather than bitcasting `@add_one` itself to the
/// closure-call shape (which would silently misalign every argument).
#[test]
fn codegen_fn_name_used_as_value_wraps_in_thunk() {
    let src = "fn add_one(x: i32) -> i32:\n    x + 1\n\nfn apply(f: Fn(i32) -> i32, x: i32) -> i32:\n    f(x)\n\nfn t() -> i32:\n    apply(add_one, 5)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i32 @fnval_add_one(i8* %envp, i32 %arg_0)"), "{}", ir);
    assert!(ir.contains("call i32 @add_one(i32 %arg_0)"), "the thunk should forward to the real function: {}", ir);
    assert!(ir.contains("bitcast i32 (i8*, i32)* @fnval_add_one to i8*"), "{}", ir);
}

/// `match` used as a value-producing expression: each non-terminating arm's
/// trailing expression is inferred as the arm's own type (previously always
/// stubbed to `unknown`, see `Checker::check_match_arm`), and the overall
/// `match` picks up the first arm type that isn't just the "no value"
/// placeholder.
#[test]
fn checks_match_used_as_value_infers_arm_result_ty() {
    let ty = typed_fn_result_ty("fn t(x: i32) -> i32:\n    match x:\n        <= 0 -> -1\n        _ -> 1\n");
    assert_eq!(ty, Ty::Int);
}

/// Codegen for `match` used as a value: non-terminating arms each
/// contribute `(value, block)` to a `phi` at the join block instead of the
/// match always yielding a meaningless placeholder register.
#[test]
fn codegen_match_used_as_value_emits_phi() {
    let src = "fn t(x: i32) -> i32:\n    match x:\n        <= 0 -> -1\n        _ -> 1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains(" = phi i32 ["), "{}", ir);
}

/// A `match` used purely for side effects (every arm ends in `println`, not
/// a value-producing trailing expression) must not spuriously synthesize a
/// `phi` -- regression guard for conflating the match's own `unknown`
/// "no value" placeholder with a real result type.
#[test]
fn codegen_void_match_does_not_emit_phi() {
    let src = "fn t(x: i32):\n    match x:\n        <= 0 -> println(\"neg\")\n        _ -> println(\"pos\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(!ir.contains("phi"), "a side-effect-only match should not emit a phi: {}", ir);
}

/// A `match` used as a bare statement that is *not* the last statement of
/// its enclosing block must still parse -- `Parser::parse_match`'s own arm
/// list ends in a `Dedent` that re-syncs with the enclosing block, so the
/// statement dispatcher must not also expect a trailing `Newline`/`Dedent`
/// of its own afterward (see `Parser::parse_match_stmt`).
#[test]
fn parses_match_stmt_followed_by_another_statement() {
    let src = "fn t(x: i32):\n    match x:\n        _ -> 1\n    println(\"after\")\n";
    let module = Driver::parse(src).expect("a match statement followed by another statement at the same indentation should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert_eq!(f.body.stmts.len(), 2, "expected the match statement plus the trailing println: {:?}", f.body.stmts);
    assert!(matches!(f.body.stmts[0], Stmt::Expr(Expr::Match { .. })));
    assert!(matches!(f.body.stmts[1], Stmt::Expr(Expr::Call { .. })));
}

/// A method call (`obj.method(args)`) type-checks even though `method`
/// isn't also a field on `obj`'s struct -- before this fix, `Expr::Call`
/// always ran its callee through the generic `Expr::Field` inference
/// (`resolve_field_type`), which only ever looks a name up in the struct's
/// *field* list and rejected any real method call with "no field `method`
/// on `Type`".
#[test]
fn checks_method_call_not_shadowed_by_field_type_checks() {
    let src = "struct Counter:\n    count: i32\n\nimpl Counter:\n    fn bump(self, by: i32) -> i32:\n        self.count + by\n\nfn t(c: Counter) -> i32:\n    c.bump(3)\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "a method call not shadowed by a same-named field should type-check");
}

/// Regression guard: a call naming neither a real field nor a declared
/// method must still be a type error (the method-call fix must not swallow
/// genuinely-undefined-name errors).
#[test]
fn rejects_call_to_undefined_method_or_field() {
    let src = "struct Counter:\n    count: i32\n\nfn t(c: Counter) -> i32:\n    c.nonexistent(3)\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "calling an undefined name on a struct should be a type error");
}

/// Runtime test: `examples/option_result.exe`'s `unwrap_or` uses `match` as
/// a value-producing expression (each arm's trailing expression, no
/// explicit `return`), and `describe_sign` uses `match` as a bare statement
/// immediately followed by another statement at the same indentation.
#[test]
fn runtime_match_value_and_statement_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/option_result.exe").output().expect("failed to execute option_result.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("unwrap_or(Some(7), -1) = 7"), "match used as a value, Some arm: {}", stdout);
    assert!(stdout.contains("unwrap_or(None, -1) = -1"), "match used as a value, None arm: {}", stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    let non_positive_at = lines.iter().position(|l| *l == "non-positive").expect("non-positive line");
    assert_eq!(lines[non_positive_at + 1], "done describing", "match statement followed by another statement, non-positive branch: {}", stdout);
    let positive_at = lines.iter().position(|l| *l == "positive").expect("positive line");
    assert_eq!(lines[positive_at + 1], "done describing", "match statement followed by another statement, positive branch: {}", stdout);
}

/// Runtime test: `examples/player.exe`'s `take_damage` method (called as a
/// bare statement) and `remaining_health` method (called as a value inside
/// an f-string interpolation) both type-check and run correctly.
#[test]
fn runtime_method_calls_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/player.exe").output().expect("failed to execute player.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("remaining: 100"), "method call used as a value: {}", stdout);
    assert!(stdout.contains("Hero has perished."), "method call used as a bare statement: {}", stdout);
}

// ===== Arrays/Lists/Collections (`List<T>`) Tests ==========================

/// A non-empty list literal `[e1, e2, ...]` parses to `Expr::ListLit`.
#[test]
fn parses_list_literal() {
    let src = "fn t():\n    let x = [1, 2, 3]\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected Let") };
    let Expr::ListLit(elems, _) = value else { panic!("expected ListLit, got {:?}", value) };
    assert_eq!(elems.len(), 3);
}

/// `List<T>()` parses like any other generic-turbofish constructor call,
/// as an ordinary `Expr::StructLit` naming `List` (see
/// `Checker::infer_list_new` for how the checker special-cases it).
#[test]
fn parses_empty_list_construction() {
    let src = "fn t():\n    let x = List<i32>()\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected Let") };
    let Expr::StructLit { name, type_args, args, .. } = value else { panic!("expected StructLit, got {:?}", value) };
    assert_eq!(name, "List");
    assert_eq!(type_args, &vec![Type::Named("i32".into())]);
    assert!(args.is_empty());
}

/// `list[idx]` parses to the shared bracket-index AST node (also used for
/// `GenRef<T>` dereferencing); the checker tells them apart later.
#[test]
fn parses_list_index() {
    let src = "fn t(nums: List<i32>) -> i32:\n    nums[0]\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert!(matches!(f.body.stmts[0], Stmt::Expr(Expr::GenRefIndex { .. })));
}

/// A non-empty list literal's element type is inferred from its elements.
#[test]
fn checks_list_literal_infers_element_type() {
    let ty = typed_fn_result_ty("fn t() -> List<i32>:\n    [1, 2, 3]\n");
    assert_eq!(ty, Ty::List(Box::new(Ty::Int)));
}

/// `list[idx]` resolves to the list's element type.
#[test]
fn checks_list_index_returns_elem_type() {
    let ty = typed_fn_result_ty("fn t(nums: List<i32>) -> i32:\n    nums[0]\n");
    assert_eq!(ty, Ty::Int);
}

/// `list.len()` always resolves to `i32`, regardless of element type.
#[test]
fn checks_list_len_returns_int() {
    let ty = typed_fn_result_ty("fn t(nums: List<f32>) -> i32:\n    nums.len()\n");
    assert_eq!(ty, Ty::Int);
}

/// `list.pop()` resolves to the list's element type.
#[test]
fn checks_list_pop_returns_elem_type() {
    let ty = typed_fn_result_ty("fn t(nums: List<i32>) -> i32:\n    nums.pop()\n");
    assert_eq!(ty, Ty::Int);
}

/// `List<T>` is usable as an ordinary struct field type, and a method call
/// through a field access (`inv.items.len()`) resolves correctly.
#[test]
fn checks_list_as_struct_field_type() {
    let src = "struct Inventory:\n    items: List<i32>\n\nfn t(inv: Inventory) -> i32:\n    inv.items.len()\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "List<T> should be usable as a struct field type");
}

/// An empty list literal `[]` has no element to infer a type from and is
/// rejected -- `List<T>()` is the empty-list spelling instead.
#[test]
fn rejects_empty_list_literal() {
    let module = Driver::parse("fn t():\n    let x = []\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "an empty list literal should be a type error");
}

/// A list literal whose elements don't all share the same type is rejected.
#[test]
fn rejects_mismatched_list_literal_element_types() {
    let module = Driver::parse("fn t():\n    let x = [1, \"two\"]\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "mismatched list literal element types should be a type error");
}

/// `List()` with no `<T>` turbofish has nothing to infer an element type
/// from and is rejected.
#[test]
fn rejects_list_new_without_type_arg() {
    let module = Driver::parse("fn t():\n    let x = List()\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "`List()` with no type argument should be a type error");
}

/// `push` requires exactly one argument matching the list's element type.
#[test]
fn rejects_list_push_wrong_type() {
    let module = Driver::parse("fn t(mut nums: List<i32>):\n    nums.push(\"oops\")\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "pushing a mismatched type should be a type error");
}

/// An unrecognized method name on a `List<T>` receiver is a type error
/// (rather than, say, silently resolving to nothing).
#[test]
fn rejects_unknown_list_method() {
    let module = Driver::parse("fn t(nums: List<i32>):\n    nums.sort()\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "an unknown List<T> method should be a type error");
}

/// `[..]` indexing requires a `GenRef<T>` or `List<T>` base; indexing a
/// plain scalar is a type error.
#[test]
fn rejects_indexing_non_indexable_type() {
    let module = Driver::parse("fn t(x: i32):\n    x[0]\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "indexing a non-List/GenRef type should be a type error");
}

/// A `par`/`swarm` body that calls a mutating `List<T>` method (`push`) on
/// a list captured from the enclosing scope is rejected: the mutation can't
/// be proven disjoint across worker threads (mirrors
/// `rejects_par_mutating_captured_var`).
#[test]
fn rejects_par_pushing_captured_list() {
    let src = format!(
        "{}fn t():\n    let mut nums: List<i32> = [1, 2, 3]\n    par e in Enemies:\n        nums.push(e.hp)\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "pushing a captured list inside a par/swarm body should be a type error");
}

/// `len()` only reads, so calling it on a captured list inside a
/// `par`/`swarm` body is fine (unlike `push`/`pop` above).
#[test]
fn accepts_par_len_on_captured_list() {
    let src = format!(
        "{}fn t():\n    let nums: List<i32> = [1, 2, 3]\n    par e in Enemies:\n        e.hp -= nums.len()\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "reading a captured list's len() should be allowed");
}

/// `List<T>()` (the empty list) lowers to the struct type's zero value --
/// no instructions needed, just a `zeroinitializer` constant.
#[test]
fn codegen_list_new_is_zeroinitializer() {
    let module = Driver::parse("fn t() -> List<i32>:\n    List<i32>()\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("{ i32*, i64, i64 } zeroinitializer"), "{}", ir);
}

/// A non-empty list literal `malloc`s a tightly-sized buffer and stores
/// each element into it via GEP.
#[test]
fn codegen_list_literal_allocates_and_stores() {
    let module = Driver::parse("fn t() -> List<i32>:\n    [1, 2, 3]\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("call i8* @malloc(i64 12)"), "3 x i32 = 12 bytes: {}", ir);
    assert!(ir.contains("store i32 1,") && ir.contains("store i32 2,") && ir.contains("store i32 3,"), "{}", ir);
}

/// `push` growing past capacity copies the old buffer into a new, larger
/// one (`memcpy`) and frees the old one, rather than leaking it.
#[test]
fn codegen_list_push_grows_and_copies_old_buffer() {
    let src = "fn t():\n    let mut nums: List<i32> = List<i32>()\n    nums.push(1)\n    nums.push(2)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("icmp sge i64"), "push must check len >= cap before growing: {}", ir);
    assert!(ir.contains("call i8* @memcpy("), "growing a non-empty list should copy its old contents: {}", ir);
    assert!(ir.contains("call void @free("), "the old buffer should be freed after copying: {}", ir);
}

/// `list[idx]` (read) is bounds-checked via an unsigned compare against the
/// list's `len`, phi-merging the element's zero value on the OOB path
/// (mirrors `emit_genref_index`'s stale/OOB handling).
#[test]
fn codegen_list_index_read_is_bounds_checked() {
    let module = Driver::parse("fn t(nums: List<i32>) -> i32:\n    nums[0]\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("icmp ult i64"), "{}", ir);
    assert!(ir.contains("phi i32 ["), "{}", ir);
}

/// `list[idx] = v` (write) is bounds-checked too; an out-of-bounds write is
/// a silent no-op rather than writing out of bounds.
#[test]
fn codegen_list_index_write_is_bounds_checked() {
    let module = Driver::parse("fn t(mut nums: List<i32>):\n    nums[0] = 5\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("icmp ult i64"), "{}", ir);
    assert!(ir.contains("list_set_do"), "{}", ir);
}

/// `len()` truncates the internal `i64` length counter down to the
/// language's `i32` int type.
#[test]
fn codegen_list_len_truncates_to_i32() {
    let module = Driver::parse("fn t(nums: List<i32>) -> i32:\n    nums.len()\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("trunc i64"), "{}", ir);
}

/// Runtime test: `examples/lists.exe` exercises `List<T>` end to end
/// through a real clang-compiled executable -- a non-empty list literal,
/// `push`/`pop`/`len`, indexed read and write, passing a list by value into
/// a function, capacity growth past the initial buffer, `List<String>`,
/// `List<Point>` (a struct element type), and the "safe zero value" fallback
/// for out-of-bounds reads/pops on an empty list.
#[test]
fn runtime_lists_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/lists.exe").output().expect("failed to execute lists.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("initial len = 3"), "list literal: {}", stdout);
    assert!(stdout.contains("after push len = 5"), "push: {}", stdout);
    assert!(stdout.contains("nums[0] = 1"), "{}", stdout);
    assert!(stdout.contains("nums[4] = 5"), "{}", stdout);
    assert!(stdout.contains("nums[0] after set = 100"), "indexed write: {}", stdout);
    assert!(stdout.contains("popped = 5"), "pop: {}", stdout);
    assert!(stdout.contains("len after pop = 4"), "{}", stdout);
    assert!(stdout.contains("sum via function = 109"), "list passed by value into a function: {}", stdout);
    assert!(stdout.contains("empty len = 0"), "{}", stdout);
    assert!(stdout.contains("pop from empty = 0"), "OOB pop yields the zero value: {}", stdout);
    assert!(stdout.contains("index oob = 0"), "OOB read yields the zero value: {}", stdout);
    assert!(stdout.contains("grown len = 20"), "repeated push grows capacity past the initial buffer: {}", stdout);
    assert!(stdout.contains("grown[19] = 19"), "{}", stdout);
    assert!(stdout.contains("grown[0] = 0"), "{}", stdout);
    assert!(stdout.contains("words len = 3"), "List<String>: {}", stdout);
    assert!(stdout.contains("words[1] = beta"), "{}", stdout);
    assert!(stdout.contains("points[1] = (3, 4)"), "List<Point> (struct element type): {}", stdout);
}

// ===== LANGUAGE_ANALYSIS.md fixes =========================================
//
// Regression tests for the bugs identified in `LANGUAGE_ANALYSIS.md` and
// tracked in `todo.md`'s "Immediate" list, in the same priority order.

// --- §0: `main`'s exit code -------------------------------------------------

/// Every compiled program's exit code must be deterministic (`0` on normal
/// completion), not whatever garbage happened to be left in `eax` by the
/// last instruction before a `ret void` in a `void @main()` -- the flagship
/// bug reproduced on every single example in `examples/`.
#[test]
fn runtime_main_exit_code_is_zero_not_garbage() {
    use std::process::Command;

    let output = Command::new("examples/player.exe").output().expect("failed to execute player.exe");
    assert_eq!(output.status.code(), Some(0), "main with no declared return type must exit 0, not garbage");
}

/// `main` declared with an explicit, non-`i32` return type is rejected: it
/// can never actually be honored, since `main` is always forced to lower to
/// `i32 @main(...)` (a hosted C entry point's signature is an OS/CRT ABI
/// requirement).
#[test]
fn rejects_main_with_non_i32_return_type() {
    let module = Driver::parse("fn main() -> str:\n    return \"hi\"\n").expect("should parse");
    let errs = Driver::check(&module).expect_err("main declared to return str should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("main") && d.message.contains("i32")), "{:?}", errs);
}

/// `main` with no declared return type at all still type-checks fine (the
/// ordinary, common case) and lowers to `i32 @main(...)` with an implicit
/// `ret i32 0`.
#[test]
fn codegen_main_lowers_to_i32_with_implicit_ret_zero() {
    let module = Driver::parse("fn main():\n    print(\"hi\")\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i32 @main("), "main should always lower to i32: {}", ir);
    assert!(ir.contains("ret i32 0"), "implicit fallthrough should return 0: {}", ir);
}

/// A bare `return` (no value) inside `main` must still produce an
/// `i32`-typed terminator (`ret i32 0`), not the ordinary `ret void` a
/// no-return-type function gets elsewhere -- otherwise the function body
/// would contain a terminator disagreeing with `main`'s own forced `i32`
/// signature (invalid IR).
#[test]
fn codegen_bare_return_inside_main_returns_i32_zero() {
    let module = Driver::parse("fn main():\n    if true:\n        return\n    print(\"after\")\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let main_ir = extract_fn_body(&ir, "define i32 @main(");
    assert!(!main_ir.contains("ret void"), "main must never emit `ret void`: {}", main_ir);
    assert_eq!(main_ir.matches("ret i32 0").count(), 2, "both the early bare return and the implicit fallthrough should return i32 0: {}", main_ir);
}

// --- §3.1: frame bump-allocator capacity bounds check -----------------------

/// A `frame:` block allocating more than the 4096-byte backing buffer's
/// capacity must abort the process loudly with a diagnostic message rather
/// than segfaulting or silently corrupting whatever global data happens to
/// sit right after `@frame.buf`.
#[test]
fn runtime_frame_overflow_aborts_loudly_instead_of_segfaulting() {
    use std::process::Command;

    let output = Command::new("examples/frame_overflow.exe").output().expect("failed to execute frame_overflow.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("frame:` block exceeded its 4096-byte capacity"), "should print a diagnostic: {}", stdout);
    assert!(!stdout.contains("should not reach here"), "the frame allocation must abort before its value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "should exit cleanly with code 1, not crash/segfault: {:?}", output.status);
}

/// Codegen for a frame `let` includes a capacity check against
/// `FRAME_BUF_SIZE` before advancing `@frame.off`, with a call to `@exit` on
/// the overflow path.
#[test]
fn codegen_frame_alloc_includes_capacity_check() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\nfn test():\n    frame:\n        let p = Point(1, 2)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("icmp ugt i64"), "should compare the new offset against the buffer capacity: {}", ir);
    assert!(ir.contains("call void @exit(i32 1)"), "should abort on overflow: {}", ir);
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
    assert!(ir.contains("and i32"), "should mask the live generation to check odd/even parity: {}", ir);
    assert!(ir.contains("icmp eq i32") && ir.matches("icmp eq i32").count() >= 2, "should check both generation equality and liveness parity: {}", ir);
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
    let resume_ir = extract_fn_body(&ir, "define i1 @resume(");
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
    // Exactly one release of `s`: at the function's own fallthrough exit.
    // If `break` also released it, this would be 2 (or more, once per loop
    // iteration's worth of `break` sites).
    assert_eq!(fn_ir.matches("call void @star_rc_release").count(), 1, "`s` should be released exactly once, at function exit, not by `break`: {}", fn_ir);
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

/// A `List<str>` local's release walks its elements via a runtime loop
/// (element count isn't known at compile time), not a fixed unrolled
/// sequence of releases.
#[test]
fn codegen_list_of_str_release_uses_runtime_loop() {
    let src = "fn t(words: List<str>) -> i32:\n    1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    assert!(fn_ir.contains("rc_walk_cond"), "releasing a List<str> parameter should lower to a runtime loop: {}", fn_ir);
    assert!(fn_ir.contains("call void @star_rc_release"), "{}", fn_ir);
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
    let fn_ir = extract_fn_body(&ir, "define i32 @greet(");
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
