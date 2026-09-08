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

%Section = type { i32, i32, i32, i8* }
%NomfDocument = type { i32, i8*, i32, i1 }
%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define i8 @bits__shl8(i8 %x, i32 %n) {
entry:
  %t0 = alloca i8
  %t1 = alloca i32
  %t2 = alloca i32
  %t9 = alloca i8
  %t11 = alloca i32
  %t14 = alloca i32
  store i8 %x, i8* %t0
  store i32 %n, i32* %t1
  %t3 = load i32, i32* %t1
  store i32 %t3, i32* %t2
  %t4 = load i32, i32* %t2
  %t5 = icmp slt i32 %t4, 0
  br i1 %t5, label %if_then_0, label %if_else_1
if_then_0:
  store i32 0, i32* %t2
  br label %if_end_2
if_else_1:
  br label %if_end_2
if_end_2:
  %t6 = load i32, i32* %t2
  %t7 = icmp sge i32 %t6, 8
  br i1 %t7, label %if_then_3, label %if_else_4
if_then_3:
  %t8 = trunc i32 0 to i8
  br label %if_end_5
if_else_4:
  %t10 = trunc i32 0 to i8
  store i8 %t10, i8* %t9
  store i32 7, i32* %t11
  br label %for_cond_6
for_cond_6:
  %t12 = load i32, i32* %t11
  %t13 = icmp sge i32 %t12, 0
  br i1 %t13, label %for_body_7, label %for_end_9
for_body_7:
  %t15 = load i32, i32* %t11
  %t16 = load i32, i32* %t2
  %t17 = sub i32 %t15, %t16
  store i32 %t17, i32* %t14
  %t18 = load i32, i32* %t14
  %t19 = icmp sge i32 %t18, 0
  br i1 %t19, label %if_then_10, label %if_else_11
if_then_10:
  %t20 = load i8, i8* %t0
  %t21 = load i32, i32* %t14
  %t22 = and i32 %t21, 7
  %t23 = trunc i32 %t22 to i8
  %t24 = shl i8 1, %t23
  %t25 = and i8 %t20, %t24
  %t26 = icmp ne i8 %t25, 0
  br i1 %t26, label %if_then_13, label %if_else_14
if_then_13:
  %t27 = load i8, i8* %t9
  %t28 = load i32, i32* %t11
  %t29 = and i32 %t28, 7
  %t30 = trunc i32 %t29 to i8
  %t31 = shl i8 1, %t30
  %t32 = or i8 %t27, %t31
  store i8 %t32, i8* %t9
  br label %if_end_15
if_else_14:
  br label %if_end_15
if_end_15:
  br label %if_end_12
if_else_11:
  br label %if_end_12
if_end_12:
  br label %for_step_8
for_step_8:
  %t33 = load i32, i32* %t11
  %t34 = add i32 %t33, -1
  store i32 %t34, i32* %t11
  br label %for_cond_6
for_end_9:
  %t35 = load i8, i8* %t9
  br label %if_end_5
if_end_5:
  %t36 = phi i8 [ %t8, %if_then_3 ], [ %t35, %for_end_9 ]
  ret i8 %t36
}

define i8 @bits__shr8(i8 %x, i32 %n) {
entry:
  %t0 = alloca i8
  %t1 = alloca i32
  %t2 = alloca i32
  %t9 = alloca i8
  %t11 = alloca i32
  %t14 = alloca i32
  store i8 %x, i8* %t0
  store i32 %n, i32* %t1
  %t3 = load i32, i32* %t1
  store i32 %t3, i32* %t2
  %t4 = load i32, i32* %t2
  %t5 = icmp slt i32 %t4, 0
  br i1 %t5, label %if_then_16, label %if_else_17
if_then_16:
  store i32 0, i32* %t2
  br label %if_end_18
if_else_17:
  br label %if_end_18
if_end_18:
  %t6 = load i32, i32* %t2
  %t7 = icmp sge i32 %t6, 8
  br i1 %t7, label %if_then_19, label %if_else_20
if_then_19:
  %t8 = trunc i32 0 to i8
  br label %if_end_21
if_else_20:
  %t10 = trunc i32 0 to i8
  store i8 %t10, i8* %t9
  store i32 0, i32* %t11
  br label %for_cond_22
for_cond_22:
  %t12 = load i32, i32* %t11
  %t13 = icmp slt i32 %t12, 8
  br i1 %t13, label %for_body_23, label %for_end_25
for_body_23:
  %t15 = load i32, i32* %t11
  %t16 = load i32, i32* %t2
  %t17 = add i32 %t15, %t16
  store i32 %t17, i32* %t14
  %t18 = load i32, i32* %t14
  %t19 = icmp slt i32 %t18, 8
  br i1 %t19, label %if_then_26, label %if_else_27
if_then_26:
  %t20 = load i8, i8* %t0
  %t21 = load i32, i32* %t14
  %t22 = and i32 %t21, 7
  %t23 = trunc i32 %t22 to i8
  %t24 = shl i8 1, %t23
  %t25 = and i8 %t20, %t24
  %t26 = icmp ne i8 %t25, 0
  br i1 %t26, label %if_then_29, label %if_else_30
if_then_29:
  %t27 = load i8, i8* %t9
  %t28 = load i32, i32* %t11
  %t29 = and i32 %t28, 7
  %t30 = trunc i32 %t29 to i8
  %t31 = shl i8 1, %t30
  %t32 = or i8 %t27, %t31
  store i8 %t32, i8* %t9
  br label %if_end_31
if_else_30:
  br label %if_end_31
if_end_31:
  br label %if_end_28
if_else_27:
  br label %if_end_28
if_end_28:
  br label %for_step_24
for_step_24:
  %t33 = load i32, i32* %t11
  %t34 = add i32 %t33, 1
  store i32 %t34, i32* %t11
  br label %for_cond_22
for_end_25:
  %t35 = load i8, i8* %t9
  br label %if_end_21
if_end_21:
  %t36 = phi i8 [ %t8, %if_then_19 ], [ %t35, %for_end_25 ]
  ret i8 %t36
}

define i8 @bits__sar8(i8 %x, i32 %n) {
entry:
  %t0 = alloca i8
  %t1 = alloca i32
  %t2 = alloca i32
  %t6 = alloca i1
  %t19 = alloca i8
  %t21 = alloca i32
  %t24 = alloca i32
  store i8 %x, i8* %t0
  store i32 %n, i32* %t1
  %t3 = load i32, i32* %t1
  store i32 %t3, i32* %t2
  %t4 = load i32, i32* %t2
  %t5 = icmp slt i32 %t4, 0
  br i1 %t5, label %if_then_32, label %if_else_33
if_then_32:
  store i32 0, i32* %t2
  br label %if_end_34
if_else_33:
  br label %if_end_34
if_end_34:
  %t7 = load i8, i8* %t0
  %t8 = and i32 7, 7
  %t9 = trunc i32 %t8 to i8
  %t10 = shl i8 1, %t9
  %t11 = and i8 %t7, %t10
  %t12 = icmp ne i8 %t11, 0
  store i1 %t12, i1* %t6
  %t13 = load i32, i32* %t2
  %t14 = icmp sge i32 %t13, 8
  br i1 %t14, label %if_then_35, label %if_else_36
if_then_35:
  %t15 = load i1, i1* %t6
  br i1 %t15, label %if_then_38, label %if_else_39
if_then_38:
  %t16 = trunc i32 255 to i8
  br label %if_end_40
if_else_39:
  %t17 = trunc i32 0 to i8
  br label %if_end_40
if_end_40:
  %t18 = phi i8 [ %t16, %if_then_38 ], [ %t17, %if_else_39 ]
  br label %if_end_37
if_else_36:
  %t20 = trunc i32 0 to i8
  store i8 %t20, i8* %t19
  store i32 0, i32* %t21
  br label %for_cond_41
for_cond_41:
  %t22 = load i32, i32* %t21
  %t23 = icmp slt i32 %t22, 8
  br i1 %t23, label %for_body_42, label %for_end_44
for_body_42:
  %t25 = load i32, i32* %t21
  %t26 = load i32, i32* %t2
  %t27 = add i32 %t25, %t26
  store i32 %t27, i32* %t24
  %t28 = load i32, i32* %t24
  %t29 = icmp slt i32 %t28, 8
  br i1 %t29, label %if_then_45, label %if_else_46
if_then_45:
  %t30 = load i8, i8* %t0
  %t31 = load i32, i32* %t24
  %t32 = and i32 %t31, 7
  %t33 = trunc i32 %t32 to i8
  %t34 = shl i8 1, %t33
  %t35 = and i8 %t30, %t34
  %t36 = icmp ne i8 %t35, 0
  br i1 %t36, label %if_then_48, label %if_else_49
if_then_48:
  %t37 = load i8, i8* %t19
  %t38 = load i32, i32* %t21
  %t39 = and i32 %t38, 7
  %t40 = trunc i32 %t39 to i8
  %t41 = shl i8 1, %t40
  %t42 = or i8 %t37, %t41
  store i8 %t42, i8* %t19
  br label %if_end_50
if_else_49:
  br label %if_end_50
if_end_50:
  br label %if_end_47
if_else_46:
  %t43 = load i1, i1* %t6
  br i1 %t43, label %if_then_51, label %if_else_52
if_then_51:
  %t44 = load i8, i8* %t19
  %t45 = load i32, i32* %t21
  %t46 = and i32 %t45, 7
  %t47 = trunc i32 %t46 to i8
  %t48 = shl i8 1, %t47
  %t49 = or i8 %t44, %t48
  store i8 %t49, i8* %t19
  br label %if_end_53
if_else_52:
  br label %if_end_53
if_end_53:
  br label %if_end_47
if_end_47:
  br label %for_step_43
for_step_43:
  %t50 = load i32, i32* %t21
  %t51 = add i32 %t50, 1
  store i32 %t51, i32* %t21
  br label %for_cond_41
for_end_44:
  %t52 = load i8, i8* %t19
  br label %if_end_37
if_end_37:
  %t53 = phi i8 [ %t18, %if_end_40 ], [ %t52, %for_end_44 ]
  ret i8 %t53
}

define i8 @bits__rol8(i8 %x, i32 %n) {
entry:
  %t0 = alloca i8
  %t1 = alloca i32
  %t2 = alloca i32
  %t15 = alloca i8
  %t17 = alloca i32
  %t20 = alloca i32
  store i8 %x, i8* %t0
  store i32 %n, i32* %t1
  %t3 = load i32, i32* %t1
  %t4 = icmp eq i32 8, 0
  %t5 = icmp eq i32 %t3, -2147483648
  %t6 = icmp eq i32 8, -1
  %t7 = and i1 %t5, %t6
  %t8 = or i1 %t4, %t7
  br i1 %t8, label %int_div_fail_54, label %int_div_ok_55
int_div_fail_54:
  %t9 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t9)
  call void @exit(i32 1)
  unreachable
int_div_ok_55:
  %t10 = srem i32 %t3, 8
  store i32 %t10, i32* %t2
  %t11 = load i32, i32* %t2
  %t12 = icmp slt i32 %t11, 0
  br i1 %t12, label %if_then_56, label %if_else_57
if_then_56:
  %t13 = load i32, i32* %t2
  %t14 = add i32 %t13, 8
  store i32 %t14, i32* %t2
  br label %if_end_58
if_else_57:
  br label %if_end_58
if_end_58:
  %t16 = trunc i32 0 to i8
  store i8 %t16, i8* %t15
  store i32 0, i32* %t17
  br label %for_cond_59
for_cond_59:
  %t18 = load i32, i32* %t17
  %t19 = icmp slt i32 %t18, 8
  br i1 %t19, label %for_body_60, label %for_end_62
for_body_60:
  %t21 = load i32, i32* %t17
  %t22 = load i32, i32* %t2
  %t23 = sub i32 %t21, %t22
  %t24 = add i32 %t23, 8
  %t25 = icmp eq i32 8, 0
  %t26 = icmp eq i32 %t24, -2147483648
  %t27 = icmp eq i32 8, -1
  %t28 = and i1 %t26, %t27
  %t29 = or i1 %t25, %t28
  br i1 %t29, label %int_div_fail_63, label %int_div_ok_64
int_div_fail_63:
  %t30 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t30)
  call void @exit(i32 1)
  unreachable
int_div_ok_64:
  %t31 = srem i32 %t24, 8
  store i32 %t31, i32* %t20
  %t32 = load i8, i8* %t0
  %t33 = load i32, i32* %t20
  %t34 = and i32 %t33, 7
  %t35 = trunc i32 %t34 to i8
  %t36 = shl i8 1, %t35
  %t37 = and i8 %t32, %t36
  %t38 = icmp ne i8 %t37, 0
  br i1 %t38, label %if_then_65, label %if_else_66
if_then_65:
  %t39 = load i8, i8* %t15
  %t40 = load i32, i32* %t17
  %t41 = and i32 %t40, 7
  %t42 = trunc i32 %t41 to i8
  %t43 = shl i8 1, %t42
  %t44 = or i8 %t39, %t43
  store i8 %t44, i8* %t15
  br label %if_end_67
if_else_66:
  br label %if_end_67
if_end_67:
  br label %for_step_61
for_step_61:
  %t45 = load i32, i32* %t17
  %t46 = add i32 %t45, 1
  store i32 %t46, i32* %t17
  br label %for_cond_59
for_end_62:
  %t47 = load i8, i8* %t15
  ret i8 %t47
}

define i8 @bits__ror8(i8 %x, i32 %n) {
entry:
  %t0 = alloca i8
  %t1 = alloca i32
  %t2 = alloca i32
  store i8 %x, i8* %t0
  store i32 %n, i32* %t1
  %t3 = load i32, i32* %t1
  %t4 = icmp eq i32 8, 0
  %t5 = icmp eq i32 %t3, -2147483648
  %t6 = icmp eq i32 8, -1
  %t7 = and i1 %t5, %t6
  %t8 = or i1 %t4, %t7
  br i1 %t8, label %int_div_fail_68, label %int_div_ok_69
int_div_fail_68:
  %t9 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t9)
  call void @exit(i32 1)
  unreachable
int_div_ok_69:
  %t10 = srem i32 %t3, 8
  store i32 %t10, i32* %t2
  %t11 = load i32, i32* %t2
  %t12 = icmp slt i32 %t11, 0
  br i1 %t12, label %if_then_70, label %if_else_71
if_then_70:
  %t13 = load i32, i32* %t2
  %t14 = add i32 %t13, 8
  store i32 %t14, i32* %t2
  br label %if_end_72
if_else_71:
  br label %if_end_72
if_end_72:
  %t15 = load i8, i8* %t0
  %t16 = load i32, i32* %t2
  %t17 = sub i32 8, %t16
  %t18 = call i8 @bits__rol8(i8 %t15, i32 %t17)
  ret i8 %t18
}

define i16 @bits__shl16(i16 %x, i32 %n) {
entry:
  %t0 = alloca i16
  %t1 = alloca i32
  %t2 = alloca i32
  %t9 = alloca i16
  %t11 = alloca i32
  %t14 = alloca i32
  store i16 %x, i16* %t0
  store i32 %n, i32* %t1
  %t3 = load i32, i32* %t1
  store i32 %t3, i32* %t2
  %t4 = load i32, i32* %t2
  %t5 = icmp slt i32 %t4, 0
  br i1 %t5, label %if_then_73, label %if_else_74
if_then_73:
  store i32 0, i32* %t2
  br label %if_end_75
if_else_74:
  br label %if_end_75
if_end_75:
  %t6 = load i32, i32* %t2
  %t7 = icmp sge i32 %t6, 16
  br i1 %t7, label %if_then_76, label %if_else_77
if_then_76:
  %t8 = trunc i32 0 to i16
  br label %if_end_78
if_else_77:
  %t10 = trunc i32 0 to i16
  store i16 %t10, i16* %t9
  store i32 15, i32* %t11
  br label %for_cond_79
for_cond_79:
  %t12 = load i32, i32* %t11
  %t13 = icmp sge i32 %t12, 0
  br i1 %t13, label %for_body_80, label %for_end_82
for_body_80:
  %t15 = load i32, i32* %t11
  %t16 = load i32, i32* %t2
  %t17 = sub i32 %t15, %t16
  store i32 %t17, i32* %t14
  %t18 = load i32, i32* %t14
  %t19 = icmp sge i32 %t18, 0
  br i1 %t19, label %if_then_83, label %if_else_84
if_then_83:
  %t20 = load i16, i16* %t0
  %t21 = load i32, i32* %t14
  %t22 = and i32 %t21, 15
  %t23 = trunc i32 %t22 to i16
  %t24 = shl i16 1, %t23
  %t25 = and i16 %t20, %t24
  %t26 = icmp ne i16 %t25, 0
  br i1 %t26, label %if_then_86, label %if_else_87
if_then_86:
  %t27 = load i16, i16* %t9
  %t28 = load i32, i32* %t11
  %t29 = and i32 %t28, 15
  %t30 = trunc i32 %t29 to i16
  %t31 = shl i16 1, %t30
  %t32 = or i16 %t27, %t31
  store i16 %t32, i16* %t9
  br label %if_end_88
if_else_87:
  br label %if_end_88
if_end_88:
  br label %if_end_85
if_else_84:
  br label %if_end_85
if_end_85:
  br label %for_step_81
for_step_81:
  %t33 = load i32, i32* %t11
  %t34 = add i32 %t33, -1
  store i32 %t34, i32* %t11
  br label %for_cond_79
for_end_82:
  %t35 = load i16, i16* %t9
  br label %if_end_78
if_end_78:
  %t36 = phi i16 [ %t8, %if_then_76 ], [ %t35, %for_end_82 ]
  ret i16 %t36
}

define i16 @bits__shr16(i16 %x, i32 %n) {
entry:
  %t0 = alloca i16
  %t1 = alloca i32
  %t2 = alloca i32
  %t9 = alloca i16
  %t11 = alloca i32
  %t14 = alloca i32
  store i16 %x, i16* %t0
  store i32 %n, i32* %t1
  %t3 = load i32, i32* %t1
  store i32 %t3, i32* %t2
  %t4 = load i32, i32* %t2
  %t5 = icmp slt i32 %t4, 0
  br i1 %t5, label %if_then_89, label %if_else_90
if_then_89:
  store i32 0, i32* %t2
  br label %if_end_91
if_else_90:
  br label %if_end_91
if_end_91:
  %t6 = load i32, i32* %t2
  %t7 = icmp sge i32 %t6, 16
  br i1 %t7, label %if_then_92, label %if_else_93
if_then_92:
  %t8 = trunc i32 0 to i16
  br label %if_end_94
if_else_93:
  %t10 = trunc i32 0 to i16
  store i16 %t10, i16* %t9
  store i32 0, i32* %t11
  br label %for_cond_95
for_cond_95:
  %t12 = load i32, i32* %t11
  %t13 = icmp slt i32 %t12, 16
  br i1 %t13, label %for_body_96, label %for_end_98
for_body_96:
  %t15 = load i32, i32* %t11
  %t16 = load i32, i32* %t2
  %t17 = add i32 %t15, %t16
  store i32 %t17, i32* %t14
  %t18 = load i32, i32* %t14
  %t19 = icmp slt i32 %t18, 16
  br i1 %t19, label %if_then_99, label %if_else_100
if_then_99:
  %t20 = load i16, i16* %t0
  %t21 = load i32, i32* %t14
  %t22 = and i32 %t21, 15
  %t23 = trunc i32 %t22 to i16
  %t24 = shl i16 1, %t23
  %t25 = and i16 %t20, %t24
  %t26 = icmp ne i16 %t25, 0
  br i1 %t26, label %if_then_102, label %if_else_103
if_then_102:
  %t27 = load i16, i16* %t9
  %t28 = load i32, i32* %t11
  %t29 = and i32 %t28, 15
  %t30 = trunc i32 %t29 to i16
  %t31 = shl i16 1, %t30
  %t32 = or i16 %t27, %t31
  store i16 %t32, i16* %t9
  br label %if_end_104
if_else_103:
  br label %if_end_104
if_end_104:
  br label %if_end_101
if_else_100:
  br label %if_end_101
if_end_101:
  br label %for_step_97
for_step_97:
  %t33 = load i32, i32* %t11
  %t34 = add i32 %t33, 1
  store i32 %t34, i32* %t11
  br label %for_cond_95
for_end_98:
  %t35 = load i16, i16* %t9
  br label %if_end_94
if_end_94:
  %t36 = phi i16 [ %t8, %if_then_92 ], [ %t35, %for_end_98 ]
  ret i16 %t36
}

define i16 @bits__sar16(i16 %x, i32 %n) {
entry:
  %t0 = alloca i16
  %t1 = alloca i32
  %t2 = alloca i32
  %t6 = alloca i1
  %t19 = alloca i16
  %t21 = alloca i32
  %t24 = alloca i32
  store i16 %x, i16* %t0
  store i32 %n, i32* %t1
  %t3 = load i32, i32* %t1
  store i32 %t3, i32* %t2
  %t4 = load i32, i32* %t2
  %t5 = icmp slt i32 %t4, 0
  br i1 %t5, label %if_then_105, label %if_else_106
if_then_105:
  store i32 0, i32* %t2
  br label %if_end_107
if_else_106:
  br label %if_end_107
if_end_107:
  %t7 = load i16, i16* %t0
  %t8 = and i32 15, 15
  %t9 = trunc i32 %t8 to i16
  %t10 = shl i16 1, %t9
  %t11 = and i16 %t7, %t10
  %t12 = icmp ne i16 %t11, 0
  store i1 %t12, i1* %t6
  %t13 = load i32, i32* %t2
  %t14 = icmp sge i32 %t13, 16
  br i1 %t14, label %if_then_108, label %if_else_109
if_then_108:
  %t15 = load i1, i1* %t6
  br i1 %t15, label %if_then_111, label %if_else_112
if_then_111:
  %t16 = trunc i32 65535 to i16
  br label %if_end_113
if_else_112:
  %t17 = trunc i32 0 to i16
  br label %if_end_113
if_end_113:
  %t18 = phi i16 [ %t16, %if_then_111 ], [ %t17, %if_else_112 ]
  br label %if_end_110
if_else_109:
  %t20 = trunc i32 0 to i16
  store i16 %t20, i16* %t19
  store i32 0, i32* %t21
  br label %for_cond_114
for_cond_114:
  %t22 = load i32, i32* %t21
  %t23 = icmp slt i32 %t22, 16
  br i1 %t23, label %for_body_115, label %for_end_117
for_body_115:
  %t25 = load i32, i32* %t21
  %t26 = load i32, i32* %t2
  %t27 = add i32 %t25, %t26
  store i32 %t27, i32* %t24
  %t28 = load i32, i32* %t24
  %t29 = icmp slt i32 %t28, 16
  br i1 %t29, label %if_then_118, label %if_else_119
if_then_118:
  %t30 = load i16, i16* %t0
  %t31 = load i32, i32* %t24
  %t32 = and i32 %t31, 15
  %t33 = trunc i32 %t32 to i16
  %t34 = shl i16 1, %t33
  %t35 = and i16 %t30, %t34
  %t36 = icmp ne i16 %t35, 0
  br i1 %t36, label %if_then_121, label %if_else_122
if_then_121:
  %t37 = load i16, i16* %t19
  %t38 = load i32, i32* %t21
  %t39 = and i32 %t38, 15
  %t40 = trunc i32 %t39 to i16
  %t41 = shl i16 1, %t40
  %t42 = or i16 %t37, %t41
  store i16 %t42, i16* %t19
  br label %if_end_123
if_else_122:
  br label %if_end_123
if_end_123:
  br label %if_end_120
if_else_119:
  %t43 = load i1, i1* %t6
  br i1 %t43, label %if_then_124, label %if_else_125
if_then_124:
  %t44 = load i16, i16* %t19
  %t45 = load i32, i32* %t21
  %t46 = and i32 %t45, 15
  %t47 = trunc i32 %t46 to i16
  %t48 = shl i16 1, %t47
  %t49 = or i16 %t44, %t48
  store i16 %t49, i16* %t19
  br label %if_end_126
if_else_125:
  br label %if_end_126
if_end_126:
  br label %if_end_120
if_end_120:
  br label %for_step_116
for_step_116:
  %t50 = load i32, i32* %t21
  %t51 = add i32 %t50, 1
  store i32 %t51, i32* %t21
  br label %for_cond_114
for_end_117:
  %t52 = load i16, i16* %t19
  br label %if_end_110
if_end_110:
  %t53 = phi i16 [ %t18, %if_end_113 ], [ %t52, %for_end_117 ]
  ret i16 %t53
}

define i16 @bits__rol16(i16 %x, i32 %n) {
entry:
  %t0 = alloca i16
  %t1 = alloca i32
  %t2 = alloca i32
  %t15 = alloca i16
  %t17 = alloca i32
  %t20 = alloca i32
  store i16 %x, i16* %t0
  store i32 %n, i32* %t1
  %t3 = load i32, i32* %t1
  %t4 = icmp eq i32 16, 0
  %t5 = icmp eq i32 %t3, -2147483648
  %t6 = icmp eq i32 16, -1
  %t7 = and i1 %t5, %t6
  %t8 = or i1 %t4, %t7
  br i1 %t8, label %int_div_fail_127, label %int_div_ok_128
int_div_fail_127:
  %t9 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.3, i64 0, i64 0
  call i32 @puts(i8* %t9)
  call void @exit(i32 1)
  unreachable
int_div_ok_128:
  %t10 = srem i32 %t3, 16
  store i32 %t10, i32* %t2
  %t11 = load i32, i32* %t2
  %t12 = icmp slt i32 %t11, 0
  br i1 %t12, label %if_then_129, label %if_else_130
if_then_129:
  %t13 = load i32, i32* %t2
  %t14 = add i32 %t13, 16
  store i32 %t14, i32* %t2
  br label %if_end_131
if_else_130:
  br label %if_end_131
if_end_131:
  %t16 = trunc i32 0 to i16
  store i16 %t16, i16* %t15
  store i32 0, i32* %t17
  br label %for_cond_132
for_cond_132:
  %t18 = load i32, i32* %t17
  %t19 = icmp slt i32 %t18, 16
  br i1 %t19, label %for_body_133, label %for_end_135
for_body_133:
  %t21 = load i32, i32* %t17
  %t22 = load i32, i32* %t2
  %t23 = sub i32 %t21, %t22
  %t24 = add i32 %t23, 16
  %t25 = icmp eq i32 16, 0
  %t26 = icmp eq i32 %t24, -2147483648
  %t27 = icmp eq i32 16, -1
  %t28 = and i1 %t26, %t27
  %t29 = or i1 %t25, %t28
  br i1 %t29, label %int_div_fail_136, label %int_div_ok_137
int_div_fail_136:
  %t30 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t30)
  call void @exit(i32 1)
  unreachable
int_div_ok_137:
  %t31 = srem i32 %t24, 16
  store i32 %t31, i32* %t20
  %t32 = load i16, i16* %t0
  %t33 = load i32, i32* %t20
  %t34 = and i32 %t33, 15
  %t35 = trunc i32 %t34 to i16
  %t36 = shl i16 1, %t35
  %t37 = and i16 %t32, %t36
  %t38 = icmp ne i16 %t37, 0
  br i1 %t38, label %if_then_138, label %if_else_139
if_then_138:
  %t39 = load i16, i16* %t15
  %t40 = load i32, i32* %t17
  %t41 = and i32 %t40, 15
  %t42 = trunc i32 %t41 to i16
  %t43 = shl i16 1, %t42
  %t44 = or i16 %t39, %t43
  store i16 %t44, i16* %t15
  br label %if_end_140
if_else_139:
  br label %if_end_140
if_end_140:
  br label %for_step_134
for_step_134:
  %t45 = load i32, i32* %t17
  %t46 = add i32 %t45, 1
  store i32 %t46, i32* %t17
  br label %for_cond_132
for_end_135:
  %t47 = load i16, i16* %t15
  ret i16 %t47
}

define i16 @bits__ror16(i16 %x, i32 %n) {
entry:
  %t0 = alloca i16
  %t1 = alloca i32
  %t2 = alloca i32
  store i16 %x, i16* %t0
  store i32 %n, i32* %t1
  %t3 = load i32, i32* %t1
  %t4 = icmp eq i32 16, 0
  %t5 = icmp eq i32 %t3, -2147483648
  %t6 = icmp eq i32 16, -1
  %t7 = and i1 %t5, %t6
  %t8 = or i1 %t4, %t7
  br i1 %t8, label %int_div_fail_141, label %int_div_ok_142
int_div_fail_141:
  %t9 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.5, i64 0, i64 0
  call i32 @puts(i8* %t9)
  call void @exit(i32 1)
  unreachable
int_div_ok_142:
  %t10 = srem i32 %t3, 16
  store i32 %t10, i32* %t2
  %t11 = load i32, i32* %t2
  %t12 = icmp slt i32 %t11, 0
  br i1 %t12, label %if_then_143, label %if_else_144
if_then_143:
  %t13 = load i32, i32* %t2
  %t14 = add i32 %t13, 16
  store i32 %t14, i32* %t2
  br label %if_end_145
if_else_144:
  br label %if_end_145
if_end_145:
  %t15 = load i16, i16* %t0
  %t16 = load i32, i32* %t2
  %t17 = sub i32 16, %t16
  %t18 = call i16 @bits__rol16(i16 %t15, i32 %t17)
  ret i16 %t18
}

define { i8, i1 } @bits__rcl8(i8 %x, i1 %carry_in, i32 %n) {
entry:
  %t0 = alloca i8
  %t1 = alloca i1
  %t2 = alloca i32
  %t3 = alloca i8
  %t5 = alloca i1
  %t7 = alloca i32
  %t21 = alloca i32
  %t24 = alloca i1
  %t42 = alloca { i8, i1 }
  store i8 %x, i8* %t0
  store i1 %carry_in, i1* %t1
  store i32 %n, i32* %t2
  %t4 = load i8, i8* %t0
  store i8 %t4, i8* %t3
  %t6 = load i1, i1* %t1
  store i1 %t6, i1* %t5
  %t8 = load i32, i32* %t2
  %t9 = icmp eq i32 9, 0
  %t10 = icmp eq i32 %t8, -2147483648
  %t11 = icmp eq i32 9, -1
  %t12 = and i1 %t10, %t11
  %t13 = or i1 %t9, %t12
  br i1 %t13, label %int_div_fail_146, label %int_div_ok_147
int_div_fail_146:
  %t14 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.6, i64 0, i64 0
  call i32 @puts(i8* %t14)
  call void @exit(i32 1)
  unreachable
int_div_ok_147:
  %t15 = srem i32 %t8, 9
  store i32 %t15, i32* %t7
  %t16 = load i32, i32* %t7
  %t17 = icmp slt i32 %t16, 0
  br i1 %t17, label %if_then_148, label %if_else_149
if_then_148:
  %t18 = load i32, i32* %t7
  %t19 = add i32 %t18, 9
  store i32 %t19, i32* %t7
  br label %if_end_150
if_else_149:
  br label %if_end_150
if_end_150:
  %t20 = load i32, i32* %t7
  store i32 0, i32* %t21
  br label %for_cond_151
for_cond_151:
  %t22 = load i32, i32* %t21
  %t23 = icmp slt i32 %t22, %t20
  br i1 %t23, label %for_body_152, label %for_end_154
for_body_152:
  %t25 = load i8, i8* %t3
  %t26 = and i32 7, 7
  %t27 = trunc i32 %t26 to i8
  %t28 = shl i8 1, %t27
  %t29 = and i8 %t25, %t28
  %t30 = icmp ne i8 %t29, 0
  store i1 %t30, i1* %t24
  %t31 = load i8, i8* %t3
  %t32 = call i8 @bits__shl8(i8 %t31, i32 1)
  store i8 %t32, i8* %t3
  %t33 = load i1, i1* %t5
  br i1 %t33, label %if_then_155, label %if_else_156
if_then_155:
  %t34 = load i8, i8* %t3
  %t35 = and i32 0, 7
  %t36 = trunc i32 %t35 to i8
  %t37 = shl i8 1, %t36
  %t38 = or i8 %t34, %t37
  store i8 %t38, i8* %t3
  br label %if_end_157
if_else_156:
  br label %if_end_157
if_end_157:
  %t39 = load i1, i1* %t24
  store i1 %t39, i1* %t5
  br label %for_step_153
for_step_153:
  %t40 = load i32, i32* %t21
  %t41 = add i32 %t40, 1
  store i32 %t41, i32* %t21
  br label %for_cond_151
for_end_154:
  %t43 = load i8, i8* %t3
  %t44 = getelementptr inbounds { i8, i1 }, { i8, i1 }* %t42, i32 0, i32 0
  store i8 %t43, i8* %t44
  %t45 = load i1, i1* %t5
  %t46 = getelementptr inbounds { i8, i1 }, { i8, i1 }* %t42, i32 0, i32 1
  store i1 %t45, i1* %t46
  %t47 = load { i8, i1 }, { i8, i1 }* %t42
  ret { i8, i1 } %t47
}

define { i8, i1 } @bits__rcr8(i8 %x, i1 %carry_in, i32 %n) {
entry:
  %t0 = alloca i8
  %t1 = alloca i1
  %t2 = alloca i32
  %t3 = alloca i8
  %t5 = alloca i1
  %t7 = alloca i32
  %t21 = alloca i32
  %t24 = alloca i1
  %t42 = alloca { i8, i1 }
  store i8 %x, i8* %t0
  store i1 %carry_in, i1* %t1
  store i32 %n, i32* %t2
  %t4 = load i8, i8* %t0
  store i8 %t4, i8* %t3
  %t6 = load i1, i1* %t1
  store i1 %t6, i1* %t5
  %t8 = load i32, i32* %t2
  %t9 = icmp eq i32 9, 0
  %t10 = icmp eq i32 %t8, -2147483648
  %t11 = icmp eq i32 9, -1
  %t12 = and i1 %t10, %t11
  %t13 = or i1 %t9, %t12
  br i1 %t13, label %int_div_fail_158, label %int_div_ok_159
int_div_fail_158:
  %t14 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.7, i64 0, i64 0
  call i32 @puts(i8* %t14)
  call void @exit(i32 1)
  unreachable
int_div_ok_159:
  %t15 = srem i32 %t8, 9
  store i32 %t15, i32* %t7
  %t16 = load i32, i32* %t7
  %t17 = icmp slt i32 %t16, 0
  br i1 %t17, label %if_then_160, label %if_else_161
if_then_160:
  %t18 = load i32, i32* %t7
  %t19 = add i32 %t18, 9
  store i32 %t19, i32* %t7
  br label %if_end_162
if_else_161:
  br label %if_end_162
if_end_162:
  %t20 = load i32, i32* %t7
  store i32 0, i32* %t21
  br label %for_cond_163
for_cond_163:
  %t22 = load i32, i32* %t21
  %t23 = icmp slt i32 %t22, %t20
  br i1 %t23, label %for_body_164, label %for_end_166
for_body_164:
  %t25 = load i8, i8* %t3
  %t26 = and i32 0, 7
  %t27 = trunc i32 %t26 to i8
  %t28 = shl i8 1, %t27
  %t29 = and i8 %t25, %t28
  %t30 = icmp ne i8 %t29, 0
  store i1 %t30, i1* %t24
  %t31 = load i8, i8* %t3
  %t32 = call i8 @bits__shr8(i8 %t31, i32 1)
  store i8 %t32, i8* %t3
  %t33 = load i1, i1* %t5
  br i1 %t33, label %if_then_167, label %if_else_168
if_then_167:
  %t34 = load i8, i8* %t3
  %t35 = and i32 7, 7
  %t36 = trunc i32 %t35 to i8
  %t37 = shl i8 1, %t36
  %t38 = or i8 %t34, %t37
  store i8 %t38, i8* %t3
  br label %if_end_169
if_else_168:
  br label %if_end_169
if_end_169:
  %t39 = load i1, i1* %t24
  store i1 %t39, i1* %t5
  br label %for_step_165
for_step_165:
  %t40 = load i32, i32* %t21
  %t41 = add i32 %t40, 1
  store i32 %t41, i32* %t21
  br label %for_cond_163
for_end_166:
  %t43 = load i8, i8* %t3
  %t44 = getelementptr inbounds { i8, i1 }, { i8, i1 }* %t42, i32 0, i32 0
  store i8 %t43, i8* %t44
  %t45 = load i1, i1* %t5
  %t46 = getelementptr inbounds { i8, i1 }, { i8, i1 }* %t42, i32 0, i32 1
  store i1 %t45, i1* %t46
  %t47 = load { i8, i1 }, { i8, i1 }* %t42
  ret { i8, i1 } %t47
}

define { i16, i1 } @bits__rcl16(i16 %x, i1 %carry_in, i32 %n) {
entry:
  %t0 = alloca i16
  %t1 = alloca i1
  %t2 = alloca i32
  %t3 = alloca i16
  %t5 = alloca i1
  %t7 = alloca i32
  %t21 = alloca i32
  %t24 = alloca i1
  %t42 = alloca { i16, i1 }
  store i16 %x, i16* %t0
  store i1 %carry_in, i1* %t1
  store i32 %n, i32* %t2
  %t4 = load i16, i16* %t0
  store i16 %t4, i16* %t3
  %t6 = load i1, i1* %t1
  store i1 %t6, i1* %t5
  %t8 = load i32, i32* %t2
  %t9 = icmp eq i32 17, 0
  %t10 = icmp eq i32 %t8, -2147483648
  %t11 = icmp eq i32 17, -1
  %t12 = and i1 %t10, %t11
  %t13 = or i1 %t9, %t12
  br i1 %t13, label %int_div_fail_170, label %int_div_ok_171
int_div_fail_170:
  %t14 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.8, i64 0, i64 0
  call i32 @puts(i8* %t14)
  call void @exit(i32 1)
  unreachable
int_div_ok_171:
  %t15 = srem i32 %t8, 17
  store i32 %t15, i32* %t7
  %t16 = load i32, i32* %t7
  %t17 = icmp slt i32 %t16, 0
  br i1 %t17, label %if_then_172, label %if_else_173
if_then_172:
  %t18 = load i32, i32* %t7
  %t19 = add i32 %t18, 17
  store i32 %t19, i32* %t7
  br label %if_end_174
if_else_173:
  br label %if_end_174
if_end_174:
  %t20 = load i32, i32* %t7
  store i32 0, i32* %t21
  br label %for_cond_175
for_cond_175:
  %t22 = load i32, i32* %t21
  %t23 = icmp slt i32 %t22, %t20
  br i1 %t23, label %for_body_176, label %for_end_178
for_body_176:
  %t25 = load i16, i16* %t3
  %t26 = and i32 15, 15
  %t27 = trunc i32 %t26 to i16
  %t28 = shl i16 1, %t27
  %t29 = and i16 %t25, %t28
  %t30 = icmp ne i16 %t29, 0
  store i1 %t30, i1* %t24
  %t31 = load i16, i16* %t3
  %t32 = call i16 @bits__shl16(i16 %t31, i32 1)
  store i16 %t32, i16* %t3
  %t33 = load i1, i1* %t5
  br i1 %t33, label %if_then_179, label %if_else_180
if_then_179:
  %t34 = load i16, i16* %t3
  %t35 = and i32 0, 15
  %t36 = trunc i32 %t35 to i16
  %t37 = shl i16 1, %t36
  %t38 = or i16 %t34, %t37
  store i16 %t38, i16* %t3
  br label %if_end_181
if_else_180:
  br label %if_end_181
if_end_181:
  %t39 = load i1, i1* %t24
  store i1 %t39, i1* %t5
  br label %for_step_177
for_step_177:
  %t40 = load i32, i32* %t21
  %t41 = add i32 %t40, 1
  store i32 %t41, i32* %t21
  br label %for_cond_175
for_end_178:
  %t43 = load i16, i16* %t3
  %t44 = getelementptr inbounds { i16, i1 }, { i16, i1 }* %t42, i32 0, i32 0
  store i16 %t43, i16* %t44
  %t45 = load i1, i1* %t5
  %t46 = getelementptr inbounds { i16, i1 }, { i16, i1 }* %t42, i32 0, i32 1
  store i1 %t45, i1* %t46
  %t47 = load { i16, i1 }, { i16, i1 }* %t42
  ret { i16, i1 } %t47
}

define { i16, i1 } @bits__rcr16(i16 %x, i1 %carry_in, i32 %n) {
entry:
  %t0 = alloca i16
  %t1 = alloca i1
  %t2 = alloca i32
  %t3 = alloca i16
  %t5 = alloca i1
  %t7 = alloca i32
  %t21 = alloca i32
  %t24 = alloca i1
  %t42 = alloca { i16, i1 }
  store i16 %x, i16* %t0
  store i1 %carry_in, i1* %t1
  store i32 %n, i32* %t2
  %t4 = load i16, i16* %t0
  store i16 %t4, i16* %t3
  %t6 = load i1, i1* %t1
  store i1 %t6, i1* %t5
  %t8 = load i32, i32* %t2
  %t9 = icmp eq i32 17, 0
  %t10 = icmp eq i32 %t8, -2147483648
  %t11 = icmp eq i32 17, -1
  %t12 = and i1 %t10, %t11
  %t13 = or i1 %t9, %t12
  br i1 %t13, label %int_div_fail_182, label %int_div_ok_183
int_div_fail_182:
  %t14 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.9, i64 0, i64 0
  call i32 @puts(i8* %t14)
  call void @exit(i32 1)
  unreachable
int_div_ok_183:
  %t15 = srem i32 %t8, 17
  store i32 %t15, i32* %t7
  %t16 = load i32, i32* %t7
  %t17 = icmp slt i32 %t16, 0
  br i1 %t17, label %if_then_184, label %if_else_185
if_then_184:
  %t18 = load i32, i32* %t7
  %t19 = add i32 %t18, 17
  store i32 %t19, i32* %t7
  br label %if_end_186
if_else_185:
  br label %if_end_186
if_end_186:
  %t20 = load i32, i32* %t7
  store i32 0, i32* %t21
  br label %for_cond_187
for_cond_187:
  %t22 = load i32, i32* %t21
  %t23 = icmp slt i32 %t22, %t20
  br i1 %t23, label %for_body_188, label %for_end_190
for_body_188:
  %t25 = load i16, i16* %t3
  %t26 = and i32 0, 15
  %t27 = trunc i32 %t26 to i16
  %t28 = shl i16 1, %t27
  %t29 = and i16 %t25, %t28
  %t30 = icmp ne i16 %t29, 0
  store i1 %t30, i1* %t24
  %t31 = load i16, i16* %t3
  %t32 = call i16 @bits__shr16(i16 %t31, i32 1)
  store i16 %t32, i16* %t3
  %t33 = load i1, i1* %t5
  br i1 %t33, label %if_then_191, label %if_else_192
if_then_191:
  %t34 = load i16, i16* %t3
  %t35 = and i32 15, 15
  %t36 = trunc i32 %t35 to i16
  %t37 = shl i16 1, %t36
  %t38 = or i16 %t34, %t37
  store i16 %t38, i16* %t3
  br label %if_end_193
if_else_192:
  br label %if_end_193
if_end_193:
  %t39 = load i1, i1* %t24
  store i1 %t39, i1* %t5
  br label %for_step_189
for_step_189:
  %t40 = load i32, i32* %t21
  %t41 = add i32 %t40, 1
  store i32 %t41, i32* %t21
  br label %for_cond_187
for_end_190:
  %t43 = load i16, i16* %t3
  %t44 = getelementptr inbounds { i16, i1 }, { i16, i1 }* %t42, i32 0, i32 0
  store i16 %t43, i16* %t44
  %t45 = load i1, i1* %t5
  %t46 = getelementptr inbounds { i16, i1 }, { i16, i1 }* %t42, i32 0, i32 1
  store i1 %t45, i1* %t46
  %t47 = load { i16, i1 }, { i16, i1 }* %t42
  ret { i16, i1 } %t47
}

define i32 @bits__popcount8(i8 %x) {
entry:
  %t0 = alloca i8
  %t1 = alloca i32
  %t2 = alloca i32
  store i8 %x, i8* %t0
  store i32 0, i32* %t1
  store i32 0, i32* %t2
  br label %for_cond_194
for_cond_194:
  %t3 = load i32, i32* %t2
  %t4 = icmp slt i32 %t3, 8
  br i1 %t4, label %for_body_195, label %for_end_197
for_body_195:
  %t5 = load i8, i8* %t0
  %t6 = load i32, i32* %t2
  %t7 = and i32 %t6, 7
  %t8 = trunc i32 %t7 to i8
  %t9 = shl i8 1, %t8
  %t10 = and i8 %t5, %t9
  %t11 = icmp ne i8 %t10, 0
  br i1 %t11, label %if_then_198, label %if_else_199
if_then_198:
  %t12 = load i32, i32* %t1
  %t13 = add i32 %t12, 1
  store i32 %t13, i32* %t1
  br label %if_end_200
if_else_199:
  br label %if_end_200
if_end_200:
  br label %for_step_196
for_step_196:
  %t14 = load i32, i32* %t2
  %t15 = add i32 %t14, 1
  store i32 %t15, i32* %t2
  br label %for_cond_194
for_end_197:
  %t16 = load i32, i32* %t1
  ret i32 %t16
}

define i32 @bits__popcount16(i16 %x) {
entry:
  %t0 = alloca i16
  %t1 = alloca i32
  %t2 = alloca i32
  store i16 %x, i16* %t0
  store i32 0, i32* %t1
  store i32 0, i32* %t2
  br label %for_cond_201
for_cond_201:
  %t3 = load i32, i32* %t2
  %t4 = icmp slt i32 %t3, 16
  br i1 %t4, label %for_body_202, label %for_end_204
for_body_202:
  %t5 = load i16, i16* %t0
  %t6 = load i32, i32* %t2
  %t7 = and i32 %t6, 15
  %t8 = trunc i32 %t7 to i16
  %t9 = shl i16 1, %t8
  %t10 = and i16 %t5, %t9
  %t11 = icmp ne i16 %t10, 0
  br i1 %t11, label %if_then_205, label %if_else_206
if_then_205:
  %t12 = load i32, i32* %t1
  %t13 = add i32 %t12, 1
  store i32 %t13, i32* %t1
  br label %if_end_207
if_else_206:
  br label %if_end_207
if_end_207:
  br label %for_step_203
for_step_203:
  %t14 = load i32, i32* %t2
  %t15 = add i32 %t14, 1
  store i32 %t15, i32* %t2
  br label %for_cond_201
for_end_204:
  %t16 = load i32, i32* %t1
  ret i32 %t16
}

define i1 @bits__parity8(i8 %x) {
entry:
  %t0 = alloca i8
  store i8 %x, i8* %t0
  %t1 = load i8, i8* %t0
  %t2 = call i32 @bits__popcount8(i8 %t1)
  %t3 = icmp eq i32 2, 0
  %t4 = icmp eq i32 %t2, -2147483648
  %t5 = icmp eq i32 2, -1
  %t6 = and i1 %t4, %t5
  %t7 = or i1 %t3, %t6
  br i1 %t7, label %int_div_fail_208, label %int_div_ok_209
int_div_fail_208:
  %t8 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.10, i64 0, i64 0
  call i32 @puts(i8* %t8)
  call void @exit(i32 1)
  unreachable
int_div_ok_209:
  %t9 = srem i32 %t2, 2
  %t10 = icmp eq i32 %t9, 0
  ret i1 %t10
}

define i32 @bits__clz8(i8 %x) {
entry:
  %t0 = alloca i8
  %t1 = alloca i32
  %t2 = alloca i1
  %t3 = alloca i32
  store i8 %x, i8* %t0
  store i32 0, i32* %t1
  store i1 false, i1* %t2
  store i32 7, i32* %t3
  br label %for_cond_210
for_cond_210:
  %t4 = load i32, i32* %t3
  %t5 = icmp sge i32 %t4, 0
  br i1 %t5, label %for_body_211, label %for_end_213
for_body_211:
  %t6 = load i1, i1* %t2
  %t7 = xor i1 true, %t6
  br i1 %t7, label %if_then_214, label %if_else_215
if_then_214:
  %t8 = load i8, i8* %t0
  %t9 = load i32, i32* %t3
  %t10 = and i32 %t9, 7
  %t11 = trunc i32 %t10 to i8
  %t12 = shl i8 1, %t11
  %t13 = and i8 %t8, %t12
  %t14 = icmp ne i8 %t13, 0
  br i1 %t14, label %if_then_217, label %if_else_218
if_then_217:
  store i1 true, i1* %t2
  br label %if_end_219
if_else_218:
  %t15 = load i32, i32* %t1
  %t16 = add i32 %t15, 1
  store i32 %t16, i32* %t1
  br label %if_end_219
if_end_219:
  br label %if_end_216
if_else_215:
  br label %if_end_216
if_end_216:
  br label %for_step_212
for_step_212:
  %t17 = load i32, i32* %t3
  %t18 = add i32 %t17, -1
  store i32 %t18, i32* %t3
  br label %for_cond_210
for_end_213:
  %t19 = load i32, i32* %t1
  ret i32 %t19
}

define i32 @bits__clz16(i16 %x) {
entry:
  %t0 = alloca i16
  %t1 = alloca i32
  %t2 = alloca i1
  %t3 = alloca i32
  store i16 %x, i16* %t0
  store i32 0, i32* %t1
  store i1 false, i1* %t2
  store i32 15, i32* %t3
  br label %for_cond_220
for_cond_220:
  %t4 = load i32, i32* %t3
  %t5 = icmp sge i32 %t4, 0
  br i1 %t5, label %for_body_221, label %for_end_223
for_body_221:
  %t6 = load i1, i1* %t2
  %t7 = xor i1 true, %t6
  br i1 %t7, label %if_then_224, label %if_else_225
if_then_224:
  %t8 = load i16, i16* %t0
  %t9 = load i32, i32* %t3
  %t10 = and i32 %t9, 15
  %t11 = trunc i32 %t10 to i16
  %t12 = shl i16 1, %t11
  %t13 = and i16 %t8, %t12
  %t14 = icmp ne i16 %t13, 0
  br i1 %t14, label %if_then_227, label %if_else_228
if_then_227:
  store i1 true, i1* %t2
  br label %if_end_229
if_else_228:
  %t15 = load i32, i32* %t1
  %t16 = add i32 %t15, 1
  store i32 %t16, i32* %t1
  br label %if_end_229
if_end_229:
  br label %if_end_226
if_else_225:
  br label %if_end_226
if_end_226:
  br label %for_step_222
for_step_222:
  %t17 = load i32, i32* %t3
  %t18 = add i32 %t17, -1
  store i32 %t18, i32* %t3
  br label %for_cond_220
for_end_223:
  %t19 = load i32, i32* %t1
  ret i32 %t19
}

define i32 @bits__ctz8(i8 %x) {
entry:
  %t0 = alloca i8
  %t1 = alloca i32
  %t2 = alloca i1
  %t3 = alloca i32
  store i8 %x, i8* %t0
  store i32 0, i32* %t1
  store i1 false, i1* %t2
  store i32 0, i32* %t3
  br label %for_cond_230
for_cond_230:
  %t4 = load i32, i32* %t3
  %t5 = icmp slt i32 %t4, 8
  br i1 %t5, label %for_body_231, label %for_end_233
for_body_231:
  %t6 = load i1, i1* %t2
  %t7 = xor i1 true, %t6
  br i1 %t7, label %if_then_234, label %if_else_235
if_then_234:
  %t8 = load i8, i8* %t0
  %t9 = load i32, i32* %t3
  %t10 = and i32 %t9, 7
  %t11 = trunc i32 %t10 to i8
  %t12 = shl i8 1, %t11
  %t13 = and i8 %t8, %t12
  %t14 = icmp ne i8 %t13, 0
  br i1 %t14, label %if_then_237, label %if_else_238
if_then_237:
  store i1 true, i1* %t2
  br label %if_end_239
if_else_238:
  %t15 = load i32, i32* %t1
  %t16 = add i32 %t15, 1
  store i32 %t16, i32* %t1
  br label %if_end_239
if_end_239:
  br label %if_end_236
if_else_235:
  br label %if_end_236
if_end_236:
  br label %for_step_232
for_step_232:
  %t17 = load i32, i32* %t3
  %t18 = add i32 %t17, 1
  store i32 %t18, i32* %t3
  br label %for_cond_230
for_end_233:
  %t19 = load i32, i32* %t1
  ret i32 %t19
}

define i32 @bits__ctz16(i16 %x) {
entry:
  %t0 = alloca i16
  %t1 = alloca i32
  %t2 = alloca i1
  %t3 = alloca i32
  store i16 %x, i16* %t0
  store i32 0, i32* %t1
  store i1 false, i1* %t2
  store i32 0, i32* %t3
  br label %for_cond_240
for_cond_240:
  %t4 = load i32, i32* %t3
  %t5 = icmp slt i32 %t4, 16
  br i1 %t5, label %for_body_241, label %for_end_243
for_body_241:
  %t6 = load i1, i1* %t2
  %t7 = xor i1 true, %t6
  br i1 %t7, label %if_then_244, label %if_else_245
if_then_244:
  %t8 = load i16, i16* %t0
  %t9 = load i32, i32* %t3
  %t10 = and i32 %t9, 15
  %t11 = trunc i32 %t10 to i16
  %t12 = shl i16 1, %t11
  %t13 = and i16 %t8, %t12
  %t14 = icmp ne i16 %t13, 0
  br i1 %t14, label %if_then_247, label %if_else_248
if_then_247:
  store i1 true, i1* %t2
  br label %if_end_249
if_else_248:
  %t15 = load i32, i32* %t1
  %t16 = add i32 %t15, 1
  store i32 %t16, i32* %t1
  br label %if_end_249
if_end_249:
  br label %if_end_246
if_else_245:
  br label %if_end_246
if_end_246:
  br label %for_step_242
for_step_242:
  %t17 = load i32, i32* %t3
  %t18 = add i32 %t17, 1
  store i32 %t18, i32* %t3
  br label %for_cond_240
for_end_243:
  %t19 = load i32, i32* %t1
  ret i32 %t19
}

define i32 @bits__sign_extend8(i8 %x) {
entry:
  %t0 = alloca i8
  %t1 = alloca i32
  store i8 %x, i8* %t0
  %t2 = load i8, i8* %t0
  %t3 = zext i8 %t2 to i32
  store i32 %t3, i32* %t1
  %t4 = load i32, i32* %t1
  %t5 = icmp sge i32 %t4, 128
  br i1 %t5, label %if_then_250, label %if_else_251
if_then_250:
  %t6 = load i32, i32* %t1
  %t7 = sub i32 %t6, 256
  br label %if_end_252
if_else_251:
  %t8 = load i32, i32* %t1
  br label %if_end_252
if_end_252:
  %t9 = phi i32 [ %t7, %if_then_250 ], [ %t8, %if_else_251 ]
  ret i32 %t9
}

define %NomfDocument @new_document() {
entry:
  %t0 = alloca %NomfDocument
  %t1 = getelementptr inbounds %NomfDocument, %NomfDocument* %t0, i32 0, i32 0
  store i32 1, i32* %t1
  %t2 = getelementptr inbounds %NomfDocument, %NomfDocument* %t0, i32 0, i32 1
  store i8* null, i8** %t2
  %t3 = getelementptr inbounds %NomfDocument, %NomfDocument* %t0, i32 0, i32 2
  store i32 0, i32* %t3
  %t4 = getelementptr inbounds %NomfDocument, %NomfDocument* %t0, i32 0, i32 3
  store i1 false, i1* %t4
  %t5 = load %NomfDocument, %NomfDocument* %t0
  ret %NomfDocument %t5
}

define i8* @_crc_table_init() {
entry:
  %t0 = alloca i8*
  %t1 = alloca i32
  %t4 = alloca i64
  %t7 = alloca i32
  store i8* null, i8** %t0
  store i32 0, i32* %t1
  br label %while_cond_253
while_cond_253:
  %t2 = load i32, i32* %t1
  %t3 = icmp slt i32 %t2, 256
  br i1 %t3, label %while_body_254, label %while_else_255
while_body_254:
  %t5 = load i32, i32* %t1
  %t6 = sext i32 %t5 to i64
  store i64 %t6, i64* %t4
  store i32 0, i32* %t7
  br label %while_cond_257
while_cond_257:
  %t8 = load i32, i32* %t7
  %t9 = icmp slt i32 %t8, 8
  br i1 %t9, label %while_body_258, label %while_else_259
while_body_258:
  %t10 = load i64, i64* %t4
  %t11 = sext i32 1 to i64
  %t12 = and i64 %t10, %t11
  %t13 = sext i32 0 to i64
  %t14 = icmp ne i64 %t12, %t13
  br i1 %t14, label %if_then_261, label %if_else_262
if_then_261:
  %t15 = load i64, i64* %t4
  %t16 = and i32 1, 63
  %t17 = zext i32 %t16 to i64
  %t18 = ashr i64 %t15, %t17
  %t19 = xor i64 3988292384, %t18
  store i64 %t19, i64* %t4
  br label %if_end_263
if_else_262:
  %t20 = load i64, i64* %t4
  %t21 = and i32 1, 63
  %t22 = zext i32 %t21 to i64
  %t23 = ashr i64 %t20, %t22
  store i64 %t23, i64* %t4
  br label %if_end_263
if_end_263:
  %t24 = load i32, i32* %t7
  %t25 = add i32 %t24, 1
  store i32 %t25, i32* %t7
  br label %while_cond_257
while_else_259:
  br label %while_end_260
while_end_260:
  %t26 = getelementptr i64, i64* null, i32 1
  %t27 = ptrtoint i64* %t26 to i64
  %t28 = load i8*, i8** %t0
  %t29 = icmp eq i8* %t28, null
  br i1 %t29, label %list_cow_alloc_264, label %list_cow_check_265
list_cow_alloc_264:
  %t34 = bitcast void (i8*)* @list_release_i64 to i8*
  %t35 = call i8* @star_rc_alloc(i64 24, i8* %t34)
  %t36 = bitcast i8* %t35 to { i64*, i64, i64 }*
  %t37 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t36, i32 0, i32 0
  store i64* null, i64** %t37
  %t38 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t36, i32 0, i32 1
  store i64 0, i64* %t38
  %t39 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t36, i32 0, i32 2
  store i64 0, i64* %t39
  store i8* %t35, i8** %t0
  br label %list_cow_done_266
list_cow_check_265:
  %t40 = getelementptr inbounds i8, i8* %t28, i64 -16
  %t41 = bitcast i8* %t40 to i64*
  %t42 = load atomic i64, i64* %t41 seq_cst, align 8
  %t43 = icmp eq i64 %t42, 1
  br i1 %t43, label %list_cow_done_266, label %list_cow_clone_267
list_cow_clone_267:
  %t44 = bitcast i8* %t28 to { i64*, i64, i64 }*
  %t45 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t44, i32 0, i32 0
  %t46 = load i64*, i64** %t45
  %t47 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t44, i32 0, i32 1
  %t48 = load i64, i64* %t47
  %t49 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t44, i32 0, i32 2
  %t50 = load i64, i64* %t49
  %t51 = bitcast void (i8*)* @list_release_i64 to i8*
  %t52 = call i8* @star_rc_alloc(i64 24, i8* %t51)
  %t53 = bitcast i8* %t52 to { i64*, i64, i64 }*
  %t54 = mul i64 %t50, %t27
  %t55 = call i8* @malloc(i64 %t54)
  %t56 = bitcast i8* %t55 to i64*
  %t57 = icmp sgt i64 %t48, 0
  br i1 %t57, label %list_cow_copy_268, label %list_cow_after_copy_269
list_cow_copy_268:
  %t58 = mul i64 %t48, %t27
  %t59 = bitcast i64* %t46 to i8*
  call i8* @memcpy(i8* %t55, i8* %t59, i64 %t58)
  br label %list_cow_after_copy_269
list_cow_after_copy_269:
  %t60 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t53, i32 0, i32 0
  store i64* %t56, i64** %t60
  %t61 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t53, i32 0, i32 1
  store i64 %t48, i64* %t61
  %t62 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t53, i32 0, i32 2
  store i64 %t50, i64* %t62
  call void @star_rc_release(i8* %t28)
  store i8* %t52, i8** %t0
  br label %list_cow_done_266
list_cow_done_266:
  %t63 = load i8*, i8** %t0
  %t64 = bitcast i8* %t63 to { i64*, i64, i64 }*
  %t65 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t64, i32 0, i32 0
  %t66 = load i64*, i64** %t65
  %t67 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t64, i32 0, i32 1
  %t68 = load i64, i64* %t67
  %t69 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t64, i32 0, i32 2
  %t70 = load i64, i64* %t4
  %t71 = load i64, i64* %t69
  %t72 = load i64*, i64** %t65
  %t73 = load i64, i64* %t67
  %t74 = icmp sge i64 %t73, %t71
  br i1 %t74, label %list_push_grow_270, label %list_push_store_271
list_push_grow_270:
  %t75 = mul i64 %t71, 2
  %t76 = icmp sgt i64 %t75, 0
  %t77 = select i1 %t76, i64 %t75, i64 1
  %t78 = getelementptr i64, i64* null, i32 1
  %t79 = ptrtoint i64* %t78 to i64
  %t80 = mul i64 %t77, %t79
  %t81 = call i8* @malloc(i64 %t80)
  %t82 = bitcast i8* %t81 to i64*
  %t83 = icmp sgt i64 %t71, 0
  br i1 %t83, label %list_push_copy_272, label %list_push_after_copy_273
list_push_copy_272:
  %t84 = mul i64 %t73, %t79
  %t85 = bitcast i64* %t72 to i8*
  call i8* @memcpy(i8* %t81, i8* %t85, i64 %t84)
  call void @free(i8* %t85)
  br label %list_push_after_copy_273
list_push_after_copy_273:
  store i64* %t82, i64** %t65
  store i64 %t77, i64* %t69
  br label %list_push_store_271
list_push_store_271:
  %t86 = load i64*, i64** %t65
  %t87 = getelementptr inbounds i64, i64* %t86, i64 %t73
  store i64 %t70, i64* %t87
  %t88 = add i64 %t73, 1
  store i64 %t88, i64* %t67
  %t89 = load i32, i32* %t1
  %t90 = add i32 %t89, 1
  store i32 %t90, i32* %t1
  br label %while_cond_253
while_else_255:
  br label %while_end_256
while_end_256:
  %t91 = load i8*, i8** %t0
  %t92 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t92)
  %t93 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t93)
  ret i8* %t91
}

define i64 @_crc32(i8* %data) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i8*
  %t3 = alloca i64
  %t4 = alloca i32
  %t17 = alloca i32
  store i8* %data, i8** %t0
  %t2 = call i8* @_crc_table_init()
  store i8* %t2, i8** %t1
  store i64 4294967295, i64* %t3
  store i32 0, i32* %t4
  br label %while_cond_274
while_cond_274:
  %t5 = load i32, i32* %t4
  %t6 = load i8*, i8** %t0
  %t7 = icmp eq i8* %t6, null
  br i1 %t7, label %list_read_null_278, label %list_read_real_279
list_read_null_278:
  br label %list_read_end_280
list_read_real_279:
  %t8 = bitcast i8* %t6 to { i8*, i64, i64 }*
  %t9 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t8, i32 0, i32 0
  %t10 = load i8*, i8** %t9
  %t11 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t8, i32 0, i32 1
  %t12 = load i64, i64* %t11
  br label %list_read_end_280
list_read_end_280:
  %t13 = phi i8* [ null, %list_read_null_278 ], [ %t10, %list_read_real_279 ]
  %t14 = phi i64 [ 0, %list_read_null_278 ], [ %t12, %list_read_real_279 ]
  %t15 = trunc i64 %t14 to i32
  %t16 = icmp slt i32 %t5, %t15
  br i1 %t16, label %while_body_275, label %while_else_276
while_body_275:
  %t18 = load i64, i64* %t3
  %t19 = load i8*, i8** %t0
  %t20 = icmp eq i8* %t19, null
  br i1 %t20, label %list_read_null_281, label %list_read_real_282
list_read_null_281:
  br label %list_read_end_283
list_read_real_282:
  %t21 = bitcast i8* %t19 to { i8*, i64, i64 }*
  %t22 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t21, i32 0, i32 0
  %t23 = load i8*, i8** %t22
  %t24 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t21, i32 0, i32 1
  %t25 = load i64, i64* %t24
  br label %list_read_end_283
list_read_end_283:
  %t26 = phi i8* [ null, %list_read_null_281 ], [ %t23, %list_read_real_282 ]
  %t27 = phi i64 [ 0, %list_read_null_281 ], [ %t25, %list_read_real_282 ]
  %t28 = load i32, i32* %t4
  %t29 = sext i32 %t28 to i64
  %t30 = icmp ult i64 %t29, %t27
  br i1 %t30, label %list_idx_ok_284, label %list_idx_oob_285
list_idx_ok_284:
  %t31 = getelementptr inbounds i8, i8* %t26, i64 %t29
  %t32 = load i8, i8* %t31
  br label %list_idx_end_286
list_idx_oob_285:
  br label %list_idx_end_286
list_idx_end_286:
  %t33 = phi i8 [ %t32, %list_idx_ok_284 ], [ 0, %list_idx_oob_285 ]
  %t34 = zext i8 %t33 to i64
  %t35 = xor i64 %t18, %t34
  %t36 = and i64 %t35, 255
  %t37 = trunc i64 %t36 to i32
  store i32 %t37, i32* %t17
  %t38 = load i8*, i8** %t1
  %t39 = icmp eq i8* %t38, null
  br i1 %t39, label %list_read_null_287, label %list_read_real_288
list_read_null_287:
  br label %list_read_end_289
list_read_real_288:
  %t40 = bitcast i8* %t38 to { i64*, i64, i64 }*
  %t41 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t40, i32 0, i32 0
  %t42 = load i64*, i64** %t41
  %t43 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t40, i32 0, i32 1
  %t44 = load i64, i64* %t43
  br label %list_read_end_289
list_read_end_289:
  %t45 = phi i64* [ null, %list_read_null_287 ], [ %t42, %list_read_real_288 ]
  %t46 = phi i64 [ 0, %list_read_null_287 ], [ %t44, %list_read_real_288 ]
  %t47 = load i32, i32* %t17
  %t48 = sext i32 %t47 to i64
  %t49 = icmp ult i64 %t48, %t46
  br i1 %t49, label %list_idx_ok_290, label %list_idx_oob_291
list_idx_ok_290:
  %t50 = getelementptr inbounds i64, i64* %t45, i64 %t48
  %t51 = load i64, i64* %t50
  br label %list_idx_end_292
list_idx_oob_291:
  br label %list_idx_end_292
list_idx_end_292:
  %t52 = phi i64 [ %t51, %list_idx_ok_290 ], [ 0, %list_idx_oob_291 ]
  %t53 = load i64, i64* %t3
  %t54 = and i32 8, 63
  %t55 = zext i32 %t54 to i64
  %t56 = ashr i64 %t53, %t55
  %t57 = xor i64 %t52, %t56
  store i64 %t57, i64* %t3
  %t58 = load i32, i32* %t4
  %t59 = add i32 %t58, 1
  store i32 %t59, i32* %t4
  br label %while_cond_274
while_else_276:
  br label %while_end_277
while_end_277:
  %t60 = load i64, i64* %t3
  %t61 = xor i64 %t60, 4294967295
  %t62 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t62)
  %t63 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t63)
  ret i64 %t61
}

define i32 @_read_u16_le(i8* %data, i32 %off) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i32
  store i8* %data, i8** %t0
  store i32 %off, i32* %t1
  %t2 = load i8*, i8** %t0
  %t3 = icmp eq i8* %t2, null
  br i1 %t3, label %list_read_null_293, label %list_read_real_294
list_read_null_293:
  br label %list_read_end_295
list_read_real_294:
  %t4 = bitcast i8* %t2 to { i8*, i64, i64 }*
  %t5 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t4, i32 0, i32 0
  %t6 = load i8*, i8** %t5
  %t7 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t4, i32 0, i32 1
  %t8 = load i64, i64* %t7
  br label %list_read_end_295
list_read_end_295:
  %t9 = phi i8* [ null, %list_read_null_293 ], [ %t6, %list_read_real_294 ]
  %t10 = phi i64 [ 0, %list_read_null_293 ], [ %t8, %list_read_real_294 ]
  %t11 = load i32, i32* %t1
  %t12 = sext i32 %t11 to i64
  %t13 = icmp ult i64 %t12, %t10
  br i1 %t13, label %list_idx_ok_296, label %list_idx_oob_297
list_idx_ok_296:
  %t14 = getelementptr inbounds i8, i8* %t9, i64 %t12
  %t15 = load i8, i8* %t14
  br label %list_idx_end_298
list_idx_oob_297:
  br label %list_idx_end_298
list_idx_end_298:
  %t16 = phi i8 [ %t15, %list_idx_ok_296 ], [ 0, %list_idx_oob_297 ]
  %t17 = zext i8 %t16 to i32
  %t18 = load i8*, i8** %t0
  %t19 = icmp eq i8* %t18, null
  br i1 %t19, label %list_read_null_299, label %list_read_real_300
list_read_null_299:
  br label %list_read_end_301
list_read_real_300:
  %t20 = bitcast i8* %t18 to { i8*, i64, i64 }*
  %t21 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t20, i32 0, i32 0
  %t22 = load i8*, i8** %t21
  %t23 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t20, i32 0, i32 1
  %t24 = load i64, i64* %t23
  br label %list_read_end_301
list_read_end_301:
  %t25 = phi i8* [ null, %list_read_null_299 ], [ %t22, %list_read_real_300 ]
  %t26 = phi i64 [ 0, %list_read_null_299 ], [ %t24, %list_read_real_300 ]
  %t27 = load i32, i32* %t1
  %t28 = add i32 %t27, 1
  %t29 = sext i32 %t28 to i64
  %t30 = icmp ult i64 %t29, %t26
  br i1 %t30, label %list_idx_ok_302, label %list_idx_oob_303
list_idx_ok_302:
  %t31 = getelementptr inbounds i8, i8* %t25, i64 %t29
  %t32 = load i8, i8* %t31
  br label %list_idx_end_304
list_idx_oob_303:
  br label %list_idx_end_304
list_idx_end_304:
  %t33 = phi i8 [ %t32, %list_idx_ok_302 ], [ 0, %list_idx_oob_303 ]
  %t34 = zext i8 %t33 to i32
  %t35 = and i32 8, 31
  %t36 = shl i32 %t34, %t35
  %t37 = or i32 %t17, %t36
  %t38 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t38)
  ret i32 %t37
}

define i32 @_read_u32_le(i8* %data, i32 %off) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i32
  store i8* %data, i8** %t0
  store i32 %off, i32* %t1
  %t2 = load i8*, i8** %t0
  %t3 = icmp eq i8* %t2, null
  br i1 %t3, label %list_read_null_305, label %list_read_real_306
list_read_null_305:
  br label %list_read_end_307
list_read_real_306:
  %t4 = bitcast i8* %t2 to { i8*, i64, i64 }*
  %t5 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t4, i32 0, i32 0
  %t6 = load i8*, i8** %t5
  %t7 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t4, i32 0, i32 1
  %t8 = load i64, i64* %t7
  br label %list_read_end_307
list_read_end_307:
  %t9 = phi i8* [ null, %list_read_null_305 ], [ %t6, %list_read_real_306 ]
  %t10 = phi i64 [ 0, %list_read_null_305 ], [ %t8, %list_read_real_306 ]
  %t11 = load i32, i32* %t1
  %t12 = sext i32 %t11 to i64
  %t13 = icmp ult i64 %t12, %t10
  br i1 %t13, label %list_idx_ok_308, label %list_idx_oob_309
list_idx_ok_308:
  %t14 = getelementptr inbounds i8, i8* %t9, i64 %t12
  %t15 = load i8, i8* %t14
  br label %list_idx_end_310
list_idx_oob_309:
  br label %list_idx_end_310
list_idx_end_310:
  %t16 = phi i8 [ %t15, %list_idx_ok_308 ], [ 0, %list_idx_oob_309 ]
  %t17 = zext i8 %t16 to i32
  %t18 = load i8*, i8** %t0
  %t19 = icmp eq i8* %t18, null
  br i1 %t19, label %list_read_null_311, label %list_read_real_312
list_read_null_311:
  br label %list_read_end_313
list_read_real_312:
  %t20 = bitcast i8* %t18 to { i8*, i64, i64 }*
  %t21 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t20, i32 0, i32 0
  %t22 = load i8*, i8** %t21
  %t23 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t20, i32 0, i32 1
  %t24 = load i64, i64* %t23
  br label %list_read_end_313
list_read_end_313:
  %t25 = phi i8* [ null, %list_read_null_311 ], [ %t22, %list_read_real_312 ]
  %t26 = phi i64 [ 0, %list_read_null_311 ], [ %t24, %list_read_real_312 ]
  %t27 = load i32, i32* %t1
  %t28 = add i32 %t27, 1
  %t29 = sext i32 %t28 to i64
  %t30 = icmp ult i64 %t29, %t26
  br i1 %t30, label %list_idx_ok_314, label %list_idx_oob_315
list_idx_ok_314:
  %t31 = getelementptr inbounds i8, i8* %t25, i64 %t29
  %t32 = load i8, i8* %t31
  br label %list_idx_end_316
list_idx_oob_315:
  br label %list_idx_end_316
list_idx_end_316:
  %t33 = phi i8 [ %t32, %list_idx_ok_314 ], [ 0, %list_idx_oob_315 ]
  %t34 = zext i8 %t33 to i32
  %t35 = and i32 8, 31
  %t36 = shl i32 %t34, %t35
  %t37 = or i32 %t17, %t36
  %t38 = load i8*, i8** %t0
  %t39 = icmp eq i8* %t38, null
  br i1 %t39, label %list_read_null_317, label %list_read_real_318
list_read_null_317:
  br label %list_read_end_319
list_read_real_318:
  %t40 = bitcast i8* %t38 to { i8*, i64, i64 }*
  %t41 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t40, i32 0, i32 0
  %t42 = load i8*, i8** %t41
  %t43 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t40, i32 0, i32 1
  %t44 = load i64, i64* %t43
  br label %list_read_end_319
list_read_end_319:
  %t45 = phi i8* [ null, %list_read_null_317 ], [ %t42, %list_read_real_318 ]
  %t46 = phi i64 [ 0, %list_read_null_317 ], [ %t44, %list_read_real_318 ]
  %t47 = load i32, i32* %t1
  %t48 = add i32 %t47, 2
  %t49 = sext i32 %t48 to i64
  %t50 = icmp ult i64 %t49, %t46
  br i1 %t50, label %list_idx_ok_320, label %list_idx_oob_321
list_idx_ok_320:
  %t51 = getelementptr inbounds i8, i8* %t45, i64 %t49
  %t52 = load i8, i8* %t51
  br label %list_idx_end_322
list_idx_oob_321:
  br label %list_idx_end_322
list_idx_end_322:
  %t53 = phi i8 [ %t52, %list_idx_ok_320 ], [ 0, %list_idx_oob_321 ]
  %t54 = zext i8 %t53 to i32
  %t55 = and i32 16, 31
  %t56 = shl i32 %t54, %t55
  %t57 = or i32 %t37, %t56
  %t58 = load i8*, i8** %t0
  %t59 = icmp eq i8* %t58, null
  br i1 %t59, label %list_read_null_323, label %list_read_real_324
list_read_null_323:
  br label %list_read_end_325
list_read_real_324:
  %t60 = bitcast i8* %t58 to { i8*, i64, i64 }*
  %t61 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t60, i32 0, i32 0
  %t62 = load i8*, i8** %t61
  %t63 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t60, i32 0, i32 1
  %t64 = load i64, i64* %t63
  br label %list_read_end_325
list_read_end_325:
  %t65 = phi i8* [ null, %list_read_null_323 ], [ %t62, %list_read_real_324 ]
  %t66 = phi i64 [ 0, %list_read_null_323 ], [ %t64, %list_read_real_324 ]
  %t67 = load i32, i32* %t1
  %t68 = add i32 %t67, 3
  %t69 = sext i32 %t68 to i64
  %t70 = icmp ult i64 %t69, %t66
  br i1 %t70, label %list_idx_ok_326, label %list_idx_oob_327
list_idx_ok_326:
  %t71 = getelementptr inbounds i8, i8* %t65, i64 %t69
  %t72 = load i8, i8* %t71
  br label %list_idx_end_328
list_idx_oob_327:
  br label %list_idx_end_328
list_idx_end_328:
  %t73 = phi i8 [ %t72, %list_idx_ok_326 ], [ 0, %list_idx_oob_327 ]
  %t74 = zext i8 %t73 to i32
  %t75 = and i32 24, 31
  %t76 = shl i32 %t74, %t75
  %t77 = or i32 %t57, %t76
  %t78 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t78)
  ret i32 %t77
}

define i8* @_payload_new(i8* %data, i32 %start, i32 %length) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i32
  %t2 = alloca i32
  %t3 = alloca i8*
  %t4 = alloca i32
  store i8* %data, i8** %t0
  store i32 %start, i32* %t1
  store i32 %length, i32* %t2
  store i8* null, i8** %t3
  store i32 0, i32* %t4
  br label %while_cond_329
while_cond_329:
  %t5 = load i32, i32* %t4
  %t6 = load i32, i32* %t2
  %t7 = icmp slt i32 %t5, %t6
  br i1 %t7, label %while_body_330, label %while_else_331
while_body_330:
  %t8 = getelementptr i8, i8* null, i32 1
  %t9 = ptrtoint i8* %t8 to i64
  %t10 = load i8*, i8** %t3
  %t11 = icmp eq i8* %t10, null
  br i1 %t11, label %list_cow_alloc_333, label %list_cow_check_334
list_cow_alloc_333:
  %t16 = bitcast void (i8*)* @list_release_u8 to i8*
  %t17 = call i8* @star_rc_alloc(i64 24, i8* %t16)
  %t18 = bitcast i8* %t17 to { i8*, i64, i64 }*
  %t19 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t18, i32 0, i32 0
  store i8* null, i8** %t19
  %t20 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t18, i32 0, i32 1
  store i64 0, i64* %t20
  %t21 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t18, i32 0, i32 2
  store i64 0, i64* %t21
  store i8* %t17, i8** %t3
  br label %list_cow_done_335
list_cow_check_334:
  %t22 = getelementptr inbounds i8, i8* %t10, i64 -16
  %t23 = bitcast i8* %t22 to i64*
  %t24 = load atomic i64, i64* %t23 seq_cst, align 8
  %t25 = icmp eq i64 %t24, 1
  br i1 %t25, label %list_cow_done_335, label %list_cow_clone_336
list_cow_clone_336:
  %t26 = bitcast i8* %t10 to { i8*, i64, i64 }*
  %t27 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t26, i32 0, i32 0
  %t28 = load i8*, i8** %t27
  %t29 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t26, i32 0, i32 1
  %t30 = load i64, i64* %t29
  %t31 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t26, i32 0, i32 2
  %t32 = load i64, i64* %t31
  %t33 = bitcast void (i8*)* @list_release_u8 to i8*
  %t34 = call i8* @star_rc_alloc(i64 24, i8* %t33)
  %t35 = bitcast i8* %t34 to { i8*, i64, i64 }*
  %t36 = mul i64 %t32, %t9
  %t37 = call i8* @malloc(i64 %t36)
  %t38 = bitcast i8* %t37 to i8*
  %t39 = icmp sgt i64 %t30, 0
  br i1 %t39, label %list_cow_copy_337, label %list_cow_after_copy_338
list_cow_copy_337:
  %t40 = mul i64 %t30, %t9
  %t41 = bitcast i8* %t28 to i8*
  call i8* @memcpy(i8* %t37, i8* %t41, i64 %t40)
  br label %list_cow_after_copy_338
list_cow_after_copy_338:
  %t42 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t35, i32 0, i32 0
  store i8* %t38, i8** %t42
  %t43 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t35, i32 0, i32 1
  store i64 %t30, i64* %t43
  %t44 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t35, i32 0, i32 2
  store i64 %t32, i64* %t44
  call void @star_rc_release(i8* %t10)
  store i8* %t34, i8** %t3
  br label %list_cow_done_335
list_cow_done_335:
  %t45 = load i8*, i8** %t3
  %t46 = bitcast i8* %t45 to { i8*, i64, i64 }*
  %t47 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t46, i32 0, i32 0
  %t48 = load i8*, i8** %t47
  %t49 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t46, i32 0, i32 1
  %t50 = load i64, i64* %t49
  %t51 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t46, i32 0, i32 2
  %t52 = load i8*, i8** %t0
  %t53 = icmp eq i8* %t52, null
  br i1 %t53, label %list_read_null_339, label %list_read_real_340
list_read_null_339:
  br label %list_read_end_341
list_read_real_340:
  %t54 = bitcast i8* %t52 to { i8*, i64, i64 }*
  %t55 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t54, i32 0, i32 0
  %t56 = load i8*, i8** %t55
  %t57 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t54, i32 0, i32 1
  %t58 = load i64, i64* %t57
  br label %list_read_end_341
list_read_end_341:
  %t59 = phi i8* [ null, %list_read_null_339 ], [ %t56, %list_read_real_340 ]
  %t60 = phi i64 [ 0, %list_read_null_339 ], [ %t58, %list_read_real_340 ]
  %t61 = load i32, i32* %t1
  %t62 = load i32, i32* %t4
  %t63 = add i32 %t61, %t62
  %t64 = sext i32 %t63 to i64
  %t65 = icmp ult i64 %t64, %t60
  br i1 %t65, label %list_idx_ok_342, label %list_idx_oob_343
list_idx_ok_342:
  %t66 = getelementptr inbounds i8, i8* %t59, i64 %t64
  %t67 = load i8, i8* %t66
  br label %list_idx_end_344
list_idx_oob_343:
  br label %list_idx_end_344
list_idx_end_344:
  %t68 = phi i8 [ %t67, %list_idx_ok_342 ], [ 0, %list_idx_oob_343 ]
  %t69 = load i64, i64* %t51
  %t70 = load i8*, i8** %t47
  %t71 = load i64, i64* %t49
  %t72 = icmp sge i64 %t71, %t69
  br i1 %t72, label %list_push_grow_345, label %list_push_store_346
list_push_grow_345:
  %t73 = mul i64 %t69, 2
  %t74 = icmp sgt i64 %t73, 0
  %t75 = select i1 %t74, i64 %t73, i64 1
  %t76 = getelementptr i8, i8* null, i32 1
  %t77 = ptrtoint i8* %t76 to i64
  %t78 = mul i64 %t75, %t77
  %t79 = call i8* @malloc(i64 %t78)
  %t80 = bitcast i8* %t79 to i8*
  %t81 = icmp sgt i64 %t69, 0
  br i1 %t81, label %list_push_copy_347, label %list_push_after_copy_348
list_push_copy_347:
  %t82 = mul i64 %t71, %t77
  %t83 = bitcast i8* %t70 to i8*
  call i8* @memcpy(i8* %t79, i8* %t83, i64 %t82)
  call void @free(i8* %t83)
  br label %list_push_after_copy_348
list_push_after_copy_348:
  store i8* %t80, i8** %t47
  store i64 %t75, i64* %t51
  br label %list_push_store_346
list_push_store_346:
  %t84 = load i8*, i8** %t47
  %t85 = getelementptr inbounds i8, i8* %t84, i64 %t71
  store i8 %t68, i8* %t85
  %t86 = add i64 %t71, 1
  store i64 %t86, i64* %t49
  %t87 = load i32, i32* %t4
  %t88 = add i32 %t87, 1
  store i32 %t88, i32* %t4
  br label %while_cond_329
while_else_331:
  br label %while_end_332
while_end_332:
  %t89 = load i8*, i8** %t3
  %t90 = load i8*, i8** %t3
  call void @star_rc_retain(i8* %t90)
  %t91 = load i8*, i8** %t3
  call void @star_rc_release(i8* %t91)
  %t92 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t92)
  ret i8* %t89
}

define %Section @_decode_section(i8* %payload) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i32
  %t5 = alloca i32
  %t21 = alloca i32
  %t25 = alloca i32
  %t37 = alloca i8*
  %t42 = alloca %Section
  store i8* %payload, i8** %t0
  %t2 = load i8*, i8** %t0
  %t3 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t3)
  %t4 = call i32 @_read_u16_le(i8* %t2, i32 0)
  store i32 %t4, i32* %t1
  %t6 = load i8*, i8** %t0
  %t7 = icmp eq i8* %t6, null
  br i1 %t7, label %list_read_null_349, label %list_read_real_350
list_read_null_349:
  br label %list_read_end_351
list_read_real_350:
  %t8 = bitcast i8* %t6 to { i8*, i64, i64 }*
  %t9 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t8, i32 0, i32 0
  %t10 = load i8*, i8** %t9
  %t11 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t8, i32 0, i32 1
  %t12 = load i64, i64* %t11
  br label %list_read_end_351
list_read_end_351:
  %t13 = phi i8* [ null, %list_read_null_349 ], [ %t10, %list_read_real_350 ]
  %t14 = phi i64 [ 0, %list_read_null_349 ], [ %t12, %list_read_real_350 ]
  %t15 = sext i32 4 to i64
  %t16 = icmp ult i64 %t15, %t14
  br i1 %t16, label %list_idx_ok_352, label %list_idx_oob_353
list_idx_ok_352:
  %t17 = getelementptr inbounds i8, i8* %t13, i64 %t15
  %t18 = load i8, i8* %t17
  br label %list_idx_end_354
list_idx_oob_353:
  br label %list_idx_end_354
list_idx_end_354:
  %t19 = phi i8 [ %t18, %list_idx_ok_352 ], [ 0, %list_idx_oob_353 ]
  %t20 = zext i8 %t19 to i32
  store i32 %t20, i32* %t5
  %t22 = load i8*, i8** %t0
  %t23 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t23)
  %t24 = call i32 @_read_u16_le(i8* %t22, i32 6)
  store i32 %t24, i32* %t21
  %t26 = load i8*, i8** %t0
  %t27 = icmp eq i8* %t26, null
  br i1 %t27, label %list_read_null_355, label %list_read_real_356
list_read_null_355:
  br label %list_read_end_357
list_read_real_356:
  %t28 = bitcast i8* %t26 to { i8*, i64, i64 }*
  %t29 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t28, i32 0, i32 0
  %t30 = load i8*, i8** %t29
  %t31 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t28, i32 0, i32 1
  %t32 = load i64, i64* %t31
  br label %list_read_end_357
list_read_end_357:
  %t33 = phi i8* [ null, %list_read_null_355 ], [ %t30, %list_read_real_356 ]
  %t34 = phi i64 [ 0, %list_read_null_355 ], [ %t32, %list_read_real_356 ]
  %t35 = trunc i64 %t34 to i32
  %t36 = sub i32 %t35, 10
  store i32 %t36, i32* %t25
  %t38 = load i8*, i8** %t0
  %t39 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t39)
  %t40 = load i32, i32* %t25
  %t41 = call i8* @_payload_new(i8* %t38, i32 10, i32 %t40)
  store i8* %t41, i8** %t37
  %t43 = getelementptr inbounds %Section, %Section* %t42, i32 0, i32 0
  %t44 = load i32, i32* %t1
  store i32 %t44, i32* %t43
  %t45 = getelementptr inbounds %Section, %Section* %t42, i32 0, i32 1
  %t46 = load i32, i32* %t5
  store i32 %t46, i32* %t45
  %t47 = getelementptr inbounds %Section, %Section* %t42, i32 0, i32 2
  %t48 = load i32, i32* %t21
  store i32 %t48, i32* %t47
  %t49 = getelementptr inbounds %Section, %Section* %t42, i32 0, i32 3
  %t50 = load i8*, i8** %t37
  %t51 = load i8*, i8** %t37
  call void @star_rc_retain(i8* %t51)
  store i8* %t50, i8** %t49
  %t52 = load %Section, %Section* %t42
  %t53 = load i8*, i8** %t37
  call void @star_rc_release(i8* %t53)
  %t54 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t54)
  ret %Section %t52
}

define { i32, i1 } @_decode_entry(i8* %payload) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i32
  %t17 = alloca i32
  %t21 = alloca { i32, i1 }
  store i8* %payload, i8** %t0
  %t2 = load i8*, i8** %t0
  %t3 = icmp eq i8* %t2, null
  br i1 %t3, label %list_read_null_358, label %list_read_real_359
list_read_null_358:
  br label %list_read_end_360
list_read_real_359:
  %t4 = bitcast i8* %t2 to { i8*, i64, i64 }*
  %t5 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t4, i32 0, i32 0
  %t6 = load i8*, i8** %t5
  %t7 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t4, i32 0, i32 1
  %t8 = load i64, i64* %t7
  br label %list_read_end_360
list_read_end_360:
  %t9 = phi i8* [ null, %list_read_null_358 ], [ %t6, %list_read_real_359 ]
  %t10 = phi i64 [ 0, %list_read_null_358 ], [ %t8, %list_read_real_359 ]
  %t11 = sext i32 0 to i64
  %t12 = icmp ult i64 %t11, %t10
  br i1 %t12, label %list_idx_ok_361, label %list_idx_oob_362
list_idx_ok_361:
  %t13 = getelementptr inbounds i8, i8* %t9, i64 %t11
  %t14 = load i8, i8* %t13
  br label %list_idx_end_363
list_idx_oob_362:
  br label %list_idx_end_363
list_idx_end_363:
  %t15 = phi i8 [ %t14, %list_idx_ok_361 ], [ 0, %list_idx_oob_362 ]
  %t16 = zext i8 %t15 to i32
  store i32 %t16, i32* %t1
  %t18 = load i8*, i8** %t0
  %t19 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t19)
  %t20 = call i32 @_read_u16_le(i8* %t18, i32 1)
  store i32 %t20, i32* %t17
  %t22 = load i32, i32* %t17
  %t23 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t21, i32 0, i32 0
  store i32 %t22, i32* %t23
  %t24 = load i32, i32* %t1
  %t25 = icmp ne i32 %t24, 0
  %t26 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t21, i32 0, i32 1
  store i1 %t25, i1* %t26
  %t27 = load { i32, i1 }, { i32, i1 }* %t21
  %t28 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t28)
  ret { i32, i1 } %t27
}

define { i32, i1 } @file_kind(i8* %path) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i8*
  %t8 = alloca { i32, i1 }
  %t13 = alloca i8*
  %t45 = alloca { i32, i1 }
  %t115 = alloca { i32, i1 }
  %t121 = alloca { i32, i1 }
  store i8* %path, i8** %t0
  %t2 = load i8*, i8** %t0
  %t3 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t3)
  %t4 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t5 = call i8* @fopen(i8* %t2, i8* %t4)
  call void @star_rc_release(i8* %t2)
  call void @star_rc_release(i8* %t4)
  store i8* %t5, i8** %t1
  %t6 = load i8*, i8** %t1
  %t7 = icmp eq i8* %t6, null
  br i1 %t7, label %if_then_364, label %if_else_365
if_then_364:
  %t9 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t8, i32 0, i32 0
  store i32 0, i32* %t9
  %t10 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t8, i32 0, i32 1
  store i1 false, i1* %t10
  %t11 = load { i32, i1 }, { i32, i1 }* %t8
  %t12 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t12)
  ret { i32, i1 } %t11
if_else_365:
  br label %if_end_366
if_end_366:
  %t14 = load i8*, i8** %t1
  %t15 = icmp eq i8* %t14, null
  br i1 %t15, label %file_null_handle_367, label %file_handle_ok_368
file_null_handle_367:
  %t16 = getelementptr inbounds [79 x i8], [79 x i8]* @.str.12, i64 0, i64 0
  call i32 @puts(i8* %t16)
  call void @exit(i32 1)
  unreachable
file_handle_ok_368:
  %t17 = call i32 @ftell(i8* %t14)
  call i32 @fseek(i8* %t14, i32 0, i32 2)
  %t18 = call i32 @ftell(i8* %t14)
  call i32 @fseek(i8* %t14, i32 %t17, i32 0)
  %t19 = sub i32 %t18, %t17
  %t20 = sext i32 %t19 to i64
  %t21 = icmp sge i64 %t20, 0
  %t22 = select i1 %t21, i64 %t20, i64 0
  %t23 = call i8* @malloc(i64 %t22)
  %t24 = call i64 @fread(i8* %t23, i64 1, i64 %t22, i8* %t14)
  %t25 = bitcast void (i8*)* @list_release_u8 to i8*
  %t26 = call i8* @star_rc_alloc(i64 24, i8* %t25)
  %t27 = bitcast i8* %t26 to { i8*, i64, i64 }*
  %t28 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t27, i32 0, i32 0
  store i8* %t23, i8** %t28
  %t29 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t27, i32 0, i32 1
  store i64 %t24, i64* %t29
  %t30 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t27, i32 0, i32 2
  store i64 %t24, i64* %t30
  store i8* %t26, i8** %t13
  %t31 = load i8*, i8** %t1
  %t32 = icmp eq i8* %t31, null
  br i1 %t32, label %file_null_handle_369, label %file_handle_ok_370
file_null_handle_369:
  %t33 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.13, i64 0, i64 0
  call i32 @puts(i8* %t33)
  call void @exit(i32 1)
  unreachable
file_handle_ok_370:
  call i32 @fclose(i8* %t31)
  store i8* null, i8** %t1
  %t34 = load i8*, i8** %t13
  %t35 = icmp eq i8* %t34, null
  br i1 %t35, label %list_read_null_371, label %list_read_real_372
list_read_null_371:
  br label %list_read_end_373
list_read_real_372:
  %t36 = bitcast i8* %t34 to { i8*, i64, i64 }*
  %t37 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t36, i32 0, i32 0
  %t38 = load i8*, i8** %t37
  %t39 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t36, i32 0, i32 1
  %t40 = load i64, i64* %t39
  br label %list_read_end_373
list_read_end_373:
  %t41 = phi i8* [ null, %list_read_null_371 ], [ %t38, %list_read_real_372 ]
  %t42 = phi i64 [ 0, %list_read_null_371 ], [ %t40, %list_read_real_372 ]
  %t43 = trunc i64 %t42 to i32
  %t44 = icmp slt i32 %t43, 6
  br i1 %t44, label %if_then_374, label %if_else_375
if_then_374:
  %t46 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t45, i32 0, i32 0
  store i32 0, i32* %t46
  %t47 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t45, i32 0, i32 1
  store i1 false, i1* %t47
  %t48 = load { i32, i1 }, { i32, i1 }* %t45
  %t49 = load i8*, i8** %t13
  call void @star_rc_release(i8* %t49)
  %t50 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t50)
  ret { i32, i1 } %t48
if_else_375:
  br label %if_end_376
if_end_376:
  %t51 = load i8*, i8** %t13
  %t52 = icmp eq i8* %t51, null
  br i1 %t52, label %list_read_null_377, label %list_read_real_378
list_read_null_377:
  br label %list_read_end_379
list_read_real_378:
  %t53 = bitcast i8* %t51 to { i8*, i64, i64 }*
  %t54 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t53, i32 0, i32 0
  %t55 = load i8*, i8** %t54
  %t56 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t53, i32 0, i32 1
  %t57 = load i64, i64* %t56
  br label %list_read_end_379
list_read_end_379:
  %t58 = phi i8* [ null, %list_read_null_377 ], [ %t55, %list_read_real_378 ]
  %t59 = phi i64 [ 0, %list_read_null_377 ], [ %t57, %list_read_real_378 ]
  %t60 = sext i32 0 to i64
  %t61 = icmp ult i64 %t60, %t59
  br i1 %t61, label %list_idx_ok_380, label %list_idx_oob_381
list_idx_ok_380:
  %t62 = getelementptr inbounds i8, i8* %t58, i64 %t60
  %t63 = load i8, i8* %t62
  br label %list_idx_end_382
list_idx_oob_381:
  br label %list_idx_end_382
list_idx_end_382:
  %t64 = phi i8 [ %t63, %list_idx_ok_380 ], [ 0, %list_idx_oob_381 ]
  %t65 = icmp eq i8 %t64, 78
  br i1 %t65, label %logic_rhs_383, label %logic_short_384
logic_rhs_383:
  %t66 = load i8*, i8** %t13
  %t67 = icmp eq i8* %t66, null
  br i1 %t67, label %list_read_null_386, label %list_read_real_387
list_read_null_386:
  br label %list_read_end_388
list_read_real_387:
  %t68 = bitcast i8* %t66 to { i8*, i64, i64 }*
  %t69 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t68, i32 0, i32 0
  %t70 = load i8*, i8** %t69
  %t71 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t68, i32 0, i32 1
  %t72 = load i64, i64* %t71
  br label %list_read_end_388
list_read_end_388:
  %t73 = phi i8* [ null, %list_read_null_386 ], [ %t70, %list_read_real_387 ]
  %t74 = phi i64 [ 0, %list_read_null_386 ], [ %t72, %list_read_real_387 ]
  %t75 = sext i32 1 to i64
  %t76 = icmp ult i64 %t75, %t74
  br i1 %t76, label %list_idx_ok_389, label %list_idx_oob_390
list_idx_ok_389:
  %t77 = getelementptr inbounds i8, i8* %t73, i64 %t75
  %t78 = load i8, i8* %t77
  br label %list_idx_end_391
list_idx_oob_390:
  br label %list_idx_end_391
list_idx_end_391:
  %t79 = phi i8 [ %t78, %list_idx_ok_389 ], [ 0, %list_idx_oob_390 ]
  %t80 = icmp eq i8 %t79, 79
  br label %logic_end_385
logic_short_384:
  br label %logic_end_385
logic_end_385:
  %t81 = phi i1 [ %t80, %list_idx_end_391 ], [ false, %logic_short_384 ]
  br i1 %t81, label %logic_rhs_392, label %logic_short_393
logic_rhs_392:
  %t82 = load i8*, i8** %t13
  %t83 = icmp eq i8* %t82, null
  br i1 %t83, label %list_read_null_395, label %list_read_real_396
list_read_null_395:
  br label %list_read_end_397
list_read_real_396:
  %t84 = bitcast i8* %t82 to { i8*, i64, i64 }*
  %t85 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t84, i32 0, i32 0
  %t86 = load i8*, i8** %t85
  %t87 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t84, i32 0, i32 1
  %t88 = load i64, i64* %t87
  br label %list_read_end_397
list_read_end_397:
  %t89 = phi i8* [ null, %list_read_null_395 ], [ %t86, %list_read_real_396 ]
  %t90 = phi i64 [ 0, %list_read_null_395 ], [ %t88, %list_read_real_396 ]
  %t91 = sext i32 2 to i64
  %t92 = icmp ult i64 %t91, %t90
  br i1 %t92, label %list_idx_ok_398, label %list_idx_oob_399
list_idx_ok_398:
  %t93 = getelementptr inbounds i8, i8* %t89, i64 %t91
  %t94 = load i8, i8* %t93
  br label %list_idx_end_400
list_idx_oob_399:
  br label %list_idx_end_400
list_idx_end_400:
  %t95 = phi i8 [ %t94, %list_idx_ok_398 ], [ 0, %list_idx_oob_399 ]
  %t96 = icmp eq i8 %t95, 77
  br label %logic_end_394
logic_short_393:
  br label %logic_end_394
logic_end_394:
  %t97 = phi i1 [ %t96, %list_idx_end_400 ], [ false, %logic_short_393 ]
  br i1 %t97, label %logic_rhs_401, label %logic_short_402
logic_rhs_401:
  %t98 = load i8*, i8** %t13
  %t99 = icmp eq i8* %t98, null
  br i1 %t99, label %list_read_null_404, label %list_read_real_405
list_read_null_404:
  br label %list_read_end_406
list_read_real_405:
  %t100 = bitcast i8* %t98 to { i8*, i64, i64 }*
  %t101 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t100, i32 0, i32 0
  %t102 = load i8*, i8** %t101
  %t103 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t100, i32 0, i32 1
  %t104 = load i64, i64* %t103
  br label %list_read_end_406
list_read_end_406:
  %t105 = phi i8* [ null, %list_read_null_404 ], [ %t102, %list_read_real_405 ]
  %t106 = phi i64 [ 0, %list_read_null_404 ], [ %t104, %list_read_real_405 ]
  %t107 = sext i32 3 to i64
  %t108 = icmp ult i64 %t107, %t106
  br i1 %t108, label %list_idx_ok_407, label %list_idx_oob_408
list_idx_ok_407:
  %t109 = getelementptr inbounds i8, i8* %t105, i64 %t107
  %t110 = load i8, i8* %t109
  br label %list_idx_end_409
list_idx_oob_408:
  br label %list_idx_end_409
list_idx_end_409:
  %t111 = phi i8 [ %t110, %list_idx_ok_407 ], [ 0, %list_idx_oob_408 ]
  %t112 = icmp eq i8 %t111, 70
  br label %logic_end_403
logic_short_402:
  br label %logic_end_403
logic_end_403:
  %t113 = phi i1 [ %t112, %list_idx_end_409 ], [ false, %logic_short_402 ]
  %t114 = xor i1 true, %t113
  br i1 %t114, label %if_then_410, label %if_else_411
if_then_410:
  %t116 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t115, i32 0, i32 0
  store i32 0, i32* %t116
  %t117 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t115, i32 0, i32 1
  store i1 false, i1* %t117
  %t118 = load { i32, i1 }, { i32, i1 }* %t115
  %t119 = load i8*, i8** %t13
  call void @star_rc_release(i8* %t119)
  %t120 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t120)
  ret { i32, i1 } %t118
if_else_411:
  br label %if_end_412
if_end_412:
  %t122 = load i8*, i8** %t13
  %t123 = icmp eq i8* %t122, null
  br i1 %t123, label %list_read_null_413, label %list_read_real_414
list_read_null_413:
  br label %list_read_end_415
list_read_real_414:
  %t124 = bitcast i8* %t122 to { i8*, i64, i64 }*
  %t125 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t124, i32 0, i32 0
  %t126 = load i8*, i8** %t125
  %t127 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t124, i32 0, i32 1
  %t128 = load i64, i64* %t127
  br label %list_read_end_415
list_read_end_415:
  %t129 = phi i8* [ null, %list_read_null_413 ], [ %t126, %list_read_real_414 ]
  %t130 = phi i64 [ 0, %list_read_null_413 ], [ %t128, %list_read_real_414 ]
  %t131 = sext i32 5 to i64
  %t132 = icmp ult i64 %t131, %t130
  br i1 %t132, label %list_idx_ok_416, label %list_idx_oob_417
list_idx_ok_416:
  %t133 = getelementptr inbounds i8, i8* %t129, i64 %t131
  %t134 = load i8, i8* %t133
  br label %list_idx_end_418
list_idx_oob_417:
  br label %list_idx_end_418
list_idx_end_418:
  %t135 = phi i8 [ %t134, %list_idx_ok_416 ], [ 0, %list_idx_oob_417 ]
  %t136 = zext i8 %t135 to i32
  %t137 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t121, i32 0, i32 0
  store i32 %t136, i32* %t137
  %t138 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t121, i32 0, i32 1
  store i1 true, i1* %t138
  %t139 = load { i32, i1 }, { i32, i1 }* %t121
  %t140 = load i8*, i8** %t13
  call void @star_rc_release(i8* %t140)
  %t141 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t141)
  ret { i32, i1 } %t139
}

define { %NomfDocument, i1 } @read(i8* %path) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i8*
  %t8 = alloca { %NomfDocument, i1 }
  %t14 = alloca i8*
  %t46 = alloca { %NomfDocument, i1 }
  %t117 = alloca { %NomfDocument, i1 }
  %t124 = alloca i32
  %t140 = alloca i32
  %t156 = alloca i64
  %t161 = alloca i32
  %t167 = alloca { %NomfDocument, i1 }
  %t182 = alloca { %NomfDocument, i1 }
  %t189 = alloca i8*
  %t204 = alloca i64
  %t211 = alloca { %NomfDocument, i1 }
  %t219 = alloca %NomfDocument
  %t223 = alloca i32
  %t224 = alloca i32
  %t225 = alloca i32
  %t246 = alloca { %NomfDocument, i1 }
  %t256 = alloca i8
  %t272 = alloca i8
  %t289 = alloca i8
  %t306 = alloca i8
  %t323 = alloca i32
  %t336 = alloca { %NomfDocument, i1 }
  %t357 = alloca i8*
  %t363 = alloca %Section
  %t411 = alloca i64
  %t463 = alloca i8*
  %t469 = alloca { i32, i1 }
  %t473 = alloca i32
  %t476 = alloca i1
  %t488 = alloca { %NomfDocument, i1 }
  store i8* %path, i8** %t0
  %t2 = load i8*, i8** %t0
  %t3 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t3)
  %t4 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t5 = call i8* @fopen(i8* %t2, i8* %t4)
  call void @star_rc_release(i8* %t2)
  call void @star_rc_release(i8* %t4)
  store i8* %t5, i8** %t1
  %t6 = load i8*, i8** %t1
  %t7 = icmp eq i8* %t6, null
  br i1 %t7, label %if_then_419, label %if_else_420
if_then_419:
  %t9 = call %NomfDocument @new_document()
  %t10 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t8, i32 0, i32 0
  store %NomfDocument %t9, %NomfDocument* %t10
  %t11 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t8, i32 0, i32 1
  store i1 false, i1* %t11
  %t12 = load { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t8
  %t13 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t13)
  ret { %NomfDocument, i1 } %t12
if_else_420:
  br label %if_end_421
if_end_421:
  %t15 = load i8*, i8** %t1
  %t16 = icmp eq i8* %t15, null
  br i1 %t16, label %file_null_handle_422, label %file_handle_ok_423
file_null_handle_422:
  %t17 = getelementptr inbounds [79 x i8], [79 x i8]* @.str.15, i64 0, i64 0
  call i32 @puts(i8* %t17)
  call void @exit(i32 1)
  unreachable
file_handle_ok_423:
  %t18 = call i32 @ftell(i8* %t15)
  call i32 @fseek(i8* %t15, i32 0, i32 2)
  %t19 = call i32 @ftell(i8* %t15)
  call i32 @fseek(i8* %t15, i32 %t18, i32 0)
  %t20 = sub i32 %t19, %t18
  %t21 = sext i32 %t20 to i64
  %t22 = icmp sge i64 %t21, 0
  %t23 = select i1 %t22, i64 %t21, i64 0
  %t24 = call i8* @malloc(i64 %t23)
  %t25 = call i64 @fread(i8* %t24, i64 1, i64 %t23, i8* %t15)
  %t26 = bitcast void (i8*)* @list_release_u8 to i8*
  %t27 = call i8* @star_rc_alloc(i64 24, i8* %t26)
  %t28 = bitcast i8* %t27 to { i8*, i64, i64 }*
  %t29 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t28, i32 0, i32 0
  store i8* %t24, i8** %t29
  %t30 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t28, i32 0, i32 1
  store i64 %t25, i64* %t30
  %t31 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t28, i32 0, i32 2
  store i64 %t25, i64* %t31
  store i8* %t27, i8** %t14
  %t32 = load i8*, i8** %t1
  %t33 = icmp eq i8* %t32, null
  br i1 %t33, label %file_null_handle_424, label %file_handle_ok_425
file_null_handle_424:
  %t34 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.16, i64 0, i64 0
  call i32 @puts(i8* %t34)
  call void @exit(i32 1)
  unreachable
file_handle_ok_425:
  call i32 @fclose(i8* %t32)
  store i8* null, i8** %t1
  %t35 = load i8*, i8** %t14
  %t36 = icmp eq i8* %t35, null
  br i1 %t36, label %list_read_null_426, label %list_read_real_427
list_read_null_426:
  br label %list_read_end_428
list_read_real_427:
  %t37 = bitcast i8* %t35 to { i8*, i64, i64 }*
  %t38 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t37, i32 0, i32 0
  %t39 = load i8*, i8** %t38
  %t40 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t37, i32 0, i32 1
  %t41 = load i64, i64* %t40
  br label %list_read_end_428
list_read_end_428:
  %t42 = phi i8* [ null, %list_read_null_426 ], [ %t39, %list_read_real_427 ]
  %t43 = phi i64 [ 0, %list_read_null_426 ], [ %t41, %list_read_real_427 ]
  %t44 = trunc i64 %t43 to i32
  %t45 = icmp slt i32 %t44, 16
  br i1 %t45, label %if_then_429, label %if_else_430
if_then_429:
  %t47 = call %NomfDocument @new_document()
  %t48 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t46, i32 0, i32 0
  store %NomfDocument %t47, %NomfDocument* %t48
  %t49 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t46, i32 0, i32 1
  store i1 false, i1* %t49
  %t50 = load { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t46
  %t51 = load i8*, i8** %t14
  call void @star_rc_release(i8* %t51)
  %t52 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t52)
  ret { %NomfDocument, i1 } %t50
if_else_430:
  br label %if_end_431
if_end_431:
  %t53 = load i8*, i8** %t14
  %t54 = icmp eq i8* %t53, null
  br i1 %t54, label %list_read_null_432, label %list_read_real_433
list_read_null_432:
  br label %list_read_end_434
list_read_real_433:
  %t55 = bitcast i8* %t53 to { i8*, i64, i64 }*
  %t56 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t55, i32 0, i32 0
  %t57 = load i8*, i8** %t56
  %t58 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t55, i32 0, i32 1
  %t59 = load i64, i64* %t58
  br label %list_read_end_434
list_read_end_434:
  %t60 = phi i8* [ null, %list_read_null_432 ], [ %t57, %list_read_real_433 ]
  %t61 = phi i64 [ 0, %list_read_null_432 ], [ %t59, %list_read_real_433 ]
  %t62 = sext i32 0 to i64
  %t63 = icmp ult i64 %t62, %t61
  br i1 %t63, label %list_idx_ok_435, label %list_idx_oob_436
list_idx_ok_435:
  %t64 = getelementptr inbounds i8, i8* %t60, i64 %t62
  %t65 = load i8, i8* %t64
  br label %list_idx_end_437
list_idx_oob_436:
  br label %list_idx_end_437
list_idx_end_437:
  %t66 = phi i8 [ %t65, %list_idx_ok_435 ], [ 0, %list_idx_oob_436 ]
  %t67 = icmp eq i8 %t66, 78
  br i1 %t67, label %logic_rhs_438, label %logic_short_439
logic_rhs_438:
  %t68 = load i8*, i8** %t14
  %t69 = icmp eq i8* %t68, null
  br i1 %t69, label %list_read_null_441, label %list_read_real_442
list_read_null_441:
  br label %list_read_end_443
list_read_real_442:
  %t70 = bitcast i8* %t68 to { i8*, i64, i64 }*
  %t71 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t70, i32 0, i32 0
  %t72 = load i8*, i8** %t71
  %t73 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t70, i32 0, i32 1
  %t74 = load i64, i64* %t73
  br label %list_read_end_443
list_read_end_443:
  %t75 = phi i8* [ null, %list_read_null_441 ], [ %t72, %list_read_real_442 ]
  %t76 = phi i64 [ 0, %list_read_null_441 ], [ %t74, %list_read_real_442 ]
  %t77 = sext i32 1 to i64
  %t78 = icmp ult i64 %t77, %t76
  br i1 %t78, label %list_idx_ok_444, label %list_idx_oob_445
list_idx_ok_444:
  %t79 = getelementptr inbounds i8, i8* %t75, i64 %t77
  %t80 = load i8, i8* %t79
  br label %list_idx_end_446
list_idx_oob_445:
  br label %list_idx_end_446
list_idx_end_446:
  %t81 = phi i8 [ %t80, %list_idx_ok_444 ], [ 0, %list_idx_oob_445 ]
  %t82 = icmp eq i8 %t81, 79
  br label %logic_end_440
logic_short_439:
  br label %logic_end_440
logic_end_440:
  %t83 = phi i1 [ %t82, %list_idx_end_446 ], [ false, %logic_short_439 ]
  br i1 %t83, label %logic_rhs_447, label %logic_short_448
logic_rhs_447:
  %t84 = load i8*, i8** %t14
  %t85 = icmp eq i8* %t84, null
  br i1 %t85, label %list_read_null_450, label %list_read_real_451
list_read_null_450:
  br label %list_read_end_452
list_read_real_451:
  %t86 = bitcast i8* %t84 to { i8*, i64, i64 }*
  %t87 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t86, i32 0, i32 0
  %t88 = load i8*, i8** %t87
  %t89 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t86, i32 0, i32 1
  %t90 = load i64, i64* %t89
  br label %list_read_end_452
list_read_end_452:
  %t91 = phi i8* [ null, %list_read_null_450 ], [ %t88, %list_read_real_451 ]
  %t92 = phi i64 [ 0, %list_read_null_450 ], [ %t90, %list_read_real_451 ]
  %t93 = sext i32 2 to i64
  %t94 = icmp ult i64 %t93, %t92
  br i1 %t94, label %list_idx_ok_453, label %list_idx_oob_454
list_idx_ok_453:
  %t95 = getelementptr inbounds i8, i8* %t91, i64 %t93
  %t96 = load i8, i8* %t95
  br label %list_idx_end_455
list_idx_oob_454:
  br label %list_idx_end_455
list_idx_end_455:
  %t97 = phi i8 [ %t96, %list_idx_ok_453 ], [ 0, %list_idx_oob_454 ]
  %t98 = icmp eq i8 %t97, 77
  br label %logic_end_449
logic_short_448:
  br label %logic_end_449
logic_end_449:
  %t99 = phi i1 [ %t98, %list_idx_end_455 ], [ false, %logic_short_448 ]
  br i1 %t99, label %logic_rhs_456, label %logic_short_457
logic_rhs_456:
  %t100 = load i8*, i8** %t14
  %t101 = icmp eq i8* %t100, null
  br i1 %t101, label %list_read_null_459, label %list_read_real_460
list_read_null_459:
  br label %list_read_end_461
list_read_real_460:
  %t102 = bitcast i8* %t100 to { i8*, i64, i64 }*
  %t103 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t102, i32 0, i32 0
  %t104 = load i8*, i8** %t103
  %t105 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t102, i32 0, i32 1
  %t106 = load i64, i64* %t105
  br label %list_read_end_461
list_read_end_461:
  %t107 = phi i8* [ null, %list_read_null_459 ], [ %t104, %list_read_real_460 ]
  %t108 = phi i64 [ 0, %list_read_null_459 ], [ %t106, %list_read_real_460 ]
  %t109 = sext i32 3 to i64
  %t110 = icmp ult i64 %t109, %t108
  br i1 %t110, label %list_idx_ok_462, label %list_idx_oob_463
list_idx_ok_462:
  %t111 = getelementptr inbounds i8, i8* %t107, i64 %t109
  %t112 = load i8, i8* %t111
  br label %list_idx_end_464
list_idx_oob_463:
  br label %list_idx_end_464
list_idx_end_464:
  %t113 = phi i8 [ %t112, %list_idx_ok_462 ], [ 0, %list_idx_oob_463 ]
  %t114 = icmp eq i8 %t113, 70
  br label %logic_end_458
logic_short_457:
  br label %logic_end_458
logic_end_458:
  %t115 = phi i1 [ %t114, %list_idx_end_464 ], [ false, %logic_short_457 ]
  %t116 = xor i1 true, %t115
  br i1 %t116, label %if_then_465, label %if_else_466
if_then_465:
  %t118 = call %NomfDocument @new_document()
  %t119 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t117, i32 0, i32 0
  store %NomfDocument %t118, %NomfDocument* %t119
  %t120 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t117, i32 0, i32 1
  store i1 false, i1* %t120
  %t121 = load { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t117
  %t122 = load i8*, i8** %t14
  call void @star_rc_release(i8* %t122)
  %t123 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t123)
  ret { %NomfDocument, i1 } %t121
if_else_466:
  br label %if_end_467
if_end_467:
  %t125 = load i8*, i8** %t14
  %t126 = icmp eq i8* %t125, null
  br i1 %t126, label %list_read_null_468, label %list_read_real_469
list_read_null_468:
  br label %list_read_end_470
list_read_real_469:
  %t127 = bitcast i8* %t125 to { i8*, i64, i64 }*
  %t128 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t127, i32 0, i32 0
  %t129 = load i8*, i8** %t128
  %t130 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t127, i32 0, i32 1
  %t131 = load i64, i64* %t130
  br label %list_read_end_470
list_read_end_470:
  %t132 = phi i8* [ null, %list_read_null_468 ], [ %t129, %list_read_real_469 ]
  %t133 = phi i64 [ 0, %list_read_null_468 ], [ %t131, %list_read_real_469 ]
  %t134 = sext i32 4 to i64
  %t135 = icmp ult i64 %t134, %t133
  br i1 %t135, label %list_idx_ok_471, label %list_idx_oob_472
list_idx_ok_471:
  %t136 = getelementptr inbounds i8, i8* %t132, i64 %t134
  %t137 = load i8, i8* %t136
  br label %list_idx_end_473
list_idx_oob_472:
  br label %list_idx_end_473
list_idx_end_473:
  %t138 = phi i8 [ %t137, %list_idx_ok_471 ], [ 0, %list_idx_oob_472 ]
  %t139 = zext i8 %t138 to i32
  store i32 %t139, i32* %t124
  %t141 = load i8*, i8** %t14
  %t142 = icmp eq i8* %t141, null
  br i1 %t142, label %list_read_null_474, label %list_read_real_475
list_read_null_474:
  br label %list_read_end_476
list_read_real_475:
  %t143 = bitcast i8* %t141 to { i8*, i64, i64 }*
  %t144 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t143, i32 0, i32 0
  %t145 = load i8*, i8** %t144
  %t146 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t143, i32 0, i32 1
  %t147 = load i64, i64* %t146
  br label %list_read_end_476
list_read_end_476:
  %t148 = phi i8* [ null, %list_read_null_474 ], [ %t145, %list_read_real_475 ]
  %t149 = phi i64 [ 0, %list_read_null_474 ], [ %t147, %list_read_real_475 ]
  %t150 = sext i32 5 to i64
  %t151 = icmp ult i64 %t150, %t149
  br i1 %t151, label %list_idx_ok_477, label %list_idx_oob_478
list_idx_ok_477:
  %t152 = getelementptr inbounds i8, i8* %t148, i64 %t150
  %t153 = load i8, i8* %t152
  br label %list_idx_end_479
list_idx_oob_478:
  br label %list_idx_end_479
list_idx_end_479:
  %t154 = phi i8 [ %t153, %list_idx_ok_477 ], [ 0, %list_idx_oob_478 ]
  %t155 = zext i8 %t154 to i32
  store i32 %t155, i32* %t140
  %t157 = load i8*, i8** %t14
  %t158 = load i8*, i8** %t14
  call void @star_rc_retain(i8* %t158)
  %t159 = call i32 @_read_u32_le(i8* %t157, i32 8)
  %t160 = sext i32 %t159 to i64
  store i64 %t160, i64* %t156
  %t162 = load i8*, i8** %t14
  %t163 = load i8*, i8** %t14
  call void @star_rc_retain(i8* %t163)
  %t164 = call i32 @_read_u32_le(i8* %t162, i32 12)
  store i32 %t164, i32* %t161
  %t165 = load i32, i32* %t124
  %t166 = icmp ne i32 %t165, 1
  br i1 %t166, label %if_then_480, label %if_else_481
if_then_480:
  %t168 = call %NomfDocument @new_document()
  %t169 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t167, i32 0, i32 0
  store %NomfDocument %t168, %NomfDocument* %t169
  %t170 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t167, i32 0, i32 1
  store i1 false, i1* %t170
  %t171 = load { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t167
  %t172 = load i8*, i8** %t14
  call void @star_rc_release(i8* %t172)
  %t173 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t173)
  ret { %NomfDocument, i1 } %t171
if_else_481:
  br label %if_end_482
if_end_482:
  %t174 = load i32, i32* %t140
  %t175 = icmp ne i32 %t174, 0
  br i1 %t175, label %logic_rhs_483, label %logic_short_484
logic_rhs_483:
  %t176 = load i32, i32* %t140
  %t177 = icmp ne i32 %t176, 1
  br label %logic_end_485
logic_short_484:
  br label %logic_end_485
logic_end_485:
  %t178 = phi i1 [ %t177, %logic_rhs_483 ], [ false, %logic_short_484 ]
  br i1 %t178, label %logic_rhs_486, label %logic_short_487
logic_rhs_486:
  %t179 = load i32, i32* %t140
  %t180 = icmp ne i32 %t179, 2
  br label %logic_end_488
logic_short_487:
  br label %logic_end_488
logic_end_488:
  %t181 = phi i1 [ %t180, %logic_rhs_486 ], [ false, %logic_short_487 ]
  br i1 %t181, label %if_then_489, label %if_else_490
if_then_489:
  %t183 = call %NomfDocument @new_document()
  %t184 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t182, i32 0, i32 0
  store %NomfDocument %t183, %NomfDocument* %t184
  %t185 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t182, i32 0, i32 1
  store i1 false, i1* %t185
  %t186 = load { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t182
  %t187 = load i8*, i8** %t14
  call void @star_rc_release(i8* %t187)
  %t188 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t188)
  ret { %NomfDocument, i1 } %t186
if_else_490:
  br label %if_end_491
if_end_491:
  %t190 = load i8*, i8** %t14
  %t191 = load i8*, i8** %t14
  call void @star_rc_retain(i8* %t191)
  %t192 = load i8*, i8** %t14
  %t193 = icmp eq i8* %t192, null
  br i1 %t193, label %list_read_null_492, label %list_read_real_493
list_read_null_492:
  br label %list_read_end_494
list_read_real_493:
  %t194 = bitcast i8* %t192 to { i8*, i64, i64 }*
  %t195 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t194, i32 0, i32 0
  %t196 = load i8*, i8** %t195
  %t197 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t194, i32 0, i32 1
  %t198 = load i64, i64* %t197
  br label %list_read_end_494
list_read_end_494:
  %t199 = phi i8* [ null, %list_read_null_492 ], [ %t196, %list_read_real_493 ]
  %t200 = phi i64 [ 0, %list_read_null_492 ], [ %t198, %list_read_real_493 ]
  %t201 = trunc i64 %t200 to i32
  %t202 = sub i32 %t201, 16
  %t203 = call i8* @_payload_new(i8* %t190, i32 16, i32 %t202)
  store i8* %t203, i8** %t189
  %t205 = load i8*, i8** %t189
  %t206 = load i8*, i8** %t189
  call void @star_rc_retain(i8* %t206)
  %t207 = call i64 @_crc32(i8* %t205)
  store i64 %t207, i64* %t204
  %t208 = load i64, i64* %t204
  %t209 = load i64, i64* %t156
  %t210 = icmp ne i64 %t208, %t209
  br i1 %t210, label %if_then_495, label %if_else_496
if_then_495:
  %t212 = call %NomfDocument @new_document()
  %t213 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t211, i32 0, i32 0
  store %NomfDocument %t212, %NomfDocument* %t213
  %t214 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t211, i32 0, i32 1
  store i1 false, i1* %t214
  %t215 = load { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t211
  %t216 = load i8*, i8** %t189
  call void @star_rc_release(i8* %t216)
  %t217 = load i8*, i8** %t14
  call void @star_rc_release(i8* %t217)
  %t218 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t218)
  ret { %NomfDocument, i1 } %t215
if_else_496:
  br label %if_end_497
if_end_497:
  %t220 = call %NomfDocument @new_document()
  store %NomfDocument %t220, %NomfDocument* %t219
  %t221 = load i32, i32* %t140
  %t222 = getelementptr inbounds %NomfDocument, %NomfDocument* %t219, i32 0, i32 0
  store i32 %t221, i32* %t222
  store i32 16, i32* %t223
  store i32 0, i32* %t224
  %t226 = load i8*, i8** %t14
  %t227 = icmp eq i8* %t226, null
  br i1 %t227, label %list_read_null_498, label %list_read_real_499
list_read_null_498:
  br label %list_read_end_500
list_read_real_499:
  %t228 = bitcast i8* %t226 to { i8*, i64, i64 }*
  %t229 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t228, i32 0, i32 0
  %t230 = load i8*, i8** %t229
  %t231 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t228, i32 0, i32 1
  %t232 = load i64, i64* %t231
  br label %list_read_end_500
list_read_end_500:
  %t233 = phi i8* [ null, %list_read_null_498 ], [ %t230, %list_read_real_499 ]
  %t234 = phi i64 [ 0, %list_read_null_498 ], [ %t232, %list_read_real_499 ]
  %t235 = trunc i64 %t234 to i32
  store i32 %t235, i32* %t225
  br label %while_cond_501
while_cond_501:
  %t236 = load i32, i32* %t223
  %t237 = load i32, i32* %t225
  %t238 = icmp slt i32 %t236, %t237
  br i1 %t238, label %while_body_502, label %while_else_503
while_body_502:
  %t239 = load i32, i32* %t224
  %t240 = load i32, i32* %t161
  %t241 = icmp sge i32 %t239, %t240
  br i1 %t241, label %if_then_505, label %if_else_506
if_then_505:
  br label %while_end_504
if_else_506:
  br label %if_end_507
if_end_507:
  %t242 = load i32, i32* %t223
  %t243 = add i32 %t242, 8
  %t244 = load i32, i32* %t225
  %t245 = icmp sgt i32 %t243, %t244
  br i1 %t245, label %if_then_508, label %if_else_509
if_then_508:
  %t247 = call %NomfDocument @new_document()
  %t248 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t246, i32 0, i32 0
  store %NomfDocument %t247, %NomfDocument* %t248
  %t249 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t246, i32 0, i32 1
  store i1 false, i1* %t249
  %t250 = load { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t246
  %t251 = getelementptr inbounds %NomfDocument, %NomfDocument* %t219, i32 0, i32 1
  %t252 = load i8*, i8** %t251
  call void @star_rc_release(i8* %t252)
  %t253 = load i8*, i8** %t189
  call void @star_rc_release(i8* %t253)
  %t254 = load i8*, i8** %t14
  call void @star_rc_release(i8* %t254)
  %t255 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t255)
  ret { %NomfDocument, i1 } %t250
if_else_509:
  br label %if_end_510
if_end_510:
  %t257 = load i8*, i8** %t14
  %t258 = icmp eq i8* %t257, null
  br i1 %t258, label %list_read_null_511, label %list_read_real_512
list_read_null_511:
  br label %list_read_end_513
list_read_real_512:
  %t259 = bitcast i8* %t257 to { i8*, i64, i64 }*
  %t260 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t259, i32 0, i32 0
  %t261 = load i8*, i8** %t260
  %t262 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t259, i32 0, i32 1
  %t263 = load i64, i64* %t262
  br label %list_read_end_513
list_read_end_513:
  %t264 = phi i8* [ null, %list_read_null_511 ], [ %t261, %list_read_real_512 ]
  %t265 = phi i64 [ 0, %list_read_null_511 ], [ %t263, %list_read_real_512 ]
  %t266 = load i32, i32* %t223
  %t267 = sext i32 %t266 to i64
  %t268 = icmp ult i64 %t267, %t265
  br i1 %t268, label %list_idx_ok_514, label %list_idx_oob_515
list_idx_ok_514:
  %t269 = getelementptr inbounds i8, i8* %t264, i64 %t267
  %t270 = load i8, i8* %t269
  br label %list_idx_end_516
list_idx_oob_515:
  br label %list_idx_end_516
list_idx_end_516:
  %t271 = phi i8 [ %t270, %list_idx_ok_514 ], [ 0, %list_idx_oob_515 ]
  store i8 %t271, i8* %t256
  %t273 = load i8*, i8** %t14
  %t274 = icmp eq i8* %t273, null
  br i1 %t274, label %list_read_null_517, label %list_read_real_518
list_read_null_517:
  br label %list_read_end_519
list_read_real_518:
  %t275 = bitcast i8* %t273 to { i8*, i64, i64 }*
  %t276 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t275, i32 0, i32 0
  %t277 = load i8*, i8** %t276
  %t278 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t275, i32 0, i32 1
  %t279 = load i64, i64* %t278
  br label %list_read_end_519
list_read_end_519:
  %t280 = phi i8* [ null, %list_read_null_517 ], [ %t277, %list_read_real_518 ]
  %t281 = phi i64 [ 0, %list_read_null_517 ], [ %t279, %list_read_real_518 ]
  %t282 = load i32, i32* %t223
  %t283 = add i32 %t282, 1
  %t284 = sext i32 %t283 to i64
  %t285 = icmp ult i64 %t284, %t281
  br i1 %t285, label %list_idx_ok_520, label %list_idx_oob_521
list_idx_ok_520:
  %t286 = getelementptr inbounds i8, i8* %t280, i64 %t284
  %t287 = load i8, i8* %t286
  br label %list_idx_end_522
list_idx_oob_521:
  br label %list_idx_end_522
list_idx_end_522:
  %t288 = phi i8 [ %t287, %list_idx_ok_520 ], [ 0, %list_idx_oob_521 ]
  store i8 %t288, i8* %t272
  %t290 = load i8*, i8** %t14
  %t291 = icmp eq i8* %t290, null
  br i1 %t291, label %list_read_null_523, label %list_read_real_524
list_read_null_523:
  br label %list_read_end_525
list_read_real_524:
  %t292 = bitcast i8* %t290 to { i8*, i64, i64 }*
  %t293 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t292, i32 0, i32 0
  %t294 = load i8*, i8** %t293
  %t295 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t292, i32 0, i32 1
  %t296 = load i64, i64* %t295
  br label %list_read_end_525
list_read_end_525:
  %t297 = phi i8* [ null, %list_read_null_523 ], [ %t294, %list_read_real_524 ]
  %t298 = phi i64 [ 0, %list_read_null_523 ], [ %t296, %list_read_real_524 ]
  %t299 = load i32, i32* %t223
  %t300 = add i32 %t299, 2
  %t301 = sext i32 %t300 to i64
  %t302 = icmp ult i64 %t301, %t298
  br i1 %t302, label %list_idx_ok_526, label %list_idx_oob_527
list_idx_ok_526:
  %t303 = getelementptr inbounds i8, i8* %t297, i64 %t301
  %t304 = load i8, i8* %t303
  br label %list_idx_end_528
list_idx_oob_527:
  br label %list_idx_end_528
list_idx_end_528:
  %t305 = phi i8 [ %t304, %list_idx_ok_526 ], [ 0, %list_idx_oob_527 ]
  store i8 %t305, i8* %t289
  %t307 = load i8*, i8** %t14
  %t308 = icmp eq i8* %t307, null
  br i1 %t308, label %list_read_null_529, label %list_read_real_530
list_read_null_529:
  br label %list_read_end_531
list_read_real_530:
  %t309 = bitcast i8* %t307 to { i8*, i64, i64 }*
  %t310 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t309, i32 0, i32 0
  %t311 = load i8*, i8** %t310
  %t312 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t309, i32 0, i32 1
  %t313 = load i64, i64* %t312
  br label %list_read_end_531
list_read_end_531:
  %t314 = phi i8* [ null, %list_read_null_529 ], [ %t311, %list_read_real_530 ]
  %t315 = phi i64 [ 0, %list_read_null_529 ], [ %t313, %list_read_real_530 ]
  %t316 = load i32, i32* %t223
  %t317 = add i32 %t316, 3
  %t318 = sext i32 %t317 to i64
  %t319 = icmp ult i64 %t318, %t315
  br i1 %t319, label %list_idx_ok_532, label %list_idx_oob_533
list_idx_ok_532:
  %t320 = getelementptr inbounds i8, i8* %t314, i64 %t318
  %t321 = load i8, i8* %t320
  br label %list_idx_end_534
list_idx_oob_533:
  br label %list_idx_end_534
list_idx_end_534:
  %t322 = phi i8 [ %t321, %list_idx_ok_532 ], [ 0, %list_idx_oob_533 ]
  store i8 %t322, i8* %t306
  %t324 = load i8*, i8** %t14
  %t325 = load i8*, i8** %t14
  call void @star_rc_retain(i8* %t325)
  %t326 = load i32, i32* %t223
  %t327 = add i32 %t326, 4
  %t328 = call i32 @_read_u32_le(i8* %t324, i32 %t327)
  store i32 %t328, i32* %t323
  %t329 = load i32, i32* %t223
  %t330 = add i32 %t329, 8
  store i32 %t330, i32* %t223
  %t331 = load i32, i32* %t223
  %t332 = load i32, i32* %t323
  %t333 = add i32 %t331, %t332
  %t334 = load i32, i32* %t225
  %t335 = icmp sgt i32 %t333, %t334
  br i1 %t335, label %if_then_535, label %if_else_536
if_then_535:
  %t337 = call %NomfDocument @new_document()
  %t338 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t336, i32 0, i32 0
  store %NomfDocument %t337, %NomfDocument* %t338
  %t339 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t336, i32 0, i32 1
  store i1 false, i1* %t339
  %t340 = load { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t336
  %t341 = getelementptr inbounds %NomfDocument, %NomfDocument* %t219, i32 0, i32 1
  %t342 = load i8*, i8** %t341
  call void @star_rc_release(i8* %t342)
  %t343 = load i8*, i8** %t189
  call void @star_rc_release(i8* %t343)
  %t344 = load i8*, i8** %t14
  call void @star_rc_release(i8* %t344)
  %t345 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t345)
  ret { %NomfDocument, i1 } %t340
if_else_536:
  br label %if_end_537
if_end_537:
  %t346 = load i8, i8* %t256
  %t347 = icmp eq i8 %t346, 83
  br i1 %t347, label %logic_rhs_538, label %logic_short_539
logic_rhs_538:
  %t348 = load i8, i8* %t272
  %t349 = icmp eq i8 %t348, 69
  br label %logic_end_540
logic_short_539:
  br label %logic_end_540
logic_end_540:
  %t350 = phi i1 [ %t349, %logic_rhs_538 ], [ false, %logic_short_539 ]
  br i1 %t350, label %logic_rhs_541, label %logic_short_542
logic_rhs_541:
  %t351 = load i8, i8* %t289
  %t352 = icmp eq i8 %t351, 67
  br label %logic_end_543
logic_short_542:
  br label %logic_end_543
logic_end_543:
  %t353 = phi i1 [ %t352, %logic_rhs_541 ], [ false, %logic_short_542 ]
  br i1 %t353, label %logic_rhs_544, label %logic_short_545
logic_rhs_544:
  %t354 = load i8, i8* %t306
  %t355 = icmp eq i8 %t354, 84
  br label %logic_end_546
logic_short_545:
  br label %logic_end_546
logic_end_546:
  %t356 = phi i1 [ %t355, %logic_rhs_544 ], [ false, %logic_short_545 ]
  br i1 %t356, label %if_then_547, label %if_else_548
if_then_547:
  %t358 = load i8*, i8** %t14
  %t359 = load i8*, i8** %t14
  call void @star_rc_retain(i8* %t359)
  %t360 = load i32, i32* %t223
  %t361 = load i32, i32* %t323
  %t362 = call i8* @_payload_new(i8* %t358, i32 %t360, i32 %t361)
  store i8* %t362, i8** %t357
  %t364 = load i8*, i8** %t357
  %t365 = load i8*, i8** %t357
  call void @star_rc_retain(i8* %t365)
  %t366 = call %Section @_decode_section(i8* %t364)
  store %Section %t366, %Section* %t363
  %t367 = getelementptr inbounds %NomfDocument, %NomfDocument* %t219, i32 0, i32 1
  %t368 = getelementptr %Section, %Section* null, i32 1
  %t369 = ptrtoint %Section* %t368 to i64
  %t370 = load i8*, i8** %t367
  %t371 = icmp eq i8* %t370, null
  br i1 %t371, label %list_cow_alloc_550, label %list_cow_check_551
list_cow_alloc_550:
  %t385 = bitcast void (i8*)* @list_release_s_Section to i8*
  %t386 = call i8* @star_rc_alloc(i64 24, i8* %t385)
  %t387 = bitcast i8* %t386 to { %Section*, i64, i64 }*
  %t388 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t387, i32 0, i32 0
  store %Section* null, %Section** %t388
  %t389 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t387, i32 0, i32 1
  store i64 0, i64* %t389
  %t390 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t387, i32 0, i32 2
  store i64 0, i64* %t390
  store i8* %t386, i8** %t367
  br label %list_cow_done_552
list_cow_check_551:
  %t391 = getelementptr inbounds i8, i8* %t370, i64 -16
  %t392 = bitcast i8* %t391 to i64*
  %t393 = load atomic i64, i64* %t392 seq_cst, align 8
  %t394 = icmp eq i64 %t393, 1
  br i1 %t394, label %list_cow_done_552, label %list_cow_clone_556
list_cow_clone_556:
  %t395 = bitcast i8* %t370 to { %Section*, i64, i64 }*
  %t396 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t395, i32 0, i32 0
  %t397 = load %Section*, %Section** %t396
  %t398 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t395, i32 0, i32 1
  %t399 = load i64, i64* %t398
  %t400 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t395, i32 0, i32 2
  %t401 = load i64, i64* %t400
  %t402 = bitcast void (i8*)* @list_release_s_Section to i8*
  %t403 = call i8* @star_rc_alloc(i64 24, i8* %t402)
  %t404 = bitcast i8* %t403 to { %Section*, i64, i64 }*
  %t405 = mul i64 %t401, %t369
  %t406 = call i8* @malloc(i64 %t405)
  %t407 = bitcast i8* %t406 to %Section*
  %t408 = icmp sgt i64 %t399, 0
  br i1 %t408, label %list_cow_copy_557, label %list_cow_after_copy_558
list_cow_copy_557:
  %t409 = mul i64 %t399, %t369
  %t410 = bitcast %Section* %t397 to i8*
  call i8* @memcpy(i8* %t406, i8* %t410, i64 %t409)
  store i64 0, i64* %t411
  br label %list_cow_retain_cond_559
list_cow_retain_cond_559:
  %t412 = load i64, i64* %t411
  %t413 = icmp slt i64 %t412, %t399
  br i1 %t413, label %list_cow_retain_body_560, label %list_cow_retain_end_561
list_cow_retain_body_560:
  %t414 = getelementptr inbounds %Section, %Section* %t407, i64 %t412
  %t415 = getelementptr inbounds %Section, %Section* %t414, i32 0, i32 3
  %t416 = load i8*, i8** %t415
  call void @star_rc_retain(i8* %t416)
  %t417 = add i64 %t412, 1
  store i64 %t417, i64* %t411
  br label %list_cow_retain_cond_559
list_cow_retain_end_561:
  br label %list_cow_after_copy_558
list_cow_after_copy_558:
  %t418 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t404, i32 0, i32 0
  store %Section* %t407, %Section** %t418
  %t419 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t404, i32 0, i32 1
  store i64 %t399, i64* %t419
  %t420 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t404, i32 0, i32 2
  store i64 %t401, i64* %t420
  call void @star_rc_release(i8* %t370)
  store i8* %t403, i8** %t367
  br label %list_cow_done_552
list_cow_done_552:
  %t421 = load i8*, i8** %t367
  %t422 = bitcast i8* %t421 to { %Section*, i64, i64 }*
  %t423 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t422, i32 0, i32 0
  %t424 = load %Section*, %Section** %t423
  %t425 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t422, i32 0, i32 1
  %t426 = load i64, i64* %t425
  %t427 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t422, i32 0, i32 2
  %t428 = load %Section, %Section* %t363
  %t429 = getelementptr inbounds %Section, %Section* %t363, i32 0, i32 3
  %t430 = load i8*, i8** %t429
  call void @star_rc_retain(i8* %t430)
  %t431 = load i64, i64* %t427
  %t432 = load %Section*, %Section** %t423
  %t433 = load i64, i64* %t425
  %t434 = icmp sge i64 %t433, %t431
  br i1 %t434, label %list_push_grow_562, label %list_push_store_563
list_push_grow_562:
  %t435 = mul i64 %t431, 2
  %t436 = icmp sgt i64 %t435, 0
  %t437 = select i1 %t436, i64 %t435, i64 1
  %t438 = getelementptr %Section, %Section* null, i32 1
  %t439 = ptrtoint %Section* %t438 to i64
  %t440 = mul i64 %t437, %t439
  %t441 = call i8* @malloc(i64 %t440)
  %t442 = bitcast i8* %t441 to %Section*
  %t443 = icmp sgt i64 %t431, 0
  br i1 %t443, label %list_push_copy_564, label %list_push_after_copy_565
list_push_copy_564:
  %t444 = mul i64 %t433, %t439
  %t445 = bitcast %Section* %t432 to i8*
  call i8* @memcpy(i8* %t441, i8* %t445, i64 %t444)
  call void @free(i8* %t445)
  br label %list_push_after_copy_565
list_push_after_copy_565:
  store %Section* %t442, %Section** %t423
  store i64 %t437, i64* %t427
  br label %list_push_store_563
list_push_store_563:
  %t446 = load %Section*, %Section** %t423
  %t447 = getelementptr inbounds %Section, %Section* %t446, i64 %t433
  store %Section %t428, %Section* %t447
  %t448 = add i64 %t433, 1
  store i64 %t448, i64* %t425
  %t449 = getelementptr inbounds %Section, %Section* %t363, i32 0, i32 3
  %t450 = load i8*, i8** %t449
  call void @star_rc_release(i8* %t450)
  %t451 = load i8*, i8** %t357
  call void @star_rc_release(i8* %t451)
  br label %if_end_549
if_else_548:
  %t452 = load i8, i8* %t256
  %t453 = icmp eq i8 %t452, 69
  br i1 %t453, label %logic_rhs_566, label %logic_short_567
logic_rhs_566:
  %t454 = load i8, i8* %t272
  %t455 = icmp eq i8 %t454, 78
  br label %logic_end_568
logic_short_567:
  br label %logic_end_568
logic_end_568:
  %t456 = phi i1 [ %t455, %logic_rhs_566 ], [ false, %logic_short_567 ]
  br i1 %t456, label %logic_rhs_569, label %logic_short_570
logic_rhs_569:
  %t457 = load i8, i8* %t289
  %t458 = icmp eq i8 %t457, 84
  br label %logic_end_571
logic_short_570:
  br label %logic_end_571
logic_end_571:
  %t459 = phi i1 [ %t458, %logic_rhs_569 ], [ false, %logic_short_570 ]
  br i1 %t459, label %logic_rhs_572, label %logic_short_573
logic_rhs_572:
  %t460 = load i8, i8* %t306
  %t461 = icmp eq i8 %t460, 82
  br label %logic_end_574
logic_short_573:
  br label %logic_end_574
logic_end_574:
  %t462 = phi i1 [ %t461, %logic_rhs_572 ], [ false, %logic_short_573 ]
  br i1 %t462, label %if_then_575, label %if_else_576
if_then_575:
  %t464 = load i8*, i8** %t14
  %t465 = load i8*, i8** %t14
  call void @star_rc_retain(i8* %t465)
  %t466 = load i32, i32* %t223
  %t467 = load i32, i32* %t323
  %t468 = call i8* @_payload_new(i8* %t464, i32 %t466, i32 %t467)
  store i8* %t468, i8** %t463
  %t470 = load i8*, i8** %t463
  %t471 = load i8*, i8** %t463
  call void @star_rc_retain(i8* %t471)
  %t472 = call { i32, i1 } @_decode_entry(i8* %t470)
  store { i32, i1 } %t472, { i32, i1 }* %t469
  %t474 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t469, i32 0, i32 0
  %t475 = load i32, i32* %t474
  store i32 %t475, i32* %t473
  %t477 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t469, i32 0, i32 1
  %t478 = load i1, i1* %t477
  store i1 %t478, i1* %t476
  %t479 = load i32, i32* %t473
  %t480 = getelementptr inbounds %NomfDocument, %NomfDocument* %t219, i32 0, i32 2
  store i32 %t479, i32* %t480
  %t481 = getelementptr inbounds %NomfDocument, %NomfDocument* %t219, i32 0, i32 3
  store i1 true, i1* %t481
  %t482 = load i8*, i8** %t463
  call void @star_rc_release(i8* %t482)
  br label %if_end_577
if_else_576:
  br label %if_end_577
if_end_577:
  br label %if_end_549
if_end_549:
  %t483 = load i32, i32* %t323
  %t484 = load i32, i32* %t223
  %t485 = add i32 %t484, %t483
  store i32 %t485, i32* %t223
  %t486 = load i32, i32* %t224
  %t487 = add i32 %t486, 1
  store i32 %t487, i32* %t224
  br label %while_cond_501
while_else_503:
  br label %while_end_504
while_end_504:
  %t489 = load %NomfDocument, %NomfDocument* %t219
  %t490 = getelementptr inbounds %NomfDocument, %NomfDocument* %t219, i32 0, i32 1
  %t491 = load i8*, i8** %t490
  call void @star_rc_retain(i8* %t491)
  %t492 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t488, i32 0, i32 0
  store %NomfDocument %t489, %NomfDocument* %t492
  %t493 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t488, i32 0, i32 1
  store i1 true, i1* %t493
  %t494 = load { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t488
  %t495 = getelementptr inbounds %NomfDocument, %NomfDocument* %t219, i32 0, i32 1
  %t496 = load i8*, i8** %t495
  call void @star_rc_release(i8* %t496)
  %t497 = load i8*, i8** %t189
  call void @star_rc_release(i8* %t497)
  %t498 = load i8*, i8** %t14
  call void @star_rc_release(i8* %t498)
  %t499 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t499)
  ret { %NomfDocument, i1 } %t494
}

define { i32, i1 } @load_nomf(i8* %path) {
entry:
  %t0 = alloca i8*
  %t1 = alloca { %NomfDocument, i1 }
  %t5 = alloca %NomfDocument
  %t10 = alloca i1
  %t15 = alloca { i32, i1 }
  %t28 = alloca { i32, i1 }
  %t41 = alloca { i32, i1 }
  %t63 = alloca { i32, i1 }
  %t75 = alloca { i32, i1 }
  %t87 = alloca i32
  %t88 = alloca i32
  %t116 = alloca %Section
  %t136 = alloca %Section
  %t142 = alloca { i32, i1 }
  store i8* %path, i8** %t0
  %t2 = load i8*, i8** %t0
  %t3 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t3)
  %t4 = call { %NomfDocument, i1 } @read(i8* %t2)
  store { %NomfDocument, i1 } %t4, { %NomfDocument, i1 }* %t1
  %t6 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t1, i32 0, i32 0
  %t7 = load %NomfDocument, %NomfDocument* %t6
  %t8 = getelementptr inbounds %NomfDocument, %NomfDocument* %t6, i32 0, i32 1
  %t9 = load i8*, i8** %t8
  call void @star_rc_retain(i8* %t9)
  store %NomfDocument %t7, %NomfDocument* %t5
  %t11 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t1, i32 0, i32 1
  %t12 = load i1, i1* %t11
  store i1 %t12, i1* %t10
  %t13 = load i1, i1* %t10
  %t14 = xor i1 true, %t13
  br i1 %t14, label %if_then_578, label %if_else_579
if_then_578:
  %t16 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t15, i32 0, i32 0
  store i32 0, i32* %t16
  %t17 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t15, i32 0, i32 1
  store i1 false, i1* %t17
  %t18 = load { i32, i1 }, { i32, i1 }* %t15
  %t19 = getelementptr inbounds %NomfDocument, %NomfDocument* %t5, i32 0, i32 1
  %t20 = load i8*, i8** %t19
  call void @star_rc_release(i8* %t20)
  %t21 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t1, i32 0, i32 0
  %t22 = getelementptr inbounds %NomfDocument, %NomfDocument* %t21, i32 0, i32 1
  %t23 = load i8*, i8** %t22
  call void @star_rc_release(i8* %t23)
  %t24 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t24)
  ret { i32, i1 } %t18
if_else_579:
  br label %if_end_580
if_end_580:
  %t25 = getelementptr inbounds %NomfDocument, %NomfDocument* %t5, i32 0, i32 0
  %t26 = load i32, i32* %t25
  %t27 = icmp eq i32 %t26, 0
  br i1 %t27, label %if_then_581, label %if_else_582
if_then_581:
  %t29 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t28, i32 0, i32 0
  store i32 0, i32* %t29
  %t30 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t28, i32 0, i32 1
  store i1 false, i1* %t30
  %t31 = load { i32, i1 }, { i32, i1 }* %t28
  %t32 = getelementptr inbounds %NomfDocument, %NomfDocument* %t5, i32 0, i32 1
  %t33 = load i8*, i8** %t32
  call void @star_rc_release(i8* %t33)
  %t34 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t1, i32 0, i32 0
  %t35 = getelementptr inbounds %NomfDocument, %NomfDocument* %t34, i32 0, i32 1
  %t36 = load i8*, i8** %t35
  call void @star_rc_release(i8* %t36)
  %t37 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t37)
  ret { i32, i1 } %t31
if_else_582:
  br label %if_end_583
if_end_583:
  %t38 = getelementptr inbounds %NomfDocument, %NomfDocument* %t5, i32 0, i32 0
  %t39 = load i32, i32* %t38
  %t40 = icmp ne i32 %t39, 1
  br i1 %t40, label %if_then_584, label %if_else_585
if_then_584:
  %t42 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t41, i32 0, i32 0
  store i32 0, i32* %t42
  %t43 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t41, i32 0, i32 1
  store i1 false, i1* %t43
  %t44 = load { i32, i1 }, { i32, i1 }* %t41
  %t45 = getelementptr inbounds %NomfDocument, %NomfDocument* %t5, i32 0, i32 1
  %t46 = load i8*, i8** %t45
  call void @star_rc_release(i8* %t46)
  %t47 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t1, i32 0, i32 0
  %t48 = getelementptr inbounds %NomfDocument, %NomfDocument* %t47, i32 0, i32 1
  %t49 = load i8*, i8** %t48
  call void @star_rc_release(i8* %t49)
  %t50 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t50)
  ret { i32, i1 } %t44
if_else_585:
  br label %if_end_586
if_end_586:
  %t51 = getelementptr inbounds %NomfDocument, %NomfDocument* %t5, i32 0, i32 1
  %t52 = load i8*, i8** %t51
  %t53 = icmp eq i8* %t52, null
  br i1 %t53, label %list_read_null_587, label %list_read_real_588
list_read_null_587:
  br label %list_read_end_589
list_read_real_588:
  %t54 = bitcast i8* %t52 to { %Section*, i64, i64 }*
  %t55 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t54, i32 0, i32 0
  %t56 = load %Section*, %Section** %t55
  %t57 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t54, i32 0, i32 1
  %t58 = load i64, i64* %t57
  br label %list_read_end_589
list_read_end_589:
  %t59 = phi %Section* [ null, %list_read_null_587 ], [ %t56, %list_read_real_588 ]
  %t60 = phi i64 [ 0, %list_read_null_587 ], [ %t58, %list_read_real_588 ]
  %t61 = trunc i64 %t60 to i32
  %t62 = icmp eq i32 %t61, 0
  br i1 %t62, label %if_then_590, label %if_else_591
if_then_590:
  %t64 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t63, i32 0, i32 0
  store i32 0, i32* %t64
  %t65 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t63, i32 0, i32 1
  store i1 false, i1* %t65
  %t66 = load { i32, i1 }, { i32, i1 }* %t63
  %t67 = getelementptr inbounds %NomfDocument, %NomfDocument* %t5, i32 0, i32 1
  %t68 = load i8*, i8** %t67
  call void @star_rc_release(i8* %t68)
  %t69 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t1, i32 0, i32 0
  %t70 = getelementptr inbounds %NomfDocument, %NomfDocument* %t69, i32 0, i32 1
  %t71 = load i8*, i8** %t70
  call void @star_rc_release(i8* %t71)
  %t72 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t72)
  ret { i32, i1 } %t66
if_else_591:
  br label %if_end_592
if_end_592:
  %t73 = getelementptr inbounds %NomfDocument, %NomfDocument* %t5, i32 0, i32 3
  %t74 = load i1, i1* %t73
  br i1 %t74, label %if_then_593, label %if_else_594
if_then_593:
  %t76 = getelementptr inbounds %NomfDocument, %NomfDocument* %t5, i32 0, i32 2
  %t77 = load i32, i32* %t76
  %t78 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t75, i32 0, i32 0
  store i32 %t77, i32* %t78
  %t79 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t75, i32 0, i32 1
  store i1 true, i1* %t79
  %t80 = load { i32, i1 }, { i32, i1 }* %t75
  %t81 = getelementptr inbounds %NomfDocument, %NomfDocument* %t5, i32 0, i32 1
  %t82 = load i8*, i8** %t81
  call void @star_rc_release(i8* %t82)
  %t83 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t1, i32 0, i32 0
  %t84 = getelementptr inbounds %NomfDocument, %NomfDocument* %t83, i32 0, i32 1
  %t85 = load i8*, i8** %t84
  call void @star_rc_release(i8* %t85)
  %t86 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t86)
  ret { i32, i1 } %t80
if_else_594:
  br label %if_end_595
if_end_595:
  store i32 65536, i32* %t87
  store i32 0, i32* %t88
  br label %while_cond_596
while_cond_596:
  %t89 = load i32, i32* %t88
  %t90 = getelementptr inbounds %NomfDocument, %NomfDocument* %t5, i32 0, i32 1
  %t91 = load i8*, i8** %t90
  %t92 = icmp eq i8* %t91, null
  br i1 %t92, label %list_read_null_600, label %list_read_real_601
list_read_null_600:
  br label %list_read_end_602
list_read_real_601:
  %t93 = bitcast i8* %t91 to { %Section*, i64, i64 }*
  %t94 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t93, i32 0, i32 0
  %t95 = load %Section*, %Section** %t94
  %t96 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t93, i32 0, i32 1
  %t97 = load i64, i64* %t96
  br label %list_read_end_602
list_read_end_602:
  %t98 = phi %Section* [ null, %list_read_null_600 ], [ %t95, %list_read_real_601 ]
  %t99 = phi i64 [ 0, %list_read_null_600 ], [ %t97, %list_read_real_601 ]
  %t100 = trunc i64 %t99 to i32
  %t101 = icmp slt i32 %t89, %t100
  br i1 %t101, label %while_body_597, label %while_else_598
while_body_597:
  %t102 = getelementptr inbounds %NomfDocument, %NomfDocument* %t5, i32 0, i32 1
  %t103 = load i8*, i8** %t102
  %t104 = icmp eq i8* %t103, null
  br i1 %t104, label %list_read_null_603, label %list_read_real_604
list_read_null_603:
  br label %list_read_end_605
list_read_real_604:
  %t105 = bitcast i8* %t103 to { %Section*, i64, i64 }*
  %t106 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t105, i32 0, i32 0
  %t107 = load %Section*, %Section** %t106
  %t108 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t105, i32 0, i32 1
  %t109 = load i64, i64* %t108
  br label %list_read_end_605
list_read_end_605:
  %t110 = phi %Section* [ null, %list_read_null_603 ], [ %t107, %list_read_real_604 ]
  %t111 = phi i64 [ 0, %list_read_null_603 ], [ %t109, %list_read_real_604 ]
  %t112 = load i32, i32* %t88
  %t113 = sext i32 %t112 to i64
  %t114 = icmp ult i64 %t113, %t111
  br i1 %t114, label %list_read_place_ok_606, label %list_read_place_oob_607
list_read_place_ok_606:
  %t115 = getelementptr inbounds %Section, %Section* %t110, i64 %t113
  br label %list_read_place_end_608
list_read_place_oob_607:
  store %Section zeroinitializer, %Section* %t116
  br label %list_read_place_end_608
list_read_place_end_608:
  %t117 = phi %Section* [ %t115, %list_read_place_ok_606 ], [ %t116, %list_read_place_oob_607 ]
  %t118 = getelementptr inbounds %Section, %Section* %t117, i32 0, i32 2
  %t119 = load i32, i32* %t118
  %t120 = load i32, i32* %t87
  %t121 = icmp slt i32 %t119, %t120
  br i1 %t121, label %if_then_609, label %if_else_610
if_then_609:
  %t122 = getelementptr inbounds %NomfDocument, %NomfDocument* %t5, i32 0, i32 1
  %t123 = load i8*, i8** %t122
  %t124 = icmp eq i8* %t123, null
  br i1 %t124, label %list_read_null_612, label %list_read_real_613
list_read_null_612:
  br label %list_read_end_614
list_read_real_613:
  %t125 = bitcast i8* %t123 to { %Section*, i64, i64 }*
  %t126 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t125, i32 0, i32 0
  %t127 = load %Section*, %Section** %t126
  %t128 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t125, i32 0, i32 1
  %t129 = load i64, i64* %t128
  br label %list_read_end_614
list_read_end_614:
  %t130 = phi %Section* [ null, %list_read_null_612 ], [ %t127, %list_read_real_613 ]
  %t131 = phi i64 [ 0, %list_read_null_612 ], [ %t129, %list_read_real_613 ]
  %t132 = load i32, i32* %t88
  %t133 = sext i32 %t132 to i64
  %t134 = icmp ult i64 %t133, %t131
  br i1 %t134, label %list_read_place_ok_615, label %list_read_place_oob_616
list_read_place_ok_615:
  %t135 = getelementptr inbounds %Section, %Section* %t130, i64 %t133
  br label %list_read_place_end_617
list_read_place_oob_616:
  store %Section zeroinitializer, %Section* %t136
  br label %list_read_place_end_617
list_read_place_end_617:
  %t137 = phi %Section* [ %t135, %list_read_place_ok_615 ], [ %t136, %list_read_place_oob_616 ]
  %t138 = getelementptr inbounds %Section, %Section* %t137, i32 0, i32 2
  %t139 = load i32, i32* %t138
  store i32 %t139, i32* %t87
  br label %if_end_611
if_else_610:
  br label %if_end_611
if_end_611:
  %t140 = load i32, i32* %t88
  %t141 = add i32 %t140, 1
  store i32 %t141, i32* %t88
  br label %while_cond_596
while_else_598:
  br label %while_end_599
while_end_599:
  %t143 = load i32, i32* %t87
  %t144 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t142, i32 0, i32 0
  store i32 %t143, i32* %t144
  %t145 = getelementptr inbounds { i32, i1 }, { i32, i1 }* %t142, i32 0, i32 1
  store i1 true, i1* %t145
  %t146 = load { i32, i1 }, { i32, i1 }* %t142
  %t147 = getelementptr inbounds %NomfDocument, %NomfDocument* %t5, i32 0, i32 1
  %t148 = load i8*, i8** %t147
  call void @star_rc_release(i8* %t148)
  %t149 = getelementptr inbounds { %NomfDocument, i1 }, { %NomfDocument, i1 }* %t1, i32 0, i32 0
  %t150 = getelementptr inbounds %NomfDocument, %NomfDocument* %t149, i32 0, i32 1
  %t151 = load i8*, i8** %t150
  call void @star_rc_release(i8* %t151)
  %t152 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t152)
  ret { i32, i1 } %t146
}


; par/swarm worker functions
define void @list_release_i64(i8* %objp) {
entry:
  %t30 = bitcast i8* %objp to { i64*, i64, i64 }*
  %t31 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t30, i32 0, i32 0
  %t32 = load i64*, i64** %t31
  %t33 = bitcast i64* %t32 to i8*
  call void @free(i8* %t33)
  ret void
}


define void @list_release_u8(i8* %objp) {
entry:
  %t12 = bitcast i8* %objp to { i8*, i64, i64 }*
  %t13 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t12, i32 0, i32 0
  %t14 = load i8*, i8** %t13
  %t15 = bitcast i8* %t14 to i8*
  call void @free(i8* %t15)
  ret void
}


define void @list_release_s_Section(i8* %objp) {
entry:
  %t377 = alloca i64
  %t372 = bitcast i8* %objp to { %Section*, i64, i64 }*
  %t373 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t372, i32 0, i32 0
  %t374 = load %Section*, %Section** %t373
  %t375 = getelementptr inbounds { %Section*, i64, i64 }, { %Section*, i64, i64 }* %t372, i32 0, i32 1
  %t376 = load i64, i64* %t375
  store i64 0, i64* %t377
  br label %list_release_cond_553
list_release_cond_553:
  %t378 = load i64, i64* %t377
  %t379 = icmp slt i64 %t378, %t376
  br i1 %t379, label %list_release_body_554, label %list_release_end_555
list_release_body_554:
  %t380 = getelementptr inbounds %Section, %Section* %t374, i64 %t378
  %t381 = getelementptr inbounds %Section, %Section* %t380, i32 0, i32 3
  %t382 = load i8*, i8** %t381
  call void @star_rc_release(i8* %t382)
  %t383 = add i64 %t378, 1
  store i64 %t383, i64* %t377
  br label %list_release_cond_553
list_release_end_555:
  %t384 = bitcast %Section* %t374 to i8*
  call void @free(i8* %t384)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.1 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.2 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.3 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.4 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.5 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.6 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.7 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.8 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.9 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.10 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.11 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"rb\00" }
@.str.12 = private unnamed_addr constant [79 x i8] c"star runtime error: file_read_bytes(..) called with a null/closed file handle\0A\00"
@.str.13 = private unnamed_addr constant [74 x i8] c"star runtime error: file_close(..) called with a null/closed file handle\0A\00"
@.str.14 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"rb\00" }
@.str.15 = private unnamed_addr constant [79 x i8] c"star runtime error: file_read_bytes(..) called with a null/closed file handle\0A\00"
@.str.16 = private unnamed_addr constant [74 x i8] c"star runtime error: file_close(..) called with a null/closed file handle\0A\00"
