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

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t0 = alloca i8*
  %t310 = alloca i8
  %t370 = alloca i8*
  %t435 = alloca i8*
  %t473 = alloca i8*
  %t489 = alloca i8*
  %t500 = alloca i8*
  %t583 = alloca i8*
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  store i8* null, i8** %t0
  %t1 = load i8*, i8** %t0
  %t2 = icmp eq i8* %t1, null
  br i1 %t2, label %list_read_null_0, label %list_read_real_1
list_read_null_0:
  br label %list_read_end_2
list_read_real_1:
  %t3 = bitcast i8* %t1 to { i8*, i64, i64 }*
  %t4 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t3, i32 0, i32 0
  %t5 = load i8*, i8** %t4
  %t6 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t3, i32 0, i32 1
  %t7 = load i64, i64* %t6
  br label %list_read_end_2
list_read_end_2:
  %t8 = phi i8* [ null, %list_read_null_0 ], [ %t5, %list_read_real_1 ]
  %t9 = phi i64 [ 0, %list_read_null_0 ], [ %t7, %list_read_real_1 ]
  %t10 = trunc i64 %t9 to i32
  %t11 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t11, i32 %t10)
  %t12 = getelementptr i8, i8* null, i32 1
  %t13 = ptrtoint i8* %t12 to i64
  %t14 = load i8*, i8** %t0
  %t15 = icmp eq i8* %t14, null
  br i1 %t15, label %list_cow_alloc_3, label %list_cow_check_4
list_cow_alloc_3:
  %t20 = bitcast void (i8*)* @list_release_u8 to i8*
  %t21 = call i8* @star_rc_alloc(i64 24, i8* %t20)
  %t22 = bitcast i8* %t21 to { i8*, i64, i64 }*
  %t23 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t22, i32 0, i32 0
  store i8* null, i8** %t23
  %t24 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t22, i32 0, i32 1
  store i64 0, i64* %t24
  %t25 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t22, i32 0, i32 2
  store i64 0, i64* %t25
  store i8* %t21, i8** %t0
  br label %list_cow_done_5
list_cow_check_4:
  %t26 = getelementptr inbounds i8, i8* %t14, i64 -16
  %t27 = bitcast i8* %t26 to i64*
  %t28 = load atomic i64, i64* %t27 seq_cst, align 8
  %t29 = icmp eq i64 %t28, 1
  br i1 %t29, label %list_cow_done_5, label %list_cow_clone_6
list_cow_clone_6:
  %t30 = bitcast i8* %t14 to { i8*, i64, i64 }*
  %t31 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t30, i32 0, i32 0
  %t32 = load i8*, i8** %t31
  %t33 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t30, i32 0, i32 1
  %t34 = load i64, i64* %t33
  %t35 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t30, i32 0, i32 2
  %t36 = load i64, i64* %t35
  %t37 = bitcast void (i8*)* @list_release_u8 to i8*
  %t38 = call i8* @star_rc_alloc(i64 24, i8* %t37)
  %t39 = bitcast i8* %t38 to { i8*, i64, i64 }*
  %t40 = mul i64 %t36, %t13
  %t41 = call i8* @malloc(i64 %t40)
  %t42 = bitcast i8* %t41 to i8*
  %t43 = icmp sgt i64 %t34, 0
  br i1 %t43, label %list_cow_copy_7, label %list_cow_after_copy_8
list_cow_copy_7:
  %t44 = mul i64 %t34, %t13
  %t45 = bitcast i8* %t32 to i8*
  call i8* @memcpy(i8* %t41, i8* %t45, i64 %t44)
  br label %list_cow_after_copy_8
list_cow_after_copy_8:
  %t46 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t39, i32 0, i32 0
  store i8* %t42, i8** %t46
  %t47 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t39, i32 0, i32 1
  store i64 %t34, i64* %t47
  %t48 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t39, i32 0, i32 2
  store i64 %t36, i64* %t48
  call void @star_rc_release(i8* %t14)
  store i8* %t38, i8** %t0
  br label %list_cow_done_5
list_cow_done_5:
  %t49 = load i8*, i8** %t0
  %t50 = bitcast i8* %t49 to { i8*, i64, i64 }*
  %t51 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t50, i32 0, i32 0
  %t52 = load i8*, i8** %t51
  %t53 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t50, i32 0, i32 1
  %t54 = load i64, i64* %t53
  %t55 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t50, i32 0, i32 2
  %t56 = trunc i32 72 to i8
  %t57 = load i64, i64* %t55
  %t58 = load i8*, i8** %t51
  %t59 = load i64, i64* %t53
  %t60 = icmp sge i64 %t59, %t57
  br i1 %t60, label %list_push_grow_9, label %list_push_store_10
list_push_grow_9:
  %t61 = mul i64 %t57, 2
  %t62 = icmp sgt i64 %t61, 0
  %t63 = select i1 %t62, i64 %t61, i64 1
  %t64 = getelementptr i8, i8* null, i32 1
  %t65 = ptrtoint i8* %t64 to i64
  %t66 = mul i64 %t63, %t65
  %t67 = call i8* @malloc(i64 %t66)
  %t68 = bitcast i8* %t67 to i8*
  %t69 = icmp sgt i64 %t57, 0
  br i1 %t69, label %list_push_copy_11, label %list_push_after_copy_12
list_push_copy_11:
  %t70 = mul i64 %t59, %t65
  %t71 = bitcast i8* %t58 to i8*
  call i8* @memcpy(i8* %t67, i8* %t71, i64 %t70)
  call void @free(i8* %t71)
  br label %list_push_after_copy_12
list_push_after_copy_12:
  store i8* %t68, i8** %t51
  store i64 %t63, i64* %t55
  br label %list_push_store_10
list_push_store_10:
  %t72 = load i8*, i8** %t51
  %t73 = getelementptr inbounds i8, i8* %t72, i64 %t59
  store i8 %t56, i8* %t73
  %t74 = add i64 %t59, 1
  store i64 %t74, i64* %t53
  %t75 = getelementptr i8, i8* null, i32 1
  %t76 = ptrtoint i8* %t75 to i64
  %t77 = load i8*, i8** %t0
  %t78 = icmp eq i8* %t77, null
  br i1 %t78, label %list_cow_alloc_13, label %list_cow_check_14
list_cow_alloc_13:
  %t79 = bitcast void (i8*)* @list_release_u8 to i8*
  %t80 = call i8* @star_rc_alloc(i64 24, i8* %t79)
  %t81 = bitcast i8* %t80 to { i8*, i64, i64 }*
  %t82 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t81, i32 0, i32 0
  store i8* null, i8** %t82
  %t83 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t81, i32 0, i32 1
  store i64 0, i64* %t83
  %t84 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t81, i32 0, i32 2
  store i64 0, i64* %t84
  store i8* %t80, i8** %t0
  br label %list_cow_done_15
list_cow_check_14:
  %t85 = getelementptr inbounds i8, i8* %t77, i64 -16
  %t86 = bitcast i8* %t85 to i64*
  %t87 = load atomic i64, i64* %t86 seq_cst, align 8
  %t88 = icmp eq i64 %t87, 1
  br i1 %t88, label %list_cow_done_15, label %list_cow_clone_16
list_cow_clone_16:
  %t89 = bitcast i8* %t77 to { i8*, i64, i64 }*
  %t90 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t89, i32 0, i32 0
  %t91 = load i8*, i8** %t90
  %t92 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t89, i32 0, i32 1
  %t93 = load i64, i64* %t92
  %t94 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t89, i32 0, i32 2
  %t95 = load i64, i64* %t94
  %t96 = bitcast void (i8*)* @list_release_u8 to i8*
  %t97 = call i8* @star_rc_alloc(i64 24, i8* %t96)
  %t98 = bitcast i8* %t97 to { i8*, i64, i64 }*
  %t99 = mul i64 %t95, %t76
  %t100 = call i8* @malloc(i64 %t99)
  %t101 = bitcast i8* %t100 to i8*
  %t102 = icmp sgt i64 %t93, 0
  br i1 %t102, label %list_cow_copy_17, label %list_cow_after_copy_18
list_cow_copy_17:
  %t103 = mul i64 %t93, %t76
  %t104 = bitcast i8* %t91 to i8*
  call i8* @memcpy(i8* %t100, i8* %t104, i64 %t103)
  br label %list_cow_after_copy_18
list_cow_after_copy_18:
  %t105 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t98, i32 0, i32 0
  store i8* %t101, i8** %t105
  %t106 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t98, i32 0, i32 1
  store i64 %t93, i64* %t106
  %t107 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t98, i32 0, i32 2
  store i64 %t95, i64* %t107
  call void @star_rc_release(i8* %t77)
  store i8* %t97, i8** %t0
  br label %list_cow_done_15
list_cow_done_15:
  %t108 = load i8*, i8** %t0
  %t109 = bitcast i8* %t108 to { i8*, i64, i64 }*
  %t110 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t109, i32 0, i32 0
  %t111 = load i8*, i8** %t110
  %t112 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t109, i32 0, i32 1
  %t113 = load i64, i64* %t112
  %t114 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t109, i32 0, i32 2
  %t115 = trunc i32 73 to i8
  %t116 = load i64, i64* %t114
  %t117 = load i8*, i8** %t110
  %t118 = load i64, i64* %t112
  %t119 = icmp sge i64 %t118, %t116
  br i1 %t119, label %list_push_grow_19, label %list_push_store_20
list_push_grow_19:
  %t120 = mul i64 %t116, 2
  %t121 = icmp sgt i64 %t120, 0
  %t122 = select i1 %t121, i64 %t120, i64 1
  %t123 = getelementptr i8, i8* null, i32 1
  %t124 = ptrtoint i8* %t123 to i64
  %t125 = mul i64 %t122, %t124
  %t126 = call i8* @malloc(i64 %t125)
  %t127 = bitcast i8* %t126 to i8*
  %t128 = icmp sgt i64 %t116, 0
  br i1 %t128, label %list_push_copy_21, label %list_push_after_copy_22
list_push_copy_21:
  %t129 = mul i64 %t118, %t124
  %t130 = bitcast i8* %t117 to i8*
  call i8* @memcpy(i8* %t126, i8* %t130, i64 %t129)
  call void @free(i8* %t130)
  br label %list_push_after_copy_22
list_push_after_copy_22:
  store i8* %t127, i8** %t110
  store i64 %t122, i64* %t114
  br label %list_push_store_20
list_push_store_20:
  %t131 = load i8*, i8** %t110
  %t132 = getelementptr inbounds i8, i8* %t131, i64 %t118
  store i8 %t115, i8* %t132
  %t133 = add i64 %t118, 1
  store i64 %t133, i64* %t112
  %t134 = getelementptr i8, i8* null, i32 1
  %t135 = ptrtoint i8* %t134 to i64
  %t136 = load i8*, i8** %t0
  %t137 = icmp eq i8* %t136, null
  br i1 %t137, label %list_cow_alloc_23, label %list_cow_check_24
list_cow_alloc_23:
  %t138 = bitcast void (i8*)* @list_release_u8 to i8*
  %t139 = call i8* @star_rc_alloc(i64 24, i8* %t138)
  %t140 = bitcast i8* %t139 to { i8*, i64, i64 }*
  %t141 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t140, i32 0, i32 0
  store i8* null, i8** %t141
  %t142 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t140, i32 0, i32 1
  store i64 0, i64* %t142
  %t143 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t140, i32 0, i32 2
  store i64 0, i64* %t143
  store i8* %t139, i8** %t0
  br label %list_cow_done_25
list_cow_check_24:
  %t144 = getelementptr inbounds i8, i8* %t136, i64 -16
  %t145 = bitcast i8* %t144 to i64*
  %t146 = load atomic i64, i64* %t145 seq_cst, align 8
  %t147 = icmp eq i64 %t146, 1
  br i1 %t147, label %list_cow_done_25, label %list_cow_clone_26
list_cow_clone_26:
  %t148 = bitcast i8* %t136 to { i8*, i64, i64 }*
  %t149 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t148, i32 0, i32 0
  %t150 = load i8*, i8** %t149
  %t151 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t148, i32 0, i32 1
  %t152 = load i64, i64* %t151
  %t153 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t148, i32 0, i32 2
  %t154 = load i64, i64* %t153
  %t155 = bitcast void (i8*)* @list_release_u8 to i8*
  %t156 = call i8* @star_rc_alloc(i64 24, i8* %t155)
  %t157 = bitcast i8* %t156 to { i8*, i64, i64 }*
  %t158 = mul i64 %t154, %t135
  %t159 = call i8* @malloc(i64 %t158)
  %t160 = bitcast i8* %t159 to i8*
  %t161 = icmp sgt i64 %t152, 0
  br i1 %t161, label %list_cow_copy_27, label %list_cow_after_copy_28
list_cow_copy_27:
  %t162 = mul i64 %t152, %t135
  %t163 = bitcast i8* %t150 to i8*
  call i8* @memcpy(i8* %t159, i8* %t163, i64 %t162)
  br label %list_cow_after_copy_28
list_cow_after_copy_28:
  %t164 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t157, i32 0, i32 0
  store i8* %t160, i8** %t164
  %t165 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t157, i32 0, i32 1
  store i64 %t152, i64* %t165
  %t166 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t157, i32 0, i32 2
  store i64 %t154, i64* %t166
  call void @star_rc_release(i8* %t136)
  store i8* %t156, i8** %t0
  br label %list_cow_done_25
list_cow_done_25:
  %t167 = load i8*, i8** %t0
  %t168 = bitcast i8* %t167 to { i8*, i64, i64 }*
  %t169 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t168, i32 0, i32 0
  %t170 = load i8*, i8** %t169
  %t171 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t168, i32 0, i32 1
  %t172 = load i64, i64* %t171
  %t173 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t168, i32 0, i32 2
  %t174 = trunc i32 33 to i8
  %t175 = load i64, i64* %t173
  %t176 = load i8*, i8** %t169
  %t177 = load i64, i64* %t171
  %t178 = icmp sge i64 %t177, %t175
  br i1 %t178, label %list_push_grow_29, label %list_push_store_30
list_push_grow_29:
  %t179 = mul i64 %t175, 2
  %t180 = icmp sgt i64 %t179, 0
  %t181 = select i1 %t180, i64 %t179, i64 1
  %t182 = getelementptr i8, i8* null, i32 1
  %t183 = ptrtoint i8* %t182 to i64
  %t184 = mul i64 %t181, %t183
  %t185 = call i8* @malloc(i64 %t184)
  %t186 = bitcast i8* %t185 to i8*
  %t187 = icmp sgt i64 %t175, 0
  br i1 %t187, label %list_push_copy_31, label %list_push_after_copy_32
list_push_copy_31:
  %t188 = mul i64 %t177, %t183
  %t189 = bitcast i8* %t176 to i8*
  call i8* @memcpy(i8* %t185, i8* %t189, i64 %t188)
  call void @free(i8* %t189)
  br label %list_push_after_copy_32
list_push_after_copy_32:
  store i8* %t186, i8** %t169
  store i64 %t181, i64* %t173
  br label %list_push_store_30
list_push_store_30:
  %t190 = load i8*, i8** %t169
  %t191 = getelementptr inbounds i8, i8* %t190, i64 %t177
  store i8 %t174, i8* %t191
  %t192 = add i64 %t177, 1
  store i64 %t192, i64* %t171
  %t193 = load i8*, i8** %t0
  %t194 = icmp eq i8* %t193, null
  br i1 %t194, label %list_read_null_33, label %list_read_real_34
list_read_null_33:
  br label %list_read_end_35
list_read_real_34:
  %t195 = bitcast i8* %t193 to { i8*, i64, i64 }*
  %t196 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t195, i32 0, i32 0
  %t197 = load i8*, i8** %t196
  %t198 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t195, i32 0, i32 1
  %t199 = load i64, i64* %t198
  br label %list_read_end_35
list_read_end_35:
  %t200 = phi i8* [ null, %list_read_null_33 ], [ %t197, %list_read_real_34 ]
  %t201 = phi i64 [ 0, %list_read_null_33 ], [ %t199, %list_read_real_34 ]
  %t202 = trunc i64 %t201 to i32
  %t203 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t203, i32 %t202)
  %t204 = load i8*, i8** %t0
  %t205 = icmp eq i8* %t204, null
  br i1 %t205, label %list_read_null_36, label %list_read_real_37
list_read_null_36:
  br label %list_read_end_38
list_read_real_37:
  %t206 = bitcast i8* %t204 to { i8*, i64, i64 }*
  %t207 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t206, i32 0, i32 0
  %t208 = load i8*, i8** %t207
  %t209 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t206, i32 0, i32 1
  %t210 = load i64, i64* %t209
  br label %list_read_end_38
list_read_end_38:
  %t211 = phi i8* [ null, %list_read_null_36 ], [ %t208, %list_read_real_37 ]
  %t212 = phi i64 [ 0, %list_read_null_36 ], [ %t210, %list_read_real_37 ]
  %t213 = sext i32 0 to i64
  %t214 = icmp ult i64 %t213, %t212
  br i1 %t214, label %list_idx_ok_39, label %list_idx_oob_40
list_idx_ok_39:
  %t215 = getelementptr inbounds i8, i8* %t211, i64 %t213
  %t216 = load i8, i8* %t215
  br label %list_idx_end_41
list_idx_oob_40:
  br label %list_idx_end_41
list_idx_end_41:
  %t217 = phi i8 [ %t216, %list_idx_ok_39 ], [ 0, %list_idx_oob_40 ]
  %t218 = load i8*, i8** %t0
  %t219 = icmp eq i8* %t218, null
  br i1 %t219, label %list_read_null_42, label %list_read_real_43
list_read_null_42:
  br label %list_read_end_44
list_read_real_43:
  %t220 = bitcast i8* %t218 to { i8*, i64, i64 }*
  %t221 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t220, i32 0, i32 0
  %t222 = load i8*, i8** %t221
  %t223 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t220, i32 0, i32 1
  %t224 = load i64, i64* %t223
  br label %list_read_end_44
list_read_end_44:
  %t225 = phi i8* [ null, %list_read_null_42 ], [ %t222, %list_read_real_43 ]
  %t226 = phi i64 [ 0, %list_read_null_42 ], [ %t224, %list_read_real_43 ]
  %t227 = sext i32 1 to i64
  %t228 = icmp ult i64 %t227, %t226
  br i1 %t228, label %list_idx_ok_45, label %list_idx_oob_46
list_idx_ok_45:
  %t229 = getelementptr inbounds i8, i8* %t225, i64 %t227
  %t230 = load i8, i8* %t229
  br label %list_idx_end_47
list_idx_oob_46:
  br label %list_idx_end_47
list_idx_end_47:
  %t231 = phi i8 [ %t230, %list_idx_ok_45 ], [ 0, %list_idx_oob_46 ]
  %t232 = load i8*, i8** %t0
  %t233 = icmp eq i8* %t232, null
  br i1 %t233, label %list_read_null_48, label %list_read_real_49
list_read_null_48:
  br label %list_read_end_50
list_read_real_49:
  %t234 = bitcast i8* %t232 to { i8*, i64, i64 }*
  %t235 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t234, i32 0, i32 0
  %t236 = load i8*, i8** %t235
  %t237 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t234, i32 0, i32 1
  %t238 = load i64, i64* %t237
  br label %list_read_end_50
list_read_end_50:
  %t239 = phi i8* [ null, %list_read_null_48 ], [ %t236, %list_read_real_49 ]
  %t240 = phi i64 [ 0, %list_read_null_48 ], [ %t238, %list_read_real_49 ]
  %t241 = sext i32 2 to i64
  %t242 = icmp ult i64 %t241, %t240
  br i1 %t242, label %list_idx_ok_51, label %list_idx_oob_52
list_idx_ok_51:
  %t243 = getelementptr inbounds i8, i8* %t239, i64 %t241
  %t244 = load i8, i8* %t243
  br label %list_idx_end_53
list_idx_oob_52:
  br label %list_idx_end_53
list_idx_end_53:
  %t245 = phi i8 [ %t244, %list_idx_ok_51 ], [ 0, %list_idx_oob_52 ]
  %t246 = getelementptr inbounds [39 x i8], [39 x i8]* @.str.2, i64 0, i64 0
  %t247 = zext i8 %t217 to i32
  %t248 = zext i8 %t231 to i32
  %t249 = zext i8 %t245 to i32
  call i32 (i8*, ...) @printf(i8* %t246, i32 %t247, i32 %t248, i32 %t249)
  %t250 = trunc i32 104 to i8
  %t251 = getelementptr i8, i8* null, i32 1
  %t252 = ptrtoint i8* %t251 to i64
  %t253 = load i8*, i8** %t0
  %t254 = icmp eq i8* %t253, null
  br i1 %t254, label %list_cow_alloc_54, label %list_cow_check_55
list_cow_alloc_54:
  %t255 = bitcast void (i8*)* @list_release_u8 to i8*
  %t256 = call i8* @star_rc_alloc(i64 24, i8* %t255)
  %t257 = bitcast i8* %t256 to { i8*, i64, i64 }*
  %t258 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t257, i32 0, i32 0
  store i8* null, i8** %t258
  %t259 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t257, i32 0, i32 1
  store i64 0, i64* %t259
  %t260 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t257, i32 0, i32 2
  store i64 0, i64* %t260
  store i8* %t256, i8** %t0
  br label %list_cow_done_56
list_cow_check_55:
  %t261 = getelementptr inbounds i8, i8* %t253, i64 -16
  %t262 = bitcast i8* %t261 to i64*
  %t263 = load atomic i64, i64* %t262 seq_cst, align 8
  %t264 = icmp eq i64 %t263, 1
  br i1 %t264, label %list_cow_done_56, label %list_cow_clone_57
list_cow_clone_57:
  %t265 = bitcast i8* %t253 to { i8*, i64, i64 }*
  %t266 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t265, i32 0, i32 0
  %t267 = load i8*, i8** %t266
  %t268 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t265, i32 0, i32 1
  %t269 = load i64, i64* %t268
  %t270 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t265, i32 0, i32 2
  %t271 = load i64, i64* %t270
  %t272 = bitcast void (i8*)* @list_release_u8 to i8*
  %t273 = call i8* @star_rc_alloc(i64 24, i8* %t272)
  %t274 = bitcast i8* %t273 to { i8*, i64, i64 }*
  %t275 = mul i64 %t271, %t252
  %t276 = call i8* @malloc(i64 %t275)
  %t277 = bitcast i8* %t276 to i8*
  %t278 = icmp sgt i64 %t269, 0
  br i1 %t278, label %list_cow_copy_58, label %list_cow_after_copy_59
list_cow_copy_58:
  %t279 = mul i64 %t269, %t252
  %t280 = bitcast i8* %t267 to i8*
  call i8* @memcpy(i8* %t276, i8* %t280, i64 %t279)
  br label %list_cow_after_copy_59
list_cow_after_copy_59:
  %t281 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t274, i32 0, i32 0
  store i8* %t277, i8** %t281
  %t282 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t274, i32 0, i32 1
  store i64 %t269, i64* %t282
  %t283 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t274, i32 0, i32 2
  store i64 %t271, i64* %t283
  call void @star_rc_release(i8* %t253)
  store i8* %t273, i8** %t0
  br label %list_cow_done_56
list_cow_done_56:
  %t284 = load i8*, i8** %t0
  %t285 = bitcast i8* %t284 to { i8*, i64, i64 }*
  %t286 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t285, i32 0, i32 0
  %t287 = load i8*, i8** %t286
  %t288 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t285, i32 0, i32 1
  %t289 = load i64, i64* %t288
  %t290 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t285, i32 0, i32 2
  %t291 = sext i32 0 to i64
  %t292 = icmp ult i64 %t291, %t289
  br i1 %t292, label %list_set_do_60, label %list_set_oob_61
list_set_do_60:
  %t293 = getelementptr inbounds i8, i8* %t287, i64 %t291
  store i8 %t250, i8* %t293
  br label %list_set_end_62
list_set_oob_61:
  br label %list_set_end_62
list_set_end_62:
  %t294 = load i8*, i8** %t0
  %t295 = icmp eq i8* %t294, null
  br i1 %t295, label %list_read_null_63, label %list_read_real_64
list_read_null_63:
  br label %list_read_end_65
list_read_real_64:
  %t296 = bitcast i8* %t294 to { i8*, i64, i64 }*
  %t297 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t296, i32 0, i32 0
  %t298 = load i8*, i8** %t297
  %t299 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t296, i32 0, i32 1
  %t300 = load i64, i64* %t299
  br label %list_read_end_65
list_read_end_65:
  %t301 = phi i8* [ null, %list_read_null_63 ], [ %t298, %list_read_real_64 ]
  %t302 = phi i64 [ 0, %list_read_null_63 ], [ %t300, %list_read_real_64 ]
  %t303 = sext i32 0 to i64
  %t304 = icmp ult i64 %t303, %t302
  br i1 %t304, label %list_idx_ok_66, label %list_idx_oob_67
list_idx_ok_66:
  %t305 = getelementptr inbounds i8, i8* %t301, i64 %t303
  %t306 = load i8, i8* %t305
  br label %list_idx_end_68
list_idx_oob_67:
  br label %list_idx_end_68
list_idx_end_68:
  %t307 = phi i8 [ %t306, %list_idx_ok_66 ], [ 0, %list_idx_oob_67 ]
  %t308 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.3, i64 0, i64 0
  %t309 = zext i8 %t307 to i32
  call i32 (i8*, ...) @printf(i8* %t308, i32 %t309)
  %t311 = getelementptr i8, i8* null, i32 1
  %t312 = ptrtoint i8* %t311 to i64
  %t313 = load i8*, i8** %t0
  %t314 = icmp eq i8* %t313, null
  br i1 %t314, label %list_cow_alloc_69, label %list_cow_check_70
list_cow_alloc_69:
  %t315 = bitcast void (i8*)* @list_release_u8 to i8*
  %t316 = call i8* @star_rc_alloc(i64 24, i8* %t315)
  %t317 = bitcast i8* %t316 to { i8*, i64, i64 }*
  %t318 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t317, i32 0, i32 0
  store i8* null, i8** %t318
  %t319 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t317, i32 0, i32 1
  store i64 0, i64* %t319
  %t320 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t317, i32 0, i32 2
  store i64 0, i64* %t320
  store i8* %t316, i8** %t0
  br label %list_cow_done_71
list_cow_check_70:
  %t321 = getelementptr inbounds i8, i8* %t313, i64 -16
  %t322 = bitcast i8* %t321 to i64*
  %t323 = load atomic i64, i64* %t322 seq_cst, align 8
  %t324 = icmp eq i64 %t323, 1
  br i1 %t324, label %list_cow_done_71, label %list_cow_clone_72
list_cow_clone_72:
  %t325 = bitcast i8* %t313 to { i8*, i64, i64 }*
  %t326 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t325, i32 0, i32 0
  %t327 = load i8*, i8** %t326
  %t328 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t325, i32 0, i32 1
  %t329 = load i64, i64* %t328
  %t330 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t325, i32 0, i32 2
  %t331 = load i64, i64* %t330
  %t332 = bitcast void (i8*)* @list_release_u8 to i8*
  %t333 = call i8* @star_rc_alloc(i64 24, i8* %t332)
  %t334 = bitcast i8* %t333 to { i8*, i64, i64 }*
  %t335 = mul i64 %t331, %t312
  %t336 = call i8* @malloc(i64 %t335)
  %t337 = bitcast i8* %t336 to i8*
  %t338 = icmp sgt i64 %t329, 0
  br i1 %t338, label %list_cow_copy_73, label %list_cow_after_copy_74
list_cow_copy_73:
  %t339 = mul i64 %t329, %t312
  %t340 = bitcast i8* %t327 to i8*
  call i8* @memcpy(i8* %t336, i8* %t340, i64 %t339)
  br label %list_cow_after_copy_74
list_cow_after_copy_74:
  %t341 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t334, i32 0, i32 0
  store i8* %t337, i8** %t341
  %t342 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t334, i32 0, i32 1
  store i64 %t329, i64* %t342
  %t343 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t334, i32 0, i32 2
  store i64 %t331, i64* %t343
  call void @star_rc_release(i8* %t313)
  store i8* %t333, i8** %t0
  br label %list_cow_done_71
list_cow_done_71:
  %t344 = load i8*, i8** %t0
  %t345 = bitcast i8* %t344 to { i8*, i64, i64 }*
  %t346 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t345, i32 0, i32 0
  %t347 = load i8*, i8** %t346
  %t348 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t345, i32 0, i32 1
  %t349 = load i64, i64* %t348
  %t350 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t345, i32 0, i32 2
  %t351 = icmp eq i64 %t349, 0
  br i1 %t351, label %list_pop_empty_75, label %list_pop_nonempty_76
list_pop_nonempty_76:
  %t352 = sub i64 %t349, 1
  store i64 %t352, i64* %t348
  %t353 = load i8*, i8** %t346
  %t354 = getelementptr inbounds i8, i8* %t353, i64 %t352
  %t355 = load i8, i8* %t354
  br label %list_pop_end_77
list_pop_empty_75:
  br label %list_pop_end_77
list_pop_end_77:
  %t356 = phi i8 [ %t355, %list_pop_nonempty_76 ], [ 0, %list_pop_empty_75 ]
  store i8 %t356, i8* %t310
  %t357 = load i8, i8* %t310
  %t358 = load i8*, i8** %t0
  %t359 = icmp eq i8* %t358, null
  br i1 %t359, label %list_read_null_78, label %list_read_real_79
list_read_null_78:
  br label %list_read_end_80
list_read_real_79:
  %t360 = bitcast i8* %t358 to { i8*, i64, i64 }*
  %t361 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t360, i32 0, i32 0
  %t362 = load i8*, i8** %t361
  %t363 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t360, i32 0, i32 1
  %t364 = load i64, i64* %t363
  br label %list_read_end_80
list_read_end_80:
  %t365 = phi i8* [ null, %list_read_null_78 ], [ %t362, %list_read_real_79 ]
  %t366 = phi i64 [ 0, %list_read_null_78 ], [ %t364, %list_read_real_79 ]
  %t367 = trunc i64 %t366 to i32
  %t368 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.4, i64 0, i64 0
  %t369 = zext i8 %t357 to i32
  call i32 (i8*, ...) @printf(i8* %t368, i32 %t369, i32 %t367)
  store i8* null, i8** %t370
  %t371 = getelementptr i8, i8* null, i32 1
  %t372 = ptrtoint i8* %t371 to i64
  %t373 = load i8*, i8** %t370
  %t374 = icmp eq i8* %t373, null
  br i1 %t374, label %list_cow_alloc_81, label %list_cow_check_82
list_cow_alloc_81:
  %t375 = bitcast void (i8*)* @list_release_u8 to i8*
  %t376 = call i8* @star_rc_alloc(i64 24, i8* %t375)
  %t377 = bitcast i8* %t376 to { i8*, i64, i64 }*
  %t378 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t377, i32 0, i32 0
  store i8* null, i8** %t378
  %t379 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t377, i32 0, i32 1
  store i64 0, i64* %t379
  %t380 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t377, i32 0, i32 2
  store i64 0, i64* %t380
  store i8* %t376, i8** %t370
  br label %list_cow_done_83
list_cow_check_82:
  %t381 = getelementptr inbounds i8, i8* %t373, i64 -16
  %t382 = bitcast i8* %t381 to i64*
  %t383 = load atomic i64, i64* %t382 seq_cst, align 8
  %t384 = icmp eq i64 %t383, 1
  br i1 %t384, label %list_cow_done_83, label %list_cow_clone_84
list_cow_clone_84:
  %t385 = bitcast i8* %t373 to { i8*, i64, i64 }*
  %t386 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t385, i32 0, i32 0
  %t387 = load i8*, i8** %t386
  %t388 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t385, i32 0, i32 1
  %t389 = load i64, i64* %t388
  %t390 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t385, i32 0, i32 2
  %t391 = load i64, i64* %t390
  %t392 = bitcast void (i8*)* @list_release_u8 to i8*
  %t393 = call i8* @star_rc_alloc(i64 24, i8* %t392)
  %t394 = bitcast i8* %t393 to { i8*, i64, i64 }*
  %t395 = mul i64 %t391, %t372
  %t396 = call i8* @malloc(i64 %t395)
  %t397 = bitcast i8* %t396 to i8*
  %t398 = icmp sgt i64 %t389, 0
  br i1 %t398, label %list_cow_copy_85, label %list_cow_after_copy_86
list_cow_copy_85:
  %t399 = mul i64 %t389, %t372
  %t400 = bitcast i8* %t387 to i8*
  call i8* @memcpy(i8* %t396, i8* %t400, i64 %t399)
  br label %list_cow_after_copy_86
list_cow_after_copy_86:
  %t401 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t394, i32 0, i32 0
  store i8* %t397, i8** %t401
  %t402 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t394, i32 0, i32 1
  store i64 %t389, i64* %t402
  %t403 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t394, i32 0, i32 2
  store i64 %t391, i64* %t403
  call void @star_rc_release(i8* %t373)
  store i8* %t393, i8** %t370
  br label %list_cow_done_83
list_cow_done_83:
  %t404 = load i8*, i8** %t370
  %t405 = bitcast i8* %t404 to { i8*, i64, i64 }*
  %t406 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t405, i32 0, i32 0
  %t407 = load i8*, i8** %t406
  %t408 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t405, i32 0, i32 1
  %t409 = load i64, i64* %t408
  %t410 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t405, i32 0, i32 2
  %t411 = icmp eq i64 %t409, 0
  br i1 %t411, label %list_pop_empty_87, label %list_pop_nonempty_88
list_pop_nonempty_88:
  %t412 = sub i64 %t409, 1
  store i64 %t412, i64* %t408
  %t413 = load i8*, i8** %t406
  %t414 = getelementptr inbounds i8, i8* %t413, i64 %t412
  %t415 = load i8, i8* %t414
  br label %list_pop_end_89
list_pop_empty_87:
  br label %list_pop_end_89
list_pop_end_89:
  %t416 = phi i8 [ %t415, %list_pop_nonempty_88 ], [ 0, %list_pop_empty_87 ]
  %t417 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.5, i64 0, i64 0
  %t418 = zext i8 %t416 to i32
  call i32 (i8*, ...) @printf(i8* %t417, i32 %t418)
  %t419 = load i8*, i8** %t370
  %t420 = icmp eq i8* %t419, null
  br i1 %t420, label %list_read_null_90, label %list_read_real_91
list_read_null_90:
  br label %list_read_end_92
list_read_real_91:
  %t421 = bitcast i8* %t419 to { i8*, i64, i64 }*
  %t422 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t421, i32 0, i32 0
  %t423 = load i8*, i8** %t422
  %t424 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t421, i32 0, i32 1
  %t425 = load i64, i64* %t424
  br label %list_read_end_92
list_read_end_92:
  %t426 = phi i8* [ null, %list_read_null_90 ], [ %t423, %list_read_real_91 ]
  %t427 = phi i64 [ 0, %list_read_null_90 ], [ %t425, %list_read_real_91 ]
  %t428 = sext i32 0 to i64
  %t429 = icmp ult i64 %t428, %t427
  br i1 %t429, label %list_idx_ok_93, label %list_idx_oob_94
list_idx_ok_93:
  %t430 = getelementptr inbounds i8, i8* %t426, i64 %t428
  %t431 = load i8, i8* %t430
  br label %list_idx_end_95
list_idx_oob_94:
  br label %list_idx_end_95
list_idx_end_95:
  %t432 = phi i8 [ %t431, %list_idx_ok_93 ], [ 0, %list_idx_oob_94 ]
  %t433 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.6, i64 0, i64 0
  %t434 = zext i8 %t432 to i32
  call i32 (i8*, ...) @printf(i8* %t433, i32 %t434)
  %t436 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t437 = call i32 @strlen(i8* %t436)
  %t438 = sext i32 %t437 to i64
  %t439 = call i8* @malloc(i64 %t438)
  call i8* @memcpy(i8* %t439, i8* %t436, i64 %t438)
  call void @star_rc_release(i8* %t436)
  %t440 = bitcast void (i8*)* @list_release_u8 to i8*
  %t441 = call i8* @star_rc_alloc(i64 24, i8* %t440)
  %t442 = bitcast i8* %t441 to { i8*, i64, i64 }*
  %t443 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t442, i32 0, i32 0
  store i8* %t439, i8** %t443
  %t444 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t442, i32 0, i32 1
  store i64 %t438, i64* %t444
  %t445 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t442, i32 0, i32 2
  store i64 %t438, i64* %t445
  store i8* %t441, i8** %t435
  %t446 = load i8*, i8** %t435
  %t447 = icmp eq i8* %t446, null
  br i1 %t447, label %list_read_null_96, label %list_read_real_97
list_read_null_96:
  br label %list_read_end_98
list_read_real_97:
  %t448 = bitcast i8* %t446 to { i8*, i64, i64 }*
  %t449 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t448, i32 0, i32 0
  %t450 = load i8*, i8** %t449
  %t451 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t448, i32 0, i32 1
  %t452 = load i64, i64* %t451
  br label %list_read_end_98
list_read_end_98:
  %t453 = phi i8* [ null, %list_read_null_96 ], [ %t450, %list_read_real_97 ]
  %t454 = phi i64 [ 0, %list_read_null_96 ], [ %t452, %list_read_real_97 ]
  %t455 = trunc i64 %t454 to i32
  %t456 = getelementptr inbounds [36 x i8], [36 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t456, i32 %t455)
  %t457 = load i8*, i8** %t435
  %t458 = icmp eq i8* %t457, null
  br i1 %t458, label %list_read_null_99, label %list_read_real_100
list_read_null_99:
  br label %list_read_end_101
list_read_real_100:
  %t459 = bitcast i8* %t457 to { i8*, i64, i64 }*
  %t460 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t459, i32 0, i32 0
  %t461 = load i8*, i8** %t460
  %t462 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t459, i32 0, i32 1
  %t463 = load i64, i64* %t462
  br label %list_read_end_101
list_read_end_101:
  %t464 = phi i8* [ null, %list_read_null_99 ], [ %t461, %list_read_real_100 ]
  %t465 = phi i64 [ 0, %list_read_null_99 ], [ %t463, %list_read_real_100 ]
  %t466 = sext i32 0 to i64
  %t467 = icmp ult i64 %t466, %t465
  br i1 %t467, label %list_idx_ok_102, label %list_idx_oob_103
list_idx_ok_102:
  %t468 = getelementptr inbounds i8, i8* %t464, i64 %t466
  %t469 = load i8, i8* %t468
  br label %list_idx_end_104
list_idx_oob_103:
  br label %list_idx_end_104
list_idx_end_104:
  %t470 = phi i8 [ %t469, %list_idx_ok_102 ], [ 0, %list_idx_oob_103 ]
  %t471 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.9, i64 0, i64 0
  %t472 = zext i8 %t470 to i32
  call i32 (i8*, ...) @printf(i8* %t471, i32 %t472)
  %t474 = load i8*, i8** %t435
  %t475 = icmp eq i8* %t474, null
  br i1 %t475, label %list_read_null_105, label %list_read_real_106
list_read_null_105:
  br label %list_read_end_107
list_read_real_106:
  %t476 = bitcast i8* %t474 to { i8*, i64, i64 }*
  %t477 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t476, i32 0, i32 0
  %t478 = load i8*, i8** %t477
  %t479 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t476, i32 0, i32 1
  %t480 = load i64, i64* %t479
  br label %list_read_end_107
list_read_end_107:
  %t481 = phi i8* [ null, %list_read_null_105 ], [ %t478, %list_read_real_106 ]
  %t482 = phi i64 [ 0, %list_read_null_105 ], [ %t480, %list_read_real_106 ]
  %t483 = add i64 %t482, 1
  %t484 = call i8* @star_rc_alloc(i64 %t483, i8* null)
  call i8* @memcpy(i8* %t484, i8* %t481, i64 %t482)
  %t485 = getelementptr inbounds i8, i8* %t484, i64 %t482
  store i8 0, i8* %t485
  store i8* %t484, i8** %t473
  %t486 = load i8*, i8** %t473
  %t487 = load i8*, i8** %t473
  call void @star_rc_retain(i8* %t487)
  call void @star_rc_release(i8* %t486)
  %t488 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t488, i8* %t486)
  %t490 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t491 = call i32 @strlen(i8* %t490)
  %t492 = sext i32 %t491 to i64
  %t493 = call i8* @malloc(i64 %t492)
  call i8* @memcpy(i8* %t493, i8* %t490, i64 %t492)
  call void @star_rc_release(i8* %t490)
  %t494 = bitcast void (i8*)* @list_release_u8 to i8*
  %t495 = call i8* @star_rc_alloc(i64 24, i8* %t494)
  %t496 = bitcast i8* %t495 to { i8*, i64, i64 }*
  %t497 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t496, i32 0, i32 0
  store i8* %t493, i8** %t497
  %t498 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t496, i32 0, i32 1
  store i64 %t492, i64* %t498
  %t499 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t496, i32 0, i32 2
  store i64 %t492, i64* %t499
  store i8* %t495, i8** %t489
  %t501 = load i8*, i8** %t489
  %t502 = load i8*, i8** %t489
  call void @star_rc_retain(i8* %t502)
  store i8* %t501, i8** %t500
  %t503 = getelementptr i8, i8* null, i32 1
  %t504 = ptrtoint i8* %t503 to i64
  %t505 = load i8*, i8** %t489
  %t506 = icmp eq i8* %t505, null
  br i1 %t506, label %list_cow_alloc_108, label %list_cow_check_109
list_cow_alloc_108:
  %t507 = bitcast void (i8*)* @list_release_u8 to i8*
  %t508 = call i8* @star_rc_alloc(i64 24, i8* %t507)
  %t509 = bitcast i8* %t508 to { i8*, i64, i64 }*
  %t510 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t509, i32 0, i32 0
  store i8* null, i8** %t510
  %t511 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t509, i32 0, i32 1
  store i64 0, i64* %t511
  %t512 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t509, i32 0, i32 2
  store i64 0, i64* %t512
  store i8* %t508, i8** %t489
  br label %list_cow_done_110
list_cow_check_109:
  %t513 = getelementptr inbounds i8, i8* %t505, i64 -16
  %t514 = bitcast i8* %t513 to i64*
  %t515 = load atomic i64, i64* %t514 seq_cst, align 8
  %t516 = icmp eq i64 %t515, 1
  br i1 %t516, label %list_cow_done_110, label %list_cow_clone_111
list_cow_clone_111:
  %t517 = bitcast i8* %t505 to { i8*, i64, i64 }*
  %t518 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t517, i32 0, i32 0
  %t519 = load i8*, i8** %t518
  %t520 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t517, i32 0, i32 1
  %t521 = load i64, i64* %t520
  %t522 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t517, i32 0, i32 2
  %t523 = load i64, i64* %t522
  %t524 = bitcast void (i8*)* @list_release_u8 to i8*
  %t525 = call i8* @star_rc_alloc(i64 24, i8* %t524)
  %t526 = bitcast i8* %t525 to { i8*, i64, i64 }*
  %t527 = mul i64 %t523, %t504
  %t528 = call i8* @malloc(i64 %t527)
  %t529 = bitcast i8* %t528 to i8*
  %t530 = icmp sgt i64 %t521, 0
  br i1 %t530, label %list_cow_copy_112, label %list_cow_after_copy_113
list_cow_copy_112:
  %t531 = mul i64 %t521, %t504
  %t532 = bitcast i8* %t519 to i8*
  call i8* @memcpy(i8* %t528, i8* %t532, i64 %t531)
  br label %list_cow_after_copy_113
list_cow_after_copy_113:
  %t533 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t526, i32 0, i32 0
  store i8* %t529, i8** %t533
  %t534 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t526, i32 0, i32 1
  store i64 %t521, i64* %t534
  %t535 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t526, i32 0, i32 2
  store i64 %t523, i64* %t535
  call void @star_rc_release(i8* %t505)
  store i8* %t525, i8** %t489
  br label %list_cow_done_110
list_cow_done_110:
  %t536 = load i8*, i8** %t489
  %t537 = bitcast i8* %t536 to { i8*, i64, i64 }*
  %t538 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t537, i32 0, i32 0
  %t539 = load i8*, i8** %t538
  %t540 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t537, i32 0, i32 1
  %t541 = load i64, i64* %t540
  %t542 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t537, i32 0, i32 2
  %t543 = trunc i32 99 to i8
  %t544 = load i64, i64* %t542
  %t545 = load i8*, i8** %t538
  %t546 = load i64, i64* %t540
  %t547 = icmp sge i64 %t546, %t544
  br i1 %t547, label %list_push_grow_114, label %list_push_store_115
list_push_grow_114:
  %t548 = mul i64 %t544, 2
  %t549 = icmp sgt i64 %t548, 0
  %t550 = select i1 %t549, i64 %t548, i64 1
  %t551 = getelementptr i8, i8* null, i32 1
  %t552 = ptrtoint i8* %t551 to i64
  %t553 = mul i64 %t550, %t552
  %t554 = call i8* @malloc(i64 %t553)
  %t555 = bitcast i8* %t554 to i8*
  %t556 = icmp sgt i64 %t544, 0
  br i1 %t556, label %list_push_copy_116, label %list_push_after_copy_117
list_push_copy_116:
  %t557 = mul i64 %t546, %t552
  %t558 = bitcast i8* %t545 to i8*
  call i8* @memcpy(i8* %t554, i8* %t558, i64 %t557)
  call void @free(i8* %t558)
  br label %list_push_after_copy_117
list_push_after_copy_117:
  store i8* %t555, i8** %t538
  store i64 %t550, i64* %t542
  br label %list_push_store_115
list_push_store_115:
  %t559 = load i8*, i8** %t538
  %t560 = getelementptr inbounds i8, i8* %t559, i64 %t546
  store i8 %t543, i8* %t560
  %t561 = add i64 %t546, 1
  store i64 %t561, i64* %t540
  %t562 = load i8*, i8** %t489
  %t563 = icmp eq i8* %t562, null
  br i1 %t563, label %list_read_null_118, label %list_read_real_119
list_read_null_118:
  br label %list_read_end_120
list_read_real_119:
  %t564 = bitcast i8* %t562 to { i8*, i64, i64 }*
  %t565 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t564, i32 0, i32 0
  %t566 = load i8*, i8** %t565
  %t567 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t564, i32 0, i32 1
  %t568 = load i64, i64* %t567
  br label %list_read_end_120
list_read_end_120:
  %t569 = phi i8* [ null, %list_read_null_118 ], [ %t566, %list_read_real_119 ]
  %t570 = phi i64 [ 0, %list_read_null_118 ], [ %t568, %list_read_real_119 ]
  %t571 = trunc i64 %t570 to i32
  %t572 = load i8*, i8** %t500
  %t573 = icmp eq i8* %t572, null
  br i1 %t573, label %list_read_null_121, label %list_read_real_122
list_read_null_121:
  br label %list_read_end_123
list_read_real_122:
  %t574 = bitcast i8* %t572 to { i8*, i64, i64 }*
  %t575 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t574, i32 0, i32 0
  %t576 = load i8*, i8** %t575
  %t577 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t574, i32 0, i32 1
  %t578 = load i64, i64* %t577
  br label %list_read_end_123
list_read_end_123:
  %t579 = phi i8* [ null, %list_read_null_121 ], [ %t576, %list_read_real_122 ]
  %t580 = phi i64 [ 0, %list_read_null_121 ], [ %t578, %list_read_real_122 ]
  %t581 = trunc i64 %t580 to i32
  %t582 = getelementptr inbounds [28 x i8], [28 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t582, i32 %t571, i32 %t581)
  %t584 = getelementptr inbounds { i64, i8*, [1 x i8] }, { i64, i8*, [1 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t585 = call i32 @strlen(i8* %t584)
  %t586 = sext i32 %t585 to i64
  %t587 = call i8* @malloc(i64 %t586)
  call i8* @memcpy(i8* %t587, i8* %t584, i64 %t586)
  call void @star_rc_release(i8* %t584)
  %t588 = bitcast void (i8*)* @list_release_u8 to i8*
  %t589 = call i8* @star_rc_alloc(i64 24, i8* %t588)
  %t590 = bitcast i8* %t589 to { i8*, i64, i64 }*
  %t591 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t590, i32 0, i32 0
  store i8* %t587, i8** %t591
  %t592 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t590, i32 0, i32 1
  store i64 %t586, i64* %t592
  %t593 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t590, i32 0, i32 2
  store i64 %t586, i64* %t593
  store i8* %t589, i8** %t583
  %t594 = load i8*, i8** %t583
  %t595 = icmp eq i8* %t594, null
  br i1 %t595, label %list_read_null_124, label %list_read_real_125
list_read_null_124:
  br label %list_read_end_126
list_read_real_125:
  %t596 = bitcast i8* %t594 to { i8*, i64, i64 }*
  %t597 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t596, i32 0, i32 0
  %t598 = load i8*, i8** %t597
  %t599 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t596, i32 0, i32 1
  %t600 = load i64, i64* %t599
  br label %list_read_end_126
list_read_end_126:
  %t601 = phi i8* [ null, %list_read_null_124 ], [ %t598, %list_read_real_125 ]
  %t602 = phi i64 [ 0, %list_read_null_124 ], [ %t600, %list_read_real_125 ]
  %t603 = trunc i64 %t602 to i32
  %t604 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t604, i32 %t603)
  %t605 = load i8*, i8** %t583
  %t606 = icmp eq i8* %t605, null
  br i1 %t606, label %list_read_null_127, label %list_read_real_128
list_read_null_127:
  br label %list_read_end_129
list_read_real_128:
  %t607 = bitcast i8* %t605 to { i8*, i64, i64 }*
  %t608 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t607, i32 0, i32 0
  %t609 = load i8*, i8** %t608
  %t610 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t607, i32 0, i32 1
  %t611 = load i64, i64* %t610
  br label %list_read_end_129
list_read_end_129:
  %t612 = phi i8* [ null, %list_read_null_127 ], [ %t609, %list_read_real_128 ]
  %t613 = phi i64 [ 0, %list_read_null_127 ], [ %t611, %list_read_real_128 ]
  %t614 = add i64 %t613, 1
  %t615 = call i8* @star_rc_alloc(i64 %t614, i8* null)
  call i8* @memcpy(i8* %t615, i8* %t612, i64 %t613)
  %t616 = getelementptr inbounds i8, i8* %t615, i64 %t613
  store i8 0, i8* %t616
  call void @star_rc_release(i8* %t615)
  %t617 = getelementptr inbounds [30 x i8], [30 x i8]* @.str.15, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t617, i8* %t615)
  %t618 = load i8*, i8** %t583
  call void @star_rc_release(i8* %t618)
  %t619 = load i8*, i8** %t500
  call void @star_rc_release(i8* %t619)
  %t620 = load i8*, i8** %t489
  call void @star_rc_release(i8* %t620)
  %t621 = load i8*, i8** %t473
  call void @star_rc_release(i8* %t621)
  %t622 = load i8*, i8** %t435
  call void @star_rc_release(i8* %t622)
  %t623 = load i8*, i8** %t370
  call void @star_rc_release(i8* %t623)
  %t624 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t624)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_u8(i8* %objp) {
entry:
  %t16 = bitcast i8* %objp to { i8*, i64, i64 }*
  %t17 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t16, i32 0, i32 0
  %t18 = load i8*, i8** %t17
  %t19 = bitcast i8* %t18 to i8*
  call void @free(i8* %t19)
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
