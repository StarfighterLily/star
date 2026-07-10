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

%Entity = type { i32 }
%Entities = type { %Entity*, i64 }
@arena.Entities.data = global %Entity* null
@arena.Entities.count = global i64 0
@arena.Entities.gen = global [1024 x i32] zeroinitializer
@arena.Entities.free = global [1024 x i64] zeroinitializer
@arena.Entities.free_top = global i64 0

define void @main() {
entry:
  %t0 = load %Entity*, %Entity** @arena.Entities.data
  %t1 = icmp eq %Entity* %t0, null
  br i1 %t1, label %spawn_init_0, label %spawn_ready_1
spawn_init_0:
  %t2 = call i8* @malloc(i64 4096)
  %t3 = bitcast i8* %t2 to %Entity*
  store %Entity* %t3, %Entity** @arena.Entities.data
  br label %spawn_ready_1
spawn_ready_1:
  %t4 = load %Entity*, %Entity** @arena.Entities.data
  %t5 = load i64, i64* @arena.Entities.free_top
  %t6 = icmp sgt i64 %t5, 0
  br i1 %t6, label %spawn_reuse_2, label %spawn_grow_3
spawn_reuse_2:
  %t7 = sub i64 %t5, 1
  store i64 %t7, i64* @arena.Entities.free_top
  %t8 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t7
  %t9 = load i64, i64* %t8
  br label %spawn_store_4
spawn_grow_3:
  %t10 = load i64, i64* @arena.Entities.count
  %t11 = icmp slt i64 %t10, 1024
  br i1 %t11, label %spawn_grow_ok_6, label %spawn_end_5
spawn_grow_ok_6:
  %t12 = add i64 %t10, 1
  store i64 %t12, i64* @arena.Entities.count
  br label %spawn_store_4
spawn_store_4:
  %t13 = phi i64 [ %t9, %spawn_reuse_2 ], [ %t10, %spawn_grow_ok_6 ]
  %t14 = alloca %Entity
  %t15 = getelementptr inbounds %Entity, %Entity* %t14, i32 0, i32 0
  store i32 100, i32* %t15
  %t16 = load %Entity, %Entity* %t14
  %t17 = getelementptr inbounds %Entity, %Entity* %t4, i64 %t13
  store %Entity %t16, %Entity* %t17
  %t18 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t13
  %t19 = load i32, i32* %t18
  %t20 = add i32 %t19, 1
  store i32 %t20, i32* %t18
  br label %spawn_end_5
spawn_end_5:
  %t21 = sext i32 0 to i64
  %t22 = icmp ult i64 %t21, 1024
  br i1 %t22, label %despawn_do_7, label %despawn_end_8
despawn_do_7:
  %t23 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t21
  %t24 = load i32, i32* %t23
  %t25 = and i32 %t24, 1
  %t26 = icmp eq i32 %t25, 1
  br i1 %t26, label %despawn_live_9, label %despawn_end_8
despawn_live_9:
  %t27 = add i32 %t24, 1
  store i32 %t27, i32* %t23
  %t28 = load i64, i64* @arena.Entities.free_top
  %t29 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t28
  store i64 %t21, i64* %t29
  %t30 = add i64 %t28, 1
  store i64 %t30, i64* @arena.Entities.free_top
  br label %despawn_end_8
despawn_end_8:
  %t31 = sext i32 0 to i64
  %t32 = icmp ult i64 %t31, 1024
  br i1 %t32, label %despawn_do_10, label %despawn_end_11
despawn_do_10:
  %t33 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t31
  %t34 = load i32, i32* %t33
  %t35 = and i32 %t34, 1
  %t36 = icmp eq i32 %t35, 1
  br i1 %t36, label %despawn_live_12, label %despawn_end_11
despawn_live_12:
  %t37 = add i32 %t34, 1
  store i32 %t37, i32* %t33
  %t38 = load i64, i64* @arena.Entities.free_top
  %t39 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t38
  store i64 %t31, i64* %t39
  %t40 = add i64 %t38, 1
  store i64 %t40, i64* @arena.Entities.free_top
  br label %despawn_end_11
despawn_end_11:
  %t41 = load %Entity*, %Entity** @arena.Entities.data
  %t42 = icmp eq %Entity* %t41, null
  br i1 %t42, label %spawn_init_13, label %spawn_ready_14
spawn_init_13:
  %t43 = call i8* @malloc(i64 4096)
  %t44 = bitcast i8* %t43 to %Entity*
  store %Entity* %t44, %Entity** @arena.Entities.data
  br label %spawn_ready_14
spawn_ready_14:
  %t45 = load %Entity*, %Entity** @arena.Entities.data
  %t46 = load i64, i64* @arena.Entities.free_top
  %t47 = icmp sgt i64 %t46, 0
  br i1 %t47, label %spawn_reuse_15, label %spawn_grow_16
spawn_reuse_15:
  %t48 = sub i64 %t46, 1
  store i64 %t48, i64* @arena.Entities.free_top
  %t49 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t48
  %t50 = load i64, i64* %t49
  br label %spawn_store_17
spawn_grow_16:
  %t51 = load i64, i64* @arena.Entities.count
  %t52 = icmp slt i64 %t51, 1024
  br i1 %t52, label %spawn_grow_ok_19, label %spawn_end_18
spawn_grow_ok_19:
  %t53 = add i64 %t51, 1
  store i64 %t53, i64* @arena.Entities.count
  br label %spawn_store_17
spawn_store_17:
  %t54 = phi i64 [ %t50, %spawn_reuse_15 ], [ %t51, %spawn_grow_ok_19 ]
  %t55 = alloca %Entity
  %t56 = getelementptr inbounds %Entity, %Entity* %t55, i32 0, i32 0
  store i32 200, i32* %t56
  %t57 = load %Entity, %Entity* %t55
  %t58 = getelementptr inbounds %Entity, %Entity* %t45, i64 %t54
  store %Entity %t57, %Entity* %t58
  %t59 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t54
  %t60 = load i32, i32* %t59
  %t61 = add i32 %t60, 1
  store i32 %t61, i32* %t59
  br label %spawn_end_18
spawn_end_18:
  %t62 = load %Entity*, %Entity** @arena.Entities.data
  %t63 = icmp eq %Entity* %t62, null
  br i1 %t63, label %spawn_init_20, label %spawn_ready_21
spawn_init_20:
  %t64 = call i8* @malloc(i64 4096)
  %t65 = bitcast i8* %t64 to %Entity*
  store %Entity* %t65, %Entity** @arena.Entities.data
  br label %spawn_ready_21
spawn_ready_21:
  %t66 = load %Entity*, %Entity** @arena.Entities.data
  %t67 = load i64, i64* @arena.Entities.free_top
  %t68 = icmp sgt i64 %t67, 0
  br i1 %t68, label %spawn_reuse_22, label %spawn_grow_23
spawn_reuse_22:
  %t69 = sub i64 %t67, 1
  store i64 %t69, i64* @arena.Entities.free_top
  %t70 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t69
  %t71 = load i64, i64* %t70
  br label %spawn_store_24
spawn_grow_23:
  %t72 = load i64, i64* @arena.Entities.count
  %t73 = icmp slt i64 %t72, 1024
  br i1 %t73, label %spawn_grow_ok_26, label %spawn_end_25
spawn_grow_ok_26:
  %t74 = add i64 %t72, 1
  store i64 %t74, i64* @arena.Entities.count
  br label %spawn_store_24
spawn_store_24:
  %t75 = phi i64 [ %t71, %spawn_reuse_22 ], [ %t72, %spawn_grow_ok_26 ]
  %t76 = alloca %Entity
  %t77 = getelementptr inbounds %Entity, %Entity* %t76, i32 0, i32 0
  store i32 300, i32* %t77
  %t78 = load %Entity, %Entity* %t76
  %t79 = getelementptr inbounds %Entity, %Entity* %t66, i64 %t75
  store %Entity %t78, %Entity* %t79
  %t80 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t75
  %t81 = load i32, i32* %t80
  %t82 = add i32 %t81, 1
  store i32 %t82, i32* %t80
  br label %spawn_end_25
spawn_end_25:
  %t83 = alloca %GenRef
  %t84 = sext i32 0 to i64
  %t85 = icmp ult i64 %t84, 1024
  br i1 %t85, label %genref_create_ok_27, label %genref_create_oob_28
genref_create_ok_27:
  %t86 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t84
  %t87 = load i32, i32* %t86
  br label %genref_create_end_29
genref_create_oob_28:
  br label %genref_create_end_29
genref_create_end_29:
  %t88 = phi i32 [ %t87, %genref_create_ok_27 ], [ 0, %genref_create_oob_28 ]
  %t89 = alloca %GenRef
  %t90 = getelementptr inbounds %GenRef, %GenRef* %t89, i32 0, i32 0
  store i32 0, i32* %t90
  %t91 = getelementptr inbounds %GenRef, %GenRef* %t89, i32 0, i32 1
  store i32 %t88, i32* %t91
  %t92 = load %GenRef, %GenRef* %t89
  store %GenRef %t92, %GenRef* %t83
  %t93 = alloca %GenRef
  %t94 = sext i32 1 to i64
  %t95 = icmp ult i64 %t94, 1024
  br i1 %t95, label %genref_create_ok_30, label %genref_create_oob_31
genref_create_ok_30:
  %t96 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t94
  %t97 = load i32, i32* %t96
  br label %genref_create_end_32
genref_create_oob_31:
  br label %genref_create_end_32
genref_create_end_32:
  %t98 = phi i32 [ %t97, %genref_create_ok_30 ], [ 0, %genref_create_oob_31 ]
  %t99 = alloca %GenRef
  %t100 = getelementptr inbounds %GenRef, %GenRef* %t99, i32 0, i32 0
  store i32 1, i32* %t100
  %t101 = getelementptr inbounds %GenRef, %GenRef* %t99, i32 0, i32 1
  store i32 %t98, i32* %t101
  %t102 = load %GenRef, %GenRef* %t99
  store %GenRef %t102, %GenRef* %t93
  %t103 = getelementptr inbounds %GenRef, %GenRef* %t83, i32 0, i32 0
  %t104 = load i32, i32* %t103
  %t105 = getelementptr inbounds %GenRef, %GenRef* %t83, i32 0, i32 1
  %t106 = load i32, i32* %t105
  %t107 = sext i32 %t104 to i64
  %t108 = icmp ult i64 %t107, 1024
  br i1 %t108, label %genref_check_33, label %genref_stale_35
genref_check_33:
  %t109 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t107
  %t110 = load i32, i32* %t109
  %t111 = icmp eq i32 %t106, %t110
  br i1 %t111, label %genref_ok_34, label %genref_stale_35
genref_ok_34:
  %t112 = load %Entity*, %Entity** @arena.Entities.data
  %t113 = getelementptr inbounds %Entity, %Entity* %t112, i64 %t107
  %t114 = load %Entity, %Entity* %t113
  br label %genref_end_36
genref_stale_35:
  br label %genref_end_36
genref_end_36:
  %t115 = phi %Entity [ %t114, %genref_ok_34 ], [ zeroinitializer, %genref_stale_35 ]
  %t116 = alloca %Entity
  store %Entity %t115, %Entity* %t116
  %t117 = getelementptr inbounds %Entity, %Entity* %t116, i32 0, i32 0
  %t118 = load i32, i32* %t117
  %t119 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t119, i32 %t118)
  %t120 = getelementptr inbounds %GenRef, %GenRef* %t93, i32 0, i32 0
  %t121 = load i32, i32* %t120
  %t122 = getelementptr inbounds %GenRef, %GenRef* %t93, i32 0, i32 1
  %t123 = load i32, i32* %t122
  %t124 = sext i32 %t121 to i64
  %t125 = icmp ult i64 %t124, 1024
  br i1 %t125, label %genref_check_37, label %genref_stale_39
genref_check_37:
  %t126 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t124
  %t127 = load i32, i32* %t126
  %t128 = icmp eq i32 %t123, %t127
  br i1 %t128, label %genref_ok_38, label %genref_stale_39
genref_ok_38:
  %t129 = load %Entity*, %Entity** @arena.Entities.data
  %t130 = getelementptr inbounds %Entity, %Entity* %t129, i64 %t124
  %t131 = load %Entity, %Entity* %t130
  br label %genref_end_40
genref_stale_39:
  br label %genref_end_40
genref_end_40:
  %t132 = phi %Entity [ %t131, %genref_ok_38 ], [ zeroinitializer, %genref_stale_39 ]
  %t133 = alloca %Entity
  store %Entity %t132, %Entity* %t133
  %t134 = getelementptr inbounds %Entity, %Entity* %t133, i32 0, i32 0
  %t135 = load i32, i32* %t134
  %t136 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t136, i32 %t135)
  ret void
}


; Global Constants
@.str.0 = private unnamed_addr constant [11 x i8] c"slot0: %d\0A\00"
@.str.1 = private unnamed_addr constant [11 x i8] c"slot1: %d\0A\00"
