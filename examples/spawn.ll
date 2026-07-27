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
  %t21 = alloca %Enemy
  %t49 = alloca %Enemy
  %t77 = alloca %Enemy
  %t148 = alloca i32
  %t149 = alloca i32
  %t159 = alloca [64 x { i64, i64 }]
  %t160 = alloca i32
  %t180 = alloca i32
  %t192 = alloca { i64, i64 }
  %t220 = alloca i32
  %t221 = alloca i32
  %t231 = alloca [64 x { i64, i64 }]
  %t232 = alloca i32
  %t252 = alloca i32
  %t264 = alloca { i64, i64 }
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
  %t17 = load i1, i1* @arena.Enemies.warned
  br i1 %t17, label %spawn_end_5, label %spawn_warn_print_8
spawn_warn_print_8:
  store i1 1, i1* @arena.Enemies.warned
  %t18 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t18)
  br label %spawn_end_5
spawn_grow_ok_6:
  %t19 = add i64 %t15, 1
  store i64 %t19, i64* @arena.Enemies.count
  br label %spawn_store_4
spawn_store_4:
  %t20 = phi i64 [ %t14, %spawn_reuse_2 ], [ %t15, %spawn_grow_ok_6 ]
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
  br label %spawn_end_5
spawn_end_5:
  %t29 = phi i32 [ %t28, %spawn_store_4 ], [ -1, %spawn_capacity_warn_7 ], [ -1, %spawn_warn_print_8 ]
  %t30 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t31 = icmp eq %Enemy* %t30, null
  br i1 %t31, label %spawn_init_9, label %spawn_ready_10
spawn_init_9:
  %t32 = getelementptr %Enemy, %Enemy* null, i32 1
  %t33 = ptrtoint %Enemy* %t32 to i64
  %t34 = mul i64 %t33, 1024
  %t35 = call i8* @malloc(i64 %t34)
  %t36 = bitcast i8* %t35 to %Enemy*
  store %Enemy* %t36, %Enemy** @arena.Enemies.data
  br label %spawn_ready_10
spawn_ready_10:
  %t37 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t38 = load i64, i64* @arena.Enemies.free_top
  %t39 = icmp sgt i64 %t38, 0
  br i1 %t39, label %spawn_reuse_11, label %spawn_grow_12
spawn_reuse_11:
  %t40 = sub i64 %t38, 1
  store i64 %t40, i64* @arena.Enemies.free_top
  %t41 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t40
  %t42 = load i64, i64* %t41
  br label %spawn_store_13
spawn_grow_12:
  %t43 = load i64, i64* @arena.Enemies.count
  %t44 = icmp slt i64 %t43, 1024
  br i1 %t44, label %spawn_grow_ok_15, label %spawn_capacity_warn_16
spawn_capacity_warn_16:
  %t45 = load i1, i1* @arena.Enemies.warned
  br i1 %t45, label %spawn_end_14, label %spawn_warn_print_17
spawn_warn_print_17:
  store i1 1, i1* @arena.Enemies.warned
  %t46 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t46)
  br label %spawn_end_14
spawn_grow_ok_15:
  %t47 = add i64 %t43, 1
  store i64 %t47, i64* @arena.Enemies.count
  br label %spawn_store_13
spawn_store_13:
  %t48 = phi i64 [ %t42, %spawn_reuse_11 ], [ %t43, %spawn_grow_ok_15 ]
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
  br label %spawn_end_14
spawn_end_14:
  %t57 = phi i32 [ %t56, %spawn_store_13 ], [ -1, %spawn_capacity_warn_16 ], [ -1, %spawn_warn_print_17 ]
  %t58 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t59 = icmp eq %Enemy* %t58, null
  br i1 %t59, label %spawn_init_18, label %spawn_ready_19
spawn_init_18:
  %t60 = getelementptr %Enemy, %Enemy* null, i32 1
  %t61 = ptrtoint %Enemy* %t60 to i64
  %t62 = mul i64 %t61, 1024
  %t63 = call i8* @malloc(i64 %t62)
  %t64 = bitcast i8* %t63 to %Enemy*
  store %Enemy* %t64, %Enemy** @arena.Enemies.data
  br label %spawn_ready_19
spawn_ready_19:
  %t65 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t66 = load i64, i64* @arena.Enemies.free_top
  %t67 = icmp sgt i64 %t66, 0
  br i1 %t67, label %spawn_reuse_20, label %spawn_grow_21
spawn_reuse_20:
  %t68 = sub i64 %t66, 1
  store i64 %t68, i64* @arena.Enemies.free_top
  %t69 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t68
  %t70 = load i64, i64* %t69
  br label %spawn_store_22
spawn_grow_21:
  %t71 = load i64, i64* @arena.Enemies.count
  %t72 = icmp slt i64 %t71, 1024
  br i1 %t72, label %spawn_grow_ok_24, label %spawn_capacity_warn_25
spawn_capacity_warn_25:
  %t73 = load i1, i1* @arena.Enemies.warned
  br i1 %t73, label %spawn_end_23, label %spawn_warn_print_26
spawn_warn_print_26:
  store i1 1, i1* @arena.Enemies.warned
  %t74 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t74)
  br label %spawn_end_23
spawn_grow_ok_24:
  %t75 = add i64 %t71, 1
  store i64 %t75, i64* @arena.Enemies.count
  br label %spawn_store_22
spawn_store_22:
  %t76 = phi i64 [ %t70, %spawn_reuse_20 ], [ %t71, %spawn_grow_ok_24 ]
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
  br label %spawn_end_23
spawn_end_23:
  %t85 = phi i32 [ %t84, %spawn_store_22 ], [ -1, %spawn_capacity_warn_25 ], [ -1, %spawn_warn_print_26 ]
  call void @par.pool.ensure_init()
  %t145 = load i32, i32* @par.pool.num_workers
  %t146 = sext i32 %t145 to i64
  %t147 = call i32 @GetCurrentThreadId()
  store i32 -1, i32* %t148
  store i32 0, i32* %t149
  br label %par_reentry_cond_33
par_reentry_cond_33:
  %t150 = load i32, i32* %t149
  %t151 = icmp slt i32 %t150, %t145
  br i1 %t151, label %par_reentry_body_34, label %par_reentry_end_37
par_reentry_body_34:
  %t152 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t150
  %t153 = load i32, i32* %t152
  %t154 = icmp eq i32 %t147, %t153
  br i1 %t154, label %par_reentry_match_35, label %par_reentry_step_36
par_reentry_match_35:
  store i32 %t150, i32* %t148
  br label %par_reentry_step_36
par_reentry_step_36:
  %t155 = add i32 %t150, 1
  store i32 %t155, i32* %t149
  br label %par_reentry_cond_33
par_reentry_end_37:
  %t156 = load i32, i32* %t148
  %t157 = icmp sge i32 %t156, 0
  br i1 %t157, label %par_serial_39, label %par_pooled_38
par_pooled_38:
  %t158 = load i64, i64* @arena.Enemies.count
  store i32 0, i32* %t160
  br label %par_fanout_cond_44
par_fanout_cond_44:
  %t161 = load i32, i32* %t160
  %t162 = icmp slt i32 %t161, %t145
  br i1 %t162, label %par_fanout_body_45, label %par_fanout_end_47
par_fanout_body_45:
  %t163 = sext i32 %t161 to i64
  %t164 = mul i64 %t158, %t163
  %t165 = sdiv i64 %t164, %t146
  %t166 = add i32 %t161, 1
  %t167 = sext i32 %t166 to i64
  %t168 = mul i64 %t158, %t167
  %t169 = sdiv i64 %t168, %t146
  %t170 = getelementptr inbounds [64 x { i64, i64 }], [64 x { i64, i64 }]* %t159, i32 0, i32 %t161
  %t171 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t170, i32 0, i32 0
  store i64 %t165, i64* %t171
  %t172 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t170, i32 0, i32 1
  store i64 %t169, i64* %t172
  %t173 = bitcast { i64, i64 }* %t170 to i8*
  %t174 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t161
  store i8* %t173, i8** %t174
  %t175 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t161
  store i32 (i8*)* @par_worker_27, i32 (i8*)** %t175
  %t176 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t161
  %t177 = load i8*, i8** %t176
  %t178 = call i32 @ReleaseSemaphore(i8* %t177, i32 1, i32* null)
  br label %par_fanout_step_46
par_fanout_step_46:
  %t179 = add i32 %t161, 1
  store i32 %t179, i32* %t160
  br label %par_fanout_cond_44
par_fanout_end_47:
  store i32 0, i32* %t180
  br label %par_join_wait_cond_48
par_join_wait_cond_48:
  %t181 = load i32, i32* %t180
  %t182 = icmp slt i32 %t181, %t145
  br i1 %t182, label %par_join_wait_body_49, label %par_join_wait_end_51
par_join_wait_body_49:
  %t183 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t181
  %t184 = load i8*, i8** %t183
  %t185 = call i32 @WaitForSingleObject(i8* %t184, i32 -1)
  br label %par_join_wait_step_50
par_join_wait_step_50:
  %t186 = add i32 %t181, 1
  store i32 %t186, i32* %t180
  br label %par_join_wait_cond_48
par_join_wait_end_51:
  br label %par_join_43
par_serial_39:
  %t187 = load i32, i32* @par.pool.serial_owner
  %t188 = icmp eq i32 %t187, %t156
  br i1 %t188, label %par_run_41, label %par_acquire_40
par_acquire_40:
  %t189 = load i8*, i8** @par.pool.serial_lock
  %t190 = call i32 @WaitForSingleObject(i8* %t189, i32 -1)
  store i32 %t156, i32* @par.pool.serial_owner
  br label %par_run_41
par_run_41:
  %t191 = load i64, i64* @arena.Enemies.count
  %t193 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t192, i32 0, i32 0
  store i64 0, i64* %t193
  %t194 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t192, i32 0, i32 1
  store i64 %t191, i64* %t194
  %t195 = bitcast { i64, i64 }* %t192 to i8*
  %t196 = call i32 @par_worker_27(i8* %t195)
  br i1 %t188, label %par_join_43, label %par_release_42
par_release_42:
  store i32 -1, i32* @par.pool.serial_owner
  %t197 = load i8*, i8** @par.pool.serial_lock
  %t198 = call i32 @ReleaseSemaphore(i8* %t197, i32 1, i32* null)
  br label %par_join_43
par_join_43:
  call void @par.pool.ensure_init()
  %t217 = load i32, i32* @par.pool.num_workers
  %t218 = sext i32 %t217 to i64
  %t219 = call i32 @GetCurrentThreadId()
  store i32 -1, i32* %t220
  store i32 0, i32* %t221
  br label %par_reentry_cond_58
par_reentry_cond_58:
  %t222 = load i32, i32* %t221
  %t223 = icmp slt i32 %t222, %t217
  br i1 %t223, label %par_reentry_body_59, label %par_reentry_end_62
par_reentry_body_59:
  %t224 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t222
  %t225 = load i32, i32* %t224
  %t226 = icmp eq i32 %t219, %t225
  br i1 %t226, label %par_reentry_match_60, label %par_reentry_step_61
par_reentry_match_60:
  store i32 %t222, i32* %t220
  br label %par_reentry_step_61
par_reentry_step_61:
  %t227 = add i32 %t222, 1
  store i32 %t227, i32* %t221
  br label %par_reentry_cond_58
par_reentry_end_62:
  %t228 = load i32, i32* %t220
  %t229 = icmp sge i32 %t228, 0
  br i1 %t229, label %par_serial_64, label %par_pooled_63
par_pooled_63:
  %t230 = load i64, i64* @arena.Enemies.count
  store i32 0, i32* %t232
  br label %par_fanout_cond_69
par_fanout_cond_69:
  %t233 = load i32, i32* %t232
  %t234 = icmp slt i32 %t233, %t217
  br i1 %t234, label %par_fanout_body_70, label %par_fanout_end_72
par_fanout_body_70:
  %t235 = sext i32 %t233 to i64
  %t236 = mul i64 %t230, %t235
  %t237 = sdiv i64 %t236, %t218
  %t238 = add i32 %t233, 1
  %t239 = sext i32 %t238 to i64
  %t240 = mul i64 %t230, %t239
  %t241 = sdiv i64 %t240, %t218
  %t242 = getelementptr inbounds [64 x { i64, i64 }], [64 x { i64, i64 }]* %t231, i32 0, i32 %t233
  %t243 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t242, i32 0, i32 0
  store i64 %t237, i64* %t243
  %t244 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t242, i32 0, i32 1
  store i64 %t241, i64* %t244
  %t245 = bitcast { i64, i64 }* %t242 to i8*
  %t246 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t233
  store i8* %t245, i8** %t246
  %t247 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t233
  store i32 (i8*)* @par_worker_52, i32 (i8*)** %t247
  %t248 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t233
  %t249 = load i8*, i8** %t248
  %t250 = call i32 @ReleaseSemaphore(i8* %t249, i32 1, i32* null)
  br label %par_fanout_step_71
par_fanout_step_71:
  %t251 = add i32 %t233, 1
  store i32 %t251, i32* %t232
  br label %par_fanout_cond_69
par_fanout_end_72:
  store i32 0, i32* %t252
  br label %par_join_wait_cond_73
par_join_wait_cond_73:
  %t253 = load i32, i32* %t252
  %t254 = icmp slt i32 %t253, %t217
  br i1 %t254, label %par_join_wait_body_74, label %par_join_wait_end_76
par_join_wait_body_74:
  %t255 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t253
  %t256 = load i8*, i8** %t255
  %t257 = call i32 @WaitForSingleObject(i8* %t256, i32 -1)
  br label %par_join_wait_step_75
par_join_wait_step_75:
  %t258 = add i32 %t253, 1
  store i32 %t258, i32* %t252
  br label %par_join_wait_cond_73
par_join_wait_end_76:
  br label %par_join_68
par_serial_64:
  %t259 = load i32, i32* @par.pool.serial_owner
  %t260 = icmp eq i32 %t259, %t228
  br i1 %t260, label %par_run_66, label %par_acquire_65
par_acquire_65:
  %t261 = load i8*, i8** @par.pool.serial_lock
  %t262 = call i32 @WaitForSingleObject(i8* %t261, i32 -1)
  store i32 %t228, i32* @par.pool.serial_owner
  br label %par_run_66
par_run_66:
  %t263 = load i64, i64* @arena.Enemies.count
  %t265 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t264, i32 0, i32 0
  store i64 0, i64* %t265
  %t266 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t264, i32 0, i32 1
  store i64 %t263, i64* %t266
  %t267 = bitcast { i64, i64 }* %t264 to i8*
  %t268 = call i32 @par_worker_52(i8* %t267)
  br i1 %t260, label %par_join_68, label %par_release_67
par_release_67:
  store i32 -1, i32* @par.pool.serial_owner
  %t269 = load i8*, i8** @par.pool.serial_lock
  %t270 = call i32 @ReleaseSemaphore(i8* %t269, i32 1, i32* null)
  br label %par_join_68
par_join_68:
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_27(i8* %argp) {
entry:
  %t92 = alloca i64
  %t86 = bitcast i8* %argp to { i64, i64 }*
  %t87 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t86, i32 0, i32 0
  %t88 = load i64, i64* %t87
  %t89 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t86, i32 0, i32 1
  %t90 = load i64, i64* %t89
  %t91 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t88, i64* %t92
  br label %par_cond_28
par_cond_28:
  %t93 = load i64, i64* %t92
  %t94 = icmp slt i64 %t93, %t90
  br i1 %t94, label %par_body_29, label %par_end_32
par_body_29:
  %t95 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t93
  %t96 = load i64, i64* %t95
  %t97 = and i64 %t96, 1
  %t98 = icmp eq i64 %t97, 1
  br i1 %t98, label %par_live_30, label %par_incr_31
par_live_30:
  %t99 = getelementptr inbounds %Enemy, %Enemy* %t91, i64 %t93
  %t100 = getelementptr inbounds %Enemy, %Enemy* %t99, i32 0, i32 0
  %t101 = load i32, i32* %t100
  %t102 = sub i32 %t101, 1
  %t103 = getelementptr inbounds %Enemy, %Enemy* %t99, i32 0, i32 0
  store i32 %t102, i32* %t103
  br label %par_incr_31
par_incr_31:
  %t104 = add i64 %t93, 1
  store i64 %t104, i64* %t92
  br label %par_cond_28
par_end_32:
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
  %t105 = ptrtoint i8* %idx_arg to i64
  %t106 = trunc i64 %t105 to i32
  %t107 = call i32 @GetCurrentThreadId()
  %t108 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t106
  store i32 %t107, i32* %t108
  br label %loop
loop:
  %t109 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t106
  %t110 = load i8*, i8** %t109
  %t111 = call i32 @WaitForSingleObject(i8* %t110, i32 -1)
  %t112 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t106
  %t113 = load i32 (i8*)*, i32 (i8*)** %t112
  %t114 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t106
  %t115 = load i8*, i8** %t114
  %t116 = call i32 %t113(i8* %t115)
  %t117 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t106
  %t118 = load i8*, i8** %t117
  %t119 = call i32 @ReleaseSemaphore(i8* %t118, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t120 = load i1, i1* @par.pool.inited
  br i1 %t120, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t121 = getelementptr inbounds [13 x i8], [13 x i8]* @par.pool.env_name, i64 0, i64 0
  %t122 = call i8* @getenv(i8* %t121)
  %t123 = icmp eq i8* %t122, null
  br i1 %t123, label %par_pool_detect, label %par_pool_override
par_pool_override:
  %t124 = call i32 @atoi(i8* %t122)
  br label %par_pool_clamp
par_pool_detect:
  %t125 = getelementptr inbounds [48 x i8], [48 x i8]* @par.pool.sysinfo_buf, i64 0, i64 0
  call void @GetSystemInfo(i8* %t125)
  %t126 = getelementptr inbounds [48 x i8], [48 x i8]* @par.pool.sysinfo_buf, i64 0, i64 32
  %t127 = bitcast i8* %t126 to i32*
  %t128 = load i32, i32* %t127
  br label %par_pool_clamp
par_pool_clamp:
  %t129 = phi i32 [ %t124, %par_pool_override ], [ %t128, %par_pool_detect ]
  %t130 = icmp slt i32 %t129, 4
  %t131 = select i1 %t130, i32 4, i32 %t129
  %t132 = icmp sgt i32 %t131, 64
  %t133 = select i1 %t132, i32 64, i32 %t131
  store i32 %t133, i32* @par.pool.num_workers
  %t134 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t134, i8** @par.pool.serial_lock
  store i32 0, i32* @par.pool.init_i
  br label %par_pool_thread_cond
par_pool_thread_cond:
  %t135 = load i32, i32* @par.pool.init_i
  %t136 = icmp slt i32 %t135, %t133
  br i1 %t136, label %par_pool_thread_body, label %par_pool_init_done
par_pool_thread_body:
  %t137 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t138 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t135
  store i8* %t137, i8** %t138
  %t139 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t140 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t135
  store i8* %t139, i8** %t140
  %t141 = sext i32 %t135 to i64
  %t142 = inttoptr i64 %t141 to i8*
  %t143 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* %t142, i32 0, i32* null)
  %t144 = add i32 %t135, 1
  store i32 %t144, i32* @par.pool.init_i
  br label %par_pool_thread_cond
par_pool_init_done:
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_52(i8* %argp) {
entry:
  %t205 = alloca i64
  %t199 = bitcast i8* %argp to { i64, i64 }*
  %t200 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t199, i32 0, i32 0
  %t201 = load i64, i64* %t200
  %t202 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t199, i32 0, i32 1
  %t203 = load i64, i64* %t202
  %t204 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t201, i64* %t205
  br label %par_cond_53
par_cond_53:
  %t206 = load i64, i64* %t205
  %t207 = icmp slt i64 %t206, %t203
  br i1 %t207, label %par_body_54, label %par_end_57
par_body_54:
  %t208 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t206
  %t209 = load i64, i64* %t208
  %t210 = and i64 %t209, 1
  %t211 = icmp eq i64 %t210, 1
  br i1 %t211, label %par_live_55, label %par_incr_56
par_live_55:
  %t212 = getelementptr inbounds %Enemy, %Enemy* %t204, i64 %t206
  %t213 = getelementptr inbounds %Enemy, %Enemy* %t212, i32 0, i32 0
  %t214 = load i32, i32* %t213
  %t215 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t215, i32 %t214)
  br label %par_incr_56
par_incr_56:
  %t216 = add i64 %t206, 1
  store i64 %t216, i64* %t205
  br label %par_cond_53
par_end_57:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.1 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.2 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.3 = private unnamed_addr constant [8 x i8] c"hp: %d\0A\00"
