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
  %t1 = getelementptr i32, i32* null, i32 1
  %t2 = ptrtoint i32* %t1 to i64
  %t3 = mul i64 %t2, 3
  %t4 = call i8* @malloc(i64 %t3)
  %t5 = bitcast i8* %t4 to i32*
  %t6 = getelementptr inbounds i32, i32* %t5, i64 0
  store i32 1, i32* %t6
  %t7 = getelementptr inbounds i32, i32* %t5, i64 1
  store i32 2, i32* %t7
  %t8 = getelementptr inbounds i32, i32* %t5, i64 2
  store i32 3, i32* %t8
  %t13 = bitcast void (i8*)* @list_release_i32 to i8*
  %t14 = call i8* @star_rc_alloc(i64 24, i8* %t13)
  %t15 = bitcast i8* %t14 to { i32*, i64, i64 }*
  %t16 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t15, i32 0, i32 0
  store i32* %t5, i32** %t16
  %t17 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t15, i32 0, i32 1
  store i64 3, i64* %t17
  %t18 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t15, i32 0, i32 2
  store i64 3, i64* %t18
  store i8* %t14, i8** %t0
  %t19 = load i8*, i8** %t0
  %t20 = icmp eq i8* %t19, null
  br i1 %t20, label %list_read_null_13, label %list_read_real_14
list_read_null_13:
  br label %list_read_end_15
list_read_real_14:
  %t21 = bitcast i8* %t19 to { i32*, i64, i64 }*
  %t22 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t21, i32 0, i32 0
  %t23 = load i32*, i32** %t22
  %t24 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t21, i32 0, i32 1
  %t25 = load i64, i64* %t24
  br label %list_read_end_15
list_read_end_15:
  %t26 = phi i32* [ null, %list_read_null_13 ], [ %t23, %list_read_real_14 ]
  %t27 = phi i64 [ 0, %list_read_null_13 ], [ %t25, %list_read_real_14 ]
  %t28 = trunc i64 %t27 to i32
  %t29 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t29, i32 %t28)
  %t30 = getelementptr i32, i32* null, i32 1
  %t31 = ptrtoint i32* %t30 to i64
  %t32 = load i8*, i8** %t0
  %t33 = icmp eq i8* %t32, null
  br i1 %t33, label %list_cow_alloc_16, label %list_cow_check_17
list_cow_alloc_16:
  %t34 = bitcast void (i8*)* @list_release_i32 to i8*
  %t35 = call i8* @star_rc_alloc(i64 24, i8* %t34)
  %t36 = bitcast i8* %t35 to { i32*, i64, i64 }*
  %t37 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t36, i32 0, i32 0
  store i32* null, i32** %t37
  %t38 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t36, i32 0, i32 1
  store i64 0, i64* %t38
  %t39 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t36, i32 0, i32 2
  store i64 0, i64* %t39
  store i8* %t35, i8** %t0
  br label %list_cow_done_18
list_cow_check_17:
  %t40 = getelementptr inbounds i8, i8* %t32, i64 -16
  %t41 = bitcast i8* %t40 to i64*
  %t42 = load atomic i64, i64* %t41 seq_cst, align 8
  %t43 = icmp eq i64 %t42, 1
  br i1 %t43, label %list_cow_done_18, label %list_cow_clone_19
list_cow_clone_19:
  %t44 = bitcast i8* %t32 to { i32*, i64, i64 }*
  %t45 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t44, i32 0, i32 0
  %t46 = load i32*, i32** %t45
  %t47 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t44, i32 0, i32 1
  %t48 = load i64, i64* %t47
  %t49 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t44, i32 0, i32 2
  %t50 = load i64, i64* %t49
  %t51 = bitcast void (i8*)* @list_release_i32 to i8*
  %t52 = call i8* @star_rc_alloc(i64 24, i8* %t51)
  %t53 = bitcast i8* %t52 to { i32*, i64, i64 }*
  %t54 = mul i64 %t50, %t31
  %t55 = call i8* @malloc(i64 %t54)
  %t56 = bitcast i8* %t55 to i32*
  %t57 = icmp sgt i64 %t48, 0
  br i1 %t57, label %list_cow_copy_20, label %list_cow_after_copy_21
list_cow_copy_20:
  %t58 = mul i64 %t48, %t31
  %t59 = bitcast i32* %t46 to i8*
  call i8* @memcpy(i8* %t55, i8* %t59, i64 %t58)
  br label %list_cow_after_copy_21
list_cow_after_copy_21:
  %t60 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t53, i32 0, i32 0
  store i32* %t56, i32** %t60
  %t61 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t53, i32 0, i32 1
  store i64 %t48, i64* %t61
  %t62 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t53, i32 0, i32 2
  store i64 %t50, i64* %t62
  call void @star_rc_release(i8* %t32)
  store i8* %t52, i8** %t0
  br label %list_cow_done_18
list_cow_done_18:
  %t63 = load i8*, i8** %t0
  %t64 = bitcast i8* %t63 to { i32*, i64, i64 }*
  %t65 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t64, i32 0, i32 0
  %t66 = load i32*, i32** %t65
  %t67 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t64, i32 0, i32 1
  %t68 = load i64, i64* %t67
  %t69 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t64, i32 0, i32 2
  %t70 = load i64, i64* %t69
  %t71 = load i32*, i32** %t65
  %t72 = icmp sge i64 %t68, %t70
  br i1 %t72, label %list_push_grow_22, label %list_push_store_23
list_push_grow_22:
  %t73 = mul i64 %t70, 2
  %t74 = icmp sgt i64 %t73, 0
  %t75 = select i1 %t74, i64 %t73, i64 1
  %t76 = getelementptr i32, i32* null, i32 1
  %t77 = ptrtoint i32* %t76 to i64
  %t78 = mul i64 %t75, %t77
  %t79 = call i8* @malloc(i64 %t78)
  %t80 = bitcast i8* %t79 to i32*
  %t81 = icmp sgt i64 %t70, 0
  br i1 %t81, label %list_push_copy_24, label %list_push_after_copy_25
list_push_copy_24:
  %t82 = mul i64 %t68, %t77
  %t83 = bitcast i32* %t71 to i8*
  call i8* @memcpy(i8* %t79, i8* %t83, i64 %t82)
  call void @free(i8* %t83)
  br label %list_push_after_copy_25
list_push_after_copy_25:
  store i32* %t80, i32** %t65
  store i64 %t75, i64* %t69
  br label %list_push_store_23
list_push_store_23:
  %t84 = load i32*, i32** %t65
  %t85 = getelementptr inbounds i32, i32* %t84, i64 %t68
  store i32 4, i32* %t85
  %t86 = add i64 %t68, 1
  store i64 %t86, i64* %t67
  %t87 = getelementptr i32, i32* null, i32 1
  %t88 = ptrtoint i32* %t87 to i64
  %t89 = load i8*, i8** %t0
  %t90 = icmp eq i8* %t89, null
  br i1 %t90, label %list_cow_alloc_26, label %list_cow_check_27
list_cow_alloc_26:
  %t91 = bitcast void (i8*)* @list_release_i32 to i8*
  %t92 = call i8* @star_rc_alloc(i64 24, i8* %t91)
  %t93 = bitcast i8* %t92 to { i32*, i64, i64 }*
  %t94 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t93, i32 0, i32 0
  store i32* null, i32** %t94
  %t95 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t93, i32 0, i32 1
  store i64 0, i64* %t95
  %t96 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t93, i32 0, i32 2
  store i64 0, i64* %t96
  store i8* %t92, i8** %t0
  br label %list_cow_done_28
list_cow_check_27:
  %t97 = getelementptr inbounds i8, i8* %t89, i64 -16
  %t98 = bitcast i8* %t97 to i64*
  %t99 = load atomic i64, i64* %t98 seq_cst, align 8
  %t100 = icmp eq i64 %t99, 1
  br i1 %t100, label %list_cow_done_28, label %list_cow_clone_29
list_cow_clone_29:
  %t101 = bitcast i8* %t89 to { i32*, i64, i64 }*
  %t102 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t101, i32 0, i32 0
  %t103 = load i32*, i32** %t102
  %t104 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t101, i32 0, i32 1
  %t105 = load i64, i64* %t104
  %t106 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t101, i32 0, i32 2
  %t107 = load i64, i64* %t106
  %t108 = bitcast void (i8*)* @list_release_i32 to i8*
  %t109 = call i8* @star_rc_alloc(i64 24, i8* %t108)
  %t110 = bitcast i8* %t109 to { i32*, i64, i64 }*
  %t111 = mul i64 %t107, %t88
  %t112 = call i8* @malloc(i64 %t111)
  %t113 = bitcast i8* %t112 to i32*
  %t114 = icmp sgt i64 %t105, 0
  br i1 %t114, label %list_cow_copy_30, label %list_cow_after_copy_31
list_cow_copy_30:
  %t115 = mul i64 %t105, %t88
  %t116 = bitcast i32* %t103 to i8*
  call i8* @memcpy(i8* %t112, i8* %t116, i64 %t115)
  br label %list_cow_after_copy_31
list_cow_after_copy_31:
  %t117 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t110, i32 0, i32 0
  store i32* %t113, i32** %t117
  %t118 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t110, i32 0, i32 1
  store i64 %t105, i64* %t118
  %t119 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t110, i32 0, i32 2
  store i64 %t107, i64* %t119
  call void @star_rc_release(i8* %t89)
  store i8* %t109, i8** %t0
  br label %list_cow_done_28
list_cow_done_28:
  %t120 = load i8*, i8** %t0
  %t121 = bitcast i8* %t120 to { i32*, i64, i64 }*
  %t122 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t121, i32 0, i32 0
  %t123 = load i32*, i32** %t122
  %t124 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t121, i32 0, i32 1
  %t125 = load i64, i64* %t124
  %t126 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t121, i32 0, i32 2
  %t127 = load i64, i64* %t126
  %t128 = load i32*, i32** %t122
  %t129 = icmp sge i64 %t125, %t127
  br i1 %t129, label %list_push_grow_32, label %list_push_store_33
list_push_grow_32:
  %t130 = mul i64 %t127, 2
  %t131 = icmp sgt i64 %t130, 0
  %t132 = select i1 %t131, i64 %t130, i64 1
  %t133 = getelementptr i32, i32* null, i32 1
  %t134 = ptrtoint i32* %t133 to i64
  %t135 = mul i64 %t132, %t134
  %t136 = call i8* @malloc(i64 %t135)
  %t137 = bitcast i8* %t136 to i32*
  %t138 = icmp sgt i64 %t127, 0
  br i1 %t138, label %list_push_copy_34, label %list_push_after_copy_35
list_push_copy_34:
  %t139 = mul i64 %t125, %t134
  %t140 = bitcast i32* %t128 to i8*
  call i8* @memcpy(i8* %t136, i8* %t140, i64 %t139)
  call void @free(i8* %t140)
  br label %list_push_after_copy_35
list_push_after_copy_35:
  store i32* %t137, i32** %t122
  store i64 %t132, i64* %t126
  br label %list_push_store_33
list_push_store_33:
  %t141 = load i32*, i32** %t122
  %t142 = getelementptr inbounds i32, i32* %t141, i64 %t125
  store i32 5, i32* %t142
  %t143 = add i64 %t125, 1
  store i64 %t143, i64* %t124
  %t144 = load i8*, i8** %t0
  %t145 = icmp eq i8* %t144, null
  br i1 %t145, label %list_read_null_36, label %list_read_real_37
list_read_null_36:
  br label %list_read_end_38
list_read_real_37:
  %t146 = bitcast i8* %t144 to { i32*, i64, i64 }*
  %t147 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t146, i32 0, i32 0
  %t148 = load i32*, i32** %t147
  %t149 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t146, i32 0, i32 1
  %t150 = load i64, i64* %t149
  br label %list_read_end_38
list_read_end_38:
  %t151 = phi i32* [ null, %list_read_null_36 ], [ %t148, %list_read_real_37 ]
  %t152 = phi i64 [ 0, %list_read_null_36 ], [ %t150, %list_read_real_37 ]
  %t153 = trunc i64 %t152 to i32
  %t154 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t154, i32 %t153)
  %t155 = load i8*, i8** %t0
  %t156 = icmp eq i8* %t155, null
  br i1 %t156, label %list_read_null_39, label %list_read_real_40
list_read_null_39:
  br label %list_read_end_41
list_read_real_40:
  %t157 = bitcast i8* %t155 to { i32*, i64, i64 }*
  %t158 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t157, i32 0, i32 0
  %t159 = load i32*, i32** %t158
  %t160 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t157, i32 0, i32 1
  %t161 = load i64, i64* %t160
  br label %list_read_end_41
list_read_end_41:
  %t162 = phi i32* [ null, %list_read_null_39 ], [ %t159, %list_read_real_40 ]
  %t163 = phi i64 [ 0, %list_read_null_39 ], [ %t161, %list_read_real_40 ]
  %t164 = trunc i64 %t163 to i32
  %t165 = alloca i32
  store i32 0, i32* %t165
  br label %for_cond_42
for_cond_42:
  %t166 = load i32, i32* %t165
  %t167 = icmp slt i32 %t166, %t164
  br i1 %t167, label %for_body_43, label %for_end_45
for_body_43:
  %t168 = load i32, i32* %t165
  %t169 = load i8*, i8** %t0
  %t170 = icmp eq i8* %t169, null
  br i1 %t170, label %list_read_null_46, label %list_read_real_47
list_read_null_46:
  br label %list_read_end_48
list_read_real_47:
  %t171 = bitcast i8* %t169 to { i32*, i64, i64 }*
  %t172 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t171, i32 0, i32 0
  %t173 = load i32*, i32** %t172
  %t174 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t171, i32 0, i32 1
  %t175 = load i64, i64* %t174
  br label %list_read_end_48
list_read_end_48:
  %t176 = phi i32* [ null, %list_read_null_46 ], [ %t173, %list_read_real_47 ]
  %t177 = phi i64 [ 0, %list_read_null_46 ], [ %t175, %list_read_real_47 ]
  %t178 = load i32, i32* %t165
  %t179 = sext i32 %t178 to i64
  %t180 = icmp ult i64 %t179, %t177
  br i1 %t180, label %list_idx_ok_49, label %list_idx_oob_50
list_idx_ok_49:
  %t181 = getelementptr inbounds i32, i32* %t176, i64 %t179
  %t182 = load i32, i32* %t181
  br label %list_idx_end_51
list_idx_oob_50:
  br label %list_idx_end_51
list_idx_end_51:
  %t183 = phi i32 [ %t182, %list_idx_ok_49 ], [ 0, %list_idx_oob_50 ]
  %t184 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t184, i32 %t168, i32 %t183)
  br label %for_step_44
for_step_44:
  %t185 = load i32, i32* %t165
  %t186 = add i32 %t185, 1
  store i32 %t186, i32* %t165
  br label %for_cond_42
for_end_45:
  %t187 = getelementptr i32, i32* null, i32 1
  %t188 = ptrtoint i32* %t187 to i64
  %t189 = load i8*, i8** %t0
  %t190 = icmp eq i8* %t189, null
  br i1 %t190, label %list_cow_alloc_52, label %list_cow_check_53
list_cow_alloc_52:
  %t191 = bitcast void (i8*)* @list_release_i32 to i8*
  %t192 = call i8* @star_rc_alloc(i64 24, i8* %t191)
  %t193 = bitcast i8* %t192 to { i32*, i64, i64 }*
  %t194 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t193, i32 0, i32 0
  store i32* null, i32** %t194
  %t195 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t193, i32 0, i32 1
  store i64 0, i64* %t195
  %t196 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t193, i32 0, i32 2
  store i64 0, i64* %t196
  store i8* %t192, i8** %t0
  br label %list_cow_done_54
list_cow_check_53:
  %t197 = getelementptr inbounds i8, i8* %t189, i64 -16
  %t198 = bitcast i8* %t197 to i64*
  %t199 = load atomic i64, i64* %t198 seq_cst, align 8
  %t200 = icmp eq i64 %t199, 1
  br i1 %t200, label %list_cow_done_54, label %list_cow_clone_55
list_cow_clone_55:
  %t201 = bitcast i8* %t189 to { i32*, i64, i64 }*
  %t202 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t201, i32 0, i32 0
  %t203 = load i32*, i32** %t202
  %t204 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t201, i32 0, i32 1
  %t205 = load i64, i64* %t204
  %t206 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t201, i32 0, i32 2
  %t207 = load i64, i64* %t206
  %t208 = bitcast void (i8*)* @list_release_i32 to i8*
  %t209 = call i8* @star_rc_alloc(i64 24, i8* %t208)
  %t210 = bitcast i8* %t209 to { i32*, i64, i64 }*
  %t211 = mul i64 %t207, %t188
  %t212 = call i8* @malloc(i64 %t211)
  %t213 = bitcast i8* %t212 to i32*
  %t214 = icmp sgt i64 %t205, 0
  br i1 %t214, label %list_cow_copy_56, label %list_cow_after_copy_57
list_cow_copy_56:
  %t215 = mul i64 %t205, %t188
  %t216 = bitcast i32* %t203 to i8*
  call i8* @memcpy(i8* %t212, i8* %t216, i64 %t215)
  br label %list_cow_after_copy_57
list_cow_after_copy_57:
  %t217 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t210, i32 0, i32 0
  store i32* %t213, i32** %t217
  %t218 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t210, i32 0, i32 1
  store i64 %t205, i64* %t218
  %t219 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t210, i32 0, i32 2
  store i64 %t207, i64* %t219
  call void @star_rc_release(i8* %t189)
  store i8* %t209, i8** %t0
  br label %list_cow_done_54
list_cow_done_54:
  %t220 = load i8*, i8** %t0
  %t221 = bitcast i8* %t220 to { i32*, i64, i64 }*
  %t222 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t221, i32 0, i32 0
  %t223 = load i32*, i32** %t222
  %t224 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t221, i32 0, i32 1
  %t225 = load i64, i64* %t224
  %t226 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t221, i32 0, i32 2
  %t227 = sext i32 0 to i64
  %t228 = icmp ult i64 %t227, %t225
  br i1 %t228, label %list_set_do_58, label %list_set_end_59
list_set_do_58:
  %t229 = getelementptr inbounds i32, i32* %t223, i64 %t227
  store i32 100, i32* %t229
  br label %list_set_end_59
list_set_end_59:
  %t230 = load i8*, i8** %t0
  %t231 = icmp eq i8* %t230, null
  br i1 %t231, label %list_read_null_60, label %list_read_real_61
list_read_null_60:
  br label %list_read_end_62
list_read_real_61:
  %t232 = bitcast i8* %t230 to { i32*, i64, i64 }*
  %t233 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t232, i32 0, i32 0
  %t234 = load i32*, i32** %t233
  %t235 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t232, i32 0, i32 1
  %t236 = load i64, i64* %t235
  br label %list_read_end_62
list_read_end_62:
  %t237 = phi i32* [ null, %list_read_null_60 ], [ %t234, %list_read_real_61 ]
  %t238 = phi i64 [ 0, %list_read_null_60 ], [ %t236, %list_read_real_61 ]
  %t239 = sext i32 0 to i64
  %t240 = icmp ult i64 %t239, %t238
  br i1 %t240, label %list_idx_ok_63, label %list_idx_oob_64
list_idx_ok_63:
  %t241 = getelementptr inbounds i32, i32* %t237, i64 %t239
  %t242 = load i32, i32* %t241
  br label %list_idx_end_65
list_idx_oob_64:
  br label %list_idx_end_65
list_idx_end_65:
  %t243 = phi i32 [ %t242, %list_idx_ok_63 ], [ 0, %list_idx_oob_64 ]
  %t244 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t244, i32 %t243)
  %t245 = alloca i32
  %t246 = getelementptr i32, i32* null, i32 1
  %t247 = ptrtoint i32* %t246 to i64
  %t248 = load i8*, i8** %t0
  %t249 = icmp eq i8* %t248, null
  br i1 %t249, label %list_cow_alloc_66, label %list_cow_check_67
list_cow_alloc_66:
  %t250 = bitcast void (i8*)* @list_release_i32 to i8*
  %t251 = call i8* @star_rc_alloc(i64 24, i8* %t250)
  %t252 = bitcast i8* %t251 to { i32*, i64, i64 }*
  %t253 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t252, i32 0, i32 0
  store i32* null, i32** %t253
  %t254 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t252, i32 0, i32 1
  store i64 0, i64* %t254
  %t255 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t252, i32 0, i32 2
  store i64 0, i64* %t255
  store i8* %t251, i8** %t0
  br label %list_cow_done_68
list_cow_check_67:
  %t256 = getelementptr inbounds i8, i8* %t248, i64 -16
  %t257 = bitcast i8* %t256 to i64*
  %t258 = load atomic i64, i64* %t257 seq_cst, align 8
  %t259 = icmp eq i64 %t258, 1
  br i1 %t259, label %list_cow_done_68, label %list_cow_clone_69
list_cow_clone_69:
  %t260 = bitcast i8* %t248 to { i32*, i64, i64 }*
  %t261 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t260, i32 0, i32 0
  %t262 = load i32*, i32** %t261
  %t263 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t260, i32 0, i32 1
  %t264 = load i64, i64* %t263
  %t265 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t260, i32 0, i32 2
  %t266 = load i64, i64* %t265
  %t267 = bitcast void (i8*)* @list_release_i32 to i8*
  %t268 = call i8* @star_rc_alloc(i64 24, i8* %t267)
  %t269 = bitcast i8* %t268 to { i32*, i64, i64 }*
  %t270 = mul i64 %t266, %t247
  %t271 = call i8* @malloc(i64 %t270)
  %t272 = bitcast i8* %t271 to i32*
  %t273 = icmp sgt i64 %t264, 0
  br i1 %t273, label %list_cow_copy_70, label %list_cow_after_copy_71
list_cow_copy_70:
  %t274 = mul i64 %t264, %t247
  %t275 = bitcast i32* %t262 to i8*
  call i8* @memcpy(i8* %t271, i8* %t275, i64 %t274)
  br label %list_cow_after_copy_71
list_cow_after_copy_71:
  %t276 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t269, i32 0, i32 0
  store i32* %t272, i32** %t276
  %t277 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t269, i32 0, i32 1
  store i64 %t264, i64* %t277
  %t278 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t269, i32 0, i32 2
  store i64 %t266, i64* %t278
  call void @star_rc_release(i8* %t248)
  store i8* %t268, i8** %t0
  br label %list_cow_done_68
list_cow_done_68:
  %t279 = load i8*, i8** %t0
  %t280 = bitcast i8* %t279 to { i32*, i64, i64 }*
  %t281 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t280, i32 0, i32 0
  %t282 = load i32*, i32** %t281
  %t283 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t280, i32 0, i32 1
  %t284 = load i64, i64* %t283
  %t285 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t280, i32 0, i32 2
  %t286 = icmp eq i64 %t284, 0
  br i1 %t286, label %list_pop_empty_72, label %list_pop_nonempty_73
list_pop_nonempty_73:
  %t287 = sub i64 %t284, 1
  store i64 %t287, i64* %t283
  %t288 = load i32*, i32** %t281
  %t289 = getelementptr inbounds i32, i32* %t288, i64 %t287
  %t290 = load i32, i32* %t289
  br label %list_pop_end_74
list_pop_empty_72:
  br label %list_pop_end_74
list_pop_end_74:
  %t291 = phi i32 [ %t290, %list_pop_nonempty_73 ], [ 0, %list_pop_empty_72 ]
  store i32 %t291, i32* %t245
  %t292 = load i32, i32* %t245
  %t293 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t293, i32 %t292)
  %t294 = load i8*, i8** %t0
  %t295 = icmp eq i8* %t294, null
  br i1 %t295, label %list_read_null_75, label %list_read_real_76
list_read_null_75:
  br label %list_read_end_77
list_read_real_76:
  %t296 = bitcast i8* %t294 to { i32*, i64, i64 }*
  %t297 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t296, i32 0, i32 0
  %t298 = load i32*, i32** %t297
  %t299 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t296, i32 0, i32 1
  %t300 = load i64, i64* %t299
  br label %list_read_end_77
list_read_end_77:
  %t301 = phi i32* [ null, %list_read_null_75 ], [ %t298, %list_read_real_76 ]
  %t302 = phi i64 [ 0, %list_read_null_75 ], [ %t300, %list_read_real_76 ]
  %t303 = trunc i64 %t302 to i32
  %t304 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t304, i32 %t303)
  %t305 = load i8*, i8** %t0
  %t306 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t306)
  %t307 = call i32 @sum_list(i8* %t305)
  %t308 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t308, i32 %t307)
  %t309 = alloca i8*
  store i8* null, i8** %t309
  %t310 = load i8*, i8** %t309
  %t311 = icmp eq i8* %t310, null
  br i1 %t311, label %list_read_null_78, label %list_read_real_79
list_read_null_78:
  br label %list_read_end_80
list_read_real_79:
  %t312 = bitcast i8* %t310 to { i32*, i64, i64 }*
  %t313 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t312, i32 0, i32 0
  %t314 = load i32*, i32** %t313
  %t315 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t312, i32 0, i32 1
  %t316 = load i64, i64* %t315
  br label %list_read_end_80
list_read_end_80:
  %t317 = phi i32* [ null, %list_read_null_78 ], [ %t314, %list_read_real_79 ]
  %t318 = phi i64 [ 0, %list_read_null_78 ], [ %t316, %list_read_real_79 ]
  %t319 = trunc i64 %t318 to i32
  %t320 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t320, i32 %t319)
  %t321 = alloca i32
  %t322 = getelementptr i32, i32* null, i32 1
  %t323 = ptrtoint i32* %t322 to i64
  %t324 = load i8*, i8** %t309
  %t325 = icmp eq i8* %t324, null
  br i1 %t325, label %list_cow_alloc_81, label %list_cow_check_82
list_cow_alloc_81:
  %t326 = bitcast void (i8*)* @list_release_i32 to i8*
  %t327 = call i8* @star_rc_alloc(i64 24, i8* %t326)
  %t328 = bitcast i8* %t327 to { i32*, i64, i64 }*
  %t329 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t328, i32 0, i32 0
  store i32* null, i32** %t329
  %t330 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t328, i32 0, i32 1
  store i64 0, i64* %t330
  %t331 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t328, i32 0, i32 2
  store i64 0, i64* %t331
  store i8* %t327, i8** %t309
  br label %list_cow_done_83
list_cow_check_82:
  %t332 = getelementptr inbounds i8, i8* %t324, i64 -16
  %t333 = bitcast i8* %t332 to i64*
  %t334 = load atomic i64, i64* %t333 seq_cst, align 8
  %t335 = icmp eq i64 %t334, 1
  br i1 %t335, label %list_cow_done_83, label %list_cow_clone_84
list_cow_clone_84:
  %t336 = bitcast i8* %t324 to { i32*, i64, i64 }*
  %t337 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t336, i32 0, i32 0
  %t338 = load i32*, i32** %t337
  %t339 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t336, i32 0, i32 1
  %t340 = load i64, i64* %t339
  %t341 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t336, i32 0, i32 2
  %t342 = load i64, i64* %t341
  %t343 = bitcast void (i8*)* @list_release_i32 to i8*
  %t344 = call i8* @star_rc_alloc(i64 24, i8* %t343)
  %t345 = bitcast i8* %t344 to { i32*, i64, i64 }*
  %t346 = mul i64 %t342, %t323
  %t347 = call i8* @malloc(i64 %t346)
  %t348 = bitcast i8* %t347 to i32*
  %t349 = icmp sgt i64 %t340, 0
  br i1 %t349, label %list_cow_copy_85, label %list_cow_after_copy_86
list_cow_copy_85:
  %t350 = mul i64 %t340, %t323
  %t351 = bitcast i32* %t338 to i8*
  call i8* @memcpy(i8* %t347, i8* %t351, i64 %t350)
  br label %list_cow_after_copy_86
list_cow_after_copy_86:
  %t352 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t345, i32 0, i32 0
  store i32* %t348, i32** %t352
  %t353 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t345, i32 0, i32 1
  store i64 %t340, i64* %t353
  %t354 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t345, i32 0, i32 2
  store i64 %t342, i64* %t354
  call void @star_rc_release(i8* %t324)
  store i8* %t344, i8** %t309
  br label %list_cow_done_83
list_cow_done_83:
  %t355 = load i8*, i8** %t309
  %t356 = bitcast i8* %t355 to { i32*, i64, i64 }*
  %t357 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t356, i32 0, i32 0
  %t358 = load i32*, i32** %t357
  %t359 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t356, i32 0, i32 1
  %t360 = load i64, i64* %t359
  %t361 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t356, i32 0, i32 2
  %t362 = icmp eq i64 %t360, 0
  br i1 %t362, label %list_pop_empty_87, label %list_pop_nonempty_88
list_pop_nonempty_88:
  %t363 = sub i64 %t360, 1
  store i64 %t363, i64* %t359
  %t364 = load i32*, i32** %t357
  %t365 = getelementptr inbounds i32, i32* %t364, i64 %t363
  %t366 = load i32, i32* %t365
  br label %list_pop_end_89
list_pop_empty_87:
  br label %list_pop_end_89
list_pop_end_89:
  %t367 = phi i32 [ %t366, %list_pop_nonempty_88 ], [ 0, %list_pop_empty_87 ]
  store i32 %t367, i32* %t321
  %t368 = load i32, i32* %t321
  %t369 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t369, i32 %t368)
  %t370 = alloca i32
  %t371 = load i8*, i8** %t309
  %t372 = icmp eq i8* %t371, null
  br i1 %t372, label %list_read_null_90, label %list_read_real_91
list_read_null_90:
  br label %list_read_end_92
list_read_real_91:
  %t373 = bitcast i8* %t371 to { i32*, i64, i64 }*
  %t374 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t373, i32 0, i32 0
  %t375 = load i32*, i32** %t374
  %t376 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t373, i32 0, i32 1
  %t377 = load i64, i64* %t376
  br label %list_read_end_92
list_read_end_92:
  %t378 = phi i32* [ null, %list_read_null_90 ], [ %t375, %list_read_real_91 ]
  %t379 = phi i64 [ 0, %list_read_null_90 ], [ %t377, %list_read_real_91 ]
  %t380 = sext i32 0 to i64
  %t381 = icmp ult i64 %t380, %t379
  br i1 %t381, label %list_idx_ok_93, label %list_idx_oob_94
list_idx_ok_93:
  %t382 = getelementptr inbounds i32, i32* %t378, i64 %t380
  %t383 = load i32, i32* %t382
  br label %list_idx_end_95
list_idx_oob_94:
  br label %list_idx_end_95
list_idx_end_95:
  %t384 = phi i32 [ %t383, %list_idx_ok_93 ], [ 0, %list_idx_oob_94 ]
  store i32 %t384, i32* %t370
  %t385 = load i32, i32* %t370
  %t386 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t386, i32 %t385)
  %t387 = alloca i8*
  store i8* null, i8** %t387
  %t388 = alloca i32
  store i32 0, i32* %t388
  br label %while_cond_96
while_cond_96:
  %t389 = load i32, i32* %t388
  %t390 = icmp slt i32 %t389, 20
  br i1 %t390, label %while_body_97, label %while_end_99
while_body_97:
  %t391 = getelementptr i32, i32* null, i32 1
  %t392 = ptrtoint i32* %t391 to i64
  %t393 = load i8*, i8** %t387
  %t394 = icmp eq i8* %t393, null
  br i1 %t394, label %list_cow_alloc_100, label %list_cow_check_101
list_cow_alloc_100:
  %t395 = bitcast void (i8*)* @list_release_i32 to i8*
  %t396 = call i8* @star_rc_alloc(i64 24, i8* %t395)
  %t397 = bitcast i8* %t396 to { i32*, i64, i64 }*
  %t398 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t397, i32 0, i32 0
  store i32* null, i32** %t398
  %t399 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t397, i32 0, i32 1
  store i64 0, i64* %t399
  %t400 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t397, i32 0, i32 2
  store i64 0, i64* %t400
  store i8* %t396, i8** %t387
  br label %list_cow_done_102
list_cow_check_101:
  %t401 = getelementptr inbounds i8, i8* %t393, i64 -16
  %t402 = bitcast i8* %t401 to i64*
  %t403 = load atomic i64, i64* %t402 seq_cst, align 8
  %t404 = icmp eq i64 %t403, 1
  br i1 %t404, label %list_cow_done_102, label %list_cow_clone_103
list_cow_clone_103:
  %t405 = bitcast i8* %t393 to { i32*, i64, i64 }*
  %t406 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t405, i32 0, i32 0
  %t407 = load i32*, i32** %t406
  %t408 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t405, i32 0, i32 1
  %t409 = load i64, i64* %t408
  %t410 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t405, i32 0, i32 2
  %t411 = load i64, i64* %t410
  %t412 = bitcast void (i8*)* @list_release_i32 to i8*
  %t413 = call i8* @star_rc_alloc(i64 24, i8* %t412)
  %t414 = bitcast i8* %t413 to { i32*, i64, i64 }*
  %t415 = mul i64 %t411, %t392
  %t416 = call i8* @malloc(i64 %t415)
  %t417 = bitcast i8* %t416 to i32*
  %t418 = icmp sgt i64 %t409, 0
  br i1 %t418, label %list_cow_copy_104, label %list_cow_after_copy_105
list_cow_copy_104:
  %t419 = mul i64 %t409, %t392
  %t420 = bitcast i32* %t407 to i8*
  call i8* @memcpy(i8* %t416, i8* %t420, i64 %t419)
  br label %list_cow_after_copy_105
list_cow_after_copy_105:
  %t421 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t414, i32 0, i32 0
  store i32* %t417, i32** %t421
  %t422 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t414, i32 0, i32 1
  store i64 %t409, i64* %t422
  %t423 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t414, i32 0, i32 2
  store i64 %t411, i64* %t423
  call void @star_rc_release(i8* %t393)
  store i8* %t413, i8** %t387
  br label %list_cow_done_102
list_cow_done_102:
  %t424 = load i8*, i8** %t387
  %t425 = bitcast i8* %t424 to { i32*, i64, i64 }*
  %t426 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t425, i32 0, i32 0
  %t427 = load i32*, i32** %t426
  %t428 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t425, i32 0, i32 1
  %t429 = load i64, i64* %t428
  %t430 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t425, i32 0, i32 2
  %t431 = load i32, i32* %t388
  %t432 = load i64, i64* %t430
  %t433 = load i32*, i32** %t426
  %t434 = icmp sge i64 %t429, %t432
  br i1 %t434, label %list_push_grow_106, label %list_push_store_107
list_push_grow_106:
  %t435 = mul i64 %t432, 2
  %t436 = icmp sgt i64 %t435, 0
  %t437 = select i1 %t436, i64 %t435, i64 1
  %t438 = getelementptr i32, i32* null, i32 1
  %t439 = ptrtoint i32* %t438 to i64
  %t440 = mul i64 %t437, %t439
  %t441 = call i8* @malloc(i64 %t440)
  %t442 = bitcast i8* %t441 to i32*
  %t443 = icmp sgt i64 %t432, 0
  br i1 %t443, label %list_push_copy_108, label %list_push_after_copy_109
list_push_copy_108:
  %t444 = mul i64 %t429, %t439
  %t445 = bitcast i32* %t433 to i8*
  call i8* @memcpy(i8* %t441, i8* %t445, i64 %t444)
  call void @free(i8* %t445)
  br label %list_push_after_copy_109
list_push_after_copy_109:
  store i32* %t442, i32** %t426
  store i64 %t437, i64* %t430
  br label %list_push_store_107
list_push_store_107:
  %t446 = load i32*, i32** %t426
  %t447 = getelementptr inbounds i32, i32* %t446, i64 %t429
  store i32 %t431, i32* %t447
  %t448 = add i64 %t429, 1
  store i64 %t448, i64* %t428
  %t449 = load i32, i32* %t388
  %t450 = add i32 %t449, 1
  store i32 %t450, i32* %t388
  br label %while_cond_96
while_else_98:
  br label %while_end_99
while_end_99:
  %t451 = load i8*, i8** %t387
  %t452 = icmp eq i8* %t451, null
  br i1 %t452, label %list_read_null_110, label %list_read_real_111
list_read_null_110:
  br label %list_read_end_112
list_read_real_111:
  %t453 = bitcast i8* %t451 to { i32*, i64, i64 }*
  %t454 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t453, i32 0, i32 0
  %t455 = load i32*, i32** %t454
  %t456 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t453, i32 0, i32 1
  %t457 = load i64, i64* %t456
  br label %list_read_end_112
list_read_end_112:
  %t458 = phi i32* [ null, %list_read_null_110 ], [ %t455, %list_read_real_111 ]
  %t459 = phi i64 [ 0, %list_read_null_110 ], [ %t457, %list_read_real_111 ]
  %t460 = trunc i64 %t459 to i32
  %t461 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t461, i32 %t460)
  %t462 = load i8*, i8** %t387
  %t463 = icmp eq i8* %t462, null
  br i1 %t463, label %list_read_null_113, label %list_read_real_114
list_read_null_113:
  br label %list_read_end_115
list_read_real_114:
  %t464 = bitcast i8* %t462 to { i32*, i64, i64 }*
  %t465 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t464, i32 0, i32 0
  %t466 = load i32*, i32** %t465
  %t467 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t464, i32 0, i32 1
  %t468 = load i64, i64* %t467
  br label %list_read_end_115
list_read_end_115:
  %t469 = phi i32* [ null, %list_read_null_113 ], [ %t466, %list_read_real_114 ]
  %t470 = phi i64 [ 0, %list_read_null_113 ], [ %t468, %list_read_real_114 ]
  %t471 = sext i32 19 to i64
  %t472 = icmp ult i64 %t471, %t470
  br i1 %t472, label %list_idx_ok_116, label %list_idx_oob_117
list_idx_ok_116:
  %t473 = getelementptr inbounds i32, i32* %t469, i64 %t471
  %t474 = load i32, i32* %t473
  br label %list_idx_end_118
list_idx_oob_117:
  br label %list_idx_end_118
list_idx_end_118:
  %t475 = phi i32 [ %t474, %list_idx_ok_116 ], [ 0, %list_idx_oob_117 ]
  %t476 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t476, i32 %t475)
  %t477 = load i8*, i8** %t387
  %t478 = icmp eq i8* %t477, null
  br i1 %t478, label %list_read_null_119, label %list_read_real_120
list_read_null_119:
  br label %list_read_end_121
list_read_real_120:
  %t479 = bitcast i8* %t477 to { i32*, i64, i64 }*
  %t480 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t479, i32 0, i32 0
  %t481 = load i32*, i32** %t480
  %t482 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t479, i32 0, i32 1
  %t483 = load i64, i64* %t482
  br label %list_read_end_121
list_read_end_121:
  %t484 = phi i32* [ null, %list_read_null_119 ], [ %t481, %list_read_real_120 ]
  %t485 = phi i64 [ 0, %list_read_null_119 ], [ %t483, %list_read_real_120 ]
  %t486 = sext i32 0 to i64
  %t487 = icmp ult i64 %t486, %t485
  br i1 %t487, label %list_idx_ok_122, label %list_idx_oob_123
list_idx_ok_122:
  %t488 = getelementptr inbounds i32, i32* %t484, i64 %t486
  %t489 = load i32, i32* %t488
  br label %list_idx_end_124
list_idx_oob_123:
  br label %list_idx_end_124
list_idx_end_124:
  %t490 = phi i32 [ %t489, %list_idx_ok_122 ], [ 0, %list_idx_oob_123 ]
  %t491 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t491, i32 %t490)
  %t492 = alloca i8*
  %t493 = getelementptr i8*, i8** null, i32 1
  %t494 = ptrtoint i8** %t493 to i64
  %t495 = mul i64 %t494, 3
  %t496 = call i8* @malloc(i64 %t495)
  %t497 = bitcast i8* %t496 to i8**
  %t498 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t499 = getelementptr inbounds i8*, i8** %t497, i64 0
  store i8* %t498, i8** %t499
  %t500 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t501 = getelementptr inbounds i8*, i8** %t497, i64 1
  store i8* %t500, i8** %t501
  %t502 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t503 = getelementptr inbounds i8*, i8** %t497, i64 2
  store i8* %t502, i8** %t503
  %t516 = bitcast void (i8*)* @list_release_str to i8*
  %t517 = call i8* @star_rc_alloc(i64 24, i8* %t516)
  %t518 = bitcast i8* %t517 to { i8**, i64, i64 }*
  %t519 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t518, i32 0, i32 0
  store i8** %t497, i8*** %t519
  %t520 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t518, i32 0, i32 1
  store i64 3, i64* %t520
  %t521 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t518, i32 0, i32 2
  store i64 3, i64* %t521
  store i8* %t517, i8** %t492
  %t522 = load i8*, i8** %t492
  %t523 = icmp eq i8* %t522, null
  br i1 %t523, label %list_read_null_128, label %list_read_real_129
list_read_null_128:
  br label %list_read_end_130
list_read_real_129:
  %t524 = bitcast i8* %t522 to { i8**, i64, i64 }*
  %t525 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t524, i32 0, i32 0
  %t526 = load i8**, i8*** %t525
  %t527 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t524, i32 0, i32 1
  %t528 = load i64, i64* %t527
  br label %list_read_end_130
list_read_end_130:
  %t529 = phi i8** [ null, %list_read_null_128 ], [ %t526, %list_read_real_129 ]
  %t530 = phi i64 [ 0, %list_read_null_128 ], [ %t528, %list_read_real_129 ]
  %t531 = trunc i64 %t530 to i32
  %t532 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t532, i32 %t531)
  %t533 = load i8*, i8** %t492
  %t534 = icmp eq i8* %t533, null
  br i1 %t534, label %list_read_null_131, label %list_read_real_132
list_read_null_131:
  br label %list_read_end_133
list_read_real_132:
  %t535 = bitcast i8* %t533 to { i8**, i64, i64 }*
  %t536 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t535, i32 0, i32 0
  %t537 = load i8**, i8*** %t536
  %t538 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t535, i32 0, i32 1
  %t539 = load i64, i64* %t538
  br label %list_read_end_133
list_read_end_133:
  %t540 = phi i8** [ null, %list_read_null_131 ], [ %t537, %list_read_real_132 ]
  %t541 = phi i64 [ 0, %list_read_null_131 ], [ %t539, %list_read_real_132 ]
  %t542 = sext i32 1 to i64
  %t543 = icmp ult i64 %t542, %t541
  br i1 %t543, label %list_idx_ok_134, label %list_idx_oob_135
list_idx_ok_134:
  %t544 = getelementptr inbounds i8*, i8** %t540, i64 %t542
  %t545 = load i8*, i8** %t544
  %t546 = load i8*, i8** %t544
  call void @star_rc_retain(i8* %t546)
  br label %list_idx_end_136
list_idx_oob_135:
  br label %list_idx_end_136
list_idx_end_136:
  %t547 = phi i8* [ %t545, %list_idx_ok_134 ], [ null, %list_idx_oob_135 ]
  call void @star_rc_release(i8* %t547)
  %t548 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t548, i8* %t547)
  %t549 = alloca i8*
  %t550 = getelementptr %Point, %Point* null, i32 1
  %t551 = ptrtoint %Point* %t550 to i64
  %t552 = mul i64 %t551, 2
  %t553 = call i8* @malloc(i64 %t552)
  %t554 = bitcast i8* %t553 to %Point*
  %t555 = alloca %Point
  %t556 = getelementptr inbounds %Point, %Point* %t555, i32 0, i32 0
  store i32 1, i32* %t556
  %t557 = getelementptr inbounds %Point, %Point* %t555, i32 0, i32 1
  store i32 2, i32* %t557
  %t558 = load %Point, %Point* %t555
  %t559 = getelementptr inbounds %Point, %Point* %t554, i64 0
  store %Point %t558, %Point* %t559
  %t560 = alloca %Point
  %t561 = getelementptr inbounds %Point, %Point* %t560, i32 0, i32 0
  store i32 3, i32* %t561
  %t562 = getelementptr inbounds %Point, %Point* %t560, i32 0, i32 1
  store i32 4, i32* %t562
  %t563 = load %Point, %Point* %t560
  %t564 = getelementptr inbounds %Point, %Point* %t554, i64 1
  store %Point %t563, %Point* %t564
  %t569 = bitcast void (i8*)* @list_release_s_Point to i8*
  %t570 = call i8* @star_rc_alloc(i64 24, i8* %t569)
  %t571 = bitcast i8* %t570 to { %Point*, i64, i64 }*
  %t572 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t571, i32 0, i32 0
  store %Point* %t554, %Point** %t572
  %t573 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t571, i32 0, i32 1
  store i64 2, i64* %t573
  %t574 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t571, i32 0, i32 2
  store i64 2, i64* %t574
  store i8* %t570, i8** %t549
  %t575 = alloca %Point
  %t576 = load i8*, i8** %t549
  %t577 = icmp eq i8* %t576, null
  br i1 %t577, label %list_read_null_137, label %list_read_real_138
list_read_null_137:
  br label %list_read_end_139
list_read_real_138:
  %t578 = bitcast i8* %t576 to { %Point*, i64, i64 }*
  %t579 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t578, i32 0, i32 0
  %t580 = load %Point*, %Point** %t579
  %t581 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t578, i32 0, i32 1
  %t582 = load i64, i64* %t581
  br label %list_read_end_139
list_read_end_139:
  %t583 = phi %Point* [ null, %list_read_null_137 ], [ %t580, %list_read_real_138 ]
  %t584 = phi i64 [ 0, %list_read_null_137 ], [ %t582, %list_read_real_138 ]
  %t585 = sext i32 1 to i64
  %t586 = icmp ult i64 %t585, %t584
  br i1 %t586, label %list_idx_ok_140, label %list_idx_oob_141
list_idx_ok_140:
  %t587 = getelementptr inbounds %Point, %Point* %t583, i64 %t585
  %t588 = load %Point, %Point* %t587
  br label %list_idx_end_142
list_idx_oob_141:
  br label %list_idx_end_142
list_idx_end_142:
  %t589 = phi %Point [ %t588, %list_idx_ok_140 ], [ zeroinitializer, %list_idx_oob_141 ]
  store %Point %t589, %Point* %t575
  %t590 = getelementptr inbounds %Point, %Point* %t575, i32 0, i32 0
  %t591 = load i32, i32* %t590
  %t592 = getelementptr inbounds %Point, %Point* %t575, i32 0, i32 1
  %t593 = load i32, i32* %t592
  %t594 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.18, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t594, i32 %t591, i32 %t593)
  %t595 = load i8*, i8** %t549
  call void @star_rc_release(i8* %t595)
  %t596 = load i8*, i8** %t492
  call void @star_rc_release(i8* %t596)
  %t597 = load i8*, i8** %t387
  call void @star_rc_release(i8* %t597)
  %t598 = load i8*, i8** %t309
  call void @star_rc_release(i8* %t598)
  %t599 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t599)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_i32(i8* %objp) {
entry:
  %t9 = bitcast i8* %objp to { i32*, i64, i64 }*
  %t10 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t9, i32 0, i32 0
  %t11 = load i32*, i32** %t10
  %t12 = bitcast i32* %t11 to i8*
  call void @free(i8* %t12)
  ret void
}


define void @list_release_str(i8* %objp) {
entry:
  %t504 = bitcast i8* %objp to { i8**, i64, i64 }*
  %t505 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t504, i32 0, i32 0
  %t506 = load i8**, i8*** %t505
  %t507 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t504, i32 0, i32 1
  %t508 = load i64, i64* %t507
  %t509 = alloca i64
  store i64 0, i64* %t509
  br label %list_release_cond_125
list_release_cond_125:
  %t510 = load i64, i64* %t509
  %t511 = icmp slt i64 %t510, %t508
  br i1 %t511, label %list_release_body_126, label %list_release_end_127
list_release_body_126:
  %t512 = getelementptr inbounds i8*, i8** %t506, i64 %t510
  %t513 = load i8*, i8** %t512
  call void @star_rc_release(i8* %t513)
  %t514 = add i64 %t510, 1
  store i64 %t514, i64* %t509
  br label %list_release_cond_125
list_release_end_127:
  %t515 = bitcast i8** %t506 to i8*
  call void @free(i8* %t515)
  ret void
}


define void @list_release_s_Point(i8* %objp) {
entry:
  %t565 = bitcast i8* %objp to { %Point*, i64, i64 }*
  %t566 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t565, i32 0, i32 0
  %t567 = load %Point*, %Point** %t566
  %t568 = bitcast %Point* %t567 to i8*
  call void @free(i8* %t568)
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
