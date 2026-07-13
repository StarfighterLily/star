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

declare i32 @putchar(i32)
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = alloca i8*
  %t1 = getelementptr inbounds { i64, i8*, [107 x i8] }, { i64, i8*, [107 x i8] }* @.str.0, i64 0, i32 2, i64 0
  store i8* %t1, i8** %t0
  %t2 = alloca i32
  %t3 = load i8*, i8** %t0
  %t4 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t4)
  call void @star_rc_release(i8* %t3)
  %t5 = call i32 @strlen(i8* %t3)
  store i32 %t5, i32* %t2
  %t6 = alloca i8*
  store i8* null, i8** %t6
  %t7 = alloca i32
  store i32 0, i32* %t7
  br label %while_cond_0
while_cond_0:
  %t8 = load i32, i32* %t7
  %t9 = icmp slt i32 %t8, 30000
  br i1 %t9, label %while_body_1, label %while_end_3
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
  %t56 = icmp sge i64 %t52, %t54
  br i1 %t56, label %list_push_grow_10, label %list_push_store_11
list_push_grow_10:
  %t57 = mul i64 %t54, 2
  %t58 = icmp sgt i64 %t57, 0
  %t59 = select i1 %t58, i64 %t57, i64 1
  %t60 = getelementptr i32, i32* null, i32 1
  %t61 = ptrtoint i32* %t60 to i64
  %t62 = mul i64 %t59, %t61
  %t63 = call i8* @malloc(i64 %t62)
  %t64 = bitcast i8* %t63 to i32*
  %t65 = icmp sgt i64 %t54, 0
  br i1 %t65, label %list_push_copy_12, label %list_push_after_copy_13
list_push_copy_12:
  %t66 = mul i64 %t52, %t61
  %t67 = bitcast i32* %t55 to i8*
  call i8* @memcpy(i8* %t63, i8* %t67, i64 %t66)
  call void @free(i8* %t67)
  br label %list_push_after_copy_13
list_push_after_copy_13:
  store i32* %t64, i32** %t49
  store i64 %t59, i64* %t53
  br label %list_push_store_11
list_push_store_11:
  %t68 = load i32*, i32** %t49
  %t69 = getelementptr inbounds i32, i32* %t68, i64 %t52
  store i32 0, i32* %t69
  %t70 = add i64 %t52, 1
  store i64 %t70, i64* %t51
  %t71 = load i32, i32* %t7
  %t72 = add i32 %t71, 1
  store i32 %t72, i32* %t7
  br label %while_cond_0
while_else_2:
  br label %while_end_3
while_end_3:
  %t73 = alloca i8*
  store i8* null, i8** %t73
  store i32 0, i32* %t7
  br label %while_cond_14
while_cond_14:
  %t74 = load i32, i32* %t7
  %t75 = load i32, i32* %t2
  %t76 = icmp slt i32 %t74, %t75
  br i1 %t76, label %while_body_15, label %while_end_17
while_body_15:
  %t77 = getelementptr i32, i32* null, i32 1
  %t78 = ptrtoint i32* %t77 to i64
  %t79 = load i8*, i8** %t73
  %t80 = icmp eq i8* %t79, null
  br i1 %t80, label %list_cow_alloc_18, label %list_cow_check_19
list_cow_alloc_18:
  %t81 = bitcast void (i8*)* @list_release_i32 to i8*
  %t82 = call i8* @star_rc_alloc(i64 24, i8* %t81)
  %t83 = bitcast i8* %t82 to { i32*, i64, i64 }*
  %t84 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t83, i32 0, i32 0
  store i32* null, i32** %t84
  %t85 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t83, i32 0, i32 1
  store i64 0, i64* %t85
  %t86 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t83, i32 0, i32 2
  store i64 0, i64* %t86
  store i8* %t82, i8** %t73
  br label %list_cow_done_20
list_cow_check_19:
  %t87 = getelementptr inbounds i8, i8* %t79, i64 -16
  %t88 = bitcast i8* %t87 to i64*
  %t89 = load atomic i64, i64* %t88 seq_cst, align 8
  %t90 = icmp eq i64 %t89, 1
  br i1 %t90, label %list_cow_done_20, label %list_cow_clone_21
list_cow_clone_21:
  %t91 = bitcast i8* %t79 to { i32*, i64, i64 }*
  %t92 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t91, i32 0, i32 0
  %t93 = load i32*, i32** %t92
  %t94 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t91, i32 0, i32 1
  %t95 = load i64, i64* %t94
  %t96 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t91, i32 0, i32 2
  %t97 = load i64, i64* %t96
  %t98 = bitcast void (i8*)* @list_release_i32 to i8*
  %t99 = call i8* @star_rc_alloc(i64 24, i8* %t98)
  %t100 = bitcast i8* %t99 to { i32*, i64, i64 }*
  %t101 = mul i64 %t97, %t78
  %t102 = call i8* @malloc(i64 %t101)
  %t103 = bitcast i8* %t102 to i32*
  %t104 = icmp sgt i64 %t95, 0
  br i1 %t104, label %list_cow_copy_22, label %list_cow_after_copy_23
list_cow_copy_22:
  %t105 = mul i64 %t95, %t78
  %t106 = bitcast i32* %t93 to i8*
  call i8* @memcpy(i8* %t102, i8* %t106, i64 %t105)
  br label %list_cow_after_copy_23
list_cow_after_copy_23:
  %t107 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t100, i32 0, i32 0
  store i32* %t103, i32** %t107
  %t108 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t100, i32 0, i32 1
  store i64 %t95, i64* %t108
  %t109 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t100, i32 0, i32 2
  store i64 %t97, i64* %t109
  call void @star_rc_release(i8* %t79)
  store i8* %t99, i8** %t73
  br label %list_cow_done_20
list_cow_done_20:
  %t110 = load i8*, i8** %t73
  %t111 = bitcast i8* %t110 to { i32*, i64, i64 }*
  %t112 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t111, i32 0, i32 0
  %t113 = load i32*, i32** %t112
  %t114 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t111, i32 0, i32 1
  %t115 = load i64, i64* %t114
  %t116 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t111, i32 0, i32 2
  %t117 = load i64, i64* %t116
  %t118 = load i32*, i32** %t112
  %t119 = icmp sge i64 %t115, %t117
  br i1 %t119, label %list_push_grow_24, label %list_push_store_25
list_push_grow_24:
  %t120 = mul i64 %t117, 2
  %t121 = icmp sgt i64 %t120, 0
  %t122 = select i1 %t121, i64 %t120, i64 1
  %t123 = getelementptr i32, i32* null, i32 1
  %t124 = ptrtoint i32* %t123 to i64
  %t125 = mul i64 %t122, %t124
  %t126 = call i8* @malloc(i64 %t125)
  %t127 = bitcast i8* %t126 to i32*
  %t128 = icmp sgt i64 %t117, 0
  br i1 %t128, label %list_push_copy_26, label %list_push_after_copy_27
list_push_copy_26:
  %t129 = mul i64 %t115, %t124
  %t130 = bitcast i32* %t118 to i8*
  call i8* @memcpy(i8* %t126, i8* %t130, i64 %t129)
  call void @free(i8* %t130)
  br label %list_push_after_copy_27
list_push_after_copy_27:
  store i32* %t127, i32** %t112
  store i64 %t122, i64* %t116
  br label %list_push_store_25
list_push_store_25:
  %t131 = load i32*, i32** %t112
  %t132 = getelementptr inbounds i32, i32* %t131, i64 %t115
  store i32 0, i32* %t132
  %t133 = add i64 %t115, 1
  store i64 %t133, i64* %t114
  %t134 = load i32, i32* %t7
  %t135 = add i32 %t134, 1
  store i32 %t135, i32* %t7
  br label %while_cond_14
while_else_16:
  br label %while_end_17
while_end_17:
  %t136 = alloca i8*
  store i8* null, i8** %t136
  store i32 0, i32* %t7
  br label %while_cond_28
while_cond_28:
  %t137 = load i32, i32* %t7
  %t138 = load i32, i32* %t2
  %t139 = icmp slt i32 %t137, %t138
  br i1 %t139, label %while_body_29, label %while_end_31
while_body_29:
  %t140 = alloca i32
  %t141 = load i8*, i8** %t0
  %t142 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t142)
  call void @star_rc_release(i8* %t141)
  %t143 = load i32, i32* %t7
  %t144 = sext i32 %t143 to i64
  %t145 = icmp eq i8* %t141, null
  br i1 %t145, label %str_idx_oob_34, label %str_idx_chk_32
str_idx_chk_32:
  %t146 = call i32 @strlen(i8* %t141)
  %t147 = sext i32 %t146 to i64
  %t148 = icmp ult i64 %t144, %t147
  br i1 %t148, label %str_idx_ok_33, label %str_idx_oob_34
str_idx_ok_33:
  %t149 = getelementptr inbounds i8, i8* %t141, i64 %t144
  %t150 = load i8, i8* %t149
  %t151 = zext i8 %t150 to i32
  br label %str_idx_end_35
str_idx_oob_34:
  br label %str_idx_end_35
str_idx_end_35:
  %t152 = phi i32 [ %t151, %str_idx_ok_33 ], [ 0, %str_idx_oob_34 ]
  store i32 %t152, i32* %t140
  %t153 = load i32, i32* %t140
  %t154 = icmp eq i32 %t153, 91
  br i1 %t154, label %if_then_36, label %if_else_37
if_then_36:
  %t155 = getelementptr i32, i32* null, i32 1
  %t156 = ptrtoint i32* %t155 to i64
  %t157 = load i8*, i8** %t136
  %t158 = icmp eq i8* %t157, null
  br i1 %t158, label %list_cow_alloc_39, label %list_cow_check_40
list_cow_alloc_39:
  %t159 = bitcast void (i8*)* @list_release_i32 to i8*
  %t160 = call i8* @star_rc_alloc(i64 24, i8* %t159)
  %t161 = bitcast i8* %t160 to { i32*, i64, i64 }*
  %t162 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t161, i32 0, i32 0
  store i32* null, i32** %t162
  %t163 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t161, i32 0, i32 1
  store i64 0, i64* %t163
  %t164 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t161, i32 0, i32 2
  store i64 0, i64* %t164
  store i8* %t160, i8** %t136
  br label %list_cow_done_41
list_cow_check_40:
  %t165 = getelementptr inbounds i8, i8* %t157, i64 -16
  %t166 = bitcast i8* %t165 to i64*
  %t167 = load atomic i64, i64* %t166 seq_cst, align 8
  %t168 = icmp eq i64 %t167, 1
  br i1 %t168, label %list_cow_done_41, label %list_cow_clone_42
list_cow_clone_42:
  %t169 = bitcast i8* %t157 to { i32*, i64, i64 }*
  %t170 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t169, i32 0, i32 0
  %t171 = load i32*, i32** %t170
  %t172 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t169, i32 0, i32 1
  %t173 = load i64, i64* %t172
  %t174 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t169, i32 0, i32 2
  %t175 = load i64, i64* %t174
  %t176 = bitcast void (i8*)* @list_release_i32 to i8*
  %t177 = call i8* @star_rc_alloc(i64 24, i8* %t176)
  %t178 = bitcast i8* %t177 to { i32*, i64, i64 }*
  %t179 = mul i64 %t175, %t156
  %t180 = call i8* @malloc(i64 %t179)
  %t181 = bitcast i8* %t180 to i32*
  %t182 = icmp sgt i64 %t173, 0
  br i1 %t182, label %list_cow_copy_43, label %list_cow_after_copy_44
list_cow_copy_43:
  %t183 = mul i64 %t173, %t156
  %t184 = bitcast i32* %t171 to i8*
  call i8* @memcpy(i8* %t180, i8* %t184, i64 %t183)
  br label %list_cow_after_copy_44
list_cow_after_copy_44:
  %t185 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t178, i32 0, i32 0
  store i32* %t181, i32** %t185
  %t186 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t178, i32 0, i32 1
  store i64 %t173, i64* %t186
  %t187 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t178, i32 0, i32 2
  store i64 %t175, i64* %t187
  call void @star_rc_release(i8* %t157)
  store i8* %t177, i8** %t136
  br label %list_cow_done_41
list_cow_done_41:
  %t188 = load i8*, i8** %t136
  %t189 = bitcast i8* %t188 to { i32*, i64, i64 }*
  %t190 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t189, i32 0, i32 0
  %t191 = load i32*, i32** %t190
  %t192 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t189, i32 0, i32 1
  %t193 = load i64, i64* %t192
  %t194 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t189, i32 0, i32 2
  %t195 = load i32, i32* %t7
  %t196 = load i64, i64* %t194
  %t197 = load i32*, i32** %t190
  %t198 = icmp sge i64 %t193, %t196
  br i1 %t198, label %list_push_grow_45, label %list_push_store_46
list_push_grow_45:
  %t199 = mul i64 %t196, 2
  %t200 = icmp sgt i64 %t199, 0
  %t201 = select i1 %t200, i64 %t199, i64 1
  %t202 = getelementptr i32, i32* null, i32 1
  %t203 = ptrtoint i32* %t202 to i64
  %t204 = mul i64 %t201, %t203
  %t205 = call i8* @malloc(i64 %t204)
  %t206 = bitcast i8* %t205 to i32*
  %t207 = icmp sgt i64 %t196, 0
  br i1 %t207, label %list_push_copy_47, label %list_push_after_copy_48
list_push_copy_47:
  %t208 = mul i64 %t193, %t203
  %t209 = bitcast i32* %t197 to i8*
  call i8* @memcpy(i8* %t205, i8* %t209, i64 %t208)
  call void @free(i8* %t209)
  br label %list_push_after_copy_48
list_push_after_copy_48:
  store i32* %t206, i32** %t190
  store i64 %t201, i64* %t194
  br label %list_push_store_46
list_push_store_46:
  %t210 = load i32*, i32** %t190
  %t211 = getelementptr inbounds i32, i32* %t210, i64 %t193
  store i32 %t195, i32* %t211
  %t212 = add i64 %t193, 1
  store i64 %t212, i64* %t192
  br label %if_end_38
if_else_37:
  br label %if_end_38
if_end_38:
  %t213 = load i32, i32* %t140
  %t214 = icmp eq i32 %t213, 93
  br i1 %t214, label %if_then_49, label %if_else_50
if_then_49:
  %t215 = alloca i32
  %t216 = getelementptr i32, i32* null, i32 1
  %t217 = ptrtoint i32* %t216 to i64
  %t218 = load i8*, i8** %t136
  %t219 = icmp eq i8* %t218, null
  br i1 %t219, label %list_cow_alloc_52, label %list_cow_check_53
list_cow_alloc_52:
  %t220 = bitcast void (i8*)* @list_release_i32 to i8*
  %t221 = call i8* @star_rc_alloc(i64 24, i8* %t220)
  %t222 = bitcast i8* %t221 to { i32*, i64, i64 }*
  %t223 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t222, i32 0, i32 0
  store i32* null, i32** %t223
  %t224 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t222, i32 0, i32 1
  store i64 0, i64* %t224
  %t225 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t222, i32 0, i32 2
  store i64 0, i64* %t225
  store i8* %t221, i8** %t136
  br label %list_cow_done_54
list_cow_check_53:
  %t226 = getelementptr inbounds i8, i8* %t218, i64 -16
  %t227 = bitcast i8* %t226 to i64*
  %t228 = load atomic i64, i64* %t227 seq_cst, align 8
  %t229 = icmp eq i64 %t228, 1
  br i1 %t229, label %list_cow_done_54, label %list_cow_clone_55
list_cow_clone_55:
  %t230 = bitcast i8* %t218 to { i32*, i64, i64 }*
  %t231 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t230, i32 0, i32 0
  %t232 = load i32*, i32** %t231
  %t233 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t230, i32 0, i32 1
  %t234 = load i64, i64* %t233
  %t235 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t230, i32 0, i32 2
  %t236 = load i64, i64* %t235
  %t237 = bitcast void (i8*)* @list_release_i32 to i8*
  %t238 = call i8* @star_rc_alloc(i64 24, i8* %t237)
  %t239 = bitcast i8* %t238 to { i32*, i64, i64 }*
  %t240 = mul i64 %t236, %t217
  %t241 = call i8* @malloc(i64 %t240)
  %t242 = bitcast i8* %t241 to i32*
  %t243 = icmp sgt i64 %t234, 0
  br i1 %t243, label %list_cow_copy_56, label %list_cow_after_copy_57
list_cow_copy_56:
  %t244 = mul i64 %t234, %t217
  %t245 = bitcast i32* %t232 to i8*
  call i8* @memcpy(i8* %t241, i8* %t245, i64 %t244)
  br label %list_cow_after_copy_57
list_cow_after_copy_57:
  %t246 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t239, i32 0, i32 0
  store i32* %t242, i32** %t246
  %t247 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t239, i32 0, i32 1
  store i64 %t234, i64* %t247
  %t248 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t239, i32 0, i32 2
  store i64 %t236, i64* %t248
  call void @star_rc_release(i8* %t218)
  store i8* %t238, i8** %t136
  br label %list_cow_done_54
list_cow_done_54:
  %t249 = load i8*, i8** %t136
  %t250 = bitcast i8* %t249 to { i32*, i64, i64 }*
  %t251 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t250, i32 0, i32 0
  %t252 = load i32*, i32** %t251
  %t253 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t250, i32 0, i32 1
  %t254 = load i64, i64* %t253
  %t255 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t250, i32 0, i32 2
  %t256 = icmp eq i64 %t254, 0
  br i1 %t256, label %list_pop_empty_58, label %list_pop_nonempty_59
list_pop_nonempty_59:
  %t257 = sub i64 %t254, 1
  store i64 %t257, i64* %t253
  %t258 = load i32*, i32** %t251
  %t259 = getelementptr inbounds i32, i32* %t258, i64 %t257
  %t260 = load i32, i32* %t259
  br label %list_pop_end_60
list_pop_empty_58:
  br label %list_pop_end_60
list_pop_end_60:
  %t261 = phi i32 [ %t260, %list_pop_nonempty_59 ], [ 0, %list_pop_empty_58 ]
  store i32 %t261, i32* %t215
  %t262 = load i32, i32* %t7
  %t263 = getelementptr i32, i32* null, i32 1
  %t264 = ptrtoint i32* %t263 to i64
  %t265 = load i8*, i8** %t73
  %t266 = icmp eq i8* %t265, null
  br i1 %t266, label %list_cow_alloc_61, label %list_cow_check_62
list_cow_alloc_61:
  %t267 = bitcast void (i8*)* @list_release_i32 to i8*
  %t268 = call i8* @star_rc_alloc(i64 24, i8* %t267)
  %t269 = bitcast i8* %t268 to { i32*, i64, i64 }*
  %t270 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t269, i32 0, i32 0
  store i32* null, i32** %t270
  %t271 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t269, i32 0, i32 1
  store i64 0, i64* %t271
  %t272 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t269, i32 0, i32 2
  store i64 0, i64* %t272
  store i8* %t268, i8** %t73
  br label %list_cow_done_63
list_cow_check_62:
  %t273 = getelementptr inbounds i8, i8* %t265, i64 -16
  %t274 = bitcast i8* %t273 to i64*
  %t275 = load atomic i64, i64* %t274 seq_cst, align 8
  %t276 = icmp eq i64 %t275, 1
  br i1 %t276, label %list_cow_done_63, label %list_cow_clone_64
list_cow_clone_64:
  %t277 = bitcast i8* %t265 to { i32*, i64, i64 }*
  %t278 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t277, i32 0, i32 0
  %t279 = load i32*, i32** %t278
  %t280 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t277, i32 0, i32 1
  %t281 = load i64, i64* %t280
  %t282 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t277, i32 0, i32 2
  %t283 = load i64, i64* %t282
  %t284 = bitcast void (i8*)* @list_release_i32 to i8*
  %t285 = call i8* @star_rc_alloc(i64 24, i8* %t284)
  %t286 = bitcast i8* %t285 to { i32*, i64, i64 }*
  %t287 = mul i64 %t283, %t264
  %t288 = call i8* @malloc(i64 %t287)
  %t289 = bitcast i8* %t288 to i32*
  %t290 = icmp sgt i64 %t281, 0
  br i1 %t290, label %list_cow_copy_65, label %list_cow_after_copy_66
list_cow_copy_65:
  %t291 = mul i64 %t281, %t264
  %t292 = bitcast i32* %t279 to i8*
  call i8* @memcpy(i8* %t288, i8* %t292, i64 %t291)
  br label %list_cow_after_copy_66
list_cow_after_copy_66:
  %t293 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t286, i32 0, i32 0
  store i32* %t289, i32** %t293
  %t294 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t286, i32 0, i32 1
  store i64 %t281, i64* %t294
  %t295 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t286, i32 0, i32 2
  store i64 %t283, i64* %t295
  call void @star_rc_release(i8* %t265)
  store i8* %t285, i8** %t73
  br label %list_cow_done_63
list_cow_done_63:
  %t296 = load i8*, i8** %t73
  %t297 = bitcast i8* %t296 to { i32*, i64, i64 }*
  %t298 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t297, i32 0, i32 0
  %t299 = load i32*, i32** %t298
  %t300 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t297, i32 0, i32 1
  %t301 = load i64, i64* %t300
  %t302 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t297, i32 0, i32 2
  %t303 = load i32, i32* %t215
  %t304 = sext i32 %t303 to i64
  %t305 = icmp ult i64 %t304, %t301
  br i1 %t305, label %list_set_do_67, label %list_set_end_68
list_set_do_67:
  %t306 = getelementptr inbounds i32, i32* %t299, i64 %t304
  store i32 %t262, i32* %t306
  br label %list_set_end_68
list_set_end_68:
  %t307 = load i32, i32* %t215
  %t308 = getelementptr i32, i32* null, i32 1
  %t309 = ptrtoint i32* %t308 to i64
  %t310 = load i8*, i8** %t73
  %t311 = icmp eq i8* %t310, null
  br i1 %t311, label %list_cow_alloc_69, label %list_cow_check_70
list_cow_alloc_69:
  %t312 = bitcast void (i8*)* @list_release_i32 to i8*
  %t313 = call i8* @star_rc_alloc(i64 24, i8* %t312)
  %t314 = bitcast i8* %t313 to { i32*, i64, i64 }*
  %t315 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t314, i32 0, i32 0
  store i32* null, i32** %t315
  %t316 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t314, i32 0, i32 1
  store i64 0, i64* %t316
  %t317 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t314, i32 0, i32 2
  store i64 0, i64* %t317
  store i8* %t313, i8** %t73
  br label %list_cow_done_71
list_cow_check_70:
  %t318 = getelementptr inbounds i8, i8* %t310, i64 -16
  %t319 = bitcast i8* %t318 to i64*
  %t320 = load atomic i64, i64* %t319 seq_cst, align 8
  %t321 = icmp eq i64 %t320, 1
  br i1 %t321, label %list_cow_done_71, label %list_cow_clone_72
list_cow_clone_72:
  %t322 = bitcast i8* %t310 to { i32*, i64, i64 }*
  %t323 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t322, i32 0, i32 0
  %t324 = load i32*, i32** %t323
  %t325 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t322, i32 0, i32 1
  %t326 = load i64, i64* %t325
  %t327 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t322, i32 0, i32 2
  %t328 = load i64, i64* %t327
  %t329 = bitcast void (i8*)* @list_release_i32 to i8*
  %t330 = call i8* @star_rc_alloc(i64 24, i8* %t329)
  %t331 = bitcast i8* %t330 to { i32*, i64, i64 }*
  %t332 = mul i64 %t328, %t309
  %t333 = call i8* @malloc(i64 %t332)
  %t334 = bitcast i8* %t333 to i32*
  %t335 = icmp sgt i64 %t326, 0
  br i1 %t335, label %list_cow_copy_73, label %list_cow_after_copy_74
list_cow_copy_73:
  %t336 = mul i64 %t326, %t309
  %t337 = bitcast i32* %t324 to i8*
  call i8* @memcpy(i8* %t333, i8* %t337, i64 %t336)
  br label %list_cow_after_copy_74
list_cow_after_copy_74:
  %t338 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t331, i32 0, i32 0
  store i32* %t334, i32** %t338
  %t339 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t331, i32 0, i32 1
  store i64 %t326, i64* %t339
  %t340 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t331, i32 0, i32 2
  store i64 %t328, i64* %t340
  call void @star_rc_release(i8* %t310)
  store i8* %t330, i8** %t73
  br label %list_cow_done_71
list_cow_done_71:
  %t341 = load i8*, i8** %t73
  %t342 = bitcast i8* %t341 to { i32*, i64, i64 }*
  %t343 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t342, i32 0, i32 0
  %t344 = load i32*, i32** %t343
  %t345 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t342, i32 0, i32 1
  %t346 = load i64, i64* %t345
  %t347 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t342, i32 0, i32 2
  %t348 = load i32, i32* %t7
  %t349 = sext i32 %t348 to i64
  %t350 = icmp ult i64 %t349, %t346
  br i1 %t350, label %list_set_do_75, label %list_set_end_76
list_set_do_75:
  %t351 = getelementptr inbounds i32, i32* %t344, i64 %t349
  store i32 %t307, i32* %t351
  br label %list_set_end_76
list_set_end_76:
  br label %if_end_51
if_else_50:
  br label %if_end_51
if_end_51:
  %t352 = load i32, i32* %t7
  %t353 = add i32 %t352, 1
  store i32 %t353, i32* %t7
  br label %while_cond_28
while_else_30:
  br label %while_end_31
while_end_31:
  %t354 = alloca i32
  store i32 0, i32* %t354
  %t355 = alloca i32
  store i32 0, i32* %t355
  br label %while_cond_77
while_cond_77:
  %t356 = load i32, i32* %t355
  %t357 = load i32, i32* %t2
  %t358 = icmp slt i32 %t356, %t357
  br i1 %t358, label %while_body_78, label %while_end_80
while_body_78:
  %t359 = alloca i32
  %t360 = load i8*, i8** %t0
  %t361 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t361)
  call void @star_rc_release(i8* %t360)
  %t362 = load i32, i32* %t355
  %t363 = sext i32 %t362 to i64
  %t364 = icmp eq i8* %t360, null
  br i1 %t364, label %str_idx_oob_83, label %str_idx_chk_81
str_idx_chk_81:
  %t365 = call i32 @strlen(i8* %t360)
  %t366 = sext i32 %t365 to i64
  %t367 = icmp ult i64 %t363, %t366
  br i1 %t367, label %str_idx_ok_82, label %str_idx_oob_83
str_idx_ok_82:
  %t368 = getelementptr inbounds i8, i8* %t360, i64 %t363
  %t369 = load i8, i8* %t368
  %t370 = zext i8 %t369 to i32
  br label %str_idx_end_84
str_idx_oob_83:
  br label %str_idx_end_84
str_idx_end_84:
  %t371 = phi i32 [ %t370, %str_idx_ok_82 ], [ 0, %str_idx_oob_83 ]
  store i32 %t371, i32* %t359
  %t372 = load i32, i32* %t359
  br label %match_scrutinee_374
match_scrutinee_374:
  %t375 = icmp eq i32 %t372, 43
  br i1 %t375, label %match_then_0, label %match_next_0
match_then_0:
  %t376 = alloca i32
  %t377 = load i8*, i8** %t6
  %t378 = icmp eq i8* %t377, null
  br i1 %t378, label %list_read_null_85, label %list_read_real_86
list_read_null_85:
  br label %list_read_end_87
list_read_real_86:
  %t379 = bitcast i8* %t377 to { i32*, i64, i64 }*
  %t380 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t379, i32 0, i32 0
  %t381 = load i32*, i32** %t380
  %t382 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t379, i32 0, i32 1
  %t383 = load i64, i64* %t382
  br label %list_read_end_87
list_read_end_87:
  %t384 = phi i32* [ null, %list_read_null_85 ], [ %t381, %list_read_real_86 ]
  %t385 = phi i64 [ 0, %list_read_null_85 ], [ %t383, %list_read_real_86 ]
  %t386 = load i32, i32* %t354
  %t387 = sext i32 %t386 to i64
  %t388 = icmp ult i64 %t387, %t385
  br i1 %t388, label %list_idx_ok_88, label %list_idx_oob_89
list_idx_ok_88:
  %t389 = getelementptr inbounds i32, i32* %t384, i64 %t387
  %t390 = load i32, i32* %t389
  br label %list_idx_end_90
list_idx_oob_89:
  br label %list_idx_end_90
list_idx_end_90:
  %t391 = phi i32 [ %t390, %list_idx_ok_88 ], [ 0, %list_idx_oob_89 ]
  %t392 = add i32 %t391, 1
  store i32 %t392, i32* %t376
  %t393 = load i32, i32* %t376
  %t394 = icmp sgt i32 %t393, 255
  br i1 %t394, label %if_then_91, label %if_else_92
if_then_91:
  store i32 0, i32* %t376
  br label %if_end_93
if_else_92:
  br label %if_end_93
if_end_93:
  %t395 = load i32, i32* %t376
  %t396 = getelementptr i32, i32* null, i32 1
  %t397 = ptrtoint i32* %t396 to i64
  %t398 = load i8*, i8** %t6
  %t399 = icmp eq i8* %t398, null
  br i1 %t399, label %list_cow_alloc_94, label %list_cow_check_95
list_cow_alloc_94:
  %t400 = bitcast void (i8*)* @list_release_i32 to i8*
  %t401 = call i8* @star_rc_alloc(i64 24, i8* %t400)
  %t402 = bitcast i8* %t401 to { i32*, i64, i64 }*
  %t403 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t402, i32 0, i32 0
  store i32* null, i32** %t403
  %t404 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t402, i32 0, i32 1
  store i64 0, i64* %t404
  %t405 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t402, i32 0, i32 2
  store i64 0, i64* %t405
  store i8* %t401, i8** %t6
  br label %list_cow_done_96
list_cow_check_95:
  %t406 = getelementptr inbounds i8, i8* %t398, i64 -16
  %t407 = bitcast i8* %t406 to i64*
  %t408 = load atomic i64, i64* %t407 seq_cst, align 8
  %t409 = icmp eq i64 %t408, 1
  br i1 %t409, label %list_cow_done_96, label %list_cow_clone_97
list_cow_clone_97:
  %t410 = bitcast i8* %t398 to { i32*, i64, i64 }*
  %t411 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t410, i32 0, i32 0
  %t412 = load i32*, i32** %t411
  %t413 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t410, i32 0, i32 1
  %t414 = load i64, i64* %t413
  %t415 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t410, i32 0, i32 2
  %t416 = load i64, i64* %t415
  %t417 = bitcast void (i8*)* @list_release_i32 to i8*
  %t418 = call i8* @star_rc_alloc(i64 24, i8* %t417)
  %t419 = bitcast i8* %t418 to { i32*, i64, i64 }*
  %t420 = mul i64 %t416, %t397
  %t421 = call i8* @malloc(i64 %t420)
  %t422 = bitcast i8* %t421 to i32*
  %t423 = icmp sgt i64 %t414, 0
  br i1 %t423, label %list_cow_copy_98, label %list_cow_after_copy_99
list_cow_copy_98:
  %t424 = mul i64 %t414, %t397
  %t425 = bitcast i32* %t412 to i8*
  call i8* @memcpy(i8* %t421, i8* %t425, i64 %t424)
  br label %list_cow_after_copy_99
list_cow_after_copy_99:
  %t426 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t419, i32 0, i32 0
  store i32* %t422, i32** %t426
  %t427 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t419, i32 0, i32 1
  store i64 %t414, i64* %t427
  %t428 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t419, i32 0, i32 2
  store i64 %t416, i64* %t428
  call void @star_rc_release(i8* %t398)
  store i8* %t418, i8** %t6
  br label %list_cow_done_96
list_cow_done_96:
  %t429 = load i8*, i8** %t6
  %t430 = bitcast i8* %t429 to { i32*, i64, i64 }*
  %t431 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t430, i32 0, i32 0
  %t432 = load i32*, i32** %t431
  %t433 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t430, i32 0, i32 1
  %t434 = load i64, i64* %t433
  %t435 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t430, i32 0, i32 2
  %t436 = load i32, i32* %t354
  %t437 = sext i32 %t436 to i64
  %t438 = icmp ult i64 %t437, %t434
  br i1 %t438, label %list_set_do_100, label %list_set_end_101
list_set_do_100:
  %t439 = getelementptr inbounds i32, i32* %t432, i64 %t437
  store i32 %t395, i32* %t439
  br label %list_set_end_101
list_set_end_101:
  br label %match_end_373
match_next_0:
  %t440 = icmp eq i32 %t372, 45
  br i1 %t440, label %match_then_1, label %match_next_1
match_then_1:
  %t441 = alloca i32
  %t442 = load i8*, i8** %t6
  %t443 = icmp eq i8* %t442, null
  br i1 %t443, label %list_read_null_102, label %list_read_real_103
list_read_null_102:
  br label %list_read_end_104
list_read_real_103:
  %t444 = bitcast i8* %t442 to { i32*, i64, i64 }*
  %t445 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t444, i32 0, i32 0
  %t446 = load i32*, i32** %t445
  %t447 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t444, i32 0, i32 1
  %t448 = load i64, i64* %t447
  br label %list_read_end_104
list_read_end_104:
  %t449 = phi i32* [ null, %list_read_null_102 ], [ %t446, %list_read_real_103 ]
  %t450 = phi i64 [ 0, %list_read_null_102 ], [ %t448, %list_read_real_103 ]
  %t451 = load i32, i32* %t354
  %t452 = sext i32 %t451 to i64
  %t453 = icmp ult i64 %t452, %t450
  br i1 %t453, label %list_idx_ok_105, label %list_idx_oob_106
list_idx_ok_105:
  %t454 = getelementptr inbounds i32, i32* %t449, i64 %t452
  %t455 = load i32, i32* %t454
  br label %list_idx_end_107
list_idx_oob_106:
  br label %list_idx_end_107
list_idx_end_107:
  %t456 = phi i32 [ %t455, %list_idx_ok_105 ], [ 0, %list_idx_oob_106 ]
  %t457 = sub i32 %t456, 1
  store i32 %t457, i32* %t441
  %t458 = load i32, i32* %t441
  %t459 = icmp slt i32 %t458, 0
  br i1 %t459, label %if_then_108, label %if_else_109
if_then_108:
  store i32 255, i32* %t441
  br label %if_end_110
if_else_109:
  br label %if_end_110
if_end_110:
  %t460 = load i32, i32* %t441
  %t461 = getelementptr i32, i32* null, i32 1
  %t462 = ptrtoint i32* %t461 to i64
  %t463 = load i8*, i8** %t6
  %t464 = icmp eq i8* %t463, null
  br i1 %t464, label %list_cow_alloc_111, label %list_cow_check_112
list_cow_alloc_111:
  %t465 = bitcast void (i8*)* @list_release_i32 to i8*
  %t466 = call i8* @star_rc_alloc(i64 24, i8* %t465)
  %t467 = bitcast i8* %t466 to { i32*, i64, i64 }*
  %t468 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t467, i32 0, i32 0
  store i32* null, i32** %t468
  %t469 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t467, i32 0, i32 1
  store i64 0, i64* %t469
  %t470 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t467, i32 0, i32 2
  store i64 0, i64* %t470
  store i8* %t466, i8** %t6
  br label %list_cow_done_113
list_cow_check_112:
  %t471 = getelementptr inbounds i8, i8* %t463, i64 -16
  %t472 = bitcast i8* %t471 to i64*
  %t473 = load atomic i64, i64* %t472 seq_cst, align 8
  %t474 = icmp eq i64 %t473, 1
  br i1 %t474, label %list_cow_done_113, label %list_cow_clone_114
list_cow_clone_114:
  %t475 = bitcast i8* %t463 to { i32*, i64, i64 }*
  %t476 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t475, i32 0, i32 0
  %t477 = load i32*, i32** %t476
  %t478 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t475, i32 0, i32 1
  %t479 = load i64, i64* %t478
  %t480 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t475, i32 0, i32 2
  %t481 = load i64, i64* %t480
  %t482 = bitcast void (i8*)* @list_release_i32 to i8*
  %t483 = call i8* @star_rc_alloc(i64 24, i8* %t482)
  %t484 = bitcast i8* %t483 to { i32*, i64, i64 }*
  %t485 = mul i64 %t481, %t462
  %t486 = call i8* @malloc(i64 %t485)
  %t487 = bitcast i8* %t486 to i32*
  %t488 = icmp sgt i64 %t479, 0
  br i1 %t488, label %list_cow_copy_115, label %list_cow_after_copy_116
list_cow_copy_115:
  %t489 = mul i64 %t479, %t462
  %t490 = bitcast i32* %t477 to i8*
  call i8* @memcpy(i8* %t486, i8* %t490, i64 %t489)
  br label %list_cow_after_copy_116
list_cow_after_copy_116:
  %t491 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t484, i32 0, i32 0
  store i32* %t487, i32** %t491
  %t492 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t484, i32 0, i32 1
  store i64 %t479, i64* %t492
  %t493 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t484, i32 0, i32 2
  store i64 %t481, i64* %t493
  call void @star_rc_release(i8* %t463)
  store i8* %t483, i8** %t6
  br label %list_cow_done_113
list_cow_done_113:
  %t494 = load i8*, i8** %t6
  %t495 = bitcast i8* %t494 to { i32*, i64, i64 }*
  %t496 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t495, i32 0, i32 0
  %t497 = load i32*, i32** %t496
  %t498 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t495, i32 0, i32 1
  %t499 = load i64, i64* %t498
  %t500 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t495, i32 0, i32 2
  %t501 = load i32, i32* %t354
  %t502 = sext i32 %t501 to i64
  %t503 = icmp ult i64 %t502, %t499
  br i1 %t503, label %list_set_do_117, label %list_set_end_118
list_set_do_117:
  %t504 = getelementptr inbounds i32, i32* %t497, i64 %t502
  store i32 %t460, i32* %t504
  br label %list_set_end_118
list_set_end_118:
  br label %match_end_373
match_next_1:
  %t505 = icmp eq i32 %t372, 62
  br i1 %t505, label %match_then_2, label %match_next_2
match_then_2:
  %t506 = load i32, i32* %t354
  %t507 = add i32 %t506, 1
  store i32 %t507, i32* %t354
  br label %match_end_373
match_next_2:
  %t508 = icmp eq i32 %t372, 60
  br i1 %t508, label %match_then_3, label %match_next_3
match_then_3:
  %t509 = load i32, i32* %t354
  %t510 = sub i32 %t509, 1
  store i32 %t510, i32* %t354
  br label %match_end_373
match_next_3:
  %t511 = icmp eq i32 %t372, 46
  br i1 %t511, label %match_then_4, label %match_next_4
match_then_4:
  %t512 = load i8*, i8** %t6
  %t513 = icmp eq i8* %t512, null
  br i1 %t513, label %list_read_null_119, label %list_read_real_120
list_read_null_119:
  br label %list_read_end_121
list_read_real_120:
  %t514 = bitcast i8* %t512 to { i32*, i64, i64 }*
  %t515 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t514, i32 0, i32 0
  %t516 = load i32*, i32** %t515
  %t517 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t514, i32 0, i32 1
  %t518 = load i64, i64* %t517
  br label %list_read_end_121
list_read_end_121:
  %t519 = phi i32* [ null, %list_read_null_119 ], [ %t516, %list_read_real_120 ]
  %t520 = phi i64 [ 0, %list_read_null_119 ], [ %t518, %list_read_real_120 ]
  %t521 = load i32, i32* %t354
  %t522 = sext i32 %t521 to i64
  %t523 = icmp ult i64 %t522, %t520
  br i1 %t523, label %list_idx_ok_122, label %list_idx_oob_123
list_idx_ok_122:
  %t524 = getelementptr inbounds i32, i32* %t519, i64 %t522
  %t525 = load i32, i32* %t524
  br label %list_idx_end_124
list_idx_oob_123:
  br label %list_idx_end_124
list_idx_end_124:
  %t526 = phi i32 [ %t525, %list_idx_ok_122 ], [ 0, %list_idx_oob_123 ]
  %t527 = call i32 @putchar(i32 %t526)
  br label %match_end_373
match_next_4:
  %t528 = icmp eq i32 %t372, 44
  br i1 %t528, label %match_then_5, label %match_next_5
match_then_5:
  %t529 = getelementptr i32, i32* null, i32 1
  %t530 = ptrtoint i32* %t529 to i64
  %t531 = load i8*, i8** %t6
  %t532 = icmp eq i8* %t531, null
  br i1 %t532, label %list_cow_alloc_125, label %list_cow_check_126
list_cow_alloc_125:
  %t533 = bitcast void (i8*)* @list_release_i32 to i8*
  %t534 = call i8* @star_rc_alloc(i64 24, i8* %t533)
  %t535 = bitcast i8* %t534 to { i32*, i64, i64 }*
  %t536 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t535, i32 0, i32 0
  store i32* null, i32** %t536
  %t537 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t535, i32 0, i32 1
  store i64 0, i64* %t537
  %t538 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t535, i32 0, i32 2
  store i64 0, i64* %t538
  store i8* %t534, i8** %t6
  br label %list_cow_done_127
list_cow_check_126:
  %t539 = getelementptr inbounds i8, i8* %t531, i64 -16
  %t540 = bitcast i8* %t539 to i64*
  %t541 = load atomic i64, i64* %t540 seq_cst, align 8
  %t542 = icmp eq i64 %t541, 1
  br i1 %t542, label %list_cow_done_127, label %list_cow_clone_128
list_cow_clone_128:
  %t543 = bitcast i8* %t531 to { i32*, i64, i64 }*
  %t544 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t543, i32 0, i32 0
  %t545 = load i32*, i32** %t544
  %t546 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t543, i32 0, i32 1
  %t547 = load i64, i64* %t546
  %t548 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t543, i32 0, i32 2
  %t549 = load i64, i64* %t548
  %t550 = bitcast void (i8*)* @list_release_i32 to i8*
  %t551 = call i8* @star_rc_alloc(i64 24, i8* %t550)
  %t552 = bitcast i8* %t551 to { i32*, i64, i64 }*
  %t553 = mul i64 %t549, %t530
  %t554 = call i8* @malloc(i64 %t553)
  %t555 = bitcast i8* %t554 to i32*
  %t556 = icmp sgt i64 %t547, 0
  br i1 %t556, label %list_cow_copy_129, label %list_cow_after_copy_130
list_cow_copy_129:
  %t557 = mul i64 %t547, %t530
  %t558 = bitcast i32* %t545 to i8*
  call i8* @memcpy(i8* %t554, i8* %t558, i64 %t557)
  br label %list_cow_after_copy_130
list_cow_after_copy_130:
  %t559 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t552, i32 0, i32 0
  store i32* %t555, i32** %t559
  %t560 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t552, i32 0, i32 1
  store i64 %t547, i64* %t560
  %t561 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t552, i32 0, i32 2
  store i64 %t549, i64* %t561
  call void @star_rc_release(i8* %t531)
  store i8* %t551, i8** %t6
  br label %list_cow_done_127
list_cow_done_127:
  %t562 = load i8*, i8** %t6
  %t563 = bitcast i8* %t562 to { i32*, i64, i64 }*
  %t564 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t563, i32 0, i32 0
  %t565 = load i32*, i32** %t564
  %t566 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t563, i32 0, i32 1
  %t567 = load i64, i64* %t566
  %t568 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t563, i32 0, i32 2
  %t569 = load i32, i32* %t354
  %t570 = sext i32 %t569 to i64
  %t571 = icmp ult i64 %t570, %t567
  br i1 %t571, label %list_set_do_131, label %list_set_end_132
list_set_do_131:
  %t572 = getelementptr inbounds i32, i32* %t565, i64 %t570
  store i32 0, i32* %t572
  br label %list_set_end_132
list_set_end_132:
  br label %match_end_373
match_next_5:
  %t573 = icmp eq i32 %t372, 91
  br i1 %t573, label %match_then_6, label %match_next_6
match_then_6:
  %t574 = load i8*, i8** %t6
  %t575 = icmp eq i8* %t574, null
  br i1 %t575, label %list_read_null_133, label %list_read_real_134
list_read_null_133:
  br label %list_read_end_135
list_read_real_134:
  %t576 = bitcast i8* %t574 to { i32*, i64, i64 }*
  %t577 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t576, i32 0, i32 0
  %t578 = load i32*, i32** %t577
  %t579 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t576, i32 0, i32 1
  %t580 = load i64, i64* %t579
  br label %list_read_end_135
list_read_end_135:
  %t581 = phi i32* [ null, %list_read_null_133 ], [ %t578, %list_read_real_134 ]
  %t582 = phi i64 [ 0, %list_read_null_133 ], [ %t580, %list_read_real_134 ]
  %t583 = load i32, i32* %t354
  %t584 = sext i32 %t583 to i64
  %t585 = icmp ult i64 %t584, %t582
  br i1 %t585, label %list_idx_ok_136, label %list_idx_oob_137
list_idx_ok_136:
  %t586 = getelementptr inbounds i32, i32* %t581, i64 %t584
  %t587 = load i32, i32* %t586
  br label %list_idx_end_138
list_idx_oob_137:
  br label %list_idx_end_138
list_idx_end_138:
  %t588 = phi i32 [ %t587, %list_idx_ok_136 ], [ 0, %list_idx_oob_137 ]
  %t589 = icmp eq i32 %t588, 0
  br i1 %t589, label %if_then_139, label %if_else_140
if_then_139:
  %t590 = load i8*, i8** %t73
  %t591 = icmp eq i8* %t590, null
  br i1 %t591, label %list_read_null_142, label %list_read_real_143
list_read_null_142:
  br label %list_read_end_144
list_read_real_143:
  %t592 = bitcast i8* %t590 to { i32*, i64, i64 }*
  %t593 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t592, i32 0, i32 0
  %t594 = load i32*, i32** %t593
  %t595 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t592, i32 0, i32 1
  %t596 = load i64, i64* %t595
  br label %list_read_end_144
list_read_end_144:
  %t597 = phi i32* [ null, %list_read_null_142 ], [ %t594, %list_read_real_143 ]
  %t598 = phi i64 [ 0, %list_read_null_142 ], [ %t596, %list_read_real_143 ]
  %t599 = load i32, i32* %t355
  %t600 = sext i32 %t599 to i64
  %t601 = icmp ult i64 %t600, %t598
  br i1 %t601, label %list_idx_ok_145, label %list_idx_oob_146
list_idx_ok_145:
  %t602 = getelementptr inbounds i32, i32* %t597, i64 %t600
  %t603 = load i32, i32* %t602
  br label %list_idx_end_147
list_idx_oob_146:
  br label %list_idx_end_147
list_idx_end_147:
  %t604 = phi i32 [ %t603, %list_idx_ok_145 ], [ 0, %list_idx_oob_146 ]
  store i32 %t604, i32* %t355
  br label %if_end_141
if_else_140:
  br label %if_end_141
if_end_141:
  br label %match_end_373
match_next_6:
  %t605 = icmp eq i32 %t372, 93
  br i1 %t605, label %match_then_7, label %match_next_7
match_then_7:
  %t606 = load i8*, i8** %t6
  %t607 = icmp eq i8* %t606, null
  br i1 %t607, label %list_read_null_148, label %list_read_real_149
list_read_null_148:
  br label %list_read_end_150
list_read_real_149:
  %t608 = bitcast i8* %t606 to { i32*, i64, i64 }*
  %t609 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t608, i32 0, i32 0
  %t610 = load i32*, i32** %t609
  %t611 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t608, i32 0, i32 1
  %t612 = load i64, i64* %t611
  br label %list_read_end_150
list_read_end_150:
  %t613 = phi i32* [ null, %list_read_null_148 ], [ %t610, %list_read_real_149 ]
  %t614 = phi i64 [ 0, %list_read_null_148 ], [ %t612, %list_read_real_149 ]
  %t615 = load i32, i32* %t354
  %t616 = sext i32 %t615 to i64
  %t617 = icmp ult i64 %t616, %t614
  br i1 %t617, label %list_idx_ok_151, label %list_idx_oob_152
list_idx_ok_151:
  %t618 = getelementptr inbounds i32, i32* %t613, i64 %t616
  %t619 = load i32, i32* %t618
  br label %list_idx_end_153
list_idx_oob_152:
  br label %list_idx_end_153
list_idx_end_153:
  %t620 = phi i32 [ %t619, %list_idx_ok_151 ], [ 0, %list_idx_oob_152 ]
  %t621 = icmp ne i32 %t620, 0
  br i1 %t621, label %if_then_154, label %if_else_155
if_then_154:
  %t622 = load i8*, i8** %t73
  %t623 = icmp eq i8* %t622, null
  br i1 %t623, label %list_read_null_157, label %list_read_real_158
list_read_null_157:
  br label %list_read_end_159
list_read_real_158:
  %t624 = bitcast i8* %t622 to { i32*, i64, i64 }*
  %t625 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t624, i32 0, i32 0
  %t626 = load i32*, i32** %t625
  %t627 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t624, i32 0, i32 1
  %t628 = load i64, i64* %t627
  br label %list_read_end_159
list_read_end_159:
  %t629 = phi i32* [ null, %list_read_null_157 ], [ %t626, %list_read_real_158 ]
  %t630 = phi i64 [ 0, %list_read_null_157 ], [ %t628, %list_read_real_158 ]
  %t631 = load i32, i32* %t355
  %t632 = sext i32 %t631 to i64
  %t633 = icmp ult i64 %t632, %t630
  br i1 %t633, label %list_idx_ok_160, label %list_idx_oob_161
list_idx_ok_160:
  %t634 = getelementptr inbounds i32, i32* %t629, i64 %t632
  %t635 = load i32, i32* %t634
  br label %list_idx_end_162
list_idx_oob_161:
  br label %list_idx_end_162
list_idx_end_162:
  %t636 = phi i32 [ %t635, %list_idx_ok_160 ], [ 0, %list_idx_oob_161 ]
  store i32 %t636, i32* %t355
  br label %if_end_156
if_else_155:
  br label %if_end_156
if_end_156:
  br label %match_end_373
match_next_7:
  br label %match_end_373
match_end_373:
  %t637 = phi i32 [ undef, %list_set_end_101 ], [ undef, %list_set_end_118 ], [ undef, %match_then_2 ], [ undef, %match_then_3 ], [ %t527, %list_idx_end_124 ], [ undef, %list_set_end_132 ], [ undef, %if_end_141 ], [ undef, %if_end_156 ], [ 0, %match_next_7 ]
  %t638 = load i32, i32* %t355
  %t639 = add i32 %t638, 1
  store i32 %t639, i32* %t355
  br label %while_cond_77
while_else_79:
  br label %while_end_80
while_end_80:
  %t640 = load i8*, i8** %t136
  call void @star_rc_release(i8* %t640)
  %t641 = load i8*, i8** %t73
  call void @star_rc_release(i8* %t641)
  %t642 = load i8*, i8** %t6
  call void @star_rc_release(i8* %t642)
  %t643 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t643)
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
