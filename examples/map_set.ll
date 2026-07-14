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

%Point = type { i32, i32 }
%Option__i32 = type { i32, [1 x i64] }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = alloca i8*
  store i8* null, i8** %t0
  %t1 = getelementptr i8*, i8** null, i32 1
  %t2 = ptrtoint i8** %t1 to i64
  %t3 = getelementptr i32, i32* null, i32 1
  %t4 = ptrtoint i32* %t3 to i64
  %t5 = load i8*, i8** %t0
  %t6 = icmp eq i8* %t5, null
  br i1 %t6, label %map_cow_alloc_0, label %map_cow_check_1
map_cow_alloc_0:
  %t22 = bitcast void (i8*)* @map_release_str_i32 to i8*
  %t23 = call i8* @star_rc_alloc(i64 32, i8* %t22)
  %t24 = bitcast i8* %t23 to { i8**, i32*, i64, i64 }*
  %t25 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t24, i32 0, i32 0
  store i8** null, i8*** %t25
  %t26 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t24, i32 0, i32 1
  store i32* null, i32** %t26
  %t27 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t24, i32 0, i32 2
  store i64 0, i64* %t27
  %t28 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t24, i32 0, i32 3
  store i64 0, i64* %t28
  store i8* %t23, i8** %t0
  br label %map_cow_done_2
map_cow_check_1:
  %t29 = getelementptr inbounds i8, i8* %t5, i64 -16
  %t30 = bitcast i8* %t29 to i64*
  %t31 = load atomic i64, i64* %t30 seq_cst, align 8
  %t32 = icmp eq i64 %t31, 1
  br i1 %t32, label %map_cow_done_2, label %map_cow_clone_6
map_cow_clone_6:
  %t33 = bitcast i8* %t5 to { i8**, i32*, i64, i64 }*
  %t34 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t33, i32 0, i32 0
  %t35 = load i8**, i8*** %t34
  %t36 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t33, i32 0, i32 1
  %t37 = load i32*, i32** %t36
  %t38 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t33, i32 0, i32 2
  %t39 = load i64, i64* %t38
  %t40 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t33, i32 0, i32 3
  %t41 = load i64, i64* %t40
  %t42 = bitcast void (i8*)* @map_release_str_i32 to i8*
  %t43 = call i8* @star_rc_alloc(i64 32, i8* %t42)
  %t44 = bitcast i8* %t43 to { i8**, i32*, i64, i64 }*
  %t45 = mul i64 %t41, %t2
  %t46 = call i8* @malloc(i64 %t45)
  %t47 = bitcast i8* %t46 to i8**
  %t48 = mul i64 %t41, %t4
  %t49 = call i8* @malloc(i64 %t48)
  %t50 = bitcast i8* %t49 to i32*
  %t51 = icmp sgt i64 %t39, 0
  br i1 %t51, label %map_cow_copy_7, label %map_cow_after_copy_8
map_cow_copy_7:
  %t52 = mul i64 %t39, %t2
  %t53 = bitcast i8** %t35 to i8*
  call i8* @memcpy(i8* %t46, i8* %t53, i64 %t52)
  %t54 = mul i64 %t39, %t4
  %t55 = bitcast i32* %t37 to i8*
  call i8* @memcpy(i8* %t49, i8* %t55, i64 %t54)
  %t56 = alloca i64
  store i64 0, i64* %t56
  br label %map_cow_retain_cond_9
map_cow_retain_cond_9:
  %t57 = load i64, i64* %t56
  %t58 = icmp slt i64 %t57, %t39
  br i1 %t58, label %map_cow_retain_body_10, label %map_cow_retain_end_11
map_cow_retain_body_10:
  %t59 = getelementptr inbounds i8*, i8** %t47, i64 %t57
  %t60 = load i8*, i8** %t59
  call void @star_rc_retain(i8* %t60)
  %t61 = add i64 %t57, 1
  store i64 %t61, i64* %t56
  br label %map_cow_retain_cond_9
map_cow_retain_end_11:
  br label %map_cow_after_copy_8
map_cow_after_copy_8:
  %t62 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t44, i32 0, i32 0
  store i8** %t47, i8*** %t62
  %t63 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t44, i32 0, i32 1
  store i32* %t50, i32** %t63
  %t64 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t44, i32 0, i32 2
  store i64 %t39, i64* %t64
  %t65 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t44, i32 0, i32 3
  store i64 %t41, i64* %t65
  call void @star_rc_release(i8* %t5)
  store i8* %t43, i8** %t0
  br label %map_cow_done_2
map_cow_done_2:
  %t66 = load i8*, i8** %t0
  %t67 = bitcast i8* %t66 to { i8**, i32*, i64, i64 }*
  %t68 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t67, i32 0, i32 0
  %t69 = load i8**, i8*** %t68
  %t70 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t67, i32 0, i32 1
  %t71 = load i32*, i32** %t70
  %t72 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t67, i32 0, i32 2
  %t73 = load i64, i64* %t72
  %t74 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t67, i32 0, i32 3
  %t75 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t76 = load i8**, i8*** %t68
  %t79 = alloca i64
  store i64 0, i64* %t79
  br label %map_find_cond_12
map_find_cond_12:
  %t80 = load i64, i64* %t79
  %t81 = icmp slt i64 %t80, %t73
  br i1 %t81, label %map_find_body_13, label %map_find_end_16
map_find_body_13:
  %t82 = getelementptr inbounds i8*, i8** %t76, i64 %t80
  %t83 = load i8*, i8** %t82
  br label %map_find_eq_check_14
map_find_eq_check_14:
  %t84 = call i1 @eq_str(i8* %t83, i8* %t75)
  br i1 %t84, label %map_find_end_16, label %map_find_next_15
map_find_next_15:
  %t85 = add i64 %t80, 1
  store i64 %t85, i64* %t79
  br label %map_find_cond_12
map_find_end_16:
  %t86 = load i64, i64* %t79
  %t87 = icmp slt i64 %t86, %t73
  br i1 %t87, label %map_insert_overwrite_17, label %map_insert_new_18
map_insert_overwrite_17:
  %t88 = load i32*, i32** %t70
  %t89 = getelementptr inbounds i32, i32* %t88, i64 %t86
  store i32 30, i32* %t89
  br label %map_insert_after_19
map_insert_new_18:
  %t90 = load i64, i64* %t74
  %t91 = icmp sge i64 %t73, %t90
  br i1 %t91, label %map_insert_grow_20, label %map_insert_store_21
map_insert_grow_20:
  %t92 = mul i64 %t90, 2
  %t93 = icmp sgt i64 %t92, 0
  %t94 = select i1 %t93, i64 %t92, i64 1
  %t95 = getelementptr i8*, i8** null, i32 1
  %t96 = ptrtoint i8** %t95 to i64
  %t97 = mul i64 %t94, %t96
  %t98 = call i8* @malloc(i64 %t97)
  %t99 = bitcast i8* %t98 to i8**
  %t100 = getelementptr i32, i32* null, i32 1
  %t101 = ptrtoint i32* %t100 to i64
  %t102 = mul i64 %t94, %t101
  %t103 = call i8* @malloc(i64 %t102)
  %t104 = bitcast i8* %t103 to i32*
  %t105 = icmp sgt i64 %t90, 0
  br i1 %t105, label %map_insert_copy_22, label %map_insert_after_copy_23
map_insert_copy_22:
  %t106 = load i8**, i8*** %t68
  %t107 = mul i64 %t73, %t96
  %t108 = bitcast i8** %t106 to i8*
  call i8* @memcpy(i8* %t98, i8* %t108, i64 %t107)
  call void @free(i8* %t108)
  %t109 = load i32*, i32** %t70
  %t110 = mul i64 %t73, %t101
  %t111 = bitcast i32* %t109 to i8*
  call i8* @memcpy(i8* %t103, i8* %t111, i64 %t110)
  call void @free(i8* %t111)
  br label %map_insert_after_copy_23
map_insert_after_copy_23:
  store i8** %t99, i8*** %t68
  store i32* %t104, i32** %t70
  store i64 %t94, i64* %t74
  br label %map_insert_store_21
map_insert_store_21:
  %t112 = load i8**, i8*** %t68
  %t113 = load i32*, i32** %t70
  %t114 = getelementptr inbounds i8*, i8** %t112, i64 %t73
  store i8* %t75, i8** %t114
  %t115 = getelementptr inbounds i32, i32* %t113, i64 %t73
  store i32 30, i32* %t115
  %t116 = add i64 %t73, 1
  store i64 %t116, i64* %t72
  br label %map_insert_after_19
map_insert_after_19:
  %t117 = getelementptr i8*, i8** null, i32 1
  %t118 = ptrtoint i8** %t117 to i64
  %t119 = getelementptr i32, i32* null, i32 1
  %t120 = ptrtoint i32* %t119 to i64
  %t121 = load i8*, i8** %t0
  %t122 = icmp eq i8* %t121, null
  br i1 %t122, label %map_cow_alloc_24, label %map_cow_check_25
map_cow_alloc_24:
  %t123 = bitcast void (i8*)* @map_release_str_i32 to i8*
  %t124 = call i8* @star_rc_alloc(i64 32, i8* %t123)
  %t125 = bitcast i8* %t124 to { i8**, i32*, i64, i64 }*
  %t126 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t125, i32 0, i32 0
  store i8** null, i8*** %t126
  %t127 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t125, i32 0, i32 1
  store i32* null, i32** %t127
  %t128 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t125, i32 0, i32 2
  store i64 0, i64* %t128
  %t129 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t125, i32 0, i32 3
  store i64 0, i64* %t129
  store i8* %t124, i8** %t0
  br label %map_cow_done_26
map_cow_check_25:
  %t130 = getelementptr inbounds i8, i8* %t121, i64 -16
  %t131 = bitcast i8* %t130 to i64*
  %t132 = load atomic i64, i64* %t131 seq_cst, align 8
  %t133 = icmp eq i64 %t132, 1
  br i1 %t133, label %map_cow_done_26, label %map_cow_clone_27
map_cow_clone_27:
  %t134 = bitcast i8* %t121 to { i8**, i32*, i64, i64 }*
  %t135 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t134, i32 0, i32 0
  %t136 = load i8**, i8*** %t135
  %t137 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t134, i32 0, i32 1
  %t138 = load i32*, i32** %t137
  %t139 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t134, i32 0, i32 2
  %t140 = load i64, i64* %t139
  %t141 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t134, i32 0, i32 3
  %t142 = load i64, i64* %t141
  %t143 = bitcast void (i8*)* @map_release_str_i32 to i8*
  %t144 = call i8* @star_rc_alloc(i64 32, i8* %t143)
  %t145 = bitcast i8* %t144 to { i8**, i32*, i64, i64 }*
  %t146 = mul i64 %t142, %t118
  %t147 = call i8* @malloc(i64 %t146)
  %t148 = bitcast i8* %t147 to i8**
  %t149 = mul i64 %t142, %t120
  %t150 = call i8* @malloc(i64 %t149)
  %t151 = bitcast i8* %t150 to i32*
  %t152 = icmp sgt i64 %t140, 0
  br i1 %t152, label %map_cow_copy_28, label %map_cow_after_copy_29
map_cow_copy_28:
  %t153 = mul i64 %t140, %t118
  %t154 = bitcast i8** %t136 to i8*
  call i8* @memcpy(i8* %t147, i8* %t154, i64 %t153)
  %t155 = mul i64 %t140, %t120
  %t156 = bitcast i32* %t138 to i8*
  call i8* @memcpy(i8* %t150, i8* %t156, i64 %t155)
  %t157 = alloca i64
  store i64 0, i64* %t157
  br label %map_cow_retain_cond_30
map_cow_retain_cond_30:
  %t158 = load i64, i64* %t157
  %t159 = icmp slt i64 %t158, %t140
  br i1 %t159, label %map_cow_retain_body_31, label %map_cow_retain_end_32
map_cow_retain_body_31:
  %t160 = getelementptr inbounds i8*, i8** %t148, i64 %t158
  %t161 = load i8*, i8** %t160
  call void @star_rc_retain(i8* %t161)
  %t162 = add i64 %t158, 1
  store i64 %t162, i64* %t157
  br label %map_cow_retain_cond_30
map_cow_retain_end_32:
  br label %map_cow_after_copy_29
map_cow_after_copy_29:
  %t163 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t145, i32 0, i32 0
  store i8** %t148, i8*** %t163
  %t164 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t145, i32 0, i32 1
  store i32* %t151, i32** %t164
  %t165 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t145, i32 0, i32 2
  store i64 %t140, i64* %t165
  %t166 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t145, i32 0, i32 3
  store i64 %t142, i64* %t166
  call void @star_rc_release(i8* %t121)
  store i8* %t144, i8** %t0
  br label %map_cow_done_26
map_cow_done_26:
  %t167 = load i8*, i8** %t0
  %t168 = bitcast i8* %t167 to { i8**, i32*, i64, i64 }*
  %t169 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t168, i32 0, i32 0
  %t170 = load i8**, i8*** %t169
  %t171 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t168, i32 0, i32 1
  %t172 = load i32*, i32** %t171
  %t173 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t168, i32 0, i32 2
  %t174 = load i64, i64* %t173
  %t175 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t168, i32 0, i32 3
  %t176 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t177 = load i8**, i8*** %t169
  %t178 = alloca i64
  store i64 0, i64* %t178
  br label %map_find_cond_33
map_find_cond_33:
  %t179 = load i64, i64* %t178
  %t180 = icmp slt i64 %t179, %t174
  br i1 %t180, label %map_find_body_34, label %map_find_end_37
map_find_body_34:
  %t181 = getelementptr inbounds i8*, i8** %t177, i64 %t179
  %t182 = load i8*, i8** %t181
  br label %map_find_eq_check_35
map_find_eq_check_35:
  %t183 = call i1 @eq_str(i8* %t182, i8* %t176)
  br i1 %t183, label %map_find_end_37, label %map_find_next_36
map_find_next_36:
  %t184 = add i64 %t179, 1
  store i64 %t184, i64* %t178
  br label %map_find_cond_33
map_find_end_37:
  %t185 = load i64, i64* %t178
  %t186 = icmp slt i64 %t185, %t174
  br i1 %t186, label %map_insert_overwrite_38, label %map_insert_new_39
map_insert_overwrite_38:
  %t187 = load i32*, i32** %t171
  %t188 = getelementptr inbounds i32, i32* %t187, i64 %t185
  store i32 25, i32* %t188
  br label %map_insert_after_40
map_insert_new_39:
  %t189 = load i64, i64* %t175
  %t190 = icmp sge i64 %t174, %t189
  br i1 %t190, label %map_insert_grow_41, label %map_insert_store_42
map_insert_grow_41:
  %t191 = mul i64 %t189, 2
  %t192 = icmp sgt i64 %t191, 0
  %t193 = select i1 %t192, i64 %t191, i64 1
  %t194 = getelementptr i8*, i8** null, i32 1
  %t195 = ptrtoint i8** %t194 to i64
  %t196 = mul i64 %t193, %t195
  %t197 = call i8* @malloc(i64 %t196)
  %t198 = bitcast i8* %t197 to i8**
  %t199 = getelementptr i32, i32* null, i32 1
  %t200 = ptrtoint i32* %t199 to i64
  %t201 = mul i64 %t193, %t200
  %t202 = call i8* @malloc(i64 %t201)
  %t203 = bitcast i8* %t202 to i32*
  %t204 = icmp sgt i64 %t189, 0
  br i1 %t204, label %map_insert_copy_43, label %map_insert_after_copy_44
map_insert_copy_43:
  %t205 = load i8**, i8*** %t169
  %t206 = mul i64 %t174, %t195
  %t207 = bitcast i8** %t205 to i8*
  call i8* @memcpy(i8* %t197, i8* %t207, i64 %t206)
  call void @free(i8* %t207)
  %t208 = load i32*, i32** %t171
  %t209 = mul i64 %t174, %t200
  %t210 = bitcast i32* %t208 to i8*
  call i8* @memcpy(i8* %t202, i8* %t210, i64 %t209)
  call void @free(i8* %t210)
  br label %map_insert_after_copy_44
map_insert_after_copy_44:
  store i8** %t198, i8*** %t169
  store i32* %t203, i32** %t171
  store i64 %t193, i64* %t175
  br label %map_insert_store_42
map_insert_store_42:
  %t211 = load i8**, i8*** %t169
  %t212 = load i32*, i32** %t171
  %t213 = getelementptr inbounds i8*, i8** %t211, i64 %t174
  store i8* %t176, i8** %t213
  %t214 = getelementptr inbounds i32, i32* %t212, i64 %t174
  store i32 25, i32* %t214
  %t215 = add i64 %t174, 1
  store i64 %t215, i64* %t173
  br label %map_insert_after_40
map_insert_after_40:
  %t216 = load i8*, i8** %t0
  %t217 = icmp eq i8* %t216, null
  br i1 %t217, label %map_read_null_45, label %map_read_real_46
map_read_null_45:
  br label %map_read_end_47
map_read_real_46:
  %t218 = bitcast i8* %t216 to { i8**, i32*, i64, i64 }*
  %t219 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t218, i32 0, i32 0
  %t220 = load i8**, i8*** %t219
  %t221 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t218, i32 0, i32 1
  %t222 = load i32*, i32** %t221
  %t223 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t218, i32 0, i32 2
  %t224 = load i64, i64* %t223
  br label %map_read_end_47
map_read_end_47:
  %t225 = phi i8** [ null, %map_read_null_45 ], [ %t220, %map_read_real_46 ]
  %t226 = phi i32* [ null, %map_read_null_45 ], [ %t222, %map_read_real_46 ]
  %t227 = phi i64 [ 0, %map_read_null_45 ], [ %t224, %map_read_real_46 ]
  %t228 = trunc i64 %t227 to i32
  %t229 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t229, i32 %t228)
  %t230 = load i8*, i8** %t0
  %t231 = icmp eq i8* %t230, null
  br i1 %t231, label %map_read_null_48, label %map_read_real_49
map_read_null_48:
  br label %map_read_end_50
map_read_real_49:
  %t232 = bitcast i8* %t230 to { i8**, i32*, i64, i64 }*
  %t233 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t232, i32 0, i32 0
  %t234 = load i8**, i8*** %t233
  %t235 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t232, i32 0, i32 1
  %t236 = load i32*, i32** %t235
  %t237 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t232, i32 0, i32 2
  %t238 = load i64, i64* %t237
  br label %map_read_end_50
map_read_end_50:
  %t239 = phi i8** [ null, %map_read_null_48 ], [ %t234, %map_read_real_49 ]
  %t240 = phi i32* [ null, %map_read_null_48 ], [ %t236, %map_read_real_49 ]
  %t241 = phi i64 [ 0, %map_read_null_48 ], [ %t238, %map_read_real_49 ]
  %t242 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t243 = alloca i64
  store i64 0, i64* %t243
  br label %map_find_cond_51
map_find_cond_51:
  %t244 = load i64, i64* %t243
  %t245 = icmp slt i64 %t244, %t241
  br i1 %t245, label %map_find_body_52, label %map_find_end_55
map_find_body_52:
  %t246 = getelementptr inbounds i8*, i8** %t239, i64 %t244
  %t247 = load i8*, i8** %t246
  br label %map_find_eq_check_53
map_find_eq_check_53:
  %t248 = call i1 @eq_str(i8* %t247, i8* %t242)
  br i1 %t248, label %map_find_end_55, label %map_find_next_54
map_find_next_54:
  %t249 = add i64 %t244, 1
  store i64 %t249, i64* %t243
  br label %map_find_cond_51
map_find_end_55:
  %t250 = load i64, i64* %t243
  %t251 = icmp slt i64 %t250, %t241
  br i1 %t251, label %map_get_some_56, label %map_get_none_57
map_get_some_56:
  %t252 = getelementptr inbounds i32, i32* %t240, i64 %t250
  %t253 = load i32, i32* %t252
  %t254 = alloca %Option__i32
  %t255 = getelementptr inbounds %Option__i32, %Option__i32* %t254, i32 0, i32 0
  store i32 1, i32* %t255
  %t256 = getelementptr inbounds %Option__i32, %Option__i32* %t254, i32 0, i32 1
  %t257 = bitcast [1 x i64]* %t256 to { i32 }*
  %t258 = getelementptr inbounds { i32 }, { i32 }* %t257, i32 0, i32 0
  store i32 %t253, i32* %t258
  %t259 = load %Option__i32, %Option__i32* %t254
  br label %map_get_end_58
map_get_none_57:
  %t260 = alloca %Option__i32
  %t261 = getelementptr inbounds %Option__i32, %Option__i32* %t260, i32 0, i32 0
  store i32 0, i32* %t261
  %t262 = load %Option__i32, %Option__i32* %t260
  br label %map_get_end_58
map_get_end_58:
  %t263 = phi %Option__i32 [ %t259, %map_get_some_56 ], [ %t262, %map_get_none_57 ]
  %t264 = alloca %Option__i32
  store %Option__i32 %t263, %Option__i32* %t264
  br label %match_scrutinee_266
match_scrutinee_266:
  %t270 = getelementptr inbounds %Option__i32, %Option__i32* %t264, i32 0, i32 0
  %t271 = load i32, i32* %t270
  %t269 = icmp eq i32 %t271, 1
  br i1 %t269, label %match_then_0_267, label %match_next_0_268
match_then_0_267:
  %t272 = getelementptr inbounds %Option__i32, %Option__i32* %t264, i32 0, i32 1
  %t273 = bitcast [1 x i64]* %t272 to { i32 }*
  %t274 = getelementptr inbounds { i32 }, { i32 }* %t273, i32 0, i32 0
  %t275 = load i32, i32* %t274
  %t276 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t276, i32 %t275)
  br label %match_end_265
match_next_0_268:
  %t280 = getelementptr inbounds %Option__i32, %Option__i32* %t264, i32 0, i32 0
  %t281 = load i32, i32* %t280
  %t279 = icmp eq i32 %t281, 0
  br i1 %t279, label %match_then_1_277, label %match_next_1_278
match_then_1_277:
  %t282 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.5, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t282)
  %t283 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t283)
  br label %match_end_265
match_next_1_278:
  br label %match_end_265
match_end_265:
  %t284 = load i8*, i8** %t0
  %t285 = icmp eq i8* %t284, null
  br i1 %t285, label %map_read_null_59, label %map_read_real_60
map_read_null_59:
  br label %map_read_end_61
map_read_real_60:
  %t286 = bitcast i8* %t284 to { i8**, i32*, i64, i64 }*
  %t287 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t286, i32 0, i32 0
  %t288 = load i8**, i8*** %t287
  %t289 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t286, i32 0, i32 1
  %t290 = load i32*, i32** %t289
  %t291 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t286, i32 0, i32 2
  %t292 = load i64, i64* %t291
  br label %map_read_end_61
map_read_end_61:
  %t293 = phi i8** [ null, %map_read_null_59 ], [ %t288, %map_read_real_60 ]
  %t294 = phi i32* [ null, %map_read_null_59 ], [ %t290, %map_read_real_60 ]
  %t295 = phi i64 [ 0, %map_read_null_59 ], [ %t292, %map_read_real_60 ]
  %t296 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t297 = alloca i64
  store i64 0, i64* %t297
  br label %map_find_cond_62
map_find_cond_62:
  %t298 = load i64, i64* %t297
  %t299 = icmp slt i64 %t298, %t295
  br i1 %t299, label %map_find_body_63, label %map_find_end_66
map_find_body_63:
  %t300 = getelementptr inbounds i8*, i8** %t293, i64 %t298
  %t301 = load i8*, i8** %t300
  br label %map_find_eq_check_64
map_find_eq_check_64:
  %t302 = call i1 @eq_str(i8* %t301, i8* %t296)
  br i1 %t302, label %map_find_end_66, label %map_find_next_65
map_find_next_65:
  %t303 = add i64 %t298, 1
  store i64 %t303, i64* %t297
  br label %map_find_cond_62
map_find_end_66:
  %t304 = load i64, i64* %t297
  %t305 = icmp slt i64 %t304, %t295
  br i1 %t305, label %map_get_some_67, label %map_get_none_68
map_get_some_67:
  %t306 = getelementptr inbounds i32, i32* %t294, i64 %t304
  %t307 = load i32, i32* %t306
  %t308 = alloca %Option__i32
  %t309 = getelementptr inbounds %Option__i32, %Option__i32* %t308, i32 0, i32 0
  store i32 1, i32* %t309
  %t310 = getelementptr inbounds %Option__i32, %Option__i32* %t308, i32 0, i32 1
  %t311 = bitcast [1 x i64]* %t310 to { i32 }*
  %t312 = getelementptr inbounds { i32 }, { i32 }* %t311, i32 0, i32 0
  store i32 %t307, i32* %t312
  %t313 = load %Option__i32, %Option__i32* %t308
  br label %map_get_end_69
map_get_none_68:
  %t314 = alloca %Option__i32
  %t315 = getelementptr inbounds %Option__i32, %Option__i32* %t314, i32 0, i32 0
  store i32 0, i32* %t315
  %t316 = load %Option__i32, %Option__i32* %t314
  br label %map_get_end_69
map_get_end_69:
  %t317 = phi %Option__i32 [ %t313, %map_get_some_67 ], [ %t316, %map_get_none_68 ]
  %t318 = alloca %Option__i32
  store %Option__i32 %t317, %Option__i32* %t318
  br label %match_scrutinee_320
match_scrutinee_320:
  %t324 = getelementptr inbounds %Option__i32, %Option__i32* %t318, i32 0, i32 0
  %t325 = load i32, i32* %t324
  %t323 = icmp eq i32 %t325, 1
  br i1 %t323, label %match_then_0_321, label %match_next_0_322
match_then_0_321:
  %t326 = getelementptr inbounds %Option__i32, %Option__i32* %t318, i32 0, i32 1
  %t327 = bitcast [1 x i64]* %t326 to { i32 }*
  %t328 = getelementptr inbounds { i32 }, { i32 }* %t327, i32 0, i32 0
  %t329 = load i32, i32* %t328
  %t330 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t330, i32 %t329)
  br label %match_end_319
match_next_0_322:
  %t334 = getelementptr inbounds %Option__i32, %Option__i32* %t318, i32 0, i32 0
  %t335 = load i32, i32* %t334
  %t333 = icmp eq i32 %t335, 0
  br i1 %t333, label %match_then_1_331, label %match_next_1_332
match_then_1_331:
  %t336 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.9, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t336)
  %t337 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t337)
  br label %match_end_319
match_next_1_332:
  br label %match_end_319
match_end_319:
  %t338 = getelementptr i8*, i8** null, i32 1
  %t339 = ptrtoint i8** %t338 to i64
  %t340 = getelementptr i32, i32* null, i32 1
  %t341 = ptrtoint i32* %t340 to i64
  %t342 = load i8*, i8** %t0
  %t343 = icmp eq i8* %t342, null
  br i1 %t343, label %map_cow_alloc_70, label %map_cow_check_71
map_cow_alloc_70:
  %t344 = bitcast void (i8*)* @map_release_str_i32 to i8*
  %t345 = call i8* @star_rc_alloc(i64 32, i8* %t344)
  %t346 = bitcast i8* %t345 to { i8**, i32*, i64, i64 }*
  %t347 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t346, i32 0, i32 0
  store i8** null, i8*** %t347
  %t348 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t346, i32 0, i32 1
  store i32* null, i32** %t348
  %t349 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t346, i32 0, i32 2
  store i64 0, i64* %t349
  %t350 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t346, i32 0, i32 3
  store i64 0, i64* %t350
  store i8* %t345, i8** %t0
  br label %map_cow_done_72
map_cow_check_71:
  %t351 = getelementptr inbounds i8, i8* %t342, i64 -16
  %t352 = bitcast i8* %t351 to i64*
  %t353 = load atomic i64, i64* %t352 seq_cst, align 8
  %t354 = icmp eq i64 %t353, 1
  br i1 %t354, label %map_cow_done_72, label %map_cow_clone_73
map_cow_clone_73:
  %t355 = bitcast i8* %t342 to { i8**, i32*, i64, i64 }*
  %t356 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t355, i32 0, i32 0
  %t357 = load i8**, i8*** %t356
  %t358 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t355, i32 0, i32 1
  %t359 = load i32*, i32** %t358
  %t360 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t355, i32 0, i32 2
  %t361 = load i64, i64* %t360
  %t362 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t355, i32 0, i32 3
  %t363 = load i64, i64* %t362
  %t364 = bitcast void (i8*)* @map_release_str_i32 to i8*
  %t365 = call i8* @star_rc_alloc(i64 32, i8* %t364)
  %t366 = bitcast i8* %t365 to { i8**, i32*, i64, i64 }*
  %t367 = mul i64 %t363, %t339
  %t368 = call i8* @malloc(i64 %t367)
  %t369 = bitcast i8* %t368 to i8**
  %t370 = mul i64 %t363, %t341
  %t371 = call i8* @malloc(i64 %t370)
  %t372 = bitcast i8* %t371 to i32*
  %t373 = icmp sgt i64 %t361, 0
  br i1 %t373, label %map_cow_copy_74, label %map_cow_after_copy_75
map_cow_copy_74:
  %t374 = mul i64 %t361, %t339
  %t375 = bitcast i8** %t357 to i8*
  call i8* @memcpy(i8* %t368, i8* %t375, i64 %t374)
  %t376 = mul i64 %t361, %t341
  %t377 = bitcast i32* %t359 to i8*
  call i8* @memcpy(i8* %t371, i8* %t377, i64 %t376)
  %t378 = alloca i64
  store i64 0, i64* %t378
  br label %map_cow_retain_cond_76
map_cow_retain_cond_76:
  %t379 = load i64, i64* %t378
  %t380 = icmp slt i64 %t379, %t361
  br i1 %t380, label %map_cow_retain_body_77, label %map_cow_retain_end_78
map_cow_retain_body_77:
  %t381 = getelementptr inbounds i8*, i8** %t369, i64 %t379
  %t382 = load i8*, i8** %t381
  call void @star_rc_retain(i8* %t382)
  %t383 = add i64 %t379, 1
  store i64 %t383, i64* %t378
  br label %map_cow_retain_cond_76
map_cow_retain_end_78:
  br label %map_cow_after_copy_75
map_cow_after_copy_75:
  %t384 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t366, i32 0, i32 0
  store i8** %t369, i8*** %t384
  %t385 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t366, i32 0, i32 1
  store i32* %t372, i32** %t385
  %t386 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t366, i32 0, i32 2
  store i64 %t361, i64* %t386
  %t387 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t366, i32 0, i32 3
  store i64 %t363, i64* %t387
  call void @star_rc_release(i8* %t342)
  store i8* %t365, i8** %t0
  br label %map_cow_done_72
map_cow_done_72:
  %t388 = load i8*, i8** %t0
  %t389 = bitcast i8* %t388 to { i8**, i32*, i64, i64 }*
  %t390 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t389, i32 0, i32 0
  %t391 = load i8**, i8*** %t390
  %t392 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t389, i32 0, i32 1
  %t393 = load i32*, i32** %t392
  %t394 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t389, i32 0, i32 2
  %t395 = load i64, i64* %t394
  %t396 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t389, i32 0, i32 3
  %t397 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t398 = load i8**, i8*** %t390
  %t399 = alloca i64
  store i64 0, i64* %t399
  br label %map_find_cond_79
map_find_cond_79:
  %t400 = load i64, i64* %t399
  %t401 = icmp slt i64 %t400, %t395
  br i1 %t401, label %map_find_body_80, label %map_find_end_83
map_find_body_80:
  %t402 = getelementptr inbounds i8*, i8** %t398, i64 %t400
  %t403 = load i8*, i8** %t402
  br label %map_find_eq_check_81
map_find_eq_check_81:
  %t404 = call i1 @eq_str(i8* %t403, i8* %t397)
  br i1 %t404, label %map_find_end_83, label %map_find_next_82
map_find_next_82:
  %t405 = add i64 %t400, 1
  store i64 %t405, i64* %t399
  br label %map_find_cond_79
map_find_end_83:
  %t406 = load i64, i64* %t399
  %t407 = icmp slt i64 %t406, %t395
  br i1 %t407, label %map_insert_overwrite_84, label %map_insert_new_85
map_insert_overwrite_84:
  %t408 = load i32*, i32** %t392
  %t409 = getelementptr inbounds i32, i32* %t408, i64 %t406
  store i32 31, i32* %t409
  br label %map_insert_after_86
map_insert_new_85:
  %t410 = load i64, i64* %t396
  %t411 = icmp sge i64 %t395, %t410
  br i1 %t411, label %map_insert_grow_87, label %map_insert_store_88
map_insert_grow_87:
  %t412 = mul i64 %t410, 2
  %t413 = icmp sgt i64 %t412, 0
  %t414 = select i1 %t413, i64 %t412, i64 1
  %t415 = getelementptr i8*, i8** null, i32 1
  %t416 = ptrtoint i8** %t415 to i64
  %t417 = mul i64 %t414, %t416
  %t418 = call i8* @malloc(i64 %t417)
  %t419 = bitcast i8* %t418 to i8**
  %t420 = getelementptr i32, i32* null, i32 1
  %t421 = ptrtoint i32* %t420 to i64
  %t422 = mul i64 %t414, %t421
  %t423 = call i8* @malloc(i64 %t422)
  %t424 = bitcast i8* %t423 to i32*
  %t425 = icmp sgt i64 %t410, 0
  br i1 %t425, label %map_insert_copy_89, label %map_insert_after_copy_90
map_insert_copy_89:
  %t426 = load i8**, i8*** %t390
  %t427 = mul i64 %t395, %t416
  %t428 = bitcast i8** %t426 to i8*
  call i8* @memcpy(i8* %t418, i8* %t428, i64 %t427)
  call void @free(i8* %t428)
  %t429 = load i32*, i32** %t392
  %t430 = mul i64 %t395, %t421
  %t431 = bitcast i32* %t429 to i8*
  call i8* @memcpy(i8* %t423, i8* %t431, i64 %t430)
  call void @free(i8* %t431)
  br label %map_insert_after_copy_90
map_insert_after_copy_90:
  store i8** %t419, i8*** %t390
  store i32* %t424, i32** %t392
  store i64 %t414, i64* %t396
  br label %map_insert_store_88
map_insert_store_88:
  %t432 = load i8**, i8*** %t390
  %t433 = load i32*, i32** %t392
  %t434 = getelementptr inbounds i8*, i8** %t432, i64 %t395
  store i8* %t397, i8** %t434
  %t435 = getelementptr inbounds i32, i32* %t433, i64 %t395
  store i32 31, i32* %t435
  %t436 = add i64 %t395, 1
  store i64 %t436, i64* %t394
  br label %map_insert_after_86
map_insert_after_86:
  %t437 = load i8*, i8** %t0
  %t438 = icmp eq i8* %t437, null
  br i1 %t438, label %map_read_null_91, label %map_read_real_92
map_read_null_91:
  br label %map_read_end_93
map_read_real_92:
  %t439 = bitcast i8* %t437 to { i8**, i32*, i64, i64 }*
  %t440 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t439, i32 0, i32 0
  %t441 = load i8**, i8*** %t440
  %t442 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t439, i32 0, i32 1
  %t443 = load i32*, i32** %t442
  %t444 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t439, i32 0, i32 2
  %t445 = load i64, i64* %t444
  br label %map_read_end_93
map_read_end_93:
  %t446 = phi i8** [ null, %map_read_null_91 ], [ %t441, %map_read_real_92 ]
  %t447 = phi i32* [ null, %map_read_null_91 ], [ %t443, %map_read_real_92 ]
  %t448 = phi i64 [ 0, %map_read_null_91 ], [ %t445, %map_read_real_92 ]
  %t449 = trunc i64 %t448 to i32
  %t450 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t450, i32 %t449)
  %t451 = load i8*, i8** %t0
  %t452 = icmp eq i8* %t451, null
  br i1 %t452, label %map_read_null_94, label %map_read_real_95
map_read_null_94:
  br label %map_read_end_96
map_read_real_95:
  %t453 = bitcast i8* %t451 to { i8**, i32*, i64, i64 }*
  %t454 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t453, i32 0, i32 0
  %t455 = load i8**, i8*** %t454
  %t456 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t453, i32 0, i32 1
  %t457 = load i32*, i32** %t456
  %t458 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t453, i32 0, i32 2
  %t459 = load i64, i64* %t458
  br label %map_read_end_96
map_read_end_96:
  %t460 = phi i8** [ null, %map_read_null_94 ], [ %t455, %map_read_real_95 ]
  %t461 = phi i32* [ null, %map_read_null_94 ], [ %t457, %map_read_real_95 ]
  %t462 = phi i64 [ 0, %map_read_null_94 ], [ %t459, %map_read_real_95 ]
  %t463 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t464 = alloca i64
  store i64 0, i64* %t464
  br label %map_find_cond_97
map_find_cond_97:
  %t465 = load i64, i64* %t464
  %t466 = icmp slt i64 %t465, %t462
  br i1 %t466, label %map_find_body_98, label %map_find_end_101
map_find_body_98:
  %t467 = getelementptr inbounds i8*, i8** %t460, i64 %t465
  %t468 = load i8*, i8** %t467
  br label %map_find_eq_check_99
map_find_eq_check_99:
  %t469 = call i1 @eq_str(i8* %t468, i8* %t463)
  br i1 %t469, label %map_find_end_101, label %map_find_next_100
map_find_next_100:
  %t470 = add i64 %t465, 1
  store i64 %t470, i64* %t464
  br label %map_find_cond_97
map_find_end_101:
  %t471 = load i64, i64* %t464
  %t472 = icmp slt i64 %t471, %t462
  br i1 %t472, label %map_get_some_102, label %map_get_none_103
map_get_some_102:
  %t473 = getelementptr inbounds i32, i32* %t461, i64 %t471
  %t474 = load i32, i32* %t473
  %t475 = alloca %Option__i32
  %t476 = getelementptr inbounds %Option__i32, %Option__i32* %t475, i32 0, i32 0
  store i32 1, i32* %t476
  %t477 = getelementptr inbounds %Option__i32, %Option__i32* %t475, i32 0, i32 1
  %t478 = bitcast [1 x i64]* %t477 to { i32 }*
  %t479 = getelementptr inbounds { i32 }, { i32 }* %t478, i32 0, i32 0
  store i32 %t474, i32* %t479
  %t480 = load %Option__i32, %Option__i32* %t475
  br label %map_get_end_104
map_get_none_103:
  %t481 = alloca %Option__i32
  %t482 = getelementptr inbounds %Option__i32, %Option__i32* %t481, i32 0, i32 0
  store i32 0, i32* %t482
  %t483 = load %Option__i32, %Option__i32* %t481
  br label %map_get_end_104
map_get_end_104:
  %t484 = phi %Option__i32 [ %t480, %map_get_some_102 ], [ %t483, %map_get_none_103 ]
  %t485 = alloca %Option__i32
  store %Option__i32 %t484, %Option__i32* %t485
  br label %match_scrutinee_487
match_scrutinee_487:
  %t491 = getelementptr inbounds %Option__i32, %Option__i32* %t485, i32 0, i32 0
  %t492 = load i32, i32* %t491
  %t490 = icmp eq i32 %t492, 1
  br i1 %t490, label %match_then_0_488, label %match_next_0_489
match_then_0_488:
  %t493 = getelementptr inbounds %Option__i32, %Option__i32* %t485, i32 0, i32 1
  %t494 = bitcast [1 x i64]* %t493 to { i32 }*
  %t495 = getelementptr inbounds { i32 }, { i32 }* %t494, i32 0, i32 0
  %t496 = load i32, i32* %t495
  %t497 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t497, i32 %t496)
  br label %match_end_486
match_next_0_489:
  %t501 = getelementptr inbounds %Option__i32, %Option__i32* %t485, i32 0, i32 0
  %t502 = load i32, i32* %t501
  %t500 = icmp eq i32 %t502, 0
  br i1 %t500, label %match_then_1_498, label %match_next_1_499
match_then_1_498:
  %t503 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.15, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t503)
  %t504 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t504)
  br label %match_end_486
match_next_1_499:
  br label %match_end_486
match_end_486:
  %t505 = alloca i8*
  %t506 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.17, i64 0, i32 2, i64 0
  store i8* %t506, i8** %t505
  %t507 = load i8*, i8** %t0
  %t508 = icmp eq i8* %t507, null
  br i1 %t508, label %map_read_null_105, label %map_read_real_106
map_read_null_105:
  br label %map_read_end_107
map_read_real_106:
  %t509 = bitcast i8* %t507 to { i8**, i32*, i64, i64 }*
  %t510 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t509, i32 0, i32 0
  %t511 = load i8**, i8*** %t510
  %t512 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t509, i32 0, i32 1
  %t513 = load i32*, i32** %t512
  %t514 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t509, i32 0, i32 2
  %t515 = load i64, i64* %t514
  br label %map_read_end_107
map_read_end_107:
  %t516 = phi i8** [ null, %map_read_null_105 ], [ %t511, %map_read_real_106 ]
  %t517 = phi i32* [ null, %map_read_null_105 ], [ %t513, %map_read_real_106 ]
  %t518 = phi i64 [ 0, %map_read_null_105 ], [ %t515, %map_read_real_106 ]
  %t519 = load i8*, i8** %t505
  %t520 = load i8*, i8** %t505
  call void @star_rc_retain(i8* %t520)
  %t521 = alloca i64
  store i64 0, i64* %t521
  br label %map_find_cond_108
map_find_cond_108:
  %t522 = load i64, i64* %t521
  %t523 = icmp slt i64 %t522, %t518
  br i1 %t523, label %map_find_body_109, label %map_find_end_112
map_find_body_109:
  %t524 = getelementptr inbounds i8*, i8** %t516, i64 %t522
  %t525 = load i8*, i8** %t524
  br label %map_find_eq_check_110
map_find_eq_check_110:
  %t526 = call i1 @eq_str(i8* %t525, i8* %t519)
  br i1 %t526, label %map_find_end_112, label %map_find_next_111
map_find_next_111:
  %t527 = add i64 %t522, 1
  store i64 %t527, i64* %t521
  br label %map_find_cond_108
map_find_end_112:
  %t528 = load i64, i64* %t521
  %t529 = icmp slt i64 %t528, %t518
  %t530 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.18, i64 0, i64 0
  %t531 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.19, i64 0, i64 0
  %t532 = select i1 %t529, i8* %t530, i8* %t531
  %t533 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.20, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t533, i8* %t532)
  %t534 = getelementptr i8*, i8** null, i32 1
  %t535 = ptrtoint i8** %t534 to i64
  %t536 = getelementptr i32, i32* null, i32 1
  %t537 = ptrtoint i32* %t536 to i64
  %t538 = load i8*, i8** %t0
  %t539 = icmp eq i8* %t538, null
  br i1 %t539, label %map_cow_alloc_113, label %map_cow_check_114
map_cow_alloc_113:
  %t540 = bitcast void (i8*)* @map_release_str_i32 to i8*
  %t541 = call i8* @star_rc_alloc(i64 32, i8* %t540)
  %t542 = bitcast i8* %t541 to { i8**, i32*, i64, i64 }*
  %t543 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t542, i32 0, i32 0
  store i8** null, i8*** %t543
  %t544 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t542, i32 0, i32 1
  store i32* null, i32** %t544
  %t545 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t542, i32 0, i32 2
  store i64 0, i64* %t545
  %t546 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t542, i32 0, i32 3
  store i64 0, i64* %t546
  store i8* %t541, i8** %t0
  br label %map_cow_done_115
map_cow_check_114:
  %t547 = getelementptr inbounds i8, i8* %t538, i64 -16
  %t548 = bitcast i8* %t547 to i64*
  %t549 = load atomic i64, i64* %t548 seq_cst, align 8
  %t550 = icmp eq i64 %t549, 1
  br i1 %t550, label %map_cow_done_115, label %map_cow_clone_116
map_cow_clone_116:
  %t551 = bitcast i8* %t538 to { i8**, i32*, i64, i64 }*
  %t552 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t551, i32 0, i32 0
  %t553 = load i8**, i8*** %t552
  %t554 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t551, i32 0, i32 1
  %t555 = load i32*, i32** %t554
  %t556 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t551, i32 0, i32 2
  %t557 = load i64, i64* %t556
  %t558 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t551, i32 0, i32 3
  %t559 = load i64, i64* %t558
  %t560 = bitcast void (i8*)* @map_release_str_i32 to i8*
  %t561 = call i8* @star_rc_alloc(i64 32, i8* %t560)
  %t562 = bitcast i8* %t561 to { i8**, i32*, i64, i64 }*
  %t563 = mul i64 %t559, %t535
  %t564 = call i8* @malloc(i64 %t563)
  %t565 = bitcast i8* %t564 to i8**
  %t566 = mul i64 %t559, %t537
  %t567 = call i8* @malloc(i64 %t566)
  %t568 = bitcast i8* %t567 to i32*
  %t569 = icmp sgt i64 %t557, 0
  br i1 %t569, label %map_cow_copy_117, label %map_cow_after_copy_118
map_cow_copy_117:
  %t570 = mul i64 %t557, %t535
  %t571 = bitcast i8** %t553 to i8*
  call i8* @memcpy(i8* %t564, i8* %t571, i64 %t570)
  %t572 = mul i64 %t557, %t537
  %t573 = bitcast i32* %t555 to i8*
  call i8* @memcpy(i8* %t567, i8* %t573, i64 %t572)
  %t574 = alloca i64
  store i64 0, i64* %t574
  br label %map_cow_retain_cond_119
map_cow_retain_cond_119:
  %t575 = load i64, i64* %t574
  %t576 = icmp slt i64 %t575, %t557
  br i1 %t576, label %map_cow_retain_body_120, label %map_cow_retain_end_121
map_cow_retain_body_120:
  %t577 = getelementptr inbounds i8*, i8** %t565, i64 %t575
  %t578 = load i8*, i8** %t577
  call void @star_rc_retain(i8* %t578)
  %t579 = add i64 %t575, 1
  store i64 %t579, i64* %t574
  br label %map_cow_retain_cond_119
map_cow_retain_end_121:
  br label %map_cow_after_copy_118
map_cow_after_copy_118:
  %t580 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t562, i32 0, i32 0
  store i8** %t565, i8*** %t580
  %t581 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t562, i32 0, i32 1
  store i32* %t568, i32** %t581
  %t582 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t562, i32 0, i32 2
  store i64 %t557, i64* %t582
  %t583 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t562, i32 0, i32 3
  store i64 %t559, i64* %t583
  call void @star_rc_release(i8* %t538)
  store i8* %t561, i8** %t0
  br label %map_cow_done_115
map_cow_done_115:
  %t584 = load i8*, i8** %t0
  %t585 = bitcast i8* %t584 to { i8**, i32*, i64, i64 }*
  %t586 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t585, i32 0, i32 0
  %t587 = load i8**, i8*** %t586
  %t588 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t585, i32 0, i32 1
  %t589 = load i32*, i32** %t588
  %t590 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t585, i32 0, i32 2
  %t591 = load i64, i64* %t590
  %t592 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t585, i32 0, i32 3
  %t593 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.21, i64 0, i32 2, i64 0
  %t594 = alloca i64
  store i64 0, i64* %t594
  br label %map_find_cond_122
map_find_cond_122:
  %t595 = load i64, i64* %t594
  %t596 = icmp slt i64 %t595, %t591
  br i1 %t596, label %map_find_body_123, label %map_find_end_126
map_find_body_123:
  %t597 = getelementptr inbounds i8*, i8** %t587, i64 %t595
  %t598 = load i8*, i8** %t597
  br label %map_find_eq_check_124
map_find_eq_check_124:
  %t599 = call i1 @eq_str(i8* %t598, i8* %t593)
  br i1 %t599, label %map_find_end_126, label %map_find_next_125
map_find_next_125:
  %t600 = add i64 %t595, 1
  store i64 %t600, i64* %t594
  br label %map_find_cond_122
map_find_end_126:
  %t601 = load i64, i64* %t594
  %t602 = icmp slt i64 %t601, %t591
  br i1 %t602, label %map_remove_some_127, label %map_remove_none_128
map_remove_some_127:
  %t603 = getelementptr inbounds i8*, i8** %t587, i64 %t601
  %t604 = getelementptr inbounds i32, i32* %t589, i64 %t601
  %t605 = load i32, i32* %t604
  %t606 = load i8*, i8** %t603
  call void @star_rc_release(i8* %t606)
  %t607 = sub i64 %t591, 1
  %t608 = getelementptr inbounds i8*, i8** %t587, i64 %t607
  %t609 = load i8*, i8** %t608
  %t610 = getelementptr inbounds i32, i32* %t589, i64 %t607
  %t611 = load i32, i32* %t610
  store i8* %t609, i8** %t603
  store i32 %t611, i32* %t604
  store i64 %t607, i64* %t590
  %t612 = alloca %Option__i32
  %t613 = getelementptr inbounds %Option__i32, %Option__i32* %t612, i32 0, i32 0
  store i32 1, i32* %t613
  %t614 = getelementptr inbounds %Option__i32, %Option__i32* %t612, i32 0, i32 1
  %t615 = bitcast [1 x i64]* %t614 to { i32 }*
  %t616 = getelementptr inbounds { i32 }, { i32 }* %t615, i32 0, i32 0
  store i32 %t605, i32* %t616
  %t617 = load %Option__i32, %Option__i32* %t612
  br label %map_remove_end_129
map_remove_none_128:
  %t618 = alloca %Option__i32
  %t619 = getelementptr inbounds %Option__i32, %Option__i32* %t618, i32 0, i32 0
  store i32 0, i32* %t619
  %t620 = load %Option__i32, %Option__i32* %t618
  br label %map_remove_end_129
map_remove_end_129:
  %t621 = phi %Option__i32 [ %t617, %map_remove_some_127 ], [ %t620, %map_remove_none_128 ]
  %t622 = alloca %Option__i32
  store %Option__i32 %t621, %Option__i32* %t622
  br label %match_scrutinee_624
match_scrutinee_624:
  %t628 = getelementptr inbounds %Option__i32, %Option__i32* %t622, i32 0, i32 0
  %t629 = load i32, i32* %t628
  %t627 = icmp eq i32 %t629, 1
  br i1 %t627, label %match_then_0_625, label %match_next_0_626
match_then_0_625:
  %t630 = getelementptr inbounds %Option__i32, %Option__i32* %t622, i32 0, i32 1
  %t631 = bitcast [1 x i64]* %t630 to { i32 }*
  %t632 = getelementptr inbounds { i32 }, { i32 }* %t631, i32 0, i32 0
  %t633 = load i32, i32* %t632
  %t634 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t634, i32 %t633)
  br label %match_end_623
match_next_0_626:
  %t638 = getelementptr inbounds %Option__i32, %Option__i32* %t622, i32 0, i32 0
  %t639 = load i32, i32* %t638
  %t637 = icmp eq i32 %t639, 0
  br i1 %t637, label %match_then_1_635, label %match_next_1_636
match_then_1_635:
  %t640 = getelementptr inbounds { i64, i8*, [13 x i8] }, { i64, i8*, [13 x i8] }* @.str.23, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t640)
  %t641 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.24, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t641)
  br label %match_end_623
match_next_1_636:
  br label %match_end_623
match_end_623:
  %t642 = load i8*, i8** %t0
  %t643 = icmp eq i8* %t642, null
  br i1 %t643, label %map_read_null_130, label %map_read_real_131
map_read_null_130:
  br label %map_read_end_132
map_read_real_131:
  %t644 = bitcast i8* %t642 to { i8**, i32*, i64, i64 }*
  %t645 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t644, i32 0, i32 0
  %t646 = load i8**, i8*** %t645
  %t647 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t644, i32 0, i32 1
  %t648 = load i32*, i32** %t647
  %t649 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t644, i32 0, i32 2
  %t650 = load i64, i64* %t649
  br label %map_read_end_132
map_read_end_132:
  %t651 = phi i8** [ null, %map_read_null_130 ], [ %t646, %map_read_real_131 ]
  %t652 = phi i32* [ null, %map_read_null_130 ], [ %t648, %map_read_real_131 ]
  %t653 = phi i64 [ 0, %map_read_null_130 ], [ %t650, %map_read_real_131 ]
  %t654 = load i8*, i8** %t505
  %t655 = load i8*, i8** %t505
  call void @star_rc_retain(i8* %t655)
  %t656 = alloca i64
  store i64 0, i64* %t656
  br label %map_find_cond_133
map_find_cond_133:
  %t657 = load i64, i64* %t656
  %t658 = icmp slt i64 %t657, %t653
  br i1 %t658, label %map_find_body_134, label %map_find_end_137
map_find_body_134:
  %t659 = getelementptr inbounds i8*, i8** %t651, i64 %t657
  %t660 = load i8*, i8** %t659
  br label %map_find_eq_check_135
map_find_eq_check_135:
  %t661 = call i1 @eq_str(i8* %t660, i8* %t654)
  br i1 %t661, label %map_find_end_137, label %map_find_next_136
map_find_next_136:
  %t662 = add i64 %t657, 1
  store i64 %t662, i64* %t656
  br label %map_find_cond_133
map_find_end_137:
  %t663 = load i64, i64* %t656
  %t664 = icmp slt i64 %t663, %t653
  %t665 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.25, i64 0, i64 0
  %t666 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.26, i64 0, i64 0
  %t667 = select i1 %t664, i8* %t665, i8* %t666
  %t668 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.27, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t668, i8* %t667)
  %t669 = load i8*, i8** %t0
  %t670 = icmp eq i8* %t669, null
  br i1 %t670, label %map_read_null_138, label %map_read_real_139
map_read_null_138:
  br label %map_read_end_140
map_read_real_139:
  %t671 = bitcast i8* %t669 to { i8**, i32*, i64, i64 }*
  %t672 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t671, i32 0, i32 0
  %t673 = load i8**, i8*** %t672
  %t674 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t671, i32 0, i32 1
  %t675 = load i32*, i32** %t674
  %t676 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t671, i32 0, i32 2
  %t677 = load i64, i64* %t676
  br label %map_read_end_140
map_read_end_140:
  %t678 = phi i8** [ null, %map_read_null_138 ], [ %t673, %map_read_real_139 ]
  %t679 = phi i32* [ null, %map_read_null_138 ], [ %t675, %map_read_real_139 ]
  %t680 = phi i64 [ 0, %map_read_null_138 ], [ %t677, %map_read_real_139 ]
  %t681 = trunc i64 %t680 to i32
  %t682 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.28, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t682, i32 %t681)
  %t683 = alloca i8*
  store i8* null, i8** %t683
  %t684 = getelementptr i32, i32* null, i32 1
  %t685 = ptrtoint i32* %t684 to i64
  %t686 = load i8*, i8** %t683
  %t687 = icmp eq i8* %t686, null
  br i1 %t687, label %set_cow_alloc_141, label %set_cow_check_142
set_cow_alloc_141:
  %t692 = bitcast void (i8*)* @set_release_i32 to i8*
  %t693 = call i8* @star_rc_alloc(i64 24, i8* %t692)
  %t694 = bitcast i8* %t693 to { i32*, i64, i64 }*
  %t695 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t694, i32 0, i32 0
  store i32* null, i32** %t695
  %t696 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t694, i32 0, i32 1
  store i64 0, i64* %t696
  %t697 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t694, i32 0, i32 2
  store i64 0, i64* %t697
  store i8* %t693, i8** %t683
  br label %set_cow_done_143
set_cow_check_142:
  %t698 = getelementptr inbounds i8, i8* %t686, i64 -16
  %t699 = bitcast i8* %t698 to i64*
  %t700 = load atomic i64, i64* %t699 seq_cst, align 8
  %t701 = icmp eq i64 %t700, 1
  br i1 %t701, label %set_cow_done_143, label %set_cow_clone_144
set_cow_clone_144:
  %t702 = bitcast i8* %t686 to { i32*, i64, i64 }*
  %t703 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t702, i32 0, i32 0
  %t704 = load i32*, i32** %t703
  %t705 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t702, i32 0, i32 1
  %t706 = load i64, i64* %t705
  %t707 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t702, i32 0, i32 2
  %t708 = load i64, i64* %t707
  %t709 = bitcast void (i8*)* @set_release_i32 to i8*
  %t710 = call i8* @star_rc_alloc(i64 24, i8* %t709)
  %t711 = bitcast i8* %t710 to { i32*, i64, i64 }*
  %t712 = mul i64 %t708, %t685
  %t713 = call i8* @malloc(i64 %t712)
  %t714 = bitcast i8* %t713 to i32*
  %t715 = icmp sgt i64 %t706, 0
  br i1 %t715, label %set_cow_copy_145, label %set_cow_after_copy_146
set_cow_copy_145:
  %t716 = mul i64 %t706, %t685
  %t717 = bitcast i32* %t704 to i8*
  call i8* @memcpy(i8* %t713, i8* %t717, i64 %t716)
  br label %set_cow_after_copy_146
set_cow_after_copy_146:
  %t718 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t711, i32 0, i32 0
  store i32* %t714, i32** %t718
  %t719 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t711, i32 0, i32 1
  store i64 %t706, i64* %t719
  %t720 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t711, i32 0, i32 2
  store i64 %t708, i64* %t720
  call void @star_rc_release(i8* %t686)
  store i8* %t710, i8** %t683
  br label %set_cow_done_143
set_cow_done_143:
  %t721 = load i8*, i8** %t683
  %t722 = bitcast i8* %t721 to { i32*, i64, i64 }*
  %t723 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t722, i32 0, i32 0
  %t724 = load i32*, i32** %t723
  %t725 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t722, i32 0, i32 1
  %t726 = load i64, i64* %t725
  %t727 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t722, i32 0, i32 2
  %t728 = load i32*, i32** %t723
  %t730 = alloca i64
  store i64 0, i64* %t730
  %t731 = alloca i1
  store i1 false, i1* %t731
  br label %find_cond_147
find_cond_147:
  %t732 = load i64, i64* %t730
  %t733 = icmp slt i64 %t732, %t726
  br i1 %t733, label %find_body_148, label %find_end_151
find_body_148:
  %t734 = getelementptr inbounds i32, i32* %t728, i64 %t732
  %t735 = load i32, i32* %t734
  br label %find_eq_check_149
find_eq_check_149:
  %t736 = call i1 @eq_i32(i32 %t735, i32 1)
  br i1 %t736, label %find_end_151, label %find_next_150
find_next_150:
  %t737 = add i64 %t732, 1
  store i64 %t737, i64* %t730
  br label %find_cond_147
find_end_151:
  %t738 = load i64, i64* %t730
  %t739 = icmp slt i64 %t738, %t726
  br i1 %t739, label %set_insert_end_153, label %set_insert_do_152
set_insert_do_152:
  %t740 = load i64, i64* %t727
  %t741 = load i32*, i32** %t723
  %t742 = icmp sge i64 %t726, %t740
  br i1 %t742, label %set_insert_grow_154, label %set_insert_store_155
set_insert_grow_154:
  %t743 = mul i64 %t740, 2
  %t744 = icmp sgt i64 %t743, 0
  %t745 = select i1 %t744, i64 %t743, i64 1
  %t746 = getelementptr i32, i32* null, i32 1
  %t747 = ptrtoint i32* %t746 to i64
  %t748 = mul i64 %t745, %t747
  %t749 = call i8* @malloc(i64 %t748)
  %t750 = bitcast i8* %t749 to i32*
  %t751 = icmp sgt i64 %t740, 0
  br i1 %t751, label %set_insert_copy_156, label %set_insert_after_copy_157
set_insert_copy_156:
  %t752 = mul i64 %t726, %t747
  %t753 = bitcast i32* %t741 to i8*
  call i8* @memcpy(i8* %t749, i8* %t753, i64 %t752)
  call void @free(i8* %t753)
  br label %set_insert_after_copy_157
set_insert_after_copy_157:
  store i32* %t750, i32** %t723
  store i64 %t745, i64* %t727
  br label %set_insert_store_155
set_insert_store_155:
  %t754 = load i32*, i32** %t723
  %t755 = getelementptr inbounds i32, i32* %t754, i64 %t726
  store i32 1, i32* %t755
  %t756 = add i64 %t726, 1
  store i64 %t756, i64* %t725
  br label %set_insert_end_153
set_insert_end_153:
  %t757 = phi i1 [ false, %find_end_151 ], [ true, %set_insert_store_155 ]
  %t758 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.29, i64 0, i64 0
  %t759 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.30, i64 0, i64 0
  %t760 = select i1 %t757, i8* %t758, i8* %t759
  %t761 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.31, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t761, i8* %t760)
  %t762 = getelementptr i32, i32* null, i32 1
  %t763 = ptrtoint i32* %t762 to i64
  %t764 = load i8*, i8** %t683
  %t765 = icmp eq i8* %t764, null
  br i1 %t765, label %set_cow_alloc_158, label %set_cow_check_159
set_cow_alloc_158:
  %t766 = bitcast void (i8*)* @set_release_i32 to i8*
  %t767 = call i8* @star_rc_alloc(i64 24, i8* %t766)
  %t768 = bitcast i8* %t767 to { i32*, i64, i64 }*
  %t769 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t768, i32 0, i32 0
  store i32* null, i32** %t769
  %t770 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t768, i32 0, i32 1
  store i64 0, i64* %t770
  %t771 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t768, i32 0, i32 2
  store i64 0, i64* %t771
  store i8* %t767, i8** %t683
  br label %set_cow_done_160
set_cow_check_159:
  %t772 = getelementptr inbounds i8, i8* %t764, i64 -16
  %t773 = bitcast i8* %t772 to i64*
  %t774 = load atomic i64, i64* %t773 seq_cst, align 8
  %t775 = icmp eq i64 %t774, 1
  br i1 %t775, label %set_cow_done_160, label %set_cow_clone_161
set_cow_clone_161:
  %t776 = bitcast i8* %t764 to { i32*, i64, i64 }*
  %t777 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t776, i32 0, i32 0
  %t778 = load i32*, i32** %t777
  %t779 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t776, i32 0, i32 1
  %t780 = load i64, i64* %t779
  %t781 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t776, i32 0, i32 2
  %t782 = load i64, i64* %t781
  %t783 = bitcast void (i8*)* @set_release_i32 to i8*
  %t784 = call i8* @star_rc_alloc(i64 24, i8* %t783)
  %t785 = bitcast i8* %t784 to { i32*, i64, i64 }*
  %t786 = mul i64 %t782, %t763
  %t787 = call i8* @malloc(i64 %t786)
  %t788 = bitcast i8* %t787 to i32*
  %t789 = icmp sgt i64 %t780, 0
  br i1 %t789, label %set_cow_copy_162, label %set_cow_after_copy_163
set_cow_copy_162:
  %t790 = mul i64 %t780, %t763
  %t791 = bitcast i32* %t778 to i8*
  call i8* @memcpy(i8* %t787, i8* %t791, i64 %t790)
  br label %set_cow_after_copy_163
set_cow_after_copy_163:
  %t792 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t785, i32 0, i32 0
  store i32* %t788, i32** %t792
  %t793 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t785, i32 0, i32 1
  store i64 %t780, i64* %t793
  %t794 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t785, i32 0, i32 2
  store i64 %t782, i64* %t794
  call void @star_rc_release(i8* %t764)
  store i8* %t784, i8** %t683
  br label %set_cow_done_160
set_cow_done_160:
  %t795 = load i8*, i8** %t683
  %t796 = bitcast i8* %t795 to { i32*, i64, i64 }*
  %t797 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t796, i32 0, i32 0
  %t798 = load i32*, i32** %t797
  %t799 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t796, i32 0, i32 1
  %t800 = load i64, i64* %t799
  %t801 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t796, i32 0, i32 2
  %t802 = load i32*, i32** %t797
  %t803 = alloca i64
  store i64 0, i64* %t803
  %t804 = alloca i1
  store i1 false, i1* %t804
  br label %find_cond_164
find_cond_164:
  %t805 = load i64, i64* %t803
  %t806 = icmp slt i64 %t805, %t800
  br i1 %t806, label %find_body_165, label %find_end_168
find_body_165:
  %t807 = getelementptr inbounds i32, i32* %t802, i64 %t805
  %t808 = load i32, i32* %t807
  br label %find_eq_check_166
find_eq_check_166:
  %t809 = call i1 @eq_i32(i32 %t808, i32 2)
  br i1 %t809, label %find_end_168, label %find_next_167
find_next_167:
  %t810 = add i64 %t805, 1
  store i64 %t810, i64* %t803
  br label %find_cond_164
find_end_168:
  %t811 = load i64, i64* %t803
  %t812 = icmp slt i64 %t811, %t800
  br i1 %t812, label %set_insert_end_170, label %set_insert_do_169
set_insert_do_169:
  %t813 = load i64, i64* %t801
  %t814 = load i32*, i32** %t797
  %t815 = icmp sge i64 %t800, %t813
  br i1 %t815, label %set_insert_grow_171, label %set_insert_store_172
set_insert_grow_171:
  %t816 = mul i64 %t813, 2
  %t817 = icmp sgt i64 %t816, 0
  %t818 = select i1 %t817, i64 %t816, i64 1
  %t819 = getelementptr i32, i32* null, i32 1
  %t820 = ptrtoint i32* %t819 to i64
  %t821 = mul i64 %t818, %t820
  %t822 = call i8* @malloc(i64 %t821)
  %t823 = bitcast i8* %t822 to i32*
  %t824 = icmp sgt i64 %t813, 0
  br i1 %t824, label %set_insert_copy_173, label %set_insert_after_copy_174
set_insert_copy_173:
  %t825 = mul i64 %t800, %t820
  %t826 = bitcast i32* %t814 to i8*
  call i8* @memcpy(i8* %t822, i8* %t826, i64 %t825)
  call void @free(i8* %t826)
  br label %set_insert_after_copy_174
set_insert_after_copy_174:
  store i32* %t823, i32** %t797
  store i64 %t818, i64* %t801
  br label %set_insert_store_172
set_insert_store_172:
  %t827 = load i32*, i32** %t797
  %t828 = getelementptr inbounds i32, i32* %t827, i64 %t800
  store i32 2, i32* %t828
  %t829 = add i64 %t800, 1
  store i64 %t829, i64* %t799
  br label %set_insert_end_170
set_insert_end_170:
  %t830 = phi i1 [ false, %find_end_168 ], [ true, %set_insert_store_172 ]
  %t831 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.32, i64 0, i64 0
  %t832 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.33, i64 0, i64 0
  %t833 = select i1 %t830, i8* %t831, i8* %t832
  %t834 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.34, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t834, i8* %t833)
  %t835 = getelementptr i32, i32* null, i32 1
  %t836 = ptrtoint i32* %t835 to i64
  %t837 = load i8*, i8** %t683
  %t838 = icmp eq i8* %t837, null
  br i1 %t838, label %set_cow_alloc_175, label %set_cow_check_176
set_cow_alloc_175:
  %t839 = bitcast void (i8*)* @set_release_i32 to i8*
  %t840 = call i8* @star_rc_alloc(i64 24, i8* %t839)
  %t841 = bitcast i8* %t840 to { i32*, i64, i64 }*
  %t842 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t841, i32 0, i32 0
  store i32* null, i32** %t842
  %t843 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t841, i32 0, i32 1
  store i64 0, i64* %t843
  %t844 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t841, i32 0, i32 2
  store i64 0, i64* %t844
  store i8* %t840, i8** %t683
  br label %set_cow_done_177
set_cow_check_176:
  %t845 = getelementptr inbounds i8, i8* %t837, i64 -16
  %t846 = bitcast i8* %t845 to i64*
  %t847 = load atomic i64, i64* %t846 seq_cst, align 8
  %t848 = icmp eq i64 %t847, 1
  br i1 %t848, label %set_cow_done_177, label %set_cow_clone_178
set_cow_clone_178:
  %t849 = bitcast i8* %t837 to { i32*, i64, i64 }*
  %t850 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t849, i32 0, i32 0
  %t851 = load i32*, i32** %t850
  %t852 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t849, i32 0, i32 1
  %t853 = load i64, i64* %t852
  %t854 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t849, i32 0, i32 2
  %t855 = load i64, i64* %t854
  %t856 = bitcast void (i8*)* @set_release_i32 to i8*
  %t857 = call i8* @star_rc_alloc(i64 24, i8* %t856)
  %t858 = bitcast i8* %t857 to { i32*, i64, i64 }*
  %t859 = mul i64 %t855, %t836
  %t860 = call i8* @malloc(i64 %t859)
  %t861 = bitcast i8* %t860 to i32*
  %t862 = icmp sgt i64 %t853, 0
  br i1 %t862, label %set_cow_copy_179, label %set_cow_after_copy_180
set_cow_copy_179:
  %t863 = mul i64 %t853, %t836
  %t864 = bitcast i32* %t851 to i8*
  call i8* @memcpy(i8* %t860, i8* %t864, i64 %t863)
  br label %set_cow_after_copy_180
set_cow_after_copy_180:
  %t865 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t858, i32 0, i32 0
  store i32* %t861, i32** %t865
  %t866 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t858, i32 0, i32 1
  store i64 %t853, i64* %t866
  %t867 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t858, i32 0, i32 2
  store i64 %t855, i64* %t867
  call void @star_rc_release(i8* %t837)
  store i8* %t857, i8** %t683
  br label %set_cow_done_177
set_cow_done_177:
  %t868 = load i8*, i8** %t683
  %t869 = bitcast i8* %t868 to { i32*, i64, i64 }*
  %t870 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t869, i32 0, i32 0
  %t871 = load i32*, i32** %t870
  %t872 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t869, i32 0, i32 1
  %t873 = load i64, i64* %t872
  %t874 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t869, i32 0, i32 2
  %t875 = load i32*, i32** %t870
  %t876 = alloca i64
  store i64 0, i64* %t876
  %t877 = alloca i1
  store i1 false, i1* %t877
  br label %find_cond_181
find_cond_181:
  %t878 = load i64, i64* %t876
  %t879 = icmp slt i64 %t878, %t873
  br i1 %t879, label %find_body_182, label %find_end_185
find_body_182:
  %t880 = getelementptr inbounds i32, i32* %t875, i64 %t878
  %t881 = load i32, i32* %t880
  br label %find_eq_check_183
find_eq_check_183:
  %t882 = call i1 @eq_i32(i32 %t881, i32 1)
  br i1 %t882, label %find_end_185, label %find_next_184
find_next_184:
  %t883 = add i64 %t878, 1
  store i64 %t883, i64* %t876
  br label %find_cond_181
find_end_185:
  %t884 = load i64, i64* %t876
  %t885 = icmp slt i64 %t884, %t873
  br i1 %t885, label %set_insert_end_187, label %set_insert_do_186
set_insert_do_186:
  %t886 = load i64, i64* %t874
  %t887 = load i32*, i32** %t870
  %t888 = icmp sge i64 %t873, %t886
  br i1 %t888, label %set_insert_grow_188, label %set_insert_store_189
set_insert_grow_188:
  %t889 = mul i64 %t886, 2
  %t890 = icmp sgt i64 %t889, 0
  %t891 = select i1 %t890, i64 %t889, i64 1
  %t892 = getelementptr i32, i32* null, i32 1
  %t893 = ptrtoint i32* %t892 to i64
  %t894 = mul i64 %t891, %t893
  %t895 = call i8* @malloc(i64 %t894)
  %t896 = bitcast i8* %t895 to i32*
  %t897 = icmp sgt i64 %t886, 0
  br i1 %t897, label %set_insert_copy_190, label %set_insert_after_copy_191
set_insert_copy_190:
  %t898 = mul i64 %t873, %t893
  %t899 = bitcast i32* %t887 to i8*
  call i8* @memcpy(i8* %t895, i8* %t899, i64 %t898)
  call void @free(i8* %t899)
  br label %set_insert_after_copy_191
set_insert_after_copy_191:
  store i32* %t896, i32** %t870
  store i64 %t891, i64* %t874
  br label %set_insert_store_189
set_insert_store_189:
  %t900 = load i32*, i32** %t870
  %t901 = getelementptr inbounds i32, i32* %t900, i64 %t873
  store i32 1, i32* %t901
  %t902 = add i64 %t873, 1
  store i64 %t902, i64* %t872
  br label %set_insert_end_187
set_insert_end_187:
  %t903 = phi i1 [ false, %find_end_185 ], [ true, %set_insert_store_189 ]
  %t904 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.35, i64 0, i64 0
  %t905 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.36, i64 0, i64 0
  %t906 = select i1 %t903, i8* %t904, i8* %t905
  %t907 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.37, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t907, i8* %t906)
  %t908 = load i8*, i8** %t683
  %t909 = icmp eq i8* %t908, null
  br i1 %t909, label %set_read_null_192, label %set_read_real_193
set_read_null_192:
  br label %set_read_end_194
set_read_real_193:
  %t910 = bitcast i8* %t908 to { i32*, i64, i64 }*
  %t911 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t910, i32 0, i32 0
  %t912 = load i32*, i32** %t911
  %t913 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t910, i32 0, i32 1
  %t914 = load i64, i64* %t913
  br label %set_read_end_194
set_read_end_194:
  %t915 = phi i32* [ null, %set_read_null_192 ], [ %t912, %set_read_real_193 ]
  %t916 = phi i64 [ 0, %set_read_null_192 ], [ %t914, %set_read_real_193 ]
  %t917 = trunc i64 %t916 to i32
  %t918 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.38, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t918, i32 %t917)
  %t919 = load i8*, i8** %t683
  %t920 = icmp eq i8* %t919, null
  br i1 %t920, label %set_read_null_195, label %set_read_real_196
set_read_null_195:
  br label %set_read_end_197
set_read_real_196:
  %t921 = bitcast i8* %t919 to { i32*, i64, i64 }*
  %t922 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t921, i32 0, i32 0
  %t923 = load i32*, i32** %t922
  %t924 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t921, i32 0, i32 1
  %t925 = load i64, i64* %t924
  br label %set_read_end_197
set_read_end_197:
  %t926 = phi i32* [ null, %set_read_null_195 ], [ %t923, %set_read_real_196 ]
  %t927 = phi i64 [ 0, %set_read_null_195 ], [ %t925, %set_read_real_196 ]
  %t928 = alloca i64
  store i64 0, i64* %t928
  %t929 = alloca i1
  store i1 false, i1* %t929
  br label %find_cond_198
find_cond_198:
  %t930 = load i64, i64* %t928
  %t931 = icmp slt i64 %t930, %t927
  br i1 %t931, label %find_body_199, label %find_end_202
find_body_199:
  %t932 = getelementptr inbounds i32, i32* %t926, i64 %t930
  %t933 = load i32, i32* %t932
  br label %find_eq_check_200
find_eq_check_200:
  %t934 = call i1 @eq_i32(i32 %t933, i32 2)
  br i1 %t934, label %find_end_202, label %find_next_201
find_next_201:
  %t935 = add i64 %t930, 1
  store i64 %t935, i64* %t928
  br label %find_cond_198
find_end_202:
  %t936 = load i64, i64* %t928
  %t937 = icmp slt i64 %t936, %t927
  %t938 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.39, i64 0, i64 0
  %t939 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.40, i64 0, i64 0
  %t940 = select i1 %t937, i8* %t938, i8* %t939
  %t941 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.41, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t941, i8* %t940)
  %t942 = getelementptr i32, i32* null, i32 1
  %t943 = ptrtoint i32* %t942 to i64
  %t944 = load i8*, i8** %t683
  %t945 = icmp eq i8* %t944, null
  br i1 %t945, label %set_cow_alloc_203, label %set_cow_check_204
set_cow_alloc_203:
  %t946 = bitcast void (i8*)* @set_release_i32 to i8*
  %t947 = call i8* @star_rc_alloc(i64 24, i8* %t946)
  %t948 = bitcast i8* %t947 to { i32*, i64, i64 }*
  %t949 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t948, i32 0, i32 0
  store i32* null, i32** %t949
  %t950 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t948, i32 0, i32 1
  store i64 0, i64* %t950
  %t951 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t948, i32 0, i32 2
  store i64 0, i64* %t951
  store i8* %t947, i8** %t683
  br label %set_cow_done_205
set_cow_check_204:
  %t952 = getelementptr inbounds i8, i8* %t944, i64 -16
  %t953 = bitcast i8* %t952 to i64*
  %t954 = load atomic i64, i64* %t953 seq_cst, align 8
  %t955 = icmp eq i64 %t954, 1
  br i1 %t955, label %set_cow_done_205, label %set_cow_clone_206
set_cow_clone_206:
  %t956 = bitcast i8* %t944 to { i32*, i64, i64 }*
  %t957 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t956, i32 0, i32 0
  %t958 = load i32*, i32** %t957
  %t959 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t956, i32 0, i32 1
  %t960 = load i64, i64* %t959
  %t961 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t956, i32 0, i32 2
  %t962 = load i64, i64* %t961
  %t963 = bitcast void (i8*)* @set_release_i32 to i8*
  %t964 = call i8* @star_rc_alloc(i64 24, i8* %t963)
  %t965 = bitcast i8* %t964 to { i32*, i64, i64 }*
  %t966 = mul i64 %t962, %t943
  %t967 = call i8* @malloc(i64 %t966)
  %t968 = bitcast i8* %t967 to i32*
  %t969 = icmp sgt i64 %t960, 0
  br i1 %t969, label %set_cow_copy_207, label %set_cow_after_copy_208
set_cow_copy_207:
  %t970 = mul i64 %t960, %t943
  %t971 = bitcast i32* %t958 to i8*
  call i8* @memcpy(i8* %t967, i8* %t971, i64 %t970)
  br label %set_cow_after_copy_208
set_cow_after_copy_208:
  %t972 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t965, i32 0, i32 0
  store i32* %t968, i32** %t972
  %t973 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t965, i32 0, i32 1
  store i64 %t960, i64* %t973
  %t974 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t965, i32 0, i32 2
  store i64 %t962, i64* %t974
  call void @star_rc_release(i8* %t944)
  store i8* %t964, i8** %t683
  br label %set_cow_done_205
set_cow_done_205:
  %t975 = load i8*, i8** %t683
  %t976 = bitcast i8* %t975 to { i32*, i64, i64 }*
  %t977 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t976, i32 0, i32 0
  %t978 = load i32*, i32** %t977
  %t979 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t976, i32 0, i32 1
  %t980 = load i64, i64* %t979
  %t981 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t976, i32 0, i32 2
  %t982 = load i32*, i32** %t977
  %t983 = alloca i64
  store i64 0, i64* %t983
  %t984 = alloca i1
  store i1 false, i1* %t984
  br label %find_cond_209
find_cond_209:
  %t985 = load i64, i64* %t983
  %t986 = icmp slt i64 %t985, %t980
  br i1 %t986, label %find_body_210, label %find_end_213
find_body_210:
  %t987 = getelementptr inbounds i32, i32* %t982, i64 %t985
  %t988 = load i32, i32* %t987
  br label %find_eq_check_211
find_eq_check_211:
  %t989 = call i1 @eq_i32(i32 %t988, i32 2)
  br i1 %t989, label %find_end_213, label %find_next_212
find_next_212:
  %t990 = add i64 %t985, 1
  store i64 %t990, i64* %t983
  br label %find_cond_209
find_end_213:
  %t991 = load i64, i64* %t983
  %t992 = icmp slt i64 %t991, %t980
  br i1 %t992, label %set_remove_do_214, label %set_remove_end_215
set_remove_do_214:
  %t993 = getelementptr inbounds i32, i32* %t982, i64 %t991
  %t994 = sub i64 %t980, 1
  %t995 = getelementptr inbounds i32, i32* %t982, i64 %t994
  %t996 = load i32, i32* %t995
  store i32 %t996, i32* %t993
  store i64 %t994, i64* %t979
  br label %set_remove_end_215
set_remove_end_215:
  %t997 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.42, i64 0, i64 0
  %t998 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.43, i64 0, i64 0
  %t999 = select i1 %t992, i8* %t997, i8* %t998
  %t1000 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.44, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1000, i8* %t999)
  %t1001 = load i8*, i8** %t683
  %t1002 = icmp eq i8* %t1001, null
  br i1 %t1002, label %set_read_null_216, label %set_read_real_217
set_read_null_216:
  br label %set_read_end_218
set_read_real_217:
  %t1003 = bitcast i8* %t1001 to { i32*, i64, i64 }*
  %t1004 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1003, i32 0, i32 0
  %t1005 = load i32*, i32** %t1004
  %t1006 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1003, i32 0, i32 1
  %t1007 = load i64, i64* %t1006
  br label %set_read_end_218
set_read_end_218:
  %t1008 = phi i32* [ null, %set_read_null_216 ], [ %t1005, %set_read_real_217 ]
  %t1009 = phi i64 [ 0, %set_read_null_216 ], [ %t1007, %set_read_real_217 ]
  %t1010 = alloca i64
  store i64 0, i64* %t1010
  %t1011 = alloca i1
  store i1 false, i1* %t1011
  br label %find_cond_219
find_cond_219:
  %t1012 = load i64, i64* %t1010
  %t1013 = icmp slt i64 %t1012, %t1009
  br i1 %t1013, label %find_body_220, label %find_end_223
find_body_220:
  %t1014 = getelementptr inbounds i32, i32* %t1008, i64 %t1012
  %t1015 = load i32, i32* %t1014
  br label %find_eq_check_221
find_eq_check_221:
  %t1016 = call i1 @eq_i32(i32 %t1015, i32 2)
  br i1 %t1016, label %find_end_223, label %find_next_222
find_next_222:
  %t1017 = add i64 %t1012, 1
  store i64 %t1017, i64* %t1010
  br label %find_cond_219
find_end_223:
  %t1018 = load i64, i64* %t1010
  %t1019 = icmp slt i64 %t1018, %t1009
  %t1020 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.45, i64 0, i64 0
  %t1021 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.46, i64 0, i64 0
  %t1022 = select i1 %t1019, i8* %t1020, i8* %t1021
  %t1023 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.47, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1023, i8* %t1022)
  %t1024 = getelementptr i32, i32* null, i32 1
  %t1025 = ptrtoint i32* %t1024 to i64
  %t1026 = load i8*, i8** %t683
  %t1027 = icmp eq i8* %t1026, null
  br i1 %t1027, label %set_cow_alloc_224, label %set_cow_check_225
set_cow_alloc_224:
  %t1028 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1029 = call i8* @star_rc_alloc(i64 24, i8* %t1028)
  %t1030 = bitcast i8* %t1029 to { i32*, i64, i64 }*
  %t1031 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1030, i32 0, i32 0
  store i32* null, i32** %t1031
  %t1032 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1030, i32 0, i32 1
  store i64 0, i64* %t1032
  %t1033 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1030, i32 0, i32 2
  store i64 0, i64* %t1033
  store i8* %t1029, i8** %t683
  br label %set_cow_done_226
set_cow_check_225:
  %t1034 = getelementptr inbounds i8, i8* %t1026, i64 -16
  %t1035 = bitcast i8* %t1034 to i64*
  %t1036 = load atomic i64, i64* %t1035 seq_cst, align 8
  %t1037 = icmp eq i64 %t1036, 1
  br i1 %t1037, label %set_cow_done_226, label %set_cow_clone_227
set_cow_clone_227:
  %t1038 = bitcast i8* %t1026 to { i32*, i64, i64 }*
  %t1039 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1038, i32 0, i32 0
  %t1040 = load i32*, i32** %t1039
  %t1041 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1038, i32 0, i32 1
  %t1042 = load i64, i64* %t1041
  %t1043 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1038, i32 0, i32 2
  %t1044 = load i64, i64* %t1043
  %t1045 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1046 = call i8* @star_rc_alloc(i64 24, i8* %t1045)
  %t1047 = bitcast i8* %t1046 to { i32*, i64, i64 }*
  %t1048 = mul i64 %t1044, %t1025
  %t1049 = call i8* @malloc(i64 %t1048)
  %t1050 = bitcast i8* %t1049 to i32*
  %t1051 = icmp sgt i64 %t1042, 0
  br i1 %t1051, label %set_cow_copy_228, label %set_cow_after_copy_229
set_cow_copy_228:
  %t1052 = mul i64 %t1042, %t1025
  %t1053 = bitcast i32* %t1040 to i8*
  call i8* @memcpy(i8* %t1049, i8* %t1053, i64 %t1052)
  br label %set_cow_after_copy_229
set_cow_after_copy_229:
  %t1054 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1047, i32 0, i32 0
  store i32* %t1050, i32** %t1054
  %t1055 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1047, i32 0, i32 1
  store i64 %t1042, i64* %t1055
  %t1056 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1047, i32 0, i32 2
  store i64 %t1044, i64* %t1056
  call void @star_rc_release(i8* %t1026)
  store i8* %t1046, i8** %t683
  br label %set_cow_done_226
set_cow_done_226:
  %t1057 = load i8*, i8** %t683
  %t1058 = bitcast i8* %t1057 to { i32*, i64, i64 }*
  %t1059 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1058, i32 0, i32 0
  %t1060 = load i32*, i32** %t1059
  %t1061 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1058, i32 0, i32 1
  %t1062 = load i64, i64* %t1061
  %t1063 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1058, i32 0, i32 2
  %t1064 = load i32*, i32** %t1059
  %t1065 = alloca i64
  store i64 0, i64* %t1065
  %t1066 = alloca i1
  store i1 false, i1* %t1066
  br label %find_cond_230
find_cond_230:
  %t1067 = load i64, i64* %t1065
  %t1068 = icmp slt i64 %t1067, %t1062
  br i1 %t1068, label %find_body_231, label %find_end_234
find_body_231:
  %t1069 = getelementptr inbounds i32, i32* %t1064, i64 %t1067
  %t1070 = load i32, i32* %t1069
  br label %find_eq_check_232
find_eq_check_232:
  %t1071 = call i1 @eq_i32(i32 %t1070, i32 2)
  br i1 %t1071, label %find_end_234, label %find_next_233
find_next_233:
  %t1072 = add i64 %t1067, 1
  store i64 %t1072, i64* %t1065
  br label %find_cond_230
find_end_234:
  %t1073 = load i64, i64* %t1065
  %t1074 = icmp slt i64 %t1073, %t1062
  br i1 %t1074, label %set_remove_do_235, label %set_remove_end_236
set_remove_do_235:
  %t1075 = getelementptr inbounds i32, i32* %t1064, i64 %t1073
  %t1076 = sub i64 %t1062, 1
  %t1077 = getelementptr inbounds i32, i32* %t1064, i64 %t1076
  %t1078 = load i32, i32* %t1077
  store i32 %t1078, i32* %t1075
  store i64 %t1076, i64* %t1061
  br label %set_remove_end_236
set_remove_end_236:
  %t1079 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.48, i64 0, i64 0
  %t1080 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.49, i64 0, i64 0
  %t1081 = select i1 %t1074, i8* %t1079, i8* %t1080
  %t1082 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.50, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1082, i8* %t1081)
  %t1083 = load i8*, i8** %t683
  %t1084 = icmp eq i8* %t1083, null
  br i1 %t1084, label %set_read_null_237, label %set_read_real_238
set_read_null_237:
  br label %set_read_end_239
set_read_real_238:
  %t1085 = bitcast i8* %t1083 to { i32*, i64, i64 }*
  %t1086 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1085, i32 0, i32 0
  %t1087 = load i32*, i32** %t1086
  %t1088 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1085, i32 0, i32 1
  %t1089 = load i64, i64* %t1088
  br label %set_read_end_239
set_read_end_239:
  %t1090 = phi i32* [ null, %set_read_null_237 ], [ %t1087, %set_read_real_238 ]
  %t1091 = phi i64 [ 0, %set_read_null_237 ], [ %t1089, %set_read_real_238 ]
  %t1092 = trunc i64 %t1091 to i32
  %t1093 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.51, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1093, i32 %t1092)
  %t1094 = alloca i8*
  store i8* null, i8** %t1094
  %t1095 = getelementptr %Point, %Point* null, i32 1
  %t1096 = ptrtoint %Point* %t1095 to i64
  %t1097 = load i8*, i8** %t1094
  %t1098 = icmp eq i8* %t1097, null
  br i1 %t1098, label %set_cow_alloc_240, label %set_cow_check_241
set_cow_alloc_240:
  %t1103 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1104 = call i8* @star_rc_alloc(i64 24, i8* %t1103)
  %t1105 = bitcast i8* %t1104 to { %Point*, i64, i64 }*
  %t1106 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1105, i32 0, i32 0
  store %Point* null, %Point** %t1106
  %t1107 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1105, i32 0, i32 1
  store i64 0, i64* %t1107
  %t1108 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1105, i32 0, i32 2
  store i64 0, i64* %t1108
  store i8* %t1104, i8** %t1094
  br label %set_cow_done_242
set_cow_check_241:
  %t1109 = getelementptr inbounds i8, i8* %t1097, i64 -16
  %t1110 = bitcast i8* %t1109 to i64*
  %t1111 = load atomic i64, i64* %t1110 seq_cst, align 8
  %t1112 = icmp eq i64 %t1111, 1
  br i1 %t1112, label %set_cow_done_242, label %set_cow_clone_243
set_cow_clone_243:
  %t1113 = bitcast i8* %t1097 to { %Point*, i64, i64 }*
  %t1114 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1113, i32 0, i32 0
  %t1115 = load %Point*, %Point** %t1114
  %t1116 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1113, i32 0, i32 1
  %t1117 = load i64, i64* %t1116
  %t1118 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1113, i32 0, i32 2
  %t1119 = load i64, i64* %t1118
  %t1120 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1121 = call i8* @star_rc_alloc(i64 24, i8* %t1120)
  %t1122 = bitcast i8* %t1121 to { %Point*, i64, i64 }*
  %t1123 = mul i64 %t1119, %t1096
  %t1124 = call i8* @malloc(i64 %t1123)
  %t1125 = bitcast i8* %t1124 to %Point*
  %t1126 = icmp sgt i64 %t1117, 0
  br i1 %t1126, label %set_cow_copy_244, label %set_cow_after_copy_245
set_cow_copy_244:
  %t1127 = mul i64 %t1117, %t1096
  %t1128 = bitcast %Point* %t1115 to i8*
  call i8* @memcpy(i8* %t1124, i8* %t1128, i64 %t1127)
  br label %set_cow_after_copy_245
set_cow_after_copy_245:
  %t1129 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1122, i32 0, i32 0
  store %Point* %t1125, %Point** %t1129
  %t1130 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1122, i32 0, i32 1
  store i64 %t1117, i64* %t1130
  %t1131 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1122, i32 0, i32 2
  store i64 %t1119, i64* %t1131
  call void @star_rc_release(i8* %t1097)
  store i8* %t1121, i8** %t1094
  br label %set_cow_done_242
set_cow_done_242:
  %t1132 = load i8*, i8** %t1094
  %t1133 = bitcast i8* %t1132 to { %Point*, i64, i64 }*
  %t1134 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1133, i32 0, i32 0
  %t1135 = load %Point*, %Point** %t1134
  %t1136 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1133, i32 0, i32 1
  %t1137 = load i64, i64* %t1136
  %t1138 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1133, i32 0, i32 2
  %t1139 = alloca %Point
  %t1140 = getelementptr inbounds %Point, %Point* %t1139, i32 0, i32 0
  store i32 1, i32* %t1140
  %t1141 = getelementptr inbounds %Point, %Point* %t1139, i32 0, i32 1
  store i32 2, i32* %t1141
  %t1142 = load %Point, %Point* %t1139
  %t1143 = load %Point*, %Point** %t1134
  %t1151 = alloca i64
  store i64 0, i64* %t1151
  %t1152 = alloca i1
  store i1 false, i1* %t1152
  br label %find_cond_246
find_cond_246:
  %t1153 = load i64, i64* %t1151
  %t1154 = icmp slt i64 %t1153, %t1137
  br i1 %t1154, label %find_body_247, label %find_end_250
find_body_247:
  %t1155 = getelementptr inbounds %Point, %Point* %t1143, i64 %t1153
  %t1156 = load %Point, %Point* %t1155
  br label %find_eq_check_248
find_eq_check_248:
  %t1157 = call i1 @eq_s_Point(%Point %t1156, %Point %t1142)
  br i1 %t1157, label %find_end_250, label %find_next_249
find_next_249:
  %t1158 = add i64 %t1153, 1
  store i64 %t1158, i64* %t1151
  br label %find_cond_246
find_end_250:
  %t1159 = load i64, i64* %t1151
  %t1160 = icmp slt i64 %t1159, %t1137
  br i1 %t1160, label %set_insert_end_252, label %set_insert_do_251
set_insert_do_251:
  %t1161 = load i64, i64* %t1138
  %t1162 = load %Point*, %Point** %t1134
  %t1163 = icmp sge i64 %t1137, %t1161
  br i1 %t1163, label %set_insert_grow_253, label %set_insert_store_254
set_insert_grow_253:
  %t1164 = mul i64 %t1161, 2
  %t1165 = icmp sgt i64 %t1164, 0
  %t1166 = select i1 %t1165, i64 %t1164, i64 1
  %t1167 = getelementptr %Point, %Point* null, i32 1
  %t1168 = ptrtoint %Point* %t1167 to i64
  %t1169 = mul i64 %t1166, %t1168
  %t1170 = call i8* @malloc(i64 %t1169)
  %t1171 = bitcast i8* %t1170 to %Point*
  %t1172 = icmp sgt i64 %t1161, 0
  br i1 %t1172, label %set_insert_copy_255, label %set_insert_after_copy_256
set_insert_copy_255:
  %t1173 = mul i64 %t1137, %t1168
  %t1174 = bitcast %Point* %t1162 to i8*
  call i8* @memcpy(i8* %t1170, i8* %t1174, i64 %t1173)
  call void @free(i8* %t1174)
  br label %set_insert_after_copy_256
set_insert_after_copy_256:
  store %Point* %t1171, %Point** %t1134
  store i64 %t1166, i64* %t1138
  br label %set_insert_store_254
set_insert_store_254:
  %t1175 = load %Point*, %Point** %t1134
  %t1176 = getelementptr inbounds %Point, %Point* %t1175, i64 %t1137
  store %Point %t1142, %Point* %t1176
  %t1177 = add i64 %t1137, 1
  store i64 %t1177, i64* %t1136
  br label %set_insert_end_252
set_insert_end_252:
  %t1178 = phi i1 [ false, %find_end_250 ], [ true, %set_insert_store_254 ]
  %t1179 = getelementptr %Point, %Point* null, i32 1
  %t1180 = ptrtoint %Point* %t1179 to i64
  %t1181 = load i8*, i8** %t1094
  %t1182 = icmp eq i8* %t1181, null
  br i1 %t1182, label %set_cow_alloc_257, label %set_cow_check_258
set_cow_alloc_257:
  %t1183 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1184 = call i8* @star_rc_alloc(i64 24, i8* %t1183)
  %t1185 = bitcast i8* %t1184 to { %Point*, i64, i64 }*
  %t1186 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1185, i32 0, i32 0
  store %Point* null, %Point** %t1186
  %t1187 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1185, i32 0, i32 1
  store i64 0, i64* %t1187
  %t1188 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1185, i32 0, i32 2
  store i64 0, i64* %t1188
  store i8* %t1184, i8** %t1094
  br label %set_cow_done_259
set_cow_check_258:
  %t1189 = getelementptr inbounds i8, i8* %t1181, i64 -16
  %t1190 = bitcast i8* %t1189 to i64*
  %t1191 = load atomic i64, i64* %t1190 seq_cst, align 8
  %t1192 = icmp eq i64 %t1191, 1
  br i1 %t1192, label %set_cow_done_259, label %set_cow_clone_260
set_cow_clone_260:
  %t1193 = bitcast i8* %t1181 to { %Point*, i64, i64 }*
  %t1194 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1193, i32 0, i32 0
  %t1195 = load %Point*, %Point** %t1194
  %t1196 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1193, i32 0, i32 1
  %t1197 = load i64, i64* %t1196
  %t1198 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1193, i32 0, i32 2
  %t1199 = load i64, i64* %t1198
  %t1200 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1201 = call i8* @star_rc_alloc(i64 24, i8* %t1200)
  %t1202 = bitcast i8* %t1201 to { %Point*, i64, i64 }*
  %t1203 = mul i64 %t1199, %t1180
  %t1204 = call i8* @malloc(i64 %t1203)
  %t1205 = bitcast i8* %t1204 to %Point*
  %t1206 = icmp sgt i64 %t1197, 0
  br i1 %t1206, label %set_cow_copy_261, label %set_cow_after_copy_262
set_cow_copy_261:
  %t1207 = mul i64 %t1197, %t1180
  %t1208 = bitcast %Point* %t1195 to i8*
  call i8* @memcpy(i8* %t1204, i8* %t1208, i64 %t1207)
  br label %set_cow_after_copy_262
set_cow_after_copy_262:
  %t1209 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1202, i32 0, i32 0
  store %Point* %t1205, %Point** %t1209
  %t1210 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1202, i32 0, i32 1
  store i64 %t1197, i64* %t1210
  %t1211 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1202, i32 0, i32 2
  store i64 %t1199, i64* %t1211
  call void @star_rc_release(i8* %t1181)
  store i8* %t1201, i8** %t1094
  br label %set_cow_done_259
set_cow_done_259:
  %t1212 = load i8*, i8** %t1094
  %t1213 = bitcast i8* %t1212 to { %Point*, i64, i64 }*
  %t1214 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1213, i32 0, i32 0
  %t1215 = load %Point*, %Point** %t1214
  %t1216 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1213, i32 0, i32 1
  %t1217 = load i64, i64* %t1216
  %t1218 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1213, i32 0, i32 2
  %t1219 = alloca %Point
  %t1220 = getelementptr inbounds %Point, %Point* %t1219, i32 0, i32 0
  store i32 1, i32* %t1220
  %t1221 = getelementptr inbounds %Point, %Point* %t1219, i32 0, i32 1
  store i32 2, i32* %t1221
  %t1222 = load %Point, %Point* %t1219
  %t1223 = load %Point*, %Point** %t1214
  %t1224 = alloca i64
  store i64 0, i64* %t1224
  %t1225 = alloca i1
  store i1 false, i1* %t1225
  br label %find_cond_263
find_cond_263:
  %t1226 = load i64, i64* %t1224
  %t1227 = icmp slt i64 %t1226, %t1217
  br i1 %t1227, label %find_body_264, label %find_end_267
find_body_264:
  %t1228 = getelementptr inbounds %Point, %Point* %t1223, i64 %t1226
  %t1229 = load %Point, %Point* %t1228
  br label %find_eq_check_265
find_eq_check_265:
  %t1230 = call i1 @eq_s_Point(%Point %t1229, %Point %t1222)
  br i1 %t1230, label %find_end_267, label %find_next_266
find_next_266:
  %t1231 = add i64 %t1226, 1
  store i64 %t1231, i64* %t1224
  br label %find_cond_263
find_end_267:
  %t1232 = load i64, i64* %t1224
  %t1233 = icmp slt i64 %t1232, %t1217
  br i1 %t1233, label %set_insert_end_269, label %set_insert_do_268
set_insert_do_268:
  %t1234 = load i64, i64* %t1218
  %t1235 = load %Point*, %Point** %t1214
  %t1236 = icmp sge i64 %t1217, %t1234
  br i1 %t1236, label %set_insert_grow_270, label %set_insert_store_271
set_insert_grow_270:
  %t1237 = mul i64 %t1234, 2
  %t1238 = icmp sgt i64 %t1237, 0
  %t1239 = select i1 %t1238, i64 %t1237, i64 1
  %t1240 = getelementptr %Point, %Point* null, i32 1
  %t1241 = ptrtoint %Point* %t1240 to i64
  %t1242 = mul i64 %t1239, %t1241
  %t1243 = call i8* @malloc(i64 %t1242)
  %t1244 = bitcast i8* %t1243 to %Point*
  %t1245 = icmp sgt i64 %t1234, 0
  br i1 %t1245, label %set_insert_copy_272, label %set_insert_after_copy_273
set_insert_copy_272:
  %t1246 = mul i64 %t1217, %t1241
  %t1247 = bitcast %Point* %t1235 to i8*
  call i8* @memcpy(i8* %t1243, i8* %t1247, i64 %t1246)
  call void @free(i8* %t1247)
  br label %set_insert_after_copy_273
set_insert_after_copy_273:
  store %Point* %t1244, %Point** %t1214
  store i64 %t1239, i64* %t1218
  br label %set_insert_store_271
set_insert_store_271:
  %t1248 = load %Point*, %Point** %t1214
  %t1249 = getelementptr inbounds %Point, %Point* %t1248, i64 %t1217
  store %Point %t1222, %Point* %t1249
  %t1250 = add i64 %t1217, 1
  store i64 %t1250, i64* %t1216
  br label %set_insert_end_269
set_insert_end_269:
  %t1251 = phi i1 [ false, %find_end_267 ], [ true, %set_insert_store_271 ]
  %t1252 = getelementptr %Point, %Point* null, i32 1
  %t1253 = ptrtoint %Point* %t1252 to i64
  %t1254 = load i8*, i8** %t1094
  %t1255 = icmp eq i8* %t1254, null
  br i1 %t1255, label %set_cow_alloc_274, label %set_cow_check_275
set_cow_alloc_274:
  %t1256 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1257 = call i8* @star_rc_alloc(i64 24, i8* %t1256)
  %t1258 = bitcast i8* %t1257 to { %Point*, i64, i64 }*
  %t1259 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1258, i32 0, i32 0
  store %Point* null, %Point** %t1259
  %t1260 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1258, i32 0, i32 1
  store i64 0, i64* %t1260
  %t1261 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1258, i32 0, i32 2
  store i64 0, i64* %t1261
  store i8* %t1257, i8** %t1094
  br label %set_cow_done_276
set_cow_check_275:
  %t1262 = getelementptr inbounds i8, i8* %t1254, i64 -16
  %t1263 = bitcast i8* %t1262 to i64*
  %t1264 = load atomic i64, i64* %t1263 seq_cst, align 8
  %t1265 = icmp eq i64 %t1264, 1
  br i1 %t1265, label %set_cow_done_276, label %set_cow_clone_277
set_cow_clone_277:
  %t1266 = bitcast i8* %t1254 to { %Point*, i64, i64 }*
  %t1267 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1266, i32 0, i32 0
  %t1268 = load %Point*, %Point** %t1267
  %t1269 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1266, i32 0, i32 1
  %t1270 = load i64, i64* %t1269
  %t1271 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1266, i32 0, i32 2
  %t1272 = load i64, i64* %t1271
  %t1273 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1274 = call i8* @star_rc_alloc(i64 24, i8* %t1273)
  %t1275 = bitcast i8* %t1274 to { %Point*, i64, i64 }*
  %t1276 = mul i64 %t1272, %t1253
  %t1277 = call i8* @malloc(i64 %t1276)
  %t1278 = bitcast i8* %t1277 to %Point*
  %t1279 = icmp sgt i64 %t1270, 0
  br i1 %t1279, label %set_cow_copy_278, label %set_cow_after_copy_279
set_cow_copy_278:
  %t1280 = mul i64 %t1270, %t1253
  %t1281 = bitcast %Point* %t1268 to i8*
  call i8* @memcpy(i8* %t1277, i8* %t1281, i64 %t1280)
  br label %set_cow_after_copy_279
set_cow_after_copy_279:
  %t1282 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1275, i32 0, i32 0
  store %Point* %t1278, %Point** %t1282
  %t1283 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1275, i32 0, i32 1
  store i64 %t1270, i64* %t1283
  %t1284 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1275, i32 0, i32 2
  store i64 %t1272, i64* %t1284
  call void @star_rc_release(i8* %t1254)
  store i8* %t1274, i8** %t1094
  br label %set_cow_done_276
set_cow_done_276:
  %t1285 = load i8*, i8** %t1094
  %t1286 = bitcast i8* %t1285 to { %Point*, i64, i64 }*
  %t1287 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1286, i32 0, i32 0
  %t1288 = load %Point*, %Point** %t1287
  %t1289 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1286, i32 0, i32 1
  %t1290 = load i64, i64* %t1289
  %t1291 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1286, i32 0, i32 2
  %t1292 = alloca %Point
  %t1293 = getelementptr inbounds %Point, %Point* %t1292, i32 0, i32 0
  store i32 3, i32* %t1293
  %t1294 = getelementptr inbounds %Point, %Point* %t1292, i32 0, i32 1
  store i32 4, i32* %t1294
  %t1295 = load %Point, %Point* %t1292
  %t1296 = load %Point*, %Point** %t1287
  %t1297 = alloca i64
  store i64 0, i64* %t1297
  %t1298 = alloca i1
  store i1 false, i1* %t1298
  br label %find_cond_280
find_cond_280:
  %t1299 = load i64, i64* %t1297
  %t1300 = icmp slt i64 %t1299, %t1290
  br i1 %t1300, label %find_body_281, label %find_end_284
find_body_281:
  %t1301 = getelementptr inbounds %Point, %Point* %t1296, i64 %t1299
  %t1302 = load %Point, %Point* %t1301
  br label %find_eq_check_282
find_eq_check_282:
  %t1303 = call i1 @eq_s_Point(%Point %t1302, %Point %t1295)
  br i1 %t1303, label %find_end_284, label %find_next_283
find_next_283:
  %t1304 = add i64 %t1299, 1
  store i64 %t1304, i64* %t1297
  br label %find_cond_280
find_end_284:
  %t1305 = load i64, i64* %t1297
  %t1306 = icmp slt i64 %t1305, %t1290
  br i1 %t1306, label %set_insert_end_286, label %set_insert_do_285
set_insert_do_285:
  %t1307 = load i64, i64* %t1291
  %t1308 = load %Point*, %Point** %t1287
  %t1309 = icmp sge i64 %t1290, %t1307
  br i1 %t1309, label %set_insert_grow_287, label %set_insert_store_288
set_insert_grow_287:
  %t1310 = mul i64 %t1307, 2
  %t1311 = icmp sgt i64 %t1310, 0
  %t1312 = select i1 %t1311, i64 %t1310, i64 1
  %t1313 = getelementptr %Point, %Point* null, i32 1
  %t1314 = ptrtoint %Point* %t1313 to i64
  %t1315 = mul i64 %t1312, %t1314
  %t1316 = call i8* @malloc(i64 %t1315)
  %t1317 = bitcast i8* %t1316 to %Point*
  %t1318 = icmp sgt i64 %t1307, 0
  br i1 %t1318, label %set_insert_copy_289, label %set_insert_after_copy_290
set_insert_copy_289:
  %t1319 = mul i64 %t1290, %t1314
  %t1320 = bitcast %Point* %t1308 to i8*
  call i8* @memcpy(i8* %t1316, i8* %t1320, i64 %t1319)
  call void @free(i8* %t1320)
  br label %set_insert_after_copy_290
set_insert_after_copy_290:
  store %Point* %t1317, %Point** %t1287
  store i64 %t1312, i64* %t1291
  br label %set_insert_store_288
set_insert_store_288:
  %t1321 = load %Point*, %Point** %t1287
  %t1322 = getelementptr inbounds %Point, %Point* %t1321, i64 %t1290
  store %Point %t1295, %Point* %t1322
  %t1323 = add i64 %t1290, 1
  store i64 %t1323, i64* %t1289
  br label %set_insert_end_286
set_insert_end_286:
  %t1324 = phi i1 [ false, %find_end_284 ], [ true, %set_insert_store_288 ]
  %t1325 = load i8*, i8** %t1094
  %t1326 = icmp eq i8* %t1325, null
  br i1 %t1326, label %set_read_null_291, label %set_read_real_292
set_read_null_291:
  br label %set_read_end_293
set_read_real_292:
  %t1327 = bitcast i8* %t1325 to { %Point*, i64, i64 }*
  %t1328 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1327, i32 0, i32 0
  %t1329 = load %Point*, %Point** %t1328
  %t1330 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1327, i32 0, i32 1
  %t1331 = load i64, i64* %t1330
  br label %set_read_end_293
set_read_end_293:
  %t1332 = phi %Point* [ null, %set_read_null_291 ], [ %t1329, %set_read_real_292 ]
  %t1333 = phi i64 [ 0, %set_read_null_291 ], [ %t1331, %set_read_real_292 ]
  %t1334 = trunc i64 %t1333 to i32
  %t1335 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.52, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1335, i32 %t1334)
  %t1336 = load i8*, i8** %t1094
  %t1337 = icmp eq i8* %t1336, null
  br i1 %t1337, label %set_read_null_294, label %set_read_real_295
set_read_null_294:
  br label %set_read_end_296
set_read_real_295:
  %t1338 = bitcast i8* %t1336 to { %Point*, i64, i64 }*
  %t1339 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1338, i32 0, i32 0
  %t1340 = load %Point*, %Point** %t1339
  %t1341 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1338, i32 0, i32 1
  %t1342 = load i64, i64* %t1341
  br label %set_read_end_296
set_read_end_296:
  %t1343 = phi %Point* [ null, %set_read_null_294 ], [ %t1340, %set_read_real_295 ]
  %t1344 = phi i64 [ 0, %set_read_null_294 ], [ %t1342, %set_read_real_295 ]
  %t1345 = alloca %Point
  %t1346 = getelementptr inbounds %Point, %Point* %t1345, i32 0, i32 0
  store i32 1, i32* %t1346
  %t1347 = getelementptr inbounds %Point, %Point* %t1345, i32 0, i32 1
  store i32 2, i32* %t1347
  %t1348 = load %Point, %Point* %t1345
  %t1349 = alloca i64
  store i64 0, i64* %t1349
  %t1350 = alloca i1
  store i1 false, i1* %t1350
  br label %find_cond_297
find_cond_297:
  %t1351 = load i64, i64* %t1349
  %t1352 = icmp slt i64 %t1351, %t1344
  br i1 %t1352, label %find_body_298, label %find_end_301
find_body_298:
  %t1353 = getelementptr inbounds %Point, %Point* %t1343, i64 %t1351
  %t1354 = load %Point, %Point* %t1353
  br label %find_eq_check_299
find_eq_check_299:
  %t1355 = call i1 @eq_s_Point(%Point %t1354, %Point %t1348)
  br i1 %t1355, label %find_end_301, label %find_next_300
find_next_300:
  %t1356 = add i64 %t1351, 1
  store i64 %t1356, i64* %t1349
  br label %find_cond_297
find_end_301:
  %t1357 = load i64, i64* %t1349
  %t1358 = icmp slt i64 %t1357, %t1344
  %t1359 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.53, i64 0, i64 0
  %t1360 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.54, i64 0, i64 0
  %t1361 = select i1 %t1358, i8* %t1359, i8* %t1360
  %t1362 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.55, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1362, i8* %t1361)
  %t1363 = load i8*, i8** %t1094
  %t1364 = icmp eq i8* %t1363, null
  br i1 %t1364, label %set_read_null_302, label %set_read_real_303
set_read_null_302:
  br label %set_read_end_304
set_read_real_303:
  %t1365 = bitcast i8* %t1363 to { %Point*, i64, i64 }*
  %t1366 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1365, i32 0, i32 0
  %t1367 = load %Point*, %Point** %t1366
  %t1368 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1365, i32 0, i32 1
  %t1369 = load i64, i64* %t1368
  br label %set_read_end_304
set_read_end_304:
  %t1370 = phi %Point* [ null, %set_read_null_302 ], [ %t1367, %set_read_real_303 ]
  %t1371 = phi i64 [ 0, %set_read_null_302 ], [ %t1369, %set_read_real_303 ]
  %t1372 = alloca %Point
  %t1373 = getelementptr inbounds %Point, %Point* %t1372, i32 0, i32 0
  store i32 9, i32* %t1373
  %t1374 = getelementptr inbounds %Point, %Point* %t1372, i32 0, i32 1
  store i32 9, i32* %t1374
  %t1375 = load %Point, %Point* %t1372
  %t1376 = alloca i64
  store i64 0, i64* %t1376
  %t1377 = alloca i1
  store i1 false, i1* %t1377
  br label %find_cond_305
find_cond_305:
  %t1378 = load i64, i64* %t1376
  %t1379 = icmp slt i64 %t1378, %t1371
  br i1 %t1379, label %find_body_306, label %find_end_309
find_body_306:
  %t1380 = getelementptr inbounds %Point, %Point* %t1370, i64 %t1378
  %t1381 = load %Point, %Point* %t1380
  br label %find_eq_check_307
find_eq_check_307:
  %t1382 = call i1 @eq_s_Point(%Point %t1381, %Point %t1375)
  br i1 %t1382, label %find_end_309, label %find_next_308
find_next_308:
  %t1383 = add i64 %t1378, 1
  store i64 %t1383, i64* %t1376
  br label %find_cond_305
find_end_309:
  %t1384 = load i64, i64* %t1376
  %t1385 = icmp slt i64 %t1384, %t1371
  %t1386 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.56, i64 0, i64 0
  %t1387 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.57, i64 0, i64 0
  %t1388 = select i1 %t1385, i8* %t1386, i8* %t1387
  %t1389 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.58, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1389, i8* %t1388)
  %t1390 = load i8*, i8** %t1094
  call void @star_rc_release(i8* %t1390)
  %t1391 = load i8*, i8** %t683
  call void @star_rc_release(i8* %t1391)
  %t1392 = load i8*, i8** %t505
  call void @star_rc_release(i8* %t1392)
  %t1393 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t1393)
  ret i32 0
}


; par/swarm worker functions
define void @map_release_str_i32(i8* %objp) {
entry:
  %t7 = bitcast i8* %objp to { i8**, i32*, i64, i64 }*
  %t8 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t7, i32 0, i32 0
  %t9 = load i8**, i8*** %t8
  %t10 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t7, i32 0, i32 1
  %t11 = load i32*, i32** %t10
  %t12 = getelementptr inbounds { i8**, i32*, i64, i64 }, { i8**, i32*, i64, i64 }* %t7, i32 0, i32 2
  %t13 = load i64, i64* %t12
  %t14 = alloca i64
  store i64 0, i64* %t14
  br label %map_release_cond_3
map_release_cond_3:
  %t15 = load i64, i64* %t14
  %t16 = icmp slt i64 %t15, %t13
  br i1 %t16, label %map_release_body_4, label %map_release_end_5
map_release_body_4:
  %t17 = getelementptr inbounds i8*, i8** %t9, i64 %t15
  %t18 = load i8*, i8** %t17
  call void @star_rc_release(i8* %t18)
  %t19 = add i64 %t15, 1
  store i64 %t19, i64* %t14
  br label %map_release_cond_3
map_release_end_5:
  %t20 = bitcast i8** %t9 to i8*
  call void @free(i8* %t20)
  %t21 = bitcast i32* %t11 to i8*
  call void @free(i8* %t21)
  ret void
}


define i1 @eq_str(i8* %a, i8* %b) {
entry:
  %t77 = call i32 @strcmp(i8* %a, i8* %b)
  %t78 = icmp eq i32 %t77, 0
  ret i1 %t78
}


define void @set_release_i32(i8* %objp) {
entry:
  %t688 = bitcast i8* %objp to { i32*, i64, i64 }*
  %t689 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t688, i32 0, i32 0
  %t690 = load i32*, i32** %t689
  %t691 = bitcast i32* %t690 to i8*
  call void @free(i8* %t691)
  ret void
}


define i1 @eq_i32(i32 %a, i32 %b) {
entry:
  %t729 = icmp eq i32 %a, %b
  ret i1 %t729
}


define void @set_release_s_Point(i8* %objp) {
entry:
  %t1099 = bitcast i8* %objp to { %Point*, i64, i64 }*
  %t1100 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t1099, i32 0, i32 0
  %t1101 = load %Point*, %Point** %t1100
  %t1102 = bitcast %Point* %t1101 to i8*
  call void @free(i8* %t1102)
  ret void
}


define i1 @eq_s_Point(%Point %a, %Point %b) {
entry:
  %t1144 = extractvalue %Point %a, 0
  %t1145 = extractvalue %Point %b, 0
  %t1146 = icmp eq i32 %t1144, %t1145
  %t1147 = extractvalue %Point %a, 1
  %t1148 = extractvalue %Point %b, 1
  %t1149 = icmp eq i32 %t1147, %t1148
  %t1150 = and i1 %t1146, %t1149
  ret i1 %t1150
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"alice\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"bob\00" }
@.str.2 = private unnamed_addr constant [25 x i8] c"len after 2 inserts: %d\0A\00"
@.str.3 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"alice\00" }
@.str.4 = private unnamed_addr constant [11 x i8] c"alice: %d\0A\00"
@.str.5 = private unnamed_addr constant { i64, i8*, [15 x i8] } { i64 -1, i8* null, [15 x i8] c"alice: missing\00" }
@.str.6 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.7 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"carol\00" }
@.str.8 = private unnamed_addr constant [11 x i8] c"carol: %d\0A\00"
@.str.9 = private unnamed_addr constant { i64, i8*, [15 x i8] } { i64 -1, i8* null, [15 x i8] c"carol: missing\00" }
@.str.10 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.11 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"alice\00" }
@.str.12 = private unnamed_addr constant [25 x i8] c"len after overwrite: %d\0A\00"
@.str.13 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"alice\00" }
@.str.14 = private unnamed_addr constant [27 x i8] c"alice after overwrite: %d\0A\00"
@.str.15 = private unnamed_addr constant { i64, i8*, [15 x i8] } { i64 -1, i8* null, [15 x i8] c"alice: missing\00" }
@.str.16 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.17 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"bob\00" }
@.str.18 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.19 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.20 = private unnamed_addr constant [18 x i8] c"contains bob: %s\0A\00"
@.str.21 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"bob\00" }
@.str.22 = private unnamed_addr constant [17 x i8] c"removed bob: %d\0A\00"
@.str.23 = private unnamed_addr constant { i64, i8*, [13 x i8] } { i64 -1, i8* null, [13 x i8] c"bob: missing\00" }
@.str.24 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.25 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.26 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.27 = private unnamed_addr constant [31 x i8] c"contains bob after remove: %s\0A\00"
@.str.28 = private unnamed_addr constant [22 x i8] c"len after remove: %d\0A\00"
@.str.29 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.30 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.31 = private unnamed_addr constant [20 x i8] c"insert 1 (new): %s\0A\00"
@.str.32 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.33 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.34 = private unnamed_addr constant [20 x i8] c"insert 2 (new): %s\0A\00"
@.str.35 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.36 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.37 = private unnamed_addr constant [20 x i8] c"insert 1 (dup): %s\0A\00"
@.str.38 = private unnamed_addr constant [13 x i8] c"set len: %d\0A\00"
@.str.39 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.40 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.41 = private unnamed_addr constant [16 x i8] c"contains 2: %s\0A\00"
@.str.42 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.43 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.44 = private unnamed_addr constant [14 x i8] c"remove 2: %s\0A\00"
@.str.45 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.46 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.47 = private unnamed_addr constant [29 x i8] c"contains 2 after remove: %s\0A\00"
@.str.48 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.49 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.50 = private unnamed_addr constant [20 x i8] c"remove 2 again: %s\0A\00"
@.str.51 = private unnamed_addr constant [27 x i8] c"set len after removes: %d\0A\00"
@.str.52 = private unnamed_addr constant [20 x i8] c"struct set len: %d\0A\00"
@.str.53 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.54 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.55 = private unnamed_addr constant [20 x i8] c"contains (1,2): %s\0A\00"
@.str.56 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.57 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.58 = private unnamed_addr constant [20 x i8] c"contains (9,9): %s\0A\00"
