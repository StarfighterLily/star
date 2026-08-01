//! `draw_pixels`/`texture_create`/`texture_update`/`texture_draw`/
//! `texture_destroy` (`crate::codegen::sdl`, added for the `projects/nova`
//! render-loop performance investigation -- see `emit_draw_pixels`'s own
//! doc comment) had no dedicated test file of their own (`todo.md` P2 #8):
//! every other SDL builtin family in this compiler gets arg-type checks, a
//! `par`/`swarm` ban-list check, and a real `SDL_VIDEODRIVER=dummy`
//! round-trip, but these five builtins only ever rode along on the *other*
//! SDL test files not regressing -- coverage-by-absence, not coverage.
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Arg-type / arity checks =============================================

/// `draw_pixels(window, pixels: Bytes, width, height, dst_x, dst_y, dst_w,
/// dst_h)` expects `ptr, Bytes, int, int, int, int, int, int`.
#[test]
fn checks_draw_pixels_full_call_type_checks() {
    let src = "fn t():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               let mut pixels = Bytes()\n    \
               pixels.push(1 as u8)\n    \
               draw_pixels(w, pixels, 1, 1, 0, 0, 1, 1)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("draw_pixels(ptr, Bytes, int, int, int, int, int, int) should type-check");
}

#[test]
fn checker_rejects_draw_pixels_wrong_arg_count() {
    let src = "fn t():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               let mut pixels = Bytes()\n    \
               draw_pixels(w, pixels, 1, 1, 0, 0, 1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("draw_pixels with 7 arguments should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`draw_pixels` expects 8 argument(s)")), "{:?}", diags);
}

#[test]
fn checker_rejects_draw_pixels_wrong_window_type() {
    let src = "fn t():\n    \
               let mut pixels = Bytes()\n    \
               draw_pixels(42, pixels, 1, 1, 0, 0, 1, 1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("draw_pixels(int, ..) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`draw_pixels` argument 1 expected `ptr`")), "{:?}", diags);
}

/// The easy mistake, since `draw_pixel` (no `s`) right next to it takes a
/// plain `Color32` -- passing a bare `str` where `Bytes` is expected should
/// be rejected rather than silently misreading `list_fields`' expected
/// `{ u8*, i64, i64 }` payload off the wrong shape (mirrors `frontend_file_
/// io.rs`'s `checker_rejects_file_write_bytes_wrong_arg_type`).
#[test]
fn checker_rejects_draw_pixels_wrong_pixels_type() {
    let src = "fn t():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               draw_pixels(w, \"not bytes\", 1, 1, 0, 0, 1, 1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("draw_pixels(ptr, str, ..) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`draw_pixels` argument 2 expected `Bytes`")), "{:?}", diags);
}

/// One of the six trailing `int` dimension/position arguments (here `dst_h`,
/// argument 8) given the wrong type is still caught -- not just the first
/// one in the loop.
#[test]
fn checker_rejects_draw_pixels_wrong_trailing_dim_type() {
    let src = "fn t():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               let mut pixels = Bytes()\n    \
               draw_pixels(w, pixels, 1, 1, 0, 0, 1, \"1\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("draw_pixels(.., str) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`draw_pixels` argument 8 expected `int`")), "{:?}", diags);
}

/// `texture_create(window, width, height) -> ptr`, same opaque-handle
/// convention `window_create`/`font_load` established.
#[test]
fn checks_texture_create_returns_ptr() {
    let src = "fn t():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               let tex: ptr = texture_create(w, 1, 1)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("texture_create(..) should type-check as ptr");
}

#[test]
fn checker_rejects_texture_create_wrong_arg_count() {
    let src = "fn t():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               texture_create(w, 1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("texture_create with 2 arguments should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`texture_create` expects 3 argument(s)")), "{:?}", diags);
}

#[test]
fn checker_rejects_texture_create_wrong_dim_type() {
    let src = "fn t():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               texture_create(w, \"1\", 1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("texture_create(ptr, str, ..) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`texture_create` argument 2 expected `int`")), "{:?}", diags);
}

/// `texture_update(tex, pixels: Bytes, width, height)` expects `ptr, Bytes,
/// int, int`.
#[test]
fn checks_texture_update_type_checks() {
    let src = "fn t():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               let tex = texture_create(w, 1, 1)\n    \
               let mut pixels = Bytes()\n    \
               texture_update(tex, pixels, 1, 1)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("texture_update(ptr, Bytes, int, int) should type-check");
}

#[test]
fn checker_rejects_texture_update_wrong_arg_count() {
    let src = "fn t():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               let tex = texture_create(w, 1, 1)\n    \
               let mut pixels = Bytes()\n    \
               texture_update(tex, pixels, 1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("texture_update with 3 arguments should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`texture_update` expects 4 argument(s)")), "{:?}", diags);
}

#[test]
fn checker_rejects_texture_update_wrong_pixels_type() {
    let src = "fn t():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               let tex = texture_create(w, 1, 1)\n    \
               texture_update(tex, \"not bytes\", 1, 1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("texture_update(ptr, str, ..) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`texture_update` argument 2 expected `Bytes`")), "{:?}", diags);
}

/// `texture_draw(window, tex, dst_x, dst_y, dst_w, dst_h)` expects `ptr,
/// ptr, int, int, int, int` -- two independent `ptr` slots (window, then
/// texture), unlike every other builtin here with only one.
#[test]
fn checks_texture_draw_type_checks() {
    let src = "fn t():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               let tex = texture_create(w, 1, 1)\n    \
               texture_draw(w, tex, 0, 0, 1, 1)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("texture_draw(ptr, ptr, int, int, int, int) should type-check");
}

#[test]
fn checker_rejects_texture_draw_wrong_arg_count() {
    let src = "fn t():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               let tex = texture_create(w, 1, 1)\n    \
               texture_draw(w, tex, 0, 0, 1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("texture_draw with 5 arguments should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`texture_draw` expects 6 argument(s)")), "{:?}", diags);
}

/// The *second* `ptr` slot (the texture, not the window) given a non-`ptr`
/// type is caught too, not just the first -- exercises argument 2's own
/// independent check.
#[test]
fn checker_rejects_texture_draw_wrong_texture_type() {
    let src = "fn t():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               texture_draw(w, 42, 0, 0, 1, 1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("texture_draw(ptr, int, ..) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`texture_draw` argument 2 expected `ptr`")), "{:?}", diags);
}

/// `texture_destroy(tex: ptr)`, same single-argument shape as
/// `window_destroy`/`font_free`.
#[test]
fn checks_texture_destroy_type_checks() {
    let src = "fn t():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               let tex = texture_create(w, 1, 1)\n    \
               texture_destroy(tex)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("texture_destroy(ptr) should type-check");
}

#[test]
fn checker_rejects_texture_destroy_wrong_arg_type() {
    let src = "fn t():\n    texture_destroy(42)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("texture_destroy(int) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`texture_destroy` expects a `ptr` argument")), "{:?}", diags);
}

// ===== par/swarm ban list ===================================================

/// All five bulk-pixel-blit builtins re-derive or mutate the shared
/// `SDL_Renderer*` (`draw_pixels`/`texture_draw` via `SDL_RenderCopy`,
/// `texture_create` via `SDL_CreateTexture` against the shared renderer,
/// `texture_update`/`texture_destroy` mutate/free a texture that could be
/// concurrently in use by another worker's `texture_draw`), so
/// `is_banned_sdl_builtin_in_par` bans every one of them -- mirrors
/// `frontend_sdl_par_swarm_hazards_and_fstring_vectors.rs`'s existing
/// `rejects_sdl_render_calls_inside_par_body`/`rejects_sdl_window_and_
/// input_calls_inside_par_body` pair for the rest of the SDL surface.
#[test]
fn rejects_bulk_pixel_blit_builtins_inside_par_body() {
    let src = concat!(
        "struct Entity:\n    mut idx: i32\n\n",
        "arena Entities: Entity\n\n",
        "fn main():\n",
        "    let w = window_create(\"race\", 16, 16)\n",
        "    let tex = texture_create(w, 1, 1)\n",
        "    par e in Entities:\n",
        "        let mut pixels = Bytes()\n",
        "        pixels.push(e.idx as u8)\n",
        "        draw_pixels(w, pixels, 1, 1, 0, 0, 1, 1)\n",
        "        texture_update(tex, pixels, 1, 1)\n",
        "        texture_draw(w, tex, 0, 0, 1, 1)\n",
        "        texture_destroy(tex)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else {
        panic!("draw_pixels/texture_update/texture_draw/texture_destroy on a captured window/texture handle inside a par/swarm body should be rejected")
    };
    for name in ["draw_pixels", "texture_update", "texture_draw", "texture_destroy"] {
        assert!(
            diags.iter().any(|d| d.message.contains(&format!("cannot call `{}`", name)) && d.message.contains("shared window/renderer")),
            "expected a rejection for `{}`, got: {:?}",
            name,
            diags
        );
    }
}

/// `texture_create` alone (no `draw_pixels`/other `texture_*` call
/// alongside it) is also rejected on its own inside a `par` body -- it
/// calls `SDL_CreateTexture` against the shared renderer just like
/// `window_create` touches shared subsystem state, so it needs its own
/// coverage independent of the combined test above.
#[test]
fn rejects_texture_create_inside_par_body() {
    let src = concat!(
        "struct Entity:\n    mut idx: i32\n\n",
        "arena Entities: Entity\n\n",
        "fn main():\n",
        "    let w = window_create(\"race\", 16, 16)\n",
        "    par e in Entities:\n",
        "        let tex = texture_create(w, 1, 1)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("texture_create on a captured window handle inside a par/swarm body should be rejected") };
    assert!(
        diags.iter().any(|d| d.message.contains("cannot call `texture_create`") && d.message.contains("shared window/renderer")),
        "{:?}",
        diags
    );
}

// ===== codegen: null-handle aborts (structural, no clang/run needed) =======

/// `draw_pixels` on a null/closed window handle aborts before ever calling
/// `SDL_CreateTexture` -- same shape as `codegen_tcp_close_aborts_on_null_
/// handle`.
#[test]
fn codegen_draw_pixels_aborts_on_null_window_handle() {
    let src = "fn t():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               window_destroy(w)\n    \
               let mut pixels = Bytes()\n    \
               draw_pixels(w, pixels, 1, 1, 0, 0, 1, 1)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    // The escaped error-message string itself is a global constant defined
    // outside the function body (see `abort_if_null_window`), so it's
    // checked against the whole module's `ir`, not `extract_fn_body`'s
    // slice -- mirrors `frontend_networking.rs`'s own `codegen_tcp_close_
    // aborts_on_null_handle`, which only checks the fn body for the
    // control-flow shape (icmp/exit/unreachable), not the message text.
    assert!(ir.contains("null/closed window handle"), "{}", ir);
    let fn_ir = extract_fn_body(&ir, "define void @t(");
    assert!(fn_ir.contains("icmp eq i8* "), "should compare the handle against null: {}", fn_ir);
    assert!(fn_ir.contains("call void @exit(i32 1)"), "should abort on a null window handle: {}", fn_ir);
    assert!(fn_ir.contains("unreachable"), "{}", fn_ir);
}

/// `texture_update`/`texture_draw`/`texture_destroy` on a null/destroyed
/// texture handle abort before touching SDL -- `abort_if_null_texture`'s
/// own dedicated error wording ("null/destroyed texture handle"), distinct
/// from the window-handle wording above.
#[test]
fn codegen_texture_update_aborts_on_null_texture_handle() {
    let src = "fn t():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               let tex = texture_create(w, 1, 1)\n    \
               texture_destroy(tex)\n    \
               let mut pixels = Bytes()\n    \
               texture_update(tex, pixels, 1, 1)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    // See the sibling window-handle test above for why the message text is
    // checked against the whole-module `ir`, not the function-body slice.
    assert!(ir.contains("null/destroyed texture handle"), "{}", ir);
    let fn_ir = extract_fn_body(&ir, "define void @t(");
    assert!(fn_ir.contains("icmp eq i8* "), "should compare the handle against null: {}", fn_ir);
    assert!(fn_ir.contains("call void @exit(i32 1)"), "should abort on a null texture handle: {}", fn_ir);
    assert!(fn_ir.contains("unreachable"), "{}", fn_ir);
}

/// `draw_pixels` on a `pixels` buffer smaller than `width * height * 4`
/// bytes aborts before ever calling `SDL_UpdateTexture` -- found via manual
/// bug-hunt repro: before `abort_if_pixel_buffer_too_small` existed, a real
/// too-small buffer against a large `width`/`height` request segfaulted
/// (`SDL_UpdateTexture`'s internal `memcpy` reading past the buffer's own
/// heap allocation) instead of erroring.
#[test]
fn codegen_draw_pixels_aborts_on_undersized_pixel_buffer() {
    let src = "fn t():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               let mut pixels = Bytes()\n    \
               pixels.push(1 as u8)\n    \
               draw_pixels(w, pixels, 512, 512, 0, 0, 16, 16)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("smaller than width * height * 4 bytes"), "{}", ir);
    let fn_ir = extract_fn_body(&ir, "define void @t(");
    assert!(fn_ir.contains("icmp ult i64 "), "should compare the buffer length against the needed size: {}", fn_ir);
    assert!(fn_ir.contains("call void @exit(i32 1)"), "should abort on an undersized buffer: {}", fn_ir);
    assert!(fn_ir.contains("unreachable"), "{}", fn_ir);
}

/// `texture_update` gets the identical undersized-buffer check as
/// `draw_pixels` (shared `abort_if_pixel_buffer_too_small` helper).
#[test]
fn codegen_texture_update_aborts_on_undersized_pixel_buffer() {
    let src = "fn t():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               let tex = texture_create(w, 512, 512)\n    \
               let mut pixels = Bytes()\n    \
               pixels.push(1 as u8)\n    \
               texture_update(tex, pixels, 512, 512)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("smaller than width * height * 4 bytes"), "{}", ir);
    let fn_ir = extract_fn_body(&ir, "define void @t(");
    assert!(fn_ir.contains("icmp ult i64 "), "should compare the buffer length against the needed size: {}", fn_ir);
    assert!(fn_ir.contains("call void @exit(i32 1)"), "should abort on an undersized buffer: {}", fn_ir);
    assert!(fn_ir.contains("unreachable"), "{}", fn_ir);
}

// ===== runtime: real SDL_VIDEODRIVER=dummy round trips =====================
//
// All of these draw against a real (headless) `SDL_Renderer` and read the
// result back with `get_pixel` (`SDL_RenderReadPixels`, `crate::codegen::
// font`) -- exactly the "draw, then read back exactly the colors drawn"
// proof `docs/cross_platform_scope.md`'s "Already seamed" section already
// establishes for `draw_rect`. Every source pixel buffer here is built with
// `Bytes()`/`push` the same way `frontend_file_io.rs`'s `Bytes`-round-trip
// tests are, in `SDL_PIXELFORMAT_RGBA32`'s R,G,B,A byte order (`crate::
// codegen::sdl`'s own `SDL_PIXELFORMAT_RGBA32` doc comment).

/// The one-shot form (`draw_pixels`): a single 1x1 source pixel blitted 1:1
/// (no scaling) reads back through `get_pixel` as exactly the color
/// written, round-tripping all four channels including alpha.
#[test]
fn runtime_draw_pixels_one_shot_exact_pixel_round_trip_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               clear_screen(w, Color32(9, 9, 9, 255))\n    \
               let mut pixels = Bytes()\n    \
               pixels.push(200 as u8)\n    \
               pixels.push(100 as u8)\n    \
               pixels.push(50 as u8)\n    \
               pixels.push(255 as u8)\n    \
               draw_pixels(w, pixels, 1, 1, 0, 0, 1, 1)\n    \
               let p = get_pixel(w, 0, 0)\n    \
               println(f\"{color32_r(p)},{color32_g(p)},{color32_b(p)},{color32_a(p)}\")\n    \
               window_destroy(w)\n";
    let output = compile_and_run_sdl("draw_pixels_one_shot_exact", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "200,100,50,255");
}

/// A 2x1 source buffer (red pixel, then green pixel) blitted 1:1 reads back
/// with the right color at the right *column* -- catches a row-major/
/// column-order mixup in `pixels`' packing that a single-pixel or uniform-
/// fill test could never distinguish from a correct implementation.
#[test]
fn runtime_draw_pixels_row_major_layout_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               clear_screen(w, Color32(9, 9, 9, 255))\n    \
               let mut pixels = Bytes()\n    \
               pixels.push(255 as u8)\n    \
               pixels.push(0 as u8)\n    \
               pixels.push(0 as u8)\n    \
               pixels.push(255 as u8)\n    \
               pixels.push(0 as u8)\n    \
               pixels.push(255 as u8)\n    \
               pixels.push(0 as u8)\n    \
               pixels.push(255 as u8)\n    \
               draw_pixels(w, pixels, 2, 1, 0, 0, 2, 1)\n    \
               let left = get_pixel(w, 0, 0)\n    \
               let right = get_pixel(w, 1, 0)\n    \
               println(f\"{color32_r(left)},{color32_g(left)},{color32_b(left)}\")\n    \
               println(f\"{color32_r(right)},{color32_g(right)},{color32_b(right)}\")\n    \
               window_destroy(w)\n";
    let output = compile_and_run_sdl("draw_pixels_row_major", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["255,0,0", "0,255,0"], "left pixel should be red, right pixel green: {}", stdout);
}

/// The destination rect's `(dst_x, dst_y)` is honored, not silently treated
/// as always `(0, 0)`: a blit to `(5, 5, 2, 2)` must land there and nowhere
/// else, leaving the cleared background color untouched at the origin.
#[test]
fn runtime_draw_pixels_destination_offset_isolated_from_background_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               clear_screen(w, Color32(9, 9, 9, 255))\n    \
               let mut pixels = Bytes()\n    \
               pixels.push(1 as u8)\n    \
               pixels.push(2 as u8)\n    \
               pixels.push(3 as u8)\n    \
               pixels.push(255 as u8)\n    \
               draw_pixels(w, pixels, 1, 1, 5, 5, 2, 2)\n    \
               let inside = get_pixel(w, 6, 6)\n    \
               let outside = get_pixel(w, 0, 0)\n    \
               println(f\"{color32_r(inside)},{color32_g(inside)},{color32_b(inside)}\")\n    \
               println(f\"{color32_r(outside)}\")\n    \
               window_destroy(w)\n";
    let output = compile_and_run_sdl("draw_pixels_dest_offset", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["1,2,3", "9"], "{}", stdout);
}

/// The cached-handle form (`texture_create`/`texture_update`/`texture_draw`)
/// round-trips like `draw_pixels`, and -- the thing the one-shot form can't
/// test at all -- reusing the *same* texture handle across two successive
/// `texture_update`/`texture_draw` calls actually re-uploads new pixel data
/// each time rather than silently redrawing stale contents from the first
/// `texture_update` (the classic cached-handle bug: if reuse were broken,
/// the second read would still show the first color).
#[test]
fn runtime_texture_create_update_draw_reuse_round_trip_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               clear_screen(w, Color32(9, 9, 9, 255))\n    \
               let tex = texture_create(w, 1, 1)\n    \
               println(f\"{is_null(tex)}\")\n    \
               let mut a = Bytes()\n    \
               a.push(10 as u8)\n    \
               a.push(20 as u8)\n    \
               a.push(30 as u8)\n    \
               a.push(255 as u8)\n    \
               texture_update(tex, a, 1, 1)\n    \
               texture_draw(w, tex, 0, 0, 1, 1)\n    \
               let p1 = get_pixel(w, 0, 0)\n    \
               println(f\"{color32_r(p1)},{color32_g(p1)},{color32_b(p1)}\")\n    \
               let mut b = Bytes()\n    \
               b.push(90 as u8)\n    \
               b.push(80 as u8)\n    \
               b.push(70 as u8)\n    \
               b.push(255 as u8)\n    \
               texture_update(tex, b, 1, 1)\n    \
               texture_draw(w, tex, 0, 0, 1, 1)\n    \
               let p2 = get_pixel(w, 0, 0)\n    \
               println(f\"{color32_r(p2)},{color32_g(p2)},{color32_b(p2)}\")\n    \
               texture_destroy(tex)\n    \
               window_destroy(w)\n";
    let output = compile_and_run_sdl("texture_create_update_draw_reuse", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "10,20,30", "90,80,70"], "second draw should show the re-uploaded color, not stale data: {}", stdout);
}

/// `texture_draw`'s own `(dst_x, dst_y)` destination rect, the cached-handle
/// counterpart of `runtime_draw_pixels_destination_offset_isolated_from_
/// background_end_to_end` above.
#[test]
fn runtime_texture_draw_destination_offset_isolated_from_background_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               clear_screen(w, Color32(9, 9, 9, 255))\n    \
               let tex = texture_create(w, 1, 1)\n    \
               let mut px = Bytes()\n    \
               px.push(4 as u8)\n    \
               px.push(5 as u8)\n    \
               px.push(6 as u8)\n    \
               px.push(255 as u8)\n    \
               texture_update(tex, px, 1, 1)\n    \
               texture_draw(w, tex, 5, 5, 2, 2)\n    \
               let inside = get_pixel(w, 6, 6)\n    \
               let outside = get_pixel(w, 0, 0)\n    \
               println(f\"{color32_r(inside)},{color32_g(inside)},{color32_b(inside)}\")\n    \
               println(f\"{color32_r(outside)}\")\n    \
               texture_destroy(tex)\n    \
               window_destroy(w)\n";
    let output = compile_and_run_sdl("texture_draw_dest_offset", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["4,5,6", "9"], "{}", stdout);
}

/// `draw_pixels` on a null/closed window handle aborts loudly at runtime
/// instead of crashing/segfaulting -- mirrors `runtime_tcp_send_aborts_on_
/// null_handle_end_to_end`.
#[test]
fn runtime_draw_pixels_null_window_handle_aborts_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               window_destroy(w)\n    \
               println(\"before\")\n    \
               let mut pixels = Bytes()\n    \
               pixels.push(1 as u8)\n    \
               draw_pixels(w, pixels, 1, 1, 0, 0, 1, 1)\n    \
               println(\"should not reach here\")\n";
    let output = compile_and_run_sdl("draw_pixels_null_window", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "must abort before the null handle is ever used: {}", stdout);
    assert!(stdout.contains("null/closed window handle"), "{}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

/// `texture_create` on a null/closed window handle aborts the same way
/// `draw_pixels`/`clear_screen`/every other window-taking builtin does.
#[test]
fn runtime_texture_create_null_window_handle_aborts_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               window_destroy(w)\n    \
               println(\"before\")\n    \
               let tex = texture_create(w, 1, 1)\n    \
               println(\"should not reach here\")\n";
    let output = compile_and_run_sdl("texture_create_null_window", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "must abort before the null handle is ever used: {}", stdout);
    assert!(stdout.contains("null/closed window handle"), "{}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

/// `texture_destroy` nulls the caller's own variable out (mirrors
/// `window_destroy`/`tcp_close` -- see either's doc comment), so a second
/// `texture_update` against the same bare-variable handle hits the ordinary
/// null-handle abort path instead of a use-after-free reaching SDL.
#[test]
fn runtime_texture_update_after_destroy_aborts_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               let tex = texture_create(w, 1, 1)\n    \
               texture_destroy(tex)\n    \
               println(\"destroyed\")\n    \
               let mut pixels = Bytes()\n    \
               pixels.push(1 as u8)\n    \
               texture_update(tex, pixels, 1, 1)\n    \
               println(\"should not reach here\")\n";
    let output = compile_and_run_sdl("texture_update_after_destroy", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("destroyed"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "must abort before the null handle is ever used: {}", stdout);
    assert!(stdout.contains("null/destroyed texture handle"), "{}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

/// `draw_pixels` given a real but undersized `pixels` buffer (4 bytes, a
/// single RGBA pixel) against a `512x512` request aborts loudly instead of
/// segfaulting -- the exact shape of the bug-hunt repro that motivated
/// `abort_if_pixel_buffer_too_small`. Before the fix, this test's own
/// process crashed (`output.status.success()` false with no captured
/// message, a bare segfault) rather than exiting 1 with a diagnostic.
#[test]
fn runtime_draw_pixels_undersized_buffer_aborts_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               println(\"before\")\n    \
               let mut pixels = Bytes()\n    \
               pixels.push(200 as u8)\n    \
               pixels.push(100 as u8)\n    \
               pixels.push(50 as u8)\n    \
               pixels.push(255 as u8)\n    \
               draw_pixels(w, pixels, 512, 512, 0, 0, 16, 16)\n    \
               println(\"should not reach here\")\n";
    let output = compile_and_run_sdl("draw_pixels_undersized_buffer", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "must abort before the undersized buffer is ever read: {}", stdout);
    assert!(stdout.contains("smaller than width * height * 4 bytes"), "{}", stdout);
    assert_eq!(output.status.code(), Some(1), "should exit cleanly, not segfault: {:?}", output.status);
}

/// `texture_update`'s identical undersized-buffer check, runtime-verified.
#[test]
fn runtime_texture_update_undersized_buffer_aborts_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               let tex = texture_create(w, 512, 512)\n    \
               println(\"before\")\n    \
               let mut pixels = Bytes()\n    \
               pixels.push(1 as u8)\n    \
               texture_update(tex, pixels, 512, 512)\n    \
               println(\"should not reach here\")\n";
    let output = compile_and_run_sdl("texture_update_undersized_buffer", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "must abort before the undersized buffer is ever read: {}", stdout);
    assert!(stdout.contains("smaller than width * height * 4 bytes"), "{}", stdout);
    assert_eq!(output.status.code(), Some(1), "should exit cleanly, not segfault: {:?}", output.status);
}

/// `texture_destroy` called twice on the same bare-variable handle: the
/// first call nulls it out, so the second hits the null-handle abort
/// instead of double-freeing the `SDL_Texture*` -- mirrors `frontend_sdl_
/// round6_deeper_coverage.rs`'s `runtime_double_window_destroy_aborts_
/// cleanly_end_to_end`.
#[test]
fn runtime_double_texture_destroy_aborts_cleanly_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"t\", 16, 16)\n    \
               let tex = texture_create(w, 1, 1)\n    \
               texture_destroy(tex)\n    \
               println(\"first destroy ok\")\n    \
               texture_destroy(tex)\n    \
               println(\"should not reach\")\n";
    let output = compile_and_run_sdl("double_texture_destroy", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("first destroy ok"), "{}", stdout);
    assert!(!stdout.contains("should not reach"), "second destroy must abort, not double-free: {}", stdout);
    assert!(stdout.contains("null/destroyed texture handle"), "{}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}
