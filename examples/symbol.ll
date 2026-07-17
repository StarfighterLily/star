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

%Option__i32 = type { i32, [1 x i64] }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t0 = alloca i64
  %t4 = alloca i64
  %t29 = alloca i64
  %t33 = alloca i64
  %t58 = alloca i64
  %t62 = alloca i64
  %t108 = alloca i64
  %t110 = alloca i64
  %t126 = alloca i64
  %t155 = alloca i8*
  %t220 = alloca i64
  %t314 = alloca i64
  %t408 = alloca i64
  %t435 = alloca i64
  %t500 = alloca i64
  %t511 = alloca %Option__i32
  %t517 = alloca %Option__i32
  %t521 = alloca %Option__i32
  %t540 = alloca i8*
  %t588 = alloca i64
  %t615 = alloca i64
  %t616 = alloca i1
  %t686 = alloca i64
  %t713 = alloca i64
  %t714 = alloca i1
  %t784 = alloca i64
  %t811 = alloca i64
  %t812 = alloca i1
  %t850 = alloca i1
  %t854 = alloca i64
  %t888 = alloca i64
  %t889 = alloca i1
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t1 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t2 = load i64, i64* @sym.len
  %t3 = load i8**, i8*** @sym.data
  store i64 0, i64* %t4
  br label %sym_find_cond_0
sym_find_cond_0:
  %t5 = load i64, i64* %t4
  %t6 = icmp slt i64 %t5, %t2
  br i1 %t6, label %sym_find_body_1, label %sym_find_end_3
sym_find_body_1:
  %t7 = getelementptr inbounds i8*, i8** %t3, i64 %t5
  %t8 = load i8*, i8** %t7
  %t9 = call i32 @strcmp(i8* %t8, i8* %t1)
  %t10 = icmp eq i32 %t9, 0
  br i1 %t10, label %sym_find_end_3, label %sym_find_next_2
sym_find_next_2:
  %t11 = add i64 %t5, 1
  store i64 %t11, i64* %t4
  br label %sym_find_cond_0
sym_find_end_3:
  %t12 = load i64, i64* %t4
  %t13 = icmp slt i64 %t12, %t2
  br i1 %t13, label %sym_found_4, label %sym_notfound_5
sym_found_4:
  call void @star_rc_release(i8* %t1)
  br label %sym_done_6
sym_notfound_5:
  %t14 = load i64, i64* @sym.cap
  %t15 = icmp sge i64 %t2, %t14
  br i1 %t15, label %sym_grow_7, label %sym_store_8
sym_grow_7:
  %t16 = mul i64 %t14, 2
  %t17 = icmp sgt i64 %t16, 0
  %t18 = select i1 %t17, i64 %t16, i64 1
  %t19 = mul i64 %t18, 8
  %t20 = call i8* @malloc(i64 %t19)
  %t21 = bitcast i8* %t20 to i8**
  %t22 = icmp sgt i64 %t14, 0
  br i1 %t22, label %sym_copy_9, label %sym_after_copy_10
sym_copy_9:
  %t23 = mul i64 %t2, 8
  %t24 = bitcast i8** %t3 to i8*
  call i8* @memcpy(i8* %t20, i8* %t24, i64 %t23)
  call void @free(i8* %t24)
  br label %sym_after_copy_10
sym_after_copy_10:
  store i8** %t21, i8*** @sym.data
  store i64 %t18, i64* @sym.cap
  br label %sym_store_8
sym_store_8:
  %t25 = load i8**, i8*** @sym.data
  %t26 = getelementptr inbounds i8*, i8** %t25, i64 %t2
  store i8* %t1, i8** %t26
  %t27 = add i64 %t2, 1
  store i64 %t27, i64* @sym.len
  br label %sym_done_6
sym_done_6:
  %t28 = phi i64 [ %t12, %sym_found_4 ], [ %t2, %sym_store_8 ]
  store i64 %t28, i64* %t0
  %t30 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t31 = load i64, i64* @sym.len
  %t32 = load i8**, i8*** @sym.data
  store i64 0, i64* %t33
  br label %sym_find_cond_11
sym_find_cond_11:
  %t34 = load i64, i64* %t33
  %t35 = icmp slt i64 %t34, %t31
  br i1 %t35, label %sym_find_body_12, label %sym_find_end_14
sym_find_body_12:
  %t36 = getelementptr inbounds i8*, i8** %t32, i64 %t34
  %t37 = load i8*, i8** %t36
  %t38 = call i32 @strcmp(i8* %t37, i8* %t30)
  %t39 = icmp eq i32 %t38, 0
  br i1 %t39, label %sym_find_end_14, label %sym_find_next_13
sym_find_next_13:
  %t40 = add i64 %t34, 1
  store i64 %t40, i64* %t33
  br label %sym_find_cond_11
sym_find_end_14:
  %t41 = load i64, i64* %t33
  %t42 = icmp slt i64 %t41, %t31
  br i1 %t42, label %sym_found_15, label %sym_notfound_16
sym_found_15:
  call void @star_rc_release(i8* %t30)
  br label %sym_done_17
sym_notfound_16:
  %t43 = load i64, i64* @sym.cap
  %t44 = icmp sge i64 %t31, %t43
  br i1 %t44, label %sym_grow_18, label %sym_store_19
sym_grow_18:
  %t45 = mul i64 %t43, 2
  %t46 = icmp sgt i64 %t45, 0
  %t47 = select i1 %t46, i64 %t45, i64 1
  %t48 = mul i64 %t47, 8
  %t49 = call i8* @malloc(i64 %t48)
  %t50 = bitcast i8* %t49 to i8**
  %t51 = icmp sgt i64 %t43, 0
  br i1 %t51, label %sym_copy_20, label %sym_after_copy_21
sym_copy_20:
  %t52 = mul i64 %t31, 8
  %t53 = bitcast i8** %t32 to i8*
  call i8* @memcpy(i8* %t49, i8* %t53, i64 %t52)
  call void @free(i8* %t53)
  br label %sym_after_copy_21
sym_after_copy_21:
  store i8** %t50, i8*** @sym.data
  store i64 %t47, i64* @sym.cap
  br label %sym_store_19
sym_store_19:
  %t54 = load i8**, i8*** @sym.data
  %t55 = getelementptr inbounds i8*, i8** %t54, i64 %t31
  store i8* %t30, i8** %t55
  %t56 = add i64 %t31, 1
  store i64 %t56, i64* @sym.len
  br label %sym_done_17
sym_done_17:
  %t57 = phi i64 [ %t41, %sym_found_15 ], [ %t31, %sym_store_19 ]
  store i64 %t57, i64* %t29
  %t59 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t60 = load i64, i64* @sym.len
  %t61 = load i8**, i8*** @sym.data
  store i64 0, i64* %t62
  br label %sym_find_cond_22
sym_find_cond_22:
  %t63 = load i64, i64* %t62
  %t64 = icmp slt i64 %t63, %t60
  br i1 %t64, label %sym_find_body_23, label %sym_find_end_25
sym_find_body_23:
  %t65 = getelementptr inbounds i8*, i8** %t61, i64 %t63
  %t66 = load i8*, i8** %t65
  %t67 = call i32 @strcmp(i8* %t66, i8* %t59)
  %t68 = icmp eq i32 %t67, 0
  br i1 %t68, label %sym_find_end_25, label %sym_find_next_24
sym_find_next_24:
  %t69 = add i64 %t63, 1
  store i64 %t69, i64* %t62
  br label %sym_find_cond_22
sym_find_end_25:
  %t70 = load i64, i64* %t62
  %t71 = icmp slt i64 %t70, %t60
  br i1 %t71, label %sym_found_26, label %sym_notfound_27
sym_found_26:
  call void @star_rc_release(i8* %t59)
  br label %sym_done_28
sym_notfound_27:
  %t72 = load i64, i64* @sym.cap
  %t73 = icmp sge i64 %t60, %t72
  br i1 %t73, label %sym_grow_29, label %sym_store_30
sym_grow_29:
  %t74 = mul i64 %t72, 2
  %t75 = icmp sgt i64 %t74, 0
  %t76 = select i1 %t75, i64 %t74, i64 1
  %t77 = mul i64 %t76, 8
  %t78 = call i8* @malloc(i64 %t77)
  %t79 = bitcast i8* %t78 to i8**
  %t80 = icmp sgt i64 %t72, 0
  br i1 %t80, label %sym_copy_31, label %sym_after_copy_32
sym_copy_31:
  %t81 = mul i64 %t60, 8
  %t82 = bitcast i8** %t61 to i8*
  call i8* @memcpy(i8* %t78, i8* %t82, i64 %t81)
  call void @free(i8* %t82)
  br label %sym_after_copy_32
sym_after_copy_32:
  store i8** %t79, i8*** @sym.data
  store i64 %t76, i64* @sym.cap
  br label %sym_store_30
sym_store_30:
  %t83 = load i8**, i8*** @sym.data
  %t84 = getelementptr inbounds i8*, i8** %t83, i64 %t60
  store i8* %t59, i8** %t84
  %t85 = add i64 %t60, 1
  store i64 %t85, i64* @sym.len
  br label %sym_done_28
sym_done_28:
  %t86 = phi i64 [ %t70, %sym_found_26 ], [ %t60, %sym_store_30 ]
  store i64 %t86, i64* %t58
  %t87 = load i64, i64* %t0
  %t88 = load i64, i64* %t29
  %t89 = icmp eq i64 %t87, %t88
  %t90 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.3, i64 0, i64 0
  %t91 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.4, i64 0, i64 0
  %t92 = select i1 %t89, i8* %t90, i8* %t91
  %t93 = getelementptr inbounds [44 x i8], [44 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t93, i8* %t92)
  %t94 = load i64, i64* %t0
  %t95 = load i64, i64* %t58
  %t96 = icmp eq i64 %t94, %t95
  %t97 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.6, i64 0, i64 0
  %t98 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.7, i64 0, i64 0
  %t99 = select i1 %t96, i8* %t97, i8* %t98
  %t100 = getelementptr inbounds [43 x i8], [43 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t100, i8* %t99)
  %t101 = load i64, i64* %t0
  %t102 = load i64, i64* %t58
  %t103 = icmp ne i64 %t101, %t102
  %t104 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.9, i64 0, i64 0
  %t105 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.10, i64 0, i64 0
  %t106 = select i1 %t103, i8* %t104, i8* %t105
  %t107 = getelementptr inbounds [43 x i8], [43 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t107, i8* %t106)
  %t109 = load i64, i64* %t0
  store i64 %t109, i64* %t108
  %t111 = load i64, i64* %t58
  store i64 %t111, i64* %t110
  %t112 = load i64, i64* %t108
  %t113 = sext i32 0 to i64
  %t114 = icmp eq i64 %t112, %t113
  %t115 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.12, i64 0, i64 0
  %t116 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.13, i64 0, i64 0
  %t117 = select i1 %t114, i8* %t115, i8* %t116
  %t118 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t118, i8* %t117)
  %t119 = load i64, i64* %t110
  %t120 = sext i32 1 to i64
  %t121 = icmp eq i64 %t119, %t120
  %t122 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.15, i64 0, i64 0
  %t123 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.16, i64 0, i64 0
  %t124 = select i1 %t121, i8* %t122, i8* %t123
  %t125 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t125, i8* %t124)
  %t127 = load i64, i64* %t110
  store i64 %t127, i64* %t126
  %t128 = load i64, i64* %t126
  %t129 = load i64, i64* %t58
  %t130 = icmp eq i64 %t128, %t129
  %t131 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.18, i64 0, i64 0
  %t132 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.19, i64 0, i64 0
  %t133 = select i1 %t130, i8* %t131, i8* %t132
  %t134 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.20, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t134, i8* %t133)
  %t135 = load i64, i64* %t0
  %t136 = load i64, i64* @sym.len
  %t137 = icmp sge i64 %t135, 0
  %t138 = icmp slt i64 %t135, %t136
  %t139 = and i1 %t137, %t138
  br i1 %t139, label %sym_name_ok_33, label %sym_name_oob_34
sym_name_ok_33:
  %t140 = load i8**, i8*** @sym.data
  %t141 = getelementptr inbounds i8*, i8** %t140, i64 %t135
  %t142 = load i8*, i8** %t141
  call void @star_rc_retain(i8* %t142)
  br label %sym_name_end_35
sym_name_oob_34:
  br label %sym_name_end_35
sym_name_end_35:
  %t143 = phi i8* [ %t142, %sym_name_ok_33 ], [ null, %sym_name_oob_34 ]
  call void @star_rc_release(i8* %t143)
  %t144 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.21, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t144, i8* %t143)
  %t145 = load i64, i64* %t58
  %t146 = load i64, i64* @sym.len
  %t147 = icmp sge i64 %t145, 0
  %t148 = icmp slt i64 %t145, %t146
  %t149 = and i1 %t147, %t148
  br i1 %t149, label %sym_name_ok_36, label %sym_name_oob_37
sym_name_ok_36:
  %t150 = load i8**, i8*** @sym.data
  %t151 = getelementptr inbounds i8*, i8** %t150, i64 %t145
  %t152 = load i8*, i8** %t151
  call void @star_rc_retain(i8* %t152)
  br label %sym_name_end_38
sym_name_oob_37:
  br label %sym_name_end_38
sym_name_end_38:
  %t153 = phi i8* [ %t152, %sym_name_ok_36 ], [ null, %sym_name_oob_37 ]
  call void @star_rc_release(i8* %t153)
  %t154 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t154, i8* %t153)
  store i8* null, i8** %t155
  %t156 = getelementptr i64, i64* null, i32 1
  %t157 = ptrtoint i64* %t156 to i64
  %t158 = getelementptr i32, i32* null, i32 1
  %t159 = ptrtoint i32* %t158 to i64
  %t160 = load i8*, i8** %t155
  %t161 = icmp eq i8* %t160, null
  br i1 %t161, label %map_cow_alloc_39, label %map_cow_check_40
map_cow_alloc_39:
  %t169 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t170 = call i8* @star_rc_alloc(i64 32, i8* %t169)
  %t171 = bitcast i8* %t170 to { i64*, i32*, i64, i64 }*
  %t172 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t171, i32 0, i32 0
  store i64* null, i64** %t172
  %t173 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t171, i32 0, i32 1
  store i32* null, i32** %t173
  %t174 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t171, i32 0, i32 2
  store i64 0, i64* %t174
  %t175 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t171, i32 0, i32 3
  store i64 0, i64* %t175
  store i8* %t170, i8** %t155
  br label %map_cow_done_41
map_cow_check_40:
  %t176 = getelementptr inbounds i8, i8* %t160, i64 -16
  %t177 = bitcast i8* %t176 to i64*
  %t178 = load atomic i64, i64* %t177 seq_cst, align 8
  %t179 = icmp eq i64 %t178, 1
  br i1 %t179, label %map_cow_done_41, label %map_cow_clone_42
map_cow_clone_42:
  %t180 = bitcast i8* %t160 to { i64*, i32*, i64, i64 }*
  %t181 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t180, i32 0, i32 0
  %t182 = load i64*, i64** %t181
  %t183 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t180, i32 0, i32 1
  %t184 = load i32*, i32** %t183
  %t185 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t180, i32 0, i32 2
  %t186 = load i64, i64* %t185
  %t187 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t180, i32 0, i32 3
  %t188 = load i64, i64* %t187
  %t189 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t190 = call i8* @star_rc_alloc(i64 32, i8* %t189)
  %t191 = bitcast i8* %t190 to { i64*, i32*, i64, i64 }*
  %t192 = mul i64 %t188, %t157
  %t193 = call i8* @malloc(i64 %t192)
  %t194 = bitcast i8* %t193 to i64*
  %t195 = mul i64 %t188, %t159
  %t196 = call i8* @malloc(i64 %t195)
  %t197 = bitcast i8* %t196 to i32*
  %t198 = icmp sgt i64 %t186, 0
  br i1 %t198, label %map_cow_copy_43, label %map_cow_after_copy_44
map_cow_copy_43:
  %t199 = mul i64 %t186, %t157
  %t200 = bitcast i64* %t182 to i8*
  call i8* @memcpy(i8* %t193, i8* %t200, i64 %t199)
  %t201 = mul i64 %t186, %t159
  %t202 = bitcast i32* %t184 to i8*
  call i8* @memcpy(i8* %t196, i8* %t202, i64 %t201)
  br label %map_cow_after_copy_44
map_cow_after_copy_44:
  %t203 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t191, i32 0, i32 0
  store i64* %t194, i64** %t203
  %t204 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t191, i32 0, i32 1
  store i32* %t197, i32** %t204
  %t205 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t191, i32 0, i32 2
  store i64 %t186, i64* %t205
  %t206 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t191, i32 0, i32 3
  store i64 %t188, i64* %t206
  call void @star_rc_release(i8* %t160)
  store i8* %t190, i8** %t155
  br label %map_cow_done_41
map_cow_done_41:
  %t207 = load i8*, i8** %t155
  %t208 = bitcast i8* %t207 to { i64*, i32*, i64, i64 }*
  %t209 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t208, i32 0, i32 0
  %t210 = load i64*, i64** %t209
  %t211 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t208, i32 0, i32 1
  %t212 = load i32*, i32** %t211
  %t213 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t208, i32 0, i32 2
  %t214 = load i64, i64* %t213
  %t215 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t208, i32 0, i32 3
  %t216 = load i64, i64* %t0
  %t217 = load i64, i64* %t213
  %t218 = load i64*, i64** %t209
  store i64 0, i64* %t220
  br label %map_find_cond_45
map_find_cond_45:
  %t221 = load i64, i64* %t220
  %t222 = icmp slt i64 %t221, %t217
  br i1 %t222, label %map_find_body_46, label %map_find_end_49
map_find_body_46:
  %t223 = getelementptr inbounds i64, i64* %t218, i64 %t221
  %t224 = load i64, i64* %t223
  br label %map_find_eq_check_47
map_find_eq_check_47:
  %t225 = call i1 @eq_symbol(i64 %t224, i64 %t216)
  br i1 %t225, label %map_find_end_49, label %map_find_next_48
map_find_next_48:
  %t226 = add i64 %t221, 1
  store i64 %t226, i64* %t220
  br label %map_find_cond_45
map_find_end_49:
  %t227 = load i64, i64* %t220
  %t228 = icmp slt i64 %t227, %t217
  br i1 %t228, label %map_insert_overwrite_50, label %map_insert_new_51
map_insert_overwrite_50:
  %t229 = load i32*, i32** %t211
  %t230 = getelementptr inbounds i32, i32* %t229, i64 %t227
  store i32 100, i32* %t230
  br label %map_insert_after_52
map_insert_new_51:
  %t231 = load i64, i64* %t215
  %t232 = icmp sge i64 %t217, %t231
  br i1 %t232, label %map_insert_grow_53, label %map_insert_store_54
map_insert_grow_53:
  %t233 = mul i64 %t231, 2
  %t234 = icmp sgt i64 %t233, 0
  %t235 = select i1 %t234, i64 %t233, i64 1
  %t236 = getelementptr i64, i64* null, i32 1
  %t237 = ptrtoint i64* %t236 to i64
  %t238 = mul i64 %t235, %t237
  %t239 = call i8* @malloc(i64 %t238)
  %t240 = bitcast i8* %t239 to i64*
  %t241 = getelementptr i32, i32* null, i32 1
  %t242 = ptrtoint i32* %t241 to i64
  %t243 = mul i64 %t235, %t242
  %t244 = call i8* @malloc(i64 %t243)
  %t245 = bitcast i8* %t244 to i32*
  %t246 = icmp sgt i64 %t231, 0
  br i1 %t246, label %map_insert_copy_55, label %map_insert_after_copy_56
map_insert_copy_55:
  %t247 = load i64*, i64** %t209
  %t248 = mul i64 %t217, %t237
  %t249 = bitcast i64* %t247 to i8*
  call i8* @memcpy(i8* %t239, i8* %t249, i64 %t248)
  call void @free(i8* %t249)
  %t250 = load i32*, i32** %t211
  %t251 = mul i64 %t217, %t242
  %t252 = bitcast i32* %t250 to i8*
  call i8* @memcpy(i8* %t244, i8* %t252, i64 %t251)
  call void @free(i8* %t252)
  br label %map_insert_after_copy_56
map_insert_after_copy_56:
  store i64* %t240, i64** %t209
  store i32* %t245, i32** %t211
  store i64 %t235, i64* %t215
  br label %map_insert_store_54
map_insert_store_54:
  %t253 = load i64*, i64** %t209
  %t254 = load i32*, i32** %t211
  %t255 = getelementptr inbounds i64, i64* %t253, i64 %t217
  store i64 %t216, i64* %t255
  %t256 = getelementptr inbounds i32, i32* %t254, i64 %t217
  store i32 100, i32* %t256
  %t257 = add i64 %t217, 1
  store i64 %t257, i64* %t213
  br label %map_insert_after_52
map_insert_after_52:
  %t258 = getelementptr i64, i64* null, i32 1
  %t259 = ptrtoint i64* %t258 to i64
  %t260 = getelementptr i32, i32* null, i32 1
  %t261 = ptrtoint i32* %t260 to i64
  %t262 = load i8*, i8** %t155
  %t263 = icmp eq i8* %t262, null
  br i1 %t263, label %map_cow_alloc_57, label %map_cow_check_58
map_cow_alloc_57:
  %t264 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t265 = call i8* @star_rc_alloc(i64 32, i8* %t264)
  %t266 = bitcast i8* %t265 to { i64*, i32*, i64, i64 }*
  %t267 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t266, i32 0, i32 0
  store i64* null, i64** %t267
  %t268 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t266, i32 0, i32 1
  store i32* null, i32** %t268
  %t269 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t266, i32 0, i32 2
  store i64 0, i64* %t269
  %t270 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t266, i32 0, i32 3
  store i64 0, i64* %t270
  store i8* %t265, i8** %t155
  br label %map_cow_done_59
map_cow_check_58:
  %t271 = getelementptr inbounds i8, i8* %t262, i64 -16
  %t272 = bitcast i8* %t271 to i64*
  %t273 = load atomic i64, i64* %t272 seq_cst, align 8
  %t274 = icmp eq i64 %t273, 1
  br i1 %t274, label %map_cow_done_59, label %map_cow_clone_60
map_cow_clone_60:
  %t275 = bitcast i8* %t262 to { i64*, i32*, i64, i64 }*
  %t276 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t275, i32 0, i32 0
  %t277 = load i64*, i64** %t276
  %t278 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t275, i32 0, i32 1
  %t279 = load i32*, i32** %t278
  %t280 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t275, i32 0, i32 2
  %t281 = load i64, i64* %t280
  %t282 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t275, i32 0, i32 3
  %t283 = load i64, i64* %t282
  %t284 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t285 = call i8* @star_rc_alloc(i64 32, i8* %t284)
  %t286 = bitcast i8* %t285 to { i64*, i32*, i64, i64 }*
  %t287 = mul i64 %t283, %t259
  %t288 = call i8* @malloc(i64 %t287)
  %t289 = bitcast i8* %t288 to i64*
  %t290 = mul i64 %t283, %t261
  %t291 = call i8* @malloc(i64 %t290)
  %t292 = bitcast i8* %t291 to i32*
  %t293 = icmp sgt i64 %t281, 0
  br i1 %t293, label %map_cow_copy_61, label %map_cow_after_copy_62
map_cow_copy_61:
  %t294 = mul i64 %t281, %t259
  %t295 = bitcast i64* %t277 to i8*
  call i8* @memcpy(i8* %t288, i8* %t295, i64 %t294)
  %t296 = mul i64 %t281, %t261
  %t297 = bitcast i32* %t279 to i8*
  call i8* @memcpy(i8* %t291, i8* %t297, i64 %t296)
  br label %map_cow_after_copy_62
map_cow_after_copy_62:
  %t298 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t286, i32 0, i32 0
  store i64* %t289, i64** %t298
  %t299 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t286, i32 0, i32 1
  store i32* %t292, i32** %t299
  %t300 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t286, i32 0, i32 2
  store i64 %t281, i64* %t300
  %t301 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t286, i32 0, i32 3
  store i64 %t283, i64* %t301
  call void @star_rc_release(i8* %t262)
  store i8* %t285, i8** %t155
  br label %map_cow_done_59
map_cow_done_59:
  %t302 = load i8*, i8** %t155
  %t303 = bitcast i8* %t302 to { i64*, i32*, i64, i64 }*
  %t304 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t303, i32 0, i32 0
  %t305 = load i64*, i64** %t304
  %t306 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t303, i32 0, i32 1
  %t307 = load i32*, i32** %t306
  %t308 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t303, i32 0, i32 2
  %t309 = load i64, i64* %t308
  %t310 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t303, i32 0, i32 3
  %t311 = load i64, i64* %t58
  %t312 = load i64, i64* %t308
  %t313 = load i64*, i64** %t304
  store i64 0, i64* %t314
  br label %map_find_cond_63
map_find_cond_63:
  %t315 = load i64, i64* %t314
  %t316 = icmp slt i64 %t315, %t312
  br i1 %t316, label %map_find_body_64, label %map_find_end_67
map_find_body_64:
  %t317 = getelementptr inbounds i64, i64* %t313, i64 %t315
  %t318 = load i64, i64* %t317
  br label %map_find_eq_check_65
map_find_eq_check_65:
  %t319 = call i1 @eq_symbol(i64 %t318, i64 %t311)
  br i1 %t319, label %map_find_end_67, label %map_find_next_66
map_find_next_66:
  %t320 = add i64 %t315, 1
  store i64 %t320, i64* %t314
  br label %map_find_cond_63
map_find_end_67:
  %t321 = load i64, i64* %t314
  %t322 = icmp slt i64 %t321, %t312
  br i1 %t322, label %map_insert_overwrite_68, label %map_insert_new_69
map_insert_overwrite_68:
  %t323 = load i32*, i32** %t306
  %t324 = getelementptr inbounds i32, i32* %t323, i64 %t321
  store i32 40, i32* %t324
  br label %map_insert_after_70
map_insert_new_69:
  %t325 = load i64, i64* %t310
  %t326 = icmp sge i64 %t312, %t325
  br i1 %t326, label %map_insert_grow_71, label %map_insert_store_72
map_insert_grow_71:
  %t327 = mul i64 %t325, 2
  %t328 = icmp sgt i64 %t327, 0
  %t329 = select i1 %t328, i64 %t327, i64 1
  %t330 = getelementptr i64, i64* null, i32 1
  %t331 = ptrtoint i64* %t330 to i64
  %t332 = mul i64 %t329, %t331
  %t333 = call i8* @malloc(i64 %t332)
  %t334 = bitcast i8* %t333 to i64*
  %t335 = getelementptr i32, i32* null, i32 1
  %t336 = ptrtoint i32* %t335 to i64
  %t337 = mul i64 %t329, %t336
  %t338 = call i8* @malloc(i64 %t337)
  %t339 = bitcast i8* %t338 to i32*
  %t340 = icmp sgt i64 %t325, 0
  br i1 %t340, label %map_insert_copy_73, label %map_insert_after_copy_74
map_insert_copy_73:
  %t341 = load i64*, i64** %t304
  %t342 = mul i64 %t312, %t331
  %t343 = bitcast i64* %t341 to i8*
  call i8* @memcpy(i8* %t333, i8* %t343, i64 %t342)
  call void @free(i8* %t343)
  %t344 = load i32*, i32** %t306
  %t345 = mul i64 %t312, %t336
  %t346 = bitcast i32* %t344 to i8*
  call i8* @memcpy(i8* %t338, i8* %t346, i64 %t345)
  call void @free(i8* %t346)
  br label %map_insert_after_copy_74
map_insert_after_copy_74:
  store i64* %t334, i64** %t304
  store i32* %t339, i32** %t306
  store i64 %t329, i64* %t310
  br label %map_insert_store_72
map_insert_store_72:
  %t347 = load i64*, i64** %t304
  %t348 = load i32*, i32** %t306
  %t349 = getelementptr inbounds i64, i64* %t347, i64 %t312
  store i64 %t311, i64* %t349
  %t350 = getelementptr inbounds i32, i32* %t348, i64 %t312
  store i32 40, i32* %t350
  %t351 = add i64 %t312, 1
  store i64 %t351, i64* %t308
  br label %map_insert_after_70
map_insert_after_70:
  %t352 = getelementptr i64, i64* null, i32 1
  %t353 = ptrtoint i64* %t352 to i64
  %t354 = getelementptr i32, i32* null, i32 1
  %t355 = ptrtoint i32* %t354 to i64
  %t356 = load i8*, i8** %t155
  %t357 = icmp eq i8* %t356, null
  br i1 %t357, label %map_cow_alloc_75, label %map_cow_check_76
map_cow_alloc_75:
  %t358 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t359 = call i8* @star_rc_alloc(i64 32, i8* %t358)
  %t360 = bitcast i8* %t359 to { i64*, i32*, i64, i64 }*
  %t361 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t360, i32 0, i32 0
  store i64* null, i64** %t361
  %t362 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t360, i32 0, i32 1
  store i32* null, i32** %t362
  %t363 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t360, i32 0, i32 2
  store i64 0, i64* %t363
  %t364 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t360, i32 0, i32 3
  store i64 0, i64* %t364
  store i8* %t359, i8** %t155
  br label %map_cow_done_77
map_cow_check_76:
  %t365 = getelementptr inbounds i8, i8* %t356, i64 -16
  %t366 = bitcast i8* %t365 to i64*
  %t367 = load atomic i64, i64* %t366 seq_cst, align 8
  %t368 = icmp eq i64 %t367, 1
  br i1 %t368, label %map_cow_done_77, label %map_cow_clone_78
map_cow_clone_78:
  %t369 = bitcast i8* %t356 to { i64*, i32*, i64, i64 }*
  %t370 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t369, i32 0, i32 0
  %t371 = load i64*, i64** %t370
  %t372 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t369, i32 0, i32 1
  %t373 = load i32*, i32** %t372
  %t374 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t369, i32 0, i32 2
  %t375 = load i64, i64* %t374
  %t376 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t369, i32 0, i32 3
  %t377 = load i64, i64* %t376
  %t378 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t379 = call i8* @star_rc_alloc(i64 32, i8* %t378)
  %t380 = bitcast i8* %t379 to { i64*, i32*, i64, i64 }*
  %t381 = mul i64 %t377, %t353
  %t382 = call i8* @malloc(i64 %t381)
  %t383 = bitcast i8* %t382 to i64*
  %t384 = mul i64 %t377, %t355
  %t385 = call i8* @malloc(i64 %t384)
  %t386 = bitcast i8* %t385 to i32*
  %t387 = icmp sgt i64 %t375, 0
  br i1 %t387, label %map_cow_copy_79, label %map_cow_after_copy_80
map_cow_copy_79:
  %t388 = mul i64 %t375, %t353
  %t389 = bitcast i64* %t371 to i8*
  call i8* @memcpy(i8* %t382, i8* %t389, i64 %t388)
  %t390 = mul i64 %t375, %t355
  %t391 = bitcast i32* %t373 to i8*
  call i8* @memcpy(i8* %t385, i8* %t391, i64 %t390)
  br label %map_cow_after_copy_80
map_cow_after_copy_80:
  %t392 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t380, i32 0, i32 0
  store i64* %t383, i64** %t392
  %t393 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t380, i32 0, i32 1
  store i32* %t386, i32** %t393
  %t394 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t380, i32 0, i32 2
  store i64 %t375, i64* %t394
  %t395 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t380, i32 0, i32 3
  store i64 %t377, i64* %t395
  call void @star_rc_release(i8* %t356)
  store i8* %t379, i8** %t155
  br label %map_cow_done_77
map_cow_done_77:
  %t396 = load i8*, i8** %t155
  %t397 = bitcast i8* %t396 to { i64*, i32*, i64, i64 }*
  %t398 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t397, i32 0, i32 0
  %t399 = load i64*, i64** %t398
  %t400 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t397, i32 0, i32 1
  %t401 = load i32*, i32** %t400
  %t402 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t397, i32 0, i32 2
  %t403 = load i64, i64* %t402
  %t404 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t397, i32 0, i32 3
  %t405 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.23, i64 0, i32 2, i64 0
  %t406 = load i64, i64* @sym.len
  %t407 = load i8**, i8*** @sym.data
  store i64 0, i64* %t408
  br label %sym_find_cond_81
sym_find_cond_81:
  %t409 = load i64, i64* %t408
  %t410 = icmp slt i64 %t409, %t406
  br i1 %t410, label %sym_find_body_82, label %sym_find_end_84
sym_find_body_82:
  %t411 = getelementptr inbounds i8*, i8** %t407, i64 %t409
  %t412 = load i8*, i8** %t411
  %t413 = call i32 @strcmp(i8* %t412, i8* %t405)
  %t414 = icmp eq i32 %t413, 0
  br i1 %t414, label %sym_find_end_84, label %sym_find_next_83
sym_find_next_83:
  %t415 = add i64 %t409, 1
  store i64 %t415, i64* %t408
  br label %sym_find_cond_81
sym_find_end_84:
  %t416 = load i64, i64* %t408
  %t417 = icmp slt i64 %t416, %t406
  br i1 %t417, label %sym_found_85, label %sym_notfound_86
sym_found_85:
  call void @star_rc_release(i8* %t405)
  br label %sym_done_87
sym_notfound_86:
  %t418 = load i64, i64* @sym.cap
  %t419 = icmp sge i64 %t406, %t418
  br i1 %t419, label %sym_grow_88, label %sym_store_89
sym_grow_88:
  %t420 = mul i64 %t418, 2
  %t421 = icmp sgt i64 %t420, 0
  %t422 = select i1 %t421, i64 %t420, i64 1
  %t423 = mul i64 %t422, 8
  %t424 = call i8* @malloc(i64 %t423)
  %t425 = bitcast i8* %t424 to i8**
  %t426 = icmp sgt i64 %t418, 0
  br i1 %t426, label %sym_copy_90, label %sym_after_copy_91
sym_copy_90:
  %t427 = mul i64 %t406, 8
  %t428 = bitcast i8** %t407 to i8*
  call i8* @memcpy(i8* %t424, i8* %t428, i64 %t427)
  call void @free(i8* %t428)
  br label %sym_after_copy_91
sym_after_copy_91:
  store i8** %t425, i8*** @sym.data
  store i64 %t422, i64* @sym.cap
  br label %sym_store_89
sym_store_89:
  %t429 = load i8**, i8*** @sym.data
  %t430 = getelementptr inbounds i8*, i8** %t429, i64 %t406
  store i8* %t405, i8** %t430
  %t431 = add i64 %t406, 1
  store i64 %t431, i64* @sym.len
  br label %sym_done_87
sym_done_87:
  %t432 = phi i64 [ %t416, %sym_found_85 ], [ %t406, %sym_store_89 ]
  %t433 = load i64, i64* %t402
  %t434 = load i64*, i64** %t398
  store i64 0, i64* %t435
  br label %map_find_cond_92
map_find_cond_92:
  %t436 = load i64, i64* %t435
  %t437 = icmp slt i64 %t436, %t433
  br i1 %t437, label %map_find_body_93, label %map_find_end_96
map_find_body_93:
  %t438 = getelementptr inbounds i64, i64* %t434, i64 %t436
  %t439 = load i64, i64* %t438
  br label %map_find_eq_check_94
map_find_eq_check_94:
  %t440 = call i1 @eq_symbol(i64 %t439, i64 %t432)
  br i1 %t440, label %map_find_end_96, label %map_find_next_95
map_find_next_95:
  %t441 = add i64 %t436, 1
  store i64 %t441, i64* %t435
  br label %map_find_cond_92
map_find_end_96:
  %t442 = load i64, i64* %t435
  %t443 = icmp slt i64 %t442, %t433
  br i1 %t443, label %map_insert_overwrite_97, label %map_insert_new_98
map_insert_overwrite_97:
  %t444 = load i32*, i32** %t400
  %t445 = getelementptr inbounds i32, i32* %t444, i64 %t442
  store i32 80, i32* %t445
  br label %map_insert_after_99
map_insert_new_98:
  %t446 = load i64, i64* %t404
  %t447 = icmp sge i64 %t433, %t446
  br i1 %t447, label %map_insert_grow_100, label %map_insert_store_101
map_insert_grow_100:
  %t448 = mul i64 %t446, 2
  %t449 = icmp sgt i64 %t448, 0
  %t450 = select i1 %t449, i64 %t448, i64 1
  %t451 = getelementptr i64, i64* null, i32 1
  %t452 = ptrtoint i64* %t451 to i64
  %t453 = mul i64 %t450, %t452
  %t454 = call i8* @malloc(i64 %t453)
  %t455 = bitcast i8* %t454 to i64*
  %t456 = getelementptr i32, i32* null, i32 1
  %t457 = ptrtoint i32* %t456 to i64
  %t458 = mul i64 %t450, %t457
  %t459 = call i8* @malloc(i64 %t458)
  %t460 = bitcast i8* %t459 to i32*
  %t461 = icmp sgt i64 %t446, 0
  br i1 %t461, label %map_insert_copy_102, label %map_insert_after_copy_103
map_insert_copy_102:
  %t462 = load i64*, i64** %t398
  %t463 = mul i64 %t433, %t452
  %t464 = bitcast i64* %t462 to i8*
  call i8* @memcpy(i8* %t454, i8* %t464, i64 %t463)
  call void @free(i8* %t464)
  %t465 = load i32*, i32** %t400
  %t466 = mul i64 %t433, %t457
  %t467 = bitcast i32* %t465 to i8*
  call i8* @memcpy(i8* %t459, i8* %t467, i64 %t466)
  call void @free(i8* %t467)
  br label %map_insert_after_copy_103
map_insert_after_copy_103:
  store i64* %t455, i64** %t398
  store i32* %t460, i32** %t400
  store i64 %t450, i64* %t404
  br label %map_insert_store_101
map_insert_store_101:
  %t468 = load i64*, i64** %t398
  %t469 = load i32*, i32** %t400
  %t470 = getelementptr inbounds i64, i64* %t468, i64 %t433
  store i64 %t432, i64* %t470
  %t471 = getelementptr inbounds i32, i32* %t469, i64 %t433
  store i32 80, i32* %t471
  %t472 = add i64 %t433, 1
  store i64 %t472, i64* %t402
  br label %map_insert_after_99
map_insert_after_99:
  %t473 = load i8*, i8** %t155
  %t474 = icmp eq i8* %t473, null
  br i1 %t474, label %map_read_null_104, label %map_read_real_105
map_read_null_104:
  br label %map_read_end_106
map_read_real_105:
  %t475 = bitcast i8* %t473 to { i64*, i32*, i64, i64 }*
  %t476 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t475, i32 0, i32 0
  %t477 = load i64*, i64** %t476
  %t478 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t475, i32 0, i32 1
  %t479 = load i32*, i32** %t478
  %t480 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t475, i32 0, i32 2
  %t481 = load i64, i64* %t480
  br label %map_read_end_106
map_read_end_106:
  %t482 = phi i64* [ null, %map_read_null_104 ], [ %t477, %map_read_real_105 ]
  %t483 = phi i32* [ null, %map_read_null_104 ], [ %t479, %map_read_real_105 ]
  %t484 = phi i64 [ 0, %map_read_null_104 ], [ %t481, %map_read_real_105 ]
  %t485 = trunc i64 %t484 to i32
  %t486 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.24, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t486, i32 %t485)
  %t487 = load i64, i64* %t0
  %t488 = load i8*, i8** %t155
  %t489 = icmp eq i8* %t488, null
  br i1 %t489, label %map_read_null_107, label %map_read_real_108
map_read_null_107:
  br label %map_read_end_109
map_read_real_108:
  %t490 = bitcast i8* %t488 to { i64*, i32*, i64, i64 }*
  %t491 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t490, i32 0, i32 0
  %t492 = load i64*, i64** %t491
  %t493 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t490, i32 0, i32 1
  %t494 = load i32*, i32** %t493
  %t495 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t490, i32 0, i32 2
  %t496 = load i64, i64* %t495
  br label %map_read_end_109
map_read_end_109:
  %t497 = phi i64* [ null, %map_read_null_107 ], [ %t492, %map_read_real_108 ]
  %t498 = phi i32* [ null, %map_read_null_107 ], [ %t494, %map_read_real_108 ]
  %t499 = phi i64 [ 0, %map_read_null_107 ], [ %t496, %map_read_real_108 ]
  store i64 0, i64* %t500
  br label %map_find_cond_110
map_find_cond_110:
  %t501 = load i64, i64* %t500
  %t502 = icmp slt i64 %t501, %t499
  br i1 %t502, label %map_find_body_111, label %map_find_end_114
map_find_body_111:
  %t503 = getelementptr inbounds i64, i64* %t497, i64 %t501
  %t504 = load i64, i64* %t503
  br label %map_find_eq_check_112
map_find_eq_check_112:
  %t505 = call i1 @eq_symbol(i64 %t504, i64 %t487)
  br i1 %t505, label %map_find_end_114, label %map_find_next_113
map_find_next_113:
  %t506 = add i64 %t501, 1
  store i64 %t506, i64* %t500
  br label %map_find_cond_110
map_find_end_114:
  %t507 = load i64, i64* %t500
  %t508 = icmp slt i64 %t507, %t499
  br i1 %t508, label %map_get_some_115, label %map_get_none_116
map_get_some_115:
  %t509 = getelementptr inbounds i32, i32* %t498, i64 %t507
  %t510 = load i32, i32* %t509
  %t512 = getelementptr inbounds %Option__i32, %Option__i32* %t511, i32 0, i32 0
  store i32 1, i32* %t512
  %t513 = getelementptr inbounds %Option__i32, %Option__i32* %t511, i32 0, i32 1
  %t514 = bitcast [1 x i64]* %t513 to { i32 }*
  %t515 = getelementptr inbounds { i32 }, { i32 }* %t514, i32 0, i32 0
  store i32 %t510, i32* %t515
  %t516 = load %Option__i32, %Option__i32* %t511
  br label %map_get_end_117
map_get_none_116:
  %t518 = getelementptr inbounds %Option__i32, %Option__i32* %t517, i32 0, i32 0
  store i32 0, i32* %t518
  %t519 = load %Option__i32, %Option__i32* %t517
  br label %map_get_end_117
map_get_end_117:
  %t520 = phi %Option__i32 [ %t516, %map_get_some_115 ], [ %t519, %map_get_none_116 ]
  store %Option__i32 %t520, %Option__i32* %t521
  br label %match_scrutinee_523
match_scrutinee_523:
  %t527 = getelementptr inbounds %Option__i32, %Option__i32* %t521, i32 0, i32 0
  %t528 = load i32, i32* %t527
  %t526 = icmp eq i32 %t528, 1
  br i1 %t526, label %match_then_0_524, label %match_next_0_525
match_then_0_524:
  %t529 = getelementptr inbounds %Option__i32, %Option__i32* %t521, i32 0, i32 1
  %t530 = bitcast [1 x i64]* %t529 to { i32 }*
  %t531 = getelementptr inbounds { i32 }, { i32 }* %t530, i32 0, i32 0
  %t532 = load i32, i32* %t531
  %t533 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.25, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t533, i32 %t532)
  br label %match_end_522
match_next_0_525:
  %t537 = getelementptr inbounds %Option__i32, %Option__i32* %t521, i32 0, i32 0
  %t538 = load i32, i32* %t537
  %t536 = icmp eq i32 %t538, 0
  br i1 %t536, label %match_then_1_534, label %match_next_1_535
match_then_1_534:
  %t539 = getelementptr inbounds { i64, i8*, [18 x i8] }, { i64, i8*, [18 x i8] }* @.str.26, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t539)
  call i32 (i8*, ...) @printf(i8* %t539)
  br label %match_end_522
match_next_1_535:
  br label %match_end_522
match_end_522:
  store i8* null, i8** %t540
  %t541 = getelementptr i64, i64* null, i32 1
  %t542 = ptrtoint i64* %t541 to i64
  %t543 = load i8*, i8** %t540
  %t544 = icmp eq i8* %t543, null
  br i1 %t544, label %set_cow_alloc_118, label %set_cow_check_119
set_cow_alloc_118:
  %t549 = bitcast void (i8*)* @set_release_symbol to i8*
  %t550 = call i8* @star_rc_alloc(i64 24, i8* %t549)
  %t551 = bitcast i8* %t550 to { i64*, i64, i64 }*
  %t552 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t551, i32 0, i32 0
  store i64* null, i64** %t552
  %t553 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t551, i32 0, i32 1
  store i64 0, i64* %t553
  %t554 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t551, i32 0, i32 2
  store i64 0, i64* %t554
  store i8* %t550, i8** %t540
  br label %set_cow_done_120
set_cow_check_119:
  %t555 = getelementptr inbounds i8, i8* %t543, i64 -16
  %t556 = bitcast i8* %t555 to i64*
  %t557 = load atomic i64, i64* %t556 seq_cst, align 8
  %t558 = icmp eq i64 %t557, 1
  br i1 %t558, label %set_cow_done_120, label %set_cow_clone_121
set_cow_clone_121:
  %t559 = bitcast i8* %t543 to { i64*, i64, i64 }*
  %t560 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t559, i32 0, i32 0
  %t561 = load i64*, i64** %t560
  %t562 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t559, i32 0, i32 1
  %t563 = load i64, i64* %t562
  %t564 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t559, i32 0, i32 2
  %t565 = load i64, i64* %t564
  %t566 = bitcast void (i8*)* @set_release_symbol to i8*
  %t567 = call i8* @star_rc_alloc(i64 24, i8* %t566)
  %t568 = bitcast i8* %t567 to { i64*, i64, i64 }*
  %t569 = mul i64 %t565, %t542
  %t570 = call i8* @malloc(i64 %t569)
  %t571 = bitcast i8* %t570 to i64*
  %t572 = icmp sgt i64 %t563, 0
  br i1 %t572, label %set_cow_copy_122, label %set_cow_after_copy_123
set_cow_copy_122:
  %t573 = mul i64 %t563, %t542
  %t574 = bitcast i64* %t561 to i8*
  call i8* @memcpy(i8* %t570, i8* %t574, i64 %t573)
  br label %set_cow_after_copy_123
set_cow_after_copy_123:
  %t575 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t568, i32 0, i32 0
  store i64* %t571, i64** %t575
  %t576 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t568, i32 0, i32 1
  store i64 %t563, i64* %t576
  %t577 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t568, i32 0, i32 2
  store i64 %t565, i64* %t577
  call void @star_rc_release(i8* %t543)
  store i8* %t567, i8** %t540
  br label %set_cow_done_120
set_cow_done_120:
  %t578 = load i8*, i8** %t540
  %t579 = bitcast i8* %t578 to { i64*, i64, i64 }*
  %t580 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t579, i32 0, i32 0
  %t581 = load i64*, i64** %t580
  %t582 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t579, i32 0, i32 1
  %t583 = load i64, i64* %t582
  %t584 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t579, i32 0, i32 2
  %t585 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.27, i64 0, i32 2, i64 0
  %t586 = load i64, i64* @sym.len
  %t587 = load i8**, i8*** @sym.data
  store i64 0, i64* %t588
  br label %sym_find_cond_124
sym_find_cond_124:
  %t589 = load i64, i64* %t588
  %t590 = icmp slt i64 %t589, %t586
  br i1 %t590, label %sym_find_body_125, label %sym_find_end_127
sym_find_body_125:
  %t591 = getelementptr inbounds i8*, i8** %t587, i64 %t589
  %t592 = load i8*, i8** %t591
  %t593 = call i32 @strcmp(i8* %t592, i8* %t585)
  %t594 = icmp eq i32 %t593, 0
  br i1 %t594, label %sym_find_end_127, label %sym_find_next_126
sym_find_next_126:
  %t595 = add i64 %t589, 1
  store i64 %t595, i64* %t588
  br label %sym_find_cond_124
sym_find_end_127:
  %t596 = load i64, i64* %t588
  %t597 = icmp slt i64 %t596, %t586
  br i1 %t597, label %sym_found_128, label %sym_notfound_129
sym_found_128:
  call void @star_rc_release(i8* %t585)
  br label %sym_done_130
sym_notfound_129:
  %t598 = load i64, i64* @sym.cap
  %t599 = icmp sge i64 %t586, %t598
  br i1 %t599, label %sym_grow_131, label %sym_store_132
sym_grow_131:
  %t600 = mul i64 %t598, 2
  %t601 = icmp sgt i64 %t600, 0
  %t602 = select i1 %t601, i64 %t600, i64 1
  %t603 = mul i64 %t602, 8
  %t604 = call i8* @malloc(i64 %t603)
  %t605 = bitcast i8* %t604 to i8**
  %t606 = icmp sgt i64 %t598, 0
  br i1 %t606, label %sym_copy_133, label %sym_after_copy_134
sym_copy_133:
  %t607 = mul i64 %t586, 8
  %t608 = bitcast i8** %t587 to i8*
  call i8* @memcpy(i8* %t604, i8* %t608, i64 %t607)
  call void @free(i8* %t608)
  br label %sym_after_copy_134
sym_after_copy_134:
  store i8** %t605, i8*** @sym.data
  store i64 %t602, i64* @sym.cap
  br label %sym_store_132
sym_store_132:
  %t609 = load i8**, i8*** @sym.data
  %t610 = getelementptr inbounds i8*, i8** %t609, i64 %t586
  store i8* %t585, i8** %t610
  %t611 = add i64 %t586, 1
  store i64 %t611, i64* @sym.len
  br label %sym_done_130
sym_done_130:
  %t612 = phi i64 [ %t596, %sym_found_128 ], [ %t586, %sym_store_132 ]
  %t613 = load i64, i64* %t582
  %t614 = load i64*, i64** %t580
  store i64 0, i64* %t615
  store i1 false, i1* %t616
  br label %find_cond_135
find_cond_135:
  %t617 = load i64, i64* %t615
  %t618 = icmp slt i64 %t617, %t613
  br i1 %t618, label %find_body_136, label %find_end_139
find_body_136:
  %t619 = getelementptr inbounds i64, i64* %t614, i64 %t617
  %t620 = load i64, i64* %t619
  br label %find_eq_check_137
find_eq_check_137:
  %t621 = call i1 @eq_symbol(i64 %t620, i64 %t612)
  br i1 %t621, label %find_end_139, label %find_next_138
find_next_138:
  %t622 = add i64 %t617, 1
  store i64 %t622, i64* %t615
  br label %find_cond_135
find_end_139:
  %t623 = load i64, i64* %t615
  %t624 = icmp slt i64 %t623, %t613
  br i1 %t624, label %set_insert_already_present_140, label %set_insert_do_141
set_insert_already_present_140:
  br label %set_insert_end_142
set_insert_do_141:
  %t625 = load i64, i64* %t584
  %t626 = load i64*, i64** %t580
  %t627 = icmp sge i64 %t613, %t625
  br i1 %t627, label %set_insert_grow_143, label %set_insert_store_144
set_insert_grow_143:
  %t628 = mul i64 %t625, 2
  %t629 = icmp sgt i64 %t628, 0
  %t630 = select i1 %t629, i64 %t628, i64 1
  %t631 = getelementptr i64, i64* null, i32 1
  %t632 = ptrtoint i64* %t631 to i64
  %t633 = mul i64 %t630, %t632
  %t634 = call i8* @malloc(i64 %t633)
  %t635 = bitcast i8* %t634 to i64*
  %t636 = icmp sgt i64 %t625, 0
  br i1 %t636, label %set_insert_copy_145, label %set_insert_after_copy_146
set_insert_copy_145:
  %t637 = mul i64 %t613, %t632
  %t638 = bitcast i64* %t626 to i8*
  call i8* @memcpy(i8* %t634, i8* %t638, i64 %t637)
  call void @free(i8* %t638)
  br label %set_insert_after_copy_146
set_insert_after_copy_146:
  store i64* %t635, i64** %t580
  store i64 %t630, i64* %t584
  br label %set_insert_store_144
set_insert_store_144:
  %t639 = load i64*, i64** %t580
  %t640 = getelementptr inbounds i64, i64* %t639, i64 %t613
  store i64 %t612, i64* %t640
  %t641 = add i64 %t613, 1
  store i64 %t641, i64* %t582
  br label %set_insert_end_142
set_insert_end_142:
  %t642 = phi i1 [ false, %set_insert_already_present_140 ], [ true, %set_insert_store_144 ]
  %t643 = getelementptr i64, i64* null, i32 1
  %t644 = ptrtoint i64* %t643 to i64
  %t645 = load i8*, i8** %t540
  %t646 = icmp eq i8* %t645, null
  br i1 %t646, label %set_cow_alloc_147, label %set_cow_check_148
set_cow_alloc_147:
  %t647 = bitcast void (i8*)* @set_release_symbol to i8*
  %t648 = call i8* @star_rc_alloc(i64 24, i8* %t647)
  %t649 = bitcast i8* %t648 to { i64*, i64, i64 }*
  %t650 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t649, i32 0, i32 0
  store i64* null, i64** %t650
  %t651 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t649, i32 0, i32 1
  store i64 0, i64* %t651
  %t652 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t649, i32 0, i32 2
  store i64 0, i64* %t652
  store i8* %t648, i8** %t540
  br label %set_cow_done_149
set_cow_check_148:
  %t653 = getelementptr inbounds i8, i8* %t645, i64 -16
  %t654 = bitcast i8* %t653 to i64*
  %t655 = load atomic i64, i64* %t654 seq_cst, align 8
  %t656 = icmp eq i64 %t655, 1
  br i1 %t656, label %set_cow_done_149, label %set_cow_clone_150
set_cow_clone_150:
  %t657 = bitcast i8* %t645 to { i64*, i64, i64 }*
  %t658 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t657, i32 0, i32 0
  %t659 = load i64*, i64** %t658
  %t660 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t657, i32 0, i32 1
  %t661 = load i64, i64* %t660
  %t662 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t657, i32 0, i32 2
  %t663 = load i64, i64* %t662
  %t664 = bitcast void (i8*)* @set_release_symbol to i8*
  %t665 = call i8* @star_rc_alloc(i64 24, i8* %t664)
  %t666 = bitcast i8* %t665 to { i64*, i64, i64 }*
  %t667 = mul i64 %t663, %t644
  %t668 = call i8* @malloc(i64 %t667)
  %t669 = bitcast i8* %t668 to i64*
  %t670 = icmp sgt i64 %t661, 0
  br i1 %t670, label %set_cow_copy_151, label %set_cow_after_copy_152
set_cow_copy_151:
  %t671 = mul i64 %t661, %t644
  %t672 = bitcast i64* %t659 to i8*
  call i8* @memcpy(i8* %t668, i8* %t672, i64 %t671)
  br label %set_cow_after_copy_152
set_cow_after_copy_152:
  %t673 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t666, i32 0, i32 0
  store i64* %t669, i64** %t673
  %t674 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t666, i32 0, i32 1
  store i64 %t661, i64* %t674
  %t675 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t666, i32 0, i32 2
  store i64 %t663, i64* %t675
  call void @star_rc_release(i8* %t645)
  store i8* %t665, i8** %t540
  br label %set_cow_done_149
set_cow_done_149:
  %t676 = load i8*, i8** %t540
  %t677 = bitcast i8* %t676 to { i64*, i64, i64 }*
  %t678 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t677, i32 0, i32 0
  %t679 = load i64*, i64** %t678
  %t680 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t677, i32 0, i32 1
  %t681 = load i64, i64* %t680
  %t682 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t677, i32 0, i32 2
  %t683 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.28, i64 0, i32 2, i64 0
  %t684 = load i64, i64* @sym.len
  %t685 = load i8**, i8*** @sym.data
  store i64 0, i64* %t686
  br label %sym_find_cond_153
sym_find_cond_153:
  %t687 = load i64, i64* %t686
  %t688 = icmp slt i64 %t687, %t684
  br i1 %t688, label %sym_find_body_154, label %sym_find_end_156
sym_find_body_154:
  %t689 = getelementptr inbounds i8*, i8** %t685, i64 %t687
  %t690 = load i8*, i8** %t689
  %t691 = call i32 @strcmp(i8* %t690, i8* %t683)
  %t692 = icmp eq i32 %t691, 0
  br i1 %t692, label %sym_find_end_156, label %sym_find_next_155
sym_find_next_155:
  %t693 = add i64 %t687, 1
  store i64 %t693, i64* %t686
  br label %sym_find_cond_153
sym_find_end_156:
  %t694 = load i64, i64* %t686
  %t695 = icmp slt i64 %t694, %t684
  br i1 %t695, label %sym_found_157, label %sym_notfound_158
sym_found_157:
  call void @star_rc_release(i8* %t683)
  br label %sym_done_159
sym_notfound_158:
  %t696 = load i64, i64* @sym.cap
  %t697 = icmp sge i64 %t684, %t696
  br i1 %t697, label %sym_grow_160, label %sym_store_161
sym_grow_160:
  %t698 = mul i64 %t696, 2
  %t699 = icmp sgt i64 %t698, 0
  %t700 = select i1 %t699, i64 %t698, i64 1
  %t701 = mul i64 %t700, 8
  %t702 = call i8* @malloc(i64 %t701)
  %t703 = bitcast i8* %t702 to i8**
  %t704 = icmp sgt i64 %t696, 0
  br i1 %t704, label %sym_copy_162, label %sym_after_copy_163
sym_copy_162:
  %t705 = mul i64 %t684, 8
  %t706 = bitcast i8** %t685 to i8*
  call i8* @memcpy(i8* %t702, i8* %t706, i64 %t705)
  call void @free(i8* %t706)
  br label %sym_after_copy_163
sym_after_copy_163:
  store i8** %t703, i8*** @sym.data
  store i64 %t700, i64* @sym.cap
  br label %sym_store_161
sym_store_161:
  %t707 = load i8**, i8*** @sym.data
  %t708 = getelementptr inbounds i8*, i8** %t707, i64 %t684
  store i8* %t683, i8** %t708
  %t709 = add i64 %t684, 1
  store i64 %t709, i64* @sym.len
  br label %sym_done_159
sym_done_159:
  %t710 = phi i64 [ %t694, %sym_found_157 ], [ %t684, %sym_store_161 ]
  %t711 = load i64, i64* %t680
  %t712 = load i64*, i64** %t678
  store i64 0, i64* %t713
  store i1 false, i1* %t714
  br label %find_cond_164
find_cond_164:
  %t715 = load i64, i64* %t713
  %t716 = icmp slt i64 %t715, %t711
  br i1 %t716, label %find_body_165, label %find_end_168
find_body_165:
  %t717 = getelementptr inbounds i64, i64* %t712, i64 %t715
  %t718 = load i64, i64* %t717
  br label %find_eq_check_166
find_eq_check_166:
  %t719 = call i1 @eq_symbol(i64 %t718, i64 %t710)
  br i1 %t719, label %find_end_168, label %find_next_167
find_next_167:
  %t720 = add i64 %t715, 1
  store i64 %t720, i64* %t713
  br label %find_cond_164
find_end_168:
  %t721 = load i64, i64* %t713
  %t722 = icmp slt i64 %t721, %t711
  br i1 %t722, label %set_insert_already_present_169, label %set_insert_do_170
set_insert_already_present_169:
  br label %set_insert_end_171
set_insert_do_170:
  %t723 = load i64, i64* %t682
  %t724 = load i64*, i64** %t678
  %t725 = icmp sge i64 %t711, %t723
  br i1 %t725, label %set_insert_grow_172, label %set_insert_store_173
set_insert_grow_172:
  %t726 = mul i64 %t723, 2
  %t727 = icmp sgt i64 %t726, 0
  %t728 = select i1 %t727, i64 %t726, i64 1
  %t729 = getelementptr i64, i64* null, i32 1
  %t730 = ptrtoint i64* %t729 to i64
  %t731 = mul i64 %t728, %t730
  %t732 = call i8* @malloc(i64 %t731)
  %t733 = bitcast i8* %t732 to i64*
  %t734 = icmp sgt i64 %t723, 0
  br i1 %t734, label %set_insert_copy_174, label %set_insert_after_copy_175
set_insert_copy_174:
  %t735 = mul i64 %t711, %t730
  %t736 = bitcast i64* %t724 to i8*
  call i8* @memcpy(i8* %t732, i8* %t736, i64 %t735)
  call void @free(i8* %t736)
  br label %set_insert_after_copy_175
set_insert_after_copy_175:
  store i64* %t733, i64** %t678
  store i64 %t728, i64* %t682
  br label %set_insert_store_173
set_insert_store_173:
  %t737 = load i64*, i64** %t678
  %t738 = getelementptr inbounds i64, i64* %t737, i64 %t711
  store i64 %t710, i64* %t738
  %t739 = add i64 %t711, 1
  store i64 %t739, i64* %t680
  br label %set_insert_end_171
set_insert_end_171:
  %t740 = phi i1 [ false, %set_insert_already_present_169 ], [ true, %set_insert_store_173 ]
  %t741 = getelementptr i64, i64* null, i32 1
  %t742 = ptrtoint i64* %t741 to i64
  %t743 = load i8*, i8** %t540
  %t744 = icmp eq i8* %t743, null
  br i1 %t744, label %set_cow_alloc_176, label %set_cow_check_177
set_cow_alloc_176:
  %t745 = bitcast void (i8*)* @set_release_symbol to i8*
  %t746 = call i8* @star_rc_alloc(i64 24, i8* %t745)
  %t747 = bitcast i8* %t746 to { i64*, i64, i64 }*
  %t748 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t747, i32 0, i32 0
  store i64* null, i64** %t748
  %t749 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t747, i32 0, i32 1
  store i64 0, i64* %t749
  %t750 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t747, i32 0, i32 2
  store i64 0, i64* %t750
  store i8* %t746, i8** %t540
  br label %set_cow_done_178
set_cow_check_177:
  %t751 = getelementptr inbounds i8, i8* %t743, i64 -16
  %t752 = bitcast i8* %t751 to i64*
  %t753 = load atomic i64, i64* %t752 seq_cst, align 8
  %t754 = icmp eq i64 %t753, 1
  br i1 %t754, label %set_cow_done_178, label %set_cow_clone_179
set_cow_clone_179:
  %t755 = bitcast i8* %t743 to { i64*, i64, i64 }*
  %t756 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t755, i32 0, i32 0
  %t757 = load i64*, i64** %t756
  %t758 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t755, i32 0, i32 1
  %t759 = load i64, i64* %t758
  %t760 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t755, i32 0, i32 2
  %t761 = load i64, i64* %t760
  %t762 = bitcast void (i8*)* @set_release_symbol to i8*
  %t763 = call i8* @star_rc_alloc(i64 24, i8* %t762)
  %t764 = bitcast i8* %t763 to { i64*, i64, i64 }*
  %t765 = mul i64 %t761, %t742
  %t766 = call i8* @malloc(i64 %t765)
  %t767 = bitcast i8* %t766 to i64*
  %t768 = icmp sgt i64 %t759, 0
  br i1 %t768, label %set_cow_copy_180, label %set_cow_after_copy_181
set_cow_copy_180:
  %t769 = mul i64 %t759, %t742
  %t770 = bitcast i64* %t757 to i8*
  call i8* @memcpy(i8* %t766, i8* %t770, i64 %t769)
  br label %set_cow_after_copy_181
set_cow_after_copy_181:
  %t771 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t764, i32 0, i32 0
  store i64* %t767, i64** %t771
  %t772 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t764, i32 0, i32 1
  store i64 %t759, i64* %t772
  %t773 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t764, i32 0, i32 2
  store i64 %t761, i64* %t773
  call void @star_rc_release(i8* %t743)
  store i8* %t763, i8** %t540
  br label %set_cow_done_178
set_cow_done_178:
  %t774 = load i8*, i8** %t540
  %t775 = bitcast i8* %t774 to { i64*, i64, i64 }*
  %t776 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t775, i32 0, i32 0
  %t777 = load i64*, i64** %t776
  %t778 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t775, i32 0, i32 1
  %t779 = load i64, i64* %t778
  %t780 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t775, i32 0, i32 2
  %t781 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.29, i64 0, i32 2, i64 0
  %t782 = load i64, i64* @sym.len
  %t783 = load i8**, i8*** @sym.data
  store i64 0, i64* %t784
  br label %sym_find_cond_182
sym_find_cond_182:
  %t785 = load i64, i64* %t784
  %t786 = icmp slt i64 %t785, %t782
  br i1 %t786, label %sym_find_body_183, label %sym_find_end_185
sym_find_body_183:
  %t787 = getelementptr inbounds i8*, i8** %t783, i64 %t785
  %t788 = load i8*, i8** %t787
  %t789 = call i32 @strcmp(i8* %t788, i8* %t781)
  %t790 = icmp eq i32 %t789, 0
  br i1 %t790, label %sym_find_end_185, label %sym_find_next_184
sym_find_next_184:
  %t791 = add i64 %t785, 1
  store i64 %t791, i64* %t784
  br label %sym_find_cond_182
sym_find_end_185:
  %t792 = load i64, i64* %t784
  %t793 = icmp slt i64 %t792, %t782
  br i1 %t793, label %sym_found_186, label %sym_notfound_187
sym_found_186:
  call void @star_rc_release(i8* %t781)
  br label %sym_done_188
sym_notfound_187:
  %t794 = load i64, i64* @sym.cap
  %t795 = icmp sge i64 %t782, %t794
  br i1 %t795, label %sym_grow_189, label %sym_store_190
sym_grow_189:
  %t796 = mul i64 %t794, 2
  %t797 = icmp sgt i64 %t796, 0
  %t798 = select i1 %t797, i64 %t796, i64 1
  %t799 = mul i64 %t798, 8
  %t800 = call i8* @malloc(i64 %t799)
  %t801 = bitcast i8* %t800 to i8**
  %t802 = icmp sgt i64 %t794, 0
  br i1 %t802, label %sym_copy_191, label %sym_after_copy_192
sym_copy_191:
  %t803 = mul i64 %t782, 8
  %t804 = bitcast i8** %t783 to i8*
  call i8* @memcpy(i8* %t800, i8* %t804, i64 %t803)
  call void @free(i8* %t804)
  br label %sym_after_copy_192
sym_after_copy_192:
  store i8** %t801, i8*** @sym.data
  store i64 %t798, i64* @sym.cap
  br label %sym_store_190
sym_store_190:
  %t805 = load i8**, i8*** @sym.data
  %t806 = getelementptr inbounds i8*, i8** %t805, i64 %t782
  store i8* %t781, i8** %t806
  %t807 = add i64 %t782, 1
  store i64 %t807, i64* @sym.len
  br label %sym_done_188
sym_done_188:
  %t808 = phi i64 [ %t792, %sym_found_186 ], [ %t782, %sym_store_190 ]
  %t809 = load i64, i64* %t778
  %t810 = load i64*, i64** %t776
  store i64 0, i64* %t811
  store i1 false, i1* %t812
  br label %find_cond_193
find_cond_193:
  %t813 = load i64, i64* %t811
  %t814 = icmp slt i64 %t813, %t809
  br i1 %t814, label %find_body_194, label %find_end_197
find_body_194:
  %t815 = getelementptr inbounds i64, i64* %t810, i64 %t813
  %t816 = load i64, i64* %t815
  br label %find_eq_check_195
find_eq_check_195:
  %t817 = call i1 @eq_symbol(i64 %t816, i64 %t808)
  br i1 %t817, label %find_end_197, label %find_next_196
find_next_196:
  %t818 = add i64 %t813, 1
  store i64 %t818, i64* %t811
  br label %find_cond_193
find_end_197:
  %t819 = load i64, i64* %t811
  %t820 = icmp slt i64 %t819, %t809
  br i1 %t820, label %set_insert_already_present_198, label %set_insert_do_199
set_insert_already_present_198:
  br label %set_insert_end_200
set_insert_do_199:
  %t821 = load i64, i64* %t780
  %t822 = load i64*, i64** %t776
  %t823 = icmp sge i64 %t809, %t821
  br i1 %t823, label %set_insert_grow_201, label %set_insert_store_202
set_insert_grow_201:
  %t824 = mul i64 %t821, 2
  %t825 = icmp sgt i64 %t824, 0
  %t826 = select i1 %t825, i64 %t824, i64 1
  %t827 = getelementptr i64, i64* null, i32 1
  %t828 = ptrtoint i64* %t827 to i64
  %t829 = mul i64 %t826, %t828
  %t830 = call i8* @malloc(i64 %t829)
  %t831 = bitcast i8* %t830 to i64*
  %t832 = icmp sgt i64 %t821, 0
  br i1 %t832, label %set_insert_copy_203, label %set_insert_after_copy_204
set_insert_copy_203:
  %t833 = mul i64 %t809, %t828
  %t834 = bitcast i64* %t822 to i8*
  call i8* @memcpy(i8* %t830, i8* %t834, i64 %t833)
  call void @free(i8* %t834)
  br label %set_insert_after_copy_204
set_insert_after_copy_204:
  store i64* %t831, i64** %t776
  store i64 %t826, i64* %t780
  br label %set_insert_store_202
set_insert_store_202:
  %t835 = load i64*, i64** %t776
  %t836 = getelementptr inbounds i64, i64* %t835, i64 %t809
  store i64 %t808, i64* %t836
  %t837 = add i64 %t809, 1
  store i64 %t837, i64* %t778
  br label %set_insert_end_200
set_insert_end_200:
  %t838 = phi i1 [ false, %set_insert_already_present_198 ], [ true, %set_insert_store_202 ]
  %t839 = load i8*, i8** %t540
  %t840 = icmp eq i8* %t839, null
  br i1 %t840, label %set_read_null_205, label %set_read_real_206
set_read_null_205:
  br label %set_read_end_207
set_read_real_206:
  %t841 = bitcast i8* %t839 to { i64*, i64, i64 }*
  %t842 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t841, i32 0, i32 0
  %t843 = load i64*, i64** %t842
  %t844 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t841, i32 0, i32 1
  %t845 = load i64, i64* %t844
  br label %set_read_end_207
set_read_end_207:
  %t846 = phi i64* [ null, %set_read_null_205 ], [ %t843, %set_read_real_206 ]
  %t847 = phi i64 [ 0, %set_read_null_205 ], [ %t845, %set_read_real_206 ]
  %t848 = trunc i64 %t847 to i32
  %t849 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.30, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t849, i32 %t848)
  %t851 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.31, i64 0, i32 2, i64 0
  %t852 = load i64, i64* @sym.len
  %t853 = load i8**, i8*** @sym.data
  store i64 0, i64* %t854
  br label %sym_find_cond_208
sym_find_cond_208:
  %t855 = load i64, i64* %t854
  %t856 = icmp slt i64 %t855, %t852
  br i1 %t856, label %sym_find_body_209, label %sym_find_end_211
sym_find_body_209:
  %t857 = getelementptr inbounds i8*, i8** %t853, i64 %t855
  %t858 = load i8*, i8** %t857
  %t859 = call i32 @strcmp(i8* %t858, i8* %t851)
  %t860 = icmp eq i32 %t859, 0
  br i1 %t860, label %sym_find_end_211, label %sym_find_next_210
sym_find_next_210:
  %t861 = add i64 %t855, 1
  store i64 %t861, i64* %t854
  br label %sym_find_cond_208
sym_find_end_211:
  %t862 = load i64, i64* %t854
  %t863 = icmp slt i64 %t862, %t852
  br i1 %t863, label %sym_found_212, label %sym_notfound_213
sym_found_212:
  call void @star_rc_release(i8* %t851)
  br label %sym_done_214
sym_notfound_213:
  %t864 = load i64, i64* @sym.cap
  %t865 = icmp sge i64 %t852, %t864
  br i1 %t865, label %sym_grow_215, label %sym_store_216
sym_grow_215:
  %t866 = mul i64 %t864, 2
  %t867 = icmp sgt i64 %t866, 0
  %t868 = select i1 %t867, i64 %t866, i64 1
  %t869 = mul i64 %t868, 8
  %t870 = call i8* @malloc(i64 %t869)
  %t871 = bitcast i8* %t870 to i8**
  %t872 = icmp sgt i64 %t864, 0
  br i1 %t872, label %sym_copy_217, label %sym_after_copy_218
sym_copy_217:
  %t873 = mul i64 %t852, 8
  %t874 = bitcast i8** %t853 to i8*
  call i8* @memcpy(i8* %t870, i8* %t874, i64 %t873)
  call void @free(i8* %t874)
  br label %sym_after_copy_218
sym_after_copy_218:
  store i8** %t871, i8*** @sym.data
  store i64 %t868, i64* @sym.cap
  br label %sym_store_216
sym_store_216:
  %t875 = load i8**, i8*** @sym.data
  %t876 = getelementptr inbounds i8*, i8** %t875, i64 %t852
  store i8* %t851, i8** %t876
  %t877 = add i64 %t852, 1
  store i64 %t877, i64* @sym.len
  br label %sym_done_214
sym_done_214:
  %t878 = phi i64 [ %t862, %sym_found_212 ], [ %t852, %sym_store_216 ]
  %t879 = load i8*, i8** %t540
  %t880 = icmp eq i8* %t879, null
  br i1 %t880, label %set_read_null_219, label %set_read_real_220
set_read_null_219:
  br label %set_read_end_221
set_read_real_220:
  %t881 = bitcast i8* %t879 to { i64*, i64, i64 }*
  %t882 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t881, i32 0, i32 0
  %t883 = load i64*, i64** %t882
  %t884 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t881, i32 0, i32 1
  %t885 = load i64, i64* %t884
  br label %set_read_end_221
set_read_end_221:
  %t886 = phi i64* [ null, %set_read_null_219 ], [ %t883, %set_read_real_220 ]
  %t887 = phi i64 [ 0, %set_read_null_219 ], [ %t885, %set_read_real_220 ]
  store i64 0, i64* %t888
  store i1 false, i1* %t889
  br label %find_cond_222
find_cond_222:
  %t890 = load i64, i64* %t888
  %t891 = icmp slt i64 %t890, %t887
  br i1 %t891, label %find_body_223, label %find_end_226
find_body_223:
  %t892 = getelementptr inbounds i64, i64* %t886, i64 %t890
  %t893 = load i64, i64* %t892
  br label %find_eq_check_224
find_eq_check_224:
  %t894 = call i1 @eq_symbol(i64 %t893, i64 %t878)
  br i1 %t894, label %find_end_226, label %find_next_225
find_next_225:
  %t895 = add i64 %t890, 1
  store i64 %t895, i64* %t888
  br label %find_cond_222
find_end_226:
  %t896 = load i64, i64* %t888
  %t897 = icmp slt i64 %t896, %t887
  store i1 %t897, i1* %t850
  %t898 = load i1, i1* %t850
  %t899 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.32, i64 0, i64 0
  %t900 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.33, i64 0, i64 0
  %t901 = select i1 %t898, i8* %t899, i8* %t900
  %t902 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.34, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t902, i8* %t901)
  %t903 = load i8*, i8** %t540
  call void @star_rc_release(i8* %t903)
  %t904 = load i8*, i8** %t155
  call void @star_rc_release(i8* %t904)
  ret i32 0
}


; par/swarm worker functions
define void @map_release_6_symboli32(i8* %objp) {
entry:
  %t162 = bitcast i8* %objp to { i64*, i32*, i64, i64 }*
  %t163 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t162, i32 0, i32 0
  %t164 = load i64*, i64** %t163
  %t165 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t162, i32 0, i32 1
  %t166 = load i32*, i32** %t165
  %t167 = bitcast i64* %t164 to i8*
  call void @free(i8* %t167)
  %t168 = bitcast i32* %t166 to i8*
  call void @free(i8* %t168)
  ret void
}


define i1 @eq_symbol(i64 %a, i64 %b) {
entry:
  %t219 = icmp eq i64 %a, %b
  ret i1 %t219
}


define void @set_release_symbol(i8* %objp) {
entry:
  %t545 = bitcast i8* %objp to { i64*, i64, i64 }*
  %t546 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t545, i32 0, i32 0
  %t547 = load i64*, i64** %t546
  %t548 = bitcast i64* %t547 to i8*
  call void @free(i8* %t548)
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
