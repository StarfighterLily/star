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
  %t1 = alloca i64
  %t3 = alloca i64
  %t5 = alloca i32
  %t18 = alloca i64
  %t27 = alloca i64
  %t29 = alloca i64
  %t31 = alloca i32
  %t44 = alloca i64
  %t60 = alloca i64
  %t62 = alloca i64
  %t64 = alloca i64
  %t73 = alloca i64
  %t87 = alloca i64
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t2 = sext i32 0 to i64
  store i64 %t2, i64* %t1
  %t4 = load i64, i64* %t1
  store i64 %t4, i64* %t3
  store i32 0, i32* %t5
  br label %for_cond_0
for_cond_0:
  %t6 = load i32, i32* %t5
  %t7 = icmp slt i32 %t6, 60
  br i1 %t7, label %for_body_1, label %for_end_3
for_body_1:
  %t8 = load i64, i64* %t3
  %t9 = sext i32 1 to i64
  %t10 = call { i64, i1 } @llvm.sadd.with.overflow.i64(i64 %t8, i64 %t9)
  %t11 = extractvalue { i64, i1 } %t10, 0
  %t12 = extractvalue { i64, i1 } %t10, 1
  br i1 %t12, label %int_overflow_fail_4, label %int_overflow_ok_5
int_overflow_fail_4:
  %t13 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t13)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_5:
  store i64 %t11, i64* %t3
  br label %for_step_2
for_step_2:
  %t14 = load i32, i32* %t5
  %t15 = add i32 %t14, 1
  store i32 %t15, i32* %t5
  br label %for_cond_0
for_end_3:
  %t16 = load i64, i64* %t3
  %t17 = getelementptr inbounds [28 x i8], [28 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t17, i64 %t16)
  %t19 = load i64, i64* %t3
  %t20 = load i64, i64* %t1
  %t21 = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %t19, i64 %t20)
  %t22 = extractvalue { i64, i1 } %t21, 0
  %t23 = extractvalue { i64, i1 } %t21, 1
  br i1 %t23, label %int_overflow_fail_6, label %int_overflow_ok_7
int_overflow_fail_6:
  %t24 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t24)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_7:
  store i64 %t22, i64* %t18
  %t25 = load i64, i64* %t18
  %t26 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t26, i64 %t25)
  %t28 = sext i32 16666667 to i64
  store i64 %t28, i64* %t27
  %t30 = sext i32 0 to i64
  store i64 %t30, i64* %t29
  store i32 0, i32* %t31
  br label %for_cond_8
for_cond_8:
  %t32 = load i32, i32* %t31
  %t33 = icmp slt i32 %t32, 3
  br i1 %t33, label %for_body_9, label %for_end_11
for_body_9:
  %t34 = load i64, i64* %t29
  %t35 = load i64, i64* %t27
  %t36 = call { i64, i1 } @llvm.sadd.with.overflow.i64(i64 %t34, i64 %t35)
  %t37 = extractvalue { i64, i1 } %t36, 0
  %t38 = extractvalue { i64, i1 } %t36, 1
  br i1 %t38, label %int_overflow_fail_12, label %int_overflow_ok_13
int_overflow_fail_12:
  %t39 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t39)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_13:
  store i64 %t37, i64* %t29
  br label %for_step_10
for_step_10:
  %t40 = load i32, i32* %t31
  %t41 = add i32 %t40, 1
  store i32 %t41, i32* %t31
  br label %for_cond_8
for_end_11:
  %t42 = load i64, i64* %t29
  %t43 = getelementptr inbounds [41 x i8], [41 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t43, i64 %t42)
  %t45 = load i64, i64* %t29
  %t46 = load i64, i64* %t27
  %t47 = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %t45, i64 %t46)
  %t48 = extractvalue { i64, i1 } %t47, 0
  %t49 = extractvalue { i64, i1 } %t47, 1
  br i1 %t49, label %int_overflow_fail_14, label %int_overflow_ok_15
int_overflow_fail_14:
  %t50 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.6, i64 0, i64 0
  call i32 @puts(i8* %t50)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_15:
  store i64 %t48, i64* %t44
  %t51 = load i64, i64* %t44
  %t52 = getelementptr inbounds [47 x i8], [47 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t52, i64 %t51)
  %t53 = load i64, i64* %t27
  %t54 = load i64, i64* %t29
  %t55 = icmp slt i64 %t53, %t54
  %t56 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.8, i64 0, i64 0
  %t57 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.9, i64 0, i64 0
  %t58 = select i1 %t55, i8* %t56, i8* %t57
  %t59 = getelementptr inbounds [28 x i8], [28 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t59, i8* %t58)
  %t61 = sext i32 1000 to i64
  store i64 %t61, i64* %t60
  %t63 = sext i32 2500 to i64
  store i64 %t63, i64* %t62
  %t65 = load i64, i64* %t62
  %t66 = load i64, i64* %t60
  %t67 = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %t65, i64 %t66)
  %t68 = extractvalue { i64, i1 } %t67, 0
  %t69 = extractvalue { i64, i1 } %t67, 1
  br i1 %t69, label %int_overflow_fail_16, label %int_overflow_ok_17
int_overflow_fail_16:
  %t70 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.11, i64 0, i64 0
  call i32 @puts(i8* %t70)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_17:
  store i64 %t68, i64* %t64
  %t71 = load i64, i64* %t64
  %t72 = getelementptr inbounds [32 x i8], [32 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t72, i64 %t71)
  %t74 = load i64, i64* %t60
  %t75 = load i64, i64* %t64
  %t76 = call { i64, i1 } @llvm.sadd.with.overflow.i64(i64 %t74, i64 %t75)
  %t77 = extractvalue { i64, i1 } %t76, 0
  %t78 = extractvalue { i64, i1 } %t76, 1
  br i1 %t78, label %int_overflow_fail_18, label %int_overflow_ok_19
int_overflow_fail_18:
  %t79 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.13, i64 0, i64 0
  call i32 @puts(i8* %t79)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_19:
  store i64 %t77, i64* %t73
  %t80 = load i64, i64* %t73
  %t81 = load i64, i64* %t62
  %t82 = icmp eq i64 %t80, %t81
  %t83 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.14, i64 0, i64 0
  %t84 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.15, i64 0, i64 0
  %t85 = select i1 %t82, i8* %t83, i8* %t84
  %t86 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t86, i8* %t85)
  %t88 = load i64, i64* %t62
  %t89 = load i64, i64* %t64
  %t90 = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %t88, i64 %t89)
  %t91 = extractvalue { i64, i1 } %t90, 0
  %t92 = extractvalue { i64, i1 } %t90, 1
  br i1 %t92, label %int_overflow_fail_20, label %int_overflow_ok_21
int_overflow_fail_20:
  %t93 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.17, i64 0, i64 0
  call i32 @puts(i8* %t93)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_21:
  store i64 %t91, i64* %t87
  %t94 = load i64, i64* %t87
  %t95 = load i64, i64* %t60
  %t96 = icmp eq i64 %t94, %t95
  %t97 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.18, i64 0, i64 0
  %t98 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.19, i64 0, i64 0
  %t99 = select i1 %t96, i8* %t97, i8* %t98
  %t100 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.20, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t100, i8* %t99)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [69 x i8] c"star runtime error: signed 64-bit integer overflow in `+` operation\0A\00"
@.str.1 = private unnamed_addr constant [28 x i8] c"tick after 60 steps = %lld\0A\00"
@.str.2 = private unnamed_addr constant [69 x i8] c"star runtime error: signed 64-bit integer overflow in `-` operation\0A\00"
@.str.3 = private unnamed_addr constant [22 x i8] c"elapsed ticks = %lld\0A\00"
@.str.4 = private unnamed_addr constant [69 x i8] c"star runtime error: signed 64-bit integer overflow in `+` operation\0A\00"
@.str.5 = private unnamed_addr constant [41 x i8] c"total duration after 3 frames = %lld ns\0A\00"
@.str.6 = private unnamed_addr constant [69 x i8] c"star runtime error: signed 64-bit integer overflow in `-` operation\0A\00"
@.str.7 = private unnamed_addr constant [47 x i8] c"remaining after refunding one frame = %lld ns\0A\00"
@.str.8 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.9 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.10 = private unnamed_addr constant [28 x i8] c"frame_budget < total is %s\0A\00"
@.str.11 = private unnamed_addr constant [69 x i8] c"star runtime error: signed 64-bit integer overflow in `-` operation\0A\00"
@.str.12 = private unnamed_addr constant [32 x i8] c"gap between instants = %lld ns\0A\00"
@.str.13 = private unnamed_addr constant [69 x i8] c"star runtime error: signed 64-bit integer overflow in `+` operation\0A\00"
@.str.14 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.15 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.16 = private unnamed_addr constant [31 x i8] c"t0 shifted by gap == t1 is %s\0A\00"
@.str.17 = private unnamed_addr constant [69 x i8] c"star runtime error: signed 64-bit integer overflow in `-` operation\0A\00"
@.str.18 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.19 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.20 = private unnamed_addr constant [31 x i8] c"t1 rewound by gap == t0 is %s\0A\00"
