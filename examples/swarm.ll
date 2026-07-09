; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
declare i32 @puts(i8*)
declare noalias i8* @malloc(i64)
declare void @free(i8*)
declare i32 @strlen(i8*)
declare i8* @memcpy(i8*, i8*, i64)
declare i8* @CreateThread(i8*, i64, i8*, i8*, i32, i32*)
declare i32 @WaitForSingleObject(i8*, i32)
declare i32 @CloseHandle(i8*)

%GenRef = type { i32, i32 }

@frame.buf = global [4096 x i8] zeroinitializer
@frame.off = global i64 0

%Enemy = type { i32 }
%Enemies = type { %Enemy*, i64 }
@arena.Enemies.data = global %Enemy* null
@arena.Enemies.count = global i64 0

define void @main() {
entry:
  %t15 = load i64, i64* @arena.Enemies.count
  %t16 = alloca [4 x i8*]
  %t17 = mul i64 %t15, 0
  %t18 = sdiv i64 %t17, 4
  %t19 = mul i64 %t15, 1
  %t20 = sdiv i64 %t19, 4
  %t21 = alloca { i64, i64 }
  %t22 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t21, i32 0, i32 0
  store i64 %t18, i64* %t22
  %t23 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t21, i32 0, i32 1
  store i64 %t20, i64* %t23
  %t24 = bitcast { i64, i64 }* %t21 to i8*
  %t25 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_0 to i8*), i8* %t24, i32 0, i32* null)
  %t26 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t16, i32 0, i32 0
  store i8* %t25, i8** %t26
  %t27 = mul i64 %t15, 1
  %t28 = sdiv i64 %t27, 4
  %t29 = mul i64 %t15, 2
  %t30 = sdiv i64 %t29, 4
  %t31 = alloca { i64, i64 }
  %t32 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t31, i32 0, i32 0
  store i64 %t28, i64* %t32
  %t33 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t31, i32 0, i32 1
  store i64 %t30, i64* %t33
  %t34 = bitcast { i64, i64 }* %t31 to i8*
  %t35 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_0 to i8*), i8* %t34, i32 0, i32* null)
  %t36 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t16, i32 0, i32 1
  store i8* %t35, i8** %t36
  %t37 = mul i64 %t15, 2
  %t38 = sdiv i64 %t37, 4
  %t39 = mul i64 %t15, 3
  %t40 = sdiv i64 %t39, 4
  %t41 = alloca { i64, i64 }
  %t42 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t41, i32 0, i32 0
  store i64 %t38, i64* %t42
  %t43 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t41, i32 0, i32 1
  store i64 %t40, i64* %t43
  %t44 = bitcast { i64, i64 }* %t41 to i8*
  %t45 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_0 to i8*), i8* %t44, i32 0, i32* null)
  %t46 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t16, i32 0, i32 2
  store i8* %t45, i8** %t46
  %t47 = mul i64 %t15, 3
  %t48 = sdiv i64 %t47, 4
  %t49 = mul i64 %t15, 4
  %t50 = sdiv i64 %t49, 4
  %t51 = alloca { i64, i64 }
  %t52 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t51, i32 0, i32 0
  store i64 %t48, i64* %t52
  %t53 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t51, i32 0, i32 1
  store i64 %t50, i64* %t53
  %t54 = bitcast { i64, i64 }* %t51 to i8*
  %t55 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_0 to i8*), i8* %t54, i32 0, i32* null)
  %t56 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t16, i32 0, i32 3
  store i8* %t55, i8** %t56
  %t57 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t16, i32 0, i32 0
  %t58 = load i8*, i8** %t57
  %t59 = call i32 @WaitForSingleObject(i8* %t58, i32 -1)
  %t60 = call i32 @CloseHandle(i8* %t58)
  %t61 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t16, i32 0, i32 1
  %t62 = load i8*, i8** %t61
  %t63 = call i32 @WaitForSingleObject(i8* %t62, i32 -1)
  %t64 = call i32 @CloseHandle(i8* %t62)
  %t65 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t16, i32 0, i32 2
  %t66 = load i8*, i8** %t65
  %t67 = call i32 @WaitForSingleObject(i8* %t66, i32 -1)
  %t68 = call i32 @CloseHandle(i8* %t66)
  %t69 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t16, i32 0, i32 3
  %t70 = load i8*, i8** %t69
  %t71 = call i32 @WaitForSingleObject(i8* %t70, i32 -1)
  %t72 = call i32 @CloseHandle(i8* %t70)
  %t85 = load i64, i64* @arena.Enemies.count
  %t86 = alloca [4 x i8*]
  %t87 = mul i64 %t85, 0
  %t88 = sdiv i64 %t87, 4
  %t89 = mul i64 %t85, 1
  %t90 = sdiv i64 %t89, 4
  %t91 = alloca { i64, i64 }
  %t92 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t91, i32 0, i32 0
  store i64 %t88, i64* %t92
  %t93 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t91, i32 0, i32 1
  store i64 %t90, i64* %t93
  %t94 = bitcast { i64, i64 }* %t91 to i8*
  %t95 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_4 to i8*), i8* %t94, i32 0, i32* null)
  %t96 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t86, i32 0, i32 0
  store i8* %t95, i8** %t96
  %t97 = mul i64 %t85, 1
  %t98 = sdiv i64 %t97, 4
  %t99 = mul i64 %t85, 2
  %t100 = sdiv i64 %t99, 4
  %t101 = alloca { i64, i64 }
  %t102 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t101, i32 0, i32 0
  store i64 %t98, i64* %t102
  %t103 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t101, i32 0, i32 1
  store i64 %t100, i64* %t103
  %t104 = bitcast { i64, i64 }* %t101 to i8*
  %t105 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_4 to i8*), i8* %t104, i32 0, i32* null)
  %t106 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t86, i32 0, i32 1
  store i8* %t105, i8** %t106
  %t107 = mul i64 %t85, 2
  %t108 = sdiv i64 %t107, 4
  %t109 = mul i64 %t85, 3
  %t110 = sdiv i64 %t109, 4
  %t111 = alloca { i64, i64 }
  %t112 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t111, i32 0, i32 0
  store i64 %t108, i64* %t112
  %t113 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t111, i32 0, i32 1
  store i64 %t110, i64* %t113
  %t114 = bitcast { i64, i64 }* %t111 to i8*
  %t115 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_4 to i8*), i8* %t114, i32 0, i32* null)
  %t116 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t86, i32 0, i32 2
  store i8* %t115, i8** %t116
  %t117 = mul i64 %t85, 3
  %t118 = sdiv i64 %t117, 4
  %t119 = mul i64 %t85, 4
  %t120 = sdiv i64 %t119, 4
  %t121 = alloca { i64, i64 }
  %t122 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t121, i32 0, i32 0
  store i64 %t118, i64* %t122
  %t123 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t121, i32 0, i32 1
  store i64 %t120, i64* %t123
  %t124 = bitcast { i64, i64 }* %t121 to i8*
  %t125 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_4 to i8*), i8* %t124, i32 0, i32* null)
  %t126 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t86, i32 0, i32 3
  store i8* %t125, i8** %t126
  %t127 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t86, i32 0, i32 0
  %t128 = load i8*, i8** %t127
  %t129 = call i32 @WaitForSingleObject(i8* %t128, i32 -1)
  %t130 = call i32 @CloseHandle(i8* %t128)
  %t131 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t86, i32 0, i32 1
  %t132 = load i8*, i8** %t131
  %t133 = call i32 @WaitForSingleObject(i8* %t132, i32 -1)
  %t134 = call i32 @CloseHandle(i8* %t132)
  %t135 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t86, i32 0, i32 2
  %t136 = load i8*, i8** %t135
  %t137 = call i32 @WaitForSingleObject(i8* %t136, i32 -1)
  %t138 = call i32 @CloseHandle(i8* %t136)
  %t139 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t86, i32 0, i32 3
  %t140 = load i8*, i8** %t139
  %t141 = call i32 @WaitForSingleObject(i8* %t140, i32 -1)
  %t142 = call i32 @CloseHandle(i8* %t140)
  %t143 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t143)
  ret void
}


; par/swarm worker functions
define i32 @par_worker_0(i8* %argp) {
entry:
  %t0 = bitcast i8* %argp to { i64, i64 }*
  %t1 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t0, i32 0, i32 0
  %t2 = load i64, i64* %t1
  %t3 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t0, i32 0, i32 1
  %t4 = load i64, i64* %t3
  %t5 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t6 = alloca i64
  store i64 %t2, i64* %t6
  br label %par_cond_1
par_cond_1:
  %t7 = load i64, i64* %t6
  %t8 = icmp slt i64 %t7, %t4
  br i1 %t8, label %par_body_2, label %par_end_3
par_body_2:
  %t9 = getelementptr inbounds %Enemy, %Enemy* %t5, i64 %t7
  %t10 = getelementptr inbounds %Enemy, %Enemy* %t9, i32 0, i32 0
  %t11 = load i32, i32* %t10
  %t12 = sub i32 %t11, 1
  %t13 = getelementptr inbounds %Enemy, %Enemy* %t9, i32 0, i32 0
  store i32 %t12, i32* %t13
  %t14 = add i64 %t7, 1
  store i64 %t14, i64* %t6
  br label %par_cond_1
par_end_3:
  ret i32 0
}


define i32 @par_worker_4(i8* %argp) {
entry:
  %t73 = bitcast i8* %argp to { i64, i64 }*
  %t74 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t73, i32 0, i32 0
  %t75 = load i64, i64* %t74
  %t76 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t73, i32 0, i32 1
  %t77 = load i64, i64* %t76
  %t78 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t79 = alloca i64
  store i64 %t75, i64* %t79
  br label %par_cond_5
par_cond_5:
  %t80 = load i64, i64* %t79
  %t81 = icmp slt i64 %t80, %t77
  br i1 %t81, label %par_body_6, label %par_end_7
par_body_6:
  %t82 = getelementptr inbounds %Enemy, %Enemy* %t78, i64 %t80
  %t83 = getelementptr inbounds %Enemy, %Enemy* %t82, i32 0, i32 0
  store i32 0, i32* %t83
  %t84 = add i64 %t80, 1
  store i64 %t84, i64* %t79
  br label %par_cond_5
par_end_7:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [12 x i8] c"swarm done\0A\00"
