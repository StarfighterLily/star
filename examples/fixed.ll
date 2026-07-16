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
  %t0 = alloca i32
  %t3 = alloca i32
  %t52 = alloca i32
  %t70 = alloca float
  %t77 = alloca i8
  %t80 = alloca i8
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t1 = fmul float 0x400C000000000000, 0x40F0000000000000
  %t2 = call i32 @llvm.fptosi.sat.i32.f32(float %t1)
  store i32 %t2, i32* %t0
  %t4 = fmul float 0x4000000000000000, 0x40F0000000000000
  %t5 = call i32 @llvm.fptosi.sat.i32.f32(float %t4)
  store i32 %t5, i32* %t3
  %t6 = load i32, i32* %t0
  %t7 = load i32, i32* %t3
  %t8 = call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %t6, i32 %t7)
  %t9 = extractvalue { i32, i1 } %t8, 0
  %t10 = extractvalue { i32, i1 } %t8, 1
  br i1 %t10, label %int_overflow_fail_0, label %int_overflow_ok_1
int_overflow_fail_0:
  %t11 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t11)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_1:
  %t12 = sitofp i32 %t9 to double
  %t13 = fdiv double %t12, 0x40F0000000000000
  %t14 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t14, double %t13)
  %t15 = load i32, i32* %t0
  %t16 = load i32, i32* %t3
  %t17 = call { i32, i1 } @llvm.ssub.with.overflow.i32(i32 %t15, i32 %t16)
  %t18 = extractvalue { i32, i1 } %t17, 0
  %t19 = extractvalue { i32, i1 } %t17, 1
  br i1 %t19, label %int_overflow_fail_2, label %int_overflow_ok_3
int_overflow_fail_2:
  %t20 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t20)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_3:
  %t21 = sitofp i32 %t18 to double
  %t22 = fdiv double %t21, 0x40F0000000000000
  %t23 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t23, double %t22)
  %t24 = load i32, i32* %t0
  %t25 = load i32, i32* %t3
  %t26 = sext i32 %t24 to i128
  %t27 = sext i32 %t25 to i128
  %t28 = mul i128 %t26, %t27
  %t29 = ashr i128 %t28, 16
  %t30 = trunc i128 %t29 to i32
  %t31 = sext i32 %t30 to i128
  %t32 = icmp eq i128 %t31, %t29
  br i1 %t32, label %fixed_overflow_ok_5, label %fixed_overflow_fail_4
fixed_overflow_fail_4:
  %t33 = getelementptr inbounds [62 x i8], [62 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t33)
  call void @exit(i32 1)
  unreachable
fixed_overflow_ok_5:
  %t34 = sitofp i32 %t30 to double
  %t35 = fdiv double %t34, 0x40F0000000000000
  %t36 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t36, double %t35)
  %t37 = load i32, i32* %t0
  %t38 = load i32, i32* %t3
  %t39 = sext i32 %t37 to i128
  %t40 = sext i32 %t38 to i128
  %t41 = shl i128 %t39, 16
  %t42 = icmp eq i128 %t40, 0
  br i1 %t42, label %fixed_div_zero_fail_6, label %fixed_div_zero_ok_7
fixed_div_zero_fail_6:
  %t43 = getelementptr inbounds [57 x i8], [57 x i8]* @.str.6, i64 0, i64 0
  call i32 @puts(i8* %t43)
  call void @exit(i32 1)
  unreachable
fixed_div_zero_ok_7:
  %t44 = sdiv i128 %t41, %t40
  %t45 = trunc i128 %t44 to i32
  %t46 = sext i32 %t45 to i128
  %t47 = icmp eq i128 %t46, %t44
  br i1 %t47, label %fixed_overflow_ok_9, label %fixed_overflow_fail_8
fixed_overflow_fail_8:
  %t48 = getelementptr inbounds [56 x i8], [56 x i8]* @.str.7, i64 0, i64 0
  call i32 @puts(i8* %t48)
  call void @exit(i32 1)
  unreachable
fixed_overflow_ok_9:
  %t49 = sitofp i32 %t45 to double
  %t50 = fdiv double %t49, 0x40F0000000000000
  %t51 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t51, double %t50)
  %t53 = sext i32 10 to i128
  %t54 = shl i128 %t53, 16
  %t55 = trunc i128 %t54 to i32
  %t56 = sext i32 %t55 to i128
  %t57 = icmp eq i128 %t56, %t54
  br i1 %t57, label %fixed_overflow_ok_11, label %fixed_overflow_fail_10
fixed_overflow_fail_10:
  %t58 = getelementptr inbounds [60 x i8], [60 x i8]* @.str.9, i64 0, i64 0
  call i32 @puts(i8* %t58)
  call void @exit(i32 1)
  unreachable
fixed_overflow_ok_11:
  store i32 %t55, i32* %t52
  %t59 = load i32, i32* %t52
  %t60 = sitofp i32 %t59 to double
  %t61 = fdiv double %t60, 0x40F0000000000000
  %t62 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t62, double %t61)
  %t63 = load i32, i32* %t0
  %t64 = load i32, i32* %t52
  %t65 = icmp slt i32 %t63, %t64
  %t66 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.11, i64 0, i64 0
  %t67 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.12, i64 0, i64 0
  %t68 = select i1 %t65, i8* %t66, i8* %t67
  %t69 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t69, i8* %t68)
  %t71 = load i32, i32* %t0
  %t72 = sitofp i32 %t71 to float
  %t73 = fdiv float %t72, 0x40F0000000000000
  store float %t73, float* %t70
  %t74 = load float, float* %t70
  %t75 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.14, i64 0, i64 0
  %t76 = fpext float %t74 to double
  call i32 (i8*, ...) @printf(i8* %t75, double %t76)
  %t78 = fmul float 0x400C000000000000, 0x4030000000000000
  %t79 = call i8 @llvm.fptosi.sat.i8.f32(float %t78)
  store i8 %t79, i8* %t77
  %t81 = fmul float 0x3FF8000000000000, 0x4030000000000000
  %t82 = call i8 @llvm.fptosi.sat.i8.f32(float %t81)
  store i8 %t82, i8* %t80
  %t83 = load i8, i8* %t77
  %t84 = load i8, i8* %t80
  %t85 = sext i8 %t83 to i128
  %t86 = sext i8 %t84 to i128
  %t87 = mul i128 %t85, %t86
  %t88 = ashr i128 %t87, 4
  %t89 = trunc i128 %t88 to i8
  %t90 = sext i8 %t89 to i128
  %t91 = icmp eq i128 %t90, %t88
  br i1 %t91, label %fixed_overflow_ok_13, label %fixed_overflow_fail_12
fixed_overflow_fail_12:
  %t92 = getelementptr inbounds [62 x i8], [62 x i8]* @.str.15, i64 0, i64 0
  call i32 @puts(i8* %t92)
  call void @exit(i32 1)
  unreachable
fixed_overflow_ok_13:
  %t93 = sitofp i8 %t89 to double
  %t94 = fdiv double %t93, 0x4030000000000000
  %t95 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t95, double %t94)
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
