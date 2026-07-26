# SDL2-backed audio playback builtins (todo.md #8 "Audio playback and
# gamepad input" -- the audio half; see examples/gamepad.star for the other
# half). Loads a short WAV clip and exercises one-shot sound-effect
# playback, looping "music" playback layered underneath it, and the
# stop-everything builtin.
#
# Build with SDL2 linked (SDL2.dll must also be next to the built .exe, or on
# PATH, to run):
#   star build examples/audio.star -L sdl/lib/x64 -l SDL2

fn main():
    let beep = sound_load("examples/assets/beep.wav")
    if is_null(beep):
        println("sound_load failed")
        return

    println("playing a one-shot sound effect")
    sound_play(beep)
    delay(400)

    println("looping the same clip as background music")
    music_play(beep)
    delay(800)

    println("layering a second one-shot sound effect on top of the music")
    sound_play(beep)
    delay(400)

    music_stop()
    sound_stop_all()
    sound_free(beep)
    println("done")
