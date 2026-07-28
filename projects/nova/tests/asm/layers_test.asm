; Layer compositing + LSWAP/LMOVE/LCOPY regression test for the Star Nova-16
; port (see ../../NOTES.md "Layer compositing"). Assembled with the upstream
; Python nova_assembler.py and checked against this port's own Cpu::step()
; via ../run_bin.star -- see NOTES.md for the full checkpoint-by-checkpoint
; expected values.
;
; R0: composite(10,10) after layer0=5, layer1=7 written there -> layer1
;     should win (background layers overlay the base) -> expect 7
; R1: composite(20,20), layer1=9 only (layer0=0 there) -> expect 9
; R2: LCOPY 1->2 of pixel (30,30)=11, then layer1 cleared entirely ->
;     composite(30,30) should still show 11 (survives on layer2) -> expect 11
; R3: LMOVE 1->4 of pixel (40,40)=13, read back immediately (proves the
;     value actually reached the target layer) -> expect 13
; R4: same pixel (40,40) after layer4 is cleared entirely -> if LMOVE
;     correctly cleared its *source* layer (1) too, nothing is left ->
;     expect 0 (a bug that only copies instead of moving would leave 13)
; R5: LSWAP 1<->2 of pixel (50,50) -- layer1=17, layer2=19 before the swap,
;     then layer2 is cleared entirely -> composite should show whatever
;     ended up on layer1, i.e. 19 (the pre-swap layer2 value) if the swap
;     really happened -> expect 19 (a broken/no-op swap would leave 17)
ORG 0x0000

START:
    MOV VL, 0
    MOV VX, 10
    MOV VY, 10
    SWRITE 5

    MOV VL, 1
    MOV VX, 10
    MOV VY, 10
    SWRITE 7

    MOV VX, 20
    MOV VY, 20
    SWRITE 9

    MOV VX, 10
    MOV VY, 10
    SREAD R0

    MOV VX, 20
    MOV VY, 20
    SREAD R1

    ; -- LCOPY --
    MOV VL, 1
    MOV VX, 30
    MOV VY, 30
    SWRITE 11
    LCOPY 2
    SFILL 0             ; clears layer 1 (current VL)
    SREAD R2

    ; -- LMOVE --
    MOV VL, 1
    MOV VX, 40
    MOV VY, 40
    SWRITE 13
    LMOVE 4
    SREAD R3            ; moved value visible on layer4 already

    MOV VL, 4
    SFILL 0             ; clear layer4 entirely
    SREAD R4            ; if LMOVE cleared layer1 too, this is 0

    ; -- LSWAP --
    MOV VL, 1
    MOV VX, 50
    MOV VY, 50
    SWRITE 17
    MOV VL, 2
    SWRITE 19
    MOV VL, 1
    LSWAP 2
    MOV VL, 2
    SFILL 0             ; clear layer2 entirely (post-swap contents)
    SREAD R5            ; whatever ended up on layer1 post-swap

    HLT
