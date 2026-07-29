; Regression test for the BCDA/BCDS/BCDCMP/BCDADD/BCDSUB read-width bug
; (see ../../NOTES.md "BCD operations read width"): an earlier draft of
; this port assumed these opcodes always read their operands as a plain
; 8-bit byte, but the live Python reference actually applies the usual
; "8 if op1 is an R register, else 16" destination-kind rule to BCD reads
; too -- only the final written-back *value* is unconditionally masked to
; a byte. `BCDA P0, P1` with P0=0x1234, P1=0x0006 reads the *full* 16-bit
; P-register values (sum 0x123A, not 0x34+0x06=0x3A), which changes
; whether the BCD-carry flag ends up set. Confirmed against the live
; reference over MCP; run_bin.star's harness doesn't print flags directly,
; so the carry flag is captured into R1 via JC/JMP instead.
;
; P0 (after BCDA) -> expect 0x003A (masked-to-byte result, same either way)
; R1 (carry flag captured via JC) -> expect 1 (raw 16-bit sum 0x123A >
;     0x99; an 8-bit-only read of 0x34+0x06=0x3A would have left C clear,
;     i.e. R1=0)
ORG 0x0000

START:
    MOV P0, 0x1234
    MOV P1, 0x0006
    BCDA P0, P1
    JC CARRY_SET
    MOV R1, 0
    JMP DONE
CARRY_SET:
    MOV R1, 1
DONE:
    HLT
