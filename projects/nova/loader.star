# Binary program loader: loads a real compiled Nova-16 program (produced by
# the upstream Python `nova_assembler.py`, not this port -- there's still no
# assembler here, see NOTES.md) into a `Cpu`'s memory, byte-accurately.
#
# This is the thing gotcha #9 in NOTES.md ("`file_read`'s `str` result
# silently truncates at the first embedded NUL byte") was unblocking at the
# language level (`file_read_bytes(handle) -> Bytes`) without ever being
# wired up to anything -- every real Nova-16 program contains 0x00 bytes
# (`HLT` alone is opcode 0), so the old NUL-terminated `file_read` could
# never have loaded one correctly. This module is the actual wiring.
#
# Binary-mode caveat (Windows): the `.bin` itself is opened with `"rb"`, not
# `"r"`. On Windows, C text-mode `fread` stops at the first `0x1A` (Ctrl-Z)
# byte and reports EOF there, so a `.bin` opened in text mode silently
# truncates the moment its code/data crosses that offset -- the exact
# mechanism that used to make `astrid/game.bin` (a multi-KB Astrid-compiled
# program containing 18 `0x1A` bytes) halt immediately on this loader. See
# the `load_program` body's own comment and NOTES.md's "Binary program
# loading" section for the full write-up. The `.org` sidecar, by contrast, is
# a genuinely textual file and is correctly opened with `"rb"`'s `"r"` twin.
#
# NOMF support (this round): the upstream Python assembler's default output
# is now NOMF (`nova/nomf.py`) -- a single-file, versioned, CRC-protected
# container replacing the loose `.bin` + `.org` + `.sym` sidecar trio. This
# loader detects NOMF by magic bytes (`NOMF`, first 4 bytes) and delegates
# to `nomf.star` for parsing; the legacy `.bin` + `.org` path is the
# fallback for non-NOMF files. See `nomf.star` and NOTES.md's "NOMF format
# support" section for the full format description.
#
# Legacy segment format (non-NOMF path): mirrors `nova/memory/memory.py::
# load_program_with_org_detection`/`load_with_org_info` exactly, since that's
# what actually produces the files this loads. `nova_assembler.py` always
# writes a `.org` sidecar next to its `.bin` output (same base name, `.org`
# extension):
#
#   # comment lines start with '#' and are ignored, as are blank lines
#   <start_addr_hex> <length_decimal> <bin_offset_decimal>
#
# one line per contiguous ORG segment, `start_addr` in `0x`-prefixed hex,
# `length`/`bin_offset` in decimal. The *first* segment's `start_addr` is the
# program's entry point (matches the Python loader's own "first segment sets
# entry_point" rule) -- multi-segment programs (more than one `ORG` in the
# source) are supported the same way the reference is. When a `.bin` has no
# matching `.org` file (hand-assembled raw bytes, or any other binary blob),
# the whole file loads at address 0 and PC starts at 0 -- the Python loader's
# own "legacy" fallback for the same case.
#
# `load_program` is a method on `cpu::Cpu` (via a cross-module `impl`, gotcha
# #6) rather than a free function taking `Cpu` as an ordinary parameter, on
# purpose: `Cpu` is a large struct (memory alone is ~300KB, and screen/layers
# push it further), and NOTES.md's own established rule for this project is
# that a struct like this is only ever constructed once and then only ever
# passed around via `self` afterward -- see NOTES.md's "Four Star compiler
# bugs found and fixed" #1 for why (the fix for a large by-value parameter
# exists at the compiler level now, but it's still a real `memcpy` of the
# whole struct on every call, and this project avoids leaning on it when
# `self` is free instead).

import "cpu.star" as cpu

extern "C" fn atoi(s: str) -> i32
extern "C" fn strtol(s: str, endptr: ptr, base: i32) -> i32

# -- NOMF format detection ------------------------------------------------
#
# NOMF (Nova Object Module Format) is the upstream Python assembler's
# default output format. We detect it by magic bytes and parse just enough
# to load sections into memory. Full format details are in `nomf.star`;
# this is the minimal inlined detection needed by the loader.
#
# Header: 4 bytes magic "NOMF", 1 byte version, 1 byte kind, 2 bytes flags,
# 4 bytes CRC32, 4 bytes chunk count. Chunk = 4-byte tag + u32 LE length + payload.

const NOMF_MAGIC_0: u8 = 78 as u8   # 'N'
const NOMF_MAGIC_1: u8 = 79 as u8   # 'O'
const NOMF_MAGIC_2: u8 = 77 as u8   # 'M'
const NOMF_MAGIC_3: u8 = 70 as u8   # 'F'

const NOMF_KIND_EXECUTABLE: i32 = 1
const NOMF_KIND_OBJECT: i32 = 0

const NOMF_HEADER_SIZE: i32 = 16
const NOMF_CHUNK_HEADER_SIZE: i32 = 8

# SECT tag bytes: "SECT"
const NOMF_TAG_SECT_0: u8 = 83 as u8
const NOMF_TAG_SECT_1: u8 = 69 as u8
const NOMF_TAG_SECT_2: u8 = 67 as u8
const NOMF_TAG_SECT_3: u8 = 84 as u8

# ENTR tag bytes: "ENTR"
const NOMF_TAG_ENTR_0: u8 = 69 as u8
const NOMF_TAG_ENTR_1: u8 = 78 as u8
const NOMF_TAG_ENTR_2: u8 = 84 as u8
const NOMF_TAG_ENTR_3: u8 = 82 as u8

# Returns true if the file at `path` is a NOMF file (magic bytes match).
fn _is_nomf(path: str) -> bool:
    let fh = file_open(path, "rb")
    if is_null(fh):
        return false
    let head = file_read_bytes(fh)
    file_close(fh)
    if head.len() < 6:
        return false
    (head[0] == NOMF_MAGIC_0) and (head[1] == NOMF_MAGIC_1) and (head[2] == NOMF_MAGIC_2) and (head[3] == NOMF_MAGIC_3)

# Parses one `.org` segment line -- see the module header for the format.
# Returns (start_addr, length, bin_offset, ok); `ok` is false for anything
# that isn't exactly 3 whitespace-separated fields, matching the Python
# loader's own `len(parts) != 3` rejection. `start_addr` is parsed with
# `strtol(..., base=0)` (auto-detects the `0x` prefix the assembler always
# emits; also accepts plain decimal, which the Python side never writes but
# costs nothing extra to accept); `length`/`bin_offset` are plain `atoi`
# decimal, matching the reference's `int(parts[1])`/`int(parts[2])` (no hex
# there).
fn parse_org_line(line: str) -> (i32, i32, i32, bool):
    let parts = str_split(line, " ")
    if parts.len() != 3:
        return (0, 0, 0, false)
    let start_addr = strtol(parts[0], null_ptr(), 0)
    let length = atoi(parts[1])
    let bin_offset = atoi(parts[2])
    (start_addr, length, bin_offset, true)

impl cpu::Cpu:
    # Loads `bin_path` (plus its `.org` sidecar, if any) into `self.mem`.
    # Returns (entry_point, ok); `ok` is false only when `bin_path` itself
    # couldn't be opened (a missing/unreadable `.org` sidecar is not an
    # error -- see the module header's "legacy" fallback). Does not touch
    # `self.pc` -- the caller decides whether/when to jump to `entry_point`.
    fn load_program(mut self, bin_path: str) -> (i32, bool):
        # `"rb"` (binary), not `"r"` (text): on Windows a text-mode `fread`
        # stops at the first `0x1A` (Ctrl-Z/SUB) byte and treats it as EOF, so
        # any program whose code/data extends past its first `0x1A` silently
        # truncates mid-load -- exactly how `astrid/game.bin` (from the sibling
        # Python `Nova` repo's `astrid/` dir) used to halt immediately, all of
        # `func_main` and the `0x8000` globals never making it into memory.
        # The reference loader (`nova/memory/memory.py`) opens the `.bin` with
        # `open(..., 'rb')` for the same reason; this must match it if this
        # port is to load real upstream binaries byte-for-byte.
        let bh = file_open(bin_path, "rb")
        if is_null(bh):
            return (0, false)
        let data = file_read_bytes(bh)
        file_close(bh)

        # NOMF detection: the upstream Python assembler's default output is now
        # NOMF (magic bytes "NOMF" at offset 0). If detected, parse and load
        # the sections directly -- mirrors the Python reference's Memory._load_nomf
        # iterating doc.load_segments().
        if _is_nomf(bin_path):
            return self._load_nomf_into_memory(bin_path)

        # Legacy path: .bin + .org sidecar
        let org_path = str_replace(bin_path, ".bin", ".org")
        let oh = file_open(org_path, "r")
        let mut entry_point = 0
        if is_null(oh):
            let mut i = 0
            while i < data.len():
                self.mem.write_byte(i, data[i])
                i += 1
        else:
            let content = file_read(oh)
            file_close(oh)
            let lines = str_split(content, "\n")
            let mut li = 0
            let mut first_segment = true
            while li < lines.len():
                let line = str_trim(lines[li])
                if len(line) > 0 and !str_starts_with(line, "#"):
                    let (start_addr, seg_len, bin_off, ok) = parse_org_line(line)
                    if ok:
                        if first_segment:
                            entry_point = start_addr
                            first_segment = false
                        let mut k = 0
                        while k < seg_len:
                            self.mem.write_byte(start_addr + k, data[bin_off + k])
                            k += 1
                li += 1
        (entry_point, true)

    # NOMF loader: parses a NOMF executable (.nex) and loads its sections
    # into memory. Mirrors the Python reference's Memory._load_nomf iterating
    # doc.load_segments() and calling _place_segment for each.
    fn _load_nomf_into_memory(mut self, path: str) -> (i32, bool):
        let fh = file_open(path, "rb")
        if is_null(fh):
            return (0, false)
        let raw = file_read_bytes(fh)
        file_close(fh)

        if raw.len() < NOMF_HEADER_SIZE:
            return (0, false)

        let kind = raw[5] as i32
        if kind != NOMF_KIND_EXECUTABLE:
            return (0, false)

        let chunk_count = (raw[12] as i32) | ((raw[13] as i32) << 8) | ((raw[14] as i32) << 16) | ((raw[15] as i32) << 24)

        let mut pos = NOMF_HEADER_SIZE
        let mut entry_point = 0
        let mut has_entry = false
        let mut first_section_base = -1
        let raw_len = raw.len()

        let mut seen = 0
        while pos < raw_len and seen < chunk_count:
            if pos + NOMF_CHUNK_HEADER_SIZE > raw_len:
                return (0, false)

            let tag0 = raw[pos]
            let tag1 = raw[pos + 1]
            let tag2 = raw[pos + 2]
            let tag3 = raw[pos + 3]
            let length = (raw[pos + 4] as i32) | ((raw[pos + 5] as i32) << 8) | ((raw[pos + 6] as i32) << 16) | ((raw[pos + 7] as i32) << 24)
            pos += NOMF_CHUNK_HEADER_SIZE

            if pos + length > raw_len:
                return (0, false)

            if (tag0 == NOMF_TAG_SECT_0) and (tag1 == NOMF_TAG_SECT_1) and (tag2 == NOMF_TAG_SECT_2) and (tag3 == NOMF_TAG_SECT_3):
                # SECT payload: u16 id(0-1), u8 type(2), u8 align(3), u16 org_hint(4-5), u16 flags(6-7), data(8+)
                if length >= 8:
                    let org_hint = (raw[pos + 4] as i32) | ((raw[pos + 5] as i32) << 8)
                    let data_len = length - 8
                    let mut k = 0
                    while k < data_len:
                        self.mem.write_byte(org_hint + k, raw[pos + 8 + k])
                        k += 1
                    if first_section_base < 0:
                        first_section_base = org_hint
            elif (tag0 == NOMF_TAG_ENTR_0) and (tag1 == NOMF_TAG_ENTR_1) and (tag2 == NOMF_TAG_ENTR_2) and (tag3 == NOMF_TAG_ENTR_3):
                # ENTR payload: u8 has_symbol, u16 addr
                if length >= 3:
                    let addr = (raw[pos + 1] as i32) | ((raw[pos + 2] as i32) << 8)
                    entry_point = addr
                    has_entry = true

            pos += length
            seen += 1

        if not has_entry and first_section_base >= 0:
            entry_point = first_section_base

        (entry_point, true)
