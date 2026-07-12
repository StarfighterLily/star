; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
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

define i32 @main() {
entry:
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
  %t50 = call i8* @malloc(i64 16)
  %t51 = bitcast i8* %t50 to i8**
  %t52 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t53 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t54 = call i32 @strlen(i8* %t52)
  %t55 = call i32 @strlen(i8* %t53)
  %t56 = add i32 %t54, %t55
  %t57 = add i32 %t56, 1
  %t58 = sext i32 %t57 to i64
  %t59 = call i8* @star_rc_alloc(i64 %t58, i8* null)
  call i8* @strcpy(i8* %t59, i8* %t52)
  call i8* @strcat(i8* %t59, i8* %t53)
  %t60 = getelementptr inbounds i8*, i8** %t51, i64 0
  store i8* %t59, i8** %t60
  %t61 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.12, i64 0, i32 2, i64 0
  %t62 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t63 = call i32 @strlen(i8* %t61)
  %t64 = call i32 @strlen(i8* %t62)
  %t65 = add i32 %t63, %t64
  %t66 = add i32 %t65, 1
  %t67 = sext i32 %t66 to i64
  %t68 = call i8* @star_rc_alloc(i64 %t67, i8* null)
  call i8* @strcpy(i8* %t68, i8* %t61)
  call i8* @strcat(i8* %t68, i8* %t62)
  %t69 = getelementptr inbounds i8*, i8** %t51, i64 1
  store i8* %t68, i8** %t69
  %t82 = bitcast void (i8*)* @list_release_str to i8*
  %t83 = call i8* @star_rc_alloc(i64 24, i8* %t82)
  %t84 = bitcast i8* %t83 to { i8**, i64, i64 }*
  %t85 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t84, i32 0, i32 0
  store i8** %t51, i8*** %t85
  %t86 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t84, i32 0, i32 1
  store i64 2, i64* %t86
  %t87 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t84, i32 0, i32 2
  store i64 2, i64* %t87
  store i8* %t83, i8** %t49
  %t88 = load i8*, i8** %t49
  %t89 = icmp eq i8* %t88, null
  br i1 %t89, label %list_cow_alloc_3, label %list_cow_check_4
list_cow_alloc_3:
  %t90 = bitcast void (i8*)* @list_release_str to i8*
  %t91 = call i8* @star_rc_alloc(i64 24, i8* %t90)
  %t92 = bitcast i8* %t91 to { i8**, i64, i64 }*
  %t93 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t92, i32 0, i32 0
  store i8** null, i8*** %t93
  %t94 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t92, i32 0, i32 1
  store i64 0, i64* %t94
  %t95 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t92, i32 0, i32 2
  store i64 0, i64* %t95
  store i8* %t91, i8** %t49
  br label %list_cow_done_5
list_cow_check_4:
  %t96 = getelementptr inbounds i8, i8* %t88, i64 -16
  %t97 = bitcast i8* %t96 to i64*
  %t98 = load atomic i64, i64* %t97 seq_cst, align 8
  %t99 = icmp eq i64 %t98, 1
  br i1 %t99, label %list_cow_done_5, label %list_cow_clone_6
list_cow_clone_6:
  %t100 = bitcast i8* %t88 to { i8**, i64, i64 }*
  %t101 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t100, i32 0, i32 0
  %t102 = load i8**, i8*** %t101
  %t103 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t100, i32 0, i32 1
  %t104 = load i64, i64* %t103
  %t105 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t100, i32 0, i32 2
  %t106 = load i64, i64* %t105
  %t107 = bitcast void (i8*)* @list_release_str to i8*
  %t108 = call i8* @star_rc_alloc(i64 24, i8* %t107)
  %t109 = bitcast i8* %t108 to { i8**, i64, i64 }*
  %t110 = mul i64 %t106, 8
  %t111 = call i8* @malloc(i64 %t110)
  %t112 = bitcast i8* %t111 to i8**
  %t113 = icmp sgt i64 %t104, 0
  br i1 %t113, label %list_cow_copy_7, label %list_cow_after_copy_8
list_cow_copy_7:
  %t114 = mul i64 %t104, 8
  %t115 = bitcast i8** %t102 to i8*
  call i8* @memcpy(i8* %t111, i8* %t115, i64 %t114)
  %t116 = alloca i64
  store i64 0, i64* %t116
  br label %list_cow_retain_cond_9
list_cow_retain_cond_9:
  %t117 = load i64, i64* %t116
  %t118 = icmp slt i64 %t117, %t104
  br i1 %t118, label %list_cow_retain_body_10, label %list_cow_retain_end_11
list_cow_retain_body_10:
  %t119 = getelementptr inbounds i8*, i8** %t112, i64 %t117
  %t120 = load i8*, i8** %t119
  call void @star_rc_retain(i8* %t120)
  %t121 = add i64 %t117, 1
  store i64 %t121, i64* %t116
  br label %list_cow_retain_cond_9
list_cow_retain_end_11:
  br label %list_cow_after_copy_8
list_cow_after_copy_8:
  %t122 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t109, i32 0, i32 0
  store i8** %t112, i8*** %t122
  %t123 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t109, i32 0, i32 1
  store i64 %t104, i64* %t123
  %t124 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t109, i32 0, i32 2
  store i64 %t106, i64* %t124
  call void @star_rc_release(i8* %t88)
  store i8* %t108, i8** %t49
  br label %list_cow_done_5
list_cow_done_5:
  %t125 = load i8*, i8** %t49
  %t126 = bitcast i8* %t125 to { i8**, i64, i64 }*
  %t127 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t126, i32 0, i32 0
  %t128 = load i8**, i8*** %t127
  %t129 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t126, i32 0, i32 1
  %t130 = load i64, i64* %t129
  %t131 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t126, i32 0, i32 2
  %t132 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t133 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t134 = call i32 @strlen(i8* %t132)
  %t135 = call i32 @strlen(i8* %t133)
  %t136 = add i32 %t134, %t135
  %t137 = add i32 %t136, 1
  %t138 = sext i32 %t137 to i64
  %t139 = call i8* @star_rc_alloc(i64 %t138, i8* null)
  call i8* @strcpy(i8* %t139, i8* %t132)
  call i8* @strcat(i8* %t139, i8* %t133)
  %t140 = load i64, i64* %t131
  %t141 = load i8**, i8*** %t127
  %t142 = icmp sge i64 %t130, %t140
  br i1 %t142, label %list_push_grow_12, label %list_push_store_13
list_push_grow_12:
  %t143 = mul i64 %t140, 2
  %t144 = icmp sgt i64 %t143, 0
  %t145 = select i1 %t144, i64 %t143, i64 1
  %t146 = mul i64 %t145, 8
  %t147 = call i8* @malloc(i64 %t146)
  %t148 = bitcast i8* %t147 to i8**
  %t149 = icmp sgt i64 %t140, 0
  br i1 %t149, label %list_push_copy_14, label %list_push_after_copy_15
list_push_copy_14:
  %t150 = mul i64 %t130, 8
  %t151 = bitcast i8** %t141 to i8*
  call i8* @memcpy(i8* %t147, i8* %t151, i64 %t150)
  call void @free(i8* %t151)
  br label %list_push_after_copy_15
list_push_after_copy_15:
  store i8** %t148, i8*** %t127
  store i64 %t145, i64* %t131
  br label %list_push_store_13
list_push_store_13:
  %t152 = load i8**, i8*** %t127
  %t153 = getelementptr inbounds i8*, i8** %t152, i64 %t130
  store i8* %t139, i8** %t153
  %t154 = add i64 %t130, 1
  store i64 %t154, i64* %t129
  %t155 = load i8*, i8** %t49
  %t156 = icmp eq i8* %t155, null
  br i1 %t156, label %list_read_null_16, label %list_read_real_17
list_read_null_16:
  br label %list_read_end_18
list_read_real_17:
  %t157 = bitcast i8* %t155 to { i8**, i64, i64 }*
  %t158 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t157, i32 0, i32 0
  %t159 = load i8**, i8*** %t158
  %t160 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t157, i32 0, i32 1
  %t161 = load i64, i64* %t160
  br label %list_read_end_18
list_read_end_18:
  %t162 = phi i8** [ null, %list_read_null_16 ], [ %t159, %list_read_real_17 ]
  %t163 = phi i64 [ 0, %list_read_null_16 ], [ %t161, %list_read_real_17 ]
  %t164 = sext i32 0 to i64
  %t165 = icmp ult i64 %t164, %t163
  br i1 %t165, label %list_idx_ok_19, label %list_idx_oob_20
list_idx_ok_19:
  %t166 = getelementptr inbounds i8*, i8** %t162, i64 %t164
  %t167 = load i8*, i8** %t166
  %t168 = load i8*, i8** %t166
  call void @star_rc_retain(i8* %t168)
  br label %list_idx_end_21
list_idx_oob_20:
  br label %list_idx_end_21
list_idx_end_21:
  %t169 = phi i8* [ %t167, %list_idx_ok_19 ], [ null, %list_idx_oob_20 ]
  call void @star_rc_release(i8* %t169)
  %t170 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t170, i8* %t169)
  %t171 = load i8*, i8** %t49
  %t172 = icmp eq i8* %t171, null
  br i1 %t172, label %list_read_null_22, label %list_read_real_23
list_read_null_22:
  br label %list_read_end_24
list_read_real_23:
  %t173 = bitcast i8* %t171 to { i8**, i64, i64 }*
  %t174 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t173, i32 0, i32 0
  %t175 = load i8**, i8*** %t174
  %t176 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t173, i32 0, i32 1
  %t177 = load i64, i64* %t176
  br label %list_read_end_24
list_read_end_24:
  %t178 = phi i8** [ null, %list_read_null_22 ], [ %t175, %list_read_real_23 ]
  %t179 = phi i64 [ 0, %list_read_null_22 ], [ %t177, %list_read_real_23 ]
  %t180 = sext i32 1 to i64
  %t181 = icmp ult i64 %t180, %t179
  br i1 %t181, label %list_idx_ok_25, label %list_idx_oob_26
list_idx_ok_25:
  %t182 = getelementptr inbounds i8*, i8** %t178, i64 %t180
  %t183 = load i8*, i8** %t182
  %t184 = load i8*, i8** %t182
  call void @star_rc_retain(i8* %t184)
  br label %list_idx_end_27
list_idx_oob_26:
  br label %list_idx_end_27
list_idx_end_27:
  %t185 = phi i8* [ %t183, %list_idx_ok_25 ], [ null, %list_idx_oob_26 ]
  call void @star_rc_release(i8* %t185)
  %t186 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t186, i8* %t185)
  %t187 = load i8*, i8** %t49
  %t188 = icmp eq i8* %t187, null
  br i1 %t188, label %list_read_null_28, label %list_read_real_29
list_read_null_28:
  br label %list_read_end_30
list_read_real_29:
  %t189 = bitcast i8* %t187 to { i8**, i64, i64 }*
  %t190 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t189, i32 0, i32 0
  %t191 = load i8**, i8*** %t190
  %t192 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t189, i32 0, i32 1
  %t193 = load i64, i64* %t192
  br label %list_read_end_30
list_read_end_30:
  %t194 = phi i8** [ null, %list_read_null_28 ], [ %t191, %list_read_real_29 ]
  %t195 = phi i64 [ 0, %list_read_null_28 ], [ %t193, %list_read_real_29 ]
  %t196 = sext i32 2 to i64
  %t197 = icmp ult i64 %t196, %t195
  br i1 %t197, label %list_idx_ok_31, label %list_idx_oob_32
list_idx_ok_31:
  %t198 = getelementptr inbounds i8*, i8** %t194, i64 %t196
  %t199 = load i8*, i8** %t198
  %t200 = load i8*, i8** %t198
  call void @star_rc_retain(i8* %t200)
  br label %list_idx_end_33
list_idx_oob_32:
  br label %list_idx_end_33
list_idx_end_33:
  %t201 = phi i8* [ %t199, %list_idx_ok_31 ], [ null, %list_idx_oob_32 ]
  call void @star_rc_release(i8* %t201)
  %t202 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.18, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t202, i8* %t201)
  %t203 = load i8*, i8** %t49
  %t204 = icmp eq i8* %t203, null
  br i1 %t204, label %list_read_null_34, label %list_read_real_35
list_read_null_34:
  br label %list_read_end_36
list_read_real_35:
  %t205 = bitcast i8* %t203 to { i8**, i64, i64 }*
  %t206 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t205, i32 0, i32 0
  %t207 = load i8**, i8*** %t206
  %t208 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t205, i32 0, i32 1
  %t209 = load i64, i64* %t208
  br label %list_read_end_36
list_read_end_36:
  %t210 = phi i8** [ null, %list_read_null_34 ], [ %t207, %list_read_real_35 ]
  %t211 = phi i64 [ 0, %list_read_null_34 ], [ %t209, %list_read_real_35 ]
  %t212 = trunc i64 %t211 to i32
  %t213 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.19, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t213, i32 %t212)
  %t214 = alloca i8*
  %t215 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.20, i64 0, i32 2, i64 0
  %t216 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.21, i64 0, i32 2, i64 0
  %t217 = call i32 @strlen(i8* %t215)
  %t218 = call i32 @strlen(i8* %t216)
  %t219 = add i32 %t217, %t218
  %t220 = add i32 %t219, 1
  %t221 = sext i32 %t220 to i64
  %t222 = call i8* @star_rc_alloc(i64 %t221, i8* null)
  call i8* @strcpy(i8* %t222, i8* %t215)
  call i8* @strcat(i8* %t222, i8* %t216)
  store i8* %t222, i8** %t214
  %t223 = load i8*, i8** %t214
  %t224 = load i8*, i8** %t214
  call void @star_rc_retain(i8* %t224)
  %t225 = call i32 @shout_len(i8* %t223)
  %t226 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t226, i32 %t225)
  %t227 = alloca i32
  store i32 0, i32* %t227
  %t228 = alloca i8*
  %t229 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.23, i64 0, i32 2, i64 0
  store i8* %t229, i8** %t228
  br label %while_cond_37
while_cond_37:
  %t230 = load i32, i32* %t227
  %t231 = icmp slt i32 %t230, 5
  br i1 %t231, label %while_body_38, label %while_end_40
while_body_38:
  %t232 = load i8*, i8** %t228
  %t233 = load i8*, i8** %t228
  call void @star_rc_retain(i8* %t233)
  call void @star_rc_release(i8* %t232)
  %t234 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.24, i64 0, i32 2, i64 0
  %t235 = call i32 @strlen(i8* %t232)
  %t236 = call i32 @strlen(i8* %t234)
  %t237 = add i32 %t235, %t236
  %t238 = add i32 %t237, 1
  %t239 = sext i32 %t238 to i64
  %t240 = call i8* @star_rc_alloc(i64 %t239, i8* null)
  call i8* @strcpy(i8* %t240, i8* %t232)
  call i8* @strcat(i8* %t240, i8* %t234)
  %t241 = load i8*, i8** %t228
  call void @star_rc_release(i8* %t241)
  store i8* %t240, i8** %t228
  %t242 = load i32, i32* %t227
  %t243 = add i32 %t242, 1
  store i32 %t243, i32* %t227
  br label %while_cond_37
while_else_39:
  br label %while_end_40
while_end_40:
  %t244 = load i8*, i8** %t228
  %t245 = load i8*, i8** %t228
  call void @star_rc_retain(i8* %t245)
  call void @star_rc_release(i8* %t244)
  call i32 (i8*, ...) @printf(i8* %t244)
  %t246 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.25, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t246)
  %t247 = load i8*, i8** %t228
  call void @star_rc_release(i8* %t247)
  %t248 = load i8*, i8** %t214
  call void @star_rc_release(i8* %t248)
  %t249 = load i8*, i8** %t49
  call void @star_rc_release(i8* %t249)
  %t250 = getelementptr inbounds %Greeting, %Greeting* %t41, i32 0, i32 0
  %t251 = load i8*, i8** %t250
  call void @star_rc_release(i8* %t251)
  %t252 = getelementptr inbounds %Greeting, %Greeting* %t25, i32 0, i32 0
  %t253 = load i8*, i8** %t252
  call void @star_rc_release(i8* %t253)
  %t254 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t254)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_str(i8* %objp) {
entry:
  %t70 = bitcast i8* %objp to { i8**, i64, i64 }*
  %t71 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t70, i32 0, i32 0
  %t72 = load i8**, i8*** %t71
  %t73 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t70, i32 0, i32 1
  %t74 = load i64, i64* %t73
  %t75 = alloca i64
  store i64 0, i64* %t75
  br label %list_release_cond_0
list_release_cond_0:
  %t76 = load i64, i64* %t75
  %t77 = icmp slt i64 %t76, %t74
  br i1 %t77, label %list_release_body_1, label %list_release_end_2
list_release_body_1:
  %t78 = getelementptr inbounds i8*, i8** %t72, i64 %t76
  %t79 = load i8*, i8** %t78
  call void @star_rc_release(i8* %t79)
  %t80 = add i64 %t76, 1
  store i64 %t80, i64* %t75
  br label %list_release_cond_0
list_release_end_2:
  %t81 = bitcast i8** %t72 to i8*
  call void @free(i8* %t81)
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
