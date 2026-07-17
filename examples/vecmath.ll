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
  %t10 = alloca <3 x float>
  %t24 = alloca <3 x float>
  %t40 = alloca <4 x float>
  %t45 = alloca <4 x float>
  %t50 = alloca <4 x float>
  %t67 = alloca <3 x float>
  %t80 = alloca [4 x <4 x float>]
  %t101 = alloca <4 x float>
  %t157 = alloca <4 x float>
  %t171 = alloca <2 x float>
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = insertelement <3 x float> undef, float 0x3FF0000000000000, i32 0
  %t4 = insertelement <3 x float> %t3, float 0x4000000000000000, i32 1
  %t5 = insertelement <3 x float> %t4, float 0x4008000000000000, i32 2
  store <3 x float> %t5, <3 x float>* %t2
  %t7 = insertelement <3 x float> undef, float 0x4024000000000000, i32 0
  %t8 = insertelement <3 x float> %t7, float 0x4034000000000000, i32 1
  %t9 = insertelement <3 x float> %t8, float 0x403E000000000000, i32 2
  store <3 x float> %t9, <3 x float>* %t6
  %t11 = load <3 x float>, <3 x float>* %t2
  %t12 = load <3 x float>, <3 x float>* %t6
  %t13 = fadd <3 x float> %t11, %t12
  store <3 x float> %t13, <3 x float>* %t10
  %t14 = load <3 x float>, <3 x float>* %t10
  %t15 = extractelement <3 x float> %t14, i32 0
  %t16 = load <3 x float>, <3 x float>* %t10
  %t17 = extractelement <3 x float> %t16, i32 1
  %t18 = load <3 x float>, <3 x float>* %t10
  %t19 = extractelement <3 x float> %t18, i32 2
  %t20 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.0, i64 0, i64 0
  %t21 = fpext float %t15 to double
  %t22 = fpext float %t17 to double
  %t23 = fpext float %t19 to double
  call i32 (i8*, ...) @printf(i8* %t20, double %t21, double %t22, double %t23)
  %t25 = load <3 x float>, <3 x float>* %t2
  %t26 = insertelement <3 x float> undef, float 0x4000000000000000, i32 0
  %t27 = insertelement <3 x float> %t26, float 0x4000000000000000, i32 1
  %t28 = insertelement <3 x float> %t27, float 0x4000000000000000, i32 2
  %t29 = fmul <3 x float> %t25, %t28
  store <3 x float> %t29, <3 x float>* %t24
  %t30 = load <3 x float>, <3 x float>* %t24
  %t31 = extractelement <3 x float> %t30, i32 0
  %t32 = load <3 x float>, <3 x float>* %t24
  %t33 = extractelement <3 x float> %t32, i32 1
  %t34 = load <3 x float>, <3 x float>* %t24
  %t35 = extractelement <3 x float> %t34, i32 2
  %t36 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.1, i64 0, i64 0
  %t37 = fpext float %t31 to double
  %t38 = fpext float %t33 to double
  %t39 = fpext float %t35 to double
  call i32 (i8*, ...) @printf(i8* %t36, double %t37, double %t38, double %t39)
  %t41 = insertelement <4 x float> undef, float 0x3FF0000000000000, i32 0
  %t42 = insertelement <4 x float> %t41, float 0x0000000000000000, i32 1
  %t43 = insertelement <4 x float> %t42, float 0x0000000000000000, i32 2
  %t44 = insertelement <4 x float> %t43, float 0x0000000000000000, i32 3
  store <4 x float> %t44, <4 x float>* %t40
  %t46 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t47 = insertelement <4 x float> %t46, float 0x3FF0000000000000, i32 1
  %t48 = insertelement <4 x float> %t47, float 0x0000000000000000, i32 2
  %t49 = insertelement <4 x float> %t48, float 0x0000000000000000, i32 3
  store <4 x float> %t49, <4 x float>* %t45
  %t51 = load <4 x float>, <4 x float>* %t40
  %t52 = load <4 x float>, <4 x float>* %t45
  %t53 = fadd <4 x float> %t51, %t52
  store <4 x float> %t53, <4 x float>* %t50
  %t54 = load <4 x float>, <4 x float>* %t50
  %t55 = extractelement <4 x float> %t54, i32 0
  %t56 = load <4 x float>, <4 x float>* %t50
  %t57 = extractelement <4 x float> %t56, i32 1
  %t58 = load <4 x float>, <4 x float>* %t50
  %t59 = extractelement <4 x float> %t58, i32 2
  %t60 = load <4 x float>, <4 x float>* %t50
  %t61 = extractelement <4 x float> %t60, i32 3
  %t62 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.2, i64 0, i64 0
  %t63 = fpext float %t55 to double
  %t64 = fpext float %t57 to double
  %t65 = fpext float %t59 to double
  %t66 = fpext float %t61 to double
  call i32 (i8*, ...) @printf(i8* %t62, double %t63, double %t64, double %t65, double %t66)
  %t68 = load <3 x float>, <3 x float>* %t10
  %t69 = shufflevector <3 x float> %t68, <3 x float> undef, <3 x i32> <i32 2, i32 1, i32 0>
  store <3 x float> %t69, <3 x float>* %t67
  %t70 = load <3 x float>, <3 x float>* %t67
  %t71 = extractelement <3 x float> %t70, i32 0
  %t72 = load <3 x float>, <3 x float>* %t67
  %t73 = extractelement <3 x float> %t72, i32 1
  %t74 = load <3 x float>, <3 x float>* %t67
  %t75 = extractelement <3 x float> %t74, i32 2
  %t76 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.3, i64 0, i64 0
  %t77 = fpext float %t71 to double
  %t78 = fpext float %t73 to double
  %t79 = fpext float %t75 to double
  call i32 (i8*, ...) @printf(i8* %t76, double %t77, double %t78, double %t79)
  %t81 = insertelement <4 x float> undef, float 0x3FF0000000000000, i32 0
  %t82 = insertelement <4 x float> %t81, float 0x0000000000000000, i32 1
  %t83 = insertelement <4 x float> %t82, float 0x0000000000000000, i32 2
  %t84 = insertelement <4 x float> %t83, float 0x0000000000000000, i32 3
  %t85 = insertvalue [4 x <4 x float>] undef, <4 x float> %t84, 0
  %t86 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t87 = insertelement <4 x float> %t86, float 0x3FF0000000000000, i32 1
  %t88 = insertelement <4 x float> %t87, float 0x0000000000000000, i32 2
  %t89 = insertelement <4 x float> %t88, float 0x0000000000000000, i32 3
  %t90 = insertvalue [4 x <4 x float>] %t85, <4 x float> %t89, 1
  %t91 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t92 = insertelement <4 x float> %t91, float 0x0000000000000000, i32 1
  %t93 = insertelement <4 x float> %t92, float 0x3FF0000000000000, i32 2
  %t94 = insertelement <4 x float> %t93, float 0x0000000000000000, i32 3
  %t95 = insertvalue [4 x <4 x float>] %t90, <4 x float> %t94, 2
  %t96 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t97 = insertelement <4 x float> %t96, float 0x0000000000000000, i32 1
  %t98 = insertelement <4 x float> %t97, float 0x0000000000000000, i32 2
  %t99 = insertelement <4 x float> %t98, float 0x3FF0000000000000, i32 3
  %t100 = insertvalue [4 x <4 x float>] %t95, <4 x float> %t99, 3
  store [4 x <4 x float>] %t100, [4 x <4 x float>]* %t80
  %t102 = load [4 x <4 x float>], [4 x <4 x float>]* %t80
  %t103 = load <4 x float>, <4 x float>* %t40
  %t104 = extractvalue [4 x <4 x float>] %t102, 0
  %t105 = fmul <4 x float> %t104, %t103
  %t106 = extractelement <4 x float> %t105, i32 0
  %t107 = extractelement <4 x float> %t105, i32 1
  %t108 = fadd float %t106, %t107
  %t109 = extractelement <4 x float> %t105, i32 2
  %t110 = fadd float %t108, %t109
  %t111 = extractelement <4 x float> %t105, i32 3
  %t112 = fadd float %t110, %t111
  %t113 = extractvalue [4 x <4 x float>] %t102, 1
  %t114 = fmul <4 x float> %t113, %t103
  %t115 = extractelement <4 x float> %t114, i32 0
  %t116 = extractelement <4 x float> %t114, i32 1
  %t117 = fadd float %t115, %t116
  %t118 = extractelement <4 x float> %t114, i32 2
  %t119 = fadd float %t117, %t118
  %t120 = extractelement <4 x float> %t114, i32 3
  %t121 = fadd float %t119, %t120
  %t122 = extractvalue [4 x <4 x float>] %t102, 2
  %t123 = fmul <4 x float> %t122, %t103
  %t124 = extractelement <4 x float> %t123, i32 0
  %t125 = extractelement <4 x float> %t123, i32 1
  %t126 = fadd float %t124, %t125
  %t127 = extractelement <4 x float> %t123, i32 2
  %t128 = fadd float %t126, %t127
  %t129 = extractelement <4 x float> %t123, i32 3
  %t130 = fadd float %t128, %t129
  %t131 = extractvalue [4 x <4 x float>] %t102, 3
  %t132 = fmul <4 x float> %t131, %t103
  %t133 = extractelement <4 x float> %t132, i32 0
  %t134 = extractelement <4 x float> %t132, i32 1
  %t135 = fadd float %t133, %t134
  %t136 = extractelement <4 x float> %t132, i32 2
  %t137 = fadd float %t135, %t136
  %t138 = extractelement <4 x float> %t132, i32 3
  %t139 = fadd float %t137, %t138
  %t140 = insertelement <4 x float> undef, float %t112, i32 0
  %t141 = insertelement <4 x float> %t140, float %t121, i32 1
  %t142 = insertelement <4 x float> %t141, float %t130, i32 2
  %t143 = insertelement <4 x float> %t142, float %t139, i32 3
  store <4 x float> %t143, <4 x float>* %t101
  %t144 = load <4 x float>, <4 x float>* %t101
  %t145 = extractelement <4 x float> %t144, i32 0
  %t146 = load <4 x float>, <4 x float>* %t101
  %t147 = extractelement <4 x float> %t146, i32 1
  %t148 = load <4 x float>, <4 x float>* %t101
  %t149 = extractelement <4 x float> %t148, i32 2
  %t150 = load <4 x float>, <4 x float>* %t101
  %t151 = extractelement <4 x float> %t150, i32 3
  %t152 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.4, i64 0, i64 0
  %t153 = fpext float %t145 to double
  %t154 = fpext float %t147 to double
  %t155 = fpext float %t149 to double
  %t156 = fpext float %t151 to double
  call i32 (i8*, ...) @printf(i8* %t152, double %t153, double %t154, double %t155, double %t156)
  %t158 = insertelement <4 x float> undef, float 0x3FF0000000000000, i32 0
  %t159 = insertelement <4 x float> %t158, float 0x3FF0000000000000, i32 1
  %t160 = insertelement <4 x float> %t159, float 0x3FF0000000000000, i32 2
  %t161 = insertelement <4 x float> %t160, float 0x3FF0000000000000, i32 3
  store <4 x float> %t161, <4 x float>* %t157
  %t162 = load <4 x float>, <4 x float>* %t157
  %t163 = insertelement <4 x float> %t162, float 0x4058C00000000000, i32 0
  store <4 x float> %t163, <4 x float>* %t157
  %t164 = load <4 x float>, <4 x float>* %t157
  %t165 = extractelement <4 x float> %t164, i32 0
  %t166 = load <4 x float>, <4 x float>* %t157
  %t167 = extractelement <4 x float> %t166, i32 1
  %t168 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.5, i64 0, i64 0
  %t169 = fpext float %t165 to double
  %t170 = fpext float %t167 to double
  call i32 (i8*, ...) @printf(i8* %t168, double %t169, double %t170)
  %t172 = insertelement <2 x float> undef, float 0x3FF0000000000000, i32 0
  %t173 = insertelement <2 x float> %t172, float 0x3FF0000000000000, i32 1
  store <2 x float> %t173, <2 x float>* %t171
  %t174 = insertelement <2 x float> undef, float 0x4014000000000000, i32 0
  %t175 = insertelement <2 x float> %t174, float 0x4018000000000000, i32 1
  %t176 = load <2 x float>, <2 x float>* %t171
  %t177 = extractelement <2 x float> %t175, i32 0
  %t178 = insertelement <2 x float> %t176, float %t177, i32 0
  %t179 = extractelement <2 x float> %t175, i32 1
  %t180 = insertelement <2 x float> %t178, float %t179, i32 1
  store <2 x float> %t180, <2 x float>* %t171
  %t181 = load <2 x float>, <2 x float>* %t171
  %t182 = extractelement <2 x float> %t181, i32 0
  %t183 = load <2 x float>, <2 x float>* %t171
  %t184 = extractelement <2 x float> %t183, i32 1
  %t185 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.6, i64 0, i64 0
  %t186 = fpext float %t182 to double
  %t187 = fpext float %t184 to double
  call i32 (i8*, ...) @printf(i8* %t185, double %t186, double %t187)
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
