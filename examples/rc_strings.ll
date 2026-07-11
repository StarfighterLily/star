; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
declare i32 @puts(i8*)
declare noalias i8* @malloc(i64)
declare void @free(i8*)
declare void @exit(i32) noreturn
declare i32 @strlen(i8*)
declare i8* @memcpy(i8*, i8*, i64)
declare i8* @strcpy(i8*, i8*)
declare i8* @strcat(i8*, i8*)
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
  %rc = load i64, i64* %hdr
  %is_immortal = icmp eq i64 %rc, -1
  br i1 %is_immortal, label %done, label %incr
incr:
  %rc1 = add i64 %rc, 1
  store i64 %rc1, i64* %hdr
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
  %rc = load i64, i64* %hdr
  %is_immortal = icmp eq i64 %rc, -1
  br i1 %is_immortal, label %done, label %decr
decr:
  %rc1 = sub i64 %rc, 1
  store i64 %rc1, i64* %hdr
  %iszero = icmp eq i64 %rc1, 0
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
  %t4 = load i8*, i8** %t3
  call void @star_rc_retain(i8* %t4)
  %t5 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t5)
  %t7 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t6 = alloca i8*
  store i8* %t7, i8** %t6
  %t8 = load i8*, i8** %t6
  %t9 = call i32 @strlen(i8* %t5)
  %t10 = call i32 @strlen(i8* %t8)
  %t11 = add i32 %t9, %t10
  %t12 = add i32 %t11, 1
  %t13 = sext i32 %t12 to i64
  %t14 = call i8* @star_rc_alloc(i64 %t13, i8* null)
  call i8* @strcpy(i8* %t14, i8* %t5)
  call i8* @strcat(i8* %t14, i8* %t8)
  %t15 = alloca i8*
  store i8* %t14, i8** %t15
  store i8* %t15, i8** %t1
  %t16 = load i8*, i8** %t1
  %t17 = load i8*, i8** %t1
  %t18 = load i8*, i8** %t17
  call void @star_rc_retain(i8* %t18)
  %t19 = load i8*, i8** %t16
  call void @star_rc_release(i8* %t19)
  %t20 = call i32 @strlen(i8* %t19)
  %t21 = load i8*, i8** %t1
  %t22 = load i8*, i8** %t21
  call void @star_rc_release(i8* %t22)
  %t23 = load i8*, i8** %t0
  %t24 = load i8*, i8** %t23
  call void @star_rc_release(i8* %t24)
  ret i32 %t20
}

define i32 @main() {
entry:
  %t0 = alloca i8*
  %t2 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t1 = alloca i8*
  store i8* %t2, i8** %t1
  %t3 = load i8*, i8** %t1
  %t5 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t4 = alloca i8*
  store i8* %t5, i8** %t4
  %t6 = load i8*, i8** %t4
  %t7 = call i32 @strlen(i8* %t3)
  %t8 = call i32 @strlen(i8* %t6)
  %t9 = add i32 %t7, %t8
  %t10 = add i32 %t9, 1
  %t11 = sext i32 %t10 to i64
  %t12 = call i8* @star_rc_alloc(i64 %t11, i8* null)
  call i8* @strcpy(i8* %t12, i8* %t3)
  call i8* @strcat(i8* %t12, i8* %t6)
  %t13 = alloca i8*
  store i8* %t12, i8** %t13
  store i8* %t13, i8** %t0
  %t14 = load i8*, i8** %t0
  %t15 = load i8*, i8** %t0
  %t16 = load i8*, i8** %t15
  call void @star_rc_retain(i8* %t16)
  %t17 = load i8*, i8** %t14
  call void @star_rc_release(i8* %t17)
  call i32 (i8*, ...) @printf(i8* %t17)
  %t18 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t18)
  %t19 = load i8*, i8** %t0
  %t20 = load i8*, i8** %t0
  %t21 = load i8*, i8** %t20
  call void @star_rc_retain(i8* %t21)
  %t22 = load i8*, i8** %t19
  call void @star_rc_release(i8* %t22)
  %t24 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t23 = alloca i8*
  store i8* %t24, i8** %t23
  %t25 = load i8*, i8** %t23
  %t26 = call i32 @strlen(i8* %t22)
  %t27 = call i32 @strlen(i8* %t25)
  %t28 = add i32 %t26, %t27
  %t29 = add i32 %t28, 1
  %t30 = sext i32 %t29 to i64
  %t31 = call i8* @star_rc_alloc(i64 %t30, i8* null)
  call i8* @strcpy(i8* %t31, i8* %t22)
  call i8* @strcat(i8* %t31, i8* %t25)
  %t32 = alloca i8*
  store i8* %t31, i8** %t32
  %t33 = load i8*, i8** %t0
  %t34 = load i8*, i8** %t33
  call void @star_rc_release(i8* %t34)
  store i8* %t32, i8** %t0
  %t35 = load i8*, i8** %t0
  %t36 = load i8*, i8** %t0
  %t37 = load i8*, i8** %t36
  call void @star_rc_retain(i8* %t37)
  %t38 = load i8*, i8** %t35
  call void @star_rc_release(i8* %t38)
  call i32 (i8*, ...) @printf(i8* %t38)
  %t39 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t39)
  %t40 = alloca %Greeting
  %t41 = alloca %Greeting
  %t43 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t42 = alloca i8*
  store i8* %t43, i8** %t42
  %t44 = load i8*, i8** %t42
  %t46 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t45 = alloca i8*
  store i8* %t46, i8** %t45
  %t47 = load i8*, i8** %t45
  %t48 = call i32 @strlen(i8* %t44)
  %t49 = call i32 @strlen(i8* %t47)
  %t50 = add i32 %t48, %t49
  %t51 = add i32 %t50, 1
  %t52 = sext i32 %t51 to i64
  %t53 = call i8* @star_rc_alloc(i64 %t52, i8* null)
  call i8* @strcpy(i8* %t53, i8* %t44)
  call i8* @strcat(i8* %t53, i8* %t47)
  %t54 = alloca i8*
  store i8* %t53, i8** %t54
  %t55 = getelementptr inbounds %Greeting, %Greeting* %t41, i32 0, i32 0
  store i8* %t54, i8** %t55
  %t56 = load %Greeting, %Greeting* %t41
  store %Greeting %t56, %Greeting* %t40
  %t57 = getelementptr inbounds %Greeting, %Greeting* %t40, i32 0, i32 0
  %t58 = load i8*, i8** %t57
  %t59 = load i8*, i8** %t57
  %t60 = load i8*, i8** %t59
  call void @star_rc_retain(i8* %t60)
  %t61 = load i8*, i8** %t58
  call void @star_rc_release(i8* %t61)
  call i32 (i8*, ...) @printf(i8* %t61)
  %t62 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t62)
  %t63 = alloca %Greeting
  %t64 = load %Greeting, %Greeting* %t40
  %t65 = getelementptr inbounds %Greeting, %Greeting* %t40, i32 0, i32 0
  %t66 = load i8*, i8** %t65
  %t67 = load i8*, i8** %t66
  call void @star_rc_retain(i8* %t67)
  store %Greeting %t64, %Greeting* %t63
  %t68 = getelementptr inbounds %Greeting, %Greeting* %t63, i32 0, i32 0
  %t69 = load i8*, i8** %t68
  %t70 = load i8*, i8** %t68
  %t71 = load i8*, i8** %t70
  call void @star_rc_retain(i8* %t71)
  %t72 = load i8*, i8** %t69
  call void @star_rc_release(i8* %t72)
  call i32 (i8*, ...) @printf(i8* %t72)
  %t73 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t73)
  %t74 = alloca { i8**, i64, i64 }
  %t75 = call i8* @malloc(i64 16)
  %t76 = bitcast i8* %t75 to i8**
  %t78 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t77 = alloca i8*
  store i8* %t78, i8** %t77
  %t79 = load i8*, i8** %t77
  %t81 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t80 = alloca i8*
  store i8* %t81, i8** %t80
  %t82 = load i8*, i8** %t80
  %t83 = call i32 @strlen(i8* %t79)
  %t84 = call i32 @strlen(i8* %t82)
  %t85 = add i32 %t83, %t84
  %t86 = add i32 %t85, 1
  %t87 = sext i32 %t86 to i64
  %t88 = call i8* @star_rc_alloc(i64 %t87, i8* null)
  call i8* @strcpy(i8* %t88, i8* %t79)
  call i8* @strcat(i8* %t88, i8* %t82)
  %t89 = alloca i8*
  store i8* %t88, i8** %t89
  %t90 = getelementptr inbounds i8*, i8** %t76, i64 0
  store i8* %t89, i8** %t90
  %t92 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.12, i64 0, i32 2, i64 0
  %t91 = alloca i8*
  store i8* %t92, i8** %t91
  %t93 = load i8*, i8** %t91
  %t95 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t94 = alloca i8*
  store i8* %t95, i8** %t94
  %t96 = load i8*, i8** %t94
  %t97 = call i32 @strlen(i8* %t93)
  %t98 = call i32 @strlen(i8* %t96)
  %t99 = add i32 %t97, %t98
  %t100 = add i32 %t99, 1
  %t101 = sext i32 %t100 to i64
  %t102 = call i8* @star_rc_alloc(i64 %t101, i8* null)
  call i8* @strcpy(i8* %t102, i8* %t93)
  call i8* @strcat(i8* %t102, i8* %t96)
  %t103 = alloca i8*
  store i8* %t102, i8** %t103
  %t104 = getelementptr inbounds i8*, i8** %t76, i64 1
  store i8* %t103, i8** %t104
  %t105 = alloca { i8**, i64, i64 }
  %t106 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t105, i32 0, i32 0
  store i8** %t76, i8*** %t106
  %t107 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t105, i32 0, i32 1
  store i64 2, i64* %t107
  %t108 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t105, i32 0, i32 2
  store i64 2, i64* %t108
  %t109 = load { i8**, i64, i64 }, { i8**, i64, i64 }* %t105
  store { i8**, i64, i64 } %t109, { i8**, i64, i64 }* %t74
  %t110 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t74, i32 0, i32 0
  %t111 = load i8**, i8*** %t110
  %t112 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t74, i32 0, i32 1
  %t113 = load i64, i64* %t112
  %t114 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t74, i32 0, i32 2
  %t116 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t115 = alloca i8*
  store i8* %t116, i8** %t115
  %t117 = load i8*, i8** %t115
  %t119 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t118 = alloca i8*
  store i8* %t119, i8** %t118
  %t120 = load i8*, i8** %t118
  %t121 = call i32 @strlen(i8* %t117)
  %t122 = call i32 @strlen(i8* %t120)
  %t123 = add i32 %t121, %t122
  %t124 = add i32 %t123, 1
  %t125 = sext i32 %t124 to i64
  %t126 = call i8* @star_rc_alloc(i64 %t125, i8* null)
  call i8* @strcpy(i8* %t126, i8* %t117)
  call i8* @strcat(i8* %t126, i8* %t120)
  %t127 = alloca i8*
  store i8* %t126, i8** %t127
  %t128 = load i64, i64* %t114
  %t129 = load i8**, i8*** %t110
  %t130 = icmp sge i64 %t113, %t128
  br i1 %t130, label %list_push_grow_0, label %list_push_store_1
list_push_grow_0:
  %t131 = mul i64 %t128, 2
  %t132 = icmp sgt i64 %t131, 0
  %t133 = select i1 %t132, i64 %t131, i64 1
  %t134 = mul i64 %t133, 8
  %t135 = call i8* @malloc(i64 %t134)
  %t136 = bitcast i8* %t135 to i8**
  %t137 = icmp sgt i64 %t128, 0
  br i1 %t137, label %list_push_copy_2, label %list_push_after_copy_3
list_push_copy_2:
  %t138 = mul i64 %t113, 8
  %t139 = bitcast i8** %t129 to i8*
  call i8* @memcpy(i8* %t135, i8* %t139, i64 %t138)
  call void @free(i8* %t139)
  br label %list_push_after_copy_3
list_push_after_copy_3:
  store i8** %t136, i8*** %t110
  store i64 %t133, i64* %t114
  br label %list_push_store_1
list_push_store_1:
  %t140 = load i8**, i8*** %t110
  %t141 = getelementptr inbounds i8*, i8** %t140, i64 %t113
  store i8* %t127, i8** %t141
  %t142 = add i64 %t113, 1
  store i64 %t142, i64* %t112
  %t143 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t74, i32 0, i32 0
  %t144 = load i8**, i8*** %t143
  %t145 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t74, i32 0, i32 1
  %t146 = load i64, i64* %t145
  %t147 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t74, i32 0, i32 2
  %t148 = sext i32 0 to i64
  %t149 = icmp ult i64 %t148, %t146
  br i1 %t149, label %list_idx_ok_4, label %list_idx_oob_5
list_idx_ok_4:
  %t150 = getelementptr inbounds i8*, i8** %t144, i64 %t148
  %t151 = load i8*, i8** %t150
  %t152 = load i8*, i8** %t150
  %t153 = load i8*, i8** %t152
  call void @star_rc_retain(i8* %t153)
  br label %list_idx_end_6
list_idx_oob_5:
  br label %list_idx_end_6
list_idx_end_6:
  %t154 = phi i8* [ %t151, %list_idx_ok_4 ], [ null, %list_idx_oob_5 ]
  %t155 = load i8*, i8** %t154
  call void @star_rc_release(i8* %t155)
  %t156 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t156, i8* %t155)
  %t157 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t74, i32 0, i32 0
  %t158 = load i8**, i8*** %t157
  %t159 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t74, i32 0, i32 1
  %t160 = load i64, i64* %t159
  %t161 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t74, i32 0, i32 2
  %t162 = sext i32 1 to i64
  %t163 = icmp ult i64 %t162, %t160
  br i1 %t163, label %list_idx_ok_7, label %list_idx_oob_8
list_idx_ok_7:
  %t164 = getelementptr inbounds i8*, i8** %t158, i64 %t162
  %t165 = load i8*, i8** %t164
  %t166 = load i8*, i8** %t164
  %t167 = load i8*, i8** %t166
  call void @star_rc_retain(i8* %t167)
  br label %list_idx_end_9
list_idx_oob_8:
  br label %list_idx_end_9
list_idx_end_9:
  %t168 = phi i8* [ %t165, %list_idx_ok_7 ], [ null, %list_idx_oob_8 ]
  %t169 = load i8*, i8** %t168
  call void @star_rc_release(i8* %t169)
  %t170 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t170, i8* %t169)
  %t171 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t74, i32 0, i32 0
  %t172 = load i8**, i8*** %t171
  %t173 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t74, i32 0, i32 1
  %t174 = load i64, i64* %t173
  %t175 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t74, i32 0, i32 2
  %t176 = sext i32 2 to i64
  %t177 = icmp ult i64 %t176, %t174
  br i1 %t177, label %list_idx_ok_10, label %list_idx_oob_11
list_idx_ok_10:
  %t178 = getelementptr inbounds i8*, i8** %t172, i64 %t176
  %t179 = load i8*, i8** %t178
  %t180 = load i8*, i8** %t178
  %t181 = load i8*, i8** %t180
  call void @star_rc_retain(i8* %t181)
  br label %list_idx_end_12
list_idx_oob_11:
  br label %list_idx_end_12
list_idx_end_12:
  %t182 = phi i8* [ %t179, %list_idx_ok_10 ], [ null, %list_idx_oob_11 ]
  %t183 = load i8*, i8** %t182
  call void @star_rc_release(i8* %t183)
  %t184 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.18, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t184, i8* %t183)
  %t185 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t74, i32 0, i32 0
  %t186 = load i8**, i8*** %t185
  %t187 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t74, i32 0, i32 1
  %t188 = load i64, i64* %t187
  %t189 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t74, i32 0, i32 2
  %t190 = trunc i64 %t188 to i32
  %t191 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.19, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t191, i32 %t190)
  %t192 = alloca i8*
  %t194 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.20, i64 0, i32 2, i64 0
  %t193 = alloca i8*
  store i8* %t194, i8** %t193
  %t195 = load i8*, i8** %t193
  %t197 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.21, i64 0, i32 2, i64 0
  %t196 = alloca i8*
  store i8* %t197, i8** %t196
  %t198 = load i8*, i8** %t196
  %t199 = call i32 @strlen(i8* %t195)
  %t200 = call i32 @strlen(i8* %t198)
  %t201 = add i32 %t199, %t200
  %t202 = add i32 %t201, 1
  %t203 = sext i32 %t202 to i64
  %t204 = call i8* @star_rc_alloc(i64 %t203, i8* null)
  call i8* @strcpy(i8* %t204, i8* %t195)
  call i8* @strcat(i8* %t204, i8* %t198)
  %t205 = alloca i8*
  store i8* %t204, i8** %t205
  store i8* %t205, i8** %t192
  %t206 = load i8*, i8** %t192
  %t207 = load i8*, i8** %t192
  %t208 = load i8*, i8** %t207
  call void @star_rc_retain(i8* %t208)
  %t209 = call i32 @shout_len(i8* %t206)
  %t210 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t210, i32 %t209)
  %t211 = alloca i32
  store i32 0, i32* %t211
  %t212 = alloca i8*
  %t214 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.23, i64 0, i32 2, i64 0
  %t213 = alloca i8*
  store i8* %t214, i8** %t213
  store i8* %t213, i8** %t212
  br label %while_cond_13
while_cond_13:
  %t215 = load i32, i32* %t211
  %t216 = icmp slt i32 %t215, 5
  br i1 %t216, label %while_body_14, label %while_end_16
while_body_14:
  %t217 = load i8*, i8** %t212
  %t218 = load i8*, i8** %t212
  %t219 = load i8*, i8** %t218
  call void @star_rc_retain(i8* %t219)
  %t220 = load i8*, i8** %t217
  call void @star_rc_release(i8* %t220)
  %t222 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.24, i64 0, i32 2, i64 0
  %t221 = alloca i8*
  store i8* %t222, i8** %t221
  %t223 = load i8*, i8** %t221
  %t224 = call i32 @strlen(i8* %t220)
  %t225 = call i32 @strlen(i8* %t223)
  %t226 = add i32 %t224, %t225
  %t227 = add i32 %t226, 1
  %t228 = sext i32 %t227 to i64
  %t229 = call i8* @star_rc_alloc(i64 %t228, i8* null)
  call i8* @strcpy(i8* %t229, i8* %t220)
  call i8* @strcat(i8* %t229, i8* %t223)
  %t230 = alloca i8*
  store i8* %t229, i8** %t230
  %t231 = load i8*, i8** %t212
  %t232 = load i8*, i8** %t231
  call void @star_rc_release(i8* %t232)
  store i8* %t230, i8** %t212
  %t233 = load i32, i32* %t211
  %t234 = add i32 %t233, 1
  store i32 %t234, i32* %t211
  br label %while_cond_13
while_else_15:
  br label %while_end_16
while_end_16:
  %t235 = load i8*, i8** %t212
  %t236 = load i8*, i8** %t212
  %t237 = load i8*, i8** %t236
  call void @star_rc_retain(i8* %t237)
  %t238 = load i8*, i8** %t235
  call void @star_rc_release(i8* %t238)
  call i32 (i8*, ...) @printf(i8* %t238)
  %t239 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.25, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t239)
  %t240 = load i8*, i8** %t212
  %t241 = load i8*, i8** %t240
  call void @star_rc_release(i8* %t241)
  %t242 = load i8*, i8** %t192
  %t243 = load i8*, i8** %t242
  call void @star_rc_release(i8* %t243)
  %t244 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t74, i32 0, i32 0
  %t245 = load i8**, i8*** %t244
  %t246 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t74, i32 0, i32 1
  %t247 = load i64, i64* %t246
  %t248 = alloca i64
  store i64 0, i64* %t248
  br label %rc_walk_cond_17
rc_walk_cond_17:
  %t249 = load i64, i64* %t248
  %t250 = icmp slt i64 %t249, %t247
  br i1 %t250, label %rc_walk_body_18, label %rc_walk_end_19
rc_walk_body_18:
  %t251 = getelementptr inbounds i8*, i8** %t245, i64 %t249
  %t252 = load i8*, i8** %t251
  %t253 = load i8*, i8** %t252
  call void @star_rc_release(i8* %t253)
  %t254 = add i64 %t249, 1
  store i64 %t254, i64* %t248
  br label %rc_walk_cond_17
rc_walk_end_19:
  %t255 = getelementptr inbounds %Greeting, %Greeting* %t63, i32 0, i32 0
  %t256 = load i8*, i8** %t255
  %t257 = load i8*, i8** %t256
  call void @star_rc_release(i8* %t257)
  %t258 = getelementptr inbounds %Greeting, %Greeting* %t40, i32 0, i32 0
  %t259 = load i8*, i8** %t258
  %t260 = load i8*, i8** %t259
  call void @star_rc_release(i8* %t260)
  %t261 = load i8*, i8** %t0
  %t262 = load i8*, i8** %t261
  call void @star_rc_release(i8* %t262)
  ret i32 0
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
