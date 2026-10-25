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
//   pike ref_cases.pike <havokos_pike_dir> -ds <ds_lib_dir> <cases.txt> > m4_ds.expected.txt
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
//
// With -ds, the same kind of case file runs on the Dead Souls 3.9 mudlib
// instead (todo.md HavokOS M4): the driver is configured from DS3.9's own
// mudos.cfg and boots only as far as its first step, the simul_efun object
// (no master, no preloads -- the Star side boots the same way), so cases
// can call the mudlib's own simul_efuns, real LPC built on the efun library.

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
    int ds = argv[2] == "-ds";
    string root = ds ? argv[3] : combine_path(tests, "minilib");
    mapping cfg = ds ? ([
        // E:/ds3.9/bin/mudos.cfg
        "name": "DeadSoulsNew", "master file": "/secure/daemon/master",
        "simulated efun file": "/secure/sefun/sefun", "include directories": "/secure/include:/include",
        "global include file": "<global.h>", "port": "6666",
    ]) : ([
        "name": "HavokTest", "master file": "/secure/master",
        "simulated efun file": "/secure/sefun", "include directories": "/include",
        "global include file": "<global.h>", "port": "6699",
    ]);
    // the Star driver never offers MCCP (NOTES.md deviation #13), which is
    // the reference with `havok mccp : 0`
    cfg["havok mccp"] = "0";
    object drv = compile_file(combine_path(pike_dir, "havok/driver.pike"))(root, cfg);
    drv->debug_level = 0;
    // The driver hooks the Star side has as efuns (efun_table.star
    // test_efun_codes(), todo.md HavokOS M5): a subclass of the reference's
    // own efun table adding them, installed before anything compiles, since
    // transpiled code binds __E at compile time. Each drives the driver the
    // way run_tests.pike's own Pike-level tests do.
    add_constant("__HavokEfunsBase", compile_file(combine_path(pike_dir, "havok/efuns.pike")));
    program test_efuns = compile_string(#"
        inherit __HavokEfunsBase;
        int test_hb(object self, int n) { for (int k = 0; k < n; k++) drv->heart_beat_tick(); return 0; }
        array test_hb_round(object self) {
            for (int k = 0; k < predef::sizeof(drv->hb_slots); k++) drv->heart_beat_slot_tick();
            predef::remove_call_out(drv->heart_beat_slot_tick);
            return predef::map(drv->hb_slots, predef::sizeof);
        }
        int test_callouts(object self) {
            int n;
            foreach (drv->pending_call_outs(), object c) if (drv->callouts[c->handle]) { drv->run_call_out(c->handle); n++; }
            return n;
        }
        int test_reset_cfg(object self, int r, int c, int lazy) {
            drv->reset_interval = r; drv->cleanup_interval = c; drv->lazy_resets = lazy; drv->now_sec = predef::time();
            return 0;
        }
        int test_set_reset_time(object self, object ob, int t) { if (drv->info[ob]) drv->info[ob]->reset_time = t; return 0; }
        int test_set_last_used(object self, object ob, int t) { if (drv->info[ob]) drv->info[ob]->last_used = t; return 0; }
        int test_reset_time(object self, object ob) { return drv->info[ob] ? drv->info[ob]->reset_time : 0; }
        int test_no_clean_up(object self, object ob) { return drv->info[ob] ? drv->info[ob]->no_clean_up : 0; }
        int test_sweep(object self) { drv->reset_sweep_once(); return 0; }
        mixed test_limited(object self, string fn, int usec) {
            drv->max_cost = usec;
            drv->begin_eval();
            mixed r;
            mixed err = catch { r = drv->call_other(self, self, fn, ({})); };
            drv->end_eval();
            drv->max_cost = 0;
            if (err) predef::throw(err);
            return r;
        }
        array test_eval_state(object self) { return ({ drv->eval_nest, drv->outoftime, !!drv->eval_deadline }); }
        // telnet hooks (todo.md HavokOS M6, efuns_net.star's header): the
        // reference's own Connection on a loopback socket, the client end
        // kept here, as run_tests.pike's fake_user() does; bytes cross in
        // the ~xx printable form
        Stdio.Port tel_port;
        int tel_portnum;
        mapping(int:array) tel = ([]);
        int tel_seq;
        string tel_dec(string s) {
            String.Buffer b = String.Buffer();
            string hex = \"0123456789abcdef\";
            for (int i = 0; i < predef::sizeof(s); i++) {
                int hi = i + 2 < predef::sizeof(s) ? predef::search(hex, s[i + 1..i + 1]) : -1;
                int lo = i + 2 < predef::sizeof(s) ? predef::search(hex, s[i + 2..i + 2]) : -1;
                if (s[i] == '~' && hi >= 0 && lo >= 0) {
                    b->putchar(hi * 16 + lo);
                    i += 2;
                } else b->putchar(s[i]);
            }
            return b->get();
        }
        string tel_enc(string s) {
            String.Buffer b = String.Buffer();
            foreach (s; ; int c) {
                if (c >= 32 && c < 127 && c != '~') b->putchar(c);
                else b->add(predef::sprintf(\"~%02x\", c & 255));
            }
            return b->get();
        }
        void tel_pump() { for (int i = 0; i < 10; i++) Pike.DefaultBackend(0.02); }
        array tel_link() {
            if (!tel_port) {
                tel_port = Stdio.Port(0, 0, \"127.0.0.1\");
                tel_portnum = (int)((tel_port->query_address() / \" \")[1]);
            }
            Stdio.File cli = Stdio.File();
            cli->connect(\"127.0.0.1\", tel_portnum);
            Stdio.File srv = tel_port->accept();
            cli->set_nonblocking();
            return ({ cli, srv });
        }
        string tel_read(Stdio.File cli) {
            tel_pump();
            string got = \"\";
            for (;;) {
                string d = cli->read(65536, 1);
                if (!d || !predef::sizeof(d)) break;
                got += d;
            }
            return got;
        }
        int test_tel_open(object self, object u) {
            if (!drv->lpc_objectp(u)) return 0;
            [Stdio.File cli, Stdio.File srv] = tel_link();
            object c = drv->net->Connection(srv, tel_portnum);
            drv->net->connections[c] = 1;
            c->user = u;
            drv->info[u]->conn = c;
            tel[++tel_seq] = ({ c, cli });
            return tel_seq;
        }
        int test_tel_connect(object self) {
            [Stdio.File cli, Stdio.File srv] = tel_link();
            object c = drv->net->Connection(srv, tel_portnum);
            tel[++tel_seq] = ({ c, cli });
            drv->net->start_session(c);
            return tel_seq;
        }
        object test_tel_user(object self, int id) {
            object c = tel[id] && tel[id][0];
            return c && !c->closed && drv->lpc_objectp(c->user) ? c->user : 0;
        }
        string test_tel_say(object self, int id, string s) {
            if (!tel[id]) return 0;
            tel[id][1]->write(tel_dec(s));
            return tel_enc(tel_read(tel[id][1]));
        }
        string test_tel_drain(object self, int id) { return tel[id] ? tel_enc(tel_read(tel[id][1])) : 0; }
        int test_tel_hangup(object self, int id) {
            if (!tel[id]) return 0;
            tel[id][1]->close();
            tel_pump();
            return 0;
        }
        int test_tel_tp(object self, mixed ob) { drv->cur_player = drv->lpc_objectp(ob) ? ob : 0; return 0; }
    ");
    drv->efuns = test_efuns(drv);
    add_constant("__E", drv->efuns);
    drv->compiler->set_efuns(drv->efuns->implemented());
    drv->compiler->cache_dir = combine_path(pike_dir, "runtime/test_cache");
    if (ds) {
        // boot()'s first step only (driver.pike boot_steps())
        drv->sefun_ob = drv->load_object(drv->compiler->sefun_path);
        drv->refresh_sefuns();
    } else if (!drv->boot()) { werror("boot failed\n"); return 1; }
    runner->drv = drv;

    if (argv[2] == "-extra" || ds) {
        foreach (Stdio.read_file(argv[ds ? 4 : 3]) / "\n", string line) {
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
