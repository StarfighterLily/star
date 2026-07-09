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
  %t0 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t1 = icmp eq %Enemy* %t0, null
  br i1 %t1, label %spawn_init_0, label %spawn_ready_1
spawn_init_0:
  %t2 = call i8* @malloc(i64 4096)
  %t3 = bitcast i8* %t2 to %Enemy*
  store %Enemy* %t3, %Enemy** @arena.Enemies.data
  br label %spawn_ready_1
spawn_ready_1:
  %t4 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t5 = load i64, i64* @arena.Enemies.count
  %t6 = icmp slt i64 %t5, 1024
  br i1 %t6, label %spawn_store_2, label %spawn_end_3
spawn_store_2:
  %t7 = alloca %Enemy
  %t8 = getelementptr inbounds %Enemy, %Enemy* %t7, i32 0, i32 0
  store i32 10, i32* %t8
  %t9 = load %Enemy, %Enemy* %t7
  %t10 = getelementptr inbounds %Enemy, %Enemy* %t4, i64 %t5
  store %Enemy %t9, %Enemy* %t10
  %t11 = add i64 %t5, 1
  store i64 %t11, i64* @arena.Enemies.count
  br label %spawn_end_3
spawn_end_3:
  %t12 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t13 = icmp eq %Enemy* %t12, null
  br i1 %t13, label %spawn_init_4, label %spawn_ready_5
spawn_init_4:
  %t14 = call i8* @malloc(i64 4096)
  %t15 = bitcast i8* %t14 to %Enemy*
  store %Enemy* %t15, %Enemy** @arena.Enemies.data
  br label %spawn_ready_5
spawn_ready_5:
  %t16 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t17 = load i64, i64* @arena.Enemies.count
  %t18 = icmp slt i64 %t17, 1024
  br i1 %t18, label %spawn_store_6, label %spawn_end_7
spawn_store_6:
  %t19 = alloca %Enemy
  %t20 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 0
  store i32 20, i32* %t20
  %t21 = load %Enemy, %Enemy* %t19
  %t22 = getelementptr inbounds %Enemy, %Enemy* %t16, i64 %t17
  store %Enemy %t21, %Enemy* %t22
  %t23 = add i64 %t17, 1
  store i64 %t23, i64* @arena.Enemies.count
  br label %spawn_end_7
spawn_end_7:
  %t24 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t25 = icmp eq %Enemy* %t24, null
  br i1 %t25, label %spawn_init_8, label %spawn_ready_9
spawn_init_8:
  %t26 = call i8* @malloc(i64 4096)
  %t27 = bitcast i8* %t26 to %Enemy*
  store %Enemy* %t27, %Enemy** @arena.Enemies.data
  br label %spawn_ready_9
spawn_ready_9:
  %t28 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t29 = load i64, i64* @arena.Enemies.count
  %t30 = icmp slt i64 %t29, 1024
  br i1 %t30, label %spawn_store_10, label %spawn_end_11
spawn_store_10:
  %t31 = alloca %Enemy
  %t32 = getelementptr inbounds %Enemy, %Enemy* %t31, i32 0, i32 0
  store i32 30, i32* %t32
  %t33 = load %Enemy, %Enemy* %t31
  %t34 = getelementptr inbounds %Enemy, %Enemy* %t28, i64 %t29
  store %Enemy %t33, %Enemy* %t34
  %t35 = add i64 %t29, 1
  store i64 %t35, i64* @arena.Enemies.count
  br label %spawn_end_11
spawn_end_11:
  %t51 = load i64, i64* @arena.Enemies.count
  %t52 = alloca [4 x i8*]
  %t53 = mul i64 %t51, 0
  %t54 = sdiv i64 %t53, 4
  %t55 = mul i64 %t51, 1
  %t56 = sdiv i64 %t55, 4
  %t57 = alloca { i64, i64 }
  %t58 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t57, i32 0, i32 0
  store i64 %t54, i64* %t58
  %t59 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t57, i32 0, i32 1
  store i64 %t56, i64* %t59
  %t60 = bitcast { i64, i64 }* %t57 to i8*
  %t61 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_12 to i8*), i8* %t60, i32 0, i32* null)
  %t62 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t52, i32 0, i32 0
  store i8* %t61, i8** %t62
  %t63 = mul i64 %t51, 1
  %t64 = sdiv i64 %t63, 4
  %t65 = mul i64 %t51, 2
  %t66 = sdiv i64 %t65, 4
  %t67 = alloca { i64, i64 }
  %t68 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t67, i32 0, i32 0
  store i64 %t64, i64* %t68
  %t69 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t67, i32 0, i32 1
  store i64 %t66, i64* %t69
  %t70 = bitcast { i64, i64 }* %t67 to i8*
  %t71 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_12 to i8*), i8* %t70, i32 0, i32* null)
  %t72 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t52, i32 0, i32 1
  store i8* %t71, i8** %t72
  %t73 = mul i64 %t51, 2
  %t74 = sdiv i64 %t73, 4
  %t75 = mul i64 %t51, 3
  %t76 = sdiv i64 %t75, 4
  %t77 = alloca { i64, i64 }
  %t78 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t77, i32 0, i32 0
  store i64 %t74, i64* %t78
  %t79 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t77, i32 0, i32 1
  store i64 %t76, i64* %t79
  %t80 = bitcast { i64, i64 }* %t77 to i8*
  %t81 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_12 to i8*), i8* %t80, i32 0, i32* null)
  %t82 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t52, i32 0, i32 2
  store i8* %t81, i8** %t82
  %t83 = mul i64 %t51, 3
  %t84 = sdiv i64 %t83, 4
  %t85 = mul i64 %t51, 4
  %t86 = sdiv i64 %t85, 4
  %t87 = alloca { i64, i64 }
  %t88 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t87, i32 0, i32 0
  store i64 %t84, i64* %t88
  %t89 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t87, i32 0, i32 1
  store i64 %t86, i64* %t89
  %t90 = bitcast { i64, i64 }* %t87 to i8*
  %t91 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_12 to i8*), i8* %t90, i32 0, i32* null)
  %t92 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t52, i32 0, i32 3
  store i8* %t91, i8** %t92
  %t93 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t52, i32 0, i32 0
  %t94 = load i8*, i8** %t93
  %t95 = call i32 @WaitForSingleObject(i8* %t94, i32 -1)
  %t96 = call i32 @CloseHandle(i8* %t94)
  %t97 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t52, i32 0, i32 1
  %t98 = load i8*, i8** %t97
  %t99 = call i32 @WaitForSingleObject(i8* %t98, i32 -1)
  %t100 = call i32 @CloseHandle(i8* %t98)
  %t101 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t52, i32 0, i32 2
  %t102 = load i8*, i8** %t101
  %t103 = call i32 @WaitForSingleObject(i8* %t102, i32 -1)
  %t104 = call i32 @CloseHandle(i8* %t102)
  %t105 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t52, i32 0, i32 3
  %t106 = load i8*, i8** %t105
  %t107 = call i32 @WaitForSingleObject(i8* %t106, i32 -1)
  %t108 = call i32 @CloseHandle(i8* %t106)
  %t123 = load i64, i64* @arena.Enemies.count
  %t124 = alloca [4 x i8*]
  %t125 = mul i64 %t123, 0
  %t126 = sdiv i64 %t125, 4
  %t127 = mul i64 %t123, 1
  %t128 = sdiv i64 %t127, 4
  %t129 = alloca { i64, i64 }
  %t130 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t129, i32 0, i32 0
  store i64 %t126, i64* %t130
  %t131 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t129, i32 0, i32 1
  store i64 %t128, i64* %t131
  %t132 = bitcast { i64, i64 }* %t129 to i8*
  %t133 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_16 to i8*), i8* %t132, i32 0, i32* null)
  %t134 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t124, i32 0, i32 0
  store i8* %t133, i8** %t134
  %t135 = mul i64 %t123, 1
  %t136 = sdiv i64 %t135, 4
  %t137 = mul i64 %t123, 2
  %t138 = sdiv i64 %t137, 4
  %t139 = alloca { i64, i64 }
  %t140 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t139, i32 0, i32 0
  store i64 %t136, i64* %t140
  %t141 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t139, i32 0, i32 1
  store i64 %t138, i64* %t141
  %t142 = bitcast { i64, i64 }* %t139 to i8*
  %t143 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_16 to i8*), i8* %t142, i32 0, i32* null)
  %t144 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t124, i32 0, i32 1
  store i8* %t143, i8** %t144
  %t145 = mul i64 %t123, 2
  %t146 = sdiv i64 %t145, 4
  %t147 = mul i64 %t123, 3
  %t148 = sdiv i64 %t147, 4
  %t149 = alloca { i64, i64 }
  %t150 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t149, i32 0, i32 0
  store i64 %t146, i64* %t150
  %t151 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t149, i32 0, i32 1
  store i64 %t148, i64* %t151
  %t152 = bitcast { i64, i64 }* %t149 to i8*
  %t153 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_16 to i8*), i8* %t152, i32 0, i32* null)
  %t154 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t124, i32 0, i32 2
  store i8* %t153, i8** %t154
  %t155 = mul i64 %t123, 3
  %t156 = sdiv i64 %t155, 4
  %t157 = mul i64 %t123, 4
  %t158 = sdiv i64 %t157, 4
  %t159 = alloca { i64, i64 }
  %t160 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t159, i32 0, i32 0
  store i64 %t156, i64* %t160
  %t161 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t159, i32 0, i32 1
  store i64 %t158, i64* %t161
  %t162 = bitcast { i64, i64 }* %t159 to i8*
  %t163 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_16 to i8*), i8* %t162, i32 0, i32* null)
  %t164 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t124, i32 0, i32 3
  store i8* %t163, i8** %t164
  %t165 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t124, i32 0, i32 0
  %t166 = load i8*, i8** %t165
  %t167 = call i32 @WaitForSingleObject(i8* %t166, i32 -1)
  %t168 = call i32 @CloseHandle(i8* %t166)
  %t169 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t124, i32 0, i32 1
  %t170 = load i8*, i8** %t169
  %t171 = call i32 @WaitForSingleObject(i8* %t170, i32 -1)
  %t172 = call i32 @CloseHandle(i8* %t170)
  %t173 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t124, i32 0, i32 2
  %t174 = load i8*, i8** %t173
  %t175 = call i32 @WaitForSingleObject(i8* %t174, i32 -1)
  %t176 = call i32 @CloseHandle(i8* %t174)
  %t177 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t124, i32 0, i32 3
  %t178 = load i8*, i8** %t177
  %t179 = call i32 @WaitForSingleObject(i8* %t178, i32 -1)
  %t180 = call i32 @CloseHandle(i8* %t178)
  ret void
}


; par/swarm worker functions
define i32 @par_worker_12(i8* %argp) {
entry:
  %t36 = bitcast i8* %argp to { i64, i64 }*
  %t37 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t36, i32 0, i32 0
  %t38 = load i64, i64* %t37
  %t39 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t36, i32 0, i32 1
  %t40 = load i64, i64* %t39
  %t41 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t42 = alloca i64
  store i64 %t38, i64* %t42
  br label %par_cond_13
par_cond_13:
  %t43 = load i64, i64* %t42
  %t44 = icmp slt i64 %t43, %t40
  br i1 %t44, label %par_body_14, label %par_end_15
par_body_14:
  %t45 = getelementptr inbounds %Enemy, %Enemy* %t41, i64 %t43
  %t46 = getelementptr inbounds %Enemy, %Enemy* %t45, i32 0, i32 0
  %t47 = load i32, i32* %t46
  %t48 = sub i32 %t47, 1
  %t49 = getelementptr inbounds %Enemy, %Enemy* %t45, i32 0, i32 0
  store i32 %t48, i32* %t49
  %t50 = add i64 %t43, 1
  store i64 %t50, i64* %t42
  br label %par_cond_13
par_end_15:
  ret i32 0
}


define i32 @par_worker_16(i8* %argp) {
entry:
  %t109 = bitcast i8* %argp to { i64, i64 }*
  %t110 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t109, i32 0, i32 0
  %t111 = load i64, i64* %t110
  %t112 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t109, i32 0, i32 1
  %t113 = load i64, i64* %t112
  %t114 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t115 = alloca i64
  store i64 %t111, i64* %t115
  br label %par_cond_17
par_cond_17:
  %t116 = load i64, i64* %t115
  %t117 = icmp slt i64 %t116, %t113
  br i1 %t117, label %par_body_18, label %par_end_19
par_body_18:
  %t118 = getelementptr inbounds %Enemy, %Enemy* %t114, i64 %t116
  %t119 = getelementptr inbounds %Enemy, %Enemy* %t118, i32 0, i32 0
  %t120 = load i32, i32* %t119
  %t121 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t121, i32 %t120)
  %t122 = add i64 %t116, 1
  store i64 %t122, i64* %t115
  br label %par_cond_17
par_end_19:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [8 x i8] c"hp: %d\0A\00"
