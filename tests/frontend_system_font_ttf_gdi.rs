//! Proportional real-glyph text rendering via Windows GDI/TTF
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Proportional, real-glyph-shaped text rendering via Windows GDI ======
// ===== (`todo.md` P2 #9: `font_load_system`/`font_load_ttf`/
// ===== `font_ttf_free`/`draw_text_ttf`/`measure_text_ttf`, see
// ===== `crate::codegen::system_font`) -- the sibling, higher-fidelity
// ===== counterpart to `font_load`/`draw_text`'s hand-authored 5x7
// ===== uppercase-only bitmap font above. Every runtime test here assumes
// ===== the reference dev machine's real, always-present Windows fonts
// ===== ("Segoe UI" and `C:\Windows\Fonts\arial.ttf`) exist, the same
// ===== "single Windows dev machine" assumption this whole project's build
// ===== story already makes (see `readme.md`'s toolchain note). ===========

/// Like `compile_and_run_sdl`, but also links `gdi32` -- every builtin in
/// `crate::codegen::system_font` calls into it, and (unlike libc/kernel32)
/// it isn't part of this target's implicitly-linked default libraries, so
/// omitting `-lgdi32` fails at link time with undefined `CreateFontA`/etc.
/// symbols.
fn compile_and_run_sdl_gdi(name: &str, src: &str) -> std::process::Output {
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let dir = std::env::temp_dir().join(format!("star_test_sdl_{}", name));
    std::fs::create_dir_all(&dir).expect("failed to create test scratch dir");
    let exe = dir.join("test.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");

    let sdl_lib_dir = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("sdl").join("lib").join("x64");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .arg(format!("-L{}", sdl_lib_dir.display()))
        .args(["-lSDL2", "-lgdi32"])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR, linked against SDL2 + gdi32");

    let dll_dest = dir.join("SDL2.dll");
    std::fs::copy(sdl_lib_dir.join("SDL2.dll"), &dll_dest).expect("failed to stage SDL2.dll next to the test binary");

    let output = std::process::Command::new(&exe).env("SDL_VIDEODRIVER", "dummy").output().expect("failed to execute compiled test binary");
    let _ = std::fs::remove_dir_all(&dir);
    output
}

#[test]
fn checks_font_load_system_returns_ptr() {
    let src = "fn t():\n    let w = window_create(\"t\", 8, 8)\n    let f: ptr = font_load_system(w, \"Segoe UI\", 16)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("font_load_system(..) should type-check as ptr");
}

#[test]
fn checker_rejects_font_load_system_wrong_arg_count() {
    let src = "fn t():\n    let w = window_create(\"t\", 8, 8)\n    let f = font_load_system(w, \"Segoe UI\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("font_load_system with 2 arguments should be rejected") };
    assert!(diags.iter().any(|d| d.message.contains("`font_load_system` expects 3 argument")), "{:?}", diags);
}

#[test]
fn checker_rejects_font_load_system_wrong_arg_types() {
    let src = concat!(
        "fn t():\n",
        "    let a = font_load_system(\"not a window\", \"Segoe UI\", 16)\n",
        "    let w = window_create(\"t\", 8, 8)\n",
        "    let b = font_load_system(w, 5, 16)\n",
        "    let c = font_load_system(w, \"Segoe UI\", \"16\")\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("every font_load_system call above has a wrong-typed argument and should be rejected") };
    for expected in [
        "`font_load_system` argument 1 (window) expected `ptr`",
        "`font_load_system` argument 2 (family) expected `str`",
        "`font_load_system` argument 3 (size) expected `int`",
    ] {
        assert!(diags.iter().any(|d| d.message.contains(expected)), "expected {:?}, got: {:?}", expected, diags);
    }
}

#[test]
fn checker_rejects_font_load_ttf_wrong_arg_count() {
    let src = "fn t():\n    let w = window_create(\"t\", 8, 8)\n    let f = font_load_ttf(w, \"x.ttf\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("font_load_ttf with 2 arguments should be rejected") };
    assert!(diags.iter().any(|d| d.message.contains("`font_load_ttf` expects 3 argument")), "{:?}", diags);
}

/// `font_load_ttf`'s second argument is labeled `path` in its own
/// diagnostics, unlike `font_load_system`'s `family` -- both share one
/// checker arm (`types/expr.rs`), so this pins that the shared arm still
/// picks the right label per builtin name.
#[test]
fn checker_rejects_font_load_ttf_wrong_arg_types() {
    let src = concat!(
        "fn t():\n",
        "    let w = window_create(\"t\", 8, 8)\n",
        "    let a = font_load_ttf(w, 5, 16)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("font_load_ttf(w, 5, 16) should be rejected") };
    assert!(diags.iter().any(|d| d.message.contains("`font_load_ttf` argument 2 (path) expected `str`")), "{:?}", diags);
}

#[test]
fn checker_rejects_font_ttf_free_wrong_arg_type() {
    let src = "fn t():\n    font_ttf_free(\"nope\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("font_ttf_free(\"nope\") should be rejected") };
    assert!(diags.iter().any(|d| d.message.contains("`font_ttf_free` expects a `ptr` argument")), "{:?}", diags);
}

#[test]
fn checker_rejects_draw_text_ttf_wrong_arg_count() {
    let src = "fn t():\n    let w = window_create(\"t\", 8, 8)\n    draw_text_ttf(w, w, \"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("draw_text_ttf with 3 args should be rejected") };
    assert!(diags.iter().any(|d| d.message.contains("`draw_text_ttf` expects 6 argument")), "{:?}", diags);
}

#[test]
fn checker_rejects_draw_text_ttf_wrong_arg_types() {
    let src = concat!(
        "fn t():\n",
        "    let w = window_create(\"t\", 8, 8)\n",
        "    draw_text_ttf(1, w, \"hi\", 0, 0, Color32(1, 2, 3, 255))\n",
        "    draw_text_ttf(w, \"not a font\", \"hi\", 0, 0, Color32(1, 2, 3, 255))\n",
        "    draw_text_ttf(w, w, 5, 0, 0, Color32(1, 2, 3, 255))\n",
        "    draw_text_ttf(w, w, \"hi\", \"x\", 0, Color32(1, 2, 3, 255))\n",
        "    draw_text_ttf(w, w, \"hi\", 0, \"y\", Color32(1, 2, 3, 255))\n",
        "    draw_text_ttf(w, w, \"hi\", 0, 0, 5)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("every draw_text_ttf call above has a wrong-typed argument and should be rejected") };
    for expected in [
        "`draw_text_ttf` argument 1 (window) expected `ptr`",
        "`draw_text_ttf` argument 2 (font) expected `ptr`",
        "`draw_text_ttf` argument 3 (text) expected `str`",
        "`draw_text_ttf` argument 4 expected `int`",
        "`draw_text_ttf` argument 5 expected `int`",
        "`draw_text_ttf` argument 6 (color) expected `Color32`",
    ] {
        assert!(diags.iter().any(|d| d.message.contains(expected)), "expected {:?}, got: {:?}", expected, diags);
    }
}

#[test]
fn checker_rejects_measure_text_ttf_wrong_arg_count() {
    let src = "fn t():\n    let w = window_create(\"t\", 8, 8)\n    let sz = measure_text_ttf(w)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("measure_text_ttf with 1 arg should be rejected") };
    assert!(diags.iter().any(|d| d.message.contains("`measure_text_ttf` expects 2 argument")), "{:?}", diags);
}

#[test]
fn checker_rejects_measure_text_ttf_wrong_arg_types() {
    let src = concat!(
        "fn t():\n",
        "    let a = measure_text_ttf(\"not a font\", \"hi\")\n",
        "    let w = window_create(\"t\", 8, 8)\n",
        "    let b = measure_text_ttf(w, 5)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("every measure_text_ttf call above has a wrong-typed argument and should be rejected") };
    assert!(diags.iter().any(|d| d.message.contains("`measure_text_ttf` argument 1 (font) expected `ptr`")), "{:?}", diags);
    assert!(diags.iter().any(|d| d.message.contains("`measure_text_ttf` argument 2 (text) expected `str`")), "{:?}", diags);
}

/// `font_load_system`/`font_load_ttf`/`font_ttf_free`/`draw_text_ttf` all
/// touch the shared `SDL_Renderer*` (rasterizing into it or drawing/
/// destroying a texture against it), so all four must join the same
/// `par`/`swarm` ban list `draw_text`/`get_pixel` are already in -- a
/// regression guard that the ban list was actually extended for this
/// module too, not just the bitmap-font one.
#[test]
fn rejects_system_font_builtins_that_touch_the_renderer_inside_par_body() {
    let src = concat!(
        "struct Entity:\n    mut idx: i32\n\n",
        "arena Entities: Entity\n\n",
        "fn main():\n",
        "    let w = window_create(\"race\", 64, 48)\n",
        "    par e in Entities:\n",
        "        let f = font_load_system(w, \"Segoe UI\", e.idx)\n",
        "        let g = font_load_ttf(w, \"x.ttf\", e.idx)\n",
        "        draw_text_ttf(w, f, \"x\", e.idx, e.idx, Color32(1, 2, 3, 255))\n",
        "        font_ttf_free(f)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else {
        panic!("font_load_system/font_load_ttf/draw_text_ttf/font_ttf_free on a captured window handle inside a par/swarm body should be rejected")
    };
    for name in ["font_load_system", "font_load_ttf", "draw_text_ttf", "font_ttf_free"] {
        assert!(
            diags.iter().any(|d| d.message.contains(&format!("cannot call `{}`", name)) && d.message.contains("shared window/renderer")),
            "expected a rejection for `{}`, got: {:?}",
            name,
            diags
        );
    }
}

/// Sibling positive test: `measure_text_ttf` only reads a font handle's own
/// already-rasterized metrics table, no SDL call at all -- it must stay
/// usable inside a `par`/`swarm` body, exactly like `measure_text`.
#[test]
fn accepts_measure_text_ttf_inside_par_body() {
    let src = concat!(
        "struct Entity:\n    mut idx: i32\n\n",
        "arena Entities: Entity\n\n",
        "fn main():\n",
        "    let w = window_create(\"t\", 8, 8)\n",
        "    let f = font_load_system(w, \"Segoe UI\", 16)\n",
        "    par e in Entities:\n",
        "        let sz = measure_text_ttf(f, \"x\")\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let result = Driver::check(&module);
    assert!(result.is_ok(), "measure_text_ttf inside a par/swarm body should still be allowed: {:?}", result.err());
}

/// Codegen-shape regression guard: `font_load_system` really does drive
/// GDI's `CreateFontA` and rasterize into a real `SDL_CreateTexture`
/// (not, say, silently falling back to some other path), and
/// `draw_text_ttf` really does blit through `SDL_RenderCopy` -- cheap to
/// check on the generated IR text directly, without a real GDI/SDL round
/// trip.
#[test]
fn codegen_font_load_system_and_draw_text_ttf_emit_expected_calls() {
    let src = concat!(
        "fn main():\n",
        "    let w = window_create(\"t\", 8, 8)\n",
        "    let f = font_load_system(w, \"Segoe UI\", 16)\n",
        "    draw_text_ttf(w, f, \"hi\", 0, 0, Color32(1, 2, 3, 255))\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("call i8* @CreateFontA("), "{}", ir);
    assert!(ir.contains("call i8* @SDL_CreateTexture("), "{}", ir);
    assert!(ir.contains("call i32 @SDL_RenderCopy("), "{}", ir);
}

/// `font_load_system` loads a real, always-installed system font by family
/// name, rasterizes it into a real atlas texture, and `draw_text_ttf`
/// actually lights up pixels drawing with it -- read back with `get_pixel`
/// over the whole measured text region (not one hand-picked coordinate,
/// which could land in a real glyph's own counter/gap and look like a
/// false failure) and counting how many differ from the background. A
/// hand-authored bitmap glyph's expected shape is checked pixel-by-pixel
/// elsewhere (`runtime_font_load_custom_glyph_round_trip_renders_expected_
/// pixels_end_to_end`); a real system font's antialiased glyph shapes have
/// no such fixed pixel-perfect expectation to pin, so this only asserts
/// real coverage exists, not its exact shape.
#[test]
fn runtime_font_load_system_draws_real_text_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let w = window_create(\"t\", 200, 60)\n",
        "    let f = font_load_system(w, \"Segoe UI\", 24)\n",
        "    println(f\"{is_null(f)}\")\n",
        "    let sz = measure_text_ttf(f, \"Hi\")\n",
        "    println(f\"{sz.0 > 0}\")\n",
        "    println(f\"{sz.1 > 0}\")\n",
        "    clear_screen(w, Color32(0, 0, 0, 255))\n",
        "    draw_text_ttf(w, f, \"Hi\", 10, 10, Color32(255, 255, 255, 255))\n",
        "    present(w)\n",
        "    let mut lit = 0\n",
        "    let mut y = 10\n",
        "    while y < 10 + sz.1:\n",
        "        let mut x = 10\n",
        "        while x < 10 + sz.0:\n",
        "            let px = get_pixel(w, x, y)\n",
        "            if color32_r(px) > 10:\n",
        "                lit += 1\n",
        "            x += 1\n",
        "        y += 1\n",
        "    println(f\"{lit > 0}\")\n",
        "    font_ttf_free(f)\n",
    );
    let output = compile_and_run_sdl_gdi("font_load_system_draws_real_text", src);
    assert!(output.status.success(), "{:?} stderr={}", output.status, String::from_utf8_lossy(&output.stderr));
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "true", "true", "true"], "{}", stdout);
}

/// `font_load_ttf` loads a real bundled `.ttf` file (here, the reference
/// machine's own `arial.ttf` -- standing in for a game shipping its own
/// font file, which is the actual point of this loader over `font_load_
/// system`) by privately registering it and hand-parsing its `sfnt`
/// `name` table for a usable family name, then rasterizes exactly like
/// `font_load_system`.
#[test]
fn runtime_font_load_ttf_loads_real_file_and_draws_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let w = window_create(\"t\", 200, 60)\n",
        "    let f = font_load_ttf(w, \"C:\\\\Windows\\\\Fonts\\\\arial.ttf\", 20)\n",
        "    println(f\"{is_null(f)}\")\n",
        "    let sz = measure_text_ttf(f, \"Hi\")\n",
        "    println(f\"{sz.0 > 0}\")\n",
        "    font_ttf_free(f)\n",
    );
    let output = compile_and_run_sdl_gdi("font_load_ttf_loads_real_file_and_draws", src);
    assert!(output.status.success(), "{:?} stderr={}", output.status, String::from_utf8_lossy(&output.stderr));
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "true"], "{}", stdout);
}

#[test]
fn runtime_font_load_ttf_missing_file_returns_null_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let w = window_create(\"t\", 8, 8)\n",
        "    let f = font_load_ttf(w, \"this_font_does_not_exist_star_test.ttf\", 16)\n",
        "    println(f\"{is_null(f)}\")\n",
    );
    let output = compile_and_run_sdl_gdi("font_load_ttf_missing_file_returns_null", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "true");
}

/// A file that opens fine but isn't a recognizable `sfnt` font (too short
/// for even the 12-byte header) must be rejected, not read past its own
/// end -- mirrors `runtime_font_load_truncated_header_returns_null_end_to_
/// end`'s identical guard for the bitmap-font loader.
#[test]
fn runtime_font_load_ttf_truncated_file_returns_null_end_to_end() {
    let path = scratch_file_path("star_test_font_load_ttf_truncated.ttf");
    let src = format!(
        concat!(
            "fn main():\n",
            "    let p = \"{p}\"\n",
            "    let fh = file_open(p, \"wb\")\n",
            "    file_write(fh, \"abcdef\")\n",
            "    file_close(fh)\n",
            "    let w = window_create(\"t\", 8, 8)\n",
            "    let f = font_load_ttf(w, p, 16)\n",
            "    println(f\"{{is_null(f)}}\")\n",
        ),
        p = path
    );
    let output = compile_and_run_sdl_gdi("font_load_ttf_truncated_file_returns_null", &src);
    let _ = std::fs::remove_file(&path);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "true");
}

#[test]
fn runtime_font_ttf_free_nulls_caller_binding_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let w = window_create(\"t\", 8, 8)\n",
        "    let mut f = font_load_system(w, \"Segoe UI\", 16)\n",
        "    println(f\"{is_null(f)}\")\n",
        "    font_ttf_free(f)\n",
        "    println(f\"{is_null(f)}\")\n",
    );
    let output = compile_and_run_sdl_gdi("font_ttf_free_nulls_caller_binding", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "true"], "{}", stdout);
}

#[test]
fn runtime_font_ttf_free_aborts_on_null_handle_end_to_end() {
    let src = "fn main():\n    \
               let f = null_ptr()\n    \
               println(\"before\")\n    \
               font_ttf_free(f)\n    \
               println(\"should not reach here\")\n";
    let output = compile_and_run_sdl_gdi("font_ttf_free_aborts_on_null_handle", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "must abort before the null handle is ever used: {}", stdout);
    assert!(stdout.contains("null/freed system-font handle"), "should print a diagnostic: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "should exit cleanly with code 1, not crash/segfault: {:?}", output.status);
}

#[test]
fn runtime_draw_text_ttf_aborts_on_null_window_handle_end_to_end() {
    let src = "fn main():\n    \
               let w = null_ptr()\n    \
               let real_w = window_create(\"t\", 8, 8)\n    \
               let f = font_load_system(real_w, \"Segoe UI\", 16)\n    \
               println(\"before\")\n    \
               draw_text_ttf(w, f, \"hi\", 0, 0, Color32(1, 2, 3, 255))\n    \
               println(\"should not reach here\")\n";
    let output = compile_and_run_sdl_gdi("draw_text_ttf_aborts_on_null_window_handle", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "{}", stdout);
    assert!(stdout.contains("null/closed window handle"), "{}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

#[test]
fn runtime_draw_text_ttf_aborts_on_null_font_handle_end_to_end() {
    let src = "fn main():\n    \
               let w = window_create(\"t\", 8, 8)\n    \
               let f = null_ptr()\n    \
               println(\"before\")\n    \
               draw_text_ttf(w, f, \"hi\", 0, 0, Color32(1, 2, 3, 255))\n    \
               println(\"should not reach here\")\n";
    let output = compile_and_run_sdl_gdi("draw_text_ttf_aborts_on_null_font_handle", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "{}", stdout);
    assert!(stdout.contains("null/freed system-font handle"), "{}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

#[test]
fn runtime_measure_text_ttf_aborts_on_null_font_handle_end_to_end() {
    let src = "fn main():\n    \
               let f = null_ptr()\n    \
               println(\"before\")\n    \
               let sz = measure_text_ttf(f, \"hi\")\n    \
               println(\"should not reach here\")\n";
    let output = compile_and_run_sdl_gdi("measure_text_ttf_aborts_on_null_font_handle", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "{}", stdout);
    assert!(stdout.contains("null/freed system-font handle"), "{}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

/// `\n` is a line break in `measure_text_ttf`, exactly like `measure_text`:
/// two lines of the same text should measure roughly twice as tall as one
/// line (not exactly double -- real font line-height math -- but strictly
/// more than 1.5x, which a single-line reading of a two-line string could
/// never produce).
#[test]
fn runtime_measure_text_ttf_newline_increases_height_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let w = window_create(\"t\", 8, 8)\n",
        "    let f = font_load_system(w, \"Segoe UI\", 16)\n",
        "    let one = measure_text_ttf(f, \"Hi\")\n",
        "    let two = measure_text_ttf(f, \"Hi\\nHi\")\n",
        "    println(f\"{two.1 * 2 > one.1 * 3}\")\n",
    );
    let output = compile_and_run_sdl_gdi("measure_text_ttf_newline_increases_height", src);
    assert!(output.status.success(), "{:?} stderr={}", output.status, String::from_utf8_lossy(&output.stderr));
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "true");
}

/// A codepoint outside the atlas's covered range (here, `chr(1)`, well
/// below the printable-ASCII floor `FIRST_CHAR`) draws as nothing but still
/// advances the cursor by the space glyph's own width -- exactly the same
/// width a real space character measures, confirmed by comparing the two
/// directly rather than asserting some other specific pixel width.
#[test]
fn runtime_measure_text_ttf_out_of_range_codepoint_advances_like_space_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let w = window_create(\"t\", 8, 8)\n",
        "    let f = font_load_system(w, \"Segoe UI\", 16)\n",
        "    let space = measure_text_ttf(f, \" \")\n",
        "    let unsupported = measure_text_ttf(f, chr(1))\n",
        "    println(f\"{space.0 == unsupported.0}\")\n",
    );
    let output = compile_and_run_sdl_gdi("measure_text_ttf_out_of_range_codepoint_advances_like_space", src);
    assert!(output.status.success(), "{:?} stderr={}", output.status, String::from_utf8_lossy(&output.stderr));
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "true");
}
