; Probe: is BCDA's carry check (`result > 0x99`) evaluated before or after
; the `result &= 0xFF` mask? R0=0x89, R1=0x89 (both R registers, so this
; doesn't even touch the read-width question) -> raw sum 0x112 (274).
; Pre-mask: 274 > 0x99(153) -> carry should be SET.
; Post-mask: 274 & 0xFF = 0x12(18), 18 > 153 -> carry would be CLEAR.
ORG 0x0000
START:
    MOV R0, 0x89
    MOV R1, 0x89
    BCDA R0, R1
    JC CARRY_SET
    MOV R2, 0
    JMP DONE
CARRY_SET:
    MOV R2, 1
DONE:
    HLT
