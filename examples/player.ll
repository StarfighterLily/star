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
declare i8* @CreateSemaphoreA(i8*, i32, i32, i8*)
declare i32 @ReleaseSemaphore(i8*, i32, i32*)
declare i32 @GetCurrentThreadId()
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

define i8* @star_rc_alloc(i64 %size, i8* %release_fn) {
entry:
  %total = add i64 %size, 16
  %raw = call i8* @malloc(i64 %total)
  %hdr = bitcast i8* %raw to i64*
  store i64 1, i64* %hdr
  %relfn_slot_i8 = getelementptr inbounds i8, i8* %raw, i64 8
  %relfn_slot = bitcast i8* %relfn_slot_i8 to i8**
  store i8* %release_fn, i8** %relfn_slot
  %data = getelementptr inbounds i8, i8* %raw, i64 16
  ret i8* %data
}

define void @star_rc_retain(i8* %p) {
entry:
  %isnull = icmp eq i8* %p, null
  br i1 %isnull, label %done, label %do
do:
  %hdr_i8 = getelementptr inbounds i8, i8* %p, i64 -16
  %hdr = bitcast i8* %hdr_i8 to i64*
  %rc = load i64, i64* %hdr
  %is_immortal = icmp eq i64 %rc, -1
  br i1 %is_immortal, label %done, label %incr
incr:
  %rc1 = add i64 %rc, 1
  store i64 %rc1, i64* %hdr
  br label %done
done:
  ret void
}

define void @star_rc_release(i8* %p) {
entry:
  %isnull = icmp eq i8* %p, null
  br i1 %isnull, label %done, label %do
do:
  %hdr_i8 = getelementptr inbounds i8, i8* %p, i64 -16
  %hdr = bitcast i8* %hdr_i8 to i64*
  %rc = load i64, i64* %hdr
  %is_immortal = icmp eq i64 %rc, -1
  br i1 %is_immortal, label %done, label %decr
decr:
  %rc1 = sub i64 %rc, 1
  store i64 %rc1, i64* %hdr
  %iszero = icmp eq i64 %rc1, 0
  br i1 %iszero, label %free, label %done
free:
  %relfn_slot_i8 = getelementptr inbounds i8, i8* %p, i64 -8
  %relfn_slot = bitcast i8* %relfn_slot_i8 to i8**
  %relfn = load i8*, i8** %relfn_slot
  %relfn_isnull = icmp eq i8* %relfn, null
  br i1 %relfn_isnull, label %dofree, label %callrelfn
callrelfn:
  %relfn_typed = bitcast i8* %relfn to void (i8*)*
  call void %relfn_typed(i8* %p)
  br label %dofree
dofree:
  call void @free(i8* %hdr_i8)
  br label %done
done:
  ret void
}

%Vec3 = type { float, float, float }
%Player = type { i32, <3 x float>, i8* }
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
  br label %match_scrutinee_13
match_scrutinee_13:
  %t14 = icmp sle i32 %t11, 0
  br i1 %t14, label %match_then_0, label %match_next_0
match_then_0:
  %t15 = load %Player*, %Player** %t0
  %t16 = getelementptr inbounds %Player, %Player* %t15, i32 0, i32 2
  %t17 = load i8*, i8** %t16
  %t18 = load i8*, i8** %t16
  %t19 = load i8*, i8** %t18
  call void @star_rc_retain(i8* %t19)
  %t20 = load i8*, i8** %t17
  call void @star_rc_release(i8* %t20)
  %t21 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t21, i8* %t20)
  br label %match_end_12
match_next_0:
  %t22 = load %Player*, %Player** %t0
  %t23 = getelementptr inbounds %Player, %Player* %t22, i32 0, i32 0
  %t24 = load i32, i32* %t23
  %t25 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t25, i32 %t24)
  br label %match_end_12
match_end_12:
  ret void
}

define i32 @remaining_health(%Player* %self) {
entry:
  %t0 = alloca %Player*
  store %Player* %self, %Player** %t0
  %t1 = load %Player*, %Player** %t0
  %t2 = getelementptr inbounds %Player, %Player* %t1, i32 0, i32 0
  %t3 = load i32, i32* %t2
  ret i32 %t3
}

define i32 @main() {
entry:
  %t0 = alloca %Player
  %t1 = alloca %Player
  %t2 = getelementptr inbounds %Player, %Player* %t1, i32 0, i32 0
  store i32 100, i32* %t2
  %t3 = sitofp i32 0 to float
  %t4 = insertelement <3 x float> undef, float %t3, i32 0
  %t5 = sitofp i32 0 to float
  %t6 = insertelement <3 x float> %t4, float %t5, i32 1
  %t7 = sitofp i32 0 to float
  %t8 = insertelement <3 x float> %t6, float %t7, i32 2
  %t9 = getelementptr inbounds %Player, %Player* %t1, i32 0, i32 1
  store <3 x float> %t8, <3 x float>* %t9
  %t11 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t10 = alloca i8*
  store i8* %t11, i8** %t10
  %t12 = getelementptr inbounds %Player, %Player* %t1, i32 0, i32 2
  store i8* %t10, i8** %t12
  %t13 = load %Player, %Player* %t1
  store %Player %t13, %Player* %t0
  %t14 = call i32 @remaining_health(%Player* %t0)
  %t15 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t15, i32 %t14)
  call void @take_damage(%Player* %t0, i32 150)
  %t17 = getelementptr inbounds %Player, %Player* %t0, i32 0, i32 2
  %t18 = load i8*, i8** %t17
  %t19 = load i8*, i8** %t18
  call void @star_rc_release(i8* %t19)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [18 x i8] c"%s has perished.\0A\00"
@.str.1 = private unnamed_addr constant [21 x i8] c"Health critical: %d\0A\00"
@.str.2 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"Hero\00" }
@.str.3 = private unnamed_addr constant [15 x i8] c"remaining: %d\0A\00"
