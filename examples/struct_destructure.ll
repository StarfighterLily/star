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
%Line = type { %Point, %Point }
define i32 @manhattan(%Point %p) {
entry:
  %t0 = alloca %Point
  store %Point %p, %Point* %t0
  br label %match_scrutinee_2
match_scrutinee_2:
  %t3 = getelementptr inbounds %Point, %Point* %t0, i32 0, i32 0
  %t4 = getelementptr inbounds %Point, %Point* %t0, i32 0, i32 1
  %t5 = load i32, i32* %t3
  %t6 = load i32, i32* %t4
  %t7 = add i32 %t5, %t6
  ret i32 %t7
match_end_1:
  unreachable
}

define i32 @length_sq(%Line %l) {
entry:
  %t0 = alloca %Line
  store %Line %l, %Line* %t0
  br label %match_scrutinee_2
match_scrutinee_2:
  %t3 = getelementptr inbounds %Line, %Line* %t0, i32 0, i32 0
  %t4 = getelementptr inbounds %Line, %Line* %t0, i32 0, i32 1
  %t5 = alloca i32
  %t6 = getelementptr inbounds %Point, %Point* %t4, i32 0, i32 0
  %t7 = load i32, i32* %t6
  %t8 = getelementptr inbounds %Point, %Point* %t3, i32 0, i32 0
  %t9 = load i32, i32* %t8
  %t10 = sub i32 %t7, %t9
  store i32 %t10, i32* %t5
  %t11 = alloca i32
  %t12 = getelementptr inbounds %Point, %Point* %t4, i32 0, i32 1
  %t13 = load i32, i32* %t12
  %t14 = getelementptr inbounds %Point, %Point* %t3, i32 0, i32 1
  %t15 = load i32, i32* %t14
  %t16 = sub i32 %t13, %t15
  store i32 %t16, i32* %t11
  %t17 = load i32, i32* %t5
  %t18 = load i32, i32* %t5
  %t19 = mul i32 %t17, %t18
  %t20 = load i32, i32* %t11
  %t21 = load i32, i32* %t11
  %t22 = mul i32 %t20, %t21
  %t23 = add i32 %t19, %t22
  ret i32 %t23
match_end_1:
  unreachable
}

define void @main() {
entry:
  %t0 = alloca %Point
  %t1 = getelementptr inbounds %Point, %Point* %t0, i32 0, i32 0
  store i32 3, i32* %t1
  %t2 = getelementptr inbounds %Point, %Point* %t0, i32 0, i32 1
  store i32 4, i32* %t2
  %t3 = load %Point, %Point* %t0
  %t4 = call i32 @manhattan(%Point %t3)
  %t5 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t5, i32 %t4)
  %t6 = alloca %Line
  %t7 = alloca %Point
  %t8 = getelementptr inbounds %Point, %Point* %t7, i32 0, i32 0
  store i32 0, i32* %t8
  %t9 = getelementptr inbounds %Point, %Point* %t7, i32 0, i32 1
  store i32 0, i32* %t9
  %t10 = load %Point, %Point* %t7
  %t11 = getelementptr inbounds %Line, %Line* %t6, i32 0, i32 0
  store %Point %t10, %Point* %t11
  %t12 = alloca %Point
  %t13 = getelementptr inbounds %Point, %Point* %t12, i32 0, i32 0
  store i32 3, i32* %t13
  %t14 = getelementptr inbounds %Point, %Point* %t12, i32 0, i32 1
  store i32 4, i32* %t14
  %t15 = load %Point, %Point* %t12
  %t16 = getelementptr inbounds %Line, %Line* %t6, i32 0, i32 1
  store %Point %t15, %Point* %t16
  %t17 = load %Line, %Line* %t6
  %t18 = call i32 @length_sq(%Line %t17)
  %t19 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t19, i32 %t18)
  ret void
}


; Global Constants
@.str.0 = private unnamed_addr constant [9 x i8] c"sum: %d\0A\00"
@.str.1 = private unnamed_addr constant [15 x i8] c"length_sq: %d\0A\00"
