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

%Vec3 = type { float, float, float }
%Player = type { i32, { float, float, float }, i8* }
define void @take_damage(%Player* %self, i32 %amount) {
entry:
  %t0 = alloca %Player*
  store %Player* %self, %Player** %t0
  %t1 = alloca i32
  store i32 %amount, i32* %t1
  %t2 = load i32, i32* %t1
  %t3 = load %Player*, %Player** %t0
  %t4 = getelementptr inbounds %Player, %Player* %t3, i32 0, i32 0
  %t5 = load i32, i32* %t4
  %t6 = sub i32 %t5, %t2
  %t7 = load %Player*, %Player** %t0
  %t8 = getelementptr inbounds %Player, %Player* %t7, i32 0, i32 0
  store i32 %t6, i32* %t8
  %t9 = load %Player*, %Player** %t0
  %t10 = getelementptr inbounds %Player, %Player* %t9, i32 0, i32 0
  %t11 = load i32, i32* %t10
  %t13 = icmp sle i32 %t11, 0
  br i1 %t13, label %match_then_0, label %match_next_0
match_then_0:
  %t14 = load %Player*, %Player** %t0
  %t15 = getelementptr inbounds %Player, %Player* %t14, i32 0, i32 2
  %t16 = load i8*, i8** %t15
  %t17 = load i8*, i8** %t16
  %t18 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t18, i8* %t17)
  br label %match_end_12
match_next_0:
  %t19 = load %Player*, %Player** %t0
  %t20 = getelementptr inbounds %Player, %Player* %t19, i32 0, i32 0
  %t21 = load i32, i32* %t20
  %t22 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t22, i32 %t21)
  br label %match_end_12
match_end_12:
  ret void
}

define void @main() {
entry:
  %t0 = alloca %Player
  %t1 = alloca %Player
  %t2 = getelementptr inbounds %Player, %Player* %t1, i32 0, i32 0
  store i32 100, i32* %t2
  %t3 = alloca { float, float, float }
  %t4 = sitofp i32 0 to float
  %t5 = getelementptr inbounds { float, float, float }, { float, float, float }* %t3, i32 0, i32 0
  store float %t4, float* %t5
  %t6 = sitofp i32 0 to float
  %t7 = getelementptr inbounds { float, float, float }, { float, float, float }* %t3, i32 0, i32 1
  store float %t6, float* %t7
  %t8 = sitofp i32 0 to float
  %t9 = getelementptr inbounds { float, float, float }, { float, float, float }* %t3, i32 0, i32 2
  store float %t8, float* %t9
  %t10 = load { float, float, float }, { float, float, float }* %t3
  %t11 = getelementptr inbounds %Player, %Player* %t1, i32 0, i32 1
  store { float, float, float } %t10, { float, float, float }* %t11
  %t13 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.2, i64 0, i64 0
  %t12 = alloca i8*
  store i8* %t13, i8** %t12
  %t14 = getelementptr inbounds %Player, %Player* %t1, i32 0, i32 2
  store i8* %t12, i8** %t14
  %t15 = load %Player, %Player* %t1
  store %Player %t15, %Player* %t0
  call void @take_damage(%Player* %t0, i32 150)
  ret void
}


; Global Constants
@.str.0 = private unnamed_addr constant [18 x i8] c"%s has perished.\0A\00"
@.str.1 = private unnamed_addr constant [21 x i8] c"Health critical: %d\0A\00"
@.str.2 = private unnamed_addr constant [5 x i8] c"Hero\00"
