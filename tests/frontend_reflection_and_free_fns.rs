//! M8 reflection metadata and free functions
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

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

/// A decorated field typed as a monomorphized *user-defined* generic struct
/// (`Box<i32>`) must show that real generic spelling in its reflection
/// metadata, not the internal flat-mangled symbol codegen actually uses
/// (`Box__i32`) -- `Codegen::reflect_type_name`'s `Ty::Named` arm previously
/// just cloned the mangled name verbatim (there is no dedicated `Ty`
/// variant for a user-defined generic the way there is for `List<T>`/
/// `Map<K,V>`/..., so it fell to the same catch-all as an ordinary,
/// non-generic struct). Confirmed via a real `star emit llvm` on exactly
/// this shape: the emitted `@__star_reflect_Holder` string read
/// `boxed:0:Box__i32:export`, an internal mangling artifact indistinguishable
/// from a plainly-named struct actually called `Box__i32`, not a name any
/// external tool or human reading the metadata could make sense of as "a
/// `Box` of `i32`". Fixed by threading `Checker::mono_struct_of`/
/// `mono_enum_of` through `TypedModule::generic_instantiations` (they don't
/// otherwise survive past type-checking -- `Codegen` never sees the
/// `Checker` that produced its input) so `reflect_type_name` can render
/// `Base<Arg, ...>` for any mangled name it recognizes as a generic
/// instantiation (`src/types/hir.rs`, `src/types/mod.rs`,
/// `src/codegen/reflect.rs`).
#[test]
fn codegen_reflect_metadata_shows_real_generic_name_for_user_defined_generic_field() {
    let src = "struct Box<T>:\n    value: T\nstruct Holder:\n    @export boxed: Box<i32> = Box(1)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("boxed:0:Box<i32>:export"), "expected the real generic spelling `Box<i32>`, not the mangled `Box__i32`: {}", ir);
    assert!(!ir.contains("Box__i32:export"), "the mangled name must not leak into reflection metadata: {}", ir);
}

/// Same bug, the compiler-*builtin* `Option<T>`/`Result<T,E>` generics
/// (`docs/design.md`'s "Type System" §9 -- synthesized as ordinary generic
/// enum templates, so they hit the exact same `Ty::Enum` catch-all bug as a
/// user-defined generic enum would) -- and a *nested* generic
/// (`Box<Option<i32>>`), confirming the fix recurses through
/// `reflect_type_name` for each type argument rather than only handling one
/// level of generic nesting.
#[test]
fn codegen_reflect_metadata_shows_real_generic_name_for_builtin_and_nested_generics() {
    let src = "struct Box<T>:\n    value: T\nstruct Holder:\n    @export opt: Option<i32> = Option<i32>::None\n    @export nested: Box<Option<i32>> = Box(Option<i32>::None)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("opt:0:Option<i32>:export"), "expected `Option<i32>`, not the mangled `Option__i32`: {}", ir);
    assert!(ir.contains("nested:") && ir.contains(":Box<Option<i32>>:export"), "a nested generic field must render every level, not just the outermost: {}", ir);
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
