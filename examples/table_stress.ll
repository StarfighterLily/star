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

%Item = type { i32, i8* }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i32
  %t67 = alloca i64
  %t83 = alloca %Item
  %t154 = alloca %Item
  %t164 = alloca %Item
  %t181 = alloca %Item
  %t191 = alloca %Item
  %t208 = alloca %Item
  %t218 = alloca %Item
  %t235 = alloca %Item
  %t245 = alloca %Item
  %t249 = alloca i8*
  %t252 = alloca i32
  %t303 = alloca i64
  %t319 = alloca %Item
  %t403 = alloca %Item
  %t413 = alloca %Item
  %t430 = alloca %Item
  %t440 = alloca %Item
  %t458 = alloca %Item
  %t468 = alloca %Item
  %t485 = alloca %Item
  %t495 = alloca %Item
  %t500 = alloca i8*
  %t501 = alloca i32
  %t552 = alloca i64
  %t568 = alloca %Item
  %t619 = alloca %Item
  %t668 = alloca i64
  %t684 = alloca %Item
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  store i8* null, i8** %t0
  store i32 0, i32* %t1
  br label %while_cond_0
while_cond_0:
  %t2 = load i32, i32* %t1
  %t3 = icmp slt i32 %t2, 5000
  br i1 %t3, label %while_body_1, label %while_else_2
while_body_1:
  %t4 = load i8*, i8** %t0
  %t5 = icmp eq i8* %t4, null
  br i1 %t5, label %table_cow_alloc_4, label %table_cow_check_5
table_cow_alloc_4:
  %t21 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t22 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t23 = ptrtoint { i64, i64, i32*, i8** }* %t22 to i64
  %t24 = call i8* @star_rc_alloc(i64 %t23, i8* %t21)
  %t25 = bitcast i8* %t24 to { i64, i64, i32*, i8** }*
  %t26 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t25, i32 0, i32 0
  store i64 0, i64* %t26
  %t27 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t25, i32 0, i32 1
  store i64 0, i64* %t27
  %t28 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t25, i32 0, i32 2
  store i32* null, i32** %t28
  %t29 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t25, i32 0, i32 3
  store i8** null, i8*** %t29
  store i8* %t24, i8** %t0
  br label %table_cow_done_6
table_cow_check_5:
  %t30 = getelementptr inbounds i8, i8* %t4, i64 -16
  %t31 = bitcast i8* %t30 to i64*
  %t32 = load atomic i64, i64* %t31 seq_cst, align 8
  %t33 = icmp eq i64 %t32, 1
  br i1 %t33, label %table_cow_done_6, label %table_cow_clone_10
table_cow_clone_10:
  %t34 = bitcast i8* %t4 to { i64, i64, i32*, i8** }*
  %t35 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t34, i32 0, i32 0
  %t36 = load i64, i64* %t35
  %t37 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t34, i32 0, i32 1
  %t38 = load i64, i64* %t37
  %t39 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t40 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t41 = ptrtoint { i64, i64, i32*, i8** }* %t40 to i64
  %t42 = call i8* @star_rc_alloc(i64 %t41, i8* %t39)
  %t43 = bitcast i8* %t42 to { i64, i64, i32*, i8** }*
  %t44 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t43, i32 0, i32 0
  store i64 %t36, i64* %t44
  %t45 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t43, i32 0, i32 1
  store i64 %t38, i64* %t45
  %t46 = getelementptr i32, i32* null, i32 1
  %t47 = ptrtoint i32* %t46 to i64
  %t48 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t34, i32 0, i32 2
  %t49 = load i32*, i32** %t48
  %t50 = mul i64 %t38, %t47
  %t51 = call i8* @malloc(i64 %t50)
  %t52 = bitcast i8* %t51 to i32*
  %t53 = icmp sgt i64 %t36, 0
  br i1 %t53, label %table_cow_copy_11, label %table_cow_after_copy_12
table_cow_copy_11:
  %t54 = mul i64 %t36, %t47
  %t55 = bitcast i32* %t49 to i8*
  call i8* @memcpy(i8* %t51, i8* %t55, i64 %t54)
  br label %table_cow_after_copy_12
table_cow_after_copy_12:
  %t56 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t43, i32 0, i32 2
  store i32* %t52, i32** %t56
  %t57 = getelementptr i8*, i8** null, i32 1
  %t58 = ptrtoint i8** %t57 to i64
  %t59 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t34, i32 0, i32 3
  %t60 = load i8**, i8*** %t59
  %t61 = mul i64 %t38, %t58
  %t62 = call i8* @malloc(i64 %t61)
  %t63 = bitcast i8* %t62 to i8**
  %t64 = icmp sgt i64 %t36, 0
  br i1 %t64, label %table_cow_copy_13, label %table_cow_after_copy_14
table_cow_copy_13:
  %t65 = mul i64 %t36, %t58
  %t66 = bitcast i8** %t60 to i8*
  call i8* @memcpy(i8* %t62, i8* %t66, i64 %t65)
  store i64 0, i64* %t67
  br label %table_cow_retain_cond_15
table_cow_retain_cond_15:
  %t68 = load i64, i64* %t67
  %t69 = icmp slt i64 %t68, %t36
  br i1 %t69, label %table_cow_retain_body_16, label %table_cow_retain_end_17
table_cow_retain_body_16:
  %t70 = getelementptr inbounds i8*, i8** %t63, i64 %t68
  %t71 = load i8*, i8** %t70
  call void @star_rc_retain(i8* %t71)
  %t72 = add i64 %t68, 1
  store i64 %t72, i64* %t67
  br label %table_cow_retain_cond_15
table_cow_retain_end_17:
  br label %table_cow_after_copy_14
table_cow_after_copy_14:
  %t73 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t43, i32 0, i32 3
  store i8** %t63, i8*** %t73
  call void @star_rc_release(i8* %t4)
  store i8* %t42, i8** %t0
  br label %table_cow_done_6
table_cow_done_6:
  %t74 = load i8*, i8** %t0
  %t75 = bitcast i8* %t74 to { i64, i64, i32*, i8** }*
  %t76 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t75, i32 0, i32 0
  %t77 = load i64, i64* %t76
  %t78 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t75, i32 0, i32 1
  %t79 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t75, i32 0, i32 2
  %t80 = load i32*, i32** %t79
  %t81 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t75, i32 0, i32 3
  %t82 = load i8**, i8*** %t81
  %t84 = load i32, i32* %t1
  %t85 = getelementptr inbounds %Item, %Item* %t83, i32 0, i32 0
  store i32 %t84, i32* %t85
  %t86 = load i32, i32* %t1
  %t87 = getelementptr inbounds [7 x i8], [7 x i8]* @.str.0, i64 0, i64 0
  %t88 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t87, i32 %t86)
  %t89 = add i32 %t88, 1
  %t90 = sext i32 %t89 to i64
  %t91 = call i8* @star_rc_alloc(i64 %t90, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t91, i64 %t90, i8* %t87, i32 %t86)
  %t92 = getelementptr inbounds %Item, %Item* %t83, i32 0, i32 1
  store i8* %t91, i8** %t92
  %t93 = load %Item, %Item* %t83
  %t94 = load i64, i64* %t78
  %t95 = load i64, i64* %t76
  %t96 = load i32*, i32** %t79
  %t97 = load i8**, i8*** %t81
  %t98 = icmp sge i64 %t95, %t94
  br i1 %t98, label %table_push_grow_18, label %table_push_store_19
table_push_grow_18:
  %t99 = mul i64 %t94, 2
  %t100 = icmp sgt i64 %t99, 0
  %t101 = select i1 %t100, i64 %t99, i64 1
  %t102 = getelementptr i32, i32* null, i32 1
  %t103 = ptrtoint i32* %t102 to i64
  %t104 = mul i64 %t101, %t103
  %t105 = call i8* @malloc(i64 %t104)
  %t106 = bitcast i8* %t105 to i32*
  %t107 = icmp sgt i64 %t94, 0
  br i1 %t107, label %table_push_copy_20, label %table_push_after_copy_21
table_push_copy_20:
  %t108 = mul i64 %t95, %t103
  %t109 = bitcast i32* %t96 to i8*
  call i8* @memcpy(i8* %t105, i8* %t109, i64 %t108)
  call void @free(i8* %t109)
  br label %table_push_after_copy_21
table_push_after_copy_21:
  store i32* %t106, i32** %t79
  %t110 = getelementptr i8*, i8** null, i32 1
  %t111 = ptrtoint i8** %t110 to i64
  %t112 = mul i64 %t101, %t111
  %t113 = call i8* @malloc(i64 %t112)
  %t114 = bitcast i8* %t113 to i8**
  %t115 = icmp sgt i64 %t94, 0
  br i1 %t115, label %table_push_copy_22, label %table_push_after_copy_23
table_push_copy_22:
  %t116 = mul i64 %t95, %t111
  %t117 = bitcast i8** %t97 to i8*
  call i8* @memcpy(i8* %t113, i8* %t117, i64 %t116)
  call void @free(i8* %t117)
  br label %table_push_after_copy_23
table_push_after_copy_23:
  store i8** %t114, i8*** %t81
  store i64 %t101, i64* %t78
  br label %table_push_store_19
table_push_store_19:
  %t118 = load i32*, i32** %t79
  %t119 = extractvalue %Item %t93, 0
  %t120 = getelementptr inbounds i32, i32* %t118, i64 %t95
  store i32 %t119, i32* %t120
  %t121 = load i8**, i8*** %t81
  %t122 = extractvalue %Item %t93, 1
  %t123 = getelementptr inbounds i8*, i8** %t121, i64 %t95
  store i8* %t122, i8** %t123
  %t124 = add i64 %t95, 1
  store i64 %t124, i64* %t76
  %t125 = load i32, i32* %t1
  %t126 = add i32 %t125, 1
  store i32 %t126, i32* %t1
  br label %while_cond_0
while_else_2:
  br label %while_end_3
while_end_3:
  %t127 = load i8*, i8** %t0
  %t128 = icmp eq i8* %t127, null
  br i1 %t128, label %table_read_null_24, label %table_read_real_25
table_read_null_24:
  br label %table_read_end_26
table_read_real_25:
  %t129 = bitcast i8* %t127 to { i64, i64, i32*, i8** }*
  %t130 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t129, i32 0, i32 0
  %t131 = load i64, i64* %t130
  %t132 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t129, i32 0, i32 2
  %t133 = load i32*, i32** %t132
  %t134 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t129, i32 0, i32 3
  %t135 = load i8**, i8*** %t134
  br label %table_read_end_26
table_read_end_26:
  %t136 = phi i64 [ 0, %table_read_null_24 ], [ %t131, %table_read_real_25 ]
  %t137 = phi i32* [ null, %table_read_null_24 ], [ %t133, %table_read_real_25 ]
  %t138 = phi i8** [ null, %table_read_null_24 ], [ %t135, %table_read_real_25 ]
  %t139 = trunc i64 %t136 to i32
  %t140 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t140, i32 %t139)
  %t141 = sext i32 0 to i64
  %t142 = load i8*, i8** %t0
  %t143 = icmp eq i8* %t142, null
  br i1 %t143, label %table_read_null_27, label %table_read_real_28
table_read_null_27:
  br label %table_read_end_29
table_read_real_28:
  %t144 = bitcast i8* %t142 to { i64, i64, i32*, i8** }*
  %t145 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t144, i32 0, i32 0
  %t146 = load i64, i64* %t145
  %t147 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t144, i32 0, i32 2
  %t148 = load i32*, i32** %t147
  %t149 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t144, i32 0, i32 3
  %t150 = load i8**, i8*** %t149
  br label %table_read_end_29
table_read_end_29:
  %t151 = phi i64 [ 0, %table_read_null_27 ], [ %t146, %table_read_real_28 ]
  %t152 = phi i32* [ null, %table_read_null_27 ], [ %t148, %table_read_real_28 ]
  %t153 = phi i8** [ null, %table_read_null_27 ], [ %t150, %table_read_real_28 ]
  %t155 = icmp ult i64 %t141, %t151
  br i1 %t155, label %table_idx_ok_30, label %table_idx_oob_31
table_idx_ok_30:
  %t156 = getelementptr inbounds i32, i32* %t152, i64 %t141
  %t157 = load i32, i32* %t156
  %t158 = getelementptr inbounds %Item, %Item* %t154, i32 0, i32 0
  store i32 %t157, i32* %t158
  %t159 = getelementptr inbounds i8*, i8** %t153, i64 %t141
  %t160 = load i8*, i8** %t159
  call void @star_rc_retain(i8* %t160)
  %t161 = load i8*, i8** %t159
  %t162 = getelementptr inbounds %Item, %Item* %t154, i32 0, i32 1
  store i8* %t161, i8** %t162
  br label %table_idx_end_32
table_idx_oob_31:
  store %Item zeroinitializer, %Item* %t154
  br label %table_idx_end_32
table_idx_end_32:
  %t163 = load %Item, %Item* %t154
  store %Item %t163, %Item* %t164
  %t165 = getelementptr inbounds %Item, %Item* %t164, i32 0, i32 1
  %t166 = load i8*, i8** %t165
  %t167 = load i8*, i8** %t165
  call void @star_rc_retain(i8* %t167)
  call void @star_rc_release(i8* %t166)
  %t168 = sext i32 0 to i64
  %t169 = load i8*, i8** %t0
  %t170 = icmp eq i8* %t169, null
  br i1 %t170, label %table_read_null_33, label %table_read_real_34
table_read_null_33:
  br label %table_read_end_35
table_read_real_34:
  %t171 = bitcast i8* %t169 to { i64, i64, i32*, i8** }*
  %t172 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t171, i32 0, i32 0
  %t173 = load i64, i64* %t172
  %t174 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t171, i32 0, i32 2
  %t175 = load i32*, i32** %t174
  %t176 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t171, i32 0, i32 3
  %t177 = load i8**, i8*** %t176
  br label %table_read_end_35
table_read_end_35:
  %t178 = phi i64 [ 0, %table_read_null_33 ], [ %t173, %table_read_real_34 ]
  %t179 = phi i32* [ null, %table_read_null_33 ], [ %t175, %table_read_real_34 ]
  %t180 = phi i8** [ null, %table_read_null_33 ], [ %t177, %table_read_real_34 ]
  %t182 = icmp ult i64 %t168, %t178
  br i1 %t182, label %table_idx_ok_36, label %table_idx_oob_37
table_idx_ok_36:
  %t183 = getelementptr inbounds i32, i32* %t179, i64 %t168
  %t184 = load i32, i32* %t183
  %t185 = getelementptr inbounds %Item, %Item* %t181, i32 0, i32 0
  store i32 %t184, i32* %t185
  %t186 = getelementptr inbounds i8*, i8** %t180, i64 %t168
  %t187 = load i8*, i8** %t186
  call void @star_rc_retain(i8* %t187)
  %t188 = load i8*, i8** %t186
  %t189 = getelementptr inbounds %Item, %Item* %t181, i32 0, i32 1
  store i8* %t188, i8** %t189
  br label %table_idx_end_38
table_idx_oob_37:
  store %Item zeroinitializer, %Item* %t181
  br label %table_idx_end_38
table_idx_end_38:
  %t190 = load %Item, %Item* %t181
  store %Item %t190, %Item* %t191
  %t192 = getelementptr inbounds %Item, %Item* %t191, i32 0, i32 0
  %t193 = load i32, i32* %t192
  %t194 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t194, i8* %t166, i32 %t193)
  %t195 = sext i32 4999 to i64
  %t196 = load i8*, i8** %t0
  %t197 = icmp eq i8* %t196, null
  br i1 %t197, label %table_read_null_39, label %table_read_real_40
table_read_null_39:
  br label %table_read_end_41
table_read_real_40:
  %t198 = bitcast i8* %t196 to { i64, i64, i32*, i8** }*
  %t199 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t198, i32 0, i32 0
  %t200 = load i64, i64* %t199
  %t201 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t198, i32 0, i32 2
  %t202 = load i32*, i32** %t201
  %t203 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t198, i32 0, i32 3
  %t204 = load i8**, i8*** %t203
  br label %table_read_end_41
table_read_end_41:
  %t205 = phi i64 [ 0, %table_read_null_39 ], [ %t200, %table_read_real_40 ]
  %t206 = phi i32* [ null, %table_read_null_39 ], [ %t202, %table_read_real_40 ]
  %t207 = phi i8** [ null, %table_read_null_39 ], [ %t204, %table_read_real_40 ]
  %t209 = icmp ult i64 %t195, %t205
  br i1 %t209, label %table_idx_ok_42, label %table_idx_oob_43
table_idx_ok_42:
  %t210 = getelementptr inbounds i32, i32* %t206, i64 %t195
  %t211 = load i32, i32* %t210
  %t212 = getelementptr inbounds %Item, %Item* %t208, i32 0, i32 0
  store i32 %t211, i32* %t212
  %t213 = getelementptr inbounds i8*, i8** %t207, i64 %t195
  %t214 = load i8*, i8** %t213
  call void @star_rc_retain(i8* %t214)
  %t215 = load i8*, i8** %t213
  %t216 = getelementptr inbounds %Item, %Item* %t208, i32 0, i32 1
  store i8* %t215, i8** %t216
  br label %table_idx_end_44
table_idx_oob_43:
  store %Item zeroinitializer, %Item* %t208
  br label %table_idx_end_44
table_idx_end_44:
  %t217 = load %Item, %Item* %t208
  store %Item %t217, %Item* %t218
  %t219 = getelementptr inbounds %Item, %Item* %t218, i32 0, i32 1
  %t220 = load i8*, i8** %t219
  %t221 = load i8*, i8** %t219
  call void @star_rc_retain(i8* %t221)
  call void @star_rc_release(i8* %t220)
  %t222 = sext i32 4999 to i64
  %t223 = load i8*, i8** %t0
  %t224 = icmp eq i8* %t223, null
  br i1 %t224, label %table_read_null_45, label %table_read_real_46
table_read_null_45:
  br label %table_read_end_47
table_read_real_46:
  %t225 = bitcast i8* %t223 to { i64, i64, i32*, i8** }*
  %t226 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t225, i32 0, i32 0
  %t227 = load i64, i64* %t226
  %t228 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t225, i32 0, i32 2
  %t229 = load i32*, i32** %t228
  %t230 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t225, i32 0, i32 3
  %t231 = load i8**, i8*** %t230
  br label %table_read_end_47
table_read_end_47:
  %t232 = phi i64 [ 0, %table_read_null_45 ], [ %t227, %table_read_real_46 ]
  %t233 = phi i32* [ null, %table_read_null_45 ], [ %t229, %table_read_real_46 ]
  %t234 = phi i8** [ null, %table_read_null_45 ], [ %t231, %table_read_real_46 ]
  %t236 = icmp ult i64 %t222, %t232
  br i1 %t236, label %table_idx_ok_48, label %table_idx_oob_49
table_idx_ok_48:
  %t237 = getelementptr inbounds i32, i32* %t233, i64 %t222
  %t238 = load i32, i32* %t237
  %t239 = getelementptr inbounds %Item, %Item* %t235, i32 0, i32 0
  store i32 %t238, i32* %t239
  %t240 = getelementptr inbounds i8*, i8** %t234, i64 %t222
  %t241 = load i8*, i8** %t240
  call void @star_rc_retain(i8* %t241)
  %t242 = load i8*, i8** %t240
  %t243 = getelementptr inbounds %Item, %Item* %t235, i32 0, i32 1
  store i8* %t242, i8** %t243
  br label %table_idx_end_50
table_idx_oob_49:
  store %Item zeroinitializer, %Item* %t235
  br label %table_idx_end_50
table_idx_end_50:
  %t244 = load %Item, %Item* %t235
  store %Item %t244, %Item* %t245
  %t246 = getelementptr inbounds %Item, %Item* %t245, i32 0, i32 0
  %t247 = load i32, i32* %t246
  %t248 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t248, i8* %t220, i32 %t247)
  %t250 = load i8*, i8** %t0
  %t251 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t251)
  store i8* %t250, i8** %t249
  store i32 0, i32* %t252
  br label %while_cond_51
while_cond_51:
  %t253 = load i32, i32* %t252
  %t254 = icmp slt i32 %t253, 5000
  br i1 %t254, label %while_body_52, label %while_else_53
while_body_52:
  %t255 = load i8*, i8** %t249
  %t256 = icmp eq i8* %t255, null
  br i1 %t256, label %table_cow_alloc_55, label %table_cow_check_56
table_cow_alloc_55:
  %t257 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t258 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t259 = ptrtoint { i64, i64, i32*, i8** }* %t258 to i64
  %t260 = call i8* @star_rc_alloc(i64 %t259, i8* %t257)
  %t261 = bitcast i8* %t260 to { i64, i64, i32*, i8** }*
  %t262 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t261, i32 0, i32 0
  store i64 0, i64* %t262
  %t263 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t261, i32 0, i32 1
  store i64 0, i64* %t263
  %t264 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t261, i32 0, i32 2
  store i32* null, i32** %t264
  %t265 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t261, i32 0, i32 3
  store i8** null, i8*** %t265
  store i8* %t260, i8** %t249
  br label %table_cow_done_57
table_cow_check_56:
  %t266 = getelementptr inbounds i8, i8* %t255, i64 -16
  %t267 = bitcast i8* %t266 to i64*
  %t268 = load atomic i64, i64* %t267 seq_cst, align 8
  %t269 = icmp eq i64 %t268, 1
  br i1 %t269, label %table_cow_done_57, label %table_cow_clone_58
table_cow_clone_58:
  %t270 = bitcast i8* %t255 to { i64, i64, i32*, i8** }*
  %t271 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t270, i32 0, i32 0
  %t272 = load i64, i64* %t271
  %t273 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t270, i32 0, i32 1
  %t274 = load i64, i64* %t273
  %t275 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t276 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t277 = ptrtoint { i64, i64, i32*, i8** }* %t276 to i64
  %t278 = call i8* @star_rc_alloc(i64 %t277, i8* %t275)
  %t279 = bitcast i8* %t278 to { i64, i64, i32*, i8** }*
  %t280 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t279, i32 0, i32 0
  store i64 %t272, i64* %t280
  %t281 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t279, i32 0, i32 1
  store i64 %t274, i64* %t281
  %t282 = getelementptr i32, i32* null, i32 1
  %t283 = ptrtoint i32* %t282 to i64
  %t284 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t270, i32 0, i32 2
  %t285 = load i32*, i32** %t284
  %t286 = mul i64 %t274, %t283
  %t287 = call i8* @malloc(i64 %t286)
  %t288 = bitcast i8* %t287 to i32*
  %t289 = icmp sgt i64 %t272, 0
  br i1 %t289, label %table_cow_copy_59, label %table_cow_after_copy_60
table_cow_copy_59:
  %t290 = mul i64 %t272, %t283
  %t291 = bitcast i32* %t285 to i8*
  call i8* @memcpy(i8* %t287, i8* %t291, i64 %t290)
  br label %table_cow_after_copy_60
table_cow_after_copy_60:
  %t292 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t279, i32 0, i32 2
  store i32* %t288, i32** %t292
  %t293 = getelementptr i8*, i8** null, i32 1
  %t294 = ptrtoint i8** %t293 to i64
  %t295 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t270, i32 0, i32 3
  %t296 = load i8**, i8*** %t295
  %t297 = mul i64 %t274, %t294
  %t298 = call i8* @malloc(i64 %t297)
  %t299 = bitcast i8* %t298 to i8**
  %t300 = icmp sgt i64 %t272, 0
  br i1 %t300, label %table_cow_copy_61, label %table_cow_after_copy_62
table_cow_copy_61:
  %t301 = mul i64 %t272, %t294
  %t302 = bitcast i8** %t296 to i8*
  call i8* @memcpy(i8* %t298, i8* %t302, i64 %t301)
  store i64 0, i64* %t303
  br label %table_cow_retain_cond_63
table_cow_retain_cond_63:
  %t304 = load i64, i64* %t303
  %t305 = icmp slt i64 %t304, %t272
  br i1 %t305, label %table_cow_retain_body_64, label %table_cow_retain_end_65
table_cow_retain_body_64:
  %t306 = getelementptr inbounds i8*, i8** %t299, i64 %t304
  %t307 = load i8*, i8** %t306
  call void @star_rc_retain(i8* %t307)
  %t308 = add i64 %t304, 1
  store i64 %t308, i64* %t303
  br label %table_cow_retain_cond_63
table_cow_retain_end_65:
  br label %table_cow_after_copy_62
table_cow_after_copy_62:
  %t309 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t279, i32 0, i32 3
  store i8** %t299, i8*** %t309
  call void @star_rc_release(i8* %t255)
  store i8* %t278, i8** %t249
  br label %table_cow_done_57
table_cow_done_57:
  %t310 = load i8*, i8** %t249
  %t311 = bitcast i8* %t310 to { i64, i64, i32*, i8** }*
  %t312 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t311, i32 0, i32 0
  %t313 = load i64, i64* %t312
  %t314 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t311, i32 0, i32 1
  %t315 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t311, i32 0, i32 2
  %t316 = load i32*, i32** %t315
  %t317 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t311, i32 0, i32 3
  %t318 = load i8**, i8*** %t317
  %t320 = load i32, i32* %t252
  %t321 = getelementptr inbounds %Item, %Item* %t319, i32 0, i32 0
  store i32 %t320, i32* %t321
  %t322 = load i32, i32* %t252
  %t323 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.4, i64 0, i64 0
  %t324 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t323, i32 %t322)
  %t325 = add i32 %t324, 1
  %t326 = sext i32 %t325 to i64
  %t327 = call i8* @star_rc_alloc(i64 %t326, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t327, i64 %t326, i8* %t323, i32 %t322)
  %t328 = getelementptr inbounds %Item, %Item* %t319, i32 0, i32 1
  store i8* %t327, i8** %t328
  %t329 = load %Item, %Item* %t319
  %t330 = load i64, i64* %t314
  %t331 = load i64, i64* %t312
  %t332 = load i32*, i32** %t315
  %t333 = load i8**, i8*** %t317
  %t334 = icmp sge i64 %t331, %t330
  br i1 %t334, label %table_push_grow_66, label %table_push_store_67
table_push_grow_66:
  %t335 = mul i64 %t330, 2
  %t336 = icmp sgt i64 %t335, 0
  %t337 = select i1 %t336, i64 %t335, i64 1
  %t338 = getelementptr i32, i32* null, i32 1
  %t339 = ptrtoint i32* %t338 to i64
  %t340 = mul i64 %t337, %t339
  %t341 = call i8* @malloc(i64 %t340)
  %t342 = bitcast i8* %t341 to i32*
  %t343 = icmp sgt i64 %t330, 0
  br i1 %t343, label %table_push_copy_68, label %table_push_after_copy_69
table_push_copy_68:
  %t344 = mul i64 %t331, %t339
  %t345 = bitcast i32* %t332 to i8*
  call i8* @memcpy(i8* %t341, i8* %t345, i64 %t344)
  call void @free(i8* %t345)
  br label %table_push_after_copy_69
table_push_after_copy_69:
  store i32* %t342, i32** %t315
  %t346 = getelementptr i8*, i8** null, i32 1
  %t347 = ptrtoint i8** %t346 to i64
  %t348 = mul i64 %t337, %t347
  %t349 = call i8* @malloc(i64 %t348)
  %t350 = bitcast i8* %t349 to i8**
  %t351 = icmp sgt i64 %t330, 0
  br i1 %t351, label %table_push_copy_70, label %table_push_after_copy_71
table_push_copy_70:
  %t352 = mul i64 %t331, %t347
  %t353 = bitcast i8** %t333 to i8*
  call i8* @memcpy(i8* %t349, i8* %t353, i64 %t352)
  call void @free(i8* %t353)
  br label %table_push_after_copy_71
table_push_after_copy_71:
  store i8** %t350, i8*** %t317
  store i64 %t337, i64* %t314
  br label %table_push_store_67
table_push_store_67:
  %t354 = load i32*, i32** %t315
  %t355 = extractvalue %Item %t329, 0
  %t356 = getelementptr inbounds i32, i32* %t354, i64 %t331
  store i32 %t355, i32* %t356
  %t357 = load i8**, i8*** %t317
  %t358 = extractvalue %Item %t329, 1
  %t359 = getelementptr inbounds i8*, i8** %t357, i64 %t331
  store i8* %t358, i8** %t359
  %t360 = add i64 %t331, 1
  store i64 %t360, i64* %t312
  %t361 = load i32, i32* %t252
  %t362 = add i32 %t361, 1
  store i32 %t362, i32* %t252
  br label %while_cond_51
while_else_53:
  br label %while_end_54
while_end_54:
  %t363 = load i8*, i8** %t0
  %t364 = icmp eq i8* %t363, null
  br i1 %t364, label %table_read_null_72, label %table_read_real_73
table_read_null_72:
  br label %table_read_end_74
table_read_real_73:
  %t365 = bitcast i8* %t363 to { i64, i64, i32*, i8** }*
  %t366 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t365, i32 0, i32 0
  %t367 = load i64, i64* %t366
  %t368 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t365, i32 0, i32 2
  %t369 = load i32*, i32** %t368
  %t370 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t365, i32 0, i32 3
  %t371 = load i8**, i8*** %t370
  br label %table_read_end_74
table_read_end_74:
  %t372 = phi i64 [ 0, %table_read_null_72 ], [ %t367, %table_read_real_73 ]
  %t373 = phi i32* [ null, %table_read_null_72 ], [ %t369, %table_read_real_73 ]
  %t374 = phi i8** [ null, %table_read_null_72 ], [ %t371, %table_read_real_73 ]
  %t375 = trunc i64 %t372 to i32
  %t376 = load i8*, i8** %t249
  %t377 = icmp eq i8* %t376, null
  br i1 %t377, label %table_read_null_75, label %table_read_real_76
table_read_null_75:
  br label %table_read_end_77
table_read_real_76:
  %t378 = bitcast i8* %t376 to { i64, i64, i32*, i8** }*
  %t379 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t378, i32 0, i32 0
  %t380 = load i64, i64* %t379
  %t381 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t378, i32 0, i32 2
  %t382 = load i32*, i32** %t381
  %t383 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t378, i32 0, i32 3
  %t384 = load i8**, i8*** %t383
  br label %table_read_end_77
table_read_end_77:
  %t385 = phi i64 [ 0, %table_read_null_75 ], [ %t380, %table_read_real_76 ]
  %t386 = phi i32* [ null, %table_read_null_75 ], [ %t382, %table_read_real_76 ]
  %t387 = phi i8** [ null, %table_read_null_75 ], [ %t384, %table_read_real_76 ]
  %t388 = trunc i64 %t385 to i32
  %t389 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t389, i32 %t375, i32 %t388)
  %t390 = sext i32 0 to i64
  %t391 = load i8*, i8** %t0
  %t392 = icmp eq i8* %t391, null
  br i1 %t392, label %table_read_null_78, label %table_read_real_79
table_read_null_78:
  br label %table_read_end_80
table_read_real_79:
  %t393 = bitcast i8* %t391 to { i64, i64, i32*, i8** }*
  %t394 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t393, i32 0, i32 0
  %t395 = load i64, i64* %t394
  %t396 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t393, i32 0, i32 2
  %t397 = load i32*, i32** %t396
  %t398 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t393, i32 0, i32 3
  %t399 = load i8**, i8*** %t398
  br label %table_read_end_80
table_read_end_80:
  %t400 = phi i64 [ 0, %table_read_null_78 ], [ %t395, %table_read_real_79 ]
  %t401 = phi i32* [ null, %table_read_null_78 ], [ %t397, %table_read_real_79 ]
  %t402 = phi i8** [ null, %table_read_null_78 ], [ %t399, %table_read_real_79 ]
  %t404 = icmp ult i64 %t390, %t400
  br i1 %t404, label %table_idx_ok_81, label %table_idx_oob_82
table_idx_ok_81:
  %t405 = getelementptr inbounds i32, i32* %t401, i64 %t390
  %t406 = load i32, i32* %t405
  %t407 = getelementptr inbounds %Item, %Item* %t403, i32 0, i32 0
  store i32 %t406, i32* %t407
  %t408 = getelementptr inbounds i8*, i8** %t402, i64 %t390
  %t409 = load i8*, i8** %t408
  call void @star_rc_retain(i8* %t409)
  %t410 = load i8*, i8** %t408
  %t411 = getelementptr inbounds %Item, %Item* %t403, i32 0, i32 1
  store i8* %t410, i8** %t411
  br label %table_idx_end_83
table_idx_oob_82:
  store %Item zeroinitializer, %Item* %t403
  br label %table_idx_end_83
table_idx_end_83:
  %t412 = load %Item, %Item* %t403
  store %Item %t412, %Item* %t413
  %t414 = getelementptr inbounds %Item, %Item* %t413, i32 0, i32 1
  %t415 = load i8*, i8** %t414
  %t416 = load i8*, i8** %t414
  call void @star_rc_retain(i8* %t416)
  call void @star_rc_release(i8* %t415)
  %t417 = sext i32 0 to i64
  %t418 = load i8*, i8** %t249
  %t419 = icmp eq i8* %t418, null
  br i1 %t419, label %table_read_null_84, label %table_read_real_85
table_read_null_84:
  br label %table_read_end_86
table_read_real_85:
  %t420 = bitcast i8* %t418 to { i64, i64, i32*, i8** }*
  %t421 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t420, i32 0, i32 0
  %t422 = load i64, i64* %t421
  %t423 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t420, i32 0, i32 2
  %t424 = load i32*, i32** %t423
  %t425 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t420, i32 0, i32 3
  %t426 = load i8**, i8*** %t425
  br label %table_read_end_86
table_read_end_86:
  %t427 = phi i64 [ 0, %table_read_null_84 ], [ %t422, %table_read_real_85 ]
  %t428 = phi i32* [ null, %table_read_null_84 ], [ %t424, %table_read_real_85 ]
  %t429 = phi i8** [ null, %table_read_null_84 ], [ %t426, %table_read_real_85 ]
  %t431 = icmp ult i64 %t417, %t427
  br i1 %t431, label %table_idx_ok_87, label %table_idx_oob_88
table_idx_ok_87:
  %t432 = getelementptr inbounds i32, i32* %t428, i64 %t417
  %t433 = load i32, i32* %t432
  %t434 = getelementptr inbounds %Item, %Item* %t430, i32 0, i32 0
  store i32 %t433, i32* %t434
  %t435 = getelementptr inbounds i8*, i8** %t429, i64 %t417
  %t436 = load i8*, i8** %t435
  call void @star_rc_retain(i8* %t436)
  %t437 = load i8*, i8** %t435
  %t438 = getelementptr inbounds %Item, %Item* %t430, i32 0, i32 1
  store i8* %t437, i8** %t438
  br label %table_idx_end_89
table_idx_oob_88:
  store %Item zeroinitializer, %Item* %t430
  br label %table_idx_end_89
table_idx_end_89:
  %t439 = load %Item, %Item* %t430
  store %Item %t439, %Item* %t440
  %t441 = getelementptr inbounds %Item, %Item* %t440, i32 0, i32 1
  %t442 = load i8*, i8** %t441
  %t443 = load i8*, i8** %t441
  call void @star_rc_retain(i8* %t443)
  call void @star_rc_release(i8* %t442)
  %t444 = getelementptr inbounds [32 x i8], [32 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t444, i8* %t415, i8* %t442)
  %t445 = sext i32 4999 to i64
  %t446 = load i8*, i8** %t0
  %t447 = icmp eq i8* %t446, null
  br i1 %t447, label %table_read_null_90, label %table_read_real_91
table_read_null_90:
  br label %table_read_end_92
table_read_real_91:
  %t448 = bitcast i8* %t446 to { i64, i64, i32*, i8** }*
  %t449 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t448, i32 0, i32 0
  %t450 = load i64, i64* %t449
  %t451 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t448, i32 0, i32 2
  %t452 = load i32*, i32** %t451
  %t453 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t448, i32 0, i32 3
  %t454 = load i8**, i8*** %t453
  br label %table_read_end_92
table_read_end_92:
  %t455 = phi i64 [ 0, %table_read_null_90 ], [ %t450, %table_read_real_91 ]
  %t456 = phi i32* [ null, %table_read_null_90 ], [ %t452, %table_read_real_91 ]
  %t457 = phi i8** [ null, %table_read_null_90 ], [ %t454, %table_read_real_91 ]
  %t459 = icmp ult i64 %t445, %t455
  br i1 %t459, label %table_idx_ok_93, label %table_idx_oob_94
table_idx_ok_93:
  %t460 = getelementptr inbounds i32, i32* %t456, i64 %t445
  %t461 = load i32, i32* %t460
  %t462 = getelementptr inbounds %Item, %Item* %t458, i32 0, i32 0
  store i32 %t461, i32* %t462
  %t463 = getelementptr inbounds i8*, i8** %t457, i64 %t445
  %t464 = load i8*, i8** %t463
  call void @star_rc_retain(i8* %t464)
  %t465 = load i8*, i8** %t463
  %t466 = getelementptr inbounds %Item, %Item* %t458, i32 0, i32 1
  store i8* %t465, i8** %t466
  br label %table_idx_end_95
table_idx_oob_94:
  store %Item zeroinitializer, %Item* %t458
  br label %table_idx_end_95
table_idx_end_95:
  %t467 = load %Item, %Item* %t458
  store %Item %t467, %Item* %t468
  %t469 = getelementptr inbounds %Item, %Item* %t468, i32 0, i32 1
  %t470 = load i8*, i8** %t469
  %t471 = load i8*, i8** %t469
  call void @star_rc_retain(i8* %t471)
  call void @star_rc_release(i8* %t470)
  %t472 = sext i32 4999 to i64
  %t473 = load i8*, i8** %t249
  %t474 = icmp eq i8* %t473, null
  br i1 %t474, label %table_read_null_96, label %table_read_real_97
table_read_null_96:
  br label %table_read_end_98
table_read_real_97:
  %t475 = bitcast i8* %t473 to { i64, i64, i32*, i8** }*
  %t476 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t475, i32 0, i32 0
  %t477 = load i64, i64* %t476
  %t478 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t475, i32 0, i32 2
  %t479 = load i32*, i32** %t478
  %t480 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t475, i32 0, i32 3
  %t481 = load i8**, i8*** %t480
  br label %table_read_end_98
table_read_end_98:
  %t482 = phi i64 [ 0, %table_read_null_96 ], [ %t477, %table_read_real_97 ]
  %t483 = phi i32* [ null, %table_read_null_96 ], [ %t479, %table_read_real_97 ]
  %t484 = phi i8** [ null, %table_read_null_96 ], [ %t481, %table_read_real_97 ]
  %t486 = icmp ult i64 %t472, %t482
  br i1 %t486, label %table_idx_ok_99, label %table_idx_oob_100
table_idx_ok_99:
  %t487 = getelementptr inbounds i32, i32* %t483, i64 %t472
  %t488 = load i32, i32* %t487
  %t489 = getelementptr inbounds %Item, %Item* %t485, i32 0, i32 0
  store i32 %t488, i32* %t489
  %t490 = getelementptr inbounds i8*, i8** %t484, i64 %t472
  %t491 = load i8*, i8** %t490
  call void @star_rc_retain(i8* %t491)
  %t492 = load i8*, i8** %t490
  %t493 = getelementptr inbounds %Item, %Item* %t485, i32 0, i32 1
  store i8* %t492, i8** %t493
  br label %table_idx_end_101
table_idx_oob_100:
  store %Item zeroinitializer, %Item* %t485
  br label %table_idx_end_101
table_idx_end_101:
  %t494 = load %Item, %Item* %t485
  store %Item %t494, %Item* %t495
  %t496 = getelementptr inbounds %Item, %Item* %t495, i32 0, i32 1
  %t497 = load i8*, i8** %t496
  %t498 = load i8*, i8** %t496
  call void @star_rc_retain(i8* %t498)
  call void @star_rc_release(i8* %t497)
  %t499 = getelementptr inbounds [38 x i8], [38 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t499, i8* %t470, i8* %t497)
  store i8* null, i8** %t500
  store i32 0, i32* %t501
  br label %while_cond_102
while_cond_102:
  %t502 = load i32, i32* %t501
  %t503 = icmp slt i32 %t502, 3000
  br i1 %t503, label %while_body_103, label %while_else_104
while_body_103:
  %t504 = load i8*, i8** %t500
  %t505 = icmp eq i8* %t504, null
  br i1 %t505, label %table_cow_alloc_106, label %table_cow_check_107
table_cow_alloc_106:
  %t506 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t507 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t508 = ptrtoint { i64, i64, i32*, i8** }* %t507 to i64
  %t509 = call i8* @star_rc_alloc(i64 %t508, i8* %t506)
  %t510 = bitcast i8* %t509 to { i64, i64, i32*, i8** }*
  %t511 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t510, i32 0, i32 0
  store i64 0, i64* %t511
  %t512 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t510, i32 0, i32 1
  store i64 0, i64* %t512
  %t513 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t510, i32 0, i32 2
  store i32* null, i32** %t513
  %t514 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t510, i32 0, i32 3
  store i8** null, i8*** %t514
  store i8* %t509, i8** %t500
  br label %table_cow_done_108
table_cow_check_107:
  %t515 = getelementptr inbounds i8, i8* %t504, i64 -16
  %t516 = bitcast i8* %t515 to i64*
  %t517 = load atomic i64, i64* %t516 seq_cst, align 8
  %t518 = icmp eq i64 %t517, 1
  br i1 %t518, label %table_cow_done_108, label %table_cow_clone_109
table_cow_clone_109:
  %t519 = bitcast i8* %t504 to { i64, i64, i32*, i8** }*
  %t520 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t519, i32 0, i32 0
  %t521 = load i64, i64* %t520
  %t522 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t519, i32 0, i32 1
  %t523 = load i64, i64* %t522
  %t524 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t525 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t526 = ptrtoint { i64, i64, i32*, i8** }* %t525 to i64
  %t527 = call i8* @star_rc_alloc(i64 %t526, i8* %t524)
  %t528 = bitcast i8* %t527 to { i64, i64, i32*, i8** }*
  %t529 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t528, i32 0, i32 0
  store i64 %t521, i64* %t529
  %t530 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t528, i32 0, i32 1
  store i64 %t523, i64* %t530
  %t531 = getelementptr i32, i32* null, i32 1
  %t532 = ptrtoint i32* %t531 to i64
  %t533 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t519, i32 0, i32 2
  %t534 = load i32*, i32** %t533
  %t535 = mul i64 %t523, %t532
  %t536 = call i8* @malloc(i64 %t535)
  %t537 = bitcast i8* %t536 to i32*
  %t538 = icmp sgt i64 %t521, 0
  br i1 %t538, label %table_cow_copy_110, label %table_cow_after_copy_111
table_cow_copy_110:
  %t539 = mul i64 %t521, %t532
  %t540 = bitcast i32* %t534 to i8*
  call i8* @memcpy(i8* %t536, i8* %t540, i64 %t539)
  br label %table_cow_after_copy_111
table_cow_after_copy_111:
  %t541 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t528, i32 0, i32 2
  store i32* %t537, i32** %t541
  %t542 = getelementptr i8*, i8** null, i32 1
  %t543 = ptrtoint i8** %t542 to i64
  %t544 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t519, i32 0, i32 3
  %t545 = load i8**, i8*** %t544
  %t546 = mul i64 %t523, %t543
  %t547 = call i8* @malloc(i64 %t546)
  %t548 = bitcast i8* %t547 to i8**
  %t549 = icmp sgt i64 %t521, 0
  br i1 %t549, label %table_cow_copy_112, label %table_cow_after_copy_113
table_cow_copy_112:
  %t550 = mul i64 %t521, %t543
  %t551 = bitcast i8** %t545 to i8*
  call i8* @memcpy(i8* %t547, i8* %t551, i64 %t550)
  store i64 0, i64* %t552
  br label %table_cow_retain_cond_114
table_cow_retain_cond_114:
  %t553 = load i64, i64* %t552
  %t554 = icmp slt i64 %t553, %t521
  br i1 %t554, label %table_cow_retain_body_115, label %table_cow_retain_end_116
table_cow_retain_body_115:
  %t555 = getelementptr inbounds i8*, i8** %t548, i64 %t553
  %t556 = load i8*, i8** %t555
  call void @star_rc_retain(i8* %t556)
  %t557 = add i64 %t553, 1
  store i64 %t557, i64* %t552
  br label %table_cow_retain_cond_114
table_cow_retain_end_116:
  br label %table_cow_after_copy_113
table_cow_after_copy_113:
  %t558 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t528, i32 0, i32 3
  store i8** %t548, i8*** %t558
  call void @star_rc_release(i8* %t504)
  store i8* %t527, i8** %t500
  br label %table_cow_done_108
table_cow_done_108:
  %t559 = load i8*, i8** %t500
  %t560 = bitcast i8* %t559 to { i64, i64, i32*, i8** }*
  %t561 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t560, i32 0, i32 0
  %t562 = load i64, i64* %t561
  %t563 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t560, i32 0, i32 1
  %t564 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t560, i32 0, i32 2
  %t565 = load i32*, i32** %t564
  %t566 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t560, i32 0, i32 3
  %t567 = load i8**, i8*** %t566
  %t569 = load i32, i32* %t501
  %t570 = getelementptr inbounds %Item, %Item* %t568, i32 0, i32 0
  store i32 %t569, i32* %t570
  %t571 = load i32, i32* %t501
  %t572 = getelementptr inbounds [7 x i8], [7 x i8]* @.str.8, i64 0, i64 0
  %t573 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t572, i32 %t571)
  %t574 = add i32 %t573, 1
  %t575 = sext i32 %t574 to i64
  %t576 = call i8* @star_rc_alloc(i64 %t575, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t576, i64 %t575, i8* %t572, i32 %t571)
  %t577 = getelementptr inbounds %Item, %Item* %t568, i32 0, i32 1
  store i8* %t576, i8** %t577
  %t578 = load %Item, %Item* %t568
  %t579 = load i64, i64* %t563
  %t580 = load i64, i64* %t561
  %t581 = load i32*, i32** %t564
  %t582 = load i8**, i8*** %t566
  %t583 = icmp sge i64 %t580, %t579
  br i1 %t583, label %table_push_grow_117, label %table_push_store_118
table_push_grow_117:
  %t584 = mul i64 %t579, 2
  %t585 = icmp sgt i64 %t584, 0
  %t586 = select i1 %t585, i64 %t584, i64 1
  %t587 = getelementptr i32, i32* null, i32 1
  %t588 = ptrtoint i32* %t587 to i64
  %t589 = mul i64 %t586, %t588
  %t590 = call i8* @malloc(i64 %t589)
  %t591 = bitcast i8* %t590 to i32*
  %t592 = icmp sgt i64 %t579, 0
  br i1 %t592, label %table_push_copy_119, label %table_push_after_copy_120
table_push_copy_119:
  %t593 = mul i64 %t580, %t588
  %t594 = bitcast i32* %t581 to i8*
  call i8* @memcpy(i8* %t590, i8* %t594, i64 %t593)
  call void @free(i8* %t594)
  br label %table_push_after_copy_120
table_push_after_copy_120:
  store i32* %t591, i32** %t564
  %t595 = getelementptr i8*, i8** null, i32 1
  %t596 = ptrtoint i8** %t595 to i64
  %t597 = mul i64 %t586, %t596
  %t598 = call i8* @malloc(i64 %t597)
  %t599 = bitcast i8* %t598 to i8**
  %t600 = icmp sgt i64 %t579, 0
  br i1 %t600, label %table_push_copy_121, label %table_push_after_copy_122
table_push_copy_121:
  %t601 = mul i64 %t580, %t596
  %t602 = bitcast i8** %t582 to i8*
  call i8* @memcpy(i8* %t598, i8* %t602, i64 %t601)
  call void @free(i8* %t602)
  br label %table_push_after_copy_122
table_push_after_copy_122:
  store i8** %t599, i8*** %t566
  store i64 %t586, i64* %t563
  br label %table_push_store_118
table_push_store_118:
  %t603 = load i32*, i32** %t564
  %t604 = extractvalue %Item %t578, 0
  %t605 = getelementptr inbounds i32, i32* %t603, i64 %t580
  store i32 %t604, i32* %t605
  %t606 = load i8**, i8*** %t566
  %t607 = extractvalue %Item %t578, 1
  %t608 = getelementptr inbounds i8*, i8** %t606, i64 %t580
  store i8* %t607, i8** %t608
  %t609 = add i64 %t580, 1
  store i64 %t609, i64* %t561
  %t610 = load i32, i32* %t501
  %t611 = icmp eq i32 3, 0
  %t612 = icmp eq i32 %t610, -2147483648
  %t613 = icmp eq i32 3, -1
  %t614 = and i1 %t612, %t613
  %t615 = or i1 %t611, %t614
  br i1 %t615, label %int_div_fail_123, label %int_div_ok_124
int_div_fail_123:
  %t616 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.9, i64 0, i64 0
  call i32 @puts(i8* %t616)
  call void @exit(i32 1)
  unreachable
int_div_ok_124:
  %t617 = srem i32 %t610, 3
  %t618 = icmp eq i32 %t617, 0
  br i1 %t618, label %if_then_125, label %if_else_126
if_then_125:
  %t620 = load i8*, i8** %t500
  %t621 = icmp eq i8* %t620, null
  br i1 %t621, label %table_cow_alloc_128, label %table_cow_check_129
table_cow_alloc_128:
  %t622 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t623 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t624 = ptrtoint { i64, i64, i32*, i8** }* %t623 to i64
  %t625 = call i8* @star_rc_alloc(i64 %t624, i8* %t622)
  %t626 = bitcast i8* %t625 to { i64, i64, i32*, i8** }*
  %t627 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t626, i32 0, i32 0
  store i64 0, i64* %t627
  %t628 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t626, i32 0, i32 1
  store i64 0, i64* %t628
  %t629 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t626, i32 0, i32 2
  store i32* null, i32** %t629
  %t630 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t626, i32 0, i32 3
  store i8** null, i8*** %t630
  store i8* %t625, i8** %t500
  br label %table_cow_done_130
table_cow_check_129:
  %t631 = getelementptr inbounds i8, i8* %t620, i64 -16
  %t632 = bitcast i8* %t631 to i64*
  %t633 = load atomic i64, i64* %t632 seq_cst, align 8
  %t634 = icmp eq i64 %t633, 1
  br i1 %t634, label %table_cow_done_130, label %table_cow_clone_131
table_cow_clone_131:
  %t635 = bitcast i8* %t620 to { i64, i64, i32*, i8** }*
  %t636 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t635, i32 0, i32 0
  %t637 = load i64, i64* %t636
  %t638 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t635, i32 0, i32 1
  %t639 = load i64, i64* %t638
  %t640 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t641 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t642 = ptrtoint { i64, i64, i32*, i8** }* %t641 to i64
  %t643 = call i8* @star_rc_alloc(i64 %t642, i8* %t640)
  %t644 = bitcast i8* %t643 to { i64, i64, i32*, i8** }*
  %t645 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t644, i32 0, i32 0
  store i64 %t637, i64* %t645
  %t646 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t644, i32 0, i32 1
  store i64 %t639, i64* %t646
  %t647 = getelementptr i32, i32* null, i32 1
  %t648 = ptrtoint i32* %t647 to i64
  %t649 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t635, i32 0, i32 2
  %t650 = load i32*, i32** %t649
  %t651 = mul i64 %t639, %t648
  %t652 = call i8* @malloc(i64 %t651)
  %t653 = bitcast i8* %t652 to i32*
  %t654 = icmp sgt i64 %t637, 0
  br i1 %t654, label %table_cow_copy_132, label %table_cow_after_copy_133
table_cow_copy_132:
  %t655 = mul i64 %t637, %t648
  %t656 = bitcast i32* %t650 to i8*
  call i8* @memcpy(i8* %t652, i8* %t656, i64 %t655)
  br label %table_cow_after_copy_133
table_cow_after_copy_133:
  %t657 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t644, i32 0, i32 2
  store i32* %t653, i32** %t657
  %t658 = getelementptr i8*, i8** null, i32 1
  %t659 = ptrtoint i8** %t658 to i64
  %t660 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t635, i32 0, i32 3
  %t661 = load i8**, i8*** %t660
  %t662 = mul i64 %t639, %t659
  %t663 = call i8* @malloc(i64 %t662)
  %t664 = bitcast i8* %t663 to i8**
  %t665 = icmp sgt i64 %t637, 0
  br i1 %t665, label %table_cow_copy_134, label %table_cow_after_copy_135
table_cow_copy_134:
  %t666 = mul i64 %t637, %t659
  %t667 = bitcast i8** %t661 to i8*
  call i8* @memcpy(i8* %t663, i8* %t667, i64 %t666)
  store i64 0, i64* %t668
  br label %table_cow_retain_cond_136
table_cow_retain_cond_136:
  %t669 = load i64, i64* %t668
  %t670 = icmp slt i64 %t669, %t637
  br i1 %t670, label %table_cow_retain_body_137, label %table_cow_retain_end_138
table_cow_retain_body_137:
  %t671 = getelementptr inbounds i8*, i8** %t664, i64 %t669
  %t672 = load i8*, i8** %t671
  call void @star_rc_retain(i8* %t672)
  %t673 = add i64 %t669, 1
  store i64 %t673, i64* %t668
  br label %table_cow_retain_cond_136
table_cow_retain_end_138:
  br label %table_cow_after_copy_135
table_cow_after_copy_135:
  %t674 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t644, i32 0, i32 3
  store i8** %t664, i8*** %t674
  call void @star_rc_release(i8* %t620)
  store i8* %t643, i8** %t500
  br label %table_cow_done_130
table_cow_done_130:
  %t675 = load i8*, i8** %t500
  %t676 = bitcast i8* %t675 to { i64, i64, i32*, i8** }*
  %t677 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t676, i32 0, i32 0
  %t678 = load i64, i64* %t677
  %t679 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t676, i32 0, i32 1
  %t680 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t676, i32 0, i32 2
  %t681 = load i32*, i32** %t680
  %t682 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t676, i32 0, i32 3
  %t683 = load i8**, i8*** %t682
  %t685 = icmp eq i64 %t678, 0
  br i1 %t685, label %table_pop_empty_139, label %table_pop_nonempty_140
table_pop_nonempty_140:
  %t686 = sub i64 %t678, 1
  store i64 %t686, i64* %t677
  %t687 = getelementptr inbounds i32, i32* %t681, i64 %t686
  %t688 = load i32, i32* %t687
  %t689 = getelementptr inbounds %Item, %Item* %t684, i32 0, i32 0
  store i32 %t688, i32* %t689
  %t690 = getelementptr inbounds i8*, i8** %t683, i64 %t686
  %t691 = load i8*, i8** %t690
  %t692 = getelementptr inbounds %Item, %Item* %t684, i32 0, i32 1
  store i8* %t691, i8** %t692
  br label %table_pop_end_141
table_pop_empty_139:
  store %Item zeroinitializer, %Item* %t684
  br label %table_pop_end_141
table_pop_end_141:
  %t693 = load %Item, %Item* %t684
  store %Item %t693, %Item* %t619
  %t694 = getelementptr inbounds %Item, %Item* %t619, i32 0, i32 1
  %t695 = load i8*, i8** %t694
  %t696 = load i8*, i8** %t694
  call void @star_rc_retain(i8* %t696)
  call void @star_rc_release(i8* %t695)
  %t697 = call i32 @strlen(i8* %t695)
  %t698 = icmp eq i32 %t697, 0
  br i1 %t698, label %if_then_142, label %if_else_143
if_then_142:
  %t699 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.10, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t699)
  %t700 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t700)
  br label %if_end_144
if_else_143:
  br label %if_end_144
if_end_144:
  %t701 = getelementptr inbounds %Item, %Item* %t619, i32 0, i32 1
  %t702 = load i8*, i8** %t701
  call void @star_rc_release(i8* %t702)
  br label %if_end_127
if_else_126:
  br label %if_end_127
if_end_127:
  %t703 = load i32, i32* %t501
  %t704 = add i32 %t703, 1
  store i32 %t704, i32* %t501
  br label %while_cond_102
while_else_104:
  br label %while_end_105
while_end_105:
  %t705 = load i8*, i8** %t500
  %t706 = icmp eq i8* %t705, null
  br i1 %t706, label %table_read_null_145, label %table_read_real_146
table_read_null_145:
  br label %table_read_end_147
table_read_real_146:
  %t707 = bitcast i8* %t705 to { i64, i64, i32*, i8** }*
  %t708 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t707, i32 0, i32 0
  %t709 = load i64, i64* %t708
  %t710 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t707, i32 0, i32 2
  %t711 = load i32*, i32** %t710
  %t712 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t707, i32 0, i32 3
  %t713 = load i8**, i8*** %t712
  br label %table_read_end_147
table_read_end_147:
  %t714 = phi i64 [ 0, %table_read_null_145 ], [ %t709, %table_read_real_146 ]
  %t715 = phi i32* [ null, %table_read_null_145 ], [ %t711, %table_read_real_146 ]
  %t716 = phi i8** [ null, %table_read_null_145 ], [ %t713, %table_read_real_146 ]
  %t717 = trunc i64 %t714 to i32
  %t718 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t718, i32 %t717)
  %t719 = load i8*, i8** %t500
  call void @star_rc_release(i8* %t719)
  %t720 = load i8*, i8** %t249
  call void @star_rc_release(i8* %t720)
  %t721 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t721)
  ret i32 0
}


; par/swarm worker functions
define void @table_release_s_Item(i8* %objp) {
entry:
  %t14 = alloca i64
  %t6 = bitcast i8* %objp to { i64, i64, i32*, i8** }*
  %t7 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t6, i32 0, i32 0
  %t8 = load i64, i64* %t7
  %t9 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t6, i32 0, i32 2
  %t10 = load i32*, i32** %t9
  %t11 = bitcast i32* %t10 to i8*
  call void @free(i8* %t11)
  %t12 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t6, i32 0, i32 3
  %t13 = load i8**, i8*** %t12
  store i64 0, i64* %t14
  br label %table_release_cond_7
table_release_cond_7:
  %t15 = load i64, i64* %t14
  %t16 = icmp slt i64 %t15, %t8
  br i1 %t16, label %table_release_body_8, label %table_release_end_9
table_release_body_8:
  %t17 = getelementptr inbounds i8*, i8** %t13, i64 %t15
  %t18 = load i8*, i8** %t17
  call void @star_rc_release(i8* %t18)
  %t19 = add i64 %t15, 1
  store i64 %t19, i64* %t14
  br label %table_release_cond_7
table_release_end_9:
  %t20 = bitcast i8** %t13 to i8*
  call void @free(i8* %t20)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant [7 x i8] c"tag-%d\00"
@.str.1 = private unnamed_addr constant [10 x i8] c"len = %d\0A\00"
@.str.2 = private unnamed_addr constant [17 x i8] c"t[0] = %s hp=%d\0A\00"
@.str.3 = private unnamed_addr constant [20 x i8] c"t[4999] = %s hp=%d\0A\00"
@.str.4 = private unnamed_addr constant [9 x i8] c"clone-%d\00"
@.str.5 = private unnamed_addr constant [34 x i8] c"original len = %d clone len = %d\0A\00"
@.str.6 = private unnamed_addr constant [32 x i8] c"original[0] = %s clone[0] = %s\0A\00"
@.str.7 = private unnamed_addr constant [38 x i8] c"original[4999] = %s clone[4999] = %s\0A\00"
@.str.8 = private unnamed_addr constant [7 x i8] c"cyc-%d\00"
@.str.9 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.10 = private unnamed_addr constant { i64, i8*, [21 x i8] } { i64 -1, i8* null, [21 x i8] c"unexpected empty pop\00" }
@.str.11 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.12 = private unnamed_addr constant [17 x i8] c"cycler len = %d\0A\00"
