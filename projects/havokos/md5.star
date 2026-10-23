# MD5 and MD5-crypt for crypt()/oldcrypt() -- todo.md HavokOS M4 (efuns).
#
# The reference's crypt() is "$1$" + salt + "$" + Pike's
# Crypto.MD5.crypt_hash(password, salt): the FreeBSD/glibc MD5-crypt
# algorithm (RFC 1321 MD5 at its core), deterministic for a given salt so
# the usual LPC check `crypt(pw, stored) == stored` works. Pike has it built
# in; Star doesn't, so both are here. The salt rules are the reference
# efun's (`efuns_str.star`): an existing "$1$salt$..." hash supplies its
# salt, any other string of 2+ characters its first 8, and anything else
# gets a random 8-character salt.
#
# All 32-bit arithmetic is done in i64 and masked: Star's u32/i64 `+` and
# `*` trap on overflow (NOTES.md deviation #6's wrapping helpers would do
# too, but masking after each add keeps every intermediate below 2^34).

fn m32() -> i64:
    ((1 as i64) << 32) - (1 as i64)

fn rotl(x: i64, c: i32) -> i64:
    ((x << c) | (x >> (32 - c))) & m32()

fn md5_k() -> List<i64>:
    # floor(abs(sin(i + 1)) * 2^32), as 32-bit words split in 16-bit halves
    # because i64 literals above 2^31 need arithmetic (NOTES.md #6)
    let hi = [55146, 59591, 9248, 49597, 62844, 18311, 43056, 64838, 27008, 35652, 65535, 35164, 27536, 64920, 42617, 18868, 63006, 49216, 9822, 59830, 54831, 580, 55457, 59347, 8673, 49975, 62677, 17754, 43491, 64751, 26479, 36138, 65530, 34673, 28061, 64997, 42174, 19422, 63163, 48831, 10395, 60065, 54511, 1160, 55764, 59099, 8098, 50348, 62505, 17194, 43924, 64659, 25947, 36620, 65519, 34180, 28584, 65068, 41729, 19976, 63315, 48442, 10967, 60294]
    let lo = [42104, 46934, 28891, 52974, 4015, 50730, 17939, 38145, 39128, 63407, 23473, 55230, 4386, 29075, 17294, 2081, 9570, 45888, 23121, 51114, 4189, 5203, 59009, 64456, 52710, 2006, 3463, 5357, 59653, 41976, 729, 19594, 14658, 63105, 24866, 14348, 59972, 53161, 19296, 48240, 32454, 10234, 12421, 7429, 53305, 39397, 31992, 22117, 8772, 65431, 9127, 41017, 22979, 52370, 62589, 24017, 32335, 59104, 17172, 4513, 32386, 62005, 53947, 54161]
    let mut k: List<i64> = List<i64>()
    for i in 0..64:
        k.push(((hi[i] as i64) << 16) | (lo[i] as i64))
    k

fn md5_r() -> List<i32>:
    [7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21]

# MD5 of msg: 16 bytes
fn md5(msg: Bytes) -> Bytes:
    let k = md5_k()
    let r = md5_r()
    let mask = m32()
    let mut m = msg
    let bitlen = (msg.len() as i64) * (8 as i64)
    m.push(128 as u8)
    while m.len() % 64 != 56:
        m.push(0 as u8)
    for i in 0..8:
        m.push(((bitlen >> (8 * i)) & (255 as i64)) as u8)
    let mut a0 = ((26437 as i64) << 16) | (8961 as i64)     # 0x67452301
    let mut b0 = ((61389 as i64) << 16) | (43913 as i64)    # 0xefcdab89
    let mut c0 = ((39098 as i64) << 16) | (56574 as i64)    # 0x98badcfe
    let mut d0 = ((4146 as i64) << 16) | (21622 as i64)     # 0x10325476
    let mut chunk = 0
    while chunk < m.len():
        let mut w: List<i64> = List<i64>()
        for j in 0..16:
            let p = chunk + j * 4
            w.push((m[p] as i64) | ((m[p + 1] as i64) << 8) | ((m[p + 2] as i64) << 16) | ((m[p + 3] as i64) << 24))
        let mut a = a0
        let mut b = b0
        let mut c = c0
        let mut d = d0
        for i in 0..64:
            let mut f = 0 as i64
            let mut g = 0
            if i < 16:
                f = (b & c) | ((b ^ mask) & d)
                g = i
            elif i < 32:
                f = (d & b) | ((d ^ mask) & c)
                g = (5 * i + 1) % 16
            elif i < 48:
                f = b ^ c ^ d
                g = (3 * i + 5) % 16
            else:
                f = c ^ (b | (d ^ mask))
                g = (7 * i) % 16
            let t = (a + f + k[i] + w[g]) & mask
            a = d
            d = c
            c = b
            b = (b + rotl(t, r[i])) & mask
        a0 = (a0 + a) & mask
        b0 = (b0 + b) & mask
        c0 = (c0 + c) & mask
        d0 = (d0 + d) & mask
        chunk += 64
    let mut out: Bytes = Bytes()
    let words = [a0, b0, c0, d0]
    for i in 0..4:
        for j in 0..4:
            out.push(((words[i] >> (8 * j)) & (255 as i64)) as u8)
    out

fn cat_b(a: Bytes, b: Bytes) -> Bytes:
    let mut o = a
    for i in 0..b.len():
        o.push(b[i])
    o

fn to64(mut o: Bytes, v_in: i64, n: i32) -> Bytes:
    let chars = bytes_from_str("./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
    let mut v = v_in
    for i in 0..n:
        o.push(chars[(v & (63 as i64)) as i32])
        v = v >> 6
    o

# Pike's Crypto.MD5.crypt_hash(pw, salt): the 22-character hash part of
# "$1$salt$hash" (the salt is used up to its first 8 characters).
fn md5_crypt_hash(pw: Bytes, salt_in: Bytes) -> str:
    let mut salt: Bytes = Bytes()
    for i in 0..salt_in.len():
        if i < 8 and (salt_in[i] as i32) != 36:
            salt.push(salt_in[i])
    let magic = bytes_from_str("$1$")
    let alt = md5(cat_b(cat_b(pw, salt), pw))
    let mut ctx = cat_b(cat_b(pw, magic), salt)
    let mut pl = pw.len()
    while pl > 0:
        let n = if pl > 16: 16 else: pl
        for i in 0..n:
            ctx.push(alt[i])
        pl -= 16
    let mut i = pw.len()
    while i > 0:
        if (i & 1) != 0:
            ctx.push(0 as u8)
        elif pw.len() > 0:
            ctx.push(pw[0])
        else:
            ctx.push(0 as u8)
        i = i >> 1
    let mut fin = md5(ctx)
    for r in 0..1000:
        let mut c: Bytes = Bytes()
        if (r & 1) != 0:
            c = cat_b(c, pw)
        else:
            c = cat_b(c, fin)
        if r % 3 != 0:
            c = cat_b(c, salt)
        if r % 7 != 0:
            c = cat_b(c, pw)
        if (r & 1) != 0:
            c = cat_b(c, fin)
        else:
            c = cat_b(c, pw)
        fin = md5(c)
    let mut o: Bytes = Bytes()
    o = to64(o, ((fin[0] as i64) << 16) | ((fin[6] as i64) << 8) | (fin[12] as i64), 4)
    o = to64(o, ((fin[1] as i64) << 16) | ((fin[7] as i64) << 8) | (fin[13] as i64), 4)
    o = to64(o, ((fin[2] as i64) << 16) | ((fin[8] as i64) << 8) | (fin[14] as i64), 4)
    o = to64(o, ((fin[3] as i64) << 16) | ((fin[9] as i64) << 8) | (fin[15] as i64), 4)
    o = to64(o, ((fin[4] as i64) << 16) | ((fin[10] as i64) << 8) | (fin[5] as i64), 4)
    o = to64(o, fin[11] as i64, 2)
    str_from_bytes(o)
