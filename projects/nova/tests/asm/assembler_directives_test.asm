; Regression test for the new Star `assembler.star` (todo.md P1 #2): exercises
; every directive (EQU/DB/DW/DEFSTR/DS), char literals, a negative decimal
; immediate, a string literal containing a comma (tests the string-aware
; comma splitter), and label references in every direction (forward,
; backward, and a data-section reference back up into the code section) --
; none of which any of this project's other checked-in tests/asm/*.asm
; sources exercise (they only use ORG plus plain register/immediate/memory
; operands). Verified byte-for-byte against a fresh run of the live upstream
; `nova_assembler.py` (see NOTES.md's "Assembler" section) and via this
; project's own disasm.star round trip.
;
; R0 = VALUE (0x2A, from EQU)
; R1 = NEGATIVE as a 16-bit two's complement value (0xFFFB), truncated by
;      MOV's own 8-bit register destination width down to 0xFB
; R2 = 'A' (0x41)
; R3 = '\n' (0x0A)
; R4 = 0x00 (set from BACKWARD, reached via a forward CALL)
; R5 = 0x00 (post-loop: 3 -> 2 -> 1 -> 0 via a genuine backward JNZ branch)
;
; Note: `DB` below uses `0x41` rather than `'A'` for its first byte, even
; though `MOV R2, 'A'` a few lines up uses the char-literal form freely and
; both assemblers agree on it there. `nova_assembler.py`'s `DataGenerator.
; _parse_numeric_value` (the function backing `DB`'s own non-string
; arguments) never checks `OperandClassifier`'s char-literal pattern at all
; -- confirmed empirically: `DB 'A'` fails in the live Python assembler with
; "Unknown value: 'A'". This project's own `assembler.star` does not share
; that gap (`DB 'A'` assembles correctly here), but this file sticks to
; `0x41` specifically so its whole output stays byte-for-byte comparable
; against a real Python assembler run, per this project's standing
; verification method.

VALUE EQU 0x2A
NEGATIVE EQU -5

ORG 0x0000

START:
    MOV R0, VALUE
    MOV R5, 0x03
LOOPTOP:
    DEC R5
    JNZ LOOPTOP
    JMP FORWARD
    HLT

FORWARD:
    MOV R1, NEGATIVE
    MOV R2, 'A'
    MOV R3, '\n'
    CALL BACKWARD
    JMP DONE

BACKWARD:
    MOV R4, 0x00
    RET

DONE:
    HLT

ORG 0x0100
MSG:
    DB "hello, world", 0
    DB 0x41, 10, 0x41, VALUE
    DW 0x1234, START
    DEFSTR "star"
    DS 4
