; Nova SMIX/SECHO/SREVERB/SFILTER test (todo.md P2 #4) -- these four have no
; upstream reference implementation to match (opcodes.py leaves them
; unimplemented too), so unlike every other .asm test in this project this
; one isn't checking output against a documented "expected" value from the
; Python reference. It's a smoke test, same spirit as sound_channel_test.asm/
; sound_leak_test.asm: proves the assembler now accepts these four mnemonics
; (previously rejected at assembly time) and that cpu_sound.star's new
; op_smix/op_secho/op_sreverb/op_sfilter handlers -- and the DSP behind them
; in sound.star -- run end to end against the real hardware build with no
; crash/hang, exercising every documented operand (channel, delay/amount/
; type, output).

ORG 0x1000

MAIN:
    ; Channel 0: sine tone, looping, so there's a real cached buffer for the
    ; effects below to process (SECHO/SREVERB/SFILTER on a channel with
    ; nothing cached are documented no-ops -- this exercises the real path).
    MOV SF, 140
    MOV SV, 120
    MOV SW, 0xC2        ; enable(0x80) + loop(0x40) + channel 0 + sine(2)
    SPLAY

    ; Channel 1: square tone, one-shot -- a second source for SMIX to mix in.
    MOV SF, 90
    MOV SV, 90
    MOV SW, 0x89        ; enable(0x80) + channel 1 (0x08) + square(1)
    SPLAY

    ; SECHO channel 0, delay=128 (mid-range of the documented 0-255 mapping).
    MOV R0, 0
    MOV R1, 128
    SECHO R0, R1

    ; SREVERB channel 0, amount=200.
    MOV R0, 0
    MOV R1, 200
    SREVERB R0, R1

    ; SFILTER channel 1, type=0 (low-pass), then type=1 (high-pass) on the
    ; same channel -- exercises re-processing an already-processed buffer.
    MOV R0, 1
    MOV R1, 0
    SFILTER R0, R1
    MOV R1, 1
    SFILTER R0, R1

    ; SFILTER with an out-of-range type (matching this file's own "clamps to
    ; a safe passthrough" documented convention rather than crashing).
    MOV R0, 1
    MOV R1, 99
    SFILTER R0, R1

    ; SMIX output=2 -- mixes channels 0/1's (now effect-processed) buffers
    ; down onto channel 2, which is itself then chainable.
    MOV R0, 2
    SMIX R0

    ; SECHO on a channel with nothing cached (channel 5) -- documented no-op,
    ; must not crash.
    MOV R0, 5
    MOV R1, 50
    SECHO R0, R1

    SSTOP
    HLT
