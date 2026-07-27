# Nova-16 fantasy computer -- native emulator entry point: opens the host
# window, builds the CPU/memory/screen/keyboard state, loads a small
# built-in demo program (see NOTES.md -- there's no assembler in this port,
# and reading an arbitrary compiled `.bin` isn't safe yet either: Star's
# `file_read` returns a `str`, whose `len()`/indexing appear to rely on
# `strlen` under the hood and truncate at the first embedded 0x00 byte,
# which any real Nova-16 program is virtually guaranteed to contain --
# HLT alone is opcode 0. A byte-count-based binary reader is future work),
# and runs the fetch-decode-execute loop, presenting the 256x256 indexed
# screen through the palette every frame.
#
# Build (from the repo root, SDL2 must be linked explicitly):
#   star build projects/nova/main.star -L sdl/lib/x64 -l SDL2 -o projects/nova/nova16.exe
# `sdl/lib/x64/SDL2.dll` must be next to the built .exe (or on PATH) to run.

import "cpu.star" as cpu
import "memory.star" as mem
import "screen.star" as screen
import "keyboard.star" as keyboard
import "flags.star" as flg
import "font_data.star" as fontdata
import "palette.star" as pal

const SCREEN_SIZE: i32 = 256

# A tiny built-in demo: fills the screen with a diagonal-stripe pattern
# using SWRITE in a double loop, then jumps back to address 0 forever (so
# the window stays open and responsive instead of halting after one
# frame). Encoded by hand against docs/nova16_instruction_reference.md's
# opcode table and docs/Operand prefix system.md's mode-byte layout --
# verified headlessly against the exact expected pixel values before
# wiring it up here; see NOTES.md for the byte-by-byte trace and the two
# encoding bugs that first draft had (a wrong mode byte, and a loop
# condition -- "R0 <= 255" -- that can never be false for an 8-bit
# register, fixed by switching to the standard INC-then-JNZ idiom, which
# terminates cleanly on the 8-bit wraparound instead).
fn demo_program() -> List<i32>:
    let prog: List<i32> = [
        # R0 = 0 (x), R1 = 0 (y)                                   addr
        6, 4, 231, 0,                                              # 0
        6, 4, 232, 0,                                              # 4
        # outer_y: MOV VY, R1                                      8
        6, 0, 254, 232,
        # R0 = 0 (reset x at the start of every row)               12
        6, 4, 231, 0,
        # inner_x: MOV VX, R0                                      16
        6, 0, 253, 231,
        # R2 = R0 + R1 (color = x + y, wraps to a diagonal ramp)    20
        6, 4, 233, 0,
        7, 0, 233, 231,
        7, 0, 233, 232,
        # SWRITE R2                                                32
        51, 0, 233,
        # INC R0 ; JNZ inner_x (addr 16, i.e. loop while x != 0     35
        # after the increment -- covers all 256 values via wraparound)
        11, 0, 231,
        32, 2, 0, 16,
        # INC R1 ; JNZ outer_y (addr 8, same wraparound idiom)      42
        11, 0, 232,
        32, 2, 0, 8,
        # JMP back to addr 0 (redraw forever)                      49
        30, 2, 0, 0,
    ]
    prog

fn main():
    let w = window_create("Nova-16", SCREEN_SIZE * 2, SCREEN_SIZE * 2)
    if is_null(w):
        println("window_create failed")
        return

    let mut c = cpu::Cpu(
        mem = mem::Memory(ram = [0 as u8; 65536], bank_ram = [0 as u8; 245760], bank = 0 as u8),
        screen = screen::Screen(screen = [0 as u8; 65536], vram = [0 as u8; 65536], font = fontdata::new_font_data()),
        kbd = keyboard::Keyboard(buffer = [0 as u8; 64], head = 0, tail = 0, count = 0, status = 0 as u8, control = 0 as u8),
        flags = flg::StatusFlags(bits = BitField<16>(0)),
        r = [Wrapping<u8>(0 as u8); 10],
        p = [Wrapping<u16>(0 as u16); 10],
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
        mx = Wrapping<u8>(0 as u8),
        my = Wrapping<u8>(0 as u8),
        mb = Wrapping<u8>(0 as u8),
        c0 = Wrapping<u16>(0 as u16),
        c1 = Wrapping<u16>(0 as u16),
        halted = false,
        cycles = 0 as i64,
    )

    let prog = demo_program()
    let mut load_i = 0
    while load_i < prog.len():
        c.mem.write_byte(load_i, prog[load_i] as u8)
        load_i += 1
    c.pc = Wrapping<u16>(0 as u16)

    let escape_sc = 41
    # A small, arbitrary host-scancode -> Nova-16 key-code map (letters A-Z
    # start at SDL scancode 4). Good enough to prove KEYIN/KEYSTAT/KEYCOUNT/
    # KEYCLEAR/KEYCTRL work end to end; not a full keyboard layout -- see
    # NOTES.md.
    let mut prev_down: [bool; 26] = [false; 26]

    while !window_should_close(w):
        if key_down(escape_sc):
            break

        let mut k = 0
        while k < 26:
            let sc = 4 + k
            let down = key_down(sc)
            if down and !prev_down[k]:
                c.kbd.push_key((65 + k) as u8)
            prev_down[k] = down
            k += 1

        let mut n = 0
        while !c.halted and n < 20000:
            c.step()
            n += 1

        clear_screen(w, Color32(0, 0, 0, 255))
        let mut y = 0
        while y < SCREEN_SIZE:
            let mut x = 0
            while x < SCREEN_SIZE:
                let idx = c.screen.get_screen(x, y)
                if idx != (0 as u8):
                    let rgb = pal::palette_color(idx)
                    draw_rect(w, x * 2, y * 2, 2, 2, Color32(rgb.0 as i32, rgb.1 as i32, rgb.2 as i32, 255))
                x += 1
            y += 1
        present(w)
        delay(16)
