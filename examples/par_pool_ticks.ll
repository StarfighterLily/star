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
  store i32 100, i32* %t16
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
  store i32 100, i32* %t38
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
  store i32 100, i32* %t60
  %t61 = load %Enemy, %Enemy* %t59
  %t62 = getelementptr inbounds %Enemy, %Enemy* %t48, i64 %t58
  store %Enemy %t61, %Enemy* %t62
  %t63 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t58
  %t64 = load i32, i32* %t63
  %t65 = add i32 %t64, 1
  store i32 %t65, i32* %t63
  br label %spawn_end_21
spawn_end_21:
  %t66 = alloca i32
  store i32 0, i32* %t66
  br label %for_cond_24
for_cond_24:
  %t67 = load i32, i32* %t66
  %t68 = icmp slt i32 %t67, 5
  br i1 %t68, label %for_body_25, label %for_end_27
for_body_25:
  call void @par.pool.ensure_init()
  %t123 = call i32 @GetCurrentThreadId()
  %t124 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t125 = load i32, i32* %t124
  %t126 = icmp eq i32 %t123, %t125
  %t127 = select i1 %t126, i32 0, i32 -1
  %t128 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t129 = load i32, i32* %t128
  %t130 = icmp eq i32 %t123, %t129
  %t131 = select i1 %t130, i32 1, i32 %t127
  %t132 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t133 = load i32, i32* %t132
  %t134 = icmp eq i32 %t123, %t133
  %t135 = select i1 %t134, i32 2, i32 %t131
  %t136 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t137 = load i32, i32* %t136
  %t138 = icmp eq i32 %t123, %t137
  %t139 = select i1 %t138, i32 3, i32 %t135
  %t140 = icmp sge i32 %t139, 0
  br i1 %t140, label %par_serial_33, label %par_pooled_32
par_pooled_32:
  %t141 = load i64, i64* @arena.Enemies.count
  %t142 = mul i64 %t141, 0
  %t143 = sdiv i64 %t142, 4
  %t144 = mul i64 %t141, 1
  %t145 = sdiv i64 %t144, 4
  %t146 = alloca { i64, i64, i32* }
  %t147 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t146, i32 0, i32 0
  store i64 %t143, i64* %t147
  %t148 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t146, i32 0, i32 1
  store i64 %t145, i64* %t148
  %t149 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t146, i32 0, i32 2
  store i32* %t66, i32** %t149
  %t150 = bitcast { i64, i64, i32* }* %t146 to i8*
  %t151 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t150, i8** %t151
  %t152 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t152
  %t153 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t154 = load i8*, i8** %t153
  %t155 = call i32 @ReleaseSemaphore(i8* %t154, i32 1, i32* null)
  %t156 = mul i64 %t141, 1
  %t157 = sdiv i64 %t156, 4
  %t158 = mul i64 %t141, 2
  %t159 = sdiv i64 %t158, 4
  %t160 = alloca { i64, i64, i32* }
  %t161 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t160, i32 0, i32 0
  store i64 %t157, i64* %t161
  %t162 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t160, i32 0, i32 1
  store i64 %t159, i64* %t162
  %t163 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t160, i32 0, i32 2
  store i32* %t66, i32** %t163
  %t164 = bitcast { i64, i64, i32* }* %t160 to i8*
  %t165 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t164, i8** %t165
  %t166 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t166
  %t167 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t168 = load i8*, i8** %t167
  %t169 = call i32 @ReleaseSemaphore(i8* %t168, i32 1, i32* null)
  %t170 = mul i64 %t141, 2
  %t171 = sdiv i64 %t170, 4
  %t172 = mul i64 %t141, 3
  %t173 = sdiv i64 %t172, 4
  %t174 = alloca { i64, i64, i32* }
  %t175 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t174, i32 0, i32 0
  store i64 %t171, i64* %t175
  %t176 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t174, i32 0, i32 1
  store i64 %t173, i64* %t176
  %t177 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t174, i32 0, i32 2
  store i32* %t66, i32** %t177
  %t178 = bitcast { i64, i64, i32* }* %t174 to i8*
  %t179 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t178, i8** %t179
  %t180 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t180
  %t181 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t182 = load i8*, i8** %t181
  %t183 = call i32 @ReleaseSemaphore(i8* %t182, i32 1, i32* null)
  %t184 = mul i64 %t141, 3
  %t185 = sdiv i64 %t184, 4
  %t186 = mul i64 %t141, 4
  %t187 = sdiv i64 %t186, 4
  %t188 = alloca { i64, i64, i32* }
  %t189 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t188, i32 0, i32 0
  store i64 %t185, i64* %t189
  %t190 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t188, i32 0, i32 1
  store i64 %t187, i64* %t190
  %t191 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t188, i32 0, i32 2
  store i32* %t66, i32** %t191
  %t192 = bitcast { i64, i64, i32* }* %t188 to i8*
  %t193 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t192, i8** %t193
  %t194 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t194
  %t195 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t196 = load i8*, i8** %t195
  %t197 = call i32 @ReleaseSemaphore(i8* %t196, i32 1, i32* null)
  %t198 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t199 = load i8*, i8** %t198
  %t200 = call i32 @WaitForSingleObject(i8* %t199, i32 -1)
  %t201 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t202 = load i8*, i8** %t201
  %t203 = call i32 @WaitForSingleObject(i8* %t202, i32 -1)
  %t204 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t205 = load i8*, i8** %t204
  %t206 = call i32 @WaitForSingleObject(i8* %t205, i32 -1)
  %t207 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t208 = load i8*, i8** %t207
  %t209 = call i32 @WaitForSingleObject(i8* %t208, i32 -1)
  br label %par_join_37
par_serial_33:
  %t210 = load i32, i32* @par.pool.serial_owner
  %t211 = icmp eq i32 %t210, %t139
  br i1 %t211, label %par_run_35, label %par_acquire_34
par_acquire_34:
  %t212 = load i8*, i8** @par.pool.serial_lock
  %t213 = call i32 @WaitForSingleObject(i8* %t212, i32 -1)
  store i32 %t139, i32* @par.pool.serial_owner
  br label %par_run_35
par_run_35:
  %t214 = load i64, i64* @arena.Enemies.count
  %t215 = alloca { i64, i64, i32* }
  %t216 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t215, i32 0, i32 0
  store i64 0, i64* %t216
  %t217 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t215, i32 0, i32 1
  store i64 %t214, i64* %t217
  %t218 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t215, i32 0, i32 2
  store i32* %t66, i32** %t218
  %t219 = bitcast { i64, i64, i32* }* %t215 to i8*
  %t220 = call i32 @par_worker_28(i8* %t219)
  br i1 %t211, label %par_join_37, label %par_release_36
par_release_36:
  store i32 -1, i32* @par.pool.serial_owner
  %t221 = load i8*, i8** @par.pool.serial_lock
  %t222 = call i32 @ReleaseSemaphore(i8* %t221, i32 1, i32* null)
  br label %par_join_37
par_join_37:
  br label %for_step_26
for_step_26:
  %t223 = load i32, i32* %t66
  %t224 = add i32 %t223, 1
  store i32 %t224, i32* %t66
  br label %for_cond_24
for_end_27:
  call void @par.pool.ensure_init()
  %t239 = call i32 @GetCurrentThreadId()
  %t240 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t241 = load i32, i32* %t240
  %t242 = icmp eq i32 %t239, %t241
  %t243 = select i1 %t242, i32 0, i32 -1
  %t244 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t245 = load i32, i32* %t244
  %t246 = icmp eq i32 %t239, %t245
  %t247 = select i1 %t246, i32 1, i32 %t243
  %t248 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t249 = load i32, i32* %t248
  %t250 = icmp eq i32 %t239, %t249
  %t251 = select i1 %t250, i32 2, i32 %t247
  %t252 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t253 = load i32, i32* %t252
  %t254 = icmp eq i32 %t239, %t253
  %t255 = select i1 %t254, i32 3, i32 %t251
  %t256 = icmp sge i32 %t255, 0
  br i1 %t256, label %par_serial_43, label %par_pooled_42
par_pooled_42:
  %t257 = load i64, i64* @arena.Enemies.count
  %t258 = mul i64 %t257, 0
  %t259 = sdiv i64 %t258, 4
  %t260 = mul i64 %t257, 1
  %t261 = sdiv i64 %t260, 4
  %t262 = alloca { i64, i64 }
  %t263 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t262, i32 0, i32 0
  store i64 %t259, i64* %t263
  %t264 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t262, i32 0, i32 1
  store i64 %t261, i64* %t264
  %t265 = bitcast { i64, i64 }* %t262 to i8*
  %t266 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t265, i8** %t266
  %t267 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_38, i32 (i8*)** %t267
  %t268 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t269 = load i8*, i8** %t268
  %t270 = call i32 @ReleaseSemaphore(i8* %t269, i32 1, i32* null)
  %t271 = mul i64 %t257, 1
  %t272 = sdiv i64 %t271, 4
  %t273 = mul i64 %t257, 2
  %t274 = sdiv i64 %t273, 4
  %t275 = alloca { i64, i64 }
  %t276 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t275, i32 0, i32 0
  store i64 %t272, i64* %t276
  %t277 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t275, i32 0, i32 1
  store i64 %t274, i64* %t277
  %t278 = bitcast { i64, i64 }* %t275 to i8*
  %t279 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t278, i8** %t279
  %t280 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_38, i32 (i8*)** %t280
  %t281 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t282 = load i8*, i8** %t281
  %t283 = call i32 @ReleaseSemaphore(i8* %t282, i32 1, i32* null)
  %t284 = mul i64 %t257, 2
  %t285 = sdiv i64 %t284, 4
  %t286 = mul i64 %t257, 3
  %t287 = sdiv i64 %t286, 4
  %t288 = alloca { i64, i64 }
  %t289 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t288, i32 0, i32 0
  store i64 %t285, i64* %t289
  %t290 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t288, i32 0, i32 1
  store i64 %t287, i64* %t290
  %t291 = bitcast { i64, i64 }* %t288 to i8*
  %t292 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t291, i8** %t292
  %t293 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_38, i32 (i8*)** %t293
  %t294 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t295 = load i8*, i8** %t294
  %t296 = call i32 @ReleaseSemaphore(i8* %t295, i32 1, i32* null)
  %t297 = mul i64 %t257, 3
  %t298 = sdiv i64 %t297, 4
  %t299 = mul i64 %t257, 4
  %t300 = sdiv i64 %t299, 4
  %t301 = alloca { i64, i64 }
  %t302 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t301, i32 0, i32 0
  store i64 %t298, i64* %t302
  %t303 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t301, i32 0, i32 1
  store i64 %t300, i64* %t303
  %t304 = bitcast { i64, i64 }* %t301 to i8*
  %t305 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t304, i8** %t305
  %t306 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_38, i32 (i8*)** %t306
  %t307 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t308 = load i8*, i8** %t307
  %t309 = call i32 @ReleaseSemaphore(i8* %t308, i32 1, i32* null)
  %t310 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t311 = load i8*, i8** %t310
  %t312 = call i32 @WaitForSingleObject(i8* %t311, i32 -1)
  %t313 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t314 = load i8*, i8** %t313
  %t315 = call i32 @WaitForSingleObject(i8* %t314, i32 -1)
  %t316 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t317 = load i8*, i8** %t316
  %t318 = call i32 @WaitForSingleObject(i8* %t317, i32 -1)
  %t319 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t320 = load i8*, i8** %t319
  %t321 = call i32 @WaitForSingleObject(i8* %t320, i32 -1)
  br label %par_join_47
par_serial_43:
  %t322 = load i32, i32* @par.pool.serial_owner
  %t323 = icmp eq i32 %t322, %t255
  br i1 %t323, label %par_run_45, label %par_acquire_44
par_acquire_44:
  %t324 = load i8*, i8** @par.pool.serial_lock
  %t325 = call i32 @WaitForSingleObject(i8* %t324, i32 -1)
  store i32 %t255, i32* @par.pool.serial_owner
  br label %par_run_45
par_run_45:
  %t326 = load i64, i64* @arena.Enemies.count
  %t327 = alloca { i64, i64 }
  %t328 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t327, i32 0, i32 0
  store i64 0, i64* %t328
  %t329 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t327, i32 0, i32 1
  store i64 %t326, i64* %t329
  %t330 = bitcast { i64, i64 }* %t327 to i8*
  %t331 = call i32 @par_worker_38(i8* %t330)
  br i1 %t323, label %par_join_47, label %par_release_46
par_release_46:
  store i32 -1, i32* @par.pool.serial_owner
  %t332 = load i8*, i8** @par.pool.serial_lock
  %t333 = call i32 @ReleaseSemaphore(i8* %t332, i32 1, i32* null)
  br label %par_join_47
par_join_47:
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_28(i8* %argp) {
entry:
  %t69 = bitcast i8* %argp to { i64, i64, i32* }*
  %t70 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t69, i32 0, i32 0
  %t71 = load i64, i64* %t70
  %t72 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t69, i32 0, i32 1
  %t73 = load i64, i64* %t72
  %t74 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t69, i32 0, i32 2
  %t75 = load i32*, i32** %t74
  %t76 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t77 = alloca i64
  store i64 %t71, i64* %t77
  br label %par_cond_29
par_cond_29:
  %t78 = load i64, i64* %t77
  %t79 = icmp slt i64 %t78, %t73
  br i1 %t79, label %par_body_30, label %par_end_31
par_body_30:
  %t80 = getelementptr inbounds %Enemy, %Enemy* %t76, i64 %t78
  %t81 = getelementptr inbounds %Enemy, %Enemy* %t80, i32 0, i32 0
  %t82 = load i32, i32* %t81
  %t83 = sub i32 %t82, 1
  %t84 = getelementptr inbounds %Enemy, %Enemy* %t80, i32 0, i32 0
  store i32 %t83, i32* %t84
  %t85 = add i64 %t78, 1
  store i64 %t85, i64* %t77
  br label %par_cond_29
par_end_31:
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
  %t86 = ptrtoint i8* %idx_arg to i64
  %t87 = trunc i64 %t86 to i32
  %t88 = call i32 @GetCurrentThreadId()
  %t89 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t87
  store i32 %t88, i32* %t89
  br label %loop
loop:
  %t90 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t87
  %t91 = load i8*, i8** %t90
  %t92 = call i32 @WaitForSingleObject(i8* %t91, i32 -1)
  %t93 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t87
  %t94 = load i32 (i8*)*, i32 (i8*)** %t93
  %t95 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t87
  %t96 = load i8*, i8** %t95
  %t97 = call i32 %t94(i8* %t96)
  %t98 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t87
  %t99 = load i8*, i8** %t98
  %t100 = call i32 @ReleaseSemaphore(i8* %t99, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t101 = load i1, i1* @par.pool.inited
  br i1 %t101, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t102 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t102, i8** @par.pool.serial_lock
  %t103 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t104 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t103, i8** %t104
  %t105 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t106 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t105, i8** %t106
  %t107 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t108 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t109 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t108, i8** %t109
  %t110 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t111 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t110, i8** %t111
  %t112 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t113 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t114 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t113, i8** %t114
  %t115 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t116 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t115, i8** %t116
  %t117 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t118 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t119 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t118, i8** %t119
  %t120 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t121 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t120, i8** %t121
  %t122 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_38(i8* %argp) {
entry:
  %t225 = bitcast i8* %argp to { i64, i64 }*
  %t226 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t225, i32 0, i32 0
  %t227 = load i64, i64* %t226
  %t228 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t225, i32 0, i32 1
  %t229 = load i64, i64* %t228
  %t230 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t231 = alloca i64
  store i64 %t227, i64* %t231
  br label %par_cond_39
par_cond_39:
  %t232 = load i64, i64* %t231
  %t233 = icmp slt i64 %t232, %t229
  br i1 %t233, label %par_body_40, label %par_end_41
par_body_40:
  %t234 = getelementptr inbounds %Enemy, %Enemy* %t230, i64 %t232
  %t235 = getelementptr inbounds %Enemy, %Enemy* %t234, i32 0, i32 0
  %t236 = load i32, i32* %t235
  %t237 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t237, i32 %t236)
  %t238 = add i64 %t232, 1
  store i64 %t238, i64* %t231
  br label %par_cond_39
par_end_41:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [8 x i8] c"hp: %d\0A\00"
