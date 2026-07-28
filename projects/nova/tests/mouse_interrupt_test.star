# Headless regression test for MOUSECTRL's interrupt gating (cpu.star's
# `op_mousectrl`/`check_interrupts`) -- see NOTES.md "Mouse plumbing". There
# is no host bridge to drive real mouse events through a `.bin` (nothing
# reachable from a running Nova-16 program can set `mouse_pending_irq` --
# only `main.star`'s per-frame loop does, from the real host mouse), so
# this is a direct-field-poke harness in the same spirit as the BCD/string
# rounds' "standalone headless harness" (NOTES.md), checked in this time
# per this round's convention. It exercises `Cpu::check_interrupts`
# directly (not `step()`/a hand-encoded handler) since the thing being
# tested is purely the interrupt-dispatch gating logic, not opcode fetch.
#
# Usage: mouse_interrupt_test.exe -- prints PASS/FAIL lines, no arguments.

import "../cpu.star" as cpu
import "../memory.star" as mem
import "../screen.star" as screen
import "../keyboard.star" as keyboard
import "../flags.star" as flg
import "../uart.star" as uart

fn new_cpu() -> cpu::Cpu:
    cpu::Cpu(
        mem = mem::new_memory(),
        screen = screen::new_screen(),
        kbd = keyboard::Keyboard(buffer = [0 as u8; 64], head = 0, tail = 0, count = 0, status = 0 as u8, control = 0 as u8),
        flags = flg::Flags(bits = BitField<16>(0)),
        uart = uart::new_uart(),
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
        mouse_enabled = false,
        mouse_pending_irq = false,
        c0 = Wrapping<u16>(0 as u16),
        c1 = Wrapping<u16>(0 as u16),
        halted = false,
        cycles = 0 as i64,
    )

fn check(name: str, got: bool, expected: bool):
    if got == expected:
        println(f"PASS {name}")
    else:
        println(f"FAIL {name}: got {got}, expected {expected}")

fn main():
    let mut c = new_cpu()

    # IVT vector 3 (0x0100 + 3*4 = 0x010C) -> handler at 0x2000.
    c.mem.write_byte(0x010C, 0x20 as u8)
    c.mem.write_byte(0x010D, 0x00 as u8)

    c.flags.set_i(true)
    c.pc = Wrapping<u16>(0x1234 as u16)

    # Disabled: a pending flag alone must not fire the interrupt, and must
    # not be consumed either (mirrors `NovaMouse`'s own gate on
    # `interrupts[3]`/`self.enabled`, checked again at dispatch time, not
    # just when the flag was first set).
    c.mouse_enabled = false
    c.mouse_pending_irq = true
    c.check_interrupts()
    check("disabled mouse IRQ leaves PC alone", (c.pc as u16) == (0x1234 as u16), true)
    check("disabled mouse IRQ leaves pending flag set", c.mouse_pending_irq, true)

    # Enabled: now it must fire, jump to the vector-3 handler, and clear
    # the pending flag (matches `_check_pending_interrupts`'s own
    # `uart.clear_interrupt()`-style consume-on-dispatch for the mouse
    # source).
    c.mouse_enabled = true
    c.check_interrupts()
    check("enabled mouse IRQ jumps to vector 3 handler", (c.pc as u16) == (0x2000 as u16), true)
    check("enabled mouse IRQ clears pending flag", c.mouse_pending_irq, false)

    # I disabled (flag clear, per Interrupt flag semantics): must not
    # refire even though nothing else has touched mouse_enabled/pending.
    c.pc = Wrapping<u16>(0x1234 as u16)
    c.mouse_pending_irq = true
    c.flags.set_i(false)
    c.check_interrupts()
    check("I-flag-disabled mouse IRQ leaves PC alone", (c.pc as u16) == (0x1234 as u16), true)
