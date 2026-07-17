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

%Player = type { i32, float, i8* }
define i32 @add(i32 %a, i32 %b) {
entry:
  %t0 = alloca i32
  %t1 = alloca i32
  store i32 %a, i32* %t0
  store i32 %b, i32* %t1
  %t2 = load i32, i32* %t0
  %t3 = load i32, i32* %t1
  %t4 = add i32 %t2, %t3
  ret i32 %t4
}

define i32 @clamp_health(i32 %h) {
entry:
  %t0 = alloca i32
  store i32 %h, i32* %t0
  %t1 = load i32, i32* %t0
  %t2 = icmp slt i32 %t1, 100
  %t3 = select i1 %t2, i32 %t1, i32 100
  %t4 = icmp sgt i32 0, %t3
  %t5 = select i1 %t4, i32 0, i32 %t3
  ret i32 %t5
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t26 = alloca i8*
  %t32 = alloca i8*
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i32 @add(i32 2, i32 3)
  %t2 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t2, i32 %t1)
  %t3 = call float @llvm.sqrt.f32(float 0x4030000000000000)
  %t4 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.1, i64 0, i64 0
  %t5 = fpext float %t3 to double
  call i32 (i8*, ...) @printf(i8* %t4, double %t5)
  %t6 = call float @llvm.pow.f32(float 0x4000000000000000, float 0x4024000000000000)
  %t7 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.2, i64 0, i64 0
  %t8 = fpext float %t6 to double
  call i32 (i8*, ...) @printf(i8* %t7, double %t8)
  %t9 = sub i32 0, 5
  %t10 = sub i32 0, %t9
  %t11 = icmp slt i32 %t9, 0
  %t12 = select i1 %t11, i32 %t10, i32 %t9
  %t13 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t13, i32 %t12)
  %t14 = fsub float 0.0, 0x4016000000000000
  %t15 = call float @llvm.fabs.f32(float %t14)
  %t16 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.4, i64 0, i64 0
  %t17 = fpext float %t15 to double
  call i32 (i8*, ...) @printf(i8* %t16, double %t17)
  %t18 = call float @llvm.floor.f32(float 0x400E000000000000)
  %t19 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.5, i64 0, i64 0
  %t20 = fpext float %t18 to double
  call i32 (i8*, ...) @printf(i8* %t19, double %t20)
  %t21 = call float @llvm.ceil.f32(float 0x400A000000000000)
  %t22 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.6, i64 0, i64 0
  %t23 = fpext float %t21 to double
  call i32 (i8*, ...) @printf(i8* %t22, double %t23)
  %t24 = call i32 @clamp_health(i32 150)
  %t25 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t25, i32 %t24)
  %t27 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.8, i64 0, i32 2, i64 0
  store i8* %t27, i8** %t26
  %t28 = load i8*, i8** %t26
  %t29 = load i8*, i8** %t26
  call void @star_rc_retain(i8* %t29)
  %t30 = call i32 @strlen(i8* %t28)
  call void @star_rc_release(i8* %t28)
  %t31 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t31, i32 %t30)
  %t33 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t34 = load i8*, i8** %t26
  %t35 = load i8*, i8** %t26
  call void @star_rc_retain(i8* %t35)
  %t36 = call i32 @strlen(i8* %t33)
  %t37 = call i32 @strlen(i8* %t34)
  %t38 = add i32 %t36, %t37
  %t39 = add i32 %t38, 1
  %t40 = sext i32 %t39 to i64
  %t41 = call i8* @star_rc_alloc(i64 %t40, i8* null)
  call i8* @strcpy(i8* %t41, i8* %t33)
  call i8* @strcat(i8* %t41, i8* %t34)
  call void @star_rc_release(i8* %t33)
  call void @star_rc_release(i8* %t34)
  store i8* %t41, i8** %t32
  %t42 = load i8*, i8** %t32
  %t43 = load i8*, i8** %t32
  call void @star_rc_retain(i8* %t43)
  call void @star_rc_release(i8* %t42)
  %t44 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t44, i8* %t42)
  %t45 = load i8*, i8** %t32
  call void @star_rc_release(i8* %t45)
  %t46 = load i8*, i8** %t26
  call void @star_rc_release(i8* %t46)
  ret i32 0
}


; Global Constants
@__star_reflect_Player = private unnamed_addr constant [45 x i8] c"health:0:i32:export;speed:4:float:tweakable;\00"
@.str.0 = private unnamed_addr constant [9 x i8] c"sum: %d\0A\00"
@.str.1 = private unnamed_addr constant [10 x i8] c"sqrt: %f\0A\00"
@.str.2 = private unnamed_addr constant [9 x i8] c"pow: %f\0A\00"
@.str.3 = private unnamed_addr constant [13 x i8] c"abs int: %d\0A\00"
@.str.4 = private unnamed_addr constant [15 x i8] c"abs float: %f\0A\00"
@.str.5 = private unnamed_addr constant [11 x i8] c"floor: %f\0A\00"
@.str.6 = private unnamed_addr constant [10 x i8] c"ceil: %f\0A\00"
@.str.7 = private unnamed_addr constant [13 x i8] c"clamped: %d\0A\00"
@.str.8 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"Hero\00" }
@.str.9 = private unnamed_addr constant [14 x i8] c"name len: %d\0A\00"
@.str.10 = private unnamed_addr constant { i64, i8*, [8 x i8] } { i64 -1, i8* null, [8 x i8] c"hello, \00" }
@.str.11 = private unnamed_addr constant [14 x i8] c"greeting: %s\0A\00"
