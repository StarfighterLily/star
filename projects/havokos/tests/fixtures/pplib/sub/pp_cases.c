// Preprocessor edge cases, compared token-for-token against the Pike
// reference's cpp() by tests/run_pp_cases_test.ps1.
#include <inc_a.h>
#include INC_B
#include "local.h"

#define OBJ 1 + 2
#define F(x) ((x) * 2)
#define G(a, b) a - b
#define Z() zero_args
#define ONE(x) [x]
int o = OBJ;
int f1 = F(3);
int f2 = F(F(4));
int g1 = G(F(1), OBJ);
int z = Z();
mixed e = ONE();
int noparen = F;

// self-reference and mutual recursion terminate
#define foo foo + 1
#define ping pong
#define pong ping
int s = foo;
int p = ping;

// a function-like name produced by an expansion takes its args from after it
#define H F
int h = H(5);

// arguments containing commas inside nested brackets
#define FIRST(a, b) a
mixed arr = FIRST(({ 1, 2 }), 3);
mixed map = FIRST(([ "k": 1, "j": 2 ]), 0);
mixed fn = FIRST((: $1 + $2 :), 0);
mixed call = FIRST(foo(1, 2), bar(3));

// multi-line invocation
int ml = G(10,
           20);

// stringify and paste
#define STR(x) #x
#define CAT(a, b) a ## b
#define XSTR(x) STR(x)
string st = STR(hello world);
string st2 = XSTR(OBJ);
int CAT(var, 1) = 5;
int cat2 = CAT(12, 34);

// conditionals
#if defined(OBJ) && !defined(NOPE)
int c1 = 1;
#elif 1
int c1 = 2;
#else
int c1 = 3;
#endif
#if (1 << 4) == 16 && (7 % 4) == 3 ? 1 : 0
int c2 = 1;
#endif
#if NOPE
int c3 = 1;
#elif GLOBAL_SEEN
int c3 = 2;
#endif
#ifdef OBJ trailing junk here
int c4 = 1;
#endif
#ifndef OBJ
int c5 = 0;
#else
#  if 0
int c5 = 1;
#  else
int c5 = 2;
#  endif
#endif
#if 0
this is not code at all ; } ) ]
#endif
#undef OBJ
#ifdef OBJ
int c6 = 1;
#endif
int c7 = efun_defined(nonexistent_efun);

// line continuation and comments inside a definition
#define LONG(a) a + \
    a /* comment */ + a // trailing
int lg = LONG(2);

int line_here = __LINE__;
string file = __FILE__;
string dir = __DIR__;

// literals
int ch = 'a' + '\n' + '\x41' + '\101';
int hx = 0x1F + 0b101 + 1_000;
float fl = 1.5 + .25 + 2e3 + 1.;
mixed rng = arr[1..2];
string esc = "tab\there \"q\" back\\slash \x41\101 unknown\q";
string raw = "line one
line two";
mixed lines = @@END
alpha
beta
END
;
int after = 1;
