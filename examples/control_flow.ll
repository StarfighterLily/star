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

define void @print_dir(i32 %d) {
entry:
  %t0 = alloca i32
  store i32 %d, i32* %t0
  %t1 = load i32, i32* %t0
  br label %match_scrutinee_3
match_scrutinee_3:
  %t4 = icmp eq i32 %t1, 0
  br i1 %t4, label %match_then_0, label %match_next_0
match_then_0:
  %t6 = getelementptr inbounds { i64, i8*, [11 x i8] }, { i64, i8*, [11 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t5 = alloca i8*
  store i8* %t6, i8** %t5
  %t7 = load i8*, i8** %t5
  call i32 (i8*, ...) @printf(i8* %t7)
  %t8 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t8)
  br label %match_end_2
match_next_0:
  %t9 = icmp eq i32 %t1, 1
  br i1 %t9, label %match_then_1, label %match_next_1
match_then_1:
  %t11 = getelementptr inbounds { i64, i8*, [11 x i8] }, { i64, i8*, [11 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t10 = alloca i8*
  store i8* %t11, i8** %t10
  %t12 = load i8*, i8** %t10
  call i32 (i8*, ...) @printf(i8* %t12)
  %t13 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t13)
  br label %match_end_2
match_next_1:
  %t14 = icmp eq i32 %t1, 2
  br i1 %t14, label %match_then_2, label %match_next_2
match_then_2:
  %t16 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t15 = alloca i8*
  store i8* %t16, i8** %t15
  %t17 = load i8*, i8** %t15
  call i32 (i8*, ...) @printf(i8* %t17)
  %t18 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t18)
  br label %match_end_2
match_next_2:
  %t19 = icmp eq i32 %t1, 3
  br i1 %t19, label %match_then_3, label %match_next_3
match_then_3:
  %t21 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t20 = alloca i8*
  store i8* %t21, i8** %t20
  %t22 = load i8*, i8** %t20
  call i32 (i8*, ...) @printf(i8* %t22)
  %t23 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t23)
  br label %match_end_2
match_next_3:
  br label %match_end_2
match_end_2:
  ret void
}

define i32 @sum_with_skip_and_stop() {
entry:
  %t0 = alloca i32
  store i32 0, i32* %t0
  %t1 = alloca i32
  store i32 0, i32* %t1
  br label %for_cond_0
for_cond_0:
  %t2 = load i32, i32* %t1
  %t3 = icmp slt i32 %t2, 10
  br i1 %t3, label %for_body_1, label %for_end_3
for_body_1:
  %t4 = load i32, i32* %t1
  %t5 = icmp eq i32 %t4, 5
  br i1 %t5, label %if_then_4, label %if_else_5
if_then_4:
  br label %for_step_2
if_else_5:
  br label %if_end_6
if_end_6:
  %t6 = load i32, i32* %t1
  %t7 = icmp eq i32 %t6, 8
  br i1 %t7, label %if_then_7, label %if_else_8
if_then_7:
  br label %for_end_3
if_else_8:
  br label %if_end_9
if_end_9:
  %t8 = load i32, i32* %t1
  %t9 = load i32, i32* %t0
  %t10 = add i32 %t9, %t8
  store i32 %t10, i32* %t0
  br label %for_step_2
for_step_2:
  %t11 = load i32, i32* %t1
  %t12 = add i32 %t11, 1
  store i32 %t12, i32* %t1
  br label %for_cond_0
for_end_3:
  %t13 = load i32, i32* %t0
  ret i32 %t13
}

define i32 @count_with_nested_break() {
entry:
  %t0 = alloca i32
  store i32 0, i32* %t0
  %t1 = alloca i32
  store i32 0, i32* %t1
  br label %for_cond_10
for_cond_10:
  %t2 = load i32, i32* %t1
  %t3 = icmp slt i32 %t2, 3
  br i1 %t3, label %for_body_11, label %for_end_13
for_body_11:
  %t4 = alloca i32
  store i32 0, i32* %t4
  br label %for_cond_14
for_cond_14:
  %t5 = load i32, i32* %t4
  %t6 = icmp slt i32 %t5, 3
  br i1 %t6, label %for_body_15, label %for_end_17
for_body_15:
  %t7 = load i32, i32* %t4
  %t8 = icmp eq i32 %t7, 1
  br i1 %t8, label %if_then_18, label %if_else_19
if_then_18:
  br label %for_end_17
if_else_19:
  br label %if_end_20
if_end_20:
  %t9 = load i32, i32* %t0
  %t10 = add i32 %t9, 1
  store i32 %t10, i32* %t0
  br label %for_step_16
for_step_16:
  %t11 = load i32, i32* %t4
  %t12 = add i32 %t11, 1
  store i32 %t12, i32* %t4
  br label %for_cond_14
for_end_17:
  br label %for_step_12
for_step_12:
  %t13 = load i32, i32* %t1
  %t14 = add i32 %t13, 1
  store i32 %t14, i32* %t1
  br label %for_cond_10
for_end_13:
  %t15 = load i32, i32* %t0
  ret i32 %t15
}

define i32 @while_break_at_four() {
entry:
  %t0 = alloca i32
  store i32 0, i32* %t0
  br label %while_cond_21
while_cond_21:
  br i1 true, label %while_body_22, label %while_end_24
while_body_22:
  %t1 = load i32, i32* %t0
  %t2 = add i32 %t1, 1
  store i32 %t2, i32* %t0
  %t3 = load i32, i32* %t0
  %t4 = icmp eq i32 %t3, 4
  br i1 %t4, label %if_then_25, label %if_else_26
if_then_25:
  br label %while_end_24
if_else_26:
  br label %if_end_27
if_end_27:
  br label %while_cond_21
while_else_23:
  br label %while_end_24
while_end_24:
  %t5 = load i32, i32* %t0
  ret i32 %t5
}

define i32 @main() {
entry:
  %t0 = call i32 @sum_with_skip_and_stop()
  %t1 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1, i32 %t0)
  %t2 = call i32 @count_with_nested_break()
  %t3 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t3, i32 %t2)
  %t4 = call i32 @while_break_at_four()
  %t5 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t5, i32 %t4)
  call void @print_dir(i32 0)
  call void @print_dir(i32 3)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [11 x i8] } { i64 -1, i8* null, [11 x i8] c"dir: north\00" }
@.str.1 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.2 = private unnamed_addr constant { i64, i8*, [11 x i8] } { i64 -1, i8* null, [11 x i8] c"dir: south\00" }
@.str.3 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.4 = private unnamed_addr constant { i64, i8*, [10 x i8] } { i64 -1, i8* null, [10 x i8] c"dir: east\00" }
@.str.5 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.6 = private unnamed_addr constant { i64, i8*, [10 x i8] } { i64 -1, i8* null, [10 x i8] c"dir: west\00" }
@.str.7 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.8 = private unnamed_addr constant [9 x i8] c"sum: %d\0A\00"
@.str.9 = private unnamed_addr constant [12 x i8] c"nested: %d\0A\00"
@.str.10 = private unnamed_addr constant [11 x i8] c"while: %d\0A\00"
