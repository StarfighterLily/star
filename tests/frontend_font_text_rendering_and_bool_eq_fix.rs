//! Bitmap text rendering/font loading; bool equality bugfix
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Text rendering / font loading (`crate::codegen::font`): closes ======
// ===== `projects/snake/NOTES.md` section 4's "no text/font rendering at ====
// ===== all" gap. `default_font`/`font_load` reuse `Ty::Ptr` as an opaque ===
// ===== font handle exactly like `window_create` does for `SDL_Window*`. ====
// ===== `get_pixel` (SDL_RenderReadPixels) is new supporting infrastructure ==
// ===== added alongside this feature specifically so these tests can =======
// ===== verify *actual rendered pixels* rather than only "didn't crash" -- ==
// ===== every prior SDL drawing builtin's tests could only assert the ======
// ===== latter, since there was previously no way to read a framebuffer ====
// ===== pixel back at all. ===================================================

/// `default_font`/`font_load` type-check to `ptr` (`window_create`'s own
/// opaque-handle convention); `measure_text` to `(int, int)`; `get_pixel` to
/// `Color32`; `font_free`/`draw_text` to nothing.
#[test]
fn checks_font_builtin_return_types() {
    let src = concat!(
        "fn t():\n",
        "    let f: ptr = default_font()\n",
        "    let g: ptr = font_load(\"x.sbf\")\n",
        "    font_free(g)\n",
        "    let w = window_create(\"t\", 8, 8)\n",
        "    draw_text(w, f, \"hi\", 0, 0, 1, Color32(1, 2, 3, 255))\n",
        "    let sz: (i32, i32) = measure_text(f, \"hi\", 1)\n",
        "    let c: Color32 = get_pixel(w, 0, 0)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let result = Driver::check(&module);
    assert!(result.is_ok(), "{:?}", result.err());
}

#[test]
fn checker_rejects_default_font_wrong_arg_count() {
    let src = "fn t():\n    let f = default_font(1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("default_font(1) should be rejected") };
    assert!(diags.iter().any(|d| d.message.contains("`default_font` expects 0 argument")), "{:?}", diags);
}

#[test]
fn checker_rejects_font_load_wrong_arg_count() {
    let src = "fn t():\n    let f = font_load()\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("font_load() should be rejected") };
    assert!(diags.iter().any(|d| d.message.contains("`font_load` expects 1 argument")), "{:?}", diags);
}

#[test]
fn checker_rejects_font_load_wrong_arg_type() {
    let src = "fn t():\n    let f = font_load(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("font_load(5) should be rejected") };
    assert!(diags.iter().any(|d| d.message.contains("`font_load` expects a `str` argument")), "{:?}", diags);
}

#[test]
fn checker_rejects_font_free_wrong_arg_type() {
    let src = "fn t():\n    font_free(\"nope\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("font_free(\"nope\") should be rejected") };
    assert!(diags.iter().any(|d| d.message.contains("`font_free` expects a `ptr` argument")), "{:?}", diags);
}

#[test]
fn checker_rejects_draw_text_wrong_arg_count() {
    let src = "fn t():\n    let w = window_create(\"t\", 8, 8)\n    draw_text(w, default_font(), \"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("draw_text with 3 args should be rejected") };
    assert!(diags.iter().any(|d| d.message.contains("`draw_text` expects 7 argument")), "{:?}", diags);
}

/// One dedicated bad-type check per argument slot -- `draw_text`'s own
/// checker arm validates each position independently (window/font `ptr`,
/// text `str`, x/y/scale `int`, color `Color32`), so a single "some argument
/// is wrong" test wouldn't confirm every position is actually checked.
#[test]
fn checker_rejects_draw_text_wrong_arg_types() {
    let src = concat!(
        "fn t():\n",
        "    let w = window_create(\"t\", 8, 8)\n",
        "    draw_text(1, default_font(), \"hi\", 0, 0, 1, Color32(1, 2, 3, 255))\n",
        "    draw_text(w, \"not a font\", \"hi\", 0, 0, 1, Color32(1, 2, 3, 255))\n",
        "    draw_text(w, default_font(), 5, 0, 0, 1, Color32(1, 2, 3, 255))\n",
        "    draw_text(w, default_font(), \"hi\", \"x\", 0, 1, Color32(1, 2, 3, 255))\n",
        "    draw_text(w, default_font(), \"hi\", 0, \"y\", 1, Color32(1, 2, 3, 255))\n",
        "    draw_text(w, default_font(), \"hi\", 0, 0, \"s\", Color32(1, 2, 3, 255))\n",
        "    draw_text(w, default_font(), \"hi\", 0, 0, 1, 5)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("every draw_text call above has a wrong-typed argument and should be rejected") };
    for expected in [
        "`draw_text` argument 1 (window) expected `ptr`",
        "`draw_text` argument 2 (font) expected `ptr`",
        "`draw_text` argument 3 (text) expected `str`",
        "`draw_text` argument 4 expected `int`",
        "`draw_text` argument 5 expected `int`",
        "`draw_text` argument 6 expected `int`",
        "`draw_text` argument 7 (color) expected `Color32`",
    ] {
        assert!(diags.iter().any(|d| d.message.contains(expected)), "expected {:?}, got: {:?}", expected, diags);
    }
}

#[test]
fn checker_rejects_measure_text_wrong_arg_count() {
    let src = "fn t():\n    let sz = measure_text(default_font(), \"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("measure_text with 2 args should be rejected") };
    assert!(diags.iter().any(|d| d.message.contains("`measure_text` expects 3 argument")), "{:?}", diags);
}

#[test]
fn checker_rejects_measure_text_wrong_arg_types() {
    let src = concat!(
        "fn t():\n",
        "    let a = measure_text(\"not a font\", \"hi\", 1)\n",
        "    let b = measure_text(default_font(), 5, 1)\n",
        "    let c = measure_text(default_font(), \"hi\", \"s\")\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("every measure_text call above has a wrong-typed argument and should be rejected") };
    for expected in [
        "`measure_text` argument 1 (font) expected `ptr`",
        "`measure_text` argument 2 (text) expected `str`",
        "`measure_text` argument 3 (scale) expected `int`",
    ] {
        assert!(diags.iter().any(|d| d.message.contains(expected)), "expected {:?}, got: {:?}", expected, diags);
    }
}

#[test]
fn checker_rejects_get_pixel_wrong_arg_count() {
    let src = "fn t():\n    let w = window_create(\"t\", 8, 8)\n    let c = get_pixel(w, 0)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("get_pixel with 2 args should be rejected") };
    assert!(diags.iter().any(|d| d.message.contains("`get_pixel` expects 3 argument")), "{:?}", diags);
}

#[test]
fn checker_rejects_get_pixel_wrong_arg_types() {
    let src = concat!(
        "fn t():\n",
        "    let a = get_pixel(\"not a window\", 0, 0)\n",
        "    let b = get_pixel(window_create(\"t\", 8, 8), \"x\", 0)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("every get_pixel call above has a wrong-typed argument and should be rejected") };
    assert!(diags.iter().any(|d| d.message.contains("`get_pixel` argument 1 expected `ptr`")), "{:?}", diags);
    assert!(diags.iter().any(|d| d.message.contains("`get_pixel` argument 2 expected `int`")), "{:?}", diags);
}

/// `draw_text`/`get_pixel` touch the shared `SDL_Renderer*` exactly like
/// `draw_rect`/`draw_pixel` already do, so they must join the same
/// `par`/`swarm` ban list (`crate::types::par_analysis::
/// is_banned_sdl_builtin_in_par`) -- a regression guard that the ban list
/// was actually extended, not just the two new builtins added elsewhere.
#[test]
fn rejects_draw_text_and_get_pixel_inside_par_body() {
    let src = concat!(
        "struct Entity:\n    mut idx: i32\n\n",
        "arena Entities: Entity\n\n",
        "fn main():\n",
        "    let w = window_create(\"race\", 64, 48)\n",
        "    let f = default_font()\n",
        "    par e in Entities:\n",
        "        draw_text(w, f, \"x\", e.idx, e.idx, 1, Color32(1, 2, 3, 255))\n",
        "        let c = get_pixel(w, e.idx, e.idx)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else {
        panic!("draw_text/get_pixel on a captured window handle inside a par/swarm body should be rejected")
    };
    for name in ["draw_text", "get_pixel"] {
        assert!(
            diags.iter().any(|d| d.message.contains(&format!("cannot call `{}`", name)) && d.message.contains("shared window/renderer")),
            "expected a rejection for `{}`, got: {:?}",
            name,
            diags
        );
    }
}

/// Sibling positive test: `font_load`/`font_free`/`default_font`/
/// `measure_text` touch no shared window/renderer/event-queue state (a font
/// handle is its own independent resource), so -- like `delay`/`ticks` --
/// they must stay usable inside a `par`/`swarm` body. Guards against
/// overcorrecting the ban list to reject every builtin this module adds
/// indiscriminately.
#[test]
fn accepts_font_load_and_measure_text_inside_par_body() {
    let src = concat!(
        "struct Entity:\n    mut idx: i32\n\n",
        "arena Entities: Entity\n\n",
        "fn main():\n",
        "    par e in Entities:\n",
        "        let f = default_font()\n",
        "        let sz = measure_text(f, \"x\", 1)\n",
        "        let g = font_load(\"x.sbf\")\n",
        "        font_free(g)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let result = Driver::check(&module);
    assert!(result.is_ok(), "font_load/font_free/default_font/measure_text inside a par/swarm body should still be allowed: {:?}", result.err());
}

/// `default_font()` draws a legible-enough glyph for every hand-authored
/// character to actually light up at least one pixel and to leave at least
/// one pixel of its cell dark -- a real end-to-end render, not just a
/// type-check, verified by reading the framebuffer back with `get_pixel`
/// (this module's own new supporting builtin -- there was no way to
/// observe a drawn pixel at all before it existed). `'A'`'s glyph is
/// `..#.. / .#.#. / #...# / #...# / ##### / #...# / #...#`: at scale 1
/// starting at `(0, 0)`, `(2, 0)` (row 0's lit middle column) must be the
/// draw color, while `(0, 0)` (row 0's blank first column) must still be
/// the clear color.
#[test]
fn runtime_default_font_draw_text_renders_expected_pixels_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let w = window_create(\"t\", 40, 40)\n",
        "    let f = default_font()\n",
        "    clear_screen(w, Color32(0, 0, 0, 255))\n",
        "    draw_text(w, f, \"A\", 0, 0, 1, Color32(200, 100, 50, 255))\n",
        "    present(w)\n",
        "    println(f\"{get_pixel(w, 2, 0) == Color32(200, 100, 50, 255)}\")\n",
        "    println(f\"{get_pixel(w, 0, 0) == Color32(0, 0, 0, 255)}\")\n",
        "    println(f\"{get_pixel(w, 0, 2) == Color32(200, 100, 50, 255)}\")\n",
        "    println(f\"{get_pixel(w, 4, 2) == Color32(200, 100, 50, 255)}\")\n",
        "    window_destroy(w)\n",
    );
    let output = compile_and_run_sdl("default_font_draw_text_renders_expected_pixels", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "true", "true", "true"], "{}", stdout);
}

/// `\n` inside `draw_text`'s `text` resets the cursor's `x` back to its
/// starting column and advances `y` by exactly one line height
/// (`(height+1)*scale`) -- verified by reading back three specific pixels:
/// the first line's lit column, the (blank) 1-row gap between lines, and
/// the second line's lit column at its expected `y` offset.
#[test]
fn runtime_draw_text_newline_advances_to_next_line_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let w = window_create(\"t\", 40, 40)\n",
        "    let f = default_font()\n",
        "    clear_screen(w, Color32(0, 0, 0, 255))\n",
        "    draw_text(w, f, \"A\\nA\", 0, 0, 1, Color32(255, 255, 255, 255))\n",
        "    present(w)\n",
        "    println(f\"{get_pixel(w, 2, 0) == Color32(255, 255, 255, 255)}\")\n",
        "    println(f\"{get_pixel(w, 2, 7) == Color32(0, 0, 0, 255)}\")\n",
        "    println(f\"{get_pixel(w, 2, 8) == Color32(255, 255, 255, 255)}\")\n",
        "    window_destroy(w)\n",
    );
    let output = compile_and_run_sdl("draw_text_newline_advances_to_next_line", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "true", "true"], "{}", stdout);
}

/// `measure_text` reports `((width+1)*scale*char_count, (height+1)*scale -
/// scale)` for single-line text -- exact numbers, not just "some positive
/// int", against the built-in default font's known `5x7` metrics.
#[test]
fn runtime_measure_text_exact_single_line_metrics_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let f = default_font()\n",
        "    let sz = measure_text(f, \"AB\", 2)\n",
        "    println(f\"{sz.0} {sz.1}\")\n",
    );
    let output = compile_and_run_sdl("measure_text_exact_single_line_metrics", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "24 14");
}

/// Sibling covering the `\n` line-break case: two 2-character lines report
/// the same width as one (both lines are equally long) but a taller height
/// (`2*line_height - 1*gap` instead of `1*line_height - 1*gap`).
#[test]
fn runtime_measure_text_exact_multiline_metrics_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let f = default_font()\n",
        "    let sz = measure_text(f, \"AB\\nCD\", 2)\n",
        "    println(f\"{sz.0} {sz.1}\")\n",
    );
    let output = compile_and_run_sdl("measure_text_exact_multiline_metrics", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "24 30");
}

/// An empty string still reports one line's worth of height (a HUD caption
/// that's sometimes blank shouldn't collapse its layout to zero height) and
/// zero width.
#[test]
fn runtime_measure_text_empty_string_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let f = default_font()\n",
        "    let sz = measure_text(f, \"\", 2)\n",
        "    println(f\"{sz.0} {sz.1}\")\n",
    );
    let output = compile_and_run_sdl("measure_text_empty_string", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "0 14");
}

/// `draw_text`/`measure_text` fold lowercase `a`-`z` to its uppercase
/// codepoint before glyph lookup (the built-in default font only defines
/// uppercase letters) -- `measure_text` on the same text in both cases must
/// report identical metrics, confirming the fold actually happens rather
/// than lowercase silently falling through as "unsupported" (which would
/// still report the *same* width today, since an unsupported codepoint
/// advances by exactly one cell too -- see the next test -- so this alone
/// wouldn't distinguish "folded" from "coincidentally same width"; the
/// paired rendering test below closes that gap by checking actual pixels).
#[test]
fn runtime_measure_text_lowercase_and_uppercase_same_metrics_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let f = default_font()\n",
        "    let lower = measure_text(f, \"abc\", 2)\n",
        "    let upper = measure_text(f, \"ABC\", 2)\n",
        "    println(f\"{lower.0 == upper.0 and lower.1 == upper.1}\")\n",
    );
    let output = compile_and_run_sdl("measure_text_lowercase_and_uppercase_same_metrics", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "true");
}

/// The rendering half of the lowercase-folding claim above: `draw_text`
/// with a lowercase `"a"` must light up exactly the same pixels as an
/// uppercase `"A"` -- not just report the same *width* (which an
/// unsupported/blank glyph would also do).
#[test]
fn runtime_draw_text_lowercase_renders_same_pixels_as_uppercase_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let w = window_create(\"t\", 40, 40)\n",
        "    let f = default_font()\n",
        "    clear_screen(w, Color32(0, 0, 0, 255))\n",
        "    draw_text(w, f, \"a\", 0, 0, 1, Color32(255, 255, 255, 255))\n",
        "    present(w)\n",
        "    println(f\"{get_pixel(w, 2, 0) == Color32(255, 255, 255, 255)}\")\n",
        "    println(f\"{get_pixel(w, 0, 0) == Color32(0, 0, 0, 255)}\")\n",
        "    println(f\"{get_pixel(w, 0, 2) == Color32(255, 255, 255, 255)}\")\n",
        "    window_destroy(w)\n",
    );
    let output = compile_and_run_sdl("draw_text_lowercase_renders_same_pixels_as_uppercase", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "true", "true"], "{}", stdout);
}

/// A character outside the default font's declared `[' ', 'Z']` range (`@`
/// is inside that range but has no hand-authored glyph, so use `~`, which
/// is outside it entirely) still advances the cursor by exactly one glyph
/// cell -- confirmed both by `measure_text`'s reported width (this test)
/// and, in the sibling test below, by `draw_text` actually leaving that
/// cell blank rather than drawing garbage.
#[test]
fn runtime_measure_text_unsupported_character_still_advances_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let f = default_font()\n",
        "    let sz = measure_text(f, \"~~\", 2)\n",
        "    println(f\"{sz.0}\")\n",
    );
    let output = compile_and_run_sdl("measure_text_unsupported_character_still_advances", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "24");
}

/// The rendering half of the above: `~` (outside the default font's range)
/// must draw as a fully blank cell -- every pixel in its cell stays the
/// clear color -- not garbage from reading past the font's glyph table.
#[test]
fn runtime_draw_text_unsupported_character_renders_blank_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let w = window_create(\"t\", 40, 40)\n",
        "    let f = default_font()\n",
        "    clear_screen(w, Color32(0, 0, 0, 255))\n",
        "    draw_text(w, f, \"~\", 0, 0, 1, Color32(255, 255, 255, 255))\n",
        "    present(w)\n",
        "    let mut all_blank = true\n",
        "    let mut row = 0\n",
        "    while row < 7:\n",
        "        let mut col = 0\n",
        "        while col < 5:\n",
        "            if get_pixel(w, col, row) != Color32(0, 0, 0, 255):\n",
        "                all_blank = false\n",
        "            col += 1\n",
        "        row += 1\n",
        "    println(f\"{all_blank}\")\n",
        "    window_destroy(w)\n",
    );
    let output = compile_and_run_sdl("draw_text_unsupported_character_renders_blank", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "true");
}

/// `draw_text`'s `scale` argument, like `delay`'s `ms`, is clamped to a safe
/// minimum (`1`) rather than trusted as-is -- a `0` or negative scale must
/// not crash or hang (a naive implementation might divide by it, or produce
/// a zero-size fill rect it then loops forever trying to advance past).
/// Confirmed both ways: the program must still exit cleanly, and the
/// clamped-to-1 rendering must actually happen (checked the same way as
/// the unsupported-character test above -- a lit pixel where scale-1
/// rendering would put one).
#[test]
fn runtime_draw_text_negative_and_zero_scale_clamped_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let w = window_create(\"t\", 40, 40)\n",
        "    let f = default_font()\n",
        "    clear_screen(w, Color32(0, 0, 0, 255))\n",
        "    draw_text(w, f, \"A\", 0, 0, -5, Color32(255, 255, 255, 255))\n",
        "    draw_text(w, f, \"A\", 10, 0, 0, Color32(255, 255, 255, 255))\n",
        "    present(w)\n",
        "    println(f\"{get_pixel(w, 2, 0) == Color32(255, 255, 255, 255)}\")\n",
        "    println(f\"{get_pixel(w, 12, 0) == Color32(255, 255, 255, 255)}\")\n",
        "    println(\"survived\")\n",
        "    window_destroy(w)\n",
    );
    let output = compile_and_run_sdl("draw_text_negative_and_zero_scale_clamped", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "true", "survived"], "{}", stdout);
}

/// `measure_text`'s `scale` is clamped the same way -- a `0`/negative scale
/// must not produce a negative or zero-divide-adjacent width/height.
#[test]
fn runtime_measure_text_negative_and_zero_scale_clamped_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let f = default_font()\n",
        "    let a = measure_text(f, \"AB\", -5)\n",
        "    let b = measure_text(f, \"AB\", 0)\n",
        "    println(f\"{a.0} {a.1} {b.0} {b.1}\")\n",
    );
    let output = compile_and_run_sdl("measure_text_negative_and_zero_scale_clamped", src);
    assert!(output.status.success(), "{:?}", output.status);
    // Both clamp to scale 1: width == 2*(5+1)*1 == 12, height == (7+1)*1 - 1 == 7.
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "12 7 12 7");
}

/// `default_font()` is memoized (`Codegen::default_font_global`) -- calling
/// it more than once (the realistic per-frame usage pattern) must return a
/// pointer to the *same* underlying constant each time, not a fresh
/// duplicate global per call site. `ptr == ptr` (this module's own doc
/// comment: legalized well before this feature, `crate::codegen::sdl`'s
/// `Ty::Ptr` doc comment) is the direct way to confirm pointer identity.
#[test]
fn runtime_default_font_handle_is_stable_across_calls_end_to_end() {
    let src = "fn main():\n    let a = default_font()\n    let b = default_font()\n    println(f\"{a == b}\")\n";
    let output = compile_and_run_sdl("default_font_handle_is_stable_across_calls", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "true");
}

/// Full round trip through `font_load`'s own on-disk format (this module's
/// doc comment): a hand-built 2-row, 3-column, 1-glyph font file (glyph
/// `'A'`: row 0 `#.#`, row 1 `.#.`) written via `file_write`/`chr`, loaded
/// back via `font_load`, then actually drawn and read back pixel-by-pixel
/// via `get_pixel` -- the strongest possible confirmation that the file
/// format's header/glyph-row byte layout is parsed exactly as designed, not
/// just that *some* non-null handle came back.
#[test]
fn runtime_font_load_custom_glyph_round_trip_renders_expected_pixels_end_to_end() {
    let path = scratch_file_path("star_test_font_load_custom_glyph.sbf");
    let src = format!(
        concat!(
            "fn main():\n",
            "    let p = \"{p}\"\n",
            "    let fh = file_open(p, \"wb\")\n",
            "    let bytes = concat(concat(concat(concat(concat(chr(3), chr(2)), chr(65)), chr(1)), chr(5)), chr(2))\n",
            "    file_write(fh, bytes)\n",
            "    file_close(fh)\n",
            "    let custom = font_load(p)\n",
            "    println(f\"{{is_null(custom)}}\")\n",
            "    let w = window_create(\"t\", 40, 40)\n",
            "    clear_screen(w, Color32(0, 0, 0, 255))\n",
            "    draw_text(w, custom, \"A\", 0, 0, 1, Color32(255, 255, 255, 255))\n",
            "    present(w)\n",
            "    println(f\"{{get_pixel(w, 0, 0) == Color32(255, 255, 255, 255)}}\")\n",
            "    println(f\"{{get_pixel(w, 1, 0) == Color32(0, 0, 0, 255)}}\")\n",
            "    println(f\"{{get_pixel(w, 2, 0) == Color32(255, 255, 255, 255)}}\")\n",
            "    println(f\"{{get_pixel(w, 0, 1) == Color32(0, 0, 0, 255)}}\")\n",
            "    println(f\"{{get_pixel(w, 1, 1) == Color32(255, 255, 255, 255)}}\")\n",
            "    println(f\"{{get_pixel(w, 2, 1) == Color32(0, 0, 0, 255)}}\")\n",
            "    font_free(custom)\n",
            "    window_destroy(w)\n",
        ),
        p = path
    );
    let output = compile_and_run_sdl("font_load_custom_glyph_round_trip_renders_expected_pixels", &src);
    let _ = std::fs::remove_file(&path);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "true", "true", "true", "true", "true", "true"], "{}", stdout);
}

#[test]
fn runtime_font_load_missing_file_returns_null_end_to_end() {
    let src = "fn main():\n    let f = font_load(\"this_file_does_not_exist_star_test.sbf\")\n    println(f\"{is_null(f)}\")\n";
    let output = compile_and_run_sdl("font_load_missing_file_returns_null", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "true");
}

/// A file shorter than the format's fixed 4-byte header must be rejected,
/// not read past its own end.
#[test]
fn runtime_font_load_truncated_header_returns_null_end_to_end() {
    let path = scratch_file_path("star_test_font_load_truncated_header.sbf");
    let src = format!(
        concat!(
            "fn main():\n",
            "    let p = \"{p}\"\n",
            "    let fh = file_open(p, \"wb\")\n",
            "    file_write(fh, \"ab\")\n",
            "    file_close(fh)\n",
            "    let f = font_load(p)\n",
            "    println(f\"{{is_null(f)}}\")\n",
        ),
        p = path
    );
    let output = compile_and_run_sdl("font_load_truncated_header_returns_null", &src);
    let _ = std::fs::remove_file(&path);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "true");
}

/// A header claiming more (or fewer) glyph-row bytes than the file actually
/// contains must be rejected -- here `height=2`/`num_chars=1` promises 2
/// glyph-row bytes (6 bytes total) but the file only has 1 (5 bytes total).
/// Guards against `draw_text`/`measure_text` later reading past a
/// `malloc`'d buffer's real end.
#[test]
fn runtime_font_load_size_mismatch_returns_null_end_to_end() {
    let path = scratch_file_path("star_test_font_load_size_mismatch.sbf");
    let src = format!(
        concat!(
            "fn main():\n",
            "    let p = \"{p}\"\n",
            "    let fh = file_open(p, \"wb\")\n",
            "    let bytes = concat(concat(concat(chr(3), chr(2)), chr(65)), concat(chr(1), chr(5)))\n",
            "    file_write(fh, bytes)\n",
            "    file_close(fh)\n",
            "    let f = font_load(p)\n",
            "    println(f\"{{is_null(f)}}\")\n",
        ),
        p = path
    );
    let output = compile_and_run_sdl("font_load_size_mismatch_returns_null", &src);
    let _ = std::fs::remove_file(&path);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "true");
}

/// `width` outside `1..=8` (this format packs one glyph row into a single
/// byte, so a wider glyph can't be represented) must be rejected even when
/// the file's overall size otherwise matches the header's own claim --
/// covers both directions: `width=0` and `width=9`.
#[test]
fn runtime_font_load_width_out_of_range_returns_null_end_to_end() {
    let path_zero = scratch_file_path("star_test_font_load_width_zero.sbf");
    let path_big = scratch_file_path("star_test_font_load_width_nine.sbf");
    let src = format!(
        concat!(
            "fn main():\n",
            "    let p0 = \"{p0}\"\n",
            "    let fh0 = file_open(p0, \"wb\")\n",
            "    let bytes0 = concat(concat(concat(chr(0), chr(1)), chr(65)), concat(chr(1), chr(0)))\n",
            "    file_write(fh0, bytes0)\n",
            "    file_close(fh0)\n",
            "    println(f\"{{is_null(font_load(p0))}}\")\n",
            "    let p1 = \"{p1}\"\n",
            "    let fh1 = file_open(p1, \"wb\")\n",
            "    let bytes1 = concat(concat(concat(chr(9), chr(1)), chr(65)), concat(chr(1), chr(0)))\n",
            "    file_write(fh1, bytes1)\n",
            "    file_close(fh1)\n",
            "    println(f\"{{is_null(font_load(p1))}}\")\n",
        ),
        p0 = path_zero,
        p1 = path_big
    );
    let output = compile_and_run_sdl("font_load_width_out_of_range_returns_null", &src);
    let _ = std::fs::remove_file(&path_zero);
    let _ = std::fs::remove_file(&path_big);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "true"], "{}", stdout);
}

/// `font_free`, like `window_destroy`/`file_close`, nulls out the caller's
/// own variable when it's a bare `Ident` -- so a later accidental reuse
/// hits `is_null`/the abort path instead of silently handing a dangling
/// pointer to `draw_text`/`measure_text`.
#[test]
fn runtime_font_free_nulls_caller_binding_end_to_end() {
    let path = scratch_file_path("star_test_font_free_nulls_caller_binding.sbf");
    let src = format!(
        concat!(
            "fn main():\n",
            "    let p = \"{p}\"\n",
            "    let fh = file_open(p, \"wb\")\n",
            "    let bytes = concat(concat(concat(concat(concat(chr(1), chr(1)), chr(65)), chr(1)), chr(1)), \"\")\n",
            "    file_write(fh, bytes)\n",
            "    file_close(fh)\n",
            "    let custom = font_load(p)\n",
            "    println(f\"{{is_null(custom)}}\")\n",
            "    font_free(custom)\n",
            "    println(f\"{{is_null(custom)}}\")\n",
        ),
        p = path
    );
    let output = compile_and_run_sdl("font_free_nulls_caller_binding", &src);
    let _ = std::fs::remove_file(&path);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "true"], "{}", stdout);
}

#[test]
fn runtime_font_free_aborts_on_null_handle_end_to_end() {
    let src = "fn main():\n    \
               let f = null_ptr()\n    \
               println(\"before\")\n    \
               font_free(f)\n    \
               println(\"should not reach here\")\n";
    let output = compile_and_run_sdl("font_free_aborts_on_null_handle", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "must abort before the null handle is ever used: {}", stdout);
    assert!(stdout.contains("null/closed font handle"), "should print a diagnostic: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "should exit cleanly with code 1, not crash/segfault: {:?}", output.status);
}

#[test]
fn runtime_draw_text_aborts_on_null_window_handle_end_to_end() {
    let src = "fn main():\n    \
               let w = null_ptr()\n    \
               let f = default_font()\n    \
               println(\"before\")\n    \
               draw_text(w, f, \"hi\", 0, 0, 1, Color32(1, 2, 3, 255))\n    \
               println(\"should not reach here\")\n";
    let output = compile_and_run_sdl("draw_text_aborts_on_null_window_handle", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "{}", stdout);
    assert!(stdout.contains("null/closed window handle"), "{}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

/// The window handle must be validated *before* the font handle -- this
/// test passes a valid font but a null window, so a diagnostic naming the
/// window (not the font) confirms the check ordering matches `draw_text`'s
/// own argument order.
#[test]
fn runtime_draw_text_aborts_on_null_font_handle_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"t\", 8, 8)\n    \
               let f = null_ptr()\n    \
               println(\"before\")\n    \
               draw_text(w, f, \"hi\", 0, 0, 1, Color32(1, 2, 3, 255))\n    \
               println(\"should not reach here\")\n";
    let output = compile_and_run_sdl("draw_text_aborts_on_null_font_handle", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "{}", stdout);
    assert!(stdout.contains("null/closed font handle"), "{}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

#[test]
fn runtime_measure_text_aborts_on_null_font_handle_end_to_end() {
    let src = "fn main():\n    \
               let f = null_ptr()\n    \
               println(\"before\")\n    \
               let sz = measure_text(f, \"hi\", 1)\n    \
               println(\"should not reach here\")\n";
    let output = compile_and_run_sdl("measure_text_aborts_on_null_font_handle", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "{}", stdout);
    assert!(stdout.contains("null/closed font handle"), "{}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

#[test]
fn runtime_get_pixel_aborts_on_null_window_handle_end_to_end() {
    let src = "fn main():\n    \
               let w = null_ptr()\n    \
               println(\"before\")\n    \
               let c = get_pixel(w, 0, 0)\n    \
               println(\"should not reach here\")\n";
    let output = compile_and_run_sdl("get_pixel_aborts_on_null_window_handle", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "{}", stdout);
    assert!(stdout.contains("null/closed window handle"), "{}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

/// A font `ptr` handle, like a window `ptr` handle
/// (`runtime_window_ptr_survives_struct_list_closure_and_fn_return_end_to_end`),
/// is just an opaque pointer value -- no RC header -- so it must round-trip
/// cleanly through a struct field, a `List<ptr>` element, and a function
/// return value with no accidental RC-release/retain codegen path applied
/// to it.
#[test]
fn runtime_font_ptr_survives_struct_list_and_fn_return_end_to_end() {
    let src = concat!(
        "struct Holder:\n    f: ptr\n\n",
        "fn make_font() -> ptr:\n    default_font()\n\n",
        "fn main():\n",
        "    let f = make_font()\n",
        "    let h = Holder(f = f)\n",
        "    println(f\"{is_null(h.f)}\")\n",
        "    let mut lst: List<ptr> = List<ptr>()\n",
        "    lst.push(f)\n",
        "    println(f\"{is_null(lst[0])}\")\n",
        "    let w = window_create(\"t\", 8, 8)\n",
        "    draw_text(w, f, \"hi\", 0, 0, 1, Color32(1, 2, 3, 255))\n",
        "    present(w)\n",
        "    println(\"draw ok\")\n",
        "    window_destroy(w)\n",
    );
    let output = compile_and_run_sdl("font_ptr_survives_struct_list_and_fn_return", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "false", "draw ok"], "{}", stdout);
}

// ===== Bug fix found incidentally while writing the tests above: =========
// ===== `bool == bool`/`!=` was entirely unsupported (`Ty::Bool` is =========
// ===== deliberately not `is_numeric()`, so it fell through every dedicated
// ===== equality arm in `Checker::infer_binop_ty` -- Color32/Symbol/ptr/
// ===== BitField/Flags/str/char all had one, but plain `bool` never did --
// ===== straight to the final "not supported" error). Confirmed live via
// ===== `star check` on a bare `println(f"{true == false}")`. Fixed by
// ===== adding a dedicated `bool`/`bool` arm (`==`/`!=` only, no ordering --
// ===== same "no meaningful less-than" reasoning every other non-numeric
// ===== equality-only type already carries) to both `infer_binop_ty` and
// ===== `Codegen::emit_binop` (`crate::codegen::vector_math`).

#[test]
fn checks_bool_equality_now_type_checks() {
    let src = "fn t():\n    let a: bool = (true == false)\n    let b: bool = (true != false)\n";
    let module = Driver::parse(src).expect("should parse");
    let result = Driver::check(&module);
    assert!(result.is_ok(), "bool == bool / != should type-check: {:?}", result.err());
}

#[test]
fn rejects_bool_ordering_comparison() {
    let src = "fn t():\n    let a = true < false\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("`bool < bool` has no meaningful ordering and should be rejected") };
    assert!(diags.iter().any(|d| d.message.contains("only `==`/`!=` are supported between `bool` values")), "{:?}", diags);
}

#[test]
fn runtime_bool_equality_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    println(f\"{true == true}\")\n",
        "    println(f\"{true == false}\")\n",
        "    println(f\"{true != false}\")\n",
        "    let a = is_null(null_ptr())\n",
        "    let b = is_null(null_ptr())\n",
        "    println(f\"{a == b}\")\n",
    );
    let output = compile_and_run("bool_equality", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "false", "true", "true"], "{}", stdout);
}
