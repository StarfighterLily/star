; Manual smoke-test program for uart_tcp_bridge.star (not part of the
; automated regression suite -- exercised by hand against a real TCP peer,
; see NOTES.md's "UART" section). Echoes every received byte straight back
; out via SEROUT until it receives a 0xFF sentinel byte, then halts.
; Deliberately *not* 0x00: a `str`-based `tcp_recv` can't distinguish a real
; single `0x00` payload byte from a true zero-byte close (`str` truncates at
; the first NUL -- see `../../uart_tcp_bridge.star`'s own doc comment on
; this, found via an earlier run of this exact smoke test).
;
; PASS marker: P0 = 0xBEEF (received the 0xFF sentinel and halted cleanly)

ORG 0x1000

START:
    ; No SERCTRL call here on purpose: `SERCTRL`'s low two status-shaped
    ; control bits are directly reflected into rx_available/tx_complete
    ; (uart.star's own documented quirk) -- SERCTRL 0x01 would flip
    ; rx_available true immediately, before any real byte ever arrives,
    ; causing SERIN below to read the zero-initialized data_register and
    ; false-positive-match the 0x00 sentinel on the very first WAIT check.

WAIT:
    SERSTAT R1
    AND R1, 0x01
    CMP R1, 0x01
    JNZ WAIT
    SERIN R2
    CMP R2, 0xFF
    JZ DONE
    SEROUT R2
    JMP WAIT

DONE:
    MOV P0, 0xBEEF
    HLT
