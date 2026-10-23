// Parser edge cases DS3.9 never exercises (run_ast_cases_test.ps1). Each is
// parsed by the live Pike reference and the frozen dump is the contract.
// This file only has to *parse*, not make sense.

private inherit "/lib/" + "base" + ".c" base_lbl;
inherit "/lib/plain";
nosave inherit "/lib/x" "/y";

class Pair { int a, *b; static string array c; mixed d; };
struct Other { unknown u; };
class Pair p1, *p2;
static nomask varargs private int *xs = ({ 1, 2 }), y, *zs;
string array names;
mapping m = ([ "k", "v": 2, 3 ]);
float f = 1.5;
int h = 0x1F + 'a' + '\n';

int proto(int, string *);
varargs void defaults(int a: (: 5 :), string b: (: "x" :), mixed rest...) {}
void refs(int ref a, ref mixed *b, varargs int c, const int d) {}
void nothing(void) {}

mixed cases(mixed x) {
    switch (x) {
    case 1..5: break;
    case ..3: break;
    case 7..: break;
    case "a": case -1: return 1;
    default: x++;
    }
    return x;
}

mixed fptrs(object ob) {
    function f1 = (: ::create :);
    function f2 = (: efun::write, "x", :);
    function f3 = (: base_lbl::setup, 1, 2 :);
    function f4 = (: tell, 1, :);
    function f5 = (: $1 + $(ob) :);
    function f6 = function(int a, string b: (: "d" :)) { return a; };
    return ({ f1, f2, f3, f4, f5, f6 });
}

mixed exprs(object ob, mixed *a, mapping m2) {
    int status;
    status = 1;
    mixed v = ob->(query_name())(1, 2);
    mixed w = ob->("x");
    ob->prop = 3;
    ob->list[2] = 4;
    !v = ob->q();
    v && w = 5;
    v = a[<1] + a[1..<2] + a[..3] + a[<3..] + a[2..] + a[..<1] + a[<2..<1];
    v = (int)w + (string *)a + (class Pair)w + (status) + 1 + (float array)a;
    v = *ob;
    v = &w;
    v = (*v)(1)(2);
    v = new(class Pair, a: 1, b: ({ 2 }));
    v = new(class Other);
    v = new("/obj/thing", 1);
    v = parse_command("get x", ob, "%s", v);
    sscanf("1 2", "%d %d", v, w);
    v = time_expression(v + 1);
    v = time_expression { v++; };
    v = catch(error("x"));
    v = catch { throw(1); };
    v = ({ a..., 1, }) + f(a...) + g(ref v);
    v = (v ? w : v, 2);
    v <<= 2; v >>= 1; v ^= 1; v |= 2; v &= 3; v %= 4; v /= 5; v *= 6; v -= 7; v += 8;
    v = +v - -v + ~v + ++v + --v + v++ + v--;
    v = 1 || 2 && 3 | 4 ^ 5 & 6 == 7 != 8 < 9 <= 10 > 11 >= 12 << 13 >> 14 + 15 - 16 * 17 / 18 % 19;
    v = ::create() + ::create + base_lbl::setup(1) + base_lbl::setup;
    v = 1.25e2 + .5 + "con" "cat" + 'q';
    return default;
}

void stmts(mixed *arr, mapping mp) {
    int i, j;
    for (int k = 0, l = 1; ; ) break;
    for (;;) continue;
    for (i = 0, j = 2; i < 3; i++, j--) ;
    foreach (ref string s in arr) s = "";
    foreach (mixed k, mixed v in mp) ;
    foreach (i, j in mp) ;
    foreach (int *q in arr) ;
    do i++; while (i < 3);
    while (0) {}
    if (i) ; else if (j) { } else i = 2;
    { static int z = 1; class Pair loc; function g; }
    ;
}
