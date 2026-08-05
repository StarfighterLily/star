# Nova-16 CPU: math-library and fixed-point-conversion opcode handlers
# (POWR/SQRT/LOG/EXP/SIN/COS/TAN/ATAN/ASIN/ACOS/DEG/RAD/FLOOR/CEIL/ROUND/
# TRUNC/FRAC plus FMUL/FDIV/FTOI/ITOF, docs/nova16_instruction_reference.md
# 0x5B-0x6C / 0xAC-0xAF) -- split out of `cpu.star` (todo.md P2 #5). See
# `cpu_data.star`'s header comment for the full rationale (pure code motion,
# no behavior change) and why this `import "cpu.star" as cpu` isn't
# circular. `cpu::PI`/`cpu::MATH_OVERFLOW_GUARD`/`cpu::floor_div16` are
# `cpu.star`'s own module-level `const`s/free function -- unlike a method
# call through `self`, a bare top-level name from another file *does* need
# its `alias::` qualification (only `impl` blocks skip name-mangling
# entirely; free functions and consts don't), so every reference here is
# qualified accordingly, unchanged from what `cpu.star` itself would have
# written for a same-file call.
import "cpu.star" as cpu

impl cpu::Cpu:
    # ── Math library (docs/nova16_instruction_reference.md 0x5B-0x6C) ──
    # Ported from core/exec_handlers.py's _powr/_sqrt/_log/.../_intgr. Every
    # one of these treats its operand as a 16-bit *signed* value via
    # `to_signed(a, 16)` regardless of the destination's resolved width --
    # matching the reference's own hardcoded `_to_signed_16`, unlike this
    # port's usual "infer width from the destination register's real kind"
    # rule (see "Operand width is inferred..." in NOTES.md). Deliberate, not
    # an oversight: Q8.8 fixed-point is inherently a 16-bit format, real
    # Nova-16 programs always target a P register (or memory) with these,
    # and the one case where the distinction could matter -- targeting an
    # 8-bit R/VX/SF/... register -- already reads only 8 bits before the
    # signed reinterpretation ever runs, so `to_signed(a, 16)` is a no-op
    # there in both this port and the reference alike (an 8-bit read is
    # always < 0x8000). Flags are likewise always computed at width=16,
    # matching `_set_arith_flags(..., 16, ...)` in every handler below --
    # `apply_arith`'s `op1`/`op2` arguments are each handler's *raw* operand
    # read(s), not the signed-reinterpreted value used for the math itself,
    # again matching the reference exactly.
    #
    # SIN/COS/TAN/ATAN/ASIN/ACOS/LOG/EXP/SQRT/POWR route through Star's
    # builtin math functions, which compute in `f32` (single) precision --
    # the Python reference uses `f64` throughout. Deliberately accepted for
    # the fixed-point-scaled ones (SIN/COS/etc.): Q8.8 only needs 8 bits of
    # fractional precision, far inside `f32`'s ~23-bit mantissa, so it can
    # only matter at the very edge of an exact-tie rounding boundary.
    # POWR/EXP's overflow thresholds are a bigger, more visible consequence
    # of the same gap -- see their own comments below.

    fn op_powr(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let p = pow(a, b)
        # `_powr` catches Python's OverflowError and substitutes 0; `f32`
        # overflows to +inf at a far lower magnitude than `f64` (~3.4e38 vs
        # ~1.8e308), so this falls back to 0 across a visibly wider range of
        # (base, exponent) pairs than the reference does. Also inherent:
        # `f32` only represents integers exactly up to 2**24 (~16.8M), so a
        # POWR result between that and the ~9e15 cutoff below is a rounded
        # approximation of the reference's exact (arbitrary-precision,
        # then-truncated-to-16-bits) result, not a bit-exact match -- there
        # is no way to reproduce Python's exact low-16-bits-of-a-bignum
        # behavior through float math; flagged rather than silently wrong.
        let mut result: i32 = 0
        if p == p and p < 9_000_000_000_000_000.0 and p > (0.0 - 9_000_000_000_000_000.0):
            result = (p as i64) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, a, b, 16, false, false)
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(result, ww))

    fn op_sqrt(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let mut result = 0
        if v >= 0:
            result = sqrt(v) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    fn op_log(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let mut result = 0
        if v > 0:
            result = (log((v as f32) / 256.0) * 256.0) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    fn op_exp(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let p = exp((v as f32) / 256.0)
        # `_exp` substitutes 0xFFFF (not 0) on overflow. `f32` overflows
        # around exp(88.7) where `f64` doesn't overflow until exp(709.8) --
        # a real, reachable gap here (v/256 can be up to ~128), unlike
        # SIN/COS/TAN/ATAN's inputs, whose result magnitude is bounded
        # regardless of precision.
        let mut result = 0xFFFF
        if p == p and p < cpu::MATH_OVERFLOW_GUARD and p > (0.0 - cpu::MATH_OVERFLOW_GUARD):
            result = self.mask_to_width((p * 256.0) as i32, 16)
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    fn op_sin(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let result = (sin((v as f32) / 256.0) * 256.0) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    fn op_cos(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let result = (cos((v as f32) / 256.0) * 256.0) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    # TAN (0x61) is a genuine reference quirk, not a transcription slip: the
    # Python handler uses `v` directly as radians (not `v / 256.0` like
    # every other trig op here) and scales its result by 1000 (not 256).
    # Ported bug-for-bug -- `core/exec_handlers.py::_tan`'s own docstring
    # ("tangent (scaled by 1000)") confirms it's intentional upstream, odd
    # as it looks next to its neighbors.
    fn op_tan(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let t = tan(v as f32)
        let mut result = 0
        if t == t and t < cpu::MATH_OVERFLOW_GUARD and t > (0.0 - cpu::MATH_OVERFLOW_GUARD):
            result = self.mask_to_width((t * 1000.0) as i32, 16)
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    fn op_atan(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let result = (atan((v as f32) / 256.0) * 256.0) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    fn op_asin(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let mut result = 0
        if v >= (0 - 256) and v <= 256:
            result = (asin((v as f32) / 256.0) * 256.0) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    fn op_acos(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let mut result = 0
        if v >= (0 - 256) and v <= 256:
            result = (acos((v as f32) / 256.0) * 256.0) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    # DEG (0x65): despite the name, converts a plain-integer *degree* value
    # to Q8.8 *radians* (docs: "Converts deg to rad") -- `v` itself is the
    # degree count, not `v / 256.0`.
    fn op_deg(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let result = (((v as f32) * cpu::PI / 180.0) * 256.0) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    # RAD (0x66): the inverse -- Q8.8 radians in, plain-integer degrees out.
    fn op_rad(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let result = (((v as f32) / 256.0) * 180.0 / cpu::PI) as i32
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    fn op_floor(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let result = cpu::floor_div16(v, 256)
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    fn op_ceil(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let q = cpu::floor_div16(v, 256)
        let r = v - q * 256
        let mut result = q
        if r != 0:
            result = q + 1
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    # Round-half-to-even (matches Python's `round()`), computed with pure
    # integer arithmetic rather than through float math at all: `v / 256.0`
    # is always *exact* in a double or float (256 is a power of 2 and `v`
    # is only ever 16 bits), so the "exactly .5" tie case is a genuine tie,
    # not a float-precision artifact, and happens exactly when the
    # floor-remainder (`v` mod 256, always in [0, 256)) is exactly 128.
    fn op_round(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let q = cpu::floor_div16(v, 256)
        let frac = v - q * 256
        let mut result = q
        if frac > 128:
            result = q + 1
        elif frac == 128:
            if q % 2 != 0:
                result = q + 1
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    # TRUNC (0x6A) and INTGR (0x6C) are the same operation in the
    # reference (`_intgr`'s own docstring: "alias of TRUNC") -- both opcodes
    # dispatch here directly (see `execute` below) rather than duplicating
    # this method under two names.
    fn op_trunc(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let result = v / 256
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    # FRAC: fractional part with the *same sign as the input* (unlike
    # FLOOR's remainder) -- `v == TRUNC(v) * 256 + FRAC(v)`. This is Star's
    # `%` directly (truncating remainder, sign follows the dividend), not
    # `floor_div16`'s remainder.
    fn op_frac(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let v = self.to_signed(a, 16)
        let result = v % 256
        let masked = self.mask_to_width(result, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(result, width))

    # ── Fixed-point Q8.8 conversion (0xAC-0xAF) ─────────────────────────
    # Same "always 16-bit signed regardless of resolved width" rule as the
    # math library above -- ported from core/exec_handlers.py's
    # _fmul/_fdiv/_ftoi/_itof.

    fn op_fmul(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        let da = self.to_signed(a, 16)
        let db = self.to_signed(b, 16)
        # Widest possible |da * db| is 32768*32768 (~1.07e9), comfortably
        # inside i32 -- no overflow-trap risk from the plain `*` below.
        # `>>` arithmetic-shifts (sign-extending), matching Python's `>>`
        # floor-toward-negative-infinity semantics on a negative product.
        let raw = (da * db) >> 8
        let masked = self.mask_to_width(raw, 16)
        self.flags.apply_arith(masked, a, b, 16, false, false)
        let ww = self.write_width_for(op1, op2)
        self.operand_write(op1, ww, self.mask_to_width(raw, ww))

    fn op_fdiv(mut self):
        let (op1, op2, _op3) = self.decode_operands(2)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let b = self.operand_read(op2, width)
        # Python's FDIV raises on division by zero (a hard error); this port
        # instead prints a diagnostic and skips the write, matching the
        # existing DIV/MOD/DIVH precedent above (see NOTES.md "Known
        # simplifications").
        if b == 0:
            println("[nova16] FDIV by zero -- ignored")
        else:
            let da = self.to_signed(a, 16)
            let db = self.to_signed(b, 16)
            let raw = cpu::floor_div16(da << 8, db)
            let masked = self.mask_to_width(raw, 16)
            self.flags.apply_arith(masked, a, b, 16, false, false)
            let ww = self.write_width_for(op1, op2)
            self.operand_write(op1, ww, self.mask_to_width(raw, ww))

    fn op_ftoi(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let signed = self.to_signed(a, 16)
        let raw = signed >> 8
        let masked = self.mask_to_width(raw, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

    fn op_itof(mut self):
        let (op1, _op2, _op3) = self.decode_operands(1)
        let width = self.operand_width(op1)
        let a = self.operand_read(op1, width)
        let signed = self.to_signed(a, 16)
        let raw = signed << 8
        let masked = self.mask_to_width(raw, 16)
        self.flags.apply_arith(masked, 0, a, 16, false, false)
        self.operand_write(op1, width, self.mask_to_width(raw, width))

