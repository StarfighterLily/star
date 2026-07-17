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

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca i8*
  %t311 = alloca i8
  %t371 = alloca i8*
  %t436 = alloca i8*
  %t474 = alloca i8*
  %t490 = alloca i8*
  %t501 = alloca i8*
  %t584 = alloca i8*
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  store i8* null, i8** %t1
  %t2 = load i8*, i8** %t1
  %t3 = icmp eq i8* %t2, null
  br i1 %t3, label %list_read_null_0, label %list_read_real_1
list_read_null_0:
  br label %list_read_end_2
list_read_real_1:
  %t4 = bitcast i8* %t2 to { i8*, i64, i64 }*
  %t5 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t4, i32 0, i32 0
  %t6 = load i8*, i8** %t5
  %t7 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t4, i32 0, i32 1
  %t8 = load i64, i64* %t7
  br label %list_read_end_2
list_read_end_2:
  %t9 = phi i8* [ null, %list_read_null_0 ], [ %t6, %list_read_real_1 ]
  %t10 = phi i64 [ 0, %list_read_null_0 ], [ %t8, %list_read_real_1 ]
  %t11 = trunc i64 %t10 to i32
  %t12 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t12, i32 %t11)
  %t13 = getelementptr i8, i8* null, i32 1
  %t14 = ptrtoint i8* %t13 to i64
  %t15 = load i8*, i8** %t1
  %t16 = icmp eq i8* %t15, null
  br i1 %t16, label %list_cow_alloc_3, label %list_cow_check_4
list_cow_alloc_3:
  %t21 = bitcast void (i8*)* @list_release_u8 to i8*
  %t22 = call i8* @star_rc_alloc(i64 24, i8* %t21)
  %t23 = bitcast i8* %t22 to { i8*, i64, i64 }*
  %t24 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t23, i32 0, i32 0
  store i8* null, i8** %t24
  %t25 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t23, i32 0, i32 1
  store i64 0, i64* %t25
  %t26 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t23, i32 0, i32 2
  store i64 0, i64* %t26
  store i8* %t22, i8** %t1
  br label %list_cow_done_5
list_cow_check_4:
  %t27 = getelementptr inbounds i8, i8* %t15, i64 -16
  %t28 = bitcast i8* %t27 to i64*
  %t29 = load atomic i64, i64* %t28 seq_cst, align 8
  %t30 = icmp eq i64 %t29, 1
  br i1 %t30, label %list_cow_done_5, label %list_cow_clone_6
list_cow_clone_6:
  %t31 = bitcast i8* %t15 to { i8*, i64, i64 }*
  %t32 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t31, i32 0, i32 0
  %t33 = load i8*, i8** %t32
  %t34 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t31, i32 0, i32 1
  %t35 = load i64, i64* %t34
  %t36 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t31, i32 0, i32 2
  %t37 = load i64, i64* %t36
  %t38 = bitcast void (i8*)* @list_release_u8 to i8*
  %t39 = call i8* @star_rc_alloc(i64 24, i8* %t38)
  %t40 = bitcast i8* %t39 to { i8*, i64, i64 }*
  %t41 = mul i64 %t37, %t14
  %t42 = call i8* @malloc(i64 %t41)
  %t43 = bitcast i8* %t42 to i8*
  %t44 = icmp sgt i64 %t35, 0
  br i1 %t44, label %list_cow_copy_7, label %list_cow_after_copy_8
list_cow_copy_7:
  %t45 = mul i64 %t35, %t14
  %t46 = bitcast i8* %t33 to i8*
  call i8* @memcpy(i8* %t42, i8* %t46, i64 %t45)
  br label %list_cow_after_copy_8
list_cow_after_copy_8:
  %t47 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t40, i32 0, i32 0
  store i8* %t43, i8** %t47
  %t48 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t40, i32 0, i32 1
  store i64 %t35, i64* %t48
  %t49 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t40, i32 0, i32 2
  store i64 %t37, i64* %t49
  call void @star_rc_release(i8* %t15)
  store i8* %t39, i8** %t1
  br label %list_cow_done_5
list_cow_done_5:
  %t50 = load i8*, i8** %t1
  %t51 = bitcast i8* %t50 to { i8*, i64, i64 }*
  %t52 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t51, i32 0, i32 0
  %t53 = load i8*, i8** %t52
  %t54 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t51, i32 0, i32 1
  %t55 = load i64, i64* %t54
  %t56 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t51, i32 0, i32 2
  %t57 = trunc i32 72 to i8
  %t58 = load i64, i64* %t56
  %t59 = load i8*, i8** %t52
  %t60 = load i64, i64* %t54
  %t61 = icmp sge i64 %t60, %t58
  br i1 %t61, label %list_push_grow_9, label %list_push_store_10
list_push_grow_9:
  %t62 = mul i64 %t58, 2
  %t63 = icmp sgt i64 %t62, 0
  %t64 = select i1 %t63, i64 %t62, i64 1
  %t65 = getelementptr i8, i8* null, i32 1
  %t66 = ptrtoint i8* %t65 to i64
  %t67 = mul i64 %t64, %t66
  %t68 = call i8* @malloc(i64 %t67)
  %t69 = bitcast i8* %t68 to i8*
  %t70 = icmp sgt i64 %t58, 0
  br i1 %t70, label %list_push_copy_11, label %list_push_after_copy_12
list_push_copy_11:
  %t71 = mul i64 %t60, %t66
  %t72 = bitcast i8* %t59 to i8*
  call i8* @memcpy(i8* %t68, i8* %t72, i64 %t71)
  call void @free(i8* %t72)
  br label %list_push_after_copy_12
list_push_after_copy_12:
  store i8* %t69, i8** %t52
  store i64 %t64, i64* %t56
  br label %list_push_store_10
list_push_store_10:
  %t73 = load i8*, i8** %t52
  %t74 = getelementptr inbounds i8, i8* %t73, i64 %t60
  store i8 %t57, i8* %t74
  %t75 = add i64 %t60, 1
  store i64 %t75, i64* %t54
  %t76 = getelementptr i8, i8* null, i32 1
  %t77 = ptrtoint i8* %t76 to i64
  %t78 = load i8*, i8** %t1
  %t79 = icmp eq i8* %t78, null
  br i1 %t79, label %list_cow_alloc_13, label %list_cow_check_14
list_cow_alloc_13:
  %t80 = bitcast void (i8*)* @list_release_u8 to i8*
  %t81 = call i8* @star_rc_alloc(i64 24, i8* %t80)
  %t82 = bitcast i8* %t81 to { i8*, i64, i64 }*
  %t83 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t82, i32 0, i32 0
  store i8* null, i8** %t83
  %t84 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t82, i32 0, i32 1
  store i64 0, i64* %t84
  %t85 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t82, i32 0, i32 2
  store i64 0, i64* %t85
  store i8* %t81, i8** %t1
  br label %list_cow_done_15
list_cow_check_14:
  %t86 = getelementptr inbounds i8, i8* %t78, i64 -16
  %t87 = bitcast i8* %t86 to i64*
  %t88 = load atomic i64, i64* %t87 seq_cst, align 8
  %t89 = icmp eq i64 %t88, 1
  br i1 %t89, label %list_cow_done_15, label %list_cow_clone_16
list_cow_clone_16:
  %t90 = bitcast i8* %t78 to { i8*, i64, i64 }*
  %t91 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t90, i32 0, i32 0
  %t92 = load i8*, i8** %t91
  %t93 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t90, i32 0, i32 1
  %t94 = load i64, i64* %t93
  %t95 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t90, i32 0, i32 2
  %t96 = load i64, i64* %t95
  %t97 = bitcast void (i8*)* @list_release_u8 to i8*
  %t98 = call i8* @star_rc_alloc(i64 24, i8* %t97)
  %t99 = bitcast i8* %t98 to { i8*, i64, i64 }*
  %t100 = mul i64 %t96, %t77
  %t101 = call i8* @malloc(i64 %t100)
  %t102 = bitcast i8* %t101 to i8*
  %t103 = icmp sgt i64 %t94, 0
  br i1 %t103, label %list_cow_copy_17, label %list_cow_after_copy_18
list_cow_copy_17:
  %t104 = mul i64 %t94, %t77
  %t105 = bitcast i8* %t92 to i8*
  call i8* @memcpy(i8* %t101, i8* %t105, i64 %t104)
  br label %list_cow_after_copy_18
list_cow_after_copy_18:
  %t106 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t99, i32 0, i32 0
  store i8* %t102, i8** %t106
  %t107 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t99, i32 0, i32 1
  store i64 %t94, i64* %t107
  %t108 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t99, i32 0, i32 2
  store i64 %t96, i64* %t108
  call void @star_rc_release(i8* %t78)
  store i8* %t98, i8** %t1
  br label %list_cow_done_15
list_cow_done_15:
  %t109 = load i8*, i8** %t1
  %t110 = bitcast i8* %t109 to { i8*, i64, i64 }*
  %t111 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t110, i32 0, i32 0
  %t112 = load i8*, i8** %t111
  %t113 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t110, i32 0, i32 1
  %t114 = load i64, i64* %t113
  %t115 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t110, i32 0, i32 2
  %t116 = trunc i32 73 to i8
  %t117 = load i64, i64* %t115
  %t118 = load i8*, i8** %t111
  %t119 = load i64, i64* %t113
  %t120 = icmp sge i64 %t119, %t117
  br i1 %t120, label %list_push_grow_19, label %list_push_store_20
list_push_grow_19:
  %t121 = mul i64 %t117, 2
  %t122 = icmp sgt i64 %t121, 0
  %t123 = select i1 %t122, i64 %t121, i64 1
  %t124 = getelementptr i8, i8* null, i32 1
  %t125 = ptrtoint i8* %t124 to i64
  %t126 = mul i64 %t123, %t125
  %t127 = call i8* @malloc(i64 %t126)
  %t128 = bitcast i8* %t127 to i8*
  %t129 = icmp sgt i64 %t117, 0
  br i1 %t129, label %list_push_copy_21, label %list_push_after_copy_22
list_push_copy_21:
  %t130 = mul i64 %t119, %t125
  %t131 = bitcast i8* %t118 to i8*
  call i8* @memcpy(i8* %t127, i8* %t131, i64 %t130)
  call void @free(i8* %t131)
  br label %list_push_after_copy_22
list_push_after_copy_22:
  store i8* %t128, i8** %t111
  store i64 %t123, i64* %t115
  br label %list_push_store_20
list_push_store_20:
  %t132 = load i8*, i8** %t111
  %t133 = getelementptr inbounds i8, i8* %t132, i64 %t119
  store i8 %t116, i8* %t133
  %t134 = add i64 %t119, 1
  store i64 %t134, i64* %t113
  %t135 = getelementptr i8, i8* null, i32 1
  %t136 = ptrtoint i8* %t135 to i64
  %t137 = load i8*, i8** %t1
  %t138 = icmp eq i8* %t137, null
  br i1 %t138, label %list_cow_alloc_23, label %list_cow_check_24
list_cow_alloc_23:
  %t139 = bitcast void (i8*)* @list_release_u8 to i8*
  %t140 = call i8* @star_rc_alloc(i64 24, i8* %t139)
  %t141 = bitcast i8* %t140 to { i8*, i64, i64 }*
  %t142 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t141, i32 0, i32 0
  store i8* null, i8** %t142
  %t143 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t141, i32 0, i32 1
  store i64 0, i64* %t143
  %t144 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t141, i32 0, i32 2
  store i64 0, i64* %t144
  store i8* %t140, i8** %t1
  br label %list_cow_done_25
list_cow_check_24:
  %t145 = getelementptr inbounds i8, i8* %t137, i64 -16
  %t146 = bitcast i8* %t145 to i64*
  %t147 = load atomic i64, i64* %t146 seq_cst, align 8
  %t148 = icmp eq i64 %t147, 1
  br i1 %t148, label %list_cow_done_25, label %list_cow_clone_26
list_cow_clone_26:
  %t149 = bitcast i8* %t137 to { i8*, i64, i64 }*
  %t150 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t149, i32 0, i32 0
  %t151 = load i8*, i8** %t150
  %t152 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t149, i32 0, i32 1
  %t153 = load i64, i64* %t152
  %t154 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t149, i32 0, i32 2
  %t155 = load i64, i64* %t154
  %t156 = bitcast void (i8*)* @list_release_u8 to i8*
  %t157 = call i8* @star_rc_alloc(i64 24, i8* %t156)
  %t158 = bitcast i8* %t157 to { i8*, i64, i64 }*
  %t159 = mul i64 %t155, %t136
  %t160 = call i8* @malloc(i64 %t159)
  %t161 = bitcast i8* %t160 to i8*
  %t162 = icmp sgt i64 %t153, 0
  br i1 %t162, label %list_cow_copy_27, label %list_cow_after_copy_28
list_cow_copy_27:
  %t163 = mul i64 %t153, %t136
  %t164 = bitcast i8* %t151 to i8*
  call i8* @memcpy(i8* %t160, i8* %t164, i64 %t163)
  br label %list_cow_after_copy_28
list_cow_after_copy_28:
  %t165 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t158, i32 0, i32 0
  store i8* %t161, i8** %t165
  %t166 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t158, i32 0, i32 1
  store i64 %t153, i64* %t166
  %t167 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t158, i32 0, i32 2
  store i64 %t155, i64* %t167
  call void @star_rc_release(i8* %t137)
  store i8* %t157, i8** %t1
  br label %list_cow_done_25
list_cow_done_25:
  %t168 = load i8*, i8** %t1
  %t169 = bitcast i8* %t168 to { i8*, i64, i64 }*
  %t170 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t169, i32 0, i32 0
  %t171 = load i8*, i8** %t170
  %t172 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t169, i32 0, i32 1
  %t173 = load i64, i64* %t172
  %t174 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t169, i32 0, i32 2
  %t175 = trunc i32 33 to i8
  %t176 = load i64, i64* %t174
  %t177 = load i8*, i8** %t170
  %t178 = load i64, i64* %t172
  %t179 = icmp sge i64 %t178, %t176
  br i1 %t179, label %list_push_grow_29, label %list_push_store_30
list_push_grow_29:
  %t180 = mul i64 %t176, 2
  %t181 = icmp sgt i64 %t180, 0
  %t182 = select i1 %t181, i64 %t180, i64 1
  %t183 = getelementptr i8, i8* null, i32 1
  %t184 = ptrtoint i8* %t183 to i64
  %t185 = mul i64 %t182, %t184
  %t186 = call i8* @malloc(i64 %t185)
  %t187 = bitcast i8* %t186 to i8*
  %t188 = icmp sgt i64 %t176, 0
  br i1 %t188, label %list_push_copy_31, label %list_push_after_copy_32
list_push_copy_31:
  %t189 = mul i64 %t178, %t184
  %t190 = bitcast i8* %t177 to i8*
  call i8* @memcpy(i8* %t186, i8* %t190, i64 %t189)
  call void @free(i8* %t190)
  br label %list_push_after_copy_32
list_push_after_copy_32:
  store i8* %t187, i8** %t170
  store i64 %t182, i64* %t174
  br label %list_push_store_30
list_push_store_30:
  %t191 = load i8*, i8** %t170
  %t192 = getelementptr inbounds i8, i8* %t191, i64 %t178
  store i8 %t175, i8* %t192
  %t193 = add i64 %t178, 1
  store i64 %t193, i64* %t172
  %t194 = load i8*, i8** %t1
  %t195 = icmp eq i8* %t194, null
  br i1 %t195, label %list_read_null_33, label %list_read_real_34
list_read_null_33:
  br label %list_read_end_35
list_read_real_34:
  %t196 = bitcast i8* %t194 to { i8*, i64, i64 }*
  %t197 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t196, i32 0, i32 0
  %t198 = load i8*, i8** %t197
  %t199 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t196, i32 0, i32 1
  %t200 = load i64, i64* %t199
  br label %list_read_end_35
list_read_end_35:
  %t201 = phi i8* [ null, %list_read_null_33 ], [ %t198, %list_read_real_34 ]
  %t202 = phi i64 [ 0, %list_read_null_33 ], [ %t200, %list_read_real_34 ]
  %t203 = trunc i64 %t202 to i32
  %t204 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t204, i32 %t203)
  %t205 = load i8*, i8** %t1
  %t206 = icmp eq i8* %t205, null
  br i1 %t206, label %list_read_null_36, label %list_read_real_37
list_read_null_36:
  br label %list_read_end_38
list_read_real_37:
  %t207 = bitcast i8* %t205 to { i8*, i64, i64 }*
  %t208 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t207, i32 0, i32 0
  %t209 = load i8*, i8** %t208
  %t210 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t207, i32 0, i32 1
  %t211 = load i64, i64* %t210
  br label %list_read_end_38
list_read_end_38:
  %t212 = phi i8* [ null, %list_read_null_36 ], [ %t209, %list_read_real_37 ]
  %t213 = phi i64 [ 0, %list_read_null_36 ], [ %t211, %list_read_real_37 ]
  %t214 = sext i32 0 to i64
  %t215 = icmp ult i64 %t214, %t213
  br i1 %t215, label %list_idx_ok_39, label %list_idx_oob_40
list_idx_ok_39:
  %t216 = getelementptr inbounds i8, i8* %t212, i64 %t214
  %t217 = load i8, i8* %t216
  br label %list_idx_end_41
list_idx_oob_40:
  br label %list_idx_end_41
list_idx_end_41:
  %t218 = phi i8 [ %t217, %list_idx_ok_39 ], [ 0, %list_idx_oob_40 ]
  %t219 = load i8*, i8** %t1
  %t220 = icmp eq i8* %t219, null
  br i1 %t220, label %list_read_null_42, label %list_read_real_43
list_read_null_42:
  br label %list_read_end_44
list_read_real_43:
  %t221 = bitcast i8* %t219 to { i8*, i64, i64 }*
  %t222 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t221, i32 0, i32 0
  %t223 = load i8*, i8** %t222
  %t224 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t221, i32 0, i32 1
  %t225 = load i64, i64* %t224
  br label %list_read_end_44
list_read_end_44:
  %t226 = phi i8* [ null, %list_read_null_42 ], [ %t223, %list_read_real_43 ]
  %t227 = phi i64 [ 0, %list_read_null_42 ], [ %t225, %list_read_real_43 ]
  %t228 = sext i32 1 to i64
  %t229 = icmp ult i64 %t228, %t227
  br i1 %t229, label %list_idx_ok_45, label %list_idx_oob_46
list_idx_ok_45:
  %t230 = getelementptr inbounds i8, i8* %t226, i64 %t228
  %t231 = load i8, i8* %t230
  br label %list_idx_end_47
list_idx_oob_46:
  br label %list_idx_end_47
list_idx_end_47:
  %t232 = phi i8 [ %t231, %list_idx_ok_45 ], [ 0, %list_idx_oob_46 ]
  %t233 = load i8*, i8** %t1
  %t234 = icmp eq i8* %t233, null
  br i1 %t234, label %list_read_null_48, label %list_read_real_49
list_read_null_48:
  br label %list_read_end_50
list_read_real_49:
  %t235 = bitcast i8* %t233 to { i8*, i64, i64 }*
  %t236 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t235, i32 0, i32 0
  %t237 = load i8*, i8** %t236
  %t238 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t235, i32 0, i32 1
  %t239 = load i64, i64* %t238
  br label %list_read_end_50
list_read_end_50:
  %t240 = phi i8* [ null, %list_read_null_48 ], [ %t237, %list_read_real_49 ]
  %t241 = phi i64 [ 0, %list_read_null_48 ], [ %t239, %list_read_real_49 ]
  %t242 = sext i32 2 to i64
  %t243 = icmp ult i64 %t242, %t241
  br i1 %t243, label %list_idx_ok_51, label %list_idx_oob_52
list_idx_ok_51:
  %t244 = getelementptr inbounds i8, i8* %t240, i64 %t242
  %t245 = load i8, i8* %t244
  br label %list_idx_end_53
list_idx_oob_52:
  br label %list_idx_end_53
list_idx_end_53:
  %t246 = phi i8 [ %t245, %list_idx_ok_51 ], [ 0, %list_idx_oob_52 ]
  %t247 = getelementptr inbounds [39 x i8], [39 x i8]* @.str.2, i64 0, i64 0
  %t248 = zext i8 %t218 to i32
  %t249 = zext i8 %t232 to i32
  %t250 = zext i8 %t246 to i32
  call i32 (i8*, ...) @printf(i8* %t247, i32 %t248, i32 %t249, i32 %t250)
  %t251 = trunc i32 104 to i8
  %t252 = getelementptr i8, i8* null, i32 1
  %t253 = ptrtoint i8* %t252 to i64
  %t254 = load i8*, i8** %t1
  %t255 = icmp eq i8* %t254, null
  br i1 %t255, label %list_cow_alloc_54, label %list_cow_check_55
list_cow_alloc_54:
  %t256 = bitcast void (i8*)* @list_release_u8 to i8*
  %t257 = call i8* @star_rc_alloc(i64 24, i8* %t256)
  %t258 = bitcast i8* %t257 to { i8*, i64, i64 }*
  %t259 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t258, i32 0, i32 0
  store i8* null, i8** %t259
  %t260 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t258, i32 0, i32 1
  store i64 0, i64* %t260
  %t261 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t258, i32 0, i32 2
  store i64 0, i64* %t261
  store i8* %t257, i8** %t1
  br label %list_cow_done_56
list_cow_check_55:
  %t262 = getelementptr inbounds i8, i8* %t254, i64 -16
  %t263 = bitcast i8* %t262 to i64*
  %t264 = load atomic i64, i64* %t263 seq_cst, align 8
  %t265 = icmp eq i64 %t264, 1
  br i1 %t265, label %list_cow_done_56, label %list_cow_clone_57
list_cow_clone_57:
  %t266 = bitcast i8* %t254 to { i8*, i64, i64 }*
  %t267 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t266, i32 0, i32 0
  %t268 = load i8*, i8** %t267
  %t269 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t266, i32 0, i32 1
  %t270 = load i64, i64* %t269
  %t271 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t266, i32 0, i32 2
  %t272 = load i64, i64* %t271
  %t273 = bitcast void (i8*)* @list_release_u8 to i8*
  %t274 = call i8* @star_rc_alloc(i64 24, i8* %t273)
  %t275 = bitcast i8* %t274 to { i8*, i64, i64 }*
  %t276 = mul i64 %t272, %t253
  %t277 = call i8* @malloc(i64 %t276)
  %t278 = bitcast i8* %t277 to i8*
  %t279 = icmp sgt i64 %t270, 0
  br i1 %t279, label %list_cow_copy_58, label %list_cow_after_copy_59
list_cow_copy_58:
  %t280 = mul i64 %t270, %t253
  %t281 = bitcast i8* %t268 to i8*
  call i8* @memcpy(i8* %t277, i8* %t281, i64 %t280)
  br label %list_cow_after_copy_59
list_cow_after_copy_59:
  %t282 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t275, i32 0, i32 0
  store i8* %t278, i8** %t282
  %t283 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t275, i32 0, i32 1
  store i64 %t270, i64* %t283
  %t284 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t275, i32 0, i32 2
  store i64 %t272, i64* %t284
  call void @star_rc_release(i8* %t254)
  store i8* %t274, i8** %t1
  br label %list_cow_done_56
list_cow_done_56:
  %t285 = load i8*, i8** %t1
  %t286 = bitcast i8* %t285 to { i8*, i64, i64 }*
  %t287 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t286, i32 0, i32 0
  %t288 = load i8*, i8** %t287
  %t289 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t286, i32 0, i32 1
  %t290 = load i64, i64* %t289
  %t291 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t286, i32 0, i32 2
  %t292 = sext i32 0 to i64
  %t293 = icmp ult i64 %t292, %t290
  br i1 %t293, label %list_set_do_60, label %list_set_oob_61
list_set_do_60:
  %t294 = getelementptr inbounds i8, i8* %t288, i64 %t292
  store i8 %t251, i8* %t294
  br label %list_set_end_62
list_set_oob_61:
  br label %list_set_end_62
list_set_end_62:
  %t295 = load i8*, i8** %t1
  %t296 = icmp eq i8* %t295, null
  br i1 %t296, label %list_read_null_63, label %list_read_real_64
list_read_null_63:
  br label %list_read_end_65
list_read_real_64:
  %t297 = bitcast i8* %t295 to { i8*, i64, i64 }*
  %t298 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t297, i32 0, i32 0
  %t299 = load i8*, i8** %t298
  %t300 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t297, i32 0, i32 1
  %t301 = load i64, i64* %t300
  br label %list_read_end_65
list_read_end_65:
  %t302 = phi i8* [ null, %list_read_null_63 ], [ %t299, %list_read_real_64 ]
  %t303 = phi i64 [ 0, %list_read_null_63 ], [ %t301, %list_read_real_64 ]
  %t304 = sext i32 0 to i64
  %t305 = icmp ult i64 %t304, %t303
  br i1 %t305, label %list_idx_ok_66, label %list_idx_oob_67
list_idx_ok_66:
  %t306 = getelementptr inbounds i8, i8* %t302, i64 %t304
  %t307 = load i8, i8* %t306
  br label %list_idx_end_68
list_idx_oob_67:
  br label %list_idx_end_68
list_idx_end_68:
  %t308 = phi i8 [ %t307, %list_idx_ok_66 ], [ 0, %list_idx_oob_67 ]
  %t309 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.3, i64 0, i64 0
  %t310 = zext i8 %t308 to i32
  call i32 (i8*, ...) @printf(i8* %t309, i32 %t310)
  %t312 = getelementptr i8, i8* null, i32 1
  %t313 = ptrtoint i8* %t312 to i64
  %t314 = load i8*, i8** %t1
  %t315 = icmp eq i8* %t314, null
  br i1 %t315, label %list_cow_alloc_69, label %list_cow_check_70
list_cow_alloc_69:
  %t316 = bitcast void (i8*)* @list_release_u8 to i8*
  %t317 = call i8* @star_rc_alloc(i64 24, i8* %t316)
  %t318 = bitcast i8* %t317 to { i8*, i64, i64 }*
  %t319 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t318, i32 0, i32 0
  store i8* null, i8** %t319
  %t320 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t318, i32 0, i32 1
  store i64 0, i64* %t320
  %t321 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t318, i32 0, i32 2
  store i64 0, i64* %t321
  store i8* %t317, i8** %t1
  br label %list_cow_done_71
list_cow_check_70:
  %t322 = getelementptr inbounds i8, i8* %t314, i64 -16
  %t323 = bitcast i8* %t322 to i64*
  %t324 = load atomic i64, i64* %t323 seq_cst, align 8
  %t325 = icmp eq i64 %t324, 1
  br i1 %t325, label %list_cow_done_71, label %list_cow_clone_72
list_cow_clone_72:
  %t326 = bitcast i8* %t314 to { i8*, i64, i64 }*
  %t327 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t326, i32 0, i32 0
  %t328 = load i8*, i8** %t327
  %t329 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t326, i32 0, i32 1
  %t330 = load i64, i64* %t329
  %t331 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t326, i32 0, i32 2
  %t332 = load i64, i64* %t331
  %t333 = bitcast void (i8*)* @list_release_u8 to i8*
  %t334 = call i8* @star_rc_alloc(i64 24, i8* %t333)
  %t335 = bitcast i8* %t334 to { i8*, i64, i64 }*
  %t336 = mul i64 %t332, %t313
  %t337 = call i8* @malloc(i64 %t336)
  %t338 = bitcast i8* %t337 to i8*
  %t339 = icmp sgt i64 %t330, 0
  br i1 %t339, label %list_cow_copy_73, label %list_cow_after_copy_74
list_cow_copy_73:
  %t340 = mul i64 %t330, %t313
  %t341 = bitcast i8* %t328 to i8*
  call i8* @memcpy(i8* %t337, i8* %t341, i64 %t340)
  br label %list_cow_after_copy_74
list_cow_after_copy_74:
  %t342 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t335, i32 0, i32 0
  store i8* %t338, i8** %t342
  %t343 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t335, i32 0, i32 1
  store i64 %t330, i64* %t343
  %t344 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t335, i32 0, i32 2
  store i64 %t332, i64* %t344
  call void @star_rc_release(i8* %t314)
  store i8* %t334, i8** %t1
  br label %list_cow_done_71
list_cow_done_71:
  %t345 = load i8*, i8** %t1
  %t346 = bitcast i8* %t345 to { i8*, i64, i64 }*
  %t347 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t346, i32 0, i32 0
  %t348 = load i8*, i8** %t347
  %t349 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t346, i32 0, i32 1
  %t350 = load i64, i64* %t349
  %t351 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t346, i32 0, i32 2
  %t352 = icmp eq i64 %t350, 0
  br i1 %t352, label %list_pop_empty_75, label %list_pop_nonempty_76
list_pop_nonempty_76:
  %t353 = sub i64 %t350, 1
  store i64 %t353, i64* %t349
  %t354 = load i8*, i8** %t347
  %t355 = getelementptr inbounds i8, i8* %t354, i64 %t353
  %t356 = load i8, i8* %t355
  br label %list_pop_end_77
list_pop_empty_75:
  br label %list_pop_end_77
list_pop_end_77:
  %t357 = phi i8 [ %t356, %list_pop_nonempty_76 ], [ 0, %list_pop_empty_75 ]
  store i8 %t357, i8* %t311
  %t358 = load i8, i8* %t311
  %t359 = load i8*, i8** %t1
  %t360 = icmp eq i8* %t359, null
  br i1 %t360, label %list_read_null_78, label %list_read_real_79
list_read_null_78:
  br label %list_read_end_80
list_read_real_79:
  %t361 = bitcast i8* %t359 to { i8*, i64, i64 }*
  %t362 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t361, i32 0, i32 0
  %t363 = load i8*, i8** %t362
  %t364 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t361, i32 0, i32 1
  %t365 = load i64, i64* %t364
  br label %list_read_end_80
list_read_end_80:
  %t366 = phi i8* [ null, %list_read_null_78 ], [ %t363, %list_read_real_79 ]
  %t367 = phi i64 [ 0, %list_read_null_78 ], [ %t365, %list_read_real_79 ]
  %t368 = trunc i64 %t367 to i32
  %t369 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.4, i64 0, i64 0
  %t370 = zext i8 %t358 to i32
  call i32 (i8*, ...) @printf(i8* %t369, i32 %t370, i32 %t368)
  store i8* null, i8** %t371
  %t372 = getelementptr i8, i8* null, i32 1
  %t373 = ptrtoint i8* %t372 to i64
  %t374 = load i8*, i8** %t371
  %t375 = icmp eq i8* %t374, null
  br i1 %t375, label %list_cow_alloc_81, label %list_cow_check_82
list_cow_alloc_81:
  %t376 = bitcast void (i8*)* @list_release_u8 to i8*
  %t377 = call i8* @star_rc_alloc(i64 24, i8* %t376)
  %t378 = bitcast i8* %t377 to { i8*, i64, i64 }*
  %t379 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t378, i32 0, i32 0
  store i8* null, i8** %t379
  %t380 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t378, i32 0, i32 1
  store i64 0, i64* %t380
  %t381 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t378, i32 0, i32 2
  store i64 0, i64* %t381
  store i8* %t377, i8** %t371
  br label %list_cow_done_83
list_cow_check_82:
  %t382 = getelementptr inbounds i8, i8* %t374, i64 -16
  %t383 = bitcast i8* %t382 to i64*
  %t384 = load atomic i64, i64* %t383 seq_cst, align 8
  %t385 = icmp eq i64 %t384, 1
  br i1 %t385, label %list_cow_done_83, label %list_cow_clone_84
list_cow_clone_84:
  %t386 = bitcast i8* %t374 to { i8*, i64, i64 }*
  %t387 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t386, i32 0, i32 0
  %t388 = load i8*, i8** %t387
  %t389 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t386, i32 0, i32 1
  %t390 = load i64, i64* %t389
  %t391 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t386, i32 0, i32 2
  %t392 = load i64, i64* %t391
  %t393 = bitcast void (i8*)* @list_release_u8 to i8*
  %t394 = call i8* @star_rc_alloc(i64 24, i8* %t393)
  %t395 = bitcast i8* %t394 to { i8*, i64, i64 }*
  %t396 = mul i64 %t392, %t373
  %t397 = call i8* @malloc(i64 %t396)
  %t398 = bitcast i8* %t397 to i8*
  %t399 = icmp sgt i64 %t390, 0
  br i1 %t399, label %list_cow_copy_85, label %list_cow_after_copy_86
list_cow_copy_85:
  %t400 = mul i64 %t390, %t373
  %t401 = bitcast i8* %t388 to i8*
  call i8* @memcpy(i8* %t397, i8* %t401, i64 %t400)
  br label %list_cow_after_copy_86
list_cow_after_copy_86:
  %t402 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t395, i32 0, i32 0
  store i8* %t398, i8** %t402
  %t403 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t395, i32 0, i32 1
  store i64 %t390, i64* %t403
  %t404 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t395, i32 0, i32 2
  store i64 %t392, i64* %t404
  call void @star_rc_release(i8* %t374)
  store i8* %t394, i8** %t371
  br label %list_cow_done_83
list_cow_done_83:
  %t405 = load i8*, i8** %t371
  %t406 = bitcast i8* %t405 to { i8*, i64, i64 }*
  %t407 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t406, i32 0, i32 0
  %t408 = load i8*, i8** %t407
  %t409 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t406, i32 0, i32 1
  %t410 = load i64, i64* %t409
  %t411 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t406, i32 0, i32 2
  %t412 = icmp eq i64 %t410, 0
  br i1 %t412, label %list_pop_empty_87, label %list_pop_nonempty_88
list_pop_nonempty_88:
  %t413 = sub i64 %t410, 1
  store i64 %t413, i64* %t409
  %t414 = load i8*, i8** %t407
  %t415 = getelementptr inbounds i8, i8* %t414, i64 %t413
  %t416 = load i8, i8* %t415
  br label %list_pop_end_89
list_pop_empty_87:
  br label %list_pop_end_89
list_pop_end_89:
  %t417 = phi i8 [ %t416, %list_pop_nonempty_88 ], [ 0, %list_pop_empty_87 ]
  %t418 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.5, i64 0, i64 0
  %t419 = zext i8 %t417 to i32
  call i32 (i8*, ...) @printf(i8* %t418, i32 %t419)
  %t420 = load i8*, i8** %t371
  %t421 = icmp eq i8* %t420, null
  br i1 %t421, label %list_read_null_90, label %list_read_real_91
list_read_null_90:
  br label %list_read_end_92
list_read_real_91:
  %t422 = bitcast i8* %t420 to { i8*, i64, i64 }*
  %t423 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t422, i32 0, i32 0
  %t424 = load i8*, i8** %t423
  %t425 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t422, i32 0, i32 1
  %t426 = load i64, i64* %t425
  br label %list_read_end_92
list_read_end_92:
  %t427 = phi i8* [ null, %list_read_null_90 ], [ %t424, %list_read_real_91 ]
  %t428 = phi i64 [ 0, %list_read_null_90 ], [ %t426, %list_read_real_91 ]
  %t429 = sext i32 0 to i64
  %t430 = icmp ult i64 %t429, %t428
  br i1 %t430, label %list_idx_ok_93, label %list_idx_oob_94
list_idx_ok_93:
  %t431 = getelementptr inbounds i8, i8* %t427, i64 %t429
  %t432 = load i8, i8* %t431
  br label %list_idx_end_95
list_idx_oob_94:
  br label %list_idx_end_95
list_idx_end_95:
  %t433 = phi i8 [ %t432, %list_idx_ok_93 ], [ 0, %list_idx_oob_94 ]
  %t434 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.6, i64 0, i64 0
  %t435 = zext i8 %t433 to i32
  call i32 (i8*, ...) @printf(i8* %t434, i32 %t435)
  %t437 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t438 = call i32 @strlen(i8* %t437)
  %t439 = sext i32 %t438 to i64
  %t440 = call i8* @malloc(i64 %t439)
  call i8* @memcpy(i8* %t440, i8* %t437, i64 %t439)
  call void @star_rc_release(i8* %t437)
  %t441 = bitcast void (i8*)* @list_release_u8 to i8*
  %t442 = call i8* @star_rc_alloc(i64 24, i8* %t441)
  %t443 = bitcast i8* %t442 to { i8*, i64, i64 }*
  %t444 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t443, i32 0, i32 0
  store i8* %t440, i8** %t444
  %t445 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t443, i32 0, i32 1
  store i64 %t439, i64* %t445
  %t446 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t443, i32 0, i32 2
  store i64 %t439, i64* %t446
  store i8* %t442, i8** %t436
  %t447 = load i8*, i8** %t436
  %t448 = icmp eq i8* %t447, null
  br i1 %t448, label %list_read_null_96, label %list_read_real_97
list_read_null_96:
  br label %list_read_end_98
list_read_real_97:
  %t449 = bitcast i8* %t447 to { i8*, i64, i64 }*
  %t450 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t449, i32 0, i32 0
  %t451 = load i8*, i8** %t450
  %t452 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t449, i32 0, i32 1
  %t453 = load i64, i64* %t452
  br label %list_read_end_98
list_read_end_98:
  %t454 = phi i8* [ null, %list_read_null_96 ], [ %t451, %list_read_real_97 ]
  %t455 = phi i64 [ 0, %list_read_null_96 ], [ %t453, %list_read_real_97 ]
  %t456 = trunc i64 %t455 to i32
  %t457 = getelementptr inbounds [36 x i8], [36 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t457, i32 %t456)
  %t458 = load i8*, i8** %t436
  %t459 = icmp eq i8* %t458, null
  br i1 %t459, label %list_read_null_99, label %list_read_real_100
list_read_null_99:
  br label %list_read_end_101
list_read_real_100:
  %t460 = bitcast i8* %t458 to { i8*, i64, i64 }*
  %t461 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t460, i32 0, i32 0
  %t462 = load i8*, i8** %t461
  %t463 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t460, i32 0, i32 1
  %t464 = load i64, i64* %t463
  br label %list_read_end_101
list_read_end_101:
  %t465 = phi i8* [ null, %list_read_null_99 ], [ %t462, %list_read_real_100 ]
  %t466 = phi i64 [ 0, %list_read_null_99 ], [ %t464, %list_read_real_100 ]
  %t467 = sext i32 0 to i64
  %t468 = icmp ult i64 %t467, %t466
  br i1 %t468, label %list_idx_ok_102, label %list_idx_oob_103
list_idx_ok_102:
  %t469 = getelementptr inbounds i8, i8* %t465, i64 %t467
  %t470 = load i8, i8* %t469
  br label %list_idx_end_104
list_idx_oob_103:
  br label %list_idx_end_104
list_idx_end_104:
  %t471 = phi i8 [ %t470, %list_idx_ok_102 ], [ 0, %list_idx_oob_103 ]
  %t472 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.9, i64 0, i64 0
  %t473 = zext i8 %t471 to i32
  call i32 (i8*, ...) @printf(i8* %t472, i32 %t473)
  %t475 = load i8*, i8** %t436
  %t476 = icmp eq i8* %t475, null
  br i1 %t476, label %list_read_null_105, label %list_read_real_106
list_read_null_105:
  br label %list_read_end_107
list_read_real_106:
  %t477 = bitcast i8* %t475 to { i8*, i64, i64 }*
  %t478 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t477, i32 0, i32 0
  %t479 = load i8*, i8** %t478
  %t480 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t477, i32 0, i32 1
  %t481 = load i64, i64* %t480
  br label %list_read_end_107
list_read_end_107:
  %t482 = phi i8* [ null, %list_read_null_105 ], [ %t479, %list_read_real_106 ]
  %t483 = phi i64 [ 0, %list_read_null_105 ], [ %t481, %list_read_real_106 ]
  %t484 = add i64 %t483, 1
  %t485 = call i8* @star_rc_alloc(i64 %t484, i8* null)
  call i8* @memcpy(i8* %t485, i8* %t482, i64 %t483)
  %t486 = getelementptr inbounds i8, i8* %t485, i64 %t483
  store i8 0, i8* %t486
  store i8* %t485, i8** %t474
  %t487 = load i8*, i8** %t474
  %t488 = load i8*, i8** %t474
  call void @star_rc_retain(i8* %t488)
  call void @star_rc_release(i8* %t487)
  %t489 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t489, i8* %t487)
  %t491 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t492 = call i32 @strlen(i8* %t491)
  %t493 = sext i32 %t492 to i64
  %t494 = call i8* @malloc(i64 %t493)
  call i8* @memcpy(i8* %t494, i8* %t491, i64 %t493)
  call void @star_rc_release(i8* %t491)
  %t495 = bitcast void (i8*)* @list_release_u8 to i8*
  %t496 = call i8* @star_rc_alloc(i64 24, i8* %t495)
  %t497 = bitcast i8* %t496 to { i8*, i64, i64 }*
  %t498 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t497, i32 0, i32 0
  store i8* %t494, i8** %t498
  %t499 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t497, i32 0, i32 1
  store i64 %t493, i64* %t499
  %t500 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t497, i32 0, i32 2
  store i64 %t493, i64* %t500
  store i8* %t496, i8** %t490
  %t502 = load i8*, i8** %t490
  %t503 = load i8*, i8** %t490
  call void @star_rc_retain(i8* %t503)
  store i8* %t502, i8** %t501
  %t504 = getelementptr i8, i8* null, i32 1
  %t505 = ptrtoint i8* %t504 to i64
  %t506 = load i8*, i8** %t490
  %t507 = icmp eq i8* %t506, null
  br i1 %t507, label %list_cow_alloc_108, label %list_cow_check_109
list_cow_alloc_108:
  %t508 = bitcast void (i8*)* @list_release_u8 to i8*
  %t509 = call i8* @star_rc_alloc(i64 24, i8* %t508)
  %t510 = bitcast i8* %t509 to { i8*, i64, i64 }*
  %t511 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t510, i32 0, i32 0
  store i8* null, i8** %t511
  %t512 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t510, i32 0, i32 1
  store i64 0, i64* %t512
  %t513 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t510, i32 0, i32 2
  store i64 0, i64* %t513
  store i8* %t509, i8** %t490
  br label %list_cow_done_110
list_cow_check_109:
  %t514 = getelementptr inbounds i8, i8* %t506, i64 -16
  %t515 = bitcast i8* %t514 to i64*
  %t516 = load atomic i64, i64* %t515 seq_cst, align 8
  %t517 = icmp eq i64 %t516, 1
  br i1 %t517, label %list_cow_done_110, label %list_cow_clone_111
list_cow_clone_111:
  %t518 = bitcast i8* %t506 to { i8*, i64, i64 }*
  %t519 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t518, i32 0, i32 0
  %t520 = load i8*, i8** %t519
  %t521 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t518, i32 0, i32 1
  %t522 = load i64, i64* %t521
  %t523 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t518, i32 0, i32 2
  %t524 = load i64, i64* %t523
  %t525 = bitcast void (i8*)* @list_release_u8 to i8*
  %t526 = call i8* @star_rc_alloc(i64 24, i8* %t525)
  %t527 = bitcast i8* %t526 to { i8*, i64, i64 }*
  %t528 = mul i64 %t524, %t505
  %t529 = call i8* @malloc(i64 %t528)
  %t530 = bitcast i8* %t529 to i8*
  %t531 = icmp sgt i64 %t522, 0
  br i1 %t531, label %list_cow_copy_112, label %list_cow_after_copy_113
list_cow_copy_112:
  %t532 = mul i64 %t522, %t505
  %t533 = bitcast i8* %t520 to i8*
  call i8* @memcpy(i8* %t529, i8* %t533, i64 %t532)
  br label %list_cow_after_copy_113
list_cow_after_copy_113:
  %t534 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t527, i32 0, i32 0
  store i8* %t530, i8** %t534
  %t535 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t527, i32 0, i32 1
  store i64 %t522, i64* %t535
  %t536 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t527, i32 0, i32 2
  store i64 %t524, i64* %t536
  call void @star_rc_release(i8* %t506)
  store i8* %t526, i8** %t490
  br label %list_cow_done_110
list_cow_done_110:
  %t537 = load i8*, i8** %t490
  %t538 = bitcast i8* %t537 to { i8*, i64, i64 }*
  %t539 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t538, i32 0, i32 0
  %t540 = load i8*, i8** %t539
  %t541 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t538, i32 0, i32 1
  %t542 = load i64, i64* %t541
  %t543 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t538, i32 0, i32 2
  %t544 = trunc i32 99 to i8
  %t545 = load i64, i64* %t543
  %t546 = load i8*, i8** %t539
  %t547 = load i64, i64* %t541
  %t548 = icmp sge i64 %t547, %t545
  br i1 %t548, label %list_push_grow_114, label %list_push_store_115
list_push_grow_114:
  %t549 = mul i64 %t545, 2
  %t550 = icmp sgt i64 %t549, 0
  %t551 = select i1 %t550, i64 %t549, i64 1
  %t552 = getelementptr i8, i8* null, i32 1
  %t553 = ptrtoint i8* %t552 to i64
  %t554 = mul i64 %t551, %t553
  %t555 = call i8* @malloc(i64 %t554)
  %t556 = bitcast i8* %t555 to i8*
  %t557 = icmp sgt i64 %t545, 0
  br i1 %t557, label %list_push_copy_116, label %list_push_after_copy_117
list_push_copy_116:
  %t558 = mul i64 %t547, %t553
  %t559 = bitcast i8* %t546 to i8*
  call i8* @memcpy(i8* %t555, i8* %t559, i64 %t558)
  call void @free(i8* %t559)
  br label %list_push_after_copy_117
list_push_after_copy_117:
  store i8* %t556, i8** %t539
  store i64 %t551, i64* %t543
  br label %list_push_store_115
list_push_store_115:
  %t560 = load i8*, i8** %t539
  %t561 = getelementptr inbounds i8, i8* %t560, i64 %t547
  store i8 %t544, i8* %t561
  %t562 = add i64 %t547, 1
  store i64 %t562, i64* %t541
  %t563 = load i8*, i8** %t490
  %t564 = icmp eq i8* %t563, null
  br i1 %t564, label %list_read_null_118, label %list_read_real_119
list_read_null_118:
  br label %list_read_end_120
list_read_real_119:
  %t565 = bitcast i8* %t563 to { i8*, i64, i64 }*
  %t566 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t565, i32 0, i32 0
  %t567 = load i8*, i8** %t566
  %t568 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t565, i32 0, i32 1
  %t569 = load i64, i64* %t568
  br label %list_read_end_120
list_read_end_120:
  %t570 = phi i8* [ null, %list_read_null_118 ], [ %t567, %list_read_real_119 ]
  %t571 = phi i64 [ 0, %list_read_null_118 ], [ %t569, %list_read_real_119 ]
  %t572 = trunc i64 %t571 to i32
  %t573 = load i8*, i8** %t501
  %t574 = icmp eq i8* %t573, null
  br i1 %t574, label %list_read_null_121, label %list_read_real_122
list_read_null_121:
  br label %list_read_end_123
list_read_real_122:
  %t575 = bitcast i8* %t573 to { i8*, i64, i64 }*
  %t576 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t575, i32 0, i32 0
  %t577 = load i8*, i8** %t576
  %t578 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t575, i32 0, i32 1
  %t579 = load i64, i64* %t578
  br label %list_read_end_123
list_read_end_123:
  %t580 = phi i8* [ null, %list_read_null_121 ], [ %t577, %list_read_real_122 ]
  %t581 = phi i64 [ 0, %list_read_null_121 ], [ %t579, %list_read_real_122 ]
  %t582 = trunc i64 %t581 to i32
  %t583 = getelementptr inbounds [28 x i8], [28 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t583, i32 %t572, i32 %t582)
  %t585 = getelementptr inbounds { i64, i8*, [1 x i8] }, { i64, i8*, [1 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t586 = call i32 @strlen(i8* %t585)
  %t587 = sext i32 %t586 to i64
  %t588 = call i8* @malloc(i64 %t587)
  call i8* @memcpy(i8* %t588, i8* %t585, i64 %t587)
  call void @star_rc_release(i8* %t585)
  %t589 = bitcast void (i8*)* @list_release_u8 to i8*
  %t590 = call i8* @star_rc_alloc(i64 24, i8* %t589)
  %t591 = bitcast i8* %t590 to { i8*, i64, i64 }*
  %t592 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t591, i32 0, i32 0
  store i8* %t588, i8** %t592
  %t593 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t591, i32 0, i32 1
  store i64 %t587, i64* %t593
  %t594 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t591, i32 0, i32 2
  store i64 %t587, i64* %t594
  store i8* %t590, i8** %t584
  %t595 = load i8*, i8** %t584
  %t596 = icmp eq i8* %t595, null
  br i1 %t596, label %list_read_null_124, label %list_read_real_125
list_read_null_124:
  br label %list_read_end_126
list_read_real_125:
  %t597 = bitcast i8* %t595 to { i8*, i64, i64 }*
  %t598 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t597, i32 0, i32 0
  %t599 = load i8*, i8** %t598
  %t600 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t597, i32 0, i32 1
  %t601 = load i64, i64* %t600
  br label %list_read_end_126
list_read_end_126:
  %t602 = phi i8* [ null, %list_read_null_124 ], [ %t599, %list_read_real_125 ]
  %t603 = phi i64 [ 0, %list_read_null_124 ], [ %t601, %list_read_real_125 ]
  %t604 = trunc i64 %t603 to i32
  %t605 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t605, i32 %t604)
  %t606 = load i8*, i8** %t584
  %t607 = icmp eq i8* %t606, null
  br i1 %t607, label %list_read_null_127, label %list_read_real_128
list_read_null_127:
  br label %list_read_end_129
list_read_real_128:
  %t608 = bitcast i8* %t606 to { i8*, i64, i64 }*
  %t609 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t608, i32 0, i32 0
  %t610 = load i8*, i8** %t609
  %t611 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t608, i32 0, i32 1
  %t612 = load i64, i64* %t611
  br label %list_read_end_129
list_read_end_129:
  %t613 = phi i8* [ null, %list_read_null_127 ], [ %t610, %list_read_real_128 ]
  %t614 = phi i64 [ 0, %list_read_null_127 ], [ %t612, %list_read_real_128 ]
  %t615 = add i64 %t614, 1
  %t616 = call i8* @star_rc_alloc(i64 %t615, i8* null)
  call i8* @memcpy(i8* %t616, i8* %t613, i64 %t614)
  %t617 = getelementptr inbounds i8, i8* %t616, i64 %t614
  store i8 0, i8* %t617
  call void @star_rc_release(i8* %t616)
  %t618 = getelementptr inbounds [30 x i8], [30 x i8]* @.str.15, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t618, i8* %t616)
  %t619 = load i8*, i8** %t584
  call void @star_rc_release(i8* %t619)
  %t620 = load i8*, i8** %t501
  call void @star_rc_release(i8* %t620)
  %t621 = load i8*, i8** %t490
  call void @star_rc_release(i8* %t621)
  %t622 = load i8*, i8** %t474
  call void @star_rc_release(i8* %t622)
  %t623 = load i8*, i8** %t436
  call void @star_rc_release(i8* %t623)
  %t624 = load i8*, i8** %t371
  call void @star_rc_release(i8* %t624)
  %t625 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t625)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_u8(i8* %objp) {
entry:
  %t17 = bitcast i8* %objp to { i8*, i64, i64 }*
  %t18 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t17, i32 0, i32 0
  %t19 = load i8*, i8** %t18
  %t20 = bitcast i8* %t19 to i8*
  call void @free(i8* %t20)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant [22 x i8] c"empty buf.len() = %d\0A\00"
@.str.1 = private unnamed_addr constant [26 x i8] c"after 3 pushes, len = %d\0A\00"
@.str.2 = private unnamed_addr constant [39 x i8] c"buf[0] = %u, buf[1] = %u, buf[2] = %u\0A\00"
@.str.3 = private unnamed_addr constant [33 x i8] c"after buf[0] = 104, buf[0] = %u\0A\00"
@.str.4 = private unnamed_addr constant [27 x i8] c"popped = %u, len now = %d\0A\00"
@.str.5 = private unnamed_addr constant [18 x i8] c"empty.pop() = %u\0A\00"
@.str.6 = private unnamed_addr constant [15 x i8] c"empty[0] = %u\0A\00"
@.str.7 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"Hello\00" }
@.str.8 = private unnamed_addr constant [36 x i8] c"bytes_from_str(\22Hello\22).len() = %d\0A\00"
@.str.9 = private unnamed_addr constant [33 x i8] c"bytes_from_str(\22Hello\22)[0] = %u\0A\00"
@.str.10 = private unnamed_addr constant [16 x i8] c"round-trip: %s\0A\00"
@.str.11 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"ab\00" }
@.str.12 = private unnamed_addr constant [28 x i8] c"a.len() = %d, b.len() = %d\0A\00"
@.str.13 = private unnamed_addr constant { i64, i8*, [1 x i8] } { i64 -1, i8* null, [1 x i8] c"\00" }
@.str.14 = private unnamed_addr constant [31 x i8] c"bytes_from_str(\22\22).len() = %d\0A\00"
@.str.15 = private unnamed_addr constant [30 x i8] c"str_from_bytes(empty) = \22%s\22\0A\00"
