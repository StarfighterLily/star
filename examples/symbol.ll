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

%Option__i32 = type { i32, [1 x i64] }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca i64
  %t6 = alloca i64
  %t31 = alloca i64
  %t36 = alloca i64
  %t61 = alloca i64
  %t66 = alloca i64
  %t112 = alloca i64
  %t114 = alloca i64
  %t130 = alloca i64
  %t163 = alloca i8*
  %t228 = alloca i64
  %t322 = alloca i64
  %t417 = alloca i64
  %t444 = alloca i64
  %t509 = alloca i64
  %t520 = alloca %Option__i32
  %t526 = alloca %Option__i32
  %t530 = alloca %Option__i32
  %t549 = alloca i8*
  %t598 = alloca i64
  %t625 = alloca i64
  %t626 = alloca i1
  %t697 = alloca i64
  %t724 = alloca i64
  %t725 = alloca i1
  %t796 = alloca i64
  %t823 = alloca i64
  %t824 = alloca i1
  %t862 = alloca i1
  %t867 = alloca i64
  %t901 = alloca i64
  %t902 = alloca i1
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t2 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t3 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t3, i32 -1)
  %t4 = load i64, i64* @sym.len
  %t5 = load i8**, i8*** @sym.data
  store i64 0, i64* %t6
  br label %sym_find_cond_0
sym_find_cond_0:
  %t7 = load i64, i64* %t6
  %t8 = icmp slt i64 %t7, %t4
  br i1 %t8, label %sym_find_body_1, label %sym_find_end_3
sym_find_body_1:
  %t9 = getelementptr inbounds i8*, i8** %t5, i64 %t7
  %t10 = load i8*, i8** %t9
  %t11 = call i32 @strcmp(i8* %t10, i8* %t2)
  %t12 = icmp eq i32 %t11, 0
  br i1 %t12, label %sym_find_end_3, label %sym_find_next_2
sym_find_next_2:
  %t13 = add i64 %t7, 1
  store i64 %t13, i64* %t6
  br label %sym_find_cond_0
sym_find_end_3:
  %t14 = load i64, i64* %t6
  %t15 = icmp slt i64 %t14, %t4
  br i1 %t15, label %sym_found_4, label %sym_notfound_5
sym_found_4:
  call void @star_rc_release(i8* %t2)
  br label %sym_done_6
sym_notfound_5:
  %t16 = load i64, i64* @sym.cap
  %t17 = icmp sge i64 %t4, %t16
  br i1 %t17, label %sym_grow_7, label %sym_store_8
sym_grow_7:
  %t18 = mul i64 %t16, 2
  %t19 = icmp sgt i64 %t18, 0
  %t20 = select i1 %t19, i64 %t18, i64 1
  %t21 = mul i64 %t20, 8
  %t22 = call i8* @malloc(i64 %t21)
  %t23 = bitcast i8* %t22 to i8**
  %t24 = icmp sgt i64 %t16, 0
  br i1 %t24, label %sym_copy_9, label %sym_after_copy_10
sym_copy_9:
  %t25 = mul i64 %t4, 8
  %t26 = bitcast i8** %t5 to i8*
  call i8* @memcpy(i8* %t22, i8* %t26, i64 %t25)
  call void @free(i8* %t26)
  br label %sym_after_copy_10
sym_after_copy_10:
  store i8** %t23, i8*** @sym.data
  store i64 %t20, i64* @sym.cap
  br label %sym_store_8
sym_store_8:
  %t27 = load i8**, i8*** @sym.data
  %t28 = getelementptr inbounds i8*, i8** %t27, i64 %t4
  store i8* %t2, i8** %t28
  %t29 = add i64 %t4, 1
  store i64 %t29, i64* @sym.len
  br label %sym_done_6
sym_done_6:
  %t30 = phi i64 [ %t14, %sym_found_4 ], [ %t4, %sym_store_8 ]
  call i32 @ReleaseSemaphore(i8* %t3, i32 1, i32* null)
  store i64 %t30, i64* %t1
  %t32 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t33 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t33, i32 -1)
  %t34 = load i64, i64* @sym.len
  %t35 = load i8**, i8*** @sym.data
  store i64 0, i64* %t36
  br label %sym_find_cond_11
sym_find_cond_11:
  %t37 = load i64, i64* %t36
  %t38 = icmp slt i64 %t37, %t34
  br i1 %t38, label %sym_find_body_12, label %sym_find_end_14
sym_find_body_12:
  %t39 = getelementptr inbounds i8*, i8** %t35, i64 %t37
  %t40 = load i8*, i8** %t39
  %t41 = call i32 @strcmp(i8* %t40, i8* %t32)
  %t42 = icmp eq i32 %t41, 0
  br i1 %t42, label %sym_find_end_14, label %sym_find_next_13
sym_find_next_13:
  %t43 = add i64 %t37, 1
  store i64 %t43, i64* %t36
  br label %sym_find_cond_11
sym_find_end_14:
  %t44 = load i64, i64* %t36
  %t45 = icmp slt i64 %t44, %t34
  br i1 %t45, label %sym_found_15, label %sym_notfound_16
sym_found_15:
  call void @star_rc_release(i8* %t32)
  br label %sym_done_17
sym_notfound_16:
  %t46 = load i64, i64* @sym.cap
  %t47 = icmp sge i64 %t34, %t46
  br i1 %t47, label %sym_grow_18, label %sym_store_19
sym_grow_18:
  %t48 = mul i64 %t46, 2
  %t49 = icmp sgt i64 %t48, 0
  %t50 = select i1 %t49, i64 %t48, i64 1
  %t51 = mul i64 %t50, 8
  %t52 = call i8* @malloc(i64 %t51)
  %t53 = bitcast i8* %t52 to i8**
  %t54 = icmp sgt i64 %t46, 0
  br i1 %t54, label %sym_copy_20, label %sym_after_copy_21
sym_copy_20:
  %t55 = mul i64 %t34, 8
  %t56 = bitcast i8** %t35 to i8*
  call i8* @memcpy(i8* %t52, i8* %t56, i64 %t55)
  call void @free(i8* %t56)
  br label %sym_after_copy_21
sym_after_copy_21:
  store i8** %t53, i8*** @sym.data
  store i64 %t50, i64* @sym.cap
  br label %sym_store_19
sym_store_19:
  %t57 = load i8**, i8*** @sym.data
  %t58 = getelementptr inbounds i8*, i8** %t57, i64 %t34
  store i8* %t32, i8** %t58
  %t59 = add i64 %t34, 1
  store i64 %t59, i64* @sym.len
  br label %sym_done_17
sym_done_17:
  %t60 = phi i64 [ %t44, %sym_found_15 ], [ %t34, %sym_store_19 ]
  call i32 @ReleaseSemaphore(i8* %t33, i32 1, i32* null)
  store i64 %t60, i64* %t31
  %t62 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t63 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t63, i32 -1)
  %t64 = load i64, i64* @sym.len
  %t65 = load i8**, i8*** @sym.data
  store i64 0, i64* %t66
  br label %sym_find_cond_22
sym_find_cond_22:
  %t67 = load i64, i64* %t66
  %t68 = icmp slt i64 %t67, %t64
  br i1 %t68, label %sym_find_body_23, label %sym_find_end_25
sym_find_body_23:
  %t69 = getelementptr inbounds i8*, i8** %t65, i64 %t67
  %t70 = load i8*, i8** %t69
  %t71 = call i32 @strcmp(i8* %t70, i8* %t62)
  %t72 = icmp eq i32 %t71, 0
  br i1 %t72, label %sym_find_end_25, label %sym_find_next_24
sym_find_next_24:
  %t73 = add i64 %t67, 1
  store i64 %t73, i64* %t66
  br label %sym_find_cond_22
sym_find_end_25:
  %t74 = load i64, i64* %t66
  %t75 = icmp slt i64 %t74, %t64
  br i1 %t75, label %sym_found_26, label %sym_notfound_27
sym_found_26:
  call void @star_rc_release(i8* %t62)
  br label %sym_done_28
sym_notfound_27:
  %t76 = load i64, i64* @sym.cap
  %t77 = icmp sge i64 %t64, %t76
  br i1 %t77, label %sym_grow_29, label %sym_store_30
sym_grow_29:
  %t78 = mul i64 %t76, 2
  %t79 = icmp sgt i64 %t78, 0
  %t80 = select i1 %t79, i64 %t78, i64 1
  %t81 = mul i64 %t80, 8
  %t82 = call i8* @malloc(i64 %t81)
  %t83 = bitcast i8* %t82 to i8**
  %t84 = icmp sgt i64 %t76, 0
  br i1 %t84, label %sym_copy_31, label %sym_after_copy_32
sym_copy_31:
  %t85 = mul i64 %t64, 8
  %t86 = bitcast i8** %t65 to i8*
  call i8* @memcpy(i8* %t82, i8* %t86, i64 %t85)
  call void @free(i8* %t86)
  br label %sym_after_copy_32
sym_after_copy_32:
  store i8** %t83, i8*** @sym.data
  store i64 %t80, i64* @sym.cap
  br label %sym_store_30
sym_store_30:
  %t87 = load i8**, i8*** @sym.data
  %t88 = getelementptr inbounds i8*, i8** %t87, i64 %t64
  store i8* %t62, i8** %t88
  %t89 = add i64 %t64, 1
  store i64 %t89, i64* @sym.len
  br label %sym_done_28
sym_done_28:
  %t90 = phi i64 [ %t74, %sym_found_26 ], [ %t64, %sym_store_30 ]
  call i32 @ReleaseSemaphore(i8* %t63, i32 1, i32* null)
  store i64 %t90, i64* %t61
  %t91 = load i64, i64* %t1
  %t92 = load i64, i64* %t31
  %t93 = icmp eq i64 %t91, %t92
  %t94 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.3, i64 0, i64 0
  %t95 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.4, i64 0, i64 0
  %t96 = select i1 %t93, i8* %t94, i8* %t95
  %t97 = getelementptr inbounds [44 x i8], [44 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t97, i8* %t96)
  %t98 = load i64, i64* %t1
  %t99 = load i64, i64* %t61
  %t100 = icmp eq i64 %t98, %t99
  %t101 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.6, i64 0, i64 0
  %t102 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.7, i64 0, i64 0
  %t103 = select i1 %t100, i8* %t101, i8* %t102
  %t104 = getelementptr inbounds [43 x i8], [43 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t104, i8* %t103)
  %t105 = load i64, i64* %t1
  %t106 = load i64, i64* %t61
  %t107 = icmp ne i64 %t105, %t106
  %t108 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.9, i64 0, i64 0
  %t109 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.10, i64 0, i64 0
  %t110 = select i1 %t107, i8* %t108, i8* %t109
  %t111 = getelementptr inbounds [43 x i8], [43 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t111, i8* %t110)
  %t113 = load i64, i64* %t1
  store i64 %t113, i64* %t112
  %t115 = load i64, i64* %t61
  store i64 %t115, i64* %t114
  %t116 = load i64, i64* %t112
  %t117 = sext i32 0 to i64
  %t118 = icmp eq i64 %t116, %t117
  %t119 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.12, i64 0, i64 0
  %t120 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.13, i64 0, i64 0
  %t121 = select i1 %t118, i8* %t119, i8* %t120
  %t122 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t122, i8* %t121)
  %t123 = load i64, i64* %t114
  %t124 = sext i32 1 to i64
  %t125 = icmp eq i64 %t123, %t124
  %t126 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.15, i64 0, i64 0
  %t127 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.16, i64 0, i64 0
  %t128 = select i1 %t125, i8* %t126, i8* %t127
  %t129 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t129, i8* %t128)
  %t131 = load i64, i64* %t114
  store i64 %t131, i64* %t130
  %t132 = load i64, i64* %t130
  %t133 = load i64, i64* %t61
  %t134 = icmp eq i64 %t132, %t133
  %t135 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.18, i64 0, i64 0
  %t136 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.19, i64 0, i64 0
  %t137 = select i1 %t134, i8* %t135, i8* %t136
  %t138 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.20, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t138, i8* %t137)
  %t139 = load i64, i64* %t1
  %t140 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t140, i32 -1)
  %t141 = load i64, i64* @sym.len
  %t142 = icmp sge i64 %t139, 0
  %t143 = icmp slt i64 %t139, %t141
  %t144 = and i1 %t142, %t143
  br i1 %t144, label %sym_name_ok_33, label %sym_name_oob_34
sym_name_ok_33:
  %t145 = load i8**, i8*** @sym.data
  %t146 = getelementptr inbounds i8*, i8** %t145, i64 %t139
  %t147 = load i8*, i8** %t146
  call void @star_rc_retain(i8* %t147)
  br label %sym_name_end_35
sym_name_oob_34:
  %t148 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t148
  br label %sym_name_end_35
sym_name_end_35:
  %t149 = phi i8* [ %t147, %sym_name_ok_33 ], [ %t148, %sym_name_oob_34 ]
  call i32 @ReleaseSemaphore(i8* %t140, i32 1, i32* null)
  call void @star_rc_release(i8* %t149)
  %t150 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.21, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t150, i8* %t149)
  %t151 = load i64, i64* %t61
  %t152 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t152, i32 -1)
  %t153 = load i64, i64* @sym.len
  %t154 = icmp sge i64 %t151, 0
  %t155 = icmp slt i64 %t151, %t153
  %t156 = and i1 %t154, %t155
  br i1 %t156, label %sym_name_ok_36, label %sym_name_oob_37
sym_name_ok_36:
  %t157 = load i8**, i8*** @sym.data
  %t158 = getelementptr inbounds i8*, i8** %t157, i64 %t151
  %t159 = load i8*, i8** %t158
  call void @star_rc_retain(i8* %t159)
  br label %sym_name_end_38
sym_name_oob_37:
  %t160 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t160
  br label %sym_name_end_38
sym_name_end_38:
  %t161 = phi i8* [ %t159, %sym_name_ok_36 ], [ %t160, %sym_name_oob_37 ]
  call i32 @ReleaseSemaphore(i8* %t152, i32 1, i32* null)
  call void @star_rc_release(i8* %t161)
  %t162 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t162, i8* %t161)
  store i8* null, i8** %t163
  %t164 = getelementptr i64, i64* null, i32 1
  %t165 = ptrtoint i64* %t164 to i64
  %t166 = getelementptr i32, i32* null, i32 1
  %t167 = ptrtoint i32* %t166 to i64
  %t168 = load i8*, i8** %t163
  %t169 = icmp eq i8* %t168, null
  br i1 %t169, label %map_cow_alloc_39, label %map_cow_check_40
map_cow_alloc_39:
  %t177 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t178 = call i8* @star_rc_alloc(i64 32, i8* %t177)
  %t179 = bitcast i8* %t178 to { i64*, i32*, i64, i64 }*
  %t180 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t179, i32 0, i32 0
  store i64* null, i64** %t180
  %t181 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t179, i32 0, i32 1
  store i32* null, i32** %t181
  %t182 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t179, i32 0, i32 2
  store i64 0, i64* %t182
  %t183 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t179, i32 0, i32 3
  store i64 0, i64* %t183
  store i8* %t178, i8** %t163
  br label %map_cow_done_41
map_cow_check_40:
  %t184 = getelementptr inbounds i8, i8* %t168, i64 -16
  %t185 = bitcast i8* %t184 to i64*
  %t186 = load atomic i64, i64* %t185 seq_cst, align 8
  %t187 = icmp eq i64 %t186, 1
  br i1 %t187, label %map_cow_done_41, label %map_cow_clone_42
map_cow_clone_42:
  %t188 = bitcast i8* %t168 to { i64*, i32*, i64, i64 }*
  %t189 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t188, i32 0, i32 0
  %t190 = load i64*, i64** %t189
  %t191 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t188, i32 0, i32 1
  %t192 = load i32*, i32** %t191
  %t193 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t188, i32 0, i32 2
  %t194 = load i64, i64* %t193
  %t195 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t188, i32 0, i32 3
  %t196 = load i64, i64* %t195
  %t197 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t198 = call i8* @star_rc_alloc(i64 32, i8* %t197)
  %t199 = bitcast i8* %t198 to { i64*, i32*, i64, i64 }*
  %t200 = mul i64 %t196, %t165
  %t201 = call i8* @malloc(i64 %t200)
  %t202 = bitcast i8* %t201 to i64*
  %t203 = mul i64 %t196, %t167
  %t204 = call i8* @malloc(i64 %t203)
  %t205 = bitcast i8* %t204 to i32*
  %t206 = icmp sgt i64 %t194, 0
  br i1 %t206, label %map_cow_copy_43, label %map_cow_after_copy_44
map_cow_copy_43:
  %t207 = mul i64 %t194, %t165
  %t208 = bitcast i64* %t190 to i8*
  call i8* @memcpy(i8* %t201, i8* %t208, i64 %t207)
  %t209 = mul i64 %t194, %t167
  %t210 = bitcast i32* %t192 to i8*
  call i8* @memcpy(i8* %t204, i8* %t210, i64 %t209)
  br label %map_cow_after_copy_44
map_cow_after_copy_44:
  %t211 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t199, i32 0, i32 0
  store i64* %t202, i64** %t211
  %t212 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t199, i32 0, i32 1
  store i32* %t205, i32** %t212
  %t213 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t199, i32 0, i32 2
  store i64 %t194, i64* %t213
  %t214 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t199, i32 0, i32 3
  store i64 %t196, i64* %t214
  call void @star_rc_release(i8* %t168)
  store i8* %t198, i8** %t163
  br label %map_cow_done_41
map_cow_done_41:
  %t215 = load i8*, i8** %t163
  %t216 = bitcast i8* %t215 to { i64*, i32*, i64, i64 }*
  %t217 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t216, i32 0, i32 0
  %t218 = load i64*, i64** %t217
  %t219 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t216, i32 0, i32 1
  %t220 = load i32*, i32** %t219
  %t221 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t216, i32 0, i32 2
  %t222 = load i64, i64* %t221
  %t223 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t216, i32 0, i32 3
  %t224 = load i64, i64* %t1
  %t225 = load i64, i64* %t221
  %t226 = load i64*, i64** %t217
  store i64 0, i64* %t228
  br label %map_find_cond_45
map_find_cond_45:
  %t229 = load i64, i64* %t228
  %t230 = icmp slt i64 %t229, %t225
  br i1 %t230, label %map_find_body_46, label %map_find_end_49
map_find_body_46:
  %t231 = getelementptr inbounds i64, i64* %t226, i64 %t229
  %t232 = load i64, i64* %t231
  br label %map_find_eq_check_47
map_find_eq_check_47:
  %t233 = call i1 @eq_symbol(i64 %t232, i64 %t224)
  br i1 %t233, label %map_find_end_49, label %map_find_next_48
map_find_next_48:
  %t234 = add i64 %t229, 1
  store i64 %t234, i64* %t228
  br label %map_find_cond_45
map_find_end_49:
  %t235 = load i64, i64* %t228
  %t236 = icmp slt i64 %t235, %t225
  br i1 %t236, label %map_insert_overwrite_50, label %map_insert_new_51
map_insert_overwrite_50:
  %t237 = load i32*, i32** %t219
  %t238 = getelementptr inbounds i32, i32* %t237, i64 %t235
  store i32 100, i32* %t238
  br label %map_insert_after_52
map_insert_new_51:
  %t239 = load i64, i64* %t223
  %t240 = icmp sge i64 %t225, %t239
  br i1 %t240, label %map_insert_grow_53, label %map_insert_store_54
map_insert_grow_53:
  %t241 = mul i64 %t239, 2
  %t242 = icmp sgt i64 %t241, 0
  %t243 = select i1 %t242, i64 %t241, i64 1
  %t244 = getelementptr i64, i64* null, i32 1
  %t245 = ptrtoint i64* %t244 to i64
  %t246 = mul i64 %t243, %t245
  %t247 = call i8* @malloc(i64 %t246)
  %t248 = bitcast i8* %t247 to i64*
  %t249 = getelementptr i32, i32* null, i32 1
  %t250 = ptrtoint i32* %t249 to i64
  %t251 = mul i64 %t243, %t250
  %t252 = call i8* @malloc(i64 %t251)
  %t253 = bitcast i8* %t252 to i32*
  %t254 = icmp sgt i64 %t239, 0
  br i1 %t254, label %map_insert_copy_55, label %map_insert_after_copy_56
map_insert_copy_55:
  %t255 = load i64*, i64** %t217
  %t256 = mul i64 %t225, %t245
  %t257 = bitcast i64* %t255 to i8*
  call i8* @memcpy(i8* %t247, i8* %t257, i64 %t256)
  call void @free(i8* %t257)
  %t258 = load i32*, i32** %t219
  %t259 = mul i64 %t225, %t250
  %t260 = bitcast i32* %t258 to i8*
  call i8* @memcpy(i8* %t252, i8* %t260, i64 %t259)
  call void @free(i8* %t260)
  br label %map_insert_after_copy_56
map_insert_after_copy_56:
  store i64* %t248, i64** %t217
  store i32* %t253, i32** %t219
  store i64 %t243, i64* %t223
  br label %map_insert_store_54
map_insert_store_54:
  %t261 = load i64*, i64** %t217
  %t262 = load i32*, i32** %t219
  %t263 = getelementptr inbounds i64, i64* %t261, i64 %t225
  store i64 %t224, i64* %t263
  %t264 = getelementptr inbounds i32, i32* %t262, i64 %t225
  store i32 100, i32* %t264
  %t265 = add i64 %t225, 1
  store i64 %t265, i64* %t221
  br label %map_insert_after_52
map_insert_after_52:
  %t266 = getelementptr i64, i64* null, i32 1
  %t267 = ptrtoint i64* %t266 to i64
  %t268 = getelementptr i32, i32* null, i32 1
  %t269 = ptrtoint i32* %t268 to i64
  %t270 = load i8*, i8** %t163
  %t271 = icmp eq i8* %t270, null
  br i1 %t271, label %map_cow_alloc_57, label %map_cow_check_58
map_cow_alloc_57:
  %t272 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t273 = call i8* @star_rc_alloc(i64 32, i8* %t272)
  %t274 = bitcast i8* %t273 to { i64*, i32*, i64, i64 }*
  %t275 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t274, i32 0, i32 0
  store i64* null, i64** %t275
  %t276 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t274, i32 0, i32 1
  store i32* null, i32** %t276
  %t277 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t274, i32 0, i32 2
  store i64 0, i64* %t277
  %t278 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t274, i32 0, i32 3
  store i64 0, i64* %t278
  store i8* %t273, i8** %t163
  br label %map_cow_done_59
map_cow_check_58:
  %t279 = getelementptr inbounds i8, i8* %t270, i64 -16
  %t280 = bitcast i8* %t279 to i64*
  %t281 = load atomic i64, i64* %t280 seq_cst, align 8
  %t282 = icmp eq i64 %t281, 1
  br i1 %t282, label %map_cow_done_59, label %map_cow_clone_60
map_cow_clone_60:
  %t283 = bitcast i8* %t270 to { i64*, i32*, i64, i64 }*
  %t284 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t283, i32 0, i32 0
  %t285 = load i64*, i64** %t284
  %t286 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t283, i32 0, i32 1
  %t287 = load i32*, i32** %t286
  %t288 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t283, i32 0, i32 2
  %t289 = load i64, i64* %t288
  %t290 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t283, i32 0, i32 3
  %t291 = load i64, i64* %t290
  %t292 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t293 = call i8* @star_rc_alloc(i64 32, i8* %t292)
  %t294 = bitcast i8* %t293 to { i64*, i32*, i64, i64 }*
  %t295 = mul i64 %t291, %t267
  %t296 = call i8* @malloc(i64 %t295)
  %t297 = bitcast i8* %t296 to i64*
  %t298 = mul i64 %t291, %t269
  %t299 = call i8* @malloc(i64 %t298)
  %t300 = bitcast i8* %t299 to i32*
  %t301 = icmp sgt i64 %t289, 0
  br i1 %t301, label %map_cow_copy_61, label %map_cow_after_copy_62
map_cow_copy_61:
  %t302 = mul i64 %t289, %t267
  %t303 = bitcast i64* %t285 to i8*
  call i8* @memcpy(i8* %t296, i8* %t303, i64 %t302)
  %t304 = mul i64 %t289, %t269
  %t305 = bitcast i32* %t287 to i8*
  call i8* @memcpy(i8* %t299, i8* %t305, i64 %t304)
  br label %map_cow_after_copy_62
map_cow_after_copy_62:
  %t306 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t294, i32 0, i32 0
  store i64* %t297, i64** %t306
  %t307 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t294, i32 0, i32 1
  store i32* %t300, i32** %t307
  %t308 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t294, i32 0, i32 2
  store i64 %t289, i64* %t308
  %t309 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t294, i32 0, i32 3
  store i64 %t291, i64* %t309
  call void @star_rc_release(i8* %t270)
  store i8* %t293, i8** %t163
  br label %map_cow_done_59
map_cow_done_59:
  %t310 = load i8*, i8** %t163
  %t311 = bitcast i8* %t310 to { i64*, i32*, i64, i64 }*
  %t312 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t311, i32 0, i32 0
  %t313 = load i64*, i64** %t312
  %t314 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t311, i32 0, i32 1
  %t315 = load i32*, i32** %t314
  %t316 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t311, i32 0, i32 2
  %t317 = load i64, i64* %t316
  %t318 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t311, i32 0, i32 3
  %t319 = load i64, i64* %t61
  %t320 = load i64, i64* %t316
  %t321 = load i64*, i64** %t312
  store i64 0, i64* %t322
  br label %map_find_cond_63
map_find_cond_63:
  %t323 = load i64, i64* %t322
  %t324 = icmp slt i64 %t323, %t320
  br i1 %t324, label %map_find_body_64, label %map_find_end_67
map_find_body_64:
  %t325 = getelementptr inbounds i64, i64* %t321, i64 %t323
  %t326 = load i64, i64* %t325
  br label %map_find_eq_check_65
map_find_eq_check_65:
  %t327 = call i1 @eq_symbol(i64 %t326, i64 %t319)
  br i1 %t327, label %map_find_end_67, label %map_find_next_66
map_find_next_66:
  %t328 = add i64 %t323, 1
  store i64 %t328, i64* %t322
  br label %map_find_cond_63
map_find_end_67:
  %t329 = load i64, i64* %t322
  %t330 = icmp slt i64 %t329, %t320
  br i1 %t330, label %map_insert_overwrite_68, label %map_insert_new_69
map_insert_overwrite_68:
  %t331 = load i32*, i32** %t314
  %t332 = getelementptr inbounds i32, i32* %t331, i64 %t329
  store i32 40, i32* %t332
  br label %map_insert_after_70
map_insert_new_69:
  %t333 = load i64, i64* %t318
  %t334 = icmp sge i64 %t320, %t333
  br i1 %t334, label %map_insert_grow_71, label %map_insert_store_72
map_insert_grow_71:
  %t335 = mul i64 %t333, 2
  %t336 = icmp sgt i64 %t335, 0
  %t337 = select i1 %t336, i64 %t335, i64 1
  %t338 = getelementptr i64, i64* null, i32 1
  %t339 = ptrtoint i64* %t338 to i64
  %t340 = mul i64 %t337, %t339
  %t341 = call i8* @malloc(i64 %t340)
  %t342 = bitcast i8* %t341 to i64*
  %t343 = getelementptr i32, i32* null, i32 1
  %t344 = ptrtoint i32* %t343 to i64
  %t345 = mul i64 %t337, %t344
  %t346 = call i8* @malloc(i64 %t345)
  %t347 = bitcast i8* %t346 to i32*
  %t348 = icmp sgt i64 %t333, 0
  br i1 %t348, label %map_insert_copy_73, label %map_insert_after_copy_74
map_insert_copy_73:
  %t349 = load i64*, i64** %t312
  %t350 = mul i64 %t320, %t339
  %t351 = bitcast i64* %t349 to i8*
  call i8* @memcpy(i8* %t341, i8* %t351, i64 %t350)
  call void @free(i8* %t351)
  %t352 = load i32*, i32** %t314
  %t353 = mul i64 %t320, %t344
  %t354 = bitcast i32* %t352 to i8*
  call i8* @memcpy(i8* %t346, i8* %t354, i64 %t353)
  call void @free(i8* %t354)
  br label %map_insert_after_copy_74
map_insert_after_copy_74:
  store i64* %t342, i64** %t312
  store i32* %t347, i32** %t314
  store i64 %t337, i64* %t318
  br label %map_insert_store_72
map_insert_store_72:
  %t355 = load i64*, i64** %t312
  %t356 = load i32*, i32** %t314
  %t357 = getelementptr inbounds i64, i64* %t355, i64 %t320
  store i64 %t319, i64* %t357
  %t358 = getelementptr inbounds i32, i32* %t356, i64 %t320
  store i32 40, i32* %t358
  %t359 = add i64 %t320, 1
  store i64 %t359, i64* %t316
  br label %map_insert_after_70
map_insert_after_70:
  %t360 = getelementptr i64, i64* null, i32 1
  %t361 = ptrtoint i64* %t360 to i64
  %t362 = getelementptr i32, i32* null, i32 1
  %t363 = ptrtoint i32* %t362 to i64
  %t364 = load i8*, i8** %t163
  %t365 = icmp eq i8* %t364, null
  br i1 %t365, label %map_cow_alloc_75, label %map_cow_check_76
map_cow_alloc_75:
  %t366 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t367 = call i8* @star_rc_alloc(i64 32, i8* %t366)
  %t368 = bitcast i8* %t367 to { i64*, i32*, i64, i64 }*
  %t369 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t368, i32 0, i32 0
  store i64* null, i64** %t369
  %t370 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t368, i32 0, i32 1
  store i32* null, i32** %t370
  %t371 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t368, i32 0, i32 2
  store i64 0, i64* %t371
  %t372 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t368, i32 0, i32 3
  store i64 0, i64* %t372
  store i8* %t367, i8** %t163
  br label %map_cow_done_77
map_cow_check_76:
  %t373 = getelementptr inbounds i8, i8* %t364, i64 -16
  %t374 = bitcast i8* %t373 to i64*
  %t375 = load atomic i64, i64* %t374 seq_cst, align 8
  %t376 = icmp eq i64 %t375, 1
  br i1 %t376, label %map_cow_done_77, label %map_cow_clone_78
map_cow_clone_78:
  %t377 = bitcast i8* %t364 to { i64*, i32*, i64, i64 }*
  %t378 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t377, i32 0, i32 0
  %t379 = load i64*, i64** %t378
  %t380 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t377, i32 0, i32 1
  %t381 = load i32*, i32** %t380
  %t382 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t377, i32 0, i32 2
  %t383 = load i64, i64* %t382
  %t384 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t377, i32 0, i32 3
  %t385 = load i64, i64* %t384
  %t386 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t387 = call i8* @star_rc_alloc(i64 32, i8* %t386)
  %t388 = bitcast i8* %t387 to { i64*, i32*, i64, i64 }*
  %t389 = mul i64 %t385, %t361
  %t390 = call i8* @malloc(i64 %t389)
  %t391 = bitcast i8* %t390 to i64*
  %t392 = mul i64 %t385, %t363
  %t393 = call i8* @malloc(i64 %t392)
  %t394 = bitcast i8* %t393 to i32*
  %t395 = icmp sgt i64 %t383, 0
  br i1 %t395, label %map_cow_copy_79, label %map_cow_after_copy_80
map_cow_copy_79:
  %t396 = mul i64 %t383, %t361
  %t397 = bitcast i64* %t379 to i8*
  call i8* @memcpy(i8* %t390, i8* %t397, i64 %t396)
  %t398 = mul i64 %t383, %t363
  %t399 = bitcast i32* %t381 to i8*
  call i8* @memcpy(i8* %t393, i8* %t399, i64 %t398)
  br label %map_cow_after_copy_80
map_cow_after_copy_80:
  %t400 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t388, i32 0, i32 0
  store i64* %t391, i64** %t400
  %t401 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t388, i32 0, i32 1
  store i32* %t394, i32** %t401
  %t402 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t388, i32 0, i32 2
  store i64 %t383, i64* %t402
  %t403 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t388, i32 0, i32 3
  store i64 %t385, i64* %t403
  call void @star_rc_release(i8* %t364)
  store i8* %t387, i8** %t163
  br label %map_cow_done_77
map_cow_done_77:
  %t404 = load i8*, i8** %t163
  %t405 = bitcast i8* %t404 to { i64*, i32*, i64, i64 }*
  %t406 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t405, i32 0, i32 0
  %t407 = load i64*, i64** %t406
  %t408 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t405, i32 0, i32 1
  %t409 = load i32*, i32** %t408
  %t410 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t405, i32 0, i32 2
  %t411 = load i64, i64* %t410
  %t412 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t405, i32 0, i32 3
  %t413 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.23, i64 0, i32 2, i64 0
  %t414 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t414, i32 -1)
  %t415 = load i64, i64* @sym.len
  %t416 = load i8**, i8*** @sym.data
  store i64 0, i64* %t417
  br label %sym_find_cond_81
sym_find_cond_81:
  %t418 = load i64, i64* %t417
  %t419 = icmp slt i64 %t418, %t415
  br i1 %t419, label %sym_find_body_82, label %sym_find_end_84
sym_find_body_82:
  %t420 = getelementptr inbounds i8*, i8** %t416, i64 %t418
  %t421 = load i8*, i8** %t420
  %t422 = call i32 @strcmp(i8* %t421, i8* %t413)
  %t423 = icmp eq i32 %t422, 0
  br i1 %t423, label %sym_find_end_84, label %sym_find_next_83
sym_find_next_83:
  %t424 = add i64 %t418, 1
  store i64 %t424, i64* %t417
  br label %sym_find_cond_81
sym_find_end_84:
  %t425 = load i64, i64* %t417
  %t426 = icmp slt i64 %t425, %t415
  br i1 %t426, label %sym_found_85, label %sym_notfound_86
sym_found_85:
  call void @star_rc_release(i8* %t413)
  br label %sym_done_87
sym_notfound_86:
  %t427 = load i64, i64* @sym.cap
  %t428 = icmp sge i64 %t415, %t427
  br i1 %t428, label %sym_grow_88, label %sym_store_89
sym_grow_88:
  %t429 = mul i64 %t427, 2
  %t430 = icmp sgt i64 %t429, 0
  %t431 = select i1 %t430, i64 %t429, i64 1
  %t432 = mul i64 %t431, 8
  %t433 = call i8* @malloc(i64 %t432)
  %t434 = bitcast i8* %t433 to i8**
  %t435 = icmp sgt i64 %t427, 0
  br i1 %t435, label %sym_copy_90, label %sym_after_copy_91
sym_copy_90:
  %t436 = mul i64 %t415, 8
  %t437 = bitcast i8** %t416 to i8*
  call i8* @memcpy(i8* %t433, i8* %t437, i64 %t436)
  call void @free(i8* %t437)
  br label %sym_after_copy_91
sym_after_copy_91:
  store i8** %t434, i8*** @sym.data
  store i64 %t431, i64* @sym.cap
  br label %sym_store_89
sym_store_89:
  %t438 = load i8**, i8*** @sym.data
  %t439 = getelementptr inbounds i8*, i8** %t438, i64 %t415
  store i8* %t413, i8** %t439
  %t440 = add i64 %t415, 1
  store i64 %t440, i64* @sym.len
  br label %sym_done_87
sym_done_87:
  %t441 = phi i64 [ %t425, %sym_found_85 ], [ %t415, %sym_store_89 ]
  call i32 @ReleaseSemaphore(i8* %t414, i32 1, i32* null)
  %t442 = load i64, i64* %t410
  %t443 = load i64*, i64** %t406
  store i64 0, i64* %t444
  br label %map_find_cond_92
map_find_cond_92:
  %t445 = load i64, i64* %t444
  %t446 = icmp slt i64 %t445, %t442
  br i1 %t446, label %map_find_body_93, label %map_find_end_96
map_find_body_93:
  %t447 = getelementptr inbounds i64, i64* %t443, i64 %t445
  %t448 = load i64, i64* %t447
  br label %map_find_eq_check_94
map_find_eq_check_94:
  %t449 = call i1 @eq_symbol(i64 %t448, i64 %t441)
  br i1 %t449, label %map_find_end_96, label %map_find_next_95
map_find_next_95:
  %t450 = add i64 %t445, 1
  store i64 %t450, i64* %t444
  br label %map_find_cond_92
map_find_end_96:
  %t451 = load i64, i64* %t444
  %t452 = icmp slt i64 %t451, %t442
  br i1 %t452, label %map_insert_overwrite_97, label %map_insert_new_98
map_insert_overwrite_97:
  %t453 = load i32*, i32** %t408
  %t454 = getelementptr inbounds i32, i32* %t453, i64 %t451
  store i32 80, i32* %t454
  br label %map_insert_after_99
map_insert_new_98:
  %t455 = load i64, i64* %t412
  %t456 = icmp sge i64 %t442, %t455
  br i1 %t456, label %map_insert_grow_100, label %map_insert_store_101
map_insert_grow_100:
  %t457 = mul i64 %t455, 2
  %t458 = icmp sgt i64 %t457, 0
  %t459 = select i1 %t458, i64 %t457, i64 1
  %t460 = getelementptr i64, i64* null, i32 1
  %t461 = ptrtoint i64* %t460 to i64
  %t462 = mul i64 %t459, %t461
  %t463 = call i8* @malloc(i64 %t462)
  %t464 = bitcast i8* %t463 to i64*
  %t465 = getelementptr i32, i32* null, i32 1
  %t466 = ptrtoint i32* %t465 to i64
  %t467 = mul i64 %t459, %t466
  %t468 = call i8* @malloc(i64 %t467)
  %t469 = bitcast i8* %t468 to i32*
  %t470 = icmp sgt i64 %t455, 0
  br i1 %t470, label %map_insert_copy_102, label %map_insert_after_copy_103
map_insert_copy_102:
  %t471 = load i64*, i64** %t406
  %t472 = mul i64 %t442, %t461
  %t473 = bitcast i64* %t471 to i8*
  call i8* @memcpy(i8* %t463, i8* %t473, i64 %t472)
  call void @free(i8* %t473)
  %t474 = load i32*, i32** %t408
  %t475 = mul i64 %t442, %t466
  %t476 = bitcast i32* %t474 to i8*
  call i8* @memcpy(i8* %t468, i8* %t476, i64 %t475)
  call void @free(i8* %t476)
  br label %map_insert_after_copy_103
map_insert_after_copy_103:
  store i64* %t464, i64** %t406
  store i32* %t469, i32** %t408
  store i64 %t459, i64* %t412
  br label %map_insert_store_101
map_insert_store_101:
  %t477 = load i64*, i64** %t406
  %t478 = load i32*, i32** %t408
  %t479 = getelementptr inbounds i64, i64* %t477, i64 %t442
  store i64 %t441, i64* %t479
  %t480 = getelementptr inbounds i32, i32* %t478, i64 %t442
  store i32 80, i32* %t480
  %t481 = add i64 %t442, 1
  store i64 %t481, i64* %t410
  br label %map_insert_after_99
map_insert_after_99:
  %t482 = load i8*, i8** %t163
  %t483 = icmp eq i8* %t482, null
  br i1 %t483, label %map_read_null_104, label %map_read_real_105
map_read_null_104:
  br label %map_read_end_106
map_read_real_105:
  %t484 = bitcast i8* %t482 to { i64*, i32*, i64, i64 }*
  %t485 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t484, i32 0, i32 0
  %t486 = load i64*, i64** %t485
  %t487 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t484, i32 0, i32 1
  %t488 = load i32*, i32** %t487
  %t489 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t484, i32 0, i32 2
  %t490 = load i64, i64* %t489
  br label %map_read_end_106
map_read_end_106:
  %t491 = phi i64* [ null, %map_read_null_104 ], [ %t486, %map_read_real_105 ]
  %t492 = phi i32* [ null, %map_read_null_104 ], [ %t488, %map_read_real_105 ]
  %t493 = phi i64 [ 0, %map_read_null_104 ], [ %t490, %map_read_real_105 ]
  %t494 = trunc i64 %t493 to i32
  %t495 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.24, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t495, i32 %t494)
  %t496 = load i64, i64* %t1
  %t497 = load i8*, i8** %t163
  %t498 = icmp eq i8* %t497, null
  br i1 %t498, label %map_read_null_107, label %map_read_real_108
map_read_null_107:
  br label %map_read_end_109
map_read_real_108:
  %t499 = bitcast i8* %t497 to { i64*, i32*, i64, i64 }*
  %t500 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t499, i32 0, i32 0
  %t501 = load i64*, i64** %t500
  %t502 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t499, i32 0, i32 1
  %t503 = load i32*, i32** %t502
  %t504 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t499, i32 0, i32 2
  %t505 = load i64, i64* %t504
  br label %map_read_end_109
map_read_end_109:
  %t506 = phi i64* [ null, %map_read_null_107 ], [ %t501, %map_read_real_108 ]
  %t507 = phi i32* [ null, %map_read_null_107 ], [ %t503, %map_read_real_108 ]
  %t508 = phi i64 [ 0, %map_read_null_107 ], [ %t505, %map_read_real_108 ]
  store i64 0, i64* %t509
  br label %map_find_cond_110
map_find_cond_110:
  %t510 = load i64, i64* %t509
  %t511 = icmp slt i64 %t510, %t508
  br i1 %t511, label %map_find_body_111, label %map_find_end_114
map_find_body_111:
  %t512 = getelementptr inbounds i64, i64* %t506, i64 %t510
  %t513 = load i64, i64* %t512
  br label %map_find_eq_check_112
map_find_eq_check_112:
  %t514 = call i1 @eq_symbol(i64 %t513, i64 %t496)
  br i1 %t514, label %map_find_end_114, label %map_find_next_113
map_find_next_113:
  %t515 = add i64 %t510, 1
  store i64 %t515, i64* %t509
  br label %map_find_cond_110
map_find_end_114:
  %t516 = load i64, i64* %t509
  %t517 = icmp slt i64 %t516, %t508
  br i1 %t517, label %map_get_some_115, label %map_get_none_116
map_get_some_115:
  %t518 = getelementptr inbounds i32, i32* %t507, i64 %t516
  %t519 = load i32, i32* %t518
  %t521 = getelementptr inbounds %Option__i32, %Option__i32* %t520, i32 0, i32 0
  store i32 1, i32* %t521
  %t522 = getelementptr inbounds %Option__i32, %Option__i32* %t520, i32 0, i32 1
  %t523 = bitcast [1 x i64]* %t522 to { i32 }*
  %t524 = getelementptr inbounds { i32 }, { i32 }* %t523, i32 0, i32 0
  store i32 %t519, i32* %t524
  %t525 = load %Option__i32, %Option__i32* %t520
  br label %map_get_end_117
map_get_none_116:
  %t527 = getelementptr inbounds %Option__i32, %Option__i32* %t526, i32 0, i32 0
  store i32 0, i32* %t527
  %t528 = load %Option__i32, %Option__i32* %t526
  br label %map_get_end_117
map_get_end_117:
  %t529 = phi %Option__i32 [ %t525, %map_get_some_115 ], [ %t528, %map_get_none_116 ]
  store %Option__i32 %t529, %Option__i32* %t530
  br label %match_scrutinee_532
match_scrutinee_532:
  %t536 = getelementptr inbounds %Option__i32, %Option__i32* %t530, i32 0, i32 0
  %t537 = load i32, i32* %t536
  %t535 = icmp eq i32 %t537, 1
  br i1 %t535, label %match_then_0_533, label %match_next_0_534
match_then_0_533:
  %t538 = getelementptr inbounds %Option__i32, %Option__i32* %t530, i32 0, i32 1
  %t539 = bitcast [1 x i64]* %t538 to { i32 }*
  %t540 = getelementptr inbounds { i32 }, { i32 }* %t539, i32 0, i32 0
  %t541 = load i32, i32* %t540
  %t542 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.25, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t542, i32 %t541)
  br label %match_end_531
match_next_0_534:
  %t546 = getelementptr inbounds %Option__i32, %Option__i32* %t530, i32 0, i32 0
  %t547 = load i32, i32* %t546
  %t545 = icmp eq i32 %t547, 0
  br i1 %t545, label %match_then_1_543, label %match_next_1_544
match_then_1_543:
  %t548 = getelementptr inbounds { i64, i8*, [18 x i8] }, { i64, i8*, [18 x i8] }* @.str.26, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t548)
  call i32 (i8*, ...) @printf(i8* %t548)
  br label %match_end_531
match_next_1_544:
  br label %match_end_531
match_end_531:
  store i8* null, i8** %t549
  %t550 = getelementptr i64, i64* null, i32 1
  %t551 = ptrtoint i64* %t550 to i64
  %t552 = load i8*, i8** %t549
  %t553 = icmp eq i8* %t552, null
  br i1 %t553, label %set_cow_alloc_118, label %set_cow_check_119
set_cow_alloc_118:
  %t558 = bitcast void (i8*)* @set_release_symbol to i8*
  %t559 = call i8* @star_rc_alloc(i64 24, i8* %t558)
  %t560 = bitcast i8* %t559 to { i64*, i64, i64 }*
  %t561 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t560, i32 0, i32 0
  store i64* null, i64** %t561
  %t562 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t560, i32 0, i32 1
  store i64 0, i64* %t562
  %t563 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t560, i32 0, i32 2
  store i64 0, i64* %t563
  store i8* %t559, i8** %t549
  br label %set_cow_done_120
set_cow_check_119:
  %t564 = getelementptr inbounds i8, i8* %t552, i64 -16
  %t565 = bitcast i8* %t564 to i64*
  %t566 = load atomic i64, i64* %t565 seq_cst, align 8
  %t567 = icmp eq i64 %t566, 1
  br i1 %t567, label %set_cow_done_120, label %set_cow_clone_121
set_cow_clone_121:
  %t568 = bitcast i8* %t552 to { i64*, i64, i64 }*
  %t569 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t568, i32 0, i32 0
  %t570 = load i64*, i64** %t569
  %t571 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t568, i32 0, i32 1
  %t572 = load i64, i64* %t571
  %t573 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t568, i32 0, i32 2
  %t574 = load i64, i64* %t573
  %t575 = bitcast void (i8*)* @set_release_symbol to i8*
  %t576 = call i8* @star_rc_alloc(i64 24, i8* %t575)
  %t577 = bitcast i8* %t576 to { i64*, i64, i64 }*
  %t578 = mul i64 %t574, %t551
  %t579 = call i8* @malloc(i64 %t578)
  %t580 = bitcast i8* %t579 to i64*
  %t581 = icmp sgt i64 %t572, 0
  br i1 %t581, label %set_cow_copy_122, label %set_cow_after_copy_123
set_cow_copy_122:
  %t582 = mul i64 %t572, %t551
  %t583 = bitcast i64* %t570 to i8*
  call i8* @memcpy(i8* %t579, i8* %t583, i64 %t582)
  br label %set_cow_after_copy_123
set_cow_after_copy_123:
  %t584 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t577, i32 0, i32 0
  store i64* %t580, i64** %t584
  %t585 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t577, i32 0, i32 1
  store i64 %t572, i64* %t585
  %t586 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t577, i32 0, i32 2
  store i64 %t574, i64* %t586
  call void @star_rc_release(i8* %t552)
  store i8* %t576, i8** %t549
  br label %set_cow_done_120
set_cow_done_120:
  %t587 = load i8*, i8** %t549
  %t588 = bitcast i8* %t587 to { i64*, i64, i64 }*
  %t589 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t588, i32 0, i32 0
  %t590 = load i64*, i64** %t589
  %t591 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t588, i32 0, i32 1
  %t592 = load i64, i64* %t591
  %t593 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t588, i32 0, i32 2
  %t594 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.27, i64 0, i32 2, i64 0
  %t595 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t595, i32 -1)
  %t596 = load i64, i64* @sym.len
  %t597 = load i8**, i8*** @sym.data
  store i64 0, i64* %t598
  br label %sym_find_cond_124
sym_find_cond_124:
  %t599 = load i64, i64* %t598
  %t600 = icmp slt i64 %t599, %t596
  br i1 %t600, label %sym_find_body_125, label %sym_find_end_127
sym_find_body_125:
  %t601 = getelementptr inbounds i8*, i8** %t597, i64 %t599
  %t602 = load i8*, i8** %t601
  %t603 = call i32 @strcmp(i8* %t602, i8* %t594)
  %t604 = icmp eq i32 %t603, 0
  br i1 %t604, label %sym_find_end_127, label %sym_find_next_126
sym_find_next_126:
  %t605 = add i64 %t599, 1
  store i64 %t605, i64* %t598
  br label %sym_find_cond_124
sym_find_end_127:
  %t606 = load i64, i64* %t598
  %t607 = icmp slt i64 %t606, %t596
  br i1 %t607, label %sym_found_128, label %sym_notfound_129
sym_found_128:
  call void @star_rc_release(i8* %t594)
  br label %sym_done_130
sym_notfound_129:
  %t608 = load i64, i64* @sym.cap
  %t609 = icmp sge i64 %t596, %t608
  br i1 %t609, label %sym_grow_131, label %sym_store_132
sym_grow_131:
  %t610 = mul i64 %t608, 2
  %t611 = icmp sgt i64 %t610, 0
  %t612 = select i1 %t611, i64 %t610, i64 1
  %t613 = mul i64 %t612, 8
  %t614 = call i8* @malloc(i64 %t613)
  %t615 = bitcast i8* %t614 to i8**
  %t616 = icmp sgt i64 %t608, 0
  br i1 %t616, label %sym_copy_133, label %sym_after_copy_134
sym_copy_133:
  %t617 = mul i64 %t596, 8
  %t618 = bitcast i8** %t597 to i8*
  call i8* @memcpy(i8* %t614, i8* %t618, i64 %t617)
  call void @free(i8* %t618)
  br label %sym_after_copy_134
sym_after_copy_134:
  store i8** %t615, i8*** @sym.data
  store i64 %t612, i64* @sym.cap
  br label %sym_store_132
sym_store_132:
  %t619 = load i8**, i8*** @sym.data
  %t620 = getelementptr inbounds i8*, i8** %t619, i64 %t596
  store i8* %t594, i8** %t620
  %t621 = add i64 %t596, 1
  store i64 %t621, i64* @sym.len
  br label %sym_done_130
sym_done_130:
  %t622 = phi i64 [ %t606, %sym_found_128 ], [ %t596, %sym_store_132 ]
  call i32 @ReleaseSemaphore(i8* %t595, i32 1, i32* null)
  %t623 = load i64, i64* %t591
  %t624 = load i64*, i64** %t589
  store i64 0, i64* %t625
  store i1 false, i1* %t626
  br label %find_cond_135
find_cond_135:
  %t627 = load i64, i64* %t625
  %t628 = icmp slt i64 %t627, %t623
  br i1 %t628, label %find_body_136, label %find_end_139
find_body_136:
  %t629 = getelementptr inbounds i64, i64* %t624, i64 %t627
  %t630 = load i64, i64* %t629
  br label %find_eq_check_137
find_eq_check_137:
  %t631 = call i1 @eq_symbol(i64 %t630, i64 %t622)
  br i1 %t631, label %find_end_139, label %find_next_138
find_next_138:
  %t632 = add i64 %t627, 1
  store i64 %t632, i64* %t625
  br label %find_cond_135
find_end_139:
  %t633 = load i64, i64* %t625
  %t634 = icmp slt i64 %t633, %t623
  br i1 %t634, label %set_insert_already_present_140, label %set_insert_do_141
set_insert_already_present_140:
  br label %set_insert_end_142
set_insert_do_141:
  %t635 = load i64, i64* %t593
  %t636 = load i64*, i64** %t589
  %t637 = icmp sge i64 %t623, %t635
  br i1 %t637, label %set_insert_grow_143, label %set_insert_store_144
set_insert_grow_143:
  %t638 = mul i64 %t635, 2
  %t639 = icmp sgt i64 %t638, 0
  %t640 = select i1 %t639, i64 %t638, i64 1
  %t641 = getelementptr i64, i64* null, i32 1
  %t642 = ptrtoint i64* %t641 to i64
  %t643 = mul i64 %t640, %t642
  %t644 = call i8* @malloc(i64 %t643)
  %t645 = bitcast i8* %t644 to i64*
  %t646 = icmp sgt i64 %t635, 0
  br i1 %t646, label %set_insert_copy_145, label %set_insert_after_copy_146
set_insert_copy_145:
  %t647 = mul i64 %t623, %t642
  %t648 = bitcast i64* %t636 to i8*
  call i8* @memcpy(i8* %t644, i8* %t648, i64 %t647)
  call void @free(i8* %t648)
  br label %set_insert_after_copy_146
set_insert_after_copy_146:
  store i64* %t645, i64** %t589
  store i64 %t640, i64* %t593
  br label %set_insert_store_144
set_insert_store_144:
  %t649 = load i64*, i64** %t589
  %t650 = getelementptr inbounds i64, i64* %t649, i64 %t623
  store i64 %t622, i64* %t650
  %t651 = add i64 %t623, 1
  store i64 %t651, i64* %t591
  br label %set_insert_end_142
set_insert_end_142:
  %t652 = phi i1 [ false, %set_insert_already_present_140 ], [ true, %set_insert_store_144 ]
  %t653 = getelementptr i64, i64* null, i32 1
  %t654 = ptrtoint i64* %t653 to i64
  %t655 = load i8*, i8** %t549
  %t656 = icmp eq i8* %t655, null
  br i1 %t656, label %set_cow_alloc_147, label %set_cow_check_148
set_cow_alloc_147:
  %t657 = bitcast void (i8*)* @set_release_symbol to i8*
  %t658 = call i8* @star_rc_alloc(i64 24, i8* %t657)
  %t659 = bitcast i8* %t658 to { i64*, i64, i64 }*
  %t660 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t659, i32 0, i32 0
  store i64* null, i64** %t660
  %t661 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t659, i32 0, i32 1
  store i64 0, i64* %t661
  %t662 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t659, i32 0, i32 2
  store i64 0, i64* %t662
  store i8* %t658, i8** %t549
  br label %set_cow_done_149
set_cow_check_148:
  %t663 = getelementptr inbounds i8, i8* %t655, i64 -16
  %t664 = bitcast i8* %t663 to i64*
  %t665 = load atomic i64, i64* %t664 seq_cst, align 8
  %t666 = icmp eq i64 %t665, 1
  br i1 %t666, label %set_cow_done_149, label %set_cow_clone_150
set_cow_clone_150:
  %t667 = bitcast i8* %t655 to { i64*, i64, i64 }*
  %t668 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t667, i32 0, i32 0
  %t669 = load i64*, i64** %t668
  %t670 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t667, i32 0, i32 1
  %t671 = load i64, i64* %t670
  %t672 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t667, i32 0, i32 2
  %t673 = load i64, i64* %t672
  %t674 = bitcast void (i8*)* @set_release_symbol to i8*
  %t675 = call i8* @star_rc_alloc(i64 24, i8* %t674)
  %t676 = bitcast i8* %t675 to { i64*, i64, i64 }*
  %t677 = mul i64 %t673, %t654
  %t678 = call i8* @malloc(i64 %t677)
  %t679 = bitcast i8* %t678 to i64*
  %t680 = icmp sgt i64 %t671, 0
  br i1 %t680, label %set_cow_copy_151, label %set_cow_after_copy_152
set_cow_copy_151:
  %t681 = mul i64 %t671, %t654
  %t682 = bitcast i64* %t669 to i8*
  call i8* @memcpy(i8* %t678, i8* %t682, i64 %t681)
  br label %set_cow_after_copy_152
set_cow_after_copy_152:
  %t683 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t676, i32 0, i32 0
  store i64* %t679, i64** %t683
  %t684 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t676, i32 0, i32 1
  store i64 %t671, i64* %t684
  %t685 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t676, i32 0, i32 2
  store i64 %t673, i64* %t685
  call void @star_rc_release(i8* %t655)
  store i8* %t675, i8** %t549
  br label %set_cow_done_149
set_cow_done_149:
  %t686 = load i8*, i8** %t549
  %t687 = bitcast i8* %t686 to { i64*, i64, i64 }*
  %t688 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t687, i32 0, i32 0
  %t689 = load i64*, i64** %t688
  %t690 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t687, i32 0, i32 1
  %t691 = load i64, i64* %t690
  %t692 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t687, i32 0, i32 2
  %t693 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.28, i64 0, i32 2, i64 0
  %t694 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t694, i32 -1)
  %t695 = load i64, i64* @sym.len
  %t696 = load i8**, i8*** @sym.data
  store i64 0, i64* %t697
  br label %sym_find_cond_153
sym_find_cond_153:
  %t698 = load i64, i64* %t697
  %t699 = icmp slt i64 %t698, %t695
  br i1 %t699, label %sym_find_body_154, label %sym_find_end_156
sym_find_body_154:
  %t700 = getelementptr inbounds i8*, i8** %t696, i64 %t698
  %t701 = load i8*, i8** %t700
  %t702 = call i32 @strcmp(i8* %t701, i8* %t693)
  %t703 = icmp eq i32 %t702, 0
  br i1 %t703, label %sym_find_end_156, label %sym_find_next_155
sym_find_next_155:
  %t704 = add i64 %t698, 1
  store i64 %t704, i64* %t697
  br label %sym_find_cond_153
sym_find_end_156:
  %t705 = load i64, i64* %t697
  %t706 = icmp slt i64 %t705, %t695
  br i1 %t706, label %sym_found_157, label %sym_notfound_158
sym_found_157:
  call void @star_rc_release(i8* %t693)
  br label %sym_done_159
sym_notfound_158:
  %t707 = load i64, i64* @sym.cap
  %t708 = icmp sge i64 %t695, %t707
  br i1 %t708, label %sym_grow_160, label %sym_store_161
sym_grow_160:
  %t709 = mul i64 %t707, 2
  %t710 = icmp sgt i64 %t709, 0
  %t711 = select i1 %t710, i64 %t709, i64 1
  %t712 = mul i64 %t711, 8
  %t713 = call i8* @malloc(i64 %t712)
  %t714 = bitcast i8* %t713 to i8**
  %t715 = icmp sgt i64 %t707, 0
  br i1 %t715, label %sym_copy_162, label %sym_after_copy_163
sym_copy_162:
  %t716 = mul i64 %t695, 8
  %t717 = bitcast i8** %t696 to i8*
  call i8* @memcpy(i8* %t713, i8* %t717, i64 %t716)
  call void @free(i8* %t717)
  br label %sym_after_copy_163
sym_after_copy_163:
  store i8** %t714, i8*** @sym.data
  store i64 %t711, i64* @sym.cap
  br label %sym_store_161
sym_store_161:
  %t718 = load i8**, i8*** @sym.data
  %t719 = getelementptr inbounds i8*, i8** %t718, i64 %t695
  store i8* %t693, i8** %t719
  %t720 = add i64 %t695, 1
  store i64 %t720, i64* @sym.len
  br label %sym_done_159
sym_done_159:
  %t721 = phi i64 [ %t705, %sym_found_157 ], [ %t695, %sym_store_161 ]
  call i32 @ReleaseSemaphore(i8* %t694, i32 1, i32* null)
  %t722 = load i64, i64* %t690
  %t723 = load i64*, i64** %t688
  store i64 0, i64* %t724
  store i1 false, i1* %t725
  br label %find_cond_164
find_cond_164:
  %t726 = load i64, i64* %t724
  %t727 = icmp slt i64 %t726, %t722
  br i1 %t727, label %find_body_165, label %find_end_168
find_body_165:
  %t728 = getelementptr inbounds i64, i64* %t723, i64 %t726
  %t729 = load i64, i64* %t728
  br label %find_eq_check_166
find_eq_check_166:
  %t730 = call i1 @eq_symbol(i64 %t729, i64 %t721)
  br i1 %t730, label %find_end_168, label %find_next_167
find_next_167:
  %t731 = add i64 %t726, 1
  store i64 %t731, i64* %t724
  br label %find_cond_164
find_end_168:
  %t732 = load i64, i64* %t724
  %t733 = icmp slt i64 %t732, %t722
  br i1 %t733, label %set_insert_already_present_169, label %set_insert_do_170
set_insert_already_present_169:
  br label %set_insert_end_171
set_insert_do_170:
  %t734 = load i64, i64* %t692
  %t735 = load i64*, i64** %t688
  %t736 = icmp sge i64 %t722, %t734
  br i1 %t736, label %set_insert_grow_172, label %set_insert_store_173
set_insert_grow_172:
  %t737 = mul i64 %t734, 2
  %t738 = icmp sgt i64 %t737, 0
  %t739 = select i1 %t738, i64 %t737, i64 1
  %t740 = getelementptr i64, i64* null, i32 1
  %t741 = ptrtoint i64* %t740 to i64
  %t742 = mul i64 %t739, %t741
  %t743 = call i8* @malloc(i64 %t742)
  %t744 = bitcast i8* %t743 to i64*
  %t745 = icmp sgt i64 %t734, 0
  br i1 %t745, label %set_insert_copy_174, label %set_insert_after_copy_175
set_insert_copy_174:
  %t746 = mul i64 %t722, %t741
  %t747 = bitcast i64* %t735 to i8*
  call i8* @memcpy(i8* %t743, i8* %t747, i64 %t746)
  call void @free(i8* %t747)
  br label %set_insert_after_copy_175
set_insert_after_copy_175:
  store i64* %t744, i64** %t688
  store i64 %t739, i64* %t692
  br label %set_insert_store_173
set_insert_store_173:
  %t748 = load i64*, i64** %t688
  %t749 = getelementptr inbounds i64, i64* %t748, i64 %t722
  store i64 %t721, i64* %t749
  %t750 = add i64 %t722, 1
  store i64 %t750, i64* %t690
  br label %set_insert_end_171
set_insert_end_171:
  %t751 = phi i1 [ false, %set_insert_already_present_169 ], [ true, %set_insert_store_173 ]
  %t752 = getelementptr i64, i64* null, i32 1
  %t753 = ptrtoint i64* %t752 to i64
  %t754 = load i8*, i8** %t549
  %t755 = icmp eq i8* %t754, null
  br i1 %t755, label %set_cow_alloc_176, label %set_cow_check_177
set_cow_alloc_176:
  %t756 = bitcast void (i8*)* @set_release_symbol to i8*
  %t757 = call i8* @star_rc_alloc(i64 24, i8* %t756)
  %t758 = bitcast i8* %t757 to { i64*, i64, i64 }*
  %t759 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t758, i32 0, i32 0
  store i64* null, i64** %t759
  %t760 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t758, i32 0, i32 1
  store i64 0, i64* %t760
  %t761 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t758, i32 0, i32 2
  store i64 0, i64* %t761
  store i8* %t757, i8** %t549
  br label %set_cow_done_178
set_cow_check_177:
  %t762 = getelementptr inbounds i8, i8* %t754, i64 -16
  %t763 = bitcast i8* %t762 to i64*
  %t764 = load atomic i64, i64* %t763 seq_cst, align 8
  %t765 = icmp eq i64 %t764, 1
  br i1 %t765, label %set_cow_done_178, label %set_cow_clone_179
set_cow_clone_179:
  %t766 = bitcast i8* %t754 to { i64*, i64, i64 }*
  %t767 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t766, i32 0, i32 0
  %t768 = load i64*, i64** %t767
  %t769 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t766, i32 0, i32 1
  %t770 = load i64, i64* %t769
  %t771 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t766, i32 0, i32 2
  %t772 = load i64, i64* %t771
  %t773 = bitcast void (i8*)* @set_release_symbol to i8*
  %t774 = call i8* @star_rc_alloc(i64 24, i8* %t773)
  %t775 = bitcast i8* %t774 to { i64*, i64, i64 }*
  %t776 = mul i64 %t772, %t753
  %t777 = call i8* @malloc(i64 %t776)
  %t778 = bitcast i8* %t777 to i64*
  %t779 = icmp sgt i64 %t770, 0
  br i1 %t779, label %set_cow_copy_180, label %set_cow_after_copy_181
set_cow_copy_180:
  %t780 = mul i64 %t770, %t753
  %t781 = bitcast i64* %t768 to i8*
  call i8* @memcpy(i8* %t777, i8* %t781, i64 %t780)
  br label %set_cow_after_copy_181
set_cow_after_copy_181:
  %t782 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t775, i32 0, i32 0
  store i64* %t778, i64** %t782
  %t783 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t775, i32 0, i32 1
  store i64 %t770, i64* %t783
  %t784 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t775, i32 0, i32 2
  store i64 %t772, i64* %t784
  call void @star_rc_release(i8* %t754)
  store i8* %t774, i8** %t549
  br label %set_cow_done_178
set_cow_done_178:
  %t785 = load i8*, i8** %t549
  %t786 = bitcast i8* %t785 to { i64*, i64, i64 }*
  %t787 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t786, i32 0, i32 0
  %t788 = load i64*, i64** %t787
  %t789 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t786, i32 0, i32 1
  %t790 = load i64, i64* %t789
  %t791 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t786, i32 0, i32 2
  %t792 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.29, i64 0, i32 2, i64 0
  %t793 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t793, i32 -1)
  %t794 = load i64, i64* @sym.len
  %t795 = load i8**, i8*** @sym.data
  store i64 0, i64* %t796
  br label %sym_find_cond_182
sym_find_cond_182:
  %t797 = load i64, i64* %t796
  %t798 = icmp slt i64 %t797, %t794
  br i1 %t798, label %sym_find_body_183, label %sym_find_end_185
sym_find_body_183:
  %t799 = getelementptr inbounds i8*, i8** %t795, i64 %t797
  %t800 = load i8*, i8** %t799
  %t801 = call i32 @strcmp(i8* %t800, i8* %t792)
  %t802 = icmp eq i32 %t801, 0
  br i1 %t802, label %sym_find_end_185, label %sym_find_next_184
sym_find_next_184:
  %t803 = add i64 %t797, 1
  store i64 %t803, i64* %t796
  br label %sym_find_cond_182
sym_find_end_185:
  %t804 = load i64, i64* %t796
  %t805 = icmp slt i64 %t804, %t794
  br i1 %t805, label %sym_found_186, label %sym_notfound_187
sym_found_186:
  call void @star_rc_release(i8* %t792)
  br label %sym_done_188
sym_notfound_187:
  %t806 = load i64, i64* @sym.cap
  %t807 = icmp sge i64 %t794, %t806
  br i1 %t807, label %sym_grow_189, label %sym_store_190
sym_grow_189:
  %t808 = mul i64 %t806, 2
  %t809 = icmp sgt i64 %t808, 0
  %t810 = select i1 %t809, i64 %t808, i64 1
  %t811 = mul i64 %t810, 8
  %t812 = call i8* @malloc(i64 %t811)
  %t813 = bitcast i8* %t812 to i8**
  %t814 = icmp sgt i64 %t806, 0
  br i1 %t814, label %sym_copy_191, label %sym_after_copy_192
sym_copy_191:
  %t815 = mul i64 %t794, 8
  %t816 = bitcast i8** %t795 to i8*
  call i8* @memcpy(i8* %t812, i8* %t816, i64 %t815)
  call void @free(i8* %t816)
  br label %sym_after_copy_192
sym_after_copy_192:
  store i8** %t813, i8*** @sym.data
  store i64 %t810, i64* @sym.cap
  br label %sym_store_190
sym_store_190:
  %t817 = load i8**, i8*** @sym.data
  %t818 = getelementptr inbounds i8*, i8** %t817, i64 %t794
  store i8* %t792, i8** %t818
  %t819 = add i64 %t794, 1
  store i64 %t819, i64* @sym.len
  br label %sym_done_188
sym_done_188:
  %t820 = phi i64 [ %t804, %sym_found_186 ], [ %t794, %sym_store_190 ]
  call i32 @ReleaseSemaphore(i8* %t793, i32 1, i32* null)
  %t821 = load i64, i64* %t789
  %t822 = load i64*, i64** %t787
  store i64 0, i64* %t823
  store i1 false, i1* %t824
  br label %find_cond_193
find_cond_193:
  %t825 = load i64, i64* %t823
  %t826 = icmp slt i64 %t825, %t821
  br i1 %t826, label %find_body_194, label %find_end_197
find_body_194:
  %t827 = getelementptr inbounds i64, i64* %t822, i64 %t825
  %t828 = load i64, i64* %t827
  br label %find_eq_check_195
find_eq_check_195:
  %t829 = call i1 @eq_symbol(i64 %t828, i64 %t820)
  br i1 %t829, label %find_end_197, label %find_next_196
find_next_196:
  %t830 = add i64 %t825, 1
  store i64 %t830, i64* %t823
  br label %find_cond_193
find_end_197:
  %t831 = load i64, i64* %t823
  %t832 = icmp slt i64 %t831, %t821
  br i1 %t832, label %set_insert_already_present_198, label %set_insert_do_199
set_insert_already_present_198:
  br label %set_insert_end_200
set_insert_do_199:
  %t833 = load i64, i64* %t791
  %t834 = load i64*, i64** %t787
  %t835 = icmp sge i64 %t821, %t833
  br i1 %t835, label %set_insert_grow_201, label %set_insert_store_202
set_insert_grow_201:
  %t836 = mul i64 %t833, 2
  %t837 = icmp sgt i64 %t836, 0
  %t838 = select i1 %t837, i64 %t836, i64 1
  %t839 = getelementptr i64, i64* null, i32 1
  %t840 = ptrtoint i64* %t839 to i64
  %t841 = mul i64 %t838, %t840
  %t842 = call i8* @malloc(i64 %t841)
  %t843 = bitcast i8* %t842 to i64*
  %t844 = icmp sgt i64 %t833, 0
  br i1 %t844, label %set_insert_copy_203, label %set_insert_after_copy_204
set_insert_copy_203:
  %t845 = mul i64 %t821, %t840
  %t846 = bitcast i64* %t834 to i8*
  call i8* @memcpy(i8* %t842, i8* %t846, i64 %t845)
  call void @free(i8* %t846)
  br label %set_insert_after_copy_204
set_insert_after_copy_204:
  store i64* %t843, i64** %t787
  store i64 %t838, i64* %t791
  br label %set_insert_store_202
set_insert_store_202:
  %t847 = load i64*, i64** %t787
  %t848 = getelementptr inbounds i64, i64* %t847, i64 %t821
  store i64 %t820, i64* %t848
  %t849 = add i64 %t821, 1
  store i64 %t849, i64* %t789
  br label %set_insert_end_200
set_insert_end_200:
  %t850 = phi i1 [ false, %set_insert_already_present_198 ], [ true, %set_insert_store_202 ]
  %t851 = load i8*, i8** %t549
  %t852 = icmp eq i8* %t851, null
  br i1 %t852, label %set_read_null_205, label %set_read_real_206
set_read_null_205:
  br label %set_read_end_207
set_read_real_206:
  %t853 = bitcast i8* %t851 to { i64*, i64, i64 }*
  %t854 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t853, i32 0, i32 0
  %t855 = load i64*, i64** %t854
  %t856 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t853, i32 0, i32 1
  %t857 = load i64, i64* %t856
  br label %set_read_end_207
set_read_end_207:
  %t858 = phi i64* [ null, %set_read_null_205 ], [ %t855, %set_read_real_206 ]
  %t859 = phi i64 [ 0, %set_read_null_205 ], [ %t857, %set_read_real_206 ]
  %t860 = trunc i64 %t859 to i32
  %t861 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.30, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t861, i32 %t860)
  %t863 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.31, i64 0, i32 2, i64 0
  %t864 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t864, i32 -1)
  %t865 = load i64, i64* @sym.len
  %t866 = load i8**, i8*** @sym.data
  store i64 0, i64* %t867
  br label %sym_find_cond_208
sym_find_cond_208:
  %t868 = load i64, i64* %t867
  %t869 = icmp slt i64 %t868, %t865
  br i1 %t869, label %sym_find_body_209, label %sym_find_end_211
sym_find_body_209:
  %t870 = getelementptr inbounds i8*, i8** %t866, i64 %t868
  %t871 = load i8*, i8** %t870
  %t872 = call i32 @strcmp(i8* %t871, i8* %t863)
  %t873 = icmp eq i32 %t872, 0
  br i1 %t873, label %sym_find_end_211, label %sym_find_next_210
sym_find_next_210:
  %t874 = add i64 %t868, 1
  store i64 %t874, i64* %t867
  br label %sym_find_cond_208
sym_find_end_211:
  %t875 = load i64, i64* %t867
  %t876 = icmp slt i64 %t875, %t865
  br i1 %t876, label %sym_found_212, label %sym_notfound_213
sym_found_212:
  call void @star_rc_release(i8* %t863)
  br label %sym_done_214
sym_notfound_213:
  %t877 = load i64, i64* @sym.cap
  %t878 = icmp sge i64 %t865, %t877
  br i1 %t878, label %sym_grow_215, label %sym_store_216
sym_grow_215:
  %t879 = mul i64 %t877, 2
  %t880 = icmp sgt i64 %t879, 0
  %t881 = select i1 %t880, i64 %t879, i64 1
  %t882 = mul i64 %t881, 8
  %t883 = call i8* @malloc(i64 %t882)
  %t884 = bitcast i8* %t883 to i8**
  %t885 = icmp sgt i64 %t877, 0
  br i1 %t885, label %sym_copy_217, label %sym_after_copy_218
sym_copy_217:
  %t886 = mul i64 %t865, 8
  %t887 = bitcast i8** %t866 to i8*
  call i8* @memcpy(i8* %t883, i8* %t887, i64 %t886)
  call void @free(i8* %t887)
  br label %sym_after_copy_218
sym_after_copy_218:
  store i8** %t884, i8*** @sym.data
  store i64 %t881, i64* @sym.cap
  br label %sym_store_216
sym_store_216:
  %t888 = load i8**, i8*** @sym.data
  %t889 = getelementptr inbounds i8*, i8** %t888, i64 %t865
  store i8* %t863, i8** %t889
  %t890 = add i64 %t865, 1
  store i64 %t890, i64* @sym.len
  br label %sym_done_214
sym_done_214:
  %t891 = phi i64 [ %t875, %sym_found_212 ], [ %t865, %sym_store_216 ]
  call i32 @ReleaseSemaphore(i8* %t864, i32 1, i32* null)
  %t892 = load i8*, i8** %t549
  %t893 = icmp eq i8* %t892, null
  br i1 %t893, label %set_read_null_219, label %set_read_real_220
set_read_null_219:
  br label %set_read_end_221
set_read_real_220:
  %t894 = bitcast i8* %t892 to { i64*, i64, i64 }*
  %t895 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t894, i32 0, i32 0
  %t896 = load i64*, i64** %t895
  %t897 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t894, i32 0, i32 1
  %t898 = load i64, i64* %t897
  br label %set_read_end_221
set_read_end_221:
  %t899 = phi i64* [ null, %set_read_null_219 ], [ %t896, %set_read_real_220 ]
  %t900 = phi i64 [ 0, %set_read_null_219 ], [ %t898, %set_read_real_220 ]
  store i64 0, i64* %t901
  store i1 false, i1* %t902
  br label %find_cond_222
find_cond_222:
  %t903 = load i64, i64* %t901
  %t904 = icmp slt i64 %t903, %t900
  br i1 %t904, label %find_body_223, label %find_end_226
find_body_223:
  %t905 = getelementptr inbounds i64, i64* %t899, i64 %t903
  %t906 = load i64, i64* %t905
  br label %find_eq_check_224
find_eq_check_224:
  %t907 = call i1 @eq_symbol(i64 %t906, i64 %t891)
  br i1 %t907, label %find_end_226, label %find_next_225
find_next_225:
  %t908 = add i64 %t903, 1
  store i64 %t908, i64* %t901
  br label %find_cond_222
find_end_226:
  %t909 = load i64, i64* %t901
  %t910 = icmp slt i64 %t909, %t900
  store i1 %t910, i1* %t862
  %t911 = load i1, i1* %t862
  %t912 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.32, i64 0, i64 0
  %t913 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.33, i64 0, i64 0
  %t914 = select i1 %t911, i8* %t912, i8* %t913
  %t915 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.34, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t915, i8* %t914)
  %t916 = load i8*, i8** %t549
  call void @star_rc_release(i8* %t916)
  %t917 = load i8*, i8** %t163
  call void @star_rc_release(i8* %t917)
  ret i32 0
}


; par/swarm worker functions
define void @map_release_6_symboli32(i8* %objp) {
entry:
  %t170 = bitcast i8* %objp to { i64*, i32*, i64, i64 }*
  %t171 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t170, i32 0, i32 0
  %t172 = load i64*, i64** %t171
  %t173 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t170, i32 0, i32 1
  %t174 = load i32*, i32** %t173
  %t175 = bitcast i64* %t172 to i8*
  call void @free(i8* %t175)
  %t176 = bitcast i32* %t174 to i8*
  call void @free(i8* %t176)
  ret void
}


define i1 @eq_symbol(i64 %a, i64 %b) {
entry:
  %t227 = icmp eq i64 %a, %b
  ret i1 %t227
}


define void @set_release_symbol(i8* %objp) {
entry:
  %t554 = bitcast i8* %objp to { i64*, i64, i64 }*
  %t555 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t554, i32 0, i32 0
  %t556 = load i64*, i64** %t555
  %t557 = bitcast i64* %t556 to i8*
  call void @free(i8* %t557)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"player\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"player\00" }
@.str.2 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"enemy\00" }
@.str.3 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.4 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.5 = private unnamed_addr constant [44 x i8] c"Symbol(\22player\22) == Symbol(\22player\22) is %s\0A\00"
@.str.6 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.7 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.8 = private unnamed_addr constant [43 x i8] c"Symbol(\22player\22) == Symbol(\22enemy\22) is %s\0A\00"
@.str.9 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.10 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.11 = private unnamed_addr constant [43 x i8] c"Symbol(\22player\22) != Symbol(\22enemy\22) is %s\0A\00"
@.str.12 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.13 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.14 = private unnamed_addr constant [17 x i8] c"a_id == 0 is %s\0A\00"
@.str.15 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.16 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.17 = private unnamed_addr constant [17 x i8] c"c_id == 1 is %s\0A\00"
@.str.18 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.19 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.20 = private unnamed_addr constant [29 x i8] c"(c_id as Symbol) == c is %s\0A\00"
@.str.21 = private unnamed_addr constant [21 x i8] c"symbol_name(a) = %s\0A\00"
@.str.22 = private unnamed_addr constant [21 x i8] c"symbol_name(c) = %s\0A\00"
@.str.23 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"player\00" }
@.str.24 = private unnamed_addr constant [15 x i8] c"hp.len() = %d\0A\00"
@.str.25 = private unnamed_addr constant [16 x i8] c"player hp = %d\0A\00"
@.str.26 = private unnamed_addr constant { i64, i8*, [18 x i8] } { i64 -1, i8* null, [18 x i8] c"player hp missing\00" }
@.str.27 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"flying\00" }
@.str.28 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"flying\00" }
@.str.29 = private unnamed_addr constant { i64, i8*, [8 x i8] } { i64 -1, i8* null, [8 x i8] c"armored\00" }
@.str.30 = private unnamed_addr constant [17 x i8] c"tags.len() = %d\0A\00"
@.str.31 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"flying\00" }
@.str.32 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.33 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.34 = private unnamed_addr constant [29 x i8] c"tags.contains(flying) is %s\0A\00"
