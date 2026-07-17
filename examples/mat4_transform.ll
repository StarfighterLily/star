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
  %t25 = alloca [4 x <4 x float>]
  %t46 = alloca <4 x float>
  %t51 = alloca <4 x float>
  %t107 = alloca [4 x <4 x float>]
  %t298 = alloca <4 x float>
  %t354 = alloca <3 x float>
  %t358 = alloca <3 x float>
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t2 = insertelement <3 x float> undef, float 0x0000000000000000, i32 0
  %t3 = insertelement <3 x float> %t2, float 0x0000000000000000, i32 1
  %t4 = insertelement <3 x float> %t3, float 0x0000000000000000, i32 2
  store <3 x float> %t4, <3 x float>* %t1
  %t5 = load <3 x float>, <3 x float>* %t1
  %t6 = fmul <3 x float> %t5, %t5
  %t7 = extractelement <3 x float> %t6, i32 0
  %t8 = extractelement <3 x float> %t6, i32 1
  %t9 = fadd float %t7, %t8
  %t10 = extractelement <3 x float> %t6, i32 2
  %t11 = fadd float %t9, %t10
  %t12 = call float @llvm.sqrt.f32(float %t11)
  %t13 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.0, i64 0, i64 0
  %t14 = fpext float %t12 to double
  call i32 (i8*, ...) @printf(i8* %t13, double %t14)
  %t15 = load <3 x float>, <3 x float>* %t1
  %t16 = load <3 x float>, <3 x float>* %t1
  %t17 = fmul <3 x float> %t15, %t16
  %t18 = extractelement <3 x float> %t17, i32 0
  %t19 = extractelement <3 x float> %t17, i32 1
  %t20 = fadd float %t18, %t19
  %t21 = extractelement <3 x float> %t17, i32 2
  %t22 = fadd float %t20, %t21
  %t23 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.1, i64 0, i64 0
  %t24 = fpext float %t22 to double
  call i32 (i8*, ...) @printf(i8* %t23, double %t24)
  %t26 = insertelement <4 x float> undef, float 0x4000000000000000, i32 0
  %t27 = insertelement <4 x float> %t26, float 0x0000000000000000, i32 1
  %t28 = insertelement <4 x float> %t27, float 0x0000000000000000, i32 2
  %t29 = insertelement <4 x float> %t28, float 0x4024000000000000, i32 3
  %t30 = insertvalue [4 x <4 x float>] undef, <4 x float> %t29, 0
  %t31 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t32 = insertelement <4 x float> %t31, float 0x4008000000000000, i32 1
  %t33 = insertelement <4 x float> %t32, float 0x0000000000000000, i32 2
  %t34 = insertelement <4 x float> %t33, float 0x4034000000000000, i32 3
  %t35 = insertvalue [4 x <4 x float>] %t30, <4 x float> %t34, 1
  %t36 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t37 = insertelement <4 x float> %t36, float 0x0000000000000000, i32 1
  %t38 = insertelement <4 x float> %t37, float 0x4010000000000000, i32 2
  %t39 = insertelement <4 x float> %t38, float 0x403E000000000000, i32 3
  %t40 = insertvalue [4 x <4 x float>] %t35, <4 x float> %t39, 2
  %t41 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t42 = insertelement <4 x float> %t41, float 0x0000000000000000, i32 1
  %t43 = insertelement <4 x float> %t42, float 0x0000000000000000, i32 2
  %t44 = insertelement <4 x float> %t43, float 0x3FF0000000000000, i32 3
  %t45 = insertvalue [4 x <4 x float>] %t40, <4 x float> %t44, 3
  store [4 x <4 x float>] %t45, [4 x <4 x float>]* %t25
  %t47 = insertelement <4 x float> undef, float 0x3FF0000000000000, i32 0
  %t48 = insertelement <4 x float> %t47, float 0x3FF0000000000000, i32 1
  %t49 = insertelement <4 x float> %t48, float 0x3FF0000000000000, i32 2
  %t50 = insertelement <4 x float> %t49, float 0x3FF0000000000000, i32 3
  store <4 x float> %t50, <4 x float>* %t46
  %t52 = load [4 x <4 x float>], [4 x <4 x float>]* %t25
  %t53 = load <4 x float>, <4 x float>* %t46
  %t54 = extractvalue [4 x <4 x float>] %t52, 0
  %t55 = fmul <4 x float> %t54, %t53
  %t56 = extractelement <4 x float> %t55, i32 0
  %t57 = extractelement <4 x float> %t55, i32 1
  %t58 = fadd float %t56, %t57
  %t59 = extractelement <4 x float> %t55, i32 2
  %t60 = fadd float %t58, %t59
  %t61 = extractelement <4 x float> %t55, i32 3
  %t62 = fadd float %t60, %t61
  %t63 = extractvalue [4 x <4 x float>] %t52, 1
  %t64 = fmul <4 x float> %t63, %t53
  %t65 = extractelement <4 x float> %t64, i32 0
  %t66 = extractelement <4 x float> %t64, i32 1
  %t67 = fadd float %t65, %t66
  %t68 = extractelement <4 x float> %t64, i32 2
  %t69 = fadd float %t67, %t68
  %t70 = extractelement <4 x float> %t64, i32 3
  %t71 = fadd float %t69, %t70
  %t72 = extractvalue [4 x <4 x float>] %t52, 2
  %t73 = fmul <4 x float> %t72, %t53
  %t74 = extractelement <4 x float> %t73, i32 0
  %t75 = extractelement <4 x float> %t73, i32 1
  %t76 = fadd float %t74, %t75
  %t77 = extractelement <4 x float> %t73, i32 2
  %t78 = fadd float %t76, %t77
  %t79 = extractelement <4 x float> %t73, i32 3
  %t80 = fadd float %t78, %t79
  %t81 = extractvalue [4 x <4 x float>] %t52, 3
  %t82 = fmul <4 x float> %t81, %t53
  %t83 = extractelement <4 x float> %t82, i32 0
  %t84 = extractelement <4 x float> %t82, i32 1
  %t85 = fadd float %t83, %t84
  %t86 = extractelement <4 x float> %t82, i32 2
  %t87 = fadd float %t85, %t86
  %t88 = extractelement <4 x float> %t82, i32 3
  %t89 = fadd float %t87, %t88
  %t90 = insertelement <4 x float> undef, float %t62, i32 0
  %t91 = insertelement <4 x float> %t90, float %t71, i32 1
  %t92 = insertelement <4 x float> %t91, float %t80, i32 2
  %t93 = insertelement <4 x float> %t92, float %t89, i32 3
  store <4 x float> %t93, <4 x float>* %t51
  %t94 = load <4 x float>, <4 x float>* %t51
  %t95 = extractelement <4 x float> %t94, i32 0
  %t96 = load <4 x float>, <4 x float>* %t51
  %t97 = extractelement <4 x float> %t96, i32 1
  %t98 = load <4 x float>, <4 x float>* %t51
  %t99 = extractelement <4 x float> %t98, i32 2
  %t100 = load <4 x float>, <4 x float>* %t51
  %t101 = extractelement <4 x float> %t100, i32 3
  %t102 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.2, i64 0, i64 0
  %t103 = fpext float %t95 to double
  %t104 = fpext float %t97 to double
  %t105 = fpext float %t99 to double
  %t106 = fpext float %t101 to double
  call i32 (i8*, ...) @printf(i8* %t102, double %t103, double %t104, double %t105, double %t106)
  %t108 = load [4 x <4 x float>], [4 x <4 x float>]* %t25
  %t109 = load [4 x <4 x float>], [4 x <4 x float>]* %t25
  %t110 = extractvalue [4 x <4 x float>] %t108, 0
  %t111 = extractvalue [4 x <4 x float>] %t109, 0
  %t112 = extractvalue [4 x <4 x float>] %t108, 1
  %t113 = extractvalue [4 x <4 x float>] %t109, 1
  %t114 = extractvalue [4 x <4 x float>] %t108, 2
  %t115 = extractvalue [4 x <4 x float>] %t109, 2
  %t116 = extractvalue [4 x <4 x float>] %t108, 3
  %t117 = extractvalue [4 x <4 x float>] %t109, 3
  %t118 = extractelement <4 x float> %t111, i32 0
  %t119 = insertelement <4 x float> undef, float %t118, i32 0
  %t120 = extractelement <4 x float> %t113, i32 0
  %t121 = insertelement <4 x float> %t119, float %t120, i32 1
  %t122 = extractelement <4 x float> %t115, i32 0
  %t123 = insertelement <4 x float> %t121, float %t122, i32 2
  %t124 = extractelement <4 x float> %t117, i32 0
  %t125 = insertelement <4 x float> %t123, float %t124, i32 3
  %t126 = extractelement <4 x float> %t111, i32 1
  %t127 = insertelement <4 x float> undef, float %t126, i32 0
  %t128 = extractelement <4 x float> %t113, i32 1
  %t129 = insertelement <4 x float> %t127, float %t128, i32 1
  %t130 = extractelement <4 x float> %t115, i32 1
  %t131 = insertelement <4 x float> %t129, float %t130, i32 2
  %t132 = extractelement <4 x float> %t117, i32 1
  %t133 = insertelement <4 x float> %t131, float %t132, i32 3
  %t134 = extractelement <4 x float> %t111, i32 2
  %t135 = insertelement <4 x float> undef, float %t134, i32 0
  %t136 = extractelement <4 x float> %t113, i32 2
  %t137 = insertelement <4 x float> %t135, float %t136, i32 1
  %t138 = extractelement <4 x float> %t115, i32 2
  %t139 = insertelement <4 x float> %t137, float %t138, i32 2
  %t140 = extractelement <4 x float> %t117, i32 2
  %t141 = insertelement <4 x float> %t139, float %t140, i32 3
  %t142 = extractelement <4 x float> %t111, i32 3
  %t143 = insertelement <4 x float> undef, float %t142, i32 0
  %t144 = extractelement <4 x float> %t113, i32 3
  %t145 = insertelement <4 x float> %t143, float %t144, i32 1
  %t146 = extractelement <4 x float> %t115, i32 3
  %t147 = insertelement <4 x float> %t145, float %t146, i32 2
  %t148 = extractelement <4 x float> %t117, i32 3
  %t149 = insertelement <4 x float> %t147, float %t148, i32 3
  %t150 = fmul <4 x float> %t110, %t125
  %t151 = extractelement <4 x float> %t150, i32 0
  %t152 = extractelement <4 x float> %t150, i32 1
  %t153 = fadd float %t151, %t152
  %t154 = extractelement <4 x float> %t150, i32 2
  %t155 = fadd float %t153, %t154
  %t156 = extractelement <4 x float> %t150, i32 3
  %t157 = fadd float %t155, %t156
  %t158 = insertelement <4 x float> undef, float %t157, i32 0
  %t159 = fmul <4 x float> %t110, %t133
  %t160 = extractelement <4 x float> %t159, i32 0
  %t161 = extractelement <4 x float> %t159, i32 1
  %t162 = fadd float %t160, %t161
  %t163 = extractelement <4 x float> %t159, i32 2
  %t164 = fadd float %t162, %t163
  %t165 = extractelement <4 x float> %t159, i32 3
  %t166 = fadd float %t164, %t165
  %t167 = insertelement <4 x float> %t158, float %t166, i32 1
  %t168 = fmul <4 x float> %t110, %t141
  %t169 = extractelement <4 x float> %t168, i32 0
  %t170 = extractelement <4 x float> %t168, i32 1
  %t171 = fadd float %t169, %t170
  %t172 = extractelement <4 x float> %t168, i32 2
  %t173 = fadd float %t171, %t172
  %t174 = extractelement <4 x float> %t168, i32 3
  %t175 = fadd float %t173, %t174
  %t176 = insertelement <4 x float> %t167, float %t175, i32 2
  %t177 = fmul <4 x float> %t110, %t149
  %t178 = extractelement <4 x float> %t177, i32 0
  %t179 = extractelement <4 x float> %t177, i32 1
  %t180 = fadd float %t178, %t179
  %t181 = extractelement <4 x float> %t177, i32 2
  %t182 = fadd float %t180, %t181
  %t183 = extractelement <4 x float> %t177, i32 3
  %t184 = fadd float %t182, %t183
  %t185 = insertelement <4 x float> %t176, float %t184, i32 3
  %t186 = insertvalue [4 x <4 x float>] undef, <4 x float> %t185, 0
  %t187 = fmul <4 x float> %t112, %t125
  %t188 = extractelement <4 x float> %t187, i32 0
  %t189 = extractelement <4 x float> %t187, i32 1
  %t190 = fadd float %t188, %t189
  %t191 = extractelement <4 x float> %t187, i32 2
  %t192 = fadd float %t190, %t191
  %t193 = extractelement <4 x float> %t187, i32 3
  %t194 = fadd float %t192, %t193
  %t195 = insertelement <4 x float> undef, float %t194, i32 0
  %t196 = fmul <4 x float> %t112, %t133
  %t197 = extractelement <4 x float> %t196, i32 0
  %t198 = extractelement <4 x float> %t196, i32 1
  %t199 = fadd float %t197, %t198
  %t200 = extractelement <4 x float> %t196, i32 2
  %t201 = fadd float %t199, %t200
  %t202 = extractelement <4 x float> %t196, i32 3
  %t203 = fadd float %t201, %t202
  %t204 = insertelement <4 x float> %t195, float %t203, i32 1
  %t205 = fmul <4 x float> %t112, %t141
  %t206 = extractelement <4 x float> %t205, i32 0
  %t207 = extractelement <4 x float> %t205, i32 1
  %t208 = fadd float %t206, %t207
  %t209 = extractelement <4 x float> %t205, i32 2
  %t210 = fadd float %t208, %t209
  %t211 = extractelement <4 x float> %t205, i32 3
  %t212 = fadd float %t210, %t211
  %t213 = insertelement <4 x float> %t204, float %t212, i32 2
  %t214 = fmul <4 x float> %t112, %t149
  %t215 = extractelement <4 x float> %t214, i32 0
  %t216 = extractelement <4 x float> %t214, i32 1
  %t217 = fadd float %t215, %t216
  %t218 = extractelement <4 x float> %t214, i32 2
  %t219 = fadd float %t217, %t218
  %t220 = extractelement <4 x float> %t214, i32 3
  %t221 = fadd float %t219, %t220
  %t222 = insertelement <4 x float> %t213, float %t221, i32 3
  %t223 = insertvalue [4 x <4 x float>] %t186, <4 x float> %t222, 1
  %t224 = fmul <4 x float> %t114, %t125
  %t225 = extractelement <4 x float> %t224, i32 0
  %t226 = extractelement <4 x float> %t224, i32 1
  %t227 = fadd float %t225, %t226
  %t228 = extractelement <4 x float> %t224, i32 2
  %t229 = fadd float %t227, %t228
  %t230 = extractelement <4 x float> %t224, i32 3
  %t231 = fadd float %t229, %t230
  %t232 = insertelement <4 x float> undef, float %t231, i32 0
  %t233 = fmul <4 x float> %t114, %t133
  %t234 = extractelement <4 x float> %t233, i32 0
  %t235 = extractelement <4 x float> %t233, i32 1
  %t236 = fadd float %t234, %t235
  %t237 = extractelement <4 x float> %t233, i32 2
  %t238 = fadd float %t236, %t237
  %t239 = extractelement <4 x float> %t233, i32 3
  %t240 = fadd float %t238, %t239
  %t241 = insertelement <4 x float> %t232, float %t240, i32 1
  %t242 = fmul <4 x float> %t114, %t141
  %t243 = extractelement <4 x float> %t242, i32 0
  %t244 = extractelement <4 x float> %t242, i32 1
  %t245 = fadd float %t243, %t244
  %t246 = extractelement <4 x float> %t242, i32 2
  %t247 = fadd float %t245, %t246
  %t248 = extractelement <4 x float> %t242, i32 3
  %t249 = fadd float %t247, %t248
  %t250 = insertelement <4 x float> %t241, float %t249, i32 2
  %t251 = fmul <4 x float> %t114, %t149
  %t252 = extractelement <4 x float> %t251, i32 0
  %t253 = extractelement <4 x float> %t251, i32 1
  %t254 = fadd float %t252, %t253
  %t255 = extractelement <4 x float> %t251, i32 2
  %t256 = fadd float %t254, %t255
  %t257 = extractelement <4 x float> %t251, i32 3
  %t258 = fadd float %t256, %t257
  %t259 = insertelement <4 x float> %t250, float %t258, i32 3
  %t260 = insertvalue [4 x <4 x float>] %t223, <4 x float> %t259, 2
  %t261 = fmul <4 x float> %t116, %t125
  %t262 = extractelement <4 x float> %t261, i32 0
  %t263 = extractelement <4 x float> %t261, i32 1
  %t264 = fadd float %t262, %t263
  %t265 = extractelement <4 x float> %t261, i32 2
  %t266 = fadd float %t264, %t265
  %t267 = extractelement <4 x float> %t261, i32 3
  %t268 = fadd float %t266, %t267
  %t269 = insertelement <4 x float> undef, float %t268, i32 0
  %t270 = fmul <4 x float> %t116, %t133
  %t271 = extractelement <4 x float> %t270, i32 0
  %t272 = extractelement <4 x float> %t270, i32 1
  %t273 = fadd float %t271, %t272
  %t274 = extractelement <4 x float> %t270, i32 2
  %t275 = fadd float %t273, %t274
  %t276 = extractelement <4 x float> %t270, i32 3
  %t277 = fadd float %t275, %t276
  %t278 = insertelement <4 x float> %t269, float %t277, i32 1
  %t279 = fmul <4 x float> %t116, %t141
  %t280 = extractelement <4 x float> %t279, i32 0
  %t281 = extractelement <4 x float> %t279, i32 1
  %t282 = fadd float %t280, %t281
  %t283 = extractelement <4 x float> %t279, i32 2
  %t284 = fadd float %t282, %t283
  %t285 = extractelement <4 x float> %t279, i32 3
  %t286 = fadd float %t284, %t285
  %t287 = insertelement <4 x float> %t278, float %t286, i32 2
  %t288 = fmul <4 x float> %t116, %t149
  %t289 = extractelement <4 x float> %t288, i32 0
  %t290 = extractelement <4 x float> %t288, i32 1
  %t291 = fadd float %t289, %t290
  %t292 = extractelement <4 x float> %t288, i32 2
  %t293 = fadd float %t291, %t292
  %t294 = extractelement <4 x float> %t288, i32 3
  %t295 = fadd float %t293, %t294
  %t296 = insertelement <4 x float> %t287, float %t295, i32 3
  %t297 = insertvalue [4 x <4 x float>] %t260, <4 x float> %t296, 3
  store [4 x <4 x float>] %t297, [4 x <4 x float>]* %t107
  %t299 = load [4 x <4 x float>], [4 x <4 x float>]* %t107
  %t300 = load <4 x float>, <4 x float>* %t46
  %t301 = extractvalue [4 x <4 x float>] %t299, 0
  %t302 = fmul <4 x float> %t301, %t300
  %t303 = extractelement <4 x float> %t302, i32 0
  %t304 = extractelement <4 x float> %t302, i32 1
  %t305 = fadd float %t303, %t304
  %t306 = extractelement <4 x float> %t302, i32 2
  %t307 = fadd float %t305, %t306
  %t308 = extractelement <4 x float> %t302, i32 3
  %t309 = fadd float %t307, %t308
  %t310 = extractvalue [4 x <4 x float>] %t299, 1
  %t311 = fmul <4 x float> %t310, %t300
  %t312 = extractelement <4 x float> %t311, i32 0
  %t313 = extractelement <4 x float> %t311, i32 1
  %t314 = fadd float %t312, %t313
  %t315 = extractelement <4 x float> %t311, i32 2
  %t316 = fadd float %t314, %t315
  %t317 = extractelement <4 x float> %t311, i32 3
  %t318 = fadd float %t316, %t317
  %t319 = extractvalue [4 x <4 x float>] %t299, 2
  %t320 = fmul <4 x float> %t319, %t300
  %t321 = extractelement <4 x float> %t320, i32 0
  %t322 = extractelement <4 x float> %t320, i32 1
  %t323 = fadd float %t321, %t322
  %t324 = extractelement <4 x float> %t320, i32 2
  %t325 = fadd float %t323, %t324
  %t326 = extractelement <4 x float> %t320, i32 3
  %t327 = fadd float %t325, %t326
  %t328 = extractvalue [4 x <4 x float>] %t299, 3
  %t329 = fmul <4 x float> %t328, %t300
  %t330 = extractelement <4 x float> %t329, i32 0
  %t331 = extractelement <4 x float> %t329, i32 1
  %t332 = fadd float %t330, %t331
  %t333 = extractelement <4 x float> %t329, i32 2
  %t334 = fadd float %t332, %t333
  %t335 = extractelement <4 x float> %t329, i32 3
  %t336 = fadd float %t334, %t335
  %t337 = insertelement <4 x float> undef, float %t309, i32 0
  %t338 = insertelement <4 x float> %t337, float %t318, i32 1
  %t339 = insertelement <4 x float> %t338, float %t327, i32 2
  %t340 = insertelement <4 x float> %t339, float %t336, i32 3
  store <4 x float> %t340, <4 x float>* %t298
  %t341 = load <4 x float>, <4 x float>* %t298
  %t342 = extractelement <4 x float> %t341, i32 0
  %t343 = load <4 x float>, <4 x float>* %t298
  %t344 = extractelement <4 x float> %t343, i32 1
  %t345 = load <4 x float>, <4 x float>* %t298
  %t346 = extractelement <4 x float> %t345, i32 2
  %t347 = load <4 x float>, <4 x float>* %t298
  %t348 = extractelement <4 x float> %t347, i32 3
  %t349 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.3, i64 0, i64 0
  %t350 = fpext float %t342 to double
  %t351 = fpext float %t344 to double
  %t352 = fpext float %t346 to double
  %t353 = fpext float %t348 to double
  call i32 (i8*, ...) @printf(i8* %t349, double %t350, double %t351, double %t352, double %t353)
  %t355 = insertelement <3 x float> undef, float 0x3FF0000000000000, i32 0
  %t356 = insertelement <3 x float> %t355, float 0x4000000000000000, i32 1
  %t357 = insertelement <3 x float> %t356, float 0x4008000000000000, i32 2
  store <3 x float> %t357, <3 x float>* %t354
  %t359 = insertelement <3 x float> undef, float 0x4010000000000000, i32 0
  %t360 = insertelement <3 x float> %t359, float 0x4014000000000000, i32 1
  %t361 = insertelement <3 x float> %t360, float 0x4018000000000000, i32 2
  store <3 x float> %t361, <3 x float>* %t358
  %t362 = load <3 x float>, <3 x float>* %t354
  %t363 = load <3 x float>, <3 x float>* %t358
  %t364 = fmul <3 x float> %t362, %t363
  %t365 = extractelement <3 x float> %t364, i32 0
  %t366 = extractelement <3 x float> %t364, i32 1
  %t367 = fadd float %t365, %t366
  %t368 = extractelement <3 x float> %t364, i32 2
  %t369 = fadd float %t367, %t368
  %t370 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.4, i64 0, i64 0
  %t371 = fpext float %t369 to double
  call i32 (i8*, ...) @printf(i8* %t370, double %t371)
  %t372 = insertelement <2 x float> undef, float 0x4008000000000000, i32 0
  %t373 = insertelement <2 x float> %t372, float 0x4010000000000000, i32 1
  %t374 = fmul <2 x float> %t373, %t373
  %t375 = extractelement <2 x float> %t374, i32 0
  %t376 = extractelement <2 x float> %t374, i32 1
  %t377 = fadd float %t375, %t376
  %t378 = call float @llvm.sqrt.f32(float %t377)
  %t379 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.5, i64 0, i64 0
  %t380 = fpext float %t378 to double
  call i32 (i8*, ...) @printf(i8* %t379, double %t380)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [17 x i8] c"zero length: %f\0A\00"
@.str.1 = private unnamed_addr constant [14 x i8] c"zero dot: %f\0A\00"
@.str.2 = private unnamed_addr constant [19 x i8] c"m*v = %f %f %f %f\0A\00"
@.str.3 = private unnamed_addr constant [20 x i8] c"m2*v = %f %f %f %f\0A\00"
@.str.4 = private unnamed_addr constant [15 x i8] c"dot(a,b) = %f\0A\00"
@.str.5 = private unnamed_addr constant [18 x i8] c"length(3,4) = %f\0A\00"
