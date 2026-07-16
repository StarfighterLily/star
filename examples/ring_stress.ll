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
  %t0 = alloca { [4 x i8*], i64, i64 }
  %t1 = alloca i32
  %t45 = alloca i8*
  %t62 = alloca i8*
  %t79 = alloca i8*
  %t96 = alloca i8*
  %t101 = alloca { [3 x i8*], i64, i64 }
  %t102 = alloca i32
  %t134 = alloca i8*
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  store { [4 x i8*], i64, i64 } zeroinitializer, { [4 x i8*], i64, i64 }* %t0
  store i32 0, i32* %t1
  br label %while_cond_0
while_cond_0:
  %t2 = load i32, i32* %t1
  %t3 = icmp slt i32 %t2, 200000
  br i1 %t3, label %while_body_1, label %while_else_2
while_body_1:
  %t4 = load i32, i32* %t1
  %t5 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.0, i64 0, i64 0
  %t6 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t5, i32 %t4)
  %t7 = add i32 %t6, 1
  %t8 = sext i32 %t7 to i64
  %t9 = call i8* @star_rc_alloc(i64 %t8, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t9, i64 %t8, i8* %t5, i32 %t4)
  %t10 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 0
  %t11 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 1
  %t12 = load i64, i64* %t11
  %t13 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 2
  %t14 = load i64, i64* %t13
  %t15 = icmp sge i64 %t14, 4
  br i1 %t15, label %ring_push_full_4, label %ring_push_grow_5
ring_push_grow_5:
  %t16 = add i64 %t12, %t14
  %t17 = urem i64 %t16, 4
  %t18 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t10, i32 0, i64 %t17
  store i8* %t9, i8** %t18
  %t19 = add i64 %t14, 1
  store i64 %t19, i64* %t13
  br label %ring_push_done_6
ring_push_full_4:
  %t20 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t10, i32 0, i64 %t12
  %t21 = load i8*, i8** %t20
  call void @star_rc_release(i8* %t21)
  store i8* %t9, i8** %t20
  %t22 = add i64 %t12, 1
  %t23 = urem i64 %t22, 4
  store i64 %t23, i64* %t11
  br label %ring_push_done_6
ring_push_done_6:
  %t24 = load i32, i32* %t1
  %t25 = add i32 %t24, 1
  store i32 %t25, i32* %t1
  br label %while_cond_0
while_else_2:
  br label %while_end_3
while_end_3:
  %t26 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 0
  %t27 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 1
  %t28 = load i64, i64* %t27
  %t29 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 2
  %t30 = load i64, i64* %t29
  %t31 = trunc i64 %t30 to i32
  %t32 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t32, i32 %t31)
  %t33 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 0
  %t34 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 1
  %t35 = load i64, i64* %t34
  %t36 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 2
  %t37 = load i64, i64* %t36
  %t38 = sext i32 0 to i64
  %t39 = load i64, i64* %t34
  %t40 = load i64, i64* %t36
  %t41 = icmp ult i64 %t38, %t40
  br i1 %t41, label %ring_rplace_ok_7, label %ring_rplace_oob_8
ring_rplace_ok_7:
  %t42 = add i64 %t39, %t38
  %t43 = urem i64 %t42, 4
  %t44 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t33, i32 0, i64 %t43
  br label %ring_rplace_end_9
ring_rplace_oob_8:
  store i8* null, i8** %t45
  br label %ring_rplace_end_9
ring_rplace_end_9:
  %t46 = phi i8** [ %t44, %ring_rplace_ok_7 ], [ %t45, %ring_rplace_oob_8 ]
  %t47 = load i8*, i8** %t46
  %t48 = load i8*, i8** %t46
  call void @star_rc_retain(i8* %t48)
  %t49 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t49, i8* %t47)
  %t50 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 0
  %t51 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 1
  %t52 = load i64, i64* %t51
  %t53 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 2
  %t54 = load i64, i64* %t53
  %t55 = sext i32 1 to i64
  %t56 = load i64, i64* %t51
  %t57 = load i64, i64* %t53
  %t58 = icmp ult i64 %t55, %t57
  br i1 %t58, label %ring_rplace_ok_10, label %ring_rplace_oob_11
ring_rplace_ok_10:
  %t59 = add i64 %t56, %t55
  %t60 = urem i64 %t59, 4
  %t61 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t50, i32 0, i64 %t60
  br label %ring_rplace_end_12
ring_rplace_oob_11:
  store i8* null, i8** %t62
  br label %ring_rplace_end_12
ring_rplace_end_12:
  %t63 = phi i8** [ %t61, %ring_rplace_ok_10 ], [ %t62, %ring_rplace_oob_11 ]
  %t64 = load i8*, i8** %t63
  %t65 = load i8*, i8** %t63
  call void @star_rc_retain(i8* %t65)
  %t66 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t66, i8* %t64)
  %t67 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 0
  %t68 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 1
  %t69 = load i64, i64* %t68
  %t70 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 2
  %t71 = load i64, i64* %t70
  %t72 = sext i32 2 to i64
  %t73 = load i64, i64* %t68
  %t74 = load i64, i64* %t70
  %t75 = icmp ult i64 %t72, %t74
  br i1 %t75, label %ring_rplace_ok_13, label %ring_rplace_oob_14
ring_rplace_ok_13:
  %t76 = add i64 %t73, %t72
  %t77 = urem i64 %t76, 4
  %t78 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t67, i32 0, i64 %t77
  br label %ring_rplace_end_15
ring_rplace_oob_14:
  store i8* null, i8** %t79
  br label %ring_rplace_end_15
ring_rplace_end_15:
  %t80 = phi i8** [ %t78, %ring_rplace_ok_13 ], [ %t79, %ring_rplace_oob_14 ]
  %t81 = load i8*, i8** %t80
  %t82 = load i8*, i8** %t80
  call void @star_rc_retain(i8* %t82)
  %t83 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t83, i8* %t81)
  %t84 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 0
  %t85 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 1
  %t86 = load i64, i64* %t85
  %t87 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 2
  %t88 = load i64, i64* %t87
  %t89 = sext i32 3 to i64
  %t90 = load i64, i64* %t85
  %t91 = load i64, i64* %t87
  %t92 = icmp ult i64 %t89, %t91
  br i1 %t92, label %ring_rplace_ok_16, label %ring_rplace_oob_17
ring_rplace_ok_16:
  %t93 = add i64 %t90, %t89
  %t94 = urem i64 %t93, 4
  %t95 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t84, i32 0, i64 %t94
  br label %ring_rplace_end_18
ring_rplace_oob_17:
  store i8* null, i8** %t96
  br label %ring_rplace_end_18
ring_rplace_end_18:
  %t97 = phi i8** [ %t95, %ring_rplace_ok_16 ], [ %t96, %ring_rplace_oob_17 ]
  %t98 = load i8*, i8** %t97
  %t99 = load i8*, i8** %t97
  call void @star_rc_retain(i8* %t99)
  %t100 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t100, i8* %t98)
  store { [3 x i8*], i64, i64 } zeroinitializer, { [3 x i8*], i64, i64 }* %t101
  store i32 0, i32* %t102
  br label %while_cond_19
while_cond_19:
  %t103 = load i32, i32* %t102
  %t104 = icmp slt i32 %t103, 50000
  br i1 %t104, label %while_body_20, label %while_else_21
while_body_20:
  %t105 = load i32, i32* %t102
  %t106 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.6, i64 0, i64 0
  %t107 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t106, i32 %t105)
  %t108 = add i32 %t107, 1
  %t109 = sext i32 %t108 to i64
  %t110 = call i8* @star_rc_alloc(i64 %t109, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t110, i64 %t109, i8* %t106, i32 %t105)
  %t111 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t101, i32 0, i32 0
  %t112 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t101, i32 0, i32 1
  %t113 = load i64, i64* %t112
  %t114 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t101, i32 0, i32 2
  %t115 = load i64, i64* %t114
  %t116 = icmp sge i64 %t115, 3
  br i1 %t116, label %ring_push_full_23, label %ring_push_grow_24
ring_push_grow_24:
  %t117 = add i64 %t113, %t115
  %t118 = urem i64 %t117, 3
  %t119 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t111, i32 0, i64 %t118
  store i8* %t110, i8** %t119
  %t120 = add i64 %t115, 1
  store i64 %t120, i64* %t114
  br label %ring_push_done_25
ring_push_full_23:
  %t121 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t111, i32 0, i64 %t113
  %t122 = load i8*, i8** %t121
  call void @star_rc_release(i8* %t122)
  store i8* %t110, i8** %t121
  %t123 = add i64 %t113, 1
  %t124 = urem i64 %t123, 3
  store i64 %t124, i64* %t112
  br label %ring_push_done_25
ring_push_done_25:
  %t125 = load i32, i32* %t102
  %t126 = icmp eq i32 3, 0
  %t127 = icmp eq i32 %t125, -2147483648
  %t128 = icmp eq i32 3, -1
  %t129 = and i1 %t127, %t128
  %t130 = or i1 %t126, %t129
  br i1 %t130, label %int_div_fail_26, label %int_div_ok_27
int_div_fail_26:
  %t131 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.7, i64 0, i64 0
  call i32 @puts(i8* %t131)
  call void @exit(i32 1)
  unreachable
int_div_ok_27:
  %t132 = srem i32 %t125, 3
  %t133 = icmp eq i32 %t132, 0
  br i1 %t133, label %if_then_28, label %if_else_29
if_then_28:
  %t135 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t101, i32 0, i32 0
  %t136 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t101, i32 0, i32 1
  %t137 = load i64, i64* %t136
  %t138 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t101, i32 0, i32 2
  %t139 = load i64, i64* %t138
  %t140 = icmp eq i64 %t139, 0
  br i1 %t140, label %ring_pop_empty_31, label %ring_pop_nonempty_32
ring_pop_nonempty_32:
  %t141 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t135, i32 0, i64 %t137
  %t142 = load i8*, i8** %t141
  store i8* null, i8** %t141
  %t143 = add i64 %t137, 1
  %t144 = urem i64 %t143, 3
  store i64 %t144, i64* %t136
  %t145 = sub i64 %t139, 1
  store i64 %t145, i64* %t138
  br label %ring_pop_end_33
ring_pop_empty_31:
  br label %ring_pop_end_33
ring_pop_end_33:
  %t146 = phi i8* [ %t142, %ring_pop_nonempty_32 ], [ null, %ring_pop_empty_31 ]
  store i8* %t146, i8** %t134
  %t147 = load i8*, i8** %t134
  %t148 = load i8*, i8** %t134
  call void @star_rc_retain(i8* %t148)
  call void @star_rc_release(i8* %t147)
  %t149 = call i32 @strlen(i8* %t147)
  %t150 = icmp eq i32 %t149, 0
  br i1 %t150, label %if_then_34, label %if_else_35
if_then_34:
  %t151 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.8, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t151)
  %t152 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t152)
  br label %if_end_36
if_else_35:
  br label %if_end_36
if_end_36:
  %t153 = load i8*, i8** %t134
  call void @star_rc_release(i8* %t153)
  br label %if_end_30
if_else_29:
  br label %if_end_30
if_end_30:
  %t154 = load i32, i32* %t102
  %t155 = add i32 %t154, 1
  store i32 %t155, i32* %t102
  br label %while_cond_19
while_else_21:
  br label %while_end_22
while_end_22:
  %t156 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t101, i32 0, i32 0
  %t157 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t101, i32 0, i32 1
  %t158 = load i64, i64* %t157
  %t159 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t101, i32 0, i32 2
  %t160 = load i64, i64* %t159
  %t161 = trunc i64 %t160 to i32
  %t162 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t162, i32 %t161)
  %t163 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t101, i32 0, i32 0
  %t164 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t163, i32 0, i64 0
  %t165 = load i8*, i8** %t164
  call void @star_rc_release(i8* %t165)
  %t166 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t163, i32 0, i64 1
  %t167 = load i8*, i8** %t166
  call void @star_rc_release(i8* %t167)
  %t168 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t163, i32 0, i64 2
  %t169 = load i8*, i8** %t168
  call void @star_rc_release(i8* %t169)
  %t170 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 0
  %t171 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t170, i32 0, i64 0
  %t172 = load i8*, i8** %t171
  call void @star_rc_release(i8* %t172)
  %t173 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t170, i32 0, i64 1
  %t174 = load i8*, i8** %t173
  call void @star_rc_release(i8* %t174)
  %t175 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t170, i32 0, i64 2
  %t176 = load i8*, i8** %t175
  call void @star_rc_release(i8* %t176)
  %t177 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t170, i32 0, i64 3
  %t178 = load i8*, i8** %t177
  call void @star_rc_release(i8* %t178)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [8 x i8] c"item-%d\00"
@.str.1 = private unnamed_addr constant [10 x i8] c"len = %d\0A\00"
@.str.2 = private unnamed_addr constant [11 x i8] c"r[0] = %s\0A\00"
@.str.3 = private unnamed_addr constant [11 x i8] c"r[1] = %s\0A\00"
@.str.4 = private unnamed_addr constant [11 x i8] c"r[2] = %s\0A\00"
@.str.5 = private unnamed_addr constant [11 x i8] c"r[3] = %s\0A\00"
@.str.6 = private unnamed_addr constant [9 x i8] c"cycle-%d\00"
@.str.7 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.8 = private unnamed_addr constant { i64, i8*, [21 x i8] } { i64 -1, i8* null, [21 x i8] c"unexpected empty pop\00" }
@.str.9 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.10 = private unnamed_addr constant [17 x i8] c"cycler len = %d\0A\00"
