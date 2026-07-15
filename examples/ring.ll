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

%Player = type { i32, i8* }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t0 = alloca { [3 x i32], i64, i64 }
  %t66 = alloca i32
  %t81 = alloca i32
  %t96 = alloca i32
  %t132 = alloca i32
  %t147 = alloca i32
  %t162 = alloca i32
  %t166 = alloca i32
  %t200 = alloca i32
  %t204 = alloca { [2 x i32], i64, i64 }
  %t230 = alloca i32
  %t244 = alloca i32
  %t248 = alloca { [2 x i8*], i64, i64 }
  %t306 = alloca i8*
  %t322 = alloca i8*
  %t327 = alloca { [2 x %Player], i64, i64 }
  %t328 = alloca %Player
  %t348 = alloca %Player
  %t380 = alloca %Player
  %t397 = alloca %Player
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  store { [3 x i32], i64, i64 } zeroinitializer, { [3 x i32], i64, i64 }* %t0
  %t1 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t2 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t3 = load i64, i64* %t2
  %t4 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t5 = load i64, i64* %t4
  %t6 = trunc i64 %t5 to i32
  %t7 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t7, i32 %t6)
  %t8 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t9 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t10 = load i64, i64* %t9
  %t11 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t12 = load i64, i64* %t11
  %t13 = icmp sge i64 %t12, 3
  br i1 %t13, label %ring_push_full_0, label %ring_push_grow_1
ring_push_grow_1:
  %t14 = add i64 %t10, %t12
  %t15 = urem i64 %t14, 3
  %t16 = getelementptr inbounds [3 x i32], [3 x i32]* %t8, i32 0, i64 %t15
  store i32 1, i32* %t16
  %t17 = add i64 %t12, 1
  store i64 %t17, i64* %t11
  br label %ring_push_done_2
ring_push_full_0:
  %t18 = getelementptr inbounds [3 x i32], [3 x i32]* %t8, i32 0, i64 %t10
  store i32 1, i32* %t18
  %t19 = add i64 %t10, 1
  %t20 = urem i64 %t19, 3
  store i64 %t20, i64* %t9
  br label %ring_push_done_2
ring_push_done_2:
  %t21 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t22 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t23 = load i64, i64* %t22
  %t24 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t25 = load i64, i64* %t24
  %t26 = icmp sge i64 %t25, 3
  br i1 %t26, label %ring_push_full_3, label %ring_push_grow_4
ring_push_grow_4:
  %t27 = add i64 %t23, %t25
  %t28 = urem i64 %t27, 3
  %t29 = getelementptr inbounds [3 x i32], [3 x i32]* %t21, i32 0, i64 %t28
  store i32 2, i32* %t29
  %t30 = add i64 %t25, 1
  store i64 %t30, i64* %t24
  br label %ring_push_done_5
ring_push_full_3:
  %t31 = getelementptr inbounds [3 x i32], [3 x i32]* %t21, i32 0, i64 %t23
  store i32 2, i32* %t31
  %t32 = add i64 %t23, 1
  %t33 = urem i64 %t32, 3
  store i64 %t33, i64* %t22
  br label %ring_push_done_5
ring_push_done_5:
  %t34 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t35 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t36 = load i64, i64* %t35
  %t37 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t38 = load i64, i64* %t37
  %t39 = icmp sge i64 %t38, 3
  br i1 %t39, label %ring_push_full_6, label %ring_push_grow_7
ring_push_grow_7:
  %t40 = add i64 %t36, %t38
  %t41 = urem i64 %t40, 3
  %t42 = getelementptr inbounds [3 x i32], [3 x i32]* %t34, i32 0, i64 %t41
  store i32 3, i32* %t42
  %t43 = add i64 %t38, 1
  store i64 %t43, i64* %t37
  br label %ring_push_done_8
ring_push_full_6:
  %t44 = getelementptr inbounds [3 x i32], [3 x i32]* %t34, i32 0, i64 %t36
  store i32 3, i32* %t44
  %t45 = add i64 %t36, 1
  %t46 = urem i64 %t45, 3
  store i64 %t46, i64* %t35
  br label %ring_push_done_8
ring_push_done_8:
  %t47 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t48 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t49 = load i64, i64* %t48
  %t50 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t51 = load i64, i64* %t50
  %t52 = trunc i64 %t51 to i32
  %t53 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t53, i32 %t52)
  %t54 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t55 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t56 = load i64, i64* %t55
  %t57 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t58 = load i64, i64* %t57
  %t59 = sext i32 0 to i64
  %t60 = load i64, i64* %t55
  %t61 = load i64, i64* %t57
  %t62 = icmp ult i64 %t59, %t61
  br i1 %t62, label %ring_rplace_ok_9, label %ring_rplace_oob_10
ring_rplace_ok_9:
  %t63 = add i64 %t60, %t59
  %t64 = urem i64 %t63, 3
  %t65 = getelementptr inbounds [3 x i32], [3 x i32]* %t54, i32 0, i64 %t64
  br label %ring_rplace_end_11
ring_rplace_oob_10:
  store i32 0, i32* %t66
  br label %ring_rplace_end_11
ring_rplace_end_11:
  %t67 = phi i32* [ %t65, %ring_rplace_ok_9 ], [ %t66, %ring_rplace_oob_10 ]
  %t68 = load i32, i32* %t67
  %t69 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t70 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t71 = load i64, i64* %t70
  %t72 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t73 = load i64, i64* %t72
  %t74 = sext i32 1 to i64
  %t75 = load i64, i64* %t70
  %t76 = load i64, i64* %t72
  %t77 = icmp ult i64 %t74, %t76
  br i1 %t77, label %ring_rplace_ok_12, label %ring_rplace_oob_13
ring_rplace_ok_12:
  %t78 = add i64 %t75, %t74
  %t79 = urem i64 %t78, 3
  %t80 = getelementptr inbounds [3 x i32], [3 x i32]* %t69, i32 0, i64 %t79
  br label %ring_rplace_end_14
ring_rplace_oob_13:
  store i32 0, i32* %t81
  br label %ring_rplace_end_14
ring_rplace_end_14:
  %t82 = phi i32* [ %t80, %ring_rplace_ok_12 ], [ %t81, %ring_rplace_oob_13 ]
  %t83 = load i32, i32* %t82
  %t84 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t85 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t86 = load i64, i64* %t85
  %t87 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t88 = load i64, i64* %t87
  %t89 = sext i32 2 to i64
  %t90 = load i64, i64* %t85
  %t91 = load i64, i64* %t87
  %t92 = icmp ult i64 %t89, %t91
  br i1 %t92, label %ring_rplace_ok_15, label %ring_rplace_oob_16
ring_rplace_ok_15:
  %t93 = add i64 %t90, %t89
  %t94 = urem i64 %t93, 3
  %t95 = getelementptr inbounds [3 x i32], [3 x i32]* %t84, i32 0, i64 %t94
  br label %ring_rplace_end_17
ring_rplace_oob_16:
  store i32 0, i32* %t96
  br label %ring_rplace_end_17
ring_rplace_end_17:
  %t97 = phi i32* [ %t95, %ring_rplace_ok_15 ], [ %t96, %ring_rplace_oob_16 ]
  %t98 = load i32, i32* %t97
  %t99 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t99, i32 %t68, i32 %t83, i32 %t98)
  %t100 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t101 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t102 = load i64, i64* %t101
  %t103 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t104 = load i64, i64* %t103
  %t105 = icmp sge i64 %t104, 3
  br i1 %t105, label %ring_push_full_18, label %ring_push_grow_19
ring_push_grow_19:
  %t106 = add i64 %t102, %t104
  %t107 = urem i64 %t106, 3
  %t108 = getelementptr inbounds [3 x i32], [3 x i32]* %t100, i32 0, i64 %t107
  store i32 4, i32* %t108
  %t109 = add i64 %t104, 1
  store i64 %t109, i64* %t103
  br label %ring_push_done_20
ring_push_full_18:
  %t110 = getelementptr inbounds [3 x i32], [3 x i32]* %t100, i32 0, i64 %t102
  store i32 4, i32* %t110
  %t111 = add i64 %t102, 1
  %t112 = urem i64 %t111, 3
  store i64 %t112, i64* %t101
  br label %ring_push_done_20
ring_push_done_20:
  %t113 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t114 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t115 = load i64, i64* %t114
  %t116 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t117 = load i64, i64* %t116
  %t118 = trunc i64 %t117 to i32
  %t119 = getelementptr inbounds [35 x i8], [35 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t119, i32 %t118)
  %t120 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t121 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t122 = load i64, i64* %t121
  %t123 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t124 = load i64, i64* %t123
  %t125 = sext i32 0 to i64
  %t126 = load i64, i64* %t121
  %t127 = load i64, i64* %t123
  %t128 = icmp ult i64 %t125, %t127
  br i1 %t128, label %ring_rplace_ok_21, label %ring_rplace_oob_22
ring_rplace_ok_21:
  %t129 = add i64 %t126, %t125
  %t130 = urem i64 %t129, 3
  %t131 = getelementptr inbounds [3 x i32], [3 x i32]* %t120, i32 0, i64 %t130
  br label %ring_rplace_end_23
ring_rplace_oob_22:
  store i32 0, i32* %t132
  br label %ring_rplace_end_23
ring_rplace_end_23:
  %t133 = phi i32* [ %t131, %ring_rplace_ok_21 ], [ %t132, %ring_rplace_oob_22 ]
  %t134 = load i32, i32* %t133
  %t135 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t136 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t137 = load i64, i64* %t136
  %t138 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t139 = load i64, i64* %t138
  %t140 = sext i32 1 to i64
  %t141 = load i64, i64* %t136
  %t142 = load i64, i64* %t138
  %t143 = icmp ult i64 %t140, %t142
  br i1 %t143, label %ring_rplace_ok_24, label %ring_rplace_oob_25
ring_rplace_ok_24:
  %t144 = add i64 %t141, %t140
  %t145 = urem i64 %t144, 3
  %t146 = getelementptr inbounds [3 x i32], [3 x i32]* %t135, i32 0, i64 %t145
  br label %ring_rplace_end_26
ring_rplace_oob_25:
  store i32 0, i32* %t147
  br label %ring_rplace_end_26
ring_rplace_end_26:
  %t148 = phi i32* [ %t146, %ring_rplace_ok_24 ], [ %t147, %ring_rplace_oob_25 ]
  %t149 = load i32, i32* %t148
  %t150 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t151 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t152 = load i64, i64* %t151
  %t153 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t154 = load i64, i64* %t153
  %t155 = sext i32 2 to i64
  %t156 = load i64, i64* %t151
  %t157 = load i64, i64* %t153
  %t158 = icmp ult i64 %t155, %t157
  br i1 %t158, label %ring_rplace_ok_27, label %ring_rplace_oob_28
ring_rplace_ok_27:
  %t159 = add i64 %t156, %t155
  %t160 = urem i64 %t159, 3
  %t161 = getelementptr inbounds [3 x i32], [3 x i32]* %t150, i32 0, i64 %t160
  br label %ring_rplace_end_29
ring_rplace_oob_28:
  store i32 0, i32* %t162
  br label %ring_rplace_end_29
ring_rplace_end_29:
  %t163 = phi i32* [ %t161, %ring_rplace_ok_27 ], [ %t162, %ring_rplace_oob_28 ]
  %t164 = load i32, i32* %t163
  %t165 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t165, i32 %t134, i32 %t149, i32 %t164)
  %t167 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t168 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t169 = load i64, i64* %t168
  %t170 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t171 = load i64, i64* %t170
  %t172 = icmp eq i64 %t171, 0
  br i1 %t172, label %ring_pop_empty_30, label %ring_pop_nonempty_31
ring_pop_nonempty_31:
  %t173 = getelementptr inbounds [3 x i32], [3 x i32]* %t167, i32 0, i64 %t169
  %t174 = load i32, i32* %t173
  store i32 0, i32* %t173
  %t175 = add i64 %t169, 1
  %t176 = urem i64 %t175, 3
  store i64 %t176, i64* %t168
  %t177 = sub i64 %t171, 1
  store i64 %t177, i64* %t170
  br label %ring_pop_end_32
ring_pop_empty_30:
  br label %ring_pop_end_32
ring_pop_end_32:
  %t178 = phi i32 [ %t174, %ring_pop_nonempty_31 ], [ 0, %ring_pop_empty_30 ]
  store i32 %t178, i32* %t166
  %t179 = load i32, i32* %t166
  %t180 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t180, i32 %t179)
  %t181 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t182 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t183 = load i64, i64* %t182
  %t184 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t185 = load i64, i64* %t184
  %t186 = trunc i64 %t185 to i32
  %t187 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t187, i32 %t186)
  %t188 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t189 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t190 = load i64, i64* %t189
  %t191 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t192 = load i64, i64* %t191
  %t193 = sext i32 99 to i64
  %t194 = load i64, i64* %t189
  %t195 = load i64, i64* %t191
  %t196 = icmp ult i64 %t193, %t195
  br i1 %t196, label %ring_rplace_ok_33, label %ring_rplace_oob_34
ring_rplace_ok_33:
  %t197 = add i64 %t194, %t193
  %t198 = urem i64 %t197, 3
  %t199 = getelementptr inbounds [3 x i32], [3 x i32]* %t188, i32 0, i64 %t198
  br label %ring_rplace_end_35
ring_rplace_oob_34:
  store i32 0, i32* %t200
  br label %ring_rplace_end_35
ring_rplace_end_35:
  %t201 = phi i32* [ %t199, %ring_rplace_ok_33 ], [ %t200, %ring_rplace_oob_34 ]
  %t202 = load i32, i32* %t201
  %t203 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t203, i32 %t202)
  store { [2 x i32], i64, i64 } zeroinitializer, { [2 x i32], i64, i64 }* %t204
  %t205 = getelementptr inbounds { [2 x i32], i64, i64 }, { [2 x i32], i64, i64 }* %t204, i32 0, i32 0
  %t206 = getelementptr inbounds { [2 x i32], i64, i64 }, { [2 x i32], i64, i64 }* %t204, i32 0, i32 1
  %t207 = load i64, i64* %t206
  %t208 = getelementptr inbounds { [2 x i32], i64, i64 }, { [2 x i32], i64, i64 }* %t204, i32 0, i32 2
  %t209 = load i64, i64* %t208
  %t210 = icmp eq i64 %t209, 0
  br i1 %t210, label %ring_pop_empty_36, label %ring_pop_nonempty_37
ring_pop_nonempty_37:
  %t211 = getelementptr inbounds [2 x i32], [2 x i32]* %t205, i32 0, i64 %t207
  %t212 = load i32, i32* %t211
  store i32 0, i32* %t211
  %t213 = add i64 %t207, 1
  %t214 = urem i64 %t213, 2
  store i64 %t214, i64* %t206
  %t215 = sub i64 %t209, 1
  store i64 %t215, i64* %t208
  br label %ring_pop_end_38
ring_pop_empty_36:
  br label %ring_pop_end_38
ring_pop_end_38:
  %t216 = phi i32 [ %t212, %ring_pop_nonempty_37 ], [ 0, %ring_pop_empty_36 ]
  %t217 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t217, i32 %t216)
  %t218 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t219 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t220 = load i64, i64* %t219
  %t221 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t222 = load i64, i64* %t221
  %t223 = sext i32 0 to i64
  %t224 = load i64, i64* %t219
  %t225 = load i64, i64* %t221
  %t226 = icmp ult i64 %t223, %t225
  br i1 %t226, label %ring_place_ok_39, label %ring_place_oob_40
ring_place_ok_39:
  %t227 = add i64 %t224, %t223
  %t228 = urem i64 %t227, 3
  %t229 = getelementptr inbounds [3 x i32], [3 x i32]* %t218, i32 0, i64 %t228
  br label %ring_place_end_41
ring_place_oob_40:
  store i32 0, i32* %t230
  br label %ring_place_end_41
ring_place_end_41:
  %t231 = phi i32* [ %t229, %ring_place_ok_39 ], [ %t230, %ring_place_oob_40 ]
  store i32 100, i32* %t231
  %t232 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t233 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t234 = load i64, i64* %t233
  %t235 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
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
  store i8* null, i8** %t306
  br label %ring_rplace_end_56
ring_rplace_end_56:
  %t307 = phi i8** [ %t305, %ring_rplace_ok_54 ], [ %t306, %ring_rplace_oob_55 ]
  %t308 = load i8*, i8** %t307
  %t309 = load i8*, i8** %t307
  call void @star_rc_retain(i8* %t309)
  %t310 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 0
  %t311 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 1
  %t312 = load i64, i64* %t311
  %t313 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 2
  %t314 = load i64, i64* %t313
  %t315 = sext i32 1 to i64
  %t316 = load i64, i64* %t311
  %t317 = load i64, i64* %t313
  %t318 = icmp ult i64 %t315, %t317
  br i1 %t318, label %ring_rplace_ok_57, label %ring_rplace_oob_58
ring_rplace_ok_57:
  %t319 = add i64 %t316, %t315
  %t320 = urem i64 %t319, 2
  %t321 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t310, i32 0, i64 %t320
  br label %ring_rplace_end_59
ring_rplace_oob_58:
  store i8* null, i8** %t322
  br label %ring_rplace_end_59
ring_rplace_end_59:
  %t323 = phi i8** [ %t321, %ring_rplace_ok_57 ], [ %t322, %ring_rplace_oob_58 ]
  %t324 = load i8*, i8** %t323
  %t325 = load i8*, i8** %t323
  call void @star_rc_retain(i8* %t325)
  %t326 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t326, i8* %t308, i8* %t324)
  store { [2 x %Player], i64, i64 } zeroinitializer, { [2 x %Player], i64, i64 }* %t327
  %t329 = getelementptr inbounds %Player, %Player* %t328, i32 0, i32 0
  store i32 100, i32* %t329
  %t330 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t331 = getelementptr inbounds %Player, %Player* %t328, i32 0, i32 1
  store i8* %t330, i8** %t331
  %t332 = load %Player, %Player* %t328
  %t333 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t327, i32 0, i32 0
  %t334 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t327, i32 0, i32 1
  %t335 = load i64, i64* %t334
  %t336 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t327, i32 0, i32 2
  %t337 = load i64, i64* %t336
  %t338 = icmp sge i64 %t337, 2
  br i1 %t338, label %ring_push_full_60, label %ring_push_grow_61
ring_push_grow_61:
  %t339 = add i64 %t335, %t337
  %t340 = urem i64 %t339, 2
  %t341 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t333, i32 0, i64 %t340
  store %Player %t332, %Player* %t341
  %t342 = add i64 %t337, 1
  store i64 %t342, i64* %t336
  br label %ring_push_done_62
ring_push_full_60:
  %t343 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t333, i32 0, i64 %t335
  %t344 = getelementptr inbounds %Player, %Player* %t343, i32 0, i32 1
  %t345 = load i8*, i8** %t344
  call void @star_rc_release(i8* %t345)
  store %Player %t332, %Player* %t343
  %t346 = add i64 %t335, 1
  %t347 = urem i64 %t346, 2
  store i64 %t347, i64* %t334
  br label %ring_push_done_62
ring_push_done_62:
  %t349 = getelementptr inbounds %Player, %Player* %t348, i32 0, i32 0
  store i32 80, i32* %t349
  %t350 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t351 = getelementptr inbounds %Player, %Player* %t348, i32 0, i32 1
  store i8* %t350, i8** %t351
  %t352 = load %Player, %Player* %t348
  %t353 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t327, i32 0, i32 0
  %t354 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t327, i32 0, i32 1
  %t355 = load i64, i64* %t354
  %t356 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t327, i32 0, i32 2
  %t357 = load i64, i64* %t356
  %t358 = icmp sge i64 %t357, 2
  br i1 %t358, label %ring_push_full_63, label %ring_push_grow_64
ring_push_grow_64:
  %t359 = add i64 %t355, %t357
  %t360 = urem i64 %t359, 2
  %t361 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t353, i32 0, i64 %t360
  store %Player %t352, %Player* %t361
  %t362 = add i64 %t357, 1
  store i64 %t362, i64* %t356
  br label %ring_push_done_65
ring_push_full_63:
  %t363 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t353, i32 0, i64 %t355
  %t364 = getelementptr inbounds %Player, %Player* %t363, i32 0, i32 1
  %t365 = load i8*, i8** %t364
  call void @star_rc_release(i8* %t365)
  store %Player %t352, %Player* %t363
  %t366 = add i64 %t355, 1
  %t367 = urem i64 %t366, 2
  store i64 %t367, i64* %t354
  br label %ring_push_done_65
ring_push_done_65:
  %t368 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t327, i32 0, i32 0
  %t369 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t327, i32 0, i32 1
  %t370 = load i64, i64* %t369
  %t371 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t327, i32 0, i32 2
  %t372 = load i64, i64* %t371
  %t373 = sext i32 0 to i64
  %t374 = load i64, i64* %t369
  %t375 = load i64, i64* %t371
  %t376 = icmp ult i64 %t373, %t375
  br i1 %t376, label %ring_rplace_ok_66, label %ring_rplace_oob_67
ring_rplace_ok_66:
  %t377 = add i64 %t374, %t373
  %t378 = urem i64 %t377, 2
  %t379 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t368, i32 0, i64 %t378
  br label %ring_rplace_end_68
ring_rplace_oob_67:
  store %Player zeroinitializer, %Player* %t380
  br label %ring_rplace_end_68
ring_rplace_end_68:
  %t381 = phi %Player* [ %t379, %ring_rplace_ok_66 ], [ %t380, %ring_rplace_oob_67 ]
  %t382 = getelementptr inbounds %Player, %Player* %t381, i32 0, i32 1
  %t383 = load i8*, i8** %t382
  %t384 = load i8*, i8** %t382
  call void @star_rc_retain(i8* %t384)
  call void @star_rc_release(i8* %t383)
  %t385 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t327, i32 0, i32 0
  %t386 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t327, i32 0, i32 1
  %t387 = load i64, i64* %t386
  %t388 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t327, i32 0, i32 2
  %t389 = load i64, i64* %t388
  %t390 = sext i32 0 to i64
  %t391 = load i64, i64* %t386
  %t392 = load i64, i64* %t388
  %t393 = icmp ult i64 %t390, %t392
  br i1 %t393, label %ring_rplace_ok_69, label %ring_rplace_oob_70
ring_rplace_ok_69:
  %t394 = add i64 %t391, %t390
  %t395 = urem i64 %t394, 2
  %t396 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t385, i32 0, i64 %t395
  br label %ring_rplace_end_71
ring_rplace_oob_70:
  store %Player zeroinitializer, %Player* %t397
  br label %ring_rplace_end_71
ring_rplace_end_71:
  %t398 = phi %Player* [ %t396, %ring_rplace_ok_69 ], [ %t397, %ring_rplace_oob_70 ]
  %t399 = getelementptr inbounds %Player, %Player* %t398, i32 0, i32 0
  %t400 = load i32, i32* %t399
  %t401 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t401, i8* %t383, i32 %t400)
  %t402 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t327, i32 0, i32 0
  %t403 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t402, i32 0, i64 0
  %t404 = getelementptr inbounds %Player, %Player* %t403, i32 0, i32 1
  %t405 = load i8*, i8** %t404
  call void @star_rc_release(i8* %t405)
  %t406 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t402, i32 0, i64 1
  %t407 = getelementptr inbounds %Player, %Player* %t406, i32 0, i32 1
  %t408 = load i8*, i8** %t407
  call void @star_rc_release(i8* %t408)
  %t409 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 0
  %t410 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t409, i32 0, i64 0
  %t411 = load i8*, i8** %t410
  call void @star_rc_release(i8* %t411)
  %t412 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t409, i32 0, i64 1
  %t413 = load i8*, i8** %t412
  call void @star_rc_release(i8* %t413)
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
