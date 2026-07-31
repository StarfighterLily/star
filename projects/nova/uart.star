# Nova-16 UART: 8-bit data register, status/control bits, and RX/TX
# interrupt-pending signaling (docs/UART_SYSTEM.md, ported from
# `nova_uart.py::NovaUART`'s raw-mode data path).
#
# Host bridge (todo.md P0 #1): `host_push_rx` below is the "piping actual
# stdin into rx_available/data_register" seam this file's own header comment
# used to describe as future work -- see `../uart_bridge.star` for the
# actual stdin-driven driver that calls it. TX is real too: `cpu.star`'s
# `op_serout` prints every transmitted byte to the process's own stdout, so
# a real host terminal (or anything piping its output) sees it -- no buffer
# on this side, `write_data` below only updates the register model.
#
# Framed-mode parsing (todo.md P2 #3): previously deliberately unported
# because "no opcode drives framing" -- true until now. `write_control`
# below now reads control bit 2 (`0x04`, matching `docs/UART_SYSTEM.md`'s
# already-documented-but-previously-inert "Framed mode enable" bit) into
# `framed_mode`, and a new dedicated opcode, `SERFSTAT` (`0xB4`, see
# `cpu_io.star::op_serfstat`), reads back `framed_mode`/latched checksum-
# error state that `SERSTAT`'s own two low bits (by design, see below) never
# exposed. That closes the actual gap: `SERCTRL`/`SERFSTAT`/`SERIN` are now
# real opcode-reachable surface for enabling framing and observing its
# result, even though the frame *bytes themselves* still only ever arrive
# via `host_push_rx` (no opcode can inject RX bytes -- same as raw mode,
# and the same reason `mouse_pending_irq` has no opcode-reachable driver
# either, see `tests/mouse_interrupt_test.star`).
#
# Frame format (matches `docs/UART_SYSTEM.md`'s "Framed Mode" section
# exactly): `START` (`0x7E`) byte, `LENGTH` byte (payload size, `0..255`),
# that many `PAYLOAD` bytes, then a `CHECKSUM` byte (`sum(payload) & 0xFF`).
# A byte arriving outside START..CHECKSUM while idle (i.e. anything that
# isn't `0x7E`) is silently dropped rather than buffered or erroring -- the
# doc doesn't specify idle-byte handling, so this is a Star-port judgment
# call, not a transcribed reference behavior; it matches the common framing-
# parser convention of resyncing on the next start byte. On a good frame,
# every payload byte is queued into a small FIFO (`rx_queue` below) for
# `SERIN` to drain one at a time, mirroring the doc's "payload bytes are
# pushed into RX FIFO" -- genuinely a FIFO this time, unlike raw mode's
# single-register model (still exactly as before, see `read_data` below). On
# a checksum mismatch, `frame_checksum_error` latches (read-and-clear via
# `SERFSTAT`, matching this port's existing "read consumes" idiom --
# `SERIN`/`KEYIN` both already work this way) and the pending interrupt
# fires if enabled, matching the doc's "Interrupt pending is asserted if IRQ
# is enabled" checksum-error behavior. TCP transport remains out of scope --
# unrelated to framing, see `../uart_bridge.star`'s header comment for why.
#
# `write_control`'s "low two status-shaped control bits are directly
# reflected into rx_available/tx_complete" quirk (below) predates the host
# bridge and framed mode and still applies unchanged: an `SERCTRL` write can
# flip `rx_available` on its own, independent of whether `host_push_rx` has
# actually been called -- a real quirk this port verified against the
# reference, not a new bug introduced by this file.

const STATUS_RX_AVAILABLE: u8 = 0x01 as u8
const STATUS_TX_COMPLETE: u8 = 0x02 as u8
const STATUS_IRQ_PENDING: u8 = 0x80 as u8

const CONTROL_IRQ_ENABLE: u8 = 0x01 as u8
const CONTROL_FRAMED_ENABLE: u8 = 0x04 as u8

const EXT_STATUS_FRAMED_MODE: u8 = 0x04 as u8
const EXT_STATUS_CHECKSUM_ERROR: u8 = 0x10 as u8

const FRAME_START_BYTE: u8 = 0x7E as u8
const FRAME_STATE_IDLE: u8 = 0 as u8
const FRAME_STATE_LENGTH: u8 = 1 as u8
const FRAME_STATE_PAYLOAD: u8 = 2 as u8
const FRAME_STATE_CHECKSUM: u8 = 3 as u8

const RX_QUEUE_SIZE: i32 = 256

struct Uart:
    mut data_register: u8
    mut control: u8
    mut interrupt_enabled: bool
    mut rx_available: bool
    mut tx_complete: bool
    mut pending_interrupt: bool
    # Framed-mode state (todo.md P2 #3) -- inert while `framed_mode` is
    # false, so raw mode's behavior/model above is untouched.
    mut framed_mode: bool
    mut frame_state: u8
    mut frame_len: u8
    mut frame_pos: i32
    mut frame_buf: [u8; 256]
    mut frame_checksum_error: bool
    mut rx_queue: [u8; 256]
    mut rx_head: i32
    mut rx_tail: i32
    mut rx_count: i32

fn new_uart() -> Uart:
    Uart(
        data_register = 0 as u8, control = 0 as u8, interrupt_enabled = false,
        rx_available = false, tx_complete = false, pending_interrupt = false,
        framed_mode = false, frame_state = FRAME_STATE_IDLE, frame_len = 0 as u8,
        frame_pos = 0, frame_buf = [0 as u8; 256], frame_checksum_error = false,
        rx_queue = [0 as u8; 256], rx_head = 0, rx_tail = 0, rx_count = 0,
    )

impl Uart:
    # SERSTAT: low status bits only (RX available / TX complete) -- matches
    # `read_status_flags()` exactly (the interrupt-pending/checksum-error
    # bits are a *separate* compat register upstream, never returned here).
    fn read_status_flags(self) -> u8:
        let mut v = 0 as u8
        if self.rx_available:
            v = bit_set(v, 0)
        if self.tx_complete:
            v = bit_set(v, 1)
        v

    # SERFSTAT (new opcode, todo.md P2 #3): the "separate compat register"
    # `read_status_flags`'s own comment above refers to -- framed-mode
    # enabled (bit 2) and latched checksum-error (bit 4), matching the
    # doc's own bit assignments (`docs/UART_SYSTEM.md`'s status-bits table).
    # Reading clears the latched checksum error, matching this port's
    # existing "read consumes" idiom (`SERIN`/`KEYIN`).
    fn read_extended_status(mut self) -> u8:
        let mut v = 0 as u8
        if self.framed_mode:
            v = bit_set(v, 2)
        if self.frame_checksum_error:
            v = bit_set(v, 4)
        self.frame_checksum_error = false
        v

    # SERCTRL: update control bits + IRQ enable. Matches `write_control`'s
    # "low two status-shaped bits are directly reflected into rx_available/
    # tx_complete" quirk -- easy to misread as nonsensical (control bits
    # driving status bits?) but that's genuinely what the reference does.
    # Bit 2 (`0x04`) now also drives `framed_mode` (todo.md P2 #3) -- the
    # doc already documented this bit's meaning, this port just never wired
    # it to anything until framed-mode parsing existed to gate.
    fn write_control(mut self, control: u8):
        let c = control & (0x7F as u8)
        self.control = c
        self.interrupt_enabled = bit_get(c, 0)
        self.rx_available = bit_get(c, 0)
        self.tx_complete = bit_get(c, 1)
        self.framed_mode = bit_get(c, 2)

    # SERIN: in framed mode with queued payload bytes, drains the FIFO one
    # byte at a time (the genuinely-a-FIFO path framed mode adds -- see
    # header). Otherwise falls back to the original raw-mode behavior
    # unchanged: reads the data register -- either the last byte a real host
    # bridge pushed in via `host_push_rx`, or (the pre-host-bridge loopback
    # path, still exact for any program that never receives host input)
    # whatever `SEROUT` last wrote. Consuming a host-pushed byte clears
    # `rx_available`, matching a real UART's "read the data register, the
    # available flag drops" contract -- `write_control`'s own bit-0 quirk
    # (see header) can still set it back independent of this.
    fn read_data(mut self) -> u8:
        if self.framed_mode and self.rx_count > 0:
            let v = self.rx_queue[self.rx_head]
            self.rx_head = (self.rx_head + 1) % RX_QUEUE_SIZE
            self.rx_count -= 1
            self.data_register = v
            self.rx_available = self.rx_count > 0
            v
        else:
            self.rx_available = false
            self.data_register

    # Push one decoded frame payload byte into the RX FIFO (framed mode
    # only) -- shared by `parse_frame_byte`'s success path.
    fn queue_rx_byte(mut self, value: u8):
        if self.rx_count < RX_QUEUE_SIZE:
            self.rx_queue[self.rx_tail] = value
            self.rx_tail = (self.rx_tail + 1) % RX_QUEUE_SIZE
            self.rx_count += 1
        self.rx_available = self.rx_count > 0

    # Framed-mode byte-at-a-time parser (todo.md P2 #3) -- `host_push_rx`
    # below hands each incoming byte here instead of the raw single-register
    # path while `framed_mode` is on. START -> LENGTH -> PAYLOAD*length ->
    # CHECKSUM, resyncing to IDLE after either a completed frame or a
    # checksum mismatch (see header for the idle-byte-drop judgment call).
    fn parse_frame_byte(mut self, value: u8):
        if self.frame_state == FRAME_STATE_IDLE:
            if value == FRAME_START_BYTE:
                self.frame_state = FRAME_STATE_LENGTH
        elif self.frame_state == FRAME_STATE_LENGTH:
            self.frame_len = value
            self.frame_pos = 0
            if self.frame_len == (0 as u8):
                self.frame_state = FRAME_STATE_CHECKSUM
            else:
                self.frame_state = FRAME_STATE_PAYLOAD
        elif self.frame_state == FRAME_STATE_PAYLOAD:
            self.frame_buf[self.frame_pos] = value
            self.frame_pos += 1
            if self.frame_pos >= (self.frame_len as i32):
                self.frame_state = FRAME_STATE_CHECKSUM
        else:
            # Accumulate in `i32` and mask down with a truncating cast
            # rather than summing `u8`s directly -- plain `u8` arithmetic
            # traps on overflow in this language (Star's numeric-overflow
            # philosophy, `docs/design.md`), unlike a real UART's silent
            # wraparound; `mask_to_width`'s own `(value as u8) as i32`
            # pattern above is this same "compute wide, cast down" idiom.
            let mut sum = 0
            let mut i = 0
            while i < self.frame_pos:
                sum = sum + (self.frame_buf[i] as i32)
                i += 1
            let checksum = (sum as u8)
            if value == checksum:
                i = 0
                while i < self.frame_pos:
                    self.queue_rx_byte(self.frame_buf[i])
                    i += 1
            else:
                self.frame_checksum_error = true
            if self.interrupt_enabled:
                self.pending_interrupt = true
            self.frame_state = FRAME_STATE_IDLE

    # Host-bridge RX: a real byte arrived from outside the running program
    # (typed at the console, piped into stdin -- see `../uart_bridge.star`).
    # In framed mode, hands the byte to the frame parser above instead of
    # the raw single-register path. Raw-mode behavior is exactly as before:
    # overwrites `data_register` the same way `write_data`/`SEROUT` does --
    # this is a single-register model, not a FIFO (see header) -- and raises
    # the serial interrupt if enabled, mirroring `write_data`'s own TX-side
    # interrupt behavior.
    fn host_push_rx(mut self, value: u8):
        if self.framed_mode:
            self.parse_frame_byte(value)
        else:
            self.data_register = value
            self.rx_available = true
            if self.interrupt_enabled:
                self.pending_interrupt = true

    # SEROUT: stage the byte and report TX-complete immediately (no real
    # transport to wait on).
    fn write_data(mut self, value: u8):
        self.data_register = value
        self.tx_complete = true
        if self.interrupt_enabled:
            self.pending_interrupt = true

    fn irq_pending(self) -> bool:
        self.pending_interrupt

    fn clear_irq_pending(mut self):
        self.pending_interrupt = false
