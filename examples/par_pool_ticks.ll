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
  %t75 = alloca i32
  %t159 = alloca { i64, i64, i32* }
  %t173 = alloca { i64, i64, i32* }
  %t187 = alloca { i64, i64, i32* }
  %t201 = alloca { i64, i64, i32* }
  %t228 = alloca { i64, i64, i32* }
  %t279 = alloca { i64, i64 }
  %t292 = alloca { i64, i64 }
  %t305 = alloca { i64, i64 }
  %t318 = alloca { i64, i64 }
  %t344 = alloca { i64, i64 }
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
  store i32 100, i32* %t19
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
  store i32 100, i32* %t44
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
  store i32 100, i32* %t69
  %t70 = load %Enemy, %Enemy* %t68
  %t71 = getelementptr inbounds %Enemy, %Enemy* %t57, i64 %t67
  store %Enemy %t70, %Enemy* %t71
  %t72 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t67
  %t73 = load i32, i32* %t72
  %t74 = add i32 %t73, 1
  store i32 %t74, i32* %t72
  br label %spawn_end_21
spawn_end_21:
  store i32 0, i32* %t75
  br label %for_cond_24
for_cond_24:
  %t76 = load i32, i32* %t75
  %t77 = icmp slt i32 %t76, 5
  br i1 %t77, label %for_body_25, label %for_end_27
for_body_25:
  call void @par.pool.ensure_init()
  %t136 = call i32 @GetCurrentThreadId()
  %t137 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t138 = load i32, i32* %t137
  %t139 = icmp eq i32 %t136, %t138
  %t140 = select i1 %t139, i32 0, i32 -1
  %t141 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t142 = load i32, i32* %t141
  %t143 = icmp eq i32 %t136, %t142
  %t144 = select i1 %t143, i32 1, i32 %t140
  %t145 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t146 = load i32, i32* %t145
  %t147 = icmp eq i32 %t136, %t146
  %t148 = select i1 %t147, i32 2, i32 %t144
  %t149 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t150 = load i32, i32* %t149
  %t151 = icmp eq i32 %t136, %t150
  %t152 = select i1 %t151, i32 3, i32 %t148
  %t153 = icmp sge i32 %t152, 0
  br i1 %t153, label %par_serial_35, label %par_pooled_34
par_pooled_34:
  %t154 = load i64, i64* @arena.Enemies.count
  %t155 = mul i64 %t154, 0
  %t156 = sdiv i64 %t155, 4
  %t157 = mul i64 %t154, 1
  %t158 = sdiv i64 %t157, 4
  %t160 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t159, i32 0, i32 0
  store i64 %t156, i64* %t160
  %t161 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t159, i32 0, i32 1
  store i64 %t158, i64* %t161
  %t162 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t159, i32 0, i32 2
  store i32* %t75, i32** %t162
  %t163 = bitcast { i64, i64, i32* }* %t159 to i8*
  %t164 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t163, i8** %t164
  %t165 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t165
  %t166 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t167 = load i8*, i8** %t166
  %t168 = call i32 @ReleaseSemaphore(i8* %t167, i32 1, i32* null)
  %t169 = mul i64 %t154, 1
  %t170 = sdiv i64 %t169, 4
  %t171 = mul i64 %t154, 2
  %t172 = sdiv i64 %t171, 4
  %t174 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t173, i32 0, i32 0
  store i64 %t170, i64* %t174
  %t175 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t173, i32 0, i32 1
  store i64 %t172, i64* %t175
  %t176 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t173, i32 0, i32 2
  store i32* %t75, i32** %t176
  %t177 = bitcast { i64, i64, i32* }* %t173 to i8*
  %t178 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t177, i8** %t178
  %t179 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t179
  %t180 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t181 = load i8*, i8** %t180
  %t182 = call i32 @ReleaseSemaphore(i8* %t181, i32 1, i32* null)
  %t183 = mul i64 %t154, 2
  %t184 = sdiv i64 %t183, 4
  %t185 = mul i64 %t154, 3
  %t186 = sdiv i64 %t185, 4
  %t188 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t187, i32 0, i32 0
  store i64 %t184, i64* %t188
  %t189 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t187, i32 0, i32 1
  store i64 %t186, i64* %t189
  %t190 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t187, i32 0, i32 2
  store i32* %t75, i32** %t190
  %t191 = bitcast { i64, i64, i32* }* %t187 to i8*
  %t192 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t191, i8** %t192
  %t193 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t193
  %t194 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t195 = load i8*, i8** %t194
  %t196 = call i32 @ReleaseSemaphore(i8* %t195, i32 1, i32* null)
  %t197 = mul i64 %t154, 3
  %t198 = sdiv i64 %t197, 4
  %t199 = mul i64 %t154, 4
  %t200 = sdiv i64 %t199, 4
  %t202 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t201, i32 0, i32 0
  store i64 %t198, i64* %t202
  %t203 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t201, i32 0, i32 1
  store i64 %t200, i64* %t203
  %t204 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t201, i32 0, i32 2
  store i32* %t75, i32** %t204
  %t205 = bitcast { i64, i64, i32* }* %t201 to i8*
  %t206 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t205, i8** %t206
  %t207 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t207
  %t208 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t209 = load i8*, i8** %t208
  %t210 = call i32 @ReleaseSemaphore(i8* %t209, i32 1, i32* null)
  %t211 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t212 = load i8*, i8** %t211
  %t213 = call i32 @WaitForSingleObject(i8* %t212, i32 -1)
  %t214 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t215 = load i8*, i8** %t214
  %t216 = call i32 @WaitForSingleObject(i8* %t215, i32 -1)
  %t217 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t218 = load i8*, i8** %t217
  %t219 = call i32 @WaitForSingleObject(i8* %t218, i32 -1)
  %t220 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t221 = load i8*, i8** %t220
  %t222 = call i32 @WaitForSingleObject(i8* %t221, i32 -1)
  br label %par_join_39
par_serial_35:
  %t223 = load i32, i32* @par.pool.serial_owner
  %t224 = icmp eq i32 %t223, %t152
  br i1 %t224, label %par_run_37, label %par_acquire_36
par_acquire_36:
  %t225 = load i8*, i8** @par.pool.serial_lock
  %t226 = call i32 @WaitForSingleObject(i8* %t225, i32 -1)
  store i32 %t152, i32* @par.pool.serial_owner
  br label %par_run_37
par_run_37:
  %t227 = load i64, i64* @arena.Enemies.count
  %t229 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t228, i32 0, i32 0
  store i64 0, i64* %t229
  %t230 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t228, i32 0, i32 1
  store i64 %t227, i64* %t230
  %t231 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t228, i32 0, i32 2
  store i32* %t75, i32** %t231
  %t232 = bitcast { i64, i64, i32* }* %t228 to i8*
  %t233 = call i32 @par_worker_28(i8* %t232)
  br i1 %t224, label %par_join_39, label %par_release_38
par_release_38:
  store i32 -1, i32* @par.pool.serial_owner
  %t234 = load i8*, i8** @par.pool.serial_lock
  %t235 = call i32 @ReleaseSemaphore(i8* %t234, i32 1, i32* null)
  br label %par_join_39
par_join_39:
  br label %for_step_26
for_step_26:
  %t236 = load i32, i32* %t75
  %t237 = add i32 %t236, 1
  store i32 %t237, i32* %t75
  br label %for_cond_24
for_end_27:
  call void @par.pool.ensure_init()
  %t256 = call i32 @GetCurrentThreadId()
  %t257 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t258 = load i32, i32* %t257
  %t259 = icmp eq i32 %t256, %t258
  %t260 = select i1 %t259, i32 0, i32 -1
  %t261 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t262 = load i32, i32* %t261
  %t263 = icmp eq i32 %t256, %t262
  %t264 = select i1 %t263, i32 1, i32 %t260
  %t265 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t266 = load i32, i32* %t265
  %t267 = icmp eq i32 %t256, %t266
  %t268 = select i1 %t267, i32 2, i32 %t264
  %t269 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t270 = load i32, i32* %t269
  %t271 = icmp eq i32 %t256, %t270
  %t272 = select i1 %t271, i32 3, i32 %t268
  %t273 = icmp sge i32 %t272, 0
  br i1 %t273, label %par_serial_47, label %par_pooled_46
par_pooled_46:
  %t274 = load i64, i64* @arena.Enemies.count
  %t275 = mul i64 %t274, 0
  %t276 = sdiv i64 %t275, 4
  %t277 = mul i64 %t274, 1
  %t278 = sdiv i64 %t277, 4
  %t280 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t279, i32 0, i32 0
  store i64 %t276, i64* %t280
  %t281 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t279, i32 0, i32 1
  store i64 %t278, i64* %t281
  %t282 = bitcast { i64, i64 }* %t279 to i8*
  %t283 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t282, i8** %t283
  %t284 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_40, i32 (i8*)** %t284
  %t285 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t286 = load i8*, i8** %t285
  %t287 = call i32 @ReleaseSemaphore(i8* %t286, i32 1, i32* null)
  %t288 = mul i64 %t274, 1
  %t289 = sdiv i64 %t288, 4
  %t290 = mul i64 %t274, 2
  %t291 = sdiv i64 %t290, 4
  %t293 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t292, i32 0, i32 0
  store i64 %t289, i64* %t293
  %t294 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t292, i32 0, i32 1
  store i64 %t291, i64* %t294
  %t295 = bitcast { i64, i64 }* %t292 to i8*
  %t296 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t295, i8** %t296
  %t297 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_40, i32 (i8*)** %t297
  %t298 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t299 = load i8*, i8** %t298
  %t300 = call i32 @ReleaseSemaphore(i8* %t299, i32 1, i32* null)
  %t301 = mul i64 %t274, 2
  %t302 = sdiv i64 %t301, 4
  %t303 = mul i64 %t274, 3
  %t304 = sdiv i64 %t303, 4
  %t306 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t305, i32 0, i32 0
  store i64 %t302, i64* %t306
  %t307 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t305, i32 0, i32 1
  store i64 %t304, i64* %t307
  %t308 = bitcast { i64, i64 }* %t305 to i8*
  %t309 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t308, i8** %t309
  %t310 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_40, i32 (i8*)** %t310
  %t311 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t312 = load i8*, i8** %t311
  %t313 = call i32 @ReleaseSemaphore(i8* %t312, i32 1, i32* null)
  %t314 = mul i64 %t274, 3
  %t315 = sdiv i64 %t314, 4
  %t316 = mul i64 %t274, 4
  %t317 = sdiv i64 %t316, 4
  %t319 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t318, i32 0, i32 0
  store i64 %t315, i64* %t319
  %t320 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t318, i32 0, i32 1
  store i64 %t317, i64* %t320
  %t321 = bitcast { i64, i64 }* %t318 to i8*
  %t322 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t321, i8** %t322
  %t323 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_40, i32 (i8*)** %t323
  %t324 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t325 = load i8*, i8** %t324
  %t326 = call i32 @ReleaseSemaphore(i8* %t325, i32 1, i32* null)
  %t327 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t328 = load i8*, i8** %t327
  %t329 = call i32 @WaitForSingleObject(i8* %t328, i32 -1)
  %t330 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t331 = load i8*, i8** %t330
  %t332 = call i32 @WaitForSingleObject(i8* %t331, i32 -1)
  %t333 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t334 = load i8*, i8** %t333
  %t335 = call i32 @WaitForSingleObject(i8* %t334, i32 -1)
  %t336 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t337 = load i8*, i8** %t336
  %t338 = call i32 @WaitForSingleObject(i8* %t337, i32 -1)
  br label %par_join_51
par_serial_47:
  %t339 = load i32, i32* @par.pool.serial_owner
  %t340 = icmp eq i32 %t339, %t272
  br i1 %t340, label %par_run_49, label %par_acquire_48
par_acquire_48:
  %t341 = load i8*, i8** @par.pool.serial_lock
  %t342 = call i32 @WaitForSingleObject(i8* %t341, i32 -1)
  store i32 %t272, i32* @par.pool.serial_owner
  br label %par_run_49
par_run_49:
  %t343 = load i64, i64* @arena.Enemies.count
  %t345 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t344, i32 0, i32 0
  store i64 0, i64* %t345
  %t346 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t344, i32 0, i32 1
  store i64 %t343, i64* %t346
  %t347 = bitcast { i64, i64 }* %t344 to i8*
  %t348 = call i32 @par_worker_40(i8* %t347)
  br i1 %t340, label %par_join_51, label %par_release_50
par_release_50:
  store i32 -1, i32* @par.pool.serial_owner
  %t349 = load i8*, i8** @par.pool.serial_lock
  %t350 = call i32 @ReleaseSemaphore(i8* %t349, i32 1, i32* null)
  br label %par_join_51
par_join_51:
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_28(i8* %argp) {
entry:
  %t86 = alloca i64
  %t78 = bitcast i8* %argp to { i64, i64, i32* }*
  %t79 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t78, i32 0, i32 0
  %t80 = load i64, i64* %t79
  %t81 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t78, i32 0, i32 1
  %t82 = load i64, i64* %t81
  %t83 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t78, i32 0, i32 2
  %t84 = load i32*, i32** %t83
  %t85 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t80, i64* %t86
  br label %par_cond_29
par_cond_29:
  %t87 = load i64, i64* %t86
  %t88 = icmp slt i64 %t87, %t82
  br i1 %t88, label %par_body_30, label %par_end_33
par_body_30:
  %t89 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t87
  %t90 = load i32, i32* %t89
  %t91 = and i32 %t90, 1
  %t92 = icmp eq i32 %t91, 1
  br i1 %t92, label %par_live_31, label %par_incr_32
par_live_31:
  %t93 = getelementptr inbounds %Enemy, %Enemy* %t85, i64 %t87
  %t94 = getelementptr inbounds %Enemy, %Enemy* %t93, i32 0, i32 0
  %t95 = load i32, i32* %t94
  %t96 = sub i32 %t95, 1
  %t97 = getelementptr inbounds %Enemy, %Enemy* %t93, i32 0, i32 0
  store i32 %t96, i32* %t97
  br label %par_incr_32
par_incr_32:
  %t98 = add i64 %t87, 1
  store i64 %t98, i64* %t86
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
  %t99 = ptrtoint i8* %idx_arg to i64
  %t100 = trunc i64 %t99 to i32
  %t101 = call i32 @GetCurrentThreadId()
  %t102 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t100
  store i32 %t101, i32* %t102
  br label %loop
loop:
  %t103 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t100
  %t104 = load i8*, i8** %t103
  %t105 = call i32 @WaitForSingleObject(i8* %t104, i32 -1)
  %t106 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t100
  %t107 = load i32 (i8*)*, i32 (i8*)** %t106
  %t108 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t100
  %t109 = load i8*, i8** %t108
  %t110 = call i32 %t107(i8* %t109)
  %t111 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t100
  %t112 = load i8*, i8** %t111
  %t113 = call i32 @ReleaseSemaphore(i8* %t112, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t114 = load i1, i1* @par.pool.inited
  br i1 %t114, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t115 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t115, i8** @par.pool.serial_lock
  %t116 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t117 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t116, i8** %t117
  %t118 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t119 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t118, i8** %t119
  %t120 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t121 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t122 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t121, i8** %t122
  %t123 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t124 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t123, i8** %t124
  %t125 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t126 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t127 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t126, i8** %t127
  %t128 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t129 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t128, i8** %t129
  %t130 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t131 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t132 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t131, i8** %t132
  %t133 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t134 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t133, i8** %t134
  %t135 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_40(i8* %argp) {
entry:
  %t244 = alloca i64
  %t238 = bitcast i8* %argp to { i64, i64 }*
  %t239 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t238, i32 0, i32 0
  %t240 = load i64, i64* %t239
  %t241 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t238, i32 0, i32 1
  %t242 = load i64, i64* %t241
  %t243 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t240, i64* %t244
  br label %par_cond_41
par_cond_41:
  %t245 = load i64, i64* %t244
  %t246 = icmp slt i64 %t245, %t242
  br i1 %t246, label %par_body_42, label %par_end_45
par_body_42:
  %t247 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t245
  %t248 = load i32, i32* %t247
  %t249 = and i32 %t248, 1
  %t250 = icmp eq i32 %t249, 1
  br i1 %t250, label %par_live_43, label %par_incr_44
par_live_43:
  %t251 = getelementptr inbounds %Enemy, %Enemy* %t243, i64 %t245
  %t252 = getelementptr inbounds %Enemy, %Enemy* %t251, i32 0, i32 0
  %t253 = load i32, i32* %t252
  %t254 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t254, i32 %t253)
  br label %par_incr_44
par_incr_44:
  %t255 = add i64 %t245, 1
  store i64 %t255, i64* %t244
  br label %par_cond_41
par_end_45:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [8 x i8] c"hp: %d\0A\00"
