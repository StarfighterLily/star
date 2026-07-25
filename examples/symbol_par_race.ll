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
declare i8* @strstr(i8*, i8*)
declare i32 @strncmp(i8*, i8*, i64)
@str.empty = private unnamed_addr constant [1 x i8] c"\00"
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
declare i32 @SDL_RenderReadPixels(i8*, i8*, i32, i8*, i32)
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
declare float @llvm.sin.f32(float)
declare float @llvm.cos.f32(float)
declare float @llvm.tan.f32(float)
declare float @llvm.asin.f32(float)
declare float @llvm.acos.f32(float)
declare float @llvm.atan.f32(float)
declare float @llvm.atan2.f32(float, float)
declare float @llvm.exp.f32(float)
declare float @llvm.exp2.f32(float)
declare float @llvm.log.f32(float)
declare float @llvm.log2.f32(float)
declare float @llvm.log10.f32(float)
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
@sym.tbl.ids = global i64* null
@sym.tbl.cap = global i64 0
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
@arena.Entities.warned = global i1 0

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
  %t24 = alloca %Entity
  %t36 = alloca i32
  %t39 = alloca i8*
  %t229 = alloca { i64, i64, i32*, i8** }
  %t244 = alloca { i64, i64, i32*, i8** }
  %t259 = alloca { i64, i64, i32*, i8** }
  %t274 = alloca { i64, i64, i32*, i8** }
  %t302 = alloca { i64, i64, i32*, i8** }
  %t357 = alloca { i64, i64, i32* }
  %t371 = alloca { i64, i64, i32* }
  %t385 = alloca { i64, i64, i32* }
  %t399 = alloca { i64, i64, i32* }
  %t426 = alloca { i64, i64, i32* }
  %t434 = alloca i64
  %t454 = alloca i64
  %t460 = alloca i64
  %t467 = alloca i64
  %t468 = alloca i64
  %t488 = alloca i64
  %t489 = alloca i64
  %t490 = alloca i1
  %t491 = alloca i64
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
  %t20 = load i1, i1* @arena.Entities.warned
  br i1 %t20, label %spawn_end_9, label %spawn_warn_print_12
spawn_warn_print_12:
  store i1 1, i1* @arena.Entities.warned
  %t21 = getelementptr inbounds [141 x i8], [141 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t21)
  br label %spawn_end_9
spawn_grow_ok_10:
  %t22 = add i64 %t18, 1
  store i64 %t22, i64* @arena.Entities.count
  br label %spawn_store_8
spawn_store_8:
  %t23 = phi i64 [ %t17, %spawn_reuse_6 ], [ %t18, %spawn_grow_ok_10 ]
  %t25 = sext i32 0 to i64
  %t26 = getelementptr inbounds %Entity, %Entity* %t24, i32 0, i32 0
  store i64 %t25, i64* %t26
  %t27 = load %Entity, %Entity* %t24
  %t28 = getelementptr inbounds %Entity, %Entity* %t12, i64 %t23
  store %Entity %t27, %Entity* %t28
  %t29 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t23
  %t30 = load i64, i64* %t29
  %t31 = add i64 %t30, 1
  store i64 %t31, i64* %t29
  %t32 = trunc i64 %t23 to i32
  br label %spawn_end_9
spawn_end_9:
  %t33 = phi i32 [ %t32, %spawn_store_8 ], [ -1, %spawn_capacity_warn_11 ], [ -1, %spawn_warn_print_12 ]
  br label %for_step_2
for_step_2:
  %t34 = load i32, i32* %t2
  %t35 = add i32 %t34, 1
  store i32 %t35, i32* %t2
  br label %for_cond_0
for_end_3:
  store i32 0, i32* %t36
  br label %for_cond_13
for_cond_13:
  %t37 = load i32, i32* %t36
  %t38 = icmp slt i32 %t37, 200
  br i1 %t38, label %for_body_14, label %for_end_16
for_body_14:
  %t40 = load i32, i32* %t36
  %t41 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.1, i64 0, i64 0
  %t42 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t41, i32 %t40)
  %t43 = add i32 %t42, 1
  %t44 = sext i32 %t43 to i64
  %t45 = call i8* @star_rc_alloc(i64 %t44, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t45, i64 %t44, i8* %t41, i32 %t40)
  store i8* %t45, i8** %t39
  call void @par.pool.ensure_init()
  %t206 = call i32 @GetCurrentThreadId()
  %t207 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t208 = load i32, i32* %t207
  %t209 = icmp eq i32 %t206, %t208
  %t210 = select i1 %t209, i32 0, i32 -1
  %t211 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t212 = load i32, i32* %t211
  %t213 = icmp eq i32 %t206, %t212
  %t214 = select i1 %t213, i32 1, i32 %t210
  %t215 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t216 = load i32, i32* %t215
  %t217 = icmp eq i32 %t206, %t216
  %t218 = select i1 %t217, i32 2, i32 %t214
  %t219 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t220 = load i32, i32* %t219
  %t221 = icmp eq i32 %t206, %t220
  %t222 = select i1 %t221, i32 3, i32 %t218
  %t223 = icmp sge i32 %t222, 0
  br i1 %t223, label %par_serial_52, label %par_pooled_51
par_pooled_51:
  %t224 = load i64, i64* @arena.Entities.count
  %t225 = mul i64 %t224, 0
  %t226 = sdiv i64 %t225, 4
  %t227 = mul i64 %t224, 1
  %t228 = sdiv i64 %t227, 4
  %t230 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t229, i32 0, i32 0
  store i64 %t226, i64* %t230
  %t231 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t229, i32 0, i32 1
  store i64 %t228, i64* %t231
  %t232 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t229, i32 0, i32 2
  store i32* %t36, i32** %t232
  %t233 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t229, i32 0, i32 3
  store i8** %t39, i8*** %t233
  %t234 = bitcast { i64, i64, i32*, i8** }* %t229 to i8*
  %t235 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t234, i8** %t235
  %t236 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_17, i32 (i8*)** %t236
  %t237 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t238 = load i8*, i8** %t237
  %t239 = call i32 @ReleaseSemaphore(i8* %t238, i32 1, i32* null)
  %t240 = mul i64 %t224, 1
  %t241 = sdiv i64 %t240, 4
  %t242 = mul i64 %t224, 2
  %t243 = sdiv i64 %t242, 4
  %t245 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t244, i32 0, i32 0
  store i64 %t241, i64* %t245
  %t246 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t244, i32 0, i32 1
  store i64 %t243, i64* %t246
  %t247 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t244, i32 0, i32 2
  store i32* %t36, i32** %t247
  %t248 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t244, i32 0, i32 3
  store i8** %t39, i8*** %t248
  %t249 = bitcast { i64, i64, i32*, i8** }* %t244 to i8*
  %t250 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t249, i8** %t250
  %t251 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_17, i32 (i8*)** %t251
  %t252 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t253 = load i8*, i8** %t252
  %t254 = call i32 @ReleaseSemaphore(i8* %t253, i32 1, i32* null)
  %t255 = mul i64 %t224, 2
  %t256 = sdiv i64 %t255, 4
  %t257 = mul i64 %t224, 3
  %t258 = sdiv i64 %t257, 4
  %t260 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t259, i32 0, i32 0
  store i64 %t256, i64* %t260
  %t261 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t259, i32 0, i32 1
  store i64 %t258, i64* %t261
  %t262 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t259, i32 0, i32 2
  store i32* %t36, i32** %t262
  %t263 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t259, i32 0, i32 3
  store i8** %t39, i8*** %t263
  %t264 = bitcast { i64, i64, i32*, i8** }* %t259 to i8*
  %t265 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t264, i8** %t265
  %t266 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_17, i32 (i8*)** %t266
  %t267 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t268 = load i8*, i8** %t267
  %t269 = call i32 @ReleaseSemaphore(i8* %t268, i32 1, i32* null)
  %t270 = mul i64 %t224, 3
  %t271 = sdiv i64 %t270, 4
  %t272 = mul i64 %t224, 4
  %t273 = sdiv i64 %t272, 4
  %t275 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t274, i32 0, i32 0
  store i64 %t271, i64* %t275
  %t276 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t274, i32 0, i32 1
  store i64 %t273, i64* %t276
  %t277 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t274, i32 0, i32 2
  store i32* %t36, i32** %t277
  %t278 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t274, i32 0, i32 3
  store i8** %t39, i8*** %t278
  %t279 = bitcast { i64, i64, i32*, i8** }* %t274 to i8*
  %t280 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t279, i8** %t280
  %t281 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_17, i32 (i8*)** %t281
  %t282 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t283 = load i8*, i8** %t282
  %t284 = call i32 @ReleaseSemaphore(i8* %t283, i32 1, i32* null)
  %t285 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t286 = load i8*, i8** %t285
  %t287 = call i32 @WaitForSingleObject(i8* %t286, i32 -1)
  %t288 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t289 = load i8*, i8** %t288
  %t290 = call i32 @WaitForSingleObject(i8* %t289, i32 -1)
  %t291 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t292 = load i8*, i8** %t291
  %t293 = call i32 @WaitForSingleObject(i8* %t292, i32 -1)
  %t294 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t295 = load i8*, i8** %t294
  %t296 = call i32 @WaitForSingleObject(i8* %t295, i32 -1)
  br label %par_join_56
par_serial_52:
  %t297 = load i32, i32* @par.pool.serial_owner
  %t298 = icmp eq i32 %t297, %t222
  br i1 %t298, label %par_run_54, label %par_acquire_53
par_acquire_53:
  %t299 = load i8*, i8** @par.pool.serial_lock
  %t300 = call i32 @WaitForSingleObject(i8* %t299, i32 -1)
  store i32 %t222, i32* @par.pool.serial_owner
  br label %par_run_54
par_run_54:
  %t301 = load i64, i64* @arena.Entities.count
  %t303 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t302, i32 0, i32 0
  store i64 0, i64* %t303
  %t304 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t302, i32 0, i32 1
  store i64 %t301, i64* %t304
  %t305 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t302, i32 0, i32 2
  store i32* %t36, i32** %t305
  %t306 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t302, i32 0, i32 3
  store i8** %t39, i8*** %t306
  %t307 = bitcast { i64, i64, i32*, i8** }* %t302 to i8*
  %t308 = call i32 @par_worker_17(i8* %t307)
  br i1 %t298, label %par_join_56, label %par_release_55
par_release_55:
  store i32 -1, i32* @par.pool.serial_owner
  %t309 = load i8*, i8** @par.pool.serial_lock
  %t310 = call i32 @ReleaseSemaphore(i8* %t309, i32 1, i32* null)
  br label %par_join_56
par_join_56:
  %t311 = load i8*, i8** %t39
  call void @star_rc_release(i8* %t311)
  br label %for_step_15
for_step_15:
  %t312 = load i32, i32* %t36
  %t313 = add i32 %t312, 1
  store i32 %t313, i32* %t36
  br label %for_cond_13
for_end_16:
  call void @par.pool.ensure_init()
  %t334 = call i32 @GetCurrentThreadId()
  %t335 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t336 = load i32, i32* %t335
  %t337 = icmp eq i32 %t334, %t336
  %t338 = select i1 %t337, i32 0, i32 -1
  %t339 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t340 = load i32, i32* %t339
  %t341 = icmp eq i32 %t334, %t340
  %t342 = select i1 %t341, i32 1, i32 %t338
  %t343 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t344 = load i32, i32* %t343
  %t345 = icmp eq i32 %t334, %t344
  %t346 = select i1 %t345, i32 2, i32 %t342
  %t347 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t348 = load i32, i32* %t347
  %t349 = icmp eq i32 %t334, %t348
  %t350 = select i1 %t349, i32 3, i32 %t346
  %t351 = icmp sge i32 %t350, 0
  br i1 %t351, label %par_serial_64, label %par_pooled_63
par_pooled_63:
  %t352 = load i64, i64* @arena.Entities.count
  %t353 = mul i64 %t352, 0
  %t354 = sdiv i64 %t353, 4
  %t355 = mul i64 %t352, 1
  %t356 = sdiv i64 %t355, 4
  %t358 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t357, i32 0, i32 0
  store i64 %t354, i64* %t358
  %t359 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t357, i32 0, i32 1
  store i64 %t356, i64* %t359
  %t360 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t357, i32 0, i32 2
  store i32* %t36, i32** %t360
  %t361 = bitcast { i64, i64, i32* }* %t357 to i8*
  %t362 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t361, i8** %t362
  %t363 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_57, i32 (i8*)** %t363
  %t364 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t365 = load i8*, i8** %t364
  %t366 = call i32 @ReleaseSemaphore(i8* %t365, i32 1, i32* null)
  %t367 = mul i64 %t352, 1
  %t368 = sdiv i64 %t367, 4
  %t369 = mul i64 %t352, 2
  %t370 = sdiv i64 %t369, 4
  %t372 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t371, i32 0, i32 0
  store i64 %t368, i64* %t372
  %t373 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t371, i32 0, i32 1
  store i64 %t370, i64* %t373
  %t374 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t371, i32 0, i32 2
  store i32* %t36, i32** %t374
  %t375 = bitcast { i64, i64, i32* }* %t371 to i8*
  %t376 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t375, i8** %t376
  %t377 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_57, i32 (i8*)** %t377
  %t378 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t379 = load i8*, i8** %t378
  %t380 = call i32 @ReleaseSemaphore(i8* %t379, i32 1, i32* null)
  %t381 = mul i64 %t352, 2
  %t382 = sdiv i64 %t381, 4
  %t383 = mul i64 %t352, 3
  %t384 = sdiv i64 %t383, 4
  %t386 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t385, i32 0, i32 0
  store i64 %t382, i64* %t386
  %t387 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t385, i32 0, i32 1
  store i64 %t384, i64* %t387
  %t388 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t385, i32 0, i32 2
  store i32* %t36, i32** %t388
  %t389 = bitcast { i64, i64, i32* }* %t385 to i8*
  %t390 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t389, i8** %t390
  %t391 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_57, i32 (i8*)** %t391
  %t392 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t393 = load i8*, i8** %t392
  %t394 = call i32 @ReleaseSemaphore(i8* %t393, i32 1, i32* null)
  %t395 = mul i64 %t352, 3
  %t396 = sdiv i64 %t395, 4
  %t397 = mul i64 %t352, 4
  %t398 = sdiv i64 %t397, 4
  %t400 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t399, i32 0, i32 0
  store i64 %t396, i64* %t400
  %t401 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t399, i32 0, i32 1
  store i64 %t398, i64* %t401
  %t402 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t399, i32 0, i32 2
  store i32* %t36, i32** %t402
  %t403 = bitcast { i64, i64, i32* }* %t399 to i8*
  %t404 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t403, i8** %t404
  %t405 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_57, i32 (i8*)** %t405
  %t406 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t407 = load i8*, i8** %t406
  %t408 = call i32 @ReleaseSemaphore(i8* %t407, i32 1, i32* null)
  %t409 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t410 = load i8*, i8** %t409
  %t411 = call i32 @WaitForSingleObject(i8* %t410, i32 -1)
  %t412 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t413 = load i8*, i8** %t412
  %t414 = call i32 @WaitForSingleObject(i8* %t413, i32 -1)
  %t415 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t416 = load i8*, i8** %t415
  %t417 = call i32 @WaitForSingleObject(i8* %t416, i32 -1)
  %t418 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t419 = load i8*, i8** %t418
  %t420 = call i32 @WaitForSingleObject(i8* %t419, i32 -1)
  br label %par_join_68
par_serial_64:
  %t421 = load i32, i32* @par.pool.serial_owner
  %t422 = icmp eq i32 %t421, %t350
  br i1 %t422, label %par_run_66, label %par_acquire_65
par_acquire_65:
  %t423 = load i8*, i8** @par.pool.serial_lock
  %t424 = call i32 @WaitForSingleObject(i8* %t423, i32 -1)
  store i32 %t350, i32* @par.pool.serial_owner
  br label %par_run_66
par_run_66:
  %t425 = load i64, i64* @arena.Entities.count
  %t427 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t426, i32 0, i32 0
  store i64 0, i64* %t427
  %t428 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t426, i32 0, i32 1
  store i64 %t425, i64* %t428
  %t429 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t426, i32 0, i32 2
  store i32* %t36, i32** %t429
  %t430 = bitcast { i64, i64, i32* }* %t426 to i8*
  %t431 = call i32 @par_worker_57(i8* %t430)
  br i1 %t422, label %par_join_68, label %par_release_67
par_release_67:
  store i32 -1, i32* @par.pool.serial_owner
  %t432 = load i8*, i8** @par.pool.serial_lock
  %t433 = call i32 @ReleaseSemaphore(i8* %t432, i32 1, i32* null)
  br label %par_join_68
par_join_68:
  %t435 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.3, i64 0, i64 0
  %t436 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t435, i32 199)
  %t437 = add i32 %t436, 1
  %t438 = sext i32 %t437 to i64
  %t439 = call i8* @star_rc_alloc(i64 %t438, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t439, i64 %t438, i8* %t435, i32 199)
  %t440 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t440, i32 -1)
  %t441 = load i64, i64* @sym.len
  %t442 = load i64, i64* @sym.tbl.cap
  %t444 = add i64 %t441, 1
  %t443 = mul i64 %t444, 4
  %t445 = mul i64 %t442, 3
  %t446 = icmp sgt i64 %t443, %t445
  br i1 %t446, label %sym_tbl_grow_69, label %sym_tbl_after_grow_70
sym_tbl_grow_69:
  %t447 = mul i64 %t442, 2
  %t448 = icmp sgt i64 %t447, 0
  %t449 = select i1 %t448, i64 %t447, i64 8
  %t450 = sub i64 %t449, 1
  %t451 = mul i64 %t449, 8
  %t452 = call i8* @malloc(i64 %t451)
  %t453 = bitcast i8* %t452 to i64*
  store i64 0, i64* %t454
  br label %ht_fill64_cond_71
ht_fill64_cond_71:
  %t455 = load i64, i64* %t454
  %t456 = icmp slt i64 %t455, %t449
  br i1 %t456, label %ht_fill64_body_72, label %ht_fill64_end_73
ht_fill64_body_72:
  %t457 = getelementptr inbounds i64, i64* %t453, i64 %t455
  store i64 -1, i64* %t457
  %t458 = add i64 %t455, 1
  store i64 %t458, i64* %t454
  br label %ht_fill64_cond_71
ht_fill64_end_73:
  %t459 = load i8**, i8*** @sym.data
  store i64 0, i64* %t460
  br label %sym_tbl_rehash_cond_74
sym_tbl_rehash_cond_74:
  %t461 = load i64, i64* %t460
  %t462 = icmp slt i64 %t461, %t441
  br i1 %t462, label %sym_tbl_rehash_body_75, label %sym_tbl_rehash_end_76
sym_tbl_rehash_body_75:
  %t463 = getelementptr inbounds i8*, i8** %t459, i64 %t461
  %t464 = load i8*, i8** %t463
  %t465 = call i64 @hash_str(i8* %t464)
  %t466 = and i64 %t465, %t450
  store i64 0, i64* %t467
  store i64 %t466, i64* %t468
  br label %sym_fe_cond_77
sym_fe_cond_77:
  %t469 = load i64, i64* %t467
  %t470 = icmp slt i64 %t469, %t449
  br i1 %t470, label %sym_fe_body_78, label %sym_fe_end_80
sym_fe_body_78:
  %t471 = load i64, i64* %t468
  %t472 = getelementptr inbounds i64, i64* %t453, i64 %t471
  %t473 = load i64, i64* %t472
  %t474 = icmp eq i64 %t473, -1
  br i1 %t474, label %sym_fe_end_80, label %sym_fe_next_79
sym_fe_next_79:
  %t475 = add i64 %t471, 1
  %t476 = and i64 %t475, %t450
  store i64 %t476, i64* %t468
  %t477 = add i64 %t469, 1
  store i64 %t477, i64* %t467
  br label %sym_fe_cond_77
sym_fe_end_80:
  %t478 = load i64, i64* %t468
  %t479 = getelementptr inbounds i64, i64* %t453, i64 %t478
  store i64 %t461, i64* %t479
  %t480 = add i64 %t461, 1
  store i64 %t480, i64* %t460
  br label %sym_tbl_rehash_cond_74
sym_tbl_rehash_end_76:
  %t481 = load i64*, i64** @sym.tbl.ids
  %t482 = bitcast i64* %t481 to i8*
  call void @free(i8* %t482)
  store i64* %t453, i64** @sym.tbl.ids
  store i64 %t449, i64* @sym.tbl.cap
  br label %sym_tbl_after_grow_70
sym_tbl_after_grow_70:
  %t483 = load i64*, i64** @sym.tbl.ids
  %t484 = load i64, i64* @sym.tbl.cap
  %t485 = sub i64 %t484, 1
  %t486 = call i64 @hash_str(i8* %t439)
  %t487 = and i64 %t486, %t485
  store i64 0, i64* %t488
  store i64 %t487, i64* %t489
  store i1 false, i1* %t490
  store i64 -1, i64* %t491
  br label %sym_probe_cond_81
sym_probe_cond_81:
  %t492 = load i64, i64* %t488
  %t493 = icmp slt i64 %t492, %t484
  br i1 %t493, label %sym_probe_body_82, label %sym_probe_end_86
sym_probe_body_82:
  %t494 = load i64, i64* %t489
  %t495 = getelementptr inbounds i64, i64* %t483, i64 %t494
  %t496 = load i64, i64* %t495
  %t497 = icmp eq i64 %t496, -1
  br i1 %t497, label %sym_probe_end_86, label %sym_probe_on_occ_83
sym_probe_on_occ_83:
  %t498 = load i8**, i8*** @sym.data
  %t499 = getelementptr inbounds i8*, i8** %t498, i64 %t496
  %t500 = load i8*, i8** %t499
  %t501 = call i32 @strcmp(i8* %t500, i8* %t439)
  %t502 = icmp eq i32 %t501, 0
  br i1 %t502, label %sym_probe_on_match_84, label %sym_probe_next_85
sym_probe_on_match_84:
  store i1 true, i1* %t490
  store i64 %t496, i64* %t491
  br label %sym_probe_end_86
sym_probe_next_85:
  %t503 = add i64 %t494, 1
  %t504 = and i64 %t503, %t485
  store i64 %t504, i64* %t489
  %t505 = add i64 %t492, 1
  store i64 %t505, i64* %t488
  br label %sym_probe_cond_81
sym_probe_end_86:
  %t506 = load i1, i1* %t490
  %t507 = load i64, i64* %t491
  %t508 = load i64, i64* %t489
  br i1 %t506, label %sym_found_87, label %sym_notfound_88
sym_found_87:
  call void @star_rc_release(i8* %t439)
  br label %sym_done_89
sym_notfound_88:
  %t509 = load i64, i64* @sym.cap
  %t510 = icmp sge i64 %t441, %t509
  br i1 %t510, label %sym_grow_90, label %sym_store_91
sym_grow_90:
  %t511 = mul i64 %t509, 2
  %t512 = icmp sgt i64 %t511, 0
  %t513 = select i1 %t512, i64 %t511, i64 1
  %t514 = mul i64 %t513, 8
  %t515 = call i8* @malloc(i64 %t514)
  %t516 = bitcast i8* %t515 to i8**
  %t517 = icmp sgt i64 %t509, 0
  br i1 %t517, label %sym_copy_92, label %sym_after_copy_93
sym_copy_92:
  %t518 = mul i64 %t441, 8
  %t519 = load i8**, i8*** @sym.data
  %t520 = bitcast i8** %t519 to i8*
  call i8* @memcpy(i8* %t515, i8* %t520, i64 %t518)
  call void @free(i8* %t520)
  br label %sym_after_copy_93
sym_after_copy_93:
  store i8** %t516, i8*** @sym.data
  store i64 %t513, i64* @sym.cap
  br label %sym_store_91
sym_store_91:
  %t521 = load i8**, i8*** @sym.data
  %t522 = getelementptr inbounds i8*, i8** %t521, i64 %t441
  store i8* %t439, i8** %t522
  %t523 = add i64 %t441, 1
  store i64 %t523, i64* @sym.len
  %t524 = load i64*, i64** @sym.tbl.ids
  %t525 = getelementptr inbounds i64, i64* %t524, i64 %t508
  store i64 %t441, i64* %t525
  br label %sym_done_89
sym_done_89:
  %t526 = phi i64 [ %t507, %sym_found_87 ], [ %t441, %sym_store_91 ]
  call i32 @ReleaseSemaphore(i8* %t440, i32 1, i32* null)
  store i64 %t526, i64* %t434
  %t527 = load i64, i64* %t434
  %t528 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t528, i64 %t527)
  ret i32 0
}


; par/swarm worker functions
define i64 @hash_str(i8* %v) {
entry:
  %t86 = alloca i64
  %t89 = alloca i64
  store i64 -3750763034362895579, i64* %t86
  %t87 = call i32 @strlen(i8* %v)
  %t88 = zext i32 %t87 to i64
  store i64 0, i64* %t89
  br label %hash_str_cond_28
hash_str_cond_28:
  %t90 = load i64, i64* %t89
  %t91 = icmp slt i64 %t90, %t88
  br i1 %t91, label %hash_str_body_29, label %hash_str_end_30
hash_str_body_29:
  %t92 = getelementptr inbounds i8, i8* %v, i64 %t90
  %t93 = load i8, i8* %t92
  %t94 = zext i8 %t93 to i64
  %t95 = load i64, i64* %t86
  %t96 = xor i64 %t95, %t94
  %t97 = mul i64 %t96, 1099511628211
  store i64 %t97, i64* %t86
  %t98 = add i64 %t90, 1
  store i64 %t98, i64* %t89
  br label %hash_str_cond_28
hash_str_end_30:
  %t99 = load i64, i64* %t86
  ret i64 %t99
}


define i32 @par_worker_17(i8* %argp) {
entry:
  %t56 = alloca i64
  %t80 = alloca i64
  %t100 = alloca i64
  %t107 = alloca i64
  %t108 = alloca i64
  %t128 = alloca i64
  %t129 = alloca i64
  %t130 = alloca i1
  %t131 = alloca i64
  %t46 = bitcast i8* %argp to { i64, i64, i32*, i8** }*
  %t47 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t46, i32 0, i32 0
  %t48 = load i64, i64* %t47
  %t49 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t46, i32 0, i32 1
  %t50 = load i64, i64* %t49
  %t51 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t46, i32 0, i32 2
  %t52 = load i32*, i32** %t51
  %t53 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t46, i32 0, i32 3
  %t54 = load i8**, i8*** %t53
  %t55 = load %Entity*, %Entity** @arena.Entities.data
  store i64 %t48, i64* %t56
  br label %par_cond_18
par_cond_18:
  %t57 = load i64, i64* %t56
  %t58 = icmp slt i64 %t57, %t50
  br i1 %t58, label %par_body_19, label %par_end_22
par_body_19:
  %t59 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t57
  %t60 = load i64, i64* %t59
  %t61 = and i64 %t60, 1
  %t62 = icmp eq i64 %t61, 1
  br i1 %t62, label %par_live_20, label %par_incr_21
par_live_20:
  %t63 = getelementptr inbounds %Entity, %Entity* %t55, i64 %t57
  %t64 = load i8*, i8** %t54
  %t65 = load i8*, i8** %t54
  call void @star_rc_retain(i8* %t65)
  %t66 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t66, i32 -1)
  %t67 = load i64, i64* @sym.len
  %t68 = load i64, i64* @sym.tbl.cap
  %t70 = add i64 %t67, 1
  %t69 = mul i64 %t70, 4
  %t71 = mul i64 %t68, 3
  %t72 = icmp sgt i64 %t69, %t71
  br i1 %t72, label %sym_tbl_grow_23, label %sym_tbl_after_grow_24
sym_tbl_grow_23:
  %t73 = mul i64 %t68, 2
  %t74 = icmp sgt i64 %t73, 0
  %t75 = select i1 %t74, i64 %t73, i64 8
  %t76 = sub i64 %t75, 1
  %t77 = mul i64 %t75, 8
  %t78 = call i8* @malloc(i64 %t77)
  %t79 = bitcast i8* %t78 to i64*
  store i64 0, i64* %t80
  br label %ht_fill64_cond_25
ht_fill64_cond_25:
  %t81 = load i64, i64* %t80
  %t82 = icmp slt i64 %t81, %t75
  br i1 %t82, label %ht_fill64_body_26, label %ht_fill64_end_27
ht_fill64_body_26:
  %t83 = getelementptr inbounds i64, i64* %t79, i64 %t81
  store i64 -1, i64* %t83
  %t84 = add i64 %t81, 1
  store i64 %t84, i64* %t80
  br label %ht_fill64_cond_25
ht_fill64_end_27:
  %t85 = load i8**, i8*** @sym.data
  store i64 0, i64* %t100
  br label %sym_tbl_rehash_cond_31
sym_tbl_rehash_cond_31:
  %t101 = load i64, i64* %t100
  %t102 = icmp slt i64 %t101, %t67
  br i1 %t102, label %sym_tbl_rehash_body_32, label %sym_tbl_rehash_end_33
sym_tbl_rehash_body_32:
  %t103 = getelementptr inbounds i8*, i8** %t85, i64 %t101
  %t104 = load i8*, i8** %t103
  %t105 = call i64 @hash_str(i8* %t104)
  %t106 = and i64 %t105, %t76
  store i64 0, i64* %t107
  store i64 %t106, i64* %t108
  br label %sym_fe_cond_34
sym_fe_cond_34:
  %t109 = load i64, i64* %t107
  %t110 = icmp slt i64 %t109, %t75
  br i1 %t110, label %sym_fe_body_35, label %sym_fe_end_37
sym_fe_body_35:
  %t111 = load i64, i64* %t108
  %t112 = getelementptr inbounds i64, i64* %t79, i64 %t111
  %t113 = load i64, i64* %t112
  %t114 = icmp eq i64 %t113, -1
  br i1 %t114, label %sym_fe_end_37, label %sym_fe_next_36
sym_fe_next_36:
  %t115 = add i64 %t111, 1
  %t116 = and i64 %t115, %t76
  store i64 %t116, i64* %t108
  %t117 = add i64 %t109, 1
  store i64 %t117, i64* %t107
  br label %sym_fe_cond_34
sym_fe_end_37:
  %t118 = load i64, i64* %t108
  %t119 = getelementptr inbounds i64, i64* %t79, i64 %t118
  store i64 %t101, i64* %t119
  %t120 = add i64 %t101, 1
  store i64 %t120, i64* %t100
  br label %sym_tbl_rehash_cond_31
sym_tbl_rehash_end_33:
  %t121 = load i64*, i64** @sym.tbl.ids
  %t122 = bitcast i64* %t121 to i8*
  call void @free(i8* %t122)
  store i64* %t79, i64** @sym.tbl.ids
  store i64 %t75, i64* @sym.tbl.cap
  br label %sym_tbl_after_grow_24
sym_tbl_after_grow_24:
  %t123 = load i64*, i64** @sym.tbl.ids
  %t124 = load i64, i64* @sym.tbl.cap
  %t125 = sub i64 %t124, 1
  %t126 = call i64 @hash_str(i8* %t64)
  %t127 = and i64 %t126, %t125
  store i64 0, i64* %t128
  store i64 %t127, i64* %t129
  store i1 false, i1* %t130
  store i64 -1, i64* %t131
  br label %sym_probe_cond_38
sym_probe_cond_38:
  %t132 = load i64, i64* %t128
  %t133 = icmp slt i64 %t132, %t124
  br i1 %t133, label %sym_probe_body_39, label %sym_probe_end_43
sym_probe_body_39:
  %t134 = load i64, i64* %t129
  %t135 = getelementptr inbounds i64, i64* %t123, i64 %t134
  %t136 = load i64, i64* %t135
  %t137 = icmp eq i64 %t136, -1
  br i1 %t137, label %sym_probe_end_43, label %sym_probe_on_occ_40
sym_probe_on_occ_40:
  %t138 = load i8**, i8*** @sym.data
  %t139 = getelementptr inbounds i8*, i8** %t138, i64 %t136
  %t140 = load i8*, i8** %t139
  %t141 = call i32 @strcmp(i8* %t140, i8* %t64)
  %t142 = icmp eq i32 %t141, 0
  br i1 %t142, label %sym_probe_on_match_41, label %sym_probe_next_42
sym_probe_on_match_41:
  store i1 true, i1* %t130
  store i64 %t136, i64* %t131
  br label %sym_probe_end_43
sym_probe_next_42:
  %t143 = add i64 %t134, 1
  %t144 = and i64 %t143, %t125
  store i64 %t144, i64* %t129
  %t145 = add i64 %t132, 1
  store i64 %t145, i64* %t128
  br label %sym_probe_cond_38
sym_probe_end_43:
  %t146 = load i1, i1* %t130
  %t147 = load i64, i64* %t131
  %t148 = load i64, i64* %t129
  br i1 %t146, label %sym_found_44, label %sym_notfound_45
sym_found_44:
  call void @star_rc_release(i8* %t64)
  br label %sym_done_46
sym_notfound_45:
  %t149 = load i64, i64* @sym.cap
  %t150 = icmp sge i64 %t67, %t149
  br i1 %t150, label %sym_grow_47, label %sym_store_48
sym_grow_47:
  %t151 = mul i64 %t149, 2
  %t152 = icmp sgt i64 %t151, 0
  %t153 = select i1 %t152, i64 %t151, i64 1
  %t154 = mul i64 %t153, 8
  %t155 = call i8* @malloc(i64 %t154)
  %t156 = bitcast i8* %t155 to i8**
  %t157 = icmp sgt i64 %t149, 0
  br i1 %t157, label %sym_copy_49, label %sym_after_copy_50
sym_copy_49:
  %t158 = mul i64 %t67, 8
  %t159 = load i8**, i8*** @sym.data
  %t160 = bitcast i8** %t159 to i8*
  call i8* @memcpy(i8* %t155, i8* %t160, i64 %t158)
  call void @free(i8* %t160)
  br label %sym_after_copy_50
sym_after_copy_50:
  store i8** %t156, i8*** @sym.data
  store i64 %t153, i64* @sym.cap
  br label %sym_store_48
sym_store_48:
  %t161 = load i8**, i8*** @sym.data
  %t162 = getelementptr inbounds i8*, i8** %t161, i64 %t67
  store i8* %t64, i8** %t162
  %t163 = add i64 %t67, 1
  store i64 %t163, i64* @sym.len
  %t164 = load i64*, i64** @sym.tbl.ids
  %t165 = getelementptr inbounds i64, i64* %t164, i64 %t148
  store i64 %t67, i64* %t165
  br label %sym_done_46
sym_done_46:
  %t166 = phi i64 [ %t147, %sym_found_44 ], [ %t67, %sym_store_48 ]
  call i32 @ReleaseSemaphore(i8* %t66, i32 1, i32* null)
  %t167 = getelementptr inbounds %Entity, %Entity* %t63, i32 0, i32 0
  store i64 %t166, i64* %t167
  br label %par_incr_21
par_incr_21:
  %t168 = add i64 %t57, 1
  store i64 %t168, i64* %t56
  br label %par_cond_18
par_end_22:
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
  %t169 = ptrtoint i8* %idx_arg to i64
  %t170 = trunc i64 %t169 to i32
  %t171 = call i32 @GetCurrentThreadId()
  %t172 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t170
  store i32 %t171, i32* %t172
  br label %loop
loop:
  %t173 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t170
  %t174 = load i8*, i8** %t173
  %t175 = call i32 @WaitForSingleObject(i8* %t174, i32 -1)
  %t176 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t170
  %t177 = load i32 (i8*)*, i32 (i8*)** %t176
  %t178 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t170
  %t179 = load i8*, i8** %t178
  %t180 = call i32 %t177(i8* %t179)
  %t181 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t170
  %t182 = load i8*, i8** %t181
  %t183 = call i32 @ReleaseSemaphore(i8* %t182, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t184 = load i1, i1* @par.pool.inited
  br i1 %t184, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t185 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t185, i8** @par.pool.serial_lock
  %t186 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t187 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t186, i8** %t187
  %t188 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t189 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t188, i8** %t189
  %t190 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t191 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t192 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t191, i8** %t192
  %t193 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t194 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t193, i8** %t194
  %t195 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t196 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t197 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t196, i8** %t197
  %t198 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t199 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t198, i8** %t199
  %t200 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t201 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t202 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t201, i8** %t202
  %t203 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t204 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t203, i8** %t204
  %t205 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_57(i8* %argp) {
entry:
  %t322 = alloca i64
  %t314 = bitcast i8* %argp to { i64, i64, i32* }*
  %t315 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t314, i32 0, i32 0
  %t316 = load i64, i64* %t315
  %t317 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t314, i32 0, i32 1
  %t318 = load i64, i64* %t317
  %t319 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t314, i32 0, i32 2
  %t320 = load i32*, i32** %t319
  %t321 = load %Entity*, %Entity** @arena.Entities.data
  store i64 %t316, i64* %t322
  br label %par_cond_58
par_cond_58:
  %t323 = load i64, i64* %t322
  %t324 = icmp slt i64 %t323, %t318
  br i1 %t324, label %par_body_59, label %par_end_62
par_body_59:
  %t325 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t323
  %t326 = load i64, i64* %t325
  %t327 = and i64 %t326, 1
  %t328 = icmp eq i64 %t327, 1
  br i1 %t328, label %par_live_60, label %par_incr_61
par_live_60:
  %t329 = getelementptr inbounds %Entity, %Entity* %t321, i64 %t323
  %t330 = getelementptr inbounds %Entity, %Entity* %t329, i32 0, i32 0
  %t331 = load i64, i64* %t330
  %t332 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t332, i64 %t331)
  br label %par_incr_61
par_incr_61:
  %t333 = add i64 %t323, 1
  store i64 %t333, i64* %t322
  br label %par_cond_58
par_end_62:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [141 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.1 = private unnamed_addr constant [6 x i8] c"tag%d\00"
@.str.2 = private unnamed_addr constant [6 x i8] c"%lld\0A\00"
@.str.3 = private unnamed_addr constant [6 x i8] c"tag%d\00"
@.str.4 = private unnamed_addr constant [14 x i8] c"check = %lld\0A\00"
