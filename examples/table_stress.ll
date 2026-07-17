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

%Item = type { i32, i8* }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca i8*
  %t2 = alloca i32
  %t68 = alloca i64
  %t84 = alloca %Item
  %t155 = alloca %Item
  %t165 = alloca %Item
  %t182 = alloca %Item
  %t192 = alloca %Item
  %t209 = alloca %Item
  %t219 = alloca %Item
  %t236 = alloca %Item
  %t246 = alloca %Item
  %t250 = alloca i8*
  %t253 = alloca i32
  %t304 = alloca i64
  %t320 = alloca %Item
  %t404 = alloca %Item
  %t414 = alloca %Item
  %t431 = alloca %Item
  %t441 = alloca %Item
  %t459 = alloca %Item
  %t469 = alloca %Item
  %t486 = alloca %Item
  %t496 = alloca %Item
  %t501 = alloca i8*
  %t502 = alloca i32
  %t553 = alloca i64
  %t569 = alloca %Item
  %t620 = alloca %Item
  %t669 = alloca i64
  %t685 = alloca %Item
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  store i8* null, i8** %t1
  store i32 0, i32* %t2
  br label %while_cond_0
while_cond_0:
  %t3 = load i32, i32* %t2
  %t4 = icmp slt i32 %t3, 5000
  br i1 %t4, label %while_body_1, label %while_else_2
while_body_1:
  %t5 = load i8*, i8** %t1
  %t6 = icmp eq i8* %t5, null
  br i1 %t6, label %table_cow_alloc_4, label %table_cow_check_5
table_cow_alloc_4:
  %t22 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t23 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t24 = ptrtoint { i64, i64, i32*, i8** }* %t23 to i64
  %t25 = call i8* @star_rc_alloc(i64 %t24, i8* %t22)
  %t26 = bitcast i8* %t25 to { i64, i64, i32*, i8** }*
  %t27 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t26, i32 0, i32 0
  store i64 0, i64* %t27
  %t28 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t26, i32 0, i32 1
  store i64 0, i64* %t28
  %t29 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t26, i32 0, i32 2
  store i32* null, i32** %t29
  %t30 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t26, i32 0, i32 3
  store i8** null, i8*** %t30
  store i8* %t25, i8** %t1
  br label %table_cow_done_6
table_cow_check_5:
  %t31 = getelementptr inbounds i8, i8* %t5, i64 -16
  %t32 = bitcast i8* %t31 to i64*
  %t33 = load atomic i64, i64* %t32 seq_cst, align 8
  %t34 = icmp eq i64 %t33, 1
  br i1 %t34, label %table_cow_done_6, label %table_cow_clone_10
table_cow_clone_10:
  %t35 = bitcast i8* %t5 to { i64, i64, i32*, i8** }*
  %t36 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t35, i32 0, i32 0
  %t37 = load i64, i64* %t36
  %t38 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t35, i32 0, i32 1
  %t39 = load i64, i64* %t38
  %t40 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t41 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t42 = ptrtoint { i64, i64, i32*, i8** }* %t41 to i64
  %t43 = call i8* @star_rc_alloc(i64 %t42, i8* %t40)
  %t44 = bitcast i8* %t43 to { i64, i64, i32*, i8** }*
  %t45 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t44, i32 0, i32 0
  store i64 %t37, i64* %t45
  %t46 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t44, i32 0, i32 1
  store i64 %t39, i64* %t46
  %t47 = getelementptr i32, i32* null, i32 1
  %t48 = ptrtoint i32* %t47 to i64
  %t49 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t35, i32 0, i32 2
  %t50 = load i32*, i32** %t49
  %t51 = mul i64 %t39, %t48
  %t52 = call i8* @malloc(i64 %t51)
  %t53 = bitcast i8* %t52 to i32*
  %t54 = icmp sgt i64 %t37, 0
  br i1 %t54, label %table_cow_copy_11, label %table_cow_after_copy_12
table_cow_copy_11:
  %t55 = mul i64 %t37, %t48
  %t56 = bitcast i32* %t50 to i8*
  call i8* @memcpy(i8* %t52, i8* %t56, i64 %t55)
  br label %table_cow_after_copy_12
table_cow_after_copy_12:
  %t57 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t44, i32 0, i32 2
  store i32* %t53, i32** %t57
  %t58 = getelementptr i8*, i8** null, i32 1
  %t59 = ptrtoint i8** %t58 to i64
  %t60 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t35, i32 0, i32 3
  %t61 = load i8**, i8*** %t60
  %t62 = mul i64 %t39, %t59
  %t63 = call i8* @malloc(i64 %t62)
  %t64 = bitcast i8* %t63 to i8**
  %t65 = icmp sgt i64 %t37, 0
  br i1 %t65, label %table_cow_copy_13, label %table_cow_after_copy_14
table_cow_copy_13:
  %t66 = mul i64 %t37, %t59
  %t67 = bitcast i8** %t61 to i8*
  call i8* @memcpy(i8* %t63, i8* %t67, i64 %t66)
  store i64 0, i64* %t68
  br label %table_cow_retain_cond_15
table_cow_retain_cond_15:
  %t69 = load i64, i64* %t68
  %t70 = icmp slt i64 %t69, %t37
  br i1 %t70, label %table_cow_retain_body_16, label %table_cow_retain_end_17
table_cow_retain_body_16:
  %t71 = getelementptr inbounds i8*, i8** %t64, i64 %t69
  %t72 = load i8*, i8** %t71
  call void @star_rc_retain(i8* %t72)
  %t73 = add i64 %t69, 1
  store i64 %t73, i64* %t68
  br label %table_cow_retain_cond_15
table_cow_retain_end_17:
  br label %table_cow_after_copy_14
table_cow_after_copy_14:
  %t74 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t44, i32 0, i32 3
  store i8** %t64, i8*** %t74
  call void @star_rc_release(i8* %t5)
  store i8* %t43, i8** %t1
  br label %table_cow_done_6
table_cow_done_6:
  %t75 = load i8*, i8** %t1
  %t76 = bitcast i8* %t75 to { i64, i64, i32*, i8** }*
  %t77 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t76, i32 0, i32 0
  %t78 = load i64, i64* %t77
  %t79 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t76, i32 0, i32 1
  %t80 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t76, i32 0, i32 2
  %t81 = load i32*, i32** %t80
  %t82 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t76, i32 0, i32 3
  %t83 = load i8**, i8*** %t82
  %t85 = load i32, i32* %t2
  %t86 = getelementptr inbounds %Item, %Item* %t84, i32 0, i32 0
  store i32 %t85, i32* %t86
  %t87 = load i32, i32* %t2
  %t88 = getelementptr inbounds [7 x i8], [7 x i8]* @.str.0, i64 0, i64 0
  %t89 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t88, i32 %t87)
  %t90 = add i32 %t89, 1
  %t91 = sext i32 %t90 to i64
  %t92 = call i8* @star_rc_alloc(i64 %t91, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t92, i64 %t91, i8* %t88, i32 %t87)
  %t93 = getelementptr inbounds %Item, %Item* %t84, i32 0, i32 1
  store i8* %t92, i8** %t93
  %t94 = load %Item, %Item* %t84
  %t95 = load i64, i64* %t79
  %t96 = load i64, i64* %t77
  %t97 = load i32*, i32** %t80
  %t98 = load i8**, i8*** %t82
  %t99 = icmp sge i64 %t96, %t95
  br i1 %t99, label %table_push_grow_18, label %table_push_store_19
table_push_grow_18:
  %t100 = mul i64 %t95, 2
  %t101 = icmp sgt i64 %t100, 0
  %t102 = select i1 %t101, i64 %t100, i64 1
  %t103 = getelementptr i32, i32* null, i32 1
  %t104 = ptrtoint i32* %t103 to i64
  %t105 = mul i64 %t102, %t104
  %t106 = call i8* @malloc(i64 %t105)
  %t107 = bitcast i8* %t106 to i32*
  %t108 = icmp sgt i64 %t95, 0
  br i1 %t108, label %table_push_copy_20, label %table_push_after_copy_21
table_push_copy_20:
  %t109 = mul i64 %t96, %t104
  %t110 = bitcast i32* %t97 to i8*
  call i8* @memcpy(i8* %t106, i8* %t110, i64 %t109)
  call void @free(i8* %t110)
  br label %table_push_after_copy_21
table_push_after_copy_21:
  store i32* %t107, i32** %t80
  %t111 = getelementptr i8*, i8** null, i32 1
  %t112 = ptrtoint i8** %t111 to i64
  %t113 = mul i64 %t102, %t112
  %t114 = call i8* @malloc(i64 %t113)
  %t115 = bitcast i8* %t114 to i8**
  %t116 = icmp sgt i64 %t95, 0
  br i1 %t116, label %table_push_copy_22, label %table_push_after_copy_23
table_push_copy_22:
  %t117 = mul i64 %t96, %t112
  %t118 = bitcast i8** %t98 to i8*
  call i8* @memcpy(i8* %t114, i8* %t118, i64 %t117)
  call void @free(i8* %t118)
  br label %table_push_after_copy_23
table_push_after_copy_23:
  store i8** %t115, i8*** %t82
  store i64 %t102, i64* %t79
  br label %table_push_store_19
table_push_store_19:
  %t119 = load i32*, i32** %t80
  %t120 = extractvalue %Item %t94, 0
  %t121 = getelementptr inbounds i32, i32* %t119, i64 %t96
  store i32 %t120, i32* %t121
  %t122 = load i8**, i8*** %t82
  %t123 = extractvalue %Item %t94, 1
  %t124 = getelementptr inbounds i8*, i8** %t122, i64 %t96
  store i8* %t123, i8** %t124
  %t125 = add i64 %t96, 1
  store i64 %t125, i64* %t77
  %t126 = load i32, i32* %t2
  %t127 = add i32 %t126, 1
  store i32 %t127, i32* %t2
  br label %while_cond_0
while_else_2:
  br label %while_end_3
while_end_3:
  %t128 = load i8*, i8** %t1
  %t129 = icmp eq i8* %t128, null
  br i1 %t129, label %table_read_null_24, label %table_read_real_25
table_read_null_24:
  br label %table_read_end_26
table_read_real_25:
  %t130 = bitcast i8* %t128 to { i64, i64, i32*, i8** }*
  %t131 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t130, i32 0, i32 0
  %t132 = load i64, i64* %t131
  %t133 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t130, i32 0, i32 2
  %t134 = load i32*, i32** %t133
  %t135 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t130, i32 0, i32 3
  %t136 = load i8**, i8*** %t135
  br label %table_read_end_26
table_read_end_26:
  %t137 = phi i64 [ 0, %table_read_null_24 ], [ %t132, %table_read_real_25 ]
  %t138 = phi i32* [ null, %table_read_null_24 ], [ %t134, %table_read_real_25 ]
  %t139 = phi i8** [ null, %table_read_null_24 ], [ %t136, %table_read_real_25 ]
  %t140 = trunc i64 %t137 to i32
  %t141 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t141, i32 %t140)
  %t142 = sext i32 0 to i64
  %t143 = load i8*, i8** %t1
  %t144 = icmp eq i8* %t143, null
  br i1 %t144, label %table_read_null_27, label %table_read_real_28
table_read_null_27:
  br label %table_read_end_29
table_read_real_28:
  %t145 = bitcast i8* %t143 to { i64, i64, i32*, i8** }*
  %t146 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t145, i32 0, i32 0
  %t147 = load i64, i64* %t146
  %t148 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t145, i32 0, i32 2
  %t149 = load i32*, i32** %t148
  %t150 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t145, i32 0, i32 3
  %t151 = load i8**, i8*** %t150
  br label %table_read_end_29
table_read_end_29:
  %t152 = phi i64 [ 0, %table_read_null_27 ], [ %t147, %table_read_real_28 ]
  %t153 = phi i32* [ null, %table_read_null_27 ], [ %t149, %table_read_real_28 ]
  %t154 = phi i8** [ null, %table_read_null_27 ], [ %t151, %table_read_real_28 ]
  %t156 = icmp ult i64 %t142, %t152
  br i1 %t156, label %table_idx_ok_30, label %table_idx_oob_31
table_idx_ok_30:
  %t157 = getelementptr inbounds i32, i32* %t153, i64 %t142
  %t158 = load i32, i32* %t157
  %t159 = getelementptr inbounds %Item, %Item* %t155, i32 0, i32 0
  store i32 %t158, i32* %t159
  %t160 = getelementptr inbounds i8*, i8** %t154, i64 %t142
  %t161 = load i8*, i8** %t160
  call void @star_rc_retain(i8* %t161)
  %t162 = load i8*, i8** %t160
  %t163 = getelementptr inbounds %Item, %Item* %t155, i32 0, i32 1
  store i8* %t162, i8** %t163
  br label %table_idx_end_32
table_idx_oob_31:
  store %Item zeroinitializer, %Item* %t155
  br label %table_idx_end_32
table_idx_end_32:
  %t164 = load %Item, %Item* %t155
  store %Item %t164, %Item* %t165
  %t166 = getelementptr inbounds %Item, %Item* %t165, i32 0, i32 1
  %t167 = load i8*, i8** %t166
  %t168 = load i8*, i8** %t166
  call void @star_rc_retain(i8* %t168)
  call void @star_rc_release(i8* %t167)
  %t169 = sext i32 0 to i64
  %t170 = load i8*, i8** %t1
  %t171 = icmp eq i8* %t170, null
  br i1 %t171, label %table_read_null_33, label %table_read_real_34
table_read_null_33:
  br label %table_read_end_35
table_read_real_34:
  %t172 = bitcast i8* %t170 to { i64, i64, i32*, i8** }*
  %t173 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t172, i32 0, i32 0
  %t174 = load i64, i64* %t173
  %t175 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t172, i32 0, i32 2
  %t176 = load i32*, i32** %t175
  %t177 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t172, i32 0, i32 3
  %t178 = load i8**, i8*** %t177
  br label %table_read_end_35
table_read_end_35:
  %t179 = phi i64 [ 0, %table_read_null_33 ], [ %t174, %table_read_real_34 ]
  %t180 = phi i32* [ null, %table_read_null_33 ], [ %t176, %table_read_real_34 ]
  %t181 = phi i8** [ null, %table_read_null_33 ], [ %t178, %table_read_real_34 ]
  %t183 = icmp ult i64 %t169, %t179
  br i1 %t183, label %table_idx_ok_36, label %table_idx_oob_37
table_idx_ok_36:
  %t184 = getelementptr inbounds i32, i32* %t180, i64 %t169
  %t185 = load i32, i32* %t184
  %t186 = getelementptr inbounds %Item, %Item* %t182, i32 0, i32 0
  store i32 %t185, i32* %t186
  %t187 = getelementptr inbounds i8*, i8** %t181, i64 %t169
  %t188 = load i8*, i8** %t187
  call void @star_rc_retain(i8* %t188)
  %t189 = load i8*, i8** %t187
  %t190 = getelementptr inbounds %Item, %Item* %t182, i32 0, i32 1
  store i8* %t189, i8** %t190
  br label %table_idx_end_38
table_idx_oob_37:
  store %Item zeroinitializer, %Item* %t182
  br label %table_idx_end_38
table_idx_end_38:
  %t191 = load %Item, %Item* %t182
  store %Item %t191, %Item* %t192
  %t193 = getelementptr inbounds %Item, %Item* %t192, i32 0, i32 0
  %t194 = load i32, i32* %t193
  %t195 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t195, i8* %t167, i32 %t194)
  %t196 = sext i32 4999 to i64
  %t197 = load i8*, i8** %t1
  %t198 = icmp eq i8* %t197, null
  br i1 %t198, label %table_read_null_39, label %table_read_real_40
table_read_null_39:
  br label %table_read_end_41
table_read_real_40:
  %t199 = bitcast i8* %t197 to { i64, i64, i32*, i8** }*
  %t200 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t199, i32 0, i32 0
  %t201 = load i64, i64* %t200
  %t202 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t199, i32 0, i32 2
  %t203 = load i32*, i32** %t202
  %t204 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t199, i32 0, i32 3
  %t205 = load i8**, i8*** %t204
  br label %table_read_end_41
table_read_end_41:
  %t206 = phi i64 [ 0, %table_read_null_39 ], [ %t201, %table_read_real_40 ]
  %t207 = phi i32* [ null, %table_read_null_39 ], [ %t203, %table_read_real_40 ]
  %t208 = phi i8** [ null, %table_read_null_39 ], [ %t205, %table_read_real_40 ]
  %t210 = icmp ult i64 %t196, %t206
  br i1 %t210, label %table_idx_ok_42, label %table_idx_oob_43
table_idx_ok_42:
  %t211 = getelementptr inbounds i32, i32* %t207, i64 %t196
  %t212 = load i32, i32* %t211
  %t213 = getelementptr inbounds %Item, %Item* %t209, i32 0, i32 0
  store i32 %t212, i32* %t213
  %t214 = getelementptr inbounds i8*, i8** %t208, i64 %t196
  %t215 = load i8*, i8** %t214
  call void @star_rc_retain(i8* %t215)
  %t216 = load i8*, i8** %t214
  %t217 = getelementptr inbounds %Item, %Item* %t209, i32 0, i32 1
  store i8* %t216, i8** %t217
  br label %table_idx_end_44
table_idx_oob_43:
  store %Item zeroinitializer, %Item* %t209
  br label %table_idx_end_44
table_idx_end_44:
  %t218 = load %Item, %Item* %t209
  store %Item %t218, %Item* %t219
  %t220 = getelementptr inbounds %Item, %Item* %t219, i32 0, i32 1
  %t221 = load i8*, i8** %t220
  %t222 = load i8*, i8** %t220
  call void @star_rc_retain(i8* %t222)
  call void @star_rc_release(i8* %t221)
  %t223 = sext i32 4999 to i64
  %t224 = load i8*, i8** %t1
  %t225 = icmp eq i8* %t224, null
  br i1 %t225, label %table_read_null_45, label %table_read_real_46
table_read_null_45:
  br label %table_read_end_47
table_read_real_46:
  %t226 = bitcast i8* %t224 to { i64, i64, i32*, i8** }*
  %t227 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t226, i32 0, i32 0
  %t228 = load i64, i64* %t227
  %t229 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t226, i32 0, i32 2
  %t230 = load i32*, i32** %t229
  %t231 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t226, i32 0, i32 3
  %t232 = load i8**, i8*** %t231
  br label %table_read_end_47
table_read_end_47:
  %t233 = phi i64 [ 0, %table_read_null_45 ], [ %t228, %table_read_real_46 ]
  %t234 = phi i32* [ null, %table_read_null_45 ], [ %t230, %table_read_real_46 ]
  %t235 = phi i8** [ null, %table_read_null_45 ], [ %t232, %table_read_real_46 ]
  %t237 = icmp ult i64 %t223, %t233
  br i1 %t237, label %table_idx_ok_48, label %table_idx_oob_49
table_idx_ok_48:
  %t238 = getelementptr inbounds i32, i32* %t234, i64 %t223
  %t239 = load i32, i32* %t238
  %t240 = getelementptr inbounds %Item, %Item* %t236, i32 0, i32 0
  store i32 %t239, i32* %t240
  %t241 = getelementptr inbounds i8*, i8** %t235, i64 %t223
  %t242 = load i8*, i8** %t241
  call void @star_rc_retain(i8* %t242)
  %t243 = load i8*, i8** %t241
  %t244 = getelementptr inbounds %Item, %Item* %t236, i32 0, i32 1
  store i8* %t243, i8** %t244
  br label %table_idx_end_50
table_idx_oob_49:
  store %Item zeroinitializer, %Item* %t236
  br label %table_idx_end_50
table_idx_end_50:
  %t245 = load %Item, %Item* %t236
  store %Item %t245, %Item* %t246
  %t247 = getelementptr inbounds %Item, %Item* %t246, i32 0, i32 0
  %t248 = load i32, i32* %t247
  %t249 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t249, i8* %t221, i32 %t248)
  %t251 = load i8*, i8** %t1
  %t252 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t252)
  store i8* %t251, i8** %t250
  store i32 0, i32* %t253
  br label %while_cond_51
while_cond_51:
  %t254 = load i32, i32* %t253
  %t255 = icmp slt i32 %t254, 5000
  br i1 %t255, label %while_body_52, label %while_else_53
while_body_52:
  %t256 = load i8*, i8** %t250
  %t257 = icmp eq i8* %t256, null
  br i1 %t257, label %table_cow_alloc_55, label %table_cow_check_56
table_cow_alloc_55:
  %t258 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t259 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t260 = ptrtoint { i64, i64, i32*, i8** }* %t259 to i64
  %t261 = call i8* @star_rc_alloc(i64 %t260, i8* %t258)
  %t262 = bitcast i8* %t261 to { i64, i64, i32*, i8** }*
  %t263 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t262, i32 0, i32 0
  store i64 0, i64* %t263
  %t264 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t262, i32 0, i32 1
  store i64 0, i64* %t264
  %t265 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t262, i32 0, i32 2
  store i32* null, i32** %t265
  %t266 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t262, i32 0, i32 3
  store i8** null, i8*** %t266
  store i8* %t261, i8** %t250
  br label %table_cow_done_57
table_cow_check_56:
  %t267 = getelementptr inbounds i8, i8* %t256, i64 -16
  %t268 = bitcast i8* %t267 to i64*
  %t269 = load atomic i64, i64* %t268 seq_cst, align 8
  %t270 = icmp eq i64 %t269, 1
  br i1 %t270, label %table_cow_done_57, label %table_cow_clone_58
table_cow_clone_58:
  %t271 = bitcast i8* %t256 to { i64, i64, i32*, i8** }*
  %t272 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t271, i32 0, i32 0
  %t273 = load i64, i64* %t272
  %t274 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t271, i32 0, i32 1
  %t275 = load i64, i64* %t274
  %t276 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t277 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t278 = ptrtoint { i64, i64, i32*, i8** }* %t277 to i64
  %t279 = call i8* @star_rc_alloc(i64 %t278, i8* %t276)
  %t280 = bitcast i8* %t279 to { i64, i64, i32*, i8** }*
  %t281 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t280, i32 0, i32 0
  store i64 %t273, i64* %t281
  %t282 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t280, i32 0, i32 1
  store i64 %t275, i64* %t282
  %t283 = getelementptr i32, i32* null, i32 1
  %t284 = ptrtoint i32* %t283 to i64
  %t285 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t271, i32 0, i32 2
  %t286 = load i32*, i32** %t285
  %t287 = mul i64 %t275, %t284
  %t288 = call i8* @malloc(i64 %t287)
  %t289 = bitcast i8* %t288 to i32*
  %t290 = icmp sgt i64 %t273, 0
  br i1 %t290, label %table_cow_copy_59, label %table_cow_after_copy_60
table_cow_copy_59:
  %t291 = mul i64 %t273, %t284
  %t292 = bitcast i32* %t286 to i8*
  call i8* @memcpy(i8* %t288, i8* %t292, i64 %t291)
  br label %table_cow_after_copy_60
table_cow_after_copy_60:
  %t293 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t280, i32 0, i32 2
  store i32* %t289, i32** %t293
  %t294 = getelementptr i8*, i8** null, i32 1
  %t295 = ptrtoint i8** %t294 to i64
  %t296 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t271, i32 0, i32 3
  %t297 = load i8**, i8*** %t296
  %t298 = mul i64 %t275, %t295
  %t299 = call i8* @malloc(i64 %t298)
  %t300 = bitcast i8* %t299 to i8**
  %t301 = icmp sgt i64 %t273, 0
  br i1 %t301, label %table_cow_copy_61, label %table_cow_after_copy_62
table_cow_copy_61:
  %t302 = mul i64 %t273, %t295
  %t303 = bitcast i8** %t297 to i8*
  call i8* @memcpy(i8* %t299, i8* %t303, i64 %t302)
  store i64 0, i64* %t304
  br label %table_cow_retain_cond_63
table_cow_retain_cond_63:
  %t305 = load i64, i64* %t304
  %t306 = icmp slt i64 %t305, %t273
  br i1 %t306, label %table_cow_retain_body_64, label %table_cow_retain_end_65
table_cow_retain_body_64:
  %t307 = getelementptr inbounds i8*, i8** %t300, i64 %t305
  %t308 = load i8*, i8** %t307
  call void @star_rc_retain(i8* %t308)
  %t309 = add i64 %t305, 1
  store i64 %t309, i64* %t304
  br label %table_cow_retain_cond_63
table_cow_retain_end_65:
  br label %table_cow_after_copy_62
table_cow_after_copy_62:
  %t310 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t280, i32 0, i32 3
  store i8** %t300, i8*** %t310
  call void @star_rc_release(i8* %t256)
  store i8* %t279, i8** %t250
  br label %table_cow_done_57
table_cow_done_57:
  %t311 = load i8*, i8** %t250
  %t312 = bitcast i8* %t311 to { i64, i64, i32*, i8** }*
  %t313 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t312, i32 0, i32 0
  %t314 = load i64, i64* %t313
  %t315 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t312, i32 0, i32 1
  %t316 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t312, i32 0, i32 2
  %t317 = load i32*, i32** %t316
  %t318 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t312, i32 0, i32 3
  %t319 = load i8**, i8*** %t318
  %t321 = load i32, i32* %t253
  %t322 = getelementptr inbounds %Item, %Item* %t320, i32 0, i32 0
  store i32 %t321, i32* %t322
  %t323 = load i32, i32* %t253
  %t324 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.4, i64 0, i64 0
  %t325 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t324, i32 %t323)
  %t326 = add i32 %t325, 1
  %t327 = sext i32 %t326 to i64
  %t328 = call i8* @star_rc_alloc(i64 %t327, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t328, i64 %t327, i8* %t324, i32 %t323)
  %t329 = getelementptr inbounds %Item, %Item* %t320, i32 0, i32 1
  store i8* %t328, i8** %t329
  %t330 = load %Item, %Item* %t320
  %t331 = load i64, i64* %t315
  %t332 = load i64, i64* %t313
  %t333 = load i32*, i32** %t316
  %t334 = load i8**, i8*** %t318
  %t335 = icmp sge i64 %t332, %t331
  br i1 %t335, label %table_push_grow_66, label %table_push_store_67
table_push_grow_66:
  %t336 = mul i64 %t331, 2
  %t337 = icmp sgt i64 %t336, 0
  %t338 = select i1 %t337, i64 %t336, i64 1
  %t339 = getelementptr i32, i32* null, i32 1
  %t340 = ptrtoint i32* %t339 to i64
  %t341 = mul i64 %t338, %t340
  %t342 = call i8* @malloc(i64 %t341)
  %t343 = bitcast i8* %t342 to i32*
  %t344 = icmp sgt i64 %t331, 0
  br i1 %t344, label %table_push_copy_68, label %table_push_after_copy_69
table_push_copy_68:
  %t345 = mul i64 %t332, %t340
  %t346 = bitcast i32* %t333 to i8*
  call i8* @memcpy(i8* %t342, i8* %t346, i64 %t345)
  call void @free(i8* %t346)
  br label %table_push_after_copy_69
table_push_after_copy_69:
  store i32* %t343, i32** %t316
  %t347 = getelementptr i8*, i8** null, i32 1
  %t348 = ptrtoint i8** %t347 to i64
  %t349 = mul i64 %t338, %t348
  %t350 = call i8* @malloc(i64 %t349)
  %t351 = bitcast i8* %t350 to i8**
  %t352 = icmp sgt i64 %t331, 0
  br i1 %t352, label %table_push_copy_70, label %table_push_after_copy_71
table_push_copy_70:
  %t353 = mul i64 %t332, %t348
  %t354 = bitcast i8** %t334 to i8*
  call i8* @memcpy(i8* %t350, i8* %t354, i64 %t353)
  call void @free(i8* %t354)
  br label %table_push_after_copy_71
table_push_after_copy_71:
  store i8** %t351, i8*** %t318
  store i64 %t338, i64* %t315
  br label %table_push_store_67
table_push_store_67:
  %t355 = load i32*, i32** %t316
  %t356 = extractvalue %Item %t330, 0
  %t357 = getelementptr inbounds i32, i32* %t355, i64 %t332
  store i32 %t356, i32* %t357
  %t358 = load i8**, i8*** %t318
  %t359 = extractvalue %Item %t330, 1
  %t360 = getelementptr inbounds i8*, i8** %t358, i64 %t332
  store i8* %t359, i8** %t360
  %t361 = add i64 %t332, 1
  store i64 %t361, i64* %t313
  %t362 = load i32, i32* %t253
  %t363 = add i32 %t362, 1
  store i32 %t363, i32* %t253
  br label %while_cond_51
while_else_53:
  br label %while_end_54
while_end_54:
  %t364 = load i8*, i8** %t1
  %t365 = icmp eq i8* %t364, null
  br i1 %t365, label %table_read_null_72, label %table_read_real_73
table_read_null_72:
  br label %table_read_end_74
table_read_real_73:
  %t366 = bitcast i8* %t364 to { i64, i64, i32*, i8** }*
  %t367 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t366, i32 0, i32 0
  %t368 = load i64, i64* %t367
  %t369 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t366, i32 0, i32 2
  %t370 = load i32*, i32** %t369
  %t371 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t366, i32 0, i32 3
  %t372 = load i8**, i8*** %t371
  br label %table_read_end_74
table_read_end_74:
  %t373 = phi i64 [ 0, %table_read_null_72 ], [ %t368, %table_read_real_73 ]
  %t374 = phi i32* [ null, %table_read_null_72 ], [ %t370, %table_read_real_73 ]
  %t375 = phi i8** [ null, %table_read_null_72 ], [ %t372, %table_read_real_73 ]
  %t376 = trunc i64 %t373 to i32
  %t377 = load i8*, i8** %t250
  %t378 = icmp eq i8* %t377, null
  br i1 %t378, label %table_read_null_75, label %table_read_real_76
table_read_null_75:
  br label %table_read_end_77
table_read_real_76:
  %t379 = bitcast i8* %t377 to { i64, i64, i32*, i8** }*
  %t380 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t379, i32 0, i32 0
  %t381 = load i64, i64* %t380
  %t382 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t379, i32 0, i32 2
  %t383 = load i32*, i32** %t382
  %t384 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t379, i32 0, i32 3
  %t385 = load i8**, i8*** %t384
  br label %table_read_end_77
table_read_end_77:
  %t386 = phi i64 [ 0, %table_read_null_75 ], [ %t381, %table_read_real_76 ]
  %t387 = phi i32* [ null, %table_read_null_75 ], [ %t383, %table_read_real_76 ]
  %t388 = phi i8** [ null, %table_read_null_75 ], [ %t385, %table_read_real_76 ]
  %t389 = trunc i64 %t386 to i32
  %t390 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t390, i32 %t376, i32 %t389)
  %t391 = sext i32 0 to i64
  %t392 = load i8*, i8** %t1
  %t393 = icmp eq i8* %t392, null
  br i1 %t393, label %table_read_null_78, label %table_read_real_79
table_read_null_78:
  br label %table_read_end_80
table_read_real_79:
  %t394 = bitcast i8* %t392 to { i64, i64, i32*, i8** }*
  %t395 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t394, i32 0, i32 0
  %t396 = load i64, i64* %t395
  %t397 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t394, i32 0, i32 2
  %t398 = load i32*, i32** %t397
  %t399 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t394, i32 0, i32 3
  %t400 = load i8**, i8*** %t399
  br label %table_read_end_80
table_read_end_80:
  %t401 = phi i64 [ 0, %table_read_null_78 ], [ %t396, %table_read_real_79 ]
  %t402 = phi i32* [ null, %table_read_null_78 ], [ %t398, %table_read_real_79 ]
  %t403 = phi i8** [ null, %table_read_null_78 ], [ %t400, %table_read_real_79 ]
  %t405 = icmp ult i64 %t391, %t401
  br i1 %t405, label %table_idx_ok_81, label %table_idx_oob_82
table_idx_ok_81:
  %t406 = getelementptr inbounds i32, i32* %t402, i64 %t391
  %t407 = load i32, i32* %t406
  %t408 = getelementptr inbounds %Item, %Item* %t404, i32 0, i32 0
  store i32 %t407, i32* %t408
  %t409 = getelementptr inbounds i8*, i8** %t403, i64 %t391
  %t410 = load i8*, i8** %t409
  call void @star_rc_retain(i8* %t410)
  %t411 = load i8*, i8** %t409
  %t412 = getelementptr inbounds %Item, %Item* %t404, i32 0, i32 1
  store i8* %t411, i8** %t412
  br label %table_idx_end_83
table_idx_oob_82:
  store %Item zeroinitializer, %Item* %t404
  br label %table_idx_end_83
table_idx_end_83:
  %t413 = load %Item, %Item* %t404
  store %Item %t413, %Item* %t414
  %t415 = getelementptr inbounds %Item, %Item* %t414, i32 0, i32 1
  %t416 = load i8*, i8** %t415
  %t417 = load i8*, i8** %t415
  call void @star_rc_retain(i8* %t417)
  call void @star_rc_release(i8* %t416)
  %t418 = sext i32 0 to i64
  %t419 = load i8*, i8** %t250
  %t420 = icmp eq i8* %t419, null
  br i1 %t420, label %table_read_null_84, label %table_read_real_85
table_read_null_84:
  br label %table_read_end_86
table_read_real_85:
  %t421 = bitcast i8* %t419 to { i64, i64, i32*, i8** }*
  %t422 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t421, i32 0, i32 0
  %t423 = load i64, i64* %t422
  %t424 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t421, i32 0, i32 2
  %t425 = load i32*, i32** %t424
  %t426 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t421, i32 0, i32 3
  %t427 = load i8**, i8*** %t426
  br label %table_read_end_86
table_read_end_86:
  %t428 = phi i64 [ 0, %table_read_null_84 ], [ %t423, %table_read_real_85 ]
  %t429 = phi i32* [ null, %table_read_null_84 ], [ %t425, %table_read_real_85 ]
  %t430 = phi i8** [ null, %table_read_null_84 ], [ %t427, %table_read_real_85 ]
  %t432 = icmp ult i64 %t418, %t428
  br i1 %t432, label %table_idx_ok_87, label %table_idx_oob_88
table_idx_ok_87:
  %t433 = getelementptr inbounds i32, i32* %t429, i64 %t418
  %t434 = load i32, i32* %t433
  %t435 = getelementptr inbounds %Item, %Item* %t431, i32 0, i32 0
  store i32 %t434, i32* %t435
  %t436 = getelementptr inbounds i8*, i8** %t430, i64 %t418
  %t437 = load i8*, i8** %t436
  call void @star_rc_retain(i8* %t437)
  %t438 = load i8*, i8** %t436
  %t439 = getelementptr inbounds %Item, %Item* %t431, i32 0, i32 1
  store i8* %t438, i8** %t439
  br label %table_idx_end_89
table_idx_oob_88:
  store %Item zeroinitializer, %Item* %t431
  br label %table_idx_end_89
table_idx_end_89:
  %t440 = load %Item, %Item* %t431
  store %Item %t440, %Item* %t441
  %t442 = getelementptr inbounds %Item, %Item* %t441, i32 0, i32 1
  %t443 = load i8*, i8** %t442
  %t444 = load i8*, i8** %t442
  call void @star_rc_retain(i8* %t444)
  call void @star_rc_release(i8* %t443)
  %t445 = getelementptr inbounds [32 x i8], [32 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t445, i8* %t416, i8* %t443)
  %t446 = sext i32 4999 to i64
  %t447 = load i8*, i8** %t1
  %t448 = icmp eq i8* %t447, null
  br i1 %t448, label %table_read_null_90, label %table_read_real_91
table_read_null_90:
  br label %table_read_end_92
table_read_real_91:
  %t449 = bitcast i8* %t447 to { i64, i64, i32*, i8** }*
  %t450 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t449, i32 0, i32 0
  %t451 = load i64, i64* %t450
  %t452 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t449, i32 0, i32 2
  %t453 = load i32*, i32** %t452
  %t454 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t449, i32 0, i32 3
  %t455 = load i8**, i8*** %t454
  br label %table_read_end_92
table_read_end_92:
  %t456 = phi i64 [ 0, %table_read_null_90 ], [ %t451, %table_read_real_91 ]
  %t457 = phi i32* [ null, %table_read_null_90 ], [ %t453, %table_read_real_91 ]
  %t458 = phi i8** [ null, %table_read_null_90 ], [ %t455, %table_read_real_91 ]
  %t460 = icmp ult i64 %t446, %t456
  br i1 %t460, label %table_idx_ok_93, label %table_idx_oob_94
table_idx_ok_93:
  %t461 = getelementptr inbounds i32, i32* %t457, i64 %t446
  %t462 = load i32, i32* %t461
  %t463 = getelementptr inbounds %Item, %Item* %t459, i32 0, i32 0
  store i32 %t462, i32* %t463
  %t464 = getelementptr inbounds i8*, i8** %t458, i64 %t446
  %t465 = load i8*, i8** %t464
  call void @star_rc_retain(i8* %t465)
  %t466 = load i8*, i8** %t464
  %t467 = getelementptr inbounds %Item, %Item* %t459, i32 0, i32 1
  store i8* %t466, i8** %t467
  br label %table_idx_end_95
table_idx_oob_94:
  store %Item zeroinitializer, %Item* %t459
  br label %table_idx_end_95
table_idx_end_95:
  %t468 = load %Item, %Item* %t459
  store %Item %t468, %Item* %t469
  %t470 = getelementptr inbounds %Item, %Item* %t469, i32 0, i32 1
  %t471 = load i8*, i8** %t470
  %t472 = load i8*, i8** %t470
  call void @star_rc_retain(i8* %t472)
  call void @star_rc_release(i8* %t471)
  %t473 = sext i32 4999 to i64
  %t474 = load i8*, i8** %t250
  %t475 = icmp eq i8* %t474, null
  br i1 %t475, label %table_read_null_96, label %table_read_real_97
table_read_null_96:
  br label %table_read_end_98
table_read_real_97:
  %t476 = bitcast i8* %t474 to { i64, i64, i32*, i8** }*
  %t477 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t476, i32 0, i32 0
  %t478 = load i64, i64* %t477
  %t479 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t476, i32 0, i32 2
  %t480 = load i32*, i32** %t479
  %t481 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t476, i32 0, i32 3
  %t482 = load i8**, i8*** %t481
  br label %table_read_end_98
table_read_end_98:
  %t483 = phi i64 [ 0, %table_read_null_96 ], [ %t478, %table_read_real_97 ]
  %t484 = phi i32* [ null, %table_read_null_96 ], [ %t480, %table_read_real_97 ]
  %t485 = phi i8** [ null, %table_read_null_96 ], [ %t482, %table_read_real_97 ]
  %t487 = icmp ult i64 %t473, %t483
  br i1 %t487, label %table_idx_ok_99, label %table_idx_oob_100
table_idx_ok_99:
  %t488 = getelementptr inbounds i32, i32* %t484, i64 %t473
  %t489 = load i32, i32* %t488
  %t490 = getelementptr inbounds %Item, %Item* %t486, i32 0, i32 0
  store i32 %t489, i32* %t490
  %t491 = getelementptr inbounds i8*, i8** %t485, i64 %t473
  %t492 = load i8*, i8** %t491
  call void @star_rc_retain(i8* %t492)
  %t493 = load i8*, i8** %t491
  %t494 = getelementptr inbounds %Item, %Item* %t486, i32 0, i32 1
  store i8* %t493, i8** %t494
  br label %table_idx_end_101
table_idx_oob_100:
  store %Item zeroinitializer, %Item* %t486
  br label %table_idx_end_101
table_idx_end_101:
  %t495 = load %Item, %Item* %t486
  store %Item %t495, %Item* %t496
  %t497 = getelementptr inbounds %Item, %Item* %t496, i32 0, i32 1
  %t498 = load i8*, i8** %t497
  %t499 = load i8*, i8** %t497
  call void @star_rc_retain(i8* %t499)
  call void @star_rc_release(i8* %t498)
  %t500 = getelementptr inbounds [38 x i8], [38 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t500, i8* %t471, i8* %t498)
  store i8* null, i8** %t501
  store i32 0, i32* %t502
  br label %while_cond_102
while_cond_102:
  %t503 = load i32, i32* %t502
  %t504 = icmp slt i32 %t503, 3000
  br i1 %t504, label %while_body_103, label %while_else_104
while_body_103:
  %t505 = load i8*, i8** %t501
  %t506 = icmp eq i8* %t505, null
  br i1 %t506, label %table_cow_alloc_106, label %table_cow_check_107
table_cow_alloc_106:
  %t507 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t508 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t509 = ptrtoint { i64, i64, i32*, i8** }* %t508 to i64
  %t510 = call i8* @star_rc_alloc(i64 %t509, i8* %t507)
  %t511 = bitcast i8* %t510 to { i64, i64, i32*, i8** }*
  %t512 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t511, i32 0, i32 0
  store i64 0, i64* %t512
  %t513 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t511, i32 0, i32 1
  store i64 0, i64* %t513
  %t514 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t511, i32 0, i32 2
  store i32* null, i32** %t514
  %t515 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t511, i32 0, i32 3
  store i8** null, i8*** %t515
  store i8* %t510, i8** %t501
  br label %table_cow_done_108
table_cow_check_107:
  %t516 = getelementptr inbounds i8, i8* %t505, i64 -16
  %t517 = bitcast i8* %t516 to i64*
  %t518 = load atomic i64, i64* %t517 seq_cst, align 8
  %t519 = icmp eq i64 %t518, 1
  br i1 %t519, label %table_cow_done_108, label %table_cow_clone_109
table_cow_clone_109:
  %t520 = bitcast i8* %t505 to { i64, i64, i32*, i8** }*
  %t521 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t520, i32 0, i32 0
  %t522 = load i64, i64* %t521
  %t523 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t520, i32 0, i32 1
  %t524 = load i64, i64* %t523
  %t525 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t526 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t527 = ptrtoint { i64, i64, i32*, i8** }* %t526 to i64
  %t528 = call i8* @star_rc_alloc(i64 %t527, i8* %t525)
  %t529 = bitcast i8* %t528 to { i64, i64, i32*, i8** }*
  %t530 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t529, i32 0, i32 0
  store i64 %t522, i64* %t530
  %t531 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t529, i32 0, i32 1
  store i64 %t524, i64* %t531
  %t532 = getelementptr i32, i32* null, i32 1
  %t533 = ptrtoint i32* %t532 to i64
  %t534 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t520, i32 0, i32 2
  %t535 = load i32*, i32** %t534
  %t536 = mul i64 %t524, %t533
  %t537 = call i8* @malloc(i64 %t536)
  %t538 = bitcast i8* %t537 to i32*
  %t539 = icmp sgt i64 %t522, 0
  br i1 %t539, label %table_cow_copy_110, label %table_cow_after_copy_111
table_cow_copy_110:
  %t540 = mul i64 %t522, %t533
  %t541 = bitcast i32* %t535 to i8*
  call i8* @memcpy(i8* %t537, i8* %t541, i64 %t540)
  br label %table_cow_after_copy_111
table_cow_after_copy_111:
  %t542 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t529, i32 0, i32 2
  store i32* %t538, i32** %t542
  %t543 = getelementptr i8*, i8** null, i32 1
  %t544 = ptrtoint i8** %t543 to i64
  %t545 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t520, i32 0, i32 3
  %t546 = load i8**, i8*** %t545
  %t547 = mul i64 %t524, %t544
  %t548 = call i8* @malloc(i64 %t547)
  %t549 = bitcast i8* %t548 to i8**
  %t550 = icmp sgt i64 %t522, 0
  br i1 %t550, label %table_cow_copy_112, label %table_cow_after_copy_113
table_cow_copy_112:
  %t551 = mul i64 %t522, %t544
  %t552 = bitcast i8** %t546 to i8*
  call i8* @memcpy(i8* %t548, i8* %t552, i64 %t551)
  store i64 0, i64* %t553
  br label %table_cow_retain_cond_114
table_cow_retain_cond_114:
  %t554 = load i64, i64* %t553
  %t555 = icmp slt i64 %t554, %t522
  br i1 %t555, label %table_cow_retain_body_115, label %table_cow_retain_end_116
table_cow_retain_body_115:
  %t556 = getelementptr inbounds i8*, i8** %t549, i64 %t554
  %t557 = load i8*, i8** %t556
  call void @star_rc_retain(i8* %t557)
  %t558 = add i64 %t554, 1
  store i64 %t558, i64* %t553
  br label %table_cow_retain_cond_114
table_cow_retain_end_116:
  br label %table_cow_after_copy_113
table_cow_after_copy_113:
  %t559 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t529, i32 0, i32 3
  store i8** %t549, i8*** %t559
  call void @star_rc_release(i8* %t505)
  store i8* %t528, i8** %t501
  br label %table_cow_done_108
table_cow_done_108:
  %t560 = load i8*, i8** %t501
  %t561 = bitcast i8* %t560 to { i64, i64, i32*, i8** }*
  %t562 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t561, i32 0, i32 0
  %t563 = load i64, i64* %t562
  %t564 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t561, i32 0, i32 1
  %t565 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t561, i32 0, i32 2
  %t566 = load i32*, i32** %t565
  %t567 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t561, i32 0, i32 3
  %t568 = load i8**, i8*** %t567
  %t570 = load i32, i32* %t502
  %t571 = getelementptr inbounds %Item, %Item* %t569, i32 0, i32 0
  store i32 %t570, i32* %t571
  %t572 = load i32, i32* %t502
  %t573 = getelementptr inbounds [7 x i8], [7 x i8]* @.str.8, i64 0, i64 0
  %t574 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t573, i32 %t572)
  %t575 = add i32 %t574, 1
  %t576 = sext i32 %t575 to i64
  %t577 = call i8* @star_rc_alloc(i64 %t576, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t577, i64 %t576, i8* %t573, i32 %t572)
  %t578 = getelementptr inbounds %Item, %Item* %t569, i32 0, i32 1
  store i8* %t577, i8** %t578
  %t579 = load %Item, %Item* %t569
  %t580 = load i64, i64* %t564
  %t581 = load i64, i64* %t562
  %t582 = load i32*, i32** %t565
  %t583 = load i8**, i8*** %t567
  %t584 = icmp sge i64 %t581, %t580
  br i1 %t584, label %table_push_grow_117, label %table_push_store_118
table_push_grow_117:
  %t585 = mul i64 %t580, 2
  %t586 = icmp sgt i64 %t585, 0
  %t587 = select i1 %t586, i64 %t585, i64 1
  %t588 = getelementptr i32, i32* null, i32 1
  %t589 = ptrtoint i32* %t588 to i64
  %t590 = mul i64 %t587, %t589
  %t591 = call i8* @malloc(i64 %t590)
  %t592 = bitcast i8* %t591 to i32*
  %t593 = icmp sgt i64 %t580, 0
  br i1 %t593, label %table_push_copy_119, label %table_push_after_copy_120
table_push_copy_119:
  %t594 = mul i64 %t581, %t589
  %t595 = bitcast i32* %t582 to i8*
  call i8* @memcpy(i8* %t591, i8* %t595, i64 %t594)
  call void @free(i8* %t595)
  br label %table_push_after_copy_120
table_push_after_copy_120:
  store i32* %t592, i32** %t565
  %t596 = getelementptr i8*, i8** null, i32 1
  %t597 = ptrtoint i8** %t596 to i64
  %t598 = mul i64 %t587, %t597
  %t599 = call i8* @malloc(i64 %t598)
  %t600 = bitcast i8* %t599 to i8**
  %t601 = icmp sgt i64 %t580, 0
  br i1 %t601, label %table_push_copy_121, label %table_push_after_copy_122
table_push_copy_121:
  %t602 = mul i64 %t581, %t597
  %t603 = bitcast i8** %t583 to i8*
  call i8* @memcpy(i8* %t599, i8* %t603, i64 %t602)
  call void @free(i8* %t603)
  br label %table_push_after_copy_122
table_push_after_copy_122:
  store i8** %t600, i8*** %t567
  store i64 %t587, i64* %t564
  br label %table_push_store_118
table_push_store_118:
  %t604 = load i32*, i32** %t565
  %t605 = extractvalue %Item %t579, 0
  %t606 = getelementptr inbounds i32, i32* %t604, i64 %t581
  store i32 %t605, i32* %t606
  %t607 = load i8**, i8*** %t567
  %t608 = extractvalue %Item %t579, 1
  %t609 = getelementptr inbounds i8*, i8** %t607, i64 %t581
  store i8* %t608, i8** %t609
  %t610 = add i64 %t581, 1
  store i64 %t610, i64* %t562
  %t611 = load i32, i32* %t502
  %t612 = icmp eq i32 3, 0
  %t613 = icmp eq i32 %t611, -2147483648
  %t614 = icmp eq i32 3, -1
  %t615 = and i1 %t613, %t614
  %t616 = or i1 %t612, %t615
  br i1 %t616, label %int_div_fail_123, label %int_div_ok_124
int_div_fail_123:
  %t617 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.9, i64 0, i64 0
  call i32 @puts(i8* %t617)
  call void @exit(i32 1)
  unreachable
int_div_ok_124:
  %t618 = srem i32 %t611, 3
  %t619 = icmp eq i32 %t618, 0
  br i1 %t619, label %if_then_125, label %if_else_126
if_then_125:
  %t621 = load i8*, i8** %t501
  %t622 = icmp eq i8* %t621, null
  br i1 %t622, label %table_cow_alloc_128, label %table_cow_check_129
table_cow_alloc_128:
  %t623 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t624 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t625 = ptrtoint { i64, i64, i32*, i8** }* %t624 to i64
  %t626 = call i8* @star_rc_alloc(i64 %t625, i8* %t623)
  %t627 = bitcast i8* %t626 to { i64, i64, i32*, i8** }*
  %t628 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t627, i32 0, i32 0
  store i64 0, i64* %t628
  %t629 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t627, i32 0, i32 1
  store i64 0, i64* %t629
  %t630 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t627, i32 0, i32 2
  store i32* null, i32** %t630
  %t631 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t627, i32 0, i32 3
  store i8** null, i8*** %t631
  store i8* %t626, i8** %t501
  br label %table_cow_done_130
table_cow_check_129:
  %t632 = getelementptr inbounds i8, i8* %t621, i64 -16
  %t633 = bitcast i8* %t632 to i64*
  %t634 = load atomic i64, i64* %t633 seq_cst, align 8
  %t635 = icmp eq i64 %t634, 1
  br i1 %t635, label %table_cow_done_130, label %table_cow_clone_131
table_cow_clone_131:
  %t636 = bitcast i8* %t621 to { i64, i64, i32*, i8** }*
  %t637 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t636, i32 0, i32 0
  %t638 = load i64, i64* %t637
  %t639 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t636, i32 0, i32 1
  %t640 = load i64, i64* %t639
  %t641 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t642 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t643 = ptrtoint { i64, i64, i32*, i8** }* %t642 to i64
  %t644 = call i8* @star_rc_alloc(i64 %t643, i8* %t641)
  %t645 = bitcast i8* %t644 to { i64, i64, i32*, i8** }*
  %t646 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t645, i32 0, i32 0
  store i64 %t638, i64* %t646
  %t647 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t645, i32 0, i32 1
  store i64 %t640, i64* %t647
  %t648 = getelementptr i32, i32* null, i32 1
  %t649 = ptrtoint i32* %t648 to i64
  %t650 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t636, i32 0, i32 2
  %t651 = load i32*, i32** %t650
  %t652 = mul i64 %t640, %t649
  %t653 = call i8* @malloc(i64 %t652)
  %t654 = bitcast i8* %t653 to i32*
  %t655 = icmp sgt i64 %t638, 0
  br i1 %t655, label %table_cow_copy_132, label %table_cow_after_copy_133
table_cow_copy_132:
  %t656 = mul i64 %t638, %t649
  %t657 = bitcast i32* %t651 to i8*
  call i8* @memcpy(i8* %t653, i8* %t657, i64 %t656)
  br label %table_cow_after_copy_133
table_cow_after_copy_133:
  %t658 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t645, i32 0, i32 2
  store i32* %t654, i32** %t658
  %t659 = getelementptr i8*, i8** null, i32 1
  %t660 = ptrtoint i8** %t659 to i64
  %t661 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t636, i32 0, i32 3
  %t662 = load i8**, i8*** %t661
  %t663 = mul i64 %t640, %t660
  %t664 = call i8* @malloc(i64 %t663)
  %t665 = bitcast i8* %t664 to i8**
  %t666 = icmp sgt i64 %t638, 0
  br i1 %t666, label %table_cow_copy_134, label %table_cow_after_copy_135
table_cow_copy_134:
  %t667 = mul i64 %t638, %t660
  %t668 = bitcast i8** %t662 to i8*
  call i8* @memcpy(i8* %t664, i8* %t668, i64 %t667)
  store i64 0, i64* %t669
  br label %table_cow_retain_cond_136
table_cow_retain_cond_136:
  %t670 = load i64, i64* %t669
  %t671 = icmp slt i64 %t670, %t638
  br i1 %t671, label %table_cow_retain_body_137, label %table_cow_retain_end_138
table_cow_retain_body_137:
  %t672 = getelementptr inbounds i8*, i8** %t665, i64 %t670
  %t673 = load i8*, i8** %t672
  call void @star_rc_retain(i8* %t673)
  %t674 = add i64 %t670, 1
  store i64 %t674, i64* %t669
  br label %table_cow_retain_cond_136
table_cow_retain_end_138:
  br label %table_cow_after_copy_135
table_cow_after_copy_135:
  %t675 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t645, i32 0, i32 3
  store i8** %t665, i8*** %t675
  call void @star_rc_release(i8* %t621)
  store i8* %t644, i8** %t501
  br label %table_cow_done_130
table_cow_done_130:
  %t676 = load i8*, i8** %t501
  %t677 = bitcast i8* %t676 to { i64, i64, i32*, i8** }*
  %t678 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t677, i32 0, i32 0
  %t679 = load i64, i64* %t678
  %t680 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t677, i32 0, i32 1
  %t681 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t677, i32 0, i32 2
  %t682 = load i32*, i32** %t681
  %t683 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t677, i32 0, i32 3
  %t684 = load i8**, i8*** %t683
  %t686 = icmp eq i64 %t679, 0
  br i1 %t686, label %table_pop_empty_139, label %table_pop_nonempty_140
table_pop_nonempty_140:
  %t687 = sub i64 %t679, 1
  store i64 %t687, i64* %t678
  %t688 = getelementptr inbounds i32, i32* %t682, i64 %t687
  %t689 = load i32, i32* %t688
  %t690 = getelementptr inbounds %Item, %Item* %t685, i32 0, i32 0
  store i32 %t689, i32* %t690
  %t691 = getelementptr inbounds i8*, i8** %t684, i64 %t687
  %t692 = load i8*, i8** %t691
  %t693 = getelementptr inbounds %Item, %Item* %t685, i32 0, i32 1
  store i8* %t692, i8** %t693
  br label %table_pop_end_141
table_pop_empty_139:
  store %Item zeroinitializer, %Item* %t685
  br label %table_pop_end_141
table_pop_end_141:
  %t694 = load %Item, %Item* %t685
  store %Item %t694, %Item* %t620
  %t695 = getelementptr inbounds %Item, %Item* %t620, i32 0, i32 1
  %t696 = load i8*, i8** %t695
  %t697 = load i8*, i8** %t695
  call void @star_rc_retain(i8* %t697)
  %t698 = call i32 @strlen(i8* %t696)
  call void @star_rc_release(i8* %t696)
  %t699 = icmp eq i32 %t698, 0
  br i1 %t699, label %if_then_142, label %if_else_143
if_then_142:
  %t700 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.10, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t700)
  call i32 (i8*, ...) @printf(i8* %t700)
  %t701 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t701)
  br label %if_end_144
if_else_143:
  br label %if_end_144
if_end_144:
  %t702 = getelementptr inbounds %Item, %Item* %t620, i32 0, i32 1
  %t703 = load i8*, i8** %t702
  call void @star_rc_release(i8* %t703)
  br label %if_end_127
if_else_126:
  br label %if_end_127
if_end_127:
  %t704 = load i32, i32* %t502
  %t705 = add i32 %t704, 1
  store i32 %t705, i32* %t502
  br label %while_cond_102
while_else_104:
  br label %while_end_105
while_end_105:
  %t706 = load i8*, i8** %t501
  %t707 = icmp eq i8* %t706, null
  br i1 %t707, label %table_read_null_145, label %table_read_real_146
table_read_null_145:
  br label %table_read_end_147
table_read_real_146:
  %t708 = bitcast i8* %t706 to { i64, i64, i32*, i8** }*
  %t709 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t708, i32 0, i32 0
  %t710 = load i64, i64* %t709
  %t711 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t708, i32 0, i32 2
  %t712 = load i32*, i32** %t711
  %t713 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t708, i32 0, i32 3
  %t714 = load i8**, i8*** %t713
  br label %table_read_end_147
table_read_end_147:
  %t715 = phi i64 [ 0, %table_read_null_145 ], [ %t710, %table_read_real_146 ]
  %t716 = phi i32* [ null, %table_read_null_145 ], [ %t712, %table_read_real_146 ]
  %t717 = phi i8** [ null, %table_read_null_145 ], [ %t714, %table_read_real_146 ]
  %t718 = trunc i64 %t715 to i32
  %t719 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t719, i32 %t718)
  %t720 = load i8*, i8** %t501
  call void @star_rc_release(i8* %t720)
  %t721 = getelementptr inbounds %Item, %Item* %t496, i32 0, i32 1
  %t722 = load i8*, i8** %t721
  call void @star_rc_release(i8* %t722)
  %t723 = getelementptr inbounds %Item, %Item* %t469, i32 0, i32 1
  %t724 = load i8*, i8** %t723
  call void @star_rc_release(i8* %t724)
  %t725 = getelementptr inbounds %Item, %Item* %t441, i32 0, i32 1
  %t726 = load i8*, i8** %t725
  call void @star_rc_release(i8* %t726)
  %t727 = getelementptr inbounds %Item, %Item* %t414, i32 0, i32 1
  %t728 = load i8*, i8** %t727
  call void @star_rc_release(i8* %t728)
  %t729 = load i8*, i8** %t250
  call void @star_rc_release(i8* %t729)
  %t730 = getelementptr inbounds %Item, %Item* %t246, i32 0, i32 1
  %t731 = load i8*, i8** %t730
  call void @star_rc_release(i8* %t731)
  %t732 = getelementptr inbounds %Item, %Item* %t219, i32 0, i32 1
  %t733 = load i8*, i8** %t732
  call void @star_rc_release(i8* %t733)
  %t734 = getelementptr inbounds %Item, %Item* %t192, i32 0, i32 1
  %t735 = load i8*, i8** %t734
  call void @star_rc_release(i8* %t735)
  %t736 = getelementptr inbounds %Item, %Item* %t165, i32 0, i32 1
  %t737 = load i8*, i8** %t736
  call void @star_rc_release(i8* %t737)
  %t738 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t738)
  ret i32 0
}


; par/swarm worker functions
define void @table_release_s_Item(i8* %objp) {
entry:
  %t15 = alloca i64
  %t7 = bitcast i8* %objp to { i64, i64, i32*, i8** }*
  %t8 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t7, i32 0, i32 0
  %t9 = load i64, i64* %t8
  %t10 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t7, i32 0, i32 2
  %t11 = load i32*, i32** %t10
  %t12 = bitcast i32* %t11 to i8*
  call void @free(i8* %t12)
  %t13 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t7, i32 0, i32 3
  %t14 = load i8**, i8*** %t13
  store i64 0, i64* %t15
  br label %table_release_cond_7
table_release_cond_7:
  %t16 = load i64, i64* %t15
  %t17 = icmp slt i64 %t16, %t9
  br i1 %t17, label %table_release_body_8, label %table_release_end_9
table_release_body_8:
  %t18 = getelementptr inbounds i8*, i8** %t14, i64 %t16
  %t19 = load i8*, i8** %t18
  call void @star_rc_release(i8* %t19)
  %t20 = add i64 %t16, 1
  store i64 %t20, i64* %t15
  br label %table_release_cond_7
table_release_end_9:
  %t21 = bitcast i8** %t14 to i8*
  call void @free(i8* %t21)
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
