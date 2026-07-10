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

%Point = type { i32, i32 }
%Projectile = type { i32, i32 }
%EnemyArena = type { %Point*, i64 }
@arena.EnemyArena.data = global %Point* null
@arena.EnemyArena.count = global i64 0
@arena.EnemyArena.gen = global [1024 x i32] zeroinitializer
@arena.EnemyArena.free = global [1024 x i64] zeroinitializer
@arena.EnemyArena.free_top = global i64 0

%ProjectileArena = type { %Projectile*, i64 }
@arena.ProjectileArena.data = global %Projectile* null
@arena.ProjectileArena.count = global i64 0
@arena.ProjectileArena.gen = global [1024 x i32] zeroinitializer
@arena.ProjectileArena.free = global [1024 x i64] zeroinitializer
@arena.ProjectileArena.free_top = global i64 0

define i32 @calculate_path(i32 %start_x, i32 %start_y) {
entry:
  %t0 = alloca i32
  store i32 %start_x, i32* %t0
  %t1 = alloca i32
  store i32 %start_y, i32* %t1
  %t2 = load i64, i64* @frame.off
  %t3 = load i64, i64* @frame.off
  %t4 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t5 = getelementptr inbounds i8, i8* %t4, i64 %t3
  %t6 = add i64 %t3, 8
  store i64 %t6, i64* @frame.off
  %t7 = bitcast i8* %t5 to %Point*
  %t8 = alloca %Point
  %t9 = getelementptr inbounds %Point, %Point* %t8, i32 0, i32 0
  store i32 0, i32* %t9
  %t10 = getelementptr inbounds %Point, %Point* %t8, i32 0, i32 1
  store i32 0, i32* %t10
  %t11 = load %Point, %Point* %t8
  store %Point %t11, %Point* %t7
  %t12 = load i64, i64* @frame.off
  %t13 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t14 = getelementptr inbounds i8, i8* %t13, i64 %t12
  %t15 = add i64 %t12, 8
  store i64 %t15, i64* @frame.off
  %t16 = bitcast i8* %t14 to %Point*
  %t17 = alloca %Point
  %t18 = load i32, i32* %t0
  %t19 = getelementptr inbounds %Point, %Point* %t17, i32 0, i32 0
  store i32 %t18, i32* %t19
  %t20 = load i32, i32* %t1
  %t21 = getelementptr inbounds %Point, %Point* %t17, i32 0, i32 1
  store i32 %t20, i32* %t21
  %t22 = load %Point, %Point* %t17
  store %Point %t22, %Point* %t16
  %t23 = getelementptr inbounds %Point, %Point* %t7, i32 0, i32 0
  %t24 = load i32, i32* %t23
  %t25 = getelementptr inbounds %Point, %Point* %t16, i32 0, i32 1
  %t26 = load i32, i32* %t25
  %t27 = add i32 %t24, %t26
  store i64 %t2, i64* @frame.off
  ret i32 %t27
}

define i32 @spawn_enemy(i32 %x, i32 %y) {
entry:
  %t0 = alloca i32
  store i32 %x, i32* %t0
  %t1 = alloca i32
  store i32 %y, i32* %t1
  %t2 = load i32, i32* %t0
  ret i32 %t2
}

define i32 @spawn_projectile(i32 %x, i32 %y) {
entry:
  %t0 = alloca i32
  store i32 %x, i32* %t0
  %t1 = alloca i32
  store i32 %y, i32* %t1
  %t2 = load i32, i32* %t1
  ret i32 %t2
}

define %GenRef @create_entity_reference(i32 %idx) {
entry:
  %t0 = alloca i32
  store i32 %idx, i32* %t0
  %t1 = load i32, i32* %t0
  %t2 = sext i32 %t1 to i64
  %t3 = icmp ult i64 %t2, 1024
  br i1 %t3, label %genref_create_ok_0, label %genref_create_oob_1
genref_create_ok_0:
  %t4 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.EnemyArena.gen, i64 0, i64 %t2
  %t5 = load i32, i32* %t4
  br label %genref_create_end_2
genref_create_oob_1:
  br label %genref_create_end_2
genref_create_end_2:
  %t6 = phi i32 [ %t5, %genref_create_ok_0 ], [ 0, %genref_create_oob_1 ]
  %t7 = alloca %GenRef
  %t8 = getelementptr inbounds %GenRef, %GenRef* %t7, i32 0, i32 0
  store i32 %t1, i32* %t8
  %t9 = getelementptr inbounds %GenRef, %GenRef* %t7, i32 0, i32 1
  store i32 %t6, i32* %t9
  %t10 = load %GenRef, %GenRef* %t7
  ret %GenRef %t10
}

define i32 @follow_reference(%GenRef %gen_ref) {
entry:
  %t0 = alloca %GenRef
  store %GenRef %gen_ref, %GenRef* %t0
  %t1 = getelementptr inbounds %GenRef, %GenRef* %t0, i32 0, i32 0
  %t2 = load i32, i32* %t1
  %t3 = getelementptr inbounds %GenRef, %GenRef* %t0, i32 0, i32 1
  %t4 = load i32, i32* %t3
  %t5 = sext i32 %t2 to i64
  %t6 = icmp ult i64 %t5, 1024
  br i1 %t6, label %genref_check_3, label %genref_stale_5
genref_check_3:
  %t7 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.EnemyArena.gen, i64 0, i64 %t5
  %t8 = load i32, i32* %t7
  %t9 = icmp eq i32 %t4, %t8
  br i1 %t9, label %genref_ok_4, label %genref_stale_5
genref_ok_4:
  %t10 = load %Point*, %Point** @arena.EnemyArena.data
  %t11 = getelementptr inbounds %Point, %Point* %t10, i64 %t5
  %t12 = load %Point, %Point* %t11
  br label %genref_end_6
genref_stale_5:
  br label %genref_end_6
genref_end_6:
  %t13 = phi %Point [ %t12, %genref_ok_4 ], [ zeroinitializer, %genref_stale_5 ]
  %t14 = alloca %Point
  store %Point %t13, %Point* %t14
  %t15 = getelementptr inbounds %Point, %Point* %t14, i32 0, i32 0
  %t16 = load i32, i32* %t15
  ret i32 %t16
}

define void @game_tick() {
entry:
  %t0 = load i64, i64* @frame.off
  %t1 = load %Point*, %Point** @arena.EnemyArena.data
  %t2 = icmp eq %Point* %t1, null
  br i1 %t2, label %spawn_init_7, label %spawn_ready_8
spawn_init_7:
  %t3 = call i8* @malloc(i64 8192)
  %t4 = bitcast i8* %t3 to %Point*
  store %Point* %t4, %Point** @arena.EnemyArena.data
  br label %spawn_ready_8
spawn_ready_8:
  %t5 = load %Point*, %Point** @arena.EnemyArena.data
  %t6 = load i64, i64* @arena.EnemyArena.free_top
  %t7 = icmp sgt i64 %t6, 0
  br i1 %t7, label %spawn_reuse_9, label %spawn_grow_10
spawn_reuse_9:
  %t8 = sub i64 %t6, 1
  store i64 %t8, i64* @arena.EnemyArena.free_top
  %t9 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.EnemyArena.free, i64 0, i64 %t8
  %t10 = load i64, i64* %t9
  br label %spawn_store_11
spawn_grow_10:
  %t11 = load i64, i64* @arena.EnemyArena.count
  %t12 = icmp slt i64 %t11, 1024
  br i1 %t12, label %spawn_grow_ok_13, label %spawn_end_12
spawn_grow_ok_13:
  %t13 = add i64 %t11, 1
  store i64 %t13, i64* @arena.EnemyArena.count
  br label %spawn_store_11
spawn_store_11:
  %t14 = phi i64 [ %t10, %spawn_reuse_9 ], [ %t11, %spawn_grow_ok_13 ]
  %t15 = alloca %Point
  %t16 = getelementptr inbounds %Point, %Point* %t15, i32 0, i32 0
  store i32 42, i32* %t16
  %t17 = getelementptr inbounds %Point, %Point* %t15, i32 0, i32 1
  store i32 0, i32* %t17
  %t18 = load %Point, %Point* %t15
  %t19 = getelementptr inbounds %Point, %Point* %t5, i64 %t14
  store %Point %t18, %Point* %t19
  %t20 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.EnemyArena.gen, i64 0, i64 %t14
  %t21 = load i32, i32* %t20
  %t22 = add i32 %t21, 1
  store i32 %t22, i32* %t20
  br label %spawn_end_12
spawn_end_12:
  %t23 = load i64, i64* @frame.off
  %t24 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t25 = getelementptr inbounds i8, i8* %t24, i64 %t23
  %t26 = add i64 %t23, 4
  store i64 %t26, i64* @frame.off
  %t27 = bitcast i8* %t25 to i32*
  store i32 0, i32* %t27
  %t28 = load i64, i64* @frame.off
  %t29 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t30 = getelementptr inbounds i8, i8* %t29, i64 %t28
  %t31 = add i64 %t28, 8
  store i64 %t31, i64* @frame.off
  %t32 = bitcast i8* %t30 to %GenRef*
  %t33 = call %GenRef @create_entity_reference(i32 0)
  store %GenRef %t33, %GenRef* %t32
  %t34 = load i32, i32* %t27
  %t35 = load %GenRef, %GenRef* %t32
  %t36 = call i32 @follow_reference(%GenRef %t35)
  %t37 = add i32 %t34, %t36
  store i64 %t0, i64* @frame.off
  ret void
}

define void @main() {
entry:
  %t0 = alloca i32
  %t1 = call i32 @calculate_path(i32 5, i32 10)
  store i32 %t1, i32* %t0
  %t2 = load i32, i32* %t0
  %t3 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t3, i32 %t2)
  call void @game_tick()
  ret void
}


; Global Constants
@.str.0 = private unnamed_addr constant [29 x i8] c"Path calculation result: %d\0A\00"
