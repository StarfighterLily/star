# The line editor -- todo.md HavokOS M7 (`ed`): `havok/ed.pike`'s Session
# (the engine) and the efun glue from `havok/efuns.pike` (EdIO, ed_start(),
# ed_cmd(), query_ed_mode(), in_edit(), ed_rescue()). Dead Souls routes
# every editor through `lib/editor.c` -- the `ed` command, mail, board
# posts, bug/praise/suicide, lsed -- so until this existed all of them
# raised "not implemented".
#
# The reference's engine was written for HavokOS from POSIX ed(1) and the
# Dead Souls editor primer, its protocol learned from the FluffOS binary as
# a black box (HavokOS `docs/ed-clean-room.md`); this is a port of that
# engine, method for method, and the reference's own `ed` cases plus this
# port's edge cases pin it (`tests/fixtures/cases/m7_*`). Messages are the
# reference's word for word.
#
# Shape. A session is an `eddata.star` EdSession in `Vm.eds`, addressed by
# index from the owner's `ObjSlot.ed`; the methods here take that index and
# work through `self.eds[e]`, because file access (valid_read/valid_write,
# make_path_absolute(), the option word) calls the master in the middle of
# a command and only a `mut self` method on the Vm can do that (NOTES.md
# constraint #2). The reference abandons a command by throwing an EdError;
# here ed_oops() writes the message and sets `oops`, and every step checks
# ed_stop() -- which also stops on an LPC error from a master apply, which
# the reference doesn't catch either, so it reaches the ed_cmd() caller.
#
# Numbers typed in commands are read as i64 and capped (the reference has
# bignums), so `999999999999+999999999999` is "Line out of range." rather
# than an overflow trap (NOTES.md constraint #11).
#
# Patterns go through `regex.star`, the regexp() efun's PCRE subset plus
# capturing groups and ed's `\<`/`\>`, where the reference hands them to
# full PCRE: a backreference, lookaround or inline option is "Bad regular
# expression" here (NOTES.md deviation #15).
#
# Wiring: efuns.star dispatches codes 370-379 to efun_ed(); objects.star
# destruct_object() calls ed_destructed(), at the point driver.pike calls
# ed_rescue(); gc.star counts an editing object as referenced for
# get_garbage(), since the reference's EdIO holds it.

import "value.star" as val
import "vm.star" as vm
import "eddata.star" as edd
import "buf.star" as bf
import "regex.star" as rx
import "efun_table.star" as et

const ED_NONE: i32 = -1
const MODE_NONE: i32 = -1
const MODE_COMMAND: i32 = 0
const MODE_HELP: i32 = -2
const OPT_NUMBER: i32 = 1
const OPT_LIST: i32 = 2
const Z_LINES: i32 = 20
const BIG_Z_LINES: i32 = 40
const HELP_PAGE: i32 = 18

fn ed_help_lines() -> List<str>:
    [
        "Line editor commands.  [range] is a line or two lines separated by",
        "a comma: 3   3,7   .   $   .,$   'a   /text/   ?text?   .+2   $-5",
        "With no range most commands work on the current line.",
        "",
        "  [range]p      print lines           [range]l   print, showing tabs etc.",
        "  [range]n      print with numbers    n          line numbers on/off",
        "  [line]a       add text after line   [line]i    add text before line",
        "  [range]c      replace lines with new text",
        "                (while adding text, a line with just . finishes)",
        "  [range]d      delete lines          u          undo the last change",
        "  [range]j      join lines into one   [line]kx   mark line as 'x",
        "  [range]m line move lines after line [range]t line  copy lines",
        "  [range]s/pattern/new/[g][p]   substitute (g: every match on the line;",
        "                & in new is the match, \\1 a ( ) group, \\n a line break)",
        "  [range]g/pattern/cmd   run cmd on matching lines (v: non-matching)",
        "  /pattern   ?pattern    find the next/previous matching line",
        "  =          show the line number     z, [line]z  show a page of lines",
        "  RETURN     show the next line",
        "",
        "  w [file]   save       W file   append to file     wq  save and exit",
        "  x          save (if changed) and exit",
        "  q          exit (refused if there are unsaved changes)",
        "  Q          exit without saving",
        "  e file     edit another file (E discards unsaved changes)",
        "  r file     read file in after the line    f [file]  show/set the name",
        "  set        show options; set number, set nolist, ... ; set save",
        "",
        "Patterns: . any char, * repeat, + one or more, ? optional, [a-z] class,",
        "^ start, $ end, ( ) group, | either.  Put \\ before these to match them."
    ]

# b[a..e) as a str (clamped)
fn sub_str(b: Bytes, a_in: i32, e_in: i32) -> str:
    let a = if a_in < 0: 0 else: a_in
    let e = if e_in > b.len(): b.len() else: e_in
    let mut o: Bytes = Bytes()
    for i in a..e:
        o.push(b[i])
    str_from_bytes(o)

fn byte_str(c: i32) -> str:
    let mut o: Bytes = Bytes()
    o.push(c as u8)
    str_from_bytes(o)

# Pike String.trim_all_whites() on 8-bit text: tab, LF, VT, FF, CR, space,
# NEL (0x85) and NBSP (0xa0) -- probed against the reference's Pike
fn is_white(c: i32) -> bool:
    (c >= 9 and c <= 13) or c == 32 or c == 133 or c == 160

fn trim_ws(s: str) -> str:
    let b = bytes_from_str(s)
    let mut a = 0
    let mut e = b.len()
    while a < e and is_white(b[a] as i32):
        a += 1
    while e > a and is_white(b[e - 1] as i32):
        e -= 1
    if a == 0 and e == b.len():
        return s
    sub_str(b, a, e)

# ed.pike split_text(): file text as lines (CRLF as LF, no final empty line)
fn ed_split(text_in: str) -> List<str>:
    let mut text = text_in
    if str_contains(text, "\r"):
        text = str_replace(text, "\r\n", "\n")
    let mut lines = str_split(text, "\n")
    if lines.len() > 0 and lines[lines.len() - 1] == "":
        lines.pop()
    lines

fn pad4(n: i32) -> str:
    let mut s = f"{n}"
    while len(s) < 4:
        s = concat(" ", s)
    s

fn plural_s(n: i32) -> str:
    if n == 1:
        return ""
    "s"

fn big_cap() -> i64:
    (1000000 as i64) * (1000000 as i64)

fn min64(a: i64, b: i64) -> i64:
    if a < b:
        return a
    b

fn max64(a: i64, b: i64) -> i64:
    if a > b:
        return a
    b

# list[a..e) (clamped), Pike's buf[a..e - 1]
fn slice_lines(l: List<str>, a_in: i32, e_in: i32) -> List<str>:
    let a = if a_in < 0: 0 else: a_in
    let e = if e_in > l.len(): l.len() else: e_in
    let mut o: List<str> = List<str>()
    for i in a..e:
        o.push(l[i])
    o

fn no_marks() -> List<i32>:
    let mut m: List<i32> = List<i32>()
    for i in 0..26:
        m.push(-1)
    m

# ed.pike expand(): the replacement for one match -- `&` the match, `\N`
# group N (nothing for a group that took no part), `\n` a line break, `\c`
# the character c
fn ed_expand(rep: Bytes, m: List<i32>, line: Bytes) -> Bytes:
    let mut o: Bytes = Bytes()
    let mut i = 0
    while i < rep.len():
        let c = rep[i] as i32
        if c == 38:
            for k in m[0]..m[1]:
                o.push(line[k])
            i += 1
            continue
        if c == 92 and i + 1 < rep.len():
            i += 1
            let d = rep[i] as i32
            if d >= 48 and d <= 57:
                let g = d - 48
                if 2 * g + 1 < m.len() and m[2 * g] >= 0:
                    for k in m[2 * g]..m[2 * g + 1]:
                        o.push(line[k])
            elif d == 110:
                o.push(10 as u8)
            else:
                o.push(d as u8)
            i += 1
            continue
        o.push(c as u8)
        i += 1
    o

# What ed_read() found: kind 1 text, 0 no such file, -1 denied, -2 a
# directory (EdIO read()'s string / 0 / -1 / -2)
struct EdRead:
    kind: i32
    text: str

impl vm::Vm:
    # --- sessions ---------------------------------------------------------------

    fn ed_new(mut self, ob: i32) -> i32:
        let mut e = -1
        let mut i = 0
        while i < self.eds.len():
            if !self.eds[i].alive and !self.eds[i].running:
                e = i
                break
            i += 1
        let s = edd::EdSession(owner = ob, marks = no_marks())
        if e < 0:
            e = self.eds.len()
            self.eds.push(s)
        else:
            self.eds[e] = s
        e

    # The session ends: its slot (and buffer) can go to the next one.
    fn ed_drop(mut self, e: i32):
        self.eds[e].alive = false
        self.eds[e].finished = true
        if !self.eds[e].running:
            self.eds[e] = edd::EdSession(alive = false)

    fn ed_of(self, ob: i32) -> i32:
        if !self.alive(ob):
            return -1
        let e = self.objs[ob].ed
        if e >= 0 and e < self.eds.len() and self.eds[e].alive:
            return e
        -1

    # --- EdIO: file access as the editing object --------------------------------

    # A master apply under the reference's catch: an error in it is dropped
    # and the answer is 0.
    fn ed_master_try(mut self, name: str, args: List<val::Value>, ob: i32) -> val::Value:
        let ol = self.ostack.len()
        let sl = self.stack.len()
        let r = self.master_apply(name, args, ob)
        if self.err:
            self.clear_err()
            self.truncate_ostack(ol)
            self.truncate_stack(sl)
            return val::Value::Int(0 as i64)
        r

    # A relative name goes through the master's make_path_absolute() (Dead
    # Souls applies the user's cwd), then is normalised.
    fn ed_resolve(mut self, ob: i32, p_in: str) -> str:
        let mut p = p_in
        if !str_starts_with(p, "/"):
            let r = self.ed_master_try("make_path_absolute", [val::Value::Str(p)], ob)
            match r:
                val::Value::Str(x) ->
                    if x != "":
                        p = x
                _ -> 0
        self.mud_abs(p)

    fn ed_read(mut self, ob: i32, path: str) -> EdRead:
        if !self.check_read(ob, path, "ed_start"):
            return EdRead(kind = -1, text = "")
        let rp = self.mud_real(path)
        let k = path_kind(rp)
        if k == 2:
            return EdRead(kind = -2, text = "")
        if k != 1:
            return EdRead(kind = 0, text = "")
        let t = self.read_whole(rp)
        if !t.ok:
            return EdRead(kind = 0, text = "")
        EdRead(kind = 1, text = t.text)

    fn ed_write(mut self, ob: i32, path: str, text: str, append: bool) -> bool:
        if !self.check_write(ob, path, "ed_start"):
            return false
        self.write_whole(self.mud_real(path), text, append)

    fn ed_load_setup(mut self, ob: i32) -> i32:
        match self.ed_master_try("retrieve_ed_setup", [self.obj_value(ob)], ob):
            val::Value::Int(x) -> x as i32
            _ -> 0

    fn ed_save_setup(mut self, ob: i32, code: i32) -> bool:
        let r = self.ed_master_try("save_ed_setup", [self.obj_value(ob), val::Value::Int(code as i64)], ob)
        self.truthy(r)

    # --- output and errors ------------------------------------------------------

    fn ed_say(mut self, e: i32, s: str):
        self.eds[e].out.add_str(s)

    # ed.pike oops(): the message, and the command is abandoned
    fn ed_oops(mut self, e: i32, msg: str):
        if self.eds[e].oops:
            return
        self.eds[e].oops = true
        self.ed_say(e, msg)

    fn ed_stop(self, e: i32) -> bool:
        self.eds[e].oops or self.err

    fn ed_take(mut self, e: i32) -> str:
        let s = self.eds[e].out.to_str()
        self.eds[e].out = bf::Buf()
        s

    # query_ed_mode()
    fn ed_mode(self, e: i32) -> i32:
        if self.eds[e].finished:
            return MODE_NONE
        if self.eds[e].in_help:
            return MODE_HELP
        if self.eds[e].inserting:
            return self.eds[e].ins_after + 1
        MODE_COMMAND

    # The buffer as file text.
    fn ed_text(self, e: i32) -> str:
        let b = self.eds[e].buf
        if b.len() == 0:
            return ""
        concat(str_join(b, "\n"), "\n")

    # --- start-up (Session create()) --------------------------------------------

    fn ed_open(mut self, e: i32, ob: i32, has_file: bool, file: str, restricted: bool):
        self.eds[e].restricted = restricted
        self.eds[e].options = self.ed_load_setup(ob) & (OPT_NUMBER | OPT_LIST)
        if self.err or !has_file:
            return
        let name = self.ed_resolve(ob, file)
        self.eds[e].filename = name
        let t = self.ed_read(ob, name)
        if self.err:
            return
        if t.kind == 1:
            self.eds[e].buf = ed_split(t.text)
            let n = self.eds[e].buf.len()
            self.eds[e].cur = if n > 0: 1 else: 0
            if !restricted:
                let nb = len(t.text)
                self.ed_say(e, f"\"{name}\" {n} line{plural_s(n)}, {nb} byte{plural_s(nb)}\n")
        elif t.kind == -1:
            # the buffer stays empty and nameless, so nothing can be
            # written back under the denied name by accident
            self.ed_say(e, f"\"{name}\": permission denied.\n")
            self.eds[e].filename = ""
        elif t.kind == -2:
            self.ed_say(e, f"\"{name}\" is a directory.\n")
        elif !restricted:
            self.ed_say(e, f"\"{name}\": new file.\n")

    # --- buffer primitives: every change goes through ed_splice(), which keeps
    # marks and g/v flags lined up and records the undo state ------------------

    fn ed_about_to_change(mut self, e: i32):
        if self.eds[e].changed:
            return
        self.eds[e].changed = true
        self.eds[e].has_undo = true
        self.eds[e].undo_buf = self.eds[e].buf
        self.eds[e].undo_cur = self.eds[e].cur
        self.eds[e].undo_dirty = self.eds[e].dirty
        self.eds[e].undo_marks = self.eds[e].marks

    # Replace `count` lines from line `from` (1-based) with `lines`.
    fn ed_splice(mut self, e: i32, from: i32, count: i32, lines: List<str>):
        self.ed_about_to_change(e)
        let i = from - 1
        let old = self.eds[e].buf
        let mut nb = slice_lines(old, 0, i)
        for k in 0..lines.len():
            nb.push(lines[k])
        for k in i + count..old.len():
            nb.push(old[k])
        self.eds[e].buf = nb
        let delta = lines.len() - count
        for k in 0..26:
            let l = self.eds[e].marks[k]
            if l < 0:
                continue
            if l >= from + count:
                self.eds[e].marks[k] = l + delta
            elif l >= from:
                self.eds[e].marks[k] = if lines.len() > 0: from else: -1
        if self.eds[e].gon:
            let og = self.eds[e].gflags
            let mut ng: List<bool> = List<bool>()
            for k in 0..i:
                ng.push(og[k])
            for k in 0..lines.len():
                ng.push(false)
            for k in i + count..og.len():
                ng.push(og[k])
            self.eds[e].gflags = ng
        self.eds[e].dirty = true

    fn ed_undo(mut self, e: i32):
        if !self.eds[e].has_undo:
            self.ed_oops(e, "Nothing to undo.\n")
            return
        let b = self.eds[e].buf
        let c = self.eds[e].cur
        let d = self.eds[e].dirty
        let m = self.eds[e].marks
        self.eds[e].buf = self.eds[e].undo_buf
        self.eds[e].cur = self.eds[e].undo_cur
        self.eds[e].marks = self.eds[e].undo_marks
        self.eds[e].undo_buf = b
        self.eds[e].undo_cur = c
        self.eds[e].undo_dirty = d
        self.eds[e].undo_marks = m
        self.eds[e].dirty = true
        # keep this swap as the undo state
        self.eds[e].changed = true

    # --- the command entry point ------------------------------------------------

    fn ed_command(mut self, e: i32, line_in: str) -> str:
        self.eds[e].out = bf::Buf()
        if self.eds[e].finished:
            return ""
        let mut line = line_in
        if str_ends_with(line, "\r"):
            let b = bytes_from_str(line)
            line = sub_str(b, 0, b.len() - 1)
        if self.eds[e].in_help:
            if line == "":
                self.ed_next_help_page(e)
                return self.ed_take(e)
            # anything else leaves the help
            self.eds[e].in_help = false
            self.eds[e].help_pages = List<str>()
        if self.eds[e].inserting:
            self.ed_input_line(e, line)
            return self.ed_take(e)
        self.eds[e].changed = false
        let was_z = self.eds[e].last_was_z
        self.eds[e].last_was_z = false
        self.eds[e].oops = false
        self.ed_run(e, line, false, was_z)
        self.eds[e].oops = false
        if self.err:
            return ""
        self.ed_take(e)

    fn ed_input_line(mut self, e: i32, line: str):
        if line == ".":
            self.eds[e].inserting = false
            return
        self.ed_splice(e, self.eds[e].ins_after + 1, 0, [line])
        self.eds[e].ins_after += 1
        self.eds[e].cur = self.eds[e].ins_after

    fn ed_start_input(mut self, e: i32, after: i32):
        # one undo step covers the whole input
        self.ed_about_to_change(e)
        self.eds[e].inserting = true
        self.eds[e].ins_after = after
        self.eds[e].cur = after

    # --- addresses --------------------------------------------------------------

    fn ed_peek(self, e: i32) -> i32:
        let p = self.eds[e].pos
        if p < self.eds[e].s.len():
            return self.eds[e].s[p] as i32
        0

    fn ed_skip_blanks(mut self, e: i32):
        while self.ed_peek(e) == 32 or self.ed_peek(e) == 9:
            self.eds[e].pos += 1

    fn ed_read_number(mut self, e: i32) -> i64:
        let mut n: i64 = 0 as i64
        while self.ed_peek(e) >= 48 and self.ed_peek(e) <= 57:
            if n < big_cap():
                n = n * (10 as i64) + ((self.ed_peek(e) - 48) as i64)
            self.eds[e].pos += 1
        n

    # Text up to an unescaped `delim` (consumed if present). "\delim" is
    # the delimiter itself; other escapes are kept for the regexp.
    fn ed_read_delimited(mut self, e: i32, delim: i32) -> str:
        let s = self.eds[e].s
        let mut o = bf::Buf()
        let mut p = self.eds[e].pos
        while p < s.len():
            let c = s[p] as i32
            p += 1
            if c == delim:
                self.eds[e].pos = p
                return o.to_str()
            if c == 92 and p < s.len():
                let d = s[p] as i32
                p += 1
                if d != delim:
                    o.byte(92)
                o.byte(d)
                continue
            o.byte(c)
        self.eds[e].pos = p
        o.to_str()

    # One address, or ED_NONE when none is present.
    fn ed_address(mut self, e: i32) -> i32:
        self.ed_skip_blanks(e)
        let mut have = false
        let mut line: i64 = 0 as i64
        let c = self.ed_peek(e)
        if c == 46:
            self.eds[e].pos += 1
            line = self.eds[e].cur as i64
            have = true
        elif c == 36:
            self.eds[e].pos += 1
            line = self.eds[e].buf.len() as i64
            have = true
        elif c >= 48 and c <= 57:
            line = self.ed_read_number(e)
            have = true
        elif c == 39:
            self.eds[e].pos += 1
            let m = self.ed_peek(e)
            if m < 97 or m > 122:
                self.ed_oops(e, "Marks are named 'a to 'z.\n")
                return ED_NONE
            self.eds[e].pos += 1
            let l = self.eds[e].marks[m - 97]
            if l < 0:
                self.ed_oops(e, f"Mark '{byte_str(m)} is not set.\n")
                return ED_NONE
            line = l as i64
            have = true
        elif c == 47 or c == 63:
            self.eds[e].pos += 1
            let d = self.ed_read_delimited(e, c)
            let p = self.ed_pattern_from(e, d)
            if self.ed_stop(e):
                return ED_NONE
            let l = self.ed_find_line(e, p, c == 47)
            if self.ed_stop(e):
                return ED_NONE
            line = l as i64
            have = true
        # offsets: +n, -n, ^n; a bare +/- means 1, and with no base address
        # they are relative to the current line
        while true:
            let k = self.ed_peek(e)
            if k != 43 and k != 45 and k != 94:
                break
            self.eds[e].pos += 1
            if !have:
                line = self.eds[e].cur as i64
                have = true
            let mut n: i64 = 1 as i64
            if self.ed_peek(e) >= 48 and self.ed_peek(e) <= 57:
                n = self.ed_read_number(e)
            line = if k == 43: line + n else: line - n
        if !have:
            return ED_NONE
        if line < (0 as i64) or line > (self.eds[e].buf.len() as i64):
            self.ed_oops(e, "Line out of range.\n")
            return ED_NONE
        line as i32

    # The address list: how many addresses were given (0, 1 or 2), into
    # line1/line2. "," alone is 1,$ and ";" alone .,$; a missing first
    # address is 1 (",") or . (";"), a missing second one repeats the first;
    # ";" makes the first address current before the second is read. With
    # more than two, the last two count.
    fn ed_addresses(mut self, e: i32) -> i32:
        self.eds[e].line1 = self.eds[e].cur
        self.eds[e].line2 = self.eds[e].cur
        let mut a = self.ed_address(e)
        if self.ed_stop(e):
            return 0
        self.ed_skip_blanks(e)
        if self.ed_peek(e) != 44 and self.ed_peek(e) != 59:
            if a == ED_NONE:
                return 0
            self.eds[e].line1 = a
            self.eds[e].line2 = a
            return 1
        while self.ed_peek(e) == 44 or self.ed_peek(e) == 59:
            let sep = self.ed_peek(e)
            self.eds[e].pos += 1
            let had_first = a != ED_NONE
            if !had_first:
                a = if sep == 44: 1 else: self.eds[e].cur
            if sep == 59:
                self.eds[e].cur = a
            let mut b = self.ed_address(e)
            if self.ed_stop(e):
                return 0
            if b == ED_NONE:
                b = if had_first: a else: self.eds[e].buf.len()
            self.eds[e].line1 = a
            self.eds[e].line2 = b
            a = b
            self.ed_skip_blanks(e)
        2

    fn ed_need_range(mut self, e: i32, lo: i32):
        if self.eds[e].line1 > self.eds[e].line2:
            self.ed_oops(e, "Invalid range.\n")
            return
        if self.eds[e].line1 < lo or self.eds[e].line2 > self.eds[e].buf.len():
            self.ed_oops(e, "Line out of range.\n")

    # --- regular expressions (the regexp() efun's dialect, plus \< and \>) ------

    fn ed_pattern_from(mut self, e: i32, p: str) -> str:
        if p == "":
            if !self.eds[e].has_pattern:
                self.ed_oops(e, "No previous regular expression.\n")
                return ""
            return self.eds[e].last_pattern
        self.eds[e].last_pattern = p
        self.eds[e].has_pattern = true
        p

    # Compiles `p` into the session's `re`.
    fn ed_compile(mut self, e: i32, p: str):
        if self.eds[e].re_ok and self.eds[e].re_pat == p:
            return
        let r = rx::rx_compile_ed(rx::ed_pattern(p))
        if !r.ok:
            self.ed_oops(e, concat(concat("Bad regular expression: ", p), "\n"))
            return
        self.eds[e].re = r
        self.eds[e].re_pat = p
        self.eds[e].re_ok = true

    fn ed_matches(self, e: i32, line: str) -> bool:
        rx::rx_search(self.eds[e].re, bytes_from_str(line)).len() > 0

    # The next (or previous) line matching, wrapping round.
    fn ed_find_line(mut self, e: i32, p: str, forward: bool) -> i32:
        self.ed_compile(e, p)
        if self.ed_stop(e):
            return 0
        let n = self.eds[e].buf.len()
        let cur = self.eds[e].cur
        for i in 1..n + 1:
            let l = if forward: (cur + i - 1) % n + 1 else: (cur - i - 1 + 2 * n) % n + 1
            if self.ed_matches(e, self.eds[e].buf[l - 1]):
                return l
        self.ed_oops(e, "Pattern not found.\n")
        0

    # --- commands ---------------------------------------------------------------

    fn ed_rest(self, e: i32) -> str:
        sub_str(self.eds[e].s, self.eds[e].pos, self.eds[e].s.len())

    # The file name argument; "" if none.
    fn ed_file_arg(mut self, e: i32) -> str:
        let f = trim_ws(self.ed_rest(e))
        self.eds[e].pos = self.eds[e].s.len()
        f

    fn ed_no_more(mut self, e: i32):
        self.ed_skip_blanks(e)
        if self.eds[e].pos < self.eds[e].s.len():
            self.ed_oops(e, "Unexpected characters after the command.\n")

    # The trailing print suffix: p (1), l (2), n (4).
    fn ed_print_suffix(mut self, e: i32) -> i32:
        let mut flags = 0
        while true:
            let c = self.ed_peek(e)
            if c == 112:
                flags = flags | 1
            elif c == 108:
                flags = flags | 2
            elif c == 110:
                flags = flags | 4
            else:
                break
            self.eds[e].pos += 1
        self.ed_no_more(e)
        flags

    fn ed_print_range(mut self, e: i32, a: i32, b: i32, how: i32):
        for i in a..b + 1:
            let l = self.ed_format_line(e, i, how)
            self.ed_say(e, l)
        if b != 0:
            self.eds[e].cur = b

    fn ed_format_line(self, e: i32, i: i32, how: i32) -> str:
        let mut line = self.eds[e].buf[i - 1]
        let opts = self.eds[e].options
        if (how & 2) != 0 or (opts & OPT_LIST) != 0:
            let lb = bytes_from_str(line)
            let mut o = bf::Buf()
            for k in 0..lb.len():
                let c = lb[k] as i32
                if c == 92:
                    o.add_str("\\\\")
                elif c < 32:
                    o.byte(94)
                    o.byte(c + 64)
                elif c == 127:
                    o.add_str("^?")
                else:
                    o.byte(c)
            o.byte(36)
            line = o.to_str()
        if (how & 4) != 0 or (opts & OPT_NUMBER) != 0:
            line = concat(concat(pad4(i), "  "), line)
        concat(line, "\n")

    fn ed_after_suffix(mut self, e: i32, flags: i32):
        if flags != 0 and self.eds[e].cur != 0:
            let l = self.ed_format_line(e, self.eds[e].cur, flags)
            self.ed_say(e, l)

    fn ed_not_in_global(mut self, e: i32, in_global: bool) -> bool:
        if in_global:
            self.ed_oops(e, "That command cannot be used inside g or v.\n")
            return false
        true

    fn ed_not_restricted(mut self, e: i32) -> bool:
        if self.eds[e].restricted:
            self.ed_oops(e, "That command is not available here.\n")
            return false
        true

    # Runs one command line; `in_global` is set for the commands g/v run.
    fn ed_run(mut self, e: i32, line: str, in_global: bool, was_z: bool):
        self.eds[e].s = bytes_from_str(line)
        self.eds[e].pos = 0
        let naddr = self.ed_addresses(e)
        if self.ed_stop(e):
            return
        self.ed_skip_blanks(e)
        let c = self.ed_peek(e)
        if c != 0:
            self.eds[e].pos += 1
        let nbuf = self.eds[e].buf.len()
        if c == 0:
            if in_global:
                self.ed_no_more(e)
                return
            if naddr == 0:
                # an empty line shows the next line
                if self.eds[e].cur >= nbuf:
                    self.ed_oops(e, "End of file.\n")
                    return
                self.eds[e].line1 = self.eds[e].cur + 1
                self.eds[e].line2 = self.eds[e].cur + 1
            if self.eds[e].line2 == 0:
                self.ed_oops(e, "Line out of range.\n")
                return
            self.ed_print_range(e, self.eds[e].line2, self.eds[e].line2, 0)
            return
        if c == 97 or c == 111 or c == 105 or c == 79:
            # a o: append after the line; i O: insert before it
            self.ed_no_more(e)
            if self.ed_stop(e) or !self.ed_not_in_global(e, in_global):
                return
            let l2 = self.eds[e].line2
            if c == 97 or c == 111:
                self.ed_start_input(e, l2)
            else:
                self.ed_start_input(e, if l2 > 0: l2 - 1 else: 0)
            return
        if c == 99:
            # c
            self.ed_no_more(e)
            if self.ed_stop(e) or !self.ed_not_in_global(e, in_global):
                return
            self.ed_need_range(e, 1)
            if self.ed_stop(e):
                return
            let l1 = self.eds[e].line1
            self.ed_splice(e, l1, self.eds[e].line2 - l1 + 1, List<str>())
            self.ed_start_input(e, l1 - 1)
            return
        if c == 100:
            # d
            let flags = self.ed_print_suffix(e)
            if self.ed_stop(e):
                return
            self.ed_need_range(e, 1)
            if self.ed_stop(e):
                return
            let l1 = self.eds[e].line1
            self.ed_splice(e, l1, self.eds[e].line2 - l1 + 1, List<str>())
            let n = self.eds[e].buf.len()
            self.eds[e].cur = if l1 <= n: l1 else: n
            self.ed_after_suffix(e, flags)
            return
        if c == 112 or c == 108 or c == 110:
            # p l n
            if c == 110 and naddr == 0 and !in_global and trim_ws(self.ed_rest(e)) == "":
                # a bare "n" toggles line numbering (LPmud ed)
                self.eds[e].options = self.eds[e].options ^ OPT_NUMBER
                let on = if (self.eds[e].options & OPT_NUMBER) != 0: "on" else: "off"
                self.ed_say(e, f"Line numbers {on}.\n")
                return
            let base = if c == 108: 2 else: if c == 110: 4 else: 0
            let how = base | self.ed_print_suffix(e)
            if self.ed_stop(e):
                return
            if nbuf == 0:
                self.ed_oops(e, "The buffer is empty.\n")
                return
            self.ed_need_range(e, 1)
            if self.ed_stop(e):
                return
            self.ed_print_range(e, self.eds[e].line1, self.eds[e].line2, how)
            return
        if c == 61:
            # =
            self.ed_no_more(e)
            if self.ed_stop(e):
                return
            let n = if naddr != 0: self.eds[e].line2 else: self.eds[e].cur
            self.ed_say(e, f"{n}\n")
            return
        if c == 122 or c == 90:
            self.ed_z(e, c, naddr, was_z)
            return
        if c == 106:
            # j: default .,.+1; a single address joins nothing
            let flags = self.ed_print_suffix(e)
            if self.ed_stop(e):
                return
            if naddr == 0:
                self.eds[e].line2 = self.eds[e].cur + 1
            self.ed_need_range(e, 1)
            if self.ed_stop(e):
                return
            let l1 = self.eds[e].line1
            let l2 = self.eds[e].line2
            if l1 == l2:
                return
            let joined = str_join(slice_lines(self.eds[e].buf, l1 - 1, l2), "")
            self.ed_splice(e, l1, l2 - l1 + 1, [joined])
            self.eds[e].cur = l1
            self.ed_after_suffix(e, flags)
            return
        if c == 107:
            # kx
            let m = self.ed_peek(e)
            if m < 97 or m > 122:
                self.ed_oops(e, "Marks are named 'a to 'z.\n")
                return
            self.eds[e].pos += 1
            self.ed_no_more(e)
            if self.ed_stop(e):
                return
            if self.eds[e].line2 == 0:
                self.ed_oops(e, "Line out of range.\n")
                return
            self.eds[e].marks[m - 97] = self.eds[e].line2
            return
        if c == 109 or c == 116:
            self.ed_move_copy(e, c == 109)
            return
        if c == 115:
            self.ed_substitute(e, naddr, in_global)
            return
        if c == 103 or c == 118:
            # g v
            if in_global:
                self.ed_oops(e, "g and v cannot be nested.\n")
                return
            self.ed_run_global(e, naddr, c == 103)
            return
        if c == 117:
            # u
            self.ed_no_more(e)
            if self.ed_stop(e):
                return
            self.ed_undo(e)
            return
        if c == 101 or c == 69:
            self.ed_edit_file(e, c == 69, in_global)
            return
        if c == 102:
            # f
            if !self.ed_not_restricted(e):
                return
            let f = self.ed_file_arg(e)
            if f != "":
                let name = self.ed_resolve(self.eds[e].owner, f)
                self.eds[e].filename = name
            let fname = self.eds[e].filename
            self.ed_say(e, concat(if fname != "": fname else: "No file name.", "\n"))
            return
        if c == 114:
            self.ed_read_in(e, naddr, in_global)
            return
        if c == 119 or c == 87:
            # w W wq
            if !self.ed_not_in_global(e, in_global):
                return
            let mut then_quit = false
            if c == 119 and self.ed_peek(e) == 113:
                self.eds[e].pos += 1
                then_quit = true
            let f = self.ed_file_arg(e)
            if f != "" and !self.ed_not_restricted(e):
                return
            let mut a = 1
            let mut b = nbuf
            if naddr != 0:
                self.ed_need_range(e, 1)
                if self.ed_stop(e):
                    return
                a = self.eds[e].line1
                b = self.eds[e].line2
            self.ed_write_out(e, f, a, b, c == 87)
            if self.ed_stop(e):
                return
            if then_quit:
                self.ed_finish(e)
            return
        if c == 120:
            # x
            if !self.ed_not_in_global(e, in_global):
                return
            let f = self.ed_file_arg(e)
            if f != "" and !self.ed_not_restricted(e):
                return
            if self.eds[e].dirty or f != "":
                self.ed_write_out(e, f, 1, nbuf, false)
                if self.ed_stop(e):
                    return
            self.ed_finish(e)
            return
        if c == 113 or c == 81:
            # q Q
            if !self.ed_not_in_global(e, in_global):
                return
            self.ed_no_more(e)
            if self.ed_stop(e):
                return
            if c == 113 and self.eds[e].dirty:
                self.ed_oops(e, "The buffer has unsaved changes: x saves them and exits, Q discards them.\n")
                return
            self.ed_finish(e)
            return
        if c == 104:
            # h
            self.ed_help(e, trim_ws(self.ed_rest(e)))
            return
        if c == 33:
            self.ed_oops(e, "Mud commands are typed with ! at the start of the line.\n")
            return
        self.ed_oops(e, "Unknown command.\n")

    # z / Z [.+-][count]: a page of lines
    fn ed_z(mut self, e: i32, c: i32, naddr: i32, was_z: bool):
        let size = if c == 122: Z_LINES else: BIG_Z_LINES
        let mut how = self.ed_peek(e)
        if how == 46 or how == 43 or how == 45:
            self.eds[e].pos += 1
        else:
            how = 43
        let mut n: i64 = size as i64
        if self.ed_peek(e) >= 48 and self.ed_peek(e) <= 57:
            n = self.ed_read_number(e)
        self.ed_print_suffix(e)
        if self.ed_stop(e):
            return
        let nbuf = self.eds[e].buf.len() as i64
        if nbuf == (0 as i64):
            self.ed_oops(e, "The buffer is empty.\n")
            return
        let mut at = self.eds[e].line2 as i64
        if naddr == 0 and was_z and how == 43:
            at = (self.eds[e].cur + 1) as i64
        if at < (1 as i64):
            at = 1 as i64
        if at > nbuf:
            self.ed_oops(e, "End of file.\n")
            return
        let mut a = at
        let mut b = at
        let one = 1 as i64
        if how == 45:
            b = at
            a = max64(one, at - n + one)
        elif how == 46:
            a = max64(one, at - n / (2 as i64))
            b = min64(nbuf, a + n - one)
        else:
            b = min64(nbuf, at + n - one)
        self.ed_print_range(e, a as i32, b as i32, 0)
        self.eds[e].last_was_z = true

    # m / t: move or copy the range after a line
    fn ed_move_copy(mut self, e: i32, is_move: bool):
        self.ed_need_range(e, 1)
        if self.ed_stop(e):
            return
        let a = self.eds[e].line1
        let b = self.eds[e].line2
        let mut dest = self.ed_address(e)
        if self.ed_stop(e):
            return
        if dest == ED_NONE:
            dest = self.eds[e].cur
        let flags = self.ed_print_suffix(e)
        if self.ed_stop(e):
            return
        let chunk = slice_lines(self.eds[e].buf, a - 1, b)
        if is_move:
            if dest >= a - 1 and dest <= b:
                if dest >= a and dest < b:
                    self.ed_oops(e, "Cannot move lines into themselves.\n")
                    return
                # moving to where they already are
                self.eds[e].cur = b
                self.ed_after_suffix(e, flags)
                return
            self.ed_splice(e, a, b - a + 1, List<str>())
            if dest > b:
                dest -= b - a + 1
        self.ed_splice(e, dest + 1, 0, chunk)
        self.eds[e].cur = dest + chunk.len()
        self.ed_after_suffix(e, flags)

    # e / E [file]
    fn ed_edit_file(mut self, e: i32, discard: bool, in_global: bool):
        if !self.ed_not_in_global(e, in_global) or !self.ed_not_restricted(e):
            return
        let f = self.ed_file_arg(e)
        if !discard and self.eds[e].dirty:
            self.ed_oops(e, "The buffer has unsaved changes; use E to discard them.\n")
            return
        let ob = self.eds[e].owner
        let path = if f != "": self.ed_resolve(ob, f) else: self.eds[e].filename
        if path == "":
            self.ed_oops(e, "No file name.\n")
            return
        let t = self.ed_read(ob, path)
        if self.err:
            return
        if t.kind == -1:
            self.ed_oops(e, f"\"{path}\": permission denied.\n")
            return
        if t.kind == -2:
            self.ed_oops(e, f"\"{path}\" is a directory.\n")
            return
        self.ed_about_to_change(e)
        self.eds[e].buf = if t.kind == 1: ed_split(t.text) else: List<str>()
        self.eds[e].marks = no_marks()
        let n = self.eds[e].buf.len()
        self.eds[e].cur = if n > 0: 1 else: 0
        self.eds[e].dirty = false
        self.eds[e].filename = path
        if t.kind == 1:
            self.ed_say(e, f"\"{path}\" {n} lines, {len(t.text)} bytes\n")
        else:
            self.ed_say(e, f"\"{path}\": new file.\n")

    # [line]r [file]
    fn ed_read_in(mut self, e: i32, naddr: i32, in_global: bool):
        if !self.ed_not_in_global(e, in_global) or !self.ed_not_restricted(e):
            return
        let f = self.ed_file_arg(e)
        let ob = self.eds[e].owner
        let path = if f != "": self.ed_resolve(ob, f) else: self.eds[e].filename
        if path == "":
            self.ed_oops(e, "No file name.\n")
            return
        let t = self.ed_read(ob, path)
        if self.err:
            return
        if t.kind != 1:
            let why = if t.kind == -1: "permission denied" else: if t.kind == -2: "is a directory" else: "no such file"
            self.ed_oops(e, f"\"{path}\": {why}.\n")
            return
        let lines = ed_split(t.text)
        let after = if naddr != 0: self.eds[e].line2 else: self.eds[e].buf.len()
        self.ed_splice(e, after + 1, 0, lines)
        self.eds[e].cur = after + lines.len()
        self.ed_say(e, f"{lines.len()} lines, {len(t.text)} bytes\n")

    fn ed_finish(mut self, e: i32):
        self.eds[e].finished = true
        self.ed_say(e, "Exit from the editor.\n")

    fn ed_write_out(mut self, e: i32, f: str, a: i32, b: i32, append: bool):
        let ob = self.eds[e].owner
        let path = if f != "": self.ed_resolve(ob, f) else: self.eds[e].filename
        if path == "":
            self.ed_oops(e, "No file name; use w <file>.\n")
            return
        let data = if a <= b and b != 0: concat(str_join(slice_lines(self.eds[e].buf, a - 1, b), "\n"), "\n") else: ""
        let ok = self.ed_write(ob, path, data, append)
        if self.err:
            return
        if !ok:
            self.ed_oops(e, f"\"{path}\" could not be written.\n")
            return
        if self.eds[e].filename == "":
            self.eds[e].filename = path
        if path == self.eds[e].filename and !append and a == 1 and b == self.eds[e].buf.len():
            self.eds[e].dirty = false
        if !self.eds[e].restricted:
            let n = if b - a + 1 > 0: b - a + 1 else: 0
            let nb = len(data)
            let tail = if append: " appended" else: ""
            self.ed_say(e, f"\"{path}\" {n} line{plural_s(b - a + 1)}, {nb} byte{plural_s(nb)}{tail}\n")

    # s/re/replacement/[g][N][p|l|n]
    fn ed_substitute(mut self, e: i32, naddr: i32, in_global: bool):
        # "set" arrives here as 's' followed by "et"
        let r = bytes_from_str(self.ed_rest(e))
        if r.len() >= 2 and (r[0] as i32) == 101 and (r[1] as i32) == 116 and (r.len() == 2 or (r[2] as i32) == 32):
            self.eds[e].pos += 2
            self.ed_set_command(e, trim_ws(self.ed_rest(e)))
            return
        let delim = self.ed_peek(e)
        if delim == 0 or delim == 32 or delim == 92 or delim == 10:
            self.ed_oops(e, "Usage: s/pattern/replacement/[g][p]\n")
            return
        self.eds[e].pos += 1
        let d = self.ed_read_delimited(e, delim)
        let pat = self.ed_pattern_from(e, d)
        if self.ed_stop(e):
            return
        let mut rep = self.ed_read_replacement(e, delim)
        if rep == "%":
            if !self.eds[e].has_replacement:
                self.ed_oops(e, "No previous replacement.\n")
                return
            rep = self.eds[e].last_replacement
        self.eds[e].last_replacement = rep
        self.eds[e].has_replacement = true
        let mut all = false
        let mut nth: i64 = 1 as i64
        while true:
            let c = self.ed_peek(e)
            if c == 103:
                all = true
                self.eds[e].pos += 1
            elif c >= 49 and c <= 57:
                nth = self.ed_read_number(e)
            else:
                break
        let flags = self.ed_print_suffix(e)
        if self.ed_stop(e):
            return
        self.ed_need_range(e, 1)
        if self.ed_stop(e):
            return
        if self.eds[e].buf.len() == 0:
            self.ed_oops(e, "The buffer is empty.\n")
            return
        self.ed_compile(e, pat)
        if self.ed_stop(e):
            return
        let rb = bytes_from_str(rep)
        let mut last = 0
        let mut l = self.eds[e].line1
        while l <= self.eds[e].line2:
            let res = self.ed_subst_line(e, self.eds[e].buf[l - 1], rb, all, nth)
            if res.len() == 0:
                l += 1
                continue
            let parts = str_split(res[0], "\n")
            if parts.len() == 1:
                self.ed_about_to_change(e)
                self.eds[e].buf[l - 1] = res[0]
                self.eds[e].dirty = true
            else:
                self.ed_splice(e, l, 1, parts)
                self.eds[e].line2 += parts.len() - 1
                l += parts.len() - 1
            last = l
            l += 1
        if last == 0:
            if in_global:
                return
            self.ed_oops(e, "No match.\n")
            return
        self.eds[e].cur = last
        self.ed_after_suffix(e, flags)

    # The replacement text up to the closing delimiter, escapes kept.
    fn ed_read_replacement(mut self, e: i32, delim: i32) -> str:
        let s = self.eds[e].s
        let mut o = bf::Buf()
        let mut p = self.eds[e].pos
        while p < s.len():
            let c = s[p] as i32
            p += 1
            if c == delim:
                self.eds[e].pos = p
                return o.to_str()
            if c == 92 and p < s.len():
                o.byte(92)
                o.byte(s[p] as i32)
                p += 1
                continue
            o.byte(c)
        self.eds[e].pos = p
        o.to_str()

    # The line with the substitution made ([text]), or [] if nothing matched
    # (ed.pike subst_line()).
    fn ed_subst_line(self, e: i32, line_s: str, rep: Bytes, all: bool, nth: i64) -> List<str>:
        let line = bytes_from_str(line_s)
        let n = line.len()
        let mut o = bf::Buf()
        let mut p = 0
        let mut count: i64 = 0 as i64
        let mut done = false
        while p <= n:
            let m = rx::rx_exec(self.eds[e].re, line, p)
            if m.len() == 0:
                break
            let s0 = m[0]
            let e0 = m[1]
            count += 1 as i64
            for k in p..s0:
                o.byte(line[k] as i32)
            if count >= nth:
                o.add(ed_expand(rep, m, line))
                done = true
            else:
                for k in s0..e0:
                    o.byte(line[k] as i32)
            if e0 == s0:
                if s0 < n:
                    o.byte(line[s0] as i32)
                p = s0 + 1
            else:
                p = e0
            if done and !all:
                break
        if !done:
            return List<str>()
        for k in p..n:
            o.byte(line[k] as i32)
        [o.to_str()]

    # [range]g/re/command, [range]v/re/command
    fn ed_run_global(mut self, e: i32, naddr: i32, want: bool):
        if naddr == 0:
            self.eds[e].line1 = 1
            self.eds[e].line2 = self.eds[e].buf.len()
        if self.eds[e].buf.len() == 0:
            self.ed_oops(e, "The buffer is empty.\n")
            return
        self.ed_need_range(e, 1)
        if self.ed_stop(e):
            return
        let delim = self.ed_peek(e)
        if delim == 0 or delim == 32 or delim == 92:
            self.ed_oops(e, "Usage: g/pattern/command\n")
            return
        self.eds[e].pos += 1
        let d = self.ed_read_delimited(e, delim)
        let pat = self.ed_pattern_from(e, d)
        if self.ed_stop(e):
            return
        self.ed_compile(e, pat)
        if self.ed_stop(e):
            return
        let mut cmd = self.ed_rest(e)
        if trim_ws(cmd) == "":
            cmd = "p"
        let mut fl: List<bool> = List<bool>()
        for k in 0..self.eds[e].buf.len():
            fl.push(false)
        for l in self.eds[e].line1..self.eds[e].line2 + 1:
            if self.ed_matches(e, self.eds[e].buf[l - 1]) == want:
                fl[l - 1] = true
        self.eds[e].gflags = fl
        self.eds[e].gon = true
        while true:
            let mut i = -1
            let g = self.eds[e].gflags
            for k in 0..g.len():
                if g[k]:
                    i = k
                    break
            if i < 0:
                break
            self.eds[e].gflags[i] = false
            self.eds[e].cur = i + 1
            self.ed_run(e, cmd, true, false)
            if self.ed_stop(e):
                break
        self.eds[e].gflags = List<bool>()
        self.eds[e].gon = false

    # --- options and help -------------------------------------------------------

    fn ed_set_command(mut self, e: i32, arg: str):
        let opts = self.eds[e].options
        if arg == "":
            let l = if (opts & OPT_LIST) != 0: "on" else: "off"
            let n = if (opts & OPT_NUMBER) != 0: "on" else: "off"
            self.ed_say(e, f"list:{l} number:{n}\n")
            return
        if arg == "save":
            if !self.ed_save_setup(self.eds[e].owner, opts):
                if self.err:
                    return
                self.ed_oops(e, "Could not save the settings.\n")
                return
            self.ed_say(e, "Settings saved.\n")
            return
        let off = str_starts_with(arg, "no")
        let name = if off: sub_str(bytes_from_str(arg), 2, len(arg)) else: arg
        let bit = if name == "number": OPT_NUMBER else: if name == "list": OPT_LIST else: 0
        if bit == 0:
            self.ed_oops(e, "Options: number, list (prefix with no to turn off); set save keeps them.\n")
            return
        if off:
            self.eds[e].options = opts & (OPT_NUMBER | OPT_LIST) & (3 - bit)
        else:
            self.eds[e].options = opts | bit

    fn ed_help(mut self, e: i32, topic: str):
        let help = ed_help_lines()
        if topic != "":
            let mut hits: List<str> = List<str>()
            for i in 0..help.len():
                let t = trim_ws(help[i])
                if str_starts_with(t, topic) or str_starts_with(t, concat("[range]", topic)) or str_starts_with(t, concat("[line]", topic)):
                    hits.push(t)
            if hits.len() == 0:
                self.ed_oops(e, concat(concat("No help on ", topic), ".\n"))
                return
            self.ed_say(e, concat(str_join(hits, "\n"), "\n"))
            return
        self.eds[e].help_pages = help
        self.eds[e].in_help = true
        self.ed_next_help_page(e)

    fn ed_next_help_page(mut self, e: i32):
        let pages = self.eds[e].help_pages
        let page = slice_lines(pages, 0, HELP_PAGE)
        let rest = slice_lines(pages, HELP_PAGE, pages.len())
        self.eds[e].help_pages = rest
        self.ed_say(e, concat(str_join(page, "\n"), "\n"))
        if rest.len() > 0:
            self.ed_say(e, "-- RETURN for more, or type a command --\n")
        else:
            self.eds[e].in_help = false

    # --- the efuns --------------------------------------------------------------

    # efun_table.star codes 370-379
    fn efun_ed(mut self, code: i32, args: List<val::Value>, self_ob: i32) -> val::Value:
        if code == et::E_ED_START:
            return self.efun_ed_start(args, self_ob)
        if code == et::E_ED_CMD:
            return self.efun_ed_cmd(args, self_ob)
        if code == et::E_IN_EDIT:
            return self.efun_in_edit(args, self_ob)
        self.efun_query_ed_mode(self_ob)

    # ed_start([file], [restricted]): the opening messages
    fn efun_ed_start(mut self, args: List<val::Value>, self_ob: i32) -> val::Value:
        let mut has_file = false
        let mut file = ""
        if args.len() >= 1:
            match args[0]:
                val::Value::Str(s) ->
                    has_file = true
                    file = s
                _ ->
                    self.fail("Bad argument 1 to ed_start()\n")
                    return val::Value::Undef
        if !self.alive(self_ob):
            return val::Value::Int(0 as i64)
        if self.ed_of(self_ob) >= 0:
            self.fail("ed_start(): this object is already editing a file.\n")
            return val::Value::Undef
        let restricted = args.len() >= 2 and self.truthy(args[1])
        let e = self.ed_new(self_ob)
        self.eds[e].running = true
        self.ed_open(e, self_ob, has_file, file, restricted)
        self.eds[e].running = false
        if self.err or !self.alive(self_ob) or !self.eds[e].alive:
            self.ed_drop(e)
            return val::Value::Undef
        self.objs[self_ob].ed = e
        val::Value::Str(self.ed_take(e))

    # ed_cmd(cmd): the command's output; 0 with no session (the reference's
    # deliberate difference: Dead Souls quits an editing player with
    # ed_cmd("."), ed_cmd("x"), ed_cmd("Q"), and once "x" has closed the
    # session FluffOS's error from "Q" aborted the quit)
    fn efun_ed_cmd(mut self, args: List<val::Value>, self_ob: i32) -> val::Value:
        let cmd = match self.arg(args, 0):
            val::Value::Str(s) -> s
            _ ->
                self.fail("Bad argument 1 to ed_cmd()\n")
                return val::Value::Undef
        let e = self.ed_of(self_ob)
        if e < 0:
            return val::Value::Int(0 as i64)
        self.eds[e].running = true
        let r = self.ed_command(e, cmd)
        self.eds[e].running = false
        if !self.eds[e].alive:
            # destructed meanwhile: the session already ended
            self.ed_drop(e)
        elif self.eds[e].finished and self.alive(self_ob) and self.objs[self_ob].ed == e:
            self.objs[self_ob].ed = -1
            self.ed_drop(e)
        if self.err:
            return val::Value::Undef
        val::Value::Str(r)

    fn efun_query_ed_mode(self, self_ob: i32) -> val::Value:
        let e = self.ed_of(self_ob)
        if e < 0:
            return val::Value::Int(MODE_NONE as i64)
        val::Value::Int(self.ed_mode(e) as i64)

    # in_edit([ob]): the file being edited ("" for a nameless buffer), else 0
    fn efun_in_edit(self, args: List<val::Value>, self_ob: i32) -> val::Value:
        let ob = if args.len() < 1: self_ob else: self.obj_of(args[0])
        let e = self.ed_of(ob)
        if e < 0:
            return val::Value::Int(0 as i64)
        val::Value::Str(self.eds[e].filename)

    # Destructing an editing object (objects.star destruct_object()) ends its
    # session; unsaved changes go to the file the master's
    # get_save_file_name(file, who) names (efuns.pike ed_rescue()), with the
    # editor as this_player() meanwhile (Dead Souls asks this_player(1)).
    # Everything here runs under the reference's catch.
    fn ed_destructed(mut self, ob: i32):
        let e = self.ed_of(ob)
        if e < 0:
            return
        self.objs[ob].ed = -1
        if self.eds[e].dirty and !self.eds[e].finished and self.eds[e].buf.len() > 0:
            let tp = self.cur_player
            let ti = self.cur_interactive
            self.cur_player = ob
            self.cur_interactive = ob
            let path = self.ed_master_try("get_save_file_name", [val::Value::Str(self.eds[e].filename), self.obj_value(ob)], ob)
            self.cur_player = tp
            self.cur_interactive = ti
            match path:
                val::Value::Str(p) ->
                    if p != "":
                        self.write_whole(self.mud_real(p), self.ed_text(e), false)
                _ -> 0
        self.ed_drop(e)
