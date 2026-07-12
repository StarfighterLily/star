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
declare i8* @fopen(i8*, i8*)
declare i32 @fclose(i8*)
declare i64 @fread(i8*, i64, i64, i8*)
declare i64 @fwrite(i8*, i64, i64, i8*)
declare i32 @fseek(i8*, i32, i32)
declare i32 @ftell(i8*)
declare i32 @fgetc(i8*)
declare i8* @getenv(i8*)
declare i32 @_putenv(i8*)
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

%GenRef = type { i32, i32 }

@frame.buf = global [4096 x i8] zeroinitializer
@frame.off = global i64 0

@star.argc = global i32 0
@star.argv = global i8** null

@rng.state = global i32 123456789

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

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = alloca <3 x float>
  %t1 = insertelement <3 x float> undef, float 0x3FF0000000000000, i32 0
  %t2 = insertelement <3 x float> %t1, float 0x4000000000000000, i32 1
  %t3 = insertelement <3 x float> %t2, float 0x4008000000000000, i32 2
  store <3 x float> %t3, <3 x float>* %t0
  %t4 = alloca <3 x float>
  %t5 = insertelement <3 x float> undef, float 0x4024000000000000, i32 0
  %t6 = insertelement <3 x float> %t5, float 0x4034000000000000, i32 1
  %t7 = insertelement <3 x float> %t6, float 0x403E000000000000, i32 2
  store <3 x float> %t7, <3 x float>* %t4
  %t8 = alloca <3 x float>
  %t9 = load <3 x float>, <3 x float>* %t0
  %t10 = load <3 x float>, <3 x float>* %t4
  %t11 = fadd <3 x float> %t9, %t10
  store <3 x float> %t11, <3 x float>* %t8
  %t12 = load <3 x float>, <3 x float>* %t8
  %t13 = extractelement <3 x float> %t12, i32 0
  %t14 = load <3 x float>, <3 x float>* %t8
  %t15 = extractelement <3 x float> %t14, i32 1
  %t16 = load <3 x float>, <3 x float>* %t8
  %t17 = extractelement <3 x float> %t16, i32 2
  %t18 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.0, i64 0, i64 0
  %t19 = fpext float %t13 to double
  %t20 = fpext float %t15 to double
  %t21 = fpext float %t17 to double
  call i32 (i8*, ...) @printf(i8* %t18, double %t19, double %t20, double %t21)
  %t22 = alloca <3 x float>
  %t23 = load <3 x float>, <3 x float>* %t0
  %t24 = insertelement <3 x float> undef, float 0x4000000000000000, i32 0
  %t25 = insertelement <3 x float> %t24, float 0x4000000000000000, i32 1
  %t26 = insertelement <3 x float> %t25, float 0x4000000000000000, i32 2
  %t27 = fmul <3 x float> %t23, %t26
  store <3 x float> %t27, <3 x float>* %t22
  %t28 = load <3 x float>, <3 x float>* %t22
  %t29 = extractelement <3 x float> %t28, i32 0
  %t30 = load <3 x float>, <3 x float>* %t22
  %t31 = extractelement <3 x float> %t30, i32 1
  %t32 = load <3 x float>, <3 x float>* %t22
  %t33 = extractelement <3 x float> %t32, i32 2
  %t34 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.1, i64 0, i64 0
  %t35 = fpext float %t29 to double
  %t36 = fpext float %t31 to double
  %t37 = fpext float %t33 to double
  call i32 (i8*, ...) @printf(i8* %t34, double %t35, double %t36, double %t37)
  %t38 = alloca <4 x float>
  %t39 = insertelement <4 x float> undef, float 0x3FF0000000000000, i32 0
  %t40 = insertelement <4 x float> %t39, float 0x0000000000000000, i32 1
  %t41 = insertelement <4 x float> %t40, float 0x0000000000000000, i32 2
  %t42 = insertelement <4 x float> %t41, float 0x0000000000000000, i32 3
  store <4 x float> %t42, <4 x float>* %t38
  %t43 = alloca <4 x float>
  %t44 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t45 = insertelement <4 x float> %t44, float 0x3FF0000000000000, i32 1
  %t46 = insertelement <4 x float> %t45, float 0x0000000000000000, i32 2
  %t47 = insertelement <4 x float> %t46, float 0x0000000000000000, i32 3
  store <4 x float> %t47, <4 x float>* %t43
  %t48 = alloca <4 x float>
  %t49 = load <4 x float>, <4 x float>* %t38
  %t50 = load <4 x float>, <4 x float>* %t43
  %t51 = fadd <4 x float> %t49, %t50
  store <4 x float> %t51, <4 x float>* %t48
  %t52 = load <4 x float>, <4 x float>* %t48
  %t53 = extractelement <4 x float> %t52, i32 0
  %t54 = load <4 x float>, <4 x float>* %t48
  %t55 = extractelement <4 x float> %t54, i32 1
  %t56 = load <4 x float>, <4 x float>* %t48
  %t57 = extractelement <4 x float> %t56, i32 2
  %t58 = load <4 x float>, <4 x float>* %t48
  %t59 = extractelement <4 x float> %t58, i32 3
  %t60 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.2, i64 0, i64 0
  %t61 = fpext float %t53 to double
  %t62 = fpext float %t55 to double
  %t63 = fpext float %t57 to double
  %t64 = fpext float %t59 to double
  call i32 (i8*, ...) @printf(i8* %t60, double %t61, double %t62, double %t63, double %t64)
  %t65 = alloca <3 x float>
  %t66 = load <3 x float>, <3 x float>* %t8
  %t67 = shufflevector <3 x float> %t66, <3 x float> undef, <3 x i32> <i32 2, i32 1, i32 0>
  store <3 x float> %t67, <3 x float>* %t65
  %t68 = load <3 x float>, <3 x float>* %t65
  %t69 = extractelement <3 x float> %t68, i32 0
  %t70 = load <3 x float>, <3 x float>* %t65
  %t71 = extractelement <3 x float> %t70, i32 1
  %t72 = load <3 x float>, <3 x float>* %t65
  %t73 = extractelement <3 x float> %t72, i32 2
  %t74 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.3, i64 0, i64 0
  %t75 = fpext float %t69 to double
  %t76 = fpext float %t71 to double
  %t77 = fpext float %t73 to double
  call i32 (i8*, ...) @printf(i8* %t74, double %t75, double %t76, double %t77)
  %t78 = alloca [4 x <4 x float>]
  %t79 = insertelement <4 x float> undef, float 0x3FF0000000000000, i32 0
  %t80 = insertelement <4 x float> %t79, float 0x0000000000000000, i32 1
  %t81 = insertelement <4 x float> %t80, float 0x0000000000000000, i32 2
  %t82 = insertelement <4 x float> %t81, float 0x0000000000000000, i32 3
  %t83 = insertvalue [4 x <4 x float>] undef, <4 x float> %t82, 0
  %t84 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t85 = insertelement <4 x float> %t84, float 0x3FF0000000000000, i32 1
  %t86 = insertelement <4 x float> %t85, float 0x0000000000000000, i32 2
  %t87 = insertelement <4 x float> %t86, float 0x0000000000000000, i32 3
  %t88 = insertvalue [4 x <4 x float>] %t83, <4 x float> %t87, 1
  %t89 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t90 = insertelement <4 x float> %t89, float 0x0000000000000000, i32 1
  %t91 = insertelement <4 x float> %t90, float 0x3FF0000000000000, i32 2
  %t92 = insertelement <4 x float> %t91, float 0x0000000000000000, i32 3
  %t93 = insertvalue [4 x <4 x float>] %t88, <4 x float> %t92, 2
  %t94 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t95 = insertelement <4 x float> %t94, float 0x0000000000000000, i32 1
  %t96 = insertelement <4 x float> %t95, float 0x0000000000000000, i32 2
  %t97 = insertelement <4 x float> %t96, float 0x3FF0000000000000, i32 3
  %t98 = insertvalue [4 x <4 x float>] %t93, <4 x float> %t97, 3
  store [4 x <4 x float>] %t98, [4 x <4 x float>]* %t78
  %t99 = alloca <4 x float>
  %t100 = load [4 x <4 x float>], [4 x <4 x float>]* %t78
  %t101 = load <4 x float>, <4 x float>* %t38
  %t102 = extractvalue [4 x <4 x float>] %t100, 0
  %t103 = fmul <4 x float> %t102, %t101
  %t104 = extractelement <4 x float> %t103, i32 0
  %t105 = extractelement <4 x float> %t103, i32 1
  %t106 = fadd float %t104, %t105
  %t107 = extractelement <4 x float> %t103, i32 2
  %t108 = fadd float %t106, %t107
  %t109 = extractelement <4 x float> %t103, i32 3
  %t110 = fadd float %t108, %t109
  %t111 = extractvalue [4 x <4 x float>] %t100, 1
  %t112 = fmul <4 x float> %t111, %t101
  %t113 = extractelement <4 x float> %t112, i32 0
  %t114 = extractelement <4 x float> %t112, i32 1
  %t115 = fadd float %t113, %t114
  %t116 = extractelement <4 x float> %t112, i32 2
  %t117 = fadd float %t115, %t116
  %t118 = extractelement <4 x float> %t112, i32 3
  %t119 = fadd float %t117, %t118
  %t120 = extractvalue [4 x <4 x float>] %t100, 2
  %t121 = fmul <4 x float> %t120, %t101
  %t122 = extractelement <4 x float> %t121, i32 0
  %t123 = extractelement <4 x float> %t121, i32 1
  %t124 = fadd float %t122, %t123
  %t125 = extractelement <4 x float> %t121, i32 2
  %t126 = fadd float %t124, %t125
  %t127 = extractelement <4 x float> %t121, i32 3
  %t128 = fadd float %t126, %t127
  %t129 = extractvalue [4 x <4 x float>] %t100, 3
  %t130 = fmul <4 x float> %t129, %t101
  %t131 = extractelement <4 x float> %t130, i32 0
  %t132 = extractelement <4 x float> %t130, i32 1
  %t133 = fadd float %t131, %t132
  %t134 = extractelement <4 x float> %t130, i32 2
  %t135 = fadd float %t133, %t134
  %t136 = extractelement <4 x float> %t130, i32 3
  %t137 = fadd float %t135, %t136
  %t138 = insertelement <4 x float> undef, float %t110, i32 0
  %t139 = insertelement <4 x float> %t138, float %t119, i32 1
  %t140 = insertelement <4 x float> %t139, float %t128, i32 2
  %t141 = insertelement <4 x float> %t140, float %t137, i32 3
  store <4 x float> %t141, <4 x float>* %t99
  %t142 = load <4 x float>, <4 x float>* %t99
  %t143 = extractelement <4 x float> %t142, i32 0
  %t144 = load <4 x float>, <4 x float>* %t99
  %t145 = extractelement <4 x float> %t144, i32 1
  %t146 = load <4 x float>, <4 x float>* %t99
  %t147 = extractelement <4 x float> %t146, i32 2
  %t148 = load <4 x float>, <4 x float>* %t99
  %t149 = extractelement <4 x float> %t148, i32 3
  %t150 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.4, i64 0, i64 0
  %t151 = fpext float %t143 to double
  %t152 = fpext float %t145 to double
  %t153 = fpext float %t147 to double
  %t154 = fpext float %t149 to double
  call i32 (i8*, ...) @printf(i8* %t150, double %t151, double %t152, double %t153, double %t154)
  %t155 = alloca <4 x float>
  %t156 = insertelement <4 x float> undef, float 0x3FF0000000000000, i32 0
  %t157 = insertelement <4 x float> %t156, float 0x3FF0000000000000, i32 1
  %t158 = insertelement <4 x float> %t157, float 0x3FF0000000000000, i32 2
  %t159 = insertelement <4 x float> %t158, float 0x3FF0000000000000, i32 3
  store <4 x float> %t159, <4 x float>* %t155
  %t160 = load <4 x float>, <4 x float>* %t155
  %t161 = insertelement <4 x float> %t160, float 0x4058C00000000000, i32 0
  store <4 x float> %t161, <4 x float>* %t155
  %t162 = load <4 x float>, <4 x float>* %t155
  %t163 = extractelement <4 x float> %t162, i32 0
  %t164 = load <4 x float>, <4 x float>* %t155
  %t165 = extractelement <4 x float> %t164, i32 1
  %t166 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.5, i64 0, i64 0
  %t167 = fpext float %t163 to double
  %t168 = fpext float %t165 to double
  call i32 (i8*, ...) @printf(i8* %t166, double %t167, double %t168)
  %t169 = alloca <2 x float>
  %t170 = insertelement <2 x float> undef, float 0x3FF0000000000000, i32 0
  %t171 = insertelement <2 x float> %t170, float 0x3FF0000000000000, i32 1
  store <2 x float> %t171, <2 x float>* %t169
  %t172 = insertelement <2 x float> undef, float 0x4014000000000000, i32 0
  %t173 = insertelement <2 x float> %t172, float 0x4018000000000000, i32 1
  %t174 = load <2 x float>, <2 x float>* %t169
  %t175 = extractelement <2 x float> %t173, i32 0
  %t176 = insertelement <2 x float> %t174, float %t175, i32 0
  %t177 = extractelement <2 x float> %t173, i32 1
  %t178 = insertelement <2 x float> %t176, float %t177, i32 1
  store <2 x float> %t178, <2 x float>* %t169
  %t179 = load <2 x float>, <2 x float>* %t169
  %t180 = extractelement <2 x float> %t179, i32 0
  %t181 = load <2 x float>, <2 x float>* %t169
  %t182 = extractelement <2 x float> %t181, i32 1
  %t183 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.6, i64 0, i64 0
  %t184 = fpext float %t180 to double
  %t185 = fpext float %t182 to double
  call i32 (i8*, ...) @printf(i8* %t183, double %t184, double %t185)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [15 x i8] c"sum: %f %f %f\0A\00"
@.str.1 = private unnamed_addr constant [18 x i8] c"scaled: %f %f %f\0A\00"
@.str.2 = private unnamed_addr constant [23 x i8] c"vec4 sum: %f %f %f %f\0A\00"
@.str.3 = private unnamed_addr constant [20 x i8] c"swizzled: %f %f %f\0A\00"
@.str.4 = private unnamed_addr constant [33 x i8] c"mat4*vec4 identity: %f %f %f %f\0A\00"
@.str.5 = private unnamed_addr constant [26 x i8] c"vec4 single write: %f %f\0A\00"
@.str.6 = private unnamed_addr constant [25 x i8] c"vec2 multi write: %f %f\0A\00"
