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
  %t383 = alloca %Enemy
  %t393 = alloca %Enemy
  %t410 = alloca %Enemy
  %t420 = alloca %Enemy
  %t436 = alloca %Enemy
  %t446 = alloca %Enemy
  %t450 = alloca %Enemy
  %t504 = alloca i64
  %t526 = alloca %Enemy
  %t542 = alloca %Enemy
  %t552 = alloca %Enemy
  %t568 = alloca %Enemy
  %t578 = alloca %Enemy
  %t582 = alloca %Enemy
  %t631 = alloca i64
  %t647 = alloca %Enemy
  %t690 = alloca %Enemy
  %t700 = alloca %Enemy
  %t704 = alloca i8*
  %t705 = alloca %Enemy
  %t754 = alloca i64
  %t770 = alloca %Enemy
  %t783 = alloca i8*
  %t832 = alloca i64
  %t848 = alloca %Enemy
  %t884 = alloca i8*
  %t935 = alloca i64
  %t951 = alloca %Enemy
  %t1027 = alloca %Enemy
  %t1037 = alloca %Enemy
  %t1053 = alloca %Enemy
  %t1063 = alloca %Enemy
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
  call void @star_rc_release(i8* %t369)
  %t370 = sext i32 0 to i64
  %t371 = load i8*, i8** %t0
  %t372 = icmp eq i8* %t371, null
  br i1 %t372, label %table_read_null_66, label %table_read_real_67
table_read_null_66:
  br label %table_read_end_68
table_read_real_67:
  %t373 = bitcast i8* %t371 to { i64, i64, i32*, i8** }*
  %t374 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t373, i32 0, i32 0
  %t375 = load i64, i64* %t374
  %t376 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t373, i32 0, i32 2
  %t377 = load i32*, i32** %t376
  %t378 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t373, i32 0, i32 3
  %t379 = load i8**, i8*** %t378
  br label %table_read_end_68
table_read_end_68:
  %t380 = phi i64 [ 0, %table_read_null_66 ], [ %t375, %table_read_real_67 ]
  %t381 = phi i32* [ null, %table_read_null_66 ], [ %t377, %table_read_real_67 ]
  %t382 = phi i8** [ null, %table_read_null_66 ], [ %t379, %table_read_real_67 ]
  %t384 = icmp ult i64 %t370, %t380
  br i1 %t384, label %table_idx_ok_69, label %table_idx_oob_70
table_idx_ok_69:
  %t385 = getelementptr inbounds i32, i32* %t381, i64 %t370
  %t386 = load i32, i32* %t385
  %t387 = getelementptr inbounds %Enemy, %Enemy* %t383, i32 0, i32 0
  store i32 %t386, i32* %t387
  %t388 = getelementptr inbounds i8*, i8** %t382, i64 %t370
  %t389 = load i8*, i8** %t388
  call void @star_rc_retain(i8* %t389)
  %t390 = load i8*, i8** %t388
  %t391 = getelementptr inbounds %Enemy, %Enemy* %t383, i32 0, i32 1
  store i8* %t390, i8** %t391
  br label %table_idx_end_71
table_idx_oob_70:
  store %Enemy zeroinitializer, %Enemy* %t383
  br label %table_idx_end_71
table_idx_end_71:
  %t392 = load %Enemy, %Enemy* %t383
  store %Enemy %t392, %Enemy* %t393
  %t394 = getelementptr inbounds %Enemy, %Enemy* %t393, i32 0, i32 0
  %t395 = load i32, i32* %t394
  %t396 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t396, i8* %t369, i32 %t395)
  %t397 = sext i32 2 to i64
  %t398 = load i8*, i8** %t0
  %t399 = icmp eq i8* %t398, null
  br i1 %t399, label %table_read_null_72, label %table_read_real_73
table_read_null_72:
  br label %table_read_end_74
table_read_real_73:
  %t400 = bitcast i8* %t398 to { i64, i64, i32*, i8** }*
  %t401 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t400, i32 0, i32 0
  %t402 = load i64, i64* %t401
  %t403 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t400, i32 0, i32 2
  %t404 = load i32*, i32** %t403
  %t405 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t400, i32 0, i32 3
  %t406 = load i8**, i8*** %t405
  br label %table_read_end_74
table_read_end_74:
  %t407 = phi i64 [ 0, %table_read_null_72 ], [ %t402, %table_read_real_73 ]
  %t408 = phi i32* [ null, %table_read_null_72 ], [ %t404, %table_read_real_73 ]
  %t409 = phi i8** [ null, %table_read_null_72 ], [ %t406, %table_read_real_73 ]
  %t411 = icmp ult i64 %t397, %t407
  br i1 %t411, label %table_idx_ok_75, label %table_idx_oob_76
table_idx_ok_75:
  %t412 = getelementptr inbounds i32, i32* %t408, i64 %t397
  %t413 = load i32, i32* %t412
  %t414 = getelementptr inbounds %Enemy, %Enemy* %t410, i32 0, i32 0
  store i32 %t413, i32* %t414
  %t415 = getelementptr inbounds i8*, i8** %t409, i64 %t397
  %t416 = load i8*, i8** %t415
  call void @star_rc_retain(i8* %t416)
  %t417 = load i8*, i8** %t415
  %t418 = getelementptr inbounds %Enemy, %Enemy* %t410, i32 0, i32 1
  store i8* %t417, i8** %t418
  br label %table_idx_end_77
table_idx_oob_76:
  store %Enemy zeroinitializer, %Enemy* %t410
  br label %table_idx_end_77
table_idx_end_77:
  %t419 = load %Enemy, %Enemy* %t410
  store %Enemy %t419, %Enemy* %t420
  %t421 = getelementptr inbounds %Enemy, %Enemy* %t420, i32 0, i32 1
  %t422 = load i8*, i8** %t421
  call void @star_rc_release(i8* %t422)
  %t423 = sext i32 2 to i64
  %t424 = load i8*, i8** %t0
  %t425 = icmp eq i8* %t424, null
  br i1 %t425, label %table_read_null_78, label %table_read_real_79
table_read_null_78:
  br label %table_read_end_80
table_read_real_79:
  %t426 = bitcast i8* %t424 to { i64, i64, i32*, i8** }*
  %t427 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t426, i32 0, i32 0
  %t428 = load i64, i64* %t427
  %t429 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t426, i32 0, i32 2
  %t430 = load i32*, i32** %t429
  %t431 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t426, i32 0, i32 3
  %t432 = load i8**, i8*** %t431
  br label %table_read_end_80
table_read_end_80:
  %t433 = phi i64 [ 0, %table_read_null_78 ], [ %t428, %table_read_real_79 ]
  %t434 = phi i32* [ null, %table_read_null_78 ], [ %t430, %table_read_real_79 ]
  %t435 = phi i8** [ null, %table_read_null_78 ], [ %t432, %table_read_real_79 ]
  %t437 = icmp ult i64 %t423, %t433
  br i1 %t437, label %table_idx_ok_81, label %table_idx_oob_82
table_idx_ok_81:
  %t438 = getelementptr inbounds i32, i32* %t434, i64 %t423
  %t439 = load i32, i32* %t438
  %t440 = getelementptr inbounds %Enemy, %Enemy* %t436, i32 0, i32 0
  store i32 %t439, i32* %t440
  %t441 = getelementptr inbounds i8*, i8** %t435, i64 %t423
  %t442 = load i8*, i8** %t441
  call void @star_rc_retain(i8* %t442)
  %t443 = load i8*, i8** %t441
  %t444 = getelementptr inbounds %Enemy, %Enemy* %t436, i32 0, i32 1
  store i8* %t443, i8** %t444
  br label %table_idx_end_83
table_idx_oob_82:
  store %Enemy zeroinitializer, %Enemy* %t436
  br label %table_idx_end_83
table_idx_end_83:
  %t445 = load %Enemy, %Enemy* %t436
  store %Enemy %t445, %Enemy* %t446
  %t447 = getelementptr inbounds %Enemy, %Enemy* %t446, i32 0, i32 0
  %t448 = load i32, i32* %t447
  %t449 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t449, i8* %t422, i32 %t448)
  %t451 = getelementptr inbounds %Enemy, %Enemy* %t450, i32 0, i32 0
  store i32 99, i32* %t451
  %t452 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t453 = getelementptr inbounds %Enemy, %Enemy* %t450, i32 0, i32 1
  store i8* %t452, i8** %t453
  %t454 = load %Enemy, %Enemy* %t450
  %t455 = sext i32 1 to i64
  %t456 = load i8*, i8** %t0
  %t457 = icmp eq i8* %t456, null
  br i1 %t457, label %table_cow_alloc_84, label %table_cow_check_85
table_cow_alloc_84:
  %t458 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t459 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t460 = ptrtoint { i64, i64, i32*, i8** }* %t459 to i64
  %t461 = call i8* @star_rc_alloc(i64 %t460, i8* %t458)
  %t462 = bitcast i8* %t461 to { i64, i64, i32*, i8** }*
  %t463 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t462, i32 0, i32 0
  store i64 0, i64* %t463
  %t464 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t462, i32 0, i32 1
  store i64 0, i64* %t464
  %t465 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t462, i32 0, i32 2
  store i32* null, i32** %t465
  %t466 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t462, i32 0, i32 3
  store i8** null, i8*** %t466
  store i8* %t461, i8** %t0
  br label %table_cow_done_86
table_cow_check_85:
  %t467 = getelementptr inbounds i8, i8* %t456, i64 -16
  %t468 = bitcast i8* %t467 to i64*
  %t469 = load atomic i64, i64* %t468 seq_cst, align 8
  %t470 = icmp eq i64 %t469, 1
  br i1 %t470, label %table_cow_done_86, label %table_cow_clone_87
table_cow_clone_87:
  %t471 = bitcast i8* %t456 to { i64, i64, i32*, i8** }*
  %t472 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t471, i32 0, i32 0
  %t473 = load i64, i64* %t472
  %t474 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t471, i32 0, i32 1
  %t475 = load i64, i64* %t474
  %t476 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t477 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t478 = ptrtoint { i64, i64, i32*, i8** }* %t477 to i64
  %t479 = call i8* @star_rc_alloc(i64 %t478, i8* %t476)
  %t480 = bitcast i8* %t479 to { i64, i64, i32*, i8** }*
  %t481 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t480, i32 0, i32 0
  store i64 %t473, i64* %t481
  %t482 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t480, i32 0, i32 1
  store i64 %t475, i64* %t482
  %t483 = getelementptr i32, i32* null, i32 1
  %t484 = ptrtoint i32* %t483 to i64
  %t485 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t471, i32 0, i32 2
  %t486 = load i32*, i32** %t485
  %t487 = mul i64 %t475, %t484
  %t488 = call i8* @malloc(i64 %t487)
  %t489 = bitcast i8* %t488 to i32*
  %t490 = icmp sgt i64 %t473, 0
  br i1 %t490, label %table_cow_copy_88, label %table_cow_after_copy_89
table_cow_copy_88:
  %t491 = mul i64 %t473, %t484
  %t492 = bitcast i32* %t486 to i8*
  call i8* @memcpy(i8* %t488, i8* %t492, i64 %t491)
  br label %table_cow_after_copy_89
table_cow_after_copy_89:
  %t493 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t480, i32 0, i32 2
  store i32* %t489, i32** %t493
  %t494 = getelementptr i8*, i8** null, i32 1
  %t495 = ptrtoint i8** %t494 to i64
  %t496 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t471, i32 0, i32 3
  %t497 = load i8**, i8*** %t496
  %t498 = mul i64 %t475, %t495
  %t499 = call i8* @malloc(i64 %t498)
  %t500 = bitcast i8* %t499 to i8**
  %t501 = icmp sgt i64 %t473, 0
  br i1 %t501, label %table_cow_copy_90, label %table_cow_after_copy_91
table_cow_copy_90:
  %t502 = mul i64 %t473, %t495
  %t503 = bitcast i8** %t497 to i8*
  call i8* @memcpy(i8* %t499, i8* %t503, i64 %t502)
  store i64 0, i64* %t504
  br label %table_cow_retain_cond_92
table_cow_retain_cond_92:
  %t505 = load i64, i64* %t504
  %t506 = icmp slt i64 %t505, %t473
  br i1 %t506, label %table_cow_retain_body_93, label %table_cow_retain_end_94
table_cow_retain_body_93:
  %t507 = getelementptr inbounds i8*, i8** %t500, i64 %t505
  %t508 = load i8*, i8** %t507
  call void @star_rc_retain(i8* %t508)
  %t509 = add i64 %t505, 1
  store i64 %t509, i64* %t504
  br label %table_cow_retain_cond_92
table_cow_retain_end_94:
  br label %table_cow_after_copy_91
table_cow_after_copy_91:
  %t510 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t480, i32 0, i32 3
  store i8** %t500, i8*** %t510
  call void @star_rc_release(i8* %t456)
  store i8* %t479, i8** %t0
  br label %table_cow_done_86
table_cow_done_86:
  %t511 = load i8*, i8** %t0
  %t512 = bitcast i8* %t511 to { i64, i64, i32*, i8** }*
  %t513 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t512, i32 0, i32 0
  %t514 = load i64, i64* %t513
  %t515 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t512, i32 0, i32 1
  %t516 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t512, i32 0, i32 2
  %t517 = load i32*, i32** %t516
  %t518 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t512, i32 0, i32 3
  %t519 = load i8**, i8*** %t518
  %t520 = icmp ult i64 %t455, %t514
  br i1 %t520, label %table_set_do_95, label %table_set_oob_96
table_set_do_95:
  %t521 = extractvalue %Enemy %t454, 0
  %t522 = getelementptr inbounds i32, i32* %t517, i64 %t455
  store i32 %t521, i32* %t522
  %t523 = extractvalue %Enemy %t454, 1
  %t524 = getelementptr inbounds i8*, i8** %t519, i64 %t455
  %t525 = load i8*, i8** %t524
  call void @star_rc_release(i8* %t525)
  store i8* %t523, i8** %t524
  br label %table_set_end_97
table_set_oob_96:
  store %Enemy %t454, %Enemy* %t526
  %t527 = getelementptr inbounds %Enemy, %Enemy* %t526, i32 0, i32 1
  %t528 = load i8*, i8** %t527
  call void @star_rc_release(i8* %t528)
  br label %table_set_end_97
table_set_end_97:
  %t529 = sext i32 1 to i64
  %t530 = load i8*, i8** %t0
  %t531 = icmp eq i8* %t530, null
  br i1 %t531, label %table_read_null_98, label %table_read_real_99
table_read_null_98:
  br label %table_read_end_100
table_read_real_99:
  %t532 = bitcast i8* %t530 to { i64, i64, i32*, i8** }*
  %t533 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t532, i32 0, i32 0
  %t534 = load i64, i64* %t533
  %t535 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t532, i32 0, i32 2
  %t536 = load i32*, i32** %t535
  %t537 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t532, i32 0, i32 3
  %t538 = load i8**, i8*** %t537
  br label %table_read_end_100
table_read_end_100:
  %t539 = phi i64 [ 0, %table_read_null_98 ], [ %t534, %table_read_real_99 ]
  %t540 = phi i32* [ null, %table_read_null_98 ], [ %t536, %table_read_real_99 ]
  %t541 = phi i8** [ null, %table_read_null_98 ], [ %t538, %table_read_real_99 ]
  %t543 = icmp ult i64 %t529, %t539
  br i1 %t543, label %table_idx_ok_101, label %table_idx_oob_102
table_idx_ok_101:
  %t544 = getelementptr inbounds i32, i32* %t540, i64 %t529
  %t545 = load i32, i32* %t544
  %t546 = getelementptr inbounds %Enemy, %Enemy* %t542, i32 0, i32 0
  store i32 %t545, i32* %t546
  %t547 = getelementptr inbounds i8*, i8** %t541, i64 %t529
  %t548 = load i8*, i8** %t547
  call void @star_rc_retain(i8* %t548)
  %t549 = load i8*, i8** %t547
  %t550 = getelementptr inbounds %Enemy, %Enemy* %t542, i32 0, i32 1
  store i8* %t549, i8** %t550
  br label %table_idx_end_103
table_idx_oob_102:
  store %Enemy zeroinitializer, %Enemy* %t542
  br label %table_idx_end_103
table_idx_end_103:
  %t551 = load %Enemy, %Enemy* %t542
  store %Enemy %t551, %Enemy* %t552
  %t553 = getelementptr inbounds %Enemy, %Enemy* %t552, i32 0, i32 1
  %t554 = load i8*, i8** %t553
  call void @star_rc_release(i8* %t554)
  %t555 = sext i32 1 to i64
  %t556 = load i8*, i8** %t0
  %t557 = icmp eq i8* %t556, null
  br i1 %t557, label %table_read_null_104, label %table_read_real_105
table_read_null_104:
  br label %table_read_end_106
table_read_real_105:
  %t558 = bitcast i8* %t556 to { i64, i64, i32*, i8** }*
  %t559 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t558, i32 0, i32 0
  %t560 = load i64, i64* %t559
  %t561 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t558, i32 0, i32 2
  %t562 = load i32*, i32** %t561
  %t563 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t558, i32 0, i32 3
  %t564 = load i8**, i8*** %t563
  br label %table_read_end_106
table_read_end_106:
  %t565 = phi i64 [ 0, %table_read_null_104 ], [ %t560, %table_read_real_105 ]
  %t566 = phi i32* [ null, %table_read_null_104 ], [ %t562, %table_read_real_105 ]
  %t567 = phi i8** [ null, %table_read_null_104 ], [ %t564, %table_read_real_105 ]
  %t569 = icmp ult i64 %t555, %t565
  br i1 %t569, label %table_idx_ok_107, label %table_idx_oob_108
table_idx_ok_107:
  %t570 = getelementptr inbounds i32, i32* %t566, i64 %t555
  %t571 = load i32, i32* %t570
  %t572 = getelementptr inbounds %Enemy, %Enemy* %t568, i32 0, i32 0
  store i32 %t571, i32* %t572
  %t573 = getelementptr inbounds i8*, i8** %t567, i64 %t555
  %t574 = load i8*, i8** %t573
  call void @star_rc_retain(i8* %t574)
  %t575 = load i8*, i8** %t573
  %t576 = getelementptr inbounds %Enemy, %Enemy* %t568, i32 0, i32 1
  store i8* %t575, i8** %t576
  br label %table_idx_end_109
table_idx_oob_108:
  store %Enemy zeroinitializer, %Enemy* %t568
  br label %table_idx_end_109
table_idx_end_109:
  %t577 = load %Enemy, %Enemy* %t568
  store %Enemy %t577, %Enemy* %t578
  %t579 = getelementptr inbounds %Enemy, %Enemy* %t578, i32 0, i32 0
  %t580 = load i32, i32* %t579
  %t581 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t581, i8* %t554, i32 %t580)
  %t583 = load i8*, i8** %t0
  %t584 = icmp eq i8* %t583, null
  br i1 %t584, label %table_cow_alloc_110, label %table_cow_check_111
table_cow_alloc_110:
  %t585 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t586 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t587 = ptrtoint { i64, i64, i32*, i8** }* %t586 to i64
  %t588 = call i8* @star_rc_alloc(i64 %t587, i8* %t585)
  %t589 = bitcast i8* %t588 to { i64, i64, i32*, i8** }*
  %t590 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t589, i32 0, i32 0
  store i64 0, i64* %t590
  %t591 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t589, i32 0, i32 1
  store i64 0, i64* %t591
  %t592 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t589, i32 0, i32 2
  store i32* null, i32** %t592
  %t593 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t589, i32 0, i32 3
  store i8** null, i8*** %t593
  store i8* %t588, i8** %t0
  br label %table_cow_done_112
table_cow_check_111:
  %t594 = getelementptr inbounds i8, i8* %t583, i64 -16
  %t595 = bitcast i8* %t594 to i64*
  %t596 = load atomic i64, i64* %t595 seq_cst, align 8
  %t597 = icmp eq i64 %t596, 1
  br i1 %t597, label %table_cow_done_112, label %table_cow_clone_113
table_cow_clone_113:
  %t598 = bitcast i8* %t583 to { i64, i64, i32*, i8** }*
  %t599 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t598, i32 0, i32 0
  %t600 = load i64, i64* %t599
  %t601 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t598, i32 0, i32 1
  %t602 = load i64, i64* %t601
  %t603 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t604 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t605 = ptrtoint { i64, i64, i32*, i8** }* %t604 to i64
  %t606 = call i8* @star_rc_alloc(i64 %t605, i8* %t603)
  %t607 = bitcast i8* %t606 to { i64, i64, i32*, i8** }*
  %t608 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t607, i32 0, i32 0
  store i64 %t600, i64* %t608
  %t609 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t607, i32 0, i32 1
  store i64 %t602, i64* %t609
  %t610 = getelementptr i32, i32* null, i32 1
  %t611 = ptrtoint i32* %t610 to i64
  %t612 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t598, i32 0, i32 2
  %t613 = load i32*, i32** %t612
  %t614 = mul i64 %t602, %t611
  %t615 = call i8* @malloc(i64 %t614)
  %t616 = bitcast i8* %t615 to i32*
  %t617 = icmp sgt i64 %t600, 0
  br i1 %t617, label %table_cow_copy_114, label %table_cow_after_copy_115
table_cow_copy_114:
  %t618 = mul i64 %t600, %t611
  %t619 = bitcast i32* %t613 to i8*
  call i8* @memcpy(i8* %t615, i8* %t619, i64 %t618)
  br label %table_cow_after_copy_115
table_cow_after_copy_115:
  %t620 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t607, i32 0, i32 2
  store i32* %t616, i32** %t620
  %t621 = getelementptr i8*, i8** null, i32 1
  %t622 = ptrtoint i8** %t621 to i64
  %t623 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t598, i32 0, i32 3
  %t624 = load i8**, i8*** %t623
  %t625 = mul i64 %t602, %t622
  %t626 = call i8* @malloc(i64 %t625)
  %t627 = bitcast i8* %t626 to i8**
  %t628 = icmp sgt i64 %t600, 0
  br i1 %t628, label %table_cow_copy_116, label %table_cow_after_copy_117
table_cow_copy_116:
  %t629 = mul i64 %t600, %t622
  %t630 = bitcast i8** %t624 to i8*
  call i8* @memcpy(i8* %t626, i8* %t630, i64 %t629)
  store i64 0, i64* %t631
  br label %table_cow_retain_cond_118
table_cow_retain_cond_118:
  %t632 = load i64, i64* %t631
  %t633 = icmp slt i64 %t632, %t600
  br i1 %t633, label %table_cow_retain_body_119, label %table_cow_retain_end_120
table_cow_retain_body_119:
  %t634 = getelementptr inbounds i8*, i8** %t627, i64 %t632
  %t635 = load i8*, i8** %t634
  call void @star_rc_retain(i8* %t635)
  %t636 = add i64 %t632, 1
  store i64 %t636, i64* %t631
  br label %table_cow_retain_cond_118
table_cow_retain_end_120:
  br label %table_cow_after_copy_117
table_cow_after_copy_117:
  %t637 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t607, i32 0, i32 3
  store i8** %t627, i8*** %t637
  call void @star_rc_release(i8* %t583)
  store i8* %t606, i8** %t0
  br label %table_cow_done_112
table_cow_done_112:
  %t638 = load i8*, i8** %t0
  %t639 = bitcast i8* %t638 to { i64, i64, i32*, i8** }*
  %t640 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t639, i32 0, i32 0
  %t641 = load i64, i64* %t640
  %t642 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t639, i32 0, i32 1
  %t643 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t639, i32 0, i32 2
  %t644 = load i32*, i32** %t643
  %t645 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t639, i32 0, i32 3
  %t646 = load i8**, i8*** %t645
  %t648 = icmp eq i64 %t641, 0
  br i1 %t648, label %table_pop_empty_121, label %table_pop_nonempty_122
table_pop_nonempty_122:
  %t649 = sub i64 %t641, 1
  store i64 %t649, i64* %t640
  %t650 = getelementptr inbounds i32, i32* %t644, i64 %t649
  %t651 = load i32, i32* %t650
  %t652 = getelementptr inbounds %Enemy, %Enemy* %t647, i32 0, i32 0
  store i32 %t651, i32* %t652
  %t653 = getelementptr inbounds i8*, i8** %t646, i64 %t649
  %t654 = load i8*, i8** %t653
  %t655 = getelementptr inbounds %Enemy, %Enemy* %t647, i32 0, i32 1
  store i8* %t654, i8** %t655
  br label %table_pop_end_123
table_pop_empty_121:
  store %Enemy zeroinitializer, %Enemy* %t647
  br label %table_pop_end_123
table_pop_end_123:
  %t656 = load %Enemy, %Enemy* %t647
  store %Enemy %t656, %Enemy* %t582
  %t657 = getelementptr inbounds %Enemy, %Enemy* %t582, i32 0, i32 1
  %t658 = load i8*, i8** %t657
  %t659 = load i8*, i8** %t657
  call void @star_rc_retain(i8* %t659)
  call void @star_rc_release(i8* %t658)
  %t660 = getelementptr inbounds %Enemy, %Enemy* %t582, i32 0, i32 0
  %t661 = load i32, i32* %t660
  %t662 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t662, i8* %t658, i32 %t661)
  %t663 = load i8*, i8** %t0
  %t664 = icmp eq i8* %t663, null
  br i1 %t664, label %table_read_null_124, label %table_read_real_125
table_read_null_124:
  br label %table_read_end_126
table_read_real_125:
  %t665 = bitcast i8* %t663 to { i64, i64, i32*, i8** }*
  %t666 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t665, i32 0, i32 0
  %t667 = load i64, i64* %t666
  %t668 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t665, i32 0, i32 2
  %t669 = load i32*, i32** %t668
  %t670 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t665, i32 0, i32 3
  %t671 = load i8**, i8*** %t670
  br label %table_read_end_126
table_read_end_126:
  %t672 = phi i64 [ 0, %table_read_null_124 ], [ %t667, %table_read_real_125 ]
  %t673 = phi i32* [ null, %table_read_null_124 ], [ %t669, %table_read_real_125 ]
  %t674 = phi i8** [ null, %table_read_null_124 ], [ %t671, %table_read_real_125 ]
  %t675 = trunc i64 %t672 to i32
  %t676 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t676, i32 %t675)
  %t677 = sext i32 99 to i64
  %t678 = load i8*, i8** %t0
  %t679 = icmp eq i8* %t678, null
  br i1 %t679, label %table_read_null_127, label %table_read_real_128
table_read_null_127:
  br label %table_read_end_129
table_read_real_128:
  %t680 = bitcast i8* %t678 to { i64, i64, i32*, i8** }*
  %t681 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t680, i32 0, i32 0
  %t682 = load i64, i64* %t681
  %t683 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t680, i32 0, i32 2
  %t684 = load i32*, i32** %t683
  %t685 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t680, i32 0, i32 3
  %t686 = load i8**, i8*** %t685
  br label %table_read_end_129
table_read_end_129:
  %t687 = phi i64 [ 0, %table_read_null_127 ], [ %t682, %table_read_real_128 ]
  %t688 = phi i32* [ null, %table_read_null_127 ], [ %t684, %table_read_real_128 ]
  %t689 = phi i8** [ null, %table_read_null_127 ], [ %t686, %table_read_real_128 ]
  %t691 = icmp ult i64 %t677, %t687
  br i1 %t691, label %table_idx_ok_130, label %table_idx_oob_131
table_idx_ok_130:
  %t692 = getelementptr inbounds i32, i32* %t688, i64 %t677
  %t693 = load i32, i32* %t692
  %t694 = getelementptr inbounds %Enemy, %Enemy* %t690, i32 0, i32 0
  store i32 %t693, i32* %t694
  %t695 = getelementptr inbounds i8*, i8** %t689, i64 %t677
  %t696 = load i8*, i8** %t695
  call void @star_rc_retain(i8* %t696)
  %t697 = load i8*, i8** %t695
  %t698 = getelementptr inbounds %Enemy, %Enemy* %t690, i32 0, i32 1
  store i8* %t697, i8** %t698
  br label %table_idx_end_132
table_idx_oob_131:
  store %Enemy zeroinitializer, %Enemy* %t690
  br label %table_idx_end_132
table_idx_end_132:
  %t699 = load %Enemy, %Enemy* %t690
  store %Enemy %t699, %Enemy* %t700
  %t701 = getelementptr inbounds %Enemy, %Enemy* %t700, i32 0, i32 0
  %t702 = load i32, i32* %t701
  %t703 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t703, i32 %t702)
  store i8* null, i8** %t704
  %t706 = load i8*, i8** %t704
  %t707 = icmp eq i8* %t706, null
  br i1 %t707, label %table_cow_alloc_133, label %table_cow_check_134
table_cow_alloc_133:
  %t708 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t709 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t710 = ptrtoint { i64, i64, i32*, i8** }* %t709 to i64
  %t711 = call i8* @star_rc_alloc(i64 %t710, i8* %t708)
  %t712 = bitcast i8* %t711 to { i64, i64, i32*, i8** }*
  %t713 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t712, i32 0, i32 0
  store i64 0, i64* %t713
  %t714 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t712, i32 0, i32 1
  store i64 0, i64* %t714
  %t715 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t712, i32 0, i32 2
  store i32* null, i32** %t715
  %t716 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t712, i32 0, i32 3
  store i8** null, i8*** %t716
  store i8* %t711, i8** %t704
  br label %table_cow_done_135
table_cow_check_134:
  %t717 = getelementptr inbounds i8, i8* %t706, i64 -16
  %t718 = bitcast i8* %t717 to i64*
  %t719 = load atomic i64, i64* %t718 seq_cst, align 8
  %t720 = icmp eq i64 %t719, 1
  br i1 %t720, label %table_cow_done_135, label %table_cow_clone_136
table_cow_clone_136:
  %t721 = bitcast i8* %t706 to { i64, i64, i32*, i8** }*
  %t722 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t721, i32 0, i32 0
  %t723 = load i64, i64* %t722
  %t724 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t721, i32 0, i32 1
  %t725 = load i64, i64* %t724
  %t726 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t727 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t728 = ptrtoint { i64, i64, i32*, i8** }* %t727 to i64
  %t729 = call i8* @star_rc_alloc(i64 %t728, i8* %t726)
  %t730 = bitcast i8* %t729 to { i64, i64, i32*, i8** }*
  %t731 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t730, i32 0, i32 0
  store i64 %t723, i64* %t731
  %t732 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t730, i32 0, i32 1
  store i64 %t725, i64* %t732
  %t733 = getelementptr i32, i32* null, i32 1
  %t734 = ptrtoint i32* %t733 to i64
  %t735 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t721, i32 0, i32 2
  %t736 = load i32*, i32** %t735
  %t737 = mul i64 %t725, %t734
  %t738 = call i8* @malloc(i64 %t737)
  %t739 = bitcast i8* %t738 to i32*
  %t740 = icmp sgt i64 %t723, 0
  br i1 %t740, label %table_cow_copy_137, label %table_cow_after_copy_138
table_cow_copy_137:
  %t741 = mul i64 %t723, %t734
  %t742 = bitcast i32* %t736 to i8*
  call i8* @memcpy(i8* %t738, i8* %t742, i64 %t741)
  br label %table_cow_after_copy_138
table_cow_after_copy_138:
  %t743 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t730, i32 0, i32 2
  store i32* %t739, i32** %t743
  %t744 = getelementptr i8*, i8** null, i32 1
  %t745 = ptrtoint i8** %t744 to i64
  %t746 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t721, i32 0, i32 3
  %t747 = load i8**, i8*** %t746
  %t748 = mul i64 %t725, %t745
  %t749 = call i8* @malloc(i64 %t748)
  %t750 = bitcast i8* %t749 to i8**
  %t751 = icmp sgt i64 %t723, 0
  br i1 %t751, label %table_cow_copy_139, label %table_cow_after_copy_140
table_cow_copy_139:
  %t752 = mul i64 %t723, %t745
  %t753 = bitcast i8** %t747 to i8*
  call i8* @memcpy(i8* %t749, i8* %t753, i64 %t752)
  store i64 0, i64* %t754
  br label %table_cow_retain_cond_141
table_cow_retain_cond_141:
  %t755 = load i64, i64* %t754
  %t756 = icmp slt i64 %t755, %t723
  br i1 %t756, label %table_cow_retain_body_142, label %table_cow_retain_end_143
table_cow_retain_body_142:
  %t757 = getelementptr inbounds i8*, i8** %t750, i64 %t755
  %t758 = load i8*, i8** %t757
  call void @star_rc_retain(i8* %t758)
  %t759 = add i64 %t755, 1
  store i64 %t759, i64* %t754
  br label %table_cow_retain_cond_141
table_cow_retain_end_143:
  br label %table_cow_after_copy_140
table_cow_after_copy_140:
  %t760 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t730, i32 0, i32 3
  store i8** %t750, i8*** %t760
  call void @star_rc_release(i8* %t706)
  store i8* %t729, i8** %t704
  br label %table_cow_done_135
table_cow_done_135:
  %t761 = load i8*, i8** %t704
  %t762 = bitcast i8* %t761 to { i64, i64, i32*, i8** }*
  %t763 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t762, i32 0, i32 0
  %t764 = load i64, i64* %t763
  %t765 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t762, i32 0, i32 1
  %t766 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t762, i32 0, i32 2
  %t767 = load i32*, i32** %t766
  %t768 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t762, i32 0, i32 3
  %t769 = load i8**, i8*** %t768
  %t771 = icmp eq i64 %t764, 0
  br i1 %t771, label %table_pop_empty_144, label %table_pop_nonempty_145
table_pop_nonempty_145:
  %t772 = sub i64 %t764, 1
  store i64 %t772, i64* %t763
  %t773 = getelementptr inbounds i32, i32* %t767, i64 %t772
  %t774 = load i32, i32* %t773
  %t775 = getelementptr inbounds %Enemy, %Enemy* %t770, i32 0, i32 0
  store i32 %t774, i32* %t775
  %t776 = getelementptr inbounds i8*, i8** %t769, i64 %t772
  %t777 = load i8*, i8** %t776
  %t778 = getelementptr inbounds %Enemy, %Enemy* %t770, i32 0, i32 1
  store i8* %t777, i8** %t778
  br label %table_pop_end_146
table_pop_empty_144:
  store %Enemy zeroinitializer, %Enemy* %t770
  br label %table_pop_end_146
table_pop_end_146:
  %t779 = load %Enemy, %Enemy* %t770
  store %Enemy %t779, %Enemy* %t705
  %t780 = getelementptr inbounds %Enemy, %Enemy* %t705, i32 0, i32 0
  %t781 = load i32, i32* %t780
  %t782 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t782, i32 %t781)
  store i8* null, i8** %t783
  %t784 = load i8*, i8** %t783
  %t785 = icmp eq i8* %t784, null
  br i1 %t785, label %table_cow_alloc_147, label %table_cow_check_148
table_cow_alloc_147:
  %t786 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t787 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t788 = ptrtoint { i64, i64, i32*, i8** }* %t787 to i64
  %t789 = call i8* @star_rc_alloc(i64 %t788, i8* %t786)
  %t790 = bitcast i8* %t789 to { i64, i64, i32*, i8** }*
  %t791 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t790, i32 0, i32 0
  store i64 0, i64* %t791
  %t792 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t790, i32 0, i32 1
  store i64 0, i64* %t792
  %t793 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t790, i32 0, i32 2
  store i32* null, i32** %t793
  %t794 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t790, i32 0, i32 3
  store i8** null, i8*** %t794
  store i8* %t789, i8** %t783
  br label %table_cow_done_149
table_cow_check_148:
  %t795 = getelementptr inbounds i8, i8* %t784, i64 -16
  %t796 = bitcast i8* %t795 to i64*
  %t797 = load atomic i64, i64* %t796 seq_cst, align 8
  %t798 = icmp eq i64 %t797, 1
  br i1 %t798, label %table_cow_done_149, label %table_cow_clone_150
table_cow_clone_150:
  %t799 = bitcast i8* %t784 to { i64, i64, i32*, i8** }*
  %t800 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t799, i32 0, i32 0
  %t801 = load i64, i64* %t800
  %t802 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t799, i32 0, i32 1
  %t803 = load i64, i64* %t802
  %t804 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t805 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t806 = ptrtoint { i64, i64, i32*, i8** }* %t805 to i64
  %t807 = call i8* @star_rc_alloc(i64 %t806, i8* %t804)
  %t808 = bitcast i8* %t807 to { i64, i64, i32*, i8** }*
  %t809 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t808, i32 0, i32 0
  store i64 %t801, i64* %t809
  %t810 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t808, i32 0, i32 1
  store i64 %t803, i64* %t810
  %t811 = getelementptr i32, i32* null, i32 1
  %t812 = ptrtoint i32* %t811 to i64
  %t813 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t799, i32 0, i32 2
  %t814 = load i32*, i32** %t813
  %t815 = mul i64 %t803, %t812
  %t816 = call i8* @malloc(i64 %t815)
  %t817 = bitcast i8* %t816 to i32*
  %t818 = icmp sgt i64 %t801, 0
  br i1 %t818, label %table_cow_copy_151, label %table_cow_after_copy_152
table_cow_copy_151:
  %t819 = mul i64 %t801, %t812
  %t820 = bitcast i32* %t814 to i8*
  call i8* @memcpy(i8* %t816, i8* %t820, i64 %t819)
  br label %table_cow_after_copy_152
table_cow_after_copy_152:
  %t821 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t808, i32 0, i32 2
  store i32* %t817, i32** %t821
  %t822 = getelementptr i8*, i8** null, i32 1
  %t823 = ptrtoint i8** %t822 to i64
  %t824 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t799, i32 0, i32 3
  %t825 = load i8**, i8*** %t824
  %t826 = mul i64 %t803, %t823
  %t827 = call i8* @malloc(i64 %t826)
  %t828 = bitcast i8* %t827 to i8**
  %t829 = icmp sgt i64 %t801, 0
  br i1 %t829, label %table_cow_copy_153, label %table_cow_after_copy_154
table_cow_copy_153:
  %t830 = mul i64 %t801, %t823
  %t831 = bitcast i8** %t825 to i8*
  call i8* @memcpy(i8* %t827, i8* %t831, i64 %t830)
  store i64 0, i64* %t832
  br label %table_cow_retain_cond_155
table_cow_retain_cond_155:
  %t833 = load i64, i64* %t832
  %t834 = icmp slt i64 %t833, %t801
  br i1 %t834, label %table_cow_retain_body_156, label %table_cow_retain_end_157
table_cow_retain_body_156:
  %t835 = getelementptr inbounds i8*, i8** %t828, i64 %t833
  %t836 = load i8*, i8** %t835
  call void @star_rc_retain(i8* %t836)
  %t837 = add i64 %t833, 1
  store i64 %t837, i64* %t832
  br label %table_cow_retain_cond_155
table_cow_retain_end_157:
  br label %table_cow_after_copy_154
table_cow_after_copy_154:
  %t838 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t808, i32 0, i32 3
  store i8** %t828, i8*** %t838
  call void @star_rc_release(i8* %t784)
  store i8* %t807, i8** %t783
  br label %table_cow_done_149
table_cow_done_149:
  %t839 = load i8*, i8** %t783
  %t840 = bitcast i8* %t839 to { i64, i64, i32*, i8** }*
  %t841 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t840, i32 0, i32 0
  %t842 = load i64, i64* %t841
  %t843 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t840, i32 0, i32 1
  %t844 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t840, i32 0, i32 2
  %t845 = load i32*, i32** %t844
  %t846 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t840, i32 0, i32 3
  %t847 = load i8**, i8*** %t846
  %t849 = getelementptr inbounds %Enemy, %Enemy* %t848, i32 0, i32 0
  store i32 1, i32* %t849
  %t850 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t851 = getelementptr inbounds %Enemy, %Enemy* %t848, i32 0, i32 1
  store i8* %t850, i8** %t851
  %t852 = load %Enemy, %Enemy* %t848
  %t853 = load i64, i64* %t843
  %t854 = load i64, i64* %t841
  %t855 = load i32*, i32** %t844
  %t856 = load i8**, i8*** %t846
  %t857 = icmp sge i64 %t854, %t853
  br i1 %t857, label %table_push_grow_158, label %table_push_store_159
table_push_grow_158:
  %t858 = mul i64 %t853, 2
  %t859 = icmp sgt i64 %t858, 0
  %t860 = select i1 %t859, i64 %t858, i64 1
  %t861 = getelementptr i32, i32* null, i32 1
  %t862 = ptrtoint i32* %t861 to i64
  %t863 = mul i64 %t860, %t862
  %t864 = call i8* @malloc(i64 %t863)
  %t865 = bitcast i8* %t864 to i32*
  %t866 = icmp sgt i64 %t853, 0
  br i1 %t866, label %table_push_copy_160, label %table_push_after_copy_161
table_push_copy_160:
  %t867 = mul i64 %t854, %t862
  %t868 = bitcast i32* %t855 to i8*
  call i8* @memcpy(i8* %t864, i8* %t868, i64 %t867)
  call void @free(i8* %t868)
  br label %table_push_after_copy_161
table_push_after_copy_161:
  store i32* %t865, i32** %t844
  %t869 = getelementptr i8*, i8** null, i32 1
  %t870 = ptrtoint i8** %t869 to i64
  %t871 = mul i64 %t860, %t870
  %t872 = call i8* @malloc(i64 %t871)
  %t873 = bitcast i8* %t872 to i8**
  %t874 = icmp sgt i64 %t853, 0
  br i1 %t874, label %table_push_copy_162, label %table_push_after_copy_163
table_push_copy_162:
  %t875 = mul i64 %t854, %t870
  %t876 = bitcast i8** %t856 to i8*
  call i8* @memcpy(i8* %t872, i8* %t876, i64 %t875)
  call void @free(i8* %t876)
  br label %table_push_after_copy_163
table_push_after_copy_163:
  store i8** %t873, i8*** %t846
  store i64 %t860, i64* %t843
  br label %table_push_store_159
table_push_store_159:
  %t877 = load i32*, i32** %t844
  %t878 = extractvalue %Enemy %t852, 0
  %t879 = getelementptr inbounds i32, i32* %t877, i64 %t854
  store i32 %t878, i32* %t879
  %t880 = load i8**, i8*** %t846
  %t881 = extractvalue %Enemy %t852, 1
  %t882 = getelementptr inbounds i8*, i8** %t880, i64 %t854
  store i8* %t881, i8** %t882
  %t883 = add i64 %t854, 1
  store i64 %t883, i64* %t841
  %t885 = load i8*, i8** %t783
  %t886 = load i8*, i8** %t783
  call void @star_rc_retain(i8* %t886)
  store i8* %t885, i8** %t884
  %t887 = load i8*, i8** %t884
  %t888 = icmp eq i8* %t887, null
  br i1 %t888, label %table_cow_alloc_164, label %table_cow_check_165
table_cow_alloc_164:
  %t889 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t890 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t891 = ptrtoint { i64, i64, i32*, i8** }* %t890 to i64
  %t892 = call i8* @star_rc_alloc(i64 %t891, i8* %t889)
  %t893 = bitcast i8* %t892 to { i64, i64, i32*, i8** }*
  %t894 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t893, i32 0, i32 0
  store i64 0, i64* %t894
  %t895 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t893, i32 0, i32 1
  store i64 0, i64* %t895
  %t896 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t893, i32 0, i32 2
  store i32* null, i32** %t896
  %t897 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t893, i32 0, i32 3
  store i8** null, i8*** %t897
  store i8* %t892, i8** %t884
  br label %table_cow_done_166
table_cow_check_165:
  %t898 = getelementptr inbounds i8, i8* %t887, i64 -16
  %t899 = bitcast i8* %t898 to i64*
  %t900 = load atomic i64, i64* %t899 seq_cst, align 8
  %t901 = icmp eq i64 %t900, 1
  br i1 %t901, label %table_cow_done_166, label %table_cow_clone_167
table_cow_clone_167:
  %t902 = bitcast i8* %t887 to { i64, i64, i32*, i8** }*
  %t903 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t902, i32 0, i32 0
  %t904 = load i64, i64* %t903
  %t905 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t902, i32 0, i32 1
  %t906 = load i64, i64* %t905
  %t907 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t908 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t909 = ptrtoint { i64, i64, i32*, i8** }* %t908 to i64
  %t910 = call i8* @star_rc_alloc(i64 %t909, i8* %t907)
  %t911 = bitcast i8* %t910 to { i64, i64, i32*, i8** }*
  %t912 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t911, i32 0, i32 0
  store i64 %t904, i64* %t912
  %t913 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t911, i32 0, i32 1
  store i64 %t906, i64* %t913
  %t914 = getelementptr i32, i32* null, i32 1
  %t915 = ptrtoint i32* %t914 to i64
  %t916 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t902, i32 0, i32 2
  %t917 = load i32*, i32** %t916
  %t918 = mul i64 %t906, %t915
  %t919 = call i8* @malloc(i64 %t918)
  %t920 = bitcast i8* %t919 to i32*
  %t921 = icmp sgt i64 %t904, 0
  br i1 %t921, label %table_cow_copy_168, label %table_cow_after_copy_169
table_cow_copy_168:
  %t922 = mul i64 %t904, %t915
  %t923 = bitcast i32* %t917 to i8*
  call i8* @memcpy(i8* %t919, i8* %t923, i64 %t922)
  br label %table_cow_after_copy_169
table_cow_after_copy_169:
  %t924 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t911, i32 0, i32 2
  store i32* %t920, i32** %t924
  %t925 = getelementptr i8*, i8** null, i32 1
  %t926 = ptrtoint i8** %t925 to i64
  %t927 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t902, i32 0, i32 3
  %t928 = load i8**, i8*** %t927
  %t929 = mul i64 %t906, %t926
  %t930 = call i8* @malloc(i64 %t929)
  %t931 = bitcast i8* %t930 to i8**
  %t932 = icmp sgt i64 %t904, 0
  br i1 %t932, label %table_cow_copy_170, label %table_cow_after_copy_171
table_cow_copy_170:
  %t933 = mul i64 %t904, %t926
  %t934 = bitcast i8** %t928 to i8*
  call i8* @memcpy(i8* %t930, i8* %t934, i64 %t933)
  store i64 0, i64* %t935
  br label %table_cow_retain_cond_172
table_cow_retain_cond_172:
  %t936 = load i64, i64* %t935
  %t937 = icmp slt i64 %t936, %t904
  br i1 %t937, label %table_cow_retain_body_173, label %table_cow_retain_end_174
table_cow_retain_body_173:
  %t938 = getelementptr inbounds i8*, i8** %t931, i64 %t936
  %t939 = load i8*, i8** %t938
  call void @star_rc_retain(i8* %t939)
  %t940 = add i64 %t936, 1
  store i64 %t940, i64* %t935
  br label %table_cow_retain_cond_172
table_cow_retain_end_174:
  br label %table_cow_after_copy_171
table_cow_after_copy_171:
  %t941 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t911, i32 0, i32 3
  store i8** %t931, i8*** %t941
  call void @star_rc_release(i8* %t887)
  store i8* %t910, i8** %t884
  br label %table_cow_done_166
table_cow_done_166:
  %t942 = load i8*, i8** %t884
  %t943 = bitcast i8* %t942 to { i64, i64, i32*, i8** }*
  %t944 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t943, i32 0, i32 0
  %t945 = load i64, i64* %t944
  %t946 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t943, i32 0, i32 1
  %t947 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t943, i32 0, i32 2
  %t948 = load i32*, i32** %t947
  %t949 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t943, i32 0, i32 3
  %t950 = load i8**, i8*** %t949
  %t952 = getelementptr inbounds %Enemy, %Enemy* %t951, i32 0, i32 0
  store i32 2, i32* %t952
  %t953 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t954 = getelementptr inbounds %Enemy, %Enemy* %t951, i32 0, i32 1
  store i8* %t953, i8** %t954
  %t955 = load %Enemy, %Enemy* %t951
  %t956 = load i64, i64* %t946
  %t957 = load i64, i64* %t944
  %t958 = load i32*, i32** %t947
  %t959 = load i8**, i8*** %t949
  %t960 = icmp sge i64 %t957, %t956
  br i1 %t960, label %table_push_grow_175, label %table_push_store_176
table_push_grow_175:
  %t961 = mul i64 %t956, 2
  %t962 = icmp sgt i64 %t961, 0
  %t963 = select i1 %t962, i64 %t961, i64 1
  %t964 = getelementptr i32, i32* null, i32 1
  %t965 = ptrtoint i32* %t964 to i64
  %t966 = mul i64 %t963, %t965
  %t967 = call i8* @malloc(i64 %t966)
  %t968 = bitcast i8* %t967 to i32*
  %t969 = icmp sgt i64 %t956, 0
  br i1 %t969, label %table_push_copy_177, label %table_push_after_copy_178
table_push_copy_177:
  %t970 = mul i64 %t957, %t965
  %t971 = bitcast i32* %t958 to i8*
  call i8* @memcpy(i8* %t967, i8* %t971, i64 %t970)
  call void @free(i8* %t971)
  br label %table_push_after_copy_178
table_push_after_copy_178:
  store i32* %t968, i32** %t947
  %t972 = getelementptr i8*, i8** null, i32 1
  %t973 = ptrtoint i8** %t972 to i64
  %t974 = mul i64 %t963, %t973
  %t975 = call i8* @malloc(i64 %t974)
  %t976 = bitcast i8* %t975 to i8**
  %t977 = icmp sgt i64 %t956, 0
  br i1 %t977, label %table_push_copy_179, label %table_push_after_copy_180
table_push_copy_179:
  %t978 = mul i64 %t957, %t973
  %t979 = bitcast i8** %t959 to i8*
  call i8* @memcpy(i8* %t975, i8* %t979, i64 %t978)
  call void @free(i8* %t979)
  br label %table_push_after_copy_180
table_push_after_copy_180:
  store i8** %t976, i8*** %t949
  store i64 %t963, i64* %t946
  br label %table_push_store_176
table_push_store_176:
  %t980 = load i32*, i32** %t947
  %t981 = extractvalue %Enemy %t955, 0
  %t982 = getelementptr inbounds i32, i32* %t980, i64 %t957
  store i32 %t981, i32* %t982
  %t983 = load i8**, i8*** %t949
  %t984 = extractvalue %Enemy %t955, 1
  %t985 = getelementptr inbounds i8*, i8** %t983, i64 %t957
  store i8* %t984, i8** %t985
  %t986 = add i64 %t957, 1
  store i64 %t986, i64* %t944
  %t987 = load i8*, i8** %t783
  %t988 = icmp eq i8* %t987, null
  br i1 %t988, label %table_read_null_181, label %table_read_real_182
table_read_null_181:
  br label %table_read_end_183
table_read_real_182:
  %t989 = bitcast i8* %t987 to { i64, i64, i32*, i8** }*
  %t990 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t989, i32 0, i32 0
  %t991 = load i64, i64* %t990
  %t992 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t989, i32 0, i32 2
  %t993 = load i32*, i32** %t992
  %t994 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t989, i32 0, i32 3
  %t995 = load i8**, i8*** %t994
  br label %table_read_end_183
table_read_end_183:
  %t996 = phi i64 [ 0, %table_read_null_181 ], [ %t991, %table_read_real_182 ]
  %t997 = phi i32* [ null, %table_read_null_181 ], [ %t993, %table_read_real_182 ]
  %t998 = phi i8** [ null, %table_read_null_181 ], [ %t995, %table_read_real_182 ]
  %t999 = trunc i64 %t996 to i32
  %t1000 = load i8*, i8** %t884
  %t1001 = icmp eq i8* %t1000, null
  br i1 %t1001, label %table_read_null_184, label %table_read_real_185
table_read_null_184:
  br label %table_read_end_186
table_read_real_185:
  %t1002 = bitcast i8* %t1000 to { i64, i64, i32*, i8** }*
  %t1003 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1002, i32 0, i32 0
  %t1004 = load i64, i64* %t1003
  %t1005 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1002, i32 0, i32 2
  %t1006 = load i32*, i32** %t1005
  %t1007 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1002, i32 0, i32 3
  %t1008 = load i8**, i8*** %t1007
  br label %table_read_end_186
table_read_end_186:
  %t1009 = phi i64 [ 0, %table_read_null_184 ], [ %t1004, %table_read_real_185 ]
  %t1010 = phi i32* [ null, %table_read_null_184 ], [ %t1006, %table_read_real_185 ]
  %t1011 = phi i8** [ null, %table_read_null_184 ], [ %t1008, %table_read_real_185 ]
  %t1012 = trunc i64 %t1009 to i32
  %t1013 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.15, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1013, i32 %t999, i32 %t1012)
  %t1014 = sext i32 0 to i64
  %t1015 = load i8*, i8** %t783
  %t1016 = icmp eq i8* %t1015, null
  br i1 %t1016, label %table_read_null_187, label %table_read_real_188
table_read_null_187:
  br label %table_read_end_189
table_read_real_188:
  %t1017 = bitcast i8* %t1015 to { i64, i64, i32*, i8** }*
  %t1018 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1017, i32 0, i32 0
  %t1019 = load i64, i64* %t1018
  %t1020 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1017, i32 0, i32 2
  %t1021 = load i32*, i32** %t1020
  %t1022 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1017, i32 0, i32 3
  %t1023 = load i8**, i8*** %t1022
  br label %table_read_end_189
table_read_end_189:
  %t1024 = phi i64 [ 0, %table_read_null_187 ], [ %t1019, %table_read_real_188 ]
  %t1025 = phi i32* [ null, %table_read_null_187 ], [ %t1021, %table_read_real_188 ]
  %t1026 = phi i8** [ null, %table_read_null_187 ], [ %t1023, %table_read_real_188 ]
  %t1028 = icmp ult i64 %t1014, %t1024
  br i1 %t1028, label %table_idx_ok_190, label %table_idx_oob_191
table_idx_ok_190:
  %t1029 = getelementptr inbounds i32, i32* %t1025, i64 %t1014
  %t1030 = load i32, i32* %t1029
  %t1031 = getelementptr inbounds %Enemy, %Enemy* %t1027, i32 0, i32 0
  store i32 %t1030, i32* %t1031
  %t1032 = getelementptr inbounds i8*, i8** %t1026, i64 %t1014
  %t1033 = load i8*, i8** %t1032
  call void @star_rc_retain(i8* %t1033)
  %t1034 = load i8*, i8** %t1032
  %t1035 = getelementptr inbounds %Enemy, %Enemy* %t1027, i32 0, i32 1
  store i8* %t1034, i8** %t1035
  br label %table_idx_end_192
table_idx_oob_191:
  store %Enemy zeroinitializer, %Enemy* %t1027
  br label %table_idx_end_192
table_idx_end_192:
  %t1036 = load %Enemy, %Enemy* %t1027
  store %Enemy %t1036, %Enemy* %t1037
  %t1038 = getelementptr inbounds %Enemy, %Enemy* %t1037, i32 0, i32 0
  %t1039 = load i32, i32* %t1038
  %t1040 = sext i32 0 to i64
  %t1041 = load i8*, i8** %t884
  %t1042 = icmp eq i8* %t1041, null
  br i1 %t1042, label %table_read_null_193, label %table_read_real_194
table_read_null_193:
  br label %table_read_end_195
table_read_real_194:
  %t1043 = bitcast i8* %t1041 to { i64, i64, i32*, i8** }*
  %t1044 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1043, i32 0, i32 0
  %t1045 = load i64, i64* %t1044
  %t1046 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1043, i32 0, i32 2
  %t1047 = load i32*, i32** %t1046
  %t1048 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1043, i32 0, i32 3
  %t1049 = load i8**, i8*** %t1048
  br label %table_read_end_195
table_read_end_195:
  %t1050 = phi i64 [ 0, %table_read_null_193 ], [ %t1045, %table_read_real_194 ]
  %t1051 = phi i32* [ null, %table_read_null_193 ], [ %t1047, %table_read_real_194 ]
  %t1052 = phi i8** [ null, %table_read_null_193 ], [ %t1049, %table_read_real_194 ]
  %t1054 = icmp ult i64 %t1040, %t1050
  br i1 %t1054, label %table_idx_ok_196, label %table_idx_oob_197
table_idx_ok_196:
  %t1055 = getelementptr inbounds i32, i32* %t1051, i64 %t1040
  %t1056 = load i32, i32* %t1055
  %t1057 = getelementptr inbounds %Enemy, %Enemy* %t1053, i32 0, i32 0
  store i32 %t1056, i32* %t1057
  %t1058 = getelementptr inbounds i8*, i8** %t1052, i64 %t1040
  %t1059 = load i8*, i8** %t1058
  call void @star_rc_retain(i8* %t1059)
  %t1060 = load i8*, i8** %t1058
  %t1061 = getelementptr inbounds %Enemy, %Enemy* %t1053, i32 0, i32 1
  store i8* %t1060, i8** %t1061
  br label %table_idx_end_198
table_idx_oob_197:
  store %Enemy zeroinitializer, %Enemy* %t1053
  br label %table_idx_end_198
table_idx_end_198:
  %t1062 = load %Enemy, %Enemy* %t1053
  store %Enemy %t1062, %Enemy* %t1063
  %t1064 = getelementptr inbounds %Enemy, %Enemy* %t1063, i32 0, i32 0
  %t1065 = load i32, i32* %t1064
  %t1066 = getelementptr inbounds [38 x i8], [38 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1066, i32 %t1039, i32 %t1065)
  %t1067 = load i8*, i8** %t884
  call void @star_rc_release(i8* %t1067)
  %t1068 = load i8*, i8** %t783
  call void @star_rc_release(i8* %t1068)
  %t1069 = getelementptr inbounds %Enemy, %Enemy* %t705, i32 0, i32 1
  %t1070 = load i8*, i8** %t1069
  call void @star_rc_release(i8* %t1070)
  %t1071 = load i8*, i8** %t704
  call void @star_rc_release(i8* %t1071)
  %t1072 = getelementptr inbounds %Enemy, %Enemy* %t582, i32 0, i32 1
  %t1073 = load i8*, i8** %t1072
  call void @star_rc_release(i8* %t1073)
  %t1074 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t1074)
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
