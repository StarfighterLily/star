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
  %t76 = alloca i32
  %t160 = alloca { i64, i64, i32* }
  %t174 = alloca { i64, i64, i32* }
  %t188 = alloca { i64, i64, i32* }
  %t202 = alloca { i64, i64, i32* }
  %t229 = alloca { i64, i64, i32* }
  %t280 = alloca { i64, i64 }
  %t293 = alloca { i64, i64 }
  %t306 = alloca { i64, i64 }
  %t319 = alloca { i64, i64 }
  %t345 = alloca { i64, i64 }
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
  store i32 100, i32* %t20
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
  store i32 100, i32* %t45
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
  store i32 100, i32* %t70
  %t71 = load %Enemy, %Enemy* %t69
  %t72 = getelementptr inbounds %Enemy, %Enemy* %t58, i64 %t68
  store %Enemy %t71, %Enemy* %t72
  %t73 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t68
  %t74 = load i32, i32* %t73
  %t75 = add i32 %t74, 1
  store i32 %t75, i32* %t73
  br label %spawn_end_21
spawn_end_21:
  store i32 0, i32* %t76
  br label %for_cond_24
for_cond_24:
  %t77 = load i32, i32* %t76
  %t78 = icmp slt i32 %t77, 5
  br i1 %t78, label %for_body_25, label %for_end_27
for_body_25:
  call void @par.pool.ensure_init()
  %t137 = call i32 @GetCurrentThreadId()
  %t138 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t139 = load i32, i32* %t138
  %t140 = icmp eq i32 %t137, %t139
  %t141 = select i1 %t140, i32 0, i32 -1
  %t142 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t143 = load i32, i32* %t142
  %t144 = icmp eq i32 %t137, %t143
  %t145 = select i1 %t144, i32 1, i32 %t141
  %t146 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t147 = load i32, i32* %t146
  %t148 = icmp eq i32 %t137, %t147
  %t149 = select i1 %t148, i32 2, i32 %t145
  %t150 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t151 = load i32, i32* %t150
  %t152 = icmp eq i32 %t137, %t151
  %t153 = select i1 %t152, i32 3, i32 %t149
  %t154 = icmp sge i32 %t153, 0
  br i1 %t154, label %par_serial_35, label %par_pooled_34
par_pooled_34:
  %t155 = load i64, i64* @arena.Enemies.count
  %t156 = mul i64 %t155, 0
  %t157 = sdiv i64 %t156, 4
  %t158 = mul i64 %t155, 1
  %t159 = sdiv i64 %t158, 4
  %t161 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t160, i32 0, i32 0
  store i64 %t157, i64* %t161
  %t162 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t160, i32 0, i32 1
  store i64 %t159, i64* %t162
  %t163 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t160, i32 0, i32 2
  store i32* %t76, i32** %t163
  %t164 = bitcast { i64, i64, i32* }* %t160 to i8*
  %t165 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t164, i8** %t165
  %t166 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t166
  %t167 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t168 = load i8*, i8** %t167
  %t169 = call i32 @ReleaseSemaphore(i8* %t168, i32 1, i32* null)
  %t170 = mul i64 %t155, 1
  %t171 = sdiv i64 %t170, 4
  %t172 = mul i64 %t155, 2
  %t173 = sdiv i64 %t172, 4
  %t175 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t174, i32 0, i32 0
  store i64 %t171, i64* %t175
  %t176 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t174, i32 0, i32 1
  store i64 %t173, i64* %t176
  %t177 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t174, i32 0, i32 2
  store i32* %t76, i32** %t177
  %t178 = bitcast { i64, i64, i32* }* %t174 to i8*
  %t179 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t178, i8** %t179
  %t180 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t180
  %t181 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t182 = load i8*, i8** %t181
  %t183 = call i32 @ReleaseSemaphore(i8* %t182, i32 1, i32* null)
  %t184 = mul i64 %t155, 2
  %t185 = sdiv i64 %t184, 4
  %t186 = mul i64 %t155, 3
  %t187 = sdiv i64 %t186, 4
  %t189 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t188, i32 0, i32 0
  store i64 %t185, i64* %t189
  %t190 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t188, i32 0, i32 1
  store i64 %t187, i64* %t190
  %t191 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t188, i32 0, i32 2
  store i32* %t76, i32** %t191
  %t192 = bitcast { i64, i64, i32* }* %t188 to i8*
  %t193 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t192, i8** %t193
  %t194 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t194
  %t195 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t196 = load i8*, i8** %t195
  %t197 = call i32 @ReleaseSemaphore(i8* %t196, i32 1, i32* null)
  %t198 = mul i64 %t155, 3
  %t199 = sdiv i64 %t198, 4
  %t200 = mul i64 %t155, 4
  %t201 = sdiv i64 %t200, 4
  %t203 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t202, i32 0, i32 0
  store i64 %t199, i64* %t203
  %t204 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t202, i32 0, i32 1
  store i64 %t201, i64* %t204
  %t205 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t202, i32 0, i32 2
  store i32* %t76, i32** %t205
  %t206 = bitcast { i64, i64, i32* }* %t202 to i8*
  %t207 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t206, i8** %t207
  %t208 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t208
  %t209 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t210 = load i8*, i8** %t209
  %t211 = call i32 @ReleaseSemaphore(i8* %t210, i32 1, i32* null)
  %t212 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t213 = load i8*, i8** %t212
  %t214 = call i32 @WaitForSingleObject(i8* %t213, i32 -1)
  %t215 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t216 = load i8*, i8** %t215
  %t217 = call i32 @WaitForSingleObject(i8* %t216, i32 -1)
  %t218 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t219 = load i8*, i8** %t218
  %t220 = call i32 @WaitForSingleObject(i8* %t219, i32 -1)
  %t221 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t222 = load i8*, i8** %t221
  %t223 = call i32 @WaitForSingleObject(i8* %t222, i32 -1)
  br label %par_join_39
par_serial_35:
  %t224 = load i32, i32* @par.pool.serial_owner
  %t225 = icmp eq i32 %t224, %t153
  br i1 %t225, label %par_run_37, label %par_acquire_36
par_acquire_36:
  %t226 = load i8*, i8** @par.pool.serial_lock
  %t227 = call i32 @WaitForSingleObject(i8* %t226, i32 -1)
  store i32 %t153, i32* @par.pool.serial_owner
  br label %par_run_37
par_run_37:
  %t228 = load i64, i64* @arena.Enemies.count
  %t230 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t229, i32 0, i32 0
  store i64 0, i64* %t230
  %t231 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t229, i32 0, i32 1
  store i64 %t228, i64* %t231
  %t232 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t229, i32 0, i32 2
  store i32* %t76, i32** %t232
  %t233 = bitcast { i64, i64, i32* }* %t229 to i8*
  %t234 = call i32 @par_worker_28(i8* %t233)
  br i1 %t225, label %par_join_39, label %par_release_38
par_release_38:
  store i32 -1, i32* @par.pool.serial_owner
  %t235 = load i8*, i8** @par.pool.serial_lock
  %t236 = call i32 @ReleaseSemaphore(i8* %t235, i32 1, i32* null)
  br label %par_join_39
par_join_39:
  br label %for_step_26
for_step_26:
  %t237 = load i32, i32* %t76
  %t238 = add i32 %t237, 1
  store i32 %t238, i32* %t76
  br label %for_cond_24
for_end_27:
  call void @par.pool.ensure_init()
  %t257 = call i32 @GetCurrentThreadId()
  %t258 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t259 = load i32, i32* %t258
  %t260 = icmp eq i32 %t257, %t259
  %t261 = select i1 %t260, i32 0, i32 -1
  %t262 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t263 = load i32, i32* %t262
  %t264 = icmp eq i32 %t257, %t263
  %t265 = select i1 %t264, i32 1, i32 %t261
  %t266 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t267 = load i32, i32* %t266
  %t268 = icmp eq i32 %t257, %t267
  %t269 = select i1 %t268, i32 2, i32 %t265
  %t270 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t271 = load i32, i32* %t270
  %t272 = icmp eq i32 %t257, %t271
  %t273 = select i1 %t272, i32 3, i32 %t269
  %t274 = icmp sge i32 %t273, 0
  br i1 %t274, label %par_serial_47, label %par_pooled_46
par_pooled_46:
  %t275 = load i64, i64* @arena.Enemies.count
  %t276 = mul i64 %t275, 0
  %t277 = sdiv i64 %t276, 4
  %t278 = mul i64 %t275, 1
  %t279 = sdiv i64 %t278, 4
  %t281 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t280, i32 0, i32 0
  store i64 %t277, i64* %t281
  %t282 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t280, i32 0, i32 1
  store i64 %t279, i64* %t282
  %t283 = bitcast { i64, i64 }* %t280 to i8*
  %t284 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t283, i8** %t284
  %t285 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_40, i32 (i8*)** %t285
  %t286 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t287 = load i8*, i8** %t286
  %t288 = call i32 @ReleaseSemaphore(i8* %t287, i32 1, i32* null)
  %t289 = mul i64 %t275, 1
  %t290 = sdiv i64 %t289, 4
  %t291 = mul i64 %t275, 2
  %t292 = sdiv i64 %t291, 4
  %t294 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t293, i32 0, i32 0
  store i64 %t290, i64* %t294
  %t295 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t293, i32 0, i32 1
  store i64 %t292, i64* %t295
  %t296 = bitcast { i64, i64 }* %t293 to i8*
  %t297 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t296, i8** %t297
  %t298 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_40, i32 (i8*)** %t298
  %t299 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t300 = load i8*, i8** %t299
  %t301 = call i32 @ReleaseSemaphore(i8* %t300, i32 1, i32* null)
  %t302 = mul i64 %t275, 2
  %t303 = sdiv i64 %t302, 4
  %t304 = mul i64 %t275, 3
  %t305 = sdiv i64 %t304, 4
  %t307 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t306, i32 0, i32 0
  store i64 %t303, i64* %t307
  %t308 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t306, i32 0, i32 1
  store i64 %t305, i64* %t308
  %t309 = bitcast { i64, i64 }* %t306 to i8*
  %t310 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t309, i8** %t310
  %t311 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_40, i32 (i8*)** %t311
  %t312 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t313 = load i8*, i8** %t312
  %t314 = call i32 @ReleaseSemaphore(i8* %t313, i32 1, i32* null)
  %t315 = mul i64 %t275, 3
  %t316 = sdiv i64 %t315, 4
  %t317 = mul i64 %t275, 4
  %t318 = sdiv i64 %t317, 4
  %t320 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t319, i32 0, i32 0
  store i64 %t316, i64* %t320
  %t321 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t319, i32 0, i32 1
  store i64 %t318, i64* %t321
  %t322 = bitcast { i64, i64 }* %t319 to i8*
  %t323 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t322, i8** %t323
  %t324 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_40, i32 (i8*)** %t324
  %t325 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t326 = load i8*, i8** %t325
  %t327 = call i32 @ReleaseSemaphore(i8* %t326, i32 1, i32* null)
  %t328 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t329 = load i8*, i8** %t328
  %t330 = call i32 @WaitForSingleObject(i8* %t329, i32 -1)
  %t331 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t332 = load i8*, i8** %t331
  %t333 = call i32 @WaitForSingleObject(i8* %t332, i32 -1)
  %t334 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t335 = load i8*, i8** %t334
  %t336 = call i32 @WaitForSingleObject(i8* %t335, i32 -1)
  %t337 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t338 = load i8*, i8** %t337
  %t339 = call i32 @WaitForSingleObject(i8* %t338, i32 -1)
  br label %par_join_51
par_serial_47:
  %t340 = load i32, i32* @par.pool.serial_owner
  %t341 = icmp eq i32 %t340, %t273
  br i1 %t341, label %par_run_49, label %par_acquire_48
par_acquire_48:
  %t342 = load i8*, i8** @par.pool.serial_lock
  %t343 = call i32 @WaitForSingleObject(i8* %t342, i32 -1)
  store i32 %t273, i32* @par.pool.serial_owner
  br label %par_run_49
par_run_49:
  %t344 = load i64, i64* @arena.Enemies.count
  %t346 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t345, i32 0, i32 0
  store i64 0, i64* %t346
  %t347 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t345, i32 0, i32 1
  store i64 %t344, i64* %t347
  %t348 = bitcast { i64, i64 }* %t345 to i8*
  %t349 = call i32 @par_worker_40(i8* %t348)
  br i1 %t341, label %par_join_51, label %par_release_50
par_release_50:
  store i32 -1, i32* @par.pool.serial_owner
  %t350 = load i8*, i8** @par.pool.serial_lock
  %t351 = call i32 @ReleaseSemaphore(i8* %t350, i32 1, i32* null)
  br label %par_join_51
par_join_51:
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_28(i8* %argp) {
entry:
  %t87 = alloca i64
  %t79 = bitcast i8* %argp to { i64, i64, i32* }*
  %t80 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t79, i32 0, i32 0
  %t81 = load i64, i64* %t80
  %t82 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t79, i32 0, i32 1
  %t83 = load i64, i64* %t82
  %t84 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t79, i32 0, i32 2
  %t85 = load i32*, i32** %t84
  %t86 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t81, i64* %t87
  br label %par_cond_29
par_cond_29:
  %t88 = load i64, i64* %t87
  %t89 = icmp slt i64 %t88, %t83
  br i1 %t89, label %par_body_30, label %par_end_33
par_body_30:
  %t90 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t88
  %t91 = load i32, i32* %t90
  %t92 = and i32 %t91, 1
  %t93 = icmp eq i32 %t92, 1
  br i1 %t93, label %par_live_31, label %par_incr_32
par_live_31:
  %t94 = getelementptr inbounds %Enemy, %Enemy* %t86, i64 %t88
  %t95 = getelementptr inbounds %Enemy, %Enemy* %t94, i32 0, i32 0
  %t96 = load i32, i32* %t95
  %t97 = sub i32 %t96, 1
  %t98 = getelementptr inbounds %Enemy, %Enemy* %t94, i32 0, i32 0
  store i32 %t97, i32* %t98
  br label %par_incr_32
par_incr_32:
  %t99 = add i64 %t88, 1
  store i64 %t99, i64* %t87
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
  %t100 = ptrtoint i8* %idx_arg to i64
  %t101 = trunc i64 %t100 to i32
  %t102 = call i32 @GetCurrentThreadId()
  %t103 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t101
  store i32 %t102, i32* %t103
  br label %loop
loop:
  %t104 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t101
  %t105 = load i8*, i8** %t104
  %t106 = call i32 @WaitForSingleObject(i8* %t105, i32 -1)
  %t107 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t101
  %t108 = load i32 (i8*)*, i32 (i8*)** %t107
  %t109 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t101
  %t110 = load i8*, i8** %t109
  %t111 = call i32 %t108(i8* %t110)
  %t112 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t101
  %t113 = load i8*, i8** %t112
  %t114 = call i32 @ReleaseSemaphore(i8* %t113, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t115 = load i1, i1* @par.pool.inited
  br i1 %t115, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t116 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t116, i8** @par.pool.serial_lock
  %t117 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t118 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t117, i8** %t118
  %t119 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t120 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t119, i8** %t120
  %t121 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t122 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t123 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t122, i8** %t123
  %t124 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t125 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t124, i8** %t125
  %t126 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t127 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t128 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t127, i8** %t128
  %t129 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t130 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t129, i8** %t130
  %t131 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t132 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t133 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t132, i8** %t133
  %t134 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t135 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t134, i8** %t135
  %t136 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_40(i8* %argp) {
entry:
  %t245 = alloca i64
  %t239 = bitcast i8* %argp to { i64, i64 }*
  %t240 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t239, i32 0, i32 0
  %t241 = load i64, i64* %t240
  %t242 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t239, i32 0, i32 1
  %t243 = load i64, i64* %t242
  %t244 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t241, i64* %t245
  br label %par_cond_41
par_cond_41:
  %t246 = load i64, i64* %t245
  %t247 = icmp slt i64 %t246, %t243
  br i1 %t247, label %par_body_42, label %par_end_45
par_body_42:
  %t248 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t246
  %t249 = load i32, i32* %t248
  %t250 = and i32 %t249, 1
  %t251 = icmp eq i32 %t250, 1
  br i1 %t251, label %par_live_43, label %par_incr_44
par_live_43:
  %t252 = getelementptr inbounds %Enemy, %Enemy* %t244, i64 %t246
  %t253 = getelementptr inbounds %Enemy, %Enemy* %t252, i32 0, i32 0
  %t254 = load i32, i32* %t253
  %t255 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t255, i32 %t254)
  br label %par_incr_44
par_incr_44:
  %t256 = add i64 %t246, 1
  store i64 %t256, i64* %t245
  br label %par_cond_41
par_end_45:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [8 x i8] c"hp: %d\0A\00"
