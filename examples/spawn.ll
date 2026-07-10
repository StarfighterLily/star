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

%Enemy = type { i32 }
%Enemies = type { %Enemy*, i64 }
@arena.Enemies.data = global %Enemy* null
@arena.Enemies.count = global i64 0
@arena.Enemies.gen = global [1024 x i32] zeroinitializer
@arena.Enemies.free = global [1024 x i64] zeroinitializer
@arena.Enemies.free_top = global i64 0

define i32 @main() {
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
  br i1 %t11, label %spawn_grow_ok_6, label %spawn_capacity_warn_7
spawn_capacity_warn_7:
  %t12 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t12)
  br label %spawn_end_5
spawn_grow_ok_6:
  %t13 = add i64 %t10, 1
  store i64 %t13, i64* @arena.Enemies.count
  br label %spawn_store_4
spawn_store_4:
  %t14 = phi i64 [ %t9, %spawn_reuse_2 ], [ %t10, %spawn_grow_ok_6 ]
  %t15 = alloca %Enemy
  %t16 = getelementptr inbounds %Enemy, %Enemy* %t15, i32 0, i32 0
  store i32 10, i32* %t16
  %t17 = load %Enemy, %Enemy* %t15
  %t18 = getelementptr inbounds %Enemy, %Enemy* %t4, i64 %t14
  store %Enemy %t17, %Enemy* %t18
  %t19 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t14
  %t20 = load i32, i32* %t19
  %t21 = add i32 %t20, 1
  store i32 %t21, i32* %t19
  br label %spawn_end_5
spawn_end_5:
  %t22 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t23 = icmp eq %Enemy* %t22, null
  br i1 %t23, label %spawn_init_8, label %spawn_ready_9
spawn_init_8:
  %t24 = call i8* @malloc(i64 4096)
  %t25 = bitcast i8* %t24 to %Enemy*
  store %Enemy* %t25, %Enemy** @arena.Enemies.data
  br label %spawn_ready_9
spawn_ready_9:
  %t26 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t27 = load i64, i64* @arena.Enemies.free_top
  %t28 = icmp sgt i64 %t27, 0
  br i1 %t28, label %spawn_reuse_10, label %spawn_grow_11
spawn_reuse_10:
  %t29 = sub i64 %t27, 1
  store i64 %t29, i64* @arena.Enemies.free_top
  %t30 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t29
  %t31 = load i64, i64* %t30
  br label %spawn_store_12
spawn_grow_11:
  %t32 = load i64, i64* @arena.Enemies.count
  %t33 = icmp slt i64 %t32, 1024
  br i1 %t33, label %spawn_grow_ok_14, label %spawn_capacity_warn_15
spawn_capacity_warn_15:
  %t34 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t34)
  br label %spawn_end_13
spawn_grow_ok_14:
  %t35 = add i64 %t32, 1
  store i64 %t35, i64* @arena.Enemies.count
  br label %spawn_store_12
spawn_store_12:
  %t36 = phi i64 [ %t31, %spawn_reuse_10 ], [ %t32, %spawn_grow_ok_14 ]
  %t37 = alloca %Enemy
  %t38 = getelementptr inbounds %Enemy, %Enemy* %t37, i32 0, i32 0
  store i32 20, i32* %t38
  %t39 = load %Enemy, %Enemy* %t37
  %t40 = getelementptr inbounds %Enemy, %Enemy* %t26, i64 %t36
  store %Enemy %t39, %Enemy* %t40
  %t41 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t36
  %t42 = load i32, i32* %t41
  %t43 = add i32 %t42, 1
  store i32 %t43, i32* %t41
  br label %spawn_end_13
spawn_end_13:
  %t44 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t45 = icmp eq %Enemy* %t44, null
  br i1 %t45, label %spawn_init_16, label %spawn_ready_17
spawn_init_16:
  %t46 = call i8* @malloc(i64 4096)
  %t47 = bitcast i8* %t46 to %Enemy*
  store %Enemy* %t47, %Enemy** @arena.Enemies.data
  br label %spawn_ready_17
spawn_ready_17:
  %t48 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t49 = load i64, i64* @arena.Enemies.free_top
  %t50 = icmp sgt i64 %t49, 0
  br i1 %t50, label %spawn_reuse_18, label %spawn_grow_19
spawn_reuse_18:
  %t51 = sub i64 %t49, 1
  store i64 %t51, i64* @arena.Enemies.free_top
  %t52 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t51
  %t53 = load i64, i64* %t52
  br label %spawn_store_20
spawn_grow_19:
  %t54 = load i64, i64* @arena.Enemies.count
  %t55 = icmp slt i64 %t54, 1024
  br i1 %t55, label %spawn_grow_ok_22, label %spawn_capacity_warn_23
spawn_capacity_warn_23:
  %t56 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t56)
  br label %spawn_end_21
spawn_grow_ok_22:
  %t57 = add i64 %t54, 1
  store i64 %t57, i64* @arena.Enemies.count
  br label %spawn_store_20
spawn_store_20:
  %t58 = phi i64 [ %t53, %spawn_reuse_18 ], [ %t54, %spawn_grow_ok_22 ]
  %t59 = alloca %Enemy
  %t60 = getelementptr inbounds %Enemy, %Enemy* %t59, i32 0, i32 0
  store i32 30, i32* %t60
  %t61 = load %Enemy, %Enemy* %t59
  %t62 = getelementptr inbounds %Enemy, %Enemy* %t48, i64 %t58
  store %Enemy %t61, %Enemy* %t62
  %t63 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t58
  %t64 = load i32, i32* %t63
  %t65 = add i32 %t64, 1
  store i32 %t65, i32* %t63
  br label %spawn_end_21
spawn_end_21:
  %t81 = load i64, i64* @arena.Enemies.count
  %t82 = alloca [4 x i8*]
  %t83 = mul i64 %t81, 0
  %t84 = sdiv i64 %t83, 4
  %t85 = mul i64 %t81, 1
  %t86 = sdiv i64 %t85, 4
  %t87 = alloca { i64, i64 }
  %t88 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t87, i32 0, i32 0
  store i64 %t84, i64* %t88
  %t89 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t87, i32 0, i32 1
  store i64 %t86, i64* %t89
  %t90 = bitcast { i64, i64 }* %t87 to i8*
  %t91 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_24 to i8*), i8* %t90, i32 0, i32* null)
  %t92 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t82, i32 0, i32 0
  store i8* %t91, i8** %t92
  %t93 = mul i64 %t81, 1
  %t94 = sdiv i64 %t93, 4
  %t95 = mul i64 %t81, 2
  %t96 = sdiv i64 %t95, 4
  %t97 = alloca { i64, i64 }
  %t98 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t97, i32 0, i32 0
  store i64 %t94, i64* %t98
  %t99 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t97, i32 0, i32 1
  store i64 %t96, i64* %t99
  %t100 = bitcast { i64, i64 }* %t97 to i8*
  %t101 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_24 to i8*), i8* %t100, i32 0, i32* null)
  %t102 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t82, i32 0, i32 1
  store i8* %t101, i8** %t102
  %t103 = mul i64 %t81, 2
  %t104 = sdiv i64 %t103, 4
  %t105 = mul i64 %t81, 3
  %t106 = sdiv i64 %t105, 4
  %t107 = alloca { i64, i64 }
  %t108 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t107, i32 0, i32 0
  store i64 %t104, i64* %t108
  %t109 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t107, i32 0, i32 1
  store i64 %t106, i64* %t109
  %t110 = bitcast { i64, i64 }* %t107 to i8*
  %t111 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_24 to i8*), i8* %t110, i32 0, i32* null)
  %t112 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t82, i32 0, i32 2
  store i8* %t111, i8** %t112
  %t113 = mul i64 %t81, 3
  %t114 = sdiv i64 %t113, 4
  %t115 = mul i64 %t81, 4
  %t116 = sdiv i64 %t115, 4
  %t117 = alloca { i64, i64 }
  %t118 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t117, i32 0, i32 0
  store i64 %t114, i64* %t118
  %t119 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t117, i32 0, i32 1
  store i64 %t116, i64* %t119
  %t120 = bitcast { i64, i64 }* %t117 to i8*
  %t121 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_24 to i8*), i8* %t120, i32 0, i32* null)
  %t122 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t82, i32 0, i32 3
  store i8* %t121, i8** %t122
  %t123 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t82, i32 0, i32 0
  %t124 = load i8*, i8** %t123
  %t125 = call i32 @WaitForSingleObject(i8* %t124, i32 -1)
  %t126 = call i32 @CloseHandle(i8* %t124)
  %t127 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t82, i32 0, i32 1
  %t128 = load i8*, i8** %t127
  %t129 = call i32 @WaitForSingleObject(i8* %t128, i32 -1)
  %t130 = call i32 @CloseHandle(i8* %t128)
  %t131 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t82, i32 0, i32 2
  %t132 = load i8*, i8** %t131
  %t133 = call i32 @WaitForSingleObject(i8* %t132, i32 -1)
  %t134 = call i32 @CloseHandle(i8* %t132)
  %t135 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t82, i32 0, i32 3
  %t136 = load i8*, i8** %t135
  %t137 = call i32 @WaitForSingleObject(i8* %t136, i32 -1)
  %t138 = call i32 @CloseHandle(i8* %t136)
  %t153 = load i64, i64* @arena.Enemies.count
  %t154 = alloca [4 x i8*]
  %t155 = mul i64 %t153, 0
  %t156 = sdiv i64 %t155, 4
  %t157 = mul i64 %t153, 1
  %t158 = sdiv i64 %t157, 4
  %t159 = alloca { i64, i64 }
  %t160 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t159, i32 0, i32 0
  store i64 %t156, i64* %t160
  %t161 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t159, i32 0, i32 1
  store i64 %t158, i64* %t161
  %t162 = bitcast { i64, i64 }* %t159 to i8*
  %t163 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_28 to i8*), i8* %t162, i32 0, i32* null)
  %t164 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t154, i32 0, i32 0
  store i8* %t163, i8** %t164
  %t165 = mul i64 %t153, 1
  %t166 = sdiv i64 %t165, 4
  %t167 = mul i64 %t153, 2
  %t168 = sdiv i64 %t167, 4
  %t169 = alloca { i64, i64 }
  %t170 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t169, i32 0, i32 0
  store i64 %t166, i64* %t170
  %t171 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t169, i32 0, i32 1
  store i64 %t168, i64* %t171
  %t172 = bitcast { i64, i64 }* %t169 to i8*
  %t173 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_28 to i8*), i8* %t172, i32 0, i32* null)
  %t174 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t154, i32 0, i32 1
  store i8* %t173, i8** %t174
  %t175 = mul i64 %t153, 2
  %t176 = sdiv i64 %t175, 4
  %t177 = mul i64 %t153, 3
  %t178 = sdiv i64 %t177, 4
  %t179 = alloca { i64, i64 }
  %t180 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t179, i32 0, i32 0
  store i64 %t176, i64* %t180
  %t181 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t179, i32 0, i32 1
  store i64 %t178, i64* %t181
  %t182 = bitcast { i64, i64 }* %t179 to i8*
  %t183 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_28 to i8*), i8* %t182, i32 0, i32* null)
  %t184 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t154, i32 0, i32 2
  store i8* %t183, i8** %t184
  %t185 = mul i64 %t153, 3
  %t186 = sdiv i64 %t185, 4
  %t187 = mul i64 %t153, 4
  %t188 = sdiv i64 %t187, 4
  %t189 = alloca { i64, i64 }
  %t190 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t189, i32 0, i32 0
  store i64 %t186, i64* %t190
  %t191 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t189, i32 0, i32 1
  store i64 %t188, i64* %t191
  %t192 = bitcast { i64, i64 }* %t189 to i8*
  %t193 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par_worker_28 to i8*), i8* %t192, i32 0, i32* null)
  %t194 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t154, i32 0, i32 3
  store i8* %t193, i8** %t194
  %t195 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t154, i32 0, i32 0
  %t196 = load i8*, i8** %t195
  %t197 = call i32 @WaitForSingleObject(i8* %t196, i32 -1)
  %t198 = call i32 @CloseHandle(i8* %t196)
  %t199 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t154, i32 0, i32 1
  %t200 = load i8*, i8** %t199
  %t201 = call i32 @WaitForSingleObject(i8* %t200, i32 -1)
  %t202 = call i32 @CloseHandle(i8* %t200)
  %t203 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t154, i32 0, i32 2
  %t204 = load i8*, i8** %t203
  %t205 = call i32 @WaitForSingleObject(i8* %t204, i32 -1)
  %t206 = call i32 @CloseHandle(i8* %t204)
  %t207 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t154, i32 0, i32 3
  %t208 = load i8*, i8** %t207
  %t209 = call i32 @WaitForSingleObject(i8* %t208, i32 -1)
  %t210 = call i32 @CloseHandle(i8* %t208)
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_24(i8* %argp) {
entry:
  %t66 = bitcast i8* %argp to { i64, i64 }*
  %t67 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t66, i32 0, i32 0
  %t68 = load i64, i64* %t67
  %t69 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t66, i32 0, i32 1
  %t70 = load i64, i64* %t69
  %t71 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t72 = alloca i64
  store i64 %t68, i64* %t72
  br label %par_cond_25
par_cond_25:
  %t73 = load i64, i64* %t72
  %t74 = icmp slt i64 %t73, %t70
  br i1 %t74, label %par_body_26, label %par_end_27
par_body_26:
  %t75 = getelementptr inbounds %Enemy, %Enemy* %t71, i64 %t73
  %t76 = getelementptr inbounds %Enemy, %Enemy* %t75, i32 0, i32 0
  %t77 = load i32, i32* %t76
  %t78 = sub i32 %t77, 1
  %t79 = getelementptr inbounds %Enemy, %Enemy* %t75, i32 0, i32 0
  store i32 %t78, i32* %t79
  %t80 = add i64 %t73, 1
  store i64 %t80, i64* %t72
  br label %par_cond_25
par_end_27:
  ret i32 0
}


define i32 @par_worker_28(i8* %argp) {
entry:
  %t139 = bitcast i8* %argp to { i64, i64 }*
  %t140 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t139, i32 0, i32 0
  %t141 = load i64, i64* %t140
  %t142 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t139, i32 0, i32 1
  %t143 = load i64, i64* %t142
  %t144 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t145 = alloca i64
  store i64 %t141, i64* %t145
  br label %par_cond_29
par_cond_29:
  %t146 = load i64, i64* %t145
  %t147 = icmp slt i64 %t146, %t143
  br i1 %t147, label %par_body_30, label %par_end_31
par_body_30:
  %t148 = getelementptr inbounds %Enemy, %Enemy* %t144, i64 %t146
  %t149 = getelementptr inbounds %Enemy, %Enemy* %t148, i32 0, i32 0
  %t150 = load i32, i32* %t149
  %t151 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t151, i32 %t150)
  %t152 = add i64 %t146, 1
  store i64 %t152, i64* %t145
  br label %par_cond_29
par_end_31:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [8 x i8] c"hp: %d\0A\00"
