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

%Point = type { i32, i32 }
define i32 @sum_list(i8* %nums) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i32
  %t2 = alloca i32
  store i8* %nums, i8** %t0
  store i32 0, i32* %t1
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
  br i1 %t14, label %while_body_1, label %while_else_2
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
  %t1 = alloca i8*
  %t168 = alloca i32
  %t248 = alloca i32
  %t312 = alloca i8*
  %t324 = alloca i32
  %t373 = alloca i32
  %t390 = alloca i8*
  %t391 = alloca i32
  %t496 = alloca i8*
  %t553 = alloca i8*
  %t559 = alloca %Point
  %t564 = alloca %Point
  %t579 = alloca %Point
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t2 = getelementptr i32, i32* null, i32 1
  %t3 = ptrtoint i32* %t2 to i64
  %t4 = mul i64 %t3, 3
  %t5 = call i8* @malloc(i64 %t4)
  %t6 = bitcast i8* %t5 to i32*
  %t7 = getelementptr inbounds i32, i32* %t6, i64 0
  store i32 1, i32* %t7
  %t8 = getelementptr inbounds i32, i32* %t6, i64 1
  store i32 2, i32* %t8
  %t9 = getelementptr inbounds i32, i32* %t6, i64 2
  store i32 3, i32* %t9
  %t14 = bitcast void (i8*)* @list_release_i32 to i8*
  %t15 = call i8* @star_rc_alloc(i64 24, i8* %t14)
  %t16 = bitcast i8* %t15 to { i32*, i64, i64 }*
  %t17 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t16, i32 0, i32 0
  store i32* %t6, i32** %t17
  %t18 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t16, i32 0, i32 1
  store i64 3, i64* %t18
  %t19 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t16, i32 0, i32 2
  store i64 3, i64* %t19
  store i8* %t15, i8** %t1
  %t20 = load i8*, i8** %t1
  %t21 = icmp eq i8* %t20, null
  br i1 %t21, label %list_read_null_13, label %list_read_real_14
list_read_null_13:
  br label %list_read_end_15
list_read_real_14:
  %t22 = bitcast i8* %t20 to { i32*, i64, i64 }*
  %t23 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t22, i32 0, i32 0
  %t24 = load i32*, i32** %t23
  %t25 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t22, i32 0, i32 1
  %t26 = load i64, i64* %t25
  br label %list_read_end_15
list_read_end_15:
  %t27 = phi i32* [ null, %list_read_null_13 ], [ %t24, %list_read_real_14 ]
  %t28 = phi i64 [ 0, %list_read_null_13 ], [ %t26, %list_read_real_14 ]
  %t29 = trunc i64 %t28 to i32
  %t30 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t30, i32 %t29)
  %t31 = getelementptr i32, i32* null, i32 1
  %t32 = ptrtoint i32* %t31 to i64
  %t33 = load i8*, i8** %t1
  %t34 = icmp eq i8* %t33, null
  br i1 %t34, label %list_cow_alloc_16, label %list_cow_check_17
list_cow_alloc_16:
  %t35 = bitcast void (i8*)* @list_release_i32 to i8*
  %t36 = call i8* @star_rc_alloc(i64 24, i8* %t35)
  %t37 = bitcast i8* %t36 to { i32*, i64, i64 }*
  %t38 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t37, i32 0, i32 0
  store i32* null, i32** %t38
  %t39 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t37, i32 0, i32 1
  store i64 0, i64* %t39
  %t40 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t37, i32 0, i32 2
  store i64 0, i64* %t40
  store i8* %t36, i8** %t1
  br label %list_cow_done_18
list_cow_check_17:
  %t41 = getelementptr inbounds i8, i8* %t33, i64 -16
  %t42 = bitcast i8* %t41 to i64*
  %t43 = load atomic i64, i64* %t42 seq_cst, align 8
  %t44 = icmp eq i64 %t43, 1
  br i1 %t44, label %list_cow_done_18, label %list_cow_clone_19
list_cow_clone_19:
  %t45 = bitcast i8* %t33 to { i32*, i64, i64 }*
  %t46 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t45, i32 0, i32 0
  %t47 = load i32*, i32** %t46
  %t48 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t45, i32 0, i32 1
  %t49 = load i64, i64* %t48
  %t50 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t45, i32 0, i32 2
  %t51 = load i64, i64* %t50
  %t52 = bitcast void (i8*)* @list_release_i32 to i8*
  %t53 = call i8* @star_rc_alloc(i64 24, i8* %t52)
  %t54 = bitcast i8* %t53 to { i32*, i64, i64 }*
  %t55 = mul i64 %t51, %t32
  %t56 = call i8* @malloc(i64 %t55)
  %t57 = bitcast i8* %t56 to i32*
  %t58 = icmp sgt i64 %t49, 0
  br i1 %t58, label %list_cow_copy_20, label %list_cow_after_copy_21
list_cow_copy_20:
  %t59 = mul i64 %t49, %t32
  %t60 = bitcast i32* %t47 to i8*
  call i8* @memcpy(i8* %t56, i8* %t60, i64 %t59)
  br label %list_cow_after_copy_21
list_cow_after_copy_21:
  %t61 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t54, i32 0, i32 0
  store i32* %t57, i32** %t61
  %t62 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t54, i32 0, i32 1
  store i64 %t49, i64* %t62
  %t63 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t54, i32 0, i32 2
  store i64 %t51, i64* %t63
  call void @star_rc_release(i8* %t33)
  store i8* %t53, i8** %t1
  br label %list_cow_done_18
list_cow_done_18:
  %t64 = load i8*, i8** %t1
  %t65 = bitcast i8* %t64 to { i32*, i64, i64 }*
  %t66 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t65, i32 0, i32 0
  %t67 = load i32*, i32** %t66
  %t68 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t65, i32 0, i32 1
  %t69 = load i64, i64* %t68
  %t70 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t65, i32 0, i32 2
  %t71 = load i64, i64* %t70
  %t72 = load i32*, i32** %t66
  %t73 = load i64, i64* %t68
  %t74 = icmp sge i64 %t73, %t71
  br i1 %t74, label %list_push_grow_22, label %list_push_store_23
list_push_grow_22:
  %t75 = mul i64 %t71, 2
  %t76 = icmp sgt i64 %t75, 0
  %t77 = select i1 %t76, i64 %t75, i64 1
  %t78 = getelementptr i32, i32* null, i32 1
  %t79 = ptrtoint i32* %t78 to i64
  %t80 = mul i64 %t77, %t79
  %t81 = call i8* @malloc(i64 %t80)
  %t82 = bitcast i8* %t81 to i32*
  %t83 = icmp sgt i64 %t71, 0
  br i1 %t83, label %list_push_copy_24, label %list_push_after_copy_25
list_push_copy_24:
  %t84 = mul i64 %t73, %t79
  %t85 = bitcast i32* %t72 to i8*
  call i8* @memcpy(i8* %t81, i8* %t85, i64 %t84)
  call void @free(i8* %t85)
  br label %list_push_after_copy_25
list_push_after_copy_25:
  store i32* %t82, i32** %t66
  store i64 %t77, i64* %t70
  br label %list_push_store_23
list_push_store_23:
  %t86 = load i32*, i32** %t66
  %t87 = getelementptr inbounds i32, i32* %t86, i64 %t73
  store i32 4, i32* %t87
  %t88 = add i64 %t73, 1
  store i64 %t88, i64* %t68
  %t89 = getelementptr i32, i32* null, i32 1
  %t90 = ptrtoint i32* %t89 to i64
  %t91 = load i8*, i8** %t1
  %t92 = icmp eq i8* %t91, null
  br i1 %t92, label %list_cow_alloc_26, label %list_cow_check_27
list_cow_alloc_26:
  %t93 = bitcast void (i8*)* @list_release_i32 to i8*
  %t94 = call i8* @star_rc_alloc(i64 24, i8* %t93)
  %t95 = bitcast i8* %t94 to { i32*, i64, i64 }*
  %t96 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t95, i32 0, i32 0
  store i32* null, i32** %t96
  %t97 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t95, i32 0, i32 1
  store i64 0, i64* %t97
  %t98 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t95, i32 0, i32 2
  store i64 0, i64* %t98
  store i8* %t94, i8** %t1
  br label %list_cow_done_28
list_cow_check_27:
  %t99 = getelementptr inbounds i8, i8* %t91, i64 -16
  %t100 = bitcast i8* %t99 to i64*
  %t101 = load atomic i64, i64* %t100 seq_cst, align 8
  %t102 = icmp eq i64 %t101, 1
  br i1 %t102, label %list_cow_done_28, label %list_cow_clone_29
list_cow_clone_29:
  %t103 = bitcast i8* %t91 to { i32*, i64, i64 }*
  %t104 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t103, i32 0, i32 0
  %t105 = load i32*, i32** %t104
  %t106 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t103, i32 0, i32 1
  %t107 = load i64, i64* %t106
  %t108 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t103, i32 0, i32 2
  %t109 = load i64, i64* %t108
  %t110 = bitcast void (i8*)* @list_release_i32 to i8*
  %t111 = call i8* @star_rc_alloc(i64 24, i8* %t110)
  %t112 = bitcast i8* %t111 to { i32*, i64, i64 }*
  %t113 = mul i64 %t109, %t90
  %t114 = call i8* @malloc(i64 %t113)
  %t115 = bitcast i8* %t114 to i32*
  %t116 = icmp sgt i64 %t107, 0
  br i1 %t116, label %list_cow_copy_30, label %list_cow_after_copy_31
list_cow_copy_30:
  %t117 = mul i64 %t107, %t90
  %t118 = bitcast i32* %t105 to i8*
  call i8* @memcpy(i8* %t114, i8* %t118, i64 %t117)
  br label %list_cow_after_copy_31
list_cow_after_copy_31:
  %t119 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t112, i32 0, i32 0
  store i32* %t115, i32** %t119
  %t120 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t112, i32 0, i32 1
  store i64 %t107, i64* %t120
  %t121 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t112, i32 0, i32 2
  store i64 %t109, i64* %t121
  call void @star_rc_release(i8* %t91)
  store i8* %t111, i8** %t1
  br label %list_cow_done_28
list_cow_done_28:
  %t122 = load i8*, i8** %t1
  %t123 = bitcast i8* %t122 to { i32*, i64, i64 }*
  %t124 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t123, i32 0, i32 0
  %t125 = load i32*, i32** %t124
  %t126 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t123, i32 0, i32 1
  %t127 = load i64, i64* %t126
  %t128 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t123, i32 0, i32 2
  %t129 = load i64, i64* %t128
  %t130 = load i32*, i32** %t124
  %t131 = load i64, i64* %t126
  %t132 = icmp sge i64 %t131, %t129
  br i1 %t132, label %list_push_grow_32, label %list_push_store_33
list_push_grow_32:
  %t133 = mul i64 %t129, 2
  %t134 = icmp sgt i64 %t133, 0
  %t135 = select i1 %t134, i64 %t133, i64 1
  %t136 = getelementptr i32, i32* null, i32 1
  %t137 = ptrtoint i32* %t136 to i64
  %t138 = mul i64 %t135, %t137
  %t139 = call i8* @malloc(i64 %t138)
  %t140 = bitcast i8* %t139 to i32*
  %t141 = icmp sgt i64 %t129, 0
  br i1 %t141, label %list_push_copy_34, label %list_push_after_copy_35
list_push_copy_34:
  %t142 = mul i64 %t131, %t137
  %t143 = bitcast i32* %t130 to i8*
  call i8* @memcpy(i8* %t139, i8* %t143, i64 %t142)
  call void @free(i8* %t143)
  br label %list_push_after_copy_35
list_push_after_copy_35:
  store i32* %t140, i32** %t124
  store i64 %t135, i64* %t128
  br label %list_push_store_33
list_push_store_33:
  %t144 = load i32*, i32** %t124
  %t145 = getelementptr inbounds i32, i32* %t144, i64 %t131
  store i32 5, i32* %t145
  %t146 = add i64 %t131, 1
  store i64 %t146, i64* %t126
  %t147 = load i8*, i8** %t1
  %t148 = icmp eq i8* %t147, null
  br i1 %t148, label %list_read_null_36, label %list_read_real_37
list_read_null_36:
  br label %list_read_end_38
list_read_real_37:
  %t149 = bitcast i8* %t147 to { i32*, i64, i64 }*
  %t150 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t149, i32 0, i32 0
  %t151 = load i32*, i32** %t150
  %t152 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t149, i32 0, i32 1
  %t153 = load i64, i64* %t152
  br label %list_read_end_38
list_read_end_38:
  %t154 = phi i32* [ null, %list_read_null_36 ], [ %t151, %list_read_real_37 ]
  %t155 = phi i64 [ 0, %list_read_null_36 ], [ %t153, %list_read_real_37 ]
  %t156 = trunc i64 %t155 to i32
  %t157 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t157, i32 %t156)
  %t158 = load i8*, i8** %t1
  %t159 = icmp eq i8* %t158, null
  br i1 %t159, label %list_read_null_39, label %list_read_real_40
list_read_null_39:
  br label %list_read_end_41
list_read_real_40:
  %t160 = bitcast i8* %t158 to { i32*, i64, i64 }*
  %t161 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t160, i32 0, i32 0
  %t162 = load i32*, i32** %t161
  %t163 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t160, i32 0, i32 1
  %t164 = load i64, i64* %t163
  br label %list_read_end_41
list_read_end_41:
  %t165 = phi i32* [ null, %list_read_null_39 ], [ %t162, %list_read_real_40 ]
  %t166 = phi i64 [ 0, %list_read_null_39 ], [ %t164, %list_read_real_40 ]
  %t167 = trunc i64 %t166 to i32
  store i32 0, i32* %t168
  br label %for_cond_42
for_cond_42:
  %t169 = load i32, i32* %t168
  %t170 = icmp slt i32 %t169, %t167
  br i1 %t170, label %for_body_43, label %for_end_45
for_body_43:
  %t171 = load i32, i32* %t168
  %t172 = load i8*, i8** %t1
  %t173 = icmp eq i8* %t172, null
  br i1 %t173, label %list_read_null_46, label %list_read_real_47
list_read_null_46:
  br label %list_read_end_48
list_read_real_47:
  %t174 = bitcast i8* %t172 to { i32*, i64, i64 }*
  %t175 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t174, i32 0, i32 0
  %t176 = load i32*, i32** %t175
  %t177 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t174, i32 0, i32 1
  %t178 = load i64, i64* %t177
  br label %list_read_end_48
list_read_end_48:
  %t179 = phi i32* [ null, %list_read_null_46 ], [ %t176, %list_read_real_47 ]
  %t180 = phi i64 [ 0, %list_read_null_46 ], [ %t178, %list_read_real_47 ]
  %t181 = load i32, i32* %t168
  %t182 = sext i32 %t181 to i64
  %t183 = icmp ult i64 %t182, %t180
  br i1 %t183, label %list_idx_ok_49, label %list_idx_oob_50
list_idx_ok_49:
  %t184 = getelementptr inbounds i32, i32* %t179, i64 %t182
  %t185 = load i32, i32* %t184
  br label %list_idx_end_51
list_idx_oob_50:
  br label %list_idx_end_51
list_idx_end_51:
  %t186 = phi i32 [ %t185, %list_idx_ok_49 ], [ 0, %list_idx_oob_50 ]
  %t187 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t187, i32 %t171, i32 %t186)
  br label %for_step_44
for_step_44:
  %t188 = load i32, i32* %t168
  %t189 = add i32 %t188, 1
  store i32 %t189, i32* %t168
  br label %for_cond_42
for_end_45:
  %t190 = getelementptr i32, i32* null, i32 1
  %t191 = ptrtoint i32* %t190 to i64
  %t192 = load i8*, i8** %t1
  %t193 = icmp eq i8* %t192, null
  br i1 %t193, label %list_cow_alloc_52, label %list_cow_check_53
list_cow_alloc_52:
  %t194 = bitcast void (i8*)* @list_release_i32 to i8*
  %t195 = call i8* @star_rc_alloc(i64 24, i8* %t194)
  %t196 = bitcast i8* %t195 to { i32*, i64, i64 }*
  %t197 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t196, i32 0, i32 0
  store i32* null, i32** %t197
  %t198 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t196, i32 0, i32 1
  store i64 0, i64* %t198
  %t199 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t196, i32 0, i32 2
  store i64 0, i64* %t199
  store i8* %t195, i8** %t1
  br label %list_cow_done_54
list_cow_check_53:
  %t200 = getelementptr inbounds i8, i8* %t192, i64 -16
  %t201 = bitcast i8* %t200 to i64*
  %t202 = load atomic i64, i64* %t201 seq_cst, align 8
  %t203 = icmp eq i64 %t202, 1
  br i1 %t203, label %list_cow_done_54, label %list_cow_clone_55
list_cow_clone_55:
  %t204 = bitcast i8* %t192 to { i32*, i64, i64 }*
  %t205 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t204, i32 0, i32 0
  %t206 = load i32*, i32** %t205
  %t207 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t204, i32 0, i32 1
  %t208 = load i64, i64* %t207
  %t209 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t204, i32 0, i32 2
  %t210 = load i64, i64* %t209
  %t211 = bitcast void (i8*)* @list_release_i32 to i8*
  %t212 = call i8* @star_rc_alloc(i64 24, i8* %t211)
  %t213 = bitcast i8* %t212 to { i32*, i64, i64 }*
  %t214 = mul i64 %t210, %t191
  %t215 = call i8* @malloc(i64 %t214)
  %t216 = bitcast i8* %t215 to i32*
  %t217 = icmp sgt i64 %t208, 0
  br i1 %t217, label %list_cow_copy_56, label %list_cow_after_copy_57
list_cow_copy_56:
  %t218 = mul i64 %t208, %t191
  %t219 = bitcast i32* %t206 to i8*
  call i8* @memcpy(i8* %t215, i8* %t219, i64 %t218)
  br label %list_cow_after_copy_57
list_cow_after_copy_57:
  %t220 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t213, i32 0, i32 0
  store i32* %t216, i32** %t220
  %t221 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t213, i32 0, i32 1
  store i64 %t208, i64* %t221
  %t222 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t213, i32 0, i32 2
  store i64 %t210, i64* %t222
  call void @star_rc_release(i8* %t192)
  store i8* %t212, i8** %t1
  br label %list_cow_done_54
list_cow_done_54:
  %t223 = load i8*, i8** %t1
  %t224 = bitcast i8* %t223 to { i32*, i64, i64 }*
  %t225 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t224, i32 0, i32 0
  %t226 = load i32*, i32** %t225
  %t227 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t224, i32 0, i32 1
  %t228 = load i64, i64* %t227
  %t229 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t224, i32 0, i32 2
  %t230 = sext i32 0 to i64
  %t231 = icmp ult i64 %t230, %t228
  br i1 %t231, label %list_set_do_58, label %list_set_oob_59
list_set_do_58:
  %t232 = getelementptr inbounds i32, i32* %t226, i64 %t230
  store i32 100, i32* %t232
  br label %list_set_end_60
list_set_oob_59:
  br label %list_set_end_60
list_set_end_60:
  %t233 = load i8*, i8** %t1
  %t234 = icmp eq i8* %t233, null
  br i1 %t234, label %list_read_null_61, label %list_read_real_62
list_read_null_61:
  br label %list_read_end_63
list_read_real_62:
  %t235 = bitcast i8* %t233 to { i32*, i64, i64 }*
  %t236 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t235, i32 0, i32 0
  %t237 = load i32*, i32** %t236
  %t238 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t235, i32 0, i32 1
  %t239 = load i64, i64* %t238
  br label %list_read_end_63
list_read_end_63:
  %t240 = phi i32* [ null, %list_read_null_61 ], [ %t237, %list_read_real_62 ]
  %t241 = phi i64 [ 0, %list_read_null_61 ], [ %t239, %list_read_real_62 ]
  %t242 = sext i32 0 to i64
  %t243 = icmp ult i64 %t242, %t241
  br i1 %t243, label %list_idx_ok_64, label %list_idx_oob_65
list_idx_ok_64:
  %t244 = getelementptr inbounds i32, i32* %t240, i64 %t242
  %t245 = load i32, i32* %t244
  br label %list_idx_end_66
list_idx_oob_65:
  br label %list_idx_end_66
list_idx_end_66:
  %t246 = phi i32 [ %t245, %list_idx_ok_64 ], [ 0, %list_idx_oob_65 ]
  %t247 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t247, i32 %t246)
  %t249 = getelementptr i32, i32* null, i32 1
  %t250 = ptrtoint i32* %t249 to i64
  %t251 = load i8*, i8** %t1
  %t252 = icmp eq i8* %t251, null
  br i1 %t252, label %list_cow_alloc_67, label %list_cow_check_68
list_cow_alloc_67:
  %t253 = bitcast void (i8*)* @list_release_i32 to i8*
  %t254 = call i8* @star_rc_alloc(i64 24, i8* %t253)
  %t255 = bitcast i8* %t254 to { i32*, i64, i64 }*
  %t256 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t255, i32 0, i32 0
  store i32* null, i32** %t256
  %t257 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t255, i32 0, i32 1
  store i64 0, i64* %t257
  %t258 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t255, i32 0, i32 2
  store i64 0, i64* %t258
  store i8* %t254, i8** %t1
  br label %list_cow_done_69
list_cow_check_68:
  %t259 = getelementptr inbounds i8, i8* %t251, i64 -16
  %t260 = bitcast i8* %t259 to i64*
  %t261 = load atomic i64, i64* %t260 seq_cst, align 8
  %t262 = icmp eq i64 %t261, 1
  br i1 %t262, label %list_cow_done_69, label %list_cow_clone_70
list_cow_clone_70:
  %t263 = bitcast i8* %t251 to { i32*, i64, i64 }*
  %t264 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t263, i32 0, i32 0
  %t265 = load i32*, i32** %t264
  %t266 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t263, i32 0, i32 1
  %t267 = load i64, i64* %t266
  %t268 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t263, i32 0, i32 2
  %t269 = load i64, i64* %t268
  %t270 = bitcast void (i8*)* @list_release_i32 to i8*
  %t271 = call i8* @star_rc_alloc(i64 24, i8* %t270)
  %t272 = bitcast i8* %t271 to { i32*, i64, i64 }*
  %t273 = mul i64 %t269, %t250
  %t274 = call i8* @malloc(i64 %t273)
  %t275 = bitcast i8* %t274 to i32*
  %t276 = icmp sgt i64 %t267, 0
  br i1 %t276, label %list_cow_copy_71, label %list_cow_after_copy_72
list_cow_copy_71:
  %t277 = mul i64 %t267, %t250
  %t278 = bitcast i32* %t265 to i8*
  call i8* @memcpy(i8* %t274, i8* %t278, i64 %t277)
  br label %list_cow_after_copy_72
list_cow_after_copy_72:
  %t279 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t272, i32 0, i32 0
  store i32* %t275, i32** %t279
  %t280 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t272, i32 0, i32 1
  store i64 %t267, i64* %t280
  %t281 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t272, i32 0, i32 2
  store i64 %t269, i64* %t281
  call void @star_rc_release(i8* %t251)
  store i8* %t271, i8** %t1
  br label %list_cow_done_69
list_cow_done_69:
  %t282 = load i8*, i8** %t1
  %t283 = bitcast i8* %t282 to { i32*, i64, i64 }*
  %t284 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t283, i32 0, i32 0
  %t285 = load i32*, i32** %t284
  %t286 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t283, i32 0, i32 1
  %t287 = load i64, i64* %t286
  %t288 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t283, i32 0, i32 2
  %t289 = icmp eq i64 %t287, 0
  br i1 %t289, label %list_pop_empty_73, label %list_pop_nonempty_74
list_pop_nonempty_74:
  %t290 = sub i64 %t287, 1
  store i64 %t290, i64* %t286
  %t291 = load i32*, i32** %t284
  %t292 = getelementptr inbounds i32, i32* %t291, i64 %t290
  %t293 = load i32, i32* %t292
  br label %list_pop_end_75
list_pop_empty_73:
  br label %list_pop_end_75
list_pop_end_75:
  %t294 = phi i32 [ %t293, %list_pop_nonempty_74 ], [ 0, %list_pop_empty_73 ]
  store i32 %t294, i32* %t248
  %t295 = load i32, i32* %t248
  %t296 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t296, i32 %t295)
  %t297 = load i8*, i8** %t1
  %t298 = icmp eq i8* %t297, null
  br i1 %t298, label %list_read_null_76, label %list_read_real_77
list_read_null_76:
  br label %list_read_end_78
list_read_real_77:
  %t299 = bitcast i8* %t297 to { i32*, i64, i64 }*
  %t300 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t299, i32 0, i32 0
  %t301 = load i32*, i32** %t300
  %t302 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t299, i32 0, i32 1
  %t303 = load i64, i64* %t302
  br label %list_read_end_78
list_read_end_78:
  %t304 = phi i32* [ null, %list_read_null_76 ], [ %t301, %list_read_real_77 ]
  %t305 = phi i64 [ 0, %list_read_null_76 ], [ %t303, %list_read_real_77 ]
  %t306 = trunc i64 %t305 to i32
  %t307 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t307, i32 %t306)
  %t308 = load i8*, i8** %t1
  %t309 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t309)
  %t310 = call i32 @sum_list(i8* %t308)
  %t311 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t311, i32 %t310)
  store i8* null, i8** %t312
  %t313 = load i8*, i8** %t312
  %t314 = icmp eq i8* %t313, null
  br i1 %t314, label %list_read_null_79, label %list_read_real_80
list_read_null_79:
  br label %list_read_end_81
list_read_real_80:
  %t315 = bitcast i8* %t313 to { i32*, i64, i64 }*
  %t316 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t315, i32 0, i32 0
  %t317 = load i32*, i32** %t316
  %t318 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t315, i32 0, i32 1
  %t319 = load i64, i64* %t318
  br label %list_read_end_81
list_read_end_81:
  %t320 = phi i32* [ null, %list_read_null_79 ], [ %t317, %list_read_real_80 ]
  %t321 = phi i64 [ 0, %list_read_null_79 ], [ %t319, %list_read_real_80 ]
  %t322 = trunc i64 %t321 to i32
  %t323 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t323, i32 %t322)
  %t325 = getelementptr i32, i32* null, i32 1
  %t326 = ptrtoint i32* %t325 to i64
  %t327 = load i8*, i8** %t312
  %t328 = icmp eq i8* %t327, null
  br i1 %t328, label %list_cow_alloc_82, label %list_cow_check_83
list_cow_alloc_82:
  %t329 = bitcast void (i8*)* @list_release_i32 to i8*
  %t330 = call i8* @star_rc_alloc(i64 24, i8* %t329)
  %t331 = bitcast i8* %t330 to { i32*, i64, i64 }*
  %t332 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t331, i32 0, i32 0
  store i32* null, i32** %t332
  %t333 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t331, i32 0, i32 1
  store i64 0, i64* %t333
  %t334 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t331, i32 0, i32 2
  store i64 0, i64* %t334
  store i8* %t330, i8** %t312
  br label %list_cow_done_84
list_cow_check_83:
  %t335 = getelementptr inbounds i8, i8* %t327, i64 -16
  %t336 = bitcast i8* %t335 to i64*
  %t337 = load atomic i64, i64* %t336 seq_cst, align 8
  %t338 = icmp eq i64 %t337, 1
  br i1 %t338, label %list_cow_done_84, label %list_cow_clone_85
list_cow_clone_85:
  %t339 = bitcast i8* %t327 to { i32*, i64, i64 }*
  %t340 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t339, i32 0, i32 0
  %t341 = load i32*, i32** %t340
  %t342 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t339, i32 0, i32 1
  %t343 = load i64, i64* %t342
  %t344 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t339, i32 0, i32 2
  %t345 = load i64, i64* %t344
  %t346 = bitcast void (i8*)* @list_release_i32 to i8*
  %t347 = call i8* @star_rc_alloc(i64 24, i8* %t346)
  %t348 = bitcast i8* %t347 to { i32*, i64, i64 }*
  %t349 = mul i64 %t345, %t326
  %t350 = call i8* @malloc(i64 %t349)
  %t351 = bitcast i8* %t350 to i32*
  %t352 = icmp sgt i64 %t343, 0
  br i1 %t352, label %list_cow_copy_86, label %list_cow_after_copy_87
list_cow_copy_86:
  %t353 = mul i64 %t343, %t326
  %t354 = bitcast i32* %t341 to i8*
  call i8* @memcpy(i8* %t350, i8* %t354, i64 %t353)
  br label %list_cow_after_copy_87
list_cow_after_copy_87:
  %t355 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t348, i32 0, i32 0
  store i32* %t351, i32** %t355
  %t356 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t348, i32 0, i32 1
  store i64 %t343, i64* %t356
  %t357 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t348, i32 0, i32 2
  store i64 %t345, i64* %t357
  call void @star_rc_release(i8* %t327)
  store i8* %t347, i8** %t312
  br label %list_cow_done_84
list_cow_done_84:
  %t358 = load i8*, i8** %t312
  %t359 = bitcast i8* %t358 to { i32*, i64, i64 }*
  %t360 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t359, i32 0, i32 0
  %t361 = load i32*, i32** %t360
  %t362 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t359, i32 0, i32 1
  %t363 = load i64, i64* %t362
  %t364 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t359, i32 0, i32 2
  %t365 = icmp eq i64 %t363, 0
  br i1 %t365, label %list_pop_empty_88, label %list_pop_nonempty_89
list_pop_nonempty_89:
  %t366 = sub i64 %t363, 1
  store i64 %t366, i64* %t362
  %t367 = load i32*, i32** %t360
  %t368 = getelementptr inbounds i32, i32* %t367, i64 %t366
  %t369 = load i32, i32* %t368
  br label %list_pop_end_90
list_pop_empty_88:
  br label %list_pop_end_90
list_pop_end_90:
  %t370 = phi i32 [ %t369, %list_pop_nonempty_89 ], [ 0, %list_pop_empty_88 ]
  store i32 %t370, i32* %t324
  %t371 = load i32, i32* %t324
  %t372 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t372, i32 %t371)
  %t374 = load i8*, i8** %t312
  %t375 = icmp eq i8* %t374, null
  br i1 %t375, label %list_read_null_91, label %list_read_real_92
list_read_null_91:
  br label %list_read_end_93
list_read_real_92:
  %t376 = bitcast i8* %t374 to { i32*, i64, i64 }*
  %t377 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t376, i32 0, i32 0
  %t378 = load i32*, i32** %t377
  %t379 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t376, i32 0, i32 1
  %t380 = load i64, i64* %t379
  br label %list_read_end_93
list_read_end_93:
  %t381 = phi i32* [ null, %list_read_null_91 ], [ %t378, %list_read_real_92 ]
  %t382 = phi i64 [ 0, %list_read_null_91 ], [ %t380, %list_read_real_92 ]
  %t383 = sext i32 0 to i64
  %t384 = icmp ult i64 %t383, %t382
  br i1 %t384, label %list_idx_ok_94, label %list_idx_oob_95
list_idx_ok_94:
  %t385 = getelementptr inbounds i32, i32* %t381, i64 %t383
  %t386 = load i32, i32* %t385
  br label %list_idx_end_96
list_idx_oob_95:
  br label %list_idx_end_96
list_idx_end_96:
  %t387 = phi i32 [ %t386, %list_idx_ok_94 ], [ 0, %list_idx_oob_95 ]
  store i32 %t387, i32* %t373
  %t388 = load i32, i32* %t373
  %t389 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t389, i32 %t388)
  store i8* null, i8** %t390
  store i32 0, i32* %t391
  br label %while_cond_97
while_cond_97:
  %t392 = load i32, i32* %t391
  %t393 = icmp slt i32 %t392, 20
  br i1 %t393, label %while_body_98, label %while_else_99
while_body_98:
  %t394 = getelementptr i32, i32* null, i32 1
  %t395 = ptrtoint i32* %t394 to i64
  %t396 = load i8*, i8** %t390
  %t397 = icmp eq i8* %t396, null
  br i1 %t397, label %list_cow_alloc_101, label %list_cow_check_102
list_cow_alloc_101:
  %t398 = bitcast void (i8*)* @list_release_i32 to i8*
  %t399 = call i8* @star_rc_alloc(i64 24, i8* %t398)
  %t400 = bitcast i8* %t399 to { i32*, i64, i64 }*
  %t401 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t400, i32 0, i32 0
  store i32* null, i32** %t401
  %t402 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t400, i32 0, i32 1
  store i64 0, i64* %t402
  %t403 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t400, i32 0, i32 2
  store i64 0, i64* %t403
  store i8* %t399, i8** %t390
  br label %list_cow_done_103
list_cow_check_102:
  %t404 = getelementptr inbounds i8, i8* %t396, i64 -16
  %t405 = bitcast i8* %t404 to i64*
  %t406 = load atomic i64, i64* %t405 seq_cst, align 8
  %t407 = icmp eq i64 %t406, 1
  br i1 %t407, label %list_cow_done_103, label %list_cow_clone_104
list_cow_clone_104:
  %t408 = bitcast i8* %t396 to { i32*, i64, i64 }*
  %t409 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t408, i32 0, i32 0
  %t410 = load i32*, i32** %t409
  %t411 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t408, i32 0, i32 1
  %t412 = load i64, i64* %t411
  %t413 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t408, i32 0, i32 2
  %t414 = load i64, i64* %t413
  %t415 = bitcast void (i8*)* @list_release_i32 to i8*
  %t416 = call i8* @star_rc_alloc(i64 24, i8* %t415)
  %t417 = bitcast i8* %t416 to { i32*, i64, i64 }*
  %t418 = mul i64 %t414, %t395
  %t419 = call i8* @malloc(i64 %t418)
  %t420 = bitcast i8* %t419 to i32*
  %t421 = icmp sgt i64 %t412, 0
  br i1 %t421, label %list_cow_copy_105, label %list_cow_after_copy_106
list_cow_copy_105:
  %t422 = mul i64 %t412, %t395
  %t423 = bitcast i32* %t410 to i8*
  call i8* @memcpy(i8* %t419, i8* %t423, i64 %t422)
  br label %list_cow_after_copy_106
list_cow_after_copy_106:
  %t424 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t417, i32 0, i32 0
  store i32* %t420, i32** %t424
  %t425 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t417, i32 0, i32 1
  store i64 %t412, i64* %t425
  %t426 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t417, i32 0, i32 2
  store i64 %t414, i64* %t426
  call void @star_rc_release(i8* %t396)
  store i8* %t416, i8** %t390
  br label %list_cow_done_103
list_cow_done_103:
  %t427 = load i8*, i8** %t390
  %t428 = bitcast i8* %t427 to { i32*, i64, i64 }*
  %t429 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t428, i32 0, i32 0
  %t430 = load i32*, i32** %t429
  %t431 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t428, i32 0, i32 1
  %t432 = load i64, i64* %t431
  %t433 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t428, i32 0, i32 2
  %t434 = load i32, i32* %t391
  %t435 = load i64, i64* %t433
  %t436 = load i32*, i32** %t429
  %t437 = load i64, i64* %t431
  %t438 = icmp sge i64 %t437, %t435
  br i1 %t438, label %list_push_grow_107, label %list_push_store_108
list_push_grow_107:
  %t439 = mul i64 %t435, 2
  %t440 = icmp sgt i64 %t439, 0
  %t441 = select i1 %t440, i64 %t439, i64 1
  %t442 = getelementptr i32, i32* null, i32 1
  %t443 = ptrtoint i32* %t442 to i64
  %t444 = mul i64 %t441, %t443
  %t445 = call i8* @malloc(i64 %t444)
  %t446 = bitcast i8* %t445 to i32*
  %t447 = icmp sgt i64 %t435, 0
  br i1 %t447, label %list_push_copy_109, label %list_push_after_copy_110
list_push_copy_109:
  %t448 = mul i64 %t437, %t443
  %t449 = bitcast i32* %t436 to i8*
  call i8* @memcpy(i8* %t445, i8* %t449, i64 %t448)
  call void @free(i8* %t449)
  br label %list_push_after_copy_110
list_push_after_copy_110:
  store i32* %t446, i32** %t429
  store i64 %t441, i64* %t433
  br label %list_push_store_108
list_push_store_108:
  %t450 = load i32*, i32** %t429
  %t451 = getelementptr inbounds i32, i32* %t450, i64 %t437
  store i32 %t434, i32* %t451
  %t452 = add i64 %t437, 1
  store i64 %t452, i64* %t431
  %t453 = load i32, i32* %t391
  %t454 = add i32 %t453, 1
  store i32 %t454, i32* %t391
  br label %while_cond_97
while_else_99:
  br label %while_end_100
while_end_100:
  %t455 = load i8*, i8** %t390
  %t456 = icmp eq i8* %t455, null
  br i1 %t456, label %list_read_null_111, label %list_read_real_112
list_read_null_111:
  br label %list_read_end_113
list_read_real_112:
  %t457 = bitcast i8* %t455 to { i32*, i64, i64 }*
  %t458 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t457, i32 0, i32 0
  %t459 = load i32*, i32** %t458
  %t460 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t457, i32 0, i32 1
  %t461 = load i64, i64* %t460
  br label %list_read_end_113
list_read_end_113:
  %t462 = phi i32* [ null, %list_read_null_111 ], [ %t459, %list_read_real_112 ]
  %t463 = phi i64 [ 0, %list_read_null_111 ], [ %t461, %list_read_real_112 ]
  %t464 = trunc i64 %t463 to i32
  %t465 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t465, i32 %t464)
  %t466 = load i8*, i8** %t390
  %t467 = icmp eq i8* %t466, null
  br i1 %t467, label %list_read_null_114, label %list_read_real_115
list_read_null_114:
  br label %list_read_end_116
list_read_real_115:
  %t468 = bitcast i8* %t466 to { i32*, i64, i64 }*
  %t469 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t468, i32 0, i32 0
  %t470 = load i32*, i32** %t469
  %t471 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t468, i32 0, i32 1
  %t472 = load i64, i64* %t471
  br label %list_read_end_116
list_read_end_116:
  %t473 = phi i32* [ null, %list_read_null_114 ], [ %t470, %list_read_real_115 ]
  %t474 = phi i64 [ 0, %list_read_null_114 ], [ %t472, %list_read_real_115 ]
  %t475 = sext i32 19 to i64
  %t476 = icmp ult i64 %t475, %t474
  br i1 %t476, label %list_idx_ok_117, label %list_idx_oob_118
list_idx_ok_117:
  %t477 = getelementptr inbounds i32, i32* %t473, i64 %t475
  %t478 = load i32, i32* %t477
  br label %list_idx_end_119
list_idx_oob_118:
  br label %list_idx_end_119
list_idx_end_119:
  %t479 = phi i32 [ %t478, %list_idx_ok_117 ], [ 0, %list_idx_oob_118 ]
  %t480 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t480, i32 %t479)
  %t481 = load i8*, i8** %t390
  %t482 = icmp eq i8* %t481, null
  br i1 %t482, label %list_read_null_120, label %list_read_real_121
list_read_null_120:
  br label %list_read_end_122
list_read_real_121:
  %t483 = bitcast i8* %t481 to { i32*, i64, i64 }*
  %t484 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t483, i32 0, i32 0
  %t485 = load i32*, i32** %t484
  %t486 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t483, i32 0, i32 1
  %t487 = load i64, i64* %t486
  br label %list_read_end_122
list_read_end_122:
  %t488 = phi i32* [ null, %list_read_null_120 ], [ %t485, %list_read_real_121 ]
  %t489 = phi i64 [ 0, %list_read_null_120 ], [ %t487, %list_read_real_121 ]
  %t490 = sext i32 0 to i64
  %t491 = icmp ult i64 %t490, %t489
  br i1 %t491, label %list_idx_ok_123, label %list_idx_oob_124
list_idx_ok_123:
  %t492 = getelementptr inbounds i32, i32* %t488, i64 %t490
  %t493 = load i32, i32* %t492
  br label %list_idx_end_125
list_idx_oob_124:
  br label %list_idx_end_125
list_idx_end_125:
  %t494 = phi i32 [ %t493, %list_idx_ok_123 ], [ 0, %list_idx_oob_124 ]
  %t495 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t495, i32 %t494)
  %t497 = getelementptr i8*, i8** null, i32 1
  %t498 = ptrtoint i8** %t497 to i64
  %t499 = mul i64 %t498, 3
  %t500 = call i8* @malloc(i64 %t499)
  %t501 = bitcast i8* %t500 to i8**
  %t502 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t503 = getelementptr inbounds i8*, i8** %t501, i64 0
  store i8* %t502, i8** %t503
  %t504 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t505 = getelementptr inbounds i8*, i8** %t501, i64 1
  store i8* %t504, i8** %t505
  %t506 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t507 = getelementptr inbounds i8*, i8** %t501, i64 2
  store i8* %t506, i8** %t507
  %t520 = bitcast void (i8*)* @list_release_str to i8*
  %t521 = call i8* @star_rc_alloc(i64 24, i8* %t520)
  %t522 = bitcast i8* %t521 to { i8**, i64, i64 }*
  %t523 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t522, i32 0, i32 0
  store i8** %t501, i8*** %t523
  %t524 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t522, i32 0, i32 1
  store i64 3, i64* %t524
  %t525 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t522, i32 0, i32 2
  store i64 3, i64* %t525
  store i8* %t521, i8** %t496
  %t526 = load i8*, i8** %t496
  %t527 = icmp eq i8* %t526, null
  br i1 %t527, label %list_read_null_129, label %list_read_real_130
list_read_null_129:
  br label %list_read_end_131
list_read_real_130:
  %t528 = bitcast i8* %t526 to { i8**, i64, i64 }*
  %t529 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t528, i32 0, i32 0
  %t530 = load i8**, i8*** %t529
  %t531 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t528, i32 0, i32 1
  %t532 = load i64, i64* %t531
  br label %list_read_end_131
list_read_end_131:
  %t533 = phi i8** [ null, %list_read_null_129 ], [ %t530, %list_read_real_130 ]
  %t534 = phi i64 [ 0, %list_read_null_129 ], [ %t532, %list_read_real_130 ]
  %t535 = trunc i64 %t534 to i32
  %t536 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t536, i32 %t535)
  %t537 = load i8*, i8** %t496
  %t538 = icmp eq i8* %t537, null
  br i1 %t538, label %list_read_null_132, label %list_read_real_133
list_read_null_132:
  br label %list_read_end_134
list_read_real_133:
  %t539 = bitcast i8* %t537 to { i8**, i64, i64 }*
  %t540 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t539, i32 0, i32 0
  %t541 = load i8**, i8*** %t540
  %t542 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t539, i32 0, i32 1
  %t543 = load i64, i64* %t542
  br label %list_read_end_134
list_read_end_134:
  %t544 = phi i8** [ null, %list_read_null_132 ], [ %t541, %list_read_real_133 ]
  %t545 = phi i64 [ 0, %list_read_null_132 ], [ %t543, %list_read_real_133 ]
  %t546 = sext i32 1 to i64
  %t547 = icmp ult i64 %t546, %t545
  br i1 %t547, label %list_idx_ok_135, label %list_idx_oob_136
list_idx_ok_135:
  %t548 = getelementptr inbounds i8*, i8** %t544, i64 %t546
  %t549 = load i8*, i8** %t548
  %t550 = load i8*, i8** %t548
  call void @star_rc_retain(i8* %t550)
  br label %list_idx_end_137
list_idx_oob_136:
  br label %list_idx_end_137
list_idx_end_137:
  %t551 = phi i8* [ %t549, %list_idx_ok_135 ], [ null, %list_idx_oob_136 ]
  call void @star_rc_release(i8* %t551)
  %t552 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t552, i8* %t551)
  %t554 = getelementptr %Point, %Point* null, i32 1
  %t555 = ptrtoint %Point* %t554 to i64
  %t556 = mul i64 %t555, 2
  %t557 = call i8* @malloc(i64 %t556)
  %t558 = bitcast i8* %t557 to %Point*
  %t560 = getelementptr inbounds %Point, %Point* %t559, i32 0, i32 0
  store i32 1, i32* %t560
  %t561 = getelementptr inbounds %Point, %Point* %t559, i32 0, i32 1
  store i32 2, i32* %t561
  %t562 = load %Point, %Point* %t559
  %t563 = getelementptr inbounds %Point, %Point* %t558, i64 0
  store %Point %t562, %Point* %t563
  %t565 = getelementptr inbounds %Point, %Point* %t564, i32 0, i32 0
  store i32 3, i32* %t565
  %t566 = getelementptr inbounds %Point, %Point* %t564, i32 0, i32 1
  store i32 4, i32* %t566
  %t567 = load %Point, %Point* %t564
  %t568 = getelementptr inbounds %Point, %Point* %t558, i64 1
  store %Point %t567, %Point* %t568
  %t573 = bitcast void (i8*)* @list_release_s_Point to i8*
  %t574 = call i8* @star_rc_alloc(i64 24, i8* %t573)
  %t575 = bitcast i8* %t574 to { %Point*, i64, i64 }*
  %t576 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t575, i32 0, i32 0
  store %Point* %t558, %Point** %t576
  %t577 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t575, i32 0, i32 1
  store i64 2, i64* %t577
  %t578 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t575, i32 0, i32 2
  store i64 2, i64* %t578
  store i8* %t574, i8** %t553
  %t580 = load i8*, i8** %t553
  %t581 = icmp eq i8* %t580, null
  br i1 %t581, label %list_read_null_138, label %list_read_real_139
list_read_null_138:
  br label %list_read_end_140
list_read_real_139:
  %t582 = bitcast i8* %t580 to { %Point*, i64, i64 }*
  %t583 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t582, i32 0, i32 0
  %t584 = load %Point*, %Point** %t583
  %t585 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t582, i32 0, i32 1
  %t586 = load i64, i64* %t585
  br label %list_read_end_140
list_read_end_140:
  %t587 = phi %Point* [ null, %list_read_null_138 ], [ %t584, %list_read_real_139 ]
  %t588 = phi i64 [ 0, %list_read_null_138 ], [ %t586, %list_read_real_139 ]
  %t589 = sext i32 1 to i64
  %t590 = icmp ult i64 %t589, %t588
  br i1 %t590, label %list_idx_ok_141, label %list_idx_oob_142
list_idx_ok_141:
  %t591 = getelementptr inbounds %Point, %Point* %t587, i64 %t589
  %t592 = load %Point, %Point* %t591
  br label %list_idx_end_143
list_idx_oob_142:
  br label %list_idx_end_143
list_idx_end_143:
  %t593 = phi %Point [ %t592, %list_idx_ok_141 ], [ zeroinitializer, %list_idx_oob_142 ]
  store %Point %t593, %Point* %t579
  %t594 = getelementptr inbounds %Point, %Point* %t579, i32 0, i32 0
  %t595 = load i32, i32* %t594
  %t596 = getelementptr inbounds %Point, %Point* %t579, i32 0, i32 1
  %t597 = load i32, i32* %t596
  %t598 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.18, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t598, i32 %t595, i32 %t597)
  %t599 = load i8*, i8** %t553
  call void @star_rc_release(i8* %t599)
  %t600 = load i8*, i8** %t496
  call void @star_rc_release(i8* %t600)
  %t601 = load i8*, i8** %t390
  call void @star_rc_release(i8* %t601)
  %t602 = load i8*, i8** %t312
  call void @star_rc_release(i8* %t602)
  %t603 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t603)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_i32(i8* %objp) {
entry:
  %t10 = bitcast i8* %objp to { i32*, i64, i64 }*
  %t11 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t10, i32 0, i32 0
  %t12 = load i32*, i32** %t11
  %t13 = bitcast i32* %t12 to i8*
  call void @free(i8* %t13)
  ret void
}


define void @list_release_str(i8* %objp) {
entry:
  %t513 = alloca i64
  %t508 = bitcast i8* %objp to { i8**, i64, i64 }*
  %t509 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t508, i32 0, i32 0
  %t510 = load i8**, i8*** %t509
  %t511 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t508, i32 0, i32 1
  %t512 = load i64, i64* %t511
  store i64 0, i64* %t513
  br label %list_release_cond_126
list_release_cond_126:
  %t514 = load i64, i64* %t513
  %t515 = icmp slt i64 %t514, %t512
  br i1 %t515, label %list_release_body_127, label %list_release_end_128
list_release_body_127:
  %t516 = getelementptr inbounds i8*, i8** %t510, i64 %t514
  %t517 = load i8*, i8** %t516
  call void @star_rc_release(i8* %t517)
  %t518 = add i64 %t514, 1
  store i64 %t518, i64* %t513
  br label %list_release_cond_126
list_release_end_128:
  %t519 = bitcast i8** %t510 to i8*
  call void @free(i8* %t519)
  ret void
}


define void @list_release_s_Point(i8* %objp) {
entry:
  %t569 = bitcast i8* %objp to { %Point*, i64, i64 }*
  %t570 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t569, i32 0, i32 0
  %t571 = load %Point*, %Point** %t570
  %t572 = bitcast %Point* %t571 to i8*
  call void @free(i8* %t572)
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
