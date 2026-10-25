# A scripted telnet client for the M6 login comparison (todo.md HavokOS M6):
# connects to a driver, plays a script, and prints everything the driver
# sent, so the transcripts of two drivers can be compared byte for byte.
#
# Usage: telnet_script.exe <port> <script.txt>
#
# Script lines (blank lines and `#` comments skipped):
#   expect <text>   read until <text> has arrived after the previous
#                   expect's match (30 s at most; a timeout prints
#                   `TIMEOUT <text>` and ends the run)
#   send <text>     send <text> and CR LF (`send` alone sends an empty line)
#   raw <bytes>     send bytes given in the `~xx` form (telcodec.star)
#   pause <ms>      wait (reading meanwhile); for a mudlib's command rate
#                   limit -- where output lands in the transcript still
#                   follows the expects, not the pause
#   drain <ms>      at the end of a script: read until nothing has arrived
#                   for <ms> milliseconds
#
# Output: everything the driver sent, one `< ...` line per line it sent (in
# the `~xx` form, so telnet commands show), with each line this client sent
# as `> ...` at the point of the stream where the expect before it matched.
# Nothing depends on timing: a driver may split its output into packets
# however it likes (the reference writes a prompt's IAC GA separately, for
# instance), and a send is placed by content, not by when it happened.
#
# Build: star build projects/havokos/tools/telnet_script.star -o projects/havokos/tools/telnet_script.exe -l ws2_32

import "../telcodec.star" as enet

fn sub(s: str, a: i32, e: i32) -> str:
    let b = bytes_from_str(s)
    let mut o: Bytes = Bytes()
    let mut i = a
    while i < e and i < b.len():
        o.push(b[i])
        i += 1
    str_from_bytes(o)

fn num(s: str) -> i32:
    let b = bytes_from_str(s)
    let mut n = 0
    for i in 0..b.len():
        let c = b[i] as i32
        if c < 48 or c > 57:
            break
        n = n * 10 + (c - 48)
    n

struct Client:
    sock: ptr
    mut got: Bytes = Bytes()
    # where the last expect's match ended
    mut anchor: i32 = 0
    # sends, at the stream offset they belong to
    mut sent_at: List<i32> = List<i32>()
    mut sent: List<str> = List<str>()
    mut dead: bool = false

impl Client:
    # wait up to `ms` for data and take it
    fn pump(mut self, ms: i32) -> bool:
        if self.dead:
            return false
        let hs: List<ptr> = [self.sock]
        let ready = tcp_wait(hs, ms)
        if ready.len() == 0 or (ready[0] as i32) == 0:
            return false
        let d = tcp_recv_bytes(self.sock)
        if d.len() == 0:
            self.dead = true
            return false
        for i in 0..d.len():
            self.got.push(d[i])
        true

    # the end of `text`'s first occurrence after the anchor, or -1
    fn find(self, text: str) -> i32:
        let t = bytes_from_str(text)
        let n = self.got.len()
        let mut i = self.anchor
        while i + t.len() <= n:
            let mut ok = true
            for j in 0..t.len():
                if self.got[i + j] != t[j]:
                    ok = false
                    break
            if ok:
                return i + t.len()
            i += 1
        -1

    fn send(mut self, label: str, b: Bytes):
        self.sent_at.push(self.anchor)
        self.sent.push(label)
        let mut off = 0
        while off < b.len() and !self.dead:
            let n = tcp_send_bytes(self.sock, b, off)
            if n < 0:
                self.dead = true
                return
            off += n

    # the stream, one `<` line per line, the sends at their anchors
    fn print(self):
        let mut line: Bytes = Bytes()
        let mut k = 0
        for i in 0..self.got.len() + 1:
            while k < self.sent.len() and self.sent_at[k] == i:
                if line.len() > 0:
                    println(concat("< ", enet::tel_encode(line)))
                    line = Bytes()
                println(concat("> ", self.sent[k]))
                k += 1
            if i == self.got.len():
                break
            line.push(self.got[i])
            if (self.got[i] as i32) == 10:
                println(concat("< ", enet::tel_encode(line)))
                line = Bytes()
        if line.len() > 0:
            println(concat("< ", enet::tel_encode(line)))

fn main() -> i32:
    let cli = args()
    if cli.len() < 3:
        println("usage: telnet_script <port> <script.txt>")
        return 2
    let f = file_open(cli[2], "rb")
    if is_null(f):
        println("cannot read script")
        return 2
    let lines = str_split(str_replace(str_from_bytes(file_read_bytes(f)), "\r", ""), "\n")
    file_close(f)
    let s = tcp_connect("127.0.0.1", num(cli[1]))
    if is_null(s):
        println("cannot connect")
        return 1
    tcp_set_nonblocking(s, true)
    let mut c = Client(sock = s)
    for i in 0..lines.len():
        let l = lines[i]
        if l == "" or str_starts_with(l, "#"):
            continue
        if str_starts_with(l, "expect "):
            let t = sub(l, 7, len(l))
            let end = clock_ms() + (30000 as i64)
            while c.find(t) < 0 and !c.dead and clock_ms() < end:
                c.pump(200)
            let at = c.find(t)
            if at < 0:
                c.print()
                println(f"TIMEOUT {t}")
                return 1
            c.anchor = at
        elif str_starts_with(l, "pause "):
            let end = clock_ms() + (num(sub(l, 6, len(l))) as i64)
            while !c.dead and clock_ms() < end:
                c.pump(50)
        elif str_starts_with(l, "drain "):
            let quiet = num(sub(l, 6, len(l))) as i64
            let mut last = clock_ms()
            while !c.dead and clock_ms() - last < quiet:
                if c.pump(50):
                    last = clock_ms()
        elif l == "send" or str_starts_with(l, "send "):
            let t = if l == "send": "" else: sub(l, 5, len(l))
            let mut b = bytes_from_str(t)
            b.push(13 as u8)
            b.push(10 as u8)
            c.send(t, b)
        elif str_starts_with(l, "raw "):
            let b = enet::tel_decode(sub(l, 4, len(l)))
            c.send(concat("raw ", enet::tel_encode(b)), b)
    c.print()
    if !c.dead:
        tcp_close(s)
    0
