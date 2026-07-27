//! Bug-hunting round 6: SDL2 graphics/input, deeper pass
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Bug-hunting round 6 (SDL2 graphics/input, deeper pass): wide-coverage
// ===== tests for surface area round 5's own SDL audit didn't explicitly
// ===== exercise -- multiple simultaneous windows, `window_create` given
// ===== degenerate dimensions, a window `ptr` handle's round trip through a
// ===== struct field/`List<ptr>`/closure capture/function return, `draw_rect`
// ===== with negative width/height, and `key_down`/mouse polling before any
// ===== window (and therefore `SDL_Init`) has ever run. No new bug was found
// ===== in any of these areas (each was reproduced for real under
// ===== `SDL_VIDEODRIVER=dummy` and behaved correctly) -- see this round's
// ===== `todo.md` writeup for the full list, including the one pre-existing,
// ===== shared-not-SDL-specific limitation noted but deliberately left
// ===== unfixed (a `ptr` handle aliased into a second variable before
// ===== `window_destroy` is not nulled out, identical to `file_close`/
// ===== `tcp_close`'s own documented behavior).

/// `window_create` called twice returns two distinct, independently
/// drawable/destroyable window handles -- not a single cached window/renderer
/// pointer silently shared or overwritten by the second call, the classic
/// first-cut-binding bug shape for "one renderer per window" (see this
/// module's own doc comment for why no renderer handle is cached at all,
/// re-derived fresh via `SDL_GetRenderer` every time instead). Draws to `a`,
/// destroys `a`, then keeps drawing to and finally destroys `b` -- `b` must
/// stay fully usable throughout, confirming `window_destroy` on one window
/// doesn't touch the other's state (no `SDL_Quit` is ever called, see
/// `emit_window_destroy`'s doc comment).
#[test]
fn runtime_multiple_windows_are_independent_end_to_end() {
    let src = "fn main():\n    \
               let a = window_create(\"a\", 32, 32)\n    \
               let b = window_create(\"b\", 32, 32)\n    \
               println(f\"{is_null(a)}\")\n    \
               println(f\"{is_null(b)}\")\n    \
               clear_screen(a, Color32(255, 0, 0, 255))\n    \
               clear_screen(b, Color32(0, 255, 0, 255))\n    \
               draw_pixel(a, 1, 1, Color32(1, 1, 1, 255))\n    \
               present(a)\n    \
               present(b)\n    \
               window_destroy(a)\n    \
               println(\"a destroyed\")\n    \
               clear_screen(b, Color32(0, 0, 255, 255))\n    \
               draw_rect(b, 0, 0, 4, 4, Color32(9, 9, 9, 255))\n    \
               present(b)\n    \
               window_destroy(b)\n    \
               println(\"b destroyed\")\n";
    let output = compile_and_run_sdl("multiple_windows_independent", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "false", "a destroyed", "b destroyed"], "{}", stdout);
}

/// `window_should_close`'s event-drain loop (see this module's doc comment)
/// is safe to call on two different windows in the same frame -- draining the
/// process-wide SDL event queue while polling window `a` doesn't starve `b`'s
/// own subsequent poll or otherwise misbehave now that there's more than one
/// live window.
#[test]
fn runtime_window_should_close_across_multiple_windows_end_to_end() {
    let src = "fn main():\n    \
               let a = window_create(\"a\", 32, 32)\n    \
               let b = window_create(\"b\", 32, 32)\n    \
               println(f\"{window_should_close(a)}\")\n    \
               println(f\"{window_should_close(b)}\")\n    \
               window_destroy(a)\n    \
               window_destroy(b)\n    \
               println(\"ok\")\n";
    let output = compile_and_run_sdl("window_should_close_multi_window", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "false", "ok"], "{}", stdout);
}

/// `draw_rect` given a negative width and/or height (not just a negative
/// origin -- `w`/`h` are caller-supplied ints passed straight through to the
/// hand-built `SDL_Rect`, never computed as an `x2 - x1` difference the way a
/// two-corner rect API might) must not crash; SDL itself is responsible for
/// treating a negative-extent rect as empty/no-op. Zero width/height (a
/// degenerate but non-negative rect) is exercised alongside it.
#[test]
fn runtime_draw_rect_negative_and_zero_dimensions_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"t\", 32, 32)\n    \
               draw_rect(w, 10, 10, -5, -5, Color32(1, 2, 3, 255))\n    \
               draw_rect(w, 10, 10, -5, 5, Color32(1, 2, 3, 255))\n    \
               draw_rect(w, 10, 10, 0, 0, Color32(1, 2, 3, 255))\n    \
               present(w)\n    \
               println(\"ok\")\n    \
               window_destroy(w)\n";
    let output = compile_and_run_sdl("draw_rect_negative_dims", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "ok");
}

/// `window_create` given a negative, zero, or very large width/height must
/// not crash the codegen'd program -- either `SDL_CreateWindow` accepts the
/// degenerate size (as SDL2 does under the headless `dummy` driver, which
/// allocates no real backing surface) or it fails and `window_create` reports
/// that failure the normal way (a null `ptr`, checked with `is_null`), never
/// an uncontrolled crash.
#[test]
fn runtime_window_create_degenerate_dimensions_end_to_end() {
    let src = "fn main():\n    \
               let a = window_create(\"neg\", -10, -10)\n    \
               println(f\"{is_null(a)}\")\n    \
               let b = window_create(\"zero\", 0, 0)\n    \
               println(f\"{is_null(b)}\")\n    \
               let c = window_create(\"huge\", 2000000000, 2000000000)\n    \
               println(f\"{is_null(c)}\")\n    \
               println(\"survived\")\n";
    let output = compile_and_run_sdl("window_create_degenerate_dims", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert!(String::from_utf8_lossy(&output.stdout).contains("survived"), "{}", String::from_utf8_lossy(&output.stdout));
}

/// A window `ptr` handle is just an opaque pointer value -- no RC header, no
/// generation-counter liveness tracking -- so it should round-trip cleanly
/// through every place an ordinary `ptr`-typed value can go: a struct field,
/// a `List<ptr>` element, a closure capture, and a function return value.
/// Confirms no accidental RC-release/retain codegen path (the kind `Ty::Str`/
/// arena `GenRef<T>` get) is misapplied to what must stay a bare pointer.
#[test]
fn runtime_window_ptr_survives_struct_list_closure_and_fn_return_end_to_end() {
    let src = concat!(
        "struct Holder:\n    w: ptr\n\n",
        "fn make_window() -> ptr:\n    window_create(\"ret\", 16, 16)\n\n",
        "fn main():\n",
        "    let w = make_window()\n",
        "    let h = Holder(w = w)\n",
        "    println(f\"{is_null(h.w)}\")\n",
        "    let mut lst: List<ptr> = List<ptr>()\n",
        "    lst.push(w)\n",
        "    println(f\"{is_null(lst[0])}\")\n",
        "    let closure = fn(): draw_pixel(w, 0, 0, Color32(1, 2, 3, 255))\n",
        "    closure()\n",
        "    present(w)\n",
        "    println(\"closure ok\")\n",
        "    window_destroy(w)\n",
    );
    let output = compile_and_run_sdl("window_ptr_interop", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "false", "closure ok"], "{}", stdout);
}

/// `key_down`/`mouse_x`/`mouse_y`/`mouse_button_down` take no window handle
/// (they read SDL's process-global keyboard/mouse state, see this module's
/// doc comment), so they're callable even before any `window_create` --
/// meaning before `SDL_Init(SDL_INIT_VIDEO)` has ever run. Must return safe
/// default values (`false`/`0`), not null-deref `SDL_GetKeyboardState`'s
/// returned array on an uninitialized keyboard subsystem.
#[test]
fn runtime_key_down_and_mouse_before_any_window_create_end_to_end() {
    let src = "fn main():\n    \
               println(f\"{key_down(41)}\")\n    \
               println(f\"{mouse_x()}\")\n    \
               println(f\"{mouse_y()}\")\n    \
               println(f\"{mouse_button_down(1)}\")\n";
    let output = compile_and_run_sdl("key_mouse_before_window_create", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "0", "0", "false"], "{}", stdout);
}

/// `window_destroy` called twice on the same bare-variable handle: the first
/// call nulls the caller's variable out (see `emit_window_destroy`'s doc
/// comment), so the second call hits the ordinary null-handle abort path
/// instead of a double-free reaching SDL. Complements
/// `runtime_window_destroy_aborts_on_null_handle_end_to_end`, which only
/// covers a handle that started out null (`null_ptr()`), not one that became
/// null as a side effect of a prior `window_destroy` on the same variable.
#[test]
fn runtime_double_window_destroy_aborts_cleanly_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"t\", 32, 32)\n    \
               window_destroy(w)\n    \
               println(\"first destroy ok\")\n    \
               window_destroy(w)\n    \
               println(\"should not reach\")\n";
    let output = compile_and_run_sdl("double_window_destroy", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("first destroy ok"), "{}", stdout);
    assert!(!stdout.contains("should not reach"), "second destroy must abort, not double-free: {}", stdout);
    assert!(stdout.contains("null/closed window handle"), "{}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}
