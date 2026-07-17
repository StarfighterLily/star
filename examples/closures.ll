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
  %t1 = alloca { i8*, i8* }
  %t16 = alloca i32
  %t17 = alloca { i8*, i8* }
  %t68 = alloca { i8*, i8* }
  %t78 = alloca i32
  %t79 = alloca { i8*, i8* }
  %t140 = alloca { i8*, i8* }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t5 = bitcast i32 (i8*, i32)* @closure_1 to i8*
  %t6 = insertvalue { i8*, i8* } undef, i8* %t5, 0
  %t7 = insertvalue { i8*, i8* } %t6, i8* null, 1
  store { i8*, i8* } %t7, { i8*, i8* }* %t1
  %t8 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t9 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t10 = extractvalue { i8*, i8* } %t9, 1
  call void @star_rc_retain(i8* %t10)
  %t11 = extractvalue { i8*, i8* } %t8, 0
  %t12 = extractvalue { i8*, i8* } %t8, 1
  call void @star_rc_release(i8* %t12)
  %t13 = bitcast i8* %t11 to i32 (i8*, i32)*
  %t14 = call i32 %t13(i8* %t12, i32 5)
  %t15 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t15, i32 %t14)
  store i32 10, i32* %t16
  %t29 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* null, i32 1
  %t30 = ptrtoint { { i8*, i8* }, i32 }* %t29 to i64
  %t35 = bitcast void (i8*)* @closure_2_release_env to i8*
  %t36 = call i8* @star_rc_alloc(i64 %t30, i8* %t35)
  %t37 = bitcast i8* %t36 to { { i8*, i8* }, i32 }*
  %t38 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t39 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t40 = extractvalue { i8*, i8* } %t39, 1
  call void @star_rc_retain(i8* %t40)
  %t41 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t37, i32 0, i32 0
  store { i8*, i8* } %t38, { i8*, i8* }* %t41
  %t42 = load i32, i32* %t16
  %t43 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t37, i32 0, i32 1
  store i32 %t42, i32* %t43
  %t44 = bitcast i32 (i8*, i32)* @closure_2 to i8*
  %t45 = insertvalue { i8*, i8* } undef, i8* %t44, 0
  %t46 = insertvalue { i8*, i8* } %t45, i8* %t36, 1
  store { i8*, i8* } %t46, { i8*, i8* }* %t17
  %t47 = load { i8*, i8* }, { i8*, i8* }* %t17
  %t48 = load { i8*, i8* }, { i8*, i8* }* %t17
  %t49 = extractvalue { i8*, i8* } %t48, 1
  call void @star_rc_retain(i8* %t49)
  %t50 = extractvalue { i8*, i8* } %t47, 0
  %t51 = extractvalue { i8*, i8* } %t47, 1
  call void @star_rc_release(i8* %t51)
  %t52 = bitcast i8* %t50 to i32 (i8*, i32)*
  %t53 = call i32 %t52(i8* %t51, i32 7)
  %t54 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t54, i32 %t53)
  %t55 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t56 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t57 = extractvalue { i8*, i8* } %t56, 1
  call void @star_rc_retain(i8* %t57)
  %t58 = call i32 @apply_twice({ i8*, i8* } %t55, i32 5)
  %t59 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t59, i32 %t58)
  %t60 = call i32 @add_one(i32 5)
  %t61 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t61, i32 %t60)
  %t63 = bitcast i32 (i8*, i32)* @fnval_add_one to i8*
  %t64 = insertvalue { i8*, i8* } undef, i8* %t63, 0
  %t65 = insertvalue { i8*, i8* } %t64, i8* null, 1
  %t66 = call i32 @apply_twice({ i8*, i8* } %t65, i32 5)
  %t67 = getelementptr inbounds [30 x i8], [30 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t67, i32 %t66)
  %t69 = call { i8*, i8* } @make_adder(i32 100)
  store { i8*, i8* } %t69, { i8*, i8* }* %t68
  %t70 = load { i8*, i8* }, { i8*, i8* }* %t68
  %t71 = load { i8*, i8* }, { i8*, i8* }* %t68
  %t72 = extractvalue { i8*, i8* } %t71, 1
  call void @star_rc_retain(i8* %t72)
  %t73 = extractvalue { i8*, i8* } %t70, 0
  %t74 = extractvalue { i8*, i8* } %t70, 1
  call void @star_rc_release(i8* %t74)
  %t75 = bitcast i8* %t73 to i32 (i8*, i32)*
  %t76 = call i32 %t75(i8* %t74, i32 5)
  %t77 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t77, i32 %t76)
  store i32 0, i32* %t78
  %t98 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* null, i32 1
  %t99 = ptrtoint { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t98 to i64
  %t110 = bitcast void (i8*)* @closure_3_release_env to i8*
  %t111 = call i8* @star_rc_alloc(i64 %t99, i8* %t110)
  %t112 = bitcast i8* %t111 to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }*
  %t113 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t114 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t115 = extractvalue { i8*, i8* } %t114, 1
  call void @star_rc_retain(i8* %t115)
  %t116 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t112, i32 0, i32 0
  store { i8*, i8* } %t113, { i8*, i8* }* %t116
  %t117 = load i32, i32* %t16
  %t118 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t112, i32 0, i32 1
  store i32 %t117, i32* %t118
  %t119 = load { i8*, i8* }, { i8*, i8* }* %t17
  %t120 = load { i8*, i8* }, { i8*, i8* }* %t17
  %t121 = extractvalue { i8*, i8* } %t120, 1
  call void @star_rc_retain(i8* %t121)
  %t122 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t112, i32 0, i32 2
  store { i8*, i8* } %t119, { i8*, i8* }* %t122
  %t123 = load { i8*, i8* }, { i8*, i8* }* %t68
  %t124 = load { i8*, i8* }, { i8*, i8* }* %t68
  %t125 = extractvalue { i8*, i8* } %t124, 1
  call void @star_rc_retain(i8* %t125)
  %t126 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t112, i32 0, i32 3
  store { i8*, i8* } %t123, { i8*, i8* }* %t126
  %t127 = load i32, i32* %t78
  %t128 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t112, i32 0, i32 4
  store i32 %t127, i32* %t128
  %t129 = bitcast i32 (i8*)* @closure_3 to i8*
  %t130 = insertvalue { i8*, i8* } undef, i8* %t129, 0
  %t131 = insertvalue { i8*, i8* } %t130, i8* %t111, 1
  store { i8*, i8* } %t131, { i8*, i8* }* %t79
  store i32 50, i32* %t78
  %t132 = load { i8*, i8* }, { i8*, i8* }* %t79
  %t133 = load { i8*, i8* }, { i8*, i8* }* %t79
  %t134 = extractvalue { i8*, i8* } %t133, 1
  call void @star_rc_retain(i8* %t134)
  %t135 = extractvalue { i8*, i8* } %t132, 0
  %t136 = extractvalue { i8*, i8* } %t132, 1
  call void @star_rc_release(i8* %t136)
  %t137 = bitcast i8* %t135 to i32 (i8*)*
  %t138 = call i32 %t137(i8* %t136)
  %t139 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t139, i32 %t138)
  %t162 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* null, i32 1
  %t163 = ptrtoint { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t162 to i64
  %t177 = bitcast void (i8*)* @closure_4_release_env to i8*
  %t178 = call i8* @star_rc_alloc(i64 %t163, i8* %t177)
  %t179 = bitcast i8* %t178 to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }*
  %t180 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t181 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t182 = extractvalue { i8*, i8* } %t181, 1
  call void @star_rc_retain(i8* %t182)
  %t183 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t179, i32 0, i32 0
  store { i8*, i8* } %t180, { i8*, i8* }* %t183
  %t184 = load i32, i32* %t16
  %t185 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t179, i32 0, i32 1
  store i32 %t184, i32* %t185
  %t186 = load { i8*, i8* }, { i8*, i8* }* %t17
  %t187 = load { i8*, i8* }, { i8*, i8* }* %t17
  %t188 = extractvalue { i8*, i8* } %t187, 1
  call void @star_rc_retain(i8* %t188)
  %t189 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t179, i32 0, i32 2
  store { i8*, i8* } %t186, { i8*, i8* }* %t189
  %t190 = load { i8*, i8* }, { i8*, i8* }* %t68
  %t191 = load { i8*, i8* }, { i8*, i8* }* %t68
  %t192 = extractvalue { i8*, i8* } %t191, 1
  call void @star_rc_retain(i8* %t192)
  %t193 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t179, i32 0, i32 3
  store { i8*, i8* } %t190, { i8*, i8* }* %t193
  %t194 = load i32, i32* %t78
  %t195 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t179, i32 0, i32 4
  store i32 %t194, i32* %t195
  %t196 = load { i8*, i8* }, { i8*, i8* }* %t79
  %t197 = load { i8*, i8* }, { i8*, i8* }* %t79
  %t198 = extractvalue { i8*, i8* } %t197, 1
  call void @star_rc_retain(i8* %t198)
  %t199 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t179, i32 0, i32 5
  store { i8*, i8* } %t196, { i8*, i8* }* %t199
  %t200 = bitcast void (i8*)* @closure_4 to i8*
  %t201 = insertvalue { i8*, i8* } undef, i8* %t200, 0
  %t202 = insertvalue { i8*, i8* } %t201, i8* %t178, 1
  store { i8*, i8* } %t202, { i8*, i8* }* %t140
  %t203 = load { i8*, i8* }, { i8*, i8* }* %t140
  %t204 = load { i8*, i8* }, { i8*, i8* }* %t140
  %t205 = extractvalue { i8*, i8* } %t204, 1
  call void @star_rc_retain(i8* %t205)
  %t206 = extractvalue { i8*, i8* } %t203, 0
  %t207 = extractvalue { i8*, i8* } %t203, 1
  call void @star_rc_release(i8* %t207)
  %t208 = bitcast i8* %t206 to void (i8*)*
  call void %t208(i8* %t207)
  %t209 = load { i8*, i8* }, { i8*, i8* }* %t140
  %t210 = extractvalue { i8*, i8* } %t209, 1
  call void @star_rc_release(i8* %t210)
  %t211 = load { i8*, i8* }, { i8*, i8* }* %t79
  %t212 = extractvalue { i8*, i8* } %t211, 1
  call void @star_rc_release(i8* %t212)
  %t213 = load { i8*, i8* }, { i8*, i8* }* %t68
  %t214 = extractvalue { i8*, i8* } %t213, 1
  call void @star_rc_release(i8* %t214)
  %t215 = load { i8*, i8* }, { i8*, i8* }* %t17
  %t216 = extractvalue { i8*, i8* } %t215, 1
  call void @star_rc_release(i8* %t216)
  %t217 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t218 = extractvalue { i8*, i8* } %t217, 1
  call void @star_rc_release(i8* %t218)
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
  %t2 = alloca i32
  store i32 %arg_x, i32* %t2
  %t3 = load i32, i32* %t2
  %t4 = add i32 %t3, 1
  ret i32 %t4
}


define i32 @closure_2(i8* %envp, i32 %arg_x) {
entry:
  %t21 = alloca { i8*, i8* }
  %t24 = alloca i32
  %t25 = alloca i32
  %t18 = bitcast i8* %envp to { { i8*, i8* }, i32 }*
  %t19 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t18, i32 0, i32 0
  %t20 = load { i8*, i8* }, { i8*, i8* }* %t19
  store { i8*, i8* } %t20, { i8*, i8* }* %t21
  %t22 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t18, i32 0, i32 1
  %t23 = load i32, i32* %t22
  store i32 %t23, i32* %t24
  store i32 %arg_x, i32* %t25
  %t26 = load i32, i32* %t25
  %t27 = load i32, i32* %t24
  %t28 = add i32 %t26, %t27
  ret i32 %t28
}


define void @closure_2_release_env(i8* %envp) {
entry:
  %t31 = bitcast i8* %envp to { { i8*, i8* }, i32 }*
  %t32 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t31, i32 0, i32 0
  %t33 = load { i8*, i8* }, { i8*, i8* }* %t32
  %t34 = extractvalue { i8*, i8* } %t33, 1
  call void @star_rc_release(i8* %t34)
  ret void
}


define i32 @fnval_add_one(i8* %envp, i32 %arg_0) {
entry:
  %t62 = call i32 @add_one(i32 %arg_0)
  ret i32 %t62
}


define i32 @closure_3(i8* %envp) {
entry:
  %t83 = alloca { i8*, i8* }
  %t86 = alloca i32
  %t89 = alloca { i8*, i8* }
  %t92 = alloca { i8*, i8* }
  %t95 = alloca i32
  %t80 = bitcast i8* %envp to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }*
  %t81 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t80, i32 0, i32 0
  %t82 = load { i8*, i8* }, { i8*, i8* }* %t81
  store { i8*, i8* } %t82, { i8*, i8* }* %t83
  %t84 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t80, i32 0, i32 1
  %t85 = load i32, i32* %t84
  store i32 %t85, i32* %t86
  %t87 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t80, i32 0, i32 2
  %t88 = load { i8*, i8* }, { i8*, i8* }* %t87
  store { i8*, i8* } %t88, { i8*, i8* }* %t89
  %t90 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t80, i32 0, i32 3
  %t91 = load { i8*, i8* }, { i8*, i8* }* %t90
  store { i8*, i8* } %t91, { i8*, i8* }* %t92
  %t93 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t80, i32 0, i32 4
  %t94 = load i32, i32* %t93
  store i32 %t94, i32* %t95
  %t96 = load i32, i32* %t95
  %t97 = add i32 %t96, 1
  ret i32 %t97
}


define void @closure_3_release_env(i8* %envp) {
entry:
  %t100 = bitcast i8* %envp to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }*
  %t101 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t100, i32 0, i32 0
  %t102 = load { i8*, i8* }, { i8*, i8* }* %t101
  %t103 = extractvalue { i8*, i8* } %t102, 1
  call void @star_rc_release(i8* %t103)
  %t104 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t100, i32 0, i32 2
  %t105 = load { i8*, i8* }, { i8*, i8* }* %t104
  %t106 = extractvalue { i8*, i8* } %t105, 1
  call void @star_rc_release(i8* %t106)
  %t107 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t100, i32 0, i32 3
  %t108 = load { i8*, i8* }, { i8*, i8* }* %t107
  %t109 = extractvalue { i8*, i8* } %t108, 1
  call void @star_rc_release(i8* %t109)
  ret void
}


define void @closure_4(i8* %envp) {
entry:
  %t144 = alloca { i8*, i8* }
  %t147 = alloca i32
  %t150 = alloca { i8*, i8* }
  %t153 = alloca { i8*, i8* }
  %t156 = alloca i32
  %t159 = alloca { i8*, i8* }
  %t141 = bitcast i8* %envp to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }*
  %t142 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t141, i32 0, i32 0
  %t143 = load { i8*, i8* }, { i8*, i8* }* %t142
  store { i8*, i8* } %t143, { i8*, i8* }* %t144
  %t145 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t141, i32 0, i32 1
  %t146 = load i32, i32* %t145
  store i32 %t146, i32* %t147
  %t148 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t141, i32 0, i32 2
  %t149 = load { i8*, i8* }, { i8*, i8* }* %t148
  store { i8*, i8* } %t149, { i8*, i8* }* %t150
  %t151 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t141, i32 0, i32 3
  %t152 = load { i8*, i8* }, { i8*, i8* }* %t151
  store { i8*, i8* } %t152, { i8*, i8* }* %t153
  %t154 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t141, i32 0, i32 4
  %t155 = load i32, i32* %t154
  store i32 %t155, i32* %t156
  %t157 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t141, i32 0, i32 5
  %t158 = load { i8*, i8* }, { i8*, i8* }* %t157
  store { i8*, i8* } %t158, { i8*, i8* }* %t159
  %t160 = getelementptr inbounds { i64, i8*, [23 x i8] }, { i64, i8*, [23 x i8] }* @.str.7, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t160)
  call i32 (i8*, ...) @printf(i8* %t160)
  %t161 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t161)
  ret void
}


define void @closure_4_release_env(i8* %envp) {
entry:
  %t164 = bitcast i8* %envp to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }*
  %t165 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t164, i32 0, i32 0
  %t166 = load { i8*, i8* }, { i8*, i8* }* %t165
  %t167 = extractvalue { i8*, i8* } %t166, 1
  call void @star_rc_release(i8* %t167)
  %t168 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t164, i32 0, i32 2
  %t169 = load { i8*, i8* }, { i8*, i8* }* %t168
  %t170 = extractvalue { i8*, i8* } %t169, 1
  call void @star_rc_release(i8* %t170)
  %t171 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t164, i32 0, i32 3
  %t172 = load { i8*, i8* }, { i8*, i8* }* %t171
  %t173 = extractvalue { i8*, i8* } %t172, 1
  call void @star_rc_release(i8* %t173)
  %t174 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t164, i32 0, i32 5
  %t175 = load { i8*, i8* }, { i8*, i8* }* %t174
  %t176 = extractvalue { i8*, i8* } %t175, 1
  call void @star_rc_release(i8* %t176)
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
