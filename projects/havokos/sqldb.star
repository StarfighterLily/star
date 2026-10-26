# The reference's SQLite databases -- todo.md HavokOS P1 #7 (M7 part 4):
# db_open()/db_query()/db_info()/db_close() (efun codes 420-423),
# `havok/sqldb.pike` method for method, over the real SQLite library:
#
#   int db_open(string file)       a mudlib file (needs valid_write), or
#                                  ":memory:"; returns a handle
#   mixed *db_query(int db, string sql, mixed ... args)
#                                  rows as arrays; `?` placeholders take the
#                                  args in order, or one mapping argument
#                                  binds :name placeholders
#   mapping db_info(int db)        file, columns of the last query,
#                                  changes, insert_id, total_changes
#   int db_close(int db)
#
# A handle belongs to the object that opened it, and closes when that
# object is destructed (`db_forget()`, from objects.star's destruct).
#
# How a query runs is the reference's, step for step, because its quirks
# are visible: the trimming and trailing-semicolon stripping, the
# renumbering of bare `?` placeholders (skipping literals, quoted names and
# comments) and the count check, the binding rules, statement text after the
# first statement refused as "Trailing query data" before anything binds or
# runs, and a statement whose first word is SELECT run twice: first as
# `SELECT * FROM (<sql>) LIMIT 0` for its column names (which is why
# duplicate names come back as "a", "a:1", and why a SELECT's syntax errors
# are reported against that wrapper), then as `SELECT "col1", ... FROM
# (<sql>)` for its rows. Any other statement (PRAGMA, INSERT, WITH, VALUES)
# gives its rows as strings, NULL as "".
#
# What differs is how the values come back. The reference's Pike 8.0 SQLite
# module hands every value over as a string, so the reference wraps each
# column in quote() and parses the literal back; here the wrapper selects
# the columns themselves and reads each value's own type through the C API
# (integer, double, text, blob as its bytes, NULL as 0). Same values,
# without the round trip through text: floats keep every digit (deviation
# #3 anyway) and an infinity stays one (the reference's quote() of one is
# "Inf", which it parses as 0.0). See NOTES.md deviation #22 for the rest,
# mostly that the reference's library is SQLite 3.6.0 and this one 3.54.1.
#
# The SQLite calls are `extern "C"`, apart from the two that answer through
# an out-parameter, which are compiler builtins (`sqlite_open()`,
# `sqlite_prepare()`; `src/codegen/sqlite.rs`). So a program that imports
# this file (through `efuns.star`) links SQLite: `-L sqlite/lib/x64 -l
# sqlite3` from the repository root, with `sqlite3.dll` beside the exe
# (`projects/havokos/tools/` has a copy for the tools built there).
#
# LPC strings are byte strings here (deviation #14), so text is bound and
# read as the bytes it is. The reference encodes its strings to UTF-8 on the
# way in and decodes on the way out, so text that is UTF-8 (all a client
# sends after CHARSET UTF-8) is stored identically; a string holding Latin-1
# bytes is stored as those bytes here, as UTF-8 there.

import "value.star" as val
import "vm.star" as vm
import "efun_table.star" as et
import "extdata.star" as xd
import "buf.star" as bf

extern "C" fn sqlite3_errcode(db: ptr) -> i32
extern "C" fn sqlite3_errmsg(db: ptr) -> ptr
extern "C" fn sqlite3_close_v2(db: ptr) -> i32
extern "C" fn sqlite3_changes64(db: ptr) -> i64
extern "C" fn sqlite3_total_changes64(db: ptr) -> i64
extern "C" fn sqlite3_last_insert_rowid(db: ptr) -> i64
extern "C" fn sqlite3_sql(st: ptr) -> ptr
extern "C" fn sqlite3_step(st: ptr) -> i32
extern "C" fn sqlite3_finalize(st: ptr) -> i32
extern "C" fn sqlite3_column_count(st: ptr) -> i32
extern "C" fn sqlite3_column_name(st: ptr, i: i32) -> ptr
extern "C" fn sqlite3_column_type(st: ptr, i: i32) -> i32
extern "C" fn sqlite3_column_int64(st: ptr, i: i32) -> i64
extern "C" fn sqlite3_column_double(st: ptr, i: i32) -> f64
extern "C" fn sqlite3_column_text(st: ptr, i: i32) -> ptr
extern "C" fn sqlite3_bind_parameter_index(st: ptr, name: str) -> i32
extern "C" fn sqlite3_bind_int64(st: ptr, i: i32, v: i64) -> i32
extern "C" fn sqlite3_bind_double(st: ptr, i: i32, v: f64) -> i32
extern "C" fn sqlite3_bind_text(st: ptr, i: i32, s: str, n: i32, d: i64) -> i32

const SQLITE_ROW: i32 = 100
const SQLITE_DONE: i32 = 101
const SQLITE_INTEGER: i32 = 1
const SQLITE_FLOAT: i32 = 2
const SQLITE_NULL: i32 = 5

# Whitespace for String.trim_all_whites(). Pike also trims Unicode spaces,
# among them U+00A0 and U+0085; as bytes those end UTF-8 characters here
# (deviation #14), so only the ASCII ones are trimmed.
fn sq_ws(c: i32) -> bool:
    c == 32 or c == 9 or c == 10 or c == 13 or c == 12 or c == 11

fn sq_slice(b: Bytes, from: i32, to: i32) -> str:
    let mut o: Bytes = Bytes()
    let mut i = from
    while i < to:
        o.push(b[i])
        i += 1
    str_from_bytes(o)

# The first index >= from where pat starts in b, or -1 (Pike search()).
fn sq_find(b: Bytes, pat: str, from: i32) -> i32:
    let p = bytes_from_str(pat)
    let mut i = from
    while i + p.len() <= b.len():
        let mut k = 0
        while k < p.len() and b[i + k] == p[k]:
            k += 1
        if k == p.len():
            return i
        i += 1
    -1

# db_query()'s clean-up: trim_all_whites(), then while it ends in ";",
# drop that and trim again.
fn sq_trim(s: str) -> str:
    let b = bytes_from_str(s)
    let mut a = 0
    let mut e = b.len()
    while a < e and sq_ws(b[a] as i32):
        a += 1
    let mut more = true
    while more:
        while e > a and sq_ws(b[e - 1] as i32):
            e -= 1
        if e > a and (b[e - 1] as i32) == 59:
            e -= 1
        else:
            more = false
    sq_slice(b, a, e)

# The first keyword of a statement, upper case, past whitespace, `(` and
# comments (sqldb.pike first_word()).
fn sq_first_word(sql: str) -> str:
    let b = bytes_from_str(sql)
    let n = b.len()
    let mut k = 0
    let mut scanning = true
    while scanning and k < n:
        let c = b[k] as i32
        if c == 32 or c == 9 or c == 13 or c == 10 or c == 40:
            k += 1
        elif c == 45 and k + 1 < n and (b[k + 1] as i32) == 45:
            k = sq_find(b, "\n", k)
            if k < 0:
                return ""
        elif c == 47 and k + 1 < n and (b[k + 1] as i32) == 42:
            k = sq_find(b, "*/", k)
            if k < 0:
                return ""
            k += 2
        else:
            scanning = false
    let mut e = k
    while e < n and (((b[e] as i32) >= 97 and (b[e] as i32) <= 122) or ((b[e] as i32) >= 65 and (b[e] as i32) <= 90)):
        e += 1
    let mut o: Bytes = Bytes()
    for i in k..e:
        let c = b[i] as i32
        o.push((if c >= 97: c - 32 else: c) as u8)
    str_from_bytes(o)

# sqldb.pike number_placeholders(): bare `?` becomes ?1, ?2, ... (the
# reference's Pike module binds by name), skipping string literals, quoted
# names and comments; `?NNN` is counted and left alone. An unterminated
# literal or comment runs to the end.
struct Numbered:
    sql: str
    count: i32

fn sq_number_placeholders(sql: str) -> Numbered:
    let b = bytes_from_str(sql)
    let n = b.len()
    let mut o = bf::Buf()
    let mut k = 0
    let mut count = 0
    while k < n:
        let c = b[k] as i32
        if c == 39 or c == 34 or c == 96 or c == 91:
            let close = if c == 91: 93 else: c
            let mut e = k + 1
            while e < n and (b[e] as i32) != close:
                e += 1
            if e >= n:
                e = n - 1
            o.add_str(sq_slice(b, k, e + 1))
            k = e + 1
        elif c == 45 and k + 1 < n and (b[k + 1] as i32) == 45:
            let mut e = sq_find(b, "\n", k)
            if e < 0:
                e = n - 1
            o.add_str(sq_slice(b, k, e + 1))
            k = e + 1
        elif c == 47 and k + 1 < n and (b[k + 1] as i32) == 42:
            let mut e = sq_find(b, "*/", k + 2)
            e = if e < 0: n - 1 else: e + 1
            o.add_str(sq_slice(b, k, e + 1))
            k = e + 1
        elif c == 63:
            count += 1
            if k + 1 < n and (b[k + 1] as i32) >= 48 and (b[k + 1] as i32) <= 57:
                o.byte(c)
            else:
                o.add_str(f"?{count}")
            k += 1
        else:
            o.byte(c)
            k += 1
    Numbered(sql = o.to_str(), count = count)

fn sq_text(st: ptr, i: i32) -> str:
    let p = sqlite3_column_text(st, i)
    if is_null(p):
        return ""
    ptr_to_str(p)

# A column name, double-quoted for SQL (the reference's quote("...") minus
# the quote()).
fn sq_quote_name(c: str) -> str:
    concat(concat("\"", str_replace(c, "\"", "\"\"")), "\"")

# Bindings, checked up front as the reference's bindings() does: names
# (":a", "?1", ...) and values, in order.
struct Binds:
    mut names: List<str> = List<str>()
    mut vals: List<val::Value> = List<val::Value>()

impl vm::Vm:
    fn efun_db(mut self, code: i32, name: str, args: List<val::Value>, self_ob: i32) -> val::Value:
        if code == et::E_DB_OPEN:
            return self.db_open(self.arg(args, 0), self_ob)
        let d = self.db_get(self_ob, self.arg(args, 0), name)
        if d < 0:
            return val::Value::Undef
        if code == et::E_DB_CLOSE:
            self.db_shut(d)
            return val::Value::Int(1 as i64)
        if code == et::E_DB_INFO:
            return self.db_info(d)
        if code == et::E_DB_QUERY:
            return self.db_query(d, args)
        self.fail(f"Efun {name}() is not implemented by this driver.\n")
        val::Value::Undef

    fn db_open(mut self, fv: val::Value, self_ob: i32) -> val::Value:
        let mut file = ""
        match fv:
            val::Value::Str(s) ->
                file = s
            _ ->
                self.fail("Bad argument 1 to db_open()\n")
                return val::Value::Undef
        let mut path = file
        if file != ":memory:":
            file = self.mud_abs(file)
            if !self.check_write(self_ob, file, "db_open"):
                if !self.err:
                    self.fail(concat(concat("db_open: permission denied: ", file), "\n"))
                return val::Value::Undef
            # SQLite dies on backslashes (the reference's comment)
            path = str_replace(self.mud_real(file), "\\", "/")
            if self.is_dir_path(file):
                self.fail(concat(concat("db_open: ", file), " is a directory\n"))
                return val::Value::Undef
        let conn = sqlite_open(path)
        if is_null(conn):
            self.fail(concat(concat("db_open: cannot open ", file), ": \n"))
            return val::Value::Undef
        if sqlite3_errcode(conn) != 0:
            let msg = ptr_to_str(sqlite3_errmsg(conn))
            let c = sqlite3_close_v2(conn)
            self.fail(concat(concat(concat(concat("db_open: cannot open ", file), ": Sql.SQLite: "), msg), "\n"))
            return val::Value::Undef
        self.dbs.push(xd::SqlDb(conn = conn, owner = self.obj_value(self_ob), file = file))
        val::Value::Int(self.dbs.len() as i64)

    # sqldb.pike get(): the row of an open handle the caller owns, or -1
    # with the error set.
    fn db_get(mut self, self_ob: i32, hv: val::Value, fun: str) -> i32:
        let h = match hv:
            val::Value::Int(x) -> x
            val::Value::Undef -> 0 as i64
            _ -> -1 as i64
        if h < (1 as i64) or h > (self.dbs.len() as i64) or !self.dbs[(h - (1 as i64)) as i32].open:
            self.fail(concat(fun, ": no such database\n"))
            return -1
        let d = (h - (1 as i64)) as i32
        if self.obj_of(self.dbs[d].owner) != self_ob:
            self.fail(concat(fun, ": database opened by another object\n"))
            return -1
        d

    fn db_shut(mut self, d: i32):
        let c = sqlite3_close_v2(self.dbs[d].conn)
        self.dbs[d].conn = null_ptr()
        self.dbs[d].open = false
        self.dbs[d].columns = List<str>()

    # Destructing an object closes its handles (sqldb.pike forget_object(),
    # which also drops any whose owner is already gone).
    fn db_forget(mut self, o: i32):
        for d in 0..self.dbs.len():
            if self.dbs[d].open:
                let w = self.obj_of(self.dbs[d].owner)
                if w == o or w < 0:
                    self.db_shut(d)

    fn db_info(mut self, d: i32) -> val::Value:
        let conn = self.dbs[d].conn
        let m = self.new_map()
        self.map_set(m, val::Value::Str("file"), val::Value::Str(self.dbs[d].file))
        self.map_set(m, val::Value::Str("columns"), self.str_list_value(self.dbs[d].columns))
        self.map_set(m, val::Value::Str("changes"), val::Value::Int(sqlite3_changes64(conn)))
        self.map_set(m, val::Value::Str("insert_id"), val::Value::Int(sqlite3_last_insert_rowid(conn)))
        self.map_set(m, val::Value::Str("total_changes"), val::Value::Int(sqlite3_total_changes64(conn)))
        val::Value::Map(m)

    # sqldb.pike check_value(): only ints, floats and strings bind (0 and
    # UNDEFINED are ints).
    fn db_value_ok(mut self, v: val::Value) -> bool:
        let ok = match v:
            val::Value::Int(x) -> true
            val::Value::Undef -> true
            val::Value::Real(x) -> true
            val::Value::Str(s) -> true
            _ -> false
        if !ok:
            self.fail("db_query: only ints, floats and strings can be bound\n")
        ok

    fn db_query(mut self, d: i32, args: List<val::Value>) -> val::Value:
        let mut sql = ""
        match self.arg(args, 1):
            val::Value::Str(s) ->
                sql = s
            _ ->
                self.fail("Bad argument 2 to db_query()\n")
                return val::Value::Undef
        sql = sq_trim(sql)
        let mut b = Binds()
        let nv = args.len() - 2
        if nv > 0:
            let mut by_name = false
            if nv == 1:
                match args[2]:
                    val::Value::Map(h) ->
                        by_name = true
                    _ -> 0
            if by_name:
                let mh = match args[2]:
                    val::Value::Map(h) -> h
                    _ -> 0
                for i in 0..self.maps[mh].keys.len():
                    match self.maps[mh].keys[i]:
                        val::Value::Str(k) ->
                            let named = str_starts_with(k, ":") or str_starts_with(k, "@") or str_starts_with(k, "$")
                            b.names.push(if named: k else: concat(":", k))
                        _ ->
                            self.fail("db_query: binding names must be strings\n")
                            return val::Value::Undef
                    let v = self.maps[mh].vals[i]
                    if !self.db_value_ok(v):
                        return val::Value::Undef
                    b.vals.push(v)
            else:
                let r = sq_number_placeholders(sql)
                if r.count != nv:
                    self.fail(f"db_query: {r.count} placeholders but {nv} values\n")
                    return val::Value::Undef
                sql = r.sql
                for i in 0..nv:
                    if !self.db_value_ok(args[2 + i]):
                        return val::Value::Undef
                    b.names.push(f"?{i + 1}")
                    b.vals.push(args[2 + i])
        if sq_first_word(sql) == "SELECT":
            return self.db_select(d, sql, b)
        self.db_other(d, sql, b)

    # One statement as the reference's Pike module runs it (big_query()):
    # prepared, refused if text follows the first statement, then bound by
    # name. Null with the error set if any step fails.
    fn db_statement(mut self, d: i32, sql: str, b: Binds) -> ptr:
        let conn = self.dbs[d].conn
        let st = sqlite_prepare(conn, sql)
        if is_null(st):
            self.db_fail_conn(d)
            return null_ptr()
        let tb = bytes_from_str(sql)
        let used = len(ptr_to_str(sqlite3_sql(st)))
        let mut k = used
        while k < tb.len() and sq_ws(tb[k] as i32):
            k += 1
        if k < tb.len():
            let f = sqlite3_finalize(st)
            self.fail(concat(concat("db_query: Sql.SQLite->big_query: Trailing query data (\"", sq_slice(tb, used, tb.len())), "\")\n"))
            return null_ptr()
        for i in 0..b.names.len():
            let idx = sqlite3_bind_parameter_index(st, b.names[i])
            if idx == 0:
                let f = sqlite3_finalize(st)
                self.fail(concat(concat("db_query: Unknown bind index \"", b.names[i]), "\".\n"))
                return null_ptr()
            match b.vals[i]:
                val::Value::Int(x) ->
                    let r = sqlite3_bind_int64(st, idx, x)
                val::Value::Real(x) ->
                    let r = sqlite3_bind_double(st, idx, x)
                val::Value::Str(s) ->
                    # SQLITE_TRANSIENT (-1): SQLite copies the text
                    let r = sqlite3_bind_text(st, idx, s, 0 - 1, (0 - 1) as i64)
                _ ->
                    let r = sqlite3_bind_int64(st, idx, 0 as i64)
        st

    # The reference strips its module's "Sql.SQLite: " prefix, leaving the
    # library's own message.
    fn db_fail_conn(mut self, d: i32):
        let msg = ptr_to_str(sqlite3_errmsg(self.dbs[d].conn))
        self.fail(concat(concat("db_query: ", msg), "\n"))

    fn db_step_failed(mut self, d: i32, st: ptr):
        let msg = ptr_to_str(sqlite3_errmsg(self.dbs[d].conn))
        let f = sqlite3_finalize(st)
        self.fail(concat(concat("db_query: ", msg), "\n"))

    fn db_select(mut self, d: i32, sql: str, b: Binds) -> val::Value:
        let probe = self.db_statement(d, concat(concat("SELECT * FROM (", sql), ") LIMIT 0"), b)
        if is_null(probe):
            return val::Value::Undef
        let mut cols: List<str> = List<str>()
        for i in 0..sqlite3_column_count(probe):
            cols.push(ptr_to_str(sqlite3_column_name(probe, i)))
        let f = sqlite3_finalize(probe)
        self.dbs[d].columns = cols
        if cols.len() == 0:
            return val::Value::Arr(0)
        let mut w = bf::Buf()
        w.add_str("SELECT ")
        for i in 0..cols.len():
            if i > 0:
                w.add_str(", ")
            w.add_str(sq_quote_name(cols[i]))
        w.add_str(" FROM (")
        w.add_str(sql)
        w.add_str(")")
        let st = self.db_statement(d, w.to_str(), b)
        if is_null(st):
            return val::Value::Undef
        let n = cols.len()
        let mut rows: List<val::Value> = List<val::Value>()
        let mut rc = sqlite3_step(st)
        while rc == SQLITE_ROW:
            let mut row: List<val::Value> = List<val::Value>()
            for i in 0..n:
                let t = sqlite3_column_type(st, i)
                if t == SQLITE_INTEGER:
                    row.push(val::Value::Int(sqlite3_column_int64(st, i)))
                elif t == SQLITE_FLOAT:
                    row.push(val::Value::Real(sqlite3_column_double(st, i)))
                elif t == SQLITE_NULL:
                    row.push(val::Value::Int(0 as i64))
                else:
                    row.push(val::Value::Str(sq_text(st, i)))
            rows.push(self.new_arr(row))
            rc = sqlite3_step(st)
        if rc != SQLITE_DONE:
            self.db_step_failed(d, st)
            return val::Value::Undef
        let f2 = sqlite3_finalize(st)
        self.new_arr(rows)

    # Any other statement: rows as strings, NULL as "". The columns are the
    # statement's as soon as it is prepared and bound: the reference's module
    # runs it only when its rows are fetched, after sqldb.pike has set them,
    # so an error while it runs (a constraint, say) leaves them set.
    fn db_other(mut self, d: i32, sql: str, b: Binds) -> val::Value:
        let st = self.db_statement(d, sql, b)
        if is_null(st):
            return val::Value::Undef
        let n = sqlite3_column_count(st)
        let mut cols: List<str> = List<str>()
        for i in 0..n:
            cols.push(ptr_to_str(sqlite3_column_name(st, i)))
        self.dbs[d].columns = cols
        let mut rows: List<val::Value> = List<val::Value>()
        let mut rc = sqlite3_step(st)
        while rc == SQLITE_ROW:
            let mut row: List<val::Value> = List<val::Value>()
            for i in 0..n:
                row.push(val::Value::Str(sq_text(st, i)))
            rows.push(self.new_arr(row))
            rc = sqlite3_step(st)
        if rc != SQLITE_DONE:
            self.db_step_failed(d, st)
            return val::Value::Undef
        let f = sqlite3_finalize(st)
        self.new_arr(rows)
