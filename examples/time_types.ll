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
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca i32
  %t17 = alloca i64
  %t26 = alloca i64
  %t28 = alloca i64
  %t30 = alloca i32
  %t43 = alloca i64
  %t59 = alloca i64
  %t61 = alloca i64
  %t63 = alloca i64
  %t72 = alloca i64
  %t86 = alloca i64
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t1 = sext i32 0 to i64
  store i64 %t1, i64* %t0
  %t3 = load i64, i64* %t0
  store i64 %t3, i64* %t2
  store i32 0, i32* %t4
  br label %for_cond_0
for_cond_0:
  %t5 = load i32, i32* %t4
  %t6 = icmp slt i32 %t5, 60
  br i1 %t6, label %for_body_1, label %for_end_3
for_body_1:
  %t7 = load i64, i64* %t2
  %t8 = sext i32 1 to i64
  %t9 = call { i64, i1 } @llvm.sadd.with.overflow.i64(i64 %t7, i64 %t8)
  %t10 = extractvalue { i64, i1 } %t9, 0
  %t11 = extractvalue { i64, i1 } %t9, 1
  br i1 %t11, label %int_overflow_fail_4, label %int_overflow_ok_5
int_overflow_fail_4:
  %t12 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t12)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_5:
  store i64 %t10, i64* %t2
  br label %for_step_2
for_step_2:
  %t13 = load i32, i32* %t4
  %t14 = add i32 %t13, 1
  store i32 %t14, i32* %t4
  br label %for_cond_0
for_end_3:
  %t15 = load i64, i64* %t2
  %t16 = getelementptr inbounds [28 x i8], [28 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t16, i64 %t15)
  %t18 = load i64, i64* %t2
  %t19 = load i64, i64* %t0
  %t20 = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %t18, i64 %t19)
  %t21 = extractvalue { i64, i1 } %t20, 0
  %t22 = extractvalue { i64, i1 } %t20, 1
  br i1 %t22, label %int_overflow_fail_6, label %int_overflow_ok_7
int_overflow_fail_6:
  %t23 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t23)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_7:
  store i64 %t21, i64* %t17
  %t24 = load i64, i64* %t17
  %t25 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t25, i64 %t24)
  %t27 = sext i32 16666667 to i64
  store i64 %t27, i64* %t26
  %t29 = sext i32 0 to i64
  store i64 %t29, i64* %t28
  store i32 0, i32* %t30
  br label %for_cond_8
for_cond_8:
  %t31 = load i32, i32* %t30
  %t32 = icmp slt i32 %t31, 3
  br i1 %t32, label %for_body_9, label %for_end_11
for_body_9:
  %t33 = load i64, i64* %t28
  %t34 = load i64, i64* %t26
  %t35 = call { i64, i1 } @llvm.sadd.with.overflow.i64(i64 %t33, i64 %t34)
  %t36 = extractvalue { i64, i1 } %t35, 0
  %t37 = extractvalue { i64, i1 } %t35, 1
  br i1 %t37, label %int_overflow_fail_12, label %int_overflow_ok_13
int_overflow_fail_12:
  %t38 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t38)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_13:
  store i64 %t36, i64* %t28
  br label %for_step_10
for_step_10:
  %t39 = load i32, i32* %t30
  %t40 = add i32 %t39, 1
  store i32 %t40, i32* %t30
  br label %for_cond_8
for_end_11:
  %t41 = load i64, i64* %t28
  %t42 = getelementptr inbounds [41 x i8], [41 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t42, i64 %t41)
  %t44 = load i64, i64* %t28
  %t45 = load i64, i64* %t26
  %t46 = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %t44, i64 %t45)
  %t47 = extractvalue { i64, i1 } %t46, 0
  %t48 = extractvalue { i64, i1 } %t46, 1
  br i1 %t48, label %int_overflow_fail_14, label %int_overflow_ok_15
int_overflow_fail_14:
  %t49 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.6, i64 0, i64 0
  call i32 @puts(i8* %t49)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_15:
  store i64 %t47, i64* %t43
  %t50 = load i64, i64* %t43
  %t51 = getelementptr inbounds [47 x i8], [47 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t51, i64 %t50)
  %t52 = load i64, i64* %t26
  %t53 = load i64, i64* %t28
  %t54 = icmp slt i64 %t52, %t53
  %t55 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.8, i64 0, i64 0
  %t56 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.9, i64 0, i64 0
  %t57 = select i1 %t54, i8* %t55, i8* %t56
  %t58 = getelementptr inbounds [28 x i8], [28 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t58, i8* %t57)
  %t60 = sext i32 1000 to i64
  store i64 %t60, i64* %t59
  %t62 = sext i32 2500 to i64
  store i64 %t62, i64* %t61
  %t64 = load i64, i64* %t61
  %t65 = load i64, i64* %t59
  %t66 = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %t64, i64 %t65)
  %t67 = extractvalue { i64, i1 } %t66, 0
  %t68 = extractvalue { i64, i1 } %t66, 1
  br i1 %t68, label %int_overflow_fail_16, label %int_overflow_ok_17
int_overflow_fail_16:
  %t69 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.11, i64 0, i64 0
  call i32 @puts(i8* %t69)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_17:
  store i64 %t67, i64* %t63
  %t70 = load i64, i64* %t63
  %t71 = getelementptr inbounds [32 x i8], [32 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t71, i64 %t70)
  %t73 = load i64, i64* %t59
  %t74 = load i64, i64* %t63
  %t75 = call { i64, i1 } @llvm.sadd.with.overflow.i64(i64 %t73, i64 %t74)
  %t76 = extractvalue { i64, i1 } %t75, 0
  %t77 = extractvalue { i64, i1 } %t75, 1
  br i1 %t77, label %int_overflow_fail_18, label %int_overflow_ok_19
int_overflow_fail_18:
  %t78 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.13, i64 0, i64 0
  call i32 @puts(i8* %t78)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_19:
  store i64 %t76, i64* %t72
  %t79 = load i64, i64* %t72
  %t80 = load i64, i64* %t61
  %t81 = icmp eq i64 %t79, %t80
  %t82 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.14, i64 0, i64 0
  %t83 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.15, i64 0, i64 0
  %t84 = select i1 %t81, i8* %t82, i8* %t83
  %t85 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t85, i8* %t84)
  %t87 = load i64, i64* %t61
  %t88 = load i64, i64* %t63
  %t89 = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %t87, i64 %t88)
  %t90 = extractvalue { i64, i1 } %t89, 0
  %t91 = extractvalue { i64, i1 } %t89, 1
  br i1 %t91, label %int_overflow_fail_20, label %int_overflow_ok_21
int_overflow_fail_20:
  %t92 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.17, i64 0, i64 0
  call i32 @puts(i8* %t92)
  call void @exit(i32 1)
  unreachable
int_overflow_ok_21:
  store i64 %t90, i64* %t86
  %t93 = load i64, i64* %t86
  %t94 = load i64, i64* %t59
  %t95 = icmp eq i64 %t93, %t94
  %t96 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.18, i64 0, i64 0
  %t97 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.19, i64 0, i64 0
  %t98 = select i1 %t95, i8* %t96, i8* %t97
  %t99 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.20, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t99, i8* %t98)
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
