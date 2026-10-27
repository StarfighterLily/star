"""Generates tests/fixtures/cases/store_cases.txt (todo.md HavokOS P1 #10,
the SQLite save store: `havok save store : sqlite`, havok/savestore.pike and
its hooks in havok/efuns.pike's file efuns).

Two kinds of case:
- the reference's own save_store_tests() in pike/tests/run_tests.pike,
  ported: its check() bodies are LPC already and are copied; the Pike-level
  parts (swapping a store in, reading the disk past it, flushing, reopening
  the database, importing a mudlib into a new one) go through the
  test_store_*()/test_disk() hooks both case runners provide (savestore.star
  efun_store_test(), tools/ref_cases.pike), each doing what that test does
  by hand;
- this port's own edge cases, each probed against the live reference
  first: read_file() line ranges, read_bytes(), file_length() and
  write_bytes() on a stored save; saves into a missing directory; get_dir()
  forms and its -1 sizes over stored saves and disk files together; stat();
  a disk .o the store also holds (shadowed, listed once, removed with it);
  rename() of a text file to a save name and back, of a save into a
  directory, of a directory holding nested saves; cp() into a directory;
  restore_object()/rm() of a save that isn't there; write_file() appending
  to a save only the disk has; a save removed and written again before one
  commit, and deletes reaching the database.
Expected results (store.expected.txt) are whatever the live reference
returns, never hand-predicted. Every case runs against one store over
/test/tmp_saves.db, opened by the first case and removed by the cleanup
case; the import case makes its own.

What the cases avoid: mtimes (the clock), and the import's backup
directory's name and place, which differ by design (the reference's
pike/runtime/, here runtime/ beside the running exe; the hook compares what
was moved there and removes it).

Usage: python tools/gen_store_cases.py > tests/fixtures/cases/store_cases.txt
"""

CASES = []

def case(name, body):
    CASES.append((name, body))

DB = '"/test/tmp_saves.db"'
SAVER = 'object s = clone_object("/test/saver"); '

case("store: setup",
     'test_rmtree("/test/ss"); test_rmtree("/test/ss2"); test_rmtree("/test/ssx"); test_rmtree("/test/ssy"); '
     'rm(' + DB + '); return test_store_open(' + DB + ');')

# --- the reference's save_store_tests(), ported
case("store: save_object and restore_object go to the store, not the disk",
     'mkdir("/test/ss"); ' + SAVER + 's->save_to("/test/ss/one"); s->scramble(); '
     's->restore_from("/test/ss/one"); return s->state();')
case("store: nothing written to the disk",
     'return test_disk("/test/ss/one.o");')
case("store: file efuns see the save as a file",
     'mixed d = get_dir("/test/ss/", -1); string t = read_file("/test/ss/one.o"); '
     'return ({ file_size("/test/ss/one.o") == sizeof(t), d[0][0], d[0][1] == sizeof(t), stat("/test/ss/one.o")[0] == sizeof(t), '
     'strsrch(t, "#/test/saver.c") == 0, get_dir("/test/ss/*.o"), sizeof(read_bytes("/test/ss/one.o", 0, 5)) });')
case("store: write_file, cp, rename, rm",
     'write_file("/test/ss/two.o", "num 1\\n", 1); write_file("/test/ss/two.o", "str \\"x\\"\\n"); '
     'cp("/test/ss/two.o", "/test/ss/three.o"); cp("/test/ss/two.o", "/test/ss/two.txt"); '
     'rename("/test/ss/three.o", "/test/ss/four.o"); '
     'mixed r = ({ read_file("/test/ss/four.o"), file_size("/test/ss/three.o"), read_file("/test/ss/two.txt"), '
     'sort_array(get_dir("/test/ss/"), 1) }); '
     'rm("/test/ss/two.txt"); rm("/test/ss/four.o"); return r + ({ file_size("/test/ss/four.o"), get_dir("/test/ss/") });')
case("store: the copy to a .txt name went to the disk, the .o ones did not",
     'return ({ test_disk("/test/ss/two.o"), test_disk("/test/ss/two.txt") });')
case("store: a directory holding saves isn't empty; renaming it takes them along",
     'int a = rmdir("/test/ss"); int b = rename("/test/ss", "/test/ss2"); '
     'return ({ a, b, get_dir("/test/ss2/"), file_size("/test/ss/one.o"), file_size("/test/ss2/one.o") > 0 });')
case("store: disk saves still load; saving moves them into the store",
     'test_put("/test/ss2/old.o", "#/test/saver.c\\nnum 42\\n"); '
     + SAVER + 'int ok = s->restore_from("/test/ss2/old"); int n = s->state()[0]; '
     'int sz = file_size("/test/ss2/old.o"); s->save_to("/test/ss2/old"); '
     'return ({ ok, n, sz > 0, file_size("/test/ss2/old.o") > 0, sort_array(get_dir("/test/ss2/"), 1) });')
case("store: the disk copy is gone",
     'return test_disk("/test/ss2/old.o");')
case("store: valid_write still applies",
     'return catch(clone_object("/test/saver")->save_to("/secret/x"));')
case("store: find_files lists stored saves",
     'object o = clone_object("/test/finder"); o->find("/test/ss2", "*.o", ({})); test_sock_pump(o, "query_got"); '
     'mixed g = o->query_got(); destruct(o); return g;')
case("store: commits survive reopening",
     'test_store_flush(); return test_store_reopen(' + DB + ', "/test/ss2/two.o");')

# --- this port's edge cases
case("store: read_file ranges, read_bytes and file_length of a save",
     'write_file("/test/ss2/lines.o", "a\\nb\\nc\\nd\\n", 1); '
     'return ({ read_file("/test/ss2/lines.o", 2, 2), read_file("/test/ss2/lines.o", 3), read_file("/test/ss2/lines.o", 9), '
     'read_bytes("/test/ss2/lines.o", -4, 2), read_bytes("/test/ss2/lines.o", 2), file_length("/test/ss2/lines.o"), '
     'test_disk("/test/ss2/lines.o") });')
case("store: write_bytes into a save",
     'int a = write_bytes("/test/ss2/lines.o", 2, "XY"); int b = write_bytes("/test/ss2/lines.o", 100, "z"); '
     'int c = write_bytes("/test/ss2/lines.o", -2, "Q"); '
     'return ({ a, b, c, read_file("/test/ss2/lines.o"), file_size("/test/ss2/lines.o"), test_disk("/test/ss2/lines.o") });')
case("store: write_bytes makes a new save",
     'int a = write_bytes("/test/ss2/new.o", 0, "fresh"); mixed r = ({ a, read_file("/test/ss2/new.o"), test_disk("/test/ss2/new.o") }); '
     'rm("/test/ss2/new.o"); rm("/test/ss2/lines.o"); return r + ({ file_size("/test/ss2/new.o"), file_size("/test/ss2/lines.o") });')
case("store: saves into a missing directory fail",
     SAVER + 'return ({ s->save_to("/test/nodir/x"), write_file("/test/nodir/y.o", "z"), cp("/test/ss2/two.o", "/test/nodir/z.o"), '
     'write_bytes("/test/nodir/w.o", 0, "q"), rename("/test/ss2/two.o", "/test/nodir/two.o"), file_size("/test/nodir/x.o"), '
     'file_size("/test/ss2/two.o") > 0, get_dir("/test/nodir/") });')
case("store: get_dir forms over stored saves and disk files",
     'test_put("/test/ss2/plain.txt", "hello"); '
     'mixed d = sort_array(get_dir("/test/ss2/", -1), (: strcmp($1[0], $2[0]) :)); '
     'return ({ map(d, (: ({ $1[0], $1[1] > 0 ? ($1[0] == "plain.txt" ? $1[1] : 1) : $1[1] }) :)), '
     'get_dir("/test/ss2/o*.o"), get_dir("/test/ss2/one.o"), get_dir("/test/ss2/two.?"), get_dir("/test/ss2"), '
     'get_dir("/test/ss2/nosuch.o"), get_dir("/test/ss2/*.txt") });')
case("store: stat of a save",
     'mixed st = stat("/test/ss2/one.o"); '
     'return ({ sizeof(st), st[0] == file_size("/test/ss2/one.o"), st[1] > 0, st[2], stat("/test/ss2/nosuch.o") });')
case("store: restore_object and rm of a save that isn't there",
     SAVER + 'return ({ s->restore_from("/test/ss2/nosuch"), rm("/test/ss2/nosuch.o"), file_size("/test/ss2/nosuch.o") });')
case("store: rename a text file to a save name and back",
     'test_put("/test/ss2/t.txt", "num 5\\n"); int a = rename("/test/ss2/t.txt", "/test/ss2/t.o"); '
     'mixed r = ({ a, test_disk("/test/ss2/t.txt"), test_disk("/test/ss2/t.o"), read_file("/test/ss2/t.o") }); '
     'int b = rename("/test/ss2/t.o", "/test/ss2/t2.txt"); '
     'r += ({ b, file_size("/test/ss2/t.o"), test_disk("/test/ss2/t2.txt") }); rm("/test/ss2/t2.txt"); return r;')
case("store: rename and cp a save into a directory",
     'mkdir("/test/ss2/sub"); int a = rename("/test/ss2/one.o", "/test/ss2/sub"); '
     'mixed r = ({ a, get_dir("/test/ss2/sub/"), file_size("/test/ss2/one.o") }); '
     'int b = cp("/test/ss2/sub/one.o", "/test/ss2"); int c = rename("/test/ss2/sub/one.o", "/test/ss2/sub/moved.o"); '
     'r += ({ b, c, get_dir("/test/ss2/sub/"), file_size("/test/ss2/one.o") > 0, test_disk("/test/ss2/one.o") }); '
     'rm("/test/ss2/sub/moved.o"); return r + ({ rmdir("/test/ss2/sub") });')
case("store: rename a directory holding nested saves",
     'mkdir("/test/ssx"); mkdir("/test/ssx/a"); ' + SAVER + 's->save_to("/test/ssx/a/deep"); s->save_to("/test/ssx/top"); '
     'int a = rename("/test/ssx", "/test/ssy"); '
     'mixed r = ({ a, get_dir("/test/ssy/"), get_dir("/test/ssy/a/"), file_size("/test/ssx/a/deep.o"), s->restore_from("/test/ssy/a/deep") }); '
     'rm("/test/ssy/a/deep.o"); rm("/test/ssy/top.o"); return r + ({ rmdir("/test/ssy/a"), rmdir("/test/ssy") });')
case("store: write_file appends to a save only the disk has",
     'test_put("/test/ss2/disk.o", "num 1\\n"); int a = write_file("/test/ss2/disk.o", "str \\"y\\"\\n"); '
     'mixed r = ({ a, read_file("/test/ss2/disk.o"), test_disk("/test/ss2/disk.o") }); rm("/test/ss2/disk.o"); '
     'return r + ({ file_size("/test/ss2/disk.o") });')
case("store: a disk .o the store also holds is shadowed and removed with it",
     'test_put("/test/ss2/two.o", "stale on disk\\n"); '
     'mixed r = ({ read_file("/test/ss2/two.o"), sizeof(filter(get_dir("/test/ss2/"), (: $1 == "two.o" :))), '
     'file_size("/test/ss2/two.o") == sizeof(read_file("/test/ss2/two.o")) }); '
     'int a = rm("/test/ss2/two.o"); return r + ({ a, test_disk("/test/ss2/two.o"), file_size("/test/ss2/two.o") });')
case("store: a save removed and written again, and deletes, reach the database",
     SAVER + 'rm("/test/ss2/one.o"); s->save_to("/test/ss2/one"); test_store_flush(); '
     'mixed r = test_store_reopen(' + DB + ', "/test/ss2/one.o"); '
     'return ({ r[0], strsrch(r[1], "#/test/saver.c") == 0 });')

# (whether rm() of the database then succeeds isn't compared: the
# reference's Pike keeps the closed store's SQLite handle until a later
# collection, and Windows won't delete an open file, so its rm() fails)
case("store: cleanup",
     'foreach (string f in ({ "old", "one" })) rm("/test/ss2/" + f + ".o"); rm("/test/ss2/plain.txt"); '
     'int a = rmdir("/test/ss2"); test_store_flush(); mixed r = test_store_reopen(' + DB + ', "/test/ss2/one.o"); '
     'test_store_close(); rm(' + DB + '); return ({ a, r });')

# --- importing (run_tests.pike's last part), its own database
case("store: a new database imports the .o files and moves the originals out",
     'test_rmtree("/test/tmp_import"); test_put("/test/tmp_import/top.o", "num 1\\n"); '
     'test_put("/test/tmp_import/a/b/deep.o", "num 2\\n"); test_put("/test/tmp_import/a/notes.txt", "not a save\\n"); '
     'rm("/test/tmp_import.db"); mixed r = test_store_import("/test/tmp_import", "/test/tmp_import.db"); '
     'r += ({ test_disk("/test/tmp_import/top.o"), test_disk("/test/tmp_import/a/b/deep.o"), test_disk("/test/tmp_import/a/notes.txt") }); '
     'test_rmtree("/test/tmp_import"); rm("/test/tmp_import.db"); return r;')
case("store: an existing database imports nothing",
     'test_put("/test/tmp_import/top.o", "num 1\\n"); rm("/test/tmp_import.db"); '
     'test_store_open("/test/tmp_import.db"); test_store_close(); '
     'mixed r = test_store_import("/test/tmp_import", "/test/tmp_import.db"); '
     'r += ({ test_disk("/test/tmp_import/top.o") }); test_rmtree("/test/tmp_import"); rm("/test/tmp_import.db"); return r;')

def esc(s):
    return s.replace("\\", "\\\\").replace("\n", "\\n").replace("\t", "\\t")

print("# HavokOS save store cases (todo.md HavokOS P1 #10): `havok save store :")
print("# sqlite`, the reference's own save_store_tests() ported and this port's edge")
print("# cases, through the test_store_*()/test_disk() hooks.")
print("# GENERATED by tools/gen_store_cases.py -- edit that, not this file. One case")
print("# per line, <name><TAB><body>; expected results in store.expected.txt are the")
print("# live Pike driver's own (tools/ref_cases.pike -extra).")
for name, body in CASES:
    print(name + "\t" + esc(body.strip()))
