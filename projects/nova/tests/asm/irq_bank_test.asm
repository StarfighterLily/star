; Interrupt BANK preservation test (pure Option B, Python `4902a2e`).
;
; Scenario: interrupted code runs with BANK=3 (byte 0xA5 planted in bank 3's
; window at 0x8005); a timer interrupt (vector 0, TC enabled) fires mid-loop:
; the handler must see BANK=0 (byte at 0x8005 reads 0 from base RAM, not
; 0xA5), IRET must restore BANK=3 (byte at 0x8005 reads 0xA5 again). The
; handler also proves it can use banks itself (writes 0x5A into bank 7 at
; 0x8006, then sets BANK=0 before IRET -- matching the Python semantics that
; IRET restores the *entry* snapshot, not the handler's last bank).
;
; Evidence is accumulated in registers only (no cross-bank scratch reads):
;   R4=1 handler saw bank 0 (base-RAM read at 0x8005 was 0, BANK read 0)
;   R1=1 post-IRET bank-3 read OK (0x8005 reads 0xA5 again)
;   R2=1 post-IRET BANK register reads 3
;   R3=1 handler's bank-7 write visible from bank 7 (0x8006 reads 0x5A)
; Final: BANK=0, P8 balanced, halted=true. Verified by run_bin.exe dump.
ORG 0x0000
START:
    MOV P8, 0xFF00          ; explicit SP (stack lives in base RAM, bank-safe)

    ; Plant 0xA5 in bank 3's window at 0x8005.
    MOV BANK, 3
    MOV P1, 0x8005
    MOV R0, 0xA5
    MOV [P1], R0            ; bank3[0x8005] = 0xA5 (8-bit: R source -> 1 byte)

    ; Install handler + enable timer IRQ: TT counts, TM=2 threshold,
    ; TC=0x03 (enable + IRQ enable), TS=0 (fastest).
    ; R9 is the interrupt-fired flag and MUST be cleared before the timer is
    ; enabled -- in both emulators the timer only counts while TC bit 0 is
    ; set, so seeding R9 after TC=0x03 leaves a one-instruction race where
    ; the IRQ fires first and the handler's `MOV R9, 1` is then overwritten
    ; by this file's own `MOV R9, 0`, wedging the WAIT loop forever.
    MOV P1, 0x0100
    MOV P2, HANDLER
    MOV [P1], P2            ; IVT vector 0 -> HANDLER (base RAM write)
    MOV R9, 0               ; interrupt-fired flag (before the timer exists)
    MOV TT, 0
    MOV TM, 2
    MOV TS, 0
    MOV TC, 0x03
    STI

    ; Spin until the handler runs (still BANK=3 the whole time).
WAIT:
    MOV R8, R9
    CMP R8, 0
    JZ WAIT

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
    CLI
DONE:
    HLT

HANDLER:
    ; On entry BANK must already be 0 (forced by trigger_interrupt).
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
    ; *entry* snapshot regardless -- this proves no interference).
    MOV BANK, 7
    MOV P1, 0x8006
    MOV R0, 0x5A
    MOV [P1], R0            ; bank7[0x8006] = 0x5A
    MOV BANK, 0
    MOV R9, 1               ; tell main code the interrupt fired
    MOV TT, 0
    MOV TC, 0               ; disarm timer so it fires exactly once
    IRET
