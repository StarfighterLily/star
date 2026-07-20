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

@frame.buf = global [4096 x i8] zeroinitializer
@frame.off = global i64 0

@star.argc = global i32 0
@star.argv = global i8** null

@rng.state = global i32 123456789
@rng.lock = global i8* null

@sym.data = global i8** null
@sym.len = global i64 0
@sym.cap = global i64 0
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

%Countdown = type { i32, i32, i32 }
%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define i1 @Countdown__resume(%Countdown* %self) {
entry:
  %t0 = alloca %Countdown*
  store %Countdown* %self, %Countdown** %t0
  %t1 = load %Countdown*, %Countdown** %t0
  %t2 = getelementptr inbounds %Countdown, %Countdown* %t1, i32 0, i32 2
  %t3 = load i32, i32* %t2
  %t4 = icmp eq i32 %t3, 0
  br i1 %t4, label %if_then_0, label %if_else_1
if_then_0:
  %t5 = load %Countdown*, %Countdown** %t0
  %t6 = getelementptr inbounds %Countdown, %Countdown* %t5, i32 0, i32 0
  %t7 = load i32, i32* %t6
  %t8 = load %Countdown*, %Countdown** %t0
  %t9 = getelementptr inbounds %Countdown, %Countdown* %t8, i32 0, i32 1
  store i32 %t7, i32* %t9
  %t10 = load %Countdown*, %Countdown** %t0
  %t11 = getelementptr inbounds %Countdown, %Countdown* %t10, i32 0, i32 1
  %t12 = load i32, i32* %t11
  %t13 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t13, i32 %t12)
  %t14 = load %Countdown*, %Countdown** %t0
  %t15 = getelementptr inbounds %Countdown, %Countdown* %t14, i32 0, i32 1
  %t16 = load i32, i32* %t15
  %t17 = sub i32 %t16, 1
  %t18 = load %Countdown*, %Countdown** %t0
  %t19 = getelementptr inbounds %Countdown, %Countdown* %t18, i32 0, i32 1
  store i32 %t17, i32* %t19
  %t20 = load %Countdown*, %Countdown** %t0
  %t21 = getelementptr inbounds %Countdown, %Countdown* %t20, i32 0, i32 2
  store i32 1, i32* %t21
  ret i1 true
if_else_1:
  %t22 = load %Countdown*, %Countdown** %t0
  %t23 = getelementptr inbounds %Countdown, %Countdown* %t22, i32 0, i32 2
  %t24 = load i32, i32* %t23
  %t25 = icmp eq i32 %t24, 1
  br i1 %t25, label %if_then_3, label %if_else_4
if_then_3:
  %t26 = load %Countdown*, %Countdown** %t0
  %t27 = getelementptr inbounds %Countdown, %Countdown* %t26, i32 0, i32 1
  %t28 = load i32, i32* %t27
  %t29 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t29, i32 %t28)
  %t30 = load %Countdown*, %Countdown** %t0
  %t31 = getelementptr inbounds %Countdown, %Countdown* %t30, i32 0, i32 1
  %t32 = load i32, i32* %t31
  %t33 = sub i32 %t32, 1
  %t34 = load %Countdown*, %Countdown** %t0
  %t35 = getelementptr inbounds %Countdown, %Countdown* %t34, i32 0, i32 1
  store i32 %t33, i32* %t35
  %t36 = load %Countdown*, %Countdown** %t0
  %t37 = getelementptr inbounds %Countdown, %Countdown* %t36, i32 0, i32 2
  store i32 2, i32* %t37
  ret i1 true
if_else_4:
  %t38 = load %Countdown*, %Countdown** %t0
  %t39 = getelementptr inbounds %Countdown, %Countdown* %t38, i32 0, i32 2
  %t40 = load i32, i32* %t39
  %t41 = icmp eq i32 %t40, 2
  br i1 %t41, label %if_then_6, label %if_else_7
if_then_6:
  %t42 = load %Countdown*, %Countdown** %t0
  %t43 = getelementptr inbounds %Countdown, %Countdown* %t42, i32 0, i32 1
  %t44 = load i32, i32* %t43
  %t45 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t45, i32 %t44)
  %t46 = load %Countdown*, %Countdown** %t0
  %t47 = getelementptr inbounds %Countdown, %Countdown* %t46, i32 0, i32 1
  %t48 = load i32, i32* %t47
  %t49 = sub i32 %t48, 1
  %t50 = load %Countdown*, %Countdown** %t0
  %t51 = getelementptr inbounds %Countdown, %Countdown* %t50, i32 0, i32 1
  store i32 %t49, i32* %t51
  %t52 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t52)
  %t53 = load %Countdown*, %Countdown** %t0
  %t54 = getelementptr inbounds %Countdown, %Countdown* %t53, i32 0, i32 2
  store i32 3, i32* %t54
  ret i1 false
if_else_7:
  ret i1 false
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca %Countdown
  %t3 = alloca %Countdown
  %t8 = alloca i1
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t4 = getelementptr inbounds %Countdown, %Countdown* %t3, i32 0, i32 0
  store i32 3, i32* %t4
  %t5 = getelementptr inbounds %Countdown, %Countdown* %t3, i32 0, i32 1
  store i32 0, i32* %t5
  %t6 = getelementptr inbounds %Countdown, %Countdown* %t3, i32 0, i32 2
  store i32 0, i32* %t6
  %t7 = load %Countdown, %Countdown* %t3
  store %Countdown %t7, %Countdown* %t2
  store i1 true, i1* %t8
  br label %while_cond_9
while_cond_9:
  %t9 = load i1, i1* %t8
  br i1 %t9, label %while_body_10, label %while_else_11
while_body_10:
  %t10 = call i1 @Countdown__resume(%Countdown* %t2)
  store i1 %t10, i1* %t8
  br label %while_cond_9
while_else_11:
  br label %while_end_12
while_end_12:
  %t11 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t11)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [10 x i8] c"tick: %d\0A\00"
@.str.1 = private unnamed_addr constant [10 x i8] c"tick: %d\0A\00"
@.str.2 = private unnamed_addr constant [10 x i8] c"tick: %d\0A\00"
@.str.3 = private unnamed_addr constant [9 x i8] c"liftoff\0A\00"
@.str.4 = private unnamed_addr constant [15 x i8] c"sequence done\0A\00"
