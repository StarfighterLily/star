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

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca i8
  %t3 = alloca i8
  %t5 = alloca i32
  %t16 = alloca i8
  %t18 = alloca i8
  %t25 = alloca i32
  %t26 = alloca i32
  %t37 = alloca i16
  %t39 = alloca i16
  %t48 = alloca i8
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t2 = trunc i32 250 to i8
  store i8 %t2, i8* %t1
  %t4 = trunc i32 1 to i8
  store i8 %t4, i8* %t3
  store i32 0, i32* %t5
  br label %while_cond_0
while_cond_0:
  %t6 = load i32, i32* %t5
  %t7 = icmp slt i32 %t6, 10
  br i1 %t7, label %while_body_1, label %while_else_2
while_body_1:
  %t8 = load i8, i8* %t1
  %t9 = load i8, i8* %t3
  %t10 = add i8 %t8, %t9
  store i8 %t10, i8* %t1
  %t11 = load i32, i32* %t5
  %t12 = add i32 %t11, 1
  store i32 %t12, i32* %t5
  br label %while_cond_0
while_else_2:
  br label %while_end_3
while_end_3:
  %t13 = load i8, i8* %t1
  %t14 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.0, i64 0, i64 0
  %t15 = zext i8 %t13 to i32
  call i32 (i8*, ...) @printf(i8* %t14, i32 %t15)
  %t17 = trunc i32 127 to i8
  store i8 %t17, i8* %t16
  %t19 = trunc i32 1 to i8
  store i8 %t19, i8* %t18
  %t20 = load i8, i8* %t16
  %t21 = load i8, i8* %t18
  %t22 = add i8 %t20, %t21
  %t23 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.1, i64 0, i64 0
  %t24 = sext i8 %t22 to i32
  call i32 (i8*, ...) @printf(i8* %t23, i32 %t24)
  store i32 -2147483648, i32* %t25
  store i32 -1, i32* %t26
  %t27 = load i32, i32* %t25
  %t28 = load i32, i32* %t26
  %t29 = icmp eq i32 %t28, 0
  br i1 %t29, label %wrap_div_zero_fail_4, label %wrap_div_zero_ok_5
wrap_div_zero_fail_4:
  %t30 = getelementptr inbounds [41 x i8], [41 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t30)
  call void @exit(i32 1)
  unreachable
wrap_div_zero_ok_5:
  %t31 = icmp eq i32 %t27, -2147483648
  %t32 = icmp eq i32 %t28, -1
  %t33 = and i1 %t31, %t32
  br i1 %t33, label %wrap_div_overflow_6, label %wrap_div_normal_7
wrap_div_overflow_6:
  br label %wrap_div_join_8
wrap_div_normal_7:
  %t34 = sdiv i32 %t27, %t28
  br label %wrap_div_join_8
wrap_div_join_8:
  %t35 = phi i32 [ -2147483648, %wrap_div_overflow_6 ], [ %t34, %wrap_div_normal_7 ]
  %t36 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t36, i32 %t35)
  %t38 = trunc i32 100 to i16
  store i16 %t38, i16* %t37
  %t40 = trunc i32 200 to i16
  store i16 %t40, i16* %t39
  %t41 = load i16, i16* %t37
  %t42 = load i16, i16* %t39
  %t43 = icmp ult i16 %t41, %t42
  %t44 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.4, i64 0, i64 0
  %t45 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.5, i64 0, i64 0
  %t46 = select i1 %t43, i8* %t44, i8* %t45
  %t47 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t47, i8* %t46)
  %t49 = load i8, i8* %t1
  store i8 %t49, i8* %t48
  %t50 = load i8, i8* %t48
  %t51 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.7, i64 0, i64 0
  %t52 = zext i8 %t50 to i32
  call i32 (i8*, ...) @printf(i8* %t51, i32 %t52)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [37 x i8] c"frame_counter after wraparound = %u\0A\00"
@.str.1 = private unnamed_addr constant [25 x i8] c"i8::MAX + 1 wraps to %d\0A\00"
@.str.2 = private unnamed_addr constant [41 x i8] c"star runtime error: integer `/` by zero\0A\00"
@.str.3 = private unnamed_addr constant [27 x i8] c"i32::MIN / -1 wraps to %d\0A\00"
@.str.4 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.5 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.6 = private unnamed_addr constant [13 x i8] c"a < b is %s\0A\00"
@.str.7 = private unnamed_addr constant [16 x i8] c"unwrapped = %u\0A\00"
