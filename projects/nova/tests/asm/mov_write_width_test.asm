; Regression test for the MOV-to-memory write-width bug found while
; building the sprite-blit test (see NOTES.md "MOV [mem], narrow-source
; write-width bug"): `MOV [addr], <narrow source>` must write only as many
; bytes as the *source* operand's own width, not unconditionally 16 bits
; (which would clobber the following address's first byte). Covers all
; four write-width cases `core/exec_handlers.py::_write_result` documents:
; imm8, an 8-bit (`R`) register, a 16-bit (`P`) register, and imm16.
;
; R2 = mem[0x3000] -> expect 0xAB (imm8 write)
; R3 = mem[0x3001] -> expect 0xCD (sentinel; must be untouched by the imm8
;      write above -- a 16-bit write would have clobbered this with 0x00)
; R4 = mem[0x3010] -> expect 0x11 (R-register write)
; R5 = mem[0x3011] -> expect 0x22 (sentinel, same reasoning)
; R6 = mem[0x3020] -> expect 0x12 (P-register write, high byte, big-endian)
; R7 = mem[0x3021] -> expect 0x34 (low byte)
; R8 = mem[0x3030] -> expect 0xBE (imm16 write, high byte)
; R9 = mem[0x3031] -> expect 0xEF (low byte)
ORG 0x0000

START:
    MOV [0x3000], 0xAB
    MOV R0, 0xCD
    MOV [0x3001], R0

    MOV R0, 0x11
    MOV [0x3010], R0
    MOV R1, 0x22
    MOV [0x3011], R1

    MOV P0, 0x1234
    MOV [0x3020], P0

    MOV [0x3030], 0xBEEF

    MOV R2, [0x3000]
    MOV R3, [0x3001]
    MOV R4, [0x3010]
    MOV R5, [0x3011]
    MOV R6, [0x3020]
    MOV R7, [0x3021]
    MOV R8, [0x3030]
    MOV R9, [0x3031]

    HLT
