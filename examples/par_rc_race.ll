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
  %t14 = call i8* @malloc(i64 4096)
  %t15 = bitcast i8* %t14 to %Enemy*
  store %Enemy* %t15, %Enemy** @arena.Enemies.data
  br label %spawn_ready_5
spawn_ready_5:
  %t16 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t17 = load i64, i64* @arena.Enemies.free_top
  %t18 = icmp sgt i64 %t17, 0
  br i1 %t18, label %spawn_reuse_6, label %spawn_grow_7
spawn_reuse_6:
  %t19 = sub i64 %t17, 1
  store i64 %t19, i64* @arena.Enemies.free_top
  %t20 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t19
  %t21 = load i64, i64* %t20
  br label %spawn_store_8
spawn_grow_7:
  %t22 = load i64, i64* @arena.Enemies.count
  %t23 = icmp slt i64 %t22, 1024
  br i1 %t23, label %spawn_grow_ok_10, label %spawn_capacity_warn_11
spawn_capacity_warn_11:
  %t24 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t24)
  br label %spawn_end_9
spawn_grow_ok_10:
  %t25 = add i64 %t22, 1
  store i64 %t25, i64* @arena.Enemies.count
  br label %spawn_store_8
spawn_store_8:
  %t26 = phi i64 [ %t21, %spawn_reuse_6 ], [ %t22, %spawn_grow_ok_10 ]
  %t27 = alloca %Enemy
  %t28 = getelementptr inbounds %Enemy, %Enemy* %t27, i32 0, i32 0
  store i32 100, i32* %t28
  %t29 = load %Enemy, %Enemy* %t27
  %t30 = getelementptr inbounds %Enemy, %Enemy* %t16, i64 %t26
  store %Enemy %t29, %Enemy* %t30
  %t31 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t26
  %t32 = load i32, i32* %t31
  %t33 = add i32 %t32, 1
  store i32 %t33, i32* %t31
  br label %spawn_end_9
spawn_end_9:
  br label %for_step_2
for_step_2:
  %t34 = load i32, i32* %t9
  %t35 = add i32 %t34, 1
  store i32 %t35, i32* %t9
  br label %for_cond_0
for_end_3:
  %t36 = alloca i32
  store i32 0, i32* %t36
  br label %for_cond_12
for_cond_12:
  %t37 = load i32, i32* %t36
  %t38 = icmp slt i32 %t37, 400
  br i1 %t38, label %for_body_13, label %for_end_15
for_body_13:
  call void @par.pool.ensure_init()
  %t101 = call i32 @GetCurrentThreadId()
  %t102 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t103 = load i32, i32* %t102
  %t104 = icmp eq i32 %t101, %t103
  %t105 = select i1 %t104, i32 0, i32 -1
  %t106 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t107 = load i32, i32* %t106
  %t108 = icmp eq i32 %t101, %t107
  %t109 = select i1 %t108, i32 1, i32 %t105
  %t110 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t111 = load i32, i32* %t110
  %t112 = icmp eq i32 %t101, %t111
  %t113 = select i1 %t112, i32 2, i32 %t109
  %t114 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t115 = load i32, i32* %t114
  %t116 = icmp eq i32 %t101, %t115
  %t117 = select i1 %t116, i32 3, i32 %t113
  %t118 = icmp sge i32 %t117, 0
  br i1 %t118, label %par_serial_23, label %par_pooled_22
par_pooled_22:
  %t119 = load i64, i64* @arena.Enemies.count
  %t120 = mul i64 %t119, 0
  %t121 = sdiv i64 %t120, 4
  %t122 = mul i64 %t119, 1
  %t123 = sdiv i64 %t122, 4
  %t124 = alloca { i64, i64, i8**, i32* }
  %t125 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t124, i32 0, i32 0
  store i64 %t121, i64* %t125
  %t126 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t124, i32 0, i32 1
  store i64 %t123, i64* %t126
  %t127 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t124, i32 0, i32 2
  store i8** %t0, i8*** %t127
  %t128 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t124, i32 0, i32 3
  store i32* %t36, i32** %t128
  %t129 = bitcast { i64, i64, i8**, i32* }* %t124 to i8*
  %t130 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t129, i8** %t130
  %t131 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t131
  %t132 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t133 = load i8*, i8** %t132
  %t134 = call i32 @ReleaseSemaphore(i8* %t133, i32 1, i32* null)
  %t135 = mul i64 %t119, 1
  %t136 = sdiv i64 %t135, 4
  %t137 = mul i64 %t119, 2
  %t138 = sdiv i64 %t137, 4
  %t139 = alloca { i64, i64, i8**, i32* }
  %t140 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t139, i32 0, i32 0
  store i64 %t136, i64* %t140
  %t141 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t139, i32 0, i32 1
  store i64 %t138, i64* %t141
  %t142 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t139, i32 0, i32 2
  store i8** %t0, i8*** %t142
  %t143 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t139, i32 0, i32 3
  store i32* %t36, i32** %t143
  %t144 = bitcast { i64, i64, i8**, i32* }* %t139 to i8*
  %t145 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t144, i8** %t145
  %t146 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t146
  %t147 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t148 = load i8*, i8** %t147
  %t149 = call i32 @ReleaseSemaphore(i8* %t148, i32 1, i32* null)
  %t150 = mul i64 %t119, 2
  %t151 = sdiv i64 %t150, 4
  %t152 = mul i64 %t119, 3
  %t153 = sdiv i64 %t152, 4
  %t154 = alloca { i64, i64, i8**, i32* }
  %t155 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t154, i32 0, i32 0
  store i64 %t151, i64* %t155
  %t156 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t154, i32 0, i32 1
  store i64 %t153, i64* %t156
  %t157 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t154, i32 0, i32 2
  store i8** %t0, i8*** %t157
  %t158 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t154, i32 0, i32 3
  store i32* %t36, i32** %t158
  %t159 = bitcast { i64, i64, i8**, i32* }* %t154 to i8*
  %t160 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t159, i8** %t160
  %t161 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t161
  %t162 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t163 = load i8*, i8** %t162
  %t164 = call i32 @ReleaseSemaphore(i8* %t163, i32 1, i32* null)
  %t165 = mul i64 %t119, 3
  %t166 = sdiv i64 %t165, 4
  %t167 = mul i64 %t119, 4
  %t168 = sdiv i64 %t167, 4
  %t169 = alloca { i64, i64, i8**, i32* }
  %t170 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t169, i32 0, i32 0
  store i64 %t166, i64* %t170
  %t171 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t169, i32 0, i32 1
  store i64 %t168, i64* %t171
  %t172 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t169, i32 0, i32 2
  store i8** %t0, i8*** %t172
  %t173 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t169, i32 0, i32 3
  store i32* %t36, i32** %t173
  %t174 = bitcast { i64, i64, i8**, i32* }* %t169 to i8*
  %t175 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t174, i8** %t175
  %t176 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t176
  %t177 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t178 = load i8*, i8** %t177
  %t179 = call i32 @ReleaseSemaphore(i8* %t178, i32 1, i32* null)
  %t180 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t181 = load i8*, i8** %t180
  %t182 = call i32 @WaitForSingleObject(i8* %t181, i32 -1)
  %t183 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t184 = load i8*, i8** %t183
  %t185 = call i32 @WaitForSingleObject(i8* %t184, i32 -1)
  %t186 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t187 = load i8*, i8** %t186
  %t188 = call i32 @WaitForSingleObject(i8* %t187, i32 -1)
  %t189 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t190 = load i8*, i8** %t189
  %t191 = call i32 @WaitForSingleObject(i8* %t190, i32 -1)
  br label %par_join_27
par_serial_23:
  %t192 = load i32, i32* @par.pool.serial_owner
  %t193 = icmp eq i32 %t192, %t117
  br i1 %t193, label %par_run_25, label %par_acquire_24
par_acquire_24:
  %t194 = load i8*, i8** @par.pool.serial_lock
  %t195 = call i32 @WaitForSingleObject(i8* %t194, i32 -1)
  store i32 %t117, i32* @par.pool.serial_owner
  br label %par_run_25
par_run_25:
  %t196 = load i64, i64* @arena.Enemies.count
  %t197 = alloca { i64, i64, i8**, i32* }
  %t198 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t197, i32 0, i32 0
  store i64 0, i64* %t198
  %t199 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t197, i32 0, i32 1
  store i64 %t196, i64* %t199
  %t200 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t197, i32 0, i32 2
  store i8** %t0, i8*** %t200
  %t201 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t197, i32 0, i32 3
  store i32* %t36, i32** %t201
  %t202 = bitcast { i64, i64, i8**, i32* }* %t197 to i8*
  %t203 = call i32 @par_worker_16(i8* %t202)
  br i1 %t193, label %par_join_27, label %par_release_26
par_release_26:
  store i32 -1, i32* @par.pool.serial_owner
  %t204 = load i8*, i8** @par.pool.serial_lock
  %t205 = call i32 @ReleaseSemaphore(i8* %t204, i32 1, i32* null)
  br label %par_join_27
par_join_27:
  br label %for_step_14
for_step_14:
  %t206 = load i32, i32* %t36
  %t207 = add i32 %t206, 1
  store i32 %t207, i32* %t36
  br label %for_cond_12
for_end_15:
  %t208 = load i8*, i8** %t0
  %t209 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t209)
  call void @star_rc_release(i8* %t208)
  %t210 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t210, i8* %t208)
  %t211 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t211)
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_16(i8* %argp) {
entry:
  %t39 = bitcast i8* %argp to { i64, i64, i8**, i32* }*
  %t40 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t39, i32 0, i32 0
  %t41 = load i64, i64* %t40
  %t42 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t39, i32 0, i32 1
  %t43 = load i64, i64* %t42
  %t44 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t39, i32 0, i32 2
  %t45 = load i8**, i8*** %t44
  %t46 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t39, i32 0, i32 3
  %t47 = load i32*, i32** %t46
  %t48 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t49 = alloca i64
  store i64 %t41, i64* %t49
  br label %par_cond_17
par_cond_17:
  %t50 = load i64, i64* %t49
  %t51 = icmp slt i64 %t50, %t43
  br i1 %t51, label %par_body_18, label %par_end_21
par_body_18:
  %t52 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t50
  %t53 = load i32, i32* %t52
  %t54 = and i32 %t53, 1
  %t55 = icmp eq i32 %t54, 1
  br i1 %t55, label %par_live_19, label %par_incr_20
par_live_19:
  %t56 = getelementptr inbounds %Enemy, %Enemy* %t48, i64 %t50
  %t57 = getelementptr inbounds %Enemy, %Enemy* %t56, i32 0, i32 0
  %t58 = load i32, i32* %t57
  %t59 = sub i32 %t58, 1
  %t60 = getelementptr inbounds %Enemy, %Enemy* %t56, i32 0, i32 0
  store i32 %t59, i32* %t60
  %t61 = load i8*, i8** %t45
  %t62 = load i8*, i8** %t45
  call void @star_rc_retain(i8* %t62)
  call void @star_rc_release(i8* %t61)
  call i32 (i8*, ...) @printf(i8* %t61)
  br label %par_incr_20
par_incr_20:
  %t63 = add i64 %t50, 1
  store i64 %t63, i64* %t49
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
  %t64 = ptrtoint i8* %idx_arg to i64
  %t65 = trunc i64 %t64 to i32
  %t66 = call i32 @GetCurrentThreadId()
  %t67 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t65
  store i32 %t66, i32* %t67
  br label %loop
loop:
  %t68 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t65
  %t69 = load i8*, i8** %t68
  %t70 = call i32 @WaitForSingleObject(i8* %t69, i32 -1)
  %t71 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t65
  %t72 = load i32 (i8*)*, i32 (i8*)** %t71
  %t73 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t65
  %t74 = load i8*, i8** %t73
  %t75 = call i32 %t72(i8* %t74)
  %t76 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t65
  %t77 = load i8*, i8** %t76
  %t78 = call i32 @ReleaseSemaphore(i8* %t77, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t79 = load i1, i1* @par.pool.inited
  br i1 %t79, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t80 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t80, i8** @par.pool.serial_lock
  %t81 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t82 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t81, i8** %t82
  %t83 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t84 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t83, i8** %t84
  %t85 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t86 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t87 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t86, i8** %t87
  %t88 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t89 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t88, i8** %t89
  %t90 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t91 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t92 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t91, i8** %t92
  %t93 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t94 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t93, i8** %t94
  %t95 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t96 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t97 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t96, i8** %t97
  %t98 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t99 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t98, i8** %t99
  %t100 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
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
