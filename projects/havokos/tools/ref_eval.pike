// Reference half of the M6 parser transcript comparison (todo.md HavokOS
// M6): boot a mudlib on the live Pike driver as tools/ref_boot.pike does --
// the same efun stubs, so both drivers fail the same calls -- let its timers
// run for a while (Dead Souls finishes setting up in call_outs), then run an
// LPC file as the body of `mixed eval()` in a SECURE object, as the
// reference's own havok/eval.pike -f does. tools/boot_ds.star -eval is the
// Star side.
//
//   pike ref_eval.pike <havokos_pike_dir> <mudos.cfg> <mudlib dir> <stubs.txt> <wait seconds> <file.lpc>
//
// Prints `EVAL <result>` in the canonical value form (tools/ref_cases.pike
// render()). The file under test writes its own transcript into the mudlib.

mapping(string:string) read_config(string file) {
    mapping(string:string) cfg = ([]);
    foreach (replace(Stdio.read_file(file), "\r", "") / "\n", string line) {
        if (!sizeof(line) || line[0] == '#') continue;
        int c = search(line, ":");
        if (c < 0) continue;
        cfg[String.trim_all_whites(line[..c - 1])] = String.trim_all_whites(line[c + 1..]);
    }
    return cfg;
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

int main(int argc, array(string) argv) {
    string pike_dir = argv[1];
    mapping cfg = read_config(argv[2]);
    string root = argv[3];
    array(string) stubs = filter(map(replace(Stdio.read_file(argv[4]), "\r", "") / "\n", String.trim_all_whites), sizeof);
    float wait_secs = (float)argv[5];
    string body = Stdio.read_file(argv[6]);
    string p = cfg["external_port_1"];
    if (p) { string kind; int num; if (sscanf(p, "%s %d", kind, num) == 2) cfg["port"] = (string)num; }
    cfg["havok outbound sockets"] = "0";

    object drv = compile_file(combine_path(pike_dir, "havok/driver.pike"))(root, cfg);
    drv->debug_level = 0;
    add_constant("__HavokEfunsBase", compile_file(combine_path(pike_dir, "havok/efuns.pike")));
    string src = "inherit __HavokEfunsBase;\n";
    foreach (stubs, string n)
        src += sprintf("mixed %s(object self, mixed ... a) { fail(\"Efun %s() is not implemented by this driver.\\n\"); }\n", n, n);
    drv->efuns = compile_string(src)(drv);
    add_constant("__E", drv->efuns);
    drv->compiler->set_efuns(drv->efuns->implemented());
    drv->compiler->program_cache_dir = 0;
    if (!drv->boot()) { write("BOOT FAILED\n"); return 1; }
    int end = gethrtime() + (int)(wait_secs * 1e6);
    while (gethrtime() < end) Pike.DefaultBackend(0.1);

    string path = "/tmp/__havok_eval_0";
    string lpc = "#include <lib.h>\n#include <daemons.h>\nmixed eval() {\n" + body + "\n}\n";
    mixed res;
    mixed err = catch {
        drv->compiler->forget(path);
        program prog = drv->compiler->compile_program(path, lpc);
        object ob = prog();
        drv->register_object(ob, path, path, 0);
        drv->info[ob]->privs = "SECURE";
        drv->push(ob);
        res = ob->eval();
        drv->unwind(0);
        drv->destruct_object(0, ob);
    };
    drv->unwind(0);
    write("EVAL %s\n", err ? "ERR " + describe_error(err) : render(res));
    return 0;
}
