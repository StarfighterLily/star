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

declare i32 @toupper(i32)
declare i32 @atoi(i8*)
declare i8* @strstr(i8*, i8*)
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t4 = alloca i8*
  %t10 = alloca i8*
  %t20 = alloca i8*
  %t33 = alloca i8*
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t2 = call i32 @toupper(i32 97)
  %t3 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t3, i32 %t2)
  %t5 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.1, i64 0, i32 2, i64 0
  store i8* %t5, i8** %t4
  %t6 = load i8*, i8** %t4
  %t7 = load i8*, i8** %t4
  call void @star_rc_retain(i8* %t7)
  %t8 = call i32 @atoi(i8* %t6)
  call void @star_rc_release(i8* %t6)
  %t9 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t9, i32 %t8)
  %t11 = getelementptr inbounds { i64, i8*, [12 x i8] }, { i64, i8*, [12 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t12 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t13 = call i8* @strstr(i8* %t11, i8* %t12)
  call void @star_rc_release(i8* %t11)
  call void @star_rc_release(i8* %t12)
  store i8* %t13, i8** %t10
  %t14 = load i8*, i8** %t10
  %t15 = icmp eq i8* %t14, null
  %t16 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.5, i64 0, i64 0
  %t17 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.6, i64 0, i64 0
  %t18 = select i1 %t15, i8* %t16, i8* %t17
  %t19 = getelementptr inbounds [32 x i8], [32 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t19, i8* %t18)
  %t21 = getelementptr inbounds { i64, i8*, [12 x i8] }, { i64, i8*, [12 x i8] }* @.str.8, i64 0, i32 2, i64 0
  %t22 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.9, i64 0, i32 2, i64 0
  %t23 = call i8* @strstr(i8* %t21, i8* %t22)
  call void @star_rc_release(i8* %t21)
  call void @star_rc_release(i8* %t22)
  store i8* %t23, i8** %t20
  %t24 = load i8*, i8** %t20
  %t25 = icmp eq i8* %t24, null
  %t26 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.10, i64 0, i64 0
  %t27 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.11, i64 0, i64 0
  %t28 = select i1 %t25, i8* %t26, i8* %t27
  %t29 = getelementptr inbounds [30 x i8], [30 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t29, i8* %t28)
  %t30 = load i8*, i8** %t20
  %t31 = icmp eq i8* %t30, null
  %t32 = xor i1 true, %t31
  br i1 %t32, label %if_then_0, label %if_else_1
if_then_0:
  %t34 = load i8*, i8** %t20
  %t35 = icmp eq i8* %t34, null
  br i1 %t35, label %ptr_to_str_null_3, label %ptr_to_str_ok_4
ptr_to_str_null_3:
  %t36 = getelementptr inbounds [59 x i8], [59 x i8]* @.str.13, i64 0, i64 0
  call i32 @puts(i8* %t36)
  call void @exit(i32 1)
  unreachable
ptr_to_str_ok_4:
  %t37 = call i32 @strlen(i8* %t34)
  %t38 = add i32 %t37, 1
  %t39 = sext i32 %t38 to i64
  %t40 = call i8* @star_rc_alloc(i64 %t39, i8* null)
  call i8* @strcpy(i8* %t40, i8* %t34)
  store i8* %t40, i8** %t33
  %t41 = load i8*, i8** %t33
  %t42 = load i8*, i8** %t33
  call void @star_rc_retain(i8* %t42)
  call void @star_rc_release(i8* %t41)
  %t43 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t43, i8* %t41)
  %t44 = load i8*, i8** %t33
  call void @star_rc_release(i8* %t44)
  br label %if_end_2
if_else_1:
  br label %if_end_2
if_end_2:
  %t45 = icmp eq i8* null, null
  %t46 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.15, i64 0, i64 0
  %t47 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.16, i64 0, i64 0
  %t48 = select i1 %t45, i8* %t46, i8* %t47
  %t49 = getelementptr inbounds [30 x i8], [30 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t49, i8* %t48)
  %t50 = load i8*, i8** %t4
  call void @star_rc_release(i8* %t50)
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
@.str.13 = private unnamed_addr constant [59 x i8] c"star runtime error: ptr_to_str(..) called with a null ptr\0A\00"
@.str.14 = private unnamed_addr constant [21 x i8] c"found substring: %s\0A\00"
@.str.15 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.16 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.17 = private unnamed_addr constant [30 x i8] c"null_ptr() == null_ptr(): %s\0A\00"
