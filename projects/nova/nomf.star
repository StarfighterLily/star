# Nova Object Module Format (NOMF) reader
# =========================================
#
# Parses the NOMF binary container the upstream Python `nova_assembler.py`
# now emits by default (see sibling Python repo's `nova/nomf.py`). NOMF
# replaces the loose `.bin` + `.org` + `.sym` sidecar trio with one
# self-describing artifact: a 16-byte header followed by TLV chunks.
#
# Layout (all integers little-endian; 16-bit values throughout because the
# Nova-16 address space is a flat 64KB):
#
#   Header (16 bytes):
#     0x00  4   magic  b"NOMF"
#     0x04  1   format version (currently 1)
#     0x05  1   kind (0=object, 1=executable, 2=archive)
#     0x06  2   flags (bit0 has-symbols, bit1 has-relocs, bit2 has-debug)
#     0x08  4   CRC32 (zlib) of every byte after the header
#     0x0C  4   chunk count
#     0x10  ... chunks
#
#   Chunk = 4-byte ASCII tag + u32 LE payload length + payload
#
# Document kinds:
#   .nobj (KIND_OBJECT)     relocatable object -- not loadable directly
#   .nex  (KIND_EXECUTABLE) linked executable -- absolute load segments +
#                           explicit entry point. This is what load_nomf()
#                           returns.
#   .nlib (KIND_ARCHIVE)    archive of objects (reserved; not emitted yet)
#
# Chunk tags the loader cares about:
#   SECT  -- one section (id, type, org_hint, raw bytes). For executables,
#            org_hint is the absolute load address.
#   ENTR  -- explicit entry point (addr + optional symbol name)
#
# Unknown chunk tags are skipped (forward compatibility).
#
# Two entry points for the rest of this project:
#   file_kind(path) -> (kind, ok)       cheap magic+kind probe (no full parse)
#   load_nomf(path)  -> (entry, ok)      full parse, returns entry point +
#                                       loads nothing (caller places segments)
#
# `load_nomf` does NOT write memory itself -- it returns the parsed document
# so the caller (loader.star's Cpu::load_program) can place each section's
# bytes at its declared address, exactly mirroring how the Python reference's
# `Memory._load_nomf` iterates `doc.load_segments()` and calls
# `_place_segment` for each.
#
# Star language notes:
# - Struct constructors are positional, not named.
# - Integer literals default to `Int` (i32); hex literals > 0x7FFFFFFF
#   overflow i32, so CRC32 constants use `as i64` casts.
# - `const` declarations require the literal to match the annotated type
#   exactly (`78 as u8`, not bare `78`).
# - Local variable array types (`[T; N]`) are not supported; use `List<T>`
#   for dynamically-built tables.
# - All constants must be defined before use (no forward references).

import "bits.star" as bits

# -- Data structures (declared first; used by functions below) -----------

struct Section:
    mut id: i32
    mut sec_type: i32
    mut org_hint: i32
    mut data: Bytes

struct NomfDocument:
    mut kind: i32
    mut sections: List<Section>
    mut entry_addr: i32
    mut has_entry: bool

# -- Format constants (defined before use) -------------------------------

const MAGIC_0: u8 = 78 as u8   # 'N'
const MAGIC_1: u8 = 79 as u8   # 'O'
const MAGIC_2: u8 = 77 as u8   # 'M'
const MAGIC_3: u8 = 70 as u8   # 'F'

const FORMAT_VERSION: i32 = 1

const KIND_OBJECT: i32 = 0
const KIND_EXECUTABLE: i32 = 1
const KIND_ARCHIVE: i32 = 2

const HEADER_SIZE: i32 = 16
const CHUNK_HEADER_SIZE: i32 = 8

# Chunk tags (4 bytes each, compared byte-by-byte)
const TAG_SECT_0: u8 = 83 as u8   # 'S'
const TAG_SECT_1: u8 = 69 as u8   # 'E'
const TAG_SECT_2: u8 = 67 as u8   # 'C'
const TAG_SECT_3: u8 = 84 as u8   # 'T'

const TAG_ENTR_0: u8 = 69 as u8   # 'E'
const TAG_ENTR_1: u8 = 78 as u8   # 'N'
const TAG_ENTR_2: u8 = 84 as u8   # 'T'
const TAG_ENTR_3: u8 = 82 as u8   # 'R'

# CRC32 constants (i64 to avoid overflow -- both exceed i32::MAX)
const CRC_TABLE_SIZE: i32 = 256
const CRC_POLY: i64 = 3988292384 as i64   # 0xEDB88320 as i64
const CRC_INIT: i64 = 4294967295 as i64   # 0xFFFFFFFF as i64
const CRC_MASK: i64 = 255 as i64           # 0xFF as i64

fn new_document() -> NomfDocument:
    NomfDocument(1, List<Section>(), 0, false)

# -- CRC32 (zlib-compatible) ---------------------------------------------
#
# Standard CRC32 with the reflected polynomial 0xEDB88320, initialized with
# 0xFFFFFFFF and final-xored with 0xFFFFFFFF -- matches zlib.crc32 exactly.
# Uses a 256-entry lookup table generated at first call.
#
# All arithmetic is done in i64 to avoid i32 overflow on the hex constants
# (0xEDB88320 and 0xFFFFFFFF both exceed i32::MAX). Constants are defined
# at the top of the file (before use).

fn _crc_table_init() -> List<i64>:
    let mut table = List<i64>()
    let mut i = 0
    while i < CRC_TABLE_SIZE:
        let mut c: i64 = i as i64
        let mut j = 0
        while j < 8:
            if (c & 1 as i64) != 0 as i64:
                c = CRC_POLY ^ (c >> 1)
            else:
                c = c >> 1
            j += 1
        table.push(c)
        i += 1
    table

fn _crc32(data: Bytes) -> i64:
    let table = _crc_table_init()
    let mut crc: i64 = CRC_INIT
    let mut i = 0
    while i < data.len():
        let idx = ((crc ^ (data[i] as i64)) & CRC_MASK) as i32
        crc = table[idx] ^ (crc >> 8)
        i += 1
    crc ^ CRC_INIT

# -- Integer reading helpers (little-endian) -----------------------------

fn _read_u16_le(data: Bytes, off: i32) -> i32:
    (data[off] as i32) | ((data[off + 1] as i32) << 8)

fn _read_u32_le(data: Bytes, off: i32) -> i32:
    (data[off] as i32) | ((data[off + 1] as i32) << 8) | ((data[off + 2] as i32) << 16) | ((data[off + 3] as i32) << 24)

# -- Payload sub-range copy ----------------------------------------------
#
# Star's Bytes type has no slice operation -- _payload_new copies the
# sub-range [start, start+length) into a fresh Bytes so the original file
# buffer can be dropped independently.

fn _payload_new(data: Bytes, start: i32, length: i32) -> Bytes:
    let mut buf = Bytes()
    let mut i = 0
    while i < length:
        buf.push(data[start + i])
        i += 1
    buf

# -- Section decode ------------------------------------------------------
#
# SECT payload layout (from nova/nomf.py::Section.encode):
#   u16 LE  id
#   u8      type
#   u8      alignment
#   u16 LE  org_hint
#   u16 LE  flags
#   ...     data (rest of payload)

fn _decode_section(payload: Bytes) -> Section:
    let id = _read_u16_le(payload, 0)
    let sec_type = payload[2] as i32
    # alignment at byte 3 (skip)
    let org_hint = _read_u16_le(payload, 4)
    # flags at offset 6-7 (skip)
    let data_len = payload.len() - 8
    let data = _payload_new(payload, 8, data_len)
    Section(id, sec_type, org_hint, data)

# -- Entry decode --------------------------------------------------------
#
# ENTR payload layout (from nova/nomf.py::Entry.encode):
#   u8      has_symbol (0 or 1)
#   u16 LE  addr
#   str     symbol (u16 length + UTF-8 bytes, only if has_symbol)

fn _decode_entry(payload: Bytes) -> (i32, bool):
    let has_symbol = payload[0] as i32
    let addr = _read_u16_le(payload, 1)
    # Skip symbol string if present (not needed by loader)
    (addr, has_symbol != 0)

# -- File kind probe -----------------------------------------------------
fn file_kind(path: str) -> (i32, bool):
    let fh = file_open(path, "rb")
    if is_null(fh):
        return (0, false)
    let head = file_read_bytes(fh)
    file_close(fh)
    if head.len() < 6:
        return (0, false)
    if not (head[0] == MAGIC_0 and head[1] == MAGIC_1 and head[2] == MAGIC_2 and head[3] == MAGIC_3):
        return (0, false)
    (head[5] as i32, true)

# -- Full NOMF parse -----------------------------------------------------
#
# Reads and validates a NOMF file, returning the parsed document.
# Returns (doc, ok); ok=false on any parse/validation error.

fn read(path: str) -> (NomfDocument, bool):
    let fh = file_open(path, "rb")
    if is_null(fh):
        return (new_document(), false)
    let raw = file_read_bytes(fh)
    file_close(fh)

    if raw.len() < HEADER_SIZE:
        return (new_document(), false)

    # Magic check
    if not (raw[0] == MAGIC_0 and raw[1] == MAGIC_1 and raw[2] == MAGIC_2 and raw[3] == MAGIC_3):
        return (new_document(), false)

    let version = raw[4] as i32
    let kind = raw[5] as i32
    # flags at offset 6-7 (not needed for loading)
    let stored_crc = _read_u32_le(raw, 8) as i64
    let chunk_count = _read_u32_le(raw, 12)

    if version != FORMAT_VERSION:
        return (new_document(), false)
    if kind != KIND_OBJECT and kind != KIND_EXECUTABLE and kind != KIND_ARCHIVE:
        return (new_document(), false)

    # CRC32 validation: compute over all bytes after the header.
    let body = _payload_new(raw, HEADER_SIZE, raw.len() - HEADER_SIZE)
    let actual_crc = _crc32(body)
    if actual_crc != stored_crc:
        return (new_document(), false)

    let mut doc = new_document()
    doc.kind = kind

    # Parse chunks
    let mut pos = HEADER_SIZE
    let mut seen = 0
    let raw_len = raw.len()

    while pos < raw_len:
        if seen >= chunk_count:
            break
        if pos + CHUNK_HEADER_SIZE > raw_len:
            return (new_document(), false)
        let tag0 = raw[pos]
        let tag1 = raw[pos + 1]
        let tag2 = raw[pos + 2]
        let tag3 = raw[pos + 3]
        let length = _read_u32_le(raw, pos + 4)
        pos += CHUNK_HEADER_SIZE
        if pos + length > raw_len:
            return (new_document(), false)

        # Check tag and decode if needed
        if (tag0 == TAG_SECT_0) and (tag1 == TAG_SECT_1) and (tag2 == TAG_SECT_2) and (tag3 == TAG_SECT_3):
            let payload = _payload_new(raw, pos, length)
            let sec = _decode_section(payload)
            doc.sections.push(sec)
        elif (tag0 == TAG_ENTR_0) and (tag1 == TAG_ENTR_1) and (tag2 == TAG_ENTR_2) and (tag3 == TAG_ENTR_3):
            let payload = _payload_new(raw, pos, length)
            let (addr, has_sym) = _decode_entry(payload)
            doc.entry_addr = addr
            doc.has_entry = true
        # Skip all other tags (MODL, SYMT, RELC, DBG, MAP, unknown)

        pos += length
        seen += 1

    (doc, true)

# -- Load entry point for the loader -------------------------------------
#
# High-level entry point used by loader.star: parse the NOMF file and
# return (entry_point, ok). The caller is responsible for placing each
# section's bytes at its org_hint address (mirrors the Python reference's
# Memory._load_nomf iterating doc.load_segments()).

fn load_nomf(path: str) -> (i32, bool):
    let (doc, ok) = read(path)
    if not ok:
        return (0, false)
    if doc.kind == KIND_OBJECT:
        # Relocatable object -- not loadable directly (needs linking first)
        return (0, false)
    if doc.kind != KIND_EXECUTABLE:
        return (0, false)
    if doc.sections.len() == 0:
        return (0, false)
    if doc.has_entry:
        return (doc.entry_addr, true)
    # No ENTR chunk: fall back to lowest section base
    let mut min_base = 0x10000
    let mut i = 0
    while i < doc.sections.len():
        if doc.sections[i].org_hint < min_base:
            min_base = doc.sections[i].org_hint
        i += 1
    (min_base, true)
