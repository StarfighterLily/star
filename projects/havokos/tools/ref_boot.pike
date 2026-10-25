// Reference half of the M5 boot comparison (todo.md HavokOS M5): boot a
// mudlib on the live Pike driver the way its own boot.pike does -- the
// simul_efun object, the master, epilog() and every preload(), no network --
// then print what the boot left behind in the canonical form
// tools/boot_ds.star prints for the Star VM (see that file's header).
//
//   pike ref_boot.pike <havokos_pike_dir> <mudos.cfg> <mudlib dir> <stubs.txt>
//
// stubs.txt names the reference's efuns the Star VM doesn't implement yet
// (`boot_ds.exe -unimplemented`: the verb parser, ed, sockets, the network
// layer, ...). Each is replaced here by one raising the reference's own
// "Efun X() is not implemented by this driver." error -- what the Star VM
// raises for it -- so both drivers fail the same calls and the comparison
// measures the object model, not which later milestone is missing. The
// stubs go in a subclass of the reference's efun table installed before
// anything compiles (transpiled code binds __E at compile time).

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

string no_clone_no(string n) { return (n / "#")[0] + (has_value(n, "#") ? "#" : ""); }

int main(int argc, array(string) argv) {
    string pike_dir = argv[1];
    mapping cfg = read_config(argv[2]);
    string root = argv[3];
    array(string) stubs = filter(map(replace(Stdio.read_file(argv[4]), "\r", "") / "\n", String.trim_all_whites), sizeof);
    // boot.pike: the first telnet port is the driver's port
    string p = cfg["external_port_1"];
    if (p) { string kind; int num; if (sscanf(p, "%s %d", kind, num) == 2) cfg["port"] = (string)num; }

    object drv = compile_file(combine_path(pike_dir, "havok/driver.pike"))(root, cfg);
    drv->debug_level = 0;
    add_constant("__HavokEfunsBase", compile_file(combine_path(pike_dir, "havok/efuns.pike")));
    string src = "inherit __HavokEfunsBase;\n";
    foreach (stubs, string n)
        src += sprintf("mixed %s(object self, mixed ... a) { fail(\"Efun %s() is not implemented by this driver.\\n\"); }\n", n, n);
    drv->efuns = compile_string(src)(drv);
    add_constant("__E", drv->efuns);
    drv->compiler->set_efuns(drv->efuns->implemented());
    // compile from source every time, like the Star side
    drv->compiler->program_cache_dir = 0;

    int t0 = time();
    if (!drv->boot()) write("BOOT FAILED\n");
    remove_call_out(drv->heart_beat_slot_tick);
    remove_call_out(drv->reset_sweep);

    array(string) objs = ({});
    int nclone, nhb;
    foreach (drv->info; object ob; object i) {
        string line = sprintf("OBJ %s %s %s", no_clone_no(i->name), stringp(i->privs) ? i->privs : "0",
                              drv->lpc_objectp(i->env) ? no_clone_no(drv->info[i->env]->name) : "-");
        if (i->hb) { line += " HB"; nhb++; }
        if (i->living) line += " LIVING";
        if (i->clone) nclone++;
        objs += ({ line });
    }
    foreach (sort(objs), string l) write("%s\n", l);
    write("COUNT objects %d\n", sizeof(drv->info));
    write("COUNT clones %d\n", nclone);
    write("COUNT call_outs %d\n", sizeof(drv->callouts));
    write("COUNT heart_beats %d\n", nhb);
    write("LOG boot took %d s\n", time() - t0);
    return 0;
}
