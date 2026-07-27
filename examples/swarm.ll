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
%Enemies = type { %Enemy*, i64 }
@arena.Enemies.data = global %Enemy* null
@arena.Enemies.count = global i64 0
@arena.Enemies.gen = global [1024 x i64] zeroinitializer
@arena.Enemies.free = global [1024 x i64] zeroinitializer
@arena.Enemies.free_top = global i64 0
@arena.Enemies.warned = global i1 0

%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t64 = alloca i32
  %t65 = alloca i32
  %t75 = alloca [64 x { i64, i64 }]
  %t76 = alloca i32
  %t96 = alloca i32
  %t108 = alloca { i64, i64 }
  %t134 = alloca i32
  %t135 = alloca i32
  %t145 = alloca [64 x { i64, i64 }]
  %t146 = alloca i32
  %t166 = alloca i32
  %t178 = alloca { i64, i64 }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  call void @par.pool.ensure_init()
  %t61 = load i32, i32* @par.pool.num_workers
  %t62 = sext i32 %t61 to i64
  %t63 = call i32 @GetCurrentThreadId()
  store i32 -1, i32* %t64
  store i32 0, i32* %t65
  br label %par_reentry_cond_6
par_reentry_cond_6:
  %t66 = load i32, i32* %t65
  %t67 = icmp slt i32 %t66, %t61
  br i1 %t67, label %par_reentry_body_7, label %par_reentry_end_10
par_reentry_body_7:
  %t68 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t66
  %t69 = load i32, i32* %t68
  %t70 = icmp eq i32 %t63, %t69
  br i1 %t70, label %par_reentry_match_8, label %par_reentry_step_9
par_reentry_match_8:
  store i32 %t66, i32* %t64
  br label %par_reentry_step_9
par_reentry_step_9:
  %t71 = add i32 %t66, 1
  store i32 %t71, i32* %t65
  br label %par_reentry_cond_6
par_reentry_end_10:
  %t72 = load i32, i32* %t64
  %t73 = icmp sge i32 %t72, 0
  br i1 %t73, label %par_serial_12, label %par_pooled_11
par_pooled_11:
  %t74 = load i64, i64* @arena.Enemies.count
  store i32 0, i32* %t76
  br label %par_fanout_cond_17
par_fanout_cond_17:
  %t77 = load i32, i32* %t76
  %t78 = icmp slt i32 %t77, %t61
  br i1 %t78, label %par_fanout_body_18, label %par_fanout_end_20
par_fanout_body_18:
  %t79 = sext i32 %t77 to i64
  %t80 = mul i64 %t74, %t79
  %t81 = sdiv i64 %t80, %t62
  %t82 = add i32 %t77, 1
  %t83 = sext i32 %t82 to i64
  %t84 = mul i64 %t74, %t83
  %t85 = sdiv i64 %t84, %t62
  %t86 = getelementptr inbounds [64 x { i64, i64 }], [64 x { i64, i64 }]* %t75, i32 0, i32 %t77
  %t87 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t86, i32 0, i32 0
  store i64 %t81, i64* %t87
  %t88 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t86, i32 0, i32 1
  store i64 %t85, i64* %t88
  %t89 = bitcast { i64, i64 }* %t86 to i8*
  %t90 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t77
  store i8* %t89, i8** %t90
  %t91 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t77
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t91
  %t92 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t77
  %t93 = load i8*, i8** %t92
  %t94 = call i32 @ReleaseSemaphore(i8* %t93, i32 1, i32* null)
  br label %par_fanout_step_19
par_fanout_step_19:
  %t95 = add i32 %t77, 1
  store i32 %t95, i32* %t76
  br label %par_fanout_cond_17
par_fanout_end_20:
  store i32 0, i32* %t96
  br label %par_join_wait_cond_21
par_join_wait_cond_21:
  %t97 = load i32, i32* %t96
  %t98 = icmp slt i32 %t97, %t61
  br i1 %t98, label %par_join_wait_body_22, label %par_join_wait_end_24
par_join_wait_body_22:
  %t99 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t97
  %t100 = load i8*, i8** %t99
  %t101 = call i32 @WaitForSingleObject(i8* %t100, i32 -1)
  br label %par_join_wait_step_23
par_join_wait_step_23:
  %t102 = add i32 %t97, 1
  store i32 %t102, i32* %t96
  br label %par_join_wait_cond_21
par_join_wait_end_24:
  br label %par_join_16
par_serial_12:
  %t103 = load i32, i32* @par.pool.serial_owner
  %t104 = icmp eq i32 %t103, %t72
  br i1 %t104, label %par_run_14, label %par_acquire_13
par_acquire_13:
  %t105 = load i8*, i8** @par.pool.serial_lock
  %t106 = call i32 @WaitForSingleObject(i8* %t105, i32 -1)
  store i32 %t72, i32* @par.pool.serial_owner
  br label %par_run_14
par_run_14:
  %t107 = load i64, i64* @arena.Enemies.count
  %t109 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t108, i32 0, i32 0
  store i64 0, i64* %t109
  %t110 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t108, i32 0, i32 1
  store i64 %t107, i64* %t110
  %t111 = bitcast { i64, i64 }* %t108 to i8*
  %t112 = call i32 @par_worker_0(i8* %t111)
  br i1 %t104, label %par_join_16, label %par_release_15
par_release_15:
  store i32 -1, i32* @par.pool.serial_owner
  %t113 = load i8*, i8** @par.pool.serial_lock
  %t114 = call i32 @ReleaseSemaphore(i8* %t113, i32 1, i32* null)
  br label %par_join_16
par_join_16:
  call void @par.pool.ensure_init()
  %t131 = load i32, i32* @par.pool.num_workers
  %t132 = sext i32 %t131 to i64
  %t133 = call i32 @GetCurrentThreadId()
  store i32 -1, i32* %t134
  store i32 0, i32* %t135
  br label %par_reentry_cond_31
par_reentry_cond_31:
  %t136 = load i32, i32* %t135
  %t137 = icmp slt i32 %t136, %t131
  br i1 %t137, label %par_reentry_body_32, label %par_reentry_end_35
par_reentry_body_32:
  %t138 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t136
  %t139 = load i32, i32* %t138
  %t140 = icmp eq i32 %t133, %t139
  br i1 %t140, label %par_reentry_match_33, label %par_reentry_step_34
par_reentry_match_33:
  store i32 %t136, i32* %t134
  br label %par_reentry_step_34
par_reentry_step_34:
  %t141 = add i32 %t136, 1
  store i32 %t141, i32* %t135
  br label %par_reentry_cond_31
par_reentry_end_35:
  %t142 = load i32, i32* %t134
  %t143 = icmp sge i32 %t142, 0
  br i1 %t143, label %par_serial_37, label %par_pooled_36
par_pooled_36:
  %t144 = load i64, i64* @arena.Enemies.count
  store i32 0, i32* %t146
  br label %par_fanout_cond_42
par_fanout_cond_42:
  %t147 = load i32, i32* %t146
  %t148 = icmp slt i32 %t147, %t131
  br i1 %t148, label %par_fanout_body_43, label %par_fanout_end_45
par_fanout_body_43:
  %t149 = sext i32 %t147 to i64
  %t150 = mul i64 %t144, %t149
  %t151 = sdiv i64 %t150, %t132
  %t152 = add i32 %t147, 1
  %t153 = sext i32 %t152 to i64
  %t154 = mul i64 %t144, %t153
  %t155 = sdiv i64 %t154, %t132
  %t156 = getelementptr inbounds [64 x { i64, i64 }], [64 x { i64, i64 }]* %t145, i32 0, i32 %t147
  %t157 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t156, i32 0, i32 0
  store i64 %t151, i64* %t157
  %t158 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t156, i32 0, i32 1
  store i64 %t155, i64* %t158
  %t159 = bitcast { i64, i64 }* %t156 to i8*
  %t160 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t147
  store i8* %t159, i8** %t160
  %t161 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t147
  store i32 (i8*)* @par_worker_25, i32 (i8*)** %t161
  %t162 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t147
  %t163 = load i8*, i8** %t162
  %t164 = call i32 @ReleaseSemaphore(i8* %t163, i32 1, i32* null)
  br label %par_fanout_step_44
par_fanout_step_44:
  %t165 = add i32 %t147, 1
  store i32 %t165, i32* %t146
  br label %par_fanout_cond_42
par_fanout_end_45:
  store i32 0, i32* %t166
  br label %par_join_wait_cond_46
par_join_wait_cond_46:
  %t167 = load i32, i32* %t166
  %t168 = icmp slt i32 %t167, %t131
  br i1 %t168, label %par_join_wait_body_47, label %par_join_wait_end_49
par_join_wait_body_47:
  %t169 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t167
  %t170 = load i8*, i8** %t169
  %t171 = call i32 @WaitForSingleObject(i8* %t170, i32 -1)
  br label %par_join_wait_step_48
par_join_wait_step_48:
  %t172 = add i32 %t167, 1
  store i32 %t172, i32* %t166
  br label %par_join_wait_cond_46
par_join_wait_end_49:
  br label %par_join_41
par_serial_37:
  %t173 = load i32, i32* @par.pool.serial_owner
  %t174 = icmp eq i32 %t173, %t142
  br i1 %t174, label %par_run_39, label %par_acquire_38
par_acquire_38:
  %t175 = load i8*, i8** @par.pool.serial_lock
  %t176 = call i32 @WaitForSingleObject(i8* %t175, i32 -1)
  store i32 %t142, i32* @par.pool.serial_owner
  br label %par_run_39
par_run_39:
  %t177 = load i64, i64* @arena.Enemies.count
  %t179 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t178, i32 0, i32 0
  store i64 0, i64* %t179
  %t180 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t178, i32 0, i32 1
  store i64 %t177, i64* %t180
  %t181 = bitcast { i64, i64 }* %t178 to i8*
  %t182 = call i32 @par_worker_25(i8* %t181)
  br i1 %t174, label %par_join_41, label %par_release_40
par_release_40:
  store i32 -1, i32* @par.pool.serial_owner
  %t183 = load i8*, i8** @par.pool.serial_lock
  %t184 = call i32 @ReleaseSemaphore(i8* %t183, i32 1, i32* null)
  br label %par_join_41
par_join_41:
  %t185 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t185)
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_0(i8* %argp) {
entry:
  %t8 = alloca i64
  %t2 = bitcast i8* %argp to { i64, i64 }*
  %t3 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t2, i32 0, i32 0
  %t4 = load i64, i64* %t3
  %t5 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t2, i32 0, i32 1
  %t6 = load i64, i64* %t5
  %t7 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t4, i64* %t8
  br label %par_cond_1
par_cond_1:
  %t9 = load i64, i64* %t8
  %t10 = icmp slt i64 %t9, %t6
  br i1 %t10, label %par_body_2, label %par_end_5
par_body_2:
  %t11 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t9
  %t12 = load i64, i64* %t11
  %t13 = and i64 %t12, 1
  %t14 = icmp eq i64 %t13, 1
  br i1 %t14, label %par_live_3, label %par_incr_4
par_live_3:
  %t15 = getelementptr inbounds %Enemy, %Enemy* %t7, i64 %t9
  %t16 = getelementptr inbounds %Enemy, %Enemy* %t15, i32 0, i32 0
  %t17 = load i32, i32* %t16
  %t18 = sub i32 %t17, 1
  %t19 = getelementptr inbounds %Enemy, %Enemy* %t15, i32 0, i32 0
  store i32 %t18, i32* %t19
  br label %par_incr_4
par_incr_4:
  %t20 = add i64 %t9, 1
  store i64 %t20, i64* %t8
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
  %t21 = ptrtoint i8* %idx_arg to i64
  %t22 = trunc i64 %t21 to i32
  %t23 = call i32 @GetCurrentThreadId()
  %t24 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t22
  store i32 %t23, i32* %t24
  br label %loop
loop:
  %t25 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t22
  %t26 = load i8*, i8** %t25
  %t27 = call i32 @WaitForSingleObject(i8* %t26, i32 -1)
  %t28 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t22
  %t29 = load i32 (i8*)*, i32 (i8*)** %t28
  %t30 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t22
  %t31 = load i8*, i8** %t30
  %t32 = call i32 %t29(i8* %t31)
  %t33 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t22
  %t34 = load i8*, i8** %t33
  %t35 = call i32 @ReleaseSemaphore(i8* %t34, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t36 = load i1, i1* @par.pool.inited
  br i1 %t36, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t37 = getelementptr inbounds [13 x i8], [13 x i8]* @par.pool.env_name, i64 0, i64 0
  %t38 = call i8* @getenv(i8* %t37)
  %t39 = icmp eq i8* %t38, null
  br i1 %t39, label %par_pool_detect, label %par_pool_override
par_pool_override:
  %t40 = call i32 @atoi(i8* %t38)
  br label %par_pool_clamp
par_pool_detect:
  %t41 = getelementptr inbounds [48 x i8], [48 x i8]* @par.pool.sysinfo_buf, i64 0, i64 0
  call void @GetSystemInfo(i8* %t41)
  %t42 = getelementptr inbounds [48 x i8], [48 x i8]* @par.pool.sysinfo_buf, i64 0, i64 32
  %t43 = bitcast i8* %t42 to i32*
  %t44 = load i32, i32* %t43
  br label %par_pool_clamp
par_pool_clamp:
  %t45 = phi i32 [ %t40, %par_pool_override ], [ %t44, %par_pool_detect ]
  %t46 = icmp slt i32 %t45, 4
  %t47 = select i1 %t46, i32 4, i32 %t45
  %t48 = icmp sgt i32 %t47, 64
  %t49 = select i1 %t48, i32 64, i32 %t47
  store i32 %t49, i32* @par.pool.num_workers
  %t50 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t50, i8** @par.pool.serial_lock
  store i32 0, i32* @par.pool.init_i
  br label %par_pool_thread_cond
par_pool_thread_cond:
  %t51 = load i32, i32* @par.pool.init_i
  %t52 = icmp slt i32 %t51, %t49
  br i1 %t52, label %par_pool_thread_body, label %par_pool_init_done
par_pool_thread_body:
  %t53 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t54 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t51
  store i8* %t53, i8** %t54
  %t55 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t56 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t51
  store i8* %t55, i8** %t56
  %t57 = sext i32 %t51 to i64
  %t58 = inttoptr i64 %t57 to i8*
  %t59 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* %t58, i32 0, i32* null)
  %t60 = add i32 %t51, 1
  store i32 %t60, i32* @par.pool.init_i
  br label %par_pool_thread_cond
par_pool_init_done:
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_25(i8* %argp) {
entry:
  %t121 = alloca i64
  %t115 = bitcast i8* %argp to { i64, i64 }*
  %t116 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t115, i32 0, i32 0
  %t117 = load i64, i64* %t116
  %t118 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t115, i32 0, i32 1
  %t119 = load i64, i64* %t118
  %t120 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t117, i64* %t121
  br label %par_cond_26
par_cond_26:
  %t122 = load i64, i64* %t121
  %t123 = icmp slt i64 %t122, %t119
  br i1 %t123, label %par_body_27, label %par_end_30
par_body_27:
  %t124 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t122
  %t125 = load i64, i64* %t124
  %t126 = and i64 %t125, 1
  %t127 = icmp eq i64 %t126, 1
  br i1 %t127, label %par_live_28, label %par_incr_29
par_live_28:
  %t128 = getelementptr inbounds %Enemy, %Enemy* %t120, i64 %t122
  %t129 = getelementptr inbounds %Enemy, %Enemy* %t128, i32 0, i32 0
  store i32 0, i32* %t129
  br label %par_incr_29
par_incr_29:
  %t130 = add i64 %t122, 1
  store i64 %t130, i64* %t121
  br label %par_cond_26
par_end_30:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [12 x i8] c"swarm done\0A\00"
