; Nova-16 UART framed-mode protocol test (todo.md P2 #3).
;
; Exercises the opcode-reachable half of framed-mode parsing: SERCTRL's
; control bit 2 (framed-mode enable) and the new SERFSTAT opcode (0xB4,
; extended status -- framed-mode-enabled + latched checksum-error bits that
; SERSTAT's own two low bits never expose). The frame *bytes* themselves
; only ever arrive via Uart::host_push_rx -- no opcode can inject RX bytes,
; same as raw mode -- so this program alone cannot drive the other half; it
; is meant to be run by tests/uart_framed_test.star, a direct-field-poke
; harness (same spirit as tests/mouse_interrupt_test.star) that loads this
; .bin, steps the CPU, and calls host_push_rx directly to feed one good
; frame (0x7E 0x02 0x11 0x22 0x33) and one bad, checksum-mismatched frame
; (0x7E 0x01 0x99 <wrong checksum>) at the right points.
;
; PASS marker: P0 = 0xBEEF
; FAIL marker: P0 = 0xDEAD

ORG 0x1000

START:
    MOV P0, 0xDEAD          ; default to failure until every check passes

    SERCTRL 0x04            ; enable framed mode only (control bit 2), no IRQ

    ; SERFSTAT must report framed mode enabled, no checksum error yet.
    SERFSTAT R0
    AND R0, 0x04
    CMP R0, 0x04
    JNZ FAIL
    SERFSTAT R0
    AND R0, 0x10
    CMP R0, 0x00
    JNZ FAIL

    ; --- Good frame: payload bytes 0x11/0x22 must come back out through
    ; SERIN one at a time, in order, once the harness has pushed the whole
    ; frame (0x7E 0x02 0x11 0x22 0x33) through host_push_rx.
WAIT_GOOD_1:
    SERSTAT R1
    AND R1, 0x01
    CMP R1, 0x01
    JNZ WAIT_GOOD_1
    SERIN R2
    CMP R2, 0x11
    JNZ FAIL

WAIT_GOOD_2:
    SERSTAT R1
    AND R1, 0x01
    CMP R1, 0x01
    JNZ WAIT_GOOD_2
    SERIN R3
    CMP R3, 0x22
    JNZ FAIL

    ; No checksum error latched after a good frame.
    SERFSTAT R4
    AND R4, 0x10
    CMP R4, 0x00
    JNZ FAIL

    ; --- Bad frame (0x7E 0x01 0x99 <wrong checksum>): must latch the
    ; checksum-error bit and must NOT deliver 0x99 through SERIN.
WAIT_BAD:
    SERFSTAT R5
    AND R5, 0x10
    CMP R5, 0x10
    JNZ WAIT_BAD

    SERSTAT R6
    AND R6, 0x01
    CMP R6, 0x00
    JNZ FAIL            ; a bad frame's payload must never reach the RX FIFO

    ; SERFSTAT read-clears the checksum error -- a second read must show 0.
    SERFSTAT R7
    AND R7, 0x10
    CMP R7, 0x00
    JNZ FAIL

    MOV P0, 0xBEEF      ; PASS
    HLT

FAIL:
    MOV P0, 0xDEAD
    HLT
