// Reference half of the M6 login comparison (todo.md HavokOS M6): the live
// Pike driver serving telnet on a mudlib, set up as tools/ref_boot.pike sets
// it up -- the efuns the Star VM doesn't have yet stubbed with the
// reference's own "not implemented" error, so both drivers fail the same
// calls -- and with `havok mccp : 0`, since the Star driver never offers
// MCCP (NOTES.md deviation #13). tools/telnet_script.exe then logs in to
// either driver with the same script.
//
//   pike ref_serve.pike <havokos_pike_dir> <mudos.cfg> <mudlib dir> <stubs.txt> <port>

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

int main(int argc, array(string) argv) {
    string pike_dir = argv[1];
    mapping cfg = read_config(argv[2]);
    string root = argv[3];
    array(string) stubs = filter(map(replace(Stdio.read_file(argv[4]), "\r", "") / "\n", String.trim_all_whites), sizeof);
    int port = (int)argv[5];
    cfg["port"] = (string)port;
    cfg["havok mccp"] = "0";
    cfg["havok outbound sockets"] = "0";

    object drv = compile_file(combine_path(pike_dir, "havok/driver.pike"))(root, cfg);
    drv->debug_level = 1;
    add_constant("__HavokEfunsBase", compile_file(combine_path(pike_dir, "havok/efuns.pike")));
    string src = "inherit __HavokEfunsBase;\n";
    foreach (stubs, string n)
        src += sprintf("mixed %s(object self, mixed ... a) { fail(\"Efun %s() is not implemented by this driver.\\n\"); }\n", n, n);
    drv->efuns = compile_string(src)(drv);
    add_constant("__E", drv->efuns);
    drv->compiler->set_efuns(drv->efuns->implemented());
    drv->compiler->program_cache_dir = 0;
    if (!drv->boot()) { werror("BOOT FAILED\n"); return 1; }
    if (!drv->net->listen(port)) return 1;
    return -1;
}
