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

%GenRef = type { i32, i32 }

@frame.buf = global [4096 x i8] zeroinitializer
@frame.off = global i64 0

@star.argc = global i32 0
@star.argv = global i8** null

@rng.state = global i32 123456789

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
  %t1 = alloca <3 x float>
  %t5 = alloca <3 x float>
  %t19 = alloca <3 x float>
  %t38 = alloca <3 x float>
  %t81 = alloca float
  %t92 = alloca float
  %t120 = alloca i32
  %t145 = alloca float
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t2 = insertelement <3 x float> undef, float 0x3FF0000000000000, i32 0
  %t3 = insertelement <3 x float> %t2, float 0x0000000000000000, i32 1
  %t4 = insertelement <3 x float> %t3, float 0x0000000000000000, i32 2
  store <3 x float> %t4, <3 x float>* %t1
  %t6 = insertelement <3 x float> undef, float 0x0000000000000000, i32 0
  %t7 = insertelement <3 x float> %t6, float 0x3FF0000000000000, i32 1
  %t8 = insertelement <3 x float> %t7, float 0x0000000000000000, i32 2
  store <3 x float> %t8, <3 x float>* %t5
  %t9 = load <3 x float>, <3 x float>* %t1
  %t10 = load <3 x float>, <3 x float>* %t5
  %t11 = fmul <3 x float> %t9, %t10
  %t12 = extractelement <3 x float> %t11, i32 0
  %t13 = extractelement <3 x float> %t11, i32 1
  %t14 = fadd float %t12, %t13
  %t15 = extractelement <3 x float> %t11, i32 2
  %t16 = fadd float %t14, %t15
  %t17 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.0, i64 0, i64 0
  %t18 = fpext float %t16 to double
  call i32 (i8*, ...) @printf(i8* %t17, double %t18)
  %t20 = insertelement <3 x float> undef, float 0x4008000000000000, i32 0
  %t21 = insertelement <3 x float> %t20, float 0x4010000000000000, i32 1
  %t22 = insertelement <3 x float> %t21, float 0x0000000000000000, i32 2
  store <3 x float> %t22, <3 x float>* %t19
  %t23 = load <3 x float>, <3 x float>* %t19
  %t24 = fmul <3 x float> %t23, %t23
  %t25 = extractelement <3 x float> %t24, i32 0
  %t26 = extractelement <3 x float> %t24, i32 1
  %t27 = fadd float %t25, %t26
  %t28 = extractelement <3 x float> %t24, i32 2
  %t29 = fadd float %t27, %t28
  %t30 = call float @llvm.sqrt.f32(float %t29)
  %t31 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.1, i64 0, i64 0
  %t32 = fpext float %t30 to double
  call i32 (i8*, ...) @printf(i8* %t31, double %t32)
  %t33 = fsub float 0x4024000000000000, 0x0000000000000000
  %t34 = fmul float %t33, 0x3FE0000000000000
  %t35 = fadd float 0x0000000000000000, %t34
  %t36 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.2, i64 0, i64 0
  %t37 = fpext float %t35 to double
  call i32 (i8*, ...) @printf(i8* %t36, double %t37)
  %t39 = load <3 x float>, <3 x float>* %t1
  %t40 = load <3 x float>, <3 x float>* %t19
  %t41 = extractelement <3 x float> %t39, i32 0
  %t42 = extractelement <3 x float> %t40, i32 0
  %t43 = fsub float %t42, %t41
  %t44 = fmul float %t43, 0x3FE0000000000000
  %t45 = fadd float %t41, %t44
  %t46 = insertelement <3 x float> undef, float %t45, i32 0
  %t47 = extractelement <3 x float> %t39, i32 1
  %t48 = extractelement <3 x float> %t40, i32 1
  %t49 = fsub float %t48, %t47
  %t50 = fmul float %t49, 0x3FE0000000000000
  %t51 = fadd float %t47, %t50
  %t52 = insertelement <3 x float> %t46, float %t51, i32 1
  %t53 = extractelement <3 x float> %t39, i32 2
  %t54 = extractelement <3 x float> %t40, i32 2
  %t55 = fsub float %t54, %t53
  %t56 = fmul float %t55, 0x3FE0000000000000
  %t57 = fadd float %t53, %t56
  %t58 = insertelement <3 x float> %t52, float %t57, i32 2
  store <3 x float> %t58, <3 x float>* %t38
  %t59 = load <3 x float>, <3 x float>* %t38
  %t60 = extractelement <3 x float> %t59, i32 0
  %t61 = load <3 x float>, <3 x float>* %t38
  %t62 = extractelement <3 x float> %t61, i32 1
  %t63 = load <3 x float>, <3 x float>* %t38
  %t64 = extractelement <3 x float> %t63, i32 2
  %t65 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.3, i64 0, i64 0
  %t66 = fpext float %t60 to double
  %t67 = fpext float %t62 to double
  %t68 = fpext float %t64 to double
  call i32 (i8*, ...) @printf(i8* %t65, double %t66, double %t67, double %t68)
  %t69 = icmp sgt i32 0, 15
  %t70 = select i1 %t69, i32 0, i32 15
  %t71 = icmp slt i32 10, %t70
  %t72 = select i1 %t71, i32 10, i32 %t70
  %t73 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t73, i32 %t72)
  %t74 = fsub float 0.0, 0x4004000000000000
  %t75 = call float @llvm.maxnum.f32(float %t74, float 0x0000000000000000)
  %t76 = call float @llvm.minnum.f32(float %t75, float 0x4024000000000000)
  %t77 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.5, i64 0, i64 0
  %t78 = fpext float %t76 to double
  call i32 (i8*, ...) @printf(i8* %t77, double %t78)
  %t79 = icmp eq i32 42, 0
  %t80 = select i1 %t79, i32 1, i32 42
  store i32 %t80, i32* @rng.state
  %t82 = load i32, i32* @rng.state
  %t83 = shl i32 %t82, 13
  %t84 = xor i32 %t82, %t83
  %t85 = lshr i32 %t84, 17
  %t86 = xor i32 %t84, %t85
  %t87 = shl i32 %t86, 5
  %t88 = xor i32 %t86, %t87
  store i32 %t88, i32* @rng.state
  %t89 = and i32 %t88, 16777215
  %t90 = uitofp i32 %t89 to float
  %t91 = fdiv float %t90, 0x4170000000000000
  store float %t91, float* %t81
  %t93 = load i32, i32* @rng.state
  %t94 = shl i32 %t93, 13
  %t95 = xor i32 %t93, %t94
  %t96 = lshr i32 %t95, 17
  %t97 = xor i32 %t95, %t96
  %t98 = shl i32 %t97, 5
  %t99 = xor i32 %t97, %t98
  store i32 %t99, i32* @rng.state
  %t100 = and i32 %t99, 16777215
  %t101 = uitofp i32 %t100 to float
  %t102 = fdiv float %t101, 0x4170000000000000
  store float %t102, float* %t92
  %t103 = load float, float* %t81
  %t104 = fcmp oge float %t103, 0x0000000000000000
  br i1 %t104, label %logic_rhs_0, label %logic_short_1
logic_rhs_0:
  %t105 = load float, float* %t81
  %t106 = fcmp olt float %t105, 0x3FF0000000000000
  br label %logic_end_2
logic_short_1:
  br label %logic_end_2
logic_end_2:
  %t107 = phi i1 [ %t106, %logic_rhs_0 ], [ false, %logic_short_1 ]
  %t108 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.6, i64 0, i64 0
  %t109 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.7, i64 0, i64 0
  %t110 = select i1 %t107, i8* %t108, i8* %t109
  %t111 = load float, float* %t92
  %t112 = fcmp oge float %t111, 0x0000000000000000
  br i1 %t112, label %logic_rhs_3, label %logic_short_4
logic_rhs_3:
  %t113 = load float, float* %t92
  %t114 = fcmp olt float %t113, 0x3FF0000000000000
  br label %logic_end_5
logic_short_4:
  br label %logic_end_5
logic_end_5:
  %t115 = phi i1 [ %t114, %logic_rhs_3 ], [ false, %logic_short_4 ]
  %t116 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.8, i64 0, i64 0
  %t117 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.9, i64 0, i64 0
  %t118 = select i1 %t115, i8* %t116, i8* %t117
  %t119 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t119, i8* %t110, i8* %t118)
  %t121 = sub i32 20, 10
  %t122 = icmp sle i32 %t121, 0
  %t123 = select i1 %t122, i32 1, i32 %t121
  %t124 = load i32, i32* @rng.state
  %t125 = shl i32 %t124, 13
  %t126 = xor i32 %t124, %t125
  %t127 = lshr i32 %t126, 17
  %t128 = xor i32 %t126, %t127
  %t129 = shl i32 %t128, 5
  %t130 = xor i32 %t128, %t129
  store i32 %t130, i32* @rng.state
  %t131 = and i32 %t130, 2147483647
  %t132 = urem i32 %t131, %t123
  %t133 = add i32 10, %t132
  store i32 %t133, i32* %t120
  %t134 = load i32, i32* %t120
  %t135 = icmp sge i32 %t134, 10
  br i1 %t135, label %logic_rhs_6, label %logic_short_7
logic_rhs_6:
  %t136 = load i32, i32* %t120
  %t137 = icmp slt i32 %t136, 20
  br label %logic_end_8
logic_short_7:
  br label %logic_end_8
logic_end_8:
  %t138 = phi i1 [ %t137, %logic_rhs_6 ], [ false, %logic_short_7 ]
  %t139 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.11, i64 0, i64 0
  %t140 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.12, i64 0, i64 0
  %t141 = select i1 %t138, i8* %t139, i8* %t140
  %t142 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t142, i8* %t141)
  %t143 = icmp eq i32 42, 0
  %t144 = select i1 %t143, i32 1, i32 42
  store i32 %t144, i32* @rng.state
  %t146 = load i32, i32* @rng.state
  %t147 = shl i32 %t146, 13
  %t148 = xor i32 %t146, %t147
  %t149 = lshr i32 %t148, 17
  %t150 = xor i32 %t148, %t149
  %t151 = shl i32 %t150, 5
  %t152 = xor i32 %t150, %t151
  store i32 %t152, i32* @rng.state
  %t153 = and i32 %t152, 16777215
  %t154 = uitofp i32 %t153 to float
  %t155 = fdiv float %t154, 0x4170000000000000
  store float %t155, float* %t145
  %t156 = load float, float* %t81
  %t157 = load float, float* %t145
  %t158 = fcmp oeq float %t156, %t157
  %t159 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.14, i64 0, i64 0
  %t160 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.15, i64 0, i64 0
  %t161 = select i1 %t158, i8* %t159, i8* %t160
  %t162 = getelementptr inbounds [44 x i8], [44 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t162, i8* %t161)
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
