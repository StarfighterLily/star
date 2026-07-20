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
  %t2 = alloca i8
  %t74 = alloca i8
  %t76 = alloca i8
  %t83 = alloca i8
  %t90 = alloca i8
  %t96 = alloca i8
  %t117 = alloca i8
  %t122 = alloca i8
  %t131 = alloca i32
  %t147 = alloca i64
  %t155 = alloca i32
  %t156 = alloca i32
  %t163 = alloca i8
  %t165 = alloca i8
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  store i8 0, i8* %t2
  %t3 = load i8, i8* %t2
  %t4 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.0, i64 0, i64 0
  %t5 = zext i8 %t3 to i32
  call i32 (i8*, ...) @printf(i8* %t4, i32 %t5)
  %t6 = load i8, i8* %t2
  %t7 = and i32 0, 7
  %t8 = trunc i32 %t7 to i8
  %t9 = shl i8 1, %t8
  %t10 = or i8 %t6, %t9
  store i8 %t10, i8* %t2
  %t11 = load i8, i8* %t2
  %t12 = and i32 1, 7
  %t13 = trunc i32 %t12 to i8
  %t14 = shl i8 1, %t13
  %t15 = or i8 %t11, %t14
  store i8 %t15, i8* %t2
  %t16 = load i8, i8* %t2
  %t17 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.1, i64 0, i64 0
  %t18 = zext i8 %t16 to i32
  call i32 (i8*, ...) @printf(i8* %t17, i32 %t18)
  %t19 = load i8, i8* %t2
  %t20 = and i32 0, 7
  %t21 = trunc i32 %t20 to i8
  %t22 = shl i8 1, %t21
  %t23 = and i8 %t19, %t22
  %t24 = icmp ne i8 %t23, 0
  %t25 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.2, i64 0, i64 0
  %t26 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.3, i64 0, i64 0
  %t27 = select i1 %t24, i8* %t25, i8* %t26
  %t28 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t28, i8* %t27)
  %t29 = load i8, i8* %t2
  %t30 = and i32 2, 7
  %t31 = trunc i32 %t30 to i8
  %t32 = shl i8 1, %t31
  %t33 = and i8 %t29, %t32
  %t34 = icmp ne i8 %t33, 0
  %t35 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.5, i64 0, i64 0
  %t36 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.6, i64 0, i64 0
  %t37 = select i1 %t34, i8* %t35, i8* %t36
  %t38 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t38, i8* %t37)
  %t39 = load i8, i8* %t2
  %t40 = and i32 0, 7
  %t41 = trunc i32 %t40 to i8
  %t42 = shl i8 1, %t41
  %t44 = xor i8 %t42, -1
  %t43 = and i8 %t39, %t44
  store i8 %t43, i8* %t2
  %t45 = load i8, i8* %t2
  %t46 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.8, i64 0, i64 0
  %t47 = zext i8 %t45 to i32
  call i32 (i8*, ...) @printf(i8* %t46, i32 %t47)
  %t48 = load i8, i8* %t2
  %t49 = and i32 0, 7
  %t50 = trunc i32 %t49 to i8
  %t51 = shl i8 1, %t50
  %t52 = and i8 %t48, %t51
  %t53 = icmp ne i8 %t52, 0
  %t54 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.9, i64 0, i64 0
  %t55 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.10, i64 0, i64 0
  %t56 = select i1 %t53, i8* %t54, i8* %t55
  %t57 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t57, i8* %t56)
  %t58 = load i8, i8* %t2
  %t59 = and i32 2, 7
  %t60 = trunc i32 %t59 to i8
  %t61 = shl i8 1, %t60
  %t62 = xor i8 %t58, %t61
  store i8 %t62, i8* %t2
  %t63 = load i8, i8* %t2
  %t64 = getelementptr inbounds [32 x i8], [32 x i8]* @.str.12, i64 0, i64 0
  %t65 = zext i8 %t63 to i32
  call i32 (i8*, ...) @printf(i8* %t64, i32 %t65)
  %t66 = load i8, i8* %t2
  %t67 = and i32 2, 7
  %t68 = trunc i32 %t67 to i8
  %t69 = shl i8 1, %t68
  %t70 = xor i8 %t66, %t69
  store i8 %t70, i8* %t2
  %t71 = load i8, i8* %t2
  %t72 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.13, i64 0, i64 0
  %t73 = zext i8 %t71 to i32
  call i32 (i8*, ...) @printf(i8* %t72, i32 %t73)
  %t75 = trunc i32 15 to i8
  store i8 %t75, i8* %t74
  %t77 = load i8, i8* %t2
  %t78 = load i8, i8* %t74
  %t79 = or i8 %t77, %t78
  store i8 %t79, i8* %t76
  %t80 = load i8, i8* %t76
  %t81 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.14, i64 0, i64 0
  %t82 = zext i8 %t80 to i32
  call i32 (i8*, ...) @printf(i8* %t81, i32 %t82)
  %t84 = load i8, i8* %t76
  %t85 = load i8, i8* %t74
  %t86 = and i8 %t84, %t85
  store i8 %t86, i8* %t83
  %t87 = load i8, i8* %t83
  %t88 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.15, i64 0, i64 0
  %t89 = zext i8 %t87 to i32
  call i32 (i8*, ...) @printf(i8* %t88, i32 %t89)
  %t91 = load i8, i8* %t74
  %t92 = xor i8 %t91, -1
  store i8 %t92, i8* %t90
  %t93 = load i8, i8* %t90
  %t94 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.16, i64 0, i64 0
  %t95 = zext i8 %t93 to i32
  call i32 (i8*, ...) @printf(i8* %t94, i32 %t95)
  %t97 = load i8, i8* %t74
  %t98 = load i8, i8* %t74
  %t99 = xor i8 %t97, %t98
  store i8 %t99, i8* %t96
  %t100 = load i8, i8* %t96
  %t101 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.17, i64 0, i64 0
  %t102 = zext i8 %t100 to i32
  call i32 (i8*, ...) @printf(i8* %t101, i32 %t102)
  %t103 = load i8, i8* %t74
  %t104 = load i8, i8* %t74
  %t105 = icmp eq i8 %t103, %t104
  %t106 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.18, i64 0, i64 0
  %t107 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.19, i64 0, i64 0
  %t108 = select i1 %t105, i8* %t106, i8* %t107
  %t109 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.20, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t109, i8* %t108)
  %t110 = load i8, i8* %t74
  %t111 = load i8, i8* %t76
  %t112 = icmp ne i8 %t110, %t111
  %t113 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.21, i64 0, i64 0
  %t114 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.22, i64 0, i64 0
  %t115 = select i1 %t112, i8* %t113, i8* %t114
  %t116 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.23, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t116, i8* %t115)
  %t118 = load i8, i8* %t74
  store i8 %t118, i8* %t117
  %t119 = load i8, i8* %t117
  %t120 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.24, i64 0, i64 0
  %t121 = zext i8 %t119 to i32
  call i32 (i8*, ...) @printf(i8* %t120, i32 %t121)
  %t123 = load i8, i8* %t117
  store i8 %t123, i8* %t122
  %t124 = load i8, i8* %t122
  %t125 = load i8, i8* %t74
  %t126 = icmp eq i8 %t124, %t125
  %t127 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.25, i64 0, i64 0
  %t128 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.26, i64 0, i64 0
  %t129 = select i1 %t126, i8* %t127, i8* %t128
  %t130 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.27, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t130, i8* %t129)
  store i32 0, i32* %t131
  %t132 = load i32, i32* %t131
  %t133 = and i32 31, 31
  %t134 = shl i32 1, %t133
  %t135 = or i32 %t132, %t134
  store i32 %t135, i32* %t131
  %t136 = load i32, i32* %t131
  %t137 = getelementptr inbounds [38 x i8], [38 x i8]* @.str.28, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t137, i32 %t136)
  %t138 = load i32, i32* %t131
  %t139 = and i32 31, 31
  %t140 = shl i32 1, %t139
  %t141 = and i32 %t138, %t140
  %t142 = icmp ne i32 %t141, 0
  %t143 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.29, i64 0, i64 0
  %t144 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.30, i64 0, i64 0
  %t145 = select i1 %t142, i8* %t143, i8* %t144
  %t146 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.31, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t146, i8* %t145)
  store i64 0, i64* %t147
  %t148 = load i64, i64* %t147
  %t149 = and i32 63, 63
  %t150 = zext i32 %t149 to i64
  %t151 = shl i64 1, %t150
  %t152 = or i64 %t148, %t151
  store i64 %t152, i64* %t147
  %t153 = load i64, i64* %t147
  %t154 = getelementptr inbounds [40 x i8], [40 x i8]* @.str.32, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t154, i64 %t153)
  store i32 0, i32* %t155
  %t157 = load i32, i32* %t155
  %t158 = and i32 4, 31
  %t159 = shl i32 1, %t158
  %t160 = or i32 %t157, %t159
  store i32 %t160, i32* %t156
  %t161 = load i32, i32* %t156
  %t162 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.33, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t162, i32 %t161)
  %t164 = trunc i32 0 to i8
  store i8 %t164, i8* %t163
  %t166 = load i8, i8* %t163
  %t167 = and i32 7, 7
  %t168 = trunc i32 %t167 to i8
  %t169 = shl i8 1, %t168
  %t170 = or i8 %t166, %t169
  store i8 %t170, i8* %t165
  %t171 = load i8, i8* %t165
  %t172 = getelementptr inbounds [32 x i8], [32 x i8]* @.str.34, i64 0, i64 0
  %t173 = zext i8 %t171 to i32
  call i32 (i8*, ...) @printf(i8* %t172, i32 %t173)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [21 x i8] c"initial status = %u\0A\00"
@.str.1 = private unnamed_addr constant [33 x i8] c"after setting bits 0 and 1 = %u\0A\00"
@.str.2 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.3 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.4 = private unnamed_addr constant [23 x i8] c"bit 0 (carry) set? %s\0A\00"
@.str.5 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.6 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.7 = private unnamed_addr constant [23 x i8] c"bit 2 (unset) set? %s\0A\00"
@.str.8 = private unnamed_addr constant [27 x i8] c"after clearing bit 0 = %u\0A\00"
@.str.9 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.10 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.11 = private unnamed_addr constant [15 x i8] c"bit 0 set? %s\0A\00"
@.str.12 = private unnamed_addr constant [32 x i8] c"after toggling bit 2 once = %u\0A\00"
@.str.13 = private unnamed_addr constant [33 x i8] c"after toggling bit 2 twice = %u\0A\00"
@.str.14 = private unnamed_addr constant [20 x i8] c"status | 0x0F = %u\0A\00"
@.str.15 = private unnamed_addr constant [29 x i8] c"(status | 0x0F) & 0x0F = %u\0A\00"
@.str.16 = private unnamed_addr constant [12 x i8] c"~0x0F = %u\0A\00"
@.str.17 = private unnamed_addr constant [18 x i8] c"0x0F ^ 0x0F = %u\0A\00"
@.str.18 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.19 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.20 = private unnamed_addr constant [20 x i8] c"mask == mask is %s\0A\00"
@.str.21 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.22 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.23 = private unnamed_addr constant [24 x i8] c"mask != combined is %s\0A\00"
@.str.24 = private unnamed_addr constant [17 x i8] c"mask as u8 = %u\0A\00"
@.str.25 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.26 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.27 = private unnamed_addr constant [25 x i8] c"roundtrip == mask is %s\0A\00"
@.str.28 = private unnamed_addr constant [38 x i8] c"bit 31 of a 32-bit register set = %u\0A\00"
@.str.29 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.30 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.31 = private unnamed_addr constant [16 x i8] c"bit 31 set? %s\0A\00"
@.str.32 = private unnamed_addr constant [40 x i8] c"bit 63 of a 64-bit register set = %llu\0A\00"
@.str.33 = private unnamed_addr constant [29 x i8] c"bit_set on a plain i32 = %d\0A\00"
@.str.34 = private unnamed_addr constant [32 x i8] c"bit_set on a Wrapping<u8> = %u\0A\00"
