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
@arena.Enemies.free = global [1024 x i64] zeroinitializer
@arena.Enemies.free_top = global i64 0

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
  %t5 = load i64, i64* @arena.Enemies.free_top
  %t6 = icmp sgt i64 %t5, 0
  br i1 %t6, label %spawn_reuse_2, label %spawn_grow_3
spawn_reuse_2:
  %t7 = sub i64 %t5, 1
  store i64 %t7, i64* @arena.Enemies.free_top
  %t8 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t7
  %t9 = load i64, i64* %t8
  br label %spawn_store_4
spawn_grow_3:
  %t10 = load i64, i64* @arena.Enemies.count
  %t11 = icmp slt i64 %t10, 1024
  br i1 %t11, label %spawn_grow_ok_6, label %spawn_end_5
spawn_grow_ok_6:
  %t12 = add i64 %t10, 1
  store i64 %t12, i64* @arena.Enemies.count
  br label %spawn_store_4
spawn_store_4:
  %t13 = phi i64 [ %t9, %spawn_reuse_2 ], [ %t10, %spawn_grow_ok_6 ]
  %t14 = alloca %Enemy
  %t15 = getelementptr inbounds %Enemy, %Enemy* %t14, i32 0, i32 0
  store i32 10, i32* %t15
  %t16 = load %Enemy, %Enemy* %t14
  %t17 = getelementptr inbounds %Enemy, %Enemy* %t4, i64 %t13
  store %Enemy %t16, %Enemy* %t17
  %t18 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t13
  %t19 = load i32, i32* %t18
  %t20 = add i32 %t19, 1
  store i32 %t20, i32* %t18
  br label %spawn_end_5
spawn_end_5:
  %t21 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t22 = icmp eq %Enemy* %t21, null
  br i1 %t22, label %spawn_init_7, label %spawn_ready_8
spawn_init_7:
  %t23 = call i8* @malloc(i64 4096)
  %t24 = bitcast i8* %t23 to %Enemy*
  store %Enemy* %t24, %Enemy** @arena.Enemies.data
  br label %spawn_ready_8
spawn_ready_8:
  %t25 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t26 = load i64, i64* @arena.Enemies.free_top
  %t27 = icmp sgt i64 %t26, 0
  br i1 %t27, label %spawn_reuse_9, label %spawn_grow_10
spawn_reuse_9:
  %t28 = sub i64 %t26, 1
  store i64 %t28, i64* @arena.Enemies.free_top
  %t29 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t28
  %t30 = load i64, i64* %t29
  br label %spawn_store_11
spawn_grow_10:
  %t31 = load i64, i64* @arena.Enemies.count
  %t32 = icmp slt i64 %t31, 1024
  br i1 %t32, label %spawn_grow_ok_13, label %spawn_end_12
spawn_grow_ok_13:
  %t33 = add i64 %t31, 1
  store i64 %t33, i64* @arena.Enemies.count
  br label %spawn_store_11
spawn_store_11:
  %t34 = phi i64 [ %t30, %spawn_reuse_9 ], [ %t31, %spawn_grow_ok_13 ]
  %t35 = alloca %Enemy
  %t36 = getelementptr inbounds %Enemy, %Enemy* %t35, i32 0, i32 0
  store i32 20, i32* %t36
  %t37 = load %Enemy, %Enemy* %t35
  %t38 = getelementptr inbounds %Enemy, %Enemy* %t25, i64 %t34
  store %Enemy %t37, %Enemy* %t38
  %t39 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t34
  %t40 = load i32, i32* %t39
  %t41 = add i32 %t40, 1
  store i32 %t41, i32* %t39
  br label %spawn_end_12
spawn_end_12:
  %t42 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t43 = icmp eq %Enemy* %t42, null
  br i1 %t43, label %spawn_init_14, label %spawn_ready_15
spawn_init_14:
  %t44 = call i8* @malloc(i64 4096)
  %t45 = bitcast i8* %t44 to %Enemy*
  store %Enemy* %t45, %Enemy** @arena.Enemies.data
  br label %spawn_ready_15
spawn_ready_15:
  %t46 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t47 = load i64, i64* @arena.Enemies.free_top
  %t48 = icmp sgt i64 %t47, 0
  br i1 %t48, label %spawn_reuse_16, label %spawn_grow_17
spawn_reuse_16:
  %t49 = sub i64 %t47, 1
  store i64 %t49, i64* @arena.Enemies.free_top
  %t50 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t49
  %t51 = load i64, i64* %t50
  br label %spawn_store_18
spawn_grow_17:
  %t52 = load i64, i64* @arena.Enemies.count
  %t53 = icmp slt i64 %t52, 1024
  br i1 %t53, label %spawn_grow_ok_20, label %spawn_end_19
spawn_grow_ok_20:
  %t54 = add i64 %t52, 1
  store i64 %t54, i64* @arena.Enemies.count
  br label %spawn_store_18
spawn_store_18:
  %t55 = phi i64 [ %t51, %spawn_reuse_16 ], [ %t52, %spawn_grow_ok_20 ]
  %t56 = alloca %Enemy
  %t57 = getelementptr inbounds %Enemy, %Enemy* %t56, i32 0, i32 0
  store i32 30, i32* %t57
  %t58 = load %Enemy, %Enemy* %t56
  %t59 = getelementptr inbounds %Enemy, %Enemy* %t46, i64 %t55
  store %Enemy %t58, %Enemy* %t59
  %t60 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t55
  %t61 = load i32, i32* %t60
  %t62 = add i32 %t61, 1
  store i32 %t62, i32* %t60
  br label %spawn_end_19
spawn_end_19:
  %t78 = load i64, i64* @arena.Enemies.count
  %t79 = alloca [4 x i8*]
  %t80 = mul i64 %t78, 0
  %t81 = sdiv i64 %t80, 4
  %t82 = mul i64 %t78, 1
  %t83 = sdiv i64 %t82, 4
  %t84 = alloca { i64, i64 }
  %t85 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t84, i32 0, i32 0
  store i64 %t81, i64* %t85
  %t86 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t84, i32 0, i32 1
  store i64 %t83, i64* %t86
  %t87 = bitcast { i64, i64 }* %t84 to i8*
  %t88 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_21 to i8*), i8* %t87, i32 0, i32* null)
  %t89 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t79, i32 0, i32 0
  store i8* %t88, i8** %t89
  %t90 = mul i64 %t78, 1
  %t91 = sdiv i64 %t90, 4
  %t92 = mul i64 %t78, 2
  %t93 = sdiv i64 %t92, 4
  %t94 = alloca { i64, i64 }
  %t95 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t94, i32 0, i32 0
  store i64 %t91, i64* %t95
  %t96 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t94, i32 0, i32 1
  store i64 %t93, i64* %t96
  %t97 = bitcast { i64, i64 }* %t94 to i8*
  %t98 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_21 to i8*), i8* %t97, i32 0, i32* null)
  %t99 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t79, i32 0, i32 1
  store i8* %t98, i8** %t99
  %t100 = mul i64 %t78, 2
  %t101 = sdiv i64 %t100, 4
  %t102 = mul i64 %t78, 3
  %t103 = sdiv i64 %t102, 4
  %t104 = alloca { i64, i64 }
  %t105 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t104, i32 0, i32 0
  store i64 %t101, i64* %t105
  %t106 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t104, i32 0, i32 1
  store i64 %t103, i64* %t106
  %t107 = bitcast { i64, i64 }* %t104 to i8*
  %t108 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_21 to i8*), i8* %t107, i32 0, i32* null)
  %t109 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t79, i32 0, i32 2
  store i8* %t108, i8** %t109
  %t110 = mul i64 %t78, 3
  %t111 = sdiv i64 %t110, 4
  %t112 = mul i64 %t78, 4
  %t113 = sdiv i64 %t112, 4
  %t114 = alloca { i64, i64 }
  %t115 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t114, i32 0, i32 0
  store i64 %t111, i64* %t115
  %t116 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t114, i32 0, i32 1
  store i64 %t113, i64* %t116
  %t117 = bitcast { i64, i64 }* %t114 to i8*
  %t118 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_21 to i8*), i8* %t117, i32 0, i32* null)
  %t119 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t79, i32 0, i32 3
  store i8* %t118, i8** %t119
  %t120 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t79, i32 0, i32 0
  %t121 = load i8*, i8** %t120
  %t122 = call i32 @WaitForSingleObject(i8* %t121, i32 -1)
  %t123 = call i32 @CloseHandle(i8* %t121)
  %t124 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t79, i32 0, i32 1
  %t125 = load i8*, i8** %t124
  %t126 = call i32 @WaitForSingleObject(i8* %t125, i32 -1)
  %t127 = call i32 @CloseHandle(i8* %t125)
  %t128 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t79, i32 0, i32 2
  %t129 = load i8*, i8** %t128
  %t130 = call i32 @WaitForSingleObject(i8* %t129, i32 -1)
  %t131 = call i32 @CloseHandle(i8* %t129)
  %t132 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t79, i32 0, i32 3
  %t133 = load i8*, i8** %t132
  %t134 = call i32 @WaitForSingleObject(i8* %t133, i32 -1)
  %t135 = call i32 @CloseHandle(i8* %t133)
  %t150 = load i64, i64* @arena.Enemies.count
  %t151 = alloca [4 x i8*]
  %t152 = mul i64 %t150, 0
  %t153 = sdiv i64 %t152, 4
  %t154 = mul i64 %t150, 1
  %t155 = sdiv i64 %t154, 4
  %t156 = alloca { i64, i64 }
  %t157 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t156, i32 0, i32 0
  store i64 %t153, i64* %t157
  %t158 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t156, i32 0, i32 1
  store i64 %t155, i64* %t158
  %t159 = bitcast { i64, i64 }* %t156 to i8*
  %t160 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_25 to i8*), i8* %t159, i32 0, i32* null)
  %t161 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t151, i32 0, i32 0
  store i8* %t160, i8** %t161
  %t162 = mul i64 %t150, 1
  %t163 = sdiv i64 %t162, 4
  %t164 = mul i64 %t150, 2
  %t165 = sdiv i64 %t164, 4
  %t166 = alloca { i64, i64 }
  %t167 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t166, i32 0, i32 0
  store i64 %t163, i64* %t167
  %t168 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t166, i32 0, i32 1
  store i64 %t165, i64* %t168
  %t169 = bitcast { i64, i64 }* %t166 to i8*
  %t170 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_25 to i8*), i8* %t169, i32 0, i32* null)
  %t171 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t151, i32 0, i32 1
  store i8* %t170, i8** %t171
  %t172 = mul i64 %t150, 2
  %t173 = sdiv i64 %t172, 4
  %t174 = mul i64 %t150, 3
  %t175 = sdiv i64 %t174, 4
  %t176 = alloca { i64, i64 }
  %t177 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t176, i32 0, i32 0
  store i64 %t173, i64* %t177
  %t178 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t176, i32 0, i32 1
  store i64 %t175, i64* %t178
  %t179 = bitcast { i64, i64 }* %t176 to i8*
  %t180 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_25 to i8*), i8* %t179, i32 0, i32* null)
  %t181 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t151, i32 0, i32 2
  store i8* %t180, i8** %t181
  %t182 = mul i64 %t150, 3
  %t183 = sdiv i64 %t182, 4
  %t184 = mul i64 %t150, 4
  %t185 = sdiv i64 %t184, 4
  %t186 = alloca { i64, i64 }
  %t187 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t186, i32 0, i32 0
  store i64 %t183, i64* %t187
  %t188 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t186, i32 0, i32 1
  store i64 %t185, i64* %t188
  %t189 = bitcast { i64, i64 }* %t186 to i8*
  %t190 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_25 to i8*), i8* %t189, i32 0, i32* null)
  %t191 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t151, i32 0, i32 3
  store i8* %t190, i8** %t191
  %t192 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t151, i32 0, i32 0
  %t193 = load i8*, i8** %t192
  %t194 = call i32 @WaitForSingleObject(i8* %t193, i32 -1)
  %t195 = call i32 @CloseHandle(i8* %t193)
  %t196 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t151, i32 0, i32 1
  %t197 = load i8*, i8** %t196
  %t198 = call i32 @WaitForSingleObject(i8* %t197, i32 -1)
  %t199 = call i32 @CloseHandle(i8* %t197)
  %t200 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t151, i32 0, i32 2
  %t201 = load i8*, i8** %t200
  %t202 = call i32 @WaitForSingleObject(i8* %t201, i32 -1)
  %t203 = call i32 @CloseHandle(i8* %t201)
  %t204 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t151, i32 0, i32 3
  %t205 = load i8*, i8** %t204
  %t206 = call i32 @WaitForSingleObject(i8* %t205, i32 -1)
  %t207 = call i32 @CloseHandle(i8* %t205)
  ret void
}


; par/swarm worker functions
define i32 @par_worker_21(i8* %argp) {
entry:
  %t63 = bitcast i8* %argp to { i64, i64 }*
  %t64 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t63, i32 0, i32 0
  %t65 = load i64, i64* %t64
  %t66 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t63, i32 0, i32 1
  %t67 = load i64, i64* %t66
  %t68 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t69 = alloca i64
  store i64 %t65, i64* %t69
  br label %par_cond_22
par_cond_22:
  %t70 = load i64, i64* %t69
  %t71 = icmp slt i64 %t70, %t67
  br i1 %t71, label %par_body_23, label %par_end_24
par_body_23:
  %t72 = getelementptr inbounds %Enemy, %Enemy* %t68, i64 %t70
  %t73 = getelementptr inbounds %Enemy, %Enemy* %t72, i32 0, i32 0
  %t74 = load i32, i32* %t73
  %t75 = sub i32 %t74, 1
  %t76 = getelementptr inbounds %Enemy, %Enemy* %t72, i32 0, i32 0
  store i32 %t75, i32* %t76
  %t77 = add i64 %t70, 1
  store i64 %t77, i64* %t69
  br label %par_cond_22
par_end_24:
  ret i32 0
}


define i32 @par_worker_25(i8* %argp) {
entry:
  %t136 = bitcast i8* %argp to { i64, i64 }*
  %t137 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t136, i32 0, i32 0
  %t138 = load i64, i64* %t137
  %t139 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t136, i32 0, i32 1
  %t140 = load i64, i64* %t139
  %t141 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t142 = alloca i64
  store i64 %t138, i64* %t142
  br label %par_cond_26
par_cond_26:
  %t143 = load i64, i64* %t142
  %t144 = icmp slt i64 %t143, %t140
  br i1 %t144, label %par_body_27, label %par_end_28
par_body_27:
  %t145 = getelementptr inbounds %Enemy, %Enemy* %t141, i64 %t143
  %t146 = getelementptr inbounds %Enemy, %Enemy* %t145, i32 0, i32 0
  %t147 = load i32, i32* %t146
  %t148 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t148, i32 %t147)
  %t149 = add i64 %t143, 1
  store i64 %t149, i64* %t142
  br label %par_cond_26
par_end_28:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [8 x i8] c"hp: %d\0A\00"
