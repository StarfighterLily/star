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
define { i32, i32 } @min_max(i32 %a, i32 %b) {
entry:
  %t0 = alloca i32
  store i32 %a, i32* %t0
  %t1 = alloca i32
  store i32 %b, i32* %t1
  %t2 = load i32, i32* %t0
  %t3 = load i32, i32* %t1
  %t4 = icmp sle i32 %t2, %t3
  br label %match_scrutinee_6
match_scrutinee_6:
  %t9 = icmp eq i1 %t4, true
  br i1 %t9, label %match_then_0_7, label %match_next_0_8
match_then_0_7:
  %t10 = alloca { i32, i32 }
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
  %t19 = alloca { i32, i32 }
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
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = alloca { i32, i32 }
  %t1 = alloca { i32, i32 }
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
  %t16 = alloca { i32, i32 }
  %t17 = call { i32, i32 } @min_max(i32 7, i32 2)
  store { i32, i32 } %t17, { i32, i32 }* %t16
  %t18 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t16, i32 0, i32 0
  %t19 = load i32, i32* %t18
  %t20 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t16, i32 0, i32 1
  %t21 = load i32, i32* %t20
  %t22 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t22, i32 %t19, i32 %t21)
  %t23 = alloca { %Player, i8* }
  %t24 = alloca { %Player, i8* }
  %t25 = alloca %Player
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
  %t51 = alloca i32
  store i32 5, i32* %t51
  %t52 = load i32, i32* %t51
  %t53 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t53, i32 %t52)
  %t54 = alloca { i32 }
  %t55 = alloca { i32 }
  %t56 = getelementptr inbounds { i32 }, { i32 }* %t55, i32 0, i32 0
  store i32 9, i32* %t56
  %t57 = load { i32 }, { i32 }* %t55
  store { i32 } %t57, { i32 }* %t54
  %t58 = getelementptr inbounds { i32 }, { i32 }* %t54, i32 0, i32 0
  %t59 = load i32, i32* %t58
  %t60 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t60, i32 %t59)
  %t61 = alloca [5 x i32]
  %t62 = alloca [5 x i32]
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
  br i1 %t72, label %arr_place_ok_0, label %arr_place_oob_1
arr_place_ok_0:
  %t73 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t71
  br label %arr_place_end_2
arr_place_oob_1:
  %t74 = alloca i32
  store i32 0, i32* %t74
  br label %arr_place_end_2
arr_place_end_2:
  %t75 = phi i32* [ %t73, %arr_place_ok_0 ], [ %t74, %arr_place_oob_1 ]
  store i32 42, i32* %t75
  %t76 = sext i32 0 to i64
  %t77 = icmp ult i64 %t76, 5
  br i1 %t77, label %arr_rplace_ok_3, label %arr_rplace_oob_4
arr_rplace_ok_3:
  %t78 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t76
  br label %arr_rplace_end_5
arr_rplace_oob_4:
  %t79 = alloca i32
  store i32 0, i32* %t79
  br label %arr_rplace_end_5
arr_rplace_end_5:
  %t80 = phi i32* [ %t78, %arr_rplace_ok_3 ], [ %t79, %arr_rplace_oob_4 ]
  %t81 = load i32, i32* %t80
  %t82 = sext i32 1 to i64
  %t83 = icmp ult i64 %t82, 5
  br i1 %t83, label %arr_rplace_ok_6, label %arr_rplace_oob_7
arr_rplace_ok_6:
  %t84 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t82
  br label %arr_rplace_end_8
arr_rplace_oob_7:
  %t85 = alloca i32
  store i32 0, i32* %t85
  br label %arr_rplace_end_8
arr_rplace_end_8:
  %t86 = phi i32* [ %t84, %arr_rplace_ok_6 ], [ %t85, %arr_rplace_oob_7 ]
  %t87 = load i32, i32* %t86
  %t88 = sext i32 2 to i64
  %t89 = icmp ult i64 %t88, 5
  br i1 %t89, label %arr_rplace_ok_9, label %arr_rplace_oob_10
arr_rplace_ok_9:
  %t90 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t88
  br label %arr_rplace_end_11
arr_rplace_oob_10:
  %t91 = alloca i32
  store i32 0, i32* %t91
  br label %arr_rplace_end_11
arr_rplace_end_11:
  %t92 = phi i32* [ %t90, %arr_rplace_ok_9 ], [ %t91, %arr_rplace_oob_10 ]
  %t93 = load i32, i32* %t92
  %t94 = sext i32 3 to i64
  %t95 = icmp ult i64 %t94, 5
  br i1 %t95, label %arr_rplace_ok_12, label %arr_rplace_oob_13
arr_rplace_ok_12:
  %t96 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t94
  br label %arr_rplace_end_14
arr_rplace_oob_13:
  %t97 = alloca i32
  store i32 0, i32* %t97
  br label %arr_rplace_end_14
arr_rplace_end_14:
  %t98 = phi i32* [ %t96, %arr_rplace_ok_12 ], [ %t97, %arr_rplace_oob_13 ]
  %t99 = load i32, i32* %t98
  %t100 = sext i32 4 to i64
  %t101 = icmp ult i64 %t100, 5
  br i1 %t101, label %arr_rplace_ok_15, label %arr_rplace_oob_16
arr_rplace_ok_15:
  %t102 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t100
  br label %arr_rplace_end_17
arr_rplace_oob_16:
  %t103 = alloca i32
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
  %t109 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t107
  br label %arr_rplace_end_20
arr_rplace_oob_19:
  %t110 = alloca i32
  store i32 0, i32* %t110
  br label %arr_rplace_end_20
arr_rplace_end_20:
  %t111 = phi i32* [ %t109, %arr_rplace_ok_18 ], [ %t110, %arr_rplace_oob_19 ]
  %t112 = load i32, i32* %t111
  %t113 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t113, i32 %t112)
  %t114 = sext i32 99 to i64
  %t115 = icmp ult i64 %t114, 5
  br i1 %t115, label %arr_place_ok_21, label %arr_place_oob_22
arr_place_ok_21:
  %t116 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t114
  br label %arr_place_end_23
arr_place_oob_22:
  %t117 = alloca i32
  store i32 0, i32* %t117
  br label %arr_place_end_23
arr_place_end_23:
  %t118 = phi i32* [ %t116, %arr_place_ok_21 ], [ %t117, %arr_place_oob_22 ]
  store i32 7, i32* %t118
  %t119 = sext i32 2 to i64
  %t120 = icmp ult i64 %t119, 5
  br i1 %t120, label %arr_rplace_ok_24, label %arr_rplace_oob_25
arr_rplace_ok_24:
  %t121 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t119
  br label %arr_rplace_end_26
arr_rplace_oob_25:
  %t122 = alloca i32
  store i32 0, i32* %t122
  br label %arr_rplace_end_26
arr_rplace_end_26:
  %t123 = phi i32* [ %t121, %arr_rplace_ok_24 ], [ %t122, %arr_rplace_oob_25 ]
  %t124 = load i32, i32* %t123
  %t125 = getelementptr inbounds [54 x i8], [54 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t125, i32 %t124)
  %t126 = alloca [3 x %Player]
  %t127 = alloca [3 x %Player]
  %t128 = alloca %Player
  %t129 = getelementptr inbounds %Player, %Player* %t128, i32 0, i32 0
  store i32 50, i32* %t129
  %t130 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.12, i64 0, i32 2, i64 0
  %t131 = getelementptr inbounds %Player, %Player* %t128, i32 0, i32 1
  store i8* %t130, i8** %t131
  %t132 = load %Player, %Player* %t128
  %t133 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t127, i32 0, i64 0
  store %Player %t132, %Player* %t133
  %t134 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t127, i32 0, i64 1
  store %Player %t132, %Player* %t134
  %t135 = getelementptr inbounds %Player, %Player* %t134, i32 0, i32 1
  %t136 = load i8*, i8** %t135
  call void @star_rc_retain(i8* %t136)
  %t137 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t127, i32 0, i64 2
  store %Player %t132, %Player* %t137
  %t138 = getelementptr inbounds %Player, %Player* %t137, i32 0, i32 1
  %t139 = load i8*, i8** %t138
  call void @star_rc_retain(i8* %t139)
  %t140 = load [3 x %Player], [3 x %Player]* %t127
  store [3 x %Player] %t140, [3 x %Player]* %t126
  %t141 = sext i32 0 to i64
  %t142 = icmp ult i64 %t141, 3
  br i1 %t142, label %arr_place_ok_27, label %arr_place_oob_28
arr_place_ok_27:
  %t143 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t126, i32 0, i64 %t141
  br label %arr_place_end_29
arr_place_oob_28:
  %t144 = alloca %Player
  store %Player zeroinitializer, %Player* %t144
  br label %arr_place_end_29
arr_place_end_29:
  %t145 = phi %Player* [ %t143, %arr_place_ok_27 ], [ %t144, %arr_place_oob_28 ]
  %t146 = getelementptr inbounds %Player, %Player* %t145, i32 0, i32 0
  %t147 = load i32, i32* %t146
  %t148 = sub i32 %t147, 10
  %t149 = sext i32 0 to i64
  %t150 = icmp ult i64 %t149, 3
  br i1 %t150, label %arr_place_ok_30, label %arr_place_oob_31
arr_place_ok_30:
  %t151 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t126, i32 0, i64 %t149
  br label %arr_place_end_32
arr_place_oob_31:
  %t152 = alloca %Player
  store %Player zeroinitializer, %Player* %t152
  br label %arr_place_end_32
arr_place_end_32:
  %t153 = phi %Player* [ %t151, %arr_place_ok_30 ], [ %t152, %arr_place_oob_31 ]
  %t154 = getelementptr inbounds %Player, %Player* %t153, i32 0, i32 0
  store i32 %t148, i32* %t154
  %t155 = sext i32 0 to i64
  %t156 = icmp ult i64 %t155, 3
  br i1 %t156, label %arr_rplace_ok_33, label %arr_rplace_oob_34
arr_rplace_ok_33:
  %t157 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t126, i32 0, i64 %t155
  br label %arr_rplace_end_35
arr_rplace_oob_34:
  %t158 = alloca %Player
  store %Player zeroinitializer, %Player* %t158
  br label %arr_rplace_end_35
arr_rplace_end_35:
  %t159 = phi %Player* [ %t157, %arr_rplace_ok_33 ], [ %t158, %arr_rplace_oob_34 ]
  %t160 = getelementptr inbounds %Player, %Player* %t159, i32 0, i32 0
  %t161 = load i32, i32* %t160
  %t162 = sext i32 1 to i64
  %t163 = icmp ult i64 %t162, 3
  br i1 %t163, label %arr_rplace_ok_36, label %arr_rplace_oob_37
arr_rplace_ok_36:
  %t164 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t126, i32 0, i64 %t162
  br label %arr_rplace_end_38
arr_rplace_oob_37:
  %t165 = alloca %Player
  store %Player zeroinitializer, %Player* %t165
  br label %arr_rplace_end_38
arr_rplace_end_38:
  %t166 = phi %Player* [ %t164, %arr_rplace_ok_36 ], [ %t165, %arr_rplace_oob_37 ]
  %t167 = getelementptr inbounds %Player, %Player* %t166, i32 0, i32 0
  %t168 = load i32, i32* %t167
  %t169 = getelementptr inbounds [39 x i8], [39 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t169, i32 %t161, i32 %t168)
  %t170 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t126, i32 0, i64 0
  %t171 = getelementptr inbounds %Player, %Player* %t170, i32 0, i32 1
  %t172 = load i8*, i8** %t171
  call void @star_rc_release(i8* %t172)
  %t173 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t126, i32 0, i64 1
  %t174 = getelementptr inbounds %Player, %Player* %t173, i32 0, i32 1
  %t175 = load i8*, i8** %t174
  call void @star_rc_release(i8* %t175)
  %t176 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t126, i32 0, i64 2
  %t177 = getelementptr inbounds %Player, %Player* %t176, i32 0, i32 1
  %t178 = load i8*, i8** %t177
  call void @star_rc_release(i8* %t178)
  %t179 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t23, i32 0, i32 0
  %t180 = getelementptr inbounds %Player, %Player* %t179, i32 0, i32 1
  %t181 = load i8*, i8** %t180
  call void @star_rc_release(i8* %t181)
  %t182 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t23, i32 0, i32 1
  %t183 = load i8*, i8** %t182
  call void @star_rc_release(i8* %t183)
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
