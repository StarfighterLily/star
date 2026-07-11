; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
declare i32 @puts(i8*)
declare noalias i8* @malloc(i64)
declare void @free(i8*)
declare void @exit(i32) noreturn
declare i32 @strlen(i8*)
declare i32 @getchar()
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
  %rc = load atomic i64, i64* %hdr seq_cst, align 8
  %is_immortal = icmp eq i64 %rc, -1
  br i1 %is_immortal, label %done, label %incr
incr:
  %rc1 = atomicrmw add i64* %hdr, i64 1 seq_cst
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
  %rc = load atomic i64, i64* %hdr seq_cst, align 8
  %is_immortal = icmp eq i64 %rc, -1
  br i1 %is_immortal, label %done, label %decr
decr:
  %rc_old = atomicrmw sub i64* %hdr, i64 1 seq_cst
  %iszero = icmp eq i64 %rc_old, 1
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

declare i32 @toupper(i32)
declare i32 @atoi(i8*)
declare i8* @getenv(i8*)
define i32 @main() {
entry:
  %t0 = call i32 @toupper(i32 97)
  %t1 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1, i32 %t0)
  %t2 = alloca i8*
  %t3 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.1, i64 0, i32 2, i64 0
  store i8* %t3, i8** %t2
  %t4 = load i8*, i8** %t2
  %t5 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t5)
  call void @star_rc_release(i8* %t4)
  %t6 = call i32 @atoi(i8* %t4)
  %t7 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t7, i32 %t6)
  %t8 = alloca i8*
  %t9 = getelementptr inbounds { i64, i8*, [38 x i8] }, { i64, i8*, [38 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t10 = call i8* @getenv(i8* %t9)
  store i8* %t10, i8** %t8
  %t11 = load i8*, i8** %t8
  %t12 = icmp eq i8* %t11, null
  %t13 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.4, i64 0, i64 0
  %t14 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.5, i64 0, i64 0
  %t15 = select i1 %t12, i8* %t13, i8* %t14
  %t16 = getelementptr inbounds [30 x i8], [30 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t16, i8* %t15)
  %t17 = alloca i8*
  %t18 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t19 = call i8* @getenv(i8* %t18)
  store i8* %t19, i8** %t17
  %t20 = load i8*, i8** %t17
  %t21 = icmp eq i8* %t20, null
  %t22 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.8, i64 0, i64 0
  %t23 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.9, i64 0, i64 0
  %t24 = select i1 %t21, i8* %t22, i8* %t23
  %t25 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t25, i8* %t24)
  %t26 = load i8*, i8** %t17
  %t27 = icmp eq i8* %t26, null
  %t28 = xor i1 true, %t27
  br i1 %t28, label %if_then_0, label %if_else_1
if_then_0:
  %t29 = alloca i8*
  %t30 = load i8*, i8** %t17
  %t31 = call i32 @strlen(i8* %t30)
  %t32 = add i32 %t31, 1
  %t33 = sext i32 %t32 to i64
  %t34 = call i8* @star_rc_alloc(i64 %t33, i8* null)
  call i8* @strcpy(i8* %t34, i8* %t30)
  store i8* %t34, i8** %t29
  %t35 = load i8*, i8** %t29
  %t36 = load i8*, i8** %t29
  call void @star_rc_retain(i8* %t36)
  call void @star_rc_release(i8* %t35)
  %t37 = call i32 @strlen(i8* %t35)
  %t38 = icmp sgt i32 %t37, 0
  %t39 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.11, i64 0, i64 0
  %t40 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.12, i64 0, i64 0
  %t41 = select i1 %t38, i8* %t39, i8* %t40
  %t42 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t42, i8* %t41)
  %t43 = load i8*, i8** %t29
  call void @star_rc_release(i8* %t43)
  br label %if_end_2
if_else_1:
  br label %if_end_2
if_end_2:
  %t44 = icmp eq i8* null, null
  %t45 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.14, i64 0, i64 0
  %t46 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.15, i64 0, i64 0
  %t47 = select i1 %t44, i8* %t45, i8* %t46
  %t48 = getelementptr inbounds [30 x i8], [30 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t48, i8* %t47)
  %t49 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t49)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [17 x i8] c"toupper(97): %d\0A\00"
@.str.1 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"42\00" }
@.str.2 = private unnamed_addr constant [13 x i8] c"atoi(s): %d\0A\00"
@.str.3 = private unnamed_addr constant { i64, i8*, [38 x i8] } { i64 -1, i8* null, [38 x i8] c"STAR_EXAMPLE_DEFINITELY_UNSET_VAR_XYZ\00" }
@.str.4 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.5 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.6 = private unnamed_addr constant [30 x i8] c"is_null(missing env var): %s\0A\00"
@.str.7 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"PATH\00" }
@.str.8 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.9 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.10 = private unnamed_addr constant [19 x i8] c"is_null(PATH): %s\0A\00"
@.str.11 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.12 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.13 = private unnamed_addr constant [21 x i8] c"PATH length > 0: %s\0A\00"
@.str.14 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.15 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.16 = private unnamed_addr constant [30 x i8] c"null_ptr() == null_ptr(): %s\0A\00"
