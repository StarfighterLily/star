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
  %t0 = alloca i8*
  %t167 = alloca i32
  %t247 = alloca i32
  %t311 = alloca i8*
  %t323 = alloca i32
  %t372 = alloca i32
  %t389 = alloca i8*
  %t390 = alloca i32
  %t495 = alloca i8*
  %t552 = alloca i8*
  %t558 = alloca %Point
  %t563 = alloca %Point
  %t578 = alloca %Point
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
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
  %t72 = load i64, i64* %t67
  %t73 = icmp sge i64 %t72, %t70
  br i1 %t73, label %list_push_grow_22, label %list_push_store_23
list_push_grow_22:
  %t74 = mul i64 %t70, 2
  %t75 = icmp sgt i64 %t74, 0
  %t76 = select i1 %t75, i64 %t74, i64 1
  %t77 = getelementptr i32, i32* null, i32 1
  %t78 = ptrtoint i32* %t77 to i64
  %t79 = mul i64 %t76, %t78
  %t80 = call i8* @malloc(i64 %t79)
  %t81 = bitcast i8* %t80 to i32*
  %t82 = icmp sgt i64 %t70, 0
  br i1 %t82, label %list_push_copy_24, label %list_push_after_copy_25
list_push_copy_24:
  %t83 = mul i64 %t72, %t78
  %t84 = bitcast i32* %t71 to i8*
  call i8* @memcpy(i8* %t80, i8* %t84, i64 %t83)
  call void @free(i8* %t84)
  br label %list_push_after_copy_25
list_push_after_copy_25:
  store i32* %t81, i32** %t65
  store i64 %t76, i64* %t69
  br label %list_push_store_23
list_push_store_23:
  %t85 = load i32*, i32** %t65
  %t86 = getelementptr inbounds i32, i32* %t85, i64 %t72
  store i32 4, i32* %t86
  %t87 = add i64 %t72, 1
  store i64 %t87, i64* %t67
  %t88 = getelementptr i32, i32* null, i32 1
  %t89 = ptrtoint i32* %t88 to i64
  %t90 = load i8*, i8** %t0
  %t91 = icmp eq i8* %t90, null
  br i1 %t91, label %list_cow_alloc_26, label %list_cow_check_27
list_cow_alloc_26:
  %t92 = bitcast void (i8*)* @list_release_i32 to i8*
  %t93 = call i8* @star_rc_alloc(i64 24, i8* %t92)
  %t94 = bitcast i8* %t93 to { i32*, i64, i64 }*
  %t95 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t94, i32 0, i32 0
  store i32* null, i32** %t95
  %t96 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t94, i32 0, i32 1
  store i64 0, i64* %t96
  %t97 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t94, i32 0, i32 2
  store i64 0, i64* %t97
  store i8* %t93, i8** %t0
  br label %list_cow_done_28
list_cow_check_27:
  %t98 = getelementptr inbounds i8, i8* %t90, i64 -16
  %t99 = bitcast i8* %t98 to i64*
  %t100 = load atomic i64, i64* %t99 seq_cst, align 8
  %t101 = icmp eq i64 %t100, 1
  br i1 %t101, label %list_cow_done_28, label %list_cow_clone_29
list_cow_clone_29:
  %t102 = bitcast i8* %t90 to { i32*, i64, i64 }*
  %t103 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t102, i32 0, i32 0
  %t104 = load i32*, i32** %t103
  %t105 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t102, i32 0, i32 1
  %t106 = load i64, i64* %t105
  %t107 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t102, i32 0, i32 2
  %t108 = load i64, i64* %t107
  %t109 = bitcast void (i8*)* @list_release_i32 to i8*
  %t110 = call i8* @star_rc_alloc(i64 24, i8* %t109)
  %t111 = bitcast i8* %t110 to { i32*, i64, i64 }*
  %t112 = mul i64 %t108, %t89
  %t113 = call i8* @malloc(i64 %t112)
  %t114 = bitcast i8* %t113 to i32*
  %t115 = icmp sgt i64 %t106, 0
  br i1 %t115, label %list_cow_copy_30, label %list_cow_after_copy_31
list_cow_copy_30:
  %t116 = mul i64 %t106, %t89
  %t117 = bitcast i32* %t104 to i8*
  call i8* @memcpy(i8* %t113, i8* %t117, i64 %t116)
  br label %list_cow_after_copy_31
list_cow_after_copy_31:
  %t118 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t111, i32 0, i32 0
  store i32* %t114, i32** %t118
  %t119 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t111, i32 0, i32 1
  store i64 %t106, i64* %t119
  %t120 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t111, i32 0, i32 2
  store i64 %t108, i64* %t120
  call void @star_rc_release(i8* %t90)
  store i8* %t110, i8** %t0
  br label %list_cow_done_28
list_cow_done_28:
  %t121 = load i8*, i8** %t0
  %t122 = bitcast i8* %t121 to { i32*, i64, i64 }*
  %t123 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t122, i32 0, i32 0
  %t124 = load i32*, i32** %t123
  %t125 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t122, i32 0, i32 1
  %t126 = load i64, i64* %t125
  %t127 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t122, i32 0, i32 2
  %t128 = load i64, i64* %t127
  %t129 = load i32*, i32** %t123
  %t130 = load i64, i64* %t125
  %t131 = icmp sge i64 %t130, %t128
  br i1 %t131, label %list_push_grow_32, label %list_push_store_33
list_push_grow_32:
  %t132 = mul i64 %t128, 2
  %t133 = icmp sgt i64 %t132, 0
  %t134 = select i1 %t133, i64 %t132, i64 1
  %t135 = getelementptr i32, i32* null, i32 1
  %t136 = ptrtoint i32* %t135 to i64
  %t137 = mul i64 %t134, %t136
  %t138 = call i8* @malloc(i64 %t137)
  %t139 = bitcast i8* %t138 to i32*
  %t140 = icmp sgt i64 %t128, 0
  br i1 %t140, label %list_push_copy_34, label %list_push_after_copy_35
list_push_copy_34:
  %t141 = mul i64 %t130, %t136
  %t142 = bitcast i32* %t129 to i8*
  call i8* @memcpy(i8* %t138, i8* %t142, i64 %t141)
  call void @free(i8* %t142)
  br label %list_push_after_copy_35
list_push_after_copy_35:
  store i32* %t139, i32** %t123
  store i64 %t134, i64* %t127
  br label %list_push_store_33
list_push_store_33:
  %t143 = load i32*, i32** %t123
  %t144 = getelementptr inbounds i32, i32* %t143, i64 %t130
  store i32 5, i32* %t144
  %t145 = add i64 %t130, 1
  store i64 %t145, i64* %t125
  %t146 = load i8*, i8** %t0
  %t147 = icmp eq i8* %t146, null
  br i1 %t147, label %list_read_null_36, label %list_read_real_37
list_read_null_36:
  br label %list_read_end_38
list_read_real_37:
  %t148 = bitcast i8* %t146 to { i32*, i64, i64 }*
  %t149 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t148, i32 0, i32 0
  %t150 = load i32*, i32** %t149
  %t151 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t148, i32 0, i32 1
  %t152 = load i64, i64* %t151
  br label %list_read_end_38
list_read_end_38:
  %t153 = phi i32* [ null, %list_read_null_36 ], [ %t150, %list_read_real_37 ]
  %t154 = phi i64 [ 0, %list_read_null_36 ], [ %t152, %list_read_real_37 ]
  %t155 = trunc i64 %t154 to i32
  %t156 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t156, i32 %t155)
  %t157 = load i8*, i8** %t0
  %t158 = icmp eq i8* %t157, null
  br i1 %t158, label %list_read_null_39, label %list_read_real_40
list_read_null_39:
  br label %list_read_end_41
list_read_real_40:
  %t159 = bitcast i8* %t157 to { i32*, i64, i64 }*
  %t160 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t159, i32 0, i32 0
  %t161 = load i32*, i32** %t160
  %t162 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t159, i32 0, i32 1
  %t163 = load i64, i64* %t162
  br label %list_read_end_41
list_read_end_41:
  %t164 = phi i32* [ null, %list_read_null_39 ], [ %t161, %list_read_real_40 ]
  %t165 = phi i64 [ 0, %list_read_null_39 ], [ %t163, %list_read_real_40 ]
  %t166 = trunc i64 %t165 to i32
  store i32 0, i32* %t167
  br label %for_cond_42
for_cond_42:
  %t168 = load i32, i32* %t167
  %t169 = icmp slt i32 %t168, %t166
  br i1 %t169, label %for_body_43, label %for_end_45
for_body_43:
  %t170 = load i32, i32* %t167
  %t171 = load i8*, i8** %t0
  %t172 = icmp eq i8* %t171, null
  br i1 %t172, label %list_read_null_46, label %list_read_real_47
list_read_null_46:
  br label %list_read_end_48
list_read_real_47:
  %t173 = bitcast i8* %t171 to { i32*, i64, i64 }*
  %t174 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t173, i32 0, i32 0
  %t175 = load i32*, i32** %t174
  %t176 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t173, i32 0, i32 1
  %t177 = load i64, i64* %t176
  br label %list_read_end_48
list_read_end_48:
  %t178 = phi i32* [ null, %list_read_null_46 ], [ %t175, %list_read_real_47 ]
  %t179 = phi i64 [ 0, %list_read_null_46 ], [ %t177, %list_read_real_47 ]
  %t180 = load i32, i32* %t167
  %t181 = sext i32 %t180 to i64
  %t182 = icmp ult i64 %t181, %t179
  br i1 %t182, label %list_idx_ok_49, label %list_idx_oob_50
list_idx_ok_49:
  %t183 = getelementptr inbounds i32, i32* %t178, i64 %t181
  %t184 = load i32, i32* %t183
  br label %list_idx_end_51
list_idx_oob_50:
  br label %list_idx_end_51
list_idx_end_51:
  %t185 = phi i32 [ %t184, %list_idx_ok_49 ], [ 0, %list_idx_oob_50 ]
  %t186 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t186, i32 %t170, i32 %t185)
  br label %for_step_44
for_step_44:
  %t187 = load i32, i32* %t167
  %t188 = add i32 %t187, 1
  store i32 %t188, i32* %t167
  br label %for_cond_42
for_end_45:
  %t189 = getelementptr i32, i32* null, i32 1
  %t190 = ptrtoint i32* %t189 to i64
  %t191 = load i8*, i8** %t0
  %t192 = icmp eq i8* %t191, null
  br i1 %t192, label %list_cow_alloc_52, label %list_cow_check_53
list_cow_alloc_52:
  %t193 = bitcast void (i8*)* @list_release_i32 to i8*
  %t194 = call i8* @star_rc_alloc(i64 24, i8* %t193)
  %t195 = bitcast i8* %t194 to { i32*, i64, i64 }*
  %t196 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t195, i32 0, i32 0
  store i32* null, i32** %t196
  %t197 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t195, i32 0, i32 1
  store i64 0, i64* %t197
  %t198 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t195, i32 0, i32 2
  store i64 0, i64* %t198
  store i8* %t194, i8** %t0
  br label %list_cow_done_54
list_cow_check_53:
  %t199 = getelementptr inbounds i8, i8* %t191, i64 -16
  %t200 = bitcast i8* %t199 to i64*
  %t201 = load atomic i64, i64* %t200 seq_cst, align 8
  %t202 = icmp eq i64 %t201, 1
  br i1 %t202, label %list_cow_done_54, label %list_cow_clone_55
list_cow_clone_55:
  %t203 = bitcast i8* %t191 to { i32*, i64, i64 }*
  %t204 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t203, i32 0, i32 0
  %t205 = load i32*, i32** %t204
  %t206 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t203, i32 0, i32 1
  %t207 = load i64, i64* %t206
  %t208 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t203, i32 0, i32 2
  %t209 = load i64, i64* %t208
  %t210 = bitcast void (i8*)* @list_release_i32 to i8*
  %t211 = call i8* @star_rc_alloc(i64 24, i8* %t210)
  %t212 = bitcast i8* %t211 to { i32*, i64, i64 }*
  %t213 = mul i64 %t209, %t190
  %t214 = call i8* @malloc(i64 %t213)
  %t215 = bitcast i8* %t214 to i32*
  %t216 = icmp sgt i64 %t207, 0
  br i1 %t216, label %list_cow_copy_56, label %list_cow_after_copy_57
list_cow_copy_56:
  %t217 = mul i64 %t207, %t190
  %t218 = bitcast i32* %t205 to i8*
  call i8* @memcpy(i8* %t214, i8* %t218, i64 %t217)
  br label %list_cow_after_copy_57
list_cow_after_copy_57:
  %t219 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t212, i32 0, i32 0
  store i32* %t215, i32** %t219
  %t220 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t212, i32 0, i32 1
  store i64 %t207, i64* %t220
  %t221 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t212, i32 0, i32 2
  store i64 %t209, i64* %t221
  call void @star_rc_release(i8* %t191)
  store i8* %t211, i8** %t0
  br label %list_cow_done_54
list_cow_done_54:
  %t222 = load i8*, i8** %t0
  %t223 = bitcast i8* %t222 to { i32*, i64, i64 }*
  %t224 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t223, i32 0, i32 0
  %t225 = load i32*, i32** %t224
  %t226 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t223, i32 0, i32 1
  %t227 = load i64, i64* %t226
  %t228 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t223, i32 0, i32 2
  %t229 = sext i32 0 to i64
  %t230 = icmp ult i64 %t229, %t227
  br i1 %t230, label %list_set_do_58, label %list_set_oob_59
list_set_do_58:
  %t231 = getelementptr inbounds i32, i32* %t225, i64 %t229
  store i32 100, i32* %t231
  br label %list_set_end_60
list_set_oob_59:
  br label %list_set_end_60
list_set_end_60:
  %t232 = load i8*, i8** %t0
  %t233 = icmp eq i8* %t232, null
  br i1 %t233, label %list_read_null_61, label %list_read_real_62
list_read_null_61:
  br label %list_read_end_63
list_read_real_62:
  %t234 = bitcast i8* %t232 to { i32*, i64, i64 }*
  %t235 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t234, i32 0, i32 0
  %t236 = load i32*, i32** %t235
  %t237 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t234, i32 0, i32 1
  %t238 = load i64, i64* %t237
  br label %list_read_end_63
list_read_end_63:
  %t239 = phi i32* [ null, %list_read_null_61 ], [ %t236, %list_read_real_62 ]
  %t240 = phi i64 [ 0, %list_read_null_61 ], [ %t238, %list_read_real_62 ]
  %t241 = sext i32 0 to i64
  %t242 = icmp ult i64 %t241, %t240
  br i1 %t242, label %list_idx_ok_64, label %list_idx_oob_65
list_idx_ok_64:
  %t243 = getelementptr inbounds i32, i32* %t239, i64 %t241
  %t244 = load i32, i32* %t243
  br label %list_idx_end_66
list_idx_oob_65:
  br label %list_idx_end_66
list_idx_end_66:
  %t245 = phi i32 [ %t244, %list_idx_ok_64 ], [ 0, %list_idx_oob_65 ]
  %t246 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t246, i32 %t245)
  %t248 = getelementptr i32, i32* null, i32 1
  %t249 = ptrtoint i32* %t248 to i64
  %t250 = load i8*, i8** %t0
  %t251 = icmp eq i8* %t250, null
  br i1 %t251, label %list_cow_alloc_67, label %list_cow_check_68
list_cow_alloc_67:
  %t252 = bitcast void (i8*)* @list_release_i32 to i8*
  %t253 = call i8* @star_rc_alloc(i64 24, i8* %t252)
  %t254 = bitcast i8* %t253 to { i32*, i64, i64 }*
  %t255 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t254, i32 0, i32 0
  store i32* null, i32** %t255
  %t256 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t254, i32 0, i32 1
  store i64 0, i64* %t256
  %t257 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t254, i32 0, i32 2
  store i64 0, i64* %t257
  store i8* %t253, i8** %t0
  br label %list_cow_done_69
list_cow_check_68:
  %t258 = getelementptr inbounds i8, i8* %t250, i64 -16
  %t259 = bitcast i8* %t258 to i64*
  %t260 = load atomic i64, i64* %t259 seq_cst, align 8
  %t261 = icmp eq i64 %t260, 1
  br i1 %t261, label %list_cow_done_69, label %list_cow_clone_70
list_cow_clone_70:
  %t262 = bitcast i8* %t250 to { i32*, i64, i64 }*
  %t263 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t262, i32 0, i32 0
  %t264 = load i32*, i32** %t263
  %t265 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t262, i32 0, i32 1
  %t266 = load i64, i64* %t265
  %t267 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t262, i32 0, i32 2
  %t268 = load i64, i64* %t267
  %t269 = bitcast void (i8*)* @list_release_i32 to i8*
  %t270 = call i8* @star_rc_alloc(i64 24, i8* %t269)
  %t271 = bitcast i8* %t270 to { i32*, i64, i64 }*
  %t272 = mul i64 %t268, %t249
  %t273 = call i8* @malloc(i64 %t272)
  %t274 = bitcast i8* %t273 to i32*
  %t275 = icmp sgt i64 %t266, 0
  br i1 %t275, label %list_cow_copy_71, label %list_cow_after_copy_72
list_cow_copy_71:
  %t276 = mul i64 %t266, %t249
  %t277 = bitcast i32* %t264 to i8*
  call i8* @memcpy(i8* %t273, i8* %t277, i64 %t276)
  br label %list_cow_after_copy_72
list_cow_after_copy_72:
  %t278 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t271, i32 0, i32 0
  store i32* %t274, i32** %t278
  %t279 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t271, i32 0, i32 1
  store i64 %t266, i64* %t279
  %t280 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t271, i32 0, i32 2
  store i64 %t268, i64* %t280
  call void @star_rc_release(i8* %t250)
  store i8* %t270, i8** %t0
  br label %list_cow_done_69
list_cow_done_69:
  %t281 = load i8*, i8** %t0
  %t282 = bitcast i8* %t281 to { i32*, i64, i64 }*
  %t283 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t282, i32 0, i32 0
  %t284 = load i32*, i32** %t283
  %t285 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t282, i32 0, i32 1
  %t286 = load i64, i64* %t285
  %t287 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t282, i32 0, i32 2
  %t288 = icmp eq i64 %t286, 0
  br i1 %t288, label %list_pop_empty_73, label %list_pop_nonempty_74
list_pop_nonempty_74:
  %t289 = sub i64 %t286, 1
  store i64 %t289, i64* %t285
  %t290 = load i32*, i32** %t283
  %t291 = getelementptr inbounds i32, i32* %t290, i64 %t289
  %t292 = load i32, i32* %t291
  br label %list_pop_end_75
list_pop_empty_73:
  br label %list_pop_end_75
list_pop_end_75:
  %t293 = phi i32 [ %t292, %list_pop_nonempty_74 ], [ 0, %list_pop_empty_73 ]
  store i32 %t293, i32* %t247
  %t294 = load i32, i32* %t247
  %t295 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t295, i32 %t294)
  %t296 = load i8*, i8** %t0
  %t297 = icmp eq i8* %t296, null
  br i1 %t297, label %list_read_null_76, label %list_read_real_77
list_read_null_76:
  br label %list_read_end_78
list_read_real_77:
  %t298 = bitcast i8* %t296 to { i32*, i64, i64 }*
  %t299 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t298, i32 0, i32 0
  %t300 = load i32*, i32** %t299
  %t301 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t298, i32 0, i32 1
  %t302 = load i64, i64* %t301
  br label %list_read_end_78
list_read_end_78:
  %t303 = phi i32* [ null, %list_read_null_76 ], [ %t300, %list_read_real_77 ]
  %t304 = phi i64 [ 0, %list_read_null_76 ], [ %t302, %list_read_real_77 ]
  %t305 = trunc i64 %t304 to i32
  %t306 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t306, i32 %t305)
  %t307 = load i8*, i8** %t0
  %t308 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t308)
  %t309 = call i32 @sum_list(i8* %t307)
  %t310 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t310, i32 %t309)
  store i8* null, i8** %t311
  %t312 = load i8*, i8** %t311
  %t313 = icmp eq i8* %t312, null
  br i1 %t313, label %list_read_null_79, label %list_read_real_80
list_read_null_79:
  br label %list_read_end_81
list_read_real_80:
  %t314 = bitcast i8* %t312 to { i32*, i64, i64 }*
  %t315 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t314, i32 0, i32 0
  %t316 = load i32*, i32** %t315
  %t317 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t314, i32 0, i32 1
  %t318 = load i64, i64* %t317
  br label %list_read_end_81
list_read_end_81:
  %t319 = phi i32* [ null, %list_read_null_79 ], [ %t316, %list_read_real_80 ]
  %t320 = phi i64 [ 0, %list_read_null_79 ], [ %t318, %list_read_real_80 ]
  %t321 = trunc i64 %t320 to i32
  %t322 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t322, i32 %t321)
  %t324 = getelementptr i32, i32* null, i32 1
  %t325 = ptrtoint i32* %t324 to i64
  %t326 = load i8*, i8** %t311
  %t327 = icmp eq i8* %t326, null
  br i1 %t327, label %list_cow_alloc_82, label %list_cow_check_83
list_cow_alloc_82:
  %t328 = bitcast void (i8*)* @list_release_i32 to i8*
  %t329 = call i8* @star_rc_alloc(i64 24, i8* %t328)
  %t330 = bitcast i8* %t329 to { i32*, i64, i64 }*
  %t331 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t330, i32 0, i32 0
  store i32* null, i32** %t331
  %t332 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t330, i32 0, i32 1
  store i64 0, i64* %t332
  %t333 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t330, i32 0, i32 2
  store i64 0, i64* %t333
  store i8* %t329, i8** %t311
  br label %list_cow_done_84
list_cow_check_83:
  %t334 = getelementptr inbounds i8, i8* %t326, i64 -16
  %t335 = bitcast i8* %t334 to i64*
  %t336 = load atomic i64, i64* %t335 seq_cst, align 8
  %t337 = icmp eq i64 %t336, 1
  br i1 %t337, label %list_cow_done_84, label %list_cow_clone_85
list_cow_clone_85:
  %t338 = bitcast i8* %t326 to { i32*, i64, i64 }*
  %t339 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t338, i32 0, i32 0
  %t340 = load i32*, i32** %t339
  %t341 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t338, i32 0, i32 1
  %t342 = load i64, i64* %t341
  %t343 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t338, i32 0, i32 2
  %t344 = load i64, i64* %t343
  %t345 = bitcast void (i8*)* @list_release_i32 to i8*
  %t346 = call i8* @star_rc_alloc(i64 24, i8* %t345)
  %t347 = bitcast i8* %t346 to { i32*, i64, i64 }*
  %t348 = mul i64 %t344, %t325
  %t349 = call i8* @malloc(i64 %t348)
  %t350 = bitcast i8* %t349 to i32*
  %t351 = icmp sgt i64 %t342, 0
  br i1 %t351, label %list_cow_copy_86, label %list_cow_after_copy_87
list_cow_copy_86:
  %t352 = mul i64 %t342, %t325
  %t353 = bitcast i32* %t340 to i8*
  call i8* @memcpy(i8* %t349, i8* %t353, i64 %t352)
  br label %list_cow_after_copy_87
list_cow_after_copy_87:
  %t354 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t347, i32 0, i32 0
  store i32* %t350, i32** %t354
  %t355 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t347, i32 0, i32 1
  store i64 %t342, i64* %t355
  %t356 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t347, i32 0, i32 2
  store i64 %t344, i64* %t356
  call void @star_rc_release(i8* %t326)
  store i8* %t346, i8** %t311
  br label %list_cow_done_84
list_cow_done_84:
  %t357 = load i8*, i8** %t311
  %t358 = bitcast i8* %t357 to { i32*, i64, i64 }*
  %t359 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t358, i32 0, i32 0
  %t360 = load i32*, i32** %t359
  %t361 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t358, i32 0, i32 1
  %t362 = load i64, i64* %t361
  %t363 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t358, i32 0, i32 2
  %t364 = icmp eq i64 %t362, 0
  br i1 %t364, label %list_pop_empty_88, label %list_pop_nonempty_89
list_pop_nonempty_89:
  %t365 = sub i64 %t362, 1
  store i64 %t365, i64* %t361
  %t366 = load i32*, i32** %t359
  %t367 = getelementptr inbounds i32, i32* %t366, i64 %t365
  %t368 = load i32, i32* %t367
  br label %list_pop_end_90
list_pop_empty_88:
  br label %list_pop_end_90
list_pop_end_90:
  %t369 = phi i32 [ %t368, %list_pop_nonempty_89 ], [ 0, %list_pop_empty_88 ]
  store i32 %t369, i32* %t323
  %t370 = load i32, i32* %t323
  %t371 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t371, i32 %t370)
  %t373 = load i8*, i8** %t311
  %t374 = icmp eq i8* %t373, null
  br i1 %t374, label %list_read_null_91, label %list_read_real_92
list_read_null_91:
  br label %list_read_end_93
list_read_real_92:
  %t375 = bitcast i8* %t373 to { i32*, i64, i64 }*
  %t376 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t375, i32 0, i32 0
  %t377 = load i32*, i32** %t376
  %t378 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t375, i32 0, i32 1
  %t379 = load i64, i64* %t378
  br label %list_read_end_93
list_read_end_93:
  %t380 = phi i32* [ null, %list_read_null_91 ], [ %t377, %list_read_real_92 ]
  %t381 = phi i64 [ 0, %list_read_null_91 ], [ %t379, %list_read_real_92 ]
  %t382 = sext i32 0 to i64
  %t383 = icmp ult i64 %t382, %t381
  br i1 %t383, label %list_idx_ok_94, label %list_idx_oob_95
list_idx_ok_94:
  %t384 = getelementptr inbounds i32, i32* %t380, i64 %t382
  %t385 = load i32, i32* %t384
  br label %list_idx_end_96
list_idx_oob_95:
  br label %list_idx_end_96
list_idx_end_96:
  %t386 = phi i32 [ %t385, %list_idx_ok_94 ], [ 0, %list_idx_oob_95 ]
  store i32 %t386, i32* %t372
  %t387 = load i32, i32* %t372
  %t388 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t388, i32 %t387)
  store i8* null, i8** %t389
  store i32 0, i32* %t390
  br label %while_cond_97
while_cond_97:
  %t391 = load i32, i32* %t390
  %t392 = icmp slt i32 %t391, 20
  br i1 %t392, label %while_body_98, label %while_else_99
while_body_98:
  %t393 = getelementptr i32, i32* null, i32 1
  %t394 = ptrtoint i32* %t393 to i64
  %t395 = load i8*, i8** %t389
  %t396 = icmp eq i8* %t395, null
  br i1 %t396, label %list_cow_alloc_101, label %list_cow_check_102
list_cow_alloc_101:
  %t397 = bitcast void (i8*)* @list_release_i32 to i8*
  %t398 = call i8* @star_rc_alloc(i64 24, i8* %t397)
  %t399 = bitcast i8* %t398 to { i32*, i64, i64 }*
  %t400 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t399, i32 0, i32 0
  store i32* null, i32** %t400
  %t401 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t399, i32 0, i32 1
  store i64 0, i64* %t401
  %t402 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t399, i32 0, i32 2
  store i64 0, i64* %t402
  store i8* %t398, i8** %t389
  br label %list_cow_done_103
list_cow_check_102:
  %t403 = getelementptr inbounds i8, i8* %t395, i64 -16
  %t404 = bitcast i8* %t403 to i64*
  %t405 = load atomic i64, i64* %t404 seq_cst, align 8
  %t406 = icmp eq i64 %t405, 1
  br i1 %t406, label %list_cow_done_103, label %list_cow_clone_104
list_cow_clone_104:
  %t407 = bitcast i8* %t395 to { i32*, i64, i64 }*
  %t408 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t407, i32 0, i32 0
  %t409 = load i32*, i32** %t408
  %t410 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t407, i32 0, i32 1
  %t411 = load i64, i64* %t410
  %t412 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t407, i32 0, i32 2
  %t413 = load i64, i64* %t412
  %t414 = bitcast void (i8*)* @list_release_i32 to i8*
  %t415 = call i8* @star_rc_alloc(i64 24, i8* %t414)
  %t416 = bitcast i8* %t415 to { i32*, i64, i64 }*
  %t417 = mul i64 %t413, %t394
  %t418 = call i8* @malloc(i64 %t417)
  %t419 = bitcast i8* %t418 to i32*
  %t420 = icmp sgt i64 %t411, 0
  br i1 %t420, label %list_cow_copy_105, label %list_cow_after_copy_106
list_cow_copy_105:
  %t421 = mul i64 %t411, %t394
  %t422 = bitcast i32* %t409 to i8*
  call i8* @memcpy(i8* %t418, i8* %t422, i64 %t421)
  br label %list_cow_after_copy_106
list_cow_after_copy_106:
  %t423 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t416, i32 0, i32 0
  store i32* %t419, i32** %t423
  %t424 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t416, i32 0, i32 1
  store i64 %t411, i64* %t424
  %t425 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t416, i32 0, i32 2
  store i64 %t413, i64* %t425
  call void @star_rc_release(i8* %t395)
  store i8* %t415, i8** %t389
  br label %list_cow_done_103
list_cow_done_103:
  %t426 = load i8*, i8** %t389
  %t427 = bitcast i8* %t426 to { i32*, i64, i64 }*
  %t428 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t427, i32 0, i32 0
  %t429 = load i32*, i32** %t428
  %t430 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t427, i32 0, i32 1
  %t431 = load i64, i64* %t430
  %t432 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t427, i32 0, i32 2
  %t433 = load i32, i32* %t390
  %t434 = load i64, i64* %t432
  %t435 = load i32*, i32** %t428
  %t436 = load i64, i64* %t430
  %t437 = icmp sge i64 %t436, %t434
  br i1 %t437, label %list_push_grow_107, label %list_push_store_108
list_push_grow_107:
  %t438 = mul i64 %t434, 2
  %t439 = icmp sgt i64 %t438, 0
  %t440 = select i1 %t439, i64 %t438, i64 1
  %t441 = getelementptr i32, i32* null, i32 1
  %t442 = ptrtoint i32* %t441 to i64
  %t443 = mul i64 %t440, %t442
  %t444 = call i8* @malloc(i64 %t443)
  %t445 = bitcast i8* %t444 to i32*
  %t446 = icmp sgt i64 %t434, 0
  br i1 %t446, label %list_push_copy_109, label %list_push_after_copy_110
list_push_copy_109:
  %t447 = mul i64 %t436, %t442
  %t448 = bitcast i32* %t435 to i8*
  call i8* @memcpy(i8* %t444, i8* %t448, i64 %t447)
  call void @free(i8* %t448)
  br label %list_push_after_copy_110
list_push_after_copy_110:
  store i32* %t445, i32** %t428
  store i64 %t440, i64* %t432
  br label %list_push_store_108
list_push_store_108:
  %t449 = load i32*, i32** %t428
  %t450 = getelementptr inbounds i32, i32* %t449, i64 %t436
  store i32 %t433, i32* %t450
  %t451 = add i64 %t436, 1
  store i64 %t451, i64* %t430
  %t452 = load i32, i32* %t390
  %t453 = add i32 %t452, 1
  store i32 %t453, i32* %t390
  br label %while_cond_97
while_else_99:
  br label %while_end_100
while_end_100:
  %t454 = load i8*, i8** %t389
  %t455 = icmp eq i8* %t454, null
  br i1 %t455, label %list_read_null_111, label %list_read_real_112
list_read_null_111:
  br label %list_read_end_113
list_read_real_112:
  %t456 = bitcast i8* %t454 to { i32*, i64, i64 }*
  %t457 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t456, i32 0, i32 0
  %t458 = load i32*, i32** %t457
  %t459 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t456, i32 0, i32 1
  %t460 = load i64, i64* %t459
  br label %list_read_end_113
list_read_end_113:
  %t461 = phi i32* [ null, %list_read_null_111 ], [ %t458, %list_read_real_112 ]
  %t462 = phi i64 [ 0, %list_read_null_111 ], [ %t460, %list_read_real_112 ]
  %t463 = trunc i64 %t462 to i32
  %t464 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t464, i32 %t463)
  %t465 = load i8*, i8** %t389
  %t466 = icmp eq i8* %t465, null
  br i1 %t466, label %list_read_null_114, label %list_read_real_115
list_read_null_114:
  br label %list_read_end_116
list_read_real_115:
  %t467 = bitcast i8* %t465 to { i32*, i64, i64 }*
  %t468 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t467, i32 0, i32 0
  %t469 = load i32*, i32** %t468
  %t470 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t467, i32 0, i32 1
  %t471 = load i64, i64* %t470
  br label %list_read_end_116
list_read_end_116:
  %t472 = phi i32* [ null, %list_read_null_114 ], [ %t469, %list_read_real_115 ]
  %t473 = phi i64 [ 0, %list_read_null_114 ], [ %t471, %list_read_real_115 ]
  %t474 = sext i32 19 to i64
  %t475 = icmp ult i64 %t474, %t473
  br i1 %t475, label %list_idx_ok_117, label %list_idx_oob_118
list_idx_ok_117:
  %t476 = getelementptr inbounds i32, i32* %t472, i64 %t474
  %t477 = load i32, i32* %t476
  br label %list_idx_end_119
list_idx_oob_118:
  br label %list_idx_end_119
list_idx_end_119:
  %t478 = phi i32 [ %t477, %list_idx_ok_117 ], [ 0, %list_idx_oob_118 ]
  %t479 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t479, i32 %t478)
  %t480 = load i8*, i8** %t389
  %t481 = icmp eq i8* %t480, null
  br i1 %t481, label %list_read_null_120, label %list_read_real_121
list_read_null_120:
  br label %list_read_end_122
list_read_real_121:
  %t482 = bitcast i8* %t480 to { i32*, i64, i64 }*
  %t483 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t482, i32 0, i32 0
  %t484 = load i32*, i32** %t483
  %t485 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t482, i32 0, i32 1
  %t486 = load i64, i64* %t485
  br label %list_read_end_122
list_read_end_122:
  %t487 = phi i32* [ null, %list_read_null_120 ], [ %t484, %list_read_real_121 ]
  %t488 = phi i64 [ 0, %list_read_null_120 ], [ %t486, %list_read_real_121 ]
  %t489 = sext i32 0 to i64
  %t490 = icmp ult i64 %t489, %t488
  br i1 %t490, label %list_idx_ok_123, label %list_idx_oob_124
list_idx_ok_123:
  %t491 = getelementptr inbounds i32, i32* %t487, i64 %t489
  %t492 = load i32, i32* %t491
  br label %list_idx_end_125
list_idx_oob_124:
  br label %list_idx_end_125
list_idx_end_125:
  %t493 = phi i32 [ %t492, %list_idx_ok_123 ], [ 0, %list_idx_oob_124 ]
  %t494 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t494, i32 %t493)
  %t496 = getelementptr i8*, i8** null, i32 1
  %t497 = ptrtoint i8** %t496 to i64
  %t498 = mul i64 %t497, 3
  %t499 = call i8* @malloc(i64 %t498)
  %t500 = bitcast i8* %t499 to i8**
  %t501 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t502 = getelementptr inbounds i8*, i8** %t500, i64 0
  store i8* %t501, i8** %t502
  %t503 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t504 = getelementptr inbounds i8*, i8** %t500, i64 1
  store i8* %t503, i8** %t504
  %t505 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t506 = getelementptr inbounds i8*, i8** %t500, i64 2
  store i8* %t505, i8** %t506
  %t519 = bitcast void (i8*)* @list_release_str to i8*
  %t520 = call i8* @star_rc_alloc(i64 24, i8* %t519)
  %t521 = bitcast i8* %t520 to { i8**, i64, i64 }*
  %t522 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t521, i32 0, i32 0
  store i8** %t500, i8*** %t522
  %t523 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t521, i32 0, i32 1
  store i64 3, i64* %t523
  %t524 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t521, i32 0, i32 2
  store i64 3, i64* %t524
  store i8* %t520, i8** %t495
  %t525 = load i8*, i8** %t495
  %t526 = icmp eq i8* %t525, null
  br i1 %t526, label %list_read_null_129, label %list_read_real_130
list_read_null_129:
  br label %list_read_end_131
list_read_real_130:
  %t527 = bitcast i8* %t525 to { i8**, i64, i64 }*
  %t528 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t527, i32 0, i32 0
  %t529 = load i8**, i8*** %t528
  %t530 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t527, i32 0, i32 1
  %t531 = load i64, i64* %t530
  br label %list_read_end_131
list_read_end_131:
  %t532 = phi i8** [ null, %list_read_null_129 ], [ %t529, %list_read_real_130 ]
  %t533 = phi i64 [ 0, %list_read_null_129 ], [ %t531, %list_read_real_130 ]
  %t534 = trunc i64 %t533 to i32
  %t535 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t535, i32 %t534)
  %t536 = load i8*, i8** %t495
  %t537 = icmp eq i8* %t536, null
  br i1 %t537, label %list_read_null_132, label %list_read_real_133
list_read_null_132:
  br label %list_read_end_134
list_read_real_133:
  %t538 = bitcast i8* %t536 to { i8**, i64, i64 }*
  %t539 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t538, i32 0, i32 0
  %t540 = load i8**, i8*** %t539
  %t541 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t538, i32 0, i32 1
  %t542 = load i64, i64* %t541
  br label %list_read_end_134
list_read_end_134:
  %t543 = phi i8** [ null, %list_read_null_132 ], [ %t540, %list_read_real_133 ]
  %t544 = phi i64 [ 0, %list_read_null_132 ], [ %t542, %list_read_real_133 ]
  %t545 = sext i32 1 to i64
  %t546 = icmp ult i64 %t545, %t544
  br i1 %t546, label %list_idx_ok_135, label %list_idx_oob_136
list_idx_ok_135:
  %t547 = getelementptr inbounds i8*, i8** %t543, i64 %t545
  %t548 = load i8*, i8** %t547
  %t549 = load i8*, i8** %t547
  call void @star_rc_retain(i8* %t549)
  br label %list_idx_end_137
list_idx_oob_136:
  br label %list_idx_end_137
list_idx_end_137:
  %t550 = phi i8* [ %t548, %list_idx_ok_135 ], [ null, %list_idx_oob_136 ]
  call void @star_rc_release(i8* %t550)
  %t551 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t551, i8* %t550)
  %t553 = getelementptr %Point, %Point* null, i32 1
  %t554 = ptrtoint %Point* %t553 to i64
  %t555 = mul i64 %t554, 2
  %t556 = call i8* @malloc(i64 %t555)
  %t557 = bitcast i8* %t556 to %Point*
  %t559 = getelementptr inbounds %Point, %Point* %t558, i32 0, i32 0
  store i32 1, i32* %t559
  %t560 = getelementptr inbounds %Point, %Point* %t558, i32 0, i32 1
  store i32 2, i32* %t560
  %t561 = load %Point, %Point* %t558
  %t562 = getelementptr inbounds %Point, %Point* %t557, i64 0
  store %Point %t561, %Point* %t562
  %t564 = getelementptr inbounds %Point, %Point* %t563, i32 0, i32 0
  store i32 3, i32* %t564
  %t565 = getelementptr inbounds %Point, %Point* %t563, i32 0, i32 1
  store i32 4, i32* %t565
  %t566 = load %Point, %Point* %t563
  %t567 = getelementptr inbounds %Point, %Point* %t557, i64 1
  store %Point %t566, %Point* %t567
  %t572 = bitcast void (i8*)* @list_release_s_Point to i8*
  %t573 = call i8* @star_rc_alloc(i64 24, i8* %t572)
  %t574 = bitcast i8* %t573 to { %Point*, i64, i64 }*
  %t575 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t574, i32 0, i32 0
  store %Point* %t557, %Point** %t575
  %t576 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t574, i32 0, i32 1
  store i64 2, i64* %t576
  %t577 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t574, i32 0, i32 2
  store i64 2, i64* %t577
  store i8* %t573, i8** %t552
  %t579 = load i8*, i8** %t552
  %t580 = icmp eq i8* %t579, null
  br i1 %t580, label %list_read_null_138, label %list_read_real_139
list_read_null_138:
  br label %list_read_end_140
list_read_real_139:
  %t581 = bitcast i8* %t579 to { %Point*, i64, i64 }*
  %t582 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t581, i32 0, i32 0
  %t583 = load %Point*, %Point** %t582
  %t584 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t581, i32 0, i32 1
  %t585 = load i64, i64* %t584
  br label %list_read_end_140
list_read_end_140:
  %t586 = phi %Point* [ null, %list_read_null_138 ], [ %t583, %list_read_real_139 ]
  %t587 = phi i64 [ 0, %list_read_null_138 ], [ %t585, %list_read_real_139 ]
  %t588 = sext i32 1 to i64
  %t589 = icmp ult i64 %t588, %t587
  br i1 %t589, label %list_idx_ok_141, label %list_idx_oob_142
list_idx_ok_141:
  %t590 = getelementptr inbounds %Point, %Point* %t586, i64 %t588
  %t591 = load %Point, %Point* %t590
  br label %list_idx_end_143
list_idx_oob_142:
  br label %list_idx_end_143
list_idx_end_143:
  %t592 = phi %Point [ %t591, %list_idx_ok_141 ], [ zeroinitializer, %list_idx_oob_142 ]
  store %Point %t592, %Point* %t578
  %t593 = getelementptr inbounds %Point, %Point* %t578, i32 0, i32 0
  %t594 = load i32, i32* %t593
  %t595 = getelementptr inbounds %Point, %Point* %t578, i32 0, i32 1
  %t596 = load i32, i32* %t595
  %t597 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.18, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t597, i32 %t594, i32 %t596)
  %t598 = load i8*, i8** %t552
  call void @star_rc_release(i8* %t598)
  %t599 = load i8*, i8** %t495
  call void @star_rc_release(i8* %t599)
  %t600 = load i8*, i8** %t389
  call void @star_rc_release(i8* %t600)
  %t601 = load i8*, i8** %t311
  call void @star_rc_release(i8* %t601)
  %t602 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t602)
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
  %t512 = alloca i64
  %t507 = bitcast i8* %objp to { i8**, i64, i64 }*
  %t508 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t507, i32 0, i32 0
  %t509 = load i8**, i8*** %t508
  %t510 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t507, i32 0, i32 1
  %t511 = load i64, i64* %t510
  store i64 0, i64* %t512
  br label %list_release_cond_126
list_release_cond_126:
  %t513 = load i64, i64* %t512
  %t514 = icmp slt i64 %t513, %t511
  br i1 %t514, label %list_release_body_127, label %list_release_end_128
list_release_body_127:
  %t515 = getelementptr inbounds i8*, i8** %t509, i64 %t513
  %t516 = load i8*, i8** %t515
  call void @star_rc_release(i8* %t516)
  %t517 = add i64 %t513, 1
  store i64 %t517, i64* %t512
  br label %list_release_cond_126
list_release_end_128:
  %t518 = bitcast i8** %t509 to i8*
  call void @free(i8* %t518)
  ret void
}


define void @list_release_s_Point(i8* %objp) {
entry:
  %t568 = bitcast i8* %objp to { %Point*, i64, i64 }*
  %t569 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t568, i32 0, i32 0
  %t570 = load %Point*, %Point** %t569
  %t571 = bitcast %Point* %t570 to i8*
  call void @free(i8* %t571)
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
