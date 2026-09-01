# Nova-16 sound synthesis (todo.md P0 #1) -- real waveform generation and
# playback behind `SPLAY`/`SSTOP`/`STRIG` (docs/SOUND_SYSTEM.md), wired up
# from `cpu.star`'s op_splay/op_sstop/op_strig. Previously these were
# literal no-ops (see NOTES.md's "Known simplifications": "SPLAY/SSTOP/
# STRIG update no actual audio state") on the theory that "actual waveform
# generation is a host-audio concern more than CPU-instruction semantics" --
# todo.md's reassessment explicitly rejected that as an excuse once
# `crate::codegen::audio`'s WAV-file playback mixer (`sound_load`/
# `sound_play`/`music_play`/`music_stop`/`sound_stop_all`) landed, since that
# gives this port a real host-audio backend to drive.
#
# Approach: `sound_load` only accepts a canonical 44-byte-header, 44_100Hz/
# stereo/16-bit PCM *file* (see `audio.rs`'s own doc comment) -- there is no
# builtin to hand it raw in-memory samples directly. So every synthesis
# function here builds a complete WAV byte buffer (header + PCM) with plain
# `Bytes.push`, writes it to a fixed temp-directory path via the existing
# `file_open`/`file_write_bytes` builtins, then `sound_load`s that same path
# straight back and plays it -- a real round trip through the filesystem
# rather than a new "raw samples" builtin, exactly matching todo.md P0 #1's
# own framing ("no new language surface should be needed for a minimal
# version"). This costs one small synchronous file write+read per `SPLAY`/
# `STRIG` trigger (a few KB to a few hundred KB, once per *trigger*, not per
# frame) -- acceptable for a fantasy-console sound trigger, not something a
# real-time streaming synthesizer would ever do.
#
# Every waveform formula below only needs one sample-generation pass: each
# `synth_*` function builds its own `Bytes` from a fresh `wav_header(..)`
# call, then repeatedly reassigns it through `push_frame` (`buf =
# push_frame(buf, ..)`) once per sample. That reassignment is required, not
# stylistic: a `Bytes` (or any `List<T>`) function *parameter* is a real,
# independent copy of the caller's binding -- mutating it in place inside
# the callee (`fn f(mut b: Bytes): b.push(x)`, discarding the result) would
# silently mutate a throwaway copy the caller never sees, exactly the bug
# this project already hit and documented for the analogous `Cpu`-by-value
# case (NOTES.md's "Testing"/"Four Star compiler bugs" writeup) -- `self` is
# the only parameter kind this compiler pointer-passes mutations back
# through. `push_frame`'s own doc comment has the details. This is also why
# the 8 STRIG effects each have their own dedicated function with its own
# inline sample loop instead of composing from smaller pieces -- there's no
# cheap "concatenate two already-built `Bytes` values" primitive to reach
# for here, and hand-copying one into another via `push_frame` in a loop
# would just be this same reassignment pattern one level removed.
#
# Known, documented simplifications (todo.md P0 #1's own "minimal version"
# framing, not oversights):
# - `SSTOP` has no operand in this port's ISA (`docs/nova16_instruction_
#   reference.md`: 0 operands, unlike the upstream Python reference's
#   `SSTOP`/`SSTOP reg` split) -- `stop_all()` below always stops
#   everything, which is exactly what the single no-operand opcode means.
#
# todo.md P2 #5 ("a true per-8-channel voice model instead of the current
# one-loop-channel-plus-one-shot-pool collapse", "a real 1/f pink-noise
# filter instead of the 3-tap white-noise approximation") closed both of
# its own remaining gaps in this file:
# - **True per-8-channel voices.** `SW`'s channel-select bits (3-5) are now
#   both decoded *and* respected (`cpu.star::op_splay` extracts `(sw_val >>
#   3) & 7` and threads it all the way through) -- unblocked by a new
#   compiler builtin pair, `sound_play_channel(sound, channel, looped)`/
#   `sound_stop_channel(channel)` (`crate::codegen::audio`), which starts/
#   stops playback on an exact, caller-chosen mixer channel instead of
#   `music_play`'s hardcoded channel 0 or `sound_play`'s auto-scanned free
#   slot. `play_pcm_wav_on_channel` below is the new common entry point:
#   Nova's 8 hardware channels map directly onto mixer channels 0-7,
#   matching `nova_sound.py::NovaSound.splay`'s own `max_channels=8`/
#   `channel = (SW >> 3) & 0x07` exactly, including "starting a new `SPLAY`
#   on a channel replaces whatever was already playing there" (the
#   reference's own "stop any existing sound on this channel" -- see
#   `crate::codegen::audio::emit_channel_start`'s unconditional overwrite).
#   `STRIG` has no channel-select bits at all in either the reference or
#   this port's ISA (`nova_sound.py::_play_sample_direct` bypasses
#   `self.sound_channels`/`self.channel_states` entirely, going straight to
#   a fresh, unaddressed `pygame.mixer.Sound.play()`), so it deliberately
#   stays *off* the 8 hardware channels: `Cpu::next_strig_channel` (see
#   `cpu.star`) round-robins mixer channels 8-15 instead, one per `STRIG`
#   call -- 8 slots, coincidentally the same count `pygame.mixer`'s own
#   default channel pool has, giving up to 8 overlapping one-shot effects
#   without ever contending with a hardware voice's fixed channel.
#   `trigger_effect` below takes that rotating channel as a parameter
#   rather than calling the generic auto-scanned `sound_play` it used to.
#   One residual, documented interaction: since both a hardware channel and
#   the `STRIG` pool ultimately share the same fixed-size `NUM_CHANNELS`
#   mixer array, and channel *assignment* is otherwise fully deterministic
#   and disjoint (0-7 vs. 8-15), there is no collision path left --
#   unlike before this fix, where `SPLAY`'s one-shot pool and `STRIG`
#   both auto-scanned the *same* 1-15 range and could clobber each other.
#   Reusing the same two fixed temp-file paths (`loop_temp_path`/
#   `effect_temp_path`) across every channel stays safe under this new
#   model for the same reason it always was: `sound_load` fully reads a
#   file into its own independent `malloc`'d buffer before returning (see
#   `crate::codegen::audio::emit_sound_load`), so a handle is completely
#   decoupled from the temp file the instant `play_pcm_wav_on_channel`
#   loads it back -- a later trigger overwriting that same temp path can't
#   retroactively corrupt an already-loaded, already-playing handle on a
#   different channel. This project is single-threaded and fully
#   synchronous (write, then immediately load-back), so there's never a
#   moment where two triggers race over the same temp file either.
# - **Real pink noise.** Waveform 6 is now the same one-pole IIR low-pass
#   filter over white noise `nova_sound.py::_generate_waveform_tables`/
#   `_generate_waveform_sample` itself uses (`pink[i] = 0.99*pink[i-1] +
#   0.01*white[i]`, first sample `0.0`) -- a bug-for-bug match with the
#   reference's own "not a perfect 1/f filter but adequate" implementation
#   (the reference's own comment), replacing this port's previous 3-tap
#   running-average stand-in. `waveform_sample` now threads the filter's
#   one-sample memory through as an extra parameter/return value (a
#   `(sample, next_state)` tuple) since generating pink noise -- unlike
#   every other waveform here -- needs state that persists *across* calls,
#   not just within one; every caller (`synth_tone`/`synth_loop_tone`)
#   carries a `mut pink_state` local through its sample loop accordingly.
#   `synth_noise_decay` (`STRIG`'s Explosion effect) is a deliberately
#   separate, *not* upgraded, noise shape: the reference's own
#   `_play_effect_explosion` runs white noise through a 10-tap moving-
#   average convolution, a materially different filter from the 0.99/0.01
#   one-pole pink-noise IIR above, and todo.md P2 #5 only named "pink
#   noise" (waveform 6) as the gap -- `synth_noise_decay`'s existing 3-tap
#   approximation of that separate 10-tap shape is untouched, a pre-existing
#   simplification this round didn't touch.
#
# todo.md P2 #3 ("sound.star's leaked WAV handles") closes the one
# remaining named audio simplification: every `play_pcm_wav_on_channel`
# call now *returns* the `sound_load`d handle (`ptr`, `null_ptr()` on any
# failure -- same "null on failure, checked with `is_null`" idiom every
# other loader builtin in this codebase already uses) instead of a bare
# `bool`, and `play_tone`/`play_memory_sample`/`trigger_effect` all
# propagate that return value up to their caller (`cpu_sound.star`,
# `sound.star` itself has no `Cpu` access -- see above). `cpu_sound.star`
# is where the actual fix lives: `Cpu::sound_channel_handles` (`cpu.star`)
# tracks the one handle each of the 16 mixer channels this port ever
# addresses (0-7 hardware voices, 8-15 the `STRIG` pool) currently holds,
# and frees the *previous* occupant the instant a new one successfully
# replaces it on that exact channel -- safe with no "notify when this
# channel finishes playing" callback because `sound_play_channel`'s
# `emit_channel_start` has *already* overwritten that channel's
# `chan_base` to the new buffer by the time the old handle is freed, so
# `sound_free`'s own "stop any channel still pointing at this buffer,
# then free" scan can find no match for the outgoing one -- nothing is
# still reading it. `SSTOP` (`op_sstop`) additionally frees and clears
# every tracked handle outright (`Cpu::free_all_sound_handles`), since
# "stop everything" leaves no channel `playing` a freed handle wouldn't
# immediately identify as unreferenced. A handle backing a still-*playing*
# loop or one-shot is never touched -- only ever a channel's superseded or
# fully-stopped former occupant -- so this closes the leak without
# reintroducing the freed-while-playing race the original leak-it
# decision was avoiding.

const SAMPLE_RATE: i32 = 44_100
const PI: f32 = 3.14159265

# ── WAV file construction ────────────────────────────────────────────────

# Canonical 44-byte PCM WAV header for `data_len` bytes of 44_100Hz/stereo/
# 16-bit PCM payload -- the exact shape `crate::codegen::audio::
# emit_sound_load` validates (see its own doc comment for the byte-offset
# table this mirrors).
fn wav_header(data_len: i32) -> Bytes:
    let mut h = Bytes()
    h.push('R' as u8)
    h.push('I' as u8)
    h.push('F' as u8)
    h.push('F' as u8)
    let riff_size = 36 + data_len
    h.push((riff_size & 255) as u8)
    h.push(((riff_size >> 8) & 255) as u8)
    h.push(((riff_size >> 16) & 255) as u8)
    h.push(((riff_size >> 24) & 255) as u8)
    h.push('W' as u8)
    h.push('A' as u8)
    h.push('V' as u8)
    h.push('E' as u8)
    h.push('f' as u8)
    h.push('m' as u8)
    h.push('t' as u8)
    h.push(' ' as u8)
    h.push(16 as u8)
    h.push(0 as u8)
    h.push(0 as u8)
    h.push(0 as u8)
    h.push(1 as u8) # AudioFormat = PCM
    h.push(0 as u8)
    h.push(2 as u8) # NumChannels = stereo
    h.push(0 as u8)
    h.push((SAMPLE_RATE & 255) as u8)
    h.push(((SAMPLE_RATE >> 8) & 255) as u8)
    h.push(((SAMPLE_RATE >> 16) & 255) as u8)
    h.push(((SAMPLE_RATE >> 24) & 255) as u8)
    let byte_rate = SAMPLE_RATE * 4 # sample_rate * channels(2) * bytes_per_sample(2)
    h.push((byte_rate & 255) as u8)
    h.push(((byte_rate >> 8) & 255) as u8)
    h.push(((byte_rate >> 16) & 255) as u8)
    h.push(((byte_rate >> 24) & 255) as u8)
    h.push(4 as u8) # BlockAlign
    h.push(0 as u8)
    h.push(16 as u8) # BitsPerSample
    h.push(0 as u8)
    h.push('d' as u8)
    h.push('a' as u8)
    h.push('t' as u8)
    h.push('a' as u8)
    h.push((data_len & 255) as u8)
    h.push(((data_len >> 8) & 255) as u8)
    h.push(((data_len >> 16) & 255) as u8)
    h.push(((data_len >> 24) & 255) as u8)
    h

# Returns `buf` with one more stereo 16-bit little-endian sample frame
# appended (`sample` in [-1, 1], `amp` already folded in). Takes `buf` by
# value and *returns* the updated buffer rather than mutating it in place
# through the parameter -- a `Bytes` parameter is a real, independent copy
# of the caller's binding (confirmed the hard way for the analogous `Cpu`-
# by-value case, see NOTES.md's "Testing"/"Four Star compiler bugs" writeup:
# "a `Cpu`-by-value parameter is a real copy... every single check silently
# failed" -- `self` is the only parameter kind this compiler pointer-passes
# mutations back through), so every call site below must reassign
# (`buf = push_frame(buf, ..)`), not call this and discard the result.
fn push_frame(buf: Bytes, sample: f32, amp: f32) -> Bytes:
    let mut b = buf
    let s16 = (clamp(sample, -1.0, 1.0) * amp) as i32
    let lo = (s16 & 255) as u8
    let hi = ((s16 >> 8) & 255) as u8
    b.push(lo)
    b.push(hi)
    b.push(lo)
    b.push(hi)
    b

# ── Waveform math ────────────────────────────────────────────────────────

# `docs/SOUND_SYSTEM.md`'s documented exponential mapping, implemented
# literally: `frequency = 55.0 * (1760.0 / 55.0) ^ (SF / 255.0)` (and
# `1760.0 / 55.0 == 32.0` exactly). SF=0 -> 55Hz and SF=255 -> 1760Hz both
# check out exactly. That same doc section also claims "SF=128 -> ~440Hz
# (A4)" -- that one doesn't actually hold for its own formula (it works out
# to ~313Hz; 440Hz needs SF=~153, and SF=128 lands almost exactly on
# `sqrt(55*1760)` =~310Hz, the geometric midpoint, not 440Hz). Verified by
# hand rather than silently "corrected" -- the formula, not the worked
# example, is what SPLAY's frequency actually has to match, and there's no
# way to satisfy both at once.
fn sf_to_freq(sf: u8) -> f32:
    55.0 * pow(32.0, (sf as f32) / 255.0)

# One sample of waveform `waveform` (SW bits 0-2) at phase `phase01` in
# [0, 1) -- everything except the memory-sample waveform (7, handled
# separately by `synth_memory_sample` since it needs the CPU's own memory,
# which this module has no access to). Silence (0) and any unrecognized
# value both yield flat zero. `pink_state` is waveform 6's one-pole IIR
# filter memory (the previous call's own output sample, `0.0` for the very
# first sample of a buffer) -- returned alongside the sample as `(sample,
# next_pink_state)` since, unlike every other waveform here, pink noise
# needs state that persists *across* calls, not just within one. Every
# other waveform passes `pink_state` through unchanged.
fn waveform_sample(waveform: u8, phase01: f32, pink_state: f32) -> (f32, f32):
    if waveform == (1 as u8): # square
        if phase01 < 0.5:
            (1.0, pink_state)
        else:
            (-1.0, pink_state)
    elif waveform == (2 as u8): # sine
        (sin(2.0 * PI * phase01), pink_state)
    elif waveform == (3 as u8): # sawtooth
        (2.0 * phase01 - 1.0, pink_state)
    elif waveform == (4 as u8): # triangle
        if phase01 < 0.5:
            (4.0 * phase01 - 1.0, pink_state)
        else:
            (3.0 - 4.0 * phase01, pink_state)
    elif waveform == (5 as u8): # white noise
        (rand() * 2.0 - 1.0, pink_state)
    elif waveform == (6 as u8): # pink noise: real one-pole 1/f-ish IIR
        # filter, matching `nova_sound.py::_generate_waveform_sample`'s own
        # `pink[i] = 0.99*pink[i-1] + 0.01*white[i]` exactly (see header).
        let white = rand() * 2.0 - 1.0
        let next_pink = 0.99 * pink_state + 0.01 * white
        (next_pink, next_pink)
    else:
        (0.0, pink_state)

# ── SPLAY: current-register-driven tone/loop synthesis ──────────────────

# A fixed-duration one-shot tone -- `SPLAY` with SW's loop bit clear.
fn synth_tone(waveform: u8, freq: f32, volume: u8, seconds: f32) -> Bytes:
    let total_samples = (seconds * (SAMPLE_RATE as f32)) as i32
    let mut buf = wav_header(total_samples * 4)
    let amp = ((volume as f32) / 255.0) * 32_000.0
    let phase_step = freq / (SAMPLE_RATE as f32)
    let mut phase = 0.0
    let mut pink_state = 0.0
    let mut i = 0
    while i < total_samples:
        let (sample, next_pink) = waveform_sample(waveform, phase - floor(phase), pink_state)
        pink_state = next_pink
        buf = push_frame(buf, sample, amp)
        phase += phase_step
        i += 1
    buf

# A period-aligned loop buffer (at least ~512 samples, an integer number of
# full periods so the loop point has no discontinuity) -- `SPLAY` with SW's
# loop bit set, played on its own dedicated hardware channel (see header).
fn synth_loop_tone(waveform: u8, freq: f32, volume: u8) -> Bytes:
    let mut period_samples = (SAMPLE_RATE as f32) / freq
    if period_samples < 1.0:
        period_samples = 1.0
    let mut periods = ceil(512.0 / period_samples) as i32
    if periods < 1:
        periods = 1
    let total_samples = (period_samples * (periods as f32)) as i32
    let mut buf = wav_header(total_samples * 4)
    let amp = ((volume as f32) / 255.0) * 32_000.0
    let phase_step = freq / (SAMPLE_RATE as f32)
    let mut phase = 0.0
    let mut pink_state = 0.0
    let mut i = 0
    while i < total_samples:
        let (sample, next_pink) = waveform_sample(waveform, phase - floor(phase), pink_state)
        pink_state = next_pink
        buf = push_frame(buf, sample, amp)
        phase += phase_step
        i += 1
    buf

# Waveform 7 (memory sample): `samples` is exactly the raw bytes `cpu.star`
# already read from `SA` (0-255 each), converted to signed float range per
# `docs/SOUND_SYSTEM.md`'s "Memory Sample Format" section, one output frame
# per input byte (a 1:1 byte-to-sample mapping -- `SF` as a distinct
# "playback rate" separate from the output sample rate is not modeled).
fn synth_memory_sample(samples: Bytes, volume: u8) -> Bytes:
    let n = samples.len()
    let mut buf = wav_header(n * 4)
    let amp = ((volume as f32) / 255.0) * 32_000.0
    let mut i = 0
    while i < n:
        let centered = ((samples[i] as f32) - 128.0) / 128.0
        buf = push_frame(buf, centered, amp)
        i += 1
    buf

# ── STRIG: fixed one-shot sound effects (docs/SOUND_SYSTEM.md's table) ──

fn synth_sweep(waveform: u8, freq_start: f32, freq_end: f32, volume: u8, seconds: f32) -> Bytes:
    let total_samples = (seconds * (SAMPLE_RATE as f32)) as i32
    let mut buf = wav_header(total_samples * 4)
    let amp = ((volume as f32) / 255.0) * 32_000.0
    let mut phase = 0.0
    let mut i = 0
    while i < total_samples:
        let t = (i as f32) / (total_samples as f32)
        let freq = freq_start + (freq_end - freq_start) * t
        phase += freq / (SAMPLE_RATE as f32) # accumulate instantaneous freq, not freq*t -- keeps phase continuous through the sweep
        # `_pink_state` discarded: `synth_sweep` is only ever called with a
        # tone-shaped waveform (never 6, pink noise -- see `trigger_effect`),
        # so there's no cross-sample filter state worth threading through.
        let (sample, _pink_state) = waveform_sample(waveform, phase - floor(phase), 0.0)
        buf = push_frame(buf, sample, amp)
        i += 1
    buf

# Explosion: pink-ish noise under a linear decay envelope.
fn synth_noise_decay(volume: u8, seconds: f32) -> Bytes:
    let total_samples = (seconds * (SAMPLE_RATE as f32)) as i32
    let mut buf = wav_header(total_samples * 4)
    let amp = ((volume as f32) / 255.0) * 32_000.0
    let mut i = 0
    while i < total_samples:
        let t = (i as f32) / (total_samples as f32)
        let envelope = 1.0 - t
        let noise = ((rand() + rand() + rand()) / 3.0) * 2.0 - 1.0
        buf = push_frame(buf, noise * envelope, amp)
        i += 1
    buf

# Jump: square wave rising then falling.
fn synth_jump(volume: u8) -> Bytes:
    let seconds = 0.25
    let total_samples = (seconds * (SAMPLE_RATE as f32)) as i32
    let mut buf = wav_header(total_samples * 4)
    let amp = ((volume as f32) / 255.0) * 32_000.0
    let mut phase = 0.0
    let mut i = 0
    while i < total_samples:
        let t = (i as f32) / (total_samples as f32)
        let mut freq = 300.0
        if t < 0.5:
            freq = 300.0 + 600.0 * (t / 0.5)
        else:
            freq = 900.0 - 700.0 * ((t - 0.5) / 0.5)
        phase += freq / (SAMPLE_RATE as f32)
        let (sample, _pink_state) = waveform_sample(1 as u8, phase - floor(phase), 0.0)
        buf = push_frame(buf, sample, amp)
        i += 1
    buf

# Two sequential flat tones (rising/falling *edge*, not a sweep) -- Coin
# Pickup's documented "two-tone ascending (E5, A5)".
fn synth_two_tone(freq1: f32, freq2: f32, volume: u8, seconds_each: f32) -> Bytes:
    let total_each = (seconds_each * (SAMPLE_RATE as f32)) as i32
    let total_samples = total_each * 2
    let mut buf = wav_header(total_samples * 4)
    let amp = ((volume as f32) / 255.0) * 32_000.0
    let mut phase = 0.0
    let mut i = 0
    while i < total_samples:
        let mut freq = freq1
        if i >= total_each:
            freq = freq2
        phase += freq / (SAMPLE_RATE as f32)
        let (sample, _pink_state) = waveform_sample(2 as u8, phase - floor(phase), 0.0)
        buf = push_frame(buf, sample, amp)
        i += 1
    buf

# Power-up: ascending 4-note arpeggio (C5, E5, G5, C6).
fn synth_arpeggio(volume: u8) -> Bytes:
    let seconds_each = 0.08
    let total_each = (seconds_each * (SAMPLE_RATE as f32)) as i32
    let total_samples = total_each * 4
    let mut buf = wav_header(total_samples * 4)
    let amp = ((volume as f32) / 255.0) * 32_000.0
    let mut phase = 0.0
    let mut i = 0
    while i < total_samples:
        let note_idx = i / total_each
        let mut freq = 523.25
        if note_idx == 0:
            freq = 523.25
        elif note_idx == 1:
            freq = 659.26
        elif note_idx == 2:
            freq = 783.99
        else:
            freq = 1046.5
        phase += freq / (SAMPLE_RATE as f32)
        let (sample, _pink_state) = waveform_sample(2 as u8, phase - floor(phase), 0.0)
        buf = push_frame(buf, sample, amp)
        i += 1
    buf

# ── Playback glue ────────────────────────────────────────────────────────

fn temp_dir() -> str:
    let d = env_get("TEMP")
    if len(d) == 0:
        "."
    else:
        d

fn loop_temp_path() -> str:
    f"{temp_dir()}\\nova16_synth_loop.wav"

fn effect_temp_path() -> str:
    f"{temp_dir()}\\nova16_synth_effect.wav"

# Third fixed temp path, dedicated to `SMIX`/`SECHO`/`SREVERB`/`SFILTER`
# (`todo.md` P2 #4) so a channel-effect re-trigger can never race the
# `SPLAY`/`STRIG` temp paths above -- same "safe to reuse, `sound_load` fully
# reads the file into its own independent buffer before returning" reasoning
# as `loop_temp_path`/`effect_temp_path` (see this file's header comment).
fn fx_temp_path() -> str:
    f"{temp_dir()}\\nova16_synth_fx.wav"

# Writes `wav` to `path`, loads it back, and starts playback on the exact
# mixer channel `channel` (`crate::codegen::audio::sound_play_channel`) --
# `looped` matches SW's own loop bit, `channel` is either one of Nova's 8
# hardware voices (`SPLAY`) or the STRIG one-shot pool's current rotating
# slot (`Cpu::next_strig_channel`) -- see this file's header comment for
# why sharing these two fixed temp paths across every channel stays safe.
# `null_ptr()` (checked with `is_null`, same "never crash, just don't make
# sound" convention as every other loader builtin in this codebase) if the
# temp file couldn't be written or the roundtrip failed to load back as
# valid audio; otherwise the live `sound_load`d handle now playing on
# `channel` -- the caller (`cpu_sound.star`) is responsible for freeing
# whatever handle previously occupied that channel once this one
# successfully replaces it (see this file's header comment, "todo.md P2
# #3").
# `looped` defaults to `false` (new in Star after this file was written) --
# every `STRIG`/one-shot-effect call site below plays a non-looping buffer;
# only `play_tone`/`play_memory_sample`'s own loop branch needs `true`.
fn play_pcm_wav_on_channel(path: str, wav: Bytes, channel: u8, looped: bool = false) -> ptr:
    let fh = file_open(path, "wb")
    if is_null(fh):
        return null_ptr()
    let wrote = file_write_bytes(fh, wav)
    file_close(fh)
    if !wrote:
        return null_ptr()
    let handle = sound_load(path)
    if is_null(handle):
        return null_ptr()
    sound_play_channel(handle, channel as i32, looped)
    handle

# `cpu.star::op_splay`'s entry point for waveforms 1-6 (tone-shaped).
# `channel` is `SW`'s own decoded channel-select bits (3-5). Returns
# `(handle, wav)`: the new handle now playing on `channel` (or `null_ptr()`
# on failure, see `play_pcm_wav_on_channel`'s own doc comment), *and* the raw
# synthesized WAV bytes -- `cpu_sound.star::op_splay` caches the latter into
# `Cpu::sound_channel_last_wav` (`todo.md` P2 #4) so `SECHO`/`SREVERB`/
# `SFILTER`/`SMIX` have real dry audio to process later; see
# `cpu_sound.star`'s header comment for why that cache, not a "read back the
# live mixer buffer" builtin, is this project's answer to those four opcodes
# having no reference implementation to match.
fn play_tone(waveform: u8, freq: f32, volume: u8, looped: bool, channel: u8) -> (ptr, Bytes):
    if looped:
        let wav = synth_loop_tone(waveform, freq, volume)
        (play_pcm_wav_on_channel(loop_temp_path(), wav, channel, true), wav)
    else:
        let wav = synth_tone(waveform, freq, volume, 0.005)
        (play_pcm_wav_on_channel(effect_temp_path(), wav, channel), wav)

# `cpu.star::op_splay`'s entry point for waveform 7 (memory sample). Same
# "new handle or `null_ptr()`, plus the raw wav" return as `play_tone`.
fn play_memory_sample(samples: Bytes, volume: u8, looped: bool, channel: u8) -> (ptr, Bytes):
    let wav = synth_memory_sample(samples, volume)
    if looped:
        (play_pcm_wav_on_channel(loop_temp_path(), wav, channel, true), wav)
    else:
        (play_pcm_wav_on_channel(effect_temp_path(), wav, channel), wav)

# `cpu.star::op_strig`'s entry point -- `effect` is STRIG's operand value
# clamped/wrapped to the documented 0-7 range by the caller, `channel` is
# `Cpu::next_strig_channel`'s current rotating slot (8-15, see header). Same
# "new handle or `null_ptr()`" return as `play_tone`.
fn trigger_effect(effect: u8, volume: u8, channel: u8) -> ptr:
    if effect == (0 as u8): # Simple Beep
        play_pcm_wav_on_channel(effect_temp_path(), synth_tone(2 as u8, 800.0, volume, 0.15), channel)
    elif effect == (1 as u8): # Rising Tone
        play_pcm_wav_on_channel(effect_temp_path(), synth_sweep(2 as u8, 300.0, 1200.0, volume, 0.3), channel)
    elif effect == (2 as u8): # Falling Tone
        play_pcm_wav_on_channel(effect_temp_path(), synth_sweep(2 as u8, 1200.0, 300.0, volume, 0.3), channel)
    elif effect == (3 as u8): # Explosion
        play_pcm_wav_on_channel(effect_temp_path(), synth_noise_decay(volume, 0.6), channel)
    elif effect == (4 as u8): # Laser Shot
        play_pcm_wav_on_channel(effect_temp_path(), synth_sweep(1 as u8, 1500.0, 200.0, volume, 0.25), channel)
    elif effect == (5 as u8): # Jump
        play_pcm_wav_on_channel(effect_temp_path(), synth_jump(volume), channel)
    elif effect == (6 as u8): # Coin Pickup (E5, A5)
        play_pcm_wav_on_channel(effect_temp_path(), synth_two_tone(659.26, 880.0, volume, 0.09), channel)
    else: # Power-up (effect == 7, and any out-of-range value clamps here)
        play_pcm_wav_on_channel(effect_temp_path(), synth_arpeggio(volume), channel)

# `SSTOP` -- see this file's header comment for why "stop everything" is the
# only meaning this port's no-operand `SSTOP` has. Still `sound_stop_all()`
# (every mixer channel, not just Nova's own 0-15 range -- there is no
# channel 16+ anything else in this project could be using anyway) plus
# `music_stop()`; the latter is now redundant with the former (channel 0 is
# just another Nova hardware channel, already covered by `sound_stop_all`'s
# full sweep) but kept for clarity/no behavior change from before this round.
fn stop_all():
    sound_stop_all()
    music_stop()

# ── SMIX/SECHO/SREVERB/SFILTER: post-synthesis channel effects (todo.md P2
# #4) ─────────────────────────────────────────────────────────────────────
#
# Unlike `SPLAY`/`SSTOP`/`STRIG` above, these four have **no reference
# implementation to match**: the upstream Python `opcodes.py` marks all four
# `# unimplemented` too (no handler there either), which is exactly why
# earlier cycles left them alone rather than inventing bug-for-bug-unmatchable
# behavior. Closing them out for real means designing genuine DSP from
# scratch -- the design below, and why it fits this project's existing
# architecture instead of requiring new native code:
#
# - This port's whole `SPLAY`/`STRIG` model is "synthesize a complete WAV
#   buffer in Star, write it to a temp file, `sound_load` it back, play it"
#   (see this file's own header comment) -- `crate::codegen::audio`'s mixer
#   has no "read back the raw samples of a currently-playing/already-loaded
#   channel" builtin, and adding one would mean new native codegen work, a
#   materially bigger and more invasive change than four fantasy-console
#   opcodes call for.
# - So instead, `Cpu::sound_channel_last_wav` (`cpu.star`) caches the raw,
#   still-dry WAV buffer `op_splay` most recently synthesized for each of
#   Nova's 8 addressable hardware channels (0-7 -- the same channels `SW`'s
#   channel-select bits name, *not* `STRIG`'s ephemeral 8-15 one-shot pool,
#   which fires-and-forgets with nothing stable worth applying an effect to
#   afterward). `SECHO`/`SREVERB`/`SFILTER ch, param` read that cache,
#   process it with the functions below, and re-trigger playback of the
#   *processed* buffer on the same channel via the existing
#   `play_pcm_wav_on_channel` -- an immediate "apply this to what's on the
#   channel right now" semantics, matching `docs/nova16_instruction_
#   reference.md`'s present-tense "Applies echo"/"Applies reverb"/"Applies
#   filter" wording more literally than a "sets a param for next time"
#   design would. `SMIX output` mixes all 8 cached buffers down (simple
#   average, so a single active channel isn't quietened by silent ones) and
#   plays the result on `output`, which also becomes that channel's new
#   cached buffer -- so `SMIX` output can itself be chained into a further
#   `SECHO`/`SREVERB`/`SFILTER`.
# - All three effects and the mixer operate directly on WAV sample bytes
#   (`wav_sample_at`/`push_frame_amp` below invert/mirror `push_frame`'s own
#   byte encoding), not on the normalized `[-1, 1]` domain `push_frame`
#   itself takes -- the cached buffer is already volume-scaled at synthesis
#   time, and there's no reason to re-derive an original "sample before
#   volume" that was never kept separately.
# - `apply_filter`'s one-pole low/high/band-pass IIR deliberately reuses the
#   same "one-pole running filter" shape `waveform_sample`'s own pink-noise
#   case already established (`0.99*prev + 0.01*new`-style state carried
#   sample to sample) -- consistent math, not a new technique introduced
#   just for this.
# - Every operand/type value here clamps into its valid range the same way
#   `trigger_effect`'s own `effect` operand already does ("any out-of-range
#   value clamps here") -- there is no invalid input that crashes rather
#   than silently doing something reasonable, matching this whole file's
#   established "never crash, just don't make sound" convention.

# Number of live PCM sample frames in a WAV buffer built by `wav_header`
# (44-byte canonical header, 4 bytes/frame -- see `wav_header`'s own doc
# comment). `<= 0` (header-only or absent) means "nothing to process".
fn wav_sample_count(wav: Bytes) -> i32:
    (wav.len() - 44) / 4

# Inverse of `push_frame`'s own encoding: the signed 16-bit amplitude
# (roughly `[-32_000, 32_000]`, already volume-scaled -- *not* renormalized
# back to `[-1, 1]`) of sample frame `i`, or `0.0` (silence) if `i` falls
# outside `[0, wav_sample_count(wav))`. Only the left channel is read back
# since `push_frame` always writes identical left/right samples.
fn wav_sample_at(wav: Bytes, i: i32) -> f32:
    let n = wav_sample_count(wav)
    if i < 0 or i >= n:
        return 0.0
    let off = 44 + i * 4
    let lo = wav[off] as i32
    let hi = wav[off + 1] as i32
    let mut s16 = (hi << 8) | lo
    s16 = s16 & 0xFFFF
    if s16 >= 32_768:
        s16 = s16 - 65_536
    s16 as f32

# Appends one stereo 16-bit little-endian frame from an already-amplitude-
# scaled sample (as `wav_sample_at` returns, *not* normalized `[-1, 1]` --
# unlike `push_frame`, which takes a normalized sample and multiplies by
# `amp` itself). Same "takes `buf` by value, returns the updated buffer"
# shape as `push_frame`, for the same reason (see that function's own doc
# comment) -- every call site below must reassign.
fn push_frame_amp(buf: Bytes, amplitude: f32) -> Bytes:
    let mut b = buf
    let clamped = clamp(amplitude, -32_000.0, 32_000.0)
    let s16 = clamped as i32
    let lo = (s16 & 255) as u8
    let hi = ((s16 >> 8) & 255) as u8
    b.push(lo)
    b.push(hi)
    b.push(lo)
    b.push(hi)
    b

# `SECHO channel, delay` -- two decaying echo taps from the dry source
# (`delay` maps 0-255 onto 20ms-500ms; a fixed 0.45 decay per tap, matching
# `trigger_effect`'s own "fixed decay envelope" style elsewhere in this
# file). Output is padded with two extra `delay_samples` of tail so the
# echo isn't truncated.
fn apply_echo(wav: Bytes, delay_byte: u8) -> Bytes:
    let n = wav_sample_count(wav)
    if n <= 0:
        return wav
    let delay_ms = 20.0 + ((delay_byte as f32) / 255.0) * 480.0
    let mut delay_samples = ((delay_ms / 1000.0) * (SAMPLE_RATE as f32)) as i32
    if delay_samples < 1:
        delay_samples = 1
    let decay = 0.45
    let total = n + delay_samples * 2
    let mut buf = wav_header(total * 4)
    let mut i = 0
    while i < total:
        let dry = wav_sample_at(wav, i)
        let echo1 = wav_sample_at(wav, i - delay_samples) * decay
        let echo2 = wav_sample_at(wav, i - delay_samples * 2) * decay * decay
        buf = push_frame_amp(buf, dry + echo1 + echo2)
        i += 1
    buf

# `SREVERB channel, amount` -- a small fixed 4-tap comb reverb (taps at
# 30/50/80/130ms, decreasing per-tap gain), each tap additionally scaled by
# `amount` (0-255 -> 0.0-1.0) so `amount=0` reduces to the dry signal
# unchanged and `amount=255` is the reverb at full strength.
fn apply_reverb(wav: Bytes, amount_byte: u8) -> Bytes:
    let n = wav_sample_count(wav)
    if n <= 0:
        return wav
    let amt = (amount_byte as f32) / 255.0
    let tap1 = (0.03 * (SAMPLE_RATE as f32)) as i32
    let tap2 = (0.05 * (SAMPLE_RATE as f32)) as i32
    let tap3 = (0.08 * (SAMPLE_RATE as f32)) as i32
    let tap4 = (0.13 * (SAMPLE_RATE as f32)) as i32
    let total = n + tap4 + 1
    let mut buf = wav_header(total * 4)
    let mut i = 0
    while i < total:
        let dry = wav_sample_at(wav, i)
        let r1 = wav_sample_at(wav, i - tap1) * amt * 0.6
        let r2 = wav_sample_at(wav, i - tap2) * amt * 0.4
        let r3 = wav_sample_at(wav, i - tap3) * amt * 0.3
        let r4 = wav_sample_at(wav, i - tap4) * amt * 0.2
        buf = push_frame_amp(buf, dry + r1 + r2 + r3 + r4)
        i += 1
    buf

# `SFILTER channel, type` -- a one-pole low-pass (`type=0`), the
# complementary high-pass (`type=1`, `dry - lowpass`), or a low-pass-of-the-
# high-pass band-pass (`type=2`), all sharing one fixed-`alpha` IIR stage
# (same "one-pole running filter" shape as `waveform_sample`'s own pink-noise
# case). Any other `type` value (3+) passes the signal through unchanged --
# same "out-of-range clamps to a safe default" convention as
# `trigger_effect`'s own `effect` operand.
fn apply_filter(wav: Bytes, filter_type: u8) -> Bytes:
    let n = wav_sample_count(wav)
    if n <= 0:
        return wav
    let mut buf = wav_header(n * 4)
    let alpha = 0.3
    let mut lp_state = 0.0
    let mut bp_state = 0.0
    let mut i = 0
    while i < n:
        let x = wav_sample_at(wav, i)
        let next_lp = lp_state + alpha * (x - lp_state)
        let hp = x - next_lp
        lp_state = next_lp
        let next_bp = bp_state + alpha * (hp - bp_state)
        bp_state = next_bp
        let mut y = x
        if filter_type == (0 as u8):
            y = next_lp
        elif filter_type == (1 as u8):
            y = hp
        elif filter_type == (2 as u8):
            y = next_bp
        buf = push_frame_amp(buf, y)
        i += 1
    buf

# `SMIX output` -- averages every non-empty buffer in `bufs` (`Cpu::
# sound_channel_last_wav`, one entry per hardware channel 0-7) sample by
# sample, out to the longest buffer's own length (shorter buffers contribute
# silence past their own end, via `wav_sample_at`'s own out-of-range-is-0.0
# behavior). Averaging by the *count of non-empty channels*, not a fixed 8,
# means a single active channel mixed alone isn't quietened by seven silent
# ones. An empty `Bytes` result (header-only, `wav_header(0)`) means "no
# channel had anything cached" -- the caller checks `wav_sample_count(..) >
# 0` before playing it, same convention as every other "don't crash, just
# don't make sound" case in this file.
fn mix_wavs(bufs: List<Bytes>) -> Bytes:
    let mut max_n = 0
    let mut count = 0
    let mut i = 0
    while i < bufs.len():
        let n = wav_sample_count(bufs[i])
        if n > 0:
            count += 1
            if n > max_n:
                max_n = n
        i += 1
    if count == 0 or max_n == 0:
        return wav_header(0)
    let mut buf = wav_header(max_n * 4)
    let inv_count = 1.0 / (count as f32)
    let mut s = 0
    while s < max_n:
        let mut sum = 0.0
        let mut j = 0
        while j < bufs.len():
            sum += wav_sample_at(bufs[j], s)
            j += 1
        buf = push_frame_amp(buf, sum * inv_count)
        s += 1
    buf
