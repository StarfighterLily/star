; Regression test for the new Star `assembler.star` (todo.md P1 #2):
; exercises `[0xADDR + off]` / `[0xADDR - off]` direct-indexed addressing --
; a real Nova-16 CPU addressing mode (`cpu.star::decode_operand`,
; `disasm.star::format_operand`, and `docs/Operand prefix system.md` all
; agree on it) that the upstream Python `nova_assembler.py` cannot assemble
; at all: confirmed empirically, `MOV [0x3000+4], 0xAB` raises "Unknown base
; register: 0x3000" in the live Python assembler, since its own `direct`/
; `indexed` regexes don't compose (see `assembler.star`'s own header comment,
; "Deliberate deviations from the Python assembler"). Verified instead via
; this project's own disasm.star round trip and by running the assembled
; `.bin` on the live Nova-16 MCP debugger and checking the resulting
; register state directly (see NOTES.md's "Assembler" section).
;
; Both writes below target the same address (0x3004) from opposite signs,
; then a plain (non-indexed) direct read confirms the byte actually landed
; there rather than the encoding silently degrading to something else.
;
; R0 = 0xAB (mem[0x3004], written via [0x3000 + 4])
; R1 = 0xCD (mem[0x3004], written via [0x3010 - 12], overwriting R0's byte --
;      proves both encodings address the identical byte)
ORG 0x0000

START:
    MOV [0x3000 + 4], 0xAB
    MOV R0, [0x3004]
    MOV [0x3010 - 12], 0xCD
    MOV R1, [0x3004]
    HLT
