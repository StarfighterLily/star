; Regression test for the PUSH/POP variable-width stack bug (see
; ../../NOTES.md "PUSH/POP always used a fixed 16-bit stack slot"): an R
; register or imm8 operand must push/pop exactly 1 byte (SP +-= 1), not
; the fixed 2 bytes (SP +-= 2) this port originally always used --
; confirmed against the live Python reference over MCP, which disagrees
; with docs/nova16_instruction_reference.md's own "SP -= 2"/"SP += 2"
; entries (stale against the actually-running reference here).
;
; P1 = SP after PUSH R0 (from SP=0x9000)  -> expect 0x8FFF (1-byte push)
; P2 = SP after PUSH P0 (from SP=0x9000)  -> expect 0x8FFE (2-byte push)
; P3 = SP after PUSH [0x3000] (memory)    -> expect 0x8FFE (defaults wide)
; R0 (after POP R0 from a pushed byte)    -> expect 0xAB
; P4 = SP after that POP R0 (from 0x8FFF) -> expect 0x9000 (1-byte pop)
; P0 (after POP P0 from a pushed word)    -> expect 0x1234
; P5 = SP after that POP P0 (from 0x8FFD) -> expect 0x8FFF (2-byte pop)
ORG 0x0000

START:
    MOV P8, 0x9000
    MOV R0, 0xAB
    PUSH R0
    MOV P1, P8

    MOV P8, 0x9000
    MOV P0, 0x1234
    PUSH P0
    MOV P2, P8

    MOV P8, 0x9000
    MOV [0x3000], 0xAB
    PUSH [0x3000]
    MOV P3, P8

    MOV P8, 0x8FFF
    MOV [0x8FFF], 0xAB
    POP R0
    MOV P4, P8

    MOV P8, 0x8FFD
    MOV [0x8FFD], 0x12
    MOV [0x8FFE], 0x34
    POP P0
    MOV P5, P8

    HLT
