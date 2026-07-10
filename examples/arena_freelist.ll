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
  %t21 = alloca %GenRef
  %t22 = sext i32 0 to i64
  %t23 = icmp ult i64 %t22, 1024
  br i1 %t23, label %genref_create_ok_7, label %genref_create_oob_8
genref_create_ok_7:
  %t24 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t22
  %t25 = load i32, i32* %t24
  br label %genref_create_end_9
genref_create_oob_8:
  br label %genref_create_end_9
genref_create_end_9:
  %t26 = phi i32 [ %t25, %genref_create_ok_7 ], [ 0, %genref_create_oob_8 ]
  %t27 = alloca %GenRef
  %t28 = getelementptr inbounds %GenRef, %GenRef* %t27, i32 0, i32 0
  store i32 0, i32* %t28
  %t29 = getelementptr inbounds %GenRef, %GenRef* %t27, i32 0, i32 1
  store i32 %t26, i32* %t29
  %t30 = load %GenRef, %GenRef* %t27
  store %GenRef %t30, %GenRef* %t21
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
  %t62 = alloca %GenRef
  %t63 = sext i32 0 to i64
  %t64 = icmp ult i64 %t63, 1024
  br i1 %t64, label %genref_create_ok_20, label %genref_create_oob_21
genref_create_ok_20:
  %t65 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t63
  %t66 = load i32, i32* %t65
  br label %genref_create_end_22
genref_create_oob_21:
  br label %genref_create_end_22
genref_create_end_22:
  %t67 = phi i32 [ %t66, %genref_create_ok_20 ], [ 0, %genref_create_oob_21 ]
  %t68 = alloca %GenRef
  %t69 = getelementptr inbounds %GenRef, %GenRef* %t68, i32 0, i32 0
  store i32 0, i32* %t69
  %t70 = getelementptr inbounds %GenRef, %GenRef* %t68, i32 0, i32 1
  store i32 %t67, i32* %t70
  %t71 = load %GenRef, %GenRef* %t68
  store %GenRef %t71, %GenRef* %t62
  %t72 = alloca %Entity
  %t73 = getelementptr inbounds %GenRef, %GenRef* %t21, i32 0, i32 0
  %t74 = load i32, i32* %t73
  %t75 = getelementptr inbounds %GenRef, %GenRef* %t21, i32 0, i32 1
  %t76 = load i32, i32* %t75
  %t77 = sext i32 %t74 to i64
  %t78 = icmp ult i64 %t77, 1024
  br i1 %t78, label %genref_check_23, label %genref_stale_25
genref_check_23:
  %t79 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t77
  %t80 = load i32, i32* %t79
  %t81 = icmp eq i32 %t76, %t80
  br i1 %t81, label %genref_ok_24, label %genref_stale_25
genref_ok_24:
  %t82 = load %Entity*, %Entity** @arena.Entities.data
  %t83 = getelementptr inbounds %Entity, %Entity* %t82, i64 %t77
  %t84 = load %Entity, %Entity* %t83
  br label %genref_end_26
genref_stale_25:
  br label %genref_end_26
genref_end_26:
  %t85 = phi %Entity [ %t84, %genref_ok_24 ], [ zeroinitializer, %genref_stale_25 ]
  store %Entity %t85, %Entity* %t72
  %t86 = alloca %Entity
  %t87 = getelementptr inbounds %GenRef, %GenRef* %t62, i32 0, i32 0
  %t88 = load i32, i32* %t87
  %t89 = getelementptr inbounds %GenRef, %GenRef* %t62, i32 0, i32 1
  %t90 = load i32, i32* %t89
  %t91 = sext i32 %t88 to i64
  %t92 = icmp ult i64 %t91, 1024
  br i1 %t92, label %genref_check_27, label %genref_stale_29
genref_check_27:
  %t93 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t91
  %t94 = load i32, i32* %t93
  %t95 = icmp eq i32 %t90, %t94
  br i1 %t95, label %genref_ok_28, label %genref_stale_29
genref_ok_28:
  %t96 = load %Entity*, %Entity** @arena.Entities.data
  %t97 = getelementptr inbounds %Entity, %Entity* %t96, i64 %t91
  %t98 = load %Entity, %Entity* %t97
  br label %genref_end_30
genref_stale_29:
  br label %genref_end_30
genref_end_30:
  %t99 = phi %Entity [ %t98, %genref_ok_28 ], [ zeroinitializer, %genref_stale_29 ]
  store %Entity %t99, %Entity* %t86
  %t100 = getelementptr inbounds %Entity, %Entity* %t72, i32 0, i32 0
  %t101 = load i32, i32* %t100
  %t102 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t102, i32 %t101)
  %t103 = getelementptr inbounds %Entity, %Entity* %t86, i32 0, i32 0
  %t104 = load i32, i32* %t103
  %t105 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t105, i32 %t104)
  ret void
}


; Global Constants
@.str.0 = private unnamed_addr constant [13 x i8] c"via_old: %d\0A\00"
@.str.1 = private unnamed_addr constant [13 x i8] c"via_new: %d\0A\00"
