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
  %t157 = alloca i8*
  %t222 = alloca i64
  %t316 = alloca i64
  %t410 = alloca i64
  %t437 = alloca i64
  %t502 = alloca i64
  %t513 = alloca %Option__i32
  %t519 = alloca %Option__i32
  %t523 = alloca %Option__i32
  %t542 = alloca i8*
  %t590 = alloca i64
  %t617 = alloca i64
  %t618 = alloca i1
  %t688 = alloca i64
  %t715 = alloca i64
  %t716 = alloca i1
  %t786 = alloca i64
  %t813 = alloca i64
  %t814 = alloca i1
  %t852 = alloca i1
  %t856 = alloca i64
  %t890 = alloca i64
  %t891 = alloca i1
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
  %t143 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t143
  br label %sym_name_end_35
sym_name_end_35:
  %t144 = phi i8* [ %t142, %sym_name_ok_33 ], [ %t143, %sym_name_oob_34 ]
  call void @star_rc_release(i8* %t144)
  %t145 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.21, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t145, i8* %t144)
  %t146 = load i64, i64* %t58
  %t147 = load i64, i64* @sym.len
  %t148 = icmp sge i64 %t146, 0
  %t149 = icmp slt i64 %t146, %t147
  %t150 = and i1 %t148, %t149
  br i1 %t150, label %sym_name_ok_36, label %sym_name_oob_37
sym_name_ok_36:
  %t151 = load i8**, i8*** @sym.data
  %t152 = getelementptr inbounds i8*, i8** %t151, i64 %t146
  %t153 = load i8*, i8** %t152
  call void @star_rc_retain(i8* %t153)
  br label %sym_name_end_38
sym_name_oob_37:
  %t154 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t154
  br label %sym_name_end_38
sym_name_end_38:
  %t155 = phi i8* [ %t153, %sym_name_ok_36 ], [ %t154, %sym_name_oob_37 ]
  call void @star_rc_release(i8* %t155)
  %t156 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t156, i8* %t155)
  store i8* null, i8** %t157
  %t158 = getelementptr i64, i64* null, i32 1
  %t159 = ptrtoint i64* %t158 to i64
  %t160 = getelementptr i32, i32* null, i32 1
  %t161 = ptrtoint i32* %t160 to i64
  %t162 = load i8*, i8** %t157
  %t163 = icmp eq i8* %t162, null
  br i1 %t163, label %map_cow_alloc_39, label %map_cow_check_40
map_cow_alloc_39:
  %t171 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t172 = call i8* @star_rc_alloc(i64 32, i8* %t171)
  %t173 = bitcast i8* %t172 to { i64*, i32*, i64, i64 }*
  %t174 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t173, i32 0, i32 0
  store i64* null, i64** %t174
  %t175 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t173, i32 0, i32 1
  store i32* null, i32** %t175
  %t176 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t173, i32 0, i32 2
  store i64 0, i64* %t176
  %t177 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t173, i32 0, i32 3
  store i64 0, i64* %t177
  store i8* %t172, i8** %t157
  br label %map_cow_done_41
map_cow_check_40:
  %t178 = getelementptr inbounds i8, i8* %t162, i64 -16
  %t179 = bitcast i8* %t178 to i64*
  %t180 = load atomic i64, i64* %t179 seq_cst, align 8
  %t181 = icmp eq i64 %t180, 1
  br i1 %t181, label %map_cow_done_41, label %map_cow_clone_42
map_cow_clone_42:
  %t182 = bitcast i8* %t162 to { i64*, i32*, i64, i64 }*
  %t183 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t182, i32 0, i32 0
  %t184 = load i64*, i64** %t183
  %t185 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t182, i32 0, i32 1
  %t186 = load i32*, i32** %t185
  %t187 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t182, i32 0, i32 2
  %t188 = load i64, i64* %t187
  %t189 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t182, i32 0, i32 3
  %t190 = load i64, i64* %t189
  %t191 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t192 = call i8* @star_rc_alloc(i64 32, i8* %t191)
  %t193 = bitcast i8* %t192 to { i64*, i32*, i64, i64 }*
  %t194 = mul i64 %t190, %t159
  %t195 = call i8* @malloc(i64 %t194)
  %t196 = bitcast i8* %t195 to i64*
  %t197 = mul i64 %t190, %t161
  %t198 = call i8* @malloc(i64 %t197)
  %t199 = bitcast i8* %t198 to i32*
  %t200 = icmp sgt i64 %t188, 0
  br i1 %t200, label %map_cow_copy_43, label %map_cow_after_copy_44
map_cow_copy_43:
  %t201 = mul i64 %t188, %t159
  %t202 = bitcast i64* %t184 to i8*
  call i8* @memcpy(i8* %t195, i8* %t202, i64 %t201)
  %t203 = mul i64 %t188, %t161
  %t204 = bitcast i32* %t186 to i8*
  call i8* @memcpy(i8* %t198, i8* %t204, i64 %t203)
  br label %map_cow_after_copy_44
map_cow_after_copy_44:
  %t205 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t193, i32 0, i32 0
  store i64* %t196, i64** %t205
  %t206 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t193, i32 0, i32 1
  store i32* %t199, i32** %t206
  %t207 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t193, i32 0, i32 2
  store i64 %t188, i64* %t207
  %t208 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t193, i32 0, i32 3
  store i64 %t190, i64* %t208
  call void @star_rc_release(i8* %t162)
  store i8* %t192, i8** %t157
  br label %map_cow_done_41
map_cow_done_41:
  %t209 = load i8*, i8** %t157
  %t210 = bitcast i8* %t209 to { i64*, i32*, i64, i64 }*
  %t211 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t210, i32 0, i32 0
  %t212 = load i64*, i64** %t211
  %t213 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t210, i32 0, i32 1
  %t214 = load i32*, i32** %t213
  %t215 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t210, i32 0, i32 2
  %t216 = load i64, i64* %t215
  %t217 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t210, i32 0, i32 3
  %t218 = load i64, i64* %t0
  %t219 = load i64, i64* %t215
  %t220 = load i64*, i64** %t211
  store i64 0, i64* %t222
  br label %map_find_cond_45
map_find_cond_45:
  %t223 = load i64, i64* %t222
  %t224 = icmp slt i64 %t223, %t219
  br i1 %t224, label %map_find_body_46, label %map_find_end_49
map_find_body_46:
  %t225 = getelementptr inbounds i64, i64* %t220, i64 %t223
  %t226 = load i64, i64* %t225
  br label %map_find_eq_check_47
map_find_eq_check_47:
  %t227 = call i1 @eq_symbol(i64 %t226, i64 %t218)
  br i1 %t227, label %map_find_end_49, label %map_find_next_48
map_find_next_48:
  %t228 = add i64 %t223, 1
  store i64 %t228, i64* %t222
  br label %map_find_cond_45
map_find_end_49:
  %t229 = load i64, i64* %t222
  %t230 = icmp slt i64 %t229, %t219
  br i1 %t230, label %map_insert_overwrite_50, label %map_insert_new_51
map_insert_overwrite_50:
  %t231 = load i32*, i32** %t213
  %t232 = getelementptr inbounds i32, i32* %t231, i64 %t229
  store i32 100, i32* %t232
  br label %map_insert_after_52
map_insert_new_51:
  %t233 = load i64, i64* %t217
  %t234 = icmp sge i64 %t219, %t233
  br i1 %t234, label %map_insert_grow_53, label %map_insert_store_54
map_insert_grow_53:
  %t235 = mul i64 %t233, 2
  %t236 = icmp sgt i64 %t235, 0
  %t237 = select i1 %t236, i64 %t235, i64 1
  %t238 = getelementptr i64, i64* null, i32 1
  %t239 = ptrtoint i64* %t238 to i64
  %t240 = mul i64 %t237, %t239
  %t241 = call i8* @malloc(i64 %t240)
  %t242 = bitcast i8* %t241 to i64*
  %t243 = getelementptr i32, i32* null, i32 1
  %t244 = ptrtoint i32* %t243 to i64
  %t245 = mul i64 %t237, %t244
  %t246 = call i8* @malloc(i64 %t245)
  %t247 = bitcast i8* %t246 to i32*
  %t248 = icmp sgt i64 %t233, 0
  br i1 %t248, label %map_insert_copy_55, label %map_insert_after_copy_56
map_insert_copy_55:
  %t249 = load i64*, i64** %t211
  %t250 = mul i64 %t219, %t239
  %t251 = bitcast i64* %t249 to i8*
  call i8* @memcpy(i8* %t241, i8* %t251, i64 %t250)
  call void @free(i8* %t251)
  %t252 = load i32*, i32** %t213
  %t253 = mul i64 %t219, %t244
  %t254 = bitcast i32* %t252 to i8*
  call i8* @memcpy(i8* %t246, i8* %t254, i64 %t253)
  call void @free(i8* %t254)
  br label %map_insert_after_copy_56
map_insert_after_copy_56:
  store i64* %t242, i64** %t211
  store i32* %t247, i32** %t213
  store i64 %t237, i64* %t217
  br label %map_insert_store_54
map_insert_store_54:
  %t255 = load i64*, i64** %t211
  %t256 = load i32*, i32** %t213
  %t257 = getelementptr inbounds i64, i64* %t255, i64 %t219
  store i64 %t218, i64* %t257
  %t258 = getelementptr inbounds i32, i32* %t256, i64 %t219
  store i32 100, i32* %t258
  %t259 = add i64 %t219, 1
  store i64 %t259, i64* %t215
  br label %map_insert_after_52
map_insert_after_52:
  %t260 = getelementptr i64, i64* null, i32 1
  %t261 = ptrtoint i64* %t260 to i64
  %t262 = getelementptr i32, i32* null, i32 1
  %t263 = ptrtoint i32* %t262 to i64
  %t264 = load i8*, i8** %t157
  %t265 = icmp eq i8* %t264, null
  br i1 %t265, label %map_cow_alloc_57, label %map_cow_check_58
map_cow_alloc_57:
  %t266 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t267 = call i8* @star_rc_alloc(i64 32, i8* %t266)
  %t268 = bitcast i8* %t267 to { i64*, i32*, i64, i64 }*
  %t269 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t268, i32 0, i32 0
  store i64* null, i64** %t269
  %t270 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t268, i32 0, i32 1
  store i32* null, i32** %t270
  %t271 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t268, i32 0, i32 2
  store i64 0, i64* %t271
  %t272 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t268, i32 0, i32 3
  store i64 0, i64* %t272
  store i8* %t267, i8** %t157
  br label %map_cow_done_59
map_cow_check_58:
  %t273 = getelementptr inbounds i8, i8* %t264, i64 -16
  %t274 = bitcast i8* %t273 to i64*
  %t275 = load atomic i64, i64* %t274 seq_cst, align 8
  %t276 = icmp eq i64 %t275, 1
  br i1 %t276, label %map_cow_done_59, label %map_cow_clone_60
map_cow_clone_60:
  %t277 = bitcast i8* %t264 to { i64*, i32*, i64, i64 }*
  %t278 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t277, i32 0, i32 0
  %t279 = load i64*, i64** %t278
  %t280 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t277, i32 0, i32 1
  %t281 = load i32*, i32** %t280
  %t282 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t277, i32 0, i32 2
  %t283 = load i64, i64* %t282
  %t284 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t277, i32 0, i32 3
  %t285 = load i64, i64* %t284
  %t286 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t287 = call i8* @star_rc_alloc(i64 32, i8* %t286)
  %t288 = bitcast i8* %t287 to { i64*, i32*, i64, i64 }*
  %t289 = mul i64 %t285, %t261
  %t290 = call i8* @malloc(i64 %t289)
  %t291 = bitcast i8* %t290 to i64*
  %t292 = mul i64 %t285, %t263
  %t293 = call i8* @malloc(i64 %t292)
  %t294 = bitcast i8* %t293 to i32*
  %t295 = icmp sgt i64 %t283, 0
  br i1 %t295, label %map_cow_copy_61, label %map_cow_after_copy_62
map_cow_copy_61:
  %t296 = mul i64 %t283, %t261
  %t297 = bitcast i64* %t279 to i8*
  call i8* @memcpy(i8* %t290, i8* %t297, i64 %t296)
  %t298 = mul i64 %t283, %t263
  %t299 = bitcast i32* %t281 to i8*
  call i8* @memcpy(i8* %t293, i8* %t299, i64 %t298)
  br label %map_cow_after_copy_62
map_cow_after_copy_62:
  %t300 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t288, i32 0, i32 0
  store i64* %t291, i64** %t300
  %t301 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t288, i32 0, i32 1
  store i32* %t294, i32** %t301
  %t302 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t288, i32 0, i32 2
  store i64 %t283, i64* %t302
  %t303 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t288, i32 0, i32 3
  store i64 %t285, i64* %t303
  call void @star_rc_release(i8* %t264)
  store i8* %t287, i8** %t157
  br label %map_cow_done_59
map_cow_done_59:
  %t304 = load i8*, i8** %t157
  %t305 = bitcast i8* %t304 to { i64*, i32*, i64, i64 }*
  %t306 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t305, i32 0, i32 0
  %t307 = load i64*, i64** %t306
  %t308 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t305, i32 0, i32 1
  %t309 = load i32*, i32** %t308
  %t310 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t305, i32 0, i32 2
  %t311 = load i64, i64* %t310
  %t312 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t305, i32 0, i32 3
  %t313 = load i64, i64* %t58
  %t314 = load i64, i64* %t310
  %t315 = load i64*, i64** %t306
  store i64 0, i64* %t316
  br label %map_find_cond_63
map_find_cond_63:
  %t317 = load i64, i64* %t316
  %t318 = icmp slt i64 %t317, %t314
  br i1 %t318, label %map_find_body_64, label %map_find_end_67
map_find_body_64:
  %t319 = getelementptr inbounds i64, i64* %t315, i64 %t317
  %t320 = load i64, i64* %t319
  br label %map_find_eq_check_65
map_find_eq_check_65:
  %t321 = call i1 @eq_symbol(i64 %t320, i64 %t313)
  br i1 %t321, label %map_find_end_67, label %map_find_next_66
map_find_next_66:
  %t322 = add i64 %t317, 1
  store i64 %t322, i64* %t316
  br label %map_find_cond_63
map_find_end_67:
  %t323 = load i64, i64* %t316
  %t324 = icmp slt i64 %t323, %t314
  br i1 %t324, label %map_insert_overwrite_68, label %map_insert_new_69
map_insert_overwrite_68:
  %t325 = load i32*, i32** %t308
  %t326 = getelementptr inbounds i32, i32* %t325, i64 %t323
  store i32 40, i32* %t326
  br label %map_insert_after_70
map_insert_new_69:
  %t327 = load i64, i64* %t312
  %t328 = icmp sge i64 %t314, %t327
  br i1 %t328, label %map_insert_grow_71, label %map_insert_store_72
map_insert_grow_71:
  %t329 = mul i64 %t327, 2
  %t330 = icmp sgt i64 %t329, 0
  %t331 = select i1 %t330, i64 %t329, i64 1
  %t332 = getelementptr i64, i64* null, i32 1
  %t333 = ptrtoint i64* %t332 to i64
  %t334 = mul i64 %t331, %t333
  %t335 = call i8* @malloc(i64 %t334)
  %t336 = bitcast i8* %t335 to i64*
  %t337 = getelementptr i32, i32* null, i32 1
  %t338 = ptrtoint i32* %t337 to i64
  %t339 = mul i64 %t331, %t338
  %t340 = call i8* @malloc(i64 %t339)
  %t341 = bitcast i8* %t340 to i32*
  %t342 = icmp sgt i64 %t327, 0
  br i1 %t342, label %map_insert_copy_73, label %map_insert_after_copy_74
map_insert_copy_73:
  %t343 = load i64*, i64** %t306
  %t344 = mul i64 %t314, %t333
  %t345 = bitcast i64* %t343 to i8*
  call i8* @memcpy(i8* %t335, i8* %t345, i64 %t344)
  call void @free(i8* %t345)
  %t346 = load i32*, i32** %t308
  %t347 = mul i64 %t314, %t338
  %t348 = bitcast i32* %t346 to i8*
  call i8* @memcpy(i8* %t340, i8* %t348, i64 %t347)
  call void @free(i8* %t348)
  br label %map_insert_after_copy_74
map_insert_after_copy_74:
  store i64* %t336, i64** %t306
  store i32* %t341, i32** %t308
  store i64 %t331, i64* %t312
  br label %map_insert_store_72
map_insert_store_72:
  %t349 = load i64*, i64** %t306
  %t350 = load i32*, i32** %t308
  %t351 = getelementptr inbounds i64, i64* %t349, i64 %t314
  store i64 %t313, i64* %t351
  %t352 = getelementptr inbounds i32, i32* %t350, i64 %t314
  store i32 40, i32* %t352
  %t353 = add i64 %t314, 1
  store i64 %t353, i64* %t310
  br label %map_insert_after_70
map_insert_after_70:
  %t354 = getelementptr i64, i64* null, i32 1
  %t355 = ptrtoint i64* %t354 to i64
  %t356 = getelementptr i32, i32* null, i32 1
  %t357 = ptrtoint i32* %t356 to i64
  %t358 = load i8*, i8** %t157
  %t359 = icmp eq i8* %t358, null
  br i1 %t359, label %map_cow_alloc_75, label %map_cow_check_76
map_cow_alloc_75:
  %t360 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t361 = call i8* @star_rc_alloc(i64 32, i8* %t360)
  %t362 = bitcast i8* %t361 to { i64*, i32*, i64, i64 }*
  %t363 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t362, i32 0, i32 0
  store i64* null, i64** %t363
  %t364 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t362, i32 0, i32 1
  store i32* null, i32** %t364
  %t365 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t362, i32 0, i32 2
  store i64 0, i64* %t365
  %t366 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t362, i32 0, i32 3
  store i64 0, i64* %t366
  store i8* %t361, i8** %t157
  br label %map_cow_done_77
map_cow_check_76:
  %t367 = getelementptr inbounds i8, i8* %t358, i64 -16
  %t368 = bitcast i8* %t367 to i64*
  %t369 = load atomic i64, i64* %t368 seq_cst, align 8
  %t370 = icmp eq i64 %t369, 1
  br i1 %t370, label %map_cow_done_77, label %map_cow_clone_78
map_cow_clone_78:
  %t371 = bitcast i8* %t358 to { i64*, i32*, i64, i64 }*
  %t372 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t371, i32 0, i32 0
  %t373 = load i64*, i64** %t372
  %t374 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t371, i32 0, i32 1
  %t375 = load i32*, i32** %t374
  %t376 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t371, i32 0, i32 2
  %t377 = load i64, i64* %t376
  %t378 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t371, i32 0, i32 3
  %t379 = load i64, i64* %t378
  %t380 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t381 = call i8* @star_rc_alloc(i64 32, i8* %t380)
  %t382 = bitcast i8* %t381 to { i64*, i32*, i64, i64 }*
  %t383 = mul i64 %t379, %t355
  %t384 = call i8* @malloc(i64 %t383)
  %t385 = bitcast i8* %t384 to i64*
  %t386 = mul i64 %t379, %t357
  %t387 = call i8* @malloc(i64 %t386)
  %t388 = bitcast i8* %t387 to i32*
  %t389 = icmp sgt i64 %t377, 0
  br i1 %t389, label %map_cow_copy_79, label %map_cow_after_copy_80
map_cow_copy_79:
  %t390 = mul i64 %t377, %t355
  %t391 = bitcast i64* %t373 to i8*
  call i8* @memcpy(i8* %t384, i8* %t391, i64 %t390)
  %t392 = mul i64 %t377, %t357
  %t393 = bitcast i32* %t375 to i8*
  call i8* @memcpy(i8* %t387, i8* %t393, i64 %t392)
  br label %map_cow_after_copy_80
map_cow_after_copy_80:
  %t394 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t382, i32 0, i32 0
  store i64* %t385, i64** %t394
  %t395 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t382, i32 0, i32 1
  store i32* %t388, i32** %t395
  %t396 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t382, i32 0, i32 2
  store i64 %t377, i64* %t396
  %t397 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t382, i32 0, i32 3
  store i64 %t379, i64* %t397
  call void @star_rc_release(i8* %t358)
  store i8* %t381, i8** %t157
  br label %map_cow_done_77
map_cow_done_77:
  %t398 = load i8*, i8** %t157
  %t399 = bitcast i8* %t398 to { i64*, i32*, i64, i64 }*
  %t400 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t399, i32 0, i32 0
  %t401 = load i64*, i64** %t400
  %t402 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t399, i32 0, i32 1
  %t403 = load i32*, i32** %t402
  %t404 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t399, i32 0, i32 2
  %t405 = load i64, i64* %t404
  %t406 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t399, i32 0, i32 3
  %t407 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.23, i64 0, i32 2, i64 0
  %t408 = load i64, i64* @sym.len
  %t409 = load i8**, i8*** @sym.data
  store i64 0, i64* %t410
  br label %sym_find_cond_81
sym_find_cond_81:
  %t411 = load i64, i64* %t410
  %t412 = icmp slt i64 %t411, %t408
  br i1 %t412, label %sym_find_body_82, label %sym_find_end_84
sym_find_body_82:
  %t413 = getelementptr inbounds i8*, i8** %t409, i64 %t411
  %t414 = load i8*, i8** %t413
  %t415 = call i32 @strcmp(i8* %t414, i8* %t407)
  %t416 = icmp eq i32 %t415, 0
  br i1 %t416, label %sym_find_end_84, label %sym_find_next_83
sym_find_next_83:
  %t417 = add i64 %t411, 1
  store i64 %t417, i64* %t410
  br label %sym_find_cond_81
sym_find_end_84:
  %t418 = load i64, i64* %t410
  %t419 = icmp slt i64 %t418, %t408
  br i1 %t419, label %sym_found_85, label %sym_notfound_86
sym_found_85:
  call void @star_rc_release(i8* %t407)
  br label %sym_done_87
sym_notfound_86:
  %t420 = load i64, i64* @sym.cap
  %t421 = icmp sge i64 %t408, %t420
  br i1 %t421, label %sym_grow_88, label %sym_store_89
sym_grow_88:
  %t422 = mul i64 %t420, 2
  %t423 = icmp sgt i64 %t422, 0
  %t424 = select i1 %t423, i64 %t422, i64 1
  %t425 = mul i64 %t424, 8
  %t426 = call i8* @malloc(i64 %t425)
  %t427 = bitcast i8* %t426 to i8**
  %t428 = icmp sgt i64 %t420, 0
  br i1 %t428, label %sym_copy_90, label %sym_after_copy_91
sym_copy_90:
  %t429 = mul i64 %t408, 8
  %t430 = bitcast i8** %t409 to i8*
  call i8* @memcpy(i8* %t426, i8* %t430, i64 %t429)
  call void @free(i8* %t430)
  br label %sym_after_copy_91
sym_after_copy_91:
  store i8** %t427, i8*** @sym.data
  store i64 %t424, i64* @sym.cap
  br label %sym_store_89
sym_store_89:
  %t431 = load i8**, i8*** @sym.data
  %t432 = getelementptr inbounds i8*, i8** %t431, i64 %t408
  store i8* %t407, i8** %t432
  %t433 = add i64 %t408, 1
  store i64 %t433, i64* @sym.len
  br label %sym_done_87
sym_done_87:
  %t434 = phi i64 [ %t418, %sym_found_85 ], [ %t408, %sym_store_89 ]
  %t435 = load i64, i64* %t404
  %t436 = load i64*, i64** %t400
  store i64 0, i64* %t437
  br label %map_find_cond_92
map_find_cond_92:
  %t438 = load i64, i64* %t437
  %t439 = icmp slt i64 %t438, %t435
  br i1 %t439, label %map_find_body_93, label %map_find_end_96
map_find_body_93:
  %t440 = getelementptr inbounds i64, i64* %t436, i64 %t438
  %t441 = load i64, i64* %t440
  br label %map_find_eq_check_94
map_find_eq_check_94:
  %t442 = call i1 @eq_symbol(i64 %t441, i64 %t434)
  br i1 %t442, label %map_find_end_96, label %map_find_next_95
map_find_next_95:
  %t443 = add i64 %t438, 1
  store i64 %t443, i64* %t437
  br label %map_find_cond_92
map_find_end_96:
  %t444 = load i64, i64* %t437
  %t445 = icmp slt i64 %t444, %t435
  br i1 %t445, label %map_insert_overwrite_97, label %map_insert_new_98
map_insert_overwrite_97:
  %t446 = load i32*, i32** %t402
  %t447 = getelementptr inbounds i32, i32* %t446, i64 %t444
  store i32 80, i32* %t447
  br label %map_insert_after_99
map_insert_new_98:
  %t448 = load i64, i64* %t406
  %t449 = icmp sge i64 %t435, %t448
  br i1 %t449, label %map_insert_grow_100, label %map_insert_store_101
map_insert_grow_100:
  %t450 = mul i64 %t448, 2
  %t451 = icmp sgt i64 %t450, 0
  %t452 = select i1 %t451, i64 %t450, i64 1
  %t453 = getelementptr i64, i64* null, i32 1
  %t454 = ptrtoint i64* %t453 to i64
  %t455 = mul i64 %t452, %t454
  %t456 = call i8* @malloc(i64 %t455)
  %t457 = bitcast i8* %t456 to i64*
  %t458 = getelementptr i32, i32* null, i32 1
  %t459 = ptrtoint i32* %t458 to i64
  %t460 = mul i64 %t452, %t459
  %t461 = call i8* @malloc(i64 %t460)
  %t462 = bitcast i8* %t461 to i32*
  %t463 = icmp sgt i64 %t448, 0
  br i1 %t463, label %map_insert_copy_102, label %map_insert_after_copy_103
map_insert_copy_102:
  %t464 = load i64*, i64** %t400
  %t465 = mul i64 %t435, %t454
  %t466 = bitcast i64* %t464 to i8*
  call i8* @memcpy(i8* %t456, i8* %t466, i64 %t465)
  call void @free(i8* %t466)
  %t467 = load i32*, i32** %t402
  %t468 = mul i64 %t435, %t459
  %t469 = bitcast i32* %t467 to i8*
  call i8* @memcpy(i8* %t461, i8* %t469, i64 %t468)
  call void @free(i8* %t469)
  br label %map_insert_after_copy_103
map_insert_after_copy_103:
  store i64* %t457, i64** %t400
  store i32* %t462, i32** %t402
  store i64 %t452, i64* %t406
  br label %map_insert_store_101
map_insert_store_101:
  %t470 = load i64*, i64** %t400
  %t471 = load i32*, i32** %t402
  %t472 = getelementptr inbounds i64, i64* %t470, i64 %t435
  store i64 %t434, i64* %t472
  %t473 = getelementptr inbounds i32, i32* %t471, i64 %t435
  store i32 80, i32* %t473
  %t474 = add i64 %t435, 1
  store i64 %t474, i64* %t404
  br label %map_insert_after_99
map_insert_after_99:
  %t475 = load i8*, i8** %t157
  %t476 = icmp eq i8* %t475, null
  br i1 %t476, label %map_read_null_104, label %map_read_real_105
map_read_null_104:
  br label %map_read_end_106
map_read_real_105:
  %t477 = bitcast i8* %t475 to { i64*, i32*, i64, i64 }*
  %t478 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t477, i32 0, i32 0
  %t479 = load i64*, i64** %t478
  %t480 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t477, i32 0, i32 1
  %t481 = load i32*, i32** %t480
  %t482 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t477, i32 0, i32 2
  %t483 = load i64, i64* %t482
  br label %map_read_end_106
map_read_end_106:
  %t484 = phi i64* [ null, %map_read_null_104 ], [ %t479, %map_read_real_105 ]
  %t485 = phi i32* [ null, %map_read_null_104 ], [ %t481, %map_read_real_105 ]
  %t486 = phi i64 [ 0, %map_read_null_104 ], [ %t483, %map_read_real_105 ]
  %t487 = trunc i64 %t486 to i32
  %t488 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.24, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t488, i32 %t487)
  %t489 = load i64, i64* %t0
  %t490 = load i8*, i8** %t157
  %t491 = icmp eq i8* %t490, null
  br i1 %t491, label %map_read_null_107, label %map_read_real_108
map_read_null_107:
  br label %map_read_end_109
map_read_real_108:
  %t492 = bitcast i8* %t490 to { i64*, i32*, i64, i64 }*
  %t493 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t492, i32 0, i32 0
  %t494 = load i64*, i64** %t493
  %t495 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t492, i32 0, i32 1
  %t496 = load i32*, i32** %t495
  %t497 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t492, i32 0, i32 2
  %t498 = load i64, i64* %t497
  br label %map_read_end_109
map_read_end_109:
  %t499 = phi i64* [ null, %map_read_null_107 ], [ %t494, %map_read_real_108 ]
  %t500 = phi i32* [ null, %map_read_null_107 ], [ %t496, %map_read_real_108 ]
  %t501 = phi i64 [ 0, %map_read_null_107 ], [ %t498, %map_read_real_108 ]
  store i64 0, i64* %t502
  br label %map_find_cond_110
map_find_cond_110:
  %t503 = load i64, i64* %t502
  %t504 = icmp slt i64 %t503, %t501
  br i1 %t504, label %map_find_body_111, label %map_find_end_114
map_find_body_111:
  %t505 = getelementptr inbounds i64, i64* %t499, i64 %t503
  %t506 = load i64, i64* %t505
  br label %map_find_eq_check_112
map_find_eq_check_112:
  %t507 = call i1 @eq_symbol(i64 %t506, i64 %t489)
  br i1 %t507, label %map_find_end_114, label %map_find_next_113
map_find_next_113:
  %t508 = add i64 %t503, 1
  store i64 %t508, i64* %t502
  br label %map_find_cond_110
map_find_end_114:
  %t509 = load i64, i64* %t502
  %t510 = icmp slt i64 %t509, %t501
  br i1 %t510, label %map_get_some_115, label %map_get_none_116
map_get_some_115:
  %t511 = getelementptr inbounds i32, i32* %t500, i64 %t509
  %t512 = load i32, i32* %t511
  %t514 = getelementptr inbounds %Option__i32, %Option__i32* %t513, i32 0, i32 0
  store i32 1, i32* %t514
  %t515 = getelementptr inbounds %Option__i32, %Option__i32* %t513, i32 0, i32 1
  %t516 = bitcast [1 x i64]* %t515 to { i32 }*
  %t517 = getelementptr inbounds { i32 }, { i32 }* %t516, i32 0, i32 0
  store i32 %t512, i32* %t517
  %t518 = load %Option__i32, %Option__i32* %t513
  br label %map_get_end_117
map_get_none_116:
  %t520 = getelementptr inbounds %Option__i32, %Option__i32* %t519, i32 0, i32 0
  store i32 0, i32* %t520
  %t521 = load %Option__i32, %Option__i32* %t519
  br label %map_get_end_117
map_get_end_117:
  %t522 = phi %Option__i32 [ %t518, %map_get_some_115 ], [ %t521, %map_get_none_116 ]
  store %Option__i32 %t522, %Option__i32* %t523
  br label %match_scrutinee_525
match_scrutinee_525:
  %t529 = getelementptr inbounds %Option__i32, %Option__i32* %t523, i32 0, i32 0
  %t530 = load i32, i32* %t529
  %t528 = icmp eq i32 %t530, 1
  br i1 %t528, label %match_then_0_526, label %match_next_0_527
match_then_0_526:
  %t531 = getelementptr inbounds %Option__i32, %Option__i32* %t523, i32 0, i32 1
  %t532 = bitcast [1 x i64]* %t531 to { i32 }*
  %t533 = getelementptr inbounds { i32 }, { i32 }* %t532, i32 0, i32 0
  %t534 = load i32, i32* %t533
  %t535 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.25, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t535, i32 %t534)
  br label %match_end_524
match_next_0_527:
  %t539 = getelementptr inbounds %Option__i32, %Option__i32* %t523, i32 0, i32 0
  %t540 = load i32, i32* %t539
  %t538 = icmp eq i32 %t540, 0
  br i1 %t538, label %match_then_1_536, label %match_next_1_537
match_then_1_536:
  %t541 = getelementptr inbounds { i64, i8*, [18 x i8] }, { i64, i8*, [18 x i8] }* @.str.26, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t541)
  call i32 (i8*, ...) @printf(i8* %t541)
  br label %match_end_524
match_next_1_537:
  br label %match_end_524
match_end_524:
  store i8* null, i8** %t542
  %t543 = getelementptr i64, i64* null, i32 1
  %t544 = ptrtoint i64* %t543 to i64
  %t545 = load i8*, i8** %t542
  %t546 = icmp eq i8* %t545, null
  br i1 %t546, label %set_cow_alloc_118, label %set_cow_check_119
set_cow_alloc_118:
  %t551 = bitcast void (i8*)* @set_release_symbol to i8*
  %t552 = call i8* @star_rc_alloc(i64 24, i8* %t551)
  %t553 = bitcast i8* %t552 to { i64*, i64, i64 }*
  %t554 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t553, i32 0, i32 0
  store i64* null, i64** %t554
  %t555 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t553, i32 0, i32 1
  store i64 0, i64* %t555
  %t556 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t553, i32 0, i32 2
  store i64 0, i64* %t556
  store i8* %t552, i8** %t542
  br label %set_cow_done_120
set_cow_check_119:
  %t557 = getelementptr inbounds i8, i8* %t545, i64 -16
  %t558 = bitcast i8* %t557 to i64*
  %t559 = load atomic i64, i64* %t558 seq_cst, align 8
  %t560 = icmp eq i64 %t559, 1
  br i1 %t560, label %set_cow_done_120, label %set_cow_clone_121
set_cow_clone_121:
  %t561 = bitcast i8* %t545 to { i64*, i64, i64 }*
  %t562 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t561, i32 0, i32 0
  %t563 = load i64*, i64** %t562
  %t564 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t561, i32 0, i32 1
  %t565 = load i64, i64* %t564
  %t566 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t561, i32 0, i32 2
  %t567 = load i64, i64* %t566
  %t568 = bitcast void (i8*)* @set_release_symbol to i8*
  %t569 = call i8* @star_rc_alloc(i64 24, i8* %t568)
  %t570 = bitcast i8* %t569 to { i64*, i64, i64 }*
  %t571 = mul i64 %t567, %t544
  %t572 = call i8* @malloc(i64 %t571)
  %t573 = bitcast i8* %t572 to i64*
  %t574 = icmp sgt i64 %t565, 0
  br i1 %t574, label %set_cow_copy_122, label %set_cow_after_copy_123
set_cow_copy_122:
  %t575 = mul i64 %t565, %t544
  %t576 = bitcast i64* %t563 to i8*
  call i8* @memcpy(i8* %t572, i8* %t576, i64 %t575)
  br label %set_cow_after_copy_123
set_cow_after_copy_123:
  %t577 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t570, i32 0, i32 0
  store i64* %t573, i64** %t577
  %t578 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t570, i32 0, i32 1
  store i64 %t565, i64* %t578
  %t579 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t570, i32 0, i32 2
  store i64 %t567, i64* %t579
  call void @star_rc_release(i8* %t545)
  store i8* %t569, i8** %t542
  br label %set_cow_done_120
set_cow_done_120:
  %t580 = load i8*, i8** %t542
  %t581 = bitcast i8* %t580 to { i64*, i64, i64 }*
  %t582 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t581, i32 0, i32 0
  %t583 = load i64*, i64** %t582
  %t584 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t581, i32 0, i32 1
  %t585 = load i64, i64* %t584
  %t586 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t581, i32 0, i32 2
  %t587 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.27, i64 0, i32 2, i64 0
  %t588 = load i64, i64* @sym.len
  %t589 = load i8**, i8*** @sym.data
  store i64 0, i64* %t590
  br label %sym_find_cond_124
sym_find_cond_124:
  %t591 = load i64, i64* %t590
  %t592 = icmp slt i64 %t591, %t588
  br i1 %t592, label %sym_find_body_125, label %sym_find_end_127
sym_find_body_125:
  %t593 = getelementptr inbounds i8*, i8** %t589, i64 %t591
  %t594 = load i8*, i8** %t593
  %t595 = call i32 @strcmp(i8* %t594, i8* %t587)
  %t596 = icmp eq i32 %t595, 0
  br i1 %t596, label %sym_find_end_127, label %sym_find_next_126
sym_find_next_126:
  %t597 = add i64 %t591, 1
  store i64 %t597, i64* %t590
  br label %sym_find_cond_124
sym_find_end_127:
  %t598 = load i64, i64* %t590
  %t599 = icmp slt i64 %t598, %t588
  br i1 %t599, label %sym_found_128, label %sym_notfound_129
sym_found_128:
  call void @star_rc_release(i8* %t587)
  br label %sym_done_130
sym_notfound_129:
  %t600 = load i64, i64* @sym.cap
  %t601 = icmp sge i64 %t588, %t600
  br i1 %t601, label %sym_grow_131, label %sym_store_132
sym_grow_131:
  %t602 = mul i64 %t600, 2
  %t603 = icmp sgt i64 %t602, 0
  %t604 = select i1 %t603, i64 %t602, i64 1
  %t605 = mul i64 %t604, 8
  %t606 = call i8* @malloc(i64 %t605)
  %t607 = bitcast i8* %t606 to i8**
  %t608 = icmp sgt i64 %t600, 0
  br i1 %t608, label %sym_copy_133, label %sym_after_copy_134
sym_copy_133:
  %t609 = mul i64 %t588, 8
  %t610 = bitcast i8** %t589 to i8*
  call i8* @memcpy(i8* %t606, i8* %t610, i64 %t609)
  call void @free(i8* %t610)
  br label %sym_after_copy_134
sym_after_copy_134:
  store i8** %t607, i8*** @sym.data
  store i64 %t604, i64* @sym.cap
  br label %sym_store_132
sym_store_132:
  %t611 = load i8**, i8*** @sym.data
  %t612 = getelementptr inbounds i8*, i8** %t611, i64 %t588
  store i8* %t587, i8** %t612
  %t613 = add i64 %t588, 1
  store i64 %t613, i64* @sym.len
  br label %sym_done_130
sym_done_130:
  %t614 = phi i64 [ %t598, %sym_found_128 ], [ %t588, %sym_store_132 ]
  %t615 = load i64, i64* %t584
  %t616 = load i64*, i64** %t582
  store i64 0, i64* %t617
  store i1 false, i1* %t618
  br label %find_cond_135
find_cond_135:
  %t619 = load i64, i64* %t617
  %t620 = icmp slt i64 %t619, %t615
  br i1 %t620, label %find_body_136, label %find_end_139
find_body_136:
  %t621 = getelementptr inbounds i64, i64* %t616, i64 %t619
  %t622 = load i64, i64* %t621
  br label %find_eq_check_137
find_eq_check_137:
  %t623 = call i1 @eq_symbol(i64 %t622, i64 %t614)
  br i1 %t623, label %find_end_139, label %find_next_138
find_next_138:
  %t624 = add i64 %t619, 1
  store i64 %t624, i64* %t617
  br label %find_cond_135
find_end_139:
  %t625 = load i64, i64* %t617
  %t626 = icmp slt i64 %t625, %t615
  br i1 %t626, label %set_insert_already_present_140, label %set_insert_do_141
set_insert_already_present_140:
  br label %set_insert_end_142
set_insert_do_141:
  %t627 = load i64, i64* %t586
  %t628 = load i64*, i64** %t582
  %t629 = icmp sge i64 %t615, %t627
  br i1 %t629, label %set_insert_grow_143, label %set_insert_store_144
set_insert_grow_143:
  %t630 = mul i64 %t627, 2
  %t631 = icmp sgt i64 %t630, 0
  %t632 = select i1 %t631, i64 %t630, i64 1
  %t633 = getelementptr i64, i64* null, i32 1
  %t634 = ptrtoint i64* %t633 to i64
  %t635 = mul i64 %t632, %t634
  %t636 = call i8* @malloc(i64 %t635)
  %t637 = bitcast i8* %t636 to i64*
  %t638 = icmp sgt i64 %t627, 0
  br i1 %t638, label %set_insert_copy_145, label %set_insert_after_copy_146
set_insert_copy_145:
  %t639 = mul i64 %t615, %t634
  %t640 = bitcast i64* %t628 to i8*
  call i8* @memcpy(i8* %t636, i8* %t640, i64 %t639)
  call void @free(i8* %t640)
  br label %set_insert_after_copy_146
set_insert_after_copy_146:
  store i64* %t637, i64** %t582
  store i64 %t632, i64* %t586
  br label %set_insert_store_144
set_insert_store_144:
  %t641 = load i64*, i64** %t582
  %t642 = getelementptr inbounds i64, i64* %t641, i64 %t615
  store i64 %t614, i64* %t642
  %t643 = add i64 %t615, 1
  store i64 %t643, i64* %t584
  br label %set_insert_end_142
set_insert_end_142:
  %t644 = phi i1 [ false, %set_insert_already_present_140 ], [ true, %set_insert_store_144 ]
  %t645 = getelementptr i64, i64* null, i32 1
  %t646 = ptrtoint i64* %t645 to i64
  %t647 = load i8*, i8** %t542
  %t648 = icmp eq i8* %t647, null
  br i1 %t648, label %set_cow_alloc_147, label %set_cow_check_148
set_cow_alloc_147:
  %t649 = bitcast void (i8*)* @set_release_symbol to i8*
  %t650 = call i8* @star_rc_alloc(i64 24, i8* %t649)
  %t651 = bitcast i8* %t650 to { i64*, i64, i64 }*
  %t652 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t651, i32 0, i32 0
  store i64* null, i64** %t652
  %t653 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t651, i32 0, i32 1
  store i64 0, i64* %t653
  %t654 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t651, i32 0, i32 2
  store i64 0, i64* %t654
  store i8* %t650, i8** %t542
  br label %set_cow_done_149
set_cow_check_148:
  %t655 = getelementptr inbounds i8, i8* %t647, i64 -16
  %t656 = bitcast i8* %t655 to i64*
  %t657 = load atomic i64, i64* %t656 seq_cst, align 8
  %t658 = icmp eq i64 %t657, 1
  br i1 %t658, label %set_cow_done_149, label %set_cow_clone_150
set_cow_clone_150:
  %t659 = bitcast i8* %t647 to { i64*, i64, i64 }*
  %t660 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t659, i32 0, i32 0
  %t661 = load i64*, i64** %t660
  %t662 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t659, i32 0, i32 1
  %t663 = load i64, i64* %t662
  %t664 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t659, i32 0, i32 2
  %t665 = load i64, i64* %t664
  %t666 = bitcast void (i8*)* @set_release_symbol to i8*
  %t667 = call i8* @star_rc_alloc(i64 24, i8* %t666)
  %t668 = bitcast i8* %t667 to { i64*, i64, i64 }*
  %t669 = mul i64 %t665, %t646
  %t670 = call i8* @malloc(i64 %t669)
  %t671 = bitcast i8* %t670 to i64*
  %t672 = icmp sgt i64 %t663, 0
  br i1 %t672, label %set_cow_copy_151, label %set_cow_after_copy_152
set_cow_copy_151:
  %t673 = mul i64 %t663, %t646
  %t674 = bitcast i64* %t661 to i8*
  call i8* @memcpy(i8* %t670, i8* %t674, i64 %t673)
  br label %set_cow_after_copy_152
set_cow_after_copy_152:
  %t675 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t668, i32 0, i32 0
  store i64* %t671, i64** %t675
  %t676 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t668, i32 0, i32 1
  store i64 %t663, i64* %t676
  %t677 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t668, i32 0, i32 2
  store i64 %t665, i64* %t677
  call void @star_rc_release(i8* %t647)
  store i8* %t667, i8** %t542
  br label %set_cow_done_149
set_cow_done_149:
  %t678 = load i8*, i8** %t542
  %t679 = bitcast i8* %t678 to { i64*, i64, i64 }*
  %t680 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t679, i32 0, i32 0
  %t681 = load i64*, i64** %t680
  %t682 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t679, i32 0, i32 1
  %t683 = load i64, i64* %t682
  %t684 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t679, i32 0, i32 2
  %t685 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.28, i64 0, i32 2, i64 0
  %t686 = load i64, i64* @sym.len
  %t687 = load i8**, i8*** @sym.data
  store i64 0, i64* %t688
  br label %sym_find_cond_153
sym_find_cond_153:
  %t689 = load i64, i64* %t688
  %t690 = icmp slt i64 %t689, %t686
  br i1 %t690, label %sym_find_body_154, label %sym_find_end_156
sym_find_body_154:
  %t691 = getelementptr inbounds i8*, i8** %t687, i64 %t689
  %t692 = load i8*, i8** %t691
  %t693 = call i32 @strcmp(i8* %t692, i8* %t685)
  %t694 = icmp eq i32 %t693, 0
  br i1 %t694, label %sym_find_end_156, label %sym_find_next_155
sym_find_next_155:
  %t695 = add i64 %t689, 1
  store i64 %t695, i64* %t688
  br label %sym_find_cond_153
sym_find_end_156:
  %t696 = load i64, i64* %t688
  %t697 = icmp slt i64 %t696, %t686
  br i1 %t697, label %sym_found_157, label %sym_notfound_158
sym_found_157:
  call void @star_rc_release(i8* %t685)
  br label %sym_done_159
sym_notfound_158:
  %t698 = load i64, i64* @sym.cap
  %t699 = icmp sge i64 %t686, %t698
  br i1 %t699, label %sym_grow_160, label %sym_store_161
sym_grow_160:
  %t700 = mul i64 %t698, 2
  %t701 = icmp sgt i64 %t700, 0
  %t702 = select i1 %t701, i64 %t700, i64 1
  %t703 = mul i64 %t702, 8
  %t704 = call i8* @malloc(i64 %t703)
  %t705 = bitcast i8* %t704 to i8**
  %t706 = icmp sgt i64 %t698, 0
  br i1 %t706, label %sym_copy_162, label %sym_after_copy_163
sym_copy_162:
  %t707 = mul i64 %t686, 8
  %t708 = bitcast i8** %t687 to i8*
  call i8* @memcpy(i8* %t704, i8* %t708, i64 %t707)
  call void @free(i8* %t708)
  br label %sym_after_copy_163
sym_after_copy_163:
  store i8** %t705, i8*** @sym.data
  store i64 %t702, i64* @sym.cap
  br label %sym_store_161
sym_store_161:
  %t709 = load i8**, i8*** @sym.data
  %t710 = getelementptr inbounds i8*, i8** %t709, i64 %t686
  store i8* %t685, i8** %t710
  %t711 = add i64 %t686, 1
  store i64 %t711, i64* @sym.len
  br label %sym_done_159
sym_done_159:
  %t712 = phi i64 [ %t696, %sym_found_157 ], [ %t686, %sym_store_161 ]
  %t713 = load i64, i64* %t682
  %t714 = load i64*, i64** %t680
  store i64 0, i64* %t715
  store i1 false, i1* %t716
  br label %find_cond_164
find_cond_164:
  %t717 = load i64, i64* %t715
  %t718 = icmp slt i64 %t717, %t713
  br i1 %t718, label %find_body_165, label %find_end_168
find_body_165:
  %t719 = getelementptr inbounds i64, i64* %t714, i64 %t717
  %t720 = load i64, i64* %t719
  br label %find_eq_check_166
find_eq_check_166:
  %t721 = call i1 @eq_symbol(i64 %t720, i64 %t712)
  br i1 %t721, label %find_end_168, label %find_next_167
find_next_167:
  %t722 = add i64 %t717, 1
  store i64 %t722, i64* %t715
  br label %find_cond_164
find_end_168:
  %t723 = load i64, i64* %t715
  %t724 = icmp slt i64 %t723, %t713
  br i1 %t724, label %set_insert_already_present_169, label %set_insert_do_170
set_insert_already_present_169:
  br label %set_insert_end_171
set_insert_do_170:
  %t725 = load i64, i64* %t684
  %t726 = load i64*, i64** %t680
  %t727 = icmp sge i64 %t713, %t725
  br i1 %t727, label %set_insert_grow_172, label %set_insert_store_173
set_insert_grow_172:
  %t728 = mul i64 %t725, 2
  %t729 = icmp sgt i64 %t728, 0
  %t730 = select i1 %t729, i64 %t728, i64 1
  %t731 = getelementptr i64, i64* null, i32 1
  %t732 = ptrtoint i64* %t731 to i64
  %t733 = mul i64 %t730, %t732
  %t734 = call i8* @malloc(i64 %t733)
  %t735 = bitcast i8* %t734 to i64*
  %t736 = icmp sgt i64 %t725, 0
  br i1 %t736, label %set_insert_copy_174, label %set_insert_after_copy_175
set_insert_copy_174:
  %t737 = mul i64 %t713, %t732
  %t738 = bitcast i64* %t726 to i8*
  call i8* @memcpy(i8* %t734, i8* %t738, i64 %t737)
  call void @free(i8* %t738)
  br label %set_insert_after_copy_175
set_insert_after_copy_175:
  store i64* %t735, i64** %t680
  store i64 %t730, i64* %t684
  br label %set_insert_store_173
set_insert_store_173:
  %t739 = load i64*, i64** %t680
  %t740 = getelementptr inbounds i64, i64* %t739, i64 %t713
  store i64 %t712, i64* %t740
  %t741 = add i64 %t713, 1
  store i64 %t741, i64* %t682
  br label %set_insert_end_171
set_insert_end_171:
  %t742 = phi i1 [ false, %set_insert_already_present_169 ], [ true, %set_insert_store_173 ]
  %t743 = getelementptr i64, i64* null, i32 1
  %t744 = ptrtoint i64* %t743 to i64
  %t745 = load i8*, i8** %t542
  %t746 = icmp eq i8* %t745, null
  br i1 %t746, label %set_cow_alloc_176, label %set_cow_check_177
set_cow_alloc_176:
  %t747 = bitcast void (i8*)* @set_release_symbol to i8*
  %t748 = call i8* @star_rc_alloc(i64 24, i8* %t747)
  %t749 = bitcast i8* %t748 to { i64*, i64, i64 }*
  %t750 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t749, i32 0, i32 0
  store i64* null, i64** %t750
  %t751 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t749, i32 0, i32 1
  store i64 0, i64* %t751
  %t752 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t749, i32 0, i32 2
  store i64 0, i64* %t752
  store i8* %t748, i8** %t542
  br label %set_cow_done_178
set_cow_check_177:
  %t753 = getelementptr inbounds i8, i8* %t745, i64 -16
  %t754 = bitcast i8* %t753 to i64*
  %t755 = load atomic i64, i64* %t754 seq_cst, align 8
  %t756 = icmp eq i64 %t755, 1
  br i1 %t756, label %set_cow_done_178, label %set_cow_clone_179
set_cow_clone_179:
  %t757 = bitcast i8* %t745 to { i64*, i64, i64 }*
  %t758 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t757, i32 0, i32 0
  %t759 = load i64*, i64** %t758
  %t760 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t757, i32 0, i32 1
  %t761 = load i64, i64* %t760
  %t762 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t757, i32 0, i32 2
  %t763 = load i64, i64* %t762
  %t764 = bitcast void (i8*)* @set_release_symbol to i8*
  %t765 = call i8* @star_rc_alloc(i64 24, i8* %t764)
  %t766 = bitcast i8* %t765 to { i64*, i64, i64 }*
  %t767 = mul i64 %t763, %t744
  %t768 = call i8* @malloc(i64 %t767)
  %t769 = bitcast i8* %t768 to i64*
  %t770 = icmp sgt i64 %t761, 0
  br i1 %t770, label %set_cow_copy_180, label %set_cow_after_copy_181
set_cow_copy_180:
  %t771 = mul i64 %t761, %t744
  %t772 = bitcast i64* %t759 to i8*
  call i8* @memcpy(i8* %t768, i8* %t772, i64 %t771)
  br label %set_cow_after_copy_181
set_cow_after_copy_181:
  %t773 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t766, i32 0, i32 0
  store i64* %t769, i64** %t773
  %t774 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t766, i32 0, i32 1
  store i64 %t761, i64* %t774
  %t775 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t766, i32 0, i32 2
  store i64 %t763, i64* %t775
  call void @star_rc_release(i8* %t745)
  store i8* %t765, i8** %t542
  br label %set_cow_done_178
set_cow_done_178:
  %t776 = load i8*, i8** %t542
  %t777 = bitcast i8* %t776 to { i64*, i64, i64 }*
  %t778 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t777, i32 0, i32 0
  %t779 = load i64*, i64** %t778
  %t780 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t777, i32 0, i32 1
  %t781 = load i64, i64* %t780
  %t782 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t777, i32 0, i32 2
  %t783 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.29, i64 0, i32 2, i64 0
  %t784 = load i64, i64* @sym.len
  %t785 = load i8**, i8*** @sym.data
  store i64 0, i64* %t786
  br label %sym_find_cond_182
sym_find_cond_182:
  %t787 = load i64, i64* %t786
  %t788 = icmp slt i64 %t787, %t784
  br i1 %t788, label %sym_find_body_183, label %sym_find_end_185
sym_find_body_183:
  %t789 = getelementptr inbounds i8*, i8** %t785, i64 %t787
  %t790 = load i8*, i8** %t789
  %t791 = call i32 @strcmp(i8* %t790, i8* %t783)
  %t792 = icmp eq i32 %t791, 0
  br i1 %t792, label %sym_find_end_185, label %sym_find_next_184
sym_find_next_184:
  %t793 = add i64 %t787, 1
  store i64 %t793, i64* %t786
  br label %sym_find_cond_182
sym_find_end_185:
  %t794 = load i64, i64* %t786
  %t795 = icmp slt i64 %t794, %t784
  br i1 %t795, label %sym_found_186, label %sym_notfound_187
sym_found_186:
  call void @star_rc_release(i8* %t783)
  br label %sym_done_188
sym_notfound_187:
  %t796 = load i64, i64* @sym.cap
  %t797 = icmp sge i64 %t784, %t796
  br i1 %t797, label %sym_grow_189, label %sym_store_190
sym_grow_189:
  %t798 = mul i64 %t796, 2
  %t799 = icmp sgt i64 %t798, 0
  %t800 = select i1 %t799, i64 %t798, i64 1
  %t801 = mul i64 %t800, 8
  %t802 = call i8* @malloc(i64 %t801)
  %t803 = bitcast i8* %t802 to i8**
  %t804 = icmp sgt i64 %t796, 0
  br i1 %t804, label %sym_copy_191, label %sym_after_copy_192
sym_copy_191:
  %t805 = mul i64 %t784, 8
  %t806 = bitcast i8** %t785 to i8*
  call i8* @memcpy(i8* %t802, i8* %t806, i64 %t805)
  call void @free(i8* %t806)
  br label %sym_after_copy_192
sym_after_copy_192:
  store i8** %t803, i8*** @sym.data
  store i64 %t800, i64* @sym.cap
  br label %sym_store_190
sym_store_190:
  %t807 = load i8**, i8*** @sym.data
  %t808 = getelementptr inbounds i8*, i8** %t807, i64 %t784
  store i8* %t783, i8** %t808
  %t809 = add i64 %t784, 1
  store i64 %t809, i64* @sym.len
  br label %sym_done_188
sym_done_188:
  %t810 = phi i64 [ %t794, %sym_found_186 ], [ %t784, %sym_store_190 ]
  %t811 = load i64, i64* %t780
  %t812 = load i64*, i64** %t778
  store i64 0, i64* %t813
  store i1 false, i1* %t814
  br label %find_cond_193
find_cond_193:
  %t815 = load i64, i64* %t813
  %t816 = icmp slt i64 %t815, %t811
  br i1 %t816, label %find_body_194, label %find_end_197
find_body_194:
  %t817 = getelementptr inbounds i64, i64* %t812, i64 %t815
  %t818 = load i64, i64* %t817
  br label %find_eq_check_195
find_eq_check_195:
  %t819 = call i1 @eq_symbol(i64 %t818, i64 %t810)
  br i1 %t819, label %find_end_197, label %find_next_196
find_next_196:
  %t820 = add i64 %t815, 1
  store i64 %t820, i64* %t813
  br label %find_cond_193
find_end_197:
  %t821 = load i64, i64* %t813
  %t822 = icmp slt i64 %t821, %t811
  br i1 %t822, label %set_insert_already_present_198, label %set_insert_do_199
set_insert_already_present_198:
  br label %set_insert_end_200
set_insert_do_199:
  %t823 = load i64, i64* %t782
  %t824 = load i64*, i64** %t778
  %t825 = icmp sge i64 %t811, %t823
  br i1 %t825, label %set_insert_grow_201, label %set_insert_store_202
set_insert_grow_201:
  %t826 = mul i64 %t823, 2
  %t827 = icmp sgt i64 %t826, 0
  %t828 = select i1 %t827, i64 %t826, i64 1
  %t829 = getelementptr i64, i64* null, i32 1
  %t830 = ptrtoint i64* %t829 to i64
  %t831 = mul i64 %t828, %t830
  %t832 = call i8* @malloc(i64 %t831)
  %t833 = bitcast i8* %t832 to i64*
  %t834 = icmp sgt i64 %t823, 0
  br i1 %t834, label %set_insert_copy_203, label %set_insert_after_copy_204
set_insert_copy_203:
  %t835 = mul i64 %t811, %t830
  %t836 = bitcast i64* %t824 to i8*
  call i8* @memcpy(i8* %t832, i8* %t836, i64 %t835)
  call void @free(i8* %t836)
  br label %set_insert_after_copy_204
set_insert_after_copy_204:
  store i64* %t833, i64** %t778
  store i64 %t828, i64* %t782
  br label %set_insert_store_202
set_insert_store_202:
  %t837 = load i64*, i64** %t778
  %t838 = getelementptr inbounds i64, i64* %t837, i64 %t811
  store i64 %t810, i64* %t838
  %t839 = add i64 %t811, 1
  store i64 %t839, i64* %t780
  br label %set_insert_end_200
set_insert_end_200:
  %t840 = phi i1 [ false, %set_insert_already_present_198 ], [ true, %set_insert_store_202 ]
  %t841 = load i8*, i8** %t542
  %t842 = icmp eq i8* %t841, null
  br i1 %t842, label %set_read_null_205, label %set_read_real_206
set_read_null_205:
  br label %set_read_end_207
set_read_real_206:
  %t843 = bitcast i8* %t841 to { i64*, i64, i64 }*
  %t844 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t843, i32 0, i32 0
  %t845 = load i64*, i64** %t844
  %t846 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t843, i32 0, i32 1
  %t847 = load i64, i64* %t846
  br label %set_read_end_207
set_read_end_207:
  %t848 = phi i64* [ null, %set_read_null_205 ], [ %t845, %set_read_real_206 ]
  %t849 = phi i64 [ 0, %set_read_null_205 ], [ %t847, %set_read_real_206 ]
  %t850 = trunc i64 %t849 to i32
  %t851 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.30, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t851, i32 %t850)
  %t853 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.31, i64 0, i32 2, i64 0
  %t854 = load i64, i64* @sym.len
  %t855 = load i8**, i8*** @sym.data
  store i64 0, i64* %t856
  br label %sym_find_cond_208
sym_find_cond_208:
  %t857 = load i64, i64* %t856
  %t858 = icmp slt i64 %t857, %t854
  br i1 %t858, label %sym_find_body_209, label %sym_find_end_211
sym_find_body_209:
  %t859 = getelementptr inbounds i8*, i8** %t855, i64 %t857
  %t860 = load i8*, i8** %t859
  %t861 = call i32 @strcmp(i8* %t860, i8* %t853)
  %t862 = icmp eq i32 %t861, 0
  br i1 %t862, label %sym_find_end_211, label %sym_find_next_210
sym_find_next_210:
  %t863 = add i64 %t857, 1
  store i64 %t863, i64* %t856
  br label %sym_find_cond_208
sym_find_end_211:
  %t864 = load i64, i64* %t856
  %t865 = icmp slt i64 %t864, %t854
  br i1 %t865, label %sym_found_212, label %sym_notfound_213
sym_found_212:
  call void @star_rc_release(i8* %t853)
  br label %sym_done_214
sym_notfound_213:
  %t866 = load i64, i64* @sym.cap
  %t867 = icmp sge i64 %t854, %t866
  br i1 %t867, label %sym_grow_215, label %sym_store_216
sym_grow_215:
  %t868 = mul i64 %t866, 2
  %t869 = icmp sgt i64 %t868, 0
  %t870 = select i1 %t869, i64 %t868, i64 1
  %t871 = mul i64 %t870, 8
  %t872 = call i8* @malloc(i64 %t871)
  %t873 = bitcast i8* %t872 to i8**
  %t874 = icmp sgt i64 %t866, 0
  br i1 %t874, label %sym_copy_217, label %sym_after_copy_218
sym_copy_217:
  %t875 = mul i64 %t854, 8
  %t876 = bitcast i8** %t855 to i8*
  call i8* @memcpy(i8* %t872, i8* %t876, i64 %t875)
  call void @free(i8* %t876)
  br label %sym_after_copy_218
sym_after_copy_218:
  store i8** %t873, i8*** @sym.data
  store i64 %t870, i64* @sym.cap
  br label %sym_store_216
sym_store_216:
  %t877 = load i8**, i8*** @sym.data
  %t878 = getelementptr inbounds i8*, i8** %t877, i64 %t854
  store i8* %t853, i8** %t878
  %t879 = add i64 %t854, 1
  store i64 %t879, i64* @sym.len
  br label %sym_done_214
sym_done_214:
  %t880 = phi i64 [ %t864, %sym_found_212 ], [ %t854, %sym_store_216 ]
  %t881 = load i8*, i8** %t542
  %t882 = icmp eq i8* %t881, null
  br i1 %t882, label %set_read_null_219, label %set_read_real_220
set_read_null_219:
  br label %set_read_end_221
set_read_real_220:
  %t883 = bitcast i8* %t881 to { i64*, i64, i64 }*
  %t884 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t883, i32 0, i32 0
  %t885 = load i64*, i64** %t884
  %t886 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t883, i32 0, i32 1
  %t887 = load i64, i64* %t886
  br label %set_read_end_221
set_read_end_221:
  %t888 = phi i64* [ null, %set_read_null_219 ], [ %t885, %set_read_real_220 ]
  %t889 = phi i64 [ 0, %set_read_null_219 ], [ %t887, %set_read_real_220 ]
  store i64 0, i64* %t890
  store i1 false, i1* %t891
  br label %find_cond_222
find_cond_222:
  %t892 = load i64, i64* %t890
  %t893 = icmp slt i64 %t892, %t889
  br i1 %t893, label %find_body_223, label %find_end_226
find_body_223:
  %t894 = getelementptr inbounds i64, i64* %t888, i64 %t892
  %t895 = load i64, i64* %t894
  br label %find_eq_check_224
find_eq_check_224:
  %t896 = call i1 @eq_symbol(i64 %t895, i64 %t880)
  br i1 %t896, label %find_end_226, label %find_next_225
find_next_225:
  %t897 = add i64 %t892, 1
  store i64 %t897, i64* %t890
  br label %find_cond_222
find_end_226:
  %t898 = load i64, i64* %t890
  %t899 = icmp slt i64 %t898, %t889
  store i1 %t899, i1* %t852
  %t900 = load i1, i1* %t852
  %t901 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.32, i64 0, i64 0
  %t902 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.33, i64 0, i64 0
  %t903 = select i1 %t900, i8* %t901, i8* %t902
  %t904 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.34, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t904, i8* %t903)
  %t905 = load i8*, i8** %t542
  call void @star_rc_release(i8* %t905)
  %t906 = load i8*, i8** %t157
  call void @star_rc_release(i8* %t906)
  ret i32 0
}


; par/swarm worker functions
define void @map_release_6_symboli32(i8* %objp) {
entry:
  %t164 = bitcast i8* %objp to { i64*, i32*, i64, i64 }*
  %t165 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t164, i32 0, i32 0
  %t166 = load i64*, i64** %t165
  %t167 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t164, i32 0, i32 1
  %t168 = load i32*, i32** %t167
  %t169 = bitcast i64* %t166 to i8*
  call void @free(i8* %t169)
  %t170 = bitcast i32* %t168 to i8*
  call void @free(i8* %t170)
  ret void
}


define i1 @eq_symbol(i64 %a, i64 %b) {
entry:
  %t221 = icmp eq i64 %a, %b
  ret i1 %t221
}


define void @set_release_symbol(i8* %objp) {
entry:
  %t547 = bitcast i8* %objp to { i64*, i64, i64 }*
  %t548 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t547, i32 0, i32 0
  %t549 = load i64*, i64** %t548
  %t550 = bitcast i64* %t549 to i8*
  call void @free(i8* %t550)
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
