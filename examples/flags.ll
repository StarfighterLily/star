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
  %t2 = alloca i64
  %t50 = alloca i64
  %t87 = alloca i64
  %t100 = alloca i64
  %t107 = alloca i64
  %t114 = alloca i64
  %t125 = alloca i64
  %t126 = alloca i64
  %t137 = alloca i64
  %t148 = alloca i32
  %t149 = alloca i64
  %t170 = alloca i64
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  store i64 0, i64* %t2
  %t3 = load i64, i64* %t2
  %t4 = icmp eq i64 %t3, 0
  %t5 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.0, i64 0, i64 0
  %t6 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.1, i64 0, i64 0
  %t7 = select i1 %t4, i8* %t5, i8* %t6
  %t8 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t8, i8* %t7)
  %t9 = load i64, i64* %t2
  %t10 = zext i32 0 to i64
  %t11 = shl i64 1, %t10
  %t12 = or i64 %t9, %t11
  store i64 %t12, i64* %t2
  %t13 = load i64, i64* %t2
  %t14 = zext i32 0 to i64
  %t15 = shl i64 1, %t14
  %t16 = and i64 %t13, %t15
  %t17 = icmp ne i64 %t16, 0
  %t18 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.3, i64 0, i64 0
  %t19 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.4, i64 0, i64 0
  %t20 = select i1 %t17, i8* %t18, i8* %t19
  %t21 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t21, i8* %t20)
  %t22 = load i64, i64* %t2
  %t23 = zext i32 1 to i64
  %t24 = shl i64 1, %t23
  %t25 = and i64 %t22, %t24
  %t26 = icmp ne i64 %t25, 0
  %t27 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.6, i64 0, i64 0
  %t28 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.7, i64 0, i64 0
  %t29 = select i1 %t26, i8* %t27, i8* %t28
  %t30 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t30, i8* %t29)
  %t31 = load i64, i64* %t2
  %t32 = icmp eq i64 %t31, 0
  %t33 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.9, i64 0, i64 0
  %t34 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.10, i64 0, i64 0
  %t35 = select i1 %t32, i8* %t33, i8* %t34
  %t36 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t36, i8* %t35)
  %t37 = load i64, i64* %t2
  %t38 = zext i32 3 to i64
  %t39 = shl i64 1, %t38
  %t40 = or i64 %t37, %t39
  store i64 %t40, i64* %t2
  %t41 = load i64, i64* %t2
  %t42 = zext i32 3 to i64
  %t43 = shl i64 1, %t42
  %t44 = and i64 %t41, %t43
  %t45 = icmp ne i64 %t44, 0
  %t46 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.12, i64 0, i64 0
  %t47 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.13, i64 0, i64 0
  %t48 = select i1 %t45, i8* %t46, i8* %t47
  %t49 = getelementptr inbounds [38 x i8], [38 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t49, i8* %t48)
  %t51 = zext i32 0 to i64
  %t52 = shl i64 1, %t51
  %t53 = or i64 0, %t52
  %t54 = zext i32 3 to i64
  %t55 = shl i64 1, %t54
  %t56 = or i64 %t53, %t55
  store i64 %t56, i64* %t50
  %t57 = load i64, i64* %t50
  %t58 = load i64, i64* %t2
  %t59 = icmp eq i64 %t57, %t58
  %t60 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.15, i64 0, i64 0
  %t61 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.16, i64 0, i64 0
  %t62 = select i1 %t59, i8* %t60, i8* %t61
  %t63 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t63, i8* %t62)
  %t64 = load i64, i64* %t2
  %t65 = zext i32 0 to i64
  %t66 = shl i64 1, %t65
  %t68 = xor i64 %t66, -1
  %t67 = and i64 %t64, %t68
  store i64 %t67, i64* %t2
  %t69 = load i64, i64* %t2
  %t70 = zext i32 0 to i64
  %t71 = shl i64 1, %t70
  %t72 = and i64 %t69, %t71
  %t73 = icmp ne i64 %t72, 0
  %t74 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.18, i64 0, i64 0
  %t75 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.19, i64 0, i64 0
  %t76 = select i1 %t73, i8* %t74, i8* %t75
  %t77 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.20, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t77, i8* %t76)
  %t78 = load i64, i64* %t2
  %t79 = zext i32 3 to i64
  %t80 = shl i64 1, %t79
  %t81 = and i64 %t78, %t80
  %t82 = icmp ne i64 %t81, 0
  %t83 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.21, i64 0, i64 0
  %t84 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.22, i64 0, i64 0
  %t85 = select i1 %t82, i8* %t83, i8* %t84
  %t86 = getelementptr inbounds [28 x i8], [28 x i8]* @.str.23, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t86, i8* %t85)
  %t88 = zext i32 0 to i64
  %t89 = shl i64 1, %t88
  %t90 = or i64 0, %t89
  %t91 = zext i32 1 to i64
  %t92 = shl i64 1, %t91
  %t93 = or i64 %t90, %t92
  %t94 = zext i32 2 to i64
  %t95 = shl i64 1, %t94
  %t96 = or i64 %t93, %t95
  %t97 = zext i32 3 to i64
  %t98 = shl i64 1, %t97
  %t99 = or i64 %t96, %t98
  store i64 %t99, i64* %t87
  %t101 = zext i32 0 to i64
  %t102 = shl i64 1, %t101
  %t103 = or i64 0, %t102
  %t104 = zext i32 1 to i64
  %t105 = shl i64 1, %t104
  %t106 = or i64 %t103, %t105
  store i64 %t106, i64* %t100
  %t108 = zext i32 2 to i64
  %t109 = shl i64 1, %t108
  %t110 = or i64 0, %t109
  %t111 = zext i32 3 to i64
  %t112 = shl i64 1, %t111
  %t113 = or i64 %t110, %t112
  store i64 %t113, i64* %t107
  %t115 = load i64, i64* %t100
  %t116 = load i64, i64* %t107
  %t117 = or i64 %t115, %t116
  store i64 %t117, i64* %t114
  %t118 = load i64, i64* %t114
  %t119 = load i64, i64* %t87
  %t120 = icmp eq i64 %t118, %t119
  %t121 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.24, i64 0, i64 0
  %t122 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.25, i64 0, i64 0
  %t123 = select i1 %t120, i8* %t121, i8* %t122
  %t124 = getelementptr inbounds [41 x i8], [41 x i8]* @.str.26, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t124, i8* %t123)
  store i64 0, i64* %t125
  %t127 = load i64, i64* %t100
  %t128 = load i64, i64* %t107
  %t129 = and i64 %t127, %t128
  store i64 %t129, i64* %t126
  %t130 = load i64, i64* %t126
  %t131 = load i64, i64* %t125
  %t132 = icmp eq i64 %t130, %t131
  %t133 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.27, i64 0, i64 0
  %t134 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.28, i64 0, i64 0
  %t135 = select i1 %t132, i8* %t133, i8* %t134
  %t136 = getelementptr inbounds [36 x i8], [36 x i8]* @.str.29, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t136, i8* %t135)
  %t138 = load i64, i64* %t87
  %t139 = load i64, i64* %t100
  %t140 = xor i64 %t138, %t139
  store i64 %t140, i64* %t137
  %t141 = load i64, i64* %t137
  %t142 = load i64, i64* %t107
  %t143 = icmp eq i64 %t141, %t142
  %t144 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.30, i64 0, i64 0
  %t145 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.31, i64 0, i64 0
  %t146 = select i1 %t143, i8* %t144, i8* %t145
  %t147 = getelementptr inbounds [41 x i8], [41 x i8]* @.str.32, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t147, i8* %t146)
  store i32 2, i32* %t148
  %t150 = load i32, i32* %t148
  %t151 = zext i32 %t150 to i64
  %t152 = shl i64 1, %t151
  %t153 = or i64 0, %t152
  store i64 %t153, i64* %t149
  %t154 = load i64, i64* %t149
  %t155 = zext i32 2 to i64
  %t156 = shl i64 1, %t155
  %t157 = and i64 %t154, %t156
  %t158 = icmp ne i64 %t157, 0
  %t159 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.33, i64 0, i64 0
  %t160 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.34, i64 0, i64 0
  %t161 = select i1 %t158, i8* %t159, i8* %t160
  %t162 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.35, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t162, i8* %t161)
  %t163 = load i64, i64* %t100
  %t164 = load i64, i64* %t107
  %t165 = icmp ne i64 %t163, %t164
  %t166 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.36, i64 0, i64 0
  %t167 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.37, i64 0, i64 0
  %t168 = select i1 %t165, i8* %t166, i8* %t167
  %t169 = getelementptr inbounds [30 x i8], [30 x i8]* @.str.38, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t169, i8* %t168)
  %t171 = load i64, i64* %t87
  store i64 %t171, i64* %t170
  %t172 = load i64, i64* %t170
  %t173 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.39, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t173, i64 %t172)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.1 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.2 = private unnamed_addr constant [27 x i8] c"empty moving is empty? %s\0A\00"
@.str.3 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.4 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.5 = private unnamed_addr constant [19 x i8] c"moving has Up? %s\0A\00"
@.str.6 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.7 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.8 = private unnamed_addr constant [21 x i8] c"moving has Down? %s\0A\00"
@.str.9 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.10 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.11 = private unnamed_addr constant [21 x i8] c"moving is empty? %s\0A\00"
@.str.12 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.13 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.14 = private unnamed_addr constant [38 x i8] c"moving has Right after adding it? %s\0A\00"
@.str.15 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.16 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.17 = private unnamed_addr constant [26 x i8] c"diagonal == moving is %s\0A\00"
@.str.18 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.19 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.20 = private unnamed_addr constant [37 x i8] c"moving has Up after removing it? %s\0A\00"
@.str.21 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.22 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.23 = private unnamed_addr constant [28 x i8] c"moving has Right still? %s\0A\00"
@.str.24 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.25 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.26 = private unnamed_addr constant [41 x i8] c"vertical | horizontal == all_four is %s\0A\00"
@.str.27 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.28 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.29 = private unnamed_addr constant [36 x i8] c"vertical & horizontal is empty? %s\0A\00"
@.str.30 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.31 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.32 = private unnamed_addr constant [41 x i8] c"all_four ^ vertical == horizontal is %s\0A\00"
@.str.33 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.34 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.35 = private unnamed_addr constant [23 x i8] c"from_var has Left? %s\0A\00"
@.str.36 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.37 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.38 = private unnamed_addr constant [30 x i8] c"vertical != horizontal is %s\0A\00"
@.str.39 = private unnamed_addr constant [24 x i8] c"all_four as i64 = %lld\0A\00"
