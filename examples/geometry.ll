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
  %t2 = alloca %Rect
  %t3 = alloca %Rect
  %t53 = alloca %Rect
  %t54 = alloca %Rect
  %t60 = alloca %Rect
  %t61 = alloca %Rect
  %t117 = alloca %Aabb2
  %t118 = alloca %Aabb2
  %t148 = alloca %Aabb2
  %t149 = alloca %Aabb2
  %t182 = alloca %Aabb3
  %t183 = alloca %Aabb3
  %t223 = alloca %Aabb3
  %t224 = alloca %Aabb3
  %t267 = alloca %Ray
  %t268 = alloca %Ray
  %t278 = alloca <3 x float>
  %t307 = alloca %Plane
  %t308 = alloca %Plane
  %t335 = alloca [6 x %Plane]
  %t336 = alloca [6 x %Plane]
  %t339 = alloca i64
  %t345 = alloca %Frustum
  %t346 = alloca %Frustum
  %t571 = alloca %Transform
  %t572 = alloca %Transform
  %t587 = alloca <3 x float>
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t4 = getelementptr inbounds %Rect, %Rect* %t3, i32 0, i32 0
  store float 0x0000000000000000, float* %t4
  %t5 = getelementptr inbounds %Rect, %Rect* %t3, i32 0, i32 1
  store float 0x0000000000000000, float* %t5
  %t6 = getelementptr inbounds %Rect, %Rect* %t3, i32 0, i32 2
  store float 0x4024000000000000, float* %t6
  %t7 = getelementptr inbounds %Rect, %Rect* %t3, i32 0, i32 3
  store float 0x4024000000000000, float* %t7
  %t8 = load %Rect, %Rect* %t3
  store %Rect %t8, %Rect* %t2
  %t9 = load %Rect, %Rect* %t2
  %t10 = insertelement <2 x float> undef, float 0x4014000000000000, i32 0
  %t11 = insertelement <2 x float> %t10, float 0x4014000000000000, i32 1
  %t12 = extractvalue %Rect %t9, 0
  %t13 = extractvalue %Rect %t9, 1
  %t14 = extractvalue %Rect %t9, 2
  %t15 = extractvalue %Rect %t9, 3
  %t16 = extractelement <2 x float> %t11, i32 0
  %t17 = extractelement <2 x float> %t11, i32 1
  %t18 = fadd float %t12, %t14
  %t19 = fadd float %t13, %t15
  %t20 = fcmp oge float %t16, %t12
  %t21 = fcmp ole float %t16, %t18
  %t22 = fcmp oge float %t17, %t13
  %t23 = fcmp ole float %t17, %t19
  %t24 = and i1 %t20, %t21
  %t25 = and i1 %t24, %t22
  %t26 = and i1 %t25, %t23
  %t27 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.0, i64 0, i64 0
  %t28 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.1, i64 0, i64 0
  %t29 = select i1 %t26, i8* %t27, i8* %t28
  %t30 = getelementptr inbounds [32 x i8], [32 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t30, i8* %t29)
  %t31 = load %Rect, %Rect* %t2
  %t32 = insertelement <2 x float> undef, float 0x4049000000000000, i32 0
  %t33 = insertelement <2 x float> %t32, float 0x4014000000000000, i32 1
  %t34 = extractvalue %Rect %t31, 0
  %t35 = extractvalue %Rect %t31, 1
  %t36 = extractvalue %Rect %t31, 2
  %t37 = extractvalue %Rect %t31, 3
  %t38 = extractelement <2 x float> %t33, i32 0
  %t39 = extractelement <2 x float> %t33, i32 1
  %t40 = fadd float %t34, %t36
  %t41 = fadd float %t35, %t37
  %t42 = fcmp oge float %t38, %t34
  %t43 = fcmp ole float %t38, %t40
  %t44 = fcmp oge float %t39, %t35
  %t45 = fcmp ole float %t39, %t41
  %t46 = and i1 %t42, %t43
  %t47 = and i1 %t46, %t44
  %t48 = and i1 %t47, %t45
  %t49 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.3, i64 0, i64 0
  %t50 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.4, i64 0, i64 0
  %t51 = select i1 %t48, i8* %t49, i8* %t50
  %t52 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t52, i8* %t51)
  %t55 = getelementptr inbounds %Rect, %Rect* %t54, i32 0, i32 0
  store float 0x4014000000000000, float* %t55
  %t56 = getelementptr inbounds %Rect, %Rect* %t54, i32 0, i32 1
  store float 0x4014000000000000, float* %t56
  %t57 = getelementptr inbounds %Rect, %Rect* %t54, i32 0, i32 2
  store float 0x4024000000000000, float* %t57
  %t58 = getelementptr inbounds %Rect, %Rect* %t54, i32 0, i32 3
  store float 0x4024000000000000, float* %t58
  %t59 = load %Rect, %Rect* %t54
  store %Rect %t59, %Rect* %t53
  %t62 = getelementptr inbounds %Rect, %Rect* %t61, i32 0, i32 0
  store float 0x4059000000000000, float* %t62
  %t63 = getelementptr inbounds %Rect, %Rect* %t61, i32 0, i32 1
  store float 0x4059000000000000, float* %t63
  %t64 = getelementptr inbounds %Rect, %Rect* %t61, i32 0, i32 2
  store float 0x4024000000000000, float* %t64
  %t65 = getelementptr inbounds %Rect, %Rect* %t61, i32 0, i32 3
  store float 0x4024000000000000, float* %t65
  %t66 = load %Rect, %Rect* %t61
  store %Rect %t66, %Rect* %t60
  %t67 = load %Rect, %Rect* %t2
  %t68 = load %Rect, %Rect* %t53
  %t69 = extractvalue %Rect %t67, 0
  %t70 = extractvalue %Rect %t67, 1
  %t71 = extractvalue %Rect %t67, 2
  %t72 = extractvalue %Rect %t67, 3
  %t73 = extractvalue %Rect %t68, 0
  %t74 = extractvalue %Rect %t68, 1
  %t75 = extractvalue %Rect %t68, 2
  %t76 = extractvalue %Rect %t68, 3
  %t77 = fadd float %t69, %t71
  %t78 = fadd float %t70, %t72
  %t79 = fadd float %t73, %t75
  %t80 = fadd float %t74, %t76
  %t81 = fcmp ole float %t69, %t79
  %t82 = fcmp ole float %t73, %t77
  %t83 = fcmp ole float %t70, %t80
  %t84 = fcmp ole float %t74, %t78
  %t85 = and i1 %t81, %t82
  %t86 = and i1 %t85, %t83
  %t87 = and i1 %t86, %t84
  %t88 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.6, i64 0, i64 0
  %t89 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.7, i64 0, i64 0
  %t90 = select i1 %t87, i8* %t88, i8* %t89
  %t91 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t91, i8* %t90)
  %t92 = load %Rect, %Rect* %t2
  %t93 = load %Rect, %Rect* %t60
  %t94 = extractvalue %Rect %t92, 0
  %t95 = extractvalue %Rect %t92, 1
  %t96 = extractvalue %Rect %t92, 2
  %t97 = extractvalue %Rect %t92, 3
  %t98 = extractvalue %Rect %t93, 0
  %t99 = extractvalue %Rect %t93, 1
  %t100 = extractvalue %Rect %t93, 2
  %t101 = extractvalue %Rect %t93, 3
  %t102 = fadd float %t94, %t96
  %t103 = fadd float %t95, %t97
  %t104 = fadd float %t98, %t100
  %t105 = fadd float %t99, %t101
  %t106 = fcmp ole float %t94, %t104
  %t107 = fcmp ole float %t98, %t102
  %t108 = fcmp ole float %t95, %t105
  %t109 = fcmp ole float %t99, %t103
  %t110 = and i1 %t106, %t107
  %t111 = and i1 %t110, %t108
  %t112 = and i1 %t111, %t109
  %t113 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.9, i64 0, i64 0
  %t114 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.10, i64 0, i64 0
  %t115 = select i1 %t112, i8* %t113, i8* %t114
  %t116 = getelementptr inbounds [30 x i8], [30 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t116, i8* %t115)
  %t119 = insertelement <2 x float> undef, float 0x0000000000000000, i32 0
  %t120 = insertelement <2 x float> %t119, float 0x0000000000000000, i32 1
  %t121 = getelementptr inbounds %Aabb2, %Aabb2* %t118, i32 0, i32 0
  store <2 x float> %t120, <2 x float>* %t121
  %t122 = insertelement <2 x float> undef, float 0x4024000000000000, i32 0
  %t123 = insertelement <2 x float> %t122, float 0x4024000000000000, i32 1
  %t124 = getelementptr inbounds %Aabb2, %Aabb2* %t118, i32 0, i32 1
  store <2 x float> %t123, <2 x float>* %t124
  %t125 = load %Aabb2, %Aabb2* %t118
  store %Aabb2 %t125, %Aabb2* %t117
  %t126 = load %Aabb2, %Aabb2* %t117
  %t127 = insertelement <2 x float> undef, float 0x3FF0000000000000, i32 0
  %t128 = insertelement <2 x float> %t127, float 0x3FF0000000000000, i32 1
  %t129 = extractvalue %Aabb2 %t126, 0
  %t130 = extractvalue %Aabb2 %t126, 1
  %t131 = extractelement <2 x float> %t129, i32 0
  %t132 = extractelement <2 x float> %t129, i32 1
  %t133 = extractelement <2 x float> %t130, i32 0
  %t134 = extractelement <2 x float> %t130, i32 1
  %t135 = extractelement <2 x float> %t128, i32 0
  %t136 = extractelement <2 x float> %t128, i32 1
  %t137 = fcmp oge float %t135, %t131
  %t138 = fcmp ole float %t135, %t133
  %t139 = fcmp oge float %t136, %t132
  %t140 = fcmp ole float %t136, %t134
  %t141 = and i1 %t137, %t138
  %t142 = and i1 %t141, %t139
  %t143 = and i1 %t142, %t140
  %t144 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.12, i64 0, i64 0
  %t145 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.13, i64 0, i64 0
  %t146 = select i1 %t143, i8* %t144, i8* %t145
  %t147 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t147, i8* %t146)
  %t150 = insertelement <2 x float> undef, float 0x4014000000000000, i32 0
  %t151 = insertelement <2 x float> %t150, float 0x4014000000000000, i32 1
  %t152 = getelementptr inbounds %Aabb2, %Aabb2* %t149, i32 0, i32 0
  store <2 x float> %t151, <2 x float>* %t152
  %t153 = insertelement <2 x float> undef, float 0x402E000000000000, i32 0
  %t154 = insertelement <2 x float> %t153, float 0x402E000000000000, i32 1
  %t155 = getelementptr inbounds %Aabb2, %Aabb2* %t149, i32 0, i32 1
  store <2 x float> %t154, <2 x float>* %t155
  %t156 = load %Aabb2, %Aabb2* %t149
  store %Aabb2 %t156, %Aabb2* %t148
  %t157 = load %Aabb2, %Aabb2* %t117
  %t158 = load %Aabb2, %Aabb2* %t148
  %t159 = extractvalue %Aabb2 %t157, 0
  %t160 = extractvalue %Aabb2 %t157, 1
  %t161 = extractvalue %Aabb2 %t158, 0
  %t162 = extractvalue %Aabb2 %t158, 1
  %t163 = extractelement <2 x float> %t159, i32 0
  %t164 = extractelement <2 x float> %t159, i32 1
  %t165 = extractelement <2 x float> %t160, i32 0
  %t166 = extractelement <2 x float> %t160, i32 1
  %t167 = extractelement <2 x float> %t161, i32 0
  %t168 = extractelement <2 x float> %t161, i32 1
  %t169 = extractelement <2 x float> %t162, i32 0
  %t170 = extractelement <2 x float> %t162, i32 1
  %t171 = fcmp ole float %t163, %t169
  %t172 = fcmp ole float %t167, %t165
  %t173 = fcmp ole float %t164, %t170
  %t174 = fcmp ole float %t168, %t166
  %t175 = and i1 %t171, %t172
  %t176 = and i1 %t175, %t173
  %t177 = and i1 %t176, %t174
  %t178 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.15, i64 0, i64 0
  %t179 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.16, i64 0, i64 0
  %t180 = select i1 %t177, i8* %t178, i8* %t179
  %t181 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t181, i8* %t180)
  %t184 = insertelement <3 x float> undef, float 0x0000000000000000, i32 0
  %t185 = insertelement <3 x float> %t184, float 0x0000000000000000, i32 1
  %t186 = insertelement <3 x float> %t185, float 0x0000000000000000, i32 2
  %t187 = getelementptr inbounds %Aabb3, %Aabb3* %t183, i32 0, i32 0
  store <3 x float> %t186, <3 x float>* %t187
  %t188 = insertelement <3 x float> undef, float 0x4024000000000000, i32 0
  %t189 = insertelement <3 x float> %t188, float 0x4024000000000000, i32 1
  %t190 = insertelement <3 x float> %t189, float 0x4024000000000000, i32 2
  %t191 = getelementptr inbounds %Aabb3, %Aabb3* %t183, i32 0, i32 1
  store <3 x float> %t190, <3 x float>* %t191
  %t192 = load %Aabb3, %Aabb3* %t183
  store %Aabb3 %t192, %Aabb3* %t182
  %t193 = load %Aabb3, %Aabb3* %t182
  %t194 = insertelement <3 x float> undef, float 0x3FF0000000000000, i32 0
  %t195 = insertelement <3 x float> %t194, float 0x3FF0000000000000, i32 1
  %t196 = insertelement <3 x float> %t195, float 0x3FF0000000000000, i32 2
  %t197 = extractvalue %Aabb3 %t193, 0
  %t198 = extractvalue %Aabb3 %t193, 1
  %t199 = extractelement <3 x float> %t197, i32 0
  %t200 = extractelement <3 x float> %t198, i32 0
  %t201 = extractelement <3 x float> %t196, i32 0
  %t202 = fcmp oge float %t201, %t199
  %t203 = fcmp ole float %t201, %t200
  %t204 = and i1 %t202, %t203
  %t205 = extractelement <3 x float> %t197, i32 1
  %t206 = extractelement <3 x float> %t198, i32 1
  %t207 = extractelement <3 x float> %t196, i32 1
  %t208 = fcmp oge float %t207, %t205
  %t209 = fcmp ole float %t207, %t206
  %t210 = and i1 %t208, %t209
  %t211 = and i1 %t204, %t210
  %t212 = extractelement <3 x float> %t197, i32 2
  %t213 = extractelement <3 x float> %t198, i32 2
  %t214 = extractelement <3 x float> %t196, i32 2
  %t215 = fcmp oge float %t214, %t212
  %t216 = fcmp ole float %t214, %t213
  %t217 = and i1 %t215, %t216
  %t218 = and i1 %t211, %t217
  %t219 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.18, i64 0, i64 0
  %t220 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.19, i64 0, i64 0
  %t221 = select i1 %t218, i8* %t219, i8* %t220
  %t222 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.20, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t222, i8* %t221)
  %t225 = insertelement <3 x float> undef, float 0x4034000000000000, i32 0
  %t226 = insertelement <3 x float> %t225, float 0x4034000000000000, i32 1
  %t227 = insertelement <3 x float> %t226, float 0x4034000000000000, i32 2
  %t228 = getelementptr inbounds %Aabb3, %Aabb3* %t224, i32 0, i32 0
  store <3 x float> %t227, <3 x float>* %t228
  %t229 = insertelement <3 x float> undef, float 0x403E000000000000, i32 0
  %t230 = insertelement <3 x float> %t229, float 0x403E000000000000, i32 1
  %t231 = insertelement <3 x float> %t230, float 0x403E000000000000, i32 2
  %t232 = getelementptr inbounds %Aabb3, %Aabb3* %t224, i32 0, i32 1
  store <3 x float> %t231, <3 x float>* %t232
  %t233 = load %Aabb3, %Aabb3* %t224
  store %Aabb3 %t233, %Aabb3* %t223
  %t234 = load %Aabb3, %Aabb3* %t182
  %t235 = load %Aabb3, %Aabb3* %t223
  %t236 = extractvalue %Aabb3 %t234, 0
  %t237 = extractvalue %Aabb3 %t234, 1
  %t238 = extractvalue %Aabb3 %t235, 0
  %t239 = extractvalue %Aabb3 %t235, 1
  %t240 = extractelement <3 x float> %t236, i32 0
  %t241 = extractelement <3 x float> %t237, i32 0
  %t242 = extractelement <3 x float> %t238, i32 0
  %t243 = extractelement <3 x float> %t239, i32 0
  %t244 = fcmp ole float %t240, %t243
  %t245 = fcmp ole float %t242, %t241
  %t246 = and i1 %t244, %t245
  %t247 = extractelement <3 x float> %t236, i32 1
  %t248 = extractelement <3 x float> %t237, i32 1
  %t249 = extractelement <3 x float> %t238, i32 1
  %t250 = extractelement <3 x float> %t239, i32 1
  %t251 = fcmp ole float %t247, %t250
  %t252 = fcmp ole float %t249, %t248
  %t253 = and i1 %t251, %t252
  %t254 = and i1 %t246, %t253
  %t255 = extractelement <3 x float> %t236, i32 2
  %t256 = extractelement <3 x float> %t237, i32 2
  %t257 = extractelement <3 x float> %t238, i32 2
  %t258 = extractelement <3 x float> %t239, i32 2
  %t259 = fcmp ole float %t255, %t258
  %t260 = fcmp ole float %t257, %t256
  %t261 = and i1 %t259, %t260
  %t262 = and i1 %t254, %t261
  %t263 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.21, i64 0, i64 0
  %t264 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.22, i64 0, i64 0
  %t265 = select i1 %t262, i8* %t263, i8* %t264
  %t266 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.23, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t266, i8* %t265)
  %t269 = insertelement <3 x float> undef, float 0x0000000000000000, i32 0
  %t270 = insertelement <3 x float> %t269, float 0x0000000000000000, i32 1
  %t271 = insertelement <3 x float> %t270, float 0x0000000000000000, i32 2
  %t272 = getelementptr inbounds %Ray, %Ray* %t268, i32 0, i32 0
  store <3 x float> %t271, <3 x float>* %t272
  %t273 = insertelement <3 x float> undef, float 0x3FF0000000000000, i32 0
  %t274 = insertelement <3 x float> %t273, float 0x0000000000000000, i32 1
  %t275 = insertelement <3 x float> %t274, float 0x0000000000000000, i32 2
  %t276 = getelementptr inbounds %Ray, %Ray* %t268, i32 0, i32 1
  store <3 x float> %t275, <3 x float>* %t276
  %t277 = load %Ray, %Ray* %t268
  store %Ray %t277, %Ray* %t267
  %t279 = load %Ray, %Ray* %t267
  %t280 = extractvalue %Ray %t279, 0
  %t281 = extractvalue %Ray %t279, 1
  %t282 = extractelement <3 x float> %t280, i32 0
  %t283 = extractelement <3 x float> %t281, i32 0
  %t284 = fmul float %t283, 0x4014000000000000
  %t285 = fadd float %t282, %t284
  %t286 = insertelement <3 x float> undef, float %t285, i32 0
  %t287 = extractelement <3 x float> %t280, i32 1
  %t288 = extractelement <3 x float> %t281, i32 1
  %t289 = fmul float %t288, 0x4014000000000000
  %t290 = fadd float %t287, %t289
  %t291 = insertelement <3 x float> %t286, float %t290, i32 1
  %t292 = extractelement <3 x float> %t280, i32 2
  %t293 = extractelement <3 x float> %t281, i32 2
  %t294 = fmul float %t293, 0x4014000000000000
  %t295 = fadd float %t292, %t294
  %t296 = insertelement <3 x float> %t291, float %t295, i32 2
  store <3 x float> %t296, <3 x float>* %t278
  %t297 = load <3 x float>, <3 x float>* %t278
  %t298 = extractelement <3 x float> %t297, i32 0
  %t299 = load <3 x float>, <3 x float>* %t278
  %t300 = extractelement <3 x float> %t299, i32 1
  %t301 = load <3 x float>, <3 x float>* %t278
  %t302 = extractelement <3 x float> %t301, i32 2
  %t303 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.24, i64 0, i64 0
  %t304 = fpext float %t298 to double
  %t305 = fpext float %t300 to double
  %t306 = fpext float %t302 to double
  call i32 (i8*, ...) @printf(i8* %t303, double %t304, double %t305, double %t306)
  %t309 = insertelement <3 x float> undef, float 0x0000000000000000, i32 0
  %t310 = insertelement <3 x float> %t309, float 0x3FF0000000000000, i32 1
  %t311 = insertelement <3 x float> %t310, float 0x0000000000000000, i32 2
  %t312 = getelementptr inbounds %Plane, %Plane* %t308, i32 0, i32 0
  store <3 x float> %t311, <3 x float>* %t312
  %t313 = getelementptr inbounds %Plane, %Plane* %t308, i32 0, i32 1
  store float 0x0000000000000000, float* %t313
  %t314 = load %Plane, %Plane* %t308
  store %Plane %t314, %Plane* %t307
  %t315 = load %Plane, %Plane* %t307
  %t316 = insertelement <3 x float> undef, float 0x0000000000000000, i32 0
  %t317 = insertelement <3 x float> %t316, float 0x4008000000000000, i32 1
  %t318 = insertelement <3 x float> %t317, float 0x0000000000000000, i32 2
  %t319 = extractvalue %Plane %t315, 0
  %t320 = extractvalue %Plane %t315, 1
  %t321 = extractelement <3 x float> %t319, i32 0
  %t322 = extractelement <3 x float> %t318, i32 0
  %t323 = fmul float %t321, %t322
  %t324 = extractelement <3 x float> %t319, i32 1
  %t325 = extractelement <3 x float> %t318, i32 1
  %t326 = fmul float %t324, %t325
  %t327 = fadd float %t323, %t326
  %t328 = extractelement <3 x float> %t319, i32 2
  %t329 = extractelement <3 x float> %t318, i32 2
  %t330 = fmul float %t328, %t329
  %t331 = fadd float %t327, %t330
  %t332 = fsub float %t331, %t320
  %t333 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.25, i64 0, i64 0
  %t334 = fpext float %t332 to double
  call i32 (i8*, ...) @printf(i8* %t333, double %t334)
  %t337 = load %Plane, %Plane* %t307
  %t338 = getelementptr inbounds [6 x %Plane], [6 x %Plane]* %t336, i32 0, i64 0
  store %Plane %t337, %Plane* %t338
  store i64 1, i64* %t339
  br label %arr_rep_cond_0
arr_rep_cond_0:
  %t340 = load i64, i64* %t339
  %t341 = icmp ult i64 %t340, 6
  br i1 %t341, label %arr_rep_body_1, label %arr_rep_end_2
arr_rep_body_1:
  %t342 = getelementptr inbounds [6 x %Plane], [6 x %Plane]* %t336, i32 0, i64 %t340
  store %Plane %t337, %Plane* %t342
  %t343 = add i64 %t340, 1
  store i64 %t343, i64* %t339
  br label %arr_rep_cond_0
arr_rep_end_2:
  %t344 = load [6 x %Plane], [6 x %Plane]* %t336
  store [6 x %Plane] %t344, [6 x %Plane]* %t335
  %t347 = load [6 x %Plane], [6 x %Plane]* %t335
  %t348 = getelementptr inbounds %Frustum, %Frustum* %t346, i32 0, i32 0
  store [6 x %Plane] %t347, [6 x %Plane]* %t348
  %t349 = load %Frustum, %Frustum* %t346
  store %Frustum %t349, %Frustum* %t345
  %t350 = load %Frustum, %Frustum* %t345
  %t351 = insertelement <3 x float> undef, float 0x0000000000000000, i32 0
  %t352 = insertelement <3 x float> %t351, float 0x3FF0000000000000, i32 1
  %t353 = insertelement <3 x float> %t352, float 0x0000000000000000, i32 2
  %t354 = extractvalue %Frustum %t350, 0
  %t355 = extractvalue [6 x %Plane] %t354, 0
  %t356 = extractvalue %Plane %t355, 0
  %t357 = extractvalue %Plane %t355, 1
  %t358 = extractelement <3 x float> %t356, i32 0
  %t359 = extractelement <3 x float> %t353, i32 0
  %t360 = fmul float %t358, %t359
  %t361 = extractelement <3 x float> %t356, i32 1
  %t362 = extractelement <3 x float> %t353, i32 1
  %t363 = fmul float %t361, %t362
  %t364 = fadd float %t360, %t363
  %t365 = extractelement <3 x float> %t356, i32 2
  %t366 = extractelement <3 x float> %t353, i32 2
  %t367 = fmul float %t365, %t366
  %t368 = fadd float %t364, %t367
  %t369 = fsub float %t368, %t357
  %t370 = fcmp oge float %t369, 0x0000000000000000
  %t371 = extractvalue [6 x %Plane] %t354, 1
  %t372 = extractvalue %Plane %t371, 0
  %t373 = extractvalue %Plane %t371, 1
  %t374 = extractelement <3 x float> %t372, i32 0
  %t375 = extractelement <3 x float> %t353, i32 0
  %t376 = fmul float %t374, %t375
  %t377 = extractelement <3 x float> %t372, i32 1
  %t378 = extractelement <3 x float> %t353, i32 1
  %t379 = fmul float %t377, %t378
  %t380 = fadd float %t376, %t379
  %t381 = extractelement <3 x float> %t372, i32 2
  %t382 = extractelement <3 x float> %t353, i32 2
  %t383 = fmul float %t381, %t382
  %t384 = fadd float %t380, %t383
  %t385 = fsub float %t384, %t373
  %t386 = fcmp oge float %t385, 0x0000000000000000
  %t387 = and i1 %t370, %t386
  %t388 = extractvalue [6 x %Plane] %t354, 2
  %t389 = extractvalue %Plane %t388, 0
  %t390 = extractvalue %Plane %t388, 1
  %t391 = extractelement <3 x float> %t389, i32 0
  %t392 = extractelement <3 x float> %t353, i32 0
  %t393 = fmul float %t391, %t392
  %t394 = extractelement <3 x float> %t389, i32 1
  %t395 = extractelement <3 x float> %t353, i32 1
  %t396 = fmul float %t394, %t395
  %t397 = fadd float %t393, %t396
  %t398 = extractelement <3 x float> %t389, i32 2
  %t399 = extractelement <3 x float> %t353, i32 2
  %t400 = fmul float %t398, %t399
  %t401 = fadd float %t397, %t400
  %t402 = fsub float %t401, %t390
  %t403 = fcmp oge float %t402, 0x0000000000000000
  %t404 = and i1 %t387, %t403
  %t405 = extractvalue [6 x %Plane] %t354, 3
  %t406 = extractvalue %Plane %t405, 0
  %t407 = extractvalue %Plane %t405, 1
  %t408 = extractelement <3 x float> %t406, i32 0
  %t409 = extractelement <3 x float> %t353, i32 0
  %t410 = fmul float %t408, %t409
  %t411 = extractelement <3 x float> %t406, i32 1
  %t412 = extractelement <3 x float> %t353, i32 1
  %t413 = fmul float %t411, %t412
  %t414 = fadd float %t410, %t413
  %t415 = extractelement <3 x float> %t406, i32 2
  %t416 = extractelement <3 x float> %t353, i32 2
  %t417 = fmul float %t415, %t416
  %t418 = fadd float %t414, %t417
  %t419 = fsub float %t418, %t407
  %t420 = fcmp oge float %t419, 0x0000000000000000
  %t421 = and i1 %t404, %t420
  %t422 = extractvalue [6 x %Plane] %t354, 4
  %t423 = extractvalue %Plane %t422, 0
  %t424 = extractvalue %Plane %t422, 1
  %t425 = extractelement <3 x float> %t423, i32 0
  %t426 = extractelement <3 x float> %t353, i32 0
  %t427 = fmul float %t425, %t426
  %t428 = extractelement <3 x float> %t423, i32 1
  %t429 = extractelement <3 x float> %t353, i32 1
  %t430 = fmul float %t428, %t429
  %t431 = fadd float %t427, %t430
  %t432 = extractelement <3 x float> %t423, i32 2
  %t433 = extractelement <3 x float> %t353, i32 2
  %t434 = fmul float %t432, %t433
  %t435 = fadd float %t431, %t434
  %t436 = fsub float %t435, %t424
  %t437 = fcmp oge float %t436, 0x0000000000000000
  %t438 = and i1 %t421, %t437
  %t439 = extractvalue [6 x %Plane] %t354, 5
  %t440 = extractvalue %Plane %t439, 0
  %t441 = extractvalue %Plane %t439, 1
  %t442 = extractelement <3 x float> %t440, i32 0
  %t443 = extractelement <3 x float> %t353, i32 0
  %t444 = fmul float %t442, %t443
  %t445 = extractelement <3 x float> %t440, i32 1
  %t446 = extractelement <3 x float> %t353, i32 1
  %t447 = fmul float %t445, %t446
  %t448 = fadd float %t444, %t447
  %t449 = extractelement <3 x float> %t440, i32 2
  %t450 = extractelement <3 x float> %t353, i32 2
  %t451 = fmul float %t449, %t450
  %t452 = fadd float %t448, %t451
  %t453 = fsub float %t452, %t441
  %t454 = fcmp oge float %t453, 0x0000000000000000
  %t455 = and i1 %t438, %t454
  %t456 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.26, i64 0, i64 0
  %t457 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.27, i64 0, i64 0
  %t458 = select i1 %t455, i8* %t456, i8* %t457
  %t459 = getelementptr inbounds [35 x i8], [35 x i8]* @.str.28, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t459, i8* %t458)
  %t460 = load %Frustum, %Frustum* %t345
  %t461 = insertelement <3 x float> undef, float 0x0000000000000000, i32 0
  %t462 = fsub float 0.0, 0x3FF0000000000000
  %t463 = insertelement <3 x float> %t461, float %t462, i32 1
  %t464 = insertelement <3 x float> %t463, float 0x0000000000000000, i32 2
  %t465 = extractvalue %Frustum %t460, 0
  %t466 = extractvalue [6 x %Plane] %t465, 0
  %t467 = extractvalue %Plane %t466, 0
  %t468 = extractvalue %Plane %t466, 1
  %t469 = extractelement <3 x float> %t467, i32 0
  %t470 = extractelement <3 x float> %t464, i32 0
  %t471 = fmul float %t469, %t470
  %t472 = extractelement <3 x float> %t467, i32 1
  %t473 = extractelement <3 x float> %t464, i32 1
  %t474 = fmul float %t472, %t473
  %t475 = fadd float %t471, %t474
  %t476 = extractelement <3 x float> %t467, i32 2
  %t477 = extractelement <3 x float> %t464, i32 2
  %t478 = fmul float %t476, %t477
  %t479 = fadd float %t475, %t478
  %t480 = fsub float %t479, %t468
  %t481 = fcmp oge float %t480, 0x0000000000000000
  %t482 = extractvalue [6 x %Plane] %t465, 1
  %t483 = extractvalue %Plane %t482, 0
  %t484 = extractvalue %Plane %t482, 1
  %t485 = extractelement <3 x float> %t483, i32 0
  %t486 = extractelement <3 x float> %t464, i32 0
  %t487 = fmul float %t485, %t486
  %t488 = extractelement <3 x float> %t483, i32 1
  %t489 = extractelement <3 x float> %t464, i32 1
  %t490 = fmul float %t488, %t489
  %t491 = fadd float %t487, %t490
  %t492 = extractelement <3 x float> %t483, i32 2
  %t493 = extractelement <3 x float> %t464, i32 2
  %t494 = fmul float %t492, %t493
  %t495 = fadd float %t491, %t494
  %t496 = fsub float %t495, %t484
  %t497 = fcmp oge float %t496, 0x0000000000000000
  %t498 = and i1 %t481, %t497
  %t499 = extractvalue [6 x %Plane] %t465, 2
  %t500 = extractvalue %Plane %t499, 0
  %t501 = extractvalue %Plane %t499, 1
  %t502 = extractelement <3 x float> %t500, i32 0
  %t503 = extractelement <3 x float> %t464, i32 0
  %t504 = fmul float %t502, %t503
  %t505 = extractelement <3 x float> %t500, i32 1
  %t506 = extractelement <3 x float> %t464, i32 1
  %t507 = fmul float %t505, %t506
  %t508 = fadd float %t504, %t507
  %t509 = extractelement <3 x float> %t500, i32 2
  %t510 = extractelement <3 x float> %t464, i32 2
  %t511 = fmul float %t509, %t510
  %t512 = fadd float %t508, %t511
  %t513 = fsub float %t512, %t501
  %t514 = fcmp oge float %t513, 0x0000000000000000
  %t515 = and i1 %t498, %t514
  %t516 = extractvalue [6 x %Plane] %t465, 3
  %t517 = extractvalue %Plane %t516, 0
  %t518 = extractvalue %Plane %t516, 1
  %t519 = extractelement <3 x float> %t517, i32 0
  %t520 = extractelement <3 x float> %t464, i32 0
  %t521 = fmul float %t519, %t520
  %t522 = extractelement <3 x float> %t517, i32 1
  %t523 = extractelement <3 x float> %t464, i32 1
  %t524 = fmul float %t522, %t523
  %t525 = fadd float %t521, %t524
  %t526 = extractelement <3 x float> %t517, i32 2
  %t527 = extractelement <3 x float> %t464, i32 2
  %t528 = fmul float %t526, %t527
  %t529 = fadd float %t525, %t528
  %t530 = fsub float %t529, %t518
  %t531 = fcmp oge float %t530, 0x0000000000000000
  %t532 = and i1 %t515, %t531
  %t533 = extractvalue [6 x %Plane] %t465, 4
  %t534 = extractvalue %Plane %t533, 0
  %t535 = extractvalue %Plane %t533, 1
  %t536 = extractelement <3 x float> %t534, i32 0
  %t537 = extractelement <3 x float> %t464, i32 0
  %t538 = fmul float %t536, %t537
  %t539 = extractelement <3 x float> %t534, i32 1
  %t540 = extractelement <3 x float> %t464, i32 1
  %t541 = fmul float %t539, %t540
  %t542 = fadd float %t538, %t541
  %t543 = extractelement <3 x float> %t534, i32 2
  %t544 = extractelement <3 x float> %t464, i32 2
  %t545 = fmul float %t543, %t544
  %t546 = fadd float %t542, %t545
  %t547 = fsub float %t546, %t535
  %t548 = fcmp oge float %t547, 0x0000000000000000
  %t549 = and i1 %t532, %t548
  %t550 = extractvalue [6 x %Plane] %t465, 5
  %t551 = extractvalue %Plane %t550, 0
  %t552 = extractvalue %Plane %t550, 1
  %t553 = extractelement <3 x float> %t551, i32 0
  %t554 = extractelement <3 x float> %t464, i32 0
  %t555 = fmul float %t553, %t554
  %t556 = extractelement <3 x float> %t551, i32 1
  %t557 = extractelement <3 x float> %t464, i32 1
  %t558 = fmul float %t556, %t557
  %t559 = fadd float %t555, %t558
  %t560 = extractelement <3 x float> %t551, i32 2
  %t561 = extractelement <3 x float> %t464, i32 2
  %t562 = fmul float %t560, %t561
  %t563 = fadd float %t559, %t562
  %t564 = fsub float %t563, %t552
  %t565 = fcmp oge float %t564, 0x0000000000000000
  %t566 = and i1 %t549, %t565
  %t567 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.29, i64 0, i64 0
  %t568 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.30, i64 0, i64 0
  %t569 = select i1 %t566, i8* %t567, i8* %t568
  %t570 = getelementptr inbounds [35 x i8], [35 x i8]* @.str.31, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t570, i8* %t569)
  %t573 = insertelement <3 x float> undef, float 0x3FF0000000000000, i32 0
  %t574 = insertelement <3 x float> %t573, float 0x0000000000000000, i32 1
  %t575 = insertelement <3 x float> %t574, float 0x0000000000000000, i32 2
  %t576 = getelementptr inbounds %Transform, %Transform* %t572, i32 0, i32 0
  store <3 x float> %t575, <3 x float>* %t576
  %t577 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t578 = insertelement <4 x float> %t577, float 0x0000000000000000, i32 1
  %t579 = insertelement <4 x float> %t578, float 0x0000000000000000, i32 2
  %t580 = insertelement <4 x float> %t579, float 0x3FF0000000000000, i32 3
  %t581 = getelementptr inbounds %Transform, %Transform* %t572, i32 0, i32 1
  store <4 x float> %t580, <4 x float>* %t581
  %t582 = insertelement <3 x float> undef, float 0x4000000000000000, i32 0
  %t583 = insertelement <3 x float> %t582, float 0x4000000000000000, i32 1
  %t584 = insertelement <3 x float> %t583, float 0x4000000000000000, i32 2
  %t585 = getelementptr inbounds %Transform, %Transform* %t572, i32 0, i32 2
  store <3 x float> %t584, <3 x float>* %t585
  %t586 = load %Transform, %Transform* %t572
  store %Transform %t586, %Transform* %t571
  %t588 = load %Transform, %Transform* %t571
  %t589 = insertelement <3 x float> undef, float 0x3FF0000000000000, i32 0
  %t590 = insertelement <3 x float> %t589, float 0x0000000000000000, i32 1
  %t591 = insertelement <3 x float> %t590, float 0x0000000000000000, i32 2
  %t592 = extractvalue %Transform %t588, 0
  %t593 = extractvalue %Transform %t588, 1
  %t594 = extractvalue %Transform %t588, 2
  %t595 = extractelement <3 x float> %t591, i32 0
  %t596 = extractelement <3 x float> %t594, i32 0
  %t597 = fmul float %t595, %t596
  %t598 = insertelement <3 x float> undef, float %t597, i32 0
  %t599 = extractelement <3 x float> %t591, i32 1
  %t600 = extractelement <3 x float> %t594, i32 1
  %t601 = fmul float %t599, %t600
  %t602 = insertelement <3 x float> %t598, float %t601, i32 1
  %t603 = extractelement <3 x float> %t591, i32 2
  %t604 = extractelement <3 x float> %t594, i32 2
  %t605 = fmul float %t603, %t604
  %t606 = insertelement <3 x float> %t602, float %t605, i32 2
  %t607 = extractelement <3 x float> %t606, i32 0
  %t608 = extractelement <3 x float> %t606, i32 1
  %t609 = extractelement <3 x float> %t606, i32 2
  %t610 = insertelement <4 x float> undef, float %t607, i32 0
  %t611 = insertelement <4 x float> %t610, float %t608, i32 1
  %t612 = insertelement <4 x float> %t611, float %t609, i32 2
  %t613 = insertelement <4 x float> %t612, float 0x0000000000000000, i32 3
  %t614 = extractelement <4 x float> %t593, i32 0
  %t615 = extractelement <4 x float> %t593, i32 1
  %t616 = extractelement <4 x float> %t593, i32 2
  %t617 = extractelement <4 x float> %t593, i32 3
  %t618 = fsub float 0x0000000000000000, %t614
  %t619 = fsub float 0x0000000000000000, %t615
  %t620 = fsub float 0x0000000000000000, %t616
  %t621 = insertelement <4 x float> undef, float %t618, i32 0
  %t622 = insertelement <4 x float> %t621, float %t619, i32 1
  %t623 = insertelement <4 x float> %t622, float %t620, i32 2
  %t624 = insertelement <4 x float> %t623, float %t617, i32 3
  %t625 = extractelement <4 x float> %t593, i32 0
  %t626 = extractelement <4 x float> %t593, i32 1
  %t627 = extractelement <4 x float> %t593, i32 2
  %t628 = extractelement <4 x float> %t593, i32 3
  %t629 = extractelement <4 x float> %t613, i32 0
  %t630 = extractelement <4 x float> %t613, i32 1
  %t631 = extractelement <4 x float> %t613, i32 2
  %t632 = extractelement <4 x float> %t613, i32 3
  %t633 = fmul float %t628, %t632
  %t634 = fmul float %t625, %t629
  %t635 = fmul float %t626, %t630
  %t636 = fmul float %t627, %t631
  %t637 = fsub float %t633, %t634
  %t638 = fsub float %t637, %t635
  %t639 = fsub float %t638, %t636
  %t640 = fmul float %t628, %t629
  %t641 = fmul float %t625, %t632
  %t642 = fmul float %t626, %t631
  %t643 = fmul float %t627, %t630
  %t644 = fadd float %t640, %t641
  %t645 = fadd float %t644, %t642
  %t646 = fsub float %t645, %t643
  %t647 = fmul float %t628, %t630
  %t648 = fmul float %t625, %t631
  %t649 = fmul float %t626, %t632
  %t650 = fmul float %t627, %t629
  %t651 = fsub float %t647, %t648
  %t652 = fadd float %t651, %t649
  %t653 = fadd float %t652, %t650
  %t654 = fmul float %t628, %t631
  %t655 = fmul float %t625, %t630
  %t656 = fmul float %t626, %t629
  %t657 = fmul float %t627, %t632
  %t658 = fadd float %t654, %t655
  %t659 = fsub float %t658, %t656
  %t660 = fadd float %t659, %t657
  %t661 = insertelement <4 x float> undef, float %t646, i32 0
  %t662 = insertelement <4 x float> %t661, float %t653, i32 1
  %t663 = insertelement <4 x float> %t662, float %t660, i32 2
  %t664 = insertelement <4 x float> %t663, float %t639, i32 3
  %t665 = extractelement <4 x float> %t664, i32 0
  %t666 = extractelement <4 x float> %t664, i32 1
  %t667 = extractelement <4 x float> %t664, i32 2
  %t668 = extractelement <4 x float> %t664, i32 3
  %t669 = extractelement <4 x float> %t624, i32 0
  %t670 = extractelement <4 x float> %t624, i32 1
  %t671 = extractelement <4 x float> %t624, i32 2
  %t672 = extractelement <4 x float> %t624, i32 3
  %t673 = fmul float %t668, %t672
  %t674 = fmul float %t665, %t669
  %t675 = fmul float %t666, %t670
  %t676 = fmul float %t667, %t671
  %t677 = fsub float %t673, %t674
  %t678 = fsub float %t677, %t675
  %t679 = fsub float %t678, %t676
  %t680 = fmul float %t668, %t669
  %t681 = fmul float %t665, %t672
  %t682 = fmul float %t666, %t671
  %t683 = fmul float %t667, %t670
  %t684 = fadd float %t680, %t681
  %t685 = fadd float %t684, %t682
  %t686 = fsub float %t685, %t683
  %t687 = fmul float %t668, %t670
  %t688 = fmul float %t665, %t671
  %t689 = fmul float %t666, %t672
  %t690 = fmul float %t667, %t669
  %t691 = fsub float %t687, %t688
  %t692 = fadd float %t691, %t689
  %t693 = fadd float %t692, %t690
  %t694 = fmul float %t668, %t671
  %t695 = fmul float %t665, %t670
  %t696 = fmul float %t666, %t669
  %t697 = fmul float %t667, %t672
  %t698 = fadd float %t694, %t695
  %t699 = fsub float %t698, %t696
  %t700 = fadd float %t699, %t697
  %t701 = insertelement <4 x float> undef, float %t686, i32 0
  %t702 = insertelement <4 x float> %t701, float %t693, i32 1
  %t703 = insertelement <4 x float> %t702, float %t700, i32 2
  %t704 = insertelement <4 x float> %t703, float %t679, i32 3
  %t705 = extractelement <4 x float> %t704, i32 0
  %t706 = extractelement <4 x float> %t704, i32 1
  %t707 = extractelement <4 x float> %t704, i32 2
  %t708 = insertelement <3 x float> undef, float %t705, i32 0
  %t709 = insertelement <3 x float> %t708, float %t706, i32 1
  %t710 = insertelement <3 x float> %t709, float %t707, i32 2
  %t711 = extractelement <3 x float> %t592, i32 0
  %t712 = extractelement <3 x float> %t710, i32 0
  %t713 = fadd float %t711, %t712
  %t714 = insertelement <3 x float> undef, float %t713, i32 0
  %t715 = extractelement <3 x float> %t592, i32 1
  %t716 = extractelement <3 x float> %t710, i32 1
  %t717 = fadd float %t715, %t716
  %t718 = insertelement <3 x float> %t714, float %t717, i32 1
  %t719 = extractelement <3 x float> %t592, i32 2
  %t720 = extractelement <3 x float> %t710, i32 2
  %t721 = fadd float %t719, %t720
  %t722 = insertelement <3 x float> %t718, float %t721, i32 2
  store <3 x float> %t722, <3 x float>* %t587
  %t723 = load <3 x float>, <3 x float>* %t587
  %t724 = extractelement <3 x float> %t723, i32 0
  %t725 = load <3 x float>, <3 x float>* %t587
  %t726 = extractelement <3 x float> %t725, i32 1
  %t727 = load <3 x float>, <3 x float>* %t587
  %t728 = extractelement <3 x float> %t727, i32 2
  %t729 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.32, i64 0, i64 0
  %t730 = fpext float %t724 to double
  %t731 = fpext float %t726 to double
  %t732 = fpext float %t728 to double
  call i32 (i8*, ...) @printf(i8* %t729, double %t730, double %t731, double %t732)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.1 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.2 = private unnamed_addr constant [32 x i8] c"rect contains inside point: %s\0A\00"
@.str.3 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.4 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.5 = private unnamed_addr constant [33 x i8] c"rect contains outside point: %s\0A\00"
@.str.6 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.7 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.8 = private unnamed_addr constant [33 x i8] c"rect intersects overlapping: %s\0A\00"
@.str.9 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.10 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.11 = private unnamed_addr constant [30 x i8] c"rect intersects far away: %s\0A\00"
@.str.12 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.13 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.14 = private unnamed_addr constant [20 x i8] c"aabb2 contains: %s\0A\00"
@.str.15 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.16 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.17 = private unnamed_addr constant [22 x i8] c"aabb2 intersects: %s\0A\00"
@.str.18 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.19 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.20 = private unnamed_addr constant [20 x i8] c"aabb3 contains: %s\0A\00"
@.str.21 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.22 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.23 = private unnamed_addr constant [31 x i8] c"aabb3 intersects far away: %s\0A\00"
@.str.24 = private unnamed_addr constant [24 x i8] c"ray at t=5: %f, %f, %f\0A\00"
@.str.25 = private unnamed_addr constant [25 x i8] c"height above ground: %f\0A\00"
@.str.26 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.27 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.28 = private unnamed_addr constant [35 x i8] c"frustum contains above ground: %s\0A\00"
@.str.29 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.30 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.31 = private unnamed_addr constant [35 x i8] c"frustum excludes below ground: %s\0A\00"
@.str.32 = private unnamed_addr constant [31 x i8] c"transformed point: %f, %f, %f\0A\00"
