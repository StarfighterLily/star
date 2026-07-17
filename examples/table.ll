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

%Enemy = type { i32, i8* }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca i8*
  %t79 = alloca i64
  %t95 = alloca %Enemy
  %t179 = alloca i64
  %t195 = alloca %Enemy
  %t279 = alloca i64
  %t295 = alloca %Enemy
  %t358 = alloca %Enemy
  %t368 = alloca %Enemy
  %t385 = alloca %Enemy
  %t395 = alloca %Enemy
  %t412 = alloca %Enemy
  %t422 = alloca %Enemy
  %t439 = alloca %Enemy
  %t449 = alloca %Enemy
  %t453 = alloca %Enemy
  %t507 = alloca i64
  %t529 = alloca %Enemy
  %t545 = alloca %Enemy
  %t555 = alloca %Enemy
  %t572 = alloca %Enemy
  %t582 = alloca %Enemy
  %t586 = alloca %Enemy
  %t635 = alloca i64
  %t651 = alloca %Enemy
  %t694 = alloca %Enemy
  %t704 = alloca %Enemy
  %t708 = alloca i8*
  %t709 = alloca %Enemy
  %t758 = alloca i64
  %t774 = alloca %Enemy
  %t787 = alloca i8*
  %t836 = alloca i64
  %t852 = alloca %Enemy
  %t888 = alloca i8*
  %t939 = alloca i64
  %t955 = alloca %Enemy
  %t1031 = alloca %Enemy
  %t1041 = alloca %Enemy
  %t1057 = alloca %Enemy
  %t1067 = alloca %Enemy
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  store i8* null, i8** %t1
  %t2 = load i8*, i8** %t1
  %t3 = icmp eq i8* %t2, null
  br i1 %t3, label %table_read_null_0, label %table_read_real_1
table_read_null_0:
  br label %table_read_end_2
table_read_real_1:
  %t4 = bitcast i8* %t2 to { i64, i64, i32*, i8** }*
  %t5 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t4, i32 0, i32 0
  %t6 = load i64, i64* %t5
  %t7 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t4, i32 0, i32 2
  %t8 = load i32*, i32** %t7
  %t9 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t4, i32 0, i32 3
  %t10 = load i8**, i8*** %t9
  br label %table_read_end_2
table_read_end_2:
  %t11 = phi i64 [ 0, %table_read_null_0 ], [ %t6, %table_read_real_1 ]
  %t12 = phi i32* [ null, %table_read_null_0 ], [ %t8, %table_read_real_1 ]
  %t13 = phi i8** [ null, %table_read_null_0 ], [ %t10, %table_read_real_1 ]
  %t14 = trunc i64 %t11 to i32
  %t15 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t15, i32 %t14)
  %t16 = load i8*, i8** %t1
  %t17 = icmp eq i8* %t16, null
  br i1 %t17, label %table_cow_alloc_3, label %table_cow_check_4
table_cow_alloc_3:
  %t33 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t34 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t35 = ptrtoint { i64, i64, i32*, i8** }* %t34 to i64
  %t36 = call i8* @star_rc_alloc(i64 %t35, i8* %t33)
  %t37 = bitcast i8* %t36 to { i64, i64, i32*, i8** }*
  %t38 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t37, i32 0, i32 0
  store i64 0, i64* %t38
  %t39 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t37, i32 0, i32 1
  store i64 0, i64* %t39
  %t40 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t37, i32 0, i32 2
  store i32* null, i32** %t40
  %t41 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t37, i32 0, i32 3
  store i8** null, i8*** %t41
  store i8* %t36, i8** %t1
  br label %table_cow_done_5
table_cow_check_4:
  %t42 = getelementptr inbounds i8, i8* %t16, i64 -16
  %t43 = bitcast i8* %t42 to i64*
  %t44 = load atomic i64, i64* %t43 seq_cst, align 8
  %t45 = icmp eq i64 %t44, 1
  br i1 %t45, label %table_cow_done_5, label %table_cow_clone_9
table_cow_clone_9:
  %t46 = bitcast i8* %t16 to { i64, i64, i32*, i8** }*
  %t47 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t46, i32 0, i32 0
  %t48 = load i64, i64* %t47
  %t49 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t46, i32 0, i32 1
  %t50 = load i64, i64* %t49
  %t51 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t52 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t53 = ptrtoint { i64, i64, i32*, i8** }* %t52 to i64
  %t54 = call i8* @star_rc_alloc(i64 %t53, i8* %t51)
  %t55 = bitcast i8* %t54 to { i64, i64, i32*, i8** }*
  %t56 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t55, i32 0, i32 0
  store i64 %t48, i64* %t56
  %t57 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t55, i32 0, i32 1
  store i64 %t50, i64* %t57
  %t58 = getelementptr i32, i32* null, i32 1
  %t59 = ptrtoint i32* %t58 to i64
  %t60 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t46, i32 0, i32 2
  %t61 = load i32*, i32** %t60
  %t62 = mul i64 %t50, %t59
  %t63 = call i8* @malloc(i64 %t62)
  %t64 = bitcast i8* %t63 to i32*
  %t65 = icmp sgt i64 %t48, 0
  br i1 %t65, label %table_cow_copy_10, label %table_cow_after_copy_11
table_cow_copy_10:
  %t66 = mul i64 %t48, %t59
  %t67 = bitcast i32* %t61 to i8*
  call i8* @memcpy(i8* %t63, i8* %t67, i64 %t66)
  br label %table_cow_after_copy_11
table_cow_after_copy_11:
  %t68 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t55, i32 0, i32 2
  store i32* %t64, i32** %t68
  %t69 = getelementptr i8*, i8** null, i32 1
  %t70 = ptrtoint i8** %t69 to i64
  %t71 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t46, i32 0, i32 3
  %t72 = load i8**, i8*** %t71
  %t73 = mul i64 %t50, %t70
  %t74 = call i8* @malloc(i64 %t73)
  %t75 = bitcast i8* %t74 to i8**
  %t76 = icmp sgt i64 %t48, 0
  br i1 %t76, label %table_cow_copy_12, label %table_cow_after_copy_13
table_cow_copy_12:
  %t77 = mul i64 %t48, %t70
  %t78 = bitcast i8** %t72 to i8*
  call i8* @memcpy(i8* %t74, i8* %t78, i64 %t77)
  store i64 0, i64* %t79
  br label %table_cow_retain_cond_14
table_cow_retain_cond_14:
  %t80 = load i64, i64* %t79
  %t81 = icmp slt i64 %t80, %t48
  br i1 %t81, label %table_cow_retain_body_15, label %table_cow_retain_end_16
table_cow_retain_body_15:
  %t82 = getelementptr inbounds i8*, i8** %t75, i64 %t80
  %t83 = load i8*, i8** %t82
  call void @star_rc_retain(i8* %t83)
  %t84 = add i64 %t80, 1
  store i64 %t84, i64* %t79
  br label %table_cow_retain_cond_14
table_cow_retain_end_16:
  br label %table_cow_after_copy_13
table_cow_after_copy_13:
  %t85 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t55, i32 0, i32 3
  store i8** %t75, i8*** %t85
  call void @star_rc_release(i8* %t16)
  store i8* %t54, i8** %t1
  br label %table_cow_done_5
table_cow_done_5:
  %t86 = load i8*, i8** %t1
  %t87 = bitcast i8* %t86 to { i64, i64, i32*, i8** }*
  %t88 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t87, i32 0, i32 0
  %t89 = load i64, i64* %t88
  %t90 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t87, i32 0, i32 1
  %t91 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t87, i32 0, i32 2
  %t92 = load i32*, i32** %t91
  %t93 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t87, i32 0, i32 3
  %t94 = load i8**, i8*** %t93
  %t96 = getelementptr inbounds %Enemy, %Enemy* %t95, i32 0, i32 0
  store i32 10, i32* %t96
  %t97 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t98 = getelementptr inbounds %Enemy, %Enemy* %t95, i32 0, i32 1
  store i8* %t97, i8** %t98
  %t99 = load %Enemy, %Enemy* %t95
  %t100 = load i64, i64* %t90
  %t101 = load i64, i64* %t88
  %t102 = load i32*, i32** %t91
  %t103 = load i8**, i8*** %t93
  %t104 = icmp sge i64 %t101, %t100
  br i1 %t104, label %table_push_grow_17, label %table_push_store_18
table_push_grow_17:
  %t105 = mul i64 %t100, 2
  %t106 = icmp sgt i64 %t105, 0
  %t107 = select i1 %t106, i64 %t105, i64 1
  %t108 = getelementptr i32, i32* null, i32 1
  %t109 = ptrtoint i32* %t108 to i64
  %t110 = mul i64 %t107, %t109
  %t111 = call i8* @malloc(i64 %t110)
  %t112 = bitcast i8* %t111 to i32*
  %t113 = icmp sgt i64 %t100, 0
  br i1 %t113, label %table_push_copy_19, label %table_push_after_copy_20
table_push_copy_19:
  %t114 = mul i64 %t101, %t109
  %t115 = bitcast i32* %t102 to i8*
  call i8* @memcpy(i8* %t111, i8* %t115, i64 %t114)
  call void @free(i8* %t115)
  br label %table_push_after_copy_20
table_push_after_copy_20:
  store i32* %t112, i32** %t91
  %t116 = getelementptr i8*, i8** null, i32 1
  %t117 = ptrtoint i8** %t116 to i64
  %t118 = mul i64 %t107, %t117
  %t119 = call i8* @malloc(i64 %t118)
  %t120 = bitcast i8* %t119 to i8**
  %t121 = icmp sgt i64 %t100, 0
  br i1 %t121, label %table_push_copy_21, label %table_push_after_copy_22
table_push_copy_21:
  %t122 = mul i64 %t101, %t117
  %t123 = bitcast i8** %t103 to i8*
  call i8* @memcpy(i8* %t119, i8* %t123, i64 %t122)
  call void @free(i8* %t123)
  br label %table_push_after_copy_22
table_push_after_copy_22:
  store i8** %t120, i8*** %t93
  store i64 %t107, i64* %t90
  br label %table_push_store_18
table_push_store_18:
  %t124 = load i32*, i32** %t91
  %t125 = extractvalue %Enemy %t99, 0
  %t126 = getelementptr inbounds i32, i32* %t124, i64 %t101
  store i32 %t125, i32* %t126
  %t127 = load i8**, i8*** %t93
  %t128 = extractvalue %Enemy %t99, 1
  %t129 = getelementptr inbounds i8*, i8** %t127, i64 %t101
  store i8* %t128, i8** %t129
  %t130 = add i64 %t101, 1
  store i64 %t130, i64* %t88
  %t131 = load i8*, i8** %t1
  %t132 = icmp eq i8* %t131, null
  br i1 %t132, label %table_cow_alloc_23, label %table_cow_check_24
table_cow_alloc_23:
  %t133 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t134 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t135 = ptrtoint { i64, i64, i32*, i8** }* %t134 to i64
  %t136 = call i8* @star_rc_alloc(i64 %t135, i8* %t133)
  %t137 = bitcast i8* %t136 to { i64, i64, i32*, i8** }*
  %t138 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t137, i32 0, i32 0
  store i64 0, i64* %t138
  %t139 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t137, i32 0, i32 1
  store i64 0, i64* %t139
  %t140 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t137, i32 0, i32 2
  store i32* null, i32** %t140
  %t141 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t137, i32 0, i32 3
  store i8** null, i8*** %t141
  store i8* %t136, i8** %t1
  br label %table_cow_done_25
table_cow_check_24:
  %t142 = getelementptr inbounds i8, i8* %t131, i64 -16
  %t143 = bitcast i8* %t142 to i64*
  %t144 = load atomic i64, i64* %t143 seq_cst, align 8
  %t145 = icmp eq i64 %t144, 1
  br i1 %t145, label %table_cow_done_25, label %table_cow_clone_26
table_cow_clone_26:
  %t146 = bitcast i8* %t131 to { i64, i64, i32*, i8** }*
  %t147 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t146, i32 0, i32 0
  %t148 = load i64, i64* %t147
  %t149 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t146, i32 0, i32 1
  %t150 = load i64, i64* %t149
  %t151 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t152 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t153 = ptrtoint { i64, i64, i32*, i8** }* %t152 to i64
  %t154 = call i8* @star_rc_alloc(i64 %t153, i8* %t151)
  %t155 = bitcast i8* %t154 to { i64, i64, i32*, i8** }*
  %t156 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t155, i32 0, i32 0
  store i64 %t148, i64* %t156
  %t157 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t155, i32 0, i32 1
  store i64 %t150, i64* %t157
  %t158 = getelementptr i32, i32* null, i32 1
  %t159 = ptrtoint i32* %t158 to i64
  %t160 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t146, i32 0, i32 2
  %t161 = load i32*, i32** %t160
  %t162 = mul i64 %t150, %t159
  %t163 = call i8* @malloc(i64 %t162)
  %t164 = bitcast i8* %t163 to i32*
  %t165 = icmp sgt i64 %t148, 0
  br i1 %t165, label %table_cow_copy_27, label %table_cow_after_copy_28
table_cow_copy_27:
  %t166 = mul i64 %t148, %t159
  %t167 = bitcast i32* %t161 to i8*
  call i8* @memcpy(i8* %t163, i8* %t167, i64 %t166)
  br label %table_cow_after_copy_28
table_cow_after_copy_28:
  %t168 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t155, i32 0, i32 2
  store i32* %t164, i32** %t168
  %t169 = getelementptr i8*, i8** null, i32 1
  %t170 = ptrtoint i8** %t169 to i64
  %t171 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t146, i32 0, i32 3
  %t172 = load i8**, i8*** %t171
  %t173 = mul i64 %t150, %t170
  %t174 = call i8* @malloc(i64 %t173)
  %t175 = bitcast i8* %t174 to i8**
  %t176 = icmp sgt i64 %t148, 0
  br i1 %t176, label %table_cow_copy_29, label %table_cow_after_copy_30
table_cow_copy_29:
  %t177 = mul i64 %t148, %t170
  %t178 = bitcast i8** %t172 to i8*
  call i8* @memcpy(i8* %t174, i8* %t178, i64 %t177)
  store i64 0, i64* %t179
  br label %table_cow_retain_cond_31
table_cow_retain_cond_31:
  %t180 = load i64, i64* %t179
  %t181 = icmp slt i64 %t180, %t148
  br i1 %t181, label %table_cow_retain_body_32, label %table_cow_retain_end_33
table_cow_retain_body_32:
  %t182 = getelementptr inbounds i8*, i8** %t175, i64 %t180
  %t183 = load i8*, i8** %t182
  call void @star_rc_retain(i8* %t183)
  %t184 = add i64 %t180, 1
  store i64 %t184, i64* %t179
  br label %table_cow_retain_cond_31
table_cow_retain_end_33:
  br label %table_cow_after_copy_30
table_cow_after_copy_30:
  %t185 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t155, i32 0, i32 3
  store i8** %t175, i8*** %t185
  call void @star_rc_release(i8* %t131)
  store i8* %t154, i8** %t1
  br label %table_cow_done_25
table_cow_done_25:
  %t186 = load i8*, i8** %t1
  %t187 = bitcast i8* %t186 to { i64, i64, i32*, i8** }*
  %t188 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t187, i32 0, i32 0
  %t189 = load i64, i64* %t188
  %t190 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t187, i32 0, i32 1
  %t191 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t187, i32 0, i32 2
  %t192 = load i32*, i32** %t191
  %t193 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t187, i32 0, i32 3
  %t194 = load i8**, i8*** %t193
  %t196 = getelementptr inbounds %Enemy, %Enemy* %t195, i32 0, i32 0
  store i32 20, i32* %t196
  %t197 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t198 = getelementptr inbounds %Enemy, %Enemy* %t195, i32 0, i32 1
  store i8* %t197, i8** %t198
  %t199 = load %Enemy, %Enemy* %t195
  %t200 = load i64, i64* %t190
  %t201 = load i64, i64* %t188
  %t202 = load i32*, i32** %t191
  %t203 = load i8**, i8*** %t193
  %t204 = icmp sge i64 %t201, %t200
  br i1 %t204, label %table_push_grow_34, label %table_push_store_35
table_push_grow_34:
  %t205 = mul i64 %t200, 2
  %t206 = icmp sgt i64 %t205, 0
  %t207 = select i1 %t206, i64 %t205, i64 1
  %t208 = getelementptr i32, i32* null, i32 1
  %t209 = ptrtoint i32* %t208 to i64
  %t210 = mul i64 %t207, %t209
  %t211 = call i8* @malloc(i64 %t210)
  %t212 = bitcast i8* %t211 to i32*
  %t213 = icmp sgt i64 %t200, 0
  br i1 %t213, label %table_push_copy_36, label %table_push_after_copy_37
table_push_copy_36:
  %t214 = mul i64 %t201, %t209
  %t215 = bitcast i32* %t202 to i8*
  call i8* @memcpy(i8* %t211, i8* %t215, i64 %t214)
  call void @free(i8* %t215)
  br label %table_push_after_copy_37
table_push_after_copy_37:
  store i32* %t212, i32** %t191
  %t216 = getelementptr i8*, i8** null, i32 1
  %t217 = ptrtoint i8** %t216 to i64
  %t218 = mul i64 %t207, %t217
  %t219 = call i8* @malloc(i64 %t218)
  %t220 = bitcast i8* %t219 to i8**
  %t221 = icmp sgt i64 %t200, 0
  br i1 %t221, label %table_push_copy_38, label %table_push_after_copy_39
table_push_copy_38:
  %t222 = mul i64 %t201, %t217
  %t223 = bitcast i8** %t203 to i8*
  call i8* @memcpy(i8* %t219, i8* %t223, i64 %t222)
  call void @free(i8* %t223)
  br label %table_push_after_copy_39
table_push_after_copy_39:
  store i8** %t220, i8*** %t193
  store i64 %t207, i64* %t190
  br label %table_push_store_35
table_push_store_35:
  %t224 = load i32*, i32** %t191
  %t225 = extractvalue %Enemy %t199, 0
  %t226 = getelementptr inbounds i32, i32* %t224, i64 %t201
  store i32 %t225, i32* %t226
  %t227 = load i8**, i8*** %t193
  %t228 = extractvalue %Enemy %t199, 1
  %t229 = getelementptr inbounds i8*, i8** %t227, i64 %t201
  store i8* %t228, i8** %t229
  %t230 = add i64 %t201, 1
  store i64 %t230, i64* %t188
  %t231 = load i8*, i8** %t1
  %t232 = icmp eq i8* %t231, null
  br i1 %t232, label %table_cow_alloc_40, label %table_cow_check_41
table_cow_alloc_40:
  %t233 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t234 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t235 = ptrtoint { i64, i64, i32*, i8** }* %t234 to i64
  %t236 = call i8* @star_rc_alloc(i64 %t235, i8* %t233)
  %t237 = bitcast i8* %t236 to { i64, i64, i32*, i8** }*
  %t238 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t237, i32 0, i32 0
  store i64 0, i64* %t238
  %t239 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t237, i32 0, i32 1
  store i64 0, i64* %t239
  %t240 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t237, i32 0, i32 2
  store i32* null, i32** %t240
  %t241 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t237, i32 0, i32 3
  store i8** null, i8*** %t241
  store i8* %t236, i8** %t1
  br label %table_cow_done_42
table_cow_check_41:
  %t242 = getelementptr inbounds i8, i8* %t231, i64 -16
  %t243 = bitcast i8* %t242 to i64*
  %t244 = load atomic i64, i64* %t243 seq_cst, align 8
  %t245 = icmp eq i64 %t244, 1
  br i1 %t245, label %table_cow_done_42, label %table_cow_clone_43
table_cow_clone_43:
  %t246 = bitcast i8* %t231 to { i64, i64, i32*, i8** }*
  %t247 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t246, i32 0, i32 0
  %t248 = load i64, i64* %t247
  %t249 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t246, i32 0, i32 1
  %t250 = load i64, i64* %t249
  %t251 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t252 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t253 = ptrtoint { i64, i64, i32*, i8** }* %t252 to i64
  %t254 = call i8* @star_rc_alloc(i64 %t253, i8* %t251)
  %t255 = bitcast i8* %t254 to { i64, i64, i32*, i8** }*
  %t256 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t255, i32 0, i32 0
  store i64 %t248, i64* %t256
  %t257 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t255, i32 0, i32 1
  store i64 %t250, i64* %t257
  %t258 = getelementptr i32, i32* null, i32 1
  %t259 = ptrtoint i32* %t258 to i64
  %t260 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t246, i32 0, i32 2
  %t261 = load i32*, i32** %t260
  %t262 = mul i64 %t250, %t259
  %t263 = call i8* @malloc(i64 %t262)
  %t264 = bitcast i8* %t263 to i32*
  %t265 = icmp sgt i64 %t248, 0
  br i1 %t265, label %table_cow_copy_44, label %table_cow_after_copy_45
table_cow_copy_44:
  %t266 = mul i64 %t248, %t259
  %t267 = bitcast i32* %t261 to i8*
  call i8* @memcpy(i8* %t263, i8* %t267, i64 %t266)
  br label %table_cow_after_copy_45
table_cow_after_copy_45:
  %t268 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t255, i32 0, i32 2
  store i32* %t264, i32** %t268
  %t269 = getelementptr i8*, i8** null, i32 1
  %t270 = ptrtoint i8** %t269 to i64
  %t271 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t246, i32 0, i32 3
  %t272 = load i8**, i8*** %t271
  %t273 = mul i64 %t250, %t270
  %t274 = call i8* @malloc(i64 %t273)
  %t275 = bitcast i8* %t274 to i8**
  %t276 = icmp sgt i64 %t248, 0
  br i1 %t276, label %table_cow_copy_46, label %table_cow_after_copy_47
table_cow_copy_46:
  %t277 = mul i64 %t248, %t270
  %t278 = bitcast i8** %t272 to i8*
  call i8* @memcpy(i8* %t274, i8* %t278, i64 %t277)
  store i64 0, i64* %t279
  br label %table_cow_retain_cond_48
table_cow_retain_cond_48:
  %t280 = load i64, i64* %t279
  %t281 = icmp slt i64 %t280, %t248
  br i1 %t281, label %table_cow_retain_body_49, label %table_cow_retain_end_50
table_cow_retain_body_49:
  %t282 = getelementptr inbounds i8*, i8** %t275, i64 %t280
  %t283 = load i8*, i8** %t282
  call void @star_rc_retain(i8* %t283)
  %t284 = add i64 %t280, 1
  store i64 %t284, i64* %t279
  br label %table_cow_retain_cond_48
table_cow_retain_end_50:
  br label %table_cow_after_copy_47
table_cow_after_copy_47:
  %t285 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t255, i32 0, i32 3
  store i8** %t275, i8*** %t285
  call void @star_rc_release(i8* %t231)
  store i8* %t254, i8** %t1
  br label %table_cow_done_42
table_cow_done_42:
  %t286 = load i8*, i8** %t1
  %t287 = bitcast i8* %t286 to { i64, i64, i32*, i8** }*
  %t288 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t287, i32 0, i32 0
  %t289 = load i64, i64* %t288
  %t290 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t287, i32 0, i32 1
  %t291 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t287, i32 0, i32 2
  %t292 = load i32*, i32** %t291
  %t293 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t287, i32 0, i32 3
  %t294 = load i8**, i8*** %t293
  %t296 = getelementptr inbounds %Enemy, %Enemy* %t295, i32 0, i32 0
  store i32 30, i32* %t296
  %t297 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t298 = getelementptr inbounds %Enemy, %Enemy* %t295, i32 0, i32 1
  store i8* %t297, i8** %t298
  %t299 = load %Enemy, %Enemy* %t295
  %t300 = load i64, i64* %t290
  %t301 = load i64, i64* %t288
  %t302 = load i32*, i32** %t291
  %t303 = load i8**, i8*** %t293
  %t304 = icmp sge i64 %t301, %t300
  br i1 %t304, label %table_push_grow_51, label %table_push_store_52
table_push_grow_51:
  %t305 = mul i64 %t300, 2
  %t306 = icmp sgt i64 %t305, 0
  %t307 = select i1 %t306, i64 %t305, i64 1
  %t308 = getelementptr i32, i32* null, i32 1
  %t309 = ptrtoint i32* %t308 to i64
  %t310 = mul i64 %t307, %t309
  %t311 = call i8* @malloc(i64 %t310)
  %t312 = bitcast i8* %t311 to i32*
  %t313 = icmp sgt i64 %t300, 0
  br i1 %t313, label %table_push_copy_53, label %table_push_after_copy_54
table_push_copy_53:
  %t314 = mul i64 %t301, %t309
  %t315 = bitcast i32* %t302 to i8*
  call i8* @memcpy(i8* %t311, i8* %t315, i64 %t314)
  call void @free(i8* %t315)
  br label %table_push_after_copy_54
table_push_after_copy_54:
  store i32* %t312, i32** %t291
  %t316 = getelementptr i8*, i8** null, i32 1
  %t317 = ptrtoint i8** %t316 to i64
  %t318 = mul i64 %t307, %t317
  %t319 = call i8* @malloc(i64 %t318)
  %t320 = bitcast i8* %t319 to i8**
  %t321 = icmp sgt i64 %t300, 0
  br i1 %t321, label %table_push_copy_55, label %table_push_after_copy_56
table_push_copy_55:
  %t322 = mul i64 %t301, %t317
  %t323 = bitcast i8** %t303 to i8*
  call i8* @memcpy(i8* %t319, i8* %t323, i64 %t322)
  call void @free(i8* %t323)
  br label %table_push_after_copy_56
table_push_after_copy_56:
  store i8** %t320, i8*** %t293
  store i64 %t307, i64* %t290
  br label %table_push_store_52
table_push_store_52:
  %t324 = load i32*, i32** %t291
  %t325 = extractvalue %Enemy %t299, 0
  %t326 = getelementptr inbounds i32, i32* %t324, i64 %t301
  store i32 %t325, i32* %t326
  %t327 = load i8**, i8*** %t293
  %t328 = extractvalue %Enemy %t299, 1
  %t329 = getelementptr inbounds i8*, i8** %t327, i64 %t301
  store i8* %t328, i8** %t329
  %t330 = add i64 %t301, 1
  store i64 %t330, i64* %t288
  %t331 = load i8*, i8** %t1
  %t332 = icmp eq i8* %t331, null
  br i1 %t332, label %table_read_null_57, label %table_read_real_58
table_read_null_57:
  br label %table_read_end_59
table_read_real_58:
  %t333 = bitcast i8* %t331 to { i64, i64, i32*, i8** }*
  %t334 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t333, i32 0, i32 0
  %t335 = load i64, i64* %t334
  %t336 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t333, i32 0, i32 2
  %t337 = load i32*, i32** %t336
  %t338 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t333, i32 0, i32 3
  %t339 = load i8**, i8*** %t338
  br label %table_read_end_59
table_read_end_59:
  %t340 = phi i64 [ 0, %table_read_null_57 ], [ %t335, %table_read_real_58 ]
  %t341 = phi i32* [ null, %table_read_null_57 ], [ %t337, %table_read_real_58 ]
  %t342 = phi i8** [ null, %table_read_null_57 ], [ %t339, %table_read_real_58 ]
  %t343 = trunc i64 %t340 to i32
  %t344 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t344, i32 %t343)
  %t345 = sext i32 0 to i64
  %t346 = load i8*, i8** %t1
  %t347 = icmp eq i8* %t346, null
  br i1 %t347, label %table_read_null_60, label %table_read_real_61
table_read_null_60:
  br label %table_read_end_62
table_read_real_61:
  %t348 = bitcast i8* %t346 to { i64, i64, i32*, i8** }*
  %t349 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t348, i32 0, i32 0
  %t350 = load i64, i64* %t349
  %t351 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t348, i32 0, i32 2
  %t352 = load i32*, i32** %t351
  %t353 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t348, i32 0, i32 3
  %t354 = load i8**, i8*** %t353
  br label %table_read_end_62
table_read_end_62:
  %t355 = phi i64 [ 0, %table_read_null_60 ], [ %t350, %table_read_real_61 ]
  %t356 = phi i32* [ null, %table_read_null_60 ], [ %t352, %table_read_real_61 ]
  %t357 = phi i8** [ null, %table_read_null_60 ], [ %t354, %table_read_real_61 ]
  %t359 = icmp ult i64 %t345, %t355
  br i1 %t359, label %table_idx_ok_63, label %table_idx_oob_64
table_idx_ok_63:
  %t360 = getelementptr inbounds i32, i32* %t356, i64 %t345
  %t361 = load i32, i32* %t360
  %t362 = getelementptr inbounds %Enemy, %Enemy* %t358, i32 0, i32 0
  store i32 %t361, i32* %t362
  %t363 = getelementptr inbounds i8*, i8** %t357, i64 %t345
  %t364 = load i8*, i8** %t363
  call void @star_rc_retain(i8* %t364)
  %t365 = load i8*, i8** %t363
  %t366 = getelementptr inbounds %Enemy, %Enemy* %t358, i32 0, i32 1
  store i8* %t365, i8** %t366
  br label %table_idx_end_65
table_idx_oob_64:
  store %Enemy zeroinitializer, %Enemy* %t358
  br label %table_idx_end_65
table_idx_end_65:
  %t367 = load %Enemy, %Enemy* %t358
  store %Enemy %t367, %Enemy* %t368
  %t369 = getelementptr inbounds %Enemy, %Enemy* %t368, i32 0, i32 1
  %t370 = load i8*, i8** %t369
  %t371 = load i8*, i8** %t369
  call void @star_rc_retain(i8* %t371)
  call void @star_rc_release(i8* %t370)
  %t372 = sext i32 0 to i64
  %t373 = load i8*, i8** %t1
  %t374 = icmp eq i8* %t373, null
  br i1 %t374, label %table_read_null_66, label %table_read_real_67
table_read_null_66:
  br label %table_read_end_68
table_read_real_67:
  %t375 = bitcast i8* %t373 to { i64, i64, i32*, i8** }*
  %t376 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t375, i32 0, i32 0
  %t377 = load i64, i64* %t376
  %t378 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t375, i32 0, i32 2
  %t379 = load i32*, i32** %t378
  %t380 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t375, i32 0, i32 3
  %t381 = load i8**, i8*** %t380
  br label %table_read_end_68
table_read_end_68:
  %t382 = phi i64 [ 0, %table_read_null_66 ], [ %t377, %table_read_real_67 ]
  %t383 = phi i32* [ null, %table_read_null_66 ], [ %t379, %table_read_real_67 ]
  %t384 = phi i8** [ null, %table_read_null_66 ], [ %t381, %table_read_real_67 ]
  %t386 = icmp ult i64 %t372, %t382
  br i1 %t386, label %table_idx_ok_69, label %table_idx_oob_70
table_idx_ok_69:
  %t387 = getelementptr inbounds i32, i32* %t383, i64 %t372
  %t388 = load i32, i32* %t387
  %t389 = getelementptr inbounds %Enemy, %Enemy* %t385, i32 0, i32 0
  store i32 %t388, i32* %t389
  %t390 = getelementptr inbounds i8*, i8** %t384, i64 %t372
  %t391 = load i8*, i8** %t390
  call void @star_rc_retain(i8* %t391)
  %t392 = load i8*, i8** %t390
  %t393 = getelementptr inbounds %Enemy, %Enemy* %t385, i32 0, i32 1
  store i8* %t392, i8** %t393
  br label %table_idx_end_71
table_idx_oob_70:
  store %Enemy zeroinitializer, %Enemy* %t385
  br label %table_idx_end_71
table_idx_end_71:
  %t394 = load %Enemy, %Enemy* %t385
  store %Enemy %t394, %Enemy* %t395
  %t396 = getelementptr inbounds %Enemy, %Enemy* %t395, i32 0, i32 0
  %t397 = load i32, i32* %t396
  %t398 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t398, i8* %t370, i32 %t397)
  %t399 = sext i32 2 to i64
  %t400 = load i8*, i8** %t1
  %t401 = icmp eq i8* %t400, null
  br i1 %t401, label %table_read_null_72, label %table_read_real_73
table_read_null_72:
  br label %table_read_end_74
table_read_real_73:
  %t402 = bitcast i8* %t400 to { i64, i64, i32*, i8** }*
  %t403 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t402, i32 0, i32 0
  %t404 = load i64, i64* %t403
  %t405 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t402, i32 0, i32 2
  %t406 = load i32*, i32** %t405
  %t407 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t402, i32 0, i32 3
  %t408 = load i8**, i8*** %t407
  br label %table_read_end_74
table_read_end_74:
  %t409 = phi i64 [ 0, %table_read_null_72 ], [ %t404, %table_read_real_73 ]
  %t410 = phi i32* [ null, %table_read_null_72 ], [ %t406, %table_read_real_73 ]
  %t411 = phi i8** [ null, %table_read_null_72 ], [ %t408, %table_read_real_73 ]
  %t413 = icmp ult i64 %t399, %t409
  br i1 %t413, label %table_idx_ok_75, label %table_idx_oob_76
table_idx_ok_75:
  %t414 = getelementptr inbounds i32, i32* %t410, i64 %t399
  %t415 = load i32, i32* %t414
  %t416 = getelementptr inbounds %Enemy, %Enemy* %t412, i32 0, i32 0
  store i32 %t415, i32* %t416
  %t417 = getelementptr inbounds i8*, i8** %t411, i64 %t399
  %t418 = load i8*, i8** %t417
  call void @star_rc_retain(i8* %t418)
  %t419 = load i8*, i8** %t417
  %t420 = getelementptr inbounds %Enemy, %Enemy* %t412, i32 0, i32 1
  store i8* %t419, i8** %t420
  br label %table_idx_end_77
table_idx_oob_76:
  store %Enemy zeroinitializer, %Enemy* %t412
  br label %table_idx_end_77
table_idx_end_77:
  %t421 = load %Enemy, %Enemy* %t412
  store %Enemy %t421, %Enemy* %t422
  %t423 = getelementptr inbounds %Enemy, %Enemy* %t422, i32 0, i32 1
  %t424 = load i8*, i8** %t423
  %t425 = load i8*, i8** %t423
  call void @star_rc_retain(i8* %t425)
  call void @star_rc_release(i8* %t424)
  %t426 = sext i32 2 to i64
  %t427 = load i8*, i8** %t1
  %t428 = icmp eq i8* %t427, null
  br i1 %t428, label %table_read_null_78, label %table_read_real_79
table_read_null_78:
  br label %table_read_end_80
table_read_real_79:
  %t429 = bitcast i8* %t427 to { i64, i64, i32*, i8** }*
  %t430 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t429, i32 0, i32 0
  %t431 = load i64, i64* %t430
  %t432 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t429, i32 0, i32 2
  %t433 = load i32*, i32** %t432
  %t434 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t429, i32 0, i32 3
  %t435 = load i8**, i8*** %t434
  br label %table_read_end_80
table_read_end_80:
  %t436 = phi i64 [ 0, %table_read_null_78 ], [ %t431, %table_read_real_79 ]
  %t437 = phi i32* [ null, %table_read_null_78 ], [ %t433, %table_read_real_79 ]
  %t438 = phi i8** [ null, %table_read_null_78 ], [ %t435, %table_read_real_79 ]
  %t440 = icmp ult i64 %t426, %t436
  br i1 %t440, label %table_idx_ok_81, label %table_idx_oob_82
table_idx_ok_81:
  %t441 = getelementptr inbounds i32, i32* %t437, i64 %t426
  %t442 = load i32, i32* %t441
  %t443 = getelementptr inbounds %Enemy, %Enemy* %t439, i32 0, i32 0
  store i32 %t442, i32* %t443
  %t444 = getelementptr inbounds i8*, i8** %t438, i64 %t426
  %t445 = load i8*, i8** %t444
  call void @star_rc_retain(i8* %t445)
  %t446 = load i8*, i8** %t444
  %t447 = getelementptr inbounds %Enemy, %Enemy* %t439, i32 0, i32 1
  store i8* %t446, i8** %t447
  br label %table_idx_end_83
table_idx_oob_82:
  store %Enemy zeroinitializer, %Enemy* %t439
  br label %table_idx_end_83
table_idx_end_83:
  %t448 = load %Enemy, %Enemy* %t439
  store %Enemy %t448, %Enemy* %t449
  %t450 = getelementptr inbounds %Enemy, %Enemy* %t449, i32 0, i32 0
  %t451 = load i32, i32* %t450
  %t452 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t452, i8* %t424, i32 %t451)
  %t454 = getelementptr inbounds %Enemy, %Enemy* %t453, i32 0, i32 0
  store i32 99, i32* %t454
  %t455 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t456 = getelementptr inbounds %Enemy, %Enemy* %t453, i32 0, i32 1
  store i8* %t455, i8** %t456
  %t457 = load %Enemy, %Enemy* %t453
  %t458 = sext i32 1 to i64
  %t459 = load i8*, i8** %t1
  %t460 = icmp eq i8* %t459, null
  br i1 %t460, label %table_cow_alloc_84, label %table_cow_check_85
table_cow_alloc_84:
  %t461 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t462 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t463 = ptrtoint { i64, i64, i32*, i8** }* %t462 to i64
  %t464 = call i8* @star_rc_alloc(i64 %t463, i8* %t461)
  %t465 = bitcast i8* %t464 to { i64, i64, i32*, i8** }*
  %t466 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t465, i32 0, i32 0
  store i64 0, i64* %t466
  %t467 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t465, i32 0, i32 1
  store i64 0, i64* %t467
  %t468 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t465, i32 0, i32 2
  store i32* null, i32** %t468
  %t469 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t465, i32 0, i32 3
  store i8** null, i8*** %t469
  store i8* %t464, i8** %t1
  br label %table_cow_done_86
table_cow_check_85:
  %t470 = getelementptr inbounds i8, i8* %t459, i64 -16
  %t471 = bitcast i8* %t470 to i64*
  %t472 = load atomic i64, i64* %t471 seq_cst, align 8
  %t473 = icmp eq i64 %t472, 1
  br i1 %t473, label %table_cow_done_86, label %table_cow_clone_87
table_cow_clone_87:
  %t474 = bitcast i8* %t459 to { i64, i64, i32*, i8** }*
  %t475 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t474, i32 0, i32 0
  %t476 = load i64, i64* %t475
  %t477 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t474, i32 0, i32 1
  %t478 = load i64, i64* %t477
  %t479 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t480 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t481 = ptrtoint { i64, i64, i32*, i8** }* %t480 to i64
  %t482 = call i8* @star_rc_alloc(i64 %t481, i8* %t479)
  %t483 = bitcast i8* %t482 to { i64, i64, i32*, i8** }*
  %t484 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t483, i32 0, i32 0
  store i64 %t476, i64* %t484
  %t485 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t483, i32 0, i32 1
  store i64 %t478, i64* %t485
  %t486 = getelementptr i32, i32* null, i32 1
  %t487 = ptrtoint i32* %t486 to i64
  %t488 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t474, i32 0, i32 2
  %t489 = load i32*, i32** %t488
  %t490 = mul i64 %t478, %t487
  %t491 = call i8* @malloc(i64 %t490)
  %t492 = bitcast i8* %t491 to i32*
  %t493 = icmp sgt i64 %t476, 0
  br i1 %t493, label %table_cow_copy_88, label %table_cow_after_copy_89
table_cow_copy_88:
  %t494 = mul i64 %t476, %t487
  %t495 = bitcast i32* %t489 to i8*
  call i8* @memcpy(i8* %t491, i8* %t495, i64 %t494)
  br label %table_cow_after_copy_89
table_cow_after_copy_89:
  %t496 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t483, i32 0, i32 2
  store i32* %t492, i32** %t496
  %t497 = getelementptr i8*, i8** null, i32 1
  %t498 = ptrtoint i8** %t497 to i64
  %t499 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t474, i32 0, i32 3
  %t500 = load i8**, i8*** %t499
  %t501 = mul i64 %t478, %t498
  %t502 = call i8* @malloc(i64 %t501)
  %t503 = bitcast i8* %t502 to i8**
  %t504 = icmp sgt i64 %t476, 0
  br i1 %t504, label %table_cow_copy_90, label %table_cow_after_copy_91
table_cow_copy_90:
  %t505 = mul i64 %t476, %t498
  %t506 = bitcast i8** %t500 to i8*
  call i8* @memcpy(i8* %t502, i8* %t506, i64 %t505)
  store i64 0, i64* %t507
  br label %table_cow_retain_cond_92
table_cow_retain_cond_92:
  %t508 = load i64, i64* %t507
  %t509 = icmp slt i64 %t508, %t476
  br i1 %t509, label %table_cow_retain_body_93, label %table_cow_retain_end_94
table_cow_retain_body_93:
  %t510 = getelementptr inbounds i8*, i8** %t503, i64 %t508
  %t511 = load i8*, i8** %t510
  call void @star_rc_retain(i8* %t511)
  %t512 = add i64 %t508, 1
  store i64 %t512, i64* %t507
  br label %table_cow_retain_cond_92
table_cow_retain_end_94:
  br label %table_cow_after_copy_91
table_cow_after_copy_91:
  %t513 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t483, i32 0, i32 3
  store i8** %t503, i8*** %t513
  call void @star_rc_release(i8* %t459)
  store i8* %t482, i8** %t1
  br label %table_cow_done_86
table_cow_done_86:
  %t514 = load i8*, i8** %t1
  %t515 = bitcast i8* %t514 to { i64, i64, i32*, i8** }*
  %t516 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t515, i32 0, i32 0
  %t517 = load i64, i64* %t516
  %t518 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t515, i32 0, i32 1
  %t519 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t515, i32 0, i32 2
  %t520 = load i32*, i32** %t519
  %t521 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t515, i32 0, i32 3
  %t522 = load i8**, i8*** %t521
  %t523 = icmp ult i64 %t458, %t517
  br i1 %t523, label %table_set_do_95, label %table_set_oob_96
table_set_do_95:
  %t524 = extractvalue %Enemy %t457, 0
  %t525 = getelementptr inbounds i32, i32* %t520, i64 %t458
  store i32 %t524, i32* %t525
  %t526 = extractvalue %Enemy %t457, 1
  %t527 = getelementptr inbounds i8*, i8** %t522, i64 %t458
  %t528 = load i8*, i8** %t527
  call void @star_rc_release(i8* %t528)
  store i8* %t526, i8** %t527
  br label %table_set_end_97
table_set_oob_96:
  store %Enemy %t457, %Enemy* %t529
  %t530 = getelementptr inbounds %Enemy, %Enemy* %t529, i32 0, i32 1
  %t531 = load i8*, i8** %t530
  call void @star_rc_release(i8* %t531)
  br label %table_set_end_97
table_set_end_97:
  %t532 = sext i32 1 to i64
  %t533 = load i8*, i8** %t1
  %t534 = icmp eq i8* %t533, null
  br i1 %t534, label %table_read_null_98, label %table_read_real_99
table_read_null_98:
  br label %table_read_end_100
table_read_real_99:
  %t535 = bitcast i8* %t533 to { i64, i64, i32*, i8** }*
  %t536 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t535, i32 0, i32 0
  %t537 = load i64, i64* %t536
  %t538 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t535, i32 0, i32 2
  %t539 = load i32*, i32** %t538
  %t540 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t535, i32 0, i32 3
  %t541 = load i8**, i8*** %t540
  br label %table_read_end_100
table_read_end_100:
  %t542 = phi i64 [ 0, %table_read_null_98 ], [ %t537, %table_read_real_99 ]
  %t543 = phi i32* [ null, %table_read_null_98 ], [ %t539, %table_read_real_99 ]
  %t544 = phi i8** [ null, %table_read_null_98 ], [ %t541, %table_read_real_99 ]
  %t546 = icmp ult i64 %t532, %t542
  br i1 %t546, label %table_idx_ok_101, label %table_idx_oob_102
table_idx_ok_101:
  %t547 = getelementptr inbounds i32, i32* %t543, i64 %t532
  %t548 = load i32, i32* %t547
  %t549 = getelementptr inbounds %Enemy, %Enemy* %t545, i32 0, i32 0
  store i32 %t548, i32* %t549
  %t550 = getelementptr inbounds i8*, i8** %t544, i64 %t532
  %t551 = load i8*, i8** %t550
  call void @star_rc_retain(i8* %t551)
  %t552 = load i8*, i8** %t550
  %t553 = getelementptr inbounds %Enemy, %Enemy* %t545, i32 0, i32 1
  store i8* %t552, i8** %t553
  br label %table_idx_end_103
table_idx_oob_102:
  store %Enemy zeroinitializer, %Enemy* %t545
  br label %table_idx_end_103
table_idx_end_103:
  %t554 = load %Enemy, %Enemy* %t545
  store %Enemy %t554, %Enemy* %t555
  %t556 = getelementptr inbounds %Enemy, %Enemy* %t555, i32 0, i32 1
  %t557 = load i8*, i8** %t556
  %t558 = load i8*, i8** %t556
  call void @star_rc_retain(i8* %t558)
  call void @star_rc_release(i8* %t557)
  %t559 = sext i32 1 to i64
  %t560 = load i8*, i8** %t1
  %t561 = icmp eq i8* %t560, null
  br i1 %t561, label %table_read_null_104, label %table_read_real_105
table_read_null_104:
  br label %table_read_end_106
table_read_real_105:
  %t562 = bitcast i8* %t560 to { i64, i64, i32*, i8** }*
  %t563 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t562, i32 0, i32 0
  %t564 = load i64, i64* %t563
  %t565 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t562, i32 0, i32 2
  %t566 = load i32*, i32** %t565
  %t567 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t562, i32 0, i32 3
  %t568 = load i8**, i8*** %t567
  br label %table_read_end_106
table_read_end_106:
  %t569 = phi i64 [ 0, %table_read_null_104 ], [ %t564, %table_read_real_105 ]
  %t570 = phi i32* [ null, %table_read_null_104 ], [ %t566, %table_read_real_105 ]
  %t571 = phi i8** [ null, %table_read_null_104 ], [ %t568, %table_read_real_105 ]
  %t573 = icmp ult i64 %t559, %t569
  br i1 %t573, label %table_idx_ok_107, label %table_idx_oob_108
table_idx_ok_107:
  %t574 = getelementptr inbounds i32, i32* %t570, i64 %t559
  %t575 = load i32, i32* %t574
  %t576 = getelementptr inbounds %Enemy, %Enemy* %t572, i32 0, i32 0
  store i32 %t575, i32* %t576
  %t577 = getelementptr inbounds i8*, i8** %t571, i64 %t559
  %t578 = load i8*, i8** %t577
  call void @star_rc_retain(i8* %t578)
  %t579 = load i8*, i8** %t577
  %t580 = getelementptr inbounds %Enemy, %Enemy* %t572, i32 0, i32 1
  store i8* %t579, i8** %t580
  br label %table_idx_end_109
table_idx_oob_108:
  store %Enemy zeroinitializer, %Enemy* %t572
  br label %table_idx_end_109
table_idx_end_109:
  %t581 = load %Enemy, %Enemy* %t572
  store %Enemy %t581, %Enemy* %t582
  %t583 = getelementptr inbounds %Enemy, %Enemy* %t582, i32 0, i32 0
  %t584 = load i32, i32* %t583
  %t585 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t585, i8* %t557, i32 %t584)
  %t587 = load i8*, i8** %t1
  %t588 = icmp eq i8* %t587, null
  br i1 %t588, label %table_cow_alloc_110, label %table_cow_check_111
table_cow_alloc_110:
  %t589 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t590 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t591 = ptrtoint { i64, i64, i32*, i8** }* %t590 to i64
  %t592 = call i8* @star_rc_alloc(i64 %t591, i8* %t589)
  %t593 = bitcast i8* %t592 to { i64, i64, i32*, i8** }*
  %t594 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t593, i32 0, i32 0
  store i64 0, i64* %t594
  %t595 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t593, i32 0, i32 1
  store i64 0, i64* %t595
  %t596 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t593, i32 0, i32 2
  store i32* null, i32** %t596
  %t597 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t593, i32 0, i32 3
  store i8** null, i8*** %t597
  store i8* %t592, i8** %t1
  br label %table_cow_done_112
table_cow_check_111:
  %t598 = getelementptr inbounds i8, i8* %t587, i64 -16
  %t599 = bitcast i8* %t598 to i64*
  %t600 = load atomic i64, i64* %t599 seq_cst, align 8
  %t601 = icmp eq i64 %t600, 1
  br i1 %t601, label %table_cow_done_112, label %table_cow_clone_113
table_cow_clone_113:
  %t602 = bitcast i8* %t587 to { i64, i64, i32*, i8** }*
  %t603 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t602, i32 0, i32 0
  %t604 = load i64, i64* %t603
  %t605 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t602, i32 0, i32 1
  %t606 = load i64, i64* %t605
  %t607 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t608 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t609 = ptrtoint { i64, i64, i32*, i8** }* %t608 to i64
  %t610 = call i8* @star_rc_alloc(i64 %t609, i8* %t607)
  %t611 = bitcast i8* %t610 to { i64, i64, i32*, i8** }*
  %t612 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t611, i32 0, i32 0
  store i64 %t604, i64* %t612
  %t613 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t611, i32 0, i32 1
  store i64 %t606, i64* %t613
  %t614 = getelementptr i32, i32* null, i32 1
  %t615 = ptrtoint i32* %t614 to i64
  %t616 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t602, i32 0, i32 2
  %t617 = load i32*, i32** %t616
  %t618 = mul i64 %t606, %t615
  %t619 = call i8* @malloc(i64 %t618)
  %t620 = bitcast i8* %t619 to i32*
  %t621 = icmp sgt i64 %t604, 0
  br i1 %t621, label %table_cow_copy_114, label %table_cow_after_copy_115
table_cow_copy_114:
  %t622 = mul i64 %t604, %t615
  %t623 = bitcast i32* %t617 to i8*
  call i8* @memcpy(i8* %t619, i8* %t623, i64 %t622)
  br label %table_cow_after_copy_115
table_cow_after_copy_115:
  %t624 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t611, i32 0, i32 2
  store i32* %t620, i32** %t624
  %t625 = getelementptr i8*, i8** null, i32 1
  %t626 = ptrtoint i8** %t625 to i64
  %t627 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t602, i32 0, i32 3
  %t628 = load i8**, i8*** %t627
  %t629 = mul i64 %t606, %t626
  %t630 = call i8* @malloc(i64 %t629)
  %t631 = bitcast i8* %t630 to i8**
  %t632 = icmp sgt i64 %t604, 0
  br i1 %t632, label %table_cow_copy_116, label %table_cow_after_copy_117
table_cow_copy_116:
  %t633 = mul i64 %t604, %t626
  %t634 = bitcast i8** %t628 to i8*
  call i8* @memcpy(i8* %t630, i8* %t634, i64 %t633)
  store i64 0, i64* %t635
  br label %table_cow_retain_cond_118
table_cow_retain_cond_118:
  %t636 = load i64, i64* %t635
  %t637 = icmp slt i64 %t636, %t604
  br i1 %t637, label %table_cow_retain_body_119, label %table_cow_retain_end_120
table_cow_retain_body_119:
  %t638 = getelementptr inbounds i8*, i8** %t631, i64 %t636
  %t639 = load i8*, i8** %t638
  call void @star_rc_retain(i8* %t639)
  %t640 = add i64 %t636, 1
  store i64 %t640, i64* %t635
  br label %table_cow_retain_cond_118
table_cow_retain_end_120:
  br label %table_cow_after_copy_117
table_cow_after_copy_117:
  %t641 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t611, i32 0, i32 3
  store i8** %t631, i8*** %t641
  call void @star_rc_release(i8* %t587)
  store i8* %t610, i8** %t1
  br label %table_cow_done_112
table_cow_done_112:
  %t642 = load i8*, i8** %t1
  %t643 = bitcast i8* %t642 to { i64, i64, i32*, i8** }*
  %t644 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t643, i32 0, i32 0
  %t645 = load i64, i64* %t644
  %t646 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t643, i32 0, i32 1
  %t647 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t643, i32 0, i32 2
  %t648 = load i32*, i32** %t647
  %t649 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t643, i32 0, i32 3
  %t650 = load i8**, i8*** %t649
  %t652 = icmp eq i64 %t645, 0
  br i1 %t652, label %table_pop_empty_121, label %table_pop_nonempty_122
table_pop_nonempty_122:
  %t653 = sub i64 %t645, 1
  store i64 %t653, i64* %t644
  %t654 = getelementptr inbounds i32, i32* %t648, i64 %t653
  %t655 = load i32, i32* %t654
  %t656 = getelementptr inbounds %Enemy, %Enemy* %t651, i32 0, i32 0
  store i32 %t655, i32* %t656
  %t657 = getelementptr inbounds i8*, i8** %t650, i64 %t653
  %t658 = load i8*, i8** %t657
  %t659 = getelementptr inbounds %Enemy, %Enemy* %t651, i32 0, i32 1
  store i8* %t658, i8** %t659
  br label %table_pop_end_123
table_pop_empty_121:
  store %Enemy zeroinitializer, %Enemy* %t651
  br label %table_pop_end_123
table_pop_end_123:
  %t660 = load %Enemy, %Enemy* %t651
  store %Enemy %t660, %Enemy* %t586
  %t661 = getelementptr inbounds %Enemy, %Enemy* %t586, i32 0, i32 1
  %t662 = load i8*, i8** %t661
  %t663 = load i8*, i8** %t661
  call void @star_rc_retain(i8* %t663)
  call void @star_rc_release(i8* %t662)
  %t664 = getelementptr inbounds %Enemy, %Enemy* %t586, i32 0, i32 0
  %t665 = load i32, i32* %t664
  %t666 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t666, i8* %t662, i32 %t665)
  %t667 = load i8*, i8** %t1
  %t668 = icmp eq i8* %t667, null
  br i1 %t668, label %table_read_null_124, label %table_read_real_125
table_read_null_124:
  br label %table_read_end_126
table_read_real_125:
  %t669 = bitcast i8* %t667 to { i64, i64, i32*, i8** }*
  %t670 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t669, i32 0, i32 0
  %t671 = load i64, i64* %t670
  %t672 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t669, i32 0, i32 2
  %t673 = load i32*, i32** %t672
  %t674 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t669, i32 0, i32 3
  %t675 = load i8**, i8*** %t674
  br label %table_read_end_126
table_read_end_126:
  %t676 = phi i64 [ 0, %table_read_null_124 ], [ %t671, %table_read_real_125 ]
  %t677 = phi i32* [ null, %table_read_null_124 ], [ %t673, %table_read_real_125 ]
  %t678 = phi i8** [ null, %table_read_null_124 ], [ %t675, %table_read_real_125 ]
  %t679 = trunc i64 %t676 to i32
  %t680 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t680, i32 %t679)
  %t681 = sext i32 99 to i64
  %t682 = load i8*, i8** %t1
  %t683 = icmp eq i8* %t682, null
  br i1 %t683, label %table_read_null_127, label %table_read_real_128
table_read_null_127:
  br label %table_read_end_129
table_read_real_128:
  %t684 = bitcast i8* %t682 to { i64, i64, i32*, i8** }*
  %t685 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t684, i32 0, i32 0
  %t686 = load i64, i64* %t685
  %t687 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t684, i32 0, i32 2
  %t688 = load i32*, i32** %t687
  %t689 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t684, i32 0, i32 3
  %t690 = load i8**, i8*** %t689
  br label %table_read_end_129
table_read_end_129:
  %t691 = phi i64 [ 0, %table_read_null_127 ], [ %t686, %table_read_real_128 ]
  %t692 = phi i32* [ null, %table_read_null_127 ], [ %t688, %table_read_real_128 ]
  %t693 = phi i8** [ null, %table_read_null_127 ], [ %t690, %table_read_real_128 ]
  %t695 = icmp ult i64 %t681, %t691
  br i1 %t695, label %table_idx_ok_130, label %table_idx_oob_131
table_idx_ok_130:
  %t696 = getelementptr inbounds i32, i32* %t692, i64 %t681
  %t697 = load i32, i32* %t696
  %t698 = getelementptr inbounds %Enemy, %Enemy* %t694, i32 0, i32 0
  store i32 %t697, i32* %t698
  %t699 = getelementptr inbounds i8*, i8** %t693, i64 %t681
  %t700 = load i8*, i8** %t699
  call void @star_rc_retain(i8* %t700)
  %t701 = load i8*, i8** %t699
  %t702 = getelementptr inbounds %Enemy, %Enemy* %t694, i32 0, i32 1
  store i8* %t701, i8** %t702
  br label %table_idx_end_132
table_idx_oob_131:
  store %Enemy zeroinitializer, %Enemy* %t694
  br label %table_idx_end_132
table_idx_end_132:
  %t703 = load %Enemy, %Enemy* %t694
  store %Enemy %t703, %Enemy* %t704
  %t705 = getelementptr inbounds %Enemy, %Enemy* %t704, i32 0, i32 0
  %t706 = load i32, i32* %t705
  %t707 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t707, i32 %t706)
  store i8* null, i8** %t708
  %t710 = load i8*, i8** %t708
  %t711 = icmp eq i8* %t710, null
  br i1 %t711, label %table_cow_alloc_133, label %table_cow_check_134
table_cow_alloc_133:
  %t712 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t713 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t714 = ptrtoint { i64, i64, i32*, i8** }* %t713 to i64
  %t715 = call i8* @star_rc_alloc(i64 %t714, i8* %t712)
  %t716 = bitcast i8* %t715 to { i64, i64, i32*, i8** }*
  %t717 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t716, i32 0, i32 0
  store i64 0, i64* %t717
  %t718 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t716, i32 0, i32 1
  store i64 0, i64* %t718
  %t719 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t716, i32 0, i32 2
  store i32* null, i32** %t719
  %t720 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t716, i32 0, i32 3
  store i8** null, i8*** %t720
  store i8* %t715, i8** %t708
  br label %table_cow_done_135
table_cow_check_134:
  %t721 = getelementptr inbounds i8, i8* %t710, i64 -16
  %t722 = bitcast i8* %t721 to i64*
  %t723 = load atomic i64, i64* %t722 seq_cst, align 8
  %t724 = icmp eq i64 %t723, 1
  br i1 %t724, label %table_cow_done_135, label %table_cow_clone_136
table_cow_clone_136:
  %t725 = bitcast i8* %t710 to { i64, i64, i32*, i8** }*
  %t726 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t725, i32 0, i32 0
  %t727 = load i64, i64* %t726
  %t728 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t725, i32 0, i32 1
  %t729 = load i64, i64* %t728
  %t730 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t731 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t732 = ptrtoint { i64, i64, i32*, i8** }* %t731 to i64
  %t733 = call i8* @star_rc_alloc(i64 %t732, i8* %t730)
  %t734 = bitcast i8* %t733 to { i64, i64, i32*, i8** }*
  %t735 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t734, i32 0, i32 0
  store i64 %t727, i64* %t735
  %t736 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t734, i32 0, i32 1
  store i64 %t729, i64* %t736
  %t737 = getelementptr i32, i32* null, i32 1
  %t738 = ptrtoint i32* %t737 to i64
  %t739 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t725, i32 0, i32 2
  %t740 = load i32*, i32** %t739
  %t741 = mul i64 %t729, %t738
  %t742 = call i8* @malloc(i64 %t741)
  %t743 = bitcast i8* %t742 to i32*
  %t744 = icmp sgt i64 %t727, 0
  br i1 %t744, label %table_cow_copy_137, label %table_cow_after_copy_138
table_cow_copy_137:
  %t745 = mul i64 %t727, %t738
  %t746 = bitcast i32* %t740 to i8*
  call i8* @memcpy(i8* %t742, i8* %t746, i64 %t745)
  br label %table_cow_after_copy_138
table_cow_after_copy_138:
  %t747 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t734, i32 0, i32 2
  store i32* %t743, i32** %t747
  %t748 = getelementptr i8*, i8** null, i32 1
  %t749 = ptrtoint i8** %t748 to i64
  %t750 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t725, i32 0, i32 3
  %t751 = load i8**, i8*** %t750
  %t752 = mul i64 %t729, %t749
  %t753 = call i8* @malloc(i64 %t752)
  %t754 = bitcast i8* %t753 to i8**
  %t755 = icmp sgt i64 %t727, 0
  br i1 %t755, label %table_cow_copy_139, label %table_cow_after_copy_140
table_cow_copy_139:
  %t756 = mul i64 %t727, %t749
  %t757 = bitcast i8** %t751 to i8*
  call i8* @memcpy(i8* %t753, i8* %t757, i64 %t756)
  store i64 0, i64* %t758
  br label %table_cow_retain_cond_141
table_cow_retain_cond_141:
  %t759 = load i64, i64* %t758
  %t760 = icmp slt i64 %t759, %t727
  br i1 %t760, label %table_cow_retain_body_142, label %table_cow_retain_end_143
table_cow_retain_body_142:
  %t761 = getelementptr inbounds i8*, i8** %t754, i64 %t759
  %t762 = load i8*, i8** %t761
  call void @star_rc_retain(i8* %t762)
  %t763 = add i64 %t759, 1
  store i64 %t763, i64* %t758
  br label %table_cow_retain_cond_141
table_cow_retain_end_143:
  br label %table_cow_after_copy_140
table_cow_after_copy_140:
  %t764 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t734, i32 0, i32 3
  store i8** %t754, i8*** %t764
  call void @star_rc_release(i8* %t710)
  store i8* %t733, i8** %t708
  br label %table_cow_done_135
table_cow_done_135:
  %t765 = load i8*, i8** %t708
  %t766 = bitcast i8* %t765 to { i64, i64, i32*, i8** }*
  %t767 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t766, i32 0, i32 0
  %t768 = load i64, i64* %t767
  %t769 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t766, i32 0, i32 1
  %t770 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t766, i32 0, i32 2
  %t771 = load i32*, i32** %t770
  %t772 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t766, i32 0, i32 3
  %t773 = load i8**, i8*** %t772
  %t775 = icmp eq i64 %t768, 0
  br i1 %t775, label %table_pop_empty_144, label %table_pop_nonempty_145
table_pop_nonempty_145:
  %t776 = sub i64 %t768, 1
  store i64 %t776, i64* %t767
  %t777 = getelementptr inbounds i32, i32* %t771, i64 %t776
  %t778 = load i32, i32* %t777
  %t779 = getelementptr inbounds %Enemy, %Enemy* %t774, i32 0, i32 0
  store i32 %t778, i32* %t779
  %t780 = getelementptr inbounds i8*, i8** %t773, i64 %t776
  %t781 = load i8*, i8** %t780
  %t782 = getelementptr inbounds %Enemy, %Enemy* %t774, i32 0, i32 1
  store i8* %t781, i8** %t782
  br label %table_pop_end_146
table_pop_empty_144:
  store %Enemy zeroinitializer, %Enemy* %t774
  br label %table_pop_end_146
table_pop_end_146:
  %t783 = load %Enemy, %Enemy* %t774
  store %Enemy %t783, %Enemy* %t709
  %t784 = getelementptr inbounds %Enemy, %Enemy* %t709, i32 0, i32 0
  %t785 = load i32, i32* %t784
  %t786 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t786, i32 %t785)
  store i8* null, i8** %t787
  %t788 = load i8*, i8** %t787
  %t789 = icmp eq i8* %t788, null
  br i1 %t789, label %table_cow_alloc_147, label %table_cow_check_148
table_cow_alloc_147:
  %t790 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t791 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t792 = ptrtoint { i64, i64, i32*, i8** }* %t791 to i64
  %t793 = call i8* @star_rc_alloc(i64 %t792, i8* %t790)
  %t794 = bitcast i8* %t793 to { i64, i64, i32*, i8** }*
  %t795 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t794, i32 0, i32 0
  store i64 0, i64* %t795
  %t796 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t794, i32 0, i32 1
  store i64 0, i64* %t796
  %t797 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t794, i32 0, i32 2
  store i32* null, i32** %t797
  %t798 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t794, i32 0, i32 3
  store i8** null, i8*** %t798
  store i8* %t793, i8** %t787
  br label %table_cow_done_149
table_cow_check_148:
  %t799 = getelementptr inbounds i8, i8* %t788, i64 -16
  %t800 = bitcast i8* %t799 to i64*
  %t801 = load atomic i64, i64* %t800 seq_cst, align 8
  %t802 = icmp eq i64 %t801, 1
  br i1 %t802, label %table_cow_done_149, label %table_cow_clone_150
table_cow_clone_150:
  %t803 = bitcast i8* %t788 to { i64, i64, i32*, i8** }*
  %t804 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t803, i32 0, i32 0
  %t805 = load i64, i64* %t804
  %t806 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t803, i32 0, i32 1
  %t807 = load i64, i64* %t806
  %t808 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t809 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t810 = ptrtoint { i64, i64, i32*, i8** }* %t809 to i64
  %t811 = call i8* @star_rc_alloc(i64 %t810, i8* %t808)
  %t812 = bitcast i8* %t811 to { i64, i64, i32*, i8** }*
  %t813 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t812, i32 0, i32 0
  store i64 %t805, i64* %t813
  %t814 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t812, i32 0, i32 1
  store i64 %t807, i64* %t814
  %t815 = getelementptr i32, i32* null, i32 1
  %t816 = ptrtoint i32* %t815 to i64
  %t817 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t803, i32 0, i32 2
  %t818 = load i32*, i32** %t817
  %t819 = mul i64 %t807, %t816
  %t820 = call i8* @malloc(i64 %t819)
  %t821 = bitcast i8* %t820 to i32*
  %t822 = icmp sgt i64 %t805, 0
  br i1 %t822, label %table_cow_copy_151, label %table_cow_after_copy_152
table_cow_copy_151:
  %t823 = mul i64 %t805, %t816
  %t824 = bitcast i32* %t818 to i8*
  call i8* @memcpy(i8* %t820, i8* %t824, i64 %t823)
  br label %table_cow_after_copy_152
table_cow_after_copy_152:
  %t825 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t812, i32 0, i32 2
  store i32* %t821, i32** %t825
  %t826 = getelementptr i8*, i8** null, i32 1
  %t827 = ptrtoint i8** %t826 to i64
  %t828 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t803, i32 0, i32 3
  %t829 = load i8**, i8*** %t828
  %t830 = mul i64 %t807, %t827
  %t831 = call i8* @malloc(i64 %t830)
  %t832 = bitcast i8* %t831 to i8**
  %t833 = icmp sgt i64 %t805, 0
  br i1 %t833, label %table_cow_copy_153, label %table_cow_after_copy_154
table_cow_copy_153:
  %t834 = mul i64 %t805, %t827
  %t835 = bitcast i8** %t829 to i8*
  call i8* @memcpy(i8* %t831, i8* %t835, i64 %t834)
  store i64 0, i64* %t836
  br label %table_cow_retain_cond_155
table_cow_retain_cond_155:
  %t837 = load i64, i64* %t836
  %t838 = icmp slt i64 %t837, %t805
  br i1 %t838, label %table_cow_retain_body_156, label %table_cow_retain_end_157
table_cow_retain_body_156:
  %t839 = getelementptr inbounds i8*, i8** %t832, i64 %t837
  %t840 = load i8*, i8** %t839
  call void @star_rc_retain(i8* %t840)
  %t841 = add i64 %t837, 1
  store i64 %t841, i64* %t836
  br label %table_cow_retain_cond_155
table_cow_retain_end_157:
  br label %table_cow_after_copy_154
table_cow_after_copy_154:
  %t842 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t812, i32 0, i32 3
  store i8** %t832, i8*** %t842
  call void @star_rc_release(i8* %t788)
  store i8* %t811, i8** %t787
  br label %table_cow_done_149
table_cow_done_149:
  %t843 = load i8*, i8** %t787
  %t844 = bitcast i8* %t843 to { i64, i64, i32*, i8** }*
  %t845 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t844, i32 0, i32 0
  %t846 = load i64, i64* %t845
  %t847 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t844, i32 0, i32 1
  %t848 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t844, i32 0, i32 2
  %t849 = load i32*, i32** %t848
  %t850 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t844, i32 0, i32 3
  %t851 = load i8**, i8*** %t850
  %t853 = getelementptr inbounds %Enemy, %Enemy* %t852, i32 0, i32 0
  store i32 1, i32* %t853
  %t854 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t855 = getelementptr inbounds %Enemy, %Enemy* %t852, i32 0, i32 1
  store i8* %t854, i8** %t855
  %t856 = load %Enemy, %Enemy* %t852
  %t857 = load i64, i64* %t847
  %t858 = load i64, i64* %t845
  %t859 = load i32*, i32** %t848
  %t860 = load i8**, i8*** %t850
  %t861 = icmp sge i64 %t858, %t857
  br i1 %t861, label %table_push_grow_158, label %table_push_store_159
table_push_grow_158:
  %t862 = mul i64 %t857, 2
  %t863 = icmp sgt i64 %t862, 0
  %t864 = select i1 %t863, i64 %t862, i64 1
  %t865 = getelementptr i32, i32* null, i32 1
  %t866 = ptrtoint i32* %t865 to i64
  %t867 = mul i64 %t864, %t866
  %t868 = call i8* @malloc(i64 %t867)
  %t869 = bitcast i8* %t868 to i32*
  %t870 = icmp sgt i64 %t857, 0
  br i1 %t870, label %table_push_copy_160, label %table_push_after_copy_161
table_push_copy_160:
  %t871 = mul i64 %t858, %t866
  %t872 = bitcast i32* %t859 to i8*
  call i8* @memcpy(i8* %t868, i8* %t872, i64 %t871)
  call void @free(i8* %t872)
  br label %table_push_after_copy_161
table_push_after_copy_161:
  store i32* %t869, i32** %t848
  %t873 = getelementptr i8*, i8** null, i32 1
  %t874 = ptrtoint i8** %t873 to i64
  %t875 = mul i64 %t864, %t874
  %t876 = call i8* @malloc(i64 %t875)
  %t877 = bitcast i8* %t876 to i8**
  %t878 = icmp sgt i64 %t857, 0
  br i1 %t878, label %table_push_copy_162, label %table_push_after_copy_163
table_push_copy_162:
  %t879 = mul i64 %t858, %t874
  %t880 = bitcast i8** %t860 to i8*
  call i8* @memcpy(i8* %t876, i8* %t880, i64 %t879)
  call void @free(i8* %t880)
  br label %table_push_after_copy_163
table_push_after_copy_163:
  store i8** %t877, i8*** %t850
  store i64 %t864, i64* %t847
  br label %table_push_store_159
table_push_store_159:
  %t881 = load i32*, i32** %t848
  %t882 = extractvalue %Enemy %t856, 0
  %t883 = getelementptr inbounds i32, i32* %t881, i64 %t858
  store i32 %t882, i32* %t883
  %t884 = load i8**, i8*** %t850
  %t885 = extractvalue %Enemy %t856, 1
  %t886 = getelementptr inbounds i8*, i8** %t884, i64 %t858
  store i8* %t885, i8** %t886
  %t887 = add i64 %t858, 1
  store i64 %t887, i64* %t845
  %t889 = load i8*, i8** %t787
  %t890 = load i8*, i8** %t787
  call void @star_rc_retain(i8* %t890)
  store i8* %t889, i8** %t888
  %t891 = load i8*, i8** %t888
  %t892 = icmp eq i8* %t891, null
  br i1 %t892, label %table_cow_alloc_164, label %table_cow_check_165
table_cow_alloc_164:
  %t893 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t894 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t895 = ptrtoint { i64, i64, i32*, i8** }* %t894 to i64
  %t896 = call i8* @star_rc_alloc(i64 %t895, i8* %t893)
  %t897 = bitcast i8* %t896 to { i64, i64, i32*, i8** }*
  %t898 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t897, i32 0, i32 0
  store i64 0, i64* %t898
  %t899 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t897, i32 0, i32 1
  store i64 0, i64* %t899
  %t900 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t897, i32 0, i32 2
  store i32* null, i32** %t900
  %t901 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t897, i32 0, i32 3
  store i8** null, i8*** %t901
  store i8* %t896, i8** %t888
  br label %table_cow_done_166
table_cow_check_165:
  %t902 = getelementptr inbounds i8, i8* %t891, i64 -16
  %t903 = bitcast i8* %t902 to i64*
  %t904 = load atomic i64, i64* %t903 seq_cst, align 8
  %t905 = icmp eq i64 %t904, 1
  br i1 %t905, label %table_cow_done_166, label %table_cow_clone_167
table_cow_clone_167:
  %t906 = bitcast i8* %t891 to { i64, i64, i32*, i8** }*
  %t907 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t906, i32 0, i32 0
  %t908 = load i64, i64* %t907
  %t909 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t906, i32 0, i32 1
  %t910 = load i64, i64* %t909
  %t911 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t912 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t913 = ptrtoint { i64, i64, i32*, i8** }* %t912 to i64
  %t914 = call i8* @star_rc_alloc(i64 %t913, i8* %t911)
  %t915 = bitcast i8* %t914 to { i64, i64, i32*, i8** }*
  %t916 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t915, i32 0, i32 0
  store i64 %t908, i64* %t916
  %t917 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t915, i32 0, i32 1
  store i64 %t910, i64* %t917
  %t918 = getelementptr i32, i32* null, i32 1
  %t919 = ptrtoint i32* %t918 to i64
  %t920 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t906, i32 0, i32 2
  %t921 = load i32*, i32** %t920
  %t922 = mul i64 %t910, %t919
  %t923 = call i8* @malloc(i64 %t922)
  %t924 = bitcast i8* %t923 to i32*
  %t925 = icmp sgt i64 %t908, 0
  br i1 %t925, label %table_cow_copy_168, label %table_cow_after_copy_169
table_cow_copy_168:
  %t926 = mul i64 %t908, %t919
  %t927 = bitcast i32* %t921 to i8*
  call i8* @memcpy(i8* %t923, i8* %t927, i64 %t926)
  br label %table_cow_after_copy_169
table_cow_after_copy_169:
  %t928 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t915, i32 0, i32 2
  store i32* %t924, i32** %t928
  %t929 = getelementptr i8*, i8** null, i32 1
  %t930 = ptrtoint i8** %t929 to i64
  %t931 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t906, i32 0, i32 3
  %t932 = load i8**, i8*** %t931
  %t933 = mul i64 %t910, %t930
  %t934 = call i8* @malloc(i64 %t933)
  %t935 = bitcast i8* %t934 to i8**
  %t936 = icmp sgt i64 %t908, 0
  br i1 %t936, label %table_cow_copy_170, label %table_cow_after_copy_171
table_cow_copy_170:
  %t937 = mul i64 %t908, %t930
  %t938 = bitcast i8** %t932 to i8*
  call i8* @memcpy(i8* %t934, i8* %t938, i64 %t937)
  store i64 0, i64* %t939
  br label %table_cow_retain_cond_172
table_cow_retain_cond_172:
  %t940 = load i64, i64* %t939
  %t941 = icmp slt i64 %t940, %t908
  br i1 %t941, label %table_cow_retain_body_173, label %table_cow_retain_end_174
table_cow_retain_body_173:
  %t942 = getelementptr inbounds i8*, i8** %t935, i64 %t940
  %t943 = load i8*, i8** %t942
  call void @star_rc_retain(i8* %t943)
  %t944 = add i64 %t940, 1
  store i64 %t944, i64* %t939
  br label %table_cow_retain_cond_172
table_cow_retain_end_174:
  br label %table_cow_after_copy_171
table_cow_after_copy_171:
  %t945 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t915, i32 0, i32 3
  store i8** %t935, i8*** %t945
  call void @star_rc_release(i8* %t891)
  store i8* %t914, i8** %t888
  br label %table_cow_done_166
table_cow_done_166:
  %t946 = load i8*, i8** %t888
  %t947 = bitcast i8* %t946 to { i64, i64, i32*, i8** }*
  %t948 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t947, i32 0, i32 0
  %t949 = load i64, i64* %t948
  %t950 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t947, i32 0, i32 1
  %t951 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t947, i32 0, i32 2
  %t952 = load i32*, i32** %t951
  %t953 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t947, i32 0, i32 3
  %t954 = load i8**, i8*** %t953
  %t956 = getelementptr inbounds %Enemy, %Enemy* %t955, i32 0, i32 0
  store i32 2, i32* %t956
  %t957 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t958 = getelementptr inbounds %Enemy, %Enemy* %t955, i32 0, i32 1
  store i8* %t957, i8** %t958
  %t959 = load %Enemy, %Enemy* %t955
  %t960 = load i64, i64* %t950
  %t961 = load i64, i64* %t948
  %t962 = load i32*, i32** %t951
  %t963 = load i8**, i8*** %t953
  %t964 = icmp sge i64 %t961, %t960
  br i1 %t964, label %table_push_grow_175, label %table_push_store_176
table_push_grow_175:
  %t965 = mul i64 %t960, 2
  %t966 = icmp sgt i64 %t965, 0
  %t967 = select i1 %t966, i64 %t965, i64 1
  %t968 = getelementptr i32, i32* null, i32 1
  %t969 = ptrtoint i32* %t968 to i64
  %t970 = mul i64 %t967, %t969
  %t971 = call i8* @malloc(i64 %t970)
  %t972 = bitcast i8* %t971 to i32*
  %t973 = icmp sgt i64 %t960, 0
  br i1 %t973, label %table_push_copy_177, label %table_push_after_copy_178
table_push_copy_177:
  %t974 = mul i64 %t961, %t969
  %t975 = bitcast i32* %t962 to i8*
  call i8* @memcpy(i8* %t971, i8* %t975, i64 %t974)
  call void @free(i8* %t975)
  br label %table_push_after_copy_178
table_push_after_copy_178:
  store i32* %t972, i32** %t951
  %t976 = getelementptr i8*, i8** null, i32 1
  %t977 = ptrtoint i8** %t976 to i64
  %t978 = mul i64 %t967, %t977
  %t979 = call i8* @malloc(i64 %t978)
  %t980 = bitcast i8* %t979 to i8**
  %t981 = icmp sgt i64 %t960, 0
  br i1 %t981, label %table_push_copy_179, label %table_push_after_copy_180
table_push_copy_179:
  %t982 = mul i64 %t961, %t977
  %t983 = bitcast i8** %t963 to i8*
  call i8* @memcpy(i8* %t979, i8* %t983, i64 %t982)
  call void @free(i8* %t983)
  br label %table_push_after_copy_180
table_push_after_copy_180:
  store i8** %t980, i8*** %t953
  store i64 %t967, i64* %t950
  br label %table_push_store_176
table_push_store_176:
  %t984 = load i32*, i32** %t951
  %t985 = extractvalue %Enemy %t959, 0
  %t986 = getelementptr inbounds i32, i32* %t984, i64 %t961
  store i32 %t985, i32* %t986
  %t987 = load i8**, i8*** %t953
  %t988 = extractvalue %Enemy %t959, 1
  %t989 = getelementptr inbounds i8*, i8** %t987, i64 %t961
  store i8* %t988, i8** %t989
  %t990 = add i64 %t961, 1
  store i64 %t990, i64* %t948
  %t991 = load i8*, i8** %t787
  %t992 = icmp eq i8* %t991, null
  br i1 %t992, label %table_read_null_181, label %table_read_real_182
table_read_null_181:
  br label %table_read_end_183
table_read_real_182:
  %t993 = bitcast i8* %t991 to { i64, i64, i32*, i8** }*
  %t994 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t993, i32 0, i32 0
  %t995 = load i64, i64* %t994
  %t996 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t993, i32 0, i32 2
  %t997 = load i32*, i32** %t996
  %t998 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t993, i32 0, i32 3
  %t999 = load i8**, i8*** %t998
  br label %table_read_end_183
table_read_end_183:
  %t1000 = phi i64 [ 0, %table_read_null_181 ], [ %t995, %table_read_real_182 ]
  %t1001 = phi i32* [ null, %table_read_null_181 ], [ %t997, %table_read_real_182 ]
  %t1002 = phi i8** [ null, %table_read_null_181 ], [ %t999, %table_read_real_182 ]
  %t1003 = trunc i64 %t1000 to i32
  %t1004 = load i8*, i8** %t888
  %t1005 = icmp eq i8* %t1004, null
  br i1 %t1005, label %table_read_null_184, label %table_read_real_185
table_read_null_184:
  br label %table_read_end_186
table_read_real_185:
  %t1006 = bitcast i8* %t1004 to { i64, i64, i32*, i8** }*
  %t1007 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1006, i32 0, i32 0
  %t1008 = load i64, i64* %t1007
  %t1009 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1006, i32 0, i32 2
  %t1010 = load i32*, i32** %t1009
  %t1011 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1006, i32 0, i32 3
  %t1012 = load i8**, i8*** %t1011
  br label %table_read_end_186
table_read_end_186:
  %t1013 = phi i64 [ 0, %table_read_null_184 ], [ %t1008, %table_read_real_185 ]
  %t1014 = phi i32* [ null, %table_read_null_184 ], [ %t1010, %table_read_real_185 ]
  %t1015 = phi i8** [ null, %table_read_null_184 ], [ %t1012, %table_read_real_185 ]
  %t1016 = trunc i64 %t1013 to i32
  %t1017 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.15, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1017, i32 %t1003, i32 %t1016)
  %t1018 = sext i32 0 to i64
  %t1019 = load i8*, i8** %t787
  %t1020 = icmp eq i8* %t1019, null
  br i1 %t1020, label %table_read_null_187, label %table_read_real_188
table_read_null_187:
  br label %table_read_end_189
table_read_real_188:
  %t1021 = bitcast i8* %t1019 to { i64, i64, i32*, i8** }*
  %t1022 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1021, i32 0, i32 0
  %t1023 = load i64, i64* %t1022
  %t1024 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1021, i32 0, i32 2
  %t1025 = load i32*, i32** %t1024
  %t1026 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1021, i32 0, i32 3
  %t1027 = load i8**, i8*** %t1026
  br label %table_read_end_189
table_read_end_189:
  %t1028 = phi i64 [ 0, %table_read_null_187 ], [ %t1023, %table_read_real_188 ]
  %t1029 = phi i32* [ null, %table_read_null_187 ], [ %t1025, %table_read_real_188 ]
  %t1030 = phi i8** [ null, %table_read_null_187 ], [ %t1027, %table_read_real_188 ]
  %t1032 = icmp ult i64 %t1018, %t1028
  br i1 %t1032, label %table_idx_ok_190, label %table_idx_oob_191
table_idx_ok_190:
  %t1033 = getelementptr inbounds i32, i32* %t1029, i64 %t1018
  %t1034 = load i32, i32* %t1033
  %t1035 = getelementptr inbounds %Enemy, %Enemy* %t1031, i32 0, i32 0
  store i32 %t1034, i32* %t1035
  %t1036 = getelementptr inbounds i8*, i8** %t1030, i64 %t1018
  %t1037 = load i8*, i8** %t1036
  call void @star_rc_retain(i8* %t1037)
  %t1038 = load i8*, i8** %t1036
  %t1039 = getelementptr inbounds %Enemy, %Enemy* %t1031, i32 0, i32 1
  store i8* %t1038, i8** %t1039
  br label %table_idx_end_192
table_idx_oob_191:
  store %Enemy zeroinitializer, %Enemy* %t1031
  br label %table_idx_end_192
table_idx_end_192:
  %t1040 = load %Enemy, %Enemy* %t1031
  store %Enemy %t1040, %Enemy* %t1041
  %t1042 = getelementptr inbounds %Enemy, %Enemy* %t1041, i32 0, i32 0
  %t1043 = load i32, i32* %t1042
  %t1044 = sext i32 0 to i64
  %t1045 = load i8*, i8** %t888
  %t1046 = icmp eq i8* %t1045, null
  br i1 %t1046, label %table_read_null_193, label %table_read_real_194
table_read_null_193:
  br label %table_read_end_195
table_read_real_194:
  %t1047 = bitcast i8* %t1045 to { i64, i64, i32*, i8** }*
  %t1048 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1047, i32 0, i32 0
  %t1049 = load i64, i64* %t1048
  %t1050 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1047, i32 0, i32 2
  %t1051 = load i32*, i32** %t1050
  %t1052 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1047, i32 0, i32 3
  %t1053 = load i8**, i8*** %t1052
  br label %table_read_end_195
table_read_end_195:
  %t1054 = phi i64 [ 0, %table_read_null_193 ], [ %t1049, %table_read_real_194 ]
  %t1055 = phi i32* [ null, %table_read_null_193 ], [ %t1051, %table_read_real_194 ]
  %t1056 = phi i8** [ null, %table_read_null_193 ], [ %t1053, %table_read_real_194 ]
  %t1058 = icmp ult i64 %t1044, %t1054
  br i1 %t1058, label %table_idx_ok_196, label %table_idx_oob_197
table_idx_ok_196:
  %t1059 = getelementptr inbounds i32, i32* %t1055, i64 %t1044
  %t1060 = load i32, i32* %t1059
  %t1061 = getelementptr inbounds %Enemy, %Enemy* %t1057, i32 0, i32 0
  store i32 %t1060, i32* %t1061
  %t1062 = getelementptr inbounds i8*, i8** %t1056, i64 %t1044
  %t1063 = load i8*, i8** %t1062
  call void @star_rc_retain(i8* %t1063)
  %t1064 = load i8*, i8** %t1062
  %t1065 = getelementptr inbounds %Enemy, %Enemy* %t1057, i32 0, i32 1
  store i8* %t1064, i8** %t1065
  br label %table_idx_end_198
table_idx_oob_197:
  store %Enemy zeroinitializer, %Enemy* %t1057
  br label %table_idx_end_198
table_idx_end_198:
  %t1066 = load %Enemy, %Enemy* %t1057
  store %Enemy %t1066, %Enemy* %t1067
  %t1068 = getelementptr inbounds %Enemy, %Enemy* %t1067, i32 0, i32 0
  %t1069 = load i32, i32* %t1068
  %t1070 = getelementptr inbounds [38 x i8], [38 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1070, i32 %t1043, i32 %t1069)
  %t1071 = getelementptr inbounds %Enemy, %Enemy* %t1067, i32 0, i32 1
  %t1072 = load i8*, i8** %t1071
  call void @star_rc_release(i8* %t1072)
  %t1073 = getelementptr inbounds %Enemy, %Enemy* %t1041, i32 0, i32 1
  %t1074 = load i8*, i8** %t1073
  call void @star_rc_release(i8* %t1074)
  %t1075 = load i8*, i8** %t888
  call void @star_rc_release(i8* %t1075)
  %t1076 = load i8*, i8** %t787
  call void @star_rc_release(i8* %t1076)
  %t1077 = getelementptr inbounds %Enemy, %Enemy* %t709, i32 0, i32 1
  %t1078 = load i8*, i8** %t1077
  call void @star_rc_release(i8* %t1078)
  %t1079 = load i8*, i8** %t708
  call void @star_rc_release(i8* %t1079)
  %t1080 = getelementptr inbounds %Enemy, %Enemy* %t704, i32 0, i32 1
  %t1081 = load i8*, i8** %t1080
  call void @star_rc_release(i8* %t1081)
  %t1082 = getelementptr inbounds %Enemy, %Enemy* %t586, i32 0, i32 1
  %t1083 = load i8*, i8** %t1082
  call void @star_rc_release(i8* %t1083)
  %t1084 = getelementptr inbounds %Enemy, %Enemy* %t582, i32 0, i32 1
  %t1085 = load i8*, i8** %t1084
  call void @star_rc_release(i8* %t1085)
  %t1086 = getelementptr inbounds %Enemy, %Enemy* %t555, i32 0, i32 1
  %t1087 = load i8*, i8** %t1086
  call void @star_rc_release(i8* %t1087)
  %t1088 = getelementptr inbounds %Enemy, %Enemy* %t449, i32 0, i32 1
  %t1089 = load i8*, i8** %t1088
  call void @star_rc_release(i8* %t1089)
  %t1090 = getelementptr inbounds %Enemy, %Enemy* %t422, i32 0, i32 1
  %t1091 = load i8*, i8** %t1090
  call void @star_rc_release(i8* %t1091)
  %t1092 = getelementptr inbounds %Enemy, %Enemy* %t395, i32 0, i32 1
  %t1093 = load i8*, i8** %t1092
  call void @star_rc_release(i8* %t1093)
  %t1094 = getelementptr inbounds %Enemy, %Enemy* %t368, i32 0, i32 1
  %t1095 = load i8*, i8** %t1094
  call void @star_rc_release(i8* %t1095)
  %t1096 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t1096)
  ret i32 0
}


; par/swarm worker functions
define void @table_release_s_Enemy(i8* %objp) {
entry:
  %t26 = alloca i64
  %t18 = bitcast i8* %objp to { i64, i64, i32*, i8** }*
  %t19 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t18, i32 0, i32 0
  %t20 = load i64, i64* %t19
  %t21 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t18, i32 0, i32 2
  %t22 = load i32*, i32** %t21
  %t23 = bitcast i32* %t22 to i8*
  call void @free(i8* %t23)
  %t24 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t18, i32 0, i32 3
  %t25 = load i8**, i8*** %t24
  store i64 0, i64* %t26
  br label %table_release_cond_6
table_release_cond_6:
  %t27 = load i64, i64* %t26
  %t28 = icmp slt i64 %t27, %t20
  br i1 %t28, label %table_release_body_7, label %table_release_end_8
table_release_body_7:
  %t29 = getelementptr inbounds i8*, i8** %t25, i64 %t27
  %t30 = load i8*, i8** %t29
  call void @star_rc_release(i8* %t30)
  %t31 = add i64 %t27, 1
  store i64 %t31, i64* %t26
  br label %table_release_cond_6
table_release_end_8:
  %t32 = bitcast i8** %t25 to i8*
  call void @free(i8* %t32)
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
