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
  %t2 = alloca { i8*, i8* }
  %t17 = alloca i32
  %t18 = alloca { i8*, i8* }
  %t69 = alloca { i8*, i8* }
  %t79 = alloca i32
  %t80 = alloca { i8*, i8* }
  %t141 = alloca { i8*, i8* }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t6 = bitcast i32 (i8*, i32)* @closure_1 to i8*
  %t7 = insertvalue { i8*, i8* } undef, i8* %t6, 0
  %t8 = insertvalue { i8*, i8* } %t7, i8* null, 1
  store { i8*, i8* } %t8, { i8*, i8* }* %t2
  %t9 = load { i8*, i8* }, { i8*, i8* }* %t2
  %t10 = load { i8*, i8* }, { i8*, i8* }* %t2
  %t11 = extractvalue { i8*, i8* } %t10, 1
  call void @star_rc_retain(i8* %t11)
  %t12 = extractvalue { i8*, i8* } %t9, 0
  %t13 = extractvalue { i8*, i8* } %t9, 1
  call void @star_rc_release(i8* %t13)
  %t14 = bitcast i8* %t12 to i32 (i8*, i32)*
  %t15 = call i32 %t14(i8* %t13, i32 5)
  %t16 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t16, i32 %t15)
  store i32 10, i32* %t17
  %t30 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* null, i32 1
  %t31 = ptrtoint { { i8*, i8* }, i32 }* %t30 to i64
  %t36 = bitcast void (i8*)* @closure_2_release_env to i8*
  %t37 = call i8* @star_rc_alloc(i64 %t31, i8* %t36)
  %t38 = bitcast i8* %t37 to { { i8*, i8* }, i32 }*
  %t39 = load { i8*, i8* }, { i8*, i8* }* %t2
  %t40 = load { i8*, i8* }, { i8*, i8* }* %t2
  %t41 = extractvalue { i8*, i8* } %t40, 1
  call void @star_rc_retain(i8* %t41)
  %t42 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t38, i32 0, i32 0
  store { i8*, i8* } %t39, { i8*, i8* }* %t42
  %t43 = load i32, i32* %t17
  %t44 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t38, i32 0, i32 1
  store i32 %t43, i32* %t44
  %t45 = bitcast i32 (i8*, i32)* @closure_2 to i8*
  %t46 = insertvalue { i8*, i8* } undef, i8* %t45, 0
  %t47 = insertvalue { i8*, i8* } %t46, i8* %t37, 1
  store { i8*, i8* } %t47, { i8*, i8* }* %t18
  %t48 = load { i8*, i8* }, { i8*, i8* }* %t18
  %t49 = load { i8*, i8* }, { i8*, i8* }* %t18
  %t50 = extractvalue { i8*, i8* } %t49, 1
  call void @star_rc_retain(i8* %t50)
  %t51 = extractvalue { i8*, i8* } %t48, 0
  %t52 = extractvalue { i8*, i8* } %t48, 1
  call void @star_rc_release(i8* %t52)
  %t53 = bitcast i8* %t51 to i32 (i8*, i32)*
  %t54 = call i32 %t53(i8* %t52, i32 7)
  %t55 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t55, i32 %t54)
  %t56 = load { i8*, i8* }, { i8*, i8* }* %t2
  %t57 = load { i8*, i8* }, { i8*, i8* }* %t2
  %t58 = extractvalue { i8*, i8* } %t57, 1
  call void @star_rc_retain(i8* %t58)
  %t59 = call i32 @apply_twice({ i8*, i8* } %t56, i32 5)
  %t60 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t60, i32 %t59)
  %t61 = call i32 @add_one(i32 5)
  %t62 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t62, i32 %t61)
  %t64 = bitcast i32 (i8*, i32)* @fnval_add_one to i8*
  %t65 = insertvalue { i8*, i8* } undef, i8* %t64, 0
  %t66 = insertvalue { i8*, i8* } %t65, i8* null, 1
  %t67 = call i32 @apply_twice({ i8*, i8* } %t66, i32 5)
  %t68 = getelementptr inbounds [30 x i8], [30 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t68, i32 %t67)
  %t70 = call { i8*, i8* } @make_adder(i32 100)
  store { i8*, i8* } %t70, { i8*, i8* }* %t69
  %t71 = load { i8*, i8* }, { i8*, i8* }* %t69
  %t72 = load { i8*, i8* }, { i8*, i8* }* %t69
  %t73 = extractvalue { i8*, i8* } %t72, 1
  call void @star_rc_retain(i8* %t73)
  %t74 = extractvalue { i8*, i8* } %t71, 0
  %t75 = extractvalue { i8*, i8* } %t71, 1
  call void @star_rc_release(i8* %t75)
  %t76 = bitcast i8* %t74 to i32 (i8*, i32)*
  %t77 = call i32 %t76(i8* %t75, i32 5)
  %t78 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t78, i32 %t77)
  store i32 0, i32* %t79
  %t99 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* null, i32 1
  %t100 = ptrtoint { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t99 to i64
  %t111 = bitcast void (i8*)* @closure_3_release_env to i8*
  %t112 = call i8* @star_rc_alloc(i64 %t100, i8* %t111)
  %t113 = bitcast i8* %t112 to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }*
  %t114 = load { i8*, i8* }, { i8*, i8* }* %t2
  %t115 = load { i8*, i8* }, { i8*, i8* }* %t2
  %t116 = extractvalue { i8*, i8* } %t115, 1
  call void @star_rc_retain(i8* %t116)
  %t117 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t113, i32 0, i32 0
  store { i8*, i8* } %t114, { i8*, i8* }* %t117
  %t118 = load i32, i32* %t17
  %t119 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t113, i32 0, i32 1
  store i32 %t118, i32* %t119
  %t120 = load { i8*, i8* }, { i8*, i8* }* %t18
  %t121 = load { i8*, i8* }, { i8*, i8* }* %t18
  %t122 = extractvalue { i8*, i8* } %t121, 1
  call void @star_rc_retain(i8* %t122)
  %t123 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t113, i32 0, i32 2
  store { i8*, i8* } %t120, { i8*, i8* }* %t123
  %t124 = load { i8*, i8* }, { i8*, i8* }* %t69
  %t125 = load { i8*, i8* }, { i8*, i8* }* %t69
  %t126 = extractvalue { i8*, i8* } %t125, 1
  call void @star_rc_retain(i8* %t126)
  %t127 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t113, i32 0, i32 3
  store { i8*, i8* } %t124, { i8*, i8* }* %t127
  %t128 = load i32, i32* %t79
  %t129 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t113, i32 0, i32 4
  store i32 %t128, i32* %t129
  %t130 = bitcast i32 (i8*)* @closure_3 to i8*
  %t131 = insertvalue { i8*, i8* } undef, i8* %t130, 0
  %t132 = insertvalue { i8*, i8* } %t131, i8* %t112, 1
  store { i8*, i8* } %t132, { i8*, i8* }* %t80
  store i32 50, i32* %t79
  %t133 = load { i8*, i8* }, { i8*, i8* }* %t80
  %t134 = load { i8*, i8* }, { i8*, i8* }* %t80
  %t135 = extractvalue { i8*, i8* } %t134, 1
  call void @star_rc_retain(i8* %t135)
  %t136 = extractvalue { i8*, i8* } %t133, 0
  %t137 = extractvalue { i8*, i8* } %t133, 1
  call void @star_rc_release(i8* %t137)
  %t138 = bitcast i8* %t136 to i32 (i8*)*
  %t139 = call i32 %t138(i8* %t137)
  %t140 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t140, i32 %t139)
  %t163 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* null, i32 1
  %t164 = ptrtoint { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t163 to i64
  %t178 = bitcast void (i8*)* @closure_4_release_env to i8*
  %t179 = call i8* @star_rc_alloc(i64 %t164, i8* %t178)
  %t180 = bitcast i8* %t179 to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }*
  %t181 = load { i8*, i8* }, { i8*, i8* }* %t2
  %t182 = load { i8*, i8* }, { i8*, i8* }* %t2
  %t183 = extractvalue { i8*, i8* } %t182, 1
  call void @star_rc_retain(i8* %t183)
  %t184 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t180, i32 0, i32 0
  store { i8*, i8* } %t181, { i8*, i8* }* %t184
  %t185 = load i32, i32* %t17
  %t186 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t180, i32 0, i32 1
  store i32 %t185, i32* %t186
  %t187 = load { i8*, i8* }, { i8*, i8* }* %t18
  %t188 = load { i8*, i8* }, { i8*, i8* }* %t18
  %t189 = extractvalue { i8*, i8* } %t188, 1
  call void @star_rc_retain(i8* %t189)
  %t190 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t180, i32 0, i32 2
  store { i8*, i8* } %t187, { i8*, i8* }* %t190
  %t191 = load { i8*, i8* }, { i8*, i8* }* %t69
  %t192 = load { i8*, i8* }, { i8*, i8* }* %t69
  %t193 = extractvalue { i8*, i8* } %t192, 1
  call void @star_rc_retain(i8* %t193)
  %t194 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t180, i32 0, i32 3
  store { i8*, i8* } %t191, { i8*, i8* }* %t194
  %t195 = load i32, i32* %t79
  %t196 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t180, i32 0, i32 4
  store i32 %t195, i32* %t196
  %t197 = load { i8*, i8* }, { i8*, i8* }* %t80
  %t198 = load { i8*, i8* }, { i8*, i8* }* %t80
  %t199 = extractvalue { i8*, i8* } %t198, 1
  call void @star_rc_retain(i8* %t199)
  %t200 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t180, i32 0, i32 5
  store { i8*, i8* } %t197, { i8*, i8* }* %t200
  %t201 = bitcast void (i8*)* @closure_4 to i8*
  %t202 = insertvalue { i8*, i8* } undef, i8* %t201, 0
  %t203 = insertvalue { i8*, i8* } %t202, i8* %t179, 1
  store { i8*, i8* } %t203, { i8*, i8* }* %t141
  %t204 = load { i8*, i8* }, { i8*, i8* }* %t141
  %t205 = load { i8*, i8* }, { i8*, i8* }* %t141
  %t206 = extractvalue { i8*, i8* } %t205, 1
  call void @star_rc_retain(i8* %t206)
  %t207 = extractvalue { i8*, i8* } %t204, 0
  %t208 = extractvalue { i8*, i8* } %t204, 1
  call void @star_rc_release(i8* %t208)
  %t209 = bitcast i8* %t207 to void (i8*)*
  call void %t209(i8* %t208)
  %t210 = load { i8*, i8* }, { i8*, i8* }* %t141
  %t211 = extractvalue { i8*, i8* } %t210, 1
  call void @star_rc_release(i8* %t211)
  %t212 = load { i8*, i8* }, { i8*, i8* }* %t80
  %t213 = extractvalue { i8*, i8* } %t212, 1
  call void @star_rc_release(i8* %t213)
  %t214 = load { i8*, i8* }, { i8*, i8* }* %t69
  %t215 = extractvalue { i8*, i8* } %t214, 1
  call void @star_rc_release(i8* %t215)
  %t216 = load { i8*, i8* }, { i8*, i8* }* %t18
  %t217 = extractvalue { i8*, i8* } %t216, 1
  call void @star_rc_release(i8* %t217)
  %t218 = load { i8*, i8* }, { i8*, i8* }* %t2
  %t219 = extractvalue { i8*, i8* } %t218, 1
  call void @star_rc_release(i8* %t219)
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
  %t3 = alloca i32
  store i32 %arg_x, i32* %t3
  %t4 = load i32, i32* %t3
  %t5 = add i32 %t4, 1
  ret i32 %t5
}


define i32 @closure_2(i8* %envp, i32 %arg_x) {
entry:
  %t22 = alloca { i8*, i8* }
  %t25 = alloca i32
  %t26 = alloca i32
  %t19 = bitcast i8* %envp to { { i8*, i8* }, i32 }*
  %t20 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t19, i32 0, i32 0
  %t21 = load { i8*, i8* }, { i8*, i8* }* %t20
  store { i8*, i8* } %t21, { i8*, i8* }* %t22
  %t23 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t19, i32 0, i32 1
  %t24 = load i32, i32* %t23
  store i32 %t24, i32* %t25
  store i32 %arg_x, i32* %t26
  %t27 = load i32, i32* %t26
  %t28 = load i32, i32* %t25
  %t29 = add i32 %t27, %t28
  ret i32 %t29
}


define void @closure_2_release_env(i8* %envp) {
entry:
  %t32 = bitcast i8* %envp to { { i8*, i8* }, i32 }*
  %t33 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t32, i32 0, i32 0
  %t34 = load { i8*, i8* }, { i8*, i8* }* %t33
  %t35 = extractvalue { i8*, i8* } %t34, 1
  call void @star_rc_release(i8* %t35)
  ret void
}


define i32 @fnval_add_one(i8* %envp, i32 %arg_0) {
entry:
  %t63 = call i32 @add_one(i32 %arg_0)
  ret i32 %t63
}


define i32 @closure_3(i8* %envp) {
entry:
  %t84 = alloca { i8*, i8* }
  %t87 = alloca i32
  %t90 = alloca { i8*, i8* }
  %t93 = alloca { i8*, i8* }
  %t96 = alloca i32
  %t81 = bitcast i8* %envp to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }*
  %t82 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t81, i32 0, i32 0
  %t83 = load { i8*, i8* }, { i8*, i8* }* %t82
  store { i8*, i8* } %t83, { i8*, i8* }* %t84
  %t85 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t81, i32 0, i32 1
  %t86 = load i32, i32* %t85
  store i32 %t86, i32* %t87
  %t88 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t81, i32 0, i32 2
  %t89 = load { i8*, i8* }, { i8*, i8* }* %t88
  store { i8*, i8* } %t89, { i8*, i8* }* %t90
  %t91 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t81, i32 0, i32 3
  %t92 = load { i8*, i8* }, { i8*, i8* }* %t91
  store { i8*, i8* } %t92, { i8*, i8* }* %t93
  %t94 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t81, i32 0, i32 4
  %t95 = load i32, i32* %t94
  store i32 %t95, i32* %t96
  %t97 = load i32, i32* %t96
  %t98 = add i32 %t97, 1
  ret i32 %t98
}


define void @closure_3_release_env(i8* %envp) {
entry:
  %t101 = bitcast i8* %envp to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }*
  %t102 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t101, i32 0, i32 0
  %t103 = load { i8*, i8* }, { i8*, i8* }* %t102
  %t104 = extractvalue { i8*, i8* } %t103, 1
  call void @star_rc_release(i8* %t104)
  %t105 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t101, i32 0, i32 2
  %t106 = load { i8*, i8* }, { i8*, i8* }* %t105
  %t107 = extractvalue { i8*, i8* } %t106, 1
  call void @star_rc_release(i8* %t107)
  %t108 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t101, i32 0, i32 3
  %t109 = load { i8*, i8* }, { i8*, i8* }* %t108
  %t110 = extractvalue { i8*, i8* } %t109, 1
  call void @star_rc_release(i8* %t110)
  ret void
}


define void @closure_4(i8* %envp) {
entry:
  %t145 = alloca { i8*, i8* }
  %t148 = alloca i32
  %t151 = alloca { i8*, i8* }
  %t154 = alloca { i8*, i8* }
  %t157 = alloca i32
  %t160 = alloca { i8*, i8* }
  %t142 = bitcast i8* %envp to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }*
  %t143 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t142, i32 0, i32 0
  %t144 = load { i8*, i8* }, { i8*, i8* }* %t143
  store { i8*, i8* } %t144, { i8*, i8* }* %t145
  %t146 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t142, i32 0, i32 1
  %t147 = load i32, i32* %t146
  store i32 %t147, i32* %t148
  %t149 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t142, i32 0, i32 2
  %t150 = load { i8*, i8* }, { i8*, i8* }* %t149
  store { i8*, i8* } %t150, { i8*, i8* }* %t151
  %t152 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t142, i32 0, i32 3
  %t153 = load { i8*, i8* }, { i8*, i8* }* %t152
  store { i8*, i8* } %t153, { i8*, i8* }* %t154
  %t155 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t142, i32 0, i32 4
  %t156 = load i32, i32* %t155
  store i32 %t156, i32* %t157
  %t158 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t142, i32 0, i32 5
  %t159 = load { i8*, i8* }, { i8*, i8* }* %t158
  store { i8*, i8* } %t159, { i8*, i8* }* %t160
  %t161 = getelementptr inbounds { i64, i8*, [23 x i8] }, { i64, i8*, [23 x i8] }* @.str.7, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t161)
  call i32 (i8*, ...) @printf(i8* %t161)
  %t162 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t162)
  ret void
}


define void @closure_4_release_env(i8* %envp) {
entry:
  %t165 = bitcast i8* %envp to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }*
  %t166 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t165, i32 0, i32 0
  %t167 = load { i8*, i8* }, { i8*, i8* }* %t166
  %t168 = extractvalue { i8*, i8* } %t167, 1
  call void @star_rc_release(i8* %t168)
  %t169 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t165, i32 0, i32 2
  %t170 = load { i8*, i8* }, { i8*, i8* }* %t169
  %t171 = extractvalue { i8*, i8* } %t170, 1
  call void @star_rc_release(i8* %t171)
  %t172 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t165, i32 0, i32 3
  %t173 = load { i8*, i8* }, { i8*, i8* }* %t172
  %t174 = extractvalue { i8*, i8* } %t173, 1
  call void @star_rc_release(i8* %t174)
  %t175 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t165, i32 0, i32 5
  %t176 = load { i8*, i8* }, { i8*, i8* }* %t175
  %t177 = extractvalue { i8*, i8* } %t176, 1
  call void @star_rc_release(i8* %t177)
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
