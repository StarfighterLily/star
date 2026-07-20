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
  %t36 = alloca i8*
  %t153 = alloca { i64, i64, i32*, i8** }
  %t168 = alloca { i64, i64, i32*, i8** }
  %t183 = alloca { i64, i64, i32*, i8** }
  %t198 = alloca { i64, i64, i32*, i8** }
  %t226 = alloca { i64, i64, i32*, i8** }
  %t281 = alloca { i64, i64, i32* }
  %t295 = alloca { i64, i64, i32* }
  %t309 = alloca { i64, i64, i32* }
  %t323 = alloca { i64, i64, i32* }
  %t350 = alloca { i64, i64, i32* }
  %t358 = alloca i64
  %t367 = alloca i64
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
  %t37 = load i32, i32* %t33
  %t38 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.1, i64 0, i64 0
  %t39 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t38, i32 %t37)
  %t40 = add i32 %t39, 1
  %t41 = sext i32 %t40 to i64
  %t42 = call i8* @star_rc_alloc(i64 %t41, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t42, i64 %t41, i8* %t38, i32 %t37)
  store i8* %t42, i8** %t36
  call void @par.pool.ensure_init()
  %t130 = call i32 @GetCurrentThreadId()
  %t131 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t132 = load i32, i32* %t131
  %t133 = icmp eq i32 %t130, %t132
  %t134 = select i1 %t133, i32 0, i32 -1
  %t135 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t136 = load i32, i32* %t135
  %t137 = icmp eq i32 %t130, %t136
  %t138 = select i1 %t137, i32 1, i32 %t134
  %t139 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t140 = load i32, i32* %t139
  %t141 = icmp eq i32 %t130, %t140
  %t142 = select i1 %t141, i32 2, i32 %t138
  %t143 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t144 = load i32, i32* %t143
  %t145 = icmp eq i32 %t130, %t144
  %t146 = select i1 %t145, i32 3, i32 %t142
  %t147 = icmp sge i32 %t146, 0
  br i1 %t147, label %par_serial_34, label %par_pooled_33
par_pooled_33:
  %t148 = load i64, i64* @arena.Entities.count
  %t149 = mul i64 %t148, 0
  %t150 = sdiv i64 %t149, 4
  %t151 = mul i64 %t148, 1
  %t152 = sdiv i64 %t151, 4
  %t154 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t153, i32 0, i32 0
  store i64 %t150, i64* %t154
  %t155 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t153, i32 0, i32 1
  store i64 %t152, i64* %t155
  %t156 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t153, i32 0, i32 2
  store i32* %t33, i32** %t156
  %t157 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t153, i32 0, i32 3
  store i8** %t36, i8*** %t157
  %t158 = bitcast { i64, i64, i32*, i8** }* %t153 to i8*
  %t159 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t158, i8** %t159
  %t160 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t160
  %t161 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t162 = load i8*, i8** %t161
  %t163 = call i32 @ReleaseSemaphore(i8* %t162, i32 1, i32* null)
  %t164 = mul i64 %t148, 1
  %t165 = sdiv i64 %t164, 4
  %t166 = mul i64 %t148, 2
  %t167 = sdiv i64 %t166, 4
  %t169 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t168, i32 0, i32 0
  store i64 %t165, i64* %t169
  %t170 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t168, i32 0, i32 1
  store i64 %t167, i64* %t170
  %t171 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t168, i32 0, i32 2
  store i32* %t33, i32** %t171
  %t172 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t168, i32 0, i32 3
  store i8** %t36, i8*** %t172
  %t173 = bitcast { i64, i64, i32*, i8** }* %t168 to i8*
  %t174 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t173, i8** %t174
  %t175 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t175
  %t176 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t177 = load i8*, i8** %t176
  %t178 = call i32 @ReleaseSemaphore(i8* %t177, i32 1, i32* null)
  %t179 = mul i64 %t148, 2
  %t180 = sdiv i64 %t179, 4
  %t181 = mul i64 %t148, 3
  %t182 = sdiv i64 %t181, 4
  %t184 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t183, i32 0, i32 0
  store i64 %t180, i64* %t184
  %t185 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t183, i32 0, i32 1
  store i64 %t182, i64* %t185
  %t186 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t183, i32 0, i32 2
  store i32* %t33, i32** %t186
  %t187 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t183, i32 0, i32 3
  store i8** %t36, i8*** %t187
  %t188 = bitcast { i64, i64, i32*, i8** }* %t183 to i8*
  %t189 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t188, i8** %t189
  %t190 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t190
  %t191 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t192 = load i8*, i8** %t191
  %t193 = call i32 @ReleaseSemaphore(i8* %t192, i32 1, i32* null)
  %t194 = mul i64 %t148, 3
  %t195 = sdiv i64 %t194, 4
  %t196 = mul i64 %t148, 4
  %t197 = sdiv i64 %t196, 4
  %t199 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t198, i32 0, i32 0
  store i64 %t195, i64* %t199
  %t200 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t198, i32 0, i32 1
  store i64 %t197, i64* %t200
  %t201 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t198, i32 0, i32 2
  store i32* %t33, i32** %t201
  %t202 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t198, i32 0, i32 3
  store i8** %t36, i8*** %t202
  %t203 = bitcast { i64, i64, i32*, i8** }* %t198 to i8*
  %t204 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t203, i8** %t204
  %t205 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_16, i32 (i8*)** %t205
  %t206 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t207 = load i8*, i8** %t206
  %t208 = call i32 @ReleaseSemaphore(i8* %t207, i32 1, i32* null)
  %t209 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t210 = load i8*, i8** %t209
  %t211 = call i32 @WaitForSingleObject(i8* %t210, i32 -1)
  %t212 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t213 = load i8*, i8** %t212
  %t214 = call i32 @WaitForSingleObject(i8* %t213, i32 -1)
  %t215 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t216 = load i8*, i8** %t215
  %t217 = call i32 @WaitForSingleObject(i8* %t216, i32 -1)
  %t218 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t219 = load i8*, i8** %t218
  %t220 = call i32 @WaitForSingleObject(i8* %t219, i32 -1)
  br label %par_join_38
par_serial_34:
  %t221 = load i32, i32* @par.pool.serial_owner
  %t222 = icmp eq i32 %t221, %t146
  br i1 %t222, label %par_run_36, label %par_acquire_35
par_acquire_35:
  %t223 = load i8*, i8** @par.pool.serial_lock
  %t224 = call i32 @WaitForSingleObject(i8* %t223, i32 -1)
  store i32 %t146, i32* @par.pool.serial_owner
  br label %par_run_36
par_run_36:
  %t225 = load i64, i64* @arena.Entities.count
  %t227 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t226, i32 0, i32 0
  store i64 0, i64* %t227
  %t228 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t226, i32 0, i32 1
  store i64 %t225, i64* %t228
  %t229 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t226, i32 0, i32 2
  store i32* %t33, i32** %t229
  %t230 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t226, i32 0, i32 3
  store i8** %t36, i8*** %t230
  %t231 = bitcast { i64, i64, i32*, i8** }* %t226 to i8*
  %t232 = call i32 @par_worker_16(i8* %t231)
  br i1 %t222, label %par_join_38, label %par_release_37
par_release_37:
  store i32 -1, i32* @par.pool.serial_owner
  %t233 = load i8*, i8** @par.pool.serial_lock
  %t234 = call i32 @ReleaseSemaphore(i8* %t233, i32 1, i32* null)
  br label %par_join_38
par_join_38:
  %t235 = load i8*, i8** %t36
  call void @star_rc_release(i8* %t235)
  br label %for_step_14
for_step_14:
  %t236 = load i32, i32* %t33
  %t237 = add i32 %t236, 1
  store i32 %t237, i32* %t33
  br label %for_cond_12
for_end_15:
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
  br i1 %t275, label %par_serial_46, label %par_pooled_45
par_pooled_45:
  %t276 = load i64, i64* @arena.Entities.count
  %t277 = mul i64 %t276, 0
  %t278 = sdiv i64 %t277, 4
  %t279 = mul i64 %t276, 1
  %t280 = sdiv i64 %t279, 4
  %t282 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t281, i32 0, i32 0
  store i64 %t278, i64* %t282
  %t283 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t281, i32 0, i32 1
  store i64 %t280, i64* %t283
  %t284 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t281, i32 0, i32 2
  store i32* %t33, i32** %t284
  %t285 = bitcast { i64, i64, i32* }* %t281 to i8*
  %t286 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t285, i8** %t286
  %t287 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_39, i32 (i8*)** %t287
  %t288 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t289 = load i8*, i8** %t288
  %t290 = call i32 @ReleaseSemaphore(i8* %t289, i32 1, i32* null)
  %t291 = mul i64 %t276, 1
  %t292 = sdiv i64 %t291, 4
  %t293 = mul i64 %t276, 2
  %t294 = sdiv i64 %t293, 4
  %t296 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t295, i32 0, i32 0
  store i64 %t292, i64* %t296
  %t297 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t295, i32 0, i32 1
  store i64 %t294, i64* %t297
  %t298 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t295, i32 0, i32 2
  store i32* %t33, i32** %t298
  %t299 = bitcast { i64, i64, i32* }* %t295 to i8*
  %t300 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t299, i8** %t300
  %t301 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_39, i32 (i8*)** %t301
  %t302 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t303 = load i8*, i8** %t302
  %t304 = call i32 @ReleaseSemaphore(i8* %t303, i32 1, i32* null)
  %t305 = mul i64 %t276, 2
  %t306 = sdiv i64 %t305, 4
  %t307 = mul i64 %t276, 3
  %t308 = sdiv i64 %t307, 4
  %t310 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t309, i32 0, i32 0
  store i64 %t306, i64* %t310
  %t311 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t309, i32 0, i32 1
  store i64 %t308, i64* %t311
  %t312 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t309, i32 0, i32 2
  store i32* %t33, i32** %t312
  %t313 = bitcast { i64, i64, i32* }* %t309 to i8*
  %t314 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t313, i8** %t314
  %t315 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_39, i32 (i8*)** %t315
  %t316 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t317 = load i8*, i8** %t316
  %t318 = call i32 @ReleaseSemaphore(i8* %t317, i32 1, i32* null)
  %t319 = mul i64 %t276, 3
  %t320 = sdiv i64 %t319, 4
  %t321 = mul i64 %t276, 4
  %t322 = sdiv i64 %t321, 4
  %t324 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t323, i32 0, i32 0
  store i64 %t320, i64* %t324
  %t325 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t323, i32 0, i32 1
  store i64 %t322, i64* %t325
  %t326 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t323, i32 0, i32 2
  store i32* %t33, i32** %t326
  %t327 = bitcast { i64, i64, i32* }* %t323 to i8*
  %t328 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t327, i8** %t328
  %t329 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_39, i32 (i8*)** %t329
  %t330 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t331 = load i8*, i8** %t330
  %t332 = call i32 @ReleaseSemaphore(i8* %t331, i32 1, i32* null)
  %t333 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t334 = load i8*, i8** %t333
  %t335 = call i32 @WaitForSingleObject(i8* %t334, i32 -1)
  %t336 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t337 = load i8*, i8** %t336
  %t338 = call i32 @WaitForSingleObject(i8* %t337, i32 -1)
  %t339 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t340 = load i8*, i8** %t339
  %t341 = call i32 @WaitForSingleObject(i8* %t340, i32 -1)
  %t342 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t343 = load i8*, i8** %t342
  %t344 = call i32 @WaitForSingleObject(i8* %t343, i32 -1)
  br label %par_join_50
par_serial_46:
  %t345 = load i32, i32* @par.pool.serial_owner
  %t346 = icmp eq i32 %t345, %t274
  br i1 %t346, label %par_run_48, label %par_acquire_47
par_acquire_47:
  %t347 = load i8*, i8** @par.pool.serial_lock
  %t348 = call i32 @WaitForSingleObject(i8* %t347, i32 -1)
  store i32 %t274, i32* @par.pool.serial_owner
  br label %par_run_48
par_run_48:
  %t349 = load i64, i64* @arena.Entities.count
  %t351 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t350, i32 0, i32 0
  store i64 0, i64* %t351
  %t352 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t350, i32 0, i32 1
  store i64 %t349, i64* %t352
  %t353 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t350, i32 0, i32 2
  store i32* %t33, i32** %t353
  %t354 = bitcast { i64, i64, i32* }* %t350 to i8*
  %t355 = call i32 @par_worker_39(i8* %t354)
  br i1 %t346, label %par_join_50, label %par_release_49
par_release_49:
  store i32 -1, i32* @par.pool.serial_owner
  %t356 = load i8*, i8** @par.pool.serial_lock
  %t357 = call i32 @ReleaseSemaphore(i8* %t356, i32 1, i32* null)
  br label %par_join_50
par_join_50:
  %t359 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.3, i64 0, i64 0
  %t360 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t359, i32 199)
  %t361 = add i32 %t360, 1
  %t362 = sext i32 %t361 to i64
  %t363 = call i8* @star_rc_alloc(i64 %t362, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t363, i64 %t362, i8* %t359, i32 199)
  %t364 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t364, i32 -1)
  %t365 = load i64, i64* @sym.len
  %t366 = load i8**, i8*** @sym.data
  store i64 0, i64* %t367
  br label %sym_find_cond_51
sym_find_cond_51:
  %t368 = load i64, i64* %t367
  %t369 = icmp slt i64 %t368, %t365
  br i1 %t369, label %sym_find_body_52, label %sym_find_end_54
sym_find_body_52:
  %t370 = getelementptr inbounds i8*, i8** %t366, i64 %t368
  %t371 = load i8*, i8** %t370
  %t372 = call i32 @strcmp(i8* %t371, i8* %t363)
  %t373 = icmp eq i32 %t372, 0
  br i1 %t373, label %sym_find_end_54, label %sym_find_next_53
sym_find_next_53:
  %t374 = add i64 %t368, 1
  store i64 %t374, i64* %t367
  br label %sym_find_cond_51
sym_find_end_54:
  %t375 = load i64, i64* %t367
  %t376 = icmp slt i64 %t375, %t365
  br i1 %t376, label %sym_found_55, label %sym_notfound_56
sym_found_55:
  call void @star_rc_release(i8* %t363)
  br label %sym_done_57
sym_notfound_56:
  %t377 = load i64, i64* @sym.cap
  %t378 = icmp sge i64 %t365, %t377
  br i1 %t378, label %sym_grow_58, label %sym_store_59
sym_grow_58:
  %t379 = mul i64 %t377, 2
  %t380 = icmp sgt i64 %t379, 0
  %t381 = select i1 %t380, i64 %t379, i64 1
  %t382 = mul i64 %t381, 8
  %t383 = call i8* @malloc(i64 %t382)
  %t384 = bitcast i8* %t383 to i8**
  %t385 = icmp sgt i64 %t377, 0
  br i1 %t385, label %sym_copy_60, label %sym_after_copy_61
sym_copy_60:
  %t386 = mul i64 %t365, 8
  %t387 = bitcast i8** %t366 to i8*
  call i8* @memcpy(i8* %t383, i8* %t387, i64 %t386)
  call void @free(i8* %t387)
  br label %sym_after_copy_61
sym_after_copy_61:
  store i8** %t384, i8*** @sym.data
  store i64 %t381, i64* @sym.cap
  br label %sym_store_59
sym_store_59:
  %t388 = load i8**, i8*** @sym.data
  %t389 = getelementptr inbounds i8*, i8** %t388, i64 %t365
  store i8* %t363, i8** %t389
  %t390 = add i64 %t365, 1
  store i64 %t390, i64* @sym.len
  br label %sym_done_57
sym_done_57:
  %t391 = phi i64 [ %t375, %sym_found_55 ], [ %t365, %sym_store_59 ]
  call i32 @ReleaseSemaphore(i8* %t364, i32 1, i32* null)
  store i64 %t391, i64* %t358
  %t392 = load i64, i64* %t358
  %t393 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t393, i64 %t392)
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_16(i8* %argp) {
entry:
  %t53 = alloca i64
  %t66 = alloca i64
  %t43 = bitcast i8* %argp to { i64, i64, i32*, i8** }*
  %t44 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t43, i32 0, i32 0
  %t45 = load i64, i64* %t44
  %t46 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t43, i32 0, i32 1
  %t47 = load i64, i64* %t46
  %t48 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t43, i32 0, i32 2
  %t49 = load i32*, i32** %t48
  %t50 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t43, i32 0, i32 3
  %t51 = load i8**, i8*** %t50
  %t52 = load %Entity*, %Entity** @arena.Entities.data
  store i64 %t45, i64* %t53
  br label %par_cond_17
par_cond_17:
  %t54 = load i64, i64* %t53
  %t55 = icmp slt i64 %t54, %t47
  br i1 %t55, label %par_body_18, label %par_end_21
par_body_18:
  %t56 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t54
  %t57 = load i64, i64* %t56
  %t58 = and i64 %t57, 1
  %t59 = icmp eq i64 %t58, 1
  br i1 %t59, label %par_live_19, label %par_incr_20
par_live_19:
  %t60 = getelementptr inbounds %Entity, %Entity* %t52, i64 %t54
  %t61 = load i8*, i8** %t51
  %t62 = load i8*, i8** %t51
  call void @star_rc_retain(i8* %t62)
  %t63 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t63, i32 -1)
  %t64 = load i64, i64* @sym.len
  %t65 = load i8**, i8*** @sym.data
  store i64 0, i64* %t66
  br label %sym_find_cond_22
sym_find_cond_22:
  %t67 = load i64, i64* %t66
  %t68 = icmp slt i64 %t67, %t64
  br i1 %t68, label %sym_find_body_23, label %sym_find_end_25
sym_find_body_23:
  %t69 = getelementptr inbounds i8*, i8** %t65, i64 %t67
  %t70 = load i8*, i8** %t69
  %t71 = call i32 @strcmp(i8* %t70, i8* %t61)
  %t72 = icmp eq i32 %t71, 0
  br i1 %t72, label %sym_find_end_25, label %sym_find_next_24
sym_find_next_24:
  %t73 = add i64 %t67, 1
  store i64 %t73, i64* %t66
  br label %sym_find_cond_22
sym_find_end_25:
  %t74 = load i64, i64* %t66
  %t75 = icmp slt i64 %t74, %t64
  br i1 %t75, label %sym_found_26, label %sym_notfound_27
sym_found_26:
  call void @star_rc_release(i8* %t61)
  br label %sym_done_28
sym_notfound_27:
  %t76 = load i64, i64* @sym.cap
  %t77 = icmp sge i64 %t64, %t76
  br i1 %t77, label %sym_grow_29, label %sym_store_30
sym_grow_29:
  %t78 = mul i64 %t76, 2
  %t79 = icmp sgt i64 %t78, 0
  %t80 = select i1 %t79, i64 %t78, i64 1
  %t81 = mul i64 %t80, 8
  %t82 = call i8* @malloc(i64 %t81)
  %t83 = bitcast i8* %t82 to i8**
  %t84 = icmp sgt i64 %t76, 0
  br i1 %t84, label %sym_copy_31, label %sym_after_copy_32
sym_copy_31:
  %t85 = mul i64 %t64, 8
  %t86 = bitcast i8** %t65 to i8*
  call i8* @memcpy(i8* %t82, i8* %t86, i64 %t85)
  call void @free(i8* %t86)
  br label %sym_after_copy_32
sym_after_copy_32:
  store i8** %t83, i8*** @sym.data
  store i64 %t80, i64* @sym.cap
  br label %sym_store_30
sym_store_30:
  %t87 = load i8**, i8*** @sym.data
  %t88 = getelementptr inbounds i8*, i8** %t87, i64 %t64
  store i8* %t61, i8** %t88
  %t89 = add i64 %t64, 1
  store i64 %t89, i64* @sym.len
  br label %sym_done_28
sym_done_28:
  %t90 = phi i64 [ %t74, %sym_found_26 ], [ %t64, %sym_store_30 ]
  call i32 @ReleaseSemaphore(i8* %t63, i32 1, i32* null)
  %t91 = getelementptr inbounds %Entity, %Entity* %t60, i32 0, i32 0
  store i64 %t90, i64* %t91
  br label %par_incr_20
par_incr_20:
  %t92 = add i64 %t54, 1
  store i64 %t92, i64* %t53
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
  %t93 = ptrtoint i8* %idx_arg to i64
  %t94 = trunc i64 %t93 to i32
  %t95 = call i32 @GetCurrentThreadId()
  %t96 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t94
  store i32 %t95, i32* %t96
  br label %loop
loop:
  %t97 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t94
  %t98 = load i8*, i8** %t97
  %t99 = call i32 @WaitForSingleObject(i8* %t98, i32 -1)
  %t100 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t94
  %t101 = load i32 (i8*)*, i32 (i8*)** %t100
  %t102 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t94
  %t103 = load i8*, i8** %t102
  %t104 = call i32 %t101(i8* %t103)
  %t105 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t94
  %t106 = load i8*, i8** %t105
  %t107 = call i32 @ReleaseSemaphore(i8* %t106, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t108 = load i1, i1* @par.pool.inited
  br i1 %t108, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t109 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t109, i8** @par.pool.serial_lock
  %t110 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t111 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t110, i8** %t111
  %t112 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t113 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t112, i8** %t113
  %t114 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t115 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t116 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t115, i8** %t116
  %t117 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t118 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t117, i8** %t118
  %t119 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t120 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t121 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t120, i8** %t121
  %t122 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t123 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t122, i8** %t123
  %t124 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t125 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t126 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t125, i8** %t126
  %t127 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t128 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t127, i8** %t128
  %t129 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_39(i8* %argp) {
entry:
  %t246 = alloca i64
  %t238 = bitcast i8* %argp to { i64, i64, i32* }*
  %t239 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t238, i32 0, i32 0
  %t240 = load i64, i64* %t239
  %t241 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t238, i32 0, i32 1
  %t242 = load i64, i64* %t241
  %t243 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t238, i32 0, i32 2
  %t244 = load i32*, i32** %t243
  %t245 = load %Entity*, %Entity** @arena.Entities.data
  store i64 %t240, i64* %t246
  br label %par_cond_40
par_cond_40:
  %t247 = load i64, i64* %t246
  %t248 = icmp slt i64 %t247, %t242
  br i1 %t248, label %par_body_41, label %par_end_44
par_body_41:
  %t249 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t247
  %t250 = load i64, i64* %t249
  %t251 = and i64 %t250, 1
  %t252 = icmp eq i64 %t251, 1
  br i1 %t252, label %par_live_42, label %par_incr_43
par_live_42:
  %t253 = getelementptr inbounds %Entity, %Entity* %t245, i64 %t247
  %t254 = getelementptr inbounds %Entity, %Entity* %t253, i32 0, i32 0
  %t255 = load i64, i64* %t254
  %t256 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t256, i64 %t255)
  br label %par_incr_43
par_incr_43:
  %t257 = add i64 %t247, 1
  store i64 %t257, i64* %t246
  br label %par_cond_40
par_end_44:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [6 x i8] c"tag%d\00"
@.str.2 = private unnamed_addr constant [6 x i8] c"%lld\0A\00"
@.str.3 = private unnamed_addr constant [6 x i8] c"tag%d\00"
@.str.4 = private unnamed_addr constant [14 x i8] c"check = %lld\0A\00"
