//! SDL2-backed audio playback builtins (`todo.md` #8 "Audio playback and
//! gamepad input" -- the audio half; see `crate::codegen::gamepad` for the
//! other half).
//!
//! `sound_load` parses a WAV file by hand from a plain `fopen`/`fread`
//! buffer -- mirroring `crate::codegen::font::emit_font_load`'s own
//! "`fopen` in binary mode, `fseek`/`ftell` to size the file, one
//! `malloc`+`fread` of the whole thing" approach -- rather than going
//! through SDL's own `SDL_LoadWAV_RW`/`SDL_AudioSpec`. Only the canonical,
//! minimal 44-byte-header PCM WAV shape is accepted: a `RIFF`/`WAVE` file
//! whose 16-byte `fmt ` chunk is immediately followed by the `data` chunk
//! (the layout every common WAV exporter -- Audacity, `sox`, `ffmpeg -f
//! wav` -- produces by default), and whose audio format is exactly 16-bit,
//! 44100Hz, stereo PCM. A WAV with extra chunks before `data` (e.g. a
//! `LIST`/`INFO` metadata chunk), a non-16-byte `fmt ` chunk, or any other
//! sample rate/bit depth/channel count is rejected outright (`sound_load`
//! returns `null`, checked with `is_null`) rather than scanned past or
//! resampled -- there is no runtime format-conversion path anywhere in this
//! floor, matching `window_create`'s own "fails cleanly, never silently
//! does something else" convention.
//!
//! Playback is a small hand-rolled additive mixer, not `SDL_QueueAudio`:
//! a fixed table of `NUM_CHANNELS` channels (channel 0 reserved for
//! looping "music", the rest one-shot "sound effects") is mixed every time
//! SDL's output device calls back for more data (`@star.audio.mix_callback`,
//! emitted once per program by `ensure_audio_pool_emitted`, mirroring
//! `crate::codegen::par_pool::ensure_par_pool_emitted`'s own "one-time
//! static machinery, guarded by a bool field" shape exactly). This gives
//! real overlapping playback (a footstep sound effect on top of background
//! music) that `SDL_QueueAudio` alone (which just serializes everything
//! into one FIFO) can't.
//!
//! Every loaded sound and the shared output device operate in one fixed
//! canonical format -- 44100Hz, stereo, signed 16-bit little-endian
//! (`AUDIO_S16LSB`) -- so the mixer never needs to resample or convert
//! between formats at mix time, only additively blend
//! (`SDL_MixAudioFormat`, which already handles the signed-16-bit
//! saturating add so this floor doesn't have to hand-roll clipping math).
//!
//! Concurrency note: the channel-table globals (`@star.audio.chan_*`) are
//! plain, unguarded globals -- read every audio-device callback (on SDL's
//! own dedicated audio thread) and written by `sound_play`/`music_play`/
//! `music_stop`/`sound_stop_all`/`sound_free` (on whichever thread calls
//! them). There is no lock: correctness leans on `emit_channel_start`
//! always writing a channel's `playing` flag *last* (so the mixer, which
//! checks `playing` *first* before reading any other field of that
//! channel, never observes a half-updated channel) and on x86/x64's own
//! strong store ordering (a plain store is never reordered after an
//! earlier plain store to a different address, on this compiler's only
//! target -- see `crate::codegen::mod`'s Windows-x64-only scope). A
//! genuinely portable version of this would need real atomics; this floor
//! doesn't need one. This is also why `sound_play`/`music_play`/
//! `music_stop`/`sound_stop_all`/`sound_free` are banned inside a `par`/
//! `swarm` body (`crate::types::par_analysis`) -- concurrent *writers* to
//! this same unlocked table from multiple worker threads is a real,
//! unguarded race the single-writer assumption above doesn't cover.
//!
//! `Ty::Ptr` is reused as the opaque sound handle exactly like
//! `window_create`/`font_load` (a 16-byte `malloc`'d `{ i64 len; i8* base
//! }` pair -- `base` is the whole loaded file buffer, `base + 44` is where
//! the PCM sample data actually starts, `len` is that data's own byte
//! length from the WAV's `data` chunk header).
//!
//! Linking note: same as `crate::codegen::sdl`'s own note -- needs
//! `-L sdl/lib/x64 -l SDL2` at build time and `SDL2.dll` discoverable at
//! run time.
//!
//! `sound_play_channel`/`sound_stop_channel` (added for `todo.md` P2 #5,
//! Nova-16's own 8-independent-sound-channel port) generalize `music_play`'s
//! "start on a fixed channel, replacing whatever's there" shape to any
//! caller-chosen channel index, with the loop flag now a runtime argument
//! instead of which builtin was called -- see their own doc comments below.

use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

/// Total channel slots in the shared mixer -- channel 0 is reserved for
/// `music_play`'s looping playback; channels `1..NUM_CHANNELS` are one-shot
/// slots `sound_play` scans for a free one. A `sound_play` call that finds
/// every slot busy is silently dropped (documented floor cut, no different
/// in kind from a real game engine's own fixed-voice-count mixer).
const NUM_CHANNELS: u32 = 16;

/// `AUDIO_S16LSB` (`SDL_audio.h`): signed 16-bit little-endian samples.
const AUDIO_S16LSB: u32 = 0x8010;

/// Little-endian 4-byte RIFF tag, read as a bare `u32` -- lets `sound_load`
/// validate a chunk tag (`"RIFF"`/`"WAVE"`/`"fmt "`/`"data"`) with one
/// `icmp eq i32` against a plain integer literal instead of a byte-by-byte
/// comparison, since native little-endian byte order already matches the
/// order these bytes are read back in by a bare `i32` load off the file
/// buffer.
fn wav_tag(tag: &[u8; 4]) -> u32 {
    u32::from_le_bytes(*tag)
}

impl Codegen {
    /// Abort (matches `crate::codegen::sdl`'s `abort_if_null_window` shape
    /// exactly, with sound-specific wording) if `handle` is a null `ptr`.
    fn abort_if_null_sound(&mut self, handle: &str, builtin_name: &str) {
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, handle));
        let fail_label = self.block_label("sound_null_handle");
        let ok_label = self.block_label("sound_handle_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, fail_label, ok_label));

        self.open_block(&fail_label);
        let msg = format!("star runtime error: {}(..) called with a null/freed sound handle\n", builtin_name);
        let g = self.global_name();
        let escaped = msg.replace("\\", "\\\\").replace("\"", "\\22").replace("\n", "\\0A");
        self.global_defs.push(format!("{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"", g, msg.len() + 1, escaped));
        let msg_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", msg_ptr, msg.len() + 1, msg.len() + 1, g));
        self.line(&format!("  call i32 @puts(i8* {})", msg_ptr));
        self.line("  call void @exit(i32 1)");
        self.line("  unreachable");

        self.open_block(&ok_label);
    }

    /// Emit the shared mixer's one-time static machinery (the channel-table
    /// globals and `@star.audio.mix_callback`) exactly once per program --
    /// see `crate::codegen::par_pool::ensure_par_pool_emitted`'s own doc
    /// comment for the identical guarded-emit-once shape this mirrors.
    /// Called by every builtin that references the channel table, whether
    /// or not it also needs a live output device (`music_stop`/
    /// `sound_stop_all`/`sound_free` write the table directly; `sound_play`/
    /// `music_play` also need `ensure_audio_device`).
    pub(super) fn ensure_audio_pool_emitted(&mut self) {
        if self.audio_pool_emitted {
            return;
        }
        self.audio_pool_emitted = true;

        let saved_ir = std::mem::take(&mut self.ir);

        self.line("@star.audio.device = global i32 0");
        self.line(&format!("@star.audio.chan_base = global [{} x i8*] zeroinitializer", NUM_CHANNELS));
        self.line(&format!("@star.audio.chan_len = global [{} x i64] zeroinitializer", NUM_CHANNELS));
        self.line(&format!("@star.audio.chan_pos = global [{} x i64] zeroinitializer", NUM_CHANNELS));
        self.line(&format!("@star.audio.chan_playing = global [{} x i8] zeroinitializer", NUM_CHANNELS));
        self.line(&format!("@star.audio.chan_loop = global [{} x i8] zeroinitializer", NUM_CHANNELS));
        self.line("");

        // The audio-device callback: zero the requested buffer, then
        // additively mix every currently-playing channel's remaining
        // samples into it. See this module's doc comment for the channel
        // table's field meanings and the informal (x86/TSO-leaning)
        // concurrency argument.
        self.line("define void @star.audio.mix_callback(i8* %userdata, i8* %stream, i32 %len) {");
        self.open_block("entry");
        let ci_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", ci_ptr));
        self.line(&format!("  store i32 0, i32* {}", ci_ptr));
        let len64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 %len to i64", len64));
        self.emit_fill_i8("%stream", &len64, 0);
        self.line("  br label %chan_cond");

        self.open_block("chan_cond");
        let ci = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", ci, ci_ptr));
        let cdone = self.tmp_name();
        self.line(&format!("  {} = icmp sge i32 {}, {}", cdone, ci, NUM_CHANNELS));
        self.line(&format!("  br i1 {}, label %exit, label %chan_body", cdone));

        self.open_block("chan_body");
        let playing_gep = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8], [{} x i8]* @star.audio.chan_playing, i32 0, i32 {}",
            playing_gep, NUM_CHANNELS, NUM_CHANNELS, ci
        ));
        let playing = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", playing, playing_gep));
        let is_playing = self.tmp_name();
        self.line(&format!("  {} = icmp ne i8 {}, 0", is_playing, playing));
        self.line(&format!("  br i1 {}, label %chan_mix, label %chan_latch", is_playing));

        self.open_block("chan_mix");
        let pos_gep = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @star.audio.chan_pos, i32 0, i32 {}",
            pos_gep, NUM_CHANNELS, NUM_CHANNELS, ci
        ));
        let pos0 = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", pos0, pos_gep));
        let len_gep = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @star.audio.chan_len, i32 0, i32 {}",
            len_gep, NUM_CHANNELS, NUM_CHANNELS, ci
        ));
        let clen = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", clen, len_gep));
        let remaining0 = self.tmp_name();
        self.line(&format!("  {} = sub i64 {}, {}", remaining0, clen, pos0));
        let needs_loop_check = self.tmp_name();
        self.line(&format!("  {} = icmp sle i64 {}, 0", needs_loop_check, remaining0));
        self.line(&format!("  br i1 {}, label %chan_checkloop, label %chan_have", needs_loop_check));

        // Channel exhausted (remaining <= 0): a looping channel restarts
        // from the beginning -- but only takes effect on the *next*
        // callback tick, not partway through this one, so a very short
        // loop clip relative to the ~23ms default callback buffer
        // (`samples=1024` @ 44100Hz) can have up to one buffer's silence
        // at its loop point. A non-looping channel just stops.
        self.open_block("chan_checkloop");
        let loop_gep = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8], [{} x i8]* @star.audio.chan_loop, i32 0, i32 {}",
            loop_gep, NUM_CHANNELS, NUM_CHANNELS, ci
        ));
        let loopflag = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", loopflag, loop_gep));
        let is_loop = self.tmp_name();
        self.line(&format!("  {} = icmp ne i8 {}, 0", is_loop, loopflag));
        self.line(&format!("  br i1 {}, label %chan_have, label %chan_stop", is_loop));

        self.open_block("chan_stop");
        self.line(&format!("  store i8 0, i8* {}", playing_gep));
        self.line("  br label %chan_latch");

        self.open_block("chan_have");
        let pos_m = self.tmp_name();
        self.line(&format!("  {} = phi i64 [ {}, %chan_mix ], [ 0, %chan_checkloop ]", pos_m, pos0));
        let remaining_m = self.tmp_name();
        self.line(&format!("  {} = phi i64 [ {}, %chan_mix ], [ {}, %chan_checkloop ]", remaining_m, remaining0, clen));
        let fits = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", fits, remaining_m, len64));
        let n = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i64 {}, i64 {}", n, fits, remaining_m, len64));
        let n32 = self.tmp_name();
        self.line(&format!("  {} = trunc i64 {} to i32", n32, n));
        let base_gep = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @star.audio.chan_base, i32 0, i32 {}",
            base_gep, NUM_CHANNELS, NUM_CHANNELS, ci
        ));
        let base = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", base, base_gep));
        let src = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", src, base, pos_m));
        self.line(&format!(
            "  call void @SDL_MixAudioFormat(i8* %stream, i8* {}, i16 {}, i32 {}, i32 128)",
            src, AUDIO_S16LSB, n32
        ));
        let newpos = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, {}", newpos, pos_m, n));
        self.line(&format!("  store i64 {}, i64* {}", newpos, pos_gep));
        let chan_done = self.tmp_name();
        self.line(&format!("  {} = icmp sge i64 {}, {}", chan_done, newpos, clen));
        self.line(&format!("  br i1 {}, label %chan_checkdone, label %chan_latch", chan_done));

        self.open_block("chan_checkdone");
        let loop_gep2 = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8], [{} x i8]* @star.audio.chan_loop, i32 0, i32 {}",
            loop_gep2, NUM_CHANNELS, NUM_CHANNELS, ci
        ));
        let loopflag2 = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", loopflag2, loop_gep2));
        let is_loop2 = self.tmp_name();
        self.line(&format!("  {} = icmp ne i8 {}, 0", is_loop2, loopflag2));
        self.line(&format!("  br i1 {}, label %chan_wrap, label %chan_finish", is_loop2));

        self.open_block("chan_wrap");
        self.line(&format!("  store i64 0, i64* {}", pos_gep));
        self.line("  br label %chan_latch");

        self.open_block("chan_finish");
        self.line(&format!("  store i8 0, i8* {}", playing_gep));
        self.line("  br label %chan_latch");

        self.open_block("chan_latch");
        let ci_next = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", ci_next, ci));
        self.line(&format!("  store i32 {}, i32* {}", ci_next, ci_ptr));
        self.line("  br label %chan_cond");

        self.open_block("exit");
        self.line("  ret void");
        self.line("}");
        self.line("");

        let pool_ir = std::mem::replace(&mut self.ir, saved_ir);
        self.pending_top.push(Self::hoist_allocas_to_entry(&pool_ir));
    }

    /// Lazily open the shared output device the first time any sound
    /// actually needs to play, guarded by `@star.audio.device` (`0` means
    /// "not yet opened"). Deliberately guarded rather than called
    /// unconditionally-every-time the way `window_create`'s own `SDL_Init`
    /// call is (see that function's doc comment) -- audio has exactly one
    /// shared mixer device for the whole program, not one instance per
    /// call, so opening it more than once would either fail outright or
    /// create redundant simultaneous output streams. A failed open leaves
    /// the flag at `0`, so every subsequent `sound_play`/`music_play` call
    /// harmlessly retries (matching this floor's "never crash, just don't
    /// make sound" convention on a machine with no audio device at all).
    fn ensure_audio_device(&mut self) {
        self.ensure_audio_pool_emitted();

        let dev = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* @star.audio.device", dev));
        let dev_open = self.tmp_name();
        self.line(&format!("  {} = icmp ne i32 {}, 0", dev_open, dev));
        let init_label = self.block_label("audio_dev_init");
        let ok_label = self.block_label("audio_dev_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", dev_open, ok_label, init_label));

        self.open_block(&init_label);
        let sdl_init = self.tmp_name();
        self.line(&format!("  {} = call i32 @SDL_Init(i32 16)", sdl_init)); // SDL_INIT_AUDIO

        // `SDL_AudioSpec` (32 bytes on a 64-bit target -- see
        // `SDL_audio.h`): `{ i32 freq; i16 format; i8 channels; i8 silence;
        // i16 samples; i16 padding; i32 size; void(*callback)(...); void*
        // userdata; }`. Zeroed first so `silence`/`size` (SDL-calculated,
        // never read from the *desired* spec) and `userdata` (unused --
        // the callback reads the channel table directly, needing no
        // userdata of its own) are never left as uninitialized stack
        // garbage.
        let spec_buf = self.tmp_name();
        self.line(&format!("  {} = alloca [32 x i8]", spec_buf));
        let spec_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [32 x i8], [32 x i8]* {}, i64 0, i64 0", spec_ptr, spec_buf));
        self.emit_fill_i8(&spec_ptr, "32", 0);

        let freq_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", freq_ptr, spec_ptr));
        self.line(&format!("  store i32 44100, i32* {}", freq_ptr));

        let fmt_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 4", fmt_gep, spec_ptr));
        let fmt_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i16*", fmt_ptr, fmt_gep));
        self.line(&format!("  store i16 {}, i16* {}", AUDIO_S16LSB, fmt_ptr));

        let chan_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 6", chan_gep, spec_ptr));
        self.line(&format!("  store i8 2, i8* {}", chan_gep));

        let samples_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 8", samples_gep, spec_ptr));
        let samples_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i16*", samples_ptr, samples_gep));
        self.line(&format!("  store i16 1024, i16* {}", samples_ptr));

        let cb_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 16", cb_gep, spec_ptr));
        let cb_slot = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i8**", cb_slot, cb_gep));
        let cb_fn_i8 = self.tmp_name();
        self.line(&format!("  {} = bitcast void (i8*, i8*, i32)* @star.audio.mix_callback to i8*", cb_fn_i8));
        self.line(&format!("  store i8* {}, i8** {}", cb_fn_i8, cb_slot));

        // `allowed_changes = 0`: SDL must give back exactly the requested
        // format or fail -- this floor has no fallback conversion path
        // (see this module's doc comment), so a silently-different actual
        // format would desync every channel's own fixed-format assumption.
        let devid = self.tmp_name();
        self.line(&format!(
            "  {} = call i32 @SDL_OpenAudioDevice(i8* null, i32 0, i8* {}, i8* null, i32 0)",
            devid, spec_ptr
        ));
        let open_ok = self.tmp_name();
        self.line(&format!("  {} = icmp ne i32 {}, 0", open_ok, devid));
        let open_ok_label = self.block_label("audio_open_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", open_ok, open_ok_label, ok_label));

        self.open_block(&open_ok_label);
        self.line(&format!("  store i32 {}, i32* @star.audio.device", devid));
        self.line(&format!("  call void @SDL_PauseAudioDevice(i32 {}, i32 0)", devid));
        self.line(&format!("  br label %{}", ok_label));

        self.open_block(&ok_label);
    }

    /// Read a loaded sound handle's `{ i64 len; i8* base }` pair back into
    /// the PCM data's own start pointer (`base + 44`, past the 44-byte
    /// canonical WAV header -- see this module's doc comment) and its byte
    /// length.
    fn emit_sound_data_and_len(&mut self, handle: &str) -> (String, String) {
        let len_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i64*", len_ptr, handle));
        let len = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len, len_ptr));
        let base_field_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 8", base_field_gep, handle));
        let base_field_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i8**", base_field_ptr, base_field_gep));
        let base = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", base, base_field_ptr));
        let data_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 44", data_ptr, base));
        (data_ptr, len)
    }

    /// Start playback on channel `chan_index` (a register or a literal
    /// like `"0"`): `base`/`len`/`pos=0`/`loop` are stored first, `playing`
    /// last -- see this module's own doc comment for why that ordering is
    /// the whole (informal) concurrency argument for the mixer callback
    /// never observing a half-updated channel.
    fn emit_channel_start(&mut self, chan_index: &str, data_ptr: &str, len: &str, is_loop: bool) {
        let base_gep = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @star.audio.chan_base, i32 0, i32 {}",
            base_gep, NUM_CHANNELS, NUM_CHANNELS, chan_index
        ));
        self.line(&format!("  store i8* {}, i8** {}", data_ptr, base_gep));

        let len_gep = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @star.audio.chan_len, i32 0, i32 {}",
            len_gep, NUM_CHANNELS, NUM_CHANNELS, chan_index
        ));
        self.line(&format!("  store i64 {}, i64* {}", len, len_gep));

        let pos_gep = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i64], [{} x i64]* @star.audio.chan_pos, i32 0, i32 {}",
            pos_gep, NUM_CHANNELS, NUM_CHANNELS, chan_index
        ));
        self.line(&format!("  store i64 0, i64* {}", pos_gep));

        let loop_gep = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8], [{} x i8]* @star.audio.chan_loop, i32 0, i32 {}",
            loop_gep, NUM_CHANNELS, NUM_CHANNELS, chan_index
        ));
        self.line(&format!("  store i8 {}, i8* {}", if is_loop { 1 } else { 0 }, loop_gep));

        let playing_gep = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8], [{} x i8]* @star.audio.chan_playing, i32 0, i32 {}",
            playing_gep, NUM_CHANNELS, NUM_CHANNELS, chan_index
        ));
        self.line(&format!("  store i8 1, i8* {}", playing_gep));
    }

    /// `sound_load(path: str) -> ptr`: see this module's doc comment for
    /// the exact canonical-WAV shape accepted. `null` on any failure
    /// (missing file, too-short/malformed header, or a non-canonical
    /// format), checked with `is_null`.
    pub(super) fn emit_sound_load(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("sound_load(..) expects 1 argument (path)", Span::dummy());
            return "i8* null".into();
        };
        let path = self.emit_raw_str_ptr(arg);
        let mode_g = self.global_name();
        self.global_defs.push(format!("{} = private unnamed_addr constant [3 x i8] c\"rb\\00\"", mode_g));
        let mode_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [3 x i8], [3 x i8]* {}, i64 0, i64 0", mode_ptr, mode_g));
        let handle = self.tmp_name();
        self.line(&format!("  {} = call i8* @fopen(i8* {}, i8* {})", handle, path, mode_ptr));
        self.line(&format!("  call void @star_rc_release(i8* {})", path));

        let open_failed = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", open_failed, handle));
        let open_fail_label = self.block_label("sound_load_open_fail");
        let open_ok_label = self.block_label("sound_load_open_ok");
        let end_label = self.block_label("sound_load_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", open_failed, open_fail_label, open_ok_label));

        self.open_block(&open_fail_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&open_ok_label);
        self.line(&format!("  call i32 @fseek(i8* {}, i32 0, i32 2)", handle));
        let size = self.tmp_name();
        self.line(&format!("  {} = call i32 @ftell(i8* {})", size, handle));
        self.line(&format!("  call i32 @fseek(i8* {}, i32 0, i32 0)", handle));

        let size_ok = self.tmp_name();
        self.line(&format!("  {} = icmp sge i32 {}, 44", size_ok, size)); // canonical header size
        let too_small_label = self.block_label("sound_load_too_small");
        let read_label = self.block_label("sound_load_read");
        self.line(&format!("  br i1 {}, label %{}, label %{}", size_ok, read_label, too_small_label));

        self.open_block(&too_small_label);
        self.line(&format!("  call i32 @fclose(i8* {})", handle));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&read_label);
        let size64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", size64, size));
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", buf, size64));
        let nread = self.tmp_name();
        self.line(&format!("  {} = call i64 @fread(i8* {}, i64 1, i64 {}, i8* {})", nread, buf, size64, handle));
        self.line(&format!("  call i32 @fclose(i8* {})", handle));

        let read_ok = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, {}", read_ok, nread, size64));
        let short_read_label = self.block_label("sound_load_short_read");
        let validate_label = self.block_label("sound_load_validate");
        self.line(&format!("  br i1 {}, label %{}, label %{}", read_ok, validate_label, short_read_label));

        self.open_block(&short_read_label);
        self.line(&format!("  call void @free(i8* {})", buf));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&validate_label);
        let riff_ok = self.emit_check_u32_tag(&buf, 0, wav_tag(b"RIFF"));
        let wave_ok = self.emit_check_u32_tag(&buf, 8, wav_tag(b"WAVE"));
        let fmt_tag_ok = self.emit_check_u32_tag(&buf, 12, wav_tag(b"fmt "));
        let subchunk1_ok = self.emit_check_u32_tag(&buf, 16, 16); // `fmt ` chunk size, PCM
        // `AudioFormat`(u16 @20)==1 (PCM) and `NumChannels`(u16 @22)==2
        // (stereo), read together as one packed `u32` (`NumChannels<<16 |
        // AudioFormat`) so both fields are checked with a single load+compare.
        let fmtchan_ok = self.emit_check_u32_tag(&buf, 20, 1 | (2 << 16));
        let rate_ok = self.emit_check_u32_tag(&buf, 24, 44100); // SampleRate (u32 @24)

        let bits_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 34", bits_gep, buf));
        let bits_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i16*", bits_ptr, bits_gep));
        let bits = self.tmp_name();
        self.line(&format!("  {} = load i16, i16* {}", bits, bits_ptr));
        let bits_ok = self.tmp_name();
        self.line(&format!("  {} = icmp eq i16 {}, 16", bits_ok, bits)); // BitsPerSample

        let data_tag_ok = self.emit_check_u32_tag(&buf, 36, wav_tag(b"data"));

        let a1 = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", a1, riff_ok, wave_ok));
        let a2 = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", a2, a1, fmt_tag_ok));
        let a3 = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", a3, a2, subchunk1_ok));
        let a4 = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", a4, a3, fmtchan_ok));
        let a5 = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", a5, a4, rate_ok));
        let a6 = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", a6, a5, bits_ok));
        let all_ok = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", all_ok, a6, data_tag_ok));

        let invalid_label = self.block_label("sound_load_invalid");
        let valid_label = self.block_label("sound_load_valid");
        self.line(&format!("  br i1 {}, label %{}, label %{}", all_ok, valid_label, invalid_label));

        self.open_block(&invalid_label);
        self.line(&format!("  call void @free(i8* {})", buf));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&valid_label);
        let datalen_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 40", datalen_gep, buf));
        let datalen_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", datalen_ptr, datalen_gep));
        let datalen32 = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", datalen32, datalen_ptr));
        let datalen64 = self.tmp_name();
        self.line(&format!("  {} = zext i32 {} to i64", datalen64, datalen32)); // Subchunk2Size (unsigned)

        let wrapper = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 16)", wrapper));
        let len_field_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i64*", len_field_ptr, wrapper));
        self.line(&format!("  store i64 {}, i64* {}", datalen64, len_field_ptr));
        let base_field_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 8", base_field_gep, wrapper));
        let base_field_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i8**", base_field_ptr, base_field_gep));
        self.line(&format!("  store i8* {}, i8** {}", buf, base_field_ptr));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!(
            "  {} = phi i8* [ null, %{} ], [ null, %{} ], [ null, %{} ], [ null, %{} ], [ {}, %{} ]",
            result, open_fail_label, too_small_label, short_read_label, invalid_label, wrapper, valid_label
        ));
        format!("i8* {}", result)
    }

    /// Load a `u32` at byte offset `offset` from `buf` and compare it
    /// against the literal `expected`, returning the `i1` comparison
    /// result -- shared by every fixed-offset header-field check
    /// `emit_sound_load` runs.
    fn emit_check_u32_tag(&mut self, buf: &str, offset: u64, expected: u32) -> String {
        let gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", gep, buf, offset));
        let ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", ptr, gep));
        let val = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", val, ptr));
        let ok = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, {}", ok, val, expected));
        ok
    }

    /// `sound_free(handle: ptr)`: stops every channel currently playing
    /// this sound's data (so the mixer never reads freed memory on its
    /// next callback tick), then frees both the loaded WAV byte buffer and
    /// the handle wrapper itself. Nulls out the caller's own variable, if
    /// `arg` is a bare one -- same rationale as
    /// `crate::codegen::sdl::emit_window_destroy`.
    pub(super) fn emit_sound_free(&mut self, args: &[TypedExpr]) {
        let Some(arg) = args.first() else {
            self.err("sound_free(..) expects 1 argument", Span::dummy());
            return;
        };
        let val = self.emit_expr(arg);
        let handle = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_sound(&handle, "sound_free");
        self.ensure_audio_pool_emitted();

        let (data_ptr, _len) = self.emit_sound_data_and_len(&handle);

        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", i_ptr));
        self.line(&format!("  store i32 0, i32* {}", i_ptr));
        let cond = self.block_label("sound_free_scan_cond");
        let check = self.block_label("sound_free_scan_check");
        let match_lbl = self.block_label("sound_free_scan_match");
        let next = self.block_label("sound_free_scan_next");
        let end = self.block_label("sound_free_scan_end");
        self.line(&format!("  br label %{}", cond));

        self.open_block(&cond);
        let i = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", i, i_ptr));
        let done = self.tmp_name();
        self.line(&format!("  {} = icmp sge i32 {}, {}", done, i, NUM_CHANNELS));
        self.line(&format!("  br i1 {}, label %{}, label %{}", done, end, check));

        self.open_block(&check);
        let base_gep = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8*], [{} x i8*]* @star.audio.chan_base, i32 0, i32 {}",
            base_gep, NUM_CHANNELS, NUM_CHANNELS, i
        ));
        let base = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", base, base_gep));
        let is_match = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, {}", is_match, base, data_ptr));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_match, match_lbl, next));

        self.open_block(&match_lbl);
        let playing_gep = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8], [{} x i8]* @star.audio.chan_playing, i32 0, i32 {}",
            playing_gep, NUM_CHANNELS, NUM_CHANNELS, i
        ));
        self.line(&format!("  store i8 0, i8* {}", playing_gep));
        self.line(&format!("  br label %{}", next));

        self.open_block(&next);
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", i_next, i));
        self.line(&format!("  store i32 {}, i32* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond));

        self.open_block(&end);
        let base_field_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 8", base_field_gep, handle));
        let base_field_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i8**", base_field_ptr, base_field_gep));
        let base2 = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", base2, base_field_ptr));
        self.line(&format!("  call void @free(i8* {})", base2));
        self.line(&format!("  call void @free(i8* {})", handle));

        if let TypedExpr::Ident { .. } = arg {
            let place = self.emit_place(arg);
            self.line(&format!("  store i8* null, i8** {}", place));
        }
    }

    /// `sound_play(sound: ptr)`: one-shot playback on the first free
    /// channel in `1..NUM_CHANNELS` (channel 0 is reserved for
    /// `music_play`). Silently dropped if every slot is already busy --
    /// see `NUM_CHANNELS`'s own doc comment.
    pub(super) fn emit_sound_play(&mut self, args: &[TypedExpr]) {
        let Some(arg) = args.first() else {
            self.err("sound_play(..) expects 1 argument (sound)", Span::dummy());
            return;
        };
        let val = self.emit_expr(arg);
        let handle = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_sound(&handle, "sound_play");
        self.ensure_audio_device();
        let (data_ptr, len) = self.emit_sound_data_and_len(&handle);

        let slot_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", slot_ptr));
        self.line(&format!("  store i32 -1, i32* {}", slot_ptr));
        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", i_ptr));
        self.line(&format!("  store i32 1, i32* {}", i_ptr)); // skip channel 0 (music)

        let cond = self.block_label("sound_play_scan_cond");
        let check = self.block_label("sound_play_scan_check");
        let found = self.block_label("sound_play_scan_found");
        let body = self.block_label("sound_play_scan_body");
        let end = self.block_label("sound_play_scan_end");
        self.line(&format!("  br label %{}", cond));

        self.open_block(&cond);
        let i = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", i, i_ptr));
        let done = self.tmp_name();
        self.line(&format!("  {} = icmp sge i32 {}, {}", done, i, NUM_CHANNELS));
        self.line(&format!("  br i1 {}, label %{}, label %{}", done, end, check));

        self.open_block(&check);
        let p_gep = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8], [{} x i8]* @star.audio.chan_playing, i32 0, i32 {}",
            p_gep, NUM_CHANNELS, NUM_CHANNELS, i
        ));
        let p = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", p, p_gep));
        let free = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8 {}, 0", free, p));
        self.line(&format!("  br i1 {}, label %{}, label %{}", free, found, body));

        self.open_block(&found);
        self.line(&format!("  store i32 {}, i32* {}", i, slot_ptr));
        self.line(&format!("  br label %{}", end));

        self.open_block(&body);
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", i_next, i));
        self.line(&format!("  store i32 {}, i32* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond));

        self.open_block(&end);
        let slot = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", slot, slot_ptr));
        let has_slot = self.tmp_name();
        self.line(&format!("  {} = icmp sge i32 {}, 0", has_slot, slot));
        let play_label = self.block_label("sound_play_do");
        let after_label = self.block_label("sound_play_after");
        self.line(&format!("  br i1 {}, label %{}, label %{}", has_slot, play_label, after_label));

        self.open_block(&play_label);
        self.emit_channel_start(&slot, &data_ptr, &len, false);
        self.line(&format!("  br label %{}", after_label));

        self.open_block(&after_label);
    }

    /// `music_play(sound: ptr)`: unconditionally (re)starts looping
    /// playback on the reserved music channel (0), replacing whatever was
    /// playing there.
    pub(super) fn emit_music_play(&mut self, args: &[TypedExpr]) {
        let Some(arg) = args.first() else {
            self.err("music_play(..) expects 1 argument (sound)", Span::dummy());
            return;
        };
        let val = self.emit_expr(arg);
        let handle = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_sound(&handle, "music_play");
        self.ensure_audio_device();
        let (data_ptr, len) = self.emit_sound_data_and_len(&handle);
        self.emit_channel_start("0", &data_ptr, &len, true);
    }

    /// `music_stop()`: stops the reserved music channel (0). No handle
    /// argument and no null-check -- there's nothing to misuse.
    pub(super) fn emit_music_stop(&mut self) {
        self.ensure_audio_pool_emitted();
        let gep = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8], [{} x i8]* @star.audio.chan_playing, i32 0, i32 0",
            gep, NUM_CHANNELS, NUM_CHANNELS
        ));
        self.line(&format!("  store i8 0, i8* {}", gep));
    }

    /// `sound_stop_all()`: stops every channel (music and every sound
    /// effect alike) -- a "panic button" for, e.g., a scene transition.
    pub(super) fn emit_sound_stop_all(&mut self) {
        self.ensure_audio_pool_emitted();
        let gep = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8], [{} x i8]* @star.audio.chan_playing, i32 0, i32 0",
            gep, NUM_CHANNELS, NUM_CHANNELS
        ));
        self.emit_fill_i8(&gep, &NUM_CHANNELS.to_string(), 0);
    }

    /// `sound_play_channel(sound: ptr, channel: int, looped: bool)`: starts
    /// playback of `sound` on the exact mixer channel `channel & (NUM_CHANNELS
    /// - 1)` -- a cheap power-of-two mask that keeps the index always
    /// in-bounds with no branch, matching `wrap_addr`-style masking already
    /// used elsewhere in this codebase's own Nova-16 port rather than a
    /// bounds-check-and-clamp. Unlike `sound_play`'s auto-scanned free slot
    /// or `music_play`'s hardcoded channel 0, this lets a caller address a
    /// *specific* channel directly, unconditionally overwriting whatever was
    /// already playing there via the same `emit_channel_start` every other
    /// playback builtin uses -- "start on channel N, replacing whatever's
    /// there" is exactly `music_play`'s own semantics, generalized from a
    /// fixed channel to any caller-chosen one, with the loop flag now a
    /// runtime argument rather than baked into which builtin was called.
    /// This is what a true per-N-independent-voice model needs: `todo.md`
    /// P2 #5's Nova-16 port is the first real caller, mapping its own 8
    /// SW-channel-select-bit voices onto mixer channels 0-7 directly (see
    /// `projects/nova/sound.star`), leaving 8-15 to the existing `sound_play`
    /// auto-scan pool for its unaddressed one-shot effects.
    pub(super) fn emit_sound_play_channel(&mut self, args: &[TypedExpr]) {
        if args.len() < 3 {
            self.err("sound_play_channel(..) expects 3 arguments (sound, channel, looped)", Span::dummy());
            return;
        }
        let val = self.emit_expr(&args[0]);
        let handle = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_sound(&handle, "sound_play_channel");
        self.ensure_audio_device();
        let (data_ptr, len) = self.emit_sound_data_and_len(&handle);

        let chan_val = self.emit_expr(&args[1]);
        let chan_raw = self.untag(&chan_val, &Ty::Int);
        let chan_masked = self.tmp_name();
        self.line(&format!("  {} = and i32 {}, {}", chan_masked, chan_raw, NUM_CHANNELS - 1));

        let loop_val = self.emit_expr(&args[2]);
        let loop_i1 = self.untag(&loop_val, &Ty::Bool);
        let loop_label = self.block_label("sound_play_channel_loop");
        let oneshot_label = self.block_label("sound_play_channel_oneshot");
        let after_label = self.block_label("sound_play_channel_after");
        self.line(&format!("  br i1 {}, label %{}, label %{}", loop_i1, loop_label, oneshot_label));

        self.open_block(&loop_label);
        self.emit_channel_start(&chan_masked, &data_ptr, &len, true);
        self.line(&format!("  br label %{}", after_label));

        self.open_block(&oneshot_label);
        self.emit_channel_start(&chan_masked, &data_ptr, &len, false);
        self.line(&format!("  br label %{}", after_label));

        self.open_block(&after_label);
    }

    /// `sound_stop_channel(channel: int)`: stops only the exact mixer
    /// channel `channel & (NUM_CHANNELS - 1)`, unlike `sound_stop_all`'s
    /// "stop everything" -- the counterpart `sound_play_channel` needs a way
    /// to silence one independently-addressed voice without cutting off
    /// every other channel currently playing.
    pub(super) fn emit_sound_stop_channel(&mut self, args: &[TypedExpr]) {
        let Some(chan_arg) = args.first() else {
            self.err("sound_stop_channel(..) expects 1 argument (channel)", Span::dummy());
            return;
        };
        self.ensure_audio_pool_emitted();
        let chan_val = self.emit_expr(chan_arg);
        let chan_raw = self.untag(&chan_val, &Ty::Int);
        let chan_masked = self.tmp_name();
        self.line(&format!("  {} = and i32 {}, {}", chan_masked, chan_raw, NUM_CHANNELS - 1));

        let gep = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8], [{} x i8]* @star.audio.chan_playing, i32 0, i32 {}",
            gep, NUM_CHANNELS, NUM_CHANNELS, chan_masked
        ));
        self.line(&format!("  store i8 0, i8* {}", gep));
    }
}
