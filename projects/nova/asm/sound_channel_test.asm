; Nova Sound per-channel voice model test (todo.md P2 #5)
; Exercises multiple independently-addressed SPLAY channels at once (SW bits
; 3-5), plus STRIG's own separate rotating pool, to prove the real hardware
; build (not just the SDL_AUDIODRIVER=dummy compiler test suite) runs this
; shape end to end with no crash/hang.

ORG 0x1000

MAIN:
    ; Channel 2, sine wave, looping.
    MOV SF, 140
    MOV SV, 120
    MOV SW, 0xD2        ; enable(0x80) + loop(0x40) + channel 2 (0x10) + sine(2)
    SPLAY

    ; Channel 5, square wave, one-shot (SW bit 6 clear).
    MOV SF, 90
    MOV SV, 90
    MOV SW, 0xA9        ; enable(0x80) + channel 5 (0x28) + square(1)
    SPLAY

    MOV R0, 100
WAIT1:
    DEC R0
    JNZ WAIT1

    ; Retrigger channel 2 with a different waveform -- should replace the
    ; still-looping sine, not layer on top of it.
    MOV SF, 200
    MOV SV, 100
    MOV SW, 0xD4        ; enable + loop + channel 2 + triangle(4)
    SPLAY

    ; A few STRIG effects in a row -- exercises Cpu::next_strig_channel's
    ; own rotation through mixer channels 8-15.
    STRIG 0
    STRIG 3
    STRIG 6

    MOV R0, 100
WAIT2:
    DEC R0
    JNZ WAIT2

    ; Stop channel 5's one-shot explicitly via SSTOP (this port's ISA has no
    ; per-channel SSTOP operand, so this always stops everything -- see
    ; sound.star's header comment).
    SSTOP

    HLT
