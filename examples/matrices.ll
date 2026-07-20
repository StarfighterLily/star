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
  %t2 = alloca [2 x <2 x float>]
  %t9 = alloca <2 x float>
  %t32 = alloca [2 x <2 x float>]
  %t39 = alloca [2 x <2 x float>]
  %t76 = alloca <2 x float>
  %t99 = alloca [2 x <2 x float>]
  %t110 = alloca <2 x float>
  %t130 = alloca [3 x <3 x float>]
  %t143 = alloca <3 x float>
  %t182 = alloca [3 x <3 x float>]
  %t195 = alloca <3 x float>
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = insertelement <2 x float> undef, float 0x4000000000000000, i32 0
  %t4 = insertelement <2 x float> %t3, float 0x0000000000000000, i32 1
  %t5 = insertvalue [2 x <2 x float>] undef, <2 x float> %t4, 0
  %t6 = insertelement <2 x float> undef, float 0x0000000000000000, i32 0
  %t7 = insertelement <2 x float> %t6, float 0x4008000000000000, i32 1
  %t8 = insertvalue [2 x <2 x float>] %t5, <2 x float> %t7, 1
  store [2 x <2 x float>] %t8, [2 x <2 x float>]* %t2
  %t10 = load [2 x <2 x float>], [2 x <2 x float>]* %t2
  %t11 = insertelement <2 x float> undef, float 0x3FF0000000000000, i32 0
  %t12 = insertelement <2 x float> %t11, float 0x3FF0000000000000, i32 1
  %t13 = extractvalue [2 x <2 x float>] %t10, 0
  %t14 = fmul <2 x float> %t13, %t12
  %t15 = extractelement <2 x float> %t14, i32 0
  %t16 = extractelement <2 x float> %t14, i32 1
  %t17 = fadd float %t15, %t16
  %t18 = extractvalue [2 x <2 x float>] %t10, 1
  %t19 = fmul <2 x float> %t18, %t12
  %t20 = extractelement <2 x float> %t19, i32 0
  %t21 = extractelement <2 x float> %t19, i32 1
  %t22 = fadd float %t20, %t21
  %t23 = insertelement <2 x float> undef, float %t17, i32 0
  %t24 = insertelement <2 x float> %t23, float %t22, i32 1
  store <2 x float> %t24, <2 x float>* %t9
  %t25 = load <2 x float>, <2 x float>* %t9
  %t26 = extractelement <2 x float> %t25, i32 0
  %t27 = load <2 x float>, <2 x float>* %t9
  %t28 = extractelement <2 x float> %t27, i32 1
  %t29 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.0, i64 0, i64 0
  %t30 = fpext float %t26 to double
  %t31 = fpext float %t28 to double
  call i32 (i8*, ...) @printf(i8* %t29, double %t30, double %t31)
  %t33 = insertelement <2 x float> undef, float 0x3FF0000000000000, i32 0
  %t34 = insertelement <2 x float> %t33, float 0x0000000000000000, i32 1
  %t35 = insertvalue [2 x <2 x float>] undef, <2 x float> %t34, 0
  %t36 = insertelement <2 x float> undef, float 0x0000000000000000, i32 0
  %t37 = insertelement <2 x float> %t36, float 0x3FF0000000000000, i32 1
  %t38 = insertvalue [2 x <2 x float>] %t35, <2 x float> %t37, 1
  store [2 x <2 x float>] %t38, [2 x <2 x float>]* %t32
  %t40 = load [2 x <2 x float>], [2 x <2 x float>]* %t2
  %t41 = load [2 x <2 x float>], [2 x <2 x float>]* %t32
  %t42 = extractvalue [2 x <2 x float>] %t40, 0
  %t43 = extractvalue [2 x <2 x float>] %t41, 0
  %t44 = extractvalue [2 x <2 x float>] %t40, 1
  %t45 = extractvalue [2 x <2 x float>] %t41, 1
  %t46 = extractelement <2 x float> %t43, i32 0
  %t47 = insertelement <2 x float> undef, float %t46, i32 0
  %t48 = extractelement <2 x float> %t45, i32 0
  %t49 = insertelement <2 x float> %t47, float %t48, i32 1
  %t50 = extractelement <2 x float> %t43, i32 1
  %t51 = insertelement <2 x float> undef, float %t50, i32 0
  %t52 = extractelement <2 x float> %t45, i32 1
  %t53 = insertelement <2 x float> %t51, float %t52, i32 1
  %t54 = fmul <2 x float> %t42, %t49
  %t55 = extractelement <2 x float> %t54, i32 0
  %t56 = extractelement <2 x float> %t54, i32 1
  %t57 = fadd float %t55, %t56
  %t58 = insertelement <2 x float> undef, float %t57, i32 0
  %t59 = fmul <2 x float> %t42, %t53
  %t60 = extractelement <2 x float> %t59, i32 0
  %t61 = extractelement <2 x float> %t59, i32 1
  %t62 = fadd float %t60, %t61
  %t63 = insertelement <2 x float> %t58, float %t62, i32 1
  %t64 = insertvalue [2 x <2 x float>] undef, <2 x float> %t63, 0
  %t65 = fmul <2 x float> %t44, %t49
  %t66 = extractelement <2 x float> %t65, i32 0
  %t67 = extractelement <2 x float> %t65, i32 1
  %t68 = fadd float %t66, %t67
  %t69 = insertelement <2 x float> undef, float %t68, i32 0
  %t70 = fmul <2 x float> %t44, %t53
  %t71 = extractelement <2 x float> %t70, i32 0
  %t72 = extractelement <2 x float> %t70, i32 1
  %t73 = fadd float %t71, %t72
  %t74 = insertelement <2 x float> %t69, float %t73, i32 1
  %t75 = insertvalue [2 x <2 x float>] %t64, <2 x float> %t74, 1
  store [2 x <2 x float>] %t75, [2 x <2 x float>]* %t39
  %t77 = load [2 x <2 x float>], [2 x <2 x float>]* %t39
  %t78 = insertelement <2 x float> undef, float 0x3FF0000000000000, i32 0
  %t79 = insertelement <2 x float> %t78, float 0x3FF0000000000000, i32 1
  %t80 = extractvalue [2 x <2 x float>] %t77, 0
  %t81 = fmul <2 x float> %t80, %t79
  %t82 = extractelement <2 x float> %t81, i32 0
  %t83 = extractelement <2 x float> %t81, i32 1
  %t84 = fadd float %t82, %t83
  %t85 = extractvalue [2 x <2 x float>] %t77, 1
  %t86 = fmul <2 x float> %t85, %t79
  %t87 = extractelement <2 x float> %t86, i32 0
  %t88 = extractelement <2 x float> %t86, i32 1
  %t89 = fadd float %t87, %t88
  %t90 = insertelement <2 x float> undef, float %t84, i32 0
  %t91 = insertelement <2 x float> %t90, float %t89, i32 1
  store <2 x float> %t91, <2 x float>* %t76
  %t92 = load <2 x float>, <2 x float>* %t76
  %t93 = extractelement <2 x float> %t92, i32 0
  %t94 = load <2 x float>, <2 x float>* %t76
  %t95 = extractelement <2 x float> %t94, i32 1
  %t96 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.1, i64 0, i64 0
  %t97 = fpext float %t93 to double
  %t98 = fpext float %t95 to double
  call i32 (i8*, ...) @printf(i8* %t96, double %t97, double %t98)
  %t100 = load [2 x <2 x float>], [2 x <2 x float>]* %t2
  %t101 = load [2 x <2 x float>], [2 x <2 x float>]* %t32
  %t102 = extractvalue [2 x <2 x float>] %t100, 0
  %t103 = extractvalue [2 x <2 x float>] %t101, 0
  %t104 = fadd <2 x float> %t102, %t103
  %t105 = insertvalue [2 x <2 x float>] undef, <2 x float> %t104, 0
  %t106 = extractvalue [2 x <2 x float>] %t100, 1
  %t107 = extractvalue [2 x <2 x float>] %t101, 1
  %t108 = fadd <2 x float> %t106, %t107
  %t109 = insertvalue [2 x <2 x float>] %t105, <2 x float> %t108, 1
  store [2 x <2 x float>] %t109, [2 x <2 x float>]* %t99
  %t111 = load [2 x <2 x float>], [2 x <2 x float>]* %t99
  %t112 = insertelement <2 x float> undef, float 0x3FF0000000000000, i32 0
  %t113 = insertelement <2 x float> %t112, float 0x0000000000000000, i32 1
  %t114 = extractvalue [2 x <2 x float>] %t111, 0
  %t115 = fmul <2 x float> %t114, %t113
  %t116 = extractelement <2 x float> %t115, i32 0
  %t117 = extractelement <2 x float> %t115, i32 1
  %t118 = fadd float %t116, %t117
  %t119 = extractvalue [2 x <2 x float>] %t111, 1
  %t120 = fmul <2 x float> %t119, %t113
  %t121 = extractelement <2 x float> %t120, i32 0
  %t122 = extractelement <2 x float> %t120, i32 1
  %t123 = fadd float %t121, %t122
  %t124 = insertelement <2 x float> undef, float %t118, i32 0
  %t125 = insertelement <2 x float> %t124, float %t123, i32 1
  store <2 x float> %t125, <2 x float>* %t110
  %t126 = load <2 x float>, <2 x float>* %t110
  %t127 = extractelement <2 x float> %t126, i32 0
  %t128 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.2, i64 0, i64 0
  %t129 = fpext float %t127 to double
  call i32 (i8*, ...) @printf(i8* %t128, double %t129)
  %t131 = insertelement <3 x float> undef, float 0x3FF0000000000000, i32 0
  %t132 = insertelement <3 x float> %t131, float 0x0000000000000000, i32 1
  %t133 = insertelement <3 x float> %t132, float 0x0000000000000000, i32 2
  %t134 = insertvalue [3 x <3 x float>] undef, <3 x float> %t133, 0
  %t135 = insertelement <3 x float> undef, float 0x0000000000000000, i32 0
  %t136 = insertelement <3 x float> %t135, float 0x3FF0000000000000, i32 1
  %t137 = insertelement <3 x float> %t136, float 0x0000000000000000, i32 2
  %t138 = insertvalue [3 x <3 x float>] %t134, <3 x float> %t137, 1
  %t139 = insertelement <3 x float> undef, float 0x0000000000000000, i32 0
  %t140 = insertelement <3 x float> %t139, float 0x0000000000000000, i32 1
  %t141 = insertelement <3 x float> %t140, float 0x3FF0000000000000, i32 2
  %t142 = insertvalue [3 x <3 x float>] %t138, <3 x float> %t141, 2
  store [3 x <3 x float>] %t142, [3 x <3 x float>]* %t130
  %t144 = load [3 x <3 x float>], [3 x <3 x float>]* %t130
  %t145 = insertelement <3 x float> undef, float 0x4014000000000000, i32 0
  %t146 = insertelement <3 x float> %t145, float 0x4018000000000000, i32 1
  %t147 = insertelement <3 x float> %t146, float 0x401C000000000000, i32 2
  %t148 = extractvalue [3 x <3 x float>] %t144, 0
  %t149 = fmul <3 x float> %t148, %t147
  %t150 = extractelement <3 x float> %t149, i32 0
  %t151 = extractelement <3 x float> %t149, i32 1
  %t152 = fadd float %t150, %t151
  %t153 = extractelement <3 x float> %t149, i32 2
  %t154 = fadd float %t152, %t153
  %t155 = extractvalue [3 x <3 x float>] %t144, 1
  %t156 = fmul <3 x float> %t155, %t147
  %t157 = extractelement <3 x float> %t156, i32 0
  %t158 = extractelement <3 x float> %t156, i32 1
  %t159 = fadd float %t157, %t158
  %t160 = extractelement <3 x float> %t156, i32 2
  %t161 = fadd float %t159, %t160
  %t162 = extractvalue [3 x <3 x float>] %t144, 2
  %t163 = fmul <3 x float> %t162, %t147
  %t164 = extractelement <3 x float> %t163, i32 0
  %t165 = extractelement <3 x float> %t163, i32 1
  %t166 = fadd float %t164, %t165
  %t167 = extractelement <3 x float> %t163, i32 2
  %t168 = fadd float %t166, %t167
  %t169 = insertelement <3 x float> undef, float %t154, i32 0
  %t170 = insertelement <3 x float> %t169, float %t161, i32 1
  %t171 = insertelement <3 x float> %t170, float %t168, i32 2
  store <3 x float> %t171, <3 x float>* %t143
  %t172 = load <3 x float>, <3 x float>* %t143
  %t173 = extractelement <3 x float> %t172, i32 0
  %t174 = load <3 x float>, <3 x float>* %t143
  %t175 = extractelement <3 x float> %t174, i32 1
  %t176 = load <3 x float>, <3 x float>* %t143
  %t177 = extractelement <3 x float> %t176, i32 2
  %t178 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.3, i64 0, i64 0
  %t179 = fpext float %t173 to double
  %t180 = fpext float %t175 to double
  %t181 = fpext float %t177 to double
  call i32 (i8*, ...) @printf(i8* %t178, double %t179, double %t180, double %t181)
  %t183 = insertelement <3 x float> undef, float 0x0000000000000000, i32 0
  %t184 = insertelement <3 x float> %t183, float 0x3FF0000000000000, i32 1
  %t185 = insertelement <3 x float> %t184, float 0x0000000000000000, i32 2
  %t186 = insertvalue [3 x <3 x float>] undef, <3 x float> %t185, 0
  %t187 = insertelement <3 x float> undef, float 0x3FF0000000000000, i32 0
  %t188 = insertelement <3 x float> %t187, float 0x0000000000000000, i32 1
  %t189 = insertelement <3 x float> %t188, float 0x0000000000000000, i32 2
  %t190 = insertvalue [3 x <3 x float>] %t186, <3 x float> %t189, 1
  %t191 = insertelement <3 x float> undef, float 0x0000000000000000, i32 0
  %t192 = insertelement <3 x float> %t191, float 0x0000000000000000, i32 1
  %t193 = insertelement <3 x float> %t192, float 0x3FF0000000000000, i32 2
  %t194 = insertvalue [3 x <3 x float>] %t190, <3 x float> %t193, 2
  store [3 x <3 x float>] %t194, [3 x <3 x float>]* %t182
  %t196 = load [3 x <3 x float>], [3 x <3 x float>]* %t182
  %t197 = insertelement <3 x float> undef, float 0x3FF0000000000000, i32 0
  %t198 = insertelement <3 x float> %t197, float 0x4000000000000000, i32 1
  %t199 = insertelement <3 x float> %t198, float 0x4008000000000000, i32 2
  %t200 = extractvalue [3 x <3 x float>] %t196, 0
  %t201 = fmul <3 x float> %t200, %t199
  %t202 = extractelement <3 x float> %t201, i32 0
  %t203 = extractelement <3 x float> %t201, i32 1
  %t204 = fadd float %t202, %t203
  %t205 = extractelement <3 x float> %t201, i32 2
  %t206 = fadd float %t204, %t205
  %t207 = extractvalue [3 x <3 x float>] %t196, 1
  %t208 = fmul <3 x float> %t207, %t199
  %t209 = extractelement <3 x float> %t208, i32 0
  %t210 = extractelement <3 x float> %t208, i32 1
  %t211 = fadd float %t209, %t210
  %t212 = extractelement <3 x float> %t208, i32 2
  %t213 = fadd float %t211, %t212
  %t214 = extractvalue [3 x <3 x float>] %t196, 2
  %t215 = fmul <3 x float> %t214, %t199
  %t216 = extractelement <3 x float> %t215, i32 0
  %t217 = extractelement <3 x float> %t215, i32 1
  %t218 = fadd float %t216, %t217
  %t219 = extractelement <3 x float> %t215, i32 2
  %t220 = fadd float %t218, %t219
  %t221 = insertelement <3 x float> undef, float %t206, i32 0
  %t222 = insertelement <3 x float> %t221, float %t213, i32 1
  %t223 = insertelement <3 x float> %t222, float %t220, i32 2
  store <3 x float> %t223, <3 x float>* %t195
  %t224 = load <3 x float>, <3 x float>* %t195
  %t225 = extractelement <3 x float> %t224, i32 0
  %t226 = load <3 x float>, <3 x float>* %t195
  %t227 = extractelement <3 x float> %t226, i32 1
  %t228 = load <3 x float>, <3 x float>* %t195
  %t229 = extractelement <3 x float> %t228, i32 2
  %t230 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.4, i64 0, i64 0
  %t231 = fpext float %t225 to double
  %t232 = fpext float %t227 to double
  %t233 = fpext float %t229 to double
  call i32 (i8*, ...) @printf(i8* %t230, double %t231, double %t232, double %t233)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [20 x i8] c"Mat2 scale: %f, %f\0A\00"
@.str.1 = private unnamed_addr constant [25 x i8] c"Mat2 * identity: %f, %f\0A\00"
@.str.2 = private unnamed_addr constant [21 x i8] c"Mat2 sum row0.x: %f\0A\00"
@.str.3 = private unnamed_addr constant [27 x i8] c"Mat3 identity: %f, %f, %f\0A\00"
@.str.4 = private unnamed_addr constant [26 x i8] c"Mat3 swap xy: %f, %f, %f\0A\00"
