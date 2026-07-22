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
%Box__i32 = type { i32 }
%Box__str = type { i8* }
%Pair__i32__str = type { i32, i8* }
%Stack__i32 = type { i8* }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca %Box__i32
  %t3 = alloca %Box__i32
  %t13 = alloca %Box__i32
  %t17 = alloca %Box__str
  %t18 = alloca %Box__str
  %t24 = alloca %Pair__i32__str
  %t25 = alloca %Pair__i32__str
  %t35 = alloca %Stack__i32
  %t36 = alloca %Stack__i32
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t4 = getelementptr inbounds %Box__i32, %Box__i32* %t3, i32 0, i32 0
  store i32 5, i32* %t4
  %t5 = load %Box__i32, %Box__i32* %t3
  store %Box__i32 %t5, %Box__i32* %t2
  %t6 = call i32 @Box__i32__get(%Box__i32* %t2)
  %t7 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t7, i32 %t6)
  call void @Box__i32__set(%Box__i32* %t2, i32 10)
  %t9 = call i32 @Box__i32__get(%Box__i32* %t2)
  %t10 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t10, i32 %t9)
  %t11 = call i32 @Box__i32__get_twice(%Box__i32* %t2)
  %t12 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t12, i32 %t11)
  %t14 = call %Box__i32 @Box__i32__replaced(%Box__i32* %t2, i32 20)
  store %Box__i32 %t14, %Box__i32* %t13
  %t15 = call i32 @Box__i32__get(%Box__i32* %t13)
  %t16 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t16, i32 %t15)
  %t19 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t20 = getelementptr inbounds %Box__str, %Box__str* %t18, i32 0, i32 0
  store i8* %t19, i8** %t20
  %t21 = load %Box__str, %Box__str* %t18
  store %Box__str %t21, %Box__str* %t17
  %t22 = call i8* @Box__str__get(%Box__str* %t17)
  call void @star_rc_release(i8* %t22)
  %t23 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t23, i8* %t22)
  %t26 = getelementptr inbounds %Pair__i32__str, %Pair__i32__str* %t25, i32 0, i32 0
  store i32 1, i32* %t26
  %t27 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t28 = getelementptr inbounds %Pair__i32__str, %Pair__i32__str* %t25, i32 0, i32 1
  store i8* %t27, i8** %t28
  %t29 = load %Pair__i32__str, %Pair__i32__str* %t25
  store %Pair__i32__str %t29, %Pair__i32__str* %t24
  %t30 = call i32 @Pair__i32__str__first(%Pair__i32__str* %t24)
  %t31 = call i8* @Pair__i32__str__second(%Pair__i32__str* %t24)
  call void @star_rc_release(i8* %t31)
  %t32 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t32, i32 %t30, i8* %t31)
  %t33 = call i8* @Pair__i32__str__describe(%Pair__i32__str* %t24)
  call void @star_rc_release(i8* %t33)
  %t34 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t34, i8* %t33)
  %t37 = getelementptr inbounds %Stack__i32, %Stack__i32* %t36, i32 0, i32 0
  store i8* null, i8** %t37
  %t38 = load %Stack__i32, %Stack__i32* %t36
  store %Stack__i32 %t38, %Stack__i32* %t35
  call void @Stack__i32__push(%Stack__i32* %t35, i32 1)
  call void @Stack__i32__push(%Stack__i32* %t35, i32 2)
  call void @Stack__i32__push(%Stack__i32* %t35, i32 3)
  %t42 = call i32 @Stack__i32__len(%Stack__i32* %t35)
  %t43 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t43, i32 %t42)
  %t44 = call i32 @Stack__i32__pop(%Stack__i32* %t35)
  %t45 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t45, i32 %t44)
  %t46 = call i32 @Stack__i32__pop(%Stack__i32* %t35)
  %t47 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t47, i32 %t46)
  %t48 = call i32 @Stack__i32__len(%Stack__i32* %t35)
  %t49 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t49, i32 %t48)
  %t50 = getelementptr inbounds %Stack__i32, %Stack__i32* %t35, i32 0, i32 0
  %t51 = load i8*, i8** %t50
  call void @star_rc_release(i8* %t51)
  %t52 = getelementptr inbounds %Pair__i32__str, %Pair__i32__str* %t24, i32 0, i32 1
  %t53 = load i8*, i8** %t52
  call void @star_rc_release(i8* %t53)
  %t54 = getelementptr inbounds %Box__str, %Box__str* %t17, i32 0, i32 0
  %t55 = load i8*, i8** %t54
  call void @star_rc_release(i8* %t55)
  ret i32 0
}

define i32 @Box__i32__get(%Box__i32* %self) {
entry:
  %t0 = alloca %Box__i32*
  store %Box__i32* %self, %Box__i32** %t0
  %t1 = load %Box__i32*, %Box__i32** %t0
  %t2 = getelementptr inbounds %Box__i32, %Box__i32* %t1, i32 0, i32 0
  %t3 = load i32, i32* %t2
  ret i32 %t3
}

define void @Box__i32__set(%Box__i32* %self, i32 %v) {
entry:
  %t0 = alloca %Box__i32*
  %t1 = alloca i32
  store %Box__i32* %self, %Box__i32** %t0
  store i32 %v, i32* %t1
  %t2 = load i32, i32* %t1
  %t3 = load %Box__i32*, %Box__i32** %t0
  %t4 = getelementptr inbounds %Box__i32, %Box__i32* %t3, i32 0, i32 0
  store i32 %t2, i32* %t4
  ret void
}

define %Box__i32 @Box__i32__replaced(%Box__i32* %self, i32 %v) {
entry:
  %t0 = alloca %Box__i32*
  %t1 = alloca i32
  store %Box__i32* %self, %Box__i32** %t0
  store i32 %v, i32* %t1
  %t2 = load i32, i32* %t1
  %t3 = load %Box__i32*, %Box__i32** %t0
  %t4 = getelementptr inbounds %Box__i32, %Box__i32* %t3, i32 0, i32 0
  store i32 %t2, i32* %t4
  %t5 = load %Box__i32*, %Box__i32** %t0
  %t6 = load %Box__i32, %Box__i32* %t5
  ret %Box__i32 %t6
}

define i32 @Box__i32__get_twice(%Box__i32* %self) {
entry:
  %t0 = alloca %Box__i32*
  store %Box__i32* %self, %Box__i32** %t0
  %t1 = load %Box__i32*, %Box__i32** %t0
  %t2 = call i32 @Box__i32__get(%Box__i32* %t1)
  ret i32 %t2
}

define i8* @Box__str__get(%Box__str* %self) {
entry:
  %t0 = alloca %Box__str*
  store %Box__str* %self, %Box__str** %t0
  %t1 = load %Box__str*, %Box__str** %t0
  %t2 = getelementptr inbounds %Box__str, %Box__str* %t1, i32 0, i32 0
  %t3 = load i8*, i8** %t2
  %t4 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t4)
  ret i8* %t3
}

define void @Box__str__set(%Box__str* %self, i8* %v) {
entry:
  %t0 = alloca %Box__str*
  %t1 = alloca i8*
  store %Box__str* %self, %Box__str** %t0
  store i8* %v, i8** %t1
  %t2 = load i8*, i8** %t1
  %t3 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t3)
  %t4 = load %Box__str*, %Box__str** %t0
  %t5 = getelementptr inbounds %Box__str, %Box__str* %t4, i32 0, i32 0
  %t6 = load i8*, i8** %t5
  call void @star_rc_release(i8* %t6)
  store i8* %t2, i8** %t5
  %t7 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t7)
  ret void
}

define %Box__str @Box__str__replaced(%Box__str* %self, i8* %v) {
entry:
  %t0 = alloca %Box__str*
  %t1 = alloca i8*
  store %Box__str* %self, %Box__str** %t0
  store i8* %v, i8** %t1
  %t2 = load i8*, i8** %t1
  %t3 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t3)
  %t4 = load %Box__str*, %Box__str** %t0
  %t5 = getelementptr inbounds %Box__str, %Box__str* %t4, i32 0, i32 0
  %t6 = load i8*, i8** %t5
  call void @star_rc_release(i8* %t6)
  store i8* %t2, i8** %t5
  %t7 = load %Box__str*, %Box__str** %t0
  %t8 = load %Box__str, %Box__str* %t7
  %t9 = getelementptr inbounds %Box__str, %Box__str* %t7, i32 0, i32 0
  %t10 = load i8*, i8** %t9
  call void @star_rc_retain(i8* %t10)
  %t11 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t11)
  ret %Box__str %t8
}

define i8* @Box__str__get_twice(%Box__str* %self) {
entry:
  %t0 = alloca %Box__str*
  store %Box__str* %self, %Box__str** %t0
  %t1 = load %Box__str*, %Box__str** %t0
  %t2 = call i8* @Box__str__get(%Box__str* %t1)
  ret i8* %t2
}

define i32 @Pair__i32__str__first(%Pair__i32__str* %self) {
entry:
  %t0 = alloca %Pair__i32__str*
  store %Pair__i32__str* %self, %Pair__i32__str** %t0
  %t1 = load %Pair__i32__str*, %Pair__i32__str** %t0
  %t2 = getelementptr inbounds %Pair__i32__str, %Pair__i32__str* %t1, i32 0, i32 0
  %t3 = load i32, i32* %t2
  ret i32 %t3
}

define i8* @Pair__i32__str__second(%Pair__i32__str* %self) {
entry:
  %t0 = alloca %Pair__i32__str*
  store %Pair__i32__str* %self, %Pair__i32__str** %t0
  %t1 = load %Pair__i32__str*, %Pair__i32__str** %t0
  %t2 = getelementptr inbounds %Pair__i32__str, %Pair__i32__str* %t1, i32 0, i32 1
  %t3 = load i8*, i8** %t2
  %t4 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t4)
  ret i8* %t3
}

define i8* @Pair__i32__str__describe(%Pair__i32__str* %self) {
entry:
  %t0 = alloca %Pair__i32__str*
  store %Pair__i32__str* %self, %Pair__i32__str** %t0
  %t1 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.13, i64 0, i32 2, i64 0
  ret i8* %t1
}

define void @Stack__i32__push(%Stack__i32* %self, i32 %v) {
entry:
  %t0 = alloca %Stack__i32*
  %t1 = alloca i32
  store %Stack__i32* %self, %Stack__i32** %t0
  store i32 %v, i32* %t1
  %t2 = load %Stack__i32*, %Stack__i32** %t0
  %t3 = getelementptr inbounds %Stack__i32, %Stack__i32* %t2, i32 0, i32 0
  %t4 = getelementptr i32, i32* null, i32 1
  %t5 = ptrtoint i32* %t4 to i64
  %t6 = load i8*, i8** %t3
  %t7 = icmp eq i8* %t6, null
  br i1 %t7, label %list_cow_alloc_0, label %list_cow_check_1
list_cow_alloc_0:
  %t12 = bitcast void (i8*)* @list_release_i32 to i8*
  %t13 = call i8* @star_rc_alloc(i64 24, i8* %t12)
  %t14 = bitcast i8* %t13 to { i32*, i64, i64 }*
  %t15 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t14, i32 0, i32 0
  store i32* null, i32** %t15
  %t16 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t14, i32 0, i32 1
  store i64 0, i64* %t16
  %t17 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t14, i32 0, i32 2
  store i64 0, i64* %t17
  store i8* %t13, i8** %t3
  br label %list_cow_done_2
list_cow_check_1:
  %t18 = getelementptr inbounds i8, i8* %t6, i64 -16
  %t19 = bitcast i8* %t18 to i64*
  %t20 = load atomic i64, i64* %t19 seq_cst, align 8
  %t21 = icmp eq i64 %t20, 1
  br i1 %t21, label %list_cow_done_2, label %list_cow_clone_3
list_cow_clone_3:
  %t22 = bitcast i8* %t6 to { i32*, i64, i64 }*
  %t23 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t22, i32 0, i32 0
  %t24 = load i32*, i32** %t23
  %t25 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t22, i32 0, i32 1
  %t26 = load i64, i64* %t25
  %t27 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t22, i32 0, i32 2
  %t28 = load i64, i64* %t27
  %t29 = bitcast void (i8*)* @list_release_i32 to i8*
  %t30 = call i8* @star_rc_alloc(i64 24, i8* %t29)
  %t31 = bitcast i8* %t30 to { i32*, i64, i64 }*
  %t32 = mul i64 %t28, %t5
  %t33 = call i8* @malloc(i64 %t32)
  %t34 = bitcast i8* %t33 to i32*
  %t35 = icmp sgt i64 %t26, 0
  br i1 %t35, label %list_cow_copy_4, label %list_cow_after_copy_5
list_cow_copy_4:
  %t36 = mul i64 %t26, %t5
  %t37 = bitcast i32* %t24 to i8*
  call i8* @memcpy(i8* %t33, i8* %t37, i64 %t36)
  br label %list_cow_after_copy_5
list_cow_after_copy_5:
  %t38 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t31, i32 0, i32 0
  store i32* %t34, i32** %t38
  %t39 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t31, i32 0, i32 1
  store i64 %t26, i64* %t39
  %t40 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t31, i32 0, i32 2
  store i64 %t28, i64* %t40
  call void @star_rc_release(i8* %t6)
  store i8* %t30, i8** %t3
  br label %list_cow_done_2
list_cow_done_2:
  %t41 = load i8*, i8** %t3
  %t42 = bitcast i8* %t41 to { i32*, i64, i64 }*
  %t43 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t42, i32 0, i32 0
  %t44 = load i32*, i32** %t43
  %t45 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t42, i32 0, i32 1
  %t46 = load i64, i64* %t45
  %t47 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t42, i32 0, i32 2
  %t48 = load i32, i32* %t1
  %t49 = load i64, i64* %t47
  %t50 = load i32*, i32** %t43
  %t51 = load i64, i64* %t45
  %t52 = icmp sge i64 %t51, %t49
  br i1 %t52, label %list_push_grow_6, label %list_push_store_7
list_push_grow_6:
  %t53 = mul i64 %t49, 2
  %t54 = icmp sgt i64 %t53, 0
  %t55 = select i1 %t54, i64 %t53, i64 1
  %t56 = getelementptr i32, i32* null, i32 1
  %t57 = ptrtoint i32* %t56 to i64
  %t58 = mul i64 %t55, %t57
  %t59 = call i8* @malloc(i64 %t58)
  %t60 = bitcast i8* %t59 to i32*
  %t61 = icmp sgt i64 %t49, 0
  br i1 %t61, label %list_push_copy_8, label %list_push_after_copy_9
list_push_copy_8:
  %t62 = mul i64 %t51, %t57
  %t63 = bitcast i32* %t50 to i8*
  call i8* @memcpy(i8* %t59, i8* %t63, i64 %t62)
  call void @free(i8* %t63)
  br label %list_push_after_copy_9
list_push_after_copy_9:
  store i32* %t60, i32** %t43
  store i64 %t55, i64* %t47
  br label %list_push_store_7
list_push_store_7:
  %t64 = load i32*, i32** %t43
  %t65 = getelementptr inbounds i32, i32* %t64, i64 %t51
  store i32 %t48, i32* %t65
  %t66 = add i64 %t51, 1
  store i64 %t66, i64* %t45
  ret void
}

define i32 @Stack__i32__pop(%Stack__i32* %self) {
entry:
  %t0 = alloca %Stack__i32*
  store %Stack__i32* %self, %Stack__i32** %t0
  %t1 = load %Stack__i32*, %Stack__i32** %t0
  %t2 = getelementptr inbounds %Stack__i32, %Stack__i32* %t1, i32 0, i32 0
  %t3 = getelementptr i32, i32* null, i32 1
  %t4 = ptrtoint i32* %t3 to i64
  %t5 = load i8*, i8** %t2
  %t6 = icmp eq i8* %t5, null
  br i1 %t6, label %list_cow_alloc_10, label %list_cow_check_11
list_cow_alloc_10:
  %t7 = bitcast void (i8*)* @list_release_i32 to i8*
  %t8 = call i8* @star_rc_alloc(i64 24, i8* %t7)
  %t9 = bitcast i8* %t8 to { i32*, i64, i64 }*
  %t10 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t9, i32 0, i32 0
  store i32* null, i32** %t10
  %t11 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t9, i32 0, i32 1
  store i64 0, i64* %t11
  %t12 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t9, i32 0, i32 2
  store i64 0, i64* %t12
  store i8* %t8, i8** %t2
  br label %list_cow_done_12
list_cow_check_11:
  %t13 = getelementptr inbounds i8, i8* %t5, i64 -16
  %t14 = bitcast i8* %t13 to i64*
  %t15 = load atomic i64, i64* %t14 seq_cst, align 8
  %t16 = icmp eq i64 %t15, 1
  br i1 %t16, label %list_cow_done_12, label %list_cow_clone_13
list_cow_clone_13:
  %t17 = bitcast i8* %t5 to { i32*, i64, i64 }*
  %t18 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t17, i32 0, i32 0
  %t19 = load i32*, i32** %t18
  %t20 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t17, i32 0, i32 1
  %t21 = load i64, i64* %t20
  %t22 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t17, i32 0, i32 2
  %t23 = load i64, i64* %t22
  %t24 = bitcast void (i8*)* @list_release_i32 to i8*
  %t25 = call i8* @star_rc_alloc(i64 24, i8* %t24)
  %t26 = bitcast i8* %t25 to { i32*, i64, i64 }*
  %t27 = mul i64 %t23, %t4
  %t28 = call i8* @malloc(i64 %t27)
  %t29 = bitcast i8* %t28 to i32*
  %t30 = icmp sgt i64 %t21, 0
  br i1 %t30, label %list_cow_copy_14, label %list_cow_after_copy_15
list_cow_copy_14:
  %t31 = mul i64 %t21, %t4
  %t32 = bitcast i32* %t19 to i8*
  call i8* @memcpy(i8* %t28, i8* %t32, i64 %t31)
  br label %list_cow_after_copy_15
list_cow_after_copy_15:
  %t33 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t26, i32 0, i32 0
  store i32* %t29, i32** %t33
  %t34 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t26, i32 0, i32 1
  store i64 %t21, i64* %t34
  %t35 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t26, i32 0, i32 2
  store i64 %t23, i64* %t35
  call void @star_rc_release(i8* %t5)
  store i8* %t25, i8** %t2
  br label %list_cow_done_12
list_cow_done_12:
  %t36 = load i8*, i8** %t2
  %t37 = bitcast i8* %t36 to { i32*, i64, i64 }*
  %t38 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t37, i32 0, i32 0
  %t39 = load i32*, i32** %t38
  %t40 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t37, i32 0, i32 1
  %t41 = load i64, i64* %t40
  %t42 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t37, i32 0, i32 2
  %t43 = icmp eq i64 %t41, 0
  br i1 %t43, label %list_pop_empty_16, label %list_pop_nonempty_17
list_pop_nonempty_17:
  %t44 = sub i64 %t41, 1
  store i64 %t44, i64* %t40
  %t45 = load i32*, i32** %t38
  %t46 = getelementptr inbounds i32, i32* %t45, i64 %t44
  %t47 = load i32, i32* %t46
  br label %list_pop_end_18
list_pop_empty_16:
  br label %list_pop_end_18
list_pop_end_18:
  %t48 = phi i32 [ %t47, %list_pop_nonempty_17 ], [ 0, %list_pop_empty_16 ]
  ret i32 %t48
}

define i32 @Stack__i32__len(%Stack__i32* %self) {
entry:
  %t0 = alloca %Stack__i32*
  store %Stack__i32* %self, %Stack__i32** %t0
  %t1 = load %Stack__i32*, %Stack__i32** %t0
  %t2 = getelementptr inbounds %Stack__i32, %Stack__i32* %t1, i32 0, i32 0
  %t3 = load i8*, i8** %t2
  %t4 = icmp eq i8* %t3, null
  br i1 %t4, label %list_read_null_19, label %list_read_real_20
list_read_null_19:
  br label %list_read_end_21
list_read_real_20:
  %t5 = bitcast i8* %t3 to { i32*, i64, i64 }*
  %t6 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t5, i32 0, i32 0
  %t7 = load i32*, i32** %t6
  %t8 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t5, i32 0, i32 1
  %t9 = load i64, i64* %t8
  br label %list_read_end_21
list_read_end_21:
  %t10 = phi i32* [ null, %list_read_null_19 ], [ %t7, %list_read_real_20 ]
  %t11 = phi i64 [ 0, %list_read_null_19 ], [ %t9, %list_read_real_20 ]
  %t12 = trunc i64 %t11 to i32
  ret i32 %t12
}


; par/swarm worker functions
define void @list_release_i32(i8* %objp) {
entry:
  %t8 = bitcast i8* %objp to { i32*, i64, i64 }*
  %t9 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t8, i32 0, i32 0
  %t10 = load i32*, i32** %t9
  %t11 = bitcast i32* %t10 to i8*
  call void @free(i8* %t11)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant [13 x i8] c"box get: %d\0A\00"
@.str.1 = private unnamed_addr constant [19 x i8] c"box after set: %d\0A\00"
@.str.2 = private unnamed_addr constant [19 x i8] c"box get_twice: %d\0A\00"
@.str.3 = private unnamed_addr constant [18 x i8] c"box replaced: %d\0A\00"
@.str.4 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"hi\00" }
@.str.5 = private unnamed_addr constant [13 x i8] c"box str: %s\0A\00"
@.str.6 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"two\00" }
@.str.7 = private unnamed_addr constant [13 x i8] c"pair: %d %s\0A\00"
@.str.8 = private unnamed_addr constant [14 x i8] c"describe: %s\0A\00"
@.str.9 = private unnamed_addr constant [17 x i8] c"history len: %d\0A\00"
@.str.10 = private unnamed_addr constant [10 x i8] c"undo: %d\0A\00"
@.str.11 = private unnamed_addr constant [10 x i8] c"undo: %d\0A\00"
@.str.12 = private unnamed_addr constant [17 x i8] c"history len: %d\0A\00"
@.str.13 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"a pair\00" }
