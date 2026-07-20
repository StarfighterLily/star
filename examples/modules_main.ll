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

%geo__Point = type { i32, i32 }
%geo__Shape = type { i32, [1 x i64] }
%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define i32 @geo__Point__length_sq(%geo__Point* %self) {
entry:
  %t0 = alloca %geo__Point*
  store %geo__Point* %self, %geo__Point** %t0
  %t1 = load %geo__Point*, %geo__Point** %t0
  %t2 = getelementptr inbounds %geo__Point, %geo__Point* %t1, i32 0, i32 0
  %t3 = load i32, i32* %t2
  %t4 = load %geo__Point*, %geo__Point** %t0
  %t5 = getelementptr inbounds %geo__Point, %geo__Point* %t4, i32 0, i32 0
  %t6 = load i32, i32* %t5
  %t7 = mul i32 %t3, %t6
  %t8 = load %geo__Point*, %geo__Point** %t0
  %t9 = getelementptr inbounds %geo__Point, %geo__Point* %t8, i32 0, i32 1
  %t10 = load i32, i32* %t9
  %t11 = load %geo__Point*, %geo__Point** %t0
  %t12 = getelementptr inbounds %geo__Point, %geo__Point* %t11, i32 0, i32 1
  %t13 = load i32, i32* %t12
  %t14 = mul i32 %t10, %t13
  %t15 = add i32 %t7, %t14
  ret i32 %t15
}

define i32 @geo__dot(%geo__Point %a, %geo__Point %b) {
entry:
  %t0 = alloca %geo__Point
  %t1 = alloca %geo__Point
  store %geo__Point %a, %geo__Point* %t0
  store %geo__Point %b, %geo__Point* %t1
  %t2 = getelementptr inbounds %geo__Point, %geo__Point* %t0, i32 0, i32 0
  %t3 = load i32, i32* %t2
  %t4 = getelementptr inbounds %geo__Point, %geo__Point* %t1, i32 0, i32 0
  %t5 = load i32, i32* %t4
  %t6 = mul i32 %t3, %t5
  %t7 = getelementptr inbounds %geo__Point, %geo__Point* %t0, i32 0, i32 1
  %t8 = load i32, i32* %t7
  %t9 = getelementptr inbounds %geo__Point, %geo__Point* %t1, i32 0, i32 1
  %t10 = load i32, i32* %t9
  %t11 = mul i32 %t8, %t10
  %t12 = add i32 %t6, %t11
  ret i32 %t12
}

define i32 @geo__area(%geo__Shape %s) {
entry:
  %t0 = alloca %geo__Shape
  store %geo__Shape %s, %geo__Shape* %t0
  br label %match_scrutinee_2
match_scrutinee_2:
  %t6 = getelementptr inbounds %geo__Shape, %geo__Shape* %t0, i32 0, i32 0
  %t7 = load i32, i32* %t6
  %t5 = icmp eq i32 %t7, 0
  br i1 %t5, label %match_then_0_3, label %match_next_0_4
match_then_0_3:
  %t8 = getelementptr inbounds %geo__Shape, %geo__Shape* %t0, i32 0, i32 1
  %t9 = bitcast [1 x i64]* %t8 to { i32 }*
  %t10 = getelementptr inbounds { i32 }, { i32 }* %t9, i32 0, i32 0
  %t11 = load i32, i32* %t10
  %t12 = mul i32 3, %t11
  %t13 = load i32, i32* %t10
  %t14 = mul i32 %t12, %t13
  ret i32 %t14
match_next_0_4:
  %t18 = getelementptr inbounds %geo__Shape, %geo__Shape* %t0, i32 0, i32 0
  %t19 = load i32, i32* %t18
  %t17 = icmp eq i32 %t19, 1
  br i1 %t17, label %match_then_1_15, label %match_next_1_16
match_then_1_15:
  %t20 = getelementptr inbounds %geo__Shape, %geo__Shape* %t0, i32 0, i32 1
  %t21 = bitcast [1 x i64]* %t20 to { i32, i32 }*
  %t22 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t21, i32 0, i32 0
  %t23 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t21, i32 0, i32 1
  %t24 = load i32, i32* %t22
  %t25 = load i32, i32* %t23
  %t26 = mul i32 %t24, %t25
  ret i32 %t26
match_next_1_16:
  br label %match_end_1
match_end_1:
  unreachable
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca %geo__Point
  %t3 = alloca %geo__Point
  %t8 = alloca %geo__Point
  %t14 = alloca %geo__Shape
  %t22 = alloca %geo__Shape
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t4 = getelementptr inbounds %geo__Point, %geo__Point* %t3, i32 0, i32 0
  store i32 3, i32* %t4
  %t5 = getelementptr inbounds %geo__Point, %geo__Point* %t3, i32 0, i32 1
  store i32 4, i32* %t5
  %t6 = load %geo__Point, %geo__Point* %t3
  store %geo__Point %t6, %geo__Point* %t2
  %t7 = load %geo__Point, %geo__Point* %t2
  %t9 = getelementptr inbounds %geo__Point, %geo__Point* %t8, i32 0, i32 0
  store i32 1, i32* %t9
  %t10 = getelementptr inbounds %geo__Point, %geo__Point* %t8, i32 0, i32 1
  store i32 2, i32* %t10
  %t11 = load %geo__Point, %geo__Point* %t8
  %t12 = call i32 @geo__dot(%geo__Point %t7, %geo__Point %t11)
  %t13 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t13, i32 %t12)
  %t15 = getelementptr inbounds %geo__Shape, %geo__Shape* %t14, i32 0, i32 0
  store i32 0, i32* %t15
  %t16 = getelementptr inbounds %geo__Shape, %geo__Shape* %t14, i32 0, i32 1
  %t17 = bitcast [1 x i64]* %t16 to { i32 }*
  %t18 = getelementptr inbounds { i32 }, { i32 }* %t17, i32 0, i32 0
  store i32 2, i32* %t18
  %t19 = load %geo__Shape, %geo__Shape* %t14
  %t20 = call i32 @geo__area(%geo__Shape %t19)
  %t21 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t21, i32 %t20)
  %t23 = getelementptr inbounds %geo__Shape, %geo__Shape* %t22, i32 0, i32 0
  store i32 1, i32* %t23
  %t24 = getelementptr inbounds %geo__Shape, %geo__Shape* %t22, i32 0, i32 1
  %t25 = bitcast [1 x i64]* %t24 to { i32, i32 }*
  %t26 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t25, i32 0, i32 0
  store i32 3, i32* %t26
  %t27 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t25, i32 0, i32 1
  store i32 4, i32* %t27
  %t28 = load %geo__Shape, %geo__Shape* %t22
  %t29 = call i32 @geo__area(%geo__Shape %t28)
  %t30 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t30, i32 %t29)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [9 x i8] c"dot: %d\0A\00"
@.str.1 = private unnamed_addr constant [17 x i8] c"circle area: %d\0A\00"
@.str.2 = private unnamed_addr constant [15 x i8] c"rect area: %d\0A\00"
