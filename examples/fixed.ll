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

%GenRef = type { i32, i64 }

@frame.buf = global [4096 x i8] zeroinitializer
@frame.off = global i64 0

@star.argc = global i32 0
@star.argv = global i8** null

@rng.state = global i32 123456789
@rng.lock = global i8* null

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
  %t2 = alloca i32
  %t5 = alloca i32
  %t54 = alloca i32
  %t72 = alloca float
  %t79 = alloca i8
  %t82 = alloca i8
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = fmul float 0x400C000000000000, 0x40F0000000000000
  %t4 = call i32 @llvm.fptosi.sat.i32.f32(float %t3)
  store i32 %t4, i32* %t2
  %t6 = fmul float 0x4000000000000000, 0x40F0000000000000
  %t7 = call i32 @llvm.fptosi.sat.i32.f32(float %t6)
  store i32 %t7, i32* %t5
  %t8 = load i32, i32* %t2
  %t9 = load i32, i32* %t5
  %t10 = call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %t8, i32 %t9)
  %t11 = extractvalue { i32, i1 } %t10, 0
  %t12 = extractvalue { i32, i1 } %t10, 1
  br i1 %t12, label %int_overflow_fail_0, label %int_overflow_ok_1
int_overflow_fail_0:
  %t13 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t13)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_1:
  %t14 = sitofp i32 %t11 to double
  %t15 = fdiv double %t14, 0x40F0000000000000
  %t16 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t16, double %t15)
  %t17 = load i32, i32* %t2
  %t18 = load i32, i32* %t5
  %t19 = call { i32, i1 } @llvm.ssub.with.overflow.i32(i32 %t17, i32 %t18)
  %t20 = extractvalue { i32, i1 } %t19, 0
  %t21 = extractvalue { i32, i1 } %t19, 1
  br i1 %t21, label %int_overflow_fail_2, label %int_overflow_ok_3
int_overflow_fail_2:
  %t22 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t22)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_3:
  %t23 = sitofp i32 %t20 to double
  %t24 = fdiv double %t23, 0x40F0000000000000
  %t25 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t25, double %t24)
  %t26 = load i32, i32* %t2
  %t27 = load i32, i32* %t5
  %t28 = sext i32 %t26 to i128
  %t29 = sext i32 %t27 to i128
  %t30 = mul i128 %t28, %t29
  %t31 = ashr i128 %t30, 16
  %t32 = trunc i128 %t31 to i32
  %t33 = sext i32 %t32 to i128
  %t34 = icmp eq i128 %t33, %t31
  br i1 %t34, label %fixed_overflow_ok_5, label %fixed_overflow_fail_4
fixed_overflow_fail_4:
  %t35 = getelementptr inbounds [62 x i8], [62 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t35)
  call void @exit(i32 1)
  unreachable
fixed_overflow_ok_5:
  %t36 = sitofp i32 %t32 to double
  %t37 = fdiv double %t36, 0x40F0000000000000
  %t38 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t38, double %t37)
  %t39 = load i32, i32* %t2
  %t40 = load i32, i32* %t5
  %t41 = sext i32 %t39 to i128
  %t42 = sext i32 %t40 to i128
  %t43 = shl i128 %t41, 16
  %t44 = icmp eq i128 %t42, 0
  br i1 %t44, label %fixed_div_zero_fail_6, label %fixed_div_zero_ok_7
fixed_div_zero_fail_6:
  %t45 = getelementptr inbounds [57 x i8], [57 x i8]* @.str.6, i64 0, i64 0
  call i32 @puts(i8* %t45)
  call void @exit(i32 1)
  unreachable
fixed_div_zero_ok_7:
  %t46 = sdiv i128 %t43, %t42
  %t47 = trunc i128 %t46 to i32
  %t48 = sext i32 %t47 to i128
  %t49 = icmp eq i128 %t48, %t46
  br i1 %t49, label %fixed_overflow_ok_9, label %fixed_overflow_fail_8
fixed_overflow_fail_8:
  %t50 = getelementptr inbounds [56 x i8], [56 x i8]* @.str.7, i64 0, i64 0
  call i32 @puts(i8* %t50)
  call void @exit(i32 1)
  unreachable
fixed_overflow_ok_9:
  %t51 = sitofp i32 %t47 to double
  %t52 = fdiv double %t51, 0x40F0000000000000
  %t53 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t53, double %t52)
  %t55 = sext i32 10 to i128
  %t56 = shl i128 %t55, 16
  %t57 = trunc i128 %t56 to i32
  %t58 = sext i32 %t57 to i128
  %t59 = icmp eq i128 %t58, %t56
  br i1 %t59, label %fixed_overflow_ok_11, label %fixed_overflow_fail_10
fixed_overflow_fail_10:
  %t60 = getelementptr inbounds [60 x i8], [60 x i8]* @.str.9, i64 0, i64 0
  call i32 @puts(i8* %t60)
  call void @exit(i32 1)
  unreachable
fixed_overflow_ok_11:
  store i32 %t57, i32* %t54
  %t61 = load i32, i32* %t54
  %t62 = sitofp i32 %t61 to double
  %t63 = fdiv double %t62, 0x40F0000000000000
  %t64 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t64, double %t63)
  %t65 = load i32, i32* %t2
  %t66 = load i32, i32* %t54
  %t67 = icmp slt i32 %t65, %t66
  %t68 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.11, i64 0, i64 0
  %t69 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.12, i64 0, i64 0
  %t70 = select i1 %t67, i8* %t68, i8* %t69
  %t71 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t71, i8* %t70)
  %t73 = load i32, i32* %t2
  %t74 = sitofp i32 %t73 to float
  %t75 = fdiv float %t74, 0x40F0000000000000
  store float %t75, float* %t72
  %t76 = load float, float* %t72
  %t77 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.14, i64 0, i64 0
  %t78 = fpext float %t76 to double
  call i32 (i8*, ...) @printf(i8* %t77, double %t78)
  %t80 = fmul float 0x400C000000000000, 0x4030000000000000
  %t81 = call i8 @llvm.fptosi.sat.i8.f32(float %t80)
  store i8 %t81, i8* %t79
  %t83 = fmul float 0x3FF8000000000000, 0x4030000000000000
  %t84 = call i8 @llvm.fptosi.sat.i8.f32(float %t83)
  store i8 %t84, i8* %t82
  %t85 = load i8, i8* %t79
  %t86 = load i8, i8* %t82
  %t87 = sext i8 %t85 to i128
  %t88 = sext i8 %t86 to i128
  %t89 = mul i128 %t87, %t88
  %t90 = ashr i128 %t89, 4
  %t91 = trunc i128 %t90 to i8
  %t92 = sext i8 %t91 to i128
  %t93 = icmp eq i128 %t92, %t90
  br i1 %t93, label %fixed_overflow_ok_13, label %fixed_overflow_fail_12
fixed_overflow_fail_12:
  %t94 = getelementptr inbounds [62 x i8], [62 x i8]* @.str.15, i64 0, i64 0
  call i32 @puts(i8* %t94)
  call void @exit(i32 1)
  unreachable
fixed_overflow_ok_13:
  %t95 = sitofp i8 %t91 to double
  %t96 = fdiv double %t95, 0x4030000000000000
  %t97 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t97, double %t96)
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
