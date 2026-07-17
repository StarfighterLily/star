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
  %t2 = alloca { i32, i32 }
  %t3 = alloca { i32, i32 }
  %t18 = alloca { i32, i32 }
  %t25 = alloca { %Player, i8* }
  %t26 = alloca { %Player, i8* }
  %t27 = alloca %Player
  %t53 = alloca i32
  %t56 = alloca { i32 }
  %t57 = alloca { i32 }
  %t63 = alloca [5 x i32]
  %t64 = alloca [5 x i32]
  %t79 = alloca i32
  %t85 = alloca i32
  %t91 = alloca i32
  %t97 = alloca i32
  %t103 = alloca i32
  %t110 = alloca i32
  %t120 = alloca i32
  %t124 = alloca [3 x %Player]
  %t125 = alloca [3 x %Player]
  %t126 = alloca %Player
  %t142 = alloca %Player
  %t150 = alloca %Player
  %t156 = alloca %Player
  %t163 = alloca %Player
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t4 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t3, i32 0, i32 0
  store i32 3, i32* %t4
  %t5 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t3, i32 0, i32 1
  store i32 4, i32* %t5
  %t6 = load { i32, i32 }, { i32, i32 }* %t3
  store { i32, i32 } %t6, { i32, i32 }* %t2
  %t7 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t2, i32 0, i32 0
  %t8 = load i32, i32* %t7
  %t9 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t2, i32 0, i32 1
  %t10 = load i32, i32* %t9
  %t11 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t11, i32 %t8, i32 %t10)
  %t12 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t2, i32 0, i32 0
  store i32 10, i32* %t12
  %t13 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t2, i32 0, i32 0
  %t14 = load i32, i32* %t13
  %t15 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t2, i32 0, i32 1
  %t16 = load i32, i32* %t15
  %t17 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t17, i32 %t14, i32 %t16)
  %t19 = call { i32, i32 } @min_max(i32 7, i32 2)
  store { i32, i32 } %t19, { i32, i32 }* %t18
  %t20 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t18, i32 0, i32 0
  %t21 = load i32, i32* %t20
  %t22 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t18, i32 0, i32 1
  %t23 = load i32, i32* %t22
  %t24 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t24, i32 %t21, i32 %t23)
  %t28 = getelementptr inbounds %Player, %Player* %t27, i32 0, i32 0
  store i32 100, i32* %t28
  %t29 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t30 = getelementptr inbounds %Player, %Player* %t27, i32 0, i32 1
  store i8* %t29, i8** %t30
  %t31 = load %Player, %Player* %t27
  %t32 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t26, i32 0, i32 0
  store %Player %t31, %Player* %t32
  %t33 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t34 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t26, i32 0, i32 1
  store i8* %t33, i8** %t34
  %t35 = load { %Player, i8* }, { %Player, i8* }* %t26
  store { %Player, i8* } %t35, { %Player, i8* }* %t25
  %t36 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t25, i32 0, i32 0
  %t37 = getelementptr inbounds %Player, %Player* %t36, i32 0, i32 0
  %t38 = load i32, i32* %t37
  %t39 = sub i32 %t38, 25
  %t40 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t25, i32 0, i32 0
  %t41 = getelementptr inbounds %Player, %Player* %t40, i32 0, i32 0
  store i32 %t39, i32* %t41
  %t42 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t25, i32 0, i32 0
  %t43 = getelementptr inbounds %Player, %Player* %t42, i32 0, i32 1
  %t44 = load i8*, i8** %t43
  %t45 = load i8*, i8** %t43
  call void @star_rc_retain(i8* %t45)
  call void @star_rc_release(i8* %t44)
  %t46 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t25, i32 0, i32 0
  %t47 = getelementptr inbounds %Player, %Player* %t46, i32 0, i32 0
  %t48 = load i32, i32* %t47
  %t49 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t25, i32 0, i32 1
  %t50 = load i8*, i8** %t49
  %t51 = load i8*, i8** %t49
  call void @star_rc_retain(i8* %t51)
  call void @star_rc_release(i8* %t50)
  %t52 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t52, i8* %t44, i32 %t48, i8* %t50)
  store i32 5, i32* %t53
  %t54 = load i32, i32* %t53
  %t55 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t55, i32 %t54)
  %t58 = getelementptr inbounds { i32 }, { i32 }* %t57, i32 0, i32 0
  store i32 9, i32* %t58
  %t59 = load { i32 }, { i32 }* %t57
  store { i32 } %t59, { i32 }* %t56
  %t60 = getelementptr inbounds { i32 }, { i32 }* %t56, i32 0, i32 0
  %t61 = load i32, i32* %t60
  %t62 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t62, i32 %t61)
  %t65 = getelementptr inbounds [5 x i32], [5 x i32]* %t64, i32 0, i64 0
  store i32 0, i32* %t65
  %t66 = getelementptr inbounds [5 x i32], [5 x i32]* %t64, i32 0, i64 1
  store i32 0, i32* %t66
  %t67 = getelementptr inbounds [5 x i32], [5 x i32]* %t64, i32 0, i64 2
  store i32 0, i32* %t67
  %t68 = getelementptr inbounds [5 x i32], [5 x i32]* %t64, i32 0, i64 3
  store i32 0, i32* %t68
  %t69 = getelementptr inbounds [5 x i32], [5 x i32]* %t64, i32 0, i64 4
  store i32 0, i32* %t69
  %t70 = load [5 x i32], [5 x i32]* %t64
  store [5 x i32] %t70, [5 x i32]* %t63
  %t71 = load [5 x i32], [5 x i32]* %t63
  %t72 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t72, i32 5)
  %t73 = sext i32 2 to i64
  %t74 = icmp ult i64 %t73, 5
  br i1 %t74, label %arr_set_do_0, label %arr_set_oob_1
arr_set_do_0:
  %t75 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t73
  store i32 42, i32* %t75
  br label %arr_set_end_2
arr_set_oob_1:
  br label %arr_set_end_2
arr_set_end_2:
  %t76 = sext i32 0 to i64
  %t77 = icmp ult i64 %t76, 5
  br i1 %t77, label %arr_rplace_ok_3, label %arr_rplace_oob_4
arr_rplace_ok_3:
  %t78 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t76
  br label %arr_rplace_end_5
arr_rplace_oob_4:
  store i32 0, i32* %t79
  br label %arr_rplace_end_5
arr_rplace_end_5:
  %t80 = phi i32* [ %t78, %arr_rplace_ok_3 ], [ %t79, %arr_rplace_oob_4 ]
  %t81 = load i32, i32* %t80
  %t82 = sext i32 1 to i64
  %t83 = icmp ult i64 %t82, 5
  br i1 %t83, label %arr_rplace_ok_6, label %arr_rplace_oob_7
arr_rplace_ok_6:
  %t84 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t82
  br label %arr_rplace_end_8
arr_rplace_oob_7:
  store i32 0, i32* %t85
  br label %arr_rplace_end_8
arr_rplace_end_8:
  %t86 = phi i32* [ %t84, %arr_rplace_ok_6 ], [ %t85, %arr_rplace_oob_7 ]
  %t87 = load i32, i32* %t86
  %t88 = sext i32 2 to i64
  %t89 = icmp ult i64 %t88, 5
  br i1 %t89, label %arr_rplace_ok_9, label %arr_rplace_oob_10
arr_rplace_ok_9:
  %t90 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t88
  br label %arr_rplace_end_11
arr_rplace_oob_10:
  store i32 0, i32* %t91
  br label %arr_rplace_end_11
arr_rplace_end_11:
  %t92 = phi i32* [ %t90, %arr_rplace_ok_9 ], [ %t91, %arr_rplace_oob_10 ]
  %t93 = load i32, i32* %t92
  %t94 = sext i32 3 to i64
  %t95 = icmp ult i64 %t94, 5
  br i1 %t95, label %arr_rplace_ok_12, label %arr_rplace_oob_13
arr_rplace_ok_12:
  %t96 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t94
  br label %arr_rplace_end_14
arr_rplace_oob_13:
  store i32 0, i32* %t97
  br label %arr_rplace_end_14
arr_rplace_end_14:
  %t98 = phi i32* [ %t96, %arr_rplace_ok_12 ], [ %t97, %arr_rplace_oob_13 ]
  %t99 = load i32, i32* %t98
  %t100 = sext i32 4 to i64
  %t101 = icmp ult i64 %t100, 5
  br i1 %t101, label %arr_rplace_ok_15, label %arr_rplace_oob_16
arr_rplace_ok_15:
  %t102 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t100
  br label %arr_rplace_end_17
arr_rplace_oob_16:
  store i32 0, i32* %t103
  br label %arr_rplace_end_17
arr_rplace_end_17:
  %t104 = phi i32* [ %t102, %arr_rplace_ok_15 ], [ %t103, %arr_rplace_oob_16 ]
  %t105 = load i32, i32* %t104
  %t106 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t106, i32 %t81, i32 %t87, i32 %t93, i32 %t99, i32 %t105)
  %t107 = sext i32 99 to i64
  %t108 = icmp ult i64 %t107, 5
  br i1 %t108, label %arr_rplace_ok_18, label %arr_rplace_oob_19
arr_rplace_ok_18:
  %t109 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t107
  br label %arr_rplace_end_20
arr_rplace_oob_19:
  store i32 0, i32* %t110
  br label %arr_rplace_end_20
arr_rplace_end_20:
  %t111 = phi i32* [ %t109, %arr_rplace_ok_18 ], [ %t110, %arr_rplace_oob_19 ]
  %t112 = load i32, i32* %t111
  %t113 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t113, i32 %t112)
  %t114 = sext i32 99 to i64
  %t115 = icmp ult i64 %t114, 5
  br i1 %t115, label %arr_set_do_21, label %arr_set_oob_22
arr_set_do_21:
  %t116 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t114
  store i32 7, i32* %t116
  br label %arr_set_end_23
arr_set_oob_22:
  br label %arr_set_end_23
arr_set_end_23:
  %t117 = sext i32 2 to i64
  %t118 = icmp ult i64 %t117, 5
  br i1 %t118, label %arr_rplace_ok_24, label %arr_rplace_oob_25
arr_rplace_ok_24:
  %t119 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t117
  br label %arr_rplace_end_26
arr_rplace_oob_25:
  store i32 0, i32* %t120
  br label %arr_rplace_end_26
arr_rplace_end_26:
  %t121 = phi i32* [ %t119, %arr_rplace_ok_24 ], [ %t120, %arr_rplace_oob_25 ]
  %t122 = load i32, i32* %t121
  %t123 = getelementptr inbounds [54 x i8], [54 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t123, i32 %t122)
  %t127 = getelementptr inbounds %Player, %Player* %t126, i32 0, i32 0
  store i32 50, i32* %t127
  %t128 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.12, i64 0, i32 2, i64 0
  %t129 = getelementptr inbounds %Player, %Player* %t126, i32 0, i32 1
  store i8* %t128, i8** %t129
  %t130 = load %Player, %Player* %t126
  %t131 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t125, i32 0, i64 0
  store %Player %t130, %Player* %t131
  %t132 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t125, i32 0, i64 1
  store %Player %t130, %Player* %t132
  %t133 = getelementptr inbounds %Player, %Player* %t132, i32 0, i32 1
  %t134 = load i8*, i8** %t133
  call void @star_rc_retain(i8* %t134)
  %t135 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t125, i32 0, i64 2
  store %Player %t130, %Player* %t135
  %t136 = getelementptr inbounds %Player, %Player* %t135, i32 0, i32 1
  %t137 = load i8*, i8** %t136
  call void @star_rc_retain(i8* %t137)
  %t138 = load [3 x %Player], [3 x %Player]* %t125
  store [3 x %Player] %t138, [3 x %Player]* %t124
  %t139 = sext i32 0 to i64
  %t140 = icmp ult i64 %t139, 3
  br i1 %t140, label %arr_place_ok_27, label %arr_place_oob_28
arr_place_ok_27:
  %t141 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t124, i32 0, i64 %t139
  br label %arr_place_end_29
arr_place_oob_28:
  store %Player zeroinitializer, %Player* %t142
  br label %arr_place_end_29
arr_place_end_29:
  %t143 = phi %Player* [ %t141, %arr_place_ok_27 ], [ %t142, %arr_place_oob_28 ]
  %t144 = getelementptr inbounds %Player, %Player* %t143, i32 0, i32 0
  %t145 = load i32, i32* %t144
  %t146 = sub i32 %t145, 10
  %t147 = sext i32 0 to i64
  %t148 = icmp ult i64 %t147, 3
  br i1 %t148, label %arr_place_ok_30, label %arr_place_oob_31
arr_place_ok_30:
  %t149 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t124, i32 0, i64 %t147
  br label %arr_place_end_32
arr_place_oob_31:
  store %Player zeroinitializer, %Player* %t150
  br label %arr_place_end_32
arr_place_end_32:
  %t151 = phi %Player* [ %t149, %arr_place_ok_30 ], [ %t150, %arr_place_oob_31 ]
  %t152 = getelementptr inbounds %Player, %Player* %t151, i32 0, i32 0
  store i32 %t146, i32* %t152
  %t153 = sext i32 0 to i64
  %t154 = icmp ult i64 %t153, 3
  br i1 %t154, label %arr_rplace_ok_33, label %arr_rplace_oob_34
arr_rplace_ok_33:
  %t155 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t124, i32 0, i64 %t153
  br label %arr_rplace_end_35
arr_rplace_oob_34:
  store %Player zeroinitializer, %Player* %t156
  br label %arr_rplace_end_35
arr_rplace_end_35:
  %t157 = phi %Player* [ %t155, %arr_rplace_ok_33 ], [ %t156, %arr_rplace_oob_34 ]
  %t158 = getelementptr inbounds %Player, %Player* %t157, i32 0, i32 0
  %t159 = load i32, i32* %t158
  %t160 = sext i32 1 to i64
  %t161 = icmp ult i64 %t160, 3
  br i1 %t161, label %arr_rplace_ok_36, label %arr_rplace_oob_37
arr_rplace_ok_36:
  %t162 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t124, i32 0, i64 %t160
  br label %arr_rplace_end_38
arr_rplace_oob_37:
  store %Player zeroinitializer, %Player* %t163
  br label %arr_rplace_end_38
arr_rplace_end_38:
  %t164 = phi %Player* [ %t162, %arr_rplace_ok_36 ], [ %t163, %arr_rplace_oob_37 ]
  %t165 = getelementptr inbounds %Player, %Player* %t164, i32 0, i32 0
  %t166 = load i32, i32* %t165
  %t167 = getelementptr inbounds [39 x i8], [39 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t167, i32 %t159, i32 %t166)
  %t168 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t124, i32 0, i64 0
  %t169 = getelementptr inbounds %Player, %Player* %t168, i32 0, i32 1
  %t170 = load i8*, i8** %t169
  call void @star_rc_release(i8* %t170)
  %t171 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t124, i32 0, i64 1
  %t172 = getelementptr inbounds %Player, %Player* %t171, i32 0, i32 1
  %t173 = load i8*, i8** %t172
  call void @star_rc_release(i8* %t173)
  %t174 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t124, i32 0, i64 2
  %t175 = getelementptr inbounds %Player, %Player* %t174, i32 0, i32 1
  %t176 = load i8*, i8** %t175
  call void @star_rc_release(i8* %t176)
  %t177 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t25, i32 0, i32 0
  %t178 = getelementptr inbounds %Player, %Player* %t177, i32 0, i32 1
  %t179 = load i8*, i8** %t178
  call void @star_rc_release(i8* %t179)
  %t180 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t25, i32 0, i32 1
  %t181 = load i8*, i8** %t180
  call void @star_rc_release(i8* %t181)
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
