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
  %t15 = alloca i8*
  %t25 = alloca i8*
  %t30 = alloca [64 x i8]
  %t37 = alloca i8
  %t38 = alloca [8 x i8]
  %t895 = alloca [40 x i8]
  %t897 = alloca i64
  %t912 = alloca i8*
  %t920 = alloca i64
  %t925 = alloca i64
  %t944 = alloca i8*
  %t954 = alloca i8*
  %t959 = alloca [64 x i8]
  %t966 = alloca i8
  %t967 = alloca [8 x i8]
  %t1824 = alloca [40 x i8]
  %t1826 = alloca i64
  %t1841 = alloca i8*
  %t1849 = alloca i64
  %t1854 = alloca i64
  %t1884 = alloca i8*
  %t1892 = alloca i8*
  %t1910 = alloca i1
  %t1911 = alloca i32
  %t1912 = alloca i32
  %t1985 = alloca i1
  %t1986 = alloca i32
  %t1987 = alloca i32
  %t1988 = alloca i1
  %t1989 = alloca i32
  %t1990 = alloca i32
  %t1991 = alloca i32
  %t2079 = alloca i32
  %t2095 = alloca i8*
  %t2100 = alloca [64 x i8]
  %t2107 = alloca i8
  %t2108 = alloca [8 x i8]
  %t2965 = alloca [40 x i8]
  %t2967 = alloca i64
  %t2982 = alloca i8*
  %t2990 = alloca i64
  %t2995 = alloca i64
  %t3014 = alloca i32
  %t3025 = alloca i32
  %t3036 = alloca i32
  %t3047 = alloca i32
  %t3051 = alloca i1
  %t3052 = alloca [56 x i8]
  %t3111 = alloca i32
  %t3112 = alloca i32
  %t3113 = alloca i64
  %t3139 = alloca [16 x i8]
  %t3148 = alloca [16 x i8]
  %t3161 = alloca i8*
  %t3189 = alloca i32
  %t3190 = alloca i32
  %t3191 = alloca i64
  %t3217 = alloca [16 x i8]
  %t3226 = alloca [16 x i8]
  %t3239 = alloca { i32, i32 }
  %t3249 = alloca i32
  %t3250 = alloca i32
  %t3251 = alloca i32
  %t3252 = alloca i64
  %t3289 = alloca { i32, i32 }
  %t3328 = alloca i32
  %t3329 = alloca i32
  %t3330 = alloca i64
  %t3356 = alloca [16 x i8]
  %t3365 = alloca [16 x i8]
  %t3406 = alloca i32
  %t3407 = alloca i32
  %t3408 = alloca i64
  %t3434 = alloca [16 x i8]
  %t3443 = alloca [16 x i8]
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = getelementptr inbounds { i64, i8*, [24 x i8] }, { i64, i8*, [24 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t4 = call i32 @SDL_Init(i32 32)
  %t5 = icmp ne i32 %t4, 0
  br i1 %t5, label %sdl_init_fail_0, label %sdl_init_ok_1
sdl_init_fail_0:
  call void @star_rc_release(i8* %t3)
  br label %window_create_end_2
sdl_init_ok_1:
  %t6 = call i8* @SDL_CreateWindow(i8* %t3, i32 536805376, i32 536805376, i32 640, i32 480, i32 0)
  call void @star_rc_release(i8* %t3)
  %t7 = icmp eq i8* %t6, null
  br i1 %t7, label %sdl_window_fail_3, label %sdl_window_ok_4
sdl_window_fail_3:
  br label %window_create_end_2
sdl_window_ok_4:
  %t8 = call i8* @SDL_CreateRenderer(i8* %t6, i32 -1, i32 0)
  %t9 = icmp eq i8* %t8, null
  br i1 %t9, label %sdl_renderer_fail_5, label %sdl_renderer_ok_6
sdl_renderer_fail_5:
  call void @SDL_DestroyWindow(i8* %t6)
  br label %window_create_end_2
sdl_renderer_ok_6:
  br label %window_create_end_2
window_create_end_2:
  %t10 = phi i8* [ null, %sdl_init_fail_0 ], [ null, %sdl_window_fail_3 ], [ null, %sdl_renderer_fail_5 ], [ %t6, %sdl_renderer_ok_6 ]
  store i8* %t10, i8** %t2
  %t11 = load i8*, i8** %t2
  %t12 = icmp eq i8* %t11, null
  br i1 %t12, label %if_then_7, label %if_else_8
if_then_7:
  %t13 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.1, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t13)
  call i32 (i8*, ...) @printf(i8* %t13)
  %t14 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t14)
  ret i32 0
if_else_8:
  br label %if_end_9
if_end_9:
  %t16 = load i8*, i8** %t2
  %t17 = icmp eq i8* %t16, null
  br i1 %t17, label %sdl_null_window_10, label %sdl_window_handle_ok_11
sdl_null_window_10:
  %t18 = getelementptr inbounds [82 x i8], [82 x i8]* @.str.3, i64 0, i64 0
  call i32 @puts(i8* %t18)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_11:
  %t19 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t20 = icmp sgt i32 32, 0
  %t21 = select i1 %t20, i32 32, i32 1
  %t22 = sub i32 0, %t21
  %t23 = call i8* @CreateFontA(i32 %t22, i32 0, i32 0, i32 0, i32 400, i32 0, i32 0, i32 0, i32 1, i32 4, i32 0, i32 4, i32 0, i8* %t19)
  call void @star_rc_release(i8* %t19)
  %t24 = icmp eq i8* %t23, null
  br i1 %t24, label %font_load_system_fail_12, label %font_load_system_ok_13
font_load_system_fail_12:
  br label %font_load_system_end_14
font_load_system_ok_13:
  store i8* null, i8** %t25
  %t26 = call i8* @SDL_GetRenderer(i8* %t16)
  %t27 = call i8* @CreateCompatibleDC(i8* null)
  %t28 = icmp eq i8* %t27, null
  br i1 %t28, label %rasterize_memdc_fail_16, label %rasterize_memdc_ok_17
rasterize_memdc_fail_16:
  call i32 @DeleteObject(i8* %t23)
  br label %rasterize_end_15
rasterize_memdc_ok_17:
  %t29 = call i8* @SelectObject(i8* %t27, i8* %t23)
  call i32 @SetBkMode(i8* %t27, i32 1)
  call i32 @SetTextColor(i8* %t27, i32 16777215)
  %t31 = getelementptr inbounds [64 x i8], [64 x i8]* %t30, i64 0, i64 0
  call i32 @GetTextMetricsA(i8* %t27, i8* %t31)
  %t32 = bitcast i8* %t31 to i32*
  %t33 = load i32, i32* %t32
  %t34 = icmp sgt i32 %t33, 0
  %t35 = select i1 %t34, i32 %t33, i32 1
  %t36 = call i8* @malloc(i64 772)
  %t39 = bitcast [8 x i8]* %t38 to i32*
  store i8 32, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t40 = load i32, i32* %t39
  %t41 = icmp sgt i32 %t40, 0
  %t42 = select i1 %t41, i32 %t40, i32 1
  %t43 = getelementptr inbounds i8, i8* %t36, i64 12
  %t44 = bitcast i8* %t43 to i32*
  store i32 0, i32* %t44
  %t45 = getelementptr inbounds i8, i8* %t36, i64 392
  %t46 = bitcast i8* %t45 to i32*
  store i32 %t42, i32* %t46
  %t47 = add i32 0, %t42
  %t48 = add i32 %t47, 3
  store i8 33, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t49 = load i32, i32* %t39
  %t50 = icmp sgt i32 %t49, 0
  %t51 = select i1 %t50, i32 %t49, i32 1
  %t52 = getelementptr inbounds i8, i8* %t36, i64 16
  %t53 = bitcast i8* %t52 to i32*
  store i32 %t48, i32* %t53
  %t54 = getelementptr inbounds i8, i8* %t36, i64 396
  %t55 = bitcast i8* %t54 to i32*
  store i32 %t51, i32* %t55
  %t56 = add i32 %t48, %t51
  %t57 = add i32 %t56, 3
  store i8 34, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t58 = load i32, i32* %t39
  %t59 = icmp sgt i32 %t58, 0
  %t60 = select i1 %t59, i32 %t58, i32 1
  %t61 = getelementptr inbounds i8, i8* %t36, i64 20
  %t62 = bitcast i8* %t61 to i32*
  store i32 %t57, i32* %t62
  %t63 = getelementptr inbounds i8, i8* %t36, i64 400
  %t64 = bitcast i8* %t63 to i32*
  store i32 %t60, i32* %t64
  %t65 = add i32 %t57, %t60
  %t66 = add i32 %t65, 3
  store i8 35, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t67 = load i32, i32* %t39
  %t68 = icmp sgt i32 %t67, 0
  %t69 = select i1 %t68, i32 %t67, i32 1
  %t70 = getelementptr inbounds i8, i8* %t36, i64 24
  %t71 = bitcast i8* %t70 to i32*
  store i32 %t66, i32* %t71
  %t72 = getelementptr inbounds i8, i8* %t36, i64 404
  %t73 = bitcast i8* %t72 to i32*
  store i32 %t69, i32* %t73
  %t74 = add i32 %t66, %t69
  %t75 = add i32 %t74, 3
  store i8 36, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t76 = load i32, i32* %t39
  %t77 = icmp sgt i32 %t76, 0
  %t78 = select i1 %t77, i32 %t76, i32 1
  %t79 = getelementptr inbounds i8, i8* %t36, i64 28
  %t80 = bitcast i8* %t79 to i32*
  store i32 %t75, i32* %t80
  %t81 = getelementptr inbounds i8, i8* %t36, i64 408
  %t82 = bitcast i8* %t81 to i32*
  store i32 %t78, i32* %t82
  %t83 = add i32 %t75, %t78
  %t84 = add i32 %t83, 3
  store i8 37, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t85 = load i32, i32* %t39
  %t86 = icmp sgt i32 %t85, 0
  %t87 = select i1 %t86, i32 %t85, i32 1
  %t88 = getelementptr inbounds i8, i8* %t36, i64 32
  %t89 = bitcast i8* %t88 to i32*
  store i32 %t84, i32* %t89
  %t90 = getelementptr inbounds i8, i8* %t36, i64 412
  %t91 = bitcast i8* %t90 to i32*
  store i32 %t87, i32* %t91
  %t92 = add i32 %t84, %t87
  %t93 = add i32 %t92, 3
  store i8 38, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t94 = load i32, i32* %t39
  %t95 = icmp sgt i32 %t94, 0
  %t96 = select i1 %t95, i32 %t94, i32 1
  %t97 = getelementptr inbounds i8, i8* %t36, i64 36
  %t98 = bitcast i8* %t97 to i32*
  store i32 %t93, i32* %t98
  %t99 = getelementptr inbounds i8, i8* %t36, i64 416
  %t100 = bitcast i8* %t99 to i32*
  store i32 %t96, i32* %t100
  %t101 = add i32 %t93, %t96
  %t102 = add i32 %t101, 3
  store i8 39, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t103 = load i32, i32* %t39
  %t104 = icmp sgt i32 %t103, 0
  %t105 = select i1 %t104, i32 %t103, i32 1
  %t106 = getelementptr inbounds i8, i8* %t36, i64 40
  %t107 = bitcast i8* %t106 to i32*
  store i32 %t102, i32* %t107
  %t108 = getelementptr inbounds i8, i8* %t36, i64 420
  %t109 = bitcast i8* %t108 to i32*
  store i32 %t105, i32* %t109
  %t110 = add i32 %t102, %t105
  %t111 = add i32 %t110, 3
  store i8 40, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t112 = load i32, i32* %t39
  %t113 = icmp sgt i32 %t112, 0
  %t114 = select i1 %t113, i32 %t112, i32 1
  %t115 = getelementptr inbounds i8, i8* %t36, i64 44
  %t116 = bitcast i8* %t115 to i32*
  store i32 %t111, i32* %t116
  %t117 = getelementptr inbounds i8, i8* %t36, i64 424
  %t118 = bitcast i8* %t117 to i32*
  store i32 %t114, i32* %t118
  %t119 = add i32 %t111, %t114
  %t120 = add i32 %t119, 3
  store i8 41, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t121 = load i32, i32* %t39
  %t122 = icmp sgt i32 %t121, 0
  %t123 = select i1 %t122, i32 %t121, i32 1
  %t124 = getelementptr inbounds i8, i8* %t36, i64 48
  %t125 = bitcast i8* %t124 to i32*
  store i32 %t120, i32* %t125
  %t126 = getelementptr inbounds i8, i8* %t36, i64 428
  %t127 = bitcast i8* %t126 to i32*
  store i32 %t123, i32* %t127
  %t128 = add i32 %t120, %t123
  %t129 = add i32 %t128, 3
  store i8 42, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t130 = load i32, i32* %t39
  %t131 = icmp sgt i32 %t130, 0
  %t132 = select i1 %t131, i32 %t130, i32 1
  %t133 = getelementptr inbounds i8, i8* %t36, i64 52
  %t134 = bitcast i8* %t133 to i32*
  store i32 %t129, i32* %t134
  %t135 = getelementptr inbounds i8, i8* %t36, i64 432
  %t136 = bitcast i8* %t135 to i32*
  store i32 %t132, i32* %t136
  %t137 = add i32 %t129, %t132
  %t138 = add i32 %t137, 3
  store i8 43, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t139 = load i32, i32* %t39
  %t140 = icmp sgt i32 %t139, 0
  %t141 = select i1 %t140, i32 %t139, i32 1
  %t142 = getelementptr inbounds i8, i8* %t36, i64 56
  %t143 = bitcast i8* %t142 to i32*
  store i32 %t138, i32* %t143
  %t144 = getelementptr inbounds i8, i8* %t36, i64 436
  %t145 = bitcast i8* %t144 to i32*
  store i32 %t141, i32* %t145
  %t146 = add i32 %t138, %t141
  %t147 = add i32 %t146, 3
  store i8 44, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t148 = load i32, i32* %t39
  %t149 = icmp sgt i32 %t148, 0
  %t150 = select i1 %t149, i32 %t148, i32 1
  %t151 = getelementptr inbounds i8, i8* %t36, i64 60
  %t152 = bitcast i8* %t151 to i32*
  store i32 %t147, i32* %t152
  %t153 = getelementptr inbounds i8, i8* %t36, i64 440
  %t154 = bitcast i8* %t153 to i32*
  store i32 %t150, i32* %t154
  %t155 = add i32 %t147, %t150
  %t156 = add i32 %t155, 3
  store i8 45, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t157 = load i32, i32* %t39
  %t158 = icmp sgt i32 %t157, 0
  %t159 = select i1 %t158, i32 %t157, i32 1
  %t160 = getelementptr inbounds i8, i8* %t36, i64 64
  %t161 = bitcast i8* %t160 to i32*
  store i32 %t156, i32* %t161
  %t162 = getelementptr inbounds i8, i8* %t36, i64 444
  %t163 = bitcast i8* %t162 to i32*
  store i32 %t159, i32* %t163
  %t164 = add i32 %t156, %t159
  %t165 = add i32 %t164, 3
  store i8 46, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t166 = load i32, i32* %t39
  %t167 = icmp sgt i32 %t166, 0
  %t168 = select i1 %t167, i32 %t166, i32 1
  %t169 = getelementptr inbounds i8, i8* %t36, i64 68
  %t170 = bitcast i8* %t169 to i32*
  store i32 %t165, i32* %t170
  %t171 = getelementptr inbounds i8, i8* %t36, i64 448
  %t172 = bitcast i8* %t171 to i32*
  store i32 %t168, i32* %t172
  %t173 = add i32 %t165, %t168
  %t174 = add i32 %t173, 3
  store i8 47, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t175 = load i32, i32* %t39
  %t176 = icmp sgt i32 %t175, 0
  %t177 = select i1 %t176, i32 %t175, i32 1
  %t178 = getelementptr inbounds i8, i8* %t36, i64 72
  %t179 = bitcast i8* %t178 to i32*
  store i32 %t174, i32* %t179
  %t180 = getelementptr inbounds i8, i8* %t36, i64 452
  %t181 = bitcast i8* %t180 to i32*
  store i32 %t177, i32* %t181
  %t182 = add i32 %t174, %t177
  %t183 = add i32 %t182, 3
  store i8 48, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t184 = load i32, i32* %t39
  %t185 = icmp sgt i32 %t184, 0
  %t186 = select i1 %t185, i32 %t184, i32 1
  %t187 = getelementptr inbounds i8, i8* %t36, i64 76
  %t188 = bitcast i8* %t187 to i32*
  store i32 %t183, i32* %t188
  %t189 = getelementptr inbounds i8, i8* %t36, i64 456
  %t190 = bitcast i8* %t189 to i32*
  store i32 %t186, i32* %t190
  %t191 = add i32 %t183, %t186
  %t192 = add i32 %t191, 3
  store i8 49, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t193 = load i32, i32* %t39
  %t194 = icmp sgt i32 %t193, 0
  %t195 = select i1 %t194, i32 %t193, i32 1
  %t196 = getelementptr inbounds i8, i8* %t36, i64 80
  %t197 = bitcast i8* %t196 to i32*
  store i32 %t192, i32* %t197
  %t198 = getelementptr inbounds i8, i8* %t36, i64 460
  %t199 = bitcast i8* %t198 to i32*
  store i32 %t195, i32* %t199
  %t200 = add i32 %t192, %t195
  %t201 = add i32 %t200, 3
  store i8 50, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t202 = load i32, i32* %t39
  %t203 = icmp sgt i32 %t202, 0
  %t204 = select i1 %t203, i32 %t202, i32 1
  %t205 = getelementptr inbounds i8, i8* %t36, i64 84
  %t206 = bitcast i8* %t205 to i32*
  store i32 %t201, i32* %t206
  %t207 = getelementptr inbounds i8, i8* %t36, i64 464
  %t208 = bitcast i8* %t207 to i32*
  store i32 %t204, i32* %t208
  %t209 = add i32 %t201, %t204
  %t210 = add i32 %t209, 3
  store i8 51, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t211 = load i32, i32* %t39
  %t212 = icmp sgt i32 %t211, 0
  %t213 = select i1 %t212, i32 %t211, i32 1
  %t214 = getelementptr inbounds i8, i8* %t36, i64 88
  %t215 = bitcast i8* %t214 to i32*
  store i32 %t210, i32* %t215
  %t216 = getelementptr inbounds i8, i8* %t36, i64 468
  %t217 = bitcast i8* %t216 to i32*
  store i32 %t213, i32* %t217
  %t218 = add i32 %t210, %t213
  %t219 = add i32 %t218, 3
  store i8 52, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t220 = load i32, i32* %t39
  %t221 = icmp sgt i32 %t220, 0
  %t222 = select i1 %t221, i32 %t220, i32 1
  %t223 = getelementptr inbounds i8, i8* %t36, i64 92
  %t224 = bitcast i8* %t223 to i32*
  store i32 %t219, i32* %t224
  %t225 = getelementptr inbounds i8, i8* %t36, i64 472
  %t226 = bitcast i8* %t225 to i32*
  store i32 %t222, i32* %t226
  %t227 = add i32 %t219, %t222
  %t228 = add i32 %t227, 3
  store i8 53, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t229 = load i32, i32* %t39
  %t230 = icmp sgt i32 %t229, 0
  %t231 = select i1 %t230, i32 %t229, i32 1
  %t232 = getelementptr inbounds i8, i8* %t36, i64 96
  %t233 = bitcast i8* %t232 to i32*
  store i32 %t228, i32* %t233
  %t234 = getelementptr inbounds i8, i8* %t36, i64 476
  %t235 = bitcast i8* %t234 to i32*
  store i32 %t231, i32* %t235
  %t236 = add i32 %t228, %t231
  %t237 = add i32 %t236, 3
  store i8 54, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t238 = load i32, i32* %t39
  %t239 = icmp sgt i32 %t238, 0
  %t240 = select i1 %t239, i32 %t238, i32 1
  %t241 = getelementptr inbounds i8, i8* %t36, i64 100
  %t242 = bitcast i8* %t241 to i32*
  store i32 %t237, i32* %t242
  %t243 = getelementptr inbounds i8, i8* %t36, i64 480
  %t244 = bitcast i8* %t243 to i32*
  store i32 %t240, i32* %t244
  %t245 = add i32 %t237, %t240
  %t246 = add i32 %t245, 3
  store i8 55, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t247 = load i32, i32* %t39
  %t248 = icmp sgt i32 %t247, 0
  %t249 = select i1 %t248, i32 %t247, i32 1
  %t250 = getelementptr inbounds i8, i8* %t36, i64 104
  %t251 = bitcast i8* %t250 to i32*
  store i32 %t246, i32* %t251
  %t252 = getelementptr inbounds i8, i8* %t36, i64 484
  %t253 = bitcast i8* %t252 to i32*
  store i32 %t249, i32* %t253
  %t254 = add i32 %t246, %t249
  %t255 = add i32 %t254, 3
  store i8 56, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t256 = load i32, i32* %t39
  %t257 = icmp sgt i32 %t256, 0
  %t258 = select i1 %t257, i32 %t256, i32 1
  %t259 = getelementptr inbounds i8, i8* %t36, i64 108
  %t260 = bitcast i8* %t259 to i32*
  store i32 %t255, i32* %t260
  %t261 = getelementptr inbounds i8, i8* %t36, i64 488
  %t262 = bitcast i8* %t261 to i32*
  store i32 %t258, i32* %t262
  %t263 = add i32 %t255, %t258
  %t264 = add i32 %t263, 3
  store i8 57, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t265 = load i32, i32* %t39
  %t266 = icmp sgt i32 %t265, 0
  %t267 = select i1 %t266, i32 %t265, i32 1
  %t268 = getelementptr inbounds i8, i8* %t36, i64 112
  %t269 = bitcast i8* %t268 to i32*
  store i32 %t264, i32* %t269
  %t270 = getelementptr inbounds i8, i8* %t36, i64 492
  %t271 = bitcast i8* %t270 to i32*
  store i32 %t267, i32* %t271
  %t272 = add i32 %t264, %t267
  %t273 = add i32 %t272, 3
  store i8 58, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t274 = load i32, i32* %t39
  %t275 = icmp sgt i32 %t274, 0
  %t276 = select i1 %t275, i32 %t274, i32 1
  %t277 = getelementptr inbounds i8, i8* %t36, i64 116
  %t278 = bitcast i8* %t277 to i32*
  store i32 %t273, i32* %t278
  %t279 = getelementptr inbounds i8, i8* %t36, i64 496
  %t280 = bitcast i8* %t279 to i32*
  store i32 %t276, i32* %t280
  %t281 = add i32 %t273, %t276
  %t282 = add i32 %t281, 3
  store i8 59, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t283 = load i32, i32* %t39
  %t284 = icmp sgt i32 %t283, 0
  %t285 = select i1 %t284, i32 %t283, i32 1
  %t286 = getelementptr inbounds i8, i8* %t36, i64 120
  %t287 = bitcast i8* %t286 to i32*
  store i32 %t282, i32* %t287
  %t288 = getelementptr inbounds i8, i8* %t36, i64 500
  %t289 = bitcast i8* %t288 to i32*
  store i32 %t285, i32* %t289
  %t290 = add i32 %t282, %t285
  %t291 = add i32 %t290, 3
  store i8 60, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t292 = load i32, i32* %t39
  %t293 = icmp sgt i32 %t292, 0
  %t294 = select i1 %t293, i32 %t292, i32 1
  %t295 = getelementptr inbounds i8, i8* %t36, i64 124
  %t296 = bitcast i8* %t295 to i32*
  store i32 %t291, i32* %t296
  %t297 = getelementptr inbounds i8, i8* %t36, i64 504
  %t298 = bitcast i8* %t297 to i32*
  store i32 %t294, i32* %t298
  %t299 = add i32 %t291, %t294
  %t300 = add i32 %t299, 3
  store i8 61, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t301 = load i32, i32* %t39
  %t302 = icmp sgt i32 %t301, 0
  %t303 = select i1 %t302, i32 %t301, i32 1
  %t304 = getelementptr inbounds i8, i8* %t36, i64 128
  %t305 = bitcast i8* %t304 to i32*
  store i32 %t300, i32* %t305
  %t306 = getelementptr inbounds i8, i8* %t36, i64 508
  %t307 = bitcast i8* %t306 to i32*
  store i32 %t303, i32* %t307
  %t308 = add i32 %t300, %t303
  %t309 = add i32 %t308, 3
  store i8 62, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t310 = load i32, i32* %t39
  %t311 = icmp sgt i32 %t310, 0
  %t312 = select i1 %t311, i32 %t310, i32 1
  %t313 = getelementptr inbounds i8, i8* %t36, i64 132
  %t314 = bitcast i8* %t313 to i32*
  store i32 %t309, i32* %t314
  %t315 = getelementptr inbounds i8, i8* %t36, i64 512
  %t316 = bitcast i8* %t315 to i32*
  store i32 %t312, i32* %t316
  %t317 = add i32 %t309, %t312
  %t318 = add i32 %t317, 3
  store i8 63, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t319 = load i32, i32* %t39
  %t320 = icmp sgt i32 %t319, 0
  %t321 = select i1 %t320, i32 %t319, i32 1
  %t322 = getelementptr inbounds i8, i8* %t36, i64 136
  %t323 = bitcast i8* %t322 to i32*
  store i32 %t318, i32* %t323
  %t324 = getelementptr inbounds i8, i8* %t36, i64 516
  %t325 = bitcast i8* %t324 to i32*
  store i32 %t321, i32* %t325
  %t326 = add i32 %t318, %t321
  %t327 = add i32 %t326, 3
  store i8 64, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t328 = load i32, i32* %t39
  %t329 = icmp sgt i32 %t328, 0
  %t330 = select i1 %t329, i32 %t328, i32 1
  %t331 = getelementptr inbounds i8, i8* %t36, i64 140
  %t332 = bitcast i8* %t331 to i32*
  store i32 %t327, i32* %t332
  %t333 = getelementptr inbounds i8, i8* %t36, i64 520
  %t334 = bitcast i8* %t333 to i32*
  store i32 %t330, i32* %t334
  %t335 = add i32 %t327, %t330
  %t336 = add i32 %t335, 3
  store i8 65, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t337 = load i32, i32* %t39
  %t338 = icmp sgt i32 %t337, 0
  %t339 = select i1 %t338, i32 %t337, i32 1
  %t340 = getelementptr inbounds i8, i8* %t36, i64 144
  %t341 = bitcast i8* %t340 to i32*
  store i32 %t336, i32* %t341
  %t342 = getelementptr inbounds i8, i8* %t36, i64 524
  %t343 = bitcast i8* %t342 to i32*
  store i32 %t339, i32* %t343
  %t344 = add i32 %t336, %t339
  %t345 = add i32 %t344, 3
  store i8 66, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t346 = load i32, i32* %t39
  %t347 = icmp sgt i32 %t346, 0
  %t348 = select i1 %t347, i32 %t346, i32 1
  %t349 = getelementptr inbounds i8, i8* %t36, i64 148
  %t350 = bitcast i8* %t349 to i32*
  store i32 %t345, i32* %t350
  %t351 = getelementptr inbounds i8, i8* %t36, i64 528
  %t352 = bitcast i8* %t351 to i32*
  store i32 %t348, i32* %t352
  %t353 = add i32 %t345, %t348
  %t354 = add i32 %t353, 3
  store i8 67, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t355 = load i32, i32* %t39
  %t356 = icmp sgt i32 %t355, 0
  %t357 = select i1 %t356, i32 %t355, i32 1
  %t358 = getelementptr inbounds i8, i8* %t36, i64 152
  %t359 = bitcast i8* %t358 to i32*
  store i32 %t354, i32* %t359
  %t360 = getelementptr inbounds i8, i8* %t36, i64 532
  %t361 = bitcast i8* %t360 to i32*
  store i32 %t357, i32* %t361
  %t362 = add i32 %t354, %t357
  %t363 = add i32 %t362, 3
  store i8 68, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t364 = load i32, i32* %t39
  %t365 = icmp sgt i32 %t364, 0
  %t366 = select i1 %t365, i32 %t364, i32 1
  %t367 = getelementptr inbounds i8, i8* %t36, i64 156
  %t368 = bitcast i8* %t367 to i32*
  store i32 %t363, i32* %t368
  %t369 = getelementptr inbounds i8, i8* %t36, i64 536
  %t370 = bitcast i8* %t369 to i32*
  store i32 %t366, i32* %t370
  %t371 = add i32 %t363, %t366
  %t372 = add i32 %t371, 3
  store i8 69, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t373 = load i32, i32* %t39
  %t374 = icmp sgt i32 %t373, 0
  %t375 = select i1 %t374, i32 %t373, i32 1
  %t376 = getelementptr inbounds i8, i8* %t36, i64 160
  %t377 = bitcast i8* %t376 to i32*
  store i32 %t372, i32* %t377
  %t378 = getelementptr inbounds i8, i8* %t36, i64 540
  %t379 = bitcast i8* %t378 to i32*
  store i32 %t375, i32* %t379
  %t380 = add i32 %t372, %t375
  %t381 = add i32 %t380, 3
  store i8 70, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t382 = load i32, i32* %t39
  %t383 = icmp sgt i32 %t382, 0
  %t384 = select i1 %t383, i32 %t382, i32 1
  %t385 = getelementptr inbounds i8, i8* %t36, i64 164
  %t386 = bitcast i8* %t385 to i32*
  store i32 %t381, i32* %t386
  %t387 = getelementptr inbounds i8, i8* %t36, i64 544
  %t388 = bitcast i8* %t387 to i32*
  store i32 %t384, i32* %t388
  %t389 = add i32 %t381, %t384
  %t390 = add i32 %t389, 3
  store i8 71, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t391 = load i32, i32* %t39
  %t392 = icmp sgt i32 %t391, 0
  %t393 = select i1 %t392, i32 %t391, i32 1
  %t394 = getelementptr inbounds i8, i8* %t36, i64 168
  %t395 = bitcast i8* %t394 to i32*
  store i32 %t390, i32* %t395
  %t396 = getelementptr inbounds i8, i8* %t36, i64 548
  %t397 = bitcast i8* %t396 to i32*
  store i32 %t393, i32* %t397
  %t398 = add i32 %t390, %t393
  %t399 = add i32 %t398, 3
  store i8 72, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t400 = load i32, i32* %t39
  %t401 = icmp sgt i32 %t400, 0
  %t402 = select i1 %t401, i32 %t400, i32 1
  %t403 = getelementptr inbounds i8, i8* %t36, i64 172
  %t404 = bitcast i8* %t403 to i32*
  store i32 %t399, i32* %t404
  %t405 = getelementptr inbounds i8, i8* %t36, i64 552
  %t406 = bitcast i8* %t405 to i32*
  store i32 %t402, i32* %t406
  %t407 = add i32 %t399, %t402
  %t408 = add i32 %t407, 3
  store i8 73, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t409 = load i32, i32* %t39
  %t410 = icmp sgt i32 %t409, 0
  %t411 = select i1 %t410, i32 %t409, i32 1
  %t412 = getelementptr inbounds i8, i8* %t36, i64 176
  %t413 = bitcast i8* %t412 to i32*
  store i32 %t408, i32* %t413
  %t414 = getelementptr inbounds i8, i8* %t36, i64 556
  %t415 = bitcast i8* %t414 to i32*
  store i32 %t411, i32* %t415
  %t416 = add i32 %t408, %t411
  %t417 = add i32 %t416, 3
  store i8 74, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t418 = load i32, i32* %t39
  %t419 = icmp sgt i32 %t418, 0
  %t420 = select i1 %t419, i32 %t418, i32 1
  %t421 = getelementptr inbounds i8, i8* %t36, i64 180
  %t422 = bitcast i8* %t421 to i32*
  store i32 %t417, i32* %t422
  %t423 = getelementptr inbounds i8, i8* %t36, i64 560
  %t424 = bitcast i8* %t423 to i32*
  store i32 %t420, i32* %t424
  %t425 = add i32 %t417, %t420
  %t426 = add i32 %t425, 3
  store i8 75, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t427 = load i32, i32* %t39
  %t428 = icmp sgt i32 %t427, 0
  %t429 = select i1 %t428, i32 %t427, i32 1
  %t430 = getelementptr inbounds i8, i8* %t36, i64 184
  %t431 = bitcast i8* %t430 to i32*
  store i32 %t426, i32* %t431
  %t432 = getelementptr inbounds i8, i8* %t36, i64 564
  %t433 = bitcast i8* %t432 to i32*
  store i32 %t429, i32* %t433
  %t434 = add i32 %t426, %t429
  %t435 = add i32 %t434, 3
  store i8 76, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t436 = load i32, i32* %t39
  %t437 = icmp sgt i32 %t436, 0
  %t438 = select i1 %t437, i32 %t436, i32 1
  %t439 = getelementptr inbounds i8, i8* %t36, i64 188
  %t440 = bitcast i8* %t439 to i32*
  store i32 %t435, i32* %t440
  %t441 = getelementptr inbounds i8, i8* %t36, i64 568
  %t442 = bitcast i8* %t441 to i32*
  store i32 %t438, i32* %t442
  %t443 = add i32 %t435, %t438
  %t444 = add i32 %t443, 3
  store i8 77, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t445 = load i32, i32* %t39
  %t446 = icmp sgt i32 %t445, 0
  %t447 = select i1 %t446, i32 %t445, i32 1
  %t448 = getelementptr inbounds i8, i8* %t36, i64 192
  %t449 = bitcast i8* %t448 to i32*
  store i32 %t444, i32* %t449
  %t450 = getelementptr inbounds i8, i8* %t36, i64 572
  %t451 = bitcast i8* %t450 to i32*
  store i32 %t447, i32* %t451
  %t452 = add i32 %t444, %t447
  %t453 = add i32 %t452, 3
  store i8 78, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t454 = load i32, i32* %t39
  %t455 = icmp sgt i32 %t454, 0
  %t456 = select i1 %t455, i32 %t454, i32 1
  %t457 = getelementptr inbounds i8, i8* %t36, i64 196
  %t458 = bitcast i8* %t457 to i32*
  store i32 %t453, i32* %t458
  %t459 = getelementptr inbounds i8, i8* %t36, i64 576
  %t460 = bitcast i8* %t459 to i32*
  store i32 %t456, i32* %t460
  %t461 = add i32 %t453, %t456
  %t462 = add i32 %t461, 3
  store i8 79, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t463 = load i32, i32* %t39
  %t464 = icmp sgt i32 %t463, 0
  %t465 = select i1 %t464, i32 %t463, i32 1
  %t466 = getelementptr inbounds i8, i8* %t36, i64 200
  %t467 = bitcast i8* %t466 to i32*
  store i32 %t462, i32* %t467
  %t468 = getelementptr inbounds i8, i8* %t36, i64 580
  %t469 = bitcast i8* %t468 to i32*
  store i32 %t465, i32* %t469
  %t470 = add i32 %t462, %t465
  %t471 = add i32 %t470, 3
  store i8 80, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t472 = load i32, i32* %t39
  %t473 = icmp sgt i32 %t472, 0
  %t474 = select i1 %t473, i32 %t472, i32 1
  %t475 = getelementptr inbounds i8, i8* %t36, i64 204
  %t476 = bitcast i8* %t475 to i32*
  store i32 %t471, i32* %t476
  %t477 = getelementptr inbounds i8, i8* %t36, i64 584
  %t478 = bitcast i8* %t477 to i32*
  store i32 %t474, i32* %t478
  %t479 = add i32 %t471, %t474
  %t480 = add i32 %t479, 3
  store i8 81, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t481 = load i32, i32* %t39
  %t482 = icmp sgt i32 %t481, 0
  %t483 = select i1 %t482, i32 %t481, i32 1
  %t484 = getelementptr inbounds i8, i8* %t36, i64 208
  %t485 = bitcast i8* %t484 to i32*
  store i32 %t480, i32* %t485
  %t486 = getelementptr inbounds i8, i8* %t36, i64 588
  %t487 = bitcast i8* %t486 to i32*
  store i32 %t483, i32* %t487
  %t488 = add i32 %t480, %t483
  %t489 = add i32 %t488, 3
  store i8 82, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t490 = load i32, i32* %t39
  %t491 = icmp sgt i32 %t490, 0
  %t492 = select i1 %t491, i32 %t490, i32 1
  %t493 = getelementptr inbounds i8, i8* %t36, i64 212
  %t494 = bitcast i8* %t493 to i32*
  store i32 %t489, i32* %t494
  %t495 = getelementptr inbounds i8, i8* %t36, i64 592
  %t496 = bitcast i8* %t495 to i32*
  store i32 %t492, i32* %t496
  %t497 = add i32 %t489, %t492
  %t498 = add i32 %t497, 3
  store i8 83, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t499 = load i32, i32* %t39
  %t500 = icmp sgt i32 %t499, 0
  %t501 = select i1 %t500, i32 %t499, i32 1
  %t502 = getelementptr inbounds i8, i8* %t36, i64 216
  %t503 = bitcast i8* %t502 to i32*
  store i32 %t498, i32* %t503
  %t504 = getelementptr inbounds i8, i8* %t36, i64 596
  %t505 = bitcast i8* %t504 to i32*
  store i32 %t501, i32* %t505
  %t506 = add i32 %t498, %t501
  %t507 = add i32 %t506, 3
  store i8 84, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t508 = load i32, i32* %t39
  %t509 = icmp sgt i32 %t508, 0
  %t510 = select i1 %t509, i32 %t508, i32 1
  %t511 = getelementptr inbounds i8, i8* %t36, i64 220
  %t512 = bitcast i8* %t511 to i32*
  store i32 %t507, i32* %t512
  %t513 = getelementptr inbounds i8, i8* %t36, i64 600
  %t514 = bitcast i8* %t513 to i32*
  store i32 %t510, i32* %t514
  %t515 = add i32 %t507, %t510
  %t516 = add i32 %t515, 3
  store i8 85, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t517 = load i32, i32* %t39
  %t518 = icmp sgt i32 %t517, 0
  %t519 = select i1 %t518, i32 %t517, i32 1
  %t520 = getelementptr inbounds i8, i8* %t36, i64 224
  %t521 = bitcast i8* %t520 to i32*
  store i32 %t516, i32* %t521
  %t522 = getelementptr inbounds i8, i8* %t36, i64 604
  %t523 = bitcast i8* %t522 to i32*
  store i32 %t519, i32* %t523
  %t524 = add i32 %t516, %t519
  %t525 = add i32 %t524, 3
  store i8 86, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t526 = load i32, i32* %t39
  %t527 = icmp sgt i32 %t526, 0
  %t528 = select i1 %t527, i32 %t526, i32 1
  %t529 = getelementptr inbounds i8, i8* %t36, i64 228
  %t530 = bitcast i8* %t529 to i32*
  store i32 %t525, i32* %t530
  %t531 = getelementptr inbounds i8, i8* %t36, i64 608
  %t532 = bitcast i8* %t531 to i32*
  store i32 %t528, i32* %t532
  %t533 = add i32 %t525, %t528
  %t534 = add i32 %t533, 3
  store i8 87, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t535 = load i32, i32* %t39
  %t536 = icmp sgt i32 %t535, 0
  %t537 = select i1 %t536, i32 %t535, i32 1
  %t538 = getelementptr inbounds i8, i8* %t36, i64 232
  %t539 = bitcast i8* %t538 to i32*
  store i32 %t534, i32* %t539
  %t540 = getelementptr inbounds i8, i8* %t36, i64 612
  %t541 = bitcast i8* %t540 to i32*
  store i32 %t537, i32* %t541
  %t542 = add i32 %t534, %t537
  %t543 = add i32 %t542, 3
  store i8 88, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t544 = load i32, i32* %t39
  %t545 = icmp sgt i32 %t544, 0
  %t546 = select i1 %t545, i32 %t544, i32 1
  %t547 = getelementptr inbounds i8, i8* %t36, i64 236
  %t548 = bitcast i8* %t547 to i32*
  store i32 %t543, i32* %t548
  %t549 = getelementptr inbounds i8, i8* %t36, i64 616
  %t550 = bitcast i8* %t549 to i32*
  store i32 %t546, i32* %t550
  %t551 = add i32 %t543, %t546
  %t552 = add i32 %t551, 3
  store i8 89, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t553 = load i32, i32* %t39
  %t554 = icmp sgt i32 %t553, 0
  %t555 = select i1 %t554, i32 %t553, i32 1
  %t556 = getelementptr inbounds i8, i8* %t36, i64 240
  %t557 = bitcast i8* %t556 to i32*
  store i32 %t552, i32* %t557
  %t558 = getelementptr inbounds i8, i8* %t36, i64 620
  %t559 = bitcast i8* %t558 to i32*
  store i32 %t555, i32* %t559
  %t560 = add i32 %t552, %t555
  %t561 = add i32 %t560, 3
  store i8 90, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t562 = load i32, i32* %t39
  %t563 = icmp sgt i32 %t562, 0
  %t564 = select i1 %t563, i32 %t562, i32 1
  %t565 = getelementptr inbounds i8, i8* %t36, i64 244
  %t566 = bitcast i8* %t565 to i32*
  store i32 %t561, i32* %t566
  %t567 = getelementptr inbounds i8, i8* %t36, i64 624
  %t568 = bitcast i8* %t567 to i32*
  store i32 %t564, i32* %t568
  %t569 = add i32 %t561, %t564
  %t570 = add i32 %t569, 3
  store i8 91, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t571 = load i32, i32* %t39
  %t572 = icmp sgt i32 %t571, 0
  %t573 = select i1 %t572, i32 %t571, i32 1
  %t574 = getelementptr inbounds i8, i8* %t36, i64 248
  %t575 = bitcast i8* %t574 to i32*
  store i32 %t570, i32* %t575
  %t576 = getelementptr inbounds i8, i8* %t36, i64 628
  %t577 = bitcast i8* %t576 to i32*
  store i32 %t573, i32* %t577
  %t578 = add i32 %t570, %t573
  %t579 = add i32 %t578, 3
  store i8 92, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t580 = load i32, i32* %t39
  %t581 = icmp sgt i32 %t580, 0
  %t582 = select i1 %t581, i32 %t580, i32 1
  %t583 = getelementptr inbounds i8, i8* %t36, i64 252
  %t584 = bitcast i8* %t583 to i32*
  store i32 %t579, i32* %t584
  %t585 = getelementptr inbounds i8, i8* %t36, i64 632
  %t586 = bitcast i8* %t585 to i32*
  store i32 %t582, i32* %t586
  %t587 = add i32 %t579, %t582
  %t588 = add i32 %t587, 3
  store i8 93, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t589 = load i32, i32* %t39
  %t590 = icmp sgt i32 %t589, 0
  %t591 = select i1 %t590, i32 %t589, i32 1
  %t592 = getelementptr inbounds i8, i8* %t36, i64 256
  %t593 = bitcast i8* %t592 to i32*
  store i32 %t588, i32* %t593
  %t594 = getelementptr inbounds i8, i8* %t36, i64 636
  %t595 = bitcast i8* %t594 to i32*
  store i32 %t591, i32* %t595
  %t596 = add i32 %t588, %t591
  %t597 = add i32 %t596, 3
  store i8 94, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t598 = load i32, i32* %t39
  %t599 = icmp sgt i32 %t598, 0
  %t600 = select i1 %t599, i32 %t598, i32 1
  %t601 = getelementptr inbounds i8, i8* %t36, i64 260
  %t602 = bitcast i8* %t601 to i32*
  store i32 %t597, i32* %t602
  %t603 = getelementptr inbounds i8, i8* %t36, i64 640
  %t604 = bitcast i8* %t603 to i32*
  store i32 %t600, i32* %t604
  %t605 = add i32 %t597, %t600
  %t606 = add i32 %t605, 3
  store i8 95, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t607 = load i32, i32* %t39
  %t608 = icmp sgt i32 %t607, 0
  %t609 = select i1 %t608, i32 %t607, i32 1
  %t610 = getelementptr inbounds i8, i8* %t36, i64 264
  %t611 = bitcast i8* %t610 to i32*
  store i32 %t606, i32* %t611
  %t612 = getelementptr inbounds i8, i8* %t36, i64 644
  %t613 = bitcast i8* %t612 to i32*
  store i32 %t609, i32* %t613
  %t614 = add i32 %t606, %t609
  %t615 = add i32 %t614, 3
  store i8 96, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t616 = load i32, i32* %t39
  %t617 = icmp sgt i32 %t616, 0
  %t618 = select i1 %t617, i32 %t616, i32 1
  %t619 = getelementptr inbounds i8, i8* %t36, i64 268
  %t620 = bitcast i8* %t619 to i32*
  store i32 %t615, i32* %t620
  %t621 = getelementptr inbounds i8, i8* %t36, i64 648
  %t622 = bitcast i8* %t621 to i32*
  store i32 %t618, i32* %t622
  %t623 = add i32 %t615, %t618
  %t624 = add i32 %t623, 3
  store i8 97, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t625 = load i32, i32* %t39
  %t626 = icmp sgt i32 %t625, 0
  %t627 = select i1 %t626, i32 %t625, i32 1
  %t628 = getelementptr inbounds i8, i8* %t36, i64 272
  %t629 = bitcast i8* %t628 to i32*
  store i32 %t624, i32* %t629
  %t630 = getelementptr inbounds i8, i8* %t36, i64 652
  %t631 = bitcast i8* %t630 to i32*
  store i32 %t627, i32* %t631
  %t632 = add i32 %t624, %t627
  %t633 = add i32 %t632, 3
  store i8 98, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t634 = load i32, i32* %t39
  %t635 = icmp sgt i32 %t634, 0
  %t636 = select i1 %t635, i32 %t634, i32 1
  %t637 = getelementptr inbounds i8, i8* %t36, i64 276
  %t638 = bitcast i8* %t637 to i32*
  store i32 %t633, i32* %t638
  %t639 = getelementptr inbounds i8, i8* %t36, i64 656
  %t640 = bitcast i8* %t639 to i32*
  store i32 %t636, i32* %t640
  %t641 = add i32 %t633, %t636
  %t642 = add i32 %t641, 3
  store i8 99, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t643 = load i32, i32* %t39
  %t644 = icmp sgt i32 %t643, 0
  %t645 = select i1 %t644, i32 %t643, i32 1
  %t646 = getelementptr inbounds i8, i8* %t36, i64 280
  %t647 = bitcast i8* %t646 to i32*
  store i32 %t642, i32* %t647
  %t648 = getelementptr inbounds i8, i8* %t36, i64 660
  %t649 = bitcast i8* %t648 to i32*
  store i32 %t645, i32* %t649
  %t650 = add i32 %t642, %t645
  %t651 = add i32 %t650, 3
  store i8 100, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t652 = load i32, i32* %t39
  %t653 = icmp sgt i32 %t652, 0
  %t654 = select i1 %t653, i32 %t652, i32 1
  %t655 = getelementptr inbounds i8, i8* %t36, i64 284
  %t656 = bitcast i8* %t655 to i32*
  store i32 %t651, i32* %t656
  %t657 = getelementptr inbounds i8, i8* %t36, i64 664
  %t658 = bitcast i8* %t657 to i32*
  store i32 %t654, i32* %t658
  %t659 = add i32 %t651, %t654
  %t660 = add i32 %t659, 3
  store i8 101, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t661 = load i32, i32* %t39
  %t662 = icmp sgt i32 %t661, 0
  %t663 = select i1 %t662, i32 %t661, i32 1
  %t664 = getelementptr inbounds i8, i8* %t36, i64 288
  %t665 = bitcast i8* %t664 to i32*
  store i32 %t660, i32* %t665
  %t666 = getelementptr inbounds i8, i8* %t36, i64 668
  %t667 = bitcast i8* %t666 to i32*
  store i32 %t663, i32* %t667
  %t668 = add i32 %t660, %t663
  %t669 = add i32 %t668, 3
  store i8 102, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t670 = load i32, i32* %t39
  %t671 = icmp sgt i32 %t670, 0
  %t672 = select i1 %t671, i32 %t670, i32 1
  %t673 = getelementptr inbounds i8, i8* %t36, i64 292
  %t674 = bitcast i8* %t673 to i32*
  store i32 %t669, i32* %t674
  %t675 = getelementptr inbounds i8, i8* %t36, i64 672
  %t676 = bitcast i8* %t675 to i32*
  store i32 %t672, i32* %t676
  %t677 = add i32 %t669, %t672
  %t678 = add i32 %t677, 3
  store i8 103, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t679 = load i32, i32* %t39
  %t680 = icmp sgt i32 %t679, 0
  %t681 = select i1 %t680, i32 %t679, i32 1
  %t682 = getelementptr inbounds i8, i8* %t36, i64 296
  %t683 = bitcast i8* %t682 to i32*
  store i32 %t678, i32* %t683
  %t684 = getelementptr inbounds i8, i8* %t36, i64 676
  %t685 = bitcast i8* %t684 to i32*
  store i32 %t681, i32* %t685
  %t686 = add i32 %t678, %t681
  %t687 = add i32 %t686, 3
  store i8 104, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t688 = load i32, i32* %t39
  %t689 = icmp sgt i32 %t688, 0
  %t690 = select i1 %t689, i32 %t688, i32 1
  %t691 = getelementptr inbounds i8, i8* %t36, i64 300
  %t692 = bitcast i8* %t691 to i32*
  store i32 %t687, i32* %t692
  %t693 = getelementptr inbounds i8, i8* %t36, i64 680
  %t694 = bitcast i8* %t693 to i32*
  store i32 %t690, i32* %t694
  %t695 = add i32 %t687, %t690
  %t696 = add i32 %t695, 3
  store i8 105, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t697 = load i32, i32* %t39
  %t698 = icmp sgt i32 %t697, 0
  %t699 = select i1 %t698, i32 %t697, i32 1
  %t700 = getelementptr inbounds i8, i8* %t36, i64 304
  %t701 = bitcast i8* %t700 to i32*
  store i32 %t696, i32* %t701
  %t702 = getelementptr inbounds i8, i8* %t36, i64 684
  %t703 = bitcast i8* %t702 to i32*
  store i32 %t699, i32* %t703
  %t704 = add i32 %t696, %t699
  %t705 = add i32 %t704, 3
  store i8 106, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t706 = load i32, i32* %t39
  %t707 = icmp sgt i32 %t706, 0
  %t708 = select i1 %t707, i32 %t706, i32 1
  %t709 = getelementptr inbounds i8, i8* %t36, i64 308
  %t710 = bitcast i8* %t709 to i32*
  store i32 %t705, i32* %t710
  %t711 = getelementptr inbounds i8, i8* %t36, i64 688
  %t712 = bitcast i8* %t711 to i32*
  store i32 %t708, i32* %t712
  %t713 = add i32 %t705, %t708
  %t714 = add i32 %t713, 3
  store i8 107, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t715 = load i32, i32* %t39
  %t716 = icmp sgt i32 %t715, 0
  %t717 = select i1 %t716, i32 %t715, i32 1
  %t718 = getelementptr inbounds i8, i8* %t36, i64 312
  %t719 = bitcast i8* %t718 to i32*
  store i32 %t714, i32* %t719
  %t720 = getelementptr inbounds i8, i8* %t36, i64 692
  %t721 = bitcast i8* %t720 to i32*
  store i32 %t717, i32* %t721
  %t722 = add i32 %t714, %t717
  %t723 = add i32 %t722, 3
  store i8 108, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t724 = load i32, i32* %t39
  %t725 = icmp sgt i32 %t724, 0
  %t726 = select i1 %t725, i32 %t724, i32 1
  %t727 = getelementptr inbounds i8, i8* %t36, i64 316
  %t728 = bitcast i8* %t727 to i32*
  store i32 %t723, i32* %t728
  %t729 = getelementptr inbounds i8, i8* %t36, i64 696
  %t730 = bitcast i8* %t729 to i32*
  store i32 %t726, i32* %t730
  %t731 = add i32 %t723, %t726
  %t732 = add i32 %t731, 3
  store i8 109, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t733 = load i32, i32* %t39
  %t734 = icmp sgt i32 %t733, 0
  %t735 = select i1 %t734, i32 %t733, i32 1
  %t736 = getelementptr inbounds i8, i8* %t36, i64 320
  %t737 = bitcast i8* %t736 to i32*
  store i32 %t732, i32* %t737
  %t738 = getelementptr inbounds i8, i8* %t36, i64 700
  %t739 = bitcast i8* %t738 to i32*
  store i32 %t735, i32* %t739
  %t740 = add i32 %t732, %t735
  %t741 = add i32 %t740, 3
  store i8 110, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t742 = load i32, i32* %t39
  %t743 = icmp sgt i32 %t742, 0
  %t744 = select i1 %t743, i32 %t742, i32 1
  %t745 = getelementptr inbounds i8, i8* %t36, i64 324
  %t746 = bitcast i8* %t745 to i32*
  store i32 %t741, i32* %t746
  %t747 = getelementptr inbounds i8, i8* %t36, i64 704
  %t748 = bitcast i8* %t747 to i32*
  store i32 %t744, i32* %t748
  %t749 = add i32 %t741, %t744
  %t750 = add i32 %t749, 3
  store i8 111, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t751 = load i32, i32* %t39
  %t752 = icmp sgt i32 %t751, 0
  %t753 = select i1 %t752, i32 %t751, i32 1
  %t754 = getelementptr inbounds i8, i8* %t36, i64 328
  %t755 = bitcast i8* %t754 to i32*
  store i32 %t750, i32* %t755
  %t756 = getelementptr inbounds i8, i8* %t36, i64 708
  %t757 = bitcast i8* %t756 to i32*
  store i32 %t753, i32* %t757
  %t758 = add i32 %t750, %t753
  %t759 = add i32 %t758, 3
  store i8 112, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t760 = load i32, i32* %t39
  %t761 = icmp sgt i32 %t760, 0
  %t762 = select i1 %t761, i32 %t760, i32 1
  %t763 = getelementptr inbounds i8, i8* %t36, i64 332
  %t764 = bitcast i8* %t763 to i32*
  store i32 %t759, i32* %t764
  %t765 = getelementptr inbounds i8, i8* %t36, i64 712
  %t766 = bitcast i8* %t765 to i32*
  store i32 %t762, i32* %t766
  %t767 = add i32 %t759, %t762
  %t768 = add i32 %t767, 3
  store i8 113, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t769 = load i32, i32* %t39
  %t770 = icmp sgt i32 %t769, 0
  %t771 = select i1 %t770, i32 %t769, i32 1
  %t772 = getelementptr inbounds i8, i8* %t36, i64 336
  %t773 = bitcast i8* %t772 to i32*
  store i32 %t768, i32* %t773
  %t774 = getelementptr inbounds i8, i8* %t36, i64 716
  %t775 = bitcast i8* %t774 to i32*
  store i32 %t771, i32* %t775
  %t776 = add i32 %t768, %t771
  %t777 = add i32 %t776, 3
  store i8 114, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t778 = load i32, i32* %t39
  %t779 = icmp sgt i32 %t778, 0
  %t780 = select i1 %t779, i32 %t778, i32 1
  %t781 = getelementptr inbounds i8, i8* %t36, i64 340
  %t782 = bitcast i8* %t781 to i32*
  store i32 %t777, i32* %t782
  %t783 = getelementptr inbounds i8, i8* %t36, i64 720
  %t784 = bitcast i8* %t783 to i32*
  store i32 %t780, i32* %t784
  %t785 = add i32 %t777, %t780
  %t786 = add i32 %t785, 3
  store i8 115, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t787 = load i32, i32* %t39
  %t788 = icmp sgt i32 %t787, 0
  %t789 = select i1 %t788, i32 %t787, i32 1
  %t790 = getelementptr inbounds i8, i8* %t36, i64 344
  %t791 = bitcast i8* %t790 to i32*
  store i32 %t786, i32* %t791
  %t792 = getelementptr inbounds i8, i8* %t36, i64 724
  %t793 = bitcast i8* %t792 to i32*
  store i32 %t789, i32* %t793
  %t794 = add i32 %t786, %t789
  %t795 = add i32 %t794, 3
  store i8 116, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t796 = load i32, i32* %t39
  %t797 = icmp sgt i32 %t796, 0
  %t798 = select i1 %t797, i32 %t796, i32 1
  %t799 = getelementptr inbounds i8, i8* %t36, i64 348
  %t800 = bitcast i8* %t799 to i32*
  store i32 %t795, i32* %t800
  %t801 = getelementptr inbounds i8, i8* %t36, i64 728
  %t802 = bitcast i8* %t801 to i32*
  store i32 %t798, i32* %t802
  %t803 = add i32 %t795, %t798
  %t804 = add i32 %t803, 3
  store i8 117, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t805 = load i32, i32* %t39
  %t806 = icmp sgt i32 %t805, 0
  %t807 = select i1 %t806, i32 %t805, i32 1
  %t808 = getelementptr inbounds i8, i8* %t36, i64 352
  %t809 = bitcast i8* %t808 to i32*
  store i32 %t804, i32* %t809
  %t810 = getelementptr inbounds i8, i8* %t36, i64 732
  %t811 = bitcast i8* %t810 to i32*
  store i32 %t807, i32* %t811
  %t812 = add i32 %t804, %t807
  %t813 = add i32 %t812, 3
  store i8 118, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t814 = load i32, i32* %t39
  %t815 = icmp sgt i32 %t814, 0
  %t816 = select i1 %t815, i32 %t814, i32 1
  %t817 = getelementptr inbounds i8, i8* %t36, i64 356
  %t818 = bitcast i8* %t817 to i32*
  store i32 %t813, i32* %t818
  %t819 = getelementptr inbounds i8, i8* %t36, i64 736
  %t820 = bitcast i8* %t819 to i32*
  store i32 %t816, i32* %t820
  %t821 = add i32 %t813, %t816
  %t822 = add i32 %t821, 3
  store i8 119, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t823 = load i32, i32* %t39
  %t824 = icmp sgt i32 %t823, 0
  %t825 = select i1 %t824, i32 %t823, i32 1
  %t826 = getelementptr inbounds i8, i8* %t36, i64 360
  %t827 = bitcast i8* %t826 to i32*
  store i32 %t822, i32* %t827
  %t828 = getelementptr inbounds i8, i8* %t36, i64 740
  %t829 = bitcast i8* %t828 to i32*
  store i32 %t825, i32* %t829
  %t830 = add i32 %t822, %t825
  %t831 = add i32 %t830, 3
  store i8 120, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t832 = load i32, i32* %t39
  %t833 = icmp sgt i32 %t832, 0
  %t834 = select i1 %t833, i32 %t832, i32 1
  %t835 = getelementptr inbounds i8, i8* %t36, i64 364
  %t836 = bitcast i8* %t835 to i32*
  store i32 %t831, i32* %t836
  %t837 = getelementptr inbounds i8, i8* %t36, i64 744
  %t838 = bitcast i8* %t837 to i32*
  store i32 %t834, i32* %t838
  %t839 = add i32 %t831, %t834
  %t840 = add i32 %t839, 3
  store i8 121, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t841 = load i32, i32* %t39
  %t842 = icmp sgt i32 %t841, 0
  %t843 = select i1 %t842, i32 %t841, i32 1
  %t844 = getelementptr inbounds i8, i8* %t36, i64 368
  %t845 = bitcast i8* %t844 to i32*
  store i32 %t840, i32* %t845
  %t846 = getelementptr inbounds i8, i8* %t36, i64 748
  %t847 = bitcast i8* %t846 to i32*
  store i32 %t843, i32* %t847
  %t848 = add i32 %t840, %t843
  %t849 = add i32 %t848, 3
  store i8 122, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t850 = load i32, i32* %t39
  %t851 = icmp sgt i32 %t850, 0
  %t852 = select i1 %t851, i32 %t850, i32 1
  %t853 = getelementptr inbounds i8, i8* %t36, i64 372
  %t854 = bitcast i8* %t853 to i32*
  store i32 %t849, i32* %t854
  %t855 = getelementptr inbounds i8, i8* %t36, i64 752
  %t856 = bitcast i8* %t855 to i32*
  store i32 %t852, i32* %t856
  %t857 = add i32 %t849, %t852
  %t858 = add i32 %t857, 3
  store i8 123, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t859 = load i32, i32* %t39
  %t860 = icmp sgt i32 %t859, 0
  %t861 = select i1 %t860, i32 %t859, i32 1
  %t862 = getelementptr inbounds i8, i8* %t36, i64 376
  %t863 = bitcast i8* %t862 to i32*
  store i32 %t858, i32* %t863
  %t864 = getelementptr inbounds i8, i8* %t36, i64 756
  %t865 = bitcast i8* %t864 to i32*
  store i32 %t861, i32* %t865
  %t866 = add i32 %t858, %t861
  %t867 = add i32 %t866, 3
  store i8 124, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t868 = load i32, i32* %t39
  %t869 = icmp sgt i32 %t868, 0
  %t870 = select i1 %t869, i32 %t868, i32 1
  %t871 = getelementptr inbounds i8, i8* %t36, i64 380
  %t872 = bitcast i8* %t871 to i32*
  store i32 %t867, i32* %t872
  %t873 = getelementptr inbounds i8, i8* %t36, i64 760
  %t874 = bitcast i8* %t873 to i32*
  store i32 %t870, i32* %t874
  %t875 = add i32 %t867, %t870
  %t876 = add i32 %t875, 3
  store i8 125, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t877 = load i32, i32* %t39
  %t878 = icmp sgt i32 %t877, 0
  %t879 = select i1 %t878, i32 %t877, i32 1
  %t880 = getelementptr inbounds i8, i8* %t36, i64 384
  %t881 = bitcast i8* %t880 to i32*
  store i32 %t876, i32* %t881
  %t882 = getelementptr inbounds i8, i8* %t36, i64 764
  %t883 = bitcast i8* %t882 to i32*
  store i32 %t879, i32* %t883
  %t884 = add i32 %t876, %t879
  %t885 = add i32 %t884, 3
  store i8 126, i8* %t37
  call i32 @GetTextExtentPoint32A(i8* %t27, i8* %t37, i32 1, i8* %t38)
  %t886 = load i32, i32* %t39
  %t887 = icmp sgt i32 %t886, 0
  %t888 = select i1 %t887, i32 %t886, i32 1
  %t889 = getelementptr inbounds i8, i8* %t36, i64 388
  %t890 = bitcast i8* %t889 to i32*
  store i32 %t885, i32* %t890
  %t891 = getelementptr inbounds i8, i8* %t36, i64 768
  %t892 = bitcast i8* %t891 to i32*
  store i32 %t888, i32* %t892
  %t893 = add i32 %t885, %t888
  %t894 = add i32 %t893, 3
  %t896 = getelementptr inbounds [40 x i8], [40 x i8]* %t895, i64 0, i64 0
  store i64 0, i64* %t897
  br label %ht_fill8_cond_18
ht_fill8_cond_18:
  %t898 = load i64, i64* %t897
  %t899 = icmp slt i64 %t898, 40
  br i1 %t899, label %ht_fill8_body_19, label %ht_fill8_end_20
ht_fill8_body_19:
  %t900 = getelementptr inbounds i8, i8* %t896, i64 %t898
  store i8 0, i8* %t900
  %t901 = add i64 %t898, 1
  store i64 %t901, i64* %t897
  br label %ht_fill8_cond_18
ht_fill8_end_20:
  %t902 = bitcast i8* %t896 to i32*
  store i32 40, i32* %t902
  %t903 = getelementptr inbounds i8, i8* %t896, i64 4
  %t904 = bitcast i8* %t903 to i32*
  store i32 %t894, i32* %t904
  %t905 = sub i32 0, %t35
  %t906 = getelementptr inbounds i8, i8* %t896, i64 8
  %t907 = bitcast i8* %t906 to i32*
  store i32 %t905, i32* %t907
  %t908 = getelementptr inbounds i8, i8* %t896, i64 12
  %t909 = bitcast i8* %t908 to i16*
  store i16 1, i16* %t909
  %t910 = getelementptr inbounds i8, i8* %t896, i64 14
  %t911 = bitcast i8* %t910 to i16*
  store i16 32, i16* %t911
  %t913 = call i8* @CreateDIBSection(i8* %t27, i8* %t896, i32 0, i8** %t912, i8* null, i32 0)
  %t914 = icmp eq i8* %t913, null
  br i1 %t914, label %rasterize_dib_fail_21, label %rasterize_dib_ok_22
rasterize_dib_fail_21:
  call i8* @SelectObject(i8* %t27, i8* %t29)
  call i32 @DeleteObject(i8* %t23)
  call i32 @DeleteDC(i8* %t27)
  call void @free(i8* %t36)
  br label %rasterize_end_15
rasterize_dib_ok_22:
  %t915 = load i8*, i8** %t912
  %t916 = call i8* @SelectObject(i8* %t27, i8* %t913)
  %t917 = mul i32 %t894, %t35
  %t918 = sext i32 %t917 to i64
  %t919 = mul i64 %t918, 4
  store i64 0, i64* %t920
  br label %ht_fill8_cond_23
ht_fill8_cond_23:
  %t921 = load i64, i64* %t920
  %t922 = icmp slt i64 %t921, %t919
  br i1 %t922, label %ht_fill8_body_24, label %ht_fill8_end_25
ht_fill8_body_24:
  %t923 = getelementptr inbounds i8, i8* %t915, i64 %t921
  store i8 0, i8* %t923
  %t924 = add i64 %t921, 1
  store i64 %t924, i64* %t920
  br label %ht_fill8_cond_23
ht_fill8_end_25:
  store i8 32, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 0, i32 0, i8* %t37, i32 1)
  store i8 33, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t48, i32 0, i8* %t37, i32 1)
  store i8 34, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t57, i32 0, i8* %t37, i32 1)
  store i8 35, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t66, i32 0, i8* %t37, i32 1)
  store i8 36, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t75, i32 0, i8* %t37, i32 1)
  store i8 37, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t84, i32 0, i8* %t37, i32 1)
  store i8 38, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t93, i32 0, i8* %t37, i32 1)
  store i8 39, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t102, i32 0, i8* %t37, i32 1)
  store i8 40, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t111, i32 0, i8* %t37, i32 1)
  store i8 41, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t120, i32 0, i8* %t37, i32 1)
  store i8 42, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t129, i32 0, i8* %t37, i32 1)
  store i8 43, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t138, i32 0, i8* %t37, i32 1)
  store i8 44, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t147, i32 0, i8* %t37, i32 1)
  store i8 45, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t156, i32 0, i8* %t37, i32 1)
  store i8 46, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t165, i32 0, i8* %t37, i32 1)
  store i8 47, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t174, i32 0, i8* %t37, i32 1)
  store i8 48, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t183, i32 0, i8* %t37, i32 1)
  store i8 49, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t192, i32 0, i8* %t37, i32 1)
  store i8 50, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t201, i32 0, i8* %t37, i32 1)
  store i8 51, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t210, i32 0, i8* %t37, i32 1)
  store i8 52, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t219, i32 0, i8* %t37, i32 1)
  store i8 53, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t228, i32 0, i8* %t37, i32 1)
  store i8 54, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t237, i32 0, i8* %t37, i32 1)
  store i8 55, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t246, i32 0, i8* %t37, i32 1)
  store i8 56, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t255, i32 0, i8* %t37, i32 1)
  store i8 57, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t264, i32 0, i8* %t37, i32 1)
  store i8 58, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t273, i32 0, i8* %t37, i32 1)
  store i8 59, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t282, i32 0, i8* %t37, i32 1)
  store i8 60, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t291, i32 0, i8* %t37, i32 1)
  store i8 61, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t300, i32 0, i8* %t37, i32 1)
  store i8 62, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t309, i32 0, i8* %t37, i32 1)
  store i8 63, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t318, i32 0, i8* %t37, i32 1)
  store i8 64, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t327, i32 0, i8* %t37, i32 1)
  store i8 65, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t336, i32 0, i8* %t37, i32 1)
  store i8 66, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t345, i32 0, i8* %t37, i32 1)
  store i8 67, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t354, i32 0, i8* %t37, i32 1)
  store i8 68, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t363, i32 0, i8* %t37, i32 1)
  store i8 69, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t372, i32 0, i8* %t37, i32 1)
  store i8 70, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t381, i32 0, i8* %t37, i32 1)
  store i8 71, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t390, i32 0, i8* %t37, i32 1)
  store i8 72, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t399, i32 0, i8* %t37, i32 1)
  store i8 73, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t408, i32 0, i8* %t37, i32 1)
  store i8 74, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t417, i32 0, i8* %t37, i32 1)
  store i8 75, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t426, i32 0, i8* %t37, i32 1)
  store i8 76, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t435, i32 0, i8* %t37, i32 1)
  store i8 77, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t444, i32 0, i8* %t37, i32 1)
  store i8 78, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t453, i32 0, i8* %t37, i32 1)
  store i8 79, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t462, i32 0, i8* %t37, i32 1)
  store i8 80, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t471, i32 0, i8* %t37, i32 1)
  store i8 81, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t480, i32 0, i8* %t37, i32 1)
  store i8 82, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t489, i32 0, i8* %t37, i32 1)
  store i8 83, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t498, i32 0, i8* %t37, i32 1)
  store i8 84, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t507, i32 0, i8* %t37, i32 1)
  store i8 85, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t516, i32 0, i8* %t37, i32 1)
  store i8 86, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t525, i32 0, i8* %t37, i32 1)
  store i8 87, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t534, i32 0, i8* %t37, i32 1)
  store i8 88, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t543, i32 0, i8* %t37, i32 1)
  store i8 89, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t552, i32 0, i8* %t37, i32 1)
  store i8 90, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t561, i32 0, i8* %t37, i32 1)
  store i8 91, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t570, i32 0, i8* %t37, i32 1)
  store i8 92, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t579, i32 0, i8* %t37, i32 1)
  store i8 93, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t588, i32 0, i8* %t37, i32 1)
  store i8 94, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t597, i32 0, i8* %t37, i32 1)
  store i8 95, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t606, i32 0, i8* %t37, i32 1)
  store i8 96, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t615, i32 0, i8* %t37, i32 1)
  store i8 97, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t624, i32 0, i8* %t37, i32 1)
  store i8 98, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t633, i32 0, i8* %t37, i32 1)
  store i8 99, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t642, i32 0, i8* %t37, i32 1)
  store i8 100, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t651, i32 0, i8* %t37, i32 1)
  store i8 101, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t660, i32 0, i8* %t37, i32 1)
  store i8 102, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t669, i32 0, i8* %t37, i32 1)
  store i8 103, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t678, i32 0, i8* %t37, i32 1)
  store i8 104, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t687, i32 0, i8* %t37, i32 1)
  store i8 105, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t696, i32 0, i8* %t37, i32 1)
  store i8 106, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t705, i32 0, i8* %t37, i32 1)
  store i8 107, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t714, i32 0, i8* %t37, i32 1)
  store i8 108, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t723, i32 0, i8* %t37, i32 1)
  store i8 109, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t732, i32 0, i8* %t37, i32 1)
  store i8 110, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t741, i32 0, i8* %t37, i32 1)
  store i8 111, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t750, i32 0, i8* %t37, i32 1)
  store i8 112, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t759, i32 0, i8* %t37, i32 1)
  store i8 113, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t768, i32 0, i8* %t37, i32 1)
  store i8 114, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t777, i32 0, i8* %t37, i32 1)
  store i8 115, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t786, i32 0, i8* %t37, i32 1)
  store i8 116, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t795, i32 0, i8* %t37, i32 1)
  store i8 117, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t804, i32 0, i8* %t37, i32 1)
  store i8 118, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t813, i32 0, i8* %t37, i32 1)
  store i8 119, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t822, i32 0, i8* %t37, i32 1)
  store i8 120, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t831, i32 0, i8* %t37, i32 1)
  store i8 121, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t840, i32 0, i8* %t37, i32 1)
  store i8 122, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t849, i32 0, i8* %t37, i32 1)
  store i8 123, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t858, i32 0, i8* %t37, i32 1)
  store i8 124, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t867, i32 0, i8* %t37, i32 1)
  store i8 125, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t876, i32 0, i8* %t37, i32 1)
  store i8 126, i8* %t37
  call i32 @TextOutA(i8* %t27, i32 %t885, i32 0, i8* %t37, i32 1)
  call i8* @SelectObject(i8* %t27, i8* %t29)
  call i8* @SelectObject(i8* %t27, i8* %t916)
  store i64 0, i64* %t925
  br label %cov2a_cond_26
cov2a_cond_26:
  %t926 = load i64, i64* %t925
  %t927 = icmp slt i64 %t926, %t918
  br i1 %t927, label %cov2a_body_27, label %cov2a_end_28
cov2a_body_27:
  %t928 = mul i64 %t926, 4
  %t929 = getelementptr inbounds i8, i8* %t915, i64 %t928
  %t930 = load i8, i8* %t929
  %t931 = getelementptr inbounds i8, i8* %t929, i64 1
  %t932 = getelementptr inbounds i8, i8* %t929, i64 2
  %t933 = getelementptr inbounds i8, i8* %t929, i64 3
  store i8 %t930, i8* %t933
  store i8 255, i8* %t929
  store i8 255, i8* %t931
  store i8 255, i8* %t932
  %t934 = add i64 %t926, 1
  store i64 %t934, i64* %t925
  br label %cov2a_cond_26
cov2a_end_28:
  %t935 = call i8* @SDL_CreateTexture(i8* %t26, i32 372645892, i32 0, i32 %t894, i32 %t35)
  %t936 = icmp eq i8* %t935, null
  br i1 %t936, label %rasterize_tex_fail_29, label %rasterize_tex_ok_30
rasterize_tex_fail_29:
  call i32 @DeleteObject(i8* %t913)
  call i32 @DeleteObject(i8* %t23)
  call i32 @DeleteDC(i8* %t27)
  call void @free(i8* %t36)
  br label %rasterize_end_15
rasterize_tex_ok_30:
  call i32 @SDL_SetTextureBlendMode(i8* %t935, i32 1)
  %t937 = mul i32 %t894, 4
  call i32 @SDL_UpdateTexture(i8* %t935, i8* null, i8* %t915, i32 %t937)
  call i32 @DeleteObject(i8* %t913)
  call i32 @DeleteObject(i8* %t23)
  call i32 @DeleteDC(i8* %t27)
  %t938 = getelementptr inbounds i8, i8* %t36, i64 0
  %t939 = bitcast i8* %t938 to i8**
  store i8* %t935, i8** %t939
  %t940 = getelementptr inbounds i8, i8* %t36, i64 8
  %t941 = bitcast i8* %t940 to i32*
  store i32 %t35, i32* %t941
  store i8* %t36, i8** %t25
  br label %rasterize_end_15
rasterize_end_15:
  %t942 = load i8*, i8** %t25
  br label %font_load_system_end_14
font_load_system_end_14:
  %t943 = phi i8* [ null, %font_load_system_fail_12 ], [ %t942, %rasterize_end_15 ]
  store i8* %t943, i8** %t15
  %t945 = load i8*, i8** %t2
  %t946 = icmp eq i8* %t945, null
  br i1 %t946, label %sdl_null_window_31, label %sdl_window_handle_ok_32
sdl_null_window_31:
  %t947 = getelementptr inbounds [82 x i8], [82 x i8]* @.str.5, i64 0, i64 0
  call i32 @puts(i8* %t947)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_32:
  %t948 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t949 = icmp sgt i32 18, 0
  %t950 = select i1 %t949, i32 18, i32 1
  %t951 = sub i32 0, %t950
  %t952 = call i8* @CreateFontA(i32 %t951, i32 0, i32 0, i32 0, i32 400, i32 0, i32 0, i32 0, i32 1, i32 4, i32 0, i32 4, i32 0, i8* %t948)
  call void @star_rc_release(i8* %t948)
  %t953 = icmp eq i8* %t952, null
  br i1 %t953, label %font_load_system_fail_33, label %font_load_system_ok_34
font_load_system_fail_33:
  br label %font_load_system_end_35
font_load_system_ok_34:
  store i8* null, i8** %t954
  %t955 = call i8* @SDL_GetRenderer(i8* %t945)
  %t956 = call i8* @CreateCompatibleDC(i8* null)
  %t957 = icmp eq i8* %t956, null
  br i1 %t957, label %rasterize_memdc_fail_37, label %rasterize_memdc_ok_38
rasterize_memdc_fail_37:
  call i32 @DeleteObject(i8* %t952)
  br label %rasterize_end_36
rasterize_memdc_ok_38:
  %t958 = call i8* @SelectObject(i8* %t956, i8* %t952)
  call i32 @SetBkMode(i8* %t956, i32 1)
  call i32 @SetTextColor(i8* %t956, i32 16777215)
  %t960 = getelementptr inbounds [64 x i8], [64 x i8]* %t959, i64 0, i64 0
  call i32 @GetTextMetricsA(i8* %t956, i8* %t960)
  %t961 = bitcast i8* %t960 to i32*
  %t962 = load i32, i32* %t961
  %t963 = icmp sgt i32 %t962, 0
  %t964 = select i1 %t963, i32 %t962, i32 1
  %t965 = call i8* @malloc(i64 772)
  %t968 = bitcast [8 x i8]* %t967 to i32*
  store i8 32, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t969 = load i32, i32* %t968
  %t970 = icmp sgt i32 %t969, 0
  %t971 = select i1 %t970, i32 %t969, i32 1
  %t972 = getelementptr inbounds i8, i8* %t965, i64 12
  %t973 = bitcast i8* %t972 to i32*
  store i32 0, i32* %t973
  %t974 = getelementptr inbounds i8, i8* %t965, i64 392
  %t975 = bitcast i8* %t974 to i32*
  store i32 %t971, i32* %t975
  %t976 = add i32 0, %t971
  %t977 = add i32 %t976, 3
  store i8 33, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t978 = load i32, i32* %t968
  %t979 = icmp sgt i32 %t978, 0
  %t980 = select i1 %t979, i32 %t978, i32 1
  %t981 = getelementptr inbounds i8, i8* %t965, i64 16
  %t982 = bitcast i8* %t981 to i32*
  store i32 %t977, i32* %t982
  %t983 = getelementptr inbounds i8, i8* %t965, i64 396
  %t984 = bitcast i8* %t983 to i32*
  store i32 %t980, i32* %t984
  %t985 = add i32 %t977, %t980
  %t986 = add i32 %t985, 3
  store i8 34, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t987 = load i32, i32* %t968
  %t988 = icmp sgt i32 %t987, 0
  %t989 = select i1 %t988, i32 %t987, i32 1
  %t990 = getelementptr inbounds i8, i8* %t965, i64 20
  %t991 = bitcast i8* %t990 to i32*
  store i32 %t986, i32* %t991
  %t992 = getelementptr inbounds i8, i8* %t965, i64 400
  %t993 = bitcast i8* %t992 to i32*
  store i32 %t989, i32* %t993
  %t994 = add i32 %t986, %t989
  %t995 = add i32 %t994, 3
  store i8 35, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t996 = load i32, i32* %t968
  %t997 = icmp sgt i32 %t996, 0
  %t998 = select i1 %t997, i32 %t996, i32 1
  %t999 = getelementptr inbounds i8, i8* %t965, i64 24
  %t1000 = bitcast i8* %t999 to i32*
  store i32 %t995, i32* %t1000
  %t1001 = getelementptr inbounds i8, i8* %t965, i64 404
  %t1002 = bitcast i8* %t1001 to i32*
  store i32 %t998, i32* %t1002
  %t1003 = add i32 %t995, %t998
  %t1004 = add i32 %t1003, 3
  store i8 36, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1005 = load i32, i32* %t968
  %t1006 = icmp sgt i32 %t1005, 0
  %t1007 = select i1 %t1006, i32 %t1005, i32 1
  %t1008 = getelementptr inbounds i8, i8* %t965, i64 28
  %t1009 = bitcast i8* %t1008 to i32*
  store i32 %t1004, i32* %t1009
  %t1010 = getelementptr inbounds i8, i8* %t965, i64 408
  %t1011 = bitcast i8* %t1010 to i32*
  store i32 %t1007, i32* %t1011
  %t1012 = add i32 %t1004, %t1007
  %t1013 = add i32 %t1012, 3
  store i8 37, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1014 = load i32, i32* %t968
  %t1015 = icmp sgt i32 %t1014, 0
  %t1016 = select i1 %t1015, i32 %t1014, i32 1
  %t1017 = getelementptr inbounds i8, i8* %t965, i64 32
  %t1018 = bitcast i8* %t1017 to i32*
  store i32 %t1013, i32* %t1018
  %t1019 = getelementptr inbounds i8, i8* %t965, i64 412
  %t1020 = bitcast i8* %t1019 to i32*
  store i32 %t1016, i32* %t1020
  %t1021 = add i32 %t1013, %t1016
  %t1022 = add i32 %t1021, 3
  store i8 38, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1023 = load i32, i32* %t968
  %t1024 = icmp sgt i32 %t1023, 0
  %t1025 = select i1 %t1024, i32 %t1023, i32 1
  %t1026 = getelementptr inbounds i8, i8* %t965, i64 36
  %t1027 = bitcast i8* %t1026 to i32*
  store i32 %t1022, i32* %t1027
  %t1028 = getelementptr inbounds i8, i8* %t965, i64 416
  %t1029 = bitcast i8* %t1028 to i32*
  store i32 %t1025, i32* %t1029
  %t1030 = add i32 %t1022, %t1025
  %t1031 = add i32 %t1030, 3
  store i8 39, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1032 = load i32, i32* %t968
  %t1033 = icmp sgt i32 %t1032, 0
  %t1034 = select i1 %t1033, i32 %t1032, i32 1
  %t1035 = getelementptr inbounds i8, i8* %t965, i64 40
  %t1036 = bitcast i8* %t1035 to i32*
  store i32 %t1031, i32* %t1036
  %t1037 = getelementptr inbounds i8, i8* %t965, i64 420
  %t1038 = bitcast i8* %t1037 to i32*
  store i32 %t1034, i32* %t1038
  %t1039 = add i32 %t1031, %t1034
  %t1040 = add i32 %t1039, 3
  store i8 40, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1041 = load i32, i32* %t968
  %t1042 = icmp sgt i32 %t1041, 0
  %t1043 = select i1 %t1042, i32 %t1041, i32 1
  %t1044 = getelementptr inbounds i8, i8* %t965, i64 44
  %t1045 = bitcast i8* %t1044 to i32*
  store i32 %t1040, i32* %t1045
  %t1046 = getelementptr inbounds i8, i8* %t965, i64 424
  %t1047 = bitcast i8* %t1046 to i32*
  store i32 %t1043, i32* %t1047
  %t1048 = add i32 %t1040, %t1043
  %t1049 = add i32 %t1048, 3
  store i8 41, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1050 = load i32, i32* %t968
  %t1051 = icmp sgt i32 %t1050, 0
  %t1052 = select i1 %t1051, i32 %t1050, i32 1
  %t1053 = getelementptr inbounds i8, i8* %t965, i64 48
  %t1054 = bitcast i8* %t1053 to i32*
  store i32 %t1049, i32* %t1054
  %t1055 = getelementptr inbounds i8, i8* %t965, i64 428
  %t1056 = bitcast i8* %t1055 to i32*
  store i32 %t1052, i32* %t1056
  %t1057 = add i32 %t1049, %t1052
  %t1058 = add i32 %t1057, 3
  store i8 42, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1059 = load i32, i32* %t968
  %t1060 = icmp sgt i32 %t1059, 0
  %t1061 = select i1 %t1060, i32 %t1059, i32 1
  %t1062 = getelementptr inbounds i8, i8* %t965, i64 52
  %t1063 = bitcast i8* %t1062 to i32*
  store i32 %t1058, i32* %t1063
  %t1064 = getelementptr inbounds i8, i8* %t965, i64 432
  %t1065 = bitcast i8* %t1064 to i32*
  store i32 %t1061, i32* %t1065
  %t1066 = add i32 %t1058, %t1061
  %t1067 = add i32 %t1066, 3
  store i8 43, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1068 = load i32, i32* %t968
  %t1069 = icmp sgt i32 %t1068, 0
  %t1070 = select i1 %t1069, i32 %t1068, i32 1
  %t1071 = getelementptr inbounds i8, i8* %t965, i64 56
  %t1072 = bitcast i8* %t1071 to i32*
  store i32 %t1067, i32* %t1072
  %t1073 = getelementptr inbounds i8, i8* %t965, i64 436
  %t1074 = bitcast i8* %t1073 to i32*
  store i32 %t1070, i32* %t1074
  %t1075 = add i32 %t1067, %t1070
  %t1076 = add i32 %t1075, 3
  store i8 44, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1077 = load i32, i32* %t968
  %t1078 = icmp sgt i32 %t1077, 0
  %t1079 = select i1 %t1078, i32 %t1077, i32 1
  %t1080 = getelementptr inbounds i8, i8* %t965, i64 60
  %t1081 = bitcast i8* %t1080 to i32*
  store i32 %t1076, i32* %t1081
  %t1082 = getelementptr inbounds i8, i8* %t965, i64 440
  %t1083 = bitcast i8* %t1082 to i32*
  store i32 %t1079, i32* %t1083
  %t1084 = add i32 %t1076, %t1079
  %t1085 = add i32 %t1084, 3
  store i8 45, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1086 = load i32, i32* %t968
  %t1087 = icmp sgt i32 %t1086, 0
  %t1088 = select i1 %t1087, i32 %t1086, i32 1
  %t1089 = getelementptr inbounds i8, i8* %t965, i64 64
  %t1090 = bitcast i8* %t1089 to i32*
  store i32 %t1085, i32* %t1090
  %t1091 = getelementptr inbounds i8, i8* %t965, i64 444
  %t1092 = bitcast i8* %t1091 to i32*
  store i32 %t1088, i32* %t1092
  %t1093 = add i32 %t1085, %t1088
  %t1094 = add i32 %t1093, 3
  store i8 46, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1095 = load i32, i32* %t968
  %t1096 = icmp sgt i32 %t1095, 0
  %t1097 = select i1 %t1096, i32 %t1095, i32 1
  %t1098 = getelementptr inbounds i8, i8* %t965, i64 68
  %t1099 = bitcast i8* %t1098 to i32*
  store i32 %t1094, i32* %t1099
  %t1100 = getelementptr inbounds i8, i8* %t965, i64 448
  %t1101 = bitcast i8* %t1100 to i32*
  store i32 %t1097, i32* %t1101
  %t1102 = add i32 %t1094, %t1097
  %t1103 = add i32 %t1102, 3
  store i8 47, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1104 = load i32, i32* %t968
  %t1105 = icmp sgt i32 %t1104, 0
  %t1106 = select i1 %t1105, i32 %t1104, i32 1
  %t1107 = getelementptr inbounds i8, i8* %t965, i64 72
  %t1108 = bitcast i8* %t1107 to i32*
  store i32 %t1103, i32* %t1108
  %t1109 = getelementptr inbounds i8, i8* %t965, i64 452
  %t1110 = bitcast i8* %t1109 to i32*
  store i32 %t1106, i32* %t1110
  %t1111 = add i32 %t1103, %t1106
  %t1112 = add i32 %t1111, 3
  store i8 48, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1113 = load i32, i32* %t968
  %t1114 = icmp sgt i32 %t1113, 0
  %t1115 = select i1 %t1114, i32 %t1113, i32 1
  %t1116 = getelementptr inbounds i8, i8* %t965, i64 76
  %t1117 = bitcast i8* %t1116 to i32*
  store i32 %t1112, i32* %t1117
  %t1118 = getelementptr inbounds i8, i8* %t965, i64 456
  %t1119 = bitcast i8* %t1118 to i32*
  store i32 %t1115, i32* %t1119
  %t1120 = add i32 %t1112, %t1115
  %t1121 = add i32 %t1120, 3
  store i8 49, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1122 = load i32, i32* %t968
  %t1123 = icmp sgt i32 %t1122, 0
  %t1124 = select i1 %t1123, i32 %t1122, i32 1
  %t1125 = getelementptr inbounds i8, i8* %t965, i64 80
  %t1126 = bitcast i8* %t1125 to i32*
  store i32 %t1121, i32* %t1126
  %t1127 = getelementptr inbounds i8, i8* %t965, i64 460
  %t1128 = bitcast i8* %t1127 to i32*
  store i32 %t1124, i32* %t1128
  %t1129 = add i32 %t1121, %t1124
  %t1130 = add i32 %t1129, 3
  store i8 50, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1131 = load i32, i32* %t968
  %t1132 = icmp sgt i32 %t1131, 0
  %t1133 = select i1 %t1132, i32 %t1131, i32 1
  %t1134 = getelementptr inbounds i8, i8* %t965, i64 84
  %t1135 = bitcast i8* %t1134 to i32*
  store i32 %t1130, i32* %t1135
  %t1136 = getelementptr inbounds i8, i8* %t965, i64 464
  %t1137 = bitcast i8* %t1136 to i32*
  store i32 %t1133, i32* %t1137
  %t1138 = add i32 %t1130, %t1133
  %t1139 = add i32 %t1138, 3
  store i8 51, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1140 = load i32, i32* %t968
  %t1141 = icmp sgt i32 %t1140, 0
  %t1142 = select i1 %t1141, i32 %t1140, i32 1
  %t1143 = getelementptr inbounds i8, i8* %t965, i64 88
  %t1144 = bitcast i8* %t1143 to i32*
  store i32 %t1139, i32* %t1144
  %t1145 = getelementptr inbounds i8, i8* %t965, i64 468
  %t1146 = bitcast i8* %t1145 to i32*
  store i32 %t1142, i32* %t1146
  %t1147 = add i32 %t1139, %t1142
  %t1148 = add i32 %t1147, 3
  store i8 52, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1149 = load i32, i32* %t968
  %t1150 = icmp sgt i32 %t1149, 0
  %t1151 = select i1 %t1150, i32 %t1149, i32 1
  %t1152 = getelementptr inbounds i8, i8* %t965, i64 92
  %t1153 = bitcast i8* %t1152 to i32*
  store i32 %t1148, i32* %t1153
  %t1154 = getelementptr inbounds i8, i8* %t965, i64 472
  %t1155 = bitcast i8* %t1154 to i32*
  store i32 %t1151, i32* %t1155
  %t1156 = add i32 %t1148, %t1151
  %t1157 = add i32 %t1156, 3
  store i8 53, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1158 = load i32, i32* %t968
  %t1159 = icmp sgt i32 %t1158, 0
  %t1160 = select i1 %t1159, i32 %t1158, i32 1
  %t1161 = getelementptr inbounds i8, i8* %t965, i64 96
  %t1162 = bitcast i8* %t1161 to i32*
  store i32 %t1157, i32* %t1162
  %t1163 = getelementptr inbounds i8, i8* %t965, i64 476
  %t1164 = bitcast i8* %t1163 to i32*
  store i32 %t1160, i32* %t1164
  %t1165 = add i32 %t1157, %t1160
  %t1166 = add i32 %t1165, 3
  store i8 54, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1167 = load i32, i32* %t968
  %t1168 = icmp sgt i32 %t1167, 0
  %t1169 = select i1 %t1168, i32 %t1167, i32 1
  %t1170 = getelementptr inbounds i8, i8* %t965, i64 100
  %t1171 = bitcast i8* %t1170 to i32*
  store i32 %t1166, i32* %t1171
  %t1172 = getelementptr inbounds i8, i8* %t965, i64 480
  %t1173 = bitcast i8* %t1172 to i32*
  store i32 %t1169, i32* %t1173
  %t1174 = add i32 %t1166, %t1169
  %t1175 = add i32 %t1174, 3
  store i8 55, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1176 = load i32, i32* %t968
  %t1177 = icmp sgt i32 %t1176, 0
  %t1178 = select i1 %t1177, i32 %t1176, i32 1
  %t1179 = getelementptr inbounds i8, i8* %t965, i64 104
  %t1180 = bitcast i8* %t1179 to i32*
  store i32 %t1175, i32* %t1180
  %t1181 = getelementptr inbounds i8, i8* %t965, i64 484
  %t1182 = bitcast i8* %t1181 to i32*
  store i32 %t1178, i32* %t1182
  %t1183 = add i32 %t1175, %t1178
  %t1184 = add i32 %t1183, 3
  store i8 56, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1185 = load i32, i32* %t968
  %t1186 = icmp sgt i32 %t1185, 0
  %t1187 = select i1 %t1186, i32 %t1185, i32 1
  %t1188 = getelementptr inbounds i8, i8* %t965, i64 108
  %t1189 = bitcast i8* %t1188 to i32*
  store i32 %t1184, i32* %t1189
  %t1190 = getelementptr inbounds i8, i8* %t965, i64 488
  %t1191 = bitcast i8* %t1190 to i32*
  store i32 %t1187, i32* %t1191
  %t1192 = add i32 %t1184, %t1187
  %t1193 = add i32 %t1192, 3
  store i8 57, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1194 = load i32, i32* %t968
  %t1195 = icmp sgt i32 %t1194, 0
  %t1196 = select i1 %t1195, i32 %t1194, i32 1
  %t1197 = getelementptr inbounds i8, i8* %t965, i64 112
  %t1198 = bitcast i8* %t1197 to i32*
  store i32 %t1193, i32* %t1198
  %t1199 = getelementptr inbounds i8, i8* %t965, i64 492
  %t1200 = bitcast i8* %t1199 to i32*
  store i32 %t1196, i32* %t1200
  %t1201 = add i32 %t1193, %t1196
  %t1202 = add i32 %t1201, 3
  store i8 58, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1203 = load i32, i32* %t968
  %t1204 = icmp sgt i32 %t1203, 0
  %t1205 = select i1 %t1204, i32 %t1203, i32 1
  %t1206 = getelementptr inbounds i8, i8* %t965, i64 116
  %t1207 = bitcast i8* %t1206 to i32*
  store i32 %t1202, i32* %t1207
  %t1208 = getelementptr inbounds i8, i8* %t965, i64 496
  %t1209 = bitcast i8* %t1208 to i32*
  store i32 %t1205, i32* %t1209
  %t1210 = add i32 %t1202, %t1205
  %t1211 = add i32 %t1210, 3
  store i8 59, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1212 = load i32, i32* %t968
  %t1213 = icmp sgt i32 %t1212, 0
  %t1214 = select i1 %t1213, i32 %t1212, i32 1
  %t1215 = getelementptr inbounds i8, i8* %t965, i64 120
  %t1216 = bitcast i8* %t1215 to i32*
  store i32 %t1211, i32* %t1216
  %t1217 = getelementptr inbounds i8, i8* %t965, i64 500
  %t1218 = bitcast i8* %t1217 to i32*
  store i32 %t1214, i32* %t1218
  %t1219 = add i32 %t1211, %t1214
  %t1220 = add i32 %t1219, 3
  store i8 60, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1221 = load i32, i32* %t968
  %t1222 = icmp sgt i32 %t1221, 0
  %t1223 = select i1 %t1222, i32 %t1221, i32 1
  %t1224 = getelementptr inbounds i8, i8* %t965, i64 124
  %t1225 = bitcast i8* %t1224 to i32*
  store i32 %t1220, i32* %t1225
  %t1226 = getelementptr inbounds i8, i8* %t965, i64 504
  %t1227 = bitcast i8* %t1226 to i32*
  store i32 %t1223, i32* %t1227
  %t1228 = add i32 %t1220, %t1223
  %t1229 = add i32 %t1228, 3
  store i8 61, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1230 = load i32, i32* %t968
  %t1231 = icmp sgt i32 %t1230, 0
  %t1232 = select i1 %t1231, i32 %t1230, i32 1
  %t1233 = getelementptr inbounds i8, i8* %t965, i64 128
  %t1234 = bitcast i8* %t1233 to i32*
  store i32 %t1229, i32* %t1234
  %t1235 = getelementptr inbounds i8, i8* %t965, i64 508
  %t1236 = bitcast i8* %t1235 to i32*
  store i32 %t1232, i32* %t1236
  %t1237 = add i32 %t1229, %t1232
  %t1238 = add i32 %t1237, 3
  store i8 62, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1239 = load i32, i32* %t968
  %t1240 = icmp sgt i32 %t1239, 0
  %t1241 = select i1 %t1240, i32 %t1239, i32 1
  %t1242 = getelementptr inbounds i8, i8* %t965, i64 132
  %t1243 = bitcast i8* %t1242 to i32*
  store i32 %t1238, i32* %t1243
  %t1244 = getelementptr inbounds i8, i8* %t965, i64 512
  %t1245 = bitcast i8* %t1244 to i32*
  store i32 %t1241, i32* %t1245
  %t1246 = add i32 %t1238, %t1241
  %t1247 = add i32 %t1246, 3
  store i8 63, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1248 = load i32, i32* %t968
  %t1249 = icmp sgt i32 %t1248, 0
  %t1250 = select i1 %t1249, i32 %t1248, i32 1
  %t1251 = getelementptr inbounds i8, i8* %t965, i64 136
  %t1252 = bitcast i8* %t1251 to i32*
  store i32 %t1247, i32* %t1252
  %t1253 = getelementptr inbounds i8, i8* %t965, i64 516
  %t1254 = bitcast i8* %t1253 to i32*
  store i32 %t1250, i32* %t1254
  %t1255 = add i32 %t1247, %t1250
  %t1256 = add i32 %t1255, 3
  store i8 64, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1257 = load i32, i32* %t968
  %t1258 = icmp sgt i32 %t1257, 0
  %t1259 = select i1 %t1258, i32 %t1257, i32 1
  %t1260 = getelementptr inbounds i8, i8* %t965, i64 140
  %t1261 = bitcast i8* %t1260 to i32*
  store i32 %t1256, i32* %t1261
  %t1262 = getelementptr inbounds i8, i8* %t965, i64 520
  %t1263 = bitcast i8* %t1262 to i32*
  store i32 %t1259, i32* %t1263
  %t1264 = add i32 %t1256, %t1259
  %t1265 = add i32 %t1264, 3
  store i8 65, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1266 = load i32, i32* %t968
  %t1267 = icmp sgt i32 %t1266, 0
  %t1268 = select i1 %t1267, i32 %t1266, i32 1
  %t1269 = getelementptr inbounds i8, i8* %t965, i64 144
  %t1270 = bitcast i8* %t1269 to i32*
  store i32 %t1265, i32* %t1270
  %t1271 = getelementptr inbounds i8, i8* %t965, i64 524
  %t1272 = bitcast i8* %t1271 to i32*
  store i32 %t1268, i32* %t1272
  %t1273 = add i32 %t1265, %t1268
  %t1274 = add i32 %t1273, 3
  store i8 66, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1275 = load i32, i32* %t968
  %t1276 = icmp sgt i32 %t1275, 0
  %t1277 = select i1 %t1276, i32 %t1275, i32 1
  %t1278 = getelementptr inbounds i8, i8* %t965, i64 148
  %t1279 = bitcast i8* %t1278 to i32*
  store i32 %t1274, i32* %t1279
  %t1280 = getelementptr inbounds i8, i8* %t965, i64 528
  %t1281 = bitcast i8* %t1280 to i32*
  store i32 %t1277, i32* %t1281
  %t1282 = add i32 %t1274, %t1277
  %t1283 = add i32 %t1282, 3
  store i8 67, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1284 = load i32, i32* %t968
  %t1285 = icmp sgt i32 %t1284, 0
  %t1286 = select i1 %t1285, i32 %t1284, i32 1
  %t1287 = getelementptr inbounds i8, i8* %t965, i64 152
  %t1288 = bitcast i8* %t1287 to i32*
  store i32 %t1283, i32* %t1288
  %t1289 = getelementptr inbounds i8, i8* %t965, i64 532
  %t1290 = bitcast i8* %t1289 to i32*
  store i32 %t1286, i32* %t1290
  %t1291 = add i32 %t1283, %t1286
  %t1292 = add i32 %t1291, 3
  store i8 68, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1293 = load i32, i32* %t968
  %t1294 = icmp sgt i32 %t1293, 0
  %t1295 = select i1 %t1294, i32 %t1293, i32 1
  %t1296 = getelementptr inbounds i8, i8* %t965, i64 156
  %t1297 = bitcast i8* %t1296 to i32*
  store i32 %t1292, i32* %t1297
  %t1298 = getelementptr inbounds i8, i8* %t965, i64 536
  %t1299 = bitcast i8* %t1298 to i32*
  store i32 %t1295, i32* %t1299
  %t1300 = add i32 %t1292, %t1295
  %t1301 = add i32 %t1300, 3
  store i8 69, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1302 = load i32, i32* %t968
  %t1303 = icmp sgt i32 %t1302, 0
  %t1304 = select i1 %t1303, i32 %t1302, i32 1
  %t1305 = getelementptr inbounds i8, i8* %t965, i64 160
  %t1306 = bitcast i8* %t1305 to i32*
  store i32 %t1301, i32* %t1306
  %t1307 = getelementptr inbounds i8, i8* %t965, i64 540
  %t1308 = bitcast i8* %t1307 to i32*
  store i32 %t1304, i32* %t1308
  %t1309 = add i32 %t1301, %t1304
  %t1310 = add i32 %t1309, 3
  store i8 70, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1311 = load i32, i32* %t968
  %t1312 = icmp sgt i32 %t1311, 0
  %t1313 = select i1 %t1312, i32 %t1311, i32 1
  %t1314 = getelementptr inbounds i8, i8* %t965, i64 164
  %t1315 = bitcast i8* %t1314 to i32*
  store i32 %t1310, i32* %t1315
  %t1316 = getelementptr inbounds i8, i8* %t965, i64 544
  %t1317 = bitcast i8* %t1316 to i32*
  store i32 %t1313, i32* %t1317
  %t1318 = add i32 %t1310, %t1313
  %t1319 = add i32 %t1318, 3
  store i8 71, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1320 = load i32, i32* %t968
  %t1321 = icmp sgt i32 %t1320, 0
  %t1322 = select i1 %t1321, i32 %t1320, i32 1
  %t1323 = getelementptr inbounds i8, i8* %t965, i64 168
  %t1324 = bitcast i8* %t1323 to i32*
  store i32 %t1319, i32* %t1324
  %t1325 = getelementptr inbounds i8, i8* %t965, i64 548
  %t1326 = bitcast i8* %t1325 to i32*
  store i32 %t1322, i32* %t1326
  %t1327 = add i32 %t1319, %t1322
  %t1328 = add i32 %t1327, 3
  store i8 72, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1329 = load i32, i32* %t968
  %t1330 = icmp sgt i32 %t1329, 0
  %t1331 = select i1 %t1330, i32 %t1329, i32 1
  %t1332 = getelementptr inbounds i8, i8* %t965, i64 172
  %t1333 = bitcast i8* %t1332 to i32*
  store i32 %t1328, i32* %t1333
  %t1334 = getelementptr inbounds i8, i8* %t965, i64 552
  %t1335 = bitcast i8* %t1334 to i32*
  store i32 %t1331, i32* %t1335
  %t1336 = add i32 %t1328, %t1331
  %t1337 = add i32 %t1336, 3
  store i8 73, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1338 = load i32, i32* %t968
  %t1339 = icmp sgt i32 %t1338, 0
  %t1340 = select i1 %t1339, i32 %t1338, i32 1
  %t1341 = getelementptr inbounds i8, i8* %t965, i64 176
  %t1342 = bitcast i8* %t1341 to i32*
  store i32 %t1337, i32* %t1342
  %t1343 = getelementptr inbounds i8, i8* %t965, i64 556
  %t1344 = bitcast i8* %t1343 to i32*
  store i32 %t1340, i32* %t1344
  %t1345 = add i32 %t1337, %t1340
  %t1346 = add i32 %t1345, 3
  store i8 74, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1347 = load i32, i32* %t968
  %t1348 = icmp sgt i32 %t1347, 0
  %t1349 = select i1 %t1348, i32 %t1347, i32 1
  %t1350 = getelementptr inbounds i8, i8* %t965, i64 180
  %t1351 = bitcast i8* %t1350 to i32*
  store i32 %t1346, i32* %t1351
  %t1352 = getelementptr inbounds i8, i8* %t965, i64 560
  %t1353 = bitcast i8* %t1352 to i32*
  store i32 %t1349, i32* %t1353
  %t1354 = add i32 %t1346, %t1349
  %t1355 = add i32 %t1354, 3
  store i8 75, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1356 = load i32, i32* %t968
  %t1357 = icmp sgt i32 %t1356, 0
  %t1358 = select i1 %t1357, i32 %t1356, i32 1
  %t1359 = getelementptr inbounds i8, i8* %t965, i64 184
  %t1360 = bitcast i8* %t1359 to i32*
  store i32 %t1355, i32* %t1360
  %t1361 = getelementptr inbounds i8, i8* %t965, i64 564
  %t1362 = bitcast i8* %t1361 to i32*
  store i32 %t1358, i32* %t1362
  %t1363 = add i32 %t1355, %t1358
  %t1364 = add i32 %t1363, 3
  store i8 76, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1365 = load i32, i32* %t968
  %t1366 = icmp sgt i32 %t1365, 0
  %t1367 = select i1 %t1366, i32 %t1365, i32 1
  %t1368 = getelementptr inbounds i8, i8* %t965, i64 188
  %t1369 = bitcast i8* %t1368 to i32*
  store i32 %t1364, i32* %t1369
  %t1370 = getelementptr inbounds i8, i8* %t965, i64 568
  %t1371 = bitcast i8* %t1370 to i32*
  store i32 %t1367, i32* %t1371
  %t1372 = add i32 %t1364, %t1367
  %t1373 = add i32 %t1372, 3
  store i8 77, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1374 = load i32, i32* %t968
  %t1375 = icmp sgt i32 %t1374, 0
  %t1376 = select i1 %t1375, i32 %t1374, i32 1
  %t1377 = getelementptr inbounds i8, i8* %t965, i64 192
  %t1378 = bitcast i8* %t1377 to i32*
  store i32 %t1373, i32* %t1378
  %t1379 = getelementptr inbounds i8, i8* %t965, i64 572
  %t1380 = bitcast i8* %t1379 to i32*
  store i32 %t1376, i32* %t1380
  %t1381 = add i32 %t1373, %t1376
  %t1382 = add i32 %t1381, 3
  store i8 78, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1383 = load i32, i32* %t968
  %t1384 = icmp sgt i32 %t1383, 0
  %t1385 = select i1 %t1384, i32 %t1383, i32 1
  %t1386 = getelementptr inbounds i8, i8* %t965, i64 196
  %t1387 = bitcast i8* %t1386 to i32*
  store i32 %t1382, i32* %t1387
  %t1388 = getelementptr inbounds i8, i8* %t965, i64 576
  %t1389 = bitcast i8* %t1388 to i32*
  store i32 %t1385, i32* %t1389
  %t1390 = add i32 %t1382, %t1385
  %t1391 = add i32 %t1390, 3
  store i8 79, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1392 = load i32, i32* %t968
  %t1393 = icmp sgt i32 %t1392, 0
  %t1394 = select i1 %t1393, i32 %t1392, i32 1
  %t1395 = getelementptr inbounds i8, i8* %t965, i64 200
  %t1396 = bitcast i8* %t1395 to i32*
  store i32 %t1391, i32* %t1396
  %t1397 = getelementptr inbounds i8, i8* %t965, i64 580
  %t1398 = bitcast i8* %t1397 to i32*
  store i32 %t1394, i32* %t1398
  %t1399 = add i32 %t1391, %t1394
  %t1400 = add i32 %t1399, 3
  store i8 80, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1401 = load i32, i32* %t968
  %t1402 = icmp sgt i32 %t1401, 0
  %t1403 = select i1 %t1402, i32 %t1401, i32 1
  %t1404 = getelementptr inbounds i8, i8* %t965, i64 204
  %t1405 = bitcast i8* %t1404 to i32*
  store i32 %t1400, i32* %t1405
  %t1406 = getelementptr inbounds i8, i8* %t965, i64 584
  %t1407 = bitcast i8* %t1406 to i32*
  store i32 %t1403, i32* %t1407
  %t1408 = add i32 %t1400, %t1403
  %t1409 = add i32 %t1408, 3
  store i8 81, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1410 = load i32, i32* %t968
  %t1411 = icmp sgt i32 %t1410, 0
  %t1412 = select i1 %t1411, i32 %t1410, i32 1
  %t1413 = getelementptr inbounds i8, i8* %t965, i64 208
  %t1414 = bitcast i8* %t1413 to i32*
  store i32 %t1409, i32* %t1414
  %t1415 = getelementptr inbounds i8, i8* %t965, i64 588
  %t1416 = bitcast i8* %t1415 to i32*
  store i32 %t1412, i32* %t1416
  %t1417 = add i32 %t1409, %t1412
  %t1418 = add i32 %t1417, 3
  store i8 82, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1419 = load i32, i32* %t968
  %t1420 = icmp sgt i32 %t1419, 0
  %t1421 = select i1 %t1420, i32 %t1419, i32 1
  %t1422 = getelementptr inbounds i8, i8* %t965, i64 212
  %t1423 = bitcast i8* %t1422 to i32*
  store i32 %t1418, i32* %t1423
  %t1424 = getelementptr inbounds i8, i8* %t965, i64 592
  %t1425 = bitcast i8* %t1424 to i32*
  store i32 %t1421, i32* %t1425
  %t1426 = add i32 %t1418, %t1421
  %t1427 = add i32 %t1426, 3
  store i8 83, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1428 = load i32, i32* %t968
  %t1429 = icmp sgt i32 %t1428, 0
  %t1430 = select i1 %t1429, i32 %t1428, i32 1
  %t1431 = getelementptr inbounds i8, i8* %t965, i64 216
  %t1432 = bitcast i8* %t1431 to i32*
  store i32 %t1427, i32* %t1432
  %t1433 = getelementptr inbounds i8, i8* %t965, i64 596
  %t1434 = bitcast i8* %t1433 to i32*
  store i32 %t1430, i32* %t1434
  %t1435 = add i32 %t1427, %t1430
  %t1436 = add i32 %t1435, 3
  store i8 84, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1437 = load i32, i32* %t968
  %t1438 = icmp sgt i32 %t1437, 0
  %t1439 = select i1 %t1438, i32 %t1437, i32 1
  %t1440 = getelementptr inbounds i8, i8* %t965, i64 220
  %t1441 = bitcast i8* %t1440 to i32*
  store i32 %t1436, i32* %t1441
  %t1442 = getelementptr inbounds i8, i8* %t965, i64 600
  %t1443 = bitcast i8* %t1442 to i32*
  store i32 %t1439, i32* %t1443
  %t1444 = add i32 %t1436, %t1439
  %t1445 = add i32 %t1444, 3
  store i8 85, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1446 = load i32, i32* %t968
  %t1447 = icmp sgt i32 %t1446, 0
  %t1448 = select i1 %t1447, i32 %t1446, i32 1
  %t1449 = getelementptr inbounds i8, i8* %t965, i64 224
  %t1450 = bitcast i8* %t1449 to i32*
  store i32 %t1445, i32* %t1450
  %t1451 = getelementptr inbounds i8, i8* %t965, i64 604
  %t1452 = bitcast i8* %t1451 to i32*
  store i32 %t1448, i32* %t1452
  %t1453 = add i32 %t1445, %t1448
  %t1454 = add i32 %t1453, 3
  store i8 86, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1455 = load i32, i32* %t968
  %t1456 = icmp sgt i32 %t1455, 0
  %t1457 = select i1 %t1456, i32 %t1455, i32 1
  %t1458 = getelementptr inbounds i8, i8* %t965, i64 228
  %t1459 = bitcast i8* %t1458 to i32*
  store i32 %t1454, i32* %t1459
  %t1460 = getelementptr inbounds i8, i8* %t965, i64 608
  %t1461 = bitcast i8* %t1460 to i32*
  store i32 %t1457, i32* %t1461
  %t1462 = add i32 %t1454, %t1457
  %t1463 = add i32 %t1462, 3
  store i8 87, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1464 = load i32, i32* %t968
  %t1465 = icmp sgt i32 %t1464, 0
  %t1466 = select i1 %t1465, i32 %t1464, i32 1
  %t1467 = getelementptr inbounds i8, i8* %t965, i64 232
  %t1468 = bitcast i8* %t1467 to i32*
  store i32 %t1463, i32* %t1468
  %t1469 = getelementptr inbounds i8, i8* %t965, i64 612
  %t1470 = bitcast i8* %t1469 to i32*
  store i32 %t1466, i32* %t1470
  %t1471 = add i32 %t1463, %t1466
  %t1472 = add i32 %t1471, 3
  store i8 88, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1473 = load i32, i32* %t968
  %t1474 = icmp sgt i32 %t1473, 0
  %t1475 = select i1 %t1474, i32 %t1473, i32 1
  %t1476 = getelementptr inbounds i8, i8* %t965, i64 236
  %t1477 = bitcast i8* %t1476 to i32*
  store i32 %t1472, i32* %t1477
  %t1478 = getelementptr inbounds i8, i8* %t965, i64 616
  %t1479 = bitcast i8* %t1478 to i32*
  store i32 %t1475, i32* %t1479
  %t1480 = add i32 %t1472, %t1475
  %t1481 = add i32 %t1480, 3
  store i8 89, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1482 = load i32, i32* %t968
  %t1483 = icmp sgt i32 %t1482, 0
  %t1484 = select i1 %t1483, i32 %t1482, i32 1
  %t1485 = getelementptr inbounds i8, i8* %t965, i64 240
  %t1486 = bitcast i8* %t1485 to i32*
  store i32 %t1481, i32* %t1486
  %t1487 = getelementptr inbounds i8, i8* %t965, i64 620
  %t1488 = bitcast i8* %t1487 to i32*
  store i32 %t1484, i32* %t1488
  %t1489 = add i32 %t1481, %t1484
  %t1490 = add i32 %t1489, 3
  store i8 90, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1491 = load i32, i32* %t968
  %t1492 = icmp sgt i32 %t1491, 0
  %t1493 = select i1 %t1492, i32 %t1491, i32 1
  %t1494 = getelementptr inbounds i8, i8* %t965, i64 244
  %t1495 = bitcast i8* %t1494 to i32*
  store i32 %t1490, i32* %t1495
  %t1496 = getelementptr inbounds i8, i8* %t965, i64 624
  %t1497 = bitcast i8* %t1496 to i32*
  store i32 %t1493, i32* %t1497
  %t1498 = add i32 %t1490, %t1493
  %t1499 = add i32 %t1498, 3
  store i8 91, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1500 = load i32, i32* %t968
  %t1501 = icmp sgt i32 %t1500, 0
  %t1502 = select i1 %t1501, i32 %t1500, i32 1
  %t1503 = getelementptr inbounds i8, i8* %t965, i64 248
  %t1504 = bitcast i8* %t1503 to i32*
  store i32 %t1499, i32* %t1504
  %t1505 = getelementptr inbounds i8, i8* %t965, i64 628
  %t1506 = bitcast i8* %t1505 to i32*
  store i32 %t1502, i32* %t1506
  %t1507 = add i32 %t1499, %t1502
  %t1508 = add i32 %t1507, 3
  store i8 92, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1509 = load i32, i32* %t968
  %t1510 = icmp sgt i32 %t1509, 0
  %t1511 = select i1 %t1510, i32 %t1509, i32 1
  %t1512 = getelementptr inbounds i8, i8* %t965, i64 252
  %t1513 = bitcast i8* %t1512 to i32*
  store i32 %t1508, i32* %t1513
  %t1514 = getelementptr inbounds i8, i8* %t965, i64 632
  %t1515 = bitcast i8* %t1514 to i32*
  store i32 %t1511, i32* %t1515
  %t1516 = add i32 %t1508, %t1511
  %t1517 = add i32 %t1516, 3
  store i8 93, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1518 = load i32, i32* %t968
  %t1519 = icmp sgt i32 %t1518, 0
  %t1520 = select i1 %t1519, i32 %t1518, i32 1
  %t1521 = getelementptr inbounds i8, i8* %t965, i64 256
  %t1522 = bitcast i8* %t1521 to i32*
  store i32 %t1517, i32* %t1522
  %t1523 = getelementptr inbounds i8, i8* %t965, i64 636
  %t1524 = bitcast i8* %t1523 to i32*
  store i32 %t1520, i32* %t1524
  %t1525 = add i32 %t1517, %t1520
  %t1526 = add i32 %t1525, 3
  store i8 94, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1527 = load i32, i32* %t968
  %t1528 = icmp sgt i32 %t1527, 0
  %t1529 = select i1 %t1528, i32 %t1527, i32 1
  %t1530 = getelementptr inbounds i8, i8* %t965, i64 260
  %t1531 = bitcast i8* %t1530 to i32*
  store i32 %t1526, i32* %t1531
  %t1532 = getelementptr inbounds i8, i8* %t965, i64 640
  %t1533 = bitcast i8* %t1532 to i32*
  store i32 %t1529, i32* %t1533
  %t1534 = add i32 %t1526, %t1529
  %t1535 = add i32 %t1534, 3
  store i8 95, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1536 = load i32, i32* %t968
  %t1537 = icmp sgt i32 %t1536, 0
  %t1538 = select i1 %t1537, i32 %t1536, i32 1
  %t1539 = getelementptr inbounds i8, i8* %t965, i64 264
  %t1540 = bitcast i8* %t1539 to i32*
  store i32 %t1535, i32* %t1540
  %t1541 = getelementptr inbounds i8, i8* %t965, i64 644
  %t1542 = bitcast i8* %t1541 to i32*
  store i32 %t1538, i32* %t1542
  %t1543 = add i32 %t1535, %t1538
  %t1544 = add i32 %t1543, 3
  store i8 96, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1545 = load i32, i32* %t968
  %t1546 = icmp sgt i32 %t1545, 0
  %t1547 = select i1 %t1546, i32 %t1545, i32 1
  %t1548 = getelementptr inbounds i8, i8* %t965, i64 268
  %t1549 = bitcast i8* %t1548 to i32*
  store i32 %t1544, i32* %t1549
  %t1550 = getelementptr inbounds i8, i8* %t965, i64 648
  %t1551 = bitcast i8* %t1550 to i32*
  store i32 %t1547, i32* %t1551
  %t1552 = add i32 %t1544, %t1547
  %t1553 = add i32 %t1552, 3
  store i8 97, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1554 = load i32, i32* %t968
  %t1555 = icmp sgt i32 %t1554, 0
  %t1556 = select i1 %t1555, i32 %t1554, i32 1
  %t1557 = getelementptr inbounds i8, i8* %t965, i64 272
  %t1558 = bitcast i8* %t1557 to i32*
  store i32 %t1553, i32* %t1558
  %t1559 = getelementptr inbounds i8, i8* %t965, i64 652
  %t1560 = bitcast i8* %t1559 to i32*
  store i32 %t1556, i32* %t1560
  %t1561 = add i32 %t1553, %t1556
  %t1562 = add i32 %t1561, 3
  store i8 98, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1563 = load i32, i32* %t968
  %t1564 = icmp sgt i32 %t1563, 0
  %t1565 = select i1 %t1564, i32 %t1563, i32 1
  %t1566 = getelementptr inbounds i8, i8* %t965, i64 276
  %t1567 = bitcast i8* %t1566 to i32*
  store i32 %t1562, i32* %t1567
  %t1568 = getelementptr inbounds i8, i8* %t965, i64 656
  %t1569 = bitcast i8* %t1568 to i32*
  store i32 %t1565, i32* %t1569
  %t1570 = add i32 %t1562, %t1565
  %t1571 = add i32 %t1570, 3
  store i8 99, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1572 = load i32, i32* %t968
  %t1573 = icmp sgt i32 %t1572, 0
  %t1574 = select i1 %t1573, i32 %t1572, i32 1
  %t1575 = getelementptr inbounds i8, i8* %t965, i64 280
  %t1576 = bitcast i8* %t1575 to i32*
  store i32 %t1571, i32* %t1576
  %t1577 = getelementptr inbounds i8, i8* %t965, i64 660
  %t1578 = bitcast i8* %t1577 to i32*
  store i32 %t1574, i32* %t1578
  %t1579 = add i32 %t1571, %t1574
  %t1580 = add i32 %t1579, 3
  store i8 100, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1581 = load i32, i32* %t968
  %t1582 = icmp sgt i32 %t1581, 0
  %t1583 = select i1 %t1582, i32 %t1581, i32 1
  %t1584 = getelementptr inbounds i8, i8* %t965, i64 284
  %t1585 = bitcast i8* %t1584 to i32*
  store i32 %t1580, i32* %t1585
  %t1586 = getelementptr inbounds i8, i8* %t965, i64 664
  %t1587 = bitcast i8* %t1586 to i32*
  store i32 %t1583, i32* %t1587
  %t1588 = add i32 %t1580, %t1583
  %t1589 = add i32 %t1588, 3
  store i8 101, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1590 = load i32, i32* %t968
  %t1591 = icmp sgt i32 %t1590, 0
  %t1592 = select i1 %t1591, i32 %t1590, i32 1
  %t1593 = getelementptr inbounds i8, i8* %t965, i64 288
  %t1594 = bitcast i8* %t1593 to i32*
  store i32 %t1589, i32* %t1594
  %t1595 = getelementptr inbounds i8, i8* %t965, i64 668
  %t1596 = bitcast i8* %t1595 to i32*
  store i32 %t1592, i32* %t1596
  %t1597 = add i32 %t1589, %t1592
  %t1598 = add i32 %t1597, 3
  store i8 102, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1599 = load i32, i32* %t968
  %t1600 = icmp sgt i32 %t1599, 0
  %t1601 = select i1 %t1600, i32 %t1599, i32 1
  %t1602 = getelementptr inbounds i8, i8* %t965, i64 292
  %t1603 = bitcast i8* %t1602 to i32*
  store i32 %t1598, i32* %t1603
  %t1604 = getelementptr inbounds i8, i8* %t965, i64 672
  %t1605 = bitcast i8* %t1604 to i32*
  store i32 %t1601, i32* %t1605
  %t1606 = add i32 %t1598, %t1601
  %t1607 = add i32 %t1606, 3
  store i8 103, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1608 = load i32, i32* %t968
  %t1609 = icmp sgt i32 %t1608, 0
  %t1610 = select i1 %t1609, i32 %t1608, i32 1
  %t1611 = getelementptr inbounds i8, i8* %t965, i64 296
  %t1612 = bitcast i8* %t1611 to i32*
  store i32 %t1607, i32* %t1612
  %t1613 = getelementptr inbounds i8, i8* %t965, i64 676
  %t1614 = bitcast i8* %t1613 to i32*
  store i32 %t1610, i32* %t1614
  %t1615 = add i32 %t1607, %t1610
  %t1616 = add i32 %t1615, 3
  store i8 104, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1617 = load i32, i32* %t968
  %t1618 = icmp sgt i32 %t1617, 0
  %t1619 = select i1 %t1618, i32 %t1617, i32 1
  %t1620 = getelementptr inbounds i8, i8* %t965, i64 300
  %t1621 = bitcast i8* %t1620 to i32*
  store i32 %t1616, i32* %t1621
  %t1622 = getelementptr inbounds i8, i8* %t965, i64 680
  %t1623 = bitcast i8* %t1622 to i32*
  store i32 %t1619, i32* %t1623
  %t1624 = add i32 %t1616, %t1619
  %t1625 = add i32 %t1624, 3
  store i8 105, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1626 = load i32, i32* %t968
  %t1627 = icmp sgt i32 %t1626, 0
  %t1628 = select i1 %t1627, i32 %t1626, i32 1
  %t1629 = getelementptr inbounds i8, i8* %t965, i64 304
  %t1630 = bitcast i8* %t1629 to i32*
  store i32 %t1625, i32* %t1630
  %t1631 = getelementptr inbounds i8, i8* %t965, i64 684
  %t1632 = bitcast i8* %t1631 to i32*
  store i32 %t1628, i32* %t1632
  %t1633 = add i32 %t1625, %t1628
  %t1634 = add i32 %t1633, 3
  store i8 106, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1635 = load i32, i32* %t968
  %t1636 = icmp sgt i32 %t1635, 0
  %t1637 = select i1 %t1636, i32 %t1635, i32 1
  %t1638 = getelementptr inbounds i8, i8* %t965, i64 308
  %t1639 = bitcast i8* %t1638 to i32*
  store i32 %t1634, i32* %t1639
  %t1640 = getelementptr inbounds i8, i8* %t965, i64 688
  %t1641 = bitcast i8* %t1640 to i32*
  store i32 %t1637, i32* %t1641
  %t1642 = add i32 %t1634, %t1637
  %t1643 = add i32 %t1642, 3
  store i8 107, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1644 = load i32, i32* %t968
  %t1645 = icmp sgt i32 %t1644, 0
  %t1646 = select i1 %t1645, i32 %t1644, i32 1
  %t1647 = getelementptr inbounds i8, i8* %t965, i64 312
  %t1648 = bitcast i8* %t1647 to i32*
  store i32 %t1643, i32* %t1648
  %t1649 = getelementptr inbounds i8, i8* %t965, i64 692
  %t1650 = bitcast i8* %t1649 to i32*
  store i32 %t1646, i32* %t1650
  %t1651 = add i32 %t1643, %t1646
  %t1652 = add i32 %t1651, 3
  store i8 108, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1653 = load i32, i32* %t968
  %t1654 = icmp sgt i32 %t1653, 0
  %t1655 = select i1 %t1654, i32 %t1653, i32 1
  %t1656 = getelementptr inbounds i8, i8* %t965, i64 316
  %t1657 = bitcast i8* %t1656 to i32*
  store i32 %t1652, i32* %t1657
  %t1658 = getelementptr inbounds i8, i8* %t965, i64 696
  %t1659 = bitcast i8* %t1658 to i32*
  store i32 %t1655, i32* %t1659
  %t1660 = add i32 %t1652, %t1655
  %t1661 = add i32 %t1660, 3
  store i8 109, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1662 = load i32, i32* %t968
  %t1663 = icmp sgt i32 %t1662, 0
  %t1664 = select i1 %t1663, i32 %t1662, i32 1
  %t1665 = getelementptr inbounds i8, i8* %t965, i64 320
  %t1666 = bitcast i8* %t1665 to i32*
  store i32 %t1661, i32* %t1666
  %t1667 = getelementptr inbounds i8, i8* %t965, i64 700
  %t1668 = bitcast i8* %t1667 to i32*
  store i32 %t1664, i32* %t1668
  %t1669 = add i32 %t1661, %t1664
  %t1670 = add i32 %t1669, 3
  store i8 110, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1671 = load i32, i32* %t968
  %t1672 = icmp sgt i32 %t1671, 0
  %t1673 = select i1 %t1672, i32 %t1671, i32 1
  %t1674 = getelementptr inbounds i8, i8* %t965, i64 324
  %t1675 = bitcast i8* %t1674 to i32*
  store i32 %t1670, i32* %t1675
  %t1676 = getelementptr inbounds i8, i8* %t965, i64 704
  %t1677 = bitcast i8* %t1676 to i32*
  store i32 %t1673, i32* %t1677
  %t1678 = add i32 %t1670, %t1673
  %t1679 = add i32 %t1678, 3
  store i8 111, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1680 = load i32, i32* %t968
  %t1681 = icmp sgt i32 %t1680, 0
  %t1682 = select i1 %t1681, i32 %t1680, i32 1
  %t1683 = getelementptr inbounds i8, i8* %t965, i64 328
  %t1684 = bitcast i8* %t1683 to i32*
  store i32 %t1679, i32* %t1684
  %t1685 = getelementptr inbounds i8, i8* %t965, i64 708
  %t1686 = bitcast i8* %t1685 to i32*
  store i32 %t1682, i32* %t1686
  %t1687 = add i32 %t1679, %t1682
  %t1688 = add i32 %t1687, 3
  store i8 112, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1689 = load i32, i32* %t968
  %t1690 = icmp sgt i32 %t1689, 0
  %t1691 = select i1 %t1690, i32 %t1689, i32 1
  %t1692 = getelementptr inbounds i8, i8* %t965, i64 332
  %t1693 = bitcast i8* %t1692 to i32*
  store i32 %t1688, i32* %t1693
  %t1694 = getelementptr inbounds i8, i8* %t965, i64 712
  %t1695 = bitcast i8* %t1694 to i32*
  store i32 %t1691, i32* %t1695
  %t1696 = add i32 %t1688, %t1691
  %t1697 = add i32 %t1696, 3
  store i8 113, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1698 = load i32, i32* %t968
  %t1699 = icmp sgt i32 %t1698, 0
  %t1700 = select i1 %t1699, i32 %t1698, i32 1
  %t1701 = getelementptr inbounds i8, i8* %t965, i64 336
  %t1702 = bitcast i8* %t1701 to i32*
  store i32 %t1697, i32* %t1702
  %t1703 = getelementptr inbounds i8, i8* %t965, i64 716
  %t1704 = bitcast i8* %t1703 to i32*
  store i32 %t1700, i32* %t1704
  %t1705 = add i32 %t1697, %t1700
  %t1706 = add i32 %t1705, 3
  store i8 114, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1707 = load i32, i32* %t968
  %t1708 = icmp sgt i32 %t1707, 0
  %t1709 = select i1 %t1708, i32 %t1707, i32 1
  %t1710 = getelementptr inbounds i8, i8* %t965, i64 340
  %t1711 = bitcast i8* %t1710 to i32*
  store i32 %t1706, i32* %t1711
  %t1712 = getelementptr inbounds i8, i8* %t965, i64 720
  %t1713 = bitcast i8* %t1712 to i32*
  store i32 %t1709, i32* %t1713
  %t1714 = add i32 %t1706, %t1709
  %t1715 = add i32 %t1714, 3
  store i8 115, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1716 = load i32, i32* %t968
  %t1717 = icmp sgt i32 %t1716, 0
  %t1718 = select i1 %t1717, i32 %t1716, i32 1
  %t1719 = getelementptr inbounds i8, i8* %t965, i64 344
  %t1720 = bitcast i8* %t1719 to i32*
  store i32 %t1715, i32* %t1720
  %t1721 = getelementptr inbounds i8, i8* %t965, i64 724
  %t1722 = bitcast i8* %t1721 to i32*
  store i32 %t1718, i32* %t1722
  %t1723 = add i32 %t1715, %t1718
  %t1724 = add i32 %t1723, 3
  store i8 116, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1725 = load i32, i32* %t968
  %t1726 = icmp sgt i32 %t1725, 0
  %t1727 = select i1 %t1726, i32 %t1725, i32 1
  %t1728 = getelementptr inbounds i8, i8* %t965, i64 348
  %t1729 = bitcast i8* %t1728 to i32*
  store i32 %t1724, i32* %t1729
  %t1730 = getelementptr inbounds i8, i8* %t965, i64 728
  %t1731 = bitcast i8* %t1730 to i32*
  store i32 %t1727, i32* %t1731
  %t1732 = add i32 %t1724, %t1727
  %t1733 = add i32 %t1732, 3
  store i8 117, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1734 = load i32, i32* %t968
  %t1735 = icmp sgt i32 %t1734, 0
  %t1736 = select i1 %t1735, i32 %t1734, i32 1
  %t1737 = getelementptr inbounds i8, i8* %t965, i64 352
  %t1738 = bitcast i8* %t1737 to i32*
  store i32 %t1733, i32* %t1738
  %t1739 = getelementptr inbounds i8, i8* %t965, i64 732
  %t1740 = bitcast i8* %t1739 to i32*
  store i32 %t1736, i32* %t1740
  %t1741 = add i32 %t1733, %t1736
  %t1742 = add i32 %t1741, 3
  store i8 118, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1743 = load i32, i32* %t968
  %t1744 = icmp sgt i32 %t1743, 0
  %t1745 = select i1 %t1744, i32 %t1743, i32 1
  %t1746 = getelementptr inbounds i8, i8* %t965, i64 356
  %t1747 = bitcast i8* %t1746 to i32*
  store i32 %t1742, i32* %t1747
  %t1748 = getelementptr inbounds i8, i8* %t965, i64 736
  %t1749 = bitcast i8* %t1748 to i32*
  store i32 %t1745, i32* %t1749
  %t1750 = add i32 %t1742, %t1745
  %t1751 = add i32 %t1750, 3
  store i8 119, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1752 = load i32, i32* %t968
  %t1753 = icmp sgt i32 %t1752, 0
  %t1754 = select i1 %t1753, i32 %t1752, i32 1
  %t1755 = getelementptr inbounds i8, i8* %t965, i64 360
  %t1756 = bitcast i8* %t1755 to i32*
  store i32 %t1751, i32* %t1756
  %t1757 = getelementptr inbounds i8, i8* %t965, i64 740
  %t1758 = bitcast i8* %t1757 to i32*
  store i32 %t1754, i32* %t1758
  %t1759 = add i32 %t1751, %t1754
  %t1760 = add i32 %t1759, 3
  store i8 120, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1761 = load i32, i32* %t968
  %t1762 = icmp sgt i32 %t1761, 0
  %t1763 = select i1 %t1762, i32 %t1761, i32 1
  %t1764 = getelementptr inbounds i8, i8* %t965, i64 364
  %t1765 = bitcast i8* %t1764 to i32*
  store i32 %t1760, i32* %t1765
  %t1766 = getelementptr inbounds i8, i8* %t965, i64 744
  %t1767 = bitcast i8* %t1766 to i32*
  store i32 %t1763, i32* %t1767
  %t1768 = add i32 %t1760, %t1763
  %t1769 = add i32 %t1768, 3
  store i8 121, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1770 = load i32, i32* %t968
  %t1771 = icmp sgt i32 %t1770, 0
  %t1772 = select i1 %t1771, i32 %t1770, i32 1
  %t1773 = getelementptr inbounds i8, i8* %t965, i64 368
  %t1774 = bitcast i8* %t1773 to i32*
  store i32 %t1769, i32* %t1774
  %t1775 = getelementptr inbounds i8, i8* %t965, i64 748
  %t1776 = bitcast i8* %t1775 to i32*
  store i32 %t1772, i32* %t1776
  %t1777 = add i32 %t1769, %t1772
  %t1778 = add i32 %t1777, 3
  store i8 122, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1779 = load i32, i32* %t968
  %t1780 = icmp sgt i32 %t1779, 0
  %t1781 = select i1 %t1780, i32 %t1779, i32 1
  %t1782 = getelementptr inbounds i8, i8* %t965, i64 372
  %t1783 = bitcast i8* %t1782 to i32*
  store i32 %t1778, i32* %t1783
  %t1784 = getelementptr inbounds i8, i8* %t965, i64 752
  %t1785 = bitcast i8* %t1784 to i32*
  store i32 %t1781, i32* %t1785
  %t1786 = add i32 %t1778, %t1781
  %t1787 = add i32 %t1786, 3
  store i8 123, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1788 = load i32, i32* %t968
  %t1789 = icmp sgt i32 %t1788, 0
  %t1790 = select i1 %t1789, i32 %t1788, i32 1
  %t1791 = getelementptr inbounds i8, i8* %t965, i64 376
  %t1792 = bitcast i8* %t1791 to i32*
  store i32 %t1787, i32* %t1792
  %t1793 = getelementptr inbounds i8, i8* %t965, i64 756
  %t1794 = bitcast i8* %t1793 to i32*
  store i32 %t1790, i32* %t1794
  %t1795 = add i32 %t1787, %t1790
  %t1796 = add i32 %t1795, 3
  store i8 124, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1797 = load i32, i32* %t968
  %t1798 = icmp sgt i32 %t1797, 0
  %t1799 = select i1 %t1798, i32 %t1797, i32 1
  %t1800 = getelementptr inbounds i8, i8* %t965, i64 380
  %t1801 = bitcast i8* %t1800 to i32*
  store i32 %t1796, i32* %t1801
  %t1802 = getelementptr inbounds i8, i8* %t965, i64 760
  %t1803 = bitcast i8* %t1802 to i32*
  store i32 %t1799, i32* %t1803
  %t1804 = add i32 %t1796, %t1799
  %t1805 = add i32 %t1804, 3
  store i8 125, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1806 = load i32, i32* %t968
  %t1807 = icmp sgt i32 %t1806, 0
  %t1808 = select i1 %t1807, i32 %t1806, i32 1
  %t1809 = getelementptr inbounds i8, i8* %t965, i64 384
  %t1810 = bitcast i8* %t1809 to i32*
  store i32 %t1805, i32* %t1810
  %t1811 = getelementptr inbounds i8, i8* %t965, i64 764
  %t1812 = bitcast i8* %t1811 to i32*
  store i32 %t1808, i32* %t1812
  %t1813 = add i32 %t1805, %t1808
  %t1814 = add i32 %t1813, 3
  store i8 126, i8* %t966
  call i32 @GetTextExtentPoint32A(i8* %t956, i8* %t966, i32 1, i8* %t967)
  %t1815 = load i32, i32* %t968
  %t1816 = icmp sgt i32 %t1815, 0
  %t1817 = select i1 %t1816, i32 %t1815, i32 1
  %t1818 = getelementptr inbounds i8, i8* %t965, i64 388
  %t1819 = bitcast i8* %t1818 to i32*
  store i32 %t1814, i32* %t1819
  %t1820 = getelementptr inbounds i8, i8* %t965, i64 768
  %t1821 = bitcast i8* %t1820 to i32*
  store i32 %t1817, i32* %t1821
  %t1822 = add i32 %t1814, %t1817
  %t1823 = add i32 %t1822, 3
  %t1825 = getelementptr inbounds [40 x i8], [40 x i8]* %t1824, i64 0, i64 0
  store i64 0, i64* %t1826
  br label %ht_fill8_cond_39
ht_fill8_cond_39:
  %t1827 = load i64, i64* %t1826
  %t1828 = icmp slt i64 %t1827, 40
  br i1 %t1828, label %ht_fill8_body_40, label %ht_fill8_end_41
ht_fill8_body_40:
  %t1829 = getelementptr inbounds i8, i8* %t1825, i64 %t1827
  store i8 0, i8* %t1829
  %t1830 = add i64 %t1827, 1
  store i64 %t1830, i64* %t1826
  br label %ht_fill8_cond_39
ht_fill8_end_41:
  %t1831 = bitcast i8* %t1825 to i32*
  store i32 40, i32* %t1831
  %t1832 = getelementptr inbounds i8, i8* %t1825, i64 4
  %t1833 = bitcast i8* %t1832 to i32*
  store i32 %t1823, i32* %t1833
  %t1834 = sub i32 0, %t964
  %t1835 = getelementptr inbounds i8, i8* %t1825, i64 8
  %t1836 = bitcast i8* %t1835 to i32*
  store i32 %t1834, i32* %t1836
  %t1837 = getelementptr inbounds i8, i8* %t1825, i64 12
  %t1838 = bitcast i8* %t1837 to i16*
  store i16 1, i16* %t1838
  %t1839 = getelementptr inbounds i8, i8* %t1825, i64 14
  %t1840 = bitcast i8* %t1839 to i16*
  store i16 32, i16* %t1840
  %t1842 = call i8* @CreateDIBSection(i8* %t956, i8* %t1825, i32 0, i8** %t1841, i8* null, i32 0)
  %t1843 = icmp eq i8* %t1842, null
  br i1 %t1843, label %rasterize_dib_fail_42, label %rasterize_dib_ok_43
rasterize_dib_fail_42:
  call i8* @SelectObject(i8* %t956, i8* %t958)
  call i32 @DeleteObject(i8* %t952)
  call i32 @DeleteDC(i8* %t956)
  call void @free(i8* %t965)
  br label %rasterize_end_36
rasterize_dib_ok_43:
  %t1844 = load i8*, i8** %t1841
  %t1845 = call i8* @SelectObject(i8* %t956, i8* %t1842)
  %t1846 = mul i32 %t1823, %t964
  %t1847 = sext i32 %t1846 to i64
  %t1848 = mul i64 %t1847, 4
  store i64 0, i64* %t1849
  br label %ht_fill8_cond_44
ht_fill8_cond_44:
  %t1850 = load i64, i64* %t1849
  %t1851 = icmp slt i64 %t1850, %t1848
  br i1 %t1851, label %ht_fill8_body_45, label %ht_fill8_end_46
ht_fill8_body_45:
  %t1852 = getelementptr inbounds i8, i8* %t1844, i64 %t1850
  store i8 0, i8* %t1852
  %t1853 = add i64 %t1850, 1
  store i64 %t1853, i64* %t1849
  br label %ht_fill8_cond_44
ht_fill8_end_46:
  store i8 32, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 0, i32 0, i8* %t966, i32 1)
  store i8 33, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t977, i32 0, i8* %t966, i32 1)
  store i8 34, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t986, i32 0, i8* %t966, i32 1)
  store i8 35, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t995, i32 0, i8* %t966, i32 1)
  store i8 36, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1004, i32 0, i8* %t966, i32 1)
  store i8 37, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1013, i32 0, i8* %t966, i32 1)
  store i8 38, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1022, i32 0, i8* %t966, i32 1)
  store i8 39, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1031, i32 0, i8* %t966, i32 1)
  store i8 40, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1040, i32 0, i8* %t966, i32 1)
  store i8 41, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1049, i32 0, i8* %t966, i32 1)
  store i8 42, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1058, i32 0, i8* %t966, i32 1)
  store i8 43, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1067, i32 0, i8* %t966, i32 1)
  store i8 44, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1076, i32 0, i8* %t966, i32 1)
  store i8 45, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1085, i32 0, i8* %t966, i32 1)
  store i8 46, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1094, i32 0, i8* %t966, i32 1)
  store i8 47, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1103, i32 0, i8* %t966, i32 1)
  store i8 48, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1112, i32 0, i8* %t966, i32 1)
  store i8 49, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1121, i32 0, i8* %t966, i32 1)
  store i8 50, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1130, i32 0, i8* %t966, i32 1)
  store i8 51, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1139, i32 0, i8* %t966, i32 1)
  store i8 52, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1148, i32 0, i8* %t966, i32 1)
  store i8 53, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1157, i32 0, i8* %t966, i32 1)
  store i8 54, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1166, i32 0, i8* %t966, i32 1)
  store i8 55, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1175, i32 0, i8* %t966, i32 1)
  store i8 56, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1184, i32 0, i8* %t966, i32 1)
  store i8 57, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1193, i32 0, i8* %t966, i32 1)
  store i8 58, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1202, i32 0, i8* %t966, i32 1)
  store i8 59, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1211, i32 0, i8* %t966, i32 1)
  store i8 60, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1220, i32 0, i8* %t966, i32 1)
  store i8 61, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1229, i32 0, i8* %t966, i32 1)
  store i8 62, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1238, i32 0, i8* %t966, i32 1)
  store i8 63, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1247, i32 0, i8* %t966, i32 1)
  store i8 64, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1256, i32 0, i8* %t966, i32 1)
  store i8 65, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1265, i32 0, i8* %t966, i32 1)
  store i8 66, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1274, i32 0, i8* %t966, i32 1)
  store i8 67, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1283, i32 0, i8* %t966, i32 1)
  store i8 68, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1292, i32 0, i8* %t966, i32 1)
  store i8 69, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1301, i32 0, i8* %t966, i32 1)
  store i8 70, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1310, i32 0, i8* %t966, i32 1)
  store i8 71, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1319, i32 0, i8* %t966, i32 1)
  store i8 72, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1328, i32 0, i8* %t966, i32 1)
  store i8 73, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1337, i32 0, i8* %t966, i32 1)
  store i8 74, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1346, i32 0, i8* %t966, i32 1)
  store i8 75, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1355, i32 0, i8* %t966, i32 1)
  store i8 76, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1364, i32 0, i8* %t966, i32 1)
  store i8 77, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1373, i32 0, i8* %t966, i32 1)
  store i8 78, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1382, i32 0, i8* %t966, i32 1)
  store i8 79, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1391, i32 0, i8* %t966, i32 1)
  store i8 80, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1400, i32 0, i8* %t966, i32 1)
  store i8 81, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1409, i32 0, i8* %t966, i32 1)
  store i8 82, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1418, i32 0, i8* %t966, i32 1)
  store i8 83, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1427, i32 0, i8* %t966, i32 1)
  store i8 84, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1436, i32 0, i8* %t966, i32 1)
  store i8 85, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1445, i32 0, i8* %t966, i32 1)
  store i8 86, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1454, i32 0, i8* %t966, i32 1)
  store i8 87, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1463, i32 0, i8* %t966, i32 1)
  store i8 88, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1472, i32 0, i8* %t966, i32 1)
  store i8 89, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1481, i32 0, i8* %t966, i32 1)
  store i8 90, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1490, i32 0, i8* %t966, i32 1)
  store i8 91, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1499, i32 0, i8* %t966, i32 1)
  store i8 92, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1508, i32 0, i8* %t966, i32 1)
  store i8 93, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1517, i32 0, i8* %t966, i32 1)
  store i8 94, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1526, i32 0, i8* %t966, i32 1)
  store i8 95, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1535, i32 0, i8* %t966, i32 1)
  store i8 96, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1544, i32 0, i8* %t966, i32 1)
  store i8 97, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1553, i32 0, i8* %t966, i32 1)
  store i8 98, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1562, i32 0, i8* %t966, i32 1)
  store i8 99, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1571, i32 0, i8* %t966, i32 1)
  store i8 100, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1580, i32 0, i8* %t966, i32 1)
  store i8 101, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1589, i32 0, i8* %t966, i32 1)
  store i8 102, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1598, i32 0, i8* %t966, i32 1)
  store i8 103, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1607, i32 0, i8* %t966, i32 1)
  store i8 104, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1616, i32 0, i8* %t966, i32 1)
  store i8 105, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1625, i32 0, i8* %t966, i32 1)
  store i8 106, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1634, i32 0, i8* %t966, i32 1)
  store i8 107, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1643, i32 0, i8* %t966, i32 1)
  store i8 108, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1652, i32 0, i8* %t966, i32 1)
  store i8 109, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1661, i32 0, i8* %t966, i32 1)
  store i8 110, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1670, i32 0, i8* %t966, i32 1)
  store i8 111, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1679, i32 0, i8* %t966, i32 1)
  store i8 112, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1688, i32 0, i8* %t966, i32 1)
  store i8 113, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1697, i32 0, i8* %t966, i32 1)
  store i8 114, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1706, i32 0, i8* %t966, i32 1)
  store i8 115, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1715, i32 0, i8* %t966, i32 1)
  store i8 116, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1724, i32 0, i8* %t966, i32 1)
  store i8 117, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1733, i32 0, i8* %t966, i32 1)
  store i8 118, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1742, i32 0, i8* %t966, i32 1)
  store i8 119, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1751, i32 0, i8* %t966, i32 1)
  store i8 120, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1760, i32 0, i8* %t966, i32 1)
  store i8 121, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1769, i32 0, i8* %t966, i32 1)
  store i8 122, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1778, i32 0, i8* %t966, i32 1)
  store i8 123, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1787, i32 0, i8* %t966, i32 1)
  store i8 124, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1796, i32 0, i8* %t966, i32 1)
  store i8 125, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1805, i32 0, i8* %t966, i32 1)
  store i8 126, i8* %t966
  call i32 @TextOutA(i8* %t956, i32 %t1814, i32 0, i8* %t966, i32 1)
  call i8* @SelectObject(i8* %t956, i8* %t958)
  call i8* @SelectObject(i8* %t956, i8* %t1845)
  store i64 0, i64* %t1854
  br label %cov2a_cond_47
cov2a_cond_47:
  %t1855 = load i64, i64* %t1854
  %t1856 = icmp slt i64 %t1855, %t1847
  br i1 %t1856, label %cov2a_body_48, label %cov2a_end_49
cov2a_body_48:
  %t1857 = mul i64 %t1855, 4
  %t1858 = getelementptr inbounds i8, i8* %t1844, i64 %t1857
  %t1859 = load i8, i8* %t1858
  %t1860 = getelementptr inbounds i8, i8* %t1858, i64 1
  %t1861 = getelementptr inbounds i8, i8* %t1858, i64 2
  %t1862 = getelementptr inbounds i8, i8* %t1858, i64 3
  store i8 %t1859, i8* %t1862
  store i8 255, i8* %t1858
  store i8 255, i8* %t1860
  store i8 255, i8* %t1861
  %t1863 = add i64 %t1855, 1
  store i64 %t1863, i64* %t1854
  br label %cov2a_cond_47
cov2a_end_49:
  %t1864 = call i8* @SDL_CreateTexture(i8* %t955, i32 372645892, i32 0, i32 %t1823, i32 %t964)
  %t1865 = icmp eq i8* %t1864, null
  br i1 %t1865, label %rasterize_tex_fail_50, label %rasterize_tex_ok_51
rasterize_tex_fail_50:
  call i32 @DeleteObject(i8* %t1842)
  call i32 @DeleteObject(i8* %t952)
  call i32 @DeleteDC(i8* %t956)
  call void @free(i8* %t965)
  br label %rasterize_end_36
rasterize_tex_ok_51:
  call i32 @SDL_SetTextureBlendMode(i8* %t1864, i32 1)
  %t1866 = mul i32 %t1823, 4
  call i32 @SDL_UpdateTexture(i8* %t1864, i8* null, i8* %t1844, i32 %t1866)
  call i32 @DeleteObject(i8* %t1842)
  call i32 @DeleteObject(i8* %t952)
  call i32 @DeleteDC(i8* %t956)
  %t1867 = getelementptr inbounds i8, i8* %t965, i64 0
  %t1868 = bitcast i8* %t1867 to i8**
  store i8* %t1864, i8** %t1868
  %t1869 = getelementptr inbounds i8, i8* %t965, i64 8
  %t1870 = bitcast i8* %t1869 to i32*
  store i32 %t964, i32* %t1870
  store i8* %t965, i8** %t954
  br label %rasterize_end_36
rasterize_end_36:
  %t1871 = load i8*, i8** %t954
  br label %font_load_system_end_35
font_load_system_end_35:
  %t1872 = phi i8* [ null, %font_load_system_fail_33 ], [ %t1871, %rasterize_end_36 ]
  store i8* %t1872, i8** %t944
  %t1873 = load i8*, i8** %t15
  %t1874 = icmp eq i8* %t1873, null
  br i1 %t1874, label %logic_short_53, label %logic_rhs_52
logic_rhs_52:
  %t1875 = load i8*, i8** %t944
  %t1876 = icmp eq i8* %t1875, null
  br label %logic_end_54
logic_short_53:
  br label %logic_end_54
logic_end_54:
  %t1877 = phi i1 [ %t1876, %logic_rhs_52 ], [ true, %logic_short_53 ]
  br i1 %t1877, label %if_then_55, label %if_else_56
if_then_55:
  %t1878 = getelementptr inbounds { i64, i8*, [24 x i8] }, { i64, i8*, [24 x i8] }* @.str.7, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t1878)
  call i32 (i8*, ...) @printf(i8* %t1878)
  %t1879 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1879)
  %t1880 = load i8*, i8** %t2
  %t1881 = icmp eq i8* %t1880, null
  br i1 %t1881, label %sdl_null_window_58, label %sdl_window_handle_ok_59
sdl_null_window_58:
  %t1882 = getelementptr inbounds [80 x i8], [80 x i8]* @.str.9, i64 0, i64 0
  call i32 @puts(i8* %t1882)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_59:
  %t1883 = call i8* @SDL_GetRenderer(i8* %t1880)
  call void @SDL_DestroyRenderer(i8* %t1883)
  call void @SDL_DestroyWindow(i8* %t1880)
  store i8* null, i8** %t2
  ret i32 0
if_else_56:
  br label %if_end_57
if_end_57:
  %t1885 = load i8*, i8** %t2
  %t1886 = icmp eq i8* %t1885, null
  br i1 %t1886, label %sdl_null_window_60, label %sdl_window_handle_ok_61
sdl_null_window_60:
  %t1887 = getelementptr inbounds [79 x i8], [79 x i8]* @.str.10, i64 0, i64 0
  call i32 @puts(i8* %t1887)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_61:
  %t1888 = getelementptr inbounds { i64, i8*, [27 x i8] }, { i64, i8*, [27 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t1889 = icmp sgt i32 18, 0
  %t1890 = select i1 %t1889, i32 18, i32 1
  %t1891 = sub i32 0, %t1890
  store i8* null, i8** %t1892
  %t1893 = getelementptr inbounds [3 x i8], [3 x i8]* @.str.12, i64 0, i64 0
  %t1894 = call i8* @fopen(i8* %t1888, i8* %t1893)
  %t1895 = icmp eq i8* %t1894, null
  br i1 %t1895, label %ttf_load_open_fail_63, label %ttf_load_open_ok_64
ttf_load_open_fail_63:
  br label %ttf_load_end_62
ttf_load_open_ok_64:
  call i32 @fseek(i8* %t1894, i32 0, i32 2)
  %t1896 = call i32 @ftell(i8* %t1894)
  call i32 @fseek(i8* %t1894, i32 0, i32 0)
  %t1897 = icmp sge i32 %t1896, 12
  br i1 %t1897, label %ttf_load_read_66, label %ttf_load_too_small_65
ttf_load_too_small_65:
  call i32 @fclose(i8* %t1894)
  br label %ttf_load_end_62
ttf_load_read_66:
  %t1898 = sext i32 %t1896 to i64
  %t1899 = call i8* @malloc(i64 %t1898)
  call i64 @fread(i8* %t1899, i64 1, i64 %t1898, i8* %t1894)
  call i32 @fclose(i8* %t1894)
  %t1900 = call i32 @AddFontResourceExA(i8* %t1888, i32 16, i8* null)
  %t1901 = icmp eq i32 %t1900, 0
  br i1 %t1901, label %ttf_load_add_fail_67, label %ttf_load_add_ok_68
ttf_load_add_fail_67:
  call void @free(i8* %t1899)
  br label %ttf_load_end_62
ttf_load_add_ok_68:
  %t1902 = getelementptr inbounds i8, i8* %t1899, i64 4
  %t1903 = load i8, i8* %t1902
  %t1904 = getelementptr inbounds i8, i8* %t1902, i64 1
  %t1905 = load i8, i8* %t1904
  %t1906 = zext i8 %t1903 to i32
  %t1907 = zext i8 %t1905 to i32
  %t1908 = shl i32 %t1906, 8
  %t1909 = or i32 %t1908, %t1907
  store i1 false, i1* %t1910
  store i32 0, i32* %t1911
  store i32 0, i32* %t1912
  br label %ttf_tdir_cond_69
ttf_tdir_cond_69:
  %t1913 = load i32, i32* %t1912
  %t1914 = icmp slt i32 %t1913, %t1909
  %t1915 = mul i32 %t1913, 16
  %t1916 = add i32 %t1915, 12
  %t1917 = add i32 %t1916, 16
  %t1918 = icmp sle i32 %t1917, %t1896
  %t1919 = and i1 %t1914, %t1918
  br i1 %t1919, label %ttf_tdir_body_70, label %ttf_tdir_end_73
ttf_tdir_body_70:
  %t1920 = sext i32 %t1916 to i64
  %t1921 = getelementptr inbounds i8, i8* %t1899, i64 %t1920
  %t1922 = getelementptr inbounds i8, i8* %t1921, i64 0
  %t1923 = load i8, i8* %t1922
  %t1924 = zext i8 %t1923 to i32
  %t1925 = getelementptr inbounds i8, i8* %t1921, i64 1
  %t1926 = load i8, i8* %t1925
  %t1927 = zext i8 %t1926 to i32
  %t1928 = getelementptr inbounds i8, i8* %t1921, i64 2
  %t1929 = load i8, i8* %t1928
  %t1930 = zext i8 %t1929 to i32
  %t1931 = getelementptr inbounds i8, i8* %t1921, i64 3
  %t1932 = load i8, i8* %t1931
  %t1933 = zext i8 %t1932 to i32
  %t1934 = shl i32 %t1924, 24
  %t1935 = shl i32 %t1927, 16
  %t1936 = or i32 %t1934, %t1935
  %t1937 = shl i32 %t1930, 8
  %t1938 = or i32 %t1936, %t1937
  %t1939 = shl i32 %t1933, 0
  %t1940 = or i32 %t1938, %t1939
  %t1941 = icmp eq i32 %t1940, 1851878757
  br i1 %t1941, label %ttf_tdir_match_71, label %ttf_tdir_next_72
ttf_tdir_match_71:
  %t1942 = getelementptr inbounds i8, i8* %t1921, i64 8
  %t1943 = getelementptr inbounds i8, i8* %t1942, i64 0
  %t1944 = load i8, i8* %t1943
  %t1945 = zext i8 %t1944 to i32
  %t1946 = getelementptr inbounds i8, i8* %t1942, i64 1
  %t1947 = load i8, i8* %t1946
  %t1948 = zext i8 %t1947 to i32
  %t1949 = getelementptr inbounds i8, i8* %t1942, i64 2
  %t1950 = load i8, i8* %t1949
  %t1951 = zext i8 %t1950 to i32
  %t1952 = getelementptr inbounds i8, i8* %t1942, i64 3
  %t1953 = load i8, i8* %t1952
  %t1954 = zext i8 %t1953 to i32
  %t1955 = shl i32 %t1945, 24
  %t1956 = shl i32 %t1948, 16
  %t1957 = or i32 %t1955, %t1956
  %t1958 = shl i32 %t1951, 8
  %t1959 = or i32 %t1957, %t1958
  %t1960 = shl i32 %t1954, 0
  %t1961 = or i32 %t1959, %t1960
  store i1 true, i1* %t1910
  store i32 %t1961, i32* %t1911
  br label %ttf_tdir_next_72
ttf_tdir_next_72:
  %t1962 = add i32 %t1913, 1
  store i32 %t1962, i32* %t1912
  br label %ttf_tdir_cond_69
ttf_tdir_end_73:
  %t1963 = load i1, i1* %t1910
  br i1 %t1963, label %ttf_name_hdr_ok_75, label %ttf_name_hdr_fail_74
ttf_name_hdr_fail_74:
  call i32 @RemoveFontResourceExA(i8* %t1888, i32 16, i8* null)
  call void @free(i8* %t1899)
  br label %ttf_load_end_62
ttf_name_hdr_ok_75:
  %t1964 = load i32, i32* %t1911
  %t1965 = add i32 %t1964, 6
  %t1966 = icmp sle i32 %t1965, %t1896
  br i1 %t1966, label %ttf_hdr_ok_77, label %ttf_hdr_fail_76
ttf_hdr_fail_76:
  call i32 @RemoveFontResourceExA(i8* %t1888, i32 16, i8* null)
  call void @free(i8* %t1899)
  br label %ttf_load_end_62
ttf_hdr_ok_77:
  %t1967 = sext i32 %t1964 to i64
  %t1968 = getelementptr inbounds i8, i8* %t1899, i64 %t1967
  %t1969 = getelementptr inbounds i8, i8* %t1968, i64 2
  %t1970 = load i8, i8* %t1969
  %t1971 = getelementptr inbounds i8, i8* %t1969, i64 1
  %t1972 = load i8, i8* %t1971
  %t1973 = zext i8 %t1970 to i32
  %t1974 = zext i8 %t1972 to i32
  %t1975 = shl i32 %t1973, 8
  %t1976 = or i32 %t1975, %t1974
  %t1977 = getelementptr inbounds i8, i8* %t1968, i64 4
  %t1978 = load i8, i8* %t1977
  %t1979 = getelementptr inbounds i8, i8* %t1977, i64 1
  %t1980 = load i8, i8* %t1979
  %t1981 = zext i8 %t1978 to i32
  %t1982 = zext i8 %t1980 to i32
  %t1983 = shl i32 %t1981, 8
  %t1984 = or i32 %t1983, %t1982
  store i1 false, i1* %t1985
  store i32 0, i32* %t1986
  store i32 0, i32* %t1987
  store i1 false, i1* %t1988
  store i32 0, i32* %t1989
  store i32 0, i32* %t1990
  store i32 0, i32* %t1991
  br label %ttf_rec_cond_78
ttf_rec_cond_78:
  %t1992 = load i32, i32* %t1991
  %t1993 = icmp slt i32 %t1992, %t1976
  %t1994 = mul i32 %t1992, 12
  %t1995 = add i32 %t1994, 6
  %t1996 = add i32 %t1995, 12
  %t1997 = add i32 %t1964, %t1996
  %t1998 = icmp sle i32 %t1997, %t1896
  %t1999 = and i1 %t1993, %t1998
  br i1 %t1999, label %ttf_rec_body_79, label %ttf_rec_end_84
ttf_rec_body_79:
  %t2000 = add i32 %t1964, %t1995
  %t2001 = sext i32 %t2000 to i64
  %t2002 = getelementptr inbounds i8, i8* %t1899, i64 %t2001
  %t2003 = load i8, i8* %t2002
  %t2004 = getelementptr inbounds i8, i8* %t2002, i64 1
  %t2005 = load i8, i8* %t2004
  %t2006 = zext i8 %t2003 to i32
  %t2007 = zext i8 %t2005 to i32
  %t2008 = shl i32 %t2006, 8
  %t2009 = or i32 %t2008, %t2007
  %t2010 = getelementptr inbounds i8, i8* %t2002, i64 2
  %t2011 = load i8, i8* %t2010
  %t2012 = getelementptr inbounds i8, i8* %t2010, i64 1
  %t2013 = load i8, i8* %t2012
  %t2014 = zext i8 %t2011 to i32
  %t2015 = zext i8 %t2013 to i32
  %t2016 = shl i32 %t2014, 8
  %t2017 = or i32 %t2016, %t2015
  %t2018 = getelementptr inbounds i8, i8* %t2002, i64 4
  %t2019 = load i8, i8* %t2018
  %t2020 = getelementptr inbounds i8, i8* %t2018, i64 1
  %t2021 = load i8, i8* %t2020
  %t2022 = zext i8 %t2019 to i32
  %t2023 = zext i8 %t2021 to i32
  %t2024 = shl i32 %t2022, 8
  %t2025 = or i32 %t2024, %t2023
  %t2026 = getelementptr inbounds i8, i8* %t2002, i64 6
  %t2027 = load i8, i8* %t2026
  %t2028 = getelementptr inbounds i8, i8* %t2026, i64 1
  %t2029 = load i8, i8* %t2028
  %t2030 = zext i8 %t2027 to i32
  %t2031 = zext i8 %t2029 to i32
  %t2032 = shl i32 %t2030, 8
  %t2033 = or i32 %t2032, %t2031
  %t2034 = getelementptr inbounds i8, i8* %t2002, i64 8
  %t2035 = load i8, i8* %t2034
  %t2036 = getelementptr inbounds i8, i8* %t2034, i64 1
  %t2037 = load i8, i8* %t2036
  %t2038 = zext i8 %t2035 to i32
  %t2039 = zext i8 %t2037 to i32
  %t2040 = shl i32 %t2038, 8
  %t2041 = or i32 %t2040, %t2039
  %t2042 = getelementptr inbounds i8, i8* %t2002, i64 10
  %t2043 = load i8, i8* %t2042
  %t2044 = getelementptr inbounds i8, i8* %t2042, i64 1
  %t2045 = load i8, i8* %t2044
  %t2046 = zext i8 %t2043 to i32
  %t2047 = zext i8 %t2045 to i32
  %t2048 = shl i32 %t2046, 8
  %t2049 = or i32 %t2048, %t2047
  %t2050 = icmp eq i32 %t2009, 3
  %t2051 = icmp eq i32 %t2017, 1
  %t2052 = icmp eq i32 %t2025, 1033
  %t2053 = icmp eq i32 %t2033, 1
  %t2054 = and i1 %t2050, %t2051
  %t2055 = and i1 %t2054, %t2052
  %t2056 = and i1 %t2055, %t2053
  br i1 %t2056, label %ttf_rec_exact_80, label %ttf_rec_check_fb_81
ttf_rec_exact_80:
  store i1 true, i1* %t1985
  store i32 %t2049, i32* %t1986
  store i32 %t2041, i32* %t1987
  br label %ttf_rec_next_83
ttf_rec_check_fb_81:
  br i1 %t2053, label %ttf_rec_fb_82, label %ttf_rec_next_83
ttf_rec_fb_82:
  store i1 true, i1* %t1988
  store i32 %t2049, i32* %t1989
  store i32 %t2041, i32* %t1990
  br label %ttf_rec_next_83
ttf_rec_next_83:
  %t2057 = add i32 %t1992, 1
  store i32 %t2057, i32* %t1991
  br label %ttf_rec_cond_78
ttf_rec_end_84:
  %t2058 = load i1, i1* %t1985
  %t2059 = load i1, i1* %t1988
  %t2060 = or i1 %t2058, %t2059
  %t2061 = load i32, i32* %t1986
  %t2062 = load i32, i32* %t1987
  %t2063 = load i32, i32* %t1989
  %t2064 = load i32, i32* %t1990
  %t2065 = select i1 %t2058, i32 %t2061, i32 %t2063
  %t2066 = select i1 %t2058, i32 %t2062, i32 %t2064
  br i1 %t2060, label %ttf_name_found_ok_86, label %ttf_name_found_fail_85
ttf_name_found_fail_85:
  call i32 @RemoveFontResourceExA(i8* %t1888, i32 16, i8* null)
  call void @free(i8* %t1899)
  br label %ttf_load_end_62
ttf_name_found_ok_86:
  %t2067 = add i32 %t1964, %t1984
  %t2068 = add i32 %t2067, %t2065
  %t2069 = add i32 %t2068, %t2066
  %t2070 = icmp sge i32 %t2068, 0
  %t2071 = icmp sge i32 %t2066, 0
  %t2072 = icmp sle i32 %t2069, %t1896
  %t2073 = and i1 %t2070, %t2071
  %t2074 = and i1 %t2073, %t2072
  br i1 %t2074, label %ttf_str_ok_88, label %ttf_str_fail_87
ttf_str_fail_87:
  call i32 @RemoveFontResourceExA(i8* %t1888, i32 16, i8* null)
  call void @free(i8* %t1899)
  br label %ttf_load_end_62
ttf_str_ok_88:
  %t2075 = sdiv i32 %t2066, 2
  %t2076 = add i32 %t2075, 1
  %t2077 = sext i32 %t2076 to i64
  %t2078 = call i8* @malloc(i64 %t2077)
  store i32 0, i32* %t2079
  br label %ttf_copy_cond_89
ttf_copy_cond_89:
  %t2080 = load i32, i32* %t2079
  %t2081 = icmp slt i32 %t2080, %t2075
  br i1 %t2081, label %ttf_copy_body_90, label %ttf_copy_end_91
ttf_copy_body_90:
  %t2082 = mul i32 %t2080, 2
  %t2083 = add i32 %t2082, 1
  %t2084 = add i32 %t2068, %t2083
  %t2085 = sext i32 %t2084 to i64
  %t2086 = getelementptr inbounds i8, i8* %t1899, i64 %t2085
  %t2087 = load i8, i8* %t2086
  %t2088 = sext i32 %t2080 to i64
  %t2089 = getelementptr inbounds i8, i8* %t2078, i64 %t2088
  store i8 %t2087, i8* %t2089
  %t2090 = add i32 %t2080, 1
  store i32 %t2090, i32* %t2079
  br label %ttf_copy_cond_89
ttf_copy_end_91:
  %t2091 = sext i32 %t2075 to i64
  %t2092 = getelementptr inbounds i8, i8* %t2078, i64 %t2091
  store i8 0, i8* %t2092
  call void @free(i8* %t1899)
  %t2093 = call i8* @CreateFontA(i32 %t1891, i32 0, i32 0, i32 0, i32 400, i32 0, i32 0, i32 0, i32 1, i32 4, i32 0, i32 4, i32 0, i8* %t2078)
  call void @free(i8* %t2078)
  %t2094 = icmp eq i8* %t2093, null
  br i1 %t2094, label %ttf_hfont_fail_92, label %ttf_hfont_ok_93
ttf_hfont_fail_92:
  call i32 @RemoveFontResourceExA(i8* %t1888, i32 16, i8* null)
  br label %ttf_load_end_62
ttf_hfont_ok_93:
  store i8* null, i8** %t2095
  %t2096 = call i8* @SDL_GetRenderer(i8* %t1885)
  %t2097 = call i8* @CreateCompatibleDC(i8* null)
  %t2098 = icmp eq i8* %t2097, null
  br i1 %t2098, label %rasterize_memdc_fail_95, label %rasterize_memdc_ok_96
rasterize_memdc_fail_95:
  call i32 @DeleteObject(i8* %t2093)
  br label %rasterize_end_94
rasterize_memdc_ok_96:
  %t2099 = call i8* @SelectObject(i8* %t2097, i8* %t2093)
  call i32 @SetBkMode(i8* %t2097, i32 1)
  call i32 @SetTextColor(i8* %t2097, i32 16777215)
  %t2101 = getelementptr inbounds [64 x i8], [64 x i8]* %t2100, i64 0, i64 0
  call i32 @GetTextMetricsA(i8* %t2097, i8* %t2101)
  %t2102 = bitcast i8* %t2101 to i32*
  %t2103 = load i32, i32* %t2102
  %t2104 = icmp sgt i32 %t2103, 0
  %t2105 = select i1 %t2104, i32 %t2103, i32 1
  %t2106 = call i8* @malloc(i64 772)
  %t2109 = bitcast [8 x i8]* %t2108 to i32*
  store i8 32, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2110 = load i32, i32* %t2109
  %t2111 = icmp sgt i32 %t2110, 0
  %t2112 = select i1 %t2111, i32 %t2110, i32 1
  %t2113 = getelementptr inbounds i8, i8* %t2106, i64 12
  %t2114 = bitcast i8* %t2113 to i32*
  store i32 0, i32* %t2114
  %t2115 = getelementptr inbounds i8, i8* %t2106, i64 392
  %t2116 = bitcast i8* %t2115 to i32*
  store i32 %t2112, i32* %t2116
  %t2117 = add i32 0, %t2112
  %t2118 = add i32 %t2117, 3
  store i8 33, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2119 = load i32, i32* %t2109
  %t2120 = icmp sgt i32 %t2119, 0
  %t2121 = select i1 %t2120, i32 %t2119, i32 1
  %t2122 = getelementptr inbounds i8, i8* %t2106, i64 16
  %t2123 = bitcast i8* %t2122 to i32*
  store i32 %t2118, i32* %t2123
  %t2124 = getelementptr inbounds i8, i8* %t2106, i64 396
  %t2125 = bitcast i8* %t2124 to i32*
  store i32 %t2121, i32* %t2125
  %t2126 = add i32 %t2118, %t2121
  %t2127 = add i32 %t2126, 3
  store i8 34, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2128 = load i32, i32* %t2109
  %t2129 = icmp sgt i32 %t2128, 0
  %t2130 = select i1 %t2129, i32 %t2128, i32 1
  %t2131 = getelementptr inbounds i8, i8* %t2106, i64 20
  %t2132 = bitcast i8* %t2131 to i32*
  store i32 %t2127, i32* %t2132
  %t2133 = getelementptr inbounds i8, i8* %t2106, i64 400
  %t2134 = bitcast i8* %t2133 to i32*
  store i32 %t2130, i32* %t2134
  %t2135 = add i32 %t2127, %t2130
  %t2136 = add i32 %t2135, 3
  store i8 35, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2137 = load i32, i32* %t2109
  %t2138 = icmp sgt i32 %t2137, 0
  %t2139 = select i1 %t2138, i32 %t2137, i32 1
  %t2140 = getelementptr inbounds i8, i8* %t2106, i64 24
  %t2141 = bitcast i8* %t2140 to i32*
  store i32 %t2136, i32* %t2141
  %t2142 = getelementptr inbounds i8, i8* %t2106, i64 404
  %t2143 = bitcast i8* %t2142 to i32*
  store i32 %t2139, i32* %t2143
  %t2144 = add i32 %t2136, %t2139
  %t2145 = add i32 %t2144, 3
  store i8 36, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2146 = load i32, i32* %t2109
  %t2147 = icmp sgt i32 %t2146, 0
  %t2148 = select i1 %t2147, i32 %t2146, i32 1
  %t2149 = getelementptr inbounds i8, i8* %t2106, i64 28
  %t2150 = bitcast i8* %t2149 to i32*
  store i32 %t2145, i32* %t2150
  %t2151 = getelementptr inbounds i8, i8* %t2106, i64 408
  %t2152 = bitcast i8* %t2151 to i32*
  store i32 %t2148, i32* %t2152
  %t2153 = add i32 %t2145, %t2148
  %t2154 = add i32 %t2153, 3
  store i8 37, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2155 = load i32, i32* %t2109
  %t2156 = icmp sgt i32 %t2155, 0
  %t2157 = select i1 %t2156, i32 %t2155, i32 1
  %t2158 = getelementptr inbounds i8, i8* %t2106, i64 32
  %t2159 = bitcast i8* %t2158 to i32*
  store i32 %t2154, i32* %t2159
  %t2160 = getelementptr inbounds i8, i8* %t2106, i64 412
  %t2161 = bitcast i8* %t2160 to i32*
  store i32 %t2157, i32* %t2161
  %t2162 = add i32 %t2154, %t2157
  %t2163 = add i32 %t2162, 3
  store i8 38, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2164 = load i32, i32* %t2109
  %t2165 = icmp sgt i32 %t2164, 0
  %t2166 = select i1 %t2165, i32 %t2164, i32 1
  %t2167 = getelementptr inbounds i8, i8* %t2106, i64 36
  %t2168 = bitcast i8* %t2167 to i32*
  store i32 %t2163, i32* %t2168
  %t2169 = getelementptr inbounds i8, i8* %t2106, i64 416
  %t2170 = bitcast i8* %t2169 to i32*
  store i32 %t2166, i32* %t2170
  %t2171 = add i32 %t2163, %t2166
  %t2172 = add i32 %t2171, 3
  store i8 39, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2173 = load i32, i32* %t2109
  %t2174 = icmp sgt i32 %t2173, 0
  %t2175 = select i1 %t2174, i32 %t2173, i32 1
  %t2176 = getelementptr inbounds i8, i8* %t2106, i64 40
  %t2177 = bitcast i8* %t2176 to i32*
  store i32 %t2172, i32* %t2177
  %t2178 = getelementptr inbounds i8, i8* %t2106, i64 420
  %t2179 = bitcast i8* %t2178 to i32*
  store i32 %t2175, i32* %t2179
  %t2180 = add i32 %t2172, %t2175
  %t2181 = add i32 %t2180, 3
  store i8 40, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2182 = load i32, i32* %t2109
  %t2183 = icmp sgt i32 %t2182, 0
  %t2184 = select i1 %t2183, i32 %t2182, i32 1
  %t2185 = getelementptr inbounds i8, i8* %t2106, i64 44
  %t2186 = bitcast i8* %t2185 to i32*
  store i32 %t2181, i32* %t2186
  %t2187 = getelementptr inbounds i8, i8* %t2106, i64 424
  %t2188 = bitcast i8* %t2187 to i32*
  store i32 %t2184, i32* %t2188
  %t2189 = add i32 %t2181, %t2184
  %t2190 = add i32 %t2189, 3
  store i8 41, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2191 = load i32, i32* %t2109
  %t2192 = icmp sgt i32 %t2191, 0
  %t2193 = select i1 %t2192, i32 %t2191, i32 1
  %t2194 = getelementptr inbounds i8, i8* %t2106, i64 48
  %t2195 = bitcast i8* %t2194 to i32*
  store i32 %t2190, i32* %t2195
  %t2196 = getelementptr inbounds i8, i8* %t2106, i64 428
  %t2197 = bitcast i8* %t2196 to i32*
  store i32 %t2193, i32* %t2197
  %t2198 = add i32 %t2190, %t2193
  %t2199 = add i32 %t2198, 3
  store i8 42, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2200 = load i32, i32* %t2109
  %t2201 = icmp sgt i32 %t2200, 0
  %t2202 = select i1 %t2201, i32 %t2200, i32 1
  %t2203 = getelementptr inbounds i8, i8* %t2106, i64 52
  %t2204 = bitcast i8* %t2203 to i32*
  store i32 %t2199, i32* %t2204
  %t2205 = getelementptr inbounds i8, i8* %t2106, i64 432
  %t2206 = bitcast i8* %t2205 to i32*
  store i32 %t2202, i32* %t2206
  %t2207 = add i32 %t2199, %t2202
  %t2208 = add i32 %t2207, 3
  store i8 43, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2209 = load i32, i32* %t2109
  %t2210 = icmp sgt i32 %t2209, 0
  %t2211 = select i1 %t2210, i32 %t2209, i32 1
  %t2212 = getelementptr inbounds i8, i8* %t2106, i64 56
  %t2213 = bitcast i8* %t2212 to i32*
  store i32 %t2208, i32* %t2213
  %t2214 = getelementptr inbounds i8, i8* %t2106, i64 436
  %t2215 = bitcast i8* %t2214 to i32*
  store i32 %t2211, i32* %t2215
  %t2216 = add i32 %t2208, %t2211
  %t2217 = add i32 %t2216, 3
  store i8 44, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2218 = load i32, i32* %t2109
  %t2219 = icmp sgt i32 %t2218, 0
  %t2220 = select i1 %t2219, i32 %t2218, i32 1
  %t2221 = getelementptr inbounds i8, i8* %t2106, i64 60
  %t2222 = bitcast i8* %t2221 to i32*
  store i32 %t2217, i32* %t2222
  %t2223 = getelementptr inbounds i8, i8* %t2106, i64 440
  %t2224 = bitcast i8* %t2223 to i32*
  store i32 %t2220, i32* %t2224
  %t2225 = add i32 %t2217, %t2220
  %t2226 = add i32 %t2225, 3
  store i8 45, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2227 = load i32, i32* %t2109
  %t2228 = icmp sgt i32 %t2227, 0
  %t2229 = select i1 %t2228, i32 %t2227, i32 1
  %t2230 = getelementptr inbounds i8, i8* %t2106, i64 64
  %t2231 = bitcast i8* %t2230 to i32*
  store i32 %t2226, i32* %t2231
  %t2232 = getelementptr inbounds i8, i8* %t2106, i64 444
  %t2233 = bitcast i8* %t2232 to i32*
  store i32 %t2229, i32* %t2233
  %t2234 = add i32 %t2226, %t2229
  %t2235 = add i32 %t2234, 3
  store i8 46, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2236 = load i32, i32* %t2109
  %t2237 = icmp sgt i32 %t2236, 0
  %t2238 = select i1 %t2237, i32 %t2236, i32 1
  %t2239 = getelementptr inbounds i8, i8* %t2106, i64 68
  %t2240 = bitcast i8* %t2239 to i32*
  store i32 %t2235, i32* %t2240
  %t2241 = getelementptr inbounds i8, i8* %t2106, i64 448
  %t2242 = bitcast i8* %t2241 to i32*
  store i32 %t2238, i32* %t2242
  %t2243 = add i32 %t2235, %t2238
  %t2244 = add i32 %t2243, 3
  store i8 47, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2245 = load i32, i32* %t2109
  %t2246 = icmp sgt i32 %t2245, 0
  %t2247 = select i1 %t2246, i32 %t2245, i32 1
  %t2248 = getelementptr inbounds i8, i8* %t2106, i64 72
  %t2249 = bitcast i8* %t2248 to i32*
  store i32 %t2244, i32* %t2249
  %t2250 = getelementptr inbounds i8, i8* %t2106, i64 452
  %t2251 = bitcast i8* %t2250 to i32*
  store i32 %t2247, i32* %t2251
  %t2252 = add i32 %t2244, %t2247
  %t2253 = add i32 %t2252, 3
  store i8 48, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2254 = load i32, i32* %t2109
  %t2255 = icmp sgt i32 %t2254, 0
  %t2256 = select i1 %t2255, i32 %t2254, i32 1
  %t2257 = getelementptr inbounds i8, i8* %t2106, i64 76
  %t2258 = bitcast i8* %t2257 to i32*
  store i32 %t2253, i32* %t2258
  %t2259 = getelementptr inbounds i8, i8* %t2106, i64 456
  %t2260 = bitcast i8* %t2259 to i32*
  store i32 %t2256, i32* %t2260
  %t2261 = add i32 %t2253, %t2256
  %t2262 = add i32 %t2261, 3
  store i8 49, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2263 = load i32, i32* %t2109
  %t2264 = icmp sgt i32 %t2263, 0
  %t2265 = select i1 %t2264, i32 %t2263, i32 1
  %t2266 = getelementptr inbounds i8, i8* %t2106, i64 80
  %t2267 = bitcast i8* %t2266 to i32*
  store i32 %t2262, i32* %t2267
  %t2268 = getelementptr inbounds i8, i8* %t2106, i64 460
  %t2269 = bitcast i8* %t2268 to i32*
  store i32 %t2265, i32* %t2269
  %t2270 = add i32 %t2262, %t2265
  %t2271 = add i32 %t2270, 3
  store i8 50, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2272 = load i32, i32* %t2109
  %t2273 = icmp sgt i32 %t2272, 0
  %t2274 = select i1 %t2273, i32 %t2272, i32 1
  %t2275 = getelementptr inbounds i8, i8* %t2106, i64 84
  %t2276 = bitcast i8* %t2275 to i32*
  store i32 %t2271, i32* %t2276
  %t2277 = getelementptr inbounds i8, i8* %t2106, i64 464
  %t2278 = bitcast i8* %t2277 to i32*
  store i32 %t2274, i32* %t2278
  %t2279 = add i32 %t2271, %t2274
  %t2280 = add i32 %t2279, 3
  store i8 51, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2281 = load i32, i32* %t2109
  %t2282 = icmp sgt i32 %t2281, 0
  %t2283 = select i1 %t2282, i32 %t2281, i32 1
  %t2284 = getelementptr inbounds i8, i8* %t2106, i64 88
  %t2285 = bitcast i8* %t2284 to i32*
  store i32 %t2280, i32* %t2285
  %t2286 = getelementptr inbounds i8, i8* %t2106, i64 468
  %t2287 = bitcast i8* %t2286 to i32*
  store i32 %t2283, i32* %t2287
  %t2288 = add i32 %t2280, %t2283
  %t2289 = add i32 %t2288, 3
  store i8 52, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2290 = load i32, i32* %t2109
  %t2291 = icmp sgt i32 %t2290, 0
  %t2292 = select i1 %t2291, i32 %t2290, i32 1
  %t2293 = getelementptr inbounds i8, i8* %t2106, i64 92
  %t2294 = bitcast i8* %t2293 to i32*
  store i32 %t2289, i32* %t2294
  %t2295 = getelementptr inbounds i8, i8* %t2106, i64 472
  %t2296 = bitcast i8* %t2295 to i32*
  store i32 %t2292, i32* %t2296
  %t2297 = add i32 %t2289, %t2292
  %t2298 = add i32 %t2297, 3
  store i8 53, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2299 = load i32, i32* %t2109
  %t2300 = icmp sgt i32 %t2299, 0
  %t2301 = select i1 %t2300, i32 %t2299, i32 1
  %t2302 = getelementptr inbounds i8, i8* %t2106, i64 96
  %t2303 = bitcast i8* %t2302 to i32*
  store i32 %t2298, i32* %t2303
  %t2304 = getelementptr inbounds i8, i8* %t2106, i64 476
  %t2305 = bitcast i8* %t2304 to i32*
  store i32 %t2301, i32* %t2305
  %t2306 = add i32 %t2298, %t2301
  %t2307 = add i32 %t2306, 3
  store i8 54, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2308 = load i32, i32* %t2109
  %t2309 = icmp sgt i32 %t2308, 0
  %t2310 = select i1 %t2309, i32 %t2308, i32 1
  %t2311 = getelementptr inbounds i8, i8* %t2106, i64 100
  %t2312 = bitcast i8* %t2311 to i32*
  store i32 %t2307, i32* %t2312
  %t2313 = getelementptr inbounds i8, i8* %t2106, i64 480
  %t2314 = bitcast i8* %t2313 to i32*
  store i32 %t2310, i32* %t2314
  %t2315 = add i32 %t2307, %t2310
  %t2316 = add i32 %t2315, 3
  store i8 55, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2317 = load i32, i32* %t2109
  %t2318 = icmp sgt i32 %t2317, 0
  %t2319 = select i1 %t2318, i32 %t2317, i32 1
  %t2320 = getelementptr inbounds i8, i8* %t2106, i64 104
  %t2321 = bitcast i8* %t2320 to i32*
  store i32 %t2316, i32* %t2321
  %t2322 = getelementptr inbounds i8, i8* %t2106, i64 484
  %t2323 = bitcast i8* %t2322 to i32*
  store i32 %t2319, i32* %t2323
  %t2324 = add i32 %t2316, %t2319
  %t2325 = add i32 %t2324, 3
  store i8 56, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2326 = load i32, i32* %t2109
  %t2327 = icmp sgt i32 %t2326, 0
  %t2328 = select i1 %t2327, i32 %t2326, i32 1
  %t2329 = getelementptr inbounds i8, i8* %t2106, i64 108
  %t2330 = bitcast i8* %t2329 to i32*
  store i32 %t2325, i32* %t2330
  %t2331 = getelementptr inbounds i8, i8* %t2106, i64 488
  %t2332 = bitcast i8* %t2331 to i32*
  store i32 %t2328, i32* %t2332
  %t2333 = add i32 %t2325, %t2328
  %t2334 = add i32 %t2333, 3
  store i8 57, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2335 = load i32, i32* %t2109
  %t2336 = icmp sgt i32 %t2335, 0
  %t2337 = select i1 %t2336, i32 %t2335, i32 1
  %t2338 = getelementptr inbounds i8, i8* %t2106, i64 112
  %t2339 = bitcast i8* %t2338 to i32*
  store i32 %t2334, i32* %t2339
  %t2340 = getelementptr inbounds i8, i8* %t2106, i64 492
  %t2341 = bitcast i8* %t2340 to i32*
  store i32 %t2337, i32* %t2341
  %t2342 = add i32 %t2334, %t2337
  %t2343 = add i32 %t2342, 3
  store i8 58, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2344 = load i32, i32* %t2109
  %t2345 = icmp sgt i32 %t2344, 0
  %t2346 = select i1 %t2345, i32 %t2344, i32 1
  %t2347 = getelementptr inbounds i8, i8* %t2106, i64 116
  %t2348 = bitcast i8* %t2347 to i32*
  store i32 %t2343, i32* %t2348
  %t2349 = getelementptr inbounds i8, i8* %t2106, i64 496
  %t2350 = bitcast i8* %t2349 to i32*
  store i32 %t2346, i32* %t2350
  %t2351 = add i32 %t2343, %t2346
  %t2352 = add i32 %t2351, 3
  store i8 59, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2353 = load i32, i32* %t2109
  %t2354 = icmp sgt i32 %t2353, 0
  %t2355 = select i1 %t2354, i32 %t2353, i32 1
  %t2356 = getelementptr inbounds i8, i8* %t2106, i64 120
  %t2357 = bitcast i8* %t2356 to i32*
  store i32 %t2352, i32* %t2357
  %t2358 = getelementptr inbounds i8, i8* %t2106, i64 500
  %t2359 = bitcast i8* %t2358 to i32*
  store i32 %t2355, i32* %t2359
  %t2360 = add i32 %t2352, %t2355
  %t2361 = add i32 %t2360, 3
  store i8 60, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2362 = load i32, i32* %t2109
  %t2363 = icmp sgt i32 %t2362, 0
  %t2364 = select i1 %t2363, i32 %t2362, i32 1
  %t2365 = getelementptr inbounds i8, i8* %t2106, i64 124
  %t2366 = bitcast i8* %t2365 to i32*
  store i32 %t2361, i32* %t2366
  %t2367 = getelementptr inbounds i8, i8* %t2106, i64 504
  %t2368 = bitcast i8* %t2367 to i32*
  store i32 %t2364, i32* %t2368
  %t2369 = add i32 %t2361, %t2364
  %t2370 = add i32 %t2369, 3
  store i8 61, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2371 = load i32, i32* %t2109
  %t2372 = icmp sgt i32 %t2371, 0
  %t2373 = select i1 %t2372, i32 %t2371, i32 1
  %t2374 = getelementptr inbounds i8, i8* %t2106, i64 128
  %t2375 = bitcast i8* %t2374 to i32*
  store i32 %t2370, i32* %t2375
  %t2376 = getelementptr inbounds i8, i8* %t2106, i64 508
  %t2377 = bitcast i8* %t2376 to i32*
  store i32 %t2373, i32* %t2377
  %t2378 = add i32 %t2370, %t2373
  %t2379 = add i32 %t2378, 3
  store i8 62, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2380 = load i32, i32* %t2109
  %t2381 = icmp sgt i32 %t2380, 0
  %t2382 = select i1 %t2381, i32 %t2380, i32 1
  %t2383 = getelementptr inbounds i8, i8* %t2106, i64 132
  %t2384 = bitcast i8* %t2383 to i32*
  store i32 %t2379, i32* %t2384
  %t2385 = getelementptr inbounds i8, i8* %t2106, i64 512
  %t2386 = bitcast i8* %t2385 to i32*
  store i32 %t2382, i32* %t2386
  %t2387 = add i32 %t2379, %t2382
  %t2388 = add i32 %t2387, 3
  store i8 63, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2389 = load i32, i32* %t2109
  %t2390 = icmp sgt i32 %t2389, 0
  %t2391 = select i1 %t2390, i32 %t2389, i32 1
  %t2392 = getelementptr inbounds i8, i8* %t2106, i64 136
  %t2393 = bitcast i8* %t2392 to i32*
  store i32 %t2388, i32* %t2393
  %t2394 = getelementptr inbounds i8, i8* %t2106, i64 516
  %t2395 = bitcast i8* %t2394 to i32*
  store i32 %t2391, i32* %t2395
  %t2396 = add i32 %t2388, %t2391
  %t2397 = add i32 %t2396, 3
  store i8 64, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2398 = load i32, i32* %t2109
  %t2399 = icmp sgt i32 %t2398, 0
  %t2400 = select i1 %t2399, i32 %t2398, i32 1
  %t2401 = getelementptr inbounds i8, i8* %t2106, i64 140
  %t2402 = bitcast i8* %t2401 to i32*
  store i32 %t2397, i32* %t2402
  %t2403 = getelementptr inbounds i8, i8* %t2106, i64 520
  %t2404 = bitcast i8* %t2403 to i32*
  store i32 %t2400, i32* %t2404
  %t2405 = add i32 %t2397, %t2400
  %t2406 = add i32 %t2405, 3
  store i8 65, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2407 = load i32, i32* %t2109
  %t2408 = icmp sgt i32 %t2407, 0
  %t2409 = select i1 %t2408, i32 %t2407, i32 1
  %t2410 = getelementptr inbounds i8, i8* %t2106, i64 144
  %t2411 = bitcast i8* %t2410 to i32*
  store i32 %t2406, i32* %t2411
  %t2412 = getelementptr inbounds i8, i8* %t2106, i64 524
  %t2413 = bitcast i8* %t2412 to i32*
  store i32 %t2409, i32* %t2413
  %t2414 = add i32 %t2406, %t2409
  %t2415 = add i32 %t2414, 3
  store i8 66, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2416 = load i32, i32* %t2109
  %t2417 = icmp sgt i32 %t2416, 0
  %t2418 = select i1 %t2417, i32 %t2416, i32 1
  %t2419 = getelementptr inbounds i8, i8* %t2106, i64 148
  %t2420 = bitcast i8* %t2419 to i32*
  store i32 %t2415, i32* %t2420
  %t2421 = getelementptr inbounds i8, i8* %t2106, i64 528
  %t2422 = bitcast i8* %t2421 to i32*
  store i32 %t2418, i32* %t2422
  %t2423 = add i32 %t2415, %t2418
  %t2424 = add i32 %t2423, 3
  store i8 67, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2425 = load i32, i32* %t2109
  %t2426 = icmp sgt i32 %t2425, 0
  %t2427 = select i1 %t2426, i32 %t2425, i32 1
  %t2428 = getelementptr inbounds i8, i8* %t2106, i64 152
  %t2429 = bitcast i8* %t2428 to i32*
  store i32 %t2424, i32* %t2429
  %t2430 = getelementptr inbounds i8, i8* %t2106, i64 532
  %t2431 = bitcast i8* %t2430 to i32*
  store i32 %t2427, i32* %t2431
  %t2432 = add i32 %t2424, %t2427
  %t2433 = add i32 %t2432, 3
  store i8 68, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2434 = load i32, i32* %t2109
  %t2435 = icmp sgt i32 %t2434, 0
  %t2436 = select i1 %t2435, i32 %t2434, i32 1
  %t2437 = getelementptr inbounds i8, i8* %t2106, i64 156
  %t2438 = bitcast i8* %t2437 to i32*
  store i32 %t2433, i32* %t2438
  %t2439 = getelementptr inbounds i8, i8* %t2106, i64 536
  %t2440 = bitcast i8* %t2439 to i32*
  store i32 %t2436, i32* %t2440
  %t2441 = add i32 %t2433, %t2436
  %t2442 = add i32 %t2441, 3
  store i8 69, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2443 = load i32, i32* %t2109
  %t2444 = icmp sgt i32 %t2443, 0
  %t2445 = select i1 %t2444, i32 %t2443, i32 1
  %t2446 = getelementptr inbounds i8, i8* %t2106, i64 160
  %t2447 = bitcast i8* %t2446 to i32*
  store i32 %t2442, i32* %t2447
  %t2448 = getelementptr inbounds i8, i8* %t2106, i64 540
  %t2449 = bitcast i8* %t2448 to i32*
  store i32 %t2445, i32* %t2449
  %t2450 = add i32 %t2442, %t2445
  %t2451 = add i32 %t2450, 3
  store i8 70, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2452 = load i32, i32* %t2109
  %t2453 = icmp sgt i32 %t2452, 0
  %t2454 = select i1 %t2453, i32 %t2452, i32 1
  %t2455 = getelementptr inbounds i8, i8* %t2106, i64 164
  %t2456 = bitcast i8* %t2455 to i32*
  store i32 %t2451, i32* %t2456
  %t2457 = getelementptr inbounds i8, i8* %t2106, i64 544
  %t2458 = bitcast i8* %t2457 to i32*
  store i32 %t2454, i32* %t2458
  %t2459 = add i32 %t2451, %t2454
  %t2460 = add i32 %t2459, 3
  store i8 71, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2461 = load i32, i32* %t2109
  %t2462 = icmp sgt i32 %t2461, 0
  %t2463 = select i1 %t2462, i32 %t2461, i32 1
  %t2464 = getelementptr inbounds i8, i8* %t2106, i64 168
  %t2465 = bitcast i8* %t2464 to i32*
  store i32 %t2460, i32* %t2465
  %t2466 = getelementptr inbounds i8, i8* %t2106, i64 548
  %t2467 = bitcast i8* %t2466 to i32*
  store i32 %t2463, i32* %t2467
  %t2468 = add i32 %t2460, %t2463
  %t2469 = add i32 %t2468, 3
  store i8 72, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2470 = load i32, i32* %t2109
  %t2471 = icmp sgt i32 %t2470, 0
  %t2472 = select i1 %t2471, i32 %t2470, i32 1
  %t2473 = getelementptr inbounds i8, i8* %t2106, i64 172
  %t2474 = bitcast i8* %t2473 to i32*
  store i32 %t2469, i32* %t2474
  %t2475 = getelementptr inbounds i8, i8* %t2106, i64 552
  %t2476 = bitcast i8* %t2475 to i32*
  store i32 %t2472, i32* %t2476
  %t2477 = add i32 %t2469, %t2472
  %t2478 = add i32 %t2477, 3
  store i8 73, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2479 = load i32, i32* %t2109
  %t2480 = icmp sgt i32 %t2479, 0
  %t2481 = select i1 %t2480, i32 %t2479, i32 1
  %t2482 = getelementptr inbounds i8, i8* %t2106, i64 176
  %t2483 = bitcast i8* %t2482 to i32*
  store i32 %t2478, i32* %t2483
  %t2484 = getelementptr inbounds i8, i8* %t2106, i64 556
  %t2485 = bitcast i8* %t2484 to i32*
  store i32 %t2481, i32* %t2485
  %t2486 = add i32 %t2478, %t2481
  %t2487 = add i32 %t2486, 3
  store i8 74, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2488 = load i32, i32* %t2109
  %t2489 = icmp sgt i32 %t2488, 0
  %t2490 = select i1 %t2489, i32 %t2488, i32 1
  %t2491 = getelementptr inbounds i8, i8* %t2106, i64 180
  %t2492 = bitcast i8* %t2491 to i32*
  store i32 %t2487, i32* %t2492
  %t2493 = getelementptr inbounds i8, i8* %t2106, i64 560
  %t2494 = bitcast i8* %t2493 to i32*
  store i32 %t2490, i32* %t2494
  %t2495 = add i32 %t2487, %t2490
  %t2496 = add i32 %t2495, 3
  store i8 75, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2497 = load i32, i32* %t2109
  %t2498 = icmp sgt i32 %t2497, 0
  %t2499 = select i1 %t2498, i32 %t2497, i32 1
  %t2500 = getelementptr inbounds i8, i8* %t2106, i64 184
  %t2501 = bitcast i8* %t2500 to i32*
  store i32 %t2496, i32* %t2501
  %t2502 = getelementptr inbounds i8, i8* %t2106, i64 564
  %t2503 = bitcast i8* %t2502 to i32*
  store i32 %t2499, i32* %t2503
  %t2504 = add i32 %t2496, %t2499
  %t2505 = add i32 %t2504, 3
  store i8 76, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2506 = load i32, i32* %t2109
  %t2507 = icmp sgt i32 %t2506, 0
  %t2508 = select i1 %t2507, i32 %t2506, i32 1
  %t2509 = getelementptr inbounds i8, i8* %t2106, i64 188
  %t2510 = bitcast i8* %t2509 to i32*
  store i32 %t2505, i32* %t2510
  %t2511 = getelementptr inbounds i8, i8* %t2106, i64 568
  %t2512 = bitcast i8* %t2511 to i32*
  store i32 %t2508, i32* %t2512
  %t2513 = add i32 %t2505, %t2508
  %t2514 = add i32 %t2513, 3
  store i8 77, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2515 = load i32, i32* %t2109
  %t2516 = icmp sgt i32 %t2515, 0
  %t2517 = select i1 %t2516, i32 %t2515, i32 1
  %t2518 = getelementptr inbounds i8, i8* %t2106, i64 192
  %t2519 = bitcast i8* %t2518 to i32*
  store i32 %t2514, i32* %t2519
  %t2520 = getelementptr inbounds i8, i8* %t2106, i64 572
  %t2521 = bitcast i8* %t2520 to i32*
  store i32 %t2517, i32* %t2521
  %t2522 = add i32 %t2514, %t2517
  %t2523 = add i32 %t2522, 3
  store i8 78, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2524 = load i32, i32* %t2109
  %t2525 = icmp sgt i32 %t2524, 0
  %t2526 = select i1 %t2525, i32 %t2524, i32 1
  %t2527 = getelementptr inbounds i8, i8* %t2106, i64 196
  %t2528 = bitcast i8* %t2527 to i32*
  store i32 %t2523, i32* %t2528
  %t2529 = getelementptr inbounds i8, i8* %t2106, i64 576
  %t2530 = bitcast i8* %t2529 to i32*
  store i32 %t2526, i32* %t2530
  %t2531 = add i32 %t2523, %t2526
  %t2532 = add i32 %t2531, 3
  store i8 79, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2533 = load i32, i32* %t2109
  %t2534 = icmp sgt i32 %t2533, 0
  %t2535 = select i1 %t2534, i32 %t2533, i32 1
  %t2536 = getelementptr inbounds i8, i8* %t2106, i64 200
  %t2537 = bitcast i8* %t2536 to i32*
  store i32 %t2532, i32* %t2537
  %t2538 = getelementptr inbounds i8, i8* %t2106, i64 580
  %t2539 = bitcast i8* %t2538 to i32*
  store i32 %t2535, i32* %t2539
  %t2540 = add i32 %t2532, %t2535
  %t2541 = add i32 %t2540, 3
  store i8 80, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2542 = load i32, i32* %t2109
  %t2543 = icmp sgt i32 %t2542, 0
  %t2544 = select i1 %t2543, i32 %t2542, i32 1
  %t2545 = getelementptr inbounds i8, i8* %t2106, i64 204
  %t2546 = bitcast i8* %t2545 to i32*
  store i32 %t2541, i32* %t2546
  %t2547 = getelementptr inbounds i8, i8* %t2106, i64 584
  %t2548 = bitcast i8* %t2547 to i32*
  store i32 %t2544, i32* %t2548
  %t2549 = add i32 %t2541, %t2544
  %t2550 = add i32 %t2549, 3
  store i8 81, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2551 = load i32, i32* %t2109
  %t2552 = icmp sgt i32 %t2551, 0
  %t2553 = select i1 %t2552, i32 %t2551, i32 1
  %t2554 = getelementptr inbounds i8, i8* %t2106, i64 208
  %t2555 = bitcast i8* %t2554 to i32*
  store i32 %t2550, i32* %t2555
  %t2556 = getelementptr inbounds i8, i8* %t2106, i64 588
  %t2557 = bitcast i8* %t2556 to i32*
  store i32 %t2553, i32* %t2557
  %t2558 = add i32 %t2550, %t2553
  %t2559 = add i32 %t2558, 3
  store i8 82, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2560 = load i32, i32* %t2109
  %t2561 = icmp sgt i32 %t2560, 0
  %t2562 = select i1 %t2561, i32 %t2560, i32 1
  %t2563 = getelementptr inbounds i8, i8* %t2106, i64 212
  %t2564 = bitcast i8* %t2563 to i32*
  store i32 %t2559, i32* %t2564
  %t2565 = getelementptr inbounds i8, i8* %t2106, i64 592
  %t2566 = bitcast i8* %t2565 to i32*
  store i32 %t2562, i32* %t2566
  %t2567 = add i32 %t2559, %t2562
  %t2568 = add i32 %t2567, 3
  store i8 83, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2569 = load i32, i32* %t2109
  %t2570 = icmp sgt i32 %t2569, 0
  %t2571 = select i1 %t2570, i32 %t2569, i32 1
  %t2572 = getelementptr inbounds i8, i8* %t2106, i64 216
  %t2573 = bitcast i8* %t2572 to i32*
  store i32 %t2568, i32* %t2573
  %t2574 = getelementptr inbounds i8, i8* %t2106, i64 596
  %t2575 = bitcast i8* %t2574 to i32*
  store i32 %t2571, i32* %t2575
  %t2576 = add i32 %t2568, %t2571
  %t2577 = add i32 %t2576, 3
  store i8 84, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2578 = load i32, i32* %t2109
  %t2579 = icmp sgt i32 %t2578, 0
  %t2580 = select i1 %t2579, i32 %t2578, i32 1
  %t2581 = getelementptr inbounds i8, i8* %t2106, i64 220
  %t2582 = bitcast i8* %t2581 to i32*
  store i32 %t2577, i32* %t2582
  %t2583 = getelementptr inbounds i8, i8* %t2106, i64 600
  %t2584 = bitcast i8* %t2583 to i32*
  store i32 %t2580, i32* %t2584
  %t2585 = add i32 %t2577, %t2580
  %t2586 = add i32 %t2585, 3
  store i8 85, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2587 = load i32, i32* %t2109
  %t2588 = icmp sgt i32 %t2587, 0
  %t2589 = select i1 %t2588, i32 %t2587, i32 1
  %t2590 = getelementptr inbounds i8, i8* %t2106, i64 224
  %t2591 = bitcast i8* %t2590 to i32*
  store i32 %t2586, i32* %t2591
  %t2592 = getelementptr inbounds i8, i8* %t2106, i64 604
  %t2593 = bitcast i8* %t2592 to i32*
  store i32 %t2589, i32* %t2593
  %t2594 = add i32 %t2586, %t2589
  %t2595 = add i32 %t2594, 3
  store i8 86, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2596 = load i32, i32* %t2109
  %t2597 = icmp sgt i32 %t2596, 0
  %t2598 = select i1 %t2597, i32 %t2596, i32 1
  %t2599 = getelementptr inbounds i8, i8* %t2106, i64 228
  %t2600 = bitcast i8* %t2599 to i32*
  store i32 %t2595, i32* %t2600
  %t2601 = getelementptr inbounds i8, i8* %t2106, i64 608
  %t2602 = bitcast i8* %t2601 to i32*
  store i32 %t2598, i32* %t2602
  %t2603 = add i32 %t2595, %t2598
  %t2604 = add i32 %t2603, 3
  store i8 87, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2605 = load i32, i32* %t2109
  %t2606 = icmp sgt i32 %t2605, 0
  %t2607 = select i1 %t2606, i32 %t2605, i32 1
  %t2608 = getelementptr inbounds i8, i8* %t2106, i64 232
  %t2609 = bitcast i8* %t2608 to i32*
  store i32 %t2604, i32* %t2609
  %t2610 = getelementptr inbounds i8, i8* %t2106, i64 612
  %t2611 = bitcast i8* %t2610 to i32*
  store i32 %t2607, i32* %t2611
  %t2612 = add i32 %t2604, %t2607
  %t2613 = add i32 %t2612, 3
  store i8 88, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2614 = load i32, i32* %t2109
  %t2615 = icmp sgt i32 %t2614, 0
  %t2616 = select i1 %t2615, i32 %t2614, i32 1
  %t2617 = getelementptr inbounds i8, i8* %t2106, i64 236
  %t2618 = bitcast i8* %t2617 to i32*
  store i32 %t2613, i32* %t2618
  %t2619 = getelementptr inbounds i8, i8* %t2106, i64 616
  %t2620 = bitcast i8* %t2619 to i32*
  store i32 %t2616, i32* %t2620
  %t2621 = add i32 %t2613, %t2616
  %t2622 = add i32 %t2621, 3
  store i8 89, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2623 = load i32, i32* %t2109
  %t2624 = icmp sgt i32 %t2623, 0
  %t2625 = select i1 %t2624, i32 %t2623, i32 1
  %t2626 = getelementptr inbounds i8, i8* %t2106, i64 240
  %t2627 = bitcast i8* %t2626 to i32*
  store i32 %t2622, i32* %t2627
  %t2628 = getelementptr inbounds i8, i8* %t2106, i64 620
  %t2629 = bitcast i8* %t2628 to i32*
  store i32 %t2625, i32* %t2629
  %t2630 = add i32 %t2622, %t2625
  %t2631 = add i32 %t2630, 3
  store i8 90, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2632 = load i32, i32* %t2109
  %t2633 = icmp sgt i32 %t2632, 0
  %t2634 = select i1 %t2633, i32 %t2632, i32 1
  %t2635 = getelementptr inbounds i8, i8* %t2106, i64 244
  %t2636 = bitcast i8* %t2635 to i32*
  store i32 %t2631, i32* %t2636
  %t2637 = getelementptr inbounds i8, i8* %t2106, i64 624
  %t2638 = bitcast i8* %t2637 to i32*
  store i32 %t2634, i32* %t2638
  %t2639 = add i32 %t2631, %t2634
  %t2640 = add i32 %t2639, 3
  store i8 91, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2641 = load i32, i32* %t2109
  %t2642 = icmp sgt i32 %t2641, 0
  %t2643 = select i1 %t2642, i32 %t2641, i32 1
  %t2644 = getelementptr inbounds i8, i8* %t2106, i64 248
  %t2645 = bitcast i8* %t2644 to i32*
  store i32 %t2640, i32* %t2645
  %t2646 = getelementptr inbounds i8, i8* %t2106, i64 628
  %t2647 = bitcast i8* %t2646 to i32*
  store i32 %t2643, i32* %t2647
  %t2648 = add i32 %t2640, %t2643
  %t2649 = add i32 %t2648, 3
  store i8 92, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2650 = load i32, i32* %t2109
  %t2651 = icmp sgt i32 %t2650, 0
  %t2652 = select i1 %t2651, i32 %t2650, i32 1
  %t2653 = getelementptr inbounds i8, i8* %t2106, i64 252
  %t2654 = bitcast i8* %t2653 to i32*
  store i32 %t2649, i32* %t2654
  %t2655 = getelementptr inbounds i8, i8* %t2106, i64 632
  %t2656 = bitcast i8* %t2655 to i32*
  store i32 %t2652, i32* %t2656
  %t2657 = add i32 %t2649, %t2652
  %t2658 = add i32 %t2657, 3
  store i8 93, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2659 = load i32, i32* %t2109
  %t2660 = icmp sgt i32 %t2659, 0
  %t2661 = select i1 %t2660, i32 %t2659, i32 1
  %t2662 = getelementptr inbounds i8, i8* %t2106, i64 256
  %t2663 = bitcast i8* %t2662 to i32*
  store i32 %t2658, i32* %t2663
  %t2664 = getelementptr inbounds i8, i8* %t2106, i64 636
  %t2665 = bitcast i8* %t2664 to i32*
  store i32 %t2661, i32* %t2665
  %t2666 = add i32 %t2658, %t2661
  %t2667 = add i32 %t2666, 3
  store i8 94, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2668 = load i32, i32* %t2109
  %t2669 = icmp sgt i32 %t2668, 0
  %t2670 = select i1 %t2669, i32 %t2668, i32 1
  %t2671 = getelementptr inbounds i8, i8* %t2106, i64 260
  %t2672 = bitcast i8* %t2671 to i32*
  store i32 %t2667, i32* %t2672
  %t2673 = getelementptr inbounds i8, i8* %t2106, i64 640
  %t2674 = bitcast i8* %t2673 to i32*
  store i32 %t2670, i32* %t2674
  %t2675 = add i32 %t2667, %t2670
  %t2676 = add i32 %t2675, 3
  store i8 95, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2677 = load i32, i32* %t2109
  %t2678 = icmp sgt i32 %t2677, 0
  %t2679 = select i1 %t2678, i32 %t2677, i32 1
  %t2680 = getelementptr inbounds i8, i8* %t2106, i64 264
  %t2681 = bitcast i8* %t2680 to i32*
  store i32 %t2676, i32* %t2681
  %t2682 = getelementptr inbounds i8, i8* %t2106, i64 644
  %t2683 = bitcast i8* %t2682 to i32*
  store i32 %t2679, i32* %t2683
  %t2684 = add i32 %t2676, %t2679
  %t2685 = add i32 %t2684, 3
  store i8 96, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2686 = load i32, i32* %t2109
  %t2687 = icmp sgt i32 %t2686, 0
  %t2688 = select i1 %t2687, i32 %t2686, i32 1
  %t2689 = getelementptr inbounds i8, i8* %t2106, i64 268
  %t2690 = bitcast i8* %t2689 to i32*
  store i32 %t2685, i32* %t2690
  %t2691 = getelementptr inbounds i8, i8* %t2106, i64 648
  %t2692 = bitcast i8* %t2691 to i32*
  store i32 %t2688, i32* %t2692
  %t2693 = add i32 %t2685, %t2688
  %t2694 = add i32 %t2693, 3
  store i8 97, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2695 = load i32, i32* %t2109
  %t2696 = icmp sgt i32 %t2695, 0
  %t2697 = select i1 %t2696, i32 %t2695, i32 1
  %t2698 = getelementptr inbounds i8, i8* %t2106, i64 272
  %t2699 = bitcast i8* %t2698 to i32*
  store i32 %t2694, i32* %t2699
  %t2700 = getelementptr inbounds i8, i8* %t2106, i64 652
  %t2701 = bitcast i8* %t2700 to i32*
  store i32 %t2697, i32* %t2701
  %t2702 = add i32 %t2694, %t2697
  %t2703 = add i32 %t2702, 3
  store i8 98, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2704 = load i32, i32* %t2109
  %t2705 = icmp sgt i32 %t2704, 0
  %t2706 = select i1 %t2705, i32 %t2704, i32 1
  %t2707 = getelementptr inbounds i8, i8* %t2106, i64 276
  %t2708 = bitcast i8* %t2707 to i32*
  store i32 %t2703, i32* %t2708
  %t2709 = getelementptr inbounds i8, i8* %t2106, i64 656
  %t2710 = bitcast i8* %t2709 to i32*
  store i32 %t2706, i32* %t2710
  %t2711 = add i32 %t2703, %t2706
  %t2712 = add i32 %t2711, 3
  store i8 99, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2713 = load i32, i32* %t2109
  %t2714 = icmp sgt i32 %t2713, 0
  %t2715 = select i1 %t2714, i32 %t2713, i32 1
  %t2716 = getelementptr inbounds i8, i8* %t2106, i64 280
  %t2717 = bitcast i8* %t2716 to i32*
  store i32 %t2712, i32* %t2717
  %t2718 = getelementptr inbounds i8, i8* %t2106, i64 660
  %t2719 = bitcast i8* %t2718 to i32*
  store i32 %t2715, i32* %t2719
  %t2720 = add i32 %t2712, %t2715
  %t2721 = add i32 %t2720, 3
  store i8 100, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2722 = load i32, i32* %t2109
  %t2723 = icmp sgt i32 %t2722, 0
  %t2724 = select i1 %t2723, i32 %t2722, i32 1
  %t2725 = getelementptr inbounds i8, i8* %t2106, i64 284
  %t2726 = bitcast i8* %t2725 to i32*
  store i32 %t2721, i32* %t2726
  %t2727 = getelementptr inbounds i8, i8* %t2106, i64 664
  %t2728 = bitcast i8* %t2727 to i32*
  store i32 %t2724, i32* %t2728
  %t2729 = add i32 %t2721, %t2724
  %t2730 = add i32 %t2729, 3
  store i8 101, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2731 = load i32, i32* %t2109
  %t2732 = icmp sgt i32 %t2731, 0
  %t2733 = select i1 %t2732, i32 %t2731, i32 1
  %t2734 = getelementptr inbounds i8, i8* %t2106, i64 288
  %t2735 = bitcast i8* %t2734 to i32*
  store i32 %t2730, i32* %t2735
  %t2736 = getelementptr inbounds i8, i8* %t2106, i64 668
  %t2737 = bitcast i8* %t2736 to i32*
  store i32 %t2733, i32* %t2737
  %t2738 = add i32 %t2730, %t2733
  %t2739 = add i32 %t2738, 3
  store i8 102, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2740 = load i32, i32* %t2109
  %t2741 = icmp sgt i32 %t2740, 0
  %t2742 = select i1 %t2741, i32 %t2740, i32 1
  %t2743 = getelementptr inbounds i8, i8* %t2106, i64 292
  %t2744 = bitcast i8* %t2743 to i32*
  store i32 %t2739, i32* %t2744
  %t2745 = getelementptr inbounds i8, i8* %t2106, i64 672
  %t2746 = bitcast i8* %t2745 to i32*
  store i32 %t2742, i32* %t2746
  %t2747 = add i32 %t2739, %t2742
  %t2748 = add i32 %t2747, 3
  store i8 103, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2749 = load i32, i32* %t2109
  %t2750 = icmp sgt i32 %t2749, 0
  %t2751 = select i1 %t2750, i32 %t2749, i32 1
  %t2752 = getelementptr inbounds i8, i8* %t2106, i64 296
  %t2753 = bitcast i8* %t2752 to i32*
  store i32 %t2748, i32* %t2753
  %t2754 = getelementptr inbounds i8, i8* %t2106, i64 676
  %t2755 = bitcast i8* %t2754 to i32*
  store i32 %t2751, i32* %t2755
  %t2756 = add i32 %t2748, %t2751
  %t2757 = add i32 %t2756, 3
  store i8 104, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2758 = load i32, i32* %t2109
  %t2759 = icmp sgt i32 %t2758, 0
  %t2760 = select i1 %t2759, i32 %t2758, i32 1
  %t2761 = getelementptr inbounds i8, i8* %t2106, i64 300
  %t2762 = bitcast i8* %t2761 to i32*
  store i32 %t2757, i32* %t2762
  %t2763 = getelementptr inbounds i8, i8* %t2106, i64 680
  %t2764 = bitcast i8* %t2763 to i32*
  store i32 %t2760, i32* %t2764
  %t2765 = add i32 %t2757, %t2760
  %t2766 = add i32 %t2765, 3
  store i8 105, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2767 = load i32, i32* %t2109
  %t2768 = icmp sgt i32 %t2767, 0
  %t2769 = select i1 %t2768, i32 %t2767, i32 1
  %t2770 = getelementptr inbounds i8, i8* %t2106, i64 304
  %t2771 = bitcast i8* %t2770 to i32*
  store i32 %t2766, i32* %t2771
  %t2772 = getelementptr inbounds i8, i8* %t2106, i64 684
  %t2773 = bitcast i8* %t2772 to i32*
  store i32 %t2769, i32* %t2773
  %t2774 = add i32 %t2766, %t2769
  %t2775 = add i32 %t2774, 3
  store i8 106, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2776 = load i32, i32* %t2109
  %t2777 = icmp sgt i32 %t2776, 0
  %t2778 = select i1 %t2777, i32 %t2776, i32 1
  %t2779 = getelementptr inbounds i8, i8* %t2106, i64 308
  %t2780 = bitcast i8* %t2779 to i32*
  store i32 %t2775, i32* %t2780
  %t2781 = getelementptr inbounds i8, i8* %t2106, i64 688
  %t2782 = bitcast i8* %t2781 to i32*
  store i32 %t2778, i32* %t2782
  %t2783 = add i32 %t2775, %t2778
  %t2784 = add i32 %t2783, 3
  store i8 107, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2785 = load i32, i32* %t2109
  %t2786 = icmp sgt i32 %t2785, 0
  %t2787 = select i1 %t2786, i32 %t2785, i32 1
  %t2788 = getelementptr inbounds i8, i8* %t2106, i64 312
  %t2789 = bitcast i8* %t2788 to i32*
  store i32 %t2784, i32* %t2789
  %t2790 = getelementptr inbounds i8, i8* %t2106, i64 692
  %t2791 = bitcast i8* %t2790 to i32*
  store i32 %t2787, i32* %t2791
  %t2792 = add i32 %t2784, %t2787
  %t2793 = add i32 %t2792, 3
  store i8 108, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2794 = load i32, i32* %t2109
  %t2795 = icmp sgt i32 %t2794, 0
  %t2796 = select i1 %t2795, i32 %t2794, i32 1
  %t2797 = getelementptr inbounds i8, i8* %t2106, i64 316
  %t2798 = bitcast i8* %t2797 to i32*
  store i32 %t2793, i32* %t2798
  %t2799 = getelementptr inbounds i8, i8* %t2106, i64 696
  %t2800 = bitcast i8* %t2799 to i32*
  store i32 %t2796, i32* %t2800
  %t2801 = add i32 %t2793, %t2796
  %t2802 = add i32 %t2801, 3
  store i8 109, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2803 = load i32, i32* %t2109
  %t2804 = icmp sgt i32 %t2803, 0
  %t2805 = select i1 %t2804, i32 %t2803, i32 1
  %t2806 = getelementptr inbounds i8, i8* %t2106, i64 320
  %t2807 = bitcast i8* %t2806 to i32*
  store i32 %t2802, i32* %t2807
  %t2808 = getelementptr inbounds i8, i8* %t2106, i64 700
  %t2809 = bitcast i8* %t2808 to i32*
  store i32 %t2805, i32* %t2809
  %t2810 = add i32 %t2802, %t2805
  %t2811 = add i32 %t2810, 3
  store i8 110, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2812 = load i32, i32* %t2109
  %t2813 = icmp sgt i32 %t2812, 0
  %t2814 = select i1 %t2813, i32 %t2812, i32 1
  %t2815 = getelementptr inbounds i8, i8* %t2106, i64 324
  %t2816 = bitcast i8* %t2815 to i32*
  store i32 %t2811, i32* %t2816
  %t2817 = getelementptr inbounds i8, i8* %t2106, i64 704
  %t2818 = bitcast i8* %t2817 to i32*
  store i32 %t2814, i32* %t2818
  %t2819 = add i32 %t2811, %t2814
  %t2820 = add i32 %t2819, 3
  store i8 111, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2821 = load i32, i32* %t2109
  %t2822 = icmp sgt i32 %t2821, 0
  %t2823 = select i1 %t2822, i32 %t2821, i32 1
  %t2824 = getelementptr inbounds i8, i8* %t2106, i64 328
  %t2825 = bitcast i8* %t2824 to i32*
  store i32 %t2820, i32* %t2825
  %t2826 = getelementptr inbounds i8, i8* %t2106, i64 708
  %t2827 = bitcast i8* %t2826 to i32*
  store i32 %t2823, i32* %t2827
  %t2828 = add i32 %t2820, %t2823
  %t2829 = add i32 %t2828, 3
  store i8 112, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2830 = load i32, i32* %t2109
  %t2831 = icmp sgt i32 %t2830, 0
  %t2832 = select i1 %t2831, i32 %t2830, i32 1
  %t2833 = getelementptr inbounds i8, i8* %t2106, i64 332
  %t2834 = bitcast i8* %t2833 to i32*
  store i32 %t2829, i32* %t2834
  %t2835 = getelementptr inbounds i8, i8* %t2106, i64 712
  %t2836 = bitcast i8* %t2835 to i32*
  store i32 %t2832, i32* %t2836
  %t2837 = add i32 %t2829, %t2832
  %t2838 = add i32 %t2837, 3
  store i8 113, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2839 = load i32, i32* %t2109
  %t2840 = icmp sgt i32 %t2839, 0
  %t2841 = select i1 %t2840, i32 %t2839, i32 1
  %t2842 = getelementptr inbounds i8, i8* %t2106, i64 336
  %t2843 = bitcast i8* %t2842 to i32*
  store i32 %t2838, i32* %t2843
  %t2844 = getelementptr inbounds i8, i8* %t2106, i64 716
  %t2845 = bitcast i8* %t2844 to i32*
  store i32 %t2841, i32* %t2845
  %t2846 = add i32 %t2838, %t2841
  %t2847 = add i32 %t2846, 3
  store i8 114, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2848 = load i32, i32* %t2109
  %t2849 = icmp sgt i32 %t2848, 0
  %t2850 = select i1 %t2849, i32 %t2848, i32 1
  %t2851 = getelementptr inbounds i8, i8* %t2106, i64 340
  %t2852 = bitcast i8* %t2851 to i32*
  store i32 %t2847, i32* %t2852
  %t2853 = getelementptr inbounds i8, i8* %t2106, i64 720
  %t2854 = bitcast i8* %t2853 to i32*
  store i32 %t2850, i32* %t2854
  %t2855 = add i32 %t2847, %t2850
  %t2856 = add i32 %t2855, 3
  store i8 115, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2857 = load i32, i32* %t2109
  %t2858 = icmp sgt i32 %t2857, 0
  %t2859 = select i1 %t2858, i32 %t2857, i32 1
  %t2860 = getelementptr inbounds i8, i8* %t2106, i64 344
  %t2861 = bitcast i8* %t2860 to i32*
  store i32 %t2856, i32* %t2861
  %t2862 = getelementptr inbounds i8, i8* %t2106, i64 724
  %t2863 = bitcast i8* %t2862 to i32*
  store i32 %t2859, i32* %t2863
  %t2864 = add i32 %t2856, %t2859
  %t2865 = add i32 %t2864, 3
  store i8 116, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2866 = load i32, i32* %t2109
  %t2867 = icmp sgt i32 %t2866, 0
  %t2868 = select i1 %t2867, i32 %t2866, i32 1
  %t2869 = getelementptr inbounds i8, i8* %t2106, i64 348
  %t2870 = bitcast i8* %t2869 to i32*
  store i32 %t2865, i32* %t2870
  %t2871 = getelementptr inbounds i8, i8* %t2106, i64 728
  %t2872 = bitcast i8* %t2871 to i32*
  store i32 %t2868, i32* %t2872
  %t2873 = add i32 %t2865, %t2868
  %t2874 = add i32 %t2873, 3
  store i8 117, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2875 = load i32, i32* %t2109
  %t2876 = icmp sgt i32 %t2875, 0
  %t2877 = select i1 %t2876, i32 %t2875, i32 1
  %t2878 = getelementptr inbounds i8, i8* %t2106, i64 352
  %t2879 = bitcast i8* %t2878 to i32*
  store i32 %t2874, i32* %t2879
  %t2880 = getelementptr inbounds i8, i8* %t2106, i64 732
  %t2881 = bitcast i8* %t2880 to i32*
  store i32 %t2877, i32* %t2881
  %t2882 = add i32 %t2874, %t2877
  %t2883 = add i32 %t2882, 3
  store i8 118, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2884 = load i32, i32* %t2109
  %t2885 = icmp sgt i32 %t2884, 0
  %t2886 = select i1 %t2885, i32 %t2884, i32 1
  %t2887 = getelementptr inbounds i8, i8* %t2106, i64 356
  %t2888 = bitcast i8* %t2887 to i32*
  store i32 %t2883, i32* %t2888
  %t2889 = getelementptr inbounds i8, i8* %t2106, i64 736
  %t2890 = bitcast i8* %t2889 to i32*
  store i32 %t2886, i32* %t2890
  %t2891 = add i32 %t2883, %t2886
  %t2892 = add i32 %t2891, 3
  store i8 119, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2893 = load i32, i32* %t2109
  %t2894 = icmp sgt i32 %t2893, 0
  %t2895 = select i1 %t2894, i32 %t2893, i32 1
  %t2896 = getelementptr inbounds i8, i8* %t2106, i64 360
  %t2897 = bitcast i8* %t2896 to i32*
  store i32 %t2892, i32* %t2897
  %t2898 = getelementptr inbounds i8, i8* %t2106, i64 740
  %t2899 = bitcast i8* %t2898 to i32*
  store i32 %t2895, i32* %t2899
  %t2900 = add i32 %t2892, %t2895
  %t2901 = add i32 %t2900, 3
  store i8 120, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2902 = load i32, i32* %t2109
  %t2903 = icmp sgt i32 %t2902, 0
  %t2904 = select i1 %t2903, i32 %t2902, i32 1
  %t2905 = getelementptr inbounds i8, i8* %t2106, i64 364
  %t2906 = bitcast i8* %t2905 to i32*
  store i32 %t2901, i32* %t2906
  %t2907 = getelementptr inbounds i8, i8* %t2106, i64 744
  %t2908 = bitcast i8* %t2907 to i32*
  store i32 %t2904, i32* %t2908
  %t2909 = add i32 %t2901, %t2904
  %t2910 = add i32 %t2909, 3
  store i8 121, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2911 = load i32, i32* %t2109
  %t2912 = icmp sgt i32 %t2911, 0
  %t2913 = select i1 %t2912, i32 %t2911, i32 1
  %t2914 = getelementptr inbounds i8, i8* %t2106, i64 368
  %t2915 = bitcast i8* %t2914 to i32*
  store i32 %t2910, i32* %t2915
  %t2916 = getelementptr inbounds i8, i8* %t2106, i64 748
  %t2917 = bitcast i8* %t2916 to i32*
  store i32 %t2913, i32* %t2917
  %t2918 = add i32 %t2910, %t2913
  %t2919 = add i32 %t2918, 3
  store i8 122, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2920 = load i32, i32* %t2109
  %t2921 = icmp sgt i32 %t2920, 0
  %t2922 = select i1 %t2921, i32 %t2920, i32 1
  %t2923 = getelementptr inbounds i8, i8* %t2106, i64 372
  %t2924 = bitcast i8* %t2923 to i32*
  store i32 %t2919, i32* %t2924
  %t2925 = getelementptr inbounds i8, i8* %t2106, i64 752
  %t2926 = bitcast i8* %t2925 to i32*
  store i32 %t2922, i32* %t2926
  %t2927 = add i32 %t2919, %t2922
  %t2928 = add i32 %t2927, 3
  store i8 123, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2929 = load i32, i32* %t2109
  %t2930 = icmp sgt i32 %t2929, 0
  %t2931 = select i1 %t2930, i32 %t2929, i32 1
  %t2932 = getelementptr inbounds i8, i8* %t2106, i64 376
  %t2933 = bitcast i8* %t2932 to i32*
  store i32 %t2928, i32* %t2933
  %t2934 = getelementptr inbounds i8, i8* %t2106, i64 756
  %t2935 = bitcast i8* %t2934 to i32*
  store i32 %t2931, i32* %t2935
  %t2936 = add i32 %t2928, %t2931
  %t2937 = add i32 %t2936, 3
  store i8 124, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2938 = load i32, i32* %t2109
  %t2939 = icmp sgt i32 %t2938, 0
  %t2940 = select i1 %t2939, i32 %t2938, i32 1
  %t2941 = getelementptr inbounds i8, i8* %t2106, i64 380
  %t2942 = bitcast i8* %t2941 to i32*
  store i32 %t2937, i32* %t2942
  %t2943 = getelementptr inbounds i8, i8* %t2106, i64 760
  %t2944 = bitcast i8* %t2943 to i32*
  store i32 %t2940, i32* %t2944
  %t2945 = add i32 %t2937, %t2940
  %t2946 = add i32 %t2945, 3
  store i8 125, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2947 = load i32, i32* %t2109
  %t2948 = icmp sgt i32 %t2947, 0
  %t2949 = select i1 %t2948, i32 %t2947, i32 1
  %t2950 = getelementptr inbounds i8, i8* %t2106, i64 384
  %t2951 = bitcast i8* %t2950 to i32*
  store i32 %t2946, i32* %t2951
  %t2952 = getelementptr inbounds i8, i8* %t2106, i64 764
  %t2953 = bitcast i8* %t2952 to i32*
  store i32 %t2949, i32* %t2953
  %t2954 = add i32 %t2946, %t2949
  %t2955 = add i32 %t2954, 3
  store i8 126, i8* %t2107
  call i32 @GetTextExtentPoint32A(i8* %t2097, i8* %t2107, i32 1, i8* %t2108)
  %t2956 = load i32, i32* %t2109
  %t2957 = icmp sgt i32 %t2956, 0
  %t2958 = select i1 %t2957, i32 %t2956, i32 1
  %t2959 = getelementptr inbounds i8, i8* %t2106, i64 388
  %t2960 = bitcast i8* %t2959 to i32*
  store i32 %t2955, i32* %t2960
  %t2961 = getelementptr inbounds i8, i8* %t2106, i64 768
  %t2962 = bitcast i8* %t2961 to i32*
  store i32 %t2958, i32* %t2962
  %t2963 = add i32 %t2955, %t2958
  %t2964 = add i32 %t2963, 3
  %t2966 = getelementptr inbounds [40 x i8], [40 x i8]* %t2965, i64 0, i64 0
  store i64 0, i64* %t2967
  br label %ht_fill8_cond_97
ht_fill8_cond_97:
  %t2968 = load i64, i64* %t2967
  %t2969 = icmp slt i64 %t2968, 40
  br i1 %t2969, label %ht_fill8_body_98, label %ht_fill8_end_99
ht_fill8_body_98:
  %t2970 = getelementptr inbounds i8, i8* %t2966, i64 %t2968
  store i8 0, i8* %t2970
  %t2971 = add i64 %t2968, 1
  store i64 %t2971, i64* %t2967
  br label %ht_fill8_cond_97
ht_fill8_end_99:
  %t2972 = bitcast i8* %t2966 to i32*
  store i32 40, i32* %t2972
  %t2973 = getelementptr inbounds i8, i8* %t2966, i64 4
  %t2974 = bitcast i8* %t2973 to i32*
  store i32 %t2964, i32* %t2974
  %t2975 = sub i32 0, %t2105
  %t2976 = getelementptr inbounds i8, i8* %t2966, i64 8
  %t2977 = bitcast i8* %t2976 to i32*
  store i32 %t2975, i32* %t2977
  %t2978 = getelementptr inbounds i8, i8* %t2966, i64 12
  %t2979 = bitcast i8* %t2978 to i16*
  store i16 1, i16* %t2979
  %t2980 = getelementptr inbounds i8, i8* %t2966, i64 14
  %t2981 = bitcast i8* %t2980 to i16*
  store i16 32, i16* %t2981
  %t2983 = call i8* @CreateDIBSection(i8* %t2097, i8* %t2966, i32 0, i8** %t2982, i8* null, i32 0)
  %t2984 = icmp eq i8* %t2983, null
  br i1 %t2984, label %rasterize_dib_fail_100, label %rasterize_dib_ok_101
rasterize_dib_fail_100:
  call i8* @SelectObject(i8* %t2097, i8* %t2099)
  call i32 @DeleteObject(i8* %t2093)
  call i32 @DeleteDC(i8* %t2097)
  call void @free(i8* %t2106)
  br label %rasterize_end_94
rasterize_dib_ok_101:
  %t2985 = load i8*, i8** %t2982
  %t2986 = call i8* @SelectObject(i8* %t2097, i8* %t2983)
  %t2987 = mul i32 %t2964, %t2105
  %t2988 = sext i32 %t2987 to i64
  %t2989 = mul i64 %t2988, 4
  store i64 0, i64* %t2990
  br label %ht_fill8_cond_102
ht_fill8_cond_102:
  %t2991 = load i64, i64* %t2990
  %t2992 = icmp slt i64 %t2991, %t2989
  br i1 %t2992, label %ht_fill8_body_103, label %ht_fill8_end_104
ht_fill8_body_103:
  %t2993 = getelementptr inbounds i8, i8* %t2985, i64 %t2991
  store i8 0, i8* %t2993
  %t2994 = add i64 %t2991, 1
  store i64 %t2994, i64* %t2990
  br label %ht_fill8_cond_102
ht_fill8_end_104:
  store i8 32, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 0, i32 0, i8* %t2107, i32 1)
  store i8 33, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2118, i32 0, i8* %t2107, i32 1)
  store i8 34, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2127, i32 0, i8* %t2107, i32 1)
  store i8 35, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2136, i32 0, i8* %t2107, i32 1)
  store i8 36, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2145, i32 0, i8* %t2107, i32 1)
  store i8 37, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2154, i32 0, i8* %t2107, i32 1)
  store i8 38, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2163, i32 0, i8* %t2107, i32 1)
  store i8 39, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2172, i32 0, i8* %t2107, i32 1)
  store i8 40, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2181, i32 0, i8* %t2107, i32 1)
  store i8 41, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2190, i32 0, i8* %t2107, i32 1)
  store i8 42, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2199, i32 0, i8* %t2107, i32 1)
  store i8 43, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2208, i32 0, i8* %t2107, i32 1)
  store i8 44, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2217, i32 0, i8* %t2107, i32 1)
  store i8 45, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2226, i32 0, i8* %t2107, i32 1)
  store i8 46, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2235, i32 0, i8* %t2107, i32 1)
  store i8 47, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2244, i32 0, i8* %t2107, i32 1)
  store i8 48, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2253, i32 0, i8* %t2107, i32 1)
  store i8 49, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2262, i32 0, i8* %t2107, i32 1)
  store i8 50, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2271, i32 0, i8* %t2107, i32 1)
  store i8 51, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2280, i32 0, i8* %t2107, i32 1)
  store i8 52, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2289, i32 0, i8* %t2107, i32 1)
  store i8 53, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2298, i32 0, i8* %t2107, i32 1)
  store i8 54, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2307, i32 0, i8* %t2107, i32 1)
  store i8 55, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2316, i32 0, i8* %t2107, i32 1)
  store i8 56, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2325, i32 0, i8* %t2107, i32 1)
  store i8 57, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2334, i32 0, i8* %t2107, i32 1)
  store i8 58, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2343, i32 0, i8* %t2107, i32 1)
  store i8 59, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2352, i32 0, i8* %t2107, i32 1)
  store i8 60, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2361, i32 0, i8* %t2107, i32 1)
  store i8 61, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2370, i32 0, i8* %t2107, i32 1)
  store i8 62, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2379, i32 0, i8* %t2107, i32 1)
  store i8 63, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2388, i32 0, i8* %t2107, i32 1)
  store i8 64, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2397, i32 0, i8* %t2107, i32 1)
  store i8 65, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2406, i32 0, i8* %t2107, i32 1)
  store i8 66, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2415, i32 0, i8* %t2107, i32 1)
  store i8 67, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2424, i32 0, i8* %t2107, i32 1)
  store i8 68, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2433, i32 0, i8* %t2107, i32 1)
  store i8 69, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2442, i32 0, i8* %t2107, i32 1)
  store i8 70, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2451, i32 0, i8* %t2107, i32 1)
  store i8 71, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2460, i32 0, i8* %t2107, i32 1)
  store i8 72, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2469, i32 0, i8* %t2107, i32 1)
  store i8 73, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2478, i32 0, i8* %t2107, i32 1)
  store i8 74, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2487, i32 0, i8* %t2107, i32 1)
  store i8 75, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2496, i32 0, i8* %t2107, i32 1)
  store i8 76, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2505, i32 0, i8* %t2107, i32 1)
  store i8 77, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2514, i32 0, i8* %t2107, i32 1)
  store i8 78, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2523, i32 0, i8* %t2107, i32 1)
  store i8 79, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2532, i32 0, i8* %t2107, i32 1)
  store i8 80, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2541, i32 0, i8* %t2107, i32 1)
  store i8 81, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2550, i32 0, i8* %t2107, i32 1)
  store i8 82, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2559, i32 0, i8* %t2107, i32 1)
  store i8 83, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2568, i32 0, i8* %t2107, i32 1)
  store i8 84, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2577, i32 0, i8* %t2107, i32 1)
  store i8 85, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2586, i32 0, i8* %t2107, i32 1)
  store i8 86, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2595, i32 0, i8* %t2107, i32 1)
  store i8 87, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2604, i32 0, i8* %t2107, i32 1)
  store i8 88, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2613, i32 0, i8* %t2107, i32 1)
  store i8 89, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2622, i32 0, i8* %t2107, i32 1)
  store i8 90, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2631, i32 0, i8* %t2107, i32 1)
  store i8 91, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2640, i32 0, i8* %t2107, i32 1)
  store i8 92, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2649, i32 0, i8* %t2107, i32 1)
  store i8 93, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2658, i32 0, i8* %t2107, i32 1)
  store i8 94, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2667, i32 0, i8* %t2107, i32 1)
  store i8 95, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2676, i32 0, i8* %t2107, i32 1)
  store i8 96, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2685, i32 0, i8* %t2107, i32 1)
  store i8 97, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2694, i32 0, i8* %t2107, i32 1)
  store i8 98, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2703, i32 0, i8* %t2107, i32 1)
  store i8 99, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2712, i32 0, i8* %t2107, i32 1)
  store i8 100, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2721, i32 0, i8* %t2107, i32 1)
  store i8 101, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2730, i32 0, i8* %t2107, i32 1)
  store i8 102, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2739, i32 0, i8* %t2107, i32 1)
  store i8 103, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2748, i32 0, i8* %t2107, i32 1)
  store i8 104, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2757, i32 0, i8* %t2107, i32 1)
  store i8 105, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2766, i32 0, i8* %t2107, i32 1)
  store i8 106, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2775, i32 0, i8* %t2107, i32 1)
  store i8 107, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2784, i32 0, i8* %t2107, i32 1)
  store i8 108, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2793, i32 0, i8* %t2107, i32 1)
  store i8 109, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2802, i32 0, i8* %t2107, i32 1)
  store i8 110, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2811, i32 0, i8* %t2107, i32 1)
  store i8 111, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2820, i32 0, i8* %t2107, i32 1)
  store i8 112, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2829, i32 0, i8* %t2107, i32 1)
  store i8 113, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2838, i32 0, i8* %t2107, i32 1)
  store i8 114, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2847, i32 0, i8* %t2107, i32 1)
  store i8 115, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2856, i32 0, i8* %t2107, i32 1)
  store i8 116, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2865, i32 0, i8* %t2107, i32 1)
  store i8 117, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2874, i32 0, i8* %t2107, i32 1)
  store i8 118, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2883, i32 0, i8* %t2107, i32 1)
  store i8 119, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2892, i32 0, i8* %t2107, i32 1)
  store i8 120, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2901, i32 0, i8* %t2107, i32 1)
  store i8 121, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2910, i32 0, i8* %t2107, i32 1)
  store i8 122, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2919, i32 0, i8* %t2107, i32 1)
  store i8 123, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2928, i32 0, i8* %t2107, i32 1)
  store i8 124, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2937, i32 0, i8* %t2107, i32 1)
  store i8 125, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2946, i32 0, i8* %t2107, i32 1)
  store i8 126, i8* %t2107
  call i32 @TextOutA(i8* %t2097, i32 %t2955, i32 0, i8* %t2107, i32 1)
  call i8* @SelectObject(i8* %t2097, i8* %t2099)
  call i8* @SelectObject(i8* %t2097, i8* %t2986)
  store i64 0, i64* %t2995
  br label %cov2a_cond_105
cov2a_cond_105:
  %t2996 = load i64, i64* %t2995
  %t2997 = icmp slt i64 %t2996, %t2988
  br i1 %t2997, label %cov2a_body_106, label %cov2a_end_107
cov2a_body_106:
  %t2998 = mul i64 %t2996, 4
  %t2999 = getelementptr inbounds i8, i8* %t2985, i64 %t2998
  %t3000 = load i8, i8* %t2999
  %t3001 = getelementptr inbounds i8, i8* %t2999, i64 1
  %t3002 = getelementptr inbounds i8, i8* %t2999, i64 2
  %t3003 = getelementptr inbounds i8, i8* %t2999, i64 3
  store i8 %t3000, i8* %t3003
  store i8 255, i8* %t2999
  store i8 255, i8* %t3001
  store i8 255, i8* %t3002
  %t3004 = add i64 %t2996, 1
  store i64 %t3004, i64* %t2995
  br label %cov2a_cond_105
cov2a_end_107:
  %t3005 = call i8* @SDL_CreateTexture(i8* %t2096, i32 372645892, i32 0, i32 %t2964, i32 %t2105)
  %t3006 = icmp eq i8* %t3005, null
  br i1 %t3006, label %rasterize_tex_fail_108, label %rasterize_tex_ok_109
rasterize_tex_fail_108:
  call i32 @DeleteObject(i8* %t2983)
  call i32 @DeleteObject(i8* %t2093)
  call i32 @DeleteDC(i8* %t2097)
  call void @free(i8* %t2106)
  br label %rasterize_end_94
rasterize_tex_ok_109:
  call i32 @SDL_SetTextureBlendMode(i8* %t3005, i32 1)
  %t3007 = mul i32 %t2964, 4
  call i32 @SDL_UpdateTexture(i8* %t3005, i8* null, i8* %t2985, i32 %t3007)
  call i32 @DeleteObject(i8* %t2983)
  call i32 @DeleteObject(i8* %t2093)
  call i32 @DeleteDC(i8* %t2097)
  %t3008 = getelementptr inbounds i8, i8* %t2106, i64 0
  %t3009 = bitcast i8* %t3008 to i8**
  store i8* %t3005, i8** %t3009
  %t3010 = getelementptr inbounds i8, i8* %t2106, i64 8
  %t3011 = bitcast i8* %t3010 to i32*
  store i32 %t2105, i32* %t3011
  store i8* %t2106, i8** %t2095
  br label %rasterize_end_94
rasterize_end_94:
  %t3012 = load i8*, i8** %t2095
  call i32 @RemoveFontResourceExA(i8* %t1888, i32 16, i8* null)
  store i8* %t3012, i8** %t1892
  br label %ttf_load_end_62
ttf_load_end_62:
  call void @star_rc_release(i8* %t1888)
  %t3013 = load i8*, i8** %t1892
  store i8* %t3013, i8** %t1884
  %t3015 = and i32 18, 255
  %t3016 = and i32 18, 255
  %t3017 = shl i32 %t3016, 8
  %t3018 = or i32 %t3015, %t3017
  %t3019 = and i32 26, 255
  %t3020 = shl i32 %t3019, 16
  %t3021 = or i32 %t3018, %t3020
  %t3022 = and i32 255, 255
  %t3023 = shl i32 %t3022, 24
  %t3024 = or i32 %t3021, %t3023
  store i32 %t3024, i32* %t3014
  %t3026 = and i32 255, 255
  %t3027 = and i32 255, 255
  %t3028 = shl i32 %t3027, 8
  %t3029 = or i32 %t3026, %t3028
  %t3030 = and i32 255, 255
  %t3031 = shl i32 %t3030, 16
  %t3032 = or i32 %t3029, %t3031
  %t3033 = and i32 255, 255
  %t3034 = shl i32 %t3033, 24
  %t3035 = or i32 %t3032, %t3034
  store i32 %t3035, i32* %t3025
  %t3037 = and i32 190, 255
  %t3038 = and i32 190, 255
  %t3039 = shl i32 %t3038, 8
  %t3040 = or i32 %t3037, %t3039
  %t3041 = and i32 200, 255
  %t3042 = shl i32 %t3041, 16
  %t3043 = or i32 %t3040, %t3042
  %t3044 = and i32 255, 255
  %t3045 = shl i32 %t3044, 24
  %t3046 = or i32 %t3043, %t3045
  store i32 %t3046, i32* %t3036
  store i32 41, i32* %t3047
  br label %while_cond_110
while_cond_110:
  br i1 true, label %while_body_111, label %while_else_112
while_body_111:
  %t3048 = load i8*, i8** %t2
  %t3049 = icmp eq i8* %t3048, null
  br i1 %t3049, label %sdl_null_window_114, label %sdl_window_handle_ok_115
sdl_null_window_114:
  %t3050 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.13, i64 0, i64 0
  call i32 @puts(i8* %t3050)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_115:
  store i1 false, i1* %t3051
  %t3053 = getelementptr inbounds [56 x i8], [56 x i8]* %t3052, i64 0, i64 0
  br label %sdl_poll_cond_116
sdl_poll_cond_116:
  %t3054 = call i32 @SDL_PollEvent(i8* %t3053)
  %t3055 = icmp ne i32 %t3054, 0
  br i1 %t3055, label %sdl_poll_body_117, label %sdl_poll_end_119
sdl_poll_body_117:
  %t3056 = bitcast i8* %t3053 to i32*
  %t3057 = load i32, i32* %t3056
  %t3058 = icmp eq i32 %t3057, 256
  br i1 %t3058, label %sdl_poll_set_quit_118, label %sdl_poll_cond_116
sdl_poll_set_quit_118:
  store i1 true, i1* %t3051
  br label %sdl_poll_cond_116
sdl_poll_end_119:
  %t3059 = load i1, i1* %t3051
  br i1 %t3059, label %if_then_120, label %if_else_121
if_then_120:
  br label %while_end_113
if_else_121:
  br label %if_end_122
if_end_122:
  %t3060 = load i32, i32* %t3047
  %t3061 = icmp sge i32 %t3060, 0
  %t3062 = icmp slt i32 %t3060, 512
  %t3063 = and i1 %t3061, %t3062
  br i1 %t3063, label %key_down_read_123, label %key_down_end_124
key_down_read_123:
  %t3064 = call i8* @SDL_GetKeyboardState(i32* null)
  %t3065 = sext i32 %t3060 to i64
  %t3066 = getelementptr inbounds i8, i8* %t3064, i64 %t3065
  %t3067 = load i8, i8* %t3066
  %t3068 = icmp ne i8 %t3067, 0
  br label %key_down_end_124
key_down_end_124:
  %t3069 = phi i1 [ false, %if_end_122 ], [ %t3068, %key_down_read_123 ]
  br i1 %t3069, label %if_then_125, label %if_else_126
if_then_125:
  br label %while_end_113
if_else_126:
  br label %if_end_127
if_end_127:
  %t3070 = load i8*, i8** %t2
  %t3071 = icmp eq i8* %t3070, null
  br i1 %t3071, label %sdl_null_window_128, label %sdl_window_handle_ok_129
sdl_null_window_128:
  %t3072 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.14, i64 0, i64 0
  call i32 @puts(i8* %t3072)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_129:
  %t3073 = call i8* @SDL_GetRenderer(i8* %t3070)
  %t3074 = load i32, i32* %t3014
  %t3075 = and i32 %t3074, 255
  %t3076 = trunc i32 %t3075 to i8
  %t3077 = lshr i32 %t3074, 8
  %t3078 = and i32 %t3077, 255
  %t3079 = trunc i32 %t3078 to i8
  %t3080 = lshr i32 %t3074, 16
  %t3081 = and i32 %t3080, 255
  %t3082 = trunc i32 %t3081 to i8
  %t3083 = lshr i32 %t3074, 24
  %t3084 = and i32 %t3083, 255
  %t3085 = trunc i32 %t3084 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t3073, i8 %t3076, i8 %t3079, i8 %t3082, i8 %t3085)
  call i32 @SDL_RenderClear(i8* %t3073)
  %t3086 = load i8*, i8** %t2
  %t3087 = icmp eq i8* %t3086, null
  br i1 %t3087, label %sdl_null_window_130, label %sdl_window_handle_ok_131
sdl_null_window_130:
  %t3088 = getelementptr inbounds [79 x i8], [79 x i8]* @.str.15, i64 0, i64 0
  call i32 @puts(i8* %t3088)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_131:
  %t3089 = load i8*, i8** %t15
  %t3090 = icmp eq i8* %t3089, null
  br i1 %t3090, label %sysfont_null_handle_132, label %sysfont_handle_ok_133
sysfont_null_handle_132:
  %t3091 = getelementptr inbounds [83 x i8], [83 x i8]* @.str.16, i64 0, i64 0
  call i32 @puts(i8* %t3091)
  call void @exit(i32 1)
  unreachable
sysfont_handle_ok_133:
  %t3092 = call i8* @SDL_GetRenderer(i8* %t3086)
  %t3093 = bitcast i8* %t3089 to i8**
  %t3094 = load i8*, i8** %t3093
  %t3095 = getelementptr inbounds i8, i8* %t3089, i64 8
  %t3096 = bitcast i8* %t3095 to i32*
  %t3097 = load i32, i32* %t3096
  %t3098 = load i32, i32* %t3025
  %t3099 = and i32 %t3098, 255
  %t3100 = trunc i32 %t3099 to i8
  %t3101 = lshr i32 %t3098, 8
  %t3102 = and i32 %t3101, 255
  %t3103 = trunc i32 %t3102 to i8
  %t3104 = lshr i32 %t3098, 16
  %t3105 = and i32 %t3104, 255
  %t3106 = trunc i32 %t3105 to i8
  %t3107 = lshr i32 %t3098, 24
  %t3108 = and i32 %t3107, 255
  %t3109 = trunc i32 %t3108 to i8
  call i32 @SDL_SetTextureColorMod(i8* %t3094, i8 %t3100, i8 %t3103, i8 %t3106)
  call i32 @SDL_SetTextureAlphaMod(i8* %t3094, i8 %t3109)
  %t3110 = getelementptr inbounds { i64, i8*, [12 x i8] }, { i64, i8*, [12 x i8] }* @.str.17, i64 0, i32 2, i64 0
  store i32 24, i32* %t3111
  store i32 24, i32* %t3112
  store i64 0, i64* %t3113
  br label %draw_ttf_cond_134
draw_ttf_cond_134:
  %t3114 = load i64, i64* %t3113
  %t3115 = getelementptr inbounds i8, i8* %t3110, i64 %t3114
  %t3116 = load i8, i8* %t3115
  %t3117 = icmp eq i8 %t3116, 0
  br i1 %t3117, label %draw_ttf_end_140, label %draw_ttf_body_135
draw_ttf_body_135:
  %t3118 = zext i8 %t3116 to i32
  %t3119 = icmp eq i32 %t3118, 10
  br i1 %t3119, label %draw_ttf_newline_136, label %draw_ttf_glyph_137
draw_ttf_newline_136:
  store i32 24, i32* %t3111
  %t3120 = load i32, i32* %t3112
  %t3121 = add i32 %t3120, %t3097
  store i32 %t3121, i32* %t3112
  %t3122 = add i64 %t3114, 1
  store i64 %t3122, i64* %t3113
  br label %draw_ttf_cond_134
draw_ttf_glyph_137:
  %t3123 = sub i32 %t3118, 32
  %t3124 = icmp sge i32 %t3123, 0
  %t3125 = icmp slt i32 %t3123, 95
  %t3126 = and i1 %t3124, %t3125
  %t3127 = getelementptr inbounds i8, i8* %t3089, i64 12
  %t3128 = bitcast i8* %t3127 to i32*
  %t3129 = getelementptr inbounds i8, i8* %t3089, i64 392
  %t3130 = bitcast i8* %t3129 to i32*
  %t3131 = select i1 %t3126, i32 %t3123, i32 0
  %t3132 = sext i32 %t3131 to i64
  %t3133 = getelementptr inbounds i32, i32* %t3128, i64 %t3132
  %t3134 = load i32, i32* %t3133
  %t3135 = getelementptr inbounds i32, i32* %t3130, i64 %t3132
  %t3136 = load i32, i32* %t3135
  br i1 %t3126, label %draw_ttf_draw_138, label %draw_ttf_after_139
draw_ttf_draw_138:
  %t3137 = load i32, i32* %t3111
  %t3138 = load i32, i32* %t3112
  %t3140 = getelementptr inbounds [16 x i8], [16 x i8]* %t3139, i64 0, i64 0
  %t3141 = bitcast i8* %t3140 to i32*
  store i32 %t3134, i32* %t3141
  %t3142 = getelementptr inbounds i8, i8* %t3140, i64 4
  %t3143 = bitcast i8* %t3142 to i32*
  store i32 0, i32* %t3143
  %t3144 = getelementptr inbounds i8, i8* %t3140, i64 8
  %t3145 = bitcast i8* %t3144 to i32*
  store i32 %t3136, i32* %t3145
  %t3146 = getelementptr inbounds i8, i8* %t3140, i64 12
  %t3147 = bitcast i8* %t3146 to i32*
  store i32 %t3097, i32* %t3147
  %t3149 = getelementptr inbounds [16 x i8], [16 x i8]* %t3148, i64 0, i64 0
  %t3150 = bitcast i8* %t3149 to i32*
  store i32 %t3137, i32* %t3150
  %t3151 = getelementptr inbounds i8, i8* %t3149, i64 4
  %t3152 = bitcast i8* %t3151 to i32*
  store i32 %t3138, i32* %t3152
  %t3153 = getelementptr inbounds i8, i8* %t3149, i64 8
  %t3154 = bitcast i8* %t3153 to i32*
  store i32 %t3136, i32* %t3154
  %t3155 = getelementptr inbounds i8, i8* %t3149, i64 12
  %t3156 = bitcast i8* %t3155 to i32*
  store i32 %t3097, i32* %t3156
  call i32 @SDL_RenderCopy(i8* %t3092, i8* %t3094, i8* %t3140, i8* %t3149)
  br label %draw_ttf_after_139
draw_ttf_after_139:
  %t3157 = phi i32 [ %t3136, %draw_ttf_draw_138 ], [ %t3136, %draw_ttf_glyph_137 ]
  %t3158 = load i32, i32* %t3111
  %t3159 = add i32 %t3158, %t3157
  store i32 %t3159, i32* %t3111
  %t3160 = add i64 %t3114, 1
  store i64 %t3160, i64* %t3113
  br label %draw_ttf_cond_134
draw_ttf_end_140:
  call void @star_rc_release(i8* %t3110)
  %t3162 = getelementptr inbounds { i64, i8*, [82 x i8] }, { i64, i8*, [82 x i8] }* @.str.18, i64 0, i32 2, i64 0
  store i8* %t3162, i8** %t3161
  %t3163 = load i8*, i8** %t2
  %t3164 = icmp eq i8* %t3163, null
  br i1 %t3164, label %sdl_null_window_141, label %sdl_window_handle_ok_142
sdl_null_window_141:
  %t3165 = getelementptr inbounds [79 x i8], [79 x i8]* @.str.19, i64 0, i64 0
  call i32 @puts(i8* %t3165)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_142:
  %t3166 = load i8*, i8** %t944
  %t3167 = icmp eq i8* %t3166, null
  br i1 %t3167, label %sysfont_null_handle_143, label %sysfont_handle_ok_144
sysfont_null_handle_143:
  %t3168 = getelementptr inbounds [83 x i8], [83 x i8]* @.str.20, i64 0, i64 0
  call i32 @puts(i8* %t3168)
  call void @exit(i32 1)
  unreachable
sysfont_handle_ok_144:
  %t3169 = call i8* @SDL_GetRenderer(i8* %t3163)
  %t3170 = bitcast i8* %t3166 to i8**
  %t3171 = load i8*, i8** %t3170
  %t3172 = getelementptr inbounds i8, i8* %t3166, i64 8
  %t3173 = bitcast i8* %t3172 to i32*
  %t3174 = load i32, i32* %t3173
  %t3175 = load i32, i32* %t3036
  %t3176 = and i32 %t3175, 255
  %t3177 = trunc i32 %t3176 to i8
  %t3178 = lshr i32 %t3175, 8
  %t3179 = and i32 %t3178, 255
  %t3180 = trunc i32 %t3179 to i8
  %t3181 = lshr i32 %t3175, 16
  %t3182 = and i32 %t3181, 255
  %t3183 = trunc i32 %t3182 to i8
  %t3184 = lshr i32 %t3175, 24
  %t3185 = and i32 %t3184, 255
  %t3186 = trunc i32 %t3185 to i8
  call i32 @SDL_SetTextureColorMod(i8* %t3171, i8 %t3177, i8 %t3180, i8 %t3183)
  call i32 @SDL_SetTextureAlphaMod(i8* %t3171, i8 %t3186)
  %t3187 = load i8*, i8** %t3161
  %t3188 = load i8*, i8** %t3161
  call void @star_rc_retain(i8* %t3188)
  store i32 24, i32* %t3189
  store i32 80, i32* %t3190
  store i64 0, i64* %t3191
  br label %draw_ttf_cond_145
draw_ttf_cond_145:
  %t3192 = load i64, i64* %t3191
  %t3193 = getelementptr inbounds i8, i8* %t3187, i64 %t3192
  %t3194 = load i8, i8* %t3193
  %t3195 = icmp eq i8 %t3194, 0
  br i1 %t3195, label %draw_ttf_end_151, label %draw_ttf_body_146
draw_ttf_body_146:
  %t3196 = zext i8 %t3194 to i32
  %t3197 = icmp eq i32 %t3196, 10
  br i1 %t3197, label %draw_ttf_newline_147, label %draw_ttf_glyph_148
draw_ttf_newline_147:
  store i32 24, i32* %t3189
  %t3198 = load i32, i32* %t3190
  %t3199 = add i32 %t3198, %t3174
  store i32 %t3199, i32* %t3190
  %t3200 = add i64 %t3192, 1
  store i64 %t3200, i64* %t3191
  br label %draw_ttf_cond_145
draw_ttf_glyph_148:
  %t3201 = sub i32 %t3196, 32
  %t3202 = icmp sge i32 %t3201, 0
  %t3203 = icmp slt i32 %t3201, 95
  %t3204 = and i1 %t3202, %t3203
  %t3205 = getelementptr inbounds i8, i8* %t3166, i64 12
  %t3206 = bitcast i8* %t3205 to i32*
  %t3207 = getelementptr inbounds i8, i8* %t3166, i64 392
  %t3208 = bitcast i8* %t3207 to i32*
  %t3209 = select i1 %t3204, i32 %t3201, i32 0
  %t3210 = sext i32 %t3209 to i64
  %t3211 = getelementptr inbounds i32, i32* %t3206, i64 %t3210
  %t3212 = load i32, i32* %t3211
  %t3213 = getelementptr inbounds i32, i32* %t3208, i64 %t3210
  %t3214 = load i32, i32* %t3213
  br i1 %t3204, label %draw_ttf_draw_149, label %draw_ttf_after_150
draw_ttf_draw_149:
  %t3215 = load i32, i32* %t3189
  %t3216 = load i32, i32* %t3190
  %t3218 = getelementptr inbounds [16 x i8], [16 x i8]* %t3217, i64 0, i64 0
  %t3219 = bitcast i8* %t3218 to i32*
  store i32 %t3212, i32* %t3219
  %t3220 = getelementptr inbounds i8, i8* %t3218, i64 4
  %t3221 = bitcast i8* %t3220 to i32*
  store i32 0, i32* %t3221
  %t3222 = getelementptr inbounds i8, i8* %t3218, i64 8
  %t3223 = bitcast i8* %t3222 to i32*
  store i32 %t3214, i32* %t3223
  %t3224 = getelementptr inbounds i8, i8* %t3218, i64 12
  %t3225 = bitcast i8* %t3224 to i32*
  store i32 %t3174, i32* %t3225
  %t3227 = getelementptr inbounds [16 x i8], [16 x i8]* %t3226, i64 0, i64 0
  %t3228 = bitcast i8* %t3227 to i32*
  store i32 %t3215, i32* %t3228
  %t3229 = getelementptr inbounds i8, i8* %t3227, i64 4
  %t3230 = bitcast i8* %t3229 to i32*
  store i32 %t3216, i32* %t3230
  %t3231 = getelementptr inbounds i8, i8* %t3227, i64 8
  %t3232 = bitcast i8* %t3231 to i32*
  store i32 %t3214, i32* %t3232
  %t3233 = getelementptr inbounds i8, i8* %t3227, i64 12
  %t3234 = bitcast i8* %t3233 to i32*
  store i32 %t3174, i32* %t3234
  call i32 @SDL_RenderCopy(i8* %t3169, i8* %t3171, i8* %t3218, i8* %t3227)
  br label %draw_ttf_after_150
draw_ttf_after_150:
  %t3235 = phi i32 [ %t3214, %draw_ttf_draw_149 ], [ %t3214, %draw_ttf_glyph_148 ]
  %t3236 = load i32, i32* %t3189
  %t3237 = add i32 %t3236, %t3235
  store i32 %t3237, i32* %t3189
  %t3238 = add i64 %t3192, 1
  store i64 %t3238, i64* %t3191
  br label %draw_ttf_cond_145
draw_ttf_end_151:
  call void @star_rc_release(i8* %t3187)
  %t3240 = load i8*, i8** %t944
  %t3241 = icmp eq i8* %t3240, null
  br i1 %t3241, label %sysfont_null_handle_152, label %sysfont_handle_ok_153
sysfont_null_handle_152:
  %t3242 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.21, i64 0, i64 0
  call i32 @puts(i8* %t3242)
  call void @exit(i32 1)
  unreachable
sysfont_handle_ok_153:
  %t3243 = bitcast i8* %t3240 to i8**
  %t3244 = load i8*, i8** %t3243
  %t3245 = getelementptr inbounds i8, i8* %t3240, i64 8
  %t3246 = bitcast i8* %t3245 to i32*
  %t3247 = load i32, i32* %t3246
  %t3248 = getelementptr inbounds { i64, i8*, [17 x i8] }, { i64, i8*, [17 x i8] }* @.str.22, i64 0, i32 2, i64 0
  store i32 0, i32* %t3249
  store i32 0, i32* %t3250
  store i32 1, i32* %t3251
  store i64 0, i64* %t3252
  br label %measure_ttf_cond_154
measure_ttf_cond_154:
  %t3253 = load i64, i64* %t3252
  %t3254 = getelementptr inbounds i8, i8* %t3248, i64 %t3253
  %t3255 = load i8, i8* %t3254
  %t3256 = icmp eq i8 %t3255, 0
  br i1 %t3256, label %measure_ttf_end_158, label %measure_ttf_body_155
measure_ttf_body_155:
  %t3257 = zext i8 %t3255 to i32
  %t3258 = icmp eq i32 %t3257, 10
  br i1 %t3258, label %measure_ttf_newline_156, label %measure_ttf_advance_157
measure_ttf_newline_156:
  %t3259 = load i32, i32* %t3249
  %t3260 = load i32, i32* %t3250
  %t3261 = icmp sgt i32 %t3259, %t3260
  %t3262 = select i1 %t3261, i32 %t3259, i32 %t3260
  store i32 %t3262, i32* %t3250
  store i32 0, i32* %t3249
  %t3263 = load i32, i32* %t3251
  %t3264 = add i32 %t3263, 1
  store i32 %t3264, i32* %t3251
  %t3265 = add i64 %t3253, 1
  store i64 %t3265, i64* %t3252
  br label %measure_ttf_cond_154
measure_ttf_advance_157:
  %t3266 = sub i32 %t3257, 32
  %t3267 = icmp sge i32 %t3266, 0
  %t3268 = icmp slt i32 %t3266, 95
  %t3269 = and i1 %t3267, %t3268
  %t3270 = getelementptr inbounds i8, i8* %t3240, i64 12
  %t3271 = bitcast i8* %t3270 to i32*
  %t3272 = getelementptr inbounds i8, i8* %t3240, i64 392
  %t3273 = bitcast i8* %t3272 to i32*
  %t3274 = select i1 %t3269, i32 %t3266, i32 0
  %t3275 = sext i32 %t3274 to i64
  %t3276 = getelementptr inbounds i32, i32* %t3271, i64 %t3275
  %t3277 = load i32, i32* %t3276
  %t3278 = getelementptr inbounds i32, i32* %t3273, i64 %t3275
  %t3279 = load i32, i32* %t3278
  %t3280 = load i32, i32* %t3249
  %t3281 = add i32 %t3280, %t3279
  store i32 %t3281, i32* %t3249
  %t3282 = add i64 %t3253, 1
  store i64 %t3282, i64* %t3252
  br label %measure_ttf_cond_154
measure_ttf_end_158:
  call void @star_rc_release(i8* %t3248)
  %t3283 = load i32, i32* %t3249
  %t3284 = load i32, i32* %t3250
  %t3285 = icmp sgt i32 %t3283, %t3284
  %t3286 = select i1 %t3285, i32 %t3283, i32 %t3284
  %t3287 = load i32, i32* %t3251
  %t3288 = mul i32 %t3287, %t3247
  %t3290 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t3289, i32 0, i32 0
  store i32 %t3286, i32* %t3290
  %t3291 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t3289, i32 0, i32 1
  store i32 %t3288, i32* %t3291
  %t3292 = load { i32, i32 }, { i32, i32 }* %t3289
  store { i32, i32 } %t3292, { i32, i32 }* %t3239
  %t3293 = load i8*, i8** %t2
  %t3294 = icmp eq i8* %t3293, null
  br i1 %t3294, label %sdl_null_window_159, label %sdl_window_handle_ok_160
sdl_null_window_159:
  %t3295 = getelementptr inbounds [79 x i8], [79 x i8]* @.str.23, i64 0, i64 0
  call i32 @puts(i8* %t3295)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_160:
  %t3296 = load i8*, i8** %t944
  %t3297 = icmp eq i8* %t3296, null
  br i1 %t3297, label %sysfont_null_handle_161, label %sysfont_handle_ok_162
sysfont_null_handle_161:
  %t3298 = getelementptr inbounds [83 x i8], [83 x i8]* @.str.24, i64 0, i64 0
  call i32 @puts(i8* %t3298)
  call void @exit(i32 1)
  unreachable
sysfont_handle_ok_162:
  %t3299 = call i8* @SDL_GetRenderer(i8* %t3293)
  %t3300 = bitcast i8* %t3296 to i8**
  %t3301 = load i8*, i8** %t3300
  %t3302 = getelementptr inbounds i8, i8* %t3296, i64 8
  %t3303 = bitcast i8* %t3302 to i32*
  %t3304 = load i32, i32* %t3303
  %t3305 = load i32, i32* %t3036
  %t3306 = and i32 %t3305, 255
  %t3307 = trunc i32 %t3306 to i8
  %t3308 = lshr i32 %t3305, 8
  %t3309 = and i32 %t3308, 255
  %t3310 = trunc i32 %t3309 to i8
  %t3311 = lshr i32 %t3305, 16
  %t3312 = and i32 %t3311, 255
  %t3313 = trunc i32 %t3312 to i8
  %t3314 = lshr i32 %t3305, 24
  %t3315 = and i32 %t3314, 255
  %t3316 = trunc i32 %t3315 to i8
  call i32 @SDL_SetTextureColorMod(i8* %t3301, i8 %t3307, i8 %t3310, i8 %t3313)
  call i32 @SDL_SetTextureAlphaMod(i8* %t3301, i8 %t3316)
  %t3317 = getelementptr inbounds { i64, i8*, [17 x i8] }, { i64, i8*, [17 x i8] }* @.str.25, i64 0, i32 2, i64 0
  %t3318 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t3239, i32 0, i32 0
  %t3319 = load i32, i32* %t3318
  %t3320 = sub i32 640, %t3319
  %t3321 = icmp eq i32 2, 0
  %t3322 = icmp eq i32 %t3320, -2147483648
  %t3323 = icmp eq i32 2, -1
  %t3324 = and i1 %t3322, %t3323
  %t3325 = or i1 %t3321, %t3324
  br i1 %t3325, label %int_div_fail_163, label %int_div_ok_164
int_div_fail_163:
  %t3326 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.26, i64 0, i64 0
  call i32 @puts(i8* %t3326)
  call void @exit(i32 1)
  unreachable
int_div_ok_164:
  %t3327 = sdiv i32 %t3320, 2
  store i32 %t3327, i32* %t3328
  store i32 400, i32* %t3329
  store i64 0, i64* %t3330
  br label %draw_ttf_cond_165
draw_ttf_cond_165:
  %t3331 = load i64, i64* %t3330
  %t3332 = getelementptr inbounds i8, i8* %t3317, i64 %t3331
  %t3333 = load i8, i8* %t3332
  %t3334 = icmp eq i8 %t3333, 0
  br i1 %t3334, label %draw_ttf_end_171, label %draw_ttf_body_166
draw_ttf_body_166:
  %t3335 = zext i8 %t3333 to i32
  %t3336 = icmp eq i32 %t3335, 10
  br i1 %t3336, label %draw_ttf_newline_167, label %draw_ttf_glyph_168
draw_ttf_newline_167:
  store i32 %t3327, i32* %t3328
  %t3337 = load i32, i32* %t3329
  %t3338 = add i32 %t3337, %t3304
  store i32 %t3338, i32* %t3329
  %t3339 = add i64 %t3331, 1
  store i64 %t3339, i64* %t3330
  br label %draw_ttf_cond_165
draw_ttf_glyph_168:
  %t3340 = sub i32 %t3335, 32
  %t3341 = icmp sge i32 %t3340, 0
  %t3342 = icmp slt i32 %t3340, 95
  %t3343 = and i1 %t3341, %t3342
  %t3344 = getelementptr inbounds i8, i8* %t3296, i64 12
  %t3345 = bitcast i8* %t3344 to i32*
  %t3346 = getelementptr inbounds i8, i8* %t3296, i64 392
  %t3347 = bitcast i8* %t3346 to i32*
  %t3348 = select i1 %t3343, i32 %t3340, i32 0
  %t3349 = sext i32 %t3348 to i64
  %t3350 = getelementptr inbounds i32, i32* %t3345, i64 %t3349
  %t3351 = load i32, i32* %t3350
  %t3352 = getelementptr inbounds i32, i32* %t3347, i64 %t3349
  %t3353 = load i32, i32* %t3352
  br i1 %t3343, label %draw_ttf_draw_169, label %draw_ttf_after_170
draw_ttf_draw_169:
  %t3354 = load i32, i32* %t3328
  %t3355 = load i32, i32* %t3329
  %t3357 = getelementptr inbounds [16 x i8], [16 x i8]* %t3356, i64 0, i64 0
  %t3358 = bitcast i8* %t3357 to i32*
  store i32 %t3351, i32* %t3358
  %t3359 = getelementptr inbounds i8, i8* %t3357, i64 4
  %t3360 = bitcast i8* %t3359 to i32*
  store i32 0, i32* %t3360
  %t3361 = getelementptr inbounds i8, i8* %t3357, i64 8
  %t3362 = bitcast i8* %t3361 to i32*
  store i32 %t3353, i32* %t3362
  %t3363 = getelementptr inbounds i8, i8* %t3357, i64 12
  %t3364 = bitcast i8* %t3363 to i32*
  store i32 %t3304, i32* %t3364
  %t3366 = getelementptr inbounds [16 x i8], [16 x i8]* %t3365, i64 0, i64 0
  %t3367 = bitcast i8* %t3366 to i32*
  store i32 %t3354, i32* %t3367
  %t3368 = getelementptr inbounds i8, i8* %t3366, i64 4
  %t3369 = bitcast i8* %t3368 to i32*
  store i32 %t3355, i32* %t3369
  %t3370 = getelementptr inbounds i8, i8* %t3366, i64 8
  %t3371 = bitcast i8* %t3370 to i32*
  store i32 %t3353, i32* %t3371
  %t3372 = getelementptr inbounds i8, i8* %t3366, i64 12
  %t3373 = bitcast i8* %t3372 to i32*
  store i32 %t3304, i32* %t3373
  call i32 @SDL_RenderCopy(i8* %t3299, i8* %t3301, i8* %t3357, i8* %t3366)
  br label %draw_ttf_after_170
draw_ttf_after_170:
  %t3374 = phi i32 [ %t3353, %draw_ttf_draw_169 ], [ %t3353, %draw_ttf_glyph_168 ]
  %t3375 = load i32, i32* %t3328
  %t3376 = add i32 %t3375, %t3374
  store i32 %t3376, i32* %t3328
  %t3377 = add i64 %t3331, 1
  store i64 %t3377, i64* %t3330
  br label %draw_ttf_cond_165
draw_ttf_end_171:
  call void @star_rc_release(i8* %t3317)
  %t3378 = load i8*, i8** %t1884
  %t3379 = icmp eq i8* %t3378, null
  %t3380 = xor i1 true, %t3379
  br i1 %t3380, label %if_then_172, label %if_else_173
if_then_172:
  %t3381 = load i8*, i8** %t2
  %t3382 = icmp eq i8* %t3381, null
  br i1 %t3382, label %sdl_null_window_175, label %sdl_window_handle_ok_176
sdl_null_window_175:
  %t3383 = getelementptr inbounds [79 x i8], [79 x i8]* @.str.27, i64 0, i64 0
  call i32 @puts(i8* %t3383)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_176:
  %t3384 = load i8*, i8** %t1884
  %t3385 = icmp eq i8* %t3384, null
  br i1 %t3385, label %sysfont_null_handle_177, label %sysfont_handle_ok_178
sysfont_null_handle_177:
  %t3386 = getelementptr inbounds [83 x i8], [83 x i8]* @.str.28, i64 0, i64 0
  call i32 @puts(i8* %t3386)
  call void @exit(i32 1)
  unreachable
sysfont_handle_ok_178:
  %t3387 = call i8* @SDL_GetRenderer(i8* %t3381)
  %t3388 = bitcast i8* %t3384 to i8**
  %t3389 = load i8*, i8** %t3388
  %t3390 = getelementptr inbounds i8, i8* %t3384, i64 8
  %t3391 = bitcast i8* %t3390 to i32*
  %t3392 = load i32, i32* %t3391
  %t3393 = load i32, i32* %t3036
  %t3394 = and i32 %t3393, 255
  %t3395 = trunc i32 %t3394 to i8
  %t3396 = lshr i32 %t3393, 8
  %t3397 = and i32 %t3396, 255
  %t3398 = trunc i32 %t3397 to i8
  %t3399 = lshr i32 %t3393, 16
  %t3400 = and i32 %t3399, 255
  %t3401 = trunc i32 %t3400 to i8
  %t3402 = lshr i32 %t3393, 24
  %t3403 = and i32 %t3402, 255
  %t3404 = trunc i32 %t3403 to i8
  call i32 @SDL_SetTextureColorMod(i8* %t3389, i8 %t3395, i8 %t3398, i8 %t3401)
  call i32 @SDL_SetTextureAlphaMod(i8* %t3389, i8 %t3404)
  %t3405 = getelementptr inbounds { i64, i8*, [32 x i8] }, { i64, i8*, [32 x i8] }* @.str.29, i64 0, i32 2, i64 0
  store i32 24, i32* %t3406
  store i32 130, i32* %t3407
  store i64 0, i64* %t3408
  br label %draw_ttf_cond_179
draw_ttf_cond_179:
  %t3409 = load i64, i64* %t3408
  %t3410 = getelementptr inbounds i8, i8* %t3405, i64 %t3409
  %t3411 = load i8, i8* %t3410
  %t3412 = icmp eq i8 %t3411, 0
  br i1 %t3412, label %draw_ttf_end_185, label %draw_ttf_body_180
draw_ttf_body_180:
  %t3413 = zext i8 %t3411 to i32
  %t3414 = icmp eq i32 %t3413, 10
  br i1 %t3414, label %draw_ttf_newline_181, label %draw_ttf_glyph_182
draw_ttf_newline_181:
  store i32 24, i32* %t3406
  %t3415 = load i32, i32* %t3407
  %t3416 = add i32 %t3415, %t3392
  store i32 %t3416, i32* %t3407
  %t3417 = add i64 %t3409, 1
  store i64 %t3417, i64* %t3408
  br label %draw_ttf_cond_179
draw_ttf_glyph_182:
  %t3418 = sub i32 %t3413, 32
  %t3419 = icmp sge i32 %t3418, 0
  %t3420 = icmp slt i32 %t3418, 95
  %t3421 = and i1 %t3419, %t3420
  %t3422 = getelementptr inbounds i8, i8* %t3384, i64 12
  %t3423 = bitcast i8* %t3422 to i32*
  %t3424 = getelementptr inbounds i8, i8* %t3384, i64 392
  %t3425 = bitcast i8* %t3424 to i32*
  %t3426 = select i1 %t3421, i32 %t3418, i32 0
  %t3427 = sext i32 %t3426 to i64
  %t3428 = getelementptr inbounds i32, i32* %t3423, i64 %t3427
  %t3429 = load i32, i32* %t3428
  %t3430 = getelementptr inbounds i32, i32* %t3425, i64 %t3427
  %t3431 = load i32, i32* %t3430
  br i1 %t3421, label %draw_ttf_draw_183, label %draw_ttf_after_184
draw_ttf_draw_183:
  %t3432 = load i32, i32* %t3406
  %t3433 = load i32, i32* %t3407
  %t3435 = getelementptr inbounds [16 x i8], [16 x i8]* %t3434, i64 0, i64 0
  %t3436 = bitcast i8* %t3435 to i32*
  store i32 %t3429, i32* %t3436
  %t3437 = getelementptr inbounds i8, i8* %t3435, i64 4
  %t3438 = bitcast i8* %t3437 to i32*
  store i32 0, i32* %t3438
  %t3439 = getelementptr inbounds i8, i8* %t3435, i64 8
  %t3440 = bitcast i8* %t3439 to i32*
  store i32 %t3431, i32* %t3440
  %t3441 = getelementptr inbounds i8, i8* %t3435, i64 12
  %t3442 = bitcast i8* %t3441 to i32*
  store i32 %t3392, i32* %t3442
  %t3444 = getelementptr inbounds [16 x i8], [16 x i8]* %t3443, i64 0, i64 0
  %t3445 = bitcast i8* %t3444 to i32*
  store i32 %t3432, i32* %t3445
  %t3446 = getelementptr inbounds i8, i8* %t3444, i64 4
  %t3447 = bitcast i8* %t3446 to i32*
  store i32 %t3433, i32* %t3447
  %t3448 = getelementptr inbounds i8, i8* %t3444, i64 8
  %t3449 = bitcast i8* %t3448 to i32*
  store i32 %t3431, i32* %t3449
  %t3450 = getelementptr inbounds i8, i8* %t3444, i64 12
  %t3451 = bitcast i8* %t3450 to i32*
  store i32 %t3392, i32* %t3451
  call i32 @SDL_RenderCopy(i8* %t3387, i8* %t3389, i8* %t3435, i8* %t3444)
  br label %draw_ttf_after_184
draw_ttf_after_184:
  %t3452 = phi i32 [ %t3431, %draw_ttf_draw_183 ], [ %t3431, %draw_ttf_glyph_182 ]
  %t3453 = load i32, i32* %t3406
  %t3454 = add i32 %t3453, %t3452
  store i32 %t3454, i32* %t3406
  %t3455 = add i64 %t3409, 1
  store i64 %t3455, i64* %t3408
  br label %draw_ttf_cond_179
draw_ttf_end_185:
  call void @star_rc_release(i8* %t3405)
  br label %if_end_174
if_else_173:
  br label %if_end_174
if_end_174:
  %t3456 = load i8*, i8** %t2
  %t3457 = icmp eq i8* %t3456, null
  br i1 %t3457, label %sdl_null_window_186, label %sdl_window_handle_ok_187
sdl_null_window_186:
  %t3458 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.30, i64 0, i64 0
  call i32 @puts(i8* %t3458)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_187:
  %t3459 = call i8* @SDL_GetRenderer(i8* %t3456)
  call void @SDL_RenderPresent(i8* %t3459)
  %t3460 = icmp slt i32 16, 0
  %t3461 = select i1 %t3460, i32 0, i32 16
  call void @SDL_Delay(i32 %t3461)
  %t3462 = load i8*, i8** %t3161
  call void @star_rc_release(i8* %t3462)
  br label %while_cond_110
while_else_112:
  br label %while_end_113
while_end_113:
  %t3463 = load i8*, i8** %t1884
  %t3464 = icmp eq i8* %t3463, null
  %t3465 = xor i1 true, %t3464
  br i1 %t3465, label %if_then_188, label %if_else_189
if_then_188:
  %t3466 = load i8*, i8** %t1884
  %t3467 = icmp eq i8* %t3466, null
  br i1 %t3467, label %sysfont_null_handle_191, label %sysfont_handle_ok_192
sysfont_null_handle_191:
  %t3468 = getelementptr inbounds [83 x i8], [83 x i8]* @.str.31, i64 0, i64 0
  call i32 @puts(i8* %t3468)
  call void @exit(i32 1)
  unreachable
sysfont_handle_ok_192:
  %t3469 = bitcast i8* %t3466 to i8**
  %t3470 = load i8*, i8** %t3469
  call void @SDL_DestroyTexture(i8* %t3470)
  call void @free(i8* %t3466)
  store i8* null, i8** %t1884
  br label %if_end_190
if_else_189:
  br label %if_end_190
if_end_190:
  %t3471 = load i8*, i8** %t944
  %t3472 = icmp eq i8* %t3471, null
  br i1 %t3472, label %sysfont_null_handle_193, label %sysfont_handle_ok_194
sysfont_null_handle_193:
  %t3473 = getelementptr inbounds [83 x i8], [83 x i8]* @.str.32, i64 0, i64 0
  call i32 @puts(i8* %t3473)
  call void @exit(i32 1)
  unreachable
sysfont_handle_ok_194:
  %t3474 = bitcast i8* %t3471 to i8**
  %t3475 = load i8*, i8** %t3474
  call void @SDL_DestroyTexture(i8* %t3475)
  call void @free(i8* %t3471)
  store i8* null, i8** %t944
  %t3476 = load i8*, i8** %t15
  %t3477 = icmp eq i8* %t3476, null
  br i1 %t3477, label %sysfont_null_handle_195, label %sysfont_handle_ok_196
sysfont_null_handle_195:
  %t3478 = getelementptr inbounds [83 x i8], [83 x i8]* @.str.33, i64 0, i64 0
  call i32 @puts(i8* %t3478)
  call void @exit(i32 1)
  unreachable
sysfont_handle_ok_196:
  %t3479 = bitcast i8* %t3476 to i8**
  %t3480 = load i8*, i8** %t3479
  call void @SDL_DestroyTexture(i8* %t3480)
  call void @free(i8* %t3476)
  store i8* null, i8** %t15
  %t3481 = load i8*, i8** %t2
  %t3482 = icmp eq i8* %t3481, null
  br i1 %t3482, label %sdl_null_window_197, label %sdl_window_handle_ok_198
sdl_null_window_197:
  %t3483 = getelementptr inbounds [80 x i8], [80 x i8]* @.str.34, i64 0, i64 0
  call i32 @puts(i8* %t3483)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_198:
  %t3484 = call i8* @SDL_GetRenderer(i8* %t3481)
  call void @SDL_DestroyRenderer(i8* %t3484)
  call void @SDL_DestroyWindow(i8* %t3481)
  store i8* null, i8** %t2
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [24 x i8] } { i64 -1, i8* null, [24 x i8] c"Star: system_fonts.star\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [21 x i8] } { i64 -1, i8* null, [21 x i8] c"window_create failed\00" }
@.str.2 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.3 = private unnamed_addr constant [82 x i8] c"star runtime error: font_load_system(..) called with a null/closed window handle\0A\00"
@.str.4 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"Segoe UI\00" }
@.str.5 = private unnamed_addr constant [82 x i8] c"star runtime error: font_load_system(..) called with a null/closed window handle\0A\00"
@.str.6 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"Segoe UI\00" }
@.str.7 = private unnamed_addr constant { i64, i8*, [24 x i8] } { i64 -1, i8* null, [24 x i8] c"font_load_system failed\00" }
@.str.8 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.9 = private unnamed_addr constant [80 x i8] c"star runtime error: window_destroy(..) called with a null/closed window handle\0A\00"
@.str.10 = private unnamed_addr constant [79 x i8] c"star runtime error: font_load_ttf(..) called with a null/closed window handle\0A\00"
@.str.11 = private unnamed_addr constant { i64, i8*, [27 x i8] } { i64 -1, i8* null, [27 x i8] c"C:\\Windows\\Fonts\\arial.ttf\00" }
@.str.12 = private unnamed_addr constant [3 x i8] c"rb\00"
@.str.13 = private unnamed_addr constant [85 x i8] c"star runtime error: window_should_close(..) called with a null/closed window handle\0A\00"
@.str.14 = private unnamed_addr constant [78 x i8] c"star runtime error: clear_screen(..) called with a null/closed window handle\0A\00"
@.str.15 = private unnamed_addr constant [79 x i8] c"star runtime error: draw_text_ttf(..) called with a null/closed window handle\0A\00"
@.str.16 = private unnamed_addr constant [83 x i8] c"star runtime error: draw_text_ttf(..) called with a null/freed system-font handle\0A\00"
@.str.17 = private unnamed_addr constant { i64, i8*, [12 x i8] } { i64 -1, i8* null, [12 x i8] c"Star Engine\00" }
@.str.18 = private unnamed_addr constant { i64, i8*, [82 x i8] } { i64 -1, i8* null, [82 x i8] c"Proportional text, real lowercase glyphs,\0Aantialiased edges -- straight from GDI.\00" }
@.str.19 = private unnamed_addr constant [79 x i8] c"star runtime error: draw_text_ttf(..) called with a null/closed window handle\0A\00"
@.str.20 = private unnamed_addr constant [83 x i8] c"star runtime error: draw_text_ttf(..) called with a null/freed system-font handle\0A\00"
@.str.21 = private unnamed_addr constant [86 x i8] c"star runtime error: measure_text_ttf(..) called with a null/freed system-font handle\0A\00"
@.str.22 = private unnamed_addr constant { i64, i8*, [17 x i8] } { i64 -1, i8* null, [17 x i8] c"Centered caption\00" }
@.str.23 = private unnamed_addr constant [79 x i8] c"star runtime error: draw_text_ttf(..) called with a null/closed window handle\0A\00"
@.str.24 = private unnamed_addr constant [83 x i8] c"star runtime error: draw_text_ttf(..) called with a null/freed system-font handle\0A\00"
@.str.25 = private unnamed_addr constant { i64, i8*, [17 x i8] } { i64 -1, i8* null, [17 x i8] c"Centered caption\00" }
@.str.26 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.27 = private unnamed_addr constant [79 x i8] c"star runtime error: draw_text_ttf(..) called with a null/closed window handle\0A\00"
@.str.28 = private unnamed_addr constant [83 x i8] c"star runtime error: draw_text_ttf(..) called with a null/freed system-font handle\0A\00"
@.str.29 = private unnamed_addr constant { i64, i8*, [32 x i8] } { i64 -1, i8* null, [32 x i8] c"Loaded from a bundled .ttf file\00" }
@.str.30 = private unnamed_addr constant [73 x i8] c"star runtime error: present(..) called with a null/closed window handle\0A\00"
@.str.31 = private unnamed_addr constant [83 x i8] c"star runtime error: font_ttf_free(..) called with a null/freed system-font handle\0A\00"
@.str.32 = private unnamed_addr constant [83 x i8] c"star runtime error: font_ttf_free(..) called with a null/freed system-font handle\0A\00"
@.str.33 = private unnamed_addr constant [83 x i8] c"star runtime error: font_ttf_free(..) called with a null/freed system-font handle\0A\00"
@.str.34 = private unnamed_addr constant [80 x i8] c"star runtime error: window_destroy(..) called with a null/closed window handle\0A\00"
