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

%GenRef = type { i32, i64 }

@frame.buf = global [4096 x i8] zeroinitializer
@frame.off = global i64 0

@star.argc = global i32 0
@star.argv = global i8** null

@rng.state = global i32 123456789
@rng.lock = global i8* null

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
@arena.Enemies.gen = global [1024 x i64] zeroinitializer
@arena.Enemies.free = global [1024 x i64] zeroinitializer
@arena.Enemies.free_top = global i64 0

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca i8*
  %t11 = alloca i32
  %t32 = alloca %Enemy
  %t41 = alloca i32
  %t129 = alloca { i64, i64, i8**, i32* }
  %t144 = alloca { i64, i64, i8**, i32* }
  %t159 = alloca { i64, i64, i8**, i32* }
  %t174 = alloca { i64, i64, i8**, i32* }
  %t202 = alloca { i64, i64, i8**, i32* }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t4 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t5 = call i32 @strlen(i8* %t3)
  %t6 = call i32 @strlen(i8* %t4)
  %t7 = add i32 %t5, %t6
  %t8 = add i32 %t7, 1
  %t9 = sext i32 %t8 to i64
  %t10 = call i8* @star_rc_alloc(i64 %t9, i8* null)
  call i8* @strcpy(i8* %t10, i8* %t3)
  call i8* @strcat(i8* %t10, i8* %t4)
  call void @star_rc_release(i8* %t3)
  call void @star_rc_release(i8* %t4)
  store i8* %t10, i8** %t2
  store i32 0, i32* %t11
  br label %for_cond_0
for_cond_0:
  %t12 = load i32, i32* %t11
  %t13 = icmp slt i32 %t12, 16
  br i1 %t13, label %for_body_1, label %for_end_3
for_body_1:
  %t14 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t15 = icmp eq %Enemy* %t14, null
  br i1 %t15, label %spawn_init_4, label %spawn_ready_5
spawn_init_4:
  %t16 = getelementptr %Enemy, %Enemy* null, i32 1
  %t17 = ptrtoint %Enemy* %t16 to i64
  %t18 = mul i64 %t17, 1024
  %t19 = call i8* @malloc(i64 %t18)
  %t20 = bitcast i8* %t19 to %Enemy*
  store %Enemy* %t20, %Enemy** @arena.Enemies.data
  br label %spawn_ready_5
spawn_ready_5:
  %t21 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t22 = load i64, i64* @arena.Enemies.free_top
  %t23 = icmp sgt i64 %t22, 0
  br i1 %t23, label %spawn_reuse_6, label %spawn_grow_7
spawn_reuse_6:
  %t24 = sub i64 %t22, 1
  store i64 %t24, i64* @arena.Enemies.free_top
  %t25 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t24
  %t26 = load i64, i64* %t25
  br label %spawn_store_8
spawn_grow_7:
  %t27 = load i64, i64* @arena.Enemies.count
  %t28 = icmp slt i64 %t27, 1024
  br i1 %t28, label %spawn_grow_ok_10, label %spawn_capacity_warn_11
spawn_capacity_warn_11:
  %t29 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t29)
  br label %spawn_end_9
spawn_grow_ok_10:
  %t30 = add i64 %t27, 1
  store i64 %t30, i64* @arena.Enemies.count
  br label %spawn_store_8
spawn_store_8:
  %t31 = phi i64 [ %t26, %spawn_reuse_6 ], [ %t27, %spawn_grow_ok_10 ]
  %t33 = getelementptr inbounds %Enemy, %Enemy* %t32, i32 0, i32 0
  store i32 100, i32* %t33
  %t34 = load %Enemy, %Enemy* %t32
  %t35 = getelementptr inbounds %Enemy, %Enemy* %t21, i64 %t31
  store %Enemy %t34, %Enemy* %t35
  %t36 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t31
  %t37 = load i64, i64* %t36
  %t38 = add i64 %t37, 1
  store i64 %t38, i64* %t36
  br label %spawn_end_9
spawn_end_9:
  br label %for_step_2
for_step_2:
  %t39 = load i32, i32* %t11
  %t40 = add i32 %t39, 1
  store i32 %t40, i32* %t11
  br label %for_cond_0
for_end_3:
  store i32 0, i32* %t41
  br label %for_cond_12
for_cond_12:
  %t42 = load i32, i32* %t41
  %t43 = icmp slt i32 %t42, 400
  br i1 %t43, label %for_body_13, label %for_end_15
for_body_13:
  call void @par.pool.ensure_init()
  %t106 = call i32 @GetCurrentThreadId()
  %t107 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t108 = load i32, i32* %t107
  %t109 = icmp eq i32 %t106, %t108
  %t110 = select i1 %t109, i32 0, i32 -1
  %t111 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t112 = load i32, i32* %t111
  %t113 = icmp eq i32 %t106, %t112
  %t114 = select i1 %t113, i32 1, i32 %t110
  %t115 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t116 = load i32, i32* %t115
  %t117 = icmp eq i32 %t106, %t116
  %t118 = select i1 %t117, i32 2, i32 %t114
  %t119 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t120 = load i32, i32* %t119
  %t121 = icmp eq i32 %t106, %t120
  %t122 = select i1 %t121, i32 3, i32 %t118
  %t123 = icmp sge i32 %t122, 0
  br i1 %t123, label %par_serial_23, label %par_pooled_22
par_pooled_22:
  %t124 = load i64, i64* @arena.Enemies.count
  %t125 = mul i64 %t124, 0
  %t126 = sdiv i64 %t125, 4
  %t127 = mul i64 %t124, 1
  %t128 = sdiv i64 %t127, 4
  %t130 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t129, i32 0, i32 0
  store i64 %t126, i64* %t130
  %t131 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t129, i32 0, i32 1
  store i64 %t128, i64* %t131
  %t132 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t129, i32 0, i32 2
  store i8** %t2, i8*** %t132
  %t133 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t129, i32 0, i32 3
  store i32* %t41, i32** %t133
  %t134 = bitcast { i64, i64, i8**, i32* }* %t129 to i8*
  %t135 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t134, i8** %t135
  %t136 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t136
  %t137 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t138 = load i8*, i8** %t137
  %t139 = call i32 @ReleaseSemaphore(i8* %t138, i32 1, i32* null)
  %t140 = mul i64 %t124, 1
  %t141 = sdiv i64 %t140, 4
  %t142 = mul i64 %t124, 2
  %t143 = sdiv i64 %t142, 4
  %t145 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t144, i32 0, i32 0
  store i64 %t141, i64* %t145
  %t146 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t144, i32 0, i32 1
  store i64 %t143, i64* %t146
  %t147 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t144, i32 0, i32 2
  store i8** %t2, i8*** %t147
  %t148 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t144, i32 0, i32 3
  store i32* %t41, i32** %t148
  %t149 = bitcast { i64, i64, i8**, i32* }* %t144 to i8*
  %t150 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t149, i8** %t150
  %t151 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t151
  %t152 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t153 = load i8*, i8** %t152
  %t154 = call i32 @ReleaseSemaphore(i8* %t153, i32 1, i32* null)
  %t155 = mul i64 %t124, 2
  %t156 = sdiv i64 %t155, 4
  %t157 = mul i64 %t124, 3
  %t158 = sdiv i64 %t157, 4
  %t160 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t159, i32 0, i32 0
  store i64 %t156, i64* %t160
  %t161 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t159, i32 0, i32 1
  store i64 %t158, i64* %t161
  %t162 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t159, i32 0, i32 2
  store i8** %t2, i8*** %t162
  %t163 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t159, i32 0, i32 3
  store i32* %t41, i32** %t163
  %t164 = bitcast { i64, i64, i8**, i32* }* %t159 to i8*
  %t165 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t164, i8** %t165
  %t166 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t166
  %t167 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t168 = load i8*, i8** %t167
  %t169 = call i32 @ReleaseSemaphore(i8* %t168, i32 1, i32* null)
  %t170 = mul i64 %t124, 3
  %t171 = sdiv i64 %t170, 4
  %t172 = mul i64 %t124, 4
  %t173 = sdiv i64 %t172, 4
  %t175 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t174, i32 0, i32 0
  store i64 %t171, i64* %t175
  %t176 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t174, i32 0, i32 1
  store i64 %t173, i64* %t176
  %t177 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t174, i32 0, i32 2
  store i8** %t2, i8*** %t177
  %t178 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t174, i32 0, i32 3
  store i32* %t41, i32** %t178
  %t179 = bitcast { i64, i64, i8**, i32* }* %t174 to i8*
  %t180 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t179, i8** %t180
  %t181 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t181
  %t182 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t183 = load i8*, i8** %t182
  %t184 = call i32 @ReleaseSemaphore(i8* %t183, i32 1, i32* null)
  %t185 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t186 = load i8*, i8** %t185
  %t187 = call i32 @WaitForSingleObject(i8* %t186, i32 -1)
  %t188 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t189 = load i8*, i8** %t188
  %t190 = call i32 @WaitForSingleObject(i8* %t189, i32 -1)
  %t191 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t192 = load i8*, i8** %t191
  %t193 = call i32 @WaitForSingleObject(i8* %t192, i32 -1)
  %t194 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t195 = load i8*, i8** %t194
  %t196 = call i32 @WaitForSingleObject(i8* %t195, i32 -1)
  br label %par_join_27
par_serial_23:
  %t197 = load i32, i32* @par.pool.serial_owner
  %t198 = icmp eq i32 %t197, %t122
  br i1 %t198, label %par_run_25, label %par_acquire_24
par_acquire_24:
  %t199 = load i8*, i8** @par.pool.serial_lock
  %t200 = call i32 @WaitForSingleObject(i8* %t199, i32 -1)
  store i32 %t122, i32* @par.pool.serial_owner
  br label %par_run_25
par_run_25:
  %t201 = load i64, i64* @arena.Enemies.count
  %t203 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t202, i32 0, i32 0
  store i64 0, i64* %t203
  %t204 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t202, i32 0, i32 1
  store i64 %t201, i64* %t204
  %t205 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t202, i32 0, i32 2
  store i8** %t2, i8*** %t205
  %t206 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t202, i32 0, i32 3
  store i32* %t41, i32** %t206
  %t207 = bitcast { i64, i64, i8**, i32* }* %t202 to i8*
  %t208 = call i32 @par_worker_16(i8* %t207)
  br i1 %t198, label %par_join_27, label %par_release_26
par_release_26:
  store i32 -1, i32* @par.pool.serial_owner
  %t209 = load i8*, i8** @par.pool.serial_lock
  %t210 = call i32 @ReleaseSemaphore(i8* %t209, i32 1, i32* null)
  br label %par_join_27
par_join_27:
  br label %for_step_14
for_step_14:
  %t211 = load i32, i32* %t41
  %t212 = add i32 %t211, 1
  store i32 %t212, i32* %t41
  br label %for_cond_12
for_end_15:
  %t213 = load i8*, i8** %t2
  %t214 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t214)
  call void @star_rc_release(i8* %t213)
  %t215 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t215, i8* %t213)
  %t216 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t216)
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_16(i8* %argp) {
entry:
  %t54 = alloca i64
  %t44 = bitcast i8* %argp to { i64, i64, i8**, i32* }*
  %t45 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t44, i32 0, i32 0
  %t46 = load i64, i64* %t45
  %t47 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t44, i32 0, i32 1
  %t48 = load i64, i64* %t47
  %t49 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t44, i32 0, i32 2
  %t50 = load i8**, i8*** %t49
  %t51 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t44, i32 0, i32 3
  %t52 = load i32*, i32** %t51
  %t53 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t46, i64* %t54
  br label %par_cond_17
par_cond_17:
  %t55 = load i64, i64* %t54
  %t56 = icmp slt i64 %t55, %t48
  br i1 %t56, label %par_body_18, label %par_end_21
par_body_18:
  %t57 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t55
  %t58 = load i64, i64* %t57
  %t59 = and i64 %t58, 1
  %t60 = icmp eq i64 %t59, 1
  br i1 %t60, label %par_live_19, label %par_incr_20
par_live_19:
  %t61 = getelementptr inbounds %Enemy, %Enemy* %t53, i64 %t55
  %t62 = getelementptr inbounds %Enemy, %Enemy* %t61, i32 0, i32 0
  %t63 = load i32, i32* %t62
  %t64 = sub i32 %t63, 1
  %t65 = getelementptr inbounds %Enemy, %Enemy* %t61, i32 0, i32 0
  store i32 %t64, i32* %t65
  %t66 = load i8*, i8** %t50
  %t67 = load i8*, i8** %t50
  call void @star_rc_retain(i8* %t67)
  call void @star_rc_release(i8* %t66)
  call i32 (i8*, ...) @printf(i8* %t66)
  br label %par_incr_20
par_incr_20:
  %t68 = add i64 %t55, 1
  store i64 %t68, i64* %t54
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
  %t69 = ptrtoint i8* %idx_arg to i64
  %t70 = trunc i64 %t69 to i32
  %t71 = call i32 @GetCurrentThreadId()
  %t72 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t70
  store i32 %t71, i32* %t72
  br label %loop
loop:
  %t73 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t70
  %t74 = load i8*, i8** %t73
  %t75 = call i32 @WaitForSingleObject(i8* %t74, i32 -1)
  %t76 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t70
  %t77 = load i32 (i8*)*, i32 (i8*)** %t76
  %t78 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t70
  %t79 = load i8*, i8** %t78
  %t80 = call i32 %t77(i8* %t79)
  %t81 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t70
  %t82 = load i8*, i8** %t81
  %t83 = call i32 @ReleaseSemaphore(i8* %t82, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t84 = load i1, i1* @par.pool.inited
  br i1 %t84, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t85 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t85, i8** @par.pool.serial_lock
  %t86 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t87 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t86, i8** %t87
  %t88 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t89 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t88, i8** %t89
  %t90 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t91 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t92 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t91, i8** %t92
  %t93 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t94 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t93, i8** %t94
  %t95 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t96 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t97 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t96, i8** %t97
  %t98 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t99 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t98, i8** %t99
  %t100 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t101 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t102 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t101, i8** %t102
  %t103 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t104 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t103, i8** %t104
  %t105 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
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
