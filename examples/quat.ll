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
  %t2 = alloca <4 x float>
  %t7 = alloca <3 x float>
  %t126 = alloca <4 x float>
  %t131 = alloca <3 x float>
  %t250 = alloca <4 x float>
  %t255 = alloca <4 x float>
  %t298 = alloca <3 x float>
  %t417 = alloca <3 x float>
  %t545 = alloca <4 x float>
  %t582 = alloca <4 x float>
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t4 = insertelement <4 x float> %t3, float 0x0000000000000000, i32 1
  %t5 = insertelement <4 x float> %t4, float 0x0000000000000000, i32 2
  %t6 = insertelement <4 x float> %t5, float 0x3FF0000000000000, i32 3
  store <4 x float> %t6, <4 x float>* %t2
  %t8 = load <4 x float>, <4 x float>* %t2
  %t9 = insertelement <3 x float> undef, float 0x3FF0000000000000, i32 0
  %t10 = insertelement <3 x float> %t9, float 0x0000000000000000, i32 1
  %t11 = insertelement <3 x float> %t10, float 0x0000000000000000, i32 2
  %t12 = extractelement <3 x float> %t11, i32 0
  %t13 = extractelement <3 x float> %t11, i32 1
  %t14 = extractelement <3 x float> %t11, i32 2
  %t15 = insertelement <4 x float> undef, float %t12, i32 0
  %t16 = insertelement <4 x float> %t15, float %t13, i32 1
  %t17 = insertelement <4 x float> %t16, float %t14, i32 2
  %t18 = insertelement <4 x float> %t17, float 0x0000000000000000, i32 3
  %t19 = extractelement <4 x float> %t8, i32 0
  %t20 = extractelement <4 x float> %t8, i32 1
  %t21 = extractelement <4 x float> %t8, i32 2
  %t22 = extractelement <4 x float> %t8, i32 3
  %t23 = fsub float 0x0000000000000000, %t19
  %t24 = fsub float 0x0000000000000000, %t20
  %t25 = fsub float 0x0000000000000000, %t21
  %t26 = insertelement <4 x float> undef, float %t23, i32 0
  %t27 = insertelement <4 x float> %t26, float %t24, i32 1
  %t28 = insertelement <4 x float> %t27, float %t25, i32 2
  %t29 = insertelement <4 x float> %t28, float %t22, i32 3
  %t30 = extractelement <4 x float> %t8, i32 0
  %t31 = extractelement <4 x float> %t8, i32 1
  %t32 = extractelement <4 x float> %t8, i32 2
  %t33 = extractelement <4 x float> %t8, i32 3
  %t34 = extractelement <4 x float> %t18, i32 0
  %t35 = extractelement <4 x float> %t18, i32 1
  %t36 = extractelement <4 x float> %t18, i32 2
  %t37 = extractelement <4 x float> %t18, i32 3
  %t38 = fmul float %t33, %t37
  %t39 = fmul float %t30, %t34
  %t40 = fmul float %t31, %t35
  %t41 = fmul float %t32, %t36
  %t42 = fsub float %t38, %t39
  %t43 = fsub float %t42, %t40
  %t44 = fsub float %t43, %t41
  %t45 = fmul float %t33, %t34
  %t46 = fmul float %t30, %t37
  %t47 = fmul float %t31, %t36
  %t48 = fmul float %t32, %t35
  %t49 = fadd float %t45, %t46
  %t50 = fadd float %t49, %t47
  %t51 = fsub float %t50, %t48
  %t52 = fmul float %t33, %t35
  %t53 = fmul float %t30, %t36
  %t54 = fmul float %t31, %t37
  %t55 = fmul float %t32, %t34
  %t56 = fsub float %t52, %t53
  %t57 = fadd float %t56, %t54
  %t58 = fadd float %t57, %t55
  %t59 = fmul float %t33, %t36
  %t60 = fmul float %t30, %t35
  %t61 = fmul float %t31, %t34
  %t62 = fmul float %t32, %t37
  %t63 = fadd float %t59, %t60
  %t64 = fsub float %t63, %t61
  %t65 = fadd float %t64, %t62
  %t66 = insertelement <4 x float> undef, float %t51, i32 0
  %t67 = insertelement <4 x float> %t66, float %t58, i32 1
  %t68 = insertelement <4 x float> %t67, float %t65, i32 2
  %t69 = insertelement <4 x float> %t68, float %t44, i32 3
  %t70 = extractelement <4 x float> %t69, i32 0
  %t71 = extractelement <4 x float> %t69, i32 1
  %t72 = extractelement <4 x float> %t69, i32 2
  %t73 = extractelement <4 x float> %t69, i32 3
  %t74 = extractelement <4 x float> %t29, i32 0
  %t75 = extractelement <4 x float> %t29, i32 1
  %t76 = extractelement <4 x float> %t29, i32 2
  %t77 = extractelement <4 x float> %t29, i32 3
  %t78 = fmul float %t73, %t77
  %t79 = fmul float %t70, %t74
  %t80 = fmul float %t71, %t75
  %t81 = fmul float %t72, %t76
  %t82 = fsub float %t78, %t79
  %t83 = fsub float %t82, %t80
  %t84 = fsub float %t83, %t81
  %t85 = fmul float %t73, %t74
  %t86 = fmul float %t70, %t77
  %t87 = fmul float %t71, %t76
  %t88 = fmul float %t72, %t75
  %t89 = fadd float %t85, %t86
  %t90 = fadd float %t89, %t87
  %t91 = fsub float %t90, %t88
  %t92 = fmul float %t73, %t75
  %t93 = fmul float %t70, %t76
  %t94 = fmul float %t71, %t77
  %t95 = fmul float %t72, %t74
  %t96 = fsub float %t92, %t93
  %t97 = fadd float %t96, %t94
  %t98 = fadd float %t97, %t95
  %t99 = fmul float %t73, %t76
  %t100 = fmul float %t70, %t75
  %t101 = fmul float %t71, %t74
  %t102 = fmul float %t72, %t77
  %t103 = fadd float %t99, %t100
  %t104 = fsub float %t103, %t101
  %t105 = fadd float %t104, %t102
  %t106 = insertelement <4 x float> undef, float %t91, i32 0
  %t107 = insertelement <4 x float> %t106, float %t98, i32 1
  %t108 = insertelement <4 x float> %t107, float %t105, i32 2
  %t109 = insertelement <4 x float> %t108, float %t84, i32 3
  %t110 = extractelement <4 x float> %t109, i32 0
  %t111 = extractelement <4 x float> %t109, i32 1
  %t112 = extractelement <4 x float> %t109, i32 2
  %t113 = insertelement <3 x float> undef, float %t110, i32 0
  %t114 = insertelement <3 x float> %t113, float %t111, i32 1
  %t115 = insertelement <3 x float> %t114, float %t112, i32 2
  store <3 x float> %t115, <3 x float>* %t7
  %t116 = load <3 x float>, <3 x float>* %t7
  %t117 = extractelement <3 x float> %t116, i32 0
  %t118 = load <3 x float>, <3 x float>* %t7
  %t119 = extractelement <3 x float> %t118, i32 1
  %t120 = load <3 x float>, <3 x float>* %t7
  %t121 = extractelement <3 x float> %t120, i32 2
  %t122 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.0, i64 0, i64 0
  %t123 = fpext float %t117 to double
  %t124 = fpext float %t119 to double
  %t125 = fpext float %t121 to double
  call i32 (i8*, ...) @printf(i8* %t122, double %t123, double %t124, double %t125)
  %t127 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t128 = insertelement <4 x float> %t127, float 0x0000000000000000, i32 1
  %t129 = insertelement <4 x float> %t128, float 0x3FE6A09E60000000, i32 2
  %t130 = insertelement <4 x float> %t129, float 0x3FE6A09E60000000, i32 3
  store <4 x float> %t130, <4 x float>* %t126
  %t132 = load <4 x float>, <4 x float>* %t126
  %t133 = insertelement <3 x float> undef, float 0x3FF0000000000000, i32 0
  %t134 = insertelement <3 x float> %t133, float 0x0000000000000000, i32 1
  %t135 = insertelement <3 x float> %t134, float 0x0000000000000000, i32 2
  %t136 = extractelement <3 x float> %t135, i32 0
  %t137 = extractelement <3 x float> %t135, i32 1
  %t138 = extractelement <3 x float> %t135, i32 2
  %t139 = insertelement <4 x float> undef, float %t136, i32 0
  %t140 = insertelement <4 x float> %t139, float %t137, i32 1
  %t141 = insertelement <4 x float> %t140, float %t138, i32 2
  %t142 = insertelement <4 x float> %t141, float 0x0000000000000000, i32 3
  %t143 = extractelement <4 x float> %t132, i32 0
  %t144 = extractelement <4 x float> %t132, i32 1
  %t145 = extractelement <4 x float> %t132, i32 2
  %t146 = extractelement <4 x float> %t132, i32 3
  %t147 = fsub float 0x0000000000000000, %t143
  %t148 = fsub float 0x0000000000000000, %t144
  %t149 = fsub float 0x0000000000000000, %t145
  %t150 = insertelement <4 x float> undef, float %t147, i32 0
  %t151 = insertelement <4 x float> %t150, float %t148, i32 1
  %t152 = insertelement <4 x float> %t151, float %t149, i32 2
  %t153 = insertelement <4 x float> %t152, float %t146, i32 3
  %t154 = extractelement <4 x float> %t132, i32 0
  %t155 = extractelement <4 x float> %t132, i32 1
  %t156 = extractelement <4 x float> %t132, i32 2
  %t157 = extractelement <4 x float> %t132, i32 3
  %t158 = extractelement <4 x float> %t142, i32 0
  %t159 = extractelement <4 x float> %t142, i32 1
  %t160 = extractelement <4 x float> %t142, i32 2
  %t161 = extractelement <4 x float> %t142, i32 3
  %t162 = fmul float %t157, %t161
  %t163 = fmul float %t154, %t158
  %t164 = fmul float %t155, %t159
  %t165 = fmul float %t156, %t160
  %t166 = fsub float %t162, %t163
  %t167 = fsub float %t166, %t164
  %t168 = fsub float %t167, %t165
  %t169 = fmul float %t157, %t158
  %t170 = fmul float %t154, %t161
  %t171 = fmul float %t155, %t160
  %t172 = fmul float %t156, %t159
  %t173 = fadd float %t169, %t170
  %t174 = fadd float %t173, %t171
  %t175 = fsub float %t174, %t172
  %t176 = fmul float %t157, %t159
  %t177 = fmul float %t154, %t160
  %t178 = fmul float %t155, %t161
  %t179 = fmul float %t156, %t158
  %t180 = fsub float %t176, %t177
  %t181 = fadd float %t180, %t178
  %t182 = fadd float %t181, %t179
  %t183 = fmul float %t157, %t160
  %t184 = fmul float %t154, %t159
  %t185 = fmul float %t155, %t158
  %t186 = fmul float %t156, %t161
  %t187 = fadd float %t183, %t184
  %t188 = fsub float %t187, %t185
  %t189 = fadd float %t188, %t186
  %t190 = insertelement <4 x float> undef, float %t175, i32 0
  %t191 = insertelement <4 x float> %t190, float %t182, i32 1
  %t192 = insertelement <4 x float> %t191, float %t189, i32 2
  %t193 = insertelement <4 x float> %t192, float %t168, i32 3
  %t194 = extractelement <4 x float> %t193, i32 0
  %t195 = extractelement <4 x float> %t193, i32 1
  %t196 = extractelement <4 x float> %t193, i32 2
  %t197 = extractelement <4 x float> %t193, i32 3
  %t198 = extractelement <4 x float> %t153, i32 0
  %t199 = extractelement <4 x float> %t153, i32 1
  %t200 = extractelement <4 x float> %t153, i32 2
  %t201 = extractelement <4 x float> %t153, i32 3
  %t202 = fmul float %t197, %t201
  %t203 = fmul float %t194, %t198
  %t204 = fmul float %t195, %t199
  %t205 = fmul float %t196, %t200
  %t206 = fsub float %t202, %t203
  %t207 = fsub float %t206, %t204
  %t208 = fsub float %t207, %t205
  %t209 = fmul float %t197, %t198
  %t210 = fmul float %t194, %t201
  %t211 = fmul float %t195, %t200
  %t212 = fmul float %t196, %t199
  %t213 = fadd float %t209, %t210
  %t214 = fadd float %t213, %t211
  %t215 = fsub float %t214, %t212
  %t216 = fmul float %t197, %t199
  %t217 = fmul float %t194, %t200
  %t218 = fmul float %t195, %t201
  %t219 = fmul float %t196, %t198
  %t220 = fsub float %t216, %t217
  %t221 = fadd float %t220, %t218
  %t222 = fadd float %t221, %t219
  %t223 = fmul float %t197, %t200
  %t224 = fmul float %t194, %t199
  %t225 = fmul float %t195, %t198
  %t226 = fmul float %t196, %t201
  %t227 = fadd float %t223, %t224
  %t228 = fsub float %t227, %t225
  %t229 = fadd float %t228, %t226
  %t230 = insertelement <4 x float> undef, float %t215, i32 0
  %t231 = insertelement <4 x float> %t230, float %t222, i32 1
  %t232 = insertelement <4 x float> %t231, float %t229, i32 2
  %t233 = insertelement <4 x float> %t232, float %t208, i32 3
  %t234 = extractelement <4 x float> %t233, i32 0
  %t235 = extractelement <4 x float> %t233, i32 1
  %t236 = extractelement <4 x float> %t233, i32 2
  %t237 = insertelement <3 x float> undef, float %t234, i32 0
  %t238 = insertelement <3 x float> %t237, float %t235, i32 1
  %t239 = insertelement <3 x float> %t238, float %t236, i32 2
  store <3 x float> %t239, <3 x float>* %t131
  %t240 = load <3 x float>, <3 x float>* %t131
  %t241 = extractelement <3 x float> %t240, i32 0
  %t242 = load <3 x float>, <3 x float>* %t131
  %t243 = extractelement <3 x float> %t242, i32 1
  %t244 = load <3 x float>, <3 x float>* %t131
  %t245 = extractelement <3 x float> %t244, i32 2
  %t246 = getelementptr inbounds [48 x i8], [48 x i8]* @.str.1, i64 0, i64 0
  %t247 = fpext float %t241 to double
  %t248 = fpext float %t243 to double
  %t249 = fpext float %t245 to double
  call i32 (i8*, ...) @printf(i8* %t246, double %t247, double %t248, double %t249)
  %t251 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t252 = insertelement <4 x float> %t251, float 0x0000000000000000, i32 1
  %t253 = insertelement <4 x float> %t252, float 0x3FD87DE2A0000000, i32 2
  %t254 = insertelement <4 x float> %t253, float 0x3FED906BC0000000, i32 3
  store <4 x float> %t254, <4 x float>* %t250
  %t256 = load <4 x float>, <4 x float>* %t250
  %t257 = load <4 x float>, <4 x float>* %t250
  %t258 = extractelement <4 x float> %t256, i32 0
  %t259 = extractelement <4 x float> %t256, i32 1
  %t260 = extractelement <4 x float> %t256, i32 2
  %t261 = extractelement <4 x float> %t256, i32 3
  %t262 = extractelement <4 x float> %t257, i32 0
  %t263 = extractelement <4 x float> %t257, i32 1
  %t264 = extractelement <4 x float> %t257, i32 2
  %t265 = extractelement <4 x float> %t257, i32 3
  %t266 = fmul float %t261, %t265
  %t267 = fmul float %t258, %t262
  %t268 = fmul float %t259, %t263
  %t269 = fmul float %t260, %t264
  %t270 = fsub float %t266, %t267
  %t271 = fsub float %t270, %t268
  %t272 = fsub float %t271, %t269
  %t273 = fmul float %t261, %t262
  %t274 = fmul float %t258, %t265
  %t275 = fmul float %t259, %t264
  %t276 = fmul float %t260, %t263
  %t277 = fadd float %t273, %t274
  %t278 = fadd float %t277, %t275
  %t279 = fsub float %t278, %t276
  %t280 = fmul float %t261, %t263
  %t281 = fmul float %t258, %t264
  %t282 = fmul float %t259, %t265
  %t283 = fmul float %t260, %t262
  %t284 = fsub float %t280, %t281
  %t285 = fadd float %t284, %t282
  %t286 = fadd float %t285, %t283
  %t287 = fmul float %t261, %t264
  %t288 = fmul float %t258, %t263
  %t289 = fmul float %t259, %t262
  %t290 = fmul float %t260, %t265
  %t291 = fadd float %t287, %t288
  %t292 = fsub float %t291, %t289
  %t293 = fadd float %t292, %t290
  %t294 = insertelement <4 x float> undef, float %t279, i32 0
  %t295 = insertelement <4 x float> %t294, float %t286, i32 1
  %t296 = insertelement <4 x float> %t295, float %t293, i32 2
  %t297 = insertelement <4 x float> %t296, float %t272, i32 3
  store <4 x float> %t297, <4 x float>* %t255
  %t299 = load <4 x float>, <4 x float>* %t255
  %t300 = insertelement <3 x float> undef, float 0x3FF0000000000000, i32 0
  %t301 = insertelement <3 x float> %t300, float 0x0000000000000000, i32 1
  %t302 = insertelement <3 x float> %t301, float 0x0000000000000000, i32 2
  %t303 = extractelement <3 x float> %t302, i32 0
  %t304 = extractelement <3 x float> %t302, i32 1
  %t305 = extractelement <3 x float> %t302, i32 2
  %t306 = insertelement <4 x float> undef, float %t303, i32 0
  %t307 = insertelement <4 x float> %t306, float %t304, i32 1
  %t308 = insertelement <4 x float> %t307, float %t305, i32 2
  %t309 = insertelement <4 x float> %t308, float 0x0000000000000000, i32 3
  %t310 = extractelement <4 x float> %t299, i32 0
  %t311 = extractelement <4 x float> %t299, i32 1
  %t312 = extractelement <4 x float> %t299, i32 2
  %t313 = extractelement <4 x float> %t299, i32 3
  %t314 = fsub float 0x0000000000000000, %t310
  %t315 = fsub float 0x0000000000000000, %t311
  %t316 = fsub float 0x0000000000000000, %t312
  %t317 = insertelement <4 x float> undef, float %t314, i32 0
  %t318 = insertelement <4 x float> %t317, float %t315, i32 1
  %t319 = insertelement <4 x float> %t318, float %t316, i32 2
  %t320 = insertelement <4 x float> %t319, float %t313, i32 3
  %t321 = extractelement <4 x float> %t299, i32 0
  %t322 = extractelement <4 x float> %t299, i32 1
  %t323 = extractelement <4 x float> %t299, i32 2
  %t324 = extractelement <4 x float> %t299, i32 3
  %t325 = extractelement <4 x float> %t309, i32 0
  %t326 = extractelement <4 x float> %t309, i32 1
  %t327 = extractelement <4 x float> %t309, i32 2
  %t328 = extractelement <4 x float> %t309, i32 3
  %t329 = fmul float %t324, %t328
  %t330 = fmul float %t321, %t325
  %t331 = fmul float %t322, %t326
  %t332 = fmul float %t323, %t327
  %t333 = fsub float %t329, %t330
  %t334 = fsub float %t333, %t331
  %t335 = fsub float %t334, %t332
  %t336 = fmul float %t324, %t325
  %t337 = fmul float %t321, %t328
  %t338 = fmul float %t322, %t327
  %t339 = fmul float %t323, %t326
  %t340 = fadd float %t336, %t337
  %t341 = fadd float %t340, %t338
  %t342 = fsub float %t341, %t339
  %t343 = fmul float %t324, %t326
  %t344 = fmul float %t321, %t327
  %t345 = fmul float %t322, %t328
  %t346 = fmul float %t323, %t325
  %t347 = fsub float %t343, %t344
  %t348 = fadd float %t347, %t345
  %t349 = fadd float %t348, %t346
  %t350 = fmul float %t324, %t327
  %t351 = fmul float %t321, %t326
  %t352 = fmul float %t322, %t325
  %t353 = fmul float %t323, %t328
  %t354 = fadd float %t350, %t351
  %t355 = fsub float %t354, %t352
  %t356 = fadd float %t355, %t353
  %t357 = insertelement <4 x float> undef, float %t342, i32 0
  %t358 = insertelement <4 x float> %t357, float %t349, i32 1
  %t359 = insertelement <4 x float> %t358, float %t356, i32 2
  %t360 = insertelement <4 x float> %t359, float %t335, i32 3
  %t361 = extractelement <4 x float> %t360, i32 0
  %t362 = extractelement <4 x float> %t360, i32 1
  %t363 = extractelement <4 x float> %t360, i32 2
  %t364 = extractelement <4 x float> %t360, i32 3
  %t365 = extractelement <4 x float> %t320, i32 0
  %t366 = extractelement <4 x float> %t320, i32 1
  %t367 = extractelement <4 x float> %t320, i32 2
  %t368 = extractelement <4 x float> %t320, i32 3
  %t369 = fmul float %t364, %t368
  %t370 = fmul float %t361, %t365
  %t371 = fmul float %t362, %t366
  %t372 = fmul float %t363, %t367
  %t373 = fsub float %t369, %t370
  %t374 = fsub float %t373, %t371
  %t375 = fsub float %t374, %t372
  %t376 = fmul float %t364, %t365
  %t377 = fmul float %t361, %t368
  %t378 = fmul float %t362, %t367
  %t379 = fmul float %t363, %t366
  %t380 = fadd float %t376, %t377
  %t381 = fadd float %t380, %t378
  %t382 = fsub float %t381, %t379
  %t383 = fmul float %t364, %t366
  %t384 = fmul float %t361, %t367
  %t385 = fmul float %t362, %t368
  %t386 = fmul float %t363, %t365
  %t387 = fsub float %t383, %t384
  %t388 = fadd float %t387, %t385
  %t389 = fadd float %t388, %t386
  %t390 = fmul float %t364, %t367
  %t391 = fmul float %t361, %t366
  %t392 = fmul float %t362, %t365
  %t393 = fmul float %t363, %t368
  %t394 = fadd float %t390, %t391
  %t395 = fsub float %t394, %t392
  %t396 = fadd float %t395, %t393
  %t397 = insertelement <4 x float> undef, float %t382, i32 0
  %t398 = insertelement <4 x float> %t397, float %t389, i32 1
  %t399 = insertelement <4 x float> %t398, float %t396, i32 2
  %t400 = insertelement <4 x float> %t399, float %t375, i32 3
  %t401 = extractelement <4 x float> %t400, i32 0
  %t402 = extractelement <4 x float> %t400, i32 1
  %t403 = extractelement <4 x float> %t400, i32 2
  %t404 = insertelement <3 x float> undef, float %t401, i32 0
  %t405 = insertelement <3 x float> %t404, float %t402, i32 1
  %t406 = insertelement <3 x float> %t405, float %t403, i32 2
  store <3 x float> %t406, <3 x float>* %t298
  %t407 = load <3 x float>, <3 x float>* %t298
  %t408 = extractelement <3 x float> %t407, i32 0
  %t409 = load <3 x float>, <3 x float>* %t298
  %t410 = extractelement <3 x float> %t409, i32 1
  %t411 = load <3 x float>, <3 x float>* %t298
  %t412 = extractelement <3 x float> %t411, i32 2
  %t413 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.2, i64 0, i64 0
  %t414 = fpext float %t408 to double
  %t415 = fpext float %t410 to double
  %t416 = fpext float %t412 to double
  call i32 (i8*, ...) @printf(i8* %t413, double %t414, double %t415, double %t416)
  %t418 = load <4 x float>, <4 x float>* %t126
  %t419 = extractelement <4 x float> %t418, i32 0
  %t420 = extractelement <4 x float> %t418, i32 1
  %t421 = extractelement <4 x float> %t418, i32 2
  %t422 = extractelement <4 x float> %t418, i32 3
  %t423 = fsub float 0x0000000000000000, %t419
  %t424 = fsub float 0x0000000000000000, %t420
  %t425 = fsub float 0x0000000000000000, %t421
  %t426 = insertelement <4 x float> undef, float %t423, i32 0
  %t427 = insertelement <4 x float> %t426, float %t424, i32 1
  %t428 = insertelement <4 x float> %t427, float %t425, i32 2
  %t429 = insertelement <4 x float> %t428, float %t422, i32 3
  %t430 = load <3 x float>, <3 x float>* %t131
  %t431 = extractelement <3 x float> %t430, i32 0
  %t432 = extractelement <3 x float> %t430, i32 1
  %t433 = extractelement <3 x float> %t430, i32 2
  %t434 = insertelement <4 x float> undef, float %t431, i32 0
  %t435 = insertelement <4 x float> %t434, float %t432, i32 1
  %t436 = insertelement <4 x float> %t435, float %t433, i32 2
  %t437 = insertelement <4 x float> %t436, float 0x0000000000000000, i32 3
  %t438 = extractelement <4 x float> %t429, i32 0
  %t439 = extractelement <4 x float> %t429, i32 1
  %t440 = extractelement <4 x float> %t429, i32 2
  %t441 = extractelement <4 x float> %t429, i32 3
  %t442 = fsub float 0x0000000000000000, %t438
  %t443 = fsub float 0x0000000000000000, %t439
  %t444 = fsub float 0x0000000000000000, %t440
  %t445 = insertelement <4 x float> undef, float %t442, i32 0
  %t446 = insertelement <4 x float> %t445, float %t443, i32 1
  %t447 = insertelement <4 x float> %t446, float %t444, i32 2
  %t448 = insertelement <4 x float> %t447, float %t441, i32 3
  %t449 = extractelement <4 x float> %t429, i32 0
  %t450 = extractelement <4 x float> %t429, i32 1
  %t451 = extractelement <4 x float> %t429, i32 2
  %t452 = extractelement <4 x float> %t429, i32 3
  %t453 = extractelement <4 x float> %t437, i32 0
  %t454 = extractelement <4 x float> %t437, i32 1
  %t455 = extractelement <4 x float> %t437, i32 2
  %t456 = extractelement <4 x float> %t437, i32 3
  %t457 = fmul float %t452, %t456
  %t458 = fmul float %t449, %t453
  %t459 = fmul float %t450, %t454
  %t460 = fmul float %t451, %t455
  %t461 = fsub float %t457, %t458
  %t462 = fsub float %t461, %t459
  %t463 = fsub float %t462, %t460
  %t464 = fmul float %t452, %t453
  %t465 = fmul float %t449, %t456
  %t466 = fmul float %t450, %t455
  %t467 = fmul float %t451, %t454
  %t468 = fadd float %t464, %t465
  %t469 = fadd float %t468, %t466
  %t470 = fsub float %t469, %t467
  %t471 = fmul float %t452, %t454
  %t472 = fmul float %t449, %t455
  %t473 = fmul float %t450, %t456
  %t474 = fmul float %t451, %t453
  %t475 = fsub float %t471, %t472
  %t476 = fadd float %t475, %t473
  %t477 = fadd float %t476, %t474
  %t478 = fmul float %t452, %t455
  %t479 = fmul float %t449, %t454
  %t480 = fmul float %t450, %t453
  %t481 = fmul float %t451, %t456
  %t482 = fadd float %t478, %t479
  %t483 = fsub float %t482, %t480
  %t484 = fadd float %t483, %t481
  %t485 = insertelement <4 x float> undef, float %t470, i32 0
  %t486 = insertelement <4 x float> %t485, float %t477, i32 1
  %t487 = insertelement <4 x float> %t486, float %t484, i32 2
  %t488 = insertelement <4 x float> %t487, float %t463, i32 3
  %t489 = extractelement <4 x float> %t488, i32 0
  %t490 = extractelement <4 x float> %t488, i32 1
  %t491 = extractelement <4 x float> %t488, i32 2
  %t492 = extractelement <4 x float> %t488, i32 3
  %t493 = extractelement <4 x float> %t448, i32 0
  %t494 = extractelement <4 x float> %t448, i32 1
  %t495 = extractelement <4 x float> %t448, i32 2
  %t496 = extractelement <4 x float> %t448, i32 3
  %t497 = fmul float %t492, %t496
  %t498 = fmul float %t489, %t493
  %t499 = fmul float %t490, %t494
  %t500 = fmul float %t491, %t495
  %t501 = fsub float %t497, %t498
  %t502 = fsub float %t501, %t499
  %t503 = fsub float %t502, %t500
  %t504 = fmul float %t492, %t493
  %t505 = fmul float %t489, %t496
  %t506 = fmul float %t490, %t495
  %t507 = fmul float %t491, %t494
  %t508 = fadd float %t504, %t505
  %t509 = fadd float %t508, %t506
  %t510 = fsub float %t509, %t507
  %t511 = fmul float %t492, %t494
  %t512 = fmul float %t489, %t495
  %t513 = fmul float %t490, %t496
  %t514 = fmul float %t491, %t493
  %t515 = fsub float %t511, %t512
  %t516 = fadd float %t515, %t513
  %t517 = fadd float %t516, %t514
  %t518 = fmul float %t492, %t495
  %t519 = fmul float %t489, %t494
  %t520 = fmul float %t490, %t493
  %t521 = fmul float %t491, %t496
  %t522 = fadd float %t518, %t519
  %t523 = fsub float %t522, %t520
  %t524 = fadd float %t523, %t521
  %t525 = insertelement <4 x float> undef, float %t510, i32 0
  %t526 = insertelement <4 x float> %t525, float %t517, i32 1
  %t527 = insertelement <4 x float> %t526, float %t524, i32 2
  %t528 = insertelement <4 x float> %t527, float %t503, i32 3
  %t529 = extractelement <4 x float> %t528, i32 0
  %t530 = extractelement <4 x float> %t528, i32 1
  %t531 = extractelement <4 x float> %t528, i32 2
  %t532 = insertelement <3 x float> undef, float %t529, i32 0
  %t533 = insertelement <3 x float> %t532, float %t530, i32 1
  %t534 = insertelement <3 x float> %t533, float %t531, i32 2
  store <3 x float> %t534, <3 x float>* %t417
  %t535 = load <3 x float>, <3 x float>* %t417
  %t536 = extractelement <3 x float> %t535, i32 0
  %t537 = load <3 x float>, <3 x float>* %t417
  %t538 = extractelement <3 x float> %t537, i32 1
  %t539 = load <3 x float>, <3 x float>* %t417
  %t540 = extractelement <3 x float> %t539, i32 2
  %t541 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.3, i64 0, i64 0
  %t542 = fpext float %t536 to double
  %t543 = fpext float %t538 to double
  %t544 = fpext float %t540 to double
  call i32 (i8*, ...) @printf(i8* %t541, double %t542, double %t543, double %t544)
  %t546 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t547 = insertelement <4 x float> %t546, float 0x0000000000000000, i32 1
  %t548 = insertelement <4 x float> %t547, float 0x0000000000000000, i32 2
  %t549 = insertelement <4 x float> %t548, float 0x4000000000000000, i32 3
  %t550 = extractelement <4 x float> %t549, i32 0
  %t551 = extractelement <4 x float> %t549, i32 1
  %t552 = extractelement <4 x float> %t549, i32 2
  %t553 = extractelement <4 x float> %t549, i32 3
  %t554 = extractelement <4 x float> %t549, i32 0
  %t555 = extractelement <4 x float> %t549, i32 0
  %t556 = fmul float %t554, %t555
  %t557 = extractelement <4 x float> %t549, i32 1
  %t558 = extractelement <4 x float> %t549, i32 1
  %t559 = fmul float %t557, %t558
  %t560 = fadd float %t556, %t559
  %t561 = extractelement <4 x float> %t549, i32 2
  %t562 = extractelement <4 x float> %t549, i32 2
  %t563 = fmul float %t561, %t562
  %t564 = fadd float %t560, %t563
  %t565 = extractelement <4 x float> %t549, i32 3
  %t566 = extractelement <4 x float> %t549, i32 3
  %t567 = fmul float %t565, %t566
  %t568 = fadd float %t564, %t567
  %t569 = call float @llvm.sqrt.f32(float %t568)
  %t570 = fdiv float %t550, %t569
  %t571 = fdiv float %t551, %t569
  %t572 = fdiv float %t552, %t569
  %t573 = fdiv float %t553, %t569
  %t574 = insertelement <4 x float> undef, float %t570, i32 0
  %t575 = insertelement <4 x float> %t574, float %t571, i32 1
  %t576 = insertelement <4 x float> %t575, float %t572, i32 2
  %t577 = insertelement <4 x float> %t576, float %t573, i32 3
  store <4 x float> %t577, <4 x float>* %t545
  %t578 = load <4 x float>, <4 x float>* %t545
  %t579 = extractelement <4 x float> %t578, i32 3
  %t580 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.4, i64 0, i64 0
  %t581 = fpext float %t579 to double
  call i32 (i8*, ...) @printf(i8* %t580, double %t581)
  %t583 = load <4 x float>, <4 x float>* %t126
  %t584 = load <4 x float>, <4 x float>* %t2
  %t585 = fadd <4 x float> %t583, %t584
  store <4 x float> %t585, <4 x float>* %t582
  %t586 = load <4 x float>, <4 x float>* %t582
  %t587 = extractelement <4 x float> %t586, i32 3
  %t588 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.5, i64 0, i64 0
  %t589 = fpext float %t587 to double
  call i32 (i8*, ...) @printf(i8* %t588, double %t589)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [29 x i8] c"identity rotate: %f, %f, %f\0A\00"
@.str.1 = private unnamed_addr constant [48 x i8] c"(1,0,0) rotated 90 degrees about Z: %f, %f, %f\0A\00"
@.str.2 = private unnamed_addr constant [29 x i8] c"composed rotate: %f, %f, %f\0A\00"
@.str.3 = private unnamed_addr constant [27 x i8] c"undone rotate: %f, %f, %f\0A\00"
@.str.4 = private unnamed_addr constant [18 x i8] c"normalized w: %f\0A\00"
@.str.5 = private unnamed_addr constant [25 x i8] c"componentwise sum w: %f\0A\00"
