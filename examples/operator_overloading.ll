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

%Point = type { i32, i32 }
%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define %Point @Point__add(%Point* %self, %Point %rhs) {
entry:
  %t0 = alloca %Point*
  %t1 = alloca %Point
  %t2 = alloca %Point
  store %Point* %self, %Point** %t0
  store %Point %rhs, %Point* %t1
  %t3 = load %Point*, %Point** %t0
  %t4 = getelementptr inbounds %Point, %Point* %t3, i32 0, i32 0
  %t5 = load i32, i32* %t4
  %t6 = getelementptr inbounds %Point, %Point* %t1, i32 0, i32 0
  %t7 = load i32, i32* %t6
  %t8 = add i32 %t5, %t7
  %t9 = getelementptr inbounds %Point, %Point* %t2, i32 0, i32 0
  store i32 %t8, i32* %t9
  %t10 = load %Point*, %Point** %t0
  %t11 = getelementptr inbounds %Point, %Point* %t10, i32 0, i32 1
  %t12 = load i32, i32* %t11
  %t13 = getelementptr inbounds %Point, %Point* %t1, i32 0, i32 1
  %t14 = load i32, i32* %t13
  %t15 = add i32 %t12, %t14
  %t16 = getelementptr inbounds %Point, %Point* %t2, i32 0, i32 1
  store i32 %t15, i32* %t16
  %t17 = load %Point, %Point* %t2
  ret %Point %t17
}

define %Point @Point__sub(%Point* %self, %Point %rhs) {
entry:
  %t0 = alloca %Point*
  %t1 = alloca %Point
  %t2 = alloca %Point
  store %Point* %self, %Point** %t0
  store %Point %rhs, %Point* %t1
  %t3 = load %Point*, %Point** %t0
  %t4 = getelementptr inbounds %Point, %Point* %t3, i32 0, i32 0
  %t5 = load i32, i32* %t4
  %t6 = getelementptr inbounds %Point, %Point* %t1, i32 0, i32 0
  %t7 = load i32, i32* %t6
  %t8 = sub i32 %t5, %t7
  %t9 = getelementptr inbounds %Point, %Point* %t2, i32 0, i32 0
  store i32 %t8, i32* %t9
  %t10 = load %Point*, %Point** %t0
  %t11 = getelementptr inbounds %Point, %Point* %t10, i32 0, i32 1
  %t12 = load i32, i32* %t11
  %t13 = getelementptr inbounds %Point, %Point* %t1, i32 0, i32 1
  %t14 = load i32, i32* %t13
  %t15 = sub i32 %t12, %t14
  %t16 = getelementptr inbounds %Point, %Point* %t2, i32 0, i32 1
  store i32 %t15, i32* %t16
  %t17 = load %Point, %Point* %t2
  ret %Point %t17
}

define i1 @Point__eq(%Point* %self, %Point %rhs) {
entry:
  %t0 = alloca %Point*
  %t1 = alloca %Point
  store %Point* %self, %Point** %t0
  store %Point %rhs, %Point* %t1
  %t2 = load %Point*, %Point** %t0
  %t3 = getelementptr inbounds %Point, %Point* %t2, i32 0, i32 0
  %t4 = load i32, i32* %t3
  %t5 = getelementptr inbounds %Point, %Point* %t1, i32 0, i32 0
  %t6 = load i32, i32* %t5
  %t7 = icmp eq i32 %t4, %t6
  br i1 %t7, label %logic_rhs_0, label %logic_short_1
logic_rhs_0:
  %t8 = load %Point*, %Point** %t0
  %t9 = getelementptr inbounds %Point, %Point* %t8, i32 0, i32 1
  %t10 = load i32, i32* %t9
  %t11 = getelementptr inbounds %Point, %Point* %t1, i32 0, i32 1
  %t12 = load i32, i32* %t11
  %t13 = icmp eq i32 %t10, %t12
  br label %logic_end_2
logic_short_1:
  br label %logic_end_2
logic_end_2:
  %t14 = phi i1 [ %t13, %logic_rhs_0 ], [ false, %logic_short_1 ]
  ret i1 %t14
}

define i1 @Point__lt(%Point* %self, %Point %rhs) {
entry:
  %t0 = alloca %Point*
  %t1 = alloca %Point
  store %Point* %self, %Point** %t0
  store %Point %rhs, %Point* %t1
  %t2 = load %Point*, %Point** %t0
  %t3 = getelementptr inbounds %Point, %Point* %t2, i32 0, i32 0
  %t4 = load i32, i32* %t3
  %t5 = getelementptr inbounds %Point, %Point* %t1, i32 0, i32 0
  %t6 = load i32, i32* %t5
  %t7 = icmp slt i32 %t4, %t6
  ret i1 %t7
}

define i1 @Point__gt(%Point* %self, %Point %rhs) {
entry:
  %t0 = alloca %Point*
  %t1 = alloca %Point
  store %Point* %self, %Point** %t0
  store %Point %rhs, %Point* %t1
  %t2 = load %Point*, %Point** %t0
  %t3 = getelementptr inbounds %Point, %Point* %t2, i32 0, i32 0
  %t4 = load i32, i32* %t3
  %t5 = getelementptr inbounds %Point, %Point* %t1, i32 0, i32 0
  %t6 = load i32, i32* %t5
  %t7 = icmp sgt i32 %t4, %t6
  ret i1 %t7
}

define %Point @Point__neg(%Point* %self) {
entry:
  %t0 = alloca %Point*
  %t1 = alloca %Point
  store %Point* %self, %Point** %t0
  %t2 = load %Point*, %Point** %t0
  %t3 = getelementptr inbounds %Point, %Point* %t2, i32 0, i32 0
  %t4 = load i32, i32* %t3
  %t5 = sub i32 0, %t4
  %t6 = getelementptr inbounds %Point, %Point* %t1, i32 0, i32 0
  store i32 %t5, i32* %t6
  %t7 = load %Point*, %Point** %t0
  %t8 = getelementptr inbounds %Point, %Point* %t7, i32 0, i32 1
  %t9 = load i32, i32* %t8
  %t10 = sub i32 0, %t9
  %t11 = getelementptr inbounds %Point, %Point* %t1, i32 0, i32 1
  store i32 %t10, i32* %t11
  %t12 = load %Point, %Point* %t1
  ret %Point %t12
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca %Point
  %t3 = alloca %Point
  %t7 = alloca %Point
  %t8 = alloca %Point
  %t12 = alloca %Point
  %t20 = alloca %Point
  %t28 = alloca %Point
  %t54 = alloca %Point
  %t55 = alloca %Point
  %t59 = alloca %Point
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t4 = getelementptr inbounds %Point, %Point* %t3, i32 0, i32 0
  store i32 1, i32* %t4
  %t5 = getelementptr inbounds %Point, %Point* %t3, i32 0, i32 1
  store i32 2, i32* %t5
  %t6 = load %Point, %Point* %t3
  store %Point %t6, %Point* %t2
  %t9 = getelementptr inbounds %Point, %Point* %t8, i32 0, i32 0
  store i32 3, i32* %t9
  %t10 = getelementptr inbounds %Point, %Point* %t8, i32 0, i32 1
  store i32 4, i32* %t10
  %t11 = load %Point, %Point* %t8
  store %Point %t11, %Point* %t7
  %t13 = load %Point, %Point* %t7
  %t14 = call %Point @Point__add(%Point* %t2, %Point %t13)
  store %Point %t14, %Point* %t12
  %t15 = getelementptr inbounds %Point, %Point* %t12, i32 0, i32 0
  %t16 = load i32, i32* %t15
  %t17 = getelementptr inbounds %Point, %Point* %t12, i32 0, i32 1
  %t18 = load i32, i32* %t17
  %t19 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t19, i32 %t16, i32 %t18)
  %t21 = load %Point, %Point* %t7
  %t22 = call %Point @Point__sub(%Point* %t2, %Point %t21)
  store %Point %t22, %Point* %t20
  %t23 = getelementptr inbounds %Point, %Point* %t20, i32 0, i32 0
  %t24 = load i32, i32* %t23
  %t25 = getelementptr inbounds %Point, %Point* %t20, i32 0, i32 1
  %t26 = load i32, i32* %t25
  %t27 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t27, i32 %t24, i32 %t26)
  %t29 = call %Point @Point__neg(%Point* %t2)
  store %Point %t29, %Point* %t28
  %t30 = getelementptr inbounds %Point, %Point* %t28, i32 0, i32 0
  %t31 = load i32, i32* %t30
  %t32 = getelementptr inbounds %Point, %Point* %t28, i32 0, i32 1
  %t33 = load i32, i32* %t32
  %t34 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t34, i32 %t31, i32 %t33)
  %t35 = load %Point, %Point* %t2
  %t36 = call i1 @Point__eq(%Point* %t2, %Point %t35)
  %t37 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.3, i64 0, i64 0
  %t38 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.4, i64 0, i64 0
  %t39 = select i1 %t36, i8* %t37, i8* %t38
  %t40 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t40, i8* %t39)
  %t41 = load %Point, %Point* %t7
  %t42 = call i1 @Point__eq(%Point* %t2, %Point %t41)
  %t43 = xor i1 true, %t42
  %t44 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.6, i64 0, i64 0
  %t45 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.7, i64 0, i64 0
  %t46 = select i1 %t43, i8* %t44, i8* %t45
  %t47 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t47, i8* %t46)
  %t48 = load %Point, %Point* %t7
  %t49 = call i1 @Point__lt(%Point* %t2, %Point %t48)
  %t50 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.9, i64 0, i64 0
  %t51 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.10, i64 0, i64 0
  %t52 = select i1 %t49, i8* %t50, i8* %t51
  %t53 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t53, i8* %t52)
  %t56 = getelementptr inbounds %Point, %Point* %t55, i32 0, i32 0
  store i32 2, i32* %t56
  %t57 = getelementptr inbounds %Point, %Point* %t55, i32 0, i32 1
  store i32 3, i32* %t57
  %t58 = load %Point, %Point* %t55
  %t60 = getelementptr inbounds %Point, %Point* %t59, i32 0, i32 0
  store i32 4, i32* %t60
  %t61 = getelementptr inbounds %Point, %Point* %t59, i32 0, i32 1
  store i32 6, i32* %t61
  %t62 = load %Point, %Point* %t59
  %t63 = call %Point @total__Point(%Point %t58, %Point %t62)
  store %Point %t63, %Point* %t54
  %t64 = getelementptr inbounds %Point, %Point* %t54, i32 0, i32 0
  %t65 = load i32, i32* %t64
  %t66 = getelementptr inbounds %Point, %Point* %t54, i32 0, i32 1
  %t67 = load i32, i32* %t66
  %t68 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t68, i32 %t65, i32 %t67)
  ret i32 0
}

define %Point @total__Point(%Point %a, %Point %b) {
entry:
  %t0 = alloca %Point
  %t1 = alloca %Point
  store %Point %a, %Point* %t0
  store %Point %b, %Point* %t1
  %t2 = load %Point, %Point* %t1
  %t3 = call %Point @Point__add(%Point* %t0, %Point %t2)
  ret %Point %t3
}


; Global Constants
@.str.0 = private unnamed_addr constant [13 x i8] c"sum: %d, %d\0A\00"
@.str.1 = private unnamed_addr constant [14 x i8] c"diff: %d, %d\0A\00"
@.str.2 = private unnamed_addr constant [13 x i8] c"neg: %d, %d\0A\00"
@.str.3 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.4 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.5 = private unnamed_addr constant [8 x i8] c"eq: %s\0A\00"
@.str.6 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.7 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.8 = private unnamed_addr constant [8 x i8] c"ne: %s\0A\00"
@.str.9 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.10 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.11 = private unnamed_addr constant [8 x i8] c"lt: %s\0A\00"
@.str.12 = private unnamed_addr constant [15 x i8] c"total: %d, %d\0A\00"
