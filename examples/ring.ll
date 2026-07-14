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
declare i32 @_putenv(i8*)
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
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = alloca { [3 x i32], i64, i64 }
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
  %t60 = icmp ult i64 %t59, %t58
  br i1 %t60, label %ring_rplace_ok_9, label %ring_rplace_oob_10
ring_rplace_ok_9:
  %t61 = add i64 %t56, %t59
  %t62 = urem i64 %t61, 3
  %t63 = getelementptr inbounds [3 x i32], [3 x i32]* %t54, i32 0, i64 %t62
  br label %ring_rplace_end_11
ring_rplace_oob_10:
  %t64 = alloca i32
  store i32 0, i32* %t64
  br label %ring_rplace_end_11
ring_rplace_end_11:
  %t65 = phi i32* [ %t63, %ring_rplace_ok_9 ], [ %t64, %ring_rplace_oob_10 ]
  %t66 = load i32, i32* %t65
  %t67 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t68 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t69 = load i64, i64* %t68
  %t70 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t71 = load i64, i64* %t70
  %t72 = sext i32 1 to i64
  %t73 = icmp ult i64 %t72, %t71
  br i1 %t73, label %ring_rplace_ok_12, label %ring_rplace_oob_13
ring_rplace_ok_12:
  %t74 = add i64 %t69, %t72
  %t75 = urem i64 %t74, 3
  %t76 = getelementptr inbounds [3 x i32], [3 x i32]* %t67, i32 0, i64 %t75
  br label %ring_rplace_end_14
ring_rplace_oob_13:
  %t77 = alloca i32
  store i32 0, i32* %t77
  br label %ring_rplace_end_14
ring_rplace_end_14:
  %t78 = phi i32* [ %t76, %ring_rplace_ok_12 ], [ %t77, %ring_rplace_oob_13 ]
  %t79 = load i32, i32* %t78
  %t80 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t81 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t82 = load i64, i64* %t81
  %t83 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t84 = load i64, i64* %t83
  %t85 = sext i32 2 to i64
  %t86 = icmp ult i64 %t85, %t84
  br i1 %t86, label %ring_rplace_ok_15, label %ring_rplace_oob_16
ring_rplace_ok_15:
  %t87 = add i64 %t82, %t85
  %t88 = urem i64 %t87, 3
  %t89 = getelementptr inbounds [3 x i32], [3 x i32]* %t80, i32 0, i64 %t88
  br label %ring_rplace_end_17
ring_rplace_oob_16:
  %t90 = alloca i32
  store i32 0, i32* %t90
  br label %ring_rplace_end_17
ring_rplace_end_17:
  %t91 = phi i32* [ %t89, %ring_rplace_ok_15 ], [ %t90, %ring_rplace_oob_16 ]
  %t92 = load i32, i32* %t91
  %t93 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t93, i32 %t66, i32 %t79, i32 %t92)
  %t94 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t95 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t96 = load i64, i64* %t95
  %t97 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t98 = load i64, i64* %t97
  %t99 = icmp sge i64 %t98, 3
  br i1 %t99, label %ring_push_full_18, label %ring_push_grow_19
ring_push_grow_19:
  %t100 = add i64 %t96, %t98
  %t101 = urem i64 %t100, 3
  %t102 = getelementptr inbounds [3 x i32], [3 x i32]* %t94, i32 0, i64 %t101
  store i32 4, i32* %t102
  %t103 = add i64 %t98, 1
  store i64 %t103, i64* %t97
  br label %ring_push_done_20
ring_push_full_18:
  %t104 = getelementptr inbounds [3 x i32], [3 x i32]* %t94, i32 0, i64 %t96
  store i32 4, i32* %t104
  %t105 = add i64 %t96, 1
  %t106 = urem i64 %t105, 3
  store i64 %t106, i64* %t95
  br label %ring_push_done_20
ring_push_done_20:
  %t107 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t108 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t109 = load i64, i64* %t108
  %t110 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t111 = load i64, i64* %t110
  %t112 = trunc i64 %t111 to i32
  %t113 = getelementptr inbounds [35 x i8], [35 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t113, i32 %t112)
  %t114 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t115 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t116 = load i64, i64* %t115
  %t117 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t118 = load i64, i64* %t117
  %t119 = sext i32 0 to i64
  %t120 = icmp ult i64 %t119, %t118
  br i1 %t120, label %ring_rplace_ok_21, label %ring_rplace_oob_22
ring_rplace_ok_21:
  %t121 = add i64 %t116, %t119
  %t122 = urem i64 %t121, 3
  %t123 = getelementptr inbounds [3 x i32], [3 x i32]* %t114, i32 0, i64 %t122
  br label %ring_rplace_end_23
ring_rplace_oob_22:
  %t124 = alloca i32
  store i32 0, i32* %t124
  br label %ring_rplace_end_23
ring_rplace_end_23:
  %t125 = phi i32* [ %t123, %ring_rplace_ok_21 ], [ %t124, %ring_rplace_oob_22 ]
  %t126 = load i32, i32* %t125
  %t127 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t128 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t129 = load i64, i64* %t128
  %t130 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t131 = load i64, i64* %t130
  %t132 = sext i32 1 to i64
  %t133 = icmp ult i64 %t132, %t131
  br i1 %t133, label %ring_rplace_ok_24, label %ring_rplace_oob_25
ring_rplace_ok_24:
  %t134 = add i64 %t129, %t132
  %t135 = urem i64 %t134, 3
  %t136 = getelementptr inbounds [3 x i32], [3 x i32]* %t127, i32 0, i64 %t135
  br label %ring_rplace_end_26
ring_rplace_oob_25:
  %t137 = alloca i32
  store i32 0, i32* %t137
  br label %ring_rplace_end_26
ring_rplace_end_26:
  %t138 = phi i32* [ %t136, %ring_rplace_ok_24 ], [ %t137, %ring_rplace_oob_25 ]
  %t139 = load i32, i32* %t138
  %t140 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t141 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t142 = load i64, i64* %t141
  %t143 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t144 = load i64, i64* %t143
  %t145 = sext i32 2 to i64
  %t146 = icmp ult i64 %t145, %t144
  br i1 %t146, label %ring_rplace_ok_27, label %ring_rplace_oob_28
ring_rplace_ok_27:
  %t147 = add i64 %t142, %t145
  %t148 = urem i64 %t147, 3
  %t149 = getelementptr inbounds [3 x i32], [3 x i32]* %t140, i32 0, i64 %t148
  br label %ring_rplace_end_29
ring_rplace_oob_28:
  %t150 = alloca i32
  store i32 0, i32* %t150
  br label %ring_rplace_end_29
ring_rplace_end_29:
  %t151 = phi i32* [ %t149, %ring_rplace_ok_27 ], [ %t150, %ring_rplace_oob_28 ]
  %t152 = load i32, i32* %t151
  %t153 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t153, i32 %t126, i32 %t139, i32 %t152)
  %t154 = alloca i32
  %t155 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t156 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t157 = load i64, i64* %t156
  %t158 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t159 = load i64, i64* %t158
  %t160 = icmp eq i64 %t159, 0
  br i1 %t160, label %ring_pop_empty_30, label %ring_pop_nonempty_31
ring_pop_nonempty_31:
  %t161 = getelementptr inbounds [3 x i32], [3 x i32]* %t155, i32 0, i64 %t157
  %t162 = load i32, i32* %t161
  store i32 0, i32* %t161
  %t163 = add i64 %t157, 1
  %t164 = urem i64 %t163, 3
  store i64 %t164, i64* %t156
  %t165 = sub i64 %t159, 1
  store i64 %t165, i64* %t158
  br label %ring_pop_end_32
ring_pop_empty_30:
  br label %ring_pop_end_32
ring_pop_end_32:
  %t166 = phi i32 [ %t162, %ring_pop_nonempty_31 ], [ 0, %ring_pop_empty_30 ]
  store i32 %t166, i32* %t154
  %t167 = load i32, i32* %t154
  %t168 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t168, i32 %t167)
  %t169 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t170 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t171 = load i64, i64* %t170
  %t172 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t173 = load i64, i64* %t172
  %t174 = trunc i64 %t173 to i32
  %t175 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t175, i32 %t174)
  %t176 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t177 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t178 = load i64, i64* %t177
  %t179 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t180 = load i64, i64* %t179
  %t181 = sext i32 99 to i64
  %t182 = icmp ult i64 %t181, %t180
  br i1 %t182, label %ring_rplace_ok_33, label %ring_rplace_oob_34
ring_rplace_ok_33:
  %t183 = add i64 %t178, %t181
  %t184 = urem i64 %t183, 3
  %t185 = getelementptr inbounds [3 x i32], [3 x i32]* %t176, i32 0, i64 %t184
  br label %ring_rplace_end_35
ring_rplace_oob_34:
  %t186 = alloca i32
  store i32 0, i32* %t186
  br label %ring_rplace_end_35
ring_rplace_end_35:
  %t187 = phi i32* [ %t185, %ring_rplace_ok_33 ], [ %t186, %ring_rplace_oob_34 ]
  %t188 = load i32, i32* %t187
  %t189 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t189, i32 %t188)
  %t190 = alloca { [2 x i32], i64, i64 }
  store { [2 x i32], i64, i64 } zeroinitializer, { [2 x i32], i64, i64 }* %t190
  %t191 = getelementptr inbounds { [2 x i32], i64, i64 }, { [2 x i32], i64, i64 }* %t190, i32 0, i32 0
  %t192 = getelementptr inbounds { [2 x i32], i64, i64 }, { [2 x i32], i64, i64 }* %t190, i32 0, i32 1
  %t193 = load i64, i64* %t192
  %t194 = getelementptr inbounds { [2 x i32], i64, i64 }, { [2 x i32], i64, i64 }* %t190, i32 0, i32 2
  %t195 = load i64, i64* %t194
  %t196 = icmp eq i64 %t195, 0
  br i1 %t196, label %ring_pop_empty_36, label %ring_pop_nonempty_37
ring_pop_nonempty_37:
  %t197 = getelementptr inbounds [2 x i32], [2 x i32]* %t191, i32 0, i64 %t193
  %t198 = load i32, i32* %t197
  store i32 0, i32* %t197
  %t199 = add i64 %t193, 1
  %t200 = urem i64 %t199, 2
  store i64 %t200, i64* %t192
  %t201 = sub i64 %t195, 1
  store i64 %t201, i64* %t194
  br label %ring_pop_end_38
ring_pop_empty_36:
  br label %ring_pop_end_38
ring_pop_end_38:
  %t202 = phi i32 [ %t198, %ring_pop_nonempty_37 ], [ 0, %ring_pop_empty_36 ]
  %t203 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t203, i32 %t202)
  %t204 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t205 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t206 = load i64, i64* %t205
  %t207 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t208 = load i64, i64* %t207
  %t209 = sext i32 0 to i64
  %t210 = icmp ult i64 %t209, %t208
  br i1 %t210, label %ring_place_ok_39, label %ring_place_oob_40
ring_place_ok_39:
  %t211 = add i64 %t206, %t209
  %t212 = urem i64 %t211, 3
  %t213 = getelementptr inbounds [3 x i32], [3 x i32]* %t204, i32 0, i64 %t212
  br label %ring_place_end_41
ring_place_oob_40:
  %t214 = alloca i32
  store i32 0, i32* %t214
  br label %ring_place_end_41
ring_place_end_41:
  %t215 = phi i32* [ %t213, %ring_place_ok_39 ], [ %t214, %ring_place_oob_40 ]
  store i32 100, i32* %t215
  %t216 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t217 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t218 = load i64, i64* %t217
  %t219 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t220 = load i64, i64* %t219
  %t221 = sext i32 0 to i64
  %t222 = icmp ult i64 %t221, %t220
  br i1 %t222, label %ring_rplace_ok_42, label %ring_rplace_oob_43
ring_rplace_ok_42:
  %t223 = add i64 %t218, %t221
  %t224 = urem i64 %t223, 3
  %t225 = getelementptr inbounds [3 x i32], [3 x i32]* %t216, i32 0, i64 %t224
  br label %ring_rplace_end_44
ring_rplace_oob_43:
  %t226 = alloca i32
  store i32 0, i32* %t226
  br label %ring_rplace_end_44
ring_rplace_end_44:
  %t227 = phi i32* [ %t225, %ring_rplace_ok_42 ], [ %t226, %ring_rplace_oob_43 ]
  %t228 = load i32, i32* %t227
  %t229 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t229, i32 %t228)
  %t230 = alloca { [2 x i8*], i64, i64 }
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t230
  %t231 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t230, i32 0, i32 0
  %t232 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t230, i32 0, i32 1
  %t233 = load i64, i64* %t232
  %t234 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t230, i32 0, i32 2
  %t235 = load i64, i64* %t234
  %t236 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t237 = icmp sge i64 %t235, 2
  br i1 %t237, label %ring_push_full_45, label %ring_push_grow_46
ring_push_grow_46:
  %t238 = add i64 %t233, %t235
  %t239 = urem i64 %t238, 2
  %t240 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t231, i32 0, i64 %t239
  store i8* %t236, i8** %t240
  %t241 = add i64 %t235, 1
  store i64 %t241, i64* %t234
  br label %ring_push_done_47
ring_push_full_45:
  %t242 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t231, i32 0, i64 %t233
  %t243 = load i8*, i8** %t242
  call void @star_rc_release(i8* %t243)
  store i8* %t236, i8** %t242
  %t244 = add i64 %t233, 1
  %t245 = urem i64 %t244, 2
  store i64 %t245, i64* %t232
  br label %ring_push_done_47
ring_push_done_47:
  %t246 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t230, i32 0, i32 0
  %t247 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t230, i32 0, i32 1
  %t248 = load i64, i64* %t247
  %t249 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t230, i32 0, i32 2
  %t250 = load i64, i64* %t249
  %t251 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t252 = icmp sge i64 %t250, 2
  br i1 %t252, label %ring_push_full_48, label %ring_push_grow_49
ring_push_grow_49:
  %t253 = add i64 %t248, %t250
  %t254 = urem i64 %t253, 2
  %t255 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t246, i32 0, i64 %t254
  store i8* %t251, i8** %t255
  %t256 = add i64 %t250, 1
  store i64 %t256, i64* %t249
  br label %ring_push_done_50
ring_push_full_48:
  %t257 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t246, i32 0, i64 %t248
  %t258 = load i8*, i8** %t257
  call void @star_rc_release(i8* %t258)
  store i8* %t251, i8** %t257
  %t259 = add i64 %t248, 1
  %t260 = urem i64 %t259, 2
  store i64 %t260, i64* %t247
  br label %ring_push_done_50
ring_push_done_50:
  %t261 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t230, i32 0, i32 0
  %t262 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t230, i32 0, i32 1
  %t263 = load i64, i64* %t262
  %t264 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t230, i32 0, i32 2
  %t265 = load i64, i64* %t264
  %t266 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.12, i64 0, i32 2, i64 0
  %t267 = icmp sge i64 %t265, 2
  br i1 %t267, label %ring_push_full_51, label %ring_push_grow_52
ring_push_grow_52:
  %t268 = add i64 %t263, %t265
  %t269 = urem i64 %t268, 2
  %t270 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t261, i32 0, i64 %t269
  store i8* %t266, i8** %t270
  %t271 = add i64 %t265, 1
  store i64 %t271, i64* %t264
  br label %ring_push_done_53
ring_push_full_51:
  %t272 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t261, i32 0, i64 %t263
  %t273 = load i8*, i8** %t272
  call void @star_rc_release(i8* %t273)
  store i8* %t266, i8** %t272
  %t274 = add i64 %t263, 1
  %t275 = urem i64 %t274, 2
  store i64 %t275, i64* %t262
  br label %ring_push_done_53
ring_push_done_53:
  %t276 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t230, i32 0, i32 0
  %t277 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t230, i32 0, i32 1
  %t278 = load i64, i64* %t277
  %t279 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t230, i32 0, i32 2
  %t280 = load i64, i64* %t279
  %t281 = sext i32 0 to i64
  %t282 = icmp ult i64 %t281, %t280
  br i1 %t282, label %ring_rplace_ok_54, label %ring_rplace_oob_55
ring_rplace_ok_54:
  %t283 = add i64 %t278, %t281
  %t284 = urem i64 %t283, 2
  %t285 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t276, i32 0, i64 %t284
  br label %ring_rplace_end_56
ring_rplace_oob_55:
  %t286 = alloca i8*
  store i8* null, i8** %t286
  br label %ring_rplace_end_56
ring_rplace_end_56:
  %t287 = phi i8** [ %t285, %ring_rplace_ok_54 ], [ %t286, %ring_rplace_oob_55 ]
  %t288 = load i8*, i8** %t287
  %t289 = load i8*, i8** %t287
  call void @star_rc_retain(i8* %t289)
  %t290 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t230, i32 0, i32 0
  %t291 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t230, i32 0, i32 1
  %t292 = load i64, i64* %t291
  %t293 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t230, i32 0, i32 2
  %t294 = load i64, i64* %t293
  %t295 = sext i32 1 to i64
  %t296 = icmp ult i64 %t295, %t294
  br i1 %t296, label %ring_rplace_ok_57, label %ring_rplace_oob_58
ring_rplace_ok_57:
  %t297 = add i64 %t292, %t295
  %t298 = urem i64 %t297, 2
  %t299 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t290, i32 0, i64 %t298
  br label %ring_rplace_end_59
ring_rplace_oob_58:
  %t300 = alloca i8*
  store i8* null, i8** %t300
  br label %ring_rplace_end_59
ring_rplace_end_59:
  %t301 = phi i8** [ %t299, %ring_rplace_ok_57 ], [ %t300, %ring_rplace_oob_58 ]
  %t302 = load i8*, i8** %t301
  %t303 = load i8*, i8** %t301
  call void @star_rc_retain(i8* %t303)
  %t304 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t304, i8* %t288, i8* %t302)
  %t305 = alloca { [2 x %Player], i64, i64 }
  store { [2 x %Player], i64, i64 } zeroinitializer, { [2 x %Player], i64, i64 }* %t305
  %t306 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t305, i32 0, i32 0
  %t307 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t305, i32 0, i32 1
  %t308 = load i64, i64* %t307
  %t309 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t305, i32 0, i32 2
  %t310 = load i64, i64* %t309
  %t311 = alloca %Player
  %t312 = getelementptr inbounds %Player, %Player* %t311, i32 0, i32 0
  store i32 100, i32* %t312
  %t313 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t314 = getelementptr inbounds %Player, %Player* %t311, i32 0, i32 1
  store i8* %t313, i8** %t314
  %t315 = load %Player, %Player* %t311
  %t316 = icmp sge i64 %t310, 2
  br i1 %t316, label %ring_push_full_60, label %ring_push_grow_61
ring_push_grow_61:
  %t317 = add i64 %t308, %t310
  %t318 = urem i64 %t317, 2
  %t319 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t306, i32 0, i64 %t318
  store %Player %t315, %Player* %t319
  %t320 = add i64 %t310, 1
  store i64 %t320, i64* %t309
  br label %ring_push_done_62
ring_push_full_60:
  %t321 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t306, i32 0, i64 %t308
  %t322 = getelementptr inbounds %Player, %Player* %t321, i32 0, i32 1
  %t323 = load i8*, i8** %t322
  call void @star_rc_release(i8* %t323)
  store %Player %t315, %Player* %t321
  %t324 = add i64 %t308, 1
  %t325 = urem i64 %t324, 2
  store i64 %t325, i64* %t307
  br label %ring_push_done_62
ring_push_done_62:
  %t326 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t305, i32 0, i32 0
  %t327 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t305, i32 0, i32 1
  %t328 = load i64, i64* %t327
  %t329 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t305, i32 0, i32 2
  %t330 = load i64, i64* %t329
  %t331 = alloca %Player
  %t332 = getelementptr inbounds %Player, %Player* %t331, i32 0, i32 0
  store i32 80, i32* %t332
  %t333 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t334 = getelementptr inbounds %Player, %Player* %t331, i32 0, i32 1
  store i8* %t333, i8** %t334
  %t335 = load %Player, %Player* %t331
  %t336 = icmp sge i64 %t330, 2
  br i1 %t336, label %ring_push_full_63, label %ring_push_grow_64
ring_push_grow_64:
  %t337 = add i64 %t328, %t330
  %t338 = urem i64 %t337, 2
  %t339 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t326, i32 0, i64 %t338
  store %Player %t335, %Player* %t339
  %t340 = add i64 %t330, 1
  store i64 %t340, i64* %t329
  br label %ring_push_done_65
ring_push_full_63:
  %t341 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t326, i32 0, i64 %t328
  %t342 = getelementptr inbounds %Player, %Player* %t341, i32 0, i32 1
  %t343 = load i8*, i8** %t342
  call void @star_rc_release(i8* %t343)
  store %Player %t335, %Player* %t341
  %t344 = add i64 %t328, 1
  %t345 = urem i64 %t344, 2
  store i64 %t345, i64* %t327
  br label %ring_push_done_65
ring_push_done_65:
  %t346 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t305, i32 0, i32 0
  %t347 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t305, i32 0, i32 1
  %t348 = load i64, i64* %t347
  %t349 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t305, i32 0, i32 2
  %t350 = load i64, i64* %t349
  %t351 = sext i32 0 to i64
  %t352 = icmp ult i64 %t351, %t350
  br i1 %t352, label %ring_rplace_ok_66, label %ring_rplace_oob_67
ring_rplace_ok_66:
  %t353 = add i64 %t348, %t351
  %t354 = urem i64 %t353, 2
  %t355 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t346, i32 0, i64 %t354
  br label %ring_rplace_end_68
ring_rplace_oob_67:
  %t356 = alloca %Player
  store %Player zeroinitializer, %Player* %t356
  br label %ring_rplace_end_68
ring_rplace_end_68:
  %t357 = phi %Player* [ %t355, %ring_rplace_ok_66 ], [ %t356, %ring_rplace_oob_67 ]
  %t358 = getelementptr inbounds %Player, %Player* %t357, i32 0, i32 1
  %t359 = load i8*, i8** %t358
  %t360 = load i8*, i8** %t358
  call void @star_rc_retain(i8* %t360)
  call void @star_rc_release(i8* %t359)
  %t361 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t305, i32 0, i32 0
  %t362 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t305, i32 0, i32 1
  %t363 = load i64, i64* %t362
  %t364 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t305, i32 0, i32 2
  %t365 = load i64, i64* %t364
  %t366 = sext i32 0 to i64
  %t367 = icmp ult i64 %t366, %t365
  br i1 %t367, label %ring_rplace_ok_69, label %ring_rplace_oob_70
ring_rplace_ok_69:
  %t368 = add i64 %t363, %t366
  %t369 = urem i64 %t368, 2
  %t370 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t361, i32 0, i64 %t369
  br label %ring_rplace_end_71
ring_rplace_oob_70:
  %t371 = alloca %Player
  store %Player zeroinitializer, %Player* %t371
  br label %ring_rplace_end_71
ring_rplace_end_71:
  %t372 = phi %Player* [ %t370, %ring_rplace_ok_69 ], [ %t371, %ring_rplace_oob_70 ]
  %t373 = getelementptr inbounds %Player, %Player* %t372, i32 0, i32 0
  %t374 = load i32, i32* %t373
  %t375 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t375, i8* %t359, i32 %t374)
  %t376 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t305, i32 0, i32 0
  %t377 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t376, i32 0, i64 0
  %t378 = getelementptr inbounds %Player, %Player* %t377, i32 0, i32 1
  %t379 = load i8*, i8** %t378
  call void @star_rc_release(i8* %t379)
  %t380 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t376, i32 0, i64 1
  %t381 = getelementptr inbounds %Player, %Player* %t380, i32 0, i32 1
  %t382 = load i8*, i8** %t381
  call void @star_rc_release(i8* %t382)
  %t383 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t230, i32 0, i32 0
  %t384 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t383, i32 0, i64 0
  %t385 = load i8*, i8** %t384
  call void @star_rc_release(i8* %t385)
  %t386 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t383, i32 0, i64 1
  %t387 = load i8*, i8** %t386
  call void @star_rc_release(i8* %t387)
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
