; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
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
  %t2 = insertelement <3 x float> %t1, float 0x0000000000000000, i32 1
  %t3 = insertelement <3 x float> %t2, float 0x0000000000000000, i32 2
  store <3 x float> %t3, <3 x float>* %t0
  %t4 = alloca <3 x float>
  %t5 = insertelement <3 x float> undef, float 0x0000000000000000, i32 0
  %t6 = insertelement <3 x float> %t5, float 0x3FF0000000000000, i32 1
  %t7 = insertelement <3 x float> %t6, float 0x0000000000000000, i32 2
  store <3 x float> %t7, <3 x float>* %t4
  %t8 = load <3 x float>, <3 x float>* %t0
  %t9 = load <3 x float>, <3 x float>* %t4
  %t10 = fmul <3 x float> %t8, %t9
  %t11 = extractelement <3 x float> %t10, i32 0
  %t12 = extractelement <3 x float> %t10, i32 1
  %t13 = fadd float %t11, %t12
  %t14 = extractelement <3 x float> %t10, i32 2
  %t15 = fadd float %t13, %t14
  %t16 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.0, i64 0, i64 0
  %t17 = fpext float %t15 to double
  call i32 (i8*, ...) @printf(i8* %t16, double %t17)
  %t18 = alloca <3 x float>
  %t19 = insertelement <3 x float> undef, float 0x4008000000000000, i32 0
  %t20 = insertelement <3 x float> %t19, float 0x4010000000000000, i32 1
  %t21 = insertelement <3 x float> %t20, float 0x0000000000000000, i32 2
  store <3 x float> %t21, <3 x float>* %t18
  %t22 = load <3 x float>, <3 x float>* %t18
  %t23 = fmul <3 x float> %t22, %t22
  %t24 = extractelement <3 x float> %t23, i32 0
  %t25 = extractelement <3 x float> %t23, i32 1
  %t26 = fadd float %t24, %t25
  %t27 = extractelement <3 x float> %t23, i32 2
  %t28 = fadd float %t26, %t27
  %t29 = call float @llvm.sqrt.f32(float %t28)
  %t30 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.1, i64 0, i64 0
  %t31 = fpext float %t29 to double
  call i32 (i8*, ...) @printf(i8* %t30, double %t31)
  %t32 = fsub float 0x4024000000000000, 0x0000000000000000
  %t33 = fmul float %t32, 0x3FE0000000000000
  %t34 = fadd float 0x0000000000000000, %t33
  %t35 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.2, i64 0, i64 0
  %t36 = fpext float %t34 to double
  call i32 (i8*, ...) @printf(i8* %t35, double %t36)
  %t37 = alloca <3 x float>
  %t38 = load <3 x float>, <3 x float>* %t0
  %t39 = load <3 x float>, <3 x float>* %t18
  %t40 = extractelement <3 x float> %t38, i32 0
  %t41 = extractelement <3 x float> %t39, i32 0
  %t42 = fsub float %t41, %t40
  %t43 = fmul float %t42, 0x3FE0000000000000
  %t44 = fadd float %t40, %t43
  %t45 = insertelement <3 x float> undef, float %t44, i32 0
  %t46 = extractelement <3 x float> %t38, i32 1
  %t47 = extractelement <3 x float> %t39, i32 1
  %t48 = fsub float %t47, %t46
  %t49 = fmul float %t48, 0x3FE0000000000000
  %t50 = fadd float %t46, %t49
  %t51 = insertelement <3 x float> %t45, float %t50, i32 1
  %t52 = extractelement <3 x float> %t38, i32 2
  %t53 = extractelement <3 x float> %t39, i32 2
  %t54 = fsub float %t53, %t52
  %t55 = fmul float %t54, 0x3FE0000000000000
  %t56 = fadd float %t52, %t55
  %t57 = insertelement <3 x float> %t51, float %t56, i32 2
  store <3 x float> %t57, <3 x float>* %t37
  %t58 = load <3 x float>, <3 x float>* %t37
  %t59 = extractelement <3 x float> %t58, i32 0
  %t60 = load <3 x float>, <3 x float>* %t37
  %t61 = extractelement <3 x float> %t60, i32 1
  %t62 = load <3 x float>, <3 x float>* %t37
  %t63 = extractelement <3 x float> %t62, i32 2
  %t64 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.3, i64 0, i64 0
  %t65 = fpext float %t59 to double
  %t66 = fpext float %t61 to double
  %t67 = fpext float %t63 to double
  call i32 (i8*, ...) @printf(i8* %t64, double %t65, double %t66, double %t67)
  %t68 = icmp sgt i32 0, 15
  %t69 = select i1 %t68, i32 0, i32 15
  %t70 = icmp slt i32 10, %t69
  %t71 = select i1 %t70, i32 10, i32 %t69
  %t72 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t72, i32 %t71)
  %t73 = fsub float 0.0, 0x4004000000000000
  %t74 = call float @llvm.maxnum.f32(float %t73, float 0x0000000000000000)
  %t75 = call float @llvm.minnum.f32(float %t74, float 0x4024000000000000)
  %t76 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.5, i64 0, i64 0
  %t77 = fpext float %t75 to double
  call i32 (i8*, ...) @printf(i8* %t76, double %t77)
  %t78 = icmp eq i32 42, 0
  %t79 = select i1 %t78, i32 1, i32 42
  store i32 %t79, i32* @rng.state
  %t80 = alloca float
  %t81 = load i32, i32* @rng.state
  %t82 = shl i32 %t81, 13
  %t83 = xor i32 %t81, %t82
  %t84 = lshr i32 %t83, 17
  %t85 = xor i32 %t83, %t84
  %t86 = shl i32 %t85, 5
  %t87 = xor i32 %t85, %t86
  store i32 %t87, i32* @rng.state
  %t88 = and i32 %t87, 16777215
  %t89 = uitofp i32 %t88 to float
  %t90 = fdiv float %t89, 0x4170000000000000
  store float %t90, float* %t80
  %t91 = alloca float
  %t92 = load i32, i32* @rng.state
  %t93 = shl i32 %t92, 13
  %t94 = xor i32 %t92, %t93
  %t95 = lshr i32 %t94, 17
  %t96 = xor i32 %t94, %t95
  %t97 = shl i32 %t96, 5
  %t98 = xor i32 %t96, %t97
  store i32 %t98, i32* @rng.state
  %t99 = and i32 %t98, 16777215
  %t100 = uitofp i32 %t99 to float
  %t101 = fdiv float %t100, 0x4170000000000000
  store float %t101, float* %t91
  %t102 = load float, float* %t80
  %t103 = fcmp oge float %t102, 0x0000000000000000
  br i1 %t103, label %logic_rhs_0, label %logic_short_1
logic_rhs_0:
  %t104 = load float, float* %t80
  %t105 = fcmp olt float %t104, 0x3FF0000000000000
  br label %logic_end_2
logic_short_1:
  br label %logic_end_2
logic_end_2:
  %t106 = phi i1 [ %t105, %logic_rhs_0 ], [ false, %logic_short_1 ]
  %t107 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.6, i64 0, i64 0
  %t108 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.7, i64 0, i64 0
  %t109 = select i1 %t106, i8* %t107, i8* %t108
  %t110 = load float, float* %t91
  %t111 = fcmp oge float %t110, 0x0000000000000000
  br i1 %t111, label %logic_rhs_3, label %logic_short_4
logic_rhs_3:
  %t112 = load float, float* %t91
  %t113 = fcmp olt float %t112, 0x3FF0000000000000
  br label %logic_end_5
logic_short_4:
  br label %logic_end_5
logic_end_5:
  %t114 = phi i1 [ %t113, %logic_rhs_3 ], [ false, %logic_short_4 ]
  %t115 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.8, i64 0, i64 0
  %t116 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.9, i64 0, i64 0
  %t117 = select i1 %t114, i8* %t115, i8* %t116
  %t118 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t118, i8* %t109, i8* %t117)
  %t119 = alloca i32
  %t120 = sub i32 20, 10
  %t121 = icmp sle i32 %t120, 0
  %t122 = select i1 %t121, i32 1, i32 %t120
  %t123 = load i32, i32* @rng.state
  %t124 = shl i32 %t123, 13
  %t125 = xor i32 %t123, %t124
  %t126 = lshr i32 %t125, 17
  %t127 = xor i32 %t125, %t126
  %t128 = shl i32 %t127, 5
  %t129 = xor i32 %t127, %t128
  store i32 %t129, i32* @rng.state
  %t130 = and i32 %t129, 2147483647
  %t131 = urem i32 %t130, %t122
  %t132 = add i32 10, %t131
  store i32 %t132, i32* %t119
  %t133 = load i32, i32* %t119
  %t134 = icmp sge i32 %t133, 10
  br i1 %t134, label %logic_rhs_6, label %logic_short_7
logic_rhs_6:
  %t135 = load i32, i32* %t119
  %t136 = icmp slt i32 %t135, 20
  br label %logic_end_8
logic_short_7:
  br label %logic_end_8
logic_end_8:
  %t137 = phi i1 [ %t136, %logic_rhs_6 ], [ false, %logic_short_7 ]
  %t138 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.11, i64 0, i64 0
  %t139 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.12, i64 0, i64 0
  %t140 = select i1 %t137, i8* %t138, i8* %t139
  %t141 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t141, i8* %t140)
  %t142 = icmp eq i32 42, 0
  %t143 = select i1 %t142, i32 1, i32 42
  store i32 %t143, i32* @rng.state
  %t144 = alloca float
  %t145 = load i32, i32* @rng.state
  %t146 = shl i32 %t145, 13
  %t147 = xor i32 %t145, %t146
  %t148 = lshr i32 %t147, 17
  %t149 = xor i32 %t147, %t148
  %t150 = shl i32 %t149, 5
  %t151 = xor i32 %t149, %t150
  store i32 %t151, i32* @rng.state
  %t152 = and i32 %t151, 16777215
  %t153 = uitofp i32 %t152 to float
  %t154 = fdiv float %t153, 0x4170000000000000
  store float %t154, float* %t144
  %t155 = load float, float* %t80
  %t156 = load float, float* %t144
  %t157 = fcmp oeq float %t155, %t156
  %t158 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.14, i64 0, i64 0
  %t159 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.15, i64 0, i64 0
  %t160 = select i1 %t157, i8* %t158, i8* %t159
  %t161 = getelementptr inbounds [44 x i8], [44 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t161, i8* %t160)
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
