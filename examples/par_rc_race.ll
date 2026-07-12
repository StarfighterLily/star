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
  %t0 = alloca i8*
  %t1 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t2 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t3 = call i32 @strlen(i8* %t1)
  %t4 = call i32 @strlen(i8* %t2)
  %t5 = add i32 %t3, %t4
  %t6 = add i32 %t5, 1
  %t7 = sext i32 %t6 to i64
  %t8 = call i8* @star_rc_alloc(i64 %t7, i8* null)
  call i8* @strcpy(i8* %t8, i8* %t1)
  call i8* @strcat(i8* %t8, i8* %t2)
  store i8* %t8, i8** %t0
  %t9 = alloca i32
  store i32 0, i32* %t9
  br label %for_cond_0
for_cond_0:
  %t10 = load i32, i32* %t9
  %t11 = icmp slt i32 %t10, 16
  br i1 %t11, label %for_body_1, label %for_end_3
for_body_1:
  %t12 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t13 = icmp eq %Enemy* %t12, null
  br i1 %t13, label %spawn_init_4, label %spawn_ready_5
spawn_init_4:
  %t14 = getelementptr %Enemy, %Enemy* null, i32 1
  %t15 = ptrtoint %Enemy* %t14 to i64
  %t16 = mul i64 %t15, 1024
  %t17 = call i8* @malloc(i64 %t16)
  %t18 = bitcast i8* %t17 to %Enemy*
  store %Enemy* %t18, %Enemy** @arena.Enemies.data
  br label %spawn_ready_5
spawn_ready_5:
  %t19 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t20 = load i64, i64* @arena.Enemies.free_top
  %t21 = icmp sgt i64 %t20, 0
  br i1 %t21, label %spawn_reuse_6, label %spawn_grow_7
spawn_reuse_6:
  %t22 = sub i64 %t20, 1
  store i64 %t22, i64* @arena.Enemies.free_top
  %t23 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t22
  %t24 = load i64, i64* %t23
  br label %spawn_store_8
spawn_grow_7:
  %t25 = load i64, i64* @arena.Enemies.count
  %t26 = icmp slt i64 %t25, 1024
  br i1 %t26, label %spawn_grow_ok_10, label %spawn_capacity_warn_11
spawn_capacity_warn_11:
  %t27 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t27)
  br label %spawn_end_9
spawn_grow_ok_10:
  %t28 = add i64 %t25, 1
  store i64 %t28, i64* @arena.Enemies.count
  br label %spawn_store_8
spawn_store_8:
  %t29 = phi i64 [ %t24, %spawn_reuse_6 ], [ %t25, %spawn_grow_ok_10 ]
  %t30 = alloca %Enemy
  %t31 = getelementptr inbounds %Enemy, %Enemy* %t30, i32 0, i32 0
  store i32 100, i32* %t31
  %t32 = load %Enemy, %Enemy* %t30
  %t33 = getelementptr inbounds %Enemy, %Enemy* %t19, i64 %t29
  store %Enemy %t32, %Enemy* %t33
  %t34 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t29
  %t35 = load i32, i32* %t34
  %t36 = add i32 %t35, 1
  store i32 %t36, i32* %t34
  br label %spawn_end_9
spawn_end_9:
  br label %for_step_2
for_step_2:
  %t37 = load i32, i32* %t9
  %t38 = add i32 %t37, 1
  store i32 %t38, i32* %t9
  br label %for_cond_0
for_end_3:
  %t39 = alloca i32
  store i32 0, i32* %t39
  br label %for_cond_12
for_cond_12:
  %t40 = load i32, i32* %t39
  %t41 = icmp slt i32 %t40, 400
  br i1 %t41, label %for_body_13, label %for_end_15
for_body_13:
  call void @par.pool.ensure_init()
  %t104 = call i32 @GetCurrentThreadId()
  %t105 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t106 = load i32, i32* %t105
  %t107 = icmp eq i32 %t104, %t106
  %t108 = select i1 %t107, i32 0, i32 -1
  %t109 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t110 = load i32, i32* %t109
  %t111 = icmp eq i32 %t104, %t110
  %t112 = select i1 %t111, i32 1, i32 %t108
  %t113 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t114 = load i32, i32* %t113
  %t115 = icmp eq i32 %t104, %t114
  %t116 = select i1 %t115, i32 2, i32 %t112
  %t117 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t118 = load i32, i32* %t117
  %t119 = icmp eq i32 %t104, %t118
  %t120 = select i1 %t119, i32 3, i32 %t116
  %t121 = icmp sge i32 %t120, 0
  br i1 %t121, label %par_serial_23, label %par_pooled_22
par_pooled_22:
  %t122 = load i64, i64* @arena.Enemies.count
  %t123 = mul i64 %t122, 0
  %t124 = sdiv i64 %t123, 4
  %t125 = mul i64 %t122, 1
  %t126 = sdiv i64 %t125, 4
  %t127 = alloca { i64, i64, i8**, i32* }
  %t128 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t127, i32 0, i32 0
  store i64 %t124, i64* %t128
  %t129 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t127, i32 0, i32 1
  store i64 %t126, i64* %t129
  %t130 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t127, i32 0, i32 2
  store i8** %t0, i8*** %t130
  %t131 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t127, i32 0, i32 3
  store i32* %t39, i32** %t131
  %t132 = bitcast { i64, i64, i8**, i32* }* %t127 to i8*
  %t133 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t132, i8** %t133
  %t134 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t134
  %t135 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t136 = load i8*, i8** %t135
  %t137 = call i32 @ReleaseSemaphore(i8* %t136, i32 1, i32* null)
  %t138 = mul i64 %t122, 1
  %t139 = sdiv i64 %t138, 4
  %t140 = mul i64 %t122, 2
  %t141 = sdiv i64 %t140, 4
  %t142 = alloca { i64, i64, i8**, i32* }
  %t143 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t142, i32 0, i32 0
  store i64 %t139, i64* %t143
  %t144 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t142, i32 0, i32 1
  store i64 %t141, i64* %t144
  %t145 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t142, i32 0, i32 2
  store i8** %t0, i8*** %t145
  %t146 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t142, i32 0, i32 3
  store i32* %t39, i32** %t146
  %t147 = bitcast { i64, i64, i8**, i32* }* %t142 to i8*
  %t148 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t147, i8** %t148
  %t149 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t149
  %t150 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t151 = load i8*, i8** %t150
  %t152 = call i32 @ReleaseSemaphore(i8* %t151, i32 1, i32* null)
  %t153 = mul i64 %t122, 2
  %t154 = sdiv i64 %t153, 4
  %t155 = mul i64 %t122, 3
  %t156 = sdiv i64 %t155, 4
  %t157 = alloca { i64, i64, i8**, i32* }
  %t158 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t157, i32 0, i32 0
  store i64 %t154, i64* %t158
  %t159 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t157, i32 0, i32 1
  store i64 %t156, i64* %t159
  %t160 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t157, i32 0, i32 2
  store i8** %t0, i8*** %t160
  %t161 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t157, i32 0, i32 3
  store i32* %t39, i32** %t161
  %t162 = bitcast { i64, i64, i8**, i32* }* %t157 to i8*
  %t163 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t162, i8** %t163
  %t164 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t164
  %t165 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t166 = load i8*, i8** %t165
  %t167 = call i32 @ReleaseSemaphore(i8* %t166, i32 1, i32* null)
  %t168 = mul i64 %t122, 3
  %t169 = sdiv i64 %t168, 4
  %t170 = mul i64 %t122, 4
  %t171 = sdiv i64 %t170, 4
  %t172 = alloca { i64, i64, i8**, i32* }
  %t173 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t172, i32 0, i32 0
  store i64 %t169, i64* %t173
  %t174 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t172, i32 0, i32 1
  store i64 %t171, i64* %t174
  %t175 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t172, i32 0, i32 2
  store i8** %t0, i8*** %t175
  %t176 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t172, i32 0, i32 3
  store i32* %t39, i32** %t176
  %t177 = bitcast { i64, i64, i8**, i32* }* %t172 to i8*
  %t178 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t177, i8** %t178
  %t179 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t179
  %t180 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t181 = load i8*, i8** %t180
  %t182 = call i32 @ReleaseSemaphore(i8* %t181, i32 1, i32* null)
  %t183 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t184 = load i8*, i8** %t183
  %t185 = call i32 @WaitForSingleObject(i8* %t184, i32 -1)
  %t186 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t187 = load i8*, i8** %t186
  %t188 = call i32 @WaitForSingleObject(i8* %t187, i32 -1)
  %t189 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t190 = load i8*, i8** %t189
  %t191 = call i32 @WaitForSingleObject(i8* %t190, i32 -1)
  %t192 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t193 = load i8*, i8** %t192
  %t194 = call i32 @WaitForSingleObject(i8* %t193, i32 -1)
  br label %par_join_27
par_serial_23:
  %t195 = load i32, i32* @par.pool.serial_owner
  %t196 = icmp eq i32 %t195, %t120
  br i1 %t196, label %par_run_25, label %par_acquire_24
par_acquire_24:
  %t197 = load i8*, i8** @par.pool.serial_lock
  %t198 = call i32 @WaitForSingleObject(i8* %t197, i32 -1)
  store i32 %t120, i32* @par.pool.serial_owner
  br label %par_run_25
par_run_25:
  %t199 = load i64, i64* @arena.Enemies.count
  %t200 = alloca { i64, i64, i8**, i32* }
  %t201 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t200, i32 0, i32 0
  store i64 0, i64* %t201
  %t202 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t200, i32 0, i32 1
  store i64 %t199, i64* %t202
  %t203 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t200, i32 0, i32 2
  store i8** %t0, i8*** %t203
  %t204 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t200, i32 0, i32 3
  store i32* %t39, i32** %t204
  %t205 = bitcast { i64, i64, i8**, i32* }* %t200 to i8*
  %t206 = call i32 @par_worker_16(i8* %t205)
  br i1 %t196, label %par_join_27, label %par_release_26
par_release_26:
  store i32 -1, i32* @par.pool.serial_owner
  %t207 = load i8*, i8** @par.pool.serial_lock
  %t208 = call i32 @ReleaseSemaphore(i8* %t207, i32 1, i32* null)
  br label %par_join_27
par_join_27:
  br label %for_step_14
for_step_14:
  %t209 = load i32, i32* %t39
  %t210 = add i32 %t209, 1
  store i32 %t210, i32* %t39
  br label %for_cond_12
for_end_15:
  %t211 = load i8*, i8** %t0
  %t212 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t212)
  call void @star_rc_release(i8* %t211)
  %t213 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t213, i8* %t211)
  %t214 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t214)
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_16(i8* %argp) {
entry:
  %t42 = bitcast i8* %argp to { i64, i64, i8**, i32* }*
  %t43 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t42, i32 0, i32 0
  %t44 = load i64, i64* %t43
  %t45 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t42, i32 0, i32 1
  %t46 = load i64, i64* %t45
  %t47 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t42, i32 0, i32 2
  %t48 = load i8**, i8*** %t47
  %t49 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t42, i32 0, i32 3
  %t50 = load i32*, i32** %t49
  %t51 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t52 = alloca i64
  store i64 %t44, i64* %t52
  br label %par_cond_17
par_cond_17:
  %t53 = load i64, i64* %t52
  %t54 = icmp slt i64 %t53, %t46
  br i1 %t54, label %par_body_18, label %par_end_21
par_body_18:
  %t55 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t53
  %t56 = load i32, i32* %t55
  %t57 = and i32 %t56, 1
  %t58 = icmp eq i32 %t57, 1
  br i1 %t58, label %par_live_19, label %par_incr_20
par_live_19:
  %t59 = getelementptr inbounds %Enemy, %Enemy* %t51, i64 %t53
  %t60 = getelementptr inbounds %Enemy, %Enemy* %t59, i32 0, i32 0
  %t61 = load i32, i32* %t60
  %t62 = sub i32 %t61, 1
  %t63 = getelementptr inbounds %Enemy, %Enemy* %t59, i32 0, i32 0
  store i32 %t62, i32* %t63
  %t64 = load i8*, i8** %t48
  %t65 = load i8*, i8** %t48
  call void @star_rc_retain(i8* %t65)
  call void @star_rc_release(i8* %t64)
  call i32 (i8*, ...) @printf(i8* %t64)
  br label %par_incr_20
par_incr_20:
  %t66 = add i64 %t53, 1
  store i64 %t66, i64* %t52
  br label %par_cond_17
par_end_21:
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
  %t67 = ptrtoint i8* %idx_arg to i64
  %t68 = trunc i64 %t67 to i32
  %t69 = call i32 @GetCurrentThreadId()
  %t70 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t68
  store i32 %t69, i32* %t70
  br label %loop
loop:
  %t71 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t68
  %t72 = load i8*, i8** %t71
  %t73 = call i32 @WaitForSingleObject(i8* %t72, i32 -1)
  %t74 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t68
  %t75 = load i32 (i8*)*, i32 (i8*)** %t74
  %t76 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t68
  %t77 = load i8*, i8** %t76
  %t78 = call i32 %t75(i8* %t77)
  %t79 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t68
  %t80 = load i8*, i8** %t79
  %t81 = call i32 @ReleaseSemaphore(i8* %t80, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t82 = load i1, i1* @par.pool.inited
  br i1 %t82, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t83 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t83, i8** @par.pool.serial_lock
  %t84 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t85 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t84, i8** %t85
  %t86 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t87 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t86, i8** %t87
  %t88 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t89 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t90 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t89, i8** %t90
  %t91 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t92 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t91, i8** %t92
  %t93 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t94 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t95 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t94, i8** %t95
  %t96 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t97 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t96, i8** %t97
  %t98 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t99 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t100 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t99, i8** %t100
  %t101 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t102 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t101, i8** %t102
  %t103 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"swarm-\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"tag\00" }
@.str.2 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [11 x i8] c"final: %s\0A\00"
