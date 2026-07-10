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
%Entities = type { %Point*, i64 }
@arena.Entities.data = global %Point* null
@arena.Entities.count = global i64 0
@arena.Entities.gen = global [1024 x i32] zeroinitializer
@arena.Entities.free = global [1024 x i64] zeroinitializer
@arena.Entities.free_top = global i64 0

define i32 @main() {
entry:
  %t0 = alloca %GenRef
  %t1 = sext i32 0 to i64
  %t2 = icmp ult i64 %t1, 1024
  br i1 %t2, label %genref_create_ok_0, label %genref_create_oob_1
genref_create_ok_0:
  %t3 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t1
  %t4 = load i32, i32* %t3
  br label %genref_create_end_2
genref_create_oob_1:
  br label %genref_create_end_2
genref_create_end_2:
  %t5 = phi i32 [ %t4, %genref_create_ok_0 ], [ 0, %genref_create_oob_1 ]
  %t6 = alloca %GenRef
  %t7 = getelementptr inbounds %GenRef, %GenRef* %t6, i32 0, i32 0
  store i32 0, i32* %t7
  %t8 = getelementptr inbounds %GenRef, %GenRef* %t6, i32 0, i32 1
  store i32 %t5, i32* %t8
  %t9 = load %GenRef, %GenRef* %t6
  store %GenRef %t9, %GenRef* %t0
  %t10 = alloca %Point
  %t11 = getelementptr inbounds %GenRef, %GenRef* %t0, i32 0, i32 0
  %t12 = load i32, i32* %t11
  %t13 = getelementptr inbounds %GenRef, %GenRef* %t0, i32 0, i32 1
  %t14 = load i32, i32* %t13
  %t15 = sext i32 %t12 to i64
  %t16 = icmp ult i64 %t15, 1024
  br i1 %t16, label %genref_check_3, label %genref_stale_5
genref_check_3:
  %t17 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t15
  %t18 = load i32, i32* %t17
  %t19 = icmp eq i32 %t14, %t18
  %t20 = and i32 %t18, 1
  %t21 = icmp eq i32 %t20, 1
  %t22 = and i1 %t19, %t21
  br i1 %t22, label %genref_ok_4, label %genref_stale_5
genref_ok_4:
  %t23 = load %Point*, %Point** @arena.Entities.data
  %t24 = getelementptr inbounds %Point, %Point* %t23, i64 %t15
  %t25 = load %Point, %Point* %t24
  br label %genref_end_6
genref_stale_5:
  br label %genref_end_6
genref_end_6:
  %t26 = phi %Point [ %t25, %genref_ok_4 ], [ zeroinitializer, %genref_stale_5 ]
  store %Point %t26, %Point* %t10
  %t27 = getelementptr inbounds %Point, %Point* %t10, i32 0, i32 0
  %t28 = load i32, i32* %t27
  %t29 = getelementptr inbounds %Point, %Point* %t10, i32 0, i32 1
  %t30 = load i32, i32* %t29
  %t31 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t31, i32 %t28, i32 %t30)
  %t32 = load %Point*, %Point** @arena.Entities.data
  %t33 = icmp eq %Point* %t32, null
  br i1 %t33, label %spawn_init_7, label %spawn_ready_8
spawn_init_7:
  %t34 = call i8* @malloc(i64 8192)
  %t35 = bitcast i8* %t34 to %Point*
  store %Point* %t35, %Point** @arena.Entities.data
  br label %spawn_ready_8
spawn_ready_8:
  %t36 = load %Point*, %Point** @arena.Entities.data
  %t37 = load i64, i64* @arena.Entities.free_top
  %t38 = icmp sgt i64 %t37, 0
  br i1 %t38, label %spawn_reuse_9, label %spawn_grow_10
spawn_reuse_9:
  %t39 = sub i64 %t37, 1
  store i64 %t39, i64* @arena.Entities.free_top
  %t40 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t39
  %t41 = load i64, i64* %t40
  br label %spawn_store_11
spawn_grow_10:
  %t42 = load i64, i64* @arena.Entities.count
  %t43 = icmp slt i64 %t42, 1024
  br i1 %t43, label %spawn_grow_ok_13, label %spawn_capacity_warn_14
spawn_capacity_warn_14:
  %t44 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t44)
  br label %spawn_end_12
spawn_grow_ok_13:
  %t45 = add i64 %t42, 1
  store i64 %t45, i64* @arena.Entities.count
  br label %spawn_store_11
spawn_store_11:
  %t46 = phi i64 [ %t41, %spawn_reuse_9 ], [ %t42, %spawn_grow_ok_13 ]
  %t47 = alloca %Point
  %t48 = getelementptr inbounds %Point, %Point* %t47, i32 0, i32 0
  store i32 999, i32* %t48
  %t49 = getelementptr inbounds %Point, %Point* %t47, i32 0, i32 1
  store i32 999, i32* %t49
  %t50 = load %Point, %Point* %t47
  %t51 = getelementptr inbounds %Point, %Point* %t36, i64 %t46
  store %Point %t50, %Point* %t51
  %t52 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t46
  %t53 = load i32, i32* %t52
  %t54 = add i32 %t53, 1
  store i32 %t54, i32* %t52
  br label %spawn_end_12
spawn_end_12:
  %t55 = alloca %GenRef
  %t56 = sext i32 5 to i64
  %t57 = icmp ult i64 %t56, 1024
  br i1 %t57, label %genref_create_ok_15, label %genref_create_oob_16
genref_create_ok_15:
  %t58 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t56
  %t59 = load i32, i32* %t58
  br label %genref_create_end_17
genref_create_oob_16:
  br label %genref_create_end_17
genref_create_end_17:
  %t60 = phi i32 [ %t59, %genref_create_ok_15 ], [ 0, %genref_create_oob_16 ]
  %t61 = alloca %GenRef
  %t62 = getelementptr inbounds %GenRef, %GenRef* %t61, i32 0, i32 0
  store i32 5, i32* %t62
  %t63 = getelementptr inbounds %GenRef, %GenRef* %t61, i32 0, i32 1
  store i32 %t60, i32* %t63
  %t64 = load %GenRef, %GenRef* %t61
  store %GenRef %t64, %GenRef* %t55
  %t65 = alloca %Point
  %t66 = getelementptr inbounds %GenRef, %GenRef* %t55, i32 0, i32 0
  %t67 = load i32, i32* %t66
  %t68 = getelementptr inbounds %GenRef, %GenRef* %t55, i32 0, i32 1
  %t69 = load i32, i32* %t68
  %t70 = sext i32 %t67 to i64
  %t71 = icmp ult i64 %t70, 1024
  br i1 %t71, label %genref_check_18, label %genref_stale_20
genref_check_18:
  %t72 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t70
  %t73 = load i32, i32* %t72
  %t74 = icmp eq i32 %t69, %t73
  %t75 = and i32 %t73, 1
  %t76 = icmp eq i32 %t75, 1
  %t77 = and i1 %t74, %t76
  br i1 %t77, label %genref_ok_19, label %genref_stale_20
genref_ok_19:
  %t78 = load %Point*, %Point** @arena.Entities.data
  %t79 = getelementptr inbounds %Point, %Point* %t78, i64 %t70
  %t80 = load %Point, %Point* %t79
  br label %genref_end_21
genref_stale_20:
  br label %genref_end_21
genref_end_21:
  %t81 = phi %Point [ %t80, %genref_ok_19 ], [ zeroinitializer, %genref_stale_20 ]
  store %Point %t81, %Point* %t65
  %t82 = getelementptr inbounds %Point, %Point* %t65, i32 0, i32 0
  %t83 = load i32, i32* %t82
  %t84 = getelementptr inbounds %Point, %Point* %t65, i32 0, i32 1
  %t85 = load i32, i32* %t84
  %t86 = getelementptr inbounds [53 x i8], [53 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t86, i32 %t83, i32 %t85)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [29 x i8] c"before any spawn: x=%d y=%d\0A\00"
@.str.1 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [53 x i8] c"other slot live, this slot never spawned: x=%d y=%d\0A\00"
