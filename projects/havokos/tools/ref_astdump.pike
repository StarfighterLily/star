// Reference half of the M2 golden comparison: runs the live HavokOS Pike
// front end and parser (pike/lpc/preprocess.pike -> lexer.pike::tokenize ->
// parser.pike::parse_program, exactly as pike/lpc/tools/parse_sweep.pike
// drives them) and prints each file's AST in the canonical form documented
// in ast.star: one line per top-level node, every mapping printed with its
// keys sorted, so nothing about this dump is hand-ordered.
//
//   pike ref_astdump.pike <havokos_pike_lpc_dir> <mudlib_root> <file_list.txt>
//   pike ref_astdump.pike <havokos_pike_lpc_dir> <mudlib_root> -v <vpath>
// A trailing -nolines drops every "line" key, as in astdump.star.

int with_lines = 1;

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

string dump(mixed v) {
    if (mappingp(v)) {
        array(string) parts = ({});
        foreach (sort(indices(v)), string k) {
            if (k == "line" && !with_lines) continue;
            parts += ({ k + "=" + dump(v[k]) });
        }
        return "{" + parts * " " + "}";
    }
    if (arrayp(v)) return "[" + map(v, dump) * " " + "]";
    if (multisetp(v)) return "<" + map(sort(indices(v)), dump) * " " + ">";
    if (stringp(v)) return esc(v);
    if (floatp(v)) return "f" + (string)(int)(v * 1000000.0);
    if (intp(v)) return (string)v;
    error("unexpected AST value %O\n", v);
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
    program parser_p = compile_file(lpc + "/parser.pike");
    array(string) parse(string vp) {
        array(mapping) ast = parser_p()->parse_program(lexer->tokenize(pp->preprocess(vp)[0], vp));
        return map(ast, dump);
    };
    if (argv[3] == "-v") {
        array(string) lines;
        mixed err = catch { lines = parse(argv[4]); };
        if (err) { write("FAIL %s", describe_error(err)); return 1; }
        foreach (lines, string l) write("%s\n", l);
        return 0;
    }
    foreach (Stdio.read_file(argv[3]) / "\n", string vp) {
        vp = String.trim_all_whites(vp);
        if (!sizeof(vp)) continue;
        array(string) lines;
        mixed err = catch { lines = parse(vp); };
        if (err) { write("%s FAIL\n", vp); continue; }
        write("%s OK %d %d\n", vp, sizeof(lines), fnv(lines));
    }
    return 0;
}
