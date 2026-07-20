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
  %t2 = alloca i64
  %t4 = alloca i64
  %t6 = alloca i32
  %t19 = alloca i64
  %t28 = alloca i64
  %t30 = alloca i64
  %t32 = alloca i32
  %t45 = alloca i64
  %t61 = alloca i64
  %t63 = alloca i64
  %t65 = alloca i64
  %t74 = alloca i64
  %t88 = alloca i64
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = sext i32 0 to i64
  store i64 %t3, i64* %t2
  %t5 = load i64, i64* %t2
  store i64 %t5, i64* %t4
  store i32 0, i32* %t6
  br label %for_cond_0
for_cond_0:
  %t7 = load i32, i32* %t6
  %t8 = icmp slt i32 %t7, 60
  br i1 %t8, label %for_body_1, label %for_end_3
for_body_1:
  %t9 = load i64, i64* %t4
  %t10 = sext i32 1 to i64
  %t11 = call { i64, i1 } @llvm.sadd.with.overflow.i64(i64 %t9, i64 %t10)
  %t12 = extractvalue { i64, i1 } %t11, 0
  %t13 = extractvalue { i64, i1 } %t11, 1
  br i1 %t13, label %int_overflow_fail_4, label %int_overflow_ok_5
int_overflow_fail_4:
  %t14 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t14)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_5:
  store i64 %t12, i64* %t4
  br label %for_step_2
for_step_2:
  %t15 = load i32, i32* %t6
  %t16 = add i32 %t15, 1
  store i32 %t16, i32* %t6
  br label %for_cond_0
for_end_3:
  %t17 = load i64, i64* %t4
  %t18 = getelementptr inbounds [28 x i8], [28 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t18, i64 %t17)
  %t20 = load i64, i64* %t4
  %t21 = load i64, i64* %t2
  %t22 = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %t20, i64 %t21)
  %t23 = extractvalue { i64, i1 } %t22, 0
  %t24 = extractvalue { i64, i1 } %t22, 1
  br i1 %t24, label %int_overflow_fail_6, label %int_overflow_ok_7
int_overflow_fail_6:
  %t25 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t25)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_7:
  store i64 %t23, i64* %t19
  %t26 = load i64, i64* %t19
  %t27 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t27, i64 %t26)
  %t29 = sext i32 16666667 to i64
  store i64 %t29, i64* %t28
  %t31 = sext i32 0 to i64
  store i64 %t31, i64* %t30
  store i32 0, i32* %t32
  br label %for_cond_8
for_cond_8:
  %t33 = load i32, i32* %t32
  %t34 = icmp slt i32 %t33, 3
  br i1 %t34, label %for_body_9, label %for_end_11
for_body_9:
  %t35 = load i64, i64* %t30
  %t36 = load i64, i64* %t28
  %t37 = call { i64, i1 } @llvm.sadd.with.overflow.i64(i64 %t35, i64 %t36)
  %t38 = extractvalue { i64, i1 } %t37, 0
  %t39 = extractvalue { i64, i1 } %t37, 1
  br i1 %t39, label %int_overflow_fail_12, label %int_overflow_ok_13
int_overflow_fail_12:
  %t40 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t40)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_13:
  store i64 %t38, i64* %t30
  br label %for_step_10
for_step_10:
  %t41 = load i32, i32* %t32
  %t42 = add i32 %t41, 1
  store i32 %t42, i32* %t32
  br label %for_cond_8
for_end_11:
  %t43 = load i64, i64* %t30
  %t44 = getelementptr inbounds [41 x i8], [41 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t44, i64 %t43)
  %t46 = load i64, i64* %t30
  %t47 = load i64, i64* %t28
  %t48 = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %t46, i64 %t47)
  %t49 = extractvalue { i64, i1 } %t48, 0
  %t50 = extractvalue { i64, i1 } %t48, 1
  br i1 %t50, label %int_overflow_fail_14, label %int_overflow_ok_15
int_overflow_fail_14:
  %t51 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.6, i64 0, i64 0
  call i32 @puts(i8* %t51)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_15:
  store i64 %t49, i64* %t45
  %t52 = load i64, i64* %t45
  %t53 = getelementptr inbounds [47 x i8], [47 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t53, i64 %t52)
  %t54 = load i64, i64* %t28
  %t55 = load i64, i64* %t30
  %t56 = icmp slt i64 %t54, %t55
  %t57 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.8, i64 0, i64 0
  %t58 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.9, i64 0, i64 0
  %t59 = select i1 %t56, i8* %t57, i8* %t58
  %t60 = getelementptr inbounds [28 x i8], [28 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t60, i8* %t59)
  %t62 = sext i32 1000 to i64
  store i64 %t62, i64* %t61
  %t64 = sext i32 2500 to i64
  store i64 %t64, i64* %t63
  %t66 = load i64, i64* %t63
  %t67 = load i64, i64* %t61
  %t68 = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %t66, i64 %t67)
  %t69 = extractvalue { i64, i1 } %t68, 0
  %t70 = extractvalue { i64, i1 } %t68, 1
  br i1 %t70, label %int_overflow_fail_16, label %int_overflow_ok_17
int_overflow_fail_16:
  %t71 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.11, i64 0, i64 0
  call i32 @puts(i8* %t71)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_17:
  store i64 %t69, i64* %t65
  %t72 = load i64, i64* %t65
  %t73 = getelementptr inbounds [32 x i8], [32 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t73, i64 %t72)
  %t75 = load i64, i64* %t61
  %t76 = load i64, i64* %t65
  %t77 = call { i64, i1 } @llvm.sadd.with.overflow.i64(i64 %t75, i64 %t76)
  %t78 = extractvalue { i64, i1 } %t77, 0
  %t79 = extractvalue { i64, i1 } %t77, 1
  br i1 %t79, label %int_overflow_fail_18, label %int_overflow_ok_19
int_overflow_fail_18:
  %t80 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.13, i64 0, i64 0
  call i32 @puts(i8* %t80)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_19:
  store i64 %t78, i64* %t74
  %t81 = load i64, i64* %t74
  %t82 = load i64, i64* %t63
  %t83 = icmp eq i64 %t81, %t82
  %t84 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.14, i64 0, i64 0
  %t85 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.15, i64 0, i64 0
  %t86 = select i1 %t83, i8* %t84, i8* %t85
  %t87 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t87, i8* %t86)
  %t89 = load i64, i64* %t63
  %t90 = load i64, i64* %t65
  %t91 = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %t89, i64 %t90)
  %t92 = extractvalue { i64, i1 } %t91, 0
  %t93 = extractvalue { i64, i1 } %t91, 1
  br i1 %t93, label %int_overflow_fail_20, label %int_overflow_ok_21
int_overflow_fail_20:
  %t94 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.17, i64 0, i64 0
  call i32 @puts(i8* %t94)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_21:
  store i64 %t92, i64* %t88
  %t95 = load i64, i64* %t88
  %t96 = load i64, i64* %t61
  %t97 = icmp eq i64 %t95, %t96
  %t98 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.18, i64 0, i64 0
  %t99 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.19, i64 0, i64 0
  %t100 = select i1 %t97, i8* %t98, i8* %t99
  %t101 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.20, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t101, i8* %t100)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [69 x i8] c"star runtime error: signed 64-bit integer overflow in `+` operation\0A\00"
@.str.1 = private unnamed_addr constant [28 x i8] c"tick after 60 steps = %lld\0A\00"
@.str.2 = private unnamed_addr constant [69 x i8] c"star runtime error: signed 64-bit integer overflow in `-` operation\0A\00"
@.str.3 = private unnamed_addr constant [22 x i8] c"elapsed ticks = %lld\0A\00"
@.str.4 = private unnamed_addr constant [69 x i8] c"star runtime error: signed 64-bit integer overflow in `+` operation\0A\00"
@.str.5 = private unnamed_addr constant [41 x i8] c"total duration after 3 frames = %lld ns\0A\00"
@.str.6 = private unnamed_addr constant [69 x i8] c"star runtime error: signed 64-bit integer overflow in `-` operation\0A\00"
@.str.7 = private unnamed_addr constant [47 x i8] c"remaining after refunding one frame = %lld ns\0A\00"
@.str.8 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.9 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.10 = private unnamed_addr constant [28 x i8] c"frame_budget < total is %s\0A\00"
@.str.11 = private unnamed_addr constant [69 x i8] c"star runtime error: signed 64-bit integer overflow in `-` operation\0A\00"
@.str.12 = private unnamed_addr constant [32 x i8] c"gap between instants = %lld ns\0A\00"
@.str.13 = private unnamed_addr constant [69 x i8] c"star runtime error: signed 64-bit integer overflow in `+` operation\0A\00"
@.str.14 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.15 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.16 = private unnamed_addr constant [31 x i8] c"t0 shifted by gap == t1 is %s\0A\00"
@.str.17 = private unnamed_addr constant [69 x i8] c"star runtime error: signed 64-bit integer overflow in `-` operation\0A\00"
@.str.18 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.19 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.20 = private unnamed_addr constant [31 x i8] c"t1 rewound by gap == t0 is %s\0A\00"
