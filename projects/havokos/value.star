# LPC runtime values -- todo.md HavokOS M3 (bytecode compiler + VM core).
#
# The Pike reference never needed a value model of its own: every LPC value
# *is* a Pike value, and Pike's own arrays and mappings are shared by
# reference exactly as LPC requires. Star's `List<T>` is copy-on-write
# (NOTES.md constraint #1), so an LPC array can't simply be a `List<Value>`
# inside the enum -- `a = b; b[0] = 1` would leave `a` unchanged. Instead
# every reference-semantics value (array, mapping, function pointer, class
# instance) lives in a VM-owned slot table (`vm.star`'s `Vm.arrs`, `maps`,
# ...) and a `Value` only carries the integer handle, so copying a `Value`
# copies the reference, as in LPC. Strings and numbers are immutable and stay
# inline.
#
# `Undef` is FluffOS's "undefined" zero: it behaves as int 0 everywhere
# except `undefinedp()`, and is what an uninitialised variable, a missing
# argument and a missed mapping lookup hold (Pike's `UNDEFINED`, which the
# reference relies on for the same thing).
#
# Floats are `f64`. The reference's Pike on this machine is a 32-bit-float
# build (`Pike.get_runtime_info()->float_size` is 32), which is an accident
# of that build rather than LPC semantics; FluffOS uses doubles, and both
# print floats with 6 significant digits, so results only differ past the
# 7th digit. NOTES.md "Deliberate deviations" #3.
#
# Objects carry a generation next to the slot index so a slot can be reused
# after a destruct (M5) without stale `Value::Obj`s reaching the new object.

enum Value:
    Undef
    Int(v: i64)
    Real(v: f64)
    Str(s: str)
    Arr(h: i32)
    Map(h: i32)
    Obj(h: i32, gen: i32)
    Fn(h: i32)
    Cls(h: i32)

struct ArrSlot:
    mut items: List<Value>

# An LPC mapping: insertion-ordered key/value columns plus a hash index from
# `MKey` to the row. Star's `Map` can't key on `Value` (a payload-carrying
# enum isn't hashable, constraint #4), so each key is flattened into the
# hashable `MKey` struct. Deleting swaps the last row into the hole.
struct MapSlot:
    mut keys: List<Value>
    mut vals: List<Value>
    mut idx: Map<MKey, i32>

# `t`: 1 int (and undefined, which is 0 as a key, as in Pike), 2 float,
# 3 string, 4 array, 5 mapping, 6 object, 7 function, 8 class. An int is split
# into two `i32` halves since `Map` keys can't hold an `i64`.
struct MKey:
    t: i32
    s: str
    a: i32
    b: i32

# Function pointer kinds, mirroring the reference's two families: plain
# Pike functions (a local function reference, a functional/lambda closure)
# and its `LPCFn` wrapper (efun/simul_efun/prototype pointers, and any
# pointer with bound arguments), which `functionp()` reports differently.
const FK_DIRECT: i32 = 1
const FK_SELF: i32 = 2
const FK_EFUN: i32 = 3
const FK_SEFUN: i32 = 4
const FK_UNDEF: i32 = 5
const FK_CLOSURE: i32 = 6

struct FnSlot:
    mut kind: i32
    # owning object (handle, generation); -1 for none
    mut owner: i32
    mut owner_gen: i32
    # efun/simul_efun/function name (FK_SELF/EFUN/SEFUN/UNDEF)
    mut name: str = ""
    # efun dispatch code (FK_EFUN); 0 = not implemented by this VM yet
    mut code: i32 = 0
    # FK_DIRECT/FK_CLOSURE: function to run and the object variable block it
    # runs against
    mut prog: i32 = -1
    mut fnidx: i32 = -1
    mut var_base: i32 = 0
    # FK_CLOSURE: captured cells (upvalues), in the closure's upvalue order
    mut cells: List<i32> = List<i32>()
    # arguments bound when the pointer was made (`(: f, a, b :)`), passed first
    mut bound: List<Value> = List<Value>()
    # true for the reference's `LPCFn` (functionp() flags), false for a plain
    # Pike function (functionp() == 1)
    mut lpcfn: bool = false
    # bind() of a local function or closure (M5): the owner the driver sees
    # (call_out ownership, function_owner()), pushed as current object around
    # each call; the code still runs in `owner`. -1 when not rebound.
    mut bound_owner: i32 = -1
    mut bound_gen: i32 = 0

# An LPC class (struct) instance: positional, like FluffOS; member names
# are resolved to positions at compile time.
struct ClsSlot:
    name: str
    mut vals: List<Value>

fn is_zero(v: Value) -> bool:
    match v:
        Value::Undef -> true
        Value::Int(x) -> x == (0 as i64)
        _ -> false

fn int_of(v: Value) -> i64:
    match v:
        Value::Int(x) -> x
        _ -> 0 as i64

fn mkey(v: Value) -> MKey:
    match v:
        Value::Undef -> MKey(t = 1, s = "", a = 0, b = 0)
        Value::Int(x) -> MKey(t = 1, s = "", a = (x >> 32) as i32, b = (x & (((1 as i64) << 32) - (1 as i64))) as i32)
        Value::Real(x) -> MKey(t = 2, s = f"{x}:{x * (1000000000.0 as f64)}", a = 0, b = 0)
        Value::Str(s) -> MKey(t = 3, s = s, a = 0, b = 0)
        Value::Arr(h) -> MKey(t = 4, s = "", a = h, b = 0)
        Value::Map(h) -> MKey(t = 5, s = "", a = h, b = 0)
        Value::Obj(h, g) -> MKey(t = 6, s = "", a = h, b = g)
        Value::Fn(h) -> MKey(t = 7, s = "", a = h, b = 0)
        Value::Cls(h) -> MKey(t = 8, s = "", a = h, b = 0)
