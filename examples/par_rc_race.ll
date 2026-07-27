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
  %t2 = alloca i8*
  %t11 = alloca i32
  %t33 = alloca %Enemy
  %t44 = alloca i32
  %t115 = alloca i32
  %t116 = alloca i32
  %t126 = alloca [64 x { i64, i64, i8**, i32* }]
  %t127 = alloca i32
  %t149 = alloca i32
  %t161 = alloca { i64, i64, i8**, i32* }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t4 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t5 = call i32 @strlen(i8* %t3)
  %t6 = call i32 @strlen(i8* %t4)
  %t7 = add i32 %t5, %t6
  %t8 = add i32 %t7, 1
  %t9 = sext i32 %t8 to i64
  %t10 = call i8* @star_rc_alloc(i64 %t9, i8* null)
  call i8* @strcpy(i8* %t10, i8* %t3)
  call i8* @strcat(i8* %t10, i8* %t4)
  call void @star_rc_release(i8* %t3)
  call void @star_rc_release(i8* %t4)
  store i8* %t10, i8** %t2
  store i32 0, i32* %t11
  br label %for_cond_0
for_cond_0:
  %t12 = load i32, i32* %t11
  %t13 = icmp slt i32 %t12, 16
  br i1 %t13, label %for_body_1, label %for_end_3
for_body_1:
  %t14 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t15 = icmp eq %Enemy* %t14, null
  br i1 %t15, label %spawn_init_4, label %spawn_ready_5
spawn_init_4:
  %t16 = getelementptr %Enemy, %Enemy* null, i32 1
  %t17 = ptrtoint %Enemy* %t16 to i64
  %t18 = mul i64 %t17, 1024
  %t19 = call i8* @malloc(i64 %t18)
  %t20 = bitcast i8* %t19 to %Enemy*
  store %Enemy* %t20, %Enemy** @arena.Enemies.data
  br label %spawn_ready_5
spawn_ready_5:
  %t21 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t22 = load i64, i64* @arena.Enemies.free_top
  %t23 = icmp sgt i64 %t22, 0
  br i1 %t23, label %spawn_reuse_6, label %spawn_grow_7
spawn_reuse_6:
  %t24 = sub i64 %t22, 1
  store i64 %t24, i64* @arena.Enemies.free_top
  %t25 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t24
  %t26 = load i64, i64* %t25
  br label %spawn_store_8
spawn_grow_7:
  %t27 = load i64, i64* @arena.Enemies.count
  %t28 = icmp slt i64 %t27, 1024
  br i1 %t28, label %spawn_grow_ok_10, label %spawn_capacity_warn_11
spawn_capacity_warn_11:
  %t29 = load i1, i1* @arena.Enemies.warned
  br i1 %t29, label %spawn_end_9, label %spawn_warn_print_12
spawn_warn_print_12:
  store i1 1, i1* @arena.Enemies.warned
  %t30 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t30)
  br label %spawn_end_9
spawn_grow_ok_10:
  %t31 = add i64 %t27, 1
  store i64 %t31, i64* @arena.Enemies.count
  br label %spawn_store_8
spawn_store_8:
  %t32 = phi i64 [ %t26, %spawn_reuse_6 ], [ %t27, %spawn_grow_ok_10 ]
  %t34 = getelementptr inbounds %Enemy, %Enemy* %t33, i32 0, i32 0
  store i32 100, i32* %t34
  %t35 = load %Enemy, %Enemy* %t33
  %t36 = getelementptr inbounds %Enemy, %Enemy* %t21, i64 %t32
  store %Enemy %t35, %Enemy* %t36
  %t37 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t32
  %t38 = load i64, i64* %t37
  %t39 = add i64 %t38, 1
  store i64 %t39, i64* %t37
  %t40 = trunc i64 %t32 to i32
  br label %spawn_end_9
spawn_end_9:
  %t41 = phi i32 [ %t40, %spawn_store_8 ], [ -1, %spawn_capacity_warn_11 ], [ -1, %spawn_warn_print_12 ]
  br label %for_step_2
for_step_2:
  %t42 = load i32, i32* %t11
  %t43 = add i32 %t42, 1
  store i32 %t43, i32* %t11
  br label %for_cond_0
for_end_3:
  store i32 0, i32* %t44
  br label %for_cond_13
for_cond_13:
  %t45 = load i32, i32* %t44
  %t46 = icmp slt i32 %t45, 400
  br i1 %t46, label %for_body_14, label %for_end_16
for_body_14:
  call void @par.pool.ensure_init()
  %t112 = load i32, i32* @par.pool.num_workers
  %t113 = sext i32 %t112 to i64
  %t114 = call i32 @GetCurrentThreadId()
  store i32 -1, i32* %t115
  store i32 0, i32* %t116
  br label %par_reentry_cond_23
par_reentry_cond_23:
  %t117 = load i32, i32* %t116
  %t118 = icmp slt i32 %t117, %t112
  br i1 %t118, label %par_reentry_body_24, label %par_reentry_end_27
par_reentry_body_24:
  %t119 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t117
  %t120 = load i32, i32* %t119
  %t121 = icmp eq i32 %t114, %t120
  br i1 %t121, label %par_reentry_match_25, label %par_reentry_step_26
par_reentry_match_25:
  store i32 %t117, i32* %t115
  br label %par_reentry_step_26
par_reentry_step_26:
  %t122 = add i32 %t117, 1
  store i32 %t122, i32* %t116
  br label %par_reentry_cond_23
par_reentry_end_27:
  %t123 = load i32, i32* %t115
  %t124 = icmp sge i32 %t123, 0
  br i1 %t124, label %par_serial_29, label %par_pooled_28
par_pooled_28:
  %t125 = load i64, i64* @arena.Enemies.count
  store i32 0, i32* %t127
  br label %par_fanout_cond_34
par_fanout_cond_34:
  %t128 = load i32, i32* %t127
  %t129 = icmp slt i32 %t128, %t112
  br i1 %t129, label %par_fanout_body_35, label %par_fanout_end_37
par_fanout_body_35:
  %t130 = sext i32 %t128 to i64
  %t131 = mul i64 %t125, %t130
  %t132 = sdiv i64 %t131, %t113
  %t133 = add i32 %t128, 1
  %t134 = sext i32 %t133 to i64
  %t135 = mul i64 %t125, %t134
  %t136 = sdiv i64 %t135, %t113
  %t137 = getelementptr inbounds [64 x { i64, i64, i8**, i32* }], [64 x { i64, i64, i8**, i32* }]* %t126, i32 0, i32 %t128
  %t138 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t137, i32 0, i32 0
  store i64 %t132, i64* %t138
  %t139 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t137, i32 0, i32 1
  store i64 %t136, i64* %t139
  %t140 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t137, i32 0, i32 2
  store i8** %t2, i8*** %t140
  %t141 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t137, i32 0, i32 3
  store i32* %t44, i32** %t141
  %t142 = bitcast { i64, i64, i8**, i32* }* %t137 to i8*
  %t143 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t128
  store i8* %t142, i8** %t143
  %t144 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t128
  store i32 (i8*)* @par_worker_17, i32 (i8*)** %t144
  %t145 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t128
  %t146 = load i8*, i8** %t145
  %t147 = call i32 @ReleaseSemaphore(i8* %t146, i32 1, i32* null)
  br label %par_fanout_step_36
par_fanout_step_36:
  %t148 = add i32 %t128, 1
  store i32 %t148, i32* %t127
  br label %par_fanout_cond_34
par_fanout_end_37:
  store i32 0, i32* %t149
  br label %par_join_wait_cond_38
par_join_wait_cond_38:
  %t150 = load i32, i32* %t149
  %t151 = icmp slt i32 %t150, %t112
  br i1 %t151, label %par_join_wait_body_39, label %par_join_wait_end_41
par_join_wait_body_39:
  %t152 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t150
  %t153 = load i8*, i8** %t152
  %t154 = call i32 @WaitForSingleObject(i8* %t153, i32 -1)
  br label %par_join_wait_step_40
par_join_wait_step_40:
  %t155 = add i32 %t150, 1
  store i32 %t155, i32* %t149
  br label %par_join_wait_cond_38
par_join_wait_end_41:
  br label %par_join_33
par_serial_29:
  %t156 = load i32, i32* @par.pool.serial_owner
  %t157 = icmp eq i32 %t156, %t123
  br i1 %t157, label %par_run_31, label %par_acquire_30
par_acquire_30:
  %t158 = load i8*, i8** @par.pool.serial_lock
  %t159 = call i32 @WaitForSingleObject(i8* %t158, i32 -1)
  store i32 %t123, i32* @par.pool.serial_owner
  br label %par_run_31
par_run_31:
  %t160 = load i64, i64* @arena.Enemies.count
  %t162 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t161, i32 0, i32 0
  store i64 0, i64* %t162
  %t163 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t161, i32 0, i32 1
  store i64 %t160, i64* %t163
  %t164 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t161, i32 0, i32 2
  store i8** %t2, i8*** %t164
  %t165 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t161, i32 0, i32 3
  store i32* %t44, i32** %t165
  %t166 = bitcast { i64, i64, i8**, i32* }* %t161 to i8*
  %t167 = call i32 @par_worker_17(i8* %t166)
  br i1 %t157, label %par_join_33, label %par_release_32
par_release_32:
  store i32 -1, i32* @par.pool.serial_owner
  %t168 = load i8*, i8** @par.pool.serial_lock
  %t169 = call i32 @ReleaseSemaphore(i8* %t168, i32 1, i32* null)
  br label %par_join_33
par_join_33:
  br label %for_step_15
for_step_15:
  %t170 = load i32, i32* %t44
  %t171 = add i32 %t170, 1
  store i32 %t171, i32* %t44
  br label %for_cond_13
for_end_16:
  %t172 = load i8*, i8** %t2
  %t173 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t173)
  call void @star_rc_release(i8* %t172)
  %t174 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t174, i8* %t172)
  %t175 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t175)
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_17(i8* %argp) {
entry:
  %t57 = alloca i64
  %t47 = bitcast i8* %argp to { i64, i64, i8**, i32* }*
  %t48 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t47, i32 0, i32 0
  %t49 = load i64, i64* %t48
  %t50 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t47, i32 0, i32 1
  %t51 = load i64, i64* %t50
  %t52 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t47, i32 0, i32 2
  %t53 = load i8**, i8*** %t52
  %t54 = getelementptr inbounds { i64, i64, i8**, i32* }, { i64, i64, i8**, i32* }* %t47, i32 0, i32 3
  %t55 = load i32*, i32** %t54
  %t56 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t49, i64* %t57
  br label %par_cond_18
par_cond_18:
  %t58 = load i64, i64* %t57
  %t59 = icmp slt i64 %t58, %t51
  br i1 %t59, label %par_body_19, label %par_end_22
par_body_19:
  %t60 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t58
  %t61 = load i64, i64* %t60
  %t62 = and i64 %t61, 1
  %t63 = icmp eq i64 %t62, 1
  br i1 %t63, label %par_live_20, label %par_incr_21
par_live_20:
  %t64 = getelementptr inbounds %Enemy, %Enemy* %t56, i64 %t58
  %t65 = getelementptr inbounds %Enemy, %Enemy* %t64, i32 0, i32 0
  %t66 = load i32, i32* %t65
  %t67 = sub i32 %t66, 1
  %t68 = getelementptr inbounds %Enemy, %Enemy* %t64, i32 0, i32 0
  store i32 %t67, i32* %t68
  %t69 = load i8*, i8** %t53
  %t70 = load i8*, i8** %t53
  call void @star_rc_retain(i8* %t70)
  call void @star_rc_release(i8* %t69)
  call i32 (i8*, ...) @printf(i8* %t69)
  br label %par_incr_21
par_incr_21:
  %t71 = add i64 %t58, 1
  store i64 %t71, i64* %t57
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
  %t72 = ptrtoint i8* %idx_arg to i64
  %t73 = trunc i64 %t72 to i32
  %t74 = call i32 @GetCurrentThreadId()
  %t75 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t73
  store i32 %t74, i32* %t75
  br label %loop
loop:
  %t76 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t73
  %t77 = load i8*, i8** %t76
  %t78 = call i32 @WaitForSingleObject(i8* %t77, i32 -1)
  %t79 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t73
  %t80 = load i32 (i8*)*, i32 (i8*)** %t79
  %t81 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t73
  %t82 = load i8*, i8** %t81
  %t83 = call i32 %t80(i8* %t82)
  %t84 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t73
  %t85 = load i8*, i8** %t84
  %t86 = call i32 @ReleaseSemaphore(i8* %t85, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t87 = load i1, i1* @par.pool.inited
  br i1 %t87, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t88 = getelementptr inbounds [13 x i8], [13 x i8]* @par.pool.env_name, i64 0, i64 0
  %t89 = call i8* @getenv(i8* %t88)
  %t90 = icmp eq i8* %t89, null
  br i1 %t90, label %par_pool_detect, label %par_pool_override
par_pool_override:
  %t91 = call i32 @atoi(i8* %t89)
  br label %par_pool_clamp
par_pool_detect:
  %t92 = getelementptr inbounds [48 x i8], [48 x i8]* @par.pool.sysinfo_buf, i64 0, i64 0
  call void @GetSystemInfo(i8* %t92)
  %t93 = getelementptr inbounds [48 x i8], [48 x i8]* @par.pool.sysinfo_buf, i64 0, i64 32
  %t94 = bitcast i8* %t93 to i32*
  %t95 = load i32, i32* %t94
  br label %par_pool_clamp
par_pool_clamp:
  %t96 = phi i32 [ %t91, %par_pool_override ], [ %t95, %par_pool_detect ]
  %t97 = icmp slt i32 %t96, 4
  %t98 = select i1 %t97, i32 4, i32 %t96
  %t99 = icmp sgt i32 %t98, 64
  %t100 = select i1 %t99, i32 64, i32 %t98
  store i32 %t100, i32* @par.pool.num_workers
  %t101 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t101, i8** @par.pool.serial_lock
  store i32 0, i32* @par.pool.init_i
  br label %par_pool_thread_cond
par_pool_thread_cond:
  %t102 = load i32, i32* @par.pool.init_i
  %t103 = icmp slt i32 %t102, %t100
  br i1 %t103, label %par_pool_thread_body, label %par_pool_init_done
par_pool_thread_body:
  %t104 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t105 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t102
  store i8* %t104, i8** %t105
  %t106 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t107 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t102
  store i8* %t106, i8** %t107
  %t108 = sext i32 %t102 to i64
  %t109 = inttoptr i64 %t108 to i8*
  %t110 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* %t109, i32 0, i32* null)
  %t111 = add i32 %t102, 1
  store i32 %t111, i32* @par.pool.init_i
  br label %par_pool_thread_cond
par_pool_init_done:
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"swarm-\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"tag\00" }
@.str.2 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.3 = private unnamed_addr constant [11 x i8] c"final: %s\0A\00"
