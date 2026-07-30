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
# Still deliberately not ported: TCP transport and framed-mode parsing.
# Nothing ISA-visible needs them (no opcode drives framing), and this port's
# minimal host bridge only needed one transport, not all three upstream
# offers -- see `../uart_bridge.star`'s header comment for why stdin/stdout
# was picked over a TCP bridge. `write_control`'s "low two status-shaped
# control bits are directly reflected into rx_available/tx_complete" quirk
# (below) predates the host bridge and still applies to it unchanged: an
# `SERCTRL` write can flip `rx_available` on its own, independent of
# whether `host_push_rx` has actually been called -- a real quirk this port
# verified against the reference, not a new bug introduced by this file.

const STATUS_RX_AVAILABLE: u8 = 0x01 as u8
const STATUS_TX_COMPLETE: u8 = 0x02 as u8
const STATUS_IRQ_PENDING: u8 = 0x80 as u8

const CONTROL_IRQ_ENABLE: u8 = 0x01 as u8

struct Uart:
    mut data_register: u8
    mut control: u8
    mut interrupt_enabled: bool
    mut rx_available: bool
    mut tx_complete: bool
    mut pending_interrupt: bool

fn new_uart() -> Uart:
    Uart(data_register = 0 as u8, control = 0 as u8, interrupt_enabled = false, rx_available = false, tx_complete = false, pending_interrupt = false)

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

    # SERCTRL: update control bits + IRQ enable. Matches `write_control`'s
    # "low two status-shaped bits are directly reflected into rx_available/
    # tx_complete" quirk -- easy to misread as nonsensical (control bits
    # driving status bits?) but that's genuinely what the reference does.
    fn write_control(mut self, control: u8):
        let c = control & (0x7F as u8)
        self.control = c
        self.interrupt_enabled = bit_get(c, 0)
        self.rx_available = bit_get(c, 0)
        self.tx_complete = bit_get(c, 1)

    # SERIN: reads the data register -- either the last byte a real host
    # bridge pushed in via `host_push_rx`, or (the pre-host-bridge loopback
    # path, still exact for any program that never receives host input)
    # whatever `SEROUT` last wrote. Consuming a host-pushed byte clears
    # `rx_available`, matching a real UART's "read the data register, the
    # available flag drops" contract -- `write_control`'s own bit-0 quirk
    # (see header) can still set it back independent of this.
    fn read_data(mut self) -> u8:
        self.rx_available = false
        self.data_register

    # Host-bridge RX: a real byte arrived from outside the running program
    # (typed at the console, piped into stdin -- see `../uart_bridge.star`).
    # Overwrites `data_register` the same way `write_data`/`SEROUT` does --
    # this is a single-register model, not a FIFO (see header) -- and raises
    # the serial interrupt if enabled, mirroring `write_data`'s own TX-side
    # interrupt behavior.
    fn host_push_rx(mut self, value: u8):
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
