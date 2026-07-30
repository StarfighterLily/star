# Nova-16 CPU: keyboard, serial/UART, and mouse-control opcode handlers
# (KEYIN/KEYSTAT/KEYCOUNT/KEYCLEAR/KEYCTRL, SERIN/SEROUT/SERSTAT/SERCTRL,
# MOUSECTRL -- docs/nova16_instruction_reference.md, docs/UART_SYSTEM.md)
# -- split out of `cpu.star` (todo.md P2 #5). See `cpu_data.star`'s header
# comment for the full rationale (pure code motion, no behavior change) and
# why this `import "cpu.star" as cpu` isn't circular. Grouped together as
# "peripheral I/O register" opcodes -- none of the three families needs
# `cpu.star`'s own free functions/consts or any other module's qualified
# free functions, only method calls through `self.kbd`/`self.uart`/plain
# `self` fields, so this file needs no import beyond `cpu.star` itself.
import "cpu.star" as cpu

impl cpu::Cpu:
    # ── Keyboard ─────────────────────────────────────────────────────────

    fn op_keyin(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let (v, had) = self.kbd.pop_key()
        self.flags.set_z(!had)
        self.operand_write(op1, 8, v as i32)

    fn op_keystat(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        self.operand_write(op1, 8, (self.kbd.keystat()) as i32)

    fn op_keycount(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        self.operand_write(op1, 8, (self.kbd.keycount()) as i32)

    fn op_keyclear(mut self):
        self.kbd.keyclear()

    fn op_keyctrl(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let v = self.operand_read(op1, 8)
        self.kbd.keyctrl(v as u8)

    # ── Serial / UART (docs/UART_SYSTEM.md; uart.star) ──────────────────

    fn op_serin(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let v = self.uart.read_data()
        self.operand_write(op1, 8, v as i32)

    # SEROUT: the real TX half of the host bridge (todo.md P0 #1) -- every
    # transmitted byte is printed to the process's own stdout immediately,
    # in addition to updating the register model `uart.star::write_data`
    # tracks. This *is* "transmission": whatever's attached to this
    # process's stdout (a real console, a pipe, `uart_bridge.star`'s own
    # prompt loop) is the host on the other end of the wire. `print(chr(..))`
    # rather than an f-string interpolation of `as char` -- `emit_print_like`
    # (`builtins.rs`) unconditionally appends a trailing `\n` to *any*
    # f-string argument regardless of `print` vs `println`, which would
    # inject a spurious newline after every single transmitted byte; `chr`'s
    # plain-`str` result instead takes `print`'s other path (the argument
    # handed straight to `printf` with no newline appended). Known gap
    # inherited from `chr`/`str` themselves, not new here: a transmitted
    # `0x00` byte prints as nothing (a `str` can't hold an embedded NUL --
    # same limitation `file_read`'s own doc comment already flags), and a
    # transmitted `%` is handed to `printf` as its own format string with no
    # following conversion, same latent UB every other bare `print(some_str)`
    # call in this codebase already carries.
    fn op_serout(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let v = self.operand_read(op1, 8)
        let b = v as u8
        self.uart.write_data(b)
        print(chr(b as i32))

    fn op_serstat(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        self.operand_write(op1, 8, (self.uart.read_status_flags()) as i32)

    fn op_serctrl(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let v = self.operand_read(op1, 8)
        self.uart.write_control(v as u8)

    # MOUSECTRL: enable/disable host mouse input+interrupts. Stubbed -- this
    # port doesn't generate mouse events/interrupts yet (MX/MY/MB are still
    # plain readable/writable registers via MOV, just never updated by a
    # real host mouse) -- see NOTES.md. Consumes its operand and no-ops.
    # MOUSECTRL: bit 0 enables host mouse input + interrupts (matches
    # `NovaMouse.write_control`/`_mousectrl`'s `interrupts[3] = control &
    # 0x01`). `MX`/`MY`/`MB` stay plain readable/writable registers
    # regardless -- enabling only gates whether `main.star`'s per-frame loop
    # is allowed to overwrite them from the real host mouse (mirroring
    # `NovaMouse.move_to`/`set_buttons`'s own `if from_host and not self.
    # enabled: return` guard) and whether a position/button change raises
    # the mouse interrupt (vector 3).
    fn op_mousectrl(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let v = self.operand_read(op1, 8)
        self.mouse_enabled = bit_get(v as u8, 0)

