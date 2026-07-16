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

%Player = type { i32, i8* }
define { i32, i32 } @min_max(i32 %a, i32 %b) {
entry:
  %t0 = alloca i32
  %t1 = alloca i32
  %t10 = alloca { i32, i32 }
  %t19 = alloca { i32, i32 }
  store i32 %a, i32* %t0
  store i32 %b, i32* %t1
  %t2 = load i32, i32* %t0
  %t3 = load i32, i32* %t1
  %t4 = icmp sle i32 %t2, %t3
  br label %match_scrutinee_6
match_scrutinee_6:
  %t9 = icmp eq i1 %t4, true
  br i1 %t9, label %match_then_0_7, label %match_next_0_8
match_then_0_7:
  %t11 = load i32, i32* %t0
  %t12 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t10, i32 0, i32 0
  store i32 %t11, i32* %t12
  %t13 = load i32, i32* %t1
  %t14 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t10, i32 0, i32 1
  store i32 %t13, i32* %t14
  %t15 = load { i32, i32 }, { i32, i32 }* %t10
  br label %match_end_5
match_next_0_8:
  %t18 = icmp eq i1 %t4, false
  br i1 %t18, label %match_then_1_16, label %match_next_1_17
match_then_1_16:
  %t20 = load i32, i32* %t1
  %t21 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t19, i32 0, i32 0
  store i32 %t20, i32* %t21
  %t22 = load i32, i32* %t0
  %t23 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t19, i32 0, i32 1
  store i32 %t22, i32* %t23
  %t24 = load { i32, i32 }, { i32, i32 }* %t19
  br label %match_end_5
match_next_1_17:
  br label %match_end_5
match_end_5:
  %t25 = phi { i32, i32 } [ %t15, %match_then_0_7 ], [ %t24, %match_then_1_16 ], [ undef, %match_next_1_17 ]
  ret { i32, i32 } %t25
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t0 = alloca { i32, i32 }
  %t1 = alloca { i32, i32 }
  %t16 = alloca { i32, i32 }
  %t23 = alloca { %Player, i8* }
  %t24 = alloca { %Player, i8* }
  %t25 = alloca %Player
  %t51 = alloca i32
  %t54 = alloca { i32 }
  %t55 = alloca { i32 }
  %t61 = alloca [5 x i32]
  %t62 = alloca [5 x i32]
  %t77 = alloca i32
  %t83 = alloca i32
  %t89 = alloca i32
  %t95 = alloca i32
  %t101 = alloca i32
  %t108 = alloca i32
  %t118 = alloca i32
  %t122 = alloca [3 x %Player]
  %t123 = alloca [3 x %Player]
  %t124 = alloca %Player
  %t140 = alloca %Player
  %t148 = alloca %Player
  %t154 = alloca %Player
  %t161 = alloca %Player
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t2 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1, i32 0, i32 0
  store i32 3, i32* %t2
  %t3 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1, i32 0, i32 1
  store i32 4, i32* %t3
  %t4 = load { i32, i32 }, { i32, i32 }* %t1
  store { i32, i32 } %t4, { i32, i32 }* %t0
  %t5 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t0, i32 0, i32 0
  %t6 = load i32, i32* %t5
  %t7 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t0, i32 0, i32 1
  %t8 = load i32, i32* %t7
  %t9 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t9, i32 %t6, i32 %t8)
  %t10 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t0, i32 0, i32 0
  store i32 10, i32* %t10
  %t11 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t0, i32 0, i32 0
  %t12 = load i32, i32* %t11
  %t13 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t0, i32 0, i32 1
  %t14 = load i32, i32* %t13
  %t15 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t15, i32 %t12, i32 %t14)
  %t17 = call { i32, i32 } @min_max(i32 7, i32 2)
  store { i32, i32 } %t17, { i32, i32 }* %t16
  %t18 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t16, i32 0, i32 0
  %t19 = load i32, i32* %t18
  %t20 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t16, i32 0, i32 1
  %t21 = load i32, i32* %t20
  %t22 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t22, i32 %t19, i32 %t21)
  %t26 = getelementptr inbounds %Player, %Player* %t25, i32 0, i32 0
  store i32 100, i32* %t26
  %t27 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t28 = getelementptr inbounds %Player, %Player* %t25, i32 0, i32 1
  store i8* %t27, i8** %t28
  %t29 = load %Player, %Player* %t25
  %t30 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t24, i32 0, i32 0
  store %Player %t29, %Player* %t30
  %t31 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t32 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t24, i32 0, i32 1
  store i8* %t31, i8** %t32
  %t33 = load { %Player, i8* }, { %Player, i8* }* %t24
  store { %Player, i8* } %t33, { %Player, i8* }* %t23
  %t34 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t23, i32 0, i32 0
  %t35 = getelementptr inbounds %Player, %Player* %t34, i32 0, i32 0
  %t36 = load i32, i32* %t35
  %t37 = sub i32 %t36, 25
  %t38 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t23, i32 0, i32 0
  %t39 = getelementptr inbounds %Player, %Player* %t38, i32 0, i32 0
  store i32 %t37, i32* %t39
  %t40 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t23, i32 0, i32 0
  %t41 = getelementptr inbounds %Player, %Player* %t40, i32 0, i32 1
  %t42 = load i8*, i8** %t41
  %t43 = load i8*, i8** %t41
  call void @star_rc_retain(i8* %t43)
  call void @star_rc_release(i8* %t42)
  %t44 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t23, i32 0, i32 0
  %t45 = getelementptr inbounds %Player, %Player* %t44, i32 0, i32 0
  %t46 = load i32, i32* %t45
  %t47 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t23, i32 0, i32 1
  %t48 = load i8*, i8** %t47
  %t49 = load i8*, i8** %t47
  call void @star_rc_retain(i8* %t49)
  call void @star_rc_release(i8* %t48)
  %t50 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t50, i8* %t42, i32 %t46, i8* %t48)
  store i32 5, i32* %t51
  %t52 = load i32, i32* %t51
  %t53 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t53, i32 %t52)
  %t56 = getelementptr inbounds { i32 }, { i32 }* %t55, i32 0, i32 0
  store i32 9, i32* %t56
  %t57 = load { i32 }, { i32 }* %t55
  store { i32 } %t57, { i32 }* %t54
  %t58 = getelementptr inbounds { i32 }, { i32 }* %t54, i32 0, i32 0
  %t59 = load i32, i32* %t58
  %t60 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t60, i32 %t59)
  %t63 = getelementptr inbounds [5 x i32], [5 x i32]* %t62, i32 0, i64 0
  store i32 0, i32* %t63
  %t64 = getelementptr inbounds [5 x i32], [5 x i32]* %t62, i32 0, i64 1
  store i32 0, i32* %t64
  %t65 = getelementptr inbounds [5 x i32], [5 x i32]* %t62, i32 0, i64 2
  store i32 0, i32* %t65
  %t66 = getelementptr inbounds [5 x i32], [5 x i32]* %t62, i32 0, i64 3
  store i32 0, i32* %t66
  %t67 = getelementptr inbounds [5 x i32], [5 x i32]* %t62, i32 0, i64 4
  store i32 0, i32* %t67
  %t68 = load [5 x i32], [5 x i32]* %t62
  store [5 x i32] %t68, [5 x i32]* %t61
  %t69 = load [5 x i32], [5 x i32]* %t61
  %t70 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t70, i32 5)
  %t71 = sext i32 2 to i64
  %t72 = icmp ult i64 %t71, 5
  br i1 %t72, label %arr_set_do_0, label %arr_set_oob_1
arr_set_do_0:
  %t73 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t71
  store i32 42, i32* %t73
  br label %arr_set_end_2
arr_set_oob_1:
  br label %arr_set_end_2
arr_set_end_2:
  %t74 = sext i32 0 to i64
  %t75 = icmp ult i64 %t74, 5
  br i1 %t75, label %arr_rplace_ok_3, label %arr_rplace_oob_4
arr_rplace_ok_3:
  %t76 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t74
  br label %arr_rplace_end_5
arr_rplace_oob_4:
  store i32 0, i32* %t77
  br label %arr_rplace_end_5
arr_rplace_end_5:
  %t78 = phi i32* [ %t76, %arr_rplace_ok_3 ], [ %t77, %arr_rplace_oob_4 ]
  %t79 = load i32, i32* %t78
  %t80 = sext i32 1 to i64
  %t81 = icmp ult i64 %t80, 5
  br i1 %t81, label %arr_rplace_ok_6, label %arr_rplace_oob_7
arr_rplace_ok_6:
  %t82 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t80
  br label %arr_rplace_end_8
arr_rplace_oob_7:
  store i32 0, i32* %t83
  br label %arr_rplace_end_8
arr_rplace_end_8:
  %t84 = phi i32* [ %t82, %arr_rplace_ok_6 ], [ %t83, %arr_rplace_oob_7 ]
  %t85 = load i32, i32* %t84
  %t86 = sext i32 2 to i64
  %t87 = icmp ult i64 %t86, 5
  br i1 %t87, label %arr_rplace_ok_9, label %arr_rplace_oob_10
arr_rplace_ok_9:
  %t88 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t86
  br label %arr_rplace_end_11
arr_rplace_oob_10:
  store i32 0, i32* %t89
  br label %arr_rplace_end_11
arr_rplace_end_11:
  %t90 = phi i32* [ %t88, %arr_rplace_ok_9 ], [ %t89, %arr_rplace_oob_10 ]
  %t91 = load i32, i32* %t90
  %t92 = sext i32 3 to i64
  %t93 = icmp ult i64 %t92, 5
  br i1 %t93, label %arr_rplace_ok_12, label %arr_rplace_oob_13
arr_rplace_ok_12:
  %t94 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t92
  br label %arr_rplace_end_14
arr_rplace_oob_13:
  store i32 0, i32* %t95
  br label %arr_rplace_end_14
arr_rplace_end_14:
  %t96 = phi i32* [ %t94, %arr_rplace_ok_12 ], [ %t95, %arr_rplace_oob_13 ]
  %t97 = load i32, i32* %t96
  %t98 = sext i32 4 to i64
  %t99 = icmp ult i64 %t98, 5
  br i1 %t99, label %arr_rplace_ok_15, label %arr_rplace_oob_16
arr_rplace_ok_15:
  %t100 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t98
  br label %arr_rplace_end_17
arr_rplace_oob_16:
  store i32 0, i32* %t101
  br label %arr_rplace_end_17
arr_rplace_end_17:
  %t102 = phi i32* [ %t100, %arr_rplace_ok_15 ], [ %t101, %arr_rplace_oob_16 ]
  %t103 = load i32, i32* %t102
  %t104 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t104, i32 %t79, i32 %t85, i32 %t91, i32 %t97, i32 %t103)
  %t105 = sext i32 99 to i64
  %t106 = icmp ult i64 %t105, 5
  br i1 %t106, label %arr_rplace_ok_18, label %arr_rplace_oob_19
arr_rplace_ok_18:
  %t107 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t105
  br label %arr_rplace_end_20
arr_rplace_oob_19:
  store i32 0, i32* %t108
  br label %arr_rplace_end_20
arr_rplace_end_20:
  %t109 = phi i32* [ %t107, %arr_rplace_ok_18 ], [ %t108, %arr_rplace_oob_19 ]
  %t110 = load i32, i32* %t109
  %t111 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t111, i32 %t110)
  %t112 = sext i32 99 to i64
  %t113 = icmp ult i64 %t112, 5
  br i1 %t113, label %arr_set_do_21, label %arr_set_oob_22
arr_set_do_21:
  %t114 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t112
  store i32 7, i32* %t114
  br label %arr_set_end_23
arr_set_oob_22:
  br label %arr_set_end_23
arr_set_end_23:
  %t115 = sext i32 2 to i64
  %t116 = icmp ult i64 %t115, 5
  br i1 %t116, label %arr_rplace_ok_24, label %arr_rplace_oob_25
arr_rplace_ok_24:
  %t117 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t115
  br label %arr_rplace_end_26
arr_rplace_oob_25:
  store i32 0, i32* %t118
  br label %arr_rplace_end_26
arr_rplace_end_26:
  %t119 = phi i32* [ %t117, %arr_rplace_ok_24 ], [ %t118, %arr_rplace_oob_25 ]
  %t120 = load i32, i32* %t119
  %t121 = getelementptr inbounds [54 x i8], [54 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t121, i32 %t120)
  %t125 = getelementptr inbounds %Player, %Player* %t124, i32 0, i32 0
  store i32 50, i32* %t125
  %t126 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.12, i64 0, i32 2, i64 0
  %t127 = getelementptr inbounds %Player, %Player* %t124, i32 0, i32 1
  store i8* %t126, i8** %t127
  %t128 = load %Player, %Player* %t124
  %t129 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t123, i32 0, i64 0
  store %Player %t128, %Player* %t129
  %t130 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t123, i32 0, i64 1
  store %Player %t128, %Player* %t130
  %t131 = getelementptr inbounds %Player, %Player* %t130, i32 0, i32 1
  %t132 = load i8*, i8** %t131
  call void @star_rc_retain(i8* %t132)
  %t133 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t123, i32 0, i64 2
  store %Player %t128, %Player* %t133
  %t134 = getelementptr inbounds %Player, %Player* %t133, i32 0, i32 1
  %t135 = load i8*, i8** %t134
  call void @star_rc_retain(i8* %t135)
  %t136 = load [3 x %Player], [3 x %Player]* %t123
  store [3 x %Player] %t136, [3 x %Player]* %t122
  %t137 = sext i32 0 to i64
  %t138 = icmp ult i64 %t137, 3
  br i1 %t138, label %arr_place_ok_27, label %arr_place_oob_28
arr_place_ok_27:
  %t139 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t122, i32 0, i64 %t137
  br label %arr_place_end_29
arr_place_oob_28:
  store %Player zeroinitializer, %Player* %t140
  br label %arr_place_end_29
arr_place_end_29:
  %t141 = phi %Player* [ %t139, %arr_place_ok_27 ], [ %t140, %arr_place_oob_28 ]
  %t142 = getelementptr inbounds %Player, %Player* %t141, i32 0, i32 0
  %t143 = load i32, i32* %t142
  %t144 = sub i32 %t143, 10
  %t145 = sext i32 0 to i64
  %t146 = icmp ult i64 %t145, 3
  br i1 %t146, label %arr_place_ok_30, label %arr_place_oob_31
arr_place_ok_30:
  %t147 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t122, i32 0, i64 %t145
  br label %arr_place_end_32
arr_place_oob_31:
  store %Player zeroinitializer, %Player* %t148
  br label %arr_place_end_32
arr_place_end_32:
  %t149 = phi %Player* [ %t147, %arr_place_ok_30 ], [ %t148, %arr_place_oob_31 ]
  %t150 = getelementptr inbounds %Player, %Player* %t149, i32 0, i32 0
  store i32 %t144, i32* %t150
  %t151 = sext i32 0 to i64
  %t152 = icmp ult i64 %t151, 3
  br i1 %t152, label %arr_rplace_ok_33, label %arr_rplace_oob_34
arr_rplace_ok_33:
  %t153 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t122, i32 0, i64 %t151
  br label %arr_rplace_end_35
arr_rplace_oob_34:
  store %Player zeroinitializer, %Player* %t154
  br label %arr_rplace_end_35
arr_rplace_end_35:
  %t155 = phi %Player* [ %t153, %arr_rplace_ok_33 ], [ %t154, %arr_rplace_oob_34 ]
  %t156 = getelementptr inbounds %Player, %Player* %t155, i32 0, i32 0
  %t157 = load i32, i32* %t156
  %t158 = sext i32 1 to i64
  %t159 = icmp ult i64 %t158, 3
  br i1 %t159, label %arr_rplace_ok_36, label %arr_rplace_oob_37
arr_rplace_ok_36:
  %t160 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t122, i32 0, i64 %t158
  br label %arr_rplace_end_38
arr_rplace_oob_37:
  store %Player zeroinitializer, %Player* %t161
  br label %arr_rplace_end_38
arr_rplace_end_38:
  %t162 = phi %Player* [ %t160, %arr_rplace_ok_36 ], [ %t161, %arr_rplace_oob_37 ]
  %t163 = getelementptr inbounds %Player, %Player* %t162, i32 0, i32 0
  %t164 = load i32, i32* %t163
  %t165 = getelementptr inbounds [39 x i8], [39 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t165, i32 %t157, i32 %t164)
  %t166 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t122, i32 0, i64 0
  %t167 = getelementptr inbounds %Player, %Player* %t166, i32 0, i32 1
  %t168 = load i8*, i8** %t167
  call void @star_rc_release(i8* %t168)
  %t169 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t122, i32 0, i64 1
  %t170 = getelementptr inbounds %Player, %Player* %t169, i32 0, i32 1
  %t171 = load i8*, i8** %t170
  call void @star_rc_release(i8* %t171)
  %t172 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t122, i32 0, i64 2
  %t173 = getelementptr inbounds %Player, %Player* %t172, i32 0, i32 1
  %t174 = load i8*, i8** %t173
  call void @star_rc_release(i8* %t174)
  %t175 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t23, i32 0, i32 0
  %t176 = getelementptr inbounds %Player, %Player* %t175, i32 0, i32 1
  %t177 = load i8*, i8** %t176
  call void @star_rc_release(i8* %t177)
  %t178 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t23, i32 0, i32 1
  %t179 = load i8*, i8** %t178
  call void @star_rc_release(i8* %t179)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [18 x i8] c"point = (%d, %d)\0A\00"
@.str.1 = private unnamed_addr constant [33 x i8] c"point after mutation = (%d, %d)\0A\00"
@.str.2 = private unnamed_addr constant [26 x i8] c"min_max(7, 2) = (%d, %d)\0A\00"
@.str.3 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"Hero\00" }
@.str.4 = private unnamed_addr constant { i64, i8*, [15 x i8] } { i64 -1, i8* null, [15 x i8] c"extra lives: 2\00" }
@.str.5 = private unnamed_addr constant [15 x i8] c"%s hp=%d (%s)\0A\00"
@.str.6 = private unnamed_addr constant [14 x i8] c"grouped = %d\0A\00"
@.str.7 = private unnamed_addr constant [12 x i8] c"one.0 = %d\0A\00"
@.str.8 = private unnamed_addr constant [19 x i8] c"scores.len() = %d\0A\00"
@.str.9 = private unnamed_addr constant [31 x i8] c"scores = [%d, %d, %d, %d, %d]\0A\00"
@.str.10 = private unnamed_addr constant [17 x i8] c"scores[99] = %d\0A\00"
@.str.11 = private unnamed_addr constant [54 x i8] c"scores[2] unaffected by the out-of-bounds write = %d\0A\00"
@.str.12 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"Grunt\00" }
@.str.13 = private unnamed_addr constant [39 x i8] c"party[0].health=%d party[1].health=%d\0A\00"
