# Trait-bounded generics (`todo.md` P2 #7): `fn f<T: SomeTrait>(x: T)`.
#
# Before this feature, a generic function could only move/store/return a
# bare `T` -- there was no syntax to declare that `T` must implement a
# specific trait, so calling a trait method (or, transitively, anything an
# operator or another generic desugars into) on a generic parameter had no
# compiler-enforced contract: whatever the call site's concrete type
# happened to support "just worked" (or failed with a confusing error deep
# inside the generic body), with no clean diagnostic pointing at the actual
# problem -- the call site passing a type that doesn't fulfil what the
# generic body needs.
#
# `<T: Trait>` fixes that: the checker now rejects a call/construction whose
# concrete type argument doesn't implement every bound its type parameter
# declares, with a diagnostic that names the offending type, the bound, and
# the generic function/struct/enum -- see `rejects_generic_fn_call_violating_trait_bound`
# and its neighbors in `tests/frontend.rs` for the rejection-side coverage.

trait Speaker:
    fn speak(self) -> str

trait Named:
    fn name(self) -> str

struct Dog:
    volume: i32

impl Speaker for Dog:
    fn speak(self) -> str:
        return "Woof"

impl Named for Dog:
    fn name(self) -> str:
        return "Rex"

struct Cat:
    pitch: i32

impl Speaker for Cat:
    fn speak(self) -> str:
        return "Meow"

# A single trait bound: the body may call any method `Speaker` requires on
# `x`, regardless of which concrete type the caller passes, as long as that
# type implements `Speaker`. Duck-typing an unbounded `T` would already let
# this *compile* against a type that happens to have a `speak` method (this
# compiler monomorphizes a generic body against its call site's concrete
# type before checking it) -- what a bound adds is a clean, declared
# contract and a diagnostic pointing at the actual violation (an
# unsatisfied bound) instead of a raw "no method `speak` on type `X`" once
# some later call site passes a type that doesn't have one at all.
fn announce<T: Speaker>(x: T) -> str:
    return x.speak()

# Multiple bounds (`T: A + B`, mirroring a plain type parameter's `A, B`
# list grammar): the body may call methods from every named trait.
fn introduce<T: Speaker + Named>(x: T) -> str:
    return f"{x.name()} says {x.speak()}"

# A trait-bounded generic struct: every instantiation of `Cage<T>` must bind
# `T` to a type that implements `Speaker`, checked the same way a bounded
# generic function's call-site type argument is -- at construction, not
# merely if/when a method that happens to need it is later called.
struct Cage<T: Speaker>:
    occupant: T

impl Cage<T>:
    fn announce_occupant(self) -> str:
        return self.occupant.speak()

fn main():
    let d = Dog(volume = 7)
    let c = Cat(pitch = 3)
    println(f"dog: {announce(d)}")
    println(f"cat: {announce(c)}")
    println(f"intro: {introduce(d)}")

    let cage = Cage(occupant = Dog(volume = 1))
    println(f"caged: {cage.announce_occupant()}")

    # Uncommenting either line below is a compile-time trait-bound
    # violation, not a runtime failure or a confusing deep-body error:
    #
    #   announce(5)            # error: `Int` does not satisfy the trait
    #                           # bound `T: Speaker` required by function
    #                           # `announce`
    #   Cage(occupant = 5)      # error: `Int` does not satisfy the trait
    #                           # bound `T: Speaker` required by struct
    #                           # `Cage`
