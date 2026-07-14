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

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = alloca { [4 x i8*], i64, i64 }
  store { [4 x i8*], i64, i64 } zeroinitializer, { [4 x i8*], i64, i64 }* %t0
  %t1 = alloca i32
  store i32 0, i32* %t1
  br label %while_cond_0
while_cond_0:
  %t2 = load i32, i32* %t1
  %t3 = icmp slt i32 %t2, 200000
  br i1 %t3, label %while_body_1, label %while_else_2
while_body_1:
  %t4 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 0
  %t5 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 1
  %t6 = load i64, i64* %t5
  %t7 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 2
  %t8 = load i64, i64* %t7
  %t9 = load i32, i32* %t1
  %t10 = getelementptr inbounds [8 x i8], [8 x i8]* @.str.0, i64 0, i64 0
  %t11 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t10, i32 %t9)
  %t12 = add i32 %t11, 1
  %t13 = sext i32 %t12 to i64
  %t14 = call i8* @star_rc_alloc(i64 %t13, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t14, i64 %t13, i8* %t10, i32 %t9)
  %t15 = icmp sge i64 %t8, 4
  br i1 %t15, label %ring_push_full_4, label %ring_push_grow_5
ring_push_grow_5:
  %t16 = add i64 %t6, %t8
  %t17 = urem i64 %t16, 4
  %t18 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t4, i32 0, i64 %t17
  store i8* %t14, i8** %t18
  %t19 = add i64 %t8, 1
  store i64 %t19, i64* %t7
  br label %ring_push_done_6
ring_push_full_4:
  %t20 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t4, i32 0, i64 %t6
  %t21 = load i8*, i8** %t20
  call void @star_rc_release(i8* %t21)
  store i8* %t14, i8** %t20
  %t22 = add i64 %t6, 1
  %t23 = urem i64 %t22, 4
  store i64 %t23, i64* %t5
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
  %t39 = icmp ult i64 %t38, %t37
  br i1 %t39, label %ring_rplace_ok_7, label %ring_rplace_oob_8
ring_rplace_ok_7:
  %t40 = add i64 %t35, %t38
  %t41 = urem i64 %t40, 4
  %t42 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t33, i32 0, i64 %t41
  br label %ring_rplace_end_9
ring_rplace_oob_8:
  %t43 = alloca i8*
  store i8* null, i8** %t43
  br label %ring_rplace_end_9
ring_rplace_end_9:
  %t44 = phi i8** [ %t42, %ring_rplace_ok_7 ], [ %t43, %ring_rplace_oob_8 ]
  %t45 = load i8*, i8** %t44
  %t46 = load i8*, i8** %t44
  call void @star_rc_retain(i8* %t46)
  %t47 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t47, i8* %t45)
  %t48 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 0
  %t49 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 1
  %t50 = load i64, i64* %t49
  %t51 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 2
  %t52 = load i64, i64* %t51
  %t53 = sext i32 1 to i64
  %t54 = icmp ult i64 %t53, %t52
  br i1 %t54, label %ring_rplace_ok_10, label %ring_rplace_oob_11
ring_rplace_ok_10:
  %t55 = add i64 %t50, %t53
  %t56 = urem i64 %t55, 4
  %t57 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t48, i32 0, i64 %t56
  br label %ring_rplace_end_12
ring_rplace_oob_11:
  %t58 = alloca i8*
  store i8* null, i8** %t58
  br label %ring_rplace_end_12
ring_rplace_end_12:
  %t59 = phi i8** [ %t57, %ring_rplace_ok_10 ], [ %t58, %ring_rplace_oob_11 ]
  %t60 = load i8*, i8** %t59
  %t61 = load i8*, i8** %t59
  call void @star_rc_retain(i8* %t61)
  %t62 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t62, i8* %t60)
  %t63 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 0
  %t64 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 1
  %t65 = load i64, i64* %t64
  %t66 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 2
  %t67 = load i64, i64* %t66
  %t68 = sext i32 2 to i64
  %t69 = icmp ult i64 %t68, %t67
  br i1 %t69, label %ring_rplace_ok_13, label %ring_rplace_oob_14
ring_rplace_ok_13:
  %t70 = add i64 %t65, %t68
  %t71 = urem i64 %t70, 4
  %t72 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t63, i32 0, i64 %t71
  br label %ring_rplace_end_15
ring_rplace_oob_14:
  %t73 = alloca i8*
  store i8* null, i8** %t73
  br label %ring_rplace_end_15
ring_rplace_end_15:
  %t74 = phi i8** [ %t72, %ring_rplace_ok_13 ], [ %t73, %ring_rplace_oob_14 ]
  %t75 = load i8*, i8** %t74
  %t76 = load i8*, i8** %t74
  call void @star_rc_retain(i8* %t76)
  %t77 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t77, i8* %t75)
  %t78 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 0
  %t79 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 1
  %t80 = load i64, i64* %t79
  %t81 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 2
  %t82 = load i64, i64* %t81
  %t83 = sext i32 3 to i64
  %t84 = icmp ult i64 %t83, %t82
  br i1 %t84, label %ring_rplace_ok_16, label %ring_rplace_oob_17
ring_rplace_ok_16:
  %t85 = add i64 %t80, %t83
  %t86 = urem i64 %t85, 4
  %t87 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t78, i32 0, i64 %t86
  br label %ring_rplace_end_18
ring_rplace_oob_17:
  %t88 = alloca i8*
  store i8* null, i8** %t88
  br label %ring_rplace_end_18
ring_rplace_end_18:
  %t89 = phi i8** [ %t87, %ring_rplace_ok_16 ], [ %t88, %ring_rplace_oob_17 ]
  %t90 = load i8*, i8** %t89
  %t91 = load i8*, i8** %t89
  call void @star_rc_retain(i8* %t91)
  %t92 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t92, i8* %t90)
  %t93 = alloca { [3 x i8*], i64, i64 }
  store { [3 x i8*], i64, i64 } zeroinitializer, { [3 x i8*], i64, i64 }* %t93
  %t94 = alloca i32
  store i32 0, i32* %t94
  br label %while_cond_19
while_cond_19:
  %t95 = load i32, i32* %t94
  %t96 = icmp slt i32 %t95, 50000
  br i1 %t96, label %while_body_20, label %while_else_21
while_body_20:
  %t97 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t93, i32 0, i32 0
  %t98 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t93, i32 0, i32 1
  %t99 = load i64, i64* %t98
  %t100 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t93, i32 0, i32 2
  %t101 = load i64, i64* %t100
  %t102 = load i32, i32* %t94
  %t103 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.6, i64 0, i64 0
  %t104 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t103, i32 %t102)
  %t105 = add i32 %t104, 1
  %t106 = sext i32 %t105 to i64
  %t107 = call i8* @star_rc_alloc(i64 %t106, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t107, i64 %t106, i8* %t103, i32 %t102)
  %t108 = icmp sge i64 %t101, 3
  br i1 %t108, label %ring_push_full_23, label %ring_push_grow_24
ring_push_grow_24:
  %t109 = add i64 %t99, %t101
  %t110 = urem i64 %t109, 3
  %t111 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t97, i32 0, i64 %t110
  store i8* %t107, i8** %t111
  %t112 = add i64 %t101, 1
  store i64 %t112, i64* %t100
  br label %ring_push_done_25
ring_push_full_23:
  %t113 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t97, i32 0, i64 %t99
  %t114 = load i8*, i8** %t113
  call void @star_rc_release(i8* %t114)
  store i8* %t107, i8** %t113
  %t115 = add i64 %t99, 1
  %t116 = urem i64 %t115, 3
  store i64 %t116, i64* %t98
  br label %ring_push_done_25
ring_push_done_25:
  %t117 = load i32, i32* %t94
  %t118 = icmp eq i32 3, 0
  %t119 = icmp eq i32 %t117, -2147483648
  %t120 = icmp eq i32 3, -1
  %t121 = and i1 %t119, %t120
  %t122 = or i1 %t118, %t121
  br i1 %t122, label %int_div_fail_26, label %int_div_ok_27
int_div_fail_26:
  %t123 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.7, i64 0, i64 0
  call i32 @puts(i8* %t123)
  call void @exit(i32 1)
  unreachable
int_div_ok_27:
  %t124 = srem i32 %t117, 3
  %t125 = icmp eq i32 %t124, 0
  br i1 %t125, label %if_then_28, label %if_else_29
if_then_28:
  %t126 = alloca i8*
  %t127 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t93, i32 0, i32 0
  %t128 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t93, i32 0, i32 1
  %t129 = load i64, i64* %t128
  %t130 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t93, i32 0, i32 2
  %t131 = load i64, i64* %t130
  %t132 = icmp eq i64 %t131, 0
  br i1 %t132, label %ring_pop_empty_31, label %ring_pop_nonempty_32
ring_pop_nonempty_32:
  %t133 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t127, i32 0, i64 %t129
  %t134 = load i8*, i8** %t133
  store i8* null, i8** %t133
  %t135 = add i64 %t129, 1
  %t136 = urem i64 %t135, 3
  store i64 %t136, i64* %t128
  %t137 = sub i64 %t131, 1
  store i64 %t137, i64* %t130
  br label %ring_pop_end_33
ring_pop_empty_31:
  br label %ring_pop_end_33
ring_pop_end_33:
  %t138 = phi i8* [ %t134, %ring_pop_nonempty_32 ], [ null, %ring_pop_empty_31 ]
  store i8* %t138, i8** %t126
  %t139 = load i8*, i8** %t126
  %t140 = load i8*, i8** %t126
  call void @star_rc_retain(i8* %t140)
  call void @star_rc_release(i8* %t139)
  %t141 = call i32 @strlen(i8* %t139)
  %t142 = icmp eq i32 %t141, 0
  br i1 %t142, label %if_then_34, label %if_else_35
if_then_34:
  %t143 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.8, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t143)
  %t144 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t144)
  br label %if_end_36
if_else_35:
  br label %if_end_36
if_end_36:
  %t145 = load i8*, i8** %t126
  call void @star_rc_release(i8* %t145)
  br label %if_end_30
if_else_29:
  br label %if_end_30
if_end_30:
  %t146 = load i32, i32* %t94
  %t147 = add i32 %t146, 1
  store i32 %t147, i32* %t94
  br label %while_cond_19
while_else_21:
  br label %while_end_22
while_end_22:
  %t148 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t93, i32 0, i32 0
  %t149 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t93, i32 0, i32 1
  %t150 = load i64, i64* %t149
  %t151 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t93, i32 0, i32 2
  %t152 = load i64, i64* %t151
  %t153 = trunc i64 %t152 to i32
  %t154 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t154, i32 %t153)
  %t155 = getelementptr inbounds { [3 x i8*], i64, i64 }, { [3 x i8*], i64, i64 }* %t93, i32 0, i32 0
  %t156 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t155, i32 0, i64 0
  %t157 = load i8*, i8** %t156
  call void @star_rc_release(i8* %t157)
  %t158 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t155, i32 0, i64 1
  %t159 = load i8*, i8** %t158
  call void @star_rc_release(i8* %t159)
  %t160 = getelementptr inbounds [3 x i8*], [3 x i8*]* %t155, i32 0, i64 2
  %t161 = load i8*, i8** %t160
  call void @star_rc_release(i8* %t161)
  %t162 = getelementptr inbounds { [4 x i8*], i64, i64 }, { [4 x i8*], i64, i64 }* %t0, i32 0, i32 0
  %t163 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t162, i32 0, i64 0
  %t164 = load i8*, i8** %t163
  call void @star_rc_release(i8* %t164)
  %t165 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t162, i32 0, i64 1
  %t166 = load i8*, i8** %t165
  call void @star_rc_release(i8* %t166)
  %t167 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t162, i32 0, i64 2
  %t168 = load i8*, i8** %t167
  call void @star_rc_release(i8* %t168)
  %t169 = getelementptr inbounds [4 x i8*], [4 x i8*]* %t162, i32 0, i64 3
  %t170 = load i8*, i8** %t169
  call void @star_rc_release(i8* %t170)
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
