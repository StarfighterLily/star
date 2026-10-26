"""Generates tests/fixtures/cases/gc_cases.txt (todo.md HavokOS P1 #9,
garbage collection inside one evaluation: gc.star collect_young()).

The collector frees nothing observable, so every case is an ordinary LPC
result the live reference gives too (gc.expected.txt is its output,
tools/ref_cases.pike -extra, never hand-predicted). What the cases are
built around is where a collection inside an evaluation could go wrong on
the Star side, each made to allocate enough (over the collector's 1M-value
floor) that collections really run inside it without -gcstress:
- the todo item's own loop: 40,000 `a += ({ i })`, which held 7 GB at
  30,000 and killed the driver at 40,000 before the fix;
- values only native Star frames hold while LPC runs under them: map()'s
  results so far (over an array and a mapping, whose result the efun
  allocates before the callbacks and fills itself), filter() and
  sort_array() with callbacks that make garbage, call_other()'s arguments
  while the target loads and its create() makes garbage, a call_out's
  arguments;
- values the running LPC holds in each place the collector roots: outer
  frames' locals, half-built expressions on the value stack, closure
  cells, a destructed object's variables while its code runs on, class
  instances, a caught error's thrown value, a young mapping that grows
  while garbage is made around it;
- recursion with no loop, where the only safe points are calls and
  returns.
The helper objects are written to /test/tmp_gc_*.c by the first case and
removed by the last.

Usage: python tools/gen_gc_cases.py > tests/fixtures/cases/gc_cases.txt
"""


def esc(body):
    return body.replace("\\", "\\\\").replace("\n", "\\n").replace("\t", "\\t")


def lpc_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


# makes n*(n+1)/2 values of garbage: the todo item's quadratic append
CHURN = "int *churn(int n) { int *a = ({}); for (int i = 0; i < n; i++) a += ({ i }); return a; }"

HELPERS = {
    # a create() that makes garbage, and a function its callers pass fresh
    # arrays to
    "/test/tmp_gc_new.c": "int *made; void create() { made = ({}); for (int i = 0; i < 2000; i++) made += ({ i }); } mixed f(mixed *x) { return ({ x, sizeof(made), made[1999] }); }",
    # destructs itself, then keeps using its variables
    "/test/tmp_gc_self.c": "int *glob = ({}); int run() { destruct(this_object()); for (int i = 0; i < 2000; i++) glob += ({ i }); return sizeof(glob) + glob[1999]; }",
    # a call_out whose argument is a fresh array, run while garbage is made
    "/test/tmp_gc_co.c": CHURN + " mixed got; void cb(mixed *x) { churn(1500); got = ({ x, sizeof(churn(1500)) }); } void start() { call_out(\"cb\", 0, ({ \"arg\", allocate(3, 5) })); } mixed query() { return got; }",
}

cases = []


def case(name, body):
    cases.append((name, body))


case("gc setup helpers", " ".join(f"write_file({lpc_str(p)}, {lpc_str(src)}, 1);" for p, src in HELPERS.items()) + " return 1;")

case("gc append loop 40000",
     "mixed *a = ({}); for (int i = 0; i < 40000; i++) a += ({ i }); return ({ sizeof(a), a[0], a[20000], a[39999] });")
case("gc mapping copy loop",
     "mapping m = ([]); for (int i = 0; i < 3000; i++) m = m + ([ i : ({ i, i * 2 }) ]); int s = 0; foreach (int k, int *v in m) s += v[1]; return ({ sizeof(m), s, m[2999] });")
case("gc map array results survive callbacks",
     CHURN + " @@ return map(({ 1, 2, 3, 4 }), (: ({ $1, sizeof(churn(1500)), allocate($1, $1) }) :));")
case("gc map mapping results survive callbacks",
     CHURN + " @@ mapping r = map(([ \"a\": 1, \"b\": 2, \"c\": 3 ]), (: ({ $2, sizeof(churn(1500)), ({ $1 }) }) :)); return ({ r[\"a\"], r[\"b\"], r[\"c\"], sizeof(r) });")
case("gc filter keeps its input's elements",
     CHURN + " @@ return filter(({ ({ 1 }), ({ 2 }), ({ 3 }), ({ 4 }) }), (: sizeof(churn(1500)) && $1[0] % 2 :));")
case("gc sort_array comparator makes garbage",
     CHURN + " @@ return sort_array(({ ({ 3 }), ({ 1 }), ({ 4 }), ({ 2 }) }), (: sizeof(churn(700)) ? $1[0] - $2[0] : 0 :));")
case("gc call_other args while the target loads",
     "return \"/test/tmp_gc_new\"->f(({ allocate(3, 9), ({ \"fresh\" }) }));")
case("gc clone create makes garbage",
     "object o = clone_object(\"/test/tmp_gc_new\"); mixed r = o->f(({ ({ 1 }), ([ \"k\": ({ 2 }) ]) })); destruct(o); return ({ r[0][0], r[0][1][\"k\"], r[1], r[2] });")
case("gc destructed object keeps running",
     "object o = clone_object(\"/test/tmp_gc_self\"); return ({ o->run(), objectp(o) });")
case("gc call_out argument",
     "object o = clone_object(\"/test/tmp_gc_co\"); o->start(); test_callouts(); mixed r = o->query(); destruct(o); return r;")
case("gc outer frame locals",
     CHURN + " int count(mixed *a) { return sizeof(a) + sizeof(churn(2000)); } @@ mixed *mine = ({ ({ 1 }), ({ 2 }) }); mapping mm = ([ \"x\": ({ 3 }) ]); int n = count(({ 9 })); return ({ n, mine, mm[\"x\"] });")
case("gc half-built expression on the stack",
     CHURN + " @@ return ({ ({ \"left\" }), churn(2000)[1999], ([ \"mid\": ({ 1 }) ])[\"mid\"], churn(2000)[5], ({ \"right\" }) });")
case("gc closure cell",
     CHURN + " @@ mixed *keep = ({ \"kept\" }); function f = (: keep + ({ sizeof(churn(1500)) }) :); for (int i = 0; i < 3; i++) churn(1500); keep += ({ \"more\" }); return evaluate(f);")
case("gc many closures",
     "function g; for (int i = 0; i < 20000; i++) { int j = i; g = (: $1 + j :); } return evaluate(g, 1);")
case("gc class instances",
     "class pt { int x; int *hist; } @@ class pt p; class pt keep = new(class pt); keep->x = 7; for (int i = 0; i < 5000; i++) { p = new(class pt); p->x = i; p->hist = allocate(200); } keep->hist = ({ p->x, sizeof(p->hist) }); return ({ keep->x, keep->hist });")
case("gc caught error mid-loop",
     "mixed *a = ({}); mixed e; for (int i = 0; i < 3000; i++) { a += ({ i }); if (i == 2000) e = catch(error(\"boom\")); } return ({ sizeof(a), e, a[2999] });")
case("gc thrown value through frames",
     CHURN + " mixed *deep(int n) { mixed *a = churn(1500); if (n == 0) throw(({ \"thrown\", a[1499], ({ n }) })); return deep(n - 1); } @@ return catch(deep(4));")
case("gc young mapping grows among garbage",
     "mapping m = ([]); for (int i = 0; i < 30000; i++) { m[i] = ({ i, \"v\" + i }); allocate(100); } int ok = 1; for (int i = 0; i < 30000; i++) if (m[i][0] != i || m[i][1] != \"v\" + i) ok = 0; return ({ sizeof(m), ok });")
case("gc recursion without loops",
     "int *build(int n) { return n ? build(n - 1) + ({ n }) : ({}); } @@ int *r; for (int k = 0; k < 20; k++) r = build(400); return ({ sizeof(r), r[0], r[399] });")

case("gc remove helpers", " ".join(f"rm({lpc_str(p)});" for p in HELPERS) + " return 1;")

print("# HavokOS P1 #9 cases (todo.md: garbage collection inside one evaluation).")
print("# Generated by tools/gen_gc_cases.py, which says what each case covers;")
print("# one case per line, <name><TAB><body>, the body escaped as \\\\ \\n \\t.")
print("# Expected results in gc.expected.txt are the live Pike driver's own.")
for name, body in cases:
    print(f"{name}\t{esc(body)}")
