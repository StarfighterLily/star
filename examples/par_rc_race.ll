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
@arena.Enemies.gen = global [1024 x i32] zeroinitializer
@arena.Enemies.free = global [1024 x i64] zeroinitializer
@arena.Enemies.free_top = global i64 0

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca i8*
  %t10 = alloca i32
  %t31 = alloca %Enemy
  %t40 = alloca i32
  %t128 = alloca { i64, i64, i8**, i32* }
  %t143 = alloca { i64, i64, i8**, i32* }
  %t158 = alloca { i64, i64, i8**, i32* }
  %t173 = alloca { i64, i64, i8**, i32* }
  %t201 = alloca { i64, i64, i8**, i32* }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t2 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t3 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t4 = call i32 @strlen(i8* %t2)
  %t5 = call i32 @strlen(i8* %t3)
  %t6 = add i32 %t4, %t5
  %t7 = add i32 %t6, 1
  %t8 = sext i32 %t7 to i64
  %t9 = call i8* @star_rc_alloc(i64 %t8, i8* null)
  call i8* @strcpy(i8* %t9, i8* %t2)
  call i8* @strcat(i8* %t9, i8* %t3)
  call void @star_rc_release(i8* %t2)
  call void @star_rc_release(i8* %t3)
  store i8* %t9, i8** %t1
  store i32 0, i32* %t10
  br label %for_cond_0
for_cond_0:
  %t11 = load i32, i32* %t10
  %t12 = icmp slt i32 %t11, 16
  br i1 %t12, label %for_body_1, label %for_end_3
for_body_1:
  %t13 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t14 = icmp eq %Enemy* %t13, null
  br i1 %t14, label %spawn_init_4, label %spawn_ready_5
spawn_init_4:
  %t15 = getelementptr %Enemy, %Enemy* null, i32 1
  %t16 = ptrtoint %Enemy* %t15 to i64
  %t17 = mul i64 %t16, 1024
  %t18 = call i8* @malloc(i64 %t17)
  %t19 = bitcast i8* %t18 to %Enemy*
  store %Enemy* %t19, %Enemy** @arena.Enemies.data
  br label %spawn_ready_5
spawn_ready_5:
  %t20 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t21 = load i64, i64* @arena.Enemies.free_top
  %t22 = icmp sgt i64 %t21, 0
  br i1 %t22, label %spawn_reuse_6, label %spawn_grow_7
spawn_reuse_6:
  %t23 = sub i64 %t21, 1
  store i64 %t23, i64* @arena.Enemies.free_top
  %t24 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t23
  %t25 = load i64, i64* %t24
  br label %spawn_store_8
spawn_grow_7:
  %t26 = load i64, i64* @arena.Enemies.count
  %t27 = icmp slt i64 %t26, 1024
  br i1 %t27, label %spawn_grow_ok_10, label %spawn_capacity_warn_11
spawn_capacity_warn_11:
  %t28 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t28)
  br label %spawn_end_9
spawn_grow_ok_10:
  %t29 = add i64 %t26, 1
  store i64 %t29, i64* @arena.Enemies.count
  br label %spawn_store_8
spawn_store_8:
  %t30 = phi i64 [ %t25, %spawn_reuse_6 ], [ %t26, %spawn_grow_ok_10 ]
  %t32 = getelementptr inbounds %Enemy, %Enemy* %t31, i32 0, i32 0
  store i32 100, i32* %t32
  %t33 = load %Enemy, %Enemy* %t31
  %t34 = getelementptr inbounds %Enemy, %Enemy* %t20, i64 %t30
  store %Enemy %t33, %Enemy* %t34
  %t35 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t30
  %t36 = load i32, i32* %t35
  %t37 = add i32 %t36, 1
  store i32 %t37, i32* %t35
  br label %spawn_end_9
spawn_end_9:
  br label %for_step_2
for_step_2:
  %t38 = load i32, i32* %t10
  %t39 = add i32 %t38, 1
  store i32 %t39, i32* %t10
  br label %for_cond_0
for_end_3:
  store i32 0, i32* %t40
  br label %for_cond_12
for_cond_12:
  %t41 = load i32, i32* %t40
  %t42 = icmp slt i32 %t41, 400
  br i1 %t42, label %for_body_13, label %for_end_15
for_body_13:
  call void @par.pool.ensure_init()
  %t105 = call i32 @GetCurrentThreadId()
  %t106 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t107 = load i32, i32* %t106
  %t108 = icmp eq i32 %t105, %t107
  %t109 = select i1 %t108, i32 0, i32 -1
  %t110 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t111 = load i32, i32* %t110
  %t112 = icmp eq i32 %t105, %t111
  %t113 = select i1 %t112, i32 1, i32 %t109
  %t114 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t115 = load i32, i32* %t114
  %t116 = icmp eq i32 %t105, %t115
  %t117 = select i1 %t116, i32 2, i32 %t113
  %t118 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t119 = load i32, i32* %t118
  %t120 = icmp eq i32 %t105, %t119
  %t121 = select i1 %t120, i32 3, i32 %t117
  %t122 = icmp sge i32 %t121, 0
  br i1 %t122, label %par_serial_23, label %par_pooled_22
par_pooled_22:
  %t123 = load i64, i64* @arena.Enemies.count
  %t124 = mul i64 %t123, 0
  %t125 = sdiv i64 %t124, 4
  %t126 = mul i64 %t123, 1
  %t127 = sdiv i64 %t126, 4
  %t129 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t128, i32 0, i32 0
  store i64 %t125, i64* %t129
  %t130 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t128, i32 0, i32 1
  store i64 %t127, i64* %t130
  %t131 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t128, i32 0, i32 2
  store i8** %t1, i8*** %t131
  %t132 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t128, i32 0, i32 3
  store i32* %t40, i32** %t132
  %t133 = bitcast { i64, i64, i8**, i32* }* %t128 to i8*
  %t134 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t133, i8** %t134
  %t135 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t135
  %t136 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t137 = load i8*, i8** %t136
  %t138 = call i32 @ReleaseSemaphore(i8* %t137, i32 1, i32* null)
  %t139 = mul i64 %t123, 1
  %t140 = sdiv i64 %t139, 4
  %t141 = mul i64 %t123, 2
  %t142 = sdiv i64 %t141, 4
  %t144 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t143, i32 0, i32 0
  store i64 %t140, i64* %t144
  %t145 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t143, i32 0, i32 1
  store i64 %t142, i64* %t145
  %t146 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t143, i32 0, i32 2
  store i8** %t1, i8*** %t146
  %t147 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t143, i32 0, i32 3
  store i32* %t40, i32** %t147
  %t148 = bitcast { i64, i64, i8**, i32* }* %t143 to i8*
  %t149 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t148, i8** %t149
  %t150 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t150
  %t151 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t152 = load i8*, i8** %t151
  %t153 = call i32 @ReleaseSemaphore(i8* %t152, i32 1, i32* null)
  %t154 = mul i64 %t123, 2
  %t155 = sdiv i64 %t154, 4
  %t156 = mul i64 %t123, 3
  %t157 = sdiv i64 %t156, 4
  %t159 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t158, i32 0, i32 0
  store i64 %t155, i64* %t159
  %t160 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t158, i32 0, i32 1
  store i64 %t157, i64* %t160
  %t161 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t158, i32 0, i32 2
  store i8** %t1, i8*** %t161
  %t162 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t158, i32 0, i32 3
  store i32* %t40, i32** %t162
  %t163 = bitcast { i64, i64, i8**, i32* }* %t158 to i8*
  %t164 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t163, i8** %t164
  %t165 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t165
  %t166 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t167 = load i8*, i8** %t166
  %t168 = call i32 @ReleaseSemaphore(i8* %t167, i32 1, i32* null)
  %t169 = mul i64 %t123, 3
  %t170 = sdiv i64 %t169, 4
  %t171 = mul i64 %t123, 4
  %t172 = sdiv i64 %t171, 4
  %t174 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t173, i32 0, i32 0
  store i64 %t170, i64* %t174
  %t175 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t173, i32 0, i32 1
  store i64 %t172, i64* %t175
  %t176 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t173, i32 0, i32 2
  store i8** %t1, i8*** %t176
  %t177 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t173, i32 0, i32 3
  store i32* %t40, i32** %t177
  %t178 = bitcast { i64, i64, i8**, i32* }* %t173 to i8*
  %t179 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t178, i8** %t179
  %t180 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t180
  %t181 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t182 = load i8*, i8** %t181
  %t183 = call i32 @ReleaseSemaphore(i8* %t182, i32 1, i32* null)
  %t184 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t185 = load i8*, i8** %t184
  %t186 = call i32 @WaitForSingleObject(i8* %t185, i32 -1)
  %t187 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t188 = load i8*, i8** %t187
  %t189 = call i32 @WaitForSingleObject(i8* %t188, i32 -1)
  %t190 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t191 = load i8*, i8** %t190
  %t192 = call i32 @WaitForSingleObject(i8* %t191, i32 -1)
  %t193 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t194 = load i8*, i8** %t193
  %t195 = call i32 @WaitForSingleObject(i8* %t194, i32 -1)
  br label %par_join_27
par_serial_23:
  %t196 = load i32, i32* @par.pool.serial_owner
  %t197 = icmp eq i32 %t196, %t121
  br i1 %t197, label %par_run_25, label %par_acquire_24
par_acquire_24:
  %t198 = load i8*, i8** @par.pool.serial_lock
  %t199 = call i32 @WaitForSingleObject(i8* %t198, i32 -1)
  store i32 %t121, i32* @par.pool.serial_owner
  br label %par_run_25
par_run_25:
  %t200 = load i64, i64* @arena.Enemies.count
  %t202 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t201, i32 0, i32 0
  store i64 0, i64* %t202
  %t203 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t201, i32 0, i32 1
  store i64 %t200, i64* %t203
  %t204 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t201, i32 0, i32 2
  store i8** %t1, i8*** %t204
  %t205 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t201, i32 0, i32 3
  store i32* %t40, i32** %t205
  %t206 = bitcast { i64, i64, i8**, i32* }* %t201 to i8*
  %t207 = call i32 @par_worker_16(i8* %t206)
  br i1 %t197, label %par_join_27, label %par_release_26
par_release_26:
  store i32 -1, i32* @par.pool.serial_owner
  %t208 = load i8*, i8** @par.pool.serial_lock
  %t209 = call i32 @ReleaseSemaphore(i8* %t208, i32 1, i32* null)
  br label %par_join_27
par_join_27:
  br label %for_step_14
for_step_14:
  %t210 = load i32, i32* %t40
  %t211 = add i32 %t210, 1
  store i32 %t211, i32* %t40
  br label %for_cond_12
for_end_15:
  %t212 = load i8*, i8** %t1
  %t213 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t213)
  call void @star_rc_release(i8* %t212)
  %t214 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t214, i8* %t212)
  %t215 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t215)
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_16(i8* %argp) {
entry:
  %t53 = alloca i64
  %t43 = bitcast i8* %argp to { i64, i64, i8**, i32* }*
  %t44 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t43, i32 0, i32 0
  %t45 = load i64, i64* %t44
  %t46 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t43, i32 0, i32 1
  %t47 = load i64, i64* %t46
  %t48 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t43, i32 0, i32 2
  %t49 = load i8**, i8*** %t48
  %t50 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t43, i32 0, i32 3
  %t51 = load i32*, i32** %t50
  %t52 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t45, i64* %t53
  br label %par_cond_17
par_cond_17:
  %t54 = load i64, i64* %t53
  %t55 = icmp slt i64 %t54, %t47
  br i1 %t55, label %par_body_18, label %par_end_21
par_body_18:
  %t56 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t54
  %t57 = load i32, i32* %t56
  %t58 = and i32 %t57, 1
  %t59 = icmp eq i32 %t58, 1
  br i1 %t59, label %par_live_19, label %par_incr_20
par_live_19:
  %t60 = getelementptr inbounds %Enemy, %Enemy* %t52, i64 %t54
  %t61 = getelementptr inbounds %Enemy, %Enemy* %t60, i32 0, i32 0
  %t62 = load i32, i32* %t61
  %t63 = sub i32 %t62, 1
  %t64 = getelementptr inbounds %Enemy, %Enemy* %t60, i32 0, i32 0
  store i32 %t63, i32* %t64
  %t65 = load i8*, i8** %t49
  %t66 = load i8*, i8** %t49
  call void @star_rc_retain(i8* %t66)
  call void @star_rc_release(i8* %t65)
  call i32 (i8*, ...) @printf(i8* %t65)
  br label %par_incr_20
par_incr_20:
  %t67 = add i64 %t54, 1
  store i64 %t67, i64* %t53
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
  %t68 = ptrtoint i8* %idx_arg to i64
  %t69 = trunc i64 %t68 to i32
  %t70 = call i32 @GetCurrentThreadId()
  %t71 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t69
  store i32 %t70, i32* %t71
  br label %loop
loop:
  %t72 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t69
  %t73 = load i8*, i8** %t72
  %t74 = call i32 @WaitForSingleObject(i8* %t73, i32 -1)
  %t75 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t69
  %t76 = load i32 (i8*)*, i32 (i8*)** %t75
  %t77 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t69
  %t78 = load i8*, i8** %t77
  %t79 = call i32 %t76(i8* %t78)
  %t80 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t69
  %t81 = load i8*, i8** %t80
  %t82 = call i32 @ReleaseSemaphore(i8* %t81, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t83 = load i1, i1* @par.pool.inited
  br i1 %t83, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t84 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t84, i8** @par.pool.serial_lock
  %t85 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t86 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t85, i8** %t86
  %t87 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t88 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t87, i8** %t88
  %t89 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t90 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t91 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t90, i8** %t91
  %t92 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t93 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t92, i8** %t93
  %t94 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t95 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t96 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t95, i8** %t96
  %t97 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t98 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t97, i8** %t98
  %t99 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t100 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t101 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t100, i8** %t101
  %t102 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t103 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t102, i8** %t103
  %t104 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
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
