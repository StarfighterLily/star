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

declare i32 @putchar(i32)
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca i8*
  %t3 = alloca i32
  %t7 = alloca i8*
  %t8 = alloca i32
  %t75 = alloca i8*
  %t139 = alloca i8*
  %t143 = alloca i32
  %t219 = alloca i32
  %t358 = alloca i32
  %t359 = alloca i32
  %t363 = alloca i32
  %t382 = alloca i32
  %t449 = alloca i32
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t2 = getelementptr inbounds { i64, i8*, [107 x i8] }, { i64, i8*, [107 x i8] }* @.str.0, i64 0, i32 2, i64 0
  store i8* %t2, i8** %t1
  %t4 = load i8*, i8** %t1
  %t5 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t5)
  %t6 = call i32 @strlen(i8* %t4)
  call void @star_rc_release(i8* %t4)
  store i32 %t6, i32* %t3
  store i8* null, i8** %t7
  store i32 0, i32* %t8
  br label %while_cond_0
while_cond_0:
  %t9 = load i32, i32* %t8
  %t10 = icmp slt i32 %t9, 30000
  br i1 %t10, label %while_body_1, label %while_else_2
while_body_1:
  %t11 = getelementptr i32, i32* null, i32 1
  %t12 = ptrtoint i32* %t11 to i64
  %t13 = load i8*, i8** %t7
  %t14 = icmp eq i8* %t13, null
  br i1 %t14, label %list_cow_alloc_4, label %list_cow_check_5
list_cow_alloc_4:
  %t19 = bitcast void (i8*)* @list_release_i32 to i8*
  %t20 = call i8* @star_rc_alloc(i64 24, i8* %t19)
  %t21 = bitcast i8* %t20 to { i32*, i64, i64 }*
  %t22 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t21, i32 0, i32 0
  store i32* null, i32** %t22
  %t23 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t21, i32 0, i32 1
  store i64 0, i64* %t23
  %t24 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t21, i32 0, i32 2
  store i64 0, i64* %t24
  store i8* %t20, i8** %t7
  br label %list_cow_done_6
list_cow_check_5:
  %t25 = getelementptr inbounds i8, i8* %t13, i64 -16
  %t26 = bitcast i8* %t25 to i64*
  %t27 = load atomic i64, i64* %t26 seq_cst, align 8
  %t28 = icmp eq i64 %t27, 1
  br i1 %t28, label %list_cow_done_6, label %list_cow_clone_7
list_cow_clone_7:
  %t29 = bitcast i8* %t13 to { i32*, i64, i64 }*
  %t30 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t29, i32 0, i32 0
  %t31 = load i32*, i32** %t30
  %t32 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t29, i32 0, i32 1
  %t33 = load i64, i64* %t32
  %t34 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t29, i32 0, i32 2
  %t35 = load i64, i64* %t34
  %t36 = bitcast void (i8*)* @list_release_i32 to i8*
  %t37 = call i8* @star_rc_alloc(i64 24, i8* %t36)
  %t38 = bitcast i8* %t37 to { i32*, i64, i64 }*
  %t39 = mul i64 %t35, %t12
  %t40 = call i8* @malloc(i64 %t39)
  %t41 = bitcast i8* %t40 to i32*
  %t42 = icmp sgt i64 %t33, 0
  br i1 %t42, label %list_cow_copy_8, label %list_cow_after_copy_9
list_cow_copy_8:
  %t43 = mul i64 %t33, %t12
  %t44 = bitcast i32* %t31 to i8*
  call i8* @memcpy(i8* %t40, i8* %t44, i64 %t43)
  br label %list_cow_after_copy_9
list_cow_after_copy_9:
  %t45 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t38, i32 0, i32 0
  store i32* %t41, i32** %t45
  %t46 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t38, i32 0, i32 1
  store i64 %t33, i64* %t46
  %t47 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t38, i32 0, i32 2
  store i64 %t35, i64* %t47
  call void @star_rc_release(i8* %t13)
  store i8* %t37, i8** %t7
  br label %list_cow_done_6
list_cow_done_6:
  %t48 = load i8*, i8** %t7
  %t49 = bitcast i8* %t48 to { i32*, i64, i64 }*
  %t50 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t49, i32 0, i32 0
  %t51 = load i32*, i32** %t50
  %t52 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t49, i32 0, i32 1
  %t53 = load i64, i64* %t52
  %t54 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t49, i32 0, i32 2
  %t55 = load i64, i64* %t54
  %t56 = load i32*, i32** %t50
  %t57 = load i64, i64* %t52
  %t58 = icmp sge i64 %t57, %t55
  br i1 %t58, label %list_push_grow_10, label %list_push_store_11
list_push_grow_10:
  %t59 = mul i64 %t55, 2
  %t60 = icmp sgt i64 %t59, 0
  %t61 = select i1 %t60, i64 %t59, i64 1
  %t62 = getelementptr i32, i32* null, i32 1
  %t63 = ptrtoint i32* %t62 to i64
  %t64 = mul i64 %t61, %t63
  %t65 = call i8* @malloc(i64 %t64)
  %t66 = bitcast i8* %t65 to i32*
  %t67 = icmp sgt i64 %t55, 0
  br i1 %t67, label %list_push_copy_12, label %list_push_after_copy_13
list_push_copy_12:
  %t68 = mul i64 %t57, %t63
  %t69 = bitcast i32* %t56 to i8*
  call i8* @memcpy(i8* %t65, i8* %t69, i64 %t68)
  call void @free(i8* %t69)
  br label %list_push_after_copy_13
list_push_after_copy_13:
  store i32* %t66, i32** %t50
  store i64 %t61, i64* %t54
  br label %list_push_store_11
list_push_store_11:
  %t70 = load i32*, i32** %t50
  %t71 = getelementptr inbounds i32, i32* %t70, i64 %t57
  store i32 0, i32* %t71
  %t72 = add i64 %t57, 1
  store i64 %t72, i64* %t52
  %t73 = load i32, i32* %t8
  %t74 = add i32 %t73, 1
  store i32 %t74, i32* %t8
  br label %while_cond_0
while_else_2:
  br label %while_end_3
while_end_3:
  store i8* null, i8** %t75
  store i32 0, i32* %t8
  br label %while_cond_14
while_cond_14:
  %t76 = load i32, i32* %t8
  %t77 = load i32, i32* %t3
  %t78 = icmp slt i32 %t76, %t77
  br i1 %t78, label %while_body_15, label %while_else_16
while_body_15:
  %t79 = getelementptr i32, i32* null, i32 1
  %t80 = ptrtoint i32* %t79 to i64
  %t81 = load i8*, i8** %t75
  %t82 = icmp eq i8* %t81, null
  br i1 %t82, label %list_cow_alloc_18, label %list_cow_check_19
list_cow_alloc_18:
  %t83 = bitcast void (i8*)* @list_release_i32 to i8*
  %t84 = call i8* @star_rc_alloc(i64 24, i8* %t83)
  %t85 = bitcast i8* %t84 to { i32*, i64, i64 }*
  %t86 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t85, i32 0, i32 0
  store i32* null, i32** %t86
  %t87 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t85, i32 0, i32 1
  store i64 0, i64* %t87
  %t88 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t85, i32 0, i32 2
  store i64 0, i64* %t88
  store i8* %t84, i8** %t75
  br label %list_cow_done_20
list_cow_check_19:
  %t89 = getelementptr inbounds i8, i8* %t81, i64 -16
  %t90 = bitcast i8* %t89 to i64*
  %t91 = load atomic i64, i64* %t90 seq_cst, align 8
  %t92 = icmp eq i64 %t91, 1
  br i1 %t92, label %list_cow_done_20, label %list_cow_clone_21
list_cow_clone_21:
  %t93 = bitcast i8* %t81 to { i32*, i64, i64 }*
  %t94 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t93, i32 0, i32 0
  %t95 = load i32*, i32** %t94
  %t96 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t93, i32 0, i32 1
  %t97 = load i64, i64* %t96
  %t98 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t93, i32 0, i32 2
  %t99 = load i64, i64* %t98
  %t100 = bitcast void (i8*)* @list_release_i32 to i8*
  %t101 = call i8* @star_rc_alloc(i64 24, i8* %t100)
  %t102 = bitcast i8* %t101 to { i32*, i64, i64 }*
  %t103 = mul i64 %t99, %t80
  %t104 = call i8* @malloc(i64 %t103)
  %t105 = bitcast i8* %t104 to i32*
  %t106 = icmp sgt i64 %t97, 0
  br i1 %t106, label %list_cow_copy_22, label %list_cow_after_copy_23
list_cow_copy_22:
  %t107 = mul i64 %t97, %t80
  %t108 = bitcast i32* %t95 to i8*
  call i8* @memcpy(i8* %t104, i8* %t108, i64 %t107)
  br label %list_cow_after_copy_23
list_cow_after_copy_23:
  %t109 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t102, i32 0, i32 0
  store i32* %t105, i32** %t109
  %t110 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t102, i32 0, i32 1
  store i64 %t97, i64* %t110
  %t111 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t102, i32 0, i32 2
  store i64 %t99, i64* %t111
  call void @star_rc_release(i8* %t81)
  store i8* %t101, i8** %t75
  br label %list_cow_done_20
list_cow_done_20:
  %t112 = load i8*, i8** %t75
  %t113 = bitcast i8* %t112 to { i32*, i64, i64 }*
  %t114 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t113, i32 0, i32 0
  %t115 = load i32*, i32** %t114
  %t116 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t113, i32 0, i32 1
  %t117 = load i64, i64* %t116
  %t118 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t113, i32 0, i32 2
  %t119 = load i64, i64* %t118
  %t120 = load i32*, i32** %t114
  %t121 = load i64, i64* %t116
  %t122 = icmp sge i64 %t121, %t119
  br i1 %t122, label %list_push_grow_24, label %list_push_store_25
list_push_grow_24:
  %t123 = mul i64 %t119, 2
  %t124 = icmp sgt i64 %t123, 0
  %t125 = select i1 %t124, i64 %t123, i64 1
  %t126 = getelementptr i32, i32* null, i32 1
  %t127 = ptrtoint i32* %t126 to i64
  %t128 = mul i64 %t125, %t127
  %t129 = call i8* @malloc(i64 %t128)
  %t130 = bitcast i8* %t129 to i32*
  %t131 = icmp sgt i64 %t119, 0
  br i1 %t131, label %list_push_copy_26, label %list_push_after_copy_27
list_push_copy_26:
  %t132 = mul i64 %t121, %t127
  %t133 = bitcast i32* %t120 to i8*
  call i8* @memcpy(i8* %t129, i8* %t133, i64 %t132)
  call void @free(i8* %t133)
  br label %list_push_after_copy_27
list_push_after_copy_27:
  store i32* %t130, i32** %t114
  store i64 %t125, i64* %t118
  br label %list_push_store_25
list_push_store_25:
  %t134 = load i32*, i32** %t114
  %t135 = getelementptr inbounds i32, i32* %t134, i64 %t121
  store i32 0, i32* %t135
  %t136 = add i64 %t121, 1
  store i64 %t136, i64* %t116
  %t137 = load i32, i32* %t8
  %t138 = add i32 %t137, 1
  store i32 %t138, i32* %t8
  br label %while_cond_14
while_else_16:
  br label %while_end_17
while_end_17:
  store i8* null, i8** %t139
  store i32 0, i32* %t8
  br label %while_cond_28
while_cond_28:
  %t140 = load i32, i32* %t8
  %t141 = load i32, i32* %t3
  %t142 = icmp slt i32 %t140, %t141
  br i1 %t142, label %while_body_29, label %while_else_30
while_body_29:
  %t144 = load i8*, i8** %t1
  %t145 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t145)
  %t146 = load i32, i32* %t8
  %t147 = sext i32 %t146 to i64
  %t148 = icmp eq i8* %t144, null
  br i1 %t148, label %str_idx_oob_34, label %str_idx_chk_32
str_idx_chk_32:
  %t149 = call i32 @strlen(i8* %t144)
  %t150 = sext i32 %t149 to i64
  %t151 = icmp ult i64 %t147, %t150
  br i1 %t151, label %str_idx_ok_33, label %str_idx_oob_34
str_idx_ok_33:
  %t152 = getelementptr inbounds i8, i8* %t144, i64 %t147
  %t153 = load i8, i8* %t152
  %t154 = zext i8 %t153 to i32
  br label %str_idx_end_35
str_idx_oob_34:
  br label %str_idx_end_35
str_idx_end_35:
  %t155 = phi i32 [ %t154, %str_idx_ok_33 ], [ 0, %str_idx_oob_34 ]
  call void @star_rc_release(i8* %t144)
  store i32 %t155, i32* %t143
  %t156 = load i32, i32* %t143
  %t157 = icmp eq i32 %t156, 91
  br i1 %t157, label %if_then_36, label %if_else_37
if_then_36:
  %t158 = getelementptr i32, i32* null, i32 1
  %t159 = ptrtoint i32* %t158 to i64
  %t160 = load i8*, i8** %t139
  %t161 = icmp eq i8* %t160, null
  br i1 %t161, label %list_cow_alloc_39, label %list_cow_check_40
list_cow_alloc_39:
  %t162 = bitcast void (i8*)* @list_release_i32 to i8*
  %t163 = call i8* @star_rc_alloc(i64 24, i8* %t162)
  %t164 = bitcast i8* %t163 to { i32*, i64, i64 }*
  %t165 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t164, i32 0, i32 0
  store i32* null, i32** %t165
  %t166 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t164, i32 0, i32 1
  store i64 0, i64* %t166
  %t167 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t164, i32 0, i32 2
  store i64 0, i64* %t167
  store i8* %t163, i8** %t139
  br label %list_cow_done_41
list_cow_check_40:
  %t168 = getelementptr inbounds i8, i8* %t160, i64 -16
  %t169 = bitcast i8* %t168 to i64*
  %t170 = load atomic i64, i64* %t169 seq_cst, align 8
  %t171 = icmp eq i64 %t170, 1
  br i1 %t171, label %list_cow_done_41, label %list_cow_clone_42
list_cow_clone_42:
  %t172 = bitcast i8* %t160 to { i32*, i64, i64 }*
  %t173 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t172, i32 0, i32 0
  %t174 = load i32*, i32** %t173
  %t175 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t172, i32 0, i32 1
  %t176 = load i64, i64* %t175
  %t177 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t172, i32 0, i32 2
  %t178 = load i64, i64* %t177
  %t179 = bitcast void (i8*)* @list_release_i32 to i8*
  %t180 = call i8* @star_rc_alloc(i64 24, i8* %t179)
  %t181 = bitcast i8* %t180 to { i32*, i64, i64 }*
  %t182 = mul i64 %t178, %t159
  %t183 = call i8* @malloc(i64 %t182)
  %t184 = bitcast i8* %t183 to i32*
  %t185 = icmp sgt i64 %t176, 0
  br i1 %t185, label %list_cow_copy_43, label %list_cow_after_copy_44
list_cow_copy_43:
  %t186 = mul i64 %t176, %t159
  %t187 = bitcast i32* %t174 to i8*
  call i8* @memcpy(i8* %t183, i8* %t187, i64 %t186)
  br label %list_cow_after_copy_44
list_cow_after_copy_44:
  %t188 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t181, i32 0, i32 0
  store i32* %t184, i32** %t188
  %t189 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t181, i32 0, i32 1
  store i64 %t176, i64* %t189
  %t190 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t181, i32 0, i32 2
  store i64 %t178, i64* %t190
  call void @star_rc_release(i8* %t160)
  store i8* %t180, i8** %t139
  br label %list_cow_done_41
list_cow_done_41:
  %t191 = load i8*, i8** %t139
  %t192 = bitcast i8* %t191 to { i32*, i64, i64 }*
  %t193 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t192, i32 0, i32 0
  %t194 = load i32*, i32** %t193
  %t195 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t192, i32 0, i32 1
  %t196 = load i64, i64* %t195
  %t197 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t192, i32 0, i32 2
  %t198 = load i32, i32* %t8
  %t199 = load i64, i64* %t197
  %t200 = load i32*, i32** %t193
  %t201 = load i64, i64* %t195
  %t202 = icmp sge i64 %t201, %t199
  br i1 %t202, label %list_push_grow_45, label %list_push_store_46
list_push_grow_45:
  %t203 = mul i64 %t199, 2
  %t204 = icmp sgt i64 %t203, 0
  %t205 = select i1 %t204, i64 %t203, i64 1
  %t206 = getelementptr i32, i32* null, i32 1
  %t207 = ptrtoint i32* %t206 to i64
  %t208 = mul i64 %t205, %t207
  %t209 = call i8* @malloc(i64 %t208)
  %t210 = bitcast i8* %t209 to i32*
  %t211 = icmp sgt i64 %t199, 0
  br i1 %t211, label %list_push_copy_47, label %list_push_after_copy_48
list_push_copy_47:
  %t212 = mul i64 %t201, %t207
  %t213 = bitcast i32* %t200 to i8*
  call i8* @memcpy(i8* %t209, i8* %t213, i64 %t212)
  call void @free(i8* %t213)
  br label %list_push_after_copy_48
list_push_after_copy_48:
  store i32* %t210, i32** %t193
  store i64 %t205, i64* %t197
  br label %list_push_store_46
list_push_store_46:
  %t214 = load i32*, i32** %t193
  %t215 = getelementptr inbounds i32, i32* %t214, i64 %t201
  store i32 %t198, i32* %t215
  %t216 = add i64 %t201, 1
  store i64 %t216, i64* %t195
  br label %if_end_38
if_else_37:
  br label %if_end_38
if_end_38:
  %t217 = load i32, i32* %t143
  %t218 = icmp eq i32 %t217, 93
  br i1 %t218, label %if_then_49, label %if_else_50
if_then_49:
  %t220 = getelementptr i32, i32* null, i32 1
  %t221 = ptrtoint i32* %t220 to i64
  %t222 = load i8*, i8** %t139
  %t223 = icmp eq i8* %t222, null
  br i1 %t223, label %list_cow_alloc_52, label %list_cow_check_53
list_cow_alloc_52:
  %t224 = bitcast void (i8*)* @list_release_i32 to i8*
  %t225 = call i8* @star_rc_alloc(i64 24, i8* %t224)
  %t226 = bitcast i8* %t225 to { i32*, i64, i64 }*
  %t227 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t226, i32 0, i32 0
  store i32* null, i32** %t227
  %t228 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t226, i32 0, i32 1
  store i64 0, i64* %t228
  %t229 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t226, i32 0, i32 2
  store i64 0, i64* %t229
  store i8* %t225, i8** %t139
  br label %list_cow_done_54
list_cow_check_53:
  %t230 = getelementptr inbounds i8, i8* %t222, i64 -16
  %t231 = bitcast i8* %t230 to i64*
  %t232 = load atomic i64, i64* %t231 seq_cst, align 8
  %t233 = icmp eq i64 %t232, 1
  br i1 %t233, label %list_cow_done_54, label %list_cow_clone_55
list_cow_clone_55:
  %t234 = bitcast i8* %t222 to { i32*, i64, i64 }*
  %t235 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t234, i32 0, i32 0
  %t236 = load i32*, i32** %t235
  %t237 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t234, i32 0, i32 1
  %t238 = load i64, i64* %t237
  %t239 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t234, i32 0, i32 2
  %t240 = load i64, i64* %t239
  %t241 = bitcast void (i8*)* @list_release_i32 to i8*
  %t242 = call i8* @star_rc_alloc(i64 24, i8* %t241)
  %t243 = bitcast i8* %t242 to { i32*, i64, i64 }*
  %t244 = mul i64 %t240, %t221
  %t245 = call i8* @malloc(i64 %t244)
  %t246 = bitcast i8* %t245 to i32*
  %t247 = icmp sgt i64 %t238, 0
  br i1 %t247, label %list_cow_copy_56, label %list_cow_after_copy_57
list_cow_copy_56:
  %t248 = mul i64 %t238, %t221
  %t249 = bitcast i32* %t236 to i8*
  call i8* @memcpy(i8* %t245, i8* %t249, i64 %t248)
  br label %list_cow_after_copy_57
list_cow_after_copy_57:
  %t250 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t243, i32 0, i32 0
  store i32* %t246, i32** %t250
  %t251 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t243, i32 0, i32 1
  store i64 %t238, i64* %t251
  %t252 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t243, i32 0, i32 2
  store i64 %t240, i64* %t252
  call void @star_rc_release(i8* %t222)
  store i8* %t242, i8** %t139
  br label %list_cow_done_54
list_cow_done_54:
  %t253 = load i8*, i8** %t139
  %t254 = bitcast i8* %t253 to { i32*, i64, i64 }*
  %t255 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t254, i32 0, i32 0
  %t256 = load i32*, i32** %t255
  %t257 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t254, i32 0, i32 1
  %t258 = load i64, i64* %t257
  %t259 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t254, i32 0, i32 2
  %t260 = icmp eq i64 %t258, 0
  br i1 %t260, label %list_pop_empty_58, label %list_pop_nonempty_59
list_pop_nonempty_59:
  %t261 = sub i64 %t258, 1
  store i64 %t261, i64* %t257
  %t262 = load i32*, i32** %t255
  %t263 = getelementptr inbounds i32, i32* %t262, i64 %t261
  %t264 = load i32, i32* %t263
  br label %list_pop_end_60
list_pop_empty_58:
  br label %list_pop_end_60
list_pop_end_60:
  %t265 = phi i32 [ %t264, %list_pop_nonempty_59 ], [ 0, %list_pop_empty_58 ]
  store i32 %t265, i32* %t219
  %t266 = load i32, i32* %t8
  %t267 = getelementptr i32, i32* null, i32 1
  %t268 = ptrtoint i32* %t267 to i64
  %t269 = load i8*, i8** %t75
  %t270 = icmp eq i8* %t269, null
  br i1 %t270, label %list_cow_alloc_61, label %list_cow_check_62
list_cow_alloc_61:
  %t271 = bitcast void (i8*)* @list_release_i32 to i8*
  %t272 = call i8* @star_rc_alloc(i64 24, i8* %t271)
  %t273 = bitcast i8* %t272 to { i32*, i64, i64 }*
  %t274 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t273, i32 0, i32 0
  store i32* null, i32** %t274
  %t275 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t273, i32 0, i32 1
  store i64 0, i64* %t275
  %t276 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t273, i32 0, i32 2
  store i64 0, i64* %t276
  store i8* %t272, i8** %t75
  br label %list_cow_done_63
list_cow_check_62:
  %t277 = getelementptr inbounds i8, i8* %t269, i64 -16
  %t278 = bitcast i8* %t277 to i64*
  %t279 = load atomic i64, i64* %t278 seq_cst, align 8
  %t280 = icmp eq i64 %t279, 1
  br i1 %t280, label %list_cow_done_63, label %list_cow_clone_64
list_cow_clone_64:
  %t281 = bitcast i8* %t269 to { i32*, i64, i64 }*
  %t282 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t281, i32 0, i32 0
  %t283 = load i32*, i32** %t282
  %t284 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t281, i32 0, i32 1
  %t285 = load i64, i64* %t284
  %t286 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t281, i32 0, i32 2
  %t287 = load i64, i64* %t286
  %t288 = bitcast void (i8*)* @list_release_i32 to i8*
  %t289 = call i8* @star_rc_alloc(i64 24, i8* %t288)
  %t290 = bitcast i8* %t289 to { i32*, i64, i64 }*
  %t291 = mul i64 %t287, %t268
  %t292 = call i8* @malloc(i64 %t291)
  %t293 = bitcast i8* %t292 to i32*
  %t294 = icmp sgt i64 %t285, 0
  br i1 %t294, label %list_cow_copy_65, label %list_cow_after_copy_66
list_cow_copy_65:
  %t295 = mul i64 %t285, %t268
  %t296 = bitcast i32* %t283 to i8*
  call i8* @memcpy(i8* %t292, i8* %t296, i64 %t295)
  br label %list_cow_after_copy_66
list_cow_after_copy_66:
  %t297 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t290, i32 0, i32 0
  store i32* %t293, i32** %t297
  %t298 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t290, i32 0, i32 1
  store i64 %t285, i64* %t298
  %t299 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t290, i32 0, i32 2
  store i64 %t287, i64* %t299
  call void @star_rc_release(i8* %t269)
  store i8* %t289, i8** %t75
  br label %list_cow_done_63
list_cow_done_63:
  %t300 = load i8*, i8** %t75
  %t301 = bitcast i8* %t300 to { i32*, i64, i64 }*
  %t302 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t301, i32 0, i32 0
  %t303 = load i32*, i32** %t302
  %t304 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t301, i32 0, i32 1
  %t305 = load i64, i64* %t304
  %t306 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t301, i32 0, i32 2
  %t307 = load i32, i32* %t219
  %t308 = sext i32 %t307 to i64
  %t309 = icmp ult i64 %t308, %t305
  br i1 %t309, label %list_set_do_67, label %list_set_oob_68
list_set_do_67:
  %t310 = getelementptr inbounds i32, i32* %t303, i64 %t308
  store i32 %t266, i32* %t310
  br label %list_set_end_69
list_set_oob_68:
  br label %list_set_end_69
list_set_end_69:
  %t311 = load i32, i32* %t219
  %t312 = getelementptr i32, i32* null, i32 1
  %t313 = ptrtoint i32* %t312 to i64
  %t314 = load i8*, i8** %t75
  %t315 = icmp eq i8* %t314, null
  br i1 %t315, label %list_cow_alloc_70, label %list_cow_check_71
list_cow_alloc_70:
  %t316 = bitcast void (i8*)* @list_release_i32 to i8*
  %t317 = call i8* @star_rc_alloc(i64 24, i8* %t316)
  %t318 = bitcast i8* %t317 to { i32*, i64, i64 }*
  %t319 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t318, i32 0, i32 0
  store i32* null, i32** %t319
  %t320 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t318, i32 0, i32 1
  store i64 0, i64* %t320
  %t321 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t318, i32 0, i32 2
  store i64 0, i64* %t321
  store i8* %t317, i8** %t75
  br label %list_cow_done_72
list_cow_check_71:
  %t322 = getelementptr inbounds i8, i8* %t314, i64 -16
  %t323 = bitcast i8* %t322 to i64*
  %t324 = load atomic i64, i64* %t323 seq_cst, align 8
  %t325 = icmp eq i64 %t324, 1
  br i1 %t325, label %list_cow_done_72, label %list_cow_clone_73
list_cow_clone_73:
  %t326 = bitcast i8* %t314 to { i32*, i64, i64 }*
  %t327 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t326, i32 0, i32 0
  %t328 = load i32*, i32** %t327
  %t329 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t326, i32 0, i32 1
  %t330 = load i64, i64* %t329
  %t331 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t326, i32 0, i32 2
  %t332 = load i64, i64* %t331
  %t333 = bitcast void (i8*)* @list_release_i32 to i8*
  %t334 = call i8* @star_rc_alloc(i64 24, i8* %t333)
  %t335 = bitcast i8* %t334 to { i32*, i64, i64 }*
  %t336 = mul i64 %t332, %t313
  %t337 = call i8* @malloc(i64 %t336)
  %t338 = bitcast i8* %t337 to i32*
  %t339 = icmp sgt i64 %t330, 0
  br i1 %t339, label %list_cow_copy_74, label %list_cow_after_copy_75
list_cow_copy_74:
  %t340 = mul i64 %t330, %t313
  %t341 = bitcast i32* %t328 to i8*
  call i8* @memcpy(i8* %t337, i8* %t341, i64 %t340)
  br label %list_cow_after_copy_75
list_cow_after_copy_75:
  %t342 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t335, i32 0, i32 0
  store i32* %t338, i32** %t342
  %t343 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t335, i32 0, i32 1
  store i64 %t330, i64* %t343
  %t344 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t335, i32 0, i32 2
  store i64 %t332, i64* %t344
  call void @star_rc_release(i8* %t314)
  store i8* %t334, i8** %t75
  br label %list_cow_done_72
list_cow_done_72:
  %t345 = load i8*, i8** %t75
  %t346 = bitcast i8* %t345 to { i32*, i64, i64 }*
  %t347 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t346, i32 0, i32 0
  %t348 = load i32*, i32** %t347
  %t349 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t346, i32 0, i32 1
  %t350 = load i64, i64* %t349
  %t351 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t346, i32 0, i32 2
  %t352 = load i32, i32* %t8
  %t353 = sext i32 %t352 to i64
  %t354 = icmp ult i64 %t353, %t350
  br i1 %t354, label %list_set_do_76, label %list_set_oob_77
list_set_do_76:
  %t355 = getelementptr inbounds i32, i32* %t348, i64 %t353
  store i32 %t311, i32* %t355
  br label %list_set_end_78
list_set_oob_77:
  br label %list_set_end_78
list_set_end_78:
  br label %if_end_51
if_else_50:
  br label %if_end_51
if_end_51:
  %t356 = load i32, i32* %t8
  %t357 = add i32 %t356, 1
  store i32 %t357, i32* %t8
  br label %while_cond_28
while_else_30:
  br label %while_end_31
while_end_31:
  store i32 0, i32* %t358
  store i32 0, i32* %t359
  br label %while_cond_79
while_cond_79:
  %t360 = load i32, i32* %t359
  %t361 = load i32, i32* %t3
  %t362 = icmp slt i32 %t360, %t361
  br i1 %t362, label %while_body_80, label %while_else_81
while_body_80:
  %t364 = load i8*, i8** %t1
  %t365 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t365)
  %t366 = load i32, i32* %t359
  %t367 = sext i32 %t366 to i64
  %t368 = icmp eq i8* %t364, null
  br i1 %t368, label %str_idx_oob_85, label %str_idx_chk_83
str_idx_chk_83:
  %t369 = call i32 @strlen(i8* %t364)
  %t370 = sext i32 %t369 to i64
  %t371 = icmp ult i64 %t367, %t370
  br i1 %t371, label %str_idx_ok_84, label %str_idx_oob_85
str_idx_ok_84:
  %t372 = getelementptr inbounds i8, i8* %t364, i64 %t367
  %t373 = load i8, i8* %t372
  %t374 = zext i8 %t373 to i32
  br label %str_idx_end_86
str_idx_oob_85:
  br label %str_idx_end_86
str_idx_end_86:
  %t375 = phi i32 [ %t374, %str_idx_ok_84 ], [ 0, %str_idx_oob_85 ]
  call void @star_rc_release(i8* %t364)
  store i32 %t375, i32* %t363
  %t376 = load i32, i32* %t363
  br label %match_scrutinee_378
match_scrutinee_378:
  %t381 = icmp eq i32 %t376, 43
  br i1 %t381, label %match_then_0_379, label %match_next_0_380
match_then_0_379:
  %t383 = load i8*, i8** %t7
  %t384 = icmp eq i8* %t383, null
  br i1 %t384, label %list_read_null_87, label %list_read_real_88
list_read_null_87:
  br label %list_read_end_89
list_read_real_88:
  %t385 = bitcast i8* %t383 to { i32*, i64, i64 }*
  %t386 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t385, i32 0, i32 0
  %t387 = load i32*, i32** %t386
  %t388 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t385, i32 0, i32 1
  %t389 = load i64, i64* %t388
  br label %list_read_end_89
list_read_end_89:
  %t390 = phi i32* [ null, %list_read_null_87 ], [ %t387, %list_read_real_88 ]
  %t391 = phi i64 [ 0, %list_read_null_87 ], [ %t389, %list_read_real_88 ]
  %t392 = load i32, i32* %t358
  %t393 = sext i32 %t392 to i64
  %t394 = icmp ult i64 %t393, %t391
  br i1 %t394, label %list_idx_ok_90, label %list_idx_oob_91
list_idx_ok_90:
  %t395 = getelementptr inbounds i32, i32* %t390, i64 %t393
  %t396 = load i32, i32* %t395
  br label %list_idx_end_92
list_idx_oob_91:
  br label %list_idx_end_92
list_idx_end_92:
  %t397 = phi i32 [ %t396, %list_idx_ok_90 ], [ 0, %list_idx_oob_91 ]
  %t398 = add i32 %t397, 1
  store i32 %t398, i32* %t382
  %t399 = load i32, i32* %t382
  %t400 = icmp sgt i32 %t399, 255
  br i1 %t400, label %if_then_93, label %if_else_94
if_then_93:
  store i32 0, i32* %t382
  br label %if_end_95
if_else_94:
  br label %if_end_95
if_end_95:
  %t401 = load i32, i32* %t382
  %t402 = getelementptr i32, i32* null, i32 1
  %t403 = ptrtoint i32* %t402 to i64
  %t404 = load i8*, i8** %t7
  %t405 = icmp eq i8* %t404, null
  br i1 %t405, label %list_cow_alloc_96, label %list_cow_check_97
list_cow_alloc_96:
  %t406 = bitcast void (i8*)* @list_release_i32 to i8*
  %t407 = call i8* @star_rc_alloc(i64 24, i8* %t406)
  %t408 = bitcast i8* %t407 to { i32*, i64, i64 }*
  %t409 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t408, i32 0, i32 0
  store i32* null, i32** %t409
  %t410 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t408, i32 0, i32 1
  store i64 0, i64* %t410
  %t411 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t408, i32 0, i32 2
  store i64 0, i64* %t411
  store i8* %t407, i8** %t7
  br label %list_cow_done_98
list_cow_check_97:
  %t412 = getelementptr inbounds i8, i8* %t404, i64 -16
  %t413 = bitcast i8* %t412 to i64*
  %t414 = load atomic i64, i64* %t413 seq_cst, align 8
  %t415 = icmp eq i64 %t414, 1
  br i1 %t415, label %list_cow_done_98, label %list_cow_clone_99
list_cow_clone_99:
  %t416 = bitcast i8* %t404 to { i32*, i64, i64 }*
  %t417 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t416, i32 0, i32 0
  %t418 = load i32*, i32** %t417
  %t419 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t416, i32 0, i32 1
  %t420 = load i64, i64* %t419
  %t421 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t416, i32 0, i32 2
  %t422 = load i64, i64* %t421
  %t423 = bitcast void (i8*)* @list_release_i32 to i8*
  %t424 = call i8* @star_rc_alloc(i64 24, i8* %t423)
  %t425 = bitcast i8* %t424 to { i32*, i64, i64 }*
  %t426 = mul i64 %t422, %t403
  %t427 = call i8* @malloc(i64 %t426)
  %t428 = bitcast i8* %t427 to i32*
  %t429 = icmp sgt i64 %t420, 0
  br i1 %t429, label %list_cow_copy_100, label %list_cow_after_copy_101
list_cow_copy_100:
  %t430 = mul i64 %t420, %t403
  %t431 = bitcast i32* %t418 to i8*
  call i8* @memcpy(i8* %t427, i8* %t431, i64 %t430)
  br label %list_cow_after_copy_101
list_cow_after_copy_101:
  %t432 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t425, i32 0, i32 0
  store i32* %t428, i32** %t432
  %t433 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t425, i32 0, i32 1
  store i64 %t420, i64* %t433
  %t434 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t425, i32 0, i32 2
  store i64 %t422, i64* %t434
  call void @star_rc_release(i8* %t404)
  store i8* %t424, i8** %t7
  br label %list_cow_done_98
list_cow_done_98:
  %t435 = load i8*, i8** %t7
  %t436 = bitcast i8* %t435 to { i32*, i64, i64 }*
  %t437 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t436, i32 0, i32 0
  %t438 = load i32*, i32** %t437
  %t439 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t436, i32 0, i32 1
  %t440 = load i64, i64* %t439
  %t441 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t436, i32 0, i32 2
  %t442 = load i32, i32* %t358
  %t443 = sext i32 %t442 to i64
  %t444 = icmp ult i64 %t443, %t440
  br i1 %t444, label %list_set_do_102, label %list_set_oob_103
list_set_do_102:
  %t445 = getelementptr inbounds i32, i32* %t438, i64 %t443
  store i32 %t401, i32* %t445
  br label %list_set_end_104
list_set_oob_103:
  br label %list_set_end_104
list_set_end_104:
  br label %match_end_377
match_next_0_380:
  %t448 = icmp eq i32 %t376, 45
  br i1 %t448, label %match_then_1_446, label %match_next_1_447
match_then_1_446:
  %t450 = load i8*, i8** %t7
  %t451 = icmp eq i8* %t450, null
  br i1 %t451, label %list_read_null_105, label %list_read_real_106
list_read_null_105:
  br label %list_read_end_107
list_read_real_106:
  %t452 = bitcast i8* %t450 to { i32*, i64, i64 }*
  %t453 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t452, i32 0, i32 0
  %t454 = load i32*, i32** %t453
  %t455 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t452, i32 0, i32 1
  %t456 = load i64, i64* %t455
  br label %list_read_end_107
list_read_end_107:
  %t457 = phi i32* [ null, %list_read_null_105 ], [ %t454, %list_read_real_106 ]
  %t458 = phi i64 [ 0, %list_read_null_105 ], [ %t456, %list_read_real_106 ]
  %t459 = load i32, i32* %t358
  %t460 = sext i32 %t459 to i64
  %t461 = icmp ult i64 %t460, %t458
  br i1 %t461, label %list_idx_ok_108, label %list_idx_oob_109
list_idx_ok_108:
  %t462 = getelementptr inbounds i32, i32* %t457, i64 %t460
  %t463 = load i32, i32* %t462
  br label %list_idx_end_110
list_idx_oob_109:
  br label %list_idx_end_110
list_idx_end_110:
  %t464 = phi i32 [ %t463, %list_idx_ok_108 ], [ 0, %list_idx_oob_109 ]
  %t465 = sub i32 %t464, 1
  store i32 %t465, i32* %t449
  %t466 = load i32, i32* %t449
  %t467 = icmp slt i32 %t466, 0
  br i1 %t467, label %if_then_111, label %if_else_112
if_then_111:
  store i32 255, i32* %t449
  br label %if_end_113
if_else_112:
  br label %if_end_113
if_end_113:
  %t468 = load i32, i32* %t449
  %t469 = getelementptr i32, i32* null, i32 1
  %t470 = ptrtoint i32* %t469 to i64
  %t471 = load i8*, i8** %t7
  %t472 = icmp eq i8* %t471, null
  br i1 %t472, label %list_cow_alloc_114, label %list_cow_check_115
list_cow_alloc_114:
  %t473 = bitcast void (i8*)* @list_release_i32 to i8*
  %t474 = call i8* @star_rc_alloc(i64 24, i8* %t473)
  %t475 = bitcast i8* %t474 to { i32*, i64, i64 }*
  %t476 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t475, i32 0, i32 0
  store i32* null, i32** %t476
  %t477 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t475, i32 0, i32 1
  store i64 0, i64* %t477
  %t478 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t475, i32 0, i32 2
  store i64 0, i64* %t478
  store i8* %t474, i8** %t7
  br label %list_cow_done_116
list_cow_check_115:
  %t479 = getelementptr inbounds i8, i8* %t471, i64 -16
  %t480 = bitcast i8* %t479 to i64*
  %t481 = load atomic i64, i64* %t480 seq_cst, align 8
  %t482 = icmp eq i64 %t481, 1
  br i1 %t482, label %list_cow_done_116, label %list_cow_clone_117
list_cow_clone_117:
  %t483 = bitcast i8* %t471 to { i32*, i64, i64 }*
  %t484 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t483, i32 0, i32 0
  %t485 = load i32*, i32** %t484
  %t486 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t483, i32 0, i32 1
  %t487 = load i64, i64* %t486
  %t488 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t483, i32 0, i32 2
  %t489 = load i64, i64* %t488
  %t490 = bitcast void (i8*)* @list_release_i32 to i8*
  %t491 = call i8* @star_rc_alloc(i64 24, i8* %t490)
  %t492 = bitcast i8* %t491 to { i32*, i64, i64 }*
  %t493 = mul i64 %t489, %t470
  %t494 = call i8* @malloc(i64 %t493)
  %t495 = bitcast i8* %t494 to i32*
  %t496 = icmp sgt i64 %t487, 0
  br i1 %t496, label %list_cow_copy_118, label %list_cow_after_copy_119
list_cow_copy_118:
  %t497 = mul i64 %t487, %t470
  %t498 = bitcast i32* %t485 to i8*
  call i8* @memcpy(i8* %t494, i8* %t498, i64 %t497)
  br label %list_cow_after_copy_119
list_cow_after_copy_119:
  %t499 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t492, i32 0, i32 0
  store i32* %t495, i32** %t499
  %t500 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t492, i32 0, i32 1
  store i64 %t487, i64* %t500
  %t501 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t492, i32 0, i32 2
  store i64 %t489, i64* %t501
  call void @star_rc_release(i8* %t471)
  store i8* %t491, i8** %t7
  br label %list_cow_done_116
list_cow_done_116:
  %t502 = load i8*, i8** %t7
  %t503 = bitcast i8* %t502 to { i32*, i64, i64 }*
  %t504 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t503, i32 0, i32 0
  %t505 = load i32*, i32** %t504
  %t506 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t503, i32 0, i32 1
  %t507 = load i64, i64* %t506
  %t508 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t503, i32 0, i32 2
  %t509 = load i32, i32* %t358
  %t510 = sext i32 %t509 to i64
  %t511 = icmp ult i64 %t510, %t507
  br i1 %t511, label %list_set_do_120, label %list_set_oob_121
list_set_do_120:
  %t512 = getelementptr inbounds i32, i32* %t505, i64 %t510
  store i32 %t468, i32* %t512
  br label %list_set_end_122
list_set_oob_121:
  br label %list_set_end_122
list_set_end_122:
  br label %match_end_377
match_next_1_447:
  %t515 = icmp eq i32 %t376, 62
  br i1 %t515, label %match_then_2_513, label %match_next_2_514
match_then_2_513:
  %t516 = load i32, i32* %t358
  %t517 = add i32 %t516, 1
  store i32 %t517, i32* %t358
  br label %match_end_377
match_next_2_514:
  %t520 = icmp eq i32 %t376, 60
  br i1 %t520, label %match_then_3_518, label %match_next_3_519
match_then_3_518:
  %t521 = load i32, i32* %t358
  %t522 = sub i32 %t521, 1
  store i32 %t522, i32* %t358
  br label %match_end_377
match_next_3_519:
  %t525 = icmp eq i32 %t376, 46
  br i1 %t525, label %match_then_4_523, label %match_next_4_524
match_then_4_523:
  %t526 = load i8*, i8** %t7
  %t527 = icmp eq i8* %t526, null
  br i1 %t527, label %list_read_null_123, label %list_read_real_124
list_read_null_123:
  br label %list_read_end_125
list_read_real_124:
  %t528 = bitcast i8* %t526 to { i32*, i64, i64 }*
  %t529 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t528, i32 0, i32 0
  %t530 = load i32*, i32** %t529
  %t531 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t528, i32 0, i32 1
  %t532 = load i64, i64* %t531
  br label %list_read_end_125
list_read_end_125:
  %t533 = phi i32* [ null, %list_read_null_123 ], [ %t530, %list_read_real_124 ]
  %t534 = phi i64 [ 0, %list_read_null_123 ], [ %t532, %list_read_real_124 ]
  %t535 = load i32, i32* %t358
  %t536 = sext i32 %t535 to i64
  %t537 = icmp ult i64 %t536, %t534
  br i1 %t537, label %list_idx_ok_126, label %list_idx_oob_127
list_idx_ok_126:
  %t538 = getelementptr inbounds i32, i32* %t533, i64 %t536
  %t539 = load i32, i32* %t538
  br label %list_idx_end_128
list_idx_oob_127:
  br label %list_idx_end_128
list_idx_end_128:
  %t540 = phi i32 [ %t539, %list_idx_ok_126 ], [ 0, %list_idx_oob_127 ]
  %t541 = call i32 @putchar(i32 %t540)
  br label %match_end_377
match_next_4_524:
  %t544 = icmp eq i32 %t376, 44
  br i1 %t544, label %match_then_5_542, label %match_next_5_543
match_then_5_542:
  %t545 = getelementptr i32, i32* null, i32 1
  %t546 = ptrtoint i32* %t545 to i64
  %t547 = load i8*, i8** %t7
  %t548 = icmp eq i8* %t547, null
  br i1 %t548, label %list_cow_alloc_129, label %list_cow_check_130
list_cow_alloc_129:
  %t549 = bitcast void (i8*)* @list_release_i32 to i8*
  %t550 = call i8* @star_rc_alloc(i64 24, i8* %t549)
  %t551 = bitcast i8* %t550 to { i32*, i64, i64 }*
  %t552 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t551, i32 0, i32 0
  store i32* null, i32** %t552
  %t553 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t551, i32 0, i32 1
  store i64 0, i64* %t553
  %t554 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t551, i32 0, i32 2
  store i64 0, i64* %t554
  store i8* %t550, i8** %t7
  br label %list_cow_done_131
list_cow_check_130:
  %t555 = getelementptr inbounds i8, i8* %t547, i64 -16
  %t556 = bitcast i8* %t555 to i64*
  %t557 = load atomic i64, i64* %t556 seq_cst, align 8
  %t558 = icmp eq i64 %t557, 1
  br i1 %t558, label %list_cow_done_131, label %list_cow_clone_132
list_cow_clone_132:
  %t559 = bitcast i8* %t547 to { i32*, i64, i64 }*
  %t560 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t559, i32 0, i32 0
  %t561 = load i32*, i32** %t560
  %t562 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t559, i32 0, i32 1
  %t563 = load i64, i64* %t562
  %t564 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t559, i32 0, i32 2
  %t565 = load i64, i64* %t564
  %t566 = bitcast void (i8*)* @list_release_i32 to i8*
  %t567 = call i8* @star_rc_alloc(i64 24, i8* %t566)
  %t568 = bitcast i8* %t567 to { i32*, i64, i64 }*
  %t569 = mul i64 %t565, %t546
  %t570 = call i8* @malloc(i64 %t569)
  %t571 = bitcast i8* %t570 to i32*
  %t572 = icmp sgt i64 %t563, 0
  br i1 %t572, label %list_cow_copy_133, label %list_cow_after_copy_134
list_cow_copy_133:
  %t573 = mul i64 %t563, %t546
  %t574 = bitcast i32* %t561 to i8*
  call i8* @memcpy(i8* %t570, i8* %t574, i64 %t573)
  br label %list_cow_after_copy_134
list_cow_after_copy_134:
  %t575 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t568, i32 0, i32 0
  store i32* %t571, i32** %t575
  %t576 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t568, i32 0, i32 1
  store i64 %t563, i64* %t576
  %t577 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t568, i32 0, i32 2
  store i64 %t565, i64* %t577
  call void @star_rc_release(i8* %t547)
  store i8* %t567, i8** %t7
  br label %list_cow_done_131
list_cow_done_131:
  %t578 = load i8*, i8** %t7
  %t579 = bitcast i8* %t578 to { i32*, i64, i64 }*
  %t580 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t579, i32 0, i32 0
  %t581 = load i32*, i32** %t580
  %t582 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t579, i32 0, i32 1
  %t583 = load i64, i64* %t582
  %t584 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t579, i32 0, i32 2
  %t585 = load i32, i32* %t358
  %t586 = sext i32 %t585 to i64
  %t587 = icmp ult i64 %t586, %t583
  br i1 %t587, label %list_set_do_135, label %list_set_oob_136
list_set_do_135:
  %t588 = getelementptr inbounds i32, i32* %t581, i64 %t586
  store i32 0, i32* %t588
  br label %list_set_end_137
list_set_oob_136:
  br label %list_set_end_137
list_set_end_137:
  br label %match_end_377
match_next_5_543:
  %t591 = icmp eq i32 %t376, 91
  br i1 %t591, label %match_then_6_589, label %match_next_6_590
match_then_6_589:
  %t592 = load i8*, i8** %t7
  %t593 = icmp eq i8* %t592, null
  br i1 %t593, label %list_read_null_138, label %list_read_real_139
list_read_null_138:
  br label %list_read_end_140
list_read_real_139:
  %t594 = bitcast i8* %t592 to { i32*, i64, i64 }*
  %t595 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t594, i32 0, i32 0
  %t596 = load i32*, i32** %t595
  %t597 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t594, i32 0, i32 1
  %t598 = load i64, i64* %t597
  br label %list_read_end_140
list_read_end_140:
  %t599 = phi i32* [ null, %list_read_null_138 ], [ %t596, %list_read_real_139 ]
  %t600 = phi i64 [ 0, %list_read_null_138 ], [ %t598, %list_read_real_139 ]
  %t601 = load i32, i32* %t358
  %t602 = sext i32 %t601 to i64
  %t603 = icmp ult i64 %t602, %t600
  br i1 %t603, label %list_idx_ok_141, label %list_idx_oob_142
list_idx_ok_141:
  %t604 = getelementptr inbounds i32, i32* %t599, i64 %t602
  %t605 = load i32, i32* %t604
  br label %list_idx_end_143
list_idx_oob_142:
  br label %list_idx_end_143
list_idx_end_143:
  %t606 = phi i32 [ %t605, %list_idx_ok_141 ], [ 0, %list_idx_oob_142 ]
  %t607 = icmp eq i32 %t606, 0
  br i1 %t607, label %if_then_144, label %if_else_145
if_then_144:
  %t608 = load i8*, i8** %t75
  %t609 = icmp eq i8* %t608, null
  br i1 %t609, label %list_read_null_147, label %list_read_real_148
list_read_null_147:
  br label %list_read_end_149
list_read_real_148:
  %t610 = bitcast i8* %t608 to { i32*, i64, i64 }*
  %t611 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t610, i32 0, i32 0
  %t612 = load i32*, i32** %t611
  %t613 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t610, i32 0, i32 1
  %t614 = load i64, i64* %t613
  br label %list_read_end_149
list_read_end_149:
  %t615 = phi i32* [ null, %list_read_null_147 ], [ %t612, %list_read_real_148 ]
  %t616 = phi i64 [ 0, %list_read_null_147 ], [ %t614, %list_read_real_148 ]
  %t617 = load i32, i32* %t359
  %t618 = sext i32 %t617 to i64
  %t619 = icmp ult i64 %t618, %t616
  br i1 %t619, label %list_idx_ok_150, label %list_idx_oob_151
list_idx_ok_150:
  %t620 = getelementptr inbounds i32, i32* %t615, i64 %t618
  %t621 = load i32, i32* %t620
  br label %list_idx_end_152
list_idx_oob_151:
  br label %list_idx_end_152
list_idx_end_152:
  %t622 = phi i32 [ %t621, %list_idx_ok_150 ], [ 0, %list_idx_oob_151 ]
  store i32 %t622, i32* %t359
  br label %if_end_146
if_else_145:
  br label %if_end_146
if_end_146:
  br label %match_end_377
match_next_6_590:
  %t625 = icmp eq i32 %t376, 93
  br i1 %t625, label %match_then_7_623, label %match_next_7_624
match_then_7_623:
  %t626 = load i8*, i8** %t7
  %t627 = icmp eq i8* %t626, null
  br i1 %t627, label %list_read_null_153, label %list_read_real_154
list_read_null_153:
  br label %list_read_end_155
list_read_real_154:
  %t628 = bitcast i8* %t626 to { i32*, i64, i64 }*
  %t629 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t628, i32 0, i32 0
  %t630 = load i32*, i32** %t629
  %t631 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t628, i32 0, i32 1
  %t632 = load i64, i64* %t631
  br label %list_read_end_155
list_read_end_155:
  %t633 = phi i32* [ null, %list_read_null_153 ], [ %t630, %list_read_real_154 ]
  %t634 = phi i64 [ 0, %list_read_null_153 ], [ %t632, %list_read_real_154 ]
  %t635 = load i32, i32* %t358
  %t636 = sext i32 %t635 to i64
  %t637 = icmp ult i64 %t636, %t634
  br i1 %t637, label %list_idx_ok_156, label %list_idx_oob_157
list_idx_ok_156:
  %t638 = getelementptr inbounds i32, i32* %t633, i64 %t636
  %t639 = load i32, i32* %t638
  br label %list_idx_end_158
list_idx_oob_157:
  br label %list_idx_end_158
list_idx_end_158:
  %t640 = phi i32 [ %t639, %list_idx_ok_156 ], [ 0, %list_idx_oob_157 ]
  %t641 = icmp ne i32 %t640, 0
  br i1 %t641, label %if_then_159, label %if_else_160
if_then_159:
  %t642 = load i8*, i8** %t75
  %t643 = icmp eq i8* %t642, null
  br i1 %t643, label %list_read_null_162, label %list_read_real_163
list_read_null_162:
  br label %list_read_end_164
list_read_real_163:
  %t644 = bitcast i8* %t642 to { i32*, i64, i64 }*
  %t645 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t644, i32 0, i32 0
  %t646 = load i32*, i32** %t645
  %t647 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t644, i32 0, i32 1
  %t648 = load i64, i64* %t647
  br label %list_read_end_164
list_read_end_164:
  %t649 = phi i32* [ null, %list_read_null_162 ], [ %t646, %list_read_real_163 ]
  %t650 = phi i64 [ 0, %list_read_null_162 ], [ %t648, %list_read_real_163 ]
  %t651 = load i32, i32* %t359
  %t652 = sext i32 %t651 to i64
  %t653 = icmp ult i64 %t652, %t650
  br i1 %t653, label %list_idx_ok_165, label %list_idx_oob_166
list_idx_ok_165:
  %t654 = getelementptr inbounds i32, i32* %t649, i64 %t652
  %t655 = load i32, i32* %t654
  br label %list_idx_end_167
list_idx_oob_166:
  br label %list_idx_end_167
list_idx_end_167:
  %t656 = phi i32 [ %t655, %list_idx_ok_165 ], [ 0, %list_idx_oob_166 ]
  store i32 %t656, i32* %t359
  br label %if_end_161
if_else_160:
  br label %if_end_161
if_end_161:
  br label %match_end_377
match_next_7_624:
  br label %match_end_377
match_end_377:
  %t659 = phi i32 [ undef, %list_set_end_104 ], [ undef, %list_set_end_122 ], [ undef, %match_then_2_513 ], [ undef, %match_then_3_518 ], [ %t541, %list_idx_end_128 ], [ undef, %list_set_end_137 ], [ undef, %if_end_146 ], [ undef, %if_end_161 ], [ 0, %match_next_7_624 ]
  %t660 = load i32, i32* %t359
  %t661 = add i32 %t660, 1
  store i32 %t661, i32* %t359
  br label %while_cond_79
while_else_81:
  br label %while_end_82
while_end_82:
  %t662 = load i8*, i8** %t139
  call void @star_rc_release(i8* %t662)
  %t663 = load i8*, i8** %t75
  call void @star_rc_release(i8* %t663)
  %t664 = load i8*, i8** %t7
  call void @star_rc_release(i8* %t664)
  %t665 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t665)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_i32(i8* %objp) {
entry:
  %t15 = bitcast i8* %objp to { i32*, i64, i64 }*
  %t16 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t15, i32 0, i32 0
  %t17 = load i32*, i32** %t16
  %t18 = bitcast i32* %t17 to i8*
  call void @free(i8* %t18)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [107 x i8] } { i64 -1, i8* null, [107 x i8] c"++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.\00" }
