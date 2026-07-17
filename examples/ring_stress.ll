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

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca { [4 x i8*], i64, i64 }
  %t3 = alloca i32
  %t47 = alloca i8*
  %t65 = alloca i8*
  %t83 = alloca i8*
  %t101 = alloca i8*
  %t107 = alloca { [3 x i8*], i64, i64 }
  %t108 = alloca i32
  %t140 = alloca i8*
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  store { [4 x i8*], i64, i64 } zeroinitializer, { [4 x i8*], i64, i64 }* %t2
  store i32 0, i32* %t3
  br label %while_cond_0
while_cond_0:
  %t4 = load i32, i32* %t3
  %t5 = icmp slt i32 %t4, 200000
  br i1 %t5, label %while_body_1, label %while_else_2
while_body_1:
  %t6 = load i32, i32* %t3
  %t7 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.0, i64 0, i64 0
  %t8 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t7, i32 %t6)
  %t9 = add i32 %t8, 1
  %t10 = sext i32 %t9 to i64
  %t11 = call i8* @star_rc_alloc(i64 %t10, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t11, i64 %t10, i8* %t7, i32 %t6)
  %t12 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t2, i32 0, i32 0
  %t13 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t2, i32 0, i32 1
  %t14 = load i64, i64* %t13
  %t15 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t2, i32 0, i32 2
  %t16 = load i64, i64* %t15
  %t17 = icmp sge i64 %t16, 4
  br i1 %t17, label %ring_push_full_4, label %ring_push_grow_5
ring_push_grow_5:
  %t18 = add i64 %t14, %t16
  %t19 = urem i64 %t18, 4
  %t20 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t12, i32 0, i64 %t19
  store i8* %t11, i8** %t20
  %t21 = add i64 %t16, 1
  store i64 %t21, i64* %t15
  br label %ring_push_done_6
ring_push_full_4:
  %t22 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t12, i32 0, i64 %t14
  %t23 = load i8*, i8** %t22
  call void @star_rc_release(i8* %t23)
  store i8* %t11, i8** %t22
  %t24 = add i64 %t14, 1
  %t25 = urem i64 %t24, 4
  store i64 %t25, i64* %t13
  br label %ring_push_done_6
ring_push_done_6:
  %t26 = load i32, i32* %t3
  %t27 = add i32 %t26, 1
  store i32 %t27, i32* %t3
  br label %while_cond_0
while_else_2:
  br label %while_end_3
while_end_3:
  %t28 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t2, i32 0, i32 0
  %t29 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t2, i32 0, i32 1
  %t30 = load i64, i64* %t29
  %t31 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t2, i32 0, i32 2
  %t32 = load i64, i64* %t31
  %t33 = trunc i64 %t32 to i32
  %t34 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t34, i32 %t33)
  %t35 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t2, i32 0, i32 0
  %t36 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t2, i32 0, i32 1
  %t37 = load i64, i64* %t36
  %t38 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t2, i32 0, i32 2
  %t39 = load i64, i64* %t38
  %t40 = sext i32 0 to i64
  %t41 = load i64, i64* %t36
  %t42 = load i64, i64* %t38
  %t43 = icmp ult i64 %t40, %t42
  br i1 %t43, label %ring_rplace_ok_7, label %ring_rplace_oob_8
ring_rplace_ok_7:
  %t44 = add i64 %t41, %t40
  %t45 = urem i64 %t44, 4
  %t46 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t35, i32 0, i64 %t45
  br label %ring_rplace_end_9
ring_rplace_oob_8:
  %t48 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t48
  store i8* %t48, i8** %t47
  br label %ring_rplace_end_9
ring_rplace_end_9:
  %t49 = phi i8** [ %t46, %ring_rplace_ok_7 ], [ %t47, %ring_rplace_oob_8 ]
  %t50 = load i8*, i8** %t49
  %t51 = load i8*, i8** %t49
  call void @star_rc_retain(i8* %t51)
  call void @star_rc_release(i8* %t50)
  %t52 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t52, i8* %t50)
  %t53 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t2, i32 0, i32 0
  %t54 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t2, i32 0, i32 1
  %t55 = load i64, i64* %t54
  %t56 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t2, i32 0, i32 2
  %t57 = load i64, i64* %t56
  %t58 = sext i32 1 to i64
  %t59 = load i64, i64* %t54
  %t60 = load i64, i64* %t56
  %t61 = icmp ult i64 %t58, %t60
  br i1 %t61, label %ring_rplace_ok_10, label %ring_rplace_oob_11
ring_rplace_ok_10:
  %t62 = add i64 %t59, %t58
  %t63 = urem i64 %t62, 4
  %t64 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t53, i32 0, i64 %t63
  br label %ring_rplace_end_12
ring_rplace_oob_11:
  %t66 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t66
  store i8* %t66, i8** %t65
  br label %ring_rplace_end_12
ring_rplace_end_12:
  %t67 = phi i8** [ %t64, %ring_rplace_ok_10 ], [ %t65, %ring_rplace_oob_11 ]
  %t68 = load i8*, i8** %t67
  %t69 = load i8*, i8** %t67
  call void @star_rc_retain(i8* %t69)
  call void @star_rc_release(i8* %t68)
  %t70 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t70, i8* %t68)
  %t71 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t2, i32 0, i32 0
  %t72 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t2, i32 0, i32 1
  %t73 = load i64, i64* %t72
  %t74 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t2, i32 0, i32 2
  %t75 = load i64, i64* %t74
  %t76 = sext i32 2 to i64
  %t77 = load i64, i64* %t72
  %t78 = load i64, i64* %t74
  %t79 = icmp ult i64 %t76, %t78
  br i1 %t79, label %ring_rplace_ok_13, label %ring_rplace_oob_14
ring_rplace_ok_13:
  %t80 = add i64 %t77, %t76
  %t81 = urem i64 %t80, 4
  %t82 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t71, i32 0, i64 %t81
  br label %ring_rplace_end_15
ring_rplace_oob_14:
  %t84 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t84
  store i8* %t84, i8** %t83
  br label %ring_rplace_end_15
ring_rplace_end_15:
  %t85 = phi i8** [ %t82, %ring_rplace_ok_13 ], [ %t83, %ring_rplace_oob_14 ]
  %t86 = load i8*, i8** %t85
  %t87 = load i8*, i8** %t85
  call void @star_rc_retain(i8* %t87)
  call void @star_rc_release(i8* %t86)
  %t88 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t88, i8* %t86)
  %t89 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t2, i32 0, i32 0
  %t90 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t2, i32 0, i32 1
  %t91 = load i64, i64* %t90
  %t92 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t2, i32 0, i32 2
  %t93 = load i64, i64* %t92
  %t94 = sext i32 3 to i64
  %t95 = load i64, i64* %t90
  %t96 = load i64, i64* %t92
  %t97 = icmp ult i64 %t94, %t96
  br i1 %t97, label %ring_rplace_ok_16, label %ring_rplace_oob_17
ring_rplace_ok_16:
  %t98 = add i64 %t95, %t94
  %t99 = urem i64 %t98, 4
  %t100 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t89, i32 0, i64 %t99
  br label %ring_rplace_end_18
ring_rplace_oob_17:
  %t102 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t102
  store i8* %t102, i8** %t101
  br label %ring_rplace_end_18
ring_rplace_end_18:
  %t103 = phi i8** [ %t100, %ring_rplace_ok_16 ], [ %t101, %ring_rplace_oob_17 ]
  %t104 = load i8*, i8** %t103
  %t105 = load i8*, i8** %t103
  call void @star_rc_retain(i8* %t105)
  call void @star_rc_release(i8* %t104)
  %t106 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t106, i8* %t104)
  store { [3 x i8*], i64, i64 } zeroinitializer, { [3 x i8*], i64, i64 }* %t107
  store i32 0, i32* %t108
  br label %while_cond_19
while_cond_19:
  %t109 = load i32, i32* %t108
  %t110 = icmp slt i32 %t109, 50000
  br i1 %t110, label %while_body_20, label %while_else_21
while_body_20:
  %t111 = load i32, i32* %t108
  %t112 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.6, i64 0, i64 0
  %t113 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t112, i32 %t111)
  %t114 = add i32 %t113, 1
  %t115 = sext i32 %t114 to i64
  %t116 = call i8* @star_rc_alloc(i64 %t115, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t116, i64 %t115, i8* %t112, i32 %t111)
  %t117 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t107, i32 0, i32 0
  %t118 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t107, i32 0, i32 1
  %t119 = load i64, i64* %t118
  %t120 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t107, i32 0, i32 2
  %t121 = load i64, i64* %t120
  %t122 = icmp sge i64 %t121, 3
  br i1 %t122, label %ring_push_full_23, label %ring_push_grow_24
ring_push_grow_24:
  %t123 = add i64 %t119, %t121
  %t124 = urem i64 %t123, 3
  %t125 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t117, i32 0, i64 %t124
  store i8* %t116, i8** %t125
  %t126 = add i64 %t121, 1
  store i64 %t126, i64* %t120
  br label %ring_push_done_25
ring_push_full_23:
  %t127 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t117, i32 0, i64 %t119
  %t128 = load i8*, i8** %t127
  call void @star_rc_release(i8* %t128)
  store i8* %t116, i8** %t127
  %t129 = add i64 %t119, 1
  %t130 = urem i64 %t129, 3
  store i64 %t130, i64* %t118
  br label %ring_push_done_25
ring_push_done_25:
  %t131 = load i32, i32* %t108
  %t132 = icmp eq i32 3, 0
  %t133 = icmp eq i32 %t131, -2147483648
  %t134 = icmp eq i32 3, -1
  %t135 = and i1 %t133, %t134
  %t136 = or i1 %t132, %t135
  br i1 %t136, label %int_div_fail_26, label %int_div_ok_27
int_div_fail_26:
  %t137 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.7, i64 0, i64 0
  call i32 @puts(i8* %t137)
  call void @exit(i32 1)
  unreachable
int_div_ok_27:
  %t138 = srem i32 %t131, 3
  %t139 = icmp eq i32 %t138, 0
  br i1 %t139, label %if_then_28, label %if_else_29
if_then_28:
  %t141 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t107, i32 0, i32 0
  %t142 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t107, i32 0, i32 1
  %t143 = load i64, i64* %t142
  %t144 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t107, i32 0, i32 2
  %t145 = load i64, i64* %t144
  %t146 = icmp eq i64 %t145, 0
  br i1 %t146, label %ring_pop_empty_31, label %ring_pop_nonempty_32
ring_pop_nonempty_32:
  %t147 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t141, i32 0, i64 %t143
  %t148 = load i8*, i8** %t147
  store i8* null, i8** %t147
  %t149 = add i64 %t143, 1
  %t150 = urem i64 %t149, 3
  store i64 %t150, i64* %t142
  %t151 = sub i64 %t145, 1
  store i64 %t151, i64* %t144
  br label %ring_pop_end_33
ring_pop_empty_31:
  %t152 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t152
  br label %ring_pop_end_33
ring_pop_end_33:
  %t153 = phi i8* [ %t148, %ring_pop_nonempty_32 ], [ %t152, %ring_pop_empty_31 ]
  store i8* %t153, i8** %t140
  %t154 = load i8*, i8** %t140
  %t155 = load i8*, i8** %t140
  call void @star_rc_retain(i8* %t155)
  %t156 = call i32 @strlen(i8* %t154)
  call void @star_rc_release(i8* %t154)
  %t157 = icmp eq i32 %t156, 0
  br i1 %t157, label %if_then_34, label %if_else_35
if_then_34:
  %t158 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.8, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t158)
  call i32 (i8*, ...) @printf(i8* %t158)
  %t159 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t159)
  br label %if_end_36
if_else_35:
  br label %if_end_36
if_end_36:
  %t160 = load i8*, i8** %t140
  call void @star_rc_release(i8* %t160)
  br label %if_end_30
if_else_29:
  br label %if_end_30
if_end_30:
  %t161 = load i32, i32* %t108
  %t162 = add i32 %t161, 1
  store i32 %t162, i32* %t108
  br label %while_cond_19
while_else_21:
  br label %while_end_22
while_end_22:
  %t163 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t107, i32 0, i32 0
  %t164 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t107, i32 0, i32 1
  %t165 = load i64, i64* %t164
  %t166 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t107, i32 0, i32 2
  %t167 = load i64, i64* %t166
  %t168 = trunc i64 %t167 to i32
  %t169 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t169, i32 %t168)
  %t170 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t107, i32 0, i32 0
  %t171 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t170, i32 0, i64 0
  %t172 = load i8*, i8** %t171
  call void @star_rc_release(i8* %t172)
  %t173 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t170, i32 0, i64 1
  %t174 = load i8*, i8** %t173
  call void @star_rc_release(i8* %t174)
  %t175 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t170, i32 0, i64 2
  %t176 = load i8*, i8** %t175
  call void @star_rc_release(i8* %t176)
  %t177 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t2, i32 0, i32 0
  %t178 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t177, i32 0, i64 0
  %t179 = load i8*, i8** %t178
  call void @star_rc_release(i8* %t179)
  %t180 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t177, i32 0, i64 1
  %t181 = load i8*, i8** %t180
  call void @star_rc_release(i8* %t181)
  %t182 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t177, i32 0, i64 2
  %t183 = load i8*, i8** %t182
  call void @star_rc_release(i8* %t183)
  %t184 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t177, i32 0, i64 3
  %t185 = load i8*, i8** %t184
  call void @star_rc_release(i8* %t185)
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
