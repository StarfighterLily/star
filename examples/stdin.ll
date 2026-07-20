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
  %t4 = alloca i64
  %t19 = alloca i8*
  %t21 = alloca i64
  %t36 = alloca i8*
  %t38 = alloca i64
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = call i8* @star_rc_alloc(i64 1024, i8* null)
  store i64 0, i64* %t4
  br label %read_line_cond_0
read_line_cond_0:
  %t5 = load i64, i64* %t4
  %t6 = icmp ult i64 %t5, 1023
  br i1 %t6, label %read_line_body_1, label %read_line_end_3
read_line_body_1:
  %t7 = call i32 @getchar()
  %t8 = icmp eq i32 %t7, -1
  %t9 = icmp eq i32 %t7, 10
  %t10 = or i1 %t8, %t9
  br i1 %t10, label %read_line_end_3, label %read_line_store_2
read_line_store_2:
  %t11 = getelementptr inbounds i8, i8* %t3, i64 %t5
  %t12 = trunc i32 %t7 to i8
  store i8 %t12, i8* %t11
  %t13 = add i64 %t5, 1
  store i64 %t13, i64* %t4
  br label %read_line_cond_0
read_line_end_3:
  %t14 = load i64, i64* %t4
  %t15 = getelementptr inbounds i8, i8* %t3, i64 %t14
  store i8 0, i8* %t15
  store i8* %t3, i8** %t2
  %t16 = load i8*, i8** %t2
  %t17 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t17)
  call void @star_rc_release(i8* %t16)
  %t18 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t18, i8* %t16)
  %t20 = call i8* @star_rc_alloc(i64 1024, i8* null)
  store i64 0, i64* %t21
  br label %read_line_cond_4
read_line_cond_4:
  %t22 = load i64, i64* %t21
  %t23 = icmp ult i64 %t22, 1023
  br i1 %t23, label %read_line_body_5, label %read_line_end_7
read_line_body_5:
  %t24 = call i32 @getchar()
  %t25 = icmp eq i32 %t24, -1
  %t26 = icmp eq i32 %t24, 10
  %t27 = or i1 %t25, %t26
  br i1 %t27, label %read_line_end_7, label %read_line_store_6
read_line_store_6:
  %t28 = getelementptr inbounds i8, i8* %t20, i64 %t22
  %t29 = trunc i32 %t24 to i8
  store i8 %t29, i8* %t28
  %t30 = add i64 %t22, 1
  store i64 %t30, i64* %t21
  br label %read_line_cond_4
read_line_end_7:
  %t31 = load i64, i64* %t21
  %t32 = getelementptr inbounds i8, i8* %t20, i64 %t31
  store i8 0, i8* %t32
  store i8* %t20, i8** %t19
  %t33 = load i8*, i8** %t19
  %t34 = load i8*, i8** %t19
  call void @star_rc_retain(i8* %t34)
  call void @star_rc_release(i8* %t33)
  %t35 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t35, i8* %t33)
  %t37 = call i8* @star_rc_alloc(i64 1024, i8* null)
  store i64 0, i64* %t38
  br label %read_line_cond_8
read_line_cond_8:
  %t39 = load i64, i64* %t38
  %t40 = icmp ult i64 %t39, 1023
  br i1 %t40, label %read_line_body_9, label %read_line_end_11
read_line_body_9:
  %t41 = call i32 @getchar()
  %t42 = icmp eq i32 %t41, -1
  %t43 = icmp eq i32 %t41, 10
  %t44 = or i1 %t42, %t43
  br i1 %t44, label %read_line_end_11, label %read_line_store_10
read_line_store_10:
  %t45 = getelementptr inbounds i8, i8* %t37, i64 %t39
  %t46 = trunc i32 %t41 to i8
  store i8 %t46, i8* %t45
  %t47 = add i64 %t39, 1
  store i64 %t47, i64* %t38
  br label %read_line_cond_8
read_line_end_11:
  %t48 = load i64, i64* %t38
  %t49 = getelementptr inbounds i8, i8* %t37, i64 %t48
  store i8 0, i8* %t49
  store i8* %t37, i8** %t36
  %t50 = load i8*, i8** %t36
  %t51 = load i8*, i8** %t36
  call void @star_rc_retain(i8* %t51)
  call void @star_rc_release(i8* %t50)
  %t52 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t52, i8* %t50)
  %t53 = load i8*, i8** %t36
  call void @star_rc_release(i8* %t53)
  %t54 = load i8*, i8** %t19
  call void @star_rc_release(i8* %t54)
  %t55 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t55)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [11 x i8] c"hello, %s\0A\00"
@.str.1 = private unnamed_addr constant [11 x i8] c"again: %s\0A\00"
@.str.2 = private unnamed_addr constant [10 x i8] c"last: %s\0A\00"
