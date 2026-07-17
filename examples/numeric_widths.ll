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

%Registers = type { i8, i16, i32 }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca %Registers
  %t2 = alloca %Registers
  %t19 = alloca i8
  %t21 = alloca i8
  %t31 = alloca i64
  %t33 = alloca i64
  %t42 = alloca double
  %t44 = alloca double
  %t50 = alloca i32
  %t52 = alloca i32
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t3 = trunc i32 200 to i8
  %t4 = getelementptr inbounds %Registers, %Registers* %t2, i32 0, i32 0
  store i8 %t3, i8* %t4
  %t5 = sub i32 0, 1000
  %t6 = trunc i32 %t5 to i16
  %t7 = getelementptr inbounds %Registers, %Registers* %t2, i32 0, i32 1
  store i16 %t6, i16* %t7
  %t8 = getelementptr inbounds %Registers, %Registers* %t2, i32 0, i32 2
  store i32 65536, i32* %t8
  %t9 = load %Registers, %Registers* %t2
  store %Registers %t9, %Registers* %t1
  %t10 = getelementptr inbounds %Registers, %Registers* %t1, i32 0, i32 0
  %t11 = load i8, i8* %t10
  %t12 = getelementptr inbounds %Registers, %Registers* %t1, i32 0, i32 1
  %t13 = load i16, i16* %t12
  %t14 = getelementptr inbounds %Registers, %Registers* %t1, i32 0, i32 2
  %t15 = load i32, i32* %t14
  %t16 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.0, i64 0, i64 0
  %t17 = zext i8 %t11 to i32
  %t18 = sext i16 %t13 to i32
  call i32 (i8*, ...) @printf(i8* %t16, i32 %t17, i32 %t18, i32 %t15)
  %t20 = trunc i32 250 to i8
  store i8 %t20, i8* %t19
  %t22 = trunc i32 5 to i8
  store i8 %t22, i8* %t21
  %t23 = load i8, i8* %t19
  %t24 = load i8, i8* %t21
  %t25 = call { i8, i1 } @llvm.uadd.with.overflow.i8(i8 %t23, i8 %t24)
  %t26 = extractvalue { i8, i1 } %t25, 0
  %t27 = extractvalue { i8, i1 } %t25, 1
  br i1 %t27, label %int_overflow_fail_0, label %int_overflow_ok_1
int_overflow_fail_0:
  %t28 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t28)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_1:
  %t29 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.2, i64 0, i64 0
  %t30 = zext i8 %t26 to i32
  call i32 (i8*, ...) @printf(i8* %t29, i32 %t30)
  %t32 = sext i32 1000000000 to i64
  store i64 %t32, i64* %t31
  %t34 = sext i32 8 to i64
  store i64 %t34, i64* %t33
  %t35 = load i64, i64* %t31
  %t36 = load i64, i64* %t33
  %t37 = call { i64, i1 } @llvm.smul.with.overflow.i64(i64 %t35, i64 %t36)
  %t38 = extractvalue { i64, i1 } %t37, 0
  %t39 = extractvalue { i64, i1 } %t37, 1
  br i1 %t39, label %int_overflow_fail_2, label %int_overflow_ok_3
int_overflow_fail_2:
  %t40 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.3, i64 0, i64 0
  call i32 @puts(i8* %t40)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_3:
  %t41 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t41, i64 %t38)
  %t43 = sitofp i32 22 to double
  store double %t43, double* %t42
  %t45 = sitofp i32 7 to double
  store double %t45, double* %t44
  %t46 = load double, double* %t42
  %t47 = load double, double* %t44
  %t48 = fdiv double %t46, %t47
  %t49 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t49, double %t48)
  %t51 = add i32 65, 1
  store i32 %t51, i32* %t50
  %t53 = load i32, i32* %t50
  store i32 %t53, i32* %t52
  %t54 = load i32, i32* %t52
  %t55 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t55, i32 %t54)
  %t56 = icmp ult i32 97, 98
  %t57 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.7, i64 0, i64 0
  %t58 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.8, i64 0, i64 0
  %t59 = select i1 %t56, i8* %t57, i8* %t58
  %t60 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t60, i8* %t59)
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
