# SDL2-backed graphics/input builtins (todo.md #4 "Graphics / audio / input
# bindings"): opens a window, bounces a filled square around inside it off
# the walls, and quits on a close request or the Escape key.
#
# Build with SDL2 linked (SDL2.dll must also be next to the built .exe, or on
# PATH, to run):
#   star build examples/graphics.star -L sdl/lib/x64 -l SDL2

fn main():
    let width = 640
    let height = 480
    let size = 40
    let w = window_create("Star: graphics.star", width, height)
    if is_null(w):
        println("window_create failed")
        return

    let mut x = 0
    let mut y = 0
    let mut dx = 4
    let mut dy = 3

    let escape_scancode = 41
    let background = Color32(20, 20, 30, 255)
    let square = Color32(80, 180, 255, 255)

    while true:
        if window_should_close(w):
            break
        if key_down(escape_scancode):
            break

        x += dx
        y += dy
        if x < 0 or x + size > width:
            dx = 0 - dx
        if y < 0 or y + size > height:
            dy = 0 - dy

        clear_screen(w, background)
        draw_rect(w, x, y, size, size, square)
        present(w)
        delay(16)

    window_destroy(w)
