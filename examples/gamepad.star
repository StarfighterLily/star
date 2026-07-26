# SDL2-backed gamepad/joystick input builtins (todo.md #8 "Audio playback
# and gamepad input" -- the gamepad half; see examples/audio.star for the
# other half). Polls the first connected joystick device (if any) and
# prints its button 0 / axis 0 state a few times.
#
# Build with SDL2 linked (SDL2.dll must also be next to the built .exe, or on
# PATH, to run):
#   star build examples/gamepad.star -L sdl/lib/x64 -l SDL2

fn main():
    let n = gamepad_count()
    println(f"connected joystick devices: {n}")
    if n == 0:
        println("no gamepad connected -- nothing further to demo")
        return

    let pad = gamepad_open(0)
    if is_null(pad):
        println("gamepad_open failed")
        return

    let mut i = 0
    while i < 5:
        if not gamepad_attached(pad):
            println("gamepad disconnected")
            break
        let pressed = gamepad_button_down(pad, 0)
        let axis = gamepad_axis(pad, 0)
        println(f"button 0 down={pressed} axis 0={axis}")
        delay(1000)
        i += 1

    gamepad_close(pad)
