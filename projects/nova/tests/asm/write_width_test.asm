; Regression test for generalizing the MOV-only write-width fix (see
; ../../NOTES.md "MOV [mem], narrow-source write-width" and "Generalizing
; the write-width fix") to every other opcode that writes a result back to
; a memory destination via the same `_write_result`-style inference:
; ADD/AND/SHL/BSET, each with a narrow (8-bit register or imm8) source/
; amount operand and a sentinel byte immediately after the memory
; destination, proving the resulting write really only touched 1 byte (a
; 16-bit write would have clobbered the sentinel).
;
; Each block's *read* of its own memory destination is still the usual
; 16-bit word read (a memory operand always reads 16-bit regardless of the
; source's width -- that part is unaffected by this fix), so the sentinel
; byte doubles as the read's low byte; only the narrower *write* afterward
; is what's under test here. Expected values below were captured from the
; live Python reference over MCP (`get_cpu_state` after `cpu_step`), not
; hand-derived -- see NOTES.md for why byte-for-byte replay against the
; running reference is this project's standard for exactly this kind of
; multi-step arithmetic-on-memory case.
;
; R1 = mem[0x3000] -> expect 0xD7 (ADD [addr], R0: word 0x05CD + 0x0A =
;      0x05D7, low byte written)
; R2 = mem[0x3001] -> expect 0xCD (sentinel; untouched by the 1-byte write)
; R3 = mem[0x3010] -> expect 0x0C (AND [addr], R0: word 0x0FCD & 0x0C =
;      0x0C, low byte written)
; R4 = mem[0x3011] -> expect 0xCD (sentinel, untouched)
; R5 = mem[0x3020] -> expect 0x34 (SHL [addr], 2: word 0x01CD << 2 =
;      0x0734, low byte written)
; R6 = mem[0x3021] -> expect 0xCD (sentinel, untouched)
; R7 = mem[0x3030] -> expect 0xCD (BSET [addr], 3: word 0x03CD already has
;      bit 3 set, result unchanged at 0x03CD, low byte written)
; R8 = mem[0x3031] -> expect 0xCD (sentinel, untouched)
ORG 0x0000

START:
    ; ADD [addr], R0 (8-bit register source)
    MOV [0x3000], 0x05
    MOV [0x3001], 0xCD
    MOV R0, 0x0A
    ADD [0x3000], R0

    ; AND [addr], R0
    MOV [0x3010], 0x0F
    MOV [0x3011], 0xCD
    MOV R0, 0x0C
    AND [0x3010], R0

    ; SHL [addr], imm8 (the shift *amount* is what determines write width,
    ; not the shifted value itself -- see NOTES.md)
    MOV [0x3020], 0x01
    MOV [0x3021], 0xCD
    SHL [0x3020], 2

    ; BSET [addr], imm8
    MOV [0x3030], 0x03
    MOV [0x3031], 0xCD
    BSET [0x3030], 3

    MOV R1, [0x3000]
    MOV R2, [0x3001]
    MOV R3, [0x3010]
    MOV R4, [0x3011]
    MOV R5, [0x3020]
    MOV R6, [0x3021]
    MOV R7, [0x3030]
    MOV R8, [0x3031]

    HLT
