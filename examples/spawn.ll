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

%Enemy = type { i32 }
%Enemies = type { %Enemy*, i64 }
@arena.Enemies.data = global %Enemy* null
@arena.Enemies.count = global i64 0
@arena.Enemies.gen = global [1024 x i32] zeroinitializer

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
  %t11 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t5
  store i32 1, i32* %t11
  %t12 = add i64 %t5, 1
  store i64 %t12, i64* @arena.Enemies.count
  br label %spawn_end_3
spawn_end_3:
  %t13 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t14 = icmp eq %Enemy* %t13, null
  br i1 %t14, label %spawn_init_4, label %spawn_ready_5
spawn_init_4:
  %t15 = call i8* @malloc(i64 4096)
  %t16 = bitcast i8* %t15 to %Enemy*
  store %Enemy* %t16, %Enemy** @arena.Enemies.data
  br label %spawn_ready_5
spawn_ready_5:
  %t17 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t18 = load i64, i64* @arena.Enemies.count
  %t19 = icmp slt i64 %t18, 1024
  br i1 %t19, label %spawn_store_6, label %spawn_end_7
spawn_store_6:
  %t20 = alloca %Enemy
  %t21 = getelementptr inbounds %Enemy, %Enemy* %t20, i32 0, i32 0
  store i32 20, i32* %t21
  %t22 = load %Enemy, %Enemy* %t20
  %t23 = getelementptr inbounds %Enemy, %Enemy* %t17, i64 %t18
  store %Enemy %t22, %Enemy* %t23
  %t24 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t18
  store i32 1, i32* %t24
  %t25 = add i64 %t18, 1
  store i64 %t25, i64* @arena.Enemies.count
  br label %spawn_end_7
spawn_end_7:
  %t26 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t27 = icmp eq %Enemy* %t26, null
  br i1 %t27, label %spawn_init_8, label %spawn_ready_9
spawn_init_8:
  %t28 = call i8* @malloc(i64 4096)
  %t29 = bitcast i8* %t28 to %Enemy*
  store %Enemy* %t29, %Enemy** @arena.Enemies.data
  br label %spawn_ready_9
spawn_ready_9:
  %t30 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t31 = load i64, i64* @arena.Enemies.count
  %t32 = icmp slt i64 %t31, 1024
  br i1 %t32, label %spawn_store_10, label %spawn_end_11
spawn_store_10:
  %t33 = alloca %Enemy
  %t34 = getelementptr inbounds %Enemy, %Enemy* %t33, i32 0, i32 0
  store i32 30, i32* %t34
  %t35 = load %Enemy, %Enemy* %t33
  %t36 = getelementptr inbounds %Enemy, %Enemy* %t30, i64 %t31
  store %Enemy %t35, %Enemy* %t36
  %t37 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t31
  store i32 1, i32* %t37
  %t38 = add i64 %t31, 1
  store i64 %t38, i64* @arena.Enemies.count
  br label %spawn_end_11
spawn_end_11:
  %t54 = load i64, i64* @arena.Enemies.count
  %t55 = alloca [4 x i8*]
  %t56 = mul i64 %t54, 0
  %t57 = sdiv i64 %t56, 4
  %t58 = mul i64 %t54, 1
  %t59 = sdiv i64 %t58, 4
  %t60 = alloca { i64, i64 }
  %t61 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t60, i32 0, i32 0
  store i64 %t57, i64* %t61
  %t62 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t60, i32 0, i32 1
  store i64 %t59, i64* %t62
  %t63 = bitcast { i64, i64 }* %t60 to i8*
  %t64 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_12 to i8*), i8* %t63, i32 0, i32* null)
  %t65 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t55, i32 0, i32 0
  store i8* %t64, i8** %t65
  %t66 = mul i64 %t54, 1
  %t67 = sdiv i64 %t66, 4
  %t68 = mul i64 %t54, 2
  %t69 = sdiv i64 %t68, 4
  %t70 = alloca { i64, i64 }
  %t71 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t70, i32 0, i32 0
  store i64 %t67, i64* %t71
  %t72 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t70, i32 0, i32 1
  store i64 %t69, i64* %t72
  %t73 = bitcast { i64, i64 }* %t70 to i8*
  %t74 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_12 to i8*), i8* %t73, i32 0, i32* null)
  %t75 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t55, i32 0, i32 1
  store i8* %t74, i8** %t75
  %t76 = mul i64 %t54, 2
  %t77 = sdiv i64 %t76, 4
  %t78 = mul i64 %t54, 3
  %t79 = sdiv i64 %t78, 4
  %t80 = alloca { i64, i64 }
  %t81 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t80, i32 0, i32 0
  store i64 %t77, i64* %t81
  %t82 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t80, i32 0, i32 1
  store i64 %t79, i64* %t82
  %t83 = bitcast { i64, i64 }* %t80 to i8*
  %t84 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_12 to i8*), i8* %t83, i32 0, i32* null)
  %t85 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t55, i32 0, i32 2
  store i8* %t84, i8** %t85
  %t86 = mul i64 %t54, 3
  %t87 = sdiv i64 %t86, 4
  %t88 = mul i64 %t54, 4
  %t89 = sdiv i64 %t88, 4
  %t90 = alloca { i64, i64 }
  %t91 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t90, i32 0, i32 0
  store i64 %t87, i64* %t91
  %t92 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t90, i32 0, i32 1
  store i64 %t89, i64* %t92
  %t93 = bitcast { i64, i64 }* %t90 to i8*
  %t94 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_12 to i8*), i8* %t93, i32 0, i32* null)
  %t95 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t55, i32 0, i32 3
  store i8* %t94, i8** %t95
  %t96 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t55, i32 0, i32 0
  %t97 = load i8*, i8** %t96
  %t98 = call i32 @WaitForSingleObject(i8* %t97, i32 -1)
  %t99 = call i32 @CloseHandle(i8* %t97)
  %t100 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t55, i32 0, i32 1
  %t101 = load i8*, i8** %t100
  %t102 = call i32 @WaitForSingleObject(i8* %t101, i32 -1)
  %t103 = call i32 @CloseHandle(i8* %t101)
  %t104 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t55, i32 0, i32 2
  %t105 = load i8*, i8** %t104
  %t106 = call i32 @WaitForSingleObject(i8* %t105, i32 -1)
  %t107 = call i32 @CloseHandle(i8* %t105)
  %t108 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t55, i32 0, i32 3
  %t109 = load i8*, i8** %t108
  %t110 = call i32 @WaitForSingleObject(i8* %t109, i32 -1)
  %t111 = call i32 @CloseHandle(i8* %t109)
  %t126 = load i64, i64* @arena.Enemies.count
  %t127 = alloca [4 x i8*]
  %t128 = mul i64 %t126, 0
  %t129 = sdiv i64 %t128, 4
  %t130 = mul i64 %t126, 1
  %t131 = sdiv i64 %t130, 4
  %t132 = alloca { i64, i64 }
  %t133 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t132, i32 0, i32 0
  store i64 %t129, i64* %t133
  %t134 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t132, i32 0, i32 1
  store i64 %t131, i64* %t134
  %t135 = bitcast { i64, i64 }* %t132 to i8*
  %t136 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_16 to i8*), i8* %t135, i32 0, i32* null)
  %t137 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t127, i32 0, i32 0
  store i8* %t136, i8** %t137
  %t138 = mul i64 %t126, 1
  %t139 = sdiv i64 %t138, 4
  %t140 = mul i64 %t126, 2
  %t141 = sdiv i64 %t140, 4
  %t142 = alloca { i64, i64 }
  %t143 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t142, i32 0, i32 0
  store i64 %t139, i64* %t143
  %t144 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t142, i32 0, i32 1
  store i64 %t141, i64* %t144
  %t145 = bitcast { i64, i64 }* %t142 to i8*
  %t146 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_16 to i8*), i8* %t145, i32 0, i32* null)
  %t147 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t127, i32 0, i32 1
  store i8* %t146, i8** %t147
  %t148 = mul i64 %t126, 2
  %t149 = sdiv i64 %t148, 4
  %t150 = mul i64 %t126, 3
  %t151 = sdiv i64 %t150, 4
  %t152 = alloca { i64, i64 }
  %t153 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t152, i32 0, i32 0
  store i64 %t149, i64* %t153
  %t154 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t152, i32 0, i32 1
  store i64 %t151, i64* %t154
  %t155 = bitcast { i64, i64 }* %t152 to i8*
  %t156 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_16 to i8*), i8* %t155, i32 0, i32* null)
  %t157 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t127, i32 0, i32 2
  store i8* %t156, i8** %t157
  %t158 = mul i64 %t126, 3
  %t159 = sdiv i64 %t158, 4
  %t160 = mul i64 %t126, 4
  %t161 = sdiv i64 %t160, 4
  %t162 = alloca { i64, i64 }
  %t163 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t162, i32 0, i32 0
  store i64 %t159, i64* %t163
  %t164 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t162, i32 0, i32 1
  store i64 %t161, i64* %t164
  %t165 = bitcast { i64, i64 }* %t162 to i8*
  %t166 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_16 to i8*), i8* %t165, i32 0, i32* null)
  %t167 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t127, i32 0, i32 3
  store i8* %t166, i8** %t167
  %t168 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t127, i32 0, i32 0
  %t169 = load i8*, i8** %t168
  %t170 = call i32 @WaitForSingleObject(i8* %t169, i32 -1)
  %t171 = call i32 @CloseHandle(i8* %t169)
  %t172 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t127, i32 0, i32 1
  %t173 = load i8*, i8** %t172
  %t174 = call i32 @WaitForSingleObject(i8* %t173, i32 -1)
  %t175 = call i32 @CloseHandle(i8* %t173)
  %t176 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t127, i32 0, i32 2
  %t177 = load i8*, i8** %t176
  %t178 = call i32 @WaitForSingleObject(i8* %t177, i32 -1)
  %t179 = call i32 @CloseHandle(i8* %t177)
  %t180 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t127, i32 0, i32 3
  %t181 = load i8*, i8** %t180
  %t182 = call i32 @WaitForSingleObject(i8* %t181, i32 -1)
  %t183 = call i32 @CloseHandle(i8* %t181)
  ret void
}


; par/swarm worker functions
define i32 @par_worker_12(i8* %argp) {
entry:
  %t39 = bitcast i8* %argp to { i64, i64 }*
  %t40 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t39, i32 0, i32 0
  %t41 = load i64, i64* %t40
  %t42 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t39, i32 0, i32 1
  %t43 = load i64, i64* %t42
  %t44 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t45 = alloca i64
  store i64 %t41, i64* %t45
  br label %par_cond_13
par_cond_13:
  %t46 = load i64, i64* %t45
  %t47 = icmp slt i64 %t46, %t43
  br i1 %t47, label %par_body_14, label %par_end_15
par_body_14:
  %t48 = getelementptr inbounds %Enemy, %Enemy* %t44, i64 %t46
  %t49 = getelementptr inbounds %Enemy, %Enemy* %t48, i32 0, i32 0
  %t50 = load i32, i32* %t49
  %t51 = sub i32 %t50, 1
  %t52 = getelementptr inbounds %Enemy, %Enemy* %t48, i32 0, i32 0
  store i32 %t51, i32* %t52
  %t53 = add i64 %t46, 1
  store i64 %t53, i64* %t45
  br label %par_cond_13
par_end_15:
  ret i32 0
}


define i32 @par_worker_16(i8* %argp) {
entry:
  %t112 = bitcast i8* %argp to { i64, i64 }*
  %t113 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t112, i32 0, i32 0
  %t114 = load i64, i64* %t113
  %t115 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t112, i32 0, i32 1
  %t116 = load i64, i64* %t115
  %t117 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t118 = alloca i64
  store i64 %t114, i64* %t118
  br label %par_cond_17
par_cond_17:
  %t119 = load i64, i64* %t118
  %t120 = icmp slt i64 %t119, %t116
  br i1 %t120, label %par_body_18, label %par_end_19
par_body_18:
  %t121 = getelementptr inbounds %Enemy, %Enemy* %t117, i64 %t119
  %t122 = getelementptr inbounds %Enemy, %Enemy* %t121, i32 0, i32 0
  %t123 = load i32, i32* %t122
  %t124 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t124, i32 %t123)
  %t125 = add i64 %t119, 1
  store i64 %t125, i64* %t118
  br label %par_cond_17
par_end_19:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [8 x i8] c"hp: %d\0A\00"
