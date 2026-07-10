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
  %t13 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t13, i32 %t12)
  %t14 = load %Countdown*, %Countdown** %t0
  %t15 = getelementptr inbounds %Countdown, %Countdown* %t14, i32 0, i32 1
  %t16 = load i32, i32* %t15
  %t17 = sub i32 %t16, 1
  %t18 = load %Countdown*, %Countdown** %t0
  %t19 = getelementptr inbounds %Countdown, %Countdown* %t18, i32 0, i32 1
  store i32 %t17, i32* %t19
  %t20 = load %Countdown*, %Countdown** %t0
  %t21 = getelementptr inbounds %Countdown, %Countdown* %t20, i32 0, i32 2
  store i32 1, i32* %t21
  ret i1 true
if_else_1:
  %t22 = load %Countdown*, %Countdown** %t0
  %t23 = getelementptr inbounds %Countdown, %Countdown* %t22, i32 0, i32 2
  %t24 = load i32, i32* %t23
  %t25 = icmp eq i32 %t24, 1
  br i1 %t25, label %if_then_3, label %if_else_4
if_then_3:
  %t26 = load %Countdown*, %Countdown** %t0
  %t27 = getelementptr inbounds %Countdown, %Countdown* %t26, i32 0, i32 1
  %t28 = load i32, i32* %t27
  %t29 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t29, i32 %t28)
  %t30 = load %Countdown*, %Countdown** %t0
  %t31 = getelementptr inbounds %Countdown, %Countdown* %t30, i32 0, i32 1
  %t32 = load i32, i32* %t31
  %t33 = sub i32 %t32, 1
  %t34 = load %Countdown*, %Countdown** %t0
  %t35 = getelementptr inbounds %Countdown, %Countdown* %t34, i32 0, i32 1
  store i32 %t33, i32* %t35
  %t36 = load %Countdown*, %Countdown** %t0
  %t37 = getelementptr inbounds %Countdown, %Countdown* %t36, i32 0, i32 2
  store i32 2, i32* %t37
  ret i1 true
if_else_4:
  %t38 = load %Countdown*, %Countdown** %t0
  %t39 = getelementptr inbounds %Countdown, %Countdown* %t38, i32 0, i32 2
  %t40 = load i32, i32* %t39
  %t41 = icmp eq i32 %t40, 2
  br i1 %t41, label %if_then_6, label %if_else_7
if_then_6:
  %t42 = load %Countdown*, %Countdown** %t0
  %t43 = getelementptr inbounds %Countdown, %Countdown* %t42, i32 0, i32 1
  %t44 = load i32, i32* %t43
  %t45 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t45, i32 %t44)
  %t46 = load %Countdown*, %Countdown** %t0
  %t47 = getelementptr inbounds %Countdown, %Countdown* %t46, i32 0, i32 1
  %t48 = load i32, i32* %t47
  %t49 = sub i32 %t48, 1
  %t50 = load %Countdown*, %Countdown** %t0
  %t51 = getelementptr inbounds %Countdown, %Countdown* %t50, i32 0, i32 1
  store i32 %t49, i32* %t51
  %t52 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t52)
  %t53 = load %Countdown*, %Countdown** %t0
  %t54 = getelementptr inbounds %Countdown, %Countdown* %t53, i32 0, i32 2
  store i32 3, i32* %t54
  ret i1 false
if_else_7:
  ret i1 false
}

define i32 @main() {
entry:
  %t0 = alloca %Countdown
  %t1 = alloca %Countdown
  %t2 = getelementptr inbounds %Countdown, %Countdown* %t1, i32 0, i32 0
  store i32 3, i32* %t2
  %t3 = getelementptr inbounds %Countdown, %Countdown* %t1, i32 0, i32 1
  store i32 0, i32* %t3
  %t4 = getelementptr inbounds %Countdown, %Countdown* %t1, i32 0, i32 2
  store i32 0, i32* %t4
  %t5 = load %Countdown, %Countdown* %t1
  store %Countdown %t5, %Countdown* %t0
  %t6 = alloca i1
  store i1 true, i1* %t6
  br label %while_cond_9
while_cond_9:
  %t7 = load i1, i1* %t6
  br i1 %t7, label %while_body_10, label %while_end_12
while_body_10:
  %t8 = call i1 @resume(%Countdown* %t0)
  store i1 %t8, i1* %t6
  br label %while_cond_9
while_else_11:
  br label %while_end_12
while_end_12:
  %t9 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t9)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [10 x i8] c"tick: %d\0A\00"
@.str.1 = private unnamed_addr constant [10 x i8] c"tick: %d\0A\00"
@.str.2 = private unnamed_addr constant [10 x i8] c"tick: %d\0A\00"
@.str.3 = private unnamed_addr constant [9 x i8] c"liftoff\0A\00"
@.str.4 = private unnamed_addr constant [15 x i8] c"sequence done\0A\00"
