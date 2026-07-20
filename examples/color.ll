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
  %t2 = alloca <4 x float>
  %t20 = alloca <4 x float>
  %t31 = alloca <4 x float>
  %t42 = alloca i32
  %t85 = alloca i32
  %t100 = alloca <4 x float>
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = insertelement <4 x float> undef, float 0x3FF0000000000000, i32 0
  %t4 = insertelement <4 x float> %t3, float 0x3FE0000000000000, i32 1
  %t5 = insertelement <4 x float> %t4, float 0x0000000000000000, i32 2
  %t6 = insertelement <4 x float> %t5, float 0x3FF0000000000000, i32 3
  store <4 x float> %t6, <4 x float>* %t2
  %t7 = load <4 x float>, <4 x float>* %t2
  %t8 = extractelement <4 x float> %t7, i32 0
  %t9 = load <4 x float>, <4 x float>* %t2
  %t10 = extractelement <4 x float> %t9, i32 1
  %t11 = load <4 x float>, <4 x float>* %t2
  %t12 = extractelement <4 x float> %t11, i32 2
  %t13 = load <4 x float>, <4 x float>* %t2
  %t14 = extractelement <4 x float> %t13, i32 3
  %t15 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.0, i64 0, i64 0
  %t16 = fpext float %t8 to double
  %t17 = fpext float %t10 to double
  %t18 = fpext float %t12 to double
  %t19 = fpext float %t14 to double
  call i32 (i8*, ...) @printf(i8* %t15, double %t16, double %t17, double %t18, double %t19)
  %t21 = load <4 x float>, <4 x float>* %t2
  %t22 = insertelement <4 x float> undef, float 0x3FE0000000000000, i32 0
  %t23 = insertelement <4 x float> %t22, float 0x3FE0000000000000, i32 1
  %t24 = insertelement <4 x float> %t23, float 0x3FE0000000000000, i32 2
  %t25 = insertelement <4 x float> %t24, float 0x3FE0000000000000, i32 3
  %t26 = fmul <4 x float> %t21, %t25
  store <4 x float> %t26, <4 x float>* %t20
  %t27 = load <4 x float>, <4 x float>* %t20
  %t28 = extractelement <4 x float> %t27, i32 0
  %t29 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.1, i64 0, i64 0
  %t30 = fpext float %t28 to double
  call i32 (i8*, ...) @printf(i8* %t29, double %t30)
  %t32 = load <4 x float>, <4 x float>* %t2
  %t33 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t34 = insertelement <4 x float> %t33, float 0x0000000000000000, i32 1
  %t35 = insertelement <4 x float> %t34, float 0x3FF0000000000000, i32 2
  %t36 = insertelement <4 x float> %t35, float 0x0000000000000000, i32 3
  %t37 = fadd <4 x float> %t32, %t36
  store <4 x float> %t37, <4 x float>* %t31
  %t38 = load <4 x float>, <4 x float>* %t31
  %t39 = extractelement <4 x float> %t38, i32 2
  %t40 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.2, i64 0, i64 0
  %t41 = fpext float %t39 to double
  call i32 (i8*, ...) @printf(i8* %t40, double %t41)
  %t43 = load <4 x float>, <4 x float>* %t2
  %t44 = extractelement <4 x float> %t43, i32 0
  %t45 = call float @llvm.maxnum.f32(float %t44, float 0x0000000000000000)
  %t46 = call float @llvm.minnum.f32(float %t45, float 0x3FF0000000000000)
  %t47 = fmul float %t46, 0x406FE00000000000
  %t48 = call i32 @llvm.fptoui.sat.i32.f32(float %t47)
  %t49 = extractelement <4 x float> %t43, i32 1
  %t50 = call float @llvm.maxnum.f32(float %t49, float 0x0000000000000000)
  %t51 = call float @llvm.minnum.f32(float %t50, float 0x3FF0000000000000)
  %t52 = fmul float %t51, 0x406FE00000000000
  %t53 = call i32 @llvm.fptoui.sat.i32.f32(float %t52)
  %t54 = shl i32 %t53, 8
  %t55 = or i32 %t48, %t54
  %t56 = extractelement <4 x float> %t43, i32 2
  %t57 = call float @llvm.maxnum.f32(float %t56, float 0x0000000000000000)
  %t58 = call float @llvm.minnum.f32(float %t57, float 0x3FF0000000000000)
  %t59 = fmul float %t58, 0x406FE00000000000
  %t60 = call i32 @llvm.fptoui.sat.i32.f32(float %t59)
  %t61 = shl i32 %t60, 16
  %t62 = or i32 %t55, %t61
  %t63 = extractelement <4 x float> %t43, i32 3
  %t64 = call float @llvm.maxnum.f32(float %t63, float 0x0000000000000000)
  %t65 = call float @llvm.minnum.f32(float %t64, float 0x3FF0000000000000)
  %t66 = fmul float %t65, 0x406FE00000000000
  %t67 = call i32 @llvm.fptoui.sat.i32.f32(float %t66)
  %t68 = shl i32 %t67, 24
  %t69 = or i32 %t62, %t68
  store i32 %t69, i32* %t42
  %t70 = load i32, i32* %t42
  %t71 = and i32 %t70, 255
  %t72 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t72, i32 %t71)
  %t73 = load i32, i32* %t42
  %t74 = lshr i32 %t73, 8
  %t75 = and i32 %t74, 255
  %t76 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t76, i32 %t75)
  %t77 = load i32, i32* %t42
  %t78 = lshr i32 %t77, 16
  %t79 = and i32 %t78, 255
  %t80 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t80, i32 %t79)
  %t81 = load i32, i32* %t42
  %t82 = lshr i32 %t81, 24
  %t83 = and i32 %t82, 255
  %t84 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t84, i32 %t83)
  %t86 = and i32 255, 255
  %t87 = and i32 128, 255
  %t88 = shl i32 %t87, 8
  %t89 = or i32 %t86, %t88
  %t90 = and i32 64, 255
  %t91 = shl i32 %t90, 16
  %t92 = or i32 %t89, %t91
  %t93 = and i32 255, 255
  %t94 = shl i32 %t93, 24
  %t95 = or i32 %t92, %t94
  store i32 %t95, i32* %t85
  %t96 = load i32, i32* %t85
  %t97 = lshr i32 %t96, 8
  %t98 = and i32 %t97, 255
  %t99 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t99, i32 %t98)
  %t101 = load i32, i32* %t85
  %t102 = and i32 %t101, 255
  %t103 = uitofp i32 %t102 to float
  %t104 = fdiv float %t103, 0x406FE00000000000
  %t105 = insertelement <4 x float> undef, float %t104, i32 0
  %t106 = lshr i32 %t101, 8
  %t107 = and i32 %t106, 255
  %t108 = uitofp i32 %t107 to float
  %t109 = fdiv float %t108, 0x406FE00000000000
  %t110 = insertelement <4 x float> %t105, float %t109, i32 1
  %t111 = lshr i32 %t101, 16
  %t112 = and i32 %t111, 255
  %t113 = uitofp i32 %t112 to float
  %t114 = fdiv float %t113, 0x406FE00000000000
  %t115 = insertelement <4 x float> %t110, float %t114, i32 2
  %t116 = lshr i32 %t101, 24
  %t117 = and i32 %t116, 255
  %t118 = uitofp i32 %t117 to float
  %t119 = fdiv float %t118, 0x406FE00000000000
  %t120 = insertelement <4 x float> %t115, float %t119, i32 3
  store <4 x float> %t120, <4 x float>* %t100
  %t121 = load <4 x float>, <4 x float>* %t100
  %t122 = extractelement <4 x float> %t121, i32 0
  %t123 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.8, i64 0, i64 0
  %t124 = fpext float %t122 to double
  call i32 (i8*, ...) @printf(i8* %t123, double %t124)
  %t125 = load i32, i32* %t42
  %t126 = and i32 255, 255
  %t127 = and i32 127, 255
  %t128 = shl i32 %t127, 8
  %t129 = or i32 %t126, %t128
  %t130 = and i32 0, 255
  %t131 = shl i32 %t130, 16
  %t132 = or i32 %t129, %t131
  %t133 = and i32 255, 255
  %t134 = shl i32 %t133, 24
  %t135 = or i32 %t132, %t134
  %t136 = icmp eq i32 %t125, %t135
  %t137 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.9, i64 0, i64 0
  %t138 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.10, i64 0, i64 0
  %t139 = select i1 %t136, i8* %t137, i8* %t138
  %t140 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t140, i8* %t139)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [33 x i8] c"orange channels: %f, %f, %f, %f\0A\00"
@.str.1 = private unnamed_addr constant [24 x i8] c"dimmed red channel: %f\0A\00"
@.str.2 = private unnamed_addr constant [26 x i8] c"blended blue channel: %f\0A\00"
@.str.3 = private unnamed_addr constant [14 x i8] c"packed r: %d\0A\00"
@.str.4 = private unnamed_addr constant [14 x i8] c"packed g: %d\0A\00"
@.str.5 = private unnamed_addr constant [14 x i8] c"packed b: %d\0A\00"
@.str.6 = private unnamed_addr constant [14 x i8] c"packed a: %d\0A\00"
@.str.7 = private unnamed_addr constant [11 x i8] c"raw g: %d\0A\00"
@.str.8 = private unnamed_addr constant [16 x i8] c"restored r: %f\0A\00"
@.str.9 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.10 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.11 = private unnamed_addr constant [24 x i8] c"packed == packed is %s\0A\00"
