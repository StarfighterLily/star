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

%Player = type { i32, i8* }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca { [3 x i32], i64, i64 }
  %t67 = alloca i32
  %t82 = alloca i32
  %t97 = alloca i32
  %t133 = alloca i32
  %t148 = alloca i32
  %t163 = alloca i32
  %t167 = alloca i32
  %t201 = alloca i32
  %t205 = alloca { [2 x i32], i64, i64 }
  %t243 = alloca i32
  %t247 = alloca { [2 x i8*], i64, i64 }
  %t305 = alloca i8*
  %t321 = alloca i8*
  %t326 = alloca { [2 x %Player], i64, i64 }
  %t327 = alloca %Player
  %t347 = alloca %Player
  %t379 = alloca %Player
  %t396 = alloca %Player
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  store { [3 x i32], i64, i64 } zeroinitializer, { [3 x i32], i64, i64 }* %t1
  %t2 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t3 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t4 = load i64, i64* %t3
  %t5 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t6 = load i64, i64* %t5
  %t7 = trunc i64 %t6 to i32
  %t8 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t8, i32 %t7)
  %t9 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t10 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t11 = load i64, i64* %t10
  %t12 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t13 = load i64, i64* %t12
  %t14 = icmp sge i64 %t13, 3
  br i1 %t14, label %ring_push_full_0, label %ring_push_grow_1
ring_push_grow_1:
  %t15 = add i64 %t11, %t13
  %t16 = urem i64 %t15, 3
  %t17 = getelementptr inbounds [3 x i32], [3 x i32]* %t9, i32 0, i64 %t16
  store i32 1, i32* %t17
  %t18 = add i64 %t13, 1
  store i64 %t18, i64* %t12
  br label %ring_push_done_2
ring_push_full_0:
  %t19 = getelementptr inbounds [3 x i32], [3 x i32]* %t9, i32 0, i64 %t11
  store i32 1, i32* %t19
  %t20 = add i64 %t11, 1
  %t21 = urem i64 %t20, 3
  store i64 %t21, i64* %t10
  br label %ring_push_done_2
ring_push_done_2:
  %t22 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t23 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t24 = load i64, i64* %t23
  %t25 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t26 = load i64, i64* %t25
  %t27 = icmp sge i64 %t26, 3
  br i1 %t27, label %ring_push_full_3, label %ring_push_grow_4
ring_push_grow_4:
  %t28 = add i64 %t24, %t26
  %t29 = urem i64 %t28, 3
  %t30 = getelementptr inbounds [3 x i32], [3 x i32]* %t22, i32 0, i64 %t29
  store i32 2, i32* %t30
  %t31 = add i64 %t26, 1
  store i64 %t31, i64* %t25
  br label %ring_push_done_5
ring_push_full_3:
  %t32 = getelementptr inbounds [3 x i32], [3 x i32]* %t22, i32 0, i64 %t24
  store i32 2, i32* %t32
  %t33 = add i64 %t24, 1
  %t34 = urem i64 %t33, 3
  store i64 %t34, i64* %t23
  br label %ring_push_done_5
ring_push_done_5:
  %t35 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t36 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t37 = load i64, i64* %t36
  %t38 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t39 = load i64, i64* %t38
  %t40 = icmp sge i64 %t39, 3
  br i1 %t40, label %ring_push_full_6, label %ring_push_grow_7
ring_push_grow_7:
  %t41 = add i64 %t37, %t39
  %t42 = urem i64 %t41, 3
  %t43 = getelementptr inbounds [3 x i32], [3 x i32]* %t35, i32 0, i64 %t42
  store i32 3, i32* %t43
  %t44 = add i64 %t39, 1
  store i64 %t44, i64* %t38
  br label %ring_push_done_8
ring_push_full_6:
  %t45 = getelementptr inbounds [3 x i32], [3 x i32]* %t35, i32 0, i64 %t37
  store i32 3, i32* %t45
  %t46 = add i64 %t37, 1
  %t47 = urem i64 %t46, 3
  store i64 %t47, i64* %t36
  br label %ring_push_done_8
ring_push_done_8:
  %t48 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t49 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t50 = load i64, i64* %t49
  %t51 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t52 = load i64, i64* %t51
  %t53 = trunc i64 %t52 to i32
  %t54 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t54, i32 %t53)
  %t55 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t56 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t57 = load i64, i64* %t56
  %t58 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t59 = load i64, i64* %t58
  %t60 = sext i32 0 to i64
  %t61 = load i64, i64* %t56
  %t62 = load i64, i64* %t58
  %t63 = icmp ult i64 %t60, %t62
  br i1 %t63, label %ring_rplace_ok_9, label %ring_rplace_oob_10
ring_rplace_ok_9:
  %t64 = add i64 %t61, %t60
  %t65 = urem i64 %t64, 3
  %t66 = getelementptr inbounds [3 x i32], [3 x i32]* %t55, i32 0, i64 %t65
  br label %ring_rplace_end_11
ring_rplace_oob_10:
  store i32 0, i32* %t67
  br label %ring_rplace_end_11
ring_rplace_end_11:
  %t68 = phi i32* [ %t66, %ring_rplace_ok_9 ], [ %t67, %ring_rplace_oob_10 ]
  %t69 = load i32, i32* %t68
  %t70 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t71 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t72 = load i64, i64* %t71
  %t73 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t74 = load i64, i64* %t73
  %t75 = sext i32 1 to i64
  %t76 = load i64, i64* %t71
  %t77 = load i64, i64* %t73
  %t78 = icmp ult i64 %t75, %t77
  br i1 %t78, label %ring_rplace_ok_12, label %ring_rplace_oob_13
ring_rplace_ok_12:
  %t79 = add i64 %t76, %t75
  %t80 = urem i64 %t79, 3
  %t81 = getelementptr inbounds [3 x i32], [3 x i32]* %t70, i32 0, i64 %t80
  br label %ring_rplace_end_14
ring_rplace_oob_13:
  store i32 0, i32* %t82
  br label %ring_rplace_end_14
ring_rplace_end_14:
  %t83 = phi i32* [ %t81, %ring_rplace_ok_12 ], [ %t82, %ring_rplace_oob_13 ]
  %t84 = load i32, i32* %t83
  %t85 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t86 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t87 = load i64, i64* %t86
  %t88 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t89 = load i64, i64* %t88
  %t90 = sext i32 2 to i64
  %t91 = load i64, i64* %t86
  %t92 = load i64, i64* %t88
  %t93 = icmp ult i64 %t90, %t92
  br i1 %t93, label %ring_rplace_ok_15, label %ring_rplace_oob_16
ring_rplace_ok_15:
  %t94 = add i64 %t91, %t90
  %t95 = urem i64 %t94, 3
  %t96 = getelementptr inbounds [3 x i32], [3 x i32]* %t85, i32 0, i64 %t95
  br label %ring_rplace_end_17
ring_rplace_oob_16:
  store i32 0, i32* %t97
  br label %ring_rplace_end_17
ring_rplace_end_17:
  %t98 = phi i32* [ %t96, %ring_rplace_ok_15 ], [ %t97, %ring_rplace_oob_16 ]
  %t99 = load i32, i32* %t98
  %t100 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t100, i32 %t69, i32 %t84, i32 %t99)
  %t101 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t102 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t103 = load i64, i64* %t102
  %t104 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t105 = load i64, i64* %t104
  %t106 = icmp sge i64 %t105, 3
  br i1 %t106, label %ring_push_full_18, label %ring_push_grow_19
ring_push_grow_19:
  %t107 = add i64 %t103, %t105
  %t108 = urem i64 %t107, 3
  %t109 = getelementptr inbounds [3 x i32], [3 x i32]* %t101, i32 0, i64 %t108
  store i32 4, i32* %t109
  %t110 = add i64 %t105, 1
  store i64 %t110, i64* %t104
  br label %ring_push_done_20
ring_push_full_18:
  %t111 = getelementptr inbounds [3 x i32], [3 x i32]* %t101, i32 0, i64 %t103
  store i32 4, i32* %t111
  %t112 = add i64 %t103, 1
  %t113 = urem i64 %t112, 3
  store i64 %t113, i64* %t102
  br label %ring_push_done_20
ring_push_done_20:
  %t114 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t115 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t116 = load i64, i64* %t115
  %t117 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t118 = load i64, i64* %t117
  %t119 = trunc i64 %t118 to i32
  %t120 = getelementptr inbounds [35 x i8], [35 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t120, i32 %t119)
  %t121 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t122 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t123 = load i64, i64* %t122
  %t124 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t125 = load i64, i64* %t124
  %t126 = sext i32 0 to i64
  %t127 = load i64, i64* %t122
  %t128 = load i64, i64* %t124
  %t129 = icmp ult i64 %t126, %t128
  br i1 %t129, label %ring_rplace_ok_21, label %ring_rplace_oob_22
ring_rplace_ok_21:
  %t130 = add i64 %t127, %t126
  %t131 = urem i64 %t130, 3
  %t132 = getelementptr inbounds [3 x i32], [3 x i32]* %t121, i32 0, i64 %t131
  br label %ring_rplace_end_23
ring_rplace_oob_22:
  store i32 0, i32* %t133
  br label %ring_rplace_end_23
ring_rplace_end_23:
  %t134 = phi i32* [ %t132, %ring_rplace_ok_21 ], [ %t133, %ring_rplace_oob_22 ]
  %t135 = load i32, i32* %t134
  %t136 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t137 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t138 = load i64, i64* %t137
  %t139 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t140 = load i64, i64* %t139
  %t141 = sext i32 1 to i64
  %t142 = load i64, i64* %t137
  %t143 = load i64, i64* %t139
  %t144 = icmp ult i64 %t141, %t143
  br i1 %t144, label %ring_rplace_ok_24, label %ring_rplace_oob_25
ring_rplace_ok_24:
  %t145 = add i64 %t142, %t141
  %t146 = urem i64 %t145, 3
  %t147 = getelementptr inbounds [3 x i32], [3 x i32]* %t136, i32 0, i64 %t146
  br label %ring_rplace_end_26
ring_rplace_oob_25:
  store i32 0, i32* %t148
  br label %ring_rplace_end_26
ring_rplace_end_26:
  %t149 = phi i32* [ %t147, %ring_rplace_ok_24 ], [ %t148, %ring_rplace_oob_25 ]
  %t150 = load i32, i32* %t149
  %t151 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t152 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t153 = load i64, i64* %t152
  %t154 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t155 = load i64, i64* %t154
  %t156 = sext i32 2 to i64
  %t157 = load i64, i64* %t152
  %t158 = load i64, i64* %t154
  %t159 = icmp ult i64 %t156, %t158
  br i1 %t159, label %ring_rplace_ok_27, label %ring_rplace_oob_28
ring_rplace_ok_27:
  %t160 = add i64 %t157, %t156
  %t161 = urem i64 %t160, 3
  %t162 = getelementptr inbounds [3 x i32], [3 x i32]* %t151, i32 0, i64 %t161
  br label %ring_rplace_end_29
ring_rplace_oob_28:
  store i32 0, i32* %t163
  br label %ring_rplace_end_29
ring_rplace_end_29:
  %t164 = phi i32* [ %t162, %ring_rplace_ok_27 ], [ %t163, %ring_rplace_oob_28 ]
  %t165 = load i32, i32* %t164
  %t166 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t166, i32 %t135, i32 %t150, i32 %t165)
  %t168 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t169 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t170 = load i64, i64* %t169
  %t171 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t172 = load i64, i64* %t171
  %t173 = icmp eq i64 %t172, 0
  br i1 %t173, label %ring_pop_empty_30, label %ring_pop_nonempty_31
ring_pop_nonempty_31:
  %t174 = getelementptr inbounds [3 x i32], [3 x i32]* %t168, i32 0, i64 %t170
  %t175 = load i32, i32* %t174
  store i32 0, i32* %t174
  %t176 = add i64 %t170, 1
  %t177 = urem i64 %t176, 3
  store i64 %t177, i64* %t169
  %t178 = sub i64 %t172, 1
  store i64 %t178, i64* %t171
  br label %ring_pop_end_32
ring_pop_empty_30:
  br label %ring_pop_end_32
ring_pop_end_32:
  %t179 = phi i32 [ %t175, %ring_pop_nonempty_31 ], [ 0, %ring_pop_empty_30 ]
  store i32 %t179, i32* %t167
  %t180 = load i32, i32* %t167
  %t181 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t181, i32 %t180)
  %t182 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t183 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t184 = load i64, i64* %t183
  %t185 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t186 = load i64, i64* %t185
  %t187 = trunc i64 %t186 to i32
  %t188 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t188, i32 %t187)
  %t189 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t190 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t191 = load i64, i64* %t190
  %t192 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t193 = load i64, i64* %t192
  %t194 = sext i32 99 to i64
  %t195 = load i64, i64* %t190
  %t196 = load i64, i64* %t192
  %t197 = icmp ult i64 %t194, %t196
  br i1 %t197, label %ring_rplace_ok_33, label %ring_rplace_oob_34
ring_rplace_ok_33:
  %t198 = add i64 %t195, %t194
  %t199 = urem i64 %t198, 3
  %t200 = getelementptr inbounds [3 x i32], [3 x i32]* %t189, i32 0, i64 %t199
  br label %ring_rplace_end_35
ring_rplace_oob_34:
  store i32 0, i32* %t201
  br label %ring_rplace_end_35
ring_rplace_end_35:
  %t202 = phi i32* [ %t200, %ring_rplace_ok_33 ], [ %t201, %ring_rplace_oob_34 ]
  %t203 = load i32, i32* %t202
  %t204 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t204, i32 %t203)
  store { [2 x i32], i64, i64 } zeroinitializer, { [2 x i32], i64, i64 }* %t205
  %t206 = getelementptr inbounds { [2 x i32], i64, i64 }, { [2 x i32], i64, i64 }* %t205, i32 0, i32 0
  %t207 = getelementptr inbounds { [2 x i32], i64, i64 }, { [2 x i32], i64, i64 }* %t205, i32 0, i32 1
  %t208 = load i64, i64* %t207
  %t209 = getelementptr inbounds { [2 x i32], i64, i64 }, { [2 x i32], i64, i64 }* %t205, i32 0, i32 2
  %t210 = load i64, i64* %t209
  %t211 = icmp eq i64 %t210, 0
  br i1 %t211, label %ring_pop_empty_36, label %ring_pop_nonempty_37
ring_pop_nonempty_37:
  %t212 = getelementptr inbounds [2 x i32], [2 x i32]* %t206, i32 0, i64 %t208
  %t213 = load i32, i32* %t212
  store i32 0, i32* %t212
  %t214 = add i64 %t208, 1
  %t215 = urem i64 %t214, 2
  store i64 %t215, i64* %t207
  %t216 = sub i64 %t210, 1
  store i64 %t216, i64* %t209
  br label %ring_pop_end_38
ring_pop_empty_36:
  br label %ring_pop_end_38
ring_pop_end_38:
  %t217 = phi i32 [ %t213, %ring_pop_nonempty_37 ], [ 0, %ring_pop_empty_36 ]
  %t218 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t218, i32 %t217)
  %t219 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t220 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t221 = load i64, i64* %t220
  %t222 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t223 = load i64, i64* %t222
  %t224 = sext i32 0 to i64
  %t225 = load i64, i64* %t220
  %t226 = load i64, i64* %t222
  %t227 = icmp ult i64 %t224, %t226
  br i1 %t227, label %ring_set_do_39, label %ring_set_oob_40
ring_set_do_39:
  %t228 = add i64 %t225, %t224
  %t229 = urem i64 %t228, 3
  %t230 = getelementptr inbounds [3 x i32], [3 x i32]* %t219, i32 0, i64 %t229
  store i32 100, i32* %t230
  br label %ring_set_end_41
ring_set_oob_40:
  br label %ring_set_end_41
ring_set_end_41:
  %t231 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t232 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t233 = load i64, i64* %t232
  %t234 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t235 = load i64, i64* %t234
  %t236 = sext i32 0 to i64
  %t237 = load i64, i64* %t232
  %t238 = load i64, i64* %t234
  %t239 = icmp ult i64 %t236, %t238
  br i1 %t239, label %ring_rplace_ok_42, label %ring_rplace_oob_43
ring_rplace_ok_42:
  %t240 = add i64 %t237, %t236
  %t241 = urem i64 %t240, 3
  %t242 = getelementptr inbounds [3 x i32], [3 x i32]* %t231, i32 0, i64 %t241
  br label %ring_rplace_end_44
ring_rplace_oob_43:
  store i32 0, i32* %t243
  br label %ring_rplace_end_44
ring_rplace_end_44:
  %t244 = phi i32* [ %t242, %ring_rplace_ok_42 ], [ %t243, %ring_rplace_oob_43 ]
  %t245 = load i32, i32* %t244
  %t246 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t246, i32 %t245)
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t247
  %t248 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t249 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t247, i32 0, i32 0
  %t250 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t247, i32 0, i32 1
  %t251 = load i64, i64* %t250
  %t252 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t247, i32 0, i32 2
  %t253 = load i64, i64* %t252
  %t254 = icmp sge i64 %t253, 2
  br i1 %t254, label %ring_push_full_45, label %ring_push_grow_46
ring_push_grow_46:
  %t255 = add i64 %t251, %t253
  %t256 = urem i64 %t255, 2
  %t257 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t249, i32 0, i64 %t256
  store i8* %t248, i8** %t257
  %t258 = add i64 %t253, 1
  store i64 %t258, i64* %t252
  br label %ring_push_done_47
ring_push_full_45:
  %t259 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t249, i32 0, i64 %t251
  %t260 = load i8*, i8** %t259
  call void @star_rc_release(i8* %t260)
  store i8* %t248, i8** %t259
  %t261 = add i64 %t251, 1
  %t262 = urem i64 %t261, 2
  store i64 %t262, i64* %t250
  br label %ring_push_done_47
ring_push_done_47:
  %t263 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t264 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t247, i32 0, i32 0
  %t265 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t247, i32 0, i32 1
  %t266 = load i64, i64* %t265
  %t267 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t247, i32 0, i32 2
  %t268 = load i64, i64* %t267
  %t269 = icmp sge i64 %t268, 2
  br i1 %t269, label %ring_push_full_48, label %ring_push_grow_49
ring_push_grow_49:
  %t270 = add i64 %t266, %t268
  %t271 = urem i64 %t270, 2
  %t272 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t264, i32 0, i64 %t271
  store i8* %t263, i8** %t272
  %t273 = add i64 %t268, 1
  store i64 %t273, i64* %t267
  br label %ring_push_done_50
ring_push_full_48:
  %t274 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t264, i32 0, i64 %t266
  %t275 = load i8*, i8** %t274
  call void @star_rc_release(i8* %t275)
  store i8* %t263, i8** %t274
  %t276 = add i64 %t266, 1
  %t277 = urem i64 %t276, 2
  store i64 %t277, i64* %t265
  br label %ring_push_done_50
ring_push_done_50:
  %t278 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.12, i64 0, i32 2, i64 0
  %t279 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t247, i32 0, i32 0
  %t280 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t247, i32 0, i32 1
  %t281 = load i64, i64* %t280
  %t282 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t247, i32 0, i32 2
  %t283 = load i64, i64* %t282
  %t284 = icmp sge i64 %t283, 2
  br i1 %t284, label %ring_push_full_51, label %ring_push_grow_52
ring_push_grow_52:
  %t285 = add i64 %t281, %t283
  %t286 = urem i64 %t285, 2
  %t287 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t279, i32 0, i64 %t286
  store i8* %t278, i8** %t287
  %t288 = add i64 %t283, 1
  store i64 %t288, i64* %t282
  br label %ring_push_done_53
ring_push_full_51:
  %t289 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t279, i32 0, i64 %t281
  %t290 = load i8*, i8** %t289
  call void @star_rc_release(i8* %t290)
  store i8* %t278, i8** %t289
  %t291 = add i64 %t281, 1
  %t292 = urem i64 %t291, 2
  store i64 %t292, i64* %t280
  br label %ring_push_done_53
ring_push_done_53:
  %t293 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t247, i32 0, i32 0
  %t294 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t247, i32 0, i32 1
  %t295 = load i64, i64* %t294
  %t296 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t247, i32 0, i32 2
  %t297 = load i64, i64* %t296
  %t298 = sext i32 0 to i64
  %t299 = load i64, i64* %t294
  %t300 = load i64, i64* %t296
  %t301 = icmp ult i64 %t298, %t300
  br i1 %t301, label %ring_rplace_ok_54, label %ring_rplace_oob_55
ring_rplace_ok_54:
  %t302 = add i64 %t299, %t298
  %t303 = urem i64 %t302, 2
  %t304 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t293, i32 0, i64 %t303
  br label %ring_rplace_end_56
ring_rplace_oob_55:
  store i8* null, i8** %t305
  br label %ring_rplace_end_56
ring_rplace_end_56:
  %t306 = phi i8** [ %t304, %ring_rplace_ok_54 ], [ %t305, %ring_rplace_oob_55 ]
  %t307 = load i8*, i8** %t306
  %t308 = load i8*, i8** %t306
  call void @star_rc_retain(i8* %t308)
  call void @star_rc_release(i8* %t307)
  %t309 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t247, i32 0, i32 0
  %t310 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t247, i32 0, i32 1
  %t311 = load i64, i64* %t310
  %t312 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t247, i32 0, i32 2
  %t313 = load i64, i64* %t312
  %t314 = sext i32 1 to i64
  %t315 = load i64, i64* %t310
  %t316 = load i64, i64* %t312
  %t317 = icmp ult i64 %t314, %t316
  br i1 %t317, label %ring_rplace_ok_57, label %ring_rplace_oob_58
ring_rplace_ok_57:
  %t318 = add i64 %t315, %t314
  %t319 = urem i64 %t318, 2
  %t320 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t309, i32 0, i64 %t319
  br label %ring_rplace_end_59
ring_rplace_oob_58:
  store i8* null, i8** %t321
  br label %ring_rplace_end_59
ring_rplace_end_59:
  %t322 = phi i8** [ %t320, %ring_rplace_ok_57 ], [ %t321, %ring_rplace_oob_58 ]
  %t323 = load i8*, i8** %t322
  %t324 = load i8*, i8** %t322
  call void @star_rc_retain(i8* %t324)
  call void @star_rc_release(i8* %t323)
  %t325 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t325, i8* %t307, i8* %t323)
  store { [2 x %Player], i64, i64 } zeroinitializer, { [2 x %Player], i64, i64 }* %t326
  %t328 = getelementptr inbounds %Player, %Player* %t327, i32 0, i32 0
  store i32 100, i32* %t328
  %t329 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t330 = getelementptr inbounds %Player, %Player* %t327, i32 0, i32 1
  store i8* %t329, i8** %t330
  %t331 = load %Player, %Player* %t327
  %t332 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t326, i32 0, i32 0
  %t333 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t326, i32 0, i32 1
  %t334 = load i64, i64* %t333
  %t335 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t326, i32 0, i32 2
  %t336 = load i64, i64* %t335
  %t337 = icmp sge i64 %t336, 2
  br i1 %t337, label %ring_push_full_60, label %ring_push_grow_61
ring_push_grow_61:
  %t338 = add i64 %t334, %t336
  %t339 = urem i64 %t338, 2
  %t340 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t332, i32 0, i64 %t339
  store %Player %t331, %Player* %t340
  %t341 = add i64 %t336, 1
  store i64 %t341, i64* %t335
  br label %ring_push_done_62
ring_push_full_60:
  %t342 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t332, i32 0, i64 %t334
  %t343 = getelementptr inbounds %Player, %Player* %t342, i32 0, i32 1
  %t344 = load i8*, i8** %t343
  call void @star_rc_release(i8* %t344)
  store %Player %t331, %Player* %t342
  %t345 = add i64 %t334, 1
  %t346 = urem i64 %t345, 2
  store i64 %t346, i64* %t333
  br label %ring_push_done_62
ring_push_done_62:
  %t348 = getelementptr inbounds %Player, %Player* %t347, i32 0, i32 0
  store i32 80, i32* %t348
  %t349 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t350 = getelementptr inbounds %Player, %Player* %t347, i32 0, i32 1
  store i8* %t349, i8** %t350
  %t351 = load %Player, %Player* %t347
  %t352 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t326, i32 0, i32 0
  %t353 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t326, i32 0, i32 1
  %t354 = load i64, i64* %t353
  %t355 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t326, i32 0, i32 2
  %t356 = load i64, i64* %t355
  %t357 = icmp sge i64 %t356, 2
  br i1 %t357, label %ring_push_full_63, label %ring_push_grow_64
ring_push_grow_64:
  %t358 = add i64 %t354, %t356
  %t359 = urem i64 %t358, 2
  %t360 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t352, i32 0, i64 %t359
  store %Player %t351, %Player* %t360
  %t361 = add i64 %t356, 1
  store i64 %t361, i64* %t355
  br label %ring_push_done_65
ring_push_full_63:
  %t362 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t352, i32 0, i64 %t354
  %t363 = getelementptr inbounds %Player, %Player* %t362, i32 0, i32 1
  %t364 = load i8*, i8** %t363
  call void @star_rc_release(i8* %t364)
  store %Player %t351, %Player* %t362
  %t365 = add i64 %t354, 1
  %t366 = urem i64 %t365, 2
  store i64 %t366, i64* %t353
  br label %ring_push_done_65
ring_push_done_65:
  %t367 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t326, i32 0, i32 0
  %t368 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t326, i32 0, i32 1
  %t369 = load i64, i64* %t368
  %t370 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t326, i32 0, i32 2
  %t371 = load i64, i64* %t370
  %t372 = sext i32 0 to i64
  %t373 = load i64, i64* %t368
  %t374 = load i64, i64* %t370
  %t375 = icmp ult i64 %t372, %t374
  br i1 %t375, label %ring_rplace_ok_66, label %ring_rplace_oob_67
ring_rplace_ok_66:
  %t376 = add i64 %t373, %t372
  %t377 = urem i64 %t376, 2
  %t378 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t367, i32 0, i64 %t377
  br label %ring_rplace_end_68
ring_rplace_oob_67:
  store %Player zeroinitializer, %Player* %t379
  br label %ring_rplace_end_68
ring_rplace_end_68:
  %t380 = phi %Player* [ %t378, %ring_rplace_ok_66 ], [ %t379, %ring_rplace_oob_67 ]
  %t381 = getelementptr inbounds %Player, %Player* %t380, i32 0, i32 1
  %t382 = load i8*, i8** %t381
  %t383 = load i8*, i8** %t381
  call void @star_rc_retain(i8* %t383)
  call void @star_rc_release(i8* %t382)
  %t384 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t326, i32 0, i32 0
  %t385 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t326, i32 0, i32 1
  %t386 = load i64, i64* %t385
  %t387 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t326, i32 0, i32 2
  %t388 = load i64, i64* %t387
  %t389 = sext i32 0 to i64
  %t390 = load i64, i64* %t385
  %t391 = load i64, i64* %t387
  %t392 = icmp ult i64 %t389, %t391
  br i1 %t392, label %ring_rplace_ok_69, label %ring_rplace_oob_70
ring_rplace_ok_69:
  %t393 = add i64 %t390, %t389
  %t394 = urem i64 %t393, 2
  %t395 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t384, i32 0, i64 %t394
  br label %ring_rplace_end_71
ring_rplace_oob_70:
  store %Player zeroinitializer, %Player* %t396
  br label %ring_rplace_end_71
ring_rplace_end_71:
  %t397 = phi %Player* [ %t395, %ring_rplace_ok_69 ], [ %t396, %ring_rplace_oob_70 ]
  %t398 = getelementptr inbounds %Player, %Player* %t397, i32 0, i32 0
  %t399 = load i32, i32* %t398
  %t400 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t400, i8* %t382, i32 %t399)
  %t401 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t326, i32 0, i32 0
  %t402 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t401, i32 0, i64 0
  %t403 = getelementptr inbounds %Player, %Player* %t402, i32 0, i32 1
  %t404 = load i8*, i8** %t403
  call void @star_rc_release(i8* %t404)
  %t405 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t401, i32 0, i64 1
  %t406 = getelementptr inbounds %Player, %Player* %t405, i32 0, i32 1
  %t407 = load i8*, i8** %t406
  call void @star_rc_release(i8* %t407)
  %t408 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t247, i32 0, i32 0
  %t409 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t408, i32 0, i64 0
  %t410 = load i8*, i8** %t409
  call void @star_rc_release(i8* %t410)
  %t411 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t408, i32 0, i64 1
  %t412 = load i8*, i8** %t411
  call void @star_rc_release(i8* %t412)
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
