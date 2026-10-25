# Array, mapping and math efuns -- todo.md HavokOS M4 (efuns), the "Arrays
# and mappings" and "Math" parts of `havok/efuns.pike` beyond the M3 subset
# (sizeof/allocate/keys/values/member_array/sort_array/map/filter stay in
# `efuns.star`).
#
# Where the reference leans on a Pike built-in, that built-in's behavior is
# the semantics: max()/min() compare with Pike's `>`/`<` (numbers
# numerically, strings bytewise, anything else an error), unique_array()
# groups by mapping-key identity (equal ints/strings group, distinct arrays
# don't) in first-seen order, round() rounds halves up.
#
# random() and shuffle() draw from the VM's own 64-bit generator (splitmix64,
# `Vm.rng`) rather than Star's `rand()`: that one is a 32-bit xorshift
# behind a lock, returning a float, and LPC's random(n) takes a 64-bit n.
# The generator is seeded from the clock at boot, so nothing here is
# reproducible run to run -- the test cases check ranges and membership.

import "value.star" as val
import "vm.star" as vm
import "efun_table.star" as et

fn num_f(v: val::Value) -> f64:
    match v:
        val::Value::Real(x) -> x
        val::Value::Int(x) -> x as f64
        _ -> 0.0 as f64

# Pike's round(): halves round up, towards +infinity (round(-2.5) is -2.0,
# probed against the live reference)
fn round_half_up(x: f64) -> f64:
    floor(x + (0.5 as f64))

impl vm::Vm:
    # xorshift64* (Vigna); the state is never 0 once seeded. `>>` on i64 is
    # arithmetic, so each right shift is masked to make it logical.
    fn next_rand(mut self) -> i64:
        if self.rng == (0 as i64):
            self.rng = vm::wadd(vm::wmul(vm::epoch_now(), 1103515245 as i64), (vm::clock_now() as i64) + (12345 as i64))
            if self.rng == (0 as i64):
                self.rng = 88172645 as i64
        let mut x = self.rng
        x = x ^ ((x >> 12) & ((((1 as i64) << 52) - (1 as i64))))
        x = x ^ (x << 25)
        x = x ^ ((x >> 27) & ((((1 as i64) << 37) - (1 as i64))))
        self.rng = x
        # 0x2545F4914F6CDD1D, built from halves (NOTES.md constraint #6)
        let mul = ((625341585 as i64) << 32) + (1332534557 as i64)
        vm::wmul(x, mul)

    # uniform in [0, n), n > 0
    fn rand_below(mut self, n: i64) -> i64:
        let mut r = self.next_rand() % n
        if r < (0 as i64):
            r = r + n
        r

    # Pike's `a > b` for max()/min(); sets an error on incomparable values
    fn pike_gt(mut self, a: val::Value, b: val::Value) -> bool:
        if self.is_num(a) and self.is_num(b):
            match a:
                val::Value::Real(x) ->
                    return x > num_f(b)
                _ -> 0
            match b:
                val::Value::Real(y) ->
                    return num_f(a) > y
                _ -> 0
            return val::int_of(a) > val::int_of(b)
        match a:
            val::Value::Str(s) ->
                match b:
                    val::Value::Str(t) ->
                        return vm::str_cmp(s, t) > 0
                    _ -> 0
            _ -> 0
        self.fail("Bad argument 1 to `>.\n")
        false

    fn deep_copy(mut self, v: val::Value) -> val::Value:
        match v:
            val::Value::Arr(h) ->
                let items = self.arrs[h].items
                let mut out: List<val::Value> = List<val::Value>()
                for i in 0..items.len():
                    out.push(self.deep_copy(items[i]))
                return self.new_arr(out)
            val::Value::Map(h) ->
                let ks = self.maps[h].keys
                let vs = self.maps[h].vals
                let m = self.new_map()
                for i in 0..ks.len():
                    let c = self.deep_copy(vs[i])
                    self.map_set(m, ks[i], c)
                return val::Value::Map(m)
            val::Value::Cls(h) ->
                let vals = self.clss[h].vals
                let mut out: List<val::Value> = List<val::Value>()
                for i in 0..vals.len():
                    out.push(self.deep_copy(vals[i]))
                return self.new_cls(val::ClsSlot(name = self.clss[h].name, vals = out))
            _ ->
                return v

    fn is_callable(self, v: val::Value) -> bool:
        match v:
            val::Value::Fn(h) -> true
            _ -> false

    fn efun_arr(mut self, code: i32, name: str, args: List<val::Value>, self_ob: i32) -> val::Value:
        if code == et::E_ALLOCATE_MAPPING:
            let m = self.new_map()
            let kv = self.arg(args, 0)
            match kv:
                val::Value::Arr(h) ->
                    let ks = self.arrs[h].items
                    let vals = self.arg(args, 1)
                    let vitems = self.arr_items(vals)
                    let is_arr = match vals:
                        val::Value::Arr(x) -> true
                        _ -> false
                    for i in 0..ks.len():
                        let mut v = vals
                        if is_arr:
                            if i < vitems.len():
                                v = vitems[i]
                            else:
                                self.fail("Index out of range in allocate_mapping()\n")
                                return val::Value::Undef
                        elif self.is_callable(vals):
                            v = self.call_value(vals, [ks[i]])
                            if self.err:
                                return val::Value::Undef
                        self.map_set(m, ks[i], v)
                _ -> 0
            return val::Value::Map(m)
        if code == et::E_UNIQUE_ARRAY:
            let items = self.arr_items(self.arg(args, 0))
            let f = self.arg(args, 1)
            let has_skip = args.len() > 2
            let skip = self.arg(args, 2)
            let groups = self.new_map()
            let mut lists: List<List<val::Value>> = List<List<val::Value>>()
            for i in 0..items.len():
                let v = items[i]
                let mut k = val::Value::Undef
                match f:
                    val::Value::Str(s) ->
                        k = self.call_other_value(self_ob, v, f, List<val::Value>())
                    _ ->
                        k = self.call_value(f, [v])
                if self.err:
                    return val::Value::Undef
                if has_skip and self.lpc_eq(k, skip):
                    continue
                let gi = self.map_find(groups, k)
                if gi < 0:
                    self.map_set(groups, k, val::Value::Int(lists.len() as i64))
                    lists.push([v])
                else:
                    let li = val::int_of(self.maps[groups].vals[gi]) as i32
                    lists[li].push(v)
            let mut out: List<val::Value> = List<val::Value>()
            for i in 0..lists.len():
                out.push(self.new_arr(lists[i]))
            return self.new_arr(out)
        if code == et::E_UNIQUE_MAPPING:
            let items = self.arr_items(self.arg(args, 0))
            let f = self.arg(args, 1)
            let mut rest: List<val::Value> = List<val::Value>()
            for i in 2..args.len():
                rest.push(args[i])
            let m = self.new_map()
            for i in 0..items.len():
                let v = items[i]
                let mut k = val::Value::Undef
                match f:
                    val::Value::Str(s) ->
                        k = self.call_other_value(self_ob, v, f, rest)
                    _ ->
                        let mut a: List<val::Value> = [v]
                        for j in 0..rest.len():
                            a.push(rest[j])
                        k = self.call_value(f, a)
                if self.err:
                    return val::Value::Undef
                let old = self.map_get(m, k)
                let mut l = self.arr_items(old)
                l.push(v)
                self.map_set(m, k, self.new_arr(l))
            return val::Value::Map(m)
        if code == et::E_MAP_DELETE:
            let m = self.arg(args, 0)
            match m:
                val::Value::Map(h) ->
                    self.map_delete(h, self.arg(args, 1))
                _ -> 0
            return m
        if code == et::E_COPY:
            return self.deep_copy(self.arg(args, 0))
        if code == et::E_MATCH_PATH:
            return self.efun_match_path(self.arg(args, 0), self.arg(args, 1))
        if code == et::E_ELEMENT_OF:
            let items = self.arr_items(self.arg(args, 0))
            if items.len() == 0:
                self.fail("Bad argument 1 to element_of()\n")
                return val::Value::Undef
            return items[self.rand_below(items.len() as i64) as i32]
        if code == et::E_SHUFFLE:
            let mut items = self.arr_items(self.arg(args, 0))
            let mut i = items.len() - 1
            while i > 0:
                let j = self.rand_below((i + 1) as i64) as i32
                let t = items[i]
                items[i] = items[j]
                items[j] = t
                i -= 1
            return self.new_arr(items)
        if code == et::E_MAX or code == et::E_MIN:
            let items = self.arr_items(self.arg(args, 0))
            if items.len() == 0:
                return val::Value::Int(0 as i64)
            let mut bi = 0
            for i in 0..items.len():
                let better = if code == et::E_MAX: self.pike_gt(items[i], items[bi]) else: self.pike_gt(items[bi], items[i])
                if self.err:
                    return val::Value::Undef
                if better:
                    bi = i
            if self.truthy(self.arg(args, 1)):
                return val::Value::Int(bi as i64)
            return items[bi]
        # --- math
        if code == et::E_RANDOM:
            let n = val::int_of(self.arg(args, 0))
            if n <= (0 as i64):
                return val::Value::Int(0 as i64)
            return val::Value::Int(self.rand_below(n))
        if code == et::E_ABS:
            let v = self.arg(args, 0)
            match v:
                val::Value::Real(x) ->
                    if x < (0.0 as f64):
                        return val::Value::Real((0.0 as f64) - x)
                    return v
                val::Value::Int(x) ->
                    if x < (0 as i64):
                        return val::Value::Int(vm::wsub(0 as i64, x))
                    return v
                _ ->
                    return v
        let x = num_f(self.conv(4, self.arg(args, 0)))
        if code == et::E_SQRT:
            return val::Value::Real(sqrt(x))
        if code == et::E_POW:
            return val::Value::Real(pow(x, num_f(self.conv(4, self.arg(args, 1)))))
        if code == et::E_EXP:
            return val::Value::Real(exp(x))
        if code == et::E_LOG:
            return val::Value::Real(log(x))
        if code == et::E_LOG10:
            return val::Value::Real(log(x) / log(10.0 as f64))
        if code == et::E_LOG2:
            return val::Value::Real(log(x) / log(2.0 as f64))
        if code == et::E_SIN:
            return val::Value::Real(sin(x))
        if code == et::E_COS:
            return val::Value::Real(cos(x))
        if code == et::E_TAN:
            return val::Value::Real(tan(x))
        if code == et::E_ASIN:
            return val::Value::Real(asin(x))
        if code == et::E_ACOS:
            return val::Value::Real(acos(x))
        if code == et::E_ATAN:
            return val::Value::Real(atan(x))
        if code == et::E_FLOOR:
            return val::Value::Real(floor(x))
        if code == et::E_CEIL:
            return val::Value::Real(ceil(x))
        if code == et::E_ROUND:
            return val::Value::Real(round_half_up(x))
        self.fail(f"Efun {name}() is not implemented by this driver.\n")
        val::Value::Undef

    # The value of the longest path prefix of `path` ("/", "/a/", "/a/b/",
    # "/a/b/c") in m (efuns.pike match_path()).
    fn efun_match_path(mut self, mv: val::Value, pv: val::Value) -> val::Value:
        let h = match mv:
            val::Value::Map(x) -> x
            _ -> -1
        let path = match pv:
            val::Value::Str(s) -> s
            _ -> ""
        if h < 0:
            return val::Value::Undef
        let mut value = val::Value::Undef
        let mut prefix = ""
        let parts = str_split(path, "/")
        let n = parts.len()
        for i in 0..n:
            let p = parts[i]
            if p == "" and i < n - 1:
                if prefix == "":
                    prefix = "/"
                continue
            prefix = concat(prefix, p)
            if i < n - 1:
                prefix = concat(prefix, "/")
            let at = self.map_find(h, val::Value::Str(prefix))
            if at >= 0:
                let v = self.maps[h].vals[at]
                match v:
                    val::Value::Undef -> 0
                    _ ->
                        value = v
        let root = self.map_find(h, val::Value::Str("/"))
        if path == "/" or path == "":
            if root >= 0:
                value = self.maps[h].vals[root]
        elif root >= 0:
            match value:
                val::Value::Undef ->
                    value = self.maps[h].vals[root]
                _ -> 0
        value
