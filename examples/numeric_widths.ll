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
declare i32 @_putenv(i8*)
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

%Registers = type { i8, i16, i32 }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = alloca %Registers
  %t1 = alloca %Registers
  %t2 = trunc i32 200 to i8
  %t3 = getelementptr inbounds %Registers, %Registers* %t1, i32 0, i32 0
  store i8 %t2, i8* %t3
  %t4 = sub i32 0, 1000
  %t5 = trunc i32 %t4 to i16
  %t6 = getelementptr inbounds %Registers, %Registers* %t1, i32 0, i32 1
  store i16 %t5, i16* %t6
  %t7 = getelementptr inbounds %Registers, %Registers* %t1, i32 0, i32 2
  store i32 65536, i32* %t7
  %t8 = load %Registers, %Registers* %t1
  store %Registers %t8, %Registers* %t0
  %t9 = getelementptr inbounds %Registers, %Registers* %t0, i32 0, i32 0
  %t10 = load i8, i8* %t9
  %t11 = getelementptr inbounds %Registers, %Registers* %t0, i32 0, i32 1
  %t12 = load i16, i16* %t11
  %t13 = getelementptr inbounds %Registers, %Registers* %t0, i32 0, i32 2
  %t14 = load i32, i32* %t13
  %t15 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.0, i64 0, i64 0
  %t16 = zext i8 %t10 to i32
  %t17 = sext i16 %t12 to i32
  call i32 (i8*, ...) @printf(i8* %t15, i32 %t16, i32 %t17, i32 %t14)
  %t18 = alloca i8
  %t19 = trunc i32 250 to i8
  store i8 %t19, i8* %t18
  %t20 = alloca i8
  %t21 = trunc i32 5 to i8
  store i8 %t21, i8* %t20
  %t22 = load i8, i8* %t18
  %t23 = load i8, i8* %t20
  %t24 = call { i8, i1 } @llvm.uadd.with.overflow.i8(i8 %t22, i8 %t23)
  %t25 = extractvalue { i8, i1 } %t24, 0
  %t26 = extractvalue { i8, i1 } %t24, 1
  br i1 %t26, label %int_overflow_fail_0, label %int_overflow_ok_1
int_overflow_fail_0:
  %t27 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t27)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_1:
  %t28 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.2, i64 0, i64 0
  %t29 = zext i8 %t25 to i32
  call i32 (i8*, ...) @printf(i8* %t28, i32 %t29)
  %t30 = alloca i64
  %t31 = sext i32 1000000000 to i64
  store i64 %t31, i64* %t30
  %t32 = alloca i64
  %t33 = sext i32 8 to i64
  store i64 %t33, i64* %t32
  %t34 = load i64, i64* %t30
  %t35 = load i64, i64* %t32
  %t36 = call { i64, i1 } @llvm.smul.with.overflow.i64(i64 %t34, i64 %t35)
  %t37 = extractvalue { i64, i1 } %t36, 0
  %t38 = extractvalue { i64, i1 } %t36, 1
  br i1 %t38, label %int_overflow_fail_2, label %int_overflow_ok_3
int_overflow_fail_2:
  %t39 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.3, i64 0, i64 0
  call i32 @puts(i8* %t39)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_3:
  %t40 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t40, i64 %t37)
  %t41 = alloca double
  %t42 = sitofp i32 22 to double
  store double %t42, double* %t41
  %t43 = alloca double
  %t44 = sitofp i32 7 to double
  store double %t44, double* %t43
  %t45 = load double, double* %t41
  %t46 = load double, double* %t43
  %t47 = fdiv double %t45, %t46
  %t48 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t48, double %t47)
  %t49 = alloca i32
  %t50 = add i32 65, 1
  store i32 %t50, i32* %t49
  %t51 = alloca i32
  %t52 = load i32, i32* %t49
  store i32 %t52, i32* %t51
  %t53 = load i32, i32* %t51
  %t54 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t54, i32 %t53)
  %t55 = icmp ult i32 97, 98
  %t56 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.7, i64 0, i64 0
  %t57 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.8, i64 0, i64 0
  %t58 = select i1 %t55, i8* %t56, i8* %t57
  %t59 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t59, i8* %t58)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [17 x i8] c"a=%u x=%d pc=%u\0A\00"
@.str.1 = private unnamed_addr constant [70 x i8] c"star runtime error: unsigned 8-bit integer overflow in `+` operation\0A\00"
@.str.2 = private unnamed_addr constant [14 x i8] c"healed hp=%u\0A\00"
@.str.3 = private unnamed_addr constant [69 x i8] c"star runtime error: signed 64-bit integer overflow in `*` operation\0A\00"
@.str.4 = private unnamed_addr constant [14 x i8] c"world_x=%lld\0A\00"
@.str.5 = private unnamed_addr constant [14 x i8] c"pi_approx=%f\0A\00"
@.str.6 = private unnamed_addr constant [15 x i8] c"next_grade=%c\0A\00"
@.str.7 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.8 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.9 = private unnamed_addr constant [17 x i8] c"'a' < 'b' is %s\0A\00"

