; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
declare i32 @puts(i8*)
declare noalias i8* @malloc(i64)
declare void @free(i8*)
declare void @exit(i32) noreturn
declare i32 @strlen(i8*)
declare i32 @getchar()
declare i8* @memcpy(i8*, i8*, i64)
declare i8* @strcpy(i8*, i8*)
declare i8* @strcat(i8*, i8*)
declare i8* @fopen(i8*, i8*)
declare i32 @fclose(i8*)
declare i64 @fread(i8*, i64, i64, i8*)
declare i64 @fwrite(i8*, i64, i64, i8*)
declare i32 @fseek(i8*, i32, i32)
declare i32 @ftell(i8*)
declare i32 @fgetc(i8*)
declare i8* @getenv(i8*)
declare i32 @_putenv(i8*)
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
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = load i64, i64* @frame.off
  %t1 = load i64, i64* @frame.off
  %t2 = add i64 %t1, 4480
  %t3 = icmp ugt i64 %t2, 4096
  br i1 %t3, label %frame_alloc_fail_0, label %frame_alloc_ok_1
frame_alloc_fail_0:
  %t4 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t4)
  call void @exit(i32 1)
  unreachable
frame_alloc_ok_1:
  store i64 %t2, i64* @frame.off
  %t5 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t6 = getelementptr inbounds i8, i8* %t5, i64 %t1
  %t7 = bitcast i8* %t6 to %Big*
  %t8 = alloca %Big
  %t9 = call [4 x <4 x float>] @identity()
  %t10 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 0
  store [4 x <4 x float>] %t9, [4 x <4 x float>]* %t10
  %t11 = call [4 x <4 x float>] @identity()
  %t12 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 1
  store [4 x <4 x float>] %t11, [4 x <4 x float>]* %t12
  %t13 = call [4 x <4 x float>] @identity()
  %t14 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 2
  store [4 x <4 x float>] %t13, [4 x <4 x float>]* %t14
  %t15 = call [4 x <4 x float>] @identity()
  %t16 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 3
  store [4 x <4 x float>] %t15, [4 x <4 x float>]* %t16
  %t17 = call [4 x <4 x float>] @identity()
  %t18 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 4
  store [4 x <4 x float>] %t17, [4 x <4 x float>]* %t18
  %t19 = call [4 x <4 x float>] @identity()
  %t20 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 5
  store [4 x <4 x float>] %t19, [4 x <4 x float>]* %t20
  %t21 = call [4 x <4 x float>] @identity()
  %t22 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 6
  store [4 x <4 x float>] %t21, [4 x <4 x float>]* %t22
  %t23 = call [4 x <4 x float>] @identity()
  %t24 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 7
  store [4 x <4 x float>] %t23, [4 x <4 x float>]* %t24
  %t25 = call [4 x <4 x float>] @identity()
  %t26 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 8
  store [4 x <4 x float>] %t25, [4 x <4 x float>]* %t26
  %t27 = call [4 x <4 x float>] @identity()
  %t28 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 9
  store [4 x <4 x float>] %t27, [4 x <4 x float>]* %t28
  %t29 = call [4 x <4 x float>] @identity()
  %t30 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 10
  store [4 x <4 x float>] %t29, [4 x <4 x float>]* %t30
  %t31 = call [4 x <4 x float>] @identity()
  %t32 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 11
  store [4 x <4 x float>] %t31, [4 x <4 x float>]* %t32
  %t33 = call [4 x <4 x float>] @identity()
  %t34 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 12
  store [4 x <4 x float>] %t33, [4 x <4 x float>]* %t34
  %t35 = call [4 x <4 x float>] @identity()
  %t36 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 13
  store [4 x <4 x float>] %t35, [4 x <4 x float>]* %t36
  %t37 = call [4 x <4 x float>] @identity()
  %t38 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 14
  store [4 x <4 x float>] %t37, [4 x <4 x float>]* %t38
  %t39 = call [4 x <4 x float>] @identity()
  %t40 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 15
  store [4 x <4 x float>] %t39, [4 x <4 x float>]* %t40
  %t41 = call [4 x <4 x float>] @identity()
  %t42 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 16
  store [4 x <4 x float>] %t41, [4 x <4 x float>]* %t42
  %t43 = call [4 x <4 x float>] @identity()
  %t44 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 17
  store [4 x <4 x float>] %t43, [4 x <4 x float>]* %t44
  %t45 = call [4 x <4 x float>] @identity()
  %t46 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 18
  store [4 x <4 x float>] %t45, [4 x <4 x float>]* %t46
  %t47 = call [4 x <4 x float>] @identity()
  %t48 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 19
  store [4 x <4 x float>] %t47, [4 x <4 x float>]* %t48
  %t49 = call [4 x <4 x float>] @identity()
  %t50 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 20
  store [4 x <4 x float>] %t49, [4 x <4 x float>]* %t50
  %t51 = call [4 x <4 x float>] @identity()
  %t52 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 21
  store [4 x <4 x float>] %t51, [4 x <4 x float>]* %t52
  %t53 = call [4 x <4 x float>] @identity()
  %t54 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 22
  store [4 x <4 x float>] %t53, [4 x <4 x float>]* %t54
  %t55 = call [4 x <4 x float>] @identity()
  %t56 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 23
  store [4 x <4 x float>] %t55, [4 x <4 x float>]* %t56
  %t57 = call [4 x <4 x float>] @identity()
  %t58 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 24
  store [4 x <4 x float>] %t57, [4 x <4 x float>]* %t58
  %t59 = call [4 x <4 x float>] @identity()
  %t60 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 25
  store [4 x <4 x float>] %t59, [4 x <4 x float>]* %t60
  %t61 = call [4 x <4 x float>] @identity()
  %t62 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 26
  store [4 x <4 x float>] %t61, [4 x <4 x float>]* %t62
  %t63 = call [4 x <4 x float>] @identity()
  %t64 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 27
  store [4 x <4 x float>] %t63, [4 x <4 x float>]* %t64
  %t65 = call [4 x <4 x float>] @identity()
  %t66 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 28
  store [4 x <4 x float>] %t65, [4 x <4 x float>]* %t66
  %t67 = call [4 x <4 x float>] @identity()
  %t68 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 29
  store [4 x <4 x float>] %t67, [4 x <4 x float>]* %t68
  %t69 = call [4 x <4 x float>] @identity()
  %t70 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 30
  store [4 x <4 x float>] %t69, [4 x <4 x float>]* %t70
  %t71 = call [4 x <4 x float>] @identity()
  %t72 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 31
  store [4 x <4 x float>] %t71, [4 x <4 x float>]* %t72
  %t73 = call [4 x <4 x float>] @identity()
  %t74 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 32
  store [4 x <4 x float>] %t73, [4 x <4 x float>]* %t74
  %t75 = call [4 x <4 x float>] @identity()
  %t76 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 33
  store [4 x <4 x float>] %t75, [4 x <4 x float>]* %t76
  %t77 = call [4 x <4 x float>] @identity()
  %t78 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 34
  store [4 x <4 x float>] %t77, [4 x <4 x float>]* %t78
  %t79 = call [4 x <4 x float>] @identity()
  %t80 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 35
  store [4 x <4 x float>] %t79, [4 x <4 x float>]* %t80
  %t81 = call [4 x <4 x float>] @identity()
  %t82 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 36
  store [4 x <4 x float>] %t81, [4 x <4 x float>]* %t82
  %t83 = call [4 x <4 x float>] @identity()
  %t84 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 37
  store [4 x <4 x float>] %t83, [4 x <4 x float>]* %t84
  %t85 = call [4 x <4 x float>] @identity()
  %t86 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 38
  store [4 x <4 x float>] %t85, [4 x <4 x float>]* %t86
  %t87 = call [4 x <4 x float>] @identity()
  %t88 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 39
  store [4 x <4 x float>] %t87, [4 x <4 x float>]* %t88
  %t89 = call [4 x <4 x float>] @identity()
  %t90 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 40
  store [4 x <4 x float>] %t89, [4 x <4 x float>]* %t90
  %t91 = call [4 x <4 x float>] @identity()
  %t92 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 41
  store [4 x <4 x float>] %t91, [4 x <4 x float>]* %t92
  %t93 = call [4 x <4 x float>] @identity()
  %t94 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 42
  store [4 x <4 x float>] %t93, [4 x <4 x float>]* %t94
  %t95 = call [4 x <4 x float>] @identity()
  %t96 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 43
  store [4 x <4 x float>] %t95, [4 x <4 x float>]* %t96
  %t97 = call [4 x <4 x float>] @identity()
  %t98 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 44
  store [4 x <4 x float>] %t97, [4 x <4 x float>]* %t98
  %t99 = call [4 x <4 x float>] @identity()
  %t100 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 45
  store [4 x <4 x float>] %t99, [4 x <4 x float>]* %t100
  %t101 = call [4 x <4 x float>] @identity()
  %t102 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 46
  store [4 x <4 x float>] %t101, [4 x <4 x float>]* %t102
  %t103 = call [4 x <4 x float>] @identity()
  %t104 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 47
  store [4 x <4 x float>] %t103, [4 x <4 x float>]* %t104
  %t105 = call [4 x <4 x float>] @identity()
  %t106 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 48
  store [4 x <4 x float>] %t105, [4 x <4 x float>]* %t106
  %t107 = call [4 x <4 x float>] @identity()
  %t108 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 49
  store [4 x <4 x float>] %t107, [4 x <4 x float>]* %t108
  %t109 = call [4 x <4 x float>] @identity()
  %t110 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 50
  store [4 x <4 x float>] %t109, [4 x <4 x float>]* %t110
  %t111 = call [4 x <4 x float>] @identity()
  %t112 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 51
  store [4 x <4 x float>] %t111, [4 x <4 x float>]* %t112
  %t113 = call [4 x <4 x float>] @identity()
  %t114 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 52
  store [4 x <4 x float>] %t113, [4 x <4 x float>]* %t114
  %t115 = call [4 x <4 x float>] @identity()
  %t116 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 53
  store [4 x <4 x float>] %t115, [4 x <4 x float>]* %t116
  %t117 = call [4 x <4 x float>] @identity()
  %t118 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 54
  store [4 x <4 x float>] %t117, [4 x <4 x float>]* %t118
  %t119 = call [4 x <4 x float>] @identity()
  %t120 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 55
  store [4 x <4 x float>] %t119, [4 x <4 x float>]* %t120
  %t121 = call [4 x <4 x float>] @identity()
  %t122 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 56
  store [4 x <4 x float>] %t121, [4 x <4 x float>]* %t122
  %t123 = call [4 x <4 x float>] @identity()
  %t124 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 57
  store [4 x <4 x float>] %t123, [4 x <4 x float>]* %t124
  %t125 = call [4 x <4 x float>] @identity()
  %t126 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 58
  store [4 x <4 x float>] %t125, [4 x <4 x float>]* %t126
  %t127 = call [4 x <4 x float>] @identity()
  %t128 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 59
  store [4 x <4 x float>] %t127, [4 x <4 x float>]* %t128
  %t129 = call [4 x <4 x float>] @identity()
  %t130 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 60
  store [4 x <4 x float>] %t129, [4 x <4 x float>]* %t130
  %t131 = call [4 x <4 x float>] @identity()
  %t132 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 61
  store [4 x <4 x float>] %t131, [4 x <4 x float>]* %t132
  %t133 = call [4 x <4 x float>] @identity()
  %t134 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 62
  store [4 x <4 x float>] %t133, [4 x <4 x float>]* %t134
  %t135 = call [4 x <4 x float>] @identity()
  %t136 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 63
  store [4 x <4 x float>] %t135, [4 x <4 x float>]* %t136
  %t137 = call [4 x <4 x float>] @identity()
  %t138 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 64
  store [4 x <4 x float>] %t137, [4 x <4 x float>]* %t138
  %t139 = call [4 x <4 x float>] @identity()
  %t140 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 65
  store [4 x <4 x float>] %t139, [4 x <4 x float>]* %t140
  %t141 = call [4 x <4 x float>] @identity()
  %t142 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 66
  store [4 x <4 x float>] %t141, [4 x <4 x float>]* %t142
  %t143 = call [4 x <4 x float>] @identity()
  %t144 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 67
  store [4 x <4 x float>] %t143, [4 x <4 x float>]* %t144
  %t145 = call [4 x <4 x float>] @identity()
  %t146 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 68
  store [4 x <4 x float>] %t145, [4 x <4 x float>]* %t146
  %t147 = call [4 x <4 x float>] @identity()
  %t148 = getelementptr inbounds %Big, %Big* %t8, i32 0, i32 69
  store [4 x <4 x float>] %t147, [4 x <4 x float>]* %t148
  %t149 = load %Big, %Big* %t8
  store %Big %t149, %Big* %t7
  %t150 = getelementptr inbounds { i64, i8*, [65 x i8] }, { i64, i8*, [65 x i8] }* @.str.1, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t150)
  store i64 %t0, i64* @frame.off
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [70 x i8] c"star runtime error: a `frame:` block exceeded its 4096-byte capacity\0A\00"
@.str.1 = private unnamed_addr constant { i64, i8*, [65 x i8] } { i64 -1, i8* null, [65 x i8] c"should not reach here: frame allocator did not abort on overflow\00" }
