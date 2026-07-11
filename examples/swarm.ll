; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
declare i32 @puts(i8*)
declare noalias i8* @malloc(i64)
declare void @free(i8*)
declare void @exit(i32) noreturn
declare i32 @strlen(i8*)
declare i8* @memcpy(i8*, i8*, i64)
declare i8* @strcpy(i8*, i8*)
declare i8* @strcat(i8*, i8*)
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

%GenRef = type { i32, i32 }

@frame.buf = global [4096 x i8] zeroinitializer
@frame.off = global i64 0

@rng.state = global i32 123456789

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

define i32 @main() {
entry:
  call void @par.pool.ensure_init()
  %t52 = call i32 @GetCurrentThreadId()
  %t53 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t54 = load i32, i32* %t53
  %t55 = icmp eq i32 %t52, %t54
  %t56 = select i1 %t55, i32 0, i32 -1
  %t57 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t58 = load i32, i32* %t57
  %t59 = icmp eq i32 %t52, %t58
  %t60 = select i1 %t59, i32 1, i32 %t56
  %t61 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t62 = load i32, i32* %t61
  %t63 = icmp eq i32 %t52, %t62
  %t64 = select i1 %t63, i32 2, i32 %t60
  %t65 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t66 = load i32, i32* %t65
  %t67 = icmp eq i32 %t52, %t66
  %t68 = select i1 %t67, i32 3, i32 %t64
  %t69 = icmp sge i32 %t68, 0
  br i1 %t69, label %par_serial_5, label %par_pooled_4
par_pooled_4:
  %t70 = load i64, i64* @arena.Enemies.count
  %t71 = mul i64 %t70, 0
  %t72 = sdiv i64 %t71, 4
  %t73 = mul i64 %t70, 1
  %t74 = sdiv i64 %t73, 4
  %t75 = alloca { i64, i64 }
  %t76 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t75, i32 0, i32 0
  store i64 %t72, i64* %t76
  %t77 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t75, i32 0, i32 1
  store i64 %t74, i64* %t77
  %t78 = bitcast { i64, i64 }* %t75 to i8*
  %t79 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t78, i8** %t79
  %t80 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t80
  %t81 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t82 = load i8*, i8** %t81
  %t83 = call i32 @ReleaseSemaphore(i8* %t82, i32 1, i32* null)
  %t84 = mul i64 %t70, 1
  %t85 = sdiv i64 %t84, 4
  %t86 = mul i64 %t70, 2
  %t87 = sdiv i64 %t86, 4
  %t88 = alloca { i64, i64 }
  %t89 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t88, i32 0, i32 0
  store i64 %t85, i64* %t89
  %t90 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t88, i32 0, i32 1
  store i64 %t87, i64* %t90
  %t91 = bitcast { i64, i64 }* %t88 to i8*
  %t92 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t91, i8** %t92
  %t93 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t93
  %t94 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t95 = load i8*, i8** %t94
  %t96 = call i32 @ReleaseSemaphore(i8* %t95, i32 1, i32* null)
  %t97 = mul i64 %t70, 2
  %t98 = sdiv i64 %t97, 4
  %t99 = mul i64 %t70, 3
  %t100 = sdiv i64 %t99, 4
  %t101 = alloca { i64, i64 }
  %t102 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t101, i32 0, i32 0
  store i64 %t98, i64* %t102
  %t103 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t101, i32 0, i32 1
  store i64 %t100, i64* %t103
  %t104 = bitcast { i64, i64 }* %t101 to i8*
  %t105 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t104, i8** %t105
  %t106 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t106
  %t107 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t108 = load i8*, i8** %t107
  %t109 = call i32 @ReleaseSemaphore(i8* %t108, i32 1, i32* null)
  %t110 = mul i64 %t70, 3
  %t111 = sdiv i64 %t110, 4
  %t112 = mul i64 %t70, 4
  %t113 = sdiv i64 %t112, 4
  %t114 = alloca { i64, i64 }
  %t115 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t114, i32 0, i32 0
  store i64 %t111, i64* %t115
  %t116 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t114, i32 0, i32 1
  store i64 %t113, i64* %t116
  %t117 = bitcast { i64, i64 }* %t114 to i8*
  %t118 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t117, i8** %t118
  %t119 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t119
  %t120 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t121 = load i8*, i8** %t120
  %t122 = call i32 @ReleaseSemaphore(i8* %t121, i32 1, i32* null)
  %t123 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t124 = load i8*, i8** %t123
  %t125 = call i32 @WaitForSingleObject(i8* %t124, i32 -1)
  %t126 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t127 = load i8*, i8** %t126
  %t128 = call i32 @WaitForSingleObject(i8* %t127, i32 -1)
  %t129 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t130 = load i8*, i8** %t129
  %t131 = call i32 @WaitForSingleObject(i8* %t130, i32 -1)
  %t132 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t133 = load i8*, i8** %t132
  %t134 = call i32 @WaitForSingleObject(i8* %t133, i32 -1)
  br label %par_join_9
par_serial_5:
  %t135 = load i32, i32* @par.pool.serial_owner
  %t136 = icmp eq i32 %t135, %t68
  br i1 %t136, label %par_run_7, label %par_acquire_6
par_acquire_6:
  %t137 = load i8*, i8** @par.pool.serial_lock
  %t138 = call i32 @WaitForSingleObject(i8* %t137, i32 -1)
  store i32 %t68, i32* @par.pool.serial_owner
  br label %par_run_7
par_run_7:
  %t139 = load i64, i64* @arena.Enemies.count
  %t140 = alloca { i64, i64 }
  %t141 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t140, i32 0, i32 0
  store i64 0, i64* %t141
  %t142 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t140, i32 0, i32 1
  store i64 %t139, i64* %t142
  %t143 = bitcast { i64, i64 }* %t140 to i8*
  %t144 = call i32 @par_worker_0(i8* %t143)
  br i1 %t136, label %par_join_9, label %par_release_8
par_release_8:
  store i32 -1, i32* @par.pool.serial_owner
  %t145 = load i8*, i8** @par.pool.serial_lock
  %t146 = call i32 @ReleaseSemaphore(i8* %t145, i32 1, i32* null)
  br label %par_join_9
par_join_9:
  call void @par.pool.ensure_init()
  %t159 = call i32 @GetCurrentThreadId()
  %t160 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t161 = load i32, i32* %t160
  %t162 = icmp eq i32 %t159, %t161
  %t163 = select i1 %t162, i32 0, i32 -1
  %t164 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t165 = load i32, i32* %t164
  %t166 = icmp eq i32 %t159, %t165
  %t167 = select i1 %t166, i32 1, i32 %t163
  %t168 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t169 = load i32, i32* %t168
  %t170 = icmp eq i32 %t159, %t169
  %t171 = select i1 %t170, i32 2, i32 %t167
  %t172 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t173 = load i32, i32* %t172
  %t174 = icmp eq i32 %t159, %t173
  %t175 = select i1 %t174, i32 3, i32 %t171
  %t176 = icmp sge i32 %t175, 0
  br i1 %t176, label %par_serial_15, label %par_pooled_14
par_pooled_14:
  %t177 = load i64, i64* @arena.Enemies.count
  %t178 = mul i64 %t177, 0
  %t179 = sdiv i64 %t178, 4
  %t180 = mul i64 %t177, 1
  %t181 = sdiv i64 %t180, 4
  %t182 = alloca { i64, i64 }
  %t183 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t182, i32 0, i32 0
  store i64 %t179, i64* %t183
  %t184 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t182, i32 0, i32 1
  store i64 %t181, i64* %t184
  %t185 = bitcast { i64, i64 }* %t182 to i8*
  %t186 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t185, i8** %t186
  %t187 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_10, i32 (i8*)** %t187
  %t188 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t189 = load i8*, i8** %t188
  %t190 = call i32 @ReleaseSemaphore(i8* %t189, i32 1, i32* null)
  %t191 = mul i64 %t177, 1
  %t192 = sdiv i64 %t191, 4
  %t193 = mul i64 %t177, 2
  %t194 = sdiv i64 %t193, 4
  %t195 = alloca { i64, i64 }
  %t196 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t195, i32 0, i32 0
  store i64 %t192, i64* %t196
  %t197 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t195, i32 0, i32 1
  store i64 %t194, i64* %t197
  %t198 = bitcast { i64, i64 }* %t195 to i8*
  %t199 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t198, i8** %t199
  %t200 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_10, i32 (i8*)** %t200
  %t201 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t202 = load i8*, i8** %t201
  %t203 = call i32 @ReleaseSemaphore(i8* %t202, i32 1, i32* null)
  %t204 = mul i64 %t177, 2
  %t205 = sdiv i64 %t204, 4
  %t206 = mul i64 %t177, 3
  %t207 = sdiv i64 %t206, 4
  %t208 = alloca { i64, i64 }
  %t209 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t208, i32 0, i32 0
  store i64 %t205, i64* %t209
  %t210 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t208, i32 0, i32 1
  store i64 %t207, i64* %t210
  %t211 = bitcast { i64, i64 }* %t208 to i8*
  %t212 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t211, i8** %t212
  %t213 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_10, i32 (i8*)** %t213
  %t214 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t215 = load i8*, i8** %t214
  %t216 = call i32 @ReleaseSemaphore(i8* %t215, i32 1, i32* null)
  %t217 = mul i64 %t177, 3
  %t218 = sdiv i64 %t217, 4
  %t219 = mul i64 %t177, 4
  %t220 = sdiv i64 %t219, 4
  %t221 = alloca { i64, i64 }
  %t222 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t221, i32 0, i32 0
  store i64 %t218, i64* %t222
  %t223 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t221, i32 0, i32 1
  store i64 %t220, i64* %t223
  %t224 = bitcast { i64, i64 }* %t221 to i8*
  %t225 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t224, i8** %t225
  %t226 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_10, i32 (i8*)** %t226
  %t227 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t228 = load i8*, i8** %t227
  %t229 = call i32 @ReleaseSemaphore(i8* %t228, i32 1, i32* null)
  %t230 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t231 = load i8*, i8** %t230
  %t232 = call i32 @WaitForSingleObject(i8* %t231, i32 -1)
  %t233 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t234 = load i8*, i8** %t233
  %t235 = call i32 @WaitForSingleObject(i8* %t234, i32 -1)
  %t236 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t237 = load i8*, i8** %t236
  %t238 = call i32 @WaitForSingleObject(i8* %t237, i32 -1)
  %t239 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t240 = load i8*, i8** %t239
  %t241 = call i32 @WaitForSingleObject(i8* %t240, i32 -1)
  br label %par_join_19
par_serial_15:
  %t242 = load i32, i32* @par.pool.serial_owner
  %t243 = icmp eq i32 %t242, %t175
  br i1 %t243, label %par_run_17, label %par_acquire_16
par_acquire_16:
  %t244 = load i8*, i8** @par.pool.serial_lock
  %t245 = call i32 @WaitForSingleObject(i8* %t244, i32 -1)
  store i32 %t175, i32* @par.pool.serial_owner
  br label %par_run_17
par_run_17:
  %t246 = load i64, i64* @arena.Enemies.count
  %t247 = alloca { i64, i64 }
  %t248 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t247, i32 0, i32 0
  store i64 0, i64* %t248
  %t249 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t247, i32 0, i32 1
  store i64 %t246, i64* %t249
  %t250 = bitcast { i64, i64 }* %t247 to i8*
  %t251 = call i32 @par_worker_10(i8* %t250)
  br i1 %t243, label %par_join_19, label %par_release_18
par_release_18:
  store i32 -1, i32* @par.pool.serial_owner
  %t252 = load i8*, i8** @par.pool.serial_lock
  %t253 = call i32 @ReleaseSemaphore(i8* %t252, i32 1, i32* null)
  br label %par_join_19
par_join_19:
  %t254 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t254)
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_0(i8* %argp) {
entry:
  %t0 = bitcast i8* %argp to { i64, i64 }*
  %t1 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t0, i32 0, i32 0
  %t2 = load i64, i64* %t1
  %t3 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t0, i32 0, i32 1
  %t4 = load i64, i64* %t3
  %t5 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t6 = alloca i64
  store i64 %t2, i64* %t6
  br label %par_cond_1
par_cond_1:
  %t7 = load i64, i64* %t6
  %t8 = icmp slt i64 %t7, %t4
  br i1 %t8, label %par_body_2, label %par_end_3
par_body_2:
  %t9 = getelementptr inbounds %Enemy, %Enemy* %t5, i64 %t7
  %t10 = getelementptr inbounds %Enemy, %Enemy* %t9, i32 0, i32 0
  %t11 = load i32, i32* %t10
  %t12 = sub i32 %t11, 1
  %t13 = getelementptr inbounds %Enemy, %Enemy* %t9, i32 0, i32 0
  store i32 %t12, i32* %t13
  %t14 = add i64 %t7, 1
  store i64 %t14, i64* %t6
  br label %par_cond_1
par_end_3:
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
  %t15 = ptrtoint i8* %idx_arg to i64
  %t16 = trunc i64 %t15 to i32
  %t17 = call i32 @GetCurrentThreadId()
  %t18 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t16
  store i32 %t17, i32* %t18
  br label %loop
loop:
  %t19 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t16
  %t20 = load i8*, i8** %t19
  %t21 = call i32 @WaitForSingleObject(i8* %t20, i32 -1)
  %t22 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t16
  %t23 = load i32 (i8*)*, i32 (i8*)** %t22
  %t24 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t16
  %t25 = load i8*, i8** %t24
  %t26 = call i32 %t23(i8* %t25)
  %t27 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t16
  %t28 = load i8*, i8** %t27
  %t29 = call i32 @ReleaseSemaphore(i8* %t28, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t30 = load i1, i1* @par.pool.inited
  br i1 %t30, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t31 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t31, i8** @par.pool.serial_lock
  %t32 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t33 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t32, i8** %t33
  %t34 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t35 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t34, i8** %t35
  %t36 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t37 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t38 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t37, i8** %t38
  %t39 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t40 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t39, i8** %t40
  %t41 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t42 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t43 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t42, i8** %t43
  %t44 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t45 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t44, i8** %t45
  %t46 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t47 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t48 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t47, i8** %t48
  %t49 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t50 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t49, i8** %t50
  %t51 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_10(i8* %argp) {
entry:
  %t147 = bitcast i8* %argp to { i64, i64 }*
  %t148 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t147, i32 0, i32 0
  %t149 = load i64, i64* %t148
  %t150 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t147, i32 0, i32 1
  %t151 = load i64, i64* %t150
  %t152 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t153 = alloca i64
  store i64 %t149, i64* %t153
  br label %par_cond_11
par_cond_11:
  %t154 = load i64, i64* %t153
  %t155 = icmp slt i64 %t154, %t151
  br i1 %t155, label %par_body_12, label %par_end_13
par_body_12:
  %t156 = getelementptr inbounds %Enemy, %Enemy* %t152, i64 %t154
  %t157 = getelementptr inbounds %Enemy, %Enemy* %t156, i32 0, i32 0
  store i32 0, i32* %t157
  %t158 = add i64 %t154, 1
  store i64 %t158, i64* %t153
  br label %par_cond_11
par_end_13:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [12 x i8] c"swarm done\0A\00"
