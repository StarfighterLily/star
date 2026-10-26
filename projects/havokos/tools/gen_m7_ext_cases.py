"""Generates tests/fixtures/cases/m7_ext_cases.txt (todo.md HavokOS P1 #6,
the reference's HavokOS-only extension efuns).

Three kinds of case:
- the reference's own tests of these efuns in pike/tests/run_tests.pike,
  ported: its json, astar and status-efun checks are LPC already and are
  copied; its watch, find_files, quota, dependency and profiling tests drive
  the driver from Pike, so they run here through hooks both case runners
  provide (test_watch_poll(), test_run_call_out(), test_utime(),
  test_forget(), test_profiling(), test_put(), test_rmtree();
  tools/ref_cases.pike gives them to the reference), one case per `expect`;
- this port's own edge cases, mostly for json_encode()/json_decode(),
  whose rules are Pike's Standards.JSON and were probed against the live
  reference (json.star's header);
- astar_path() on mazes larger than the reference's two checks.
Expected results (m7_ext.expected.txt) are whatever the live reference
returns, never hand-predicted.

What the cases avoid, because the two drivers differ by design
(NOTES.md deviations):
- wide strings (characters above U+00FF, from \\u escapes or UTF-8 text),
  \\u0000, and 20-digit numbers (#7, #14, #6, #18);
- unsorted json_encode() of mappings with more than one key (#9);
- floats that need more than single precision to tell apart (#3), and
  their overflow: 1e30 squared is inf in the reference's 32-bit floats, so
  infinity is reached by squaring until it overflows in both;
- timings: the quota and profiling cases compare times only with each
  other (self time against callee time, more than before), as the
  reference's tests do; cache_stats()/malloc_status() only by their first
  line (#19).
The cases run in order and share state through the driver and a helper
object (/test/tmp_m7_ext.c, written by the first case, removed by the
last). Directories made: /test/wdir, /test/fdir, /test/dep, /secret.

Usage: python tools/gen_m7_ext_cases.py > tests/fixtures/cases/m7_ext_cases.txt
"""

def lpc_str(src):
    """An LPC string literal holding src."""
    return '"' + src.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'

CASES = []

def case(name, body, globals_=""):
    CASES.append((name, (globals_ + " @@ " if globals_ else "") + body))

H = "/test/tmp_m7_ext"
HELPER = r'''// state shared by the M7 extension cases
object w, flat, a, b, finder, prof;
// --- quotas: the test master files /test/q_* in group "q"
mapping q() { return quota_info("q") || ([]); }
void limits(mapping l, int allow) { master()->set_quota(l, allow); quota_refresh(); }
mixed *q_clones() {
    limits(([ "clones": 2, "call_outs": 3 ]), 0);
    a = clone_object("/test/q_thing");
    b = clone_object("/test/q_thing");
    mixed c = catch(clone_object("/test/q_thing"));
    return ({ q()["clones"], c, master()->query_quota_log() });
}
mixed *q_allow() {
    limits(([ "clones": 2, "call_outs": 3 ]), 1);
    object c = clone_object("/test/q_thing");
    mixed *r = ({ objectp(c), q()["clones"] });
    destruct(c);
    return r + ({ q()["clones"] });
}
mixed *q_call_outs() {
    limits(([ "clones": 2, "call_outs": 3 ]), 0);
    int total0 = quota_info()["*"]["call_outs"];
    int h = a->add(2);
    int h2 = a->add_fn();
    mixed over = catch(b->add(1));
    mixed *r = ({ q()["call_outs"], quota_info()["*"]["call_outs"] - total0, over, sizeof(master()->query_quota_log()) });
    remove_call_out(h);
    test_run_call_out(h2);
    r += ({ q()["call_outs"], a->query_ticks() });
    destruct(a);
    return r + ({ q()["call_outs"], q()["clones"] });
}
mixed *q_eval() {
    limits(([ "eval": 1 ]), 0);
    int eval0 = q()["eval"];
    int h3 = b->add(1);
    test_run_call_out(h3, "spin");
    h3 = b->add(1);
    test_run_call_out(h3, "spin");
    return ({ q()["eval"] > eval0, b->query_ticks(), master()->query_quota_log(), q()["limits"] });
}
mixed *q_done() {
    destruct(b);
    object bp = find_object("/test/q_thing");
    if (bp) destruct(bp);
    mixed *r = ({ q()["call_outs"], q()["clones"] });
    limits(([]), 0);
    return r;
}
// --- dependencies: base includes dep.h; mid and other inherit base, top
// inherits mid; solo stands alone (files dated into the past, newest last)
int age = 200;
void put(string f, string text) {
    write_file("/test/dep/" + f, text, 1);
    age -= 10;
    test_utime("/test/dep/" + f, age);
}
void reload(string p) {
    object o = find_object(p);
    if (o) destruct(o);
    load_object(p);
}
string *mine(string *r) { return filter(r, (: $1[0..9] == "/test/dep/" :)); }
string *stale(string p) { return mine(p ? stale_programs(p) : stale_programs()); }
'''

case("m7x setup helpers",
     "write_file(%s, %s, 1); load_object(%s); return 1;" % (lpc_str(H + ".c"), lpc_str(HELPER), lpc_str(H)))

def hcall(fn):
    return 'return load_object("%s")->%s;' % (H, fn)

# ---------------------------------------------------------------------------
# json: the reference's own json_tests() checks first
case("json_encode: values, int keys, ASCII escapes",
     r'return json_encode(([ "a": ({ 1, 2.5, "q\"\xe9\n" }), 3: 0, "m": ([]) ]), 2);')
case("json_encode: pretty", r'return sizeof(explode(json_encode(({ 1, ([ "k": 2 ]) }), 1), "\n")) > 3;')
case("json_decode: literals, nesting, UTF-8 bytes",
     r'return json_decode("{\"a\":[true,false,null,-1.5e1],\"s\":\"\xc3\xa9\\u0041\"}");')
case("json round trip",
     r'mixed v = ([ "x": ({ 1, ({ "y" }), ([ "z": 0 ]) }) ]); return json_decode(json_encode(v));')
case("json_decode: syntax error", r'return catch(json_decode("[1,"));')
case("json_encode: objects refused", r'return catch(json_encode(({ this_object() })));')
case("json_encode: cycles refused", r'mixed *a = ({ 0 }); a[0] = a; return catch(json_encode(a));')
case("json_encode: bad keys", r'return catch(json_encode(([ ({}) : 1 ])));')

# json_encode
case("json_encode: scalars and escapes",
     r'return json_encode(({ 1, -2, "a\"b\\c\n\t\x01/", 1.5, 0.1, 1e10, 123456789.0, ([ "k": 1 ]), ({}), ([]) }));')
case("json_encode: bytes from 0x7f up and control bytes",
     r'return ({ json_encode("\xe9\xff" + "x"), json_encode("\x7f\x80\x1f"), json_encode("\b\f\r\x0b\x1f\x20~") });')
case("json_encode: floats", r'return ({ json_encode(0.0), json_encode(-0.0), json_encode(3.0), json_encode(1.0/3.0), json_encode(2.5e-5), json_encode(({ 100000.0, 1234567.0, 0.0001, 0.00001, 12.25 })), json_encode(({ 1.0e-10, -1.5e15, 123456.0 })) });')
case("json_encode: inf and nan are null",
     r'float f = 1e30; for (int i = 0; i < 8; i++) f = f * f; return json_encode(({ f, -f, f - f }));')
case("json_encode: ints", r'return json_encode(({ 9223372036854775807, -9223372036854775807 - 1, 0 }));')
case("json_encode: canonical sorts keys bytewise",
     r'return json_encode(([ "z": 1, "a": 2, "B": 3, "10": 4, 2: 5, "": 6 ]), 2);')
case("json_encode: canonical nested", r'return json_encode(([ "b": 1, "a": ({ 1, 2 }), "c": ([ "y": 1, "x": 2 ]) ]), 2);')
case("json_encode: pretty and canonical",
     r'return json_encode(([ "b": 1, "a": ({ 1, ([ "z": ({}) , "q": ([]) ]) }) ]), 3);')
case("json_encode: pretty arrays", r'return json_encode(({ 1, ({ 2, 3 }), "x" }), 1);')
case("json_encode: pretty one-element arrays stay inline",
     r'return ({ json_encode(({1}), 1), json_encode(({1,2}), 1), json_encode(({({1})}), 1), json_encode((["a":1]), 1), json_encode((["a":({1})]), 1), json_encode(({ (["a":1]) }), 1), json_encode(({ ({}) }), 1), json_encode(({ ([]) }), 1), json_encode("x", 1), json_encode(({ "a" }), 1), json_encode(({ 1.5 }), 1), json_encode(({ ({ 1, 2 }) }), 1) });')
case("json_encode: pretty mappings",
     r'return ({ json_encode((["a":(["b":1])]), 1), json_encode((["a":([])]), 1), json_encode((["a":({})]), 1), json_encode((["a":({1,2})]), 1), json_encode(([ "a": ([ "b": ({ 1, ([ "c": "d" ]) }) ]) ]), 1) });')
case("json_encode: pretty mixed nesting",
     r'return ({ json_encode(({ 1, ({}) }), 1), json_encode(({ ({}), 1 }), 1), json_encode(({ ({1}), ({2}) }), 1), json_encode(({ 1 }), 3) + "|" + json_encode(([]), 1) + "|" + json_encode(({}), 1) });')
case("json_encode: int keys become strings", r'return ({ json_encode(([ 1: 2 ])), json_encode(([ -5: "x" ])) });')
case("json_encode: flags", r'return ({ json_encode(1, 0), json_encode(({1}), -1), json_encode(({1, 2}), 8), json_encode(({1, 2}), 4) });')
case("json_encode: non-int flags", r'mixed x = "s", y = 1.5, z = ({}), m = ([]); return ({ catch(json_encode(1, x)), catch(json_encode(1, y)), catch(json_encode(1, z)), catch(json_encode(1, m)) });')
case("json_encode: the same array twice is not a cycle",
     r'mixed *a = ({ 1 }); mixed m = (["a":1]); return ({ json_encode(({ a, a })), json_encode(({ m, ([ "m": m ]) })) });')
case("json_encode: cyclic mapping", r'mixed m = ([]); m["x"] = m; return catch(json_encode(m));')
case("json_encode: refused values", r'mixed f = 1.5; return ({ catch(json_encode((: 1 :))), catch(json_encode(([ f: 2 ]))), catch(json_encode(({ 1, ({ this_object() }) }))) });')
case("json_encode: depth limit",
     r'mixed *r = ({}); foreach (int n in ({ 511, 512, 513, 520 })) { mixed *a = ({}); for (int i = 0; i < n; i++) a = ({ a }); mixed e = catch(r += ({ sizeof(json_encode(a)) })); if (e) r += ({ e }); } return r;')

# json_decode
case("json_decode: values", r'return json_decode("{\"a\": [1, 2.5, \"x\", true, false, null, {}], \"b\": -3e2, \"c\": \"\\u00e9\\n\\/\\t\\b\\f\\r\\\\\"}");')
case("json_decode: scalars", r'return ({ json_decode("12"), json_decode(" \"s\" "), json_decode("1.0"), json_decode("[]"), json_decode("1e3"), json_decode("-0"), json_decode("0.5E+1"), json_decode("true"), json_decode("false"), json_decode("null"), json_decode("\"\""), json_decode("{}") });')
case("json_decode: numbers", r'return ({ json_decode("[1.5, -0.25, 1E2, 1e-2, 123456789012]"), json_decode("1.5e3"), json_decode("-0.0"), json_decode("1E+2"), json_decode("100"), json_decode("-7"), json_decode("0.1"), json_decode("[123456789.5, 3.14159265358979, 1e-7]") });')
case("json_decode: overflowing floats are infinite", r'return json_decode("[1e400, -1e400]");')
case("json_decode: UTF-8 text is decoded, other bytes kept",
     r'return ({ json_decode("\"\xc3\xa9\""), json_decode("\"\xe9\""), json_decode("\"\xff\xfe\""), json_decode("\"\xc3\xa9\" "), json_decode("[\"\\u0041\\u00ff\"]") });')
case("json_decode: error positions count decoded characters",
     r'return ({ catch(json_decode("\"\xc3\xa9\" x")), catch(json_decode("\"\xe9\" x")) });')
case("json_decode: escapes", r'return ({ json_decode("[\"\\b\\f\\r\\t\\n\\\"\\\\\\/\", \"\\u0041\"]"), json_decode("[\"\\\"\", \"\\u0022\"]") });')
case("json_decode: Pike's leniencies (trailing commas, a leading point)",
     r'return ({ json_decode("[1,]"), json_decode("{\"a\":1,}"), json_decode(".5"), json_decode("[.5, 1, -1.5e-1, 0.0]"), json_decode("{\"a\":[1,2,],}"), json_decode("[1 ,]"), json_decode("[1, ]"), json_decode("{\"a\":1 ,}"), json_decode("[.5e1]") });')
case("json_decode: repeated keys, nesting, whitespace",
     r'return ({ json_decode("{\"a\":1,\"a\":2}"), json_decode("{\"1\": 2}"), json_decode("  [ 1 , { \"a\" : [ ] } ]  "), json_decode("\t\r\n [1]\n"), json_decode("{\"a\":{\"b\":{}}}"), json_decode("[true,false,null]") });')
case("json_decode: not a string", r'mixed x = 5; return catch(json_decode(x));')
case("json_decode: number syntax errors",
     r'mixed *r = ({}); foreach (string s in ({ ".", ".e1", "0.", "1.5.", "00", "-01", "1e+", ".5.5", "-", "-a", ".a", "-.5", "01", "1.", "1e", "1.e5", "+1", "--1", "0x10", "[01]", "1 2" })) r += ({ catch(json_decode(s)) }); return r;')
case("json_decode: structure syntax errors",
     r'mixed *r = ({}); foreach (string s in ({ "[1, 2", "{\"a\" 1}", "", "  ", "[1] x", "[,]", "{,}", "[1,,2]", "[1,2,,]", "{\"a\":1,,}", "{1:2}", "{\"a\"}", "{\"a\":}", "[1}", "[1 2]", "[", "{", "{\"a\":", "[1", "[1,", "{\"a\":1", "{\"a\":1,", "{\"a\"", "{\"", "[1]\x0b" })) r += ({ catch(json_decode(s)) }); return r;')
case("json_decode: literal syntax errors",
     r'mixed *r = ({}); foreach (string s in ({ "tru", "nul", "nulx", "n", "truex", "true false", "TRUE", "[tru", "{\"a\":[1,{\"b\":tru}]}", "\x27a\x27" })) r += ({ catch(json_decode(s)) }); return r;')
case("json_decode: string syntax errors",
     r'mixed *r = ({}); foreach (string s in ({ "\"abc", "\"\\u12\"", "\"\\uzzzz\"", "\"\\x\"", "\"a\nb\"", "\"tab\there\"", "\"\x01\"", "\"x", "[\"x", "[\"a\\", "\"\\u00", "\"\\ud800\"" })) r += ({ catch(json_decode(s)) }); return r;')

# ---------------------------------------------------------------------------
# astar_path(): the reference's two checks, then larger mazes
case("astar_path: cheapest way round",
     r'''mapping c = ([ ' ': 1, '*': 50 ]); mixed *r = astar_path(" * \n   \n", 0, 0, 2, 0, c); return ({ r[0], r[1][2][3], r[1][0][0], sizeof(r[1][2]) });''')
case("astar_path: walls, ragged lines, no way through",
     r'''mapping c = ([ '.': 1 ]); return ({ astar_path("..#.\n.\n", 0, 0, 3, 0, c), astar_path("..\n.", 0, 0, 1, 1, c), astar_path(".x", 0, 0, 1, 0, c), astar_path("...", 0, 0, 2, 0, c)[0] });''')
MAZE = (
    "..........\n"
    ".########.\n"
    ".#......#.\n"
    ".#.####.#.\n"
    ".#.#..#.#.\n"
    ".#.#.##.#.\n"
    ".#.#....#.\n"
    ".#.######.\n"
    ".#........\n"
    ".#########\n")
case("astar_path: a maze, the whole node table",
     "mapping c = ([ '.': 1 ]); return astar_path(%s, 4, 4, 0, 9, c);" % lpc_str(MAZE))
case("astar_path: a maze the other way",
     "mapping c = ([ '.': 1 ]); mixed *r = astar_path(%s, 0, 9, 4, 4, c); return ({ r[0], sizeof(r[1]), r[2] });" % lpc_str(MAZE))
case("astar_path: float costs and a swamp",
     r'''mapping c = ([ '.': 1.0, '~': 4.5, 'h': 2 ]); return astar_path("....~...\n.~~~~~~.\n.hhhhhh.\n........\n", 0, 0, 7, 0, c);''')
case("astar_path: open field ties",
     r'''mapping c = ([ '.': 1 ]); mixed *r = astar_path("......\n......\n......\n......\n", 0, 0, 5, 3, c); return ({ r[0], sizeof(r[1]), r[2] });''')
case("astar_path: start is the goal, out of bounds, bad arguments",
     r'''mapping c = ([ '.': 1 ]); mixed m = "..."; return ({ astar_path("...", 1, 0, 1, 0, c), astar_path("...", -1, 0, 2, 0, c), astar_path("...", 0, 0, 3, 0, c), astar_path("...", 0, 0, 0, 1, c), astar_path(m, 0, 0, 2, 0, 0), astar_path(0, 0, 0, 2, 0, c) });''')
case("astar_path: costly detours lose to cheap long ways",
     r'''mapping c = ([ '.': 1, 'm': 9 ]); mixed *r = astar_path(".m.\n...\n", 0, 0, 2, 0, c); return ({ r[0], r[2], sort_array(keys(r[1]), 1) });''')

# ---------------------------------------------------------------------------
# find_files(): run_tests.pike find_files_tests(); the answer comes on a
# later pass, so each case pumps until the finder has it
FDIR = ["/test/fdir/a.c", "/test/fdir/b.h", "/test/fdir/sub/c.c", "/test/fdir/sub/deep/d.c",
        "/test/fdir/skipme/e.c", "/secret/s.c"]
case("find_files: setup",
     'test_rmtree("/test/fdir"); test_rmtree("/secret"); int n; foreach (string f in ({ %s })) n += test_put(f, "int x;\\n"); '
     'load_object("%s")->set_finder(clone_object("/test/finder")); return n;' % (", ".join(lpc_str(f) for f in FDIR), H),
     )
case("find_files: glob, recursion, skipped directories",
     'object o = load_object("%s")->query_finder(); int started = o->find("/test/fdir", "*.c", ({ "/test/fdir/skipme" })); '
     'test_sock_pump(o, "query_got"); return ({ started, o->query_got() });' % H)
case("find_files: unreadable directories left out",
     'object o = load_object("%s")->query_finder(); o->find("/", "?.c", 0); test_sock_pump(o, "query_got"); mixed got = o->query_got(); '
     'return ({ member_array("/test/fdir/a.c", got[0]) >= 0, member_array("/secret/s.c", got[0]) >= 0, member_array("/secret", got[1]) >= 0 });' % H)
case("find_files: not a directory, bad arguments",
     'object o = load_object("%s")->query_finder(); return ({ o->find("/test/nope", "*", 0), o->find("/test/finder.c", "*", 0), '
     'find_files("/test/fdir", "*", cb), find_files("/secret", "*", (: 1 :)), find_files(z, "*", (: 1 :)) });' % H,
     'mixed cb = "found"; mixed z = 0;')
case("find_files: a question mark, no matches, an empty directory",
     'object o = load_object("%s")->query_finder(); test_put("/test/fdir/empty/.keep", ""); o->find("/test/fdir", "?.?", 0); test_sock_pump(o, "query_got"); mixed a = o->query_got(); '
     'o->find("/test/fdir", "*.zz", 0); test_sock_pump(o, "query_got"); mixed b = o->query_got(); '
     'o->find("/test/fdir/", "*", ({ "/test/fdir/sub", 5 })); test_sock_pump(o, "query_got"); return ({ a, b, o->query_got() });' % H)
case("find_files: the caller destructed before the answer",
     'object o = clone_object("/test/finder"); o->find("/test/fdir", "*.c", 0); destruct(o); test_sock_pump(0, 0); return 1;')
case("find_files: cleanup",
     'destruct(load_object("%s")->query_finder()); test_rmtree("/test/fdir"); test_rmtree("/secret"); return file_size("/test/fdir");' % H)

# ---------------------------------------------------------------------------
# file watching: run_tests.pike watch_tests(), polls run by hand
case("watch_path: setup",
     'test_rmtree("/test/wdir"); mkdir("/test/wdir"); write_file("/test/wdir/a.c", "int a;\\n", 1); '
     'load_object("%s")->set_watchers(clone_object("/test/watcher"), clone_object("/test/watcher")); return 1;' % H)
case("watch_path: only directories",
     'object *ws = load_object("%s")->query_watchers(); return ({ ws[0]->watch("/test/wdir", 1), ws[1]->watch("/test/wdir", 0), ws[0]->watch("/test/nope", 0), ws[0]->watch("/test/watcher.c", 0) });' % H)
case("watch_path: nothing to report at first",
     'object *ws = load_object("%s")->query_watchers(); mixed p = test_watch_poll(); return ({ p, ws[0]->query_seen(), ws[1]->query_seen() });' % H)
case("watch_path: added and edited files",
     'object *ws = load_object("%s")->query_watchers(); write_file("/test/wdir/b.c", "int b;\\n", 1); write_file("/test/wdir/a.c", "int a, aa;\\n", 1); '
     'mixed p = test_watch_poll(); return ({ p, ws[0]->query_seen(), ws[1]->query_seen() });' % H)
case("watch_path: removed files, new subdirectories when recursive",
     'object *ws = load_object("%s")->query_watchers(); mkdir("/test/wdir/sub"); write_file("/test/wdir/sub/c.c", "int c;\\n", 1); rm("/test/wdir/b.c"); '
     'mixed p = test_watch_poll(); return ({ p, ws[0]->query_seen(), ws[1]->query_seen() });' % H)
case("watch_path: edits in a subdirectory",
     'object *ws = load_object("%s")->query_watchers(); write_file("/test/wdir/sub/c.c", "int c, cc;\\n", 1); '
     'mixed p = test_watch_poll(); return ({ p, ws[0]->query_seen(), ws[1]->query_seen(), test_watch_state() });' % H)
case("watch_path: unwatching one directory, then a new one",
     'object *ws = load_object("%s")->query_watchers(); ws[1]->unwatch("/test/wdir/"); mixed s1 = test_watch_state(); '
     'ws[1]->watch("/test/wdir/sub", 0); write_file("/test/wdir/sub/e.c", "int e;\\n", 1); mixed p = test_watch_poll(); '
     'return ({ s1, p, ws[0]->query_seen(), ws[1]->query_seen(), test_watch_state() });' % H)
case("watch_path: unwatched and destructed watchers hear nothing",
     'object *ws = load_object("%s")->query_watchers(); ws[0]->unwatch(0); destruct(ws[1]); write_file("/test/wdir/d.c", "int d;\\n", 1); '
     'mixed p = test_watch_poll(); return ({ p, ws[0]->query_seen(), test_watch_state() });' % H)
case("watch_path: cleanup",
     'object *ws = load_object("%s")->query_watchers(); destruct(ws[0]); object bp = find_object("/test/watcher"); if (bp) destruct(bp); '
     'test_rmtree("/test/wdir"); return test_watch_state();' % H)

# ---------------------------------------------------------------------------
# quotas: run_tests.pike quota_tests(), one case per expect
case("quota: clones over the limit are refused", hcall("q_clones()"))
case("quota: quota_exceeded() can allow it, destructed clones leave the count", hcall("q_allow()"))
case("quota: call_outs counted per group, removed and run ones leave the count", hcall("q_call_outs()"))
case("quota: call_out time charged, the master told once a minute", hcall("q_eval()"))
case("quota: all gone", hcall("q_done()"))
case("quota: quota_info() of unknown groups and bad arguments",
     'mixed x = 5; return ({ quota_info("no such group"), quota_info(x), sort_array(keys(quota_info()["*"]), 1), quota_info("*")["limits"] });')

# ---------------------------------------------------------------------------
# dependencies: run_tests.pike dependency_tests()
case("stale_programs: setup",
     'object h = load_object("%s"); mkdir("/test/dep"); '
     'h->put("dep.h", "#define DV 1\\n"); '
     'h->put("base.c", "#include \\"dep.h\\"\\nint bv() { return DV; }\\n"); '
     'h->put("mid.c", "inherit \\"/test/dep/base\\";\\nint mv() { return bv() + 10; }\\n"); '
     'h->put("top.c", "inherit \\"/test/dep/mid\\";\\nint tv() { return mv() + 100; }\\n"); '
     'h->put("other.c", "inherit \\"/test/dep/base\\";\\n"); '
     'h->put("solo.c", "int sv() { return 5; }\\n"); '
     'foreach (string f in ({ "base", "mid", "top", "other", "solo" })) { object o = find_object("/test/dep/" + f); if (o) destruct(o); test_forget("/test/dep/" + f); } '
     'foreach (string f in ({ "top", "other", "solo" })) load_object("/test/dep/" + f); return 1;' % H)
case("stale_programs: nothing changed",
     'object h = load_object("%s"); return ({ h->stale("/test/dep/top"), h->stale(0) });' % H)
case("dependents: of a file, parents first", 'return dependents("/test/dep/base");')
case("dependents: of a header, and of a leaf",
     'return ({ dependents("/test/dep/dep.h"), dependents("/test/dep/top.c"), dependents("test/dep/mid"), dependents("/test/dep/nothere.h") });')
case("stale_programs: an edited ancestor and what lies between",
     'object h = load_object("%s"); h->put("base.c", "#include \\"dep.h\\"\\nint bv() { return DV * 2; }\\n"); '
     'return ({ h->stale("/test/dep/top"), h->mine(stale_programs(find_object("/test/dep/solo"))), h->stale(0) });' % H)
case("stale_programs: a recompiled ancestor makes its heirs stale",
     'object h = load_object("%s"); h->reload("/test/dep/base"); return ({ h->stale("/test/dep/base"), h->stale("/test/dep/top") });' % H)
case("stale_programs: up to date after reloading in that order",
     'object h = load_object("%s"); h->reload("/test/dep/mid"); h->reload("/test/dep/top"); '
     'return ({ h->stale("/test/dep/top"), find_object("/test/dep/top")->tv() });' % H)
case("stale_programs: recompiling unchanged code changes nothing",
     'object h = load_object("%s"); h->reload("/test/dep/base"); return h->stale("/test/dep/top");' % H)
case("stale_programs: an edited include",
     'object h = load_object("%s"); h->put("dep.h", "#define DV 3\\n"); return h->stale("/test/dep/mid");' % H)
case("stale_programs: a file never compiled, an object, bad arguments",
     'object h = load_object("%s"); mixed x = 5; return ({ h->stale("/test/dep/nothere"), h->stale("/test/dep/nothere.c"), '
     'h->mine(stale_programs(find_object("/test/dep/top"))), catch(stale_programs(x)), catch(dependents(x)) });' % H)
case("stale_programs: cleanup",
     'foreach (string f in ({ "base", "mid", "top", "other", "solo" })) { object o = find_object("/test/dep/" + f); if (o) destruct(o); } '
     'test_rmtree("/test/dep"); return file_size("/test/dep");')

# ---------------------------------------------------------------------------
# profiling: run_tests.pike profile_tests() and sample_profile_tests()
case("opcprof: one line per efun, counts 0 when not profiling",
     'opcprof("/test/tmp_opc"); string efuns = read_file("/test/tmp_opc.efun") || ""; '
     'return ({ strsrch(efuns, sprintf("%-30s: %10d\\n", "this_player", 0)) >= 0, file_size("/test/tmp_opc.eoper") >= 0 });')
case("cache_stats", 'return strsrch(cache_stats(), "HavokOS cache statistics\\n") == 0;')
case("status efuns: memory_info, malloc_status, memory_summary",
     'string m = malloc_status(); return ({ memory_info() > 1000000, strsrch(m, "Memory in use:") == 0, memory_summary() });')
case("function_profile: empty when not profiling", 'return ({ function_profile(master()), function_profile() });')
case("function_profile: calls",
     'int open = test_profiling(1); object p = find_object("/test/prof"); if (p) destruct(p); test_forget("/test/prof"); '
     'p = load_object("/test/prof"); p->outer(); p->catcher(); p->outer(); '
     'mapping prof = ([]); foreach (mapping m in function_profile(p)) prof[m["name"]] = m; '
     'return ({ open, sort_array(keys(prof), 1), map(({ "inner", "outer", "boom", "catcher", "spin", "work" }), (: $2[$1] && $2[$1]["calls"] :), prof), test_profiling(1) });')
case("function_profile: callee time is the caller's children",
     'mapping prof = ([]); foreach (mapping m in function_profile(find_object("/test/prof"))) prof[m["name"]] = m; '
     'return ({ prof["outer"]["children"] >= prof["inner"]["self"], prof["catcher"]["children"] >= prof["boom"]["self"], prof["spin"]["self"] });')
case("opcprof: counts efun calls when profiling",
     'opcprof("/test/tmp_opc"); string efuns = read_file("/test/tmp_opc.efun") || ""; '
     'return strsrch(efuns, sprintf("%-30s: %10d\\n", "strlen", 4)) >= 0;')
case("function_profile: bad arguments",
     'mixed x = 5; return ({ catch(function_profile(x)), catch(function_profile(0)) });')
case("profiling: off again",
     'int open = test_profiling(0, 1); destruct(find_object("/test/prof")); foreach (string f in ({ "tmp_opc.efun", "tmp_opc.eoper" })) rm("/test/" + f); return open;')
case("profile_report: empty before a start",
     'object p = find_object("/test/prof"); if (p) destruct(p); test_forget("/test/prof"); load_object("/test/prof"); '
     'mapping r = profile_report(); return ({ r["running"], r["samples"], r["time"], r["functions"], sort_array(keys(r), 1) });')
# The sample clock only runs inside top-level evaluations (as on a running
# driver), and a case body isn't one, so the sampled work runs through
# test_limited(fn, 0): fn as its own evaluation, no time limit (the
# reference's test uses drv->safe()).
SAMPLED = 'object p; void w1() { p->work(400000); } void w2() { p->spin(2000); } void w3() { p->spin(200000); }'
case("profile_report: the busy function has the self time, its caller the total",
     'p = find_object("/test/prof"); profile_start(200); test_limited("w1", 0); mapping r = profile_report(); '
     'mapping by = ([]); foreach (mapping f in r["functions"]) by[f["file"] + ":" + f["function"]] = f; '
     'mapping spin = by["/test/prof:spin"] || ([]), work = by["/test/prof:work"] || ([]); '
     'return ({ r["running"], spin["self"] > r["time"] / 2, work["total"] >= spin["self"], work["self"] < spin["self"], r["functions"][0]["function"], sort_array(keys(spin), 1) });',
     SAMPLED)
case("profile_report: many short evaluations are sampled",
     'p = find_object("/test/prof"); profile_report(1); profile_start(5000); for (int k = 0; k < 400; k++) test_limited("w2", 0); '
     'mapping r = profile_report(); return r["samples"] > 0 && r["functions"][0]["function"];', SAMPLED)
case("function_profile: sampled numbers when not instrumented",
     'mapping fp = ([]); foreach (mapping m in function_profile(find_object("/test/prof"))) fp[m["name"]] = m; '
     'return ({ fp["spin"] && fp["spin"]["calls"] > 0, fp["spin"] && fp["spin"]["self"] > 0, member_array("boom", keys(fp)) >= 0 });')
case("profile_stop: no more samples, report kept",
     'p = find_object("/test/prof"); profile_stop(); int n = profile_report()["samples"]; test_limited("w3", 0); '
     'mapping r = profile_report(); return ({ r["running"], r["samples"] == n, n > 0 });', SAMPLED)
case("profile_start: bad arguments, the interval floor",
     'mixed x = "s"; mixed e = catch(profile_start(x)); profile_start(1); int run = profile_report()["running"]; profile_stop(); '
     'profile_start(); int def = profile_report()["running"]; profile_stop(); profile_report(1); destruct(find_object("/test/prof")); return ({ e, run, def });')

case("m7x remove helpers",
     'destruct(load_object("%s")); rm("%s.c"); return 1;' % (H, H))

# the helper's accessors for the finder and the watchers
HELPER_TAIL = r'''
void set_finder(object o) { finder = o; }
object query_finder() { return finder; }
void set_watchers(object x, object y) { w = x; flat = y; }
object *query_watchers() { return ({ w, flat }); }
'''

def esc(s):
    return s.replace("\\", "\\\\").replace("\n", "\\n").replace("\t", "\\t")

# the helper is written whole by the first case
CASES[0] = (CASES[0][0], "write_file(%s, %s, 1); load_object(%s); return 1;" % (lpc_str(H + ".c"), lpc_str(HELPER + HELPER_TAIL), lpc_str(H)))

print("# HavokOS M7 extension cases (todo.md HavokOS P1 #6): json, astar_path,")
print("# find_files, file watching, quotas, stale_programs/dependents, profiling and")
print("# the status reports, through the test_* hooks both runners provide.")
print("# GENERATED by tools/gen_m7_ext_cases.py -- edit that, not this file. One case")
print("# per line, <name><TAB><body>; expected results in m7_ext.expected.txt are the")
print("# live Pike driver's own (tools/ref_cases.pike -extra).")
for name, body in CASES:
    print(name + "\t" + esc(body.strip()))
