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
  %t1 = alloca { i32, i32 }
  %t2 = alloca { i32, i32 }
  %t17 = alloca { i32, i32 }
  %t24 = alloca { %Player, i8* }
  %t25 = alloca { %Player, i8* }
  %t26 = alloca %Player
  %t52 = alloca i32
  %t55 = alloca { i32 }
  %t56 = alloca { i32 }
  %t62 = alloca [5 x i32]
  %t63 = alloca [5 x i32]
  %t78 = alloca i32
  %t84 = alloca i32
  %t90 = alloca i32
  %t96 = alloca i32
  %t102 = alloca i32
  %t109 = alloca i32
  %t119 = alloca i32
  %t123 = alloca [3 x %Player]
  %t124 = alloca [3 x %Player]
  %t125 = alloca %Player
  %t141 = alloca %Player
  %t149 = alloca %Player
  %t155 = alloca %Player
  %t162 = alloca %Player
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t3 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t2, i32 0, i32 0
  store i32 3, i32* %t3
  %t4 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t2, i32 0, i32 1
  store i32 4, i32* %t4
  %t5 = load { i32, i32 }, { i32, i32 }* %t2
  store { i32, i32 } %t5, { i32, i32 }* %t1
  %t6 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1, i32 0, i32 0
  %t7 = load i32, i32* %t6
  %t8 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1, i32 0, i32 1
  %t9 = load i32, i32* %t8
  %t10 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t10, i32 %t7, i32 %t9)
  %t11 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1, i32 0, i32 0
  store i32 10, i32* %t11
  %t12 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1, i32 0, i32 0
  %t13 = load i32, i32* %t12
  %t14 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1, i32 0, i32 1
  %t15 = load i32, i32* %t14
  %t16 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t16, i32 %t13, i32 %t15)
  %t18 = call { i32, i32 } @min_max(i32 7, i32 2)
  store { i32, i32 } %t18, { i32, i32 }* %t17
  %t19 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t17, i32 0, i32 0
  %t20 = load i32, i32* %t19
  %t21 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t17, i32 0, i32 1
  %t22 = load i32, i32* %t21
  %t23 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t23, i32 %t20, i32 %t22)
  %t27 = getelementptr inbounds %Player, %Player* %t26, i32 0, i32 0
  store i32 100, i32* %t27
  %t28 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t29 = getelementptr inbounds %Player, %Player* %t26, i32 0, i32 1
  store i8* %t28, i8** %t29
  %t30 = load %Player, %Player* %t26
  %t31 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t25, i32 0, i32 0
  store %Player %t30, %Player* %t31
  %t32 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t33 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t25, i32 0, i32 1
  store i8* %t32, i8** %t33
  %t34 = load { %Player, i8* }, { %Player, i8* }* %t25
  store { %Player, i8* } %t34, { %Player, i8* }* %t24
  %t35 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t24, i32 0, i32 0
  %t36 = getelementptr inbounds %Player, %Player* %t35, i32 0, i32 0
  %t37 = load i32, i32* %t36
  %t38 = sub i32 %t37, 25
  %t39 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t24, i32 0, i32 0
  %t40 = getelementptr inbounds %Player, %Player* %t39, i32 0, i32 0
  store i32 %t38, i32* %t40
  %t41 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t24, i32 0, i32 0
  %t42 = getelementptr inbounds %Player, %Player* %t41, i32 0, i32 1
  %t43 = load i8*, i8** %t42
  %t44 = load i8*, i8** %t42
  call void @star_rc_retain(i8* %t44)
  call void @star_rc_release(i8* %t43)
  %t45 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t24, i32 0, i32 0
  %t46 = getelementptr inbounds %Player, %Player* %t45, i32 0, i32 0
  %t47 = load i32, i32* %t46
  %t48 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t24, i32 0, i32 1
  %t49 = load i8*, i8** %t48
  %t50 = load i8*, i8** %t48
  call void @star_rc_retain(i8* %t50)
  call void @star_rc_release(i8* %t49)
  %t51 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t51, i8* %t43, i32 %t47, i8* %t49)
  store i32 5, i32* %t52
  %t53 = load i32, i32* %t52
  %t54 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t54, i32 %t53)
  %t57 = getelementptr inbounds { i32 }, { i32 }* %t56, i32 0, i32 0
  store i32 9, i32* %t57
  %t58 = load { i32 }, { i32 }* %t56
  store { i32 } %t58, { i32 }* %t55
  %t59 = getelementptr inbounds { i32 }, { i32 }* %t55, i32 0, i32 0
  %t60 = load i32, i32* %t59
  %t61 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t61, i32 %t60)
  %t64 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 0
  store i32 0, i32* %t64
  %t65 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 1
  store i32 0, i32* %t65
  %t66 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 2
  store i32 0, i32* %t66
  %t67 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 3
  store i32 0, i32* %t67
  %t68 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 4
  store i32 0, i32* %t68
  %t69 = load [5 x i32], [5 x i32]* %t63
  store [5 x i32] %t69, [5 x i32]* %t62
  %t70 = load [5 x i32], [5 x i32]* %t62
  %t71 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t71, i32 5)
  %t72 = sext i32 2 to i64
  %t73 = icmp ult i64 %t72, 5
  br i1 %t73, label %arr_set_do_0, label %arr_set_oob_1
arr_set_do_0:
  %t74 = getelementptr inbounds [5 x i32], [5 x i32]* %t62, i32 0, i64 %t72
  store i32 42, i32* %t74
  br label %arr_set_end_2
arr_set_oob_1:
  br label %arr_set_end_2
arr_set_end_2:
  %t75 = sext i32 0 to i64
  %t76 = icmp ult i64 %t75, 5
  br i1 %t76, label %arr_rplace_ok_3, label %arr_rplace_oob_4
arr_rplace_ok_3:
  %t77 = getelementptr inbounds [5 x i32], [5 x i32]* %t62, i32 0, i64 %t75
  br label %arr_rplace_end_5
arr_rplace_oob_4:
  store i32 0, i32* %t78
  br label %arr_rplace_end_5
arr_rplace_end_5:
  %t79 = phi i32* [ %t77, %arr_rplace_ok_3 ], [ %t78, %arr_rplace_oob_4 ]
  %t80 = load i32, i32* %t79
  %t81 = sext i32 1 to i64
  %t82 = icmp ult i64 %t81, 5
  br i1 %t82, label %arr_rplace_ok_6, label %arr_rplace_oob_7
arr_rplace_ok_6:
  %t83 = getelementptr inbounds [5 x i32], [5 x i32]* %t62, i32 0, i64 %t81
  br label %arr_rplace_end_8
arr_rplace_oob_7:
  store i32 0, i32* %t84
  br label %arr_rplace_end_8
arr_rplace_end_8:
  %t85 = phi i32* [ %t83, %arr_rplace_ok_6 ], [ %t84, %arr_rplace_oob_7 ]
  %t86 = load i32, i32* %t85
  %t87 = sext i32 2 to i64
  %t88 = icmp ult i64 %t87, 5
  br i1 %t88, label %arr_rplace_ok_9, label %arr_rplace_oob_10
arr_rplace_ok_9:
  %t89 = getelementptr inbounds [5 x i32], [5 x i32]* %t62, i32 0, i64 %t87
  br label %arr_rplace_end_11
arr_rplace_oob_10:
  store i32 0, i32* %t90
  br label %arr_rplace_end_11
arr_rplace_end_11:
  %t91 = phi i32* [ %t89, %arr_rplace_ok_9 ], [ %t90, %arr_rplace_oob_10 ]
  %t92 = load i32, i32* %t91
  %t93 = sext i32 3 to i64
  %t94 = icmp ult i64 %t93, 5
  br i1 %t94, label %arr_rplace_ok_12, label %arr_rplace_oob_13
arr_rplace_ok_12:
  %t95 = getelementptr inbounds [5 x i32], [5 x i32]* %t62, i32 0, i64 %t93
  br label %arr_rplace_end_14
arr_rplace_oob_13:
  store i32 0, i32* %t96
  br label %arr_rplace_end_14
arr_rplace_end_14:
  %t97 = phi i32* [ %t95, %arr_rplace_ok_12 ], [ %t96, %arr_rplace_oob_13 ]
  %t98 = load i32, i32* %t97
  %t99 = sext i32 4 to i64
  %t100 = icmp ult i64 %t99, 5
  br i1 %t100, label %arr_rplace_ok_15, label %arr_rplace_oob_16
arr_rplace_ok_15:
  %t101 = getelementptr inbounds [5 x i32], [5 x i32]* %t62, i32 0, i64 %t99
  br label %arr_rplace_end_17
arr_rplace_oob_16:
  store i32 0, i32* %t102
  br label %arr_rplace_end_17
arr_rplace_end_17:
  %t103 = phi i32* [ %t101, %arr_rplace_ok_15 ], [ %t102, %arr_rplace_oob_16 ]
  %t104 = load i32, i32* %t103
  %t105 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t105, i32 %t80, i32 %t86, i32 %t92, i32 %t98, i32 %t104)
  %t106 = sext i32 99 to i64
  %t107 = icmp ult i64 %t106, 5
  br i1 %t107, label %arr_rplace_ok_18, label %arr_rplace_oob_19
arr_rplace_ok_18:
  %t108 = getelementptr inbounds [5 x i32], [5 x i32]* %t62, i32 0, i64 %t106
  br label %arr_rplace_end_20
arr_rplace_oob_19:
  store i32 0, i32* %t109
  br label %arr_rplace_end_20
arr_rplace_end_20:
  %t110 = phi i32* [ %t108, %arr_rplace_ok_18 ], [ %t109, %arr_rplace_oob_19 ]
  %t111 = load i32, i32* %t110
  %t112 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t112, i32 %t111)
  %t113 = sext i32 99 to i64
  %t114 = icmp ult i64 %t113, 5
  br i1 %t114, label %arr_set_do_21, label %arr_set_oob_22
arr_set_do_21:
  %t115 = getelementptr inbounds [5 x i32], [5 x i32]* %t62, i32 0, i64 %t113
  store i32 7, i32* %t115
  br label %arr_set_end_23
arr_set_oob_22:
  br label %arr_set_end_23
arr_set_end_23:
  %t116 = sext i32 2 to i64
  %t117 = icmp ult i64 %t116, 5
  br i1 %t117, label %arr_rplace_ok_24, label %arr_rplace_oob_25
arr_rplace_ok_24:
  %t118 = getelementptr inbounds [5 x i32], [5 x i32]* %t62, i32 0, i64 %t116
  br label %arr_rplace_end_26
arr_rplace_oob_25:
  store i32 0, i32* %t119
  br label %arr_rplace_end_26
arr_rplace_end_26:
  %t120 = phi i32* [ %t118, %arr_rplace_ok_24 ], [ %t119, %arr_rplace_oob_25 ]
  %t121 = load i32, i32* %t120
  %t122 = getelementptr inbounds [54 x i8], [54 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t122, i32 %t121)
  %t126 = getelementptr inbounds %Player, %Player* %t125, i32 0, i32 0
  store i32 50, i32* %t126
  %t127 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.12, i64 0, i32 2, i64 0
  %t128 = getelementptr inbounds %Player, %Player* %t125, i32 0, i32 1
  store i8* %t127, i8** %t128
  %t129 = load %Player, %Player* %t125
  %t130 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t124, i32 0, i64 0
  store %Player %t129, %Player* %t130
  %t131 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t124, i32 0, i64 1
  store %Player %t129, %Player* %t131
  %t132 = getelementptr inbounds %Player, %Player* %t131, i32 0, i32 1
  %t133 = load i8*, i8** %t132
  call void @star_rc_retain(i8* %t133)
  %t134 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t124, i32 0, i64 2
  store %Player %t129, %Player* %t134
  %t135 = getelementptr inbounds %Player, %Player* %t134, i32 0, i32 1
  %t136 = load i8*, i8** %t135
  call void @star_rc_retain(i8* %t136)
  %t137 = load [3 x %Player], [3 x %Player]* %t124
  store [3 x %Player] %t137, [3 x %Player]* %t123
  %t138 = sext i32 0 to i64
  %t139 = icmp ult i64 %t138, 3
  br i1 %t139, label %arr_place_ok_27, label %arr_place_oob_28
arr_place_ok_27:
  %t140 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t123, i32 0, i64 %t138
  br label %arr_place_end_29
arr_place_oob_28:
  store %Player zeroinitializer, %Player* %t141
  br label %arr_place_end_29
arr_place_end_29:
  %t142 = phi %Player* [ %t140, %arr_place_ok_27 ], [ %t141, %arr_place_oob_28 ]
  %t143 = getelementptr inbounds %Player, %Player* %t142, i32 0, i32 0
  %t144 = load i32, i32* %t143
  %t145 = sub i32 %t144, 10
  %t146 = sext i32 0 to i64
  %t147 = icmp ult i64 %t146, 3
  br i1 %t147, label %arr_place_ok_30, label %arr_place_oob_31
arr_place_ok_30:
  %t148 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t123, i32 0, i64 %t146
  br label %arr_place_end_32
arr_place_oob_31:
  store %Player zeroinitializer, %Player* %t149
  br label %arr_place_end_32
arr_place_end_32:
  %t150 = phi %Player* [ %t148, %arr_place_ok_30 ], [ %t149, %arr_place_oob_31 ]
  %t151 = getelementptr inbounds %Player, %Player* %t150, i32 0, i32 0
  store i32 %t145, i32* %t151
  %t152 = sext i32 0 to i64
  %t153 = icmp ult i64 %t152, 3
  br i1 %t153, label %arr_rplace_ok_33, label %arr_rplace_oob_34
arr_rplace_ok_33:
  %t154 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t123, i32 0, i64 %t152
  br label %arr_rplace_end_35
arr_rplace_oob_34:
  store %Player zeroinitializer, %Player* %t155
  br label %arr_rplace_end_35
arr_rplace_end_35:
  %t156 = phi %Player* [ %t154, %arr_rplace_ok_33 ], [ %t155, %arr_rplace_oob_34 ]
  %t157 = getelementptr inbounds %Player, %Player* %t156, i32 0, i32 0
  %t158 = load i32, i32* %t157
  %t159 = sext i32 1 to i64
  %t160 = icmp ult i64 %t159, 3
  br i1 %t160, label %arr_rplace_ok_36, label %arr_rplace_oob_37
arr_rplace_ok_36:
  %t161 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t123, i32 0, i64 %t159
  br label %arr_rplace_end_38
arr_rplace_oob_37:
  store %Player zeroinitializer, %Player* %t162
  br label %arr_rplace_end_38
arr_rplace_end_38:
  %t163 = phi %Player* [ %t161, %arr_rplace_ok_36 ], [ %t162, %arr_rplace_oob_37 ]
  %t164 = getelementptr inbounds %Player, %Player* %t163, i32 0, i32 0
  %t165 = load i32, i32* %t164
  %t166 = getelementptr inbounds [39 x i8], [39 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t166, i32 %t158, i32 %t165)
  %t167 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t123, i32 0, i64 0
  %t168 = getelementptr inbounds %Player, %Player* %t167, i32 0, i32 1
  %t169 = load i8*, i8** %t168
  call void @star_rc_release(i8* %t169)
  %t170 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t123, i32 0, i64 1
  %t171 = getelementptr inbounds %Player, %Player* %t170, i32 0, i32 1
  %t172 = load i8*, i8** %t171
  call void @star_rc_release(i8* %t172)
  %t173 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t123, i32 0, i64 2
  %t174 = getelementptr inbounds %Player, %Player* %t173, i32 0, i32 1
  %t175 = load i8*, i8** %t174
  call void @star_rc_release(i8* %t175)
  %t176 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t24, i32 0, i32 0
  %t177 = getelementptr inbounds %Player, %Player* %t176, i32 0, i32 1
  %t178 = load i8*, i8** %t177
  call void @star_rc_release(i8* %t178)
  %t179 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t24, i32 0, i32 1
  %t180 = load i8*, i8** %t179
  call void @star_rc_release(i8* %t180)
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
