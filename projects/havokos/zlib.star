# zlib streams (RFC 1950) of deflate data (RFC 1951) -- todo.md HavokOS
# P1 #8, for MCCP v2: once a client agrees to COMPRESS2, everything the
# driver sends it is one zlib stream, sync-flushed after each write, as the
# reference does with Pike's Gz.deflate(6) (`havok/net.pike` raw_send()).
#
# Why written here rather than linked: Star has no zlib binding, and the
# compressor MCCP needs is small -- one stream per connection, always
# flushed. Linking zlib1.dll (Git for Windows ships one) would have meant a
# second third-party DLL beside SQLite for a few hundred lines of code, and
# a builtin layer to move buffers across the FFI (NOTES.md constraint #9).
#
# What the stream holds differs from zlib's own, byte for byte: matching and
# block choices are this file's (zlib level 6's parameters -- chains of 128,
# lazy matching below 16, "nice" length 128 -- but not its exact
# heuristics). That is invisible to a client: what it inflates is the same
# text. So the MCCP cases compare inflated output, and `tools/zlib_check.star`
# (tests/run_zlib_test.ps1) checks this compressor against Pike's real
# zlib inflater and this inflater against zlib-made streams.
#
# The compressor:
# - LZ77 over a sliding history of at least 32 KB (matches reach back across
#   earlier writes, as one zlib stream's do), hash chains on 3-byte
#   prefixes, lazy matching one byte ahead, and zlib's "too far" rule (a
#   3-byte match more than 4 KB back is a worse deal than three literals).
# - Each block is sent in whichever of the three forms is smallest: dynamic
#   Huffman codes (length-limited by rescaling the frequencies until the
#   tree fits), the fixed codes, or stored. A typical MUD write -- a line or
#   two of text -- comes out as fixed codes; a long room description or a
#   big `more` page as dynamic.
# - deflate() always ends with a flush: SYNC_FLUSH (an empty stored block,
#   so the client can decode everything sent so far) or FINISH (the final
#   block and the Adler-32 trailer). MCCP needs nothing else, so pending
#   input is never held back between calls.
#
# The inflater (inflate_zlib()) decodes a whole buffer: a finished stream,
# or a stream cut off after a sync flush (what an MCCP client has seen so
# far). It is only used by tests -- the case runner's test_inflate() hook --
# and is written for clarity (canonical decoding a bit at a time, as zlib's
# own `puff` reference does) rather than speed.

const SYNC_FLUSH: i32 = 2
const FINISH: i32 = 4

const WSIZE: i32 = 32768
const WMASK: i32 = 32767
const HSIZE: i32 = 32768
const HMASK: i32 = 32767
const MIN_MATCH: i32 = 3
const MAX_MATCH: i32 = 258
const MAX_CHAIN: i32 = 128
const LAZY: i32 = 16
const NICE: i32 = 128
const TOO_FAR: i32 = 4096
# symbols per block before it is sent
const BLOCK_SYMS: i32 = 16384

# The length and distance code tables of RFC 1951 3.2.5, shared by both
# directions.
struct ZTables:
    mut lbase: List<i32> = List<i32>()
    mut lext: List<i32> = List<i32>()
    mut dbase: List<i32> = List<i32>()
    mut dext: List<i32> = List<i32>()
    # match length (3..258) -> length code index (0..28)
    mut lcode: List<i32> = List<i32>()

fn ztables() -> ZTables:
    let mut t = ZTables()
    t.lbase = [3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258]
    t.lext = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0]
    t.dbase = [1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577]
    t.dext = [0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13]
    for i in 0..MAX_MATCH + 1:
        t.lcode.push(0)
    for k in 0..28:
        for j in 0..(1 << t.lext[k]):
            if t.lbase[k] + j < MAX_MATCH:
                t.lcode[t.lbase[k] + j] = k
    t.lcode[MAX_MATCH] = 28
    t

fn zeros(n: i32) -> List<i32>:
    let mut l: List<i32> = List<i32>()
    for i in 0..n:
        l.push(0)
    l

# Distance (1..32768) -> distance code (0..29).
fn dist_code(t: ZTables, d: i32) -> i32:
    let mut c = 29
    while t.dbase[c] > d:
        c -= 1
    c

# Code lengths for `freq`, none longer than `limit`. At least two symbols
# get a code, so every code is complete (RFC 1951 allows a lone one-bit
# distance code, but a complete code is valid for every inflater).
fn build_lengths(freq_in: List<i32>, limit: i32) -> List<i32>:
    let n = freq_in.len()
    let mut freq = freq_in
    let mut used = 0
    let mut one = -1
    for i in 0..n:
        if freq[i] > 0:
            used += 1
            one = i
    if used == 0:
        freq[0] = 1
        freq[1] = 1
    elif used == 1:
        freq[if one == 0: 1 else: 0] = 1
    let mut lens = zeros(n)
    while true:
        # Huffman's construction: leaves 0..n-1, internal nodes after them
        let mut weight: List<i32> = List<i32>()
        let mut parent: List<i32> = List<i32>()
        let mut active: List<i32> = List<i32>()
        for i in 0..n:
            weight.push(freq[i])
            parent.push(-1)
            if freq[i] > 0:
                active.push(i)
        while active.len() > 1:
            let ia = min_index(weight, active)
            let na = active[ia]
            active[ia] = active[active.len() - 1]
            active.pop()
            let ib = min_index(weight, active)
            let nb = active[ib]
            active[ib] = active[active.len() - 1]
            active.pop()
            let id = weight.len()
            weight.push(weight[na] + weight[nb])
            parent.push(-1)
            parent[na] = id
            parent[nb] = id
            active.push(id)
        let mut deepest = 0
        for i in 0..n:
            lens[i] = 0
            if freq[i] > 0:
                let mut d = 0
                let mut p = parent[i]
                while p >= 0:
                    d += 1
                    p = parent[p]
                lens[i] = d
                if d > deepest:
                    deepest = d
        if deepest <= limit:
            return lens
        # flatten the frequencies and try again; all-equal weights give a
        # balanced tree, at most 9 deep for 286 symbols
        for i in 0..n:
            if freq[i] > 0:
                freq[i] = (freq[i] + 1) / 2
    lens

# Index into `active` of its lightest node.
fn min_index(weight: List<i32>, active: List<i32>) -> i32:
    let mut best = 0
    for i in 1..active.len():
        if weight[active[i]] < weight[active[best]]:
            best = i
    best

# Canonical codes for `lens`, bit-reversed for LSB-first writing.
fn make_codes(lens: List<i32>) -> List<i32>:
    let mut count = zeros(16)
    for i in 0..lens.len():
        count[lens[i]] += 1
    count[0] = 0
    let mut next = zeros(16)
    let mut code = 0
    for b in 1..16:
        code = (code + count[b - 1]) << 1
        next[b] = code
    let mut codes = zeros(lens.len())
    for i in 0..lens.len():
        let l = lens[i]
        if l > 0:
            codes[i] = reverse_bits(next[l], l)
            next[l] += 1
    codes

fn reverse_bits(v: i32, n: i32) -> i32:
    let mut r = 0
    let mut x = v
    for i in 0..n:
        r = (r << 1) | (x & 1)
        x = x >> 1
    r

fn fixed_lit_lens() -> List<i32>:
    let mut l: List<i32> = List<i32>()
    for i in 0..288:
        l.push(if i < 144: 8 elif i < 256: 9 elif i < 280: 7 else: 8)
    l

fn fixed_dist_lens() -> List<i32>:
    let mut l: List<i32> = List<i32>()
    for i in 0..30:
        l.push(5)
    l

# The order code length code lengths are sent in (RFC 1951 3.2.7).
fn clen_order() -> List<i32>:
    [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15]

# One block's dynamic code description: the run-length coded code lengths
# and the code that codes them.
struct DynHeader:
    hlit: i32
    hdist: i32
    hclen: i32
    rsym: List<i32>
    rext: List<i32>
    blens: List<i32>
    bits: i32

fn dyn_header(ll: List<i32>, dl: List<i32>) -> DynHeader:
    let mut hlit = 286
    while hlit > 257 and ll[hlit - 1] == 0:
        hlit -= 1
    let mut hdist = 30
    while hdist > 1 and dl[hdist - 1] == 0:
        hdist -= 1
    let mut seq: List<i32> = List<i32>()
    for i in 0..hlit:
        seq.push(ll[i])
    for i in 0..hdist:
        seq.push(dl[i])
    let mut rsym: List<i32> = List<i32>()
    let mut rext: List<i32> = List<i32>()
    let mut i = 0
    while i < seq.len():
        let v = seq[i]
        let mut run = 1
        while i + run < seq.len() and seq[i + run] == v:
            run += 1
        i += run
        if v == 0:
            while run >= 11:
                let r = if run > 138: 138 else: run
                rsym.push(18)
                rext.push(r - 11)
                run -= r
            while run >= 3:
                let r = if run > 10: 10 else: run
                rsym.push(17)
                rext.push(r - 3)
                run -= r
        else:
            rsym.push(v)
            rext.push(0)
            run -= 1
            while run >= 3:
                let r = if run > 6: 6 else: run
                rsym.push(16)
                rext.push(r - 3)
                run -= r
        while run > 0:
            rsym.push(v)
            rext.push(0)
            run -= 1
    let mut bf = zeros(19)
    for k in 0..rsym.len():
        bf[rsym[k]] += 1
    let blens = build_lengths(bf, 7)
    let order = clen_order()
    let mut hclen = 19
    while hclen > 4 and blens[order[hclen - 1]] == 0:
        hclen -= 1
    let mut bits = 5 + 5 + 4 + 3 * hclen
    for k in 0..rsym.len():
        let s = rsym[k]
        bits += blens[s] + (if s == 16: 2 elif s == 17: 3 elif s == 18: 7 else: 0)
    DynHeader(hlit = hlit, hdist = hdist, hclen = hclen, rsym = rsym, rext = rext, blens = blens, bits = bits)

# One zlib stream being written.
struct Deflater:
    mut ready: bool = false
    mut t: ZTables = ZTables()
    # history and the current input; positions are offsets into it
    mut win: Bytes = Bytes()
    # hash of a 3-byte prefix -> latest position with it, plus one (0: none)
    mut head: List<i32> = List<i32>()
    # position & WMASK -> the previous position with the same hash, plus one
    mut prev: List<i32> = List<i32>()
    # the block being collected: a literal byte (0..255) or 256 + a match
    # length per symbol, and each match's distance; the input it covers
    mut syms: List<i32> = List<i32>()
    mut dists: List<i32> = List<i32>()
    mut blk_start: i32 = 0
    mut blk_len: i32 = 0
    mut out: Bytes = Bytes()
    mut bitbuf: i32 = 0
    mut nbits: i32 = 0
    mut started: bool = false
    mut done: bool = false
    mut ad_a: i64 = 1 as i64
    mut ad_b: i64 = 0 as i64

impl Deflater:
    fn init(mut self):
        if self.ready:
            return
        self.ready = true
        self.t = ztables()
        self.head = zeros(HSIZE)
        self.prev = zeros(WSIZE)

    # Compress `data`, then flush (SYNC_FLUSH) or end the stream (FINISH).
    # Returns the bytes for the wire; nothing once the stream has ended.
    fn deflate(mut self, data: Bytes, flush: i32) -> Bytes:
        self.init()
        if self.done:
            return Bytes()
        self.out = Bytes()
        if !self.started:
            # CM 8, a 32 KB window, the default level's FLEVEL, no dictionary
            self.out.push(120 as u8)
            self.out.push(156 as u8)
            self.started = true
        self.adler(data)
        let start = self.win.len()
        for i in 0..data.len():
            self.win.push(data[i])
        self.blk_start = start
        self.blk_len = 0
        self.compress(start)
        let last = flush == FINISH
        if self.syms.len() > 0 or last:
            self.flush_block(last)
        if last:
            self.align()
            let v = self.ad_b * (65536 as i64) + self.ad_a
            self.out.push(((v / (16777216 as i64)) % (256 as i64)) as u8)
            self.out.push(((v / (65536 as i64)) % (256 as i64)) as u8)
            self.out.push(((v / (256 as i64)) % (256 as i64)) as u8)
            self.out.push((v % (256 as i64)) as u8)
            self.done = true
        else:
            # an empty stored block ends on a byte boundary: 00 00 ff ff
            self.put_bits(0, 3)
            self.align()
            self.out.push(0 as u8)
            self.out.push(0 as u8)
            self.out.push(255 as u8)
            self.out.push(255 as u8)
        self.slide()
        let o = self.out
        self.out = Bytes()
        o

    fn adler(mut self, d: Bytes):
        let m = 65521 as i64
        let mut a = self.ad_a
        let mut b = self.ad_b
        let mut k = 0
        while k < d.len():
            let stop = if k + 5552 < d.len(): k + 5552 else: d.len()
            while k < stop:
                a = a + (d[k] as i64)
                b = b + a
                k += 1
            a = a % m
            b = b % m
        self.ad_a = a
        self.ad_b = b

    fn put_bits(mut self, v: i32, n: i32):
        self.bitbuf = self.bitbuf | (v << self.nbits)
        self.nbits += n
        while self.nbits >= 8:
            self.out.push((self.bitbuf & 255) as u8)
            self.bitbuf = self.bitbuf >> 8
            self.nbits -= 8

    fn align(mut self):
        if self.nbits > 0:
            self.out.push((self.bitbuf & 255) as u8)
        self.bitbuf = 0
        self.nbits = 0

    fn hash_at(self, i: i32) -> i32:
        (((self.win[i] as i32) << 10) ^ ((self.win[i + 1] as i32) << 5) ^ (self.win[i + 2] as i32)) & HMASK

    # Enter position i in the hash chains; the previous head of its chain.
    fn insert(mut self, i: i32) -> i32:
        let h = self.hash_at(i)
        let c = self.head[h]
        self.prev[i & WMASK] = c
        self.head[h] = i + 1
        c

    # The longest match for position i, searching the chain from `first`
    # (a position plus one), as length * 65536 + distance; 0 for none.
    # Chain entries at or before i - WSIZE are stale (their prev slot has
    # been reused), so the search stops there.
    fn longest(self, i: i32, end: i32, first: i32) -> i32:
        let maxlen = if end - i < MAX_MATCH: end - i else: MAX_MATCH
        if maxlen < MIN_MATCH:
            return 0
        let limit = i - WSIZE
        let mut c = first
        let mut best = MIN_MATCH - 1
        let mut bdist = 0
        let mut chain = MAX_CHAIN
        while c > 0 and chain > 0:
            let p = c - 1
            if p <= limit:
                break
            if self.win[p + best] == self.win[i + best] and self.win[p] == self.win[i]:
                let mut n = 1
                while n < maxlen and self.win[p + n] == self.win[i + n]:
                    n += 1
                if n > best:
                    best = n
                    bdist = i - p
                    if n >= maxlen or n >= NICE:
                        break
            c = self.prev[p & WMASK]
            chain -= 1
        if bdist == 0 or (best == MIN_MATCH and bdist > TOO_FAR):
            return 0
        best * 65536 + bdist

    fn emit_lit(mut self, c: i32):
        self.syms.push(c)
        self.dists.push(0)
        self.blk_len += 1
        if self.syms.len() >= BLOCK_SYMS:
            self.flush_block(false)

    fn emit_match(mut self, n: i32, d: i32):
        self.syms.push(256 + n)
        self.dists.push(d)
        self.blk_len += n
        if self.syms.len() >= BLOCK_SYMS:
            self.flush_block(false)

    # LZ77 over win[start..]: a match found at i is only taken once the
    # match at i + 1 turned out no longer (lazy matching).
    fn compress(mut self, start: i32):
        let end = self.win.len()
        let mut i = start
        let mut have = false
        let mut plen = 0
        let mut pdist = 0
        while i < end:
            let mut m = 0
            if i + MIN_MATCH <= end:
                let c = self.insert(i)
                if c > 0 and (!have or plen < LAZY):
                    m = self.longest(i, end, c)
            let mlen = m / 65536
            let mdist = m % 65536
            if have and plen >= MIN_MATCH and mlen <= plen:
                self.emit_match(plen, pdist)
                let stop = i - 1 + plen
                let mut k = i + 1
                while k < stop:
                    if k + MIN_MATCH <= end:
                        self.insert(k)
                    k += 1
                i = stop
                have = false
                continue
            if have:
                self.emit_lit(self.win[i - 1] as i32)
            have = true
            plen = mlen
            pdist = mdist
            i += 1
        # a decision still pending is for the last byte, which can't start
        # a match
        if have:
            self.emit_lit(self.win[end - 1] as i32)

    # Send the collected block in its smallest form.
    fn flush_block(mut self, last: bool):
        let mut lf = zeros(286)
        let mut df = zeros(30)
        for k in 0..self.syms.len():
            let s = self.syms[k]
            if s < 256:
                lf[s] += 1
            else:
                lf[257 + self.t.lcode[s - 256]] += 1
                df[dist_code(self.t, self.dists[k])] += 1
        lf[256] = 1
        let ll = build_lengths(lf, 15)
        let dl = build_lengths(df, 15)
        let hdr = dyn_header(ll, dl)
        let dyn_bits = 3 + hdr.bits + self.data_bits(lf, df, ll, dl)
        let fixed_bits = 3 + self.data_bits(lf, df, fixed_lit_lens(), fixed_dist_lens())
        let n = self.blk_len
        let chunks = if n == 0: 1 else: (n + 65534) / 65535
        let stored_bits = chunks * (3 + 7 + 32) + 8 * n
        let fin = if last: 1 else: 0
        if stored_bits < dyn_bits and stored_bits < fixed_bits:
            let mut off = self.blk_start
            let stop = self.blk_start + n
            let mut first = true
            while first or off < stop:
                first = false
                let cnt = if stop - off > 65535: 65535 else: stop - off
                self.put_bits(if off + cnt >= stop: fin else: 0, 1)
                self.put_bits(0, 2)
                self.align()
                self.out.push((cnt & 255) as u8)
                self.out.push((cnt >> 8) as u8)
                self.out.push((~cnt & 255) as u8)
                self.out.push(((~cnt >> 8) & 255) as u8)
                for q in off..off + cnt:
                    self.out.push(self.win[q])
                off += cnt
        elif fixed_bits <= dyn_bits:
            self.put_bits(fin, 1)
            self.put_bits(1, 2)
            self.send_syms(fixed_lit_lens(), fixed_dist_lens())
        else:
            self.put_bits(fin, 1)
            self.put_bits(2, 2)
            self.put_bits(hdr.hlit - 257, 5)
            self.put_bits(hdr.hdist - 1, 5)
            self.put_bits(hdr.hclen - 4, 4)
            let order = clen_order()
            for k in 0..hdr.hclen:
                self.put_bits(hdr.blens[order[k]], 3)
            let bcodes = make_codes(hdr.blens)
            for k in 0..hdr.rsym.len():
                let s = hdr.rsym[k]
                self.put_bits(bcodes[s], hdr.blens[s])
                if s == 16:
                    self.put_bits(hdr.rext[k], 2)
                elif s == 17:
                    self.put_bits(hdr.rext[k], 3)
                elif s == 18:
                    self.put_bits(hdr.rext[k], 7)
            self.send_syms(ll, dl)
        self.syms = List<i32>()
        self.dists = List<i32>()
        self.blk_start += n
        self.blk_len = 0

    # Bits the block's symbols take under the given code lengths.
    fn data_bits(self, lf: List<i32>, df: List<i32>, ll: List<i32>, dl: List<i32>) -> i32:
        let mut bits = 0
        for s in 0..286:
            if lf[s] > 0:
                bits += lf[s] * ll[s]
                if s > 256:
                    bits += lf[s] * self.t.lext[s - 257]
        for d in 0..30:
            if df[d] > 0:
                bits += df[d] * (dl[d] + self.t.dext[d])
        bits

    fn send_syms(mut self, ll: List<i32>, dl: List<i32>):
        let lc = make_codes(ll)
        let dc = make_codes(dl)
        for k in 0..self.syms.len():
            let s = self.syms[k]
            if s < 256:
                self.put_bits(lc[s], ll[s])
            else:
                let n = s - 256
                let c = self.t.lcode[n]
                self.put_bits(lc[257 + c], ll[257 + c])
                if self.t.lext[c] > 0:
                    self.put_bits(n - self.t.lbase[c], self.t.lext[c])
                let d = self.dists[k]
                let dcd = dist_code(self.t, d)
                self.put_bits(dc[dcd], dl[dcd])
                if self.t.dext[dcd] > 0:
                    self.put_bits(d - self.t.dbase[dcd], self.t.dext[dcd])
        self.put_bits(lc[256], ll[256])

    # Keep between 32 and 64 KB of history. Dropping a multiple of WSIZE
    # keeps every position's prev slot (position & WMASK) where it was.
    fn slide(mut self):
        let n = self.win.len()
        if n <= 2 * WSIZE:
            return
        let off = ((n - WSIZE) / WSIZE) * WSIZE
        let mut w: Bytes = Bytes()
        for i in off..n:
            w.push(self.win[i])
        self.win = w
        for h in 0..HSIZE:
            let e = self.head[h]
            self.head[h] = if e > off: e - off else: 0
        for p in 0..WSIZE:
            let e = self.prev[p]
            self.prev[p] = if e > off: e - off else: 0
        self.blk_start = 0

# --- inflating -------------------------------------------------------------------

# A canonical code for decoding: how many codes have each length, and the
# symbols in code order.
struct Huff:
    count: List<i32>
    symbol: List<i32>

fn make_huff(lens: List<i32>) -> Huff:
    let mut count = zeros(16)
    for i in 0..lens.len():
        count[lens[i]] += 1
    let mut offs = zeros(16)
    for b in 1..15:
        offs[b + 1] = offs[b] + count[b]
    let mut symbol = zeros(lens.len())
    for i in 0..lens.len():
        if lens[i] > 0:
            symbol[offs[lens[i]]] = i
            offs[lens[i]] += 1
    Huff(count = count, symbol = symbol)

# What inflate_zlib() made of a buffer: the bytes decoded, whether the
# stream ended (final block and a matching Adler-32), and whether it was
# broken (a bad header, code or checksum). A stream that simply stops
# after a sync flush is neither.
struct Inflated:
    out: Bytes
    ended: bool
    broken: bool

struct Inflate:
    mut inp: Bytes = Bytes()
    mut ip: i32 = 0
    mut bitbuf: i32 = 0
    mut bitcnt: i32 = 0
    mut out: Bytes = Bytes()
    mut eof: bool = false
    mut bad: bool = false
    mut t: ZTables = ZTables()

impl Inflate:
    fn bits(mut self, need: i32) -> i32:
        let mut v = self.bitbuf
        while self.bitcnt < need:
            if self.ip >= self.inp.len():
                self.eof = true
                return 0
            v = v | ((self.inp[self.ip] as i32) << self.bitcnt)
            self.ip += 1
            self.bitcnt += 8
        self.bitbuf = v >> need
        self.bitcnt -= need
        v & ((1 << need) - 1)

    fn decode(mut self, h: Huff) -> i32:
        let mut code = 0
        let mut first = 0
        let mut index = 0
        for l in 1..16:
            code = code | self.bits(1)
            if self.eof:
                return -1
            let count = h.count[l]
            if code - count < first:
                return h.symbol[index + (code - first)]
            index += count
            first += count
            first = first << 1
            code = code << 1
        self.bad = true
        -1

    fn stored(mut self):
        self.bitbuf = 0
        self.bitcnt = 0
        if self.ip + 4 > self.inp.len():
            self.eof = true
            return
        let cnt = (self.inp[self.ip] as i32) | ((self.inp[self.ip + 1] as i32) << 8)
        let ncnt = (self.inp[self.ip + 2] as i32) | ((self.inp[self.ip + 3] as i32) << 8)
        if cnt != (~ncnt & 65535):
            self.bad = true
            return
        self.ip += 4
        for k in 0..cnt:
            if self.ip >= self.inp.len():
                self.eof = true
                return
            self.out.push(self.inp[self.ip])
            self.ip += 1

    fn codes(mut self, lit: Huff, dist: Huff):
        while true:
            let s = self.decode(lit)
            if s < 0:
                return
            if s < 256:
                self.out.push(s as u8)
            elif s == 256:
                return
            else:
                let c = s - 257
                if c >= 29:
                    self.bad = true
                    return
                let n = self.t.lbase[c] + self.bits(self.t.lext[c])
                let dc = self.decode(dist)
                if dc < 0:
                    return
                if dc >= 30:
                    self.bad = true
                    return
                let d = self.t.dbase[dc] + self.bits(self.t.dext[dc])
                if self.eof:
                    return
                if d > self.out.len():
                    self.bad = true
                    return
                let src = self.out.len() - d
                for k in 0..n:
                    self.out.push(self.out[src + k])

    fn dynamic(mut self):
        let nlen = self.bits(5) + 257
        let ndist = self.bits(5) + 1
        let ncode = self.bits(4) + 4
        if self.eof:
            return
        let order = clen_order()
        let mut cl = zeros(19)
        for k in 0..ncode:
            cl[order[k]] = self.bits(3)
        let ch = make_huff(cl)
        let mut lens: List<i32> = List<i32>()
        while lens.len() < nlen + ndist:
            let s = self.decode(ch)
            if s < 0:
                return
            if s < 16:
                lens.push(s)
            else:
                let mut v = 0
                let mut rep = 0
                if s == 16:
                    if lens.len() == 0:
                        self.bad = true
                        return
                    v = lens[lens.len() - 1]
                    rep = 3 + self.bits(2)
                elif s == 17:
                    rep = 3 + self.bits(3)
                else:
                    rep = 11 + self.bits(7)
                if lens.len() + rep > nlen + ndist:
                    self.bad = true
                    return
                for k in 0..rep:
                    lens.push(v)
            if self.eof:
                return
        let mut ll: List<i32> = List<i32>()
        for k in 0..nlen:
            ll.push(lens[k])
        let mut dl: List<i32> = List<i32>()
        for k in nlen..nlen + ndist:
            dl.push(lens[k])
        self.codes(make_huff(ll), make_huff(dl))

fn inflate_zlib(data: Bytes) -> Inflated:
    let mut z = Inflate(inp = data, t = ztables())
    if data.len() < 2 or ((data[0] as i32) & 15) != 8 or ((data[0] as i32) * 256 + (data[1] as i32)) % 31 != 0 or ((data[1] as i32) & 32) != 0:
        return Inflated(out = Bytes(), ended = false, broken = data.len() >= 2)
    z.ip = 2
    let fixed_l = make_huff(fixed_lit_lens())
    let fixed_d = make_huff(fixed_dist_lens())
    let mut ended = false
    while !z.eof and !z.bad:
        # nothing left at a block boundary: a stream cut after a flush
        if z.ip >= z.inp.len() and z.bitcnt < 3:
            break
        let fin = z.bits(1)
        let kind = z.bits(2)
        if z.eof:
            break
        if kind == 0:
            z.stored()
        elif kind == 1:
            z.codes(fixed_l, fixed_d)
        elif kind == 2:
            z.dynamic()
        else:
            z.bad = true
        if fin == 1 and !z.eof and !z.bad:
            # the Adler-32 of the output, big-endian, after the last block
            if z.ip + 4 > z.inp.len():
                break
            let mut a = 1 as i64
            let mut b = 0 as i64
            for k in 0..z.out.len():
                a = (a + (z.out[k] as i64)) % (65521 as i64)
                b = (b + a) % (65521 as i64)
            let mut want = 0 as i64
            for k in 0..4:
                want = want * (256 as i64) + (z.inp[z.ip + k] as i64)
            if want != b * (65536 as i64) + a:
                z.bad = true
            ended = !z.bad
            break
    Inflated(out = z.out, ended = ended, broken = z.bad)
