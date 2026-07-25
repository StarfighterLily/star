# Operator overloading (`todo.md` P2 #7's other half): before this feature,
# no type -- generic or concrete -- could give `+ - * / % == != < > <= >=`
# (or unary `-`) any meaning beyond what a handful of hardcoded builtin
# types (`Int`/`Float`/`Vec2`/`Wrapping<T>`/...) already had. A user struct
# could satisfy a trait bound and have its trait methods *called* from a
# bounded generic body, but never let that same body use an *operator* on
# it -- `fn total<T: Add>(a: T, b: T) -> T: return a + b` had no way to
# type-check, even once `impl Add for Point:` existed, since `+`/`-`/`==`/...
# only ever dispatched on a fixed set of builtin `Ty` variants.
#
# Each overloadable operator maps to one canonical trait/method pair --
# `+` -> `Add::add`, `-` -> `Sub::sub`, `==`/`!=` -> `Eq::eq` (`!=` is `!eq(...)`,
# so implementing `Eq` gets you both), `< > <= >=` -> `Ord::{lt,gt,le,ge}`
# (four independent methods, not derived from a single `cmp` -- a trait
# declaring only `lt` yields support for only `<`), and unary `-` ->
# `Neg::neg`. `a + b` desugars to `a.add(b)` at type-check time, so it
# reuses the exact same method-call codegen a hand-written `.add(...)` call
# already gets -- see `Checker::try_operator_overload_call` and
# `tests/frontend.rs`'s "operator overloading" test block for the
# accept/reject/codegen-shape coverage.

trait Add:
    fn add(self, rhs: Self) -> Self

trait Sub:
    fn sub(self, rhs: Self) -> Self

trait Eq:
    fn eq(self, rhs: Self) -> bool

trait Ord:
    fn lt(self, rhs: Self) -> bool
    fn gt(self, rhs: Self) -> bool

trait Neg:
    fn neg(self) -> Self

struct Point:
    x: i32
    y: i32

impl Add for Point:
    fn add(self, rhs: Point) -> Point:
        return Point(x = self.x + rhs.x, y = self.y + rhs.y)

impl Sub for Point:
    fn sub(self, rhs: Point) -> Point:
        return Point(x = self.x - rhs.x, y = self.y - rhs.y)

impl Eq for Point:
    fn eq(self, rhs: Point) -> bool:
        return self.x == rhs.x and self.y == rhs.y

impl Ord for Point:
    fn lt(self, rhs: Point) -> bool:
        return self.x < rhs.x
    fn gt(self, rhs: Point) -> bool:
        return self.x > rhs.x

impl Neg for Point:
    fn neg(self) -> Point:
        return Point(x = 0 - self.x, y = 0 - self.y)

# A trait-bounded generic function using `+` (not just calling a trait
# method) on its bounded type parameter -- the exact capability this
# feature adds. Once monomorphized against `Point`, `a + b` here resolves
# through the same `Add`-trait dispatch as the concrete calls in `main`
# below.
fn total<T: Add>(a: T, b: T) -> T:
    return a + b

fn main():
    let a = Point(x = 1, y = 2)
    let b = Point(x = 3, y = 4)

    let sum = a + b
    println(f"sum: {sum.x}, {sum.y}")

    let diff = a - b
    println(f"diff: {diff.x}, {diff.y}")

    let neg = -a
    println(f"neg: {neg.x}, {neg.y}")

    println(f"eq: {a == a}")
    println(f"ne: {a != b}")
    println(f"lt: {a < b}")

    let t = total(Point(x = 2, y = 3), Point(x = 4, y = 6))
    println(f"total: {t.x}, {t.y}")
