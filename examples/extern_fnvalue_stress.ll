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

declare i32 @atoi(i8*)
define i32 @call_it({ i8*, i8* } %g) {
entry:
  %t0 = alloca { i8*, i8* }
  %t1 = alloca i8*
  store { i8*, i8* } %g, { i8*, i8* }* %t0
  %t2 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t3 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t4 = call i32 @strlen(i8* %t2)
  %t5 = call i32 @strlen(i8* %t3)
  %t6 = add i32 %t4, %t5
  %t7 = add i32 %t6, 1
  %t8 = sext i32 %t7 to i64
  %t9 = call i8* @star_rc_alloc(i64 %t8, i8* null)
  call i8* @strcpy(i8* %t9, i8* %t2)
  call i8* @strcat(i8* %t9, i8* %t3)
  call void @star_rc_release(i8* %t2)
  call void @star_rc_release(i8* %t3)
  store i8* %t9, i8** %t1
  %t10 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t11 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t12 = extractvalue { i8*, i8* } %t11, 1
  call void @star_rc_retain(i8* %t12)
  %t13 = extractvalue { i8*, i8* } %t10, 0
  %t14 = extractvalue { i8*, i8* } %t10, 1
  call void @star_rc_release(i8* %t14)
  %t15 = bitcast i8* %t13 to i32 (i8*, i8*)*
  %t16 = load i8*, i8** %t1
  %t17 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t17)
  %t18 = call i32 %t15(i8* %t14, i8* %t16)
  %t19 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t19)
  %t20 = load { i8*, i8* }, { i8*, i8* }* %t0
  %t21 = extractvalue { i8*, i8* } %t20, 1
  call void @star_rc_release(i8* %t21)
  ret i32 %t18
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca { i8*, i8* }
  %t6 = alloca i32
  %t7 = alloca i32
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t3 = bitcast i32 (i8*, i8*)* @fnval_atoi to i8*
  %t4 = insertvalue { i8*, i8* } undef, i8* %t3, 0
  %t5 = insertvalue { i8*, i8* } %t4, i8* null, 1
  store { i8*, i8* } %t5, { i8*, i8* }* %t1
  store i32 0, i32* %t6
  store i32 0, i32* %t7
  br label %while_cond_0
while_cond_0:
  %t8 = load i32, i32* %t6
  %t9 = icmp slt i32 %t8, 5000000
  br i1 %t9, label %while_body_1, label %while_else_2
while_body_1:
  %t10 = load i32, i32* %t7
  %t11 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t12 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t13 = extractvalue { i8*, i8* } %t12, 1
  call void @star_rc_retain(i8* %t13)
  %t14 = call i32 @call_it({ i8*, i8* } %t11)
  %t15 = add i32 %t10, %t14
  store i32 %t15, i32* %t7
  %t16 = load i32, i32* %t6
  %t17 = add i32 %t16, 1
  store i32 %t17, i32* %t6
  br label %while_cond_0
while_else_2:
  br label %while_end_3
while_end_3:
  %t18 = load i32, i32* %t7
  %t19 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t19, i32 %t18)
  %t20 = load { i8*, i8* }, { i8*, i8* }* %t1
  %t21 = extractvalue { i8*, i8* } %t20, 1
  call void @star_rc_release(i8* %t21)
  ret i32 0
}


; par/swarm worker functions
define i32 @fnval_atoi(i8* %envp, i8* %arg_0) {
entry:
  %t2 = call i32 @atoi(i8* %arg_0)
  call void @star_rc_release(i8* %arg_0)
  ret i32 %t2
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"4\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"2\00" }
@.str.2 = private unnamed_addr constant [18 x i8] c"done, total = %d\0A\00"
