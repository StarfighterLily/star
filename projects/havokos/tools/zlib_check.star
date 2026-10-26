# Star half of the zlib check (todo.md HavokOS P1 #8, `zlib.star`): MCCP's
# compressor is this port's own code, so its output is checked against a
# real zlib rather than against the reference byte for byte (the two
# compress differently and inflate the same). tests/run_zlib_test.ps1 runs
# both directions with tools/ref_zlib.pike (Pike's Gz, the zlib the
# reference's MCCP uses):
#
#   zlib_check deflate <in> <out> <chunk>
#       compress <in> as MCCP does: `chunk` bytes at a time, each write
#       sync-flushed, then the end of the stream (chunk 0: the whole file
#       in one write); the stream goes to <out>
#   zlib_check inflate <in> <out>
#       inflate the zlib stream in <in> to <out> with zlib.star's inflater;
#       prints "ended", "cut" (stopped after a flush) or "broken"
#
# Build: star build projects/havokos/tools/zlib_check.star -o projects/havokos/tools/zlib_check.exe

import "../zlib.star" as z

fn read_all(path: str) -> Bytes:
    let f = file_open(path, "rb")
    if is_null(f):
        return Bytes()
    let b = file_read_bytes(f)
    file_close(f)
    b

fn write_all(path: str, b: Bytes) -> bool:
    let f = file_open(path, "wb")
    if is_null(f):
        return false
    let ok = file_write_bytes(f, b)
    file_close(f)
    ok

fn to_int(s: str) -> i32:
    let b = bytes_from_str(s)
    let mut n = 0
    for i in 0..b.len():
        n = n * 10 + (b[i] as i32) - 48
    n

struct Sink:
    mut b: Bytes = Bytes()

impl Sink:
    fn add(mut self, x: Bytes):
        for i in 0..x.len():
            self.b.push(x[i])

fn main() -> i32:
    let cli = args()
    if cli.len() < 4:
        println("usage: zlib_check deflate <in> <out> <chunk> | inflate <in> <out>")
        return 2
    let data = read_all(cli[2])
    if cli[1] == "deflate":
        let chunk = if cli.len() > 4: to_int(cli[4]) else: 0
        let mut d = z::Deflater()
        let mut out = Sink()
        if chunk > 0:
            let mut off = 0
            while off < data.len():
                let stop = if off + chunk < data.len(): off + chunk else: data.len()
                let mut piece: Bytes = Bytes()
                for i in off..stop:
                    piece.push(data[i])
                out.add(d.deflate(piece, z::SYNC_FLUSH))
                off = stop
            out.add(d.deflate(Bytes(), z::FINISH))
        else:
            out.add(d.deflate(data, z::FINISH))
        if !write_all(cli[3], out.b):
            println("cannot write output")
            return 1
        println(f"{data.len()} -> {out.b.len()}")
        return 0
    if cli[1] == "inflate":
        let r = z::inflate_zlib(data)
        if !write_all(cli[3], r.out):
            println("cannot write output")
            return 1
        println(if r.broken: "broken" elif r.ended: "ended" else: "cut")
        return 0
    println("unknown mode")
    2
