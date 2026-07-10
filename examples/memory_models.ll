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
  %t4 = add i64 %t3, 8
  %t5 = icmp ugt i64 %t4, 4096
  br i1 %t5, label %frame_alloc_fail_0, label %frame_alloc_ok_1
frame_alloc_fail_0:
  %t6 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t6)
  call void @exit(i32 1)
  unreachable
frame_alloc_ok_1:
  store i64 %t4, i64* @frame.off
  %t7 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t8 = getelementptr inbounds i8, i8* %t7, i64 %t3
  %t9 = bitcast i8* %t8 to %Point*
  %t10 = alloca %Point
  %t11 = getelementptr inbounds %Point, %Point* %t10, i32 0, i32 0
  store i32 0, i32* %t11
  %t12 = getelementptr inbounds %Point, %Point* %t10, i32 0, i32 1
  store i32 0, i32* %t12
  %t13 = load %Point, %Point* %t10
  store %Point %t13, %Point* %t9
  %t14 = load i64, i64* @frame.off
  %t15 = add i64 %t14, 8
  %t16 = icmp ugt i64 %t15, 4096
  br i1 %t16, label %frame_alloc_fail_2, label %frame_alloc_ok_3
frame_alloc_fail_2:
  %t17 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t17)
  call void @exit(i32 1)
  unreachable
frame_alloc_ok_3:
  store i64 %t15, i64* @frame.off
  %t18 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t19 = getelementptr inbounds i8, i8* %t18, i64 %t14
  %t20 = bitcast i8* %t19 to %Point*
  %t21 = alloca %Point
  %t22 = load i32, i32* %t0
  %t23 = getelementptr inbounds %Point, %Point* %t21, i32 0, i32 0
  store i32 %t22, i32* %t23
  %t24 = load i32, i32* %t1
  %t25 = getelementptr inbounds %Point, %Point* %t21, i32 0, i32 1
  store i32 %t24, i32* %t25
  %t26 = load %Point, %Point* %t21
  store %Point %t26, %Point* %t20
  %t27 = getelementptr inbounds %Point, %Point* %t9, i32 0, i32 0
  %t28 = load i32, i32* %t27
  %t29 = getelementptr inbounds %Point, %Point* %t20, i32 0, i32 1
  %t30 = load i32, i32* %t29
  %t31 = add i32 %t28, %t30
  store i64 %t2, i64* @frame.off
  ret i32 %t31
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
  br i1 %t3, label %genref_create_ok_4, label %genref_create_oob_5
genref_create_ok_4:
  %t4 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.EnemyArena.gen, i64 0, i64 %t2
  %t5 = load i32, i32* %t4
  br label %genref_create_end_6
genref_create_oob_5:
  br label %genref_create_end_6
genref_create_end_6:
  %t6 = phi i32 [ %t5, %genref_create_ok_4 ], [ 0, %genref_create_oob_5 ]
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
  br i1 %t6, label %genref_check_7, label %genref_stale_9
genref_check_7:
  %t7 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.EnemyArena.gen, i64 0, i64 %t5
  %t8 = load i32, i32* %t7
  %t9 = icmp eq i32 %t4, %t8
  %t10 = and i32 %t8, 1
  %t11 = icmp eq i32 %t10, 1
  %t12 = and i1 %t9, %t11
  br i1 %t12, label %genref_ok_8, label %genref_stale_9
genref_ok_8:
  %t13 = load %Point*, %Point** @arena.EnemyArena.data
  %t14 = getelementptr inbounds %Point, %Point* %t13, i64 %t5
  %t15 = load %Point, %Point* %t14
  br label %genref_end_10
genref_stale_9:
  br label %genref_end_10
genref_end_10:
  %t16 = phi %Point [ %t15, %genref_ok_8 ], [ zeroinitializer, %genref_stale_9 ]
  %t17 = alloca %Point
  store %Point %t16, %Point* %t17
  %t18 = getelementptr inbounds %Point, %Point* %t17, i32 0, i32 0
  %t19 = load i32, i32* %t18
  ret i32 %t19
}

define void @game_tick() {
entry:
  %t0 = load i64, i64* @frame.off
  %t1 = load %Point*, %Point** @arena.EnemyArena.data
  %t2 = icmp eq %Point* %t1, null
  br i1 %t2, label %spawn_init_11, label %spawn_ready_12
spawn_init_11:
  %t3 = call i8* @malloc(i64 8192)
  %t4 = bitcast i8* %t3 to %Point*
  store %Point* %t4, %Point** @arena.EnemyArena.data
  br label %spawn_ready_12
spawn_ready_12:
  %t5 = load %Point*, %Point** @arena.EnemyArena.data
  %t6 = load i64, i64* @arena.EnemyArena.free_top
  %t7 = icmp sgt i64 %t6, 0
  br i1 %t7, label %spawn_reuse_13, label %spawn_grow_14
spawn_reuse_13:
  %t8 = sub i64 %t6, 1
  store i64 %t8, i64* @arena.EnemyArena.free_top
  %t9 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.EnemyArena.free, i64 0, i64 %t8
  %t10 = load i64, i64* %t9
  br label %spawn_store_15
spawn_grow_14:
  %t11 = load i64, i64* @arena.EnemyArena.count
  %t12 = icmp slt i64 %t11, 1024
  br i1 %t12, label %spawn_grow_ok_17, label %spawn_capacity_warn_18
spawn_capacity_warn_18:
  %t13 = getelementptr inbounds [88 x i8], [88 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t13)
  br label %spawn_end_16
spawn_grow_ok_17:
  %t14 = add i64 %t11, 1
  store i64 %t14, i64* @arena.EnemyArena.count
  br label %spawn_store_15
spawn_store_15:
  %t15 = phi i64 [ %t10, %spawn_reuse_13 ], [ %t11, %spawn_grow_ok_17 ]
  %t16 = alloca %Point
  %t17 = getelementptr inbounds %Point, %Point* %t16, i32 0, i32 0
  store i32 42, i32* %t17
  %t18 = getelementptr inbounds %Point, %Point* %t16, i32 0, i32 1
  store i32 0, i32* %t18
  %t19 = load %Point, %Point* %t16
  %t20 = getelementptr inbounds %Point, %Point* %t5, i64 %t15
  store %Point %t19, %Point* %t20
  %t21 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.EnemyArena.gen, i64 0, i64 %t15
  %t22 = load i32, i32* %t21
  %t23 = add i32 %t22, 1
  store i32 %t23, i32* %t21
  br label %spawn_end_16
spawn_end_16:
  %t24 = load i64, i64* @frame.off
  %t25 = add i64 %t24, 4
  %t26 = icmp ugt i64 %t25, 4096
  br i1 %t26, label %frame_alloc_fail_19, label %frame_alloc_ok_20
frame_alloc_fail_19:
  %t27 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.3, i64 0, i64 0
  call i32 @puts(i8* %t27)
  call void @exit(i32 1)
  unreachable
frame_alloc_ok_20:
  store i64 %t25, i64* @frame.off
  %t28 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t29 = getelementptr inbounds i8, i8* %t28, i64 %t24
  %t30 = bitcast i8* %t29 to i32*
  store i32 0, i32* %t30
  %t31 = load i64, i64* @frame.off
  %t32 = add i64 %t31, 8
  %t33 = icmp ugt i64 %t32, 4096
  br i1 %t33, label %frame_alloc_fail_21, label %frame_alloc_ok_22
frame_alloc_fail_21:
  %t34 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t34)
  call void @exit(i32 1)
  unreachable
frame_alloc_ok_22:
  store i64 %t32, i64* @frame.off
  %t35 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t36 = getelementptr inbounds i8, i8* %t35, i64 %t31
  %t37 = bitcast i8* %t36 to %GenRef*
  %t38 = call %GenRef @create_entity_reference(i32 0)
  store %GenRef %t38, %GenRef* %t37
  %t39 = load i32, i32* %t30
  %t40 = load %GenRef, %GenRef* %t37
  %t41 = call i32 @follow_reference(%GenRef %t40)
  %t42 = add i32 %t39, %t41
  store i64 %t0, i64* @frame.off
  ret void
}

define i32 @main() {
entry:
  %t0 = alloca i32
  %t1 = call i32 @calculate_path(i32 5, i32 10)
  store i32 %t1, i32* %t0
  %t2 = load i32, i32* %t0
  %t3 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t3, i32 %t2)
  call void @game_tick()
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [70 x i8] c"star runtime error: a `frame:` block exceeded its 4096-byte capacity\0A\00"
@.str.1 = private unnamed_addr constant [70 x i8] c"star runtime error: a `frame:` block exceeded its 4096-byte capacity\0A\00"
@.str.2 = private unnamed_addr constant [88 x i8] c"star runtime warning: arena `EnemyArena` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [70 x i8] c"star runtime error: a `frame:` block exceeded its 4096-byte capacity\0A\00"
@.str.4 = private unnamed_addr constant [70 x i8] c"star runtime error: a `frame:` block exceeded its 4096-byte capacity\0A\00"
@.str.5 = private unnamed_addr constant [29 x i8] c"Path calculation result: %d\0A\00"
