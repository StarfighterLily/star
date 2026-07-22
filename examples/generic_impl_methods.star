struct Box<T>:
    mut value: T

# A generic struct's inherent impl block: `impl Box<T>:` binds `T` to the
# same type parameter `struct Box<T>:` declares, so every method below sees
# `T`/`self` substituted consistently with whichever concrete instantiation
# (`Box__i32`, `Box__str`, ...) the receiver actually is.
impl Box<T>:
    fn get(self) -> T:
        return self.value

    fn set(mut self, v: T):
        self.value = v

    # `self` used as a plain value (not just `self.field`) -- returning the
    # receiver itself by value, as an ordinary struct-typed expression.
    fn replaced(mut self, v: T) -> Box<T>:
        self.value = v
        return self

    # One method calling another on the same receiver, inside the same
    # generic impl block -- exercises that both share one signature
    # registration pass before either body is checked.
    fn get_twice(self) -> T:
        return self.get()

struct Pair<A, B>:
    first: A
    second: B

impl Pair<A, B>:
    fn first(self) -> A:
        return self.first

    fn second(self) -> B:
        return self.second

trait Describable:
    fn describe(self) -> str

# A trait impl on a generic struct -- `impl Trait for Box<T>:`.
impl Describable for Pair<A, B>:
    fn describe(self) -> str:
        return "a pair"

# The motivating use case from this project's own dev notes: a generic
# `Stack<T>` wrapper with mutating methods, backed by a `List<T>` field --
# previously inexpressible (`impl Stack<T>:` was a hard parse error), used
# here as a plain undo-history stack.
struct Stack<T>:
    mut items: List<T>

impl Stack<T>:
    fn push(mut self, v: T):
        self.items.push(v)

    fn pop(mut self) -> T:
        return self.items.pop()

    fn len(self) -> i32:
        return self.items.len()

fn main():
    let mut b = Box(value = 5)
    println(f"box get: {b.get()}")
    b.set(10)
    println(f"box after set: {b.get()}")
    println(f"box get_twice: {b.get_twice()}")
    let b2 = b.replaced(20)
    println(f"box replaced: {b2.get()}")

    let bs = Box(value = "hi")
    println(f"box str: {bs.get()}")

    let p = Pair(first = 1, second = "two")
    println(f"pair: {p.first()} {p.second()}")
    println(f"describe: {p.describe()}")

    let mut history = Stack(items = List<i32>())
    history.push(1)
    history.push(2)
    history.push(3)
    println(f"history len: {history.len()}")
    println(f"undo: {history.pop()}")
    println(f"undo: {history.pop()}")
    println(f"history len: {history.len()}")
