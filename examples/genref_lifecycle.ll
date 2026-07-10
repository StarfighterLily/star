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
  %t31 = alloca %Entity
  %t32 = getelementptr inbounds %GenRef, %GenRef* %t21, i32 0, i32 0
  %t33 = load i32, i32* %t32
  %t34 = getelementptr inbounds %GenRef, %GenRef* %t21, i32 0, i32 1
  %t35 = load i32, i32* %t34
  %t36 = sext i32 %t33 to i64
  %t37 = icmp ult i64 %t36, 1024
  br i1 %t37, label %genref_check_10, label %genref_stale_12
genref_check_10:
  %t38 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t36
  %t39 = load i32, i32* %t38
  %t40 = icmp eq i32 %t35, %t39
  br i1 %t40, label %genref_ok_11, label %genref_stale_12
genref_ok_11:
  %t41 = load %Entity*, %Entity** @arena.Entities.data
  %t42 = getelementptr inbounds %Entity, %Entity* %t41, i64 %t36
  %t43 = load %Entity, %Entity* %t42
  br label %genref_end_13
genref_stale_12:
  br label %genref_end_13
genref_end_13:
  %t44 = phi %Entity [ %t43, %genref_ok_11 ], [ zeroinitializer, %genref_stale_12 ]
  store %Entity %t44, %Entity* %t31
  %t45 = getelementptr inbounds %Entity, %Entity* %t31, i32 0, i32 0
  %t46 = load i32, i32* %t45
  %t47 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t47, i32 %t46)
  %t48 = sext i32 0 to i64
  %t49 = icmp ult i64 %t48, 1024
  br i1 %t49, label %despawn_do_14, label %despawn_end_15
despawn_do_14:
  %t50 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t48
  %t51 = load i32, i32* %t50
  %t52 = and i32 %t51, 1
  %t53 = icmp eq i32 %t52, 1
  br i1 %t53, label %despawn_live_16, label %despawn_end_15
despawn_live_16:
  %t54 = add i32 %t51, 1
  store i32 %t54, i32* %t50
  %t55 = load i64, i64* @arena.Entities.free_top
  %t56 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t55
  store i64 %t48, i64* %t56
  %t57 = add i64 %t55, 1
  store i64 %t57, i64* @arena.Entities.free_top
  br label %despawn_end_15
despawn_end_15:
  %t58 = alloca %Entity
  %t59 = getelementptr inbounds %GenRef, %GenRef* %t21, i32 0, i32 0
  %t60 = load i32, i32* %t59
  %t61 = getelementptr inbounds %GenRef, %GenRef* %t21, i32 0, i32 1
  %t62 = load i32, i32* %t61
  %t63 = sext i32 %t60 to i64
  %t64 = icmp ult i64 %t63, 1024
  br i1 %t64, label %genref_check_17, label %genref_stale_19
genref_check_17:
  %t65 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t63
  %t66 = load i32, i32* %t65
  %t67 = icmp eq i32 %t62, %t66
  br i1 %t67, label %genref_ok_18, label %genref_stale_19
genref_ok_18:
  %t68 = load %Entity*, %Entity** @arena.Entities.data
  %t69 = getelementptr inbounds %Entity, %Entity* %t68, i64 %t63
  %t70 = load %Entity, %Entity* %t69
  br label %genref_end_20
genref_stale_19:
  br label %genref_end_20
genref_end_20:
  %t71 = phi %Entity [ %t70, %genref_ok_18 ], [ zeroinitializer, %genref_stale_19 ]
  store %Entity %t71, %Entity* %t58
  %t72 = getelementptr inbounds %Entity, %Entity* %t58, i32 0, i32 0
  %t73 = load i32, i32* %t72
  %t74 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t74, i32 %t73)
  ret void
}


; Global Constants
@.str.0 = private unnamed_addr constant [12 x i8] c"before: %d\0A\00"
@.str.1 = private unnamed_addr constant [11 x i8] c"after: %d\0A\00"
