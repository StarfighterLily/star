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
    # "play these raw in-memory samples" entry point) and its documented
    # simplifications (leaked WAV handles). `SW`'s channel-select bits (3-5)
    # are decoded below and threaded all the way through to
    # `sound_play_channel` (todo.md P2 #5) -- a true 8-independent-voice
    # model, not the collapsed "one loop channel + one shared pool" this
    # used to be; see `sound.star`'s own header comment for the full
    # writeup. `SMIX`/`SECHO`/`SREVERB`/`SFILTER` are still left
    # unimplemented: the reference's own `opcodes.py` marks them
    # "unimplemented" too (no handler exists there either), so leaving them
    # unimplemented here stays a bug-for-bug match rather than a gap
    # `sound.star` should invent its own answer for.
    fn op_splay(mut self):
        let sw_val = self.sw as u8
        let enabled = bit_get(sw_val, 7)
        let looped = bit_get(sw_val, 6)
        let waveform = sw_val & (7 as u8)
        let channel = (sw_val >> 3) & (7 as u8)
        if enabled and waveform != (0 as u8):
            let volume = self.sv as u8
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
                snd::play_memory_sample(samples, volume, looped, channel)
            else:
                let freq = snd::sf_to_freq(self.sf as u8)
                snd::play_tone(waveform, freq, volume, looped, channel)

    # SSTOP has no operand in this port's ISA (0 operands per
    # `docs/nova16_instruction_reference.md`, unlike the upstream reference's
    # `SSTOP`/`SSTOP reg` split) -- always "stop everything", see
    # `sound.star::stop_all`'s own doc comment.
    fn op_sstop(mut self):
        snd::stop_all()

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
        snd::trigger_effect(v as u8, volume, channel as u8)

