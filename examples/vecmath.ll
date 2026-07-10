; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
declare i32 @puts(i8*)
declare noalias i8* @malloc(i64)
declare void @free(i8*)
declare void @exit(i32) noreturn
declare i32 @strlen(i8*)
declare i8* @memcpy(i8*, i8*, i64)
declare i8* @strcpy(i8*, i8*)
declare i8* @strcat(i8*, i8*)
declare i8* @CreateThread(i8*, i64, i8*, i8*, i32, i32*)
declare i32 @WaitForSingleObject(i8*, i32)
declare i32 @CloseHandle(i8*)
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

@rng.state = global i32 123456789

define i32 @main() {
entry:
  %t0 = alloca { float, float, float }
  %t1 = alloca { float, float, float }
  %t2 = getelementptr inbounds { float, float, float }, { float, float, float }* %t1, i32 0, i32 0
  store float 0x3FF0000000000000, float* %t2
  %t3 = getelementptr inbounds { float, float, float }, { float, float, float }* %t1, i32 0, i32 1
  store float 0x4000000000000000, float* %t3
  %t4 = getelementptr inbounds { float, float, float }, { float, float, float }* %t1, i32 0, i32 2
  store float 0x4008000000000000, float* %t4
  %t5 = load { float, float, float }, { float, float, float }* %t1
  store { float, float, float } %t5, { float, float, float }* %t0
  %t6 = alloca { float, float, float }
  %t7 = alloca { float, float, float }
  %t8 = getelementptr inbounds { float, float, float }, { float, float, float }* %t7, i32 0, i32 0
  store float 0x4024000000000000, float* %t8
  %t9 = getelementptr inbounds { float, float, float }, { float, float, float }* %t7, i32 0, i32 1
  store float 0x4034000000000000, float* %t9
  %t10 = getelementptr inbounds { float, float, float }, { float, float, float }* %t7, i32 0, i32 2
  store float 0x403E000000000000, float* %t10
  %t11 = load { float, float, float }, { float, float, float }* %t7
  store { float, float, float } %t11, { float, float, float }* %t6
  %t12 = alloca { float, float, float }
  %t13 = load { float, float, float }, { float, float, float }* %t0
  %t14 = load { float, float, float }, { float, float, float }* %t6
  %t15 = extractvalue { float, float, float } %t13, 0
  %t16 = extractvalue { float, float, float } %t14, 0
  %t17 = fadd float %t15, %t16
  %t18 = insertvalue { float, float, float } undef, float %t17, 0
  %t19 = extractvalue { float, float, float } %t13, 1
  %t20 = extractvalue { float, float, float } %t14, 1
  %t21 = fadd float %t19, %t20
  %t22 = insertvalue { float, float, float } %t18, float %t21, 1
  %t23 = extractvalue { float, float, float } %t13, 2
  %t24 = extractvalue { float, float, float } %t14, 2
  %t25 = fadd float %t23, %t24
  %t26 = insertvalue { float, float, float } %t22, float %t25, 2
  store { float, float, float } %t26, { float, float, float }* %t12
  %t27 = load { float, float, float }, { float, float, float }* %t12
  %t28 = extractvalue { float, float, float } %t27, 0
  %t29 = load { float, float, float }, { float, float, float }* %t12
  %t30 = extractvalue { float, float, float } %t29, 1
  %t31 = load { float, float, float }, { float, float, float }* %t12
  %t32 = extractvalue { float, float, float } %t31, 2
  %t33 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.0, i64 0, i64 0
  %t34 = fpext float %t28 to double
  %t35 = fpext float %t30 to double
  %t36 = fpext float %t32 to double
  call i32 (i8*, ...) @printf(i8* %t33, double %t34, double %t35, double %t36)
  %t37 = alloca { float, float, float }
  %t38 = load { float, float, float }, { float, float, float }* %t0
  %t39 = extractvalue { float, float, float } %t38, 0
  %t40 = fmul float %t39, 0x4000000000000000
  %t41 = insertvalue { float, float, float } undef, float %t40, 0
  %t42 = extractvalue { float, float, float } %t38, 1
  %t43 = fmul float %t42, 0x4000000000000000
  %t44 = insertvalue { float, float, float } %t41, float %t43, 1
  %t45 = extractvalue { float, float, float } %t38, 2
  %t46 = fmul float %t45, 0x4000000000000000
  %t47 = insertvalue { float, float, float } %t44, float %t46, 2
  store { float, float, float } %t47, { float, float, float }* %t37
  %t48 = load { float, float, float }, { float, float, float }* %t37
  %t49 = extractvalue { float, float, float } %t48, 0
  %t50 = load { float, float, float }, { float, float, float }* %t37
  %t51 = extractvalue { float, float, float } %t50, 1
  %t52 = load { float, float, float }, { float, float, float }* %t37
  %t53 = extractvalue { float, float, float } %t52, 2
  %t54 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.1, i64 0, i64 0
  %t55 = fpext float %t49 to double
  %t56 = fpext float %t51 to double
  %t57 = fpext float %t53 to double
  call i32 (i8*, ...) @printf(i8* %t54, double %t55, double %t56, double %t57)
  %t58 = alloca <4 x float>
  %t59 = insertelement <4 x float> undef, float 0x3FF0000000000000, i32 0
  %t60 = insertelement <4 x float> %t59, float 0x0000000000000000, i32 1
  %t61 = insertelement <4 x float> %t60, float 0x0000000000000000, i32 2
  %t62 = insertelement <4 x float> %t61, float 0x0000000000000000, i32 3
  store <4 x float> %t62, <4 x float>* %t58
  %t63 = alloca <4 x float>
  %t64 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t65 = insertelement <4 x float> %t64, float 0x3FF0000000000000, i32 1
  %t66 = insertelement <4 x float> %t65, float 0x0000000000000000, i32 2
  %t67 = insertelement <4 x float> %t66, float 0x0000000000000000, i32 3
  store <4 x float> %t67, <4 x float>* %t63
  %t68 = alloca <4 x float>
  %t69 = load <4 x float>, <4 x float>* %t58
  %t70 = load <4 x float>, <4 x float>* %t63
  %t71 = fadd <4 x float> %t69, %t70
  store <4 x float> %t71, <4 x float>* %t68
  %t72 = load <4 x float>, <4 x float>* %t68
  %t73 = extractelement <4 x float> %t72, i32 0
  %t74 = load <4 x float>, <4 x float>* %t68
  %t75 = extractelement <4 x float> %t74, i32 1
  %t76 = load <4 x float>, <4 x float>* %t68
  %t77 = extractelement <4 x float> %t76, i32 2
  %t78 = load <4 x float>, <4 x float>* %t68
  %t79 = extractelement <4 x float> %t78, i32 3
  %t80 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.2, i64 0, i64 0
  %t81 = fpext float %t73 to double
  %t82 = fpext float %t75 to double
  %t83 = fpext float %t77 to double
  %t84 = fpext float %t79 to double
  call i32 (i8*, ...) @printf(i8* %t80, double %t81, double %t82, double %t83, double %t84)
  %t85 = alloca { float, float, float }
  %t86 = load { float, float, float }, { float, float, float }* %t12
  %t87 = extractvalue { float, float, float } %t86, 2
  %t88 = insertvalue { float, float, float } undef, float %t87, 0
  %t89 = extractvalue { float, float, float } %t86, 1
  %t90 = insertvalue { float, float, float } %t88, float %t89, 1
  %t91 = extractvalue { float, float, float } %t86, 0
  %t92 = insertvalue { float, float, float } %t90, float %t91, 2
  store { float, float, float } %t92, { float, float, float }* %t85
  %t93 = load { float, float, float }, { float, float, float }* %t85
  %t94 = extractvalue { float, float, float } %t93, 0
  %t95 = load { float, float, float }, { float, float, float }* %t85
  %t96 = extractvalue { float, float, float } %t95, 1
  %t97 = load { float, float, float }, { float, float, float }* %t85
  %t98 = extractvalue { float, float, float } %t97, 2
  %t99 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.3, i64 0, i64 0
  %t100 = fpext float %t94 to double
  %t101 = fpext float %t96 to double
  %t102 = fpext float %t98 to double
  call i32 (i8*, ...) @printf(i8* %t99, double %t100, double %t101, double %t102)
  %t103 = alloca [4 x <4 x float>]
  %t104 = insertelement <4 x float> undef, float 0x3FF0000000000000, i32 0
  %t105 = insertelement <4 x float> %t104, float 0x0000000000000000, i32 1
  %t106 = insertelement <4 x float> %t105, float 0x0000000000000000, i32 2
  %t107 = insertelement <4 x float> %t106, float 0x0000000000000000, i32 3
  %t108 = insertvalue [4 x <4 x float>] undef, <4 x float> %t107, 0
  %t109 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t110 = insertelement <4 x float> %t109, float 0x3FF0000000000000, i32 1
  %t111 = insertelement <4 x float> %t110, float 0x0000000000000000, i32 2
  %t112 = insertelement <4 x float> %t111, float 0x0000000000000000, i32 3
  %t113 = insertvalue [4 x <4 x float>] %t108, <4 x float> %t112, 1
  %t114 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t115 = insertelement <4 x float> %t114, float 0x0000000000000000, i32 1
  %t116 = insertelement <4 x float> %t115, float 0x3FF0000000000000, i32 2
  %t117 = insertelement <4 x float> %t116, float 0x0000000000000000, i32 3
  %t118 = insertvalue [4 x <4 x float>] %t113, <4 x float> %t117, 2
  %t119 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t120 = insertelement <4 x float> %t119, float 0x0000000000000000, i32 1
  %t121 = insertelement <4 x float> %t120, float 0x0000000000000000, i32 2
  %t122 = insertelement <4 x float> %t121, float 0x3FF0000000000000, i32 3
  %t123 = insertvalue [4 x <4 x float>] %t118, <4 x float> %t122, 3
  store [4 x <4 x float>] %t123, [4 x <4 x float>]* %t103
  %t124 = alloca <4 x float>
  %t125 = load [4 x <4 x float>], [4 x <4 x float>]* %t103
  %t126 = load <4 x float>, <4 x float>* %t58
  %t127 = extractvalue [4 x <4 x float>] %t125, 0
  %t128 = fmul <4 x float> %t127, %t126
  %t129 = extractelement <4 x float> %t128, i32 0
  %t130 = extractelement <4 x float> %t128, i32 1
  %t131 = fadd float %t129, %t130
  %t132 = extractelement <4 x float> %t128, i32 2
  %t133 = fadd float %t131, %t132
  %t134 = extractelement <4 x float> %t128, i32 3
  %t135 = fadd float %t133, %t134
  %t136 = extractvalue [4 x <4 x float>] %t125, 1
  %t137 = fmul <4 x float> %t136, %t126
  %t138 = extractelement <4 x float> %t137, i32 0
  %t139 = extractelement <4 x float> %t137, i32 1
  %t140 = fadd float %t138, %t139
  %t141 = extractelement <4 x float> %t137, i32 2
  %t142 = fadd float %t140, %t141
  %t143 = extractelement <4 x float> %t137, i32 3
  %t144 = fadd float %t142, %t143
  %t145 = extractvalue [4 x <4 x float>] %t125, 2
  %t146 = fmul <4 x float> %t145, %t126
  %t147 = extractelement <4 x float> %t146, i32 0
  %t148 = extractelement <4 x float> %t146, i32 1
  %t149 = fadd float %t147, %t148
  %t150 = extractelement <4 x float> %t146, i32 2
  %t151 = fadd float %t149, %t150
  %t152 = extractelement <4 x float> %t146, i32 3
  %t153 = fadd float %t151, %t152
  %t154 = extractvalue [4 x <4 x float>] %t125, 3
  %t155 = fmul <4 x float> %t154, %t126
  %t156 = extractelement <4 x float> %t155, i32 0
  %t157 = extractelement <4 x float> %t155, i32 1
  %t158 = fadd float %t156, %t157
  %t159 = extractelement <4 x float> %t155, i32 2
  %t160 = fadd float %t158, %t159
  %t161 = extractelement <4 x float> %t155, i32 3
  %t162 = fadd float %t160, %t161
  %t163 = insertelement <4 x float> undef, float %t135, i32 0
  %t164 = insertelement <4 x float> %t163, float %t144, i32 1
  %t165 = insertelement <4 x float> %t164, float %t153, i32 2
  %t166 = insertelement <4 x float> %t165, float %t162, i32 3
  store <4 x float> %t166, <4 x float>* %t124
  %t167 = load <4 x float>, <4 x float>* %t124
  %t168 = extractelement <4 x float> %t167, i32 0
  %t169 = load <4 x float>, <4 x float>* %t124
  %t170 = extractelement <4 x float> %t169, i32 1
  %t171 = load <4 x float>, <4 x float>* %t124
  %t172 = extractelement <4 x float> %t171, i32 2
  %t173 = load <4 x float>, <4 x float>* %t124
  %t174 = extractelement <4 x float> %t173, i32 3
  %t175 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.4, i64 0, i64 0
  %t176 = fpext float %t168 to double
  %t177 = fpext float %t170 to double
  %t178 = fpext float %t172 to double
  %t179 = fpext float %t174 to double
  call i32 (i8*, ...) @printf(i8* %t175, double %t176, double %t177, double %t178, double %t179)
  %t180 = alloca <4 x float>
  %t181 = insertelement <4 x float> undef, float 0x3FF0000000000000, i32 0
  %t182 = insertelement <4 x float> %t181, float 0x3FF0000000000000, i32 1
  %t183 = insertelement <4 x float> %t182, float 0x3FF0000000000000, i32 2
  %t184 = insertelement <4 x float> %t183, float 0x3FF0000000000000, i32 3
  store <4 x float> %t184, <4 x float>* %t180
  %t185 = load <4 x float>, <4 x float>* %t180
  %t186 = insertelement <4 x float> %t185, float 0x4058C00000000000, i32 0
  store <4 x float> %t186, <4 x float>* %t180
  %t187 = load <4 x float>, <4 x float>* %t180
  %t188 = extractelement <4 x float> %t187, i32 0
  %t189 = load <4 x float>, <4 x float>* %t180
  %t190 = extractelement <4 x float> %t189, i32 1
  %t191 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.5, i64 0, i64 0
  %t192 = fpext float %t188 to double
  %t193 = fpext float %t190 to double
  call i32 (i8*, ...) @printf(i8* %t191, double %t192, double %t193)
  %t194 = alloca { float, float }
  %t195 = alloca { float, float }
  %t196 = getelementptr inbounds { float, float }, { float, float }* %t195, i32 0, i32 0
  store float 0x3FF0000000000000, float* %t196
  %t197 = getelementptr inbounds { float, float }, { float, float }* %t195, i32 0, i32 1
  store float 0x3FF0000000000000, float* %t197
  %t198 = load { float, float }, { float, float }* %t195
  store { float, float } %t198, { float, float }* %t194
  %t199 = alloca { float, float }
  %t200 = getelementptr inbounds { float, float }, { float, float }* %t199, i32 0, i32 0
  store float 0x4014000000000000, float* %t200
  %t201 = getelementptr inbounds { float, float }, { float, float }* %t199, i32 0, i32 1
  store float 0x4018000000000000, float* %t201
  %t202 = load { float, float }, { float, float }* %t199
  %t203 = extractvalue { float, float } %t202, 0
  %t204 = getelementptr inbounds { float, float }, { float, float }* %t194, i32 0, i32 0
  store float %t203, float* %t204
  %t205 = extractvalue { float, float } %t202, 1
  %t206 = getelementptr inbounds { float, float }, { float, float }* %t194, i32 0, i32 1
  store float %t205, float* %t206
  %t207 = load { float, float }, { float, float }* %t194
  %t208 = extractvalue { float, float } %t207, 0
  %t209 = load { float, float }, { float, float }* %t194
  %t210 = extractvalue { float, float } %t209, 1
  %t211 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.6, i64 0, i64 0
  %t212 = fpext float %t208 to double
  %t213 = fpext float %t210 to double
  call i32 (i8*, ...) @printf(i8* %t211, double %t212, double %t213)
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
