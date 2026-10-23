# Exact float -> decimal formatting for sprintf()'s %f/%e/%g and
# save_variable() -- todo.md HavokOS M4 (efuns).
#
# Why exact: the reference's sprintf() is Pike's, built with MSVC on this
# machine, which prints a double's *exact* decimal expansion and rounds a
# tie half away from zero (`sprintf("%.0f", 2.5)` is "3", `"%.2f"` of 0.125
# is "0.13"; glibc would round half to even). Star's own float formatting
# (`f"{x}"`, the C runtime's "%f") is fixed at 6 decimals, so getting any
# other precision from it would mean rounding an already-rounded string,
# which goes wrong exactly on near-ties (0.12499999999 -> "0.125000" ->
# "0.13"). A double is m * 2^e with integer m, so its expansion is finite;
# `exact_digits` computes it with a small base-10^9 bignum (m * 5^k for a
# negative exponent), and every format is then plain digit-string rounding.
# Scaling by powers of two is exact in binary floating point, which is how m
# and e are found without access to the double's bit pattern.
#
# Values the reference prints differently anyway: its Pike is a 32-bit-float
# build (NOTES.md deviation #3), so `"%.10f"` of 0.1 there is
# "0.1000000015"; here it is "0.1000000000".

struct Dec:
    # significant digits, ASCII, no leading zeros; empty for zero
    mut d: Bytes
    # the value is 0.d * 10^point
    mut point: i32

fn big_mul(a: List<i64>, f: i64) -> List<i64>:
    let base = 1000000000 as i64
    let mut out: List<i64> = List<i64>()
    let mut carry = 0 as i64
    for i in 0..a.len():
        let v = a[i] * f + carry
        out.push(v % base)
        carry = v / base
    while carry > (0 as i64):
        out.push(carry % base)
        carry = carry / base
    out

fn big_digits(a: List<i64>) -> Bytes:
    let mut o: Bytes = Bytes()
    let mut i = a.len() - 1
    let mut first = true
    while i >= 0:
        let s = bytes_from_str(f"{a[i]}")
        if !first:
            for j in s.len()..9:
                o.push(48 as u8)
        for j in 0..s.len():
            o.push(s[j])
        first = false
        i -= 1
    o

# The exact decimal expansion of x (x >= 0, finite).
fn exact_digits(x: f64) -> Dec:
    let zero = 0.0 as f64
    if x == zero:
        return Dec(d = Bytes(), point = 1)
    let two = 2.0 as f64
    let lo = 4503599627370496.0 as f64      # 2^52
    let hi = 9007199254740992.0 as f64      # 2^53
    let mut y = x
    let mut k = 0
    while y >= hi:
        y = y / two
        k -= 1
    while y < lo:
        y = y * two
        k += 1
    let m = y as i64
    let base = 1000000000 as i64
    let mut big: List<i64> = List<i64>()
    big.push(m % base)
    big.push((m / base) % base)
    big.push(m / (base * base))
    if k <= 0:
        let mut n = 0 - k
        while n >= 30:
            big = big_mul(big, 1073741824 as i64)
            n -= 30
        while n > 0:
            big = big_mul(big, 2 as i64)
            n -= 1
    else:
        let mut n = k
        while n >= 12:
            big = big_mul(big, 244140625 as i64)
            n -= 12
        while n > 0:
            big = big_mul(big, 5 as i64)
            n -= 1
    while big.len() > 1 and big[big.len() - 1] == (0 as i64):
        big.pop()
    let digits = big_digits(big)
    let mut point = digits.len()
    if k > 0:
        point = digits.len() - k
    # trailing zeros carry no information
    let mut end = digits.len()
    while end > 0 and (digits[end - 1] as i32) == 48:
        end -= 1
    let mut d: Bytes = Bytes()
    for i in 0..end:
        d.push(digits[i])
    Dec(d = d, point = point)

# Round to `keep` significant digits (keep may be <= 0), half away from zero.
fn round_sig(v: Dec, keep: i32) -> Dec:
    if keep >= v.d.len():
        return v
    if keep < 0:
        return Dec(d = Bytes(), point = v.point)
    let up = (v.d[keep] as i32) >= 53
    let mut d: Bytes = Bytes()
    for i in 0..keep:
        d.push(v.d[i])
    let mut point = v.point
    if up:
        let mut i = keep - 1
        let mut carry = true
        while i >= 0 and carry:
            let c = d[i] as i32
            if c == 57:
                d[i] = 48 as u8
                i -= 1
            else:
                d[i] = (c + 1) as u8
                carry = false
        if carry:
            let mut nd: Bytes = Bytes()
            nd.push(49 as u8)
            for j in 0..d.len():
                nd.push(d[j])
            d = nd
            point += 1
    let mut end = d.len()
    while end > 0 and (d[end - 1] as i32) == 48:
        end -= 1
    let mut t: Bytes = Bytes()
    for i in 0..end:
        t.push(d[i])
    Dec(d = t, point = point)

fn digit_at(v: Dec, i: i32) -> u8:
    if i >= 0 and i < v.d.len():
        return v.d[i]
    48 as u8

# x (>= 0) with `prec` digits after the point ("%.<prec>f" without a sign).
fn fixed_abs(x: f64, prec: i32) -> Bytes:
    let mut v = exact_digits(x)
    v = round_sig(v, v.point + prec)
    let mut o: Bytes = Bytes()
    if v.point <= 0 or v.d.len() == 0:
        o.push(48 as u8)
    else:
        for i in 0..v.point:
            o.push(digit_at(v, i))
    if prec > 0:
        o.push(46 as u8)
        for i in 0..prec:
            o.push(digit_at(v, v.point + i))
    o

fn push_exp(mut o: Bytes, e: i32, upper: bool) -> Bytes:
    o.push(if upper: 69 as u8 else: 101 as u8)
    let mut ee = e
    if ee < 0:
        o.push(45 as u8)
        ee = 0 - ee
    else:
        o.push(43 as u8)
    # MSVC's printf always writes at least three exponent digits
    let es = bytes_from_str(f"{ee}")
    for i in es.len()..3:
        o.push(48 as u8)
    for i in 0..es.len():
        o.push(es[i])
    o

# "%.<prec>e" of x >= 0
fn exp_abs(x: f64, prec: i32, upper: bool) -> Bytes:
    let mut v = exact_digits(x)
    v = round_sig(v, prec + 1)
    let mut o: Bytes = Bytes()
    let e = if v.d.len() == 0: 0 else: v.point - 1
    o.push(digit_at(v, 0))
    if prec > 0:
        o.push(46 as u8)
        for i in 1..prec + 1:
            o.push(digit_at(v, i))
    push_exp(o, e, upper)

# "%.<prec>g" of x >= 0 (C's rule: %e when the exponent is < -4 or >= the
# precision, else %f; trailing zeros dropped unless `alt`)
fn gen_abs(x: f64, prec_in: i32, upper: bool, alt: bool) -> Bytes:
    let p = if prec_in == 0: 1 else: prec_in
    let mut v = exact_digits(x)
    v = round_sig(v, p)
    let e = if v.d.len() == 0: 0 else: v.point - 1
    let mut o: Bytes = Bytes()
    if e < -4 or e >= p:
        o = exp_abs(x, p - 1, upper)
    else:
        o = fixed_abs(x, p - 1 - e)
    if alt:
        return o
    # strip trailing zeros of the fraction (before any exponent)
    let mut epos = -1
    let mut dot = -1
    for i in 0..o.len():
        let c = o[i] as i32
        if c == 46:
            dot = i
        if c == 101 or c == 69:
            epos = i
    if dot < 0:
        return o
    let mant_end = if epos >= 0: epos else: o.len()
    let mut cut = mant_end
    while cut > dot + 1 and (o[cut - 1] as i32) == 48:
        cut -= 1
    if cut == dot + 1:
        cut = dot
    let mut r: Bytes = Bytes()
    for i in 0..cut:
        r.push(o[i])
    for i in mant_end..o.len():
        r.push(o[i])
    r
