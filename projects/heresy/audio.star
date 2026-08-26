# Heresy -- procedural WAV generation and playback.
#
# Why this module exists: the game needs sound effects and a looping ambient
# track, but Star has no audio *synthesis* builtin -- only `sound_load(path)`
# (which reads a 16-bit/44100Hz/stereo PCM WAV off disk) and the
# `sound_play`/`music_play` mixer. Rather than ship binary WAV assets (which
# would be opaque blobs this dogfood can't inspect or edit), this module
# *synthesizes* every sound as raw PCM samples in a `Bytes` buffer, writes
# each to a canonical 44-byte-header WAV file via `file_write_bytes` (the
# binary-safe sibling of `file_write`, which is NUL-terminated and would
# silently truncate a buffer containing a 0x00 byte), and hands the result
# to `sound_load`. This exercises the binary file-I/O path, the `Bytes`
# buffer API, and the audio mixer all in one real feature.
#
# The WAV format written here is exactly the canonical minimal shape
# `sound_load` accepts: 16-bit, 44100Hz, stereo PCM, `fmt ` chunk
# immediately followed by `data`. Each sample is a signed 16-bit little-
# endian value; stereo means two samples per frame (left, right).

const SAMPLE_RATE: i32 = 44100

# Write a 16-bit little-endian value into a Bytes buffer, returning the
# (possibly copy-on-write-replaced) buffer. `Bytes` is copy-on-write like
# `List<T>` -- mutating a by-value parameter inside this function would only
# affect the local copy, not the caller's binding, so the caller must
# reassign the returned buffer (`header = push_i16(header, v)`).
fn push_i16(buf: Bytes, v: i32) -> Bytes:
    let lo = v & 0xFF
    let hi = (v >> 8) & 0xFF
    let mut out = buf
    out.push(lo as u8)
    out.push(hi as u8)
    return out

# Write a canonical 44-byte-header WAV file containing `samples` (a Bytes
# buffer of interleaved 16-bit stereo PCM) to `path`.
fn write_wav(path: str, samples: Bytes):
    let f = file_open(path, "w")
    if is_null(f):
        return
    let mut header = Bytes()
    # "RIFF"
    header.push(82 as u8)
    header.push(73 as u8)
    header.push(70 as u8)
    header.push(70 as u8)
    # chunk size = 36 + data size
    let data_size = samples.len()
    header = push_i16(header, (36 + data_size) & 0xFFFF)
    header = push_i16(header, ((36 + data_size) >> 16) & 0xFFFF)
    # "WAVE"
    header.push(87 as u8)
    header.push(65 as u8)
    header.push(86 as u8)
    header.push(69 as u8)
    # "fmt "
    header.push(102 as u8)
    header.push(109 as u8)
    header.push(116 as u8)
    header.push(32 as u8)
    # fmt chunk size = 16
    header = push_i16(header, 16)
    header = push_i16(header, 0)
    # audio format = 1 (PCM)
    header = push_i16(header, 1)
    header = push_i16(header, 0)
    # channels = 2
    header = push_i16(header, 2)
    header = push_i16(header, 0)
    # sample rate = 44100
    header = push_i16(header, SAMPLE_RATE & 0xFFFF)
    header = push_i16(header, (SAMPLE_RATE >> 16) & 0xFFFF)
    # byte rate = sample_rate * channels * 2
    let byte_rate = SAMPLE_RATE * 2 * 2
    header = push_i16(header, byte_rate & 0xFFFF)
    header = push_i16(header, (byte_rate >> 16) & 0xFFFF)
    # block align = channels * 2
    header = push_i16(header, 4)
    header = push_i16(header, 0)
    # bits per sample = 16
    header = push_i16(header, 16)
    header = push_i16(header, 0)
    # "data"
    header.push(100 as u8)
    header.push(97 as u8)
    header.push(116 as u8)
    header.push(97 as u8)
    # data chunk size
    header = push_i16(header, data_size & 0xFFFF)
    header = push_i16(header, (data_size >> 16) & 0xFFFF)
    file_write_bytes(f, header)
    file_write_bytes(f, samples)
    file_close(f)

# Synthesize a short "laser zap" for the starbolt: a descending square-wave
# sweep, ~0.12s.
fn synth_zap() -> Bytes:
    let mut buf = Bytes()
    let n = SAMPLE_RATE / 8
    let mut i = 0
    while i < n:
        let t = (i as f32) / (n as f32)
        let freq = 1200.0 - t * 900.0
        let phase = (i as f32) * freq / SAMPLE_RATE as f32
        let mut v = 0.0
        if (phase as i32) % 2 == 0:
            v = 0.5
        else:
            v = -0.5
        let amp = 0.4 * (1.0 - t)
        let sample = (v * amp * 32767.0) as i32
        buf = push_i16(buf, sample)
        buf = push_i16(buf, sample)
        i += 1
    return buf

# Synthesize a low "growl" for an imp hit: a 90Hz sawtooth with a quick
# decay, ~0.2s.
fn synth_growl() -> Bytes:
    let mut buf = Bytes()
    let n = SAMPLE_RATE / 5
    let mut i = 0
    while i < n:
        let t = (i as f32) / (n as f32)
        let phase = (i as f32) * 90.0 / SAMPLE_RATE as f32
        let frac = phase - (phase as i32) as f32
        let v = frac * 2.0 - 1.0
        let amp = 0.5 * (1.0 - t)
        let sample = (v * amp * 32767.0) as i32
        buf = push_i16(buf, sample)
        buf = push_i16(buf, sample)
        i += 1
    return buf

# Synthesize a bright "pickup" chime: two quick sine tones, ~0.15s.
fn synth_pickup() -> Bytes:
    let mut buf = Bytes()
    let n = SAMPLE_RATE / 7
    let mut i = 0
    while i < n:
        let t = (i as f32) / (n as f32)
        let freq = if t < 0.5: 880.0 else: 1320.0
        let phase = (i as f32) * freq / SAMPLE_RATE as f32
        let v = sin(phase * 6.2831853)
        let amp = 0.35 * (1.0 - t)
        let sample = (v * amp * 32767.0) as i32
        buf = push_i16(buf, sample)
        buf = push_i16(buf, sample)
        i += 1
    return buf

# Synthesize a low ambient drone for looping music: a 55Hz sine with a slow
# 0.5Hz amplitude wobble, ~2s.
fn synth_drone() -> Bytes:
    let mut buf = Bytes()
    let n = SAMPLE_RATE * 2
    let mut i = 0
    while i < n:
        let t = (i as f32) / (n as f32)
        let phase = (i as f32) * 55.0 / SAMPLE_RATE as f32
        let v = sin(phase * 6.2831853)
        let wobble = 0.5 + 0.5 * sin(t * 3.1415927)
        let amp = 0.25 * wobble
        let sample = (v * amp * 32767.0) as i32
        buf = push_i16(buf, sample)
        buf = push_i16(buf, sample)
        i += 1
    return buf

struct Sounds:
    zap: ptr
    growl: ptr
    pickup: ptr
    drone: ptr

# Generate all four WAV files and load them. Returns a Sounds struct with
# null handles for any that failed to load.
fn make_sounds() -> Sounds:
    write_wav("heresy_zap.wav", synth_zap())
    write_wav("heresy_growl.wav", synth_growl())
    write_wav("heresy_pickup.wav", synth_pickup())
    write_wav("heresy_drone.wav", synth_drone())
    return Sounds(
        zap = sound_load("heresy_zap.wav"),
        growl = sound_load("heresy_growl.wav"),
        pickup = sound_load("heresy_pickup.wav"),
        drone = sound_load("heresy_drone.wav"),
    )