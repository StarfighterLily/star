# Nova-16 headless UART TCP host bridge (this round: `net.rs`'s
# `tcp_set_nonblocking` + would-block-aware `tcp_recv`, plus `uart.star`'s
# new `tx_queue`/`drain_tx_byte`) -- the `TCPSocketBridge`-equivalent
# `../uart_bridge.star`'s own header comment used to describe as out of
# scope (upstream Python reference naming; see NOTES.md's "UART" section).
# A TCP *client* only: this language has no `listen`/`accept` builtins, only
# `tcp_connect`, so this dials out to a host:port -- something like `socat
# TCP-LISTEN:9999,reuseaddr,fork EXEC:'cat'` or a real terminal server on the
# other end, mirroring how `uart_bridge.star` treats "whatever's attached to
# this process's stdin/stdout" as the host on the other end of the wire.
#
# Why this didn't exist before: `net.rs`'s `tcp_recv` used to be a single
# blocking `recv` call with no non-blocking/timeout mode, so a naive TCP
# bridge loop would freeze on every read with no peer data ready -- fatal
# for a bridge that also needs to keep running the CPU between reads. Now
# that `tcp_set_nonblocking(handle, true)` exists and `tcp_recv` returns a
# null `ptr` (checked via `is_null`) instead of `""` specifically when
# there's no data yet (`""` still means "the peer closed"), this loop can
# poll for incoming bytes without ever blocking the CPU's own progress.
#
# TX side: `op_serout` (`cpu_io.star`) still prints every transmitted byte
# to this process's own stdout unconditionally -- unchanged, and still fine
# for watching a session interactively. Independently, `uart.star::write_data`
# now also queues every transmitted byte into a real FIFO (`tx_queue`), which
# this bridge drains every iteration via `drain_tx_byte` and forwards over
# the TCP connection with `tcp_send` -- so the remote peer sees the same
# bytes a local terminal watching stdout would.
#
# Pacing: there's no plain `sleep` builtin in this language (only `delay`,
# which wraps `SDL_Delay` and would drag in an SDL link dependency this
# otherwise-headless bridge has never needed -- see `uart_bridge.star`'s own
# header comment on staying headless). This loop is therefore a genuine busy
# poll: every outer iteration does a non-blocking `tcp_recv` plus a CPU
# burst with no sleep in between. That's a real, deliberate tradeoff (one
# CPU core pegged at 100% for the lifetime of the bridge) rather than an
# oversight -- acceptable for a headless dev/test tool, not something a
# production terminal server would want unmodified.
#
# Usage:
#   star build projects/nova/uart_tcp_bridge.star -o projects/nova/uart_tcp_bridge.exe -l ws2_32 -L sdl/lib/x64 -l SDL2
#   projects/nova/uart_tcp_bridge.exe path/to/prog.bin <host> <port> [burst_cycles]
# `-l ws2_32` is needed for `tcp_*`; `-L`/`-l SDL2` for the same transitive
# `cpu_sound.star` reason `../uart_bridge.star`'s own header comment now
# documents (found and fixed there while building this file).
# Connects to `host:port`, runs the program, and bridges bytes both ways
# until the program halts or the peer closes the connection.

import "cpu.star" as cpu
import "cpu_data.star" as cpu_data
import "cpu_arith.star" as cpu_arith
import "cpu_math.star" as cpu_math
import "cpu_bitwise.star" as cpu_bitwise
import "cpu_stack.star" as cpu_stack
import "cpu_control.star" as cpu_control
import "cpu_mem.star" as cpu_mem
import "cpu_graphics.star" as cpu_graphics
import "cpu_io.star" as cpu_io
import "cpu_sound.star" as cpu_sound
import "cpu_string.star" as cpu_string
import "memory.star" as mem
import "screen.star" as screen
import "keyboard.star" as keyboard
import "flags.star" as flg
import "loader.star" as loader
import "uart.star" as uart

# `atoi` comes from `loader.star`'s own `extern "C"` declaration -- already
# visible transitively through the `import "loader.star"` above, matching
# `uart_bridge.star`'s identical reuse (a second `extern "C" fn atoi`
# declaration here would conflict with that one).

# Identical to `uart_bridge.star::new_cpu` -- see its own header comment for
# why `Cpu` is built once here rather than factored into a shared helper (a
# large struct this project deliberately never passes around by value).
fn new_cpu() -> cpu::Cpu:
    cpu::Cpu(
        mem = mem::new_memory(),
        screen = screen::new_screen(),
        kbd = keyboard::Keyboard(buffer = [0 as u8; 64], head = 0, tail = 0, count = 0, status = 0 as u8, control = 0 as u8, debounce_ms = keyboard::DEFAULT_DEBOUNCE_MS, last_press = [-1; 256]),
        flags = flg::Flags(bits = BitField<16>(0)),
        uart = uart::new_uart(),
        r = [Wrapping<u8>(0 as u8); 10],
        p = [
            Wrapping<u16>(0 as u16), Wrapping<u16>(0 as u16), Wrapping<u16>(0 as u16),
            Wrapping<u16>(0 as u16), Wrapping<u16>(0 as u16), Wrapping<u16>(0 as u16),
            Wrapping<u16>(0 as u16), Wrapping<u16>(0 as u16),
            Wrapping<u16>(0xFFFF as u16), Wrapping<u16>(0xFFFF as u16),
        ],
        pc = Wrapping<u16>(0 as u16),
        vx = Wrapping<u8>(0 as u8),
        vy = Wrapping<u8>(0 as u8),
        vc = Wrapping<u8>(0 as u8),
        vm = 0 as u8,
        vl = 0 as u8,
        tt = Wrapping<u8>(0 as u8),
        tm = Wrapping<u8>(0 as u8),
        tc = Wrapping<u8>(0 as u8),
        ts = Wrapping<u8>(0 as u8),
        timer_subcycle = 0,
        pending_timer_irq = false,
        sa = Wrapping<u16>(0 as u16),
        sf = Wrapping<u8>(0 as u8),
        sv = Wrapping<u8>(0 as u8),
        sw = Wrapping<u8>(0 as u8),
        next_strig_channel = 8,
        sound_channel_handles = [null_ptr(); 16],
        sound_channel_last_wav = cpu::new_channel_wav_cache(),
        mx = Wrapping<u8>(0 as u8),
        my = Wrapping<u8>(0 as u8),
        mb = Wrapping<u8>(0 as u8),
        mouse_enabled = false,
        mouse_pending_irq = false,
        c0 = Wrapping<u16>(0 as u16),
        c1 = Wrapping<u16>(0 as u16),
        halted = false,
        cycles = 0 as i64,
    )

# Identical to `uart_bridge.star::Cpu::run_burst` -- see its own comment.
impl cpu::Cpu:
    fn run_burst(mut self, burst: i32):
        let mut n = 0
        while !self.halted and n < burst:
            self.step()
            n += 1

    # Drains every byte `SEROUT` has queued since the last call and forwards
    # each one over `handle` with `tcp_send`. `chr(b as i32)` inherits the
    # same embedded-NUL limitation `cpu_io.star::op_serout`'s own doc comment
    # already flags for `print(chr(..))`: a transmitted `0x00` byte becomes
    # an empty `str` and `tcp_send`s zero bytes, not a real `0x00` over the
    # wire -- a pre-existing gap in `chr`/`str` themselves, not new here.
    fn drain_tx_to_tcp(mut self, handle: ptr):
        let mut draining = true
        while draining:
            let (b, had) = self.uart.drain_tx_byte()
            if had:
                let sent = tcp_send(handle, chr(b as i32))
            else:
                draining = false

fn main():
    let cli = args()
    if cli.len() < 4:
        println("usage: uart_tcp_bridge <path.bin> <host> <port> [burst_cycles]")
        return

    let mut c = new_cpu()
    let (entry_point, ok) = c.load_program(cli[1])
    if !ok:
        println(f"could not open '{cli[1]}'")
        return
    c.pc = Wrapping<u16>(entry_point as u16)

    let host = cli[2]
    let port = atoi(cli[3])

    let mut burst = 2000
    if cli.len() > 4:
        burst = atoi(cli[4])

    let h = tcp_connect(host, port)
    if is_null(h):
        println(f"uart_tcp_bridge: could not connect to {host}:{port}")
        return
    let enabled = tcp_set_nonblocking(h, true)
    if !enabled:
        println("uart_tcp_bridge: failed to enable non-blocking mode on the socket")
        tcp_close(h)
        return

    println(f"uart_tcp_bridge: connected to {host}:{port}; bridging SERIN/SEROUT over TCP. Ctrl+C to stop.")
    c.run_burst(burst)

    let mut going = !c.halted
    while going:
        c.drain_tx_to_tcp(h)

        # Non-blocking poll: a null `reply` means "nothing arrived yet, the
        # connection is still alive" (see `net.rs`'s module doc comment for
        # `tcp_set_nonblocking`/`tcp_recv`'s would-block convention) -- keep
        # the CPU moving rather than treating it as a close. An empty `""`
        # (as opposed to null) still means the peer actually closed.
        #
        # Known, inherited gap (confirmed while smoke-testing this file, same
        # root cause `cpu_io.star::op_serout`'s own doc comment already
        # flags for `print(chr(..))`): `str` is NUL-terminated, so a real
        # single-byte payload of `0x00` also makes `len(reply) == 0` here,
        # indistinguishable from a true zero-byte close. `tcp_recv` itself
        # still reports the right thing (a live "no data"/`is_null` case
        # never lands here at all) -- this is `str`'s own representation
        # limit, not a `tcp_recv` bug, and not something this floor-level
        # bridge works around; a peer bridging binary data where `0x00` is a
        # legitimate payload byte would need a `Bytes`-based `tcp_recv`
        # sibling, which doesn't exist (out of scope here, see `net.rs`'s
        # own module doc comment for this round's actual scope).
        let reply = tcp_recv(h)
        if !is_null(reply):
            if len(reply) == 0:
                println("\nuart_tcp_bridge: peer closed the connection")
                going = false
            else:
                # A `run_burst` between each pushed byte, exactly like
                # `uart_bridge.star::main`'s identical loop -- raw mode's
                # `host_push_rx` overwrites the single `data_register`
                # (no FIFO, see `uart.star`'s header comment), so pushing a
                # whole chunk back-to-back with no CPU steps in between
                # would silently drop every byte but the last one the
                # program never got a chance to `SERIN` first.
                let data = bytes_from_str(reply)
                let mut i = 0
                while i < data.len() and !c.halted:
                    c.uart.host_push_rx(data[i])
                    c.run_burst(burst)
                    i += 1

        c.run_burst(burst)
        if c.halted:
            going = false

    # One last drain so a final burst of `SEROUT` bytes right before halting
    # still reaches the peer instead of sitting in `tx_queue` unsent.
    c.drain_tx_to_tcp(h)
    tcp_close(h)
    println(f"\nuart_tcp_bridge: halted={c.halted} pc={c.pc}")
