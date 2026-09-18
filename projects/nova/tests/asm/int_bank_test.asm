; Software INT (opcode 0x30) BANK preservation test (pure Option B).
;
; Companion to irq_bank_test.asm, which covers the *hardware* interrupt path
; (timer -> trigger_interrupt). This one covers the *software* INT path, whose
; Python counterpart is a separate handler (`core/exec_handlers.py::_int`,
; opcode 0x30) rather than `InterruptController._trigger` /
; `CPU._trigger_interrupt`. Both must snapshot the entry BANK and force bank 0
; for the handler, and both must be undone by IRET.
;
; In the Star port `op_int` simply calls `trigger_interrupt`, so software and
; hardware interrupts already share `Memory::irq_enter`; in the Python
; reference they are three separate entry points, which is exactly why this
; test exists -- it pins the three-way agreement.
;
; Scenario: main code runs with BANK=3 (0xA5 planted in bank 3's window at
; 0x8005) and executes `INT 4` (vector 4 = USER1, IVT slot 0x0110). The
; handler must see BANK=0 (0x8005 reads 0 from base RAM, not 0xA5) and IRET
; must restore BANK=3.
;
; Evidence (registers only):
;   R4=1 handler saw bank 0 on entry
;   R1=1 post-IRET bank-3 read OK (0x8005 reads 0xA5 again)
;   R2=1 post-IRET BANK register reads 3
;   R3=1 handler's own bank-7 write visible from bank 7
; Final: BANK=0, P8 balanced, halted=true. Verified by run_bin.exe dump.
ORG 0x0000
START:
    MOV P8, 0xFF00          ; explicit SP (stack lives in base RAM, bank-safe)

    ; Plant 0xA5 in bank 3's window at 0x8005.
    MOV BANK, 3
    MOV P1, 0x8005
    MOV R0, 0xA5
    MOV [P1], R0            ; bank3[0x8005] = 0xA5

    ; Install the handler in IVT vector 4 (0x0100 + 4*4 = 0x0110).
    MOV P1, 0x0110
    MOV P2, HANDLER
    MOV [P1], P2            ; base RAM write -- outside the bank window

    STI                     ; INT honours the I flag: must be set to fire

    ; --- software interrupt while BANK=3 ---
    INT 4
    STI                     ; INT cleared I on entry; restore it to prove
                            ; that IRET's flag restore is also intact

    ; --- back in main code, BANK must be 3 again ---
    MOV P1, 0x8005
    MOV R0, [P1]            ; expect 0xA5 (bank 3 visible again)
    CMP R0, 0xA5
    JNZ DONE
    MOV R1, 1               ; evidence: post-IRET bank-3 read OK
    MOV R0, BANK
    CMP R0, 3
    JNZ DONE
    MOV R2, 1               ; evidence: BANK register restored to 3

    ; Handler's own bank-7 write must be visible from bank 7.
    MOV BANK, 7
    MOV P1, 0x8005
    MOV R0, [P1]            ; 0x8005 in bank 7 was never written -> 0
    CMP R0, 0
    JNZ DONE
    MOV P1, 0x8006
    MOV R0, [P1]            ; expect 0x5A (handler wrote it via bank 7)
    CMP R0, 0x5A
    JNZ DONE
    MOV R3, 1               ; evidence: handler bank use preserved

    MOV BANK, 0
DONE:
    HLT

HANDLER:
    ; On entry BANK must already be 0 (forced by the software-INT handler).
    MOV P1, 0x8005
    MOV R0, [P1]            ; base RAM at 0x8005: expect 0 (not 0xA5)
    CMP R0, 0
    JNZ HLEAVE
    MOV R0, BANK
    CMP R0, 0
    JNZ HLEAVE
    MOV R4, 1               ; evidence: handler saw bank 0
HLEAVE:
    ; Use a bank ourselves, then reset to 0 before IRET (IRET restores the
    ; *entry* snapshot regardless -- proves no interference).
    MOV BANK, 7
    MOV P1, 0x8006
    MOV R0, 0x5A
    MOV [P1], R0            ; bank7[0x8006] = 0x5A
    MOV BANK, 0
    IRET
