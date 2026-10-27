//! `len(s)`, `s[i]` and `ord(s)` read a length cached in the `str`'s RC
//! header instead of running `strlen` each time.
//!
//! `s[i]`'s bounds check called `strlen`, so scanning a string a byte at a
//! time was quadratic: about 70 s for 1 MB (found porting HavokOS, which
//! worked around it with `Bytes` everywhere hot; `todo.md` HavokOS P2 #2).
//! A `str` never has a release function, so its header's `release_fn` slot
//! now holds the length with bit 63 set, filled in by the first query
//! (`@star_str_len`) or, for a literal, at compile time; `star_rc_release`
//! treats a negative slot as "no release function". See
//! `Codegen::emit_rc_runtime` for why a lazy cache rather than a third
//! header slot or a length stored by every builder.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

fn run(name: &str, src: &str) -> String {
    let out = compile_and_run(name, src);
    assert!(out.status.success(), "exit {:?}, stderr {}", out.status, String::from_utf8_lossy(&out.stderr));
    String::from_utf8_lossy(&out.stdout).replace("\r\n", "\n")
}

fn ir_of(src: &str) -> String {
    Driver::codegen(&Driver::check(&Driver::parse(src).unwrap()).unwrap()).unwrap()
}

/// `s[i]` calls the cached-length helper, not `strlen`.
#[test]
fn codegen_str_index_uses_cached_length_not_strlen() {
    let ir = ir_of("fn f(s: str, i: i32) -> i32:\n    return s[i]\n\nfn main():\n    println(f\"{f(\"ab\", 1)}\")\n");
    let body = extract_fn_body(&ir, "define i32 @f(");
    assert!(body.contains("call i32 @star_str_len("), "{}", body);
    assert!(!body.contains("@strlen"), "{}", body);
}

/// A literal's header carries its length precomputed (bit 63 set), since
/// its header is a read-only constant the helper can't store into.
#[test]
fn codegen_literal_header_holds_tagged_length() {
    let ir = ir_of("fn main():\n    println(f\"{len(\"hello\")}\")\n");
    // 5 | i64::MIN
    assert!(ir.contains("i8* inttoptr (i64 -9223372036854775803 to i8*), [6 x i8] c\"hello\\00\""), "{}", ir);
}

/// The length, bytes and out-of-range reads of literals, including the
/// empty one and a byte with its high bit set.
#[test]
fn runtime_literal_len_index_ord() {
    let out = run("strlen_cache_literal", "fn main():
    let s = \"abc\"
    println(f\"{len(s)} {s[0]} {s[2]} {s[3]} {s[-1]} {ord(s)}\")
    let e = \"\"
    println(f\"{len(e)} {e[0]} {ord(e)}\")
    let h = \"\u{e9}\"
    println(f\"{len(h)} {h[0]} {h[1]}\")
");
    assert_eq!(out, "3 97 99 0 0 97\n0 0 0\n2 195 169\n");
}

/// Heap strings from several builders answer the same before and after
/// the length is cached (the second read of each is a cache hit).
#[test]
fn runtime_heap_strings_same_answer_on_cache_hit() {
    let out = run("strlen_cache_heap", "fn show(s: str):
    println(f\"{len(s)} {s[0]} {s[len(s) - 1]} {s[len(s)]} | {len(s)} {s[0]} {s[len(s) - 1]} {s[len(s)]}\")

fn main():
    show(concat(\"xy\", \"z\"))
    let n = 42
    show(f\"n={n}\")
    show(str_trim(\"  pad  \"))
    show(str_replace(\"aXa\", \"X\", \"YY\"))
    show(chr(65))
    let b = chr(0)
    println(f\"{len(b)} {b[0]} {ord(b)}\")
");
    assert_eq!(out, "3 120 122 0 | 3 120 122 0\n\
                     4 110 50 0 | 4 110 50 0\n\
                     3 112 100 0 | 3 112 100 0\n\
                     4 97 97 0 | 4 97 97 0\n\
                     1 65 65 0 | 1 65 65 0\n\
                     0 0 0\n");
}

/// A `str` field never assigned (a null pointer) reads as empty in all
/// three: `len` used to pass it straight to `strlen`.
#[test]
fn runtime_null_str_reads_as_empty() {
    let out = run("strlen_cache_null", "struct Holder:
    val: str

arena Holders: Holder

fn main():
    spawn Holders(\"present\")
    let h = Handle<Holder>(0)
    despawn Holders[0]
    let n: str = h[0].val
    println(f\"{len(n)} {n[0]} {ord(n)}\")
");
    assert_eq!(out, "0 0 0\n");
}

/// A string whose length was cached is still freed normally: the tagged
/// slot isn't called as a release function (a crash) and doesn't stop the
/// free (a leak).
#[test]
fn runtime_cached_strings_are_freed() {
    assert_no_leak("strlen_cache_free", "fn main():
    let mut total = 0
    let mut i = 0
    while i < 3000000:
        let s = concat(\"abcdefghijklmnopqrstuvwxyz\", f\"{i}\")
        total = total + len(s) + s[3]
        i = i + 1
    println(f\"{total}\")
    println(\"done\")
", 64 * 1024 * 1024);
}

/// Lists, whose header slot holds a real release function, still release
/// their `str` elements after those elements' lengths were cached.
#[test]
fn runtime_list_of_cached_strings_releases() {
    assert_no_leak("strlen_cache_list", "fn main():
    let mut total = 0
    let mut i = 0
    while i < 300000:
        let xs = [concat(\"aa\", f\"{i}\"), concat(\"bbb\", \"c\")]
        total = total + len(xs[0]) + xs[1][2]
        i = i + 1
    println(f\"{total}\")
    println(\"done\")
", 64 * 1024 * 1024);
}

/// A byte-at-a-time scan of 1 MB is linear now: it took about 70 s when
/// every `s[i]` ran `strlen`, and finishes in well under a second.
#[test]
fn runtime_scan_of_one_megabyte_is_linear() {
    let start = std::time::Instant::now();
    let out = run("strlen_cache_scan", "fn main():
    let mut s = \"a\"
    let mut k = 0
    while k < 20:
        s = concat(s, s)
        k = k + 1
    let mut sum = 0
    let mut i = 0
    while i < len(s):
        sum = sum + s[i]
        i = i + 1
    println(f\"{len(s)} {sum}\")
");
    assert_eq!(out, "1048576 101711872\n");
    let secs = start.elapsed().as_secs_f64();
    assert!(secs < 30.0, "the scan took {:.1} s (includes clang)", secs);
}

/// `star_str_len` is a runtime helper's name, reserved like
/// `star_rc_release`.
#[test]
fn star_str_len_is_a_reserved_name() {
    let module = Driver::parse("extern \"C\" fn star_str_len(s: str) -> i32\nfn main():\n    println(\"x\")\n").unwrap();
    let errs = Driver::check(&module).err().expect("should be rejected");
    assert!(errs.iter().any(|d| d.message.contains("collides with a symbol")), "{:?}", errs.iter().map(|d| &d.message).collect::<Vec<_>>());
}
