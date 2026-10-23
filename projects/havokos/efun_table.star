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
# Codes 1-36 are M3's (what the language-semantics cases needed: type
# predicates, the function-pointer efuns, error/throw, the object-loading
# core of call_other). M4 added the library in ranges, one per file, which
# is how `efuns.star` dispatches: 40-69 strings (`efuns_str.star`), 70-109
# arrays/mappings/math (`efuns_arr.star`), 110-141 time/files/save_object
# (`efuns_file.star`), 142-143 save_variable/restore_variable, 160+ misc.

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

# --- M4: strings (40..)
const E_SPRINTF: i32 = 40
const E_PRINTF: i32 = 41
const E_SSCANF: i32 = 42
const E_PARSE_COMMAND: i32 = 43
const E_CAPITALIZE: i32 = 44
const E_STRWIDTH: i32 = 45
const E_STRSRCH: i32 = 46
const E_REPLACE_STRING: i32 = 47
const E_REPEAT_STRING: i32 = 48
const E_STRCMP: i32 = 49
const E_REGEXP: i32 = 50
const E_REG_ASSOC: i32 = 51
const E_CRYPT: i32 = 52
const E_CRC32: i32 = 53
const E_PLURALIZE: i32 = 54
const E_STRING_DIFFERENCE: i32 = 55
const E_TERMINAL_COLOUR: i32 = 56
const E_QUERY_NUM: i32 = 57
const E_BUFFERP: i32 = 58
# --- M4: arrays and mappings (70..)
const E_ALLOCATE_MAPPING: i32 = 70
const E_UNIQUE_ARRAY: i32 = 71
const E_UNIQUE_MAPPING: i32 = 72
const E_MAP_DELETE: i32 = 73
const E_COPY: i32 = 74
const E_MATCH_PATH: i32 = 75
const E_ELEMENT_OF: i32 = 76
const E_SHUFFLE: i32 = 77
const E_MAX: i32 = 78
const E_MIN: i32 = 79
# --- M4: math (90..)
const E_RANDOM: i32 = 90
const E_ABS: i32 = 91
const E_SQRT: i32 = 92
const E_POW: i32 = 93
const E_EXP: i32 = 94
const E_LOG: i32 = 95
const E_LOG10: i32 = 96
const E_LOG2: i32 = 97
const E_SIN: i32 = 98
const E_COS: i32 = 99
const E_TAN: i32 = 100
const E_ASIN: i32 = 101
const E_ACOS: i32 = 102
const E_ATAN: i32 = 103
const E_FLOOR: i32 = 104
const E_CEIL: i32 = 105
const E_ROUND: i32 = 106
# --- M4: time (110..)
const E_TIME: i32 = 110
const E_UPTIME: i32 = 111
const E_REAL_TIME: i32 = 112
const E_CTIME: i32 = 113
const E_LOCALTIME: i32 = 114
const E_IS_DST: i32 = 115
const E_ZONETIME: i32 = 116
# --- M4: files (120..)
const E_FILE_SIZE: i32 = 120
const E_FILE_LENGTH: i32 = 121
const E_READ_FILE: i32 = 122
const E_READ_BYTES: i32 = 123
const E_WRITE_FILE: i32 = 124
const E_WRITE_BYTES: i32 = 125
const E_GET_DIR: i32 = 126
const E_MKDIR: i32 = 127
const E_RMDIR: i32 = 128
const E_RM: i32 = 129
const E_RENAME: i32 = 130
const E_CP: i32 = 131
const E_STAT: i32 = 132
const E_LINK: i32 = 133
# --- M4: save/restore (140..)
const E_SAVE_OBJECT: i32 = 140
const E_RESTORE_OBJECT: i32 = 141
const E_SAVE_VARIABLE: i32 = 142
const E_RESTORE_VARIABLE: i32 = 143
# --- M4: misc (160..)
const E_MASTER: i32 = 160
const E_GET_CONFIG: i32 = 161

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
    m.insert("master", E_MASTER)
    m.insert("get_config", E_GET_CONFIG)
    m.insert("sprintf", E_SPRINTF)
    m.insert("printf", E_PRINTF)
    m.insert("sscanf", E_SSCANF)
    m.insert("parse_command", E_PARSE_COMMAND)
    m.insert("capitalize", E_CAPITALIZE)
    m.insert("strwidth", E_STRWIDTH)
    m.insert("strsrch", E_STRSRCH)
    m.insert("replace_string", E_REPLACE_STRING)
    m.insert("repeat_string", E_REPEAT_STRING)
    m.insert("strcmp", E_STRCMP)
    m.insert("regexp", E_REGEXP)
    m.insert("reg_assoc", E_REG_ASSOC)
    m.insert("crypt", E_CRYPT)
    m.insert("oldcrypt", E_CRYPT)
    m.insert("crc32", E_CRC32)
    m.insert("pluralize", E_PLURALIZE)
    m.insert("string_difference", E_STRING_DIFFERENCE)
    m.insert("terminal_colour", E_TERMINAL_COLOUR)
    m.insert("query_num", E_QUERY_NUM)
    m.insert("bufferp", E_BUFFERP)
    m.insert("allocate_mapping", E_ALLOCATE_MAPPING)
    m.insert("unique_array", E_UNIQUE_ARRAY)
    m.insert("unique_mapping", E_UNIQUE_MAPPING)
    m.insert("map_delete", E_MAP_DELETE)
    m.insert("copy", E_COPY)
    m.insert("match_path", E_MATCH_PATH)
    m.insert("element_of", E_ELEMENT_OF)
    m.insert("shuffle", E_SHUFFLE)
    m.insert("max", E_MAX)
    m.insert("min", E_MIN)
    m.insert("random", E_RANDOM)
    m.insert("abs", E_ABS)
    m.insert("sqrt", E_SQRT)
    m.insert("pow", E_POW)
    m.insert("exp", E_EXP)
    m.insert("log", E_LOG)
    m.insert("log10", E_LOG10)
    m.insert("log2", E_LOG2)
    m.insert("sin", E_SIN)
    m.insert("cos", E_COS)
    m.insert("tan", E_TAN)
    m.insert("asin", E_ASIN)
    m.insert("acos", E_ACOS)
    m.insert("atan", E_ATAN)
    m.insert("floor", E_FLOOR)
    m.insert("ceil", E_CEIL)
    m.insert("round", E_ROUND)
    m.insert("time", E_TIME)
    m.insert("uptime", E_UPTIME)
    m.insert("real_time", E_REAL_TIME)
    m.insert("ctime", E_CTIME)
    m.insert("localtime", E_LOCALTIME)
    m.insert("is_daylight_savings_time", E_IS_DST)
    m.insert("zonetime", E_ZONETIME)
    m.insert("file_size", E_FILE_SIZE)
    m.insert("file_length", E_FILE_LENGTH)
    m.insert("read_file", E_READ_FILE)
    m.insert("read_bytes", E_READ_BYTES)
    m.insert("write_file", E_WRITE_FILE)
    m.insert("write_bytes", E_WRITE_BYTES)
    m.insert("get_dir", E_GET_DIR)
    m.insert("mkdir", E_MKDIR)
    m.insert("rmdir", E_RMDIR)
    m.insert("rm", E_RM)
    m.insert("rename", E_RENAME)
    m.insert("cp", E_CP)
    m.insert("stat", E_STAT)
    m.insert("link", E_LINK)
    m.insert("save_object", E_SAVE_OBJECT)
    m.insert("restore_object", E_RESTORE_OBJECT)
    m.insert("save_variable", E_SAVE_VARIABLE)
    m.insert("restore_variable", E_RESTORE_VARIABLE)
    m
