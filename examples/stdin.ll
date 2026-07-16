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
  %t0 = alloca i8*
  %t2 = alloca i64
  %t17 = alloca i8*
  %t19 = alloca i64
  %t34 = alloca i8*
  %t36 = alloca i64
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t1 = call i8* @star_rc_alloc(i64 1024, i8* null)
  store i64 0, i64* %t2
  br label %read_line_cond_0
read_line_cond_0:
  %t3 = load i64, i64* %t2
  %t4 = icmp ult i64 %t3, 1023
  br i1 %t4, label %read_line_body_1, label %read_line_end_3
read_line_body_1:
  %t5 = call i32 @getchar()
  %t6 = icmp eq i32 %t5, -1
  %t7 = icmp eq i32 %t5, 10
  %t8 = or i1 %t6, %t7
  br i1 %t8, label %read_line_end_3, label %read_line_store_2
read_line_store_2:
  %t9 = getelementptr inbounds i8, i8* %t1, i64 %t3
  %t10 = trunc i32 %t5 to i8
  store i8 %t10, i8* %t9
  %t11 = add i64 %t3, 1
  store i64 %t11, i64* %t2
  br label %read_line_cond_0
read_line_end_3:
  %t12 = load i64, i64* %t2
  %t13 = getelementptr inbounds i8, i8* %t1, i64 %t12
  store i8 0, i8* %t13
  store i8* %t1, i8** %t0
  %t14 = load i8*, i8** %t0
  %t15 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t15)
  call void @star_rc_release(i8* %t14)
  %t16 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t16, i8* %t14)
  %t18 = call i8* @star_rc_alloc(i64 1024, i8* null)
  store i64 0, i64* %t19
  br label %read_line_cond_4
read_line_cond_4:
  %t20 = load i64, i64* %t19
  %t21 = icmp ult i64 %t20, 1023
  br i1 %t21, label %read_line_body_5, label %read_line_end_7
read_line_body_5:
  %t22 = call i32 @getchar()
  %t23 = icmp eq i32 %t22, -1
  %t24 = icmp eq i32 %t22, 10
  %t25 = or i1 %t23, %t24
  br i1 %t25, label %read_line_end_7, label %read_line_store_6
read_line_store_6:
  %t26 = getelementptr inbounds i8, i8* %t18, i64 %t20
  %t27 = trunc i32 %t22 to i8
  store i8 %t27, i8* %t26
  %t28 = add i64 %t20, 1
  store i64 %t28, i64* %t19
  br label %read_line_cond_4
read_line_end_7:
  %t29 = load i64, i64* %t19
  %t30 = getelementptr inbounds i8, i8* %t18, i64 %t29
  store i8 0, i8* %t30
  store i8* %t18, i8** %t17
  %t31 = load i8*, i8** %t17
  %t32 = load i8*, i8** %t17
  call void @star_rc_retain(i8* %t32)
  call void @star_rc_release(i8* %t31)
  %t33 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t33, i8* %t31)
  %t35 = call i8* @star_rc_alloc(i64 1024, i8* null)
  store i64 0, i64* %t36
  br label %read_line_cond_8
read_line_cond_8:
  %t37 = load i64, i64* %t36
  %t38 = icmp ult i64 %t37, 1023
  br i1 %t38, label %read_line_body_9, label %read_line_end_11
read_line_body_9:
  %t39 = call i32 @getchar()
  %t40 = icmp eq i32 %t39, -1
  %t41 = icmp eq i32 %t39, 10
  %t42 = or i1 %t40, %t41
  br i1 %t42, label %read_line_end_11, label %read_line_store_10
read_line_store_10:
  %t43 = getelementptr inbounds i8, i8* %t35, i64 %t37
  %t44 = trunc i32 %t39 to i8
  store i8 %t44, i8* %t43
  %t45 = add i64 %t37, 1
  store i64 %t45, i64* %t36
  br label %read_line_cond_8
read_line_end_11:
  %t46 = load i64, i64* %t36
  %t47 = getelementptr inbounds i8, i8* %t35, i64 %t46
  store i8 0, i8* %t47
  store i8* %t35, i8** %t34
  %t48 = load i8*, i8** %t34
  %t49 = load i8*, i8** %t34
  call void @star_rc_retain(i8* %t49)
  call void @star_rc_release(i8* %t48)
  %t50 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t50, i8* %t48)
  %t51 = load i8*, i8** %t34
  call void @star_rc_release(i8* %t51)
  %t52 = load i8*, i8** %t17
  call void @star_rc_release(i8* %t52)
  %t53 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t53)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [11 x i8] c"hello, %s\0A\00"
@.str.1 = private unnamed_addr constant [11 x i8] c"again: %s\0A\00"
@.str.2 = private unnamed_addr constant [10 x i8] c"last: %s\0A\00"
