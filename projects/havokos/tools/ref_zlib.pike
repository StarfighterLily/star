// Reference half of the zlib check (todo.md HavokOS P1 #8; see
// tools/zlib_check.star): Pike's Gz, the zlib the reference's MCCP
// compresses with (`havok/net.pike`, Gz.deflate(6) with SYNC_FLUSH).
//
//   pike ref_zlib.pike inflate <in> <out>
//       inflate the zlib stream in <in> (a stream cut after a sync flush
//       inflates as far as it goes)
//   pike ref_zlib.pike deflate <in> <out> <level> <chunk>
//       compress <in> `chunk` bytes at a time, sync-flushing each (chunk 0:
//       all at once), then finish the stream
//   pike ref_zlib.pike random <out> <bytes> <seed>
//       write pseudo-random bytes (an incompressible test input)

int main(int argc, array(string) argv) {
    switch (argv[1]) {
    case "inflate": {
        string z = Stdio.read_file(argv[2]);
        Stdio.write_file(argv[3], Gz.inflate()->inflate(z));
        return 0;
    }
    case "deflate": {
        string d = Stdio.read_file(argv[2]);
        int level = (int)argv[4], chunk = (int)argv[5];
        Gz.deflate z = Gz.deflate(level);
        String.Buffer out = String.Buffer();
        if (chunk > 0) {
            for (int i = 0; i < sizeof(d); i += chunk) out->add(z->deflate(d[i..i + chunk - 1], Gz.SYNC_FLUSH));
            out->add(z->deflate("", Gz.FINISH));
        } else out->add(z->deflate(d, Gz.FINISH));
        Stdio.write_file(argv[3], out->get());
        return 0;
    }
    case "random": {
        random_seed((int)argv[4]);
        String.Buffer b = String.Buffer();
        for (int i = 0; i < (int)argv[3]; i++) b->putchar(random(256));
        Stdio.write_file(argv[2], b->get());
        return 0;
    }
    }
    werror("unknown mode\n");
    return 2;
}
