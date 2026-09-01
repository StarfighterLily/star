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
declare i32 @ioctlsocket(i8*, i32, i32*)
declare i32 @WSAGetLastError()
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
declare i32 @GetOpenFileNameA(i8*)
declare i8* @SDL_CreateTexture(i8*, i32, i32, i32, i32)
declare i32 @SDL_UpdateTexture(i8*, i8*, i8*, i32)
declare i32 @SDL_SetTextureBlendMode(i8*, i32)
declare i32 @SDL_SetTextureColorMod(i8*, i8, i8, i8)
declare i32 @SDL_SetTextureAlphaMod(i8*, i8)
declare i32 @SDL_RenderCopy(i8*, i8*, i8*, i8*)
declare void @SDL_DestroyTexture(i8*)
declare i8* @CreateThread(i8*, i64, i8*, i8*, i32, i32*)
declare i32 @WaitForSingleObject(i8*, i32)
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

%keyboard__Keyboard = type { [64 x i8], i32, i32, i32, i8, i8, i32, [256 x i32], [256 x i1], [256 x i32], [256 x i32] }
%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define i1 @keyboard__Keyboard__irq_enabled(%keyboard__Keyboard* %self) {
entry:
  %t0 = alloca %keyboard__Keyboard*
  store %keyboard__Keyboard* %self, %keyboard__Keyboard** %t0
  %t1 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t2 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t1, i32 0, i32 5
  %t3 = load i8, i8* %t2
  %t4 = and i32 0, 7
  %t5 = trunc i32 %t4 to i8
  %t6 = shl i8 1, %t5
  %t7 = and i8 %t3, %t6
  %t8 = icmp ne i8 %t7, 0
  ret i1 %t8
}

define void @keyboard__Keyboard__refresh_status(%keyboard__Keyboard* %self) {
entry:
  %t0 = alloca %keyboard__Keyboard*
  store %keyboard__Keyboard* %self, %keyboard__Keyboard** %t0
  %t1 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t2 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t1, i32 0, i32 3
  %t3 = load i32, i32* %t2
  %t4 = icmp sgt i32 %t3, 0
  br i1 %t4, label %if_then_0, label %if_else_1
if_then_0:
  %t5 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t6 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t5, i32 0, i32 4
  %t7 = load i8, i8* %t6
  %t8 = and i32 0, 7
  %t9 = trunc i32 %t8 to i8
  %t10 = shl i8 1, %t9
  %t11 = or i8 %t7, %t10
  %t12 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t13 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t12, i32 0, i32 4
  store i8 %t11, i8* %t13
  br label %if_end_2
if_else_1:
  %t14 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t15 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t14, i32 0, i32 4
  %t16 = load i8, i8* %t15
  %t17 = and i32 0, 7
  %t18 = trunc i32 %t17 to i8
  %t19 = shl i8 1, %t18
  %t21 = xor i8 %t19, -1
  %t20 = and i8 %t16, %t21
  %t22 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t23 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t22, i32 0, i32 4
  store i8 %t20, i8* %t23
  br label %if_end_2
if_end_2:
  %t24 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t25 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t24, i32 0, i32 3
  %t26 = load i32, i32* %t25
  %t27 = icmp sge i32 %t26, 64
  br i1 %t27, label %if_then_3, label %if_else_4
if_then_3:
  %t28 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t29 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t28, i32 0, i32 4
  %t30 = load i8, i8* %t29
  %t31 = and i32 1, 7
  %t32 = trunc i32 %t31 to i8
  %t33 = shl i8 1, %t32
  %t34 = or i8 %t30, %t33
  %t35 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t36 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t35, i32 0, i32 4
  store i8 %t34, i8* %t36
  br label %if_end_5
if_else_4:
  %t37 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t38 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t37, i32 0, i32 4
  %t39 = load i8, i8* %t38
  %t40 = and i32 1, 7
  %t41 = trunc i32 %t40 to i8
  %t42 = shl i8 1, %t41
  %t44 = xor i8 %t42, -1
  %t43 = and i8 %t39, %t44
  %t45 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t46 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t45, i32 0, i32 4
  store i8 %t43, i8* %t46
  br label %if_end_5
if_end_5:
  %t47 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t48 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t47, i32 0, i32 3
  %t49 = load i32, i32* %t48
  %t50 = icmp sgt i32 %t49, 0
  br i1 %t50, label %logic_rhs_6, label %logic_short_7
logic_rhs_6:
  %t51 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t52 = call i1 @keyboard__Keyboard__irq_enabled(%keyboard__Keyboard* %t51)
  br label %logic_end_8
logic_short_7:
  br label %logic_end_8
logic_end_8:
  %t53 = phi i1 [ %t52, %logic_rhs_6 ], [ false, %logic_short_7 ]
  br i1 %t53, label %if_then_9, label %if_else_10
if_then_9:
  %t54 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t55 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t54, i32 0, i32 4
  %t56 = load i8, i8* %t55
  %t57 = and i32 7, 7
  %t58 = trunc i32 %t57 to i8
  %t59 = shl i8 1, %t58
  %t60 = or i8 %t56, %t59
  %t61 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t62 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t61, i32 0, i32 4
  store i8 %t60, i8* %t62
  br label %if_end_11
if_else_10:
  %t63 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t64 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t63, i32 0, i32 4
  %t65 = load i8, i8* %t64
  %t66 = and i32 7, 7
  %t67 = trunc i32 %t66 to i8
  %t68 = shl i8 1, %t67
  %t70 = xor i8 %t68, -1
  %t69 = and i8 %t65, %t70
  %t71 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t72 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t71, i32 0, i32 4
  store i8 %t69, i8* %t72
  br label %if_end_11
if_end_11:
  ret void
}

define void @keyboard__Keyboard__push_key(%keyboard__Keyboard* %self, i8 %code) {
entry:
  %t0 = alloca %keyboard__Keyboard*
  %t1 = alloca i8
  store %keyboard__Keyboard* %self, %keyboard__Keyboard** %t0
  store i8 %code, i8* %t1
  %t2 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t3 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t2, i32 0, i32 3
  %t4 = load i32, i32* %t3
  %t5 = icmp slt i32 %t4, 64
  br i1 %t5, label %if_then_12, label %if_else_13
if_then_12:
  %t6 = load i8, i8* %t1
  %t7 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t8 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t7, i32 0, i32 0
  %t9 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t10 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t9, i32 0, i32 2
  %t11 = load i32, i32* %t10
  %t12 = sext i32 %t11 to i64
  %t13 = icmp ult i64 %t12, 64
  br i1 %t13, label %arr_set_do_15, label %arr_set_oob_16
arr_set_do_15:
  %t14 = getelementptr inbounds [64 x i8], [64 x i8]* %t8, i32 0, i64 %t12
  store i8 %t6, i8* %t14
  br label %arr_set_end_17
arr_set_oob_16:
  br label %arr_set_end_17
arr_set_end_17:
  %t15 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t16 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t15, i32 0, i32 2
  %t17 = load i32, i32* %t16
  %t18 = add i32 %t17, 1
  %t19 = icmp eq i32 64, 0
  %t20 = icmp eq i32 %t18, -2147483648
  %t21 = icmp eq i32 64, -1
  %t22 = and i1 %t20, %t21
  %t23 = or i1 %t19, %t22
  br i1 %t23, label %int_div_fail_18, label %int_div_ok_19
int_div_fail_18:
  %t24 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t24)
  call void @exit(i32 1)
  unreachable
int_div_ok_19:
  %t25 = srem i32 %t18, 64
  %t26 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t27 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t26, i32 0, i32 2
  store i32 %t25, i32* %t27
  %t28 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t29 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t28, i32 0, i32 3
  %t30 = load i32, i32* %t29
  %t31 = add i32 %t30, 1
  %t32 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t33 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t32, i32 0, i32 3
  store i32 %t31, i32* %t33
  br label %if_end_14
if_else_13:
  br label %if_end_14
if_end_14:
  %t34 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  call void @keyboard__Keyboard__refresh_status(%keyboard__Keyboard* %t34)
  ret void
}

define { i8, i1 } @keyboard__Keyboard__pop_key(%keyboard__Keyboard* %self) {
entry:
  %t0 = alloca %keyboard__Keyboard*
  %t5 = alloca { i8, i1 }
  %t10 = alloca i8
  %t19 = alloca i8
  %t43 = alloca { i8, i1 }
  store %keyboard__Keyboard* %self, %keyboard__Keyboard** %t0
  %t1 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t2 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t1, i32 0, i32 3
  %t3 = load i32, i32* %t2
  %t4 = icmp sle i32 %t3, 0
  br i1 %t4, label %if_then_20, label %if_else_21
if_then_20:
  %t6 = trunc i32 0 to i8
  %t7 = getelementptr inbounds { i8, i1 }, { i8, i1 }* %t5, i32 0, i32 0
  store i8 %t6, i8* %t7
  %t8 = getelementptr inbounds { i8, i1 }, { i8, i1 }* %t5, i32 0, i32 1
  store i1 false, i1* %t8
  %t9 = load { i8, i1 }, { i8, i1 }* %t5
  br label %if_end_22
if_else_21:
  %t11 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t12 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t11, i32 0, i32 0
  %t13 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t14 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t13, i32 0, i32 1
  %t15 = load i32, i32* %t14
  %t16 = sext i32 %t15 to i64
  %t17 = icmp ult i64 %t16, 64
  br i1 %t17, label %arr_rplace_ok_23, label %arr_rplace_oob_24
arr_rplace_ok_23:
  %t18 = getelementptr inbounds [64 x i8], [64 x i8]* %t12, i32 0, i64 %t16
  br label %arr_rplace_end_25
arr_rplace_oob_24:
  store i8 0, i8* %t19
  br label %arr_rplace_end_25
arr_rplace_end_25:
  %t20 = phi i8* [ %t18, %arr_rplace_ok_23 ], [ %t19, %arr_rplace_oob_24 ]
  %t21 = load i8, i8* %t20
  store i8 %t21, i8* %t10
  %t22 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t23 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t22, i32 0, i32 1
  %t24 = load i32, i32* %t23
  %t25 = add i32 %t24, 1
  %t26 = icmp eq i32 64, 0
  %t27 = icmp eq i32 %t25, -2147483648
  %t28 = icmp eq i32 64, -1
  %t29 = and i1 %t27, %t28
  %t30 = or i1 %t26, %t29
  br i1 %t30, label %int_div_fail_26, label %int_div_ok_27
int_div_fail_26:
  %t31 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t31)
  call void @exit(i32 1)
  unreachable
int_div_ok_27:
  %t32 = srem i32 %t25, 64
  %t33 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t34 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t33, i32 0, i32 1
  store i32 %t32, i32* %t34
  %t35 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t36 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t35, i32 0, i32 3
  %t37 = load i32, i32* %t36
  %t38 = sub i32 %t37, 1
  %t39 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t40 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t39, i32 0, i32 3
  store i32 %t38, i32* %t40
  %t41 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  call void @keyboard__Keyboard__refresh_status(%keyboard__Keyboard* %t41)
  %t44 = load i8, i8* %t10
  %t45 = getelementptr inbounds { i8, i1 }, { i8, i1 }* %t43, i32 0, i32 0
  store i8 %t44, i8* %t45
  %t46 = getelementptr inbounds { i8, i1 }, { i8, i1 }* %t43, i32 0, i32 1
  store i1 true, i1* %t46
  %t47 = load { i8, i1 }, { i8, i1 }* %t43
  br label %if_end_22
if_end_22:
  %t48 = phi { i8, i1 } [ %t9, %if_then_20 ], [ %t47, %int_div_ok_27 ]
  ret { i8, i1 } %t48
}

define i8 @keyboard__Keyboard__keystat(%keyboard__Keyboard* %self) {
entry:
  %t0 = alloca %keyboard__Keyboard*
  store %keyboard__Keyboard* %self, %keyboard__Keyboard** %t0
  %t1 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t2 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t1, i32 0, i32 4
  %t3 = load i8, i8* %t2
  ret i8 %t3
}

define i8 @keyboard__Keyboard__keycount(%keyboard__Keyboard* %self) {
entry:
  %t0 = alloca %keyboard__Keyboard*
  store %keyboard__Keyboard* %self, %keyboard__Keyboard** %t0
  %t1 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t2 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t1, i32 0, i32 3
  %t3 = load i32, i32* %t2
  %t4 = trunc i32 %t3 to i8
  ret i8 %t4
}

define void @keyboard__Keyboard__keyclear(%keyboard__Keyboard* %self) {
entry:
  %t0 = alloca %keyboard__Keyboard*
  store %keyboard__Keyboard* %self, %keyboard__Keyboard** %t0
  %t1 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t2 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t1, i32 0, i32 1
  store i32 0, i32* %t2
  %t3 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t4 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t3, i32 0, i32 2
  store i32 0, i32* %t4
  %t5 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t6 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t5, i32 0, i32 3
  store i32 0, i32* %t6
  %t7 = trunc i32 0 to i8
  %t8 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t9 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t8, i32 0, i32 4
  store i8 %t7, i8* %t9
  ret void
}

define void @keyboard__Keyboard__keyctrl(%keyboard__Keyboard* %self, i8 %val) {
entry:
  %t0 = alloca %keyboard__Keyboard*
  %t1 = alloca i8
  store %keyboard__Keyboard* %self, %keyboard__Keyboard** %t0
  store i8 %val, i8* %t1
  %t2 = load i8, i8* %t1
  %t3 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t4 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t3, i32 0, i32 5
  store i8 %t2, i8* %t4
  %t5 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  call void @keyboard__Keyboard__refresh_status(%keyboard__Keyboard* %t5)
  ret void
}

define i1 @keyboard__Keyboard__should_debounce_key(%keyboard__Keyboard* %self, i8 %code) {
entry:
  %t0 = alloca %keyboard__Keyboard*
  %t1 = alloca i8
  %t6 = alloca i32
  %t8 = alloca i32
  %t16 = alloca i32
  %t19 = alloca i32
  store %keyboard__Keyboard* %self, %keyboard__Keyboard** %t0
  store i8 %code, i8* %t1
  %t2 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t3 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t2, i32 0, i32 6
  %t4 = load i32, i32* %t3
  %t5 = icmp sle i32 %t4, 0
  br i1 %t5, label %if_then_28, label %if_else_29
if_then_28:
  ret i1 false
if_else_29:
  br label %if_end_30
if_end_30:
  %t7 = call i32 @SDL_GetTicks()
  store i32 %t7, i32* %t6
  %t9 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t10 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t9, i32 0, i32 7
  %t11 = load i8, i8* %t1
  %t12 = zext i8 %t11 to i32
  %t13 = sext i32 %t12 to i64
  %t14 = icmp ult i64 %t13, 256
  br i1 %t14, label %arr_rplace_ok_31, label %arr_rplace_oob_32
arr_rplace_ok_31:
  %t15 = getelementptr inbounds [256 x i32], [256 x i32]* %t10, i32 0, i64 %t13
  br label %arr_rplace_end_33
arr_rplace_oob_32:
  store i32 0, i32* %t16
  br label %arr_rplace_end_33
arr_rplace_end_33:
  %t17 = phi i32* [ %t15, %arr_rplace_ok_31 ], [ %t16, %arr_rplace_oob_32 ]
  %t18 = load i32, i32* %t17
  store i32 %t18, i32* %t8
  %t20 = load i32, i32* %t6
  %t21 = load i32, i32* %t8
  %t22 = sub i32 %t20, %t21
  store i32 %t22, i32* %t19
  %t23 = load i32, i32* %t8
  %t24 = icmp sge i32 %t23, 0
  br i1 %t24, label %logic_rhs_34, label %logic_short_35
logic_rhs_34:
  %t25 = load i32, i32* %t19
  %t26 = icmp sge i32 %t25, 0
  br label %logic_end_36
logic_short_35:
  br label %logic_end_36
logic_end_36:
  %t27 = phi i1 [ %t26, %logic_rhs_34 ], [ false, %logic_short_35 ]
  br i1 %t27, label %logic_rhs_37, label %logic_short_38
logic_rhs_37:
  %t28 = load i32, i32* %t19
  %t29 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t30 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t29, i32 0, i32 6
  %t31 = load i32, i32* %t30
  %t32 = icmp slt i32 %t28, %t31
  br label %logic_end_39
logic_short_38:
  br label %logic_end_39
logic_end_39:
  %t33 = phi i1 [ %t32, %logic_rhs_37 ], [ false, %logic_short_38 ]
  br i1 %t33, label %if_then_40, label %if_else_41
if_then_40:
  ret i1 true
if_else_41:
  br label %if_end_42
if_end_42:
  %t34 = load i32, i32* %t6
  %t35 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t36 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t35, i32 0, i32 7
  %t37 = load i8, i8* %t1
  %t38 = zext i8 %t37 to i32
  %t39 = sext i32 %t38 to i64
  %t40 = icmp ult i64 %t39, 256
  br i1 %t40, label %arr_set_do_43, label %arr_set_oob_44
arr_set_do_43:
  %t41 = getelementptr inbounds [256 x i32], [256 x i32]* %t36, i32 0, i64 %t39
  store i32 %t34, i32* %t41
  br label %arr_set_end_45
arr_set_oob_44:
  br label %arr_set_end_45
arr_set_end_45:
  ret i1 false
}

define void @keyboard__Keyboard__press_key(%keyboard__Keyboard* %self, i8 %code) {
entry:
  %t0 = alloca %keyboard__Keyboard*
  %t1 = alloca i8
  store %keyboard__Keyboard* %self, %keyboard__Keyboard** %t0
  store i8 %code, i8* %t1
  %t2 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t3 = load i8, i8* %t1
  %t4 = call i1 @keyboard__Keyboard__should_debounce_key(%keyboard__Keyboard* %t2, i8 %t3)
  br i1 %t4, label %if_then_46, label %if_else_47
if_then_46:
  ret void
if_else_47:
  br label %if_end_48
if_end_48:
  %t5 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t6 = load i8, i8* %t1
  call void @keyboard__Keyboard__push_key(%keyboard__Keyboard* %t5, i8 %t6)
  ret void
}

define void @keyboard__Keyboard__set_debounce_ms(%keyboard__Keyboard* %self, i32 %ms) {
entry:
  %t0 = alloca %keyboard__Keyboard*
  %t1 = alloca i32
  store %keyboard__Keyboard* %self, %keyboard__Keyboard** %t0
  store i32 %ms, i32* %t1
  %t2 = load i32, i32* %t1
  %t3 = icmp slt i32 %t2, 0
  br i1 %t3, label %if_then_49, label %if_else_50
if_then_49:
  %t4 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t5 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t4, i32 0, i32 6
  store i32 0, i32* %t5
  br label %if_end_51
if_else_50:
  %t6 = load i32, i32* %t1
  %t7 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t8 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t7, i32 0, i32 6
  store i32 %t6, i32* %t8
  br label %if_end_51
if_end_51:
  ret void
}

define void @keyboard__Keyboard__key_hold_begin(%keyboard__Keyboard* %self, i8 %code) {
entry:
  %t0 = alloca %keyboard__Keyboard*
  %t1 = alloca i8
  %t2 = alloca i32
  store %keyboard__Keyboard* %self, %keyboard__Keyboard** %t0
  store i8 %code, i8* %t1
  %t3 = call i32 @SDL_GetTicks()
  store i32 %t3, i32* %t2
  %t4 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t5 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t4, i32 0, i32 8
  %t6 = load i8, i8* %t1
  %t7 = zext i8 %t6 to i32
  %t8 = sext i32 %t7 to i64
  %t9 = icmp ult i64 %t8, 256
  br i1 %t9, label %arr_set_do_52, label %arr_set_oob_53
arr_set_do_52:
  %t10 = getelementptr inbounds [256 x i1], [256 x i1]* %t5, i32 0, i64 %t8
  store i1 true, i1* %t10
  br label %arr_set_end_54
arr_set_oob_53:
  br label %arr_set_end_54
arr_set_end_54:
  %t11 = load i32, i32* %t2
  %t12 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t13 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t12, i32 0, i32 9
  %t14 = load i8, i8* %t1
  %t15 = zext i8 %t14 to i32
  %t16 = sext i32 %t15 to i64
  %t17 = icmp ult i64 %t16, 256
  br i1 %t17, label %arr_set_do_55, label %arr_set_oob_56
arr_set_do_55:
  %t18 = getelementptr inbounds [256 x i32], [256 x i32]* %t13, i32 0, i64 %t16
  store i32 %t11, i32* %t18
  br label %arr_set_end_57
arr_set_oob_56:
  br label %arr_set_end_57
arr_set_end_57:
  %t19 = load i32, i32* %t2
  %t20 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t21 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t20, i32 0, i32 10
  %t22 = load i8, i8* %t1
  %t23 = zext i8 %t22 to i32
  %t24 = sext i32 %t23 to i64
  %t25 = icmp ult i64 %t24, 256
  br i1 %t25, label %arr_set_do_58, label %arr_set_oob_59
arr_set_do_58:
  %t26 = getelementptr inbounds [256 x i32], [256 x i32]* %t21, i32 0, i64 %t24
  store i32 %t19, i32* %t26
  br label %arr_set_end_60
arr_set_oob_59:
  br label %arr_set_end_60
arr_set_end_60:
  ret void
}

define i1 @keyboard__Keyboard__key_hold_tick(%keyboard__Keyboard* %self, i8 %code) {
entry:
  %t0 = alloca %keyboard__Keyboard*
  %t1 = alloca i8
  %t2 = alloca i32
  %t11 = alloca i1
  %t15 = alloca i32
  %t24 = alloca i32
  %t36 = alloca i32
  store %keyboard__Keyboard* %self, %keyboard__Keyboard** %t0
  store i8 %code, i8* %t1
  %t3 = load i8, i8* %t1
  %t4 = zext i8 %t3 to i32
  store i32 %t4, i32* %t2
  %t5 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t6 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t5, i32 0, i32 8
  %t7 = load i32, i32* %t2
  %t8 = sext i32 %t7 to i64
  %t9 = icmp ult i64 %t8, 256
  br i1 %t9, label %arr_rplace_ok_61, label %arr_rplace_oob_62
arr_rplace_ok_61:
  %t10 = getelementptr inbounds [256 x i1], [256 x i1]* %t6, i32 0, i64 %t8
  br label %arr_rplace_end_63
arr_rplace_oob_62:
  store i1 false, i1* %t11
  br label %arr_rplace_end_63
arr_rplace_end_63:
  %t12 = phi i1* [ %t10, %arr_rplace_ok_61 ], [ %t11, %arr_rplace_oob_62 ]
  %t13 = load i1, i1* %t12
  %t14 = xor i1 true, %t13
  br i1 %t14, label %if_then_64, label %if_else_65
if_then_64:
  ret i1 false
if_else_65:
  br label %if_end_66
if_end_66:
  %t16 = call i32 @SDL_GetTicks()
  store i32 %t16, i32* %t15
  %t17 = load i32, i32* %t15
  %t18 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t19 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t18, i32 0, i32 9
  %t20 = load i32, i32* %t2
  %t21 = sext i32 %t20 to i64
  %t22 = icmp ult i64 %t21, 256
  br i1 %t22, label %arr_rplace_ok_67, label %arr_rplace_oob_68
arr_rplace_ok_67:
  %t23 = getelementptr inbounds [256 x i32], [256 x i32]* %t19, i32 0, i64 %t21
  br label %arr_rplace_end_69
arr_rplace_oob_68:
  store i32 0, i32* %t24
  br label %arr_rplace_end_69
arr_rplace_end_69:
  %t25 = phi i32* [ %t23, %arr_rplace_ok_67 ], [ %t24, %arr_rplace_oob_68 ]
  %t26 = load i32, i32* %t25
  %t27 = sub i32 %t17, %t26
  %t28 = icmp sge i32 %t27, 280
  br i1 %t28, label %logic_rhs_70, label %logic_short_71
logic_rhs_70:
  %t29 = load i32, i32* %t15
  %t30 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t31 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t30, i32 0, i32 10
  %t32 = load i32, i32* %t2
  %t33 = sext i32 %t32 to i64
  %t34 = icmp ult i64 %t33, 256
  br i1 %t34, label %arr_rplace_ok_73, label %arr_rplace_oob_74
arr_rplace_ok_73:
  %t35 = getelementptr inbounds [256 x i32], [256 x i32]* %t31, i32 0, i64 %t33
  br label %arr_rplace_end_75
arr_rplace_oob_74:
  store i32 0, i32* %t36
  br label %arr_rplace_end_75
arr_rplace_end_75:
  %t37 = phi i32* [ %t35, %arr_rplace_ok_73 ], [ %t36, %arr_rplace_oob_74 ]
  %t38 = load i32, i32* %t37
  %t39 = sub i32 %t29, %t38
  %t40 = icmp sge i32 %t39, 50
  br label %logic_end_72
logic_short_71:
  br label %logic_end_72
logic_end_72:
  %t41 = phi i1 [ %t40, %arr_rplace_end_75 ], [ false, %logic_short_71 ]
  br i1 %t41, label %if_then_76, label %if_else_77
if_then_76:
  %t42 = load i32, i32* %t15
  %t43 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t44 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t43, i32 0, i32 10
  %t45 = load i32, i32* %t2
  %t46 = sext i32 %t45 to i64
  %t47 = icmp ult i64 %t46, 256
  br i1 %t47, label %arr_set_do_79, label %arr_set_oob_80
arr_set_do_79:
  %t48 = getelementptr inbounds [256 x i32], [256 x i32]* %t44, i32 0, i64 %t46
  store i32 %t42, i32* %t48
  br label %arr_set_end_81
arr_set_oob_80:
  br label %arr_set_end_81
arr_set_end_81:
  ret i1 true
if_else_77:
  br label %if_end_78
if_end_78:
  ret i1 false
}

define void @keyboard__Keyboard__key_hold_end(%keyboard__Keyboard* %self, i8 %code) {
entry:
  %t0 = alloca %keyboard__Keyboard*
  %t1 = alloca i8
  store %keyboard__Keyboard* %self, %keyboard__Keyboard** %t0
  store i8 %code, i8* %t1
  %t2 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t3 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t2, i32 0, i32 8
  %t4 = load i8, i8* %t1
  %t5 = zext i8 %t4 to i32
  %t6 = sext i32 %t5 to i64
  %t7 = icmp ult i64 %t6, 256
  br i1 %t7, label %arr_set_do_82, label %arr_set_oob_83
arr_set_do_82:
  %t8 = getelementptr inbounds [256 x i1], [256 x i1]* %t3, i32 0, i64 %t6
  store i1 false, i1* %t8
  br label %arr_set_end_84
arr_set_oob_83:
  br label %arr_set_end_84
arr_set_end_84:
  ret void
}

define void @keyboard__Keyboard__key_holds_clear(%keyboard__Keyboard* %self) {
entry:
  %t0 = alloca %keyboard__Keyboard*
  %t1 = alloca i32
  store %keyboard__Keyboard* %self, %keyboard__Keyboard** %t0
  store i32 0, i32* %t1
  br label %while_cond_85
while_cond_85:
  %t2 = load i32, i32* %t1
  %t3 = icmp slt i32 %t2, 256
  br i1 %t3, label %while_body_86, label %while_else_87
while_body_86:
  %t4 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t5 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t4, i32 0, i32 8
  %t6 = load i32, i32* %t1
  %t7 = sext i32 %t6 to i64
  %t8 = icmp ult i64 %t7, 256
  br i1 %t8, label %arr_set_do_89, label %arr_set_oob_90
arr_set_do_89:
  %t9 = getelementptr inbounds [256 x i1], [256 x i1]* %t5, i32 0, i64 %t7
  store i1 false, i1* %t9
  br label %arr_set_end_91
arr_set_oob_90:
  br label %arr_set_end_91
arr_set_end_91:
  %t10 = load i32, i32* %t1
  %t11 = add i32 %t10, 1
  store i32 %t11, i32* %t1
  br label %while_cond_85
while_else_87:
  br label %while_end_88
while_end_88:
  ret void
}

define i1 @keyboard__Keyboard__irq_pending(%keyboard__Keyboard* %self) {
entry:
  %t0 = alloca %keyboard__Keyboard*
  store %keyboard__Keyboard* %self, %keyboard__Keyboard** %t0
  %t1 = load %keyboard__Keyboard*, %keyboard__Keyboard** %t0
  %t2 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t1, i32 0, i32 4
  %t3 = load i8, i8* %t2
  %t4 = and i32 7, 7
  %t5 = trunc i32 %t4 to i8
  %t6 = shl i8 1, %t5
  %t7 = and i8 %t3, %t6
  %t8 = icmp ne i8 %t7, 0
  ret i1 %t8
}

define void @new_kbd(%keyboard__Keyboard* %.sret) {
entry:
  %t3 = alloca i64
  %t19 = alloca i64
  %t26 = alloca i64
  %t33 = alloca i64
  %t40 = alloca i64
  %t0 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %.sret, i32 0, i32 0
  %t1 = trunc i32 0 to i8
  %t2 = getelementptr inbounds [64 x i8], [64 x i8]* %t0, i32 0, i64 0
  store i8 %t1, i8* %t2
  store i64 1, i64* %t3
  br label %arr_rep_cond_92
arr_rep_cond_92:
  %t4 = load i64, i64* %t3
  %t5 = icmp ult i64 %t4, 64
  br i1 %t5, label %arr_rep_body_93, label %arr_rep_end_94
arr_rep_body_93:
  %t6 = getelementptr inbounds [64 x i8], [64 x i8]* %t0, i32 0, i64 %t4
  store i8 %t1, i8* %t6
  %t7 = add i64 %t4, 1
  store i64 %t7, i64* %t3
  br label %arr_rep_cond_92
arr_rep_end_94:
  %t8 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %.sret, i32 0, i32 1
  store i32 0, i32* %t8
  %t9 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %.sret, i32 0, i32 2
  store i32 0, i32* %t9
  %t10 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %.sret, i32 0, i32 3
  store i32 0, i32* %t10
  %t11 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %.sret, i32 0, i32 4
  %t12 = trunc i32 0 to i8
  store i8 %t12, i8* %t11
  %t13 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %.sret, i32 0, i32 5
  %t14 = trunc i32 0 to i8
  store i8 %t14, i8* %t13
  %t15 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %.sret, i32 0, i32 6
  store i32 35, i32* %t15
  %t16 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %.sret, i32 0, i32 7
  %t17 = sub i32 0, 1
  %t18 = getelementptr inbounds [256 x i32], [256 x i32]* %t16, i32 0, i64 0
  store i32 %t17, i32* %t18
  store i64 1, i64* %t19
  br label %arr_rep_cond_95
arr_rep_cond_95:
  %t20 = load i64, i64* %t19
  %t21 = icmp ult i64 %t20, 256
  br i1 %t21, label %arr_rep_body_96, label %arr_rep_end_97
arr_rep_body_96:
  %t22 = getelementptr inbounds [256 x i32], [256 x i32]* %t16, i32 0, i64 %t20
  store i32 %t17, i32* %t22
  %t23 = add i64 %t20, 1
  store i64 %t23, i64* %t19
  br label %arr_rep_cond_95
arr_rep_end_97:
  %t24 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %.sret, i32 0, i32 8
  %t25 = getelementptr inbounds [256 x i1], [256 x i1]* %t24, i32 0, i64 0
  store i1 false, i1* %t25
  store i64 1, i64* %t26
  br label %arr_rep_cond_98
arr_rep_cond_98:
  %t27 = load i64, i64* %t26
  %t28 = icmp ult i64 %t27, 256
  br i1 %t28, label %arr_rep_body_99, label %arr_rep_end_100
arr_rep_body_99:
  %t29 = getelementptr inbounds [256 x i1], [256 x i1]* %t24, i32 0, i64 %t27
  store i1 false, i1* %t29
  %t30 = add i64 %t27, 1
  store i64 %t30, i64* %t26
  br label %arr_rep_cond_98
arr_rep_end_100:
  %t31 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %.sret, i32 0, i32 9
  %t32 = getelementptr inbounds [256 x i32], [256 x i32]* %t31, i32 0, i64 0
  store i32 0, i32* %t32
  store i64 1, i64* %t33
  br label %arr_rep_cond_101
arr_rep_cond_101:
  %t34 = load i64, i64* %t33
  %t35 = icmp ult i64 %t34, 256
  br i1 %t35, label %arr_rep_body_102, label %arr_rep_end_103
arr_rep_body_102:
  %t36 = getelementptr inbounds [256 x i32], [256 x i32]* %t31, i32 0, i64 %t34
  store i32 0, i32* %t36
  %t37 = add i64 %t34, 1
  store i64 %t37, i64* %t33
  br label %arr_rep_cond_101
arr_rep_end_103:
  %t38 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %.sret, i32 0, i32 10
  %t39 = getelementptr inbounds [256 x i32], [256 x i32]* %t38, i32 0, i64 0
  store i32 0, i32* %t39
  store i64 1, i64* %t40
  br label %arr_rep_cond_104
arr_rep_cond_104:
  %t41 = load i64, i64* %t40
  %t42 = icmp ult i64 %t41, 256
  br i1 %t42, label %arr_rep_body_105, label %arr_rep_end_106
arr_rep_body_105:
  %t43 = getelementptr inbounds [256 x i32], [256 x i32]* %t38, i32 0, i64 %t41
  store i32 0, i32* %t43
  %t44 = add i64 %t41, 1
  store i64 %t44, i64* %t40
  br label %arr_rep_cond_104
arr_rep_end_106:
  ret void
}

define void @check(i8* %name, i1 %got, i1 %expected) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i1
  %t2 = alloca i1
  store i8* %name, i8** %t0
  store i1 %got, i1* %t1
  store i1 %expected, i1* %t2
  %t3 = load i1, i1* %t1
  %t4 = load i1, i1* %t2
  %t5 = icmp eq i1 %t3, %t4
  br i1 %t5, label %if_then_107, label %if_else_108
if_then_107:
  %t6 = load i8*, i8** %t0
  %t7 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t7)
  %t8 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t8, i8* %t6)
  call void @star_rc_release(i8* %t6)
  br label %if_end_109
if_else_108:
  %t9 = load i8*, i8** %t0
  %t10 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t10)
  %t11 = load i1, i1* %t1
  %t12 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.3, i64 0, i64 0
  %t13 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.4, i64 0, i64 0
  %t14 = select i1 %t11, i8* %t12, i8* %t13
  %t15 = load i1, i1* %t2
  %t16 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.5, i64 0, i64 0
  %t17 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.6, i64 0, i64 0
  %t18 = select i1 %t15, i8* %t16, i8* %t17
  %t19 = getelementptr inbounds [30 x i8], [30 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t19, i8* %t9, i8* %t14, i8* %t18)
  call void @star_rc_release(i8* %t9)
  br label %if_end_109
if_end_109:
  %t20 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t20)
  ret void
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t4 = alloca %keyboard__Keyboard
  %t5 = alloca i1
  %t101 = alloca %keyboard__Keyboard
  %t121 = alloca %keyboard__Keyboard
  %t151 = alloca %keyboard__Keyboard
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t2 = icmp slt i32 100, 0
  %t3 = select i1 %t2, i32 0, i32 100
  call void @SDL_Delay(i32 %t3)
  call void @new_kbd(%keyboard__Keyboard* %t4)
  %t6 = trunc i32 65 to i8
  %t7 = call i1 @keyboard__Keyboard__key_hold_tick(%keyboard__Keyboard* %t4, i8 %t6)
  store i1 %t7, i1* %t5
  %t8 = getelementptr inbounds { i64, i8*, [29 x i8] }, { i64, i8*, [29 x i8] }* @.str.8, i64 0, i32 2, i64 0
  %t9 = load i1, i1* %t5
  call void @check(i8* %t8, i1 %t9, i1 false)
  %t10 = getelementptr inbounds { i64, i8*, [35 x i8] }, { i64, i8*, [35 x i8] }* @.str.9, i64 0, i32 2, i64 0
  %t11 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t4, i32 0, i32 3
  %t12 = load i32, i32* %t11
  %t13 = icmp eq i32 %t12, 0
  call void @check(i8* %t10, i1 %t13, i1 true)
  %t14 = trunc i32 65 to i8
  call void @keyboard__Keyboard__key_hold_begin(%keyboard__Keyboard* %t4, i8 %t14)
  %t16 = trunc i32 65 to i8
  %t17 = call i1 @keyboard__Keyboard__key_hold_tick(%keyboard__Keyboard* %t4, i8 %t16)
  store i1 %t17, i1* %t5
  %t18 = getelementptr inbounds { i64, i8*, [34 x i8] }, { i64, i8*, [34 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t19 = load i1, i1* %t5
  call void @check(i8* %t18, i1 %t19, i1 false)
  %t20 = getelementptr inbounds { i64, i8*, [47 x i8] }, { i64, i8*, [47 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t21 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t4, i32 0, i32 3
  %t22 = load i32, i32* %t21
  %t23 = icmp eq i32 %t22, 0
  call void @check(i8* %t20, i1 %t23, i1 true)
  %t24 = call i32 @SDL_GetTicks()
  %t25 = sub i32 %t24, 300
  %t26 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t4, i32 0, i32 9
  %t27 = sext i32 65 to i64
  %t28 = icmp ult i64 %t27, 256
  br i1 %t28, label %arr_set_do_110, label %arr_set_oob_111
arr_set_do_110:
  %t29 = getelementptr inbounds [256 x i32], [256 x i32]* %t26, i32 0, i64 %t27
  store i32 %t25, i32* %t29
  br label %arr_set_end_112
arr_set_oob_111:
  br label %arr_set_end_112
arr_set_end_112:
  %t30 = call i32 @SDL_GetTicks()
  %t31 = sub i32 %t30, 300
  %t32 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t4, i32 0, i32 10
  %t33 = sext i32 65 to i64
  %t34 = icmp ult i64 %t33, 256
  br i1 %t34, label %arr_set_do_113, label %arr_set_oob_114
arr_set_do_113:
  %t35 = getelementptr inbounds [256 x i32], [256 x i32]* %t32, i32 0, i64 %t33
  store i32 %t31, i32* %t35
  br label %arr_set_end_115
arr_set_oob_114:
  br label %arr_set_end_115
arr_set_end_115:
  %t36 = trunc i32 65 to i8
  %t37 = call i1 @keyboard__Keyboard__key_hold_tick(%keyboard__Keyboard* %t4, i8 %t36)
  store i1 %t37, i1* %t5
  %t38 = load i1, i1* %t5
  br i1 %t38, label %if_then_116, label %if_else_117
if_then_116:
  %t39 = trunc i32 65 to i8
  call void @keyboard__Keyboard__push_key(%keyboard__Keyboard* %t4, i8 %t39)
  br label %if_end_118
if_else_117:
  br label %if_end_118
if_end_118:
  %t41 = getelementptr inbounds { i64, i8*, [26 x i8] }, { i64, i8*, [26 x i8] }* @.str.12, i64 0, i32 2, i64 0
  %t42 = load i1, i1* %t5
  call void @check(i8* %t41, i1 %t42, i1 true)
  %t43 = getelementptr inbounds { i64, i8*, [30 x i8] }, { i64, i8*, [30 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t44 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t4, i32 0, i32 3
  %t45 = load i32, i32* %t44
  %t46 = icmp eq i32 %t45, 1
  call void @check(i8* %t43, i1 %t46, i1 true)
  %t47 = trunc i32 65 to i8
  %t48 = call i1 @keyboard__Keyboard__key_hold_tick(%keyboard__Keyboard* %t4, i8 %t47)
  store i1 %t48, i1* %t5
  %t49 = getelementptr inbounds { i64, i8*, [43 x i8] }, { i64, i8*, [43 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t50 = load i1, i1* %t5
  call void @check(i8* %t49, i1 %t50, i1 false)
  %t51 = call i32 @SDL_GetTicks()
  %t52 = sub i32 %t51, 60
  %t53 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t4, i32 0, i32 10
  %t54 = sext i32 65 to i64
  %t55 = icmp ult i64 %t54, 256
  br i1 %t55, label %arr_set_do_119, label %arr_set_oob_120
arr_set_do_119:
  %t56 = getelementptr inbounds [256 x i32], [256 x i32]* %t53, i32 0, i64 %t54
  store i32 %t52, i32* %t56
  br label %arr_set_end_121
arr_set_oob_120:
  br label %arr_set_end_121
arr_set_end_121:
  %t57 = trunc i32 65 to i8
  %t58 = call i1 @keyboard__Keyboard__key_hold_tick(%keyboard__Keyboard* %t4, i8 %t57)
  store i1 %t58, i1* %t5
  %t59 = load i1, i1* %t5
  br i1 %t59, label %if_then_122, label %if_else_123
if_then_122:
  %t60 = trunc i32 65 to i8
  call void @keyboard__Keyboard__push_key(%keyboard__Keyboard* %t4, i8 %t60)
  br label %if_end_124
if_else_123:
  br label %if_end_124
if_end_124:
  %t62 = getelementptr inbounds { i64, i8*, [35 x i8] }, { i64, i8*, [35 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t63 = load i1, i1* %t5
  call void @check(i8* %t62, i1 %t63, i1 true)
  %t64 = getelementptr inbounds { i64, i8*, [25 x i8] }, { i64, i8*, [25 x i8] }* @.str.16, i64 0, i32 2, i64 0
  %t65 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t4, i32 0, i32 3
  %t66 = load i32, i32* %t65
  %t67 = icmp eq i32 %t66, 2
  call void @check(i8* %t64, i1 %t67, i1 true)
  %t68 = trunc i32 65 to i8
  call void @keyboard__Keyboard__key_hold_end(%keyboard__Keyboard* %t4, i8 %t68)
  %t70 = trunc i32 65 to i8
  %t71 = call i1 @keyboard__Keyboard__key_hold_tick(%keyboard__Keyboard* %t4, i8 %t70)
  store i1 %t71, i1* %t5
  %t72 = getelementptr inbounds { i64, i8*, [23 x i8] }, { i64, i8*, [23 x i8] }* @.str.17, i64 0, i32 2, i64 0
  %t73 = load i1, i1* %t5
  call void @check(i8* %t72, i1 %t73, i1 false)
  %t74 = getelementptr inbounds { i64, i8*, [26 x i8] }, { i64, i8*, [26 x i8] }* @.str.18, i64 0, i32 2, i64 0
  %t75 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t4, i32 0, i32 3
  %t76 = load i32, i32* %t75
  %t77 = icmp eq i32 %t76, 2
  call void @check(i8* %t74, i1 %t77, i1 true)
  %t78 = trunc i32 65 to i8
  call void @keyboard__Keyboard__key_hold_begin(%keyboard__Keyboard* %t4, i8 %t78)
  %t80 = trunc i32 65 to i8
  %t81 = call i1 @keyboard__Keyboard__key_hold_tick(%keyboard__Keyboard* %t4, i8 %t80)
  store i1 %t81, i1* %t5
  %t82 = getelementptr inbounds { i64, i8*, [43 x i8] }, { i64, i8*, [43 x i8] }* @.str.19, i64 0, i32 2, i64 0
  %t83 = load i1, i1* %t5
  call void @check(i8* %t82, i1 %t83, i1 false)
  %t84 = call i32 @SDL_GetTicks()
  %t85 = sub i32 %t84, 400
  %t86 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t4, i32 0, i32 9
  %t87 = sext i32 65 to i64
  %t88 = icmp ult i64 %t87, 256
  br i1 %t88, label %arr_set_do_125, label %arr_set_oob_126
arr_set_do_125:
  %t89 = getelementptr inbounds [256 x i32], [256 x i32]* %t86, i32 0, i64 %t87
  store i32 %t85, i32* %t89
  br label %arr_set_end_127
arr_set_oob_126:
  br label %arr_set_end_127
arr_set_end_127:
  %t90 = call i32 @SDL_GetTicks()
  %t91 = sub i32 %t90, 400
  %t92 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t4, i32 0, i32 10
  %t93 = sext i32 65 to i64
  %t94 = icmp ult i64 %t93, 256
  br i1 %t94, label %arr_set_do_128, label %arr_set_oob_129
arr_set_do_128:
  %t95 = getelementptr inbounds [256 x i32], [256 x i32]* %t92, i32 0, i64 %t93
  store i32 %t91, i32* %t95
  br label %arr_set_end_130
arr_set_oob_129:
  br label %arr_set_end_130
arr_set_end_130:
  call void @keyboard__Keyboard__key_holds_clear(%keyboard__Keyboard* %t4)
  %t97 = trunc i32 65 to i8
  %t98 = call i1 @keyboard__Keyboard__key_hold_tick(%keyboard__Keyboard* %t4, i8 %t97)
  store i1 %t98, i1* %t5
  %t99 = getelementptr inbounds { i64, i8*, [27 x i8] }, { i64, i8*, [27 x i8] }* @.str.20, i64 0, i32 2, i64 0
  %t100 = load i1, i1* %t5
  call void @check(i8* %t99, i1 %t100, i1 false)
  call void @new_kbd(%keyboard__Keyboard* %t101)
  %t102 = trunc i32 66 to i8
  call void @keyboard__Keyboard__key_hold_begin(%keyboard__Keyboard* %t101, i8 %t102)
  %t104 = call i32 @SDL_GetTicks()
  %t105 = sub i32 %t104, 400
  %t106 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t101, i32 0, i32 9
  %t107 = sext i32 66 to i64
  %t108 = icmp ult i64 %t107, 256
  br i1 %t108, label %arr_set_do_131, label %arr_set_oob_132
arr_set_do_131:
  %t109 = getelementptr inbounds [256 x i32], [256 x i32]* %t106, i32 0, i64 %t107
  store i32 %t105, i32* %t109
  br label %arr_set_end_133
arr_set_oob_132:
  br label %arr_set_end_133
arr_set_end_133:
  %t110 = call i32 @SDL_GetTicks()
  %t111 = sub i32 %t110, 400
  %t112 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t101, i32 0, i32 10
  %t113 = sext i32 66 to i64
  %t114 = icmp ult i64 %t113, 256
  br i1 %t114, label %arr_set_do_134, label %arr_set_oob_135
arr_set_do_134:
  %t115 = getelementptr inbounds [256 x i32], [256 x i32]* %t112, i32 0, i64 %t113
  store i32 %t111, i32* %t115
  br label %arr_set_end_136
arr_set_oob_135:
  br label %arr_set_end_136
arr_set_end_136:
  call void @keyboard__Keyboard__key_holds_clear(%keyboard__Keyboard* %t101)
  %t117 = trunc i32 66 to i8
  %t118 = call i1 @keyboard__Keyboard__key_hold_tick(%keyboard__Keyboard* %t101, i8 %t117)
  store i1 %t118, i1* %t5
  %t119 = getelementptr inbounds { i64, i8*, [23 x i8] }, { i64, i8*, [23 x i8] }* @.str.21, i64 0, i32 2, i64 0
  %t120 = load i1, i1* %t5
  call void @check(i8* %t119, i1 %t120, i1 false)
  call void @new_kbd(%keyboard__Keyboard* %t121)
  %t122 = trunc i32 65 to i8
  call void @keyboard__Keyboard__key_hold_begin(%keyboard__Keyboard* %t121, i8 %t122)
  %t124 = icmp slt i32 30, 0
  %t125 = select i1 %t124, i32 0, i32 30
  call void @SDL_Delay(i32 %t125)
  %t126 = trunc i32 66 to i8
  call void @keyboard__Keyboard__key_hold_begin(%keyboard__Keyboard* %t121, i8 %t126)
  %t128 = call i32 @SDL_GetTicks()
  %t129 = sub i32 %t128, 300
  %t130 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t121, i32 0, i32 9
  %t131 = sext i32 66 to i64
  %t132 = icmp ult i64 %t131, 256
  br i1 %t132, label %arr_set_do_137, label %arr_set_oob_138
arr_set_do_137:
  %t133 = getelementptr inbounds [256 x i32], [256 x i32]* %t130, i32 0, i64 %t131
  store i32 %t129, i32* %t133
  br label %arr_set_end_139
arr_set_oob_138:
  br label %arr_set_end_139
arr_set_end_139:
  %t134 = call i32 @SDL_GetTicks()
  %t135 = sub i32 %t134, 300
  %t136 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t121, i32 0, i32 10
  %t137 = sext i32 66 to i64
  %t138 = icmp ult i64 %t137, 256
  br i1 %t138, label %arr_set_do_140, label %arr_set_oob_141
arr_set_do_140:
  %t139 = getelementptr inbounds [256 x i32], [256 x i32]* %t136, i32 0, i64 %t137
  store i32 %t135, i32* %t139
  br label %arr_set_end_142
arr_set_oob_141:
  br label %arr_set_end_142
arr_set_end_142:
  %t140 = trunc i32 66 to i8
  %t141 = call i1 @keyboard__Keyboard__key_hold_tick(%keyboard__Keyboard* %t121, i8 %t140)
  store i1 %t141, i1* %t5
  %t142 = load i1, i1* %t5
  br i1 %t142, label %if_then_143, label %if_else_144
if_then_143:
  %t143 = trunc i32 66 to i8
  call void @keyboard__Keyboard__push_key(%keyboard__Keyboard* %t121, i8 %t143)
  br label %if_end_145
if_else_144:
  br label %if_end_145
if_end_145:
  %t145 = getelementptr inbounds { i64, i8*, [43 x i8] }, { i64, i8*, [43 x i8] }* @.str.22, i64 0, i32 2, i64 0
  %t146 = load i1, i1* %t5
  call void @check(i8* %t145, i1 %t146, i1 true)
  %t147 = trunc i32 65 to i8
  %t148 = call i1 @keyboard__Keyboard__key_hold_tick(%keyboard__Keyboard* %t121, i8 %t147)
  store i1 %t148, i1* %t5
  %t149 = getelementptr inbounds { i64, i8*, [29 x i8] }, { i64, i8*, [29 x i8] }* @.str.23, i64 0, i32 2, i64 0
  %t150 = load i1, i1* %t5
  call void @check(i8* %t149, i1 %t150, i1 false)
  call void @new_kbd(%keyboard__Keyboard* %t151)
  %t152 = trunc i32 65 to i8
  call void @keyboard__Keyboard__key_hold_begin(%keyboard__Keyboard* %t151, i8 %t152)
  %t154 = icmp slt i32 300, 0
  %t155 = select i1 %t154, i32 0, i32 300
  call void @SDL_Delay(i32 %t155)
  %t156 = trunc i32 65 to i8
  %t157 = call i1 @keyboard__Keyboard__key_hold_tick(%keyboard__Keyboard* %t151, i8 %t156)
  store i1 %t157, i1* %t5
  %t158 = load i1, i1* %t5
  br i1 %t158, label %if_then_146, label %if_else_147
if_then_146:
  %t159 = trunc i32 65 to i8
  call void @keyboard__Keyboard__push_key(%keyboard__Keyboard* %t151, i8 %t159)
  br label %if_end_148
if_else_147:
  br label %if_end_148
if_end_148:
  %t161 = getelementptr inbounds { i64, i8*, [44 x i8] }, { i64, i8*, [44 x i8] }* @.str.24, i64 0, i32 2, i64 0
  %t162 = load i1, i1* %t5
  call void @check(i8* %t161, i1 %t162, i1 true)
  %t163 = trunc i32 65 to i8
  %t164 = call i1 @keyboard__Keyboard__key_hold_tick(%keyboard__Keyboard* %t151, i8 %t163)
  store i1 %t164, i1* %t5
  %t165 = getelementptr inbounds { i64, i8*, [38 x i8] }, { i64, i8*, [38 x i8] }* @.str.25, i64 0, i32 2, i64 0
  %t166 = load i1, i1* %t5
  call void @check(i8* %t165, i1 %t166, i1 false)
  %t167 = icmp slt i32 60, 0
  %t168 = select i1 %t167, i32 0, i32 60
  call void @SDL_Delay(i32 %t168)
  %t169 = trunc i32 65 to i8
  %t170 = call i1 @keyboard__Keyboard__key_hold_tick(%keyboard__Keyboard* %t151, i8 %t169)
  store i1 %t170, i1* %t5
  %t171 = load i1, i1* %t5
  br i1 %t171, label %if_then_149, label %if_else_150
if_then_149:
  %t172 = trunc i32 65 to i8
  call void @keyboard__Keyboard__push_key(%keyboard__Keyboard* %t151, i8 %t172)
  br label %if_end_151
if_else_150:
  br label %if_end_151
if_end_151:
  %t174 = getelementptr inbounds { i64, i8*, [44 x i8] }, { i64, i8*, [44 x i8] }* @.str.26, i64 0, i32 2, i64 0
  %t175 = load i1, i1* %t5
  call void @check(i8* %t174, i1 %t175, i1 true)
  %t176 = getelementptr inbounds { i64, i8*, [29 x i8] }, { i64, i8*, [29 x i8] }* @.str.27, i64 0, i32 2, i64 0
  %t177 = getelementptr inbounds %keyboard__Keyboard, %keyboard__Keyboard* %t151, i32 0, i32 3
  %t178 = load i32, i32* %t177
  %t179 = icmp eq i32 %t178, 2
  call void @check(i8* %t176, i1 %t179, i1 true)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.1 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.2 = private unnamed_addr constant [9 x i8] c"PASS %s\0A\00"
@.str.3 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.4 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.5 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.6 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.7 = private unnamed_addr constant [30 x i8] c"FAIL %s: got %s, expected %s\0A\00"
@.str.8 = private unnamed_addr constant { i64, i8*, [29 x i8] } { i64 -1, i8* null, [29 x i8] c"never-armed code never fires\00" }
@.str.9 = private unnamed_addr constant { i64, i8*, [35 x i8] } { i64 -1, i8* null, [35 x i8] c"never-armed tick left buffer empty\00" }
@.str.10 = private unnamed_addr constant { i64, i8*, [34 x i8] } { i64 -1, i8* null, [34 x i8] c"just-armed hold does not fire yet\00" }
@.str.11 = private unnamed_addr constant { i64, i8*, [47 x i8] } { i64 -1, i8* null, [47 x i8] c"initial press itself is not the repeater's job\00" }
@.str.12 = private unnamed_addr constant { i64, i8*, [26 x i8] } { i64 -1, i8* null, [26 x i8] c"fires after initial delay\00" }
@.str.13 = private unnamed_addr constant { i64, i8*, [30 x i8] } { i64 -1, i8* null, [30 x i8] c"fired repeat landed in buffer\00" }
@.str.14 = private unnamed_addr constant { i64, i8*, [43 x i8] } { i64 -1, i8* null, [43 x i8] c"immediate second tick held off by interval\00" }
@.str.15 = private unnamed_addr constant { i64, i8*, [35 x i8] } { i64 -1, i8* null, [35 x i8] c"fires again after interval expires\00" }
@.str.16 = private unnamed_addr constant { i64, i8*, [25 x i8] } { i64 -1, i8* null, [25 x i8] c"repeat bypasses debounce\00" }
@.str.17 = private unnamed_addr constant { i64, i8*, [23 x i8] } { i64 -1, i8* null, [23 x i8] c"ended hold never fires\00" }
@.str.18 = private unnamed_addr constant { i64, i8*, [26 x i8] } { i64 -1, i8* null, [26 x i8] c"ended hold pushed nothing\00" }
@.str.19 = private unnamed_addr constant { i64, i8*, [43 x i8] } { i64 -1, i8* null, [43 x i8] c"re-armed hold starts a fresh initial delay\00" }
@.str.20 = private unnamed_addr constant { i64, i8*, [27 x i8] } { i64 -1, i8* null, [27 x i8] c"cleared hold does not fire\00" }
@.str.21 = private unnamed_addr constant { i64, i8*, [23 x i8] } { i64 -1, i8* null, [23 x i8] c"clear covers all codes\00" }
@.str.22 = private unnamed_addr constant { i64, i8*, [43 x i8] } { i64 -1, i8* null, [43 x i8] c"independent code fires on its own schedule\00" }
@.str.23 = private unnamed_addr constant { i64, i8*, [29 x i8] } { i64 -1, i8* null, [29 x i8] c"other code's hold unaffected\00" }
@.str.24 = private unnamed_addr constant { i64, i8*, [44 x i8] } { i64 -1, i8* null, [44 x i8] c"real 300ms hold fires (initial delay 280ms)\00" }
@.str.25 = private unnamed_addr constant { i64, i8*, [38 x i8] } { i64 -1, i8* null, [38 x i8] c"real-clock immediate re-tick held off\00" }
@.str.26 = private unnamed_addr constant { i64, i8*, [44 x i8] } { i64 -1, i8* null, [44 x i8] c"real 60ms later fires again (interval 50ms)\00" }
@.str.27 = private unnamed_addr constant { i64, i8*, [29 x i8] } { i64 -1, i8* null, [29 x i8] c"real-clock pushes all landed\00" }
