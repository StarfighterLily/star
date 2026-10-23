# Efun dispatch codes -- todo.md HavokOS M3.
#
# The compiler decides *whether* a call is an efun call by the reference's
# own name sets (`efun_names.star`), so name resolution matches the
# emitter's even for efuns this VM doesn't implement yet. This table only
# says which of those the VM can run today: a call compiles to
# `OP_CALL_EFUN code`, and code 0 raises the reference's "Efun X() is not
# implemented by this driver." at runtime, exactly what the reference does
# for a FluffOS efun it lacks.
#
# M3 implements the efuns the language-semantics cases need (type
# predicates, the function-pointer efuns, error/throw, the object-loading
# core of call_other); the full library is M4.

const E_UNDEFINEDP: i32 = 1
const E_SIZEOF: i32 = 2
const E_EVALUATE: i32 = 3
const E_EXPLODE: i32 = 4
const E_MAP: i32 = 5
const E_FILTER: i32 = 6
const E_SORT_ARRAY: i32 = 7
const E_UPPER_CASE: i32 = 8
const E_LOWER_CASE: i32 = 9
const E_FUNCTIONP: i32 = 10
const E_ERROR: i32 = 11
const E_THROW: i32 = 12
const E_CLASSP: i32 = 13
const E_LOAD_OBJECT: i32 = 14
const E_FIND_OBJECT: i32 = 15
const E_CLONE_OBJECT: i32 = 16
const E_THIS_OBJECT: i32 = 17
const E_PREVIOUS_OBJECT: i32 = 18
const E_CALL_OTHER: i32 = 19
const E_FILE_NAME: i32 = 20
const E_INTP: i32 = 21
const E_STRINGP: i32 = 22
const E_FLOATP: i32 = 23
const E_ARRAYP: i32 = 24
const E_MAPP: i32 = 25
const E_OBJECTP: i32 = 26
const E_TYPEOF: i32 = 27
const E_WRITE: i32 = 28
const E_ALLOCATE: i32 = 29
const E_KEYS: i32 = 30
const E_VALUES: i32 = 31
const E_MEMBER_ARRAY: i32 = 32
const E_STRLEN: i32 = 33
const E_TO_INT: i32 = 34
const E_TO_FLOAT: i32 = 35
const E_IMPLODE: i32 = 36

fn efun_codes() -> Map<str, i32>:
    let mut m: Map<str, i32> = Map<str, i32>()
    m.insert("undefinedp", E_UNDEFINEDP)
    m.insert("nullp", E_UNDEFINEDP)
    m.insert("sizeof", E_SIZEOF)
    m.insert("evaluate", E_EVALUATE)
    m.insert("funcall", E_EVALUATE)
    m.insert("explode", E_EXPLODE)
    m.insert("map", E_MAP)
    m.insert("map_array", E_MAP)
    m.insert("map_mapping", E_MAP)
    m.insert("filter", E_FILTER)
    m.insert("filter_array", E_FILTER)
    m.insert("filter_mapping", E_FILTER)
    m.insert("sort_array", E_SORT_ARRAY)
    m.insert("upper_case", E_UPPER_CASE)
    m.insert("lower_case", E_LOWER_CASE)
    m.insert("functionp", E_FUNCTIONP)
    m.insert("error", E_ERROR)
    m.insert("throw", E_THROW)
    m.insert("classp", E_CLASSP)
    m.insert("load_object", E_LOAD_OBJECT)
    m.insert("find_object", E_FIND_OBJECT)
    m.insert("clone_object", E_CLONE_OBJECT)
    m.insert("new", E_CLONE_OBJECT)
    m.insert("this_object", E_THIS_OBJECT)
    m.insert("previous_object", E_PREVIOUS_OBJECT)
    m.insert("call_other", E_CALL_OTHER)
    m.insert("file_name", E_FILE_NAME)
    m.insert("intp", E_INTP)
    m.insert("stringp", E_STRINGP)
    m.insert("floatp", E_FLOATP)
    m.insert("arrayp", E_ARRAYP)
    m.insert("pointerp", E_ARRAYP)
    m.insert("mapp", E_MAPP)
    m.insert("objectp", E_OBJECTP)
    m.insert("typeof", E_TYPEOF)
    m.insert("write", E_WRITE)
    m.insert("allocate", E_ALLOCATE)
    m.insert("keys", E_KEYS)
    m.insert("values", E_VALUES)
    m.insert("member_array", E_MEMBER_ARRAY)
    m.insert("strlen", E_STRLEN)
    m.insert("to_int", E_TO_INT)
    m.insert("to_float", E_TO_FLOAT)
    m.insert("implode", E_IMPLODE)
    m
