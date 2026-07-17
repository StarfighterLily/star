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
  %t79 = alloca { i64, i64 }
  %t92 = alloca { i64, i64 }
  %t105 = alloca { i64, i64 }
  %t118 = alloca { i64, i64 }
  %t144 = alloca { i64, i64 }
  %t190 = alloca { i64, i64 }
  %t203 = alloca { i64, i64 }
  %t216 = alloca { i64, i64 }
  %t229 = alloca { i64, i64 }
  %t255 = alloca { i64, i64 }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  call void @par.pool.ensure_init()
  %t56 = call i32 @GetCurrentThreadId()
  %t57 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t58 = load i32, i32* %t57
  %t59 = icmp eq i32 %t56, %t58
  %t60 = select i1 %t59, i32 0, i32 -1
  %t61 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t62 = load i32, i32* %t61
  %t63 = icmp eq i32 %t56, %t62
  %t64 = select i1 %t63, i32 1, i32 %t60
  %t65 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t66 = load i32, i32* %t65
  %t67 = icmp eq i32 %t56, %t66
  %t68 = select i1 %t67, i32 2, i32 %t64
  %t69 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t70 = load i32, i32* %t69
  %t71 = icmp eq i32 %t56, %t70
  %t72 = select i1 %t71, i32 3, i32 %t68
  %t73 = icmp sge i32 %t72, 0
  br i1 %t73, label %par_serial_7, label %par_pooled_6
par_pooled_6:
  %t74 = load i64, i64* @arena.Enemies.count
  %t75 = mul i64 %t74, 0
  %t76 = sdiv i64 %t75, 4
  %t77 = mul i64 %t74, 1
  %t78 = sdiv i64 %t77, 4
  %t80 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t79, i32 0, i32 0
  store i64 %t76, i64* %t80
  %t81 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t79, i32 0, i32 1
  store i64 %t78, i64* %t81
  %t82 = bitcast { i64, i64 }* %t79 to i8*
  %t83 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t82, i8** %t83
  %t84 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t84
  %t85 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t86 = load i8*, i8** %t85
  %t87 = call i32 @ReleaseSemaphore(i8* %t86, i32 1, i32* null)
  %t88 = mul i64 %t74, 1
  %t89 = sdiv i64 %t88, 4
  %t90 = mul i64 %t74, 2
  %t91 = sdiv i64 %t90, 4
  %t93 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t92, i32 0, i32 0
  store i64 %t89, i64* %t93
  %t94 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t92, i32 0, i32 1
  store i64 %t91, i64* %t94
  %t95 = bitcast { i64, i64 }* %t92 to i8*
  %t96 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t95, i8** %t96
  %t97 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t97
  %t98 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t99 = load i8*, i8** %t98
  %t100 = call i32 @ReleaseSemaphore(i8* %t99, i32 1, i32* null)
  %t101 = mul i64 %t74, 2
  %t102 = sdiv i64 %t101, 4
  %t103 = mul i64 %t74, 3
  %t104 = sdiv i64 %t103, 4
  %t106 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t105, i32 0, i32 0
  store i64 %t102, i64* %t106
  %t107 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t105, i32 0, i32 1
  store i64 %t104, i64* %t107
  %t108 = bitcast { i64, i64 }* %t105 to i8*
  %t109 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t108, i8** %t109
  %t110 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t110
  %t111 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t112 = load i8*, i8** %t111
  %t113 = call i32 @ReleaseSemaphore(i8* %t112, i32 1, i32* null)
  %t114 = mul i64 %t74, 3
  %t115 = sdiv i64 %t114, 4
  %t116 = mul i64 %t74, 4
  %t117 = sdiv i64 %t116, 4
  %t119 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t118, i32 0, i32 0
  store i64 %t115, i64* %t119
  %t120 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t118, i32 0, i32 1
  store i64 %t117, i64* %t120
  %t121 = bitcast { i64, i64 }* %t118 to i8*
  %t122 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t121, i8** %t122
  %t123 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t123
  %t124 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t125 = load i8*, i8** %t124
  %t126 = call i32 @ReleaseSemaphore(i8* %t125, i32 1, i32* null)
  %t127 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t128 = load i8*, i8** %t127
  %t129 = call i32 @WaitForSingleObject(i8* %t128, i32 -1)
  %t130 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t131 = load i8*, i8** %t130
  %t132 = call i32 @WaitForSingleObject(i8* %t131, i32 -1)
  %t133 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t134 = load i8*, i8** %t133
  %t135 = call i32 @WaitForSingleObject(i8* %t134, i32 -1)
  %t136 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t137 = load i8*, i8** %t136
  %t138 = call i32 @WaitForSingleObject(i8* %t137, i32 -1)
  br label %par_join_11
par_serial_7:
  %t139 = load i32, i32* @par.pool.serial_owner
  %t140 = icmp eq i32 %t139, %t72
  br i1 %t140, label %par_run_9, label %par_acquire_8
par_acquire_8:
  %t141 = load i8*, i8** @par.pool.serial_lock
  %t142 = call i32 @WaitForSingleObject(i8* %t141, i32 -1)
  store i32 %t72, i32* @par.pool.serial_owner
  br label %par_run_9
par_run_9:
  %t143 = load i64, i64* @arena.Enemies.count
  %t145 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t144, i32 0, i32 0
  store i64 0, i64* %t145
  %t146 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t144, i32 0, i32 1
  store i64 %t143, i64* %t146
  %t147 = bitcast { i64, i64 }* %t144 to i8*
  %t148 = call i32 @par_worker_0(i8* %t147)
  br i1 %t140, label %par_join_11, label %par_release_10
par_release_10:
  store i32 -1, i32* @par.pool.serial_owner
  %t149 = load i8*, i8** @par.pool.serial_lock
  %t150 = call i32 @ReleaseSemaphore(i8* %t149, i32 1, i32* null)
  br label %par_join_11
par_join_11:
  call void @par.pool.ensure_init()
  %t167 = call i32 @GetCurrentThreadId()
  %t168 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t169 = load i32, i32* %t168
  %t170 = icmp eq i32 %t167, %t169
  %t171 = select i1 %t170, i32 0, i32 -1
  %t172 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t173 = load i32, i32* %t172
  %t174 = icmp eq i32 %t167, %t173
  %t175 = select i1 %t174, i32 1, i32 %t171
  %t176 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t177 = load i32, i32* %t176
  %t178 = icmp eq i32 %t167, %t177
  %t179 = select i1 %t178, i32 2, i32 %t175
  %t180 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t181 = load i32, i32* %t180
  %t182 = icmp eq i32 %t167, %t181
  %t183 = select i1 %t182, i32 3, i32 %t179
  %t184 = icmp sge i32 %t183, 0
  br i1 %t184, label %par_serial_19, label %par_pooled_18
par_pooled_18:
  %t185 = load i64, i64* @arena.Enemies.count
  %t186 = mul i64 %t185, 0
  %t187 = sdiv i64 %t186, 4
  %t188 = mul i64 %t185, 1
  %t189 = sdiv i64 %t188, 4
  %t191 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t190, i32 0, i32 0
  store i64 %t187, i64* %t191
  %t192 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t190, i32 0, i32 1
  store i64 %t189, i64* %t192
  %t193 = bitcast { i64, i64 }* %t190 to i8*
  %t194 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t193, i8** %t194
  %t195 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_12, i32 (i8*)** %t195
  %t196 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t197 = load i8*, i8** %t196
  %t198 = call i32 @ReleaseSemaphore(i8* %t197, i32 1, i32* null)
  %t199 = mul i64 %t185, 1
  %t200 = sdiv i64 %t199, 4
  %t201 = mul i64 %t185, 2
  %t202 = sdiv i64 %t201, 4
  %t204 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t203, i32 0, i32 0
  store i64 %t200, i64* %t204
  %t205 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t203, i32 0, i32 1
  store i64 %t202, i64* %t205
  %t206 = bitcast { i64, i64 }* %t203 to i8*
  %t207 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t206, i8** %t207
  %t208 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_12, i32 (i8*)** %t208
  %t209 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t210 = load i8*, i8** %t209
  %t211 = call i32 @ReleaseSemaphore(i8* %t210, i32 1, i32* null)
  %t212 = mul i64 %t185, 2
  %t213 = sdiv i64 %t212, 4
  %t214 = mul i64 %t185, 3
  %t215 = sdiv i64 %t214, 4
  %t217 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t216, i32 0, i32 0
  store i64 %t213, i64* %t217
  %t218 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t216, i32 0, i32 1
  store i64 %t215, i64* %t218
  %t219 = bitcast { i64, i64 }* %t216 to i8*
  %t220 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t219, i8** %t220
  %t221 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_12, i32 (i8*)** %t221
  %t222 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t223 = load i8*, i8** %t222
  %t224 = call i32 @ReleaseSemaphore(i8* %t223, i32 1, i32* null)
  %t225 = mul i64 %t185, 3
  %t226 = sdiv i64 %t225, 4
  %t227 = mul i64 %t185, 4
  %t228 = sdiv i64 %t227, 4
  %t230 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t229, i32 0, i32 0
  store i64 %t226, i64* %t230
  %t231 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t229, i32 0, i32 1
  store i64 %t228, i64* %t231
  %t232 = bitcast { i64, i64 }* %t229 to i8*
  %t233 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t232, i8** %t233
  %t234 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_12, i32 (i8*)** %t234
  %t235 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t236 = load i8*, i8** %t235
  %t237 = call i32 @ReleaseSemaphore(i8* %t236, i32 1, i32* null)
  %t238 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t239 = load i8*, i8** %t238
  %t240 = call i32 @WaitForSingleObject(i8* %t239, i32 -1)
  %t241 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t242 = load i8*, i8** %t241
  %t243 = call i32 @WaitForSingleObject(i8* %t242, i32 -1)
  %t244 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t245 = load i8*, i8** %t244
  %t246 = call i32 @WaitForSingleObject(i8* %t245, i32 -1)
  %t247 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t248 = load i8*, i8** %t247
  %t249 = call i32 @WaitForSingleObject(i8* %t248, i32 -1)
  br label %par_join_23
par_serial_19:
  %t250 = load i32, i32* @par.pool.serial_owner
  %t251 = icmp eq i32 %t250, %t183
  br i1 %t251, label %par_run_21, label %par_acquire_20
par_acquire_20:
  %t252 = load i8*, i8** @par.pool.serial_lock
  %t253 = call i32 @WaitForSingleObject(i8* %t252, i32 -1)
  store i32 %t183, i32* @par.pool.serial_owner
  br label %par_run_21
par_run_21:
  %t254 = load i64, i64* @arena.Enemies.count
  %t256 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t255, i32 0, i32 0
  store i64 0, i64* %t256
  %t257 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t255, i32 0, i32 1
  store i64 %t254, i64* %t257
  %t258 = bitcast { i64, i64 }* %t255 to i8*
  %t259 = call i32 @par_worker_12(i8* %t258)
  br i1 %t251, label %par_join_23, label %par_release_22
par_release_22:
  store i32 -1, i32* @par.pool.serial_owner
  %t260 = load i8*, i8** @par.pool.serial_lock
  %t261 = call i32 @ReleaseSemaphore(i8* %t260, i32 1, i32* null)
  br label %par_join_23
par_join_23:
  %t262 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t262)
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_0(i8* %argp) {
entry:
  %t6 = alloca i64
  %t0 = bitcast i8* %argp to { i64, i64 }*
  %t1 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t0, i32 0, i32 0
  %t2 = load i64, i64* %t1
  %t3 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t0, i32 0, i32 1
  %t4 = load i64, i64* %t3
  %t5 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t2, i64* %t6
  br label %par_cond_1
par_cond_1:
  %t7 = load i64, i64* %t6
  %t8 = icmp slt i64 %t7, %t4
  br i1 %t8, label %par_body_2, label %par_end_5
par_body_2:
  %t9 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t7
  %t10 = load i32, i32* %t9
  %t11 = and i32 %t10, 1
  %t12 = icmp eq i32 %t11, 1
  br i1 %t12, label %par_live_3, label %par_incr_4
par_live_3:
  %t13 = getelementptr inbounds %Enemy, %Enemy* %t5, i64 %t7
  %t14 = getelementptr inbounds %Enemy, %Enemy* %t13, i32 0, i32 0
  %t15 = load i32, i32* %t14
  %t16 = sub i32 %t15, 1
  %t17 = getelementptr inbounds %Enemy, %Enemy* %t13, i32 0, i32 0
  store i32 %t16, i32* %t17
  br label %par_incr_4
par_incr_4:
  %t18 = add i64 %t7, 1
  store i64 %t18, i64* %t6
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
  %t19 = ptrtoint i8* %idx_arg to i64
  %t20 = trunc i64 %t19 to i32
  %t21 = call i32 @GetCurrentThreadId()
  %t22 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t20
  store i32 %t21, i32* %t22
  br label %loop
loop:
  %t23 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t20
  %t24 = load i8*, i8** %t23
  %t25 = call i32 @WaitForSingleObject(i8* %t24, i32 -1)
  %t26 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t20
  %t27 = load i32 (i8*)*, i32 (i8*)** %t26
  %t28 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t20
  %t29 = load i8*, i8** %t28
  %t30 = call i32 %t27(i8* %t29)
  %t31 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t20
  %t32 = load i8*, i8** %t31
  %t33 = call i32 @ReleaseSemaphore(i8* %t32, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t34 = load i1, i1* @par.pool.inited
  br i1 %t34, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t35 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t35, i8** @par.pool.serial_lock
  %t36 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t37 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t36, i8** %t37
  %t38 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t39 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t38, i8** %t39
  %t40 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t41 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t42 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t41, i8** %t42
  %t43 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t44 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t43, i8** %t44
  %t45 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t46 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t47 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t46, i8** %t47
  %t48 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t49 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t48, i8** %t49
  %t50 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t51 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t52 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t51, i8** %t52
  %t53 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t54 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t53, i8** %t54
  %t55 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_12(i8* %argp) {
entry:
  %t157 = alloca i64
  %t151 = bitcast i8* %argp to { i64, i64 }*
  %t152 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t151, i32 0, i32 0
  %t153 = load i64, i64* %t152
  %t154 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t151, i32 0, i32 1
  %t155 = load i64, i64* %t154
  %t156 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t153, i64* %t157
  br label %par_cond_13
par_cond_13:
  %t158 = load i64, i64* %t157
  %t159 = icmp slt i64 %t158, %t155
  br i1 %t159, label %par_body_14, label %par_end_17
par_body_14:
  %t160 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t158
  %t161 = load i32, i32* %t160
  %t162 = and i32 %t161, 1
  %t163 = icmp eq i32 %t162, 1
  br i1 %t163, label %par_live_15, label %par_incr_16
par_live_15:
  %t164 = getelementptr inbounds %Enemy, %Enemy* %t156, i64 %t158
  %t165 = getelementptr inbounds %Enemy, %Enemy* %t164, i32 0, i32 0
  store i32 0, i32* %t165
  br label %par_incr_16
par_incr_16:
  %t166 = add i64 %t158, 1
  store i64 %t166, i64* %t157
  br label %par_cond_13
par_end_17:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [12 x i8] c"swarm done\0A\00"
