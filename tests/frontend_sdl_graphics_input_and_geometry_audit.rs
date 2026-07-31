//! SDL2 graphics/input builtins, plus bug-hunting round 5 (geometry/vector-math/quaternion/matrix/palette)
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== SDL2 graphics/input builtins (todo.md #4 "Graphics / audio / input ==
// ===== bindings"): `window_create`/`window_destroy`/`window_should_close`/
// ===== `clear_screen`/`draw_pixel`/`draw_rect`/`draw_line`/`present`/
// ===== `key_down`/`mouse_x`/`mouse_y`/`mouse_button_down`/`delay`/`ticks`
// ===== (`crate::codegen::sdl`) -- the "window creation + framebuffer/
// ===== pixel-blit... input polling" minimal viable slice, sequenced after
// ===== FFI per that item's own note, deferring audio. SDL2's headers/import
// ===== lib/runtime DLL are vendored under `sdl/` at the repo root; every
// ===== runtime test below links against them and runs the compiled binary
// ===== with `SDL_VIDEODRIVER=dummy` (SDL2's own headless video driver,
// ===== real code path minus an actual OS window -- confirmed capable of a
// ===== full init/create-window/create-renderer/draw/read-back cycle before
// ===== any of this was wired into the compiler) so `cargo test` never pops
// ===== a real window on screen. ===========================================

/// `window_create` type-checks to `ptr`, the same opaque-handle convention
/// `file_open`/`tcp_connect` established.
#[test]
fn checks_window_create_returns_ptr() {
    let src = "fn t():\n    let w: ptr = window_create(\"t\", 64, 48)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("window_create(..) should type-check as ptr");
}

#[test]
fn checker_rejects_window_create_wrong_arg_count() {
    let src = "fn t():\n    window_create(\"t\", 64)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("window_create with 2 arguments should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`window_create` expects 3 argument(s)")), "{:?}", diags);
}

#[test]
fn checker_rejects_window_create_wrong_arg_types() {
    let src = "fn t():\n    window_create(1, \"64\", 48)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("window_create(int, str, int) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("argument 1 expected `str`")), "{:?}", diags);
    assert!(diags.iter().any(|d| d.message.contains("argument 2 expected `int`")), "{:?}", diags);
}

/// `window_destroy`/`present`/`window_should_close` all take a bare `ptr`
/// and (for `window_should_close`) type-check to `bool`.
#[test]
fn checks_window_destroy_present_should_close_type_check() {
    let src = "fn t():\n    \
               let w = window_create(\"t\", 64, 48)\n    \
               let closing: bool = window_should_close(w)\n    \
               present(w)\n    \
               window_destroy(w)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("window_destroy/present/window_should_close should type-check");
}

#[test]
fn checker_rejects_window_destroy_wrong_arg_type() {
    let src = "fn t():\n    window_destroy(42)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("window_destroy(int) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`window_destroy` expects a `ptr` argument")), "{:?}", diags);
}

/// `clear_screen(window, color)` expects a `ptr` then a `Color32`.
#[test]
fn checks_clear_screen_type_checks() {
    let src = "fn t():\n    let w = window_create(\"t\", 64, 48)\n    clear_screen(w, Color32(255, 0, 0, 255))\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("clear_screen(ptr, Color32) should type-check");
}

#[test]
fn checker_rejects_clear_screen_wrong_arg_types() {
    let src = "fn t():\n    let w = window_create(\"t\", 64, 48)\n    clear_screen(w, 255)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("clear_screen(ptr, int) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("argument 2 expected `Color32`")), "{:?}", diags);
}

/// `draw_pixel(window, x, y, color)` expects `ptr, int, int, Color32`.
#[test]
fn checks_draw_pixel_type_checks() {
    let src = "fn t():\n    let w = window_create(\"t\", 64, 48)\n    draw_pixel(w, 1, 2, Color32(0, 255, 0, 255))\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("draw_pixel(ptr, int, int, Color32) should type-check");
}

#[test]
fn checker_rejects_draw_pixel_wrong_arg_count() {
    let src = "fn t():\n    let w = window_create(\"t\", 64, 48)\n    draw_pixel(w, 1, 2)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("draw_pixel with 3 arguments should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`draw_pixel` expects 4 argument(s)")), "{:?}", diags);
}

#[test]
fn checker_rejects_draw_pixel_wrong_coordinate_type() {
    let src = "fn t():\n    let w = window_create(\"t\", 64, 48)\n    draw_pixel(w, \"1\", 2, Color32(0, 255, 0, 255))\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("draw_pixel(ptr, str, ..) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("argument 2 expected `int`")), "{:?}", diags);
}

/// `draw_rect(window, x, y, w, h, color)` expects `ptr, int, int, int, int,
/// Color32`.
#[test]
fn checks_draw_rect_type_checks() {
    let src = "fn t():\n    let w = window_create(\"t\", 64, 48)\n    draw_rect(w, 0, 0, 5, 5, Color32(0, 0, 255, 255))\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("draw_rect(ptr, int, int, int, int, Color32) should type-check");
}

#[test]
fn checker_rejects_draw_rect_wrong_arg_count() {
    let src = "fn t():\n    let w = window_create(\"t\", 64, 48)\n    draw_rect(w, 0, 0, 5, 5)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("draw_rect with 5 arguments should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`draw_rect` expects 6 argument(s)")), "{:?}", diags);
}

#[test]
fn checker_rejects_draw_rect_wrong_color_type() {
    let src = "fn t():\n    let w = window_create(\"t\", 64, 48)\n    draw_rect(w, 0, 0, 5, 5, 42)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("draw_rect(.., int) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("argument 6 expected `Color32`")), "{:?}", diags);
}

/// `draw_line(window, x1, y1, x2, y2, color)` expects `ptr, int, int, int,
/// int, Color32`.
#[test]
fn checks_draw_line_type_checks() {
    let src = "fn t():\n    let w = window_create(\"t\", 64, 48)\n    draw_line(w, 0, 0, 10, 10, Color32(255, 255, 0, 255))\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("draw_line(ptr, int, int, int, int, Color32) should type-check");
}

#[test]
fn checker_rejects_draw_line_wrong_arg_count() {
    let src = "fn t():\n    let w = window_create(\"t\", 64, 48)\n    draw_line(w, 0, 0, 10, 10)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("draw_line with 5 arguments should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`draw_line` expects 6 argument(s)")), "{:?}", diags);
}

/// `key_down`/`mouse_button_down`/`delay` each expect a single `int`
/// argument; `mouse_x`/`mouse_y`/`ticks` take none and type-check to `int`.
#[test]
fn checks_key_down_mouse_delay_ticks_type_check() {
    let src = "fn t():\n    \
               let a: bool = key_down(41)\n    \
               let b: bool = mouse_button_down(1)\n    \
               delay(10)\n    \
               let x: int = mouse_x()\n    \
               let y: int = mouse_y()\n    \
               let t: int = ticks()\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("key_down/mouse_button_down/delay/mouse_x/mouse_y/ticks should type-check");
}

#[test]
fn checker_rejects_key_down_wrong_arg_type() {
    let src = "fn t():\n    key_down(\"escape\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("key_down(str) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`key_down` expects an `int` argument")), "{:?}", diags);
}

#[test]
fn checker_rejects_mouse_x_with_arguments() {
    let src = "fn t():\n    mouse_x(1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("mouse_x(1) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`mouse_x` expects 0 argument(s)")), "{:?}", diags);
}

/// `window_create` on a real (headless-`dummy`-driver) run returns a
/// non-null window handle, and `window_destroy` tears it down cleanly with
/// no crash/hang -- the basic lifecycle the rest of this surface builds on.
#[test]
fn runtime_window_create_then_destroy_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"star sdl test\", 64, 48)\n    \
               println(f\"{is_null(w)}\")\n    \
               window_destroy(w)\n    \
               println(\"destroyed\")\n";
    let output = compile_and_run_sdl("window_create_then_destroy", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "destroyed"], "window_create should succeed under SDL_VIDEODRIVER=dummy: {}", stdout);
}

/// A full frame -- `clear_screen`, `draw_pixel`, `draw_rect`, `draw_line`,
/// `present` -- runs end to end with no crash, exercising every drawing
/// builtin's `SDL_GetRenderer`-derived-renderer path and stack-built
/// `SDL_Rect` layout for real, not just via a codegen/IR-shape assertion.
#[test]
fn runtime_full_frame_draw_sequence_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"frame test\", 64, 48)\n    \
               clear_screen(w, Color32(0, 0, 0, 255))\n    \
               draw_pixel(w, 10, 10, Color32(255, 0, 0, 255))\n    \
               draw_rect(w, 0, 0, 5, 5, Color32(0, 255, 0, 255))\n    \
               draw_line(w, 0, 0, 20, 20, Color32(0, 0, 255, 255))\n    \
               present(w)\n    \
               window_destroy(w)\n    \
               println(\"frame ok\")\n";
    let output = compile_and_run_sdl("full_frame_draw_sequence", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "frame ok", "{}", stdout);
}

/// `window_should_close` returns `false` when no `SDL_QUIT` event has been
/// posted -- the common per-frame case for a window nobody has tried to
/// close yet. (The `true` branch, a real quit request, is exercised by
/// `crate::codegen::sdl::emit_window_should_close`'s own event-draining loop
/// logic; injecting a real `SDL_QUIT` event would need a second process or
/// OS-level window-manager interaction this test harness doesn't have.)
#[test]
fn runtime_window_should_close_false_with_no_quit_event_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"quit test\", 64, 48)\n    \
               println(f\"{window_should_close(w)}\")\n    \
               window_destroy(w)\n";
    let output = compile_and_run_sdl("window_should_close_false", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "false", "{}", stdout);
}

/// `key_down` on a scancode nobody is pressing (headless `dummy` driver, so
/// nothing is ever actually pressed) returns `false` -- and, separately, an
/// out-of-range scancode (negative, or past `SDL_NUM_SCANCODES`) also
/// returns `false` rather than indexing out of bounds/crashing.
#[test]
fn runtime_key_down_false_when_unpressed_and_out_of_range_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"key test\", 64, 48)\n    \
               println(f\"{window_should_close(w)}\")\n    \
               println(f\"{key_down(41)}\")\n    \
               println(f\"{key_down(-1)}\")\n    \
               println(f\"{key_down(99999)}\")\n    \
               window_destroy(w)\n";
    let output = compile_and_run_sdl("key_down_unpressed_and_oob", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "false", "false", "false"], "{}", stdout);
}

/// `mouse_x`/`mouse_y`/`mouse_button_down` all run and return sane values
/// under the headless `dummy` driver (cursor position defaults to the
/// origin, no button pressed) -- confirms the real `SDL_GetMouseState` call
/// path works end to end, not just that it type-checks.
#[test]
fn runtime_mouse_state_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"mouse test\", 64, 48)\n    \
               println(f\"{window_should_close(w)}\")\n    \
               let x = mouse_x()\n    \
               let y = mouse_y()\n    \
               println(f\"{x >= 0}\")\n    \
               println(f\"{y >= 0}\")\n    \
               println(f\"{mouse_button_down(1)}\")\n    \
               println(f\"{mouse_button_down(2)}\")\n    \
               println(f\"{mouse_button_down(3)}\")\n    \
               window_destroy(w)\n";
    let output = compile_and_run_sdl("mouse_state", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "true", "true", "false", "false", "false"], "no button pressed under the headless dummy driver: {}", stdout);
}

/// `delay`/`ticks` perform a real, measurable sleep -- `ticks()` sampled
/// before and after `delay(50)` differs by at least 40ms (a small margin
/// below the requested 50 for scheduler slack, matching how a real game loop
/// would use these two together), confirming `SDL_Delay`/`SDL_GetTicks`
/// actually reach the OS rather than being no-op stubs.
#[test]
fn runtime_delay_and_ticks_measure_real_time_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"timing test\", 64, 48)\n    \
               let before = ticks()\n    \
               delay(50)\n    \
               let after = ticks()\n    \
               println(f\"{after - before >= 40}\")\n    \
               window_destroy(w)\n";
    let output = compile_and_run_sdl("delay_and_ticks", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "true", "{}", stdout);
}

/// Calling any of `present`/`draw_pixel`/`window_destroy`/`window_should_close`
/// with a null `ptr` (e.g. `window_create` failing, or a caller reading a
/// handle without checking `is_null` first) aborts loudly with a diagnostic
/// and a nonzero exit code instead of crashing/segfaulting or hanging --
/// mirrors `runtime_file_read_aborts_on_null_handle_end_to_end`/
/// `runtime_tcp_send_aborts_on_null_handle_end_to_end`'s "trap loudly instead
/// of corrupting/crashing unpredictably" guarantee, extended to this
/// module's own `abort_if_null_window`.
#[test]
fn runtime_present_aborts_on_null_handle_end_to_end() {
    let src = "fn main():\n    \
               let w = null_ptr()\n    \
               println(\"before\")\n    \
               present(w)\n    \
               println(\"should not reach here\")\n";
    let output = compile_and_run_sdl("present_null_handle", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "must abort before the null handle is ever used: {}", stdout);
    assert!(stdout.contains("null/closed window handle"), "should print a diagnostic: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "should exit cleanly with code 1, not crash/segfault: {:?}", output.status);
}

#[test]
fn runtime_draw_pixel_aborts_on_null_handle_end_to_end() {
    let src = "fn main():\n    \
               let w = null_ptr()\n    \
               println(\"before\")\n    \
               draw_pixel(w, 0, 0, Color32(255, 0, 0, 255))\n    \
               println(\"should not reach here\")\n";
    let output = compile_and_run_sdl("draw_pixel_null_handle", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "{}", stdout);
    assert!(stdout.contains("null/closed window handle"), "{}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

#[test]
fn runtime_window_destroy_aborts_on_null_handle_end_to_end() {
    let src = "fn main():\n    \
               let w = null_ptr()\n    \
               println(\"before\")\n    \
               window_destroy(w)\n    \
               println(\"should not reach here\")\n";
    let output = compile_and_run_sdl("window_destroy_null_handle", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "{}", stdout);
    assert!(stdout.contains("null/closed window handle"), "{}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

// ===== Bug-hunting round 5: geometry/vector-math/quaternion/matrix/palette =

/// `Ty::Color32`/`Ty::PaletteIndex` (`docs/design.md`'s "Math and geometry"
/// section, added in "Expanded types 9") were never added to the general
/// f-string-as-value path's (`TypedExpr::FStr` in `codegen/expr.rs`)
/// format-specifier/vararg-widening table -- the same table round 4's
/// follow-up ported `emit_print_like`'s full set into (`I8`/`I16`/`U8`/`U16`/
/// `U32`/`I64`/`U64`/`F64`/`Char`/`Symbol`/`Tick`/`Duration`/`Instant`/
/// `Wrapping<T>`/`Fixed<Bits,Frac>`), and the prior round's `BitField<N>`/
/// `Flags<E>` did get their own arms -- but `Color32`/`PaletteIndex` fell
/// through to the `_ => "%p"` catch-all, tagging their bare `i32`/`u8`
/// registers as pointer varargs. Confirmed via a real `star build` before
/// this fix: `f"color: {c}"` for a `Color32` local failed `clang`
/// compilation outright with `'%tN' defined with type 'i32' but expected
/// 'ptr'` (the `snprintf` sizing call and the real call disagree on the
/// vararg's type, an invalid-IR error, not just a wrong runtime value).
/// Asserts the fix at the IR level: both interpolations must use `%u`, and
/// the `snprintf` call's varargs must be tagged `i32` (`Color32`, no
/// widening needed) and `i32` again (`PaletteIndex`'s bare `u8`, zero-
/// extended per C's variadic-promotion rule), never `i8*`.
#[test]
fn codegen_fstring_value_interpolates_color32_and_palette_index_with_correct_specifier_and_vararg_type() {
    let src = "fn t(c: Color32, p: PaletteIndex) -> str:\n    f\"c={c} p={p}\"\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("c=%u p=%u"), "Color32/PaletteIndex should both use %u, not fall through to %p: {}", ir);
    let fn_ir = extract_fn_body(&ir, "define i8* @t(");
    // `PaletteIndex`'s bare `u8` must be zero-extended to `i32` (C's variadic
    // promotion rule) before either `snprintf` call, and neither vararg may
    // be tagged `i8*` (the pre-fix bug: a plain `i32`/`i8` register used
    // where the `%p` specifier's `i8*` type was expected -- an invalid-IR
    // vararg type mismatch `clang` rejects outright).
    assert!(fn_ir.contains("zext i8"), "PaletteIndex's bare u8 must be zero-extended to i32: {}", fn_ir);
    assert!(
        fn_ir.contains("@snprintf(i8* null, i64 0, i8* ") && fn_ir.matches(", i32 ").count() >= 4,
        "both snprintf calls' Color32/PaletteIndex varargs must be tagged i32, not i8*: {}",
        fn_ir
    );
}

/// Runtime companion: actually compiling (via `clang`) and running an
/// f-string value that interpolates a `Color32`/`PaletteIndex` must produce
/// the exact packed/narrow value, not fail to compile and not print garbage
/// (confirmed pre-fix: `PaletteIndex`'s bare `u8` printed via the `%p`
/// catch-all read 7 uninitialized upper bytes off the vararg slot,
/// producing a garbage pointer-looking value instead of `7`).
#[test]
fn runtime_fstring_value_interpolates_color32_and_palette_index_end_to_end() {
    let src = "fn main():\n    \
               let c: Color32 = Color32(10, 20, 30, 40)\n    \
               let s = f\"color: {c}\"\n    \
               println(s)\n    \
               let idx: PaletteIndex = PaletteIndex(7)\n    \
               let s2 = f\"index: {idx}\"\n    \
               println(s2)\n";
    let output = compile_and_run("fstring_value_color32_palette_index", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    // 10 | 20<<8 | 30<<16 | 40<<24 = 673059850.
    assert_eq!(lines, vec!["color: 673059850", "index: 7"], "{}", stdout);
}

/// Same bug, reached through `println(f"...")`'s direct sole-argument path
/// (`emit_print_like` in `builtins.rs`) rather than the general f-string
/// value path -- a separate format-specifier table with the identical gap.
/// This path didn't fail to compile (the vararg's LLVM type tag already
/// matched `Color32`/`PaletteIndex`'s real type here, just paired with the
/// wrong `%p` specifier), but printed the packed value in hex pointer
/// notation instead of decimal, and printed `PaletteIndex`'s un-widened `u8`
/// with garbage upper bytes since `%p` reads a full pointer-width slot.
#[test]
fn runtime_print_fstring_interpolates_color32_and_palette_index_end_to_end() {
    let src = "fn main():\n    \
               let c: Color32 = Color32(10, 20, 30, 40)\n    \
               println(f\"color: {c}\")\n    \
               let idx: PaletteIndex = PaletteIndex(7)\n    \
               println(f\"index: {idx}\")\n";
    let output = compile_and_run("print_fstring_color32_palette_index", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["color: 673059850", "index: 7"], "{}", stdout);
}

// --- cross-platform codegen (`crate::codegen::platform::Target`) ----------
//
// `crate::codegen::sdl` (and `audio.rs`/`gamepad.rs`) bind SDL2's own C ABI
// directly, with no Win32-specific code anywhere in them -- unlike
// `net.rs`/`os.rs`, there is no `Target` branch to write here at all; the
// Linux gap was pure packaging (this repo only vendors a Windows SDL2
// build), not codegen. Link/run-verified by hand against the Debian devbox
// 2026-07-30 (system `libsdl2-dev`, linked with a bare `-lSDL2`, no `-L`
// needed unlike Windows' vendored `-L sdl/lib/x64`): a real window create /
// clear_screen / draw_rect / present / get_pixel round trip under
// `SDL_VIDEODRIVER=dummy` read back exactly the colors drawn, and
// `gamepad_count`/`key_down`/`mouse_x`/`mouse_y` all returned safe defaults
// with no gamepad/display attached. See `docs/cross_platform_scope.md`'s
// "Already seamed" section. The one thing worth pinning down as a checked
// regression (this crate's test suite has no Linux clang/ld to link
// against, so it can't repeat the link/run proof itself) is the claim this
// whole section rests on: that SDL-builtin IR is genuinely target-invariant,
// not just assumed to be.

/// `window_create`/`clear_screen`/`draw_rect`/`present`/`get_pixel`/
/// `gamepad_count`'s call-site IR (the `@main` body, with its leading
/// `@sym.lock`/`@rng.lock` init block stripped out) is byte-identical under
/// `Target::LinuxGnu` and the default `Target::WindowsGnu` -- confirming
/// there is genuinely no Win32-specific branch hiding in
/// `crate::codegen::sdl`/`gamepad`, unlike `net.rs`/`os.rs` which each
/// needed a real `Target` match arm. `@main` always initializes those two
/// locks unconditionally (`Codegen::emit_sym_lock_init`/
/// `emit_rng_lock_init`), regardless of whether a program uses `Symbol`/
/// `rand` at all, and those genuinely do route through
/// `crate::codegen::platform`'s `Target`-gated semaphore primitives
/// (`CreateSemaphoreA` vs. `malloc`+`sem_init`, a different *line count*
/// per target, not just different call names) -- left in, a whole-body
/// comparison would fail for a reason that has nothing to do with SDL, so
/// every line belonging to that block is filtered out here.
#[test]
fn codegen_sdl_and_gamepad_ir_is_target_invariant() {
    let src = "fn main():\n    \
               let w = window_create(\"t\", 64, 48)\n    \
               clear_screen(w, Color32(10, 20, 30, 255))\n    \
               draw_rect(w, 5, 5, 10, 10, Color32(200, 100, 50, 255))\n    \
               present(w)\n    \
               let p = get_pixel(w, 8, 8)\n    \
               println(f\"{color32_r(p)}\")\n    \
               println(f\"{gamepad_count()}\")\n    \
               window_destroy(w)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");

    let windows_ir = Driver::codegen(&typed).expect("should codegen for the default (Windows) target");
    let linux_v = Driver::codegen_verified_for_target(&typed, star::codegen::Target::LinuxGnu).expect("should codegen for Target::LinuxGnu");

    let lock_init_markers = ["sym.lock", "rng.lock", "CreateSemaphoreA", "@sem_init", "malloc(i64 32)"];
    let strip_lock_init = |ir: &str| -> String {
        extract_fn_body(ir, "define i32 @main(")
            .lines()
            .filter(|l| !lock_init_markers.iter().any(|m| l.contains(m)))
            .collect::<Vec<_>>()
            .join("\n")
    };
    assert_eq!(
        strip_lock_init(&windows_ir),
        strip_lock_init(&linux_v.ir),
        "SDL/gamepad call-site IR in @main should be identical across targets aside from lock init"
    );
}
