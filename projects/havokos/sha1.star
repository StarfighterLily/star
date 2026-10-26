# SHA-1 and base64 for the WebSocket handshake -- todo.md HavokOS P1 #8.
#
# A WebSocket upgrade is answered with Sec-WebSocket-Accept: the base64 of
# the SHA-1 of the client's key and RFC 6455's GUID, which the reference
# gets from Pike (Crypto.SHA1, MIME.encode_base64 in
# Protocols.WebSocket.Request). The key itself only qualifies when it
# base64-decodes to 16 bytes, with Pike's lenient decoder (MIME.decode_base64:
# characters outside the alphabet are skipped, the first `=` ends the data),
# so a sloppy key is still an upgrade there and here.
#
# Why not OpenSSL's SHA1(): the HTTP port works without TLS, and taking the
# hash through the FFI would need a C buffer for one 20-byte answer; md5.star
# set the precedent of a small hash written here. All 32-bit arithmetic is
# done in i64 and masked, as in md5.star.

fn m32() -> i64:
    ((1 as i64) << 32) - (1 as i64)

fn rotl(x: i64, c: i32) -> i64:
    ((x << c) | (x >> (32 - c))) & m32()

fn w32(hi: i32, lo: i32) -> i64:
    ((hi as i64) << 16) | (lo as i64)

# SHA-1 of msg: 20 bytes
fn sha1(msg: Bytes) -> Bytes:
    let mask = m32()
    let mut m = msg
    let bitlen = (msg.len() as i64) * (8 as i64)
    m.push(128 as u8)
    while m.len() % 64 != 56:
        m.push(0 as u8)
    for i in 0..8:
        m.push(((bitlen >> (8 * (7 - i))) & (255 as i64)) as u8)
    let mut h: List<i64> = [w32(26437, 8961), w32(61389, 43913), w32(39098, 56574), w32(4146, 21622), w32(50130, 57840)]
    let k: List<i64> = [w32(23170, 31129), w32(28377, 60321), w32(36635, 48348), w32(51810, 49622)]
    let mut chunk = 0
    while chunk < m.len():
        let mut w: List<i64> = List<i64>()
        for j in 0..16:
            let p = chunk + j * 4
            w.push(((m[p] as i64) << 24) | ((m[p + 1] as i64) << 16) | ((m[p + 2] as i64) << 8) | (m[p + 3] as i64))
        for j in 16..80:
            w.push(rotl(w[j - 3] ^ w[j - 8] ^ w[j - 14] ^ w[j - 16], 1))
        let mut a = h[0]
        let mut b = h[1]
        let mut c = h[2]
        let mut d = h[3]
        let mut e = h[4]
        for j in 0..80:
            let mut f = 0 as i64
            let mut kk = k[3]
            if j < 20:
                f = (b & c) | ((b ^ mask) & d)
                kk = k[0]
            elif j < 40:
                f = b ^ c ^ d
                kk = k[1]
            elif j < 60:
                f = (b & c) | (b & d) | (c & d)
                kk = k[2]
            else:
                f = b ^ c ^ d
            let t = (rotl(a, 5) + f + e + kk + w[j]) & mask
            e = d
            d = c
            c = rotl(b, 30)
            b = a
            a = t
        h[0] = (h[0] + a) & mask
        h[1] = (h[1] + b) & mask
        h[2] = (h[2] + c) & mask
        h[3] = (h[3] + d) & mask
        h[4] = (h[4] + e) & mask
        chunk += 64
    let mut out: Bytes = Bytes()
    for i in 0..5:
        for s in 0..4:
            out.push(((h[i] >> (24 - 8 * s)) & (255 as i64)) as u8)
    out

fn b64_alphabet() -> Bytes:
    bytes_from_str("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")

fn base64_encode(d: Bytes) -> str:
    let al = b64_alphabet()
    let mut o: Bytes = Bytes()
    let mut i = 0
    while i < d.len():
        let n = d.len() - i
        let b0 = d[i] as i32
        let b1 = if n > 1: d[i + 1] as i32 else: 0
        let b2 = if n > 2: d[i + 2] as i32 else: 0
        o.push(al[b0 >> 2])
        o.push(al[((b0 & 3) << 4) | (b1 >> 4)])
        o.push(if n > 1: al[((b1 & 15) << 2) | (b2 >> 6)] else: 61 as u8)
        o.push(if n > 2: al[b2 & 63] else: 61 as u8)
        i += 3
    str_from_bytes(o)

# MIME.decode_base64's leniency: characters outside the alphabet are
# skipped, the first `=` ends the data.
fn base64_decode(s: str) -> Bytes:
    let b = bytes_from_str(s)
    let mut out: Bytes = Bytes()
    let mut acc = 0
    let mut bits = 0
    for i in 0..b.len():
        let c = b[i] as i32
        let mut v = -1
        if c >= 65 and c <= 90:
            v = c - 65
        elif c >= 97 and c <= 122:
            v = c - 71
        elif c >= 48 and c <= 57:
            v = c + 4
        elif c == 43:
            v = 62
        elif c == 47:
            v = 63
        elif c == 61:
            break
        if v < 0:
            continue
        acc = ((acc << 6) | v) & 16777215
        bits += 6
        if bits >= 8:
            bits -= 8
            out.push(((acc >> bits) & 255) as u8)
    out
