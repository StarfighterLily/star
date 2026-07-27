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

%Enemy = type { i32 }
%Particle = type { i32 }
%Enemies = type { %Enemy*, i64 }
@arena.Enemies.data = global %Enemy* null
@arena.Enemies.count = global i64 0
@arena.Enemies.gen = global [1024 x i64] zeroinitializer
@arena.Enemies.free = global [1024 x i64] zeroinitializer
@arena.Enemies.free_top = global i64 0
@arena.Enemies.warned = global i1 0

%Particles = type { %Particle*, i64 }
@arena.Particles.data = global %Particle* null
@arena.Particles.count = global i64 0
@arena.Particles.gen = global [1024 x i64] zeroinitializer
@arena.Particles.free = global [1024 x i64] zeroinitializer
@arena.Particles.free_top = global i64 0
@arena.Particles.warned = global i1 0

%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define i32 @sys.UpdateEnemies(i8* %_unused) {
entry:
  %t62 = alloca i32
  %t63 = alloca i32
  %t73 = alloca [64 x { i64, i64 }]
  %t74 = alloca i32
  %t94 = alloca i32
  %t106 = alloca { i64, i64 }
  call void @par.pool.ensure_init()
  %t59 = load i32, i32* @par.pool.num_workers
  %t60 = sext i32 %t59 to i64
  %t61 = call i32 @GetCurrentThreadId()
  store i32 -1, i32* %t62
  store i32 0, i32* %t63
  br label %par_reentry_cond_6
par_reentry_cond_6:
  %t64 = load i32, i32* %t63
  %t65 = icmp slt i32 %t64, %t59
  br i1 %t65, label %par_reentry_body_7, label %par_reentry_end_10
par_reentry_body_7:
  %t66 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t64
  %t67 = load i32, i32* %t66
  %t68 = icmp eq i32 %t61, %t67
  br i1 %t68, label %par_reentry_match_8, label %par_reentry_step_9
par_reentry_match_8:
  store i32 %t64, i32* %t62
  br label %par_reentry_step_9
par_reentry_step_9:
  %t69 = add i32 %t64, 1
  store i32 %t69, i32* %t63
  br label %par_reentry_cond_6
par_reentry_end_10:
  %t70 = load i32, i32* %t62
  %t71 = icmp sge i32 %t70, 0
  br i1 %t71, label %par_serial_12, label %par_pooled_11
par_pooled_11:
  %t72 = load i64, i64* @arena.Enemies.count
  store i32 0, i32* %t74
  br label %par_fanout_cond_17
par_fanout_cond_17:
  %t75 = load i32, i32* %t74
  %t76 = icmp slt i32 %t75, %t59
  br i1 %t76, label %par_fanout_body_18, label %par_fanout_end_20
par_fanout_body_18:
  %t77 = sext i32 %t75 to i64
  %t78 = mul i64 %t72, %t77
  %t79 = sdiv i64 %t78, %t60
  %t80 = add i32 %t75, 1
  %t81 = sext i32 %t80 to i64
  %t82 = mul i64 %t72, %t81
  %t83 = sdiv i64 %t82, %t60
  %t84 = getelementptr inbounds [64 x { i64, i64 }], [64 x { i64, i64 }]* %t73, i32 0, i32 %t75
  %t85 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t84, i32 0, i32 0
  store i64 %t79, i64* %t85
  %t86 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t84, i32 0, i32 1
  store i64 %t83, i64* %t86
  %t87 = bitcast { i64, i64 }* %t84 to i8*
  %t88 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t75
  store i8* %t87, i8** %t88
  %t89 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t75
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t89
  %t90 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t75
  %t91 = load i8*, i8** %t90
  %t92 = call i32 @ReleaseSemaphore(i8* %t91, i32 1, i32* null)
  br label %par_fanout_step_19
par_fanout_step_19:
  %t93 = add i32 %t75, 1
  store i32 %t93, i32* %t74
  br label %par_fanout_cond_17
par_fanout_end_20:
  store i32 0, i32* %t94
  br label %par_join_wait_cond_21
par_join_wait_cond_21:
  %t95 = load i32, i32* %t94
  %t96 = icmp slt i32 %t95, %t59
  br i1 %t96, label %par_join_wait_body_22, label %par_join_wait_end_24
par_join_wait_body_22:
  %t97 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t95
  %t98 = load i8*, i8** %t97
  %t99 = call i32 @WaitForSingleObject(i8* %t98, i32 -1)
  br label %par_join_wait_step_23
par_join_wait_step_23:
  %t100 = add i32 %t95, 1
  store i32 %t100, i32* %t94
  br label %par_join_wait_cond_21
par_join_wait_end_24:
  br label %par_join_16
par_serial_12:
  %t101 = load i32, i32* @par.pool.serial_owner
  %t102 = icmp eq i32 %t101, %t70
  br i1 %t102, label %par_run_14, label %par_acquire_13
par_acquire_13:
  %t103 = load i8*, i8** @par.pool.serial_lock
  %t104 = call i32 @WaitForSingleObject(i8* %t103, i32 -1)
  store i32 %t70, i32* @par.pool.serial_owner
  br label %par_run_14
par_run_14:
  %t105 = load i64, i64* @arena.Enemies.count
  %t107 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t106, i32 0, i32 0
  store i64 0, i64* %t107
  %t108 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t106, i32 0, i32 1
  store i64 %t105, i64* %t108
  %t109 = bitcast { i64, i64 }* %t106 to i8*
  %t110 = call i32 @par_worker_0(i8* %t109)
  br i1 %t102, label %par_join_16, label %par_release_15
par_release_15:
  store i32 -1, i32* @par.pool.serial_owner
  %t111 = load i8*, i8** @par.pool.serial_lock
  %t112 = call i32 @ReleaseSemaphore(i8* %t111, i32 1, i32* null)
  br label %par_join_16
par_join_16:
  ret i32 0
}

define i32 @sys.UpdateParticles(i8* %_unused) {
entry:
  %t22 = alloca i32
  %t23 = alloca i32
  %t33 = alloca [64 x { i64, i64 }]
  %t34 = alloca i32
  %t54 = alloca i32
  %t66 = alloca { i64, i64 }
  call void @par.pool.ensure_init()
  %t19 = load i32, i32* @par.pool.num_workers
  %t20 = sext i32 %t19 to i64
  %t21 = call i32 @GetCurrentThreadId()
  store i32 -1, i32* %t22
  store i32 0, i32* %t23
  br label %par_reentry_cond_31
par_reentry_cond_31:
  %t24 = load i32, i32* %t23
  %t25 = icmp slt i32 %t24, %t19
  br i1 %t25, label %par_reentry_body_32, label %par_reentry_end_35
par_reentry_body_32:
  %t26 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t24
  %t27 = load i32, i32* %t26
  %t28 = icmp eq i32 %t21, %t27
  br i1 %t28, label %par_reentry_match_33, label %par_reentry_step_34
par_reentry_match_33:
  store i32 %t24, i32* %t22
  br label %par_reentry_step_34
par_reentry_step_34:
  %t29 = add i32 %t24, 1
  store i32 %t29, i32* %t23
  br label %par_reentry_cond_31
par_reentry_end_35:
  %t30 = load i32, i32* %t22
  %t31 = icmp sge i32 %t30, 0
  br i1 %t31, label %par_serial_37, label %par_pooled_36
par_pooled_36:
  %t32 = load i64, i64* @arena.Particles.count
  store i32 0, i32* %t34
  br label %par_fanout_cond_42
par_fanout_cond_42:
  %t35 = load i32, i32* %t34
  %t36 = icmp slt i32 %t35, %t19
  br i1 %t36, label %par_fanout_body_43, label %par_fanout_end_45
par_fanout_body_43:
  %t37 = sext i32 %t35 to i64
  %t38 = mul i64 %t32, %t37
  %t39 = sdiv i64 %t38, %t20
  %t40 = add i32 %t35, 1
  %t41 = sext i32 %t40 to i64
  %t42 = mul i64 %t32, %t41
  %t43 = sdiv i64 %t42, %t20
  %t44 = getelementptr inbounds [64 x { i64, i64 }], [64 x { i64, i64 }]* %t33, i32 0, i32 %t35
  %t45 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t44, i32 0, i32 0
  store i64 %t39, i64* %t45
  %t46 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t44, i32 0, i32 1
  store i64 %t43, i64* %t46
  %t47 = bitcast { i64, i64 }* %t44 to i8*
  %t48 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t35
  store i8* %t47, i8** %t48
  %t49 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t35
  store i32 (i8*)* @par_worker_25, i32 (i8*)** %t49
  %t50 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t35
  %t51 = load i8*, i8** %t50
  %t52 = call i32 @ReleaseSemaphore(i8* %t51, i32 1, i32* null)
  br label %par_fanout_step_44
par_fanout_step_44:
  %t53 = add i32 %t35, 1
  store i32 %t53, i32* %t34
  br label %par_fanout_cond_42
par_fanout_end_45:
  store i32 0, i32* %t54
  br label %par_join_wait_cond_46
par_join_wait_cond_46:
  %t55 = load i32, i32* %t54
  %t56 = icmp slt i32 %t55, %t19
  br i1 %t56, label %par_join_wait_body_47, label %par_join_wait_end_49
par_join_wait_body_47:
  %t57 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t55
  %t58 = load i8*, i8** %t57
  %t59 = call i32 @WaitForSingleObject(i8* %t58, i32 -1)
  br label %par_join_wait_step_48
par_join_wait_step_48:
  %t60 = add i32 %t55, 1
  store i32 %t60, i32* %t54
  br label %par_join_wait_cond_46
par_join_wait_end_49:
  br label %par_join_41
par_serial_37:
  %t61 = load i32, i32* @par.pool.serial_owner
  %t62 = icmp eq i32 %t61, %t30
  br i1 %t62, label %par_run_39, label %par_acquire_38
par_acquire_38:
  %t63 = load i8*, i8** @par.pool.serial_lock
  %t64 = call i32 @WaitForSingleObject(i8* %t63, i32 -1)
  store i32 %t30, i32* @par.pool.serial_owner
  br label %par_run_39
par_run_39:
  %t65 = load i64, i64* @arena.Particles.count
  %t67 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t66, i32 0, i32 0
  store i64 0, i64* %t67
  %t68 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t66, i32 0, i32 1
  store i64 %t65, i64* %t68
  %t69 = bitcast { i64, i64 }* %t66 to i8*
  %t70 = call i32 @par_worker_25(i8* %t69)
  br i1 %t62, label %par_join_41, label %par_release_40
par_release_40:
  store i32 -1, i32* @par.pool.serial_owner
  %t71 = load i8*, i8** @par.pool.serial_lock
  %t72 = call i32 @ReleaseSemaphore(i8* %t71, i32 1, i32* null)
  br label %par_join_41
par_join_41:
  ret i32 0
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t21 = alloca %Enemy
  %t49 = alloca %Enemy
  %t77 = alloca %Enemy
  %t105 = alloca %Particle
  %t133 = alloca %Particle
  %t179 = alloca i32
  %t180 = alloca i32
  %t190 = alloca [64 x { i64, i64 }]
  %t191 = alloca i32
  %t211 = alloca i32
  %t223 = alloca { i64, i64 }
  %t251 = alloca i32
  %t252 = alloca i32
  %t262 = alloca [64 x { i64, i64 }]
  %t263 = alloca i32
  %t283 = alloca i32
  %t295 = alloca { i64, i64 }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t2 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t3 = icmp eq %Enemy* %t2, null
  br i1 %t3, label %spawn_init_50, label %spawn_ready_51
spawn_init_50:
  %t4 = getelementptr %Enemy, %Enemy* null, i32 1
  %t5 = ptrtoint %Enemy* %t4 to i64
  %t6 = mul i64 %t5, 1024
  %t7 = call i8* @malloc(i64 %t6)
  %t8 = bitcast i8* %t7 to %Enemy*
  store %Enemy* %t8, %Enemy** @arena.Enemies.data
  br label %spawn_ready_51
spawn_ready_51:
  %t9 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t10 = load i64, i64* @arena.Enemies.free_top
  %t11 = icmp sgt i64 %t10, 0
  br i1 %t11, label %spawn_reuse_52, label %spawn_grow_53
spawn_reuse_52:
  %t12 = sub i64 %t10, 1
  store i64 %t12, i64* @arena.Enemies.free_top
  %t13 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t12
  %t14 = load i64, i64* %t13
  br label %spawn_store_54
spawn_grow_53:
  %t15 = load i64, i64* @arena.Enemies.count
  %t16 = icmp slt i64 %t15, 1024
  br i1 %t16, label %spawn_grow_ok_56, label %spawn_capacity_warn_57
spawn_capacity_warn_57:
  %t17 = load i1, i1* @arena.Enemies.warned
  br i1 %t17, label %spawn_end_55, label %spawn_warn_print_58
spawn_warn_print_58:
  store i1 1, i1* @arena.Enemies.warned
  %t18 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t18)
  br label %spawn_end_55
spawn_grow_ok_56:
  %t19 = add i64 %t15, 1
  store i64 %t19, i64* @arena.Enemies.count
  br label %spawn_store_54
spawn_store_54:
  %t20 = phi i64 [ %t14, %spawn_reuse_52 ], [ %t15, %spawn_grow_ok_56 ]
  %t22 = getelementptr inbounds %Enemy, %Enemy* %t21, i32 0, i32 0
  store i32 10, i32* %t22
  %t23 = load %Enemy, %Enemy* %t21
  %t24 = getelementptr inbounds %Enemy, %Enemy* %t9, i64 %t20
  store %Enemy %t23, %Enemy* %t24
  %t25 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t20
  %t26 = load i64, i64* %t25
  %t27 = add i64 %t26, 1
  store i64 %t27, i64* %t25
  %t28 = trunc i64 %t20 to i32
  br label %spawn_end_55
spawn_end_55:
  %t29 = phi i32 [ %t28, %spawn_store_54 ], [ -1, %spawn_capacity_warn_57 ], [ -1, %spawn_warn_print_58 ]
  %t30 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t31 = icmp eq %Enemy* %t30, null
  br i1 %t31, label %spawn_init_59, label %spawn_ready_60
spawn_init_59:
  %t32 = getelementptr %Enemy, %Enemy* null, i32 1
  %t33 = ptrtoint %Enemy* %t32 to i64
  %t34 = mul i64 %t33, 1024
  %t35 = call i8* @malloc(i64 %t34)
  %t36 = bitcast i8* %t35 to %Enemy*
  store %Enemy* %t36, %Enemy** @arena.Enemies.data
  br label %spawn_ready_60
spawn_ready_60:
  %t37 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t38 = load i64, i64* @arena.Enemies.free_top
  %t39 = icmp sgt i64 %t38, 0
  br i1 %t39, label %spawn_reuse_61, label %spawn_grow_62
spawn_reuse_61:
  %t40 = sub i64 %t38, 1
  store i64 %t40, i64* @arena.Enemies.free_top
  %t41 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t40
  %t42 = load i64, i64* %t41
  br label %spawn_store_63
spawn_grow_62:
  %t43 = load i64, i64* @arena.Enemies.count
  %t44 = icmp slt i64 %t43, 1024
  br i1 %t44, label %spawn_grow_ok_65, label %spawn_capacity_warn_66
spawn_capacity_warn_66:
  %t45 = load i1, i1* @arena.Enemies.warned
  br i1 %t45, label %spawn_end_64, label %spawn_warn_print_67
spawn_warn_print_67:
  store i1 1, i1* @arena.Enemies.warned
  %t46 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t46)
  br label %spawn_end_64
spawn_grow_ok_65:
  %t47 = add i64 %t43, 1
  store i64 %t47, i64* @arena.Enemies.count
  br label %spawn_store_63
spawn_store_63:
  %t48 = phi i64 [ %t42, %spawn_reuse_61 ], [ %t43, %spawn_grow_ok_65 ]
  %t50 = getelementptr inbounds %Enemy, %Enemy* %t49, i32 0, i32 0
  store i32 20, i32* %t50
  %t51 = load %Enemy, %Enemy* %t49
  %t52 = getelementptr inbounds %Enemy, %Enemy* %t37, i64 %t48
  store %Enemy %t51, %Enemy* %t52
  %t53 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t48
  %t54 = load i64, i64* %t53
  %t55 = add i64 %t54, 1
  store i64 %t55, i64* %t53
  %t56 = trunc i64 %t48 to i32
  br label %spawn_end_64
spawn_end_64:
  %t57 = phi i32 [ %t56, %spawn_store_63 ], [ -1, %spawn_capacity_warn_66 ], [ -1, %spawn_warn_print_67 ]
  %t58 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t59 = icmp eq %Enemy* %t58, null
  br i1 %t59, label %spawn_init_68, label %spawn_ready_69
spawn_init_68:
  %t60 = getelementptr %Enemy, %Enemy* null, i32 1
  %t61 = ptrtoint %Enemy* %t60 to i64
  %t62 = mul i64 %t61, 1024
  %t63 = call i8* @malloc(i64 %t62)
  %t64 = bitcast i8* %t63 to %Enemy*
  store %Enemy* %t64, %Enemy** @arena.Enemies.data
  br label %spawn_ready_69
spawn_ready_69:
  %t65 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t66 = load i64, i64* @arena.Enemies.free_top
  %t67 = icmp sgt i64 %t66, 0
  br i1 %t67, label %spawn_reuse_70, label %spawn_grow_71
spawn_reuse_70:
  %t68 = sub i64 %t66, 1
  store i64 %t68, i64* @arena.Enemies.free_top
  %t69 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t68
  %t70 = load i64, i64* %t69
  br label %spawn_store_72
spawn_grow_71:
  %t71 = load i64, i64* @arena.Enemies.count
  %t72 = icmp slt i64 %t71, 1024
  br i1 %t72, label %spawn_grow_ok_74, label %spawn_capacity_warn_75
spawn_capacity_warn_75:
  %t73 = load i1, i1* @arena.Enemies.warned
  br i1 %t73, label %spawn_end_73, label %spawn_warn_print_76
spawn_warn_print_76:
  store i1 1, i1* @arena.Enemies.warned
  %t74 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t74)
  br label %spawn_end_73
spawn_grow_ok_74:
  %t75 = add i64 %t71, 1
  store i64 %t75, i64* @arena.Enemies.count
  br label %spawn_store_72
spawn_store_72:
  %t76 = phi i64 [ %t70, %spawn_reuse_70 ], [ %t71, %spawn_grow_ok_74 ]
  %t78 = getelementptr inbounds %Enemy, %Enemy* %t77, i32 0, i32 0
  store i32 30, i32* %t78
  %t79 = load %Enemy, %Enemy* %t77
  %t80 = getelementptr inbounds %Enemy, %Enemy* %t65, i64 %t76
  store %Enemy %t79, %Enemy* %t80
  %t81 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t76
  %t82 = load i64, i64* %t81
  %t83 = add i64 %t82, 1
  store i64 %t83, i64* %t81
  %t84 = trunc i64 %t76 to i32
  br label %spawn_end_73
spawn_end_73:
  %t85 = phi i32 [ %t84, %spawn_store_72 ], [ -1, %spawn_capacity_warn_75 ], [ -1, %spawn_warn_print_76 ]
  %t86 = load %Particle*, %Particle** @arena.Particles.data
  %t87 = icmp eq %Particle* %t86, null
  br i1 %t87, label %spawn_init_77, label %spawn_ready_78
spawn_init_77:
  %t88 = getelementptr %Particle, %Particle* null, i32 1
  %t89 = ptrtoint %Particle* %t88 to i64
  %t90 = mul i64 %t89, 1024
  %t91 = call i8* @malloc(i64 %t90)
  %t92 = bitcast i8* %t91 to %Particle*
  store %Particle* %t92, %Particle** @arena.Particles.data
  br label %spawn_ready_78
spawn_ready_78:
  %t93 = load %Particle*, %Particle** @arena.Particles.data
  %t94 = load i64, i64* @arena.Particles.free_top
  %t95 = icmp sgt i64 %t94, 0
  br i1 %t95, label %spawn_reuse_79, label %spawn_grow_80
spawn_reuse_79:
  %t96 = sub i64 %t94, 1
  store i64 %t96, i64* @arena.Particles.free_top
  %t97 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.free, i64 0, i64 %t96
  %t98 = load i64, i64* %t97
  br label %spawn_store_81
spawn_grow_80:
  %t99 = load i64, i64* @arena.Particles.count
  %t100 = icmp slt i64 %t99, 1024
  br i1 %t100, label %spawn_grow_ok_83, label %spawn_capacity_warn_84
spawn_capacity_warn_84:
  %t101 = load i1, i1* @arena.Particles.warned
  br i1 %t101, label %spawn_end_82, label %spawn_warn_print_85
spawn_warn_print_85:
  store i1 1, i1* @arena.Particles.warned
  %t102 = getelementptr inbounds [142 x i8], [142 x i8]* @.str.3, i64 0, i64 0
  call i32 @puts(i8* %t102)
  br label %spawn_end_82
spawn_grow_ok_83:
  %t103 = add i64 %t99, 1
  store i64 %t103, i64* @arena.Particles.count
  br label %spawn_store_81
spawn_store_81:
  %t104 = phi i64 [ %t98, %spawn_reuse_79 ], [ %t99, %spawn_grow_ok_83 ]
  %t106 = getelementptr inbounds %Particle, %Particle* %t105, i32 0, i32 0
  store i32 5, i32* %t106
  %t107 = load %Particle, %Particle* %t105
  %t108 = getelementptr inbounds %Particle, %Particle* %t93, i64 %t104
  store %Particle %t107, %Particle* %t108
  %t109 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.gen, i64 0, i64 %t104
  %t110 = load i64, i64* %t109
  %t111 = add i64 %t110, 1
  store i64 %t111, i64* %t109
  %t112 = trunc i64 %t104 to i32
  br label %spawn_end_82
spawn_end_82:
  %t113 = phi i32 [ %t112, %spawn_store_81 ], [ -1, %spawn_capacity_warn_84 ], [ -1, %spawn_warn_print_85 ]
  %t114 = load %Particle*, %Particle** @arena.Particles.data
  %t115 = icmp eq %Particle* %t114, null
  br i1 %t115, label %spawn_init_86, label %spawn_ready_87
spawn_init_86:
  %t116 = getelementptr %Particle, %Particle* null, i32 1
  %t117 = ptrtoint %Particle* %t116 to i64
  %t118 = mul i64 %t117, 1024
  %t119 = call i8* @malloc(i64 %t118)
  %t120 = bitcast i8* %t119 to %Particle*
  store %Particle* %t120, %Particle** @arena.Particles.data
  br label %spawn_ready_87
spawn_ready_87:
  %t121 = load %Particle*, %Particle** @arena.Particles.data
  %t122 = load i64, i64* @arena.Particles.free_top
  %t123 = icmp sgt i64 %t122, 0
  br i1 %t123, label %spawn_reuse_88, label %spawn_grow_89
spawn_reuse_88:
  %t124 = sub i64 %t122, 1
  store i64 %t124, i64* @arena.Particles.free_top
  %t125 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.free, i64 0, i64 %t124
  %t126 = load i64, i64* %t125
  br label %spawn_store_90
spawn_grow_89:
  %t127 = load i64, i64* @arena.Particles.count
  %t128 = icmp slt i64 %t127, 1024
  br i1 %t128, label %spawn_grow_ok_92, label %spawn_capacity_warn_93
spawn_capacity_warn_93:
  %t129 = load i1, i1* @arena.Particles.warned
  br i1 %t129, label %spawn_end_91, label %spawn_warn_print_94
spawn_warn_print_94:
  store i1 1, i1* @arena.Particles.warned
  %t130 = getelementptr inbounds [142 x i8], [142 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t130)
  br label %spawn_end_91
spawn_grow_ok_92:
  %t131 = add i64 %t127, 1
  store i64 %t131, i64* @arena.Particles.count
  br label %spawn_store_90
spawn_store_90:
  %t132 = phi i64 [ %t126, %spawn_reuse_88 ], [ %t127, %spawn_grow_ok_92 ]
  %t134 = getelementptr inbounds %Particle, %Particle* %t133, i32 0, i32 0
  store i32 8, i32* %t134
  %t135 = load %Particle, %Particle* %t133
  %t136 = getelementptr inbounds %Particle, %Particle* %t121, i64 %t132
  store %Particle %t135, %Particle* %t136
  %t137 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.gen, i64 0, i64 %t132
  %t138 = load i64, i64* %t137
  %t139 = add i64 %t138, 1
  store i64 %t139, i64* %t137
  %t140 = trunc i64 %t132 to i32
  br label %spawn_end_91
spawn_end_91:
  %t141 = phi i32 [ %t140, %spawn_store_90 ], [ -1, %spawn_capacity_warn_93 ], [ -1, %spawn_warn_print_94 ]
  call void @par.pool.ensure_init()
  %t142 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @sys.UpdateEnemies, i32 (i8*)** %t142
  %t143 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* null, i8** %t143
  %t144 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t145 = load i8*, i8** %t144
  %t146 = call i32 @ReleaseSemaphore(i8* %t145, i32 1, i32* null)
  %t147 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @sys.UpdateParticles, i32 (i8*)** %t147
  %t148 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* null, i8** %t148
  %t149 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t150 = load i8*, i8** %t149
  %t151 = call i32 @ReleaseSemaphore(i8* %t150, i32 1, i32* null)
  %t152 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t153 = load i8*, i8** %t152
  %t154 = call i32 @WaitForSingleObject(i8* %t153, i32 -1)
  %t155 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t156 = load i8*, i8** %t155
  %t157 = call i32 @WaitForSingleObject(i8* %t156, i32 -1)
  call void @par.pool.ensure_init()
  %t176 = load i32, i32* @par.pool.num_workers
  %t177 = sext i32 %t176 to i64
  %t178 = call i32 @GetCurrentThreadId()
  store i32 -1, i32* %t179
  store i32 0, i32* %t180
  br label %par_reentry_cond_101
par_reentry_cond_101:
  %t181 = load i32, i32* %t180
  %t182 = icmp slt i32 %t181, %t176
  br i1 %t182, label %par_reentry_body_102, label %par_reentry_end_105
par_reentry_body_102:
  %t183 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t181
  %t184 = load i32, i32* %t183
  %t185 = icmp eq i32 %t178, %t184
  br i1 %t185, label %par_reentry_match_103, label %par_reentry_step_104
par_reentry_match_103:
  store i32 %t181, i32* %t179
  br label %par_reentry_step_104
par_reentry_step_104:
  %t186 = add i32 %t181, 1
  store i32 %t186, i32* %t180
  br label %par_reentry_cond_101
par_reentry_end_105:
  %t187 = load i32, i32* %t179
  %t188 = icmp sge i32 %t187, 0
  br i1 %t188, label %par_serial_107, label %par_pooled_106
par_pooled_106:
  %t189 = load i64, i64* @arena.Enemies.count
  store i32 0, i32* %t191
  br label %par_fanout_cond_112
par_fanout_cond_112:
  %t192 = load i32, i32* %t191
  %t193 = icmp slt i32 %t192, %t176
  br i1 %t193, label %par_fanout_body_113, label %par_fanout_end_115
par_fanout_body_113:
  %t194 = sext i32 %t192 to i64
  %t195 = mul i64 %t189, %t194
  %t196 = sdiv i64 %t195, %t177
  %t197 = add i32 %t192, 1
  %t198 = sext i32 %t197 to i64
  %t199 = mul i64 %t189, %t198
  %t200 = sdiv i64 %t199, %t177
  %t201 = getelementptr inbounds [64 x { i64, i64 }], [64 x { i64, i64 }]* %t190, i32 0, i32 %t192
  %t202 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t201, i32 0, i32 0
  store i64 %t196, i64* %t202
  %t203 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t201, i32 0, i32 1
  store i64 %t200, i64* %t203
  %t204 = bitcast { i64, i64 }* %t201 to i8*
  %t205 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t192
  store i8* %t204, i8** %t205
  %t206 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t192
  store i32 (i8*)* @par_worker_95, i32 (i8*)** %t206
  %t207 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t192
  %t208 = load i8*, i8** %t207
  %t209 = call i32 @ReleaseSemaphore(i8* %t208, i32 1, i32* null)
  br label %par_fanout_step_114
par_fanout_step_114:
  %t210 = add i32 %t192, 1
  store i32 %t210, i32* %t191
  br label %par_fanout_cond_112
par_fanout_end_115:
  store i32 0, i32* %t211
  br label %par_join_wait_cond_116
par_join_wait_cond_116:
  %t212 = load i32, i32* %t211
  %t213 = icmp slt i32 %t212, %t176
  br i1 %t213, label %par_join_wait_body_117, label %par_join_wait_end_119
par_join_wait_body_117:
  %t214 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t212
  %t215 = load i8*, i8** %t214
  %t216 = call i32 @WaitForSingleObject(i8* %t215, i32 -1)
  br label %par_join_wait_step_118
par_join_wait_step_118:
  %t217 = add i32 %t212, 1
  store i32 %t217, i32* %t211
  br label %par_join_wait_cond_116
par_join_wait_end_119:
  br label %par_join_111
par_serial_107:
  %t218 = load i32, i32* @par.pool.serial_owner
  %t219 = icmp eq i32 %t218, %t187
  br i1 %t219, label %par_run_109, label %par_acquire_108
par_acquire_108:
  %t220 = load i8*, i8** @par.pool.serial_lock
  %t221 = call i32 @WaitForSingleObject(i8* %t220, i32 -1)
  store i32 %t187, i32* @par.pool.serial_owner
  br label %par_run_109
par_run_109:
  %t222 = load i64, i64* @arena.Enemies.count
  %t224 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t223, i32 0, i32 0
  store i64 0, i64* %t224
  %t225 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t223, i32 0, i32 1
  store i64 %t222, i64* %t225
  %t226 = bitcast { i64, i64 }* %t223 to i8*
  %t227 = call i32 @par_worker_95(i8* %t226)
  br i1 %t219, label %par_join_111, label %par_release_110
par_release_110:
  store i32 -1, i32* @par.pool.serial_owner
  %t228 = load i8*, i8** @par.pool.serial_lock
  %t229 = call i32 @ReleaseSemaphore(i8* %t228, i32 1, i32* null)
  br label %par_join_111
par_join_111:
  call void @par.pool.ensure_init()
  %t248 = load i32, i32* @par.pool.num_workers
  %t249 = sext i32 %t248 to i64
  %t250 = call i32 @GetCurrentThreadId()
  store i32 -1, i32* %t251
  store i32 0, i32* %t252
  br label %par_reentry_cond_126
par_reentry_cond_126:
  %t253 = load i32, i32* %t252
  %t254 = icmp slt i32 %t253, %t248
  br i1 %t254, label %par_reentry_body_127, label %par_reentry_end_130
par_reentry_body_127:
  %t255 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t253
  %t256 = load i32, i32* %t255
  %t257 = icmp eq i32 %t250, %t256
  br i1 %t257, label %par_reentry_match_128, label %par_reentry_step_129
par_reentry_match_128:
  store i32 %t253, i32* %t251
  br label %par_reentry_step_129
par_reentry_step_129:
  %t258 = add i32 %t253, 1
  store i32 %t258, i32* %t252
  br label %par_reentry_cond_126
par_reentry_end_130:
  %t259 = load i32, i32* %t251
  %t260 = icmp sge i32 %t259, 0
  br i1 %t260, label %par_serial_132, label %par_pooled_131
par_pooled_131:
  %t261 = load i64, i64* @arena.Particles.count
  store i32 0, i32* %t263
  br label %par_fanout_cond_137
par_fanout_cond_137:
  %t264 = load i32, i32* %t263
  %t265 = icmp slt i32 %t264, %t248
  br i1 %t265, label %par_fanout_body_138, label %par_fanout_end_140
par_fanout_body_138:
  %t266 = sext i32 %t264 to i64
  %t267 = mul i64 %t261, %t266
  %t268 = sdiv i64 %t267, %t249
  %t269 = add i32 %t264, 1
  %t270 = sext i32 %t269 to i64
  %t271 = mul i64 %t261, %t270
  %t272 = sdiv i64 %t271, %t249
  %t273 = getelementptr inbounds [64 x { i64, i64 }], [64 x { i64, i64 }]* %t262, i32 0, i32 %t264
  %t274 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t273, i32 0, i32 0
  store i64 %t268, i64* %t274
  %t275 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t273, i32 0, i32 1
  store i64 %t272, i64* %t275
  %t276 = bitcast { i64, i64 }* %t273 to i8*
  %t277 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t264
  store i8* %t276, i8** %t277
  %t278 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t264
  store i32 (i8*)* @par_worker_120, i32 (i8*)** %t278
  %t279 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t264
  %t280 = load i8*, i8** %t279
  %t281 = call i32 @ReleaseSemaphore(i8* %t280, i32 1, i32* null)
  br label %par_fanout_step_139
par_fanout_step_139:
  %t282 = add i32 %t264, 1
  store i32 %t282, i32* %t263
  br label %par_fanout_cond_137
par_fanout_end_140:
  store i32 0, i32* %t283
  br label %par_join_wait_cond_141
par_join_wait_cond_141:
  %t284 = load i32, i32* %t283
  %t285 = icmp slt i32 %t284, %t248
  br i1 %t285, label %par_join_wait_body_142, label %par_join_wait_end_144
par_join_wait_body_142:
  %t286 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t284
  %t287 = load i8*, i8** %t286
  %t288 = call i32 @WaitForSingleObject(i8* %t287, i32 -1)
  br label %par_join_wait_step_143
par_join_wait_step_143:
  %t289 = add i32 %t284, 1
  store i32 %t289, i32* %t283
  br label %par_join_wait_cond_141
par_join_wait_end_144:
  br label %par_join_136
par_serial_132:
  %t290 = load i32, i32* @par.pool.serial_owner
  %t291 = icmp eq i32 %t290, %t259
  br i1 %t291, label %par_run_134, label %par_acquire_133
par_acquire_133:
  %t292 = load i8*, i8** @par.pool.serial_lock
  %t293 = call i32 @WaitForSingleObject(i8* %t292, i32 -1)
  store i32 %t259, i32* @par.pool.serial_owner
  br label %par_run_134
par_run_134:
  %t294 = load i64, i64* @arena.Particles.count
  %t296 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t295, i32 0, i32 0
  store i64 0, i64* %t296
  %t297 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t295, i32 0, i32 1
  store i64 %t294, i64* %t297
  %t298 = bitcast { i64, i64 }* %t295 to i8*
  %t299 = call i32 @par_worker_120(i8* %t298)
  br i1 %t291, label %par_join_136, label %par_release_135
par_release_135:
  store i32 -1, i32* @par.pool.serial_owner
  %t300 = load i8*, i8** @par.pool.serial_lock
  %t301 = call i32 @ReleaseSemaphore(i8* %t300, i32 1, i32* null)
  br label %par_join_136
par_join_136:
  %t302 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t302)
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_0(i8* %argp) {
entry:
  %t6 = alloca i64
  %t0 = bitcast i8* %argp to { i64, i64 }*
  %t1 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t0, i32 0, i32 0
  %t2 = load i64, i64* %t1
  %t3 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t0, i32 0, i32 1
  %t4 = load i64, i64* %t3
  %t5 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t2, i64* %t6
  br label %par_cond_1
par_cond_1:
  %t7 = load i64, i64* %t6
  %t8 = icmp slt i64 %t7, %t4
  br i1 %t8, label %par_body_2, label %par_end_5
par_body_2:
  %t9 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t7
  %t10 = load i64, i64* %t9
  %t11 = and i64 %t10, 1
  %t12 = icmp eq i64 %t11, 1
  br i1 %t12, label %par_live_3, label %par_incr_4
par_live_3:
  %t13 = getelementptr inbounds %Enemy, %Enemy* %t5, i64 %t7
  %t14 = getelementptr inbounds %Enemy, %Enemy* %t13, i32 0, i32 0
  %t15 = load i32, i32* %t14
  %t16 = sub i32 %t15, 1
  %t17 = getelementptr inbounds %Enemy, %Enemy* %t13, i32 0, i32 0
  store i32 %t16, i32* %t17
  br label %par_incr_4
par_incr_4:
  %t18 = add i64 %t7, 1
  store i64 %t18, i64* %t6
  br label %par_cond_1
par_end_5:
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
  %t19 = ptrtoint i8* %idx_arg to i64
  %t20 = trunc i64 %t19 to i32
  %t21 = call i32 @GetCurrentThreadId()
  %t22 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t20
  store i32 %t21, i32* %t22
  br label %loop
loop:
  %t23 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t20
  %t24 = load i8*, i8** %t23
  %t25 = call i32 @WaitForSingleObject(i8* %t24, i32 -1)
  %t26 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t20
  %t27 = load i32 (i8*)*, i32 (i8*)** %t26
  %t28 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t20
  %t29 = load i8*, i8** %t28
  %t30 = call i32 %t27(i8* %t29)
  %t31 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t20
  %t32 = load i8*, i8** %t31
  %t33 = call i32 @ReleaseSemaphore(i8* %t32, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t34 = load i1, i1* @par.pool.inited
  br i1 %t34, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t35 = getelementptr inbounds [13 x i8], [13 x i8]* @par.pool.env_name, i64 0, i64 0
  %t36 = call i8* @getenv(i8* %t35)
  %t37 = icmp eq i8* %t36, null
  br i1 %t37, label %par_pool_detect, label %par_pool_override
par_pool_override:
  %t38 = call i32 @atoi(i8* %t36)
  br label %par_pool_clamp
par_pool_detect:
  %t39 = getelementptr inbounds [48 x i8], [48 x i8]* @par.pool.sysinfo_buf, i64 0, i64 0
  call void @GetSystemInfo(i8* %t39)
  %t40 = getelementptr inbounds [48 x i8], [48 x i8]* @par.pool.sysinfo_buf, i64 0, i64 32
  %t41 = bitcast i8* %t40 to i32*
  %t42 = load i32, i32* %t41
  br label %par_pool_clamp
par_pool_clamp:
  %t43 = phi i32 [ %t38, %par_pool_override ], [ %t42, %par_pool_detect ]
  %t44 = icmp slt i32 %t43, 4
  %t45 = select i1 %t44, i32 4, i32 %t43
  %t46 = icmp sgt i32 %t45, 64
  %t47 = select i1 %t46, i32 64, i32 %t45
  store i32 %t47, i32* @par.pool.num_workers
  %t48 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t48, i8** @par.pool.serial_lock
  store i32 0, i32* @par.pool.init_i
  br label %par_pool_thread_cond
par_pool_thread_cond:
  %t49 = load i32, i32* @par.pool.init_i
  %t50 = icmp slt i32 %t49, %t47
  br i1 %t50, label %par_pool_thread_body, label %par_pool_init_done
par_pool_thread_body:
  %t51 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t52 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t49
  store i8* %t51, i8** %t52
  %t53 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t54 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t49
  store i8* %t53, i8** %t54
  %t55 = sext i32 %t49 to i64
  %t56 = inttoptr i64 %t55 to i8*
  %t57 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* %t56, i32 0, i32* null)
  %t58 = add i32 %t49, 1
  store i32 %t58, i32* @par.pool.init_i
  br label %par_pool_thread_cond
par_pool_init_done:
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_25(i8* %argp) {
entry:
  %t6 = alloca i64
  %t0 = bitcast i8* %argp to { i64, i64 }*
  %t1 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t0, i32 0, i32 0
  %t2 = load i64, i64* %t1
  %t3 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t0, i32 0, i32 1
  %t4 = load i64, i64* %t3
  %t5 = load %Particle*, %Particle** @arena.Particles.data
  store i64 %t2, i64* %t6
  br label %par_cond_26
par_cond_26:
  %t7 = load i64, i64* %t6
  %t8 = icmp slt i64 %t7, %t4
  br i1 %t8, label %par_body_27, label %par_end_30
par_body_27:
  %t9 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.gen, i64 0, i64 %t7
  %t10 = load i64, i64* %t9
  %t11 = and i64 %t10, 1
  %t12 = icmp eq i64 %t11, 1
  br i1 %t12, label %par_live_28, label %par_incr_29
par_live_28:
  %t13 = getelementptr inbounds %Particle, %Particle* %t5, i64 %t7
  %t14 = getelementptr inbounds %Particle, %Particle* %t13, i32 0, i32 0
  %t15 = load i32, i32* %t14
  %t16 = sub i32 %t15, 1
  %t17 = getelementptr inbounds %Particle, %Particle* %t13, i32 0, i32 0
  store i32 %t16, i32* %t17
  br label %par_incr_29
par_incr_29:
  %t18 = add i64 %t7, 1
  store i64 %t18, i64* %t6
  br label %par_cond_26
par_end_30:
  ret i32 0
}


define i32 @par_worker_95(i8* %argp) {
entry:
  %t164 = alloca i64
  %t158 = bitcast i8* %argp to { i64, i64 }*
  %t159 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t158, i32 0, i32 0
  %t160 = load i64, i64* %t159
  %t161 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t158, i32 0, i32 1
  %t162 = load i64, i64* %t161
  %t163 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t160, i64* %t164
  br label %par_cond_96
par_cond_96:
  %t165 = load i64, i64* %t164
  %t166 = icmp slt i64 %t165, %t162
  br i1 %t166, label %par_body_97, label %par_end_100
par_body_97:
  %t167 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t165
  %t168 = load i64, i64* %t167
  %t169 = and i64 %t168, 1
  %t170 = icmp eq i64 %t169, 1
  br i1 %t170, label %par_live_98, label %par_incr_99
par_live_98:
  %t171 = getelementptr inbounds %Enemy, %Enemy* %t163, i64 %t165
  %t172 = getelementptr inbounds %Enemy, %Enemy* %t171, i32 0, i32 0
  %t173 = load i32, i32* %t172
  %t174 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t174, i32 %t173)
  br label %par_incr_99
par_incr_99:
  %t175 = add i64 %t165, 1
  store i64 %t175, i64* %t164
  br label %par_cond_96
par_end_100:
  ret i32 0
}


define i32 @par_worker_120(i8* %argp) {
entry:
  %t236 = alloca i64
  %t230 = bitcast i8* %argp to { i64, i64 }*
  %t231 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t230, i32 0, i32 0
  %t232 = load i64, i64* %t231
  %t233 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t230, i32 0, i32 1
  %t234 = load i64, i64* %t233
  %t235 = load %Particle*, %Particle** @arena.Particles.data
  store i64 %t232, i64* %t236
  br label %par_cond_121
par_cond_121:
  %t237 = load i64, i64* %t236
  %t238 = icmp slt i64 %t237, %t234
  br i1 %t238, label %par_body_122, label %par_end_125
par_body_122:
  %t239 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.gen, i64 0, i64 %t237
  %t240 = load i64, i64* %t239
  %t241 = and i64 %t240, 1
  %t242 = icmp eq i64 %t241, 1
  br i1 %t242, label %par_live_123, label %par_incr_124
par_live_123:
  %t243 = getelementptr inbounds %Particle, %Particle* %t235, i64 %t237
  %t244 = getelementptr inbounds %Particle, %Particle* %t243, i32 0, i32 0
  %t245 = load i32, i32* %t244
  %t246 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t246, i32 %t245)
  br label %par_incr_124
par_incr_124:
  %t247 = add i64 %t237, 1
  store i64 %t247, i64* %t236
  br label %par_cond_121
par_end_125:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.1 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.2 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.3 = private unnamed_addr constant [142 x i8] c"star runtime warning: arena `Particles` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.4 = private unnamed_addr constant [142 x i8] c"star runtime warning: arena `Particles` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.5 = private unnamed_addr constant [14 x i8] c"enemy hp: %d\0A\00"
@.str.6 = private unnamed_addr constant [19 x i8] c"particle life: %d\0A\00"
@.str.7 = private unnamed_addr constant [15 x i8] c"parallel done\0A\00"
