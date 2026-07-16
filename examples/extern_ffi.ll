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

declare i32 @toupper(i32)
declare i32 @atoi(i8*)
declare i8* @strstr(i8*, i8*)
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca i8*
  %t8 = alloca i8*
  %t18 = alloca i8*
  %t31 = alloca i8*
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i32 @toupper(i32 97)
  %t1 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1, i32 %t0)
  %t3 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.1, i64 0, i32 2, i64 0
  store i8* %t3, i8** %t2
  %t4 = load i8*, i8** %t2
  %t5 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t5)
  call void @star_rc_release(i8* %t4)
  %t6 = call i32 @atoi(i8* %t4)
  %t7 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t7, i32 %t6)
  %t9 = getelementptr inbounds { i64, i8*, [12 x i8] }, { i64, i8*, [12 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t10 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t11 = call i8* @strstr(i8* %t9, i8* %t10)
  store i8* %t11, i8** %t8
  %t12 = load i8*, i8** %t8
  %t13 = icmp eq i8* %t12, null
  %t14 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.5, i64 0, i64 0
  %t15 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.6, i64 0, i64 0
  %t16 = select i1 %t13, i8* %t14, i8* %t15
  %t17 = getelementptr inbounds [32 x i8], [32 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t17, i8* %t16)
  %t19 = getelementptr inbounds { i64, i8*, [12 x i8] }, { i64, i8*, [12 x i8] }* @.str.8, i64 0, i32 2, i64 0
  %t20 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.9, i64 0, i32 2, i64 0
  %t21 = call i8* @strstr(i8* %t19, i8* %t20)
  store i8* %t21, i8** %t18
  %t22 = load i8*, i8** %t18
  %t23 = icmp eq i8* %t22, null
  %t24 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.10, i64 0, i64 0
  %t25 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.11, i64 0, i64 0
  %t26 = select i1 %t23, i8* %t24, i8* %t25
  %t27 = getelementptr inbounds [30 x i8], [30 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t27, i8* %t26)
  %t28 = load i8*, i8** %t18
  %t29 = icmp eq i8* %t28, null
  %t30 = xor i1 true, %t29
  br i1 %t30, label %if_then_0, label %if_else_1
if_then_0:
  %t32 = load i8*, i8** %t18
  %t33 = call i32 @strlen(i8* %t32)
  %t34 = add i32 %t33, 1
  %t35 = sext i32 %t34 to i64
  %t36 = call i8* @star_rc_alloc(i64 %t35, i8* null)
  call i8* @strcpy(i8* %t36, i8* %t32)
  store i8* %t36, i8** %t31
  %t37 = load i8*, i8** %t31
  %t38 = load i8*, i8** %t31
  call void @star_rc_retain(i8* %t38)
  call void @star_rc_release(i8* %t37)
  %t39 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t39, i8* %t37)
  %t40 = load i8*, i8** %t31
  call void @star_rc_release(i8* %t40)
  br label %if_end_2
if_else_1:
  br label %if_end_2
if_end_2:
  %t41 = icmp eq i8* null, null
  %t42 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.14, i64 0, i64 0
  %t43 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.15, i64 0, i64 0
  %t44 = select i1 %t41, i8* %t42, i8* %t43
  %t45 = getelementptr inbounds [30 x i8], [30 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t45, i8* %t44)
  %t46 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t46)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [17 x i8] c"toupper(97): %d\0A\00"
@.str.1 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"42\00" }
@.str.2 = private unnamed_addr constant [13 x i8] c"atoi(s): %d\0A\00"
@.str.3 = private unnamed_addr constant { i64, i8*, [12 x i8] } { i64 -1, i8* null, [12 x i8] c"hello world\00" }
@.str.4 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"xyz\00" }
@.str.5 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.6 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.7 = private unnamed_addr constant [32 x i8] c"is_null(missing substring): %s\0A\00"
@.str.8 = private unnamed_addr constant { i64, i8*, [12 x i8] } { i64 -1, i8* null, [12 x i8] c"hello world\00" }
@.str.9 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"world\00" }
@.str.10 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.11 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.12 = private unnamed_addr constant [30 x i8] c"is_null(found substring): %s\0A\00"
@.str.13 = private unnamed_addr constant [21 x i8] c"found substring: %s\0A\00"
@.str.14 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.15 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.16 = private unnamed_addr constant [30 x i8] c"null_ptr() == null_ptr(): %s\0A\00"
