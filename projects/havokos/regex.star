# Regular expressions for regexp() and reg_assoc() -- todo.md HavokOS M4
# (efuns).
#
# The reference compiles every pattern with Pike's Regexp.PCRE.Plain (after
# turning FluffOS's Spencer-style `\<`/`\>` word anchors into `\b`), so the
# dialect is PCRE's. This is the subset DS3.9 and ordinary LPC code use:
# literals and escapes, `.` (not newline), classes with ranges/negation/
# `\d\w\s` and `[:alpha:]`-style names, `^`/`$` (`$` also before a final
# newline, as in PCRE), `\b`/`\B`, groups `(...)`/`(?:...)`, `|`, and the
# quantifiers `* + ? {n} {n,} {n,m}` with lazy `?` forms. Anything else
# (backreferences, lookaround, inline options) is reported as a bad pattern,
# the reference's own error for a pattern PCRE rejects.
#
# Engine: the pattern compiles to a small program with *relative* jumps, so
# fragments can be concatenated while parsing without relocation, and runs
# as a backtracking search that explores alternatives in priority order --
# the first match found is PCRE's (leftmost, greedy-first). regexp() and
# reg_assoc() need no capture groups, only where the whole match starts and
# ends, so a state is just (instruction, position): states reached at a
# SPLIT are memoized per start position, which both stops empty loops like
# `(a*)*` from spinning forever and keeps a failing search from going
# exponential.
#
# The line editor (todo.md HavokOS M7, `ed.star`) does need groups: its
# `s///` puts `\1` and `&` in the replacement, from Pike's PCRE exec()
# vector. Capturing groups compile to RX_SAVE pairs, which rx_search() steps
# over and rx_exec() records, undoing them on backtrack through the same
# stack. The memo stays sound with captures: a state is only ever found
# visited after it failed (a success returns at once), and without
# backreferences whether a state can still match doesn't depend on what was
# captured on the way to it -- so the first match found is still PCRE's,
# groups included. ed's `\<`/`\>` (the reference: PCRE `\b(?=\w)` and
# `\b(?<=\w)`) are RX_WSTART/RX_WEND, reached only through rx_compile_ed(),
# since regexp() turns both into a plain `\b`.

const RX_CHAR: i32 = 1     # c
const RX_ANY: i32 = 2
const RX_CLASS: i32 = 3    # k (index into classes)
const RX_BOL: i32 = 4
const RX_EOL: i32 = 5
const RX_WB: i32 = 6
const RX_NWB: i32 = 7
const RX_JMP: i32 = 8      # off
const RX_SPLIT: i32 = 9    # a b (try pc+a, then pc+b)
const RX_MATCH: i32 = 10
const RX_SAVE: i32 = 11    # slot (2g: group g's start, 2g + 1: its end)
const RX_WSTART: i32 = 12
const RX_WEND: i32 = 13

struct Regex:
    mut ok: bool = true
    mut code: List<i32> = List<i32>()
    # 256 entries of 0/1 per class
    mut classes: List<Bytes> = List<Bytes>()
    mut nsplit: i32 = 0
    # SPLIT instruction pc -> its memo slot
    mut split_slot: List<i32> = List<i32>()
    # capturing groups
    mut ngroups: i32 = 0

struct RxParser:
    p: Bytes
    mut pos: i32 = 0
    mut ok: bool = true
    mut classes: List<Bytes> = List<Bytes>()
    mut ngroups: i32 = 0
    # ed's dialect: `\` + byte 1 / byte 2 (what ed_pattern() makes of `\<`
    # and `\>`) are the word-start and word-end anchors
    ed: bool = false

fn cat(a: List<i32>, b: List<i32>) -> List<i32>:
    let mut o = a
    for i in 0..b.len():
        o.push(b[i])
    o

fn frag_alt(a: List<i32>, b: List<i32>) -> List<i32>:
    let mut o: List<i32> = [RX_SPLIT, 3, 3 + a.len() + 2]
    o = cat(o, a)
    o.push(RX_JMP)
    o.push(2 + b.len())
    cat(o, b)

fn frag_star(f: List<i32>, lazy: bool) -> List<i32>:
    let mut o: List<i32> = List<i32>()
    o.push(RX_SPLIT)
    if lazy:
        o.push(3 + f.len() + 2)
        o.push(3)
    else:
        o.push(3)
        o.push(3 + f.len() + 2)
    o = cat(o, f)
    o.push(RX_JMP)
    o.push(0 - (3 + f.len()))
    o

fn frag_plus(f: List<i32>, lazy: bool) -> List<i32>:
    let mut o = f
    o.push(RX_SPLIT)
    if lazy:
        o.push(3)
        o.push(0 - f.len())
    else:
        o.push(0 - f.len())
        o.push(3)
    o

fn frag_opt(f: List<i32>, lazy: bool) -> List<i32>:
    let mut o: List<i32> = List<i32>()
    o.push(RX_SPLIT)
    if lazy:
        o.push(3 + f.len())
        o.push(3)
    else:
        o.push(3)
        o.push(3 + f.len())
    cat(o, f)

fn new_set() -> Bytes:
    let mut b: Bytes = Bytes()
    for i in 0..256:
        b.push(0 as u8)
    b

fn is_word(c: i32) -> bool:
    (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95

fn is_space(c: i32) -> bool:
    c == 32 or (c >= 9 and c <= 13)

# Add class escape `e` (d, w, s or their negations) to set b
fn add_escape_class(b_in: Bytes, e: i32) -> Bytes:
    let mut b = b_in
    for c in 0..256:
        let mut hit = false
        if e == 100 or e == 68:
            hit = c >= 48 and c <= 57
        elif e == 119 or e == 87:
            hit = is_word(c)
        else:
            hit = is_space(c)
        if e == 68 or e == 87 or e == 83:
            hit = !hit
        if hit:
            b[c] = 1 as u8
    b

fn add_posix(b_in: Bytes, name: str) -> Bytes:
    let mut b = b_in
    for c in 0..256:
        let mut hit = false
        let alpha = (c >= 65 and c <= 90) or (c >= 97 and c <= 122)
        let digit = c >= 48 and c <= 57
        if name == "alpha":
            hit = alpha
        elif name == "digit":
            hit = digit
        elif name == "alnum":
            hit = alpha or digit
        elif name == "space":
            hit = is_space(c)
        elif name == "upper":
            hit = c >= 65 and c <= 90
        elif name == "lower":
            hit = c >= 97 and c <= 122
        elif name == "punct":
            hit = (c >= 33 and c <= 47) or (c >= 58 and c <= 64) or (c >= 91 and c <= 96) or (c >= 123 and c <= 126)
        elif name == "xdigit":
            hit = digit or (c >= 65 and c <= 70) or (c >= 97 and c <= 102)
        elif name == "word":
            hit = is_word(c)
        elif name == "blank":
            hit = c == 32 or c == 9
        elif name == "cntrl":
            hit = c < 32 or c == 127
        elif name == "print":
            hit = c >= 32 and c <= 126
        elif name == "graph":
            hit = c >= 33 and c <= 126
        if hit:
            b[c] = 1 as u8
    b

# The character a simple escape stands for, or -1 if it isn't one
fn escape_char(e: i32) -> i32:
    if e == 110:
        return 10
    if e == 116:
        return 9
    if e == 114:
        return 13
    if e == 102:
        return 12
    if e == 118:
        return 11
    if e == 101:
        return 27
    if e == 97:
        return 7
    if (e >= 48 and e <= 57) or (e >= 65 and e <= 90) or (e >= 97 and e <= 122):
        return -1
    e

fn hexv(c: i32) -> i32:
    if c >= 48 and c <= 57:
        return c - 48
    if c >= 97 and c <= 102:
        return c - 87
    if c >= 65 and c <= 70:
        return c - 55
    -1

impl RxParser:
    fn peek(self) -> i32:
        if self.pos < self.p.len():
            return self.p[self.pos] as i32
        -1

    fn bad(mut self) -> List<i32>:
        self.ok = false
        List<i32>()

    fn add_class(mut self, b: Bytes) -> List<i32>:
        let k = self.classes.len()
        self.classes.push(b)
        [RX_CLASS, k]

    fn parse_alt(mut self) -> List<i32>:
        let mut f = self.parse_seq()
        while self.ok and self.peek() == 124:
            self.pos += 1
            let g = self.parse_seq()
            f = frag_alt(f, g)
        f

    fn parse_seq(mut self) -> List<i32>:
        let mut f: List<i32> = List<i32>()
        while self.ok:
            let c = self.peek()
            if c < 0 or c == 124 or c == 41:
                return f
            let a = self.parse_atom()
            if !self.ok:
                return f
            let q = self.parse_quant(a)
            f = cat(f, q)
        f

    # {n}, {n,}, {n,m} at pos (just after '{'); -2 means "not a quantifier"
    fn read_num(mut self) -> i32:
        let mut n = -1
        while self.peek() >= 48 and self.peek() <= 57:
            if n < 0:
                n = 0
            n = n * 10 + (self.peek() - 48)
            self.pos += 1
        n

    fn parse_quant(mut self, atom: List<i32>) -> List<i32>:
        let mut f = atom
        while self.ok:
            let c = self.peek()
            let mut lo = -1
            let mut hi = -1
            if c == 42:
                lo = 0
                hi = -1
                self.pos += 1
            elif c == 43:
                lo = 1
                hi = -1
                self.pos += 1
            elif c == 63:
                lo = 0
                hi = 1
                self.pos += 1
            elif c == 123:
                let save = self.pos
                self.pos += 1
                let a = self.read_num()
                if a < 0:
                    self.pos = save
                    return f
                lo = a
                hi = a
                if self.peek() == 44:
                    self.pos += 1
                    hi = self.read_num()
                if self.peek() != 125 or (hi >= 0 and hi < lo):
                    self.pos = save
                    return f
                self.pos += 1
            else:
                return f
            let mut lazy = false
            if self.peek() == 63:
                lazy = true
                self.pos += 1
            elif self.peek() == 43:
                self.pos += 1
            let mut out: List<i32> = List<i32>()
            for i in 0..lo:
                out = cat(out, f)
            if hi < 0:
                if lo == 0:
                    out = cat(out, frag_star(f, lazy))
                else:
                    # f{n,}: n-1 copies, then f+
                    out = List<i32>()
                    for i in 0..lo - 1:
                        out = cat(out, f)
                    out = cat(out, frag_plus(f, lazy))
            elif hi > lo:
                let mut tail: List<i32> = List<i32>()
                for i in 0..hi - lo:
                    tail = frag_opt(cat(f, tail), lazy)
                out = cat(out, tail)
            f = out
        f

    fn parse_atom(mut self) -> List<i32>:
        let c = self.peek()
        self.pos += 1
        if c == 40:
            let mut g = 0
            if self.peek() == 63:
                if self.pos + 1 < self.p.len() and (self.p[self.pos + 1] as i32) == 58:
                    self.pos += 2
                else:
                    return self.bad()
            else:
                self.ngroups += 1
                g = self.ngroups
            let f = self.parse_alt()
            if self.peek() != 41:
                return self.bad()
            self.pos += 1
            if g == 0:
                return f
            return cat(cat([RX_SAVE, 2 * g], f), [RX_SAVE, 2 * g + 1])
        if c == 41 or c == 42 or c == 43 or c == 63:
            return self.bad()
        if c == 91:
            return self.parse_class()
        if c == 46:
            return [RX_ANY]
        if c == 94:
            return [RX_BOL]
        if c == 36:
            return [RX_EOL]
        if c == 92:
            let e = self.peek()
            if e < 0:
                return self.bad()
            self.pos += 1
            if e == 100 or e == 68 or e == 119 or e == 87 or e == 115 or e == 83:
                return self.add_class(add_escape_class(new_set(), e))
            if e == 98:
                return [RX_WB]
            if e == 66:
                return [RX_NWB]
            if self.ed and e == 1:
                return [RX_WSTART]
            if self.ed and e == 2:
                return [RX_WEND]
            if e == 120:
                let h1 = hexv(self.peek())
                if h1 < 0:
                    return [RX_CHAR, 0]
                self.pos += 1
                let h2 = hexv(self.peek())
                if h2 < 0:
                    return [RX_CHAR, h1]
                self.pos += 1
                return [RX_CHAR, h1 * 16 + h2]
            let ch = escape_char(e)
            if ch < 0:
                return self.bad()
            return [RX_CHAR, ch]
        [RX_CHAR, c]

    fn parse_class(mut self) -> List<i32>:
        let mut b = new_set()
        let mut neg = false
        if self.peek() == 94:
            neg = true
            self.pos += 1
        let mut first = true
        while true:
            let c = self.peek()
            if c < 0:
                return self.bad()
            if c == 93 and !first:
                self.pos += 1
                break
            first = false
            self.pos += 1
            let mut lo = c
            if c == 91 and self.peek() == 58:
                # [:name:]
                let start = self.pos + 1
                let mut k = start
                while k < self.p.len() and (self.p[k] as i32) != 58:
                    k += 1
                if k + 1 < self.p.len() and (self.p[k + 1] as i32) == 93:
                    let mut nb: Bytes = Bytes()
                    for i in start..k:
                        nb.push(self.p[i])
                    b = add_posix(b, str_from_bytes(nb))
                    self.pos = k + 2
                    continue
            if c == 92:
                let e = self.peek()
                if e < 0:
                    return self.bad()
                self.pos += 1
                if e == 100 or e == 68 or e == 119 or e == 87 or e == 115 or e == 83:
                    b = add_escape_class(b, e)
                    continue
                if e == 98:
                    lo = 8
                else:
                    let ch = escape_char(e)
                    lo = if ch < 0: e else: ch
            # a range lo-hi (a '-' before ']' is literal)
            if self.peek() == 45 and self.pos + 1 < self.p.len() and (self.p[self.pos + 1] as i32) != 93:
                self.pos += 1
                let mut hi = self.peek()
                self.pos += 1
                if hi == 92:
                    let e = self.peek()
                    self.pos += 1
                    let ch = escape_char(e)
                    hi = if ch < 0: e else: ch
                if hi < lo:
                    return self.bad()
                for x in lo..hi + 1:
                    b[x] = 1 as u8
            else:
                b[lo] = 1 as u8
        if neg:
            for x in 0..256:
                b[x] = if (b[x] as i32) == 0: 1 as u8 else: 0 as u8
        self.add_class(b)

fn rx_compile(pat: str) -> Regex:
    rx_compile_opts(pat, false)

# ed.pike compile(): an ed_pattern() result, with ed's word anchors
fn rx_compile_ed(pat: str) -> Regex:
    rx_compile_opts(pat, true)

fn rx_compile_opts(pat: str, ed: bool) -> Regex:
    let mut ps = RxParser(p = bytes_from_str(pat), ed = ed)
    let mut code = ps.parse_alt()
    if ps.pos < ps.p.len():
        ps.ok = false
    let mut r = Regex()
    if !ps.ok:
        r.ok = false
        return r
    code.push(RX_MATCH)
    r.code = code
    r.classes = ps.classes
    r.ngroups = ps.ngroups
    let mut pc = 0
    while pc < code.len():
        r.split_slot.push(-1)
        let op = code[pc]
        let mut w = 1
        if op == RX_CHAR or op == RX_CLASS or op == RX_JMP or op == RX_SAVE:
            w = 2
        elif op == RX_SPLIT:
            w = 3
            r.split_slot[pc] = r.nsplit
            r.nsplit += 1
        for k in 1..w:
            r.split_slot.push(-1)
        pc += w
    r

# The leftmost match in s: [start, end], or [] for none. One function, so
# the memo table stays a local: a `mut` List parameter would be copied on
# its first write for every start position (copy-on-write, NOTES.md
# constraint #1). `memo` holds, per SPLIT slot and position, the start
# position (+1) whose search already visited that state.
fn rx_search(r: Regex, s: Bytes) -> List<i32>:
    let n = s.len()
    let mut memo: List<i32> = List<i32>()
    for i in 0..r.nsplit * (n + 1):
        memo.push(0)
    let mut stack: List<i32> = List<i32>()
    for start in 0..n + 1:
        stack.push(0)
        stack.push(start)
        let stamp = start + 1
        while stack.len() > 0:
            let mut sp = stack.pop()
            let mut pc = stack.pop()
            let mut alive = true
            while alive:
                let op = r.code[pc]
                if op == RX_CHAR:
                    if sp < n and (s[sp] as i32) == r.code[pc + 1]:
                        pc += 2
                        sp += 1
                    else:
                        alive = false
                elif op == RX_ANY:
                    if sp < n and (s[sp] as i32) != 10:
                        pc += 1
                        sp += 1
                    else:
                        alive = false
                elif op == RX_CLASS:
                    if sp < n and (r.classes[r.code[pc + 1]][s[sp] as i32] as i32) != 0:
                        pc += 2
                        sp += 1
                    else:
                        alive = false
                elif op == RX_BOL:
                    if sp == 0:
                        pc += 1
                    else:
                        alive = false
                elif op == RX_EOL:
                    if sp == n or (sp == n - 1 and (s[sp] as i32) == 10):
                        pc += 1
                    else:
                        alive = false
                elif op == RX_WB or op == RX_NWB:
                    let before = sp > 0 and is_word(s[sp - 1] as i32)
                    let after = sp < n and is_word(s[sp] as i32)
                    let at_b = before != after
                    if at_b == (op == RX_WB):
                        pc += 1
                    else:
                        alive = false
                elif op == RX_JMP:
                    pc = pc + r.code[pc + 1]
                elif op == RX_SAVE:
                    pc += 2
                elif op == RX_WSTART or op == RX_WEND:
                    if word_anchor(s, sp, op):
                        pc += 1
                    else:
                        alive = false
                elif op == RX_SPLIT:
                    let slot = r.split_slot[pc] * (n + 1) + sp
                    if memo[slot] == stamp:
                        alive = false
                    else:
                        memo[slot] = stamp
                        stack.push(pc + r.code[pc + 2])
                        stack.push(sp)
                        pc = pc + r.code[pc + 1]
                else:
                    return [start, sp]
    List<i32>()

# `\<` (a word starts at sp) or `\>` (one ends there)
fn word_anchor(s: Bytes, sp: i32, op: i32) -> bool:
    let before = sp > 0 and is_word(s[sp - 1] as i32)
    let after = sp < s.len() and is_word(s[sp] as i32)
    if op == RX_WSTART:
        return !before and after
    before and !after

# Pike's Regexp.PCRE exec(s, from), as ed.pike uses it: the leftmost match
# starting at or after `from` (`^` still means the start of s, and the
# anchors see the bytes before `from`), as [start, end, g1 start, g1 end,
# ...] with -1 for a group that took no part, or [] for none. rx_search()'s
# loop plus the captures: stack entries are triples, and an RX_SAVE pushes a
# restore entry (tag = its slot) that backtracking pops on its way back to
# the branch entry (tag -1) before it.
fn rx_exec(r: Regex, s: Bytes, from: i32) -> List<i32>:
    let n = s.len()
    if from > n:
        return List<i32>()
    let nc = 2 * (r.ngroups + 1)
    let mut memo: List<i32> = List<i32>()
    for i in 0..r.nsplit * (n + 1):
        memo.push(0)
    let mut caps: List<i32> = List<i32>()
    for i in 0..nc:
        caps.push(-1)
    let mut stack: List<i32> = List<i32>()
    for start in from..n + 1:
        for i in 0..nc:
            caps[i] = -1
        stack.push(0)
        stack.push(start)
        stack.push(-1)
        let stamp = start + 1
        while stack.len() > 0:
            let tag = stack.pop()
            let b = stack.pop()
            let a = stack.pop()
            if tag >= 0:
                caps[tag] = a
                continue
            let mut pc = a
            let mut sp = b
            let mut alive = true
            while alive:
                let op = r.code[pc]
                if op == RX_CHAR:
                    if sp < n and (s[sp] as i32) == r.code[pc + 1]:
                        pc += 2
                        sp += 1
                    else:
                        alive = false
                elif op == RX_ANY:
                    if sp < n and (s[sp] as i32) != 10:
                        pc += 1
                        sp += 1
                    else:
                        alive = false
                elif op == RX_CLASS:
                    if sp < n and (r.classes[r.code[pc + 1]][s[sp] as i32] as i32) != 0:
                        pc += 2
                        sp += 1
                    else:
                        alive = false
                elif op == RX_BOL:
                    if sp == 0:
                        pc += 1
                    else:
                        alive = false
                elif op == RX_EOL:
                    if sp == n or (sp == n - 1 and (s[sp] as i32) == 10):
                        pc += 1
                    else:
                        alive = false
                elif op == RX_WB or op == RX_NWB:
                    let before = sp > 0 and is_word(s[sp - 1] as i32)
                    let after = sp < n and is_word(s[sp] as i32)
                    let at_b = before != after
                    if at_b == (op == RX_WB):
                        pc += 1
                    else:
                        alive = false
                elif op == RX_WSTART or op == RX_WEND:
                    if word_anchor(s, sp, op):
                        pc += 1
                    else:
                        alive = false
                elif op == RX_JMP:
                    pc = pc + r.code[pc + 1]
                elif op == RX_SAVE:
                    let slot = r.code[pc + 1]
                    stack.push(caps[slot])
                    stack.push(0)
                    stack.push(slot)
                    caps[slot] = sp
                    pc += 2
                elif op == RX_SPLIT:
                    let slot = r.split_slot[pc] * (n + 1) + sp
                    if memo[slot] == stamp:
                        alive = false
                    else:
                        memo[slot] = stamp
                        stack.push(pc + r.code[pc + 2])
                        stack.push(sp)
                        stack.push(-1)
                        pc = pc + r.code[pc + 1]
                else:
                    let mut m: List<i32> = [start, sp]
                    for i in 2..nc:
                        m.push(caps[i])
                    return m
    List<i32>()

# ed.pike compile()'s translation: `\<` and `\>`, scanned left to right as
# Pike's replace() does, become the escapes only rx_compile_ed() reads.
fn ed_pattern(pat: str) -> str:
    let b = bytes_from_str(pat)
    let mut o: Bytes = Bytes()
    let mut i = 0
    while i < b.len():
        if (b[i] as i32) == 92 and i + 1 < b.len() and ((b[i + 1] as i32) == 60 or (b[i + 1] as i32) == 62):
            o.push(92 as u8)
            o.push(if (b[i + 1] as i32) == 60: 1 as u8 else: 2 as u8)
            i += 2
        else:
            o.push(b[i])
            i += 1
    str_from_bytes(o)

# The reference's FluffOS-to-PCRE translation: `\<` and `\>` become `\b`.
fn spencer_to_pcre(pat: str) -> str:
    let b = bytes_from_str(pat)
    let mut o: Bytes = Bytes()
    let mut i = 0
    while i < b.len():
        if (b[i] as i32) == 92 and i + 1 < b.len() and ((b[i + 1] as i32) == 60 or (b[i + 1] as i32) == 62):
            o.push(92 as u8)
            o.push(98 as u8)
            i += 2
        else:
            o.push(b[i])
            i += 1
    str_from_bytes(o)
