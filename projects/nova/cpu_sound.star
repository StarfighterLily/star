# Nova-16 CPU: sound opcode handlers (SPLAY/SSTOP/STRIG,
# docs/SOUND_SYSTEM.md; sound.star) -- split out of `cpu.star` (todo.md
# P2 #5). See `cpu_data.star`'s header comment for the full rationale (pure
# code motion, no behavior change) and why this `import "cpu.star" as cpu`
# isn't circular. `snd::play_tone`/`play_memory_sample`/`stop_all`/
# `trigger_effect`/`sf_to_freq` are `sound.star`'s own real waveform-
# synthesis/playback entry points (`todo.md` P0 #1's own work), qualified
# here exactly as `cpu.star` itself always wrote them.
import "cpu.star" as cpu
import "sound.star" as snd

impl cpu::Cpu:
    # ── Sound (docs/SOUND_SYSTEM.md; sound.star) -- todo.md P0 #1 ─────────
    # `SA`/`SF`/`SV`/`SW` are already plain readable/writable registers (via
    # `MOV`/etc., through the same register-code map as everything else).
    # `SPLAY`/`SSTOP`/`STRIG` drive real waveform synthesis and playback
    # through `sound.star` -- see that file's header comment for the
    # WAV-file-roundtrip approach (`sound_load`/`sound_play_channel` have no
    # "play these raw in-memory samples" entry point) and for
    # `replace_channel_handle`/`free_all_sound_handles` below, which free
    # each channel's previously-loaded handle instead of leaking it
    # (`todo.md` P2 #3). `SW`'s channel-select bits (3-5)
    # are decoded below and threaded all the way through to
    # `sound_play_channel` (todo.md P2 #5) -- a true 8-independent-voice
    # model, not the collapsed "one loop channel + one shared pool" this
    # used to be; see `sound.star`'s own header comment for the full
    # writeup. `SMIX`/`SECHO`/`SREVERB`/`SFILTER` are now real too
    # (`todo.md` P2 #4) -- unlike everything else in this file, they have no
    # reference implementation to match at all (`opcodes.py` marks all four
    # `# unimplemented`), so `sound.star`'s own "SMIX/SECHO/SREVERB/SFILTER"
    # header section is where the actual DSP design (and why it's a
    # deliberate Star-original answer rather than a gap) lives; `op_smix`/
    # `op_secho`/`op_sreverb`/`op_sfilter` below are just the CPU-state glue
    # around it, the same role `op_splay`/`op_strig` already play for
    # `sound.star`'s synthesis functions.
    fn op_splay(mut self):
        let sw_val = self.sw as u8
        let enabled = bit_get(sw_val, 7)
        let looped = bit_get(sw_val, 6)
        let waveform = sw_val & (7 as u8)
        let channel = (sw_val >> 3) & (7 as u8)
        if enabled and waveform != (0 as u8):
            let volume = self.sv as u8
            let mut new_handle = null_ptr()
            let mut new_wav = Bytes()
            if waveform == (7 as u8):
                # Memory sample: read the documented max 1024 bytes straight
                # from `SA` into a fresh `Bytes` (`self.mem` isn't reachable
                # from `sound.star`, which has no `Cpu` access at all) --
                # `synth_memory_sample` does the byte->signed-float
                # conversion.
                let mut samples = Bytes()
                let sa_val = (self.sa as u16) as i32
                let mut k = 0
                while k < 1024:
                    samples.push(self.mem.read_byte(cpu::wrap_addr(sa_val + k)))
                    k += 1
                let (h, w) = snd::play_memory_sample(samples, volume, looped, channel)
                new_handle = h
                new_wav = w
            else:
                let freq = snd::sf_to_freq(self.sf as u8)
                let (h, w) = snd::play_tone(waveform, freq, volume, looped, channel)
                new_handle = h
                new_wav = w
            self.replace_channel_handle(channel, new_handle)
            # `todo.md` P2 #4: cache the dry buffer this channel now holds so
            # a later `SECHO`/`SREVERB`/`SFILTER`/`SMIX` has real audio to
            # process -- only on success, matching `replace_channel_handle`'s
            # own "a failed retrigger leaves the previous occupant untouched"
            # rule (see `sound.star`'s "SMIX/SECHO/SREVERB/SFILTER" header
            # section for the full design).
            if !is_null(new_handle):
                self.sound_channel_last_wav[channel as i32] = new_wav

    # SSTOP has no operand in this port's ISA (0 operands per
    # `docs/nova16_instruction_reference.md`, unlike the upstream reference's
    # `SSTOP`/`SSTOP reg` split) -- always "stop everything", see
    # `sound.star::stop_all`'s own doc comment. Also frees every tracked
    # handle (`todo.md` P2 #3): once every channel is stopped, nothing is
    # still reading any of them.
    fn op_sstop(mut self):
        snd::stop_all()
        self.free_all_sound_handles()

    # `STRIG` has no channel-select bits in either the reference or this
    # port's own ISA -- it's a fire-and-forget effect trigger, not one of
    # the 8 addressable `SPLAY` voices (see `sound.star`'s header comment).
    # `next_strig_channel` round-robins mixer channels 8-15 (Nova's own 8
    # hardware channels live at 0-7) so overlapping `STRIG` calls layer
    # instead of cutting each other off, without ever contending with a
    # `SPLAY` voice's own fixed channel.
    fn op_strig(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let v = self.operand_read(op1, 8)
        let volume = self.sv as u8
        let channel = self.next_strig_channel
        self.next_strig_channel += 1
        if self.next_strig_channel > 15:
            self.next_strig_channel = 8
        let new_handle = snd::trigger_effect(v as u8, volume, channel as u8)
        self.replace_channel_handle(channel as u8, new_handle)

    # Shared by `op_splay`/`op_strig` (`todo.md` P2 #3): if `new_handle` is
    # non-null (playback actually started), free whatever handle previously
    # occupied `channel` -- safe because `sound_play_channel` has already
    # overwritten that channel's `chan_base` to `new_handle`'s data by the
    # time this runs, so `sound_free`'s own "stop any channel still using
    # this buffer" scan finds no match for the outgoing handle -- and record
    # `new_handle` as the channel's new occupant. A `null_ptr()` new_handle
    # (the underlying `sound_load` roundtrip failed) leaves the channel's
    # previous occupant, still playing, untouched.
    fn replace_channel_handle(mut self, channel: u8, new_handle: ptr):
        if !is_null(new_handle):
            let old_handle = self.sound_channel_handles[channel as i32]
            if !is_null(old_handle):
                sound_free(old_handle)
            self.sound_channel_handles[channel as i32] = new_handle

    # Frees every mixer channel's currently-tracked handle and clears the
    # array (`todo.md` P2 #3) -- shared by `op_sstop` (stop everything, so
    # nothing is holding onto any of them anymore) and `Cpu::reinit`
    # (`main.star`: `Reset` must not silently leak every handle still
    # sitting in the array when the rest of the emulator's state is wiped
    # out from under it). Also resets `sound_channel_last_wav` (`todo.md` P2
    # #4): once every channel is stopped/reset there's nothing left for a
    # later `SECHO`/`SREVERB`/`SFILTER`/`SMIX` to process.
    fn free_all_sound_handles(mut self):
        let mut i = 0
        while i < 16:
            let h = self.sound_channel_handles[i]
            if !is_null(h):
                sound_free(h)
                self.sound_channel_handles[i] = null_ptr()
            i += 1
        self.sound_channel_last_wav = cpu::new_channel_wav_cache()

    # `SMIX output` -- mixes the dry buffers `sound_channel_last_wav` has
    # cached for all 8 hardware channels down to one (`sound.star::mix_wavs`)
    # and plays the result on `output` (masked to 0-7, Nova's own
    # addressable-channel range -- see `sound.star`'s "SMIX/SECHO/SREVERB/
    # SFILTER" header section for the full design). A completely empty mix
    # (no channel has ever cached anything) leaves `output` untouched rather
    # than replacing it with silence, the same "don't crash, don't clobber a
    # still-valid channel over nothing" convention `replace_channel_handle`
    # already follows for a failed `sound_load` roundtrip.
    fn op_smix(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let out_channel = (self.operand_read(op1, 8) as u8) & (7 as u8)
        let mixed = snd::mix_wavs(self.sound_channel_last_wav)
        if snd::wav_sample_count(mixed) > 0:
            let new_handle = snd::play_pcm_wav_on_channel(snd::fx_temp_path(), mixed, out_channel, false)
            self.replace_channel_handle(out_channel, new_handle)
            if !is_null(new_handle):
                self.sound_channel_last_wav[out_channel as i32] = mixed

    # `SECHO channel, delay` -- applies `sound.star::apply_echo` to
    # `channel`'s cached dry buffer and re-triggers playback of the result on
    # that same channel. A channel with nothing cached (never `SPLAY`ed, or
    # stopped/reset since) is left untouched -- there is nothing to echo.
    fn op_secho(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let channel = (self.operand_read(op1, 8) as u8) & (7 as u8)
        let delay = self.operand_read(op2, 8) as u8
        let src = self.sound_channel_last_wav[channel as i32]
        if snd::wav_sample_count(src) > 0:
            let processed = snd::apply_echo(src, delay)
            let new_handle = snd::play_pcm_wav_on_channel(snd::fx_temp_path(), processed, channel, false)
            self.replace_channel_handle(channel, new_handle)
            if !is_null(new_handle):
                self.sound_channel_last_wav[channel as i32] = processed

    # `SREVERB channel, amount` -- same shape as `op_secho`, via
    # `sound.star::apply_reverb`.
    fn op_sreverb(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let channel = (self.operand_read(op1, 8) as u8) & (7 as u8)
        let amount = self.operand_read(op2, 8) as u8
        let src = self.sound_channel_last_wav[channel as i32]
        if snd::wav_sample_count(src) > 0:
            let processed = snd::apply_reverb(src, amount)
            let new_handle = snd::play_pcm_wav_on_channel(snd::fx_temp_path(), processed, channel, false)
            self.replace_channel_handle(channel, new_handle)
            if !is_null(new_handle):
                self.sound_channel_last_wav[channel as i32] = processed

    # `SFILTER channel, type` -- same shape as `op_secho`, via
    # `sound.star::apply_filter`.
    fn op_sfilter(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let channel = (self.operand_read(op1, 8) as u8) & (7 as u8)
        let filter_type = self.operand_read(op2, 8) as u8
        let src = self.sound_channel_last_wav[channel as i32]
        if snd::wav_sample_count(src) > 0:
            let processed = snd::apply_filter(src, filter_type)
            let new_handle = snd::play_pcm_wav_on_channel(snd::fx_temp_path(), processed, channel, false)
            self.replace_channel_handle(channel, new_handle)
            if !is_null(new_handle):
                self.sound_channel_last_wav[channel as i32] = processed

