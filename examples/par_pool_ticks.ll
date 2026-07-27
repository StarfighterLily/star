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
  %t86 = alloca i32
  %t153 = alloca i32
  %t154 = alloca i32
  %t164 = alloca [64 x { i64, i64, i32* }]
  %t165 = alloca i32
  %t186 = alloca i32
  %t198 = alloca { i64, i64, i32* }
  %t229 = alloca i32
  %t230 = alloca i32
  %t240 = alloca [64 x { i64, i64 }]
  %t241 = alloca i32
  %t261 = alloca i32
  %t273 = alloca { i64, i64 }
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
  store i32 100, i32* %t22
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
  store i32 100, i32* %t50
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
  store i32 100, i32* %t78
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
  store i32 0, i32* %t86
  br label %for_cond_27
for_cond_27:
  %t87 = load i32, i32* %t86
  %t88 = icmp slt i32 %t87, 5
  br i1 %t88, label %for_body_28, label %for_end_30
for_body_28:
  call void @par.pool.ensure_init()
  %t150 = load i32, i32* @par.pool.num_workers
  %t151 = sext i32 %t150 to i64
  %t152 = call i32 @GetCurrentThreadId()
  store i32 -1, i32* %t153
  store i32 0, i32* %t154
  br label %par_reentry_cond_37
par_reentry_cond_37:
  %t155 = load i32, i32* %t154
  %t156 = icmp slt i32 %t155, %t150
  br i1 %t156, label %par_reentry_body_38, label %par_reentry_end_41
par_reentry_body_38:
  %t157 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t155
  %t158 = load i32, i32* %t157
  %t159 = icmp eq i32 %t152, %t158
  br i1 %t159, label %par_reentry_match_39, label %par_reentry_step_40
par_reentry_match_39:
  store i32 %t155, i32* %t153
  br label %par_reentry_step_40
par_reentry_step_40:
  %t160 = add i32 %t155, 1
  store i32 %t160, i32* %t154
  br label %par_reentry_cond_37
par_reentry_end_41:
  %t161 = load i32, i32* %t153
  %t162 = icmp sge i32 %t161, 0
  br i1 %t162, label %par_serial_43, label %par_pooled_42
par_pooled_42:
  %t163 = load i64, i64* @arena.Enemies.count
  store i32 0, i32* %t165
  br label %par_fanout_cond_48
par_fanout_cond_48:
  %t166 = load i32, i32* %t165
  %t167 = icmp slt i32 %t166, %t150
  br i1 %t167, label %par_fanout_body_49, label %par_fanout_end_51
par_fanout_body_49:
  %t168 = sext i32 %t166 to i64
  %t169 = mul i64 %t163, %t168
  %t170 = sdiv i64 %t169, %t151
  %t171 = add i32 %t166, 1
  %t172 = sext i32 %t171 to i64
  %t173 = mul i64 %t163, %t172
  %t174 = sdiv i64 %t173, %t151
  %t175 = getelementptr inbounds [64 x { i64, i64, i32* }], [64 x { i64, i64, i32* }]* %t164, i32 0, i32 %t166
  %t176 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t175, i32 0, i32 0
  store i64 %t170, i64* %t176
  %t177 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t175, i32 0, i32 1
  store i64 %t174, i64* %t177
  %t178 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t175, i32 0, i32 2
  store i32* %t86, i32** %t178
  %t179 = bitcast { i64, i64, i32* }* %t175 to i8*
  %t180 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t166
  store i8* %t179, i8** %t180
  %t181 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t166
  store i32 (i8*)* @par_worker_31, i32 (i8*)** %t181
  %t182 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t166
  %t183 = load i8*, i8** %t182
  %t184 = call i32 @ReleaseSemaphore(i8* %t183, i32 1, i32* null)
  br label %par_fanout_step_50
par_fanout_step_50:
  %t185 = add i32 %t166, 1
  store i32 %t185, i32* %t165
  br label %par_fanout_cond_48
par_fanout_end_51:
  store i32 0, i32* %t186
  br label %par_join_wait_cond_52
par_join_wait_cond_52:
  %t187 = load i32, i32* %t186
  %t188 = icmp slt i32 %t187, %t150
  br i1 %t188, label %par_join_wait_body_53, label %par_join_wait_end_55
par_join_wait_body_53:
  %t189 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t187
  %t190 = load i8*, i8** %t189
  %t191 = call i32 @WaitForSingleObject(i8* %t190, i32 -1)
  br label %par_join_wait_step_54
par_join_wait_step_54:
  %t192 = add i32 %t187, 1
  store i32 %t192, i32* %t186
  br label %par_join_wait_cond_52
par_join_wait_end_55:
  br label %par_join_47
par_serial_43:
  %t193 = load i32, i32* @par.pool.serial_owner
  %t194 = icmp eq i32 %t193, %t161
  br i1 %t194, label %par_run_45, label %par_acquire_44
par_acquire_44:
  %t195 = load i8*, i8** @par.pool.serial_lock
  %t196 = call i32 @WaitForSingleObject(i8* %t195, i32 -1)
  store i32 %t161, i32* @par.pool.serial_owner
  br label %par_run_45
par_run_45:
  %t197 = load i64, i64* @arena.Enemies.count
  %t199 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t198, i32 0, i32 0
  store i64 0, i64* %t199
  %t200 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t198, i32 0, i32 1
  store i64 %t197, i64* %t200
  %t201 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t198, i32 0, i32 2
  store i32* %t86, i32** %t201
  %t202 = bitcast { i64, i64, i32* }* %t198 to i8*
  %t203 = call i32 @par_worker_31(i8* %t202)
  br i1 %t194, label %par_join_47, label %par_release_46
par_release_46:
  store i32 -1, i32* @par.pool.serial_owner
  %t204 = load i8*, i8** @par.pool.serial_lock
  %t205 = call i32 @ReleaseSemaphore(i8* %t204, i32 1, i32* null)
  br label %par_join_47
par_join_47:
  br label %for_step_29
for_step_29:
  %t206 = load i32, i32* %t86
  %t207 = add i32 %t206, 1
  store i32 %t207, i32* %t86
  br label %for_cond_27
for_end_30:
  call void @par.pool.ensure_init()
  %t226 = load i32, i32* @par.pool.num_workers
  %t227 = sext i32 %t226 to i64
  %t228 = call i32 @GetCurrentThreadId()
  store i32 -1, i32* %t229
  store i32 0, i32* %t230
  br label %par_reentry_cond_62
par_reentry_cond_62:
  %t231 = load i32, i32* %t230
  %t232 = icmp slt i32 %t231, %t226
  br i1 %t232, label %par_reentry_body_63, label %par_reentry_end_66
par_reentry_body_63:
  %t233 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t231
  %t234 = load i32, i32* %t233
  %t235 = icmp eq i32 %t228, %t234
  br i1 %t235, label %par_reentry_match_64, label %par_reentry_step_65
par_reentry_match_64:
  store i32 %t231, i32* %t229
  br label %par_reentry_step_65
par_reentry_step_65:
  %t236 = add i32 %t231, 1
  store i32 %t236, i32* %t230
  br label %par_reentry_cond_62
par_reentry_end_66:
  %t237 = load i32, i32* %t229
  %t238 = icmp sge i32 %t237, 0
  br i1 %t238, label %par_serial_68, label %par_pooled_67
par_pooled_67:
  %t239 = load i64, i64* @arena.Enemies.count
  store i32 0, i32* %t241
  br label %par_fanout_cond_73
par_fanout_cond_73:
  %t242 = load i32, i32* %t241
  %t243 = icmp slt i32 %t242, %t226
  br i1 %t243, label %par_fanout_body_74, label %par_fanout_end_76
par_fanout_body_74:
  %t244 = sext i32 %t242 to i64
  %t245 = mul i64 %t239, %t244
  %t246 = sdiv i64 %t245, %t227
  %t247 = add i32 %t242, 1
  %t248 = sext i32 %t247 to i64
  %t249 = mul i64 %t239, %t248
  %t250 = sdiv i64 %t249, %t227
  %t251 = getelementptr inbounds [64 x { i64, i64 }], [64 x { i64, i64 }]* %t240, i32 0, i32 %t242
  %t252 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t251, i32 0, i32 0
  store i64 %t246, i64* %t252
  %t253 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t251, i32 0, i32 1
  store i64 %t250, i64* %t253
  %t254 = bitcast { i64, i64 }* %t251 to i8*
  %t255 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t242
  store i8* %t254, i8** %t255
  %t256 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t242
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t256
  %t257 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t242
  %t258 = load i8*, i8** %t257
  %t259 = call i32 @ReleaseSemaphore(i8* %t258, i32 1, i32* null)
  br label %par_fanout_step_75
par_fanout_step_75:
  %t260 = add i32 %t242, 1
  store i32 %t260, i32* %t241
  br label %par_fanout_cond_73
par_fanout_end_76:
  store i32 0, i32* %t261
  br label %par_join_wait_cond_77
par_join_wait_cond_77:
  %t262 = load i32, i32* %t261
  %t263 = icmp slt i32 %t262, %t226
  br i1 %t263, label %par_join_wait_body_78, label %par_join_wait_end_80
par_join_wait_body_78:
  %t264 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t262
  %t265 = load i8*, i8** %t264
  %t266 = call i32 @WaitForSingleObject(i8* %t265, i32 -1)
  br label %par_join_wait_step_79
par_join_wait_step_79:
  %t267 = add i32 %t262, 1
  store i32 %t267, i32* %t261
  br label %par_join_wait_cond_77
par_join_wait_end_80:
  br label %par_join_72
par_serial_68:
  %t268 = load i32, i32* @par.pool.serial_owner
  %t269 = icmp eq i32 %t268, %t237
  br i1 %t269, label %par_run_70, label %par_acquire_69
par_acquire_69:
  %t270 = load i8*, i8** @par.pool.serial_lock
  %t271 = call i32 @WaitForSingleObject(i8* %t270, i32 -1)
  store i32 %t237, i32* @par.pool.serial_owner
  br label %par_run_70
par_run_70:
  %t272 = load i64, i64* @arena.Enemies.count
  %t274 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t273, i32 0, i32 0
  store i64 0, i64* %t274
  %t275 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t273, i32 0, i32 1
  store i64 %t272, i64* %t275
  %t276 = bitcast { i64, i64 }* %t273 to i8*
  %t277 = call i32 @par_worker_56(i8* %t276)
  br i1 %t269, label %par_join_72, label %par_release_71
par_release_71:
  store i32 -1, i32* @par.pool.serial_owner
  %t278 = load i8*, i8** @par.pool.serial_lock
  %t279 = call i32 @ReleaseSemaphore(i8* %t278, i32 1, i32* null)
  br label %par_join_72
par_join_72:
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_31(i8* %argp) {
entry:
  %t97 = alloca i64
  %t89 = bitcast i8* %argp to { i64, i64, i32* }*
  %t90 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t89, i32 0, i32 0
  %t91 = load i64, i64* %t90
  %t92 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t89, i32 0, i32 1
  %t93 = load i64, i64* %t92
  %t94 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t89, i32 0, i32 2
  %t95 = load i32*, i32** %t94
  %t96 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t91, i64* %t97
  br label %par_cond_32
par_cond_32:
  %t98 = load i64, i64* %t97
  %t99 = icmp slt i64 %t98, %t93
  br i1 %t99, label %par_body_33, label %par_end_36
par_body_33:
  %t100 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t98
  %t101 = load i64, i64* %t100
  %t102 = and i64 %t101, 1
  %t103 = icmp eq i64 %t102, 1
  br i1 %t103, label %par_live_34, label %par_incr_35
par_live_34:
  %t104 = getelementptr inbounds %Enemy, %Enemy* %t96, i64 %t98
  %t105 = getelementptr inbounds %Enemy, %Enemy* %t104, i32 0, i32 0
  %t106 = load i32, i32* %t105
  %t107 = sub i32 %t106, 1
  %t108 = getelementptr inbounds %Enemy, %Enemy* %t104, i32 0, i32 0
  store i32 %t107, i32* %t108
  br label %par_incr_35
par_incr_35:
  %t109 = add i64 %t98, 1
  store i64 %t109, i64* %t97
  br label %par_cond_32
par_end_36:
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
  %t110 = ptrtoint i8* %idx_arg to i64
  %t111 = trunc i64 %t110 to i32
  %t112 = call i32 @GetCurrentThreadId()
  %t113 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t111
  store i32 %t112, i32* %t113
  br label %loop
loop:
  %t114 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t111
  %t115 = load i8*, i8** %t114
  %t116 = call i32 @WaitForSingleObject(i8* %t115, i32 -1)
  %t117 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t111
  %t118 = load i32 (i8*)*, i32 (i8*)** %t117
  %t119 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t111
  %t120 = load i8*, i8** %t119
  %t121 = call i32 %t118(i8* %t120)
  %t122 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t111
  %t123 = load i8*, i8** %t122
  %t124 = call i32 @ReleaseSemaphore(i8* %t123, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t125 = load i1, i1* @par.pool.inited
  br i1 %t125, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t126 = getelementptr inbounds [13 x i8], [13 x i8]* @par.pool.env_name, i64 0, i64 0
  %t127 = call i8* @getenv(i8* %t126)
  %t128 = icmp eq i8* %t127, null
  br i1 %t128, label %par_pool_detect, label %par_pool_override
par_pool_override:
  %t129 = call i32 @atoi(i8* %t127)
  br label %par_pool_clamp
par_pool_detect:
  %t130 = getelementptr inbounds [48 x i8], [48 x i8]* @par.pool.sysinfo_buf, i64 0, i64 0
  call void @GetSystemInfo(i8* %t130)
  %t131 = getelementptr inbounds [48 x i8], [48 x i8]* @par.pool.sysinfo_buf, i64 0, i64 32
  %t132 = bitcast i8* %t131 to i32*
  %t133 = load i32, i32* %t132
  br label %par_pool_clamp
par_pool_clamp:
  %t134 = phi i32 [ %t129, %par_pool_override ], [ %t133, %par_pool_detect ]
  %t135 = icmp slt i32 %t134, 4
  %t136 = select i1 %t135, i32 4, i32 %t134
  %t137 = icmp sgt i32 %t136, 64
  %t138 = select i1 %t137, i32 64, i32 %t136
  store i32 %t138, i32* @par.pool.num_workers
  %t139 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t139, i8** @par.pool.serial_lock
  store i32 0, i32* @par.pool.init_i
  br label %par_pool_thread_cond
par_pool_thread_cond:
  %t140 = load i32, i32* @par.pool.init_i
  %t141 = icmp slt i32 %t140, %t138
  br i1 %t141, label %par_pool_thread_body, label %par_pool_init_done
par_pool_thread_body:
  %t142 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t143 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t140
  store i8* %t142, i8** %t143
  %t144 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t145 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t140
  store i8* %t144, i8** %t145
  %t146 = sext i32 %t140 to i64
  %t147 = inttoptr i64 %t146 to i8*
  %t148 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* %t147, i32 0, i32* null)
  %t149 = add i32 %t140, 1
  store i32 %t149, i32* @par.pool.init_i
  br label %par_pool_thread_cond
par_pool_init_done:
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_56(i8* %argp) {
entry:
  %t214 = alloca i64
  %t208 = bitcast i8* %argp to { i64, i64 }*
  %t209 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t208, i32 0, i32 0
  %t210 = load i64, i64* %t209
  %t211 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t208, i32 0, i32 1
  %t212 = load i64, i64* %t211
  %t213 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t210, i64* %t214
  br label %par_cond_57
par_cond_57:
  %t215 = load i64, i64* %t214
  %t216 = icmp slt i64 %t215, %t212
  br i1 %t216, label %par_body_58, label %par_end_61
par_body_58:
  %t217 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t215
  %t218 = load i64, i64* %t217
  %t219 = and i64 %t218, 1
  %t220 = icmp eq i64 %t219, 1
  br i1 %t220, label %par_live_59, label %par_incr_60
par_live_59:
  %t221 = getelementptr inbounds %Enemy, %Enemy* %t213, i64 %t215
  %t222 = getelementptr inbounds %Enemy, %Enemy* %t221, i32 0, i32 0
  %t223 = load i32, i32* %t222
  %t224 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t224, i32 %t223)
  br label %par_incr_60
par_incr_60:
  %t225 = add i64 %t215, 1
  store i64 %t225, i64* %t214
  br label %par_cond_57
par_end_61:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.1 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.2 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.3 = private unnamed_addr constant [8 x i8] c"hp: %d\0A\00"
