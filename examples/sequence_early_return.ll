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

%Countdown = type { i32, i32, i32 }
define i1 @Countdown__resume(%Countdown* %self) {
entry:
  %t0 = alloca %Countdown*
  store %Countdown* %self, %Countdown** %t0
  %t1 = load %Countdown*, %Countdown** %t0
  %t2 = getelementptr inbounds %Countdown, %Countdown* %t1, i32 0, i32 2
  %t3 = load i32, i32* %t2
  %t4 = icmp eq i32 %t3, 0
  br i1 %t4, label %if_then_0, label %if_else_1
if_then_0:
  %t5 = load %Countdown*, %Countdown** %t0
  %t6 = getelementptr inbounds %Countdown, %Countdown* %t5, i32 0, i32 0
  %t7 = load i32, i32* %t6
  %t8 = load %Countdown*, %Countdown** %t0
  %t9 = getelementptr inbounds %Countdown, %Countdown* %t8, i32 0, i32 1
  store i32 %t7, i32* %t9
  %t10 = load %Countdown*, %Countdown** %t0
  %t11 = getelementptr inbounds %Countdown, %Countdown* %t10, i32 0, i32 1
  %t12 = load i32, i32* %t11
  %t13 = icmp slt i32 %t12, 0
  br i1 %t13, label %if_then_3, label %if_else_4
if_then_3:
  ret i1 false
if_else_4:
  br label %if_end_5
if_end_5:
  %t14 = load %Countdown*, %Countdown** %t0
  %t15 = getelementptr inbounds %Countdown, %Countdown* %t14, i32 0, i32 2
  store i32 1, i32* %t15
  ret i1 true
if_else_1:
  %t16 = load %Countdown*, %Countdown** %t0
  %t17 = getelementptr inbounds %Countdown, %Countdown* %t16, i32 0, i32 2
  %t18 = load i32, i32* %t17
  %t19 = icmp eq i32 %t18, 1
  br i1 %t19, label %if_then_6, label %if_else_7
if_then_6:
  %t20 = load %Countdown*, %Countdown** %t0
  %t21 = getelementptr inbounds %Countdown, %Countdown* %t20, i32 0, i32 1
  %t22 = load i32, i32* %t21
  %t23 = sub i32 %t22, 1
  %t24 = load %Countdown*, %Countdown** %t0
  %t25 = getelementptr inbounds %Countdown, %Countdown* %t24, i32 0, i32 1
  store i32 %t23, i32* %t25
  %t26 = load %Countdown*, %Countdown** %t0
  %t27 = getelementptr inbounds %Countdown, %Countdown* %t26, i32 0, i32 2
  store i32 2, i32* %t27
  ret i1 true
if_else_7:
  %t28 = load %Countdown*, %Countdown** %t0
  %t29 = getelementptr inbounds %Countdown, %Countdown* %t28, i32 0, i32 2
  %t30 = load i32, i32* %t29
  %t31 = icmp eq i32 %t30, 2
  br i1 %t31, label %if_then_9, label %if_else_10
if_then_9:
  %t32 = load %Countdown*, %Countdown** %t0
  %t33 = getelementptr inbounds %Countdown, %Countdown* %t32, i32 0, i32 1
  %t34 = load i32, i32* %t33
  %t35 = sub i32 %t34, 1
  %t36 = load %Countdown*, %Countdown** %t0
  %t37 = getelementptr inbounds %Countdown, %Countdown* %t36, i32 0, i32 1
  store i32 %t35, i32* %t37
  %t38 = load %Countdown*, %Countdown** %t0
  %t39 = getelementptr inbounds %Countdown, %Countdown* %t38, i32 0, i32 2
  store i32 3, i32* %t39
  ret i1 false
if_else_10:
  ret i1 false
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t0 = alloca %Countdown
  %t1 = alloca %Countdown
  %t6 = alloca i1
  %t7 = alloca i32
  %t14 = alloca %Countdown
  %t15 = alloca %Countdown
  %t21 = alloca i1
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t2 = getelementptr inbounds %Countdown, %Countdown* %t1, i32 0, i32 0
  store i32 1, i32* %t2
  %t3 = getelementptr inbounds %Countdown, %Countdown* %t1, i32 0, i32 1
  store i32 0, i32* %t3
  %t4 = getelementptr inbounds %Countdown, %Countdown* %t1, i32 0, i32 2
  store i32 0, i32* %t4
  %t5 = load %Countdown, %Countdown* %t1
  store %Countdown %t5, %Countdown* %t0
  store i1 true, i1* %t6
  store i32 0, i32* %t7
  br label %while_cond_12
while_cond_12:
  %t8 = load i1, i1* %t6
  br i1 %t8, label %while_body_13, label %while_else_14
while_body_13:
  %t9 = call i1 @Countdown__resume(%Countdown* %t0)
  store i1 %t9, i1* %t6
  %t10 = load i32, i32* %t7
  %t11 = add i32 %t10, 1
  store i32 %t11, i32* %t7
  br label %while_cond_12
while_else_14:
  br label %while_end_15
while_end_15:
  %t12 = load i32, i32* %t7
  %t13 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t13, i32 %t12)
  %t16 = sub i32 0, 1
  %t17 = getelementptr inbounds %Countdown, %Countdown* %t15, i32 0, i32 0
  store i32 %t16, i32* %t17
  %t18 = getelementptr inbounds %Countdown, %Countdown* %t15, i32 0, i32 1
  store i32 0, i32* %t18
  %t19 = getelementptr inbounds %Countdown, %Countdown* %t15, i32 0, i32 2
  store i32 0, i32* %t19
  %t20 = load %Countdown, %Countdown* %t15
  store %Countdown %t20, %Countdown* %t14
  %t22 = call i1 @Countdown__resume(%Countdown* %t14)
  store i1 %t22, i1* %t21
  %t23 = load i1, i1* %t21
  %t24 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.1, i64 0, i64 0
  %t25 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.2, i64 0, i64 0
  %t26 = select i1 %t23, i8* %t24, i8* %t25
  %t27 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t27, i8* %t26)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [11 x i8] c"ticks: %d\0A\00"
@.str.1 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.2 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.3 = private unnamed_addr constant [31 x i8] c"early return reports done: %s\0A\00"
