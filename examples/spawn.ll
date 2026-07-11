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
  %rc = load i64, i64* %hdr
  %is_immortal = icmp eq i64 %rc, -1
  br i1 %is_immortal, label %done, label %incr
incr:
  %rc1 = add i64 %rc, 1
  store i64 %rc1, i64* %hdr
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
  %rc = load i64, i64* %hdr
  %is_immortal = icmp eq i64 %rc, -1
  br i1 %is_immortal, label %done, label %decr
decr:
  %rc1 = sub i64 %rc, 1
  store i64 %rc1, i64* %hdr
  %iszero = icmp eq i64 %rc1, 0
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
  %t0 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t1 = icmp eq %Enemy* %t0, null
  br i1 %t1, label %spawn_init_0, label %spawn_ready_1
spawn_init_0:
  %t2 = call i8* @malloc(i64 4096)
  %t3 = bitcast i8* %t2 to %Enemy*
  store %Enemy* %t3, %Enemy** @arena.Enemies.data
  br label %spawn_ready_1
spawn_ready_1:
  %t4 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t5 = load i64, i64* @arena.Enemies.free_top
  %t6 = icmp sgt i64 %t5, 0
  br i1 %t6, label %spawn_reuse_2, label %spawn_grow_3
spawn_reuse_2:
  %t7 = sub i64 %t5, 1
  store i64 %t7, i64* @arena.Enemies.free_top
  %t8 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t7
  %t9 = load i64, i64* %t8
  br label %spawn_store_4
spawn_grow_3:
  %t10 = load i64, i64* @arena.Enemies.count
  %t11 = icmp slt i64 %t10, 1024
  br i1 %t11, label %spawn_grow_ok_6, label %spawn_capacity_warn_7
spawn_capacity_warn_7:
  %t12 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t12)
  br label %spawn_end_5
spawn_grow_ok_6:
  %t13 = add i64 %t10, 1
  store i64 %t13, i64* @arena.Enemies.count
  br label %spawn_store_4
spawn_store_4:
  %t14 = phi i64 [ %t9, %spawn_reuse_2 ], [ %t10, %spawn_grow_ok_6 ]
  %t15 = alloca %Enemy
  %t16 = getelementptr inbounds %Enemy, %Enemy* %t15, i32 0, i32 0
  store i32 10, i32* %t16
  %t17 = load %Enemy, %Enemy* %t15
  %t18 = getelementptr inbounds %Enemy, %Enemy* %t4, i64 %t14
  store %Enemy %t17, %Enemy* %t18
  %t19 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t14
  %t20 = load i32, i32* %t19
  %t21 = add i32 %t20, 1
  store i32 %t21, i32* %t19
  br label %spawn_end_5
spawn_end_5:
  %t22 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t23 = icmp eq %Enemy* %t22, null
  br i1 %t23, label %spawn_init_8, label %spawn_ready_9
spawn_init_8:
  %t24 = call i8* @malloc(i64 4096)
  %t25 = bitcast i8* %t24 to %Enemy*
  store %Enemy* %t25, %Enemy** @arena.Enemies.data
  br label %spawn_ready_9
spawn_ready_9:
  %t26 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t27 = load i64, i64* @arena.Enemies.free_top
  %t28 = icmp sgt i64 %t27, 0
  br i1 %t28, label %spawn_reuse_10, label %spawn_grow_11
spawn_reuse_10:
  %t29 = sub i64 %t27, 1
  store i64 %t29, i64* @arena.Enemies.free_top
  %t30 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t29
  %t31 = load i64, i64* %t30
  br label %spawn_store_12
spawn_grow_11:
  %t32 = load i64, i64* @arena.Enemies.count
  %t33 = icmp slt i64 %t32, 1024
  br i1 %t33, label %spawn_grow_ok_14, label %spawn_capacity_warn_15
spawn_capacity_warn_15:
  %t34 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t34)
  br label %spawn_end_13
spawn_grow_ok_14:
  %t35 = add i64 %t32, 1
  store i64 %t35, i64* @arena.Enemies.count
  br label %spawn_store_12
spawn_store_12:
  %t36 = phi i64 [ %t31, %spawn_reuse_10 ], [ %t32, %spawn_grow_ok_14 ]
  %t37 = alloca %Enemy
  %t38 = getelementptr inbounds %Enemy, %Enemy* %t37, i32 0, i32 0
  store i32 20, i32* %t38
  %t39 = load %Enemy, %Enemy* %t37
  %t40 = getelementptr inbounds %Enemy, %Enemy* %t26, i64 %t36
  store %Enemy %t39, %Enemy* %t40
  %t41 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t36
  %t42 = load i32, i32* %t41
  %t43 = add i32 %t42, 1
  store i32 %t43, i32* %t41
  br label %spawn_end_13
spawn_end_13:
  %t44 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t45 = icmp eq %Enemy* %t44, null
  br i1 %t45, label %spawn_init_16, label %spawn_ready_17
spawn_init_16:
  %t46 = call i8* @malloc(i64 4096)
  %t47 = bitcast i8* %t46 to %Enemy*
  store %Enemy* %t47, %Enemy** @arena.Enemies.data
  br label %spawn_ready_17
spawn_ready_17:
  %t48 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t49 = load i64, i64* @arena.Enemies.free_top
  %t50 = icmp sgt i64 %t49, 0
  br i1 %t50, label %spawn_reuse_18, label %spawn_grow_19
spawn_reuse_18:
  %t51 = sub i64 %t49, 1
  store i64 %t51, i64* @arena.Enemies.free_top
  %t52 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t51
  %t53 = load i64, i64* %t52
  br label %spawn_store_20
spawn_grow_19:
  %t54 = load i64, i64* @arena.Enemies.count
  %t55 = icmp slt i64 %t54, 1024
  br i1 %t55, label %spawn_grow_ok_22, label %spawn_capacity_warn_23
spawn_capacity_warn_23:
  %t56 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t56)
  br label %spawn_end_21
spawn_grow_ok_22:
  %t57 = add i64 %t54, 1
  store i64 %t57, i64* @arena.Enemies.count
  br label %spawn_store_20
spawn_store_20:
  %t58 = phi i64 [ %t53, %spawn_reuse_18 ], [ %t54, %spawn_grow_ok_22 ]
  %t59 = alloca %Enemy
  %t60 = getelementptr inbounds %Enemy, %Enemy* %t59, i32 0, i32 0
  store i32 30, i32* %t60
  %t61 = load %Enemy, %Enemy* %t59
  %t62 = getelementptr inbounds %Enemy, %Enemy* %t48, i64 %t58
  store %Enemy %t61, %Enemy* %t62
  %t63 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t58
  %t64 = load i32, i32* %t63
  %t65 = add i32 %t64, 1
  store i32 %t65, i32* %t63
  br label %spawn_end_21
spawn_end_21:
  call void @par.pool.ensure_init()
  %t118 = call i32 @GetCurrentThreadId()
  %t119 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t120 = load i32, i32* %t119
  %t121 = icmp eq i32 %t118, %t120
  %t122 = select i1 %t121, i32 0, i32 -1
  %t123 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t124 = load i32, i32* %t123
  %t125 = icmp eq i32 %t118, %t124
  %t126 = select i1 %t125, i32 1, i32 %t122
  %t127 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t128 = load i32, i32* %t127
  %t129 = icmp eq i32 %t118, %t128
  %t130 = select i1 %t129, i32 2, i32 %t126
  %t131 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t132 = load i32, i32* %t131
  %t133 = icmp eq i32 %t118, %t132
  %t134 = select i1 %t133, i32 3, i32 %t130
  %t135 = icmp sge i32 %t134, 0
  br i1 %t135, label %par_serial_29, label %par_pooled_28
par_pooled_28:
  %t136 = load i64, i64* @arena.Enemies.count
  %t137 = mul i64 %t136, 0
  %t138 = sdiv i64 %t137, 4
  %t139 = mul i64 %t136, 1
  %t140 = sdiv i64 %t139, 4
  %t141 = alloca { i64, i64 }
  %t142 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t141, i32 0, i32 0
  store i64 %t138, i64* %t142
  %t143 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t141, i32 0, i32 1
  store i64 %t140, i64* %t143
  %t144 = bitcast { i64, i64 }* %t141 to i8*
  %t145 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t144, i8** %t145
  %t146 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t146
  %t147 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t148 = load i8*, i8** %t147
  %t149 = call i32 @ReleaseSemaphore(i8* %t148, i32 1, i32* null)
  %t150 = mul i64 %t136, 1
  %t151 = sdiv i64 %t150, 4
  %t152 = mul i64 %t136, 2
  %t153 = sdiv i64 %t152, 4
  %t154 = alloca { i64, i64 }
  %t155 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t154, i32 0, i32 0
  store i64 %t151, i64* %t155
  %t156 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t154, i32 0, i32 1
  store i64 %t153, i64* %t156
  %t157 = bitcast { i64, i64 }* %t154 to i8*
  %t158 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t157, i8** %t158
  %t159 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t159
  %t160 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t161 = load i8*, i8** %t160
  %t162 = call i32 @ReleaseSemaphore(i8* %t161, i32 1, i32* null)
  %t163 = mul i64 %t136, 2
  %t164 = sdiv i64 %t163, 4
  %t165 = mul i64 %t136, 3
  %t166 = sdiv i64 %t165, 4
  %t167 = alloca { i64, i64 }
  %t168 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t167, i32 0, i32 0
  store i64 %t164, i64* %t168
  %t169 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t167, i32 0, i32 1
  store i64 %t166, i64* %t169
  %t170 = bitcast { i64, i64 }* %t167 to i8*
  %t171 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t170, i8** %t171
  %t172 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t172
  %t173 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t174 = load i8*, i8** %t173
  %t175 = call i32 @ReleaseSemaphore(i8* %t174, i32 1, i32* null)
  %t176 = mul i64 %t136, 3
  %t177 = sdiv i64 %t176, 4
  %t178 = mul i64 %t136, 4
  %t179 = sdiv i64 %t178, 4
  %t180 = alloca { i64, i64 }
  %t181 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t180, i32 0, i32 0
  store i64 %t177, i64* %t181
  %t182 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t180, i32 0, i32 1
  store i64 %t179, i64* %t182
  %t183 = bitcast { i64, i64 }* %t180 to i8*
  %t184 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t183, i8** %t184
  %t185 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t185
  %t186 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t187 = load i8*, i8** %t186
  %t188 = call i32 @ReleaseSemaphore(i8* %t187, i32 1, i32* null)
  %t189 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t190 = load i8*, i8** %t189
  %t191 = call i32 @WaitForSingleObject(i8* %t190, i32 -1)
  %t192 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t193 = load i8*, i8** %t192
  %t194 = call i32 @WaitForSingleObject(i8* %t193, i32 -1)
  %t195 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t196 = load i8*, i8** %t195
  %t197 = call i32 @WaitForSingleObject(i8* %t196, i32 -1)
  %t198 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t199 = load i8*, i8** %t198
  %t200 = call i32 @WaitForSingleObject(i8* %t199, i32 -1)
  br label %par_join_33
par_serial_29:
  %t201 = load i32, i32* @par.pool.serial_owner
  %t202 = icmp eq i32 %t201, %t134
  br i1 %t202, label %par_run_31, label %par_acquire_30
par_acquire_30:
  %t203 = load i8*, i8** @par.pool.serial_lock
  %t204 = call i32 @WaitForSingleObject(i8* %t203, i32 -1)
  store i32 %t134, i32* @par.pool.serial_owner
  br label %par_run_31
par_run_31:
  %t205 = load i64, i64* @arena.Enemies.count
  %t206 = alloca { i64, i64 }
  %t207 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t206, i32 0, i32 0
  store i64 0, i64* %t207
  %t208 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t206, i32 0, i32 1
  store i64 %t205, i64* %t208
  %t209 = bitcast { i64, i64 }* %t206 to i8*
  %t210 = call i32 @par_worker_24(i8* %t209)
  br i1 %t202, label %par_join_33, label %par_release_32
par_release_32:
  store i32 -1, i32* @par.pool.serial_owner
  %t211 = load i8*, i8** @par.pool.serial_lock
  %t212 = call i32 @ReleaseSemaphore(i8* %t211, i32 1, i32* null)
  br label %par_join_33
par_join_33:
  call void @par.pool.ensure_init()
  %t227 = call i32 @GetCurrentThreadId()
  %t228 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t229 = load i32, i32* %t228
  %t230 = icmp eq i32 %t227, %t229
  %t231 = select i1 %t230, i32 0, i32 -1
  %t232 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t233 = load i32, i32* %t232
  %t234 = icmp eq i32 %t227, %t233
  %t235 = select i1 %t234, i32 1, i32 %t231
  %t236 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t237 = load i32, i32* %t236
  %t238 = icmp eq i32 %t227, %t237
  %t239 = select i1 %t238, i32 2, i32 %t235
  %t240 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t241 = load i32, i32* %t240
  %t242 = icmp eq i32 %t227, %t241
  %t243 = select i1 %t242, i32 3, i32 %t239
  %t244 = icmp sge i32 %t243, 0
  br i1 %t244, label %par_serial_39, label %par_pooled_38
par_pooled_38:
  %t245 = load i64, i64* @arena.Enemies.count
  %t246 = mul i64 %t245, 0
  %t247 = sdiv i64 %t246, 4
  %t248 = mul i64 %t245, 1
  %t249 = sdiv i64 %t248, 4
  %t250 = alloca { i64, i64 }
  %t251 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t250, i32 0, i32 0
  store i64 %t247, i64* %t251
  %t252 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t250, i32 0, i32 1
  store i64 %t249, i64* %t252
  %t253 = bitcast { i64, i64 }* %t250 to i8*
  %t254 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t253, i8** %t254
  %t255 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_34, i32 (i8*)** %t255
  %t256 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t257 = load i8*, i8** %t256
  %t258 = call i32 @ReleaseSemaphore(i8* %t257, i32 1, i32* null)
  %t259 = mul i64 %t245, 1
  %t260 = sdiv i64 %t259, 4
  %t261 = mul i64 %t245, 2
  %t262 = sdiv i64 %t261, 4
  %t263 = alloca { i64, i64 }
  %t264 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t263, i32 0, i32 0
  store i64 %t260, i64* %t264
  %t265 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t263, i32 0, i32 1
  store i64 %t262, i64* %t265
  %t266 = bitcast { i64, i64 }* %t263 to i8*
  %t267 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t266, i8** %t267
  %t268 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_34, i32 (i8*)** %t268
  %t269 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t270 = load i8*, i8** %t269
  %t271 = call i32 @ReleaseSemaphore(i8* %t270, i32 1, i32* null)
  %t272 = mul i64 %t245, 2
  %t273 = sdiv i64 %t272, 4
  %t274 = mul i64 %t245, 3
  %t275 = sdiv i64 %t274, 4
  %t276 = alloca { i64, i64 }
  %t277 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t276, i32 0, i32 0
  store i64 %t273, i64* %t277
  %t278 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t276, i32 0, i32 1
  store i64 %t275, i64* %t278
  %t279 = bitcast { i64, i64 }* %t276 to i8*
  %t280 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t279, i8** %t280
  %t281 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_34, i32 (i8*)** %t281
  %t282 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t283 = load i8*, i8** %t282
  %t284 = call i32 @ReleaseSemaphore(i8* %t283, i32 1, i32* null)
  %t285 = mul i64 %t245, 3
  %t286 = sdiv i64 %t285, 4
  %t287 = mul i64 %t245, 4
  %t288 = sdiv i64 %t287, 4
  %t289 = alloca { i64, i64 }
  %t290 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t289, i32 0, i32 0
  store i64 %t286, i64* %t290
  %t291 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t289, i32 0, i32 1
  store i64 %t288, i64* %t291
  %t292 = bitcast { i64, i64 }* %t289 to i8*
  %t293 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t292, i8** %t293
  %t294 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_34, i32 (i8*)** %t294
  %t295 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t296 = load i8*, i8** %t295
  %t297 = call i32 @ReleaseSemaphore(i8* %t296, i32 1, i32* null)
  %t298 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t299 = load i8*, i8** %t298
  %t300 = call i32 @WaitForSingleObject(i8* %t299, i32 -1)
  %t301 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t302 = load i8*, i8** %t301
  %t303 = call i32 @WaitForSingleObject(i8* %t302, i32 -1)
  %t304 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t305 = load i8*, i8** %t304
  %t306 = call i32 @WaitForSingleObject(i8* %t305, i32 -1)
  %t307 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t308 = load i8*, i8** %t307
  %t309 = call i32 @WaitForSingleObject(i8* %t308, i32 -1)
  br label %par_join_43
par_serial_39:
  %t310 = load i32, i32* @par.pool.serial_owner
  %t311 = icmp eq i32 %t310, %t243
  br i1 %t311, label %par_run_41, label %par_acquire_40
par_acquire_40:
  %t312 = load i8*, i8** @par.pool.serial_lock
  %t313 = call i32 @WaitForSingleObject(i8* %t312, i32 -1)
  store i32 %t243, i32* @par.pool.serial_owner
  br label %par_run_41
par_run_41:
  %t314 = load i64, i64* @arena.Enemies.count
  %t315 = alloca { i64, i64 }
  %t316 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t315, i32 0, i32 0
  store i64 0, i64* %t316
  %t317 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t315, i32 0, i32 1
  store i64 %t314, i64* %t317
  %t318 = bitcast { i64, i64 }* %t315 to i8*
  %t319 = call i32 @par_worker_34(i8* %t318)
  br i1 %t311, label %par_join_43, label %par_release_42
par_release_42:
  store i32 -1, i32* @par.pool.serial_owner
  %t320 = load i8*, i8** @par.pool.serial_lock
  %t321 = call i32 @ReleaseSemaphore(i8* %t320, i32 1, i32* null)
  br label %par_join_43
par_join_43:
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_24(i8* %argp) {
entry:
  %t66 = bitcast i8* %argp to { i64, i64 }*
  %t67 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t66, i32 0, i32 0
  %t68 = load i64, i64* %t67
  %t69 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t66, i32 0, i32 1
  %t70 = load i64, i64* %t69
  %t71 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t72 = alloca i64
  store i64 %t68, i64* %t72
  br label %par_cond_25
par_cond_25:
  %t73 = load i64, i64* %t72
  %t74 = icmp slt i64 %t73, %t70
  br i1 %t74, label %par_body_26, label %par_end_27
par_body_26:
  %t75 = getelementptr inbounds %Enemy, %Enemy* %t71, i64 %t73
  %t76 = getelementptr inbounds %Enemy, %Enemy* %t75, i32 0, i32 0
  %t77 = load i32, i32* %t76
  %t78 = sub i32 %t77, 1
  %t79 = getelementptr inbounds %Enemy, %Enemy* %t75, i32 0, i32 0
  store i32 %t78, i32* %t79
  %t80 = add i64 %t73, 1
  store i64 %t80, i64* %t72
  br label %par_cond_25
par_end_27:
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
  %t81 = ptrtoint i8* %idx_arg to i64
  %t82 = trunc i64 %t81 to i32
  %t83 = call i32 @GetCurrentThreadId()
  %t84 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t82
  store i32 %t83, i32* %t84
  br label %loop
loop:
  %t85 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t82
  %t86 = load i8*, i8** %t85
  %t87 = call i32 @WaitForSingleObject(i8* %t86, i32 -1)
  %t88 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t82
  %t89 = load i32 (i8*)*, i32 (i8*)** %t88
  %t90 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t82
  %t91 = load i8*, i8** %t90
  %t92 = call i32 %t89(i8* %t91)
  %t93 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t82
  %t94 = load i8*, i8** %t93
  %t95 = call i32 @ReleaseSemaphore(i8* %t94, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t96 = load i1, i1* @par.pool.inited
  br i1 %t96, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t97 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t97, i8** @par.pool.serial_lock
  %t98 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t99 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t98, i8** %t99
  %t100 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t101 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t100, i8** %t101
  %t102 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t103 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t104 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t103, i8** %t104
  %t105 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t106 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t105, i8** %t106
  %t107 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t108 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t109 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t108, i8** %t109
  %t110 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t111 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t110, i8** %t111
  %t112 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t113 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t114 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t113, i8** %t114
  %t115 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t116 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t115, i8** %t116
  %t117 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_34(i8* %argp) {
entry:
  %t213 = bitcast i8* %argp to { i64, i64 }*
  %t214 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t213, i32 0, i32 0
  %t215 = load i64, i64* %t214
  %t216 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t213, i32 0, i32 1
  %t217 = load i64, i64* %t216
  %t218 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t219 = alloca i64
  store i64 %t215, i64* %t219
  br label %par_cond_35
par_cond_35:
  %t220 = load i64, i64* %t219
  %t221 = icmp slt i64 %t220, %t217
  br i1 %t221, label %par_body_36, label %par_end_37
par_body_36:
  %t222 = getelementptr inbounds %Enemy, %Enemy* %t218, i64 %t220
  %t223 = getelementptr inbounds %Enemy, %Enemy* %t222, i32 0, i32 0
  %t224 = load i32, i32* %t223
  %t225 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t225, i32 %t224)
  %t226 = add i64 %t220, 1
  store i64 %t226, i64* %t219
  br label %par_cond_35
par_end_37:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [8 x i8] c"hp: %d\0A\00"
