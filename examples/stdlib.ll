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

%Player = type { i32, float, i8* }
define i32 @add(i32 %a, i32 %b) {
entry:
  %t0 = alloca i32
  store i32 %a, i32* %t0
  %t1 = alloca i32
  store i32 %b, i32* %t1
  %t2 = load i32, i32* %t0
  %t3 = load i32, i32* %t1
  %t4 = add i32 %t2, %t3
  ret i32 %t4
}

define i32 @clamp_health(i32 %h) {
entry:
  %t0 = alloca i32
  store i32 %h, i32* %t0
  %t1 = load i32, i32* %t0
  %t2 = icmp slt i32 %t1, 100
  %t3 = select i1 %t2, i32 %t1, i32 100
  %t4 = icmp sgt i32 0, %t3
  %t5 = select i1 %t4, i32 0, i32 %t3
  ret i32 %t5
}

define void @main() {
entry:
  %t0 = call i32 @add(i32 2, i32 3)
  %t1 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1, i32 %t0)
  %t2 = call float @llvm.sqrt.f32(float 0x4030000000000000)
  %t3 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.1, i64 0, i64 0
  %t4 = fpext float %t2 to double
  call i32 (i8*, ...) @printf(i8* %t3, double %t4)
  %t5 = call float @llvm.pow.f32(float 0x4000000000000000, float 0x4024000000000000)
  %t6 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.2, i64 0, i64 0
  %t7 = fpext float %t5 to double
  call i32 (i8*, ...) @printf(i8* %t6, double %t7)
  %t8 = sub i32 0, 5
  %t9 = sub i32 0, %t8
  %t10 = icmp slt i32 %t8, 0
  %t11 = select i1 %t10, i32 %t9, i32 %t8
  %t12 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t12, i32 %t11)
  %t13 = fsub float 0.0, 0x4016000000000000
  %t14 = call float @llvm.fabs.f32(float %t13)
  %t15 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.4, i64 0, i64 0
  %t16 = fpext float %t14 to double
  call i32 (i8*, ...) @printf(i8* %t15, double %t16)
  %t17 = call float @llvm.floor.f32(float 0x400E000000000000)
  %t18 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.5, i64 0, i64 0
  %t19 = fpext float %t17 to double
  call i32 (i8*, ...) @printf(i8* %t18, double %t19)
  %t20 = call float @llvm.ceil.f32(float 0x400A000000000000)
  %t21 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.6, i64 0, i64 0
  %t22 = fpext float %t20 to double
  call i32 (i8*, ...) @printf(i8* %t21, double %t22)
  %t23 = call i32 @clamp_health(i32 150)
  %t24 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t24, i32 %t23)
  %t25 = alloca i8*
  %t27 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.8, i64 0, i64 0
  %t26 = alloca i8*
  store i8* %t27, i8** %t26
  store i8* %t26, i8** %t25
  %t28 = load i8*, i8** %t25
  %t29 = load i8*, i8** %t28
  %t30 = call i32 @strlen(i8* %t29)
  %t31 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t31, i32 %t30)
  %t32 = alloca i8*
  %t34 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.10, i64 0, i64 0
  %t33 = alloca i8*
  store i8* %t34, i8** %t33
  %t35 = load i8*, i8** %t33
  %t36 = load i8*, i8** %t25
  %t37 = load i8*, i8** %t36
  %t38 = call i32 @strlen(i8* %t35)
  %t39 = call i32 @strlen(i8* %t37)
  %t40 = add i32 %t38, %t39
  %t41 = add i32 %t40, 1
  %t42 = sext i32 %t41 to i64
  %t43 = call i8* @malloc(i64 %t42)
  call i8* @strcpy(i8* %t43, i8* %t35)
  call i8* @strcat(i8* %t43, i8* %t37)
  %t44 = alloca i8*
  store i8* %t43, i8** %t44
  store i8* %t44, i8** %t32
  %t45 = load i8*, i8** %t32
  %t46 = load i8*, i8** %t45
  %t47 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t47, i8* %t46)
  ret void
}


; Global Constants
@__star_reflect_Player = private unnamed_addr constant [45 x i8] c"health:0:i32:export;speed:4:float:tweakable;\00"
@.str.0 = private unnamed_addr constant [9 x i8] c"sum: %d\0A\00"
@.str.1 = private unnamed_addr constant [10 x i8] c"sqrt: %f\0A\00"
@.str.2 = private unnamed_addr constant [9 x i8] c"pow: %f\0A\00"
@.str.3 = private unnamed_addr constant [13 x i8] c"abs int: %d\0A\00"
@.str.4 = private unnamed_addr constant [15 x i8] c"abs float: %f\0A\00"
@.str.5 = private unnamed_addr constant [11 x i8] c"floor: %f\0A\00"
@.str.6 = private unnamed_addr constant [10 x i8] c"ceil: %f\0A\00"
@.str.7 = private unnamed_addr constant [13 x i8] c"clamped: %d\0A\00"
@.str.8 = private unnamed_addr constant [5 x i8] c"Hero\00"
@.str.9 = private unnamed_addr constant [14 x i8] c"name len: %d\0A\00"
@.str.10 = private unnamed_addr constant [8 x i8] c"hello, \00"
@.str.11 = private unnamed_addr constant [14 x i8] c"greeting: %s\0A\00"
