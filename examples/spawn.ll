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
  %t18 = alloca %Enemy
  %t43 = alloca %Enemy
  %t68 = alloca %Enemy
  %t154 = alloca { i64, i64 }
  %t167 = alloca { i64, i64 }
  %t180 = alloca { i64, i64 }
  %t193 = alloca { i64, i64 }
  %t219 = alloca { i64, i64 }
  %t267 = alloca { i64, i64 }
  %t280 = alloca { i64, i64 }
  %t293 = alloca { i64, i64 }
  %t306 = alloca { i64, i64 }
  %t332 = alloca { i64, i64 }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t1 = icmp eq %Enemy* %t0, null
  br i1 %t1, label %spawn_init_0, label %spawn_ready_1
spawn_init_0:
  %t2 = getelementptr %Enemy, %Enemy* null, i32 1
  %t3 = ptrtoint %Enemy* %t2 to i64
  %t4 = mul i64 %t3, 1024
  %t5 = call i8* @malloc(i64 %t4)
  %t6 = bitcast i8* %t5 to %Enemy*
  store %Enemy* %t6, %Enemy** @arena.Enemies.data
  br label %spawn_ready_1
spawn_ready_1:
  %t7 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t8 = load i64, i64* @arena.Enemies.free_top
  %t9 = icmp sgt i64 %t8, 0
  br i1 %t9, label %spawn_reuse_2, label %spawn_grow_3
spawn_reuse_2:
  %t10 = sub i64 %t8, 1
  store i64 %t10, i64* @arena.Enemies.free_top
  %t11 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t10
  %t12 = load i64, i64* %t11
  br label %spawn_store_4
spawn_grow_3:
  %t13 = load i64, i64* @arena.Enemies.count
  %t14 = icmp slt i64 %t13, 1024
  br i1 %t14, label %spawn_grow_ok_6, label %spawn_capacity_warn_7
spawn_capacity_warn_7:
  %t15 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t15)
  br label %spawn_end_5
spawn_grow_ok_6:
  %t16 = add i64 %t13, 1
  store i64 %t16, i64* @arena.Enemies.count
  br label %spawn_store_4
spawn_store_4:
  %t17 = phi i64 [ %t12, %spawn_reuse_2 ], [ %t13, %spawn_grow_ok_6 ]
  %t19 = getelementptr inbounds %Enemy, %Enemy* %t18, i32 0, i32 0
  store i32 10, i32* %t19
  %t20 = load %Enemy, %Enemy* %t18
  %t21 = getelementptr inbounds %Enemy, %Enemy* %t7, i64 %t17
  store %Enemy %t20, %Enemy* %t21
  %t22 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t17
  %t23 = load i32, i32* %t22
  %t24 = add i32 %t23, 1
  store i32 %t24, i32* %t22
  br label %spawn_end_5
spawn_end_5:
  %t25 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t26 = icmp eq %Enemy* %t25, null
  br i1 %t26, label %spawn_init_8, label %spawn_ready_9
spawn_init_8:
  %t27 = getelementptr %Enemy, %Enemy* null, i32 1
  %t28 = ptrtoint %Enemy* %t27 to i64
  %t29 = mul i64 %t28, 1024
  %t30 = call i8* @malloc(i64 %t29)
  %t31 = bitcast i8* %t30 to %Enemy*
  store %Enemy* %t31, %Enemy** @arena.Enemies.data
  br label %spawn_ready_9
spawn_ready_9:
  %t32 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t33 = load i64, i64* @arena.Enemies.free_top
  %t34 = icmp sgt i64 %t33, 0
  br i1 %t34, label %spawn_reuse_10, label %spawn_grow_11
spawn_reuse_10:
  %t35 = sub i64 %t33, 1
  store i64 %t35, i64* @arena.Enemies.free_top
  %t36 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t35
  %t37 = load i64, i64* %t36
  br label %spawn_store_12
spawn_grow_11:
  %t38 = load i64, i64* @arena.Enemies.count
  %t39 = icmp slt i64 %t38, 1024
  br i1 %t39, label %spawn_grow_ok_14, label %spawn_capacity_warn_15
spawn_capacity_warn_15:
  %t40 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t40)
  br label %spawn_end_13
spawn_grow_ok_14:
  %t41 = add i64 %t38, 1
  store i64 %t41, i64* @arena.Enemies.count
  br label %spawn_store_12
spawn_store_12:
  %t42 = phi i64 [ %t37, %spawn_reuse_10 ], [ %t38, %spawn_grow_ok_14 ]
  %t44 = getelementptr inbounds %Enemy, %Enemy* %t43, i32 0, i32 0
  store i32 20, i32* %t44
  %t45 = load %Enemy, %Enemy* %t43
  %t46 = getelementptr inbounds %Enemy, %Enemy* %t32, i64 %t42
  store %Enemy %t45, %Enemy* %t46
  %t47 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t42
  %t48 = load i32, i32* %t47
  %t49 = add i32 %t48, 1
  store i32 %t49, i32* %t47
  br label %spawn_end_13
spawn_end_13:
  %t50 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t51 = icmp eq %Enemy* %t50, null
  br i1 %t51, label %spawn_init_16, label %spawn_ready_17
spawn_init_16:
  %t52 = getelementptr %Enemy, %Enemy* null, i32 1
  %t53 = ptrtoint %Enemy* %t52 to i64
  %t54 = mul i64 %t53, 1024
  %t55 = call i8* @malloc(i64 %t54)
  %t56 = bitcast i8* %t55 to %Enemy*
  store %Enemy* %t56, %Enemy** @arena.Enemies.data
  br label %spawn_ready_17
spawn_ready_17:
  %t57 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t58 = load i64, i64* @arena.Enemies.free_top
  %t59 = icmp sgt i64 %t58, 0
  br i1 %t59, label %spawn_reuse_18, label %spawn_grow_19
spawn_reuse_18:
  %t60 = sub i64 %t58, 1
  store i64 %t60, i64* @arena.Enemies.free_top
  %t61 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t60
  %t62 = load i64, i64* %t61
  br label %spawn_store_20
spawn_grow_19:
  %t63 = load i64, i64* @arena.Enemies.count
  %t64 = icmp slt i64 %t63, 1024
  br i1 %t64, label %spawn_grow_ok_22, label %spawn_capacity_warn_23
spawn_capacity_warn_23:
  %t65 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t65)
  br label %spawn_end_21
spawn_grow_ok_22:
  %t66 = add i64 %t63, 1
  store i64 %t66, i64* @arena.Enemies.count
  br label %spawn_store_20
spawn_store_20:
  %t67 = phi i64 [ %t62, %spawn_reuse_18 ], [ %t63, %spawn_grow_ok_22 ]
  %t69 = getelementptr inbounds %Enemy, %Enemy* %t68, i32 0, i32 0
  store i32 30, i32* %t69
  %t70 = load %Enemy, %Enemy* %t68
  %t71 = getelementptr inbounds %Enemy, %Enemy* %t57, i64 %t67
  store %Enemy %t70, %Enemy* %t71
  %t72 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t67
  %t73 = load i32, i32* %t72
  %t74 = add i32 %t73, 1
  store i32 %t74, i32* %t72
  br label %spawn_end_21
spawn_end_21:
  call void @par.pool.ensure_init()
  %t131 = call i32 @GetCurrentThreadId()
  %t132 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t133 = load i32, i32* %t132
  %t134 = icmp eq i32 %t131, %t133
  %t135 = select i1 %t134, i32 0, i32 -1
  %t136 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t137 = load i32, i32* %t136
  %t138 = icmp eq i32 %t131, %t137
  %t139 = select i1 %t138, i32 1, i32 %t135
  %t140 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t141 = load i32, i32* %t140
  %t142 = icmp eq i32 %t131, %t141
  %t143 = select i1 %t142, i32 2, i32 %t139
  %t144 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t145 = load i32, i32* %t144
  %t146 = icmp eq i32 %t131, %t145
  %t147 = select i1 %t146, i32 3, i32 %t143
  %t148 = icmp sge i32 %t147, 0
  br i1 %t148, label %par_serial_31, label %par_pooled_30
par_pooled_30:
  %t149 = load i64, i64* @arena.Enemies.count
  %t150 = mul i64 %t149, 0
  %t151 = sdiv i64 %t150, 4
  %t152 = mul i64 %t149, 1
  %t153 = sdiv i64 %t152, 4
  %t155 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t154, i32 0, i32 0
  store i64 %t151, i64* %t155
  %t156 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t154, i32 0, i32 1
  store i64 %t153, i64* %t156
  %t157 = bitcast { i64, i64 }* %t154 to i8*
  %t158 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t157, i8** %t158
  %t159 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t159
  %t160 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t161 = load i8*, i8** %t160
  %t162 = call i32 @ReleaseSemaphore(i8* %t161, i32 1, i32* null)
  %t163 = mul i64 %t149, 1
  %t164 = sdiv i64 %t163, 4
  %t165 = mul i64 %t149, 2
  %t166 = sdiv i64 %t165, 4
  %t168 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t167, i32 0, i32 0
  store i64 %t164, i64* %t168
  %t169 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t167, i32 0, i32 1
  store i64 %t166, i64* %t169
  %t170 = bitcast { i64, i64 }* %t167 to i8*
  %t171 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t170, i8** %t171
  %t172 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t172
  %t173 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t174 = load i8*, i8** %t173
  %t175 = call i32 @ReleaseSemaphore(i8* %t174, i32 1, i32* null)
  %t176 = mul i64 %t149, 2
  %t177 = sdiv i64 %t176, 4
  %t178 = mul i64 %t149, 3
  %t179 = sdiv i64 %t178, 4
  %t181 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t180, i32 0, i32 0
  store i64 %t177, i64* %t181
  %t182 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t180, i32 0, i32 1
  store i64 %t179, i64* %t182
  %t183 = bitcast { i64, i64 }* %t180 to i8*
  %t184 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t183, i8** %t184
  %t185 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t185
  %t186 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t187 = load i8*, i8** %t186
  %t188 = call i32 @ReleaseSemaphore(i8* %t187, i32 1, i32* null)
  %t189 = mul i64 %t149, 3
  %t190 = sdiv i64 %t189, 4
  %t191 = mul i64 %t149, 4
  %t192 = sdiv i64 %t191, 4
  %t194 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t193, i32 0, i32 0
  store i64 %t190, i64* %t194
  %t195 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t193, i32 0, i32 1
  store i64 %t192, i64* %t195
  %t196 = bitcast { i64, i64 }* %t193 to i8*
  %t197 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t196, i8** %t197
  %t198 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_24, i32 (i8*)** %t198
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
  br label %par_join_35
par_serial_31:
  %t214 = load i32, i32* @par.pool.serial_owner
  %t215 = icmp eq i32 %t214, %t147
  br i1 %t215, label %par_run_33, label %par_acquire_32
par_acquire_32:
  %t216 = load i8*, i8** @par.pool.serial_lock
  %t217 = call i32 @WaitForSingleObject(i8* %t216, i32 -1)
  store i32 %t147, i32* @par.pool.serial_owner
  br label %par_run_33
par_run_33:
  %t218 = load i64, i64* @arena.Enemies.count
  %t220 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t219, i32 0, i32 0
  store i64 0, i64* %t220
  %t221 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t219, i32 0, i32 1
  store i64 %t218, i64* %t221
  %t222 = bitcast { i64, i64 }* %t219 to i8*
  %t223 = call i32 @par_worker_24(i8* %t222)
  br i1 %t215, label %par_join_35, label %par_release_34
par_release_34:
  store i32 -1, i32* @par.pool.serial_owner
  %t224 = load i8*, i8** @par.pool.serial_lock
  %t225 = call i32 @ReleaseSemaphore(i8* %t224, i32 1, i32* null)
  br label %par_join_35
par_join_35:
  call void @par.pool.ensure_init()
  %t244 = call i32 @GetCurrentThreadId()
  %t245 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t246 = load i32, i32* %t245
  %t247 = icmp eq i32 %t244, %t246
  %t248 = select i1 %t247, i32 0, i32 -1
  %t249 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t250 = load i32, i32* %t249
  %t251 = icmp eq i32 %t244, %t250
  %t252 = select i1 %t251, i32 1, i32 %t248
  %t253 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t254 = load i32, i32* %t253
  %t255 = icmp eq i32 %t244, %t254
  %t256 = select i1 %t255, i32 2, i32 %t252
  %t257 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t258 = load i32, i32* %t257
  %t259 = icmp eq i32 %t244, %t258
  %t260 = select i1 %t259, i32 3, i32 %t256
  %t261 = icmp sge i32 %t260, 0
  br i1 %t261, label %par_serial_43, label %par_pooled_42
par_pooled_42:
  %t262 = load i64, i64* @arena.Enemies.count
  %t263 = mul i64 %t262, 0
  %t264 = sdiv i64 %t263, 4
  %t265 = mul i64 %t262, 1
  %t266 = sdiv i64 %t265, 4
  %t268 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t267, i32 0, i32 0
  store i64 %t264, i64* %t268
  %t269 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t267, i32 0, i32 1
  store i64 %t266, i64* %t269
  %t270 = bitcast { i64, i64 }* %t267 to i8*
  %t271 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t270, i8** %t271
  %t272 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_36, i32 (i8*)** %t272
  %t273 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t274 = load i8*, i8** %t273
  %t275 = call i32 @ReleaseSemaphore(i8* %t274, i32 1, i32* null)
  %t276 = mul i64 %t262, 1
  %t277 = sdiv i64 %t276, 4
  %t278 = mul i64 %t262, 2
  %t279 = sdiv i64 %t278, 4
  %t281 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t280, i32 0, i32 0
  store i64 %t277, i64* %t281
  %t282 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t280, i32 0, i32 1
  store i64 %t279, i64* %t282
  %t283 = bitcast { i64, i64 }* %t280 to i8*
  %t284 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t283, i8** %t284
  %t285 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_36, i32 (i8*)** %t285
  %t286 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t287 = load i8*, i8** %t286
  %t288 = call i32 @ReleaseSemaphore(i8* %t287, i32 1, i32* null)
  %t289 = mul i64 %t262, 2
  %t290 = sdiv i64 %t289, 4
  %t291 = mul i64 %t262, 3
  %t292 = sdiv i64 %t291, 4
  %t294 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t293, i32 0, i32 0
  store i64 %t290, i64* %t294
  %t295 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t293, i32 0, i32 1
  store i64 %t292, i64* %t295
  %t296 = bitcast { i64, i64 }* %t293 to i8*
  %t297 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t296, i8** %t297
  %t298 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_36, i32 (i8*)** %t298
  %t299 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t300 = load i8*, i8** %t299
  %t301 = call i32 @ReleaseSemaphore(i8* %t300, i32 1, i32* null)
  %t302 = mul i64 %t262, 3
  %t303 = sdiv i64 %t302, 4
  %t304 = mul i64 %t262, 4
  %t305 = sdiv i64 %t304, 4
  %t307 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t306, i32 0, i32 0
  store i64 %t303, i64* %t307
  %t308 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t306, i32 0, i32 1
  store i64 %t305, i64* %t308
  %t309 = bitcast { i64, i64 }* %t306 to i8*
  %t310 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t309, i8** %t310
  %t311 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_36, i32 (i8*)** %t311
  %t312 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t313 = load i8*, i8** %t312
  %t314 = call i32 @ReleaseSemaphore(i8* %t313, i32 1, i32* null)
  %t315 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t316 = load i8*, i8** %t315
  %t317 = call i32 @WaitForSingleObject(i8* %t316, i32 -1)
  %t318 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t319 = load i8*, i8** %t318
  %t320 = call i32 @WaitForSingleObject(i8* %t319, i32 -1)
  %t321 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t322 = load i8*, i8** %t321
  %t323 = call i32 @WaitForSingleObject(i8* %t322, i32 -1)
  %t324 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t325 = load i8*, i8** %t324
  %t326 = call i32 @WaitForSingleObject(i8* %t325, i32 -1)
  br label %par_join_47
par_serial_43:
  %t327 = load i32, i32* @par.pool.serial_owner
  %t328 = icmp eq i32 %t327, %t260
  br i1 %t328, label %par_run_45, label %par_acquire_44
par_acquire_44:
  %t329 = load i8*, i8** @par.pool.serial_lock
  %t330 = call i32 @WaitForSingleObject(i8* %t329, i32 -1)
  store i32 %t260, i32* @par.pool.serial_owner
  br label %par_run_45
par_run_45:
  %t331 = load i64, i64* @arena.Enemies.count
  %t333 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t332, i32 0, i32 0
  store i64 0, i64* %t333
  %t334 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t332, i32 0, i32 1
  store i64 %t331, i64* %t334
  %t335 = bitcast { i64, i64 }* %t332 to i8*
  %t336 = call i32 @par_worker_36(i8* %t335)
  br i1 %t328, label %par_join_47, label %par_release_46
par_release_46:
  store i32 -1, i32* @par.pool.serial_owner
  %t337 = load i8*, i8** @par.pool.serial_lock
  %t338 = call i32 @ReleaseSemaphore(i8* %t337, i32 1, i32* null)
  br label %par_join_47
par_join_47:
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_24(i8* %argp) {
entry:
  %t81 = alloca i64
  %t75 = bitcast i8* %argp to { i64, i64 }*
  %t76 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t75, i32 0, i32 0
  %t77 = load i64, i64* %t76
  %t78 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t75, i32 0, i32 1
  %t79 = load i64, i64* %t78
  %t80 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t77, i64* %t81
  br label %par_cond_25
par_cond_25:
  %t82 = load i64, i64* %t81
  %t83 = icmp slt i64 %t82, %t79
  br i1 %t83, label %par_body_26, label %par_end_29
par_body_26:
  %t84 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t82
  %t85 = load i32, i32* %t84
  %t86 = and i32 %t85, 1
  %t87 = icmp eq i32 %t86, 1
  br i1 %t87, label %par_live_27, label %par_incr_28
par_live_27:
  %t88 = getelementptr inbounds %Enemy, %Enemy* %t80, i64 %t82
  %t89 = getelementptr inbounds %Enemy, %Enemy* %t88, i32 0, i32 0
  %t90 = load i32, i32* %t89
  %t91 = sub i32 %t90, 1
  %t92 = getelementptr inbounds %Enemy, %Enemy* %t88, i32 0, i32 0
  store i32 %t91, i32* %t92
  br label %par_incr_28
par_incr_28:
  %t93 = add i64 %t82, 1
  store i64 %t93, i64* %t81
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
  %t94 = ptrtoint i8* %idx_arg to i64
  %t95 = trunc i64 %t94 to i32
  %t96 = call i32 @GetCurrentThreadId()
  %t97 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t95
  store i32 %t96, i32* %t97
  br label %loop
loop:
  %t98 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t95
  %t99 = load i8*, i8** %t98
  %t100 = call i32 @WaitForSingleObject(i8* %t99, i32 -1)
  %t101 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t95
  %t102 = load i32 (i8*)*, i32 (i8*)** %t101
  %t103 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t95
  %t104 = load i8*, i8** %t103
  %t105 = call i32 %t102(i8* %t104)
  %t106 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t95
  %t107 = load i8*, i8** %t106
  %t108 = call i32 @ReleaseSemaphore(i8* %t107, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t109 = load i1, i1* @par.pool.inited
  br i1 %t109, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t110 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t110, i8** @par.pool.serial_lock
  %t111 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t112 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t111, i8** %t112
  %t113 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t114 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t113, i8** %t114
  %t115 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t116 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t117 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t116, i8** %t117
  %t118 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t119 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t118, i8** %t119
  %t120 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t121 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t122 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t121, i8** %t122
  %t123 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t124 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t123, i8** %t124
  %t125 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t126 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t127 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t126, i8** %t127
  %t128 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t129 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t128, i8** %t129
  %t130 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_36(i8* %argp) {
entry:
  %t232 = alloca i64
  %t226 = bitcast i8* %argp to { i64, i64 }*
  %t227 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t226, i32 0, i32 0
  %t228 = load i64, i64* %t227
  %t229 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t226, i32 0, i32 1
  %t230 = load i64, i64* %t229
  %t231 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t228, i64* %t232
  br label %par_cond_37
par_cond_37:
  %t233 = load i64, i64* %t232
  %t234 = icmp slt i64 %t233, %t230
  br i1 %t234, label %par_body_38, label %par_end_41
par_body_38:
  %t235 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t233
  %t236 = load i32, i32* %t235
  %t237 = and i32 %t236, 1
  %t238 = icmp eq i32 %t237, 1
  br i1 %t238, label %par_live_39, label %par_incr_40
par_live_39:
  %t239 = getelementptr inbounds %Enemy, %Enemy* %t231, i64 %t233
  %t240 = getelementptr inbounds %Enemy, %Enemy* %t239, i32 0, i32 0
  %t241 = load i32, i32* %t240
  %t242 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t242, i32 %t241)
  br label %par_incr_40
par_incr_40:
  %t243 = add i64 %t233, 1
  store i64 %t243, i64* %t232
  br label %par_cond_37
par_end_41:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [8 x i8] c"hp: %d\0A\00"
