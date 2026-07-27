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
declare i32 @SDL_OpenAudioDevice(i8*, i32, i8*, i8*, i32)
declare void @SDL_PauseAudioDevice(i32, i32)
declare void @SDL_MixAudioFormat(i8*, i8*, i16, i32, i32)
declare i32 @SDL_NumJoysticks()
declare i8* @SDL_JoystickOpen(i32)
declare void @SDL_JoystickClose(i8*)
declare void @SDL_JoystickUpdate()
declare i8 @SDL_JoystickGetButton(i8*, i32)
declare i16 @SDL_JoystickGetAxis(i8*, i32)
declare i32 @SDL_JoystickGetAttached(i8*)
declare i8* @CreateCompatibleDC(i8*)
declare i8* @CreateFontA(i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i8*)
declare i8* @SelectObject(i8*, i8*)
declare i32 @DeleteObject(i8*)
declare i32 @DeleteDC(i8*)
declare i32 @SetBkMode(i8*, i32)
declare i32 @SetTextColor(i8*, i32)
declare i32 @GetTextExtentPoint32A(i8*, i8*, i32, i8*)
declare i32 @GetTextMetricsA(i8*, i8*)
declare i8* @CreateDIBSection(i8*, i8*, i32, i8**, i8*, i32)
declare i32 @TextOutA(i8*, i32, i32, i8*, i32)
declare i32 @AddFontResourceExA(i8*, i32, i8*)
declare i32 @RemoveFontResourceExA(i8*, i32, i8*)
declare i8* @SDL_CreateTexture(i8*, i32, i32, i32, i32)
declare i32 @SDL_UpdateTexture(i8*, i8*, i8*, i32)
declare i32 @SDL_SetTextureBlendMode(i8*, i32)
declare i32 @SDL_SetTextureColorMod(i8*, i8, i8, i8)
declare i32 @SDL_SetTextureAlphaMod(i8*, i8)
declare i32 @SDL_RenderCopy(i8*, i8*, i8*, i8*)
declare void @SDL_DestroyTexture(i8*)
declare i8* @CreateThread(i8*, i64, i8*, i8*, i32, i32*)
declare i32 @WaitForSingleObject(i8*, i32)
declare i32 @CloseHandle(i8*)
declare i8* @CreateSemaphoreA(i8*, i32, i32, i8*)
declare i32 @ReleaseSemaphore(i8*, i32, i32*)
declare i32 @GetCurrentThreadId()
declare void @GetSystemInfo(i8*)
declare i32 @atoi(i8*)
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

@frame.buf = global [16777216 x i8] zeroinitializer
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
  %t212 = alloca i32
  %t213 = alloca i32
  %t223 = alloca [64 x { i64, i64, i32*, i8** }]
  %t224 = alloca i32
  %t246 = alloca i32
  %t258 = alloca { i64, i64, i32*, i8** }
  %t293 = alloca i32
  %t294 = alloca i32
  %t304 = alloca [64 x { i64, i64, i32* }]
  %t305 = alloca i32
  %t326 = alloca i32
  %t338 = alloca { i64, i64, i32* }
  %t346 = alloca i64
  %t366 = alloca i64
  %t372 = alloca i64
  %t379 = alloca i64
  %t380 = alloca i64
  %t400 = alloca i64
  %t401 = alloca i64
  %t402 = alloca i1
  %t403 = alloca i64
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
  %t209 = load i32, i32* @par.pool.num_workers
  %t210 = sext i32 %t209 to i64
  %t211 = call i32 @GetCurrentThreadId()
  store i32 -1, i32* %t212
  store i32 0, i32* %t213
  br label %par_reentry_cond_51
par_reentry_cond_51:
  %t214 = load i32, i32* %t213
  %t215 = icmp slt i32 %t214, %t209
  br i1 %t215, label %par_reentry_body_52, label %par_reentry_end_55
par_reentry_body_52:
  %t216 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t214
  %t217 = load i32, i32* %t216
  %t218 = icmp eq i32 %t211, %t217
  br i1 %t218, label %par_reentry_match_53, label %par_reentry_step_54
par_reentry_match_53:
  store i32 %t214, i32* %t212
  br label %par_reentry_step_54
par_reentry_step_54:
  %t219 = add i32 %t214, 1
  store i32 %t219, i32* %t213
  br label %par_reentry_cond_51
par_reentry_end_55:
  %t220 = load i32, i32* %t212
  %t221 = icmp sge i32 %t220, 0
  br i1 %t221, label %par_serial_57, label %par_pooled_56
par_pooled_56:
  %t222 = load i64, i64* @arena.Entities.count
  store i32 0, i32* %t224
  br label %par_fanout_cond_62
par_fanout_cond_62:
  %t225 = load i32, i32* %t224
  %t226 = icmp slt i32 %t225, %t209
  br i1 %t226, label %par_fanout_body_63, label %par_fanout_end_65
par_fanout_body_63:
  %t227 = sext i32 %t225 to i64
  %t228 = mul i64 %t222, %t227
  %t229 = sdiv i64 %t228, %t210
  %t230 = add i32 %t225, 1
  %t231 = sext i32 %t230 to i64
  %t232 = mul i64 %t222, %t231
  %t233 = sdiv i64 %t232, %t210
  %t234 = getelementptr inbounds [64 x { i64, i64, i32*, i8** }], [64 x { i64, i64, i32*, i8** }]* %t223, i32 0, i32 %t225
  %t235 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t234, i32 0, i32 0
  store i64 %t229, i64* %t235
  %t236 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t234, i32 0, i32 1
  store i64 %t233, i64* %t236
  %t237 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t234, i32 0, i32 2
  store i32* %t36, i32** %t237
  %t238 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t234, i32 0, i32 3
  store i8** %t39, i8*** %t238
  %t239 = bitcast { i64, i64, i32*, i8** }* %t234 to i8*
  %t240 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t225
  store i8* %t239, i8** %t240
  %t241 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t225
  store i32 (i8*)* @par_worker_17, i32 (i8*)** %t241
  %t242 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t225
  %t243 = load i8*, i8** %t242
  %t244 = call i32 @ReleaseSemaphore(i8* %t243, i32 1, i32* null)
  br label %par_fanout_step_64
par_fanout_step_64:
  %t245 = add i32 %t225, 1
  store i32 %t245, i32* %t224
  br label %par_fanout_cond_62
par_fanout_end_65:
  store i32 0, i32* %t246
  br label %par_join_wait_cond_66
par_join_wait_cond_66:
  %t247 = load i32, i32* %t246
  %t248 = icmp slt i32 %t247, %t209
  br i1 %t248, label %par_join_wait_body_67, label %par_join_wait_end_69
par_join_wait_body_67:
  %t249 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t247
  %t250 = load i8*, i8** %t249
  %t251 = call i32 @WaitForSingleObject(i8* %t250, i32 -1)
  br label %par_join_wait_step_68
par_join_wait_step_68:
  %t252 = add i32 %t247, 1
  store i32 %t252, i32* %t246
  br label %par_join_wait_cond_66
par_join_wait_end_69:
  br label %par_join_61
par_serial_57:
  %t253 = load i32, i32* @par.pool.serial_owner
  %t254 = icmp eq i32 %t253, %t220
  br i1 %t254, label %par_run_59, label %par_acquire_58
par_acquire_58:
  %t255 = load i8*, i8** @par.pool.serial_lock
  %t256 = call i32 @WaitForSingleObject(i8* %t255, i32 -1)
  store i32 %t220, i32* @par.pool.serial_owner
  br label %par_run_59
par_run_59:
  %t257 = load i64, i64* @arena.Entities.count
  %t259 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t258, i32 0, i32 0
  store i64 0, i64* %t259
  %t260 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t258, i32 0, i32 1
  store i64 %t257, i64* %t260
  %t261 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t258, i32 0, i32 2
  store i32* %t36, i32** %t261
  %t262 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t258, i32 0, i32 3
  store i8** %t39, i8*** %t262
  %t263 = bitcast { i64, i64, i32*, i8** }* %t258 to i8*
  %t264 = call i32 @par_worker_17(i8* %t263)
  br i1 %t254, label %par_join_61, label %par_release_60
par_release_60:
  store i32 -1, i32* @par.pool.serial_owner
  %t265 = load i8*, i8** @par.pool.serial_lock
  %t266 = call i32 @ReleaseSemaphore(i8* %t265, i32 1, i32* null)
  br label %par_join_61
par_join_61:
  %t267 = load i8*, i8** %t39
  call void @star_rc_release(i8* %t267)
  br label %for_step_15
for_step_15:
  %t268 = load i32, i32* %t36
  %t269 = add i32 %t268, 1
  store i32 %t269, i32* %t36
  br label %for_cond_13
for_end_16:
  call void @par.pool.ensure_init()
  %t290 = load i32, i32* @par.pool.num_workers
  %t291 = sext i32 %t290 to i64
  %t292 = call i32 @GetCurrentThreadId()
  store i32 -1, i32* %t293
  store i32 0, i32* %t294
  br label %par_reentry_cond_76
par_reentry_cond_76:
  %t295 = load i32, i32* %t294
  %t296 = icmp slt i32 %t295, %t290
  br i1 %t296, label %par_reentry_body_77, label %par_reentry_end_80
par_reentry_body_77:
  %t297 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t295
  %t298 = load i32, i32* %t297
  %t299 = icmp eq i32 %t292, %t298
  br i1 %t299, label %par_reentry_match_78, label %par_reentry_step_79
par_reentry_match_78:
  store i32 %t295, i32* %t293
  br label %par_reentry_step_79
par_reentry_step_79:
  %t300 = add i32 %t295, 1
  store i32 %t300, i32* %t294
  br label %par_reentry_cond_76
par_reentry_end_80:
  %t301 = load i32, i32* %t293
  %t302 = icmp sge i32 %t301, 0
  br i1 %t302, label %par_serial_82, label %par_pooled_81
par_pooled_81:
  %t303 = load i64, i64* @arena.Entities.count
  store i32 0, i32* %t305
  br label %par_fanout_cond_87
par_fanout_cond_87:
  %t306 = load i32, i32* %t305
  %t307 = icmp slt i32 %t306, %t290
  br i1 %t307, label %par_fanout_body_88, label %par_fanout_end_90
par_fanout_body_88:
  %t308 = sext i32 %t306 to i64
  %t309 = mul i64 %t303, %t308
  %t310 = sdiv i64 %t309, %t291
  %t311 = add i32 %t306, 1
  %t312 = sext i32 %t311 to i64
  %t313 = mul i64 %t303, %t312
  %t314 = sdiv i64 %t313, %t291
  %t315 = getelementptr inbounds [64 x { i64, i64, i32* }], [64 x { i64, i64, i32* }]* %t304, i32 0, i32 %t306
  %t316 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t315, i32 0, i32 0
  store i64 %t310, i64* %t316
  %t317 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t315, i32 0, i32 1
  store i64 %t314, i64* %t317
  %t318 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t315, i32 0, i32 2
  store i32* %t36, i32** %t318
  %t319 = bitcast { i64, i64, i32* }* %t315 to i8*
  %t320 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t306
  store i8* %t319, i8** %t320
  %t321 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t306
  store i32 (i8*)* @par_worker_70, i32 (i8*)** %t321
  %t322 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t306
  %t323 = load i8*, i8** %t322
  %t324 = call i32 @ReleaseSemaphore(i8* %t323, i32 1, i32* null)
  br label %par_fanout_step_89
par_fanout_step_89:
  %t325 = add i32 %t306, 1
  store i32 %t325, i32* %t305
  br label %par_fanout_cond_87
par_fanout_end_90:
  store i32 0, i32* %t326
  br label %par_join_wait_cond_91
par_join_wait_cond_91:
  %t327 = load i32, i32* %t326
  %t328 = icmp slt i32 %t327, %t290
  br i1 %t328, label %par_join_wait_body_92, label %par_join_wait_end_94
par_join_wait_body_92:
  %t329 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t327
  %t330 = load i8*, i8** %t329
  %t331 = call i32 @WaitForSingleObject(i8* %t330, i32 -1)
  br label %par_join_wait_step_93
par_join_wait_step_93:
  %t332 = add i32 %t327, 1
  store i32 %t332, i32* %t326
  br label %par_join_wait_cond_91
par_join_wait_end_94:
  br label %par_join_86
par_serial_82:
  %t333 = load i32, i32* @par.pool.serial_owner
  %t334 = icmp eq i32 %t333, %t301
  br i1 %t334, label %par_run_84, label %par_acquire_83
par_acquire_83:
  %t335 = load i8*, i8** @par.pool.serial_lock
  %t336 = call i32 @WaitForSingleObject(i8* %t335, i32 -1)
  store i32 %t301, i32* @par.pool.serial_owner
  br label %par_run_84
par_run_84:
  %t337 = load i64, i64* @arena.Entities.count
  %t339 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t338, i32 0, i32 0
  store i64 0, i64* %t339
  %t340 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t338, i32 0, i32 1
  store i64 %t337, i64* %t340
  %t341 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t338, i32 0, i32 2
  store i32* %t36, i32** %t341
  %t342 = bitcast { i64, i64, i32* }* %t338 to i8*
  %t343 = call i32 @par_worker_70(i8* %t342)
  br i1 %t334, label %par_join_86, label %par_release_85
par_release_85:
  store i32 -1, i32* @par.pool.serial_owner
  %t344 = load i8*, i8** @par.pool.serial_lock
  %t345 = call i32 @ReleaseSemaphore(i8* %t344, i32 1, i32* null)
  br label %par_join_86
par_join_86:
  %t347 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.3, i64 0, i64 0
  %t348 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t347, i32 199)
  %t349 = add i32 %t348, 1
  %t350 = sext i32 %t349 to i64
  %t351 = call i8* @star_rc_alloc(i64 %t350, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t351, i64 %t350, i8* %t347, i32 199)
  %t352 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t352, i32 -1)
  %t353 = load i64, i64* @sym.len
  %t354 = load i64, i64* @sym.tbl.cap
  %t356 = add i64 %t353, 1
  %t355 = mul i64 %t356, 4
  %t357 = mul i64 %t354, 3
  %t358 = icmp sgt i64 %t355, %t357
  br i1 %t358, label %sym_tbl_grow_95, label %sym_tbl_after_grow_96
sym_tbl_grow_95:
  %t359 = mul i64 %t354, 2
  %t360 = icmp sgt i64 %t359, 0
  %t361 = select i1 %t360, i64 %t359, i64 8
  %t362 = sub i64 %t361, 1
  %t363 = mul i64 %t361, 8
  %t364 = call i8* @malloc(i64 %t363)
  %t365 = bitcast i8* %t364 to i64*
  store i64 0, i64* %t366
  br label %ht_fill64_cond_97
ht_fill64_cond_97:
  %t367 = load i64, i64* %t366
  %t368 = icmp slt i64 %t367, %t361
  br i1 %t368, label %ht_fill64_body_98, label %ht_fill64_end_99
ht_fill64_body_98:
  %t369 = getelementptr inbounds i64, i64* %t365, i64 %t367
  store i64 -1, i64* %t369
  %t370 = add i64 %t367, 1
  store i64 %t370, i64* %t366
  br label %ht_fill64_cond_97
ht_fill64_end_99:
  %t371 = load i8**, i8*** @sym.data
  store i64 0, i64* %t372
  br label %sym_tbl_rehash_cond_100
sym_tbl_rehash_cond_100:
  %t373 = load i64, i64* %t372
  %t374 = icmp slt i64 %t373, %t353
  br i1 %t374, label %sym_tbl_rehash_body_101, label %sym_tbl_rehash_end_102
sym_tbl_rehash_body_101:
  %t375 = getelementptr inbounds i8*, i8** %t371, i64 %t373
  %t376 = load i8*, i8** %t375
  %t377 = call i64 @hash_str(i8* %t376)
  %t378 = and i64 %t377, %t362
  store i64 0, i64* %t379
  store i64 %t378, i64* %t380
  br label %sym_fe_cond_103
sym_fe_cond_103:
  %t381 = load i64, i64* %t379
  %t382 = icmp slt i64 %t381, %t361
  br i1 %t382, label %sym_fe_body_104, label %sym_fe_end_106
sym_fe_body_104:
  %t383 = load i64, i64* %t380
  %t384 = getelementptr inbounds i64, i64* %t365, i64 %t383
  %t385 = load i64, i64* %t384
  %t386 = icmp eq i64 %t385, -1
  br i1 %t386, label %sym_fe_end_106, label %sym_fe_next_105
sym_fe_next_105:
  %t387 = add i64 %t383, 1
  %t388 = and i64 %t387, %t362
  store i64 %t388, i64* %t380
  %t389 = add i64 %t381, 1
  store i64 %t389, i64* %t379
  br label %sym_fe_cond_103
sym_fe_end_106:
  %t390 = load i64, i64* %t380
  %t391 = getelementptr inbounds i64, i64* %t365, i64 %t390
  store i64 %t373, i64* %t391
  %t392 = add i64 %t373, 1
  store i64 %t392, i64* %t372
  br label %sym_tbl_rehash_cond_100
sym_tbl_rehash_end_102:
  %t393 = load i64*, i64** @sym.tbl.ids
  %t394 = bitcast i64* %t393 to i8*
  call void @free(i8* %t394)
  store i64* %t365, i64** @sym.tbl.ids
  store i64 %t361, i64* @sym.tbl.cap
  br label %sym_tbl_after_grow_96
sym_tbl_after_grow_96:
  %t395 = load i64*, i64** @sym.tbl.ids
  %t396 = load i64, i64* @sym.tbl.cap
  %t397 = sub i64 %t396, 1
  %t398 = call i64 @hash_str(i8* %t351)
  %t399 = and i64 %t398, %t397
  store i64 0, i64* %t400
  store i64 %t399, i64* %t401
  store i1 false, i1* %t402
  store i64 -1, i64* %t403
  br label %sym_probe_cond_107
sym_probe_cond_107:
  %t404 = load i64, i64* %t400
  %t405 = icmp slt i64 %t404, %t396
  br i1 %t405, label %sym_probe_body_108, label %sym_probe_end_112
sym_probe_body_108:
  %t406 = load i64, i64* %t401
  %t407 = getelementptr inbounds i64, i64* %t395, i64 %t406
  %t408 = load i64, i64* %t407
  %t409 = icmp eq i64 %t408, -1
  br i1 %t409, label %sym_probe_end_112, label %sym_probe_on_occ_109
sym_probe_on_occ_109:
  %t410 = load i8**, i8*** @sym.data
  %t411 = getelementptr inbounds i8*, i8** %t410, i64 %t408
  %t412 = load i8*, i8** %t411
  %t413 = call i32 @strcmp(i8* %t412, i8* %t351)
  %t414 = icmp eq i32 %t413, 0
  br i1 %t414, label %sym_probe_on_match_110, label %sym_probe_next_111
sym_probe_on_match_110:
  store i1 true, i1* %t402
  store i64 %t408, i64* %t403
  br label %sym_probe_end_112
sym_probe_next_111:
  %t415 = add i64 %t406, 1
  %t416 = and i64 %t415, %t397
  store i64 %t416, i64* %t401
  %t417 = add i64 %t404, 1
  store i64 %t417, i64* %t400
  br label %sym_probe_cond_107
sym_probe_end_112:
  %t418 = load i1, i1* %t402
  %t419 = load i64, i64* %t403
  %t420 = load i64, i64* %t401
  br i1 %t418, label %sym_found_113, label %sym_notfound_114
sym_found_113:
  call void @star_rc_release(i8* %t351)
  br label %sym_done_115
sym_notfound_114:
  %t421 = load i64, i64* @sym.cap
  %t422 = icmp sge i64 %t353, %t421
  br i1 %t422, label %sym_grow_116, label %sym_store_117
sym_grow_116:
  %t423 = mul i64 %t421, 2
  %t424 = icmp sgt i64 %t423, 0
  %t425 = select i1 %t424, i64 %t423, i64 1
  %t426 = mul i64 %t425, 8
  %t427 = call i8* @malloc(i64 %t426)
  %t428 = bitcast i8* %t427 to i8**
  %t429 = icmp sgt i64 %t421, 0
  br i1 %t429, label %sym_copy_118, label %sym_after_copy_119
sym_copy_118:
  %t430 = mul i64 %t353, 8
  %t431 = load i8**, i8*** @sym.data
  %t432 = bitcast i8** %t431 to i8*
  call i8* @memcpy(i8* %t427, i8* %t432, i64 %t430)
  call void @free(i8* %t432)
  br label %sym_after_copy_119
sym_after_copy_119:
  store i8** %t428, i8*** @sym.data
  store i64 %t425, i64* @sym.cap
  br label %sym_store_117
sym_store_117:
  %t433 = load i8**, i8*** @sym.data
  %t434 = getelementptr inbounds i8*, i8** %t433, i64 %t353
  store i8* %t351, i8** %t434
  %t435 = add i64 %t353, 1
  store i64 %t435, i64* @sym.len
  %t436 = load i64*, i64** @sym.tbl.ids
  %t437 = getelementptr inbounds i64, i64* %t436, i64 %t420
  store i64 %t353, i64* %t437
  br label %sym_done_115
sym_done_115:
  %t438 = phi i64 [ %t419, %sym_found_113 ], [ %t353, %sym_store_117 ]
  call i32 @ReleaseSemaphore(i8* %t352, i32 1, i32* null)
  store i64 %t438, i64* %t346
  %t439 = load i64, i64* %t346
  %t440 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t440, i64 %t439)
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


@par.pool.job_fn = global [64 x i32 (i8*)*] zeroinitializer
@par.pool.job_arg = global [64 x i8*] zeroinitializer
@par.pool.start_sem = global [64 x i8*] zeroinitializer
@par.pool.done_sem = global [64 x i8*] zeroinitializer
@par.pool.tid = global [64 x i32] zeroinitializer
@par.pool.inited = global i1 false
@par.pool.num_workers = global i32 0
@par.pool.sysinfo_buf = global [48 x i8] zeroinitializer
@par.pool.init_i = global i32 0
@par.pool.env_name = private unnamed_addr constant [13 x i8] c"STAR_WORKERS\00"
@par.pool.serial_lock = global i8* null
@par.pool.serial_owner = global i32 -1

define i32 @par.pool.worker_main(i8* %idx_arg) {
entry:
  %t169 = ptrtoint i8* %idx_arg to i64
  %t170 = trunc i64 %t169 to i32
  %t171 = call i32 @GetCurrentThreadId()
  %t172 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t170
  store i32 %t171, i32* %t172
  br label %loop
loop:
  %t173 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t170
  %t174 = load i8*, i8** %t173
  %t175 = call i32 @WaitForSingleObject(i8* %t174, i32 -1)
  %t176 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t170
  %t177 = load i32 (i8*)*, i32 (i8*)** %t176
  %t178 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t170
  %t179 = load i8*, i8** %t178
  %t180 = call i32 %t177(i8* %t179)
  %t181 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t170
  %t182 = load i8*, i8** %t181
  %t183 = call i32 @ReleaseSemaphore(i8* %t182, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t184 = load i1, i1* @par.pool.inited
  br i1 %t184, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t185 = getelementptr inbounds [13 x i8], [13 x i8]* @par.pool.env_name, i64 0, i64 0
  %t186 = call i8* @getenv(i8* %t185)
  %t187 = icmp eq i8* %t186, null
  br i1 %t187, label %par_pool_detect, label %par_pool_override
par_pool_override:
  %t188 = call i32 @atoi(i8* %t186)
  br label %par_pool_clamp
par_pool_detect:
  %t189 = getelementptr inbounds [48 x i8], [48 x i8]* @par.pool.sysinfo_buf, i64 0, i64 0
  call void @GetSystemInfo(i8* %t189)
  %t190 = getelementptr inbounds [48 x i8], [48 x i8]* @par.pool.sysinfo_buf, i64 0, i64 32
  %t191 = bitcast i8* %t190 to i32*
  %t192 = load i32, i32* %t191
  br label %par_pool_clamp
par_pool_clamp:
  %t193 = phi i32 [ %t188, %par_pool_override ], [ %t192, %par_pool_detect ]
  %t194 = icmp slt i32 %t193, 4
  %t195 = select i1 %t194, i32 4, i32 %t193
  %t196 = icmp sgt i32 %t195, 64
  %t197 = select i1 %t196, i32 64, i32 %t195
  store i32 %t197, i32* @par.pool.num_workers
  %t198 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t198, i8** @par.pool.serial_lock
  store i32 0, i32* @par.pool.init_i
  br label %par_pool_thread_cond
par_pool_thread_cond:
  %t199 = load i32, i32* @par.pool.init_i
  %t200 = icmp slt i32 %t199, %t197
  br i1 %t200, label %par_pool_thread_body, label %par_pool_init_done
par_pool_thread_body:
  %t201 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t202 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t199
  store i8* %t201, i8** %t202
  %t203 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t204 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t199
  store i8* %t203, i8** %t204
  %t205 = sext i32 %t199 to i64
  %t206 = inttoptr i64 %t205 to i8*
  %t207 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* %t206, i32 0, i32* null)
  %t208 = add i32 %t199, 1
  store i32 %t208, i32* @par.pool.init_i
  br label %par_pool_thread_cond
par_pool_init_done:
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_70(i8* %argp) {
entry:
  %t278 = alloca i64
  %t270 = bitcast i8* %argp to { i64, i64, i32* }*
  %t271 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t270, i32 0, i32 0
  %t272 = load i64, i64* %t271
  %t273 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t270, i32 0, i32 1
  %t274 = load i64, i64* %t273
  %t275 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t270, i32 0, i32 2
  %t276 = load i32*, i32** %t275
  %t277 = load %Entity*, %Entity** @arena.Entities.data
  store i64 %t272, i64* %t278
  br label %par_cond_71
par_cond_71:
  %t279 = load i64, i64* %t278
  %t280 = icmp slt i64 %t279, %t274
  br i1 %t280, label %par_body_72, label %par_end_75
par_body_72:
  %t281 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t279
  %t282 = load i64, i64* %t281
  %t283 = and i64 %t282, 1
  %t284 = icmp eq i64 %t283, 1
  br i1 %t284, label %par_live_73, label %par_incr_74
par_live_73:
  %t285 = getelementptr inbounds %Entity, %Entity* %t277, i64 %t279
  %t286 = getelementptr inbounds %Entity, %Entity* %t285, i32 0, i32 0
  %t287 = load i64, i64* %t286
  %t288 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t288, i64 %t287)
  br label %par_incr_74
par_incr_74:
  %t289 = add i64 %t279, 1
  store i64 %t289, i64* %t278
  br label %par_cond_71
par_end_75:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [141 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.1 = private unnamed_addr constant [6 x i8] c"tag%d\00"
@.str.2 = private unnamed_addr constant [6 x i8] c"%lld\0A\00"
@.str.3 = private unnamed_addr constant [6 x i8] c"tag%d\00"
@.str.4 = private unnamed_addr constant [14 x i8] c"check = %lld\0A\00"
