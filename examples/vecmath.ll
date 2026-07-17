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
  %t9 = alloca <3 x float>
  %t23 = alloca <3 x float>
  %t39 = alloca <4 x float>
  %t44 = alloca <4 x float>
  %t49 = alloca <4 x float>
  %t66 = alloca <3 x float>
  %t79 = alloca [4 x <4 x float>]
  %t100 = alloca <4 x float>
  %t156 = alloca <4 x float>
  %t170 = alloca <2 x float>
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t2 = insertelement <3 x float> undef, float 0x3FF0000000000000, i32 0
  %t3 = insertelement <3 x float> %t2, float 0x4000000000000000, i32 1
  %t4 = insertelement <3 x float> %t3, float 0x4008000000000000, i32 2
  store <3 x float> %t4, <3 x float>* %t1
  %t6 = insertelement <3 x float> undef, float 0x4024000000000000, i32 0
  %t7 = insertelement <3 x float> %t6, float 0x4034000000000000, i32 1
  %t8 = insertelement <3 x float> %t7, float 0x403E000000000000, i32 2
  store <3 x float> %t8, <3 x float>* %t5
  %t10 = load <3 x float>, <3 x float>* %t1
  %t11 = load <3 x float>, <3 x float>* %t5
  %t12 = fadd <3 x float> %t10, %t11
  store <3 x float> %t12, <3 x float>* %t9
  %t13 = load <3 x float>, <3 x float>* %t9
  %t14 = extractelement <3 x float> %t13, i32 0
  %t15 = load <3 x float>, <3 x float>* %t9
  %t16 = extractelement <3 x float> %t15, i32 1
  %t17 = load <3 x float>, <3 x float>* %t9
  %t18 = extractelement <3 x float> %t17, i32 2
  %t19 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.0, i64 0, i64 0
  %t20 = fpext float %t14 to double
  %t21 = fpext float %t16 to double
  %t22 = fpext float %t18 to double
  call i32 (i8*, ...) @printf(i8* %t19, double %t20, double %t21, double %t22)
  %t24 = load <3 x float>, <3 x float>* %t1
  %t25 = insertelement <3 x float> undef, float 0x4000000000000000, i32 0
  %t26 = insertelement <3 x float> %t25, float 0x4000000000000000, i32 1
  %t27 = insertelement <3 x float> %t26, float 0x4000000000000000, i32 2
  %t28 = fmul <3 x float> %t24, %t27
  store <3 x float> %t28, <3 x float>* %t23
  %t29 = load <3 x float>, <3 x float>* %t23
  %t30 = extractelement <3 x float> %t29, i32 0
  %t31 = load <3 x float>, <3 x float>* %t23
  %t32 = extractelement <3 x float> %t31, i32 1
  %t33 = load <3 x float>, <3 x float>* %t23
  %t34 = extractelement <3 x float> %t33, i32 2
  %t35 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.1, i64 0, i64 0
  %t36 = fpext float %t30 to double
  %t37 = fpext float %t32 to double
  %t38 = fpext float %t34 to double
  call i32 (i8*, ...) @printf(i8* %t35, double %t36, double %t37, double %t38)
  %t40 = insertelement <4 x float> undef, float 0x3FF0000000000000, i32 0
  %t41 = insertelement <4 x float> %t40, float 0x0000000000000000, i32 1
  %t42 = insertelement <4 x float> %t41, float 0x0000000000000000, i32 2
  %t43 = insertelement <4 x float> %t42, float 0x0000000000000000, i32 3
  store <4 x float> %t43, <4 x float>* %t39
  %t45 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t46 = insertelement <4 x float> %t45, float 0x3FF0000000000000, i32 1
  %t47 = insertelement <4 x float> %t46, float 0x0000000000000000, i32 2
  %t48 = insertelement <4 x float> %t47, float 0x0000000000000000, i32 3
  store <4 x float> %t48, <4 x float>* %t44
  %t50 = load <4 x float>, <4 x float>* %t39
  %t51 = load <4 x float>, <4 x float>* %t44
  %t52 = fadd <4 x float> %t50, %t51
  store <4 x float> %t52, <4 x float>* %t49
  %t53 = load <4 x float>, <4 x float>* %t49
  %t54 = extractelement <4 x float> %t53, i32 0
  %t55 = load <4 x float>, <4 x float>* %t49
  %t56 = extractelement <4 x float> %t55, i32 1
  %t57 = load <4 x float>, <4 x float>* %t49
  %t58 = extractelement <4 x float> %t57, i32 2
  %t59 = load <4 x float>, <4 x float>* %t49
  %t60 = extractelement <4 x float> %t59, i32 3
  %t61 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.2, i64 0, i64 0
  %t62 = fpext float %t54 to double
  %t63 = fpext float %t56 to double
  %t64 = fpext float %t58 to double
  %t65 = fpext float %t60 to double
  call i32 (i8*, ...) @printf(i8* %t61, double %t62, double %t63, double %t64, double %t65)
  %t67 = load <3 x float>, <3 x float>* %t9
  %t68 = shufflevector <3 x float> %t67, <3 x float> undef, <3 x i32> <i32 2, i32 1, i32 0>
  store <3 x float> %t68, <3 x float>* %t66
  %t69 = load <3 x float>, <3 x float>* %t66
  %t70 = extractelement <3 x float> %t69, i32 0
  %t71 = load <3 x float>, <3 x float>* %t66
  %t72 = extractelement <3 x float> %t71, i32 1
  %t73 = load <3 x float>, <3 x float>* %t66
  %t74 = extractelement <3 x float> %t73, i32 2
  %t75 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.3, i64 0, i64 0
  %t76 = fpext float %t70 to double
  %t77 = fpext float %t72 to double
  %t78 = fpext float %t74 to double
  call i32 (i8*, ...) @printf(i8* %t75, double %t76, double %t77, double %t78)
  %t80 = insertelement <4 x float> undef, float 0x3FF0000000000000, i32 0
  %t81 = insertelement <4 x float> %t80, float 0x0000000000000000, i32 1
  %t82 = insertelement <4 x float> %t81, float 0x0000000000000000, i32 2
  %t83 = insertelement <4 x float> %t82, float 0x0000000000000000, i32 3
  %t84 = insertvalue [4 x <4 x float>] undef, <4 x float> %t83, 0
  %t85 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t86 = insertelement <4 x float> %t85, float 0x3FF0000000000000, i32 1
  %t87 = insertelement <4 x float> %t86, float 0x0000000000000000, i32 2
  %t88 = insertelement <4 x float> %t87, float 0x0000000000000000, i32 3
  %t89 = insertvalue [4 x <4 x float>] %t84, <4 x float> %t88, 1
  %t90 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t91 = insertelement <4 x float> %t90, float 0x0000000000000000, i32 1
  %t92 = insertelement <4 x float> %t91, float 0x3FF0000000000000, i32 2
  %t93 = insertelement <4 x float> %t92, float 0x0000000000000000, i32 3
  %t94 = insertvalue [4 x <4 x float>] %t89, <4 x float> %t93, 2
  %t95 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t96 = insertelement <4 x float> %t95, float 0x0000000000000000, i32 1
  %t97 = insertelement <4 x float> %t96, float 0x0000000000000000, i32 2
  %t98 = insertelement <4 x float> %t97, float 0x3FF0000000000000, i32 3
  %t99 = insertvalue [4 x <4 x float>] %t94, <4 x float> %t98, 3
  store [4 x <4 x float>] %t99, [4 x <4 x float>]* %t79
  %t101 = load [4 x <4 x float>], [4 x <4 x float>]* %t79
  %t102 = load <4 x float>, <4 x float>* %t39
  %t103 = extractvalue [4 x <4 x float>] %t101, 0
  %t104 = fmul <4 x float> %t103, %t102
  %t105 = extractelement <4 x float> %t104, i32 0
  %t106 = extractelement <4 x float> %t104, i32 1
  %t107 = fadd float %t105, %t106
  %t108 = extractelement <4 x float> %t104, i32 2
  %t109 = fadd float %t107, %t108
  %t110 = extractelement <4 x float> %t104, i32 3
  %t111 = fadd float %t109, %t110
  %t112 = extractvalue [4 x <4 x float>] %t101, 1
  %t113 = fmul <4 x float> %t112, %t102
  %t114 = extractelement <4 x float> %t113, i32 0
  %t115 = extractelement <4 x float> %t113, i32 1
  %t116 = fadd float %t114, %t115
  %t117 = extractelement <4 x float> %t113, i32 2
  %t118 = fadd float %t116, %t117
  %t119 = extractelement <4 x float> %t113, i32 3
  %t120 = fadd float %t118, %t119
  %t121 = extractvalue [4 x <4 x float>] %t101, 2
  %t122 = fmul <4 x float> %t121, %t102
  %t123 = extractelement <4 x float> %t122, i32 0
  %t124 = extractelement <4 x float> %t122, i32 1
  %t125 = fadd float %t123, %t124
  %t126 = extractelement <4 x float> %t122, i32 2
  %t127 = fadd float %t125, %t126
  %t128 = extractelement <4 x float> %t122, i32 3
  %t129 = fadd float %t127, %t128
  %t130 = extractvalue [4 x <4 x float>] %t101, 3
  %t131 = fmul <4 x float> %t130, %t102
  %t132 = extractelement <4 x float> %t131, i32 0
  %t133 = extractelement <4 x float> %t131, i32 1
  %t134 = fadd float %t132, %t133
  %t135 = extractelement <4 x float> %t131, i32 2
  %t136 = fadd float %t134, %t135
  %t137 = extractelement <4 x float> %t131, i32 3
  %t138 = fadd float %t136, %t137
  %t139 = insertelement <4 x float> undef, float %t111, i32 0
  %t140 = insertelement <4 x float> %t139, float %t120, i32 1
  %t141 = insertelement <4 x float> %t140, float %t129, i32 2
  %t142 = insertelement <4 x float> %t141, float %t138, i32 3
  store <4 x float> %t142, <4 x float>* %t100
  %t143 = load <4 x float>, <4 x float>* %t100
  %t144 = extractelement <4 x float> %t143, i32 0
  %t145 = load <4 x float>, <4 x float>* %t100
  %t146 = extractelement <4 x float> %t145, i32 1
  %t147 = load <4 x float>, <4 x float>* %t100
  %t148 = extractelement <4 x float> %t147, i32 2
  %t149 = load <4 x float>, <4 x float>* %t100
  %t150 = extractelement <4 x float> %t149, i32 3
  %t151 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.4, i64 0, i64 0
  %t152 = fpext float %t144 to double
  %t153 = fpext float %t146 to double
  %t154 = fpext float %t148 to double
  %t155 = fpext float %t150 to double
  call i32 (i8*, ...) @printf(i8* %t151, double %t152, double %t153, double %t154, double %t155)
  %t157 = insertelement <4 x float> undef, float 0x3FF0000000000000, i32 0
  %t158 = insertelement <4 x float> %t157, float 0x3FF0000000000000, i32 1
  %t159 = insertelement <4 x float> %t158, float 0x3FF0000000000000, i32 2
  %t160 = insertelement <4 x float> %t159, float 0x3FF0000000000000, i32 3
  store <4 x float> %t160, <4 x float>* %t156
  %t161 = load <4 x float>, <4 x float>* %t156
  %t162 = insertelement <4 x float> %t161, float 0x4058C00000000000, i32 0
  store <4 x float> %t162, <4 x float>* %t156
  %t163 = load <4 x float>, <4 x float>* %t156
  %t164 = extractelement <4 x float> %t163, i32 0
  %t165 = load <4 x float>, <4 x float>* %t156
  %t166 = extractelement <4 x float> %t165, i32 1
  %t167 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.5, i64 0, i64 0
  %t168 = fpext float %t164 to double
  %t169 = fpext float %t166 to double
  call i32 (i8*, ...) @printf(i8* %t167, double %t168, double %t169)
  %t171 = insertelement <2 x float> undef, float 0x3FF0000000000000, i32 0
  %t172 = insertelement <2 x float> %t171, float 0x3FF0000000000000, i32 1
  store <2 x float> %t172, <2 x float>* %t170
  %t173 = insertelement <2 x float> undef, float 0x4014000000000000, i32 0
  %t174 = insertelement <2 x float> %t173, float 0x4018000000000000, i32 1
  %t175 = load <2 x float>, <2 x float>* %t170
  %t176 = extractelement <2 x float> %t174, i32 0
  %t177 = insertelement <2 x float> %t175, float %t176, i32 0
  %t178 = extractelement <2 x float> %t174, i32 1
  %t179 = insertelement <2 x float> %t177, float %t178, i32 1
  store <2 x float> %t179, <2 x float>* %t170
  %t180 = load <2 x float>, <2 x float>* %t170
  %t181 = extractelement <2 x float> %t180, i32 0
  %t182 = load <2 x float>, <2 x float>* %t170
  %t183 = extractelement <2 x float> %t182, i32 1
  %t184 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.6, i64 0, i64 0
  %t185 = fpext float %t181 to double
  %t186 = fpext float %t183 to double
  call i32 (i8*, ...) @printf(i8* %t184, double %t185, double %t186)
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
