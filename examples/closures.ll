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

define i32 @apply_twice({ i8*, i8* } %f, i32 %x) {
entry:
  %t0 = alloca { i8*, i8* }
  store { i8*, i8* } %f, { i8*, i8* }* %t0
  %t1 = alloca i32
  store i32 %x, i32* %t1
  %t2 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t3 = extractvalue { i8*, i8* } %t2, 0
  %t4 = extractvalue { i8*, i8* } %t2, 1
  %t5 = bitcast i8* %t3 to i32 (i8*, i32)*
  %t6 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t7 = extractvalue { i8*, i8* } %t6, 0
  %t8 = extractvalue { i8*, i8* } %t6, 1
  %t9 = bitcast i8* %t7 to i32 (i8*, i32)*
  %t10 = load i32, i32* %t1
  %t11 = call i32 %t9(i8* %t8, i32 %t10)
  %t12 = call i32 %t5(i8* %t4, i32 %t11)
  ret i32 %t12
}

define i32 @add_one(i32 %x) {
entry:
  %t0 = alloca i32
  store i32 %x, i32* %t0
  %t1 = load i32, i32* %t0
  %t2 = add i32 %t1, 1
  ret i32 %t2
}

define { i8*, i8* } @make_adder(i32 %n) {
entry:
  %t0 = alloca i32
  store i32 %n, i32* %t0
  %t9 = getelementptr inbounds { i32 }, { i32 }* null, i32 1
  %t10 = ptrtoint { i32 }* %t9 to i64
  %t11 = call i8* @malloc(i64 %t10)
  %t12 = bitcast i8* %t11 to { i32 }*
  %t13 = load i32, i32* %t0
  %t14 = getelementptr inbounds { i32 }, { i32 }* %t12, i32 0, i32 0
  store i32 %t13, i32* %t14
  %t15 = bitcast i32 (i8*, i32)* @closure_0 to i8*
  %t16 = insertvalue { i8*, i8* } undef, i8* %t15, 0
  %t17 = insertvalue { i8*, i8* } %t16, i8* %t11, 1
  ret { i8*, i8* } %t17
}

define i32 @main() {
entry:
  %t0 = alloca { i8*, i8* }
  %t4 = bitcast i32 (i8*, i32)* @closure_1 to i8*
  %t5 = insertvalue { i8*, i8* } undef, i8* %t4, 0
  %t6 = insertvalue { i8*, i8* } %t5, i8* null, 1
  store { i8*, i8* } %t6, { i8*, i8* }* %t0
  %t7 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t8 = extractvalue { i8*, i8* } %t7, 0
  %t9 = extractvalue { i8*, i8* } %t7, 1
  %t10 = bitcast i8* %t8 to i32 (i8*, i32)*
  %t11 = call i32 %t10(i8* %t9, i32 5)
  %t12 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t12, i32 %t11)
  %t13 = alloca i32
  store i32 10, i32* %t13
  %t14 = alloca { i8*, i8* }
  %t26 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* null, i32 1
  %t27 = ptrtoint { { i8*, i8* }, i32 }* %t26 to i64
  %t28 = call i8* @malloc(i64 %t27)
  %t29 = bitcast i8* %t28 to { { i8*, i8* }, i32 }*
  %t30 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t31 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t29, i32 0, i32 0
  store { i8*, i8* } %t30, { i8*, i8* }* %t31
  %t32 = load i32, i32* %t13
  %t33 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t29, i32 0, i32 1
  store i32 %t32, i32* %t33
  %t34 = bitcast i32 (i8*, i32)* @closure_2 to i8*
  %t35 = insertvalue { i8*, i8* } undef, i8* %t34, 0
  %t36 = insertvalue { i8*, i8* } %t35, i8* %t28, 1
  store { i8*, i8* } %t36, { i8*, i8* }* %t14
  %t37 = load { i8*, i8* }, { i8*, i8* }* %t14
  %t38 = extractvalue { i8*, i8* } %t37, 0
  %t39 = extractvalue { i8*, i8* } %t37, 1
  %t40 = bitcast i8* %t38 to i32 (i8*, i32)*
  %t41 = call i32 %t40(i8* %t39, i32 7)
  %t42 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t42, i32 %t41)
  %t43 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t44 = call i32 @apply_twice({ i8*, i8* } %t43, i32 5)
  %t45 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t45, i32 %t44)
  %t46 = call i32 @add_one(i32 5)
  %t47 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t47, i32 %t46)
  %t49 = bitcast i32 (i8*, i32)* @fnval_add_one to i8*
  %t50 = insertvalue { i8*, i8* } undef, i8* %t49, 0
  %t51 = insertvalue { i8*, i8* } %t50, i8* null, 1
  %t52 = call i32 @apply_twice({ i8*, i8* } %t51, i32 5)
  %t53 = getelementptr inbounds [30 x i8], [30 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t53, i32 %t52)
  %t54 = alloca { i8*, i8* }
  %t55 = call { i8*, i8* } @make_adder(i32 100)
  store { i8*, i8* } %t55, { i8*, i8* }* %t54
  %t56 = load { i8*, i8* }, { i8*, i8* }* %t54
  %t57 = extractvalue { i8*, i8* } %t56, 0
  %t58 = extractvalue { i8*, i8* } %t56, 1
  %t59 = bitcast i8* %t57 to i32 (i8*, i32)*
  %t60 = call i32 %t59(i8* %t58, i32 5)
  %t61 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t61, i32 %t60)
  %t62 = alloca i32
  store i32 0, i32* %t62
  %t63 = alloca { i8*, i8* }
  %t82 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* null, i32 1
  %t83 = ptrtoint { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t82 to i64
  %t84 = call i8* @malloc(i64 %t83)
  %t85 = bitcast i8* %t84 to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }*
  %t86 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t87 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t85, i32 0, i32 0
  store { i8*, i8* } %t86, { i8*, i8* }* %t87
  %t88 = load i32, i32* %t13
  %t89 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t85, i32 0, i32 1
  store i32 %t88, i32* %t89
  %t90 = load { i8*, i8* }, { i8*, i8* }* %t14
  %t91 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t85, i32 0, i32 2
  store { i8*, i8* } %t90, { i8*, i8* }* %t91
  %t92 = load { i8*, i8* }, { i8*, i8* }* %t54
  %t93 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t85, i32 0, i32 3
  store { i8*, i8* } %t92, { i8*, i8* }* %t93
  %t94 = load i32, i32* %t62
  %t95 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t85, i32 0, i32 4
  store i32 %t94, i32* %t95
  %t96 = bitcast i32 (i8*)* @closure_3 to i8*
  %t97 = insertvalue { i8*, i8* } undef, i8* %t96, 0
  %t98 = insertvalue { i8*, i8* } %t97, i8* %t84, 1
  store { i8*, i8* } %t98, { i8*, i8* }* %t63
  store i32 50, i32* %t62
  %t99 = load { i8*, i8* }, { i8*, i8* }* %t63
  %t100 = extractvalue { i8*, i8* } %t99, 0
  %t101 = extractvalue { i8*, i8* } %t99, 1
  %t102 = bitcast i8* %t100 to i32 (i8*)*
  %t103 = call i32 %t102(i8* %t101)
  %t104 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t104, i32 %t103)
  %t105 = alloca { i8*, i8* }
  %t129 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* null, i32 1
  %t130 = ptrtoint { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t129 to i64
  %t131 = call i8* @malloc(i64 %t130)
  %t132 = bitcast i8* %t131 to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }*
  %t133 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t134 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t132, i32 0, i32 0
  store { i8*, i8* } %t133, { i8*, i8* }* %t134
  %t135 = load i32, i32* %t13
  %t136 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t132, i32 0, i32 1
  store i32 %t135, i32* %t136
  %t137 = load { i8*, i8* }, { i8*, i8* }* %t14
  %t138 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t132, i32 0, i32 2
  store { i8*, i8* } %t137, { i8*, i8* }* %t138
  %t139 = load { i8*, i8* }, { i8*, i8* }* %t54
  %t140 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t132, i32 0, i32 3
  store { i8*, i8* } %t139, { i8*, i8* }* %t140
  %t141 = load i32, i32* %t62
  %t142 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t132, i32 0, i32 4
  store i32 %t141, i32* %t142
  %t143 = load { i8*, i8* }, { i8*, i8* }* %t63
  %t144 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t132, i32 0, i32 5
  store { i8*, i8* } %t143, { i8*, i8* }* %t144
  %t145 = bitcast void (i8*)* @closure_4 to i8*
  %t146 = insertvalue { i8*, i8* } undef, i8* %t145, 0
  %t147 = insertvalue { i8*, i8* } %t146, i8* %t131, 1
  store { i8*, i8* } %t147, { i8*, i8* }* %t105
  %t148 = load { i8*, i8* }, { i8*, i8* }* %t105
  %t149 = extractvalue { i8*, i8* } %t148, 0
  %t150 = extractvalue { i8*, i8* } %t148, 1
  %t151 = bitcast i8* %t149 to void (i8*)*
  call void %t151(i8* %t150)
  ret i32 0
}


; par/swarm worker functions
define i32 @closure_0(i8* %envp, i32 %arg_x) {
entry:
  %t1 = bitcast i8* %envp to { i32 }*
  %t2 = getelementptr inbounds { i32 }, { i32 }* %t1, i32 0, i32 0
  %t3 = load i32, i32* %t2
  %t4 = alloca i32
  store i32 %t3, i32* %t4
  %t5 = alloca i32
  store i32 %arg_x, i32* %t5
  %t6 = load i32, i32* %t5
  %t7 = load i32, i32* %t4
  %t8 = add i32 %t6, %t7
  ret i32 %t8
}


define i32 @closure_1(i8* %envp, i32 %arg_x) {
entry:
  %t1 = alloca i32
  store i32 %arg_x, i32* %t1
  %t2 = load i32, i32* %t1
  %t3 = add i32 %t2, 1
  ret i32 %t3
}


define i32 @closure_2(i8* %envp, i32 %arg_x) {
entry:
  %t15 = bitcast i8* %envp to { { i8*, i8* }, i32 }*
  %t16 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t15, i32 0, i32 0
  %t17 = load { i8*, i8* }, { i8*, i8* }* %t16
  %t18 = alloca { i8*, i8* }
  store { i8*, i8* } %t17, { i8*, i8* }* %t18
  %t19 = getelementptr inbounds { { i8*, i8* }, i32 }, { { i8*, i8* }, i32 }* %t15, i32 0, i32 1
  %t20 = load i32, i32* %t19
  %t21 = alloca i32
  store i32 %t20, i32* %t21
  %t22 = alloca i32
  store i32 %arg_x, i32* %t22
  %t23 = load i32, i32* %t22
  %t24 = load i32, i32* %t21
  %t25 = add i32 %t23, %t24
  ret i32 %t25
}


define i32 @fnval_add_one(i8* %envp, i32 %arg_0) {
entry:
  %t48 = call i32 @add_one(i32 %arg_0)
  ret i32 %t48
}


define i32 @closure_3(i8* %envp) {
entry:
  %t64 = bitcast i8* %envp to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }*
  %t65 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t64, i32 0, i32 0
  %t66 = load { i8*, i8* }, { i8*, i8* }* %t65
  %t67 = alloca { i8*, i8* }
  store { i8*, i8* } %t66, { i8*, i8* }* %t67
  %t68 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t64, i32 0, i32 1
  %t69 = load i32, i32* %t68
  %t70 = alloca i32
  store i32 %t69, i32* %t70
  %t71 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t64, i32 0, i32 2
  %t72 = load { i8*, i8* }, { i8*, i8* }* %t71
  %t73 = alloca { i8*, i8* }
  store { i8*, i8* } %t72, { i8*, i8* }* %t73
  %t74 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t64, i32 0, i32 3
  %t75 = load { i8*, i8* }, { i8*, i8* }* %t74
  %t76 = alloca { i8*, i8* }
  store { i8*, i8* } %t75, { i8*, i8* }* %t76
  %t77 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32 }* %t64, i32 0, i32 4
  %t78 = load i32, i32* %t77
  %t79 = alloca i32
  store i32 %t78, i32* %t79
  %t80 = load i32, i32* %t79
  %t81 = add i32 %t80, 1
  ret i32 %t81
}


define void @closure_4(i8* %envp) {
entry:
  %t106 = bitcast i8* %envp to { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }*
  %t107 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t106, i32 0, i32 0
  %t108 = load { i8*, i8* }, { i8*, i8* }* %t107
  %t109 = alloca { i8*, i8* }
  store { i8*, i8* } %t108, { i8*, i8* }* %t109
  %t110 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t106, i32 0, i32 1
  %t111 = load i32, i32* %t110
  %t112 = alloca i32
  store i32 %t111, i32* %t112
  %t113 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t106, i32 0, i32 2
  %t114 = load { i8*, i8* }, { i8*, i8* }* %t113
  %t115 = alloca { i8*, i8* }
  store { i8*, i8* } %t114, { i8*, i8* }* %t115
  %t116 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t106, i32 0, i32 3
  %t117 = load { i8*, i8* }, { i8*, i8* }* %t116
  %t118 = alloca { i8*, i8* }
  store { i8*, i8* } %t117, { i8*, i8* }* %t118
  %t119 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t106, i32 0, i32 4
  %t120 = load i32, i32* %t119
  %t121 = alloca i32
  store i32 %t120, i32* %t121
  %t122 = getelementptr inbounds { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }, { { i8*, i8* }, i32, { i8*, i8* }, { i8*, i8* }, i32, { i8*, i8* } }* %t106, i32 0, i32 5
  %t123 = load { i8*, i8* }, { i8*, i8* }* %t122
  %t124 = alloca { i8*, i8* }
  store { i8*, i8* } %t123, { i8*, i8* }* %t124
  %t126 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.7, i64 0, i64 0
  %t125 = alloca i8*
  store i8* %t126, i8** %t125
  %t127 = load i8*, i8** %t125
  call i32 (i8*, ...) @printf(i8* %t127)
  %t128 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t128)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant [14 x i8] c"add1(5) = %d\0A\00"
@.str.1 = private unnamed_addr constant [18 x i8] c"add_base(7) = %d\0A\00"
@.str.2 = private unnamed_addr constant [27 x i8] c"apply_twice(add1, 5) = %d\0A\00"
@.str.3 = private unnamed_addr constant [17 x i8] c"add_one(5) = %d\0A\00"
@.str.4 = private unnamed_addr constant [30 x i8] c"apply_twice(add_one, 5) = %d\0A\00"
@.str.5 = private unnamed_addr constant [15 x i8] c"adder(5) = %d\0A\00"
@.str.6 = private unnamed_addr constant [13 x i8] c"bump() = %d\0A\00"
@.str.7 = private unnamed_addr constant [23 x i8] c"hi from a void closure\00"
@.str.8 = private unnamed_addr constant [2 x i8] c"\0A\00"
