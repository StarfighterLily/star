# Nova-16 UART: 8-bit data register, status/control bits, and RX/TX
# interrupt-pending signaling (docs/UART_SYSTEM.md, ported from
# `nova_uart.py::NovaUART`'s raw-mode data path).
#
# Deliberately not ported: the host bridge (`LocalTerminalBridge`/
# `TCPSocketBridge`/`TCPServerBridge`) and framed-mode parsing. Both exist
# upstream purely to get bytes *into* the RX path from outside the running
# program (a host terminal, a TCP peer) -- there is no opcode that lets a
# Nova-16 program push a byte into its own RX FIFO, so without a host bridge
# feeding it, `rx_fifo` can never hold anything a real program could ever
# observe: `SERIN` always ends up reading back `data_register`, i.e.
# whatever `SEROUT` last wrote (the exact loopback-on-empty-RX-FIFO path
# `read_data()` already falls through to upstream, confirmed against
# `asm/uart_integration_test.asm`'s own SEROUT-then-SERIN check, which never
# touches a host bridge either). This mirrors how `MOUSECTRL`'s register
# model was already fully in place, ISA-reachable, and testable long before
# real host mouse events existed -- see `main.star`'s mouse plumbing for the
# same pattern applied for real. A future host bridge (piping actual stdin
# into `rx_available`/`data_register`) would slot in later without changing
# any of this file's opcode-facing surface.

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

    # SERIN: pop RX (never non-empty without a host bridge -- see header) or
    # fall back to the data register, i.e. whatever SEROUT last wrote.
    fn read_data(mut self) -> u8:
        self.data_register

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
