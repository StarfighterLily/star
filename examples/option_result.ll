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

%IntOption = type { i32, [1 x i64] }
%DivResult = type { i32, [1 x i64] }
%Shape = type { i32, [1 x i64] }
define %DivResult @safe_div(i32 %a, i32 %b) {
entry:
  %t0 = alloca i32
  store i32 %a, i32* %t0
  %t1 = alloca i32
  store i32 %b, i32* %t1
  %t2 = load i32, i32* %t1
  %t3 = icmp eq i32 %t2, 0
  br i1 %t3, label %if_then_0, label %if_else_1
if_then_0:
  %t4 = alloca %DivResult
  %t5 = getelementptr inbounds %DivResult, %DivResult* %t4, i32 0, i32 0
  store i32 1, i32* %t5
  %t6 = getelementptr inbounds %DivResult, %DivResult* %t4, i32 0, i32 1
  %t7 = bitcast [1 x i64]* %t6 to { i32 }*
  %t8 = getelementptr inbounds { i32 }, { i32 }* %t7, i32 0, i32 0
  store i32 1, i32* %t8
  %t9 = load %DivResult, %DivResult* %t4
  ret %DivResult %t9
if_else_1:
  br label %if_end_2
if_end_2:
  %t10 = alloca %DivResult
  %t11 = getelementptr inbounds %DivResult, %DivResult* %t10, i32 0, i32 0
  store i32 0, i32* %t11
  %t12 = getelementptr inbounds %DivResult, %DivResult* %t10, i32 0, i32 1
  %t13 = bitcast [1 x i64]* %t12 to { i32 }*
  %t14 = load i32, i32* %t0
  %t15 = load i32, i32* %t1
  %t16 = sdiv i32 %t14, %t15
  %t17 = getelementptr inbounds { i32 }, { i32 }* %t13, i32 0, i32 0
  store i32 %t16, i32* %t17
  %t18 = load %DivResult, %DivResult* %t10
  ret %DivResult %t18
}

define %IntOption @first_even(i32 %a, i32 %b, i32 %c) {
entry:
  %t0 = alloca i32
  store i32 %a, i32* %t0
  %t1 = alloca i32
  store i32 %b, i32* %t1
  %t2 = alloca i32
  store i32 %c, i32* %t2
  %t3 = load i32, i32* %t0
  %t4 = srem i32 %t3, 2
  %t5 = icmp eq i32 %t4, 0
  br i1 %t5, label %if_then_3, label %if_else_4
if_then_3:
  %t6 = alloca %IntOption
  %t7 = getelementptr inbounds %IntOption, %IntOption* %t6, i32 0, i32 0
  store i32 1, i32* %t7
  %t8 = getelementptr inbounds %IntOption, %IntOption* %t6, i32 0, i32 1
  %t9 = bitcast [1 x i64]* %t8 to { i32 }*
  %t10 = load i32, i32* %t0
  %t11 = getelementptr inbounds { i32 }, { i32 }* %t9, i32 0, i32 0
  store i32 %t10, i32* %t11
  %t12 = load %IntOption, %IntOption* %t6
  ret %IntOption %t12
if_else_4:
  br label %if_end_5
if_end_5:
  %t13 = load i32, i32* %t1
  %t14 = srem i32 %t13, 2
  %t15 = icmp eq i32 %t14, 0
  br i1 %t15, label %if_then_6, label %if_else_7
if_then_6:
  %t16 = alloca %IntOption
  %t17 = getelementptr inbounds %IntOption, %IntOption* %t16, i32 0, i32 0
  store i32 1, i32* %t17
  %t18 = getelementptr inbounds %IntOption, %IntOption* %t16, i32 0, i32 1
  %t19 = bitcast [1 x i64]* %t18 to { i32 }*
  %t20 = load i32, i32* %t1
  %t21 = getelementptr inbounds { i32 }, { i32 }* %t19, i32 0, i32 0
  store i32 %t20, i32* %t21
  %t22 = load %IntOption, %IntOption* %t16
  ret %IntOption %t22
if_else_7:
  br label %if_end_8
if_end_8:
  %t23 = load i32, i32* %t2
  %t24 = srem i32 %t23, 2
  %t25 = icmp eq i32 %t24, 0
  br i1 %t25, label %if_then_9, label %if_else_10
if_then_9:
  %t26 = alloca %IntOption
  %t27 = getelementptr inbounds %IntOption, %IntOption* %t26, i32 0, i32 0
  store i32 1, i32* %t27
  %t28 = getelementptr inbounds %IntOption, %IntOption* %t26, i32 0, i32 1
  %t29 = bitcast [1 x i64]* %t28 to { i32 }*
  %t30 = load i32, i32* %t2
  %t31 = getelementptr inbounds { i32 }, { i32 }* %t29, i32 0, i32 0
  store i32 %t30, i32* %t31
  %t32 = load %IntOption, %IntOption* %t26
  ret %IntOption %t32
if_else_10:
  br label %if_end_11
if_end_11:
  %t33 = alloca %IntOption
  %t34 = getelementptr inbounds %IntOption, %IntOption* %t33, i32 0, i32 0
  store i32 0, i32* %t34
  %t35 = load %IntOption, %IntOption* %t33
  ret %IntOption %t35
}

define i32 @describe_option(%IntOption %o) {
entry:
  %t0 = alloca %IntOption
  store %IntOption %o, %IntOption* %t0
  br label %match_scrutinee_2
match_scrutinee_2:
  %t4 = getelementptr inbounds %IntOption, %IntOption* %t0, i32 0, i32 0
  %t5 = load i32, i32* %t4
  %t3 = icmp eq i32 %t5, 1
  br i1 %t3, label %match_then_0, label %match_next_0
match_then_0:
  %t6 = getelementptr inbounds %IntOption, %IntOption* %t0, i32 0, i32 1
  %t7 = bitcast [1 x i64]* %t6 to { i32 }*
  %t8 = getelementptr inbounds { i32 }, { i32 }* %t7, i32 0, i32 0
  %t9 = load i32, i32* %t8
  ret i32 %t9
match_next_0:
  %t11 = getelementptr inbounds %IntOption, %IntOption* %t0, i32 0, i32 0
  %t12 = load i32, i32* %t11
  %t10 = icmp eq i32 %t12, 0
  br i1 %t10, label %match_then_1, label %match_next_1
match_then_1:
  %t13 = sub i32 0, 1
  ret i32 %t13
match_next_1:
  br label %match_end_1
match_end_1:
  unreachable
}

define i32 @unwrap_or(%IntOption %o, i32 %default) {
entry:
  %t0 = alloca %IntOption
  store %IntOption %o, %IntOption* %t0
  %t1 = alloca i32
  store i32 %default, i32* %t1
  br label %match_scrutinee_3
match_scrutinee_3:
  %t5 = getelementptr inbounds %IntOption, %IntOption* %t0, i32 0, i32 0
  %t6 = load i32, i32* %t5
  %t4 = icmp eq i32 %t6, 1
  br i1 %t4, label %match_then_0, label %match_next_0
match_then_0:
  %t7 = getelementptr inbounds %IntOption, %IntOption* %t0, i32 0, i32 1
  %t8 = bitcast [1 x i64]* %t7 to { i32 }*
  %t9 = getelementptr inbounds { i32 }, { i32 }* %t8, i32 0, i32 0
  %t10 = load i32, i32* %t9
  br label %match_end_2
match_next_0:
  %t12 = getelementptr inbounds %IntOption, %IntOption* %t0, i32 0, i32 0
  %t13 = load i32, i32* %t12
  %t11 = icmp eq i32 %t13, 0
  br i1 %t11, label %match_then_1, label %match_next_1
match_then_1:
  %t14 = load i32, i32* %t1
  br label %match_end_2
match_next_1:
  br label %match_end_2
match_end_2:
  %t15 = phi i32 [ %t10, %match_then_0 ], [ %t14, %match_then_1 ], [ undef, %match_next_1 ]
  ret i32 %t15
}

define void @describe_sign(i32 %x) {
entry:
  %t0 = alloca i32
  store i32 %x, i32* %t0
  %t1 = load i32, i32* %t0
  br label %match_scrutinee_3
match_scrutinee_3:
  %t4 = icmp sle i32 %t1, 0
  br i1 %t4, label %match_then_0, label %match_next_0
match_then_0:
  %t6 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.0, i64 0, i64 0
  %t5 = alloca i8*
  store i8* %t6, i8** %t5
  %t7 = load i8*, i8** %t5
  call i32 (i8*, ...) @printf(i8* %t7)
  %t8 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t8)
  br label %match_end_2
match_next_0:
  %t10 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.2, i64 0, i64 0
  %t9 = alloca i8*
  store i8* %t10, i8** %t9
  %t11 = load i8*, i8** %t9
  call i32 (i8*, ...) @printf(i8* %t11)
  %t12 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t12)
  br label %match_end_2
match_end_2:
  %t14 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.4, i64 0, i64 0
  %t13 = alloca i8*
  store i8* %t14, i8** %t13
  %t15 = load i8*, i8** %t13
  call i32 (i8*, ...) @printf(i8* %t15)
  %t16 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t16)
  ret void
}

define void @print_div(%DivResult %r) {
entry:
  %t0 = alloca %DivResult
  store %DivResult %r, %DivResult* %t0
  br label %match_scrutinee_2
match_scrutinee_2:
  %t4 = getelementptr inbounds %DivResult, %DivResult* %t0, i32 0, i32 0
  %t5 = load i32, i32* %t4
  %t3 = icmp eq i32 %t5, 0
  br i1 %t3, label %match_then_0, label %match_next_0
match_then_0:
  %t6 = getelementptr inbounds %DivResult, %DivResult* %t0, i32 0, i32 1
  %t7 = bitcast [1 x i64]* %t6 to { i32 }*
  %t8 = getelementptr inbounds { i32 }, { i32 }* %t7, i32 0, i32 0
  %t9 = load i32, i32* %t8
  %t10 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t10, i32 %t9)
  br label %match_end_1
match_next_0:
  %t12 = getelementptr inbounds %DivResult, %DivResult* %t0, i32 0, i32 0
  %t13 = load i32, i32* %t12
  %t11 = icmp eq i32 %t13, 1
  br i1 %t11, label %match_then_1, label %match_next_1
match_then_1:
  %t14 = getelementptr inbounds %DivResult, %DivResult* %t0, i32 0, i32 1
  %t15 = bitcast [1 x i64]* %t14 to { i32 }*
  %t16 = getelementptr inbounds { i32 }, { i32 }* %t15, i32 0, i32 0
  %t17 = load i32, i32* %t16
  %t18 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t18, i32 %t17)
  br label %match_end_1
match_next_1:
  br label %match_end_1
match_end_1:
  ret void
}

define i32 @area(%Shape %s) {
entry:
  %t0 = alloca %Shape
  store %Shape %s, %Shape* %t0
  br label %match_scrutinee_2
match_scrutinee_2:
  %t4 = getelementptr inbounds %Shape, %Shape* %t0, i32 0, i32 0
  %t5 = load i32, i32* %t4
  %t3 = icmp eq i32 %t5, 0
  br i1 %t3, label %match_then_0, label %match_next_0
match_then_0:
  %t6 = getelementptr inbounds %Shape, %Shape* %t0, i32 0, i32 1
  %t7 = bitcast [1 x i64]* %t6 to { i32 }*
  %t8 = getelementptr inbounds { i32 }, { i32 }* %t7, i32 0, i32 0
  %t9 = load i32, i32* %t8
  %t10 = mul i32 3, %t9
  %t11 = load i32, i32* %t8
  %t12 = mul i32 %t10, %t11
  ret i32 %t12
match_next_0:
  %t14 = getelementptr inbounds %Shape, %Shape* %t0, i32 0, i32 0
  %t15 = load i32, i32* %t14
  %t13 = icmp eq i32 %t15, 1
  br i1 %t13, label %match_then_1, label %match_next_1
match_then_1:
  %t16 = getelementptr inbounds %Shape, %Shape* %t0, i32 0, i32 1
  %t17 = bitcast [1 x i64]* %t16 to { i32, i32 }*
  %t18 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t17, i32 0, i32 0
  %t19 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t17, i32 0, i32 1
  %t20 = load i32, i32* %t18
  %t21 = load i32, i32* %t19
  %t22 = mul i32 %t20, %t21
  ret i32 %t22
match_next_1:
  br label %match_end_1
match_end_1:
  unreachable
}

define i32 @main() {
entry:
  %t0 = call %DivResult @safe_div(i32 10, i32 2)
  call void @print_div(%DivResult %t0)
  %t1 = call %DivResult @safe_div(i32 10, i32 0)
  call void @print_div(%DivResult %t1)
  %t2 = call %IntOption @first_even(i32 1, i32 3, i32 4)
  %t3 = call i32 @describe_option(%IntOption %t2)
  %t4 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t4, i32 %t3)
  %t5 = call %IntOption @first_even(i32 1, i32 3, i32 5)
  %t6 = call i32 @describe_option(%IntOption %t5)
  %t7 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t7, i32 %t6)
  %t8 = alloca %Shape
  %t9 = getelementptr inbounds %Shape, %Shape* %t8, i32 0, i32 0
  store i32 0, i32* %t9
  %t10 = getelementptr inbounds %Shape, %Shape* %t8, i32 0, i32 1
  %t11 = bitcast [1 x i64]* %t10 to { i32 }*
  %t12 = getelementptr inbounds { i32 }, { i32 }* %t11, i32 0, i32 0
  store i32 2, i32* %t12
  %t13 = load %Shape, %Shape* %t8
  %t14 = call i32 @area(%Shape %t13)
  %t15 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t15, i32 %t14)
  %t16 = alloca %Shape
  %t17 = getelementptr inbounds %Shape, %Shape* %t16, i32 0, i32 0
  store i32 1, i32* %t17
  %t18 = getelementptr inbounds %Shape, %Shape* %t16, i32 0, i32 1
  %t19 = bitcast [1 x i64]* %t18 to { i32, i32 }*
  %t20 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t19, i32 0, i32 0
  store i32 3, i32* %t20
  %t21 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t19, i32 0, i32 1
  store i32 4, i32* %t21
  %t22 = load %Shape, %Shape* %t16
  %t23 = call i32 @area(%Shape %t22)
  %t24 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t24, i32 %t23)
  %t25 = alloca %IntOption
  %t26 = getelementptr inbounds %IntOption, %IntOption* %t25, i32 0, i32 0
  store i32 1, i32* %t26
  %t27 = getelementptr inbounds %IntOption, %IntOption* %t25, i32 0, i32 1
  %t28 = bitcast [1 x i64]* %t27 to { i32 }*
  %t29 = getelementptr inbounds { i32 }, { i32 }* %t28, i32 0, i32 0
  store i32 7, i32* %t29
  %t30 = load %IntOption, %IntOption* %t25
  %t31 = sub i32 0, 1
  %t32 = call i32 @unwrap_or(%IntOption %t30, i32 %t31)
  %t33 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t33, i32 %t32)
  %t34 = alloca %IntOption
  %t35 = getelementptr inbounds %IntOption, %IntOption* %t34, i32 0, i32 0
  store i32 0, i32* %t35
  %t36 = load %IntOption, %IntOption* %t34
  %t37 = sub i32 0, 1
  %t38 = call i32 @unwrap_or(%IntOption %t36, i32 %t37)
  %t39 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t39, i32 %t38)
  %t40 = sub i32 0, 3
  call void @describe_sign(i32 %t40)
  call void @describe_sign(i32 4)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [13 x i8] c"non-positive\00"
@.str.1 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.2 = private unnamed_addr constant [9 x i8] c"positive\00"
@.str.3 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.4 = private unnamed_addr constant [16 x i8] c"done describing\00"
@.str.5 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.6 = private unnamed_addr constant [8 x i8] c"ok: %d\0A\00"
@.str.7 = private unnamed_addr constant [9 x i8] c"err: %d\0A\00"
@.str.8 = private unnamed_addr constant [11 x i8] c"found: %d\0A\00"
@.str.9 = private unnamed_addr constant [11 x i8] c"found: %d\0A\00"
@.str.10 = private unnamed_addr constant [17 x i8] c"circle area: %d\0A\00"
@.str.11 = private unnamed_addr constant [15 x i8] c"rect area: %d\0A\00"
@.str.12 = private unnamed_addr constant [29 x i8] c"unwrap_or(Some(7), -1) = %d\0A\00"
@.str.13 = private unnamed_addr constant [26 x i8] c"unwrap_or(None, -1) = %d\0A\00"
