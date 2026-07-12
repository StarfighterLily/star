; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
declare i32 @puts(i8*)
declare noalias i8* @malloc(i64)
declare void @free(i8*)
declare void @exit(i32) noreturn
declare i32 @strlen(i8*)
declare i32 @getchar()
declare i8* @memcpy(i8*, i8*, i64)
declare i8* @strcpy(i8*, i8*)
declare i8* @strcat(i8*, i8*)
declare i8* @fopen(i8*, i8*)
declare i32 @fclose(i8*)
declare i64 @fread(i8*, i64, i64, i8*)
declare i64 @fwrite(i8*, i64, i64, i8*)
declare i32 @fseek(i8*, i32, i32)
declare i32 @ftell(i8*)
declare i32 @fgetc(i8*)
declare i8* @getenv(i8*)
declare i32 @_putenv(i8*)
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

%Point = type { i32, i32 }
define i32 @sum_list(i8* %nums) {
entry:
  %t0 = alloca i8*
  store i8* %nums, i8** %t0
  %t1 = alloca i32
  store i32 0, i32* %t1
  %t2 = alloca i32
  store i32 0, i32* %t2
  br label %while_cond_0
while_cond_0:
  %t3 = load i32, i32* %t2
  %t4 = load i8*, i8** %t0
  %t5 = icmp eq i8* %t4, null
  br i1 %t5, label %list_read_null_4, label %list_read_real_5
list_read_null_4:
  br label %list_read_end_6
list_read_real_5:
  %t6 = bitcast i8* %t4 to { i32*, i64, i64 }*
  %t7 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t6, i32 0, i32 0
  %t8 = load i32*, i32** %t7
  %t9 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t6, i32 0, i32 1
  %t10 = load i64, i64* %t9
  br label %list_read_end_6
list_read_end_6:
  %t11 = phi i32* [ null, %list_read_null_4 ], [ %t8, %list_read_real_5 ]
  %t12 = phi i64 [ 0, %list_read_null_4 ], [ %t10, %list_read_real_5 ]
  %t13 = trunc i64 %t12 to i32
  %t14 = icmp slt i32 %t3, %t13
  br i1 %t14, label %while_body_1, label %while_end_3
while_body_1:
  %t15 = load i8*, i8** %t0
  %t16 = icmp eq i8* %t15, null
  br i1 %t16, label %list_read_null_7, label %list_read_real_8
list_read_null_7:
  br label %list_read_end_9
list_read_real_8:
  %t17 = bitcast i8* %t15 to { i32*, i64, i64 }*
  %t18 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t17, i32 0, i32 0
  %t19 = load i32*, i32** %t18
  %t20 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t17, i32 0, i32 1
  %t21 = load i64, i64* %t20
  br label %list_read_end_9
list_read_end_9:
  %t22 = phi i32* [ null, %list_read_null_7 ], [ %t19, %list_read_real_8 ]
  %t23 = phi i64 [ 0, %list_read_null_7 ], [ %t21, %list_read_real_8 ]
  %t24 = load i32, i32* %t2
  %t25 = sext i32 %t24 to i64
  %t26 = icmp ult i64 %t25, %t23
  br i1 %t26, label %list_idx_ok_10, label %list_idx_oob_11
list_idx_ok_10:
  %t27 = getelementptr inbounds i32, i32* %t22, i64 %t25
  %t28 = load i32, i32* %t27
  br label %list_idx_end_12
list_idx_oob_11:
  br label %list_idx_end_12
list_idx_end_12:
  %t29 = phi i32 [ %t28, %list_idx_ok_10 ], [ 0, %list_idx_oob_11 ]
  %t30 = load i32, i32* %t1
  %t31 = add i32 %t30, %t29
  store i32 %t31, i32* %t1
  %t32 = load i32, i32* %t2
  %t33 = add i32 %t32, 1
  store i32 %t33, i32* %t2
  br label %while_cond_0
while_else_2:
  br label %while_end_3
while_end_3:
  %t34 = load i32, i32* %t1
  %t35 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t35)
  ret i32 %t34
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = alloca i8*
  %t1 = call i8* @malloc(i64 12)
  %t2 = bitcast i8* %t1 to i32*
  %t3 = getelementptr inbounds i32, i32* %t2, i64 0
  store i32 1, i32* %t3
  %t4 = getelementptr inbounds i32, i32* %t2, i64 1
  store i32 2, i32* %t4
  %t5 = getelementptr inbounds i32, i32* %t2, i64 2
  store i32 3, i32* %t5
  %t10 = bitcast void (i8*)* @list_release_i32 to i8*
  %t11 = call i8* @star_rc_alloc(i64 24, i8* %t10)
  %t12 = bitcast i8* %t11 to { i32*, i64, i64 }*
  %t13 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t12, i32 0, i32 0
  store i32* %t2, i32** %t13
  %t14 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t12, i32 0, i32 1
  store i64 3, i64* %t14
  %t15 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t12, i32 0, i32 2
  store i64 3, i64* %t15
  store i8* %t11, i8** %t0
  %t16 = load i8*, i8** %t0
  %t17 = icmp eq i8* %t16, null
  br i1 %t17, label %list_read_null_13, label %list_read_real_14
list_read_null_13:
  br label %list_read_end_15
list_read_real_14:
  %t18 = bitcast i8* %t16 to { i32*, i64, i64 }*
  %t19 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t18, i32 0, i32 0
  %t20 = load i32*, i32** %t19
  %t21 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t18, i32 0, i32 1
  %t22 = load i64, i64* %t21
  br label %list_read_end_15
list_read_end_15:
  %t23 = phi i32* [ null, %list_read_null_13 ], [ %t20, %list_read_real_14 ]
  %t24 = phi i64 [ 0, %list_read_null_13 ], [ %t22, %list_read_real_14 ]
  %t25 = trunc i64 %t24 to i32
  %t26 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t26, i32 %t25)
  %t27 = load i8*, i8** %t0
  %t28 = icmp eq i8* %t27, null
  br i1 %t28, label %list_cow_alloc_16, label %list_cow_check_17
list_cow_alloc_16:
  %t29 = bitcast void (i8*)* @list_release_i32 to i8*
  %t30 = call i8* @star_rc_alloc(i64 24, i8* %t29)
  %t31 = bitcast i8* %t30 to { i32*, i64, i64 }*
  %t32 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t31, i32 0, i32 0
  store i32* null, i32** %t32
  %t33 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t31, i32 0, i32 1
  store i64 0, i64* %t33
  %t34 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t31, i32 0, i32 2
  store i64 0, i64* %t34
  store i8* %t30, i8** %t0
  br label %list_cow_done_18
list_cow_check_17:
  %t35 = getelementptr inbounds i8, i8* %t27, i64 -16
  %t36 = bitcast i8* %t35 to i64*
  %t37 = load atomic i64, i64* %t36 seq_cst, align 8
  %t38 = icmp eq i64 %t37, 1
  br i1 %t38, label %list_cow_done_18, label %list_cow_clone_19
list_cow_clone_19:
  %t39 = bitcast i8* %t27 to { i32*, i64, i64 }*
  %t40 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t39, i32 0, i32 0
  %t41 = load i32*, i32** %t40
  %t42 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t39, i32 0, i32 1
  %t43 = load i64, i64* %t42
  %t44 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t39, i32 0, i32 2
  %t45 = load i64, i64* %t44
  %t46 = bitcast void (i8*)* @list_release_i32 to i8*
  %t47 = call i8* @star_rc_alloc(i64 24, i8* %t46)
  %t48 = bitcast i8* %t47 to { i32*, i64, i64 }*
  %t49 = mul i64 %t45, 4
  %t50 = call i8* @malloc(i64 %t49)
  %t51 = bitcast i8* %t50 to i32*
  %t52 = icmp sgt i64 %t43, 0
  br i1 %t52, label %list_cow_copy_20, label %list_cow_after_copy_21
list_cow_copy_20:
  %t53 = mul i64 %t43, 4
  %t54 = bitcast i32* %t41 to i8*
  call i8* @memcpy(i8* %t50, i8* %t54, i64 %t53)
  br label %list_cow_after_copy_21
list_cow_after_copy_21:
  %t55 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t48, i32 0, i32 0
  store i32* %t51, i32** %t55
  %t56 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t48, i32 0, i32 1
  store i64 %t43, i64* %t56
  %t57 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t48, i32 0, i32 2
  store i64 %t45, i64* %t57
  call void @star_rc_release(i8* %t27)
  store i8* %t47, i8** %t0
  br label %list_cow_done_18
list_cow_done_18:
  %t58 = load i8*, i8** %t0
  %t59 = bitcast i8* %t58 to { i32*, i64, i64 }*
  %t60 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t59, i32 0, i32 0
  %t61 = load i32*, i32** %t60
  %t62 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t59, i32 0, i32 1
  %t63 = load i64, i64* %t62
  %t64 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t59, i32 0, i32 2
  %t65 = load i64, i64* %t64
  %t66 = load i32*, i32** %t60
  %t67 = icmp sge i64 %t63, %t65
  br i1 %t67, label %list_push_grow_22, label %list_push_store_23
list_push_grow_22:
  %t68 = mul i64 %t65, 2
  %t69 = icmp sgt i64 %t68, 0
  %t70 = select i1 %t69, i64 %t68, i64 1
  %t71 = mul i64 %t70, 4
  %t72 = call i8* @malloc(i64 %t71)
  %t73 = bitcast i8* %t72 to i32*
  %t74 = icmp sgt i64 %t65, 0
  br i1 %t74, label %list_push_copy_24, label %list_push_after_copy_25
list_push_copy_24:
  %t75 = mul i64 %t63, 4
  %t76 = bitcast i32* %t66 to i8*
  call i8* @memcpy(i8* %t72, i8* %t76, i64 %t75)
  call void @free(i8* %t76)
  br label %list_push_after_copy_25
list_push_after_copy_25:
  store i32* %t73, i32** %t60
  store i64 %t70, i64* %t64
  br label %list_push_store_23
list_push_store_23:
  %t77 = load i32*, i32** %t60
  %t78 = getelementptr inbounds i32, i32* %t77, i64 %t63
  store i32 4, i32* %t78
  %t79 = add i64 %t63, 1
  store i64 %t79, i64* %t62
  %t80 = load i8*, i8** %t0
  %t81 = icmp eq i8* %t80, null
  br i1 %t81, label %list_cow_alloc_26, label %list_cow_check_27
list_cow_alloc_26:
  %t82 = bitcast void (i8*)* @list_release_i32 to i8*
  %t83 = call i8* @star_rc_alloc(i64 24, i8* %t82)
  %t84 = bitcast i8* %t83 to { i32*, i64, i64 }*
  %t85 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t84, i32 0, i32 0
  store i32* null, i32** %t85
  %t86 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t84, i32 0, i32 1
  store i64 0, i64* %t86
  %t87 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t84, i32 0, i32 2
  store i64 0, i64* %t87
  store i8* %t83, i8** %t0
  br label %list_cow_done_28
list_cow_check_27:
  %t88 = getelementptr inbounds i8, i8* %t80, i64 -16
  %t89 = bitcast i8* %t88 to i64*
  %t90 = load atomic i64, i64* %t89 seq_cst, align 8
  %t91 = icmp eq i64 %t90, 1
  br i1 %t91, label %list_cow_done_28, label %list_cow_clone_29
list_cow_clone_29:
  %t92 = bitcast i8* %t80 to { i32*, i64, i64 }*
  %t93 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t92, i32 0, i32 0
  %t94 = load i32*, i32** %t93
  %t95 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t92, i32 0, i32 1
  %t96 = load i64, i64* %t95
  %t97 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t92, i32 0, i32 2
  %t98 = load i64, i64* %t97
  %t99 = bitcast void (i8*)* @list_release_i32 to i8*
  %t100 = call i8* @star_rc_alloc(i64 24, i8* %t99)
  %t101 = bitcast i8* %t100 to { i32*, i64, i64 }*
  %t102 = mul i64 %t98, 4
  %t103 = call i8* @malloc(i64 %t102)
  %t104 = bitcast i8* %t103 to i32*
  %t105 = icmp sgt i64 %t96, 0
  br i1 %t105, label %list_cow_copy_30, label %list_cow_after_copy_31
list_cow_copy_30:
  %t106 = mul i64 %t96, 4
  %t107 = bitcast i32* %t94 to i8*
  call i8* @memcpy(i8* %t103, i8* %t107, i64 %t106)
  br label %list_cow_after_copy_31
list_cow_after_copy_31:
  %t108 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t101, i32 0, i32 0
  store i32* %t104, i32** %t108
  %t109 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t101, i32 0, i32 1
  store i64 %t96, i64* %t109
  %t110 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t101, i32 0, i32 2
  store i64 %t98, i64* %t110
  call void @star_rc_release(i8* %t80)
  store i8* %t100, i8** %t0
  br label %list_cow_done_28
list_cow_done_28:
  %t111 = load i8*, i8** %t0
  %t112 = bitcast i8* %t111 to { i32*, i64, i64 }*
  %t113 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t112, i32 0, i32 0
  %t114 = load i32*, i32** %t113
  %t115 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t112, i32 0, i32 1
  %t116 = load i64, i64* %t115
  %t117 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t112, i32 0, i32 2
  %t118 = load i64, i64* %t117
  %t119 = load i32*, i32** %t113
  %t120 = icmp sge i64 %t116, %t118
  br i1 %t120, label %list_push_grow_32, label %list_push_store_33
list_push_grow_32:
  %t121 = mul i64 %t118, 2
  %t122 = icmp sgt i64 %t121, 0
  %t123 = select i1 %t122, i64 %t121, i64 1
  %t124 = mul i64 %t123, 4
  %t125 = call i8* @malloc(i64 %t124)
  %t126 = bitcast i8* %t125 to i32*
  %t127 = icmp sgt i64 %t118, 0
  br i1 %t127, label %list_push_copy_34, label %list_push_after_copy_35
list_push_copy_34:
  %t128 = mul i64 %t116, 4
  %t129 = bitcast i32* %t119 to i8*
  call i8* @memcpy(i8* %t125, i8* %t129, i64 %t128)
  call void @free(i8* %t129)
  br label %list_push_after_copy_35
list_push_after_copy_35:
  store i32* %t126, i32** %t113
  store i64 %t123, i64* %t117
  br label %list_push_store_33
list_push_store_33:
  %t130 = load i32*, i32** %t113
  %t131 = getelementptr inbounds i32, i32* %t130, i64 %t116
  store i32 5, i32* %t131
  %t132 = add i64 %t116, 1
  store i64 %t132, i64* %t115
  %t133 = load i8*, i8** %t0
  %t134 = icmp eq i8* %t133, null
  br i1 %t134, label %list_read_null_36, label %list_read_real_37
list_read_null_36:
  br label %list_read_end_38
list_read_real_37:
  %t135 = bitcast i8* %t133 to { i32*, i64, i64 }*
  %t136 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t135, i32 0, i32 0
  %t137 = load i32*, i32** %t136
  %t138 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t135, i32 0, i32 1
  %t139 = load i64, i64* %t138
  br label %list_read_end_38
list_read_end_38:
  %t140 = phi i32* [ null, %list_read_null_36 ], [ %t137, %list_read_real_37 ]
  %t141 = phi i64 [ 0, %list_read_null_36 ], [ %t139, %list_read_real_37 ]
  %t142 = trunc i64 %t141 to i32
  %t143 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t143, i32 %t142)
  %t144 = load i8*, i8** %t0
  %t145 = icmp eq i8* %t144, null
  br i1 %t145, label %list_read_null_39, label %list_read_real_40
list_read_null_39:
  br label %list_read_end_41
list_read_real_40:
  %t146 = bitcast i8* %t144 to { i32*, i64, i64 }*
  %t147 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t146, i32 0, i32 0
  %t148 = load i32*, i32** %t147
  %t149 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t146, i32 0, i32 1
  %t150 = load i64, i64* %t149
  br label %list_read_end_41
list_read_end_41:
  %t151 = phi i32* [ null, %list_read_null_39 ], [ %t148, %list_read_real_40 ]
  %t152 = phi i64 [ 0, %list_read_null_39 ], [ %t150, %list_read_real_40 ]
  %t153 = trunc i64 %t152 to i32
  %t154 = alloca i32
  store i32 0, i32* %t154
  br label %for_cond_42
for_cond_42:
  %t155 = load i32, i32* %t154
  %t156 = icmp slt i32 %t155, %t153
  br i1 %t156, label %for_body_43, label %for_end_45
for_body_43:
  %t157 = load i32, i32* %t154
  %t158 = load i8*, i8** %t0
  %t159 = icmp eq i8* %t158, null
  br i1 %t159, label %list_read_null_46, label %list_read_real_47
list_read_null_46:
  br label %list_read_end_48
list_read_real_47:
  %t160 = bitcast i8* %t158 to { i32*, i64, i64 }*
  %t161 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t160, i32 0, i32 0
  %t162 = load i32*, i32** %t161
  %t163 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t160, i32 0, i32 1
  %t164 = load i64, i64* %t163
  br label %list_read_end_48
list_read_end_48:
  %t165 = phi i32* [ null, %list_read_null_46 ], [ %t162, %list_read_real_47 ]
  %t166 = phi i64 [ 0, %list_read_null_46 ], [ %t164, %list_read_real_47 ]
  %t167 = load i32, i32* %t154
  %t168 = sext i32 %t167 to i64
  %t169 = icmp ult i64 %t168, %t166
  br i1 %t169, label %list_idx_ok_49, label %list_idx_oob_50
list_idx_ok_49:
  %t170 = getelementptr inbounds i32, i32* %t165, i64 %t168
  %t171 = load i32, i32* %t170
  br label %list_idx_end_51
list_idx_oob_50:
  br label %list_idx_end_51
list_idx_end_51:
  %t172 = phi i32 [ %t171, %list_idx_ok_49 ], [ 0, %list_idx_oob_50 ]
  %t173 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t173, i32 %t157, i32 %t172)
  br label %for_step_44
for_step_44:
  %t174 = load i32, i32* %t154
  %t175 = add i32 %t174, 1
  store i32 %t175, i32* %t154
  br label %for_cond_42
for_end_45:
  %t176 = load i8*, i8** %t0
  %t177 = icmp eq i8* %t176, null
  br i1 %t177, label %list_cow_alloc_52, label %list_cow_check_53
list_cow_alloc_52:
  %t178 = bitcast void (i8*)* @list_release_i32 to i8*
  %t179 = call i8* @star_rc_alloc(i64 24, i8* %t178)
  %t180 = bitcast i8* %t179 to { i32*, i64, i64 }*
  %t181 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t180, i32 0, i32 0
  store i32* null, i32** %t181
  %t182 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t180, i32 0, i32 1
  store i64 0, i64* %t182
  %t183 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t180, i32 0, i32 2
  store i64 0, i64* %t183
  store i8* %t179, i8** %t0
  br label %list_cow_done_54
list_cow_check_53:
  %t184 = getelementptr inbounds i8, i8* %t176, i64 -16
  %t185 = bitcast i8* %t184 to i64*
  %t186 = load atomic i64, i64* %t185 seq_cst, align 8
  %t187 = icmp eq i64 %t186, 1
  br i1 %t187, label %list_cow_done_54, label %list_cow_clone_55
list_cow_clone_55:
  %t188 = bitcast i8* %t176 to { i32*, i64, i64 }*
  %t189 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t188, i32 0, i32 0
  %t190 = load i32*, i32** %t189
  %t191 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t188, i32 0, i32 1
  %t192 = load i64, i64* %t191
  %t193 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t188, i32 0, i32 2
  %t194 = load i64, i64* %t193
  %t195 = bitcast void (i8*)* @list_release_i32 to i8*
  %t196 = call i8* @star_rc_alloc(i64 24, i8* %t195)
  %t197 = bitcast i8* %t196 to { i32*, i64, i64 }*
  %t198 = mul i64 %t194, 4
  %t199 = call i8* @malloc(i64 %t198)
  %t200 = bitcast i8* %t199 to i32*
  %t201 = icmp sgt i64 %t192, 0
  br i1 %t201, label %list_cow_copy_56, label %list_cow_after_copy_57
list_cow_copy_56:
  %t202 = mul i64 %t192, 4
  %t203 = bitcast i32* %t190 to i8*
  call i8* @memcpy(i8* %t199, i8* %t203, i64 %t202)
  br label %list_cow_after_copy_57
list_cow_after_copy_57:
  %t204 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t197, i32 0, i32 0
  store i32* %t200, i32** %t204
  %t205 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t197, i32 0, i32 1
  store i64 %t192, i64* %t205
  %t206 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t197, i32 0, i32 2
  store i64 %t194, i64* %t206
  call void @star_rc_release(i8* %t176)
  store i8* %t196, i8** %t0
  br label %list_cow_done_54
list_cow_done_54:
  %t207 = load i8*, i8** %t0
  %t208 = bitcast i8* %t207 to { i32*, i64, i64 }*
  %t209 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t208, i32 0, i32 0
  %t210 = load i32*, i32** %t209
  %t211 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t208, i32 0, i32 1
  %t212 = load i64, i64* %t211
  %t213 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t208, i32 0, i32 2
  %t214 = sext i32 0 to i64
  %t215 = icmp ult i64 %t214, %t212
  br i1 %t215, label %list_set_do_58, label %list_set_end_59
list_set_do_58:
  %t216 = getelementptr inbounds i32, i32* %t210, i64 %t214
  store i32 100, i32* %t216
  br label %list_set_end_59
list_set_end_59:
  %t217 = load i8*, i8** %t0
  %t218 = icmp eq i8* %t217, null
  br i1 %t218, label %list_read_null_60, label %list_read_real_61
list_read_null_60:
  br label %list_read_end_62
list_read_real_61:
  %t219 = bitcast i8* %t217 to { i32*, i64, i64 }*
  %t220 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t219, i32 0, i32 0
  %t221 = load i32*, i32** %t220
  %t222 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t219, i32 0, i32 1
  %t223 = load i64, i64* %t222
  br label %list_read_end_62
list_read_end_62:
  %t224 = phi i32* [ null, %list_read_null_60 ], [ %t221, %list_read_real_61 ]
  %t225 = phi i64 [ 0, %list_read_null_60 ], [ %t223, %list_read_real_61 ]
  %t226 = sext i32 0 to i64
  %t227 = icmp ult i64 %t226, %t225
  br i1 %t227, label %list_idx_ok_63, label %list_idx_oob_64
list_idx_ok_63:
  %t228 = getelementptr inbounds i32, i32* %t224, i64 %t226
  %t229 = load i32, i32* %t228
  br label %list_idx_end_65
list_idx_oob_64:
  br label %list_idx_end_65
list_idx_end_65:
  %t230 = phi i32 [ %t229, %list_idx_ok_63 ], [ 0, %list_idx_oob_64 ]
  %t231 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t231, i32 %t230)
  %t232 = alloca i32
  %t233 = load i8*, i8** %t0
  %t234 = icmp eq i8* %t233, null
  br i1 %t234, label %list_cow_alloc_66, label %list_cow_check_67
list_cow_alloc_66:
  %t235 = bitcast void (i8*)* @list_release_i32 to i8*
  %t236 = call i8* @star_rc_alloc(i64 24, i8* %t235)
  %t237 = bitcast i8* %t236 to { i32*, i64, i64 }*
  %t238 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t237, i32 0, i32 0
  store i32* null, i32** %t238
  %t239 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t237, i32 0, i32 1
  store i64 0, i64* %t239
  %t240 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t237, i32 0, i32 2
  store i64 0, i64* %t240
  store i8* %t236, i8** %t0
  br label %list_cow_done_68
list_cow_check_67:
  %t241 = getelementptr inbounds i8, i8* %t233, i64 -16
  %t242 = bitcast i8* %t241 to i64*
  %t243 = load atomic i64, i64* %t242 seq_cst, align 8
  %t244 = icmp eq i64 %t243, 1
  br i1 %t244, label %list_cow_done_68, label %list_cow_clone_69
list_cow_clone_69:
  %t245 = bitcast i8* %t233 to { i32*, i64, i64 }*
  %t246 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t245, i32 0, i32 0
  %t247 = load i32*, i32** %t246
  %t248 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t245, i32 0, i32 1
  %t249 = load i64, i64* %t248
  %t250 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t245, i32 0, i32 2
  %t251 = load i64, i64* %t250
  %t252 = bitcast void (i8*)* @list_release_i32 to i8*
  %t253 = call i8* @star_rc_alloc(i64 24, i8* %t252)
  %t254 = bitcast i8* %t253 to { i32*, i64, i64 }*
  %t255 = mul i64 %t251, 4
  %t256 = call i8* @malloc(i64 %t255)
  %t257 = bitcast i8* %t256 to i32*
  %t258 = icmp sgt i64 %t249, 0
  br i1 %t258, label %list_cow_copy_70, label %list_cow_after_copy_71
list_cow_copy_70:
  %t259 = mul i64 %t249, 4
  %t260 = bitcast i32* %t247 to i8*
  call i8* @memcpy(i8* %t256, i8* %t260, i64 %t259)
  br label %list_cow_after_copy_71
list_cow_after_copy_71:
  %t261 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t254, i32 0, i32 0
  store i32* %t257, i32** %t261
  %t262 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t254, i32 0, i32 1
  store i64 %t249, i64* %t262
  %t263 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t254, i32 0, i32 2
  store i64 %t251, i64* %t263
  call void @star_rc_release(i8* %t233)
  store i8* %t253, i8** %t0
  br label %list_cow_done_68
list_cow_done_68:
  %t264 = load i8*, i8** %t0
  %t265 = bitcast i8* %t264 to { i32*, i64, i64 }*
  %t266 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t265, i32 0, i32 0
  %t267 = load i32*, i32** %t266
  %t268 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t265, i32 0, i32 1
  %t269 = load i64, i64* %t268
  %t270 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t265, i32 0, i32 2
  %t271 = icmp eq i64 %t269, 0
  br i1 %t271, label %list_pop_empty_72, label %list_pop_nonempty_73
list_pop_nonempty_73:
  %t272 = sub i64 %t269, 1
  store i64 %t272, i64* %t268
  %t273 = load i32*, i32** %t266
  %t274 = getelementptr inbounds i32, i32* %t273, i64 %t272
  %t275 = load i32, i32* %t274
  br label %list_pop_end_74
list_pop_empty_72:
  br label %list_pop_end_74
list_pop_end_74:
  %t276 = phi i32 [ %t275, %list_pop_nonempty_73 ], [ 0, %list_pop_empty_72 ]
  store i32 %t276, i32* %t232
  %t277 = load i32, i32* %t232
  %t278 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t278, i32 %t277)
  %t279 = load i8*, i8** %t0
  %t280 = icmp eq i8* %t279, null
  br i1 %t280, label %list_read_null_75, label %list_read_real_76
list_read_null_75:
  br label %list_read_end_77
list_read_real_76:
  %t281 = bitcast i8* %t279 to { i32*, i64, i64 }*
  %t282 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t281, i32 0, i32 0
  %t283 = load i32*, i32** %t282
  %t284 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t281, i32 0, i32 1
  %t285 = load i64, i64* %t284
  br label %list_read_end_77
list_read_end_77:
  %t286 = phi i32* [ null, %list_read_null_75 ], [ %t283, %list_read_real_76 ]
  %t287 = phi i64 [ 0, %list_read_null_75 ], [ %t285, %list_read_real_76 ]
  %t288 = trunc i64 %t287 to i32
  %t289 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t289, i32 %t288)
  %t290 = load i8*, i8** %t0
  %t291 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t291)
  %t292 = call i32 @sum_list(i8* %t290)
  %t293 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t293, i32 %t292)
  %t294 = alloca i8*
  store i8* null, i8** %t294
  %t295 = load i8*, i8** %t294
  %t296 = icmp eq i8* %t295, null
  br i1 %t296, label %list_read_null_78, label %list_read_real_79
list_read_null_78:
  br label %list_read_end_80
list_read_real_79:
  %t297 = bitcast i8* %t295 to { i32*, i64, i64 }*
  %t298 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t297, i32 0, i32 0
  %t299 = load i32*, i32** %t298
  %t300 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t297, i32 0, i32 1
  %t301 = load i64, i64* %t300
  br label %list_read_end_80
list_read_end_80:
  %t302 = phi i32* [ null, %list_read_null_78 ], [ %t299, %list_read_real_79 ]
  %t303 = phi i64 [ 0, %list_read_null_78 ], [ %t301, %list_read_real_79 ]
  %t304 = trunc i64 %t303 to i32
  %t305 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t305, i32 %t304)
  %t306 = alloca i32
  %t307 = load i8*, i8** %t294
  %t308 = icmp eq i8* %t307, null
  br i1 %t308, label %list_cow_alloc_81, label %list_cow_check_82
list_cow_alloc_81:
  %t309 = bitcast void (i8*)* @list_release_i32 to i8*
  %t310 = call i8* @star_rc_alloc(i64 24, i8* %t309)
  %t311 = bitcast i8* %t310 to { i32*, i64, i64 }*
  %t312 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t311, i32 0, i32 0
  store i32* null, i32** %t312
  %t313 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t311, i32 0, i32 1
  store i64 0, i64* %t313
  %t314 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t311, i32 0, i32 2
  store i64 0, i64* %t314
  store i8* %t310, i8** %t294
  br label %list_cow_done_83
list_cow_check_82:
  %t315 = getelementptr inbounds i8, i8* %t307, i64 -16
  %t316 = bitcast i8* %t315 to i64*
  %t317 = load atomic i64, i64* %t316 seq_cst, align 8
  %t318 = icmp eq i64 %t317, 1
  br i1 %t318, label %list_cow_done_83, label %list_cow_clone_84
list_cow_clone_84:
  %t319 = bitcast i8* %t307 to { i32*, i64, i64 }*
  %t320 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t319, i32 0, i32 0
  %t321 = load i32*, i32** %t320
  %t322 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t319, i32 0, i32 1
  %t323 = load i64, i64* %t322
  %t324 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t319, i32 0, i32 2
  %t325 = load i64, i64* %t324
  %t326 = bitcast void (i8*)* @list_release_i32 to i8*
  %t327 = call i8* @star_rc_alloc(i64 24, i8* %t326)
  %t328 = bitcast i8* %t327 to { i32*, i64, i64 }*
  %t329 = mul i64 %t325, 4
  %t330 = call i8* @malloc(i64 %t329)
  %t331 = bitcast i8* %t330 to i32*
  %t332 = icmp sgt i64 %t323, 0
  br i1 %t332, label %list_cow_copy_85, label %list_cow_after_copy_86
list_cow_copy_85:
  %t333 = mul i64 %t323, 4
  %t334 = bitcast i32* %t321 to i8*
  call i8* @memcpy(i8* %t330, i8* %t334, i64 %t333)
  br label %list_cow_after_copy_86
list_cow_after_copy_86:
  %t335 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t328, i32 0, i32 0
  store i32* %t331, i32** %t335
  %t336 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t328, i32 0, i32 1
  store i64 %t323, i64* %t336
  %t337 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t328, i32 0, i32 2
  store i64 %t325, i64* %t337
  call void @star_rc_release(i8* %t307)
  store i8* %t327, i8** %t294
  br label %list_cow_done_83
list_cow_done_83:
  %t338 = load i8*, i8** %t294
  %t339 = bitcast i8* %t338 to { i32*, i64, i64 }*
  %t340 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t339, i32 0, i32 0
  %t341 = load i32*, i32** %t340
  %t342 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t339, i32 0, i32 1
  %t343 = load i64, i64* %t342
  %t344 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t339, i32 0, i32 2
  %t345 = icmp eq i64 %t343, 0
  br i1 %t345, label %list_pop_empty_87, label %list_pop_nonempty_88
list_pop_nonempty_88:
  %t346 = sub i64 %t343, 1
  store i64 %t346, i64* %t342
  %t347 = load i32*, i32** %t340
  %t348 = getelementptr inbounds i32, i32* %t347, i64 %t346
  %t349 = load i32, i32* %t348
  br label %list_pop_end_89
list_pop_empty_87:
  br label %list_pop_end_89
list_pop_end_89:
  %t350 = phi i32 [ %t349, %list_pop_nonempty_88 ], [ 0, %list_pop_empty_87 ]
  store i32 %t350, i32* %t306
  %t351 = load i32, i32* %t306
  %t352 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t352, i32 %t351)
  %t353 = alloca i32
  %t354 = load i8*, i8** %t294
  %t355 = icmp eq i8* %t354, null
  br i1 %t355, label %list_read_null_90, label %list_read_real_91
list_read_null_90:
  br label %list_read_end_92
list_read_real_91:
  %t356 = bitcast i8* %t354 to { i32*, i64, i64 }*
  %t357 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t356, i32 0, i32 0
  %t358 = load i32*, i32** %t357
  %t359 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t356, i32 0, i32 1
  %t360 = load i64, i64* %t359
  br label %list_read_end_92
list_read_end_92:
  %t361 = phi i32* [ null, %list_read_null_90 ], [ %t358, %list_read_real_91 ]
  %t362 = phi i64 [ 0, %list_read_null_90 ], [ %t360, %list_read_real_91 ]
  %t363 = sext i32 0 to i64
  %t364 = icmp ult i64 %t363, %t362
  br i1 %t364, label %list_idx_ok_93, label %list_idx_oob_94
list_idx_ok_93:
  %t365 = getelementptr inbounds i32, i32* %t361, i64 %t363
  %t366 = load i32, i32* %t365
  br label %list_idx_end_95
list_idx_oob_94:
  br label %list_idx_end_95
list_idx_end_95:
  %t367 = phi i32 [ %t366, %list_idx_ok_93 ], [ 0, %list_idx_oob_94 ]
  store i32 %t367, i32* %t353
  %t368 = load i32, i32* %t353
  %t369 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t369, i32 %t368)
  %t370 = alloca i8*
  store i8* null, i8** %t370
  %t371 = alloca i32
  store i32 0, i32* %t371
  br label %while_cond_96
while_cond_96:
  %t372 = load i32, i32* %t371
  %t373 = icmp slt i32 %t372, 20
  br i1 %t373, label %while_body_97, label %while_end_99
while_body_97:
  %t374 = load i8*, i8** %t370
  %t375 = icmp eq i8* %t374, null
  br i1 %t375, label %list_cow_alloc_100, label %list_cow_check_101
list_cow_alloc_100:
  %t376 = bitcast void (i8*)* @list_release_i32 to i8*
  %t377 = call i8* @star_rc_alloc(i64 24, i8* %t376)
  %t378 = bitcast i8* %t377 to { i32*, i64, i64 }*
  %t379 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t378, i32 0, i32 0
  store i32* null, i32** %t379
  %t380 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t378, i32 0, i32 1
  store i64 0, i64* %t380
  %t381 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t378, i32 0, i32 2
  store i64 0, i64* %t381
  store i8* %t377, i8** %t370
  br label %list_cow_done_102
list_cow_check_101:
  %t382 = getelementptr inbounds i8, i8* %t374, i64 -16
  %t383 = bitcast i8* %t382 to i64*
  %t384 = load atomic i64, i64* %t383 seq_cst, align 8
  %t385 = icmp eq i64 %t384, 1
  br i1 %t385, label %list_cow_done_102, label %list_cow_clone_103
list_cow_clone_103:
  %t386 = bitcast i8* %t374 to { i32*, i64, i64 }*
  %t387 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t386, i32 0, i32 0
  %t388 = load i32*, i32** %t387
  %t389 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t386, i32 0, i32 1
  %t390 = load i64, i64* %t389
  %t391 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t386, i32 0, i32 2
  %t392 = load i64, i64* %t391
  %t393 = bitcast void (i8*)* @list_release_i32 to i8*
  %t394 = call i8* @star_rc_alloc(i64 24, i8* %t393)
  %t395 = bitcast i8* %t394 to { i32*, i64, i64 }*
  %t396 = mul i64 %t392, 4
  %t397 = call i8* @malloc(i64 %t396)
  %t398 = bitcast i8* %t397 to i32*
  %t399 = icmp sgt i64 %t390, 0
  br i1 %t399, label %list_cow_copy_104, label %list_cow_after_copy_105
list_cow_copy_104:
  %t400 = mul i64 %t390, 4
  %t401 = bitcast i32* %t388 to i8*
  call i8* @memcpy(i8* %t397, i8* %t401, i64 %t400)
  br label %list_cow_after_copy_105
list_cow_after_copy_105:
  %t402 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t395, i32 0, i32 0
  store i32* %t398, i32** %t402
  %t403 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t395, i32 0, i32 1
  store i64 %t390, i64* %t403
  %t404 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t395, i32 0, i32 2
  store i64 %t392, i64* %t404
  call void @star_rc_release(i8* %t374)
  store i8* %t394, i8** %t370
  br label %list_cow_done_102
list_cow_done_102:
  %t405 = load i8*, i8** %t370
  %t406 = bitcast i8* %t405 to { i32*, i64, i64 }*
  %t407 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t406, i32 0, i32 0
  %t408 = load i32*, i32** %t407
  %t409 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t406, i32 0, i32 1
  %t410 = load i64, i64* %t409
  %t411 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t406, i32 0, i32 2
  %t412 = load i32, i32* %t371
  %t413 = load i64, i64* %t411
  %t414 = load i32*, i32** %t407
  %t415 = icmp sge i64 %t410, %t413
  br i1 %t415, label %list_push_grow_106, label %list_push_store_107
list_push_grow_106:
  %t416 = mul i64 %t413, 2
  %t417 = icmp sgt i64 %t416, 0
  %t418 = select i1 %t417, i64 %t416, i64 1
  %t419 = mul i64 %t418, 4
  %t420 = call i8* @malloc(i64 %t419)
  %t421 = bitcast i8* %t420 to i32*
  %t422 = icmp sgt i64 %t413, 0
  br i1 %t422, label %list_push_copy_108, label %list_push_after_copy_109
list_push_copy_108:
  %t423 = mul i64 %t410, 4
  %t424 = bitcast i32* %t414 to i8*
  call i8* @memcpy(i8* %t420, i8* %t424, i64 %t423)
  call void @free(i8* %t424)
  br label %list_push_after_copy_109
list_push_after_copy_109:
  store i32* %t421, i32** %t407
  store i64 %t418, i64* %t411
  br label %list_push_store_107
list_push_store_107:
  %t425 = load i32*, i32** %t407
  %t426 = getelementptr inbounds i32, i32* %t425, i64 %t410
  store i32 %t412, i32* %t426
  %t427 = add i64 %t410, 1
  store i64 %t427, i64* %t409
  %t428 = load i32, i32* %t371
  %t429 = add i32 %t428, 1
  store i32 %t429, i32* %t371
  br label %while_cond_96
while_else_98:
  br label %while_end_99
while_end_99:
  %t430 = load i8*, i8** %t370
  %t431 = icmp eq i8* %t430, null
  br i1 %t431, label %list_read_null_110, label %list_read_real_111
list_read_null_110:
  br label %list_read_end_112
list_read_real_111:
  %t432 = bitcast i8* %t430 to { i32*, i64, i64 }*
  %t433 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t432, i32 0, i32 0
  %t434 = load i32*, i32** %t433
  %t435 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t432, i32 0, i32 1
  %t436 = load i64, i64* %t435
  br label %list_read_end_112
list_read_end_112:
  %t437 = phi i32* [ null, %list_read_null_110 ], [ %t434, %list_read_real_111 ]
  %t438 = phi i64 [ 0, %list_read_null_110 ], [ %t436, %list_read_real_111 ]
  %t439 = trunc i64 %t438 to i32
  %t440 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t440, i32 %t439)
  %t441 = load i8*, i8** %t370
  %t442 = icmp eq i8* %t441, null
  br i1 %t442, label %list_read_null_113, label %list_read_real_114
list_read_null_113:
  br label %list_read_end_115
list_read_real_114:
  %t443 = bitcast i8* %t441 to { i32*, i64, i64 }*
  %t444 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t443, i32 0, i32 0
  %t445 = load i32*, i32** %t444
  %t446 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t443, i32 0, i32 1
  %t447 = load i64, i64* %t446
  br label %list_read_end_115
list_read_end_115:
  %t448 = phi i32* [ null, %list_read_null_113 ], [ %t445, %list_read_real_114 ]
  %t449 = phi i64 [ 0, %list_read_null_113 ], [ %t447, %list_read_real_114 ]
  %t450 = sext i32 19 to i64
  %t451 = icmp ult i64 %t450, %t449
  br i1 %t451, label %list_idx_ok_116, label %list_idx_oob_117
list_idx_ok_116:
  %t452 = getelementptr inbounds i32, i32* %t448, i64 %t450
  %t453 = load i32, i32* %t452
  br label %list_idx_end_118
list_idx_oob_117:
  br label %list_idx_end_118
list_idx_end_118:
  %t454 = phi i32 [ %t453, %list_idx_ok_116 ], [ 0, %list_idx_oob_117 ]
  %t455 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t455, i32 %t454)
  %t456 = load i8*, i8** %t370
  %t457 = icmp eq i8* %t456, null
  br i1 %t457, label %list_read_null_119, label %list_read_real_120
list_read_null_119:
  br label %list_read_end_121
list_read_real_120:
  %t458 = bitcast i8* %t456 to { i32*, i64, i64 }*
  %t459 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t458, i32 0, i32 0
  %t460 = load i32*, i32** %t459
  %t461 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t458, i32 0, i32 1
  %t462 = load i64, i64* %t461
  br label %list_read_end_121
list_read_end_121:
  %t463 = phi i32* [ null, %list_read_null_119 ], [ %t460, %list_read_real_120 ]
  %t464 = phi i64 [ 0, %list_read_null_119 ], [ %t462, %list_read_real_120 ]
  %t465 = sext i32 0 to i64
  %t466 = icmp ult i64 %t465, %t464
  br i1 %t466, label %list_idx_ok_122, label %list_idx_oob_123
list_idx_ok_122:
  %t467 = getelementptr inbounds i32, i32* %t463, i64 %t465
  %t468 = load i32, i32* %t467
  br label %list_idx_end_124
list_idx_oob_123:
  br label %list_idx_end_124
list_idx_end_124:
  %t469 = phi i32 [ %t468, %list_idx_ok_122 ], [ 0, %list_idx_oob_123 ]
  %t470 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t470, i32 %t469)
  %t471 = alloca i8*
  %t472 = call i8* @malloc(i64 24)
  %t473 = bitcast i8* %t472 to i8**
  %t474 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t475 = getelementptr inbounds i8*, i8** %t473, i64 0
  store i8* %t474, i8** %t475
  %t476 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t477 = getelementptr inbounds i8*, i8** %t473, i64 1
  store i8* %t476, i8** %t477
  %t478 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t479 = getelementptr inbounds i8*, i8** %t473, i64 2
  store i8* %t478, i8** %t479
  %t492 = bitcast void (i8*)* @list_release_str to i8*
  %t493 = call i8* @star_rc_alloc(i64 24, i8* %t492)
  %t494 = bitcast i8* %t493 to { i8**, i64, i64 }*
  %t495 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t494, i32 0, i32 0
  store i8** %t473, i8*** %t495
  %t496 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t494, i32 0, i32 1
  store i64 3, i64* %t496
  %t497 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t494, i32 0, i32 2
  store i64 3, i64* %t497
  store i8* %t493, i8** %t471
  %t498 = load i8*, i8** %t471
  %t499 = icmp eq i8* %t498, null
  br i1 %t499, label %list_read_null_128, label %list_read_real_129
list_read_null_128:
  br label %list_read_end_130
list_read_real_129:
  %t500 = bitcast i8* %t498 to { i8**, i64, i64 }*
  %t501 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t500, i32 0, i32 0
  %t502 = load i8**, i8*** %t501
  %t503 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t500, i32 0, i32 1
  %t504 = load i64, i64* %t503
  br label %list_read_end_130
list_read_end_130:
  %t505 = phi i8** [ null, %list_read_null_128 ], [ %t502, %list_read_real_129 ]
  %t506 = phi i64 [ 0, %list_read_null_128 ], [ %t504, %list_read_real_129 ]
  %t507 = trunc i64 %t506 to i32
  %t508 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t508, i32 %t507)
  %t509 = load i8*, i8** %t471
  %t510 = icmp eq i8* %t509, null
  br i1 %t510, label %list_read_null_131, label %list_read_real_132
list_read_null_131:
  br label %list_read_end_133
list_read_real_132:
  %t511 = bitcast i8* %t509 to { i8**, i64, i64 }*
  %t512 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t511, i32 0, i32 0
  %t513 = load i8**, i8*** %t512
  %t514 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t511, i32 0, i32 1
  %t515 = load i64, i64* %t514
  br label %list_read_end_133
list_read_end_133:
  %t516 = phi i8** [ null, %list_read_null_131 ], [ %t513, %list_read_real_132 ]
  %t517 = phi i64 [ 0, %list_read_null_131 ], [ %t515, %list_read_real_132 ]
  %t518 = sext i32 1 to i64
  %t519 = icmp ult i64 %t518, %t517
  br i1 %t519, label %list_idx_ok_134, label %list_idx_oob_135
list_idx_ok_134:
  %t520 = getelementptr inbounds i8*, i8** %t516, i64 %t518
  %t521 = load i8*, i8** %t520
  %t522 = load i8*, i8** %t520
  call void @star_rc_retain(i8* %t522)
  br label %list_idx_end_136
list_idx_oob_135:
  br label %list_idx_end_136
list_idx_end_136:
  %t523 = phi i8* [ %t521, %list_idx_ok_134 ], [ null, %list_idx_oob_135 ]
  call void @star_rc_release(i8* %t523)
  %t524 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t524, i8* %t523)
  %t525 = alloca i8*
  %t526 = call i8* @malloc(i64 16)
  %t527 = bitcast i8* %t526 to %Point*
  %t528 = alloca %Point
  %t529 = getelementptr inbounds %Point, %Point* %t528, i32 0, i32 0
  store i32 1, i32* %t529
  %t530 = getelementptr inbounds %Point, %Point* %t528, i32 0, i32 1
  store i32 2, i32* %t530
  %t531 = load %Point, %Point* %t528
  %t532 = getelementptr inbounds %Point, %Point* %t527, i64 0
  store %Point %t531, %Point* %t532
  %t533 = alloca %Point
  %t534 = getelementptr inbounds %Point, %Point* %t533, i32 0, i32 0
  store i32 3, i32* %t534
  %t535 = getelementptr inbounds %Point, %Point* %t533, i32 0, i32 1
  store i32 4, i32* %t535
  %t536 = load %Point, %Point* %t533
  %t537 = getelementptr inbounds %Point, %Point* %t527, i64 1
  store %Point %t536, %Point* %t537
  %t542 = bitcast void (i8*)* @list_release_s_Point to i8*
  %t543 = call i8* @star_rc_alloc(i64 24, i8* %t542)
  %t544 = bitcast i8* %t543 to { %Point*, i64, i64 }*
  %t545 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t544, i32 0, i32 0
  store %Point* %t527, %Point** %t545
  %t546 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t544, i32 0, i32 1
  store i64 2, i64* %t546
  %t547 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t544, i32 0, i32 2
  store i64 2, i64* %t547
  store i8* %t543, i8** %t525
  %t548 = alloca %Point
  %t549 = load i8*, i8** %t525
  %t550 = icmp eq i8* %t549, null
  br i1 %t550, label %list_read_null_137, label %list_read_real_138
list_read_null_137:
  br label %list_read_end_139
list_read_real_138:
  %t551 = bitcast i8* %t549 to { %Point*, i64, i64 }*
  %t552 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t551, i32 0, i32 0
  %t553 = load %Point*, %Point** %t552
  %t554 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t551, i32 0, i32 1
  %t555 = load i64, i64* %t554
  br label %list_read_end_139
list_read_end_139:
  %t556 = phi %Point* [ null, %list_read_null_137 ], [ %t553, %list_read_real_138 ]
  %t557 = phi i64 [ 0, %list_read_null_137 ], [ %t555, %list_read_real_138 ]
  %t558 = sext i32 1 to i64
  %t559 = icmp ult i64 %t558, %t557
  br i1 %t559, label %list_idx_ok_140, label %list_idx_oob_141
list_idx_ok_140:
  %t560 = getelementptr inbounds %Point, %Point* %t556, i64 %t558
  %t561 = load %Point, %Point* %t560
  br label %list_idx_end_142
list_idx_oob_141:
  br label %list_idx_end_142
list_idx_end_142:
  %t562 = phi %Point [ %t561, %list_idx_ok_140 ], [ zeroinitializer, %list_idx_oob_141 ]
  store %Point %t562, %Point* %t548
  %t563 = getelementptr inbounds %Point, %Point* %t548, i32 0, i32 0
  %t564 = load i32, i32* %t563
  %t565 = getelementptr inbounds %Point, %Point* %t548, i32 0, i32 1
  %t566 = load i32, i32* %t565
  %t567 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.18, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t567, i32 %t564, i32 %t566)
  %t568 = load i8*, i8** %t525
  call void @star_rc_release(i8* %t568)
  %t569 = load i8*, i8** %t471
  call void @star_rc_release(i8* %t569)
  %t570 = load i8*, i8** %t370
  call void @star_rc_release(i8* %t570)
  %t571 = load i8*, i8** %t294
  call void @star_rc_release(i8* %t571)
  %t572 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t572)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_i32(i8* %objp) {
entry:
  %t6 = bitcast i8* %objp to { i32*, i64, i64 }*
  %t7 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t6, i32 0, i32 0
  %t8 = load i32*, i32** %t7
  %t9 = bitcast i32* %t8 to i8*
  call void @free(i8* %t9)
  ret void
}


define void @list_release_str(i8* %objp) {
entry:
  %t480 = bitcast i8* %objp to { i8**, i64, i64 }*
  %t481 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t480, i32 0, i32 0
  %t482 = load i8**, i8*** %t481
  %t483 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t480, i32 0, i32 1
  %t484 = load i64, i64* %t483
  %t485 = alloca i64
  store i64 0, i64* %t485
  br label %list_release_cond_125
list_release_cond_125:
  %t486 = load i64, i64* %t485
  %t487 = icmp slt i64 %t486, %t484
  br i1 %t487, label %list_release_body_126, label %list_release_end_127
list_release_body_126:
  %t488 = getelementptr inbounds i8*, i8** %t482, i64 %t486
  %t489 = load i8*, i8** %t488
  call void @star_rc_release(i8* %t489)
  %t490 = add i64 %t486, 1
  store i64 %t490, i64* %t485
  br label %list_release_cond_125
list_release_end_127:
  %t491 = bitcast i8** %t482 to i8*
  call void @free(i8* %t491)
  ret void
}


define void @list_release_s_Point(i8* %objp) {
entry:
  %t538 = bitcast i8* %objp to { %Point*, i64, i64 }*
  %t539 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t538, i32 0, i32 0
  %t540 = load %Point*, %Point** %t539
  %t541 = bitcast %Point* %t540 to i8*
  call void @free(i8* %t541)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant [18 x i8] c"initial len = %d\0A\00"
@.str.1 = private unnamed_addr constant [21 x i8] c"after push len = %d\0A\00"
@.str.2 = private unnamed_addr constant [15 x i8] c"nums[%d] = %d\0A\00"
@.str.3 = private unnamed_addr constant [24 x i8] c"nums[0] after set = %d\0A\00"
@.str.4 = private unnamed_addr constant [13 x i8] c"popped = %d\0A\00"
@.str.5 = private unnamed_addr constant [20 x i8] c"len after pop = %d\0A\00"
@.str.6 = private unnamed_addr constant [23 x i8] c"sum via function = %d\0A\00"
@.str.7 = private unnamed_addr constant [16 x i8] c"empty len = %d\0A\00"
@.str.8 = private unnamed_addr constant [21 x i8] c"pop from empty = %d\0A\00"
@.str.9 = private unnamed_addr constant [16 x i8] c"index oob = %d\0A\00"
@.str.10 = private unnamed_addr constant [16 x i8] c"grown len = %d\0A\00"
@.str.11 = private unnamed_addr constant [16 x i8] c"grown[19] = %d\0A\00"
@.str.12 = private unnamed_addr constant [15 x i8] c"grown[0] = %d\0A\00"
@.str.13 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"alpha\00" }
@.str.14 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"beta\00" }
@.str.15 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"gamma\00" }
@.str.16 = private unnamed_addr constant [16 x i8] c"words len = %d\0A\00"
@.str.17 = private unnamed_addr constant [15 x i8] c"words[1] = %s\0A\00"
@.str.18 = private unnamed_addr constant [22 x i8] c"points[1] = (%d, %d)\0A\00"
