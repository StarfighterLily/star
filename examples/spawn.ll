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
  %t19 = alloca %Enemy
  %t44 = alloca %Enemy
  %t69 = alloca %Enemy
  %t155 = alloca { i64, i64 }
  %t168 = alloca { i64, i64 }
  %t181 = alloca { i64, i64 }
  %t194 = alloca { i64, i64 }
  %t220 = alloca { i64, i64 }
  %t268 = alloca { i64, i64 }
  %t281 = alloca { i64, i64 }
  %t294 = alloca { i64, i64 }
  %t307 = alloca { i64, i64 }
  %t333 = alloca { i64, i64 }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t2 = icmp eq %Enemy* %t1, null
  br i1 %t2, label %spawn_init_0, label %spawn_ready_1
spawn_init_0:
  %t3 = getelementptr %Enemy, %Enemy* null, i32 1
  %t4 = ptrtoint %Enemy* %t3 to i64
  %t5 = mul i64 %t4, 1024
  %t6 = call i8* @malloc(i64 %t5)
  %t7 = bitcast i8* %t6 to %Enemy*
  store %Enemy* %t7, %Enemy** @arena.Enemies.data
  br label %spawn_ready_1
spawn_ready_1:
  %t8 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t9 = load i64, i64* @arena.Enemies.free_top
  %t10 = icmp sgt i64 %t9, 0
  br i1 %t10, label %spawn_reuse_2, label %spawn_grow_3
spawn_reuse_2:
  %t11 = sub i64 %t9, 1
  store i64 %t11, i64* @arena.Enemies.free_top
  %t12 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t11
  %t13 = load i64, i64* %t12
  br label %spawn_store_4
spawn_grow_3:
  %t14 = load i64, i64* @arena.Enemies.count
  %t15 = icmp slt i64 %t14, 1024
  br i1 %t15, label %spawn_grow_ok_6, label %spawn_capacity_warn_7
spawn_capacity_warn_7:
  %t16 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t16)
  br label %spawn_end_5
spawn_grow_ok_6:
  %t17 = add i64 %t14, 1
  store i64 %t17, i64* @arena.Enemies.count
  br label %spawn_store_4
spawn_store_4:
  %t18 = phi i64 [ %t13, %spawn_reuse_2 ], [ %t14, %spawn_grow_ok_6 ]
  %t20 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 0
  store i32 10, i32* %t20
  %t21 = load %Enemy, %Enemy* %t19
  %t22 = getelementptr inbounds %Enemy, %Enemy* %t8, i64 %t18
  store %Enemy %t21, %Enemy* %t22
  %t23 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t18
  %t24 = load i32, i32* %t23
  %t25 = add i32 %t24, 1
  store i32 %t25, i32* %t23
  br label %spawn_end_5
spawn_end_5:
  %t26 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t27 = icmp eq %Enemy* %t26, null
  br i1 %t27, label %spawn_init_8, label %spawn_ready_9
spawn_init_8:
  %t28 = getelementptr %Enemy, %Enemy* null, i32 1
  %t29 = ptrtoint %Enemy* %t28 to i64
  %t30 = mul i64 %t29, 1024
  %t31 = call i8* @malloc(i64 %t30)
  %t32 = bitcast i8* %t31 to %Enemy*
  store %Enemy* %t32, %Enemy** @arena.Enemies.data
  br label %spawn_ready_9
spawn_ready_9:
  %t33 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t34 = load i64, i64* @arena.Enemies.free_top
  %t35 = icmp sgt i64 %t34, 0
  br i1 %t35, label %spawn_reuse_10, label %spawn_grow_11
spawn_reuse_10:
  %t36 = sub i64 %t34, 1
  store i64 %t36, i64* @arena.Enemies.free_top
  %t37 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t36
  %t38 = load i64, i64* %t37
  br label %spawn_store_12
spawn_grow_11:
  %t39 = load i64, i64* @arena.Enemies.count
  %t40 = icmp slt i64 %t39, 1024
  br i1 %t40, label %spawn_grow_ok_14, label %spawn_capacity_warn_15
spawn_capacity_warn_15:
  %t41 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t41)
  br label %spawn_end_13
spawn_grow_ok_14:
  %t42 = add i64 %t39, 1
  store i64 %t42, i64* @arena.Enemies.count
  br label %spawn_store_12
spawn_store_12:
  %t43 = phi i64 [ %t38, %spawn_reuse_10 ], [ %t39, %spawn_grow_ok_14 ]
  %t45 = getelementptr inbounds %Enemy, %Enemy* %t44, i32 0, i32 0
  store i32 20, i32* %t45
  %t46 = load %Enemy, %Enemy* %t44
  %t47 = getelementptr inbounds %Enemy, %Enemy* %t33, i64 %t43
  store %Enemy %t46, %Enemy* %t47
  %t48 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t43
  %t49 = load i32, i32* %t48
  %t50 = add i32 %t49, 1
  store i32 %t50, i32* %t48
  br label %spawn_end_13
spawn_end_13:
  %t51 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t52 = icmp eq %Enemy* %t51, null
  br i1 %t52, label %spawn_init_16, label %spawn_ready_17
spawn_init_16:
  %t53 = getelementptr %Enemy, %Enemy* null, i32 1
  %t54 = ptrtoint %Enemy* %t53 to i64
  %t55 = mul i64 %t54, 1024
  %t56 = call i8* @malloc(i64 %t55)
  %t57 = bitcast i8* %t56 to %Enemy*
  store %Enemy* %t57, %Enemy** @arena.Enemies.data
  br label %spawn_ready_17
spawn_ready_17:
  %t58 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t59 = load i64, i64* @arena.Enemies.free_top
  %t60 = icmp sgt i64 %t59, 0
  br i1 %t60, label %spawn_reuse_18, label %spawn_grow_19
spawn_reuse_18:
  %t61 = sub i64 %t59, 1
  store i64 %t61, i64* @arena.Enemies.free_top
  %t62 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t61
  %t63 = load i64, i64* %t62
  br label %spawn_store_20
spawn_grow_19:
  %t64 = load i64, i64* @arena.Enemies.count
  %t65 = icmp slt i64 %t64, 1024
  br i1 %t65, label %spawn_grow_ok_22, label %spawn_capacity_warn_23
spawn_capacity_warn_23:
  %t66 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t66)
  br label %spawn_end_21
spawn_grow_ok_22:
  %t67 = add i64 %t64, 1
  store i64 %t67, i64* @arena.Enemies.count
  br label %spawn_store_20
spawn_store_20:
  %t68 = phi i64 [ %t63, %spawn_reuse_18 ], [ %t64, %spawn_grow_ok_22 ]
  %t70 = getelementptr inbounds %Enemy, %Enemy* %t69, i32 0, i32 0
  store i32 30, i32* %t70
  %t71 = load %Enemy, %Enemy* %t69
  %t72 = getelementptr inbounds %Enemy, %Enemy* %t58, i64 %t68
  store %Enemy %t71, %Enemy* %t72
  %t73 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t68
  %t74 = load i32, i32* %t73
  %t75 = add i32 %t74, 1
  store i32 %t75, i32* %t73
  br label %spawn_end_21
spawn_end_21:
  call void @par.pool.ensure_init()
  %t132 = call i32 @GetCurrentThreadId()
  %t133 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t134 = load i32, i32* %t133
  %t135 = icmp eq i32 %t132, %t134
  %t136 = select i1 %t135, i32 0, i32 -1
  %t137 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t138 = load i32, i32* %t137
  %t139 = icmp eq i32 %t132, %t138
  %t140 = select i1 %t139, i32 1, i32 %t136
  %t141 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t142 = load i32, i32* %t141
  %t143 = icmp eq i32 %t132, %t142
  %t144 = select i1 %t143, i32 2, i32 %t140
  %t145 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t146 = load i32, i32* %t145
  %t147 = icmp eq i32 %t132, %t146
  %t148 = select i1 %t147, i32 3, i32 %t144
  %t149 = icmp sge i32 %t148, 0
  br i1 %t149, label %par_serial_31, label %par_pooled_30
par_pooled_30:
  %t150 = load i64, i64* @arena.Enemies.count
  %t151 = mul i64 %t150, 0
  %t152 = sdiv i64 %t151, 4
  %t153 = mul i64 %t150, 1
  %t154 = sdiv i64 %t153, 4
  %t156 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t155, i32 0, i32 0
  store i64 %t152, i64* %t156
  %t157 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t155, i32 0, i32 1
  store i64 %t154, i64* %t157
  %t158 = bitcast { i64, i64 }* %t155 to i8*
  %t159 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t158, i8** %t159
  %t160 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t160
  %t161 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t162 = load i8*, i8** %t161
  %t163 = call i32 @ReleaseSemaphore(i8* %t162, i32 1, i32* null)
  %t164 = mul i64 %t150, 1
  %t165 = sdiv i64 %t164, 4
  %t166 = mul i64 %t150, 2
  %t167 = sdiv i64 %t166, 4
  %t169 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t168, i32 0, i32 0
  store i64 %t165, i64* %t169
  %t170 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t168, i32 0, i32 1
  store i64 %t167, i64* %t170
  %t171 = bitcast { i64, i64 }* %t168 to i8*
  %t172 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t171, i8** %t172
  %t173 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t173
  %t174 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t175 = load i8*, i8** %t174
  %t176 = call i32 @ReleaseSemaphore(i8* %t175, i32 1, i32* null)
  %t177 = mul i64 %t150, 2
  %t178 = sdiv i64 %t177, 4
  %t179 = mul i64 %t150, 3
  %t180 = sdiv i64 %t179, 4
  %t182 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t181, i32 0, i32 0
  store i64 %t178, i64* %t182
  %t183 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t181, i32 0, i32 1
  store i64 %t180, i64* %t183
  %t184 = bitcast { i64, i64 }* %t181 to i8*
  %t185 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t184, i8** %t185
  %t186 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t186
  %t187 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t188 = load i8*, i8** %t187
  %t189 = call i32 @ReleaseSemaphore(i8* %t188, i32 1, i32* null)
  %t190 = mul i64 %t150, 3
  %t191 = sdiv i64 %t190, 4
  %t192 = mul i64 %t150, 4
  %t193 = sdiv i64 %t192, 4
  %t195 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t194, i32 0, i32 0
  store i64 %t191, i64* %t195
  %t196 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t194, i32 0, i32 1
  store i64 %t193, i64* %t196
  %t197 = bitcast { i64, i64 }* %t194 to i8*
  %t198 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t197, i8** %t198
  %t199 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t199
  %t200 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t201 = load i8*, i8** %t200
  %t202 = call i32 @ReleaseSemaphore(i8* %t201, i32 1, i32* null)
  %t203 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t204 = load i8*, i8** %t203
  %t205 = call i32 @WaitForSingleObject(i8* %t204, i32 -1)
  %t206 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t207 = load i8*, i8** %t206
  %t208 = call i32 @WaitForSingleObject(i8* %t207, i32 -1)
  %t209 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t210 = load i8*, i8** %t209
  %t211 = call i32 @WaitForSingleObject(i8* %t210, i32 -1)
  %t212 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t213 = load i8*, i8** %t212
  %t214 = call i32 @WaitForSingleObject(i8* %t213, i32 -1)
  br label %par_join_35
par_serial_31:
  %t215 = load i32, i32* @par.pool.serial_owner
  %t216 = icmp eq i32 %t215, %t148
  br i1 %t216, label %par_run_33, label %par_acquire_32
par_acquire_32:
  %t217 = load i8*, i8** @par.pool.serial_lock
  %t218 = call i32 @WaitForSingleObject(i8* %t217, i32 -1)
  store i32 %t148, i32* @par.pool.serial_owner
  br label %par_run_33
par_run_33:
  %t219 = load i64, i64* @arena.Enemies.count
  %t221 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t220, i32 0, i32 0
  store i64 0, i64* %t221
  %t222 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t220, i32 0, i32 1
  store i64 %t219, i64* %t222
  %t223 = bitcast { i64, i64 }* %t220 to i8*
  %t224 = call i32 @par_worker_24(i8* %t223)
  br i1 %t216, label %par_join_35, label %par_release_34
par_release_34:
  store i32 -1, i32* @par.pool.serial_owner
  %t225 = load i8*, i8** @par.pool.serial_lock
  %t226 = call i32 @ReleaseSemaphore(i8* %t225, i32 1, i32* null)
  br label %par_join_35
par_join_35:
  call void @par.pool.ensure_init()
  %t245 = call i32 @GetCurrentThreadId()
  %t246 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t247 = load i32, i32* %t246
  %t248 = icmp eq i32 %t245, %t247
  %t249 = select i1 %t248, i32 0, i32 -1
  %t250 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t251 = load i32, i32* %t250
  %t252 = icmp eq i32 %t245, %t251
  %t253 = select i1 %t252, i32 1, i32 %t249
  %t254 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t255 = load i32, i32* %t254
  %t256 = icmp eq i32 %t245, %t255
  %t257 = select i1 %t256, i32 2, i32 %t253
  %t258 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t259 = load i32, i32* %t258
  %t260 = icmp eq i32 %t245, %t259
  %t261 = select i1 %t260, i32 3, i32 %t257
  %t262 = icmp sge i32 %t261, 0
  br i1 %t262, label %par_serial_43, label %par_pooled_42
par_pooled_42:
  %t263 = load i64, i64* @arena.Enemies.count
  %t264 = mul i64 %t263, 0
  %t265 = sdiv i64 %t264, 4
  %t266 = mul i64 %t263, 1
  %t267 = sdiv i64 %t266, 4
  %t269 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t268, i32 0, i32 0
  store i64 %t265, i64* %t269
  %t270 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t268, i32 0, i32 1
  store i64 %t267, i64* %t270
  %t271 = bitcast { i64, i64 }* %t268 to i8*
  %t272 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t271, i8** %t272
  %t273 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_36, i32 (i8*)** %t273
  %t274 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t275 = load i8*, i8** %t274
  %t276 = call i32 @ReleaseSemaphore(i8* %t275, i32 1, i32* null)
  %t277 = mul i64 %t263, 1
  %t278 = sdiv i64 %t277, 4
  %t279 = mul i64 %t263, 2
  %t280 = sdiv i64 %t279, 4
  %t282 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t281, i32 0, i32 0
  store i64 %t278, i64* %t282
  %t283 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t281, i32 0, i32 1
  store i64 %t280, i64* %t283
  %t284 = bitcast { i64, i64 }* %t281 to i8*
  %t285 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t284, i8** %t285
  %t286 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_36, i32 (i8*)** %t286
  %t287 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t288 = load i8*, i8** %t287
  %t289 = call i32 @ReleaseSemaphore(i8* %t288, i32 1, i32* null)
  %t290 = mul i64 %t263, 2
  %t291 = sdiv i64 %t290, 4
  %t292 = mul i64 %t263, 3
  %t293 = sdiv i64 %t292, 4
  %t295 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t294, i32 0, i32 0
  store i64 %t291, i64* %t295
  %t296 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t294, i32 0, i32 1
  store i64 %t293, i64* %t296
  %t297 = bitcast { i64, i64 }* %t294 to i8*
  %t298 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t297, i8** %t298
  %t299 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_36, i32 (i8*)** %t299
  %t300 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t301 = load i8*, i8** %t300
  %t302 = call i32 @ReleaseSemaphore(i8* %t301, i32 1, i32* null)
  %t303 = mul i64 %t263, 3
  %t304 = sdiv i64 %t303, 4
  %t305 = mul i64 %t263, 4
  %t306 = sdiv i64 %t305, 4
  %t308 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t307, i32 0, i32 0
  store i64 %t304, i64* %t308
  %t309 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t307, i32 0, i32 1
  store i64 %t306, i64* %t309
  %t310 = bitcast { i64, i64 }* %t307 to i8*
  %t311 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t310, i8** %t311
  %t312 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_36, i32 (i8*)** %t312
  %t313 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t314 = load i8*, i8** %t313
  %t315 = call i32 @ReleaseSemaphore(i8* %t314, i32 1, i32* null)
  %t316 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t317 = load i8*, i8** %t316
  %t318 = call i32 @WaitForSingleObject(i8* %t317, i32 -1)
  %t319 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t320 = load i8*, i8** %t319
  %t321 = call i32 @WaitForSingleObject(i8* %t320, i32 -1)
  %t322 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t323 = load i8*, i8** %t322
  %t324 = call i32 @WaitForSingleObject(i8* %t323, i32 -1)
  %t325 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t326 = load i8*, i8** %t325
  %t327 = call i32 @WaitForSingleObject(i8* %t326, i32 -1)
  br label %par_join_47
par_serial_43:
  %t328 = load i32, i32* @par.pool.serial_owner
  %t329 = icmp eq i32 %t328, %t261
  br i1 %t329, label %par_run_45, label %par_acquire_44
par_acquire_44:
  %t330 = load i8*, i8** @par.pool.serial_lock
  %t331 = call i32 @WaitForSingleObject(i8* %t330, i32 -1)
  store i32 %t261, i32* @par.pool.serial_owner
  br label %par_run_45
par_run_45:
  %t332 = load i64, i64* @arena.Enemies.count
  %t334 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t333, i32 0, i32 0
  store i64 0, i64* %t334
  %t335 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t333, i32 0, i32 1
  store i64 %t332, i64* %t335
  %t336 = bitcast { i64, i64 }* %t333 to i8*
  %t337 = call i32 @par_worker_36(i8* %t336)
  br i1 %t329, label %par_join_47, label %par_release_46
par_release_46:
  store i32 -1, i32* @par.pool.serial_owner
  %t338 = load i8*, i8** @par.pool.serial_lock
  %t339 = call i32 @ReleaseSemaphore(i8* %t338, i32 1, i32* null)
  br label %par_join_47
par_join_47:
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_24(i8* %argp) {
entry:
  %t82 = alloca i64
  %t76 = bitcast i8* %argp to { i64, i64 }*
  %t77 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t76, i32 0, i32 0
  %t78 = load i64, i64* %t77
  %t79 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t76, i32 0, i32 1
  %t80 = load i64, i64* %t79
  %t81 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t78, i64* %t82
  br label %par_cond_25
par_cond_25:
  %t83 = load i64, i64* %t82
  %t84 = icmp slt i64 %t83, %t80
  br i1 %t84, label %par_body_26, label %par_end_29
par_body_26:
  %t85 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t83
  %t86 = load i32, i32* %t85
  %t87 = and i32 %t86, 1
  %t88 = icmp eq i32 %t87, 1
  br i1 %t88, label %par_live_27, label %par_incr_28
par_live_27:
  %t89 = getelementptr inbounds %Enemy, %Enemy* %t81, i64 %t83
  %t90 = getelementptr inbounds %Enemy, %Enemy* %t89, i32 0, i32 0
  %t91 = load i32, i32* %t90
  %t92 = sub i32 %t91, 1
  %t93 = getelementptr inbounds %Enemy, %Enemy* %t89, i32 0, i32 0
  store i32 %t92, i32* %t93
  br label %par_incr_28
par_incr_28:
  %t94 = add i64 %t83, 1
  store i64 %t94, i64* %t82
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
  %t95 = ptrtoint i8* %idx_arg to i64
  %t96 = trunc i64 %t95 to i32
  %t97 = call i32 @GetCurrentThreadId()
  %t98 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t96
  store i32 %t97, i32* %t98
  br label %loop
loop:
  %t99 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t96
  %t100 = load i8*, i8** %t99
  %t101 = call i32 @WaitForSingleObject(i8* %t100, i32 -1)
  %t102 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t96
  %t103 = load i32 (i8*)*, i32 (i8*)** %t102
  %t104 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t96
  %t105 = load i8*, i8** %t104
  %t106 = call i32 %t103(i8* %t105)
  %t107 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t96
  %t108 = load i8*, i8** %t107
  %t109 = call i32 @ReleaseSemaphore(i8* %t108, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t110 = load i1, i1* @par.pool.inited
  br i1 %t110, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t111 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t111, i8** @par.pool.serial_lock
  %t112 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t113 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t112, i8** %t113
  %t114 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t115 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t114, i8** %t115
  %t116 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t117 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t118 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t117, i8** %t118
  %t119 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t120 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t119, i8** %t120
  %t121 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t122 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t123 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t122, i8** %t123
  %t124 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t125 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t124, i8** %t125
  %t126 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t127 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t128 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t127, i8** %t128
  %t129 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t130 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t129, i8** %t130
  %t131 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_36(i8* %argp) {
entry:
  %t233 = alloca i64
  %t227 = bitcast i8* %argp to { i64, i64 }*
  %t228 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t227, i32 0, i32 0
  %t229 = load i64, i64* %t228
  %t230 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t227, i32 0, i32 1
  %t231 = load i64, i64* %t230
  %t232 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t229, i64* %t233
  br label %par_cond_37
par_cond_37:
  %t234 = load i64, i64* %t233
  %t235 = icmp slt i64 %t234, %t231
  br i1 %t235, label %par_body_38, label %par_end_41
par_body_38:
  %t236 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t234
  %t237 = load i32, i32* %t236
  %t238 = and i32 %t237, 1
  %t239 = icmp eq i32 %t238, 1
  br i1 %t239, label %par_live_39, label %par_incr_40
par_live_39:
  %t240 = getelementptr inbounds %Enemy, %Enemy* %t232, i64 %t234
  %t241 = getelementptr inbounds %Enemy, %Enemy* %t240, i32 0, i32 0
  %t242 = load i32, i32* %t241
  %t243 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t243, i32 %t242)
  br label %par_incr_40
par_incr_40:
  %t244 = add i64 %t234, 1
  store i64 %t244, i64* %t233
  br label %par_cond_37
par_end_41:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [8 x i8] c"hp: %d\0A\00"
