; RTC test program for Star emulator
; Tests that C0/C1 registers return live wall-clock values
; that change between successive reads

ORG 0x1000

MAIN:
    ; Read C0 (low word of RTC) into P0
    MOV P0, C0
    
    ; Read C1 (high word of RTC) into P1
    MOV P1, C1
    
    ; Store first read at memory location 0xC000
    MOV [0xC000], P0
    MOV [0xC002], P1
    
    ; Simple delay loop
    MOV P2, 0x100       ; Loop counter
    
DELAY:
    DEC P2
    CMP P2, 0
    JNZ DELAY
    
    ; Read C0 again into P5
    MOV P5, C0
    
    ; Read C1 again into P6
    MOV P6, C1
    
    ; Store second read at memory location 0xC004
    MOV [0xC004], P5
    MOV [0xC006], P6
    
    ; Compare first and second C0 reads
    ; If they differ, write 0x01 to 0xC008 (success)
    ; If same, write 0x00 to 0xC008 (failure)
    MOV P7, [0xC000]    ; First C0 read
    CMP P5, P7          ; Compare with second C0 read
    JZ NO_CHANGE        ; If equal, no change detected
    
    ; Change detected - write success marker
    MOV [0xC008], 1
    JMP DONE
    
NO_CHANGE:
    ; No change detected - write failure marker
    MOV [0xC008], 0
    
DONE:
    HLT
