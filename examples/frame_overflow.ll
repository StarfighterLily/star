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

%Big = type { [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>], [4 x <4 x float>] }
define [4 x <4 x float>] @identity() {
entry:
  %t0 = sitofp i32 1 to float
  %t1 = insertelement <4 x float> undef, float %t0, i32 0
  %t2 = sitofp i32 0 to float
  %t3 = insertelement <4 x float> %t1, float %t2, i32 1
  %t4 = sitofp i32 0 to float
  %t5 = insertelement <4 x float> %t3, float %t4, i32 2
  %t6 = sitofp i32 0 to float
  %t7 = insertelement <4 x float> %t5, float %t6, i32 3
  %t8 = insertvalue [4 x <4 x float>] undef, <4 x float> %t7, 0
  %t9 = sitofp i32 0 to float
  %t10 = insertelement <4 x float> undef, float %t9, i32 0
  %t11 = sitofp i32 1 to float
  %t12 = insertelement <4 x float> %t10, float %t11, i32 1
  %t13 = sitofp i32 0 to float
  %t14 = insertelement <4 x float> %t12, float %t13, i32 2
  %t15 = sitofp i32 0 to float
  %t16 = insertelement <4 x float> %t14, float %t15, i32 3
  %t17 = insertvalue [4 x <4 x float>] %t8, <4 x float> %t16, 1
  %t18 = sitofp i32 0 to float
  %t19 = insertelement <4 x float> undef, float %t18, i32 0
  %t20 = sitofp i32 0 to float
  %t21 = insertelement <4 x float> %t19, float %t20, i32 1
  %t22 = sitofp i32 1 to float
  %t23 = insertelement <4 x float> %t21, float %t22, i32 2
  %t24 = sitofp i32 0 to float
  %t25 = insertelement <4 x float> %t23, float %t24, i32 3
  %t26 = insertvalue [4 x <4 x float>] %t17, <4 x float> %t25, 2
  %t27 = sitofp i32 0 to float
  %t28 = insertelement <4 x float> undef, float %t27, i32 0
  %t29 = sitofp i32 0 to float
  %t30 = insertelement <4 x float> %t28, float %t29, i32 1
  %t31 = sitofp i32 0 to float
  %t32 = insertelement <4 x float> %t30, float %t31, i32 2
  %t33 = sitofp i32 1 to float
  %t34 = insertelement <4 x float> %t32, float %t33, i32 3
  %t35 = insertvalue [4 x <4 x float>] %t26, <4 x float> %t34, 3
  ret [4 x <4 x float>] %t35
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t11 = alloca %Big
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = load i64, i64* @frame.off
  %t2 = getelementptr %Big, %Big* null, i32 1
  %t3 = ptrtoint %Big* %t2 to i64
  %t4 = load i64, i64* @frame.off
  %t5 = add i64 %t4, %t3
  %t6 = icmp ugt i64 %t5, 4096
  br i1 %t6, label %frame_alloc_fail_0, label %frame_alloc_ok_1
frame_alloc_fail_0:
  %t7 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t7)
  call void @exit(i32 1)
  unreachable
frame_alloc_ok_1:
  store i64 %t5, i64* @frame.off
  %t8 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t9 = getelementptr inbounds i8, i8* %t8, i64 %t4
  %t10 = bitcast i8* %t9 to %Big*
  %t12 = call [4 x <4 x float>] @identity()
  %t13 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 0
  store [4 x <4 x float>] %t12, [4 x <4 x float>]* %t13
  %t14 = call [4 x <4 x float>] @identity()
  %t15 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 1
  store [4 x <4 x float>] %t14, [4 x <4 x float>]* %t15
  %t16 = call [4 x <4 x float>] @identity()
  %t17 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 2
  store [4 x <4 x float>] %t16, [4 x <4 x float>]* %t17
  %t18 = call [4 x <4 x float>] @identity()
  %t19 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 3
  store [4 x <4 x float>] %t18, [4 x <4 x float>]* %t19
  %t20 = call [4 x <4 x float>] @identity()
  %t21 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 4
  store [4 x <4 x float>] %t20, [4 x <4 x float>]* %t21
  %t22 = call [4 x <4 x float>] @identity()
  %t23 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 5
  store [4 x <4 x float>] %t22, [4 x <4 x float>]* %t23
  %t24 = call [4 x <4 x float>] @identity()
  %t25 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 6
  store [4 x <4 x float>] %t24, [4 x <4 x float>]* %t25
  %t26 = call [4 x <4 x float>] @identity()
  %t27 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 7
  store [4 x <4 x float>] %t26, [4 x <4 x float>]* %t27
  %t28 = call [4 x <4 x float>] @identity()
  %t29 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 8
  store [4 x <4 x float>] %t28, [4 x <4 x float>]* %t29
  %t30 = call [4 x <4 x float>] @identity()
  %t31 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 9
  store [4 x <4 x float>] %t30, [4 x <4 x float>]* %t31
  %t32 = call [4 x <4 x float>] @identity()
  %t33 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 10
  store [4 x <4 x float>] %t32, [4 x <4 x float>]* %t33
  %t34 = call [4 x <4 x float>] @identity()
  %t35 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 11
  store [4 x <4 x float>] %t34, [4 x <4 x float>]* %t35
  %t36 = call [4 x <4 x float>] @identity()
  %t37 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 12
  store [4 x <4 x float>] %t36, [4 x <4 x float>]* %t37
  %t38 = call [4 x <4 x float>] @identity()
  %t39 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 13
  store [4 x <4 x float>] %t38, [4 x <4 x float>]* %t39
  %t40 = call [4 x <4 x float>] @identity()
  %t41 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 14
  store [4 x <4 x float>] %t40, [4 x <4 x float>]* %t41
  %t42 = call [4 x <4 x float>] @identity()
  %t43 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 15
  store [4 x <4 x float>] %t42, [4 x <4 x float>]* %t43
  %t44 = call [4 x <4 x float>] @identity()
  %t45 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 16
  store [4 x <4 x float>] %t44, [4 x <4 x float>]* %t45
  %t46 = call [4 x <4 x float>] @identity()
  %t47 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 17
  store [4 x <4 x float>] %t46, [4 x <4 x float>]* %t47
  %t48 = call [4 x <4 x float>] @identity()
  %t49 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 18
  store [4 x <4 x float>] %t48, [4 x <4 x float>]* %t49
  %t50 = call [4 x <4 x float>] @identity()
  %t51 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 19
  store [4 x <4 x float>] %t50, [4 x <4 x float>]* %t51
  %t52 = call [4 x <4 x float>] @identity()
  %t53 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 20
  store [4 x <4 x float>] %t52, [4 x <4 x float>]* %t53
  %t54 = call [4 x <4 x float>] @identity()
  %t55 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 21
  store [4 x <4 x float>] %t54, [4 x <4 x float>]* %t55
  %t56 = call [4 x <4 x float>] @identity()
  %t57 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 22
  store [4 x <4 x float>] %t56, [4 x <4 x float>]* %t57
  %t58 = call [4 x <4 x float>] @identity()
  %t59 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 23
  store [4 x <4 x float>] %t58, [4 x <4 x float>]* %t59
  %t60 = call [4 x <4 x float>] @identity()
  %t61 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 24
  store [4 x <4 x float>] %t60, [4 x <4 x float>]* %t61
  %t62 = call [4 x <4 x float>] @identity()
  %t63 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 25
  store [4 x <4 x float>] %t62, [4 x <4 x float>]* %t63
  %t64 = call [4 x <4 x float>] @identity()
  %t65 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 26
  store [4 x <4 x float>] %t64, [4 x <4 x float>]* %t65
  %t66 = call [4 x <4 x float>] @identity()
  %t67 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 27
  store [4 x <4 x float>] %t66, [4 x <4 x float>]* %t67
  %t68 = call [4 x <4 x float>] @identity()
  %t69 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 28
  store [4 x <4 x float>] %t68, [4 x <4 x float>]* %t69
  %t70 = call [4 x <4 x float>] @identity()
  %t71 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 29
  store [4 x <4 x float>] %t70, [4 x <4 x float>]* %t71
  %t72 = call [4 x <4 x float>] @identity()
  %t73 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 30
  store [4 x <4 x float>] %t72, [4 x <4 x float>]* %t73
  %t74 = call [4 x <4 x float>] @identity()
  %t75 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 31
  store [4 x <4 x float>] %t74, [4 x <4 x float>]* %t75
  %t76 = call [4 x <4 x float>] @identity()
  %t77 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 32
  store [4 x <4 x float>] %t76, [4 x <4 x float>]* %t77
  %t78 = call [4 x <4 x float>] @identity()
  %t79 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 33
  store [4 x <4 x float>] %t78, [4 x <4 x float>]* %t79
  %t80 = call [4 x <4 x float>] @identity()
  %t81 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 34
  store [4 x <4 x float>] %t80, [4 x <4 x float>]* %t81
  %t82 = call [4 x <4 x float>] @identity()
  %t83 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 35
  store [4 x <4 x float>] %t82, [4 x <4 x float>]* %t83
  %t84 = call [4 x <4 x float>] @identity()
  %t85 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 36
  store [4 x <4 x float>] %t84, [4 x <4 x float>]* %t85
  %t86 = call [4 x <4 x float>] @identity()
  %t87 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 37
  store [4 x <4 x float>] %t86, [4 x <4 x float>]* %t87
  %t88 = call [4 x <4 x float>] @identity()
  %t89 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 38
  store [4 x <4 x float>] %t88, [4 x <4 x float>]* %t89
  %t90 = call [4 x <4 x float>] @identity()
  %t91 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 39
  store [4 x <4 x float>] %t90, [4 x <4 x float>]* %t91
  %t92 = call [4 x <4 x float>] @identity()
  %t93 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 40
  store [4 x <4 x float>] %t92, [4 x <4 x float>]* %t93
  %t94 = call [4 x <4 x float>] @identity()
  %t95 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 41
  store [4 x <4 x float>] %t94, [4 x <4 x float>]* %t95
  %t96 = call [4 x <4 x float>] @identity()
  %t97 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 42
  store [4 x <4 x float>] %t96, [4 x <4 x float>]* %t97
  %t98 = call [4 x <4 x float>] @identity()
  %t99 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 43
  store [4 x <4 x float>] %t98, [4 x <4 x float>]* %t99
  %t100 = call [4 x <4 x float>] @identity()
  %t101 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 44
  store [4 x <4 x float>] %t100, [4 x <4 x float>]* %t101
  %t102 = call [4 x <4 x float>] @identity()
  %t103 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 45
  store [4 x <4 x float>] %t102, [4 x <4 x float>]* %t103
  %t104 = call [4 x <4 x float>] @identity()
  %t105 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 46
  store [4 x <4 x float>] %t104, [4 x <4 x float>]* %t105
  %t106 = call [4 x <4 x float>] @identity()
  %t107 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 47
  store [4 x <4 x float>] %t106, [4 x <4 x float>]* %t107
  %t108 = call [4 x <4 x float>] @identity()
  %t109 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 48
  store [4 x <4 x float>] %t108, [4 x <4 x float>]* %t109
  %t110 = call [4 x <4 x float>] @identity()
  %t111 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 49
  store [4 x <4 x float>] %t110, [4 x <4 x float>]* %t111
  %t112 = call [4 x <4 x float>] @identity()
  %t113 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 50
  store [4 x <4 x float>] %t112, [4 x <4 x float>]* %t113
  %t114 = call [4 x <4 x float>] @identity()
  %t115 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 51
  store [4 x <4 x float>] %t114, [4 x <4 x float>]* %t115
  %t116 = call [4 x <4 x float>] @identity()
  %t117 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 52
  store [4 x <4 x float>] %t116, [4 x <4 x float>]* %t117
  %t118 = call [4 x <4 x float>] @identity()
  %t119 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 53
  store [4 x <4 x float>] %t118, [4 x <4 x float>]* %t119
  %t120 = call [4 x <4 x float>] @identity()
  %t121 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 54
  store [4 x <4 x float>] %t120, [4 x <4 x float>]* %t121
  %t122 = call [4 x <4 x float>] @identity()
  %t123 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 55
  store [4 x <4 x float>] %t122, [4 x <4 x float>]* %t123
  %t124 = call [4 x <4 x float>] @identity()
  %t125 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 56
  store [4 x <4 x float>] %t124, [4 x <4 x float>]* %t125
  %t126 = call [4 x <4 x float>] @identity()
  %t127 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 57
  store [4 x <4 x float>] %t126, [4 x <4 x float>]* %t127
  %t128 = call [4 x <4 x float>] @identity()
  %t129 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 58
  store [4 x <4 x float>] %t128, [4 x <4 x float>]* %t129
  %t130 = call [4 x <4 x float>] @identity()
  %t131 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 59
  store [4 x <4 x float>] %t130, [4 x <4 x float>]* %t131
  %t132 = call [4 x <4 x float>] @identity()
  %t133 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 60
  store [4 x <4 x float>] %t132, [4 x <4 x float>]* %t133
  %t134 = call [4 x <4 x float>] @identity()
  %t135 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 61
  store [4 x <4 x float>] %t134, [4 x <4 x float>]* %t135
  %t136 = call [4 x <4 x float>] @identity()
  %t137 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 62
  store [4 x <4 x float>] %t136, [4 x <4 x float>]* %t137
  %t138 = call [4 x <4 x float>] @identity()
  %t139 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 63
  store [4 x <4 x float>] %t138, [4 x <4 x float>]* %t139
  %t140 = call [4 x <4 x float>] @identity()
  %t141 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 64
  store [4 x <4 x float>] %t140, [4 x <4 x float>]* %t141
  %t142 = call [4 x <4 x float>] @identity()
  %t143 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 65
  store [4 x <4 x float>] %t142, [4 x <4 x float>]* %t143
  %t144 = call [4 x <4 x float>] @identity()
  %t145 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 66
  store [4 x <4 x float>] %t144, [4 x <4 x float>]* %t145
  %t146 = call [4 x <4 x float>] @identity()
  %t147 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 67
  store [4 x <4 x float>] %t146, [4 x <4 x float>]* %t147
  %t148 = call [4 x <4 x float>] @identity()
  %t149 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 68
  store [4 x <4 x float>] %t148, [4 x <4 x float>]* %t149
  %t150 = call [4 x <4 x float>] @identity()
  %t151 = getelementptr inbounds %Big, %Big* %t11, i32 0, i32 69
  store [4 x <4 x float>] %t150, [4 x <4 x float>]* %t151
  %t152 = load %Big, %Big* %t11
  store %Big %t152, %Big* %t10
  %t153 = getelementptr inbounds { i64, i8*, [65 x i8] }, { i64, i8*, [65 x i8] }* @.str.1, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t153)
  call i32 (i8*, ...) @printf(i8* %t153)
  store i64 %t1, i64* @frame.off
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [70 x i8] c"star runtime error: a `frame:` block exceeded its 4096-byte capacity\0A\00"
@.str.1 = private unnamed_addr constant { i64, i8*, [65 x i8] } { i64 -1, i8* null, [65 x i8] c"should not reach here: frame allocator did not abort on overflow\00" }
