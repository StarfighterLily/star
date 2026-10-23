# LPC virtual machine -- todo.md HavokOS M3. Runs `compiler.star`'s
# bytecode, and holds what the reference's `havok/driver.pike` holds for
# that: the program and object tables, the driver's object stack (what
# previous_object() reads), loading/cloning, call_other dispatch and the
# runtime helpers the emitter calls (`index`, `range_set`, `lpc_div`,
# `catch_result`, `fe1`/`fe2`, ...).
#
# Execution model. Each LPC call pushes a `Frame` (its locals live on the
# shared value stack from `base`); `execute(stop)` runs frames until the
# frame list shrinks back to `stop`. Calls between LPC functions -- local,
# virtual, `::`, call_other, simul_efun, a function pointer -- push a frame
# on the same loop rather than recursing in Star, so LPC recursion depth
# isn't bounded by the native stack. Only an efun calling back into LPC
# (map, filter, evaluate, create() during a load) runs a nested `execute`,
# which bounds native recursion by how deeply efuns nest, not LPC calls.
#
# Errors. Star has no exceptions, so an LPC error (a runtime error, error(),
# throw()) sets `err` and unwinds explicitly: to the innermost `catch`
# handler belonging to this `execute`, or, failing that, out of it (the
# efun or loader that started it sees `err` and returns, and the `execute`
# that called the efun carries on unwinding). A caught error becomes the
# reference's catch value: the thrown value, or `"*message\n"` for an error.
#
# Not here yet (later milestones, NOTES.md roadmap): destruct and the
# "destructed object reads as 0" rule, shadows, reset/clean_up, the
# evaluation cost limit, and the garbage collector for the heap tables --
# M3's heap only grows, which a test run and the booted MVP can afford for
# now; a mark-and-sweep between top-level evaluations is planned (NOTES.md
# "Value representation").

import "value.star" as val
import "program.star" as pg
import "compiler.star" as cc
import "preprocess.star" as pre
import "parser.star" as ps
import "token.star" as tk
import "ast.star" as ast
import "paths.star" as paths
import "efun_table.star" as et
import "efun_names.star" as en
import "buf.star" as bf


extern "C" fn clock() -> i32
extern "C" fn _time64(t: ptr) -> i64

# For the efun files, which can't redeclare these externs (a second
# `extern "C"` declaration of the same name is a duplicate).
fn clock_now() -> i32:
    clock()

fn epoch_now() -> i64:
    _time64(null_ptr())

struct Frame:
    prog: i32
    fnidx: i32
    mut pc: i32
    base: i32
    obj: i32
    var_base: i32
    cells: List<i32>
    # driver object stack depth to restore when this frame returns
    ostack_before: i32

struct Handler:
    fr_index: i32
    target: i32
    stack_len: i32
    ostack_len: i32

struct ObjSlot:
    mut prog: i32
    mut gen: i32
    mut name: str
    mut alive: bool
    mut vars: List<val::Value>
    mut clone: bool
    # time() when created (stat()'s third element)
    mut load_time: i64 = 0 as i64

struct Vm:
    root: str
    mut pp: pre::Pp
    mut progs: List<pg::Program> = List<pg::Program>()
    mut prog_by_path: Map<str, i32> = Map<str, i32>()
    mut compiling: Set<str> = Set<str>()
    mut compile_error: str = ""
    mut objs: List<ObjSlot> = List<ObjSlot>()
    mut obj_by_name: Map<str, i32> = Map<str, i32>()
    mut loading: Set<str> = Set<str>()
    mut clone_count: i32 = 0
    mut arrs: List<val::ArrSlot> = List<val::ArrSlot>()
    mut maps: List<val::MapSlot> = List<val::MapSlot>()
    mut fns: List<val::FnSlot> = List<val::FnSlot>()
    mut clss: List<val::ClsSlot> = List<val::ClsSlot>()
    mut cells: List<val::Value> = List<val::Value>()
    mut stack: List<val::Value> = List<val::Value>()
    mut frames: List<Frame> = List<Frame>()
    mut handlers: List<Handler> = List<Handler>()
    # the driver's object stack (`stack`/`sp` in driver.pike): object handles
    mut ostack: List<i32> = List<i32>()
    mut err: bool = false
    mut err_thrown: bool = false
    mut errv: val::Value = val::Value::Undef
    mut errmsg: str = ""
    mut sefun_path: str = "/secure/sefun"
    mut sefun_ob: i32 = -1
    # the master object (file efuns' valid_read/valid_write); -1 until boot
    # has loaded it, which file efuns treat as "allowed", as FluffOS does
    mut master_path: str = ""
    mut master_ob: i32 = -1
    mut sefun_names: Set<str> = Set<str>()
    mut sefun_types: Map<str, str> = Map<str, str>()
    mut efun_codes: Map<str, i32> = Map<str, i32>()
    mut ref_efuns: Set<str> = Set<str>()
    mut known_efuns: Set<str> = Set<str>()
    # compile errors and other driver messages (the reference's werror())
    mut log: List<str> = List<str>()
    # the driver config (mudos.cfg keys, e.g. "name", "port"), for
    # get_config() and the predefined macros
    mut config: Map<str, str> = Map<str, str>()
    # random()/shuffle()'s generator state (efuns_arr.star), 0 until first use
    mut rng: i64 = 0 as i64
    # time() at boot, for uptime()
    mut boot_time: i64 = 0 as i64
    # scratch output buffers for the recursive formatters (sprintf's %O,
    # the save format), appended to in place -- buf.star says why
    mut dsc: bf::Buf = bf::Buf()
    mut enc: bf::Buf = bf::Buf()

fn new_vm(root: str) -> Vm:
    let mut v = Vm(root = root, pp = pre::new_pp(root))
    v.boot_time = epoch_now()
    # handle 0: Pike's one shared empty array (see new_arr)
    v.arrs.push(val::ArrSlot(items = List<val::Value>()))
    v.efun_codes = et::efun_codes()
    let r = en::reference_efuns()
    for i in 0..r.len():
        v.ref_efuns.insert(r[i])
        v.pp.efun_names.insert(r[i])
    let k = en::fluffos_efuns()
    for i in 0..k.len():
        v.known_efuns.insert(k[i])
    v

# LPC int arithmetic wraps at 64 bits (NOTES.md deviation #6). Star's own
# `i64` `+`/`-`/`*`/`/` trap on overflow and abort the whole process, so an
# LPC `(1 << 62) * 4` would have taken the driver down; every operator on
# LPC ints goes through these instead. `Wrapping<i64>` is the same machine
# arithmetic without the trap (and `MIN / -1` wraps rather than faulting).
fn wadd(a: i64, b: i64) -> i64:
    (Wrapping<i64>(a) + Wrapping<i64>(b)) as i64

fn wsub(a: i64, b: i64) -> i64:
    (Wrapping<i64>(a) - Wrapping<i64>(b)) as i64

fn wmul(a: i64, b: i64) -> i64:
    (Wrapping<i64>(a) * Wrapping<i64>(b)) as i64

fn wdiv(a: i64, b: i64) -> i64:
    (Wrapping<i64>(a) / Wrapping<i64>(b)) as i64

fn wmod(a: i64, b: i64) -> i64:
    (Wrapping<i64>(a) % Wrapping<i64>(b)) as i64

# x << n and x >> n for any n: a shift by 64 or more is poison in LLVM, so
# it's spelled out (all bits shifted out; `>>` is arithmetic, so a negative
# x fills with ones). A negative count shifts the other way.
fn wshl(x: i64, n: i64) -> i64:
    if n < (0 as i64):
        return wshr(x, wsub(0 as i64, n))
    if n >= (64 as i64):
        return 0 as i64
    x << (n as i32)

fn wshr(x: i64, n: i64) -> i64:
    if n < (0 as i64):
        return wshl(x, wsub(0 as i64, n))
    if n >= (64 as i64):
        if x < (0 as i64):
            return 0 as i64 - (1 as i64)
        return 0 as i64
    x >> (n as i32)

fn str_cmp(a: str, b: str) -> i32:
    let x = bytes_from_str(a)
    let y = bytes_from_str(b)
    let n = if x.len() < y.len(): x.len() else: y.len()
    for i in 0..n:
        let p = x[i] as i32
        let q = y[i] as i32
        if p != q:
            return p - q
    x.len() - y.len()

fn int_str(x: i64) -> str:
    f"{x}"

fn p10(n: i32) -> f64:
    let mut r = 1.0 as f64
    let ten = 10.0 as f64
    if n >= 0:
        for i in 0..n:
            r = r * ten
    else:
        for i in 0..(0 - n):
            r = r / ten
    r

fn digits_of(m: i64) -> Bytes:
    let s = bytes_from_str(f"{m}")
    s

# LPC float -> string, as the reference prints it: Pike's (string)float,
# which on this build is C's "%g" (6 significant digits, MSVC's 3-digit
# exponent) plus ".0" when the result would read as an int.
fn fmt_float(v: f64) -> str:
    if v != v:
        return "nan"
    let zero = 0.0 as f64
    if v == zero:
        return "0.0"
    let neg = v < zero
    let x = if neg: zero - v else: v
    if x - x != zero:
        return if neg: "-inf" else: "inf"
    let mut e = 0
    let mut t = x
    let ten = 10.0 as f64
    let one = 1.0 as f64
    while t >= ten:
        t = t / ten
        e += 1
    while t < one:
        t = t * ten
        e -= 1
    let half = 0.5 as f64
    let mut m = (x * p10(5 - e) + half) as i64
    if m >= (1000000 as i64):
        e += 1
        m = (x * p10(5 - e) + half) as i64
    if m < (100000 as i64):
        e -= 1
        m = (x * p10(5 - e) + half) as i64
    let d = digits_of(m)
    let mut out: Bytes = Bytes()
    if neg:
        out.push(45 as u8)
    if e < -4 or e >= 6:
        out.push(d[0])
        let mut last = 5
        while last >= 1 and (d[last] as i32) == 48:
            last -= 1
        if last >= 1:
            out.push(46 as u8)
            for i in 1..last + 1:
                out.push(d[i])
        out.push(101 as u8)
        let mut ee = e
        if ee < 0:
            out.push(45 as u8)
            ee = 0 - ee
        else:
            out.push(43 as u8)
        let es = bytes_from_str(f"{ee}")
        for i in es.len()..3:
            out.push(48 as u8)
        for i in 0..es.len():
            out.push(es[i])
        return str_from_bytes(out)
    let mut last = 5
    while last >= 0 and (d[last] as i32) == 48:
        last -= 1
    if e >= 0:
        for i in 0..e + 1:
            out.push(d[i])
        if last > e:
            out.push(46 as u8)
            for i in e + 1..last + 1:
                out.push(d[i])
        else:
            out.push(46 as u8)
            out.push(48 as u8)
    else:
        out.push(48 as u8)
        out.push(46 as u8)
        for i in 0..(0 - e - 1):
            out.push(48 as u8)
        for i in 0..last + 1:
            out.push(d[i])
    str_from_bytes(out)

# Pike sscanf "%d" on a string (cast_int): optional sign and digits after
# leading whitespace; anything else gives 0.
fn parse_int_prefix(s: str) -> i64:
    let b = bytes_from_str(s)
    let mut i = 0
    while i < b.len() and ((b[i] as i32) == 32 or (b[i] as i32) == 9 or (b[i] as i32) == 10 or (b[i] as i32) == 13):
        i += 1
    let mut neg = false
    if i < b.len() and ((b[i] as i32) == 45 or (b[i] as i32) == 43):
        neg = (b[i] as i32) == 45
        i += 1
    let mut v = 0 as i64
    while i < b.len() and (b[i] as i32) >= 48 and (b[i] as i32) <= 57:
        v = wadd(wmul(v, 10 as i64), ((b[i] as i32) - 48) as i64)
        i += 1
    if neg:
        return wsub(0 as i64, v)
    v

fn substr(s: str, a: i32, b: i32) -> str:
    let x = bytes_from_str(s)
    let mut o: Bytes = Bytes()
    let mut i = a
    while i < b:
        o.push(x[i])
        i += 1
    str_from_bytes(o)

fn esc_quoted(s: str) -> str:
    let hex = bytes_from_str("0123456789abcdef")
    let b = bytes_from_str(s)
    let mut o: Bytes = Bytes()
    o.push(34 as u8)
    for i in 0..b.len():
        let c = b[i] as i32
        if c == 92:
            o.push(92 as u8)
            o.push(92 as u8)
        elif c == 34:
            o.push(92 as u8)
            o.push(34 as u8)
        elif c == 10:
            o.push(92 as u8)
            o.push(110 as u8)
        elif c == 9:
            o.push(92 as u8)
            o.push(116 as u8)
        elif c == 13:
            o.push(92 as u8)
            o.push(114 as u8)
        elif c < 32 or c >= 127:
            o.push(92 as u8)
            o.push(120 as u8)
            o.push(hex[c / 16])
            o.push(hex[c % 16])
        else:
            o.push(b[i])
    o.push(34 as u8)
    str_from_bytes(o)

impl Vm:
    # --- errors -----------------------------------------------------------------

    fn fail(mut self, msg: str):
        if self.err:
            return
        self.err = true
        self.err_thrown = false
        self.errmsg = msg
        self.errv = val::Value::Str(msg)

    fn throw_value(mut self, v: val::Value):
        if self.err:
            return
        self.err = true
        self.err_thrown = true
        self.errv = v
        self.errmsg = "thrown value"

    # the reference's catch_result(): the thrown value, or "*message\n"
    fn catch_value(self) -> val::Value:
        if self.err_thrown:
            return self.errv
        let mut m = self.errmsg
        if !str_ends_with(m, "\n"):
            m = concat(m, "\n")
        if !str_starts_with(m, "*"):
            m = concat("*", m)
        val::Value::Str(m)

    fn clear_err(mut self):
        self.err = false
        self.err_thrown = false
        self.errv = val::Value::Undef
        self.errmsg = ""

    # --- heap -------------------------------------------------------------------

    # Every empty array is the same object, as in Pike (`({}) == ({})` and
    # `({}) == allocate(0)` are true there, while two non-empty arrays never
    # are), so handle 0 is shared and nothing may grow it in place.
    fn new_arr(mut self, items: List<val::Value>) -> val::Value:
        if items.len() == 0:
            return val::Value::Arr(0)
        let h = self.arrs.len()
        self.arrs.push(val::ArrSlot(items = items))
        val::Value::Arr(h)

    fn new_map(mut self) -> i32:
        let h = self.maps.len()
        self.maps.push(val::MapSlot(keys = List<val::Value>(), vals = List<val::Value>(), idx = Map<val::MKey, i32>()))
        h

    fn map_find(self, h: i32, k: val::Value) -> i32:
        if let Option::Some(i) = self.maps[h].idx.get(val::mkey(k)):
            return i
        -1

    fn map_get(self, h: i32, k: val::Value) -> val::Value:
        let i = self.map_find(h, k)
        if i < 0:
            return val::Value::Undef
        self.maps[h].vals[i]

    fn map_set(mut self, h: i32, k: val::Value, v: val::Value):
        let i = self.map_find(h, k)
        if i >= 0:
            self.maps[h].vals[i] = v
            return
        let n = self.maps[h].keys.len()
        let kk = match k:
            val::Value::Undef -> val::Value::Int(0 as i64)
            _ -> k
        self.maps[h].keys.push(kk)
        self.maps[h].vals.push(v)
        self.maps[h].idx.insert(val::mkey(kk), n)

    fn map_delete(mut self, h: i32, k: val::Value):
        let i = self.map_find(h, k)
        if i < 0:
            return
        let last = self.maps[h].keys.len() - 1
        self.maps[h].idx.remove(val::mkey(k))
        if i != last:
            let lk = self.maps[h].keys[last]
            self.maps[h].keys[i] = lk
            self.maps[h].vals[i] = self.maps[h].vals[last]
            self.maps[h].idx.insert(val::mkey(lk), i)
        self.maps[h].keys.pop()
        self.maps[h].vals.pop()

    fn new_cell(mut self, v: val::Value) -> i32:
        let c = self.cells.len()
        self.cells.push(v)
        c

    fn new_fn(mut self, f: val::FnSlot) -> val::Value:
        let h = self.fns.len()
        self.fns.push(f)
        val::Value::Fn(h)

    fn obj_value(self, o: i32) -> val::Value:
        if o < 0:
            return val::Value::Int(0 as i64)
        val::Value::Obj(o, self.objs[o].gen)

    # the live object a value refers to, or -1
    fn obj_of(self, v: val::Value) -> i32:
        match v:
            val::Value::Obj(h, g) ->
                if self.objs[h].alive and self.objs[h].gen == g:
                    return h
                -1
            _ -> -1

    fn cur_obj(self) -> i32:
        if self.frames.len() == 0:
            return -1
        self.frames[self.frames.len() - 1].obj

    # --- conversions ------------------------------------------------------------

    fn type_name(self, v: val::Value) -> str:
        match v:
            val::Value::Undef -> "int"
            val::Value::Int(x) -> "int"
            val::Value::Real(x) -> "float"
            val::Value::Str(s) -> "string"
            val::Value::Arr(h) -> "array"
            val::Value::Map(h) -> "mapping"
            val::Value::Obj(h, g) -> "object"
            val::Value::Fn(h) -> "function"
            val::Value::Cls(h) -> "class"

    fn to_str(self, v: val::Value) -> str:
        match v:
            val::Value::Undef -> "0"
            val::Value::Int(x) -> int_str(x)
            val::Value::Real(x) -> fmt_float(x)
            val::Value::Str(s) -> s
            _ -> ""

    fn conv(mut self, mode: i32, v: val::Value) -> val::Value:
        if mode == pg::CONV_F2I:
            match v:
                val::Value::Real(x) ->
                    return val::Value::Int(x as i64)
                _ ->
                    return v
        if mode == pg::CONV_I2F:
            match v:
                val::Value::Int(x) ->
                    return val::Value::Real(x as f64)
                val::Value::Undef ->
                    return val::Value::Real(0.0 as f64)
                _ ->
                    return v
        if mode == pg::CONV_INT:
            match v:
                val::Value::Real(x) ->
                    return val::Value::Int(x as i64)
                val::Value::Str(s) ->
                    return val::Value::Int(parse_int_prefix(s))
                _ ->
                    return v
        if mode == pg::CONV_FLOAT:
            match v:
                val::Value::Int(x) ->
                    return val::Value::Real(x as f64)
                val::Value::Undef ->
                    return val::Value::Real(0.0 as f64)
                val::Value::Str(s) ->
                    return val::Value::Real(atof(s))
                _ ->
                    return v
        match v:
            val::Value::Int(x) -> val::Value::Str(int_str(x))
            val::Value::Undef -> val::Value::Str("0")
            val::Value::Real(x) -> val::Value::Str(fmt_float(x))
            _ -> v

    # --- operators (Pike's, which the reference's LPC code runs on) ---------------

    fn truthy(self, v: val::Value) -> bool:
        match v:
            val::Value::Undef -> false
            val::Value::Int(x) -> x != (0 as i64)
            val::Value::Obj(h, g) -> self.objs[h].alive and self.objs[h].gen == g
            _ -> true

    fn lpc_eq(self, a: val::Value, b: val::Value) -> bool:
        match a:
            # Pike's `==`: an int never equals a float, even 3 == 3.0
            val::Value::Undef ->
                match b:
                    val::Value::Undef ->
                        return true
                    val::Value::Int(y) ->
                        return y == (0 as i64)
                    _ ->
                        return false
            val::Value::Int(x) ->
                match b:
                    val::Value::Undef ->
                        return x == (0 as i64)
                    val::Value::Int(y) ->
                        return x == y
                    _ ->
                        return false
            val::Value::Real(x) ->
                match b:
                    val::Value::Real(y) ->
                        return x == y
                    _ ->
                        return false
            val::Value::Str(s) ->
                match b:
                    val::Value::Str(t) ->
                        return s == t
                    _ ->
                        return false
            val::Value::Arr(h) ->
                match b:
                    val::Value::Arr(k) ->
                        return h == k
                    _ ->
                        return false
            val::Value::Map(h) ->
                match b:
                    val::Value::Map(k) ->
                        return h == k
                    _ ->
                        return false
            val::Value::Obj(h, g) ->
                match b:
                    val::Value::Obj(k, j) ->
                        return h == k and g == j
                    _ ->
                        return false
            val::Value::Fn(h) ->
                match b:
                    val::Value::Fn(k) ->
                        return h == k
                    _ ->
                        return false
            val::Value::Cls(h) ->
                match b:
                    val::Value::Cls(k) ->
                        return h == k
                    _ ->
                        return false

    fn arr_items(self, v: val::Value) -> List<val::Value>:
        match v:
            val::Value::Arr(h) -> self.arrs[h].items
            _ -> List<val::Value>()

    fn arr_has(self, items: List<val::Value>, x: val::Value) -> bool:
        for i in 0..items.len():
            if self.lpc_eq(items[i], x):
                return true
        false

    fn bad_arg(mut self, n: i32, op: str, v: val::Value):
        self.fail(f"Bad argument {n} to {op}() (got {self.type_name(v)}).\n")

    fn num_op(mut self, op: i32, a: val::Value, b: val::Value) -> val::Value:
        # both numbers here (int or float); int op int stays int
        let mut ai = 0 as i64
        let mut af = 0.0 as f64
        let mut a_real = false
        match a:
            val::Value::Int(x) ->
                ai = x
            val::Value::Real(x) ->
                af = x
                a_real = true
            _ ->
                ai = 0 as i64
        let mut bi = 0 as i64
        let mut bf = 0.0 as f64
        let mut b_real = false
        match b:
            val::Value::Int(x) ->
                bi = x
            val::Value::Real(x) ->
                bf = x
                b_real = true
            _ ->
                bi = 0 as i64
        if !a_real and !b_real:
            if op == pg::B_ADD:
                return val::Value::Int(wadd(ai, bi))
            if op == pg::B_SUB:
                return val::Value::Int(wsub(ai, bi))
            if op == pg::B_MUL:
                return val::Value::Int(wmul(ai, bi))
            if op == pg::B_LT:
                return self.bool_v(ai < bi)
            if op == pg::B_LE:
                return self.bool_v(ai <= bi)
            if op == pg::B_GT:
                return self.bool_v(ai > bi)
            return self.bool_v(ai >= bi)
        let x = if a_real: af else: ai as f64
        let y = if b_real: bf else: bi as f64
        if op == pg::B_ADD:
            return val::Value::Real(x + y)
        if op == pg::B_SUB:
            return val::Value::Real(x - y)
        if op == pg::B_MUL:
            return val::Value::Real(x * y)
        if op == pg::B_LT:
            return self.bool_v(x < y)
        if op == pg::B_LE:
            return self.bool_v(x <= y)
        if op == pg::B_GT:
            return self.bool_v(x > y)
        self.bool_v(x >= y)

    fn bool_v(self, b: bool) -> val::Value:
        if b:
            return val::Value::Int(1 as i64)
        val::Value::Int(0 as i64)

    fn is_num(self, v: val::Value) -> bool:
        match v:
            val::Value::Undef -> true
            val::Value::Int(x) -> true
            val::Value::Real(x) -> true
            _ -> false

    fn is_int(self, v: val::Value) -> bool:
        match v:
            val::Value::Undef -> true
            val::Value::Int(x) -> true
            _ -> false

    fn lpc_div(mut self, a: val::Value, b: val::Value, floor: bool) -> val::Value:
        if self.is_int(a) and self.is_int(b):
            let x = val::int_of(a)
            let y = val::int_of(b)
            if y == (0 as i64):
                self.fail("Division by zero\n")
                return val::Value::Undef
            let mut q = wdiv(x, y)
            if floor and wmul(q, y) != x and ((x < (0 as i64)) != (y < (0 as i64))):
                q = wsub(q, 1 as i64)
            return val::Value::Int(q)
        if !self.is_num(a):
            self.fail(f"Bad argument 1 to / (expected int or float, got {self.type_name(a)})\n")
            return val::Value::Undef
        if !self.is_num(b):
            self.fail(f"Bad argument 2 to / (expected int or float, got {self.type_name(b)})\n")
            return val::Value::Undef
        let x = match a:
            val::Value::Real(f) -> f
            _ -> val::int_of(a) as f64
        let y = match b:
            val::Value::Real(f) -> f
            _ -> val::int_of(b) as f64
        if y == (0.0 as f64):
            match b:
                val::Value::Real(f) -> self.fail("Division by 0.0\n")
                _ -> self.fail("Division by zero\n")
            return val::Value::Undef
        val::Value::Real(x / y)

    fn lpc_mod(mut self, a: val::Value, b: val::Value, floor: bool) -> val::Value:
        if !self.is_int(a):
            self.fail(f"Bad argument 1 to % (expected int, got {self.type_name(a)})\n")
            return val::Value::Undef
        if !self.is_int(b):
            self.fail(f"Bad argument 2 to % (expected int, got {self.type_name(b)})\n")
            return val::Value::Undef
        let x = val::int_of(a)
        let y = val::int_of(b)
        if y == (0 as i64):
            self.fail("Modulus by zero.\n")
            return val::Value::Undef
        let mut r = wmod(x, y)
        if floor and r != (0 as i64) and ((r < (0 as i64)) != (y < (0 as i64))):
            r = wadd(r, y)
        val::Value::Int(r)

    fn binop(mut self, op: i32, a: val::Value, b: val::Value) -> val::Value:
        if op == pg::B_EQ:
            return self.bool_v(self.lpc_eq(a, b))
        if op == pg::B_NE:
            return self.bool_v(!self.lpc_eq(a, b))
        if op == pg::B_CADD or op == pg::B_CSUB or op == pg::B_CMUL or op == pg::B_CDIV:
            let base = if op == pg::B_CADD: pg::B_ADD elif op == pg::B_CSUB: pg::B_SUB elif op == pg::B_CMUL: pg::B_MUL else: pg::B_DIV
            let r = self.binop(base, a, b)
            if self.is_int(a):
                match r:
                    val::Value::Real(x) ->
                        return val::Value::Int(x as i64)
                    _ ->
                        return r
            return r
        if op == pg::B_DIV:
            return self.lpc_div(a, b, false)
        if op == pg::B_PDIV:
            return self.lpc_div(a, b, true)
        if op == pg::B_MOD:
            return self.lpc_mod(a, b, false)
        if op == pg::B_PMOD:
            return self.lpc_mod(a, b, true)
        if self.is_num(a) and self.is_num(b):
            if op == pg::B_ADD or op == pg::B_SUB or op == pg::B_MUL or op == pg::B_LT or op == pg::B_LE or op == pg::B_GT or op == pg::B_GE:
                return self.num_op(op, a, b)
            if self.is_int(a) and self.is_int(b):
                let x = val::int_of(a)
                let y = val::int_of(b)
                if op == pg::B_AND:
                    return val::Value::Int(x & y)
                if op == pg::B_OR:
                    return val::Value::Int(x | y)
                if op == pg::B_XOR:
                    return val::Value::Int(x ^ y)
                if op == pg::B_SHL:
                    return val::Value::Int(wshl(x, y))
                if op == pg::B_SHR:
                    return val::Value::Int(wshr(x, y))
            self.fail("Bad argument to bitwise operator (expected int).\n")
            return val::Value::Undef
        if op == pg::B_ADD:
            return self.add_values(a, b)
        if op == pg::B_SUB:
            return self.sub_values(a, b)
        if op == pg::B_MUL:
            return self.mul_values(a, b)
        if op == pg::B_LT or op == pg::B_LE or op == pg::B_GT or op == pg::B_GE:
            match a:
                val::Value::Str(s) ->
                    match b:
                        val::Value::Str(t) ->
                            let c = str_cmp(s, t)
                            if op == pg::B_LT:
                                return self.bool_v(c < 0)
                            if op == pg::B_LE:
                                return self.bool_v(c <= 0)
                            if op == pg::B_GT:
                                return self.bool_v(c > 0)
                            return self.bool_v(c >= 0)
                        _ -> 0
                _ -> 0
            self.fail(f"Bad argument to comparison ({self.type_name(a)} vs {self.type_name(b)}).\n")
            return val::Value::Undef
        if op == pg::B_AND or op == pg::B_OR or op == pg::B_XOR:
            match a:
                val::Value::Arr(h) ->
                    match b:
                        val::Value::Arr(k) ->
                            return self.arr_setop(op, h, k)
                        _ -> 0
                _ -> 0
        self.fail(f"Bad arguments to operator ({self.type_name(a)}, {self.type_name(b)}).\n")
        val::Value::Undef

    fn add_values(mut self, a: val::Value, b: val::Value) -> val::Value:
        match a:
            val::Value::Str(s) ->
                match b:
                    val::Value::Str(t) ->
                        return val::Value::Str(concat(s, t))
                    _ ->
                        if self.is_num(b):
                            return val::Value::Str(concat(s, self.to_str(b)))
            val::Value::Arr(h) ->
                match b:
                    val::Value::Arr(k) ->
                        let mut items = self.arrs[h].items
                        let more = self.arrs[k].items
                        for i in 0..more.len():
                            items.push(more[i])
                        return self.new_arr(items)
                    _ -> 0
            val::Value::Map(h) ->
                match b:
                    val::Value::Map(k) ->
                        let m = self.copy_map(h)
                        let ks = self.maps[k].keys
                        let vs = self.maps[k].vals
                        for i in 0..ks.len():
                            self.map_set(m, ks[i], vs[i])
                        return val::Value::Map(m)
                    _ -> 0
            _ ->
                if self.is_num(a):
                    match b:
                        val::Value::Str(t) ->
                            return val::Value::Str(concat(self.to_str(a), t))
                        _ -> 0
        self.fail(f"Bad argument to + ({self.type_name(a)} + {self.type_name(b)}).\n")
        val::Value::Undef

    fn copy_map(mut self, h: i32) -> i32:
        let m = self.new_map()
        let ks = self.maps[h].keys
        let vs = self.maps[h].vals
        for i in 0..ks.len():
            self.map_set(m, ks[i], vs[i])
        m

    fn sub_values(mut self, a: val::Value, b: val::Value) -> val::Value:
        match a:
            val::Value::Arr(h) ->
                match b:
                    val::Value::Arr(k) ->
                        let items = self.arrs[h].items
                        let drop = self.arrs[k].items
                        let mut out: List<val::Value> = List<val::Value>()
                        for i in 0..items.len():
                            if !self.arr_has(drop, items[i]):
                                out.push(items[i])
                        return self.new_arr(out)
                    _ -> 0
            val::Value::Map(h) ->
                match b:
                    val::Value::Map(k) ->
                        let m = self.copy_map(h)
                        let ks = self.maps[k].keys
                        for i in 0..ks.len():
                            self.map_delete(m, ks[i])
                        return val::Value::Map(m)
                    _ -> 0
            val::Value::Str(s) ->
                match b:
                    val::Value::Str(t) ->
                        if t == "":
                            return a
                        return val::Value::Str(str_replace(s, t, ""))
                    _ -> 0
            _ -> 0
        self.fail(f"Bad argument to - ({self.type_name(a)} - {self.type_name(b)}).\n")
        val::Value::Undef

    fn mul_values(mut self, a: val::Value, b: val::Value) -> val::Value:
        match a:
            val::Value::Arr(h) ->
                match b:
                    val::Value::Str(d) ->
                        let items = self.arrs[h].items
                        let mut parts: List<str> = List<str>()
                        for i in 0..items.len():
                            match items[i]:
                                val::Value::Str(s) -> parts.push(s)
                                _ ->
                                    self.fail("Bad element in array * string.\n")
                                    return val::Value::Undef
                        return val::Value::Str(str_join(parts, d))
                    _ -> 0
            val::Value::Str(s) ->
                if self.is_int(b):
                    let n = val::int_of(b)
                    let mut parts: List<str> = List<str>()
                    let mut i = 0 as i64
                    while i < n:
                        parts.push(s)
                        i = i + (1 as i64)
                    return val::Value::Str(str_join(parts, ""))
            _ -> 0
        self.fail(f"Bad argument to * ({self.type_name(a)} * {self.type_name(b)}).\n")
        val::Value::Undef

    fn arr_setop(mut self, op: i32, h: i32, k: i32) -> val::Value:
        let a = self.arrs[h].items
        let b = self.arrs[k].items
        let mut out: List<val::Value> = List<val::Value>()
        if op == pg::B_AND:
            for i in 0..a.len():
                if self.arr_has(b, a[i]):
                    out.push(a[i])
        elif op == pg::B_OR:
            for i in 0..a.len():
                out.push(a[i])
            for i in 0..b.len():
                if !self.arr_has(a, b[i]):
                    out.push(b[i])
        else:
            for i in 0..a.len():
                if !self.arr_has(b, a[i]):
                    out.push(a[i])
            for i in 0..b.len():
                if !self.arr_has(a, b[i]):
                    out.push(b[i])
        self.new_arr(out)

    fn negate(mut self, v: val::Value) -> val::Value:
        match v:
            val::Value::Undef -> val::Value::Int(0 as i64)
            val::Value::Int(x) -> val::Value::Int(wsub(0 as i64, x))
            val::Value::Real(x) -> val::Value::Real((0.0 as f64) - x)
            _ ->
                self.fail(f"Bad argument 1 to `-() (got {self.type_name(v)}).\n")
                val::Value::Undef

    fn compl(mut self, v: val::Value) -> val::Value:
        if self.is_int(v):
            return val::Value::Int(val::int_of(v) ^ ((0 as i64) - (1 as i64)))
        self.fail(f"Bad argument 1 to `~() (got {self.type_name(v)}).\n")
        val::Value::Undef

    # Pike's %O of a key, for "Cannot index ..." messages
    fn describe(self, v: val::Value) -> str:
        match v:
            val::Value::Str(s) -> esc_quoted(s)
            val::Value::Undef -> "UNDEFINED"
            val::Value::Int(x) -> int_str(x)
            val::Value::Real(x) -> fmt_float(x)
            _ -> self.type_name(v)

    # Rvalue indexing (the reference's driver index()).
    fn index(mut self, c: val::Value, k: val::Value) -> val::Value:
        match c:
            val::Value::Str(s) ->
                if self.is_int(k):
                    let b = bytes_from_str(s)
                    let n = b.len() as i64
                    let i = val::int_of(k)
                    if i == n:
                        return val::Value::Int(0 as i64)
                    if i < (0 as i64) - n or i > n:
                        self.fail(f"String index out of bounds ({i}/{n}).\n")
                        return val::Value::Undef
                    let j = if i < (0 as i64): (i + n) as i32 else: i as i32
                    return val::Value::Int(b[j] as i64)
                self.fail(f"Indexing a string with {self.describe(k)}.\n")
                return val::Value::Undef
            val::Value::Arr(h) ->
                if self.is_int(k):
                    let n = self.arrs[h].items.len() as i64
                    let i = val::int_of(k)
                    if i < (0 as i64) - n or i >= n:
                        self.fail(f"Index {i} is out of array range {(0 as i64) - n}..{n - (1 as i64)}.\n")
                        return val::Value::Undef
                    let j = if i < (0 as i64): (i + n) as i32 else: i as i32
                    return self.arrs[h].items[j]
                self.fail(f"Indexing an array with {self.describe(k)}.\n")
                return val::Value::Undef
            val::Value::Map(h) ->
                return self.map_get(h, k)
            val::Value::Cls(h) ->
                if self.is_int(k):
                    let i = val::int_of(k) as i32
                    if i >= 0 and i < self.clss[h].vals.len():
                        return self.clss[h].vals[i]
                self.fail("Bad class index.\n")
                return val::Value::Undef
            val::Value::Undef ->
                self.fail(f"Cannot index the NULL value with {self.describe(k)}.\n")
                return val::Value::Undef
            val::Value::Int(x) ->
                if x == (0 as i64):
                    self.fail(f"Cannot index the NULL value with {self.describe(k)}.\n")
                else:
                    self.fail(f"Cannot index the integer {x}.\n")
                return val::Value::Undef
            _ ->
                self.fail(f"Cannot index a {self.type_name(c)}.\n")
                return val::Value::Undef

    # In-place store; returns the replacement container for a string (whose
    # owner must take it back), undefined otherwise.
    fn index_store(mut self, c: val::Value, k: val::Value, v: val::Value) -> val::Value:
        match c:
            val::Value::Arr(h) ->
                if self.is_int(k):
                    let n = self.arrs[h].items.len() as i64
                    let i = val::int_of(k)
                    if i < (0 as i64) - n or i >= n:
                        self.fail(f"Index {i} is out of array range {(0 as i64) - n}..{n - (1 as i64)}.\n")
                        return val::Value::Undef
                    let j = if i < (0 as i64): (i + n) as i32 else: i as i32
                    self.arrs[h].items[j] = v
                    return val::Value::Undef
                self.fail(f"Indexing an array with {self.describe(k)}.\n")
                return val::Value::Undef
            val::Value::Map(h) ->
                self.map_set(h, k, v)
                return val::Value::Undef
            val::Value::Cls(h) ->
                if self.is_int(k):
                    let i = val::int_of(k) as i32
                    if i >= 0 and i < self.clss[h].vals.len():
                        self.clss[h].vals[i] = v
                        return val::Value::Undef
                self.fail("Bad class index.\n")
                return val::Value::Undef
            val::Value::Str(s) ->
                if !self.is_int(k) or !self.is_int(v):
                    self.fail("Bad string index assignment.\n")
                    return val::Value::Undef
                let mut b = bytes_from_str(s)
                let n = b.len() as i64
                let i = val::int_of(k)
                if i < (0 as i64) - n or i >= n:
                    self.fail(f"String index out of bounds ({i}/{n}).\n")
                    return val::Value::Undef
                let j = if i < (0 as i64): (i + n) as i32 else: i as i32
                b[j] = val::int_of(v) as u8
                return val::Value::Str(str_from_bytes(b))
            _ ->
                self.fail(f"Cannot index the NULL value with {self.describe(k)}.\n")
                return val::Value::Undef

    fn member(mut self, c: val::Value, pos: i32) -> val::Value:
        match c:
            val::Value::Cls(h) ->
                if pos < self.clss[h].vals.len():
                    return self.clss[h].vals[pos]
                return val::Value::Undef
            _ ->
                if val::is_zero(c):
                    self.fail("Class member access on 0\n")
                else:
                    self.fail("Left argument of -> is not a class\n")
                val::Value::Undef

    fn member_store(mut self, c: val::Value, pos: i32, v: val::Value):
        match c:
            val::Value::Cls(h) ->
                if pos < self.clss[h].vals.len():
                    self.clss[h].vals[pos] = v
            _ ->
                if val::is_zero(c):
                    self.fail("Class member access on 0\n")
                else:
                    self.fail("Left argument of -> is not a class\n")

    fn seq_len(self, v: val::Value) -> i32:
        match v:
            val::Value::Str(s) -> len(s)
            val::Value::Arr(h) -> self.arrs[h].items.len()
            _ -> 0

    # s[lo..hi] with LPC's `<n` (from the end) forms resolved and Pike's clamping
    fn range_bounds(self, n: i32, flags: i32, lo: val::Value, hi: val::Value) -> List<i32>:
        let mut a = 0
        let mut b = n - 1
        if (flags & pg::R_HAS_LO) != 0:
            let x = val::int_of(lo) as i32
            a = if (flags & pg::R_LO_END) != 0: n - x else: x
        if (flags & pg::R_HAS_HI) != 0:
            let y = val::int_of(hi) as i32
            b = if (flags & pg::R_HI_END) != 0: n - y else: y
        [a, b]

    fn range(mut self, s: val::Value, flags: i32, lo: val::Value, hi: val::Value) -> val::Value:
        match s:
            val::Value::Str(str_v) ->
                let n = len(str_v)
                let ab = self.range_bounds(n, flags, lo, hi)
                let mut a = ab[0]
                let mut b = ab[1]
                if a < 0:
                    a = 0
                if b >= n:
                    b = n - 1
                if b < a:
                    return val::Value::Str("")
                return val::Value::Str(substr(str_v, a, b + 1))
            val::Value::Arr(h) ->
                let items = self.arrs[h].items
                let n = items.len()
                let ab = self.range_bounds(n, flags, lo, hi)
                let mut a = ab[0]
                let mut b = ab[1]
                if a < 0:
                    a = 0
                if b >= n:
                    b = n - 1
                let mut out: List<val::Value> = List<val::Value>()
                let mut i = a
                while i <= b:
                    out.push(items[i])
                    i += 1
                return self.new_arr(out)
            _ ->
                self.fail(f"Cannot take a range of {self.type_name(s)}.\n")
                return val::Value::Undef

    # The reference's range_set(): open ends cover the whole sequence.
    fn range_set(mut self, s: val::Value, flags: i32, lo: val::Value, hi: val::Value, v: val::Value) -> val::Value:
        let is_str = match s:
            val::Value::Str(x) -> true
            _ -> false
        let is_arr = match s:
            val::Value::Arr(x) -> true
            _ -> false
        if !is_str and !is_arr:
            self.fail("Bad range assignment target\n")
            return val::Value::Undef
        let n = self.seq_len(s)
        let ab = self.range_bounds(n, flags, lo, hi)
        let mut a = ab[0]
        let mut b = ab[1]
        if a < 0:
            a = 0
        if b >= n:
            b = n - 1
        if is_str:
            match v:
                val::Value::Str(t) ->
                    match s:
                        val::Value::Str(x) ->
                            let head = if a > 0: substr(x, 0, a) else: ""
                            let tail = if b + 1 < n: substr(x, b + 1, n) else: ""
                            return val::Value::Str(concat(concat(head, t), tail))
                        _ ->
                            return val::Value::Undef
                _ ->
                    self.fail("Bad right-hand side to range assignment\n")
                    return val::Value::Undef
        match v:
            val::Value::Arr(k) ->
                let items = self.arr_items(s)
                let mid = self.arrs[k].items
                let mut out: List<val::Value> = List<val::Value>()
                for i in 0..a:
                    out.push(items[i])
                for i in 0..mid.len():
                    out.push(mid[i])
                let mut i = b + 1
                while i < n:
                    out.push(items[i])
                    i += 1
                return self.new_arr(out)
            _ ->
                self.fail("Bad right-hand side to range assignment\n")
                return val::Value::Undef

    # --- stack helpers ----------------------------------------------------------

    fn pop(mut self) -> val::Value:
        let n = self.stack.len()
        let v = self.stack[n - 1]
        self.stack.pop()
        v

    fn truncate_stack(mut self, n: i32):
        while self.stack.len() > n:
            self.stack.pop()

    fn pop_args(mut self, n: i32) -> List<val::Value>:
        let mut out: List<val::Value> = List<val::Value>()
        let s = self.stack.len() - n
        for i in 0..n:
            out.push(self.stack[s + i])
        self.truncate_stack(s)
        out

    # argc -1: the arguments arrive as one array (a spread call)
    fn take_args(mut self, argc: i32) -> List<val::Value>:
        if argc >= 0:
            return self.pop_args(argc)
        let a = self.pop()
        self.arr_items(a)

    fn push_all(mut self, args: List<val::Value>):
        for i in 0..args.len():
            self.stack.push(args[i])

    # --- driver object stack ----------------------------------------------------

    fn opush(mut self, o: i32):
        if self.ostack.len() >= 1000:
            self.fail("Too deep recursion.\n")
            return
        self.ostack.push(o)

    fn ensure_top(mut self, o: i32):
        if o < 0:
            return
        let n = self.ostack.len()
        if n > 0 and self.ostack[n - 1] == o:
            return
        self.opush(o)

    fn truncate_ostack(mut self, n: i32):
        while self.ostack.len() > n:
            self.ostack.pop()

    # previous_object(n) as seen from `self_ob` (driver previous())
    fn previous(mut self, self_ob: i32, n: i32) -> val::Value:
        let sp = self.ostack.len()
        let base = if sp > 0 and self.ostack[sp - 1] == self_ob: sp - 1 else: sp
        if n < 0:
            let mut out: List<val::Value> = List<val::Value>()
            let mut i = base - 1
            while i >= 0:
                let o = self.ostack[i]
                out.push(if o >= 0 and self.objs[o].alive: self.obj_value(o) else: val::Value::Int(0 as i64))
                i -= 1
            return self.new_arr(out)
        let i = base - 1 - n
        if i >= 0:
            let o = self.ostack[i]
            if o >= 0 and self.objs[o].alive:
                return self.obj_value(o)
        val::Value::Int(0 as i64)

    # --- function lookup ----------------------------------------------------------

    # call_other-visible function of an object (driver public_fn)
    fn public_fn(self, o: i32, name: str) -> pg::DispEntry:
        let p = self.objs[o].prog
        if let Option::Some(e) = self.progs[p].vt.get(name):
            if !e.is_static:
                return e
        pg::DispEntry(prog = -1, fnidx = -1, var_off = 0)

    # any function by name, static/private included (driver any_fn)
    fn any_fn(self, o: i32, name: str) -> pg::DispEntry:
        let p = self.objs[o].prog
        if let Option::Some(e) = self.progs[p].anyt.get(name):
            return e
        pg::DispEntry(prog = -1, fnidx = -1, var_off = 0)

    # --- calls ----------------------------------------------------------------------

    # Push a frame for `prog.fns[fnidx]`, whose `argc` arguments are on top of
    # the stack: missing ones become undefined, extras are dropped (or
    # collected by a varargs last parameter), as for every LPC call.
    fn enter(mut self, prog: i32, fnidx: i32, var_base: i32, obj: i32, argc: i32, cells: List<i32>, ostack_before: i32):
        if self.frames.len() >= 20000:
            self.fail("Too deep recursion.\n")
            return
        let f = self.progs[prog].fns[fnidx]
        let mut n = argc
        if f.varargs:
            let fixed = f.nparams - 1
            while n < fixed:
                self.stack.push(val::Value::Undef)
                n += 1
            let rest = self.pop_args(n - fixed)
            let a = self.new_arr(rest)
            self.stack.push(a)
            n = f.nparams
        else:
            while n > f.nparams:
                self.stack.pop()
                n -= 1
            while n < f.nparams:
                self.stack.push(val::Value::Undef)
                n += 1
        while n < f.nlocals:
            self.stack.push(val::Value::Undef)
            n += 1
        let base = self.stack.len() - f.nlocals
        for i in 0..f.cell_params.len():
            let s = f.cell_params[i]
            let c = self.new_cell(self.stack[base + s])
            self.stack[base + s] = val::Value::Int(c as i64)
        self.frames.push(Frame(prog = prog, fnidx = fnidx, pc = 0, base = base, obj = obj, var_base = var_base, cells = cells, ostack_before = ostack_before))

    fn undefined_function(mut self, name: str, o: i32):
        let n = if o >= 0: self.objs[o].name else: "?"
        self.fail(f"Undefined function {name}() in {n}\n")

    # call_other(target, fname, args) from `caller`: enters a frame (true) or
    # leaves the result on the stack (false). Driver call_other().
    fn call_other_start(mut self, caller: i32, target_in: val::Value, fname_in: val::Value, args_in: List<val::Value>) -> bool:
        let mut fname = fname_in
        let mut args = args_in
        match fname_in:
            val::Value::Arr(h) ->
                let items = self.arrs[h].items
                if items.len() > 0:
                    fname = items[0]
                let mut na: List<val::Value> = List<val::Value>()
                for i in 1..items.len():
                    na.push(items[i])
                for i in 0..args_in.len():
                    na.push(args_in[i])
                args = na
            _ -> 0
        let mut target = target_in
        match target_in:
            val::Value::Arr(h) ->
                let items = self.arrs[h].items
                let mut out: List<val::Value> = List<val::Value>()
                for i in 0..items.len():
                    let t = items[i]
                    let ok = match t:
                        val::Value::Str(s) -> true
                        _ -> self.obj_of(t) >= 0
                    if ok:
                        let r = self.call_other_value(caller, t, fname, args)
                        if self.err:
                            return false
                        out.push(r)
                    else:
                        out.push(val::Value::Int(0 as i64))
                let a = self.new_arr(out)
                self.stack.push(a)
                return false
            val::Value::Str(s) ->
                let o = self.find_object(s)
                if o >= 0:
                    target = self.obj_value(o)
                else:
                    target = self.load_object(s, caller)
                    if self.err:
                        return false
            _ -> 0
        let ob = self.obj_of(target)
        if ob < 0:
            match target:
                val::Value::Obj(h, g) ->
                    self.stack.push(val::Value::Undef)
                    return false
                _ -> 0
            self.fail("Bad argument 1 to call_other()\n")
            return false
        let name = match fname:
            val::Value::Str(s) -> s
            _ -> ""
        let is_str = match fname:
            val::Value::Str(s) -> true
            _ -> false
        if !is_str:
            self.fail("Bad argument 2 to call_other()\n")
            return false
        let mut e = self.public_fn(ob, name)
        if e.prog < 0 and caller == ob:
            e = self.any_fn(ob, name)
        if e.prog < 0:
            self.stack.push(val::Value::Undef)
            return false
        let before = self.ostack.len()
        self.ensure_top(caller)
        self.opush(ob)
        if self.err:
            return false
        self.push_all(args)
        self.enter(e.prog, e.fnidx, e.var_off, ob, args.len(), List<i32>(), before)
        true

    # call_other() run to completion (for efuns and the array form)
    fn call_other_value(mut self, caller: i32, target: val::Value, fname: val::Value, args: List<val::Value>) -> val::Value:
        let depth = self.frames.len()
        let entered = self.call_other_start(caller, target, fname, args)
        if self.err:
            return val::Value::Undef
        if entered:
            self.execute(depth)
            if self.err:
                return val::Value::Undef
        self.pop()

    fn sefun_start(mut self, self_ob: i32, name: str, args: List<val::Value>) -> bool:
        if self.sefun_ob < 0 or !self.objs[self.sefun_ob].alive:
            self.fail("Unable to load the simul_efun object\n")
            return false
        let e = self.public_fn(self.sefun_ob, name)
        if e.prog < 0:
            self.fail(f"Undefined simul_efun {name}()\n")
            return false
        let before = self.ostack.len()
        self.ensure_top(self_ob)
        self.opush(self.sefun_ob)
        if self.err:
            return false
        self.push_all(args)
        self.enter(e.prog, e.fnidx, e.var_off, self.sefun_ob, args.len(), List<i32>(), before)
        true

    # Call a function value: enters a frame (true) or leaves the result on
    # the stack (false). Driver callv() + LPCFn `()`.
    fn call_fn_start(mut self, f: val::Value, args_in: List<val::Value>) -> bool:
        match f:
            val::Value::Fn(h) ->
                let s = self.fns[h]
                let mut args = args_in
                if s.bound.len() > 0:
                    let mut all = s.bound
                    for i in 0..args_in.len():
                        all.push(args_in[i])
                    args = all
                if s.kind == val::FK_DIRECT or s.kind == val::FK_CLOSURE:
                    let before = self.ostack.len()
                    if s.lpcfn:
                        self.ensure_top(s.owner)
                    self.push_all(args)
                    self.enter(s.prog, s.fnidx, s.var_base, s.owner, args.len(), s.cells, before)
                    return true
                if s.kind == val::FK_EFUN:
                    let r = self.efun(s.code, s.name, args, s.owner)
                    if !self.err:
                        self.stack.push(r)
                    return false
                if s.kind == val::FK_SEFUN:
                    return self.sefun_start(s.owner, s.name, args)
                if s.kind == val::FK_SELF:
                    let e = self.any_fn(s.owner, s.name)
                    if e.prog < 0:
                        self.undefined_function(s.name, s.owner)
                        return false
                    self.push_all(args)
                    self.enter(e.prog, e.fnidx, e.var_off, s.owner, args.len(), List<i32>(), self.ostack.len())
                    return true
                self.fail(f"Efun {s.name}() is not implemented by this driver.\n")
                return false
            _ ->
                if val::is_zero(f):
                    self.fail("Function pointer is 0\n")
                else:
                    self.fail(f"Attempt to call a non-function ({self.type_name(f)})\n")
                return false

    # Call a function value to completion (efuns calling back into LPC).
    fn call_value(mut self, f: val::Value, args: List<val::Value>) -> val::Value:
        let depth = self.frames.len()
        let entered = self.call_fn_start(f, args)
        if self.err:
            return val::Value::Undef
        if entered:
            self.execute(depth)
            if self.err:
                return val::Value::Undef
        self.pop()

    # Run one function of an object to completion.
    fn call_direct(mut self, prog: i32, fnidx: i32, var_base: i32, obj: i32, args: List<val::Value>) -> val::Value:
        let depth = self.frames.len()
        self.push_all(args)
        self.enter(prog, fnidx, var_base, obj, args.len(), List<i32>(), self.ostack.len())
        if self.err:
            return val::Value::Undef
        self.execute(depth)
        if self.err:
            return val::Value::Undef
        self.pop()

    # Function pointer to `name` resolved in `o` now (a local function
    # reference is a Pike function bound to its object).
    fn fn_virt(mut self, o: i32, name: str) -> val::Value:
        let mut e = self.public_fn(o, name)
        if e.prog < 0:
            let p = self.objs[o].prog
            if let Option::Some(x) = self.progs[p].vt.get(name):
                e = x
        if e.prog < 0:
            e = self.any_fn(o, name)
        if e.prog < 0:
            return self.new_fn(val::FnSlot(kind = val::FK_SELF, owner = o, owner_gen = self.objs[o].gen, name = name, lpcfn = true))
        self.new_fn(val::FnSlot(kind = val::FK_DIRECT, owner = o, owner_gen = self.objs[o].gen, name = name, prog = e.prog, fnidx = e.fnidx, var_base = e.var_off))

    # (: f, args :) -- driver bind_args()
    fn bind_args(mut self, f: val::Value, bound: List<val::Value>) -> val::Value:
        match f:
            val::Value::Fn(h) ->
                let mut s = self.fns[h]
                let mut b = s.bound
                for i in 0..bound.len():
                    b.push(bound[i])
                s.bound = b
                s.lpcfn = true
                return self.new_fn(s)
            _ ->
                self.fail("Bad function pointer\n")
                return val::Value::Undef

    # --- the interpreter ----------------------------------------------------------

    # Unwind an error to the innermost handler of frames >= stop. True when
    # one caught it (execution goes on there).
    fn unwind(mut self, stop: i32) -> bool:
        let nh = self.handlers.len()
        if nh > 0:
            let h = self.handlers[nh - 1]
            if h.fr_index >= stop:
                self.handlers.pop()
                while self.frames.len() > h.fr_index + 1:
                    self.frames.pop()
                self.truncate_stack(h.stack_len)
                self.truncate_ostack(h.ostack_len)
                let v = self.catch_value()
                self.clear_err()
                self.stack.push(v)
                self.frames[h.fr_index].pc = h.target
                return true
        # not caught here: drop this execute's frames
        if self.frames.len() > stop:
            let f = self.frames[stop]
            self.truncate_stack(f.base)
            self.truncate_ostack(f.ostack_before)
            while self.frames.len() > stop:
                self.frames.pop()
        while self.handlers.len() > 0 and self.handlers[self.handlers.len() - 1].fr_index >= stop:
            self.handlers.pop()
        false

    fn execute(mut self, stop: i32):
        while self.frames.len() > stop:
            if self.err:
                if !self.unwind(stop):
                    return
                continue
            let fi = self.frames.len() - 1
            let fr = self.frames[fi]
            let code = self.progs[fr.prog].fns[fr.fnidx].code
            let base = fr.base
            let obj = fr.obj
            let vbase = fr.var_base
            let mut pc = fr.pc
            let mut running = true
            while running:
                let op = code[pc]
                if op == pg::OP_LOAD_LOCAL:
                    self.stack.push(self.stack[base + code[pc + 1]])
                    pc += 2
                elif op == pg::OP_PUSH_INT:
                    self.stack.push(val::Value::Int(code[pc + 1] as i64))
                    pc += 2
                elif op == pg::OP_PUSH_CONST:
                    self.stack.push(self.progs[fr.prog].consts[code[pc + 1]])
                    pc += 2
                elif op == pg::OP_STORE_LOCAL:
                    let v = self.pop()
                    self.stack[base + code[pc + 1]] = v
                    pc += 2
                elif op == pg::OP_BIN:
                    let b = self.pop()
                    let a = self.pop()
                    let r = self.binop(code[pc + 1], a, b)
                    pc += 2
                    if self.err:
                        running = false
                    else:
                        self.stack.push(r)
                elif op == pg::OP_JZ:
                    let v = self.pop()
                    if self.truthy(v):
                        pc += 2
                    else:
                        pc = code[pc + 1]
                elif op == pg::OP_JNZ:
                    let v = self.pop()
                    if self.truthy(v):
                        pc = code[pc + 1]
                    else:
                        pc += 2
                elif op == pg::OP_JMP:
                    pc = code[pc + 1]
                elif op == pg::OP_POP:
                    self.stack.pop()
                    pc += 1
                elif op == pg::OP_DUP:
                    let n = self.stack.len()
                    self.stack.push(self.stack[n - 1])
                    pc += 1
                elif op == pg::OP_DUP2:
                    let n = self.stack.len()
                    let a = self.stack[n - 2]
                    let b = self.stack[n - 1]
                    self.stack.push(a)
                    self.stack.push(b)
                    pc += 1
                elif op == pg::OP_SWAP:
                    let n = self.stack.len()
                    let a = self.stack[n - 2]
                    self.stack[n - 2] = self.stack[n - 1]
                    self.stack[n - 1] = a
                    pc += 1
                elif op == pg::OP_LOAD_GLOBAL:
                    self.stack.push(self.objs[obj].vars[vbase + code[pc + 1]])
                    pc += 2
                elif op == pg::OP_STORE_GLOBAL:
                    let v = self.pop()
                    self.objs[obj].vars[vbase + code[pc + 1]] = v
                    pc += 2
                elif op == pg::OP_PUSH_UNDEF:
                    self.stack.push(val::Value::Undef)
                    pc += 1
                elif op == pg::OP_JZ_KEEP:
                    let n = self.stack.len()
                    if self.truthy(self.stack[n - 1]):
                        self.stack.pop()
                        pc += 2
                    else:
                        pc = code[pc + 1]
                elif op == pg::OP_JNZ_KEEP:
                    let n = self.stack.len()
                    if self.truthy(self.stack[n - 1]):
                        pc = code[pc + 1]
                    else:
                        self.stack.pop()
                        pc += 2
                elif op == pg::OP_LOAD_CELL:
                    let c = val::int_of(self.stack[base + code[pc + 1]]) as i32
                    self.stack.push(self.cells[c])
                    pc += 2
                elif op == pg::OP_STORE_CELL:
                    let v = self.pop()
                    let c = val::int_of(self.stack[base + code[pc + 1]]) as i32
                    self.cells[c] = v
                    pc += 2
                elif op == pg::OP_LOAD_UPVAL:
                    self.stack.push(self.cells[fr.cells[code[pc + 1]]])
                    pc += 2
                elif op == pg::OP_STORE_UPVAL:
                    let v = self.pop()
                    self.cells[fr.cells[code[pc + 1]]] = v
                    pc += 2
                elif op == pg::OP_MKCELL:
                    let s = base + code[pc + 1]
                    let c = self.new_cell(self.stack[s])
                    self.stack[s] = val::Value::Int(c as i64)
                    pc += 2
                elif op == pg::OP_PUSH_UPVAL_REF:
                    self.stack.push(val::Value::Int(fr.cells[code[pc + 1]] as i64))
                    pc += 2
                elif op == pg::OP_NOT:
                    let v = self.pop()
                    self.stack.push(self.bool_v(!self.truthy(v)))
                    pc += 1
                elif op == pg::OP_NEG:
                    let v = self.pop()
                    let r = self.negate(v)
                    pc += 1
                    if self.err:
                        running = false
                    else:
                        self.stack.push(r)
                elif op == pg::OP_COMPL:
                    let v = self.pop()
                    let r = self.compl(v)
                    pc += 1
                    if self.err:
                        running = false
                    else:
                        self.stack.push(r)
                elif op == pg::OP_INDEX:
                    let k = self.pop()
                    let c = self.pop()
                    let r = self.index(c, k)
                    pc += 1
                    if self.err:
                        running = false
                    else:
                        self.stack.push(r)
                elif op == pg::OP_ISTORE:
                    let v = self.pop()
                    let k = self.pop()
                    let c = self.pop()
                    let nc = self.index_store(c, k, v)
                    pc += 1
                    if self.err:
                        running = false
                    else:
                        self.stack.push(nc)
                        self.stack.push(v)
                elif op == pg::OP_ISTORE_UP:
                    let v = self.pop()
                    let sub = self.pop()
                    let k = self.pop()
                    let c = self.pop()
                    let mut nc = val::Value::Undef
                    match sub:
                        val::Value::Undef ->
                            nc = val::Value::Undef
                        _ ->
                            nc = self.index_store(c, k, sub)
                    pc += 1
                    if self.err:
                        running = false
                    else:
                        self.stack.push(nc)
                        self.stack.push(v)
                elif op == pg::OP_MEMBER:
                    let c = self.pop()
                    let r = self.member(c, code[pc + 1])
                    pc += 2
                    if self.err:
                        running = false
                    else:
                        self.stack.push(r)
                elif op == pg::OP_MSTORE:
                    let v = self.pop()
                    let c = self.pop()
                    self.member_store(c, code[pc + 1], v)
                    pc += 2
                    if self.err:
                        running = false
                    else:
                        self.stack.push(val::Value::Undef)
                        self.stack.push(v)
                elif op == pg::OP_MSTORE_UP:
                    let v = self.pop()
                    let sub = self.pop()
                    self.stack.pop()
                    let c = self.pop()
                    match sub:
                        val::Value::Undef -> 0
                        _ ->
                            self.member_store(c, code[pc + 1], sub)
                    pc += 2
                    if self.err:
                        running = false
                    else:
                        self.stack.push(val::Value::Undef)
                        self.stack.push(v)
                elif op == pg::OP_RANGE:
                    let hi = self.pop()
                    let lo = self.pop()
                    let s = self.pop()
                    let r = self.range(s, code[pc + 1], lo, hi)
                    pc += 2
                    if self.err:
                        running = false
                    else:
                        self.stack.push(r)
                elif op == pg::OP_RANGE_SET:
                    let v = self.pop()
                    let hi = self.pop()
                    let lo = self.pop()
                    let s = self.pop()
                    let r = self.range_set(s, code[pc + 1], lo, hi, v)
                    pc += 2
                    if self.err:
                        running = false
                    else:
                        self.stack.push(r)
                elif op == pg::OP_MKARRAY:
                    let items = self.pop_args(code[pc + 1])
                    let a = self.new_arr(items)
                    self.stack.push(a)
                    pc += 2
                elif op == pg::OP_ARR_APPEND:
                    let v = self.pop()
                    let n = self.stack.len()
                    match self.stack[n - 1]:
                        val::Value::Arr(h) ->
                            if h == 0:
                                self.stack[n - 1] = self.new_arr([v])
                            else:
                                self.arrs[h].items.push(v)
                        _ -> 0
                    pc += 1
                elif op == pg::OP_ARR_EXTEND:
                    let v = self.pop()
                    let n = self.stack.len()
                    match v:
                        val::Value::Arr(k) ->
                            let more = self.arrs[k].items
                            match self.stack[n - 1]:
                                val::Value::Arr(h) ->
                                    if h == 0:
                                        self.stack[n - 1] = self.new_arr(more)
                                    else:
                                        for i in 0..more.len():
                                            self.arrs[h].items.push(more[i])
                                _ -> 0
                        _ ->
                            if !val::is_zero(v):
                                self.fail("Bad argument to @ (expected array).\n")
                    pc += 1
                    if self.err:
                        running = false
                elif op == pg::OP_MKMAP:
                    let n = code[pc + 1]
                    let kv = self.pop_args(n * 2)
                    let m = self.new_map()
                    for i in 0..n:
                        self.map_set(m, kv[i * 2], kv[i * 2 + 1])
                    self.stack.push(val::Value::Map(m))
                    pc += 2
                elif op == pg::OP_THIS:
                    self.stack.push(self.obj_value(obj))
                    pc += 1
                elif op == pg::OP_CONV:
                    let v = self.pop()
                    let r = self.conv(code[pc + 1], v)
                    self.stack.push(r)
                    pc += 2
                elif op == pg::OP_RET:
                    let v = self.pop()
                    let f = self.frames[fi]
                    self.truncate_stack(f.base)
                    self.truncate_ostack(f.ostack_before)
                    while self.handlers.len() > 0 and self.handlers[self.handlers.len() - 1].fr_index >= fi:
                        self.handlers.pop()
                    self.frames.pop()
                    self.stack.push(v)
                    running = false
                elif op == pg::OP_CALL_VIRT:
                    let name = self.const_str(fr.prog, code[pc + 1])
                    let argc = code[pc + 2]
                    pc += 3
                    self.frames[fi].pc = pc
                    let p = self.objs[obj].prog
                    let mut e = pg::DispEntry(prog = -1, fnidx = -1, var_off = 0)
                    if let Option::Some(x) = self.progs[p].vt.get(name):
                        e = x
                    if e.prog < 0:
                        e = self.any_fn(obj, name)
                    if e.prog < 0:
                        self.undefined_function(name, obj)
                    else:
                        if argc < 0:
                            let a = self.take_args(argc)
                            self.push_all(a)
                            self.enter(e.prog, e.fnidx, e.var_off, obj, a.len(), List<i32>(), self.ostack.len())
                        else:
                            self.enter(e.prog, e.fnidx, e.var_off, obj, argc, List<i32>(), self.ostack.len())
                    running = false
                elif op == pg::OP_CALL_DIRECT:
                    let argc = code[pc + 4]
                    let p = code[pc + 1]
                    let fx = code[pc + 2]
                    let vo = code[pc + 3]
                    pc += 5
                    self.frames[fi].pc = pc
                    if argc < 0:
                        let a = self.take_args(argc)
                        self.push_all(a)
                        self.enter(p, fx, vbase + vo, obj, a.len(), List<i32>(), self.ostack.len())
                    else:
                        self.enter(p, fx, vbase + vo, obj, argc, List<i32>(), self.ostack.len())
                    running = false
                elif op == pg::OP_CALL_SELF:
                    let name = self.const_str(fr.prog, code[pc + 1])
                    let argc = code[pc + 2]
                    pc += 3
                    self.frames[fi].pc = pc
                    let e = self.any_fn(obj, name)
                    if e.prog < 0:
                        self.undefined_function(name, obj)
                    else:
                        let a = self.take_args(argc)
                        self.push_all(a)
                        self.enter(e.prog, e.fnidx, e.var_off, obj, a.len(), List<i32>(), self.ostack.len())
                    running = false
                elif op == pg::OP_CALL_SEFUN:
                    let name = self.const_str(fr.prog, code[pc + 1])
                    let argc = code[pc + 2]
                    pc += 3
                    self.frames[fi].pc = pc
                    let a = self.take_args(argc)
                    self.sefun_start(obj, name, a)
                    running = false
                elif op == pg::OP_CALL_EFUN:
                    let ecode = code[pc + 1]
                    let name = self.const_str(fr.prog, code[pc + 2])
                    let argc = code[pc + 3]
                    pc += 4
                    self.frames[fi].pc = pc
                    let a = self.take_args(argc)
                    let r = self.efun(ecode, name, a, obj)
                    if self.err:
                        running = false
                    else:
                        self.stack.push(r)
                        # an efun may have run LPC (nested execute); our frame is unchanged
                elif op == pg::OP_CALL_OTHER:
                    let argc = code[pc + 1]
                    pc += 2
                    self.frames[fi].pc = pc
                    let mut a: List<val::Value> = List<val::Value>()
                    let mut name = val::Value::Undef
                    let mut target = val::Value::Undef
                    if argc < 0:
                        let all = self.arr_items(self.pop())
                        if all.len() > 0:
                            target = all[0]
                        if all.len() > 1:
                            name = all[1]
                        for i in 2..all.len():
                            a.push(all[i])
                    else:
                        a = self.pop_args(argc)
                        name = self.pop()
                        target = self.pop()
                    self.call_other_start(obj, target, name, a)
                    running = false
                elif op == pg::OP_CALLV:
                    let argc = code[pc + 1]
                    pc += 2
                    self.frames[fi].pc = pc
                    let a = self.take_args(argc)
                    let f = self.pop()
                    self.call_fn_start(f, a)
                    running = false
                elif op == pg::OP_FN_VIRT:
                    let name = self.const_str(fr.prog, code[pc + 1])
                    let f = self.fn_virt(obj, name)
                    self.stack.push(f)
                    pc += 2
                elif op == pg::OP_FN_DIRECT:
                    let f = self.new_fn(val::FnSlot(kind = val::FK_DIRECT, owner = obj, owner_gen = self.objs[obj].gen, prog = code[pc + 1], fnidx = code[pc + 2], var_base = vbase + code[pc + 3]))
                    self.stack.push(f)
                    pc += 4
                elif op == pg::OP_FN_SELF or op == pg::OP_FN_SEFUN or op == pg::OP_FN_UNDEF:
                    let name = self.const_str(fr.prog, code[pc + 1])
                    let kind = if op == pg::OP_FN_SELF: val::FK_SELF elif op == pg::OP_FN_SEFUN: val::FK_SEFUN else: val::FK_UNDEF
                    let f = self.new_fn(val::FnSlot(kind = kind, owner = obj, owner_gen = self.objs[obj].gen, name = name, lpcfn = true))
                    self.stack.push(f)
                    pc += 2
                elif op == pg::OP_FN_EFUN:
                    let name = self.const_str(fr.prog, code[pc + 2])
                    let f = self.new_fn(val::FnSlot(kind = val::FK_EFUN, owner = obj, owner_gen = self.objs[obj].gen, name = name, code = code[pc + 1], lpcfn = true))
                    self.stack.push(f)
                    pc += 3
                elif op == pg::OP_BIND:
                    let a = self.pop_args(code[pc + 1])
                    let f = self.pop()
                    let r = self.bind_args(f, a)
                    pc += 2
                    if self.err:
                        running = false
                    else:
                        self.stack.push(r)
                elif op == pg::OP_MKCLOSURE:
                    let cfi = code[pc + 1]
                    let ndv = code[pc + 2]
                    let nref = code[pc + 3]
                    let refs = self.pop_args(nref)
                    let dvs = self.pop_args(ndv)
                    let kinds = self.progs[fr.prog].fns[cfi].upval_kinds
                    let mut cl: List<i32> = List<i32>()
                    let mut di = 0
                    let mut ri = 0
                    for i in 0..kinds.len():
                        if kinds[i] == pg::UV_DOLLAR:
                            cl.push(self.new_cell(dvs[di]))
                            di += 1
                        else:
                            cl.push(val::int_of(refs[ri]) as i32)
                            ri += 1
                    let f = self.new_fn(val::FnSlot(kind = val::FK_CLOSURE, owner = obj, owner_gen = self.objs[obj].gen, prog = fr.prog, fnidx = cfi, var_base = vbase, cells = cl))
                    self.stack.push(f)
                    pc += 4
                elif op == pg::OP_CATCH_BEGIN:
                    self.handlers.push(Handler(fr_index = fi, target = code[pc + 1], stack_len = self.stack.len(), ostack_len = self.ostack.len()))
                    pc += 2
                elif op == pg::OP_CATCH_END:
                    self.handlers.pop()
                    pc += 1
                elif op == pg::OP_FE_INIT:
                    let n = code[pc + 1]
                    let s = base + code[pc + 2]
                    let v = self.pop()
                    pc += 3
                    self.fe_init(n, s, v)
                    if self.err:
                        running = false
                elif op == pg::OP_FE_NEXT:
                    let n = code[pc + 1]
                    let s = base + code[pc + 2]
                    if self.fe_next(n, s):
                        pc += 4
                    else:
                        pc = code[pc + 3]
                elif op == pg::OP_NEWCLASS:
                    let name = self.const_str(fr.prog, code[pc + 1])
                    let size = code[pc + 2]
                    let n = code[pc + 3]
                    let vals = self.pop_args(n)
                    let mut slots: List<val::Value> = List<val::Value>()
                    for i in 0..size:
                        slots.push(val::Value::Int(0 as i64))
                    for i in 0..n:
                        slots[code[pc + 4 + i]] = vals[i]
                    let h = self.clss.len()
                    self.clss.push(val::ClsSlot(name = name, vals = slots))
                    self.stack.push(val::Value::Cls(h))
                    pc += 4 + n
                elif op == pg::OP_EVAL_DEFAULT:
                    let v = self.pop()
                    pc += 1
                    match v:
                        val::Value::Fn(h) ->
                            self.frames[fi].pc = pc
                            let r = self.call_value(v, List<val::Value>())
                            if self.err:
                                running = false
                            else:
                                self.stack.push(r)
                        _ -> self.stack.push(v)
                elif op == pg::OP_TIME_BEGIN:
                    self.stack[base + code[pc + 1]] = val::Value::Int(clock() as i64)
                    pc += 2
                elif op == pg::OP_TIME_END:
                    let t0 = val::int_of(self.stack[base + code[pc + 1]])
                    self.stack.push(val::Value::Int(((clock() as i64) - t0) * (1000 as i64)))
                    pc += 2
                else:
                    self.fail(f"bad opcode {op} at {pc}")
                    running = false
            if self.frames.len() == fi + 1:
                self.frames[fi].pc = pc

    fn const_str(self, prog: i32, k: i32) -> str:
        match self.progs[prog].consts[k]:
            val::Value::Str(s) -> s
            _ -> ""

    # foreach: iteration state in locals s (container), s+1 (keys snapshot
    # or 0), s+2 (position) -- driver fe1()/fe2()
    fn fe_init(mut self, n: i32, s: i32, v: val::Value):
        let mut cont = v
        let mut keys = val::Value::Undef
        match v:
            val::Value::Map(h) ->
                keys = self.new_arr(self.maps[h].keys)
                if n == 1:
                    cont = keys
            val::Value::Arr(h) ->
                cont = v
            val::Value::Str(str_v) ->
                if n == 1:
                    let b = bytes_from_str(str_v)
                    let mut items: List<val::Value> = List<val::Value>()
                    for i in 0..b.len():
                        items.push(val::Value::Int(b[i] as i64))
                    cont = self.new_arr(items)
                else:
                    self.fail("foreach() on a non-mapping\n")
                    return
            _ ->
                if val::is_zero(v):
                    cont = self.new_arr(List<val::Value>())
                else:
                    if n == 1:
                        self.fail("foreach() on a non-array\n")
                    else:
                        self.fail("foreach() on a non-mapping\n")
                    return
        self.stack[s] = cont
        self.stack[s + 1] = keys
        self.stack[s + 2] = val::Value::Int(0 as i64)

    fn fe_next(mut self, n: i32, s: i32) -> bool:
        let cont = self.stack[s]
        let i = val::int_of(self.stack[s + 2]) as i32
        match cont:
            val::Value::Arr(h) ->
                if i >= self.arrs[h].items.len():
                    return false
                self.stack[s + 2] = val::Value::Int((i + 1) as i64)
                if n == 2:
                    self.stack.push(val::Value::Int(i as i64))
                self.stack.push(self.arrs[h].items[i])
                return true
            val::Value::Map(h) ->
                let keys = self.arr_items(self.stack[s + 1])
                if i >= keys.len():
                    return false
                self.stack[s + 2] = val::Value::Int((i + 1) as i64)
                self.stack.push(keys[i])
                self.stack.push(self.map_get(h, keys[i]))
                return true
            _ -> false

    # --- programs and objects ---------------------------------------------------

    # Normalise an LPC path: absolute, no ".c" (compiler.pike normalize()).
    fn normalize(self, path_in: str, relative_to: str) -> str:
        let mut path = path_in
        if str_ends_with(path, ".c"):
            path = substr(path, 0, len(path) - 2)
        if path == "":
            return "/"
        if !str_starts_with(path, "/"):
            let base = if relative_to != "": paths::dirname(relative_to) else: "/"
            path = paths::combine_path(base, path)
        paths::combine_path("/", path)

    fn compile_tokens(mut self, path: str, toks: List<tk::Token>) -> i32:
        for i in 0..toks.len():
            if toks[i].kind == tk::Tk::Bad:
                self.compile_error = f"{path}.c:{toks[i].line}: bad token {toks[i].text}"
                return -1
        let p = ps::parse_tokens(toks, self.pp.files)
        if p.had_error:
            self.compile_error = p.error
            return -1
        let mut inh: List<cc::InhIn> = List<cc::InhIn>()
        for i in 0..p.top.len():
            match p.nodes[p.top[i]].kind:
                ast::NodeKind::Inherit(ipath, label, mods) ->
                    let ip = self.normalize(ipath, concat(path, ".c"))
                    if self.compiling.contains(ip):
                        self.compile_error = f"{path}.c: recursive inherit of {ip}"
                        return -1
                    let id = self.compile_program(ip)
                    if id < 0:
                        return -1
                    let lbl = if label != "": label else: cc::base_name_of(ip)
                    inh.push(cc::InhIn(id = id, prog = self.progs[id], path = ip, label = lbl))
                _ -> 0
        let id = self.progs.len()
        let mut c = cc::new_compiler(p.nodes, self.pp.files, path, id, inh, self.sefun_names, self.sefun_types, path == self.sefun_path, self.efun_codes, self.ref_efuns, self.known_efuns)
        let prog = c.compile_program(p.top)
        if c.had_error:
            self.compile_error = c.error
            return -1
        self.progs.push(prog)
        self.prog_by_path.insert(path, id)
        id

    fn compile_program(mut self, path: str) -> i32:
        if let Option::Some(id) = self.prog_by_path.get(path):
            return id
        self.compiling.insert(path)
        self.pp.preprocess(concat(path, ".c"))
        if self.pp.had_error:
            self.compile_error = self.pp.error
            self.compiling.remove(path)
            return -1
        let toks = self.pp.out
        let id = self.compile_tokens(path, toks)
        self.compiling.remove(path)
        id

    # Compile LPC source text as program `path` (always afresh).
    fn compile_source(mut self, path: str, src: str) -> i32:
        self.prog_by_path.remove(path)
        self.compiling.insert(path)
        self.pp.preprocess_string(concat(path, ".c"), src)
        if self.pp.had_error:
            self.compile_error = self.pp.error
            self.compiling.remove(path)
            return -1
        let toks = self.pp.out
        let id = self.compile_tokens(path, toks)
        self.compiling.remove(path)
        id

    fn find_object(self, path_in: str) -> i32:
        let path = self.normalize(path_in, "")
        if let Option::Some(o) = self.obj_by_name.get(path):
            if self.objs[o].alive:
                return o
        -1

    fn run_inits(mut self, o: i32, pid: i32, base: i32):
        let p = self.progs[pid]
        for i in 0..p.inherits.len():
            self.run_inits(o, p.inherits[i].prog, base + p.inherits[i].var_off)
            if self.err:
                return
        if p.init_fn >= 0:
            self.call_direct(pid, p.init_fn, base, o, List<val::Value>())

    # A new object of program `pid`: variables initialised, then registered
    # under `name` (the reference instantiates, then register_object()s).
    fn new_object(mut self, pid: i32, name: str, clone: bool) -> i32:
        let o = self.objs.len()
        let mut vars: List<val::Value> = List<val::Value>()
        for i in 0..self.progs[pid].nvars:
            vars.push(val::Value::Undef)
        self.objs.push(ObjSlot(prog = pid, gen = 0, name = name, alive = true, vars = vars, clone = clone, load_time = epoch_now()))
        self.run_inits(o, pid, 0)
        if self.err:
            self.objs[o].alive = false
            return -1
        self.obj_by_name.insert(name, o)
        o

    fn call_create(mut self, o: i32, caller: i32, args: List<val::Value>):
        let e = self.any_fn(o, "create")
        if e.prog < 0:
            return
        let before = self.ostack.len()
        self.ensure_top(caller)
        self.opush(o)
        if self.err:
            return
        self.call_direct(e.prog, e.fnidx, e.var_off, o, args)
        self.truncate_ostack(before)

    # The simul_efun names programs compile against: every name in the
    # simul_efun program's function table (driver refresh_sefuns(), which
    # takes prototypes and static functions too) and their return types.
    fn set_sefuns_from(mut self, pid: i32):
        self.sefun_names = Set<str>()
        self.sefun_types = Map<str, str>()
        if pid < 0:
            return
        let p = self.progs[pid]
        for i in 0..p.all_func_names.len():
            self.sefun_names.insert(p.all_func_names[i])
        self.sefun_types = p.func_types

    fn refresh_sefuns(mut self):
        if self.sefun_ob < 0:
            self.set_sefuns_from(-1)
            return
        self.set_sefuns_from(self.objs[self.sefun_ob].prog)

    # The driver's config-derived predefined macros (driver create()).
    # `__NO_RESETS__`/`__LAZY_RESETS__` follow the reset settings, which
    # arrive with resets themselves (M5).
    fn configure(mut self, mud_name: str, port: i32):
        self.config.insert("name", mud_name)
        self.config.insert("port", f"{port}")
        self.pp.predefine("MUD_NAME", esc_quoted(mud_name))
        self.pp.predefine("__PORT__", f"{port}")
        self.pp.predefine("__HAVOKOS__", "1")
        self.pp.predefine("__OPCPROF__", "")
        self.pp.predefine("__CACHE_STATS__", "")

    # driver load_object()
    fn load_object(mut self, path_in: str, caller: i32) -> val::Value:
        let path = self.normalize(path_in, "")
        if str_contains(path, "#"):
            return self.obj_value(self.find_object(path))
        let found = self.find_object(path)
        if found >= 0:
            return self.obj_value(found)
        if self.loading.contains(path):
            self.fail(f"Recursive load of {path}\n")
            return val::Value::Undef
        if !file_exists(concat(self.root, concat(path, ".c"))):
            return val::Value::Int(0 as i64)
        self.loading.insert(path)
        let pid = self.compile_program(path)
        if pid < 0:
            self.loading.remove(path)
            self.log.push(self.compile_error)
            self.fail(f"*Error in loading object '{path}'\n")
            return val::Value::Undef
        let inh = self.progs[pid].inherits
        for i in 0..inh.len():
            if self.find_object(inh[i].path) < 0:
                self.load_object(inh[i].path, caller)
                if self.err:
                    self.loading.remove(path)
                    return val::Value::Undef
        let o = self.new_object(pid, path, false)
        if o < 0:
            self.loading.remove(path)
            return val::Value::Undef
        if path == self.sefun_path:
            self.sefun_ob = o
            self.refresh_sefuns()
        self.call_create(o, caller, List<val::Value>())
        self.loading.remove(path)
        if self.err:
            return val::Value::Undef
        self.obj_value(o)

    # driver clone_object()
    fn clone_object(mut self, path_in: str, args: List<val::Value>, caller: i32) -> val::Value:
        let path = self.normalize(path_in, "")
        let mc = self.load_object(path, caller)
        if self.err:
            return val::Value::Undef
        let m = self.obj_of(mc)
        if m < 0:
            self.fail(f"*Unable to load {path} for cloning\n")
            return val::Value::Undef
        self.clone_count += 1
        let name = f"{path}#{self.clone_count}"
        let o = self.new_object(self.objs[m].prog, name, true)
        if o < 0:
            return val::Value::Undef
        self.call_create(o, caller, args)
        if self.err:
            return val::Value::Undef
        self.obj_value(o)

    # Boot (driver boot()): the simul_efun object first, so every later
    # program compiles against its function names, then the master. As in
    # FluffOS, master applies made while the master's own create() runs are
    # skipped: master_ob is only set once it has returned. The master's
    # other boot duties (privs, epilog/preload) come with the object model
    # (M5); M4 needs it for the file efuns' valid_read/valid_write.
    fn boot(mut self, sefun_path: str, master_path: str) -> bool:
        self.sefun_path = sefun_path
        self.load_object(sefun_path, -1)
        if self.err:
            self.log.push(f"boot: {self.errmsg}")
            return false
        if master_path == "":
            return true
        self.master_path = self.normalize(master_path, "")
        let m = self.load_object(self.master_path, -1)
        if self.err:
            self.log.push(f"boot: master: {self.errmsg}")
            return false
        self.master_ob = self.obj_of(m)
        if self.master_ob < 0:
            self.log.push(f"boot: master {self.master_path} not found")
            return false
        true

    # --- rendering (tools/run_cases.star; ref_cases.pike's render()) ---------------

    fn render(mut self, v: val::Value) -> str:
        match v:
            val::Value::Undef -> "0"
            val::Value::Int(x) -> int_str(x)
            val::Value::Real(x) -> concat("F", fmt_float(x))
            val::Value::Str(s) -> esc_quoted(s)
            val::Value::Arr(h) ->
                let items = self.arrs[h].items
                let mut parts: List<str> = List<str>()
                for i in 0..items.len():
                    parts.push(self.render(items[i]))
                concat(concat("({", str_join(parts, ",")), "})")
            val::Value::Map(h) ->
                let ks = self.maps[h].keys
                let vs = self.maps[h].vals
                let mut parts: List<str> = List<str>()
                for i in 0..ks.len():
                    parts.push(concat(concat(self.render(ks[i]), ":"), self.render(vs[i])))
                let mut a = 1
                while a < parts.len():
                    let x = parts[a]
                    let mut b = a - 1
                    while b >= 0 and str_cmp(x, parts[b]) < 0:
                        parts[b + 1] = parts[b]
                        b -= 1
                    parts[b + 1] = x
                    a += 1
                concat(concat("([", str_join(parts, ",")), "])")
            val::Value::Obj(h, g) ->
                if self.objs[h].alive and self.objs[h].gen == g:
                    return concat("OB:", self.objs[h].name)
                "0"
            val::Value::Cls(h) ->
                let vals = self.clss[h].vals
                let mut parts: List<str> = ["\"CLASS\""]
                for i in 0..vals.len():
                    parts.push(self.render(vals[i]))
                concat(concat("({", str_join(parts, ",")), "})")
            val::Value::Fn(h) -> "FN"
