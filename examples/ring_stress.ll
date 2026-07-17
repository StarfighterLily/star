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

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca { [4 x i8*], i64, i64 }
  %t2 = alloca i32
  %t46 = alloca i8*
  %t63 = alloca i8*
  %t80 = alloca i8*
  %t97 = alloca i8*
  %t102 = alloca { [3 x i8*], i64, i64 }
  %t103 = alloca i32
  %t135 = alloca i8*
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  store { [4 x i8*], i64, i64 } zeroinitializer, { [4 x i8*], i64, i64 }* %t1
  store i32 0, i32* %t2
  br label %while_cond_0
while_cond_0:
  %t3 = load i32, i32* %t2
  %t4 = icmp slt i32 %t3, 200000
  br i1 %t4, label %while_body_1, label %while_else_2
while_body_1:
  %t5 = load i32, i32* %t2
  %t6 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.0, i64 0, i64 0
  %t7 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t6, i32 %t5)
  %t8 = add i32 %t7, 1
  %t9 = sext i32 %t8 to i64
  %t10 = call i8* @star_rc_alloc(i64 %t9, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t10, i64 %t9, i8* %t6, i32 %t5)
  %t11 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t1, i32 0, i32 0
  %t12 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t1, i32 0, i32 1
  %t13 = load i64, i64* %t12
  %t14 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t1, i32 0, i32 2
  %t15 = load i64, i64* %t14
  %t16 = icmp sge i64 %t15, 4
  br i1 %t16, label %ring_push_full_4, label %ring_push_grow_5
ring_push_grow_5:
  %t17 = add i64 %t13, %t15
  %t18 = urem i64 %t17, 4
  %t19 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t11, i32 0, i64 %t18
  store i8* %t10, i8** %t19
  %t20 = add i64 %t15, 1
  store i64 %t20, i64* %t14
  br label %ring_push_done_6
ring_push_full_4:
  %t21 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t11, i32 0, i64 %t13
  %t22 = load i8*, i8** %t21
  call void @star_rc_release(i8* %t22)
  store i8* %t10, i8** %t21
  %t23 = add i64 %t13, 1
  %t24 = urem i64 %t23, 4
  store i64 %t24, i64* %t12
  br label %ring_push_done_6
ring_push_done_6:
  %t25 = load i32, i32* %t2
  %t26 = add i32 %t25, 1
  store i32 %t26, i32* %t2
  br label %while_cond_0
while_else_2:
  br label %while_end_3
while_end_3:
  %t27 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t1, i32 0, i32 0
  %t28 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t1, i32 0, i32 1
  %t29 = load i64, i64* %t28
  %t30 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t1, i32 0, i32 2
  %t31 = load i64, i64* %t30
  %t32 = trunc i64 %t31 to i32
  %t33 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t33, i32 %t32)
  %t34 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t1, i32 0, i32 0
  %t35 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t1, i32 0, i32 1
  %t36 = load i64, i64* %t35
  %t37 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t1, i32 0, i32 2
  %t38 = load i64, i64* %t37
  %t39 = sext i32 0 to i64
  %t40 = load i64, i64* %t35
  %t41 = load i64, i64* %t37
  %t42 = icmp ult i64 %t39, %t41
  br i1 %t42, label %ring_rplace_ok_7, label %ring_rplace_oob_8
ring_rplace_ok_7:
  %t43 = add i64 %t40, %t39
  %t44 = urem i64 %t43, 4
  %t45 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t34, i32 0, i64 %t44
  br label %ring_rplace_end_9
ring_rplace_oob_8:
  store i8* null, i8** %t46
  br label %ring_rplace_end_9
ring_rplace_end_9:
  %t47 = phi i8** [ %t45, %ring_rplace_ok_7 ], [ %t46, %ring_rplace_oob_8 ]
  %t48 = load i8*, i8** %t47
  %t49 = load i8*, i8** %t47
  call void @star_rc_retain(i8* %t49)
  call void @star_rc_release(i8* %t48)
  %t50 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t50, i8* %t48)
  %t51 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t1, i32 0, i32 0
  %t52 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t1, i32 0, i32 1
  %t53 = load i64, i64* %t52
  %t54 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t1, i32 0, i32 2
  %t55 = load i64, i64* %t54
  %t56 = sext i32 1 to i64
  %t57 = load i64, i64* %t52
  %t58 = load i64, i64* %t54
  %t59 = icmp ult i64 %t56, %t58
  br i1 %t59, label %ring_rplace_ok_10, label %ring_rplace_oob_11
ring_rplace_ok_10:
  %t60 = add i64 %t57, %t56
  %t61 = urem i64 %t60, 4
  %t62 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t51, i32 0, i64 %t61
  br label %ring_rplace_end_12
ring_rplace_oob_11:
  store i8* null, i8** %t63
  br label %ring_rplace_end_12
ring_rplace_end_12:
  %t64 = phi i8** [ %t62, %ring_rplace_ok_10 ], [ %t63, %ring_rplace_oob_11 ]
  %t65 = load i8*, i8** %t64
  %t66 = load i8*, i8** %t64
  call void @star_rc_retain(i8* %t66)
  call void @star_rc_release(i8* %t65)
  %t67 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t67, i8* %t65)
  %t68 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t1, i32 0, i32 0
  %t69 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t1, i32 0, i32 1
  %t70 = load i64, i64* %t69
  %t71 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t1, i32 0, i32 2
  %t72 = load i64, i64* %t71
  %t73 = sext i32 2 to i64
  %t74 = load i64, i64* %t69
  %t75 = load i64, i64* %t71
  %t76 = icmp ult i64 %t73, %t75
  br i1 %t76, label %ring_rplace_ok_13, label %ring_rplace_oob_14
ring_rplace_ok_13:
  %t77 = add i64 %t74, %t73
  %t78 = urem i64 %t77, 4
  %t79 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t68, i32 0, i64 %t78
  br label %ring_rplace_end_15
ring_rplace_oob_14:
  store i8* null, i8** %t80
  br label %ring_rplace_end_15
ring_rplace_end_15:
  %t81 = phi i8** [ %t79, %ring_rplace_ok_13 ], [ %t80, %ring_rplace_oob_14 ]
  %t82 = load i8*, i8** %t81
  %t83 = load i8*, i8** %t81
  call void @star_rc_retain(i8* %t83)
  call void @star_rc_release(i8* %t82)
  %t84 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t84, i8* %t82)
  %t85 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t1, i32 0, i32 0
  %t86 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t1, i32 0, i32 1
  %t87 = load i64, i64* %t86
  %t88 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t1, i32 0, i32 2
  %t89 = load i64, i64* %t88
  %t90 = sext i32 3 to i64
  %t91 = load i64, i64* %t86
  %t92 = load i64, i64* %t88
  %t93 = icmp ult i64 %t90, %t92
  br i1 %t93, label %ring_rplace_ok_16, label %ring_rplace_oob_17
ring_rplace_ok_16:
  %t94 = add i64 %t91, %t90
  %t95 = urem i64 %t94, 4
  %t96 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t85, i32 0, i64 %t95
  br label %ring_rplace_end_18
ring_rplace_oob_17:
  store i8* null, i8** %t97
  br label %ring_rplace_end_18
ring_rplace_end_18:
  %t98 = phi i8** [ %t96, %ring_rplace_ok_16 ], [ %t97, %ring_rplace_oob_17 ]
  %t99 = load i8*, i8** %t98
  %t100 = load i8*, i8** %t98
  call void @star_rc_retain(i8* %t100)
  call void @star_rc_release(i8* %t99)
  %t101 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t101, i8* %t99)
  store { [3 x i8*], i64, i64 } zeroinitializer, { [3 x i8*], i64, i64 }* %t102
  store i32 0, i32* %t103
  br label %while_cond_19
while_cond_19:
  %t104 = load i32, i32* %t103
  %t105 = icmp slt i32 %t104, 50000
  br i1 %t105, label %while_body_20, label %while_else_21
while_body_20:
  %t106 = load i32, i32* %t103
  %t107 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.6, i64 0, i64 0
  %t108 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t107, i32 %t106)
  %t109 = add i32 %t108, 1
  %t110 = sext i32 %t109 to i64
  %t111 = call i8* @star_rc_alloc(i64 %t110, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t111, i64 %t110, i8* %t107, i32 %t106)
  %t112 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t102, i32 0, i32 0
  %t113 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t102, i32 0, i32 1
  %t114 = load i64, i64* %t113
  %t115 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t102, i32 0, i32 2
  %t116 = load i64, i64* %t115
  %t117 = icmp sge i64 %t116, 3
  br i1 %t117, label %ring_push_full_23, label %ring_push_grow_24
ring_push_grow_24:
  %t118 = add i64 %t114, %t116
  %t119 = urem i64 %t118, 3
  %t120 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t112, i32 0, i64 %t119
  store i8* %t111, i8** %t120
  %t121 = add i64 %t116, 1
  store i64 %t121, i64* %t115
  br label %ring_push_done_25
ring_push_full_23:
  %t122 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t112, i32 0, i64 %t114
  %t123 = load i8*, i8** %t122
  call void @star_rc_release(i8* %t123)
  store i8* %t111, i8** %t122
  %t124 = add i64 %t114, 1
  %t125 = urem i64 %t124, 3
  store i64 %t125, i64* %t113
  br label %ring_push_done_25
ring_push_done_25:
  %t126 = load i32, i32* %t103
  %t127 = icmp eq i32 3, 0
  %t128 = icmp eq i32 %t126, -2147483648
  %t129 = icmp eq i32 3, -1
  %t130 = and i1 %t128, %t129
  %t131 = or i1 %t127, %t130
  br i1 %t131, label %int_div_fail_26, label %int_div_ok_27
int_div_fail_26:
  %t132 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.7, i64 0, i64 0
  call i32 @puts(i8* %t132)
  call void @exit(i32 1)
  unreachable
int_div_ok_27:
  %t133 = srem i32 %t126, 3
  %t134 = icmp eq i32 %t133, 0
  br i1 %t134, label %if_then_28, label %if_else_29
if_then_28:
  %t136 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t102, i32 0, i32 0
  %t137 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t102, i32 0, i32 1
  %t138 = load i64, i64* %t137
  %t139 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t102, i32 0, i32 2
  %t140 = load i64, i64* %t139
  %t141 = icmp eq i64 %t140, 0
  br i1 %t141, label %ring_pop_empty_31, label %ring_pop_nonempty_32
ring_pop_nonempty_32:
  %t142 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t136, i32 0, i64 %t138
  %t143 = load i8*, i8** %t142
  store i8* null, i8** %t142
  %t144 = add i64 %t138, 1
  %t145 = urem i64 %t144, 3
  store i64 %t145, i64* %t137
  %t146 = sub i64 %t140, 1
  store i64 %t146, i64* %t139
  br label %ring_pop_end_33
ring_pop_empty_31:
  br label %ring_pop_end_33
ring_pop_end_33:
  %t147 = phi i8* [ %t143, %ring_pop_nonempty_32 ], [ null, %ring_pop_empty_31 ]
  store i8* %t147, i8** %t135
  %t148 = load i8*, i8** %t135
  %t149 = load i8*, i8** %t135
  call void @star_rc_retain(i8* %t149)
  %t150 = call i32 @strlen(i8* %t148)
  call void @star_rc_release(i8* %t148)
  %t151 = icmp eq i32 %t150, 0
  br i1 %t151, label %if_then_34, label %if_else_35
if_then_34:
  %t152 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.8, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t152)
  call i32 (i8*, ...) @printf(i8* %t152)
  %t153 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t153)
  br label %if_end_36
if_else_35:
  br label %if_end_36
if_end_36:
  %t154 = load i8*, i8** %t135
  call void @star_rc_release(i8* %t154)
  br label %if_end_30
if_else_29:
  br label %if_end_30
if_end_30:
  %t155 = load i32, i32* %t103
  %t156 = add i32 %t155, 1
  store i32 %t156, i32* %t103
  br label %while_cond_19
while_else_21:
  br label %while_end_22
while_end_22:
  %t157 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t102, i32 0, i32 0
  %t158 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t102, i32 0, i32 1
  %t159 = load i64, i64* %t158
  %t160 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t102, i32 0, i32 2
  %t161 = load i64, i64* %t160
  %t162 = trunc i64 %t161 to i32
  %t163 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t163, i32 %t162)
  %t164 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t102, i32 0, i32 0
  %t165 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t164, i32 0, i64 0
  %t166 = load i8*, i8** %t165
  call void @star_rc_release(i8* %t166)
  %t167 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t164, i32 0, i64 1
  %t168 = load i8*, i8** %t167
  call void @star_rc_release(i8* %t168)
  %t169 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t164, i32 0, i64 2
  %t170 = load i8*, i8** %t169
  call void @star_rc_release(i8* %t170)
  %t171 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t1, i32 0, i32 0
  %t172 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t171, i32 0, i64 0
  %t173 = load i8*, i8** %t172
  call void @star_rc_release(i8* %t173)
  %t174 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t171, i32 0, i64 1
  %t175 = load i8*, i8** %t174
  call void @star_rc_release(i8* %t175)
  %t176 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t171, i32 0, i64 2
  %t177 = load i8*, i8** %t176
  call void @star_rc_release(i8* %t177)
  %t178 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t171, i32 0, i64 3
  %t179 = load i8*, i8** %t178
  call void @star_rc_release(i8* %t179)
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
