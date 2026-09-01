# Headless regression test for UART framed-mode parsing (todo.md P2 #3):
# `SERCTRL`'s control bit 2 (framed-mode enable), the new `SERFSTAT` opcode
# (0xB4, extended status), and the frame parser wired into
# `Uart::host_push_rx` (`../uart.star`). Runs the real assembled program
# `tests/asm/uart_framed_test.asm` (its own header comment has the full
# design) through `Cpu::step()` -- SERCTRL/SERFSTAT/SERIN all execute as
# real opcodes here, not hand-poked fields. The one piece with no opcode-
# reachable way to drive it end to end is the frame *bytes* themselves (no
# opcode can inject RX bytes -- same situation as raw mode, and the same
# reason `mouse_pending_irq` has no opcode-reachable driver either, see
# `mouse_interrupt_test.star`), so this harness calls `host_push_rx`
# directly, between bursts of `step()`, exactly like `../uart_bridge.star`'s
# interactive loop does for a real host bridge -- just with a scripted byte
# sequence instead of a human typing.
#
# Build: star build projects/nova/tests/uart_framed_test.star -L sdl/lib/x64
#   -l SDL2 -o projects/nova/tests/uart_framed_test.exe (SDL2 is a link-time
#   requirement only, transitively pulled in via cpu_sound.star -- same as
#   run_bin.star, see its own header comment's "Correction" note).
# Usage: run from `projects/nova` as the working directory (cwd) --
#   `tests\uart_framed_test.exe`, no arguments, prints PASS/FAIL lines. Two
#   things depend on that cwd, both pre-existing conditions this harness
#   just inherits, not new: the hardcoded `tests/asm/uart_framed_test.bin`
#   load path below, and Windows DLL search order finding `SDL2.dll` (it
#   lives in `projects/nova/`, not `projects/nova/tests/` alongside this
#   built exe -- the current directory is one of the paths Windows searches
#   for a dependent DLL, the exe's own directory is not enough here). Same
#   two constraints already apply unremarked-on to `run_bin.exe`, which
#   also lives in `tests/` and also needs `-l SDL2`.

import "../cpu.star" as cpu
import "../cpu_data.star" as cpu_data
import "../cpu_arith.star" as cpu_arith
import "../cpu_math.star" as cpu_math
import "../cpu_bitwise.star" as cpu_bitwise
import "../cpu_stack.star" as cpu_stack
import "../cpu_control.star" as cpu_control
import "../cpu_mem.star" as cpu_mem
import "../cpu_graphics.star" as cpu_graphics
import "../cpu_io.star" as cpu_io
import "../cpu_sound.star" as cpu_sound
import "../cpu_string.star" as cpu_string
import "../memory.star" as mem
import "../screen.star" as screen
import "../keyboard.star" as keyboard
import "../flags.star" as flg
import "../loader.star" as loader
import "../uart.star" as uart

# Identical to `../uart_bridge.star`/`run_bin.star`'s own inline `Cpu`
# construction -- see `../loader.star`'s header comment for why `Cpu` is
# built once here rather than factored into a shared helper.
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

impl cpu::Cpu:
    fn run_burst(mut self, burst: i32):
        let mut n = 0
        while !self.halted and n < burst:
            self.step()
            n += 1

fn check(name: str, got: i32, expected: i32):
    if got == expected:
        println(f"PASS {name}")
    else:
        println(f"FAIL {name}: got {got}, expected {expected}")

fn check_bool(name: str, got: bool, expected: bool):
    if got == expected:
        println(f"PASS {name}")
    else:
        println(f"FAIL {name}: got {got}, expected {expected}")

fn main():
    let mut c = new_cpu()
    let (entry_point, ok) = c.load_program("tests/asm/uart_framed_test.bin")
    if !ok:
        println("could not open tests/asm/uart_framed_test.bin")
        return
    c.pc = Wrapping<u16>(entry_point as u16)

    # Run past MOV P0,0xDEAD / SERCTRL 0x04 / the two SERFSTAT enable-check
    # blocks, landing in the WAIT_GOOD_1 polling loop (framed_mode is now
    # on, so the frame bytes below actually reach the parser instead of the
    # raw single-register path).
    c.run_burst(40)

    # Good frame: START, LENGTH=2, payload 0x11/0x22, CHECKSUM=sum&0xFF.
    c.uart.host_push_rx(0x7E as u8)
    c.uart.host_push_rx(0x02 as u8)
    c.uart.host_push_rx(0x11 as u8)
    c.uart.host_push_rx(0x22 as u8)
    c.uart.host_push_rx(0x33 as u8)
    c.run_burst(4000)

    # Bad frame: START, LENGTH=1, payload 0x99, a deliberately wrong
    # checksum (0x99's real sum is 0x99 -- 0x01 is guaranteed not to match).
    c.uart.host_push_rx(0x7E as u8)
    c.uart.host_push_rx(0x01 as u8)
    c.uart.host_push_rx(0x99 as u8)
    c.uart.host_push_rx(0x01 as u8)
    c.run_burst(4000)

    check_bool("program halted", c.halted, true)
    check("R0 (no checksum error after good frame)", (c.r[0] as u8) as i32, 0x00)
    check("R1 (rx-available seen twice)", (c.r[1] as u8) as i32, 0x01)
    check("R2 (first payload byte via SERIN)", (c.r[2] as u8) as i32, 0x11)
    check("R3 (second payload byte via SERIN)", (c.r[3] as u8) as i32, 0x22)
    check("R4 (no checksum error latched after good frame)", (c.r[4] as u8) as i32, 0x00)
    check("R5 (checksum error latched after bad frame)", (c.r[5] as u8) as i32, 0x10)
    check("R6 (bad frame's payload never reached RX FIFO)", (c.r[6] as u8) as i32, 0x00)
    check("R7 (SERFSTAT read-clears checksum error)", (c.r[7] as u8) as i32, 0x00)
    check("P0 pass/fail marker", (c.p[0] as u16) as i32, 0xBEEF)
