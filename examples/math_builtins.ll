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

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca <3 x float>
  %t6 = alloca <3 x float>
  %t20 = alloca <3 x float>
  %t39 = alloca <3 x float>
  %t83 = alloca float
  %t95 = alloca float
  %t124 = alloca i32
  %t151 = alloca float
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = insertelement <3 x float> undef, float 0x3FF0000000000000, i32 0
  %t4 = insertelement <3 x float> %t3, float 0x0000000000000000, i32 1
  %t5 = insertelement <3 x float> %t4, float 0x0000000000000000, i32 2
  store <3 x float> %t5, <3 x float>* %t2
  %t7 = insertelement <3 x float> undef, float 0x0000000000000000, i32 0
  %t8 = insertelement <3 x float> %t7, float 0x3FF0000000000000, i32 1
  %t9 = insertelement <3 x float> %t8, float 0x0000000000000000, i32 2
  store <3 x float> %t9, <3 x float>* %t6
  %t10 = load <3 x float>, <3 x float>* %t2
  %t11 = load <3 x float>, <3 x float>* %t6
  %t12 = fmul <3 x float> %t10, %t11
  %t13 = extractelement <3 x float> %t12, i32 0
  %t14 = extractelement <3 x float> %t12, i32 1
  %t15 = fadd float %t13, %t14
  %t16 = extractelement <3 x float> %t12, i32 2
  %t17 = fadd float %t15, %t16
  %t18 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.0, i64 0, i64 0
  %t19 = fpext float %t17 to double
  call i32 (i8*, ...) @printf(i8* %t18, double %t19)
  %t21 = insertelement <3 x float> undef, float 0x4008000000000000, i32 0
  %t22 = insertelement <3 x float> %t21, float 0x4010000000000000, i32 1
  %t23 = insertelement <3 x float> %t22, float 0x0000000000000000, i32 2
  store <3 x float> %t23, <3 x float>* %t20
  %t24 = load <3 x float>, <3 x float>* %t20
  %t25 = fmul <3 x float> %t24, %t24
  %t26 = extractelement <3 x float> %t25, i32 0
  %t27 = extractelement <3 x float> %t25, i32 1
  %t28 = fadd float %t26, %t27
  %t29 = extractelement <3 x float> %t25, i32 2
  %t30 = fadd float %t28, %t29
  %t31 = call float @llvm.sqrt.f32(float %t30)
  %t32 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.1, i64 0, i64 0
  %t33 = fpext float %t31 to double
  call i32 (i8*, ...) @printf(i8* %t32, double %t33)
  %t34 = fsub float 0x4024000000000000, 0x0000000000000000
  %t35 = fmul float %t34, 0x3FE0000000000000
  %t36 = fadd float 0x0000000000000000, %t35
  %t37 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.2, i64 0, i64 0
  %t38 = fpext float %t36 to double
  call i32 (i8*, ...) @printf(i8* %t37, double %t38)
  %t40 = load <3 x float>, <3 x float>* %t2
  %t41 = load <3 x float>, <3 x float>* %t20
  %t42 = extractelement <3 x float> %t40, i32 0
  %t43 = extractelement <3 x float> %t41, i32 0
  %t44 = fsub float %t43, %t42
  %t45 = fmul float %t44, 0x3FE0000000000000
  %t46 = fadd float %t42, %t45
  %t47 = insertelement <3 x float> undef, float %t46, i32 0
  %t48 = extractelement <3 x float> %t40, i32 1
  %t49 = extractelement <3 x float> %t41, i32 1
  %t50 = fsub float %t49, %t48
  %t51 = fmul float %t50, 0x3FE0000000000000
  %t52 = fadd float %t48, %t51
  %t53 = insertelement <3 x float> %t47, float %t52, i32 1
  %t54 = extractelement <3 x float> %t40, i32 2
  %t55 = extractelement <3 x float> %t41, i32 2
  %t56 = fsub float %t55, %t54
  %t57 = fmul float %t56, 0x3FE0000000000000
  %t58 = fadd float %t54, %t57
  %t59 = insertelement <3 x float> %t53, float %t58, i32 2
  store <3 x float> %t59, <3 x float>* %t39
  %t60 = load <3 x float>, <3 x float>* %t39
  %t61 = extractelement <3 x float> %t60, i32 0
  %t62 = load <3 x float>, <3 x float>* %t39
  %t63 = extractelement <3 x float> %t62, i32 1
  %t64 = load <3 x float>, <3 x float>* %t39
  %t65 = extractelement <3 x float> %t64, i32 2
  %t66 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.3, i64 0, i64 0
  %t67 = fpext float %t61 to double
  %t68 = fpext float %t63 to double
  %t69 = fpext float %t65 to double
  call i32 (i8*, ...) @printf(i8* %t66, double %t67, double %t68, double %t69)
  %t70 = icmp sgt i32 0, 15
  %t71 = select i1 %t70, i32 0, i32 15
  %t72 = icmp slt i32 10, %t71
  %t73 = select i1 %t72, i32 10, i32 %t71
  %t74 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t74, i32 %t73)
  %t75 = fsub float 0.0, 0x4004000000000000
  %t76 = call float @llvm.maxnum.f32(float %t75, float 0x0000000000000000)
  %t77 = call float @llvm.minnum.f32(float %t76, float 0x4024000000000000)
  %t78 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.5, i64 0, i64 0
  %t79 = fpext float %t77 to double
  call i32 (i8*, ...) @printf(i8* %t78, double %t79)
  %t80 = icmp eq i32 42, 0
  %t81 = select i1 %t80, i32 1, i32 42
  %t82 = load i8*, i8** @rng.lock
  call i32 @WaitForSingleObject(i8* %t82, i32 -1)
  store i32 %t81, i32* @rng.state
  call i32 @ReleaseSemaphore(i8* %t82, i32 1, i32* null)
  %t84 = load i8*, i8** @rng.lock
  call i32 @WaitForSingleObject(i8* %t84, i32 -1)
  %t85 = load i32, i32* @rng.state
  %t86 = shl i32 %t85, 13
  %t87 = xor i32 %t85, %t86
  %t88 = lshr i32 %t87, 17
  %t89 = xor i32 %t87, %t88
  %t90 = shl i32 %t89, 5
  %t91 = xor i32 %t89, %t90
  store i32 %t91, i32* @rng.state
  call i32 @ReleaseSemaphore(i8* %t84, i32 1, i32* null)
  %t92 = and i32 %t91, 16777215
  %t93 = uitofp i32 %t92 to float
  %t94 = fdiv float %t93, 0x4170000000000000
  store float %t94, float* %t83
  %t96 = load i8*, i8** @rng.lock
  call i32 @WaitForSingleObject(i8* %t96, i32 -1)
  %t97 = load i32, i32* @rng.state
  %t98 = shl i32 %t97, 13
  %t99 = xor i32 %t97, %t98
  %t100 = lshr i32 %t99, 17
  %t101 = xor i32 %t99, %t100
  %t102 = shl i32 %t101, 5
  %t103 = xor i32 %t101, %t102
  store i32 %t103, i32* @rng.state
  call i32 @ReleaseSemaphore(i8* %t96, i32 1, i32* null)
  %t104 = and i32 %t103, 16777215
  %t105 = uitofp i32 %t104 to float
  %t106 = fdiv float %t105, 0x4170000000000000
  store float %t106, float* %t95
  %t107 = load float, float* %t83
  %t108 = fcmp oge float %t107, 0x0000000000000000
  br i1 %t108, label %logic_rhs_0, label %logic_short_1
logic_rhs_0:
  %t109 = load float, float* %t83
  %t110 = fcmp olt float %t109, 0x3FF0000000000000
  br label %logic_end_2
logic_short_1:
  br label %logic_end_2
logic_end_2:
  %t111 = phi i1 [ %t110, %logic_rhs_0 ], [ false, %logic_short_1 ]
  %t112 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.6, i64 0, i64 0
  %t113 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.7, i64 0, i64 0
  %t114 = select i1 %t111, i8* %t112, i8* %t113
  %t115 = load float, float* %t95
  %t116 = fcmp oge float %t115, 0x0000000000000000
  br i1 %t116, label %logic_rhs_3, label %logic_short_4
logic_rhs_3:
  %t117 = load float, float* %t95
  %t118 = fcmp olt float %t117, 0x3FF0000000000000
  br label %logic_end_5
logic_short_4:
  br label %logic_end_5
logic_end_5:
  %t119 = phi i1 [ %t118, %logic_rhs_3 ], [ false, %logic_short_4 ]
  %t120 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.8, i64 0, i64 0
  %t121 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.9, i64 0, i64 0
  %t122 = select i1 %t119, i8* %t120, i8* %t121
  %t123 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t123, i8* %t114, i8* %t122)
  %t125 = sub i32 20, 10
  %t126 = icmp sle i32 %t125, 0
  %t127 = select i1 %t126, i32 1, i32 %t125
  %t128 = load i8*, i8** @rng.lock
  call i32 @WaitForSingleObject(i8* %t128, i32 -1)
  %t129 = load i32, i32* @rng.state
  %t130 = shl i32 %t129, 13
  %t131 = xor i32 %t129, %t130
  %t132 = lshr i32 %t131, 17
  %t133 = xor i32 %t131, %t132
  %t134 = shl i32 %t133, 5
  %t135 = xor i32 %t133, %t134
  store i32 %t135, i32* @rng.state
  call i32 @ReleaseSemaphore(i8* %t128, i32 1, i32* null)
  %t136 = and i32 %t135, 2147483647
  %t137 = urem i32 %t136, %t127
  %t138 = add i32 10, %t137
  store i32 %t138, i32* %t124
  %t139 = load i32, i32* %t124
  %t140 = icmp sge i32 %t139, 10
  br i1 %t140, label %logic_rhs_6, label %logic_short_7
logic_rhs_6:
  %t141 = load i32, i32* %t124
  %t142 = icmp slt i32 %t141, 20
  br label %logic_end_8
logic_short_7:
  br label %logic_end_8
logic_end_8:
  %t143 = phi i1 [ %t142, %logic_rhs_6 ], [ false, %logic_short_7 ]
  %t144 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.11, i64 0, i64 0
  %t145 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.12, i64 0, i64 0
  %t146 = select i1 %t143, i8* %t144, i8* %t145
  %t147 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t147, i8* %t146)
  %t148 = icmp eq i32 42, 0
  %t149 = select i1 %t148, i32 1, i32 42
  %t150 = load i8*, i8** @rng.lock
  call i32 @WaitForSingleObject(i8* %t150, i32 -1)
  store i32 %t149, i32* @rng.state
  call i32 @ReleaseSemaphore(i8* %t150, i32 1, i32* null)
  %t152 = load i8*, i8** @rng.lock
  call i32 @WaitForSingleObject(i8* %t152, i32 -1)
  %t153 = load i32, i32* @rng.state
  %t154 = shl i32 %t153, 13
  %t155 = xor i32 %t153, %t154
  %t156 = lshr i32 %t155, 17
  %t157 = xor i32 %t155, %t156
  %t158 = shl i32 %t157, 5
  %t159 = xor i32 %t157, %t158
  store i32 %t159, i32* @rng.state
  call i32 @ReleaseSemaphore(i8* %t152, i32 1, i32* null)
  %t160 = and i32 %t159, 16777215
  %t161 = uitofp i32 %t160 to float
  %t162 = fdiv float %t161, 0x4170000000000000
  store float %t162, float* %t151
  %t163 = load float, float* %t83
  %t164 = load float, float* %t151
  %t165 = fcmp oeq float %t163, %t164
  %t166 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.14, i64 0, i64 0
  %t167 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.15, i64 0, i64 0
  %t168 = select i1 %t165, i8* %t166, i8* %t167
  %t169 = getelementptr inbounds [44 x i8], [44 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t169, i8* %t168)
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
