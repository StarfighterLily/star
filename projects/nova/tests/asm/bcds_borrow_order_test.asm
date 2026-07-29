; Probe: is BCDS's borrow check (`result < 0`) evaluated before or after
; the `result &= 0xFF` mask? R0=0x15, R1=0x42 -> raw diff = 0x15-0x42 =
; -45 (a genuine borrow: op1 < op2).
; Pre-mask: -45 < 0 -> borrow should be SET.
; Post-mask (Star's & Python's bitwise `&` both yield 0-255 unconditionally
; for a negative operand) -> -45 & 0xFF = 0xD3 (211), 211 < 0 is never
; true -> borrow would be CLEAR.
ORG 0x0000
START:
    MOV R0, 0x15
    MOV R1, 0x42
    BCDS R0, R1
    JC BORROW_SET
    MOV R2, 0
    JMP DONE
BORROW_SET:
    MOV R2, 1
DONE:
    HLT
