//! Audio playback / gamepad input
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Audio playback / gamepad input (`todo.md` #8 "Audio playback and ===
// ===== gamepad input"): `sound_load`/`sound_free`/`sound_play`/          ===
// ===== `music_play`/`music_stop`/`sound_stop_all` (`crate::codegen::audio`) =
// ===== and `gamepad_count`/`gamepad_open`/`gamepad_close`/                ===
// ===== `gamepad_button_down`/`gamepad_axis`/`gamepad_attached`            ===
// ===== (`crate::codegen::gamepad`). ========================================

/// Absolute path (forward-slashed, so it drops cleanly into a Star string
/// literal with no backslash-escaping) to the committed short WAV clip
/// (`examples/assets/beep.wav`: 0.25s, 44100Hz, stereo, 16-bit PCM, the
/// canonical shape `sound_load` accepts) used by every "real file" audio
/// test below.
fn beep_wav_path() -> String {
    std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("examples")
        .join("assets")
        .join("beep.wav")
        .to_string_lossy()
        .replace('\\', "/")
}

/// Hand-build a canonical 44-byte-header PCM WAV file's bytes with
/// arbitrary format fields -- lets tests probe `sound_load`'s validation
/// (wrong sample rate/bit depth/channel count) without needing a whole
/// zoo of committed asset files, mirroring this module's own hand-rolled
/// WAV parser (`crate::codegen::audio::emit_sound_load`) byte-for-byte.
fn build_wav_bytes(sample_rate: u32, channels: u16, bits_per_sample: u16, num_frames: u32) -> Vec<u8> {
    let block_align = channels as u32 * (bits_per_sample as u32 / 8);
    let data_size = num_frames * block_align;
    let byte_rate = sample_rate * block_align;
    let mut buf = Vec::new();
    buf.extend_from_slice(b"RIFF");
    buf.extend_from_slice(&(36 + data_size).to_le_bytes());
    buf.extend_from_slice(b"WAVE");
    buf.extend_from_slice(b"fmt ");
    buf.extend_from_slice(&16u32.to_le_bytes());
    buf.extend_from_slice(&1u16.to_le_bytes()); // PCM
    buf.extend_from_slice(&channels.to_le_bytes());
    buf.extend_from_slice(&sample_rate.to_le_bytes());
    buf.extend_from_slice(&byte_rate.to_le_bytes());
    buf.extend_from_slice(&(block_align as u16).to_le_bytes());
    buf.extend_from_slice(&bits_per_sample.to_le_bytes());
    buf.extend_from_slice(b"data");
    buf.extend_from_slice(&data_size.to_le_bytes());
    buf.resize(buf.len() + data_size as usize, 0);
    buf
}

/// Write `bytes` to a fresh file under a unique scratch directory (so
/// concurrently-running tests never collide on the same path), returning
/// its forward-slashed path. The caller is responsible for nothing further
/// -- these are one-shot per-test scratch files in the OS temp dir, never
/// cleaned up individually, matching this file's existing scratch-file
/// tests (e.g. `file_open`'s own temp-path helpers).
fn write_scratch_file(name: &str, bytes: &[u8]) -> String {
    let dir = std::env::temp_dir().join("star_test_audio_assets");
    std::fs::create_dir_all(&dir).expect("failed to create scratch dir");
    let path = dir.join(name);
    std::fs::write(&path, bytes).expect("failed to write scratch file");
    path.to_string_lossy().replace('\\', "/")
}

// --- checker: return types / arity / argument types ------------------------

#[test]
fn checks_sound_load_returns_ptr() {
    let src = "fn t():\n    let s: ptr = sound_load(\"x.wav\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("sound_load(..) should type-check as ptr");
}

#[test]
fn checker_rejects_sound_load_wrong_arg_count() {
    let src = "fn t():\n    sound_load()\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("sound_load with 0 arguments should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`sound_load` expects 1 argument")), "{:?}", diags);
}

#[test]
fn checker_rejects_sound_load_wrong_arg_type() {
    let src = "fn t():\n    sound_load(1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("sound_load(int) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`sound_load` expects a `str` argument")), "{:?}", diags);
}

/// `sound_free`/`sound_play`/`music_play` all take a bare `ptr` and return
/// no useful value.
#[test]
fn checks_sound_free_play_music_play_take_ptr_and_return_no_value() {
    let src = "fn t():\n    \
               let s = sound_load(\"x.wav\")\n    \
               sound_play(s)\n    \
               music_play(s)\n    \
               sound_free(s)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("sound_free/sound_play/music_play should type-check");
}

#[test]
fn checker_rejects_sound_free_play_music_play_wrong_arg_type() {
    for (name, call) in [("sound_free", "sound_free(1)"), ("sound_play", "sound_play(1)"), ("music_play", "music_play(1)")] {
        let src = format!("fn t():\n    {}\n", call);
        let module = Driver::parse(&src).expect("should parse");
        let Err(diags) = Driver::check(&module) else { panic!("{}(int) should fail to type-check", name) };
        assert!(
            diags.iter().any(|d| d.message.contains(&format!("`{}` expects a `ptr` argument", name))),
            "expected a ptr-argument diagnostic for `{}`, got: {:?}",
            name,
            diags
        );
    }
}

#[test]
fn checker_rejects_music_stop_sound_stop_all_gamepad_count_wrong_arg_count() {
    for (name, call) in [
        ("music_stop", "music_stop(1)"),
        ("sound_stop_all", "sound_stop_all(1)"),
        ("gamepad_count", "gamepad_count(1)"),
    ] {
        let src = format!("fn t():\n    {}\n", call);
        let module = Driver::parse(&src).expect("should parse");
        let Err(diags) = Driver::check(&module) else { panic!("{} with an argument should fail to type-check", name) };
        assert!(
            diags.iter().any(|d| d.message.contains(&format!("`{}` expects 0 argument(s)", name))),
            "expected a 0-argument diagnostic for `{}`, got: {:?}",
            name,
            diags
        );
    }
}

#[test]
fn checks_music_stop_sound_stop_all_gamepad_count_zero_arity_type_check() {
    let src = "fn t():\n    \
               music_stop()\n    \
               sound_stop_all()\n    \
               let n: int = gamepad_count()\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("music_stop()/sound_stop_all()/gamepad_count() should type-check");
}

#[test]
fn checks_gamepad_open_takes_int_returns_ptr() {
    let src = "fn t():\n    let pad: ptr = gamepad_open(0)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("gamepad_open(int) should type-check as ptr");
}

#[test]
fn checker_rejects_gamepad_open_wrong_arg_type() {
    let src = "fn t():\n    gamepad_open(\"0\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("gamepad_open(str) should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`gamepad_open` expects an `int` argument")), "{:?}", diags);
}

#[test]
fn checks_gamepad_close_and_attached_take_ptr() {
    let src = "fn t():\n    \
               let pad = gamepad_open(0)\n    \
               let a: bool = gamepad_attached(pad)\n    \
               gamepad_close(pad)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("gamepad_close/gamepad_attached should type-check");
}

#[test]
fn checker_rejects_gamepad_close_and_attached_wrong_arg_type() {
    for (name, call) in [("gamepad_close", "gamepad_close(1)"), ("gamepad_attached", "gamepad_attached(1)")] {
        let src = format!("fn t():\n    {}\n", call);
        let module = Driver::parse(&src).expect("should parse");
        let Err(diags) = Driver::check(&module) else { panic!("{}(int) should fail to type-check", name) };
        assert!(
            diags.iter().any(|d| d.message.contains(&format!("`{}` expects a `ptr` argument", name))),
            "expected a ptr-argument diagnostic for `{}`, got: {:?}",
            name,
            diags
        );
    }
}

#[test]
fn checks_gamepad_button_down_and_axis_arg_types_and_return() {
    let src = "fn t():\n    \
               let pad = gamepad_open(0)\n    \
               let pressed: bool = gamepad_button_down(pad, 0)\n    \
               let axis: int = gamepad_axis(pad, 0)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("gamepad_button_down/gamepad_axis should type-check");
}

#[test]
fn checker_rejects_gamepad_button_down_and_axis_wrong_arg_count() {
    for (name, call) in [("gamepad_button_down", "gamepad_button_down(gamepad_open(0))"), ("gamepad_axis", "gamepad_axis(gamepad_open(0))")] {
        let src = format!("fn t():\n    {}\n", call);
        let module = Driver::parse(&src).expect("should parse");
        let Err(diags) = Driver::check(&module) else { panic!("{} with 1 argument should fail to type-check", name) };
        assert!(diags.iter().any(|d| d.message.contains(&format!("`{}` expects 2 argument(s)", name))), "{:?}", diags);
    }
}

#[test]
fn checker_rejects_gamepad_button_down_and_axis_wrong_arg_types() {
    for (name, call) in [
        ("gamepad_button_down", "gamepad_button_down(1, \"0\")"),
        ("gamepad_axis", "gamepad_axis(1, \"0\")"),
    ] {
        let src = format!("fn t():\n    {}\n", call);
        let module = Driver::parse(&src).expect("should parse");
        let Err(diags) = Driver::check(&module) else { panic!("{}(int, str) should fail to type-check", name) };
        assert!(diags.iter().any(|d| d.message.contains(&format!("`{}` argument 1 expected `ptr`", name))), "{:?}", diags);
        assert!(diags.iter().any(|d| d.message.contains(&format!("`{}` argument 2 expected `int`", name))), "{:?}", diags);
    }
}

// --- par/swarm ban list -----------------------------------------------------

/// `sound_play`/`music_play`/`music_stop`/`sound_stop_all`/`sound_free` all
/// mutate (or, for `sound_free`, conditionally scan-and-mutate) the shared,
/// unlocked global channel table (`crate::codegen::audio`), so they must
/// join `is_banned_sdl_builtin_in_par`'s ban list -- a regression guard
/// mirroring `rejects_draw_text_and_get_pixel_inside_par_body`'s own shape.
#[test]
fn rejects_audio_playback_calls_inside_par_body() {
    let src = concat!(
        "struct Entity:\n    mut idx: i32\n\n",
        "arena Entities: Entity\n\n",
        "fn main():\n",
        "    let s = sound_load(\"x.wav\")\n",
        "    par e in Entities:\n",
        "        sound_play(s)\n",
        "        music_play(s)\n",
        "        music_stop()\n",
        "        sound_stop_all()\n",
        "        sound_free(s)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else {
        panic!("sound_play/music_play/music_stop/sound_stop_all/sound_free inside a par/swarm body should be rejected")
    };
    for name in ["sound_play", "music_play", "music_stop", "sound_stop_all", "sound_free"] {
        assert!(
            diags.iter().any(|d| d.message.contains(&format!("cannot call `{}`", name))),
            "expected a rejection for `{}`, got: {:?}",
            name,
            diags
        );
    }
}

/// Sibling covering the gamepad half: `gamepad_count`/`gamepad_open`/
/// `gamepad_close` (shared SDL joystick-subsystem state) and
/// `gamepad_button_down`/`gamepad_axis`/`gamepad_attached` (`SDL_JoystickUpdate`,
/// a global input-state pump, plus a specific joystick's own shared state).
#[test]
fn rejects_gamepad_calls_inside_par_body() {
    let src = concat!(
        "struct Entity:\n    mut idx: i32\n\n",
        "arena Entities: Entity\n\n",
        "fn main():\n",
        "    let pad = gamepad_open(0)\n",
        "    par e in Entities:\n",
        "        let n = gamepad_count()\n",
        "        let p2 = gamepad_open(e.idx)\n",
        "        let pressed = gamepad_button_down(pad, e.idx)\n",
        "        let axis = gamepad_axis(pad, e.idx)\n",
        "        let a = gamepad_attached(pad)\n",
        "        gamepad_close(pad)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else {
        panic!("gamepad_count/gamepad_open/gamepad_close/gamepad_button_down/gamepad_axis/gamepad_attached inside a par/swarm body should be rejected")
    };
    for name in ["gamepad_count", "gamepad_open", "gamepad_close", "gamepad_button_down", "gamepad_axis", "gamepad_attached"] {
        assert!(
            diags.iter().any(|d| d.message.contains(&format!("cannot call `{}`", name))),
            "expected a rejection for `{}`, got: {:?}",
            name,
            diags
        );
    }
}

/// Sibling positive test: `sound_load` touches no shared state (its own
/// independently `malloc`'d buffer only), so -- like `font_load` -- it must
/// stay usable inside a `par`/`swarm` body. Guards against overcorrecting
/// the ban list.
#[test]
fn accepts_sound_load_inside_par_body() {
    let src = concat!(
        "struct Entity:\n    mut idx: i32\n\n",
        "arena Entities: Entity\n\n",
        "fn main():\n",
        "    par e in Entities:\n",
        "        let s = sound_load(\"x.wav\")\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let result = Driver::check(&module);
    assert!(result.is_ok(), "sound_load should stay usable inside a par/swarm body: {:?}", result.err());
}

// --- codegen shape -----------------------------------------------------------

/// `sound_load` never emits a call to any SDL function -- the whole WAV
/// parse is hand-rolled over `fopen`/`fread` (mirroring `font_load`, see
/// `crate::codegen::audio`'s own doc comment), so linking a program that
/// only calls `sound_load` shouldn't require SDL2 at all.
#[test]
fn codegen_sound_load_never_calls_sdl() {
    let src = "fn t():\n    let s = sound_load(\"x.wav\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("@fopen"), "sound_load should read the file via fopen: {}", ir);
    assert!(ir.contains("@fread"), "sound_load should read the file via fread: {}", ir);
    // SDL functions are unconditionally `declare`d in every module regardless
    // of use (see `Codegen::emit_builtins`), so the right check is that no
    // *call* actually invokes one, not that "@SDL_" never appears at all.
    let calls_sdl = ir.lines().any(|l| l.contains("call") && l.contains("@SDL_"));
    assert!(!calls_sdl, "sound_load should never call into SDL: {}", ir);
}

/// `sound_play`/`music_play` reference the shared mixer's channel-table
/// globals and pull in the one-time `@star.audio.mix_callback`/
/// `SDL_OpenAudioDevice` machinery (`ensure_audio_pool_emitted`/
/// `ensure_audio_device`).
#[test]
fn codegen_sound_play_emits_channel_table_and_mixer_machinery() {
    let src = "fn t():\n    \
               let s = sound_load(\"x.wav\")\n    \
               sound_play(s)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("@star.audio.chan_playing"), "{}", ir);
    assert!(ir.contains("@star.audio.chan_base"), "{}", ir);
    assert!(ir.contains("define void @star.audio.mix_callback"), "{}", ir);
    assert!(ir.contains("@SDL_OpenAudioDevice"), "{}", ir);
    assert!(ir.contains("@SDL_MixAudioFormat"), "{}", ir);
}

/// `music_play` always targets channel index `0` and sets the loop flag
/// (`1`), unlike `sound_play`'s scanned free-slot index -- confirms the two
/// builtins actually diverge in the way this module's doc comment claims.
#[test]
fn codegen_music_play_targets_channel_zero_with_loop_flag_set() {
    let src = "fn t():\n    \
               let s = sound_load(\"x.wav\")\n    \
               music_play(s)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(
        ir.contains("@star.audio.chan_loop, i32 0, i32 0"),
        "music_play should index the loop-flag array at the literal channel 0: {}",
        ir
    );
    assert!(ir.contains("store i8 1,"), "music_play should set the loop flag to 1: {}", ir);
}

/// `music_stop`/`sound_stop_all` reference the channel table but need
/// neither a live handle nor the output device -- confirming they don't
/// pull in `SDL_OpenAudioDevice` at all.
#[test]
fn codegen_music_stop_and_sound_stop_all_touch_channel_table_only() {
    let src = "fn t():\n    \
               music_stop()\n    \
               sound_stop_all()\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("@star.audio.chan_playing"), "{}", ir);
    // `@SDL_OpenAudioDevice` is unconditionally `declare`d in every module
    // regardless of use (see `Codegen::emit_builtins`), so the right check
    // is that nothing actually *calls* it, not that the text never appears.
    let calls_open_device = ir.lines().any(|l| l.contains("call") && l.contains("@SDL_OpenAudioDevice"));
    assert!(!calls_open_device, "music_stop/sound_stop_all shouldn't need the output device: {}", ir);
}

/// The mixer's one-time static machinery is emitted exactly once even
/// though several call sites reference it -- `ensure_audio_pool_emitted`'s
/// whole point (mirroring `par_pool_emitted`'s own guard).
#[test]
fn codegen_audio_pool_machinery_emitted_exactly_once() {
    let src = "fn t():\n    \
               let s = sound_load(\"x.wav\")\n    \
               sound_play(s)\n    \
               music_play(s)\n    \
               music_stop()\n    \
               sound_stop_all()\n    \
               sound_free(s)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let occurrences = ir.matches("define void @star.audio.mix_callback").count();
    assert_eq!(occurrences, 1, "mixer callback should be emitted exactly once regardless of call count: {}", ir);
    let global_occurrences = ir.matches("@star.audio.chan_playing = global").count();
    assert_eq!(global_occurrences, 1, "channel table globals should be emitted exactly once: {}", ir);
}

/// `gamepad_button_down`/`gamepad_axis` both pump fresh state via
/// `SDL_JoystickUpdate` before reading -- see `crate::codegen::gamepad`'s
/// own doc comment on why a gamepad-only program can't rely on
/// `window_should_close`'s event-queue drain instead.
#[test]
fn codegen_gamepad_button_down_and_axis_call_joystick_update_first() {
    let src = "fn t():\n    \
               let pad = gamepad_open(0)\n    \
               let pressed = gamepad_button_down(pad, 0)\n    \
               let axis = gamepad_axis(pad, 0)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("call void @SDL_JoystickUpdate()"), "{}", ir);
    assert!(ir.contains("call i8 @SDL_JoystickGetButton"), "{}", ir);
    assert!(ir.contains("call i16 @SDL_JoystickGetAxis"), "{}", ir);
    assert!(ir.contains("sext i16"), "gamepad_axis should sign-extend SDL's Sint16 to this compiler's i32: {}", ir);
}

/// `gamepad_count`/`gamepad_open` both initialize the joystick subsystem
/// (`SDL_INIT_JOYSTICK = 0x200 = 512`) every call, mirroring
/// `window_create`'s own "called every time, ref-counted by SDL" `SDL_Init`
/// convention.
#[test]
fn codegen_gamepad_count_and_open_init_joystick_subsystem() {
    let src = "fn t():\n    \
               let n = gamepad_count()\n    \
               let pad = gamepad_open(0)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert_eq!(ir.matches("call i32 @SDL_Init(i32 512)").count(), 2, "both gamepad_count and gamepad_open should init SDL_INIT_JOYSTICK: {}", ir);
    assert!(ir.contains("call i32 @SDL_NumJoysticks()"), "{}", ir);
    assert!(ir.contains("call i8* @SDL_JoystickOpen"), "{}", ir);
}

// --- runtime end-to-end (real SDL, headless `dummy` drivers) ----------------

/// `sound_load` on a real, valid canonical WAV file returns a non-null
/// handle, and `sound_free` tears it down with no crash -- the basic
/// lifecycle the rest of this surface builds on.
#[test]
fn runtime_sound_load_valid_wav_then_free_end_to_end() {
    let path = beep_wav_path();
    let src = format!(
        "fn main():\n    \
         let s = sound_load(\"{}\")\n    \
         println(f\"{{is_null(s)}}\")\n    \
         sound_free(s)\n    \
         println(\"freed\")\n",
        path
    );
    let output = compile_and_run_sdl_audio("sound_load_valid_then_free", &src);
    assert!(output.status.success(), "{:?} stderr={}", output.status, String::from_utf8_lossy(&output.stderr));
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "freed"], "{}", stdout);
}

/// `sound_load` on a nonexistent path returns `null`, same convention as
/// `file_open`/`window_create`.
#[test]
fn runtime_sound_load_missing_file_returns_null_end_to_end() {
    let src = "fn main():\n    \
               let s = sound_load(\"this/file/does/not/exist.wav\")\n    \
               println(f\"{is_null(s)}\")\n";
    let output = compile_and_run_sdl_audio("sound_load_missing_file", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "true", "{}", stdout);
}

/// `sound_load` rejects every non-canonical WAV shape it's documented to
/// reject: wrong sample rate, wrong bit depth, wrong channel count, and a
/// too-short (truncated header) file -- each independently, none silently
/// accepted or misread.
#[test]
fn runtime_sound_load_rejects_non_canonical_wav_shapes_end_to_end() {
    let wrong_rate = write_scratch_file("wrong_rate.wav", &build_wav_bytes(22050, 2, 16, 100));
    let wrong_bits = write_scratch_file("wrong_bits.wav", &build_wav_bytes(44100, 2, 8, 100));
    let wrong_channels = write_scratch_file("wrong_channels.wav", &build_wav_bytes(44100, 1, 16, 100));
    let too_short = write_scratch_file("too_short.wav", &build_wav_bytes(44100, 2, 16, 100)[..20]);

    let src = format!(
        "fn main():\n    \
         let a = sound_load(\"{}\")\n    \
         let b = sound_load(\"{}\")\n    \
         let c = sound_load(\"{}\")\n    \
         let d = sound_load(\"{}\")\n    \
         println(f\"{{is_null(a)}}\")\n    \
         println(f\"{{is_null(b)}}\")\n    \
         println(f\"{{is_null(c)}}\")\n    \
         println(f\"{{is_null(d)}}\")\n",
        wrong_rate, wrong_bits, wrong_channels, too_short
    );
    let output = compile_and_run_sdl_audio("sound_load_rejects_non_canonical", &src);
    assert!(output.status.success(), "{:?} stderr={}", output.status, String::from_utf8_lossy(&output.stderr));
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "true", "true", "true"], "every non-canonical WAV shape should be rejected: {}", stdout);
}

/// `sound_free` aborts loudly on a null/already-freed handle, matching
/// `window_destroy`/`file_close`'s own convention exactly.
#[test]
fn runtime_sound_free_aborts_on_null_handle_end_to_end() {
    let src = "fn main():\n    \
               let s = null_ptr()\n    \
               println(\"before\")\n    \
               sound_free(s)\n    \
               println(\"should not reach here\")\n";
    let output = compile_and_run_sdl_audio("sound_free_null_handle", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "{}", stdout);
    assert!(stdout.contains("null/freed sound handle"), "{}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

/// A full playback sequence -- one-shot `sound_play`, looping `music_play`
/// layered on top, `music_stop`, `sound_stop_all`, then `sound_free` --
/// runs end to end with no crash/hang under `SDL_AUDIODRIVER=dummy`,
/// exercising the real `SDL_OpenAudioDevice`/mixer-callback path, not just
/// a codegen-shape assertion.
#[test]
fn runtime_sound_and_music_playback_sequence_end_to_end() {
    let path = beep_wav_path();
    let src = format!(
        "fn main():\n    \
         let s = sound_load(\"{}\")\n    \
         println(f\"{{is_null(s)}}\")\n    \
         sound_play(s)\n    \
         delay(30)\n    \
         music_play(s)\n    \
         delay(30)\n    \
         sound_play(s)\n    \
         delay(30)\n    \
         music_stop()\n    \
         sound_stop_all()\n    \
         sound_free(s)\n    \
         println(\"done\")\n",
        path
    );
    let output = compile_and_run_sdl_audio("sound_and_music_playback_sequence", &src);
    assert!(output.status.success(), "{:?} stderr={}", output.status, String::from_utf8_lossy(&output.stderr));
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "done"], "{}", stdout);
}

/// `gamepad_count` returns `0` and `gamepad_open` returns `null` when no
/// joystick device is attached at all -- the common case under a headless
/// CI run with no virtual joystick set up (see
/// `runtime_gamepad_virtual_joystick_button_and_axis_round_trip_end_to_end`
/// for the "a device exists" side of this surface).
#[test]
fn runtime_gamepad_count_zero_and_open_null_with_no_device_end_to_end() {
    let src = "fn main():\n    \
               println(f\"{gamepad_count()}\")\n    \
               let pad = gamepad_open(0)\n    \
               println(f\"{is_null(pad)}\")\n";
    let output = compile_and_run_sdl("gamepad_count_zero_no_device", src);
    assert!(output.status.success(), "{:?} stderr={}", output.status, String::from_utf8_lossy(&output.stderr));
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["0", "true"], "{}", stdout);
}

/// `gamepad_close` aborts loudly on a null handle, matching
/// `window_destroy`/`sound_free`'s own convention.
#[test]
fn runtime_gamepad_close_aborts_on_null_handle_end_to_end() {
    let src = "fn main():\n    \
               let pad = null_ptr()\n    \
               println(\"before\")\n    \
               gamepad_close(pad)\n    \
               println(\"should not reach here\")\n";
    let output = compile_and_run_sdl("gamepad_close_null_handle", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "{}", stdout);
    assert!(stdout.contains("null/closed gamepad handle"), "{}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

/// The real end-to-end proof that `gamepad_open`/`gamepad_button_down`/
/// `gamepad_axis`/`gamepad_attached` actually read live SDL joystick state,
/// not just that they type-check and emit plausible-looking IR: attaches a
/// real SDL2 *virtual* joystick (`SDL_JoystickAttachVirtual`, available
/// since SDL 2.0.14 -- no physical hardware needed, unlike every other
/// input device this compiler binds to), sets its button/axis state with
/// `SDL_JoystickSetVirtualButton`/`SetVirtualAxis`, then confirms this
/// compiler's own `gamepad_*` builtins observe exactly that state.
///
/// Those three SDL functions can't be declared directly from a `.star`
/// program's own `extern "C" fn` -- this compiler's grammar always parses
/// `Name(args)` as a struct-literal constructor when `Name` starts with an
/// uppercase letter (`Checker::check_extern_fn` rejects any such extern
/// declaration outright, with no rename/alias syntax to work around it), and
/// every one of SDL2's real symbol names does. `compile_and_run_sdl_with_c_helper`
/// instead compiles a small lowercase-named C wrapper (below) into the same
/// binary, which a `.star` program's `extern "C" fn` declarations *can*
/// legally name and call.
#[test]
fn runtime_gamepad_virtual_joystick_button_and_axis_round_trip_end_to_end() {
    let c_helper = concat!(
        "#include <SDL.h>\n",
        "int star_test_joystick_attach_virtual(int naxes, int nbuttons) {\n",
        "    return SDL_JoystickAttachVirtual(SDL_JOYSTICK_TYPE_UNKNOWN, naxes, nbuttons, 0);\n",
        "}\n",
        "int star_test_joystick_set_virtual_button(void* joystick, int button, int value) {\n",
        "    return SDL_JoystickSetVirtualButton((SDL_Joystick*)joystick, button, (Uint8)value);\n",
        "}\n",
        "int star_test_joystick_set_virtual_axis(void* joystick, int axis, int value) {\n",
        "    return SDL_JoystickSetVirtualAxis((SDL_Joystick*)joystick, axis, (Sint16)value);\n",
        "}\n",
    );
    let src = concat!(
        "extern \"C\" fn star_test_joystick_attach_virtual(naxes: int, nbuttons: int) -> int\n",
        "extern \"C\" fn star_test_joystick_set_virtual_button(joystick: ptr, button: int, value: int) -> int\n",
        "extern \"C\" fn star_test_joystick_set_virtual_axis(joystick: ptr, axis: int, value: int) -> int\n",
        "\n",
        "fn main():\n",
        "    let before = gamepad_count()\n",
        "    let idx = star_test_joystick_attach_virtual(2, 2)\n",
        "    let after = gamepad_count()\n",
        "    println(f\"{after - before}\")\n",
        "    let pad = gamepad_open(idx)\n",
        "    println(f\"{is_null(pad)}\")\n",
        "    println(f\"{gamepad_attached(pad)}\")\n",
        "    println(f\"{gamepad_button_down(pad, 0)}\")\n",
        "    star_test_joystick_set_virtual_button(pad, 0, 1)\n",
        "    println(f\"{gamepad_button_down(pad, 0)}\")\n",
        "    println(f\"{gamepad_axis(pad, 0)}\")\n",
        "    star_test_joystick_set_virtual_axis(pad, 0, 12345)\n",
        "    println(f\"{gamepad_axis(pad, 0)}\")\n",
        "    gamepad_close(pad)\n",
    );
    let output = compile_and_run_sdl_with_c_helper("gamepad_virtual_joystick_round_trip", src, c_helper);
    assert!(output.status.success(), "{:?} stderr={}", output.status, String::from_utf8_lossy(&output.stderr));
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec!["1", "false", "true", "false", "true", "0", "12345"],
        "virtual joystick attach + button/axis round trip: {}",
        stdout
    );
}
