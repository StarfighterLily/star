# Nova-16 headless UART host bridge (todo.md P0 #1) -- the actual "real
# host bridge" `uart.star`'s header comment promises: a second, non-graphical
# entry point (alongside `main.star`) that feeds real host stdin bytes into
# a running program's `SERIN` path via `Uart::host_push_rx`, and shows every
# `SEROUT`-transmitted byte as it happens (see `cpu.star::op_serout`, which
# prints to this same process's stdout directly -- no plumbing needed here
# for TX, only for RX).
#
# Why stdin/stdout and not TCP: `net.rs`'s `tcp_recv` is a single blocking
# `recv` call with no non-blocking/timeout mode exposed at the language
# level (no `ioctlsocket`/`setsockopt` builtin exists), so wiring a TCP
# bridge into a real-time loop would freeze on every read with no peer data
# ready -- exactly the problem `main.star`'s graphical loop can't tolerate,
# which is why this bridge is its own separate headless tool instead of
# being wired into `main.star`'s per-frame loop. A terminal, by contrast, is
# *supposed* to block waiting for the next line of human input between
# bursts of CPU execution -- that's just how an interactive console program
# behaves, not a limitation being worked around. `read_line()` (an existing
# builtin, no new language surface needed, matching todo.md P0 #1's own
# framing) already gives exactly that: block for one line, then hand every
# byte of it to the running program before blocking again.
#
# Usage:
#   star build projects/nova/uart_bridge.star -o projects/nova/uart_bridge.exe
#   projects/nova/uart_bridge.exe path/to/prog.bin [burst_cycles]
# Type a line and press Enter to push its bytes into the UART RX path one at
# a time (each followed by a burst of CPU execution so the program can react
# before the next byte arrives -- a real UART receives one byte at a time
# too, this isn't a simplification unique to this bridge). Bytes the program
# transmits via SEROUT appear on this same console as they're sent. An empty
# line (EOF, e.g. redirecting stdin from an already-exhausted pipe) ends the
# session.

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
# `tests/run_bin.star`'s identical reuse (a second `extern "C" fn atoi`
# declaration here would conflict with that one).

# Identical to `tests/run_bin.star::new_cpu` / `main.star::main`'s inline
# `Cpu` construction -- see `loader.star`'s header comment for why `Cpu` is
# built once here rather than factored into a shared helper (a large struct
# this project deliberately never passes around by value).
fn new_cpu() -> cpu::Cpu:
    cpu::Cpu(
        mem = mem::new_memory(),
        screen = screen::new_screen(),
        kbd = keyboard::Keyboard(buffer = [0 as u8; 64], head = 0, tail = 0, count = 0, status = 0 as u8, control = 0 as u8),
        flags = flg::Flags(bits = BitField<16>(0)),
        uart = uart::new_uart(),
        r = [Wrapping<u8>(0 as u8); 10],
        # SP (P8)/FP (P9) reset to 0xFFFF, matching `main.star`'s identical
        # fix -- see its own comment on this same field for the full bug
        # writeup (found via `debugger.star`'s `stack` command).
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

# Runs up to `burst` instructions (fewer if the program halts first) --
# shared by the initial run (letting the program reach its first `SERIN`
# wait loop) and the post-injection runs (letting it react to each byte). A
# method via a cross-module `impl` (`loader.star`'s own "gotcha #6" pattern)
# rather than a free function taking `Cpu` by value, on purpose -- see
# `loader.star`'s header comment for why this project avoids by-value `Cpu`
# parameters (a real whole-struct `memcpy` per call) in favor of `self`.
impl cpu::Cpu:
    fn run_burst(mut self, burst: i32):
        let mut n = 0
        while !self.halted and n < burst:
            self.step()
            n += 1

fn main():
    let cli = args()
    if cli.len() < 2:
        println("usage: uart_bridge <path.bin> [burst_cycles]")
        return

    let mut c = new_cpu()
    let (entry_point, ok) = c.load_program(cli[1])
    if !ok:
        println(f"could not open '{cli[1]}'")
        return
    c.pc = Wrapping<u16>(entry_point as u16)

    let mut burst = 2000
    if cli.len() > 2:
        burst = atoi(cli[2])

    println("uart_bridge: type a line + Enter to feed bytes into SERIN; SEROUT output appears inline below. Empty line/EOF exits.")
    c.run_burst(burst)

    let mut going = !c.halted
    while going:
        let line = read_line()
        if len(line) == 0:
            going = false
        else:
            let data = bytes_from_str(line)
            let mut i = 0
            while i < data.len() and !c.halted:
                c.uart.host_push_rx(data[i])
                c.run_burst(burst)
                i += 1
            if c.halted:
                going = false

    println(f"\nuart_bridge: halted={c.halted} pc={c.pc}")
