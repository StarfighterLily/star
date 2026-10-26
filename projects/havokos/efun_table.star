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
# M5 added 200-299, the object model (`efuns_obj.star`), and 900-999, the
# test hooks (`test_efun_codes()`, below). M6 added 300-349, connections and
# telnet (`efuns_net.star`), and 350-369, the verb parser's registry
# (`verbparse.star`). M7 added 370-379, the line editor (`ed.star`), then
# 380-399, the LPC socket efuns and resolve() (`sockets.star`), then 400-419,
# the reference's HavokOS-only extensions (`json.star`, `ext.star`), and
# 420-429 its SQLite databases (`sqldb.star`, P1 #7), then 430-439 the rest of
# the network's (`http.star`, P1 #8) and 440-449 LPC buffers (`buffers.star`,
# P1 #8).

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
# --- M5: the object model (200..)
const E_DESTRUCT: i32 = 200
const E_ENVIRONMENT: i32 = 201
const E_ALL_INVENTORY: i32 = 202
const E_DEEP_INVENTORY: i32 = 203
const E_FIRST_INVENTORY: i32 = 204
const E_NEXT_INVENTORY: i32 = 205
const E_PRESENT: i32 = 206
const E_MOVE_OBJECT: i32 = 207
const E_BASE_NAME: i32 = 208
const E_CLONEP: i32 = 209
const E_VIRTUALP: i32 = 210
const E_CHILDREN: i32 = 211
const E_INHERITORS: i32 = 212
const E_OBJECTS: i32 = 213
const E_INHERITS: i32 = 214
const E_INHERIT_LIST: i32 = 215
const E_DEEP_INHERIT_LIST: i32 = 216
const E_FUNCTION_EXISTS: i32 = 217
const E_FUNCTIONS: i32 = 218
const E_VARIABLES: i32 = 219
const E_FETCH_VARIABLE: i32 = 220
const E_STORE_VARIABLE: i32 = 221
const E_QUERY_PRIVS: i32 = 222
const E_SET_PRIVS: i32 = 223
const E_SHADOW: i32 = 224
const E_QUERY_SHADOWING: i32 = 225
const E_REMOVE_SHADOW: i32 = 226
const E_ORIGIN: i32 = 227
const E_CALL_STACK: i32 = 228
const E_ALL_PREVIOUS_OBJECTS: i32 = 229
const E_THIS_PLAYER: i32 = 230
const E_THIS_INTERACTIVE: i32 = 231
const E_BIND: i32 = 232
const E_FUNCTION_OWNER: i32 = 233
const E_REPLACE_PROGRAM: i32 = 234
const E_QUERY_REPLACED_PROGRAM: i32 = 235
const E_REPLACEABLE: i32 = 236
const E_RELOAD_OBJECT: i32 = 237
const E_REFS: i32 = 238
const E_SET_AUTHOR: i32 = 239
const E_AUTHOR_STATS: i32 = 240
const E_GET_GARBAGE: i32 = 241
const E_RECLAIM_OBJECTS: i32 = 242
const E_ENABLE_COMMANDS: i32 = 243
const E_DISABLE_COMMANDS: i32 = 244
const E_LIVING: i32 = 245
const E_LIVINGS: i32 = 246
const E_NAMED_LIVINGS: i32 = 247
const E_SET_LIVING_NAME: i32 = 248
const E_FIND_LIVING: i32 = 249
const E_FIND_PLAYER: i32 = 250
const E_ADD_ACTION: i32 = 251
const E_REMOVE_ACTION: i32 = 252
const E_COMMANDS: i32 = 253
const E_QUERY_VERB: i32 = 254
const E_NOTIFY_FAIL: i32 = 255
const E_QUERY_NOTIFY_FAIL: i32 = 256
const E_COMMAND: i32 = 257
const E_SET_HIDE: i32 = 258
const E_TELL_OBJECT: i32 = 259
const E_RECEIVE: i32 = 260
const E_SAY: i32 = 261
const E_TELL_ROOM: i32 = 262
const E_SHOUT: i32 = 263
const E_MESSAGE: i32 = 264
const E_FLUSH_MESSAGES: i32 = 265
const E_CALL_OUT: i32 = 266
const E_REMOVE_CALL_OUT: i32 = 267
const E_FIND_CALL_OUT: i32 = 268
const E_CALL_OUT_INFO: i32 = 269
const E_SET_HEART_BEAT: i32 = 270
const E_QUERY_HEART_BEAT: i32 = 271
const E_HEART_BEATS: i32 = 272
const E_SET_RESET: i32 = 273
const E_EVAL_COST: i32 = 274
const E_MAX_EVAL_COST: i32 = 275
const E_RESET_EVAL_COST: i32 = 276
const E_SET_EVAL_LIMIT: i32 = 277
const E_SHUTDOWN: i32 = 278
const E_MUD_STATUS: i32 = 279
const E_MEMORY_INFO: i32 = 280
const E_DEBUG_INFO: i32 = 281
const E_DEBUG_MESSAGE: i32 = 282
const E_QUERY_LOAD_AVERAGE: i32 = 283
const E_USERS: i32 = 284
const E_INTERACTIVE: i32 = 285
const E_USERP: i32 = 286
const E_RUSAGE: i32 = 287
const E_OPCPROF: i32 = 288
const E_DUMPALLOBJ: i32 = 289
# --- M6: connections (300..), efuns_net.star
const E_EXEC: i32 = 300
const E_QUERY_IP_NUMBER: i32 = 301
const E_QUERY_IP_NAME: i32 = 302
const E_QUERY_IP_PORT: i32 = 303
const E_QUERY_HOST_NAME: i32 = 304
const E_QUERY_IDLE: i32 = 305
const E_IN_INPUT: i32 = 306
const E_REMOVE_INTERACTIVE: i32 = 307
const E_SNOOP: i32 = 308
const E_QUERY_SNOOP: i32 = 309
const E_QUERY_SNOOPING: i32 = 310
const E_QUERY_CHARMODE: i32 = 311
const E_REMOVE_CHARMODE: i32 = 312
const E_REMOVE_GET_CHAR: i32 = 313
const E_HAS_MXP: i32 = 314
const E_HAS_ZMP: i32 = 315
const E_HAS_GMCP: i32 = 316
const E_HAS_MSDP: i32 = 317
const E_HAS_MSP: i32 = 318
const E_SEND_ZMP: i32 = 319
const E_SEND_GMCP: i32 = 320
const E_ACT_MXP: i32 = 321
const E_SEND_MSDP: i32 = 322
const E_SEND_MSP: i32 = 323
const E_CLIENT_INFO: i32 = 324
const E_REQUEST_TERM_TYPE: i32 = 325
const E_START_REQUEST_TERM_TYPE: i32 = 326
const E_REQUEST_TERM_SIZE: i32 = 327
const E_SEND_NULLBYTE: i32 = 328
const E_NETWORK_STATS: i32 = 329
const E_INPUT_TO: i32 = 330
const E_GET_CHAR: i32 = 331
# --- M6: the verb parser's registry (350..), verbparse.star
const E_PARSE_INIT: i32 = 350
const E_PARSE_REFRESH: i32 = 351
const E_PARSE_ADD_RULE: i32 = 352
const E_PARSE_ADD_SYNONYM: i32 = 353
const E_PARSE_REMOVE: i32 = 354
const E_PARSE_DUMP: i32 = 355
const E_PARSE_SENTENCE: i32 = 356
const E_PARSE_MY_RULES: i32 = 357
# --- M7: the line editor (370..), ed.star
const E_ED_START: i32 = 370
const E_ED_CMD: i32 = 371
const E_IN_EDIT: i32 = 372
const E_QUERY_ED_MODE: i32 = 373
# --- M7: LPC sockets (380..), sockets.star
const E_SOCKET_CREATE: i32 = 380
const E_SOCKET_BIND: i32 = 381
const E_SOCKET_LISTEN: i32 = 382
const E_SOCKET_ACCEPT: i32 = 383
const E_SOCKET_CONNECT: i32 = 384
const E_SOCKET_WRITE: i32 = 385
const E_SOCKET_CLOSE: i32 = 386
const E_SOCKET_RELEASE: i32 = 387
const E_SOCKET_ACQUIRE: i32 = 388
const E_SOCKET_ERROR: i32 = 389
const E_SOCKET_ADDRESS: i32 = 390
const E_SOCKET_STATUS: i32 = 391
const E_RESOLVE: i32 = 392
const E_DUMP_FILE_DESCRIPTORS: i32 = 393
# --- M7: the reference's HavokOS-only extensions (400..): json.star, then
# ext.star for the rest (astar_path, find_files, file watching, quotas,
# dependencies, profiling, the status reports)
const E_JSON_ENCODE: i32 = 400
const E_JSON_DECODE: i32 = 401
const E_ASTAR_PATH: i32 = 402
const E_FIND_FILES: i32 = 403
const E_WATCH_PATH: i32 = 404
const E_UNWATCH_PATH: i32 = 405
const E_QUOTA_INFO: i32 = 406
const E_QUOTA_REFRESH: i32 = 407
const E_STALE_PROGRAMS: i32 = 408
const E_DEPENDENTS: i32 = 409
const E_FUNCTION_PROFILE: i32 = 410
const E_PROFILE_START: i32 = 411
const E_PROFILE_STOP: i32 = 412
const E_PROFILE_REPORT: i32 = 413
const E_CACHE_STATS: i32 = 414
const E_MALLOC_STATUS: i32 = 415
const E_MEMORY_SUMMARY: i32 = 416
# --- P1 #7: the reference's SQLite databases (420..): sqldb.star
const E_DB_OPEN: i32 = 420
const E_DB_QUERY: i32 = 421
const E_DB_INFO: i32 = 422
const E_DB_CLOSE: i32 = 423
# --- P1 #8: the HTTP port (http.star)
const E_HTTP_RESPOND: i32 = 430
# --- P1 #8: LPC buffers (buffers.star)
const E_ALLOCATE_BUFFER: i32 = 440
const E_READ_BUFFER: i32 = 441
const E_WRITE_BUFFER: i32 = 442
# --- M5: test hooks (900..), see test_efun_codes()
const E_TEST_HB: i32 = 900
const E_TEST_HB_ROUND: i32 = 901
const E_TEST_CALLOUTS: i32 = 902
const E_TEST_RESET_CFG: i32 = 903
const E_TEST_SET_RESET_TIME: i32 = 904
const E_TEST_SET_LAST_USED: i32 = 905
const E_TEST_RESET_TIME: i32 = 906
const E_TEST_NO_CLEAN_UP: i32 = 907
const E_TEST_SWEEP: i32 = 908
const E_TEST_LIMITED: i32 = 909
const E_TEST_EVAL_STATE: i32 = 910
# --- M6: telnet test hooks (efuns_net.star)
const E_TEST_TEL_OPEN: i32 = 911
const E_TEST_TEL_SAY: i32 = 912
const E_TEST_TEL_DRAIN: i32 = 913
const E_TEST_TEL_HANGUP: i32 = 914
const E_TEST_TEL_TP: i32 = 915
const E_TEST_TEL_CONNECT: i32 = 916
const E_TEST_TEL_USER: i32 = 917
# --- M7: socket test hooks (sockets.star)
const E_TEST_SOCK_PUMP: i32 = 918
const E_TEST_CONFIG: i32 = 919
# --- M7: extension test hooks (ext.star)
const E_TEST_WATCH_POLL: i32 = 920
const E_TEST_RUN_CALL_OUT: i32 = 921
const E_TEST_UTIME: i32 = 922
const E_TEST_FORGET: i32 = 923
const E_TEST_PROFILING: i32 = 924
const E_TEST_WATCH_STATE: i32 = 925
const E_TEST_PUT: i32 = 926
const E_TEST_RMTREE: i32 = 927
# --- P1 #8: network test hooks (efuns_net.star efun_net_test())
const E_TEST_INFLATE: i32 = 930
const E_TEST_CLI_OPEN: i32 = 931
const E_TEST_CLI_SEND: i32 = 932
const E_TEST_CLI_RECV: i32 = 933
const E_TEST_CLI_CLOSED: i32 = 934
const E_TEST_CLI_CLOSE: i32 = 935
const E_TEST_SRV_LISTEN: i32 = 936
const E_TEST_SRV_TAKE: i32 = 937
const E_TEST_TEL_LISTEN: i32 = 938
const E_TEST_HTTP_LISTEN: i32 = 939
const E_TEST_PORTS_CLOSE: i32 = 940
const E_TEST_FREE_PORT: i32 = 941

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
    m.insert("destruct", E_DESTRUCT)
    m.insert("environment", E_ENVIRONMENT)
    m.insert("all_inventory", E_ALL_INVENTORY)
    m.insert("deep_inventory", E_DEEP_INVENTORY)
    m.insert("first_inventory", E_FIRST_INVENTORY)
    m.insert("next_inventory", E_NEXT_INVENTORY)
    m.insert("present", E_PRESENT)
    m.insert("move_object", E_MOVE_OBJECT)
    m.insert("base_name", E_BASE_NAME)
    m.insert("clonep", E_CLONEP)
    m.insert("virtualp", E_VIRTUALP)
    m.insert("children", E_CHILDREN)
    m.insert("inheritors", E_INHERITORS)
    m.insert("objects", E_OBJECTS)
    m.insert("inherits", E_INHERITS)
    m.insert("inherit_list", E_INHERIT_LIST)
    m.insert("deep_inherit_list", E_DEEP_INHERIT_LIST)
    m.insert("function_exists", E_FUNCTION_EXISTS)
    m.insert("functions", E_FUNCTIONS)
    m.insert("variables", E_VARIABLES)
    m.insert("fetch_variable", E_FETCH_VARIABLE)
    m.insert("store_variable", E_STORE_VARIABLE)
    m.insert("query_privs", E_QUERY_PRIVS)
    m.insert("set_privs", E_SET_PRIVS)
    m.insert("shadow", E_SHADOW)
    m.insert("query_shadowing", E_QUERY_SHADOWING)
    m.insert("remove_shadow", E_REMOVE_SHADOW)
    m.insert("origin", E_ORIGIN)
    m.insert("call_stack", E_CALL_STACK)
    m.insert("all_previous_objects", E_ALL_PREVIOUS_OBJECTS)
    m.insert("this_player", E_THIS_PLAYER)
    m.insert("this_interactive", E_THIS_INTERACTIVE)
    m.insert("bind", E_BIND)
    m.insert("function_owner", E_FUNCTION_OWNER)
    m.insert("replace_program", E_REPLACE_PROGRAM)
    m.insert("query_replaced_program", E_QUERY_REPLACED_PROGRAM)
    m.insert("replaceable", E_REPLACEABLE)
    m.insert("reload_object", E_RELOAD_OBJECT)
    m.insert("refs", E_REFS)
    m.insert("set_author", E_SET_AUTHOR)
    m.insert("author_stats", E_AUTHOR_STATS)
    m.insert("get_garbage", E_GET_GARBAGE)
    m.insert("reclaim_objects", E_RECLAIM_OBJECTS)
    m.insert("enable_commands", E_ENABLE_COMMANDS)
    m.insert("disable_commands", E_DISABLE_COMMANDS)
    m.insert("living", E_LIVING)
    m.insert("livings", E_LIVINGS)
    m.insert("named_livings", E_NAMED_LIVINGS)
    m.insert("set_living_name", E_SET_LIVING_NAME)
    m.insert("find_living", E_FIND_LIVING)
    m.insert("find_player", E_FIND_PLAYER)
    m.insert("add_action", E_ADD_ACTION)
    m.insert("remove_action", E_REMOVE_ACTION)
    m.insert("commands", E_COMMANDS)
    m.insert("query_verb", E_QUERY_VERB)
    m.insert("notify_fail", E_NOTIFY_FAIL)
    m.insert("query_notify_fail", E_QUERY_NOTIFY_FAIL)
    m.insert("command", E_COMMAND)
    m.insert("set_hide", E_SET_HIDE)
    m.insert("tell_object", E_TELL_OBJECT)
    m.insert("receive", E_RECEIVE)
    m.insert("say", E_SAY)
    m.insert("tell_room", E_TELL_ROOM)
    m.insert("shout", E_SHOUT)
    m.insert("message", E_MESSAGE)
    m.insert("flush_messages", E_FLUSH_MESSAGES)
    m.insert("call_out", E_CALL_OUT)
    m.insert("remove_call_out", E_REMOVE_CALL_OUT)
    m.insert("find_call_out", E_FIND_CALL_OUT)
    m.insert("call_out_info", E_CALL_OUT_INFO)
    m.insert("set_heart_beat", E_SET_HEART_BEAT)
    m.insert("query_heart_beat", E_QUERY_HEART_BEAT)
    m.insert("heart_beats", E_HEART_BEATS)
    m.insert("set_reset", E_SET_RESET)
    m.insert("eval_cost", E_EVAL_COST)
    m.insert("max_eval_cost", E_MAX_EVAL_COST)
    m.insert("reset_eval_cost", E_RESET_EVAL_COST)
    m.insert("set_eval_limit", E_SET_EVAL_LIMIT)
    m.insert("shutdown", E_SHUTDOWN)
    m.insert("mud_status", E_MUD_STATUS)
    m.insert("memory_info", E_MEMORY_INFO)
    m.insert("debug_info", E_DEBUG_INFO)
    m.insert("debug_message", E_DEBUG_MESSAGE)
    m.insert("query_load_average", E_QUERY_LOAD_AVERAGE)
    m.insert("users", E_USERS)
    m.insert("interactive", E_INTERACTIVE)
    m.insert("userp", E_USERP)
    m.insert("rusage", E_RUSAGE)
    m.insert("opcprof", E_OPCPROF)
    m.insert("dumpallobj", E_DUMPALLOBJ)
    m.insert("shallow_inherit_list", E_INHERIT_LIST)
    m.insert("this_user", E_THIS_PLAYER)
    m.insert("get_eval_cost", E_EVAL_COST)
    m.insert("domain_stats", E_AUTHOR_STATS)
    m.insert("exec", E_EXEC)
    m.insert("query_ip_number", E_QUERY_IP_NUMBER)
    m.insert("query_ip_name", E_QUERY_IP_NAME)
    m.insert("query_ip_port", E_QUERY_IP_PORT)
    m.insert("query_host_name", E_QUERY_HOST_NAME)
    m.insert("query_idle", E_QUERY_IDLE)
    m.insert("in_input", E_IN_INPUT)
    m.insert("remove_interactive", E_REMOVE_INTERACTIVE)
    m.insert("snoop", E_SNOOP)
    m.insert("query_snoop", E_QUERY_SNOOP)
    m.insert("query_snooping", E_QUERY_SNOOPING)
    m.insert("query_charmode", E_QUERY_CHARMODE)
    m.insert("remove_charmode", E_REMOVE_CHARMODE)
    m.insert("remove_get_char", E_REMOVE_GET_CHAR)
    m.insert("has_mxp", E_HAS_MXP)
    m.insert("has_zmp", E_HAS_ZMP)
    m.insert("has_gmcp", E_HAS_GMCP)
    m.insert("has_msdp", E_HAS_MSDP)
    m.insert("has_msp", E_HAS_MSP)
    m.insert("send_zmp", E_SEND_ZMP)
    m.insert("send_gmcp", E_SEND_GMCP)
    m.insert("act_mxp", E_ACT_MXP)
    m.insert("send_msdp", E_SEND_MSDP)
    m.insert("send_msp", E_SEND_MSP)
    m.insert("client_info", E_CLIENT_INFO)
    m.insert("request_term_type", E_REQUEST_TERM_TYPE)
    m.insert("start_request_term_type", E_START_REQUEST_TERM_TYPE)
    m.insert("request_term_size", E_REQUEST_TERM_SIZE)
    m.insert("send_nullbyte", E_SEND_NULLBYTE)
    m.insert("network_stats", E_NETWORK_STATS)
    m.insert("input_to", E_INPUT_TO)
    m.insert("get_char", E_GET_CHAR)
    m.insert("parse_init", E_PARSE_INIT)
    m.insert("parse_refresh", E_PARSE_REFRESH)
    m.insert("parse_add_rule", E_PARSE_ADD_RULE)
    m.insert("parse_add_synonym", E_PARSE_ADD_SYNONYM)
    m.insert("parse_remove", E_PARSE_REMOVE)
    m.insert("parse_dump", E_PARSE_DUMP)
    m.insert("parse_sentence", E_PARSE_SENTENCE)
    m.insert("parse_my_rules", E_PARSE_MY_RULES)
    m.insert("ed_start", E_ED_START)
    m.insert("ed_cmd", E_ED_CMD)
    m.insert("in_edit", E_IN_EDIT)
    m.insert("query_ed_mode", E_QUERY_ED_MODE)
    m.insert("socket_create", E_SOCKET_CREATE)
    m.insert("socket_bind", E_SOCKET_BIND)
    m.insert("socket_listen", E_SOCKET_LISTEN)
    m.insert("socket_accept", E_SOCKET_ACCEPT)
    m.insert("socket_connect", E_SOCKET_CONNECT)
    m.insert("socket_write", E_SOCKET_WRITE)
    m.insert("socket_close", E_SOCKET_CLOSE)
    m.insert("socket_release", E_SOCKET_RELEASE)
    m.insert("socket_acquire", E_SOCKET_ACQUIRE)
    m.insert("socket_error", E_SOCKET_ERROR)
    m.insert("socket_address", E_SOCKET_ADDRESS)
    m.insert("socket_status", E_SOCKET_STATUS)
    m.insert("resolve", E_RESOLVE)
    m.insert("dump_file_descriptors", E_DUMP_FILE_DESCRIPTORS)
    m.insert("json_encode", E_JSON_ENCODE)
    m.insert("json_decode", E_JSON_DECODE)
    m.insert("astar_path", E_ASTAR_PATH)
    m.insert("find_files", E_FIND_FILES)
    m.insert("watch_path", E_WATCH_PATH)
    m.insert("unwatch_path", E_UNWATCH_PATH)
    m.insert("quota_info", E_QUOTA_INFO)
    m.insert("quota_refresh", E_QUOTA_REFRESH)
    m.insert("stale_programs", E_STALE_PROGRAMS)
    m.insert("dependents", E_DEPENDENTS)
    m.insert("function_profile", E_FUNCTION_PROFILE)
    m.insert("profile_start", E_PROFILE_START)
    m.insert("profile_stop", E_PROFILE_STOP)
    m.insert("profile_report", E_PROFILE_REPORT)
    m.insert("cache_stats", E_CACHE_STATS)
    m.insert("malloc_status", E_MALLOC_STATUS)
    m.insert("memory_summary", E_MEMORY_SUMMARY)
    m.insert("db_open", E_DB_OPEN)
    m.insert("db_query", E_DB_QUERY)
    m.insert("db_info", E_DB_INFO)
    m.insert("db_close", E_DB_CLOSE)
    m.insert("http_respond", E_HTTP_RESPOND)
    m.insert("allocate_buffer", E_ALLOCATE_BUFFER)
    m.insert("read_buffer", E_READ_BUFFER)
    m.insert("write_buffer", E_WRITE_BUFFER)
    m

# Driver hooks for the case runner (`tools/run_cases.star` with `-hooks`,
# `tools/ref_cases.pike` gives the reference the same efuns): they drive
# what a running driver does by itself -- heart beats, call_outs, the reset
# sweep, an evaluation limit -- from inside an LPC case, so both drivers can
# be stepped identically. Never registered by a real boot.
fn test_efun_codes() -> Map<str, i32>:
    let mut m: Map<str, i32> = Map<str, i32>()
    m.insert("test_hb", E_TEST_HB)
    m.insert("test_hb_round", E_TEST_HB_ROUND)
    m.insert("test_callouts", E_TEST_CALLOUTS)
    m.insert("test_reset_cfg", E_TEST_RESET_CFG)
    m.insert("test_set_reset_time", E_TEST_SET_RESET_TIME)
    m.insert("test_set_last_used", E_TEST_SET_LAST_USED)
    m.insert("test_reset_time", E_TEST_RESET_TIME)
    m.insert("test_no_clean_up", E_TEST_NO_CLEAN_UP)
    m.insert("test_sweep", E_TEST_SWEEP)
    m.insert("test_limited", E_TEST_LIMITED)
    m.insert("test_eval_state", E_TEST_EVAL_STATE)
    m.insert("test_tel_open", E_TEST_TEL_OPEN)
    m.insert("test_tel_say", E_TEST_TEL_SAY)
    m.insert("test_tel_drain", E_TEST_TEL_DRAIN)
    m.insert("test_tel_hangup", E_TEST_TEL_HANGUP)
    m.insert("test_tel_tp", E_TEST_TEL_TP)
    m.insert("test_tel_connect", E_TEST_TEL_CONNECT)
    m.insert("test_tel_user", E_TEST_TEL_USER)
    m.insert("test_sock_pump", E_TEST_SOCK_PUMP)
    m.insert("test_config", E_TEST_CONFIG)
    m.insert("test_watch_poll", E_TEST_WATCH_POLL)
    m.insert("test_run_call_out", E_TEST_RUN_CALL_OUT)
    m.insert("test_utime", E_TEST_UTIME)
    m.insert("test_forget", E_TEST_FORGET)
    m.insert("test_profiling", E_TEST_PROFILING)
    m.insert("test_watch_state", E_TEST_WATCH_STATE)
    m.insert("test_put", E_TEST_PUT)
    m.insert("test_rmtree", E_TEST_RMTREE)
    m.insert("test_inflate", E_TEST_INFLATE)
    m.insert("test_cli_open", E_TEST_CLI_OPEN)
    m.insert("test_cli_send", E_TEST_CLI_SEND)
    m.insert("test_cli_recv", E_TEST_CLI_RECV)
    m.insert("test_cli_closed", E_TEST_CLI_CLOSED)
    m.insert("test_cli_close", E_TEST_CLI_CLOSE)
    m.insert("test_srv_listen", E_TEST_SRV_LISTEN)
    m.insert("test_srv_take", E_TEST_SRV_TAKE)
    m.insert("test_tel_listen", E_TEST_TEL_LISTEN)
    m.insert("test_http_listen", E_TEST_HTTP_LISTEN)
    m.insert("test_ports_close", E_TEST_PORTS_CLOSE)
    m.insert("test_free_port", E_TEST_FREE_PORT)
    m
