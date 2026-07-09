; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
declare i32 @puts(i8*)
declare noalias i8* @malloc(i64)
declare void @free(i8*)
declare i32 @strlen(i8*)
declare i8* @memcpy(i8*, i8*, i64)

%GenRef = type { i32, i32 }

@frame.buf = global [4096 x i8] zeroinitializer
@frame.off = global i64 0

%Point = type { i32, i32 }
%EnemyArena = type { %Point*, i64 }
@arena.EnemyArena.data = global %Point* null
@arena.EnemyArena.count = global i64 0

%ProjectileArena = type { %Point*, i64 }
@arena.ProjectileArena.data = global %Point* null
@arena.ProjectileArena.count = global i64 0

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

define %GenRef @create_entity_reference(i32 %id) {
entry:
  %t0 = alloca i32
  store i32 %id, i32* %t0
  %t1 = alloca %GenRef
  %t2 = load i32, i32* %t0
  %t3 = getelementptr inbounds %GenRef, %GenRef* %t1, i32 0, i32 0
  store i32 %t2, i32* %t3
  %t4 = getelementptr inbounds %GenRef, %GenRef* %t1, i32 0, i32 1
  store i32 0, i32* %t4
  %t5 = load %GenRef, %GenRef* %t1
  ret %GenRef %t5
}

define i32 @follow_reference(%GenRef %gen_ref) {
entry:
  %t0 = alloca %GenRef
  store %GenRef %gen_ref, %GenRef* %t0
  %t1 = getelementptr inbounds %GenRef, %GenRef* %t0, i32 0, i32 0
  %t2 = load i32, i32* %t1
  ret i32 %t2
}

define void @game_tick() {
entry:
  %t0 = load i64, i64* @frame.off
  %t1 = load i64, i64* @frame.off
  %t2 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t3 = getelementptr inbounds i8, i8* %t2, i64 %t1
  %t4 = add i64 %t1, 4
  store i64 %t4, i64* @frame.off
  %t5 = bitcast i8* %t3 to i32*
  store i32 0, i32* %t5
  %t6 = load i64, i64* @frame.off
  %t7 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t8 = getelementptr inbounds i8, i8* %t7, i64 %t6
  %t9 = add i64 %t6, 8
  store i64 %t9, i64* @frame.off
  %t10 = bitcast i8* %t8 to %GenRef*
  %t11 = call %GenRef @create_entity_reference(i32 42)
  store %GenRef %t11, %GenRef* %t10
  %t12 = load i32, i32* %t5
  %t13 = load %GenRef, %GenRef* %t10
  %t14 = call i32 @follow_reference(%GenRef %t13)
  %t15 = add i32 %t12, %t14
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
