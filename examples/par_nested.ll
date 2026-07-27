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
%Bullet = type { i32 }
%Enemies = type { %Enemy*, i64 }
@arena.Enemies.data = global %Enemy* null
@arena.Enemies.count = global i64 0
@arena.Enemies.gen = global [1024 x i64] zeroinitializer
@arena.Enemies.free = global [1024 x i64] zeroinitializer
@arena.Enemies.free_top = global i64 0
@arena.Enemies.warned = global i1 0

%Bullets = type { %Bullet*, i64 }
@arena.Bullets.data = global %Bullet* null
@arena.Bullets.count = global i64 0
@arena.Bullets.gen = global [1024 x i64] zeroinitializer
@arena.Bullets.free = global [1024 x i64] zeroinitializer
@arena.Bullets.free_top = global i64 0
@arena.Bullets.warned = global i1 0

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
  %t105 = alloca %Bullet
  %t133 = alloca %Bullet
  %t161 = alloca %Bullet
  %t189 = alloca %Bullet
  %t333 = alloca i32
  %t334 = alloca i32
  %t344 = alloca [64 x { i64, i64 }]
  %t345 = alloca i32
  %t365 = alloca i32
  %t377 = alloca { i64, i64 }
  %t405 = alloca i32
  %t406 = alloca i32
  %t416 = alloca [64 x { i64, i64 }]
  %t417 = alloca i32
  %t437 = alloca i32
  %t449 = alloca { i64, i64 }
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
  store i32 10, i32* %t50
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
  store i32 10, i32* %t78
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
  %t86 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t87 = icmp eq %Bullet* %t86, null
  br i1 %t87, label %spawn_init_27, label %spawn_ready_28
spawn_init_27:
  %t88 = getelementptr %Bullet, %Bullet* null, i32 1
  %t89 = ptrtoint %Bullet* %t88 to i64
  %t90 = mul i64 %t89, 1024
  %t91 = call i8* @malloc(i64 %t90)
  %t92 = bitcast i8* %t91 to %Bullet*
  store %Bullet* %t92, %Bullet** @arena.Bullets.data
  br label %spawn_ready_28
spawn_ready_28:
  %t93 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t94 = load i64, i64* @arena.Bullets.free_top
  %t95 = icmp sgt i64 %t94, 0
  br i1 %t95, label %spawn_reuse_29, label %spawn_grow_30
spawn_reuse_29:
  %t96 = sub i64 %t94, 1
  store i64 %t96, i64* @arena.Bullets.free_top
  %t97 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t96
  %t98 = load i64, i64* %t97
  br label %spawn_store_31
spawn_grow_30:
  %t99 = load i64, i64* @arena.Bullets.count
  %t100 = icmp slt i64 %t99, 1024
  br i1 %t100, label %spawn_grow_ok_33, label %spawn_capacity_warn_34
spawn_capacity_warn_34:
  %t101 = load i1, i1* @arena.Bullets.warned
  br i1 %t101, label %spawn_end_32, label %spawn_warn_print_35
spawn_warn_print_35:
  store i1 1, i1* @arena.Bullets.warned
  %t102 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.3, i64 0, i64 0
  call i32 @puts(i8* %t102)
  br label %spawn_end_32
spawn_grow_ok_33:
  %t103 = add i64 %t99, 1
  store i64 %t103, i64* @arena.Bullets.count
  br label %spawn_store_31
spawn_store_31:
  %t104 = phi i64 [ %t98, %spawn_reuse_29 ], [ %t99, %spawn_grow_ok_33 ]
  %t106 = getelementptr inbounds %Bullet, %Bullet* %t105, i32 0, i32 0
  store i32 0, i32* %t106
  %t107 = load %Bullet, %Bullet* %t105
  %t108 = getelementptr inbounds %Bullet, %Bullet* %t93, i64 %t104
  store %Bullet %t107, %Bullet* %t108
  %t109 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.gen, i64 0, i64 %t104
  %t110 = load i64, i64* %t109
  %t111 = add i64 %t110, 1
  store i64 %t111, i64* %t109
  %t112 = trunc i64 %t104 to i32
  br label %spawn_end_32
spawn_end_32:
  %t113 = phi i32 [ %t112, %spawn_store_31 ], [ -1, %spawn_capacity_warn_34 ], [ -1, %spawn_warn_print_35 ]
  %t114 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t115 = icmp eq %Bullet* %t114, null
  br i1 %t115, label %spawn_init_36, label %spawn_ready_37
spawn_init_36:
  %t116 = getelementptr %Bullet, %Bullet* null, i32 1
  %t117 = ptrtoint %Bullet* %t116 to i64
  %t118 = mul i64 %t117, 1024
  %t119 = call i8* @malloc(i64 %t118)
  %t120 = bitcast i8* %t119 to %Bullet*
  store %Bullet* %t120, %Bullet** @arena.Bullets.data
  br label %spawn_ready_37
spawn_ready_37:
  %t121 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t122 = load i64, i64* @arena.Bullets.free_top
  %t123 = icmp sgt i64 %t122, 0
  br i1 %t123, label %spawn_reuse_38, label %spawn_grow_39
spawn_reuse_38:
  %t124 = sub i64 %t122, 1
  store i64 %t124, i64* @arena.Bullets.free_top
  %t125 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t124
  %t126 = load i64, i64* %t125
  br label %spawn_store_40
spawn_grow_39:
  %t127 = load i64, i64* @arena.Bullets.count
  %t128 = icmp slt i64 %t127, 1024
  br i1 %t128, label %spawn_grow_ok_42, label %spawn_capacity_warn_43
spawn_capacity_warn_43:
  %t129 = load i1, i1* @arena.Bullets.warned
  br i1 %t129, label %spawn_end_41, label %spawn_warn_print_44
spawn_warn_print_44:
  store i1 1, i1* @arena.Bullets.warned
  %t130 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t130)
  br label %spawn_end_41
spawn_grow_ok_42:
  %t131 = add i64 %t127, 1
  store i64 %t131, i64* @arena.Bullets.count
  br label %spawn_store_40
spawn_store_40:
  %t132 = phi i64 [ %t126, %spawn_reuse_38 ], [ %t127, %spawn_grow_ok_42 ]
  %t134 = getelementptr inbounds %Bullet, %Bullet* %t133, i32 0, i32 0
  store i32 0, i32* %t134
  %t135 = load %Bullet, %Bullet* %t133
  %t136 = getelementptr inbounds %Bullet, %Bullet* %t121, i64 %t132
  store %Bullet %t135, %Bullet* %t136
  %t137 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.gen, i64 0, i64 %t132
  %t138 = load i64, i64* %t137
  %t139 = add i64 %t138, 1
  store i64 %t139, i64* %t137
  %t140 = trunc i64 %t132 to i32
  br label %spawn_end_41
spawn_end_41:
  %t141 = phi i32 [ %t140, %spawn_store_40 ], [ -1, %spawn_capacity_warn_43 ], [ -1, %spawn_warn_print_44 ]
  %t142 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t143 = icmp eq %Bullet* %t142, null
  br i1 %t143, label %spawn_init_45, label %spawn_ready_46
spawn_init_45:
  %t144 = getelementptr %Bullet, %Bullet* null, i32 1
  %t145 = ptrtoint %Bullet* %t144 to i64
  %t146 = mul i64 %t145, 1024
  %t147 = call i8* @malloc(i64 %t146)
  %t148 = bitcast i8* %t147 to %Bullet*
  store %Bullet* %t148, %Bullet** @arena.Bullets.data
  br label %spawn_ready_46
spawn_ready_46:
  %t149 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t150 = load i64, i64* @arena.Bullets.free_top
  %t151 = icmp sgt i64 %t150, 0
  br i1 %t151, label %spawn_reuse_47, label %spawn_grow_48
spawn_reuse_47:
  %t152 = sub i64 %t150, 1
  store i64 %t152, i64* @arena.Bullets.free_top
  %t153 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t152
  %t154 = load i64, i64* %t153
  br label %spawn_store_49
spawn_grow_48:
  %t155 = load i64, i64* @arena.Bullets.count
  %t156 = icmp slt i64 %t155, 1024
  br i1 %t156, label %spawn_grow_ok_51, label %spawn_capacity_warn_52
spawn_capacity_warn_52:
  %t157 = load i1, i1* @arena.Bullets.warned
  br i1 %t157, label %spawn_end_50, label %spawn_warn_print_53
spawn_warn_print_53:
  store i1 1, i1* @arena.Bullets.warned
  %t158 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.5, i64 0, i64 0
  call i32 @puts(i8* %t158)
  br label %spawn_end_50
spawn_grow_ok_51:
  %t159 = add i64 %t155, 1
  store i64 %t159, i64* @arena.Bullets.count
  br label %spawn_store_49
spawn_store_49:
  %t160 = phi i64 [ %t154, %spawn_reuse_47 ], [ %t155, %spawn_grow_ok_51 ]
  %t162 = getelementptr inbounds %Bullet, %Bullet* %t161, i32 0, i32 0
  store i32 0, i32* %t162
  %t163 = load %Bullet, %Bullet* %t161
  %t164 = getelementptr inbounds %Bullet, %Bullet* %t149, i64 %t160
  store %Bullet %t163, %Bullet* %t164
  %t165 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.gen, i64 0, i64 %t160
  %t166 = load i64, i64* %t165
  %t167 = add i64 %t166, 1
  store i64 %t167, i64* %t165
  %t168 = trunc i64 %t160 to i32
  br label %spawn_end_50
spawn_end_50:
  %t169 = phi i32 [ %t168, %spawn_store_49 ], [ -1, %spawn_capacity_warn_52 ], [ -1, %spawn_warn_print_53 ]
  %t170 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t171 = icmp eq %Bullet* %t170, null
  br i1 %t171, label %spawn_init_54, label %spawn_ready_55
spawn_init_54:
  %t172 = getelementptr %Bullet, %Bullet* null, i32 1
  %t173 = ptrtoint %Bullet* %t172 to i64
  %t174 = mul i64 %t173, 1024
  %t175 = call i8* @malloc(i64 %t174)
  %t176 = bitcast i8* %t175 to %Bullet*
  store %Bullet* %t176, %Bullet** @arena.Bullets.data
  br label %spawn_ready_55
spawn_ready_55:
  %t177 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t178 = load i64, i64* @arena.Bullets.free_top
  %t179 = icmp sgt i64 %t178, 0
  br i1 %t179, label %spawn_reuse_56, label %spawn_grow_57
spawn_reuse_56:
  %t180 = sub i64 %t178, 1
  store i64 %t180, i64* @arena.Bullets.free_top
  %t181 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t180
  %t182 = load i64, i64* %t181
  br label %spawn_store_58
spawn_grow_57:
  %t183 = load i64, i64* @arena.Bullets.count
  %t184 = icmp slt i64 %t183, 1024
  br i1 %t184, label %spawn_grow_ok_60, label %spawn_capacity_warn_61
spawn_capacity_warn_61:
  %t185 = load i1, i1* @arena.Bullets.warned
  br i1 %t185, label %spawn_end_59, label %spawn_warn_print_62
spawn_warn_print_62:
  store i1 1, i1* @arena.Bullets.warned
  %t186 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.6, i64 0, i64 0
  call i32 @puts(i8* %t186)
  br label %spawn_end_59
spawn_grow_ok_60:
  %t187 = add i64 %t183, 1
  store i64 %t187, i64* @arena.Bullets.count
  br label %spawn_store_58
spawn_store_58:
  %t188 = phi i64 [ %t182, %spawn_reuse_56 ], [ %t183, %spawn_grow_ok_60 ]
  %t190 = getelementptr inbounds %Bullet, %Bullet* %t189, i32 0, i32 0
  store i32 0, i32* %t190
  %t191 = load %Bullet, %Bullet* %t189
  %t192 = getelementptr inbounds %Bullet, %Bullet* %t177, i64 %t188
  store %Bullet %t191, %Bullet* %t192
  %t193 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.gen, i64 0, i64 %t188
  %t194 = load i64, i64* %t193
  %t195 = add i64 %t194, 1
  store i64 %t195, i64* %t193
  %t196 = trunc i64 %t188 to i32
  br label %spawn_end_59
spawn_end_59:
  %t197 = phi i32 [ %t196, %spawn_store_58 ], [ -1, %spawn_capacity_warn_61 ], [ -1, %spawn_warn_print_62 ]
  call void @par.pool.ensure_init()
  %t330 = load i32, i32* @par.pool.num_workers
  %t331 = sext i32 %t330 to i64
  %t332 = call i32 @GetCurrentThreadId()
  store i32 -1, i32* %t333
  store i32 0, i32* %t334
  br label %par_reentry_cond_94
par_reentry_cond_94:
  %t335 = load i32, i32* %t334
  %t336 = icmp slt i32 %t335, %t330
  br i1 %t336, label %par_reentry_body_95, label %par_reentry_end_98
par_reentry_body_95:
  %t337 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t335
  %t338 = load i32, i32* %t337
  %t339 = icmp eq i32 %t332, %t338
  br i1 %t339, label %par_reentry_match_96, label %par_reentry_step_97
par_reentry_match_96:
  store i32 %t335, i32* %t333
  br label %par_reentry_step_97
par_reentry_step_97:
  %t340 = add i32 %t335, 1
  store i32 %t340, i32* %t334
  br label %par_reentry_cond_94
par_reentry_end_98:
  %t341 = load i32, i32* %t333
  %t342 = icmp sge i32 %t341, 0
  br i1 %t342, label %par_serial_100, label %par_pooled_99
par_pooled_99:
  %t343 = load i64, i64* @arena.Enemies.count
  store i32 0, i32* %t345
  br label %par_fanout_cond_105
par_fanout_cond_105:
  %t346 = load i32, i32* %t345
  %t347 = icmp slt i32 %t346, %t330
  br i1 %t347, label %par_fanout_body_106, label %par_fanout_end_108
par_fanout_body_106:
  %t348 = sext i32 %t346 to i64
  %t349 = mul i64 %t343, %t348
  %t350 = sdiv i64 %t349, %t331
  %t351 = add i32 %t346, 1
  %t352 = sext i32 %t351 to i64
  %t353 = mul i64 %t343, %t352
  %t354 = sdiv i64 %t353, %t331
  %t355 = getelementptr inbounds [64 x { i64, i64 }], [64 x { i64, i64 }]* %t344, i32 0, i32 %t346
  %t356 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t355, i32 0, i32 0
  store i64 %t350, i64* %t356
  %t357 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t355, i32 0, i32 1
  store i64 %t354, i64* %t357
  %t358 = bitcast { i64, i64 }* %t355 to i8*
  %t359 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t346
  store i8* %t358, i8** %t359
  %t360 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t346
  store i32 (i8*)* @par_worker_63, i32 (i8*)** %t360
  %t361 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t346
  %t362 = load i8*, i8** %t361
  %t363 = call i32 @ReleaseSemaphore(i8* %t362, i32 1, i32* null)
  br label %par_fanout_step_107
par_fanout_step_107:
  %t364 = add i32 %t346, 1
  store i32 %t364, i32* %t345
  br label %par_fanout_cond_105
par_fanout_end_108:
  store i32 0, i32* %t365
  br label %par_join_wait_cond_109
par_join_wait_cond_109:
  %t366 = load i32, i32* %t365
  %t367 = icmp slt i32 %t366, %t330
  br i1 %t367, label %par_join_wait_body_110, label %par_join_wait_end_112
par_join_wait_body_110:
  %t368 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t366
  %t369 = load i8*, i8** %t368
  %t370 = call i32 @WaitForSingleObject(i8* %t369, i32 -1)
  br label %par_join_wait_step_111
par_join_wait_step_111:
  %t371 = add i32 %t366, 1
  store i32 %t371, i32* %t365
  br label %par_join_wait_cond_109
par_join_wait_end_112:
  br label %par_join_104
par_serial_100:
  %t372 = load i32, i32* @par.pool.serial_owner
  %t373 = icmp eq i32 %t372, %t341
  br i1 %t373, label %par_run_102, label %par_acquire_101
par_acquire_101:
  %t374 = load i8*, i8** @par.pool.serial_lock
  %t375 = call i32 @WaitForSingleObject(i8* %t374, i32 -1)
  store i32 %t341, i32* @par.pool.serial_owner
  br label %par_run_102
par_run_102:
  %t376 = load i64, i64* @arena.Enemies.count
  %t378 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t377, i32 0, i32 0
  store i64 0, i64* %t378
  %t379 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t377, i32 0, i32 1
  store i64 %t376, i64* %t379
  %t380 = bitcast { i64, i64 }* %t377 to i8*
  %t381 = call i32 @par_worker_63(i8* %t380)
  br i1 %t373, label %par_join_104, label %par_release_103
par_release_103:
  store i32 -1, i32* @par.pool.serial_owner
  %t382 = load i8*, i8** @par.pool.serial_lock
  %t383 = call i32 @ReleaseSemaphore(i8* %t382, i32 1, i32* null)
  br label %par_join_104
par_join_104:
  call void @par.pool.ensure_init()
  %t402 = load i32, i32* @par.pool.num_workers
  %t403 = sext i32 %t402 to i64
  %t404 = call i32 @GetCurrentThreadId()
  store i32 -1, i32* %t405
  store i32 0, i32* %t406
  br label %par_reentry_cond_119
par_reentry_cond_119:
  %t407 = load i32, i32* %t406
  %t408 = icmp slt i32 %t407, %t402
  br i1 %t408, label %par_reentry_body_120, label %par_reentry_end_123
par_reentry_body_120:
  %t409 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t407
  %t410 = load i32, i32* %t409
  %t411 = icmp eq i32 %t404, %t410
  br i1 %t411, label %par_reentry_match_121, label %par_reentry_step_122
par_reentry_match_121:
  store i32 %t407, i32* %t405
  br label %par_reentry_step_122
par_reentry_step_122:
  %t412 = add i32 %t407, 1
  store i32 %t412, i32* %t406
  br label %par_reentry_cond_119
par_reentry_end_123:
  %t413 = load i32, i32* %t405
  %t414 = icmp sge i32 %t413, 0
  br i1 %t414, label %par_serial_125, label %par_pooled_124
par_pooled_124:
  %t415 = load i64, i64* @arena.Bullets.count
  store i32 0, i32* %t417
  br label %par_fanout_cond_130
par_fanout_cond_130:
  %t418 = load i32, i32* %t417
  %t419 = icmp slt i32 %t418, %t402
  br i1 %t419, label %par_fanout_body_131, label %par_fanout_end_133
par_fanout_body_131:
  %t420 = sext i32 %t418 to i64
  %t421 = mul i64 %t415, %t420
  %t422 = sdiv i64 %t421, %t403
  %t423 = add i32 %t418, 1
  %t424 = sext i32 %t423 to i64
  %t425 = mul i64 %t415, %t424
  %t426 = sdiv i64 %t425, %t403
  %t427 = getelementptr inbounds [64 x { i64, i64 }], [64 x { i64, i64 }]* %t416, i32 0, i32 %t418
  %t428 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t427, i32 0, i32 0
  store i64 %t422, i64* %t428
  %t429 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t427, i32 0, i32 1
  store i64 %t426, i64* %t429
  %t430 = bitcast { i64, i64 }* %t427 to i8*
  %t431 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t418
  store i8* %t430, i8** %t431
  %t432 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t418
  store i32 (i8*)* @par_worker_113, i32 (i8*)** %t432
  %t433 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t418
  %t434 = load i8*, i8** %t433
  %t435 = call i32 @ReleaseSemaphore(i8* %t434, i32 1, i32* null)
  br label %par_fanout_step_132
par_fanout_step_132:
  %t436 = add i32 %t418, 1
  store i32 %t436, i32* %t417
  br label %par_fanout_cond_130
par_fanout_end_133:
  store i32 0, i32* %t437
  br label %par_join_wait_cond_134
par_join_wait_cond_134:
  %t438 = load i32, i32* %t437
  %t439 = icmp slt i32 %t438, %t402
  br i1 %t439, label %par_join_wait_body_135, label %par_join_wait_end_137
par_join_wait_body_135:
  %t440 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t438
  %t441 = load i8*, i8** %t440
  %t442 = call i32 @WaitForSingleObject(i8* %t441, i32 -1)
  br label %par_join_wait_step_136
par_join_wait_step_136:
  %t443 = add i32 %t438, 1
  store i32 %t443, i32* %t437
  br label %par_join_wait_cond_134
par_join_wait_end_137:
  br label %par_join_129
par_serial_125:
  %t444 = load i32, i32* @par.pool.serial_owner
  %t445 = icmp eq i32 %t444, %t413
  br i1 %t445, label %par_run_127, label %par_acquire_126
par_acquire_126:
  %t446 = load i8*, i8** @par.pool.serial_lock
  %t447 = call i32 @WaitForSingleObject(i8* %t446, i32 -1)
  store i32 %t413, i32* @par.pool.serial_owner
  br label %par_run_127
par_run_127:
  %t448 = load i64, i64* @arena.Bullets.count
  %t450 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t449, i32 0, i32 0
  store i64 0, i64* %t450
  %t451 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t449, i32 0, i32 1
  store i64 %t448, i64* %t451
  %t452 = bitcast { i64, i64 }* %t449 to i8*
  %t453 = call i32 @par_worker_113(i8* %t452)
  br i1 %t445, label %par_join_129, label %par_release_128
par_release_128:
  store i32 -1, i32* @par.pool.serial_owner
  %t454 = load i8*, i8** @par.pool.serial_lock
  %t455 = call i32 @ReleaseSemaphore(i8* %t454, i32 1, i32* null)
  br label %par_join_129
par_join_129:
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_69(i8* %argp) {
entry:
  %t220 = alloca i64
  %t212 = bitcast i8* %argp to { i64, i64, %Enemy* }*
  %t213 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t212, i32 0, i32 0
  %t214 = load i64, i64* %t213
  %t215 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t212, i32 0, i32 1
  %t216 = load i64, i64* %t215
  %t217 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t212, i32 0, i32 2
  %t218 = load %Enemy*, %Enemy** %t217
  %t219 = load %Bullet*, %Bullet** @arena.Bullets.data
  store i64 %t214, i64* %t220
  br label %par_cond_70
par_cond_70:
  %t221 = load i64, i64* %t220
  %t222 = icmp slt i64 %t221, %t216
  br i1 %t222, label %par_body_71, label %par_end_74
par_body_71:
  %t223 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.gen, i64 0, i64 %t221
  %t224 = load i64, i64* %t223
  %t225 = and i64 %t224, 1
  %t226 = icmp eq i64 %t225, 1
  br i1 %t226, label %par_live_72, label %par_incr_73
par_live_72:
  %t227 = getelementptr inbounds %Bullet, %Bullet* %t219, i64 %t221
  %t228 = getelementptr inbounds %Bullet, %Bullet* %t227, i32 0, i32 0
  %t229 = load i32, i32* %t228
  %t230 = add i32 %t229, 1
  %t231 = getelementptr inbounds %Bullet, %Bullet* %t227, i32 0, i32 0
  store i32 %t230, i32* %t231
  br label %par_incr_73
par_incr_73:
  %t232 = add i64 %t221, 1
  store i64 %t232, i64* %t220
  br label %par_cond_70
par_end_74:
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
  %t233 = ptrtoint i8* %idx_arg to i64
  %t234 = trunc i64 %t233 to i32
  %t235 = call i32 @GetCurrentThreadId()
  %t236 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t234
  store i32 %t235, i32* %t236
  br label %loop
loop:
  %t237 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t234
  %t238 = load i8*, i8** %t237
  %t239 = call i32 @WaitForSingleObject(i8* %t238, i32 -1)
  %t240 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t234
  %t241 = load i32 (i8*)*, i32 (i8*)** %t240
  %t242 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t234
  %t243 = load i8*, i8** %t242
  %t244 = call i32 %t241(i8* %t243)
  %t245 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t234
  %t246 = load i8*, i8** %t245
  %t247 = call i32 @ReleaseSemaphore(i8* %t246, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t248 = load i1, i1* @par.pool.inited
  br i1 %t248, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t249 = getelementptr inbounds [13 x i8], [13 x i8]* @par.pool.env_name, i64 0, i64 0
  %t250 = call i8* @getenv(i8* %t249)
  %t251 = icmp eq i8* %t250, null
  br i1 %t251, label %par_pool_detect, label %par_pool_override
par_pool_override:
  %t252 = call i32 @atoi(i8* %t250)
  br label %par_pool_clamp
par_pool_detect:
  %t253 = getelementptr inbounds [48 x i8], [48 x i8]* @par.pool.sysinfo_buf, i64 0, i64 0
  call void @GetSystemInfo(i8* %t253)
  %t254 = getelementptr inbounds [48 x i8], [48 x i8]* @par.pool.sysinfo_buf, i64 0, i64 32
  %t255 = bitcast i8* %t254 to i32*
  %t256 = load i32, i32* %t255
  br label %par_pool_clamp
par_pool_clamp:
  %t257 = phi i32 [ %t252, %par_pool_override ], [ %t256, %par_pool_detect ]
  %t258 = icmp slt i32 %t257, 4
  %t259 = select i1 %t258, i32 4, i32 %t257
  %t260 = icmp sgt i32 %t259, 64
  %t261 = select i1 %t260, i32 64, i32 %t259
  store i32 %t261, i32* @par.pool.num_workers
  %t262 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t262, i8** @par.pool.serial_lock
  store i32 0, i32* @par.pool.init_i
  br label %par_pool_thread_cond
par_pool_thread_cond:
  %t263 = load i32, i32* @par.pool.init_i
  %t264 = icmp slt i32 %t263, %t261
  br i1 %t264, label %par_pool_thread_body, label %par_pool_init_done
par_pool_thread_body:
  %t265 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t266 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t263
  store i8* %t265, i8** %t266
  %t267 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t268 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t263
  store i8* %t267, i8** %t268
  %t269 = sext i32 %t263 to i64
  %t270 = inttoptr i64 %t269 to i8*
  %t271 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* %t270, i32 0, i32* null)
  %t272 = add i32 %t263, 1
  store i32 %t272, i32* @par.pool.init_i
  br label %par_pool_thread_cond
par_pool_init_done:
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_63(i8* %argp) {
entry:
  %t204 = alloca i64
  %t276 = alloca i32
  %t277 = alloca i32
  %t287 = alloca [64 x { i64, i64, %Enemy* }]
  %t288 = alloca i32
  %t309 = alloca i32
  %t321 = alloca { i64, i64, %Enemy* }
  %t198 = bitcast i8* %argp to { i64, i64 }*
  %t199 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t198, i32 0, i32 0
  %t200 = load i64, i64* %t199
  %t201 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t198, i32 0, i32 1
  %t202 = load i64, i64* %t201
  %t203 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t200, i64* %t204
  br label %par_cond_64
par_cond_64:
  %t205 = load i64, i64* %t204
  %t206 = icmp slt i64 %t205, %t202
  br i1 %t206, label %par_body_65, label %par_end_68
par_body_65:
  %t207 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t205
  %t208 = load i64, i64* %t207
  %t209 = and i64 %t208, 1
  %t210 = icmp eq i64 %t209, 1
  br i1 %t210, label %par_live_66, label %par_incr_67
par_live_66:
  %t211 = getelementptr inbounds %Enemy, %Enemy* %t203, i64 %t205
  call void @par.pool.ensure_init()
  %t273 = load i32, i32* @par.pool.num_workers
  %t274 = sext i32 %t273 to i64
  %t275 = call i32 @GetCurrentThreadId()
  store i32 -1, i32* %t276
  store i32 0, i32* %t277
  br label %par_reentry_cond_75
par_reentry_cond_75:
  %t278 = load i32, i32* %t277
  %t279 = icmp slt i32 %t278, %t273
  br i1 %t279, label %par_reentry_body_76, label %par_reentry_end_79
par_reentry_body_76:
  %t280 = getelementptr inbounds [64 x i32], [64 x i32]* @par.pool.tid, i32 0, i32 %t278
  %t281 = load i32, i32* %t280
  %t282 = icmp eq i32 %t275, %t281
  br i1 %t282, label %par_reentry_match_77, label %par_reentry_step_78
par_reentry_match_77:
  store i32 %t278, i32* %t276
  br label %par_reentry_step_78
par_reentry_step_78:
  %t283 = add i32 %t278, 1
  store i32 %t283, i32* %t277
  br label %par_reentry_cond_75
par_reentry_end_79:
  %t284 = load i32, i32* %t276
  %t285 = icmp sge i32 %t284, 0
  br i1 %t285, label %par_serial_81, label %par_pooled_80
par_pooled_80:
  %t286 = load i64, i64* @arena.Bullets.count
  store i32 0, i32* %t288
  br label %par_fanout_cond_86
par_fanout_cond_86:
  %t289 = load i32, i32* %t288
  %t290 = icmp slt i32 %t289, %t273
  br i1 %t290, label %par_fanout_body_87, label %par_fanout_end_89
par_fanout_body_87:
  %t291 = sext i32 %t289 to i64
  %t292 = mul i64 %t286, %t291
  %t293 = sdiv i64 %t292, %t274
  %t294 = add i32 %t289, 1
  %t295 = sext i32 %t294 to i64
  %t296 = mul i64 %t286, %t295
  %t297 = sdiv i64 %t296, %t274
  %t298 = getelementptr inbounds [64 x { i64, i64, %Enemy* }], [64 x { i64, i64, %Enemy* }]* %t287, i32 0, i32 %t289
  %t299 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t298, i32 0, i32 0
  store i64 %t293, i64* %t299
  %t300 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t298, i32 0, i32 1
  store i64 %t297, i64* %t300
  %t301 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t298, i32 0, i32 2
  store %Enemy* %t211, %Enemy** %t301
  %t302 = bitcast { i64, i64, %Enemy* }* %t298 to i8*
  %t303 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.job_arg, i32 0, i32 %t289
  store i8* %t302, i8** %t303
  %t304 = getelementptr inbounds [64 x i32 (i8*)*], [64 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t289
  store i32 (i8*)* @par_worker_69, i32 (i8*)** %t304
  %t305 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.start_sem, i32 0, i32 %t289
  %t306 = load i8*, i8** %t305
  %t307 = call i32 @ReleaseSemaphore(i8* %t306, i32 1, i32* null)
  br label %par_fanout_step_88
par_fanout_step_88:
  %t308 = add i32 %t289, 1
  store i32 %t308, i32* %t288
  br label %par_fanout_cond_86
par_fanout_end_89:
  store i32 0, i32* %t309
  br label %par_join_wait_cond_90
par_join_wait_cond_90:
  %t310 = load i32, i32* %t309
  %t311 = icmp slt i32 %t310, %t273
  br i1 %t311, label %par_join_wait_body_91, label %par_join_wait_end_93
par_join_wait_body_91:
  %t312 = getelementptr inbounds [64 x i8*], [64 x i8*]* @par.pool.done_sem, i32 0, i32 %t310
  %t313 = load i8*, i8** %t312
  %t314 = call i32 @WaitForSingleObject(i8* %t313, i32 -1)
  br label %par_join_wait_step_92
par_join_wait_step_92:
  %t315 = add i32 %t310, 1
  store i32 %t315, i32* %t309
  br label %par_join_wait_cond_90
par_join_wait_end_93:
  br label %par_join_85
par_serial_81:
  %t316 = load i32, i32* @par.pool.serial_owner
  %t317 = icmp eq i32 %t316, %t284
  br i1 %t317, label %par_run_83, label %par_acquire_82
par_acquire_82:
  %t318 = load i8*, i8** @par.pool.serial_lock
  %t319 = call i32 @WaitForSingleObject(i8* %t318, i32 -1)
  store i32 %t284, i32* @par.pool.serial_owner
  br label %par_run_83
par_run_83:
  %t320 = load i64, i64* @arena.Bullets.count
  %t322 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t321, i32 0, i32 0
  store i64 0, i64* %t322
  %t323 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t321, i32 0, i32 1
  store i64 %t320, i64* %t323
  %t324 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t321, i32 0, i32 2
  store %Enemy* %t211, %Enemy** %t324
  %t325 = bitcast { i64, i64, %Enemy* }* %t321 to i8*
  %t326 = call i32 @par_worker_69(i8* %t325)
  br i1 %t317, label %par_join_85, label %par_release_84
par_release_84:
  store i32 -1, i32* @par.pool.serial_owner
  %t327 = load i8*, i8** @par.pool.serial_lock
  %t328 = call i32 @ReleaseSemaphore(i8* %t327, i32 1, i32* null)
  br label %par_join_85
par_join_85:
  br label %par_incr_67
par_incr_67:
  %t329 = add i64 %t205, 1
  store i64 %t329, i64* %t204
  br label %par_cond_64
par_end_68:
  ret i32 0
}


define i32 @par_worker_113(i8* %argp) {
entry:
  %t390 = alloca i64
  %t384 = bitcast i8* %argp to { i64, i64 }*
  %t385 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t384, i32 0, i32 0
  %t386 = load i64, i64* %t385
  %t387 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t384, i32 0, i32 1
  %t388 = load i64, i64* %t387
  %t389 = load %Bullet*, %Bullet** @arena.Bullets.data
  store i64 %t386, i64* %t390
  br label %par_cond_114
par_cond_114:
  %t391 = load i64, i64* %t390
  %t392 = icmp slt i64 %t391, %t388
  br i1 %t392, label %par_body_115, label %par_end_118
par_body_115:
  %t393 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.gen, i64 0, i64 %t391
  %t394 = load i64, i64* %t393
  %t395 = and i64 %t394, 1
  %t396 = icmp eq i64 %t395, 1
  br i1 %t396, label %par_live_116, label %par_incr_117
par_live_116:
  %t397 = getelementptr inbounds %Bullet, %Bullet* %t389, i64 %t391
  %t398 = getelementptr inbounds %Bullet, %Bullet* %t397, i32 0, i32 0
  %t399 = load i32, i32* %t398
  %t400 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t400, i32 %t399)
  br label %par_incr_117
par_incr_117:
  %t401 = add i64 %t391, 1
  store i64 %t401, i64* %t390
  br label %par_cond_114
par_end_118:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.1 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.2 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.3 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Bullets` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.4 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Bullets` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.5 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Bullets` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.6 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Bullets` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.7 = private unnamed_addr constant [9 x i8] c"dmg: %d\0A\00"
