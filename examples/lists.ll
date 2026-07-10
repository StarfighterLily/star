; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
declare i32 @puts(i8*)
declare noalias i8* @malloc(i64)
declare void @free(i8*)
declare i32 @strlen(i8*)
declare i8* @memcpy(i8*, i8*, i64)
declare i8* @strcpy(i8*, i8*)
declare i8* @strcat(i8*, i8*)
declare i8* @CreateThread(i8*, i64, i8*, i8*, i32, i32*)
declare i32 @WaitForSingleObject(i8*, i32)
declare i32 @CloseHandle(i8*)
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

%Point = type { i32, i32 }
define i32 @sum_list({ i32*, i64, i64 } %nums) {
entry:
  %t0 = alloca { i32*, i64, i64 }
  store { i32*, i64, i64 } %nums, { i32*, i64, i64 }* %t0
  %t1 = alloca i32
  store i32 0, i32* %t1
  %t2 = alloca i32
  store i32 0, i32* %t2
  br label %while_cond_0
while_cond_0:
  %t3 = load i32, i32* %t2
  %t4 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 0
  %t5 = load i32*, i32** %t4
  %t6 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 1
  %t7 = load i64, i64* %t6
  %t8 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 2
  %t9 = trunc i64 %t7 to i32
  %t10 = icmp slt i32 %t3, %t9
  br i1 %t10, label %while_body_1, label %while_end_3
while_body_1:
  %t11 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 0
  %t12 = load i32*, i32** %t11
  %t13 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 1
  %t14 = load i64, i64* %t13
  %t15 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 2
  %t16 = load i32, i32* %t2
  %t17 = sext i32 %t16 to i64
  %t18 = icmp ult i64 %t17, %t14
  br i1 %t18, label %list_idx_ok_4, label %list_idx_oob_5
list_idx_ok_4:
  %t19 = getelementptr inbounds i32, i32* %t12, i64 %t17
  %t20 = load i32, i32* %t19
  br label %list_idx_end_6
list_idx_oob_5:
  br label %list_idx_end_6
list_idx_end_6:
  %t21 = phi i32 [ %t20, %list_idx_ok_4 ], [ 0, %list_idx_oob_5 ]
  %t22 = load i32, i32* %t1
  %t23 = add i32 %t22, %t21
  store i32 %t23, i32* %t1
  %t24 = load i32, i32* %t2
  %t25 = add i32 %t24, 1
  store i32 %t25, i32* %t2
  br label %while_cond_0
while_else_2:
  br label %while_end_3
while_end_3:
  %t26 = load i32, i32* %t1
  ret i32 %t26
}

define void @main() {
entry:
  %t0 = alloca { i32*, i64, i64 }
  %t1 = call i8* @malloc(i64 12)
  %t2 = bitcast i8* %t1 to i32*
  %t3 = getelementptr inbounds i32, i32* %t2, i64 0
  store i32 1, i32* %t3
  %t4 = getelementptr inbounds i32, i32* %t2, i64 1
  store i32 2, i32* %t4
  %t5 = getelementptr inbounds i32, i32* %t2, i64 2
  store i32 3, i32* %t5
  %t6 = alloca { i32*, i64, i64 }
  %t7 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t6, i32 0, i32 0
  store i32* %t2, i32** %t7
  %t8 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t6, i32 0, i32 1
  store i64 3, i64* %t8
  %t9 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t6, i32 0, i32 2
  store i64 3, i64* %t9
  %t10 = load { i32*, i64, i64 }, { i32*, i64, i64 }* %t6
  store { i32*, i64, i64 } %t10, { i32*, i64, i64 }* %t0
  %t11 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 0
  %t12 = load i32*, i32** %t11
  %t13 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 1
  %t14 = load i64, i64* %t13
  %t15 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 2
  %t16 = trunc i64 %t14 to i32
  %t17 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t17, i32 %t16)
  %t18 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 0
  %t19 = load i32*, i32** %t18
  %t20 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 1
  %t21 = load i64, i64* %t20
  %t22 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 2
  %t23 = load i64, i64* %t22
  %t24 = load i32*, i32** %t18
  %t25 = icmp sge i64 %t21, %t23
  br i1 %t25, label %list_push_grow_7, label %list_push_store_8
list_push_grow_7:
  %t26 = mul i64 %t23, 2
  %t27 = icmp sgt i64 %t26, 0
  %t28 = select i1 %t27, i64 %t26, i64 1
  %t29 = mul i64 %t28, 4
  %t30 = call i8* @malloc(i64 %t29)
  %t31 = bitcast i8* %t30 to i32*
  %t32 = icmp sgt i64 %t23, 0
  br i1 %t32, label %list_push_copy_9, label %list_push_after_copy_10
list_push_copy_9:
  %t33 = mul i64 %t21, 4
  %t34 = bitcast i32* %t24 to i8*
  call i8* @memcpy(i8* %t30, i8* %t34, i64 %t33)
  call void @free(i8* %t34)
  br label %list_push_after_copy_10
list_push_after_copy_10:
  store i32* %t31, i32** %t18
  store i64 %t28, i64* %t22
  br label %list_push_store_8
list_push_store_8:
  %t35 = load i32*, i32** %t18
  %t36 = getelementptr inbounds i32, i32* %t35, i64 %t21
  store i32 4, i32* %t36
  %t37 = add i64 %t21, 1
  store i64 %t37, i64* %t20
  %t38 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 0
  %t39 = load i32*, i32** %t38
  %t40 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 1
  %t41 = load i64, i64* %t40
  %t42 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 2
  %t43 = load i64, i64* %t42
  %t44 = load i32*, i32** %t38
  %t45 = icmp sge i64 %t41, %t43
  br i1 %t45, label %list_push_grow_11, label %list_push_store_12
list_push_grow_11:
  %t46 = mul i64 %t43, 2
  %t47 = icmp sgt i64 %t46, 0
  %t48 = select i1 %t47, i64 %t46, i64 1
  %t49 = mul i64 %t48, 4
  %t50 = call i8* @malloc(i64 %t49)
  %t51 = bitcast i8* %t50 to i32*
  %t52 = icmp sgt i64 %t43, 0
  br i1 %t52, label %list_push_copy_13, label %list_push_after_copy_14
list_push_copy_13:
  %t53 = mul i64 %t41, 4
  %t54 = bitcast i32* %t44 to i8*
  call i8* @memcpy(i8* %t50, i8* %t54, i64 %t53)
  call void @free(i8* %t54)
  br label %list_push_after_copy_14
list_push_after_copy_14:
  store i32* %t51, i32** %t38
  store i64 %t48, i64* %t42
  br label %list_push_store_12
list_push_store_12:
  %t55 = load i32*, i32** %t38
  %t56 = getelementptr inbounds i32, i32* %t55, i64 %t41
  store i32 5, i32* %t56
  %t57 = add i64 %t41, 1
  store i64 %t57, i64* %t40
  %t58 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 0
  %t59 = load i32*, i32** %t58
  %t60 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 1
  %t61 = load i64, i64* %t60
  %t62 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 2
  %t63 = trunc i64 %t61 to i32
  %t64 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t64, i32 %t63)
  %t65 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 0
  %t66 = load i32*, i32** %t65
  %t67 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 1
  %t68 = load i64, i64* %t67
  %t69 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 2
  %t70 = trunc i64 %t68 to i32
  %t71 = alloca i32
  store i32 0, i32* %t71
  br label %for_cond_15
for_cond_15:
  %t72 = load i32, i32* %t71
  %t73 = icmp slt i32 %t72, %t70
  br i1 %t73, label %for_body_16, label %for_end_18
for_body_16:
  %t74 = load i32, i32* %t71
  %t75 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 0
  %t76 = load i32*, i32** %t75
  %t77 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 1
  %t78 = load i64, i64* %t77
  %t79 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 2
  %t80 = load i32, i32* %t71
  %t81 = sext i32 %t80 to i64
  %t82 = icmp ult i64 %t81, %t78
  br i1 %t82, label %list_idx_ok_19, label %list_idx_oob_20
list_idx_ok_19:
  %t83 = getelementptr inbounds i32, i32* %t76, i64 %t81
  %t84 = load i32, i32* %t83
  br label %list_idx_end_21
list_idx_oob_20:
  br label %list_idx_end_21
list_idx_end_21:
  %t85 = phi i32 [ %t84, %list_idx_ok_19 ], [ 0, %list_idx_oob_20 ]
  %t86 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t86, i32 %t74, i32 %t85)
  br label %for_step_17
for_step_17:
  %t87 = load i32, i32* %t71
  %t88 = add i32 %t87, 1
  store i32 %t88, i32* %t71
  br label %for_cond_15
for_end_18:
  %t89 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 0
  %t90 = load i32*, i32** %t89
  %t91 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 1
  %t92 = load i64, i64* %t91
  %t93 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 2
  %t94 = sext i32 0 to i64
  %t95 = icmp ult i64 %t94, %t92
  br i1 %t95, label %list_set_do_22, label %list_set_end_23
list_set_do_22:
  %t96 = getelementptr inbounds i32, i32* %t90, i64 %t94
  store i32 100, i32* %t96
  br label %list_set_end_23
list_set_end_23:
  %t97 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 0
  %t98 = load i32*, i32** %t97
  %t99 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 1
  %t100 = load i64, i64* %t99
  %t101 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 2
  %t102 = sext i32 0 to i64
  %t103 = icmp ult i64 %t102, %t100
  br i1 %t103, label %list_idx_ok_24, label %list_idx_oob_25
list_idx_ok_24:
  %t104 = getelementptr inbounds i32, i32* %t98, i64 %t102
  %t105 = load i32, i32* %t104
  br label %list_idx_end_26
list_idx_oob_25:
  br label %list_idx_end_26
list_idx_end_26:
  %t106 = phi i32 [ %t105, %list_idx_ok_24 ], [ 0, %list_idx_oob_25 ]
  %t107 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t107, i32 %t106)
  %t108 = alloca i32
  %t109 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 0
  %t110 = load i32*, i32** %t109
  %t111 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 1
  %t112 = load i64, i64* %t111
  %t113 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 2
  %t114 = icmp eq i64 %t112, 0
  br i1 %t114, label %list_pop_empty_27, label %list_pop_nonempty_28
list_pop_nonempty_28:
  %t115 = sub i64 %t112, 1
  store i64 %t115, i64* %t111
  %t116 = load i32*, i32** %t109
  %t117 = getelementptr inbounds i32, i32* %t116, i64 %t115
  %t118 = load i32, i32* %t117
  br label %list_pop_end_29
list_pop_empty_27:
  br label %list_pop_end_29
list_pop_end_29:
  %t119 = phi i32 [ %t118, %list_pop_nonempty_28 ], [ 0, %list_pop_empty_27 ]
  store i32 %t119, i32* %t108
  %t120 = load i32, i32* %t108
  %t121 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t121, i32 %t120)
  %t122 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 0
  %t123 = load i32*, i32** %t122
  %t124 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 1
  %t125 = load i64, i64* %t124
  %t126 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t0, i32 0, i32 2
  %t127 = trunc i64 %t125 to i32
  %t128 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t128, i32 %t127)
  %t129 = load { i32*, i64, i64 }, { i32*, i64, i64 }* %t0
  %t130 = call i32 @sum_list({ i32*, i64, i64 } %t129)
  %t131 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t131, i32 %t130)
  %t132 = alloca { i32*, i64, i64 }
  store { i32*, i64, i64 } zeroinitializer, { i32*, i64, i64 }* %t132
  %t133 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t132, i32 0, i32 0
  %t134 = load i32*, i32** %t133
  %t135 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t132, i32 0, i32 1
  %t136 = load i64, i64* %t135
  %t137 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t132, i32 0, i32 2
  %t138 = trunc i64 %t136 to i32
  %t139 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t139, i32 %t138)
  %t140 = alloca i32
  %t141 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t132, i32 0, i32 0
  %t142 = load i32*, i32** %t141
  %t143 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t132, i32 0, i32 1
  %t144 = load i64, i64* %t143
  %t145 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t132, i32 0, i32 2
  %t146 = icmp eq i64 %t144, 0
  br i1 %t146, label %list_pop_empty_30, label %list_pop_nonempty_31
list_pop_nonempty_31:
  %t147 = sub i64 %t144, 1
  store i64 %t147, i64* %t143
  %t148 = load i32*, i32** %t141
  %t149 = getelementptr inbounds i32, i32* %t148, i64 %t147
  %t150 = load i32, i32* %t149
  br label %list_pop_end_32
list_pop_empty_30:
  br label %list_pop_end_32
list_pop_end_32:
  %t151 = phi i32 [ %t150, %list_pop_nonempty_31 ], [ 0, %list_pop_empty_30 ]
  store i32 %t151, i32* %t140
  %t152 = load i32, i32* %t140
  %t153 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t153, i32 %t152)
  %t154 = alloca i32
  %t155 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t132, i32 0, i32 0
  %t156 = load i32*, i32** %t155
  %t157 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t132, i32 0, i32 1
  %t158 = load i64, i64* %t157
  %t159 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t132, i32 0, i32 2
  %t160 = sext i32 0 to i64
  %t161 = icmp ult i64 %t160, %t158
  br i1 %t161, label %list_idx_ok_33, label %list_idx_oob_34
list_idx_ok_33:
  %t162 = getelementptr inbounds i32, i32* %t156, i64 %t160
  %t163 = load i32, i32* %t162
  br label %list_idx_end_35
list_idx_oob_34:
  br label %list_idx_end_35
list_idx_end_35:
  %t164 = phi i32 [ %t163, %list_idx_ok_33 ], [ 0, %list_idx_oob_34 ]
  store i32 %t164, i32* %t154
  %t165 = load i32, i32* %t154
  %t166 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t166, i32 %t165)
  %t167 = alloca { i32*, i64, i64 }
  store { i32*, i64, i64 } zeroinitializer, { i32*, i64, i64 }* %t167
  %t168 = alloca i32
  store i32 0, i32* %t168
  br label %while_cond_36
while_cond_36:
  %t169 = load i32, i32* %t168
  %t170 = icmp slt i32 %t169, 20
  br i1 %t170, label %while_body_37, label %while_end_39
while_body_37:
  %t171 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t167, i32 0, i32 0
  %t172 = load i32*, i32** %t171
  %t173 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t167, i32 0, i32 1
  %t174 = load i64, i64* %t173
  %t175 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t167, i32 0, i32 2
  %t176 = load i32, i32* %t168
  %t177 = load i64, i64* %t175
  %t178 = load i32*, i32** %t171
  %t179 = icmp sge i64 %t174, %t177
  br i1 %t179, label %list_push_grow_40, label %list_push_store_41
list_push_grow_40:
  %t180 = mul i64 %t177, 2
  %t181 = icmp sgt i64 %t180, 0
  %t182 = select i1 %t181, i64 %t180, i64 1
  %t183 = mul i64 %t182, 4
  %t184 = call i8* @malloc(i64 %t183)
  %t185 = bitcast i8* %t184 to i32*
  %t186 = icmp sgt i64 %t177, 0
  br i1 %t186, label %list_push_copy_42, label %list_push_after_copy_43
list_push_copy_42:
  %t187 = mul i64 %t174, 4
  %t188 = bitcast i32* %t178 to i8*
  call i8* @memcpy(i8* %t184, i8* %t188, i64 %t187)
  call void @free(i8* %t188)
  br label %list_push_after_copy_43
list_push_after_copy_43:
  store i32* %t185, i32** %t171
  store i64 %t182, i64* %t175
  br label %list_push_store_41
list_push_store_41:
  %t189 = load i32*, i32** %t171
  %t190 = getelementptr inbounds i32, i32* %t189, i64 %t174
  store i32 %t176, i32* %t190
  %t191 = add i64 %t174, 1
  store i64 %t191, i64* %t173
  %t192 = load i32, i32* %t168
  %t193 = add i32 %t192, 1
  store i32 %t193, i32* %t168
  br label %while_cond_36
while_else_38:
  br label %while_end_39
while_end_39:
  %t194 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t167, i32 0, i32 0
  %t195 = load i32*, i32** %t194
  %t196 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t167, i32 0, i32 1
  %t197 = load i64, i64* %t196
  %t198 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t167, i32 0, i32 2
  %t199 = trunc i64 %t197 to i32
  %t200 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t200, i32 %t199)
  %t201 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t167, i32 0, i32 0
  %t202 = load i32*, i32** %t201
  %t203 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t167, i32 0, i32 1
  %t204 = load i64, i64* %t203
  %t205 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t167, i32 0, i32 2
  %t206 = sext i32 19 to i64
  %t207 = icmp ult i64 %t206, %t204
  br i1 %t207, label %list_idx_ok_44, label %list_idx_oob_45
list_idx_ok_44:
  %t208 = getelementptr inbounds i32, i32* %t202, i64 %t206
  %t209 = load i32, i32* %t208
  br label %list_idx_end_46
list_idx_oob_45:
  br label %list_idx_end_46
list_idx_end_46:
  %t210 = phi i32 [ %t209, %list_idx_ok_44 ], [ 0, %list_idx_oob_45 ]
  %t211 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t211, i32 %t210)
  %t212 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t167, i32 0, i32 0
  %t213 = load i32*, i32** %t212
  %t214 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t167, i32 0, i32 1
  %t215 = load i64, i64* %t214
  %t216 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t167, i32 0, i32 2
  %t217 = sext i32 0 to i64
  %t218 = icmp ult i64 %t217, %t215
  br i1 %t218, label %list_idx_ok_47, label %list_idx_oob_48
list_idx_ok_47:
  %t219 = getelementptr inbounds i32, i32* %t213, i64 %t217
  %t220 = load i32, i32* %t219
  br label %list_idx_end_49
list_idx_oob_48:
  br label %list_idx_end_49
list_idx_end_49:
  %t221 = phi i32 [ %t220, %list_idx_ok_47 ], [ 0, %list_idx_oob_48 ]
  %t222 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t222, i32 %t221)
  %t223 = alloca { i8**, i64, i64 }
  %t224 = call i8* @malloc(i64 24)
  %t225 = bitcast i8* %t224 to i8**
  %t227 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.13, i64 0, i64 0
  %t226 = alloca i8*
  store i8* %t227, i8** %t226
  %t228 = getelementptr inbounds i8*, i8** %t225, i64 0
  store i8* %t226, i8** %t228
  %t230 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.14, i64 0, i64 0
  %t229 = alloca i8*
  store i8* %t230, i8** %t229
  %t231 = getelementptr inbounds i8*, i8** %t225, i64 1
  store i8* %t229, i8** %t231
  %t233 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.15, i64 0, i64 0
  %t232 = alloca i8*
  store i8* %t233, i8** %t232
  %t234 = getelementptr inbounds i8*, i8** %t225, i64 2
  store i8* %t232, i8** %t234
  %t235 = alloca { i8**, i64, i64 }
  %t236 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t235, i32 0, i32 0
  store i8** %t225, i8*** %t236
  %t237 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t235, i32 0, i32 1
  store i64 3, i64* %t237
  %t238 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t235, i32 0, i32 2
  store i64 3, i64* %t238
  %t239 = load { i8**, i64, i64 }, { i8**, i64, i64 }* %t235
  store { i8**, i64, i64 } %t239, { i8**, i64, i64 }* %t223
  %t240 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t223, i32 0, i32 0
  %t241 = load i8**, i8*** %t240
  %t242 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t223, i32 0, i32 1
  %t243 = load i64, i64* %t242
  %t244 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t223, i32 0, i32 2
  %t245 = trunc i64 %t243 to i32
  %t246 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t246, i32 %t245)
  %t247 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t223, i32 0, i32 0
  %t248 = load i8**, i8*** %t247
  %t249 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t223, i32 0, i32 1
  %t250 = load i64, i64* %t249
  %t251 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t223, i32 0, i32 2
  %t252 = sext i32 1 to i64
  %t253 = icmp ult i64 %t252, %t250
  br i1 %t253, label %list_idx_ok_50, label %list_idx_oob_51
list_idx_ok_50:
  %t254 = getelementptr inbounds i8*, i8** %t248, i64 %t252
  %t255 = load i8*, i8** %t254
  br label %list_idx_end_52
list_idx_oob_51:
  br label %list_idx_end_52
list_idx_end_52:
  %t256 = phi i8* [ %t255, %list_idx_ok_50 ], [ null, %list_idx_oob_51 ]
  %t257 = load i8*, i8** %t256
  %t258 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t258, i8* %t257)
  %t259 = alloca { %Point*, i64, i64 }
  %t260 = call i8* @malloc(i64 16)
  %t261 = bitcast i8* %t260 to %Point*
  %t262 = alloca %Point
  %t263 = getelementptr inbounds %Point, %Point* %t262, i32 0, i32 0
  store i32 1, i32* %t263
  %t264 = getelementptr inbounds %Point, %Point* %t262, i32 0, i32 1
  store i32 2, i32* %t264
  %t265 = load %Point, %Point* %t262
  %t266 = getelementptr inbounds %Point, %Point* %t261, i64 0
  store %Point %t265, %Point* %t266
  %t267 = alloca %Point
  %t268 = getelementptr inbounds %Point, %Point* %t267, i32 0, i32 0
  store i32 3, i32* %t268
  %t269 = getelementptr inbounds %Point, %Point* %t267, i32 0, i32 1
  store i32 4, i32* %t269
  %t270 = load %Point, %Point* %t267
  %t271 = getelementptr inbounds %Point, %Point* %t261, i64 1
  store %Point %t270, %Point* %t271
  %t272 = alloca { %Point*, i64, i64 }
  %t273 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t272, i32 0, i32 0
  store %Point* %t261, %Point** %t273
  %t274 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t272, i32 0, i32 1
  store i64 2, i64* %t274
  %t275 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t272, i32 0, i32 2
  store i64 2, i64* %t275
  %t276 = load { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t272
  store { %Point*, i64, i64 } %t276, { %Point*, i64, i64 }* %t259
  %t277 = alloca %Point
  %t278 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t259, i32 0, i32 0
  %t279 = load %Point*, %Point** %t278
  %t280 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t259, i32 0, i32 1
  %t281 = load i64, i64* %t280
  %t282 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t259, i32 0, i32 2
  %t283 = sext i32 1 to i64
  %t284 = icmp ult i64 %t283, %t281
  br i1 %t284, label %list_idx_ok_53, label %list_idx_oob_54
list_idx_ok_53:
  %t285 = getelementptr inbounds %Point, %Point* %t279, i64 %t283
  %t286 = load %Point, %Point* %t285
  br label %list_idx_end_55
list_idx_oob_54:
  br label %list_idx_end_55
list_idx_end_55:
  %t287 = phi %Point [ %t286, %list_idx_ok_53 ], [ zeroinitializer, %list_idx_oob_54 ]
  store %Point %t287, %Point* %t277
  %t288 = getelementptr inbounds %Point, %Point* %t277, i32 0, i32 0
  %t289 = load i32, i32* %t288
  %t290 = getelementptr inbounds %Point, %Point* %t277, i32 0, i32 1
  %t291 = load i32, i32* %t290
  %t292 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.18, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t292, i32 %t289, i32 %t291)
  ret void
}


; Global Constants
@.str.0 = private unnamed_addr constant [18 x i8] c"initial len = %d\0A\00"
@.str.1 = private unnamed_addr constant [21 x i8] c"after push len = %d\0A\00"
@.str.2 = private unnamed_addr constant [15 x i8] c"nums[%d] = %d\0A\00"
@.str.3 = private unnamed_addr constant [24 x i8] c"nums[0] after set = %d\0A\00"
@.str.4 = private unnamed_addr constant [13 x i8] c"popped = %d\0A\00"
@.str.5 = private unnamed_addr constant [20 x i8] c"len after pop = %d\0A\00"
@.str.6 = private unnamed_addr constant [23 x i8] c"sum via function = %d\0A\00"
@.str.7 = private unnamed_addr constant [16 x i8] c"empty len = %d\0A\00"
@.str.8 = private unnamed_addr constant [21 x i8] c"pop from empty = %d\0A\00"
@.str.9 = private unnamed_addr constant [16 x i8] c"index oob = %d\0A\00"
@.str.10 = private unnamed_addr constant [16 x i8] c"grown len = %d\0A\00"
@.str.11 = private unnamed_addr constant [16 x i8] c"grown[19] = %d\0A\00"
@.str.12 = private unnamed_addr constant [15 x i8] c"grown[0] = %d\0A\00"
@.str.13 = private unnamed_addr constant [6 x i8] c"alpha\00"
@.str.14 = private unnamed_addr constant [5 x i8] c"beta\00"
@.str.15 = private unnamed_addr constant [6 x i8] c"gamma\00"
@.str.16 = private unnamed_addr constant [16 x i8] c"words len = %d\0A\00"
@.str.17 = private unnamed_addr constant [15 x i8] c"words[1] = %s\0A\00"
@.str.18 = private unnamed_addr constant [22 x i8] c"points[1] = (%d, %d)\0A\00"
