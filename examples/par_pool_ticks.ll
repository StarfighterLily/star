; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
declare i32 @puts(i8*)
declare noalias i8* @malloc(i64)
declare void @free(i8*)
declare void @exit(i32) noreturn
declare i32 @strlen(i8*)
declare i32 @getchar()
declare i8* @memcpy(i8*, i8*, i64)
declare i8* @strcpy(i8*, i8*)
declare i8* @strcat(i8*, i8*)
declare i8* @fopen(i8*, i8*)
declare i32 @fclose(i8*)
declare i64 @fread(i8*, i64, i64, i8*)
declare i64 @fwrite(i8*, i64, i64, i8*)
declare i32 @fseek(i8*, i32, i32)
declare i32 @ftell(i8*)
declare i32 @fgetc(i8*)
declare i8* @getenv(i8*)
declare i32 @_putenv(i8*)
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

@star.argc = global i32 0
@star.argv = global i8** null

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

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
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
  %t127 = call i32 @GetCurrentThreadId()
  %t128 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t129 = load i32, i32* %t128
  %t130 = icmp eq i32 %t127, %t129
  %t131 = select i1 %t130, i32 0, i32 -1
  %t132 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t133 = load i32, i32* %t132
  %t134 = icmp eq i32 %t127, %t133
  %t135 = select i1 %t134, i32 1, i32 %t131
  %t136 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t137 = load i32, i32* %t136
  %t138 = icmp eq i32 %t127, %t137
  %t139 = select i1 %t138, i32 2, i32 %t135
  %t140 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t141 = load i32, i32* %t140
  %t142 = icmp eq i32 %t127, %t141
  %t143 = select i1 %t142, i32 3, i32 %t139
  %t144 = icmp sge i32 %t143, 0
  br i1 %t144, label %par_serial_35, label %par_pooled_34
par_pooled_34:
  %t145 = load i64, i64* @arena.Enemies.count
  %t146 = mul i64 %t145, 0
  %t147 = sdiv i64 %t146, 4
  %t148 = mul i64 %t145, 1
  %t149 = sdiv i64 %t148, 4
  %t150 = alloca { i64, i64, i32* }
  %t151 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t150, i32 0, i32 0
  store i64 %t147, i64* %t151
  %t152 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t150, i32 0, i32 1
  store i64 %t149, i64* %t152
  %t153 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t150, i32 0, i32 2
  store i32* %t66, i32** %t153
  %t154 = bitcast { i64, i64, i32* }* %t150 to i8*
  %t155 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t154, i8** %t155
  %t156 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t156
  %t157 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t158 = load i8*, i8** %t157
  %t159 = call i32 @ReleaseSemaphore(i8* %t158, i32 1, i32* null)
  %t160 = mul i64 %t145, 1
  %t161 = sdiv i64 %t160, 4
  %t162 = mul i64 %t145, 2
  %t163 = sdiv i64 %t162, 4
  %t164 = alloca { i64, i64, i32* }
  %t165 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t164, i32 0, i32 0
  store i64 %t161, i64* %t165
  %t166 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t164, i32 0, i32 1
  store i64 %t163, i64* %t166
  %t167 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t164, i32 0, i32 2
  store i32* %t66, i32** %t167
  %t168 = bitcast { i64, i64, i32* }* %t164 to i8*
  %t169 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t168, i8** %t169
  %t170 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t170
  %t171 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t172 = load i8*, i8** %t171
  %t173 = call i32 @ReleaseSemaphore(i8* %t172, i32 1, i32* null)
  %t174 = mul i64 %t145, 2
  %t175 = sdiv i64 %t174, 4
  %t176 = mul i64 %t145, 3
  %t177 = sdiv i64 %t176, 4
  %t178 = alloca { i64, i64, i32* }
  %t179 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t178, i32 0, i32 0
  store i64 %t175, i64* %t179
  %t180 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t178, i32 0, i32 1
  store i64 %t177, i64* %t180
  %t181 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t178, i32 0, i32 2
  store i32* %t66, i32** %t181
  %t182 = bitcast { i64, i64, i32* }* %t178 to i8*
  %t183 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t182, i8** %t183
  %t184 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t184
  %t185 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t186 = load i8*, i8** %t185
  %t187 = call i32 @ReleaseSemaphore(i8* %t186, i32 1, i32* null)
  %t188 = mul i64 %t145, 3
  %t189 = sdiv i64 %t188, 4
  %t190 = mul i64 %t145, 4
  %t191 = sdiv i64 %t190, 4
  %t192 = alloca { i64, i64, i32* }
  %t193 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t192, i32 0, i32 0
  store i64 %t189, i64* %t193
  %t194 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t192, i32 0, i32 1
  store i64 %t191, i64* %t194
  %t195 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t192, i32 0, i32 2
  store i32* %t66, i32** %t195
  %t196 = bitcast { i64, i64, i32* }* %t192 to i8*
  %t197 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t196, i8** %t197
  %t198 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t198
  %t199 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t200 = load i8*, i8** %t199
  %t201 = call i32 @ReleaseSemaphore(i8* %t200, i32 1, i32* null)
  %t202 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t203 = load i8*, i8** %t202
  %t204 = call i32 @WaitForSingleObject(i8* %t203, i32 -1)
  %t205 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t206 = load i8*, i8** %t205
  %t207 = call i32 @WaitForSingleObject(i8* %t206, i32 -1)
  %t208 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t209 = load i8*, i8** %t208
  %t210 = call i32 @WaitForSingleObject(i8* %t209, i32 -1)
  %t211 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t212 = load i8*, i8** %t211
  %t213 = call i32 @WaitForSingleObject(i8* %t212, i32 -1)
  br label %par_join_39
par_serial_35:
  %t214 = load i32, i32* @par.pool.serial_owner
  %t215 = icmp eq i32 %t214, %t143
  br i1 %t215, label %par_run_37, label %par_acquire_36
par_acquire_36:
  %t216 = load i8*, i8** @par.pool.serial_lock
  %t217 = call i32 @WaitForSingleObject(i8* %t216, i32 -1)
  store i32 %t143, i32* @par.pool.serial_owner
  br label %par_run_37
par_run_37:
  %t218 = load i64, i64* @arena.Enemies.count
  %t219 = alloca { i64, i64, i32* }
  %t220 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t219, i32 0, i32 0
  store i64 0, i64* %t220
  %t221 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t219, i32 0, i32 1
  store i64 %t218, i64* %t221
  %t222 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t219, i32 0, i32 2
  store i32* %t66, i32** %t222
  %t223 = bitcast { i64, i64, i32* }* %t219 to i8*
  %t224 = call i32 @par_worker_28(i8* %t223)
  br i1 %t215, label %par_join_39, label %par_release_38
par_release_38:
  store i32 -1, i32* @par.pool.serial_owner
  %t225 = load i8*, i8** @par.pool.serial_lock
  %t226 = call i32 @ReleaseSemaphore(i8* %t225, i32 1, i32* null)
  br label %par_join_39
par_join_39:
  br label %for_step_26
for_step_26:
  %t227 = load i32, i32* %t66
  %t228 = add i32 %t227, 1
  store i32 %t228, i32* %t66
  br label %for_cond_24
for_end_27:
  call void @par.pool.ensure_init()
  %t247 = call i32 @GetCurrentThreadId()
  %t248 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t249 = load i32, i32* %t248
  %t250 = icmp eq i32 %t247, %t249
  %t251 = select i1 %t250, i32 0, i32 -1
  %t252 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t253 = load i32, i32* %t252
  %t254 = icmp eq i32 %t247, %t253
  %t255 = select i1 %t254, i32 1, i32 %t251
  %t256 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t257 = load i32, i32* %t256
  %t258 = icmp eq i32 %t247, %t257
  %t259 = select i1 %t258, i32 2, i32 %t255
  %t260 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t261 = load i32, i32* %t260
  %t262 = icmp eq i32 %t247, %t261
  %t263 = select i1 %t262, i32 3, i32 %t259
  %t264 = icmp sge i32 %t263, 0
  br i1 %t264, label %par_serial_47, label %par_pooled_46
par_pooled_46:
  %t265 = load i64, i64* @arena.Enemies.count
  %t266 = mul i64 %t265, 0
  %t267 = sdiv i64 %t266, 4
  %t268 = mul i64 %t265, 1
  %t269 = sdiv i64 %t268, 4
  %t270 = alloca { i64, i64 }
  %t271 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t270, i32 0, i32 0
  store i64 %t267, i64* %t271
  %t272 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t270, i32 0, i32 1
  store i64 %t269, i64* %t272
  %t273 = bitcast { i64, i64 }* %t270 to i8*
  %t274 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t273, i8** %t274
  %t275 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_40, i32 (i8*)** %t275
  %t276 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t277 = load i8*, i8** %t276
  %t278 = call i32 @ReleaseSemaphore(i8* %t277, i32 1, i32* null)
  %t279 = mul i64 %t265, 1
  %t280 = sdiv i64 %t279, 4
  %t281 = mul i64 %t265, 2
  %t282 = sdiv i64 %t281, 4
  %t283 = alloca { i64, i64 }
  %t284 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t283, i32 0, i32 0
  store i64 %t280, i64* %t284
  %t285 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t283, i32 0, i32 1
  store i64 %t282, i64* %t285
  %t286 = bitcast { i64, i64 }* %t283 to i8*
  %t287 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t286, i8** %t287
  %t288 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_40, i32 (i8*)** %t288
  %t289 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t290 = load i8*, i8** %t289
  %t291 = call i32 @ReleaseSemaphore(i8* %t290, i32 1, i32* null)
  %t292 = mul i64 %t265, 2
  %t293 = sdiv i64 %t292, 4
  %t294 = mul i64 %t265, 3
  %t295 = sdiv i64 %t294, 4
  %t296 = alloca { i64, i64 }
  %t297 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t296, i32 0, i32 0
  store i64 %t293, i64* %t297
  %t298 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t296, i32 0, i32 1
  store i64 %t295, i64* %t298
  %t299 = bitcast { i64, i64 }* %t296 to i8*
  %t300 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t299, i8** %t300
  %t301 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_40, i32 (i8*)** %t301
  %t302 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t303 = load i8*, i8** %t302
  %t304 = call i32 @ReleaseSemaphore(i8* %t303, i32 1, i32* null)
  %t305 = mul i64 %t265, 3
  %t306 = sdiv i64 %t305, 4
  %t307 = mul i64 %t265, 4
  %t308 = sdiv i64 %t307, 4
  %t309 = alloca { i64, i64 }
  %t310 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t309, i32 0, i32 0
  store i64 %t306, i64* %t310
  %t311 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t309, i32 0, i32 1
  store i64 %t308, i64* %t311
  %t312 = bitcast { i64, i64 }* %t309 to i8*
  %t313 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t312, i8** %t313
  %t314 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_40, i32 (i8*)** %t314
  %t315 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t316 = load i8*, i8** %t315
  %t317 = call i32 @ReleaseSemaphore(i8* %t316, i32 1, i32* null)
  %t318 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t319 = load i8*, i8** %t318
  %t320 = call i32 @WaitForSingleObject(i8* %t319, i32 -1)
  %t321 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t322 = load i8*, i8** %t321
  %t323 = call i32 @WaitForSingleObject(i8* %t322, i32 -1)
  %t324 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t325 = load i8*, i8** %t324
  %t326 = call i32 @WaitForSingleObject(i8* %t325, i32 -1)
  %t327 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t328 = load i8*, i8** %t327
  %t329 = call i32 @WaitForSingleObject(i8* %t328, i32 -1)
  br label %par_join_51
par_serial_47:
  %t330 = load i32, i32* @par.pool.serial_owner
  %t331 = icmp eq i32 %t330, %t263
  br i1 %t331, label %par_run_49, label %par_acquire_48
par_acquire_48:
  %t332 = load i8*, i8** @par.pool.serial_lock
  %t333 = call i32 @WaitForSingleObject(i8* %t332, i32 -1)
  store i32 %t263, i32* @par.pool.serial_owner
  br label %par_run_49
par_run_49:
  %t334 = load i64, i64* @arena.Enemies.count
  %t335 = alloca { i64, i64 }
  %t336 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t335, i32 0, i32 0
  store i64 0, i64* %t336
  %t337 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t335, i32 0, i32 1
  store i64 %t334, i64* %t337
  %t338 = bitcast { i64, i64 }* %t335 to i8*
  %t339 = call i32 @par_worker_40(i8* %t338)
  br i1 %t331, label %par_join_51, label %par_release_50
par_release_50:
  store i32 -1, i32* @par.pool.serial_owner
  %t340 = load i8*, i8** @par.pool.serial_lock
  %t341 = call i32 @ReleaseSemaphore(i8* %t340, i32 1, i32* null)
  br label %par_join_51
par_join_51:
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
  br i1 %t79, label %par_body_30, label %par_end_33
par_body_30:
  %t80 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t78
  %t81 = load i32, i32* %t80
  %t82 = and i32 %t81, 1
  %t83 = icmp eq i32 %t82, 1
  br i1 %t83, label %par_live_31, label %par_incr_32
par_live_31:
  %t84 = getelementptr inbounds %Enemy, %Enemy* %t76, i64 %t78
  %t85 = getelementptr inbounds %Enemy, %Enemy* %t84, i32 0, i32 0
  %t86 = load i32, i32* %t85
  %t87 = sub i32 %t86, 1
  %t88 = getelementptr inbounds %Enemy, %Enemy* %t84, i32 0, i32 0
  store i32 %t87, i32* %t88
  br label %par_incr_32
par_incr_32:
  %t89 = add i64 %t78, 1
  store i64 %t89, i64* %t77
  br label %par_cond_29
par_end_33:
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
  %t90 = ptrtoint i8* %idx_arg to i64
  %t91 = trunc i64 %t90 to i32
  %t92 = call i32 @GetCurrentThreadId()
  %t93 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t91
  store i32 %t92, i32* %t93
  br label %loop
loop:
  %t94 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t91
  %t95 = load i8*, i8** %t94
  %t96 = call i32 @WaitForSingleObject(i8* %t95, i32 -1)
  %t97 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t91
  %t98 = load i32 (i8*)*, i32 (i8*)** %t97
  %t99 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t91
  %t100 = load i8*, i8** %t99
  %t101 = call i32 %t98(i8* %t100)
  %t102 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t91
  %t103 = load i8*, i8** %t102
  %t104 = call i32 @ReleaseSemaphore(i8* %t103, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t105 = load i1, i1* @par.pool.inited
  br i1 %t105, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t106 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t106, i8** @par.pool.serial_lock
  %t107 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t108 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t107, i8** %t108
  %t109 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t110 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t109, i8** %t110
  %t111 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t112 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t113 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t112, i8** %t113
  %t114 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t115 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t114, i8** %t115
  %t116 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t117 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t118 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t117, i8** %t118
  %t119 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t120 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t119, i8** %t120
  %t121 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t122 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t123 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t122, i8** %t123
  %t124 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t125 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t124, i8** %t125
  %t126 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_40(i8* %argp) {
entry:
  %t229 = bitcast i8* %argp to { i64, i64 }*
  %t230 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t229, i32 0, i32 0
  %t231 = load i64, i64* %t230
  %t232 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t229, i32 0, i32 1
  %t233 = load i64, i64* %t232
  %t234 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t235 = alloca i64
  store i64 %t231, i64* %t235
  br label %par_cond_41
par_cond_41:
  %t236 = load i64, i64* %t235
  %t237 = icmp slt i64 %t236, %t233
  br i1 %t237, label %par_body_42, label %par_end_45
par_body_42:
  %t238 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t236
  %t239 = load i32, i32* %t238
  %t240 = and i32 %t239, 1
  %t241 = icmp eq i32 %t240, 1
  br i1 %t241, label %par_live_43, label %par_incr_44
par_live_43:
  %t242 = getelementptr inbounds %Enemy, %Enemy* %t234, i64 %t236
  %t243 = getelementptr inbounds %Enemy, %Enemy* %t242, i32 0, i32 0
  %t244 = load i32, i32* %t243
  %t245 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t245, i32 %t244)
  br label %par_incr_44
par_incr_44:
  %t246 = add i64 %t236, 1
  store i64 %t246, i64* %t235
  br label %par_cond_41
par_end_45:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [8 x i8] c"hp: %d\0A\00"
