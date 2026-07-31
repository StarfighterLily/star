; Nova Sound leaked-WAV-handle regression test (todo.md P2 #3)
; Repeatedly retriggers the same SPLAY hardware channel (one-shot, no wait
; for real playback to finish) and saturates STRIG's 8-slot round-robin pool
; twice over, then SSTOP -- exercises Cpu::sound_channel_handles'
; free-the-previous-occupant path (op_splay/op_strig's replace_channel_handle)
; and free_all_sound_handles (op_sstop) many times in a row. A double-free or
; a free-while-still-playing bug in that logic would abort the process
; (sound_free's own null-handle guard) or corrupt the heap; this proves the
; whole sequence still runs clean to HLT.

ORG 0x1000

MAIN:
    MOV SF, 140
    MOV SV, 80
    MOV R1, 20
RETRIGGER_LOOP:
    ; Channel 0, square wave, one-shot (SW bit 6 clear) -- retriggered 20
    ; times in a row on the exact same channel before any of them would have
    ; finished playing in real time.
    MOV SW, 0x81        ; enable(0x80) + channel 0 + square(1)
    SPLAY
    DEC R1
    JNZ RETRIGGER_LOOP

    ; 16 STRIG calls in a row -- Cpu::next_strig_channel round-robins
    ; channels 8-15, so this wraps the pool exactly twice, retriggering each
    ; of the 8 slots back-to-back.
    MOV R2, 16
STRIG_LOOP:
    STRIG 0
    DEC R2
    JNZ STRIG_LOOP

    SSTOP
    HLT
