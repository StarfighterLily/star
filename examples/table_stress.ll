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

%Item = type { i32, i8* }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = alloca i8*
  store i8* null, i8** %t0
  %t1 = alloca i32
  store i32 0, i32* %t1
  br label %while_cond_0
while_cond_0:
  %t2 = load i32, i32* %t1
  %t3 = icmp slt i32 %t2, 5000
  br i1 %t3, label %while_body_1, label %while_else_2
while_body_1:
  %t4 = load i8*, i8** %t0
  %t5 = icmp eq i8* %t4, null
  br i1 %t5, label %table_cow_alloc_4, label %table_cow_check_5
table_cow_alloc_4:
  %t21 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t22 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t23 = ptrtoint { i64, i64, i32*, i8** }* %t22 to i64
  %t24 = call i8* @star_rc_alloc(i64 %t23, i8* %t21)
  %t25 = bitcast i8* %t24 to { i64, i64, i32*, i8** }*
  %t26 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t25, i32 0, i32 0
  store i64 0, i64* %t26
  %t27 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t25, i32 0, i32 1
  store i64 0, i64* %t27
  %t28 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t25, i32 0, i32 2
  store i32* null, i32** %t28
  %t29 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t25, i32 0, i32 3
  store i8** null, i8*** %t29
  store i8* %t24, i8** %t0
  br label %table_cow_done_6
table_cow_check_5:
  %t30 = getelementptr inbounds i8, i8* %t4, i64 -16
  %t31 = bitcast i8* %t30 to i64*
  %t32 = load atomic i64, i64* %t31 seq_cst, align 8
  %t33 = icmp eq i64 %t32, 1
  br i1 %t33, label %table_cow_done_6, label %table_cow_clone_10
table_cow_clone_10:
  %t34 = bitcast i8* %t4 to { i64, i64, i32*, i8** }*
  %t35 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t34, i32 0, i32 0
  %t36 = load i64, i64* %t35
  %t37 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t34, i32 0, i32 1
  %t38 = load i64, i64* %t37
  %t39 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t40 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t41 = ptrtoint { i64, i64, i32*, i8** }* %t40 to i64
  %t42 = call i8* @star_rc_alloc(i64 %t41, i8* %t39)
  %t43 = bitcast i8* %t42 to { i64, i64, i32*, i8** }*
  %t44 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t43, i32 0, i32 0
  store i64 %t36, i64* %t44
  %t45 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t43, i32 0, i32 1
  store i64 %t38, i64* %t45
  %t46 = getelementptr i32, i32* null, i32 1
  %t47 = ptrtoint i32* %t46 to i64
  %t48 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t34, i32 0, i32 2
  %t49 = load i32*, i32** %t48
  %t50 = mul i64 %t38, %t47
  %t51 = call i8* @malloc(i64 %t50)
  %t52 = bitcast i8* %t51 to i32*
  %t53 = icmp sgt i64 %t36, 0
  br i1 %t53, label %table_cow_copy_11, label %table_cow_after_copy_12
table_cow_copy_11:
  %t54 = mul i64 %t36, %t47
  %t55 = bitcast i32* %t49 to i8*
  call i8* @memcpy(i8* %t51, i8* %t55, i64 %t54)
  br label %table_cow_after_copy_12
table_cow_after_copy_12:
  %t56 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t43, i32 0, i32 2
  store i32* %t52, i32** %t56
  %t57 = getelementptr i8*, i8** null, i32 1
  %t58 = ptrtoint i8** %t57 to i64
  %t59 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t34, i32 0, i32 3
  %t60 = load i8**, i8*** %t59
  %t61 = mul i64 %t38, %t58
  %t62 = call i8* @malloc(i64 %t61)
  %t63 = bitcast i8* %t62 to i8**
  %t64 = icmp sgt i64 %t36, 0
  br i1 %t64, label %table_cow_copy_13, label %table_cow_after_copy_14
table_cow_copy_13:
  %t65 = mul i64 %t36, %t58
  %t66 = bitcast i8** %t60 to i8*
  call i8* @memcpy(i8* %t62, i8* %t66, i64 %t65)
  %t67 = alloca i64
  store i64 0, i64* %t67
  br label %table_cow_retain_cond_15
table_cow_retain_cond_15:
  %t68 = load i64, i64* %t67
  %t69 = icmp slt i64 %t68, %t36
  br i1 %t69, label %table_cow_retain_body_16, label %table_cow_retain_end_17
table_cow_retain_body_16:
  %t70 = getelementptr inbounds i8*, i8** %t63, i64 %t68
  %t71 = load i8*, i8** %t70
  call void @star_rc_retain(i8* %t71)
  %t72 = add i64 %t68, 1
  store i64 %t72, i64* %t67
  br label %table_cow_retain_cond_15
table_cow_retain_end_17:
  br label %table_cow_after_copy_14
table_cow_after_copy_14:
  %t73 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t43, i32 0, i32 3
  store i8** %t63, i8*** %t73
  call void @star_rc_release(i8* %t4)
  store i8* %t42, i8** %t0
  br label %table_cow_done_6
table_cow_done_6:
  %t74 = load i8*, i8** %t0
  %t75 = bitcast i8* %t74 to { i64, i64, i32*, i8** }*
  %t76 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t75, i32 0, i32 0
  %t77 = load i64, i64* %t76
  %t78 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t75, i32 0, i32 1
  %t79 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t75, i32 0, i32 2
  %t80 = load i32*, i32** %t79
  %t81 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t75, i32 0, i32 3
  %t82 = load i8**, i8*** %t81
  %t83 = alloca %Item
  %t84 = load i32, i32* %t1
  %t85 = getelementptr inbounds %Item, %Item* %t83, i32 0, i32 0
  store i32 %t84, i32* %t85
  %t86 = load i32, i32* %t1
  %t87 = getelementptr inbounds [7 x i8], [7 x i8]* @.str.0, i64 0, i64 0
  %t88 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t87, i32 %t86)
  %t89 = add i32 %t88, 1
  %t90 = sext i32 %t89 to i64
  %t91 = call i8* @star_rc_alloc(i64 %t90, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t91, i64 %t90, i8* %t87, i32 %t86)
  %t92 = getelementptr inbounds %Item, %Item* %t83, i32 0, i32 1
  store i8* %t91, i8** %t92
  %t93 = load %Item, %Item* %t83
  %t94 = load i64, i64* %t78
  %t95 = icmp sge i64 %t77, %t94
  br i1 %t95, label %table_push_grow_18, label %table_push_store_19
table_push_grow_18:
  %t96 = mul i64 %t94, 2
  %t97 = icmp sgt i64 %t96, 0
  %t98 = select i1 %t97, i64 %t96, i64 1
  %t99 = getelementptr i32, i32* null, i32 1
  %t100 = ptrtoint i32* %t99 to i64
  %t101 = mul i64 %t98, %t100
  %t102 = call i8* @malloc(i64 %t101)
  %t103 = bitcast i8* %t102 to i32*
  %t104 = icmp sgt i64 %t94, 0
  br i1 %t104, label %table_push_copy_20, label %table_push_after_copy_21
table_push_copy_20:
  %t105 = mul i64 %t77, %t100
  %t106 = bitcast i32* %t80 to i8*
  call i8* @memcpy(i8* %t102, i8* %t106, i64 %t105)
  call void @free(i8* %t106)
  br label %table_push_after_copy_21
table_push_after_copy_21:
  store i32* %t103, i32** %t79
  %t107 = getelementptr i8*, i8** null, i32 1
  %t108 = ptrtoint i8** %t107 to i64
  %t109 = mul i64 %t98, %t108
  %t110 = call i8* @malloc(i64 %t109)
  %t111 = bitcast i8* %t110 to i8**
  %t112 = icmp sgt i64 %t94, 0
  br i1 %t112, label %table_push_copy_22, label %table_push_after_copy_23
table_push_copy_22:
  %t113 = mul i64 %t77, %t108
  %t114 = bitcast i8** %t82 to i8*
  call i8* @memcpy(i8* %t110, i8* %t114, i64 %t113)
  call void @free(i8* %t114)
  br label %table_push_after_copy_23
table_push_after_copy_23:
  store i8** %t111, i8*** %t81
  store i64 %t98, i64* %t78
  br label %table_push_store_19
table_push_store_19:
  %t115 = load i32*, i32** %t79
  %t116 = extractvalue %Item %t93, 0
  %t117 = getelementptr inbounds i32, i32* %t115, i64 %t77
  store i32 %t116, i32* %t117
  %t118 = load i8**, i8*** %t81
  %t119 = extractvalue %Item %t93, 1
  %t120 = getelementptr inbounds i8*, i8** %t118, i64 %t77
  store i8* %t119, i8** %t120
  %t121 = add i64 %t77, 1
  store i64 %t121, i64* %t76
  %t122 = load i32, i32* %t1
  %t123 = add i32 %t122, 1
  store i32 %t123, i32* %t1
  br label %while_cond_0
while_else_2:
  br label %while_end_3
while_end_3:
  %t124 = load i8*, i8** %t0
  %t125 = icmp eq i8* %t124, null
  br i1 %t125, label %table_read_null_24, label %table_read_real_25
table_read_null_24:
  br label %table_read_end_26
table_read_real_25:
  %t126 = bitcast i8* %t124 to { i64, i64, i32*, i8** }*
  %t127 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t126, i32 0, i32 0
  %t128 = load i64, i64* %t127
  %t129 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t126, i32 0, i32 2
  %t130 = load i32*, i32** %t129
  %t131 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t126, i32 0, i32 3
  %t132 = load i8**, i8*** %t131
  br label %table_read_end_26
table_read_end_26:
  %t133 = phi i64 [ 0, %table_read_null_24 ], [ %t128, %table_read_real_25 ]
  %t134 = phi i32* [ null, %table_read_null_24 ], [ %t130, %table_read_real_25 ]
  %t135 = phi i8** [ null, %table_read_null_24 ], [ %t132, %table_read_real_25 ]
  %t136 = trunc i64 %t133 to i32
  %t137 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t137, i32 %t136)
  %t138 = load i8*, i8** %t0
  %t139 = icmp eq i8* %t138, null
  br i1 %t139, label %table_read_null_27, label %table_read_real_28
table_read_null_27:
  br label %table_read_end_29
table_read_real_28:
  %t140 = bitcast i8* %t138 to { i64, i64, i32*, i8** }*
  %t141 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t140, i32 0, i32 0
  %t142 = load i64, i64* %t141
  %t143 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t140, i32 0, i32 2
  %t144 = load i32*, i32** %t143
  %t145 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t140, i32 0, i32 3
  %t146 = load i8**, i8*** %t145
  br label %table_read_end_29
table_read_end_29:
  %t147 = phi i64 [ 0, %table_read_null_27 ], [ %t142, %table_read_real_28 ]
  %t148 = phi i32* [ null, %table_read_null_27 ], [ %t144, %table_read_real_28 ]
  %t149 = phi i8** [ null, %table_read_null_27 ], [ %t146, %table_read_real_28 ]
  %t150 = sext i32 0 to i64
  %t151 = alloca %Item
  %t152 = icmp ult i64 %t150, %t147
  br i1 %t152, label %table_idx_ok_30, label %table_idx_oob_31
table_idx_ok_30:
  %t153 = getelementptr inbounds i32, i32* %t148, i64 %t150
  %t154 = load i32, i32* %t153
  %t155 = getelementptr inbounds %Item, %Item* %t151, i32 0, i32 0
  store i32 %t154, i32* %t155
  %t156 = getelementptr inbounds i8*, i8** %t149, i64 %t150
  %t157 = load i8*, i8** %t156
  call void @star_rc_retain(i8* %t157)
  %t158 = load i8*, i8** %t156
  %t159 = getelementptr inbounds %Item, %Item* %t151, i32 0, i32 1
  store i8* %t158, i8** %t159
  br label %table_idx_end_32
table_idx_oob_31:
  store %Item zeroinitializer, %Item* %t151
  br label %table_idx_end_32
table_idx_end_32:
  %t160 = load %Item, %Item* %t151
  %t161 = alloca %Item
  store %Item %t160, %Item* %t161
  %t162 = getelementptr inbounds %Item, %Item* %t161, i32 0, i32 1
  %t163 = load i8*, i8** %t162
  %t164 = load i8*, i8** %t162
  call void @star_rc_retain(i8* %t164)
  call void @star_rc_release(i8* %t163)
  %t165 = load i8*, i8** %t0
  %t166 = icmp eq i8* %t165, null
  br i1 %t166, label %table_read_null_33, label %table_read_real_34
table_read_null_33:
  br label %table_read_end_35
table_read_real_34:
  %t167 = bitcast i8* %t165 to { i64, i64, i32*, i8** }*
  %t168 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t167, i32 0, i32 0
  %t169 = load i64, i64* %t168
  %t170 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t167, i32 0, i32 2
  %t171 = load i32*, i32** %t170
  %t172 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t167, i32 0, i32 3
  %t173 = load i8**, i8*** %t172
  br label %table_read_end_35
table_read_end_35:
  %t174 = phi i64 [ 0, %table_read_null_33 ], [ %t169, %table_read_real_34 ]
  %t175 = phi i32* [ null, %table_read_null_33 ], [ %t171, %table_read_real_34 ]
  %t176 = phi i8** [ null, %table_read_null_33 ], [ %t173, %table_read_real_34 ]
  %t177 = sext i32 0 to i64
  %t178 = alloca %Item
  %t179 = icmp ult i64 %t177, %t174
  br i1 %t179, label %table_idx_ok_36, label %table_idx_oob_37
table_idx_ok_36:
  %t180 = getelementptr inbounds i32, i32* %t175, i64 %t177
  %t181 = load i32, i32* %t180
  %t182 = getelementptr inbounds %Item, %Item* %t178, i32 0, i32 0
  store i32 %t181, i32* %t182
  %t183 = getelementptr inbounds i8*, i8** %t176, i64 %t177
  %t184 = load i8*, i8** %t183
  call void @star_rc_retain(i8* %t184)
  %t185 = load i8*, i8** %t183
  %t186 = getelementptr inbounds %Item, %Item* %t178, i32 0, i32 1
  store i8* %t185, i8** %t186
  br label %table_idx_end_38
table_idx_oob_37:
  store %Item zeroinitializer, %Item* %t178
  br label %table_idx_end_38
table_idx_end_38:
  %t187 = load %Item, %Item* %t178
  %t188 = alloca %Item
  store %Item %t187, %Item* %t188
  %t189 = getelementptr inbounds %Item, %Item* %t188, i32 0, i32 0
  %t190 = load i32, i32* %t189
  %t191 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t191, i8* %t163, i32 %t190)
  %t192 = load i8*, i8** %t0
  %t193 = icmp eq i8* %t192, null
  br i1 %t193, label %table_read_null_39, label %table_read_real_40
table_read_null_39:
  br label %table_read_end_41
table_read_real_40:
  %t194 = bitcast i8* %t192 to { i64, i64, i32*, i8** }*
  %t195 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t194, i32 0, i32 0
  %t196 = load i64, i64* %t195
  %t197 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t194, i32 0, i32 2
  %t198 = load i32*, i32** %t197
  %t199 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t194, i32 0, i32 3
  %t200 = load i8**, i8*** %t199
  br label %table_read_end_41
table_read_end_41:
  %t201 = phi i64 [ 0, %table_read_null_39 ], [ %t196, %table_read_real_40 ]
  %t202 = phi i32* [ null, %table_read_null_39 ], [ %t198, %table_read_real_40 ]
  %t203 = phi i8** [ null, %table_read_null_39 ], [ %t200, %table_read_real_40 ]
  %t204 = sext i32 4999 to i64
  %t205 = alloca %Item
  %t206 = icmp ult i64 %t204, %t201
  br i1 %t206, label %table_idx_ok_42, label %table_idx_oob_43
table_idx_ok_42:
  %t207 = getelementptr inbounds i32, i32* %t202, i64 %t204
  %t208 = load i32, i32* %t207
  %t209 = getelementptr inbounds %Item, %Item* %t205, i32 0, i32 0
  store i32 %t208, i32* %t209
  %t210 = getelementptr inbounds i8*, i8** %t203, i64 %t204
  %t211 = load i8*, i8** %t210
  call void @star_rc_retain(i8* %t211)
  %t212 = load i8*, i8** %t210
  %t213 = getelementptr inbounds %Item, %Item* %t205, i32 0, i32 1
  store i8* %t212, i8** %t213
  br label %table_idx_end_44
table_idx_oob_43:
  store %Item zeroinitializer, %Item* %t205
  br label %table_idx_end_44
table_idx_end_44:
  %t214 = load %Item, %Item* %t205
  %t215 = alloca %Item
  store %Item %t214, %Item* %t215
  %t216 = getelementptr inbounds %Item, %Item* %t215, i32 0, i32 1
  %t217 = load i8*, i8** %t216
  %t218 = load i8*, i8** %t216
  call void @star_rc_retain(i8* %t218)
  call void @star_rc_release(i8* %t217)
  %t219 = load i8*, i8** %t0
  %t220 = icmp eq i8* %t219, null
  br i1 %t220, label %table_read_null_45, label %table_read_real_46
table_read_null_45:
  br label %table_read_end_47
table_read_real_46:
  %t221 = bitcast i8* %t219 to { i64, i64, i32*, i8** }*
  %t222 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t221, i32 0, i32 0
  %t223 = load i64, i64* %t222
  %t224 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t221, i32 0, i32 2
  %t225 = load i32*, i32** %t224
  %t226 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t221, i32 0, i32 3
  %t227 = load i8**, i8*** %t226
  br label %table_read_end_47
table_read_end_47:
  %t228 = phi i64 [ 0, %table_read_null_45 ], [ %t223, %table_read_real_46 ]
  %t229 = phi i32* [ null, %table_read_null_45 ], [ %t225, %table_read_real_46 ]
  %t230 = phi i8** [ null, %table_read_null_45 ], [ %t227, %table_read_real_46 ]
  %t231 = sext i32 4999 to i64
  %t232 = alloca %Item
  %t233 = icmp ult i64 %t231, %t228
  br i1 %t233, label %table_idx_ok_48, label %table_idx_oob_49
table_idx_ok_48:
  %t234 = getelementptr inbounds i32, i32* %t229, i64 %t231
  %t235 = load i32, i32* %t234
  %t236 = getelementptr inbounds %Item, %Item* %t232, i32 0, i32 0
  store i32 %t235, i32* %t236
  %t237 = getelementptr inbounds i8*, i8** %t230, i64 %t231
  %t238 = load i8*, i8** %t237
  call void @star_rc_retain(i8* %t238)
  %t239 = load i8*, i8** %t237
  %t240 = getelementptr inbounds %Item, %Item* %t232, i32 0, i32 1
  store i8* %t239, i8** %t240
  br label %table_idx_end_50
table_idx_oob_49:
  store %Item zeroinitializer, %Item* %t232
  br label %table_idx_end_50
table_idx_end_50:
  %t241 = load %Item, %Item* %t232
  %t242 = alloca %Item
  store %Item %t241, %Item* %t242
  %t243 = getelementptr inbounds %Item, %Item* %t242, i32 0, i32 0
  %t244 = load i32, i32* %t243
  %t245 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t245, i8* %t217, i32 %t244)
  %t246 = alloca i8*
  %t247 = load i8*, i8** %t0
  %t248 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t248)
  store i8* %t247, i8** %t246
  %t249 = alloca i32
  store i32 0, i32* %t249
  br label %while_cond_51
while_cond_51:
  %t250 = load i32, i32* %t249
  %t251 = icmp slt i32 %t250, 5000
  br i1 %t251, label %while_body_52, label %while_else_53
while_body_52:
  %t252 = load i8*, i8** %t246
  %t253 = icmp eq i8* %t252, null
  br i1 %t253, label %table_cow_alloc_55, label %table_cow_check_56
table_cow_alloc_55:
  %t254 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t255 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t256 = ptrtoint { i64, i64, i32*, i8** }* %t255 to i64
  %t257 = call i8* @star_rc_alloc(i64 %t256, i8* %t254)
  %t258 = bitcast i8* %t257 to { i64, i64, i32*, i8** }*
  %t259 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t258, i32 0, i32 0
  store i64 0, i64* %t259
  %t260 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t258, i32 0, i32 1
  store i64 0, i64* %t260
  %t261 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t258, i32 0, i32 2
  store i32* null, i32** %t261
  %t262 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t258, i32 0, i32 3
  store i8** null, i8*** %t262
  store i8* %t257, i8** %t246
  br label %table_cow_done_57
table_cow_check_56:
  %t263 = getelementptr inbounds i8, i8* %t252, i64 -16
  %t264 = bitcast i8* %t263 to i64*
  %t265 = load atomic i64, i64* %t264 seq_cst, align 8
  %t266 = icmp eq i64 %t265, 1
  br i1 %t266, label %table_cow_done_57, label %table_cow_clone_58
table_cow_clone_58:
  %t267 = bitcast i8* %t252 to { i64, i64, i32*, i8** }*
  %t268 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t267, i32 0, i32 0
  %t269 = load i64, i64* %t268
  %t270 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t267, i32 0, i32 1
  %t271 = load i64, i64* %t270
  %t272 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t273 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t274 = ptrtoint { i64, i64, i32*, i8** }* %t273 to i64
  %t275 = call i8* @star_rc_alloc(i64 %t274, i8* %t272)
  %t276 = bitcast i8* %t275 to { i64, i64, i32*, i8** }*
  %t277 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t276, i32 0, i32 0
  store i64 %t269, i64* %t277
  %t278 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t276, i32 0, i32 1
  store i64 %t271, i64* %t278
  %t279 = getelementptr i32, i32* null, i32 1
  %t280 = ptrtoint i32* %t279 to i64
  %t281 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t267, i32 0, i32 2
  %t282 = load i32*, i32** %t281
  %t283 = mul i64 %t271, %t280
  %t284 = call i8* @malloc(i64 %t283)
  %t285 = bitcast i8* %t284 to i32*
  %t286 = icmp sgt i64 %t269, 0
  br i1 %t286, label %table_cow_copy_59, label %table_cow_after_copy_60
table_cow_copy_59:
  %t287 = mul i64 %t269, %t280
  %t288 = bitcast i32* %t282 to i8*
  call i8* @memcpy(i8* %t284, i8* %t288, i64 %t287)
  br label %table_cow_after_copy_60
table_cow_after_copy_60:
  %t289 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t276, i32 0, i32 2
  store i32* %t285, i32** %t289
  %t290 = getelementptr i8*, i8** null, i32 1
  %t291 = ptrtoint i8** %t290 to i64
  %t292 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t267, i32 0, i32 3
  %t293 = load i8**, i8*** %t292
  %t294 = mul i64 %t271, %t291
  %t295 = call i8* @malloc(i64 %t294)
  %t296 = bitcast i8* %t295 to i8**
  %t297 = icmp sgt i64 %t269, 0
  br i1 %t297, label %table_cow_copy_61, label %table_cow_after_copy_62
table_cow_copy_61:
  %t298 = mul i64 %t269, %t291
  %t299 = bitcast i8** %t293 to i8*
  call i8* @memcpy(i8* %t295, i8* %t299, i64 %t298)
  %t300 = alloca i64
  store i64 0, i64* %t300
  br label %table_cow_retain_cond_63
table_cow_retain_cond_63:
  %t301 = load i64, i64* %t300
  %t302 = icmp slt i64 %t301, %t269
  br i1 %t302, label %table_cow_retain_body_64, label %table_cow_retain_end_65
table_cow_retain_body_64:
  %t303 = getelementptr inbounds i8*, i8** %t296, i64 %t301
  %t304 = load i8*, i8** %t303
  call void @star_rc_retain(i8* %t304)
  %t305 = add i64 %t301, 1
  store i64 %t305, i64* %t300
  br label %table_cow_retain_cond_63
table_cow_retain_end_65:
  br label %table_cow_after_copy_62
table_cow_after_copy_62:
  %t306 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t276, i32 0, i32 3
  store i8** %t296, i8*** %t306
  call void @star_rc_release(i8* %t252)
  store i8* %t275, i8** %t246
  br label %table_cow_done_57
table_cow_done_57:
  %t307 = load i8*, i8** %t246
  %t308 = bitcast i8* %t307 to { i64, i64, i32*, i8** }*
  %t309 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t308, i32 0, i32 0
  %t310 = load i64, i64* %t309
  %t311 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t308, i32 0, i32 1
  %t312 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t308, i32 0, i32 2
  %t313 = load i32*, i32** %t312
  %t314 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t308, i32 0, i32 3
  %t315 = load i8**, i8*** %t314
  %t316 = alloca %Item
  %t317 = load i32, i32* %t249
  %t318 = getelementptr inbounds %Item, %Item* %t316, i32 0, i32 0
  store i32 %t317, i32* %t318
  %t319 = load i32, i32* %t249
  %t320 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.4, i64 0, i64 0
  %t321 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t320, i32 %t319)
  %t322 = add i32 %t321, 1
  %t323 = sext i32 %t322 to i64
  %t324 = call i8* @star_rc_alloc(i64 %t323, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t324, i64 %t323, i8* %t320, i32 %t319)
  %t325 = getelementptr inbounds %Item, %Item* %t316, i32 0, i32 1
  store i8* %t324, i8** %t325
  %t326 = load %Item, %Item* %t316
  %t327 = load i64, i64* %t311
  %t328 = icmp sge i64 %t310, %t327
  br i1 %t328, label %table_push_grow_66, label %table_push_store_67
table_push_grow_66:
  %t329 = mul i64 %t327, 2
  %t330 = icmp sgt i64 %t329, 0
  %t331 = select i1 %t330, i64 %t329, i64 1
  %t332 = getelementptr i32, i32* null, i32 1
  %t333 = ptrtoint i32* %t332 to i64
  %t334 = mul i64 %t331, %t333
  %t335 = call i8* @malloc(i64 %t334)
  %t336 = bitcast i8* %t335 to i32*
  %t337 = icmp sgt i64 %t327, 0
  br i1 %t337, label %table_push_copy_68, label %table_push_after_copy_69
table_push_copy_68:
  %t338 = mul i64 %t310, %t333
  %t339 = bitcast i32* %t313 to i8*
  call i8* @memcpy(i8* %t335, i8* %t339, i64 %t338)
  call void @free(i8* %t339)
  br label %table_push_after_copy_69
table_push_after_copy_69:
  store i32* %t336, i32** %t312
  %t340 = getelementptr i8*, i8** null, i32 1
  %t341 = ptrtoint i8** %t340 to i64
  %t342 = mul i64 %t331, %t341
  %t343 = call i8* @malloc(i64 %t342)
  %t344 = bitcast i8* %t343 to i8**
  %t345 = icmp sgt i64 %t327, 0
  br i1 %t345, label %table_push_copy_70, label %table_push_after_copy_71
table_push_copy_70:
  %t346 = mul i64 %t310, %t341
  %t347 = bitcast i8** %t315 to i8*
  call i8* @memcpy(i8* %t343, i8* %t347, i64 %t346)
  call void @free(i8* %t347)
  br label %table_push_after_copy_71
table_push_after_copy_71:
  store i8** %t344, i8*** %t314
  store i64 %t331, i64* %t311
  br label %table_push_store_67
table_push_store_67:
  %t348 = load i32*, i32** %t312
  %t349 = extractvalue %Item %t326, 0
  %t350 = getelementptr inbounds i32, i32* %t348, i64 %t310
  store i32 %t349, i32* %t350
  %t351 = load i8**, i8*** %t314
  %t352 = extractvalue %Item %t326, 1
  %t353 = getelementptr inbounds i8*, i8** %t351, i64 %t310
  store i8* %t352, i8** %t353
  %t354 = add i64 %t310, 1
  store i64 %t354, i64* %t309
  %t355 = load i32, i32* %t249
  %t356 = add i32 %t355, 1
  store i32 %t356, i32* %t249
  br label %while_cond_51
while_else_53:
  br label %while_end_54
while_end_54:
  %t357 = load i8*, i8** %t0
  %t358 = icmp eq i8* %t357, null
  br i1 %t358, label %table_read_null_72, label %table_read_real_73
table_read_null_72:
  br label %table_read_end_74
table_read_real_73:
  %t359 = bitcast i8* %t357 to { i64, i64, i32*, i8** }*
  %t360 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t359, i32 0, i32 0
  %t361 = load i64, i64* %t360
  %t362 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t359, i32 0, i32 2
  %t363 = load i32*, i32** %t362
  %t364 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t359, i32 0, i32 3
  %t365 = load i8**, i8*** %t364
  br label %table_read_end_74
table_read_end_74:
  %t366 = phi i64 [ 0, %table_read_null_72 ], [ %t361, %table_read_real_73 ]
  %t367 = phi i32* [ null, %table_read_null_72 ], [ %t363, %table_read_real_73 ]
  %t368 = phi i8** [ null, %table_read_null_72 ], [ %t365, %table_read_real_73 ]
  %t369 = trunc i64 %t366 to i32
  %t370 = load i8*, i8** %t246
  %t371 = icmp eq i8* %t370, null
  br i1 %t371, label %table_read_null_75, label %table_read_real_76
table_read_null_75:
  br label %table_read_end_77
table_read_real_76:
  %t372 = bitcast i8* %t370 to { i64, i64, i32*, i8** }*
  %t373 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t372, i32 0, i32 0
  %t374 = load i64, i64* %t373
  %t375 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t372, i32 0, i32 2
  %t376 = load i32*, i32** %t375
  %t377 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t372, i32 0, i32 3
  %t378 = load i8**, i8*** %t377
  br label %table_read_end_77
table_read_end_77:
  %t379 = phi i64 [ 0, %table_read_null_75 ], [ %t374, %table_read_real_76 ]
  %t380 = phi i32* [ null, %table_read_null_75 ], [ %t376, %table_read_real_76 ]
  %t381 = phi i8** [ null, %table_read_null_75 ], [ %t378, %table_read_real_76 ]
  %t382 = trunc i64 %t379 to i32
  %t383 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t383, i32 %t369, i32 %t382)
  %t384 = load i8*, i8** %t0
  %t385 = icmp eq i8* %t384, null
  br i1 %t385, label %table_read_null_78, label %table_read_real_79
table_read_null_78:
  br label %table_read_end_80
table_read_real_79:
  %t386 = bitcast i8* %t384 to { i64, i64, i32*, i8** }*
  %t387 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t386, i32 0, i32 0
  %t388 = load i64, i64* %t387
  %t389 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t386, i32 0, i32 2
  %t390 = load i32*, i32** %t389
  %t391 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t386, i32 0, i32 3
  %t392 = load i8**, i8*** %t391
  br label %table_read_end_80
table_read_end_80:
  %t393 = phi i64 [ 0, %table_read_null_78 ], [ %t388, %table_read_real_79 ]
  %t394 = phi i32* [ null, %table_read_null_78 ], [ %t390, %table_read_real_79 ]
  %t395 = phi i8** [ null, %table_read_null_78 ], [ %t392, %table_read_real_79 ]
  %t396 = sext i32 0 to i64
  %t397 = alloca %Item
  %t398 = icmp ult i64 %t396, %t393
  br i1 %t398, label %table_idx_ok_81, label %table_idx_oob_82
table_idx_ok_81:
  %t399 = getelementptr inbounds i32, i32* %t394, i64 %t396
  %t400 = load i32, i32* %t399
  %t401 = getelementptr inbounds %Item, %Item* %t397, i32 0, i32 0
  store i32 %t400, i32* %t401
  %t402 = getelementptr inbounds i8*, i8** %t395, i64 %t396
  %t403 = load i8*, i8** %t402
  call void @star_rc_retain(i8* %t403)
  %t404 = load i8*, i8** %t402
  %t405 = getelementptr inbounds %Item, %Item* %t397, i32 0, i32 1
  store i8* %t404, i8** %t405
  br label %table_idx_end_83
table_idx_oob_82:
  store %Item zeroinitializer, %Item* %t397
  br label %table_idx_end_83
table_idx_end_83:
  %t406 = load %Item, %Item* %t397
  %t407 = alloca %Item
  store %Item %t406, %Item* %t407
  %t408 = getelementptr inbounds %Item, %Item* %t407, i32 0, i32 1
  %t409 = load i8*, i8** %t408
  %t410 = load i8*, i8** %t408
  call void @star_rc_retain(i8* %t410)
  call void @star_rc_release(i8* %t409)
  %t411 = load i8*, i8** %t246
  %t412 = icmp eq i8* %t411, null
  br i1 %t412, label %table_read_null_84, label %table_read_real_85
table_read_null_84:
  br label %table_read_end_86
table_read_real_85:
  %t413 = bitcast i8* %t411 to { i64, i64, i32*, i8** }*
  %t414 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t413, i32 0, i32 0
  %t415 = load i64, i64* %t414
  %t416 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t413, i32 0, i32 2
  %t417 = load i32*, i32** %t416
  %t418 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t413, i32 0, i32 3
  %t419 = load i8**, i8*** %t418
  br label %table_read_end_86
table_read_end_86:
  %t420 = phi i64 [ 0, %table_read_null_84 ], [ %t415, %table_read_real_85 ]
  %t421 = phi i32* [ null, %table_read_null_84 ], [ %t417, %table_read_real_85 ]
  %t422 = phi i8** [ null, %table_read_null_84 ], [ %t419, %table_read_real_85 ]
  %t423 = sext i32 0 to i64
  %t424 = alloca %Item
  %t425 = icmp ult i64 %t423, %t420
  br i1 %t425, label %table_idx_ok_87, label %table_idx_oob_88
table_idx_ok_87:
  %t426 = getelementptr inbounds i32, i32* %t421, i64 %t423
  %t427 = load i32, i32* %t426
  %t428 = getelementptr inbounds %Item, %Item* %t424, i32 0, i32 0
  store i32 %t427, i32* %t428
  %t429 = getelementptr inbounds i8*, i8** %t422, i64 %t423
  %t430 = load i8*, i8** %t429
  call void @star_rc_retain(i8* %t430)
  %t431 = load i8*, i8** %t429
  %t432 = getelementptr inbounds %Item, %Item* %t424, i32 0, i32 1
  store i8* %t431, i8** %t432
  br label %table_idx_end_89
table_idx_oob_88:
  store %Item zeroinitializer, %Item* %t424
  br label %table_idx_end_89
table_idx_end_89:
  %t433 = load %Item, %Item* %t424
  %t434 = alloca %Item
  store %Item %t433, %Item* %t434
  %t435 = getelementptr inbounds %Item, %Item* %t434, i32 0, i32 1
  %t436 = load i8*, i8** %t435
  %t437 = load i8*, i8** %t435
  call void @star_rc_retain(i8* %t437)
  call void @star_rc_release(i8* %t436)
  %t438 = getelementptr inbounds [32 x i8], [32 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t438, i8* %t409, i8* %t436)
  %t439 = load i8*, i8** %t0
  %t440 = icmp eq i8* %t439, null
  br i1 %t440, label %table_read_null_90, label %table_read_real_91
table_read_null_90:
  br label %table_read_end_92
table_read_real_91:
  %t441 = bitcast i8* %t439 to { i64, i64, i32*, i8** }*
  %t442 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t441, i32 0, i32 0
  %t443 = load i64, i64* %t442
  %t444 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t441, i32 0, i32 2
  %t445 = load i32*, i32** %t444
  %t446 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t441, i32 0, i32 3
  %t447 = load i8**, i8*** %t446
  br label %table_read_end_92
table_read_end_92:
  %t448 = phi i64 [ 0, %table_read_null_90 ], [ %t443, %table_read_real_91 ]
  %t449 = phi i32* [ null, %table_read_null_90 ], [ %t445, %table_read_real_91 ]
  %t450 = phi i8** [ null, %table_read_null_90 ], [ %t447, %table_read_real_91 ]
  %t451 = sext i32 4999 to i64
  %t452 = alloca %Item
  %t453 = icmp ult i64 %t451, %t448
  br i1 %t453, label %table_idx_ok_93, label %table_idx_oob_94
table_idx_ok_93:
  %t454 = getelementptr inbounds i32, i32* %t449, i64 %t451
  %t455 = load i32, i32* %t454
  %t456 = getelementptr inbounds %Item, %Item* %t452, i32 0, i32 0
  store i32 %t455, i32* %t456
  %t457 = getelementptr inbounds i8*, i8** %t450, i64 %t451
  %t458 = load i8*, i8** %t457
  call void @star_rc_retain(i8* %t458)
  %t459 = load i8*, i8** %t457
  %t460 = getelementptr inbounds %Item, %Item* %t452, i32 0, i32 1
  store i8* %t459, i8** %t460
  br label %table_idx_end_95
table_idx_oob_94:
  store %Item zeroinitializer, %Item* %t452
  br label %table_idx_end_95
table_idx_end_95:
  %t461 = load %Item, %Item* %t452
  %t462 = alloca %Item
  store %Item %t461, %Item* %t462
  %t463 = getelementptr inbounds %Item, %Item* %t462, i32 0, i32 1
  %t464 = load i8*, i8** %t463
  %t465 = load i8*, i8** %t463
  call void @star_rc_retain(i8* %t465)
  call void @star_rc_release(i8* %t464)
  %t466 = load i8*, i8** %t246
  %t467 = icmp eq i8* %t466, null
  br i1 %t467, label %table_read_null_96, label %table_read_real_97
table_read_null_96:
  br label %table_read_end_98
table_read_real_97:
  %t468 = bitcast i8* %t466 to { i64, i64, i32*, i8** }*
  %t469 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t468, i32 0, i32 0
  %t470 = load i64, i64* %t469
  %t471 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t468, i32 0, i32 2
  %t472 = load i32*, i32** %t471
  %t473 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t468, i32 0, i32 3
  %t474 = load i8**, i8*** %t473
  br label %table_read_end_98
table_read_end_98:
  %t475 = phi i64 [ 0, %table_read_null_96 ], [ %t470, %table_read_real_97 ]
  %t476 = phi i32* [ null, %table_read_null_96 ], [ %t472, %table_read_real_97 ]
  %t477 = phi i8** [ null, %table_read_null_96 ], [ %t474, %table_read_real_97 ]
  %t478 = sext i32 4999 to i64
  %t479 = alloca %Item
  %t480 = icmp ult i64 %t478, %t475
  br i1 %t480, label %table_idx_ok_99, label %table_idx_oob_100
table_idx_ok_99:
  %t481 = getelementptr inbounds i32, i32* %t476, i64 %t478
  %t482 = load i32, i32* %t481
  %t483 = getelementptr inbounds %Item, %Item* %t479, i32 0, i32 0
  store i32 %t482, i32* %t483
  %t484 = getelementptr inbounds i8*, i8** %t477, i64 %t478
  %t485 = load i8*, i8** %t484
  call void @star_rc_retain(i8* %t485)
  %t486 = load i8*, i8** %t484
  %t487 = getelementptr inbounds %Item, %Item* %t479, i32 0, i32 1
  store i8* %t486, i8** %t487
  br label %table_idx_end_101
table_idx_oob_100:
  store %Item zeroinitializer, %Item* %t479
  br label %table_idx_end_101
table_idx_end_101:
  %t488 = load %Item, %Item* %t479
  %t489 = alloca %Item
  store %Item %t488, %Item* %t489
  %t490 = getelementptr inbounds %Item, %Item* %t489, i32 0, i32 1
  %t491 = load i8*, i8** %t490
  %t492 = load i8*, i8** %t490
  call void @star_rc_retain(i8* %t492)
  call void @star_rc_release(i8* %t491)
  %t493 = getelementptr inbounds [38 x i8], [38 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t493, i8* %t464, i8* %t491)
  %t494 = alloca i8*
  store i8* null, i8** %t494
  %t495 = alloca i32
  store i32 0, i32* %t495
  br label %while_cond_102
while_cond_102:
  %t496 = load i32, i32* %t495
  %t497 = icmp slt i32 %t496, 3000
  br i1 %t497, label %while_body_103, label %while_else_104
while_body_103:
  %t498 = load i8*, i8** %t494
  %t499 = icmp eq i8* %t498, null
  br i1 %t499, label %table_cow_alloc_106, label %table_cow_check_107
table_cow_alloc_106:
  %t500 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t501 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t502 = ptrtoint { i64, i64, i32*, i8** }* %t501 to i64
  %t503 = call i8* @star_rc_alloc(i64 %t502, i8* %t500)
  %t504 = bitcast i8* %t503 to { i64, i64, i32*, i8** }*
  %t505 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t504, i32 0, i32 0
  store i64 0, i64* %t505
  %t506 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t504, i32 0, i32 1
  store i64 0, i64* %t506
  %t507 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t504, i32 0, i32 2
  store i32* null, i32** %t507
  %t508 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t504, i32 0, i32 3
  store i8** null, i8*** %t508
  store i8* %t503, i8** %t494
  br label %table_cow_done_108
table_cow_check_107:
  %t509 = getelementptr inbounds i8, i8* %t498, i64 -16
  %t510 = bitcast i8* %t509 to i64*
  %t511 = load atomic i64, i64* %t510 seq_cst, align 8
  %t512 = icmp eq i64 %t511, 1
  br i1 %t512, label %table_cow_done_108, label %table_cow_clone_109
table_cow_clone_109:
  %t513 = bitcast i8* %t498 to { i64, i64, i32*, i8** }*
  %t514 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t513, i32 0, i32 0
  %t515 = load i64, i64* %t514
  %t516 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t513, i32 0, i32 1
  %t517 = load i64, i64* %t516
  %t518 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t519 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t520 = ptrtoint { i64, i64, i32*, i8** }* %t519 to i64
  %t521 = call i8* @star_rc_alloc(i64 %t520, i8* %t518)
  %t522 = bitcast i8* %t521 to { i64, i64, i32*, i8** }*
  %t523 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t522, i32 0, i32 0
  store i64 %t515, i64* %t523
  %t524 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t522, i32 0, i32 1
  store i64 %t517, i64* %t524
  %t525 = getelementptr i32, i32* null, i32 1
  %t526 = ptrtoint i32* %t525 to i64
  %t527 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t513, i32 0, i32 2
  %t528 = load i32*, i32** %t527
  %t529 = mul i64 %t517, %t526
  %t530 = call i8* @malloc(i64 %t529)
  %t531 = bitcast i8* %t530 to i32*
  %t532 = icmp sgt i64 %t515, 0
  br i1 %t532, label %table_cow_copy_110, label %table_cow_after_copy_111
table_cow_copy_110:
  %t533 = mul i64 %t515, %t526
  %t534 = bitcast i32* %t528 to i8*
  call i8* @memcpy(i8* %t530, i8* %t534, i64 %t533)
  br label %table_cow_after_copy_111
table_cow_after_copy_111:
  %t535 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t522, i32 0, i32 2
  store i32* %t531, i32** %t535
  %t536 = getelementptr i8*, i8** null, i32 1
  %t537 = ptrtoint i8** %t536 to i64
  %t538 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t513, i32 0, i32 3
  %t539 = load i8**, i8*** %t538
  %t540 = mul i64 %t517, %t537
  %t541 = call i8* @malloc(i64 %t540)
  %t542 = bitcast i8* %t541 to i8**
  %t543 = icmp sgt i64 %t515, 0
  br i1 %t543, label %table_cow_copy_112, label %table_cow_after_copy_113
table_cow_copy_112:
  %t544 = mul i64 %t515, %t537
  %t545 = bitcast i8** %t539 to i8*
  call i8* @memcpy(i8* %t541, i8* %t545, i64 %t544)
  %t546 = alloca i64
  store i64 0, i64* %t546
  br label %table_cow_retain_cond_114
table_cow_retain_cond_114:
  %t547 = load i64, i64* %t546
  %t548 = icmp slt i64 %t547, %t515
  br i1 %t548, label %table_cow_retain_body_115, label %table_cow_retain_end_116
table_cow_retain_body_115:
  %t549 = getelementptr inbounds i8*, i8** %t542, i64 %t547
  %t550 = load i8*, i8** %t549
  call void @star_rc_retain(i8* %t550)
  %t551 = add i64 %t547, 1
  store i64 %t551, i64* %t546
  br label %table_cow_retain_cond_114
table_cow_retain_end_116:
  br label %table_cow_after_copy_113
table_cow_after_copy_113:
  %t552 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t522, i32 0, i32 3
  store i8** %t542, i8*** %t552
  call void @star_rc_release(i8* %t498)
  store i8* %t521, i8** %t494
  br label %table_cow_done_108
table_cow_done_108:
  %t553 = load i8*, i8** %t494
  %t554 = bitcast i8* %t553 to { i64, i64, i32*, i8** }*
  %t555 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t554, i32 0, i32 0
  %t556 = load i64, i64* %t555
  %t557 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t554, i32 0, i32 1
  %t558 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t554, i32 0, i32 2
  %t559 = load i32*, i32** %t558
  %t560 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t554, i32 0, i32 3
  %t561 = load i8**, i8*** %t560
  %t562 = alloca %Item
  %t563 = load i32, i32* %t495
  %t564 = getelementptr inbounds %Item, %Item* %t562, i32 0, i32 0
  store i32 %t563, i32* %t564
  %t565 = load i32, i32* %t495
  %t566 = getelementptr inbounds [7 x i8], [7 x i8]* @.str.8, i64 0, i64 0
  %t567 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t566, i32 %t565)
  %t568 = add i32 %t567, 1
  %t569 = sext i32 %t568 to i64
  %t570 = call i8* @star_rc_alloc(i64 %t569, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t570, i64 %t569, i8* %t566, i32 %t565)
  %t571 = getelementptr inbounds %Item, %Item* %t562, i32 0, i32 1
  store i8* %t570, i8** %t571
  %t572 = load %Item, %Item* %t562
  %t573 = load i64, i64* %t557
  %t574 = icmp sge i64 %t556, %t573
  br i1 %t574, label %table_push_grow_117, label %table_push_store_118
table_push_grow_117:
  %t575 = mul i64 %t573, 2
  %t576 = icmp sgt i64 %t575, 0
  %t577 = select i1 %t576, i64 %t575, i64 1
  %t578 = getelementptr i32, i32* null, i32 1
  %t579 = ptrtoint i32* %t578 to i64
  %t580 = mul i64 %t577, %t579
  %t581 = call i8* @malloc(i64 %t580)
  %t582 = bitcast i8* %t581 to i32*
  %t583 = icmp sgt i64 %t573, 0
  br i1 %t583, label %table_push_copy_119, label %table_push_after_copy_120
table_push_copy_119:
  %t584 = mul i64 %t556, %t579
  %t585 = bitcast i32* %t559 to i8*
  call i8* @memcpy(i8* %t581, i8* %t585, i64 %t584)
  call void @free(i8* %t585)
  br label %table_push_after_copy_120
table_push_after_copy_120:
  store i32* %t582, i32** %t558
  %t586 = getelementptr i8*, i8** null, i32 1
  %t587 = ptrtoint i8** %t586 to i64
  %t588 = mul i64 %t577, %t587
  %t589 = call i8* @malloc(i64 %t588)
  %t590 = bitcast i8* %t589 to i8**
  %t591 = icmp sgt i64 %t573, 0
  br i1 %t591, label %table_push_copy_121, label %table_push_after_copy_122
table_push_copy_121:
  %t592 = mul i64 %t556, %t587
  %t593 = bitcast i8** %t561 to i8*
  call i8* @memcpy(i8* %t589, i8* %t593, i64 %t592)
  call void @free(i8* %t593)
  br label %table_push_after_copy_122
table_push_after_copy_122:
  store i8** %t590, i8*** %t560
  store i64 %t577, i64* %t557
  br label %table_push_store_118
table_push_store_118:
  %t594 = load i32*, i32** %t558
  %t595 = extractvalue %Item %t572, 0
  %t596 = getelementptr inbounds i32, i32* %t594, i64 %t556
  store i32 %t595, i32* %t596
  %t597 = load i8**, i8*** %t560
  %t598 = extractvalue %Item %t572, 1
  %t599 = getelementptr inbounds i8*, i8** %t597, i64 %t556
  store i8* %t598, i8** %t599
  %t600 = add i64 %t556, 1
  store i64 %t600, i64* %t555
  %t601 = load i32, i32* %t495
  %t602 = icmp eq i32 3, 0
  %t603 = icmp eq i32 %t601, -2147483648
  %t604 = icmp eq i32 3, -1
  %t605 = and i1 %t603, %t604
  %t606 = or i1 %t602, %t605
  br i1 %t606, label %int_div_fail_123, label %int_div_ok_124
int_div_fail_123:
  %t607 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.9, i64 0, i64 0
  call i32 @puts(i8* %t607)
  call void @exit(i32 1)
  unreachable
int_div_ok_124:
  %t608 = srem i32 %t601, 3
  %t609 = icmp eq i32 %t608, 0
  br i1 %t609, label %if_then_125, label %if_else_126
if_then_125:
  %t610 = alloca %Item
  %t611 = load i8*, i8** %t494
  %t612 = icmp eq i8* %t611, null
  br i1 %t612, label %table_cow_alloc_128, label %table_cow_check_129
table_cow_alloc_128:
  %t613 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t614 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t615 = ptrtoint { i64, i64, i32*, i8** }* %t614 to i64
  %t616 = call i8* @star_rc_alloc(i64 %t615, i8* %t613)
  %t617 = bitcast i8* %t616 to { i64, i64, i32*, i8** }*
  %t618 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t617, i32 0, i32 0
  store i64 0, i64* %t618
  %t619 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t617, i32 0, i32 1
  store i64 0, i64* %t619
  %t620 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t617, i32 0, i32 2
  store i32* null, i32** %t620
  %t621 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t617, i32 0, i32 3
  store i8** null, i8*** %t621
  store i8* %t616, i8** %t494
  br label %table_cow_done_130
table_cow_check_129:
  %t622 = getelementptr inbounds i8, i8* %t611, i64 -16
  %t623 = bitcast i8* %t622 to i64*
  %t624 = load atomic i64, i64* %t623 seq_cst, align 8
  %t625 = icmp eq i64 %t624, 1
  br i1 %t625, label %table_cow_done_130, label %table_cow_clone_131
table_cow_clone_131:
  %t626 = bitcast i8* %t611 to { i64, i64, i32*, i8** }*
  %t627 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t626, i32 0, i32 0
  %t628 = load i64, i64* %t627
  %t629 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t626, i32 0, i32 1
  %t630 = load i64, i64* %t629
  %t631 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t632 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t633 = ptrtoint { i64, i64, i32*, i8** }* %t632 to i64
  %t634 = call i8* @star_rc_alloc(i64 %t633, i8* %t631)
  %t635 = bitcast i8* %t634 to { i64, i64, i32*, i8** }*
  %t636 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t635, i32 0, i32 0
  store i64 %t628, i64* %t636
  %t637 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t635, i32 0, i32 1
  store i64 %t630, i64* %t637
  %t638 = getelementptr i32, i32* null, i32 1
  %t639 = ptrtoint i32* %t638 to i64
  %t640 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t626, i32 0, i32 2
  %t641 = load i32*, i32** %t640
  %t642 = mul i64 %t630, %t639
  %t643 = call i8* @malloc(i64 %t642)
  %t644 = bitcast i8* %t643 to i32*
  %t645 = icmp sgt i64 %t628, 0
  br i1 %t645, label %table_cow_copy_132, label %table_cow_after_copy_133
table_cow_copy_132:
  %t646 = mul i64 %t628, %t639
  %t647 = bitcast i32* %t641 to i8*
  call i8* @memcpy(i8* %t643, i8* %t647, i64 %t646)
  br label %table_cow_after_copy_133
table_cow_after_copy_133:
  %t648 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t635, i32 0, i32 2
  store i32* %t644, i32** %t648
  %t649 = getelementptr i8*, i8** null, i32 1
  %t650 = ptrtoint i8** %t649 to i64
  %t651 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t626, i32 0, i32 3
  %t652 = load i8**, i8*** %t651
  %t653 = mul i64 %t630, %t650
  %t654 = call i8* @malloc(i64 %t653)
  %t655 = bitcast i8* %t654 to i8**
  %t656 = icmp sgt i64 %t628, 0
  br i1 %t656, label %table_cow_copy_134, label %table_cow_after_copy_135
table_cow_copy_134:
  %t657 = mul i64 %t628, %t650
  %t658 = bitcast i8** %t652 to i8*
  call i8* @memcpy(i8* %t654, i8* %t658, i64 %t657)
  %t659 = alloca i64
  store i64 0, i64* %t659
  br label %table_cow_retain_cond_136
table_cow_retain_cond_136:
  %t660 = load i64, i64* %t659
  %t661 = icmp slt i64 %t660, %t628
  br i1 %t661, label %table_cow_retain_body_137, label %table_cow_retain_end_138
table_cow_retain_body_137:
  %t662 = getelementptr inbounds i8*, i8** %t655, i64 %t660
  %t663 = load i8*, i8** %t662
  call void @star_rc_retain(i8* %t663)
  %t664 = add i64 %t660, 1
  store i64 %t664, i64* %t659
  br label %table_cow_retain_cond_136
table_cow_retain_end_138:
  br label %table_cow_after_copy_135
table_cow_after_copy_135:
  %t665 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t635, i32 0, i32 3
  store i8** %t655, i8*** %t665
  call void @star_rc_release(i8* %t611)
  store i8* %t634, i8** %t494
  br label %table_cow_done_130
table_cow_done_130:
  %t666 = load i8*, i8** %t494
  %t667 = bitcast i8* %t666 to { i64, i64, i32*, i8** }*
  %t668 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t667, i32 0, i32 0
  %t669 = load i64, i64* %t668
  %t670 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t667, i32 0, i32 1
  %t671 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t667, i32 0, i32 2
  %t672 = load i32*, i32** %t671
  %t673 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t667, i32 0, i32 3
  %t674 = load i8**, i8*** %t673
  %t675 = alloca %Item
  %t676 = icmp eq i64 %t669, 0
  br i1 %t676, label %table_pop_empty_139, label %table_pop_nonempty_140
table_pop_nonempty_140:
  %t677 = sub i64 %t669, 1
  store i64 %t677, i64* %t668
  %t678 = getelementptr inbounds i32, i32* %t672, i64 %t677
  %t679 = load i32, i32* %t678
  %t680 = getelementptr inbounds %Item, %Item* %t675, i32 0, i32 0
  store i32 %t679, i32* %t680
  %t681 = getelementptr inbounds i8*, i8** %t674, i64 %t677
  %t682 = load i8*, i8** %t681
  %t683 = getelementptr inbounds %Item, %Item* %t675, i32 0, i32 1
  store i8* %t682, i8** %t683
  br label %table_pop_end_141
table_pop_empty_139:
  store %Item zeroinitializer, %Item* %t675
  br label %table_pop_end_141
table_pop_end_141:
  %t684 = load %Item, %Item* %t675
  store %Item %t684, %Item* %t610
  %t685 = getelementptr inbounds %Item, %Item* %t610, i32 0, i32 1
  %t686 = load i8*, i8** %t685
  %t687 = load i8*, i8** %t685
  call void @star_rc_retain(i8* %t687)
  call void @star_rc_release(i8* %t686)
  %t688 = call i32 @strlen(i8* %t686)
  %t689 = icmp eq i32 %t688, 0
  br i1 %t689, label %if_then_142, label %if_else_143
if_then_142:
  %t690 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.10, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t690)
  %t691 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t691)
  br label %if_end_144
if_else_143:
  br label %if_end_144
if_end_144:
  %t692 = getelementptr inbounds %Item, %Item* %t610, i32 0, i32 1
  %t693 = load i8*, i8** %t692
  call void @star_rc_release(i8* %t693)
  br label %if_end_127
if_else_126:
  br label %if_end_127
if_end_127:
  %t694 = load i32, i32* %t495
  %t695 = add i32 %t694, 1
  store i32 %t695, i32* %t495
  br label %while_cond_102
while_else_104:
  br label %while_end_105
while_end_105:
  %t696 = load i8*, i8** %t494
  %t697 = icmp eq i8* %t696, null
  br i1 %t697, label %table_read_null_145, label %table_read_real_146
table_read_null_145:
  br label %table_read_end_147
table_read_real_146:
  %t698 = bitcast i8* %t696 to { i64, i64, i32*, i8** }*
  %t699 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t698, i32 0, i32 0
  %t700 = load i64, i64* %t699
  %t701 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t698, i32 0, i32 2
  %t702 = load i32*, i32** %t701
  %t703 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t698, i32 0, i32 3
  %t704 = load i8**, i8*** %t703
  br label %table_read_end_147
table_read_end_147:
  %t705 = phi i64 [ 0, %table_read_null_145 ], [ %t700, %table_read_real_146 ]
  %t706 = phi i32* [ null, %table_read_null_145 ], [ %t702, %table_read_real_146 ]
  %t707 = phi i8** [ null, %table_read_null_145 ], [ %t704, %table_read_real_146 ]
  %t708 = trunc i64 %t705 to i32
  %t709 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t709, i32 %t708)
  %t710 = load i8*, i8** %t494
  call void @star_rc_release(i8* %t710)
  %t711 = load i8*, i8** %t246
  call void @star_rc_release(i8* %t711)
  %t712 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t712)
  ret i32 0
}


; par/swarm worker functions
define void @table_release_s_Item(i8* %objp) {
entry:
  %t6 = bitcast i8* %objp to { i64, i64, i32*, i8** }*
  %t7 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t6, i32 0, i32 0
  %t8 = load i64, i64* %t7
  %t9 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t6, i32 0, i32 2
  %t10 = load i32*, i32** %t9
  %t11 = bitcast i32* %t10 to i8*
  call void @free(i8* %t11)
  %t12 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t6, i32 0, i32 3
  %t13 = load i8**, i8*** %t12
  %t14 = alloca i64
  store i64 0, i64* %t14
  br label %table_release_cond_7
table_release_cond_7:
  %t15 = load i64, i64* %t14
  %t16 = icmp slt i64 %t15, %t8
  br i1 %t16, label %table_release_body_8, label %table_release_end_9
table_release_body_8:
  %t17 = getelementptr inbounds i8*, i8** %t13, i64 %t15
  %t18 = load i8*, i8** %t17
  call void @star_rc_release(i8* %t18)
  %t19 = add i64 %t15, 1
  store i64 %t19, i64* %t14
  br label %table_release_cond_7
table_release_end_9:
  %t20 = bitcast i8** %t13 to i8*
  call void @free(i8* %t20)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant [7 x i8] c"tag-%d\00"
@.str.1 = private unnamed_addr constant [10 x i8] c"len = %d\0A\00"
@.str.2 = private unnamed_addr constant [17 x i8] c"t[0] = %s hp=%d\0A\00"
@.str.3 = private unnamed_addr constant [20 x i8] c"t[4999] = %s hp=%d\0A\00"
@.str.4 = private unnamed_addr constant [9 x i8] c"clone-%d\00"
@.str.5 = private unnamed_addr constant [34 x i8] c"original len = %d clone len = %d\0A\00"
@.str.6 = private unnamed_addr constant [32 x i8] c"original[0] = %s clone[0] = %s\0A\00"
@.str.7 = private unnamed_addr constant [38 x i8] c"original[4999] = %s clone[4999] = %s\0A\00"
@.str.8 = private unnamed_addr constant [7 x i8] c"cyc-%d\00"
@.str.9 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.10 = private unnamed_addr constant { i64, i8*, [21 x i8] } { i64 -1, i8* null, [21 x i8] c"unexpected empty pop\00" }
@.str.11 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.12 = private unnamed_addr constant [17 x i8] c"cycler len = %d\0A\00"
