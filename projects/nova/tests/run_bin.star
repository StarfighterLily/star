# Headless Nova-16 program runner/checker -- loads a real assembled `.bin`
# (see ../loader.star) via the command line, runs it to completion (or a
# cycle cap), and prints every general-purpose/pointer register plus the
# halted flag, so a shell-level test can `grep`/compare the output instead of
# needing an in-language assertion facility (Star has none -- see NOTES.md's
# "Testing" section). This is the reusable half of this project's new
# binary-loader-driven test workflow; see NOTES.md for how each opcode-group
# round below actually uses it.
#
# Usage: run_bin.exe <path/to/program.bin> [max_cycles]
# (built via: star build projects/nova/tests/run_bin.star -L sdl/lib/x64 -l SDL2 -o projects/nova/tests/run_bin.exe --
# this harness never opens a window, but `-l SDL2` is required regardless
# now that `cpu.star` transitively pulls in `sound.star`'s audio builtins
# for SPLAY/SSTOP/STRIG, todo.md P0 #1 -- omitting it fails at link time
# with undefined `SDL_Init`/`SDL_OpenAudioDevice`/etc, not at build time.)

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

fn main():
    let cli = args()
    if cli.len() < 2:
        println("usage: run_bin <path.bin> [max_cycles]")
        return

    let mut max_cycles = 100000
    if cli.len() > 2:
        max_cycles = atoi(cli[2])

    let mut c = new_cpu()
    let (entry_point, ok) = c.load_program(cli[1])
    if !ok:
        println(f"could not open '{cli[1]}'")
        return
    c.pc = Wrapping<u16>(entry_point as u16)

    let mut n = 0
    while !c.halted and n < max_cycles:
        c.step()
        n += 1

    println(f"halted={c.halted} cycles_run={n} pc={c.pc}")
    let mut i = 0
    while i < 10:
        println(f"R{i}={c.r[i]}")
        i += 1
    i = 0
    while i < 10:
        println(f"P{i}={c.p[i]}")
        i += 1

    if cli.len() > 3:
        let dump_start = atoi(cli[3])
        let mut dump_len = 16
        if cli.len() > 4:
            dump_len = atoi(cli[4])
        let mut j = 0
        while j < dump_len:
            println(f"mem[{dump_start + j}]={c.mem.read_byte(dump_start + j)}")
            j += 1
