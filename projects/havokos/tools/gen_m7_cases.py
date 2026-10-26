"""Generates tests/fixtures/cases/m7_cases.txt (todo.md HavokOS M7, `ed`).

The M7 cases drive the line editor through its efuns (ed_start(), ed_cmd(),
query_ed_mode(), in_edit()) on the test minilib, whose master answers the
editor's applies (make_path_absolute() puts relative names under /test/,
retrieve_ed_setup()/save_ed_setup() keep the option word, and
get_save_file_name() rescues a lost buffer to /test/ed_dead.edit). They are
written here as readable LPC and flattened to the case file's one-line,
escaped form; the expected results (m7_extra.expected.txt) are whatever the
live reference returns for them (tools/ref_cases.pike -extra), never
hand-predicted.

Two kinds of case:
- the reference's own ed_tests() (pike/tests/run_tests.pike), bodies
  verbatim, so their expected column can be checked against the fixture;
- this port's edge cases, one command family each, mostly built by sess():
  a session's opening output, then one element per command.

Usage: python tools/gen_m7_cases.py > tests/fixtures/cases/m7_cases.txt
"""

def lpc_str(src):
    """An LPC string literal holding src."""
    return '"' + src.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'

CASES = []

def case(name, body, globals_=""):
    CASES.append((name, (globals_ + " @@ " if globals_ else "") + body))

# Ends whatever session this object still has: input mode needs a ".", and
# "Q" leaves the help and exits without saving.
CLOSE = 'while (query_ed_mode() != -1) ed_cmd(query_ed_mode() > 0 ? "." : "Q");'

def sess(name, start, cmds, pre="", post="", globals_=""):
    """A case running one session: ed_start(<start>)'s output, then each
    command's -- a str is an ed command, "@expr" an LPC expression."""
    parts = [pre, "mixed *r = ({ ed_start(%s) });" % start]
    for c in cmds:
        parts.append("r += ({ %s });" % (c[1:] if c.startswith("@") else "ed_cmd(%s)" % lpc_str(c)))
    parts += [CLOSE, post, "return r;"]
    case(name, " ".join(p for p in parts if p), globals_)

MODE = "@query_ed_mode()"
A = "/test/tmp_m7_a.txt"
B = "/test/tmp_m7_b.txt"
C = "/test/tmp_m7_c.txt"
FIVE = "alpha\nbeta\ngamma\ndelta\nepsilon\n"

def wr(path, text):
    return "write_file(%s, %s, 1);" % (lpc_str(path), lpc_str(text))

RM = " ".join('rm("%s");' % p for p in (A, B, C, "/test/tmp_m7_none.txt", "/test/ed_dead.edit"))

# --- the reference's ed_tests(), verbatim
case("ed session: insert, substitute, save and exit",
     r'''rm("/test/ed_a.txt"); write_file("/test/ed_a.txt", "one\ntwo\nthree\n"); ed_start("/test/ed_a.txt"); mixed *r = ({ query_ed_mode(), in_edit(), ed_cmd("2"), ed_cmd("a"), query_ed_mode(), ed_cmd("new"), query_ed_mode(), ed_cmd("."), query_ed_mode(), ed_cmd("1,$s/e/E/g"), ed_cmd("x"), query_ed_mode(), in_edit(), read_file("/test/ed_a.txt") }); rm("/test/ed_a.txt"); return r;''')
case("ed restricted mode and relative names",
     r'''rm("/test/ed_b.txt"); ed_start("ed_b.txt", 1); mixed *r = ({ in_edit(), ed_cmd("$a"), query_ed_mode(), ed_cmd("hello"), ed_cmd("."), ed_cmd("w /test/ed_c.txt"), ed_cmd("f"), ed_cmd("x"), query_ed_mode(), read_file("/test/ed_b.txt"), file_size("/test/ed_c.txt") }); rm("/test/ed_b.txt"); return r;''')
case("ed q refuses unsaved changes; failed writes keep the session",
     r'''ed_start("/secret/x.txt"); mixed *r = ({ in_edit(), ed_cmd("a"), ed_cmd("x"), ed_cmd("."), ed_cmd("q"), query_ed_mode(), ed_cmd("w /secret/y.txt"), ed_cmd("x"), query_ed_mode(), ed_cmd("Q"), query_ed_mode() }); return r;''')
case("ed one session per object",
     r'''mixed e1 = ed_cmd("p"); ed_start(); mixed e2 = catch(ed_start()); string q = ed_cmd("Q"); return ({ e1, stringp(e2), q, query_ed_mode(), ed_cmd("Q") });''')
case("ed help paging and saved settings",
     r'''ed_start(); mixed *r = ({ sizeof(ed_cmd("h")) > 0, query_ed_mode(), sizeof(ed_cmd("")) > 0, query_ed_mode(), ed_cmd("set number"), ed_cmd("set save"), ed_cmd("Q") }); ed_start(); r += ({ ed_cmd("set") }); ed_cmd("set nonumber"); ed_cmd("set save"); ed_cmd("Q"); return r;''')
case("ed regexp dialect, g and undo",
     r'''ed_start(); ed_cmd("a"); ed_cmd("a(b)c ab"); ed_cmd("."); mixed *r = ({ ed_cmd("s/(b)/<\\1>/gp"), ed_cmd("s/\\(/[/p"), ed_cmd("g/</s/a|c/_/gp"), ed_cmd("u"), ed_cmd("p"), ed_cmd("/nothing/") }); ed_cmd("Q"); return r;''')
case("ed buffer rescued when the editor is destructed",
     r'''rm("/test/ed_dead.edit"); object u = clone_object("/test/ed_user"); u->start("/test/ed_r.txt"); u->cmd("a"); u->cmd("lost line"); object v = clone_object("/test/ed_user"); v->start("/test/ed_s.txt"); destruct(u); destruct(v); string r = read_file("/test/ed_dead.edit"); rm("/test/ed_dead.edit"); return ({ r, master()->query_ed_rescued_for() });''')

# --- this port's edge cases
case("m7 setup helpers",
     wr("/test/tmp_m7_ed.c", 'void go() { ed_start(); }\nstring c(string s) { return ed_cmd(s); }\nint mode() { return query_ed_mode(); }\n') + " return 1;")

# opening a file: the messages for each kind of file, then in_edit()/mode
case("ed opening messages",
     wr(A, "x\n") + " " + wr(B, "") + " " + wr(C, "a\r\nb\r\nlast") + '''
mixed *r = ({});
foreach (string f in ({ "%s", "%s", "%s", "tmp_m7_a.txt", "/test/tmp_m7_none.txt", "/test", "/secret/z.txt", "", "/test/../test/./tmp_m7_a.txt" })) {
    r += ({ ed_start(f), in_edit(), query_ed_mode() });
    r += ({ ed_cmd(",p"), ed_cmd("=") });
    %s
}
r += ({ ed_start(), in_edit(), query_ed_mode(), ed_cmd("f") });
%s
%s
return r;''' % (A, B, C, CLOSE, CLOSE, RM))

sess("ed addresses", lpc_str(A), [
    "p", "$p", "2,4p", ",p", ";p", "3;+1p", "+p", "++p", "-p", "--p", "$-2p", "4^p", "^p",
    "2", "0", "6p", "0p", "4,2p", "1,2,3p", "2 , 3 p", "  4p", ",", "1,", ",3p",
    "/ta/p", "?al?p", "//p", "??p", "/zz/", "/a/+1p",
    "1", "", "", "$", "", "=", "$=", "2=", ".=",
    "'ap", "'Ap", "3ka", "'ap", "'a,$p", "'a-1p",
    "99999999999999999999999p", "1,99999999999999999999p", "1+99999999999999999999-99999999999999999999p",
], pre=wr(A, FIVE), post=RM)

sess("ed print forms and options", lpc_str(A), [
    "p", "l", "n", "pn", "pl", "ln", "nl", "1n", "n", MODE, "p", "n", "p",
    "set", "set list", "set", "p", "2p", "set nolist", "set number", "set", "p", "set nonumber",
    "set bogus", "set nobogus", "set  list", "set nolist", "setx", "se",
    "p\r",
], pre=r'write_file("%s", "a\tb\\c" + sprintf("%%c", 1) + "d" + sprintf("%%c", 127) + "e~\nsecond\n", 1);' % A, post=RM)

sess("ed input modes", "", [
    "a", MODE, "one", MODE, "two", MODE, ".", MODE, ",p", "=",
    "1i", MODE, "zero", ".", ",p", "=",
    "0a", "first", ".", "0i", "very first", ".", ",n",
    "2c", "TWO", "TWO.5", ".", ",p", "=",
    "$o", "after", ".", "1O", "before", ".", ",p",
    "a", "Q", "x\r", ".", ",p", "u", ",p", "u", ",p",
    "a x", "ax", "c", ".", "=", ",p",
])

sess("ed input into an empty buffer", "", [
    "p", "c", "i", MODE, "only", ".", "p", "1c", ".", ",p", "=", MODE, "c",
])

sess("ed delete and join", lpc_str(A), [
    "2d", "p", "=", "2,3dp", ",p", "$d", "=", "u", ",p",
    "1,2j", ",p", "j", ",p", "1j", "jp", "$j", "1,$jn", "=",
    ",d", "p", "d", "=", "j", "u", ",p",
    "2dx", "dpl", ",p",
], pre=wr(A, FIVE), post=RM)

sess("ed marks follow edits", lpc_str(A), [
    "3ka", "1d", "'ap", "'ad", "'ap",
    "2kb", "1i", "new", ".", "'bp", "'b=",
    "4kc", "4c", "X", ".", "'cp", "u", "'cp",
    "1ka", "2,3m$", "'ap", "$ka", "1t0", "'ap",
    "kA", "k", "ka x", "0ka",
], pre=wr(A, FIVE), post=RM)

sess("ed move and copy", lpc_str(A), [
    "1m$", ",p", "=", "u", ",p",
    "2,3m0", ",p", "=", "u",
    "2m2", "=", "2m1", "=", "1,3m2", "1,3m1", ",p",
    "1,2t$", ",p", "=", "u",
    "1t0", ",p", "=", "u",
    "3", "2,3t", ",p", "u",
    "1,2m$p", "4,5m0 n", "1m 9", "1m'z", "1mx",
], pre=wr(A, FIVE), post=RM)

sess("ed substitute", lpc_str(A), [
    "1s/at/AT/p", "u", "1s/at/AT/gp", "u",
    "1s/at/[&]/2p", "u", "1s/at/<&>/3gp", "u", "1s/at/<&>/g2p", "u",
    r"1s/(c)(a)t/\2\1-\0-\3/p", "u", r"1s/(x)?the/[\1]/p", "u",
    r"2s/\./-/gp", "u", "2s/./-/gp", "u", "2s/x*/-/gp", "u", "2s/$/!/p", "u", "2s/^/>/gp", "u",
    r"3s/y/\n/p", ",p", "=", "u",
    r"1,2s/a/(\n)/", ",p", "=", "u",
    "1s/cat/dog/", "s/dog/%/p", "1s/sat/%/p", "u", "u", "u",
    "1s//X/p", "u", "s|a|b|p", "u", r"2s/\./\//gp", "u", r"2s/b/\&\t\\/p", "u",
    r"1s/\<s/S/gp", "u", r"1s/t\>/T/gp", "u", r"1s/\<[a-z]/_/gp", "u",
    "1s/[aeiou]/_/g3p", "u", "1s/a/A/0p", "1s/a/b/x",
    "s", "s ", "s\\a\\b\\", "s/q/r/", "s/(/x/", "s/a", "1s/e/E",
    "1,$s/a/A/gp", "=", ",p", "u",
    "s/%/x/", "5s/xyz/abc/p",
], pre=wr(A, "the cat sat on the mat\na.b.c\nxyz\n"), post=RM)

sess("ed substitute needs a previous pattern and replacement", "", [
    "a", "abc", ".", "s//x/", "s/b/%/", "/b/", "s//[&]/p", "s/c/%/p",
])

sess("ed global commands", lpc_str(A), [
    "g/a/p", "g/e/", "g/l/ ", "v/a/p", "v/./p", "g/zz/p", "g/a/=", "2,3g/./p", "g//n",
    "g/l/d", ",p", "=", "u", ",p",
    "g/a/s/a/A/gp", "u", "g/t/s/ph/PH/p", "u",
    "g/a/m0", ",p", "u",
    r"g/a/s/a/\n/", ",p", "=", "u",
    "g/^[ab]/j", ",p", "u",
    "g/a/g/b/p", "g/a/v/b/p", "g/a/a", "g/a/i", "g/a/c", "g/a/w", "g/a/q", "g/a/x", "g/a/e", "g/a/r", "g/a/zz",
    "g", "g ", "g\\a\\p", "g/(/p", r"g/\<d/p", "g/a/u", ",p",
], pre=wr(A, FIVE), post=RM)

sess("ed global on an empty buffer", "", ["g/a/p", "v/a/p", "1,2g/a/p"])

sess("ed undo", lpc_str(A), [
    "u", "1d", "u", "p", "u", "p", "q", "u", MODE,
    "1,2d", "3a", "x", "y", ".", "u", ",p", "u", ",p", "w", "u", "q",
], pre=wr(A, FIVE), post=RM)

case("ed z paging",
     'string t = ""; for (int i = 1; i <= 50; i++) t += i + "\\n"; write_file("%s", t, 1); ' % A +
     "mixed *r = ({ ed_start(%s) });" % lpc_str(A) +
     " ".join("r += ({ ed_cmd(%s) });" % lpc_str(c) for c in [
         "z", "z", "z", "z", "1z5", "z", "=", "10z-3", "=", "25z.4", "=", "26z.5", "1z.", "Z", "=", "Z",
         "z.", "5z-", "zp", "3z0", "=", "$z", "z", "2", "z", "40Z", "1z3n", "1zx", "z99999999999999999999",
         "", "0z2"]) + " " + CLOSE +
     ' ed_start(); r += ({ ed_cmd("z"), ed_cmd("Z") }); ' + CLOSE + " " + RM + " return r;")

sess("ed files: e, E, r, f", lpc_str(A), [
    "f", "1d", "e %s" % B, "E tmp_m7_b.txt", ",p", "f", "=",
    "r tmp_m7_a.txt", "=", "0r tmp_m7_b.txt", ",n", "1r", "=",
    "r /secret/q", "r /test", "r /test/tmp_m7_none.txt",
    "e", "E", "f", ",p", "f %s" % A, "f", "e", "E /secret/q", "E /test", "f",
    "E /test/tmp_m7_none.txt", "f", ",p", "=", "e tmp_m7_a.txt", "=", "p",
    "f  tmp_m7_b.txt  ", "f",
], pre=wr(A, FIVE) + " " + wr(B, "one\ntwo\n"), post=RM)

sess("ed files: w, W, wq, x", lpc_str(A), [
    "w %s" % C, "@read_file(%s)" % lpc_str(C), "1,2W %s" % C, "@read_file(%s)" % lpc_str(C),
    "2,1w %s" % C, "0w %s" % C, "$W %s" % C, "@read_file(%s)" % lpc_str(C),
    "1d", "q", "w %s" % C, "q", "e", "w", "q", "E",
    "W /secret/q", "w /secret/q", "w /test", "2w", "@read_file(%s)" % lpc_str(A), "q", "w",
    "1,$d", "w", "@read_file(%s)" % lpc_str(A), "@file_size(%s)" % lpc_str(A),
    "a", "back", ".", "wq", MODE, "@read_file(%s)" % lpc_str(A),
], pre=wr(A, FIVE), post=RM)

sess("ed files: x and nameless buffers", "", [
    "f", "w", "x", "e", "r", "a", "text", ".", "x", "q", "W", "w tmp_m7_c.txt", "f", "x", MODE,
    "@read_file(%s)" % lpc_str(C),
], post=RM)

sess("ed files: x writes only when changed", lpc_str(A), [
    "x", MODE, "@read_file(%s)" % lpc_str(A),
], pre=wr(A, FIVE), post='r += ({ ed_start(%s), ed_cmd("x %s"), read_file(%s) }); %s %s' % (lpc_str(A), C, lpc_str(C), CLOSE, RM))

sess("ed restricted sessions", lpc_str("tmp_m7_none.txt") + ", 1", [
    "@in_edit()", "f", "f x", "e x", "E x", "r x", "w x", "W x", "x x", "wq x", "x %s" % C,
    "a", "hi", ".", "w", "@read_file(\"/test/tmp_m7_none.txt\")", "1,1W", "@read_file(\"/test/tmp_m7_none.txt\")",
    "wq", MODE,
], post='r += ({ ed_start(%s, 1), ed_cmd(",p"), ed_cmd("x"), ed_start("/test/tmp_m7_none.txt", yes), ed_cmd("Q") }); %s %s' % (lpc_str(A), CLOSE, RM),
     pre=wr(A, FIVE) + ' mixed yes = "yes";')

sess("ed help", "", [
    "h", MODE, "", MODE, "", MODE,
    "h", "", "", MODE,
    "h", "p", MODE,
    "h", "x", MODE,
    "h d", "h s", "h z", "h w", "h set", "h zz", "h  p ", "hd",
    "1h", MODE,
])

sess("ed errors", lpc_str(A), [
    "y", "!ls", "pq", "= 3", "=x", "uu", "u x", "qq", "Q x", "#", "1,2", "1;", ";", "1;3", "=",
    "Y", "  ", "\t", " p", "\tp", "2\tp",
], pre=wr(A, FIVE), post=RM)

sess("ed q and Q end the session", lpc_str(A), [
    "1d", "q", MODE, "Q", MODE, "@in_edit()", "p", "Q", "@query_ed_mode()",
], pre=wr(A, FIVE), post=RM)

case("ed efun arguments",
     '''mixed one = 1, zero = 0;
mixed *r = ({ catch(ed_start(one)), catch(ed_start(zero)), catch(ed_cmd(one)), catch(ed_cmd(zero)), ed_cmd("p"), query_ed_mode(), in_edit(), in_edit(zero) });
object u = clone_object("/test/ed_user");
r += ({ u->start("%s"), in_edit(u), u->mode(), in_edit(), query_ed_mode() });
r += ({ u->cmd("a"), u->mode(), in_edit(u), u->cmd("."), u->cmd("Q"), in_edit(u), u->mode() });
destruct(u);
r += ({ in_edit(u) });
return r;''' % A)

case("ed sessions are per object",
     wr(A, FIVE) + " " + wr(B, "one\ntwo\n") + '''
object u = clone_object("/test/ed_user"), v = clone_object("/test/ed_user");
mixed *r = ({ u->start("%s"), v->start("%s"), ed_start("%s") });
r += ({ u->cmd("2p"), v->cmd("2p"), ed_cmd("2p"), u->cmd("1d"), v->cmd(",p"), in_edit(u), in_edit(v), in_edit() });
r += ({ u->cmd("Q"), u->cmd("p"), v->cmd("p"), ed_cmd("Q"), v->cmd("x") });
destruct(u); destruct(v);
%s
return r;''' % (A, B, A, RM))

case("ed rescue edge cases",
     wr(A, FIVE) + '''
mixed *r = ({});
rm("/test/ed_dead.edit");
object u = clone_object("/test/tmp_m7_ed");
u->go(); u->c("a"); u->c("nameless"); u->c(".");
destruct(u);
r += ({ read_file("/test/ed_dead.edit"), master()->query_ed_rescued_for() });
rm("/test/ed_dead.edit");
u = clone_object("/test/ed_user");
u->start("%s"); u->cmd("1d"); u->cmd("w");
destruct(u);
r += ({ file_size("/test/ed_dead.edit") });
u = clone_object("/test/ed_user");
u->start("%s"); u->cmd(",d");
destruct(u);
r += ({ file_size("/test/ed_dead.edit") });
u = clone_object("/test/ed_user");
u->start("%s"); u->cmd("1d"); u->cmd("u");
destruct(u);
r += ({ read_file("/test/ed_dead.edit"), master()->query_ed_rescued_for() });
rm("/test/ed_dead.edit");
u = clone_object("/test/ed_user");
u->start("%s"); u->cmd("$a"); u->cmd("typed");
destruct(u);
r += ({ read_file("/test/ed_dead.edit") });
%s
return r;''' % (A, A, A, A, RM))

case("ed get_garbage keeps an editing clone",
     'mk(); int a = count(); children("/test/tmp_m7_ed")->c("Q"); int b = count(); '
     'foreach (object o in children("/test/tmp_m7_ed")) destruct(o); return ({ a, b });',
     'void mk() { clone_object("/test/tmp_m7_ed")->go(); }\n'
     'int count() { return sizeof(filter(get_garbage(), (: base_name($1) == "/test/tmp_m7_ed" :))); }')

case("m7 remove helpers", 'rm("/test/tmp_m7_ed.c"); ' + RM + " return 1;")

def esc(s):
    return s.replace("\\", "\\\\").replace("\n", "\\n").replace("\t", "\\t")

print("# HavokOS M7 cases (todo.md HavokOS M7): the line editor, through ed_start(),")
print("# ed_cmd(), query_ed_mode() and in_edit() on the test minilib.")
print("# GENERATED by tools/gen_m7_cases.py -- edit that, not this file. One case per")
print("# line, <name><TAB><body>; expected results in m7_extra.expected.txt are the")
print("# live Pike driver's own (tools/ref_cases.pike -extra).")
for name, body in CASES:
    print(name + "\t" + esc(body.strip()))
