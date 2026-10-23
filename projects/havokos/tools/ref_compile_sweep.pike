// Reference half of the M3 compile sweep (todo.md HavokOS M3): runs the
// live HavokOS compiler front half -- preprocess, parse, resolve inherits,
// emit (compiler.pike transpile()) -- on every listed DS3.9 file and prints
// what tools/compile_sweep.star prints for the Star compiler:
//
//   <vpath> OK <nfuncs> <funcs hash> <nvars> <vars hash>
//   <vpath> FAIL
//
// <nfuncs>/<funcs hash> cover the program's `all_funcs` meta (every
// non-private function name it defines or inherits, each marked def or
// proto), <nvars>/<vars hash> its `all_vars` (every visible variable name):
// the tables an inheriting program's name resolution reads, so matching
// them on the real mudlib checks the Star compiler's inherit handling, not
// just that it doesn't fail. The hashes are order-independent sums of
// FNV-1a over "name=def"/"name=proto" (or the bare variable name), since the
// Star side keeps no sorted order of its own.
//
// Both sides compile the simul_efun program first and resolve every later
// file against its function names, as after a boot -- without them a call
// to a DS simul_efun that shadows an efun (query_charmode) is sent to the
// efun, and the reference's Pike compile then rejects the efun's arity. No
// object is made on either side.
//
//   pike ref_compile_sweep.pike <havokos_pike_dir> <mudlib_root> <file_list.txt> <cache_dir>

int fnv(string s) {
    int h = 2166136261;
    foreach (s; ; int c) h = ((h ^ (c & 255)) * 16777619) & 0xffffffff;
    return h;
}

int main(int argc, array(string) argv) {
    string pd = argv[1], root = argv[2];
    mapping cfg = ([ "name": "Sweep", "master file": "/secure/daemon/master",
        "simulated efun file": "/secure/sefun/sefun",
        "include directories": "/secure/include:/include",
        "global include file": "<global.h>", "port": "6666" ]);
    object drv = compile_file(pd + "/havok/driver.pike")(root, cfg);
    drv->debug_level = 0;
    drv->compiler->cache_dir = argv[4];
    catch { drv->compiler->compile_program(drv->compiler->sefun_path); };
    drv->refresh_sefuns();
    foreach (Stdio.read_file(argv[3]) / "\n", string line) {
        string vp = String.trim_all_whites(line);
        if (vp == "") continue;
        string path = has_suffix(vp, ".c") ? vp[..sizeof(vp) - 3] : vp;
        mapping meta;
        mixed err = catch { meta = drv->compiler->transpile(path)[1]; };
        if (err || !meta) { write("%s FAIL\n", vp); continue; }
        int fh = 0, vh = 0;
        foreach (meta->all_funcs; string f; string kind)
            fh = (fh + fnv(f + "=" + (kind == "def" ? "def" : "proto"))) & 0xffffffff;
        foreach (indices(meta->all_vars), string v) vh = (vh + fnv(v)) & 0xffffffff;
        write("%s OK %d %d %d %d\n", vp, sizeof(meta->all_funcs), fh, sizeof(meta->all_vars), vh);
    }
    return 0;
}
