# Compiled LPC programs: the bytecode format `compiler.star` produces and
# `vm.star` runs -- todo.md HavokOS M3.
#
# The reference has no counterpart: `lpc/emitter.pike` writes Pike source
# and Pike's own compiler and runtime take it from there. Star can't compile
# code at runtime, so each LPC program becomes a `Program` of `FnDef`s whose
# bodies are flat `List<i32>` instruction streams (opcode, then its inline
# operands) for a stack machine.
#
# Why a stack machine with inline `i32` operands: it keeps the compiler a
# straight AST walk (the emitter's shape, so the two stay comparable case by
# case) and the instruction stream a single flat list the interpreter can
# hold in a local while a frame runs. A register machine would save stack
# traffic but needs an allocator in the compiler; that can come later if
# profiling the booted mudlib says the interpreter loop is the bottleneck.
#
# Object variables: a program's variable block is its inherits' blocks laid
# out in inherit order, then its own variables. Code always addresses
# variables relative to the block of the program it was compiled in (the
# frame's `var_base`), so an inherited function runs unchanged inside any
# object that inherits it -- the same "inherited code sees its own variables
# at a fixed offset" model FluffOS uses.

import "value.star" as val

# --- opcodes -----------------------------------------------------------------
# Stack effects are written (before -- after). `k` = constant pool index,
# `s` = local slot, `g` = global variable index relative to var_base.

const OP_PUSH_INT: i32 = 1        # imm             ( -- int)
const OP_PUSH_CONST: i32 = 2      # k               ( -- v)
const OP_PUSH_UNDEF: i32 = 3      #                 ( -- undef)
const OP_POP: i32 = 4             #                 (v -- )
const OP_DUP: i32 = 5             #                 (v -- v v)
const OP_DUP2: i32 = 6            #                 (a b -- a b a b)
const OP_SWAP: i32 = 7            #                 (a b -- b a)
const OP_LOAD_LOCAL: i32 = 8      # s
const OP_STORE_LOCAL: i32 = 9     # s               (v -- )
const OP_LOAD_GLOBAL: i32 = 10    # g
const OP_STORE_GLOBAL: i32 = 11   # g               (v -- )
const OP_LOAD_CELL: i32 = 12      # s   local s holds a cell id (a captured local)
const OP_STORE_CELL: i32 = 13     # s               (v -- )
const OP_LOAD_UPVAL: i32 = 14     # n   closure upvalue n
const OP_STORE_UPVAL: i32 = 15    # n               (v -- )
const OP_MKCELL: i32 = 16         # s   box local s's value into a fresh cell
const OP_PUSH_UPVAL_REF: i32 = 17 # n   ( -- cell id of upvalue n), for a nested closure
const OP_BIN: i32 = 20            # binop           (a b -- r)
const OP_NEG: i32 = 21
const OP_NOT: i32 = 22
const OP_COMPL: i32 = 23
const OP_JMP: i32 = 24            # addr
const OP_JZ: i32 = 25             # addr            (v -- )
const OP_JNZ: i32 = 26            # addr            (v -- )
const OP_JZ_KEEP: i32 = 27        # addr  falsy: jump, keeping v; else pop
const OP_JNZ_KEEP: i32 = 28       # addr  truthy: jump, keeping v; else pop
const OP_INDEX: i32 = 30          #                 (c k -- v)
const OP_ISTORE: i32 = 31         #                 (c k v -- c' v)
const OP_ISTORE_UP: i32 = 32      #                 (c k sub v -- c' v)
const OP_MEMBER: i32 = 33         # pos             (c -- v)
const OP_MSTORE: i32 = 34         # pos             (c v -- c v)
const OP_MSTORE_UP: i32 = 35      # pos             (c sub v -- c v)
const OP_RANGE: i32 = 36          # flags           (s lo hi -- r)
const OP_RANGE_SET: i32 = 37      # flags           (s lo hi v -- s')
const OP_MKARRAY: i32 = 38        # n               (v1..vn -- arr)
const OP_ARR_APPEND: i32 = 39     #                 (arr v -- arr)
const OP_ARR_EXTEND: i32 = 40     #                 (arr arr2 -- arr)   `@arr2`
const OP_MKMAP: i32 = 41          # n               (k1 v1 .. kn vn -- map)
const OP_CALL_VIRT: i32 = 42      # k(name) argc
const OP_CALL_DIRECT: i32 = 43    # prog fnidx var_off argc
const OP_CALL_SELF: i32 = 44      # k(name) argc   prototype-only: resolved by name at runtime
const OP_CALL_SEFUN: i32 = 45     # k(name) argc
const OP_CALL_EFUN: i32 = 46      # code k(name) argc
const OP_CALL_OTHER: i32 = 47     # argc            (ob name args -- r)
const OP_CALLV: i32 = 48          # argc            (f args -- r)
const OP_RET: i32 = 49            #                 (v -- )
const OP_FN_VIRT: i32 = 50        # k(name)  pointer to a function, resolved in this object now
const OP_FN_DIRECT: i32 = 51      # prog fnidx var_off
const OP_FN_SELF: i32 = 52        # k(name)
const OP_FN_SEFUN: i32 = 53       # k(name)
const OP_FN_EFUN: i32 = 54        # code k(name)
const OP_FN_UNDEF: i32 = 55       # k(name)
const OP_BIND: i32 = 56           # argc            (f args -- f')
const OP_MKCLOSURE: i32 = 57      # fnidx ndv nref  (dv1..dvn ref1..refm -- f)
const OP_CATCH_BEGIN: i32 = 58    # addr  error/throw lands at addr with the catch value pushed
const OP_CATCH_END: i32 = 59      #       drop the innermost handler
const OP_CONV: i32 = 60           # mode (CONV_*)   (v -- v')
const OP_FE_INIT: i32 = 61        # nvars s         (v -- )  iteration state in locals s..s+2
const OP_FE_NEXT: i32 = 62        # nvars s addr    ( -- v | k v), or jump to addr when done
const OP_THIS: i32 = 63           #                 ( -- this_object())
const OP_NEWCLASS: i32 = 64       # k(name) size n pos1..posn   (v1..vn -- cls)
const OP_EVAL_DEFAULT: i32 = 65   #                 (v -- v')  default argument: call it if callable
const OP_TIME_BEGIN: i32 = 66     # s
const OP_TIME_END: i32 = 67       # s               ( -- elapsed)

# OP_BIN operators. The C* forms are the reference's driver helpers for a
# compound assignment that keeps an int slot an int (`compound_add` ...);
# PDIV/PMOD are Pike's own flooring `/` and `%`, which the reference's
# emitter falls back to for `a[f()] /= x` (an lvalue it can't re-read).
const B_ADD: i32 = 1
const B_SUB: i32 = 2
const B_MUL: i32 = 3
const B_DIV: i32 = 4
const B_MOD: i32 = 5
const B_AND: i32 = 6
const B_OR: i32 = 7
const B_XOR: i32 = 8
const B_SHL: i32 = 9
const B_SHR: i32 = 10
const B_EQ: i32 = 11
const B_NE: i32 = 12
const B_LT: i32 = 13
const B_LE: i32 = 14
const B_GT: i32 = 15
const B_GE: i32 = 16
const B_CADD: i32 = 21
const B_CSUB: i32 = 22
const B_CMUL: i32 = 23
const B_CDIV: i32 = 24
const B_PDIV: i32 = 25
const B_PMOD: i32 = 26

# OP_CONV modes: the emitter's `emit_assigned()` conversions and LPC casts
const CONV_F2I: i32 = 1
const CONV_I2F: i32 = 2
const CONV_INT: i32 = 3
const CONV_FLOAT: i32 = 4
const CONV_STRING: i32 = 5

# OP_RANGE / OP_RANGE_SET flags
const R_HAS_LO: i32 = 1
const R_LO_END: i32 = 2
const R_HAS_HI: i32 = 4
const R_HI_END: i32 = 8

# OP_MKCLOSURE upvalue sources, per upvalue, in FnDef.upval_kinds
const UV_DOLLAR: i32 = 1   # a `$(expr)` value, evaluated when the closure is made
const UV_REF: i32 = 2      # a captured enclosing local (its cell)

# --- programs ------------------------------------------------------------------

struct FnDef:
    mut name: str
    # declared return type (the emitter's `func_types`, for int/float
    # assignment conversion at call sites)
    mut typ: str = "mixed"
    mut nparams: i32 = 0
    # the last parameter collects the remaining arguments as an array
    mut varargs: bool = false
    # local slots including parameters and compiler temporaries
    mut nlocals: i32 = 0
    mut code: List<i32> = List<i32>()
    # parameters captured by a closure, boxed into cells on entry
    mut cell_params: List<i32> = List<i32>()
    mut is_static: bool = false
    mut is_private: bool = false
    # closures only
    mut upval_kinds: List<i32> = List<i32>()

# How a name reaches a function: the defining program and function, and the
# offset of that program's variable block inside the program the entry
# belongs to.
struct DispEntry:
    mut prog: i32
    mut fnidx: i32
    mut var_off: i32
    mut is_static: bool = false

struct InheritInfo:
    mut prog: i32
    mut path: str
    # the LPC label: an explicit `inherit "x" : label;`, else the file's base name
    mut label: str
    mut var_off: i32

struct ClassDef:
    mut name: str
    mut members: List<str>
    mut types: List<str>

struct Program:
    mut path: str
    mut inherits: List<InheritInfo> = List<InheritInfo>()
    mut nvars: i32 = 0
    mut own_var_start: i32 = 0
    # own variables, in layout order
    mut var_names: List<str> = List<str>()
    mut var_nosave: List<bool> = List<bool>()
    mut fns: List<FnDef> = List<FnDef>()
    mut consts: List<val::Value> = List<val::Value>()
    mut init_fn: i32 = -1
    # Virtual dispatch: every non-private function reachable by name (later
    # inherits override earlier ones, own definitions override both) -- what
    # an unqualified call in code and call_other() resolve against.
    mut vt: Map<str, DispEntry> = Map<str, DispEntry>()
    # The reference's `__lpc_fn`: own definitions (private included) first,
    # then each inherit's in inherit order -- prototype calls and
    # call_other() from the object itself resolve against this one.
    mut anyt: Map<str, DispEntry> = Map<str, DispEntry>()
    mut anyt_names: List<str> = List<str>()
    # --- compile-time tables an inheriting program reads (the reference's meta) ---
    # function name -> true for a definition, false for a prototype only
    mut all_funcs: Map<str, bool> = Map<str, bool>()
    mut all_func_names: List<str> = List<str>()
    mut func_types: Map<str, str> = Map<str, str>()
    # visible (non-private) variable -> index relative to this program's block
    mut all_vars: Map<str, i32> = Map<str, i32>()
    mut all_var_names: List<str> = List<str>()
    mut global_types: Map<str, str> = Map<str, str>()
    mut classes: Map<str, ClassDef> = Map<str, ClassDef>()
    mut class_names: List<str> = List<str>()
