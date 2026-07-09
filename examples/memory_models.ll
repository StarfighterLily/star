; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
declare i32 @puts(i8*)
declare noalias i8* @malloc(i64)
declare void @free(i8*)
declare i32 @strlen(i8*)
declare i8* @memcpy(i8*, i8*, i64)
declare void @llvm.memcpy.p0i8.p0i8.i64(i8*, i8*, i64, i1)

; GenRef: generational reference type (index, generation)
%GenRef = type { i32, i32 }

; Frame allocator for temporal allocations
%FrameAllocator = type { i8* }

%Point = type { i32, i32 }
; Arena: EnemyArena for type `Point` (element size: 8 bytes)
%EnemyArena = type { i8*, i64, i64 }

@arena.EnemyArena.data = global i8* null
@arena.EnemyArena.count = global i64 0

; Arena: ProjectileArena for type `Point` (element size: 8 bytes)
%ProjectileArena = type { i8*, i64, i64 }

@arena.ProjectileArena.data = global i8* null
@arena.ProjectileArena.count = global i64 0

; Frame allocator global state
@frame.buf = global [4096 x i8] zeroinitializer
@frame.off = global i64 0

define i32 @calculate_path(i32 %start_x, i32 %start_y) {
entry:
  %t0 = alloca i32
  store i32 %start_x, i32* %t0
  %t1 = alloca i32
  store i32 %start_y, i32* %t1
  %t2 = load i64, i64* @frame.off
  %t3 = alloca %Point
  %t5 = load i64, i64* @frame.off
  %t6 = add i64 %t5, 8
  %t7 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t4 = getelementptr inbounds i8, i8* %t7, i64 %t5
  store i64 %t6, i64* @frame.off
  %t8 = getelementptr inbounds %Point, %Point* %t4, i32 0, i32 0
  store i32 0, i32* %t8
  %t9 = getelementptr inbounds %Point, %Point* %t4, i32 0, i32 1
  store i32 0, i32* %t9
  %t10 = load %Point, %Point* %t4
  store %Point %t10, %Point* %t3
  %t11 = alloca %Point
  %t13 = load i64, i64* @frame.off
  %t14 = add i64 %t13, 8
  %t15 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t12 = getelementptr inbounds i8, i8* %t15, i64 %t13
  store i64 %t14, i64* @frame.off
  %t16 = load i32, i32* %t0
  %t17 = getelementptr inbounds %Point, %Point* %t12, i32 0, i32 0
  store i32 %t16, i32* %t17
  %t18 = load i32, i32* %t1
  %t19 = getelementptr inbounds %Point, %Point* %t12, i32 0, i32 1
  store i32 %t18, i32* %t19
  %t20 = load %Point, %Point* %t12
  store %Point %t20, %Point* %t11
  %t21 = getelementptr inbounds %Point, %Point* %t3, i32 0, i32 0
  %t22 = load i32, i32* %t21
  %t23 = getelementptr inbounds %Point, %Point* %t11, i32 0, i32 1
  %t24 = load i32, i32* %t23
  %t25 = add i32 %t22, %t24
  store i64 %t2, i64* @frame.off
  ret i32 %t25
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
  %t1 = load i32, i32* %t0
  %t2 = alloca %GenRef
  %t3 = getelementptr inbounds %GenRef, %GenRef* %t2, i32 0, i32 0
  store i32 %t1, i32* %t3
  %t4 = getelementptr inbounds %GenRef, %GenRef* %t2, i32 0, i32 1
  store i32 1, i32* %t4
  %t5 = load %GenRef, %GenRef* %t2
  ret %GenRef %t5
}

define i32 @follow_reference(%GenRef %gen_ref) {
entry:
  %t0 = alloca %GenRef
  store %GenRef %gen_ref, %GenRef* %t0
  %t1 = getelementptr inbounds %GenRef, %GenRef* %t0, i32 0, i32 0
  %t2 = load i32, i32* %t1
  %t3 = getelementptr inbounds %GenRef, %GenRef* %t0, i32 0, i32 1
  %t4 = load i32, i32* %t3
  ret i32 %t2
}

define void @game_tick() {
entry:
  %t0 = load i64, i64* @frame.off
  %t1 = alloca i32
  store i32 0, i32* %t1
  %t2 = alloca %GenRef
  %t3 = call %GenRef @create_entity_reference(i32 42)
  store %GenRef %t3, %GenRef* %t2
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
  ret void
}


; Global Constants
@.str.0 = private unnamed_addr constant [29 x i8] c"Path calculation result: %d\0A\00"
