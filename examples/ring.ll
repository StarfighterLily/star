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

%Player = type { i32, i8* }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca { [3 x i32], i64, i64 }
  %t68 = alloca i32
  %t83 = alloca i32
  %t98 = alloca i32
  %t134 = alloca i32
  %t149 = alloca i32
  %t164 = alloca i32
  %t168 = alloca i32
  %t202 = alloca i32
  %t206 = alloca { [2 x i32], i64, i64 }
  %t244 = alloca i32
  %t248 = alloca { [2 x i8*], i64, i64 }
  %t306 = alloca i8*
  %t323 = alloca i8*
  %t329 = alloca { [2 x %Player], i64, i64 }
  %t330 = alloca %Player
  %t350 = alloca %Player
  %t382 = alloca %Player
  %t399 = alloca %Player
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  store { [3 x i32], i64, i64 } zeroinitializer, { [3 x i32], i64, i64 }* %t2
  %t3 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t4 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t5 = load i64, i64* %t4
  %t6 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t7 = load i64, i64* %t6
  %t8 = trunc i64 %t7 to i32
  %t9 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t9, i32 %t8)
  %t10 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t11 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t12 = load i64, i64* %t11
  %t13 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t14 = load i64, i64* %t13
  %t15 = icmp sge i64 %t14, 3
  br i1 %t15, label %ring_push_full_0, label %ring_push_grow_1
ring_push_grow_1:
  %t16 = add i64 %t12, %t14
  %t17 = urem i64 %t16, 3
  %t18 = getelementptr inbounds [3 x i32], [3 x i32]* %t10, i32 0, i64 %t17
  store i32 1, i32* %t18
  %t19 = add i64 %t14, 1
  store i64 %t19, i64* %t13
  br label %ring_push_done_2
ring_push_full_0:
  %t20 = getelementptr inbounds [3 x i32], [3 x i32]* %t10, i32 0, i64 %t12
  store i32 1, i32* %t20
  %t21 = add i64 %t12, 1
  %t22 = urem i64 %t21, 3
  store i64 %t22, i64* %t11
  br label %ring_push_done_2
ring_push_done_2:
  %t23 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t24 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t25 = load i64, i64* %t24
  %t26 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t27 = load i64, i64* %t26
  %t28 = icmp sge i64 %t27, 3
  br i1 %t28, label %ring_push_full_3, label %ring_push_grow_4
ring_push_grow_4:
  %t29 = add i64 %t25, %t27
  %t30 = urem i64 %t29, 3
  %t31 = getelementptr inbounds [3 x i32], [3 x i32]* %t23, i32 0, i64 %t30
  store i32 2, i32* %t31
  %t32 = add i64 %t27, 1
  store i64 %t32, i64* %t26
  br label %ring_push_done_5
ring_push_full_3:
  %t33 = getelementptr inbounds [3 x i32], [3 x i32]* %t23, i32 0, i64 %t25
  store i32 2, i32* %t33
  %t34 = add i64 %t25, 1
  %t35 = urem i64 %t34, 3
  store i64 %t35, i64* %t24
  br label %ring_push_done_5
ring_push_done_5:
  %t36 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t37 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t38 = load i64, i64* %t37
  %t39 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t40 = load i64, i64* %t39
  %t41 = icmp sge i64 %t40, 3
  br i1 %t41, label %ring_push_full_6, label %ring_push_grow_7
ring_push_grow_7:
  %t42 = add i64 %t38, %t40
  %t43 = urem i64 %t42, 3
  %t44 = getelementptr inbounds [3 x i32], [3 x i32]* %t36, i32 0, i64 %t43
  store i32 3, i32* %t44
  %t45 = add i64 %t40, 1
  store i64 %t45, i64* %t39
  br label %ring_push_done_8
ring_push_full_6:
  %t46 = getelementptr inbounds [3 x i32], [3 x i32]* %t36, i32 0, i64 %t38
  store i32 3, i32* %t46
  %t47 = add i64 %t38, 1
  %t48 = urem i64 %t47, 3
  store i64 %t48, i64* %t37
  br label %ring_push_done_8
ring_push_done_8:
  %t49 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t50 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t51 = load i64, i64* %t50
  %t52 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t53 = load i64, i64* %t52
  %t54 = trunc i64 %t53 to i32
  %t55 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t55, i32 %t54)
  %t56 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t57 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t58 = load i64, i64* %t57
  %t59 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t60 = load i64, i64* %t59
  %t61 = sext i32 0 to i64
  %t62 = load i64, i64* %t57
  %t63 = load i64, i64* %t59
  %t64 = icmp ult i64 %t61, %t63
  br i1 %t64, label %ring_rplace_ok_9, label %ring_rplace_oob_10
ring_rplace_ok_9:
  %t65 = add i64 %t62, %t61
  %t66 = urem i64 %t65, 3
  %t67 = getelementptr inbounds [3 x i32], [3 x i32]* %t56, i32 0, i64 %t66
  br label %ring_rplace_end_11
ring_rplace_oob_10:
  store i32 0, i32* %t68
  br label %ring_rplace_end_11
ring_rplace_end_11:
  %t69 = phi i32* [ %t67, %ring_rplace_ok_9 ], [ %t68, %ring_rplace_oob_10 ]
  %t70 = load i32, i32* %t69
  %t71 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t72 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t73 = load i64, i64* %t72
  %t74 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t75 = load i64, i64* %t74
  %t76 = sext i32 1 to i64
  %t77 = load i64, i64* %t72
  %t78 = load i64, i64* %t74
  %t79 = icmp ult i64 %t76, %t78
  br i1 %t79, label %ring_rplace_ok_12, label %ring_rplace_oob_13
ring_rplace_ok_12:
  %t80 = add i64 %t77, %t76
  %t81 = urem i64 %t80, 3
  %t82 = getelementptr inbounds [3 x i32], [3 x i32]* %t71, i32 0, i64 %t81
  br label %ring_rplace_end_14
ring_rplace_oob_13:
  store i32 0, i32* %t83
  br label %ring_rplace_end_14
ring_rplace_end_14:
  %t84 = phi i32* [ %t82, %ring_rplace_ok_12 ], [ %t83, %ring_rplace_oob_13 ]
  %t85 = load i32, i32* %t84
  %t86 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t87 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t88 = load i64, i64* %t87
  %t89 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t90 = load i64, i64* %t89
  %t91 = sext i32 2 to i64
  %t92 = load i64, i64* %t87
  %t93 = load i64, i64* %t89
  %t94 = icmp ult i64 %t91, %t93
  br i1 %t94, label %ring_rplace_ok_15, label %ring_rplace_oob_16
ring_rplace_ok_15:
  %t95 = add i64 %t92, %t91
  %t96 = urem i64 %t95, 3
  %t97 = getelementptr inbounds [3 x i32], [3 x i32]* %t86, i32 0, i64 %t96
  br label %ring_rplace_end_17
ring_rplace_oob_16:
  store i32 0, i32* %t98
  br label %ring_rplace_end_17
ring_rplace_end_17:
  %t99 = phi i32* [ %t97, %ring_rplace_ok_15 ], [ %t98, %ring_rplace_oob_16 ]
  %t100 = load i32, i32* %t99
  %t101 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t101, i32 %t70, i32 %t85, i32 %t100)
  %t102 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t103 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t104 = load i64, i64* %t103
  %t105 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t106 = load i64, i64* %t105
  %t107 = icmp sge i64 %t106, 3
  br i1 %t107, label %ring_push_full_18, label %ring_push_grow_19
ring_push_grow_19:
  %t108 = add i64 %t104, %t106
  %t109 = urem i64 %t108, 3
  %t110 = getelementptr inbounds [3 x i32], [3 x i32]* %t102, i32 0, i64 %t109
  store i32 4, i32* %t110
  %t111 = add i64 %t106, 1
  store i64 %t111, i64* %t105
  br label %ring_push_done_20
ring_push_full_18:
  %t112 = getelementptr inbounds [3 x i32], [3 x i32]* %t102, i32 0, i64 %t104
  store i32 4, i32* %t112
  %t113 = add i64 %t104, 1
  %t114 = urem i64 %t113, 3
  store i64 %t114, i64* %t103
  br label %ring_push_done_20
ring_push_done_20:
  %t115 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t116 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t117 = load i64, i64* %t116
  %t118 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t119 = load i64, i64* %t118
  %t120 = trunc i64 %t119 to i32
  %t121 = getelementptr inbounds [35 x i8], [35 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t121, i32 %t120)
  %t122 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t123 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t124 = load i64, i64* %t123
  %t125 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t126 = load i64, i64* %t125
  %t127 = sext i32 0 to i64
  %t128 = load i64, i64* %t123
  %t129 = load i64, i64* %t125
  %t130 = icmp ult i64 %t127, %t129
  br i1 %t130, label %ring_rplace_ok_21, label %ring_rplace_oob_22
ring_rplace_ok_21:
  %t131 = add i64 %t128, %t127
  %t132 = urem i64 %t131, 3
  %t133 = getelementptr inbounds [3 x i32], [3 x i32]* %t122, i32 0, i64 %t132
  br label %ring_rplace_end_23
ring_rplace_oob_22:
  store i32 0, i32* %t134
  br label %ring_rplace_end_23
ring_rplace_end_23:
  %t135 = phi i32* [ %t133, %ring_rplace_ok_21 ], [ %t134, %ring_rplace_oob_22 ]
  %t136 = load i32, i32* %t135
  %t137 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t138 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t139 = load i64, i64* %t138
  %t140 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t141 = load i64, i64* %t140
  %t142 = sext i32 1 to i64
  %t143 = load i64, i64* %t138
  %t144 = load i64, i64* %t140
  %t145 = icmp ult i64 %t142, %t144
  br i1 %t145, label %ring_rplace_ok_24, label %ring_rplace_oob_25
ring_rplace_ok_24:
  %t146 = add i64 %t143, %t142
  %t147 = urem i64 %t146, 3
  %t148 = getelementptr inbounds [3 x i32], [3 x i32]* %t137, i32 0, i64 %t147
  br label %ring_rplace_end_26
ring_rplace_oob_25:
  store i32 0, i32* %t149
  br label %ring_rplace_end_26
ring_rplace_end_26:
  %t150 = phi i32* [ %t148, %ring_rplace_ok_24 ], [ %t149, %ring_rplace_oob_25 ]
  %t151 = load i32, i32* %t150
  %t152 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t153 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t154 = load i64, i64* %t153
  %t155 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t156 = load i64, i64* %t155
  %t157 = sext i32 2 to i64
  %t158 = load i64, i64* %t153
  %t159 = load i64, i64* %t155
  %t160 = icmp ult i64 %t157, %t159
  br i1 %t160, label %ring_rplace_ok_27, label %ring_rplace_oob_28
ring_rplace_ok_27:
  %t161 = add i64 %t158, %t157
  %t162 = urem i64 %t161, 3
  %t163 = getelementptr inbounds [3 x i32], [3 x i32]* %t152, i32 0, i64 %t162
  br label %ring_rplace_end_29
ring_rplace_oob_28:
  store i32 0, i32* %t164
  br label %ring_rplace_end_29
ring_rplace_end_29:
  %t165 = phi i32* [ %t163, %ring_rplace_ok_27 ], [ %t164, %ring_rplace_oob_28 ]
  %t166 = load i32, i32* %t165
  %t167 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t167, i32 %t136, i32 %t151, i32 %t166)
  %t169 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t170 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t171 = load i64, i64* %t170
  %t172 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t173 = load i64, i64* %t172
  %t174 = icmp eq i64 %t173, 0
  br i1 %t174, label %ring_pop_empty_30, label %ring_pop_nonempty_31
ring_pop_nonempty_31:
  %t175 = getelementptr inbounds [3 x i32], [3 x i32]* %t169, i32 0, i64 %t171
  %t176 = load i32, i32* %t175
  store i32 0, i32* %t175
  %t177 = add i64 %t171, 1
  %t178 = urem i64 %t177, 3
  store i64 %t178, i64* %t170
  %t179 = sub i64 %t173, 1
  store i64 %t179, i64* %t172
  br label %ring_pop_end_32
ring_pop_empty_30:
  br label %ring_pop_end_32
ring_pop_end_32:
  %t180 = phi i32 [ %t176, %ring_pop_nonempty_31 ], [ 0, %ring_pop_empty_30 ]
  store i32 %t180, i32* %t168
  %t181 = load i32, i32* %t168
  %t182 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t182, i32 %t181)
  %t183 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t184 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t185 = load i64, i64* %t184
  %t186 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t187 = load i64, i64* %t186
  %t188 = trunc i64 %t187 to i32
  %t189 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t189, i32 %t188)
  %t190 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t191 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t192 = load i64, i64* %t191
  %t193 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t194 = load i64, i64* %t193
  %t195 = sext i32 99 to i64
  %t196 = load i64, i64* %t191
  %t197 = load i64, i64* %t193
  %t198 = icmp ult i64 %t195, %t197
  br i1 %t198, label %ring_rplace_ok_33, label %ring_rplace_oob_34
ring_rplace_ok_33:
  %t199 = add i64 %t196, %t195
  %t200 = urem i64 %t199, 3
  %t201 = getelementptr inbounds [3 x i32], [3 x i32]* %t190, i32 0, i64 %t200
  br label %ring_rplace_end_35
ring_rplace_oob_34:
  store i32 0, i32* %t202
  br label %ring_rplace_end_35
ring_rplace_end_35:
  %t203 = phi i32* [ %t201, %ring_rplace_ok_33 ], [ %t202, %ring_rplace_oob_34 ]
  %t204 = load i32, i32* %t203
  %t205 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t205, i32 %t204)
  store { [2 x i32], i64, i64 } zeroinitializer, { [2 x i32], i64, i64 }* %t206
  %t207 = getelementptr inbounds { [2 x i32], i64, i64 }, { [2 x i32], i64, i64 }* %t206, i32 0, i32 0
  %t208 = getelementptr inbounds { [2 x i32], i64, i64 }, { [2 x i32], i64, i64 }* %t206, i32 0, i32 1
  %t209 = load i64, i64* %t208
  %t210 = getelementptr inbounds { [2 x i32], i64, i64 }, { [2 x i32], i64, i64 }* %t206, i32 0, i32 2
  %t211 = load i64, i64* %t210
  %t212 = icmp eq i64 %t211, 0
  br i1 %t212, label %ring_pop_empty_36, label %ring_pop_nonempty_37
ring_pop_nonempty_37:
  %t213 = getelementptr inbounds [2 x i32], [2 x i32]* %t207, i32 0, i64 %t209
  %t214 = load i32, i32* %t213
  store i32 0, i32* %t213
  %t215 = add i64 %t209, 1
  %t216 = urem i64 %t215, 2
  store i64 %t216, i64* %t208
  %t217 = sub i64 %t211, 1
  store i64 %t217, i64* %t210
  br label %ring_pop_end_38
ring_pop_empty_36:
  br label %ring_pop_end_38
ring_pop_end_38:
  %t218 = phi i32 [ %t214, %ring_pop_nonempty_37 ], [ 0, %ring_pop_empty_36 ]
  %t219 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t219, i32 %t218)
  %t220 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t221 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t222 = load i64, i64* %t221
  %t223 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t224 = load i64, i64* %t223
  %t225 = sext i32 0 to i64
  %t226 = load i64, i64* %t221
  %t227 = load i64, i64* %t223
  %t228 = icmp ult i64 %t225, %t227
  br i1 %t228, label %ring_set_do_39, label %ring_set_oob_40
ring_set_do_39:
  %t229 = add i64 %t226, %t225
  %t230 = urem i64 %t229, 3
  %t231 = getelementptr inbounds [3 x i32], [3 x i32]* %t220, i32 0, i64 %t230
  store i32 100, i32* %t231
  br label %ring_set_end_41
ring_set_oob_40:
  br label %ring_set_end_41
ring_set_end_41:
  %t232 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t233 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t234 = load i64, i64* %t233
  %t235 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t236 = load i64, i64* %t235
  %t237 = sext i32 0 to i64
  %t238 = load i64, i64* %t233
  %t239 = load i64, i64* %t235
  %t240 = icmp ult i64 %t237, %t239
  br i1 %t240, label %ring_rplace_ok_42, label %ring_rplace_oob_43
ring_rplace_ok_42:
  %t241 = add i64 %t238, %t237
  %t242 = urem i64 %t241, 3
  %t243 = getelementptr inbounds [3 x i32], [3 x i32]* %t232, i32 0, i64 %t242
  br label %ring_rplace_end_44
ring_rplace_oob_43:
  store i32 0, i32* %t244
  br label %ring_rplace_end_44
ring_rplace_end_44:
  %t245 = phi i32* [ %t243, %ring_rplace_ok_42 ], [ %t244, %ring_rplace_oob_43 ]
  %t246 = load i32, i32* %t245
  %t247 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t247, i32 %t246)
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t248
  %t249 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t250 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 0
  %t251 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 1
  %t252 = load i64, i64* %t251
  %t253 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 2
  %t254 = load i64, i64* %t253
  %t255 = icmp sge i64 %t254, 2
  br i1 %t255, label %ring_push_full_45, label %ring_push_grow_46
ring_push_grow_46:
  %t256 = add i64 %t252, %t254
  %t257 = urem i64 %t256, 2
  %t258 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t250, i32 0, i64 %t257
  store i8* %t249, i8** %t258
  %t259 = add i64 %t254, 1
  store i64 %t259, i64* %t253
  br label %ring_push_done_47
ring_push_full_45:
  %t260 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t250, i32 0, i64 %t252
  %t261 = load i8*, i8** %t260
  call void @star_rc_release(i8* %t261)
  store i8* %t249, i8** %t260
  %t262 = add i64 %t252, 1
  %t263 = urem i64 %t262, 2
  store i64 %t263, i64* %t251
  br label %ring_push_done_47
ring_push_done_47:
  %t264 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t265 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 0
  %t266 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 1
  %t267 = load i64, i64* %t266
  %t268 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 2
  %t269 = load i64, i64* %t268
  %t270 = icmp sge i64 %t269, 2
  br i1 %t270, label %ring_push_full_48, label %ring_push_grow_49
ring_push_grow_49:
  %t271 = add i64 %t267, %t269
  %t272 = urem i64 %t271, 2
  %t273 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t265, i32 0, i64 %t272
  store i8* %t264, i8** %t273
  %t274 = add i64 %t269, 1
  store i64 %t274, i64* %t268
  br label %ring_push_done_50
ring_push_full_48:
  %t275 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t265, i32 0, i64 %t267
  %t276 = load i8*, i8** %t275
  call void @star_rc_release(i8* %t276)
  store i8* %t264, i8** %t275
  %t277 = add i64 %t267, 1
  %t278 = urem i64 %t277, 2
  store i64 %t278, i64* %t266
  br label %ring_push_done_50
ring_push_done_50:
  %t279 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.12, i64 0, i32 2, i64 0
  %t280 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 0
  %t281 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 1
  %t282 = load i64, i64* %t281
  %t283 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 2
  %t284 = load i64, i64* %t283
  %t285 = icmp sge i64 %t284, 2
  br i1 %t285, label %ring_push_full_51, label %ring_push_grow_52
ring_push_grow_52:
  %t286 = add i64 %t282, %t284
  %t287 = urem i64 %t286, 2
  %t288 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t280, i32 0, i64 %t287
  store i8* %t279, i8** %t288
  %t289 = add i64 %t284, 1
  store i64 %t289, i64* %t283
  br label %ring_push_done_53
ring_push_full_51:
  %t290 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t280, i32 0, i64 %t282
  %t291 = load i8*, i8** %t290
  call void @star_rc_release(i8* %t291)
  store i8* %t279, i8** %t290
  %t292 = add i64 %t282, 1
  %t293 = urem i64 %t292, 2
  store i64 %t293, i64* %t281
  br label %ring_push_done_53
ring_push_done_53:
  %t294 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 0
  %t295 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 1
  %t296 = load i64, i64* %t295
  %t297 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 2
  %t298 = load i64, i64* %t297
  %t299 = sext i32 0 to i64
  %t300 = load i64, i64* %t295
  %t301 = load i64, i64* %t297
  %t302 = icmp ult i64 %t299, %t301
  br i1 %t302, label %ring_rplace_ok_54, label %ring_rplace_oob_55
ring_rplace_ok_54:
  %t303 = add i64 %t300, %t299
  %t304 = urem i64 %t303, 2
  %t305 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t294, i32 0, i64 %t304
  br label %ring_rplace_end_56
ring_rplace_oob_55:
  %t307 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t307
  store i8* %t307, i8** %t306
  br label %ring_rplace_end_56
ring_rplace_end_56:
  %t308 = phi i8** [ %t305, %ring_rplace_ok_54 ], [ %t306, %ring_rplace_oob_55 ]
  %t309 = load i8*, i8** %t308
  %t310 = load i8*, i8** %t308
  call void @star_rc_retain(i8* %t310)
  call void @star_rc_release(i8* %t309)
  %t311 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 0
  %t312 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 1
  %t313 = load i64, i64* %t312
  %t314 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 2
  %t315 = load i64, i64* %t314
  %t316 = sext i32 1 to i64
  %t317 = load i64, i64* %t312
  %t318 = load i64, i64* %t314
  %t319 = icmp ult i64 %t316, %t318
  br i1 %t319, label %ring_rplace_ok_57, label %ring_rplace_oob_58
ring_rplace_ok_57:
  %t320 = add i64 %t317, %t316
  %t321 = urem i64 %t320, 2
  %t322 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t311, i32 0, i64 %t321
  br label %ring_rplace_end_59
ring_rplace_oob_58:
  %t324 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t324
  store i8* %t324, i8** %t323
  br label %ring_rplace_end_59
ring_rplace_end_59:
  %t325 = phi i8** [ %t322, %ring_rplace_ok_57 ], [ %t323, %ring_rplace_oob_58 ]
  %t326 = load i8*, i8** %t325
  %t327 = load i8*, i8** %t325
  call void @star_rc_retain(i8* %t327)
  call void @star_rc_release(i8* %t326)
  %t328 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t328, i8* %t309, i8* %t326)
  store { [2 x %Player], i64, i64 } zeroinitializer, { [2 x %Player], i64, i64 }* %t329
  %t331 = getelementptr inbounds %Player, %Player* %t330, i32 0, i32 0
  store i32 100, i32* %t331
  %t332 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t333 = getelementptr inbounds %Player, %Player* %t330, i32 0, i32 1
  store i8* %t332, i8** %t333
  %t334 = load %Player, %Player* %t330
  %t335 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t329, i32 0, i32 0
  %t336 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t329, i32 0, i32 1
  %t337 = load i64, i64* %t336
  %t338 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t329, i32 0, i32 2
  %t339 = load i64, i64* %t338
  %t340 = icmp sge i64 %t339, 2
  br i1 %t340, label %ring_push_full_60, label %ring_push_grow_61
ring_push_grow_61:
  %t341 = add i64 %t337, %t339
  %t342 = urem i64 %t341, 2
  %t343 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t335, i32 0, i64 %t342
  store %Player %t334, %Player* %t343
  %t344 = add i64 %t339, 1
  store i64 %t344, i64* %t338
  br label %ring_push_done_62
ring_push_full_60:
  %t345 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t335, i32 0, i64 %t337
  %t346 = getelementptr inbounds %Player, %Player* %t345, i32 0, i32 1
  %t347 = load i8*, i8** %t346
  call void @star_rc_release(i8* %t347)
  store %Player %t334, %Player* %t345
  %t348 = add i64 %t337, 1
  %t349 = urem i64 %t348, 2
  store i64 %t349, i64* %t336
  br label %ring_push_done_62
ring_push_done_62:
  %t351 = getelementptr inbounds %Player, %Player* %t350, i32 0, i32 0
  store i32 80, i32* %t351
  %t352 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t353 = getelementptr inbounds %Player, %Player* %t350, i32 0, i32 1
  store i8* %t352, i8** %t353
  %t354 = load %Player, %Player* %t350
  %t355 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t329, i32 0, i32 0
  %t356 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t329, i32 0, i32 1
  %t357 = load i64, i64* %t356
  %t358 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t329, i32 0, i32 2
  %t359 = load i64, i64* %t358
  %t360 = icmp sge i64 %t359, 2
  br i1 %t360, label %ring_push_full_63, label %ring_push_grow_64
ring_push_grow_64:
  %t361 = add i64 %t357, %t359
  %t362 = urem i64 %t361, 2
  %t363 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t355, i32 0, i64 %t362
  store %Player %t354, %Player* %t363
  %t364 = add i64 %t359, 1
  store i64 %t364, i64* %t358
  br label %ring_push_done_65
ring_push_full_63:
  %t365 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t355, i32 0, i64 %t357
  %t366 = getelementptr inbounds %Player, %Player* %t365, i32 0, i32 1
  %t367 = load i8*, i8** %t366
  call void @star_rc_release(i8* %t367)
  store %Player %t354, %Player* %t365
  %t368 = add i64 %t357, 1
  %t369 = urem i64 %t368, 2
  store i64 %t369, i64* %t356
  br label %ring_push_done_65
ring_push_done_65:
  %t370 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t329, i32 0, i32 0
  %t371 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t329, i32 0, i32 1
  %t372 = load i64, i64* %t371
  %t373 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t329, i32 0, i32 2
  %t374 = load i64, i64* %t373
  %t375 = sext i32 0 to i64
  %t376 = load i64, i64* %t371
  %t377 = load i64, i64* %t373
  %t378 = icmp ult i64 %t375, %t377
  br i1 %t378, label %ring_rplace_ok_66, label %ring_rplace_oob_67
ring_rplace_ok_66:
  %t379 = add i64 %t376, %t375
  %t380 = urem i64 %t379, 2
  %t381 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t370, i32 0, i64 %t380
  br label %ring_rplace_end_68
ring_rplace_oob_67:
  store %Player zeroinitializer, %Player* %t382
  br label %ring_rplace_end_68
ring_rplace_end_68:
  %t383 = phi %Player* [ %t381, %ring_rplace_ok_66 ], [ %t382, %ring_rplace_oob_67 ]
  %t384 = getelementptr inbounds %Player, %Player* %t383, i32 0, i32 1
  %t385 = load i8*, i8** %t384
  %t386 = load i8*, i8** %t384
  call void @star_rc_retain(i8* %t386)
  call void @star_rc_release(i8* %t385)
  %t387 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t329, i32 0, i32 0
  %t388 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t329, i32 0, i32 1
  %t389 = load i64, i64* %t388
  %t390 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t329, i32 0, i32 2
  %t391 = load i64, i64* %t390
  %t392 = sext i32 0 to i64
  %t393 = load i64, i64* %t388
  %t394 = load i64, i64* %t390
  %t395 = icmp ult i64 %t392, %t394
  br i1 %t395, label %ring_rplace_ok_69, label %ring_rplace_oob_70
ring_rplace_ok_69:
  %t396 = add i64 %t393, %t392
  %t397 = urem i64 %t396, 2
  %t398 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t387, i32 0, i64 %t397
  br label %ring_rplace_end_71
ring_rplace_oob_70:
  store %Player zeroinitializer, %Player* %t399
  br label %ring_rplace_end_71
ring_rplace_end_71:
  %t400 = phi %Player* [ %t398, %ring_rplace_ok_69 ], [ %t399, %ring_rplace_oob_70 ]
  %t401 = getelementptr inbounds %Player, %Player* %t400, i32 0, i32 0
  %t402 = load i32, i32* %t401
  %t403 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t403, i8* %t385, i32 %t402)
  %t404 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t329, i32 0, i32 0
  %t405 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t404, i32 0, i64 0
  %t406 = getelementptr inbounds %Player, %Player* %t405, i32 0, i32 1
  %t407 = load i8*, i8** %t406
  call void @star_rc_release(i8* %t407)
  %t408 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t404, i32 0, i64 1
  %t409 = getelementptr inbounds %Player, %Player* %t408, i32 0, i32 1
  %t410 = load i8*, i8** %t409
  call void @star_rc_release(i8* %t410)
  %t411 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 0
  %t412 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t411, i32 0, i64 0
  %t413 = load i8*, i8** %t412
  call void @star_rc_release(i8* %t413)
  %t414 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t411, i32 0, i64 1
  %t415 = load i8*, i8** %t414
  call void @star_rc_release(i8* %t415)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [16 x i8] c"empty len = %d\0A\00"
@.str.1 = private unnamed_addr constant [25 x i8] c"after 3 pushes len = %d\0A\00"
@.str.2 = private unnamed_addr constant [24 x i8] c"history = [%d, %d, %d]\0A\00"
@.str.3 = private unnamed_addr constant [35 x i8] c"after push past capacity len = %d\0A\00"
@.str.4 = private unnamed_addr constant [24 x i8] c"history = [%d, %d, %d]\0A\00"
@.str.5 = private unnamed_addr constant [13 x i8] c"popped = %d\0A\00"
@.str.6 = private unnamed_addr constant [20 x i8] c"len after pop = %d\0A\00"
@.str.7 = private unnamed_addr constant [18 x i8] c"history[99] = %d\0A\00"
@.str.8 = private unnamed_addr constant [21 x i8] c"pop from empty = %d\0A\00"
@.str.9 = private unnamed_addr constant [27 x i8] c"history[0] after set = %d\0A\00"
@.str.10 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"alpha\00" }
@.str.11 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"beta\00" }
@.str.12 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"gamma\00" }
@.str.13 = private unnamed_addr constant [18 x i8] c"names = [%s, %s]\0A\00"
@.str.14 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"Hero\00" }
@.str.15 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"Sidekick\00" }
@.str.16 = private unnamed_addr constant [21 x i8] c"party[0] = %s hp=%d\0A\00"
