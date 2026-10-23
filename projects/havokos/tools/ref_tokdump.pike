// Reference half of the M1 golden comparison: runs the live HavokOS Pike
// front end (pike/lpc/preprocess.pike -> lexer.pike::tokenize, exactly as
// pike/lpc/tools/parse_sweep.pike drives them) and prints the canonical
// token format documented in tokdump.star.
//
//   pike ref_tokdump.pike <havokos_pike_lpc_dir> <mudlib_root> <file_list.txt>
//   pike ref_tokdump.pike <havokos_pike_lpc_dir> <mudlib_root> -v <vpath>
// A trailing -nolines drops line numbers, as in tokdump.star.

string esc(string s) {
    String.Buffer b = String.Buffer();
    foreach (s; ; int c) {
        if (c == '\\') b->add("\\\\");
        else if (c == '\n') b->add("\\n");
        else if (c == '\t') b->add("\\t");
        else if (c == '\r') b->add("\\r");
        else if (c < 32 || c >= 127) b->add(sprintf("\\x%02x", c & 255));
        else b->putchar(c);
    }
    return b->get();
}

string value_of(array t) {
    switch (t[0]) {
    case "int": return (string)t[1];
    case "float": return (string)(int)(t[1] * 1000000.0);
    case "str": return esc(t[1]);
    case "dollar": return (string)t[1];
    case "eof": return "0";
    default: return t[1];
    }
}

int with_lines = 1;

array(string) dump_lines(array(array) toks) {
    array(string) lines = ({});
    for (int i = 0; i < sizeof(toks); i++) {
        array t = toks[i];
        mixed v = t[1];
        if (t[0] == "str") {
            while (i + 1 < sizeof(toks) && toks[i + 1][0] == "str") { i++; v += toks[i][1]; }
        }
        string pos = with_lines ? sprintf("%s:%d", t[3], t[2]) : t[3];
        lines += ({ sprintf("%s %s %s", pos, t[0], value_of(({ t[0], v }))) });
    }
    return lines;
}

int fnv(array(string) lines) {
    int h = 2166136261;
    foreach (lines, string l) {
        foreach (l + "\n"; ; int c) h = ((h ^ (c & 255)) * 16777619) & 0xffffffff;
    }
    return h;
}

int main(int argc, array(string) argv) {
    string lpc = argv[1], root = argv[2];
    if (argv[-1] == "-nolines") { with_lines = 0; argv = argv[..sizeof(argv) - 2]; }
    object pp = compile_file(lpc + "/preprocess.pike")(root);
    object lexer = compile_file(lpc + "/lexer.pike")();
    if (argv[3] == "-v") {
        string vp = argv[4];
        array toks;
        mixed err = catch { toks = lexer->tokenize(pp->preprocess(vp)[0], vp); };
        if (err) { write("FAIL %s", describe_error(err)); return 1; }
        foreach (dump_lines(toks), string l) write("%s\n", l);
        return 0;
    }
    foreach (Stdio.read_file(argv[3]) / "\n", string vp) {
        vp = String.trim_all_whites(vp);
        if (!sizeof(vp)) continue;
        array toks;
        mixed err = catch { toks = lexer->tokenize(pp->preprocess(vp)[0], vp); };
        if (err) { write("%s FAIL\n", vp); continue; }
        array(string) lines = dump_lines(toks);
        write("%s OK %d %d\n", vp, sizeof(lines), fnv(lines));
    }
    return 0;
}
