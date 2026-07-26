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
  %t2 = alloca i32
  %t11 = alloca i8*
  %t18 = alloca i32
  %t29 = alloca i1
  %t35 = alloca i32
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = call i32 @SDL_Init(i32 512)
  %t4 = call i32 @SDL_NumJoysticks()
  store i32 %t4, i32* %t2
  %t5 = load i32, i32* %t2
  %t6 = getelementptr inbounds [32 x i8], [32 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t6, i32 %t5)
  %t7 = load i32, i32* %t2
  %t8 = icmp eq i32 %t7, 0
  br i1 %t8, label %if_then_0, label %if_else_1
if_then_0:
  %t9 = getelementptr inbounds { i64, i8*, [48 x i8] }, { i64, i8*, [48 x i8] }* @.str.1, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t9)
  call i32 (i8*, ...) @printf(i8* %t9)
  %t10 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t10)
  ret i32 0
if_else_1:
  br label %if_end_2
if_end_2:
  %t12 = call i32 @SDL_Init(i32 512)
  %t13 = call i8* @SDL_JoystickOpen(i32 0)
  store i8* %t13, i8** %t11
  %t14 = load i8*, i8** %t11
  %t15 = icmp eq i8* %t14, null
  br i1 %t15, label %if_then_3, label %if_else_4
if_then_3:
  %t16 = getelementptr inbounds { i64, i8*, [20 x i8] }, { i64, i8*, [20 x i8] }* @.str.3, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t16)
  call i32 (i8*, ...) @printf(i8* %t16)
  %t17 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t17)
  ret i32 0
if_else_4:
  br label %if_end_5
if_end_5:
  store i32 0, i32* %t18
  br label %while_cond_6
while_cond_6:
  %t19 = load i32, i32* %t18
  %t20 = icmp slt i32 %t19, 5
  br i1 %t20, label %while_body_7, label %while_else_8
while_body_7:
  %t21 = load i8*, i8** %t11
  %t22 = icmp eq i8* %t21, null
  br i1 %t22, label %gamepad_null_handle_10, label %gamepad_handle_ok_11
gamepad_null_handle_10:
  %t23 = getelementptr inbounds [83 x i8], [83 x i8]* @.str.5, i64 0, i64 0
  call i32 @puts(i8* %t23)
  call void @exit(i32 1)
  unreachable
gamepad_handle_ok_11:
  %t24 = call i32 @SDL_JoystickGetAttached(i8* %t21)
  %t25 = icmp ne i32 %t24, 0
  %t26 = xor i1 true, %t25
  br i1 %t26, label %if_then_12, label %if_else_13
if_then_12:
  %t27 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.6, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t27)
  call i32 (i8*, ...) @printf(i8* %t27)
  %t28 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t28)
  br label %while_end_9
if_else_13:
  br label %if_end_14
if_end_14:
  %t30 = load i8*, i8** %t11
  %t31 = icmp eq i8* %t30, null
  br i1 %t31, label %gamepad_null_handle_15, label %gamepad_handle_ok_16
gamepad_null_handle_15:
  %t32 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.8, i64 0, i64 0
  call i32 @puts(i8* %t32)
  call void @exit(i32 1)
  unreachable
gamepad_handle_ok_16:
  call void @SDL_JoystickUpdate()
  %t33 = call i8 @SDL_JoystickGetButton(i8* %t30, i32 0)
  %t34 = icmp ne i8 %t33, 0
  store i1 %t34, i1* %t29
  %t36 = load i8*, i8** %t11
  %t37 = icmp eq i8* %t36, null
  br i1 %t37, label %gamepad_null_handle_17, label %gamepad_handle_ok_18
gamepad_null_handle_17:
  %t38 = getelementptr inbounds [79 x i8], [79 x i8]* @.str.9, i64 0, i64 0
  call i32 @puts(i8* %t38)
  call void @exit(i32 1)
  unreachable
gamepad_handle_ok_18:
  call void @SDL_JoystickUpdate()
  %t39 = call i16 @SDL_JoystickGetAxis(i8* %t36, i32 0)
  %t40 = sext i16 %t39 to i32
  store i32 %t40, i32* %t35
  %t41 = load i1, i1* %t29
  %t42 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.10, i64 0, i64 0
  %t43 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.11, i64 0, i64 0
  %t44 = select i1 %t41, i8* %t42, i8* %t43
  %t45 = load i32, i32* %t35
  %t46 = getelementptr inbounds [28 x i8], [28 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t46, i8* %t44, i32 %t45)
  %t47 = icmp slt i32 1000, 0
  %t48 = select i1 %t47, i32 0, i32 1000
  call void @SDL_Delay(i32 %t48)
  %t49 = load i32, i32* %t18
  %t50 = add i32 %t49, 1
  store i32 %t50, i32* %t18
  br label %while_cond_6
while_else_8:
  br label %while_end_9
while_end_9:
  %t51 = load i8*, i8** %t11
  %t52 = icmp eq i8* %t51, null
  br i1 %t52, label %gamepad_null_handle_19, label %gamepad_handle_ok_20
gamepad_null_handle_19:
  %t53 = getelementptr inbounds [80 x i8], [80 x i8]* @.str.13, i64 0, i64 0
  call i32 @puts(i8* %t53)
  call void @exit(i32 1)
  unreachable
gamepad_handle_ok_20:
  call void @SDL_JoystickClose(i8* %t51)
  store i8* null, i8** %t11
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [32 x i8] c"connected joystick devices: %d\0A\00"
@.str.1 = private unnamed_addr constant { i64, i8*, [48 x i8] } { i64 -1, i8* null, [48 x i8] c"no gamepad connected -- nothing further to demo\00" }
@.str.2 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.3 = private unnamed_addr constant { i64, i8*, [20 x i8] } { i64 -1, i8* null, [20 x i8] c"gamepad_open failed\00" }
@.str.4 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.5 = private unnamed_addr constant [83 x i8] c"star runtime error: gamepad_attached(..) called with a null/closed gamepad handle\0A\00"
@.str.6 = private unnamed_addr constant { i64, i8*, [21 x i8] } { i64 -1, i8* null, [21 x i8] c"gamepad disconnected\00" }
@.str.7 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.8 = private unnamed_addr constant [86 x i8] c"star runtime error: gamepad_button_down(..) called with a null/closed gamepad handle\0A\00"
@.str.9 = private unnamed_addr constant [79 x i8] c"star runtime error: gamepad_axis(..) called with a null/closed gamepad handle\0A\00"
@.str.10 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.11 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.12 = private unnamed_addr constant [28 x i8] c"button 0 down=%s axis 0=%d\0A\00"
@.str.13 = private unnamed_addr constant [80 x i8] c"star runtime error: gamepad_close(..) called with a null/closed gamepad handle\0A\00"
