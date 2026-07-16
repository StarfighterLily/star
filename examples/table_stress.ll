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
  %t180 = alloca %Item
  %t190 = alloca %Item
  %t207 = alloca %Item
  %t217 = alloca %Item
  %t233 = alloca %Item
  %t243 = alloca %Item
  %t247 = alloca i8*
  %t250 = alloca i32
  %t301 = alloca i64
  %t317 = alloca %Item
  %t401 = alloca %Item
  %t411 = alloca %Item
  %t427 = alloca %Item
  %t437 = alloca %Item
  %t454 = alloca %Item
  %t464 = alloca %Item
  %t480 = alloca %Item
  %t490 = alloca %Item
  %t494 = alloca i8*
  %t495 = alloca i32
  %t546 = alloca i64
  %t562 = alloca %Item
  %t613 = alloca %Item
  %t662 = alloca i64
  %t678 = alloca %Item
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
  call void @star_rc_release(i8* %t166)
  %t167 = sext i32 0 to i64
  %t168 = load i8*, i8** %t0
  %t169 = icmp eq i8* %t168, null
  br i1 %t169, label %table_read_null_33, label %table_read_real_34
table_read_null_33:
  br label %table_read_end_35
table_read_real_34:
  %t170 = bitcast i8* %t168 to { i64, i64, i32*, i8** }*
  %t171 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t170, i32 0, i32 0
  %t172 = load i64, i64* %t171
  %t173 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t170, i32 0, i32 2
  %t174 = load i32*, i32** %t173
  %t175 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t170, i32 0, i32 3
  %t176 = load i8**, i8*** %t175
  br label %table_read_end_35
table_read_end_35:
  %t177 = phi i64 [ 0, %table_read_null_33 ], [ %t172, %table_read_real_34 ]
  %t178 = phi i32* [ null, %table_read_null_33 ], [ %t174, %table_read_real_34 ]
  %t179 = phi i8** [ null, %table_read_null_33 ], [ %t176, %table_read_real_34 ]
  %t181 = icmp ult i64 %t167, %t177
  br i1 %t181, label %table_idx_ok_36, label %table_idx_oob_37
table_idx_ok_36:
  %t182 = getelementptr inbounds i32, i32* %t178, i64 %t167
  %t183 = load i32, i32* %t182
  %t184 = getelementptr inbounds %Item, %Item* %t180, i32 0, i32 0
  store i32 %t183, i32* %t184
  %t185 = getelementptr inbounds i8*, i8** %t179, i64 %t167
  %t186 = load i8*, i8** %t185
  call void @star_rc_retain(i8* %t186)
  %t187 = load i8*, i8** %t185
  %t188 = getelementptr inbounds %Item, %Item* %t180, i32 0, i32 1
  store i8* %t187, i8** %t188
  br label %table_idx_end_38
table_idx_oob_37:
  store %Item zeroinitializer, %Item* %t180
  br label %table_idx_end_38
table_idx_end_38:
  %t189 = load %Item, %Item* %t180
  store %Item %t189, %Item* %t190
  %t191 = getelementptr inbounds %Item, %Item* %t190, i32 0, i32 0
  %t192 = load i32, i32* %t191
  %t193 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t193, i8* %t166, i32 %t192)
  %t194 = sext i32 4999 to i64
  %t195 = load i8*, i8** %t0
  %t196 = icmp eq i8* %t195, null
  br i1 %t196, label %table_read_null_39, label %table_read_real_40
table_read_null_39:
  br label %table_read_end_41
table_read_real_40:
  %t197 = bitcast i8* %t195 to { i64, i64, i32*, i8** }*
  %t198 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t197, i32 0, i32 0
  %t199 = load i64, i64* %t198
  %t200 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t197, i32 0, i32 2
  %t201 = load i32*, i32** %t200
  %t202 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t197, i32 0, i32 3
  %t203 = load i8**, i8*** %t202
  br label %table_read_end_41
table_read_end_41:
  %t204 = phi i64 [ 0, %table_read_null_39 ], [ %t199, %table_read_real_40 ]
  %t205 = phi i32* [ null, %table_read_null_39 ], [ %t201, %table_read_real_40 ]
  %t206 = phi i8** [ null, %table_read_null_39 ], [ %t203, %table_read_real_40 ]
  %t208 = icmp ult i64 %t194, %t204
  br i1 %t208, label %table_idx_ok_42, label %table_idx_oob_43
table_idx_ok_42:
  %t209 = getelementptr inbounds i32, i32* %t205, i64 %t194
  %t210 = load i32, i32* %t209
  %t211 = getelementptr inbounds %Item, %Item* %t207, i32 0, i32 0
  store i32 %t210, i32* %t211
  %t212 = getelementptr inbounds i8*, i8** %t206, i64 %t194
  %t213 = load i8*, i8** %t212
  call void @star_rc_retain(i8* %t213)
  %t214 = load i8*, i8** %t212
  %t215 = getelementptr inbounds %Item, %Item* %t207, i32 0, i32 1
  store i8* %t214, i8** %t215
  br label %table_idx_end_44
table_idx_oob_43:
  store %Item zeroinitializer, %Item* %t207
  br label %table_idx_end_44
table_idx_end_44:
  %t216 = load %Item, %Item* %t207
  store %Item %t216, %Item* %t217
  %t218 = getelementptr inbounds %Item, %Item* %t217, i32 0, i32 1
  %t219 = load i8*, i8** %t218
  call void @star_rc_release(i8* %t219)
  %t220 = sext i32 4999 to i64
  %t221 = load i8*, i8** %t0
  %t222 = icmp eq i8* %t221, null
  br i1 %t222, label %table_read_null_45, label %table_read_real_46
table_read_null_45:
  br label %table_read_end_47
table_read_real_46:
  %t223 = bitcast i8* %t221 to { i64, i64, i32*, i8** }*
  %t224 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t223, i32 0, i32 0
  %t225 = load i64, i64* %t224
  %t226 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t223, i32 0, i32 2
  %t227 = load i32*, i32** %t226
  %t228 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t223, i32 0, i32 3
  %t229 = load i8**, i8*** %t228
  br label %table_read_end_47
table_read_end_47:
  %t230 = phi i64 [ 0, %table_read_null_45 ], [ %t225, %table_read_real_46 ]
  %t231 = phi i32* [ null, %table_read_null_45 ], [ %t227, %table_read_real_46 ]
  %t232 = phi i8** [ null, %table_read_null_45 ], [ %t229, %table_read_real_46 ]
  %t234 = icmp ult i64 %t220, %t230
  br i1 %t234, label %table_idx_ok_48, label %table_idx_oob_49
table_idx_ok_48:
  %t235 = getelementptr inbounds i32, i32* %t231, i64 %t220
  %t236 = load i32, i32* %t235
  %t237 = getelementptr inbounds %Item, %Item* %t233, i32 0, i32 0
  store i32 %t236, i32* %t237
  %t238 = getelementptr inbounds i8*, i8** %t232, i64 %t220
  %t239 = load i8*, i8** %t238
  call void @star_rc_retain(i8* %t239)
  %t240 = load i8*, i8** %t238
  %t241 = getelementptr inbounds %Item, %Item* %t233, i32 0, i32 1
  store i8* %t240, i8** %t241
  br label %table_idx_end_50
table_idx_oob_49:
  store %Item zeroinitializer, %Item* %t233
  br label %table_idx_end_50
table_idx_end_50:
  %t242 = load %Item, %Item* %t233
  store %Item %t242, %Item* %t243
  %t244 = getelementptr inbounds %Item, %Item* %t243, i32 0, i32 0
  %t245 = load i32, i32* %t244
  %t246 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t246, i8* %t219, i32 %t245)
  %t248 = load i8*, i8** %t0
  %t249 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t249)
  store i8* %t248, i8** %t247
  store i32 0, i32* %t250
  br label %while_cond_51
while_cond_51:
  %t251 = load i32, i32* %t250
  %t252 = icmp slt i32 %t251, 5000
  br i1 %t252, label %while_body_52, label %while_else_53
while_body_52:
  %t253 = load i8*, i8** %t247
  %t254 = icmp eq i8* %t253, null
  br i1 %t254, label %table_cow_alloc_55, label %table_cow_check_56
table_cow_alloc_55:
  %t255 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t256 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t257 = ptrtoint { i64, i64, i32*, i8** }* %t256 to i64
  %t258 = call i8* @star_rc_alloc(i64 %t257, i8* %t255)
  %t259 = bitcast i8* %t258 to { i64, i64, i32*, i8** }*
  %t260 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t259, i32 0, i32 0
  store i64 0, i64* %t260
  %t261 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t259, i32 0, i32 1
  store i64 0, i64* %t261
  %t262 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t259, i32 0, i32 2
  store i32* null, i32** %t262
  %t263 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t259, i32 0, i32 3
  store i8** null, i8*** %t263
  store i8* %t258, i8** %t247
  br label %table_cow_done_57
table_cow_check_56:
  %t264 = getelementptr inbounds i8, i8* %t253, i64 -16
  %t265 = bitcast i8* %t264 to i64*
  %t266 = load atomic i64, i64* %t265 seq_cst, align 8
  %t267 = icmp eq i64 %t266, 1
  br i1 %t267, label %table_cow_done_57, label %table_cow_clone_58
table_cow_clone_58:
  %t268 = bitcast i8* %t253 to { i64, i64, i32*, i8** }*
  %t269 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t268, i32 0, i32 0
  %t270 = load i64, i64* %t269
  %t271 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t268, i32 0, i32 1
  %t272 = load i64, i64* %t271
  %t273 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t274 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t275 = ptrtoint { i64, i64, i32*, i8** }* %t274 to i64
  %t276 = call i8* @star_rc_alloc(i64 %t275, i8* %t273)
  %t277 = bitcast i8* %t276 to { i64, i64, i32*, i8** }*
  %t278 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t277, i32 0, i32 0
  store i64 %t270, i64* %t278
  %t279 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t277, i32 0, i32 1
  store i64 %t272, i64* %t279
  %t280 = getelementptr i32, i32* null, i32 1
  %t281 = ptrtoint i32* %t280 to i64
  %t282 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t268, i32 0, i32 2
  %t283 = load i32*, i32** %t282
  %t284 = mul i64 %t272, %t281
  %t285 = call i8* @malloc(i64 %t284)
  %t286 = bitcast i8* %t285 to i32*
  %t287 = icmp sgt i64 %t270, 0
  br i1 %t287, label %table_cow_copy_59, label %table_cow_after_copy_60
table_cow_copy_59:
  %t288 = mul i64 %t270, %t281
  %t289 = bitcast i32* %t283 to i8*
  call i8* @memcpy(i8* %t285, i8* %t289, i64 %t288)
  br label %table_cow_after_copy_60
table_cow_after_copy_60:
  %t290 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t277, i32 0, i32 2
  store i32* %t286, i32** %t290
  %t291 = getelementptr i8*, i8** null, i32 1
  %t292 = ptrtoint i8** %t291 to i64
  %t293 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t268, i32 0, i32 3
  %t294 = load i8**, i8*** %t293
  %t295 = mul i64 %t272, %t292
  %t296 = call i8* @malloc(i64 %t295)
  %t297 = bitcast i8* %t296 to i8**
  %t298 = icmp sgt i64 %t270, 0
  br i1 %t298, label %table_cow_copy_61, label %table_cow_after_copy_62
table_cow_copy_61:
  %t299 = mul i64 %t270, %t292
  %t300 = bitcast i8** %t294 to i8*
  call i8* @memcpy(i8* %t296, i8* %t300, i64 %t299)
  store i64 0, i64* %t301
  br label %table_cow_retain_cond_63
table_cow_retain_cond_63:
  %t302 = load i64, i64* %t301
  %t303 = icmp slt i64 %t302, %t270
  br i1 %t303, label %table_cow_retain_body_64, label %table_cow_retain_end_65
table_cow_retain_body_64:
  %t304 = getelementptr inbounds i8*, i8** %t297, i64 %t302
  %t305 = load i8*, i8** %t304
  call void @star_rc_retain(i8* %t305)
  %t306 = add i64 %t302, 1
  store i64 %t306, i64* %t301
  br label %table_cow_retain_cond_63
table_cow_retain_end_65:
  br label %table_cow_after_copy_62
table_cow_after_copy_62:
  %t307 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t277, i32 0, i32 3
  store i8** %t297, i8*** %t307
  call void @star_rc_release(i8* %t253)
  store i8* %t276, i8** %t247
  br label %table_cow_done_57
table_cow_done_57:
  %t308 = load i8*, i8** %t247
  %t309 = bitcast i8* %t308 to { i64, i64, i32*, i8** }*
  %t310 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t309, i32 0, i32 0
  %t311 = load i64, i64* %t310
  %t312 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t309, i32 0, i32 1
  %t313 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t309, i32 0, i32 2
  %t314 = load i32*, i32** %t313
  %t315 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t309, i32 0, i32 3
  %t316 = load i8**, i8*** %t315
  %t318 = load i32, i32* %t250
  %t319 = getelementptr inbounds %Item, %Item* %t317, i32 0, i32 0
  store i32 %t318, i32* %t319
  %t320 = load i32, i32* %t250
  %t321 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.4, i64 0, i64 0
  %t322 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t321, i32 %t320)
  %t323 = add i32 %t322, 1
  %t324 = sext i32 %t323 to i64
  %t325 = call i8* @star_rc_alloc(i64 %t324, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t325, i64 %t324, i8* %t321, i32 %t320)
  %t326 = getelementptr inbounds %Item, %Item* %t317, i32 0, i32 1
  store i8* %t325, i8** %t326
  %t327 = load %Item, %Item* %t317
  %t328 = load i64, i64* %t312
  %t329 = load i64, i64* %t310
  %t330 = load i32*, i32** %t313
  %t331 = load i8**, i8*** %t315
  %t332 = icmp sge i64 %t329, %t328
  br i1 %t332, label %table_push_grow_66, label %table_push_store_67
table_push_grow_66:
  %t333 = mul i64 %t328, 2
  %t334 = icmp sgt i64 %t333, 0
  %t335 = select i1 %t334, i64 %t333, i64 1
  %t336 = getelementptr i32, i32* null, i32 1
  %t337 = ptrtoint i32* %t336 to i64
  %t338 = mul i64 %t335, %t337
  %t339 = call i8* @malloc(i64 %t338)
  %t340 = bitcast i8* %t339 to i32*
  %t341 = icmp sgt i64 %t328, 0
  br i1 %t341, label %table_push_copy_68, label %table_push_after_copy_69
table_push_copy_68:
  %t342 = mul i64 %t329, %t337
  %t343 = bitcast i32* %t330 to i8*
  call i8* @memcpy(i8* %t339, i8* %t343, i64 %t342)
  call void @free(i8* %t343)
  br label %table_push_after_copy_69
table_push_after_copy_69:
  store i32* %t340, i32** %t313
  %t344 = getelementptr i8*, i8** null, i32 1
  %t345 = ptrtoint i8** %t344 to i64
  %t346 = mul i64 %t335, %t345
  %t347 = call i8* @malloc(i64 %t346)
  %t348 = bitcast i8* %t347 to i8**
  %t349 = icmp sgt i64 %t328, 0
  br i1 %t349, label %table_push_copy_70, label %table_push_after_copy_71
table_push_copy_70:
  %t350 = mul i64 %t329, %t345
  %t351 = bitcast i8** %t331 to i8*
  call i8* @memcpy(i8* %t347, i8* %t351, i64 %t350)
  call void @free(i8* %t351)
  br label %table_push_after_copy_71
table_push_after_copy_71:
  store i8** %t348, i8*** %t315
  store i64 %t335, i64* %t312
  br label %table_push_store_67
table_push_store_67:
  %t352 = load i32*, i32** %t313
  %t353 = extractvalue %Item %t327, 0
  %t354 = getelementptr inbounds i32, i32* %t352, i64 %t329
  store i32 %t353, i32* %t354
  %t355 = load i8**, i8*** %t315
  %t356 = extractvalue %Item %t327, 1
  %t357 = getelementptr inbounds i8*, i8** %t355, i64 %t329
  store i8* %t356, i8** %t357
  %t358 = add i64 %t329, 1
  store i64 %t358, i64* %t310
  %t359 = load i32, i32* %t250
  %t360 = add i32 %t359, 1
  store i32 %t360, i32* %t250
  br label %while_cond_51
while_else_53:
  br label %while_end_54
while_end_54:
  %t361 = load i8*, i8** %t0
  %t362 = icmp eq i8* %t361, null
  br i1 %t362, label %table_read_null_72, label %table_read_real_73
table_read_null_72:
  br label %table_read_end_74
table_read_real_73:
  %t363 = bitcast i8* %t361 to { i64, i64, i32*, i8** }*
  %t364 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t363, i32 0, i32 0
  %t365 = load i64, i64* %t364
  %t366 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t363, i32 0, i32 2
  %t367 = load i32*, i32** %t366
  %t368 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t363, i32 0, i32 3
  %t369 = load i8**, i8*** %t368
  br label %table_read_end_74
table_read_end_74:
  %t370 = phi i64 [ 0, %table_read_null_72 ], [ %t365, %table_read_real_73 ]
  %t371 = phi i32* [ null, %table_read_null_72 ], [ %t367, %table_read_real_73 ]
  %t372 = phi i8** [ null, %table_read_null_72 ], [ %t369, %table_read_real_73 ]
  %t373 = trunc i64 %t370 to i32
  %t374 = load i8*, i8** %t247
  %t375 = icmp eq i8* %t374, null
  br i1 %t375, label %table_read_null_75, label %table_read_real_76
table_read_null_75:
  br label %table_read_end_77
table_read_real_76:
  %t376 = bitcast i8* %t374 to { i64, i64, i32*, i8** }*
  %t377 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t376, i32 0, i32 0
  %t378 = load i64, i64* %t377
  %t379 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t376, i32 0, i32 2
  %t380 = load i32*, i32** %t379
  %t381 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t376, i32 0, i32 3
  %t382 = load i8**, i8*** %t381
  br label %table_read_end_77
table_read_end_77:
  %t383 = phi i64 [ 0, %table_read_null_75 ], [ %t378, %table_read_real_76 ]
  %t384 = phi i32* [ null, %table_read_null_75 ], [ %t380, %table_read_real_76 ]
  %t385 = phi i8** [ null, %table_read_null_75 ], [ %t382, %table_read_real_76 ]
  %t386 = trunc i64 %t383 to i32
  %t387 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t387, i32 %t373, i32 %t386)
  %t388 = sext i32 0 to i64
  %t389 = load i8*, i8** %t0
  %t390 = icmp eq i8* %t389, null
  br i1 %t390, label %table_read_null_78, label %table_read_real_79
table_read_null_78:
  br label %table_read_end_80
table_read_real_79:
  %t391 = bitcast i8* %t389 to { i64, i64, i32*, i8** }*
  %t392 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t391, i32 0, i32 0
  %t393 = load i64, i64* %t392
  %t394 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t391, i32 0, i32 2
  %t395 = load i32*, i32** %t394
  %t396 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t391, i32 0, i32 3
  %t397 = load i8**, i8*** %t396
  br label %table_read_end_80
table_read_end_80:
  %t398 = phi i64 [ 0, %table_read_null_78 ], [ %t393, %table_read_real_79 ]
  %t399 = phi i32* [ null, %table_read_null_78 ], [ %t395, %table_read_real_79 ]
  %t400 = phi i8** [ null, %table_read_null_78 ], [ %t397, %table_read_real_79 ]
  %t402 = icmp ult i64 %t388, %t398
  br i1 %t402, label %table_idx_ok_81, label %table_idx_oob_82
table_idx_ok_81:
  %t403 = getelementptr inbounds i32, i32* %t399, i64 %t388
  %t404 = load i32, i32* %t403
  %t405 = getelementptr inbounds %Item, %Item* %t401, i32 0, i32 0
  store i32 %t404, i32* %t405
  %t406 = getelementptr inbounds i8*, i8** %t400, i64 %t388
  %t407 = load i8*, i8** %t406
  call void @star_rc_retain(i8* %t407)
  %t408 = load i8*, i8** %t406
  %t409 = getelementptr inbounds %Item, %Item* %t401, i32 0, i32 1
  store i8* %t408, i8** %t409
  br label %table_idx_end_83
table_idx_oob_82:
  store %Item zeroinitializer, %Item* %t401
  br label %table_idx_end_83
table_idx_end_83:
  %t410 = load %Item, %Item* %t401
  store %Item %t410, %Item* %t411
  %t412 = getelementptr inbounds %Item, %Item* %t411, i32 0, i32 1
  %t413 = load i8*, i8** %t412
  call void @star_rc_release(i8* %t413)
  %t414 = sext i32 0 to i64
  %t415 = load i8*, i8** %t247
  %t416 = icmp eq i8* %t415, null
  br i1 %t416, label %table_read_null_84, label %table_read_real_85
table_read_null_84:
  br label %table_read_end_86
table_read_real_85:
  %t417 = bitcast i8* %t415 to { i64, i64, i32*, i8** }*
  %t418 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t417, i32 0, i32 0
  %t419 = load i64, i64* %t418
  %t420 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t417, i32 0, i32 2
  %t421 = load i32*, i32** %t420
  %t422 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t417, i32 0, i32 3
  %t423 = load i8**, i8*** %t422
  br label %table_read_end_86
table_read_end_86:
  %t424 = phi i64 [ 0, %table_read_null_84 ], [ %t419, %table_read_real_85 ]
  %t425 = phi i32* [ null, %table_read_null_84 ], [ %t421, %table_read_real_85 ]
  %t426 = phi i8** [ null, %table_read_null_84 ], [ %t423, %table_read_real_85 ]
  %t428 = icmp ult i64 %t414, %t424
  br i1 %t428, label %table_idx_ok_87, label %table_idx_oob_88
table_idx_ok_87:
  %t429 = getelementptr inbounds i32, i32* %t425, i64 %t414
  %t430 = load i32, i32* %t429
  %t431 = getelementptr inbounds %Item, %Item* %t427, i32 0, i32 0
  store i32 %t430, i32* %t431
  %t432 = getelementptr inbounds i8*, i8** %t426, i64 %t414
  %t433 = load i8*, i8** %t432
  call void @star_rc_retain(i8* %t433)
  %t434 = load i8*, i8** %t432
  %t435 = getelementptr inbounds %Item, %Item* %t427, i32 0, i32 1
  store i8* %t434, i8** %t435
  br label %table_idx_end_89
table_idx_oob_88:
  store %Item zeroinitializer, %Item* %t427
  br label %table_idx_end_89
table_idx_end_89:
  %t436 = load %Item, %Item* %t427
  store %Item %t436, %Item* %t437
  %t438 = getelementptr inbounds %Item, %Item* %t437, i32 0, i32 1
  %t439 = load i8*, i8** %t438
  call void @star_rc_release(i8* %t439)
  %t440 = getelementptr inbounds [32 x i8], [32 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t440, i8* %t413, i8* %t439)
  %t441 = sext i32 4999 to i64
  %t442 = load i8*, i8** %t0
  %t443 = icmp eq i8* %t442, null
  br i1 %t443, label %table_read_null_90, label %table_read_real_91
table_read_null_90:
  br label %table_read_end_92
table_read_real_91:
  %t444 = bitcast i8* %t442 to { i64, i64, i32*, i8** }*
  %t445 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t444, i32 0, i32 0
  %t446 = load i64, i64* %t445
  %t447 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t444, i32 0, i32 2
  %t448 = load i32*, i32** %t447
  %t449 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t444, i32 0, i32 3
  %t450 = load i8**, i8*** %t449
  br label %table_read_end_92
table_read_end_92:
  %t451 = phi i64 [ 0, %table_read_null_90 ], [ %t446, %table_read_real_91 ]
  %t452 = phi i32* [ null, %table_read_null_90 ], [ %t448, %table_read_real_91 ]
  %t453 = phi i8** [ null, %table_read_null_90 ], [ %t450, %table_read_real_91 ]
  %t455 = icmp ult i64 %t441, %t451
  br i1 %t455, label %table_idx_ok_93, label %table_idx_oob_94
table_idx_ok_93:
  %t456 = getelementptr inbounds i32, i32* %t452, i64 %t441
  %t457 = load i32, i32* %t456
  %t458 = getelementptr inbounds %Item, %Item* %t454, i32 0, i32 0
  store i32 %t457, i32* %t458
  %t459 = getelementptr inbounds i8*, i8** %t453, i64 %t441
  %t460 = load i8*, i8** %t459
  call void @star_rc_retain(i8* %t460)
  %t461 = load i8*, i8** %t459
  %t462 = getelementptr inbounds %Item, %Item* %t454, i32 0, i32 1
  store i8* %t461, i8** %t462
  br label %table_idx_end_95
table_idx_oob_94:
  store %Item zeroinitializer, %Item* %t454
  br label %table_idx_end_95
table_idx_end_95:
  %t463 = load %Item, %Item* %t454
  store %Item %t463, %Item* %t464
  %t465 = getelementptr inbounds %Item, %Item* %t464, i32 0, i32 1
  %t466 = load i8*, i8** %t465
  call void @star_rc_release(i8* %t466)
  %t467 = sext i32 4999 to i64
  %t468 = load i8*, i8** %t247
  %t469 = icmp eq i8* %t468, null
  br i1 %t469, label %table_read_null_96, label %table_read_real_97
table_read_null_96:
  br label %table_read_end_98
table_read_real_97:
  %t470 = bitcast i8* %t468 to { i64, i64, i32*, i8** }*
  %t471 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t470, i32 0, i32 0
  %t472 = load i64, i64* %t471
  %t473 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t470, i32 0, i32 2
  %t474 = load i32*, i32** %t473
  %t475 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t470, i32 0, i32 3
  %t476 = load i8**, i8*** %t475
  br label %table_read_end_98
table_read_end_98:
  %t477 = phi i64 [ 0, %table_read_null_96 ], [ %t472, %table_read_real_97 ]
  %t478 = phi i32* [ null, %table_read_null_96 ], [ %t474, %table_read_real_97 ]
  %t479 = phi i8** [ null, %table_read_null_96 ], [ %t476, %table_read_real_97 ]
  %t481 = icmp ult i64 %t467, %t477
  br i1 %t481, label %table_idx_ok_99, label %table_idx_oob_100
table_idx_ok_99:
  %t482 = getelementptr inbounds i32, i32* %t478, i64 %t467
  %t483 = load i32, i32* %t482
  %t484 = getelementptr inbounds %Item, %Item* %t480, i32 0, i32 0
  store i32 %t483, i32* %t484
  %t485 = getelementptr inbounds i8*, i8** %t479, i64 %t467
  %t486 = load i8*, i8** %t485
  call void @star_rc_retain(i8* %t486)
  %t487 = load i8*, i8** %t485
  %t488 = getelementptr inbounds %Item, %Item* %t480, i32 0, i32 1
  store i8* %t487, i8** %t488
  br label %table_idx_end_101
table_idx_oob_100:
  store %Item zeroinitializer, %Item* %t480
  br label %table_idx_end_101
table_idx_end_101:
  %t489 = load %Item, %Item* %t480
  store %Item %t489, %Item* %t490
  %t491 = getelementptr inbounds %Item, %Item* %t490, i32 0, i32 1
  %t492 = load i8*, i8** %t491
  call void @star_rc_release(i8* %t492)
  %t493 = getelementptr inbounds [38 x i8], [38 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t493, i8* %t466, i8* %t492)
  store i8* null, i8** %t494
  store i32 0, i32* %t495
  br label %while_cond_102
while_cond_102:
  %t496 = load i32, i32* %t495
  %t497 = icmp slt i32 %t496, 3000
  br i1 %t497, label %while_body_103, label %while_else_104
while_body_103:
  %t498 = load i8*, i8** %t494
  %t499 = icmp eq i8* %t498, null
  br i1 %t499, label %table_cow_alloc_106, label %table_cow_check_107
table_cow_alloc_106:
  %t500 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t501 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t502 = ptrtoint { i64, i64, i32*, i8** }* %t501 to i64
  %t503 = call i8* @star_rc_alloc(i64 %t502, i8* %t500)
  %t504 = bitcast i8* %t503 to { i64, i64, i32*, i8** }*
  %t505 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t504, i32 0, i32 0
  store i64 0, i64* %t505
  %t506 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t504, i32 0, i32 1
  store i64 0, i64* %t506
  %t507 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t504, i32 0, i32 2
  store i32* null, i32** %t507
  %t508 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t504, i32 0, i32 3
  store i8** null, i8*** %t508
  store i8* %t503, i8** %t494
  br label %table_cow_done_108
table_cow_check_107:
  %t509 = getelementptr inbounds i8, i8* %t498, i64 -16
  %t510 = bitcast i8* %t509 to i64*
  %t511 = load atomic i64, i64* %t510 seq_cst, align 8
  %t512 = icmp eq i64 %t511, 1
  br i1 %t512, label %table_cow_done_108, label %table_cow_clone_109
table_cow_clone_109:
  %t513 = bitcast i8* %t498 to { i64, i64, i32*, i8** }*
  %t514 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t513, i32 0, i32 0
  %t515 = load i64, i64* %t514
  %t516 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t513, i32 0, i32 1
  %t517 = load i64, i64* %t516
  %t518 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t519 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t520 = ptrtoint { i64, i64, i32*, i8** }* %t519 to i64
  %t521 = call i8* @star_rc_alloc(i64 %t520, i8* %t518)
  %t522 = bitcast i8* %t521 to { i64, i64, i32*, i8** }*
  %t523 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t522, i32 0, i32 0
  store i64 %t515, i64* %t523
  %t524 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t522, i32 0, i32 1
  store i64 %t517, i64* %t524
  %t525 = getelementptr i32, i32* null, i32 1
  %t526 = ptrtoint i32* %t525 to i64
  %t527 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t513, i32 0, i32 2
  %t528 = load i32*, i32** %t527
  %t529 = mul i64 %t517, %t526
  %t530 = call i8* @malloc(i64 %t529)
  %t531 = bitcast i8* %t530 to i32*
  %t532 = icmp sgt i64 %t515, 0
  br i1 %t532, label %table_cow_copy_110, label %table_cow_after_copy_111
table_cow_copy_110:
  %t533 = mul i64 %t515, %t526
  %t534 = bitcast i32* %t528 to i8*
  call i8* @memcpy(i8* %t530, i8* %t534, i64 %t533)
  br label %table_cow_after_copy_111
table_cow_after_copy_111:
  %t535 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t522, i32 0, i32 2
  store i32* %t531, i32** %t535
  %t536 = getelementptr i8*, i8** null, i32 1
  %t537 = ptrtoint i8** %t536 to i64
  %t538 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t513, i32 0, i32 3
  %t539 = load i8**, i8*** %t538
  %t540 = mul i64 %t517, %t537
  %t541 = call i8* @malloc(i64 %t540)
  %t542 = bitcast i8* %t541 to i8**
  %t543 = icmp sgt i64 %t515, 0
  br i1 %t543, label %table_cow_copy_112, label %table_cow_after_copy_113
table_cow_copy_112:
  %t544 = mul i64 %t515, %t537
  %t545 = bitcast i8** %t539 to i8*
  call i8* @memcpy(i8* %t541, i8* %t545, i64 %t544)
  store i64 0, i64* %t546
  br label %table_cow_retain_cond_114
table_cow_retain_cond_114:
  %t547 = load i64, i64* %t546
  %t548 = icmp slt i64 %t547, %t515
  br i1 %t548, label %table_cow_retain_body_115, label %table_cow_retain_end_116
table_cow_retain_body_115:
  %t549 = getelementptr inbounds i8*, i8** %t542, i64 %t547
  %t550 = load i8*, i8** %t549
  call void @star_rc_retain(i8* %t550)
  %t551 = add i64 %t547, 1
  store i64 %t551, i64* %t546
  br label %table_cow_retain_cond_114
table_cow_retain_end_116:
  br label %table_cow_after_copy_113
table_cow_after_copy_113:
  %t552 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t522, i32 0, i32 3
  store i8** %t542, i8*** %t552
  call void @star_rc_release(i8* %t498)
  store i8* %t521, i8** %t494
  br label %table_cow_done_108
table_cow_done_108:
  %t553 = load i8*, i8** %t494
  %t554 = bitcast i8* %t553 to { i64, i64, i32*, i8** }*
  %t555 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t554, i32 0, i32 0
  %t556 = load i64, i64* %t555
  %t557 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t554, i32 0, i32 1
  %t558 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t554, i32 0, i32 2
  %t559 = load i32*, i32** %t558
  %t560 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t554, i32 0, i32 3
  %t561 = load i8**, i8*** %t560
  %t563 = load i32, i32* %t495
  %t564 = getelementptr inbounds %Item, %Item* %t562, i32 0, i32 0
  store i32 %t563, i32* %t564
  %t565 = load i32, i32* %t495
  %t566 = getelementptr inbounds [7 x i8], [7 x i8]* @.str.8, i64 0, i64 0
  %t567 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t566, i32 %t565)
  %t568 = add i32 %t567, 1
  %t569 = sext i32 %t568 to i64
  %t570 = call i8* @star_rc_alloc(i64 %t569, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t570, i64 %t569, i8* %t566, i32 %t565)
  %t571 = getelementptr inbounds %Item, %Item* %t562, i32 0, i32 1
  store i8* %t570, i8** %t571
  %t572 = load %Item, %Item* %t562
  %t573 = load i64, i64* %t557
  %t574 = load i64, i64* %t555
  %t575 = load i32*, i32** %t558
  %t576 = load i8**, i8*** %t560
  %t577 = icmp sge i64 %t574, %t573
  br i1 %t577, label %table_push_grow_117, label %table_push_store_118
table_push_grow_117:
  %t578 = mul i64 %t573, 2
  %t579 = icmp sgt i64 %t578, 0
  %t580 = select i1 %t579, i64 %t578, i64 1
  %t581 = getelementptr i32, i32* null, i32 1
  %t582 = ptrtoint i32* %t581 to i64
  %t583 = mul i64 %t580, %t582
  %t584 = call i8* @malloc(i64 %t583)
  %t585 = bitcast i8* %t584 to i32*
  %t586 = icmp sgt i64 %t573, 0
  br i1 %t586, label %table_push_copy_119, label %table_push_after_copy_120
table_push_copy_119:
  %t587 = mul i64 %t574, %t582
  %t588 = bitcast i32* %t575 to i8*
  call i8* @memcpy(i8* %t584, i8* %t588, i64 %t587)
  call void @free(i8* %t588)
  br label %table_push_after_copy_120
table_push_after_copy_120:
  store i32* %t585, i32** %t558
  %t589 = getelementptr i8*, i8** null, i32 1
  %t590 = ptrtoint i8** %t589 to i64
  %t591 = mul i64 %t580, %t590
  %t592 = call i8* @malloc(i64 %t591)
  %t593 = bitcast i8* %t592 to i8**
  %t594 = icmp sgt i64 %t573, 0
  br i1 %t594, label %table_push_copy_121, label %table_push_after_copy_122
table_push_copy_121:
  %t595 = mul i64 %t574, %t590
  %t596 = bitcast i8** %t576 to i8*
  call i8* @memcpy(i8* %t592, i8* %t596, i64 %t595)
  call void @free(i8* %t596)
  br label %table_push_after_copy_122
table_push_after_copy_122:
  store i8** %t593, i8*** %t560
  store i64 %t580, i64* %t557
  br label %table_push_store_118
table_push_store_118:
  %t597 = load i32*, i32** %t558
  %t598 = extractvalue %Item %t572, 0
  %t599 = getelementptr inbounds i32, i32* %t597, i64 %t574
  store i32 %t598, i32* %t599
  %t600 = load i8**, i8*** %t560
  %t601 = extractvalue %Item %t572, 1
  %t602 = getelementptr inbounds i8*, i8** %t600, i64 %t574
  store i8* %t601, i8** %t602
  %t603 = add i64 %t574, 1
  store i64 %t603, i64* %t555
  %t604 = load i32, i32* %t495
  %t605 = icmp eq i32 3, 0
  %t606 = icmp eq i32 %t604, -2147483648
  %t607 = icmp eq i32 3, -1
  %t608 = and i1 %t606, %t607
  %t609 = or i1 %t605, %t608
  br i1 %t609, label %int_div_fail_123, label %int_div_ok_124
int_div_fail_123:
  %t610 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.9, i64 0, i64 0
  call i32 @puts(i8* %t610)
  call void @exit(i32 1)
  unreachable
int_div_ok_124:
  %t611 = srem i32 %t604, 3
  %t612 = icmp eq i32 %t611, 0
  br i1 %t612, label %if_then_125, label %if_else_126
if_then_125:
  %t614 = load i8*, i8** %t494
  %t615 = icmp eq i8* %t614, null
  br i1 %t615, label %table_cow_alloc_128, label %table_cow_check_129
table_cow_alloc_128:
  %t616 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t617 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t618 = ptrtoint { i64, i64, i32*, i8** }* %t617 to i64
  %t619 = call i8* @star_rc_alloc(i64 %t618, i8* %t616)
  %t620 = bitcast i8* %t619 to { i64, i64, i32*, i8** }*
  %t621 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t620, i32 0, i32 0
  store i64 0, i64* %t621
  %t622 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t620, i32 0, i32 1
  store i64 0, i64* %t622
  %t623 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t620, i32 0, i32 2
  store i32* null, i32** %t623
  %t624 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t620, i32 0, i32 3
  store i8** null, i8*** %t624
  store i8* %t619, i8** %t494
  br label %table_cow_done_130
table_cow_check_129:
  %t625 = getelementptr inbounds i8, i8* %t614, i64 -16
  %t626 = bitcast i8* %t625 to i64*
  %t627 = load atomic i64, i64* %t626 seq_cst, align 8
  %t628 = icmp eq i64 %t627, 1
  br i1 %t628, label %table_cow_done_130, label %table_cow_clone_131
table_cow_clone_131:
  %t629 = bitcast i8* %t614 to { i64, i64, i32*, i8** }*
  %t630 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t629, i32 0, i32 0
  %t631 = load i64, i64* %t630
  %t632 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t629, i32 0, i32 1
  %t633 = load i64, i64* %t632
  %t634 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t635 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t636 = ptrtoint { i64, i64, i32*, i8** }* %t635 to i64
  %t637 = call i8* @star_rc_alloc(i64 %t636, i8* %t634)
  %t638 = bitcast i8* %t637 to { i64, i64, i32*, i8** }*
  %t639 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t638, i32 0, i32 0
  store i64 %t631, i64* %t639
  %t640 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t638, i32 0, i32 1
  store i64 %t633, i64* %t640
  %t641 = getelementptr i32, i32* null, i32 1
  %t642 = ptrtoint i32* %t641 to i64
  %t643 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t629, i32 0, i32 2
  %t644 = load i32*, i32** %t643
  %t645 = mul i64 %t633, %t642
  %t646 = call i8* @malloc(i64 %t645)
  %t647 = bitcast i8* %t646 to i32*
  %t648 = icmp sgt i64 %t631, 0
  br i1 %t648, label %table_cow_copy_132, label %table_cow_after_copy_133
table_cow_copy_132:
  %t649 = mul i64 %t631, %t642
  %t650 = bitcast i32* %t644 to i8*
  call i8* @memcpy(i8* %t646, i8* %t650, i64 %t649)
  br label %table_cow_after_copy_133
table_cow_after_copy_133:
  %t651 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t638, i32 0, i32 2
  store i32* %t647, i32** %t651
  %t652 = getelementptr i8*, i8** null, i32 1
  %t653 = ptrtoint i8** %t652 to i64
  %t654 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t629, i32 0, i32 3
  %t655 = load i8**, i8*** %t654
  %t656 = mul i64 %t633, %t653
  %t657 = call i8* @malloc(i64 %t656)
  %t658 = bitcast i8* %t657 to i8**
  %t659 = icmp sgt i64 %t631, 0
  br i1 %t659, label %table_cow_copy_134, label %table_cow_after_copy_135
table_cow_copy_134:
  %t660 = mul i64 %t631, %t653
  %t661 = bitcast i8** %t655 to i8*
  call i8* @memcpy(i8* %t657, i8* %t661, i64 %t660)
  store i64 0, i64* %t662
  br label %table_cow_retain_cond_136
table_cow_retain_cond_136:
  %t663 = load i64, i64* %t662
  %t664 = icmp slt i64 %t663, %t631
  br i1 %t664, label %table_cow_retain_body_137, label %table_cow_retain_end_138
table_cow_retain_body_137:
  %t665 = getelementptr inbounds i8*, i8** %t658, i64 %t663
  %t666 = load i8*, i8** %t665
  call void @star_rc_retain(i8* %t666)
  %t667 = add i64 %t663, 1
  store i64 %t667, i64* %t662
  br label %table_cow_retain_cond_136
table_cow_retain_end_138:
  br label %table_cow_after_copy_135
table_cow_after_copy_135:
  %t668 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t638, i32 0, i32 3
  store i8** %t658, i8*** %t668
  call void @star_rc_release(i8* %t614)
  store i8* %t637, i8** %t494
  br label %table_cow_done_130
table_cow_done_130:
  %t669 = load i8*, i8** %t494
  %t670 = bitcast i8* %t669 to { i64, i64, i32*, i8** }*
  %t671 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t670, i32 0, i32 0
  %t672 = load i64, i64* %t671
  %t673 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t670, i32 0, i32 1
  %t674 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t670, i32 0, i32 2
  %t675 = load i32*, i32** %t674
  %t676 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t670, i32 0, i32 3
  %t677 = load i8**, i8*** %t676
  %t679 = icmp eq i64 %t672, 0
  br i1 %t679, label %table_pop_empty_139, label %table_pop_nonempty_140
table_pop_nonempty_140:
  %t680 = sub i64 %t672, 1
  store i64 %t680, i64* %t671
  %t681 = getelementptr inbounds i32, i32* %t675, i64 %t680
  %t682 = load i32, i32* %t681
  %t683 = getelementptr inbounds %Item, %Item* %t678, i32 0, i32 0
  store i32 %t682, i32* %t683
  %t684 = getelementptr inbounds i8*, i8** %t677, i64 %t680
  %t685 = load i8*, i8** %t684
  %t686 = getelementptr inbounds %Item, %Item* %t678, i32 0, i32 1
  store i8* %t685, i8** %t686
  br label %table_pop_end_141
table_pop_empty_139:
  store %Item zeroinitializer, %Item* %t678
  br label %table_pop_end_141
table_pop_end_141:
  %t687 = load %Item, %Item* %t678
  store %Item %t687, %Item* %t613
  %t688 = getelementptr inbounds %Item, %Item* %t613, i32 0, i32 1
  %t689 = load i8*, i8** %t688
  %t690 = load i8*, i8** %t688
  call void @star_rc_retain(i8* %t690)
  call void @star_rc_release(i8* %t689)
  %t691 = call i32 @strlen(i8* %t689)
  %t692 = icmp eq i32 %t691, 0
  br i1 %t692, label %if_then_142, label %if_else_143
if_then_142:
  %t693 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.10, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t693)
  %t694 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t694)
  br label %if_end_144
if_else_143:
  br label %if_end_144
if_end_144:
  %t695 = getelementptr inbounds %Item, %Item* %t613, i32 0, i32 1
  %t696 = load i8*, i8** %t695
  call void @star_rc_release(i8* %t696)
  br label %if_end_127
if_else_126:
  br label %if_end_127
if_end_127:
  %t697 = load i32, i32* %t495
  %t698 = add i32 %t697, 1
  store i32 %t698, i32* %t495
  br label %while_cond_102
while_else_104:
  br label %while_end_105
while_end_105:
  %t699 = load i8*, i8** %t494
  %t700 = icmp eq i8* %t699, null
  br i1 %t700, label %table_read_null_145, label %table_read_real_146
table_read_null_145:
  br label %table_read_end_147
table_read_real_146:
  %t701 = bitcast i8* %t699 to { i64, i64, i32*, i8** }*
  %t702 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t701, i32 0, i32 0
  %t703 = load i64, i64* %t702
  %t704 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t701, i32 0, i32 2
  %t705 = load i32*, i32** %t704
  %t706 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t701, i32 0, i32 3
  %t707 = load i8**, i8*** %t706
  br label %table_read_end_147
table_read_end_147:
  %t708 = phi i64 [ 0, %table_read_null_145 ], [ %t703, %table_read_real_146 ]
  %t709 = phi i32* [ null, %table_read_null_145 ], [ %t705, %table_read_real_146 ]
  %t710 = phi i8** [ null, %table_read_null_145 ], [ %t707, %table_read_real_146 ]
  %t711 = trunc i64 %t708 to i32
  %t712 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t712, i32 %t711)
  %t713 = load i8*, i8** %t494
  call void @star_rc_release(i8* %t713)
  %t714 = load i8*, i8** %t247
  call void @star_rc_release(i8* %t714)
  %t715 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t715)
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
