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
  %t49 = alloca { i8**, i64, i64 }
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
  %t70 = alloca { i8**, i64, i64 }
  %t71 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t70, i32 0, i32 0
  store i8** %t51, i8*** %t71
  %t72 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t70, i32 0, i32 1
  store i64 2, i64* %t72
  %t73 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t70, i32 0, i32 2
  store i64 2, i64* %t73
  %t74 = load { i8**, i64, i64 }, { i8**, i64, i64 }* %t70
  store { i8**, i64, i64 } %t74, { i8**, i64, i64 }* %t49
  %t75 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 0
  %t76 = load i8**, i8*** %t75
  %t77 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 1
  %t78 = load i64, i64* %t77
  %t79 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 2
  %t80 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t81 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t82 = call i32 @strlen(i8* %t80)
  %t83 = call i32 @strlen(i8* %t81)
  %t84 = add i32 %t82, %t83
  %t85 = add i32 %t84, 1
  %t86 = sext i32 %t85 to i64
  %t87 = call i8* @star_rc_alloc(i64 %t86, i8* null)
  call i8* @strcpy(i8* %t87, i8* %t80)
  call i8* @strcat(i8* %t87, i8* %t81)
  %t88 = load i64, i64* %t79
  %t89 = load i8**, i8*** %t75
  %t90 = icmp sge i64 %t78, %t88
  br i1 %t90, label %list_push_grow_0, label %list_push_store_1
list_push_grow_0:
  %t91 = mul i64 %t88, 2
  %t92 = icmp sgt i64 %t91, 0
  %t93 = select i1 %t92, i64 %t91, i64 1
  %t94 = mul i64 %t93, 8
  %t95 = call i8* @malloc(i64 %t94)
  %t96 = bitcast i8* %t95 to i8**
  %t97 = icmp sgt i64 %t88, 0
  br i1 %t97, label %list_push_copy_2, label %list_push_after_copy_3
list_push_copy_2:
  %t98 = mul i64 %t78, 8
  %t99 = bitcast i8** %t89 to i8*
  call i8* @memcpy(i8* %t95, i8* %t99, i64 %t98)
  call void @free(i8* %t99)
  br label %list_push_after_copy_3
list_push_after_copy_3:
  store i8** %t96, i8*** %t75
  store i64 %t93, i64* %t79
  br label %list_push_store_1
list_push_store_1:
  %t100 = load i8**, i8*** %t75
  %t101 = getelementptr inbounds i8*, i8** %t100, i64 %t78
  store i8* %t87, i8** %t101
  %t102 = add i64 %t78, 1
  store i64 %t102, i64* %t77
  %t103 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 0
  %t104 = load i8**, i8*** %t103
  %t105 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 1
  %t106 = load i64, i64* %t105
  %t107 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 2
  %t108 = sext i32 0 to i64
  %t109 = icmp ult i64 %t108, %t106
  br i1 %t109, label %list_idx_ok_4, label %list_idx_oob_5
list_idx_ok_4:
  %t110 = getelementptr inbounds i8*, i8** %t104, i64 %t108
  %t111 = load i8*, i8** %t110
  %t112 = load i8*, i8** %t110
  call void @star_rc_retain(i8* %t112)
  br label %list_idx_end_6
list_idx_oob_5:
  br label %list_idx_end_6
list_idx_end_6:
  %t113 = phi i8* [ %t111, %list_idx_ok_4 ], [ null, %list_idx_oob_5 ]
  call void @star_rc_release(i8* %t113)
  %t114 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t114, i8* %t113)
  %t115 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 0
  %t116 = load i8**, i8*** %t115
  %t117 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 1
  %t118 = load i64, i64* %t117
  %t119 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 2
  %t120 = sext i32 1 to i64
  %t121 = icmp ult i64 %t120, %t118
  br i1 %t121, label %list_idx_ok_7, label %list_idx_oob_8
list_idx_ok_7:
  %t122 = getelementptr inbounds i8*, i8** %t116, i64 %t120
  %t123 = load i8*, i8** %t122
  %t124 = load i8*, i8** %t122
  call void @star_rc_retain(i8* %t124)
  br label %list_idx_end_9
list_idx_oob_8:
  br label %list_idx_end_9
list_idx_end_9:
  %t125 = phi i8* [ %t123, %list_idx_ok_7 ], [ null, %list_idx_oob_8 ]
  call void @star_rc_release(i8* %t125)
  %t126 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t126, i8* %t125)
  %t127 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 0
  %t128 = load i8**, i8*** %t127
  %t129 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 1
  %t130 = load i64, i64* %t129
  %t131 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 2
  %t132 = sext i32 2 to i64
  %t133 = icmp ult i64 %t132, %t130
  br i1 %t133, label %list_idx_ok_10, label %list_idx_oob_11
list_idx_ok_10:
  %t134 = getelementptr inbounds i8*, i8** %t128, i64 %t132
  %t135 = load i8*, i8** %t134
  %t136 = load i8*, i8** %t134
  call void @star_rc_retain(i8* %t136)
  br label %list_idx_end_12
list_idx_oob_11:
  br label %list_idx_end_12
list_idx_end_12:
  %t137 = phi i8* [ %t135, %list_idx_ok_10 ], [ null, %list_idx_oob_11 ]
  call void @star_rc_release(i8* %t137)
  %t138 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.18, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t138, i8* %t137)
  %t139 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 0
  %t140 = load i8**, i8*** %t139
  %t141 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 1
  %t142 = load i64, i64* %t141
  %t143 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 2
  %t144 = trunc i64 %t142 to i32
  %t145 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.19, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t145, i32 %t144)
  %t146 = alloca i8*
  %t147 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.20, i64 0, i32 2, i64 0
  %t148 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.21, i64 0, i32 2, i64 0
  %t149 = call i32 @strlen(i8* %t147)
  %t150 = call i32 @strlen(i8* %t148)
  %t151 = add i32 %t149, %t150
  %t152 = add i32 %t151, 1
  %t153 = sext i32 %t152 to i64
  %t154 = call i8* @star_rc_alloc(i64 %t153, i8* null)
  call i8* @strcpy(i8* %t154, i8* %t147)
  call i8* @strcat(i8* %t154, i8* %t148)
  store i8* %t154, i8** %t146
  %t155 = load i8*, i8** %t146
  %t156 = load i8*, i8** %t146
  call void @star_rc_retain(i8* %t156)
  %t157 = call i32 @shout_len(i8* %t155)
  %t158 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t158, i32 %t157)
  %t159 = alloca i32
  store i32 0, i32* %t159
  %t160 = alloca i8*
  %t161 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.23, i64 0, i32 2, i64 0
  store i8* %t161, i8** %t160
  br label %while_cond_13
while_cond_13:
  %t162 = load i32, i32* %t159
  %t163 = icmp slt i32 %t162, 5
  br i1 %t163, label %while_body_14, label %while_end_16
while_body_14:
  %t164 = load i8*, i8** %t160
  %t165 = load i8*, i8** %t160
  call void @star_rc_retain(i8* %t165)
  call void @star_rc_release(i8* %t164)
  %t166 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.24, i64 0, i32 2, i64 0
  %t167 = call i32 @strlen(i8* %t164)
  %t168 = call i32 @strlen(i8* %t166)
  %t169 = add i32 %t167, %t168
  %t170 = add i32 %t169, 1
  %t171 = sext i32 %t170 to i64
  %t172 = call i8* @star_rc_alloc(i64 %t171, i8* null)
  call i8* @strcpy(i8* %t172, i8* %t164)
  call i8* @strcat(i8* %t172, i8* %t166)
  %t173 = load i8*, i8** %t160
  call void @star_rc_release(i8* %t173)
  store i8* %t172, i8** %t160
  %t174 = load i32, i32* %t159
  %t175 = add i32 %t174, 1
  store i32 %t175, i32* %t159
  br label %while_cond_13
while_else_15:
  br label %while_end_16
while_end_16:
  %t176 = load i8*, i8** %t160
  %t177 = load i8*, i8** %t160
  call void @star_rc_retain(i8* %t177)
  call void @star_rc_release(i8* %t176)
  call i32 (i8*, ...) @printf(i8* %t176)
  %t178 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.25, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t178)
  %t179 = load i8*, i8** %t160
  call void @star_rc_release(i8* %t179)
  %t180 = load i8*, i8** %t146
  call void @star_rc_release(i8* %t180)
  %t181 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 0
  %t182 = load i8**, i8*** %t181
  %t183 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 1
  %t184 = load i64, i64* %t183
  %t185 = alloca i64
  store i64 0, i64* %t185
  br label %rc_walk_cond_17
rc_walk_cond_17:
  %t186 = load i64, i64* %t185
  %t187 = icmp slt i64 %t186, %t184
  br i1 %t187, label %rc_walk_body_18, label %rc_walk_end_19
rc_walk_body_18:
  %t188 = getelementptr inbounds i8*, i8** %t182, i64 %t186
  %t189 = load i8*, i8** %t188
  call void @star_rc_release(i8* %t189)
  %t190 = add i64 %t186, 1
  store i64 %t190, i64* %t185
  br label %rc_walk_cond_17
rc_walk_end_19:
  %t191 = getelementptr inbounds %Greeting, %Greeting* %t41, i32 0, i32 0
  %t192 = load i8*, i8** %t191
  call void @star_rc_release(i8* %t192)
  %t193 = getelementptr inbounds %Greeting, %Greeting* %t25, i32 0, i32 0
  %t194 = load i8*, i8** %t193
  call void @star_rc_release(i8* %t194)
  %t195 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t195)
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
