// Reference half of the M3 golden comparison (todo.md HavokOS M3): runs
// LPC snippets from HavokOS's own runtime test table
// (pike/tests/run_tests.pike, the `cases` array in main()) through the live
// Pike driver, exactly the way run_tests.pike's run_lpc() does, and prints
// each result in the canonical value form tools/run_cases.star prints for
// the Star VM.
//
// Recording the live driver's *actual* results, rather than copying the
// table's expected column, means the fixture says what the reference really
// does on this machine; the script also reports any case where the two
// disagree, so a reference regression can't slip into the fixture unseen.
//
//   pike ref_cases.pike <havokos_pike_dir> <selection.txt>  > m3.expected.txt
//   pike ref_cases.pike <havokos_pike_dir> -extra <cases.txt> > m3_extra.expected.txt
//
// selection.txt names one case per line (blank lines and `#` comments
// skipped); a line `error <name>` selects one of run_tests.pike's
// check_error() cases instead, which are not in the table and are listed
// here. Output: one line per case, `<name>\t<body>\t<value>`, with the body
// escaped like a string (\n \t \\) and the value in canonical form
// (see render()). An error is `ERR <message>`.
//
// With -extra, cases.txt holds this port's own edge cases, one per line as
// `<name>\t<escaped body>`, covering language corners the table doesn't
// (closures sharing locals, nested lvalues, varargs, switch fallthrough,
// ...). There is no expected column to check them against: the live
// reference's result *is* the expectation.

string esc_body(string s) {
    return replace(s, ({ "\\", "\n", "\t", "\r" }), ({ "\\\\", "\\n", "\\t", "\\r" }));
}

string unesc_body(string s) {
    String.Buffer b = String.Buffer();
    for (int i = 0; i < sizeof(s); i++) {
        if (s[i] == '\\' && i + 1 < sizeof(s)) {
            int d = s[++i];
            b->putchar(d == 'n' ? '\n' : d == 't' ? '\t' : d == 'r' ? '\r' : d);
        } else b->putchar(s[i]);
    }
    return b->get();
}

string esc(string s) {
    String.Buffer b = String.Buffer();
    b->putchar('"');
    foreach (s; ; int c) {
        if (c == '\\') b->add("\\\\");
        else if (c == '"') b->add("\\\"");
        else if (c == '\n') b->add("\\n");
        else if (c == '\t') b->add("\\t");
        else if (c == '\r') b->add("\\r");
        else if (c < 32 || c >= 127) b->add(sprintf("\\x%02x", c & 255));
        else b->putchar(c);
    }
    b->putchar('"');
    return b->get();
}

// Canonical value form, implemented identically by vm.star's render():
//   int 12 | float F2.7 (LPC's own (string) conversion) | string "..." |
//   array ({a,b}) | mapping ([k:v,...]) entries sorted by rendered key bytes |
//   object OB:/path#n | anything else (function) FN
// Undefined and 0 both print 0: run_tests.pike compares with equal(), which
// can't tell them apart either.
string render(mixed v) {
    if (intp(v)) return (string)v;
    if (floatp(v)) return "F" + (string)v;
    if (stringp(v)) return esc(v);
    if (arrayp(v)) return "({" + map(v, render) * "," + "})";
    if (mappingp(v)) {
        array(string) parts = ({});
        foreach (v; mixed k; mixed x) parts += ({ render(k) + ":" + render(x) });
        return "([" + sort(parts) * "," + "])";
    }
    return "FN";
}

string safe_name(string name) {
    return filter(name / "", lambda(string ch) {
        return has_value("abcdefghijklmnopqrstuvwxyz0123456789", lower_case(ch)); }) * "";
}

int main(int argc, array(string) argv) {
    string pike_dir = argv[1];
    string tests = combine_path(pike_dir, "tests");
    // run_tests.pike's own helpers (run_lpc/norm), its driver boot and its
    // case table, reused rather than re-typed: compile the runner as a
    // program, then lift the table literal out of its main().
    string src = Stdio.read_file(combine_path(tests, "run_tests.pike"));
    int a = search(src, "array(array) cases = ({");
    int b = search(src, "\n    });\n", a);
    if (a < 0 || b < 0) { werror("case table not found\n"); return 1; }
    string table = src[a + sizeof("array(array) cases = ") .. b + 6];
    array(array) cases = compile_string("array(array) t = " + table + ";")()->t;

    mapping(string:array) by_name = ([]);
    foreach (cases, array c) by_name[c[0]] = c;
    // check_error() cases (run_tests.pike main(), after the table)
    mapping(string:array) errors = ([
        "call_other on 0": ({ "call_other on 0", "object o; return o->f();", "call_other" }),
        "index of zero": ({ "index of zero", "mapping m; return m[\"x\"];", "index" }),
    ]);

    object runner = compile_string(src, combine_path(tests, "run_tests.pike"))();
    runner->here = tests;
    string root = combine_path(tests, "minilib");
    mapping cfg = ([
        "name": "HavokTest", "master file": "/secure/master",
        "simulated efun file": "/secure/sefun", "include directories": "/include",
        "global include file": "<global.h>", "port": "6699",
    ]);
    object drv = compile_file(combine_path(pike_dir, "havok/driver.pike"))(root, cfg);
    drv->debug_level = 0;
    drv->compiler->cache_dir = combine_path(pike_dir, "runtime/test_cache");
    if (!drv->boot()) { werror("boot failed\n"); return 1; }
    runner->drv = drv;

    if (argv[2] == "-extra") {
        foreach (Stdio.read_file(argv[3]) / "\n", string line) {
            line = replace(line, "\r", "");
            if (line == "" || line[0] == '#') continue;
            [string name, string ebody] = line / "\t";
            mixed got;
            mixed err = catch { got = runner->norm(runner->run_lpc(unesc_body(ebody), safe_name(name))); };
            write("%s\t%s\t%s\n", name, ebody, err ? "ERR " + esc(describe_error(err)) : render(got));
        }
        return 0;
    }

    int disagreements = 0;
    foreach (Stdio.read_file(argv[2]) / "\n", string line) {
        line = String.trim_all_whites(line);
        if (line == "" || line[0] == '#') continue;
        int is_error = has_prefix(line, "error ");
        string name = is_error ? line[6..] : line;
        array c = is_error ? errors[name] : by_name[name];
        if (!c) { werror("no such case: %s\n", line); return 1; }
        mixed got;
        mixed err = catch { got = runner->norm(runner->run_lpc(c[1], safe_name(name))); };
        string out;
        if (err) {
            string msg = describe_error(err);
            out = "ERR " + esc(msg);
            if (!is_error || !has_value(msg, c[2])) {
                disagreements++;
                werror("reference disagrees with its table: %s: %s", name, msg);
            }
        } else {
            out = render(got);
            if (is_error || !equal(got, c[2])) {
                disagreements++;
                werror("reference disagrees with its table: %s: got %s\n", name, out);
            }
        }
        write("%s%s\t%s\t%s\n", is_error ? "error " : "", name, esc_body(c[1]), out);
    }
    if (disagreements) werror("%d disagreement(s)\n", disagreements);
    return 0;
}
