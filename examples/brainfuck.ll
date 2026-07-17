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

declare i32 @putchar(i32)
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t0 = alloca i8*
  %t2 = alloca i32
  %t6 = alloca i8*
  %t7 = alloca i32
  %t74 = alloca i8*
  %t138 = alloca i8*
  %t142 = alloca i32
  %t218 = alloca i32
  %t357 = alloca i32
  %t358 = alloca i32
  %t362 = alloca i32
  %t381 = alloca i32
  %t448 = alloca i32
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t1 = getelementptr inbounds { i64, i8*, [107 x i8] }, { i64, i8*, [107 x i8] }* @.str.0, i64 0, i32 2, i64 0
  store i8* %t1, i8** %t0
  %t3 = load i8*, i8** %t0
  %t4 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t4)
  %t5 = call i32 @strlen(i8* %t3)
  call void @star_rc_release(i8* %t3)
  store i32 %t5, i32* %t2
  store i8* null, i8** %t6
  store i32 0, i32* %t7
  br label %while_cond_0
while_cond_0:
  %t8 = load i32, i32* %t7
  %t9 = icmp slt i32 %t8, 30000
  br i1 %t9, label %while_body_1, label %while_else_2
while_body_1:
  %t10 = getelementptr i32, i32* null, i32 1
  %t11 = ptrtoint i32* %t10 to i64
  %t12 = load i8*, i8** %t6
  %t13 = icmp eq i8* %t12, null
  br i1 %t13, label %list_cow_alloc_4, label %list_cow_check_5
list_cow_alloc_4:
  %t18 = bitcast void (i8*)* @list_release_i32 to i8*
  %t19 = call i8* @star_rc_alloc(i64 24, i8* %t18)
  %t20 = bitcast i8* %t19 to { i32*, i64, i64 }*
  %t21 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t20, i32 0, i32 0
  store i32* null, i32** %t21
  %t22 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t20, i32 0, i32 1
  store i64 0, i64* %t22
  %t23 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t20, i32 0, i32 2
  store i64 0, i64* %t23
  store i8* %t19, i8** %t6
  br label %list_cow_done_6
list_cow_check_5:
  %t24 = getelementptr inbounds i8, i8* %t12, i64 -16
  %t25 = bitcast i8* %t24 to i64*
  %t26 = load atomic i64, i64* %t25 seq_cst, align 8
  %t27 = icmp eq i64 %t26, 1
  br i1 %t27, label %list_cow_done_6, label %list_cow_clone_7
list_cow_clone_7:
  %t28 = bitcast i8* %t12 to { i32*, i64, i64 }*
  %t29 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t28, i32 0, i32 0
  %t30 = load i32*, i32** %t29
  %t31 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t28, i32 0, i32 1
  %t32 = load i64, i64* %t31
  %t33 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t28, i32 0, i32 2
  %t34 = load i64, i64* %t33
  %t35 = bitcast void (i8*)* @list_release_i32 to i8*
  %t36 = call i8* @star_rc_alloc(i64 24, i8* %t35)
  %t37 = bitcast i8* %t36 to { i32*, i64, i64 }*
  %t38 = mul i64 %t34, %t11
  %t39 = call i8* @malloc(i64 %t38)
  %t40 = bitcast i8* %t39 to i32*
  %t41 = icmp sgt i64 %t32, 0
  br i1 %t41, label %list_cow_copy_8, label %list_cow_after_copy_9
list_cow_copy_8:
  %t42 = mul i64 %t32, %t11
  %t43 = bitcast i32* %t30 to i8*
  call i8* @memcpy(i8* %t39, i8* %t43, i64 %t42)
  br label %list_cow_after_copy_9
list_cow_after_copy_9:
  %t44 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t37, i32 0, i32 0
  store i32* %t40, i32** %t44
  %t45 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t37, i32 0, i32 1
  store i64 %t32, i64* %t45
  %t46 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t37, i32 0, i32 2
  store i64 %t34, i64* %t46
  call void @star_rc_release(i8* %t12)
  store i8* %t36, i8** %t6
  br label %list_cow_done_6
list_cow_done_6:
  %t47 = load i8*, i8** %t6
  %t48 = bitcast i8* %t47 to { i32*, i64, i64 }*
  %t49 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t48, i32 0, i32 0
  %t50 = load i32*, i32** %t49
  %t51 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t48, i32 0, i32 1
  %t52 = load i64, i64* %t51
  %t53 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t48, i32 0, i32 2
  %t54 = load i64, i64* %t53
  %t55 = load i32*, i32** %t49
  %t56 = load i64, i64* %t51
  %t57 = icmp sge i64 %t56, %t54
  br i1 %t57, label %list_push_grow_10, label %list_push_store_11
list_push_grow_10:
  %t58 = mul i64 %t54, 2
  %t59 = icmp sgt i64 %t58, 0
  %t60 = select i1 %t59, i64 %t58, i64 1
  %t61 = getelementptr i32, i32* null, i32 1
  %t62 = ptrtoint i32* %t61 to i64
  %t63 = mul i64 %t60, %t62
  %t64 = call i8* @malloc(i64 %t63)
  %t65 = bitcast i8* %t64 to i32*
  %t66 = icmp sgt i64 %t54, 0
  br i1 %t66, label %list_push_copy_12, label %list_push_after_copy_13
list_push_copy_12:
  %t67 = mul i64 %t56, %t62
  %t68 = bitcast i32* %t55 to i8*
  call i8* @memcpy(i8* %t64, i8* %t68, i64 %t67)
  call void @free(i8* %t68)
  br label %list_push_after_copy_13
list_push_after_copy_13:
  store i32* %t65, i32** %t49
  store i64 %t60, i64* %t53
  br label %list_push_store_11
list_push_store_11:
  %t69 = load i32*, i32** %t49
  %t70 = getelementptr inbounds i32, i32* %t69, i64 %t56
  store i32 0, i32* %t70
  %t71 = add i64 %t56, 1
  store i64 %t71, i64* %t51
  %t72 = load i32, i32* %t7
  %t73 = add i32 %t72, 1
  store i32 %t73, i32* %t7
  br label %while_cond_0
while_else_2:
  br label %while_end_3
while_end_3:
  store i8* null, i8** %t74
  store i32 0, i32* %t7
  br label %while_cond_14
while_cond_14:
  %t75 = load i32, i32* %t7
  %t76 = load i32, i32* %t2
  %t77 = icmp slt i32 %t75, %t76
  br i1 %t77, label %while_body_15, label %while_else_16
while_body_15:
  %t78 = getelementptr i32, i32* null, i32 1
  %t79 = ptrtoint i32* %t78 to i64
  %t80 = load i8*, i8** %t74
  %t81 = icmp eq i8* %t80, null
  br i1 %t81, label %list_cow_alloc_18, label %list_cow_check_19
list_cow_alloc_18:
  %t82 = bitcast void (i8*)* @list_release_i32 to i8*
  %t83 = call i8* @star_rc_alloc(i64 24, i8* %t82)
  %t84 = bitcast i8* %t83 to { i32*, i64, i64 }*
  %t85 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t84, i32 0, i32 0
  store i32* null, i32** %t85
  %t86 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t84, i32 0, i32 1
  store i64 0, i64* %t86
  %t87 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t84, i32 0, i32 2
  store i64 0, i64* %t87
  store i8* %t83, i8** %t74
  br label %list_cow_done_20
list_cow_check_19:
  %t88 = getelementptr inbounds i8, i8* %t80, i64 -16
  %t89 = bitcast i8* %t88 to i64*
  %t90 = load atomic i64, i64* %t89 seq_cst, align 8
  %t91 = icmp eq i64 %t90, 1
  br i1 %t91, label %list_cow_done_20, label %list_cow_clone_21
list_cow_clone_21:
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
  %t102 = mul i64 %t98, %t79
  %t103 = call i8* @malloc(i64 %t102)
  %t104 = bitcast i8* %t103 to i32*
  %t105 = icmp sgt i64 %t96, 0
  br i1 %t105, label %list_cow_copy_22, label %list_cow_after_copy_23
list_cow_copy_22:
  %t106 = mul i64 %t96, %t79
  %t107 = bitcast i32* %t94 to i8*
  call i8* @memcpy(i8* %t103, i8* %t107, i64 %t106)
  br label %list_cow_after_copy_23
list_cow_after_copy_23:
  %t108 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t101, i32 0, i32 0
  store i32* %t104, i32** %t108
  %t109 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t101, i32 0, i32 1
  store i64 %t96, i64* %t109
  %t110 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t101, i32 0, i32 2
  store i64 %t98, i64* %t110
  call void @star_rc_release(i8* %t80)
  store i8* %t100, i8** %t74
  br label %list_cow_done_20
list_cow_done_20:
  %t111 = load i8*, i8** %t74
  %t112 = bitcast i8* %t111 to { i32*, i64, i64 }*
  %t113 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t112, i32 0, i32 0
  %t114 = load i32*, i32** %t113
  %t115 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t112, i32 0, i32 1
  %t116 = load i64, i64* %t115
  %t117 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t112, i32 0, i32 2
  %t118 = load i64, i64* %t117
  %t119 = load i32*, i32** %t113
  %t120 = load i64, i64* %t115
  %t121 = icmp sge i64 %t120, %t118
  br i1 %t121, label %list_push_grow_24, label %list_push_store_25
list_push_grow_24:
  %t122 = mul i64 %t118, 2
  %t123 = icmp sgt i64 %t122, 0
  %t124 = select i1 %t123, i64 %t122, i64 1
  %t125 = getelementptr i32, i32* null, i32 1
  %t126 = ptrtoint i32* %t125 to i64
  %t127 = mul i64 %t124, %t126
  %t128 = call i8* @malloc(i64 %t127)
  %t129 = bitcast i8* %t128 to i32*
  %t130 = icmp sgt i64 %t118, 0
  br i1 %t130, label %list_push_copy_26, label %list_push_after_copy_27
list_push_copy_26:
  %t131 = mul i64 %t120, %t126
  %t132 = bitcast i32* %t119 to i8*
  call i8* @memcpy(i8* %t128, i8* %t132, i64 %t131)
  call void @free(i8* %t132)
  br label %list_push_after_copy_27
list_push_after_copy_27:
  store i32* %t129, i32** %t113
  store i64 %t124, i64* %t117
  br label %list_push_store_25
list_push_store_25:
  %t133 = load i32*, i32** %t113
  %t134 = getelementptr inbounds i32, i32* %t133, i64 %t120
  store i32 0, i32* %t134
  %t135 = add i64 %t120, 1
  store i64 %t135, i64* %t115
  %t136 = load i32, i32* %t7
  %t137 = add i32 %t136, 1
  store i32 %t137, i32* %t7
  br label %while_cond_14
while_else_16:
  br label %while_end_17
while_end_17:
  store i8* null, i8** %t138
  store i32 0, i32* %t7
  br label %while_cond_28
while_cond_28:
  %t139 = load i32, i32* %t7
  %t140 = load i32, i32* %t2
  %t141 = icmp slt i32 %t139, %t140
  br i1 %t141, label %while_body_29, label %while_else_30
while_body_29:
  %t143 = load i8*, i8** %t0
  %t144 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t144)
  %t145 = load i32, i32* %t7
  %t146 = sext i32 %t145 to i64
  %t147 = icmp eq i8* %t143, null
  br i1 %t147, label %str_idx_oob_34, label %str_idx_chk_32
str_idx_chk_32:
  %t148 = call i32 @strlen(i8* %t143)
  %t149 = sext i32 %t148 to i64
  %t150 = icmp ult i64 %t146, %t149
  br i1 %t150, label %str_idx_ok_33, label %str_idx_oob_34
str_idx_ok_33:
  %t151 = getelementptr inbounds i8, i8* %t143, i64 %t146
  %t152 = load i8, i8* %t151
  %t153 = zext i8 %t152 to i32
  br label %str_idx_end_35
str_idx_oob_34:
  br label %str_idx_end_35
str_idx_end_35:
  %t154 = phi i32 [ %t153, %str_idx_ok_33 ], [ 0, %str_idx_oob_34 ]
  call void @star_rc_release(i8* %t143)
  store i32 %t154, i32* %t142
  %t155 = load i32, i32* %t142
  %t156 = icmp eq i32 %t155, 91
  br i1 %t156, label %if_then_36, label %if_else_37
if_then_36:
  %t157 = getelementptr i32, i32* null, i32 1
  %t158 = ptrtoint i32* %t157 to i64
  %t159 = load i8*, i8** %t138
  %t160 = icmp eq i8* %t159, null
  br i1 %t160, label %list_cow_alloc_39, label %list_cow_check_40
list_cow_alloc_39:
  %t161 = bitcast void (i8*)* @list_release_i32 to i8*
  %t162 = call i8* @star_rc_alloc(i64 24, i8* %t161)
  %t163 = bitcast i8* %t162 to { i32*, i64, i64 }*
  %t164 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t163, i32 0, i32 0
  store i32* null, i32** %t164
  %t165 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t163, i32 0, i32 1
  store i64 0, i64* %t165
  %t166 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t163, i32 0, i32 2
  store i64 0, i64* %t166
  store i8* %t162, i8** %t138
  br label %list_cow_done_41
list_cow_check_40:
  %t167 = getelementptr inbounds i8, i8* %t159, i64 -16
  %t168 = bitcast i8* %t167 to i64*
  %t169 = load atomic i64, i64* %t168 seq_cst, align 8
  %t170 = icmp eq i64 %t169, 1
  br i1 %t170, label %list_cow_done_41, label %list_cow_clone_42
list_cow_clone_42:
  %t171 = bitcast i8* %t159 to { i32*, i64, i64 }*
  %t172 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t171, i32 0, i32 0
  %t173 = load i32*, i32** %t172
  %t174 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t171, i32 0, i32 1
  %t175 = load i64, i64* %t174
  %t176 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t171, i32 0, i32 2
  %t177 = load i64, i64* %t176
  %t178 = bitcast void (i8*)* @list_release_i32 to i8*
  %t179 = call i8* @star_rc_alloc(i64 24, i8* %t178)
  %t180 = bitcast i8* %t179 to { i32*, i64, i64 }*
  %t181 = mul i64 %t177, %t158
  %t182 = call i8* @malloc(i64 %t181)
  %t183 = bitcast i8* %t182 to i32*
  %t184 = icmp sgt i64 %t175, 0
  br i1 %t184, label %list_cow_copy_43, label %list_cow_after_copy_44
list_cow_copy_43:
  %t185 = mul i64 %t175, %t158
  %t186 = bitcast i32* %t173 to i8*
  call i8* @memcpy(i8* %t182, i8* %t186, i64 %t185)
  br label %list_cow_after_copy_44
list_cow_after_copy_44:
  %t187 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t180, i32 0, i32 0
  store i32* %t183, i32** %t187
  %t188 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t180, i32 0, i32 1
  store i64 %t175, i64* %t188
  %t189 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t180, i32 0, i32 2
  store i64 %t177, i64* %t189
  call void @star_rc_release(i8* %t159)
  store i8* %t179, i8** %t138
  br label %list_cow_done_41
list_cow_done_41:
  %t190 = load i8*, i8** %t138
  %t191 = bitcast i8* %t190 to { i32*, i64, i64 }*
  %t192 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t191, i32 0, i32 0
  %t193 = load i32*, i32** %t192
  %t194 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t191, i32 0, i32 1
  %t195 = load i64, i64* %t194
  %t196 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t191, i32 0, i32 2
  %t197 = load i32, i32* %t7
  %t198 = load i64, i64* %t196
  %t199 = load i32*, i32** %t192
  %t200 = load i64, i64* %t194
  %t201 = icmp sge i64 %t200, %t198
  br i1 %t201, label %list_push_grow_45, label %list_push_store_46
list_push_grow_45:
  %t202 = mul i64 %t198, 2
  %t203 = icmp sgt i64 %t202, 0
  %t204 = select i1 %t203, i64 %t202, i64 1
  %t205 = getelementptr i32, i32* null, i32 1
  %t206 = ptrtoint i32* %t205 to i64
  %t207 = mul i64 %t204, %t206
  %t208 = call i8* @malloc(i64 %t207)
  %t209 = bitcast i8* %t208 to i32*
  %t210 = icmp sgt i64 %t198, 0
  br i1 %t210, label %list_push_copy_47, label %list_push_after_copy_48
list_push_copy_47:
  %t211 = mul i64 %t200, %t206
  %t212 = bitcast i32* %t199 to i8*
  call i8* @memcpy(i8* %t208, i8* %t212, i64 %t211)
  call void @free(i8* %t212)
  br label %list_push_after_copy_48
list_push_after_copy_48:
  store i32* %t209, i32** %t192
  store i64 %t204, i64* %t196
  br label %list_push_store_46
list_push_store_46:
  %t213 = load i32*, i32** %t192
  %t214 = getelementptr inbounds i32, i32* %t213, i64 %t200
  store i32 %t197, i32* %t214
  %t215 = add i64 %t200, 1
  store i64 %t215, i64* %t194
  br label %if_end_38
if_else_37:
  br label %if_end_38
if_end_38:
  %t216 = load i32, i32* %t142
  %t217 = icmp eq i32 %t216, 93
  br i1 %t217, label %if_then_49, label %if_else_50
if_then_49:
  %t219 = getelementptr i32, i32* null, i32 1
  %t220 = ptrtoint i32* %t219 to i64
  %t221 = load i8*, i8** %t138
  %t222 = icmp eq i8* %t221, null
  br i1 %t222, label %list_cow_alloc_52, label %list_cow_check_53
list_cow_alloc_52:
  %t223 = bitcast void (i8*)* @list_release_i32 to i8*
  %t224 = call i8* @star_rc_alloc(i64 24, i8* %t223)
  %t225 = bitcast i8* %t224 to { i32*, i64, i64 }*
  %t226 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t225, i32 0, i32 0
  store i32* null, i32** %t226
  %t227 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t225, i32 0, i32 1
  store i64 0, i64* %t227
  %t228 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t225, i32 0, i32 2
  store i64 0, i64* %t228
  store i8* %t224, i8** %t138
  br label %list_cow_done_54
list_cow_check_53:
  %t229 = getelementptr inbounds i8, i8* %t221, i64 -16
  %t230 = bitcast i8* %t229 to i64*
  %t231 = load atomic i64, i64* %t230 seq_cst, align 8
  %t232 = icmp eq i64 %t231, 1
  br i1 %t232, label %list_cow_done_54, label %list_cow_clone_55
list_cow_clone_55:
  %t233 = bitcast i8* %t221 to { i32*, i64, i64 }*
  %t234 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t233, i32 0, i32 0
  %t235 = load i32*, i32** %t234
  %t236 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t233, i32 0, i32 1
  %t237 = load i64, i64* %t236
  %t238 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t233, i32 0, i32 2
  %t239 = load i64, i64* %t238
  %t240 = bitcast void (i8*)* @list_release_i32 to i8*
  %t241 = call i8* @star_rc_alloc(i64 24, i8* %t240)
  %t242 = bitcast i8* %t241 to { i32*, i64, i64 }*
  %t243 = mul i64 %t239, %t220
  %t244 = call i8* @malloc(i64 %t243)
  %t245 = bitcast i8* %t244 to i32*
  %t246 = icmp sgt i64 %t237, 0
  br i1 %t246, label %list_cow_copy_56, label %list_cow_after_copy_57
list_cow_copy_56:
  %t247 = mul i64 %t237, %t220
  %t248 = bitcast i32* %t235 to i8*
  call i8* @memcpy(i8* %t244, i8* %t248, i64 %t247)
  br label %list_cow_after_copy_57
list_cow_after_copy_57:
  %t249 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t242, i32 0, i32 0
  store i32* %t245, i32** %t249
  %t250 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t242, i32 0, i32 1
  store i64 %t237, i64* %t250
  %t251 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t242, i32 0, i32 2
  store i64 %t239, i64* %t251
  call void @star_rc_release(i8* %t221)
  store i8* %t241, i8** %t138
  br label %list_cow_done_54
list_cow_done_54:
  %t252 = load i8*, i8** %t138
  %t253 = bitcast i8* %t252 to { i32*, i64, i64 }*
  %t254 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t253, i32 0, i32 0
  %t255 = load i32*, i32** %t254
  %t256 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t253, i32 0, i32 1
  %t257 = load i64, i64* %t256
  %t258 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t253, i32 0, i32 2
  %t259 = icmp eq i64 %t257, 0
  br i1 %t259, label %list_pop_empty_58, label %list_pop_nonempty_59
list_pop_nonempty_59:
  %t260 = sub i64 %t257, 1
  store i64 %t260, i64* %t256
  %t261 = load i32*, i32** %t254
  %t262 = getelementptr inbounds i32, i32* %t261, i64 %t260
  %t263 = load i32, i32* %t262
  br label %list_pop_end_60
list_pop_empty_58:
  br label %list_pop_end_60
list_pop_end_60:
  %t264 = phi i32 [ %t263, %list_pop_nonempty_59 ], [ 0, %list_pop_empty_58 ]
  store i32 %t264, i32* %t218
  %t265 = load i32, i32* %t7
  %t266 = getelementptr i32, i32* null, i32 1
  %t267 = ptrtoint i32* %t266 to i64
  %t268 = load i8*, i8** %t74
  %t269 = icmp eq i8* %t268, null
  br i1 %t269, label %list_cow_alloc_61, label %list_cow_check_62
list_cow_alloc_61:
  %t270 = bitcast void (i8*)* @list_release_i32 to i8*
  %t271 = call i8* @star_rc_alloc(i64 24, i8* %t270)
  %t272 = bitcast i8* %t271 to { i32*, i64, i64 }*
  %t273 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t272, i32 0, i32 0
  store i32* null, i32** %t273
  %t274 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t272, i32 0, i32 1
  store i64 0, i64* %t274
  %t275 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t272, i32 0, i32 2
  store i64 0, i64* %t275
  store i8* %t271, i8** %t74
  br label %list_cow_done_63
list_cow_check_62:
  %t276 = getelementptr inbounds i8, i8* %t268, i64 -16
  %t277 = bitcast i8* %t276 to i64*
  %t278 = load atomic i64, i64* %t277 seq_cst, align 8
  %t279 = icmp eq i64 %t278, 1
  br i1 %t279, label %list_cow_done_63, label %list_cow_clone_64
list_cow_clone_64:
  %t280 = bitcast i8* %t268 to { i32*, i64, i64 }*
  %t281 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t280, i32 0, i32 0
  %t282 = load i32*, i32** %t281
  %t283 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t280, i32 0, i32 1
  %t284 = load i64, i64* %t283
  %t285 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t280, i32 0, i32 2
  %t286 = load i64, i64* %t285
  %t287 = bitcast void (i8*)* @list_release_i32 to i8*
  %t288 = call i8* @star_rc_alloc(i64 24, i8* %t287)
  %t289 = bitcast i8* %t288 to { i32*, i64, i64 }*
  %t290 = mul i64 %t286, %t267
  %t291 = call i8* @malloc(i64 %t290)
  %t292 = bitcast i8* %t291 to i32*
  %t293 = icmp sgt i64 %t284, 0
  br i1 %t293, label %list_cow_copy_65, label %list_cow_after_copy_66
list_cow_copy_65:
  %t294 = mul i64 %t284, %t267
  %t295 = bitcast i32* %t282 to i8*
  call i8* @memcpy(i8* %t291, i8* %t295, i64 %t294)
  br label %list_cow_after_copy_66
list_cow_after_copy_66:
  %t296 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t289, i32 0, i32 0
  store i32* %t292, i32** %t296
  %t297 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t289, i32 0, i32 1
  store i64 %t284, i64* %t297
  %t298 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t289, i32 0, i32 2
  store i64 %t286, i64* %t298
  call void @star_rc_release(i8* %t268)
  store i8* %t288, i8** %t74
  br label %list_cow_done_63
list_cow_done_63:
  %t299 = load i8*, i8** %t74
  %t300 = bitcast i8* %t299 to { i32*, i64, i64 }*
  %t301 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t300, i32 0, i32 0
  %t302 = load i32*, i32** %t301
  %t303 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t300, i32 0, i32 1
  %t304 = load i64, i64* %t303
  %t305 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t300, i32 0, i32 2
  %t306 = load i32, i32* %t218
  %t307 = sext i32 %t306 to i64
  %t308 = icmp ult i64 %t307, %t304
  br i1 %t308, label %list_set_do_67, label %list_set_oob_68
list_set_do_67:
  %t309 = getelementptr inbounds i32, i32* %t302, i64 %t307
  store i32 %t265, i32* %t309
  br label %list_set_end_69
list_set_oob_68:
  br label %list_set_end_69
list_set_end_69:
  %t310 = load i32, i32* %t218
  %t311 = getelementptr i32, i32* null, i32 1
  %t312 = ptrtoint i32* %t311 to i64
  %t313 = load i8*, i8** %t74
  %t314 = icmp eq i8* %t313, null
  br i1 %t314, label %list_cow_alloc_70, label %list_cow_check_71
list_cow_alloc_70:
  %t315 = bitcast void (i8*)* @list_release_i32 to i8*
  %t316 = call i8* @star_rc_alloc(i64 24, i8* %t315)
  %t317 = bitcast i8* %t316 to { i32*, i64, i64 }*
  %t318 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t317, i32 0, i32 0
  store i32* null, i32** %t318
  %t319 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t317, i32 0, i32 1
  store i64 0, i64* %t319
  %t320 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t317, i32 0, i32 2
  store i64 0, i64* %t320
  store i8* %t316, i8** %t74
  br label %list_cow_done_72
list_cow_check_71:
  %t321 = getelementptr inbounds i8, i8* %t313, i64 -16
  %t322 = bitcast i8* %t321 to i64*
  %t323 = load atomic i64, i64* %t322 seq_cst, align 8
  %t324 = icmp eq i64 %t323, 1
  br i1 %t324, label %list_cow_done_72, label %list_cow_clone_73
list_cow_clone_73:
  %t325 = bitcast i8* %t313 to { i32*, i64, i64 }*
  %t326 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t325, i32 0, i32 0
  %t327 = load i32*, i32** %t326
  %t328 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t325, i32 0, i32 1
  %t329 = load i64, i64* %t328
  %t330 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t325, i32 0, i32 2
  %t331 = load i64, i64* %t330
  %t332 = bitcast void (i8*)* @list_release_i32 to i8*
  %t333 = call i8* @star_rc_alloc(i64 24, i8* %t332)
  %t334 = bitcast i8* %t333 to { i32*, i64, i64 }*
  %t335 = mul i64 %t331, %t312
  %t336 = call i8* @malloc(i64 %t335)
  %t337 = bitcast i8* %t336 to i32*
  %t338 = icmp sgt i64 %t329, 0
  br i1 %t338, label %list_cow_copy_74, label %list_cow_after_copy_75
list_cow_copy_74:
  %t339 = mul i64 %t329, %t312
  %t340 = bitcast i32* %t327 to i8*
  call i8* @memcpy(i8* %t336, i8* %t340, i64 %t339)
  br label %list_cow_after_copy_75
list_cow_after_copy_75:
  %t341 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t334, i32 0, i32 0
  store i32* %t337, i32** %t341
  %t342 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t334, i32 0, i32 1
  store i64 %t329, i64* %t342
  %t343 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t334, i32 0, i32 2
  store i64 %t331, i64* %t343
  call void @star_rc_release(i8* %t313)
  store i8* %t333, i8** %t74
  br label %list_cow_done_72
list_cow_done_72:
  %t344 = load i8*, i8** %t74
  %t345 = bitcast i8* %t344 to { i32*, i64, i64 }*
  %t346 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t345, i32 0, i32 0
  %t347 = load i32*, i32** %t346
  %t348 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t345, i32 0, i32 1
  %t349 = load i64, i64* %t348
  %t350 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t345, i32 0, i32 2
  %t351 = load i32, i32* %t7
  %t352 = sext i32 %t351 to i64
  %t353 = icmp ult i64 %t352, %t349
  br i1 %t353, label %list_set_do_76, label %list_set_oob_77
list_set_do_76:
  %t354 = getelementptr inbounds i32, i32* %t347, i64 %t352
  store i32 %t310, i32* %t354
  br label %list_set_end_78
list_set_oob_77:
  br label %list_set_end_78
list_set_end_78:
  br label %if_end_51
if_else_50:
  br label %if_end_51
if_end_51:
  %t355 = load i32, i32* %t7
  %t356 = add i32 %t355, 1
  store i32 %t356, i32* %t7
  br label %while_cond_28
while_else_30:
  br label %while_end_31
while_end_31:
  store i32 0, i32* %t357
  store i32 0, i32* %t358
  br label %while_cond_79
while_cond_79:
  %t359 = load i32, i32* %t358
  %t360 = load i32, i32* %t2
  %t361 = icmp slt i32 %t359, %t360
  br i1 %t361, label %while_body_80, label %while_else_81
while_body_80:
  %t363 = load i8*, i8** %t0
  %t364 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t364)
  %t365 = load i32, i32* %t358
  %t366 = sext i32 %t365 to i64
  %t367 = icmp eq i8* %t363, null
  br i1 %t367, label %str_idx_oob_85, label %str_idx_chk_83
str_idx_chk_83:
  %t368 = call i32 @strlen(i8* %t363)
  %t369 = sext i32 %t368 to i64
  %t370 = icmp ult i64 %t366, %t369
  br i1 %t370, label %str_idx_ok_84, label %str_idx_oob_85
str_idx_ok_84:
  %t371 = getelementptr inbounds i8, i8* %t363, i64 %t366
  %t372 = load i8, i8* %t371
  %t373 = zext i8 %t372 to i32
  br label %str_idx_end_86
str_idx_oob_85:
  br label %str_idx_end_86
str_idx_end_86:
  %t374 = phi i32 [ %t373, %str_idx_ok_84 ], [ 0, %str_idx_oob_85 ]
  call void @star_rc_release(i8* %t363)
  store i32 %t374, i32* %t362
  %t375 = load i32, i32* %t362
  br label %match_scrutinee_377
match_scrutinee_377:
  %t380 = icmp eq i32 %t375, 43
  br i1 %t380, label %match_then_0_378, label %match_next_0_379
match_then_0_378:
  %t382 = load i8*, i8** %t6
  %t383 = icmp eq i8* %t382, null
  br i1 %t383, label %list_read_null_87, label %list_read_real_88
list_read_null_87:
  br label %list_read_end_89
list_read_real_88:
  %t384 = bitcast i8* %t382 to { i32*, i64, i64 }*
  %t385 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t384, i32 0, i32 0
  %t386 = load i32*, i32** %t385
  %t387 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t384, i32 0, i32 1
  %t388 = load i64, i64* %t387
  br label %list_read_end_89
list_read_end_89:
  %t389 = phi i32* [ null, %list_read_null_87 ], [ %t386, %list_read_real_88 ]
  %t390 = phi i64 [ 0, %list_read_null_87 ], [ %t388, %list_read_real_88 ]
  %t391 = load i32, i32* %t357
  %t392 = sext i32 %t391 to i64
  %t393 = icmp ult i64 %t392, %t390
  br i1 %t393, label %list_idx_ok_90, label %list_idx_oob_91
list_idx_ok_90:
  %t394 = getelementptr inbounds i32, i32* %t389, i64 %t392
  %t395 = load i32, i32* %t394
  br label %list_idx_end_92
list_idx_oob_91:
  br label %list_idx_end_92
list_idx_end_92:
  %t396 = phi i32 [ %t395, %list_idx_ok_90 ], [ 0, %list_idx_oob_91 ]
  %t397 = add i32 %t396, 1
  store i32 %t397, i32* %t381
  %t398 = load i32, i32* %t381
  %t399 = icmp sgt i32 %t398, 255
  br i1 %t399, label %if_then_93, label %if_else_94
if_then_93:
  store i32 0, i32* %t381
  br label %if_end_95
if_else_94:
  br label %if_end_95
if_end_95:
  %t400 = load i32, i32* %t381
  %t401 = getelementptr i32, i32* null, i32 1
  %t402 = ptrtoint i32* %t401 to i64
  %t403 = load i8*, i8** %t6
  %t404 = icmp eq i8* %t403, null
  br i1 %t404, label %list_cow_alloc_96, label %list_cow_check_97
list_cow_alloc_96:
  %t405 = bitcast void (i8*)* @list_release_i32 to i8*
  %t406 = call i8* @star_rc_alloc(i64 24, i8* %t405)
  %t407 = bitcast i8* %t406 to { i32*, i64, i64 }*
  %t408 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t407, i32 0, i32 0
  store i32* null, i32** %t408
  %t409 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t407, i32 0, i32 1
  store i64 0, i64* %t409
  %t410 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t407, i32 0, i32 2
  store i64 0, i64* %t410
  store i8* %t406, i8** %t6
  br label %list_cow_done_98
list_cow_check_97:
  %t411 = getelementptr inbounds i8, i8* %t403, i64 -16
  %t412 = bitcast i8* %t411 to i64*
  %t413 = load atomic i64, i64* %t412 seq_cst, align 8
  %t414 = icmp eq i64 %t413, 1
  br i1 %t414, label %list_cow_done_98, label %list_cow_clone_99
list_cow_clone_99:
  %t415 = bitcast i8* %t403 to { i32*, i64, i64 }*
  %t416 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t415, i32 0, i32 0
  %t417 = load i32*, i32** %t416
  %t418 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t415, i32 0, i32 1
  %t419 = load i64, i64* %t418
  %t420 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t415, i32 0, i32 2
  %t421 = load i64, i64* %t420
  %t422 = bitcast void (i8*)* @list_release_i32 to i8*
  %t423 = call i8* @star_rc_alloc(i64 24, i8* %t422)
  %t424 = bitcast i8* %t423 to { i32*, i64, i64 }*
  %t425 = mul i64 %t421, %t402
  %t426 = call i8* @malloc(i64 %t425)
  %t427 = bitcast i8* %t426 to i32*
  %t428 = icmp sgt i64 %t419, 0
  br i1 %t428, label %list_cow_copy_100, label %list_cow_after_copy_101
list_cow_copy_100:
  %t429 = mul i64 %t419, %t402
  %t430 = bitcast i32* %t417 to i8*
  call i8* @memcpy(i8* %t426, i8* %t430, i64 %t429)
  br label %list_cow_after_copy_101
list_cow_after_copy_101:
  %t431 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t424, i32 0, i32 0
  store i32* %t427, i32** %t431
  %t432 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t424, i32 0, i32 1
  store i64 %t419, i64* %t432
  %t433 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t424, i32 0, i32 2
  store i64 %t421, i64* %t433
  call void @star_rc_release(i8* %t403)
  store i8* %t423, i8** %t6
  br label %list_cow_done_98
list_cow_done_98:
  %t434 = load i8*, i8** %t6
  %t435 = bitcast i8* %t434 to { i32*, i64, i64 }*
  %t436 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t435, i32 0, i32 0
  %t437 = load i32*, i32** %t436
  %t438 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t435, i32 0, i32 1
  %t439 = load i64, i64* %t438
  %t440 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t435, i32 0, i32 2
  %t441 = load i32, i32* %t357
  %t442 = sext i32 %t441 to i64
  %t443 = icmp ult i64 %t442, %t439
  br i1 %t443, label %list_set_do_102, label %list_set_oob_103
list_set_do_102:
  %t444 = getelementptr inbounds i32, i32* %t437, i64 %t442
  store i32 %t400, i32* %t444
  br label %list_set_end_104
list_set_oob_103:
  br label %list_set_end_104
list_set_end_104:
  br label %match_end_376
match_next_0_379:
  %t447 = icmp eq i32 %t375, 45
  br i1 %t447, label %match_then_1_445, label %match_next_1_446
match_then_1_445:
  %t449 = load i8*, i8** %t6
  %t450 = icmp eq i8* %t449, null
  br i1 %t450, label %list_read_null_105, label %list_read_real_106
list_read_null_105:
  br label %list_read_end_107
list_read_real_106:
  %t451 = bitcast i8* %t449 to { i32*, i64, i64 }*
  %t452 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t451, i32 0, i32 0
  %t453 = load i32*, i32** %t452
  %t454 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t451, i32 0, i32 1
  %t455 = load i64, i64* %t454
  br label %list_read_end_107
list_read_end_107:
  %t456 = phi i32* [ null, %list_read_null_105 ], [ %t453, %list_read_real_106 ]
  %t457 = phi i64 [ 0, %list_read_null_105 ], [ %t455, %list_read_real_106 ]
  %t458 = load i32, i32* %t357
  %t459 = sext i32 %t458 to i64
  %t460 = icmp ult i64 %t459, %t457
  br i1 %t460, label %list_idx_ok_108, label %list_idx_oob_109
list_idx_ok_108:
  %t461 = getelementptr inbounds i32, i32* %t456, i64 %t459
  %t462 = load i32, i32* %t461
  br label %list_idx_end_110
list_idx_oob_109:
  br label %list_idx_end_110
list_idx_end_110:
  %t463 = phi i32 [ %t462, %list_idx_ok_108 ], [ 0, %list_idx_oob_109 ]
  %t464 = sub i32 %t463, 1
  store i32 %t464, i32* %t448
  %t465 = load i32, i32* %t448
  %t466 = icmp slt i32 %t465, 0
  br i1 %t466, label %if_then_111, label %if_else_112
if_then_111:
  store i32 255, i32* %t448
  br label %if_end_113
if_else_112:
  br label %if_end_113
if_end_113:
  %t467 = load i32, i32* %t448
  %t468 = getelementptr i32, i32* null, i32 1
  %t469 = ptrtoint i32* %t468 to i64
  %t470 = load i8*, i8** %t6
  %t471 = icmp eq i8* %t470, null
  br i1 %t471, label %list_cow_alloc_114, label %list_cow_check_115
list_cow_alloc_114:
  %t472 = bitcast void (i8*)* @list_release_i32 to i8*
  %t473 = call i8* @star_rc_alloc(i64 24, i8* %t472)
  %t474 = bitcast i8* %t473 to { i32*, i64, i64 }*
  %t475 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t474, i32 0, i32 0
  store i32* null, i32** %t475
  %t476 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t474, i32 0, i32 1
  store i64 0, i64* %t476
  %t477 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t474, i32 0, i32 2
  store i64 0, i64* %t477
  store i8* %t473, i8** %t6
  br label %list_cow_done_116
list_cow_check_115:
  %t478 = getelementptr inbounds i8, i8* %t470, i64 -16
  %t479 = bitcast i8* %t478 to i64*
  %t480 = load atomic i64, i64* %t479 seq_cst, align 8
  %t481 = icmp eq i64 %t480, 1
  br i1 %t481, label %list_cow_done_116, label %list_cow_clone_117
list_cow_clone_117:
  %t482 = bitcast i8* %t470 to { i32*, i64, i64 }*
  %t483 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t482, i32 0, i32 0
  %t484 = load i32*, i32** %t483
  %t485 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t482, i32 0, i32 1
  %t486 = load i64, i64* %t485
  %t487 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t482, i32 0, i32 2
  %t488 = load i64, i64* %t487
  %t489 = bitcast void (i8*)* @list_release_i32 to i8*
  %t490 = call i8* @star_rc_alloc(i64 24, i8* %t489)
  %t491 = bitcast i8* %t490 to { i32*, i64, i64 }*
  %t492 = mul i64 %t488, %t469
  %t493 = call i8* @malloc(i64 %t492)
  %t494 = bitcast i8* %t493 to i32*
  %t495 = icmp sgt i64 %t486, 0
  br i1 %t495, label %list_cow_copy_118, label %list_cow_after_copy_119
list_cow_copy_118:
  %t496 = mul i64 %t486, %t469
  %t497 = bitcast i32* %t484 to i8*
  call i8* @memcpy(i8* %t493, i8* %t497, i64 %t496)
  br label %list_cow_after_copy_119
list_cow_after_copy_119:
  %t498 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t491, i32 0, i32 0
  store i32* %t494, i32** %t498
  %t499 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t491, i32 0, i32 1
  store i64 %t486, i64* %t499
  %t500 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t491, i32 0, i32 2
  store i64 %t488, i64* %t500
  call void @star_rc_release(i8* %t470)
  store i8* %t490, i8** %t6
  br label %list_cow_done_116
list_cow_done_116:
  %t501 = load i8*, i8** %t6
  %t502 = bitcast i8* %t501 to { i32*, i64, i64 }*
  %t503 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t502, i32 0, i32 0
  %t504 = load i32*, i32** %t503
  %t505 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t502, i32 0, i32 1
  %t506 = load i64, i64* %t505
  %t507 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t502, i32 0, i32 2
  %t508 = load i32, i32* %t357
  %t509 = sext i32 %t508 to i64
  %t510 = icmp ult i64 %t509, %t506
  br i1 %t510, label %list_set_do_120, label %list_set_oob_121
list_set_do_120:
  %t511 = getelementptr inbounds i32, i32* %t504, i64 %t509
  store i32 %t467, i32* %t511
  br label %list_set_end_122
list_set_oob_121:
  br label %list_set_end_122
list_set_end_122:
  br label %match_end_376
match_next_1_446:
  %t514 = icmp eq i32 %t375, 62
  br i1 %t514, label %match_then_2_512, label %match_next_2_513
match_then_2_512:
  %t515 = load i32, i32* %t357
  %t516 = add i32 %t515, 1
  store i32 %t516, i32* %t357
  br label %match_end_376
match_next_2_513:
  %t519 = icmp eq i32 %t375, 60
  br i1 %t519, label %match_then_3_517, label %match_next_3_518
match_then_3_517:
  %t520 = load i32, i32* %t357
  %t521 = sub i32 %t520, 1
  store i32 %t521, i32* %t357
  br label %match_end_376
match_next_3_518:
  %t524 = icmp eq i32 %t375, 46
  br i1 %t524, label %match_then_4_522, label %match_next_4_523
match_then_4_522:
  %t525 = load i8*, i8** %t6
  %t526 = icmp eq i8* %t525, null
  br i1 %t526, label %list_read_null_123, label %list_read_real_124
list_read_null_123:
  br label %list_read_end_125
list_read_real_124:
  %t527 = bitcast i8* %t525 to { i32*, i64, i64 }*
  %t528 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t527, i32 0, i32 0
  %t529 = load i32*, i32** %t528
  %t530 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t527, i32 0, i32 1
  %t531 = load i64, i64* %t530
  br label %list_read_end_125
list_read_end_125:
  %t532 = phi i32* [ null, %list_read_null_123 ], [ %t529, %list_read_real_124 ]
  %t533 = phi i64 [ 0, %list_read_null_123 ], [ %t531, %list_read_real_124 ]
  %t534 = load i32, i32* %t357
  %t535 = sext i32 %t534 to i64
  %t536 = icmp ult i64 %t535, %t533
  br i1 %t536, label %list_idx_ok_126, label %list_idx_oob_127
list_idx_ok_126:
  %t537 = getelementptr inbounds i32, i32* %t532, i64 %t535
  %t538 = load i32, i32* %t537
  br label %list_idx_end_128
list_idx_oob_127:
  br label %list_idx_end_128
list_idx_end_128:
  %t539 = phi i32 [ %t538, %list_idx_ok_126 ], [ 0, %list_idx_oob_127 ]
  %t540 = call i32 @putchar(i32 %t539)
  br label %match_end_376
match_next_4_523:
  %t543 = icmp eq i32 %t375, 44
  br i1 %t543, label %match_then_5_541, label %match_next_5_542
match_then_5_541:
  %t544 = getelementptr i32, i32* null, i32 1
  %t545 = ptrtoint i32* %t544 to i64
  %t546 = load i8*, i8** %t6
  %t547 = icmp eq i8* %t546, null
  br i1 %t547, label %list_cow_alloc_129, label %list_cow_check_130
list_cow_alloc_129:
  %t548 = bitcast void (i8*)* @list_release_i32 to i8*
  %t549 = call i8* @star_rc_alloc(i64 24, i8* %t548)
  %t550 = bitcast i8* %t549 to { i32*, i64, i64 }*
  %t551 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t550, i32 0, i32 0
  store i32* null, i32** %t551
  %t552 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t550, i32 0, i32 1
  store i64 0, i64* %t552
  %t553 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t550, i32 0, i32 2
  store i64 0, i64* %t553
  store i8* %t549, i8** %t6
  br label %list_cow_done_131
list_cow_check_130:
  %t554 = getelementptr inbounds i8, i8* %t546, i64 -16
  %t555 = bitcast i8* %t554 to i64*
  %t556 = load atomic i64, i64* %t555 seq_cst, align 8
  %t557 = icmp eq i64 %t556, 1
  br i1 %t557, label %list_cow_done_131, label %list_cow_clone_132
list_cow_clone_132:
  %t558 = bitcast i8* %t546 to { i32*, i64, i64 }*
  %t559 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t558, i32 0, i32 0
  %t560 = load i32*, i32** %t559
  %t561 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t558, i32 0, i32 1
  %t562 = load i64, i64* %t561
  %t563 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t558, i32 0, i32 2
  %t564 = load i64, i64* %t563
  %t565 = bitcast void (i8*)* @list_release_i32 to i8*
  %t566 = call i8* @star_rc_alloc(i64 24, i8* %t565)
  %t567 = bitcast i8* %t566 to { i32*, i64, i64 }*
  %t568 = mul i64 %t564, %t545
  %t569 = call i8* @malloc(i64 %t568)
  %t570 = bitcast i8* %t569 to i32*
  %t571 = icmp sgt i64 %t562, 0
  br i1 %t571, label %list_cow_copy_133, label %list_cow_after_copy_134
list_cow_copy_133:
  %t572 = mul i64 %t562, %t545
  %t573 = bitcast i32* %t560 to i8*
  call i8* @memcpy(i8* %t569, i8* %t573, i64 %t572)
  br label %list_cow_after_copy_134
list_cow_after_copy_134:
  %t574 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t567, i32 0, i32 0
  store i32* %t570, i32** %t574
  %t575 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t567, i32 0, i32 1
  store i64 %t562, i64* %t575
  %t576 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t567, i32 0, i32 2
  store i64 %t564, i64* %t576
  call void @star_rc_release(i8* %t546)
  store i8* %t566, i8** %t6
  br label %list_cow_done_131
list_cow_done_131:
  %t577 = load i8*, i8** %t6
  %t578 = bitcast i8* %t577 to { i32*, i64, i64 }*
  %t579 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t578, i32 0, i32 0
  %t580 = load i32*, i32** %t579
  %t581 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t578, i32 0, i32 1
  %t582 = load i64, i64* %t581
  %t583 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t578, i32 0, i32 2
  %t584 = load i32, i32* %t357
  %t585 = sext i32 %t584 to i64
  %t586 = icmp ult i64 %t585, %t582
  br i1 %t586, label %list_set_do_135, label %list_set_oob_136
list_set_do_135:
  %t587 = getelementptr inbounds i32, i32* %t580, i64 %t585
  store i32 0, i32* %t587
  br label %list_set_end_137
list_set_oob_136:
  br label %list_set_end_137
list_set_end_137:
  br label %match_end_376
match_next_5_542:
  %t590 = icmp eq i32 %t375, 91
  br i1 %t590, label %match_then_6_588, label %match_next_6_589
match_then_6_588:
  %t591 = load i8*, i8** %t6
  %t592 = icmp eq i8* %t591, null
  br i1 %t592, label %list_read_null_138, label %list_read_real_139
list_read_null_138:
  br label %list_read_end_140
list_read_real_139:
  %t593 = bitcast i8* %t591 to { i32*, i64, i64 }*
  %t594 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t593, i32 0, i32 0
  %t595 = load i32*, i32** %t594
  %t596 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t593, i32 0, i32 1
  %t597 = load i64, i64* %t596
  br label %list_read_end_140
list_read_end_140:
  %t598 = phi i32* [ null, %list_read_null_138 ], [ %t595, %list_read_real_139 ]
  %t599 = phi i64 [ 0, %list_read_null_138 ], [ %t597, %list_read_real_139 ]
  %t600 = load i32, i32* %t357
  %t601 = sext i32 %t600 to i64
  %t602 = icmp ult i64 %t601, %t599
  br i1 %t602, label %list_idx_ok_141, label %list_idx_oob_142
list_idx_ok_141:
  %t603 = getelementptr inbounds i32, i32* %t598, i64 %t601
  %t604 = load i32, i32* %t603
  br label %list_idx_end_143
list_idx_oob_142:
  br label %list_idx_end_143
list_idx_end_143:
  %t605 = phi i32 [ %t604, %list_idx_ok_141 ], [ 0, %list_idx_oob_142 ]
  %t606 = icmp eq i32 %t605, 0
  br i1 %t606, label %if_then_144, label %if_else_145
if_then_144:
  %t607 = load i8*, i8** %t74
  %t608 = icmp eq i8* %t607, null
  br i1 %t608, label %list_read_null_147, label %list_read_real_148
list_read_null_147:
  br label %list_read_end_149
list_read_real_148:
  %t609 = bitcast i8* %t607 to { i32*, i64, i64 }*
  %t610 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t609, i32 0, i32 0
  %t611 = load i32*, i32** %t610
  %t612 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t609, i32 0, i32 1
  %t613 = load i64, i64* %t612
  br label %list_read_end_149
list_read_end_149:
  %t614 = phi i32* [ null, %list_read_null_147 ], [ %t611, %list_read_real_148 ]
  %t615 = phi i64 [ 0, %list_read_null_147 ], [ %t613, %list_read_real_148 ]
  %t616 = load i32, i32* %t358
  %t617 = sext i32 %t616 to i64
  %t618 = icmp ult i64 %t617, %t615
  br i1 %t618, label %list_idx_ok_150, label %list_idx_oob_151
list_idx_ok_150:
  %t619 = getelementptr inbounds i32, i32* %t614, i64 %t617
  %t620 = load i32, i32* %t619
  br label %list_idx_end_152
list_idx_oob_151:
  br label %list_idx_end_152
list_idx_end_152:
  %t621 = phi i32 [ %t620, %list_idx_ok_150 ], [ 0, %list_idx_oob_151 ]
  store i32 %t621, i32* %t358
  br label %if_end_146
if_else_145:
  br label %if_end_146
if_end_146:
  br label %match_end_376
match_next_6_589:
  %t624 = icmp eq i32 %t375, 93
  br i1 %t624, label %match_then_7_622, label %match_next_7_623
match_then_7_622:
  %t625 = load i8*, i8** %t6
  %t626 = icmp eq i8* %t625, null
  br i1 %t626, label %list_read_null_153, label %list_read_real_154
list_read_null_153:
  br label %list_read_end_155
list_read_real_154:
  %t627 = bitcast i8* %t625 to { i32*, i64, i64 }*
  %t628 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t627, i32 0, i32 0
  %t629 = load i32*, i32** %t628
  %t630 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t627, i32 0, i32 1
  %t631 = load i64, i64* %t630
  br label %list_read_end_155
list_read_end_155:
  %t632 = phi i32* [ null, %list_read_null_153 ], [ %t629, %list_read_real_154 ]
  %t633 = phi i64 [ 0, %list_read_null_153 ], [ %t631, %list_read_real_154 ]
  %t634 = load i32, i32* %t357
  %t635 = sext i32 %t634 to i64
  %t636 = icmp ult i64 %t635, %t633
  br i1 %t636, label %list_idx_ok_156, label %list_idx_oob_157
list_idx_ok_156:
  %t637 = getelementptr inbounds i32, i32* %t632, i64 %t635
  %t638 = load i32, i32* %t637
  br label %list_idx_end_158
list_idx_oob_157:
  br label %list_idx_end_158
list_idx_end_158:
  %t639 = phi i32 [ %t638, %list_idx_ok_156 ], [ 0, %list_idx_oob_157 ]
  %t640 = icmp ne i32 %t639, 0
  br i1 %t640, label %if_then_159, label %if_else_160
if_then_159:
  %t641 = load i8*, i8** %t74
  %t642 = icmp eq i8* %t641, null
  br i1 %t642, label %list_read_null_162, label %list_read_real_163
list_read_null_162:
  br label %list_read_end_164
list_read_real_163:
  %t643 = bitcast i8* %t641 to { i32*, i64, i64 }*
  %t644 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t643, i32 0, i32 0
  %t645 = load i32*, i32** %t644
  %t646 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t643, i32 0, i32 1
  %t647 = load i64, i64* %t646
  br label %list_read_end_164
list_read_end_164:
  %t648 = phi i32* [ null, %list_read_null_162 ], [ %t645, %list_read_real_163 ]
  %t649 = phi i64 [ 0, %list_read_null_162 ], [ %t647, %list_read_real_163 ]
  %t650 = load i32, i32* %t358
  %t651 = sext i32 %t650 to i64
  %t652 = icmp ult i64 %t651, %t649
  br i1 %t652, label %list_idx_ok_165, label %list_idx_oob_166
list_idx_ok_165:
  %t653 = getelementptr inbounds i32, i32* %t648, i64 %t651
  %t654 = load i32, i32* %t653
  br label %list_idx_end_167
list_idx_oob_166:
  br label %list_idx_end_167
list_idx_end_167:
  %t655 = phi i32 [ %t654, %list_idx_ok_165 ], [ 0, %list_idx_oob_166 ]
  store i32 %t655, i32* %t358
  br label %if_end_161
if_else_160:
  br label %if_end_161
if_end_161:
  br label %match_end_376
match_next_7_623:
  br label %match_end_376
match_end_376:
  %t658 = phi i32 [ undef, %list_set_end_104 ], [ undef, %list_set_end_122 ], [ undef, %match_then_2_512 ], [ undef, %match_then_3_517 ], [ %t540, %list_idx_end_128 ], [ undef, %list_set_end_137 ], [ undef, %if_end_146 ], [ undef, %if_end_161 ], [ 0, %match_next_7_623 ]
  %t659 = load i32, i32* %t358
  %t660 = add i32 %t659, 1
  store i32 %t660, i32* %t358
  br label %while_cond_79
while_else_81:
  br label %while_end_82
while_end_82:
  %t661 = load i8*, i8** %t138
  call void @star_rc_release(i8* %t661)
  %t662 = load i8*, i8** %t74
  call void @star_rc_release(i8* %t662)
  %t663 = load i8*, i8** %t6
  call void @star_rc_release(i8* %t663)
  %t664 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t664)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_i32(i8* %objp) {
entry:
  %t14 = bitcast i8* %objp to { i32*, i64, i64 }*
  %t15 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t14, i32 0, i32 0
  %t16 = load i32*, i32** %t15
  %t17 = bitcast i32* %t16 to i8*
  call void @free(i8* %t17)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [107 x i8] } { i64 -1, i8* null, [107 x i8] c"++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.\00" }
