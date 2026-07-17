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
  %t20 = alloca %Enemy
  %t45 = alloca %Enemy
  %t70 = alloca %Enemy
  %t156 = alloca { i64, i64 }
  %t169 = alloca { i64, i64 }
  %t182 = alloca { i64, i64 }
  %t195 = alloca { i64, i64 }
  %t221 = alloca { i64, i64 }
  %t269 = alloca { i64, i64 }
  %t282 = alloca { i64, i64 }
  %t295 = alloca { i64, i64 }
  %t308 = alloca { i64, i64 }
  %t334 = alloca { i64, i64 }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t2 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t3 = icmp eq %Enemy* %t2, null
  br i1 %t3, label %spawn_init_0, label %spawn_ready_1
spawn_init_0:
  %t4 = getelementptr %Enemy, %Enemy* null, i32 1
  %t5 = ptrtoint %Enemy* %t4 to i64
  %t6 = mul i64 %t5, 1024
  %t7 = call i8* @malloc(i64 %t6)
  %t8 = bitcast i8* %t7 to %Enemy*
  store %Enemy* %t8, %Enemy** @arena.Enemies.data
  br label %spawn_ready_1
spawn_ready_1:
  %t9 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t10 = load i64, i64* @arena.Enemies.free_top
  %t11 = icmp sgt i64 %t10, 0
  br i1 %t11, label %spawn_reuse_2, label %spawn_grow_3
spawn_reuse_2:
  %t12 = sub i64 %t10, 1
  store i64 %t12, i64* @arena.Enemies.free_top
  %t13 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t12
  %t14 = load i64, i64* %t13
  br label %spawn_store_4
spawn_grow_3:
  %t15 = load i64, i64* @arena.Enemies.count
  %t16 = icmp slt i64 %t15, 1024
  br i1 %t16, label %spawn_grow_ok_6, label %spawn_capacity_warn_7
spawn_capacity_warn_7:
  %t17 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t17)
  br label %spawn_end_5
spawn_grow_ok_6:
  %t18 = add i64 %t15, 1
  store i64 %t18, i64* @arena.Enemies.count
  br label %spawn_store_4
spawn_store_4:
  %t19 = phi i64 [ %t14, %spawn_reuse_2 ], [ %t15, %spawn_grow_ok_6 ]
  %t21 = getelementptr inbounds %Enemy, %Enemy* %t20, i32 0, i32 0
  store i32 10, i32* %t21
  %t22 = load %Enemy, %Enemy* %t20
  %t23 = getelementptr inbounds %Enemy, %Enemy* %t9, i64 %t19
  store %Enemy %t22, %Enemy* %t23
  %t24 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t19
  %t25 = load i64, i64* %t24
  %t26 = add i64 %t25, 1
  store i64 %t26, i64* %t24
  br label %spawn_end_5
spawn_end_5:
  %t27 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t28 = icmp eq %Enemy* %t27, null
  br i1 %t28, label %spawn_init_8, label %spawn_ready_9
spawn_init_8:
  %t29 = getelementptr %Enemy, %Enemy* null, i32 1
  %t30 = ptrtoint %Enemy* %t29 to i64
  %t31 = mul i64 %t30, 1024
  %t32 = call i8* @malloc(i64 %t31)
  %t33 = bitcast i8* %t32 to %Enemy*
  store %Enemy* %t33, %Enemy** @arena.Enemies.data
  br label %spawn_ready_9
spawn_ready_9:
  %t34 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t35 = load i64, i64* @arena.Enemies.free_top
  %t36 = icmp sgt i64 %t35, 0
  br i1 %t36, label %spawn_reuse_10, label %spawn_grow_11
spawn_reuse_10:
  %t37 = sub i64 %t35, 1
  store i64 %t37, i64* @arena.Enemies.free_top
  %t38 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t37
  %t39 = load i64, i64* %t38
  br label %spawn_store_12
spawn_grow_11:
  %t40 = load i64, i64* @arena.Enemies.count
  %t41 = icmp slt i64 %t40, 1024
  br i1 %t41, label %spawn_grow_ok_14, label %spawn_capacity_warn_15
spawn_capacity_warn_15:
  %t42 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t42)
  br label %spawn_end_13
spawn_grow_ok_14:
  %t43 = add i64 %t40, 1
  store i64 %t43, i64* @arena.Enemies.count
  br label %spawn_store_12
spawn_store_12:
  %t44 = phi i64 [ %t39, %spawn_reuse_10 ], [ %t40, %spawn_grow_ok_14 ]
  %t46 = getelementptr inbounds %Enemy, %Enemy* %t45, i32 0, i32 0
  store i32 20, i32* %t46
  %t47 = load %Enemy, %Enemy* %t45
  %t48 = getelementptr inbounds %Enemy, %Enemy* %t34, i64 %t44
  store %Enemy %t47, %Enemy* %t48
  %t49 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t44
  %t50 = load i64, i64* %t49
  %t51 = add i64 %t50, 1
  store i64 %t51, i64* %t49
  br label %spawn_end_13
spawn_end_13:
  %t52 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t53 = icmp eq %Enemy* %t52, null
  br i1 %t53, label %spawn_init_16, label %spawn_ready_17
spawn_init_16:
  %t54 = getelementptr %Enemy, %Enemy* null, i32 1
  %t55 = ptrtoint %Enemy* %t54 to i64
  %t56 = mul i64 %t55, 1024
  %t57 = call i8* @malloc(i64 %t56)
  %t58 = bitcast i8* %t57 to %Enemy*
  store %Enemy* %t58, %Enemy** @arena.Enemies.data
  br label %spawn_ready_17
spawn_ready_17:
  %t59 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t60 = load i64, i64* @arena.Enemies.free_top
  %t61 = icmp sgt i64 %t60, 0
  br i1 %t61, label %spawn_reuse_18, label %spawn_grow_19
spawn_reuse_18:
  %t62 = sub i64 %t60, 1
  store i64 %t62, i64* @arena.Enemies.free_top
  %t63 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t62
  %t64 = load i64, i64* %t63
  br label %spawn_store_20
spawn_grow_19:
  %t65 = load i64, i64* @arena.Enemies.count
  %t66 = icmp slt i64 %t65, 1024
  br i1 %t66, label %spawn_grow_ok_22, label %spawn_capacity_warn_23
spawn_capacity_warn_23:
  %t67 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t67)
  br label %spawn_end_21
spawn_grow_ok_22:
  %t68 = add i64 %t65, 1
  store i64 %t68, i64* @arena.Enemies.count
  br label %spawn_store_20
spawn_store_20:
  %t69 = phi i64 [ %t64, %spawn_reuse_18 ], [ %t65, %spawn_grow_ok_22 ]
  %t71 = getelementptr inbounds %Enemy, %Enemy* %t70, i32 0, i32 0
  store i32 30, i32* %t71
  %t72 = load %Enemy, %Enemy* %t70
  %t73 = getelementptr inbounds %Enemy, %Enemy* %t59, i64 %t69
  store %Enemy %t72, %Enemy* %t73
  %t74 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t69
  %t75 = load i64, i64* %t74
  %t76 = add i64 %t75, 1
  store i64 %t76, i64* %t74
  br label %spawn_end_21
spawn_end_21:
  call void @par.pool.ensure_init()
  %t133 = call i32 @GetCurrentThreadId()
  %t134 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t135 = load i32, i32* %t134
  %t136 = icmp eq i32 %t133, %t135
  %t137 = select i1 %t136, i32 0, i32 -1
  %t138 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t139 = load i32, i32* %t138
  %t140 = icmp eq i32 %t133, %t139
  %t141 = select i1 %t140, i32 1, i32 %t137
  %t142 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t143 = load i32, i32* %t142
  %t144 = icmp eq i32 %t133, %t143
  %t145 = select i1 %t144, i32 2, i32 %t141
  %t146 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t147 = load i32, i32* %t146
  %t148 = icmp eq i32 %t133, %t147
  %t149 = select i1 %t148, i32 3, i32 %t145
  %t150 = icmp sge i32 %t149, 0
  br i1 %t150, label %par_serial_31, label %par_pooled_30
par_pooled_30:
  %t151 = load i64, i64* @arena.Enemies.count
  %t152 = mul i64 %t151, 0
  %t153 = sdiv i64 %t152, 4
  %t154 = mul i64 %t151, 1
  %t155 = sdiv i64 %t154, 4
  %t157 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t156, i32 0, i32 0
  store i64 %t153, i64* %t157
  %t158 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t156, i32 0, i32 1
  store i64 %t155, i64* %t158
  %t159 = bitcast { i64, i64 }* %t156 to i8*
  %t160 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t159, i8** %t160
  %t161 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t161
  %t162 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t163 = load i8*, i8** %t162
  %t164 = call i32 @ReleaseSemaphore(i8* %t163, i32 1, i32* null)
  %t165 = mul i64 %t151, 1
  %t166 = sdiv i64 %t165, 4
  %t167 = mul i64 %t151, 2
  %t168 = sdiv i64 %t167, 4
  %t170 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t169, i32 0, i32 0
  store i64 %t166, i64* %t170
  %t171 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t169, i32 0, i32 1
  store i64 %t168, i64* %t171
  %t172 = bitcast { i64, i64 }* %t169 to i8*
  %t173 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t172, i8** %t173
  %t174 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t174
  %t175 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t176 = load i8*, i8** %t175
  %t177 = call i32 @ReleaseSemaphore(i8* %t176, i32 1, i32* null)
  %t178 = mul i64 %t151, 2
  %t179 = sdiv i64 %t178, 4
  %t180 = mul i64 %t151, 3
  %t181 = sdiv i64 %t180, 4
  %t183 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t182, i32 0, i32 0
  store i64 %t179, i64* %t183
  %t184 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t182, i32 0, i32 1
  store i64 %t181, i64* %t184
  %t185 = bitcast { i64, i64 }* %t182 to i8*
  %t186 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t185, i8** %t186
  %t187 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t187
  %t188 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t189 = load i8*, i8** %t188
  %t190 = call i32 @ReleaseSemaphore(i8* %t189, i32 1, i32* null)
  %t191 = mul i64 %t151, 3
  %t192 = sdiv i64 %t191, 4
  %t193 = mul i64 %t151, 4
  %t194 = sdiv i64 %t193, 4
  %t196 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t195, i32 0, i32 0
  store i64 %t192, i64* %t196
  %t197 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t195, i32 0, i32 1
  store i64 %t194, i64* %t197
  %t198 = bitcast { i64, i64 }* %t195 to i8*
  %t199 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t198, i8** %t199
  %t200 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t200
  %t201 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t202 = load i8*, i8** %t201
  %t203 = call i32 @ReleaseSemaphore(i8* %t202, i32 1, i32* null)
  %t204 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t205 = load i8*, i8** %t204
  %t206 = call i32 @WaitForSingleObject(i8* %t205, i32 -1)
  %t207 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t208 = load i8*, i8** %t207
  %t209 = call i32 @WaitForSingleObject(i8* %t208, i32 -1)
  %t210 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t211 = load i8*, i8** %t210
  %t212 = call i32 @WaitForSingleObject(i8* %t211, i32 -1)
  %t213 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t214 = load i8*, i8** %t213
  %t215 = call i32 @WaitForSingleObject(i8* %t214, i32 -1)
  br label %par_join_35
par_serial_31:
  %t216 = load i32, i32* @par.pool.serial_owner
  %t217 = icmp eq i32 %t216, %t149
  br i1 %t217, label %par_run_33, label %par_acquire_32
par_acquire_32:
  %t218 = load i8*, i8** @par.pool.serial_lock
  %t219 = call i32 @WaitForSingleObject(i8* %t218, i32 -1)
  store i32 %t149, i32* @par.pool.serial_owner
  br label %par_run_33
par_run_33:
  %t220 = load i64, i64* @arena.Enemies.count
  %t222 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t221, i32 0, i32 0
  store i64 0, i64* %t222
  %t223 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t221, i32 0, i32 1
  store i64 %t220, i64* %t223
  %t224 = bitcast { i64, i64 }* %t221 to i8*
  %t225 = call i32 @par_worker_24(i8* %t224)
  br i1 %t217, label %par_join_35, label %par_release_34
par_release_34:
  store i32 -1, i32* @par.pool.serial_owner
  %t226 = load i8*, i8** @par.pool.serial_lock
  %t227 = call i32 @ReleaseSemaphore(i8* %t226, i32 1, i32* null)
  br label %par_join_35
par_join_35:
  call void @par.pool.ensure_init()
  %t246 = call i32 @GetCurrentThreadId()
  %t247 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t248 = load i32, i32* %t247
  %t249 = icmp eq i32 %t246, %t248
  %t250 = select i1 %t249, i32 0, i32 -1
  %t251 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t252 = load i32, i32* %t251
  %t253 = icmp eq i32 %t246, %t252
  %t254 = select i1 %t253, i32 1, i32 %t250
  %t255 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t256 = load i32, i32* %t255
  %t257 = icmp eq i32 %t246, %t256
  %t258 = select i1 %t257, i32 2, i32 %t254
  %t259 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t260 = load i32, i32* %t259
  %t261 = icmp eq i32 %t246, %t260
  %t262 = select i1 %t261, i32 3, i32 %t258
  %t263 = icmp sge i32 %t262, 0
  br i1 %t263, label %par_serial_43, label %par_pooled_42
par_pooled_42:
  %t264 = load i64, i64* @arena.Enemies.count
  %t265 = mul i64 %t264, 0
  %t266 = sdiv i64 %t265, 4
  %t267 = mul i64 %t264, 1
  %t268 = sdiv i64 %t267, 4
  %t270 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t269, i32 0, i32 0
  store i64 %t266, i64* %t270
  %t271 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t269, i32 0, i32 1
  store i64 %t268, i64* %t271
  %t272 = bitcast { i64, i64 }* %t269 to i8*
  %t273 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t272, i8** %t273
  %t274 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_36, i32 (i8*)** %t274
  %t275 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t276 = load i8*, i8** %t275
  %t277 = call i32 @ReleaseSemaphore(i8* %t276, i32 1, i32* null)
  %t278 = mul i64 %t264, 1
  %t279 = sdiv i64 %t278, 4
  %t280 = mul i64 %t264, 2
  %t281 = sdiv i64 %t280, 4
  %t283 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t282, i32 0, i32 0
  store i64 %t279, i64* %t283
  %t284 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t282, i32 0, i32 1
  store i64 %t281, i64* %t284
  %t285 = bitcast { i64, i64 }* %t282 to i8*
  %t286 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t285, i8** %t286
  %t287 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_36, i32 (i8*)** %t287
  %t288 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t289 = load i8*, i8** %t288
  %t290 = call i32 @ReleaseSemaphore(i8* %t289, i32 1, i32* null)
  %t291 = mul i64 %t264, 2
  %t292 = sdiv i64 %t291, 4
  %t293 = mul i64 %t264, 3
  %t294 = sdiv i64 %t293, 4
  %t296 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t295, i32 0, i32 0
  store i64 %t292, i64* %t296
  %t297 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t295, i32 0, i32 1
  store i64 %t294, i64* %t297
  %t298 = bitcast { i64, i64 }* %t295 to i8*
  %t299 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t298, i8** %t299
  %t300 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_36, i32 (i8*)** %t300
  %t301 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t302 = load i8*, i8** %t301
  %t303 = call i32 @ReleaseSemaphore(i8* %t302, i32 1, i32* null)
  %t304 = mul i64 %t264, 3
  %t305 = sdiv i64 %t304, 4
  %t306 = mul i64 %t264, 4
  %t307 = sdiv i64 %t306, 4
  %t309 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t308, i32 0, i32 0
  store i64 %t305, i64* %t309
  %t310 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t308, i32 0, i32 1
  store i64 %t307, i64* %t310
  %t311 = bitcast { i64, i64 }* %t308 to i8*
  %t312 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t311, i8** %t312
  %t313 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_36, i32 (i8*)** %t313
  %t314 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t315 = load i8*, i8** %t314
  %t316 = call i32 @ReleaseSemaphore(i8* %t315, i32 1, i32* null)
  %t317 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t318 = load i8*, i8** %t317
  %t319 = call i32 @WaitForSingleObject(i8* %t318, i32 -1)
  %t320 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t321 = load i8*, i8** %t320
  %t322 = call i32 @WaitForSingleObject(i8* %t321, i32 -1)
  %t323 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t324 = load i8*, i8** %t323
  %t325 = call i32 @WaitForSingleObject(i8* %t324, i32 -1)
  %t326 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t327 = load i8*, i8** %t326
  %t328 = call i32 @WaitForSingleObject(i8* %t327, i32 -1)
  br label %par_join_47
par_serial_43:
  %t329 = load i32, i32* @par.pool.serial_owner
  %t330 = icmp eq i32 %t329, %t262
  br i1 %t330, label %par_run_45, label %par_acquire_44
par_acquire_44:
  %t331 = load i8*, i8** @par.pool.serial_lock
  %t332 = call i32 @WaitForSingleObject(i8* %t331, i32 -1)
  store i32 %t262, i32* @par.pool.serial_owner
  br label %par_run_45
par_run_45:
  %t333 = load i64, i64* @arena.Enemies.count
  %t335 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t334, i32 0, i32 0
  store i64 0, i64* %t335
  %t336 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t334, i32 0, i32 1
  store i64 %t333, i64* %t336
  %t337 = bitcast { i64, i64 }* %t334 to i8*
  %t338 = call i32 @par_worker_36(i8* %t337)
  br i1 %t330, label %par_join_47, label %par_release_46
par_release_46:
  store i32 -1, i32* @par.pool.serial_owner
  %t339 = load i8*, i8** @par.pool.serial_lock
  %t340 = call i32 @ReleaseSemaphore(i8* %t339, i32 1, i32* null)
  br label %par_join_47
par_join_47:
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_24(i8* %argp) {
entry:
  %t83 = alloca i64
  %t77 = bitcast i8* %argp to { i64, i64 }*
  %t78 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t77, i32 0, i32 0
  %t79 = load i64, i64* %t78
  %t80 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t77, i32 0, i32 1
  %t81 = load i64, i64* %t80
  %t82 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t79, i64* %t83
  br label %par_cond_25
par_cond_25:
  %t84 = load i64, i64* %t83
  %t85 = icmp slt i64 %t84, %t81
  br i1 %t85, label %par_body_26, label %par_end_29
par_body_26:
  %t86 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t84
  %t87 = load i64, i64* %t86
  %t88 = and i64 %t87, 1
  %t89 = icmp eq i64 %t88, 1
  br i1 %t89, label %par_live_27, label %par_incr_28
par_live_27:
  %t90 = getelementptr inbounds %Enemy, %Enemy* %t82, i64 %t84
  %t91 = getelementptr inbounds %Enemy, %Enemy* %t90, i32 0, i32 0
  %t92 = load i32, i32* %t91
  %t93 = sub i32 %t92, 1
  %t94 = getelementptr inbounds %Enemy, %Enemy* %t90, i32 0, i32 0
  store i32 %t93, i32* %t94
  br label %par_incr_28
par_incr_28:
  %t95 = add i64 %t84, 1
  store i64 %t95, i64* %t83
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
  %t96 = ptrtoint i8* %idx_arg to i64
  %t97 = trunc i64 %t96 to i32
  %t98 = call i32 @GetCurrentThreadId()
  %t99 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t97
  store i32 %t98, i32* %t99
  br label %loop
loop:
  %t100 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t97
  %t101 = load i8*, i8** %t100
  %t102 = call i32 @WaitForSingleObject(i8* %t101, i32 -1)
  %t103 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t97
  %t104 = load i32 (i8*)*, i32 (i8*)** %t103
  %t105 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t97
  %t106 = load i8*, i8** %t105
  %t107 = call i32 %t104(i8* %t106)
  %t108 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t97
  %t109 = load i8*, i8** %t108
  %t110 = call i32 @ReleaseSemaphore(i8* %t109, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t111 = load i1, i1* @par.pool.inited
  br i1 %t111, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t112 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t112, i8** @par.pool.serial_lock
  %t113 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t114 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t113, i8** %t114
  %t115 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t116 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t115, i8** %t116
  %t117 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t118 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t119 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t118, i8** %t119
  %t120 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t121 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t120, i8** %t121
  %t122 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t123 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t124 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t123, i8** %t124
  %t125 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t126 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t125, i8** %t126
  %t127 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t128 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t129 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t128, i8** %t129
  %t130 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t131 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t130, i8** %t131
  %t132 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_36(i8* %argp) {
entry:
  %t234 = alloca i64
  %t228 = bitcast i8* %argp to { i64, i64 }*
  %t229 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t228, i32 0, i32 0
  %t230 = load i64, i64* %t229
  %t231 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t228, i32 0, i32 1
  %t232 = load i64, i64* %t231
  %t233 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t230, i64* %t234
  br label %par_cond_37
par_cond_37:
  %t235 = load i64, i64* %t234
  %t236 = icmp slt i64 %t235, %t232
  br i1 %t236, label %par_body_38, label %par_end_41
par_body_38:
  %t237 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t235
  %t238 = load i64, i64* %t237
  %t239 = and i64 %t238, 1
  %t240 = icmp eq i64 %t239, 1
  br i1 %t240, label %par_live_39, label %par_incr_40
par_live_39:
  %t241 = getelementptr inbounds %Enemy, %Enemy* %t233, i64 %t235
  %t242 = getelementptr inbounds %Enemy, %Enemy* %t241, i32 0, i32 0
  %t243 = load i32, i32* %t242
  %t244 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t244, i32 %t243)
  br label %par_incr_40
par_incr_40:
  %t245 = add i64 %t235, 1
  store i64 %t245, i64* %t234
  br label %par_cond_37
par_end_41:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [8 x i8] c"hp: %d\0A\00"
