# Nova-16 fantasy computer -- native emulator entry point: opens the host
# window, builds the CPU/memory/screen/keyboard state, and loads a program --
# either a real compiled Nova-16 `.bin` passed on the command line, or (with
# no argument) nothing at all: the emulator opens to a blank screen and sits
# idle until a binary is loaded via the toolbar's `Load` button (or its F9
# hotkey). See `loader.star` for the binary-loading mechanics
# (`file_read_bytes` + `.org`-sidecar segment loading, todo.md P0 #1/
# NOTES.md gotcha #9) and NOTES.md's "Binary program loading" section for the
# full story.
#
# GUI+controls parity (todo.md P2 #3, extended): a toolbar (Start/Pause,
# Stop, Reset, Step, Load) plus a status bar (PC, run state, hotkey legend),
# matching `nova_gui.py::main`'s own toolbar -- including, now, its `Load`
# button, backed by `open_file_dialog` (`crate::codegen::dialog`), a native
# Windows "Open File" common dialog added specifically so this port no
# longer needs the "no file-dialog builtin in this language" scope cut
# NOTES.md's "GUI+controls parity" section previously recorded. UART
# configuration remains `uart_bridge.star`'s own separate tool, unchanged.
#
# There is deliberately no built-in demo program anymore (an earlier
# revision had one -- a hand-encoded diagonal-gradient fill, loaded whenever
# no CLI argument was given). Removed because it now conflicts with the
# `Load` button's whole point: a no-argument launch should visibly wait for
# a real binary, not silently run something else instead. Concretely, this
# needs no special "idle" state at all: `new_cpu`/`Cpu::reinit` already leave
# `self.mem` entirely zeroed, and `cpu.star::execute`'s opcode `0x00` is
# `HLT` (`self.halted = true`) -- so a never-loaded (or freshly `Reset`)
# `Cpu` simply halts on its very first `step()`, at `PC=0`, against a blank
# screen, for free.
#
# Build (from the repo root, SDL2 must be linked explicitly; `comdlg32` backs
# the `Load` button's file-open dialog, see `crate::codegen::dialog`'s own
# linking note):
#   star build projects/nova/main.star -L sdl/lib/x64 -l SDL2 -l comdlg32 -o projects/nova/nova16.exe
# `sdl/lib/x64/SDL2.dll` must be next to the built .exe (or on PATH) to run.
#
# Usage:
#   nova16.exe                  # open idle; wait for Load (toolbar or F9)
#   nova16.exe path/to/prog.bin # load and run a real assembled program
# Hotkeys (matching `nova_gui.py`'s own F5-F9 exactly): F5 Start/Pause, F6
# Stop, F7 Reset, F8 Step, F9 Load. Escape or closing the window still quits,
# unchanged. `Reset` reloads whichever binary is currently active (the
# CLI-provided one, or the most recent `Load`) if any; with nothing ever
# loaded, `Reset` just re-clears to the same idle, waiting-for-Load state.

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
import "palette.star" as pal
import "loader.star" as loader
import "uart.star" as uart

const SCREEN_SIZE: i32 = 256
const TOOLBAR_H: i32 = 40
const STATUS_H: i32 = 22

const BTN_Y: i32 = 6
const BTN_H: i32 = 28
const BTN_START_X: i32 = 8
const BTN_START_W: i32 = 96
const BTN_STOP_X: i32 = 112
const BTN_STOP_W: i32 = 64
const BTN_RESET_X: i32 = 184
const BTN_RESET_W: i32 = 64
const BTN_STEP_X: i32 = 256
const BTN_STEP_W: i32 = 64
const BTN_LOAD_X: i32 = 328
const BTN_LOAD_W: i32 = 64

# Identical to `debugger.star`/`tests/run_bin.star`/`uart_bridge.star`'s own
# `new_cpu()` -- a fresh, all-zero `Cpu` (SP/FP at 0xFFFF, see the comment on
# the `p` field below). Returning a `Cpu` (over a megabyte of aggregate
# state: `Memory` alone is ~300KB, `Screen`'s 9 compositing layers push it
# well past that) by value from an ordinary function is the same `sret`
# out-pointer shape NOTES.md "Two Star compiler bugs found and fixed" #1
# fixed and `debugger.star::new_cpu` already exercises successfully.
#
# Deliberately called only **once**, at startup -- `Reset` (see the main
# loop below) does NOT call this a second time. An earlier draft of this
# file had `Reset` call an (then-named) `build_cpu` a second and third time
# (once for the F7 hotkey, once for the toolbar button), and that build
# took several minutes and multiple gigabytes of `clang` memory to even
# finish linking -- three call sites in one function, each expanding to this
# same huge inline struct-literal-then-`sret`-copy sequence, is a
# meaningfully different shape from the one proven call site every other
# build target in this project uses, and empirically triggers something
# close to the `clang` optimizer pathology NOTES.md's "Large fixed-array/
# struct construction crashed or hung clang" bug writeup already describes
# for a different (also since-fixed) shape. `Reset` uses `Cpu::reinit`
# instead (see below): a sequence of ordinary loop-driven field/array
# writes into the *existing* `Cpu`, not a second full struct literal --
# cheap at both compile time (no giant literal for the optimizer to chew on
# a second or third time) and run time (a few hundred thousand plain byte
# stores, sub-millisecond).
fn new_cpu() -> cpu::Cpu:
    let mut c = cpu::Cpu(
        mem = mem::new_memory(),
        screen = screen::new_screen(),
        kbd = keyboard::Keyboard(buffer = [0 as u8; 64], head = 0, tail = 0, count = 0, status = 0 as u8, control = 0 as u8),
        flags = flg::Flags(bits = BitField<16>(0)),
        uart = uart::new_uart(),
        r = [Wrapping<u8>(0 as u8); 10],
        # SP (P8)/FP (P9) reset to 0xFFFF (top of the 64KB address space,
        # stack grows downward), matching `core/regfile.py::RegisterFile.
        # __init__`'s explicit `self.P[8] = self.P[9] = 0xFFFF` -- found via
        # `debugger.star`'s `stack` command showing a fresh CPU's SP as
        # 0x0000 instead (garbage-adjacent: a PUSH/CALL before the program
        # sets its own SP would immediately corrupt low memory rather than
        # the reference's real reset value). Every existing checked-in
        # `.asm` test that touches the stack happens to set SP explicitly
        # first (see e.g. `tests/asm/push_pop_width_test.asm`), which is
        # exactly why this went unnoticed until a debugger exposed the raw
        # post-reset state. P0-P7 have no documented reset value and stay 0.
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
    c

# Loads `bin_path` into an already-constructed `Cpu` if `use_file` -- with
# no demo fallback anymore (see this file's own header comment): a failed
# or absent load just leaves `self` exactly as `new_cpu`/`reinit` left it
# (all-zero memory, `pc = 0`), which halts on the very first `step()` since
# opcode `0x00` is `HLT` (`cpu.star::execute`) -- a blank screen, quietly
# waiting for a real binary via the `Load` button, with no special "idle"
# state to construct. Used at startup (right after `new_cpu()`), by `Reset`
# (right after `reinit()`), and by the `Load` button/F9 hotkey (right after
# a fresh `reinit()` of its own, mirroring `nova_gui.py::CPUController.
# reset()` + `load_binary_program()`'s own stop-reset-load sequence).
impl cpu::Cpu:
    fn load_program_or_wait(mut self, bin_path: str, use_file: bool):
        if use_file:
            let (ep, ok) = self.load_program(bin_path)
            if ok:
                self.pc = Wrapping<u16>(ep as u16)
                println(f"nova16: loaded '{bin_path}', entry point {ep}")
            else:
                println(f"nova16: could not open '{bin_path}', waiting for Load")

    # `Reset`'s own state-clearing step -- see `new_cpu`'s doc comment for
    # why this is a sequence of plain field/array writes into `self` rather
    # than a second call to a function that returns a fresh `Cpu` by value.
    # Every field here matches `new_cpu`'s own initial values exactly
    # (SP/FP at 0xFFFF, everything else 0/false), so a `Reset` produces a
    # state indistinguishable from a freshly started emulator, modulo the
    # program still needing to be reloaded afterward (see
    # `load_program_or_wait`, called right after this at both of `Reset`'s
    # call sites in the main loop below).
    fn reinit(mut self):
        let mut i = 0
        while i < 65536:
            self.mem.ram[i] = 0 as u8
            i += 1
        i = 0
        while i < 245760:
            self.mem.bank_ram[i] = 0 as u8
            i += 1
        self.mem.bank = 0 as u8

        i = 0
        while i < 65536:
            self.screen.screen[i] = 0 as u8
            self.screen.bg1[i] = 0 as u8
            self.screen.bg2[i] = 0 as u8
            self.screen.bg3[i] = 0 as u8
            self.screen.bg4[i] = 0 as u8
            self.screen.sp1[i] = 0 as u8
            self.screen.sp2[i] = 0 as u8
            self.screen.sp3[i] = 0 as u8
            self.screen.sp4[i] = 0 as u8
            self.screen.vram[i] = 0 as u8
            i += 1

        i = 0
        while i < 64:
            self.kbd.buffer[i] = 0 as u8
            i += 1
        self.kbd.head = 0
        self.kbd.tail = 0
        self.kbd.count = 0
        self.kbd.status = 0 as u8
        self.kbd.control = 0 as u8

        self.flags.bits = BitField<16>(0)
        self.uart = uart::new_uart()

        i = 0
        while i < 10:
            self.r[i] = Wrapping<u8>(0 as u8)
            i += 1
        i = 0
        while i < 8:
            self.p[i] = Wrapping<u16>(0 as u16)
            i += 1
        self.p[8] = Wrapping<u16>(0xFFFF as u16)
        self.p[9] = Wrapping<u16>(0xFFFF as u16)

        self.pc = Wrapping<u16>(0 as u16)
        self.vx = Wrapping<u8>(0 as u8)
        self.vy = Wrapping<u8>(0 as u8)
        self.vc = Wrapping<u8>(0 as u8)
        self.vm = 0 as u8
        self.vl = 0 as u8
        self.tt = Wrapping<u8>(0 as u8)
        self.tm = Wrapping<u8>(0 as u8)
        self.tc = Wrapping<u8>(0 as u8)
        self.ts = Wrapping<u8>(0 as u8)
        self.timer_subcycle = 0
        self.pending_timer_irq = false
        self.sa = Wrapping<u16>(0 as u16)
        self.sf = Wrapping<u8>(0 as u8)
        self.sv = Wrapping<u8>(0 as u8)
        self.sw = Wrapping<u8>(0 as u8)
        self.next_strig_channel = 8
        self.mx = Wrapping<u8>(0 as u8)
        self.my = Wrapping<u8>(0 as u8)
        self.mb = Wrapping<u8>(0 as u8)
        self.mouse_enabled = false
        self.mouse_pending_irq = false
        self.c0 = Wrapping<u16>(0 as u16)
        self.c1 = Wrapping<u16>(0 as u16)
        self.halted = false
        self.cycles = 0 as i64

fn point_in_rect(px: i32, py: i32, rx: i32, ry: i32, rw: i32, rh: i32) -> bool:
    px >= rx and px < rx + rw and py >= ry and py < ry + rh

# Small local hex formatter for the status bar's `PC:` readout -- not the
# same table as `disasm.star`/`debugger.star`'s own `hex_word` (this always
# prints exactly 4 digits via `>>`/`&`, no leading-zero-stripping concerns,
# and there's no reason for a one-line status readout to duplicate a whole
# disassembly-table-sized file just for this).
fn hex_digit(n: i32) -> str:
    if n < 10:
        chr(48 + n)
    else:
        chr(65 + (n - 10))

fn hex4(v: i32) -> str:
    let w = v & 0xFFFF
    let mut s = ""
    let mut shift = 12
    while shift >= 0:
        s = concat(s, hex_digit((w >> shift) & 0xF))
        shift -= 4
    s

fn main():
    let w = window_create("Nova-16", SCREEN_SIZE * 2, SCREEN_SIZE * 2 + TOOLBAR_H + STATUS_H)
    if is_null(w):
        println("window_create failed")
        return

    # `args()`, like C's argv, includes the program name itself at index 0
    # -- a real path argument (if any) is at index 1. Kept around (not just
    # consumed once at startup) so `Reset` can rebuild the same initial
    # state -- see `build_cpu`.
    let cli = args()
    # `mut` -- unlike the rest of this block, `bin_path`/`use_file` are
    # reassigned later by the `Load` button/F9 hotkey (see below), which is
    # also why `Reset` (F7 hotkey and toolbar button alike) reloads
    # *whichever* binary is current rather than only ever the original CLI
    # argument.
    let mut use_file = cli.len() > 1
    let mut bin_path = if use_file: cli[1] else: ""
    let mut c = new_cpu()
    c.load_program_or_wait(bin_path, use_file)
    let font = default_font()

    let escape_sc = 41
    # A small, arbitrary host-scancode -> Nova-16 key-code map (letters A-Z
    # start at SDL scancode 4). Good enough to prove KEYIN/KEYSTAT/KEYCOUNT/
    # KEYCLEAR/KEYCTRL work end to end; not a full keyboard layout -- see
    # NOTES.md.
    let mut prev_down: [bool; 26] = [false; 26]
    # Edge-triggered (not held-triggered) toolbar/hotkey state -- every one
    # of these needs a "just pressed this frame" transition, not a
    # continuous "is it down right now" level, or holding a key/mouse button
    # down would toggle Start/Pause or re-fire Reset every single frame at
    # 60fps. Same debounce shape `prev_down` above already uses for A-Z.
    let mut prev_f5 = false
    let mut prev_f6 = false
    let mut prev_f7 = false
    let mut prev_f8 = false
    let mut prev_f9 = false
    let mut prev_mouse_left = false
    let mut running = true

    while !window_should_close(w):
        if key_down(escape_sc):
            break

        # F5-F9 hotkeys, matching `nova_gui.py`'s own F5=Start/Pause,
        # F6=Stop, F7=Reset, F8=Step, F9=Load exactly.
        let f5_down = key_down(62)
        if f5_down and !prev_f5:
            running = !running
        prev_f5 = f5_down

        let f6_down = key_down(63)
        if f6_down and !prev_f6:
            running = false
        prev_f6 = f6_down

        let f7_down = key_down(64)
        if f7_down and !prev_f7:
            c.reinit()
            c.load_program_or_wait(bin_path, use_file)
            running = true
        prev_f7 = f7_down

        let f8_down = key_down(65)
        let mut single_step = false
        if f8_down and !prev_f8:
            single_step = true
        prev_f8 = f8_down

        # F9 = Load: a native "Open File" dialog (`open_file_dialog`,
        # `crate::codegen::dialog`), restricted to `.bin`. Mirrors
        # `nova_gui.py::load_binary_program`'s own stop-reset-load-start
        # sequence: `open_file_dialog` itself blocks this thread until the
        # dialog closes, so there's no separate "stop" step needed first --
        # the emulator is already not stepping while this call is in
        # progress. An empty result (the user canceled) leaves `c` and
        # `running` completely untouched.
        let f9_down = key_down(66)
        if f9_down and !prev_f9:
            let picked = open_file_dialog("*.bin")
            if picked != "":
                bin_path = picked
                use_file = true
                c.reinit()
                c.load_program_or_wait(bin_path, use_file)
                running = true
        prev_f9 = f9_down

        let mut k = 0
        while k < 26:
            let sc = 4 + k
            let down = key_down(sc)
            if down and !prev_down[k]:
                c.kbd.push_key((65 + k) as u8)
            prev_down[k] = down
            k += 1

        # Mouse plumbing (MOUSECTRL/MX/MY/MB -- see cpu.star's op_mousectrl
        # comment): only overwrites MX/MY/MB, and only raises the mouse
        # interrupt (vector 3) on a real change, while `MOUSECTRL` has
        # enabled it -- mirrors `NovaMouse.move_to`/`set_buttons`'s own
        # `if from_host and not self.enabled: return` guard. Window pixels
        # are 2x the emulated 256x256 grid (see `SCREEN_SIZE * 2` above), so
        # host coordinates are halved before clamping into Nova-16's range;
        # the Y coordinate is also offset by `TOOLBAR_H` now that the
        # emulator screen no longer starts at the window's own top edge,
        # matching `nova_gui.py::map_window_to_emulator`'s identical
        # toolbar-height subtraction.
        if c.mouse_enabled:
            let mut new_mx = mouse_x() / 2
            if new_mx < 0:
                new_mx = 0
            elif new_mx > 255:
                new_mx = 255
            let mut new_my = (mouse_y() - TOOLBAR_H) / 2
            if new_my < 0:
                new_my = 0
            elif new_my > 255:
                new_my = 255
            let mut new_mb = 0 as u8
            if mouse_button_down(1):
                new_mb = new_mb | (1 as u8)
            if mouse_button_down(3):
                new_mb = new_mb | (2 as u8)
            if (new_mx as u8) != (c.mx as u8) or (new_my as u8) != (c.my as u8) or new_mb != (c.mb as u8):
                c.mouse_pending_irq = true
            c.mx = Wrapping<u8>(new_mx as u8)
            c.my = Wrapping<u8>(new_my as u8)
            c.mb = Wrapping<u8>(new_mb)

        # Toolbar button clicks -- edge-triggered on the left mouse button
        # the same way the F5-F8 hotkeys are above.
        let mleft_down = mouse_button_down(1)
        let mouse_clicked = mleft_down and !prev_mouse_left
        prev_mouse_left = mleft_down
        if mouse_clicked:
            let mpx = mouse_x()
            let mpy = mouse_y()
            if point_in_rect(mpx, mpy, BTN_START_X, BTN_Y, BTN_START_W, BTN_H):
                running = !running
            elif point_in_rect(mpx, mpy, BTN_STOP_X, BTN_Y, BTN_STOP_W, BTN_H):
                running = false
            elif point_in_rect(mpx, mpy, BTN_RESET_X, BTN_Y, BTN_RESET_W, BTN_H):
                c.reinit()
                c.load_program_or_wait(bin_path, use_file)
                running = true
            elif point_in_rect(mpx, mpy, BTN_STEP_X, BTN_Y, BTN_STEP_W, BTN_H):
                single_step = true
            elif point_in_rect(mpx, mpy, BTN_LOAD_X, BTN_Y, BTN_LOAD_W, BTN_H):
                # Same load sequence as the F9 hotkey above -- see that
                # block's own comment for why no separate "stop" step is
                # needed first.
                let picked = open_file_dialog("*.bin")
                if picked != "":
                    bin_path = picked
                    use_file = true
                    c.reinit()
                    c.load_program_or_wait(bin_path, use_file)
                    running = true

        if running:
            let mut n = 0
            while !c.halted and n < 20000:
                c.step()
                n += 1
        elif single_step and !c.halted:
            c.step()

        clear_screen(w, Color32(20, 20, 20, 255))
        let mut y = 0
        while y < SCREEN_SIZE:
            let mut x = 0
            while x < SCREEN_SIZE:
                let idx = c.screen.composite_pixel(x, y)
                if idx != (0 as u8):
                    let rgb = pal::palette_color(idx)
                    draw_rect(w, x * 2, y * 2 + TOOLBAR_H, 2, 2, Color32(rgb.0 as i32, rgb.1 as i32, rgb.2 as i32, 255))
                x += 1
            y += 1

        # Toolbar.
        draw_rect(w, 0, 0, SCREEN_SIZE * 2, TOOLBAR_H, Color32(40, 40, 40, 255))
        let start_label = if running: "PAUSE" else: "START"
        let start_color = if running: Color32(200, 200, 0, 255) else: Color32(0, 160, 0, 255)
        draw_rect(w, BTN_START_X, BTN_Y, BTN_START_W, BTN_H, start_color)
        draw_text(w, font, start_label, BTN_START_X + 10, BTN_Y + 8, 2, Color32(255, 255, 255, 255))
        draw_rect(w, BTN_STOP_X, BTN_Y, BTN_STOP_W, BTN_H, Color32(160, 0, 0, 255))
        draw_text(w, font, "STOP", BTN_STOP_X + 6, BTN_Y + 8, 2, Color32(255, 255, 255, 255))
        draw_rect(w, BTN_RESET_X, BTN_Y, BTN_RESET_W, BTN_H, Color32(0, 0, 160, 255))
        draw_text(w, font, "RESET", BTN_RESET_X + 2, BTN_Y + 8, 2, Color32(255, 255, 255, 255))
        draw_rect(w, BTN_STEP_X, BTN_Y, BTN_STEP_W, BTN_H, Color32(160, 160, 0, 255))
        draw_text(w, font, "STEP", BTN_STEP_X + 6, BTN_Y + 8, 2, Color32(255, 255, 255, 255))
        draw_rect(w, BTN_LOAD_X, BTN_Y, BTN_LOAD_W, BTN_H, Color32(0, 140, 140, 255))
        draw_text(w, font, "LOAD", BTN_LOAD_X + 6, BTN_Y + 8, 2, Color32(255, 255, 255, 255))

        # Status bar.
        let status_y = SCREEN_SIZE * 2 + TOOLBAR_H
        draw_rect(w, 0, status_y, SCREEN_SIZE * 2, STATUS_H, Color32(25, 25, 25, 255))
        let state_text = if c.halted: "HALTED" elif running: "RUNNING" else: "STOPPED"
        let status: List<str> = ["PC:0x", hex4((c.pc as u16) as i32), "  ", state_text, "  F5=Start/Pause F6=Stop F7=Reset F8=Step F9=Load  Esc=Quit"]
        draw_text(w, font, str_join(status, ""), 6, status_y + 4, 1, Color32(200, 200, 200, 255))

        present(w)
        delay(16)
