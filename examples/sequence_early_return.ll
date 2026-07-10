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

%Countdown = type { i32, i32, i32 }
define i1 @resume(%Countdown* %self) {
entry:
  %t0 = alloca %Countdown*
  store %Countdown* %self, %Countdown** %t0
  %t1 = load %Countdown*, %Countdown** %t0
  %t2 = getelementptr inbounds %Countdown, %Countdown* %t1, i32 0, i32 2
  %t3 = load i32, i32* %t2
  %t4 = icmp eq i32 %t3, 0
  br i1 %t4, label %if_then_0, label %if_else_1
if_then_0:
  %t5 = load %Countdown*, %Countdown** %t0
  %t6 = getelementptr inbounds %Countdown, %Countdown* %t5, i32 0, i32 0
  %t7 = load i32, i32* %t6
  %t8 = load %Countdown*, %Countdown** %t0
  %t9 = getelementptr inbounds %Countdown, %Countdown* %t8, i32 0, i32 1
  store i32 %t7, i32* %t9
  %t10 = load %Countdown*, %Countdown** %t0
  %t11 = getelementptr inbounds %Countdown, %Countdown* %t10, i32 0, i32 1
  %t12 = load i32, i32* %t11
  %t13 = icmp slt i32 %t12, 0
  br i1 %t13, label %if_then_3, label %if_else_4
if_then_3:
  ret i1 false
if_else_4:
  br label %if_end_5
if_end_5:
  %t14 = load %Countdown*, %Countdown** %t0
  %t15 = getelementptr inbounds %Countdown, %Countdown* %t14, i32 0, i32 2
  store i32 1, i32* %t15
  ret i1 true
if_else_1:
  %t16 = load %Countdown*, %Countdown** %t0
  %t17 = getelementptr inbounds %Countdown, %Countdown* %t16, i32 0, i32 2
  %t18 = load i32, i32* %t17
  %t19 = icmp eq i32 %t18, 1
  br i1 %t19, label %if_then_6, label %if_else_7
if_then_6:
  %t20 = load %Countdown*, %Countdown** %t0
  %t21 = getelementptr inbounds %Countdown, %Countdown* %t20, i32 0, i32 1
  %t22 = load i32, i32* %t21
  %t23 = sub i32 %t22, 1
  %t24 = load %Countdown*, %Countdown** %t0
  %t25 = getelementptr inbounds %Countdown, %Countdown* %t24, i32 0, i32 1
  store i32 %t23, i32* %t25
  %t26 = load %Countdown*, %Countdown** %t0
  %t27 = getelementptr inbounds %Countdown, %Countdown* %t26, i32 0, i32 2
  store i32 2, i32* %t27
  ret i1 true
if_else_7:
  %t28 = load %Countdown*, %Countdown** %t0
  %t29 = getelementptr inbounds %Countdown, %Countdown* %t28, i32 0, i32 2
  %t30 = load i32, i32* %t29
  %t31 = icmp eq i32 %t30, 2
  br i1 %t31, label %if_then_9, label %if_else_10
if_then_9:
  %t32 = load %Countdown*, %Countdown** %t0
  %t33 = getelementptr inbounds %Countdown, %Countdown* %t32, i32 0, i32 1
  %t34 = load i32, i32* %t33
  %t35 = sub i32 %t34, 1
  %t36 = load %Countdown*, %Countdown** %t0
  %t37 = getelementptr inbounds %Countdown, %Countdown* %t36, i32 0, i32 1
  store i32 %t35, i32* %t37
  %t38 = load %Countdown*, %Countdown** %t0
  %t39 = getelementptr inbounds %Countdown, %Countdown* %t38, i32 0, i32 2
  store i32 3, i32* %t39
  ret i1 false
if_else_10:
  ret i1 false
}

define i32 @main() {
entry:
  %t0 = alloca %Countdown
  %t1 = alloca %Countdown
  %t2 = getelementptr inbounds %Countdown, %Countdown* %t1, i32 0, i32 0
  store i32 1, i32* %t2
  %t3 = getelementptr inbounds %Countdown, %Countdown* %t1, i32 0, i32 1
  store i32 0, i32* %t3
  %t4 = getelementptr inbounds %Countdown, %Countdown* %t1, i32 0, i32 2
  store i32 0, i32* %t4
  %t5 = load %Countdown, %Countdown* %t1
  store %Countdown %t5, %Countdown* %t0
  %t6 = alloca i1
  store i1 true, i1* %t6
  %t7 = alloca i32
  store i32 0, i32* %t7
  br label %while_cond_12
while_cond_12:
  %t8 = load i1, i1* %t6
  br i1 %t8, label %while_body_13, label %while_end_15
while_body_13:
  %t9 = call i1 @resume(%Countdown* %t0)
  store i1 %t9, i1* %t6
  %t10 = load i32, i32* %t7
  %t11 = add i32 %t10, 1
  store i32 %t11, i32* %t7
  br label %while_cond_12
while_else_14:
  br label %while_end_15
while_end_15:
  %t12 = load i32, i32* %t7
  %t13 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t13, i32 %t12)
  %t14 = alloca %Countdown
  %t15 = alloca %Countdown
  %t16 = sub i32 0, 1
  %t17 = getelementptr inbounds %Countdown, %Countdown* %t15, i32 0, i32 0
  store i32 %t16, i32* %t17
  %t18 = getelementptr inbounds %Countdown, %Countdown* %t15, i32 0, i32 1
  store i32 0, i32* %t18
  %t19 = getelementptr inbounds %Countdown, %Countdown* %t15, i32 0, i32 2
  store i32 0, i32* %t19
  %t20 = load %Countdown, %Countdown* %t15
  store %Countdown %t20, %Countdown* %t14
  %t21 = alloca i1
  %t22 = call i1 @resume(%Countdown* %t14)
  store i1 %t22, i1* %t21
  %t23 = load i1, i1* %t21
  %t24 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.1, i64 0, i64 0
  %t25 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.2, i64 0, i64 0
  %t26 = select i1 %t23, i8* %t24, i8* %t25
  %t27 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t27, i8* %t26)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [11 x i8] c"ticks: %d\0A\00"
@.str.1 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.2 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.3 = private unnamed_addr constant [31 x i8] c"early return reports done: %s\0A\00"
