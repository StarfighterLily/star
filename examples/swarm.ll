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

%GenRef = type { i32, i32 }

@frame.buf = global [4096 x i8] zeroinitializer
@frame.off = global i64 0

@star.argc = global i32 0
@star.argv = global i8** null

@rng.state = global i32 123456789

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
@arena.Enemies.gen = global [1024 x i32] zeroinitializer
@arena.Enemies.free = global [1024 x i64] zeroinitializer
@arena.Enemies.free_top = global i64 0

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t80 = alloca { i64, i64 }
  %t93 = alloca { i64, i64 }
  %t106 = alloca { i64, i64 }
  %t119 = alloca { i64, i64 }
  %t145 = alloca { i64, i64 }
  %t191 = alloca { i64, i64 }
  %t204 = alloca { i64, i64 }
  %t217 = alloca { i64, i64 }
  %t230 = alloca { i64, i64 }
  %t256 = alloca { i64, i64 }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  call void @par.pool.ensure_init()
  %t57 = call i32 @GetCurrentThreadId()
  %t58 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t59 = load i32, i32* %t58
  %t60 = icmp eq i32 %t57, %t59
  %t61 = select i1 %t60, i32 0, i32 -1
  %t62 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t63 = load i32, i32* %t62
  %t64 = icmp eq i32 %t57, %t63
  %t65 = select i1 %t64, i32 1, i32 %t61
  %t66 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t67 = load i32, i32* %t66
  %t68 = icmp eq i32 %t57, %t67
  %t69 = select i1 %t68, i32 2, i32 %t65
  %t70 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t71 = load i32, i32* %t70
  %t72 = icmp eq i32 %t57, %t71
  %t73 = select i1 %t72, i32 3, i32 %t69
  %t74 = icmp sge i32 %t73, 0
  br i1 %t74, label %par_serial_7, label %par_pooled_6
par_pooled_6:
  %t75 = load i64, i64* @arena.Enemies.count
  %t76 = mul i64 %t75, 0
  %t77 = sdiv i64 %t76, 4
  %t78 = mul i64 %t75, 1
  %t79 = sdiv i64 %t78, 4
  %t81 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t80, i32 0, i32 0
  store i64 %t77, i64* %t81
  %t82 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t80, i32 0, i32 1
  store i64 %t79, i64* %t82
  %t83 = bitcast { i64, i64 }* %t80 to i8*
  %t84 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t83, i8** %t84
  %t85 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t85
  %t86 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t87 = load i8*, i8** %t86
  %t88 = call i32 @ReleaseSemaphore(i8* %t87, i32 1, i32* null)
  %t89 = mul i64 %t75, 1
  %t90 = sdiv i64 %t89, 4
  %t91 = mul i64 %t75, 2
  %t92 = sdiv i64 %t91, 4
  %t94 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t93, i32 0, i32 0
  store i64 %t90, i64* %t94
  %t95 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t93, i32 0, i32 1
  store i64 %t92, i64* %t95
  %t96 = bitcast { i64, i64 }* %t93 to i8*
  %t97 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t96, i8** %t97
  %t98 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t98
  %t99 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t100 = load i8*, i8** %t99
  %t101 = call i32 @ReleaseSemaphore(i8* %t100, i32 1, i32* null)
  %t102 = mul i64 %t75, 2
  %t103 = sdiv i64 %t102, 4
  %t104 = mul i64 %t75, 3
  %t105 = sdiv i64 %t104, 4
  %t107 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t106, i32 0, i32 0
  store i64 %t103, i64* %t107
  %t108 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t106, i32 0, i32 1
  store i64 %t105, i64* %t108
  %t109 = bitcast { i64, i64 }* %t106 to i8*
  %t110 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t109, i8** %t110
  %t111 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t111
  %t112 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t113 = load i8*, i8** %t112
  %t114 = call i32 @ReleaseSemaphore(i8* %t113, i32 1, i32* null)
  %t115 = mul i64 %t75, 3
  %t116 = sdiv i64 %t115, 4
  %t117 = mul i64 %t75, 4
  %t118 = sdiv i64 %t117, 4
  %t120 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t119, i32 0, i32 0
  store i64 %t116, i64* %t120
  %t121 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t119, i32 0, i32 1
  store i64 %t118, i64* %t121
  %t122 = bitcast { i64, i64 }* %t119 to i8*
  %t123 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t122, i8** %t123
  %t124 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t124
  %t125 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t126 = load i8*, i8** %t125
  %t127 = call i32 @ReleaseSemaphore(i8* %t126, i32 1, i32* null)
  %t128 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t129 = load i8*, i8** %t128
  %t130 = call i32 @WaitForSingleObject(i8* %t129, i32 -1)
  %t131 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t132 = load i8*, i8** %t131
  %t133 = call i32 @WaitForSingleObject(i8* %t132, i32 -1)
  %t134 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t135 = load i8*, i8** %t134
  %t136 = call i32 @WaitForSingleObject(i8* %t135, i32 -1)
  %t137 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t138 = load i8*, i8** %t137
  %t139 = call i32 @WaitForSingleObject(i8* %t138, i32 -1)
  br label %par_join_11
par_serial_7:
  %t140 = load i32, i32* @par.pool.serial_owner
  %t141 = icmp eq i32 %t140, %t73
  br i1 %t141, label %par_run_9, label %par_acquire_8
par_acquire_8:
  %t142 = load i8*, i8** @par.pool.serial_lock
  %t143 = call i32 @WaitForSingleObject(i8* %t142, i32 -1)
  store i32 %t73, i32* @par.pool.serial_owner
  br label %par_run_9
par_run_9:
  %t144 = load i64, i64* @arena.Enemies.count
  %t146 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t145, i32 0, i32 0
  store i64 0, i64* %t146
  %t147 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t145, i32 0, i32 1
  store i64 %t144, i64* %t147
  %t148 = bitcast { i64, i64 }* %t145 to i8*
  %t149 = call i32 @par_worker_0(i8* %t148)
  br i1 %t141, label %par_join_11, label %par_release_10
par_release_10:
  store i32 -1, i32* @par.pool.serial_owner
  %t150 = load i8*, i8** @par.pool.serial_lock
  %t151 = call i32 @ReleaseSemaphore(i8* %t150, i32 1, i32* null)
  br label %par_join_11
par_join_11:
  call void @par.pool.ensure_init()
  %t168 = call i32 @GetCurrentThreadId()
  %t169 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t170 = load i32, i32* %t169
  %t171 = icmp eq i32 %t168, %t170
  %t172 = select i1 %t171, i32 0, i32 -1
  %t173 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t174 = load i32, i32* %t173
  %t175 = icmp eq i32 %t168, %t174
  %t176 = select i1 %t175, i32 1, i32 %t172
  %t177 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t178 = load i32, i32* %t177
  %t179 = icmp eq i32 %t168, %t178
  %t180 = select i1 %t179, i32 2, i32 %t176
  %t181 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t182 = load i32, i32* %t181
  %t183 = icmp eq i32 %t168, %t182
  %t184 = select i1 %t183, i32 3, i32 %t180
  %t185 = icmp sge i32 %t184, 0
  br i1 %t185, label %par_serial_19, label %par_pooled_18
par_pooled_18:
  %t186 = load i64, i64* @arena.Enemies.count
  %t187 = mul i64 %t186, 0
  %t188 = sdiv i64 %t187, 4
  %t189 = mul i64 %t186, 1
  %t190 = sdiv i64 %t189, 4
  %t192 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t191, i32 0, i32 0
  store i64 %t188, i64* %t192
  %t193 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t191, i32 0, i32 1
  store i64 %t190, i64* %t193
  %t194 = bitcast { i64, i64 }* %t191 to i8*
  %t195 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t194, i8** %t195
  %t196 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_12, i32 (i8*)** %t196
  %t197 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t198 = load i8*, i8** %t197
  %t199 = call i32 @ReleaseSemaphore(i8* %t198, i32 1, i32* null)
  %t200 = mul i64 %t186, 1
  %t201 = sdiv i64 %t200, 4
  %t202 = mul i64 %t186, 2
  %t203 = sdiv i64 %t202, 4
  %t205 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t204, i32 0, i32 0
  store i64 %t201, i64* %t205
  %t206 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t204, i32 0, i32 1
  store i64 %t203, i64* %t206
  %t207 = bitcast { i64, i64 }* %t204 to i8*
  %t208 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t207, i8** %t208
  %t209 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_12, i32 (i8*)** %t209
  %t210 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t211 = load i8*, i8** %t210
  %t212 = call i32 @ReleaseSemaphore(i8* %t211, i32 1, i32* null)
  %t213 = mul i64 %t186, 2
  %t214 = sdiv i64 %t213, 4
  %t215 = mul i64 %t186, 3
  %t216 = sdiv i64 %t215, 4
  %t218 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t217, i32 0, i32 0
  store i64 %t214, i64* %t218
  %t219 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t217, i32 0, i32 1
  store i64 %t216, i64* %t219
  %t220 = bitcast { i64, i64 }* %t217 to i8*
  %t221 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t220, i8** %t221
  %t222 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_12, i32 (i8*)** %t222
  %t223 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t224 = load i8*, i8** %t223
  %t225 = call i32 @ReleaseSemaphore(i8* %t224, i32 1, i32* null)
  %t226 = mul i64 %t186, 3
  %t227 = sdiv i64 %t226, 4
  %t228 = mul i64 %t186, 4
  %t229 = sdiv i64 %t228, 4
  %t231 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t230, i32 0, i32 0
  store i64 %t227, i64* %t231
  %t232 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t230, i32 0, i32 1
  store i64 %t229, i64* %t232
  %t233 = bitcast { i64, i64 }* %t230 to i8*
  %t234 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t233, i8** %t234
  %t235 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_12, i32 (i8*)** %t235
  %t236 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t237 = load i8*, i8** %t236
  %t238 = call i32 @ReleaseSemaphore(i8* %t237, i32 1, i32* null)
  %t239 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t240 = load i8*, i8** %t239
  %t241 = call i32 @WaitForSingleObject(i8* %t240, i32 -1)
  %t242 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t243 = load i8*, i8** %t242
  %t244 = call i32 @WaitForSingleObject(i8* %t243, i32 -1)
  %t245 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t246 = load i8*, i8** %t245
  %t247 = call i32 @WaitForSingleObject(i8* %t246, i32 -1)
  %t248 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t249 = load i8*, i8** %t248
  %t250 = call i32 @WaitForSingleObject(i8* %t249, i32 -1)
  br label %par_join_23
par_serial_19:
  %t251 = load i32, i32* @par.pool.serial_owner
  %t252 = icmp eq i32 %t251, %t184
  br i1 %t252, label %par_run_21, label %par_acquire_20
par_acquire_20:
  %t253 = load i8*, i8** @par.pool.serial_lock
  %t254 = call i32 @WaitForSingleObject(i8* %t253, i32 -1)
  store i32 %t184, i32* @par.pool.serial_owner
  br label %par_run_21
par_run_21:
  %t255 = load i64, i64* @arena.Enemies.count
  %t257 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t256, i32 0, i32 0
  store i64 0, i64* %t257
  %t258 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t256, i32 0, i32 1
  store i64 %t255, i64* %t258
  %t259 = bitcast { i64, i64 }* %t256 to i8*
  %t260 = call i32 @par_worker_12(i8* %t259)
  br i1 %t252, label %par_join_23, label %par_release_22
par_release_22:
  store i32 -1, i32* @par.pool.serial_owner
  %t261 = load i8*, i8** @par.pool.serial_lock
  %t262 = call i32 @ReleaseSemaphore(i8* %t261, i32 1, i32* null)
  br label %par_join_23
par_join_23:
  %t263 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t263)
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_0(i8* %argp) {
entry:
  %t7 = alloca i64
  %t1 = bitcast i8* %argp to { i64, i64 }*
  %t2 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t1, i32 0, i32 0
  %t3 = load i64, i64* %t2
  %t4 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t1, i32 0, i32 1
  %t5 = load i64, i64* %t4
  %t6 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t3, i64* %t7
  br label %par_cond_1
par_cond_1:
  %t8 = load i64, i64* %t7
  %t9 = icmp slt i64 %t8, %t5
  br i1 %t9, label %par_body_2, label %par_end_5
par_body_2:
  %t10 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t8
  %t11 = load i32, i32* %t10
  %t12 = and i32 %t11, 1
  %t13 = icmp eq i32 %t12, 1
  br i1 %t13, label %par_live_3, label %par_incr_4
par_live_3:
  %t14 = getelementptr inbounds %Enemy, %Enemy* %t6, i64 %t8
  %t15 = getelementptr inbounds %Enemy, %Enemy* %t14, i32 0, i32 0
  %t16 = load i32, i32* %t15
  %t17 = sub i32 %t16, 1
  %t18 = getelementptr inbounds %Enemy, %Enemy* %t14, i32 0, i32 0
  store i32 %t17, i32* %t18
  br label %par_incr_4
par_incr_4:
  %t19 = add i64 %t8, 1
  store i64 %t19, i64* %t7
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
  %t20 = ptrtoint i8* %idx_arg to i64
  %t21 = trunc i64 %t20 to i32
  %t22 = call i32 @GetCurrentThreadId()
  %t23 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t21
  store i32 %t22, i32* %t23
  br label %loop
loop:
  %t24 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t21
  %t25 = load i8*, i8** %t24
  %t26 = call i32 @WaitForSingleObject(i8* %t25, i32 -1)
  %t27 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t21
  %t28 = load i32 (i8*)*, i32 (i8*)** %t27
  %t29 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t21
  %t30 = load i8*, i8** %t29
  %t31 = call i32 %t28(i8* %t30)
  %t32 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t21
  %t33 = load i8*, i8** %t32
  %t34 = call i32 @ReleaseSemaphore(i8* %t33, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t35 = load i1, i1* @par.pool.inited
  br i1 %t35, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t36 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t36, i8** @par.pool.serial_lock
  %t37 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t38 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t37, i8** %t38
  %t39 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t40 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t39, i8** %t40
  %t41 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t42 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t43 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t42, i8** %t43
  %t44 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t45 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t44, i8** %t45
  %t46 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t47 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t48 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t47, i8** %t48
  %t49 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t50 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t49, i8** %t50
  %t51 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t52 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t53 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t52, i8** %t53
  %t54 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t55 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t54, i8** %t55
  %t56 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_12(i8* %argp) {
entry:
  %t158 = alloca i64
  %t152 = bitcast i8* %argp to { i64, i64 }*
  %t153 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t152, i32 0, i32 0
  %t154 = load i64, i64* %t153
  %t155 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t152, i32 0, i32 1
  %t156 = load i64, i64* %t155
  %t157 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t154, i64* %t158
  br label %par_cond_13
par_cond_13:
  %t159 = load i64, i64* %t158
  %t160 = icmp slt i64 %t159, %t156
  br i1 %t160, label %par_body_14, label %par_end_17
par_body_14:
  %t161 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t159
  %t162 = load i32, i32* %t161
  %t163 = and i32 %t162, 1
  %t164 = icmp eq i32 %t163, 1
  br i1 %t164, label %par_live_15, label %par_incr_16
par_live_15:
  %t165 = getelementptr inbounds %Enemy, %Enemy* %t157, i64 %t159
  %t166 = getelementptr inbounds %Enemy, %Enemy* %t165, i32 0, i32 0
  store i32 0, i32* %t166
  br label %par_incr_16
par_incr_16:
  %t167 = add i64 %t159, 1
  store i64 %t167, i64* %t158
  br label %par_cond_13
par_end_17:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [12 x i8] c"swarm done\0A\00"
