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

%Enemy = type { i32, i8* }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = alloca i8*
  store i8* null, i8** %t0
  %t1 = load i8*, i8** %t0
  %t2 = icmp eq i8* %t1, null
  br i1 %t2, label %table_read_null_0, label %table_read_real_1
table_read_null_0:
  br label %table_read_end_2
table_read_real_1:
  %t3 = bitcast i8* %t1 to { i64, i64, i32*, i8** }*
  %t4 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t3, i32 0, i32 0
  %t5 = load i64, i64* %t4
  %t6 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t3, i32 0, i32 2
  %t7 = load i32*, i32** %t6
  %t8 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t3, i32 0, i32 3
  %t9 = load i8**, i8*** %t8
  br label %table_read_end_2
table_read_end_2:
  %t10 = phi i64 [ 0, %table_read_null_0 ], [ %t5, %table_read_real_1 ]
  %t11 = phi i32* [ null, %table_read_null_0 ], [ %t7, %table_read_real_1 ]
  %t12 = phi i8** [ null, %table_read_null_0 ], [ %t9, %table_read_real_1 ]
  %t13 = trunc i64 %t10 to i32
  %t14 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t14, i32 %t13)
  %t15 = load i8*, i8** %t0
  %t16 = icmp eq i8* %t15, null
  br i1 %t16, label %table_cow_alloc_3, label %table_cow_check_4
table_cow_alloc_3:
  %t32 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t33 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t34 = ptrtoint { i64, i64, i32*, i8** }* %t33 to i64
  %t35 = call i8* @star_rc_alloc(i64 %t34, i8* %t32)
  %t36 = bitcast i8* %t35 to { i64, i64, i32*, i8** }*
  %t37 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t36, i32 0, i32 0
  store i64 0, i64* %t37
  %t38 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t36, i32 0, i32 1
  store i64 0, i64* %t38
  %t39 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t36, i32 0, i32 2
  store i32* null, i32** %t39
  %t40 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t36, i32 0, i32 3
  store i8** null, i8*** %t40
  store i8* %t35, i8** %t0
  br label %table_cow_done_5
table_cow_check_4:
  %t41 = getelementptr inbounds i8, i8* %t15, i64 -16
  %t42 = bitcast i8* %t41 to i64*
  %t43 = load atomic i64, i64* %t42 seq_cst, align 8
  %t44 = icmp eq i64 %t43, 1
  br i1 %t44, label %table_cow_done_5, label %table_cow_clone_9
table_cow_clone_9:
  %t45 = bitcast i8* %t15 to { i64, i64, i32*, i8** }*
  %t46 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t45, i32 0, i32 0
  %t47 = load i64, i64* %t46
  %t48 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t45, i32 0, i32 1
  %t49 = load i64, i64* %t48
  %t50 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t51 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t52 = ptrtoint { i64, i64, i32*, i8** }* %t51 to i64
  %t53 = call i8* @star_rc_alloc(i64 %t52, i8* %t50)
  %t54 = bitcast i8* %t53 to { i64, i64, i32*, i8** }*
  %t55 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t54, i32 0, i32 0
  store i64 %t47, i64* %t55
  %t56 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t54, i32 0, i32 1
  store i64 %t49, i64* %t56
  %t57 = getelementptr i32, i32* null, i32 1
  %t58 = ptrtoint i32* %t57 to i64
  %t59 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t45, i32 0, i32 2
  %t60 = load i32*, i32** %t59
  %t61 = mul i64 %t49, %t58
  %t62 = call i8* @malloc(i64 %t61)
  %t63 = bitcast i8* %t62 to i32*
  %t64 = icmp sgt i64 %t47, 0
  br i1 %t64, label %table_cow_copy_10, label %table_cow_after_copy_11
table_cow_copy_10:
  %t65 = mul i64 %t47, %t58
  %t66 = bitcast i32* %t60 to i8*
  call i8* @memcpy(i8* %t62, i8* %t66, i64 %t65)
  br label %table_cow_after_copy_11
table_cow_after_copy_11:
  %t67 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t54, i32 0, i32 2
  store i32* %t63, i32** %t67
  %t68 = getelementptr i8*, i8** null, i32 1
  %t69 = ptrtoint i8** %t68 to i64
  %t70 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t45, i32 0, i32 3
  %t71 = load i8**, i8*** %t70
  %t72 = mul i64 %t49, %t69
  %t73 = call i8* @malloc(i64 %t72)
  %t74 = bitcast i8* %t73 to i8**
  %t75 = icmp sgt i64 %t47, 0
  br i1 %t75, label %table_cow_copy_12, label %table_cow_after_copy_13
table_cow_copy_12:
  %t76 = mul i64 %t47, %t69
  %t77 = bitcast i8** %t71 to i8*
  call i8* @memcpy(i8* %t73, i8* %t77, i64 %t76)
  %t78 = alloca i64
  store i64 0, i64* %t78
  br label %table_cow_retain_cond_14
table_cow_retain_cond_14:
  %t79 = load i64, i64* %t78
  %t80 = icmp slt i64 %t79, %t47
  br i1 %t80, label %table_cow_retain_body_15, label %table_cow_retain_end_16
table_cow_retain_body_15:
  %t81 = getelementptr inbounds i8*, i8** %t74, i64 %t79
  %t82 = load i8*, i8** %t81
  call void @star_rc_retain(i8* %t82)
  %t83 = add i64 %t79, 1
  store i64 %t83, i64* %t78
  br label %table_cow_retain_cond_14
table_cow_retain_end_16:
  br label %table_cow_after_copy_13
table_cow_after_copy_13:
  %t84 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t54, i32 0, i32 3
  store i8** %t74, i8*** %t84
  call void @star_rc_release(i8* %t15)
  store i8* %t53, i8** %t0
  br label %table_cow_done_5
table_cow_done_5:
  %t85 = load i8*, i8** %t0
  %t86 = bitcast i8* %t85 to { i64, i64, i32*, i8** }*
  %t87 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t86, i32 0, i32 0
  %t88 = load i64, i64* %t87
  %t89 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t86, i32 0, i32 1
  %t90 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t86, i32 0, i32 2
  %t91 = load i32*, i32** %t90
  %t92 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t86, i32 0, i32 3
  %t93 = load i8**, i8*** %t92
  %t94 = alloca %Enemy
  %t95 = getelementptr inbounds %Enemy, %Enemy* %t94, i32 0, i32 0
  store i32 10, i32* %t95
  %t96 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t97 = getelementptr inbounds %Enemy, %Enemy* %t94, i32 0, i32 1
  store i8* %t96, i8** %t97
  %t98 = load %Enemy, %Enemy* %t94
  %t99 = load i64, i64* %t89
  %t100 = icmp sge i64 %t88, %t99
  br i1 %t100, label %table_push_grow_17, label %table_push_store_18
table_push_grow_17:
  %t101 = mul i64 %t99, 2
  %t102 = icmp sgt i64 %t101, 0
  %t103 = select i1 %t102, i64 %t101, i64 1
  %t104 = getelementptr i32, i32* null, i32 1
  %t105 = ptrtoint i32* %t104 to i64
  %t106 = mul i64 %t103, %t105
  %t107 = call i8* @malloc(i64 %t106)
  %t108 = bitcast i8* %t107 to i32*
  %t109 = icmp sgt i64 %t99, 0
  br i1 %t109, label %table_push_copy_19, label %table_push_after_copy_20
table_push_copy_19:
  %t110 = mul i64 %t88, %t105
  %t111 = bitcast i32* %t91 to i8*
  call i8* @memcpy(i8* %t107, i8* %t111, i64 %t110)
  call void @free(i8* %t111)
  br label %table_push_after_copy_20
table_push_after_copy_20:
  store i32* %t108, i32** %t90
  %t112 = getelementptr i8*, i8** null, i32 1
  %t113 = ptrtoint i8** %t112 to i64
  %t114 = mul i64 %t103, %t113
  %t115 = call i8* @malloc(i64 %t114)
  %t116 = bitcast i8* %t115 to i8**
  %t117 = icmp sgt i64 %t99, 0
  br i1 %t117, label %table_push_copy_21, label %table_push_after_copy_22
table_push_copy_21:
  %t118 = mul i64 %t88, %t113
  %t119 = bitcast i8** %t93 to i8*
  call i8* @memcpy(i8* %t115, i8* %t119, i64 %t118)
  call void @free(i8* %t119)
  br label %table_push_after_copy_22
table_push_after_copy_22:
  store i8** %t116, i8*** %t92
  store i64 %t103, i64* %t89
  br label %table_push_store_18
table_push_store_18:
  %t120 = load i32*, i32** %t90
  %t121 = extractvalue %Enemy %t98, 0
  %t122 = getelementptr inbounds i32, i32* %t120, i64 %t88
  store i32 %t121, i32* %t122
  %t123 = load i8**, i8*** %t92
  %t124 = extractvalue %Enemy %t98, 1
  %t125 = getelementptr inbounds i8*, i8** %t123, i64 %t88
  store i8* %t124, i8** %t125
  %t126 = add i64 %t88, 1
  store i64 %t126, i64* %t87
  %t127 = load i8*, i8** %t0
  %t128 = icmp eq i8* %t127, null
  br i1 %t128, label %table_cow_alloc_23, label %table_cow_check_24
table_cow_alloc_23:
  %t129 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t130 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t131 = ptrtoint { i64, i64, i32*, i8** }* %t130 to i64
  %t132 = call i8* @star_rc_alloc(i64 %t131, i8* %t129)
  %t133 = bitcast i8* %t132 to { i64, i64, i32*, i8** }*
  %t134 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t133, i32 0, i32 0
  store i64 0, i64* %t134
  %t135 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t133, i32 0, i32 1
  store i64 0, i64* %t135
  %t136 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t133, i32 0, i32 2
  store i32* null, i32** %t136
  %t137 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t133, i32 0, i32 3
  store i8** null, i8*** %t137
  store i8* %t132, i8** %t0
  br label %table_cow_done_25
table_cow_check_24:
  %t138 = getelementptr inbounds i8, i8* %t127, i64 -16
  %t139 = bitcast i8* %t138 to i64*
  %t140 = load atomic i64, i64* %t139 seq_cst, align 8
  %t141 = icmp eq i64 %t140, 1
  br i1 %t141, label %table_cow_done_25, label %table_cow_clone_26
table_cow_clone_26:
  %t142 = bitcast i8* %t127 to { i64, i64, i32*, i8** }*
  %t143 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t142, i32 0, i32 0
  %t144 = load i64, i64* %t143
  %t145 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t142, i32 0, i32 1
  %t146 = load i64, i64* %t145
  %t147 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t148 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t149 = ptrtoint { i64, i64, i32*, i8** }* %t148 to i64
  %t150 = call i8* @star_rc_alloc(i64 %t149, i8* %t147)
  %t151 = bitcast i8* %t150 to { i64, i64, i32*, i8** }*
  %t152 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t151, i32 0, i32 0
  store i64 %t144, i64* %t152
  %t153 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t151, i32 0, i32 1
  store i64 %t146, i64* %t153
  %t154 = getelementptr i32, i32* null, i32 1
  %t155 = ptrtoint i32* %t154 to i64
  %t156 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t142, i32 0, i32 2
  %t157 = load i32*, i32** %t156
  %t158 = mul i64 %t146, %t155
  %t159 = call i8* @malloc(i64 %t158)
  %t160 = bitcast i8* %t159 to i32*
  %t161 = icmp sgt i64 %t144, 0
  br i1 %t161, label %table_cow_copy_27, label %table_cow_after_copy_28
table_cow_copy_27:
  %t162 = mul i64 %t144, %t155
  %t163 = bitcast i32* %t157 to i8*
  call i8* @memcpy(i8* %t159, i8* %t163, i64 %t162)
  br label %table_cow_after_copy_28
table_cow_after_copy_28:
  %t164 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t151, i32 0, i32 2
  store i32* %t160, i32** %t164
  %t165 = getelementptr i8*, i8** null, i32 1
  %t166 = ptrtoint i8** %t165 to i64
  %t167 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t142, i32 0, i32 3
  %t168 = load i8**, i8*** %t167
  %t169 = mul i64 %t146, %t166
  %t170 = call i8* @malloc(i64 %t169)
  %t171 = bitcast i8* %t170 to i8**
  %t172 = icmp sgt i64 %t144, 0
  br i1 %t172, label %table_cow_copy_29, label %table_cow_after_copy_30
table_cow_copy_29:
  %t173 = mul i64 %t144, %t166
  %t174 = bitcast i8** %t168 to i8*
  call i8* @memcpy(i8* %t170, i8* %t174, i64 %t173)
  %t175 = alloca i64
  store i64 0, i64* %t175
  br label %table_cow_retain_cond_31
table_cow_retain_cond_31:
  %t176 = load i64, i64* %t175
  %t177 = icmp slt i64 %t176, %t144
  br i1 %t177, label %table_cow_retain_body_32, label %table_cow_retain_end_33
table_cow_retain_body_32:
  %t178 = getelementptr inbounds i8*, i8** %t171, i64 %t176
  %t179 = load i8*, i8** %t178
  call void @star_rc_retain(i8* %t179)
  %t180 = add i64 %t176, 1
  store i64 %t180, i64* %t175
  br label %table_cow_retain_cond_31
table_cow_retain_end_33:
  br label %table_cow_after_copy_30
table_cow_after_copy_30:
  %t181 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t151, i32 0, i32 3
  store i8** %t171, i8*** %t181
  call void @star_rc_release(i8* %t127)
  store i8* %t150, i8** %t0
  br label %table_cow_done_25
table_cow_done_25:
  %t182 = load i8*, i8** %t0
  %t183 = bitcast i8* %t182 to { i64, i64, i32*, i8** }*
  %t184 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t183, i32 0, i32 0
  %t185 = load i64, i64* %t184
  %t186 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t183, i32 0, i32 1
  %t187 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t183, i32 0, i32 2
  %t188 = load i32*, i32** %t187
  %t189 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t183, i32 0, i32 3
  %t190 = load i8**, i8*** %t189
  %t191 = alloca %Enemy
  %t192 = getelementptr inbounds %Enemy, %Enemy* %t191, i32 0, i32 0
  store i32 20, i32* %t192
  %t193 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t194 = getelementptr inbounds %Enemy, %Enemy* %t191, i32 0, i32 1
  store i8* %t193, i8** %t194
  %t195 = load %Enemy, %Enemy* %t191
  %t196 = load i64, i64* %t186
  %t197 = icmp sge i64 %t185, %t196
  br i1 %t197, label %table_push_grow_34, label %table_push_store_35
table_push_grow_34:
  %t198 = mul i64 %t196, 2
  %t199 = icmp sgt i64 %t198, 0
  %t200 = select i1 %t199, i64 %t198, i64 1
  %t201 = getelementptr i32, i32* null, i32 1
  %t202 = ptrtoint i32* %t201 to i64
  %t203 = mul i64 %t200, %t202
  %t204 = call i8* @malloc(i64 %t203)
  %t205 = bitcast i8* %t204 to i32*
  %t206 = icmp sgt i64 %t196, 0
  br i1 %t206, label %table_push_copy_36, label %table_push_after_copy_37
table_push_copy_36:
  %t207 = mul i64 %t185, %t202
  %t208 = bitcast i32* %t188 to i8*
  call i8* @memcpy(i8* %t204, i8* %t208, i64 %t207)
  call void @free(i8* %t208)
  br label %table_push_after_copy_37
table_push_after_copy_37:
  store i32* %t205, i32** %t187
  %t209 = getelementptr i8*, i8** null, i32 1
  %t210 = ptrtoint i8** %t209 to i64
  %t211 = mul i64 %t200, %t210
  %t212 = call i8* @malloc(i64 %t211)
  %t213 = bitcast i8* %t212 to i8**
  %t214 = icmp sgt i64 %t196, 0
  br i1 %t214, label %table_push_copy_38, label %table_push_after_copy_39
table_push_copy_38:
  %t215 = mul i64 %t185, %t210
  %t216 = bitcast i8** %t190 to i8*
  call i8* @memcpy(i8* %t212, i8* %t216, i64 %t215)
  call void @free(i8* %t216)
  br label %table_push_after_copy_39
table_push_after_copy_39:
  store i8** %t213, i8*** %t189
  store i64 %t200, i64* %t186
  br label %table_push_store_35
table_push_store_35:
  %t217 = load i32*, i32** %t187
  %t218 = extractvalue %Enemy %t195, 0
  %t219 = getelementptr inbounds i32, i32* %t217, i64 %t185
  store i32 %t218, i32* %t219
  %t220 = load i8**, i8*** %t189
  %t221 = extractvalue %Enemy %t195, 1
  %t222 = getelementptr inbounds i8*, i8** %t220, i64 %t185
  store i8* %t221, i8** %t222
  %t223 = add i64 %t185, 1
  store i64 %t223, i64* %t184
  %t224 = load i8*, i8** %t0
  %t225 = icmp eq i8* %t224, null
  br i1 %t225, label %table_cow_alloc_40, label %table_cow_check_41
table_cow_alloc_40:
  %t226 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t227 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t228 = ptrtoint { i64, i64, i32*, i8** }* %t227 to i64
  %t229 = call i8* @star_rc_alloc(i64 %t228, i8* %t226)
  %t230 = bitcast i8* %t229 to { i64, i64, i32*, i8** }*
  %t231 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t230, i32 0, i32 0
  store i64 0, i64* %t231
  %t232 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t230, i32 0, i32 1
  store i64 0, i64* %t232
  %t233 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t230, i32 0, i32 2
  store i32* null, i32** %t233
  %t234 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t230, i32 0, i32 3
  store i8** null, i8*** %t234
  store i8* %t229, i8** %t0
  br label %table_cow_done_42
table_cow_check_41:
  %t235 = getelementptr inbounds i8, i8* %t224, i64 -16
  %t236 = bitcast i8* %t235 to i64*
  %t237 = load atomic i64, i64* %t236 seq_cst, align 8
  %t238 = icmp eq i64 %t237, 1
  br i1 %t238, label %table_cow_done_42, label %table_cow_clone_43
table_cow_clone_43:
  %t239 = bitcast i8* %t224 to { i64, i64, i32*, i8** }*
  %t240 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t239, i32 0, i32 0
  %t241 = load i64, i64* %t240
  %t242 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t239, i32 0, i32 1
  %t243 = load i64, i64* %t242
  %t244 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t245 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t246 = ptrtoint { i64, i64, i32*, i8** }* %t245 to i64
  %t247 = call i8* @star_rc_alloc(i64 %t246, i8* %t244)
  %t248 = bitcast i8* %t247 to { i64, i64, i32*, i8** }*
  %t249 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t248, i32 0, i32 0
  store i64 %t241, i64* %t249
  %t250 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t248, i32 0, i32 1
  store i64 %t243, i64* %t250
  %t251 = getelementptr i32, i32* null, i32 1
  %t252 = ptrtoint i32* %t251 to i64
  %t253 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t239, i32 0, i32 2
  %t254 = load i32*, i32** %t253
  %t255 = mul i64 %t243, %t252
  %t256 = call i8* @malloc(i64 %t255)
  %t257 = bitcast i8* %t256 to i32*
  %t258 = icmp sgt i64 %t241, 0
  br i1 %t258, label %table_cow_copy_44, label %table_cow_after_copy_45
table_cow_copy_44:
  %t259 = mul i64 %t241, %t252
  %t260 = bitcast i32* %t254 to i8*
  call i8* @memcpy(i8* %t256, i8* %t260, i64 %t259)
  br label %table_cow_after_copy_45
table_cow_after_copy_45:
  %t261 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t248, i32 0, i32 2
  store i32* %t257, i32** %t261
  %t262 = getelementptr i8*, i8** null, i32 1
  %t263 = ptrtoint i8** %t262 to i64
  %t264 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t239, i32 0, i32 3
  %t265 = load i8**, i8*** %t264
  %t266 = mul i64 %t243, %t263
  %t267 = call i8* @malloc(i64 %t266)
  %t268 = bitcast i8* %t267 to i8**
  %t269 = icmp sgt i64 %t241, 0
  br i1 %t269, label %table_cow_copy_46, label %table_cow_after_copy_47
table_cow_copy_46:
  %t270 = mul i64 %t241, %t263
  %t271 = bitcast i8** %t265 to i8*
  call i8* @memcpy(i8* %t267, i8* %t271, i64 %t270)
  %t272 = alloca i64
  store i64 0, i64* %t272
  br label %table_cow_retain_cond_48
table_cow_retain_cond_48:
  %t273 = load i64, i64* %t272
  %t274 = icmp slt i64 %t273, %t241
  br i1 %t274, label %table_cow_retain_body_49, label %table_cow_retain_end_50
table_cow_retain_body_49:
  %t275 = getelementptr inbounds i8*, i8** %t268, i64 %t273
  %t276 = load i8*, i8** %t275
  call void @star_rc_retain(i8* %t276)
  %t277 = add i64 %t273, 1
  store i64 %t277, i64* %t272
  br label %table_cow_retain_cond_48
table_cow_retain_end_50:
  br label %table_cow_after_copy_47
table_cow_after_copy_47:
  %t278 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t248, i32 0, i32 3
  store i8** %t268, i8*** %t278
  call void @star_rc_release(i8* %t224)
  store i8* %t247, i8** %t0
  br label %table_cow_done_42
table_cow_done_42:
  %t279 = load i8*, i8** %t0
  %t280 = bitcast i8* %t279 to { i64, i64, i32*, i8** }*
  %t281 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t280, i32 0, i32 0
  %t282 = load i64, i64* %t281
  %t283 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t280, i32 0, i32 1
  %t284 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t280, i32 0, i32 2
  %t285 = load i32*, i32** %t284
  %t286 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t280, i32 0, i32 3
  %t287 = load i8**, i8*** %t286
  %t288 = alloca %Enemy
  %t289 = getelementptr inbounds %Enemy, %Enemy* %t288, i32 0, i32 0
  store i32 30, i32* %t289
  %t290 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t291 = getelementptr inbounds %Enemy, %Enemy* %t288, i32 0, i32 1
  store i8* %t290, i8** %t291
  %t292 = load %Enemy, %Enemy* %t288
  %t293 = load i64, i64* %t283
  %t294 = icmp sge i64 %t282, %t293
  br i1 %t294, label %table_push_grow_51, label %table_push_store_52
table_push_grow_51:
  %t295 = mul i64 %t293, 2
  %t296 = icmp sgt i64 %t295, 0
  %t297 = select i1 %t296, i64 %t295, i64 1
  %t298 = getelementptr i32, i32* null, i32 1
  %t299 = ptrtoint i32* %t298 to i64
  %t300 = mul i64 %t297, %t299
  %t301 = call i8* @malloc(i64 %t300)
  %t302 = bitcast i8* %t301 to i32*
  %t303 = icmp sgt i64 %t293, 0
  br i1 %t303, label %table_push_copy_53, label %table_push_after_copy_54
table_push_copy_53:
  %t304 = mul i64 %t282, %t299
  %t305 = bitcast i32* %t285 to i8*
  call i8* @memcpy(i8* %t301, i8* %t305, i64 %t304)
  call void @free(i8* %t305)
  br label %table_push_after_copy_54
table_push_after_copy_54:
  store i32* %t302, i32** %t284
  %t306 = getelementptr i8*, i8** null, i32 1
  %t307 = ptrtoint i8** %t306 to i64
  %t308 = mul i64 %t297, %t307
  %t309 = call i8* @malloc(i64 %t308)
  %t310 = bitcast i8* %t309 to i8**
  %t311 = icmp sgt i64 %t293, 0
  br i1 %t311, label %table_push_copy_55, label %table_push_after_copy_56
table_push_copy_55:
  %t312 = mul i64 %t282, %t307
  %t313 = bitcast i8** %t287 to i8*
  call i8* @memcpy(i8* %t309, i8* %t313, i64 %t312)
  call void @free(i8* %t313)
  br label %table_push_after_copy_56
table_push_after_copy_56:
  store i8** %t310, i8*** %t286
  store i64 %t297, i64* %t283
  br label %table_push_store_52
table_push_store_52:
  %t314 = load i32*, i32** %t284
  %t315 = extractvalue %Enemy %t292, 0
  %t316 = getelementptr inbounds i32, i32* %t314, i64 %t282
  store i32 %t315, i32* %t316
  %t317 = load i8**, i8*** %t286
  %t318 = extractvalue %Enemy %t292, 1
  %t319 = getelementptr inbounds i8*, i8** %t317, i64 %t282
  store i8* %t318, i8** %t319
  %t320 = add i64 %t282, 1
  store i64 %t320, i64* %t281
  %t321 = load i8*, i8** %t0
  %t322 = icmp eq i8* %t321, null
  br i1 %t322, label %table_read_null_57, label %table_read_real_58
table_read_null_57:
  br label %table_read_end_59
table_read_real_58:
  %t323 = bitcast i8* %t321 to { i64, i64, i32*, i8** }*
  %t324 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t323, i32 0, i32 0
  %t325 = load i64, i64* %t324
  %t326 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t323, i32 0, i32 2
  %t327 = load i32*, i32** %t326
  %t328 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t323, i32 0, i32 3
  %t329 = load i8**, i8*** %t328
  br label %table_read_end_59
table_read_end_59:
  %t330 = phi i64 [ 0, %table_read_null_57 ], [ %t325, %table_read_real_58 ]
  %t331 = phi i32* [ null, %table_read_null_57 ], [ %t327, %table_read_real_58 ]
  %t332 = phi i8** [ null, %table_read_null_57 ], [ %t329, %table_read_real_58 ]
  %t333 = trunc i64 %t330 to i32
  %t334 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t334, i32 %t333)
  %t335 = load i8*, i8** %t0
  %t336 = icmp eq i8* %t335, null
  br i1 %t336, label %table_read_null_60, label %table_read_real_61
table_read_null_60:
  br label %table_read_end_62
table_read_real_61:
  %t337 = bitcast i8* %t335 to { i64, i64, i32*, i8** }*
  %t338 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t337, i32 0, i32 0
  %t339 = load i64, i64* %t338
  %t340 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t337, i32 0, i32 2
  %t341 = load i32*, i32** %t340
  %t342 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t337, i32 0, i32 3
  %t343 = load i8**, i8*** %t342
  br label %table_read_end_62
table_read_end_62:
  %t344 = phi i64 [ 0, %table_read_null_60 ], [ %t339, %table_read_real_61 ]
  %t345 = phi i32* [ null, %table_read_null_60 ], [ %t341, %table_read_real_61 ]
  %t346 = phi i8** [ null, %table_read_null_60 ], [ %t343, %table_read_real_61 ]
  %t347 = sext i32 0 to i64
  %t348 = alloca %Enemy
  %t349 = icmp ult i64 %t347, %t344
  br i1 %t349, label %table_idx_ok_63, label %table_idx_oob_64
table_idx_ok_63:
  %t350 = getelementptr inbounds i32, i32* %t345, i64 %t347
  %t351 = load i32, i32* %t350
  %t352 = getelementptr inbounds %Enemy, %Enemy* %t348, i32 0, i32 0
  store i32 %t351, i32* %t352
  %t353 = getelementptr inbounds i8*, i8** %t346, i64 %t347
  %t354 = load i8*, i8** %t353
  call void @star_rc_retain(i8* %t354)
  %t355 = load i8*, i8** %t353
  %t356 = getelementptr inbounds %Enemy, %Enemy* %t348, i32 0, i32 1
  store i8* %t355, i8** %t356
  br label %table_idx_end_65
table_idx_oob_64:
  store %Enemy zeroinitializer, %Enemy* %t348
  br label %table_idx_end_65
table_idx_end_65:
  %t357 = load %Enemy, %Enemy* %t348
  %t358 = alloca %Enemy
  store %Enemy %t357, %Enemy* %t358
  %t359 = getelementptr inbounds %Enemy, %Enemy* %t358, i32 0, i32 1
  %t360 = load i8*, i8** %t359
  %t361 = load i8*, i8** %t359
  call void @star_rc_retain(i8* %t361)
  call void @star_rc_release(i8* %t360)
  %t362 = load i8*, i8** %t0
  %t363 = icmp eq i8* %t362, null
  br i1 %t363, label %table_read_null_66, label %table_read_real_67
table_read_null_66:
  br label %table_read_end_68
table_read_real_67:
  %t364 = bitcast i8* %t362 to { i64, i64, i32*, i8** }*
  %t365 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t364, i32 0, i32 0
  %t366 = load i64, i64* %t365
  %t367 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t364, i32 0, i32 2
  %t368 = load i32*, i32** %t367
  %t369 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t364, i32 0, i32 3
  %t370 = load i8**, i8*** %t369
  br label %table_read_end_68
table_read_end_68:
  %t371 = phi i64 [ 0, %table_read_null_66 ], [ %t366, %table_read_real_67 ]
  %t372 = phi i32* [ null, %table_read_null_66 ], [ %t368, %table_read_real_67 ]
  %t373 = phi i8** [ null, %table_read_null_66 ], [ %t370, %table_read_real_67 ]
  %t374 = sext i32 0 to i64
  %t375 = alloca %Enemy
  %t376 = icmp ult i64 %t374, %t371
  br i1 %t376, label %table_idx_ok_69, label %table_idx_oob_70
table_idx_ok_69:
  %t377 = getelementptr inbounds i32, i32* %t372, i64 %t374
  %t378 = load i32, i32* %t377
  %t379 = getelementptr inbounds %Enemy, %Enemy* %t375, i32 0, i32 0
  store i32 %t378, i32* %t379
  %t380 = getelementptr inbounds i8*, i8** %t373, i64 %t374
  %t381 = load i8*, i8** %t380
  call void @star_rc_retain(i8* %t381)
  %t382 = load i8*, i8** %t380
  %t383 = getelementptr inbounds %Enemy, %Enemy* %t375, i32 0, i32 1
  store i8* %t382, i8** %t383
  br label %table_idx_end_71
table_idx_oob_70:
  store %Enemy zeroinitializer, %Enemy* %t375
  br label %table_idx_end_71
table_idx_end_71:
  %t384 = load %Enemy, %Enemy* %t375
  %t385 = alloca %Enemy
  store %Enemy %t384, %Enemy* %t385
  %t386 = getelementptr inbounds %Enemy, %Enemy* %t385, i32 0, i32 0
  %t387 = load i32, i32* %t386
  %t388 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t388, i8* %t360, i32 %t387)
  %t389 = load i8*, i8** %t0
  %t390 = icmp eq i8* %t389, null
  br i1 %t390, label %table_read_null_72, label %table_read_real_73
table_read_null_72:
  br label %table_read_end_74
table_read_real_73:
  %t391 = bitcast i8* %t389 to { i64, i64, i32*, i8** }*
  %t392 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t391, i32 0, i32 0
  %t393 = load i64, i64* %t392
  %t394 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t391, i32 0, i32 2
  %t395 = load i32*, i32** %t394
  %t396 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t391, i32 0, i32 3
  %t397 = load i8**, i8*** %t396
  br label %table_read_end_74
table_read_end_74:
  %t398 = phi i64 [ 0, %table_read_null_72 ], [ %t393, %table_read_real_73 ]
  %t399 = phi i32* [ null, %table_read_null_72 ], [ %t395, %table_read_real_73 ]
  %t400 = phi i8** [ null, %table_read_null_72 ], [ %t397, %table_read_real_73 ]
  %t401 = sext i32 2 to i64
  %t402 = alloca %Enemy
  %t403 = icmp ult i64 %t401, %t398
  br i1 %t403, label %table_idx_ok_75, label %table_idx_oob_76
table_idx_ok_75:
  %t404 = getelementptr inbounds i32, i32* %t399, i64 %t401
  %t405 = load i32, i32* %t404
  %t406 = getelementptr inbounds %Enemy, %Enemy* %t402, i32 0, i32 0
  store i32 %t405, i32* %t406
  %t407 = getelementptr inbounds i8*, i8** %t400, i64 %t401
  %t408 = load i8*, i8** %t407
  call void @star_rc_retain(i8* %t408)
  %t409 = load i8*, i8** %t407
  %t410 = getelementptr inbounds %Enemy, %Enemy* %t402, i32 0, i32 1
  store i8* %t409, i8** %t410
  br label %table_idx_end_77
table_idx_oob_76:
  store %Enemy zeroinitializer, %Enemy* %t402
  br label %table_idx_end_77
table_idx_end_77:
  %t411 = load %Enemy, %Enemy* %t402
  %t412 = alloca %Enemy
  store %Enemy %t411, %Enemy* %t412
  %t413 = getelementptr inbounds %Enemy, %Enemy* %t412, i32 0, i32 1
  %t414 = load i8*, i8** %t413
  %t415 = load i8*, i8** %t413
  call void @star_rc_retain(i8* %t415)
  call void @star_rc_release(i8* %t414)
  %t416 = load i8*, i8** %t0
  %t417 = icmp eq i8* %t416, null
  br i1 %t417, label %table_read_null_78, label %table_read_real_79
table_read_null_78:
  br label %table_read_end_80
table_read_real_79:
  %t418 = bitcast i8* %t416 to { i64, i64, i32*, i8** }*
  %t419 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t418, i32 0, i32 0
  %t420 = load i64, i64* %t419
  %t421 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t418, i32 0, i32 2
  %t422 = load i32*, i32** %t421
  %t423 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t418, i32 0, i32 3
  %t424 = load i8**, i8*** %t423
  br label %table_read_end_80
table_read_end_80:
  %t425 = phi i64 [ 0, %table_read_null_78 ], [ %t420, %table_read_real_79 ]
  %t426 = phi i32* [ null, %table_read_null_78 ], [ %t422, %table_read_real_79 ]
  %t427 = phi i8** [ null, %table_read_null_78 ], [ %t424, %table_read_real_79 ]
  %t428 = sext i32 2 to i64
  %t429 = alloca %Enemy
  %t430 = icmp ult i64 %t428, %t425
  br i1 %t430, label %table_idx_ok_81, label %table_idx_oob_82
table_idx_ok_81:
  %t431 = getelementptr inbounds i32, i32* %t426, i64 %t428
  %t432 = load i32, i32* %t431
  %t433 = getelementptr inbounds %Enemy, %Enemy* %t429, i32 0, i32 0
  store i32 %t432, i32* %t433
  %t434 = getelementptr inbounds i8*, i8** %t427, i64 %t428
  %t435 = load i8*, i8** %t434
  call void @star_rc_retain(i8* %t435)
  %t436 = load i8*, i8** %t434
  %t437 = getelementptr inbounds %Enemy, %Enemy* %t429, i32 0, i32 1
  store i8* %t436, i8** %t437
  br label %table_idx_end_83
table_idx_oob_82:
  store %Enemy zeroinitializer, %Enemy* %t429
  br label %table_idx_end_83
table_idx_end_83:
  %t438 = load %Enemy, %Enemy* %t429
  %t439 = alloca %Enemy
  store %Enemy %t438, %Enemy* %t439
  %t440 = getelementptr inbounds %Enemy, %Enemy* %t439, i32 0, i32 0
  %t441 = load i32, i32* %t440
  %t442 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t442, i8* %t414, i32 %t441)
  %t443 = alloca %Enemy
  %t444 = getelementptr inbounds %Enemy, %Enemy* %t443, i32 0, i32 0
  store i32 99, i32* %t444
  %t445 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t446 = getelementptr inbounds %Enemy, %Enemy* %t443, i32 0, i32 1
  store i8* %t445, i8** %t446
  %t447 = load %Enemy, %Enemy* %t443
  %t448 = load i8*, i8** %t0
  %t449 = icmp eq i8* %t448, null
  br i1 %t449, label %table_cow_alloc_84, label %table_cow_check_85
table_cow_alloc_84:
  %t450 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t451 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t452 = ptrtoint { i64, i64, i32*, i8** }* %t451 to i64
  %t453 = call i8* @star_rc_alloc(i64 %t452, i8* %t450)
  %t454 = bitcast i8* %t453 to { i64, i64, i32*, i8** }*
  %t455 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t454, i32 0, i32 0
  store i64 0, i64* %t455
  %t456 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t454, i32 0, i32 1
  store i64 0, i64* %t456
  %t457 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t454, i32 0, i32 2
  store i32* null, i32** %t457
  %t458 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t454, i32 0, i32 3
  store i8** null, i8*** %t458
  store i8* %t453, i8** %t0
  br label %table_cow_done_86
table_cow_check_85:
  %t459 = getelementptr inbounds i8, i8* %t448, i64 -16
  %t460 = bitcast i8* %t459 to i64*
  %t461 = load atomic i64, i64* %t460 seq_cst, align 8
  %t462 = icmp eq i64 %t461, 1
  br i1 %t462, label %table_cow_done_86, label %table_cow_clone_87
table_cow_clone_87:
  %t463 = bitcast i8* %t448 to { i64, i64, i32*, i8** }*
  %t464 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t463, i32 0, i32 0
  %t465 = load i64, i64* %t464
  %t466 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t463, i32 0, i32 1
  %t467 = load i64, i64* %t466
  %t468 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t469 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t470 = ptrtoint { i64, i64, i32*, i8** }* %t469 to i64
  %t471 = call i8* @star_rc_alloc(i64 %t470, i8* %t468)
  %t472 = bitcast i8* %t471 to { i64, i64, i32*, i8** }*
  %t473 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t472, i32 0, i32 0
  store i64 %t465, i64* %t473
  %t474 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t472, i32 0, i32 1
  store i64 %t467, i64* %t474
  %t475 = getelementptr i32, i32* null, i32 1
  %t476 = ptrtoint i32* %t475 to i64
  %t477 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t463, i32 0, i32 2
  %t478 = load i32*, i32** %t477
  %t479 = mul i64 %t467, %t476
  %t480 = call i8* @malloc(i64 %t479)
  %t481 = bitcast i8* %t480 to i32*
  %t482 = icmp sgt i64 %t465, 0
  br i1 %t482, label %table_cow_copy_88, label %table_cow_after_copy_89
table_cow_copy_88:
  %t483 = mul i64 %t465, %t476
  %t484 = bitcast i32* %t478 to i8*
  call i8* @memcpy(i8* %t480, i8* %t484, i64 %t483)
  br label %table_cow_after_copy_89
table_cow_after_copy_89:
  %t485 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t472, i32 0, i32 2
  store i32* %t481, i32** %t485
  %t486 = getelementptr i8*, i8** null, i32 1
  %t487 = ptrtoint i8** %t486 to i64
  %t488 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t463, i32 0, i32 3
  %t489 = load i8**, i8*** %t488
  %t490 = mul i64 %t467, %t487
  %t491 = call i8* @malloc(i64 %t490)
  %t492 = bitcast i8* %t491 to i8**
  %t493 = icmp sgt i64 %t465, 0
  br i1 %t493, label %table_cow_copy_90, label %table_cow_after_copy_91
table_cow_copy_90:
  %t494 = mul i64 %t465, %t487
  %t495 = bitcast i8** %t489 to i8*
  call i8* @memcpy(i8* %t491, i8* %t495, i64 %t494)
  %t496 = alloca i64
  store i64 0, i64* %t496
  br label %table_cow_retain_cond_92
table_cow_retain_cond_92:
  %t497 = load i64, i64* %t496
  %t498 = icmp slt i64 %t497, %t465
  br i1 %t498, label %table_cow_retain_body_93, label %table_cow_retain_end_94
table_cow_retain_body_93:
  %t499 = getelementptr inbounds i8*, i8** %t492, i64 %t497
  %t500 = load i8*, i8** %t499
  call void @star_rc_retain(i8* %t500)
  %t501 = add i64 %t497, 1
  store i64 %t501, i64* %t496
  br label %table_cow_retain_cond_92
table_cow_retain_end_94:
  br label %table_cow_after_copy_91
table_cow_after_copy_91:
  %t502 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t472, i32 0, i32 3
  store i8** %t492, i8*** %t502
  call void @star_rc_release(i8* %t448)
  store i8* %t471, i8** %t0
  br label %table_cow_done_86
table_cow_done_86:
  %t503 = load i8*, i8** %t0
  %t504 = bitcast i8* %t503 to { i64, i64, i32*, i8** }*
  %t505 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t504, i32 0, i32 0
  %t506 = load i64, i64* %t505
  %t507 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t504, i32 0, i32 1
  %t508 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t504, i32 0, i32 2
  %t509 = load i32*, i32** %t508
  %t510 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t504, i32 0, i32 3
  %t511 = load i8**, i8*** %t510
  %t512 = sext i32 1 to i64
  %t513 = icmp ult i64 %t512, %t506
  br i1 %t513, label %table_set_do_95, label %table_set_end_96
table_set_do_95:
  %t514 = extractvalue %Enemy %t447, 0
  %t515 = getelementptr inbounds i32, i32* %t509, i64 %t512
  store i32 %t514, i32* %t515
  %t516 = extractvalue %Enemy %t447, 1
  %t517 = getelementptr inbounds i8*, i8** %t511, i64 %t512
  %t518 = load i8*, i8** %t517
  call void @star_rc_release(i8* %t518)
  store i8* %t516, i8** %t517
  br label %table_set_end_96
table_set_end_96:
  %t519 = load i8*, i8** %t0
  %t520 = icmp eq i8* %t519, null
  br i1 %t520, label %table_read_null_97, label %table_read_real_98
table_read_null_97:
  br label %table_read_end_99
table_read_real_98:
  %t521 = bitcast i8* %t519 to { i64, i64, i32*, i8** }*
  %t522 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t521, i32 0, i32 0
  %t523 = load i64, i64* %t522
  %t524 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t521, i32 0, i32 2
  %t525 = load i32*, i32** %t524
  %t526 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t521, i32 0, i32 3
  %t527 = load i8**, i8*** %t526
  br label %table_read_end_99
table_read_end_99:
  %t528 = phi i64 [ 0, %table_read_null_97 ], [ %t523, %table_read_real_98 ]
  %t529 = phi i32* [ null, %table_read_null_97 ], [ %t525, %table_read_real_98 ]
  %t530 = phi i8** [ null, %table_read_null_97 ], [ %t527, %table_read_real_98 ]
  %t531 = sext i32 1 to i64
  %t532 = alloca %Enemy
  %t533 = icmp ult i64 %t531, %t528
  br i1 %t533, label %table_idx_ok_100, label %table_idx_oob_101
table_idx_ok_100:
  %t534 = getelementptr inbounds i32, i32* %t529, i64 %t531
  %t535 = load i32, i32* %t534
  %t536 = getelementptr inbounds %Enemy, %Enemy* %t532, i32 0, i32 0
  store i32 %t535, i32* %t536
  %t537 = getelementptr inbounds i8*, i8** %t530, i64 %t531
  %t538 = load i8*, i8** %t537
  call void @star_rc_retain(i8* %t538)
  %t539 = load i8*, i8** %t537
  %t540 = getelementptr inbounds %Enemy, %Enemy* %t532, i32 0, i32 1
  store i8* %t539, i8** %t540
  br label %table_idx_end_102
table_idx_oob_101:
  store %Enemy zeroinitializer, %Enemy* %t532
  br label %table_idx_end_102
table_idx_end_102:
  %t541 = load %Enemy, %Enemy* %t532
  %t542 = alloca %Enemy
  store %Enemy %t541, %Enemy* %t542
  %t543 = getelementptr inbounds %Enemy, %Enemy* %t542, i32 0, i32 1
  %t544 = load i8*, i8** %t543
  %t545 = load i8*, i8** %t543
  call void @star_rc_retain(i8* %t545)
  call void @star_rc_release(i8* %t544)
  %t546 = load i8*, i8** %t0
  %t547 = icmp eq i8* %t546, null
  br i1 %t547, label %table_read_null_103, label %table_read_real_104
table_read_null_103:
  br label %table_read_end_105
table_read_real_104:
  %t548 = bitcast i8* %t546 to { i64, i64, i32*, i8** }*
  %t549 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t548, i32 0, i32 0
  %t550 = load i64, i64* %t549
  %t551 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t548, i32 0, i32 2
  %t552 = load i32*, i32** %t551
  %t553 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t548, i32 0, i32 3
  %t554 = load i8**, i8*** %t553
  br label %table_read_end_105
table_read_end_105:
  %t555 = phi i64 [ 0, %table_read_null_103 ], [ %t550, %table_read_real_104 ]
  %t556 = phi i32* [ null, %table_read_null_103 ], [ %t552, %table_read_real_104 ]
  %t557 = phi i8** [ null, %table_read_null_103 ], [ %t554, %table_read_real_104 ]
  %t558 = sext i32 1 to i64
  %t559 = alloca %Enemy
  %t560 = icmp ult i64 %t558, %t555
  br i1 %t560, label %table_idx_ok_106, label %table_idx_oob_107
table_idx_ok_106:
  %t561 = getelementptr inbounds i32, i32* %t556, i64 %t558
  %t562 = load i32, i32* %t561
  %t563 = getelementptr inbounds %Enemy, %Enemy* %t559, i32 0, i32 0
  store i32 %t562, i32* %t563
  %t564 = getelementptr inbounds i8*, i8** %t557, i64 %t558
  %t565 = load i8*, i8** %t564
  call void @star_rc_retain(i8* %t565)
  %t566 = load i8*, i8** %t564
  %t567 = getelementptr inbounds %Enemy, %Enemy* %t559, i32 0, i32 1
  store i8* %t566, i8** %t567
  br label %table_idx_end_108
table_idx_oob_107:
  store %Enemy zeroinitializer, %Enemy* %t559
  br label %table_idx_end_108
table_idx_end_108:
  %t568 = load %Enemy, %Enemy* %t559
  %t569 = alloca %Enemy
  store %Enemy %t568, %Enemy* %t569
  %t570 = getelementptr inbounds %Enemy, %Enemy* %t569, i32 0, i32 0
  %t571 = load i32, i32* %t570
  %t572 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t572, i8* %t544, i32 %t571)
  %t573 = alloca %Enemy
  %t574 = load i8*, i8** %t0
  %t575 = icmp eq i8* %t574, null
  br i1 %t575, label %table_cow_alloc_109, label %table_cow_check_110
table_cow_alloc_109:
  %t576 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t577 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t578 = ptrtoint { i64, i64, i32*, i8** }* %t577 to i64
  %t579 = call i8* @star_rc_alloc(i64 %t578, i8* %t576)
  %t580 = bitcast i8* %t579 to { i64, i64, i32*, i8** }*
  %t581 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t580, i32 0, i32 0
  store i64 0, i64* %t581
  %t582 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t580, i32 0, i32 1
  store i64 0, i64* %t582
  %t583 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t580, i32 0, i32 2
  store i32* null, i32** %t583
  %t584 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t580, i32 0, i32 3
  store i8** null, i8*** %t584
  store i8* %t579, i8** %t0
  br label %table_cow_done_111
table_cow_check_110:
  %t585 = getelementptr inbounds i8, i8* %t574, i64 -16
  %t586 = bitcast i8* %t585 to i64*
  %t587 = load atomic i64, i64* %t586 seq_cst, align 8
  %t588 = icmp eq i64 %t587, 1
  br i1 %t588, label %table_cow_done_111, label %table_cow_clone_112
table_cow_clone_112:
  %t589 = bitcast i8* %t574 to { i64, i64, i32*, i8** }*
  %t590 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t589, i32 0, i32 0
  %t591 = load i64, i64* %t590
  %t592 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t589, i32 0, i32 1
  %t593 = load i64, i64* %t592
  %t594 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t595 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t596 = ptrtoint { i64, i64, i32*, i8** }* %t595 to i64
  %t597 = call i8* @star_rc_alloc(i64 %t596, i8* %t594)
  %t598 = bitcast i8* %t597 to { i64, i64, i32*, i8** }*
  %t599 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t598, i32 0, i32 0
  store i64 %t591, i64* %t599
  %t600 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t598, i32 0, i32 1
  store i64 %t593, i64* %t600
  %t601 = getelementptr i32, i32* null, i32 1
  %t602 = ptrtoint i32* %t601 to i64
  %t603 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t589, i32 0, i32 2
  %t604 = load i32*, i32** %t603
  %t605 = mul i64 %t593, %t602
  %t606 = call i8* @malloc(i64 %t605)
  %t607 = bitcast i8* %t606 to i32*
  %t608 = icmp sgt i64 %t591, 0
  br i1 %t608, label %table_cow_copy_113, label %table_cow_after_copy_114
table_cow_copy_113:
  %t609 = mul i64 %t591, %t602
  %t610 = bitcast i32* %t604 to i8*
  call i8* @memcpy(i8* %t606, i8* %t610, i64 %t609)
  br label %table_cow_after_copy_114
table_cow_after_copy_114:
  %t611 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t598, i32 0, i32 2
  store i32* %t607, i32** %t611
  %t612 = getelementptr i8*, i8** null, i32 1
  %t613 = ptrtoint i8** %t612 to i64
  %t614 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t589, i32 0, i32 3
  %t615 = load i8**, i8*** %t614
  %t616 = mul i64 %t593, %t613
  %t617 = call i8* @malloc(i64 %t616)
  %t618 = bitcast i8* %t617 to i8**
  %t619 = icmp sgt i64 %t591, 0
  br i1 %t619, label %table_cow_copy_115, label %table_cow_after_copy_116
table_cow_copy_115:
  %t620 = mul i64 %t591, %t613
  %t621 = bitcast i8** %t615 to i8*
  call i8* @memcpy(i8* %t617, i8* %t621, i64 %t620)
  %t622 = alloca i64
  store i64 0, i64* %t622
  br label %table_cow_retain_cond_117
table_cow_retain_cond_117:
  %t623 = load i64, i64* %t622
  %t624 = icmp slt i64 %t623, %t591
  br i1 %t624, label %table_cow_retain_body_118, label %table_cow_retain_end_119
table_cow_retain_body_118:
  %t625 = getelementptr inbounds i8*, i8** %t618, i64 %t623
  %t626 = load i8*, i8** %t625
  call void @star_rc_retain(i8* %t626)
  %t627 = add i64 %t623, 1
  store i64 %t627, i64* %t622
  br label %table_cow_retain_cond_117
table_cow_retain_end_119:
  br label %table_cow_after_copy_116
table_cow_after_copy_116:
  %t628 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t598, i32 0, i32 3
  store i8** %t618, i8*** %t628
  call void @star_rc_release(i8* %t574)
  store i8* %t597, i8** %t0
  br label %table_cow_done_111
table_cow_done_111:
  %t629 = load i8*, i8** %t0
  %t630 = bitcast i8* %t629 to { i64, i64, i32*, i8** }*
  %t631 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t630, i32 0, i32 0
  %t632 = load i64, i64* %t631
  %t633 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t630, i32 0, i32 1
  %t634 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t630, i32 0, i32 2
  %t635 = load i32*, i32** %t634
  %t636 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t630, i32 0, i32 3
  %t637 = load i8**, i8*** %t636
  %t638 = alloca %Enemy
  %t639 = icmp eq i64 %t632, 0
  br i1 %t639, label %table_pop_empty_120, label %table_pop_nonempty_121
table_pop_nonempty_121:
  %t640 = sub i64 %t632, 1
  store i64 %t640, i64* %t631
  %t641 = getelementptr inbounds i32, i32* %t635, i64 %t640
  %t642 = load i32, i32* %t641
  %t643 = getelementptr inbounds %Enemy, %Enemy* %t638, i32 0, i32 0
  store i32 %t642, i32* %t643
  %t644 = getelementptr inbounds i8*, i8** %t637, i64 %t640
  %t645 = load i8*, i8** %t644
  %t646 = getelementptr inbounds %Enemy, %Enemy* %t638, i32 0, i32 1
  store i8* %t645, i8** %t646
  br label %table_pop_end_122
table_pop_empty_120:
  store %Enemy zeroinitializer, %Enemy* %t638
  br label %table_pop_end_122
table_pop_end_122:
  %t647 = load %Enemy, %Enemy* %t638
  store %Enemy %t647, %Enemy* %t573
  %t648 = getelementptr inbounds %Enemy, %Enemy* %t573, i32 0, i32 1
  %t649 = load i8*, i8** %t648
  %t650 = load i8*, i8** %t648
  call void @star_rc_retain(i8* %t650)
  call void @star_rc_release(i8* %t649)
  %t651 = getelementptr inbounds %Enemy, %Enemy* %t573, i32 0, i32 0
  %t652 = load i32, i32* %t651
  %t653 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t653, i8* %t649, i32 %t652)
  %t654 = load i8*, i8** %t0
  %t655 = icmp eq i8* %t654, null
  br i1 %t655, label %table_read_null_123, label %table_read_real_124
table_read_null_123:
  br label %table_read_end_125
table_read_real_124:
  %t656 = bitcast i8* %t654 to { i64, i64, i32*, i8** }*
  %t657 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t656, i32 0, i32 0
  %t658 = load i64, i64* %t657
  %t659 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t656, i32 0, i32 2
  %t660 = load i32*, i32** %t659
  %t661 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t656, i32 0, i32 3
  %t662 = load i8**, i8*** %t661
  br label %table_read_end_125
table_read_end_125:
  %t663 = phi i64 [ 0, %table_read_null_123 ], [ %t658, %table_read_real_124 ]
  %t664 = phi i32* [ null, %table_read_null_123 ], [ %t660, %table_read_real_124 ]
  %t665 = phi i8** [ null, %table_read_null_123 ], [ %t662, %table_read_real_124 ]
  %t666 = trunc i64 %t663 to i32
  %t667 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t667, i32 %t666)
  %t668 = load i8*, i8** %t0
  %t669 = icmp eq i8* %t668, null
  br i1 %t669, label %table_read_null_126, label %table_read_real_127
table_read_null_126:
  br label %table_read_end_128
table_read_real_127:
  %t670 = bitcast i8* %t668 to { i64, i64, i32*, i8** }*
  %t671 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t670, i32 0, i32 0
  %t672 = load i64, i64* %t671
  %t673 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t670, i32 0, i32 2
  %t674 = load i32*, i32** %t673
  %t675 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t670, i32 0, i32 3
  %t676 = load i8**, i8*** %t675
  br label %table_read_end_128
table_read_end_128:
  %t677 = phi i64 [ 0, %table_read_null_126 ], [ %t672, %table_read_real_127 ]
  %t678 = phi i32* [ null, %table_read_null_126 ], [ %t674, %table_read_real_127 ]
  %t679 = phi i8** [ null, %table_read_null_126 ], [ %t676, %table_read_real_127 ]
  %t680 = sext i32 99 to i64
  %t681 = alloca %Enemy
  %t682 = icmp ult i64 %t680, %t677
  br i1 %t682, label %table_idx_ok_129, label %table_idx_oob_130
table_idx_ok_129:
  %t683 = getelementptr inbounds i32, i32* %t678, i64 %t680
  %t684 = load i32, i32* %t683
  %t685 = getelementptr inbounds %Enemy, %Enemy* %t681, i32 0, i32 0
  store i32 %t684, i32* %t685
  %t686 = getelementptr inbounds i8*, i8** %t679, i64 %t680
  %t687 = load i8*, i8** %t686
  call void @star_rc_retain(i8* %t687)
  %t688 = load i8*, i8** %t686
  %t689 = getelementptr inbounds %Enemy, %Enemy* %t681, i32 0, i32 1
  store i8* %t688, i8** %t689
  br label %table_idx_end_131
table_idx_oob_130:
  store %Enemy zeroinitializer, %Enemy* %t681
  br label %table_idx_end_131
table_idx_end_131:
  %t690 = load %Enemy, %Enemy* %t681
  %t691 = alloca %Enemy
  store %Enemy %t690, %Enemy* %t691
  %t692 = getelementptr inbounds %Enemy, %Enemy* %t691, i32 0, i32 0
  %t693 = load i32, i32* %t692
  %t694 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t694, i32 %t693)
  %t695 = alloca i8*
  store i8* null, i8** %t695
  %t696 = alloca %Enemy
  %t697 = load i8*, i8** %t695
  %t698 = icmp eq i8* %t697, null
  br i1 %t698, label %table_cow_alloc_132, label %table_cow_check_133
table_cow_alloc_132:
  %t699 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t700 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t701 = ptrtoint { i64, i64, i32*, i8** }* %t700 to i64
  %t702 = call i8* @star_rc_alloc(i64 %t701, i8* %t699)
  %t703 = bitcast i8* %t702 to { i64, i64, i32*, i8** }*
  %t704 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t703, i32 0, i32 0
  store i64 0, i64* %t704
  %t705 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t703, i32 0, i32 1
  store i64 0, i64* %t705
  %t706 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t703, i32 0, i32 2
  store i32* null, i32** %t706
  %t707 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t703, i32 0, i32 3
  store i8** null, i8*** %t707
  store i8* %t702, i8** %t695
  br label %table_cow_done_134
table_cow_check_133:
  %t708 = getelementptr inbounds i8, i8* %t697, i64 -16
  %t709 = bitcast i8* %t708 to i64*
  %t710 = load atomic i64, i64* %t709 seq_cst, align 8
  %t711 = icmp eq i64 %t710, 1
  br i1 %t711, label %table_cow_done_134, label %table_cow_clone_135
table_cow_clone_135:
  %t712 = bitcast i8* %t697 to { i64, i64, i32*, i8** }*
  %t713 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t712, i32 0, i32 0
  %t714 = load i64, i64* %t713
  %t715 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t712, i32 0, i32 1
  %t716 = load i64, i64* %t715
  %t717 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t718 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t719 = ptrtoint { i64, i64, i32*, i8** }* %t718 to i64
  %t720 = call i8* @star_rc_alloc(i64 %t719, i8* %t717)
  %t721 = bitcast i8* %t720 to { i64, i64, i32*, i8** }*
  %t722 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t721, i32 0, i32 0
  store i64 %t714, i64* %t722
  %t723 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t721, i32 0, i32 1
  store i64 %t716, i64* %t723
  %t724 = getelementptr i32, i32* null, i32 1
  %t725 = ptrtoint i32* %t724 to i64
  %t726 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t712, i32 0, i32 2
  %t727 = load i32*, i32** %t726
  %t728 = mul i64 %t716, %t725
  %t729 = call i8* @malloc(i64 %t728)
  %t730 = bitcast i8* %t729 to i32*
  %t731 = icmp sgt i64 %t714, 0
  br i1 %t731, label %table_cow_copy_136, label %table_cow_after_copy_137
table_cow_copy_136:
  %t732 = mul i64 %t714, %t725
  %t733 = bitcast i32* %t727 to i8*
  call i8* @memcpy(i8* %t729, i8* %t733, i64 %t732)
  br label %table_cow_after_copy_137
table_cow_after_copy_137:
  %t734 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t721, i32 0, i32 2
  store i32* %t730, i32** %t734
  %t735 = getelementptr i8*, i8** null, i32 1
  %t736 = ptrtoint i8** %t735 to i64
  %t737 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t712, i32 0, i32 3
  %t738 = load i8**, i8*** %t737
  %t739 = mul i64 %t716, %t736
  %t740 = call i8* @malloc(i64 %t739)
  %t741 = bitcast i8* %t740 to i8**
  %t742 = icmp sgt i64 %t714, 0
  br i1 %t742, label %table_cow_copy_138, label %table_cow_after_copy_139
table_cow_copy_138:
  %t743 = mul i64 %t714, %t736
  %t744 = bitcast i8** %t738 to i8*
  call i8* @memcpy(i8* %t740, i8* %t744, i64 %t743)
  %t745 = alloca i64
  store i64 0, i64* %t745
  br label %table_cow_retain_cond_140
table_cow_retain_cond_140:
  %t746 = load i64, i64* %t745
  %t747 = icmp slt i64 %t746, %t714
  br i1 %t747, label %table_cow_retain_body_141, label %table_cow_retain_end_142
table_cow_retain_body_141:
  %t748 = getelementptr inbounds i8*, i8** %t741, i64 %t746
  %t749 = load i8*, i8** %t748
  call void @star_rc_retain(i8* %t749)
  %t750 = add i64 %t746, 1
  store i64 %t750, i64* %t745
  br label %table_cow_retain_cond_140
table_cow_retain_end_142:
  br label %table_cow_after_copy_139
table_cow_after_copy_139:
  %t751 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t721, i32 0, i32 3
  store i8** %t741, i8*** %t751
  call void @star_rc_release(i8* %t697)
  store i8* %t720, i8** %t695
  br label %table_cow_done_134
table_cow_done_134:
  %t752 = load i8*, i8** %t695
  %t753 = bitcast i8* %t752 to { i64, i64, i32*, i8** }*
  %t754 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t753, i32 0, i32 0
  %t755 = load i64, i64* %t754
  %t756 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t753, i32 0, i32 1
  %t757 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t753, i32 0, i32 2
  %t758 = load i32*, i32** %t757
  %t759 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t753, i32 0, i32 3
  %t760 = load i8**, i8*** %t759
  %t761 = alloca %Enemy
  %t762 = icmp eq i64 %t755, 0
  br i1 %t762, label %table_pop_empty_143, label %table_pop_nonempty_144
table_pop_nonempty_144:
  %t763 = sub i64 %t755, 1
  store i64 %t763, i64* %t754
  %t764 = getelementptr inbounds i32, i32* %t758, i64 %t763
  %t765 = load i32, i32* %t764
  %t766 = getelementptr inbounds %Enemy, %Enemy* %t761, i32 0, i32 0
  store i32 %t765, i32* %t766
  %t767 = getelementptr inbounds i8*, i8** %t760, i64 %t763
  %t768 = load i8*, i8** %t767
  %t769 = getelementptr inbounds %Enemy, %Enemy* %t761, i32 0, i32 1
  store i8* %t768, i8** %t769
  br label %table_pop_end_145
table_pop_empty_143:
  store %Enemy zeroinitializer, %Enemy* %t761
  br label %table_pop_end_145
table_pop_end_145:
  %t770 = load %Enemy, %Enemy* %t761
  store %Enemy %t770, %Enemy* %t696
  %t771 = getelementptr inbounds %Enemy, %Enemy* %t696, i32 0, i32 0
  %t772 = load i32, i32* %t771
  %t773 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t773, i32 %t772)
  %t774 = alloca i8*
  store i8* null, i8** %t774
  %t775 = load i8*, i8** %t774
  %t776 = icmp eq i8* %t775, null
  br i1 %t776, label %table_cow_alloc_146, label %table_cow_check_147
table_cow_alloc_146:
  %t777 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t778 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t779 = ptrtoint { i64, i64, i32*, i8** }* %t778 to i64
  %t780 = call i8* @star_rc_alloc(i64 %t779, i8* %t777)
  %t781 = bitcast i8* %t780 to { i64, i64, i32*, i8** }*
  %t782 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t781, i32 0, i32 0
  store i64 0, i64* %t782
  %t783 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t781, i32 0, i32 1
  store i64 0, i64* %t783
  %t784 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t781, i32 0, i32 2
  store i32* null, i32** %t784
  %t785 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t781, i32 0, i32 3
  store i8** null, i8*** %t785
  store i8* %t780, i8** %t774
  br label %table_cow_done_148
table_cow_check_147:
  %t786 = getelementptr inbounds i8, i8* %t775, i64 -16
  %t787 = bitcast i8* %t786 to i64*
  %t788 = load atomic i64, i64* %t787 seq_cst, align 8
  %t789 = icmp eq i64 %t788, 1
  br i1 %t789, label %table_cow_done_148, label %table_cow_clone_149
table_cow_clone_149:
  %t790 = bitcast i8* %t775 to { i64, i64, i32*, i8** }*
  %t791 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t790, i32 0, i32 0
  %t792 = load i64, i64* %t791
  %t793 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t790, i32 0, i32 1
  %t794 = load i64, i64* %t793
  %t795 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t796 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t797 = ptrtoint { i64, i64, i32*, i8** }* %t796 to i64
  %t798 = call i8* @star_rc_alloc(i64 %t797, i8* %t795)
  %t799 = bitcast i8* %t798 to { i64, i64, i32*, i8** }*
  %t800 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t799, i32 0, i32 0
  store i64 %t792, i64* %t800
  %t801 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t799, i32 0, i32 1
  store i64 %t794, i64* %t801
  %t802 = getelementptr i32, i32* null, i32 1
  %t803 = ptrtoint i32* %t802 to i64
  %t804 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t790, i32 0, i32 2
  %t805 = load i32*, i32** %t804
  %t806 = mul i64 %t794, %t803
  %t807 = call i8* @malloc(i64 %t806)
  %t808 = bitcast i8* %t807 to i32*
  %t809 = icmp sgt i64 %t792, 0
  br i1 %t809, label %table_cow_copy_150, label %table_cow_after_copy_151
table_cow_copy_150:
  %t810 = mul i64 %t792, %t803
  %t811 = bitcast i32* %t805 to i8*
  call i8* @memcpy(i8* %t807, i8* %t811, i64 %t810)
  br label %table_cow_after_copy_151
table_cow_after_copy_151:
  %t812 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t799, i32 0, i32 2
  store i32* %t808, i32** %t812
  %t813 = getelementptr i8*, i8** null, i32 1
  %t814 = ptrtoint i8** %t813 to i64
  %t815 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t790, i32 0, i32 3
  %t816 = load i8**, i8*** %t815
  %t817 = mul i64 %t794, %t814
  %t818 = call i8* @malloc(i64 %t817)
  %t819 = bitcast i8* %t818 to i8**
  %t820 = icmp sgt i64 %t792, 0
  br i1 %t820, label %table_cow_copy_152, label %table_cow_after_copy_153
table_cow_copy_152:
  %t821 = mul i64 %t792, %t814
  %t822 = bitcast i8** %t816 to i8*
  call i8* @memcpy(i8* %t818, i8* %t822, i64 %t821)
  %t823 = alloca i64
  store i64 0, i64* %t823
  br label %table_cow_retain_cond_154
table_cow_retain_cond_154:
  %t824 = load i64, i64* %t823
  %t825 = icmp slt i64 %t824, %t792
  br i1 %t825, label %table_cow_retain_body_155, label %table_cow_retain_end_156
table_cow_retain_body_155:
  %t826 = getelementptr inbounds i8*, i8** %t819, i64 %t824
  %t827 = load i8*, i8** %t826
  call void @star_rc_retain(i8* %t827)
  %t828 = add i64 %t824, 1
  store i64 %t828, i64* %t823
  br label %table_cow_retain_cond_154
table_cow_retain_end_156:
  br label %table_cow_after_copy_153
table_cow_after_copy_153:
  %t829 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t799, i32 0, i32 3
  store i8** %t819, i8*** %t829
  call void @star_rc_release(i8* %t775)
  store i8* %t798, i8** %t774
  br label %table_cow_done_148
table_cow_done_148:
  %t830 = load i8*, i8** %t774
  %t831 = bitcast i8* %t830 to { i64, i64, i32*, i8** }*
  %t832 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t831, i32 0, i32 0
  %t833 = load i64, i64* %t832
  %t834 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t831, i32 0, i32 1
  %t835 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t831, i32 0, i32 2
  %t836 = load i32*, i32** %t835
  %t837 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t831, i32 0, i32 3
  %t838 = load i8**, i8*** %t837
  %t839 = alloca %Enemy
  %t840 = getelementptr inbounds %Enemy, %Enemy* %t839, i32 0, i32 0
  store i32 1, i32* %t840
  %t841 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t842 = getelementptr inbounds %Enemy, %Enemy* %t839, i32 0, i32 1
  store i8* %t841, i8** %t842
  %t843 = load %Enemy, %Enemy* %t839
  %t844 = load i64, i64* %t834
  %t845 = icmp sge i64 %t833, %t844
  br i1 %t845, label %table_push_grow_157, label %table_push_store_158
table_push_grow_157:
  %t846 = mul i64 %t844, 2
  %t847 = icmp sgt i64 %t846, 0
  %t848 = select i1 %t847, i64 %t846, i64 1
  %t849 = getelementptr i32, i32* null, i32 1
  %t850 = ptrtoint i32* %t849 to i64
  %t851 = mul i64 %t848, %t850
  %t852 = call i8* @malloc(i64 %t851)
  %t853 = bitcast i8* %t852 to i32*
  %t854 = icmp sgt i64 %t844, 0
  br i1 %t854, label %table_push_copy_159, label %table_push_after_copy_160
table_push_copy_159:
  %t855 = mul i64 %t833, %t850
  %t856 = bitcast i32* %t836 to i8*
  call i8* @memcpy(i8* %t852, i8* %t856, i64 %t855)
  call void @free(i8* %t856)
  br label %table_push_after_copy_160
table_push_after_copy_160:
  store i32* %t853, i32** %t835
  %t857 = getelementptr i8*, i8** null, i32 1
  %t858 = ptrtoint i8** %t857 to i64
  %t859 = mul i64 %t848, %t858
  %t860 = call i8* @malloc(i64 %t859)
  %t861 = bitcast i8* %t860 to i8**
  %t862 = icmp sgt i64 %t844, 0
  br i1 %t862, label %table_push_copy_161, label %table_push_after_copy_162
table_push_copy_161:
  %t863 = mul i64 %t833, %t858
  %t864 = bitcast i8** %t838 to i8*
  call i8* @memcpy(i8* %t860, i8* %t864, i64 %t863)
  call void @free(i8* %t864)
  br label %table_push_after_copy_162
table_push_after_copy_162:
  store i8** %t861, i8*** %t837
  store i64 %t848, i64* %t834
  br label %table_push_store_158
table_push_store_158:
  %t865 = load i32*, i32** %t835
  %t866 = extractvalue %Enemy %t843, 0
  %t867 = getelementptr inbounds i32, i32* %t865, i64 %t833
  store i32 %t866, i32* %t867
  %t868 = load i8**, i8*** %t837
  %t869 = extractvalue %Enemy %t843, 1
  %t870 = getelementptr inbounds i8*, i8** %t868, i64 %t833
  store i8* %t869, i8** %t870
  %t871 = add i64 %t833, 1
  store i64 %t871, i64* %t832
  %t872 = alloca i8*
  %t873 = load i8*, i8** %t774
  %t874 = load i8*, i8** %t774
  call void @star_rc_retain(i8* %t874)
  store i8* %t873, i8** %t872
  %t875 = load i8*, i8** %t872
  %t876 = icmp eq i8* %t875, null
  br i1 %t876, label %table_cow_alloc_163, label %table_cow_check_164
table_cow_alloc_163:
  %t877 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t878 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t879 = ptrtoint { i64, i64, i32*, i8** }* %t878 to i64
  %t880 = call i8* @star_rc_alloc(i64 %t879, i8* %t877)
  %t881 = bitcast i8* %t880 to { i64, i64, i32*, i8** }*
  %t882 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t881, i32 0, i32 0
  store i64 0, i64* %t882
  %t883 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t881, i32 0, i32 1
  store i64 0, i64* %t883
  %t884 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t881, i32 0, i32 2
  store i32* null, i32** %t884
  %t885 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t881, i32 0, i32 3
  store i8** null, i8*** %t885
  store i8* %t880, i8** %t872
  br label %table_cow_done_165
table_cow_check_164:
  %t886 = getelementptr inbounds i8, i8* %t875, i64 -16
  %t887 = bitcast i8* %t886 to i64*
  %t888 = load atomic i64, i64* %t887 seq_cst, align 8
  %t889 = icmp eq i64 %t888, 1
  br i1 %t889, label %table_cow_done_165, label %table_cow_clone_166
table_cow_clone_166:
  %t890 = bitcast i8* %t875 to { i64, i64, i32*, i8** }*
  %t891 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t890, i32 0, i32 0
  %t892 = load i64, i64* %t891
  %t893 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t890, i32 0, i32 1
  %t894 = load i64, i64* %t893
  %t895 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t896 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t897 = ptrtoint { i64, i64, i32*, i8** }* %t896 to i64
  %t898 = call i8* @star_rc_alloc(i64 %t897, i8* %t895)
  %t899 = bitcast i8* %t898 to { i64, i64, i32*, i8** }*
  %t900 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t899, i32 0, i32 0
  store i64 %t892, i64* %t900
  %t901 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t899, i32 0, i32 1
  store i64 %t894, i64* %t901
  %t902 = getelementptr i32, i32* null, i32 1
  %t903 = ptrtoint i32* %t902 to i64
  %t904 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t890, i32 0, i32 2
  %t905 = load i32*, i32** %t904
  %t906 = mul i64 %t894, %t903
  %t907 = call i8* @malloc(i64 %t906)
  %t908 = bitcast i8* %t907 to i32*
  %t909 = icmp sgt i64 %t892, 0
  br i1 %t909, label %table_cow_copy_167, label %table_cow_after_copy_168
table_cow_copy_167:
  %t910 = mul i64 %t892, %t903
  %t911 = bitcast i32* %t905 to i8*
  call i8* @memcpy(i8* %t907, i8* %t911, i64 %t910)
  br label %table_cow_after_copy_168
table_cow_after_copy_168:
  %t912 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t899, i32 0, i32 2
  store i32* %t908, i32** %t912
  %t913 = getelementptr i8*, i8** null, i32 1
  %t914 = ptrtoint i8** %t913 to i64
  %t915 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t890, i32 0, i32 3
  %t916 = load i8**, i8*** %t915
  %t917 = mul i64 %t894, %t914
  %t918 = call i8* @malloc(i64 %t917)
  %t919 = bitcast i8* %t918 to i8**
  %t920 = icmp sgt i64 %t892, 0
  br i1 %t920, label %table_cow_copy_169, label %table_cow_after_copy_170
table_cow_copy_169:
  %t921 = mul i64 %t892, %t914
  %t922 = bitcast i8** %t916 to i8*
  call i8* @memcpy(i8* %t918, i8* %t922, i64 %t921)
  %t923 = alloca i64
  store i64 0, i64* %t923
  br label %table_cow_retain_cond_171
table_cow_retain_cond_171:
  %t924 = load i64, i64* %t923
  %t925 = icmp slt i64 %t924, %t892
  br i1 %t925, label %table_cow_retain_body_172, label %table_cow_retain_end_173
table_cow_retain_body_172:
  %t926 = getelementptr inbounds i8*, i8** %t919, i64 %t924
  %t927 = load i8*, i8** %t926
  call void @star_rc_retain(i8* %t927)
  %t928 = add i64 %t924, 1
  store i64 %t928, i64* %t923
  br label %table_cow_retain_cond_171
table_cow_retain_end_173:
  br label %table_cow_after_copy_170
table_cow_after_copy_170:
  %t929 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t899, i32 0, i32 3
  store i8** %t919, i8*** %t929
  call void @star_rc_release(i8* %t875)
  store i8* %t898, i8** %t872
  br label %table_cow_done_165
table_cow_done_165:
  %t930 = load i8*, i8** %t872
  %t931 = bitcast i8* %t930 to { i64, i64, i32*, i8** }*
  %t932 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t931, i32 0, i32 0
  %t933 = load i64, i64* %t932
  %t934 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t931, i32 0, i32 1
  %t935 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t931, i32 0, i32 2
  %t936 = load i32*, i32** %t935
  %t937 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t931, i32 0, i32 3
  %t938 = load i8**, i8*** %t937
  %t939 = alloca %Enemy
  %t940 = getelementptr inbounds %Enemy, %Enemy* %t939, i32 0, i32 0
  store i32 2, i32* %t940
  %t941 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t942 = getelementptr inbounds %Enemy, %Enemy* %t939, i32 0, i32 1
  store i8* %t941, i8** %t942
  %t943 = load %Enemy, %Enemy* %t939
  %t944 = load i64, i64* %t934
  %t945 = icmp sge i64 %t933, %t944
  br i1 %t945, label %table_push_grow_174, label %table_push_store_175
table_push_grow_174:
  %t946 = mul i64 %t944, 2
  %t947 = icmp sgt i64 %t946, 0
  %t948 = select i1 %t947, i64 %t946, i64 1
  %t949 = getelementptr i32, i32* null, i32 1
  %t950 = ptrtoint i32* %t949 to i64
  %t951 = mul i64 %t948, %t950
  %t952 = call i8* @malloc(i64 %t951)
  %t953 = bitcast i8* %t952 to i32*
  %t954 = icmp sgt i64 %t944, 0
  br i1 %t954, label %table_push_copy_176, label %table_push_after_copy_177
table_push_copy_176:
  %t955 = mul i64 %t933, %t950
  %t956 = bitcast i32* %t936 to i8*
  call i8* @memcpy(i8* %t952, i8* %t956, i64 %t955)
  call void @free(i8* %t956)
  br label %table_push_after_copy_177
table_push_after_copy_177:
  store i32* %t953, i32** %t935
  %t957 = getelementptr i8*, i8** null, i32 1
  %t958 = ptrtoint i8** %t957 to i64
  %t959 = mul i64 %t948, %t958
  %t960 = call i8* @malloc(i64 %t959)
  %t961 = bitcast i8* %t960 to i8**
  %t962 = icmp sgt i64 %t944, 0
  br i1 %t962, label %table_push_copy_178, label %table_push_after_copy_179
table_push_copy_178:
  %t963 = mul i64 %t933, %t958
  %t964 = bitcast i8** %t938 to i8*
  call i8* @memcpy(i8* %t960, i8* %t964, i64 %t963)
  call void @free(i8* %t964)
  br label %table_push_after_copy_179
table_push_after_copy_179:
  store i8** %t961, i8*** %t937
  store i64 %t948, i64* %t934
  br label %table_push_store_175
table_push_store_175:
  %t965 = load i32*, i32** %t935
  %t966 = extractvalue %Enemy %t943, 0
  %t967 = getelementptr inbounds i32, i32* %t965, i64 %t933
  store i32 %t966, i32* %t967
  %t968 = load i8**, i8*** %t937
  %t969 = extractvalue %Enemy %t943, 1
  %t970 = getelementptr inbounds i8*, i8** %t968, i64 %t933
  store i8* %t969, i8** %t970
  %t971 = add i64 %t933, 1
  store i64 %t971, i64* %t932
  %t972 = load i8*, i8** %t774
  %t973 = icmp eq i8* %t972, null
  br i1 %t973, label %table_read_null_180, label %table_read_real_181
table_read_null_180:
  br label %table_read_end_182
table_read_real_181:
  %t974 = bitcast i8* %t972 to { i64, i64, i32*, i8** }*
  %t975 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t974, i32 0, i32 0
  %t976 = load i64, i64* %t975
  %t977 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t974, i32 0, i32 2
  %t978 = load i32*, i32** %t977
  %t979 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t974, i32 0, i32 3
  %t980 = load i8**, i8*** %t979
  br label %table_read_end_182
table_read_end_182:
  %t981 = phi i64 [ 0, %table_read_null_180 ], [ %t976, %table_read_real_181 ]
  %t982 = phi i32* [ null, %table_read_null_180 ], [ %t978, %table_read_real_181 ]
  %t983 = phi i8** [ null, %table_read_null_180 ], [ %t980, %table_read_real_181 ]
  %t984 = trunc i64 %t981 to i32
  %t985 = load i8*, i8** %t872
  %t986 = icmp eq i8* %t985, null
  br i1 %t986, label %table_read_null_183, label %table_read_real_184
table_read_null_183:
  br label %table_read_end_185
table_read_real_184:
  %t987 = bitcast i8* %t985 to { i64, i64, i32*, i8** }*
  %t988 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t987, i32 0, i32 0
  %t989 = load i64, i64* %t988
  %t990 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t987, i32 0, i32 2
  %t991 = load i32*, i32** %t990
  %t992 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t987, i32 0, i32 3
  %t993 = load i8**, i8*** %t992
  br label %table_read_end_185
table_read_end_185:
  %t994 = phi i64 [ 0, %table_read_null_183 ], [ %t989, %table_read_real_184 ]
  %t995 = phi i32* [ null, %table_read_null_183 ], [ %t991, %table_read_real_184 ]
  %t996 = phi i8** [ null, %table_read_null_183 ], [ %t993, %table_read_real_184 ]
  %t997 = trunc i64 %t994 to i32
  %t998 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.15, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t998, i32 %t984, i32 %t997)
  %t999 = load i8*, i8** %t774
  %t1000 = icmp eq i8* %t999, null
  br i1 %t1000, label %table_read_null_186, label %table_read_real_187
table_read_null_186:
  br label %table_read_end_188
table_read_real_187:
  %t1001 = bitcast i8* %t999 to { i64, i64, i32*, i8** }*
  %t1002 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1001, i32 0, i32 0
  %t1003 = load i64, i64* %t1002
  %t1004 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1001, i32 0, i32 2
  %t1005 = load i32*, i32** %t1004
  %t1006 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1001, i32 0, i32 3
  %t1007 = load i8**, i8*** %t1006
  br label %table_read_end_188
table_read_end_188:
  %t1008 = phi i64 [ 0, %table_read_null_186 ], [ %t1003, %table_read_real_187 ]
  %t1009 = phi i32* [ null, %table_read_null_186 ], [ %t1005, %table_read_real_187 ]
  %t1010 = phi i8** [ null, %table_read_null_186 ], [ %t1007, %table_read_real_187 ]
  %t1011 = sext i32 0 to i64
  %t1012 = alloca %Enemy
  %t1013 = icmp ult i64 %t1011, %t1008
  br i1 %t1013, label %table_idx_ok_189, label %table_idx_oob_190
table_idx_ok_189:
  %t1014 = getelementptr inbounds i32, i32* %t1009, i64 %t1011
  %t1015 = load i32, i32* %t1014
  %t1016 = getelementptr inbounds %Enemy, %Enemy* %t1012, i32 0, i32 0
  store i32 %t1015, i32* %t1016
  %t1017 = getelementptr inbounds i8*, i8** %t1010, i64 %t1011
  %t1018 = load i8*, i8** %t1017
  call void @star_rc_retain(i8* %t1018)
  %t1019 = load i8*, i8** %t1017
  %t1020 = getelementptr inbounds %Enemy, %Enemy* %t1012, i32 0, i32 1
  store i8* %t1019, i8** %t1020
  br label %table_idx_end_191
table_idx_oob_190:
  store %Enemy zeroinitializer, %Enemy* %t1012
  br label %table_idx_end_191
table_idx_end_191:
  %t1021 = load %Enemy, %Enemy* %t1012
  %t1022 = alloca %Enemy
  store %Enemy %t1021, %Enemy* %t1022
  %t1023 = getelementptr inbounds %Enemy, %Enemy* %t1022, i32 0, i32 0
  %t1024 = load i32, i32* %t1023
  %t1025 = load i8*, i8** %t872
  %t1026 = icmp eq i8* %t1025, null
  br i1 %t1026, label %table_read_null_192, label %table_read_real_193
table_read_null_192:
  br label %table_read_end_194
table_read_real_193:
  %t1027 = bitcast i8* %t1025 to { i64, i64, i32*, i8** }*
  %t1028 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1027, i32 0, i32 0
  %t1029 = load i64, i64* %t1028
  %t1030 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1027, i32 0, i32 2
  %t1031 = load i32*, i32** %t1030
  %t1032 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1027, i32 0, i32 3
  %t1033 = load i8**, i8*** %t1032
  br label %table_read_end_194
table_read_end_194:
  %t1034 = phi i64 [ 0, %table_read_null_192 ], [ %t1029, %table_read_real_193 ]
  %t1035 = phi i32* [ null, %table_read_null_192 ], [ %t1031, %table_read_real_193 ]
  %t1036 = phi i8** [ null, %table_read_null_192 ], [ %t1033, %table_read_real_193 ]
  %t1037 = sext i32 0 to i64
  %t1038 = alloca %Enemy
  %t1039 = icmp ult i64 %t1037, %t1034
  br i1 %t1039, label %table_idx_ok_195, label %table_idx_oob_196
table_idx_ok_195:
  %t1040 = getelementptr inbounds i32, i32* %t1035, i64 %t1037
  %t1041 = load i32, i32* %t1040
  %t1042 = getelementptr inbounds %Enemy, %Enemy* %t1038, i32 0, i32 0
  store i32 %t1041, i32* %t1042
  %t1043 = getelementptr inbounds i8*, i8** %t1036, i64 %t1037
  %t1044 = load i8*, i8** %t1043
  call void @star_rc_retain(i8* %t1044)
  %t1045 = load i8*, i8** %t1043
  %t1046 = getelementptr inbounds %Enemy, %Enemy* %t1038, i32 0, i32 1
  store i8* %t1045, i8** %t1046
  br label %table_idx_end_197
table_idx_oob_196:
  store %Enemy zeroinitializer, %Enemy* %t1038
  br label %table_idx_end_197
table_idx_end_197:
  %t1047 = load %Enemy, %Enemy* %t1038
  %t1048 = alloca %Enemy
  store %Enemy %t1047, %Enemy* %t1048
  %t1049 = getelementptr inbounds %Enemy, %Enemy* %t1048, i32 0, i32 0
  %t1050 = load i32, i32* %t1049
  %t1051 = getelementptr inbounds [38 x i8], [38 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1051, i32 %t1024, i32 %t1050)
  %t1052 = load i8*, i8** %t872
  call void @star_rc_release(i8* %t1052)
  %t1053 = load i8*, i8** %t774
  call void @star_rc_release(i8* %t1053)
  %t1054 = getelementptr inbounds %Enemy, %Enemy* %t696, i32 0, i32 1
  %t1055 = load i8*, i8** %t1054
  call void @star_rc_release(i8* %t1055)
  %t1056 = load i8*, i8** %t695
  call void @star_rc_release(i8* %t1056)
  %t1057 = getelementptr inbounds %Enemy, %Enemy* %t573, i32 0, i32 1
  %t1058 = load i8*, i8** %t1057
  call void @star_rc_release(i8* %t1058)
  %t1059 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t1059)
  ret i32 0
}


; par/swarm worker functions
define void @table_release_s_Enemy(i8* %objp) {
entry:
  %t17 = bitcast i8* %objp to { i64, i64, i32*, i8** }*
  %t18 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t17, i32 0, i32 0
  %t19 = load i64, i64* %t18
  %t20 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t17, i32 0, i32 2
  %t21 = load i32*, i32** %t20
  %t22 = bitcast i32* %t21 to i8*
  call void @free(i8* %t22)
  %t23 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t17, i32 0, i32 3
  %t24 = load i8**, i8*** %t23
  %t25 = alloca i64
  store i64 0, i64* %t25
  br label %table_release_cond_6
table_release_cond_6:
  %t26 = load i64, i64* %t25
  %t27 = icmp slt i64 %t26, %t19
  br i1 %t27, label %table_release_body_7, label %table_release_end_8
table_release_body_7:
  %t28 = getelementptr inbounds i8*, i8** %t24, i64 %t26
  %t29 = load i8*, i8** %t28
  call void @star_rc_release(i8* %t29)
  %t30 = add i64 %t26, 1
  store i64 %t30, i64* %t25
  br label %table_release_cond_6
table_release_end_8:
  %t31 = bitcast i8** %t24 to i8*
  call void @free(i8* %t31)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant [16 x i8] c"empty len = %d\0A\00"
@.str.1 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"Goblin\00" }
@.str.2 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"Orc\00" }
@.str.3 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"Troll\00" }
@.str.4 = private unnamed_addr constant [25 x i8] c"after 3 pushes len = %d\0A\00"
@.str.5 = private unnamed_addr constant [23 x i8] c"enemies[0] = %s hp=%d\0A\00"
@.str.6 = private unnamed_addr constant [23 x i8] c"enemies[2] = %s hp=%d\0A\00"
@.str.7 = private unnamed_addr constant { i64, i8*, [10 x i8] } { i64 -1, i8* null, [10 x i8] c"Orc Chief\00" }
@.str.8 = private unnamed_addr constant [33 x i8] c"enemies[1] after set = %s hp=%d\0A\00"
@.str.9 = private unnamed_addr constant [19 x i8] c"popped = %s hp=%d\0A\00"
@.str.10 = private unnamed_addr constant [20 x i8] c"len after pop = %d\0A\00"
@.str.11 = private unnamed_addr constant [21 x i8] c"enemies[99] hp = %d\0A\00"
@.str.12 = private unnamed_addr constant [24 x i8] c"pop from empty hp = %d\0A\00"
@.str.13 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"A\00" }
@.str.14 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"B\00" }
@.str.15 = private unnamed_addr constant [34 x i8] c"original len = %d clone len = %d\0A\00"
@.str.16 = private unnamed_addr constant [38 x i8] c"original[0] hp = %d clone[0] hp = %d\0A\00"
