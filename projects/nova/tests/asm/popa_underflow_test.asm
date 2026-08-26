; POPA stack-underflow test (parity round, Aug 2026).
;
; The Python reference changed POPA semantics (`25033bb`, core/exec.py +
; instructions.py): once the stack is exhausted (SP >= 0xFFFE partway through
; the 23-word restore walk), remaining slots restore ZERO and SP stops
; advancing -- previously CPython raised RuntimeError there, and this port
; used to keep walking SP, silently restoring whatever garbage bytes sat at
; the exhausted addresses (including wrapping back around to address 0).
; `cpu_stack.star::op_popa` now mirrors the zero-pad.
;
; Setup walks SP from 0xFFF8: three readable words (sentinels planted below at
; 0xFFF8/0xFFFA/0xFFFC land in R0/R1/R2), then sp reaches 0xFFFE and every
; remaining slot must be ZERO. Two traps make any regression visible:
;   - word at 0xFFFE is 0xBEEF -- read only if the walk doesn't stop (R3 != 0);
;   - the program itself sits at 0x0000 (nonzero opcode bytes) -- read only if
;     the buggy impl wraps SP past 0xFFFF (also lands in R3.. onward).
; R5/P3 are pre-set to junk so the "restore" half of those slots actually
; proving it writes zeros, not just leaves defaults.
;
; Expected run_bin.exe output:
;   R0=0x11 R1=0x22 R2=0x33  (real popped words)
;   R3-R9 = 0, P0-P9 = 0 (incl. P3), VX=VY=VC=0
;   P8 (SP) = 0xFFFE       (walk stopped, did not advance past exhaustion)
;   halted=true
ORG 0x0000
START:
    MOV P8, 0xFFF8         ; near top of memory: 3 readable words left
    MOV R5, 0xA5           ; junk that POPA must overwrite with padded zeros
    MOV P3, 0x5A5A
    POPA
    HLT

ORG 0xFFF8
    DW 0x1111              ; -> R0
    DW 0x2222              ; -> R1
    DW 0x3333              ; -> R2
    DW 0xBEEF              ; -> must NEVER be restored anywhere