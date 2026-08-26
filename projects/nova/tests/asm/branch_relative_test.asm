; Branch-relative encoding + execution test (parity round, Aug 2026).
;
; `assembler.star` now encodes BR/BRZ/BRNZ *symbol* operands as signed 16-bit
; PC-relative deltas -- target minus (instruction address + 4) -- matching the
; fixed `nova_assembler.py::_parse_immediate_value`, which finished its
; previously-dead relative-offset branch (`ebbbcaa`/`955452b`). Verified two
; ways:
;   1. Byte-for-byte: this file assembled by both assemblers produces
;      identical `.bin` bytes (checked in here is the Star-produced pair;
;      re-run `python nova_assembler.py <this-file>` on a copy elsewhere
;      to re-diff).
;   2. Execution: loaded by `tests/run_bin.exe`, R9 must stay 0 (forward BR
;      over the marker), R0 must end at 2 (backward loop exits via BRZ), and
;      final pc must equal the HLT at `done`.
;
; Hand-computed layout (from address 0x0000):
;   0x0000 entry:  BR fwd        (4B) -> delta = fwd(0x0008) - (0+4) = 4
;   0x0004 marker: MOV R9,0xAA   (4B) -- skipped at runtime
;   0x0008 fwd:    MOV R0,0      (4B)
;   0x000C loop_top: INC R0      (3B)
;   0x000F CMP R0,2              (4B)
;   0x0013 BRZ done              (4B) -> taken when R0==2: done(0x001B)-(0x13+4)=4
;   0x0017 BR loop_top           (4B) -> backward: 0x000C-(0x17+4) = -15 = 0xFFF1
;   0x001B done:  HLT
;   0x001C post:  BR QUIT_ADDR   (4B) -> EQU target: 0x0100-(0x1C+4) = 0xE0
;   0x0020       BR 0x0040       (3B) -> literal stays RAW 0x0040 (no delta)
; The two post-HLT encodings (EQU-symbol and literal) are dead code, never
; executed, kept purely to pin the symbols-only delta asymmetry.
;
; Expected run_bin.exe output: halted=true, R0=2, R9=0, everything else 0
; except program flow registers (VX/VY/VC/flags unset).
ORG 0x0000
ENTRY:
    BR FWD                  ; forward skip over marker
MARKER:
    MOV R9, 0xAA            ; marker -- must NOT execute
FWD:
    MOV R0, 0               ; loop counter
LOOP_TOP:
    INC R0
    CMP R0, 2
    BRZ DONE                ; conditional exit when R0 == 2
    BR LOOP_TOP             ; backward edge of the loop
DONE:
    HLT

QUIT_ADDR EQU 0x0100

POST:
    BR QUIT_ADDR            ; dead code past HLT -- EQU symbols get deltas too
    BR 0x0040               ; dead code -- literal operands stay RAW (no delta),
                            ; exactly matching the fixed Python assembler