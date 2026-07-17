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

%Enemy = type { i32, i8* }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t0 = alloca i8*
  %t78 = alloca i64
  %t94 = alloca %Enemy
  %t178 = alloca i64
  %t194 = alloca %Enemy
  %t278 = alloca i64
  %t294 = alloca %Enemy
  %t357 = alloca %Enemy
  %t367 = alloca %Enemy
  %t384 = alloca %Enemy
  %t394 = alloca %Enemy
  %t411 = alloca %Enemy
  %t421 = alloca %Enemy
  %t438 = alloca %Enemy
  %t448 = alloca %Enemy
  %t452 = alloca %Enemy
  %t506 = alloca i64
  %t528 = alloca %Enemy
  %t544 = alloca %Enemy
  %t554 = alloca %Enemy
  %t571 = alloca %Enemy
  %t581 = alloca %Enemy
  %t585 = alloca %Enemy
  %t634 = alloca i64
  %t650 = alloca %Enemy
  %t693 = alloca %Enemy
  %t703 = alloca %Enemy
  %t707 = alloca i8*
  %t708 = alloca %Enemy
  %t757 = alloca i64
  %t773 = alloca %Enemy
  %t786 = alloca i8*
  %t835 = alloca i64
  %t851 = alloca %Enemy
  %t887 = alloca i8*
  %t938 = alloca i64
  %t954 = alloca %Enemy
  %t1030 = alloca %Enemy
  %t1040 = alloca %Enemy
  %t1056 = alloca %Enemy
  %t1066 = alloca %Enemy
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  store i8* null, i8** %t0
  %t1 = load i8*, i8** %t0
  %t2 = icmp eq i8* %t1, null
  br i1 %t2, label %table_read_null_0, label %table_read_real_1
table_read_null_0:
  br label %table_read_end_2
table_read_real_1:
  %t3 = bitcast i8* %t1 to { i64, i64, i32*, i8** }*
  %t4 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t3, i32 0, i32 0
  %t5 = load i64, i64* %t4
  %t6 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t3, i32 0, i32 2
  %t7 = load i32*, i32** %t6
  %t8 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t3, i32 0, i32 3
  %t9 = load i8**, i8*** %t8
  br label %table_read_end_2
table_read_end_2:
  %t10 = phi i64 [ 0, %table_read_null_0 ], [ %t5, %table_read_real_1 ]
  %t11 = phi i32* [ null, %table_read_null_0 ], [ %t7, %table_read_real_1 ]
  %t12 = phi i8** [ null, %table_read_null_0 ], [ %t9, %table_read_real_1 ]
  %t13 = trunc i64 %t10 to i32
  %t14 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t14, i32 %t13)
  %t15 = load i8*, i8** %t0
  %t16 = icmp eq i8* %t15, null
  br i1 %t16, label %table_cow_alloc_3, label %table_cow_check_4
table_cow_alloc_3:
  %t32 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t33 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t34 = ptrtoint { i64, i64, i32*, i8** }* %t33 to i64
  %t35 = call i8* @star_rc_alloc(i64 %t34, i8* %t32)
  %t36 = bitcast i8* %t35 to { i64, i64, i32*, i8** }*
  %t37 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t36, i32 0, i32 0
  store i64 0, i64* %t37
  %t38 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t36, i32 0, i32 1
  store i64 0, i64* %t38
  %t39 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t36, i32 0, i32 2
  store i32* null, i32** %t39
  %t40 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t36, i32 0, i32 3
  store i8** null, i8*** %t40
  store i8* %t35, i8** %t0
  br label %table_cow_done_5
table_cow_check_4:
  %t41 = getelementptr inbounds i8, i8* %t15, i64 -16
  %t42 = bitcast i8* %t41 to i64*
  %t43 = load atomic i64, i64* %t42 seq_cst, align 8
  %t44 = icmp eq i64 %t43, 1
  br i1 %t44, label %table_cow_done_5, label %table_cow_clone_9
table_cow_clone_9:
  %t45 = bitcast i8* %t15 to { i64, i64, i32*, i8** }*
  %t46 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t45, i32 0, i32 0
  %t47 = load i64, i64* %t46
  %t48 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t45, i32 0, i32 1
  %t49 = load i64, i64* %t48
  %t50 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t51 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t52 = ptrtoint { i64, i64, i32*, i8** }* %t51 to i64
  %t53 = call i8* @star_rc_alloc(i64 %t52, i8* %t50)
  %t54 = bitcast i8* %t53 to { i64, i64, i32*, i8** }*
  %t55 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t54, i32 0, i32 0
  store i64 %t47, i64* %t55
  %t56 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t54, i32 0, i32 1
  store i64 %t49, i64* %t56
  %t57 = getelementptr i32, i32* null, i32 1
  %t58 = ptrtoint i32* %t57 to i64
  %t59 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t45, i32 0, i32 2
  %t60 = load i32*, i32** %t59
  %t61 = mul i64 %t49, %t58
  %t62 = call i8* @malloc(i64 %t61)
  %t63 = bitcast i8* %t62 to i32*
  %t64 = icmp sgt i64 %t47, 0
  br i1 %t64, label %table_cow_copy_10, label %table_cow_after_copy_11
table_cow_copy_10:
  %t65 = mul i64 %t47, %t58
  %t66 = bitcast i32* %t60 to i8*
  call i8* @memcpy(i8* %t62, i8* %t66, i64 %t65)
  br label %table_cow_after_copy_11
table_cow_after_copy_11:
  %t67 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t54, i32 0, i32 2
  store i32* %t63, i32** %t67
  %t68 = getelementptr i8*, i8** null, i32 1
  %t69 = ptrtoint i8** %t68 to i64
  %t70 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t45, i32 0, i32 3
  %t71 = load i8**, i8*** %t70
  %t72 = mul i64 %t49, %t69
  %t73 = call i8* @malloc(i64 %t72)
  %t74 = bitcast i8* %t73 to i8**
  %t75 = icmp sgt i64 %t47, 0
  br i1 %t75, label %table_cow_copy_12, label %table_cow_after_copy_13
table_cow_copy_12:
  %t76 = mul i64 %t47, %t69
  %t77 = bitcast i8** %t71 to i8*
  call i8* @memcpy(i8* %t73, i8* %t77, i64 %t76)
  store i64 0, i64* %t78
  br label %table_cow_retain_cond_14
table_cow_retain_cond_14:
  %t79 = load i64, i64* %t78
  %t80 = icmp slt i64 %t79, %t47
  br i1 %t80, label %table_cow_retain_body_15, label %table_cow_retain_end_16
table_cow_retain_body_15:
  %t81 = getelementptr inbounds i8*, i8** %t74, i64 %t79
  %t82 = load i8*, i8** %t81
  call void @star_rc_retain(i8* %t82)
  %t83 = add i64 %t79, 1
  store i64 %t83, i64* %t78
  br label %table_cow_retain_cond_14
table_cow_retain_end_16:
  br label %table_cow_after_copy_13
table_cow_after_copy_13:
  %t84 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t54, i32 0, i32 3
  store i8** %t74, i8*** %t84
  call void @star_rc_release(i8* %t15)
  store i8* %t53, i8** %t0
  br label %table_cow_done_5
table_cow_done_5:
  %t85 = load i8*, i8** %t0
  %t86 = bitcast i8* %t85 to { i64, i64, i32*, i8** }*
  %t87 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t86, i32 0, i32 0
  %t88 = load i64, i64* %t87
  %t89 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t86, i32 0, i32 1
  %t90 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t86, i32 0, i32 2
  %t91 = load i32*, i32** %t90
  %t92 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t86, i32 0, i32 3
  %t93 = load i8**, i8*** %t92
  %t95 = getelementptr inbounds %Enemy, %Enemy* %t94, i32 0, i32 0
  store i32 10, i32* %t95
  %t96 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t97 = getelementptr inbounds %Enemy, %Enemy* %t94, i32 0, i32 1
  store i8* %t96, i8** %t97
  %t98 = load %Enemy, %Enemy* %t94
  %t99 = load i64, i64* %t89
  %t100 = load i64, i64* %t87
  %t101 = load i32*, i32** %t90
  %t102 = load i8**, i8*** %t92
  %t103 = icmp sge i64 %t100, %t99
  br i1 %t103, label %table_push_grow_17, label %table_push_store_18
table_push_grow_17:
  %t104 = mul i64 %t99, 2
  %t105 = icmp sgt i64 %t104, 0
  %t106 = select i1 %t105, i64 %t104, i64 1
  %t107 = getelementptr i32, i32* null, i32 1
  %t108 = ptrtoint i32* %t107 to i64
  %t109 = mul i64 %t106, %t108
  %t110 = call i8* @malloc(i64 %t109)
  %t111 = bitcast i8* %t110 to i32*
  %t112 = icmp sgt i64 %t99, 0
  br i1 %t112, label %table_push_copy_19, label %table_push_after_copy_20
table_push_copy_19:
  %t113 = mul i64 %t100, %t108
  %t114 = bitcast i32* %t101 to i8*
  call i8* @memcpy(i8* %t110, i8* %t114, i64 %t113)
  call void @free(i8* %t114)
  br label %table_push_after_copy_20
table_push_after_copy_20:
  store i32* %t111, i32** %t90
  %t115 = getelementptr i8*, i8** null, i32 1
  %t116 = ptrtoint i8** %t115 to i64
  %t117 = mul i64 %t106, %t116
  %t118 = call i8* @malloc(i64 %t117)
  %t119 = bitcast i8* %t118 to i8**
  %t120 = icmp sgt i64 %t99, 0
  br i1 %t120, label %table_push_copy_21, label %table_push_after_copy_22
table_push_copy_21:
  %t121 = mul i64 %t100, %t116
  %t122 = bitcast i8** %t102 to i8*
  call i8* @memcpy(i8* %t118, i8* %t122, i64 %t121)
  call void @free(i8* %t122)
  br label %table_push_after_copy_22
table_push_after_copy_22:
  store i8** %t119, i8*** %t92
  store i64 %t106, i64* %t89
  br label %table_push_store_18
table_push_store_18:
  %t123 = load i32*, i32** %t90
  %t124 = extractvalue %Enemy %t98, 0
  %t125 = getelementptr inbounds i32, i32* %t123, i64 %t100
  store i32 %t124, i32* %t125
  %t126 = load i8**, i8*** %t92
  %t127 = extractvalue %Enemy %t98, 1
  %t128 = getelementptr inbounds i8*, i8** %t126, i64 %t100
  store i8* %t127, i8** %t128
  %t129 = add i64 %t100, 1
  store i64 %t129, i64* %t87
  %t130 = load i8*, i8** %t0
  %t131 = icmp eq i8* %t130, null
  br i1 %t131, label %table_cow_alloc_23, label %table_cow_check_24
table_cow_alloc_23:
  %t132 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t133 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t134 = ptrtoint { i64, i64, i32*, i8** }* %t133 to i64
  %t135 = call i8* @star_rc_alloc(i64 %t134, i8* %t132)
  %t136 = bitcast i8* %t135 to { i64, i64, i32*, i8** }*
  %t137 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t136, i32 0, i32 0
  store i64 0, i64* %t137
  %t138 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t136, i32 0, i32 1
  store i64 0, i64* %t138
  %t139 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t136, i32 0, i32 2
  store i32* null, i32** %t139
  %t140 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t136, i32 0, i32 3
  store i8** null, i8*** %t140
  store i8* %t135, i8** %t0
  br label %table_cow_done_25
table_cow_check_24:
  %t141 = getelementptr inbounds i8, i8* %t130, i64 -16
  %t142 = bitcast i8* %t141 to i64*
  %t143 = load atomic i64, i64* %t142 seq_cst, align 8
  %t144 = icmp eq i64 %t143, 1
  br i1 %t144, label %table_cow_done_25, label %table_cow_clone_26
table_cow_clone_26:
  %t145 = bitcast i8* %t130 to { i64, i64, i32*, i8** }*
  %t146 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t145, i32 0, i32 0
  %t147 = load i64, i64* %t146
  %t148 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t145, i32 0, i32 1
  %t149 = load i64, i64* %t148
  %t150 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t151 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t152 = ptrtoint { i64, i64, i32*, i8** }* %t151 to i64
  %t153 = call i8* @star_rc_alloc(i64 %t152, i8* %t150)
  %t154 = bitcast i8* %t153 to { i64, i64, i32*, i8** }*
  %t155 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t154, i32 0, i32 0
  store i64 %t147, i64* %t155
  %t156 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t154, i32 0, i32 1
  store i64 %t149, i64* %t156
  %t157 = getelementptr i32, i32* null, i32 1
  %t158 = ptrtoint i32* %t157 to i64
  %t159 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t145, i32 0, i32 2
  %t160 = load i32*, i32** %t159
  %t161 = mul i64 %t149, %t158
  %t162 = call i8* @malloc(i64 %t161)
  %t163 = bitcast i8* %t162 to i32*
  %t164 = icmp sgt i64 %t147, 0
  br i1 %t164, label %table_cow_copy_27, label %table_cow_after_copy_28
table_cow_copy_27:
  %t165 = mul i64 %t147, %t158
  %t166 = bitcast i32* %t160 to i8*
  call i8* @memcpy(i8* %t162, i8* %t166, i64 %t165)
  br label %table_cow_after_copy_28
table_cow_after_copy_28:
  %t167 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t154, i32 0, i32 2
  store i32* %t163, i32** %t167
  %t168 = getelementptr i8*, i8** null, i32 1
  %t169 = ptrtoint i8** %t168 to i64
  %t170 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t145, i32 0, i32 3
  %t171 = load i8**, i8*** %t170
  %t172 = mul i64 %t149, %t169
  %t173 = call i8* @malloc(i64 %t172)
  %t174 = bitcast i8* %t173 to i8**
  %t175 = icmp sgt i64 %t147, 0
  br i1 %t175, label %table_cow_copy_29, label %table_cow_after_copy_30
table_cow_copy_29:
  %t176 = mul i64 %t147, %t169
  %t177 = bitcast i8** %t171 to i8*
  call i8* @memcpy(i8* %t173, i8* %t177, i64 %t176)
  store i64 0, i64* %t178
  br label %table_cow_retain_cond_31
table_cow_retain_cond_31:
  %t179 = load i64, i64* %t178
  %t180 = icmp slt i64 %t179, %t147
  br i1 %t180, label %table_cow_retain_body_32, label %table_cow_retain_end_33
table_cow_retain_body_32:
  %t181 = getelementptr inbounds i8*, i8** %t174, i64 %t179
  %t182 = load i8*, i8** %t181
  call void @star_rc_retain(i8* %t182)
  %t183 = add i64 %t179, 1
  store i64 %t183, i64* %t178
  br label %table_cow_retain_cond_31
table_cow_retain_end_33:
  br label %table_cow_after_copy_30
table_cow_after_copy_30:
  %t184 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t154, i32 0, i32 3
  store i8** %t174, i8*** %t184
  call void @star_rc_release(i8* %t130)
  store i8* %t153, i8** %t0
  br label %table_cow_done_25
table_cow_done_25:
  %t185 = load i8*, i8** %t0
  %t186 = bitcast i8* %t185 to { i64, i64, i32*, i8** }*
  %t187 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t186, i32 0, i32 0
  %t188 = load i64, i64* %t187
  %t189 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t186, i32 0, i32 1
  %t190 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t186, i32 0, i32 2
  %t191 = load i32*, i32** %t190
  %t192 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t186, i32 0, i32 3
  %t193 = load i8**, i8*** %t192
  %t195 = getelementptr inbounds %Enemy, %Enemy* %t194, i32 0, i32 0
  store i32 20, i32* %t195
  %t196 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t197 = getelementptr inbounds %Enemy, %Enemy* %t194, i32 0, i32 1
  store i8* %t196, i8** %t197
  %t198 = load %Enemy, %Enemy* %t194
  %t199 = load i64, i64* %t189
  %t200 = load i64, i64* %t187
  %t201 = load i32*, i32** %t190
  %t202 = load i8**, i8*** %t192
  %t203 = icmp sge i64 %t200, %t199
  br i1 %t203, label %table_push_grow_34, label %table_push_store_35
table_push_grow_34:
  %t204 = mul i64 %t199, 2
  %t205 = icmp sgt i64 %t204, 0
  %t206 = select i1 %t205, i64 %t204, i64 1
  %t207 = getelementptr i32, i32* null, i32 1
  %t208 = ptrtoint i32* %t207 to i64
  %t209 = mul i64 %t206, %t208
  %t210 = call i8* @malloc(i64 %t209)
  %t211 = bitcast i8* %t210 to i32*
  %t212 = icmp sgt i64 %t199, 0
  br i1 %t212, label %table_push_copy_36, label %table_push_after_copy_37
table_push_copy_36:
  %t213 = mul i64 %t200, %t208
  %t214 = bitcast i32* %t201 to i8*
  call i8* @memcpy(i8* %t210, i8* %t214, i64 %t213)
  call void @free(i8* %t214)
  br label %table_push_after_copy_37
table_push_after_copy_37:
  store i32* %t211, i32** %t190
  %t215 = getelementptr i8*, i8** null, i32 1
  %t216 = ptrtoint i8** %t215 to i64
  %t217 = mul i64 %t206, %t216
  %t218 = call i8* @malloc(i64 %t217)
  %t219 = bitcast i8* %t218 to i8**
  %t220 = icmp sgt i64 %t199, 0
  br i1 %t220, label %table_push_copy_38, label %table_push_after_copy_39
table_push_copy_38:
  %t221 = mul i64 %t200, %t216
  %t222 = bitcast i8** %t202 to i8*
  call i8* @memcpy(i8* %t218, i8* %t222, i64 %t221)
  call void @free(i8* %t222)
  br label %table_push_after_copy_39
table_push_after_copy_39:
  store i8** %t219, i8*** %t192
  store i64 %t206, i64* %t189
  br label %table_push_store_35
table_push_store_35:
  %t223 = load i32*, i32** %t190
  %t224 = extractvalue %Enemy %t198, 0
  %t225 = getelementptr inbounds i32, i32* %t223, i64 %t200
  store i32 %t224, i32* %t225
  %t226 = load i8**, i8*** %t192
  %t227 = extractvalue %Enemy %t198, 1
  %t228 = getelementptr inbounds i8*, i8** %t226, i64 %t200
  store i8* %t227, i8** %t228
  %t229 = add i64 %t200, 1
  store i64 %t229, i64* %t187
  %t230 = load i8*, i8** %t0
  %t231 = icmp eq i8* %t230, null
  br i1 %t231, label %table_cow_alloc_40, label %table_cow_check_41
table_cow_alloc_40:
  %t232 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t233 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t234 = ptrtoint { i64, i64, i32*, i8** }* %t233 to i64
  %t235 = call i8* @star_rc_alloc(i64 %t234, i8* %t232)
  %t236 = bitcast i8* %t235 to { i64, i64, i32*, i8** }*
  %t237 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t236, i32 0, i32 0
  store i64 0, i64* %t237
  %t238 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t236, i32 0, i32 1
  store i64 0, i64* %t238
  %t239 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t236, i32 0, i32 2
  store i32* null, i32** %t239
  %t240 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t236, i32 0, i32 3
  store i8** null, i8*** %t240
  store i8* %t235, i8** %t0
  br label %table_cow_done_42
table_cow_check_41:
  %t241 = getelementptr inbounds i8, i8* %t230, i64 -16
  %t242 = bitcast i8* %t241 to i64*
  %t243 = load atomic i64, i64* %t242 seq_cst, align 8
  %t244 = icmp eq i64 %t243, 1
  br i1 %t244, label %table_cow_done_42, label %table_cow_clone_43
table_cow_clone_43:
  %t245 = bitcast i8* %t230 to { i64, i64, i32*, i8** }*
  %t246 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t245, i32 0, i32 0
  %t247 = load i64, i64* %t246
  %t248 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t245, i32 0, i32 1
  %t249 = load i64, i64* %t248
  %t250 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t251 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t252 = ptrtoint { i64, i64, i32*, i8** }* %t251 to i64
  %t253 = call i8* @star_rc_alloc(i64 %t252, i8* %t250)
  %t254 = bitcast i8* %t253 to { i64, i64, i32*, i8** }*
  %t255 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t254, i32 0, i32 0
  store i64 %t247, i64* %t255
  %t256 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t254, i32 0, i32 1
  store i64 %t249, i64* %t256
  %t257 = getelementptr i32, i32* null, i32 1
  %t258 = ptrtoint i32* %t257 to i64
  %t259 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t245, i32 0, i32 2
  %t260 = load i32*, i32** %t259
  %t261 = mul i64 %t249, %t258
  %t262 = call i8* @malloc(i64 %t261)
  %t263 = bitcast i8* %t262 to i32*
  %t264 = icmp sgt i64 %t247, 0
  br i1 %t264, label %table_cow_copy_44, label %table_cow_after_copy_45
table_cow_copy_44:
  %t265 = mul i64 %t247, %t258
  %t266 = bitcast i32* %t260 to i8*
  call i8* @memcpy(i8* %t262, i8* %t266, i64 %t265)
  br label %table_cow_after_copy_45
table_cow_after_copy_45:
  %t267 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t254, i32 0, i32 2
  store i32* %t263, i32** %t267
  %t268 = getelementptr i8*, i8** null, i32 1
  %t269 = ptrtoint i8** %t268 to i64
  %t270 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t245, i32 0, i32 3
  %t271 = load i8**, i8*** %t270
  %t272 = mul i64 %t249, %t269
  %t273 = call i8* @malloc(i64 %t272)
  %t274 = bitcast i8* %t273 to i8**
  %t275 = icmp sgt i64 %t247, 0
  br i1 %t275, label %table_cow_copy_46, label %table_cow_after_copy_47
table_cow_copy_46:
  %t276 = mul i64 %t247, %t269
  %t277 = bitcast i8** %t271 to i8*
  call i8* @memcpy(i8* %t273, i8* %t277, i64 %t276)
  store i64 0, i64* %t278
  br label %table_cow_retain_cond_48
table_cow_retain_cond_48:
  %t279 = load i64, i64* %t278
  %t280 = icmp slt i64 %t279, %t247
  br i1 %t280, label %table_cow_retain_body_49, label %table_cow_retain_end_50
table_cow_retain_body_49:
  %t281 = getelementptr inbounds i8*, i8** %t274, i64 %t279
  %t282 = load i8*, i8** %t281
  call void @star_rc_retain(i8* %t282)
  %t283 = add i64 %t279, 1
  store i64 %t283, i64* %t278
  br label %table_cow_retain_cond_48
table_cow_retain_end_50:
  br label %table_cow_after_copy_47
table_cow_after_copy_47:
  %t284 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t254, i32 0, i32 3
  store i8** %t274, i8*** %t284
  call void @star_rc_release(i8* %t230)
  store i8* %t253, i8** %t0
  br label %table_cow_done_42
table_cow_done_42:
  %t285 = load i8*, i8** %t0
  %t286 = bitcast i8* %t285 to { i64, i64, i32*, i8** }*
  %t287 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t286, i32 0, i32 0
  %t288 = load i64, i64* %t287
  %t289 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t286, i32 0, i32 1
  %t290 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t286, i32 0, i32 2
  %t291 = load i32*, i32** %t290
  %t292 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t286, i32 0, i32 3
  %t293 = load i8**, i8*** %t292
  %t295 = getelementptr inbounds %Enemy, %Enemy* %t294, i32 0, i32 0
  store i32 30, i32* %t295
  %t296 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t297 = getelementptr inbounds %Enemy, %Enemy* %t294, i32 0, i32 1
  store i8* %t296, i8** %t297
  %t298 = load %Enemy, %Enemy* %t294
  %t299 = load i64, i64* %t289
  %t300 = load i64, i64* %t287
  %t301 = load i32*, i32** %t290
  %t302 = load i8**, i8*** %t292
  %t303 = icmp sge i64 %t300, %t299
  br i1 %t303, label %table_push_grow_51, label %table_push_store_52
table_push_grow_51:
  %t304 = mul i64 %t299, 2
  %t305 = icmp sgt i64 %t304, 0
  %t306 = select i1 %t305, i64 %t304, i64 1
  %t307 = getelementptr i32, i32* null, i32 1
  %t308 = ptrtoint i32* %t307 to i64
  %t309 = mul i64 %t306, %t308
  %t310 = call i8* @malloc(i64 %t309)
  %t311 = bitcast i8* %t310 to i32*
  %t312 = icmp sgt i64 %t299, 0
  br i1 %t312, label %table_push_copy_53, label %table_push_after_copy_54
table_push_copy_53:
  %t313 = mul i64 %t300, %t308
  %t314 = bitcast i32* %t301 to i8*
  call i8* @memcpy(i8* %t310, i8* %t314, i64 %t313)
  call void @free(i8* %t314)
  br label %table_push_after_copy_54
table_push_after_copy_54:
  store i32* %t311, i32** %t290
  %t315 = getelementptr i8*, i8** null, i32 1
  %t316 = ptrtoint i8** %t315 to i64
  %t317 = mul i64 %t306, %t316
  %t318 = call i8* @malloc(i64 %t317)
  %t319 = bitcast i8* %t318 to i8**
  %t320 = icmp sgt i64 %t299, 0
  br i1 %t320, label %table_push_copy_55, label %table_push_after_copy_56
table_push_copy_55:
  %t321 = mul i64 %t300, %t316
  %t322 = bitcast i8** %t302 to i8*
  call i8* @memcpy(i8* %t318, i8* %t322, i64 %t321)
  call void @free(i8* %t322)
  br label %table_push_after_copy_56
table_push_after_copy_56:
  store i8** %t319, i8*** %t292
  store i64 %t306, i64* %t289
  br label %table_push_store_52
table_push_store_52:
  %t323 = load i32*, i32** %t290
  %t324 = extractvalue %Enemy %t298, 0
  %t325 = getelementptr inbounds i32, i32* %t323, i64 %t300
  store i32 %t324, i32* %t325
  %t326 = load i8**, i8*** %t292
  %t327 = extractvalue %Enemy %t298, 1
  %t328 = getelementptr inbounds i8*, i8** %t326, i64 %t300
  store i8* %t327, i8** %t328
  %t329 = add i64 %t300, 1
  store i64 %t329, i64* %t287
  %t330 = load i8*, i8** %t0
  %t331 = icmp eq i8* %t330, null
  br i1 %t331, label %table_read_null_57, label %table_read_real_58
table_read_null_57:
  br label %table_read_end_59
table_read_real_58:
  %t332 = bitcast i8* %t330 to { i64, i64, i32*, i8** }*
  %t333 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t332, i32 0, i32 0
  %t334 = load i64, i64* %t333
  %t335 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t332, i32 0, i32 2
  %t336 = load i32*, i32** %t335
  %t337 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t332, i32 0, i32 3
  %t338 = load i8**, i8*** %t337
  br label %table_read_end_59
table_read_end_59:
  %t339 = phi i64 [ 0, %table_read_null_57 ], [ %t334, %table_read_real_58 ]
  %t340 = phi i32* [ null, %table_read_null_57 ], [ %t336, %table_read_real_58 ]
  %t341 = phi i8** [ null, %table_read_null_57 ], [ %t338, %table_read_real_58 ]
  %t342 = trunc i64 %t339 to i32
  %t343 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t343, i32 %t342)
  %t344 = sext i32 0 to i64
  %t345 = load i8*, i8** %t0
  %t346 = icmp eq i8* %t345, null
  br i1 %t346, label %table_read_null_60, label %table_read_real_61
table_read_null_60:
  br label %table_read_end_62
table_read_real_61:
  %t347 = bitcast i8* %t345 to { i64, i64, i32*, i8** }*
  %t348 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t347, i32 0, i32 0
  %t349 = load i64, i64* %t348
  %t350 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t347, i32 0, i32 2
  %t351 = load i32*, i32** %t350
  %t352 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t347, i32 0, i32 3
  %t353 = load i8**, i8*** %t352
  br label %table_read_end_62
table_read_end_62:
  %t354 = phi i64 [ 0, %table_read_null_60 ], [ %t349, %table_read_real_61 ]
  %t355 = phi i32* [ null, %table_read_null_60 ], [ %t351, %table_read_real_61 ]
  %t356 = phi i8** [ null, %table_read_null_60 ], [ %t353, %table_read_real_61 ]
  %t358 = icmp ult i64 %t344, %t354
  br i1 %t358, label %table_idx_ok_63, label %table_idx_oob_64
table_idx_ok_63:
  %t359 = getelementptr inbounds i32, i32* %t355, i64 %t344
  %t360 = load i32, i32* %t359
  %t361 = getelementptr inbounds %Enemy, %Enemy* %t357, i32 0, i32 0
  store i32 %t360, i32* %t361
  %t362 = getelementptr inbounds i8*, i8** %t356, i64 %t344
  %t363 = load i8*, i8** %t362
  call void @star_rc_retain(i8* %t363)
  %t364 = load i8*, i8** %t362
  %t365 = getelementptr inbounds %Enemy, %Enemy* %t357, i32 0, i32 1
  store i8* %t364, i8** %t365
  br label %table_idx_end_65
table_idx_oob_64:
  store %Enemy zeroinitializer, %Enemy* %t357
  br label %table_idx_end_65
table_idx_end_65:
  %t366 = load %Enemy, %Enemy* %t357
  store %Enemy %t366, %Enemy* %t367
  %t368 = getelementptr inbounds %Enemy, %Enemy* %t367, i32 0, i32 1
  %t369 = load i8*, i8** %t368
  %t370 = load i8*, i8** %t368
  call void @star_rc_retain(i8* %t370)
  call void @star_rc_release(i8* %t369)
  %t371 = sext i32 0 to i64
  %t372 = load i8*, i8** %t0
  %t373 = icmp eq i8* %t372, null
  br i1 %t373, label %table_read_null_66, label %table_read_real_67
table_read_null_66:
  br label %table_read_end_68
table_read_real_67:
  %t374 = bitcast i8* %t372 to { i64, i64, i32*, i8** }*
  %t375 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t374, i32 0, i32 0
  %t376 = load i64, i64* %t375
  %t377 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t374, i32 0, i32 2
  %t378 = load i32*, i32** %t377
  %t379 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t374, i32 0, i32 3
  %t380 = load i8**, i8*** %t379
  br label %table_read_end_68
table_read_end_68:
  %t381 = phi i64 [ 0, %table_read_null_66 ], [ %t376, %table_read_real_67 ]
  %t382 = phi i32* [ null, %table_read_null_66 ], [ %t378, %table_read_real_67 ]
  %t383 = phi i8** [ null, %table_read_null_66 ], [ %t380, %table_read_real_67 ]
  %t385 = icmp ult i64 %t371, %t381
  br i1 %t385, label %table_idx_ok_69, label %table_idx_oob_70
table_idx_ok_69:
  %t386 = getelementptr inbounds i32, i32* %t382, i64 %t371
  %t387 = load i32, i32* %t386
  %t388 = getelementptr inbounds %Enemy, %Enemy* %t384, i32 0, i32 0
  store i32 %t387, i32* %t388
  %t389 = getelementptr inbounds i8*, i8** %t383, i64 %t371
  %t390 = load i8*, i8** %t389
  call void @star_rc_retain(i8* %t390)
  %t391 = load i8*, i8** %t389
  %t392 = getelementptr inbounds %Enemy, %Enemy* %t384, i32 0, i32 1
  store i8* %t391, i8** %t392
  br label %table_idx_end_71
table_idx_oob_70:
  store %Enemy zeroinitializer, %Enemy* %t384
  br label %table_idx_end_71
table_idx_end_71:
  %t393 = load %Enemy, %Enemy* %t384
  store %Enemy %t393, %Enemy* %t394
  %t395 = getelementptr inbounds %Enemy, %Enemy* %t394, i32 0, i32 0
  %t396 = load i32, i32* %t395
  %t397 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t397, i8* %t369, i32 %t396)
  %t398 = sext i32 2 to i64
  %t399 = load i8*, i8** %t0
  %t400 = icmp eq i8* %t399, null
  br i1 %t400, label %table_read_null_72, label %table_read_real_73
table_read_null_72:
  br label %table_read_end_74
table_read_real_73:
  %t401 = bitcast i8* %t399 to { i64, i64, i32*, i8** }*
  %t402 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t401, i32 0, i32 0
  %t403 = load i64, i64* %t402
  %t404 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t401, i32 0, i32 2
  %t405 = load i32*, i32** %t404
  %t406 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t401, i32 0, i32 3
  %t407 = load i8**, i8*** %t406
  br label %table_read_end_74
table_read_end_74:
  %t408 = phi i64 [ 0, %table_read_null_72 ], [ %t403, %table_read_real_73 ]
  %t409 = phi i32* [ null, %table_read_null_72 ], [ %t405, %table_read_real_73 ]
  %t410 = phi i8** [ null, %table_read_null_72 ], [ %t407, %table_read_real_73 ]
  %t412 = icmp ult i64 %t398, %t408
  br i1 %t412, label %table_idx_ok_75, label %table_idx_oob_76
table_idx_ok_75:
  %t413 = getelementptr inbounds i32, i32* %t409, i64 %t398
  %t414 = load i32, i32* %t413
  %t415 = getelementptr inbounds %Enemy, %Enemy* %t411, i32 0, i32 0
  store i32 %t414, i32* %t415
  %t416 = getelementptr inbounds i8*, i8** %t410, i64 %t398
  %t417 = load i8*, i8** %t416
  call void @star_rc_retain(i8* %t417)
  %t418 = load i8*, i8** %t416
  %t419 = getelementptr inbounds %Enemy, %Enemy* %t411, i32 0, i32 1
  store i8* %t418, i8** %t419
  br label %table_idx_end_77
table_idx_oob_76:
  store %Enemy zeroinitializer, %Enemy* %t411
  br label %table_idx_end_77
table_idx_end_77:
  %t420 = load %Enemy, %Enemy* %t411
  store %Enemy %t420, %Enemy* %t421
  %t422 = getelementptr inbounds %Enemy, %Enemy* %t421, i32 0, i32 1
  %t423 = load i8*, i8** %t422
  %t424 = load i8*, i8** %t422
  call void @star_rc_retain(i8* %t424)
  call void @star_rc_release(i8* %t423)
  %t425 = sext i32 2 to i64
  %t426 = load i8*, i8** %t0
  %t427 = icmp eq i8* %t426, null
  br i1 %t427, label %table_read_null_78, label %table_read_real_79
table_read_null_78:
  br label %table_read_end_80
table_read_real_79:
  %t428 = bitcast i8* %t426 to { i64, i64, i32*, i8** }*
  %t429 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t428, i32 0, i32 0
  %t430 = load i64, i64* %t429
  %t431 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t428, i32 0, i32 2
  %t432 = load i32*, i32** %t431
  %t433 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t428, i32 0, i32 3
  %t434 = load i8**, i8*** %t433
  br label %table_read_end_80
table_read_end_80:
  %t435 = phi i64 [ 0, %table_read_null_78 ], [ %t430, %table_read_real_79 ]
  %t436 = phi i32* [ null, %table_read_null_78 ], [ %t432, %table_read_real_79 ]
  %t437 = phi i8** [ null, %table_read_null_78 ], [ %t434, %table_read_real_79 ]
  %t439 = icmp ult i64 %t425, %t435
  br i1 %t439, label %table_idx_ok_81, label %table_idx_oob_82
table_idx_ok_81:
  %t440 = getelementptr inbounds i32, i32* %t436, i64 %t425
  %t441 = load i32, i32* %t440
  %t442 = getelementptr inbounds %Enemy, %Enemy* %t438, i32 0, i32 0
  store i32 %t441, i32* %t442
  %t443 = getelementptr inbounds i8*, i8** %t437, i64 %t425
  %t444 = load i8*, i8** %t443
  call void @star_rc_retain(i8* %t444)
  %t445 = load i8*, i8** %t443
  %t446 = getelementptr inbounds %Enemy, %Enemy* %t438, i32 0, i32 1
  store i8* %t445, i8** %t446
  br label %table_idx_end_83
table_idx_oob_82:
  store %Enemy zeroinitializer, %Enemy* %t438
  br label %table_idx_end_83
table_idx_end_83:
  %t447 = load %Enemy, %Enemy* %t438
  store %Enemy %t447, %Enemy* %t448
  %t449 = getelementptr inbounds %Enemy, %Enemy* %t448, i32 0, i32 0
  %t450 = load i32, i32* %t449
  %t451 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t451, i8* %t423, i32 %t450)
  %t453 = getelementptr inbounds %Enemy, %Enemy* %t452, i32 0, i32 0
  store i32 99, i32* %t453
  %t454 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t455 = getelementptr inbounds %Enemy, %Enemy* %t452, i32 0, i32 1
  store i8* %t454, i8** %t455
  %t456 = load %Enemy, %Enemy* %t452
  %t457 = sext i32 1 to i64
  %t458 = load i8*, i8** %t0
  %t459 = icmp eq i8* %t458, null
  br i1 %t459, label %table_cow_alloc_84, label %table_cow_check_85
table_cow_alloc_84:
  %t460 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t461 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t462 = ptrtoint { i64, i64, i32*, i8** }* %t461 to i64
  %t463 = call i8* @star_rc_alloc(i64 %t462, i8* %t460)
  %t464 = bitcast i8* %t463 to { i64, i64, i32*, i8** }*
  %t465 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t464, i32 0, i32 0
  store i64 0, i64* %t465
  %t466 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t464, i32 0, i32 1
  store i64 0, i64* %t466
  %t467 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t464, i32 0, i32 2
  store i32* null, i32** %t467
  %t468 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t464, i32 0, i32 3
  store i8** null, i8*** %t468
  store i8* %t463, i8** %t0
  br label %table_cow_done_86
table_cow_check_85:
  %t469 = getelementptr inbounds i8, i8* %t458, i64 -16
  %t470 = bitcast i8* %t469 to i64*
  %t471 = load atomic i64, i64* %t470 seq_cst, align 8
  %t472 = icmp eq i64 %t471, 1
  br i1 %t472, label %table_cow_done_86, label %table_cow_clone_87
table_cow_clone_87:
  %t473 = bitcast i8* %t458 to { i64, i64, i32*, i8** }*
  %t474 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t473, i32 0, i32 0
  %t475 = load i64, i64* %t474
  %t476 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t473, i32 0, i32 1
  %t477 = load i64, i64* %t476
  %t478 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t479 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t480 = ptrtoint { i64, i64, i32*, i8** }* %t479 to i64
  %t481 = call i8* @star_rc_alloc(i64 %t480, i8* %t478)
  %t482 = bitcast i8* %t481 to { i64, i64, i32*, i8** }*
  %t483 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t482, i32 0, i32 0
  store i64 %t475, i64* %t483
  %t484 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t482, i32 0, i32 1
  store i64 %t477, i64* %t484
  %t485 = getelementptr i32, i32* null, i32 1
  %t486 = ptrtoint i32* %t485 to i64
  %t487 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t473, i32 0, i32 2
  %t488 = load i32*, i32** %t487
  %t489 = mul i64 %t477, %t486
  %t490 = call i8* @malloc(i64 %t489)
  %t491 = bitcast i8* %t490 to i32*
  %t492 = icmp sgt i64 %t475, 0
  br i1 %t492, label %table_cow_copy_88, label %table_cow_after_copy_89
table_cow_copy_88:
  %t493 = mul i64 %t475, %t486
  %t494 = bitcast i32* %t488 to i8*
  call i8* @memcpy(i8* %t490, i8* %t494, i64 %t493)
  br label %table_cow_after_copy_89
table_cow_after_copy_89:
  %t495 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t482, i32 0, i32 2
  store i32* %t491, i32** %t495
  %t496 = getelementptr i8*, i8** null, i32 1
  %t497 = ptrtoint i8** %t496 to i64
  %t498 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t473, i32 0, i32 3
  %t499 = load i8**, i8*** %t498
  %t500 = mul i64 %t477, %t497
  %t501 = call i8* @malloc(i64 %t500)
  %t502 = bitcast i8* %t501 to i8**
  %t503 = icmp sgt i64 %t475, 0
  br i1 %t503, label %table_cow_copy_90, label %table_cow_after_copy_91
table_cow_copy_90:
  %t504 = mul i64 %t475, %t497
  %t505 = bitcast i8** %t499 to i8*
  call i8* @memcpy(i8* %t501, i8* %t505, i64 %t504)
  store i64 0, i64* %t506
  br label %table_cow_retain_cond_92
table_cow_retain_cond_92:
  %t507 = load i64, i64* %t506
  %t508 = icmp slt i64 %t507, %t475
  br i1 %t508, label %table_cow_retain_body_93, label %table_cow_retain_end_94
table_cow_retain_body_93:
  %t509 = getelementptr inbounds i8*, i8** %t502, i64 %t507
  %t510 = load i8*, i8** %t509
  call void @star_rc_retain(i8* %t510)
  %t511 = add i64 %t507, 1
  store i64 %t511, i64* %t506
  br label %table_cow_retain_cond_92
table_cow_retain_end_94:
  br label %table_cow_after_copy_91
table_cow_after_copy_91:
  %t512 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t482, i32 0, i32 3
  store i8** %t502, i8*** %t512
  call void @star_rc_release(i8* %t458)
  store i8* %t481, i8** %t0
  br label %table_cow_done_86
table_cow_done_86:
  %t513 = load i8*, i8** %t0
  %t514 = bitcast i8* %t513 to { i64, i64, i32*, i8** }*
  %t515 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t514, i32 0, i32 0
  %t516 = load i64, i64* %t515
  %t517 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t514, i32 0, i32 1
  %t518 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t514, i32 0, i32 2
  %t519 = load i32*, i32** %t518
  %t520 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t514, i32 0, i32 3
  %t521 = load i8**, i8*** %t520
  %t522 = icmp ult i64 %t457, %t516
  br i1 %t522, label %table_set_do_95, label %table_set_oob_96
table_set_do_95:
  %t523 = extractvalue %Enemy %t456, 0
  %t524 = getelementptr inbounds i32, i32* %t519, i64 %t457
  store i32 %t523, i32* %t524
  %t525 = extractvalue %Enemy %t456, 1
  %t526 = getelementptr inbounds i8*, i8** %t521, i64 %t457
  %t527 = load i8*, i8** %t526
  call void @star_rc_release(i8* %t527)
  store i8* %t525, i8** %t526
  br label %table_set_end_97
table_set_oob_96:
  store %Enemy %t456, %Enemy* %t528
  %t529 = getelementptr inbounds %Enemy, %Enemy* %t528, i32 0, i32 1
  %t530 = load i8*, i8** %t529
  call void @star_rc_release(i8* %t530)
  br label %table_set_end_97
table_set_end_97:
  %t531 = sext i32 1 to i64
  %t532 = load i8*, i8** %t0
  %t533 = icmp eq i8* %t532, null
  br i1 %t533, label %table_read_null_98, label %table_read_real_99
table_read_null_98:
  br label %table_read_end_100
table_read_real_99:
  %t534 = bitcast i8* %t532 to { i64, i64, i32*, i8** }*
  %t535 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t534, i32 0, i32 0
  %t536 = load i64, i64* %t535
  %t537 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t534, i32 0, i32 2
  %t538 = load i32*, i32** %t537
  %t539 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t534, i32 0, i32 3
  %t540 = load i8**, i8*** %t539
  br label %table_read_end_100
table_read_end_100:
  %t541 = phi i64 [ 0, %table_read_null_98 ], [ %t536, %table_read_real_99 ]
  %t542 = phi i32* [ null, %table_read_null_98 ], [ %t538, %table_read_real_99 ]
  %t543 = phi i8** [ null, %table_read_null_98 ], [ %t540, %table_read_real_99 ]
  %t545 = icmp ult i64 %t531, %t541
  br i1 %t545, label %table_idx_ok_101, label %table_idx_oob_102
table_idx_ok_101:
  %t546 = getelementptr inbounds i32, i32* %t542, i64 %t531
  %t547 = load i32, i32* %t546
  %t548 = getelementptr inbounds %Enemy, %Enemy* %t544, i32 0, i32 0
  store i32 %t547, i32* %t548
  %t549 = getelementptr inbounds i8*, i8** %t543, i64 %t531
  %t550 = load i8*, i8** %t549
  call void @star_rc_retain(i8* %t550)
  %t551 = load i8*, i8** %t549
  %t552 = getelementptr inbounds %Enemy, %Enemy* %t544, i32 0, i32 1
  store i8* %t551, i8** %t552
  br label %table_idx_end_103
table_idx_oob_102:
  store %Enemy zeroinitializer, %Enemy* %t544
  br label %table_idx_end_103
table_idx_end_103:
  %t553 = load %Enemy, %Enemy* %t544
  store %Enemy %t553, %Enemy* %t554
  %t555 = getelementptr inbounds %Enemy, %Enemy* %t554, i32 0, i32 1
  %t556 = load i8*, i8** %t555
  %t557 = load i8*, i8** %t555
  call void @star_rc_retain(i8* %t557)
  call void @star_rc_release(i8* %t556)
  %t558 = sext i32 1 to i64
  %t559 = load i8*, i8** %t0
  %t560 = icmp eq i8* %t559, null
  br i1 %t560, label %table_read_null_104, label %table_read_real_105
table_read_null_104:
  br label %table_read_end_106
table_read_real_105:
  %t561 = bitcast i8* %t559 to { i64, i64, i32*, i8** }*
  %t562 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t561, i32 0, i32 0
  %t563 = load i64, i64* %t562
  %t564 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t561, i32 0, i32 2
  %t565 = load i32*, i32** %t564
  %t566 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t561, i32 0, i32 3
  %t567 = load i8**, i8*** %t566
  br label %table_read_end_106
table_read_end_106:
  %t568 = phi i64 [ 0, %table_read_null_104 ], [ %t563, %table_read_real_105 ]
  %t569 = phi i32* [ null, %table_read_null_104 ], [ %t565, %table_read_real_105 ]
  %t570 = phi i8** [ null, %table_read_null_104 ], [ %t567, %table_read_real_105 ]
  %t572 = icmp ult i64 %t558, %t568
  br i1 %t572, label %table_idx_ok_107, label %table_idx_oob_108
table_idx_ok_107:
  %t573 = getelementptr inbounds i32, i32* %t569, i64 %t558
  %t574 = load i32, i32* %t573
  %t575 = getelementptr inbounds %Enemy, %Enemy* %t571, i32 0, i32 0
  store i32 %t574, i32* %t575
  %t576 = getelementptr inbounds i8*, i8** %t570, i64 %t558
  %t577 = load i8*, i8** %t576
  call void @star_rc_retain(i8* %t577)
  %t578 = load i8*, i8** %t576
  %t579 = getelementptr inbounds %Enemy, %Enemy* %t571, i32 0, i32 1
  store i8* %t578, i8** %t579
  br label %table_idx_end_109
table_idx_oob_108:
  store %Enemy zeroinitializer, %Enemy* %t571
  br label %table_idx_end_109
table_idx_end_109:
  %t580 = load %Enemy, %Enemy* %t571
  store %Enemy %t580, %Enemy* %t581
  %t582 = getelementptr inbounds %Enemy, %Enemy* %t581, i32 0, i32 0
  %t583 = load i32, i32* %t582
  %t584 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t584, i8* %t556, i32 %t583)
  %t586 = load i8*, i8** %t0
  %t587 = icmp eq i8* %t586, null
  br i1 %t587, label %table_cow_alloc_110, label %table_cow_check_111
table_cow_alloc_110:
  %t588 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t589 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t590 = ptrtoint { i64, i64, i32*, i8** }* %t589 to i64
  %t591 = call i8* @star_rc_alloc(i64 %t590, i8* %t588)
  %t592 = bitcast i8* %t591 to { i64, i64, i32*, i8** }*
  %t593 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t592, i32 0, i32 0
  store i64 0, i64* %t593
  %t594 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t592, i32 0, i32 1
  store i64 0, i64* %t594
  %t595 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t592, i32 0, i32 2
  store i32* null, i32** %t595
  %t596 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t592, i32 0, i32 3
  store i8** null, i8*** %t596
  store i8* %t591, i8** %t0
  br label %table_cow_done_112
table_cow_check_111:
  %t597 = getelementptr inbounds i8, i8* %t586, i64 -16
  %t598 = bitcast i8* %t597 to i64*
  %t599 = load atomic i64, i64* %t598 seq_cst, align 8
  %t600 = icmp eq i64 %t599, 1
  br i1 %t600, label %table_cow_done_112, label %table_cow_clone_113
table_cow_clone_113:
  %t601 = bitcast i8* %t586 to { i64, i64, i32*, i8** }*
  %t602 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t601, i32 0, i32 0
  %t603 = load i64, i64* %t602
  %t604 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t601, i32 0, i32 1
  %t605 = load i64, i64* %t604
  %t606 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t607 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t608 = ptrtoint { i64, i64, i32*, i8** }* %t607 to i64
  %t609 = call i8* @star_rc_alloc(i64 %t608, i8* %t606)
  %t610 = bitcast i8* %t609 to { i64, i64, i32*, i8** }*
  %t611 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t610, i32 0, i32 0
  store i64 %t603, i64* %t611
  %t612 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t610, i32 0, i32 1
  store i64 %t605, i64* %t612
  %t613 = getelementptr i32, i32* null, i32 1
  %t614 = ptrtoint i32* %t613 to i64
  %t615 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t601, i32 0, i32 2
  %t616 = load i32*, i32** %t615
  %t617 = mul i64 %t605, %t614
  %t618 = call i8* @malloc(i64 %t617)
  %t619 = bitcast i8* %t618 to i32*
  %t620 = icmp sgt i64 %t603, 0
  br i1 %t620, label %table_cow_copy_114, label %table_cow_after_copy_115
table_cow_copy_114:
  %t621 = mul i64 %t603, %t614
  %t622 = bitcast i32* %t616 to i8*
  call i8* @memcpy(i8* %t618, i8* %t622, i64 %t621)
  br label %table_cow_after_copy_115
table_cow_after_copy_115:
  %t623 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t610, i32 0, i32 2
  store i32* %t619, i32** %t623
  %t624 = getelementptr i8*, i8** null, i32 1
  %t625 = ptrtoint i8** %t624 to i64
  %t626 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t601, i32 0, i32 3
  %t627 = load i8**, i8*** %t626
  %t628 = mul i64 %t605, %t625
  %t629 = call i8* @malloc(i64 %t628)
  %t630 = bitcast i8* %t629 to i8**
  %t631 = icmp sgt i64 %t603, 0
  br i1 %t631, label %table_cow_copy_116, label %table_cow_after_copy_117
table_cow_copy_116:
  %t632 = mul i64 %t603, %t625
  %t633 = bitcast i8** %t627 to i8*
  call i8* @memcpy(i8* %t629, i8* %t633, i64 %t632)
  store i64 0, i64* %t634
  br label %table_cow_retain_cond_118
table_cow_retain_cond_118:
  %t635 = load i64, i64* %t634
  %t636 = icmp slt i64 %t635, %t603
  br i1 %t636, label %table_cow_retain_body_119, label %table_cow_retain_end_120
table_cow_retain_body_119:
  %t637 = getelementptr inbounds i8*, i8** %t630, i64 %t635
  %t638 = load i8*, i8** %t637
  call void @star_rc_retain(i8* %t638)
  %t639 = add i64 %t635, 1
  store i64 %t639, i64* %t634
  br label %table_cow_retain_cond_118
table_cow_retain_end_120:
  br label %table_cow_after_copy_117
table_cow_after_copy_117:
  %t640 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t610, i32 0, i32 3
  store i8** %t630, i8*** %t640
  call void @star_rc_release(i8* %t586)
  store i8* %t609, i8** %t0
  br label %table_cow_done_112
table_cow_done_112:
  %t641 = load i8*, i8** %t0
  %t642 = bitcast i8* %t641 to { i64, i64, i32*, i8** }*
  %t643 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t642, i32 0, i32 0
  %t644 = load i64, i64* %t643
  %t645 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t642, i32 0, i32 1
  %t646 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t642, i32 0, i32 2
  %t647 = load i32*, i32** %t646
  %t648 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t642, i32 0, i32 3
  %t649 = load i8**, i8*** %t648
  %t651 = icmp eq i64 %t644, 0
  br i1 %t651, label %table_pop_empty_121, label %table_pop_nonempty_122
table_pop_nonempty_122:
  %t652 = sub i64 %t644, 1
  store i64 %t652, i64* %t643
  %t653 = getelementptr inbounds i32, i32* %t647, i64 %t652
  %t654 = load i32, i32* %t653
  %t655 = getelementptr inbounds %Enemy, %Enemy* %t650, i32 0, i32 0
  store i32 %t654, i32* %t655
  %t656 = getelementptr inbounds i8*, i8** %t649, i64 %t652
  %t657 = load i8*, i8** %t656
  %t658 = getelementptr inbounds %Enemy, %Enemy* %t650, i32 0, i32 1
  store i8* %t657, i8** %t658
  br label %table_pop_end_123
table_pop_empty_121:
  store %Enemy zeroinitializer, %Enemy* %t650
  br label %table_pop_end_123
table_pop_end_123:
  %t659 = load %Enemy, %Enemy* %t650
  store %Enemy %t659, %Enemy* %t585
  %t660 = getelementptr inbounds %Enemy, %Enemy* %t585, i32 0, i32 1
  %t661 = load i8*, i8** %t660
  %t662 = load i8*, i8** %t660
  call void @star_rc_retain(i8* %t662)
  call void @star_rc_release(i8* %t661)
  %t663 = getelementptr inbounds %Enemy, %Enemy* %t585, i32 0, i32 0
  %t664 = load i32, i32* %t663
  %t665 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t665, i8* %t661, i32 %t664)
  %t666 = load i8*, i8** %t0
  %t667 = icmp eq i8* %t666, null
  br i1 %t667, label %table_read_null_124, label %table_read_real_125
table_read_null_124:
  br label %table_read_end_126
table_read_real_125:
  %t668 = bitcast i8* %t666 to { i64, i64, i32*, i8** }*
  %t669 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t668, i32 0, i32 0
  %t670 = load i64, i64* %t669
  %t671 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t668, i32 0, i32 2
  %t672 = load i32*, i32** %t671
  %t673 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t668, i32 0, i32 3
  %t674 = load i8**, i8*** %t673
  br label %table_read_end_126
table_read_end_126:
  %t675 = phi i64 [ 0, %table_read_null_124 ], [ %t670, %table_read_real_125 ]
  %t676 = phi i32* [ null, %table_read_null_124 ], [ %t672, %table_read_real_125 ]
  %t677 = phi i8** [ null, %table_read_null_124 ], [ %t674, %table_read_real_125 ]
  %t678 = trunc i64 %t675 to i32
  %t679 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t679, i32 %t678)
  %t680 = sext i32 99 to i64
  %t681 = load i8*, i8** %t0
  %t682 = icmp eq i8* %t681, null
  br i1 %t682, label %table_read_null_127, label %table_read_real_128
table_read_null_127:
  br label %table_read_end_129
table_read_real_128:
  %t683 = bitcast i8* %t681 to { i64, i64, i32*, i8** }*
  %t684 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t683, i32 0, i32 0
  %t685 = load i64, i64* %t684
  %t686 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t683, i32 0, i32 2
  %t687 = load i32*, i32** %t686
  %t688 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t683, i32 0, i32 3
  %t689 = load i8**, i8*** %t688
  br label %table_read_end_129
table_read_end_129:
  %t690 = phi i64 [ 0, %table_read_null_127 ], [ %t685, %table_read_real_128 ]
  %t691 = phi i32* [ null, %table_read_null_127 ], [ %t687, %table_read_real_128 ]
  %t692 = phi i8** [ null, %table_read_null_127 ], [ %t689, %table_read_real_128 ]
  %t694 = icmp ult i64 %t680, %t690
  br i1 %t694, label %table_idx_ok_130, label %table_idx_oob_131
table_idx_ok_130:
  %t695 = getelementptr inbounds i32, i32* %t691, i64 %t680
  %t696 = load i32, i32* %t695
  %t697 = getelementptr inbounds %Enemy, %Enemy* %t693, i32 0, i32 0
  store i32 %t696, i32* %t697
  %t698 = getelementptr inbounds i8*, i8** %t692, i64 %t680
  %t699 = load i8*, i8** %t698
  call void @star_rc_retain(i8* %t699)
  %t700 = load i8*, i8** %t698
  %t701 = getelementptr inbounds %Enemy, %Enemy* %t693, i32 0, i32 1
  store i8* %t700, i8** %t701
  br label %table_idx_end_132
table_idx_oob_131:
  store %Enemy zeroinitializer, %Enemy* %t693
  br label %table_idx_end_132
table_idx_end_132:
  %t702 = load %Enemy, %Enemy* %t693
  store %Enemy %t702, %Enemy* %t703
  %t704 = getelementptr inbounds %Enemy, %Enemy* %t703, i32 0, i32 0
  %t705 = load i32, i32* %t704
  %t706 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t706, i32 %t705)
  store i8* null, i8** %t707
  %t709 = load i8*, i8** %t707
  %t710 = icmp eq i8* %t709, null
  br i1 %t710, label %table_cow_alloc_133, label %table_cow_check_134
table_cow_alloc_133:
  %t711 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t712 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t713 = ptrtoint { i64, i64, i32*, i8** }* %t712 to i64
  %t714 = call i8* @star_rc_alloc(i64 %t713, i8* %t711)
  %t715 = bitcast i8* %t714 to { i64, i64, i32*, i8** }*
  %t716 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t715, i32 0, i32 0
  store i64 0, i64* %t716
  %t717 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t715, i32 0, i32 1
  store i64 0, i64* %t717
  %t718 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t715, i32 0, i32 2
  store i32* null, i32** %t718
  %t719 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t715, i32 0, i32 3
  store i8** null, i8*** %t719
  store i8* %t714, i8** %t707
  br label %table_cow_done_135
table_cow_check_134:
  %t720 = getelementptr inbounds i8, i8* %t709, i64 -16
  %t721 = bitcast i8* %t720 to i64*
  %t722 = load atomic i64, i64* %t721 seq_cst, align 8
  %t723 = icmp eq i64 %t722, 1
  br i1 %t723, label %table_cow_done_135, label %table_cow_clone_136
table_cow_clone_136:
  %t724 = bitcast i8* %t709 to { i64, i64, i32*, i8** }*
  %t725 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t724, i32 0, i32 0
  %t726 = load i64, i64* %t725
  %t727 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t724, i32 0, i32 1
  %t728 = load i64, i64* %t727
  %t729 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t730 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t731 = ptrtoint { i64, i64, i32*, i8** }* %t730 to i64
  %t732 = call i8* @star_rc_alloc(i64 %t731, i8* %t729)
  %t733 = bitcast i8* %t732 to { i64, i64, i32*, i8** }*
  %t734 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t733, i32 0, i32 0
  store i64 %t726, i64* %t734
  %t735 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t733, i32 0, i32 1
  store i64 %t728, i64* %t735
  %t736 = getelementptr i32, i32* null, i32 1
  %t737 = ptrtoint i32* %t736 to i64
  %t738 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t724, i32 0, i32 2
  %t739 = load i32*, i32** %t738
  %t740 = mul i64 %t728, %t737
  %t741 = call i8* @malloc(i64 %t740)
  %t742 = bitcast i8* %t741 to i32*
  %t743 = icmp sgt i64 %t726, 0
  br i1 %t743, label %table_cow_copy_137, label %table_cow_after_copy_138
table_cow_copy_137:
  %t744 = mul i64 %t726, %t737
  %t745 = bitcast i32* %t739 to i8*
  call i8* @memcpy(i8* %t741, i8* %t745, i64 %t744)
  br label %table_cow_after_copy_138
table_cow_after_copy_138:
  %t746 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t733, i32 0, i32 2
  store i32* %t742, i32** %t746
  %t747 = getelementptr i8*, i8** null, i32 1
  %t748 = ptrtoint i8** %t747 to i64
  %t749 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t724, i32 0, i32 3
  %t750 = load i8**, i8*** %t749
  %t751 = mul i64 %t728, %t748
  %t752 = call i8* @malloc(i64 %t751)
  %t753 = bitcast i8* %t752 to i8**
  %t754 = icmp sgt i64 %t726, 0
  br i1 %t754, label %table_cow_copy_139, label %table_cow_after_copy_140
table_cow_copy_139:
  %t755 = mul i64 %t726, %t748
  %t756 = bitcast i8** %t750 to i8*
  call i8* @memcpy(i8* %t752, i8* %t756, i64 %t755)
  store i64 0, i64* %t757
  br label %table_cow_retain_cond_141
table_cow_retain_cond_141:
  %t758 = load i64, i64* %t757
  %t759 = icmp slt i64 %t758, %t726
  br i1 %t759, label %table_cow_retain_body_142, label %table_cow_retain_end_143
table_cow_retain_body_142:
  %t760 = getelementptr inbounds i8*, i8** %t753, i64 %t758
  %t761 = load i8*, i8** %t760
  call void @star_rc_retain(i8* %t761)
  %t762 = add i64 %t758, 1
  store i64 %t762, i64* %t757
  br label %table_cow_retain_cond_141
table_cow_retain_end_143:
  br label %table_cow_after_copy_140
table_cow_after_copy_140:
  %t763 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t733, i32 0, i32 3
  store i8** %t753, i8*** %t763
  call void @star_rc_release(i8* %t709)
  store i8* %t732, i8** %t707
  br label %table_cow_done_135
table_cow_done_135:
  %t764 = load i8*, i8** %t707
  %t765 = bitcast i8* %t764 to { i64, i64, i32*, i8** }*
  %t766 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t765, i32 0, i32 0
  %t767 = load i64, i64* %t766
  %t768 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t765, i32 0, i32 1
  %t769 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t765, i32 0, i32 2
  %t770 = load i32*, i32** %t769
  %t771 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t765, i32 0, i32 3
  %t772 = load i8**, i8*** %t771
  %t774 = icmp eq i64 %t767, 0
  br i1 %t774, label %table_pop_empty_144, label %table_pop_nonempty_145
table_pop_nonempty_145:
  %t775 = sub i64 %t767, 1
  store i64 %t775, i64* %t766
  %t776 = getelementptr inbounds i32, i32* %t770, i64 %t775
  %t777 = load i32, i32* %t776
  %t778 = getelementptr inbounds %Enemy, %Enemy* %t773, i32 0, i32 0
  store i32 %t777, i32* %t778
  %t779 = getelementptr inbounds i8*, i8** %t772, i64 %t775
  %t780 = load i8*, i8** %t779
  %t781 = getelementptr inbounds %Enemy, %Enemy* %t773, i32 0, i32 1
  store i8* %t780, i8** %t781
  br label %table_pop_end_146
table_pop_empty_144:
  store %Enemy zeroinitializer, %Enemy* %t773
  br label %table_pop_end_146
table_pop_end_146:
  %t782 = load %Enemy, %Enemy* %t773
  store %Enemy %t782, %Enemy* %t708
  %t783 = getelementptr inbounds %Enemy, %Enemy* %t708, i32 0, i32 0
  %t784 = load i32, i32* %t783
  %t785 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t785, i32 %t784)
  store i8* null, i8** %t786
  %t787 = load i8*, i8** %t786
  %t788 = icmp eq i8* %t787, null
  br i1 %t788, label %table_cow_alloc_147, label %table_cow_check_148
table_cow_alloc_147:
  %t789 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t790 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t791 = ptrtoint { i64, i64, i32*, i8** }* %t790 to i64
  %t792 = call i8* @star_rc_alloc(i64 %t791, i8* %t789)
  %t793 = bitcast i8* %t792 to { i64, i64, i32*, i8** }*
  %t794 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t793, i32 0, i32 0
  store i64 0, i64* %t794
  %t795 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t793, i32 0, i32 1
  store i64 0, i64* %t795
  %t796 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t793, i32 0, i32 2
  store i32* null, i32** %t796
  %t797 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t793, i32 0, i32 3
  store i8** null, i8*** %t797
  store i8* %t792, i8** %t786
  br label %table_cow_done_149
table_cow_check_148:
  %t798 = getelementptr inbounds i8, i8* %t787, i64 -16
  %t799 = bitcast i8* %t798 to i64*
  %t800 = load atomic i64, i64* %t799 seq_cst, align 8
  %t801 = icmp eq i64 %t800, 1
  br i1 %t801, label %table_cow_done_149, label %table_cow_clone_150
table_cow_clone_150:
  %t802 = bitcast i8* %t787 to { i64, i64, i32*, i8** }*
  %t803 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t802, i32 0, i32 0
  %t804 = load i64, i64* %t803
  %t805 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t802, i32 0, i32 1
  %t806 = load i64, i64* %t805
  %t807 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t808 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t809 = ptrtoint { i64, i64, i32*, i8** }* %t808 to i64
  %t810 = call i8* @star_rc_alloc(i64 %t809, i8* %t807)
  %t811 = bitcast i8* %t810 to { i64, i64, i32*, i8** }*
  %t812 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t811, i32 0, i32 0
  store i64 %t804, i64* %t812
  %t813 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t811, i32 0, i32 1
  store i64 %t806, i64* %t813
  %t814 = getelementptr i32, i32* null, i32 1
  %t815 = ptrtoint i32* %t814 to i64
  %t816 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t802, i32 0, i32 2
  %t817 = load i32*, i32** %t816
  %t818 = mul i64 %t806, %t815
  %t819 = call i8* @malloc(i64 %t818)
  %t820 = bitcast i8* %t819 to i32*
  %t821 = icmp sgt i64 %t804, 0
  br i1 %t821, label %table_cow_copy_151, label %table_cow_after_copy_152
table_cow_copy_151:
  %t822 = mul i64 %t804, %t815
  %t823 = bitcast i32* %t817 to i8*
  call i8* @memcpy(i8* %t819, i8* %t823, i64 %t822)
  br label %table_cow_after_copy_152
table_cow_after_copy_152:
  %t824 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t811, i32 0, i32 2
  store i32* %t820, i32** %t824
  %t825 = getelementptr i8*, i8** null, i32 1
  %t826 = ptrtoint i8** %t825 to i64
  %t827 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t802, i32 0, i32 3
  %t828 = load i8**, i8*** %t827
  %t829 = mul i64 %t806, %t826
  %t830 = call i8* @malloc(i64 %t829)
  %t831 = bitcast i8* %t830 to i8**
  %t832 = icmp sgt i64 %t804, 0
  br i1 %t832, label %table_cow_copy_153, label %table_cow_after_copy_154
table_cow_copy_153:
  %t833 = mul i64 %t804, %t826
  %t834 = bitcast i8** %t828 to i8*
  call i8* @memcpy(i8* %t830, i8* %t834, i64 %t833)
  store i64 0, i64* %t835
  br label %table_cow_retain_cond_155
table_cow_retain_cond_155:
  %t836 = load i64, i64* %t835
  %t837 = icmp slt i64 %t836, %t804
  br i1 %t837, label %table_cow_retain_body_156, label %table_cow_retain_end_157
table_cow_retain_body_156:
  %t838 = getelementptr inbounds i8*, i8** %t831, i64 %t836
  %t839 = load i8*, i8** %t838
  call void @star_rc_retain(i8* %t839)
  %t840 = add i64 %t836, 1
  store i64 %t840, i64* %t835
  br label %table_cow_retain_cond_155
table_cow_retain_end_157:
  br label %table_cow_after_copy_154
table_cow_after_copy_154:
  %t841 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t811, i32 0, i32 3
  store i8** %t831, i8*** %t841
  call void @star_rc_release(i8* %t787)
  store i8* %t810, i8** %t786
  br label %table_cow_done_149
table_cow_done_149:
  %t842 = load i8*, i8** %t786
  %t843 = bitcast i8* %t842 to { i64, i64, i32*, i8** }*
  %t844 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t843, i32 0, i32 0
  %t845 = load i64, i64* %t844
  %t846 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t843, i32 0, i32 1
  %t847 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t843, i32 0, i32 2
  %t848 = load i32*, i32** %t847
  %t849 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t843, i32 0, i32 3
  %t850 = load i8**, i8*** %t849
  %t852 = getelementptr inbounds %Enemy, %Enemy* %t851, i32 0, i32 0
  store i32 1, i32* %t852
  %t853 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t854 = getelementptr inbounds %Enemy, %Enemy* %t851, i32 0, i32 1
  store i8* %t853, i8** %t854
  %t855 = load %Enemy, %Enemy* %t851
  %t856 = load i64, i64* %t846
  %t857 = load i64, i64* %t844
  %t858 = load i32*, i32** %t847
  %t859 = load i8**, i8*** %t849
  %t860 = icmp sge i64 %t857, %t856
  br i1 %t860, label %table_push_grow_158, label %table_push_store_159
table_push_grow_158:
  %t861 = mul i64 %t856, 2
  %t862 = icmp sgt i64 %t861, 0
  %t863 = select i1 %t862, i64 %t861, i64 1
  %t864 = getelementptr i32, i32* null, i32 1
  %t865 = ptrtoint i32* %t864 to i64
  %t866 = mul i64 %t863, %t865
  %t867 = call i8* @malloc(i64 %t866)
  %t868 = bitcast i8* %t867 to i32*
  %t869 = icmp sgt i64 %t856, 0
  br i1 %t869, label %table_push_copy_160, label %table_push_after_copy_161
table_push_copy_160:
  %t870 = mul i64 %t857, %t865
  %t871 = bitcast i32* %t858 to i8*
  call i8* @memcpy(i8* %t867, i8* %t871, i64 %t870)
  call void @free(i8* %t871)
  br label %table_push_after_copy_161
table_push_after_copy_161:
  store i32* %t868, i32** %t847
  %t872 = getelementptr i8*, i8** null, i32 1
  %t873 = ptrtoint i8** %t872 to i64
  %t874 = mul i64 %t863, %t873
  %t875 = call i8* @malloc(i64 %t874)
  %t876 = bitcast i8* %t875 to i8**
  %t877 = icmp sgt i64 %t856, 0
  br i1 %t877, label %table_push_copy_162, label %table_push_after_copy_163
table_push_copy_162:
  %t878 = mul i64 %t857, %t873
  %t879 = bitcast i8** %t859 to i8*
  call i8* @memcpy(i8* %t875, i8* %t879, i64 %t878)
  call void @free(i8* %t879)
  br label %table_push_after_copy_163
table_push_after_copy_163:
  store i8** %t876, i8*** %t849
  store i64 %t863, i64* %t846
  br label %table_push_store_159
table_push_store_159:
  %t880 = load i32*, i32** %t847
  %t881 = extractvalue %Enemy %t855, 0
  %t882 = getelementptr inbounds i32, i32* %t880, i64 %t857
  store i32 %t881, i32* %t882
  %t883 = load i8**, i8*** %t849
  %t884 = extractvalue %Enemy %t855, 1
  %t885 = getelementptr inbounds i8*, i8** %t883, i64 %t857
  store i8* %t884, i8** %t885
  %t886 = add i64 %t857, 1
  store i64 %t886, i64* %t844
  %t888 = load i8*, i8** %t786
  %t889 = load i8*, i8** %t786
  call void @star_rc_retain(i8* %t889)
  store i8* %t888, i8** %t887
  %t890 = load i8*, i8** %t887
  %t891 = icmp eq i8* %t890, null
  br i1 %t891, label %table_cow_alloc_164, label %table_cow_check_165
table_cow_alloc_164:
  %t892 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t893 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t894 = ptrtoint { i64, i64, i32*, i8** }* %t893 to i64
  %t895 = call i8* @star_rc_alloc(i64 %t894, i8* %t892)
  %t896 = bitcast i8* %t895 to { i64, i64, i32*, i8** }*
  %t897 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t896, i32 0, i32 0
  store i64 0, i64* %t897
  %t898 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t896, i32 0, i32 1
  store i64 0, i64* %t898
  %t899 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t896, i32 0, i32 2
  store i32* null, i32** %t899
  %t900 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t896, i32 0, i32 3
  store i8** null, i8*** %t900
  store i8* %t895, i8** %t887
  br label %table_cow_done_166
table_cow_check_165:
  %t901 = getelementptr inbounds i8, i8* %t890, i64 -16
  %t902 = bitcast i8* %t901 to i64*
  %t903 = load atomic i64, i64* %t902 seq_cst, align 8
  %t904 = icmp eq i64 %t903, 1
  br i1 %t904, label %table_cow_done_166, label %table_cow_clone_167
table_cow_clone_167:
  %t905 = bitcast i8* %t890 to { i64, i64, i32*, i8** }*
  %t906 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t905, i32 0, i32 0
  %t907 = load i64, i64* %t906
  %t908 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t905, i32 0, i32 1
  %t909 = load i64, i64* %t908
  %t910 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t911 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t912 = ptrtoint { i64, i64, i32*, i8** }* %t911 to i64
  %t913 = call i8* @star_rc_alloc(i64 %t912, i8* %t910)
  %t914 = bitcast i8* %t913 to { i64, i64, i32*, i8** }*
  %t915 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t914, i32 0, i32 0
  store i64 %t907, i64* %t915
  %t916 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t914, i32 0, i32 1
  store i64 %t909, i64* %t916
  %t917 = getelementptr i32, i32* null, i32 1
  %t918 = ptrtoint i32* %t917 to i64
  %t919 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t905, i32 0, i32 2
  %t920 = load i32*, i32** %t919
  %t921 = mul i64 %t909, %t918
  %t922 = call i8* @malloc(i64 %t921)
  %t923 = bitcast i8* %t922 to i32*
  %t924 = icmp sgt i64 %t907, 0
  br i1 %t924, label %table_cow_copy_168, label %table_cow_after_copy_169
table_cow_copy_168:
  %t925 = mul i64 %t907, %t918
  %t926 = bitcast i32* %t920 to i8*
  call i8* @memcpy(i8* %t922, i8* %t926, i64 %t925)
  br label %table_cow_after_copy_169
table_cow_after_copy_169:
  %t927 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t914, i32 0, i32 2
  store i32* %t923, i32** %t927
  %t928 = getelementptr i8*, i8** null, i32 1
  %t929 = ptrtoint i8** %t928 to i64
  %t930 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t905, i32 0, i32 3
  %t931 = load i8**, i8*** %t930
  %t932 = mul i64 %t909, %t929
  %t933 = call i8* @malloc(i64 %t932)
  %t934 = bitcast i8* %t933 to i8**
  %t935 = icmp sgt i64 %t907, 0
  br i1 %t935, label %table_cow_copy_170, label %table_cow_after_copy_171
table_cow_copy_170:
  %t936 = mul i64 %t907, %t929
  %t937 = bitcast i8** %t931 to i8*
  call i8* @memcpy(i8* %t933, i8* %t937, i64 %t936)
  store i64 0, i64* %t938
  br label %table_cow_retain_cond_172
table_cow_retain_cond_172:
  %t939 = load i64, i64* %t938
  %t940 = icmp slt i64 %t939, %t907
  br i1 %t940, label %table_cow_retain_body_173, label %table_cow_retain_end_174
table_cow_retain_body_173:
  %t941 = getelementptr inbounds i8*, i8** %t934, i64 %t939
  %t942 = load i8*, i8** %t941
  call void @star_rc_retain(i8* %t942)
  %t943 = add i64 %t939, 1
  store i64 %t943, i64* %t938
  br label %table_cow_retain_cond_172
table_cow_retain_end_174:
  br label %table_cow_after_copy_171
table_cow_after_copy_171:
  %t944 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t914, i32 0, i32 3
  store i8** %t934, i8*** %t944
  call void @star_rc_release(i8* %t890)
  store i8* %t913, i8** %t887
  br label %table_cow_done_166
table_cow_done_166:
  %t945 = load i8*, i8** %t887
  %t946 = bitcast i8* %t945 to { i64, i64, i32*, i8** }*
  %t947 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t946, i32 0, i32 0
  %t948 = load i64, i64* %t947
  %t949 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t946, i32 0, i32 1
  %t950 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t946, i32 0, i32 2
  %t951 = load i32*, i32** %t950
  %t952 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t946, i32 0, i32 3
  %t953 = load i8**, i8*** %t952
  %t955 = getelementptr inbounds %Enemy, %Enemy* %t954, i32 0, i32 0
  store i32 2, i32* %t955
  %t956 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t957 = getelementptr inbounds %Enemy, %Enemy* %t954, i32 0, i32 1
  store i8* %t956, i8** %t957
  %t958 = load %Enemy, %Enemy* %t954
  %t959 = load i64, i64* %t949
  %t960 = load i64, i64* %t947
  %t961 = load i32*, i32** %t950
  %t962 = load i8**, i8*** %t952
  %t963 = icmp sge i64 %t960, %t959
  br i1 %t963, label %table_push_grow_175, label %table_push_store_176
table_push_grow_175:
  %t964 = mul i64 %t959, 2
  %t965 = icmp sgt i64 %t964, 0
  %t966 = select i1 %t965, i64 %t964, i64 1
  %t967 = getelementptr i32, i32* null, i32 1
  %t968 = ptrtoint i32* %t967 to i64
  %t969 = mul i64 %t966, %t968
  %t970 = call i8* @malloc(i64 %t969)
  %t971 = bitcast i8* %t970 to i32*
  %t972 = icmp sgt i64 %t959, 0
  br i1 %t972, label %table_push_copy_177, label %table_push_after_copy_178
table_push_copy_177:
  %t973 = mul i64 %t960, %t968
  %t974 = bitcast i32* %t961 to i8*
  call i8* @memcpy(i8* %t970, i8* %t974, i64 %t973)
  call void @free(i8* %t974)
  br label %table_push_after_copy_178
table_push_after_copy_178:
  store i32* %t971, i32** %t950
  %t975 = getelementptr i8*, i8** null, i32 1
  %t976 = ptrtoint i8** %t975 to i64
  %t977 = mul i64 %t966, %t976
  %t978 = call i8* @malloc(i64 %t977)
  %t979 = bitcast i8* %t978 to i8**
  %t980 = icmp sgt i64 %t959, 0
  br i1 %t980, label %table_push_copy_179, label %table_push_after_copy_180
table_push_copy_179:
  %t981 = mul i64 %t960, %t976
  %t982 = bitcast i8** %t962 to i8*
  call i8* @memcpy(i8* %t978, i8* %t982, i64 %t981)
  call void @free(i8* %t982)
  br label %table_push_after_copy_180
table_push_after_copy_180:
  store i8** %t979, i8*** %t952
  store i64 %t966, i64* %t949
  br label %table_push_store_176
table_push_store_176:
  %t983 = load i32*, i32** %t950
  %t984 = extractvalue %Enemy %t958, 0
  %t985 = getelementptr inbounds i32, i32* %t983, i64 %t960
  store i32 %t984, i32* %t985
  %t986 = load i8**, i8*** %t952
  %t987 = extractvalue %Enemy %t958, 1
  %t988 = getelementptr inbounds i8*, i8** %t986, i64 %t960
  store i8* %t987, i8** %t988
  %t989 = add i64 %t960, 1
  store i64 %t989, i64* %t947
  %t990 = load i8*, i8** %t786
  %t991 = icmp eq i8* %t990, null
  br i1 %t991, label %table_read_null_181, label %table_read_real_182
table_read_null_181:
  br label %table_read_end_183
table_read_real_182:
  %t992 = bitcast i8* %t990 to { i64, i64, i32*, i8** }*
  %t993 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t992, i32 0, i32 0
  %t994 = load i64, i64* %t993
  %t995 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t992, i32 0, i32 2
  %t996 = load i32*, i32** %t995
  %t997 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t992, i32 0, i32 3
  %t998 = load i8**, i8*** %t997
  br label %table_read_end_183
table_read_end_183:
  %t999 = phi i64 [ 0, %table_read_null_181 ], [ %t994, %table_read_real_182 ]
  %t1000 = phi i32* [ null, %table_read_null_181 ], [ %t996, %table_read_real_182 ]
  %t1001 = phi i8** [ null, %table_read_null_181 ], [ %t998, %table_read_real_182 ]
  %t1002 = trunc i64 %t999 to i32
  %t1003 = load i8*, i8** %t887
  %t1004 = icmp eq i8* %t1003, null
  br i1 %t1004, label %table_read_null_184, label %table_read_real_185
table_read_null_184:
  br label %table_read_end_186
table_read_real_185:
  %t1005 = bitcast i8* %t1003 to { i64, i64, i32*, i8** }*
  %t1006 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1005, i32 0, i32 0
  %t1007 = load i64, i64* %t1006
  %t1008 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1005, i32 0, i32 2
  %t1009 = load i32*, i32** %t1008
  %t1010 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1005, i32 0, i32 3
  %t1011 = load i8**, i8*** %t1010
  br label %table_read_end_186
table_read_end_186:
  %t1012 = phi i64 [ 0, %table_read_null_184 ], [ %t1007, %table_read_real_185 ]
  %t1013 = phi i32* [ null, %table_read_null_184 ], [ %t1009, %table_read_real_185 ]
  %t1014 = phi i8** [ null, %table_read_null_184 ], [ %t1011, %table_read_real_185 ]
  %t1015 = trunc i64 %t1012 to i32
  %t1016 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.15, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1016, i32 %t1002, i32 %t1015)
  %t1017 = sext i32 0 to i64
  %t1018 = load i8*, i8** %t786
  %t1019 = icmp eq i8* %t1018, null
  br i1 %t1019, label %table_read_null_187, label %table_read_real_188
table_read_null_187:
  br label %table_read_end_189
table_read_real_188:
  %t1020 = bitcast i8* %t1018 to { i64, i64, i32*, i8** }*
  %t1021 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1020, i32 0, i32 0
  %t1022 = load i64, i64* %t1021
  %t1023 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1020, i32 0, i32 2
  %t1024 = load i32*, i32** %t1023
  %t1025 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1020, i32 0, i32 3
  %t1026 = load i8**, i8*** %t1025
  br label %table_read_end_189
table_read_end_189:
  %t1027 = phi i64 [ 0, %table_read_null_187 ], [ %t1022, %table_read_real_188 ]
  %t1028 = phi i32* [ null, %table_read_null_187 ], [ %t1024, %table_read_real_188 ]
  %t1029 = phi i8** [ null, %table_read_null_187 ], [ %t1026, %table_read_real_188 ]
  %t1031 = icmp ult i64 %t1017, %t1027
  br i1 %t1031, label %table_idx_ok_190, label %table_idx_oob_191
table_idx_ok_190:
  %t1032 = getelementptr inbounds i32, i32* %t1028, i64 %t1017
  %t1033 = load i32, i32* %t1032
  %t1034 = getelementptr inbounds %Enemy, %Enemy* %t1030, i32 0, i32 0
  store i32 %t1033, i32* %t1034
  %t1035 = getelementptr inbounds i8*, i8** %t1029, i64 %t1017
  %t1036 = load i8*, i8** %t1035
  call void @star_rc_retain(i8* %t1036)
  %t1037 = load i8*, i8** %t1035
  %t1038 = getelementptr inbounds %Enemy, %Enemy* %t1030, i32 0, i32 1
  store i8* %t1037, i8** %t1038
  br label %table_idx_end_192
table_idx_oob_191:
  store %Enemy zeroinitializer, %Enemy* %t1030
  br label %table_idx_end_192
table_idx_end_192:
  %t1039 = load %Enemy, %Enemy* %t1030
  store %Enemy %t1039, %Enemy* %t1040
  %t1041 = getelementptr inbounds %Enemy, %Enemy* %t1040, i32 0, i32 0
  %t1042 = load i32, i32* %t1041
  %t1043 = sext i32 0 to i64
  %t1044 = load i8*, i8** %t887
  %t1045 = icmp eq i8* %t1044, null
  br i1 %t1045, label %table_read_null_193, label %table_read_real_194
table_read_null_193:
  br label %table_read_end_195
table_read_real_194:
  %t1046 = bitcast i8* %t1044 to { i64, i64, i32*, i8** }*
  %t1047 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1046, i32 0, i32 0
  %t1048 = load i64, i64* %t1047
  %t1049 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1046, i32 0, i32 2
  %t1050 = load i32*, i32** %t1049
  %t1051 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1046, i32 0, i32 3
  %t1052 = load i8**, i8*** %t1051
  br label %table_read_end_195
table_read_end_195:
  %t1053 = phi i64 [ 0, %table_read_null_193 ], [ %t1048, %table_read_real_194 ]
  %t1054 = phi i32* [ null, %table_read_null_193 ], [ %t1050, %table_read_real_194 ]
  %t1055 = phi i8** [ null, %table_read_null_193 ], [ %t1052, %table_read_real_194 ]
  %t1057 = icmp ult i64 %t1043, %t1053
  br i1 %t1057, label %table_idx_ok_196, label %table_idx_oob_197
table_idx_ok_196:
  %t1058 = getelementptr inbounds i32, i32* %t1054, i64 %t1043
  %t1059 = load i32, i32* %t1058
  %t1060 = getelementptr inbounds %Enemy, %Enemy* %t1056, i32 0, i32 0
  store i32 %t1059, i32* %t1060
  %t1061 = getelementptr inbounds i8*, i8** %t1055, i64 %t1043
  %t1062 = load i8*, i8** %t1061
  call void @star_rc_retain(i8* %t1062)
  %t1063 = load i8*, i8** %t1061
  %t1064 = getelementptr inbounds %Enemy, %Enemy* %t1056, i32 0, i32 1
  store i8* %t1063, i8** %t1064
  br label %table_idx_end_198
table_idx_oob_197:
  store %Enemy zeroinitializer, %Enemy* %t1056
  br label %table_idx_end_198
table_idx_end_198:
  %t1065 = load %Enemy, %Enemy* %t1056
  store %Enemy %t1065, %Enemy* %t1066
  %t1067 = getelementptr inbounds %Enemy, %Enemy* %t1066, i32 0, i32 0
  %t1068 = load i32, i32* %t1067
  %t1069 = getelementptr inbounds [38 x i8], [38 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1069, i32 %t1042, i32 %t1068)
  %t1070 = getelementptr inbounds %Enemy, %Enemy* %t1066, i32 0, i32 1
  %t1071 = load i8*, i8** %t1070
  call void @star_rc_release(i8* %t1071)
  %t1072 = getelementptr inbounds %Enemy, %Enemy* %t1040, i32 0, i32 1
  %t1073 = load i8*, i8** %t1072
  call void @star_rc_release(i8* %t1073)
  %t1074 = load i8*, i8** %t887
  call void @star_rc_release(i8* %t1074)
  %t1075 = load i8*, i8** %t786
  call void @star_rc_release(i8* %t1075)
  %t1076 = getelementptr inbounds %Enemy, %Enemy* %t708, i32 0, i32 1
  %t1077 = load i8*, i8** %t1076
  call void @star_rc_release(i8* %t1077)
  %t1078 = load i8*, i8** %t707
  call void @star_rc_release(i8* %t1078)
  %t1079 = getelementptr inbounds %Enemy, %Enemy* %t703, i32 0, i32 1
  %t1080 = load i8*, i8** %t1079
  call void @star_rc_release(i8* %t1080)
  %t1081 = getelementptr inbounds %Enemy, %Enemy* %t585, i32 0, i32 1
  %t1082 = load i8*, i8** %t1081
  call void @star_rc_release(i8* %t1082)
  %t1083 = getelementptr inbounds %Enemy, %Enemy* %t581, i32 0, i32 1
  %t1084 = load i8*, i8** %t1083
  call void @star_rc_release(i8* %t1084)
  %t1085 = getelementptr inbounds %Enemy, %Enemy* %t554, i32 0, i32 1
  %t1086 = load i8*, i8** %t1085
  call void @star_rc_release(i8* %t1086)
  %t1087 = getelementptr inbounds %Enemy, %Enemy* %t448, i32 0, i32 1
  %t1088 = load i8*, i8** %t1087
  call void @star_rc_release(i8* %t1088)
  %t1089 = getelementptr inbounds %Enemy, %Enemy* %t421, i32 0, i32 1
  %t1090 = load i8*, i8** %t1089
  call void @star_rc_release(i8* %t1090)
  %t1091 = getelementptr inbounds %Enemy, %Enemy* %t394, i32 0, i32 1
  %t1092 = load i8*, i8** %t1091
  call void @star_rc_release(i8* %t1092)
  %t1093 = getelementptr inbounds %Enemy, %Enemy* %t367, i32 0, i32 1
  %t1094 = load i8*, i8** %t1093
  call void @star_rc_release(i8* %t1094)
  %t1095 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t1095)
  ret i32 0
}


; par/swarm worker functions
define void @table_release_s_Enemy(i8* %objp) {
entry:
  %t25 = alloca i64
  %t17 = bitcast i8* %objp to { i64, i64, i32*, i8** }*
  %t18 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t17, i32 0, i32 0
  %t19 = load i64, i64* %t18
  %t20 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t17, i32 0, i32 2
  %t21 = load i32*, i32** %t20
  %t22 = bitcast i32* %t21 to i8*
  call void @free(i8* %t22)
  %t23 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t17, i32 0, i32 3
  %t24 = load i8**, i8*** %t23
  store i64 0, i64* %t25
  br label %table_release_cond_6
table_release_cond_6:
  %t26 = load i64, i64* %t25
  %t27 = icmp slt i64 %t26, %t19
  br i1 %t27, label %table_release_body_7, label %table_release_end_8
table_release_body_7:
  %t28 = getelementptr inbounds i8*, i8** %t24, i64 %t26
  %t29 = load i8*, i8** %t28
  call void @star_rc_release(i8* %t29)
  %t30 = add i64 %t26, 1
  store i64 %t30, i64* %t25
  br label %table_release_cond_6
table_release_end_8:
  %t31 = bitcast i8** %t24 to i8*
  call void @free(i8* %t31)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant [16 x i8] c"empty len = %d\0A\00"
@.str.1 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"Goblin\00" }
@.str.2 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"Orc\00" }
@.str.3 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"Troll\00" }
@.str.4 = private unnamed_addr constant [25 x i8] c"after 3 pushes len = %d\0A\00"
@.str.5 = private unnamed_addr constant [23 x i8] c"enemies[0] = %s hp=%d\0A\00"
@.str.6 = private unnamed_addr constant [23 x i8] c"enemies[2] = %s hp=%d\0A\00"
@.str.7 = private unnamed_addr constant { i64, i8*, [10 x i8] } { i64 -1, i8* null, [10 x i8] c"Orc Chief\00" }
@.str.8 = private unnamed_addr constant [33 x i8] c"enemies[1] after set = %s hp=%d\0A\00"
@.str.9 = private unnamed_addr constant [19 x i8] c"popped = %s hp=%d\0A\00"
@.str.10 = private unnamed_addr constant [20 x i8] c"len after pop = %d\0A\00"
@.str.11 = private unnamed_addr constant [21 x i8] c"enemies[99] hp = %d\0A\00"
@.str.12 = private unnamed_addr constant [24 x i8] c"pop from empty hp = %d\0A\00"
@.str.13 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"A\00" }
@.str.14 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"B\00" }
@.str.15 = private unnamed_addr constant [34 x i8] c"original len = %d clone len = %d\0A\00"
@.str.16 = private unnamed_addr constant [38 x i8] c"original[0] hp = %d clone[0] hp = %d\0A\00"
