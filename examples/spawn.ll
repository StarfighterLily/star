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
  %t122 = call i32 @GetCurrentThreadId()
  %t123 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t124 = load i32, i32* %t123
  %t125 = icmp eq i32 %t122, %t124
  %t126 = select i1 %t125, i32 0, i32 -1
  %t127 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t128 = load i32, i32* %t127
  %t129 = icmp eq i32 %t122, %t128
  %t130 = select i1 %t129, i32 1, i32 %t126
  %t131 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t132 = load i32, i32* %t131
  %t133 = icmp eq i32 %t122, %t132
  %t134 = select i1 %t133, i32 2, i32 %t130
  %t135 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t136 = load i32, i32* %t135
  %t137 = icmp eq i32 %t122, %t136
  %t138 = select i1 %t137, i32 3, i32 %t134
  %t139 = icmp sge i32 %t138, 0
  br i1 %t139, label %par_serial_31, label %par_pooled_30
par_pooled_30:
  %t140 = load i64, i64* @arena.Enemies.count
  %t141 = mul i64 %t140, 0
  %t142 = sdiv i64 %t141, 4
  %t143 = mul i64 %t140, 1
  %t144 = sdiv i64 %t143, 4
  %t145 = alloca { i64, i64 }
  %t146 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t145, i32 0, i32 0
  store i64 %t142, i64* %t146
  %t147 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t145, i32 0, i32 1
  store i64 %t144, i64* %t147
  %t148 = bitcast { i64, i64 }* %t145 to i8*
  %t149 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t148, i8** %t149
  %t150 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t150
  %t151 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t152 = load i8*, i8** %t151
  %t153 = call i32 @ReleaseSemaphore(i8* %t152, i32 1, i32* null)
  %t154 = mul i64 %t140, 1
  %t155 = sdiv i64 %t154, 4
  %t156 = mul i64 %t140, 2
  %t157 = sdiv i64 %t156, 4
  %t158 = alloca { i64, i64 }
  %t159 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t158, i32 0, i32 0
  store i64 %t155, i64* %t159
  %t160 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t158, i32 0, i32 1
  store i64 %t157, i64* %t160
  %t161 = bitcast { i64, i64 }* %t158 to i8*
  %t162 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t161, i8** %t162
  %t163 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t163
  %t164 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t165 = load i8*, i8** %t164
  %t166 = call i32 @ReleaseSemaphore(i8* %t165, i32 1, i32* null)
  %t167 = mul i64 %t140, 2
  %t168 = sdiv i64 %t167, 4
  %t169 = mul i64 %t140, 3
  %t170 = sdiv i64 %t169, 4
  %t171 = alloca { i64, i64 }
  %t172 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t171, i32 0, i32 0
  store i64 %t168, i64* %t172
  %t173 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t171, i32 0, i32 1
  store i64 %t170, i64* %t173
  %t174 = bitcast { i64, i64 }* %t171 to i8*
  %t175 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t174, i8** %t175
  %t176 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t176
  %t177 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t178 = load i8*, i8** %t177
  %t179 = call i32 @ReleaseSemaphore(i8* %t178, i32 1, i32* null)
  %t180 = mul i64 %t140, 3
  %t181 = sdiv i64 %t180, 4
  %t182 = mul i64 %t140, 4
  %t183 = sdiv i64 %t182, 4
  %t184 = alloca { i64, i64 }
  %t185 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t184, i32 0, i32 0
  store i64 %t181, i64* %t185
  %t186 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t184, i32 0, i32 1
  store i64 %t183, i64* %t186
  %t187 = bitcast { i64, i64 }* %t184 to i8*
  %t188 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t187, i8** %t188
  %t189 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t189
  %t190 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t191 = load i8*, i8** %t190
  %t192 = call i32 @ReleaseSemaphore(i8* %t191, i32 1, i32* null)
  %t193 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t194 = load i8*, i8** %t193
  %t195 = call i32 @WaitForSingleObject(i8* %t194, i32 -1)
  %t196 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t197 = load i8*, i8** %t196
  %t198 = call i32 @WaitForSingleObject(i8* %t197, i32 -1)
  %t199 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t200 = load i8*, i8** %t199
  %t201 = call i32 @WaitForSingleObject(i8* %t200, i32 -1)
  %t202 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t203 = load i8*, i8** %t202
  %t204 = call i32 @WaitForSingleObject(i8* %t203, i32 -1)
  br label %par_join_35
par_serial_31:
  %t205 = load i32, i32* @par.pool.serial_owner
  %t206 = icmp eq i32 %t205, %t138
  br i1 %t206, label %par_run_33, label %par_acquire_32
par_acquire_32:
  %t207 = load i8*, i8** @par.pool.serial_lock
  %t208 = call i32 @WaitForSingleObject(i8* %t207, i32 -1)
  store i32 %t138, i32* @par.pool.serial_owner
  br label %par_run_33
par_run_33:
  %t209 = load i64, i64* @arena.Enemies.count
  %t210 = alloca { i64, i64 }
  %t211 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t210, i32 0, i32 0
  store i64 0, i64* %t211
  %t212 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t210, i32 0, i32 1
  store i64 %t209, i64* %t212
  %t213 = bitcast { i64, i64 }* %t210 to i8*
  %t214 = call i32 @par_worker_24(i8* %t213)
  br i1 %t206, label %par_join_35, label %par_release_34
par_release_34:
  store i32 -1, i32* @par.pool.serial_owner
  %t215 = load i8*, i8** @par.pool.serial_lock
  %t216 = call i32 @ReleaseSemaphore(i8* %t215, i32 1, i32* null)
  br label %par_join_35
par_join_35:
  call void @par.pool.ensure_init()
  %t235 = call i32 @GetCurrentThreadId()
  %t236 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t237 = load i32, i32* %t236
  %t238 = icmp eq i32 %t235, %t237
  %t239 = select i1 %t238, i32 0, i32 -1
  %t240 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t241 = load i32, i32* %t240
  %t242 = icmp eq i32 %t235, %t241
  %t243 = select i1 %t242, i32 1, i32 %t239
  %t244 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t245 = load i32, i32* %t244
  %t246 = icmp eq i32 %t235, %t245
  %t247 = select i1 %t246, i32 2, i32 %t243
  %t248 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t249 = load i32, i32* %t248
  %t250 = icmp eq i32 %t235, %t249
  %t251 = select i1 %t250, i32 3, i32 %t247
  %t252 = icmp sge i32 %t251, 0
  br i1 %t252, label %par_serial_43, label %par_pooled_42
par_pooled_42:
  %t253 = load i64, i64* @arena.Enemies.count
  %t254 = mul i64 %t253, 0
  %t255 = sdiv i64 %t254, 4
  %t256 = mul i64 %t253, 1
  %t257 = sdiv i64 %t256, 4
  %t258 = alloca { i64, i64 }
  %t259 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t258, i32 0, i32 0
  store i64 %t255, i64* %t259
  %t260 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t258, i32 0, i32 1
  store i64 %t257, i64* %t260
  %t261 = bitcast { i64, i64 }* %t258 to i8*
  %t262 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t261, i8** %t262
  %t263 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_36, i32 (i8*)** %t263
  %t264 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t265 = load i8*, i8** %t264
  %t266 = call i32 @ReleaseSemaphore(i8* %t265, i32 1, i32* null)
  %t267 = mul i64 %t253, 1
  %t268 = sdiv i64 %t267, 4
  %t269 = mul i64 %t253, 2
  %t270 = sdiv i64 %t269, 4
  %t271 = alloca { i64, i64 }
  %t272 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t271, i32 0, i32 0
  store i64 %t268, i64* %t272
  %t273 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t271, i32 0, i32 1
  store i64 %t270, i64* %t273
  %t274 = bitcast { i64, i64 }* %t271 to i8*
  %t275 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t274, i8** %t275
  %t276 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_36, i32 (i8*)** %t276
  %t277 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t278 = load i8*, i8** %t277
  %t279 = call i32 @ReleaseSemaphore(i8* %t278, i32 1, i32* null)
  %t280 = mul i64 %t253, 2
  %t281 = sdiv i64 %t280, 4
  %t282 = mul i64 %t253, 3
  %t283 = sdiv i64 %t282, 4
  %t284 = alloca { i64, i64 }
  %t285 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t284, i32 0, i32 0
  store i64 %t281, i64* %t285
  %t286 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t284, i32 0, i32 1
  store i64 %t283, i64* %t286
  %t287 = bitcast { i64, i64 }* %t284 to i8*
  %t288 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t287, i8** %t288
  %t289 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_36, i32 (i8*)** %t289
  %t290 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t291 = load i8*, i8** %t290
  %t292 = call i32 @ReleaseSemaphore(i8* %t291, i32 1, i32* null)
  %t293 = mul i64 %t253, 3
  %t294 = sdiv i64 %t293, 4
  %t295 = mul i64 %t253, 4
  %t296 = sdiv i64 %t295, 4
  %t297 = alloca { i64, i64 }
  %t298 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t297, i32 0, i32 0
  store i64 %t294, i64* %t298
  %t299 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t297, i32 0, i32 1
  store i64 %t296, i64* %t299
  %t300 = bitcast { i64, i64 }* %t297 to i8*
  %t301 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t300, i8** %t301
  %t302 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_36, i32 (i8*)** %t302
  %t303 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t304 = load i8*, i8** %t303
  %t305 = call i32 @ReleaseSemaphore(i8* %t304, i32 1, i32* null)
  %t306 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t307 = load i8*, i8** %t306
  %t308 = call i32 @WaitForSingleObject(i8* %t307, i32 -1)
  %t309 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t310 = load i8*, i8** %t309
  %t311 = call i32 @WaitForSingleObject(i8* %t310, i32 -1)
  %t312 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t313 = load i8*, i8** %t312
  %t314 = call i32 @WaitForSingleObject(i8* %t313, i32 -1)
  %t315 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t316 = load i8*, i8** %t315
  %t317 = call i32 @WaitForSingleObject(i8* %t316, i32 -1)
  br label %par_join_47
par_serial_43:
  %t318 = load i32, i32* @par.pool.serial_owner
  %t319 = icmp eq i32 %t318, %t251
  br i1 %t319, label %par_run_45, label %par_acquire_44
par_acquire_44:
  %t320 = load i8*, i8** @par.pool.serial_lock
  %t321 = call i32 @WaitForSingleObject(i8* %t320, i32 -1)
  store i32 %t251, i32* @par.pool.serial_owner
  br label %par_run_45
par_run_45:
  %t322 = load i64, i64* @arena.Enemies.count
  %t323 = alloca { i64, i64 }
  %t324 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t323, i32 0, i32 0
  store i64 0, i64* %t324
  %t325 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t323, i32 0, i32 1
  store i64 %t322, i64* %t325
  %t326 = bitcast { i64, i64 }* %t323 to i8*
  %t327 = call i32 @par_worker_36(i8* %t326)
  br i1 %t319, label %par_join_47, label %par_release_46
par_release_46:
  store i32 -1, i32* @par.pool.serial_owner
  %t328 = load i8*, i8** @par.pool.serial_lock
  %t329 = call i32 @ReleaseSemaphore(i8* %t328, i32 1, i32* null)
  br label %par_join_47
par_join_47:
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
  br i1 %t74, label %par_body_26, label %par_end_29
par_body_26:
  %t75 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t73
  %t76 = load i32, i32* %t75
  %t77 = and i32 %t76, 1
  %t78 = icmp eq i32 %t77, 1
  br i1 %t78, label %par_live_27, label %par_incr_28
par_live_27:
  %t79 = getelementptr inbounds %Enemy, %Enemy* %t71, i64 %t73
  %t80 = getelementptr inbounds %Enemy, %Enemy* %t79, i32 0, i32 0
  %t81 = load i32, i32* %t80
  %t82 = sub i32 %t81, 1
  %t83 = getelementptr inbounds %Enemy, %Enemy* %t79, i32 0, i32 0
  store i32 %t82, i32* %t83
  br label %par_incr_28
par_incr_28:
  %t84 = add i64 %t73, 1
  store i64 %t84, i64* %t72
  br label %par_cond_25
par_end_29:
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
  %t85 = ptrtoint i8* %idx_arg to i64
  %t86 = trunc i64 %t85 to i32
  %t87 = call i32 @GetCurrentThreadId()
  %t88 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t86
  store i32 %t87, i32* %t88
  br label %loop
loop:
  %t89 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t86
  %t90 = load i8*, i8** %t89
  %t91 = call i32 @WaitForSingleObject(i8* %t90, i32 -1)
  %t92 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t86
  %t93 = load i32 (i8*)*, i32 (i8*)** %t92
  %t94 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t86
  %t95 = load i8*, i8** %t94
  %t96 = call i32 %t93(i8* %t95)
  %t97 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t86
  %t98 = load i8*, i8** %t97
  %t99 = call i32 @ReleaseSemaphore(i8* %t98, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t100 = load i1, i1* @par.pool.inited
  br i1 %t100, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t101 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t101, i8** @par.pool.serial_lock
  %t102 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t103 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t102, i8** %t103
  %t104 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t105 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t104, i8** %t105
  %t106 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t107 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t108 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t107, i8** %t108
  %t109 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t110 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t109, i8** %t110
  %t111 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t112 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t113 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t112, i8** %t113
  %t114 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t115 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t114, i8** %t115
  %t116 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t117 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t118 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t117, i8** %t118
  %t119 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t120 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t119, i8** %t120
  %t121 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_36(i8* %argp) {
entry:
  %t217 = bitcast i8* %argp to { i64, i64 }*
  %t218 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t217, i32 0, i32 0
  %t219 = load i64, i64* %t218
  %t220 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t217, i32 0, i32 1
  %t221 = load i64, i64* %t220
  %t222 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t223 = alloca i64
  store i64 %t219, i64* %t223
  br label %par_cond_37
par_cond_37:
  %t224 = load i64, i64* %t223
  %t225 = icmp slt i64 %t224, %t221
  br i1 %t225, label %par_body_38, label %par_end_41
par_body_38:
  %t226 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t224
  %t227 = load i32, i32* %t226
  %t228 = and i32 %t227, 1
  %t229 = icmp eq i32 %t228, 1
  br i1 %t229, label %par_live_39, label %par_incr_40
par_live_39:
  %t230 = getelementptr inbounds %Enemy, %Enemy* %t222, i64 %t224
  %t231 = getelementptr inbounds %Enemy, %Enemy* %t230, i32 0, i32 0
  %t232 = load i32, i32* %t231
  %t233 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t233, i32 %t232)
  br label %par_incr_40
par_incr_40:
  %t234 = add i64 %t224, 1
  store i64 %t234, i64* %t223
  br label %par_cond_37
par_end_41:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [8 x i8] c"hp: %d\0A\00"
