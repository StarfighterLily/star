# One line editor session's state -- todo.md HavokOS M7 (`ed`), the fields of
# `havok/ed.pike`'s Session class without its methods (those are
# `ed.star`'s, on the Vm, because file access and the option word go
# through master applies). In its own file so `vm.star` can hold the session
# table without importing the editor, as `conn.star` does for connections.
#
# A session belongs to the object that called ed_start(): `ObjSlot.ed` is
# its index in `Vm.eds`, and a slot is reused once the session ends.
# Where the reference uses 0 for "none" this uses an empty string or -1:
# `filename` "" is a nameless buffer (a resolved name is never empty), a
# mark of -1 is unset (a set mark is always a line >= 1).

import "buf.star" as bf
import "regex.star" as rx

struct EdSession:
    mut alive: bool = true
    # the editing object (file access is checked as its), and whether a
    # command is running: a destruct during one of its master applies ends
    # the session, but the slot isn't reused until the command returns
    mut owner: i32 = -1
    mut running: bool = false
    mut filename: str = ""
    mut restricted: bool = false
    # ed.pike OPT_NUMBER (1) | OPT_LIST (2)
    mut options: i32 = 0
    mut buf: List<str> = List<str>()
    # the current line, 0 when the buffer is empty
    mut cur: i32 = 0
    mut dirty: bool = false
    mut finished: bool = false
    # input mode, and the line the next input line goes after
    mut inserting: bool = false
    mut ins_after: i32 = 0
    # 'a'..'z' -> line, -1 unset
    mut marks: List<i32> = List<i32>()
    # per-line flags while g/v runs (`gon`)
    mut gflags: List<bool> = List<bool>()
    mut gon: bool = false
    mut last_pattern: str = ""
    mut has_pattern: bool = false
    mut last_replacement: str = ""
    mut has_replacement: bool = false
    mut last_was_z: bool = false
    # the help pages still to show (`in_help`: MODE_HELP)
    mut help_pages: List<str> = List<str>()
    mut in_help: bool = false
    # single-level undo: the buffer, current line, dirty flag and marks
    # before the last change, and whether this command already saved them
    mut has_undo: bool = false
    mut undo_buf: List<str> = List<str>()
    mut undo_cur: i32 = 0
    mut undo_dirty: bool = false
    mut undo_marks: List<i32> = List<i32>()
    mut changed: bool = false
    mut out: bf::Buf = bf::Buf()
    # the command line being parsed, the parse position, the address range
    mut s: Bytes = Bytes()
    mut pos: i32 = 0
    mut line1: i32 = 0
    mut line2: i32 = 0
    # ed.pike's thrown EdError: set by ed_oops() (its message already said),
    # it abandons the command
    mut oops: bool = false
    # the last pattern compiled (ed.pike re_cache, one entry: a cache can
    # change nothing a user sees)
    mut re_pat: str = ""
    mut re: rx::Regex = rx::Regex()
    mut re_ok: bool = false
