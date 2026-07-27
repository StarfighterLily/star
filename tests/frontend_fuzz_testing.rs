//! Self-contained fuzzer over the lex/parse/check pipeline
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Fuzz testing ==========================================================
//
// No fuzzing crate is available (no external dependency was added for it), so
// this is a small self-contained fuzzer: a xorshift PRNG mutates a handful of
// known-good seed programs (byte insert/delete/replace), and each mutated
// input is fed through the full front-end pipeline (lexer, parser, and type
// checker -- the same stages `star check` runs, minus module resolution,
// which the seeds below never exercise since none of them `import`) on a
// worker thread with a bounded timeout. A second fuzzer feeds the same
// pipeline uniformly random bytes with no plausible-Star-source bias at all,
// covering `ir_check.rs`'s `fuzz_never_panics`'s original motivation one
// layer earlier: raw user text hits the lexer/parser/checker *before* any
// hand-rolled IR ever could. Every run must either succeed or return a clean
// `Err`, and must always terminate -- `parser_error_uses_friendly_token_
// names`'s sibling test class is exactly how the module-scope stray-`Dedent`
// infinite loop fixed alongside this test suite was first found by hand;
// this harness exists to catch the next one automatically instead of by
// hand-crafted example.

/// A minimal xorshift64* PRNG so the fuzzer has no external dependency.
struct Rng(u64);

impl Rng {
    fn next_u64(&mut self) -> u64 {
        self.0 ^= self.0 << 13;
        self.0 ^= self.0 >> 7;
        self.0 ^= self.0 << 17;
        self.0
    }

    fn next_usize(&mut self, bound: usize) -> usize {
        (self.next_u64() as usize) % bound.max(1)
    }
}

/// Apply a handful of random byte-level mutations (insert/delete/replace) to
/// `seed`, capped at a small size so a single input can't blow up runtime.
fn mutate(seed: &str, rng: &mut Rng) -> String {
    let mut bytes: Vec<u8> = seed.as_bytes().to_vec();
    let mutations = 1 + rng.next_usize(6);
    // Bytes plausible in Star source: identifiers, punctuation, whitespace,
    // and indentation -- pure random bytes would almost always just fail
    // lexing immediately without ever reaching interesting parser states.
    let alphabet: &[u8] = b"abcXYZ012 \t\n:=+-*/(){}[]<>!.,_@\"";
    for _ in 0..mutations {
        if bytes.is_empty() {
            bytes.push(alphabet[rng.next_usize(alphabet.len())]);
            continue;
        }
        match rng.next_usize(3) {
            0 => {
                let i = rng.next_usize(bytes.len());
                bytes[i] = alphabet[rng.next_usize(alphabet.len())];
            }
            1 => {
                let i = rng.next_usize(bytes.len());
                bytes.remove(i);
            }
            _ => {
                let i = rng.next_usize(bytes.len() + 1);
                bytes.insert(i, alphabet[rng.next_usize(alphabet.len())]);
            }
        }
        if bytes.len() > 400 {
            bytes.truncate(400);
        }
    }
    // Mutation can land mid-codepoint; a fuzz input isn't required to stay
    // valid UTF-8-adjacent-safe, but the driver API takes `&str`, so repair
    // it by dropping any invalid tail bytes rather than skipping the case.
    String::from_utf8_lossy(&bytes).into_owned()
}

/// Run `f` on a worker thread and fail the test if it panics or fails to
/// return within `timeout` (the latter is how the module-scope stray-`Dedent`
/// infinite loop this suite fixed would have shown up here).
fn run_bounded(label: &str, input: &str, timeout: std::time::Duration, f: impl FnOnce(&str) + Send + 'static) {
    let owned = input.to_string();
    let (tx, rx) = std::sync::mpsc::channel();
    std::thread::spawn(move || {
        let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| f(&owned)));
        let _ = tx.send(result);
    });
    match rx.recv_timeout(timeout) {
        Ok(Ok(())) => {}
        Ok(Err(payload)) => std::panic::resume_unwind(payload),
        Err(_) => panic!("{} timed out (possible infinite loop) on input: {:?}", label, input),
    }
}

/// Run the full front-end pipeline `star check` runs -- lex, parse, then
/// type-check on a successful parse -- discarding the result. Never panics
/// on its own; any panic from a stage below propagates to the caller so
/// `run_bounded` can catch and report it against the offending input.
fn check_pipeline(src: &str) {
    if let Ok(module) = star::parser::Parser::parse_source(src) {
        let _ = Driver::check(&module);
    }
}

/// Fuzz the lexer, parser, and type checker with mutated inputs derived from
/// known-good programs, asserting every run either succeeds or returns a
/// clean `Err` -- never panics, never hangs. 2,000 cases to match
/// `ir_check.rs`'s `fuzz_never_panics` methodology one layer earlier in the
/// pipeline.
#[test]
fn fuzz_lexer_parser_checker_do_not_panic() {
    let seeds = [
        include_str!("../examples/player.star"),
        include_str!("../examples/vecmath.star"),
        include_str!("../examples/stdlib.star"),
        "struct P:\n    @export mut x: i32 = 0\n",
        "fn f(a: i32) -> i32:\n    a + 1\n",
        "sequence S(x: i32):\n    yield\n",
        "par e in Enemies:\n    e.hp -= 1\n",
        "for i in 0..3:\n    break\n",
        "enum E:\n    A\n    B\n",
        "enum E:\n    A\n    B(x: i32, y: i32)\n",
    ];

    let mut rng = Rng(0x2545_F491_4F6C_DD1D);
    let timeout = std::time::Duration::from_secs(2);
    for i in 0..2000 {
        let seed = seeds[rng.next_usize(seeds.len())];
        let input = mutate(seed, &mut rng);
        let label = format!("iteration {}", i);
        run_bounded(&label, &input, timeout, |src| check_pipeline(src));
    }
}

/// Generate `len` uniformly random bytes (the full `0..=255` range, not the
/// plausible-Star-source alphabet `mutate` restricts itself to), repaired to
/// valid UTF-8 the same lossy way `mutate` does since the driver API takes
/// `&str`. Unlike `mutate`'s seed-derived inputs, this has no bias toward
/// ever getting past the lexer's first few tokens -- it exists to cover the
/// raw-garbage end of the input space `mutate` structurally can't reach.
fn random_bytes(len: usize, rng: &mut Rng) -> String {
    let bytes: Vec<u8> = (0..len).map(|_| rng.next_usize(256) as u8).collect();
    String::from_utf8_lossy(&bytes).into_owned()
}

/// Fuzz the same full pipeline with pure random bytes instead of mutated
/// real programs, asserting every run either succeeds or returns a clean
/// `Err` -- never panics, never hangs. 2,000 cases, matching
/// `ir_check.rs`'s `fuzz_never_panics`.
#[test]
fn fuzz_full_pipeline_random_bytes_do_not_panic() {
    let mut rng = Rng(0x9E37_79B9_7F4A_7C15);
    let timeout = std::time::Duration::from_secs(2);
    for i in 0..2000 {
        let len = rng.next_usize(300);
        let input = random_bytes(len, &mut rng);
        let label = format!("iteration {}", i);
        run_bounded(&label, &input, timeout, |src| check_pipeline(src));
    }
}
