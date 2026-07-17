; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
declare i32 @snprintf(i8*, i64, i8*, ...)
declare i32 @puts(i8*)
declare noalias i8* @malloc(i64)
declare void @free(i8*)
declare void @exit(i32) noreturn
declare i32 @strlen(i8*)
declare i32 @getchar()
declare i8* @memcpy(i8*, i8*, i64)
declare i8* @strcpy(i8*, i8*)
declare i8* @strcat(i8*, i8*)
declare i32 @strcmp(i8*, i8*)
declare i8* @fopen(i8*, i8*)
declare i32 @fclose(i8*)
declare i64 @fread(i8*, i64, i64, i8*)
declare i64 @fwrite(i8*, i64, i64, i8*)
declare i32 @fseek(i8*, i32, i32)
declare i32 @ftell(i8*)
declare i32 @fgetc(i8*)
declare i8* @getenv(i8*)
declare i32 @_putenv_s(i8*, i8*)
declare i32 @WSAStartup(i16, i8*)
declare i8* @socket(i32, i32, i32)
declare i32 @connect(i8*, i8*, i32)
declare i32 @send(i8*, i8*, i32, i32)
declare i32 @recv(i8*, i8*, i32, i32)
declare i32 @closesocket(i8*)
declare i16 @htons(i16)
declare i32 @inet_addr(i8*)
declare i8* @CreateThread(i8*, i64, i8*, i8*, i32, i32*)
declare i32 @WaitForSingleObject(i8*, i32)
declare i32 @CloseHandle(i8*)
declare i8* @CreateSemaphoreA(i8*, i32, i32, i8*)
declare i32 @ReleaseSemaphore(i8*, i32, i32*)
declare i32 @GetCurrentThreadId()
declare float @llvm.sqrt.f32(float)
declare float @llvm.pow.f32(float, float)
declare float @llvm.fabs.f32(float)
declare float @llvm.floor.f32(float)
declare float @llvm.ceil.f32(float)
declare float @llvm.minnum.f32(float, float)
declare float @llvm.maxnum.f32(float, float)
declare i8 @llvm.fptosi.sat.i8.f32(float)
declare i8 @llvm.fptosi.sat.i8.f64(double)
declare i8 @llvm.fptoui.sat.i8.f32(float)
declare i8 @llvm.fptoui.sat.i8.f64(double)
declare i16 @llvm.fptosi.sat.i16.f32(float)
declare i16 @llvm.fptosi.sat.i16.f64(double)
declare i16 @llvm.fptoui.sat.i16.f32(float)
declare i16 @llvm.fptoui.sat.i16.f64(double)
declare i32 @llvm.fptosi.sat.i32.f32(float)
declare i32 @llvm.fptosi.sat.i32.f64(double)
declare i32 @llvm.fptoui.sat.i32.f32(float)
declare i32 @llvm.fptoui.sat.i32.f64(double)
declare i64 @llvm.fptosi.sat.i64.f32(float)
declare i64 @llvm.fptosi.sat.i64.f64(double)
declare i64 @llvm.fptoui.sat.i64.f32(float)
declare i64 @llvm.fptoui.sat.i64.f64(double)
declare { i8, i1 } @llvm.sadd.with.overflow.i8(i8, i8)
declare { i8, i1 } @llvm.ssub.with.overflow.i8(i8, i8)
declare { i8, i1 } @llvm.smul.with.overflow.i8(i8, i8)
declare { i8, i1 } @llvm.uadd.with.overflow.i8(i8, i8)
declare { i8, i1 } @llvm.usub.with.overflow.i8(i8, i8)
declare { i8, i1 } @llvm.umul.with.overflow.i8(i8, i8)
declare { i16, i1 } @llvm.sadd.with.overflow.i16(i16, i16)
declare { i16, i1 } @llvm.ssub.with.overflow.i16(i16, i16)
declare { i16, i1 } @llvm.smul.with.overflow.i16(i16, i16)
declare { i16, i1 } @llvm.uadd.with.overflow.i16(i16, i16)
declare { i16, i1 } @llvm.usub.with.overflow.i16(i16, i16)
declare { i16, i1 } @llvm.umul.with.overflow.i16(i16, i16)
declare { i64, i1 } @llvm.sadd.with.overflow.i64(i64, i64)
declare { i64, i1 } @llvm.ssub.with.overflow.i64(i64, i64)
declare { i64, i1 } @llvm.smul.with.overflow.i64(i64, i64)
declare { i64, i1 } @llvm.uadd.with.overflow.i64(i64, i64)
declare { i64, i1 } @llvm.usub.with.overflow.i64(i64, i64)
declare { i64, i1 } @llvm.umul.with.overflow.i64(i64, i64)
declare { i32, i1 } @llvm.uadd.with.overflow.i32(i32, i32)
declare { i32, i1 } @llvm.usub.with.overflow.i32(i32, i32)
declare { i32, i1 } @llvm.umul.with.overflow.i32(i32, i32)

%GenRef = type { i32, i64 }

@frame.buf = global [4096 x i8] zeroinitializer
@frame.off = global i64 0

@star.argc = global i32 0
@star.argv = global i8** null

@rng.state = global i32 123456789
@rng.lock = global i8* null

@sym.data = global i8** null
@sym.len = global i64 0
@sym.cap = global i64 0
@sym.lock = global i8* null

define i8* @star_rc_alloc(i64 %size, i8* %release_fn) {
entry:
  %total = add i64 %size, 16
  %raw = call i8* @malloc(i64 %total)
  %hdr = bitcast i8* %raw to i64*
  store i64 1, i64* %hdr
  %relfn_slot_i8 = getelementptr inbounds i8, i8* %raw, i64 8
  %relfn_slot = bitcast i8* %relfn_slot_i8 to i8**
  store i8* %release_fn, i8** %relfn_slot
  %data = getelementptr inbounds i8, i8* %raw, i64 16
  ret i8* %data
}

define void @star_rc_retain(i8* %p) {
entry:
  %isnull = icmp eq i8* %p, null
  br i1 %isnull, label %done, label %do
do:
  %hdr_i8 = getelementptr inbounds i8, i8* %p, i64 -16
  %hdr = bitcast i8* %hdr_i8 to i64*
  %rc = load atomic i64, i64* %hdr seq_cst, align 8
  %is_immortal = icmp eq i64 %rc, -1
  br i1 %is_immortal, label %done, label %incr
incr:
  %rc1 = atomicrmw add i64* %hdr, i64 1 seq_cst
  br label %done
done:
  ret void
}

define void @star_rc_release(i8* %p) {
entry:
  %isnull = icmp eq i8* %p, null
  br i1 %isnull, label %done, label %do
do:
  %hdr_i8 = getelementptr inbounds i8, i8* %p, i64 -16
  %hdr = bitcast i8* %hdr_i8 to i64*
  %rc = load atomic i64, i64* %hdr seq_cst, align 8
  %is_immortal = icmp eq i64 %rc, -1
  br i1 %is_immortal, label %done, label %decr
decr:
  %rc_old = atomicrmw sub i64* %hdr, i64 1 seq_cst
  %iszero = icmp eq i64 %rc_old, 1
  br i1 %iszero, label %free, label %done
free:
  %relfn_slot_i8 = getelementptr inbounds i8, i8* %p, i64 -8
  %relfn_slot = bitcast i8* %relfn_slot_i8 to i8**
  %relfn = load i8*, i8** %relfn_slot
  %relfn_isnull = icmp eq i8* %relfn, null
  br i1 %relfn_isnull, label %dofree, label %callrelfn
callrelfn:
  %relfn_typed = bitcast i8* %relfn to void (i8*)*
  call void %relfn_typed(i8* %p)
  br label %dofree
dofree:
  call void @free(i8* %hdr_i8)
  br label %done
done:
  ret void
}

%Enemy = type { i32 }
%Enemies = type { %Enemy*, i64 }
@arena.Enemies.data = global %Enemy* null
@arena.Enemies.count = global i64 0
@arena.Enemies.gen = global [1024 x i64] zeroinitializer
@arena.Enemies.free = global [1024 x i64] zeroinitializer
@arena.Enemies.free_top = global i64 0

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t81 = alloca { i64, i64 }
  %t94 = alloca { i64, i64 }
  %t107 = alloca { i64, i64 }
  %t120 = alloca { i64, i64 }
  %t146 = alloca { i64, i64 }
  %t192 = alloca { i64, i64 }
  %t205 = alloca { i64, i64 }
  %t218 = alloca { i64, i64 }
  %t231 = alloca { i64, i64 }
  %t257 = alloca { i64, i64 }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  call void @par.pool.ensure_init()
  %t58 = call i32 @GetCurrentThreadId()
  %t59 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t60 = load i32, i32* %t59
  %t61 = icmp eq i32 %t58, %t60
  %t62 = select i1 %t61, i32 0, i32 -1
  %t63 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t64 = load i32, i32* %t63
  %t65 = icmp eq i32 %t58, %t64
  %t66 = select i1 %t65, i32 1, i32 %t62
  %t67 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t68 = load i32, i32* %t67
  %t69 = icmp eq i32 %t58, %t68
  %t70 = select i1 %t69, i32 2, i32 %t66
  %t71 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t72 = load i32, i32* %t71
  %t73 = icmp eq i32 %t58, %t72
  %t74 = select i1 %t73, i32 3, i32 %t70
  %t75 = icmp sge i32 %t74, 0
  br i1 %t75, label %par_serial_7, label %par_pooled_6
par_pooled_6:
  %t76 = load i64, i64* @arena.Enemies.count
  %t77 = mul i64 %t76, 0
  %t78 = sdiv i64 %t77, 4
  %t79 = mul i64 %t76, 1
  %t80 = sdiv i64 %t79, 4
  %t82 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t81, i32 0, i32 0
  store i64 %t78, i64* %t82
  %t83 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t81, i32 0, i32 1
  store i64 %t80, i64* %t83
  %t84 = bitcast { i64, i64 }* %t81 to i8*
  %t85 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t84, i8** %t85
  %t86 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t86
  %t87 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t88 = load i8*, i8** %t87
  %t89 = call i32 @ReleaseSemaphore(i8* %t88, i32 1, i32* null)
  %t90 = mul i64 %t76, 1
  %t91 = sdiv i64 %t90, 4
  %t92 = mul i64 %t76, 2
  %t93 = sdiv i64 %t92, 4
  %t95 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t94, i32 0, i32 0
  store i64 %t91, i64* %t95
  %t96 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t94, i32 0, i32 1
  store i64 %t93, i64* %t96
  %t97 = bitcast { i64, i64 }* %t94 to i8*
  %t98 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t97, i8** %t98
  %t99 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t99
  %t100 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t101 = load i8*, i8** %t100
  %t102 = call i32 @ReleaseSemaphore(i8* %t101, i32 1, i32* null)
  %t103 = mul i64 %t76, 2
  %t104 = sdiv i64 %t103, 4
  %t105 = mul i64 %t76, 3
  %t106 = sdiv i64 %t105, 4
  %t108 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t107, i32 0, i32 0
  store i64 %t104, i64* %t108
  %t109 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t107, i32 0, i32 1
  store i64 %t106, i64* %t109
  %t110 = bitcast { i64, i64 }* %t107 to i8*
  %t111 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t110, i8** %t111
  %t112 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t112
  %t113 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t114 = load i8*, i8** %t113
  %t115 = call i32 @ReleaseSemaphore(i8* %t114, i32 1, i32* null)
  %t116 = mul i64 %t76, 3
  %t117 = sdiv i64 %t116, 4
  %t118 = mul i64 %t76, 4
  %t119 = sdiv i64 %t118, 4
  %t121 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t120, i32 0, i32 0
  store i64 %t117, i64* %t121
  %t122 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t120, i32 0, i32 1
  store i64 %t119, i64* %t122
  %t123 = bitcast { i64, i64 }* %t120 to i8*
  %t124 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t123, i8** %t124
  %t125 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t125
  %t126 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t127 = load i8*, i8** %t126
  %t128 = call i32 @ReleaseSemaphore(i8* %t127, i32 1, i32* null)
  %t129 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t130 = load i8*, i8** %t129
  %t131 = call i32 @WaitForSingleObject(i8* %t130, i32 -1)
  %t132 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t133 = load i8*, i8** %t132
  %t134 = call i32 @WaitForSingleObject(i8* %t133, i32 -1)
  %t135 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t136 = load i8*, i8** %t135
  %t137 = call i32 @WaitForSingleObject(i8* %t136, i32 -1)
  %t138 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t139 = load i8*, i8** %t138
  %t140 = call i32 @WaitForSingleObject(i8* %t139, i32 -1)
  br label %par_join_11
par_serial_7:
  %t141 = load i32, i32* @par.pool.serial_owner
  %t142 = icmp eq i32 %t141, %t74
  br i1 %t142, label %par_run_9, label %par_acquire_8
par_acquire_8:
  %t143 = load i8*, i8** @par.pool.serial_lock
  %t144 = call i32 @WaitForSingleObject(i8* %t143, i32 -1)
  store i32 %t74, i32* @par.pool.serial_owner
  br label %par_run_9
par_run_9:
  %t145 = load i64, i64* @arena.Enemies.count
  %t147 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t146, i32 0, i32 0
  store i64 0, i64* %t147
  %t148 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t146, i32 0, i32 1
  store i64 %t145, i64* %t148
  %t149 = bitcast { i64, i64 }* %t146 to i8*
  %t150 = call i32 @par_worker_0(i8* %t149)
  br i1 %t142, label %par_join_11, label %par_release_10
par_release_10:
  store i32 -1, i32* @par.pool.serial_owner
  %t151 = load i8*, i8** @par.pool.serial_lock
  %t152 = call i32 @ReleaseSemaphore(i8* %t151, i32 1, i32* null)
  br label %par_join_11
par_join_11:
  call void @par.pool.ensure_init()
  %t169 = call i32 @GetCurrentThreadId()
  %t170 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t171 = load i32, i32* %t170
  %t172 = icmp eq i32 %t169, %t171
  %t173 = select i1 %t172, i32 0, i32 -1
  %t174 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t175 = load i32, i32* %t174
  %t176 = icmp eq i32 %t169, %t175
  %t177 = select i1 %t176, i32 1, i32 %t173
  %t178 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t179 = load i32, i32* %t178
  %t180 = icmp eq i32 %t169, %t179
  %t181 = select i1 %t180, i32 2, i32 %t177
  %t182 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t183 = load i32, i32* %t182
  %t184 = icmp eq i32 %t169, %t183
  %t185 = select i1 %t184, i32 3, i32 %t181
  %t186 = icmp sge i32 %t185, 0
  br i1 %t186, label %par_serial_19, label %par_pooled_18
par_pooled_18:
  %t187 = load i64, i64* @arena.Enemies.count
  %t188 = mul i64 %t187, 0
  %t189 = sdiv i64 %t188, 4
  %t190 = mul i64 %t187, 1
  %t191 = sdiv i64 %t190, 4
  %t193 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t192, i32 0, i32 0
  store i64 %t189, i64* %t193
  %t194 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t192, i32 0, i32 1
  store i64 %t191, i64* %t194
  %t195 = bitcast { i64, i64 }* %t192 to i8*
  %t196 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t195, i8** %t196
  %t197 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_12, i32 (i8*)** %t197
  %t198 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t199 = load i8*, i8** %t198
  %t200 = call i32 @ReleaseSemaphore(i8* %t199, i32 1, i32* null)
  %t201 = mul i64 %t187, 1
  %t202 = sdiv i64 %t201, 4
  %t203 = mul i64 %t187, 2
  %t204 = sdiv i64 %t203, 4
  %t206 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t205, i32 0, i32 0
  store i64 %t202, i64* %t206
  %t207 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t205, i32 0, i32 1
  store i64 %t204, i64* %t207
  %t208 = bitcast { i64, i64 }* %t205 to i8*
  %t209 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t208, i8** %t209
  %t210 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_12, i32 (i8*)** %t210
  %t211 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t212 = load i8*, i8** %t211
  %t213 = call i32 @ReleaseSemaphore(i8* %t212, i32 1, i32* null)
  %t214 = mul i64 %t187, 2
  %t215 = sdiv i64 %t214, 4
  %t216 = mul i64 %t187, 3
  %t217 = sdiv i64 %t216, 4
  %t219 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t218, i32 0, i32 0
  store i64 %t215, i64* %t219
  %t220 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t218, i32 0, i32 1
  store i64 %t217, i64* %t220
  %t221 = bitcast { i64, i64 }* %t218 to i8*
  %t222 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t221, i8** %t222
  %t223 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_12, i32 (i8*)** %t223
  %t224 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t225 = load i8*, i8** %t224
  %t226 = call i32 @ReleaseSemaphore(i8* %t225, i32 1, i32* null)
  %t227 = mul i64 %t187, 3
  %t228 = sdiv i64 %t227, 4
  %t229 = mul i64 %t187, 4
  %t230 = sdiv i64 %t229, 4
  %t232 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t231, i32 0, i32 0
  store i64 %t228, i64* %t232
  %t233 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t231, i32 0, i32 1
  store i64 %t230, i64* %t233
  %t234 = bitcast { i64, i64 }* %t231 to i8*
  %t235 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t234, i8** %t235
  %t236 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_12, i32 (i8*)** %t236
  %t237 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t238 = load i8*, i8** %t237
  %t239 = call i32 @ReleaseSemaphore(i8* %t238, i32 1, i32* null)
  %t240 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t241 = load i8*, i8** %t240
  %t242 = call i32 @WaitForSingleObject(i8* %t241, i32 -1)
  %t243 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t244 = load i8*, i8** %t243
  %t245 = call i32 @WaitForSingleObject(i8* %t244, i32 -1)
  %t246 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t247 = load i8*, i8** %t246
  %t248 = call i32 @WaitForSingleObject(i8* %t247, i32 -1)
  %t249 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t250 = load i8*, i8** %t249
  %t251 = call i32 @WaitForSingleObject(i8* %t250, i32 -1)
  br label %par_join_23
par_serial_19:
  %t252 = load i32, i32* @par.pool.serial_owner
  %t253 = icmp eq i32 %t252, %t185
  br i1 %t253, label %par_run_21, label %par_acquire_20
par_acquire_20:
  %t254 = load i8*, i8** @par.pool.serial_lock
  %t255 = call i32 @WaitForSingleObject(i8* %t254, i32 -1)
  store i32 %t185, i32* @par.pool.serial_owner
  br label %par_run_21
par_run_21:
  %t256 = load i64, i64* @arena.Enemies.count
  %t258 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t257, i32 0, i32 0
  store i64 0, i64* %t258
  %t259 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t257, i32 0, i32 1
  store i64 %t256, i64* %t259
  %t260 = bitcast { i64, i64 }* %t257 to i8*
  %t261 = call i32 @par_worker_12(i8* %t260)
  br i1 %t253, label %par_join_23, label %par_release_22
par_release_22:
  store i32 -1, i32* @par.pool.serial_owner
  %t262 = load i8*, i8** @par.pool.serial_lock
  %t263 = call i32 @ReleaseSemaphore(i8* %t262, i32 1, i32* null)
  br label %par_join_23
par_join_23:
  %t264 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t264)
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_0(i8* %argp) {
entry:
  %t8 = alloca i64
  %t2 = bitcast i8* %argp to { i64, i64 }*
  %t3 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t2, i32 0, i32 0
  %t4 = load i64, i64* %t3
  %t5 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t2, i32 0, i32 1
  %t6 = load i64, i64* %t5
  %t7 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t4, i64* %t8
  br label %par_cond_1
par_cond_1:
  %t9 = load i64, i64* %t8
  %t10 = icmp slt i64 %t9, %t6
  br i1 %t10, label %par_body_2, label %par_end_5
par_body_2:
  %t11 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t9
  %t12 = load i64, i64* %t11
  %t13 = and i64 %t12, 1
  %t14 = icmp eq i64 %t13, 1
  br i1 %t14, label %par_live_3, label %par_incr_4
par_live_3:
  %t15 = getelementptr inbounds %Enemy, %Enemy* %t7, i64 %t9
  %t16 = getelementptr inbounds %Enemy, %Enemy* %t15, i32 0, i32 0
  %t17 = load i32, i32* %t16
  %t18 = sub i32 %t17, 1
  %t19 = getelementptr inbounds %Enemy, %Enemy* %t15, i32 0, i32 0
  store i32 %t18, i32* %t19
  br label %par_incr_4
par_incr_4:
  %t20 = add i64 %t9, 1
  store i64 %t20, i64* %t8
  br label %par_cond_1
par_end_5:
  ret i32 0
}


@par.pool.job_fn = global [4 x i32 (i8*)*] zeroinitializer
@par.pool.job_arg = global [4 x i8*] zeroinitializer
@par.pool.start_sem = global [4 x i8*] zeroinitializer
@par.pool.done_sem = global [4 x i8*] zeroinitializer
@par.pool.tid = global [4 x i32] zeroinitializer
@par.pool.inited = global i1 false
@par.pool.serial_lock = global i8* null
@par.pool.serial_owner = global i32 -1

define i32 @par.pool.worker_main(i8* %idx_arg) {
entry:
  %t21 = ptrtoint i8* %idx_arg to i64
  %t22 = trunc i64 %t21 to i32
  %t23 = call i32 @GetCurrentThreadId()
  %t24 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t22
  store i32 %t23, i32* %t24
  br label %loop
loop:
  %t25 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t22
  %t26 = load i8*, i8** %t25
  %t27 = call i32 @WaitForSingleObject(i8* %t26, i32 -1)
  %t28 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t22
  %t29 = load i32 (i8*)*, i32 (i8*)** %t28
  %t30 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t22
  %t31 = load i8*, i8** %t30
  %t32 = call i32 %t29(i8* %t31)
  %t33 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t22
  %t34 = load i8*, i8** %t33
  %t35 = call i32 @ReleaseSemaphore(i8* %t34, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t36 = load i1, i1* @par.pool.inited
  br i1 %t36, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t37 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t37, i8** @par.pool.serial_lock
  %t38 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t39 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t38, i8** %t39
  %t40 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t41 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t40, i8** %t41
  %t42 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t43 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t44 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t43, i8** %t44
  %t45 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t46 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t45, i8** %t46
  %t47 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t48 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t49 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t48, i8** %t49
  %t50 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t51 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t50, i8** %t51
  %t52 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t53 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t54 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t53, i8** %t54
  %t55 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t56 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t55, i8** %t56
  %t57 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_12(i8* %argp) {
entry:
  %t159 = alloca i64
  %t153 = bitcast i8* %argp to { i64, i64 }*
  %t154 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t153, i32 0, i32 0
  %t155 = load i64, i64* %t154
  %t156 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t153, i32 0, i32 1
  %t157 = load i64, i64* %t156
  %t158 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t155, i64* %t159
  br label %par_cond_13
par_cond_13:
  %t160 = load i64, i64* %t159
  %t161 = icmp slt i64 %t160, %t157
  br i1 %t161, label %par_body_14, label %par_end_17
par_body_14:
  %t162 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t160
  %t163 = load i64, i64* %t162
  %t164 = and i64 %t163, 1
  %t165 = icmp eq i64 %t164, 1
  br i1 %t165, label %par_live_15, label %par_incr_16
par_live_15:
  %t166 = getelementptr inbounds %Enemy, %Enemy* %t158, i64 %t160
  %t167 = getelementptr inbounds %Enemy, %Enemy* %t166, i32 0, i32 0
  store i32 0, i32* %t167
  br label %par_incr_16
par_incr_16:
  %t168 = add i64 %t160, 1
  store i64 %t168, i64* %t159
  br label %par_cond_13
par_end_17:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [12 x i8] c"swarm done\0A\00"
