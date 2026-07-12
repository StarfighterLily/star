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

%Greeting = type { i8* }
define i32 @shout_len(i8* %s) {
entry:
  %t0 = alloca i8*
  store i8* %s, i8** %t0
  %t1 = alloca i8*
  %t2 = load i8*, i8** %t0
  %t3 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t3)
  call void @star_rc_release(i8* %t2)
  %t4 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t5 = call i32 @strlen(i8* %t2)
  %t6 = call i32 @strlen(i8* %t4)
  %t7 = add i32 %t5, %t6
  %t8 = add i32 %t7, 1
  %t9 = sext i32 %t8 to i64
  %t10 = call i8* @star_rc_alloc(i64 %t9, i8* null)
  call i8* @strcpy(i8* %t10, i8* %t2)
  call i8* @strcat(i8* %t10, i8* %t4)
  store i8* %t10, i8** %t1
  %t11 = load i8*, i8** %t1
  %t12 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t12)
  call void @star_rc_release(i8* %t11)
  %t13 = call i32 @strlen(i8* %t11)
  %t14 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t14)
  %t15 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t15)
  ret i32 %t13
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = alloca i8*
  %t1 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t2 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t3 = call i32 @strlen(i8* %t1)
  %t4 = call i32 @strlen(i8* %t2)
  %t5 = add i32 %t3, %t4
  %t6 = add i32 %t5, 1
  %t7 = sext i32 %t6 to i64
  %t8 = call i8* @star_rc_alloc(i64 %t7, i8* null)
  call i8* @strcpy(i8* %t8, i8* %t1)
  call i8* @strcat(i8* %t8, i8* %t2)
  store i8* %t8, i8** %t0
  %t9 = load i8*, i8** %t0
  %t10 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t10)
  call void @star_rc_release(i8* %t9)
  call i32 (i8*, ...) @printf(i8* %t9)
  %t11 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t11)
  %t12 = load i8*, i8** %t0
  %t13 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t13)
  call void @star_rc_release(i8* %t12)
  %t14 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t15 = call i32 @strlen(i8* %t12)
  %t16 = call i32 @strlen(i8* %t14)
  %t17 = add i32 %t15, %t16
  %t18 = add i32 %t17, 1
  %t19 = sext i32 %t18 to i64
  %t20 = call i8* @star_rc_alloc(i64 %t19, i8* null)
  call i8* @strcpy(i8* %t20, i8* %t12)
  call i8* @strcat(i8* %t20, i8* %t14)
  %t21 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t21)
  store i8* %t20, i8** %t0
  %t22 = load i8*, i8** %t0
  %t23 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t23)
  call void @star_rc_release(i8* %t22)
  call i32 (i8*, ...) @printf(i8* %t22)
  %t24 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t24)
  %t25 = alloca %Greeting
  %t26 = alloca %Greeting
  %t27 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t28 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t29 = call i32 @strlen(i8* %t27)
  %t30 = call i32 @strlen(i8* %t28)
  %t31 = add i32 %t29, %t30
  %t32 = add i32 %t31, 1
  %t33 = sext i32 %t32 to i64
  %t34 = call i8* @star_rc_alloc(i64 %t33, i8* null)
  call i8* @strcpy(i8* %t34, i8* %t27)
  call i8* @strcat(i8* %t34, i8* %t28)
  %t35 = getelementptr inbounds %Greeting, %Greeting* %t26, i32 0, i32 0
  store i8* %t34, i8** %t35
  %t36 = load %Greeting, %Greeting* %t26
  store %Greeting %t36, %Greeting* %t25
  %t37 = getelementptr inbounds %Greeting, %Greeting* %t25, i32 0, i32 0
  %t38 = load i8*, i8** %t37
  %t39 = load i8*, i8** %t37
  call void @star_rc_retain(i8* %t39)
  call void @star_rc_release(i8* %t38)
  call i32 (i8*, ...) @printf(i8* %t38)
  %t40 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t40)
  %t41 = alloca %Greeting
  %t42 = load %Greeting, %Greeting* %t25
  %t43 = getelementptr inbounds %Greeting, %Greeting* %t25, i32 0, i32 0
  %t44 = load i8*, i8** %t43
  call void @star_rc_retain(i8* %t44)
  store %Greeting %t42, %Greeting* %t41
  %t45 = getelementptr inbounds %Greeting, %Greeting* %t41, i32 0, i32 0
  %t46 = load i8*, i8** %t45
  %t47 = load i8*, i8** %t45
  call void @star_rc_retain(i8* %t47)
  call void @star_rc_release(i8* %t46)
  call i32 (i8*, ...) @printf(i8* %t46)
  %t48 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t48)
  %t49 = alloca i8*
  %t50 = getelementptr i8*, i8** null, i32 1
  %t51 = ptrtoint i8** %t50 to i64
  %t52 = mul i64 %t51, 2
  %t53 = call i8* @malloc(i64 %t52)
  %t54 = bitcast i8* %t53 to i8**
  %t55 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t56 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t57 = call i32 @strlen(i8* %t55)
  %t58 = call i32 @strlen(i8* %t56)
  %t59 = add i32 %t57, %t58
  %t60 = add i32 %t59, 1
  %t61 = sext i32 %t60 to i64
  %t62 = call i8* @star_rc_alloc(i64 %t61, i8* null)
  call i8* @strcpy(i8* %t62, i8* %t55)
  call i8* @strcat(i8* %t62, i8* %t56)
  %t63 = getelementptr inbounds i8*, i8** %t54, i64 0
  store i8* %t62, i8** %t63
  %t64 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.12, i64 0, i32 2, i64 0
  %t65 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t66 = call i32 @strlen(i8* %t64)
  %t67 = call i32 @strlen(i8* %t65)
  %t68 = add i32 %t66, %t67
  %t69 = add i32 %t68, 1
  %t70 = sext i32 %t69 to i64
  %t71 = call i8* @star_rc_alloc(i64 %t70, i8* null)
  call i8* @strcpy(i8* %t71, i8* %t64)
  call i8* @strcat(i8* %t71, i8* %t65)
  %t72 = getelementptr inbounds i8*, i8** %t54, i64 1
  store i8* %t71, i8** %t72
  %t85 = bitcast void (i8*)* @list_release_str to i8*
  %t86 = call i8* @star_rc_alloc(i64 24, i8* %t85)
  %t87 = bitcast i8* %t86 to { i8**, i64, i64 }*
  %t88 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t87, i32 0, i32 0
  store i8** %t54, i8*** %t88
  %t89 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t87, i32 0, i32 1
  store i64 2, i64* %t89
  %t90 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t87, i32 0, i32 2
  store i64 2, i64* %t90
  store i8* %t86, i8** %t49
  %t91 = getelementptr i8*, i8** null, i32 1
  %t92 = ptrtoint i8** %t91 to i64
  %t93 = load i8*, i8** %t49
  %t94 = icmp eq i8* %t93, null
  br i1 %t94, label %list_cow_alloc_3, label %list_cow_check_4
list_cow_alloc_3:
  %t95 = bitcast void (i8*)* @list_release_str to i8*
  %t96 = call i8* @star_rc_alloc(i64 24, i8* %t95)
  %t97 = bitcast i8* %t96 to { i8**, i64, i64 }*
  %t98 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t97, i32 0, i32 0
  store i8** null, i8*** %t98
  %t99 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t97, i32 0, i32 1
  store i64 0, i64* %t99
  %t100 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t97, i32 0, i32 2
  store i64 0, i64* %t100
  store i8* %t96, i8** %t49
  br label %list_cow_done_5
list_cow_check_4:
  %t101 = getelementptr inbounds i8, i8* %t93, i64 -16
  %t102 = bitcast i8* %t101 to i64*
  %t103 = load atomic i64, i64* %t102 seq_cst, align 8
  %t104 = icmp eq i64 %t103, 1
  br i1 %t104, label %list_cow_done_5, label %list_cow_clone_6
list_cow_clone_6:
  %t105 = bitcast i8* %t93 to { i8**, i64, i64 }*
  %t106 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t105, i32 0, i32 0
  %t107 = load i8**, i8*** %t106
  %t108 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t105, i32 0, i32 1
  %t109 = load i64, i64* %t108
  %t110 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t105, i32 0, i32 2
  %t111 = load i64, i64* %t110
  %t112 = bitcast void (i8*)* @list_release_str to i8*
  %t113 = call i8* @star_rc_alloc(i64 24, i8* %t112)
  %t114 = bitcast i8* %t113 to { i8**, i64, i64 }*
  %t115 = mul i64 %t111, %t92
  %t116 = call i8* @malloc(i64 %t115)
  %t117 = bitcast i8* %t116 to i8**
  %t118 = icmp sgt i64 %t109, 0
  br i1 %t118, label %list_cow_copy_7, label %list_cow_after_copy_8
list_cow_copy_7:
  %t119 = mul i64 %t109, %t92
  %t120 = bitcast i8** %t107 to i8*
  call i8* @memcpy(i8* %t116, i8* %t120, i64 %t119)
  %t121 = alloca i64
  store i64 0, i64* %t121
  br label %list_cow_retain_cond_9
list_cow_retain_cond_9:
  %t122 = load i64, i64* %t121
  %t123 = icmp slt i64 %t122, %t109
  br i1 %t123, label %list_cow_retain_body_10, label %list_cow_retain_end_11
list_cow_retain_body_10:
  %t124 = getelementptr inbounds i8*, i8** %t117, i64 %t122
  %t125 = load i8*, i8** %t124
  call void @star_rc_retain(i8* %t125)
  %t126 = add i64 %t122, 1
  store i64 %t126, i64* %t121
  br label %list_cow_retain_cond_9
list_cow_retain_end_11:
  br label %list_cow_after_copy_8
list_cow_after_copy_8:
  %t127 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t114, i32 0, i32 0
  store i8** %t117, i8*** %t127
  %t128 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t114, i32 0, i32 1
  store i64 %t109, i64* %t128
  %t129 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t114, i32 0, i32 2
  store i64 %t111, i64* %t129
  call void @star_rc_release(i8* %t93)
  store i8* %t113, i8** %t49
  br label %list_cow_done_5
list_cow_done_5:
  %t130 = load i8*, i8** %t49
  %t131 = bitcast i8* %t130 to { i8**, i64, i64 }*
  %t132 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t131, i32 0, i32 0
  %t133 = load i8**, i8*** %t132
  %t134 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t131, i32 0, i32 1
  %t135 = load i64, i64* %t134
  %t136 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t131, i32 0, i32 2
  %t137 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t138 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t139 = call i32 @strlen(i8* %t137)
  %t140 = call i32 @strlen(i8* %t138)
  %t141 = add i32 %t139, %t140
  %t142 = add i32 %t141, 1
  %t143 = sext i32 %t142 to i64
  %t144 = call i8* @star_rc_alloc(i64 %t143, i8* null)
  call i8* @strcpy(i8* %t144, i8* %t137)
  call i8* @strcat(i8* %t144, i8* %t138)
  %t145 = load i64, i64* %t136
  %t146 = load i8**, i8*** %t132
  %t147 = icmp sge i64 %t135, %t145
  br i1 %t147, label %list_push_grow_12, label %list_push_store_13
list_push_grow_12:
  %t148 = mul i64 %t145, 2
  %t149 = icmp sgt i64 %t148, 0
  %t150 = select i1 %t149, i64 %t148, i64 1
  %t151 = getelementptr i8*, i8** null, i32 1
  %t152 = ptrtoint i8** %t151 to i64
  %t153 = mul i64 %t150, %t152
  %t154 = call i8* @malloc(i64 %t153)
  %t155 = bitcast i8* %t154 to i8**
  %t156 = icmp sgt i64 %t145, 0
  br i1 %t156, label %list_push_copy_14, label %list_push_after_copy_15
list_push_copy_14:
  %t157 = mul i64 %t135, %t152
  %t158 = bitcast i8** %t146 to i8*
  call i8* @memcpy(i8* %t154, i8* %t158, i64 %t157)
  call void @free(i8* %t158)
  br label %list_push_after_copy_15
list_push_after_copy_15:
  store i8** %t155, i8*** %t132
  store i64 %t150, i64* %t136
  br label %list_push_store_13
list_push_store_13:
  %t159 = load i8**, i8*** %t132
  %t160 = getelementptr inbounds i8*, i8** %t159, i64 %t135
  store i8* %t144, i8** %t160
  %t161 = add i64 %t135, 1
  store i64 %t161, i64* %t134
  %t162 = load i8*, i8** %t49
  %t163 = icmp eq i8* %t162, null
  br i1 %t163, label %list_read_null_16, label %list_read_real_17
list_read_null_16:
  br label %list_read_end_18
list_read_real_17:
  %t164 = bitcast i8* %t162 to { i8**, i64, i64 }*
  %t165 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t164, i32 0, i32 0
  %t166 = load i8**, i8*** %t165
  %t167 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t164, i32 0, i32 1
  %t168 = load i64, i64* %t167
  br label %list_read_end_18
list_read_end_18:
  %t169 = phi i8** [ null, %list_read_null_16 ], [ %t166, %list_read_real_17 ]
  %t170 = phi i64 [ 0, %list_read_null_16 ], [ %t168, %list_read_real_17 ]
  %t171 = sext i32 0 to i64
  %t172 = icmp ult i64 %t171, %t170
  br i1 %t172, label %list_idx_ok_19, label %list_idx_oob_20
list_idx_ok_19:
  %t173 = getelementptr inbounds i8*, i8** %t169, i64 %t171
  %t174 = load i8*, i8** %t173
  %t175 = load i8*, i8** %t173
  call void @star_rc_retain(i8* %t175)
  br label %list_idx_end_21
list_idx_oob_20:
  br label %list_idx_end_21
list_idx_end_21:
  %t176 = phi i8* [ %t174, %list_idx_ok_19 ], [ null, %list_idx_oob_20 ]
  call void @star_rc_release(i8* %t176)
  %t177 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t177, i8* %t176)
  %t178 = load i8*, i8** %t49
  %t179 = icmp eq i8* %t178, null
  br i1 %t179, label %list_read_null_22, label %list_read_real_23
list_read_null_22:
  br label %list_read_end_24
list_read_real_23:
  %t180 = bitcast i8* %t178 to { i8**, i64, i64 }*
  %t181 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t180, i32 0, i32 0
  %t182 = load i8**, i8*** %t181
  %t183 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t180, i32 0, i32 1
  %t184 = load i64, i64* %t183
  br label %list_read_end_24
list_read_end_24:
  %t185 = phi i8** [ null, %list_read_null_22 ], [ %t182, %list_read_real_23 ]
  %t186 = phi i64 [ 0, %list_read_null_22 ], [ %t184, %list_read_real_23 ]
  %t187 = sext i32 1 to i64
  %t188 = icmp ult i64 %t187, %t186
  br i1 %t188, label %list_idx_ok_25, label %list_idx_oob_26
list_idx_ok_25:
  %t189 = getelementptr inbounds i8*, i8** %t185, i64 %t187
  %t190 = load i8*, i8** %t189
  %t191 = load i8*, i8** %t189
  call void @star_rc_retain(i8* %t191)
  br label %list_idx_end_27
list_idx_oob_26:
  br label %list_idx_end_27
list_idx_end_27:
  %t192 = phi i8* [ %t190, %list_idx_ok_25 ], [ null, %list_idx_oob_26 ]
  call void @star_rc_release(i8* %t192)
  %t193 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t193, i8* %t192)
  %t194 = load i8*, i8** %t49
  %t195 = icmp eq i8* %t194, null
  br i1 %t195, label %list_read_null_28, label %list_read_real_29
list_read_null_28:
  br label %list_read_end_30
list_read_real_29:
  %t196 = bitcast i8* %t194 to { i8**, i64, i64 }*
  %t197 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t196, i32 0, i32 0
  %t198 = load i8**, i8*** %t197
  %t199 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t196, i32 0, i32 1
  %t200 = load i64, i64* %t199
  br label %list_read_end_30
list_read_end_30:
  %t201 = phi i8** [ null, %list_read_null_28 ], [ %t198, %list_read_real_29 ]
  %t202 = phi i64 [ 0, %list_read_null_28 ], [ %t200, %list_read_real_29 ]
  %t203 = sext i32 2 to i64
  %t204 = icmp ult i64 %t203, %t202
  br i1 %t204, label %list_idx_ok_31, label %list_idx_oob_32
list_idx_ok_31:
  %t205 = getelementptr inbounds i8*, i8** %t201, i64 %t203
  %t206 = load i8*, i8** %t205
  %t207 = load i8*, i8** %t205
  call void @star_rc_retain(i8* %t207)
  br label %list_idx_end_33
list_idx_oob_32:
  br label %list_idx_end_33
list_idx_end_33:
  %t208 = phi i8* [ %t206, %list_idx_ok_31 ], [ null, %list_idx_oob_32 ]
  call void @star_rc_release(i8* %t208)
  %t209 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.18, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t209, i8* %t208)
  %t210 = load i8*, i8** %t49
  %t211 = icmp eq i8* %t210, null
  br i1 %t211, label %list_read_null_34, label %list_read_real_35
list_read_null_34:
  br label %list_read_end_36
list_read_real_35:
  %t212 = bitcast i8* %t210 to { i8**, i64, i64 }*
  %t213 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t212, i32 0, i32 0
  %t214 = load i8**, i8*** %t213
  %t215 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t212, i32 0, i32 1
  %t216 = load i64, i64* %t215
  br label %list_read_end_36
list_read_end_36:
  %t217 = phi i8** [ null, %list_read_null_34 ], [ %t214, %list_read_real_35 ]
  %t218 = phi i64 [ 0, %list_read_null_34 ], [ %t216, %list_read_real_35 ]
  %t219 = trunc i64 %t218 to i32
  %t220 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.19, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t220, i32 %t219)
  %t221 = alloca i8*
  %t222 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.20, i64 0, i32 2, i64 0
  %t223 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.21, i64 0, i32 2, i64 0
  %t224 = call i32 @strlen(i8* %t222)
  %t225 = call i32 @strlen(i8* %t223)
  %t226 = add i32 %t224, %t225
  %t227 = add i32 %t226, 1
  %t228 = sext i32 %t227 to i64
  %t229 = call i8* @star_rc_alloc(i64 %t228, i8* null)
  call i8* @strcpy(i8* %t229, i8* %t222)
  call i8* @strcat(i8* %t229, i8* %t223)
  store i8* %t229, i8** %t221
  %t230 = load i8*, i8** %t221
  %t231 = load i8*, i8** %t221
  call void @star_rc_retain(i8* %t231)
  %t232 = call i32 @shout_len(i8* %t230)
  %t233 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t233, i32 %t232)
  %t234 = alloca i32
  store i32 0, i32* %t234
  %t235 = alloca i8*
  %t236 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.23, i64 0, i32 2, i64 0
  store i8* %t236, i8** %t235
  br label %while_cond_37
while_cond_37:
  %t237 = load i32, i32* %t234
  %t238 = icmp slt i32 %t237, 5
  br i1 %t238, label %while_body_38, label %while_end_40
while_body_38:
  %t239 = load i8*, i8** %t235
  %t240 = load i8*, i8** %t235
  call void @star_rc_retain(i8* %t240)
  call void @star_rc_release(i8* %t239)
  %t241 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.24, i64 0, i32 2, i64 0
  %t242 = call i32 @strlen(i8* %t239)
  %t243 = call i32 @strlen(i8* %t241)
  %t244 = add i32 %t242, %t243
  %t245 = add i32 %t244, 1
  %t246 = sext i32 %t245 to i64
  %t247 = call i8* @star_rc_alloc(i64 %t246, i8* null)
  call i8* @strcpy(i8* %t247, i8* %t239)
  call i8* @strcat(i8* %t247, i8* %t241)
  %t248 = load i8*, i8** %t235
  call void @star_rc_release(i8* %t248)
  store i8* %t247, i8** %t235
  %t249 = load i32, i32* %t234
  %t250 = add i32 %t249, 1
  store i32 %t250, i32* %t234
  br label %while_cond_37
while_else_39:
  br label %while_end_40
while_end_40:
  %t251 = load i8*, i8** %t235
  %t252 = load i8*, i8** %t235
  call void @star_rc_retain(i8* %t252)
  call void @star_rc_release(i8* %t251)
  call i32 (i8*, ...) @printf(i8* %t251)
  %t253 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.25, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t253)
  %t254 = load i8*, i8** %t235
  call void @star_rc_release(i8* %t254)
  %t255 = load i8*, i8** %t221
  call void @star_rc_release(i8* %t255)
  %t256 = load i8*, i8** %t49
  call void @star_rc_release(i8* %t256)
  %t257 = getelementptr inbounds %Greeting, %Greeting* %t41, i32 0, i32 0
  %t258 = load i8*, i8** %t257
  call void @star_rc_release(i8* %t258)
  %t259 = getelementptr inbounds %Greeting, %Greeting* %t25, i32 0, i32 0
  %t260 = load i8*, i8** %t259
  call void @star_rc_release(i8* %t260)
  %t261 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t261)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_str(i8* %objp) {
entry:
  %t73 = bitcast i8* %objp to { i8**, i64, i64 }*
  %t74 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t73, i32 0, i32 0
  %t75 = load i8**, i8*** %t74
  %t76 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t73, i32 0, i32 1
  %t77 = load i64, i64* %t76
  %t78 = alloca i64
  store i64 0, i64* %t78
  br label %list_release_cond_0
list_release_cond_0:
  %t79 = load i64, i64* %t78
  %t80 = icmp slt i64 %t79, %t77
  br i1 %t80, label %list_release_body_1, label %list_release_end_2
list_release_body_1:
  %t81 = getelementptr inbounds i8*, i8** %t75, i64 %t79
  %t82 = load i8*, i8** %t81
  call void @star_rc_release(i8* %t82)
  %t83 = add i64 %t79, 1
  store i64 %t83, i64* %t78
  br label %list_release_cond_0
list_release_end_2:
  %t84 = bitcast i8** %t75 to i8*
  call void @free(i8* %t84)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"!!!\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"foo\00" }
@.str.2 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"bar\00" }
@.str.3 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.4 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"baz\00" }
@.str.5 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.6 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"hello\00" }
@.str.7 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c" world\00" }
@.str.8 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.9 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.10 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"alpha\00" }
@.str.11 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"-1\00" }
@.str.12 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"beta\00" }
@.str.13 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"-2\00" }
@.str.14 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"gamma\00" }
@.str.15 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"-3\00" }
@.str.16 = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.str.17 = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.str.18 = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.str.19 = private unnamed_addr constant [16 x i8] c"words len = %d\0A\00"
@.str.20 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"g\00" }
@.str.21 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"o\00" }
@.str.22 = private unnamed_addr constant [20 x i8] c"shout_len(go) = %d\0A\00"
@.str.23 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"start\00" }
@.str.24 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"-x\00" }
@.str.25 = private unnamed_addr constant [2 x i8] c"\0A\00"
