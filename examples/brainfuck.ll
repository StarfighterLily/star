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

%GenRef = type { i32, i64 }

@frame.buf = global [4096 x i8] zeroinitializer
@frame.off = global i64 0

@star.argc = global i32 0
@star.argv = global i8** null

@rng.state = global i32 123456789
@rng.lock = global i8* null

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

declare i32 @putchar(i32)
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca i8*
  %t4 = alloca i32
  %t8 = alloca i8*
  %t9 = alloca i32
  %t76 = alloca i8*
  %t140 = alloca i8*
  %t144 = alloca i32
  %t220 = alloca i32
  %t359 = alloca i32
  %t360 = alloca i32
  %t364 = alloca i32
  %t383 = alloca i32
  %t450 = alloca i32
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = getelementptr inbounds { i64, i8*, [107 x i8] }, { i64, i8*, [107 x i8] }* @.str.0, i64 0, i32 2, i64 0
  store i8* %t3, i8** %t2
  %t5 = load i8*, i8** %t2
  %t6 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t6)
  %t7 = call i32 @strlen(i8* %t5)
  call void @star_rc_release(i8* %t5)
  store i32 %t7, i32* %t4
  store i8* null, i8** %t8
  store i32 0, i32* %t9
  br label %while_cond_0
while_cond_0:
  %t10 = load i32, i32* %t9
  %t11 = icmp slt i32 %t10, 30000
  br i1 %t11, label %while_body_1, label %while_else_2
while_body_1:
  %t12 = getelementptr i32, i32* null, i32 1
  %t13 = ptrtoint i32* %t12 to i64
  %t14 = load i8*, i8** %t8
  %t15 = icmp eq i8* %t14, null
  br i1 %t15, label %list_cow_alloc_4, label %list_cow_check_5
list_cow_alloc_4:
  %t20 = bitcast void (i8*)* @list_release_i32 to i8*
  %t21 = call i8* @star_rc_alloc(i64 24, i8* %t20)
  %t22 = bitcast i8* %t21 to { i32*, i64, i64 }*
  %t23 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t22, i32 0, i32 0
  store i32* null, i32** %t23
  %t24 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t22, i32 0, i32 1
  store i64 0, i64* %t24
  %t25 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t22, i32 0, i32 2
  store i64 0, i64* %t25
  store i8* %t21, i8** %t8
  br label %list_cow_done_6
list_cow_check_5:
  %t26 = getelementptr inbounds i8, i8* %t14, i64 -16
  %t27 = bitcast i8* %t26 to i64*
  %t28 = load atomic i64, i64* %t27 seq_cst, align 8
  %t29 = icmp eq i64 %t28, 1
  br i1 %t29, label %list_cow_done_6, label %list_cow_clone_7
list_cow_clone_7:
  %t30 = bitcast i8* %t14 to { i32*, i64, i64 }*
  %t31 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t30, i32 0, i32 0
  %t32 = load i32*, i32** %t31
  %t33 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t30, i32 0, i32 1
  %t34 = load i64, i64* %t33
  %t35 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t30, i32 0, i32 2
  %t36 = load i64, i64* %t35
  %t37 = bitcast void (i8*)* @list_release_i32 to i8*
  %t38 = call i8* @star_rc_alloc(i64 24, i8* %t37)
  %t39 = bitcast i8* %t38 to { i32*, i64, i64 }*
  %t40 = mul i64 %t36, %t13
  %t41 = call i8* @malloc(i64 %t40)
  %t42 = bitcast i8* %t41 to i32*
  %t43 = icmp sgt i64 %t34, 0
  br i1 %t43, label %list_cow_copy_8, label %list_cow_after_copy_9
list_cow_copy_8:
  %t44 = mul i64 %t34, %t13
  %t45 = bitcast i32* %t32 to i8*
  call i8* @memcpy(i8* %t41, i8* %t45, i64 %t44)
  br label %list_cow_after_copy_9
list_cow_after_copy_9:
  %t46 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t39, i32 0, i32 0
  store i32* %t42, i32** %t46
  %t47 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t39, i32 0, i32 1
  store i64 %t34, i64* %t47
  %t48 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t39, i32 0, i32 2
  store i64 %t36, i64* %t48
  call void @star_rc_release(i8* %t14)
  store i8* %t38, i8** %t8
  br label %list_cow_done_6
list_cow_done_6:
  %t49 = load i8*, i8** %t8
  %t50 = bitcast i8* %t49 to { i32*, i64, i64 }*
  %t51 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t50, i32 0, i32 0
  %t52 = load i32*, i32** %t51
  %t53 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t50, i32 0, i32 1
  %t54 = load i64, i64* %t53
  %t55 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t50, i32 0, i32 2
  %t56 = load i64, i64* %t55
  %t57 = load i32*, i32** %t51
  %t58 = load i64, i64* %t53
  %t59 = icmp sge i64 %t58, %t56
  br i1 %t59, label %list_push_grow_10, label %list_push_store_11
list_push_grow_10:
  %t60 = mul i64 %t56, 2
  %t61 = icmp sgt i64 %t60, 0
  %t62 = select i1 %t61, i64 %t60, i64 1
  %t63 = getelementptr i32, i32* null, i32 1
  %t64 = ptrtoint i32* %t63 to i64
  %t65 = mul i64 %t62, %t64
  %t66 = call i8* @malloc(i64 %t65)
  %t67 = bitcast i8* %t66 to i32*
  %t68 = icmp sgt i64 %t56, 0
  br i1 %t68, label %list_push_copy_12, label %list_push_after_copy_13
list_push_copy_12:
  %t69 = mul i64 %t58, %t64
  %t70 = bitcast i32* %t57 to i8*
  call i8* @memcpy(i8* %t66, i8* %t70, i64 %t69)
  call void @free(i8* %t70)
  br label %list_push_after_copy_13
list_push_after_copy_13:
  store i32* %t67, i32** %t51
  store i64 %t62, i64* %t55
  br label %list_push_store_11
list_push_store_11:
  %t71 = load i32*, i32** %t51
  %t72 = getelementptr inbounds i32, i32* %t71, i64 %t58
  store i32 0, i32* %t72
  %t73 = add i64 %t58, 1
  store i64 %t73, i64* %t53
  %t74 = load i32, i32* %t9
  %t75 = add i32 %t74, 1
  store i32 %t75, i32* %t9
  br label %while_cond_0
while_else_2:
  br label %while_end_3
while_end_3:
  store i8* null, i8** %t76
  store i32 0, i32* %t9
  br label %while_cond_14
while_cond_14:
  %t77 = load i32, i32* %t9
  %t78 = load i32, i32* %t4
  %t79 = icmp slt i32 %t77, %t78
  br i1 %t79, label %while_body_15, label %while_else_16
while_body_15:
  %t80 = getelementptr i32, i32* null, i32 1
  %t81 = ptrtoint i32* %t80 to i64
  %t82 = load i8*, i8** %t76
  %t83 = icmp eq i8* %t82, null
  br i1 %t83, label %list_cow_alloc_18, label %list_cow_check_19
list_cow_alloc_18:
  %t84 = bitcast void (i8*)* @list_release_i32 to i8*
  %t85 = call i8* @star_rc_alloc(i64 24, i8* %t84)
  %t86 = bitcast i8* %t85 to { i32*, i64, i64 }*
  %t87 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t86, i32 0, i32 0
  store i32* null, i32** %t87
  %t88 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t86, i32 0, i32 1
  store i64 0, i64* %t88
  %t89 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t86, i32 0, i32 2
  store i64 0, i64* %t89
  store i8* %t85, i8** %t76
  br label %list_cow_done_20
list_cow_check_19:
  %t90 = getelementptr inbounds i8, i8* %t82, i64 -16
  %t91 = bitcast i8* %t90 to i64*
  %t92 = load atomic i64, i64* %t91 seq_cst, align 8
  %t93 = icmp eq i64 %t92, 1
  br i1 %t93, label %list_cow_done_20, label %list_cow_clone_21
list_cow_clone_21:
  %t94 = bitcast i8* %t82 to { i32*, i64, i64 }*
  %t95 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t94, i32 0, i32 0
  %t96 = load i32*, i32** %t95
  %t97 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t94, i32 0, i32 1
  %t98 = load i64, i64* %t97
  %t99 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t94, i32 0, i32 2
  %t100 = load i64, i64* %t99
  %t101 = bitcast void (i8*)* @list_release_i32 to i8*
  %t102 = call i8* @star_rc_alloc(i64 24, i8* %t101)
  %t103 = bitcast i8* %t102 to { i32*, i64, i64 }*
  %t104 = mul i64 %t100, %t81
  %t105 = call i8* @malloc(i64 %t104)
  %t106 = bitcast i8* %t105 to i32*
  %t107 = icmp sgt i64 %t98, 0
  br i1 %t107, label %list_cow_copy_22, label %list_cow_after_copy_23
list_cow_copy_22:
  %t108 = mul i64 %t98, %t81
  %t109 = bitcast i32* %t96 to i8*
  call i8* @memcpy(i8* %t105, i8* %t109, i64 %t108)
  br label %list_cow_after_copy_23
list_cow_after_copy_23:
  %t110 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t103, i32 0, i32 0
  store i32* %t106, i32** %t110
  %t111 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t103, i32 0, i32 1
  store i64 %t98, i64* %t111
  %t112 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t103, i32 0, i32 2
  store i64 %t100, i64* %t112
  call void @star_rc_release(i8* %t82)
  store i8* %t102, i8** %t76
  br label %list_cow_done_20
list_cow_done_20:
  %t113 = load i8*, i8** %t76
  %t114 = bitcast i8* %t113 to { i32*, i64, i64 }*
  %t115 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t114, i32 0, i32 0
  %t116 = load i32*, i32** %t115
  %t117 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t114, i32 0, i32 1
  %t118 = load i64, i64* %t117
  %t119 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t114, i32 0, i32 2
  %t120 = load i64, i64* %t119
  %t121 = load i32*, i32** %t115
  %t122 = load i64, i64* %t117
  %t123 = icmp sge i64 %t122, %t120
  br i1 %t123, label %list_push_grow_24, label %list_push_store_25
list_push_grow_24:
  %t124 = mul i64 %t120, 2
  %t125 = icmp sgt i64 %t124, 0
  %t126 = select i1 %t125, i64 %t124, i64 1
  %t127 = getelementptr i32, i32* null, i32 1
  %t128 = ptrtoint i32* %t127 to i64
  %t129 = mul i64 %t126, %t128
  %t130 = call i8* @malloc(i64 %t129)
  %t131 = bitcast i8* %t130 to i32*
  %t132 = icmp sgt i64 %t120, 0
  br i1 %t132, label %list_push_copy_26, label %list_push_after_copy_27
list_push_copy_26:
  %t133 = mul i64 %t122, %t128
  %t134 = bitcast i32* %t121 to i8*
  call i8* @memcpy(i8* %t130, i8* %t134, i64 %t133)
  call void @free(i8* %t134)
  br label %list_push_after_copy_27
list_push_after_copy_27:
  store i32* %t131, i32** %t115
  store i64 %t126, i64* %t119
  br label %list_push_store_25
list_push_store_25:
  %t135 = load i32*, i32** %t115
  %t136 = getelementptr inbounds i32, i32* %t135, i64 %t122
  store i32 0, i32* %t136
  %t137 = add i64 %t122, 1
  store i64 %t137, i64* %t117
  %t138 = load i32, i32* %t9
  %t139 = add i32 %t138, 1
  store i32 %t139, i32* %t9
  br label %while_cond_14
while_else_16:
  br label %while_end_17
while_end_17:
  store i8* null, i8** %t140
  store i32 0, i32* %t9
  br label %while_cond_28
while_cond_28:
  %t141 = load i32, i32* %t9
  %t142 = load i32, i32* %t4
  %t143 = icmp slt i32 %t141, %t142
  br i1 %t143, label %while_body_29, label %while_else_30
while_body_29:
  %t145 = load i8*, i8** %t2
  %t146 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t146)
  %t147 = load i32, i32* %t9
  %t148 = sext i32 %t147 to i64
  %t149 = icmp eq i8* %t145, null
  br i1 %t149, label %str_idx_oob_34, label %str_idx_chk_32
str_idx_chk_32:
  %t150 = call i32 @strlen(i8* %t145)
  %t151 = sext i32 %t150 to i64
  %t152 = icmp ult i64 %t148, %t151
  br i1 %t152, label %str_idx_ok_33, label %str_idx_oob_34
str_idx_ok_33:
  %t153 = getelementptr inbounds i8, i8* %t145, i64 %t148
  %t154 = load i8, i8* %t153
  %t155 = zext i8 %t154 to i32
  br label %str_idx_end_35
str_idx_oob_34:
  br label %str_idx_end_35
str_idx_end_35:
  %t156 = phi i32 [ %t155, %str_idx_ok_33 ], [ 0, %str_idx_oob_34 ]
  call void @star_rc_release(i8* %t145)
  store i32 %t156, i32* %t144
  %t157 = load i32, i32* %t144
  %t158 = icmp eq i32 %t157, 91
  br i1 %t158, label %if_then_36, label %if_else_37
if_then_36:
  %t159 = getelementptr i32, i32* null, i32 1
  %t160 = ptrtoint i32* %t159 to i64
  %t161 = load i8*, i8** %t140
  %t162 = icmp eq i8* %t161, null
  br i1 %t162, label %list_cow_alloc_39, label %list_cow_check_40
list_cow_alloc_39:
  %t163 = bitcast void (i8*)* @list_release_i32 to i8*
  %t164 = call i8* @star_rc_alloc(i64 24, i8* %t163)
  %t165 = bitcast i8* %t164 to { i32*, i64, i64 }*
  %t166 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t165, i32 0, i32 0
  store i32* null, i32** %t166
  %t167 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t165, i32 0, i32 1
  store i64 0, i64* %t167
  %t168 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t165, i32 0, i32 2
  store i64 0, i64* %t168
  store i8* %t164, i8** %t140
  br label %list_cow_done_41
list_cow_check_40:
  %t169 = getelementptr inbounds i8, i8* %t161, i64 -16
  %t170 = bitcast i8* %t169 to i64*
  %t171 = load atomic i64, i64* %t170 seq_cst, align 8
  %t172 = icmp eq i64 %t171, 1
  br i1 %t172, label %list_cow_done_41, label %list_cow_clone_42
list_cow_clone_42:
  %t173 = bitcast i8* %t161 to { i32*, i64, i64 }*
  %t174 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t173, i32 0, i32 0
  %t175 = load i32*, i32** %t174
  %t176 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t173, i32 0, i32 1
  %t177 = load i64, i64* %t176
  %t178 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t173, i32 0, i32 2
  %t179 = load i64, i64* %t178
  %t180 = bitcast void (i8*)* @list_release_i32 to i8*
  %t181 = call i8* @star_rc_alloc(i64 24, i8* %t180)
  %t182 = bitcast i8* %t181 to { i32*, i64, i64 }*
  %t183 = mul i64 %t179, %t160
  %t184 = call i8* @malloc(i64 %t183)
  %t185 = bitcast i8* %t184 to i32*
  %t186 = icmp sgt i64 %t177, 0
  br i1 %t186, label %list_cow_copy_43, label %list_cow_after_copy_44
list_cow_copy_43:
  %t187 = mul i64 %t177, %t160
  %t188 = bitcast i32* %t175 to i8*
  call i8* @memcpy(i8* %t184, i8* %t188, i64 %t187)
  br label %list_cow_after_copy_44
list_cow_after_copy_44:
  %t189 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t182, i32 0, i32 0
  store i32* %t185, i32** %t189
  %t190 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t182, i32 0, i32 1
  store i64 %t177, i64* %t190
  %t191 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t182, i32 0, i32 2
  store i64 %t179, i64* %t191
  call void @star_rc_release(i8* %t161)
  store i8* %t181, i8** %t140
  br label %list_cow_done_41
list_cow_done_41:
  %t192 = load i8*, i8** %t140
  %t193 = bitcast i8* %t192 to { i32*, i64, i64 }*
  %t194 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t193, i32 0, i32 0
  %t195 = load i32*, i32** %t194
  %t196 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t193, i32 0, i32 1
  %t197 = load i64, i64* %t196
  %t198 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t193, i32 0, i32 2
  %t199 = load i32, i32* %t9
  %t200 = load i64, i64* %t198
  %t201 = load i32*, i32** %t194
  %t202 = load i64, i64* %t196
  %t203 = icmp sge i64 %t202, %t200
  br i1 %t203, label %list_push_grow_45, label %list_push_store_46
list_push_grow_45:
  %t204 = mul i64 %t200, 2
  %t205 = icmp sgt i64 %t204, 0
  %t206 = select i1 %t205, i64 %t204, i64 1
  %t207 = getelementptr i32, i32* null, i32 1
  %t208 = ptrtoint i32* %t207 to i64
  %t209 = mul i64 %t206, %t208
  %t210 = call i8* @malloc(i64 %t209)
  %t211 = bitcast i8* %t210 to i32*
  %t212 = icmp sgt i64 %t200, 0
  br i1 %t212, label %list_push_copy_47, label %list_push_after_copy_48
list_push_copy_47:
  %t213 = mul i64 %t202, %t208
  %t214 = bitcast i32* %t201 to i8*
  call i8* @memcpy(i8* %t210, i8* %t214, i64 %t213)
  call void @free(i8* %t214)
  br label %list_push_after_copy_48
list_push_after_copy_48:
  store i32* %t211, i32** %t194
  store i64 %t206, i64* %t198
  br label %list_push_store_46
list_push_store_46:
  %t215 = load i32*, i32** %t194
  %t216 = getelementptr inbounds i32, i32* %t215, i64 %t202
  store i32 %t199, i32* %t216
  %t217 = add i64 %t202, 1
  store i64 %t217, i64* %t196
  br label %if_end_38
if_else_37:
  br label %if_end_38
if_end_38:
  %t218 = load i32, i32* %t144
  %t219 = icmp eq i32 %t218, 93
  br i1 %t219, label %if_then_49, label %if_else_50
if_then_49:
  %t221 = getelementptr i32, i32* null, i32 1
  %t222 = ptrtoint i32* %t221 to i64
  %t223 = load i8*, i8** %t140
  %t224 = icmp eq i8* %t223, null
  br i1 %t224, label %list_cow_alloc_52, label %list_cow_check_53
list_cow_alloc_52:
  %t225 = bitcast void (i8*)* @list_release_i32 to i8*
  %t226 = call i8* @star_rc_alloc(i64 24, i8* %t225)
  %t227 = bitcast i8* %t226 to { i32*, i64, i64 }*
  %t228 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t227, i32 0, i32 0
  store i32* null, i32** %t228
  %t229 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t227, i32 0, i32 1
  store i64 0, i64* %t229
  %t230 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t227, i32 0, i32 2
  store i64 0, i64* %t230
  store i8* %t226, i8** %t140
  br label %list_cow_done_54
list_cow_check_53:
  %t231 = getelementptr inbounds i8, i8* %t223, i64 -16
  %t232 = bitcast i8* %t231 to i64*
  %t233 = load atomic i64, i64* %t232 seq_cst, align 8
  %t234 = icmp eq i64 %t233, 1
  br i1 %t234, label %list_cow_done_54, label %list_cow_clone_55
list_cow_clone_55:
  %t235 = bitcast i8* %t223 to { i32*, i64, i64 }*
  %t236 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t235, i32 0, i32 0
  %t237 = load i32*, i32** %t236
  %t238 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t235, i32 0, i32 1
  %t239 = load i64, i64* %t238
  %t240 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t235, i32 0, i32 2
  %t241 = load i64, i64* %t240
  %t242 = bitcast void (i8*)* @list_release_i32 to i8*
  %t243 = call i8* @star_rc_alloc(i64 24, i8* %t242)
  %t244 = bitcast i8* %t243 to { i32*, i64, i64 }*
  %t245 = mul i64 %t241, %t222
  %t246 = call i8* @malloc(i64 %t245)
  %t247 = bitcast i8* %t246 to i32*
  %t248 = icmp sgt i64 %t239, 0
  br i1 %t248, label %list_cow_copy_56, label %list_cow_after_copy_57
list_cow_copy_56:
  %t249 = mul i64 %t239, %t222
  %t250 = bitcast i32* %t237 to i8*
  call i8* @memcpy(i8* %t246, i8* %t250, i64 %t249)
  br label %list_cow_after_copy_57
list_cow_after_copy_57:
  %t251 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t244, i32 0, i32 0
  store i32* %t247, i32** %t251
  %t252 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t244, i32 0, i32 1
  store i64 %t239, i64* %t252
  %t253 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t244, i32 0, i32 2
  store i64 %t241, i64* %t253
  call void @star_rc_release(i8* %t223)
  store i8* %t243, i8** %t140
  br label %list_cow_done_54
list_cow_done_54:
  %t254 = load i8*, i8** %t140
  %t255 = bitcast i8* %t254 to { i32*, i64, i64 }*
  %t256 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t255, i32 0, i32 0
  %t257 = load i32*, i32** %t256
  %t258 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t255, i32 0, i32 1
  %t259 = load i64, i64* %t258
  %t260 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t255, i32 0, i32 2
  %t261 = icmp eq i64 %t259, 0
  br i1 %t261, label %list_pop_empty_58, label %list_pop_nonempty_59
list_pop_nonempty_59:
  %t262 = sub i64 %t259, 1
  store i64 %t262, i64* %t258
  %t263 = load i32*, i32** %t256
  %t264 = getelementptr inbounds i32, i32* %t263, i64 %t262
  %t265 = load i32, i32* %t264
  br label %list_pop_end_60
list_pop_empty_58:
  br label %list_pop_end_60
list_pop_end_60:
  %t266 = phi i32 [ %t265, %list_pop_nonempty_59 ], [ 0, %list_pop_empty_58 ]
  store i32 %t266, i32* %t220
  %t267 = load i32, i32* %t9
  %t268 = getelementptr i32, i32* null, i32 1
  %t269 = ptrtoint i32* %t268 to i64
  %t270 = load i8*, i8** %t76
  %t271 = icmp eq i8* %t270, null
  br i1 %t271, label %list_cow_alloc_61, label %list_cow_check_62
list_cow_alloc_61:
  %t272 = bitcast void (i8*)* @list_release_i32 to i8*
  %t273 = call i8* @star_rc_alloc(i64 24, i8* %t272)
  %t274 = bitcast i8* %t273 to { i32*, i64, i64 }*
  %t275 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t274, i32 0, i32 0
  store i32* null, i32** %t275
  %t276 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t274, i32 0, i32 1
  store i64 0, i64* %t276
  %t277 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t274, i32 0, i32 2
  store i64 0, i64* %t277
  store i8* %t273, i8** %t76
  br label %list_cow_done_63
list_cow_check_62:
  %t278 = getelementptr inbounds i8, i8* %t270, i64 -16
  %t279 = bitcast i8* %t278 to i64*
  %t280 = load atomic i64, i64* %t279 seq_cst, align 8
  %t281 = icmp eq i64 %t280, 1
  br i1 %t281, label %list_cow_done_63, label %list_cow_clone_64
list_cow_clone_64:
  %t282 = bitcast i8* %t270 to { i32*, i64, i64 }*
  %t283 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t282, i32 0, i32 0
  %t284 = load i32*, i32** %t283
  %t285 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t282, i32 0, i32 1
  %t286 = load i64, i64* %t285
  %t287 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t282, i32 0, i32 2
  %t288 = load i64, i64* %t287
  %t289 = bitcast void (i8*)* @list_release_i32 to i8*
  %t290 = call i8* @star_rc_alloc(i64 24, i8* %t289)
  %t291 = bitcast i8* %t290 to { i32*, i64, i64 }*
  %t292 = mul i64 %t288, %t269
  %t293 = call i8* @malloc(i64 %t292)
  %t294 = bitcast i8* %t293 to i32*
  %t295 = icmp sgt i64 %t286, 0
  br i1 %t295, label %list_cow_copy_65, label %list_cow_after_copy_66
list_cow_copy_65:
  %t296 = mul i64 %t286, %t269
  %t297 = bitcast i32* %t284 to i8*
  call i8* @memcpy(i8* %t293, i8* %t297, i64 %t296)
  br label %list_cow_after_copy_66
list_cow_after_copy_66:
  %t298 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t291, i32 0, i32 0
  store i32* %t294, i32** %t298
  %t299 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t291, i32 0, i32 1
  store i64 %t286, i64* %t299
  %t300 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t291, i32 0, i32 2
  store i64 %t288, i64* %t300
  call void @star_rc_release(i8* %t270)
  store i8* %t290, i8** %t76
  br label %list_cow_done_63
list_cow_done_63:
  %t301 = load i8*, i8** %t76
  %t302 = bitcast i8* %t301 to { i32*, i64, i64 }*
  %t303 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t302, i32 0, i32 0
  %t304 = load i32*, i32** %t303
  %t305 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t302, i32 0, i32 1
  %t306 = load i64, i64* %t305
  %t307 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t302, i32 0, i32 2
  %t308 = load i32, i32* %t220
  %t309 = sext i32 %t308 to i64
  %t310 = icmp ult i64 %t309, %t306
  br i1 %t310, label %list_set_do_67, label %list_set_oob_68
list_set_do_67:
  %t311 = getelementptr inbounds i32, i32* %t304, i64 %t309
  store i32 %t267, i32* %t311
  br label %list_set_end_69
list_set_oob_68:
  br label %list_set_end_69
list_set_end_69:
  %t312 = load i32, i32* %t220
  %t313 = getelementptr i32, i32* null, i32 1
  %t314 = ptrtoint i32* %t313 to i64
  %t315 = load i8*, i8** %t76
  %t316 = icmp eq i8* %t315, null
  br i1 %t316, label %list_cow_alloc_70, label %list_cow_check_71
list_cow_alloc_70:
  %t317 = bitcast void (i8*)* @list_release_i32 to i8*
  %t318 = call i8* @star_rc_alloc(i64 24, i8* %t317)
  %t319 = bitcast i8* %t318 to { i32*, i64, i64 }*
  %t320 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t319, i32 0, i32 0
  store i32* null, i32** %t320
  %t321 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t319, i32 0, i32 1
  store i64 0, i64* %t321
  %t322 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t319, i32 0, i32 2
  store i64 0, i64* %t322
  store i8* %t318, i8** %t76
  br label %list_cow_done_72
list_cow_check_71:
  %t323 = getelementptr inbounds i8, i8* %t315, i64 -16
  %t324 = bitcast i8* %t323 to i64*
  %t325 = load atomic i64, i64* %t324 seq_cst, align 8
  %t326 = icmp eq i64 %t325, 1
  br i1 %t326, label %list_cow_done_72, label %list_cow_clone_73
list_cow_clone_73:
  %t327 = bitcast i8* %t315 to { i32*, i64, i64 }*
  %t328 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t327, i32 0, i32 0
  %t329 = load i32*, i32** %t328
  %t330 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t327, i32 0, i32 1
  %t331 = load i64, i64* %t330
  %t332 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t327, i32 0, i32 2
  %t333 = load i64, i64* %t332
  %t334 = bitcast void (i8*)* @list_release_i32 to i8*
  %t335 = call i8* @star_rc_alloc(i64 24, i8* %t334)
  %t336 = bitcast i8* %t335 to { i32*, i64, i64 }*
  %t337 = mul i64 %t333, %t314
  %t338 = call i8* @malloc(i64 %t337)
  %t339 = bitcast i8* %t338 to i32*
  %t340 = icmp sgt i64 %t331, 0
  br i1 %t340, label %list_cow_copy_74, label %list_cow_after_copy_75
list_cow_copy_74:
  %t341 = mul i64 %t331, %t314
  %t342 = bitcast i32* %t329 to i8*
  call i8* @memcpy(i8* %t338, i8* %t342, i64 %t341)
  br label %list_cow_after_copy_75
list_cow_after_copy_75:
  %t343 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t336, i32 0, i32 0
  store i32* %t339, i32** %t343
  %t344 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t336, i32 0, i32 1
  store i64 %t331, i64* %t344
  %t345 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t336, i32 0, i32 2
  store i64 %t333, i64* %t345
  call void @star_rc_release(i8* %t315)
  store i8* %t335, i8** %t76
  br label %list_cow_done_72
list_cow_done_72:
  %t346 = load i8*, i8** %t76
  %t347 = bitcast i8* %t346 to { i32*, i64, i64 }*
  %t348 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t347, i32 0, i32 0
  %t349 = load i32*, i32** %t348
  %t350 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t347, i32 0, i32 1
  %t351 = load i64, i64* %t350
  %t352 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t347, i32 0, i32 2
  %t353 = load i32, i32* %t9
  %t354 = sext i32 %t353 to i64
  %t355 = icmp ult i64 %t354, %t351
  br i1 %t355, label %list_set_do_76, label %list_set_oob_77
list_set_do_76:
  %t356 = getelementptr inbounds i32, i32* %t349, i64 %t354
  store i32 %t312, i32* %t356
  br label %list_set_end_78
list_set_oob_77:
  br label %list_set_end_78
list_set_end_78:
  br label %if_end_51
if_else_50:
  br label %if_end_51
if_end_51:
  %t357 = load i32, i32* %t9
  %t358 = add i32 %t357, 1
  store i32 %t358, i32* %t9
  br label %while_cond_28
while_else_30:
  br label %while_end_31
while_end_31:
  store i32 0, i32* %t359
  store i32 0, i32* %t360
  br label %while_cond_79
while_cond_79:
  %t361 = load i32, i32* %t360
  %t362 = load i32, i32* %t4
  %t363 = icmp slt i32 %t361, %t362
  br i1 %t363, label %while_body_80, label %while_else_81
while_body_80:
  %t365 = load i8*, i8** %t2
  %t366 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t366)
  %t367 = load i32, i32* %t360
  %t368 = sext i32 %t367 to i64
  %t369 = icmp eq i8* %t365, null
  br i1 %t369, label %str_idx_oob_85, label %str_idx_chk_83
str_idx_chk_83:
  %t370 = call i32 @strlen(i8* %t365)
  %t371 = sext i32 %t370 to i64
  %t372 = icmp ult i64 %t368, %t371
  br i1 %t372, label %str_idx_ok_84, label %str_idx_oob_85
str_idx_ok_84:
  %t373 = getelementptr inbounds i8, i8* %t365, i64 %t368
  %t374 = load i8, i8* %t373
  %t375 = zext i8 %t374 to i32
  br label %str_idx_end_86
str_idx_oob_85:
  br label %str_idx_end_86
str_idx_end_86:
  %t376 = phi i32 [ %t375, %str_idx_ok_84 ], [ 0, %str_idx_oob_85 ]
  call void @star_rc_release(i8* %t365)
  store i32 %t376, i32* %t364
  %t377 = load i32, i32* %t364
  br label %match_scrutinee_379
match_scrutinee_379:
  %t382 = icmp eq i32 %t377, 43
  br i1 %t382, label %match_then_0_380, label %match_next_0_381
match_then_0_380:
  %t384 = load i8*, i8** %t8
  %t385 = icmp eq i8* %t384, null
  br i1 %t385, label %list_read_null_87, label %list_read_real_88
list_read_null_87:
  br label %list_read_end_89
list_read_real_88:
  %t386 = bitcast i8* %t384 to { i32*, i64, i64 }*
  %t387 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t386, i32 0, i32 0
  %t388 = load i32*, i32** %t387
  %t389 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t386, i32 0, i32 1
  %t390 = load i64, i64* %t389
  br label %list_read_end_89
list_read_end_89:
  %t391 = phi i32* [ null, %list_read_null_87 ], [ %t388, %list_read_real_88 ]
  %t392 = phi i64 [ 0, %list_read_null_87 ], [ %t390, %list_read_real_88 ]
  %t393 = load i32, i32* %t359
  %t394 = sext i32 %t393 to i64
  %t395 = icmp ult i64 %t394, %t392
  br i1 %t395, label %list_idx_ok_90, label %list_idx_oob_91
list_idx_ok_90:
  %t396 = getelementptr inbounds i32, i32* %t391, i64 %t394
  %t397 = load i32, i32* %t396
  br label %list_idx_end_92
list_idx_oob_91:
  br label %list_idx_end_92
list_idx_end_92:
  %t398 = phi i32 [ %t397, %list_idx_ok_90 ], [ 0, %list_idx_oob_91 ]
  %t399 = add i32 %t398, 1
  store i32 %t399, i32* %t383
  %t400 = load i32, i32* %t383
  %t401 = icmp sgt i32 %t400, 255
  br i1 %t401, label %if_then_93, label %if_else_94
if_then_93:
  store i32 0, i32* %t383
  br label %if_end_95
if_else_94:
  br label %if_end_95
if_end_95:
  %t402 = load i32, i32* %t383
  %t403 = getelementptr i32, i32* null, i32 1
  %t404 = ptrtoint i32* %t403 to i64
  %t405 = load i8*, i8** %t8
  %t406 = icmp eq i8* %t405, null
  br i1 %t406, label %list_cow_alloc_96, label %list_cow_check_97
list_cow_alloc_96:
  %t407 = bitcast void (i8*)* @list_release_i32 to i8*
  %t408 = call i8* @star_rc_alloc(i64 24, i8* %t407)
  %t409 = bitcast i8* %t408 to { i32*, i64, i64 }*
  %t410 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t409, i32 0, i32 0
  store i32* null, i32** %t410
  %t411 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t409, i32 0, i32 1
  store i64 0, i64* %t411
  %t412 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t409, i32 0, i32 2
  store i64 0, i64* %t412
  store i8* %t408, i8** %t8
  br label %list_cow_done_98
list_cow_check_97:
  %t413 = getelementptr inbounds i8, i8* %t405, i64 -16
  %t414 = bitcast i8* %t413 to i64*
  %t415 = load atomic i64, i64* %t414 seq_cst, align 8
  %t416 = icmp eq i64 %t415, 1
  br i1 %t416, label %list_cow_done_98, label %list_cow_clone_99
list_cow_clone_99:
  %t417 = bitcast i8* %t405 to { i32*, i64, i64 }*
  %t418 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t417, i32 0, i32 0
  %t419 = load i32*, i32** %t418
  %t420 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t417, i32 0, i32 1
  %t421 = load i64, i64* %t420
  %t422 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t417, i32 0, i32 2
  %t423 = load i64, i64* %t422
  %t424 = bitcast void (i8*)* @list_release_i32 to i8*
  %t425 = call i8* @star_rc_alloc(i64 24, i8* %t424)
  %t426 = bitcast i8* %t425 to { i32*, i64, i64 }*
  %t427 = mul i64 %t423, %t404
  %t428 = call i8* @malloc(i64 %t427)
  %t429 = bitcast i8* %t428 to i32*
  %t430 = icmp sgt i64 %t421, 0
  br i1 %t430, label %list_cow_copy_100, label %list_cow_after_copy_101
list_cow_copy_100:
  %t431 = mul i64 %t421, %t404
  %t432 = bitcast i32* %t419 to i8*
  call i8* @memcpy(i8* %t428, i8* %t432, i64 %t431)
  br label %list_cow_after_copy_101
list_cow_after_copy_101:
  %t433 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t426, i32 0, i32 0
  store i32* %t429, i32** %t433
  %t434 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t426, i32 0, i32 1
  store i64 %t421, i64* %t434
  %t435 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t426, i32 0, i32 2
  store i64 %t423, i64* %t435
  call void @star_rc_release(i8* %t405)
  store i8* %t425, i8** %t8
  br label %list_cow_done_98
list_cow_done_98:
  %t436 = load i8*, i8** %t8
  %t437 = bitcast i8* %t436 to { i32*, i64, i64 }*
  %t438 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t437, i32 0, i32 0
  %t439 = load i32*, i32** %t438
  %t440 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t437, i32 0, i32 1
  %t441 = load i64, i64* %t440
  %t442 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t437, i32 0, i32 2
  %t443 = load i32, i32* %t359
  %t444 = sext i32 %t443 to i64
  %t445 = icmp ult i64 %t444, %t441
  br i1 %t445, label %list_set_do_102, label %list_set_oob_103
list_set_do_102:
  %t446 = getelementptr inbounds i32, i32* %t439, i64 %t444
  store i32 %t402, i32* %t446
  br label %list_set_end_104
list_set_oob_103:
  br label %list_set_end_104
list_set_end_104:
  br label %match_end_378
match_next_0_381:
  %t449 = icmp eq i32 %t377, 45
  br i1 %t449, label %match_then_1_447, label %match_next_1_448
match_then_1_447:
  %t451 = load i8*, i8** %t8
  %t452 = icmp eq i8* %t451, null
  br i1 %t452, label %list_read_null_105, label %list_read_real_106
list_read_null_105:
  br label %list_read_end_107
list_read_real_106:
  %t453 = bitcast i8* %t451 to { i32*, i64, i64 }*
  %t454 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t453, i32 0, i32 0
  %t455 = load i32*, i32** %t454
  %t456 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t453, i32 0, i32 1
  %t457 = load i64, i64* %t456
  br label %list_read_end_107
list_read_end_107:
  %t458 = phi i32* [ null, %list_read_null_105 ], [ %t455, %list_read_real_106 ]
  %t459 = phi i64 [ 0, %list_read_null_105 ], [ %t457, %list_read_real_106 ]
  %t460 = load i32, i32* %t359
  %t461 = sext i32 %t460 to i64
  %t462 = icmp ult i64 %t461, %t459
  br i1 %t462, label %list_idx_ok_108, label %list_idx_oob_109
list_idx_ok_108:
  %t463 = getelementptr inbounds i32, i32* %t458, i64 %t461
  %t464 = load i32, i32* %t463
  br label %list_idx_end_110
list_idx_oob_109:
  br label %list_idx_end_110
list_idx_end_110:
  %t465 = phi i32 [ %t464, %list_idx_ok_108 ], [ 0, %list_idx_oob_109 ]
  %t466 = sub i32 %t465, 1
  store i32 %t466, i32* %t450
  %t467 = load i32, i32* %t450
  %t468 = icmp slt i32 %t467, 0
  br i1 %t468, label %if_then_111, label %if_else_112
if_then_111:
  store i32 255, i32* %t450
  br label %if_end_113
if_else_112:
  br label %if_end_113
if_end_113:
  %t469 = load i32, i32* %t450
  %t470 = getelementptr i32, i32* null, i32 1
  %t471 = ptrtoint i32* %t470 to i64
  %t472 = load i8*, i8** %t8
  %t473 = icmp eq i8* %t472, null
  br i1 %t473, label %list_cow_alloc_114, label %list_cow_check_115
list_cow_alloc_114:
  %t474 = bitcast void (i8*)* @list_release_i32 to i8*
  %t475 = call i8* @star_rc_alloc(i64 24, i8* %t474)
  %t476 = bitcast i8* %t475 to { i32*, i64, i64 }*
  %t477 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t476, i32 0, i32 0
  store i32* null, i32** %t477
  %t478 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t476, i32 0, i32 1
  store i64 0, i64* %t478
  %t479 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t476, i32 0, i32 2
  store i64 0, i64* %t479
  store i8* %t475, i8** %t8
  br label %list_cow_done_116
list_cow_check_115:
  %t480 = getelementptr inbounds i8, i8* %t472, i64 -16
  %t481 = bitcast i8* %t480 to i64*
  %t482 = load atomic i64, i64* %t481 seq_cst, align 8
  %t483 = icmp eq i64 %t482, 1
  br i1 %t483, label %list_cow_done_116, label %list_cow_clone_117
list_cow_clone_117:
  %t484 = bitcast i8* %t472 to { i32*, i64, i64 }*
  %t485 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t484, i32 0, i32 0
  %t486 = load i32*, i32** %t485
  %t487 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t484, i32 0, i32 1
  %t488 = load i64, i64* %t487
  %t489 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t484, i32 0, i32 2
  %t490 = load i64, i64* %t489
  %t491 = bitcast void (i8*)* @list_release_i32 to i8*
  %t492 = call i8* @star_rc_alloc(i64 24, i8* %t491)
  %t493 = bitcast i8* %t492 to { i32*, i64, i64 }*
  %t494 = mul i64 %t490, %t471
  %t495 = call i8* @malloc(i64 %t494)
  %t496 = bitcast i8* %t495 to i32*
  %t497 = icmp sgt i64 %t488, 0
  br i1 %t497, label %list_cow_copy_118, label %list_cow_after_copy_119
list_cow_copy_118:
  %t498 = mul i64 %t488, %t471
  %t499 = bitcast i32* %t486 to i8*
  call i8* @memcpy(i8* %t495, i8* %t499, i64 %t498)
  br label %list_cow_after_copy_119
list_cow_after_copy_119:
  %t500 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t493, i32 0, i32 0
  store i32* %t496, i32** %t500
  %t501 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t493, i32 0, i32 1
  store i64 %t488, i64* %t501
  %t502 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t493, i32 0, i32 2
  store i64 %t490, i64* %t502
  call void @star_rc_release(i8* %t472)
  store i8* %t492, i8** %t8
  br label %list_cow_done_116
list_cow_done_116:
  %t503 = load i8*, i8** %t8
  %t504 = bitcast i8* %t503 to { i32*, i64, i64 }*
  %t505 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t504, i32 0, i32 0
  %t506 = load i32*, i32** %t505
  %t507 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t504, i32 0, i32 1
  %t508 = load i64, i64* %t507
  %t509 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t504, i32 0, i32 2
  %t510 = load i32, i32* %t359
  %t511 = sext i32 %t510 to i64
  %t512 = icmp ult i64 %t511, %t508
  br i1 %t512, label %list_set_do_120, label %list_set_oob_121
list_set_do_120:
  %t513 = getelementptr inbounds i32, i32* %t506, i64 %t511
  store i32 %t469, i32* %t513
  br label %list_set_end_122
list_set_oob_121:
  br label %list_set_end_122
list_set_end_122:
  br label %match_end_378
match_next_1_448:
  %t516 = icmp eq i32 %t377, 62
  br i1 %t516, label %match_then_2_514, label %match_next_2_515
match_then_2_514:
  %t517 = load i32, i32* %t359
  %t518 = add i32 %t517, 1
  store i32 %t518, i32* %t359
  br label %match_end_378
match_next_2_515:
  %t521 = icmp eq i32 %t377, 60
  br i1 %t521, label %match_then_3_519, label %match_next_3_520
match_then_3_519:
  %t522 = load i32, i32* %t359
  %t523 = sub i32 %t522, 1
  store i32 %t523, i32* %t359
  br label %match_end_378
match_next_3_520:
  %t526 = icmp eq i32 %t377, 46
  br i1 %t526, label %match_then_4_524, label %match_next_4_525
match_then_4_524:
  %t527 = load i8*, i8** %t8
  %t528 = icmp eq i8* %t527, null
  br i1 %t528, label %list_read_null_123, label %list_read_real_124
list_read_null_123:
  br label %list_read_end_125
list_read_real_124:
  %t529 = bitcast i8* %t527 to { i32*, i64, i64 }*
  %t530 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t529, i32 0, i32 0
  %t531 = load i32*, i32** %t530
  %t532 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t529, i32 0, i32 1
  %t533 = load i64, i64* %t532
  br label %list_read_end_125
list_read_end_125:
  %t534 = phi i32* [ null, %list_read_null_123 ], [ %t531, %list_read_real_124 ]
  %t535 = phi i64 [ 0, %list_read_null_123 ], [ %t533, %list_read_real_124 ]
  %t536 = load i32, i32* %t359
  %t537 = sext i32 %t536 to i64
  %t538 = icmp ult i64 %t537, %t535
  br i1 %t538, label %list_idx_ok_126, label %list_idx_oob_127
list_idx_ok_126:
  %t539 = getelementptr inbounds i32, i32* %t534, i64 %t537
  %t540 = load i32, i32* %t539
  br label %list_idx_end_128
list_idx_oob_127:
  br label %list_idx_end_128
list_idx_end_128:
  %t541 = phi i32 [ %t540, %list_idx_ok_126 ], [ 0, %list_idx_oob_127 ]
  %t542 = call i32 @putchar(i32 %t541)
  br label %match_end_378
match_next_4_525:
  %t545 = icmp eq i32 %t377, 44
  br i1 %t545, label %match_then_5_543, label %match_next_5_544
match_then_5_543:
  %t546 = getelementptr i32, i32* null, i32 1
  %t547 = ptrtoint i32* %t546 to i64
  %t548 = load i8*, i8** %t8
  %t549 = icmp eq i8* %t548, null
  br i1 %t549, label %list_cow_alloc_129, label %list_cow_check_130
list_cow_alloc_129:
  %t550 = bitcast void (i8*)* @list_release_i32 to i8*
  %t551 = call i8* @star_rc_alloc(i64 24, i8* %t550)
  %t552 = bitcast i8* %t551 to { i32*, i64, i64 }*
  %t553 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t552, i32 0, i32 0
  store i32* null, i32** %t553
  %t554 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t552, i32 0, i32 1
  store i64 0, i64* %t554
  %t555 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t552, i32 0, i32 2
  store i64 0, i64* %t555
  store i8* %t551, i8** %t8
  br label %list_cow_done_131
list_cow_check_130:
  %t556 = getelementptr inbounds i8, i8* %t548, i64 -16
  %t557 = bitcast i8* %t556 to i64*
  %t558 = load atomic i64, i64* %t557 seq_cst, align 8
  %t559 = icmp eq i64 %t558, 1
  br i1 %t559, label %list_cow_done_131, label %list_cow_clone_132
list_cow_clone_132:
  %t560 = bitcast i8* %t548 to { i32*, i64, i64 }*
  %t561 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t560, i32 0, i32 0
  %t562 = load i32*, i32** %t561
  %t563 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t560, i32 0, i32 1
  %t564 = load i64, i64* %t563
  %t565 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t560, i32 0, i32 2
  %t566 = load i64, i64* %t565
  %t567 = bitcast void (i8*)* @list_release_i32 to i8*
  %t568 = call i8* @star_rc_alloc(i64 24, i8* %t567)
  %t569 = bitcast i8* %t568 to { i32*, i64, i64 }*
  %t570 = mul i64 %t566, %t547
  %t571 = call i8* @malloc(i64 %t570)
  %t572 = bitcast i8* %t571 to i32*
  %t573 = icmp sgt i64 %t564, 0
  br i1 %t573, label %list_cow_copy_133, label %list_cow_after_copy_134
list_cow_copy_133:
  %t574 = mul i64 %t564, %t547
  %t575 = bitcast i32* %t562 to i8*
  call i8* @memcpy(i8* %t571, i8* %t575, i64 %t574)
  br label %list_cow_after_copy_134
list_cow_after_copy_134:
  %t576 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t569, i32 0, i32 0
  store i32* %t572, i32** %t576
  %t577 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t569, i32 0, i32 1
  store i64 %t564, i64* %t577
  %t578 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t569, i32 0, i32 2
  store i64 %t566, i64* %t578
  call void @star_rc_release(i8* %t548)
  store i8* %t568, i8** %t8
  br label %list_cow_done_131
list_cow_done_131:
  %t579 = load i8*, i8** %t8
  %t580 = bitcast i8* %t579 to { i32*, i64, i64 }*
  %t581 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t580, i32 0, i32 0
  %t582 = load i32*, i32** %t581
  %t583 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t580, i32 0, i32 1
  %t584 = load i64, i64* %t583
  %t585 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t580, i32 0, i32 2
  %t586 = load i32, i32* %t359
  %t587 = sext i32 %t586 to i64
  %t588 = icmp ult i64 %t587, %t584
  br i1 %t588, label %list_set_do_135, label %list_set_oob_136
list_set_do_135:
  %t589 = getelementptr inbounds i32, i32* %t582, i64 %t587
  store i32 0, i32* %t589
  br label %list_set_end_137
list_set_oob_136:
  br label %list_set_end_137
list_set_end_137:
  br label %match_end_378
match_next_5_544:
  %t592 = icmp eq i32 %t377, 91
  br i1 %t592, label %match_then_6_590, label %match_next_6_591
match_then_6_590:
  %t593 = load i8*, i8** %t8
  %t594 = icmp eq i8* %t593, null
  br i1 %t594, label %list_read_null_138, label %list_read_real_139
list_read_null_138:
  br label %list_read_end_140
list_read_real_139:
  %t595 = bitcast i8* %t593 to { i32*, i64, i64 }*
  %t596 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t595, i32 0, i32 0
  %t597 = load i32*, i32** %t596
  %t598 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t595, i32 0, i32 1
  %t599 = load i64, i64* %t598
  br label %list_read_end_140
list_read_end_140:
  %t600 = phi i32* [ null, %list_read_null_138 ], [ %t597, %list_read_real_139 ]
  %t601 = phi i64 [ 0, %list_read_null_138 ], [ %t599, %list_read_real_139 ]
  %t602 = load i32, i32* %t359
  %t603 = sext i32 %t602 to i64
  %t604 = icmp ult i64 %t603, %t601
  br i1 %t604, label %list_idx_ok_141, label %list_idx_oob_142
list_idx_ok_141:
  %t605 = getelementptr inbounds i32, i32* %t600, i64 %t603
  %t606 = load i32, i32* %t605
  br label %list_idx_end_143
list_idx_oob_142:
  br label %list_idx_end_143
list_idx_end_143:
  %t607 = phi i32 [ %t606, %list_idx_ok_141 ], [ 0, %list_idx_oob_142 ]
  %t608 = icmp eq i32 %t607, 0
  br i1 %t608, label %if_then_144, label %if_else_145
if_then_144:
  %t609 = load i8*, i8** %t76
  %t610 = icmp eq i8* %t609, null
  br i1 %t610, label %list_read_null_147, label %list_read_real_148
list_read_null_147:
  br label %list_read_end_149
list_read_real_148:
  %t611 = bitcast i8* %t609 to { i32*, i64, i64 }*
  %t612 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t611, i32 0, i32 0
  %t613 = load i32*, i32** %t612
  %t614 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t611, i32 0, i32 1
  %t615 = load i64, i64* %t614
  br label %list_read_end_149
list_read_end_149:
  %t616 = phi i32* [ null, %list_read_null_147 ], [ %t613, %list_read_real_148 ]
  %t617 = phi i64 [ 0, %list_read_null_147 ], [ %t615, %list_read_real_148 ]
  %t618 = load i32, i32* %t360
  %t619 = sext i32 %t618 to i64
  %t620 = icmp ult i64 %t619, %t617
  br i1 %t620, label %list_idx_ok_150, label %list_idx_oob_151
list_idx_ok_150:
  %t621 = getelementptr inbounds i32, i32* %t616, i64 %t619
  %t622 = load i32, i32* %t621
  br label %list_idx_end_152
list_idx_oob_151:
  br label %list_idx_end_152
list_idx_end_152:
  %t623 = phi i32 [ %t622, %list_idx_ok_150 ], [ 0, %list_idx_oob_151 ]
  store i32 %t623, i32* %t360
  br label %if_end_146
if_else_145:
  br label %if_end_146
if_end_146:
  br label %match_end_378
match_next_6_591:
  %t626 = icmp eq i32 %t377, 93
  br i1 %t626, label %match_then_7_624, label %match_next_7_625
match_then_7_624:
  %t627 = load i8*, i8** %t8
  %t628 = icmp eq i8* %t627, null
  br i1 %t628, label %list_read_null_153, label %list_read_real_154
list_read_null_153:
  br label %list_read_end_155
list_read_real_154:
  %t629 = bitcast i8* %t627 to { i32*, i64, i64 }*
  %t630 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t629, i32 0, i32 0
  %t631 = load i32*, i32** %t630
  %t632 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t629, i32 0, i32 1
  %t633 = load i64, i64* %t632
  br label %list_read_end_155
list_read_end_155:
  %t634 = phi i32* [ null, %list_read_null_153 ], [ %t631, %list_read_real_154 ]
  %t635 = phi i64 [ 0, %list_read_null_153 ], [ %t633, %list_read_real_154 ]
  %t636 = load i32, i32* %t359
  %t637 = sext i32 %t636 to i64
  %t638 = icmp ult i64 %t637, %t635
  br i1 %t638, label %list_idx_ok_156, label %list_idx_oob_157
list_idx_ok_156:
  %t639 = getelementptr inbounds i32, i32* %t634, i64 %t637
  %t640 = load i32, i32* %t639
  br label %list_idx_end_158
list_idx_oob_157:
  br label %list_idx_end_158
list_idx_end_158:
  %t641 = phi i32 [ %t640, %list_idx_ok_156 ], [ 0, %list_idx_oob_157 ]
  %t642 = icmp ne i32 %t641, 0
  br i1 %t642, label %if_then_159, label %if_else_160
if_then_159:
  %t643 = load i8*, i8** %t76
  %t644 = icmp eq i8* %t643, null
  br i1 %t644, label %list_read_null_162, label %list_read_real_163
list_read_null_162:
  br label %list_read_end_164
list_read_real_163:
  %t645 = bitcast i8* %t643 to { i32*, i64, i64 }*
  %t646 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t645, i32 0, i32 0
  %t647 = load i32*, i32** %t646
  %t648 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t645, i32 0, i32 1
  %t649 = load i64, i64* %t648
  br label %list_read_end_164
list_read_end_164:
  %t650 = phi i32* [ null, %list_read_null_162 ], [ %t647, %list_read_real_163 ]
  %t651 = phi i64 [ 0, %list_read_null_162 ], [ %t649, %list_read_real_163 ]
  %t652 = load i32, i32* %t360
  %t653 = sext i32 %t652 to i64
  %t654 = icmp ult i64 %t653, %t651
  br i1 %t654, label %list_idx_ok_165, label %list_idx_oob_166
list_idx_ok_165:
  %t655 = getelementptr inbounds i32, i32* %t650, i64 %t653
  %t656 = load i32, i32* %t655
  br label %list_idx_end_167
list_idx_oob_166:
  br label %list_idx_end_167
list_idx_end_167:
  %t657 = phi i32 [ %t656, %list_idx_ok_165 ], [ 0, %list_idx_oob_166 ]
  store i32 %t657, i32* %t360
  br label %if_end_161
if_else_160:
  br label %if_end_161
if_end_161:
  br label %match_end_378
match_next_7_625:
  br label %match_end_378
match_end_378:
  %t660 = phi i32 [ undef, %list_set_end_104 ], [ undef, %list_set_end_122 ], [ undef, %match_then_2_514 ], [ undef, %match_then_3_519 ], [ %t542, %list_idx_end_128 ], [ undef, %list_set_end_137 ], [ undef, %if_end_146 ], [ undef, %if_end_161 ], [ 0, %match_next_7_625 ]
  %t661 = load i32, i32* %t360
  %t662 = add i32 %t661, 1
  store i32 %t662, i32* %t360
  br label %while_cond_79
while_else_81:
  br label %while_end_82
while_end_82:
  %t663 = load i8*, i8** %t140
  call void @star_rc_release(i8* %t663)
  %t664 = load i8*, i8** %t76
  call void @star_rc_release(i8* %t664)
  %t665 = load i8*, i8** %t8
  call void @star_rc_release(i8* %t665)
  %t666 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t666)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_i32(i8* %objp) {
entry:
  %t16 = bitcast i8* %objp to { i32*, i64, i64 }*
  %t17 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t16, i32 0, i32 0
  %t18 = load i32*, i32** %t17
  %t19 = bitcast i32* %t18 to i8*
  call void @free(i8* %t19)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [107 x i8] } { i64 -1, i8* null, [107 x i8] c"++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.\00" }
