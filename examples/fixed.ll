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
  %t1 = alloca i32
  %t4 = alloca i32
  %t53 = alloca i32
  %t71 = alloca float
  %t78 = alloca i8
  %t81 = alloca i8
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t2 = fmul float 0x400C000000000000, 0x40F0000000000000
  %t3 = call i32 @llvm.fptosi.sat.i32.f32(float %t2)
  store i32 %t3, i32* %t1
  %t5 = fmul float 0x4000000000000000, 0x40F0000000000000
  %t6 = call i32 @llvm.fptosi.sat.i32.f32(float %t5)
  store i32 %t6, i32* %t4
  %t7 = load i32, i32* %t1
  %t8 = load i32, i32* %t4
  %t9 = call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %t7, i32 %t8)
  %t10 = extractvalue { i32, i1 } %t9, 0
  %t11 = extractvalue { i32, i1 } %t9, 1
  br i1 %t11, label %int_overflow_fail_0, label %int_overflow_ok_1
int_overflow_fail_0:
  %t12 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t12)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_1:
  %t13 = sitofp i32 %t10 to double
  %t14 = fdiv double %t13, 0x40F0000000000000
  %t15 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t15, double %t14)
  %t16 = load i32, i32* %t1
  %t17 = load i32, i32* %t4
  %t18 = call { i32, i1 } @llvm.ssub.with.overflow.i32(i32 %t16, i32 %t17)
  %t19 = extractvalue { i32, i1 } %t18, 0
  %t20 = extractvalue { i32, i1 } %t18, 1
  br i1 %t20, label %int_overflow_fail_2, label %int_overflow_ok_3
int_overflow_fail_2:
  %t21 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t21)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_3:
  %t22 = sitofp i32 %t19 to double
  %t23 = fdiv double %t22, 0x40F0000000000000
  %t24 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t24, double %t23)
  %t25 = load i32, i32* %t1
  %t26 = load i32, i32* %t4
  %t27 = sext i32 %t25 to i128
  %t28 = sext i32 %t26 to i128
  %t29 = mul i128 %t27, %t28
  %t30 = ashr i128 %t29, 16
  %t31 = trunc i128 %t30 to i32
  %t32 = sext i32 %t31 to i128
  %t33 = icmp eq i128 %t32, %t30
  br i1 %t33, label %fixed_overflow_ok_5, label %fixed_overflow_fail_4
fixed_overflow_fail_4:
  %t34 = getelementptr inbounds [62 x i8], [62 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t34)
  call void @exit(i32 1)
  unreachable
fixed_overflow_ok_5:
  %t35 = sitofp i32 %t31 to double
  %t36 = fdiv double %t35, 0x40F0000000000000
  %t37 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t37, double %t36)
  %t38 = load i32, i32* %t1
  %t39 = load i32, i32* %t4
  %t40 = sext i32 %t38 to i128
  %t41 = sext i32 %t39 to i128
  %t42 = shl i128 %t40, 16
  %t43 = icmp eq i128 %t41, 0
  br i1 %t43, label %fixed_div_zero_fail_6, label %fixed_div_zero_ok_7
fixed_div_zero_fail_6:
  %t44 = getelementptr inbounds [57 x i8], [57 x i8]* @.str.6, i64 0, i64 0
  call i32 @puts(i8* %t44)
  call void @exit(i32 1)
  unreachable
fixed_div_zero_ok_7:
  %t45 = sdiv i128 %t42, %t41
  %t46 = trunc i128 %t45 to i32
  %t47 = sext i32 %t46 to i128
  %t48 = icmp eq i128 %t47, %t45
  br i1 %t48, label %fixed_overflow_ok_9, label %fixed_overflow_fail_8
fixed_overflow_fail_8:
  %t49 = getelementptr inbounds [56 x i8], [56 x i8]* @.str.7, i64 0, i64 0
  call i32 @puts(i8* %t49)
  call void @exit(i32 1)
  unreachable
fixed_overflow_ok_9:
  %t50 = sitofp i32 %t46 to double
  %t51 = fdiv double %t50, 0x40F0000000000000
  %t52 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t52, double %t51)
  %t54 = sext i32 10 to i128
  %t55 = shl i128 %t54, 16
  %t56 = trunc i128 %t55 to i32
  %t57 = sext i32 %t56 to i128
  %t58 = icmp eq i128 %t57, %t55
  br i1 %t58, label %fixed_overflow_ok_11, label %fixed_overflow_fail_10
fixed_overflow_fail_10:
  %t59 = getelementptr inbounds [60 x i8], [60 x i8]* @.str.9, i64 0, i64 0
  call i32 @puts(i8* %t59)
  call void @exit(i32 1)
  unreachable
fixed_overflow_ok_11:
  store i32 %t56, i32* %t53
  %t60 = load i32, i32* %t53
  %t61 = sitofp i32 %t60 to double
  %t62 = fdiv double %t61, 0x40F0000000000000
  %t63 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t63, double %t62)
  %t64 = load i32, i32* %t1
  %t65 = load i32, i32* %t53
  %t66 = icmp slt i32 %t64, %t65
  %t67 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.11, i64 0, i64 0
  %t68 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.12, i64 0, i64 0
  %t69 = select i1 %t66, i8* %t67, i8* %t68
  %t70 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t70, i8* %t69)
  %t72 = load i32, i32* %t1
  %t73 = sitofp i32 %t72 to float
  %t74 = fdiv float %t73, 0x40F0000000000000
  store float %t74, float* %t71
  %t75 = load float, float* %t71
  %t76 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.14, i64 0, i64 0
  %t77 = fpext float %t75 to double
  call i32 (i8*, ...) @printf(i8* %t76, double %t77)
  %t79 = fmul float 0x400C000000000000, 0x4030000000000000
  %t80 = call i8 @llvm.fptosi.sat.i8.f32(float %t79)
  store i8 %t80, i8* %t78
  %t82 = fmul float 0x3FF8000000000000, 0x4030000000000000
  %t83 = call i8 @llvm.fptosi.sat.i8.f32(float %t82)
  store i8 %t83, i8* %t81
  %t84 = load i8, i8* %t78
  %t85 = load i8, i8* %t81
  %t86 = sext i8 %t84 to i128
  %t87 = sext i8 %t85 to i128
  %t88 = mul i128 %t86, %t87
  %t89 = ashr i128 %t88, 4
  %t90 = trunc i128 %t89 to i8
  %t91 = sext i8 %t90 to i128
  %t92 = icmp eq i128 %t91, %t89
  br i1 %t92, label %fixed_overflow_ok_13, label %fixed_overflow_fail_12
fixed_overflow_fail_12:
  %t93 = getelementptr inbounds [62 x i8], [62 x i8]* @.str.15, i64 0, i64 0
  call i32 @puts(i8* %t93)
  call void @exit(i32 1)
  unreachable
fixed_overflow_ok_13:
  %t94 = sitofp i8 %t90 to double
  %t95 = fdiv double %t94, 0x4030000000000000
  %t96 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t96, double %t95)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [69 x i8] c"star runtime error: signed 32-bit integer overflow in `+` operation\0A\00"
@.str.1 = private unnamed_addr constant [12 x i8] c"a + b = %f\0A\00"
@.str.2 = private unnamed_addr constant [69 x i8] c"star runtime error: signed 32-bit integer overflow in `-` operation\0A\00"
@.str.3 = private unnamed_addr constant [12 x i8] c"a - b = %f\0A\00"
@.str.4 = private unnamed_addr constant [62 x i8] c"star runtime error: Fixed<Bits,Frac> multiplication overflow\0A\00"
@.str.5 = private unnamed_addr constant [12 x i8] c"a * b = %f\0A\00"
@.str.6 = private unnamed_addr constant [57 x i8] c"star runtime error: `Fixed<Bits,Frac>` division by zero\0A\00"
@.str.7 = private unnamed_addr constant [56 x i8] c"star runtime error: Fixed<Bits,Frac> division overflow\0A\00"
@.str.8 = private unnamed_addr constant [12 x i8] c"a / b = %f\0A\00"
@.str.9 = private unnamed_addr constant [60 x i8] c"star runtime error: Fixed<Bits,Frac> construction overflow\0A\00"
@.str.10 = private unnamed_addr constant [12 x i8] c"whole = %f\0A\00"
@.str.11 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.12 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.13 = private unnamed_addr constant [17 x i8] c"a < whole is %s\0A\00"
@.str.14 = private unnamed_addr constant [15 x i8] c"a as f32 = %f\0A\00"
@.str.15 = private unnamed_addr constant [62 x i8] c"star runtime error: Fixed<Bits,Frac> multiplication overflow\0A\00"
@.str.16 = private unnamed_addr constant [24 x i8] c"small_a * small_b = %f\0A\00"
