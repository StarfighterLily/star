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
  %t26 = alloca [4 x <4 x float>]
  %t47 = alloca <4 x float>
  %t52 = alloca <4 x float>
  %t108 = alloca [4 x <4 x float>]
  %t299 = alloca <4 x float>
  %t355 = alloca <3 x float>
  %t359 = alloca <3 x float>
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = insertelement <3 x float> undef, float 0x0000000000000000, i32 0
  %t4 = insertelement <3 x float> %t3, float 0x0000000000000000, i32 1
  %t5 = insertelement <3 x float> %t4, float 0x0000000000000000, i32 2
  store <3 x float> %t5, <3 x float>* %t2
  %t6 = load <3 x float>, <3 x float>* %t2
  %t7 = fmul <3 x float> %t6, %t6
  %t8 = extractelement <3 x float> %t7, i32 0
  %t9 = extractelement <3 x float> %t7, i32 1
  %t10 = fadd float %t8, %t9
  %t11 = extractelement <3 x float> %t7, i32 2
  %t12 = fadd float %t10, %t11
  %t13 = call float @llvm.sqrt.f32(float %t12)
  %t14 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.0, i64 0, i64 0
  %t15 = fpext float %t13 to double
  call i32 (i8*, ...) @printf(i8* %t14, double %t15)
  %t16 = load <3 x float>, <3 x float>* %t2
  %t17 = load <3 x float>, <3 x float>* %t2
  %t18 = fmul <3 x float> %t16, %t17
  %t19 = extractelement <3 x float> %t18, i32 0
  %t20 = extractelement <3 x float> %t18, i32 1
  %t21 = fadd float %t19, %t20
  %t22 = extractelement <3 x float> %t18, i32 2
  %t23 = fadd float %t21, %t22
  %t24 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.1, i64 0, i64 0
  %t25 = fpext float %t23 to double
  call i32 (i8*, ...) @printf(i8* %t24, double %t25)
  %t27 = insertelement <4 x float> undef, float 0x4000000000000000, i32 0
  %t28 = insertelement <4 x float> %t27, float 0x0000000000000000, i32 1
  %t29 = insertelement <4 x float> %t28, float 0x0000000000000000, i32 2
  %t30 = insertelement <4 x float> %t29, float 0x4024000000000000, i32 3
  %t31 = insertvalue [4 x <4 x float>] undef, <4 x float> %t30, 0
  %t32 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t33 = insertelement <4 x float> %t32, float 0x4008000000000000, i32 1
  %t34 = insertelement <4 x float> %t33, float 0x0000000000000000, i32 2
  %t35 = insertelement <4 x float> %t34, float 0x4034000000000000, i32 3
  %t36 = insertvalue [4 x <4 x float>] %t31, <4 x float> %t35, 1
  %t37 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t38 = insertelement <4 x float> %t37, float 0x0000000000000000, i32 1
  %t39 = insertelement <4 x float> %t38, float 0x4010000000000000, i32 2
  %t40 = insertelement <4 x float> %t39, float 0x403E000000000000, i32 3
  %t41 = insertvalue [4 x <4 x float>] %t36, <4 x float> %t40, 2
  %t42 = insertelement <4 x float> undef, float 0x0000000000000000, i32 0
  %t43 = insertelement <4 x float> %t42, float 0x0000000000000000, i32 1
  %t44 = insertelement <4 x float> %t43, float 0x0000000000000000, i32 2
  %t45 = insertelement <4 x float> %t44, float 0x3FF0000000000000, i32 3
  %t46 = insertvalue [4 x <4 x float>] %t41, <4 x float> %t45, 3
  store [4 x <4 x float>] %t46, [4 x <4 x float>]* %t26
  %t48 = insertelement <4 x float> undef, float 0x3FF0000000000000, i32 0
  %t49 = insertelement <4 x float> %t48, float 0x3FF0000000000000, i32 1
  %t50 = insertelement <4 x float> %t49, float 0x3FF0000000000000, i32 2
  %t51 = insertelement <4 x float> %t50, float 0x3FF0000000000000, i32 3
  store <4 x float> %t51, <4 x float>* %t47
  %t53 = load [4 x <4 x float>], [4 x <4 x float>]* %t26
  %t54 = load <4 x float>, <4 x float>* %t47
  %t55 = extractvalue [4 x <4 x float>] %t53, 0
  %t56 = fmul <4 x float> %t55, %t54
  %t57 = extractelement <4 x float> %t56, i32 0
  %t58 = extractelement <4 x float> %t56, i32 1
  %t59 = fadd float %t57, %t58
  %t60 = extractelement <4 x float> %t56, i32 2
  %t61 = fadd float %t59, %t60
  %t62 = extractelement <4 x float> %t56, i32 3
  %t63 = fadd float %t61, %t62
  %t64 = extractvalue [4 x <4 x float>] %t53, 1
  %t65 = fmul <4 x float> %t64, %t54
  %t66 = extractelement <4 x float> %t65, i32 0
  %t67 = extractelement <4 x float> %t65, i32 1
  %t68 = fadd float %t66, %t67
  %t69 = extractelement <4 x float> %t65, i32 2
  %t70 = fadd float %t68, %t69
  %t71 = extractelement <4 x float> %t65, i32 3
  %t72 = fadd float %t70, %t71
  %t73 = extractvalue [4 x <4 x float>] %t53, 2
  %t74 = fmul <4 x float> %t73, %t54
  %t75 = extractelement <4 x float> %t74, i32 0
  %t76 = extractelement <4 x float> %t74, i32 1
  %t77 = fadd float %t75, %t76
  %t78 = extractelement <4 x float> %t74, i32 2
  %t79 = fadd float %t77, %t78
  %t80 = extractelement <4 x float> %t74, i32 3
  %t81 = fadd float %t79, %t80
  %t82 = extractvalue [4 x <4 x float>] %t53, 3
  %t83 = fmul <4 x float> %t82, %t54
  %t84 = extractelement <4 x float> %t83, i32 0
  %t85 = extractelement <4 x float> %t83, i32 1
  %t86 = fadd float %t84, %t85
  %t87 = extractelement <4 x float> %t83, i32 2
  %t88 = fadd float %t86, %t87
  %t89 = extractelement <4 x float> %t83, i32 3
  %t90 = fadd float %t88, %t89
  %t91 = insertelement <4 x float> undef, float %t63, i32 0
  %t92 = insertelement <4 x float> %t91, float %t72, i32 1
  %t93 = insertelement <4 x float> %t92, float %t81, i32 2
  %t94 = insertelement <4 x float> %t93, float %t90, i32 3
  store <4 x float> %t94, <4 x float>* %t52
  %t95 = load <4 x float>, <4 x float>* %t52
  %t96 = extractelement <4 x float> %t95, i32 0
  %t97 = load <4 x float>, <4 x float>* %t52
  %t98 = extractelement <4 x float> %t97, i32 1
  %t99 = load <4 x float>, <4 x float>* %t52
  %t100 = extractelement <4 x float> %t99, i32 2
  %t101 = load <4 x float>, <4 x float>* %t52
  %t102 = extractelement <4 x float> %t101, i32 3
  %t103 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.2, i64 0, i64 0
  %t104 = fpext float %t96 to double
  %t105 = fpext float %t98 to double
  %t106 = fpext float %t100 to double
  %t107 = fpext float %t102 to double
  call i32 (i8*, ...) @printf(i8* %t103, double %t104, double %t105, double %t106, double %t107)
  %t109 = load [4 x <4 x float>], [4 x <4 x float>]* %t26
  %t110 = load [4 x <4 x float>], [4 x <4 x float>]* %t26
  %t111 = extractvalue [4 x <4 x float>] %t109, 0
  %t112 = extractvalue [4 x <4 x float>] %t110, 0
  %t113 = extractvalue [4 x <4 x float>] %t109, 1
  %t114 = extractvalue [4 x <4 x float>] %t110, 1
  %t115 = extractvalue [4 x <4 x float>] %t109, 2
  %t116 = extractvalue [4 x <4 x float>] %t110, 2
  %t117 = extractvalue [4 x <4 x float>] %t109, 3
  %t118 = extractvalue [4 x <4 x float>] %t110, 3
  %t119 = extractelement <4 x float> %t112, i32 0
  %t120 = insertelement <4 x float> undef, float %t119, i32 0
  %t121 = extractelement <4 x float> %t114, i32 0
  %t122 = insertelement <4 x float> %t120, float %t121, i32 1
  %t123 = extractelement <4 x float> %t116, i32 0
  %t124 = insertelement <4 x float> %t122, float %t123, i32 2
  %t125 = extractelement <4 x float> %t118, i32 0
  %t126 = insertelement <4 x float> %t124, float %t125, i32 3
  %t127 = extractelement <4 x float> %t112, i32 1
  %t128 = insertelement <4 x float> undef, float %t127, i32 0
  %t129 = extractelement <4 x float> %t114, i32 1
  %t130 = insertelement <4 x float> %t128, float %t129, i32 1
  %t131 = extractelement <4 x float> %t116, i32 1
  %t132 = insertelement <4 x float> %t130, float %t131, i32 2
  %t133 = extractelement <4 x float> %t118, i32 1
  %t134 = insertelement <4 x float> %t132, float %t133, i32 3
  %t135 = extractelement <4 x float> %t112, i32 2
  %t136 = insertelement <4 x float> undef, float %t135, i32 0
  %t137 = extractelement <4 x float> %t114, i32 2
  %t138 = insertelement <4 x float> %t136, float %t137, i32 1
  %t139 = extractelement <4 x float> %t116, i32 2
  %t140 = insertelement <4 x float> %t138, float %t139, i32 2
  %t141 = extractelement <4 x float> %t118, i32 2
  %t142 = insertelement <4 x float> %t140, float %t141, i32 3
  %t143 = extractelement <4 x float> %t112, i32 3
  %t144 = insertelement <4 x float> undef, float %t143, i32 0
  %t145 = extractelement <4 x float> %t114, i32 3
  %t146 = insertelement <4 x float> %t144, float %t145, i32 1
  %t147 = extractelement <4 x float> %t116, i32 3
  %t148 = insertelement <4 x float> %t146, float %t147, i32 2
  %t149 = extractelement <4 x float> %t118, i32 3
  %t150 = insertelement <4 x float> %t148, float %t149, i32 3
  %t151 = fmul <4 x float> %t111, %t126
  %t152 = extractelement <4 x float> %t151, i32 0
  %t153 = extractelement <4 x float> %t151, i32 1
  %t154 = fadd float %t152, %t153
  %t155 = extractelement <4 x float> %t151, i32 2
  %t156 = fadd float %t154, %t155
  %t157 = extractelement <4 x float> %t151, i32 3
  %t158 = fadd float %t156, %t157
  %t159 = insertelement <4 x float> undef, float %t158, i32 0
  %t160 = fmul <4 x float> %t111, %t134
  %t161 = extractelement <4 x float> %t160, i32 0
  %t162 = extractelement <4 x float> %t160, i32 1
  %t163 = fadd float %t161, %t162
  %t164 = extractelement <4 x float> %t160, i32 2
  %t165 = fadd float %t163, %t164
  %t166 = extractelement <4 x float> %t160, i32 3
  %t167 = fadd float %t165, %t166
  %t168 = insertelement <4 x float> %t159, float %t167, i32 1
  %t169 = fmul <4 x float> %t111, %t142
  %t170 = extractelement <4 x float> %t169, i32 0
  %t171 = extractelement <4 x float> %t169, i32 1
  %t172 = fadd float %t170, %t171
  %t173 = extractelement <4 x float> %t169, i32 2
  %t174 = fadd float %t172, %t173
  %t175 = extractelement <4 x float> %t169, i32 3
  %t176 = fadd float %t174, %t175
  %t177 = insertelement <4 x float> %t168, float %t176, i32 2
  %t178 = fmul <4 x float> %t111, %t150
  %t179 = extractelement <4 x float> %t178, i32 0
  %t180 = extractelement <4 x float> %t178, i32 1
  %t181 = fadd float %t179, %t180
  %t182 = extractelement <4 x float> %t178, i32 2
  %t183 = fadd float %t181, %t182
  %t184 = extractelement <4 x float> %t178, i32 3
  %t185 = fadd float %t183, %t184
  %t186 = insertelement <4 x float> %t177, float %t185, i32 3
  %t187 = insertvalue [4 x <4 x float>] undef, <4 x float> %t186, 0
  %t188 = fmul <4 x float> %t113, %t126
  %t189 = extractelement <4 x float> %t188, i32 0
  %t190 = extractelement <4 x float> %t188, i32 1
  %t191 = fadd float %t189, %t190
  %t192 = extractelement <4 x float> %t188, i32 2
  %t193 = fadd float %t191, %t192
  %t194 = extractelement <4 x float> %t188, i32 3
  %t195 = fadd float %t193, %t194
  %t196 = insertelement <4 x float> undef, float %t195, i32 0
  %t197 = fmul <4 x float> %t113, %t134
  %t198 = extractelement <4 x float> %t197, i32 0
  %t199 = extractelement <4 x float> %t197, i32 1
  %t200 = fadd float %t198, %t199
  %t201 = extractelement <4 x float> %t197, i32 2
  %t202 = fadd float %t200, %t201
  %t203 = extractelement <4 x float> %t197, i32 3
  %t204 = fadd float %t202, %t203
  %t205 = insertelement <4 x float> %t196, float %t204, i32 1
  %t206 = fmul <4 x float> %t113, %t142
  %t207 = extractelement <4 x float> %t206, i32 0
  %t208 = extractelement <4 x float> %t206, i32 1
  %t209 = fadd float %t207, %t208
  %t210 = extractelement <4 x float> %t206, i32 2
  %t211 = fadd float %t209, %t210
  %t212 = extractelement <4 x float> %t206, i32 3
  %t213 = fadd float %t211, %t212
  %t214 = insertelement <4 x float> %t205, float %t213, i32 2
  %t215 = fmul <4 x float> %t113, %t150
  %t216 = extractelement <4 x float> %t215, i32 0
  %t217 = extractelement <4 x float> %t215, i32 1
  %t218 = fadd float %t216, %t217
  %t219 = extractelement <4 x float> %t215, i32 2
  %t220 = fadd float %t218, %t219
  %t221 = extractelement <4 x float> %t215, i32 3
  %t222 = fadd float %t220, %t221
  %t223 = insertelement <4 x float> %t214, float %t222, i32 3
  %t224 = insertvalue [4 x <4 x float>] %t187, <4 x float> %t223, 1
  %t225 = fmul <4 x float> %t115, %t126
  %t226 = extractelement <4 x float> %t225, i32 0
  %t227 = extractelement <4 x float> %t225, i32 1
  %t228 = fadd float %t226, %t227
  %t229 = extractelement <4 x float> %t225, i32 2
  %t230 = fadd float %t228, %t229
  %t231 = extractelement <4 x float> %t225, i32 3
  %t232 = fadd float %t230, %t231
  %t233 = insertelement <4 x float> undef, float %t232, i32 0
  %t234 = fmul <4 x float> %t115, %t134
  %t235 = extractelement <4 x float> %t234, i32 0
  %t236 = extractelement <4 x float> %t234, i32 1
  %t237 = fadd float %t235, %t236
  %t238 = extractelement <4 x float> %t234, i32 2
  %t239 = fadd float %t237, %t238
  %t240 = extractelement <4 x float> %t234, i32 3
  %t241 = fadd float %t239, %t240
  %t242 = insertelement <4 x float> %t233, float %t241, i32 1
  %t243 = fmul <4 x float> %t115, %t142
  %t244 = extractelement <4 x float> %t243, i32 0
  %t245 = extractelement <4 x float> %t243, i32 1
  %t246 = fadd float %t244, %t245
  %t247 = extractelement <4 x float> %t243, i32 2
  %t248 = fadd float %t246, %t247
  %t249 = extractelement <4 x float> %t243, i32 3
  %t250 = fadd float %t248, %t249
  %t251 = insertelement <4 x float> %t242, float %t250, i32 2
  %t252 = fmul <4 x float> %t115, %t150
  %t253 = extractelement <4 x float> %t252, i32 0
  %t254 = extractelement <4 x float> %t252, i32 1
  %t255 = fadd float %t253, %t254
  %t256 = extractelement <4 x float> %t252, i32 2
  %t257 = fadd float %t255, %t256
  %t258 = extractelement <4 x float> %t252, i32 3
  %t259 = fadd float %t257, %t258
  %t260 = insertelement <4 x float> %t251, float %t259, i32 3
  %t261 = insertvalue [4 x <4 x float>] %t224, <4 x float> %t260, 2
  %t262 = fmul <4 x float> %t117, %t126
  %t263 = extractelement <4 x float> %t262, i32 0
  %t264 = extractelement <4 x float> %t262, i32 1
  %t265 = fadd float %t263, %t264
  %t266 = extractelement <4 x float> %t262, i32 2
  %t267 = fadd float %t265, %t266
  %t268 = extractelement <4 x float> %t262, i32 3
  %t269 = fadd float %t267, %t268
  %t270 = insertelement <4 x float> undef, float %t269, i32 0
  %t271 = fmul <4 x float> %t117, %t134
  %t272 = extractelement <4 x float> %t271, i32 0
  %t273 = extractelement <4 x float> %t271, i32 1
  %t274 = fadd float %t272, %t273
  %t275 = extractelement <4 x float> %t271, i32 2
  %t276 = fadd float %t274, %t275
  %t277 = extractelement <4 x float> %t271, i32 3
  %t278 = fadd float %t276, %t277
  %t279 = insertelement <4 x float> %t270, float %t278, i32 1
  %t280 = fmul <4 x float> %t117, %t142
  %t281 = extractelement <4 x float> %t280, i32 0
  %t282 = extractelement <4 x float> %t280, i32 1
  %t283 = fadd float %t281, %t282
  %t284 = extractelement <4 x float> %t280, i32 2
  %t285 = fadd float %t283, %t284
  %t286 = extractelement <4 x float> %t280, i32 3
  %t287 = fadd float %t285, %t286
  %t288 = insertelement <4 x float> %t279, float %t287, i32 2
  %t289 = fmul <4 x float> %t117, %t150
  %t290 = extractelement <4 x float> %t289, i32 0
  %t291 = extractelement <4 x float> %t289, i32 1
  %t292 = fadd float %t290, %t291
  %t293 = extractelement <4 x float> %t289, i32 2
  %t294 = fadd float %t292, %t293
  %t295 = extractelement <4 x float> %t289, i32 3
  %t296 = fadd float %t294, %t295
  %t297 = insertelement <4 x float> %t288, float %t296, i32 3
  %t298 = insertvalue [4 x <4 x float>] %t261, <4 x float> %t297, 3
  store [4 x <4 x float>] %t298, [4 x <4 x float>]* %t108
  %t300 = load [4 x <4 x float>], [4 x <4 x float>]* %t108
  %t301 = load <4 x float>, <4 x float>* %t47
  %t302 = extractvalue [4 x <4 x float>] %t300, 0
  %t303 = fmul <4 x float> %t302, %t301
  %t304 = extractelement <4 x float> %t303, i32 0
  %t305 = extractelement <4 x float> %t303, i32 1
  %t306 = fadd float %t304, %t305
  %t307 = extractelement <4 x float> %t303, i32 2
  %t308 = fadd float %t306, %t307
  %t309 = extractelement <4 x float> %t303, i32 3
  %t310 = fadd float %t308, %t309
  %t311 = extractvalue [4 x <4 x float>] %t300, 1
  %t312 = fmul <4 x float> %t311, %t301
  %t313 = extractelement <4 x float> %t312, i32 0
  %t314 = extractelement <4 x float> %t312, i32 1
  %t315 = fadd float %t313, %t314
  %t316 = extractelement <4 x float> %t312, i32 2
  %t317 = fadd float %t315, %t316
  %t318 = extractelement <4 x float> %t312, i32 3
  %t319 = fadd float %t317, %t318
  %t320 = extractvalue [4 x <4 x float>] %t300, 2
  %t321 = fmul <4 x float> %t320, %t301
  %t322 = extractelement <4 x float> %t321, i32 0
  %t323 = extractelement <4 x float> %t321, i32 1
  %t324 = fadd float %t322, %t323
  %t325 = extractelement <4 x float> %t321, i32 2
  %t326 = fadd float %t324, %t325
  %t327 = extractelement <4 x float> %t321, i32 3
  %t328 = fadd float %t326, %t327
  %t329 = extractvalue [4 x <4 x float>] %t300, 3
  %t330 = fmul <4 x float> %t329, %t301
  %t331 = extractelement <4 x float> %t330, i32 0
  %t332 = extractelement <4 x float> %t330, i32 1
  %t333 = fadd float %t331, %t332
  %t334 = extractelement <4 x float> %t330, i32 2
  %t335 = fadd float %t333, %t334
  %t336 = extractelement <4 x float> %t330, i32 3
  %t337 = fadd float %t335, %t336
  %t338 = insertelement <4 x float> undef, float %t310, i32 0
  %t339 = insertelement <4 x float> %t338, float %t319, i32 1
  %t340 = insertelement <4 x float> %t339, float %t328, i32 2
  %t341 = insertelement <4 x float> %t340, float %t337, i32 3
  store <4 x float> %t341, <4 x float>* %t299
  %t342 = load <4 x float>, <4 x float>* %t299
  %t343 = extractelement <4 x float> %t342, i32 0
  %t344 = load <4 x float>, <4 x float>* %t299
  %t345 = extractelement <4 x float> %t344, i32 1
  %t346 = load <4 x float>, <4 x float>* %t299
  %t347 = extractelement <4 x float> %t346, i32 2
  %t348 = load <4 x float>, <4 x float>* %t299
  %t349 = extractelement <4 x float> %t348, i32 3
  %t350 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.3, i64 0, i64 0
  %t351 = fpext float %t343 to double
  %t352 = fpext float %t345 to double
  %t353 = fpext float %t347 to double
  %t354 = fpext float %t349 to double
  call i32 (i8*, ...) @printf(i8* %t350, double %t351, double %t352, double %t353, double %t354)
  %t356 = insertelement <3 x float> undef, float 0x3FF0000000000000, i32 0
  %t357 = insertelement <3 x float> %t356, float 0x4000000000000000, i32 1
  %t358 = insertelement <3 x float> %t357, float 0x4008000000000000, i32 2
  store <3 x float> %t358, <3 x float>* %t355
  %t360 = insertelement <3 x float> undef, float 0x4010000000000000, i32 0
  %t361 = insertelement <3 x float> %t360, float 0x4014000000000000, i32 1
  %t362 = insertelement <3 x float> %t361, float 0x4018000000000000, i32 2
  store <3 x float> %t362, <3 x float>* %t359
  %t363 = load <3 x float>, <3 x float>* %t355
  %t364 = load <3 x float>, <3 x float>* %t359
  %t365 = fmul <3 x float> %t363, %t364
  %t366 = extractelement <3 x float> %t365, i32 0
  %t367 = extractelement <3 x float> %t365, i32 1
  %t368 = fadd float %t366, %t367
  %t369 = extractelement <3 x float> %t365, i32 2
  %t370 = fadd float %t368, %t369
  %t371 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.4, i64 0, i64 0
  %t372 = fpext float %t370 to double
  call i32 (i8*, ...) @printf(i8* %t371, double %t372)
  %t373 = insertelement <2 x float> undef, float 0x4008000000000000, i32 0
  %t374 = insertelement <2 x float> %t373, float 0x4010000000000000, i32 1
  %t375 = fmul <2 x float> %t374, %t374
  %t376 = extractelement <2 x float> %t375, i32 0
  %t377 = extractelement <2 x float> %t375, i32 1
  %t378 = fadd float %t376, %t377
  %t379 = call float @llvm.sqrt.f32(float %t378)
  %t380 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.5, i64 0, i64 0
  %t381 = fpext float %t379 to double
  call i32 (i8*, ...) @printf(i8* %t380, double %t381)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [17 x i8] c"zero length: %f\0A\00"
@.str.1 = private unnamed_addr constant [14 x i8] c"zero dot: %f\0A\00"
@.str.2 = private unnamed_addr constant [19 x i8] c"m*v = %f %f %f %f\0A\00"
@.str.3 = private unnamed_addr constant [20 x i8] c"m2*v = %f %f %f %f\0A\00"
@.str.4 = private unnamed_addr constant [15 x i8] c"dot(a,b) = %f\0A\00"
@.str.5 = private unnamed_addr constant [18 x i8] c"length(3,4) = %f\0A\00"
