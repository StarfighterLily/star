"""Generates tests/fixtures/cases/m7_db_cases.txt (todo.md HavokOS P1 #7,
the reference's SQLite efuns: db_open()/db_query()/db_info()/db_close(),
havok/sqldb.pike).

Two kinds of case:
- the reference's own sqlite_tests() in pike/tests/run_tests.pike, ported:
  its check()/check_error() bodies are LPC already and are copied (two
  adjusted, see below); its last two checks drive the efuns from Pike as
  two different objects, so they run here through a helper object
  (/test/tmp_m7_db.c, written by the first case, removed by the last) whose
  clones open and query handles of their own;
- this port's own edge cases, each probed against the live reference
  first: trimming, placeholder numbering and its count check, named
  bindings, the binding errors, trailing statements, the SELECT wrapper's
  column names, non-SELECT statements' string rows, db_info() after each
  kind of statement, handles and ownership, db_open()'s path checks.
Expected results (m7_db.expected.txt) are whatever the live reference
returns, never hand-predicted.

What the cases avoid, because the two drivers differ by design (NOTES.md
deviations; most of it #22, the reference's Pike bundling SQLite 3.6.0
where this driver links 3.54.1):
- SQL that 3.6.0 doesn't have: multi-row VALUES, VALUES and WITH as
  statements, RETURNING;
- messages 3.6.0 words differently: errors raised while a statement runs
  (constraint violations, integer overflow, "cannot commit") are its
  legacy "SQL logic error or missing database", and a statement cut off
  inside a comment is "near ...: syntax error" rather than "incomplete
  input";
- answers 3.6.0 gives differently: table_info's declared types as written
  (3.54 upper-cases them) and its notnull flag (99 for 1), index_list's
  column count, DELETE without WHERE counting 0 changes, the column name of
  an unaliased `'x' || 'y'`;
- binding integers past 2^31 (the reference's Pike is a 32-bit build, so
  they are bignums it can't bind), floats that need more than single
  precision (#3), infinity (its quote() literal "Inf" parses as 0.0);
- characters above U+00FF and Latin-1 bytes in bound text (the reference
  encodes its strings as UTF-8, #14), NUL bytes in blobs (#7);
- wrongly typed efun arguments as constants: the reference rejects
  db_open(5) when compiling, this compiler has no efun prototypes, so
  those go through a `mixed` variable.
The reference's first check binds sprintf("%c", 0x263a), a wide string,
so its port binds an ASCII string instead; its third reads table_info's
type of `a integer`, so its port declares `a INTEGER`.

Usage: python tools/gen_m7_db_cases.py > tests/fixtures/cases/m7_db_cases.txt
"""

def lpc_str(src):
    """An LPC string literal holding src."""
    return '"' + src.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'

CASES = []

def case(name, body):
    CASES.append((name, body))

H = "/test/tmp_m7_db"
HELPER = r'''// one object's handles, for the M7 SQLite ownership cases
int open() { return db_open(":memory:"); }
mixed query(int h, string sql) { mixed r; mixed e = catch(r = db_query(h, sql)); return e || r; }
mixed info(int h) { mixed r; mixed e = catch(r = db_info(h)); return e || r; }
mixed close(int h) { mixed r; mixed e = catch(r = db_close(h)); return e || r; }
'''
case("m7db setup helper",
     "write_file(%s, %s, 1); load_object(%s); return 1;" % (lpc_str(H + ".c"), lpc_str(HELPER), lpc_str(H)))

M = 'int db = db_open(":memory:"); '

# --- the reference's sqlite_tests(), ported
case("db_query: typed values back, ? placeholders",
     M + 'db_query(db, "create table t (id integer primary key, name text, n real, k integer)"); '
     'db_query(db, "insert into t (name, n, k) values (?, ?, ?)", "o\'neil ? -- not a comment", 2.5, 7); '
     'db_query(db, "insert into t (name, n) values (?, null);", "smile"); '
     'return db_query(db, "select id, name, n, k, n is null, \'?\' from t order by id desc");')
case("db_query: named bindings, db_info",
     M + 'mapping i; '
     'db_query(db, "create table t (a, b)"); '
     'db_query(db, "insert into t values (:a, :b)", ([ "a": 1, ":b": "x" ])); '
     'db_query(db, "insert into t values (:a, :b)", ([ "a": 2, "b": "y" ])); '
     'i = db_info(db); '
     'return ({ db_query(db, "select count(*) as n, max(a) from t where b != :b", ([ "b": "z" ])), '
     'i["insert_id"], i["changes"], db_info(db)["columns"], i["file"] });')
case("db_query: other statements give strings, empty results",
     M + 'db_query(db, "create table t (a INTEGER)"); '
     'return ({ db_query(db, "pragma table_info(t)")[0][1..2], db_query(db, "select * from t"), '
     'db_query(db, "delete from t where 1") });')
case("db_open: a file keeps its data",
     'int db = db_open("/test/tmp_db.db"); mixed r; '
     'db_query(db, "create table t (v text)"); db_query(db, "insert into t values (?)", "kept"); '
     'db_close(db); db = db_open("/test/tmp_db.db"); r = db_query(db, "select v from t"); '
     'db_close(db); rm("/test/tmp_db.db"); return ({ r, file_size("/test/tmp_db.db") });')
case("db_query: SQL errors", M + 'return catch(db_query(db, "selec 1"));')
case("db_query: placeholder count", M + 'return catch(db_query(db, "select ?, ?", 1));')
case("db_query: unbindable values", M + 'return catch(db_query(db, "select ?", ({})));')
case("db_close: twice", M + 'db_close(db); return catch(db_close(db));')
case("db_query: only the opener may use a handle",
     'object a = clone_object("%s"), b = clone_object("%s"); int h = a->open(); '
     'mixed r = ({ b->query(h, "select 1"), a->query(h, "select 1"), b->info(h), b->close(h) }); '
     'destruct(a); r += ({ b->query(h, "select 1") }); destruct(b); return r;' % (H, H))
case("db: the owner's destruct closes its handles",
     'object a = clone_object("%s"); int h = a->open(); destruct(a); '
     'return ({ catch(db_query(h, "select 1")), catch(db_info(h)) });' % H)

# --- trimming, placeholders and their count
case("db_query: whitespace and trailing semicolons",
     M + 'return ({ db_query(db, "  select 2 ;; ; "), db_query(db, "\\n\\tselect\\n1\\n"), db_query(db, "\\r\\n SeLeCt 3;") });')
case("db_query: no statement at all",
     M + 'return ({ catch(db_query(db, "")), catch(db_query(db, " ; ")), catch(db_query(db, "-- nothing")), catch(db_query(db, "/* x */")) });')
case("db_query: placeholder counts",
     M + 'return ({ catch(db_query(db, "select 1", 5)), catch(db_query(db, "select ?1, ?1", 5)), '
     'catch(db_query(db, "select ?, ?", 1, 2, 3)), catch(db_query(db, "select \'abc ?", 1)) });')
case("db_query: numbered placeholders keep their numbers",
     M + 'return ({ db_query(db, "select ?2, ?1", 7, 8), db_query(db, "select ?1, ?, ?", 1, 2, 3), '
     'catch(db_query(db, "select ?, ?3, ?", 1, 2, 3)) });')
case("db_query: placeholders with no values are NULL",
     M + 'return ({ db_query(db, "select ?, :x"), db_info(db)["columns"] });')
case("db_query: placeholders in literals, names and comments",
     M + 'return ({ db_query(db, "select \'?\' || ? as [?], ? as `?x` -- ?\\n, /* ? */ ?", "a", 1, 2), db_info(db)["columns"] });')
case("db_query: a placeholder after a quoted string",
     M + 'db_query(db, "create table t (\\"col ?\\")"); db_query(db, "insert into t values (?)", "v"); '
     'return ({ db_query(db, "select \\"col ?\\", ? from t", 9), db_info(db)["columns"] });')

# --- named bindings
case("db_query: named binding prefixes",
     M + 'return db_query(db, "select $a, @b, :c, :d", ([ "$a": 1, "@b": 2, "c": 3, ":d": 4 ]));')
case("db_query: named bindings that aren't in the statement",
     M + 'return ({ catch(db_query(db, "select :a", ([ "a": 1, "zz": 2 ]))), catch(db_query(db, "select :a", ([ "b": 1 ]))), '
     'catch(db_query(db, "select :A", ([ "a": 1 ]))), catch(db_query(db, "select ?", ([ "1": 5 ]))) });')
case("db_query: named bindings left out are NULL",
     M + 'return ({ db_query(db, "select :a, :b", ([ "a": 1 ])), db_query(db, "select 1", ([])), db_query(db, "select :a", ([ "a": 0 ])) });')
case("db_query: bad binding names and values",
     M + 'return ({ catch(db_query(db, "select 1", ([ 1: 2 ]))), catch(db_query(db, "select :a", ([ "a": ({}) ]))), '
     'catch(db_query(db, "select ?", this_object())), catch(db_query(db, "select ?, ?", ([]), ([]))), '
     'catch(db_query(db, "select :a", ([ "a": ([]) ]))) });')
case("db_query: bound values keep their types",
     M + 'return db_query(db, "select typeof(?), typeof(?), typeof(?), ?, ?, ?, ?, typeof(?)", 1, 2.5, "abc", -3, "", 0, 2147483647, "");')
case("db_query: bound strings come back as they went in",
     M + 'db_query(db, "create table t (v)"); '
     'foreach (string s in ({ "", "plain", "it\'s", "a \\"quote\\"", "back\\\\slash", "tab\\there", "line\\nbreak", " spaces " })) '
     'db_query(db, "insert into t values (?)", s); '
     'return db_query(db, "select v, length(v) from t order by rowid");')

# --- statements after the first, errors
case("db_query: statements after the first are refused",
     M + 'return ({ catch(db_query(db, "create table a(x); create table b(y)")), db_query(db, "select count(*) from sqlite_master"), '
     'catch(db_query(db, "create table a(x); -- hi")), catch(db_query(db, "create table a(x); ; create table b(y)")), '
     'catch(db_query(db, "create table a(x); create table b(y)", ([ "zz": 1 ]))) });')
case("db_query: a second SELECT is a syntax error",
     M + 'return catch(db_query(db, "select 1; select 2"));')
case("db_query: errors from preparing",
     M + 'return ({ catch(db_query(db, "select 1,")), catch(db_query(db, "select * from nosuch")), '
     'catch(db_query(db, "insert into nosuch values (1)")), catch(db_query(db, "select nocol")), catch(db_query(db, "drop table nosuch")) });')

# --- SELECT: the wrapper's columns, typed values
case("db_query: SELECT column names",
     M + 'db_query(db, "create table t (b, a)"); db_query(db, "insert into t values (1, 2)"); '
     'mixed r = ({}); '
     'foreach (string q in ({ "select a + b, * from t", "select a, a, b as a from t", "select t.a, T.b from t", "select 1", '
     '"(select 1)", "SELECT 5 AS Five", "select 1 + 2, upper(\'a\'), count(*) from t", "select 1 as \\"a b\\", 2 as \\"q\\"\\"x\\"" })) '
     'r += ({ ({ db_query(db, q), db_info(db)["columns"] }) }); return r;')
case("db_query: SELECT typed values",
     M + 'return ({ db_query(db, "select 0, -1, 9223372036854775807, -9223372036854775807 - 1, 2147483648"), '
     'db_query(db, "select 1.0, 3.0/2, 1e10, -0.5, 0.5, 100.0, 1e-5, 123456789012.0, 2.0e20"), '
     'db_query(db, "select null, null is null, \'\', x\'41424344\', typeof(x\'4142\'), length(x\'00\')") });')
case("db_query: SELECT of a column of mixed types",
     M + 'db_query(db, "create table t (v)"); '
     'foreach (string q in ({ "\'12\'", "12", "12.5", "x\'ff41\'", "null" })) db_query(db, "insert into t values (" + q + ")"); '
     'return db_query(db, "select v, typeof(v) from t order by rowid");')
case("db_query: column affinity",
     M + 'db_query(db, "create table t (i integer, r real, s text, n numeric)"); '
     'db_query(db, "insert into t values (?, ?, ?, ?)", "42", 3, 5, "7.0"); '
     'return db_query(db, "select i, typeof(i), r, typeof(r), s, typeof(s), n, typeof(n) from t");')
case("db_query: SELECT shapes",
     M + 'db_query(db, "create table t (k, v)"); '
     'foreach (mixed *r in ({ ({ "a", 1 }), ({ "b", 2 }), ({ "a", 3 }), ({ "c", 4 }) })) db_query(db, "insert into t values (?, ?)", r[0], r[1]); '
     'return ({ db_query(db, "select k, sum(v), count(*), avg(v) from t group by k order by k"), '
     'db_query(db, "select v from t order by v desc limit 2 offset 1"), '
     'db_query(db, "select 1 as x union all select 2 order by x desc"), '
     'db_query(db, "select v from t where k = ? order by v", "a"), '
     'db_query(db, "select * from t where 0"), db_info(db)["columns"], '
     'db_query(db, "select \';\';"), db_query(db, "/* hi */ -- x\\n select 7 as q"), db_info(db)["columns"], '
     'db_query(db, "select*from t where v=4") });')
case("db_query: a SELECT over many rows",
     M + 'db_query(db, "create table t (n integer)"); db_query(db, "begin"); '
     'for (int i = 0; i < 500; i++) db_query(db, "insert into t values (?)", i); db_query(db, "commit"); '
     'mixed *r = db_query(db, "select n, n * n from t order by n"); '
     'return ({ sizeof(r), r[0], r[499], db_query(db, "select sum(n), count(*) from t") });')

# --- other statements: string rows, columns
case("db_query: other statements' rows and columns",
     M + 'db_query(db, "create table t (a INTEGER, b TEXT default \'x\')"); '
     'return ({ db_query(db, "pragma table_info(t)"), db_info(db)["columns"], '
     'db_query(db, "pragma user_version"), db_query(db, "pragma user_version = 5"), db_info(db)["columns"], '
     'db_query(db, "pragma user_version"), db_query(db, "insert into t values (1, null)"), db_info(db)["columns"] });')
case("db_query: explain gives rows",
     M + 'return sizeof(db_query(db, "explain select 1")) > 0;')
case("db_query: transactions",
     M + 'return ({ db_query(db, "begin"), db_query(db, "create table t (a)"), db_query(db, "insert into t values (1)"), '
     'db_query(db, "rollback"), catch(db_query(db, "select * from t")), db_query(db, "begin transaction"), db_query(db, "end") });')

# --- db_info()
case("db_info: a fresh handle", M + 'return db_info(db);')
case("db_info: changes and insert ids",
     M + 'db_query(db, "create table t (id integer primary key, a)"); '
     'db_query(db, "insert into t (a) values (1)"); db_query(db, "insert into t (a) values (2)"); db_query(db, "insert into t (a) values (3)"); '
     'mapping i = db_info(db); db_query(db, "update t set a = a + 1 where a > 1"); mapping j = db_info(db); '
     'db_query(db, "select * from t"); mapping k = db_info(db); db_query(db, "update t set a = 0 where 0"); '
     'db_query(db, "delete from t where id = 2"); return ({ i, j, k, db_info(db) });')
case("db_info: the columns stay after an error",
     M + 'db_query(db, "select 1 as z"); catch(db_query(db, "select * from nosuch")); mixed a = db_info(db)["columns"]; '
     'catch(db_query(db, "insert into nosuch values (1)")); mixed b = db_info(db)["columns"]; '
     'db_query(db, "create table u (k unique)"); db_query(db, "insert into u values (1)"); db_query(db, "select 2 as y"); '
     'mixed e = catch(db_query(db, "insert into u values (1)")); '
     'return ({ a, b, stringp(e), db_info(db)["columns"], db_query(db, "select count(*) from u") });')
case("db_info: a copy of the columns",
     M + 'db_query(db, "select 1 as z"); string *c = db_info(db)["columns"]; c[0] = "changed"; return db_info(db)["columns"];')

# --- handles, db_open()
case("db_open: handles count up and aren't reused",
     'int a = db_open(":memory:"); int b = db_open(":memory:"); db_close(a); int c = db_open(":memory:"); '
     'return ({ b - a, c - b, db_close(b), db_close(c) });')
case("db: wrong argument types",
     'mixed x = 5, y = "s", z = 1.5, a = ({}); int db = db_open(":memory:"); '
     'return ({ catch(db_open(x)), catch(db_open(a)), catch(db_query(db, x)),catch(db_query(y, "select 1")), '
     'catch(db_info(y)), catch(db_close(z)), catch(db_info(0)), catch(db_query(-1, "select 1")) });')
case("db_open: paths",
     'int db = db_open("test/tmp_m7_db_rel.db"); mapping i = db_info(db); db_close(db); rm("/test/tmp_m7_db_rel.db"); '
     'int d2 = db_open("/test/../test/./tmp_m7_db_rel.db"); string f = db_info(d2)["file"]; db_close(d2); rm("/test/tmp_m7_db_rel.db"); '
     'return ({ i, f, db_info(db_open(":memory:"))["file"] });')
case("db_open: a directory, a missing directory",
     'return ({ catch(db_open("/test")), catch(db_open("/nosuchdir/x.db")), catch(db_open("/")) });')
case("db_open: two handles on one file",
     'int a = db_open("/test/tmp_m7_db2.db"); int b = db_open("/test/tmp_m7_db2.db"); '
     'db_query(a, "create table t (v)"); db_query(a, "insert into t values (?)", "shared"); '
     'mixed r = db_query(b, "select v from t"); db_close(a); db_close(b); rm("/test/tmp_m7_db2.db"); return r;')

case("m7db remove helper",
     'destruct(load_object("%s")); rm("%s.c"); return 1;' % (H, H))

def esc(s):
    return s.replace("\\", "\\\\").replace("\n", "\\n").replace("\t", "\\t")

print("# HavokOS M7 SQLite cases (todo.md HavokOS P1 #7): db_open(), db_query(),")
print("# db_info() and db_close(), the reference's own sqlite_tests() ported and this")
print("# port's edge cases.")
print("# GENERATED by tools/gen_m7_db_cases.py -- edit that, not this file. One case")
print("# per line, <name><TAB><body>; expected results in m7_db.expected.txt are the")
print("# live Pike driver's own (tools/ref_cases.pike -extra).")
for name, body in CASES:
    print(name + "\t" + esc(body.strip()))
