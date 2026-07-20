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
declare i32 @SDL_Init(i32)
declare i8* @SDL_CreateWindow(i8*, i32, i32, i32, i32, i32)
declare i8* @SDL_CreateRenderer(i8*, i32, i32)
declare i8* @SDL_GetRenderer(i8*)
declare void @SDL_DestroyRenderer(i8*)
declare void @SDL_DestroyWindow(i8*)
declare i32 @SDL_SetRenderDrawColor(i8*, i8, i8, i8, i8)
declare i32 @SDL_RenderClear(i8*)
declare i32 @SDL_RenderDrawPoint(i8*, i32, i32)
declare i32 @SDL_RenderFillRect(i8*, i8*)
declare i32 @SDL_RenderDrawLine(i8*, i32, i32, i32, i32)
declare void @SDL_RenderPresent(i8*)
declare i32 @SDL_PollEvent(i8*)
declare i8* @SDL_GetKeyboardState(i32*)
declare i32 @SDL_GetMouseState(i32*, i32*)
declare void @SDL_Delay(i32)
declare i32 @SDL_GetTicks()
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

%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t20 = alloca %Enemy
  %t45 = alloca %Enemy
  %t70 = alloca %Enemy
  %t77 = alloca i32
  %t161 = alloca { i64, i64, i32* }
  %t175 = alloca { i64, i64, i32* }
  %t189 = alloca { i64, i64, i32* }
  %t203 = alloca { i64, i64, i32* }
  %t230 = alloca { i64, i64, i32* }
  %t281 = alloca { i64, i64 }
  %t294 = alloca { i64, i64 }
  %t307 = alloca { i64, i64 }
  %t320 = alloca { i64, i64 }
  %t346 = alloca { i64, i64 }
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
  store i32 100, i32* %t21
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
  store i32 100, i32* %t46
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
  store i32 100, i32* %t71
  %t72 = load %Enemy, %Enemy* %t70
  %t73 = getelementptr inbounds %Enemy, %Enemy* %t59, i64 %t69
  store %Enemy %t72, %Enemy* %t73
  %t74 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t69
  %t75 = load i64, i64* %t74
  %t76 = add i64 %t75, 1
  store i64 %t76, i64* %t74
  br label %spawn_end_21
spawn_end_21:
  store i32 0, i32* %t77
  br label %for_cond_24
for_cond_24:
  %t78 = load i32, i32* %t77
  %t79 = icmp slt i32 %t78, 5
  br i1 %t79, label %for_body_25, label %for_end_27
for_body_25:
  call void @par.pool.ensure_init()
  %t138 = call i32 @GetCurrentThreadId()
  %t139 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t140 = load i32, i32* %t139
  %t141 = icmp eq i32 %t138, %t140
  %t142 = select i1 %t141, i32 0, i32 -1
  %t143 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t144 = load i32, i32* %t143
  %t145 = icmp eq i32 %t138, %t144
  %t146 = select i1 %t145, i32 1, i32 %t142
  %t147 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t148 = load i32, i32* %t147
  %t149 = icmp eq i32 %t138, %t148
  %t150 = select i1 %t149, i32 2, i32 %t146
  %t151 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t152 = load i32, i32* %t151
  %t153 = icmp eq i32 %t138, %t152
  %t154 = select i1 %t153, i32 3, i32 %t150
  %t155 = icmp sge i32 %t154, 0
  br i1 %t155, label %par_serial_35, label %par_pooled_34
par_pooled_34:
  %t156 = load i64, i64* @arena.Enemies.count
  %t157 = mul i64 %t156, 0
  %t158 = sdiv i64 %t157, 4
  %t159 = mul i64 %t156, 1
  %t160 = sdiv i64 %t159, 4
  %t162 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t161, i32 0, i32 0
  store i64 %t158, i64* %t162
  %t163 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t161, i32 0, i32 1
  store i64 %t160, i64* %t163
  %t164 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t161, i32 0, i32 2
  store i32* %t77, i32** %t164
  %t165 = bitcast { i64, i64, i32* }* %t161 to i8*
  %t166 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t165, i8** %t166
  %t167 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t167
  %t168 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t169 = load i8*, i8** %t168
  %t170 = call i32 @ReleaseSemaphore(i8* %t169, i32 1, i32* null)
  %t171 = mul i64 %t156, 1
  %t172 = sdiv i64 %t171, 4
  %t173 = mul i64 %t156, 2
  %t174 = sdiv i64 %t173, 4
  %t176 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t175, i32 0, i32 0
  store i64 %t172, i64* %t176
  %t177 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t175, i32 0, i32 1
  store i64 %t174, i64* %t177
  %t178 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t175, i32 0, i32 2
  store i32* %t77, i32** %t178
  %t179 = bitcast { i64, i64, i32* }* %t175 to i8*
  %t180 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t179, i8** %t180
  %t181 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t181
  %t182 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t183 = load i8*, i8** %t182
  %t184 = call i32 @ReleaseSemaphore(i8* %t183, i32 1, i32* null)
  %t185 = mul i64 %t156, 2
  %t186 = sdiv i64 %t185, 4
  %t187 = mul i64 %t156, 3
  %t188 = sdiv i64 %t187, 4
  %t190 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t189, i32 0, i32 0
  store i64 %t186, i64* %t190
  %t191 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t189, i32 0, i32 1
  store i64 %t188, i64* %t191
  %t192 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t189, i32 0, i32 2
  store i32* %t77, i32** %t192
  %t193 = bitcast { i64, i64, i32* }* %t189 to i8*
  %t194 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t193, i8** %t194
  %t195 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t195
  %t196 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t197 = load i8*, i8** %t196
  %t198 = call i32 @ReleaseSemaphore(i8* %t197, i32 1, i32* null)
  %t199 = mul i64 %t156, 3
  %t200 = sdiv i64 %t199, 4
  %t201 = mul i64 %t156, 4
  %t202 = sdiv i64 %t201, 4
  %t204 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t203, i32 0, i32 0
  store i64 %t200, i64* %t204
  %t205 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t203, i32 0, i32 1
  store i64 %t202, i64* %t205
  %t206 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t203, i32 0, i32 2
  store i32* %t77, i32** %t206
  %t207 = bitcast { i64, i64, i32* }* %t203 to i8*
  %t208 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t207, i8** %t208
  %t209 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t209
  %t210 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t211 = load i8*, i8** %t210
  %t212 = call i32 @ReleaseSemaphore(i8* %t211, i32 1, i32* null)
  %t213 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t214 = load i8*, i8** %t213
  %t215 = call i32 @WaitForSingleObject(i8* %t214, i32 -1)
  %t216 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t217 = load i8*, i8** %t216
  %t218 = call i32 @WaitForSingleObject(i8* %t217, i32 -1)
  %t219 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t220 = load i8*, i8** %t219
  %t221 = call i32 @WaitForSingleObject(i8* %t220, i32 -1)
  %t222 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t223 = load i8*, i8** %t222
  %t224 = call i32 @WaitForSingleObject(i8* %t223, i32 -1)
  br label %par_join_39
par_serial_35:
  %t225 = load i32, i32* @par.pool.serial_owner
  %t226 = icmp eq i32 %t225, %t154
  br i1 %t226, label %par_run_37, label %par_acquire_36
par_acquire_36:
  %t227 = load i8*, i8** @par.pool.serial_lock
  %t228 = call i32 @WaitForSingleObject(i8* %t227, i32 -1)
  store i32 %t154, i32* @par.pool.serial_owner
  br label %par_run_37
par_run_37:
  %t229 = load i64, i64* @arena.Enemies.count
  %t231 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t230, i32 0, i32 0
  store i64 0, i64* %t231
  %t232 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t230, i32 0, i32 1
  store i64 %t229, i64* %t232
  %t233 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t230, i32 0, i32 2
  store i32* %t77, i32** %t233
  %t234 = bitcast { i64, i64, i32* }* %t230 to i8*
  %t235 = call i32 @par_worker_28(i8* %t234)
  br i1 %t226, label %par_join_39, label %par_release_38
par_release_38:
  store i32 -1, i32* @par.pool.serial_owner
  %t236 = load i8*, i8** @par.pool.serial_lock
  %t237 = call i32 @ReleaseSemaphore(i8* %t236, i32 1, i32* null)
  br label %par_join_39
par_join_39:
  br label %for_step_26
for_step_26:
  %t238 = load i32, i32* %t77
  %t239 = add i32 %t238, 1
  store i32 %t239, i32* %t77
  br label %for_cond_24
for_end_27:
  call void @par.pool.ensure_init()
  %t258 = call i32 @GetCurrentThreadId()
  %t259 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t260 = load i32, i32* %t259
  %t261 = icmp eq i32 %t258, %t260
  %t262 = select i1 %t261, i32 0, i32 -1
  %t263 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t264 = load i32, i32* %t263
  %t265 = icmp eq i32 %t258, %t264
  %t266 = select i1 %t265, i32 1, i32 %t262
  %t267 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t268 = load i32, i32* %t267
  %t269 = icmp eq i32 %t258, %t268
  %t270 = select i1 %t269, i32 2, i32 %t266
  %t271 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t272 = load i32, i32* %t271
  %t273 = icmp eq i32 %t258, %t272
  %t274 = select i1 %t273, i32 3, i32 %t270
  %t275 = icmp sge i32 %t274, 0
  br i1 %t275, label %par_serial_47, label %par_pooled_46
par_pooled_46:
  %t276 = load i64, i64* @arena.Enemies.count
  %t277 = mul i64 %t276, 0
  %t278 = sdiv i64 %t277, 4
  %t279 = mul i64 %t276, 1
  %t280 = sdiv i64 %t279, 4
  %t282 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t281, i32 0, i32 0
  store i64 %t278, i64* %t282
  %t283 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t281, i32 0, i32 1
  store i64 %t280, i64* %t283
  %t284 = bitcast { i64, i64 }* %t281 to i8*
  %t285 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t284, i8** %t285
  %t286 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_40, i32 (i8*)** %t286
  %t287 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t288 = load i8*, i8** %t287
  %t289 = call i32 @ReleaseSemaphore(i8* %t288, i32 1, i32* null)
  %t290 = mul i64 %t276, 1
  %t291 = sdiv i64 %t290, 4
  %t292 = mul i64 %t276, 2
  %t293 = sdiv i64 %t292, 4
  %t295 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t294, i32 0, i32 0
  store i64 %t291, i64* %t295
  %t296 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t294, i32 0, i32 1
  store i64 %t293, i64* %t296
  %t297 = bitcast { i64, i64 }* %t294 to i8*
  %t298 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t297, i8** %t298
  %t299 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_40, i32 (i8*)** %t299
  %t300 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t301 = load i8*, i8** %t300
  %t302 = call i32 @ReleaseSemaphore(i8* %t301, i32 1, i32* null)
  %t303 = mul i64 %t276, 2
  %t304 = sdiv i64 %t303, 4
  %t305 = mul i64 %t276, 3
  %t306 = sdiv i64 %t305, 4
  %t308 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t307, i32 0, i32 0
  store i64 %t304, i64* %t308
  %t309 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t307, i32 0, i32 1
  store i64 %t306, i64* %t309
  %t310 = bitcast { i64, i64 }* %t307 to i8*
  %t311 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t310, i8** %t311
  %t312 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_40, i32 (i8*)** %t312
  %t313 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t314 = load i8*, i8** %t313
  %t315 = call i32 @ReleaseSemaphore(i8* %t314, i32 1, i32* null)
  %t316 = mul i64 %t276, 3
  %t317 = sdiv i64 %t316, 4
  %t318 = mul i64 %t276, 4
  %t319 = sdiv i64 %t318, 4
  %t321 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t320, i32 0, i32 0
  store i64 %t317, i64* %t321
  %t322 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t320, i32 0, i32 1
  store i64 %t319, i64* %t322
  %t323 = bitcast { i64, i64 }* %t320 to i8*
  %t324 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t323, i8** %t324
  %t325 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_40, i32 (i8*)** %t325
  %t326 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t327 = load i8*, i8** %t326
  %t328 = call i32 @ReleaseSemaphore(i8* %t327, i32 1, i32* null)
  %t329 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t330 = load i8*, i8** %t329
  %t331 = call i32 @WaitForSingleObject(i8* %t330, i32 -1)
  %t332 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t333 = load i8*, i8** %t332
  %t334 = call i32 @WaitForSingleObject(i8* %t333, i32 -1)
  %t335 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t336 = load i8*, i8** %t335
  %t337 = call i32 @WaitForSingleObject(i8* %t336, i32 -1)
  %t338 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t339 = load i8*, i8** %t338
  %t340 = call i32 @WaitForSingleObject(i8* %t339, i32 -1)
  br label %par_join_51
par_serial_47:
  %t341 = load i32, i32* @par.pool.serial_owner
  %t342 = icmp eq i32 %t341, %t274
  br i1 %t342, label %par_run_49, label %par_acquire_48
par_acquire_48:
  %t343 = load i8*, i8** @par.pool.serial_lock
  %t344 = call i32 @WaitForSingleObject(i8* %t343, i32 -1)
  store i32 %t274, i32* @par.pool.serial_owner
  br label %par_run_49
par_run_49:
  %t345 = load i64, i64* @arena.Enemies.count
  %t347 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t346, i32 0, i32 0
  store i64 0, i64* %t347
  %t348 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t346, i32 0, i32 1
  store i64 %t345, i64* %t348
  %t349 = bitcast { i64, i64 }* %t346 to i8*
  %t350 = call i32 @par_worker_40(i8* %t349)
  br i1 %t342, label %par_join_51, label %par_release_50
par_release_50:
  store i32 -1, i32* @par.pool.serial_owner
  %t351 = load i8*, i8** @par.pool.serial_lock
  %t352 = call i32 @ReleaseSemaphore(i8* %t351, i32 1, i32* null)
  br label %par_join_51
par_join_51:
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_28(i8* %argp) {
entry:
  %t88 = alloca i64
  %t80 = bitcast i8* %argp to { i64, i64, i32* }*
  %t81 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t80, i32 0, i32 0
  %t82 = load i64, i64* %t81
  %t83 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t80, i32 0, i32 1
  %t84 = load i64, i64* %t83
  %t85 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t80, i32 0, i32 2
  %t86 = load i32*, i32** %t85
  %t87 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t82, i64* %t88
  br label %par_cond_29
par_cond_29:
  %t89 = load i64, i64* %t88
  %t90 = icmp slt i64 %t89, %t84
  br i1 %t90, label %par_body_30, label %par_end_33
par_body_30:
  %t91 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t89
  %t92 = load i64, i64* %t91
  %t93 = and i64 %t92, 1
  %t94 = icmp eq i64 %t93, 1
  br i1 %t94, label %par_live_31, label %par_incr_32
par_live_31:
  %t95 = getelementptr inbounds %Enemy, %Enemy* %t87, i64 %t89
  %t96 = getelementptr inbounds %Enemy, %Enemy* %t95, i32 0, i32 0
  %t97 = load i32, i32* %t96
  %t98 = sub i32 %t97, 1
  %t99 = getelementptr inbounds %Enemy, %Enemy* %t95, i32 0, i32 0
  store i32 %t98, i32* %t99
  br label %par_incr_32
par_incr_32:
  %t100 = add i64 %t89, 1
  store i64 %t100, i64* %t88
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
  %t101 = ptrtoint i8* %idx_arg to i64
  %t102 = trunc i64 %t101 to i32
  %t103 = call i32 @GetCurrentThreadId()
  %t104 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t102
  store i32 %t103, i32* %t104
  br label %loop
loop:
  %t105 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t102
  %t106 = load i8*, i8** %t105
  %t107 = call i32 @WaitForSingleObject(i8* %t106, i32 -1)
  %t108 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t102
  %t109 = load i32 (i8*)*, i32 (i8*)** %t108
  %t110 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t102
  %t111 = load i8*, i8** %t110
  %t112 = call i32 %t109(i8* %t111)
  %t113 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t102
  %t114 = load i8*, i8** %t113
  %t115 = call i32 @ReleaseSemaphore(i8* %t114, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t116 = load i1, i1* @par.pool.inited
  br i1 %t116, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t117 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t117, i8** @par.pool.serial_lock
  %t118 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t119 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t118, i8** %t119
  %t120 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t121 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t120, i8** %t121
  %t122 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t123 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t124 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t123, i8** %t124
  %t125 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t126 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t125, i8** %t126
  %t127 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t128 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t129 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t128, i8** %t129
  %t130 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t131 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t130, i8** %t131
  %t132 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t133 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t134 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t133, i8** %t134
  %t135 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t136 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t135, i8** %t136
  %t137 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_40(i8* %argp) {
entry:
  %t246 = alloca i64
  %t240 = bitcast i8* %argp to { i64, i64 }*
  %t241 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t240, i32 0, i32 0
  %t242 = load i64, i64* %t241
  %t243 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t240, i32 0, i32 1
  %t244 = load i64, i64* %t243
  %t245 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t242, i64* %t246
  br label %par_cond_41
par_cond_41:
  %t247 = load i64, i64* %t246
  %t248 = icmp slt i64 %t247, %t244
  br i1 %t248, label %par_body_42, label %par_end_45
par_body_42:
  %t249 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t247
  %t250 = load i64, i64* %t249
  %t251 = and i64 %t250, 1
  %t252 = icmp eq i64 %t251, 1
  br i1 %t252, label %par_live_43, label %par_incr_44
par_live_43:
  %t253 = getelementptr inbounds %Enemy, %Enemy* %t245, i64 %t247
  %t254 = getelementptr inbounds %Enemy, %Enemy* %t253, i32 0, i32 0
  %t255 = load i32, i32* %t254
  %t256 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t256, i32 %t255)
  br label %par_incr_44
par_incr_44:
  %t257 = add i64 %t247, 1
  store i64 %t257, i64* %t246
  br label %par_cond_41
par_end_45:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [8 x i8] c"hp: %d\0A\00"
