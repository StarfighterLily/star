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

/// Blank and comment-only lines must not produce structural tokens -- not
/// even a spurious `Newline` (previously `handle_line_start` measured and
/// discarded such a line's indentation but left its trailing `\n` for
/// `scan_line_content` to turn into an extra `Newline` token, which broke
/// `parse_block`'s bare `expect(Newline); expect(Indent)` when the block's
/// very first line was a comment -- see `parses_comment_as_first_line_of_block`).
#[test]
fn ignores_blank_and_comment_lines() {
    let src = "struct P:\n\n    # a comment\n    health: i32\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let indents = tokens.iter().filter(|t| t.kind == TokenKind::Indent).count();
    assert_eq!(indents, 1, "only one real indentation level expected");
    let newlines = tokens.iter().filter(|t| t.kind == TokenKind::Newline).count();
    assert_eq!(newlines, 2, "one Newline for `struct P:`, one for `health: i32` -- none for the blank/comment lines");
}

/// A comment as the very first line of an indented block (right after the
/// opening `:`) must not break indentation tracking -- previously this
/// produced "expected an indented block, found end of line" because the
/// comment line's spurious `Newline` (see `ignores_blank_and_comment_lines`)
/// landed exactly where `parse_block` expects `Indent`.
#[test]
fn parses_comment_as_first_line_of_block() {
    let src = "fn main():\n    # a leading comment\n    let x = 1\n";
    Driver::parse(src).expect("a comment as the first line of a block should parse");
}

/// Two consecutive comment/blank lines as the first lines of a block, to
/// guard the loop in `handle_line_start` (a single skip-and-return would
/// only have shifted the bug to this case).
#[test]
fn parses_consecutive_comments_as_first_lines_of_block() {
    let src = "fn main():\n    # first comment\n\n    # second comment\n    let x = 1\n";
    Driver::parse(src).expect("consecutive comment/blank lines as the first lines of a block should parse");
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
    // `List<Vec2>()` alone is just `null` -- no allocation, so no
    // element-typed payload struct is ever spelled out. A literal forces
    // the payload/release-thunk machinery to actually mention the element
    // type.
    let module = Driver::parse("fn t() -> List<Vec2>:\n    [Vec2(1.0, 2.0)]\n").expect("should parse");
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

/// A hoisted sequence local named `state` must be rejected -- `state: i32`
/// is unconditionally appended as the desugared struct's own resume-dispatch
/// counter field (`Sequence::desugar_sequence`), so a user-declared local of
/// the same name previously shared that one struct field with no renaming:
/// the coroutine's own "advance to next segment" write silently clobbered
/// whatever value the user's `state` local held, and vice versa, with no
/// diagnostic anywhere.
#[test]
fn rejects_sequence_local_named_state() {
    let module = Driver::parse("sequence S(x: i32):\n    let mut state: i32 = 5\n    yield\n    state += 1\n    yield\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("a sequence local named `state` should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("reserved field name")), "{:?}", diags);
}

/// Same fix, parameter side: a sequence parameter named `state` collides
/// with the same reserved dispatch field.
#[test]
fn rejects_sequence_param_named_state() {
    let module = Driver::parse("sequence S(state: i32):\n    yield\n    println(f\"{state}\")\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("a sequence parameter named `state` should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("reserved parameter name")), "{:?}", diags);
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
    assert!(ir.contains("define i1 @Countdown__resume(%Countdown* %self)"), "{}", ir);
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

/// Regression test: `@arena.{name}.count` is a high-water mark of
/// ever-allocated slots, not a live count -- `despawn` never decrements it,
/// only bumps the slot's generation and pushes it onto the free-list (see
/// `codegen_despawn_pushes_freed_slot_onto_freelist`). Before this fix, the
/// `par`/`swarm` worker loop walked `[start, end)` over that raw index range
/// with no liveness check at all, so it visited despawned "holes" exactly
/// like live slots -- for an RC-bearing element type this reads/retains a
/// pointer `despawn` already released (a use-after-free), and even for
/// plain data it processes an entity that's supposed to no longer exist.
/// The generated worker must gate each slot on its generation's parity
/// before running the loop body.
#[test]
fn codegen_par_worker_skips_despawned_slots() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let worker_ir = extract_fn_body(&ir, "define i32 @par_worker_0(");
    assert!(
        worker_ir.contains("@arena.Enemies.gen"),
        "par worker should check the slot's generation before visiting it: {}",
        worker_ir
    );
    assert!(worker_ir.contains("par_live"), "par worker should branch around despawned slots: {}", worker_ir);
    assert!(worker_ir.contains("par_incr"), "the increment/next-iteration path must be reachable whether or not a slot is skipped: {}", worker_ir);
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

/// Runtime regression test for the same bug `codegen_par_worker_skips_despawned_slots`
/// checks at the IR level, but exercised end to end against an RC-bearing
/// element field (`str`), where the consequence isn't just "wrong
/// results" but an actual use-after-free: `despawn` releases a dead slot's
/// `str` field (see `emit_despawn_stmt`), so a `par` body that reads it
/// (retaining an already-released/possibly-freed pointer, then releasing it
/// again at the end of that iteration) would previously crash or corrupt
/// the heap. Also verifies the still-live entities are correctly visited
/// and mutated, so the despawned-slot skip doesn't accidentally skip real
/// work too.
///
/// This test also caught a second, independent bug while it was being
/// written: `emit_par_stmt` swapped out `self.ir`/`self.symbols` for the
/// worker function's own but never did the same for `self.owned_stack`
/// (the release-at-scope-exit bookkeeping, see `rc.rs`), and never wrapped
/// the loop body in its own `push_scope`/`pop_scope` at all. An RC-owned
/// local declared inside the body (`let t: str = e.name`, right below) got
/// `track_owned`'d onto whatever scope frame happened to be open in the
/// *caller* at the time `par` was codegen'd, rather than the worker's own
/// -- so once codegen returned and the caller's frame was eventually
/// popped, it tried to release a register (`%tN`) that was only ever
/// defined in the worker function's separate IR buffer, producing invalid
/// IR ("use of undefined value") at the `clang` step regardless of the
/// despawn/generation-parity fix above. Fixed alongside it.
#[test]
fn runtime_par_skips_despawned_slot_end_to_end() {
    let src = concat!(
        "struct Enemy:\n",
        "    mut hp: i32\n",
        "    name: str\n",
        "arena Enemies: Enemy\n",
        "fn main():\n",
        "    spawn Enemies(1, \"keep-a\")\n",
        "    spawn Enemies(2, \"keep-b\")\n",
        "    spawn Enemies(3, \"dead-c\")\n",
        "    despawn Enemies[2]\n",
        "    par e in Enemies:\n",
        "        let t: str = e.name\n",
        "        e.hp -= 100\n",
        "    let r0 = GenRef<Enemy>(0)\n",
        "    let r1 = GenRef<Enemy>(1)\n",
        "    println(f\"hp0={r0[0].hp} hp1={r1[0].hp}\")\n",
    );
    let output = compile_and_run("par_skips_despawned", src);
    assert!(
        output.status.success(),
        "reading a despawned slot's already-released str field from inside par must not crash: {:?}\nstdout: {}\nstderr: {}",
        output.status,
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "hp0=-99 hp1=-98", "both still-live entities should still be visited and mutated: {}", stdout);
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

/// Reflect metadata offsets must account for real struct field alignment/
/// padding, not just naively sum each field's size -- previously
/// `emit_reflect_metadata` did exactly that naive sum, so any struct mixing
/// a sub-8-byte field (`bool`/`i32`/`float`) with an 8-byte-aligned one
/// (`str`/`List<T>`/a named struct/`ptr`) reported an offset that didn't
/// match the field's actual position in the compiled `%Player` LLVM struct
/// (confirmed against real LLVM layout: `{ i1, i32, i8*, float }` places
/// `flag` at 0, `health` at 4, `name` at 8, `speed` at 16 -- not the naive
/// sum's 0/1/5/13).
#[test]
fn codegen_reflect_metadata_offsets_account_for_field_alignment() {
    let src = "struct Player:\n    @export flag: bool = true\n    @export health: i32 = 100\n    @export name: str = \"Hero\"\n    @export speed: float = 5.0\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("flag:0:bool:export"), "{}", ir);
    assert!(ir.contains("health:4:i32:export"), "i32 needs 4-byte alignment after a 1-byte bool: {}", ir);
    assert!(ir.contains("name:8:str:export"), "str (pointer) needs 8-byte alignment: {}", ir);
    assert!(ir.contains("speed:16:float:export"), "{}", ir);
}

/// Spawning many instances of a struct whose fields need internal padding
/// (a `bool` followed by a `str`, real LLVM layout `{ i1, i8* }` = 16 bytes,
/// not the naive-sum 9 bytes) into an arena must not corrupt data or crash --
/// previously `emit_spawn_stmt` sized the backing `malloc` via
/// `Codegen::type_size`'s naive per-field sum (no alignment padding), while
/// every read/write through the buffer indexes it via `getelementptr`
/// against the real (larger) LLVM struct type, so the `malloc`'d buffer was
/// silently undersized relative to what `getelementptr` addressing actually
/// reached once enough elements were spawned -- a real, confirmed heap
/// buffer overflow (reproduced as a segfault against the pre-fix compiler
/// with exactly this struct shape and element count). Fixed by asking LLVM
/// itself for the real element size at codegen time
/// (`Codegen::emit_sizeof_llvm_ty`) rather than trusting a Rust-side
/// estimate.
#[test]
fn runtime_arena_of_padded_struct_spawns_past_naive_size_boundary_end_to_end() {
    let src = "struct Mixed:\n    flag: bool\n    tag: str\n\narena Items: Mixed\n\nfn main():\n    for i in 0..700:\n        spawn Items(true, f\"tag{i}\")\n    let r1 = GenRef<Mixed>(650)\n    println(r1[0].tag)\n    let r2 = GenRef<Mixed>(699)\n    println(r2[0].tag)\n    let r3 = GenRef<Mixed>(0)\n    println(r3[0].tag)\n";
    let output = compile_and_run("arena_padded_struct", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["tag650", "tag699", "tag0"], "{}", stdout);
}

/// Same fix, `List<T>` side: pushing many instances of a padding-needing
/// struct element type must not corrupt data (the grow path's `malloc`
/// sizing *and* its `memcpy` byte count both previously used the same
/// undersized `type_size` estimate, so growing would both under-allocate
/// the new buffer and under-copy -- silently truncating -- the existing
/// elements).
#[test]
fn runtime_list_of_padded_struct_push_past_growth_end_to_end() {
    let src = "struct Mixed:\n    flag: bool\n    tag: str\n\nfn main():\n    let mut xs: List<Mixed> = List<Mixed>()\n    for i in 0..200:\n        xs.push(Mixed(true, f\"tag{i}\"))\n    println(xs[150].tag)\n    println(xs[199].tag)\n    println(xs[0].tag)\n";
    let output = compile_and_run("list_padded_struct", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["tag150", "tag199", "tag0"], "{}", stdout);
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

/// `read_line()` (no arguments) resolves to `str` through the checker, same
/// as `concat`'s return type.
#[test]
fn checks_read_line_return_type() {
    let src = "fn t():\n    let line: str = read_line()\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[0] else { panic!("expected fn") };
    let TypedStmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    assert_eq!(value.clone().into_ty(), Ty::Str);
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

/// Runtime test: `examples/stdin.exe` exercises `read_line()` end to end
/// through a real compiled binary fed piped stdin, including reading past
/// the last available line (EOF), which should yield an empty `str` rather
/// than crashing or hanging.
#[test]
fn runtime_read_line_end_to_end() {
    use std::io::Write;
    use std::process::{Command, Stdio};

    let mut child = Command::new("examples/stdin.exe")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .expect("failed to spawn stdin.exe");
    child
        .stdin
        .take()
        .expect("child stdin should be piped")
        .write_all(b"Alice\nBob\n")
        .expect("failed to write to child stdin");
    let output = child.wait_with_output().expect("failed to wait on stdin.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("hello, Alice"), "first read_line() call: {}", stdout);
    assert!(stdout.contains("again: Bob"), "second read_line() call: {}", stdout);
    assert!(stdout.contains("last: "), "read_line() past EOF should yield an empty str, not crash: {}", stdout);
    assert_eq!(output.status.code(), Some(0));
}

/// A `read_line()` call whose input line is longer than the builtin's fixed
/// 1024-byte capacity is truncated rather than overflowing the buffer or
/// crashing -- same bounded-buffer trade-off `frame:` blocks already make
/// (see `Codegen::emit_read_line`).
#[test]
fn runtime_read_line_truncates_oversized_input() {
    use std::io::Write;
    use std::process::{Command, Stdio};

    let mut child = Command::new("examples/stdin.exe")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .expect("failed to spawn stdin.exe");
    let long_line = "a".repeat(2000);
    let input = format!("{}\nshort\n", long_line);
    child
        .stdin
        .take()
        .expect("child stdin should be piped")
        .write_all(input.as_bytes())
        .expect("failed to write to child stdin");
    let output = child.wait_with_output().expect("failed to wait on stdin.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains(&"a".repeat(1023)), "truncated line should keep its first 1023 bytes: {}", stdout);
    assert!(!stdout.contains(&"a".repeat(1024)), "truncated line should not exceed 1023 bytes: {}", stdout);
    assert_eq!(output.status.code(), Some(0));
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
/// `if`/`match`'s own block-body grammar).
#[test]
fn parses_lambda_block_body() {
    let src = "fn t():\n    let f = fn(x: i32) -> i32:\n        let y = x + 1\n        y\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected Let") };
    let Expr::Lambda { body, .. } = value else { panic!("expected Expr::Lambda") };
    assert_eq!(body.stmts.len(), 2);
}

/// A `let` bound to a block-bodied lambda, followed by another statement at
/// the *same* indentation as the `let` itself, must parse -- previously the
/// lambda body's own closing `Dedent` (which re-syncs with the enclosing
/// block) was consumed by the nested `parse_block`, leaving nothing for
/// `parse_let`'s own `expect_line_end()`, which then choked on the next
/// statement's first token ("expected end of line, found an integer
/// literal"). Exact repro from todo.md's "Immediate" section.
#[test]
fn parses_let_bound_block_lambda_followed_by_sibling_statement() {
    let src = "fn t() -> i32:\n    let c = fn() -> i32:\n        let y = 1\n        y\n    0\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert_eq!(f.body.stmts.len(), 2, "both the `let` and the trailing `0` must be parsed as sibling statements");
    assert!(matches!(f.body.stmts[0], Stmt::Let { .. }));
    assert!(matches!(f.body.stmts[1], Stmt::Expr(Expr::Int(0, _))));
}

/// The same Dedent-consumption root cause, but via an `if`-expression (not
/// an `if`-statement) used as a `let` value, followed by a sibling
/// statement -- covered by the same generic `block_just_closed` fix rather
/// than a lambda-specific patch.
#[test]
fn parses_let_bound_if_expr_followed_by_sibling_statement() {
    let src = "fn t(cond: bool) -> i32:\n    let x = if cond:\n        1\n    else:\n        2\n    x + 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert_eq!(f.body.stmts.len(), 2, "both the `let` and the trailing `x + 1` must be parsed as sibling statements");
    assert!(matches!(f.body.stmts[0], Stmt::Let { .. }));
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

/// A `match` compare-pattern's rhs can be a negative integer literal
/// (`<= -5`), which parses as `Expr::Unary { op: Neg, operand: Expr::Int }`
/// rather than `Expr::Int` directly (the lexer has no dedicated
/// negative-literal token) -- `Codegen::emit_expr`'s `Pattern::Compare` arm
/// previously only recognized a bare `Expr::Int` rhs and fell into its
/// "unsupported match rhs expression" error for anything else, so this
/// perfectly ordinary, type-checked syntax failed at the codegen step with a
/// confusing internal error instead of compiling.
#[test]
fn runtime_match_compare_pattern_against_negative_literal_end_to_end() {
    let src = "fn classify(x: i32) -> str:\n    match x:\n        <= -5 ->\n            return \"very low\"\n        < 0 ->\n            return \"low\"\n        _ ->\n            return \"other\"\n\nfn main():\n    println(classify(-10))\n    println(classify(-1))\n    println(classify(5))\n";
    let output = compile_and_run("match_compare_negative_literal", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["very low", "low", "other"], "{}", stdout);
}

/// A `Pattern::Binding` match arm (`v -> ...`) binds the *whole* scrutinee
/// value to a fresh name, and per `check_match_exhaustive`'s own doc comment
/// is treated as an unconditional catch-all -- but nothing ever actually
/// inserted that name into the arm's scope, so any use of it failed
/// type-checking with "undefined name" on every single use, making this
/// entire documented pattern kind unusable. Exercises an `i32` scrutinee.
#[test]
fn runtime_match_binding_pattern_int_scrutinee_end_to_end() {
    let src = "fn classify(x: i32) -> i32:\n    match x:\n        v -> v + 1\n\nfn main():\n    println(f\"{classify(5)}\")\n    println(f\"{classify(-3)}\")\n";
    let output = compile_and_run("match_binding_pattern_int", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["6", "-2"], "{}", stdout);
}

/// Same `Pattern::Binding` fix, `str` scrutinee: exercises the codegen path
/// where the scrutinee has no ready-made storage pointer of its own (unlike
/// a struct/payload-enum scrutinee) and the binding must spill the loaded
/// value into a fresh alloca before it can be registered as a local.
#[test]
fn runtime_match_binding_pattern_str_scrutinee_end_to_end() {
    let src = "fn describe(s: str) -> str:\n    match s:\n        v -> v\n\nfn main():\n    println(describe(\"hello\"))\n";
    let output = compile_and_run("match_binding_pattern_str", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "hello", "{}", stdout);
}

// ===== `if`/`match`-as-value phi-predecessor tracking =======================
//
// `TypedExpr::If`'s and `TypedExpr::Match`'s codegen merge each branch/arm's
// trailing value with a `phi` instruction at the join block, and previously
// hardcoded the *entry* label of that branch/arm (`if_then_N`/`match_then_N`)
// as the `phi`'s incoming-block operand. That's only correct if the branch's
// trailing value is computed with zero further control flow of its own --
// true for a literal or a plain scalar binop, but false for almost anything
// else: a short-circuit `&&`/`||`, a `list[i]`/`gen_ref[i]` bounds check, a
// `frame:` allocation, a nested `if`/`match`, all open their *own* basic
// blocks partway through evaluating the branch, so the block actually
// falling through to the join point is whichever of those was opened last,
// not the branch's original entry block. Using the stale label produced
// invalid LLVM IR ("PHI node entries do not match predecessors" / "Instruction
// does not dominate all uses"), rejected by `clang` at the very last pipeline
// stage, for any such branch value -- discovered while fixing a narrower,
// related gap (`Checker::trailing_value_ty` not recognizing a trailing
// `frame:` block, see the `frame_escape`/`trailing_value` tests below) that
// happened to unblock type-checking for the first repro case that exposed
// this. Fixed by threading `Codegen::current_label` (updated by the new
// `open_block` helper, the sole place any block is opened) through both
// `phi` sites instead of the stale entry labels.

/// The most common trigger: a short-circuit `&&`/`||` as the trailing value
/// of one arm of an `if` used as a value (via `return if ...`).
#[test]
fn runtime_if_value_branch_with_logical_and_end_to_end() {
    let src = "fn compute(cond: bool, a: bool, b: bool) -> bool:\n    return if cond:\n        a && b\n    else:\n        false\n\nfn main():\n    println(f\"{compute(true, true, true)}\")\n    println(f\"{compute(true, true, false)}\")\n    println(f\"{compute(false, true, true)}\")\n";
    let output = compile_and_run("if_value_logical_and", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "false", "false"], "{}", stdout);
}

/// Same bug, `list[idx]`'s own internal bounds-check block as the trigger.
#[test]
fn runtime_if_value_branch_with_list_index_end_to_end() {
    let src = "fn compute(cond: bool, nums: List<i32>) -> i32:\n    return if cond:\n        nums[0]\n    else:\n        -1\n\nfn main():\n    let mut nums = List<i32>()\n    nums.push(42)\n    println(f\"{compute(true, nums)}\")\n    println(f\"{compute(false, nums)}\")\n";
    let output = compile_and_run("if_value_list_index", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["42", "-1"], "{}", stdout);
}

/// Same bug, a trailing `frame:` block as the trigger -- exercises both the
/// codegen phi fix *and* the `Checker::trailing_value_ty`/`Expr::If` type
/// inference fix that made this construct type-check as `i32` (rather than
/// `void`) in the first place.
#[test]
fn runtime_if_value_branch_with_trailing_frame_end_to_end() {
    let src = "fn compute(cond: bool) -> i32:\n    return if cond:\n        frame:\n            let x = 5\n            x * 2\n    else:\n        0\n\nfn main():\n    println(f\"{compute(true)}\")\n    println(f\"{compute(false)}\")\n";
    let output = compile_and_run("if_value_trailing_frame", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["10", "0"], "{}", stdout);
}

/// Same bug, `match`-as-value side: a `Compare`-pattern arm's trailing value
/// opens its own blocks (`&&`), exercising the `Pattern::Compare`/
/// `Pattern::EnumVariant` arms' phi-predecessor fix.
#[test]
fn runtime_match_value_compare_arm_with_logical_and_end_to_end() {
    let src = "fn classify(x: i32, flag: bool) -> bool:\n    match x:\n        <= 0 -> flag && false\n        _ -> flag && true\n\nfn main():\n    println(f\"{classify(-1, true)}\")\n    println(f\"{classify(1, true)}\")\n";
    let output = compile_and_run("match_value_compare_logical_and", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "true"], "{}", stdout);
}

/// Same bug, `match`-as-value side: an `EnumVariant`-pattern arm's trailing
/// value opens its own blocks (`&&`), exercising the payload-enum path of
/// the same phi-predecessor fix.
#[test]
fn runtime_match_value_enum_variant_arm_with_logical_and_end_to_end() {
    let src = "enum IntOption:\n    None\n    Some(value: i32)\n\nfn describe(o: IntOption, flag: bool) -> bool:\n    match o:\n        IntOption::Some(v) -> flag && (v > 0)\n        IntOption::None -> false\n\nfn main():\n    println(f\"{describe(IntOption::Some(5), true)}\")\n    println(f\"{describe(IntOption::Some(-5), true)}\")\n    println(f\"{describe(IntOption::None, true)}\")\n";
    let output = compile_and_run("match_value_enum_variant_logical_and", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "false", "false"], "{}", stdout);
}

/// `Checker::check_frame_escapes`'s lookahead (`frame_escape_source_block`)
/// previously only recognized a bare trailing expression as a branch's
/// value, so a `frame:` block nested inside an `if`-expression's branch and
/// returned from the enclosing function silently skipped this whole safety
/// check -- a struct allocated inside that `frame:` block could be returned
/// with no diagnostic at all. Fixed alongside the type-inference gap above.
#[test]
fn rejects_frame_local_struct_escaping_through_if_value_branch() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\nfn make(cond: bool) -> Point:\n    return if cond:\n        frame:\n            let p = Point(1, 2)\n            p\n    else:\n        Point(0, 0)\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("returning a frame-local struct through an if-value branch should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("p") && d.message.contains("does not outlive")), "{:?}", errs);
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

/// `List<T>()` (the empty list) lowers to `null` -- no allocation needed
/// up front; a real, uniquely-owned empty object is only lazily allocated
/// by the copy-on-write gate the first time the list is actually mutated.
#[test]
fn codegen_list_new_is_null() {
    let module = Driver::parse("fn t() -> List<i32>:\n    List<i32>()\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("ret i8* null"), "{}", ir);
}

/// A non-empty list literal `malloc`s a tightly-sized buffer and stores
/// each element into it via GEP.
#[test]
fn codegen_list_literal_allocates_and_stores() {
    let module = Driver::parse("fn t() -> List<i32>:\n    [1, 2, 3]\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    // The element size is asked of LLVM itself at codegen time (`getelementptr
    // i32, i32* null, i32 1` + `ptrtoint`) rather than baked in as a Rust-side
    // constant -- see `Codegen::emit_sizeof_llvm_ty`'s doc comment (a
    // Rust-side estimate previously undersized any struct element type
    // needing internal padding, silently overflowing this buffer).
    assert!(ir.contains("getelementptr i32, i32* null, i32 1"), "element size should be computed via LLVM's own sizeof idiom: {}", ir);
    assert!(ir.contains("ptrtoint i32* ") && ir.contains(" to i64"), "{}", ir);
    assert!(ir.contains("call i8* @malloc(i64 "), "{}", ir);
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

/// A *nested* list-index read (`m[0][1]`, where `m`'s own element type is
/// itself a `List<T>`) must not trigger the copy-on-write uniqueness gate
/// on `m` -- `list_fields` (the read path) previously resolved a
/// `ListIndex` base through `Codegen::emit_place`, whose `ListIndex` arm
/// exists for *writes* and unconditionally runs `emit_list_ensure_unique`
/// (identifiable by the `list_cow_clone` block it emits) before returning a
/// pointer, silently cloning and un-aliasing `m` from any other variable
/// sharing its buffer as a side effect of a plain read. Fixed by resolving
/// the inner object through a dedicated, retain-free, COW-free read path
/// (`Codegen::list_index_read_obj`) instead.
#[test]
fn codegen_nested_list_index_read_does_not_trigger_cow_clone() {
    let module = Driver::parse("fn t(nums: List<List<i32>>) -> i32:\n    nums[0][1]\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    assert!(!fn_ir.contains("list_cow_clone"), "a pure nested read must not clone/unshare the outer list: {}", fn_ir);
}

/// Same nested shape, but a *write* (`m[0][1] = 5`) still must run the
/// copy-on-write gate on the outer list -- a regression guard alongside
/// `codegen_nested_list_index_read_does_not_trigger_cow_clone` so the read
/// fix above doesn't overcorrect into skipping the uniqueness check a real
/// mutation still needs.
#[test]
fn codegen_nested_list_index_write_still_triggers_cow_clone() {
    let module = Driver::parse("fn t(mut nums: List<List<i32>>):\n    nums[0][1] = 5\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("list_cow_clone"), "a nested write must still uniquify the outer list before mutating: {}", ir);
}

/// A nested list-index read (`m[i][j]`) on a `List<List<i32>>` must still
/// produce correct values end to end -- a functional regression guard for
/// the `list_fields`/`list_fields_from_obj`/`list_index_read_obj` split
/// introduced to fix the unwanted-COW-clone-on-read bug above. Also
/// exercises the out-of-bounds path on both index levels (zero value, not a
/// crash), mirroring `emit_list_index`'s established OOB convention.
#[test]
fn runtime_nested_list_index_read_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let m: List<List<i32>> = [[1, 2], [3, 4, 5]]\n",
        "    println(f\"{m[0][1]}\")\n",
        "    println(f\"{m[1][2]}\")\n",
        "    println(f\"{m[0][99]}\")\n",
        "    println(f\"{m[99][0]}\")\n",
    );
    let output = compile_and_run("nested_list_index_read", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["2", "5", "0", "0"], "{}", stdout);
}

/// A pure nested read (`n[0][1]`) must not un-alias two variables sharing
/// the same outer list's buffer -- a subsequent mutation through *either*
/// alias must still behave exactly as plain copy-on-write semantics
/// predict (mutating one never affects the other), regardless of whether a
/// read happened first. This can't distinguish "never cloned" from
/// "clone­d-then-still-correctly-isolated" by final values alone (both are
/// observably identical, which is precisely why the bug was invisible from
/// program output) -- `codegen_nested_list_index_read_does_not_trigger_cow_clone`
/// is what actually pins the fix; this is a functional companion guarding
/// against a botched fix breaking ordinary COW isolation.
#[test]
fn runtime_nested_list_read_then_mutate_preserves_cow_isolation_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let mut m: List<List<i32>> = [[1, 2]]\n",
        "    let n = m\n",
        "    let x = n[0][1]\n",
        "    m[0].push(99)\n",
        "    println(f\"x={x} m0len={m[0].len()} n0len={n[0].len()}\")\n",
    );
    let output = compile_and_run("nested_list_read_then_mutate", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "x=2 m0len=3 n0len=2", "{}", stdout);
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

// ===== List<T> copy-on-write ownership (todo.md's memory-ownership fix) ===

/// The use-after-free `todo.md` originally flagged, "confirmed empirically":
/// `let b = a` used to alias the same buffer, and growing `b` past `a`'s
/// original capacity would `free` that buffer and repoint only `b`'s own
/// fields, leaving `a` holding a dangling pointer. Under copy-on-write,
/// growing `b` first clones the (now-shared) buffer, so `a`'s original
/// elements must still read back correctly -- and, since this is
/// copy-on-write (value semantics), `a`'s length must NOT have grown along
/// with `b`'s.
#[test]
fn runtime_list_cow_push_does_not_corrupt_alias_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let a: List<i32> = [1, 2, 3]\n",
        "    let mut b = a\n",
        "    let mut i: i32 = 0\n",
        "    while i < 20:\n",
        "        b.push(i)\n",
        "        i += 1\n",
        "    println(f\"a0={a[0]} a1={a[1]} a2={a[2]} alen={a.len()} blen={b.len()}\")\n",
    );
    let output = compile_and_run("list_cow_push", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "a0=1 a1=2 a2=3 alen=3 blen=23", "{}", stdout);
}

/// `let b = a; b[i] = v` (index-assignment) must not be visible through
/// `a` -- covers the copy-on-write gate on `store_list_index` specifically,
/// distinct from `push`'s grow path above.
#[test]
fn runtime_list_cow_index_assignment_diverges_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let a: List<i32> = [1, 2, 3]\n",
        "    let mut b = a\n",
        "    b[0] = 99\n",
        "    println(f\"a0={a[0]} b0={b[0]}\")\n",
    );
    let output = compile_and_run("list_cow_index_assign", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "a0=1 b0=99", "{}", stdout);
}

/// `let b = a; b.pop()` must not be visible through `a` -- the case most
/// likely to be missed by a copy-on-write implementation, since `pop` only
/// mutates `len` and never touches `data`, so it's easy to assume (wrongly)
/// that it needs no uniqueness check.
#[test]
fn runtime_list_cow_pop_diverges_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let a: List<i32> = [1, 2, 3]\n",
        "    let mut b = a\n",
        "    let popped = b.pop()\n",
        "    println(f\"alen={a.len()} blen={b.len()} popped={popped} a2={a[2]}\")\n",
    );
    let output = compile_and_run("list_cow_pop", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "alen=3 blen=2 popped=3 a2=3", "{}", stdout);
}

/// A `List<i32>` (a non-RC element type) local used to leak unconditionally
/// -- `contains_rc(List(elem))` only recursed into the element type, so a
/// list of non-RC elements was never `track_owned` and nothing but `push`'s
/// realloc ever freed its buffer. `contains_rc(List(_))` is now
/// unconditionally `true`, so this parameter should now be released (and,
/// transitively, its buffer freed by the generated `list_release_i32`
/// thunk) at scope exit, same as a `List<str>` already was.
#[test]
fn codegen_list_of_int_is_released_at_scope_exit() {
    let src = "fn t(nums: List<i32>) -> i32:\n    1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    assert!(fn_ir.contains("call void @star_rc_release"), "a List<i32> parameter should now be released at scope exit: {}", fn_ir);
}

/// A copy-on-write clone (triggered here by `push` on a shared `List<str>`)
/// must retain each copied element -- otherwise the original and the clone
/// would both believe they solely own the same string, and whichever is
/// released last would read already-freed memory. Both aliases' string
/// elements must still print correctly after the clone.
#[test]
fn runtime_list_cow_clone_retains_str_elements_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let a: List<str> = [\"alpha\", \"beta\"]\n",
        "    let mut b = a\n",
        "    b.push(\"gamma\")\n",
        "    println(f\"a0={a[0]} a1={a[1]} alen={a.len()}\")\n",
        "    println(f\"b0={b[0]} b1={b[1]} b2={b[2]} blen={b.len()}\")\n",
    );
    let output = compile_and_run("list_cow_clone_str", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let mut lines = stdout.lines();
    assert_eq!(lines.next(), Some("a0=alpha a1=beta alen=2"), "{}", stdout);
    assert_eq!(lines.next(), Some("b0=alpha b1=beta b2=gamma blen=3"), "{}", stdout);
}

/// Regression test: `Codegen::emit_place` previously had no `ListIndex` arm,
/// so a mutating operation whose *receiver* was itself a `list[i]`
/// expression (`outer[i].push(v)`, chaining a `List<T>` method call onto an
/// index) fell into `emit_place`'s generic fallback -- evaluate the
/// expression, spill the resulting *value* into a fresh, disconnected
/// alloca, and mutate that instead of the real buffer. The write silently
/// vanished: `outer[0].push(99)` type-checked, compiled, and ran with zero
/// observable effect on `outer`. Fixed by giving `emit_place` a dedicated
/// `ListIndex` arm (`Codegen::emit_list_index_place`) that resolves a real
/// pointer into the (copy-on-write-uniqued) buffer.
#[test]
fn runtime_nested_list_index_receiver_push_mutates_through_index_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let mut outer: List<List<i32>> = [[1, 2], [3, 4]]\n",
        "    outer[0].push(99)\n",
        "    println(f\"len0={outer[0].len()} last={outer[0][2]} len1={outer[1].len()}\")\n",
    );
    let output = compile_and_run("nested_list_index_push", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "len0=3 last=99 len1=2", "{}", stdout);
}

/// Same root-cause bug as above (`emit_place`'s missing `ListIndex` arm),
/// but through the `store_target`/`store_list_index` path instead of a
/// method-call receiver: `m[i][j] = v` -- a nested nested index-assignment
/// where the *outer* target's own `base` (`m[i]`) is itself a `ListIndex`
/// that must resolve to real storage in `m`'s buffer, not a throwaway copy.
#[test]
fn runtime_nested_list_index_assignment_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let mut m: List<List<i32>> = [[1, 2], [3, 4]]\n",
        "    m[0][1] = 999\n",
        "    println(f\"m00={m[0][0]} m01={m[0][1]} m10={m[1][0]}\")\n",
    );
    let output = compile_and_run("nested_list_index_assign", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "m00=1 m01=999 m10=3", "{}", stdout);
}

/// The same `emit_place` gap also applied to `GenRefIndex` (`gen_ref[0]`
/// used as the base of a further access): `r[0].field = v`/`r[0].field -= v`
/// silently no-op'd on the arena, since `emit_place`'s generic fallback
/// mutated a disconnected copy of the dereferenced struct rather than a
/// pointer into the live slot. Fixed by `Codegen::emit_genref_index_place`,
/// mirroring `emit_list_index_place`'s fix for the identical root cause.
#[test]
fn runtime_genref_field_write_mutates_arena_slot_end_to_end() {
    let src = concat!(
        "struct Entity:\n",
        "    mut hp: i32\n",
        "arena Entities: Entity\n",
        "fn main():\n",
        "    spawn Entities(100)\n",
        "    let r = GenRef<Entity>(0)\n",
        "    r[0].hp -= 10\n",
        "    let after = r[0]\n",
        "    println(f\"after: {after.hp}\")\n",
    );
    let output = compile_and_run("genref_field_write", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "after: 90", "{}", stdout);
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

// ===== Compiler-audit regression tests ======================================
//
// One test per bug found and fixed in a full lexer/parser/checker/codegen
// audit: two lexer panics on non-ASCII bytes outside a string/comment (one
// in `scan_operator`'s fallback, one in `scan_escape`'s), a silent-corruption
// bug in unrecognized escape sequences, a silent-corruption bug in oversized
// integer literals, a turbofish-heuristic misparse of a real `<` comparison
// between two capitalized identifiers, dead/silently-defaulting code in the
// `GenRef` constructor's parsing, and a compiler crash (or invalid LLVM IR)
// on a struct that's recursive by value with no cycle detection.

/// A stray non-ASCII byte outside a string/comment (e.g. an accented
/// identifier) must be a clean lexer error, not a panic -- previously
/// `scan_operator`'s fallback arm advanced by exactly one raw byte, splitting
/// a multi-byte UTF-8 codepoint across two tokens and producing a `Span` that
/// crashed `diagnostics::line_text`'s slicing with "byte index is not a char
/// boundary". If the fix regresses, this test fails via an unwinding panic
/// rather than a normal assertion failure.
#[test]
fn rejects_non_ascii_source_does_not_panic() {
    let src = "fn main():\n    let café = 1\n";
    let result = Driver::parse(src);
    assert!(result.is_err(), "a stray non-ASCII byte should be a clean parse error");
}

/// The same class of bug one level deeper: a non-ASCII byte immediately
/// after a `\` inside a string literal used to desync `scan_escape`'s
/// position tracking and panic inside `current_char()` while scanning the
/// rest of the string, at a different crash site than the bare-source case
/// above.
#[test]
fn rejects_non_ascii_escape_does_not_panic() {
    let src = "fn main():\n    let x = \"\\é\"\n";
    let result = Driver::lex(src);
    assert!(result.is_err(), "a non-ASCII escaped byte should be a clean lexer error");
}

/// An escape sequence the lexer doesn't recognize must be reported, not
/// silently accepted by dropping the backslash -- previously `"bad\qescape"`
/// silently became the string `"badqescape"` with zero diagnostics.
#[test]
fn rejects_unknown_escape_sequence() {
    let src = "fn main():\n    let x = \"bad\\qescape\"\n";
    let result = Driver::lex(src);
    let Err(diags) = result else { panic!("unknown escape sequence should be a lexer error") };
    assert!(
        diags.iter().any(|d| d.message.contains("unknown escape sequence")),
        "expected an 'unknown escape sequence' diagnostic, got: {:?}",
        diags
    );
}

/// An integer literal outside `i32`'s range must be a clean error --
/// previously `text.parse::<i64>().unwrap_or(0)` let anything in
/// `(i32::MAX, i64::MAX]` parse successfully and then silently reinterpret
/// as a negative `i32` at codegen with zero diagnostics anywhere.
#[test]
fn rejects_oversized_integer_literal() {
    let src = "fn main():\n    let x = 3000000000\n";
    let result = Driver::lex(src);
    let Err(diags) = result else { panic!("an out-of-i32-range literal should be a lexer error") };
    assert!(
        diags.iter().any(|d| d.message.contains("too large for a 32-bit integer")),
        "expected a 'too large' diagnostic, got: {:?}",
        diags
    );
}

/// `i32::MIN` written as a unary-minus literal must still parse and
/// type-check cleanly (regression guard for the magnitude special-case added
/// alongside the overflow fix above: the lexer stores the bare magnitude
/// `2147483648` as `i32::MIN`'s bit pattern, and codegen's wrapping negation
/// of that value round-trips back to `i32::MIN`).
#[test]
fn accepts_i32_min_literal() {
    let module = Driver::parse("fn main():\n    let x = -2147483648\n").expect("should parse");
    Driver::check(&module).expect("i32::MIN literal should type-check");
}

/// Deeply nested parenthesized groups must be a clean parse error, not a
/// Rust stack overflow -- previously `Parser::parse_unary`/`parse_postfix`/
/// `parse_primary` recursed one Rust stack frame per nesting level with no
/// depth limit at all; ~500 levels of nested parens reliably overflowed the
/// real call stack with a bare process abort ("thread 'main' has overflowed
/// its stack") and no diagnostic anywhere, the parser-side counterpart of
/// the same class of bug `Checker::mono_depth` already guards against for
/// generic monomorphization.
#[test]
fn rejects_deeply_nested_parens_does_not_overflow_stack() {
    let src = format!("fn main():\n    let x = {}1{}\n", "(".repeat(500), ")".repeat(500));
    let result = Driver::parse(&src);
    assert!(result.is_err(), "500 levels of nested parens should be a clean parse error, not succeed or crash");
}

/// Same fix, unary-chain side: a long chain of unary `-` also recurses
/// through `parse_unary` with no depth limit (this path never goes through
/// `parse_primary`'s paren-recursion at all, so it exercises the depth guard
/// independently of the nested-parens case above).
#[test]
fn rejects_deeply_nested_unary_minus_does_not_overflow_stack() {
    let src = format!("fn main():\n    let x = {}1\n", "-".repeat(200000));
    let result = Driver::parse(&src);
    assert!(result.is_err(), "200000 levels of unary `-` should be a clean parse error, not succeed or crash");
}

/// Same fix, type-grammar side: `parse_type` recurses into itself for both
/// `Type::Generic`'s type arguments (`List<List<...>>`) and `Type::Fn`'s
/// params/return with no depth guard of its own -- previously this could
/// overflow the real call stack with a bare process abort ("thread 'main'
/// has overflowed its stack") the same way unguarded expression nesting did,
/// just reached through a type annotation instead of a value expression.
/// `parse_type` now shares `Parser::expr_depth`/`MAX_EXPR_DEPTH` with
/// `parse_unary`.
#[test]
fn rejects_deeply_nested_generic_type_does_not_overflow_stack() {
    let src = format!(
        "fn main():\n    let x: {}int{} = 1\n",
        "List<".repeat(500),
        ">".repeat(500)
    );
    let result = Driver::parse(&src);
    assert!(result.is_err(), "500 levels of nested `List<...>` should be a clean parse error, not succeed or crash");
}

/// A reasonably (but not adversarially) nested generic type annotation --
/// well under the depth guard's threshold -- must still parse correctly (a
/// regression guard against the depth guard being so aggressive it rejects
/// sound, if unusual, code).
#[test]
fn parses_moderately_nested_generic_type() {
    let src = format!(
        "fn main():\n    let x: {}int{} = 1\n",
        "List<".repeat(20),
        ">".repeat(20)
    );
    Driver::parse(&src).expect("20 levels of nested `List<...>` should parse cleanly");
}

/// Same failure mode again, block-nesting side: `parse_block` re-enters
/// itself (via `parse_stmt` -> `parse_if_stmt`/`parse_while_stmt`/
/// `parse_for_stmt`/`parse_match`/...) with no depth guard of its own --
/// `expr_depth`/`MAX_EXPR_DEPTH` only bounds expression nesting, not
/// statement-block nesting, so a source with a few hundred levels of
/// strictly increasing indentation (nested `if true:` blocks) previously
/// overflowed the real call stack the same way. Guarded by the new,
/// separate `Parser::block_depth`/`MAX_BLOCK_DEPTH` counter.
#[test]
fn rejects_deeply_nested_if_blocks_does_not_overflow_stack() {
    let mut src = String::from("fn main():\n");
    for i in 0..300 {
        src.push_str(&"    ".repeat(i + 1));
        src.push_str("if true:\n");
    }
    src.push_str(&"    ".repeat(301));
    src.push_str("println(\"hi\")\n");
    let result = Driver::parse(&src);
    assert!(result.is_err(), "300 levels of nested `if` blocks should be a clean parse error, not succeed or crash");
}

/// A reasonably (but not adversarially) nested block -- well under
/// `MAX_BLOCK_DEPTH` -- must still parse and run correctly (a regression
/// guard against the depth guard being so aggressive it rejects sound, if
/// unusual, code).
#[test]
fn runtime_moderately_nested_if_blocks_end_to_end() {
    let mut src = String::from("fn main():\n");
    for i in 0..20 {
        src.push_str(&"    ".repeat(i + 1));
        src.push_str("if true:\n");
    }
    src.push_str(&"    ".repeat(21));
    src.push_str("println(\"hi\")\n");
    let output = compile_and_run("moderately_nested_if_blocks", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "hi", "{}", stdout);
}

/// Same failure mode again, `match`-nesting side: `parse_match` recurses
/// back into itself both as a bare statement (`parse_match_stmt`, uncounted
/// by `expr_depth`/`block_depth` at that call site) and inline in another
/// arm's body (`_ -> match ...`, going through `expr_depth` via
/// `parse_unary`) -- previously unguarded by any counter of its own, and
/// each level of `match` nesting costs far more real stack per level
/// (`parse_match` -> `parse_match_arm` -> `parse_pattern`/`parse_expr`, each
/// with their own locals) than a plain paren/unary chain does, so ~55-60
/// levels of nested inline `match` reliably overflowed the real call stack
/// with a bare process abort well *under* `MAX_EXPR_DEPTH`'s 80-level
/// threshold -- the same "guard calibrated for a lighter call chain doesn't
/// trigger before a heavier one crashes" bug already fixed once for
/// `MAX_BLOCK_DEPTH`. Guarded by the new, separate `Parser::match_depth`/
/// `MAX_MATCH_DEPTH` counter.
#[test]
fn rejects_deeply_nested_match_does_not_overflow_stack() {
    let mut src = String::from("fn main():\n    match a0:\n");
    for i in 1..60 {
        src.push_str(&"    ".repeat(i + 1));
        src.push_str(&format!("_ -> match a{}:\n", i));
    }
    src.push_str(&"    ".repeat(61));
    src.push_str("_ -> 1\n");
    let result = Driver::parse(&src);
    assert!(result.is_err(), "60 levels of nested `match` should be a clean parse error, not succeed or crash");
}

/// A reasonably (but not adversarially) nested `match` -- well under
/// `MAX_MATCH_DEPTH` -- must still parse correctly (a regression guard
/// against the depth guard being so aggressive it rejects sound, if
/// unusual, code).
#[test]
fn parses_moderately_nested_match() {
    let mut src = String::from("fn main():\n    match a0:\n");
    for i in 1..20 {
        src.push_str(&"    ".repeat(i + 1));
        src.push_str(&format!("_ -> match a{}:\n", i));
    }
    src.push_str(&"    ".repeat(21));
    src.push_str("_ -> 1\n");
    Driver::parse(&src).expect("20 levels of nested `match` should parse cleanly");
}

/// A structurally-valid enum variant followed by garbage instead of a line
/// ending (`Red 123`) must produce exactly one diagnostic and recover
/// cleanly -- `parse_enum_variant` previously discarded `expect_line_end()`'s
/// `Option` outright (`self.expect_line_end();`, no `?`), so on failure it
/// still returned `Some(EnumVariantDef { .. })` as if nothing had gone
/// wrong, leaving the stray `123` for the next loop iteration to
/// misinterpret as the start of another variant and produce a second,
/// redundant diagnostic.
#[test]
fn rejects_enum_variant_with_garbage_after_it_with_single_diagnostic() {
    let src = "enum Color:\n    Red 123\n    Blue\n";
    let errs = Driver::parse(src).expect_err("garbage after an enum variant should be a parse error");
    assert_eq!(errs.len(), 1, "should recover after exactly one diagnostic, not cascade into a second: {:?}", errs);
    assert!(errs[0].message.contains("end of line"), "{:?}", errs);
}

/// Same fix, trait-method side: a structurally-valid method signature
/// followed by garbage instead of a line ending (`fn bar() 123`) must also
/// produce exactly one diagnostic -- `parse_trait`'s method loop called
/// `self.expect_line_end();` directly (also discarding the `Option`) rather
/// than recovering on failure, so the stray `123` was left for the next
/// iteration to misinterpret as the start of another method.
#[test]
fn rejects_trait_method_with_garbage_after_it_with_single_diagnostic() {
    let src = "trait Foo:\n    fn bar() 123\n    fn baz()\n";
    let errs = Driver::parse(src).expect_err("garbage after a trait method signature should be a parse error");
    assert_eq!(errs.len(), 1, "should recover after exactly one diagnostic, not cascade into a second: {:?}", errs);
    assert!(errs[0].message.contains("end of line"), "{:?}", errs);
}

/// Same failure mode a third time, f-string-interpolation side: each nested
/// `f"{...}"` interpolation lexes and parses its inner expression with a
/// brand-new `Parser` (see `Parser::lower_fstring`), which previously reset
/// `expr_depth` to `0` at every level -- so `MAX_EXPR_DEPTH` never actually
/// accumulated across nested interpolations and only the real, unbounded
/// Rust call stack did. Fixed by carrying the outer parser's `expr_depth`/
/// `block_depth` into the fresh sub-parser instead of starting it at zero.
#[test]
fn rejects_deeply_nested_fstring_interpolation_does_not_overflow_stack() {
    let mut src = String::from("1");
    for _ in 0..200 {
        src = format!("f\"{{{}}}\"", src);
    }
    let src = format!("fn main():\n    let x = {}\n", src);
    let result = Driver::parse(&src);
    assert!(result.is_err(), "200 levels of nested f-string interpolation should be a clean parse error, not succeed or crash");
}

/// A reasonably (but not adversarially) nested f-string interpolation --
/// well under the depth guard's threshold -- must still parse and run
/// correctly.
#[test]
fn runtime_moderately_nested_fstring_interpolation_end_to_end() {
    let mut src = String::from("1");
    for _ in 0..10 {
        src = format!("f\"{{{}}}\"", src);
    }
    let src = format!("fn main():\n    let x = {}\n    println(x)\n", src);
    let output = compile_and_run("moderately_nested_fstring_interpolation", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "1", "{}", stdout);
}

/// A reasonably (but not adversarially) nested expression -- well under the
/// depth guard's threshold -- must still parse and run correctly (a
/// regression guard against the depth guard being so aggressive it rejects
/// sound, if unusual, code).
#[test]
fn runtime_moderately_nested_parens_end_to_end() {
    let src = format!("fn main():\n    let x = {}1{}\n    println(f\"{{x}}\")\n", "(".repeat(50), ")".repeat(50));
    let output = compile_and_run("moderately_nested_parens", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "1", "{}", stdout);
}

/// `if Foo < Bar:` -- both real (capitalized) local variables -- must parse
/// as an ordinary comparison, not cascade into parse errors from an eager,
/// non-backtracking turbofish attempt on the capitalized `Foo`.
#[test]
fn accepts_comparison_between_capitalized_identifiers() {
    let src = "fn main():\n    let Foo = 1\n    let Bar = 2\n    if Foo < Bar:\n        println(\"yes\")\n";
    let module = Driver::parse(src).expect("a real `<` comparison between capitalized idents should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::If { cond, .. } = &f.body.stmts[2] else { panic!("expected If") };
    match cond {
        Expr::Binary { op: BinOp::Lt, lhs, rhs, .. } => {
            assert!(matches!(lhs.as_ref(), Expr::Ident(name, _) if name == "Foo"));
            assert!(matches!(rhs.as_ref(), Expr::Ident(name, _) if name == "Bar"));
        }
        other => panic!("expected a `<` comparison, got {:?}", other),
    }
}

/// Regression guard alongside the turbofish backtracking change: legitimate
/// turbofish generic construction must still work.
#[test]
fn accepts_turbofish_generic_constructions_after_backtracking_fix() {
    let src = include_str!("../examples/generics.star");
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("Box<T>/Option<T>::Variant turbofish forms should still type-check");
}

/// `GenRef(value)` with no explicit type argument must be a clear parse
/// error -- previously it silently fell through to an incorrect `StructLit`
/// for a nonexistent `GenRef` struct, surfacing a confusing, unrelated error
/// far from the actual mistake.
#[test]
fn rejects_genref_without_type_args() {
    let src = "arena Entities: i32\nfn main():\n    let g = GenRef(0)\n";
    let module = Driver::parse(src);
    let Err(diags) = module else { panic!("bare GenRef(..) should be a parse error") };
    assert!(
        diags.iter().any(|d| d.message.contains("requires an explicit type argument")),
        "got: {:?}",
        diags
    );
}

/// `GenRef<i32>()` (missing the value argument) must be a clear parse error
/// instead of silently synthesizing a placeholder `Int(0)` value with a
/// dummy span.
#[test]
fn rejects_genref_missing_value_arg() {
    let src = "arena Entities: i32\nfn main():\n    let g = GenRef<i32>()\n";
    let module = Driver::parse(src);
    let Err(diags) = module else { panic!("GenRef<T>() with no value should be a parse error") };
    assert!(
        diags.iter().any(|d| d.message.contains("expects exactly one argument")),
        "got: {:?}",
        diags
    );
}

/// `GenRef<>(0)` (missing the type argument) must be a clear parse error
/// instead of silently synthesizing a placeholder `Type::Named("unknown")`.
#[test]
fn rejects_genref_missing_type_arg() {
    let src = "arena Entities: i32\nfn main():\n    let g = GenRef<>(0)\n";
    let module = Driver::parse(src);
    let Err(diags) = module else { panic!("GenRef<>(..) with no type arg should be a parse error") };
    assert!(
        diags.iter().any(|d| d.message.contains("expects exactly one type argument")),
        "got: {:?}",
        diags
    );
}

/// A struct that's directly recursive by value has no finite size and must
/// be rejected at type-check time -- previously this either crashed the
/// compiler with a stack overflow (via `Codegen::type_size`'s unbounded
/// recursion, when a reflection decorator touched the field) or reached
/// `clang` as invalid, unrepresentable LLVM IR.
#[test]
fn rejects_directly_recursive_struct() {
    let src = "struct Node:\n    val: i32\n    next: Node\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("a directly self-referential struct should be rejected") };
    assert!(
        errs.iter().any(|d| d.message.contains("recursive struct layout")),
        "got: {:?}",
        errs
    );
}

/// A struct that's recursive only through a generic by-value wrapper must
/// also be rejected -- `struct Box<T>: value: T` is a plain by-value
/// wrapper in this language, not a heap indirection, so `Box<Node>` used as
/// a field is just as much an infinite-size cycle as direct self-reference.
#[test]
fn rejects_struct_recursive_through_generic_wrapper() {
    let src = "struct Box<T>:\n    value: T\nstruct Node:\n    next: Box<Node>\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("a struct recursive through a monomorphized generic wrapper should be rejected")
    };
    assert!(
        errs.iter().any(|d| d.message.contains("recursive struct layout")),
        "got: {:?}",
        errs
    );
}

/// A generic struct whose field wraps its *own* type parameter in another
/// generic each level (`Node<T>: next: Node<Box<T>>`) is a fundamentally
/// different shape from `rejects_directly_recursive_struct`/
/// `rejects_struct_recursive_through_generic_wrapper` above: those are
/// caught by `check_no_recursive_structs` walking the *already-instantiated*
/// items, but this one never gets that far -- `instantiate_struct`
/// memoizes by mangled name (`Node__Box__i32`, `Node__Box__Box__i32`, ...),
/// and every recursive step here produces a *new* mangled name the memo
/// check has never seen, so it recurses through Rust's own call stack
/// forever. Previously an unguarded stack-overflow ICE (the whole `star`
/// process aborting) on four lines of otherwise ordinary-looking source,
/// with no diagnostic at all. `Checker::mono_depth` bounds this to a clean
/// error instead.
#[test]
fn rejects_infinitely_nested_generic_struct_field_does_not_overflow_stack() {
    let src = concat!(
        "struct Box<T>:\n",
        "    value: T\n",
        "struct Node<T>:\n",
        "    next: Node<Box<T>>\n",
        "struct Root:\n",
        "    n: Node<i32>\n",
        "fn main():\n",
        "    println(\"hi\")\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("an infinitely-growing generic instantiation should be rejected, not silently accepted")
    };
    assert!(
        errs.iter().any(|d| d.message.contains("nests too deeply")),
        "got: {:?}",
        errs
    );
}

/// A generic wrapper nested several levels deep, but *finitely* (each level
/// is written explicitly in the source, not generated by recursive
/// instantiation), must still compile and run correctly -- guards against
/// `mono_depth`'s recursion guard being so aggressive it rejects sound,
/// ordinary nested-generic code.
#[test]
fn runtime_finitely_nested_generic_struct_end_to_end() {
    let src = concat!(
        "struct Box<T>:\n",
        "    value: T\n",
        "fn main():\n",
        "    let b = Box(Box(Box(5)))\n",
        "    println(f\"{b.value.value.value}\")\n",
    );
    let output = compile_and_run("finitely_nested_generic", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "5", "{}", stdout);
}

/// Runtime test for the RC atomicity fix: `examples/par_rc_race.exe` spawns
/// 16 arena entries, captures a heap-backed `Str` (`tag`), then reads it
/// from inside a `par` body dispatched across the persistent 4-worker pool
/// for 400 ticks (6400 concurrent reads total), and reads it once more
/// afterward. Before the fix, `star_rc_retain`/`star_rc_release` mutated the
/// shared refcount header with a plain (non-atomic) load/add-or-sub/store,
/// so concurrent retains/releases from different worker threads could lose
/// an update and free the block while a worker still held it live -- the
/// final read would then be a use-after-free (typically a crash or garbled
/// output). This can't deterministically *prove* the race is gone (it's
/// inherently timing-dependent), but running it several times multiplies the
/// chances of hitting the lost-update window, the same stress-testing
/// approach `runtime_rc_stress_memory_stays_bounded` uses for leaks.
#[test]
fn runtime_par_rc_race_reads_captured_str_without_corruption() {
    use std::process::Command;

    for _ in 0..5 {
        let output = Command::new("examples/par_rc_race.exe").output().expect("failed to run par_rc_race.exe");
        assert!(output.status.success(), "par_rc_race.exe should exit cleanly, not crash from a use-after-free");
        let stdout = String::from_utf8_lossy(&output.stdout);
        assert!(
            stdout.trim_end().ends_with("final: swarm-tag"),
            "expected the captured Str to still read correctly after the par loop, got tail: {:?}",
            &stdout[stdout.len().saturating_sub(80)..]
        );
        // Every retain/release pair inside the loop operates on the same
        // "swarm-tag" bytes; a corrupted refcount that freed the block
        // early (but didn't crash outright) would typically show up as a
        // truncated/garbled repetition somewhere in the middle instead of a
        // clean, uniform repeat -- a stronger check than only looking at the
        // very end.
        assert!(
            !stdout.contains('\0') && stdout.matches("swarm-tag").count() >= 6400,
            "expected 6400 clean repetitions of the captured Str, got {} (len {})",
            stdout.matches("swarm-tag").count(),
            stdout.len()
        );
    }
}

/// `print`/`println`'s non-f-string form passes its argument straight
/// through as `printf`'s format string (see `Codegen::emit_print_like`),
/// with no `%s` substitution -- previously the checker never validated this
/// argument's type at all, so `print(5)` (or `print(len(s))`, or any other
/// non-`str` argument) type-checked cleanly and only failed later at the
/// `clang` step with a confusing, mislocated backend error (a raw `i32`
/// value reaching an `i8*` format-string parameter).
#[test]
fn rejects_print_of_non_str_argument() {
    let module = Driver::parse("fn main():\n    print(5)\n").expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("print(5) should be a type error") };
    assert!(
        errs.iter().any(|d| d.message.contains("expects a `str` argument")),
        "got: {:?}",
        errs
    );
}

/// Regression guard for the cycle-detection fix: a struct referencing itself
/// through `GenRef<T>` (a fixed-size arena handle, not an inlined value)
/// must still type-check -- this is the language's actual intended pattern
/// for self-referential data structures.
#[test]
fn accepts_struct_with_genref_self_reference() {
    let src = "struct Node:\n    val: i32\n    next: GenRef<Node>\narena Nodes: Node\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("GenRef<Self> should break the cycle and type-check cleanly");
}

// --- item 20: integer division/modulo by zero traps the process -----------
//
// `sdiv`/`srem i32` are undefined behavior in LLVM on a zero divisor, and
// on the lone overflowing case `i32::MIN / -1` (its true result doesn't fit
// in `i32`) -- both trap the whole process with SIGFPE and no diagnostic on
// x86 if emitted unchecked, exactly the "silently crash instead of erroring"
// failure mode item 1 (frame overflow) and item 9 (arena capacity) already
// fixed for other operations. `Codegen::emit_checked_int_div`
// (`src/codegen/vector_math.rs`) now guards both cases and aborts with a
// message, mirroring `emit_frame_alloc`'s check-then-abort shape.

/// `10 / e.hp` where `e.hp` is a runtime-computed `0` (not a literal, so the
/// checker's lack of constant folding can't be accused of catching this
/// statically) must abort loudly with a diagnostic instead of crashing the
/// process with an unexplained SIGFPE.
#[test]
fn runtime_int_division_by_zero_aborts_loudly_instead_of_trapping() {
    use std::process::Command;

    let output = Command::new("examples/int_div_by_zero.exe").output().expect("failed to execute int_div_by_zero.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("integer `/` by zero"), "should print a diagnostic: {}", stdout);
    assert!(!stdout.contains("should not reach here"), "the division must abort before its value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "should exit cleanly with code 1, not crash/trap: {:?}", output.status);
}

/// Same guard, `%` instead of `/`, and reached at the very edge of `i32`.
#[test]
fn runtime_int_modulo_by_zero_aborts_loudly_instead_of_trapping() {
    let src = "struct Enemy:\n    mut hp: i32\nfn main():\n    let e = Enemy(0)\n    println(\"before\")\n    let x = 2147483647 % e.hp\n    println(f\"unreachable {x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_int_mod_by_zero.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");

    let output = std::process::Command::new(&exe).output().expect("failed to execute int_mod_by_zero.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("integer `%` by zero"), "should print a diagnostic: {}", stdout);
    assert!(!stdout.contains("unreachable"), "the modulo must abort before its value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "should exit cleanly with code 1, not crash/trap: {:?}", output.status);

    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
}

/// `i32::MIN / -1` is the one *non-zero*-divisor input that's still
/// undefined behavior for `sdiv` (the mathematical result, `2147483648`,
/// overflows `i32`) -- must be caught by the same guard, not just the
/// zero-divisor case.
#[test]
fn runtime_int_min_divided_by_negative_one_aborts_loudly_instead_of_trapping() {
    let src = "struct Enemy:\n    mut hp: i32\nfn main():\n    let e = Enemy(-1)\n    println(\"before\")\n    let x = -2147483648 / e.hp\n    println(f\"unreachable {x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_int_min_div_neg1.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");

    let output = std::process::Command::new(&exe).output().expect("failed to execute int_min_div_neg1.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("integer `/` by zero"), "should print a diagnostic: {}", stdout);
    assert!(!stdout.contains("unreachable"), "the division must abort before its value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "should exit cleanly with code 1, not crash/trap: {:?}", output.status);

    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
}

/// Ordinary division/modulo (including negative operands, where `srem`'s
/// sign convention matters) must still compute the correct value through
/// the new checked path -- the guard must not perturb the common case.
#[test]
fn codegen_ordinary_int_division_still_computes_correct_values() {
    let src = "fn main():\n    println(f\"{10 / 3}\")\n    println(f\"{-10 / 3}\")\n    println(f\"{10 % 3}\")\n    println(f\"{-10 % 3}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_ordinary_div.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");

    let output = std::process::Command::new(&exe).output().expect("failed to execute ordinary_div.exe");
    assert!(output.status.success(), "should exit cleanly");
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["3", "-3", "1", "-1"], "LLVM's sdiv/srem truncate toward zero, matching Star's semantics");

    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
}

/// Codegen for `/`/`%` on `i32` operands includes the zero/overflow guard
/// before the `sdiv`/`srem` instruction, with a call to `@exit` on the trap
/// path -- the direct IR-shape pin, alongside the end-to-end runtime tests
/// above.
#[test]
fn codegen_int_division_includes_zero_and_overflow_guard() {
    let src = "fn div(a: i32, b: i32) -> i32:\n    a / b\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("icmp eq i32 %"), "should compare the divisor against zero: {}", ir);
    assert!(ir.contains("-2147483648"), "should compare the dividend against i32::MIN for the overflow case: {}", ir);
    assert!(ir.contains("call void @exit(i32 1)"), "should abort on the trap path: {}", ir);
    assert!(ir.contains("sdiv i32"), "should still emit sdiv on the ok path: {}", ir);
}

// ===== extern "C" FFI =========================================================
//
// `extern "C" fn name(params) -> ret` declares a foreign C symbol (no body)
// that codegen lowers to a bare LLVM `declare`, letting Star bind existing C
// libraries instead of requiring every capability to be hand-implemented
// inside the compiler (see todo.md's "Next Steps" §1). Parameter/return
// types are restricted to `int`/`float`/`ptr` (plus `str`, parameter-only)
// -- see `Checker::check_extern_fn`.

/// `extern "C" fn abs(x: int) -> int` parses to a single `Item::ExternFn`
/// with the ABI string, name, params, and return type all captured.
#[test]
fn extern_fn_parses_signature() {
    let src = "extern \"C\" fn abs(x: int) -> int\n";
    let module = Driver::parse(src).expect("should parse");
    assert_eq!(module.items.len(), 1);
    match &module.items[0] {
        Item::ExternFn(e) => {
            assert_eq!(e.abi, "C");
            assert_eq!(e.sig.name, "abs");
            assert_eq!(e.sig.params.len(), 1);
            assert_eq!(e.sig.params[0].name, "x");
            assert_eq!(e.sig.params[0].ty, Some(Type::Named("int".into())));
            assert_eq!(e.sig.ret, Some(Type::Named("int".into())));
        }
        other => panic!("expected Item::ExternFn, found {:?}", other),
    }
}

/// A no-return-type, no-argument extern declaration (`extern "C" fn
/// foo()`) parses with an empty param list and no return type -- the same
/// shape a `void` C function needs.
#[test]
fn extern_fn_parses_no_args_no_return() {
    let src = "extern \"C\" fn foo()\n";
    let module = Driver::parse(src).expect("should parse");
    match &module.items[0] {
        Item::ExternFn(e) => {
            assert!(e.sig.params.is_empty());
            assert_eq!(e.sig.ret, None);
        }
        other => panic!("expected Item::ExternFn, found {:?}", other),
    }
}

/// Two extern declarations back to back parse as two separate items -- the
/// body-less grammar must end exactly at the line, not swallow (or get
/// confused by) whatever follows.
#[test]
fn extern_fn_two_declarations_back_to_back() {
    let src = "extern \"C\" fn abs(x: int) -> int\nextern \"C\" fn atoi(s: str) -> int\nfn main():\n    println(\"ok\")\n";
    let module = Driver::parse(src).expect("should parse");
    assert_eq!(module.items.len(), 3);
    assert!(matches!(&module.items[0], Item::ExternFn(e) if e.sig.name == "abs"));
    assert!(matches!(&module.items[1], Item::ExternFn(e) if e.sig.name == "atoi"));
    assert!(matches!(&module.items[2], Item::Fn(_)));
}

/// A missing ABI string literal (`extern fn foo()` instead of `extern "C"
/// fn foo()`) is a parse error naming what was expected.
#[test]
fn extern_fn_missing_abi_string_is_parse_error() {
    let src = "extern fn foo()\n";
    let Err(diags) = Driver::parse(src) else { panic!("missing ABI string should be a parse error") };
    assert!(diags.iter().any(|d| d.message.contains("ABI")), "{:?}", diags);
}

/// An extern fn bound to an uppercase-starting C symbol (e.g. a Win32 name
/// like `CreateThread`) is rejected at the declaration, not left to fail
/// confusingly at the call site -- see `Checker::check_extern_fn`'s doc
/// comment on why such a symbol is permanently uncallable under Star's
/// grammar (`Name(args)` always parses as a struct literal).
#[test]
fn extern_fn_rejects_uppercase_name() {
    let src = "extern \"C\" fn CreateThread(x: int) -> ptr\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("uppercase-starting extern fn name should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("struct-literal constructor")), "{:?}", diags);
}

/// An extern fn's signature is registered into the same call-checking path
/// as an ordinary `fn`: a wrong argument count against `toupper(x: int)` is
/// caught exactly like it would be for a user-defined function. Uses
/// `toupper` rather than `abs`/`min`/`max`/etc. deliberately -- those names
/// are already recognized standard-library builtins (see
/// `crate::types::builtin_return_ty`), which are dispatched *ahead* of the
/// user function table by design (matching `print`'s existing shadowing
/// precedent), so an extern fn declared under one of those names would
/// silently never be reachable.
#[test]
fn extern_fn_call_arity_is_checked() {
    let src = "extern \"C\" fn toupper(x: int) -> int\nfn main():\n    let y = toupper(1, 2)\n    println(f\"{y}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("wrong arity should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("this call expects 1 argument")), "{:?}", diags);
}

/// A well-formed extern fn declaration and call (int arg/return) type-checks
/// cleanly end to end.
#[test]
fn extern_fn_call_type_checks_ok() {
    let src = "extern \"C\" fn toupper(x: int) -> int\nfn main():\n    let y: int = toupper(97)\n    println(f\"{y}\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("should type-check");
}

/// Only `"C"` is accepted as the ABI string.
#[test]
fn extern_fn_rejects_non_c_abi() {
    let src = "extern \"stdcall\" fn foo()\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("non-\"C\" abi should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("unsupported extern ABI")), "{:?}", diags);
}

/// Extern fns can't be generic -- C has no notion of a type parameter.
#[test]
fn extern_fn_rejects_type_params() {
    let src = "extern \"C\" fn foo<T>(x: int)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("generic extern fn should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("cannot be generic")), "{:?}", diags);
}

/// `bool` is rejected in extern signatures (see `Checker::check_extern_fn`'s
/// doc comment: LLVM `i1` vs. C's `_Bool`-as-`i8` ABI mismatch risk).
#[test]
fn extern_fn_rejects_bool_param() {
    let src = "extern \"C\" fn foo(x: bool)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("bool param should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("unsupported type")), "{:?}", diags);
}

/// A struct parameter type is rejected -- no C-ABI struct-by-value layout
/// is modeled by this compiler.
#[test]
fn extern_fn_rejects_struct_param() {
    let src = "struct Player:\n    health: i32\n\nextern \"C\" fn foo(p: Player)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("struct param should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("unsupported type")), "{:?}", diags);
}

/// `str` is allowed as a parameter (a Star `Str`'s payload is already a
/// bare `i8*`, safe to pass read-only to C) but rejected as a return type
/// (a `char*` from C has no RC header and must be bridged via
/// `ptr_to_str` instead of forged into a `str` directly).
#[test]
fn extern_fn_rejects_str_return_type() {
    let src = "extern \"C\" fn foo() -> str\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("str return type should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("ptr_to_str")), "{:?}", diags);
}

/// `str` parameters, by contrast, type-check fine.
#[test]
fn extern_fn_accepts_str_param() {
    let src = "extern \"C\" fn atoi(s: str) -> int\nfn main():\n    let n: int = atoi(\"42\")\n    println(f\"{n}\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("should type-check");
}

/// `null_ptr()`/`is_null(..)`/`ptr_to_str(..)` all type-check with their
/// documented signatures.
#[test]
fn ptr_builtins_type_check() {
    let src = "extern \"C\" fn foo() -> ptr\nfn main():\n    let p: ptr = null_ptr()\n    let ok: bool = is_null(p)\n    println(f\"{ok}\")\n    let s: str = ptr_to_str(foo())\n    println(s)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("should type-check");
}

/// `ptr == ptr` / `ptr != ptr` type-check to `bool`.
#[test]
fn ptr_equality_type_checks() {
    let src = "fn main():\n    let a = null_ptr()\n    let b = null_ptr()\n    let same: bool = a == b\n    println(f\"{same}\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("should type-check");
}

/// Codegen for an extern fn is a bare `declare`, never a `define` -- there
/// is no body to emit. A call to it lowers to an ordinary `call`
/// instruction against that declared symbol.
#[test]
fn extern_fn_codegen_emits_bare_declare_no_define() {
    let src = "extern \"C\" fn toupper(x: int) -> int\nfn main():\n    println(f\"{toupper(97)}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("declare i32 @toupper(i32)"), "{}", ir);
    assert!(!ir.contains("define i32 @toupper("), "extern fn must not get a body: {}", ir);
    assert!(ir.contains("call i32 @toupper("), "{}", ir);
}

/// A `str` argument passed to an extern call must extract the raw `i8*`
/// (not the RC header) and, since the extern call never releases it,
/// balance any borrowed retain back out immediately, *before* the call
/// itself -- see `Codegen::emit_extern_call`'s doc comment. (`s` also gets
/// one further release when it goes out of scope at the end of `main`,
/// same as any other owned local -- that's unrelated bookkeeping for `s`'s
/// own original ownership, not part of this retain/release pair, so this
/// test pins the *ordering* of the pair rather than a raw occurrence count.)
#[test]
fn extern_fn_str_arg_balances_retain_with_release() {
    let src = "extern \"C\" fn atoi(s: str) -> int\nfn main():\n    let s = \"42\"\n    println(f\"{atoi(s)}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let main_body = extract_fn_body(&ir, "define i32 @main(");
    let retain_idx = main_body.find("call void @star_rc_retain").expect("reading `s` should retain");
    let release_idx = main_body.find("call void @star_rc_release").expect("the transient extern-call read should be released back");
    let call_idx = main_body.find("call i32 @atoi(").expect("should call atoi");
    assert!(
        retain_idx < release_idx && release_idx < call_idx,
        "expected retain, then a balancing release, then the extern call itself, in that order: {}",
        main_body
    );
}

/// `toupper('a')` through a real `extern "C" fn` linked against the C
/// runtime (always available on this target, no `-l` needed) prints the
/// correct uppercase result. Uses `toupper` rather than `abs` -- see
/// `extern_fn_call_arity_is_checked`'s doc comment for why `abs` itself is
/// unusable as an extern fn name (it collides with the existing builtin).
#[test]
fn runtime_extern_toupper_end_to_end() {
    let src = "extern \"C\" fn toupper(x: int) -> int\nfn main():\n    println(f\"{toupper(97)}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_extern_toupper.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");

    let output = std::process::Command::new(&exe).output().expect("failed to execute extern_toupper.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("65"), "expected toupper('a'=97) == 'A'=65: {}", stdout);
    assert!(output.status.success());

    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
}

/// `atoi("42")` through a real `extern "C" fn` (msvcrt, always linked)
/// called repeatedly in a loop with the same `str` variable -- exercises
/// the RC retain/release-balancing path in `emit_extern_call` under
/// repetition. A missing release would leak (silent, doesn't crash); a
/// spurious *extra* release would double-free the string literal's backing
/// allocation and crash the process, which this test would catch.
#[test]
fn runtime_extern_atoi_str_arg_end_to_end() {
    let src = "extern \"C\" fn atoi(s: str) -> int\nfn main():\n    let s = \"42\"\n    let mut i = 0\n    while i < 20:\n        println(f\"{atoi(s)}\")\n        i += 1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_extern_atoi.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");

    let output = std::process::Command::new(&exe).output().expect("failed to execute extern_atoi.exe");
    assert!(output.status.success(), "should exit cleanly (no crash/double-free): {:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines.len(), 20, "expected 20 lines of output: {}", stdout);
    assert!(lines.iter().all(|l| *l == "42"), "every call should parse to 42: {}", stdout);

    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
}

/// A `ptr` round trip through a real C runtime symbol (`strstr`, always
/// linked on this target, no `-l` needed) -- `null_ptr()`/`is_null`
/// correctly distinguish a null handle from a real one, exercising both a
/// `str` argument and a `ptr` return in the same call. (Previously used
/// `getenv` for this, but `getenv` became a reserved runtime symbol once
/// the `env_get`/`env_set` builtins started declaring it unconditionally --
/// see `crate::codegen::os` -- so this picks a different real CRT symbol
/// with the same `str -> ptr` shape instead, which also drops the
/// dependency on the host process's `PATH` actually being set.)
///
/// Deliberately avoids any Win32 API (`GetModuleHandleA`, `GlobalAlloc`,
/// ...) for two independent reasons that make them unsuitable extern-fn
/// test targets, not just inconvenient ones:
/// (1) Star's grammar reserves `Name(args)` for struct-literal construction
/// whenever `Name` starts with an uppercase letter (`Vec3(0, 0, 0)`,
/// `Player(health = 100)`, ...) -- see `Parser::parse_primary`'s
/// `starts_uppercase` check in `src/parser/expr.rs`. This is a deliberate,
/// load-bearing rule used throughout the language, not something this
/// FFI feature can special-case around -- so a call to `GetModuleHandleA(..)`
/// parses as an attempt to construct a (nonexistent) `GetModuleHandleA`
/// struct instead of a function call. Any extern-fn call site must name a
/// symbol that doesn't start with an uppercase letter.
/// (2) Separately, many Win32 signatures (e.g. `GlobalAlloc`'s `SIZE_T`
/// byte count) have a parameter wider than Star's 32-bit `int` on this
/// x86_64 target, which isn't ABI-safe to bind with the types this FFI
/// surface currently offers (see the plan's "Scope for v1" note).
#[test]
fn runtime_extern_ptr_round_trip_end_to_end() {
    let src = "extern \"C\" fn strstr(haystack: str, needle: str) -> ptr\nfn main():\n    println(f\"{is_null(null_ptr())}\")\n    let missing = strstr(\"hello world\", \"xyz\")\n    println(f\"{is_null(missing)}\")\n    let found = strstr(\"hello world\", \"world\")\n    println(f\"{is_null(found)}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_extern_ptr_roundtrip.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");

    let output = std::process::Command::new(&exe).output().expect("failed to execute extern_ptr_roundtrip.exe");
    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec!["true", "true", "false"],
        "null_ptr() is null; a substring that isn't present yields null; one that is present doesn't: {}",
        stdout
    );

    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
}

/// An `extern "C" fn` sharing a name with a recognized standard-library
/// builtin (e.g. `abs`) is rejected at the declaration, not silently allowed
/// through to become permanently unreachable at every call site --
/// `builtin_return_ty`/`Codegen::emit_expr`'s `TypedExpr::Call` arm both
/// dispatch on name *ahead* of the user function table (see
/// `extern_fn_call_arity_is_checked`'s doc comment), so without this check
/// the extern declaration would compile clean, its `declare` would sit
/// unused in the IR, and every call would quietly run the builtin instead --
/// with no argument/type checking against the real foreign signature.
#[test]
fn extern_fn_rejects_builtin_name_collision() {
    let src = "extern \"C\" fn abs(x: int) -> int\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("extern fn colliding with a builtin name should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("collides with a built-in name")), "{:?}", diags);
}

/// An `extern "C" fn` reusing the name of a symbol `Codegen::emit_builtins`/
/// `emit_rc_runtime` already `declare`s or `define`s unconditionally in every
/// generated module (here, `puts` -- also used by `println`) is rejected at
/// the declaration. Without this check the checker accepts it, codegen
/// happily emits a second `declare i32 @puts(i8*)`, and only clang's LLVM
/// parser rejects it -- with "invalid redefinition of function", pointing at
/// generated IR the user never wrote, not at their `.star` source.
#[test]
fn extern_fn_rejects_reserved_runtime_symbol_name() {
    let src = "extern \"C\" fn puts(s: str) -> int\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("extern fn colliding with a reserved runtime symbol should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("compiler always declares internally")), "{:?}", diags);
}

/// `main` -- the reserved process entry point every program's `fn main()`
/// lowers to (see `Codegen::emit_fn`'s `is_main` special-casing) -- is also a
/// reserved runtime symbol name for this same reason: `extern "C" fn main`
/// would collide with the real, forced-`i32`-return `@main` definition.
#[test]
fn extern_fn_rejects_main_as_reserved_name() {
    let src = "extern \"C\" fn main() -> int\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("extern fn named `main` should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("compiler always declares internally")), "{:?}", diags);
}

/// Two `extern "C" fn` declarations under the same name -- even with
/// byte-for-byte identical signatures -- are rejected at the second
/// declaration. LLVM's textual IR parser refuses a duplicate `declare` for
/// the same global outright (confirmed directly: even two hand-written,
/// identical `declare i32 @puts(i8*)` lines back to back fail clang with
/// "invalid redefinition of function"), so without this check a copy-pasted
/// or accidentally repeated extern declaration would compile clean here and
/// only fail at the clang step.
#[test]
fn extern_fn_rejects_duplicate_declaration() {
    let src = "extern \"C\" fn atoi(s: str) -> int\nextern \"C\" fn atoi(s: str) -> int\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("a duplicate extern fn declaration should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("declared more than once")), "{:?}", diags);
}

/// Calling an `extern "C" fn` *indirectly* through a first-class function
/// value (`let g = some_extern_fn; g(s)`) must release a `str` argument's
/// reference exactly once per call, the same way a direct call
/// (`emit_extern_call`) already does -- see the fix's own doc comment in
/// `Codegen::emit_fn_value` (`src/codegen/closure.rs`). Before that fix, the
/// generated thunk forwarded the argument straight to the extern `declare`
/// and released nothing, leaking one refcount per call (confirmed with a
/// Working-Set memory sample over `examples/extern_fnvalue_stress.star`:
/// unbounded growth from ~15MB to ~146MB over 5,000,000 iterations before
/// the fix, flat at ~3MB after). This test checks the generated IR directly
/// rather than sampling memory (that's `runtime_rc_stress_memory_stays_bounded`'s
/// job for the general RC mechanism; this just needs to confirm the specific
/// release call is present in the specific thunk).
#[test]
fn codegen_extern_fn_value_thunk_releases_str_arg() {
    let src = "extern \"C\" fn atoi(s: str) -> int\nfn main():\n    let g = atoi\n    let s = concat(\"4\", \"2\")\n    g(s)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let thunk_ir = extract_fn_body(&ir, "define i32 @fnval_atoi(");
    assert!(thunk_ir.contains("call i32 @atoi(i8* %arg_0)"), "{}", thunk_ir);
    assert!(
        thunk_ir.contains("call void @star_rc_release(i8* %arg_0)"),
        "the thunk must release the str arg after forwarding the call, since the extern declaration itself never does: {}",
        thunk_ir
    );
}

/// A first-class value referencing an *ordinary* (non-extern) function must
/// not gain a release in its thunk -- that function's own `emit_fn`-generated
/// body already tracks and releases its own `str` params at its own scope
/// exit (see `track_owned`/`pop_scope` in `rc.rs`), so adding a second
/// release in the thunk would double-release (and, on the last reference,
/// double-free) the argument. Guards the `is_extern_target` gate in the
/// fix above -- it must trigger only for a thunk wrapping an extern
/// declaration, never for a thunk wrapping a real Star function.
#[test]
fn codegen_ordinary_fn_value_thunk_does_not_double_release_str_arg() {
    let src = "fn take(s: str) -> int:\n    len(s)\nfn main():\n    let g = take\n    let s = concat(\"4\", \"2\")\n    g(s)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let thunk_ir = extract_fn_body(&ir, "define i32 @fnval_take(");
    assert!(
        !thunk_ir.contains("star_rc_release"),
        "a thunk wrapping an ordinary Star fn must not release its own args -- `take`'s own body already does: {}",
        thunk_ir
    );
}

// ===== File I/O builtins (todo.md "Next Steps" #2) =========================
//
// `file_open` returns `ptr` (null on failure, same convention as `getenv`);
// `file_read`/`file_read_line` return `str` (empty on EOF, same convention as
// `read_line`); `file_write`/`file_exists` return `bool`; a null/closed
// handle passed to `file_read`/`file_read_line`/`file_write`/`file_close` is
// a programmer error and aborts loudly (same convention as frame overflow /
// integer division by zero). See `crate::codegen::file_io`.

/// `file_open` type-checks to `ptr`.
#[test]
fn checks_file_open_returns_ptr() {
    let src = "fn t():\n    let h: ptr = file_open(\"x.txt\", \"r\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("file_open(..) should type-check as ptr");
}

/// `file_read`/`file_read_line` type-check to `str`.
#[test]
fn checks_file_read_and_read_line_return_str() {
    let src = "fn t():\n    let h = file_open(\"x.txt\", \"r\")\n    let a: str = file_read(h)\n    let b: str = file_read_line(h)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("file_read/file_read_line should type-check as str");
}

/// `file_write`/`file_exists` type-check to `bool`.
#[test]
fn checks_file_write_and_exists_return_bool() {
    let src = "fn t():\n    let h = file_open(\"x.txt\", \"w\")\n    let ok: bool = file_write(h, \"data\")\n    let e: bool = file_exists(\"x.txt\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("file_write/file_exists should type-check as bool");
}

/// `file_read` sizes its buffer via `ftell`/`fseek` and allocates through
/// `star_rc_alloc` (a fresh owned `str`), not a bare `malloc`.
#[test]
fn codegen_file_read_uses_ftell_fseek_and_rc_alloc() {
    let src = "fn t() -> str:\n    let h = file_open(\"x.txt\", \"r\")\n    file_read(h)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i8* @t(");
    assert!(fn_ir.contains("call i32 @ftell"), "{}", fn_ir);
    assert!(fn_ir.contains("call i32 @fseek"), "{}", fn_ir);
    assert!(fn_ir.contains("call i8* @star_rc_alloc"), "{}", fn_ir);
    assert!(fn_ir.contains("call i64 @fread"), "{}", fn_ir);
}

/// `file_read_line` reads from the given handle via `@fgetc`, not the
/// stdin-only `@getchar` `read_line()` uses.
#[test]
fn codegen_file_read_line_uses_fgetc_not_getchar() {
    let src = "fn t() -> str:\n    let h = file_open(\"x.txt\", \"r\")\n    file_read_line(h)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i8* @t(");
    assert!(fn_ir.contains("call i32 @fgetc"), "{}", fn_ir);
    assert!(!fn_ir.contains("@getchar"), "file_read_line must not read from stdin: {}", fn_ir);
}

/// `file_close` on a possibly-null handle checks for null and aborts (`exit`
/// + `unreachable`) before ever calling `@fclose`, matching the frame
/// overflow / division-by-zero abort shape elsewhere in this codegen.
#[test]
fn codegen_file_close_aborts_on_null_handle() {
    let src = "fn t():\n    let h = file_open(\"x.txt\", \"r\")\n    file_close(h)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define void @t(");
    assert!(fn_ir.contains("icmp eq i8* "), "should compare the handle against null: {}", fn_ir);
    assert!(fn_ir.contains("call void @exit(i32 1)"), "should abort on a null handle: {}", fn_ir);
    assert!(fn_ir.contains("unreachable"), "{}", fn_ir);
    assert!(fn_ir.contains("call i32 @fclose"), "the ok path should still call fclose: {}", fn_ir);
}

/// Shared helper for the file-I/O runtime tests below: parse/check/codegen
/// `src`, compile it with clang into a uniquely-named temp `.exe`, run it,
/// and return its captured output -- mirrors the inline compile-and-run
/// pattern `runtime_extern_ptr_round_trip_end_to_end` established, extended
/// with a `name` parameter so concurrently-run tests don't collide on the
/// same temp `.ll`/`.exe` path.
fn compile_and_run(name: &str, src: &str) -> std::process::Output {
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join(format!("star_test_{}.exe", name));
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
    output
}

/// A scratch data-file path under the OS temp dir, with backslashes
/// normalized to forward slashes -- `fopen` accepts either on Windows, and
/// forward slashes sidestep needing to double-escape `\` inside the Star
/// string literal embedded in each test's generated source.
fn scratch_file_path(name: &str) -> String {
    std::env::temp_dir().join(name).to_string_lossy().replace('\\', "/")
}

/// Opens a file for writing, writes two `file_write` calls, closes it,
/// reopens for reading, and reads the exact content back via `file_read` --
/// the basic round trip the whole feature exists for (todo.md: "read config,
/// save/load game state").
#[test]
fn runtime_file_write_then_read_end_to_end() {
    let path = scratch_file_path("star_test_file_write_then_read.txt");
    let src = format!(
        "fn main():\n    let p = \"{p}\"\n    let w = file_open(p, \"w\")\n    file_write(w, \"hello \")\n    file_write(w, \"world\")\n    file_close(w)\n    let r = file_open(p, \"r\")\n    let content = file_read(r)\n    file_close(r)\n    println(content)\n",
        p = path
    );
    let output = compile_and_run("file_write_then_read", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "hello world", "file_read should return exactly what file_write wrote: {}", stdout);
    let _ = std::fs::remove_file(&path);
}

/// Writes a 3-line file, then reads it back one line at a time with
/// `file_read_line`; a fourth call past the last line yields an empty `str`
/// rather than crashing or hanging -- the same EOF convention `read_line()`
/// already established for stdin.
#[test]
fn runtime_file_read_line_end_to_end() {
    let path = scratch_file_path("star_test_file_read_line.txt");
    let src = format!(
        "fn main():\n    let p = \"{p}\"\n    let w = file_open(p, \"w\")\n    file_write(w, \"alpha\\nbeta\\ngamma\\n\")\n    file_close(w)\n    let r = file_open(p, \"r\")\n    println(file_read_line(r))\n    println(file_read_line(r))\n    println(file_read_line(r))\n    let last = file_read_line(r)\n    println(f\"last:{{last}}\")\n    file_close(r)\n",
        p = path
    );
    let output = compile_and_run("file_read_line", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["alpha", "beta", "gamma", "last:"], "{}", stdout);
}

/// `file_exists` is `true` for a file that was just created and `false` for
/// a path that was never created.
#[test]
fn runtime_file_exists_end_to_end() {
    let real_path = scratch_file_path("star_test_file_exists_real.txt");
    let missing_path = scratch_file_path("star_test_file_exists_missing.txt");
    let _ = std::fs::remove_file(&missing_path);
    let src = format!(
        "fn main():\n    let real = \"{real}\"\n    let missing = \"{missing}\"\n    let w = file_open(real, \"w\")\n    file_write(w, \"x\")\n    file_close(w)\n    println(f\"{{file_exists(real)}}\")\n    println(f\"{{file_exists(missing)}}\")\n",
        real = real_path,
        missing = missing_path
    );
    let output = compile_and_run("file_exists", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "false"], "{}", stdout);
    let _ = std::fs::remove_file(&real_path);
}

/// `file_open` on a path that doesn't exist (opened for reading) returns a
/// null `ptr`, checked with the existing `is_null(..)` builtin -- the exact
/// convention `getenv` already established for a foreign call that can fail.
#[test]
fn runtime_file_open_missing_file_returns_null_end_to_end() {
    let missing_path = scratch_file_path("star_test_file_open_missing.txt");
    let _ = std::fs::remove_file(&missing_path);
    let src = format!(
        "fn main():\n    let h = file_open(\"{p}\", \"r\")\n    println(f\"{{is_null(h)}}\")\n",
        p = missing_path
    );
    let output = compile_and_run("file_open_missing", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "true", "{}", stdout);
}

/// `file_write` reports `true` on an ordinary successful write.
#[test]
fn runtime_file_write_reports_true_on_success_end_to_end() {
    let path = scratch_file_path("star_test_file_write_success.txt");
    let src = format!(
        "fn main():\n    let w = file_open(\"{p}\", \"w\")\n    let ok = file_write(w, \"data\")\n    file_close(w)\n    println(f\"{{ok}}\")\n",
        p = path
    );
    let output = compile_and_run("file_write_success", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "true", "{}", stdout);
    let _ = std::fs::remove_file(&path);
}

/// Calling `file_read` on a null handle (from a failed `file_open`, used
/// without an `is_null(..)` check) aborts loudly with a diagnostic and a
/// nonzero exit code instead of crashing/segfaulting or hanging -- mirrors
/// `runtime_frame_overflow_aborts_loudly_instead_of_segfaulting` and
/// `runtime_int_division_by_zero_aborts_loudly_instead_of_trapping`'s "trap
/// loudly instead of corrupting/crashing unpredictably" guarantee.
#[test]
fn runtime_file_read_aborts_on_null_handle_end_to_end() {
    let missing_path = scratch_file_path("star_test_file_read_null_handle.txt");
    let _ = std::fs::remove_file(&missing_path);
    let src = format!(
        "fn main():\n    let h = file_open(\"{p}\", \"r\")\n    println(\"before\")\n    let content = file_read(h)\n    println(\"should not reach here\")\n",
        p = missing_path
    );
    let output = compile_and_run("file_read_null_handle", &src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "must abort before the null handle is ever read: {}", stdout);
    assert!(stdout.contains("null/closed file handle"), "should print a diagnostic: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "should exit cleanly with code 1, not crash/segfault: {:?}", output.status);
}

/// Every builtin call (not just ordinary/extern-fn calls) now has its
/// argument count and types validated by `Checker::check_builtin_call_args`,
/// ahead of `crate::codegen::file_io`'s own `args.len() < N` codegen-time
/// checks -- so a wrong argument count is now caught cleanly at type-check
/// time instead of surfacing only once codegen runs (previously the only
/// place this was caught at all; see `checker_rejects_file_open_wrong_arg_count`
/// for the same case one stage earlier, and `checker_rejects_file_open_wrong_arg_types`
/// for the argument-type checks this also added). `file_io.rs`'s own
/// `args.len() < N` guards stay in place as a defense-in-depth fallback.
#[test]
fn checker_rejects_file_open_wrong_arg_count() {
    let src = "fn t():\n    file_open(\"x.txt\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("file_open with 1 argument should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`file_open` expects 2 argument(s)")), "{:?}", diags);
}

/// Same check for `file_write`, which also takes 2 arguments.
#[test]
fn checker_rejects_file_write_wrong_arg_count() {
    let src = "fn t():\n    let h = file_open(\"x.txt\", \"w\")\n    file_write(h)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("file_write with 1 argument should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`file_write` expects 2 argument(s)")), "{:?}", diags);
}

/// `file_write` reports `false` (not a crash, not a thrown exception) when
/// the underlying `fwrite` genuinely can't write -- here, a handle opened
/// read-only. Distinguishes this from the null-handle *abort* path: a
/// non-null but unwritable handle is exactly the "real runtime condition a
/// program can react to" case `emit_file_write`'s own doc comment describes,
/// not a programmer error.
#[test]
fn runtime_file_write_on_read_only_handle_reports_false_end_to_end() {
    let path = scratch_file_path("star_test_file_write_read_only.txt");
    let src = format!(
        "fn main():\n    let w = file_open(\"{p}\", \"w\")\n    file_write(w, \"seed\")\n    file_close(w)\n    let r = file_open(\"{p}\", \"r\")\n    let ok = file_write(r, \"nope\")\n    println(f\"{{ok}}\")\n    file_close(r)\n",
        p = path
    );
    let output = compile_and_run("file_write_read_only", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "false", "writing through a read-mode handle should report false, not abort: {}", stdout);
    let _ = std::fs::remove_file(&path);
}

/// A file whose last line has no trailing newline still yields that line's
/// full content from `file_read_line` (not truncated/lost by the EOF
/// check) -- a subsequent call past it then yields `""`, same EOF
/// convention as every other case. Distinguishes "stopped because of `\n`"
/// from "stopped because of EOF" inside `emit_file_read_line`'s loop, which
/// share a single `stop` flag (`is_eof or is_nl`).
#[test]
fn runtime_file_read_line_without_trailing_newline_end_to_end() {
    let path = scratch_file_path("star_test_file_read_line_no_trailing_nl.txt");
    let src = format!(
        "fn main():\n    let p = \"{p}\"\n    let w = file_open(p, \"w\")\n    file_write(w, \"onlyline\")\n    file_close(w)\n    let r = file_open(p, \"r\")\n    println(f\"a:{{file_read_line(r)}}\")\n    println(f\"b:{{file_read_line(r)}}\")\n    file_close(r)\n",
        p = path
    );
    let output = compile_and_run("file_read_line_no_trailing_nl", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["a:onlyline", "b:"], "{}", stdout);
    let _ = std::fs::remove_file(&path);
}

/// `file_read_line`'s fixed 1024-byte buffer truncates an oversized line at
/// 1023 characters (capacity minus the trailing NUL), leaving the rest
/// unread on the handle -- mirrors `runtime_read_line_truncates_oversized_input`'s
/// guarantee for the stdin-only `read_line()`, applied to the file-backed
/// sibling that reuses the exact same fixed-capacity loop shape (see
/// `emit_file_read_line`'s doc comment).
#[test]
fn runtime_file_read_line_truncates_oversized_line_end_to_end() {
    let path = scratch_file_path("star_test_file_read_line_truncate.txt");
    let long_line = "a".repeat(2000);
    let src = format!(
        "fn main():\n    let p = \"{p}\"\n    let w = file_open(p, \"w\")\n    file_write(w, \"{long}\\nshort\\n\")\n    file_close(w)\n    let r = file_open(p, \"r\")\n    println(file_read_line(r))\n    file_close(r)\n",
        p = path,
        long = long_line
    );
    let output = compile_and_run("file_read_line_truncate", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains(&"a".repeat(1023)), "truncated line should keep its first 1023 bytes: {}", stdout);
    assert!(!stdout.contains(&"a".repeat(1024)), "truncated line should not exceed 1023 bytes: {}", stdout);
    let _ = std::fs::remove_file(&path);
}

/// `file_read` on a file with zero bytes remaining (opened, then
/// immediately read again after already consuming everything) returns `""`
/// rather than a stray byte or a crash -- the `remaining == 0` edge of
/// `emit_file_read`'s `ftell`/`fseek` buffer sizing (`cap64 = 1`, `fread`
/// asked for 0 bytes).
#[test]
fn runtime_file_read_twice_second_call_returns_empty_end_to_end() {
    let path = scratch_file_path("star_test_file_read_twice.txt");
    let src = format!(
        "fn main():\n    let p = \"{p}\"\n    let w = file_open(p, \"w\")\n    file_write(w, \"all\")\n    file_close(w)\n    let r = file_open(p, \"r\")\n    println(f\"first:{{file_read(r)}}\")\n    println(f\"second:{{file_read(r)}}\")\n    file_close(r)\n",
        p = path
    );
    let output = compile_and_run("file_read_twice", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["first:all", "second:"], "{}", stdout);
    let _ = std::fs::remove_file(&path);
}

/// `file_read` on a handle to a non-seekable stream (the `NUL` device, which
/// `fopen` happily opens but which fails `ftell`/`fseek`, returning `-1`)
/// must return `""` instead of corrupting memory -- `emit_file_read` sizes
/// its buffer as `sext(ftell(end) - ftell(start))`, and without clamping a
/// negative result, `-1` sign-extended to `i64` and treated as an unsigned
/// byte count would request a `star_rc_alloc`/`fread` of roughly
/// `u64::MAX` bytes instead of failing cleanly.
#[test]
fn runtime_file_read_on_non_seekable_handle_returns_empty_end_to_end() {
    let src = "fn main():\n    let h = file_open(\"NUL\", \"r\")\n    println(f\"len={len(file_read(h))}\")\n    file_close(h)\n    println(\"done\")\n";
    let output = compile_and_run("file_read_non_seekable", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["len=0", "done"], "{}", stdout);
}

/// Opening a file in append mode (`"a"`) and writing to it adds to the
/// existing content rather than truncating it -- exercises a third `fopen`
/// mode beyond the `"r"`/`"w"` combinations every other test uses, since
/// `file_open` passes its `mode` argument straight through with no
/// validation or special-casing (see `emit_file_open`'s doc comment).
#[test]
fn runtime_file_append_mode_preserves_existing_content_end_to_end() {
    let path = scratch_file_path("star_test_file_append_mode.txt");
    let src = format!(
        "fn main():\n    let p = \"{p}\"\n    let w = file_open(p, \"w\")\n    file_write(w, \"first-\")\n    file_close(w)\n    let a = file_open(p, \"a\")\n    file_write(a, \"second\")\n    file_close(a)\n    let r = file_open(p, \"r\")\n    println(file_read(r))\n    file_close(r)\n",
        p = path
    );
    let output = compile_and_run("file_append_mode", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "first-second", "append mode should add to, not replace, existing content: {}", stdout);
    let _ = std::fs::remove_file(&path);
}

// ===== Networking (todo.md #3: raw TCP socket builtins) ====================
//
// `tcp_connect`/`tcp_send`/`tcp_recv`/`tcp_close` (`crate::codegen::net`)
// wrap Winsock2's `socket`/`connect`/`send`/`recv`/`closesocket`, mirroring
// the file-I/O builtins' conventions: `tcp_connect` returns a null `ptr` on
// failure (checked with `is_null`, same as `file_open`), `tcp_recv` returns
// `""` on a closed connection (same EOF convention as `file_read`), and a
// null/closed handle passed to `tcp_send`/`tcp_recv`/`tcp_close` aborts
// loudly instead of corrupting/crashing. Unlike the file-I/O builtins these
// need `ws2_32` linked explicitly (`compile_and_run_linked` below), and the
// runtime tests need a real listening peer -- provided by a `std::net`
// `TcpListener` spun up inside the *Rust* test itself, not by another Star
// program.

/// Like `compile_and_run`, but also passes extra `-l<name>` link flags to
/// clang -- needed because Winsock2 isn't part of this target's implicitly-
/// linked default libraries (see `Codegen::emit_builtins`'s `net.rs` doc
/// comment), so any test exercising `tcp_*` builtins must link `ws2_32`
/// explicitly, the same way a real `star build` invocation would need
/// `-l ws2_32` passed on the command line.
fn compile_and_run_linked(name: &str, src: &str, libs: &[&str]) -> std::process::Output {
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join(format!("star_test_{}.exe", name));
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let mut cmd_args = vec!["-O0".to_string(), ll.to_str().unwrap().to_string(), "-o".to_string(), exe.to_str().unwrap().to_string()];
    cmd_args.extend(libs.iter().map(|l| format!("-l{}", l)));
    let status = std::process::Command::new("clang").args(&cmd_args).status().expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");
    let output = std::process::Command::new(&exe).output().expect("failed to execute compiled test binary");
    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
    output
}

/// `tcp_connect` type-checks to `ptr`, the same opaque-handle convention
/// `file_open` established.
#[test]
fn checks_tcp_connect_returns_ptr() {
    let src = "fn t():\n    let h: ptr = tcp_connect(\"127.0.0.1\", 80)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("tcp_connect(..) should type-check as ptr");
}

/// `tcp_send`/`tcp_recv` type-check to `bool`/`str` respectively.
#[test]
fn checks_tcp_send_and_recv_return_types() {
    let src = "fn t():\n    let h = tcp_connect(\"127.0.0.1\", 80)\n    let ok: bool = tcp_send(h, \"data\")\n    let r: str = tcp_recv(h)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("tcp_send/tcp_recv should type-check as bool/str");
}

/// `tcp_close` type-checks with no meaningful return value, same as
/// `file_close`.
#[test]
fn checks_tcp_close_type_checks() {
    let src = "fn t():\n    let h = tcp_connect(\"127.0.0.1\", 80)\n    tcp_close(h)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("tcp_close(..) should type-check");
}

/// A wrong argument count for `tcp_connect` is caught at type-check time
/// (`Checker::check_builtin_call_args`), not left to fail confusingly at the
/// `clang` step -- mirrors `checker_rejects_file_open_wrong_arg_count`.
#[test]
fn checker_rejects_tcp_connect_wrong_arg_count() {
    let src = "fn t():\n    tcp_connect(\"127.0.0.1\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("tcp_connect with 1 argument should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`tcp_connect` expects 2 argument(s)")), "{:?}", diags);
}

/// `tcp_connect`'s second argument must be `int` (the port), not `str` --
/// exercises the argument-type check, not just arity.
#[test]
fn checker_rejects_tcp_connect_wrong_arg_type() {
    let src = "fn t():\n    tcp_connect(\"127.0.0.1\", \"80\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("tcp_connect with a str port should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`tcp_connect` argument 2 expected `int`")), "{:?}", diags);
}

/// Same check for `tcp_send`, which also takes 2 arguments (`ptr`, `str`).
#[test]
fn checker_rejects_tcp_send_wrong_arg_count() {
    let src = "fn t():\n    let h = tcp_connect(\"127.0.0.1\", 80)\n    tcp_send(h)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("tcp_send with 1 argument should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`tcp_send` expects 2 argument(s)")), "{:?}", diags);
}

/// `tcp_close` on a possibly-null handle checks for null and aborts before
/// ever calling `@closesocket` -- same shape as
/// `codegen_file_close_aborts_on_null_handle`.
#[test]
fn codegen_tcp_close_aborts_on_null_handle() {
    let src = "fn t():\n    let h = tcp_connect(\"127.0.0.1\", 80)\n    tcp_close(h)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define void @t(");
    assert!(fn_ir.contains("icmp eq i8* "), "should compare the handle against null: {}", fn_ir);
    assert!(fn_ir.contains("call void @exit(i32 1)"), "should abort on a null handle: {}", fn_ir);
    assert!(fn_ir.contains("unreachable"), "{}", fn_ir);
    assert!(fn_ir.contains("call i32 @closesocket"), "the ok path should still call closesocket: {}", fn_ir);
}

/// `tcp_connect` against a port nobody is listening on returns a null `ptr`
/// (checked via `is_null`), the same "null on failure" convention
/// `file_open` established, rather than crashing or hanging.
#[test]
fn runtime_tcp_connect_refused_returns_null_end_to_end() {
    // Bind-then-immediately-drop a listener to claim an OS-assigned port
    // that's guaranteed to have nothing listening on it by the time the
    // compiled Star program tries to connect.
    let listener = std::net::TcpListener::bind("127.0.0.1:0").expect("failed to bind scratch listener");
    let port = listener.local_addr().expect("failed to read local addr").port();
    drop(listener);

    let src = format!("fn main():\n    let h = tcp_connect(\"127.0.0.1\", {port})\n    println(f\"{{is_null(h)}}\")\n", port = port);
    let output = compile_and_run_linked("tcp_connect_refused", &src, &["ws2_32"]);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "true", "connecting to a port with no listener should yield a null handle: {}", stdout);
}

/// The basic round trip the whole feature exists for (todo.md: "needed for
/// anything client/server"): connect to a real listener, send a message,
/// and receive a reply, driven against a `std::net::TcpListener` running in
/// this Rust test process itself (not another Star program).
#[test]
fn runtime_tcp_connect_send_recv_round_trip_end_to_end() {
    use std::io::{Read, Write};

    let listener = std::net::TcpListener::bind("127.0.0.1:0").expect("failed to bind scratch listener");
    let port = listener.local_addr().expect("failed to read local addr").port();
    let server = std::thread::spawn(move || {
        let (mut conn, _) = listener.accept().expect("failed to accept connection");
        let mut buf = [0u8; 64];
        let n = conn.read(&mut buf).expect("failed to read from client");
        assert_eq!(&buf[..n], b"ping", "server should receive exactly what the client sent");
        conn.write_all(b"pong").expect("failed to write reply");
    });

    let src = format!(
        "fn main():\n    let h = tcp_connect(\"127.0.0.1\", {port})\n    let ok = tcp_send(h, \"ping\")\n    println(f\"sent:{{ok}}\")\n    let reply = tcp_recv(h)\n    println(f\"reply:{{reply}}\")\n    tcp_close(h)\n",
        port = port
    );
    let output = compile_and_run_linked("tcp_round_trip", &src, &["ws2_32"]);
    server.join().expect("server thread panicked");
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["sent:true", "reply:pong"], "{}", stdout);
}

/// `tcp_recv` on a connection the peer has closed gracefully (without
/// sending anything) returns `""`, the same EOF convention
/// `file_read`/`read_line` established, rather than blocking forever or
/// reporting an error.
#[test]
fn runtime_tcp_recv_on_peer_closed_connection_returns_empty_end_to_end() {
    let listener = std::net::TcpListener::bind("127.0.0.1:0").expect("failed to bind scratch listener");
    let port = listener.local_addr().expect("failed to read local addr").port();
    let server = std::thread::spawn(move || {
        let (conn, _) = listener.accept().expect("failed to accept connection");
        drop(conn); // close immediately, sending nothing
    });

    let src = format!(
        "fn main():\n    let h = tcp_connect(\"127.0.0.1\", {port})\n    let reply = tcp_recv(h)\n    println(f\"reply:{{reply}}\")\n    tcp_close(h)\n",
        port = port
    );
    let output = compile_and_run_linked("tcp_recv_peer_closed", &src, &["ws2_32"]);
    server.join().expect("server thread panicked");
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "reply:", "a gracefully closed peer should yield an empty recv, not hang or error: {}", stdout);
}

/// Calling `tcp_send` on a null handle (from a failed `tcp_connect`, used
/// without an `is_null(..)` check) aborts loudly with a diagnostic and a
/// nonzero exit code instead of crashing/segfaulting -- mirrors
/// `runtime_file_read_aborts_on_null_handle_end_to_end`.
#[test]
fn runtime_tcp_send_aborts_on_null_handle_end_to_end() {
    let listener = std::net::TcpListener::bind("127.0.0.1:0").expect("failed to bind scratch listener");
    let port = listener.local_addr().expect("failed to read local addr").port();
    drop(listener);

    let src = format!(
        "fn main():\n    let h = tcp_connect(\"127.0.0.1\", {port})\n    println(\"before\")\n    let ok = tcp_send(h, \"x\")\n    println(\"should not reach here\")\n",
        port = port
    );
    let output = compile_and_run_linked("tcp_send_null_handle", &src, &["ws2_32"]);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "must abort before the null handle is ever used: {}", stdout);
    assert!(stdout.contains("null/closed socket handle"), "should print a diagnostic: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "should exit cleanly with code 1, not crash/segfault: {:?}", output.status);
}

// ===== Method-call receiver resolution =====================================
//
// `Codegen::emit_call_expr`'s method-call path used to resolve a call's
// receiver pointer via a bespoke `receiver_name`+`sym_ptr` combo that only
// recognized a bare local-variable identifier as `base`
// (`obj.method(args)`) -- any other receiver shape silently fell back to
// `String::new()` -> `sym_ptr("")` -> `None` -> the literal string
// `"%undef"` used as the receiver pointer operand, producing invalid LLVM
// IR ("use of undefined value '%undef'") at the `clang` step. This broke
// the very ordinary OO idiom of one method calling another through `self`,
// plus any other non-bare-identifier receiver. Fixed by routing through
// `Codegen::emit_place`, which already correctly resolves `Ident`, `self`,
// nested `Field` accesses, and arbitrary rvalues (spilled into a fresh
// alloca) to a real storage address.

/// A method calling a sibling method through `self` -- the single most
/// ordinary receiver shape after a bare local, and the one that previously
/// produced `%undef` and failed to compile at all.
#[test]
fn runtime_method_call_through_self_end_to_end() {
    let src = concat!(
        "struct Counter:\n",
        "    val: i32\n",
        "impl Counter:\n",
        "    fn bump(self) -> i32:\n",
        "        self.val + 1\n",
        "    fn double_bump(self) -> i32:\n",
        "        self.bump() + self.bump()\n",
        "fn main():\n",
        "    let c = Counter(val = 10)\n",
        "    println(f\"{c.double_bump()}\")\n",
    );
    let output = compile_and_run("method_call_through_self", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "22", "self.bump() + self.bump() on val=10 should be 22: {}", stdout);
}

/// A method call on a nested field access (`obj.inner.method()`) -- another
/// receiver shape `receiver_name` previously couldn't resolve (a `Field`
/// base, not a bare `Ident`).
#[test]
fn runtime_method_call_on_nested_field_receiver_end_to_end() {
    let src = concat!(
        "struct Inner:\n",
        "    val: i32\n",
        "struct Outer:\n",
        "    inner: Inner\n",
        "impl Inner:\n",
        "    fn get(self) -> i32:\n",
        "        self.val\n",
        "fn main():\n",
        "    let o = Outer(inner = Inner(val = 42))\n",
        "    println(f\"{o.inner.get()}\")\n",
    );
    let output = compile_and_run("method_call_on_nested_field", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "42", "{}", stdout);
}

/// A method call chained directly onto a list-index expression
/// (`list[i].method()`) -- a receiver that is neither a bare `Ident` nor a
/// `Field`, so it exercises `emit_place`'s dedicated `ListIndex` arm
/// (`Codegen::emit_list_index_place`) rather than either of its
/// named-storage arms. (Before that arm existed, this fell into the generic
/// fallback -- fine for this particular test since `get` never mutates, but
/// see `runtime_nested_list_index_receiver_push_mutates_through_index_end_to_end`
/// for the mutating case that fallback got wrong.)
#[test]
fn runtime_method_call_on_list_index_receiver_end_to_end() {
    let src = concat!(
        "struct Counter:\n",
        "    val: i32\n",
        "impl Counter:\n",
        "    fn get(self) -> i32:\n",
        "        self.val\n",
        "fn main():\n",
        "    let mut list = List<Counter>()\n",
        "    list.push(Counter(val = 7))\n",
        "    list.push(Counter(val = 9))\n",
        "    println(f\"{list[1].get()}\")\n",
    );
    let output = compile_and_run("method_call_on_list_index", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "9", "{}", stdout);
}

// ===== Method name mangling (per-struct method tables) =====================
//
// Both `Checker::check`'s registration pass and `Codegen::emit_fn` used to
// key every impl method by its *bare* method name alone -- `self.functions`
// (checker) and the emitted LLVM function itself (codegen: `define @{name}`)
// -- shared with every other function/method in the module. Two unrelated
// structs declaring a same-named method (`impl A: fn area(self) -> i32`,
// `impl B: fn area(self, scale: i32) -> i32`) collided: the checker
// type-checked every `.area()` call site against whichever impl happened to
// be registered last (wrong argument/return-type validation, or a
// false-positive arity error on perfectly valid code), and codegen emitted
// two `define @area(...)` globals under the identical LLVM name, which
// clang rejected outright ("invalid redefinition of function") even when
// both methods' signatures happened to agree. Fixed by keying methods
// per-struct: `Checker::methods`/`Codegen::methods`, both keyed by
// `"{struct}#{method}"`, with the emitted LLVM function itself mangled to
// `{struct}__{method}` (`Codegen::emit_fn`'s `owner` parameter).

/// Two unrelated structs declaring a same-named method with *different*
/// arity must not collide: previously this was rejected by the checker with
/// a bogus "expects 1 argument(s), found 0" (validated against whichever
/// impl was registered last in the flat, name-keyed table) even though
/// `a.area()` supplies exactly the right number of arguments for `A::area`.
#[test]
fn checks_same_named_methods_on_different_structs_with_different_arity() {
    let src = concat!(
        "struct A:\n",
        "    x: i32\n",
        "struct B:\n",
        "    y: i32\n",
        "impl A:\n",
        "    fn area(self) -> i32:\n",
        "        return 1\n",
        "impl B:\n",
        "    fn area(self, scale: i32) -> i32:\n",
        "        return scale\n",
        "fn main():\n",
        "    let a = A(5)\n",
        "    println(f\"{a.area()}\")\n",
    );
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "{:?}", Driver::check(&module).err());
}

/// Two unrelated structs declaring a same-named method with the *same*
/// arity/signature shape must still dispatch to the correct implementation
/// (not just type-check) and must not collide as duplicate LLVM globals --
/// previously this failed at the `clang` step with "invalid redefinition of
/// function 'area'" regardless of whether the checker accepted the source.
#[test]
fn runtime_same_named_methods_on_different_structs_dispatch_correctly_end_to_end() {
    let src = concat!(
        "struct A:\n",
        "    x: i32\n",
        "struct B:\n",
        "    y: i32\n",
        "impl A:\n",
        "    fn area(self) -> i32:\n",
        "        return self.x * 2\n",
        "impl B:\n",
        "    fn area(self) -> i32:\n",
        "        return self.y * 100\n",
        "fn main():\n",
        "    let a = A(5)\n",
        "    let b = B(3)\n",
        "    println(f\"a.area={a.area()} b.area={b.area()}\")\n",
    );
    let output = compile_and_run("method_name_collision", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "a.area=10 b.area=300", "{}", stdout);
}

/// Codegen-shape check: an impl method's emitted LLVM function is mangled
/// as `{struct}__{method}`, not the bare method name, so two structs'
/// same-named methods never collide as duplicate `define`s regardless of
/// what a runtime test's specific call sites happen to exercise.
#[test]
fn codegen_impl_method_llvm_name_is_mangled_by_struct() {
    let src = concat!(
        "struct A:\n",
        "    x: i32\n",
        "impl A:\n",
        "    fn area(self) -> i32:\n",
        "        return self.x\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i32 @A__area(%A* %self)"), "{}", ir);
    assert!(!ir.contains("define i32 @area("), "the bare, unmangled method name must never be emitted as a global: {}", ir);
}

// ===== Builtin call argument validation =====================================
//
// `Checker::check_builtin_call_args` validates argument count and types for
// every builtin call -- previously, builtins (dispatched via
// `builtin_return_ty` ahead of the ordinary function table) had *no*
// argument validation at all beyond `print`/`println`'s own special case,
// so a call like `file_open(42, 3.5)` or `clamp("x", 1, 5)` type-checked
// cleanly and only failed later at the `clang` step with a confusing
// "expected value token"/"use of undefined value" error pointing at
// generated IR the user never wrote, since several builtin codegen
// functions (`emit_abs`/`emit_dot`/`emit_clamp`/`emit_lerp`/
// `emit_file_open`/...) `untag` an argument's register using *another*
// argument's inferred type rather than a type of their own choosing.

/// A scalar builtin (`sqrt`) rejects a non-numeric argument at type-check
/// time instead of producing invalid IR at the `clang` step.
#[test]
fn checker_rejects_sqrt_non_numeric_arg() {
    let src = "fn t():\n    sqrt(\"nope\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("sqrt(\"nope\") should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("sqrt") && d.message.contains("numeric")), "{:?}", diags);
}

/// `dot`/`length` are the two "own type" `untag` calls `emit_dot`/
/// `emit_length` make against a single argument's inferred type -- `dot`
/// additionally assumes both arguments share the very same vector type
/// (`emit_dot` untags `b` using `a`'s type), so a `Vec2`/`Vec3` mismatch is
/// exactly the case previously invisible to the checker.
#[test]
fn checker_rejects_dot_with_mismatched_vector_types() {
    let src = "fn t():\n    dot(Vec2(1.0, 2.0), Vec3(1.0, 2.0, 3.0))\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("dot(..) with mismatched vector types should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`dot`") && d.message.contains("same vector type")), "{:?}", diags);
}

/// `clamp(x, lo, hi)` assumes `lo`/`hi` share `x`'s type (`emit_clamp`
/// dispatches on `x`'s type alone, then `untag`s all three the same way) --
/// a `float` bound against an `int` value is exactly the mismatch that
/// previously slipped through to a codegen-level type mismatch.
#[test]
fn checker_rejects_clamp_with_mismatched_bound_types() {
    let src = "fn t():\n    clamp(3, 1.0, 5.0)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("clamp(..) with mismatched bound types should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`clamp`")), "{:?}", diags);
}

/// `min`/`max` are the one deliberately-polymorphic case that must stay
/// permissive: `emit_minmax` promotes whichever operand is `int` to `float`
/// via each argument's own inferred type (not a shared expected type), so a
/// mixed `int`/`float` call is valid and must still type-check.
#[test]
fn checker_accepts_min_with_mixed_int_and_float_args() {
    // `min`/`max` preserve the *first* argument's type (see
    // `builtin_return_ty`), so `min(3, 2.5)` is `int`-typed even though its
    // second argument is `float` -- that's the pre-existing, deliberate
    // polymorphism this test guards against becoming over-strict, not a
    // claim about the result's own type.
    let src = "fn t() -> i32:\n    min(3, 2.5)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("min(int, float) is valid and should type-check");
}

/// `is_null`/`ptr_to_str`/`file_close`/`file_read`/`file_read_line` all
/// expect a `ptr` argument -- passing an ordinary `int` is exactly the
/// misuse `Codegen::untag`'s silent no-op fallback (`unwrap_or(s)`, see its
/// doc comment) would otherwise smuggle through as invalid IR.
#[test]
fn checker_rejects_is_null_non_ptr_arg() {
    let src = "fn t():\n    is_null(42)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("is_null(42) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`is_null`") && d.message.contains("ptr")), "{:?}", diags);
}

/// `file_open(path, mode)` expects both arguments to be `str` -- this is
/// the concrete repro that motivated adding builtin argument validation at
/// all: `file_open(42, 3.5)` previously type-checked cleanly and only
/// failed at the `clang` step with "expected value token" pointing at
/// `call i8* @fopen(i8* i32 42, i8* float ...)`.
#[test]
fn checker_rejects_file_open_wrong_arg_types() {
    let src = "fn t():\n    file_open(42, 3.5)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("file_open(42, 3.5) should fail to type-check") };
    assert_eq!(diags.iter().filter(|d| d.message.contains("`file_open`")).count(), 2, "both arguments are wrong: {:?}", diags);
}

/// `file_write(handle, data)` expects `ptr` then `str` -- swapping them
/// (a plausible mistake, both are single-argument-shaped) should be
/// rejected rather than silently misdirecting `fwrite`'s buffer/length
/// operands.
#[test]
fn checker_rejects_file_write_swapped_arg_types() {
    let src = "fn t():\n    let h = file_open(\"x.txt\", \"w\")\n    file_write(\"data\", h)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("file_write with swapped argument types should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`file_write`")), "{:?}", diags);
}

/// Every valid file-I/O call shape still type-checks cleanly -- a sanity
/// check that `check_builtin_call_args` didn't become so strict it rejects
/// legitimate use, run alongside the existing `runtime_file_*_end_to_end`
/// tests that already exercise these calls end-to-end.
#[test]
fn checker_accepts_well_typed_file_io_calls() {
    let src = "fn t():\n    let h = file_open(\"x.txt\", \"w\")\n    file_write(h, \"data\")\n    file_close(h)\n    let r = file_open(\"x.txt\", \"r\")\n    let a = file_read(r)\n    let b = file_read_line(r)\n    let e = file_exists(\"x.txt\")\n    file_close(r)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("well-typed file I/O calls should type-check");
}

// ===== Minimal OS surface: args()/env_get/env_set (todo.md #2) =============

/// `args()`/`env_get`/`env_set` resolve to proper (non-`unknown`) types
/// through the checker, same as every other builtin -- `args()` returns
/// `List<str>` (not just `str`/`bool`), so this also exercises
/// `builtin_return_ty` producing a `Ty::List` for a builtin with no
/// arguments to infer an element type from.
#[test]
fn checks_os_surface_builtin_return_types() {
    let src = "fn t():\n    let a: List<str> = args()\n    let s: str = env_get(\"PATH\")\n    let b: bool = env_set(\"X\", \"Y\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("well-typed args()/env_get/env_set calls should type-check");
}

/// `args()` takes no arguments -- passing any is rejected by
/// `Checker::check_builtin_call_args`, same as `read_line()`/`rand()`.
#[test]
fn checker_rejects_args_with_arguments() {
    let src = "fn t():\n    args(1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("args(1) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`args` expects 0 argument(s), found 1")), "{:?}", diags);
}

/// `env_get(name)` expects exactly 1 `str` argument.
#[test]
fn checker_rejects_env_get_wrong_arg_count() {
    let src = "fn t():\n    env_get()\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("env_get() should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`env_get` expects 1 argument(s), found 0")), "{:?}", diags);
}

/// `env_get(42)` -- a non-`str` argument -- is rejected rather than
/// smuggled through to `emit_env_get`'s `emit_raw_str_ptr`, which assumes
/// its argument is already a `str`.
#[test]
fn checker_rejects_env_get_non_str_arg() {
    let src = "fn t():\n    env_get(42)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("env_get(42) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`env_get` expects a `str` argument")), "{:?}", diags);
}

/// `env_set(name, value)` expects exactly 2 arguments.
#[test]
fn checker_rejects_env_set_wrong_arg_count() {
    let src = "fn t():\n    env_set(\"X\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("env_set(\"X\") should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`env_set` expects 2 argument(s), found 1")), "{:?}", diags);
}

/// `env_set(name, value)` expects both arguments to be `str` -- swapping in
/// an `int` for either is rejected rather than reaching `emit_env_set`'s
/// `strlen`/`strcpy` calls with the wrong operand type.
#[test]
fn checker_rejects_env_set_non_str_args() {
    let src = "fn t():\n    env_set(1, 2)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("env_set(1, 2) should fail to type-check") };
    assert_eq!(diags.iter().filter(|d| d.message.contains("`env_set`")).count(), 2, "both arguments are wrong: {:?}", diags);
}

/// `getenv`/`_putenv` -- the real CRT symbols `env_get`/`env_set` lower to
/// (see `crate::codegen::os`) -- are reserved runtime symbol names, same as
/// `puts`/`malloc`/etc: an `extern "C" fn getenv` would collide with the
/// `declare i8* @getenv(i8*)` `Codegen::emit_builtins` always emits.
#[test]
fn extern_fn_rejects_getenv_as_reserved_name() {
    let src = "extern \"C\" fn getenv(name: str) -> ptr\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("extern fn named `getenv` should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("compiler always declares internally")), "{:?}", diags);
}

/// `main`'s real, OS-called LLVM signature always accepts `i32 %.argc, i8**
/// %.argv` -- regardless of Star `fn main()`'s own declared (empty)
/// parameter list -- so `args()` can read the real process argv from
/// anywhere, not just from an explicitly-threaded parameter. See
/// `Codegen::emit_fn`'s `is_main` special case.
#[test]
fn codegen_main_accepts_argc_argv_params() {
    let src = "fn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i32 @main(i32 %.argc, i8** %.argv)"), "{}", ir);
    let main_body = extract_fn_body(&ir, "define i32 @main(");
    assert!(main_body.contains("store i32 %.argc, i32* @star.argc"), "{}", main_body);
    assert!(main_body.contains("store i8** %.argv, i8*** @star.argv"), "{}", main_body);
}

/// Like `compile_and_run`, but also passes extra `argv` entries and/or
/// preset environment variables to the compiled binary -- needed to
/// exercise `args()`/`env_get` end to end, since both read real
/// OS-supplied process state `compile_and_run`'s bare `.output()` call
/// doesn't control.
fn compile_and_run_with(name: &str, src: &str, extra_args: &[&str], envs: &[(&str, &str)]) -> std::process::Output {
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join(format!("star_test_{}.exe", name));
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");
    let mut cmd = std::process::Command::new(&exe);
    cmd.args(extra_args);
    for (k, v) in envs {
        cmd.env(k, v);
    }
    let output = cmd.output().expect("failed to execute compiled test binary");
    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
    output
}

/// `args()` includes `argv[0]` (the program path) plus every extra
/// command-line argument the process was actually launched with, in order
/// -- the same convention the underlying OS/CRT argv itself uses (see
/// `Codegen::emit_args`'s doc comment).
#[test]
fn runtime_args_includes_program_path_and_extra_args_end_to_end() {
    let src = "fn main():\n    let a = args()\n    println(f\"{a.len()}\")\n    println(a[1])\n    println(a[2])\n";
    let output = compile_and_run_with("args_extra", src, &["alpha", "beta"], &[]);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["3", "alpha", "beta"], "argv[0] + 2 extra args: {}", stdout);
}

/// With no extra command-line arguments, `args()` still has exactly one
/// element -- `argv[0]`, the program's own path -- never an empty list.
#[test]
fn runtime_args_has_only_program_path_when_no_extra_args_end_to_end() {
    let src = "fn main():\n    let a = args()\n    println(f\"{a.len()}\")\n";
    let output = compile_and_run_with("args_none", src, &[], &[]);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "1", "argv[0] alone: {}", stdout);
}

/// `env_get` on a variable that was never set yields `""` (empty `str`),
/// matching `read_line`/`file_read`'s established EOF convention, rather
/// than a null `ptr` or a crash.
#[test]
fn runtime_env_get_missing_var_returns_empty_string_end_to_end() {
    let src = "fn main():\n    let missing = env_get(\"STAR_TEST_DEFINITELY_UNSET_VAR_ABC123\")\n    println(f\"[{missing}]\")\n";
    let output = compile_and_run_with("env_get_missing", src, &[], &[]);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "[]", "{}", stdout);
}

/// `env_get` reads a variable that was actually set in the process's
/// environment before it started (not just one `env_set` from within the
/// same run) -- exercises the real `getenv` round trip end to end, not just
/// the same-process `env_set` -> `env_get` path.
#[test]
fn runtime_env_get_reads_preset_environment_variable_end_to_end() {
    let src = "fn main():\n    println(env_get(\"STAR_TEST_PRESET_VAR\"))\n";
    let output = compile_and_run_with("env_get_preset", src, &[], &[("STAR_TEST_PRESET_VAR", "hello from the environment")]);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "hello from the environment", "{}", stdout);
}

/// `env_set` reports success (`true`) and the variable it just set is
/// immediately visible to `env_get` within the same process -- the
/// `_putenv`-backed round trip `emit_env_set`'s doc comment describes.
#[test]
fn runtime_env_set_round_trip_end_to_end() {
    let src = "fn main():\n    let ok = env_set(\"STAR_TEST_ROUND_TRIP_VAR\", \"round trip value\")\n    println(f\"{ok}\")\n    println(env_get(\"STAR_TEST_ROUND_TRIP_VAR\"))\n";
    let output = compile_and_run_with("env_set_round_trip", src, &[], &[]);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "round trip value"], "{}", stdout);
}

/// `env_set` on an already-set variable overwrites its value (rather than,
/// say, silently failing or appending) -- distinguishes "set" from
/// "set-if-absent" semantics.
#[test]
fn runtime_env_set_overwrites_existing_value_end_to_end() {
    let src = "fn main():\n    let ok = env_set(\"STAR_TEST_OVERWRITE_VAR\", \"new value\")\n    println(f\"{ok}\")\n    println(env_get(\"STAR_TEST_OVERWRITE_VAR\"))\n";
    let output = compile_and_run_with("env_set_overwrite", src, &[], &[("STAR_TEST_OVERWRITE_VAR", "old value")]);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "new value"], "{}", stdout);
}

/// An f-string used as an ordinary value (bound to a `let`, not passed
/// directly as `print`/`println`'s sole argument) must actually substitute
/// its interpolated values, not just return the raw, unformatted
/// `"...%d...\0"`-style template pointer. Before this was fixed,
/// `Codegen::emit_expr`'s `TypedExpr::FStr` arm built the format string and
/// evaluated each hole's expression into `arg_vals` but never consumed
/// `arg_vals` at all -- it returned the bare format-string pointer, so `s`
/// held literal `%d` bytes and printing it later fed `printf` a format
/// string with unsupplied varargs, segfaulting. This only affected the
/// non-print-argument path; `println(f"...")`/`print(f"...")` directly had
/// their own separate, correct codegen in `emit_print_like` all along.
#[test]
fn runtime_fstring_bound_to_let_then_printed_end_to_end() {
    let src = "fn main():\n    let x = 42\n    let s = f\"x is {x}!\"\n    print(s)\n";
    let output = compile_and_run("fstring_let_then_print", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout, "x is 42!", "f-string bound to a `let` must substitute its hole and add no extra newline: {}", stdout);
}

/// The same bug, reached via a function return instead of a `let` --
/// confirms the fix isn't specific to one particular non-print consumer of
/// an f-string value.
#[test]
fn runtime_fstring_returned_from_function_end_to_end() {
    let src = "fn make_msg(x: i32) -> str:\n    return f\"value={x}\"\n\nfn main():\n    let s = make_msg(7)\n    println(s)\n";
    let output = compile_and_run("fstring_returned_from_fn", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "value=7", "{}", stdout);
}

/// Every interpolation-hole type this codegen path supports (`i32`, `float`,
/// `bool`, `str`) substitutes correctly when the f-string is materialized as
/// a value rather than printed directly -- `bool` in particular needs
/// `emit_bool_str`'s "true"/"false" conversion, not a raw `%p`-formatted `i1`.
#[test]
fn runtime_fstring_value_all_hole_types_end_to_end() {
    let src = "fn main():\n    let b = true\n    let f = 3.5\n    let name = \"star\"\n    let s = f\"b={b} f={f} name={name}\"\n    println(s)\n";
    let output = compile_and_run("fstring_value_all_hole_types", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "b=true f=3.500000 name=star", "{}", stdout);
}

/// An f-string value built from a `str` binding (a borrowing read, not a
/// fresh construction) must not corrupt or prematurely release the original
/// binding -- the interpolation hole only reads the bytes for `snprintf`.
#[test]
fn runtime_fstring_value_borrowing_str_read_does_not_corrupt_original_end_to_end() {
    let src = "fn main():\n    let name = \"world\"\n    let s = f\"hello {name}\"\n    println(s)\n    println(name)\n";
    let output = compile_and_run("fstring_value_borrowing_read", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["hello world", "world"], "{}", stdout);
}

/// A non-print f-string value can be built from another non-print f-string
/// value's result (nested interpolation) and passed through `concat` --
/// confirms the materialized buffer is an ordinary, fully-usable `str`.
#[test]
fn runtime_fstring_value_nested_and_concat_end_to_end() {
    let src = "fn main():\n    let name = \"star\"\n    let s2 = f\"nested: {f\"{name}!\"}\"\n    println(s2)\n    let s3 = concat(f\"a{1}\", f\"b{2}\")\n    println(s3)\n";
    let output = compile_and_run("fstring_value_nested_concat", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["nested: star!", "a1b2"], "{}", stdout);
}

// ===== match exhaustiveness ==================================================

/// A `match` over an enum that neither covers every variant nor has a
/// wildcard/binding catch-all must be rejected -- previously nothing checked
/// this at all, and the generated code fell through to an `undef` value at
/// runtime (see `Codegen::emit_expr`'s `TypedExpr::Match` arm's "no arm
/// matched" fallthrough path, which assumes this was already validated).
#[test]
fn rejects_non_exhaustive_match_over_enum() {
    let src = "enum Dir:\n    North\n    South\n    East\n    West\nfn describe(d: Dir) -> i32:\n    match d:\n        Dir::North -> 1\n        Dir::South -> 2\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("a match missing enum variants with no wildcard should be rejected")
    };
    assert!(
        errs.iter().any(|d| d.message.contains("non-exhaustive") && d.message.contains("East") && d.message.contains("West")),
        "{:?}",
        errs
    );
}

/// A `match` over an enum that covers every variant explicitly (no wildcard
/// needed) must still type-check -- guards against the exhaustiveness check
/// above being so aggressive it rejects sound, ordinary code (this is
/// exactly the shape `examples/control_flow.star`'s `Dir` match already
/// uses).
#[test]
fn accepts_exhaustive_match_over_enum_covering_every_variant_without_wildcard() {
    let src = "enum Dir:\n    North\n    South\nfn describe(d: Dir) -> i32:\n    match d:\n        Dir::North -> 1\n        Dir::South -> 2\nfn main():\n    println(f\"{describe(Dir::North)}\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("a match covering every enum variant should type-check without a wildcard");
}

/// Same bug, `bool` scrutinee: only `true` is covered, `false` isn't, and
/// there's no wildcard.
#[test]
fn rejects_non_exhaustive_match_over_bool() {
    let src = "fn describe(b: bool) -> i32:\n    match b:\n        true -> 1\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("a bool match missing `false` and no wildcard should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("non-exhaustive") && d.message.contains("bool")), "{:?}", errs);
}

/// Same bug, an unbounded scalar domain (`i32`): a finite set of
/// `Compare`/literal patterns can never be proven to cover every `i32`, so
/// this always requires an explicit wildcard.
#[test]
fn rejects_non_exhaustive_match_over_int_without_wildcard() {
    let src = "fn describe(x: i32) -> i32:\n    match x:\n        <= 0 -> 1\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("an int match with no wildcard catch-all should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("non-exhaustive")), "{:?}", errs);
}

// ===== generic type-parameter consistency ===================================

/// A generic function whose type parameter `T` appears in more than one
/// parameter position must infer the *same* concrete type from every
/// argument -- previously `Checker::unify_ty` kept only the first binding
/// found for a parameter and silently ignored any later, conflicting one, so
/// `pick(5, "hello")` against `fn pick<T>(a: T, b: T) -> T` type-checked
/// cleanly.
#[test]
fn rejects_generic_fn_call_with_inconsistent_type_parameter() {
    let src = "fn pick<T>(a: T, b: T) -> T:\n    return a\nfn main():\n    let x = pick(5, \"hello\")\n    println(f\"{x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("a generic call binding the same type parameter to two different types should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("inconsistently") && d.message.contains("pick")), "{:?}", errs);
}

/// Same bug, reached through generic struct construction (`Checker::unify_ty`
/// is shared by `infer_generic_call` and `resolve_generic_ctor_args`).
#[test]
fn rejects_generic_struct_ctor_with_inconsistent_type_parameter() {
    let src = "struct Pair<T>:\n    a: T\n    b: T\nfn main():\n    let p = Pair(5, \"hello\")\n    println(f\"{p.a}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("a generic struct literal binding the same type parameter to two different types should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("inconsistently") && d.message.contains("Pair")), "{:?}", errs);
}

/// Consistent use of a repeated type parameter must still work -- guards
/// against the check above being so aggressive it rejects sound, ordinary
/// generic calls.
#[test]
fn runtime_generic_fn_call_with_consistent_type_parameter_end_to_end() {
    let src = "fn pick<T>(a: T, b: T) -> T:\n    return a\nfn main():\n    let x = pick(5, 6)\n    println(f\"{x}\")\n";
    let output = compile_and_run("generic_consistent_type_param", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "5", "{}", stdout);
}

// ===== impl Trait completeness ===============================================

/// `impl Trait for Type` that never defines one of the trait's required
/// methods must be rejected -- previously nothing checked this, and (since
/// traits are purely nominal, with no dynamic dispatch anywhere in codegen)
/// there was no other point in the pipeline that could ever catch it either.
#[test]
fn rejects_impl_missing_trait_method() {
    let src = "trait Greeter:\n    fn greet(self) -> i32\nstruct Foo:\n    x: i32\nimpl Greeter for Foo:\n    fn other(self) -> i32:\n        return self.x\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("an impl missing a required trait method should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("missing method") && d.message.contains("greet")), "{:?}", errs);
}

/// A method present under the trait's exact name but with the wrong arity
/// must also be rejected -- a name match alone doesn't mean the impl
/// actually provides what the trait requires.
#[test]
fn rejects_impl_method_wrong_arity_for_trait() {
    let src = "trait Greeter:\n    fn greet(self, n: i32) -> i32\nstruct Foo:\n    x: i32\nimpl Greeter for Foo:\n    fn greet(self) -> i32:\n        return self.x\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("an impl method with the wrong arity for its trait method should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("parameter(s)") && d.message.contains("greet")), "{:?}", errs);
}

/// An impl that faithfully provides every trait method must still work end
/// to end -- guards against the two checks above being so aggressive they
/// reject sound, ordinary trait impls (mirrors `examples/player.star`'s
/// `Damageable`/`Player` shape).
#[test]
fn runtime_impl_satisfying_trait_exactly_end_to_end() {
    let src = "trait Greeter:\n    fn greet(self) -> i32\nstruct Foo:\n    x: i32\nimpl Greeter for Foo:\n    fn greet(self) -> i32:\n        return self.x\nfn main():\n    let f = Foo(x = 5)\n    println(f\"{f.greet()}\")\n";
    let output = compile_and_run("impl_satisfying_trait_exactly", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "5", "{}", stdout);
}

// ===== comparison-operator type checking =====================================

/// Comparing two `GenRef<T>` values with `==` must be rejected by the
/// checker with a real, located diagnostic -- previously `Checker::infer_binop_ty`
/// returned `bool` unconditionally for any comparison whose operand types
/// weren't a vector/matrix, so this type-checked cleanly and only failed
/// once `Codegen::emit_binop` actually saw the (unsupported) `GenRef`
/// operands, with no span at all (`Span::dummy()`).
#[test]
fn rejects_genref_equality_comparison() {
    let src = "struct Enemy:\n    hp: i32\narena Enemies: Enemy\nfn main():\n    spawn Enemies(10)\n    spawn Enemies(20)\n    let a: GenRef<Enemy> = GenRef<Enemy>(0)\n    let b: GenRef<Enemy> = GenRef<Enemy>(1)\n    if a == b:\n        println(\"same\")\n    else:\n        println(\"different\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("comparing two `GenRef<T>` values with `==` should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("not supported") && d.message.contains("GenRef")), "{:?}", errs);
}

/// Same bug, `str` operands -- also silently `bool`-typed before this fix,
/// then failed unlocated at codegen (there's no `strcmp`-backed `==` lowering
/// for `str` in `Codegen::emit_binop` at all).
#[test]
fn rejects_str_equality_comparison() {
    let src = "fn main():\n    let a = \"x\"\n    let b = \"y\"\n    if a == b:\n        println(\"eq\")\n    else:\n        println(\"ne\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("comparing two `str` values with `==` should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("not supported") && d.message.contains("Str")), "{:?}", errs);
}

/// Comparing two entirely unrelated types (`i32` and `str`) with `==` must
/// also be rejected, not just same-typed-but-unsupported pairs.
#[test]
fn rejects_equality_comparison_between_unrelated_types() {
    let src = "fn main():\n    if 1 == \"x\":\n        println(\"eq\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("comparing an `i32` and a `str` with `==` should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("not supported")), "{:?}", errs);
}

/// Ordinary scalar comparisons -- including a mixed `i32`/`float` pair,
/// which promotes exactly like the arithmetic operators do -- must still
/// work; guards against the checks above being so aggressive they reject
/// sound, ordinary comparisons.
#[test]
fn runtime_mixed_scalar_comparison_still_works_end_to_end() {
    let src = "fn main():\n    let a = 1\n    let b = 2.5\n    if a < b:\n        println(\"less\")\n    else:\n        println(\"not less\")\n";
    let output = compile_and_run("mixed_scalar_comparison", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "less", "{}", stdout);
}

// ===== f-string lexing =======================================================

/// An f-string interpolation hole containing a nested `str` literal that
/// itself contains a `}` byte must not confuse the hole's brace-depth
/// scanner -- previously `Lexer::scan_fstring`'s `{`/`}` counting had no
/// awareness of quotes at all, so the `}` inside the nested string literal
/// was mistaken for the hole's own closing brace.
#[test]
fn runtime_fstring_hole_containing_string_literal_with_brace_end_to_end() {
    let src = "fn main():\n    let s = f\"result: {concat(\"a}b\", \"c\")}\"\n    println(s)\n";
    let output = compile_and_run("fstring_hole_nested_brace_string", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "result: a}bc", "{}", stdout);
}

// ===== duplicate top-level declarations ======================================

/// Two top-level functions declared with the same name in one file must be
/// rejected -- previously the checker's registration pass silently let the
/// second `HashMap::insert` overwrite the first with no diagnostic at all,
/// and the collision only ever surfaced once both reached the LLVM parser as
/// clang's opaque "invalid redefinition of function".
#[test]
fn rejects_duplicate_top_level_function_declaration() {
    let src = "fn helper() -> i32:\n    return 1\nfn helper() -> i32:\n    return 2\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("two top-level functions with the same name should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("declared more than once")), "{:?}", errs);
}

/// Same bug, two top-level structs -- these share the LLVM named-type
/// namespace (`%Name`), not the function-symbol one.
#[test]
fn rejects_duplicate_top_level_struct_declaration() {
    let src = "struct Point:\n    x: i32\nstruct Point:\n    y: i32\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("two top-level structs with the same name should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("declared more than once")), "{:?}", errs);
}

/// The scenario `todo.md` specifically called out: two *different* imported
/// files, both declaring a same-named top-level item, imported under the
/// *same* alias -- `crate::modules::rename_module` mangles both files'
/// `helper` to the identical `m__helper`, which the checker's new duplicate
/// check now catches with a real diagnostic instead of it silently reaching
/// codegen as a colliding `define @m__helper` pair (a raw clang
/// "invalid redefinition" error).
#[test]
fn rejects_duplicate_top_level_name_from_two_imports_sharing_one_alias() {
    let dir = test_scratch_dir("rejects_duplicate_top_level_name_from_two_imports_sharing_one_alias");
    write_test_file(&dir, "a.star", "fn helper() -> i32:\n    return 1\n");
    write_test_file(&dir, "b.star", "fn helper() -> i32:\n    return 2\n");
    let main_path = write_test_file(
        &dir,
        "main.star",
        "import \"a.star\" as m\nimport \"b.star\" as m\nfn main():\n    println(f\"{m::helper()}\")\n",
    );
    let module = Driver::parse(&std::fs::read_to_string(&main_path).unwrap()).expect("should parse");
    let resolved = star::modules::resolve(module, &main_path).expect("import resolution itself should succeed");
    let Err(errs) = Driver::check(&resolved) else {
        panic!("two same-named top-level items imported under the same alias should be rejected by the checker")
    };
    assert!(errs.iter().any(|d| d.message.contains("declared more than once")), "{:?}", errs);
}

/// `Parser::lower_fstring` used to `?`-short-circuit out of `sub.parse_expr()`
/// on a syntax error inside an interpolation *before* merging `sub.errors`
/// into the outer parser's error list -- so a malformed interpolated
/// expression didn't fail parsing at all, it silently dropped the whole
/// enclosing statement from the AST with zero diagnostics (`Driver::parse`
/// returned `Ok` with the `let` statement simply missing from `main`'s body).
/// Found while investigating an unrelated deep-nesting stack-overflow fix
/// that happened to route through this same early-return path.
#[test]
fn rejects_malformed_expr_inside_fstring_interpolation() {
    let src = "fn main():\n    let x = f\"{1+}\"\n";
    let result = Driver::parse(src);
    assert!(result.is_err(), "a syntax error inside `f\"{{...}}\"` must be a parse error, not a silently dropped statement");
}
