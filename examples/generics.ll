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

%Result__i32__str = type { i32, [1 x i64] }
%Box__i32 = type { i32 }
%Box__Box__i32 = type { %Box__i32 }
%Option__i32 = type { i32, [1 x i64] }
define void @print_result(%Result__i32__str %r) {
entry:
  %t0 = alloca %Result__i32__str
  store %Result__i32__str %r, %Result__i32__str* %t0
  br label %match_scrutinee_2
match_scrutinee_2:
  %t4 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t0, i32 0, i32 0
  %t5 = load i32, i32* %t4
  %t3 = icmp eq i32 %t5, 0
  br i1 %t3, label %match_then_0, label %match_next_0
match_then_0:
  %t6 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t0, i32 0, i32 1
  %t7 = bitcast [1 x i64]* %t6 to { i32 }*
  %t8 = getelementptr inbounds { i32 }, { i32 }* %t7, i32 0, i32 0
  %t9 = load i32, i32* %t8
  %t10 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t10, i32 %t9)
  br label %match_end_1
match_next_0:
  %t12 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t0, i32 0, i32 0
  %t13 = load i32, i32* %t12
  %t11 = icmp eq i32 %t13, 1
  br i1 %t11, label %match_then_1, label %match_next_1
match_then_1:
  %t14 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t0, i32 0, i32 1
  %t15 = bitcast [1 x i64]* %t14 to { i8* }*
  %t16 = getelementptr inbounds { i8* }, { i8* }* %t15, i32 0, i32 0
  %t17 = load i8*, i8** %t16
  %t18 = load i8*, i8** %t17
  %t19 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t19, i8* %t18)
  br label %match_end_1
match_next_1:
  br label %match_end_1
match_end_1:
  ret void
}

define void @main() {
entry:
  %t0 = alloca %Box__i32
  %t1 = alloca %Box__i32
  %t2 = getelementptr inbounds %Box__i32, %Box__i32* %t1, i32 0, i32 0
  store i32 42, i32* %t2
  %t3 = load %Box__i32, %Box__i32* %t1
  store %Box__i32 %t3, %Box__i32* %t0
  %t4 = getelementptr inbounds %Box__i32, %Box__i32* %t0, i32 0, i32 0
  %t5 = load i32, i32* %t4
  %t6 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t6, i32 %t5)
  %t7 = alloca %Box__Box__i32
  %t8 = alloca %Box__Box__i32
  %t9 = alloca %Box__i32
  %t10 = getelementptr inbounds %Box__i32, %Box__i32* %t9, i32 0, i32 0
  store i32 99, i32* %t10
  %t11 = load %Box__i32, %Box__i32* %t9
  %t12 = getelementptr inbounds %Box__Box__i32, %Box__Box__i32* %t8, i32 0, i32 0
  store %Box__i32 %t11, %Box__i32* %t12
  %t13 = load %Box__Box__i32, %Box__Box__i32* %t8
  store %Box__Box__i32 %t13, %Box__Box__i32* %t7
  %t14 = getelementptr inbounds %Box__Box__i32, %Box__Box__i32* %t7, i32 0, i32 0
  %t15 = getelementptr inbounds %Box__i32, %Box__i32* %t14, i32 0, i32 0
  %t16 = load i32, i32* %t15
  %t17 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t17, i32 %t16)
  %t18 = alloca %Option__i32
  %t19 = alloca %Option__i32
  %t20 = getelementptr inbounds %Option__i32, %Option__i32* %t19, i32 0, i32 0
  store i32 1, i32* %t20
  %t21 = getelementptr inbounds %Option__i32, %Option__i32* %t19, i32 0, i32 1
  %t22 = bitcast [1 x i64]* %t21 to { i32 }*
  %t23 = getelementptr inbounds { i32 }, { i32 }* %t22, i32 0, i32 0
  store i32 5, i32* %t23
  %t24 = load %Option__i32, %Option__i32* %t19
  store %Option__i32 %t24, %Option__i32* %t18
  %t25 = alloca %Option__i32
  %t26 = alloca %Option__i32
  %t27 = getelementptr inbounds %Option__i32, %Option__i32* %t26, i32 0, i32 0
  store i32 0, i32* %t27
  %t28 = load %Option__i32, %Option__i32* %t26
  store %Option__i32 %t28, %Option__i32* %t25
  %t29 = load %Option__i32, %Option__i32* %t18
  %t30 = call i32 @unwrap_or__i32(%Option__i32 %t29, i32 0)
  %t31 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t31, i32 %t30)
  %t32 = load %Option__i32, %Option__i32* %t25
  %t33 = sub i32 0, 1
  %t34 = call i32 @unwrap_or__i32(%Option__i32 %t32, i32 %t33)
  %t35 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t35, i32 %t34)
  %t36 = alloca %Result__i32__str
  %t37 = alloca %Result__i32__str
  %t38 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t37, i32 0, i32 0
  store i32 0, i32* %t38
  %t39 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t37, i32 0, i32 1
  %t40 = bitcast [1 x i64]* %t39 to { i32 }*
  %t41 = getelementptr inbounds { i32 }, { i32 }* %t40, i32 0, i32 0
  store i32 10, i32* %t41
  %t42 = load %Result__i32__str, %Result__i32__str* %t37
  store %Result__i32__str %t42, %Result__i32__str* %t36
  %t43 = alloca %Result__i32__str
  %t44 = alloca %Result__i32__str
  %t45 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t44, i32 0, i32 0
  store i32 1, i32* %t45
  %t46 = getelementptr inbounds %Result__i32__str, %Result__i32__str* %t44, i32 0, i32 1
  %t47 = bitcast [1 x i64]* %t46 to { i8* }*
  %t49 = getelementptr inbounds [4 x i8], [4 x i8]* @.str.6, i64 0, i64 0
  %t48 = alloca i8*
  store i8* %t49, i8** %t48
  %t50 = getelementptr inbounds { i8* }, { i8* }* %t47, i32 0, i32 0
  store i8* %t48, i8** %t50
  %t51 = load %Result__i32__str, %Result__i32__str* %t44
  store %Result__i32__str %t51, %Result__i32__str* %t43
  %t52 = load %Result__i32__str, %Result__i32__str* %t36
  call void @print_result(%Result__i32__str %t52)
  %t53 = load %Result__i32__str, %Result__i32__str* %t43
  call void @print_result(%Result__i32__str %t53)
  %t54 = call i32 @identity__i32(i32 7)
  %t55 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t55, i32 %t54)
  %t56 = call float @identity__f32(float 0x400C000000000000)
  %t57 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.8, i64 0, i64 0
  %t58 = fpext float %t56 to double
  call i32 (i8*, ...) @printf(i8* %t57, double %t58)
  ret void
}

define i32 @unwrap_or__i32(%Option__i32 %o, i32 %default) {
entry:
  %t0 = alloca %Option__i32
  store %Option__i32 %o, %Option__i32* %t0
  %t1 = alloca i32
  store i32 %default, i32* %t1
  br label %match_scrutinee_3
match_scrutinee_3:
  %t5 = getelementptr inbounds %Option__i32, %Option__i32* %t0, i32 0, i32 0
  %t6 = load i32, i32* %t5
  %t4 = icmp eq i32 %t6, 1
  br i1 %t4, label %match_then_0, label %match_next_0
match_then_0:
  %t7 = getelementptr inbounds %Option__i32, %Option__i32* %t0, i32 0, i32 1
  %t8 = bitcast [1 x i64]* %t7 to { i32 }*
  %t9 = getelementptr inbounds { i32 }, { i32 }* %t8, i32 0, i32 0
  %t10 = load i32, i32* %t9
  ret i32 %t10
match_next_0:
  %t12 = getelementptr inbounds %Option__i32, %Option__i32* %t0, i32 0, i32 0
  %t13 = load i32, i32* %t12
  %t11 = icmp eq i32 %t13, 0
  br i1 %t11, label %match_then_1, label %match_next_1
match_then_1:
  %t14 = load i32, i32* %t1
  ret i32 %t14
match_next_1:
  br label %match_end_2
match_end_2:
  unreachable
}

define i32 @identity__i32(i32 %x) {
entry:
  %t0 = alloca i32
  store i32 %x, i32* %t0
  %t1 = load i32, i32* %t0
  ret i32 %t1
}

define float @identity__f32(float %x) {
entry:
  %t0 = alloca float
  store float %x, float* %t0
  %t1 = load float, float* %t0
  ret float %t1
}


; Global Constants
@.str.0 = private unnamed_addr constant [8 x i8] c"ok: %d\0A\00"
@.str.1 = private unnamed_addr constant [9 x i8] c"err: %s\0A\00"
@.str.2 = private unnamed_addr constant [9 x i8] c"box: %d\0A\00"
@.str.3 = private unnamed_addr constant [16 x i8] c"nested box: %d\0A\00"
@.str.4 = private unnamed_addr constant [17 x i8] c"unwrap some: %d\0A\00"
@.str.5 = private unnamed_addr constant [17 x i8] c"unwrap none: %d\0A\00"
@.str.6 = private unnamed_addr constant [4 x i8] c"bad\00"
@.str.7 = private unnamed_addr constant [18 x i8] c"identity int: %d\0A\00"
@.str.8 = private unnamed_addr constant [20 x i8] c"identity float: %f\0A\00"
