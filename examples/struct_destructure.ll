; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
declare i32 @snprintf(i8*, i64, i8*, ...)
declare i32 @puts(i8*)
declare noalias i8* @malloc(i64)
declare void @free(i8*)
declare void @exit(i32) noreturn
declare i32 @strlen(i8*)
declare i32 @getchar()
declare i8* @memcpy(i8*, i8*, i64)
declare i8* @strcpy(i8*, i8*)
declare i8* @strcat(i8*, i8*)
declare i32 @strcmp(i8*, i8*)
declare i8* @fopen(i8*, i8*)
declare i32 @fclose(i8*)
declare i64 @fread(i8*, i64, i64, i8*)
declare i64 @fwrite(i8*, i64, i64, i8*)
declare i32 @fseek(i8*, i32, i32)
declare i32 @ftell(i8*)
declare i32 @fgetc(i8*)
declare i8* @getenv(i8*)
declare i32 @_putenv_s(i8*, i8*)
declare i32 @WSAStartup(i16, i8*)
declare i8* @socket(i32, i32, i32)
declare i32 @connect(i8*, i8*, i32)
declare i32 @send(i8*, i8*, i32, i32)
declare i32 @recv(i8*, i8*, i32, i32)
declare i32 @closesocket(i8*)
declare i16 @htons(i16)
declare i32 @inet_addr(i8*)
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
declare i8 @llvm.fptosi.sat.i8.f32(float)
declare i8 @llvm.fptosi.sat.i8.f64(double)
declare i8 @llvm.fptoui.sat.i8.f32(float)
declare i8 @llvm.fptoui.sat.i8.f64(double)
declare i16 @llvm.fptosi.sat.i16.f32(float)
declare i16 @llvm.fptosi.sat.i16.f64(double)
declare i16 @llvm.fptoui.sat.i16.f32(float)
declare i16 @llvm.fptoui.sat.i16.f64(double)
declare i32 @llvm.fptosi.sat.i32.f32(float)
declare i32 @llvm.fptosi.sat.i32.f64(double)
declare i32 @llvm.fptoui.sat.i32.f32(float)
declare i32 @llvm.fptoui.sat.i32.f64(double)
declare i64 @llvm.fptosi.sat.i64.f32(float)
declare i64 @llvm.fptosi.sat.i64.f64(double)
declare i64 @llvm.fptoui.sat.i64.f32(float)
declare i64 @llvm.fptoui.sat.i64.f64(double)
declare { i8, i1 } @llvm.sadd.with.overflow.i8(i8, i8)
declare { i8, i1 } @llvm.ssub.with.overflow.i8(i8, i8)
declare { i8, i1 } @llvm.smul.with.overflow.i8(i8, i8)
declare { i8, i1 } @llvm.uadd.with.overflow.i8(i8, i8)
declare { i8, i1 } @llvm.usub.with.overflow.i8(i8, i8)
declare { i8, i1 } @llvm.umul.with.overflow.i8(i8, i8)
declare { i16, i1 } @llvm.sadd.with.overflow.i16(i16, i16)
declare { i16, i1 } @llvm.ssub.with.overflow.i16(i16, i16)
declare { i16, i1 } @llvm.smul.with.overflow.i16(i16, i16)
declare { i16, i1 } @llvm.uadd.with.overflow.i16(i16, i16)
declare { i16, i1 } @llvm.usub.with.overflow.i16(i16, i16)
declare { i16, i1 } @llvm.umul.with.overflow.i16(i16, i16)
declare { i64, i1 } @llvm.sadd.with.overflow.i64(i64, i64)
declare { i64, i1 } @llvm.ssub.with.overflow.i64(i64, i64)
declare { i64, i1 } @llvm.smul.with.overflow.i64(i64, i64)
declare { i64, i1 } @llvm.uadd.with.overflow.i64(i64, i64)
declare { i64, i1 } @llvm.usub.with.overflow.i64(i64, i64)
declare { i64, i1 } @llvm.umul.with.overflow.i64(i64, i64)
declare { i32, i1 } @llvm.uadd.with.overflow.i32(i32, i32)
declare { i32, i1 } @llvm.usub.with.overflow.i32(i32, i32)
declare { i32, i1 } @llvm.umul.with.overflow.i32(i32, i32)

%GenRef = type { i32, i32 }

@frame.buf = global [4096 x i8] zeroinitializer
@frame.off = global i64 0

@star.argc = global i32 0
@star.argv = global i8** null

@rng.state = global i32 123456789

@sym.data = global i8** null
@sym.len = global i64 0
@sym.cap = global i64 0
@sym.lock = global i8* null

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
  %t5 = getelementptr inbounds %Point, %Point* %t0, i32 0, i32 0
  %t6 = getelementptr inbounds %Point, %Point* %t0, i32 0, i32 1
  %t7 = load i32, i32* %t5
  %t8 = load i32, i32* %t6
  %t9 = add i32 %t7, %t8
  ret i32 %t9
match_end_1:
  unreachable
}

define i32 @length_sq(%Line %l) {
entry:
  %t0 = alloca %Line
  %t7 = alloca i32
  %t13 = alloca i32
  store %Line %l, %Line* %t0
  br label %match_scrutinee_2
match_scrutinee_2:
  %t5 = getelementptr inbounds %Line, %Line* %t0, i32 0, i32 0
  %t6 = getelementptr inbounds %Line, %Line* %t0, i32 0, i32 1
  %t8 = getelementptr inbounds %Point, %Point* %t6, i32 0, i32 0
  %t9 = load i32, i32* %t8
  %t10 = getelementptr inbounds %Point, %Point* %t5, i32 0, i32 0
  %t11 = load i32, i32* %t10
  %t12 = sub i32 %t9, %t11
  store i32 %t12, i32* %t7
  %t14 = getelementptr inbounds %Point, %Point* %t6, i32 0, i32 1
  %t15 = load i32, i32* %t14
  %t16 = getelementptr inbounds %Point, %Point* %t5, i32 0, i32 1
  %t17 = load i32, i32* %t16
  %t18 = sub i32 %t15, %t17
  store i32 %t18, i32* %t13
  %t19 = load i32, i32* %t7
  %t20 = load i32, i32* %t7
  %t21 = mul i32 %t19, %t20
  %t22 = load i32, i32* %t13
  %t23 = load i32, i32* %t13
  %t24 = mul i32 %t22, %t23
  %t25 = add i32 %t21, %t24
  ret i32 %t25
match_end_1:
  unreachable
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca %Point
  %t7 = alloca %Line
  %t8 = alloca %Point
  %t13 = alloca %Point
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t2 = getelementptr inbounds %Point, %Point* %t1, i32 0, i32 0
  store i32 3, i32* %t2
  %t3 = getelementptr inbounds %Point, %Point* %t1, i32 0, i32 1
  store i32 4, i32* %t3
  %t4 = load %Point, %Point* %t1
  %t5 = call i32 @manhattan(%Point %t4)
  %t6 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t6, i32 %t5)
  %t9 = getelementptr inbounds %Point, %Point* %t8, i32 0, i32 0
  store i32 0, i32* %t9
  %t10 = getelementptr inbounds %Point, %Point* %t8, i32 0, i32 1
  store i32 0, i32* %t10
  %t11 = load %Point, %Point* %t8
  %t12 = getelementptr inbounds %Line, %Line* %t7, i32 0, i32 0
  store %Point %t11, %Point* %t12
  %t14 = getelementptr inbounds %Point, %Point* %t13, i32 0, i32 0
  store i32 3, i32* %t14
  %t15 = getelementptr inbounds %Point, %Point* %t13, i32 0, i32 1
  store i32 4, i32* %t15
  %t16 = load %Point, %Point* %t13
  %t17 = getelementptr inbounds %Line, %Line* %t7, i32 0, i32 1
  store %Point %t16, %Point* %t17
  %t18 = load %Line, %Line* %t7
  %t19 = call i32 @length_sq(%Line %t18)
  %t20 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t20, i32 %t19)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [9 x i8] c"sum: %d\0A\00"
@.str.1 = private unnamed_addr constant [15 x i8] c"length_sq: %d\0A\00"
