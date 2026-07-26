# Proportional, real-glyph-shaped text rendering via Windows GDI (todo.md
# P2 #9): font_load_system loads an already-installed system font by family
# name; font_load_ttf loads a bundled .ttf/.otf file so a game's text keeps
# a consistent look regardless of what's installed on the player's machine.
# Both rasterize into a real SDL texture and draw through draw_text_ttf/
# measure_text_ttf -- unlike the fixed-width, uppercase-only default_font()
# bitmap font (see graphics.star), this gets real proportional lower/upper
# case glyph shapes with antialiasing straight from the OS's own font engine.
#
# Build with SDL2 + gdi32 linked (SDL2.dll must also be next to the built
# .exe, or on PATH, to run):
#   star build examples/system_fonts.star -L sdl/lib/x64 -l SDL2 -l gdi32

fn main():
    let w = window_create("Star: system_fonts.star", 640, 480)
    if is_null(w):
        println("window_create failed")
        return

    let title_font = font_load_system(w, "Segoe UI", 32)
    let body_font = font_load_system(w, "Segoe UI", 18)
    if is_null(title_font) or is_null(body_font):
        println("font_load_system failed")
        window_destroy(w)
        return

    # A bundled .ttf file works the same way, just loaded by path instead
    # of an installed family name -- try it if arial.ttf is present, but
    # don't treat its absence as a hard failure.
    let bundled = font_load_ttf(w, "C:\\Windows\\Fonts\\arial.ttf", 18)

    let background = Color32(18, 18, 26, 255)
    let title = Color32(255, 255, 255, 255)
    let body = Color32(190, 190, 200, 255)

    let escape_scancode = 41

    while true:
        if window_should_close(w):
            break
        if key_down(escape_scancode):
            break

        clear_screen(w, background)

        draw_text_ttf(w, title_font, "Star Engine", 24, 24, title)

        let msg = "Proportional text, real lowercase glyphs,\nantialiased edges -- straight from GDI."
        draw_text_ttf(w, body_font, msg, 24, 80, body)

        let sz = measure_text_ttf(body_font, "Centered caption")
        draw_text_ttf(w, body_font, "Centered caption", (640 - sz.0) / 2, 400, body)

        if !is_null(bundled):
            draw_text_ttf(w, bundled, "Loaded from a bundled .ttf file", 24, 130, body)

        present(w)
        delay(16)

    if !is_null(bundled):
        font_ttf_free(bundled)
    font_ttf_free(body_font)
    font_ttf_free(title_font)
    window_destroy(w)
