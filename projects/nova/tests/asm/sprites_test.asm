; Sprite control block + SPBLIT/SPBLITALL regression test for the Star
; Nova-16 port (see ../../NOTES.md "Sprites"). Assembled with the upstream
; Python nova_assembler.py and checked against this port's own Cpu::step()
; via ../run_bin.star, then cross-checked against the live Python reference
; -- see NOTES.md for the full checkpoint-by-checkpoint expected values.
;
; Sprite 0: 4x4 bitmap at 0x3000 (values 1..16, row-major), transparency
; color 0 injected at row1/col1 (byte value 5 -> replaced with 0), placed at
; (100,80), flags = active + transparency (default layer 5).
; Sprite 1: 2x2 bitmap at 0x3100, all pixels = 99, no transparency, placed
; at (150,150), flags = active + layer-select bit (target layer 6).
; Sprite 2: 1x1 bitmap at 0x3200 = 55, placed at (200,200), flags = 0
; (inactive) -- must never appear anywhere on screen.
;
; R1: composite(100,80) right after SPBLIT 0        -> expect 1 (top-left)
; R2: composite(101,81) right after SPBLIT 0         -> expect 0 (the
;     transparent pixel skips the write, so the untouched background
;     shows through)
; R3: composite(103,83) right after SPBLIT 0         -> expect 16
;     (bottom-right)
; R4: composite(150,150) after SPBLITALL             -> expect 99 (layer 6)
; R5: composite(200,200) after SPBLITALL             -> expect 0 (sprite 2
;     is inactive and must not have been blitted at all)
ORG 0x0000

START:
    ; -- sprite 0 bitmap: 0x3000..0x300F, values 1..16, byte 5 forced to 0 --
    MOV R0, 1
    MOV [0x3000], R0
    MOV R0, 2
    MOV [0x3001], R0
    MOV R0, 3
    MOV [0x3002], R0
    MOV R0, 4
    MOV [0x3003], R0
    MOV R0, 5
    MOV [0x3004], R0
    MOV R0, 0
    MOV [0x3005], R0
    MOV R0, 7
    MOV [0x3006], R0
    MOV R0, 8
    MOV [0x3007], R0
    MOV R0, 9
    MOV [0x3008], R0
    MOV R0, 10
    MOV [0x3009], R0
    MOV R0, 11
    MOV [0x300A], R0
    MOV R0, 12
    MOV [0x300B], R0
    MOV R0, 13
    MOV [0x300C], R0
    MOV R0, 14
    MOV [0x300D], R0
    MOV R0, 15
    MOV [0x300E], R0
    MOV R0, 16
    MOV [0x300F], R0

    ; -- sprite 0 SCB @ 0xF000 --
    MOV R0, 0x30
    MOV [0xF000], R0
    MOV R0, 0x00
    MOV [0xF001], R0
    MOV R0, 100
    MOV [0xF002], R0
    MOV R0, 80
    MOV [0xF003], R0
    MOV R0, 4
    MOV [0xF004], R0
    MOV [0xF005], R0
    MOV R0, 0x03
    MOV [0xF006], R0
    MOV R0, 0
    MOV [0xF007], R0

    SPBLIT 0

    MOV VX, 100
    MOV VY, 80
    SREAD R1
    MOV VX, 101
    MOV VY, 81
    SREAD R2
    MOV VX, 103
    MOV VY, 83
    SREAD R3

    ; -- sprite 1 bitmap: 0x3100..0x3103, all 99 --
    MOV R0, 99
    MOV [0x3100], R0
    MOV [0x3101], R0
    MOV [0x3102], R0
    MOV [0x3103], R0

    ; -- sprite 1 SCB @ 0xF010 --
    MOV R0, 0x31
    MOV [0xF010], R0
    MOV R0, 0x00
    MOV [0xF011], R0
    MOV R0, 150
    MOV [0xF012], R0
    MOV [0xF013], R0
    MOV R0, 2
    MOV [0xF014], R0
    MOV [0xF015], R0
    MOV R0, 0x81
    MOV [0xF016], R0
    MOV R0, 0
    MOV [0xF017], R0

    ; -- sprite 2 bitmap: 0x3200 = 55 --
    MOV R0, 55
    MOV [0x3200], R0

    ; -- sprite 2 SCB @ 0xF020: inactive (flags=0) --
    MOV R0, 0x32
    MOV [0xF020], R0
    MOV R0, 0x00
    MOV [0xF021], R0
    MOV R0, 200
    MOV [0xF022], R0
    MOV [0xF023], R0
    MOV R0, 1
    MOV [0xF024], R0
    MOV [0xF025], R0
    MOV R0, 0x00
    MOV [0xF026], R0
    MOV R0, 0
    MOV [0xF027], R0

    SPBLITALL

    MOV VX, 150
    MOV VY, 150
    SREAD R4
    MOV VX, 200
    MOV VY, 200
    SREAD R5

    HLT
