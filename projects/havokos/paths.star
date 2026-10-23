# Mudlib virtual-path helpers -- Pike's `combine_path`/`dirname` as the
# HavokOS reference uses them (`lpc/preprocess.pike`, `lpc/compiler.pike`).
# Paths are mudlib-virtual: always `/`-separated, rooted at the mudlib
# directory, never containing a drive letter.

# Pike `dirname("/a/b/c.c")` -> "/a/b"; `dirname("/x")` -> "/".
fn dirname(p: str) -> str:
    let parts = str_split(p, "/")
    if parts.len() <= 1:
        return ""
    let mut keep: List<str> = List<str>()
    for i in 0..parts.len() - 1:
        keep.push(parts[i])
    let d = str_join(keep, "/")
    if d == "":
        "/"
    else:
        d

# Pike `combine_path(base, rel)`: `rel` absolute replaces `base`; otherwise
# appended. The result is canonicalised: no empty, "." or ".." segments
# (".." at the root stays at the root), leading "/" kept if `base` (or an
# absolute `rel`) had one, no trailing "/" unless `rel` ended with one.
fn combine_path(base: str, rel: str) -> str:
    let full = if str_starts_with(rel, "/") or base == "": rel else: concat(concat(base, "/"), rel)
    let absolute = str_starts_with(full, "/")
    let trailing = str_ends_with(rel, "/") and rel != "/"
    let parts = str_split(full, "/")
    let mut out: List<str> = List<str>()
    for i in 0..parts.len():
        let s = parts[i]
        if s == "" or s == ".":
            continue
        if s == "..":
            if out.len() > 0 and out[out.len() - 1] != "..":
                out.pop()
            elif !absolute:
                out.push(s)
            continue
        out.push(s)
    let mut r = str_join(out, "/")
    if absolute:
        r = concat("/", r)
    if trailing and !str_ends_with(r, "/"):
        r = concat(r, "/")
    r
