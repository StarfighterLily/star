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

%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca float
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = call float @llvm.atan.f32(float 0x3FF0000000000000)
  %t4 = fmul float 0x4010000000000000, %t3
  store float %t4, float* %t2
  %t5 = load float, float* %t2
  %t6 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.0, i64 0, i64 0
  %t7 = fpext float %t5 to double
  call i32 (i8*, ...) @printf(i8* %t6, double %t7)
  %t8 = load float, float* %t2
  %t9 = fdiv float %t8, 0x4000000000000000
  %t10 = call float @llvm.sin.f32(float %t9)
  %t11 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.1, i64 0, i64 0
  %t12 = fpext float %t10 to double
  call i32 (i8*, ...) @printf(i8* %t11, double %t12)
  %t13 = load float, float* %t2
  %t14 = call float @llvm.cos.f32(float %t13)
  %t15 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.2, i64 0, i64 0
  %t16 = fpext float %t14 to double
  call i32 (i8*, ...) @printf(i8* %t15, double %t16)
  %t17 = load float, float* %t2
  %t18 = fdiv float %t17, 0x4010000000000000
  %t19 = call float @llvm.tan.f32(float %t18)
  %t20 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.3, i64 0, i64 0
  %t21 = fpext float %t19 to double
  call i32 (i8*, ...) @printf(i8* %t20, double %t21)
  %t22 = call float @llvm.asin.f32(float 0x3FE0000000000000)
  %t23 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.4, i64 0, i64 0
  %t24 = fpext float %t22 to double
  call i32 (i8*, ...) @printf(i8* %t23, double %t24)
  %t25 = call float @llvm.acos.f32(float 0x3FE0000000000000)
  %t26 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.5, i64 0, i64 0
  %t27 = fpext float %t25 to double
  call i32 (i8*, ...) @printf(i8* %t26, double %t27)
  %t28 = call float @llvm.atan2.f32(float 0x3FF0000000000000, float 0x3FF0000000000000)
  %t29 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.6, i64 0, i64 0
  %t30 = fpext float %t28 to double
  call i32 (i8*, ...) @printf(i8* %t29, double %t30)
  %t31 = fsub float 0.0, 0x3FF0000000000000
  %t32 = fsub float 0.0, 0x3FF0000000000000
  %t33 = call float @llvm.atan2.f32(float %t31, float %t32)
  %t34 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.7, i64 0, i64 0
  %t35 = fpext float %t33 to double
  call i32 (i8*, ...) @printf(i8* %t34, double %t35)
  %t36 = call float @llvm.exp.f32(float 0x3FF0000000000000)
  %t37 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.8, i64 0, i64 0
  %t38 = fpext float %t36 to double
  call i32 (i8*, ...) @printf(i8* %t37, double %t38)
  %t39 = call float @llvm.exp2.f32(float 0x4024000000000000)
  %t40 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.9, i64 0, i64 0
  %t41 = fpext float %t39 to double
  call i32 (i8*, ...) @printf(i8* %t40, double %t41)
  %t42 = call float @llvm.exp.f32(float 0x3FF0000000000000)
  %t43 = call float @llvm.log.f32(float %t42)
  %t44 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.10, i64 0, i64 0
  %t45 = fpext float %t43 to double
  call i32 (i8*, ...) @printf(i8* %t44, double %t45)
  %t46 = call float @llvm.log2.f32(float 0x4090000000000000)
  %t47 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.11, i64 0, i64 0
  %t48 = fpext float %t46 to double
  call i32 (i8*, ...) @printf(i8* %t47, double %t48)
  %t49 = call float @llvm.log10.f32(float 0x408F400000000000)
  %t50 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.12, i64 0, i64 0
  %t51 = fpext float %t49 to double
  call i32 (i8*, ...) @printf(i8* %t50, double %t51)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [20 x i8] c"pi (from atan): %f\0A\00"
@.str.1 = private unnamed_addr constant [15 x i8] c"sin(pi/2): %f\0A\00"
@.str.2 = private unnamed_addr constant [13 x i8] c"cos(pi): %f\0A\00"
@.str.3 = private unnamed_addr constant [15 x i8] c"tan(pi/4): %f\0A\00"
@.str.4 = private unnamed_addr constant [15 x i8] c"asin(0.5): %f\0A\00"
@.str.5 = private unnamed_addr constant [15 x i8] c"acos(0.5): %f\0A\00"
@.str.6 = private unnamed_addr constant [17 x i8] c"atan2(1, 1): %f\0A\00"
@.str.7 = private unnamed_addr constant [19 x i8] c"atan2(-1, -1): %f\0A\00"
@.str.8 = private unnamed_addr constant [12 x i8] c"exp(1): %f\0A\00"
@.str.9 = private unnamed_addr constant [14 x i8] c"exp2(10): %f\0A\00"
@.str.10 = private unnamed_addr constant [17 x i8] c"log(exp(1)): %f\0A\00"
@.str.11 = private unnamed_addr constant [16 x i8] c"log2(1024): %f\0A\00"
@.str.12 = private unnamed_addr constant [17 x i8] c"log10(1000): %f\0A\00"
