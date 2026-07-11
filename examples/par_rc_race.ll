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
  %t97 = call i32 @GetCurrentThreadId()
  %t98 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t99 = load i32, i32* %t98
  %t100 = icmp eq i32 %t97, %t99
  %t101 = select i1 %t100, i32 0, i32 -1
  %t102 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t103 = load i32, i32* %t102
  %t104 = icmp eq i32 %t97, %t103
  %t105 = select i1 %t104, i32 1, i32 %t101
  %t106 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t107 = load i32, i32* %t106
  %t108 = icmp eq i32 %t97, %t107
  %t109 = select i1 %t108, i32 2, i32 %t105
  %t110 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t111 = load i32, i32* %t110
  %t112 = icmp eq i32 %t97, %t111
  %t113 = select i1 %t112, i32 3, i32 %t109
  %t114 = icmp sge i32 %t113, 0
  br i1 %t114, label %par_serial_21, label %par_pooled_20
par_pooled_20:
  %t115 = load i64, i64* @arena.Enemies.count
  %t116 = mul i64 %t115, 0
  %t117 = sdiv i64 %t116, 4
  %t118 = mul i64 %t115, 1
  %t119 = sdiv i64 %t118, 4
  %t120 = alloca { i64, i64, i8**, i32* }
  %t121 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t120, i32 0, i32 0
  store i64 %t117, i64* %t121
  %t122 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t120, i32 0, i32 1
  store i64 %t119, i64* %t122
  %t123 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t120, i32 0, i32 2
  store i8** %t0, i8*** %t123
  %t124 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t120, i32 0, i32 3
  store i32* %t36, i32** %t124
  %t125 = bitcast { i64, i64, i8**, i32* }* %t120 to i8*
  %t126 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t125, i8** %t126
  %t127 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t127
  %t128 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t129 = load i8*, i8** %t128
  %t130 = call i32 @ReleaseSemaphore(i8* %t129, i32 1, i32* null)
  %t131 = mul i64 %t115, 1
  %t132 = sdiv i64 %t131, 4
  %t133 = mul i64 %t115, 2
  %t134 = sdiv i64 %t133, 4
  %t135 = alloca { i64, i64, i8**, i32* }
  %t136 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t135, i32 0, i32 0
  store i64 %t132, i64* %t136
  %t137 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t135, i32 0, i32 1
  store i64 %t134, i64* %t137
  %t138 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t135, i32 0, i32 2
  store i8** %t0, i8*** %t138
  %t139 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t135, i32 0, i32 3
  store i32* %t36, i32** %t139
  %t140 = bitcast { i64, i64, i8**, i32* }* %t135 to i8*
  %t141 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t140, i8** %t141
  %t142 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t142
  %t143 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t144 = load i8*, i8** %t143
  %t145 = call i32 @ReleaseSemaphore(i8* %t144, i32 1, i32* null)
  %t146 = mul i64 %t115, 2
  %t147 = sdiv i64 %t146, 4
  %t148 = mul i64 %t115, 3
  %t149 = sdiv i64 %t148, 4
  %t150 = alloca { i64, i64, i8**, i32* }
  %t151 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t150, i32 0, i32 0
  store i64 %t147, i64* %t151
  %t152 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t150, i32 0, i32 1
  store i64 %t149, i64* %t152
  %t153 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t150, i32 0, i32 2
  store i8** %t0, i8*** %t153
  %t154 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t150, i32 0, i32 3
  store i32* %t36, i32** %t154
  %t155 = bitcast { i64, i64, i8**, i32* }* %t150 to i8*
  %t156 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t155, i8** %t156
  %t157 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t157
  %t158 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t159 = load i8*, i8** %t158
  %t160 = call i32 @ReleaseSemaphore(i8* %t159, i32 1, i32* null)
  %t161 = mul i64 %t115, 3
  %t162 = sdiv i64 %t161, 4
  %t163 = mul i64 %t115, 4
  %t164 = sdiv i64 %t163, 4
  %t165 = alloca { i64, i64, i8**, i32* }
  %t166 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t165, i32 0, i32 0
  store i64 %t162, i64* %t166
  %t167 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t165, i32 0, i32 1
  store i64 %t164, i64* %t167
  %t168 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t165, i32 0, i32 2
  store i8** %t0, i8*** %t168
  %t169 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t165, i32 0, i32 3
  store i32* %t36, i32** %t169
  %t170 = bitcast { i64, i64, i8**, i32* }* %t165 to i8*
  %t171 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t170, i8** %t171
  %t172 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t172
  %t173 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t174 = load i8*, i8** %t173
  %t175 = call i32 @ReleaseSemaphore(i8* %t174, i32 1, i32* null)
  %t176 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t177 = load i8*, i8** %t176
  %t178 = call i32 @WaitForSingleObject(i8* %t177, i32 -1)
  %t179 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t180 = load i8*, i8** %t179
  %t181 = call i32 @WaitForSingleObject(i8* %t180, i32 -1)
  %t182 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t183 = load i8*, i8** %t182
  %t184 = call i32 @WaitForSingleObject(i8* %t183, i32 -1)
  %t185 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t186 = load i8*, i8** %t185
  %t187 = call i32 @WaitForSingleObject(i8* %t186, i32 -1)
  br label %par_join_25
par_serial_21:
  %t188 = load i32, i32* @par.pool.serial_owner
  %t189 = icmp eq i32 %t188, %t113
  br i1 %t189, label %par_run_23, label %par_acquire_22
par_acquire_22:
  %t190 = load i8*, i8** @par.pool.serial_lock
  %t191 = call i32 @WaitForSingleObject(i8* %t190, i32 -1)
  store i32 %t113, i32* @par.pool.serial_owner
  br label %par_run_23
par_run_23:
  %t192 = load i64, i64* @arena.Enemies.count
  %t193 = alloca { i64, i64, i8**, i32* }
  %t194 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t193, i32 0, i32 0
  store i64 0, i64* %t194
  %t195 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t193, i32 0, i32 1
  store i64 %t192, i64* %t195
  %t196 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t193, i32 0, i32 2
  store i8** %t0, i8*** %t196
  %t197 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t193, i32 0, i32 3
  store i32* %t36, i32** %t197
  %t198 = bitcast { i64, i64, i8**, i32* }* %t193 to i8*
  %t199 = call i32 @par_worker_16(i8* %t198)
  br i1 %t189, label %par_join_25, label %par_release_24
par_release_24:
  store i32 -1, i32* @par.pool.serial_owner
  %t200 = load i8*, i8** @par.pool.serial_lock
  %t201 = call i32 @ReleaseSemaphore(i8* %t200, i32 1, i32* null)
  br label %par_join_25
par_join_25:
  br label %for_step_14
for_step_14:
  %t202 = load i32, i32* %t36
  %t203 = add i32 %t202, 1
  store i32 %t203, i32* %t36
  br label %for_cond_12
for_end_15:
  %t204 = load i8*, i8** %t0
  %t205 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t205)
  call void @star_rc_release(i8* %t204)
  %t206 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t206, i8* %t204)
  %t207 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t207)
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
  br i1 %t51, label %par_body_18, label %par_end_19
par_body_18:
  %t52 = getelementptr inbounds %Enemy, %Enemy* %t48, i64 %t50
  %t53 = getelementptr inbounds %Enemy, %Enemy* %t52, i32 0, i32 0
  %t54 = load i32, i32* %t53
  %t55 = sub i32 %t54, 1
  %t56 = getelementptr inbounds %Enemy, %Enemy* %t52, i32 0, i32 0
  store i32 %t55, i32* %t56
  %t57 = load i8*, i8** %t45
  %t58 = load i8*, i8** %t45
  call void @star_rc_retain(i8* %t58)
  call void @star_rc_release(i8* %t57)
  call i32 (i8*, ...) @printf(i8* %t57)
  %t59 = add i64 %t50, 1
  store i64 %t59, i64* %t49
  br label %par_cond_17
par_end_19:
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
  %t60 = ptrtoint i8* %idx_arg to i64
  %t61 = trunc i64 %t60 to i32
  %t62 = call i32 @GetCurrentThreadId()
  %t63 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t61
  store i32 %t62, i32* %t63
  br label %loop
loop:
  %t64 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t61
  %t65 = load i8*, i8** %t64
  %t66 = call i32 @WaitForSingleObject(i8* %t65, i32 -1)
  %t67 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t61
  %t68 = load i32 (i8*)*, i32 (i8*)** %t67
  %t69 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t61
  %t70 = load i8*, i8** %t69
  %t71 = call i32 %t68(i8* %t70)
  %t72 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t61
  %t73 = load i8*, i8** %t72
  %t74 = call i32 @ReleaseSemaphore(i8* %t73, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t75 = load i1, i1* @par.pool.inited
  br i1 %t75, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t76 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t76, i8** @par.pool.serial_lock
  %t77 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t78 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t77, i8** %t78
  %t79 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t80 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t79, i8** %t80
  %t81 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t82 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t83 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t82, i8** %t83
  %t84 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t85 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t84, i8** %t85
  %t86 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t87 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t88 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t87, i8** %t88
  %t89 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t90 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t89, i8** %t90
  %t91 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t92 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t93 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t92, i8** %t93
  %t94 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t95 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t94, i8** %t95
  %t96 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
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
