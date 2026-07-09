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
  %t5 = load i64, i64* @arena.Entities.count
  %t6 = icmp slt i64 %t5, 1024
  br i1 %t6, label %spawn_store_2, label %spawn_end_3
spawn_store_2:
  %t7 = alloca %Entity
  %t8 = getelementptr inbounds %Entity, %Entity* %t7, i32 0, i32 0
  store i32 100, i32* %t8
  %t9 = load %Entity, %Entity* %t7
  %t10 = getelementptr inbounds %Entity, %Entity* %t4, i64 %t5
  store %Entity %t9, %Entity* %t10
  %t11 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t5
  store i32 1, i32* %t11
  %t12 = add i64 %t5, 1
  store i64 %t12, i64* @arena.Entities.count
  br label %spawn_end_3
spawn_end_3:
  %t13 = alloca %GenRef
  %t14 = sext i32 0 to i64
  %t15 = icmp ult i64 %t14, 1024
  br i1 %t15, label %genref_create_ok_4, label %genref_create_oob_5
genref_create_ok_4:
  %t16 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t14
  %t17 = load i32, i32* %t16
  br label %genref_create_end_6
genref_create_oob_5:
  br label %genref_create_end_6
genref_create_end_6:
  %t18 = phi i32 [ %t17, %genref_create_ok_4 ], [ 0, %genref_create_oob_5 ]
  %t19 = alloca %GenRef
  %t20 = getelementptr inbounds %GenRef, %GenRef* %t19, i32 0, i32 0
  store i32 0, i32* %t20
  %t21 = getelementptr inbounds %GenRef, %GenRef* %t19, i32 0, i32 1
  store i32 %t18, i32* %t21
  %t22 = load %GenRef, %GenRef* %t19
  store %GenRef %t22, %GenRef* %t13
  %t23 = alloca %Entity
  %t24 = getelementptr inbounds %GenRef, %GenRef* %t13, i32 0, i32 0
  %t25 = load i32, i32* %t24
  %t26 = getelementptr inbounds %GenRef, %GenRef* %t13, i32 0, i32 1
  %t27 = load i32, i32* %t26
  %t28 = sext i32 %t25 to i64
  %t29 = icmp ult i64 %t28, 1024
  br i1 %t29, label %genref_check_7, label %genref_stale_9
genref_check_7:
  %t30 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t28
  %t31 = load i32, i32* %t30
  %t32 = icmp eq i32 %t27, %t31
  br i1 %t32, label %genref_ok_8, label %genref_stale_9
genref_ok_8:
  %t33 = load %Entity*, %Entity** @arena.Entities.data
  %t34 = getelementptr inbounds %Entity, %Entity* %t33, i64 %t28
  %t35 = load %Entity, %Entity* %t34
  br label %genref_end_10
genref_stale_9:
  br label %genref_end_10
genref_end_10:
  %t36 = phi %Entity [ %t35, %genref_ok_8 ], [ zeroinitializer, %genref_stale_9 ]
  store %Entity %t36, %Entity* %t23
  %t37 = getelementptr inbounds %Entity, %Entity* %t23, i32 0, i32 0
  %t38 = load i32, i32* %t37
  %t39 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t39, i32 %t38)
  %t40 = sext i32 0 to i64
  %t41 = icmp ult i64 %t40, 1024
  br i1 %t41, label %despawn_do_11, label %despawn_end_12
despawn_do_11:
  %t42 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t40
  %t43 = load i32, i32* %t42
  %t44 = add i32 %t43, 1
  store i32 %t44, i32* %t42
  br label %despawn_end_12
despawn_end_12:
  %t45 = alloca %Entity
  %t46 = getelementptr inbounds %GenRef, %GenRef* %t13, i32 0, i32 0
  %t47 = load i32, i32* %t46
  %t48 = getelementptr inbounds %GenRef, %GenRef* %t13, i32 0, i32 1
  %t49 = load i32, i32* %t48
  %t50 = sext i32 %t47 to i64
  %t51 = icmp ult i64 %t50, 1024
  br i1 %t51, label %genref_check_13, label %genref_stale_15
genref_check_13:
  %t52 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t50
  %t53 = load i32, i32* %t52
  %t54 = icmp eq i32 %t49, %t53
  br i1 %t54, label %genref_ok_14, label %genref_stale_15
genref_ok_14:
  %t55 = load %Entity*, %Entity** @arena.Entities.data
  %t56 = getelementptr inbounds %Entity, %Entity* %t55, i64 %t50
  %t57 = load %Entity, %Entity* %t56
  br label %genref_end_16
genref_stale_15:
  br label %genref_end_16
genref_end_16:
  %t58 = phi %Entity [ %t57, %genref_ok_14 ], [ zeroinitializer, %genref_stale_15 ]
  store %Entity %t58, %Entity* %t45
  %t59 = getelementptr inbounds %Entity, %Entity* %t45, i32 0, i32 0
  %t60 = load i32, i32* %t59
  %t61 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t61, i32 %t60)
  ret void
}


; Global Constants
@.str.0 = private unnamed_addr constant [12 x i8] c"before: %d\0A\00"
@.str.1 = private unnamed_addr constant [11 x i8] c"after: %d\0A\00"
