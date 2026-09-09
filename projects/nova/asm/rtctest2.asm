; Simple RTC test - call now_seconds twice and store results
ORG 0x1000

MAIN:
    ; First call to now_seconds
    MOV P0, C0          ; C0 = low word of RTC
    
    ; Second call to now_seconds  
    MOV P1, C0          ; C0 = low word of RTC again
    
    ; Store results
    MOV [0xC000], P0    ; First read
    MOV [0xC002], P1    ; Second read
    
    ; Halt
    HLT
