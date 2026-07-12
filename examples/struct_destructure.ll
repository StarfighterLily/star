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
declare i8* @fopen(i8*, i8*)
declare i32 @fclose(i8*)
declare i64 @fread(i8*, i64, i64, i8*)
declare i64 @fwrite(i8*, i64, i64, i8*)
declare i32 @fseek(i8*, i32, i32)
declare i32 @ftell(i8*)
declare i32 @fgetc(i8*)
declare i8* @getenv(i8*)
declare i32 @_putenv(i8*)
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

@star.argc = global i32 0
@star.argv = global i8** null

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

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
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
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [9 x i8] c"sum: %d\0A\00"
@.str.1 = private unnamed_addr constant [15 x i8] c"length_sq: %d\0A\00"
