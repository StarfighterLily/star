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
  store float 0x0000000000000000, float* %t3
  %t4 = getelementptr inbounds { float, float, float }, { float, float, float }* %t1, i32 0, i32 2
  store float 0x0000000000000000, float* %t4
  %t5 = load { float, float, float }, { float, float, float }* %t1
  store { float, float, float } %t5, { float, float, float }* %t0
  %t6 = alloca { float, float, float }
  %t7 = alloca { float, float, float }
  %t8 = getelementptr inbounds { float, float, float }, { float, float, float }* %t7, i32 0, i32 0
  store float 0x0000000000000000, float* %t8
  %t9 = getelementptr inbounds { float, float, float }, { float, float, float }* %t7, i32 0, i32 1
  store float 0x3FF0000000000000, float* %t9
  %t10 = getelementptr inbounds { float, float, float }, { float, float, float }* %t7, i32 0, i32 2
  store float 0x0000000000000000, float* %t10
  %t11 = load { float, float, float }, { float, float, float }* %t7
  store { float, float, float } %t11, { float, float, float }* %t6
  %t12 = load { float, float, float }, { float, float, float }* %t0
  %t13 = load { float, float, float }, { float, float, float }* %t6
  %t14 = extractvalue { float, float, float } %t12, 0
  %t15 = extractvalue { float, float, float } %t13, 0
  %t16 = fmul float %t14, %t15
  %t17 = extractvalue { float, float, float } %t12, 1
  %t18 = extractvalue { float, float, float } %t13, 1
  %t19 = fmul float %t17, %t18
  %t20 = fadd float %t16, %t19
  %t21 = extractvalue { float, float, float } %t12, 2
  %t22 = extractvalue { float, float, float } %t13, 2
  %t23 = fmul float %t21, %t22
  %t24 = fadd float %t20, %t23
  %t25 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.0, i64 0, i64 0
  %t26 = fpext float %t24 to double
  call i32 (i8*, ...) @printf(i8* %t25, double %t26)
  %t27 = alloca { float, float, float }
  %t28 = alloca { float, float, float }
  %t29 = getelementptr inbounds { float, float, float }, { float, float, float }* %t28, i32 0, i32 0
  store float 0x4008000000000000, float* %t29
  %t30 = getelementptr inbounds { float, float, float }, { float, float, float }* %t28, i32 0, i32 1
  store float 0x4010000000000000, float* %t30
  %t31 = getelementptr inbounds { float, float, float }, { float, float, float }* %t28, i32 0, i32 2
  store float 0x0000000000000000, float* %t31
  %t32 = load { float, float, float }, { float, float, float }* %t28
  store { float, float, float } %t32, { float, float, float }* %t27
  %t33 = load { float, float, float }, { float, float, float }* %t27
  %t34 = extractvalue { float, float, float } %t33, 0
  %t35 = extractvalue { float, float, float } %t33, 0
  %t36 = fmul float %t34, %t35
  %t37 = extractvalue { float, float, float } %t33, 1
  %t38 = extractvalue { float, float, float } %t33, 1
  %t39 = fmul float %t37, %t38
  %t40 = fadd float %t36, %t39
  %t41 = extractvalue { float, float, float } %t33, 2
  %t42 = extractvalue { float, float, float } %t33, 2
  %t43 = fmul float %t41, %t42
  %t44 = fadd float %t40, %t43
  %t45 = call float @llvm.sqrt.f32(float %t44)
  %t46 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.1, i64 0, i64 0
  %t47 = fpext float %t45 to double
  call i32 (i8*, ...) @printf(i8* %t46, double %t47)
  %t48 = fsub float 0x4024000000000000, 0x0000000000000000
  %t49 = fmul float %t48, 0x3FE0000000000000
  %t50 = fadd float 0x0000000000000000, %t49
  %t51 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.2, i64 0, i64 0
  %t52 = fpext float %t50 to double
  call i32 (i8*, ...) @printf(i8* %t51, double %t52)
  %t53 = alloca { float, float, float }
  %t54 = load { float, float, float }, { float, float, float }* %t0
  %t55 = load { float, float, float }, { float, float, float }* %t27
  %t56 = extractvalue { float, float, float } %t54, 0
  %t57 = extractvalue { float, float, float } %t55, 0
  %t58 = fsub float %t57, %t56
  %t59 = fmul float %t58, 0x3FE0000000000000
  %t60 = fadd float %t56, %t59
  %t61 = insertvalue { float, float, float } undef, float %t60, 0
  %t62 = extractvalue { float, float, float } %t54, 1
  %t63 = extractvalue { float, float, float } %t55, 1
  %t64 = fsub float %t63, %t62
  %t65 = fmul float %t64, 0x3FE0000000000000
  %t66 = fadd float %t62, %t65
  %t67 = insertvalue { float, float, float } %t61, float %t66, 1
  %t68 = extractvalue { float, float, float } %t54, 2
  %t69 = extractvalue { float, float, float } %t55, 2
  %t70 = fsub float %t69, %t68
  %t71 = fmul float %t70, 0x3FE0000000000000
  %t72 = fadd float %t68, %t71
  %t73 = insertvalue { float, float, float } %t67, float %t72, 2
  store { float, float, float } %t73, { float, float, float }* %t53
  %t74 = load { float, float, float }, { float, float, float }* %t53
  %t75 = extractvalue { float, float, float } %t74, 0
  %t76 = load { float, float, float }, { float, float, float }* %t53
  %t77 = extractvalue { float, float, float } %t76, 1
  %t78 = load { float, float, float }, { float, float, float }* %t53
  %t79 = extractvalue { float, float, float } %t78, 2
  %t80 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.3, i64 0, i64 0
  %t81 = fpext float %t75 to double
  %t82 = fpext float %t77 to double
  %t83 = fpext float %t79 to double
  call i32 (i8*, ...) @printf(i8* %t80, double %t81, double %t82, double %t83)
  %t84 = icmp sgt i32 0, 15
  %t85 = select i1 %t84, i32 0, i32 15
  %t86 = icmp slt i32 10, %t85
  %t87 = select i1 %t86, i32 10, i32 %t85
  %t88 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t88, i32 %t87)
  %t89 = fsub float 0.0, 0x4004000000000000
  %t90 = call float @llvm.maxnum.f32(float %t89, float 0x0000000000000000)
  %t91 = call float @llvm.minnum.f32(float %t90, float 0x4024000000000000)
  %t92 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.5, i64 0, i64 0
  %t93 = fpext float %t91 to double
  call i32 (i8*, ...) @printf(i8* %t92, double %t93)
  %t94 = icmp eq i32 42, 0
  %t95 = select i1 %t94, i32 1, i32 42
  store i32 %t95, i32* @rng.state
  %t96 = alloca float
  %t97 = load i32, i32* @rng.state
  %t98 = shl i32 %t97, 13
  %t99 = xor i32 %t97, %t98
  %t100 = lshr i32 %t99, 17
  %t101 = xor i32 %t99, %t100
  %t102 = shl i32 %t101, 5
  %t103 = xor i32 %t101, %t102
  store i32 %t103, i32* @rng.state
  %t104 = and i32 %t103, 16777215
  %t105 = uitofp i32 %t104 to float
  %t106 = fdiv float %t105, 0x4170000000000000
  store float %t106, float* %t96
  %t107 = alloca float
  %t108 = load i32, i32* @rng.state
  %t109 = shl i32 %t108, 13
  %t110 = xor i32 %t108, %t109
  %t111 = lshr i32 %t110, 17
  %t112 = xor i32 %t110, %t111
  %t113 = shl i32 %t112, 5
  %t114 = xor i32 %t112, %t113
  store i32 %t114, i32* @rng.state
  %t115 = and i32 %t114, 16777215
  %t116 = uitofp i32 %t115 to float
  %t117 = fdiv float %t116, 0x4170000000000000
  store float %t117, float* %t107
  %t118 = load float, float* %t96
  %t119 = fcmp oge float %t118, 0x0000000000000000
  br i1 %t119, label %logic_rhs_0, label %logic_short_1
logic_rhs_0:
  %t120 = load float, float* %t96
  %t121 = fcmp olt float %t120, 0x3FF0000000000000
  br label %logic_end_2
logic_short_1:
  br label %logic_end_2
logic_end_2:
  %t122 = phi i1 [ %t121, %logic_rhs_0 ], [ false, %logic_short_1 ]
  %t123 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.6, i64 0, i64 0
  %t124 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.7, i64 0, i64 0
  %t125 = select i1 %t122, i8* %t123, i8* %t124
  %t126 = load float, float* %t107
  %t127 = fcmp oge float %t126, 0x0000000000000000
  br i1 %t127, label %logic_rhs_3, label %logic_short_4
logic_rhs_3:
  %t128 = load float, float* %t107
  %t129 = fcmp olt float %t128, 0x3FF0000000000000
  br label %logic_end_5
logic_short_4:
  br label %logic_end_5
logic_end_5:
  %t130 = phi i1 [ %t129, %logic_rhs_3 ], [ false, %logic_short_4 ]
  %t131 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.8, i64 0, i64 0
  %t132 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.9, i64 0, i64 0
  %t133 = select i1 %t130, i8* %t131, i8* %t132
  %t134 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t134, i8* %t125, i8* %t133)
  %t135 = alloca i32
  %t136 = sub i32 20, 10
  %t137 = icmp sle i32 %t136, 0
  %t138 = select i1 %t137, i32 1, i32 %t136
  %t139 = load i32, i32* @rng.state
  %t140 = shl i32 %t139, 13
  %t141 = xor i32 %t139, %t140
  %t142 = lshr i32 %t141, 17
  %t143 = xor i32 %t141, %t142
  %t144 = shl i32 %t143, 5
  %t145 = xor i32 %t143, %t144
  store i32 %t145, i32* @rng.state
  %t146 = and i32 %t145, 2147483647
  %t147 = urem i32 %t146, %t138
  %t148 = add i32 10, %t147
  store i32 %t148, i32* %t135
  %t149 = load i32, i32* %t135
  %t150 = icmp sge i32 %t149, 10
  br i1 %t150, label %logic_rhs_6, label %logic_short_7
logic_rhs_6:
  %t151 = load i32, i32* %t135
  %t152 = icmp slt i32 %t151, 20
  br label %logic_end_8
logic_short_7:
  br label %logic_end_8
logic_end_8:
  %t153 = phi i1 [ %t152, %logic_rhs_6 ], [ false, %logic_short_7 ]
  %t154 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.11, i64 0, i64 0
  %t155 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.12, i64 0, i64 0
  %t156 = select i1 %t153, i8* %t154, i8* %t155
  %t157 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t157, i8* %t156)
  %t158 = icmp eq i32 42, 0
  %t159 = select i1 %t158, i32 1, i32 42
  store i32 %t159, i32* @rng.state
  %t160 = alloca float
  %t161 = load i32, i32* @rng.state
  %t162 = shl i32 %t161, 13
  %t163 = xor i32 %t161, %t162
  %t164 = lshr i32 %t163, 17
  %t165 = xor i32 %t163, %t164
  %t166 = shl i32 %t165, 5
  %t167 = xor i32 %t165, %t166
  store i32 %t167, i32* @rng.state
  %t168 = and i32 %t167, 16777215
  %t169 = uitofp i32 %t168 to float
  %t170 = fdiv float %t169, 0x4170000000000000
  store float %t170, float* %t160
  %t171 = load float, float* %t96
  %t172 = load float, float* %t160
  %t173 = fcmp oeq float %t171, %t172
  %t174 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.14, i64 0, i64 0
  %t175 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.15, i64 0, i64 0
  %t176 = select i1 %t173, i8* %t174, i8* %t175
  %t177 = getelementptr inbounds [44 x i8], [44 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t177, i8* %t176)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [9 x i8] c"dot: %f\0A\00"
@.str.1 = private unnamed_addr constant [12 x i8] c"length: %f\0A\00"
@.str.2 = private unnamed_addr constant [16 x i8] c"lerp float: %f\0A\00"
@.str.3 = private unnamed_addr constant [20 x i8] c"lerp vec: %f %f %f\0A\00"
@.str.4 = private unnamed_addr constant [15 x i8] c"clamp int: %d\0A\00"
@.str.5 = private unnamed_addr constant [17 x i8] c"clamp float: %f\0A\00"
@.str.6 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.7 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.8 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.9 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.10 = private unnamed_addr constant [22 x i8] c"rand in [0,1): %s %s\0A\00"
@.str.11 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.12 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.13 = private unnamed_addr constant [26 x i8] c"rand_range in bounds: %s\0A\00"
@.str.14 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.15 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.16 = private unnamed_addr constant [44 x i8] c"reseeding reproduces the same sequence: %s\0A\00"
