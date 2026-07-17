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

define i32 @apply_twice({ i8*, i8* } %f, i32 %x) {
entry:
  %t0 = alloca { i8*, i8* }
  %t1 = alloca i32
  store { i8*, i8* } %f, { i8*, i8* }* %t0
  store i32 %x, i32* %t1
  %t2 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t3 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t4 = extractvalue { i8*, i8* } %t3, 1
  call void @star_rc_retain(i8* %t4)
  %t5 = extractvalue { i8*, i8* } %t2, 0
  %t6 = extractvalue { i8*, i8* } %t2, 1
  call void @star_rc_release(i8* %t6)
  %t7 = bitcast i8* %t5 to i32 (i8*, i32)*
  %t8 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t9 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t10 = extractvalue { i8*, i8* } %t9, 1
  call void @star_rc_retain(i8* %t10)
  %t11 = extractvalue { i8*, i8* } %t8, 0
  %t12 = extractvalue { i8*, i8* } %t8, 1
  call void @star_rc_release(i8* %t12)
  %t13 = bitcast i8* %t11 to i32 (i8*, i32)*
  %t14 = load i32, i32* %t1
  %t15 = call i32 %t13(i8* %t12, i32 %t14)
  %t16 = call i32 %t7(i8* %t6, i32 %t15)
  %t17 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t18 = extractvalue { i8*, i8* } %t17, 1
  call void @star_rc_release(i8* %t18)
  ret i32 %t16
}

define i32 @add_one(i32 %x) {
entry:
  %t0 = alloca i32
  store i32 %x, i32* %t0
  %t1 = load i32, i32* %t0
  %t2 = add i32 %t1, 1
  ret i32 %t2
}

define { i8*, i8* } @make_adder(i32 %n) {
entry:
  %t0 = alloca i32
  store i32 %n, i32* %t0
  %t9 = getelementptr inbounds { i32 }, { i32 }* null, i32 1
  %t10 = ptrtoint { i32 }* %t9 to i64
  %t11 = call i8* @star_rc_alloc(i64 %t10, i8* null)
  %t12 = bitcast i8* %t11 to { i32 }*
  %t13 = load i32, i32* %t0
  %t14 = getelementptr inbounds { i32 }, { i32 }* %t12, i32 0, i32 0
  store i32 %t13, i32* %t14
  %t15 = bitcast i32 (i8*, i32)* @closure_0 to i8*
  %t16 = insertvalue { i8*, i8* } undef, i8* %t15, 0
  %t17 = insertvalue { i8*, i8* } %t16, i8* %t11, 1
  ret { i8*, i8* } %t17
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t0 = alloca { i8*, i8* }
  %t15 = alloca i32
  %t16 = alloca { i8*, i8* }
  %t67 = alloca { i8*, i8* }
  %t77 = alloca i32
  %t78 = alloca { i8*, i8* }
  %t139 = alloca { i8*, i8* }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t4 = bitcast i32 (i8*, i32)* @closure_1 to i8*
  %t5 = insertvalue { i8*, i8* } undef, i8* %t4, 0
  %t6 = insertvalue { i8*, i8* } %t5, i8* null, 1
  store { i8*, i8* } %t6, { i8*, i8* }* %t0
  %t7 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t8 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t9 = extractvalue { i8*, i8* } %t8, 1
  call void @star_rc_retain(i8* %t9)
  %t10 = extractvalue { i8*, i8* } %t7, 0
  %t11 = extractvalue { i8*, i8* } %t7, 1
  call void @star_rc_release(i8* %t11)
  %t12 = bitcast i8* %t10 to i32 (i8*, i32)*
  %t13 = call i32 %t12(i8* %t11, i32 5)
  %t14 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t14, i32 %t13)
  store i32 10, i32* %t15
  %t28 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* null, i32 1
  %t29 = ptrtoint { { i8*, i8* }, i32 }* %t28 to i64
  %t34 = bitcast void (i8*)* @closure_2_release_env to i8*
  %t35 = call i8* @star_rc_alloc(i64 %t29, i8* %t34)
  %t36 = bitcast i8* %t35 to { { i8*, i8* }, i32 }*
  %t37 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t38 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t39 = extractvalue { i8*, i8* } %t38, 1
  call void @star_rc_retain(i8* %t39)
  %t40 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t36, i32 0, i32 0
  store { i8*, i8* } %t37, { i8*, i8* }* %t40
  %t41 = load i32, i32* %t15
  %t42 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t36, i32 0, i32 1
  store i32 %t41, i32* %t42
  %t43 = bitcast i32 (i8*, i32)* @closure_2 to i8*
  %t44 = insertvalue { i8*, i8* } undef, i8* %t43, 0
  %t45 = insertvalue { i8*, i8* } %t44, i8* %t35, 1
  store { i8*, i8* } %t45, { i8*, i8* }* %t16
  %t46 = load { i8*, i8* }, { i8*, i8* }* %t16
  %t47 = load { i8*, i8* }, { i8*, i8* }* %t16
  %t48 = extractvalue { i8*, i8* } %t47, 1
  call void @star_rc_retain(i8* %t48)
  %t49 = extractvalue { i8*, i8* } %t46, 0
  %t50 = extractvalue { i8*, i8* } %t46, 1
  call void @star_rc_release(i8* %t50)
  %t51 = bitcast i8* %t49 to i32 (i8*, i32)*
  %t52 = call i32 %t51(i8* %t50, i32 7)
  %t53 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t53, i32 %t52)
  %t54 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t55 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t56 = extractvalue { i8*, i8* } %t55, 1
  call void @star_rc_retain(i8* %t56)
  %t57 = call i32 @apply_twice({ i8*, i8* } %t54, i32 5)
  %t58 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t58, i32 %t57)
  %t59 = call i32 @add_one(i32 5)
  %t60 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t60, i32 %t59)
  %t62 = bitcast i32 (i8*, i32)* @fnval_add_one to i8*
  %t63 = insertvalue { i8*, i8* } undef, i8* %t62, 0
  %t64 = insertvalue { i8*, i8* } %t63, i8* null, 1
  %t65 = call i32 @apply_twice({ i8*, i8* } %t64, i32 5)
  %t66 = getelementptr inbounds [30 x i8], [30 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t66, i32 %t65)
  %t68 = call { i8*, i8* } @make_adder(i32 100)
  store { i8*, i8* } %t68, { i8*, i8* }* %t67
  %t69 = load { i8*, i8* }, { i8*, i8* }* %t67
  %t70 = load { i8*, i8* }, { i8*, i8* }* %t67
  %t71 = extractvalue { i8*, i8* } %t70, 1
  call void @star_rc_retain(i8* %t71)
  %t72 = extractvalue { i8*, i8* } %t69, 0
  %t73 = extractvalue { i8*, i8* } %t69, 1
  call void @star_rc_release(i8* %t73)
  %t74 = bitcast i8* %t72 to i32 (i8*, i32)*
  %t75 = call i32 %t74(i8* %t73, i32 5)
  %t76 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t76, i32 %t75)
  store i32 0, i32* %t77
  %t97 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* null, i32 1
  %t98 = ptrtoint { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t97 to i64
  %t109 = bitcast void (i8*)* @closure_3_release_env to i8*
  %t110 = call i8* @star_rc_alloc(i64 %t98, i8* %t109)
  %t111 = bitcast i8* %t110 to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }*
  %t112 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t113 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t114 = extractvalue { i8*, i8* } %t113, 1
  call void @star_rc_retain(i8* %t114)
  %t115 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t111, i32 0, i32 0
  store { i8*, i8* } %t112, { i8*, i8* }* %t115
  %t116 = load i32, i32* %t15
  %t117 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t111, i32 0, i32 1
  store i32 %t116, i32* %t117
  %t118 = load { i8*, i8* }, { i8*, i8* }* %t16
  %t119 = load { i8*, i8* }, { i8*, i8* }* %t16
  %t120 = extractvalue { i8*, i8* } %t119, 1
  call void @star_rc_retain(i8* %t120)
  %t121 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t111, i32 0, i32 2
  store { i8*, i8* } %t118, { i8*, i8* }* %t121
  %t122 = load { i8*, i8* }, { i8*, i8* }* %t67
  %t123 = load { i8*, i8* }, { i8*, i8* }* %t67
  %t124 = extractvalue { i8*, i8* } %t123, 1
  call void @star_rc_retain(i8* %t124)
  %t125 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t111, i32 0, i32 3
  store { i8*, i8* } %t122, { i8*, i8* }* %t125
  %t126 = load i32, i32* %t77
  %t127 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t111, i32 0, i32 4
  store i32 %t126, i32* %t127
  %t128 = bitcast i32 (i8*)* @closure_3 to i8*
  %t129 = insertvalue { i8*, i8* } undef, i8* %t128, 0
  %t130 = insertvalue { i8*, i8* } %t129, i8* %t110, 1
  store { i8*, i8* } %t130, { i8*, i8* }* %t78
  store i32 50, i32* %t77
  %t131 = load { i8*, i8* }, { i8*, i8* }* %t78
  %t132 = load { i8*, i8* }, { i8*, i8* }* %t78
  %t133 = extractvalue { i8*, i8* } %t132, 1
  call void @star_rc_retain(i8* %t133)
  %t134 = extractvalue { i8*, i8* } %t131, 0
  %t135 = extractvalue { i8*, i8* } %t131, 1
  call void @star_rc_release(i8* %t135)
  %t136 = bitcast i8* %t134 to i32 (i8*)*
  %t137 = call i32 %t136(i8* %t135)
  %t138 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t138, i32 %t137)
  %t161 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* null, i32 1
  %t162 = ptrtoint { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t161 to i64
  %t176 = bitcast void (i8*)* @closure_4_release_env to i8*
  %t177 = call i8* @star_rc_alloc(i64 %t162, i8* %t176)
  %t178 = bitcast i8* %t177 to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }*
  %t179 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t180 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t181 = extractvalue { i8*, i8* } %t180, 1
  call void @star_rc_retain(i8* %t181)
  %t182 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t178, i32 0, i32 0
  store { i8*, i8* } %t179, { i8*, i8* }* %t182
  %t183 = load i32, i32* %t15
  %t184 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t178, i32 0, i32 1
  store i32 %t183, i32* %t184
  %t185 = load { i8*, i8* }, { i8*, i8* }* %t16
  %t186 = load { i8*, i8* }, { i8*, i8* }* %t16
  %t187 = extractvalue { i8*, i8* } %t186, 1
  call void @star_rc_retain(i8* %t187)
  %t188 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t178, i32 0, i32 2
  store { i8*, i8* } %t185, { i8*, i8* }* %t188
  %t189 = load { i8*, i8* }, { i8*, i8* }* %t67
  %t190 = load { i8*, i8* }, { i8*, i8* }* %t67
  %t191 = extractvalue { i8*, i8* } %t190, 1
  call void @star_rc_retain(i8* %t191)
  %t192 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t178, i32 0, i32 3
  store { i8*, i8* } %t189, { i8*, i8* }* %t192
  %t193 = load i32, i32* %t77
  %t194 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t178, i32 0, i32 4
  store i32 %t193, i32* %t194
  %t195 = load { i8*, i8* }, { i8*, i8* }* %t78
  %t196 = load { i8*, i8* }, { i8*, i8* }* %t78
  %t197 = extractvalue { i8*, i8* } %t196, 1
  call void @star_rc_retain(i8* %t197)
  %t198 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t178, i32 0, i32 5
  store { i8*, i8* } %t195, { i8*, i8* }* %t198
  %t199 = bitcast void (i8*)* @closure_4 to i8*
  %t200 = insertvalue { i8*, i8* } undef, i8* %t199, 0
  %t201 = insertvalue { i8*, i8* } %t200, i8* %t177, 1
  store { i8*, i8* } %t201, { i8*, i8* }* %t139
  %t202 = load { i8*, i8* }, { i8*, i8* }* %t139
  %t203 = load { i8*, i8* }, { i8*, i8* }* %t139
  %t204 = extractvalue { i8*, i8* } %t203, 1
  call void @star_rc_retain(i8* %t204)
  %t205 = extractvalue { i8*, i8* } %t202, 0
  %t206 = extractvalue { i8*, i8* } %t202, 1
  call void @star_rc_release(i8* %t206)
  %t207 = bitcast i8* %t205 to void (i8*)*
  call void %t207(i8* %t206)
  %t208 = load { i8*, i8* }, { i8*, i8* }* %t139
  %t209 = extractvalue { i8*, i8* } %t208, 1
  call void @star_rc_release(i8* %t209)
  %t210 = load { i8*, i8* }, { i8*, i8* }* %t78
  %t211 = extractvalue { i8*, i8* } %t210, 1
  call void @star_rc_release(i8* %t211)
  %t212 = load { i8*, i8* }, { i8*, i8* }* %t67
  %t213 = extractvalue { i8*, i8* } %t212, 1
  call void @star_rc_release(i8* %t213)
  %t214 = load { i8*, i8* }, { i8*, i8* }* %t16
  %t215 = extractvalue { i8*, i8* } %t214, 1
  call void @star_rc_release(i8* %t215)
  %t216 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t217 = extractvalue { i8*, i8* } %t216, 1
  call void @star_rc_release(i8* %t217)
  ret i32 0
}


; par/swarm worker functions
define i32 @closure_0(i8* %envp, i32 %arg_x) {
entry:
  %t4 = alloca i32
  %t5 = alloca i32
  %t1 = bitcast i8* %envp to { i32 }*
  %t2 = getelementptr inbounds { i32 }, { i32 }* %t1, i32 0, i32 0
  %t3 = load i32, i32* %t2
  store i32 %t3, i32* %t4
  store i32 %arg_x, i32* %t5
  %t6 = load i32, i32* %t5
  %t7 = load i32, i32* %t4
  %t8 = add i32 %t6, %t7
  ret i32 %t8
}


define i32 @closure_1(i8* %envp, i32 %arg_x) {
entry:
  %t1 = alloca i32
  store i32 %arg_x, i32* %t1
  %t2 = load i32, i32* %t1
  %t3 = add i32 %t2, 1
  ret i32 %t3
}


define i32 @closure_2(i8* %envp, i32 %arg_x) {
entry:
  %t20 = alloca { i8*, i8* }
  %t23 = alloca i32
  %t24 = alloca i32
  %t17 = bitcast i8* %envp to { { i8*, i8* }, i32 }*
  %t18 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t17, i32 0, i32 0
  %t19 = load { i8*, i8* }, { i8*, i8* }* %t18
  store { i8*, i8* } %t19, { i8*, i8* }* %t20
  %t21 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t17, i32 0, i32 1
  %t22 = load i32, i32* %t21
  store i32 %t22, i32* %t23
  store i32 %arg_x, i32* %t24
  %t25 = load i32, i32* %t24
  %t26 = load i32, i32* %t23
  %t27 = add i32 %t25, %t26
  ret i32 %t27
}


define void @closure_2_release_env(i8* %envp) {
entry:
  %t30 = bitcast i8* %envp to { { i8*, i8* }, i32 }*
  %t31 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t30, i32 0, i32 0
  %t32 = load { i8*, i8* }, { i8*, i8* }* %t31
  %t33 = extractvalue { i8*, i8* } %t32, 1
  call void @star_rc_release(i8* %t33)
  ret void
}


define i32 @fnval_add_one(i8* %envp, i32 %arg_0) {
entry:
  %t61 = call i32 @add_one(i32 %arg_0)
  ret i32 %t61
}


define i32 @closure_3(i8* %envp) {
entry:
  %t82 = alloca { i8*, i8* }
  %t85 = alloca i32
  %t88 = alloca { i8*, i8* }
  %t91 = alloca { i8*, i8* }
  %t94 = alloca i32
  %t79 = bitcast i8* %envp to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }*
  %t80 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t79, i32 0, i32 0
  %t81 = load { i8*, i8* }, { i8*, i8* }* %t80
  store { i8*, i8* } %t81, { i8*, i8* }* %t82
  %t83 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t79, i32 0, i32 1
  %t84 = load i32, i32* %t83
  store i32 %t84, i32* %t85
  %t86 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t79, i32 0, i32 2
  %t87 = load { i8*, i8* }, { i8*, i8* }* %t86
  store { i8*, i8* } %t87, { i8*, i8* }* %t88
  %t89 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t79, i32 0, i32 3
  %t90 = load { i8*, i8* }, { i8*, i8* }* %t89
  store { i8*, i8* } %t90, { i8*, i8* }* %t91
  %t92 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t79, i32 0, i32 4
  %t93 = load i32, i32* %t92
  store i32 %t93, i32* %t94
  %t95 = load i32, i32* %t94
  %t96 = add i32 %t95, 1
  ret i32 %t96
}


define void @closure_3_release_env(i8* %envp) {
entry:
  %t99 = bitcast i8* %envp to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }*
  %t100 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t99, i32 0, i32 0
  %t101 = load { i8*, i8* }, { i8*, i8* }* %t100
  %t102 = extractvalue { i8*, i8* } %t101, 1
  call void @star_rc_release(i8* %t102)
  %t103 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t99, i32 0, i32 2
  %t104 = load { i8*, i8* }, { i8*, i8* }* %t103
  %t105 = extractvalue { i8*, i8* } %t104, 1
  call void @star_rc_release(i8* %t105)
  %t106 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t99, i32 0, i32 3
  %t107 = load { i8*, i8* }, { i8*, i8* }* %t106
  %t108 = extractvalue { i8*, i8* } %t107, 1
  call void @star_rc_release(i8* %t108)
  ret void
}


define void @closure_4(i8* %envp) {
entry:
  %t143 = alloca { i8*, i8* }
  %t146 = alloca i32
  %t149 = alloca { i8*, i8* }
  %t152 = alloca { i8*, i8* }
  %t155 = alloca i32
  %t158 = alloca { i8*, i8* }
  %t140 = bitcast i8* %envp to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }*
  %t141 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t140, i32 0, i32 0
  %t142 = load { i8*, i8* }, { i8*, i8* }* %t141
  store { i8*, i8* } %t142, { i8*, i8* }* %t143
  %t144 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t140, i32 0, i32 1
  %t145 = load i32, i32* %t144
  store i32 %t145, i32* %t146
  %t147 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t140, i32 0, i32 2
  %t148 = load { i8*, i8* }, { i8*, i8* }* %t147
  store { i8*, i8* } %t148, { i8*, i8* }* %t149
  %t150 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t140, i32 0, i32 3
  %t151 = load { i8*, i8* }, { i8*, i8* }* %t150
  store { i8*, i8* } %t151, { i8*, i8* }* %t152
  %t153 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t140, i32 0, i32 4
  %t154 = load i32, i32* %t153
  store i32 %t154, i32* %t155
  %t156 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t140, i32 0, i32 5
  %t157 = load { i8*, i8* }, { i8*, i8* }* %t156
  store { i8*, i8* } %t157, { i8*, i8* }* %t158
  %t159 = getelementptr inbounds { i64, i8*, [23 x i8] }, { i64, i8*, [23 x i8] }* @.str.7, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t159)
  call i32 (i8*, ...) @printf(i8* %t159)
  %t160 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t160)
  ret void
}


define void @closure_4_release_env(i8* %envp) {
entry:
  %t163 = bitcast i8* %envp to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }*
  %t164 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t163, i32 0, i32 0
  %t165 = load { i8*, i8* }, { i8*, i8* }* %t164
  %t166 = extractvalue { i8*, i8* } %t165, 1
  call void @star_rc_release(i8* %t166)
  %t167 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t163, i32 0, i32 2
  %t168 = load { i8*, i8* }, { i8*, i8* }* %t167
  %t169 = extractvalue { i8*, i8* } %t168, 1
  call void @star_rc_release(i8* %t169)
  %t170 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t163, i32 0, i32 3
  %t171 = load { i8*, i8* }, { i8*, i8* }* %t170
  %t172 = extractvalue { i8*, i8* } %t171, 1
  call void @star_rc_release(i8* %t172)
  %t173 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t163, i32 0, i32 5
  %t174 = load { i8*, i8* }, { i8*, i8* }* %t173
  %t175 = extractvalue { i8*, i8* } %t174, 1
  call void @star_rc_release(i8* %t175)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant [14 x i8] c"add1(5) = %d\0A\00"
@.str.1 = private unnamed_addr constant [18 x i8] c"add_base(7) = %d\0A\00"
@.str.2 = private unnamed_addr constant [27 x i8] c"apply_twice(add1, 5) = %d\0A\00"
@.str.3 = private unnamed_addr constant [17 x i8] c"add_one(5) = %d\0A\00"
@.str.4 = private unnamed_addr constant [30 x i8] c"apply_twice(add_one, 5) = %d\0A\00"
@.str.5 = private unnamed_addr constant [15 x i8] c"adder(5) = %d\0A\00"
@.str.6 = private unnamed_addr constant [13 x i8] c"bump() = %d\0A\00"
@.str.7 = private unnamed_addr constant { i64, i8*, [23 x i8] } { i64 -1, i8* null, [23 x i8] c"hi from a void closure\00" }
@.str.8 = private unnamed_addr constant [2 x i8] c"\0A\00"
