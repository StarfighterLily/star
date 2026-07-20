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

%Entity = type { i64 }
%Entities = type { %Entity*, i64 }
@arena.Entities.data = global %Entity* null
@arena.Entities.count = global i64 0
@arena.Entities.gen = global [1024 x i64] zeroinitializer
@arena.Entities.free = global [1024 x i64] zeroinitializer
@arena.Entities.free_top = global i64 0

%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca i32
  %t23 = alloca %Entity
  %t33 = alloca i32
  %t129 = alloca { i64, i64, i32* }
  %t143 = alloca { i64, i64, i32* }
  %t157 = alloca { i64, i64, i32* }
  %t171 = alloca { i64, i64, i32* }
  %t198 = alloca { i64, i64, i32* }
  %t249 = alloca { i64, i64, i32* }
  %t263 = alloca { i64, i64, i32* }
  %t277 = alloca { i64, i64, i32* }
  %t291 = alloca { i64, i64, i32* }
  %t318 = alloca { i64, i64, i32* }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  store i32 0, i32* %t2
  br label %for_cond_0
for_cond_0:
  %t3 = load i32, i32* %t2
  %t4 = icmp slt i32 %t3, 64
  br i1 %t4, label %for_body_1, label %for_end_3
for_body_1:
  %t5 = load %Entity*, %Entity** @arena.Entities.data
  %t6 = icmp eq %Entity* %t5, null
  br i1 %t6, label %spawn_init_4, label %spawn_ready_5
spawn_init_4:
  %t7 = getelementptr %Entity, %Entity* null, i32 1
  %t8 = ptrtoint %Entity* %t7 to i64
  %t9 = mul i64 %t8, 1024
  %t10 = call i8* @malloc(i64 %t9)
  %t11 = bitcast i8* %t10 to %Entity*
  store %Entity* %t11, %Entity** @arena.Entities.data
  br label %spawn_ready_5
spawn_ready_5:
  %t12 = load %Entity*, %Entity** @arena.Entities.data
  %t13 = load i64, i64* @arena.Entities.free_top
  %t14 = icmp sgt i64 %t13, 0
  br i1 %t14, label %spawn_reuse_6, label %spawn_grow_7
spawn_reuse_6:
  %t15 = sub i64 %t13, 1
  store i64 %t15, i64* @arena.Entities.free_top
  %t16 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t15
  %t17 = load i64, i64* %t16
  br label %spawn_store_8
spawn_grow_7:
  %t18 = load i64, i64* @arena.Entities.count
  %t19 = icmp slt i64 %t18, 1024
  br i1 %t19, label %spawn_grow_ok_10, label %spawn_capacity_warn_11
spawn_capacity_warn_11:
  %t20 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t20)
  br label %spawn_end_9
spawn_grow_ok_10:
  %t21 = add i64 %t18, 1
  store i64 %t21, i64* @arena.Entities.count
  br label %spawn_store_8
spawn_store_8:
  %t22 = phi i64 [ %t17, %spawn_reuse_6 ], [ %t18, %spawn_grow_ok_10 ]
  %t24 = sext i32 0 to i64
  %t25 = getelementptr inbounds %Entity, %Entity* %t23, i32 0, i32 0
  store i64 %t24, i64* %t25
  %t26 = load %Entity, %Entity* %t23
  %t27 = getelementptr inbounds %Entity, %Entity* %t12, i64 %t22
  store %Entity %t26, %Entity* %t27
  %t28 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t22
  %t29 = load i64, i64* %t28
  %t30 = add i64 %t29, 1
  store i64 %t30, i64* %t28
  br label %spawn_end_9
spawn_end_9:
  br label %for_step_2
for_step_2:
  %t31 = load i32, i32* %t2
  %t32 = add i32 %t31, 1
  store i32 %t32, i32* %t2
  br label %for_cond_0
for_end_3:
  store i32 0, i32* %t33
  br label %for_cond_12
for_cond_12:
  %t34 = load i32, i32* %t33
  %t35 = icmp slt i32 %t34, 200
  br i1 %t35, label %for_body_13, label %for_end_15
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
  %t124 = load i64, i64* @arena.Entities.count
  %t125 = mul i64 %t124, 0
  %t126 = sdiv i64 %t125, 4
  %t127 = mul i64 %t124, 1
  %t128 = sdiv i64 %t127, 4
  %t130 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t129, i32 0, i32 0
  store i64 %t126, i64* %t130
  %t131 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t129, i32 0, i32 1
  store i64 %t128, i64* %t131
  %t132 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t129, i32 0, i32 2
  store i32* %t33, i32** %t132
  %t133 = bitcast { i64, i64, i32* }* %t129 to i8*
  %t134 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t133, i8** %t134
  %t135 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t135
  %t136 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t137 = load i8*, i8** %t136
  %t138 = call i32 @ReleaseSemaphore(i8* %t137, i32 1, i32* null)
  %t139 = mul i64 %t124, 1
  %t140 = sdiv i64 %t139, 4
  %t141 = mul i64 %t124, 2
  %t142 = sdiv i64 %t141, 4
  %t144 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t143, i32 0, i32 0
  store i64 %t140, i64* %t144
  %t145 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t143, i32 0, i32 1
  store i64 %t142, i64* %t145
  %t146 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t143, i32 0, i32 2
  store i32* %t33, i32** %t146
  %t147 = bitcast { i64, i64, i32* }* %t143 to i8*
  %t148 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t147, i8** %t148
  %t149 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t149
  %t150 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t151 = load i8*, i8** %t150
  %t152 = call i32 @ReleaseSemaphore(i8* %t151, i32 1, i32* null)
  %t153 = mul i64 %t124, 2
  %t154 = sdiv i64 %t153, 4
  %t155 = mul i64 %t124, 3
  %t156 = sdiv i64 %t155, 4
  %t158 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t157, i32 0, i32 0
  store i64 %t154, i64* %t158
  %t159 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t157, i32 0, i32 1
  store i64 %t156, i64* %t159
  %t160 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t157, i32 0, i32 2
  store i32* %t33, i32** %t160
  %t161 = bitcast { i64, i64, i32* }* %t157 to i8*
  %t162 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t161, i8** %t162
  %t163 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t163
  %t164 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t165 = load i8*, i8** %t164
  %t166 = call i32 @ReleaseSemaphore(i8* %t165, i32 1, i32* null)
  %t167 = mul i64 %t124, 3
  %t168 = sdiv i64 %t167, 4
  %t169 = mul i64 %t124, 4
  %t170 = sdiv i64 %t169, 4
  %t172 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t171, i32 0, i32 0
  store i64 %t168, i64* %t172
  %t173 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t171, i32 0, i32 1
  store i64 %t170, i64* %t173
  %t174 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t171, i32 0, i32 2
  store i32* %t33, i32** %t174
  %t175 = bitcast { i64, i64, i32* }* %t171 to i8*
  %t176 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t175, i8** %t176
  %t177 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t177
  %t178 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t179 = load i8*, i8** %t178
  %t180 = call i32 @ReleaseSemaphore(i8* %t179, i32 1, i32* null)
  %t181 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t182 = load i8*, i8** %t181
  %t183 = call i32 @WaitForSingleObject(i8* %t182, i32 -1)
  %t184 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t185 = load i8*, i8** %t184
  %t186 = call i32 @WaitForSingleObject(i8* %t185, i32 -1)
  %t187 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t188 = load i8*, i8** %t187
  %t189 = call i32 @WaitForSingleObject(i8* %t188, i32 -1)
  %t190 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t191 = load i8*, i8** %t190
  %t192 = call i32 @WaitForSingleObject(i8* %t191, i32 -1)
  br label %par_join_27
par_serial_23:
  %t193 = load i32, i32* @par.pool.serial_owner
  %t194 = icmp eq i32 %t193, %t122
  br i1 %t194, label %par_run_25, label %par_acquire_24
par_acquire_24:
  %t195 = load i8*, i8** @par.pool.serial_lock
  %t196 = call i32 @WaitForSingleObject(i8* %t195, i32 -1)
  store i32 %t122, i32* @par.pool.serial_owner
  br label %par_run_25
par_run_25:
  %t197 = load i64, i64* @arena.Entities.count
  %t199 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t198, i32 0, i32 0
  store i64 0, i64* %t199
  %t200 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t198, i32 0, i32 1
  store i64 %t197, i64* %t200
  %t201 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t198, i32 0, i32 2
  store i32* %t33, i32** %t201
  %t202 = bitcast { i64, i64, i32* }* %t198 to i8*
  %t203 = call i32 @par_worker_16(i8* %t202)
  br i1 %t194, label %par_join_27, label %par_release_26
par_release_26:
  store i32 -1, i32* @par.pool.serial_owner
  %t204 = load i8*, i8** @par.pool.serial_lock
  %t205 = call i32 @ReleaseSemaphore(i8* %t204, i32 1, i32* null)
  br label %par_join_27
par_join_27:
  call void @par.pool.ensure_init()
  %t226 = call i32 @GetCurrentThreadId()
  %t227 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t228 = load i32, i32* %t227
  %t229 = icmp eq i32 %t226, %t228
  %t230 = select i1 %t229, i32 0, i32 -1
  %t231 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t232 = load i32, i32* %t231
  %t233 = icmp eq i32 %t226, %t232
  %t234 = select i1 %t233, i32 1, i32 %t230
  %t235 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t236 = load i32, i32* %t235
  %t237 = icmp eq i32 %t226, %t236
  %t238 = select i1 %t237, i32 2, i32 %t234
  %t239 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t240 = load i32, i32* %t239
  %t241 = icmp eq i32 %t226, %t240
  %t242 = select i1 %t241, i32 3, i32 %t238
  %t243 = icmp sge i32 %t242, 0
  br i1 %t243, label %par_serial_35, label %par_pooled_34
par_pooled_34:
  %t244 = load i64, i64* @arena.Entities.count
  %t245 = mul i64 %t244, 0
  %t246 = sdiv i64 %t245, 4
  %t247 = mul i64 %t244, 1
  %t248 = sdiv i64 %t247, 4
  %t250 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t249, i32 0, i32 0
  store i64 %t246, i64* %t250
  %t251 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t249, i32 0, i32 1
  store i64 %t248, i64* %t251
  %t252 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t249, i32 0, i32 2
  store i32* %t33, i32** %t252
  %t253 = bitcast { i64, i64, i32* }* %t249 to i8*
  %t254 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t253, i8** %t254
  %t255 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t255
  %t256 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t257 = load i8*, i8** %t256
  %t258 = call i32 @ReleaseSemaphore(i8* %t257, i32 1, i32* null)
  %t259 = mul i64 %t244, 1
  %t260 = sdiv i64 %t259, 4
  %t261 = mul i64 %t244, 2
  %t262 = sdiv i64 %t261, 4
  %t264 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t263, i32 0, i32 0
  store i64 %t260, i64* %t264
  %t265 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t263, i32 0, i32 1
  store i64 %t262, i64* %t265
  %t266 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t263, i32 0, i32 2
  store i32* %t33, i32** %t266
  %t267 = bitcast { i64, i64, i32* }* %t263 to i8*
  %t268 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t267, i8** %t268
  %t269 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t269
  %t270 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t271 = load i8*, i8** %t270
  %t272 = call i32 @ReleaseSemaphore(i8* %t271, i32 1, i32* null)
  %t273 = mul i64 %t244, 2
  %t274 = sdiv i64 %t273, 4
  %t275 = mul i64 %t244, 3
  %t276 = sdiv i64 %t275, 4
  %t278 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t277, i32 0, i32 0
  store i64 %t274, i64* %t278
  %t279 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t277, i32 0, i32 1
  store i64 %t276, i64* %t279
  %t280 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t277, i32 0, i32 2
  store i32* %t33, i32** %t280
  %t281 = bitcast { i64, i64, i32* }* %t277 to i8*
  %t282 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t281, i8** %t282
  %t283 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t283
  %t284 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t285 = load i8*, i8** %t284
  %t286 = call i32 @ReleaseSemaphore(i8* %t285, i32 1, i32* null)
  %t287 = mul i64 %t244, 3
  %t288 = sdiv i64 %t287, 4
  %t289 = mul i64 %t244, 4
  %t290 = sdiv i64 %t289, 4
  %t292 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t291, i32 0, i32 0
  store i64 %t288, i64* %t292
  %t293 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t291, i32 0, i32 1
  store i64 %t290, i64* %t293
  %t294 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t291, i32 0, i32 2
  store i32* %t33, i32** %t294
  %t295 = bitcast { i64, i64, i32* }* %t291 to i8*
  %t296 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t295, i8** %t296
  %t297 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_28, i32 (i8*)** %t297
  %t298 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t299 = load i8*, i8** %t298
  %t300 = call i32 @ReleaseSemaphore(i8* %t299, i32 1, i32* null)
  %t301 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t302 = load i8*, i8** %t301
  %t303 = call i32 @WaitForSingleObject(i8* %t302, i32 -1)
  %t304 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t305 = load i8*, i8** %t304
  %t306 = call i32 @WaitForSingleObject(i8* %t305, i32 -1)
  %t307 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t308 = load i8*, i8** %t307
  %t309 = call i32 @WaitForSingleObject(i8* %t308, i32 -1)
  %t310 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t311 = load i8*, i8** %t310
  %t312 = call i32 @WaitForSingleObject(i8* %t311, i32 -1)
  br label %par_join_39
par_serial_35:
  %t313 = load i32, i32* @par.pool.serial_owner
  %t314 = icmp eq i32 %t313, %t242
  br i1 %t314, label %par_run_37, label %par_acquire_36
par_acquire_36:
  %t315 = load i8*, i8** @par.pool.serial_lock
  %t316 = call i32 @WaitForSingleObject(i8* %t315, i32 -1)
  store i32 %t242, i32* @par.pool.serial_owner
  br label %par_run_37
par_run_37:
  %t317 = load i64, i64* @arena.Entities.count
  %t319 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t318, i32 0, i32 0
  store i64 0, i64* %t319
  %t320 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t318, i32 0, i32 1
  store i64 %t317, i64* %t320
  %t321 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t318, i32 0, i32 2
  store i32* %t33, i32** %t321
  %t322 = bitcast { i64, i64, i32* }* %t318 to i8*
  %t323 = call i32 @par_worker_28(i8* %t322)
  br i1 %t314, label %par_join_39, label %par_release_38
par_release_38:
  store i32 -1, i32* @par.pool.serial_owner
  %t324 = load i8*, i8** @par.pool.serial_lock
  %t325 = call i32 @ReleaseSemaphore(i8* %t324, i32 1, i32* null)
  br label %par_join_39
par_join_39:
  %t326 = getelementptr inbounds { i64, i8*, [1 x i8] }, { i64, i8*, [1 x i8] }* @.str.2, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t326)
  call i32 (i8*, ...) @printf(i8* %t326)
  %t327 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t327)
  br label %for_step_14
for_step_14:
  %t328 = load i32, i32* %t33
  %t329 = add i32 %t328, 1
  store i32 %t329, i32* %t33
  br label %for_cond_12
for_end_15:
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_16(i8* %argp) {
entry:
  %t44 = alloca i64
  %t36 = bitcast i8* %argp to { i64, i64, i32* }*
  %t37 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t36, i32 0, i32 0
  %t38 = load i64, i64* %t37
  %t39 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t36, i32 0, i32 1
  %t40 = load i64, i64* %t39
  %t41 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t36, i32 0, i32 2
  %t42 = load i32*, i32** %t41
  %t43 = load %Entity*, %Entity** @arena.Entities.data
  store i64 %t38, i64* %t44
  br label %par_cond_17
par_cond_17:
  %t45 = load i64, i64* %t44
  %t46 = icmp slt i64 %t45, %t40
  br i1 %t46, label %par_body_18, label %par_end_21
par_body_18:
  %t47 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t45
  %t48 = load i64, i64* %t47
  %t49 = and i64 %t48, 1
  %t50 = icmp eq i64 %t49, 1
  br i1 %t50, label %par_live_19, label %par_incr_20
par_live_19:
  %t51 = getelementptr inbounds %Entity, %Entity* %t43, i64 %t45
  %t52 = sub i32 2000000000, 0
  %t53 = icmp sle i32 %t52, 0
  %t54 = select i1 %t53, i32 1, i32 %t52
  %t55 = load i8*, i8** @rng.lock
  call i32 @WaitForSingleObject(i8* %t55, i32 -1)
  %t56 = load i32, i32* @rng.state
  %t57 = shl i32 %t56, 13
  %t58 = xor i32 %t56, %t57
  %t59 = lshr i32 %t58, 17
  %t60 = xor i32 %t58, %t59
  %t61 = shl i32 %t60, 5
  %t62 = xor i32 %t60, %t61
  store i32 %t62, i32* @rng.state
  call i32 @ReleaseSemaphore(i8* %t55, i32 1, i32* null)
  %t63 = and i32 %t62, 2147483647
  %t64 = urem i32 %t63, %t54
  %t65 = add i32 0, %t64
  %t66 = sext i32 %t65 to i64
  %t67 = getelementptr inbounds %Entity, %Entity* %t51, i32 0, i32 0
  store i64 %t66, i64* %t67
  br label %par_incr_20
par_incr_20:
  %t68 = add i64 %t45, 1
  store i64 %t68, i64* %t44
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


define i32 @par_worker_28(i8* %argp) {
entry:
  %t214 = alloca i64
  %t206 = bitcast i8* %argp to { i64, i64, i32* }*
  %t207 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t206, i32 0, i32 0
  %t208 = load i64, i64* %t207
  %t209 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t206, i32 0, i32 1
  %t210 = load i64, i64* %t209
  %t211 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t206, i32 0, i32 2
  %t212 = load i32*, i32** %t211
  %t213 = load %Entity*, %Entity** @arena.Entities.data
  store i64 %t208, i64* %t214
  br label %par_cond_29
par_cond_29:
  %t215 = load i64, i64* %t214
  %t216 = icmp slt i64 %t215, %t210
  br i1 %t216, label %par_body_30, label %par_end_33
par_body_30:
  %t217 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t215
  %t218 = load i64, i64* %t217
  %t219 = and i64 %t218, 1
  %t220 = icmp eq i64 %t219, 1
  br i1 %t220, label %par_live_31, label %par_incr_32
par_live_31:
  %t221 = getelementptr inbounds %Entity, %Entity* %t213, i64 %t215
  %t222 = getelementptr inbounds %Entity, %Entity* %t221, i32 0, i32 0
  %t223 = load i64, i64* %t222
  %t224 = getelementptr inbounds [7 x i8], [7 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t224, i64 %t223)
  br label %par_incr_32
par_incr_32:
  %t225 = add i64 %t215, 1
  store i64 %t225, i64* %t214
  br label %par_cond_29
par_end_33:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [7 x i8] c"%lld \0A\00"
@.str.2 = private unnamed_addr constant { i64, i8*, [1 x i8] } { i64 -1, i8* null, [1 x i8] c"\00" }
@.str.3 = private unnamed_addr constant [2 x i8] c"\0A\00"
