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

%Bag = type { i8*, i8* }
%Point = type { i32, i32 }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = alloca { [1 x i32], i64, i64 }
  store { [1 x i32], i64, i64 } zeroinitializer, { [1 x i32], i64, i64 }* %t0
  %t1 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t2 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t3 = load i64, i64* %t2
  %t4 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t5 = load i64, i64* %t4
  %t6 = icmp sge i64 %t5, 1
  br i1 %t6, label %ring_push_full_0, label %ring_push_grow_1
ring_push_grow_1:
  %t7 = add i64 %t3, %t5
  %t8 = urem i64 %t7, 1
  %t9 = getelementptr inbounds [1 x i32], [1 x i32]* %t1, i32 0, i64 %t8
  store i32 10, i32* %t9
  %t10 = add i64 %t5, 1
  store i64 %t10, i64* %t4
  br label %ring_push_done_2
ring_push_full_0:
  %t11 = getelementptr inbounds [1 x i32], [1 x i32]* %t1, i32 0, i64 %t3
  store i32 10, i32* %t11
  %t12 = add i64 %t3, 1
  %t13 = urem i64 %t12, 1
  store i64 %t13, i64* %t2
  br label %ring_push_done_2
ring_push_done_2:
  %t14 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t15 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t16 = load i64, i64* %t15
  %t17 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t18 = load i64, i64* %t17
  %t19 = icmp sge i64 %t18, 1
  br i1 %t19, label %ring_push_full_3, label %ring_push_grow_4
ring_push_grow_4:
  %t20 = add i64 %t16, %t18
  %t21 = urem i64 %t20, 1
  %t22 = getelementptr inbounds [1 x i32], [1 x i32]* %t14, i32 0, i64 %t21
  store i32 20, i32* %t22
  %t23 = add i64 %t18, 1
  store i64 %t23, i64* %t17
  br label %ring_push_done_5
ring_push_full_3:
  %t24 = getelementptr inbounds [1 x i32], [1 x i32]* %t14, i32 0, i64 %t16
  store i32 20, i32* %t24
  %t25 = add i64 %t16, 1
  %t26 = urem i64 %t25, 1
  store i64 %t26, i64* %t15
  br label %ring_push_done_5
ring_push_done_5:
  %t27 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t28 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t29 = load i64, i64* %t28
  %t30 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t31 = load i64, i64* %t30
  %t32 = icmp sge i64 %t31, 1
  br i1 %t32, label %ring_push_full_6, label %ring_push_grow_7
ring_push_grow_7:
  %t33 = add i64 %t29, %t31
  %t34 = urem i64 %t33, 1
  %t35 = getelementptr inbounds [1 x i32], [1 x i32]* %t27, i32 0, i64 %t34
  store i32 30, i32* %t35
  %t36 = add i64 %t31, 1
  store i64 %t36, i64* %t30
  br label %ring_push_done_8
ring_push_full_6:
  %t37 = getelementptr inbounds [1 x i32], [1 x i32]* %t27, i32 0, i64 %t29
  store i32 30, i32* %t37
  %t38 = add i64 %t29, 1
  %t39 = urem i64 %t38, 1
  store i64 %t39, i64* %t28
  br label %ring_push_done_8
ring_push_done_8:
  %t40 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t41 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t42 = load i64, i64* %t41
  %t43 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t44 = load i64, i64* %t43
  %t45 = trunc i64 %t44 to i32
  %t46 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t47 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t48 = load i64, i64* %t47
  %t49 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t50 = load i64, i64* %t49
  %t51 = sext i32 0 to i64
  %t52 = icmp ult i64 %t51, %t50
  br i1 %t52, label %ring_rplace_ok_9, label %ring_rplace_oob_10
ring_rplace_ok_9:
  %t53 = add i64 %t48, %t51
  %t54 = urem i64 %t53, 1
  %t55 = getelementptr inbounds [1 x i32], [1 x i32]* %t46, i32 0, i64 %t54
  br label %ring_rplace_end_11
ring_rplace_oob_10:
  %t56 = alloca i32
  store i32 0, i32* %t56
  br label %ring_rplace_end_11
ring_rplace_end_11:
  %t57 = phi i32* [ %t55, %ring_rplace_ok_9 ], [ %t56, %ring_rplace_oob_10 ]
  %t58 = load i32, i32* %t57
  %t59 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t59, i32 %t45, i32 %t58)
  %t60 = alloca { [3 x i32], i64, i64 }
  store { [3 x i32], i64, i64 } zeroinitializer, { [3 x i32], i64, i64 }* %t60
  %t61 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t60, i32 0, i32 0
  %t62 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t60, i32 0, i32 1
  %t63 = load i64, i64* %t62
  %t64 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t60, i32 0, i32 2
  %t65 = load i64, i64* %t64
  %t66 = icmp sge i64 %t65, 3
  br i1 %t66, label %ring_push_full_12, label %ring_push_grow_13
ring_push_grow_13:
  %t67 = add i64 %t63, %t65
  %t68 = urem i64 %t67, 3
  %t69 = getelementptr inbounds [3 x i32], [3 x i32]* %t61, i32 0, i64 %t68
  store i32 1, i32* %t69
  %t70 = add i64 %t65, 1
  store i64 %t70, i64* %t64
  br label %ring_push_done_14
ring_push_full_12:
  %t71 = getelementptr inbounds [3 x i32], [3 x i32]* %t61, i32 0, i64 %t63
  store i32 1, i32* %t71
  %t72 = add i64 %t63, 1
  %t73 = urem i64 %t72, 3
  store i64 %t73, i64* %t62
  br label %ring_push_done_14
ring_push_done_14:
  %t74 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t60, i32 0, i32 0
  %t75 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t60, i32 0, i32 1
  %t76 = load i64, i64* %t75
  %t77 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t60, i32 0, i32 2
  %t78 = load i64, i64* %t77
  %t79 = icmp sge i64 %t78, 3
  br i1 %t79, label %ring_push_full_15, label %ring_push_grow_16
ring_push_grow_16:
  %t80 = add i64 %t76, %t78
  %t81 = urem i64 %t80, 3
  %t82 = getelementptr inbounds [3 x i32], [3 x i32]* %t74, i32 0, i64 %t81
  store i32 2, i32* %t82
  %t83 = add i64 %t78, 1
  store i64 %t83, i64* %t77
  br label %ring_push_done_17
ring_push_full_15:
  %t84 = getelementptr inbounds [3 x i32], [3 x i32]* %t74, i32 0, i64 %t76
  store i32 2, i32* %t84
  %t85 = add i64 %t76, 1
  %t86 = urem i64 %t85, 3
  store i64 %t86, i64* %t75
  br label %ring_push_done_17
ring_push_done_17:
  %t87 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t60, i32 0, i32 0
  %t88 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t60, i32 0, i32 1
  %t89 = load i64, i64* %t88
  %t90 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t60, i32 0, i32 2
  %t91 = load i64, i64* %t90
  %t92 = sub i32 0, 1
  %t93 = sext i32 %t92 to i64
  %t94 = icmp ult i64 %t93, %t91
  br i1 %t94, label %ring_rplace_ok_18, label %ring_rplace_oob_19
ring_rplace_ok_18:
  %t95 = add i64 %t89, %t93
  %t96 = urem i64 %t95, 3
  %t97 = getelementptr inbounds [3 x i32], [3 x i32]* %t87, i32 0, i64 %t96
  br label %ring_rplace_end_20
ring_rplace_oob_19:
  %t98 = alloca i32
  store i32 0, i32* %t98
  br label %ring_rplace_end_20
ring_rplace_end_20:
  %t99 = phi i32* [ %t97, %ring_rplace_ok_18 ], [ %t98, %ring_rplace_oob_19 ]
  %t100 = load i32, i32* %t99
  %t101 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t101, i32 %t100)
  %t102 = alloca { [2 x %Bag], i64, i64 }
  store { [2 x %Bag], i64, i64 } zeroinitializer, { [2 x %Bag], i64, i64 }* %t102
  %t103 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 0
  %t104 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 1
  %t105 = load i64, i64* %t104
  %t106 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 2
  %t107 = load i64, i64* %t106
  %t108 = alloca %Bag
  %t109 = getelementptr i32, i32* null, i32 1
  %t110 = ptrtoint i32* %t109 to i64
  %t111 = mul i64 %t110, 3
  %t112 = call i8* @malloc(i64 %t111)
  %t113 = bitcast i8* %t112 to i32*
  %t114 = getelementptr inbounds i32, i32* %t113, i64 0
  store i32 1, i32* %t114
  %t115 = getelementptr inbounds i32, i32* %t113, i64 1
  store i32 2, i32* %t115
  %t116 = getelementptr inbounds i32, i32* %t113, i64 2
  store i32 3, i32* %t116
  %t121 = bitcast void (i8*)* @list_release_i32 to i8*
  %t122 = call i8* @star_rc_alloc(i64 24, i8* %t121)
  %t123 = bitcast i8* %t122 to { i32*, i64, i64 }*
  %t124 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t123, i32 0, i32 0
  store i32* %t113, i32** %t124
  %t125 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t123, i32 0, i32 1
  store i64 3, i64* %t125
  %t126 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t123, i32 0, i32 2
  store i64 3, i64* %t126
  %t127 = getelementptr inbounds %Bag, %Bag* %t108, i32 0, i32 0
  store i8* %t122, i8** %t127
  %t128 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t129 = getelementptr inbounds %Bag, %Bag* %t108, i32 0, i32 1
  store i8* %t128, i8** %t129
  %t130 = load %Bag, %Bag* %t108
  %t131 = icmp sge i64 %t107, 2
  br i1 %t131, label %ring_push_full_21, label %ring_push_grow_22
ring_push_grow_22:
  %t132 = add i64 %t105, %t107
  %t133 = urem i64 %t132, 2
  %t134 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t103, i32 0, i64 %t133
  store %Bag %t130, %Bag* %t134
  %t135 = add i64 %t107, 1
  store i64 %t135, i64* %t106
  br label %ring_push_done_23
ring_push_full_21:
  %t136 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t103, i32 0, i64 %t105
  %t137 = getelementptr inbounds %Bag, %Bag* %t136, i32 0, i32 0
  %t138 = load i8*, i8** %t137
  call void @star_rc_release(i8* %t138)
  %t139 = getelementptr inbounds %Bag, %Bag* %t136, i32 0, i32 1
  %t140 = load i8*, i8** %t139
  call void @star_rc_release(i8* %t140)
  store %Bag %t130, %Bag* %t136
  %t141 = add i64 %t105, 1
  %t142 = urem i64 %t141, 2
  store i64 %t142, i64* %t104
  br label %ring_push_done_23
ring_push_done_23:
  %t143 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 0
  %t144 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 1
  %t145 = load i64, i64* %t144
  %t146 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 2
  %t147 = load i64, i64* %t146
  %t148 = alloca %Bag
  %t149 = getelementptr i32, i32* null, i32 1
  %t150 = ptrtoint i32* %t149 to i64
  %t151 = mul i64 %t150, 2
  %t152 = call i8* @malloc(i64 %t151)
  %t153 = bitcast i8* %t152 to i32*
  %t154 = getelementptr inbounds i32, i32* %t153, i64 0
  store i32 4, i32* %t154
  %t155 = getelementptr inbounds i32, i32* %t153, i64 1
  store i32 5, i32* %t155
  %t156 = bitcast void (i8*)* @list_release_i32 to i8*
  %t157 = call i8* @star_rc_alloc(i64 24, i8* %t156)
  %t158 = bitcast i8* %t157 to { i32*, i64, i64 }*
  %t159 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t158, i32 0, i32 0
  store i32* %t153, i32** %t159
  %t160 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t158, i32 0, i32 1
  store i64 2, i64* %t160
  %t161 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t158, i32 0, i32 2
  store i64 2, i64* %t161
  %t162 = getelementptr inbounds %Bag, %Bag* %t148, i32 0, i32 0
  store i8* %t157, i8** %t162
  %t163 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t164 = getelementptr inbounds %Bag, %Bag* %t148, i32 0, i32 1
  store i8* %t163, i8** %t164
  %t165 = load %Bag, %Bag* %t148
  %t166 = icmp sge i64 %t147, 2
  br i1 %t166, label %ring_push_full_24, label %ring_push_grow_25
ring_push_grow_25:
  %t167 = add i64 %t145, %t147
  %t168 = urem i64 %t167, 2
  %t169 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t143, i32 0, i64 %t168
  store %Bag %t165, %Bag* %t169
  %t170 = add i64 %t147, 1
  store i64 %t170, i64* %t146
  br label %ring_push_done_26
ring_push_full_24:
  %t171 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t143, i32 0, i64 %t145
  %t172 = getelementptr inbounds %Bag, %Bag* %t171, i32 0, i32 0
  %t173 = load i8*, i8** %t172
  call void @star_rc_release(i8* %t173)
  %t174 = getelementptr inbounds %Bag, %Bag* %t171, i32 0, i32 1
  %t175 = load i8*, i8** %t174
  call void @star_rc_release(i8* %t175)
  store %Bag %t165, %Bag* %t171
  %t176 = add i64 %t145, 1
  %t177 = urem i64 %t176, 2
  store i64 %t177, i64* %t144
  br label %ring_push_done_26
ring_push_done_26:
  %t178 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 0
  %t179 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 1
  %t180 = load i64, i64* %t179
  %t181 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 2
  %t182 = load i64, i64* %t181
  %t183 = alloca %Bag
  %t184 = getelementptr i32, i32* null, i32 1
  %t185 = ptrtoint i32* %t184 to i64
  %t186 = mul i64 %t185, 1
  %t187 = call i8* @malloc(i64 %t186)
  %t188 = bitcast i8* %t187 to i32*
  %t189 = getelementptr inbounds i32, i32* %t188, i64 0
  store i32 6, i32* %t189
  %t190 = bitcast void (i8*)* @list_release_i32 to i8*
  %t191 = call i8* @star_rc_alloc(i64 24, i8* %t190)
  %t192 = bitcast i8* %t191 to { i32*, i64, i64 }*
  %t193 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t192, i32 0, i32 0
  store i32* %t188, i32** %t193
  %t194 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t192, i32 0, i32 1
  store i64 1, i64* %t194
  %t195 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t192, i32 0, i32 2
  store i64 1, i64* %t195
  %t196 = getelementptr inbounds %Bag, %Bag* %t183, i32 0, i32 0
  store i8* %t191, i8** %t196
  %t197 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t198 = getelementptr inbounds %Bag, %Bag* %t183, i32 0, i32 1
  store i8* %t197, i8** %t198
  %t199 = load %Bag, %Bag* %t183
  %t200 = icmp sge i64 %t182, 2
  br i1 %t200, label %ring_push_full_27, label %ring_push_grow_28
ring_push_grow_28:
  %t201 = add i64 %t180, %t182
  %t202 = urem i64 %t201, 2
  %t203 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t178, i32 0, i64 %t202
  store %Bag %t199, %Bag* %t203
  %t204 = add i64 %t182, 1
  store i64 %t204, i64* %t181
  br label %ring_push_done_29
ring_push_full_27:
  %t205 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t178, i32 0, i64 %t180
  %t206 = getelementptr inbounds %Bag, %Bag* %t205, i32 0, i32 0
  %t207 = load i8*, i8** %t206
  call void @star_rc_release(i8* %t207)
  %t208 = getelementptr inbounds %Bag, %Bag* %t205, i32 0, i32 1
  %t209 = load i8*, i8** %t208
  call void @star_rc_release(i8* %t209)
  store %Bag %t199, %Bag* %t205
  %t210 = add i64 %t180, 1
  %t211 = urem i64 %t210, 2
  store i64 %t211, i64* %t179
  br label %ring_push_done_29
ring_push_done_29:
  %t212 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 0
  %t213 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 1
  %t214 = load i64, i64* %t213
  %t215 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 2
  %t216 = load i64, i64* %t215
  %t217 = sext i32 0 to i64
  %t218 = icmp ult i64 %t217, %t216
  br i1 %t218, label %ring_rplace_ok_30, label %ring_rplace_oob_31
ring_rplace_ok_30:
  %t219 = add i64 %t214, %t217
  %t220 = urem i64 %t219, 2
  %t221 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t212, i32 0, i64 %t220
  br label %ring_rplace_end_32
ring_rplace_oob_31:
  %t222 = alloca %Bag
  store %Bag zeroinitializer, %Bag* %t222
  br label %ring_rplace_end_32
ring_rplace_end_32:
  %t223 = phi %Bag* [ %t221, %ring_rplace_ok_30 ], [ %t222, %ring_rplace_oob_31 ]
  %t224 = getelementptr inbounds %Bag, %Bag* %t223, i32 0, i32 1
  %t225 = load i8*, i8** %t224
  %t226 = load i8*, i8** %t224
  call void @star_rc_retain(i8* %t226)
  call void @star_rc_release(i8* %t225)
  %t227 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 0
  %t228 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 1
  %t229 = load i64, i64* %t228
  %t230 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 2
  %t231 = load i64, i64* %t230
  %t232 = sext i32 0 to i64
  %t233 = icmp ult i64 %t232, %t231
  br i1 %t233, label %ring_rplace_ok_33, label %ring_rplace_oob_34
ring_rplace_ok_33:
  %t234 = add i64 %t229, %t232
  %t235 = urem i64 %t234, 2
  %t236 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t227, i32 0, i64 %t235
  br label %ring_rplace_end_35
ring_rplace_oob_34:
  %t237 = alloca %Bag
  store %Bag zeroinitializer, %Bag* %t237
  br label %ring_rplace_end_35
ring_rplace_end_35:
  %t238 = phi %Bag* [ %t236, %ring_rplace_ok_33 ], [ %t237, %ring_rplace_oob_34 ]
  %t239 = getelementptr inbounds %Bag, %Bag* %t238, i32 0, i32 0
  %t240 = load i8*, i8** %t239
  %t241 = icmp eq i8* %t240, null
  br i1 %t241, label %list_read_null_36, label %list_read_real_37
list_read_null_36:
  br label %list_read_end_38
list_read_real_37:
  %t242 = bitcast i8* %t240 to { i32*, i64, i64 }*
  %t243 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t242, i32 0, i32 0
  %t244 = load i32*, i32** %t243
  %t245 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t242, i32 0, i32 1
  %t246 = load i64, i64* %t245
  br label %list_read_end_38
list_read_end_38:
  %t247 = phi i32* [ null, %list_read_null_36 ], [ %t244, %list_read_real_37 ]
  %t248 = phi i64 [ 0, %list_read_null_36 ], [ %t246, %list_read_real_37 ]
  %t249 = trunc i64 %t248 to i32
  %t250 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t250, i8* %t225, i32 %t249)
  %t251 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 0
  %t252 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 1
  %t253 = load i64, i64* %t252
  %t254 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 2
  %t255 = load i64, i64* %t254
  %t256 = sext i32 1 to i64
  %t257 = icmp ult i64 %t256, %t255
  br i1 %t257, label %ring_rplace_ok_39, label %ring_rplace_oob_40
ring_rplace_ok_39:
  %t258 = add i64 %t253, %t256
  %t259 = urem i64 %t258, 2
  %t260 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t251, i32 0, i64 %t259
  br label %ring_rplace_end_41
ring_rplace_oob_40:
  %t261 = alloca %Bag
  store %Bag zeroinitializer, %Bag* %t261
  br label %ring_rplace_end_41
ring_rplace_end_41:
  %t262 = phi %Bag* [ %t260, %ring_rplace_ok_39 ], [ %t261, %ring_rplace_oob_40 ]
  %t263 = getelementptr inbounds %Bag, %Bag* %t262, i32 0, i32 1
  %t264 = load i8*, i8** %t263
  %t265 = load i8*, i8** %t263
  call void @star_rc_retain(i8* %t265)
  call void @star_rc_release(i8* %t264)
  %t266 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 0
  %t267 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 1
  %t268 = load i64, i64* %t267
  %t269 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 2
  %t270 = load i64, i64* %t269
  %t271 = sext i32 1 to i64
  %t272 = icmp ult i64 %t271, %t270
  br i1 %t272, label %ring_rplace_ok_42, label %ring_rplace_oob_43
ring_rplace_ok_42:
  %t273 = add i64 %t268, %t271
  %t274 = urem i64 %t273, 2
  %t275 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t266, i32 0, i64 %t274
  br label %ring_rplace_end_44
ring_rplace_oob_43:
  %t276 = alloca %Bag
  store %Bag zeroinitializer, %Bag* %t276
  br label %ring_rplace_end_44
ring_rplace_end_44:
  %t277 = phi %Bag* [ %t275, %ring_rplace_ok_42 ], [ %t276, %ring_rplace_oob_43 ]
  %t278 = getelementptr inbounds %Bag, %Bag* %t277, i32 0, i32 0
  %t279 = load i8*, i8** %t278
  %t280 = icmp eq i8* %t279, null
  br i1 %t280, label %list_read_null_45, label %list_read_real_46
list_read_null_45:
  br label %list_read_end_47
list_read_real_46:
  %t281 = bitcast i8* %t279 to { i32*, i64, i64 }*
  %t282 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t281, i32 0, i32 0
  %t283 = load i32*, i32** %t282
  %t284 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t281, i32 0, i32 1
  %t285 = load i64, i64* %t284
  br label %list_read_end_47
list_read_end_47:
  %t286 = phi i32* [ null, %list_read_null_45 ], [ %t283, %list_read_real_46 ]
  %t287 = phi i64 [ 0, %list_read_null_45 ], [ %t285, %list_read_real_46 ]
  %t288 = trunc i64 %t287 to i32
  %t289 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t289, i8* %t264, i32 %t288)
  %t290 = alloca i8*
  store i8* null, i8** %t290
  %t291 = load i8*, i8** %t290
  %t292 = icmp eq i8* %t291, null
  br i1 %t292, label %table_cow_alloc_48, label %table_cow_check_49
table_cow_alloc_48:
  %t302 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t303 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t304 = ptrtoint { i64, i64, i32*, i32* }* %t303 to i64
  %t305 = call i8* @star_rc_alloc(i64 %t304, i8* %t302)
  %t306 = bitcast i8* %t305 to { i64, i64, i32*, i32* }*
  %t307 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t306, i32 0, i32 0
  store i64 0, i64* %t307
  %t308 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t306, i32 0, i32 1
  store i64 0, i64* %t308
  %t309 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t306, i32 0, i32 2
  store i32* null, i32** %t309
  %t310 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t306, i32 0, i32 3
  store i32* null, i32** %t310
  store i8* %t305, i8** %t290
  br label %table_cow_done_50
table_cow_check_49:
  %t311 = getelementptr inbounds i8, i8* %t291, i64 -16
  %t312 = bitcast i8* %t311 to i64*
  %t313 = load atomic i64, i64* %t312 seq_cst, align 8
  %t314 = icmp eq i64 %t313, 1
  br i1 %t314, label %table_cow_done_50, label %table_cow_clone_51
table_cow_clone_51:
  %t315 = bitcast i8* %t291 to { i64, i64, i32*, i32* }*
  %t316 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t315, i32 0, i32 0
  %t317 = load i64, i64* %t316
  %t318 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t315, i32 0, i32 1
  %t319 = load i64, i64* %t318
  %t320 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t321 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t322 = ptrtoint { i64, i64, i32*, i32* }* %t321 to i64
  %t323 = call i8* @star_rc_alloc(i64 %t322, i8* %t320)
  %t324 = bitcast i8* %t323 to { i64, i64, i32*, i32* }*
  %t325 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t324, i32 0, i32 0
  store i64 %t317, i64* %t325
  %t326 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t324, i32 0, i32 1
  store i64 %t319, i64* %t326
  %t327 = getelementptr i32, i32* null, i32 1
  %t328 = ptrtoint i32* %t327 to i64
  %t329 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t315, i32 0, i32 2
  %t330 = load i32*, i32** %t329
  %t331 = mul i64 %t319, %t328
  %t332 = call i8* @malloc(i64 %t331)
  %t333 = bitcast i8* %t332 to i32*
  %t334 = icmp sgt i64 %t317, 0
  br i1 %t334, label %table_cow_copy_52, label %table_cow_after_copy_53
table_cow_copy_52:
  %t335 = mul i64 %t317, %t328
  %t336 = bitcast i32* %t330 to i8*
  call i8* @memcpy(i8* %t332, i8* %t336, i64 %t335)
  br label %table_cow_after_copy_53
table_cow_after_copy_53:
  %t337 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t324, i32 0, i32 2
  store i32* %t333, i32** %t337
  %t338 = getelementptr i32, i32* null, i32 1
  %t339 = ptrtoint i32* %t338 to i64
  %t340 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t315, i32 0, i32 3
  %t341 = load i32*, i32** %t340
  %t342 = mul i64 %t319, %t339
  %t343 = call i8* @malloc(i64 %t342)
  %t344 = bitcast i8* %t343 to i32*
  %t345 = icmp sgt i64 %t317, 0
  br i1 %t345, label %table_cow_copy_54, label %table_cow_after_copy_55
table_cow_copy_54:
  %t346 = mul i64 %t317, %t339
  %t347 = bitcast i32* %t341 to i8*
  call i8* @memcpy(i8* %t343, i8* %t347, i64 %t346)
  br label %table_cow_after_copy_55
table_cow_after_copy_55:
  %t348 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t324, i32 0, i32 3
  store i32* %t344, i32** %t348
  call void @star_rc_release(i8* %t291)
  store i8* %t323, i8** %t290
  br label %table_cow_done_50
table_cow_done_50:
  %t349 = load i8*, i8** %t290
  %t350 = bitcast i8* %t349 to { i64, i64, i32*, i32* }*
  %t351 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t350, i32 0, i32 0
  %t352 = load i64, i64* %t351
  %t353 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t350, i32 0, i32 1
  %t354 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t350, i32 0, i32 2
  %t355 = load i32*, i32** %t354
  %t356 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t350, i32 0, i32 3
  %t357 = load i32*, i32** %t356
  %t358 = alloca %Point
  %t359 = getelementptr inbounds %Point, %Point* %t358, i32 0, i32 0
  store i32 1, i32* %t359
  %t360 = getelementptr inbounds %Point, %Point* %t358, i32 0, i32 1
  store i32 2, i32* %t360
  %t361 = load %Point, %Point* %t358
  %t362 = load i64, i64* %t353
  %t363 = icmp sge i64 %t352, %t362
  br i1 %t363, label %table_push_grow_56, label %table_push_store_57
table_push_grow_56:
  %t364 = mul i64 %t362, 2
  %t365 = icmp sgt i64 %t364, 0
  %t366 = select i1 %t365, i64 %t364, i64 1
  %t367 = getelementptr i32, i32* null, i32 1
  %t368 = ptrtoint i32* %t367 to i64
  %t369 = mul i64 %t366, %t368
  %t370 = call i8* @malloc(i64 %t369)
  %t371 = bitcast i8* %t370 to i32*
  %t372 = icmp sgt i64 %t362, 0
  br i1 %t372, label %table_push_copy_58, label %table_push_after_copy_59
table_push_copy_58:
  %t373 = mul i64 %t352, %t368
  %t374 = bitcast i32* %t355 to i8*
  call i8* @memcpy(i8* %t370, i8* %t374, i64 %t373)
  call void @free(i8* %t374)
  br label %table_push_after_copy_59
table_push_after_copy_59:
  store i32* %t371, i32** %t354
  %t375 = getelementptr i32, i32* null, i32 1
  %t376 = ptrtoint i32* %t375 to i64
  %t377 = mul i64 %t366, %t376
  %t378 = call i8* @malloc(i64 %t377)
  %t379 = bitcast i8* %t378 to i32*
  %t380 = icmp sgt i64 %t362, 0
  br i1 %t380, label %table_push_copy_60, label %table_push_after_copy_61
table_push_copy_60:
  %t381 = mul i64 %t352, %t376
  %t382 = bitcast i32* %t357 to i8*
  call i8* @memcpy(i8* %t378, i8* %t382, i64 %t381)
  call void @free(i8* %t382)
  br label %table_push_after_copy_61
table_push_after_copy_61:
  store i32* %t379, i32** %t356
  store i64 %t366, i64* %t353
  br label %table_push_store_57
table_push_store_57:
  %t383 = load i32*, i32** %t354
  %t384 = extractvalue %Point %t361, 0
  %t385 = getelementptr inbounds i32, i32* %t383, i64 %t352
  store i32 %t384, i32* %t385
  %t386 = load i32*, i32** %t356
  %t387 = extractvalue %Point %t361, 1
  %t388 = getelementptr inbounds i32, i32* %t386, i64 %t352
  store i32 %t387, i32* %t388
  %t389 = add i64 %t352, 1
  store i64 %t389, i64* %t351
  %t390 = load i8*, i8** %t290
  %t391 = icmp eq i8* %t390, null
  br i1 %t391, label %table_cow_alloc_62, label %table_cow_check_63
table_cow_alloc_62:
  %t392 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t393 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t394 = ptrtoint { i64, i64, i32*, i32* }* %t393 to i64
  %t395 = call i8* @star_rc_alloc(i64 %t394, i8* %t392)
  %t396 = bitcast i8* %t395 to { i64, i64, i32*, i32* }*
  %t397 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t396, i32 0, i32 0
  store i64 0, i64* %t397
  %t398 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t396, i32 0, i32 1
  store i64 0, i64* %t398
  %t399 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t396, i32 0, i32 2
  store i32* null, i32** %t399
  %t400 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t396, i32 0, i32 3
  store i32* null, i32** %t400
  store i8* %t395, i8** %t290
  br label %table_cow_done_64
table_cow_check_63:
  %t401 = getelementptr inbounds i8, i8* %t390, i64 -16
  %t402 = bitcast i8* %t401 to i64*
  %t403 = load atomic i64, i64* %t402 seq_cst, align 8
  %t404 = icmp eq i64 %t403, 1
  br i1 %t404, label %table_cow_done_64, label %table_cow_clone_65
table_cow_clone_65:
  %t405 = bitcast i8* %t390 to { i64, i64, i32*, i32* }*
  %t406 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t405, i32 0, i32 0
  %t407 = load i64, i64* %t406
  %t408 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t405, i32 0, i32 1
  %t409 = load i64, i64* %t408
  %t410 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t411 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t412 = ptrtoint { i64, i64, i32*, i32* }* %t411 to i64
  %t413 = call i8* @star_rc_alloc(i64 %t412, i8* %t410)
  %t414 = bitcast i8* %t413 to { i64, i64, i32*, i32* }*
  %t415 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t414, i32 0, i32 0
  store i64 %t407, i64* %t415
  %t416 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t414, i32 0, i32 1
  store i64 %t409, i64* %t416
  %t417 = getelementptr i32, i32* null, i32 1
  %t418 = ptrtoint i32* %t417 to i64
  %t419 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t405, i32 0, i32 2
  %t420 = load i32*, i32** %t419
  %t421 = mul i64 %t409, %t418
  %t422 = call i8* @malloc(i64 %t421)
  %t423 = bitcast i8* %t422 to i32*
  %t424 = icmp sgt i64 %t407, 0
  br i1 %t424, label %table_cow_copy_66, label %table_cow_after_copy_67
table_cow_copy_66:
  %t425 = mul i64 %t407, %t418
  %t426 = bitcast i32* %t420 to i8*
  call i8* @memcpy(i8* %t422, i8* %t426, i64 %t425)
  br label %table_cow_after_copy_67
table_cow_after_copy_67:
  %t427 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t414, i32 0, i32 2
  store i32* %t423, i32** %t427
  %t428 = getelementptr i32, i32* null, i32 1
  %t429 = ptrtoint i32* %t428 to i64
  %t430 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t405, i32 0, i32 3
  %t431 = load i32*, i32** %t430
  %t432 = mul i64 %t409, %t429
  %t433 = call i8* @malloc(i64 %t432)
  %t434 = bitcast i8* %t433 to i32*
  %t435 = icmp sgt i64 %t407, 0
  br i1 %t435, label %table_cow_copy_68, label %table_cow_after_copy_69
table_cow_copy_68:
  %t436 = mul i64 %t407, %t429
  %t437 = bitcast i32* %t431 to i8*
  call i8* @memcpy(i8* %t433, i8* %t437, i64 %t436)
  br label %table_cow_after_copy_69
table_cow_after_copy_69:
  %t438 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t414, i32 0, i32 3
  store i32* %t434, i32** %t438
  call void @star_rc_release(i8* %t390)
  store i8* %t413, i8** %t290
  br label %table_cow_done_64
table_cow_done_64:
  %t439 = load i8*, i8** %t290
  %t440 = bitcast i8* %t439 to { i64, i64, i32*, i32* }*
  %t441 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t440, i32 0, i32 0
  %t442 = load i64, i64* %t441
  %t443 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t440, i32 0, i32 1
  %t444 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t440, i32 0, i32 2
  %t445 = load i32*, i32** %t444
  %t446 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t440, i32 0, i32 3
  %t447 = load i32*, i32** %t446
  %t448 = alloca %Point
  %t449 = getelementptr inbounds %Point, %Point* %t448, i32 0, i32 0
  store i32 3, i32* %t449
  %t450 = getelementptr inbounds %Point, %Point* %t448, i32 0, i32 1
  store i32 4, i32* %t450
  %t451 = load %Point, %Point* %t448
  %t452 = load i64, i64* %t443
  %t453 = icmp sge i64 %t442, %t452
  br i1 %t453, label %table_push_grow_70, label %table_push_store_71
table_push_grow_70:
  %t454 = mul i64 %t452, 2
  %t455 = icmp sgt i64 %t454, 0
  %t456 = select i1 %t455, i64 %t454, i64 1
  %t457 = getelementptr i32, i32* null, i32 1
  %t458 = ptrtoint i32* %t457 to i64
  %t459 = mul i64 %t456, %t458
  %t460 = call i8* @malloc(i64 %t459)
  %t461 = bitcast i8* %t460 to i32*
  %t462 = icmp sgt i64 %t452, 0
  br i1 %t462, label %table_push_copy_72, label %table_push_after_copy_73
table_push_copy_72:
  %t463 = mul i64 %t442, %t458
  %t464 = bitcast i32* %t445 to i8*
  call i8* @memcpy(i8* %t460, i8* %t464, i64 %t463)
  call void @free(i8* %t464)
  br label %table_push_after_copy_73
table_push_after_copy_73:
  store i32* %t461, i32** %t444
  %t465 = getelementptr i32, i32* null, i32 1
  %t466 = ptrtoint i32* %t465 to i64
  %t467 = mul i64 %t456, %t466
  %t468 = call i8* @malloc(i64 %t467)
  %t469 = bitcast i8* %t468 to i32*
  %t470 = icmp sgt i64 %t452, 0
  br i1 %t470, label %table_push_copy_74, label %table_push_after_copy_75
table_push_copy_74:
  %t471 = mul i64 %t442, %t466
  %t472 = bitcast i32* %t447 to i8*
  call i8* @memcpy(i8* %t468, i8* %t472, i64 %t471)
  call void @free(i8* %t472)
  br label %table_push_after_copy_75
table_push_after_copy_75:
  store i32* %t469, i32** %t446
  store i64 %t456, i64* %t443
  br label %table_push_store_71
table_push_store_71:
  %t473 = load i32*, i32** %t444
  %t474 = extractvalue %Point %t451, 0
  %t475 = getelementptr inbounds i32, i32* %t473, i64 %t442
  store i32 %t474, i32* %t475
  %t476 = load i32*, i32** %t446
  %t477 = extractvalue %Point %t451, 1
  %t478 = getelementptr inbounds i32, i32* %t476, i64 %t442
  store i32 %t477, i32* %t478
  %t479 = add i64 %t442, 1
  store i64 %t479, i64* %t441
  %t480 = alloca i8*
  %t481 = load i8*, i8** %t290
  %t482 = load i8*, i8** %t290
  call void @star_rc_retain(i8* %t482)
  store i8* %t481, i8** %t480
  %t483 = load i8*, i8** %t480
  %t484 = icmp eq i8* %t483, null
  br i1 %t484, label %table_cow_alloc_76, label %table_cow_check_77
table_cow_alloc_76:
  %t485 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t486 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t487 = ptrtoint { i64, i64, i32*, i32* }* %t486 to i64
  %t488 = call i8* @star_rc_alloc(i64 %t487, i8* %t485)
  %t489 = bitcast i8* %t488 to { i64, i64, i32*, i32* }*
  %t490 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t489, i32 0, i32 0
  store i64 0, i64* %t490
  %t491 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t489, i32 0, i32 1
  store i64 0, i64* %t491
  %t492 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t489, i32 0, i32 2
  store i32* null, i32** %t492
  %t493 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t489, i32 0, i32 3
  store i32* null, i32** %t493
  store i8* %t488, i8** %t480
  br label %table_cow_done_78
table_cow_check_77:
  %t494 = getelementptr inbounds i8, i8* %t483, i64 -16
  %t495 = bitcast i8* %t494 to i64*
  %t496 = load atomic i64, i64* %t495 seq_cst, align 8
  %t497 = icmp eq i64 %t496, 1
  br i1 %t497, label %table_cow_done_78, label %table_cow_clone_79
table_cow_clone_79:
  %t498 = bitcast i8* %t483 to { i64, i64, i32*, i32* }*
  %t499 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t498, i32 0, i32 0
  %t500 = load i64, i64* %t499
  %t501 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t498, i32 0, i32 1
  %t502 = load i64, i64* %t501
  %t503 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t504 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t505 = ptrtoint { i64, i64, i32*, i32* }* %t504 to i64
  %t506 = call i8* @star_rc_alloc(i64 %t505, i8* %t503)
  %t507 = bitcast i8* %t506 to { i64, i64, i32*, i32* }*
  %t508 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t507, i32 0, i32 0
  store i64 %t500, i64* %t508
  %t509 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t507, i32 0, i32 1
  store i64 %t502, i64* %t509
  %t510 = getelementptr i32, i32* null, i32 1
  %t511 = ptrtoint i32* %t510 to i64
  %t512 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t498, i32 0, i32 2
  %t513 = load i32*, i32** %t512
  %t514 = mul i64 %t502, %t511
  %t515 = call i8* @malloc(i64 %t514)
  %t516 = bitcast i8* %t515 to i32*
  %t517 = icmp sgt i64 %t500, 0
  br i1 %t517, label %table_cow_copy_80, label %table_cow_after_copy_81
table_cow_copy_80:
  %t518 = mul i64 %t500, %t511
  %t519 = bitcast i32* %t513 to i8*
  call i8* @memcpy(i8* %t515, i8* %t519, i64 %t518)
  br label %table_cow_after_copy_81
table_cow_after_copy_81:
  %t520 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t507, i32 0, i32 2
  store i32* %t516, i32** %t520
  %t521 = getelementptr i32, i32* null, i32 1
  %t522 = ptrtoint i32* %t521 to i64
  %t523 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t498, i32 0, i32 3
  %t524 = load i32*, i32** %t523
  %t525 = mul i64 %t502, %t522
  %t526 = call i8* @malloc(i64 %t525)
  %t527 = bitcast i8* %t526 to i32*
  %t528 = icmp sgt i64 %t500, 0
  br i1 %t528, label %table_cow_copy_82, label %table_cow_after_copy_83
table_cow_copy_82:
  %t529 = mul i64 %t500, %t522
  %t530 = bitcast i32* %t524 to i8*
  call i8* @memcpy(i8* %t526, i8* %t530, i64 %t529)
  br label %table_cow_after_copy_83
table_cow_after_copy_83:
  %t531 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t507, i32 0, i32 3
  store i32* %t527, i32** %t531
  call void @star_rc_release(i8* %t483)
  store i8* %t506, i8** %t480
  br label %table_cow_done_78
table_cow_done_78:
  %t532 = load i8*, i8** %t480
  %t533 = bitcast i8* %t532 to { i64, i64, i32*, i32* }*
  %t534 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t533, i32 0, i32 0
  %t535 = load i64, i64* %t534
  %t536 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t533, i32 0, i32 1
  %t537 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t533, i32 0, i32 2
  %t538 = load i32*, i32** %t537
  %t539 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t533, i32 0, i32 3
  %t540 = load i32*, i32** %t539
  %t541 = alloca %Point
  %t542 = getelementptr inbounds %Point, %Point* %t541, i32 0, i32 0
  store i32 5, i32* %t542
  %t543 = getelementptr inbounds %Point, %Point* %t541, i32 0, i32 1
  store i32 6, i32* %t543
  %t544 = load %Point, %Point* %t541
  %t545 = load i64, i64* %t536
  %t546 = icmp sge i64 %t535, %t545
  br i1 %t546, label %table_push_grow_84, label %table_push_store_85
table_push_grow_84:
  %t547 = mul i64 %t545, 2
  %t548 = icmp sgt i64 %t547, 0
  %t549 = select i1 %t548, i64 %t547, i64 1
  %t550 = getelementptr i32, i32* null, i32 1
  %t551 = ptrtoint i32* %t550 to i64
  %t552 = mul i64 %t549, %t551
  %t553 = call i8* @malloc(i64 %t552)
  %t554 = bitcast i8* %t553 to i32*
  %t555 = icmp sgt i64 %t545, 0
  br i1 %t555, label %table_push_copy_86, label %table_push_after_copy_87
table_push_copy_86:
  %t556 = mul i64 %t535, %t551
  %t557 = bitcast i32* %t538 to i8*
  call i8* @memcpy(i8* %t553, i8* %t557, i64 %t556)
  call void @free(i8* %t557)
  br label %table_push_after_copy_87
table_push_after_copy_87:
  store i32* %t554, i32** %t537
  %t558 = getelementptr i32, i32* null, i32 1
  %t559 = ptrtoint i32* %t558 to i64
  %t560 = mul i64 %t549, %t559
  %t561 = call i8* @malloc(i64 %t560)
  %t562 = bitcast i8* %t561 to i32*
  %t563 = icmp sgt i64 %t545, 0
  br i1 %t563, label %table_push_copy_88, label %table_push_after_copy_89
table_push_copy_88:
  %t564 = mul i64 %t535, %t559
  %t565 = bitcast i32* %t540 to i8*
  call i8* @memcpy(i8* %t561, i8* %t565, i64 %t564)
  call void @free(i8* %t565)
  br label %table_push_after_copy_89
table_push_after_copy_89:
  store i32* %t562, i32** %t539
  store i64 %t549, i64* %t536
  br label %table_push_store_85
table_push_store_85:
  %t566 = load i32*, i32** %t537
  %t567 = extractvalue %Point %t544, 0
  %t568 = getelementptr inbounds i32, i32* %t566, i64 %t535
  store i32 %t567, i32* %t568
  %t569 = load i32*, i32** %t539
  %t570 = extractvalue %Point %t544, 1
  %t571 = getelementptr inbounds i32, i32* %t569, i64 %t535
  store i32 %t570, i32* %t571
  %t572 = add i64 %t535, 1
  store i64 %t572, i64* %t534
  %t573 = load i8*, i8** %t290
  %t574 = icmp eq i8* %t573, null
  br i1 %t574, label %table_read_null_90, label %table_read_real_91
table_read_null_90:
  br label %table_read_end_92
table_read_real_91:
  %t575 = bitcast i8* %t573 to { i64, i64, i32*, i32* }*
  %t576 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t575, i32 0, i32 0
  %t577 = load i64, i64* %t576
  %t578 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t575, i32 0, i32 2
  %t579 = load i32*, i32** %t578
  %t580 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t575, i32 0, i32 3
  %t581 = load i32*, i32** %t580
  br label %table_read_end_92
table_read_end_92:
  %t582 = phi i64 [ 0, %table_read_null_90 ], [ %t577, %table_read_real_91 ]
  %t583 = phi i32* [ null, %table_read_null_90 ], [ %t579, %table_read_real_91 ]
  %t584 = phi i32* [ null, %table_read_null_90 ], [ %t581, %table_read_real_91 ]
  %t585 = trunc i64 %t582 to i32
  %t586 = load i8*, i8** %t480
  %t587 = icmp eq i8* %t586, null
  br i1 %t587, label %table_read_null_93, label %table_read_real_94
table_read_null_93:
  br label %table_read_end_95
table_read_real_94:
  %t588 = bitcast i8* %t586 to { i64, i64, i32*, i32* }*
  %t589 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t588, i32 0, i32 0
  %t590 = load i64, i64* %t589
  %t591 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t588, i32 0, i32 2
  %t592 = load i32*, i32** %t591
  %t593 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t588, i32 0, i32 3
  %t594 = load i32*, i32** %t593
  br label %table_read_end_95
table_read_end_95:
  %t595 = phi i64 [ 0, %table_read_null_93 ], [ %t590, %table_read_real_94 ]
  %t596 = phi i32* [ null, %table_read_null_93 ], [ %t592, %table_read_real_94 ]
  %t597 = phi i32* [ null, %table_read_null_93 ], [ %t594, %table_read_real_94 ]
  %t598 = trunc i64 %t595 to i32
  %t599 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t599, i32 %t585, i32 %t598)
  %t600 = load i8*, i8** %t290
  %t601 = icmp eq i8* %t600, null
  br i1 %t601, label %table_read_null_96, label %table_read_real_97
table_read_null_96:
  br label %table_read_end_98
table_read_real_97:
  %t602 = bitcast i8* %t600 to { i64, i64, i32*, i32* }*
  %t603 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t602, i32 0, i32 0
  %t604 = load i64, i64* %t603
  %t605 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t602, i32 0, i32 2
  %t606 = load i32*, i32** %t605
  %t607 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t602, i32 0, i32 3
  %t608 = load i32*, i32** %t607
  br label %table_read_end_98
table_read_end_98:
  %t609 = phi i64 [ 0, %table_read_null_96 ], [ %t604, %table_read_real_97 ]
  %t610 = phi i32* [ null, %table_read_null_96 ], [ %t606, %table_read_real_97 ]
  %t611 = phi i32* [ null, %table_read_null_96 ], [ %t608, %table_read_real_97 ]
  %t612 = sext i32 1 to i64
  %t613 = alloca %Point
  %t614 = icmp ult i64 %t612, %t609
  br i1 %t614, label %table_idx_ok_99, label %table_idx_oob_100
table_idx_ok_99:
  %t615 = getelementptr inbounds i32, i32* %t610, i64 %t612
  %t616 = load i32, i32* %t615
  %t617 = getelementptr inbounds %Point, %Point* %t613, i32 0, i32 0
  store i32 %t616, i32* %t617
  %t618 = getelementptr inbounds i32, i32* %t611, i64 %t612
  %t619 = load i32, i32* %t618
  %t620 = getelementptr inbounds %Point, %Point* %t613, i32 0, i32 1
  store i32 %t619, i32* %t620
  br label %table_idx_end_101
table_idx_oob_100:
  store %Point zeroinitializer, %Point* %t613
  br label %table_idx_end_101
table_idx_end_101:
  %t621 = load %Point, %Point* %t613
  %t622 = alloca %Point
  store %Point %t621, %Point* %t622
  %t623 = getelementptr inbounds %Point, %Point* %t622, i32 0, i32 0
  %t624 = load i32, i32* %t623
  %t625 = load i8*, i8** %t290
  %t626 = icmp eq i8* %t625, null
  br i1 %t626, label %table_read_null_102, label %table_read_real_103
table_read_null_102:
  br label %table_read_end_104
table_read_real_103:
  %t627 = bitcast i8* %t625 to { i64, i64, i32*, i32* }*
  %t628 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t627, i32 0, i32 0
  %t629 = load i64, i64* %t628
  %t630 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t627, i32 0, i32 2
  %t631 = load i32*, i32** %t630
  %t632 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t627, i32 0, i32 3
  %t633 = load i32*, i32** %t632
  br label %table_read_end_104
table_read_end_104:
  %t634 = phi i64 [ 0, %table_read_null_102 ], [ %t629, %table_read_real_103 ]
  %t635 = phi i32* [ null, %table_read_null_102 ], [ %t631, %table_read_real_103 ]
  %t636 = phi i32* [ null, %table_read_null_102 ], [ %t633, %table_read_real_103 ]
  %t637 = sext i32 1 to i64
  %t638 = alloca %Point
  %t639 = icmp ult i64 %t637, %t634
  br i1 %t639, label %table_idx_ok_105, label %table_idx_oob_106
table_idx_ok_105:
  %t640 = getelementptr inbounds i32, i32* %t635, i64 %t637
  %t641 = load i32, i32* %t640
  %t642 = getelementptr inbounds %Point, %Point* %t638, i32 0, i32 0
  store i32 %t641, i32* %t642
  %t643 = getelementptr inbounds i32, i32* %t636, i64 %t637
  %t644 = load i32, i32* %t643
  %t645 = getelementptr inbounds %Point, %Point* %t638, i32 0, i32 1
  store i32 %t644, i32* %t645
  br label %table_idx_end_107
table_idx_oob_106:
  store %Point zeroinitializer, %Point* %t638
  br label %table_idx_end_107
table_idx_end_107:
  %t646 = load %Point, %Point* %t638
  %t647 = alloca %Point
  store %Point %t646, %Point* %t647
  %t648 = getelementptr inbounds %Point, %Point* %t647, i32 0, i32 1
  %t649 = load i32, i32* %t648
  %t650 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t650, i32 %t624, i32 %t649)
  %t651 = load i8*, i8** %t290
  %t652 = icmp eq i8* %t651, null
  br i1 %t652, label %table_read_null_108, label %table_read_real_109
table_read_null_108:
  br label %table_read_end_110
table_read_real_109:
  %t653 = bitcast i8* %t651 to { i64, i64, i32*, i32* }*
  %t654 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t653, i32 0, i32 0
  %t655 = load i64, i64* %t654
  %t656 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t653, i32 0, i32 2
  %t657 = load i32*, i32** %t656
  %t658 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t653, i32 0, i32 3
  %t659 = load i32*, i32** %t658
  br label %table_read_end_110
table_read_end_110:
  %t660 = phi i64 [ 0, %table_read_null_108 ], [ %t655, %table_read_real_109 ]
  %t661 = phi i32* [ null, %table_read_null_108 ], [ %t657, %table_read_real_109 ]
  %t662 = phi i32* [ null, %table_read_null_108 ], [ %t659, %table_read_real_109 ]
  %t663 = sub i32 0, 1
  %t664 = sext i32 %t663 to i64
  %t665 = alloca %Point
  %t666 = icmp ult i64 %t664, %t660
  br i1 %t666, label %table_idx_ok_111, label %table_idx_oob_112
table_idx_ok_111:
  %t667 = getelementptr inbounds i32, i32* %t661, i64 %t664
  %t668 = load i32, i32* %t667
  %t669 = getelementptr inbounds %Point, %Point* %t665, i32 0, i32 0
  store i32 %t668, i32* %t669
  %t670 = getelementptr inbounds i32, i32* %t662, i64 %t664
  %t671 = load i32, i32* %t670
  %t672 = getelementptr inbounds %Point, %Point* %t665, i32 0, i32 1
  store i32 %t671, i32* %t672
  br label %table_idx_end_113
table_idx_oob_112:
  store %Point zeroinitializer, %Point* %t665
  br label %table_idx_end_113
table_idx_end_113:
  %t673 = load %Point, %Point* %t665
  %t674 = alloca %Point
  store %Point %t673, %Point* %t674
  %t675 = getelementptr inbounds %Point, %Point* %t674, i32 0, i32 0
  %t676 = load i32, i32* %t675
  %t677 = load i8*, i8** %t290
  %t678 = icmp eq i8* %t677, null
  br i1 %t678, label %table_read_null_114, label %table_read_real_115
table_read_null_114:
  br label %table_read_end_116
table_read_real_115:
  %t679 = bitcast i8* %t677 to { i64, i64, i32*, i32* }*
  %t680 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t679, i32 0, i32 0
  %t681 = load i64, i64* %t680
  %t682 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t679, i32 0, i32 2
  %t683 = load i32*, i32** %t682
  %t684 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t679, i32 0, i32 3
  %t685 = load i32*, i32** %t684
  br label %table_read_end_116
table_read_end_116:
  %t686 = phi i64 [ 0, %table_read_null_114 ], [ %t681, %table_read_real_115 ]
  %t687 = phi i32* [ null, %table_read_null_114 ], [ %t683, %table_read_real_115 ]
  %t688 = phi i32* [ null, %table_read_null_114 ], [ %t685, %table_read_real_115 ]
  %t689 = sub i32 0, 1
  %t690 = sext i32 %t689 to i64
  %t691 = alloca %Point
  %t692 = icmp ult i64 %t690, %t686
  br i1 %t692, label %table_idx_ok_117, label %table_idx_oob_118
table_idx_ok_117:
  %t693 = getelementptr inbounds i32, i32* %t687, i64 %t690
  %t694 = load i32, i32* %t693
  %t695 = getelementptr inbounds %Point, %Point* %t691, i32 0, i32 0
  store i32 %t694, i32* %t695
  %t696 = getelementptr inbounds i32, i32* %t688, i64 %t690
  %t697 = load i32, i32* %t696
  %t698 = getelementptr inbounds %Point, %Point* %t691, i32 0, i32 1
  store i32 %t697, i32* %t698
  br label %table_idx_end_119
table_idx_oob_118:
  store %Point zeroinitializer, %Point* %t691
  br label %table_idx_end_119
table_idx_end_119:
  %t699 = load %Point, %Point* %t691
  %t700 = alloca %Point
  store %Point %t699, %Point* %t700
  %t701 = getelementptr inbounds %Point, %Point* %t700, i32 0, i32 1
  %t702 = load i32, i32* %t701
  %t703 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t703, i32 %t676, i32 %t702)
  %t704 = alloca i8*
  store i8* null, i8** %t704
  %t705 = load i8*, i8** %t704
  %t706 = icmp eq i8* %t705, null
  br i1 %t706, label %table_cow_alloc_120, label %table_cow_check_121
table_cow_alloc_120:
  %t728 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t729 = getelementptr { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* null, i32 1
  %t730 = ptrtoint { i64, i64, i8**, i8** }* %t729 to i64
  %t731 = call i8* @star_rc_alloc(i64 %t730, i8* %t728)
  %t732 = bitcast i8* %t731 to { i64, i64, i8**, i8** }*
  %t733 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t732, i32 0, i32 0
  store i64 0, i64* %t733
  %t734 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t732, i32 0, i32 1
  store i64 0, i64* %t734
  %t735 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t732, i32 0, i32 2
  store i8** null, i8*** %t735
  %t736 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t732, i32 0, i32 3
  store i8** null, i8*** %t736
  store i8* %t731, i8** %t704
  br label %table_cow_done_122
table_cow_check_121:
  %t737 = getelementptr inbounds i8, i8* %t705, i64 -16
  %t738 = bitcast i8* %t737 to i64*
  %t739 = load atomic i64, i64* %t738 seq_cst, align 8
  %t740 = icmp eq i64 %t739, 1
  br i1 %t740, label %table_cow_done_122, label %table_cow_clone_129
table_cow_clone_129:
  %t741 = bitcast i8* %t705 to { i64, i64, i8**, i8** }*
  %t742 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t741, i32 0, i32 0
  %t743 = load i64, i64* %t742
  %t744 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t741, i32 0, i32 1
  %t745 = load i64, i64* %t744
  %t746 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t747 = getelementptr { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* null, i32 1
  %t748 = ptrtoint { i64, i64, i8**, i8** }* %t747 to i64
  %t749 = call i8* @star_rc_alloc(i64 %t748, i8* %t746)
  %t750 = bitcast i8* %t749 to { i64, i64, i8**, i8** }*
  %t751 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t750, i32 0, i32 0
  store i64 %t743, i64* %t751
  %t752 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t750, i32 0, i32 1
  store i64 %t745, i64* %t752
  %t753 = getelementptr i8*, i8** null, i32 1
  %t754 = ptrtoint i8** %t753 to i64
  %t755 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t741, i32 0, i32 2
  %t756 = load i8**, i8*** %t755
  %t757 = mul i64 %t745, %t754
  %t758 = call i8* @malloc(i64 %t757)
  %t759 = bitcast i8* %t758 to i8**
  %t760 = icmp sgt i64 %t743, 0
  br i1 %t760, label %table_cow_copy_130, label %table_cow_after_copy_131
table_cow_copy_130:
  %t761 = mul i64 %t743, %t754
  %t762 = bitcast i8** %t756 to i8*
  call i8* @memcpy(i8* %t758, i8* %t762, i64 %t761)
  %t763 = alloca i64
  store i64 0, i64* %t763
  br label %table_cow_retain_cond_132
table_cow_retain_cond_132:
  %t764 = load i64, i64* %t763
  %t765 = icmp slt i64 %t764, %t743
  br i1 %t765, label %table_cow_retain_body_133, label %table_cow_retain_end_134
table_cow_retain_body_133:
  %t766 = getelementptr inbounds i8*, i8** %t759, i64 %t764
  %t767 = load i8*, i8** %t766
  call void @star_rc_retain(i8* %t767)
  %t768 = add i64 %t764, 1
  store i64 %t768, i64* %t763
  br label %table_cow_retain_cond_132
table_cow_retain_end_134:
  br label %table_cow_after_copy_131
table_cow_after_copy_131:
  %t769 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t750, i32 0, i32 2
  store i8** %t759, i8*** %t769
  %t770 = getelementptr i8*, i8** null, i32 1
  %t771 = ptrtoint i8** %t770 to i64
  %t772 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t741, i32 0, i32 3
  %t773 = load i8**, i8*** %t772
  %t774 = mul i64 %t745, %t771
  %t775 = call i8* @malloc(i64 %t774)
  %t776 = bitcast i8* %t775 to i8**
  %t777 = icmp sgt i64 %t743, 0
  br i1 %t777, label %table_cow_copy_135, label %table_cow_after_copy_136
table_cow_copy_135:
  %t778 = mul i64 %t743, %t771
  %t779 = bitcast i8** %t773 to i8*
  call i8* @memcpy(i8* %t775, i8* %t779, i64 %t778)
  %t780 = alloca i64
  store i64 0, i64* %t780
  br label %table_cow_retain_cond_137
table_cow_retain_cond_137:
  %t781 = load i64, i64* %t780
  %t782 = icmp slt i64 %t781, %t743
  br i1 %t782, label %table_cow_retain_body_138, label %table_cow_retain_end_139
table_cow_retain_body_138:
  %t783 = getelementptr inbounds i8*, i8** %t776, i64 %t781
  %t784 = load i8*, i8** %t783
  call void @star_rc_retain(i8* %t784)
  %t785 = add i64 %t781, 1
  store i64 %t785, i64* %t780
  br label %table_cow_retain_cond_137
table_cow_retain_end_139:
  br label %table_cow_after_copy_136
table_cow_after_copy_136:
  %t786 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t750, i32 0, i32 3
  store i8** %t776, i8*** %t786
  call void @star_rc_release(i8* %t705)
  store i8* %t749, i8** %t704
  br label %table_cow_done_122
table_cow_done_122:
  %t787 = load i8*, i8** %t704
  %t788 = bitcast i8* %t787 to { i64, i64, i8**, i8** }*
  %t789 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t788, i32 0, i32 0
  %t790 = load i64, i64* %t789
  %t791 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t788, i32 0, i32 1
  %t792 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t788, i32 0, i32 2
  %t793 = load i8**, i8*** %t792
  %t794 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t788, i32 0, i32 3
  %t795 = load i8**, i8*** %t794
  %t796 = alloca %Bag
  %t797 = getelementptr i32, i32* null, i32 1
  %t798 = ptrtoint i32* %t797 to i64
  %t799 = mul i64 %t798, 3
  %t800 = call i8* @malloc(i64 %t799)
  %t801 = bitcast i8* %t800 to i32*
  %t802 = getelementptr inbounds i32, i32* %t801, i64 0
  store i32 7, i32* %t802
  %t803 = getelementptr inbounds i32, i32* %t801, i64 1
  store i32 8, i32* %t803
  %t804 = getelementptr inbounds i32, i32* %t801, i64 2
  store i32 9, i32* %t804
  %t805 = bitcast void (i8*)* @list_release_i32 to i8*
  %t806 = call i8* @star_rc_alloc(i64 24, i8* %t805)
  %t807 = bitcast i8* %t806 to { i32*, i64, i64 }*
  %t808 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t807, i32 0, i32 0
  store i32* %t801, i32** %t808
  %t809 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t807, i32 0, i32 1
  store i64 3, i64* %t809
  %t810 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t807, i32 0, i32 2
  store i64 3, i64* %t810
  %t811 = getelementptr inbounds %Bag, %Bag* %t796, i32 0, i32 0
  store i8* %t806, i8** %t811
  %t812 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t813 = getelementptr inbounds %Bag, %Bag* %t796, i32 0, i32 1
  store i8* %t812, i8** %t813
  %t814 = load %Bag, %Bag* %t796
  %t815 = load i64, i64* %t791
  %t816 = icmp sge i64 %t790, %t815
  br i1 %t816, label %table_push_grow_140, label %table_push_store_141
table_push_grow_140:
  %t817 = mul i64 %t815, 2
  %t818 = icmp sgt i64 %t817, 0
  %t819 = select i1 %t818, i64 %t817, i64 1
  %t820 = getelementptr i8*, i8** null, i32 1
  %t821 = ptrtoint i8** %t820 to i64
  %t822 = mul i64 %t819, %t821
  %t823 = call i8* @malloc(i64 %t822)
  %t824 = bitcast i8* %t823 to i8**
  %t825 = icmp sgt i64 %t815, 0
  br i1 %t825, label %table_push_copy_142, label %table_push_after_copy_143
table_push_copy_142:
  %t826 = mul i64 %t790, %t821
  %t827 = bitcast i8** %t793 to i8*
  call i8* @memcpy(i8* %t823, i8* %t827, i64 %t826)
  call void @free(i8* %t827)
  br label %table_push_after_copy_143
table_push_after_copy_143:
  store i8** %t824, i8*** %t792
  %t828 = getelementptr i8*, i8** null, i32 1
  %t829 = ptrtoint i8** %t828 to i64
  %t830 = mul i64 %t819, %t829
  %t831 = call i8* @malloc(i64 %t830)
  %t832 = bitcast i8* %t831 to i8**
  %t833 = icmp sgt i64 %t815, 0
  br i1 %t833, label %table_push_copy_144, label %table_push_after_copy_145
table_push_copy_144:
  %t834 = mul i64 %t790, %t829
  %t835 = bitcast i8** %t795 to i8*
  call i8* @memcpy(i8* %t831, i8* %t835, i64 %t834)
  call void @free(i8* %t835)
  br label %table_push_after_copy_145
table_push_after_copy_145:
  store i8** %t832, i8*** %t794
  store i64 %t819, i64* %t791
  br label %table_push_store_141
table_push_store_141:
  %t836 = load i8**, i8*** %t792
  %t837 = extractvalue %Bag %t814, 0
  %t838 = getelementptr inbounds i8*, i8** %t836, i64 %t790
  store i8* %t837, i8** %t838
  %t839 = load i8**, i8*** %t794
  %t840 = extractvalue %Bag %t814, 1
  %t841 = getelementptr inbounds i8*, i8** %t839, i64 %t790
  store i8* %t840, i8** %t841
  %t842 = add i64 %t790, 1
  store i64 %t842, i64* %t789
  %t843 = load i8*, i8** %t704
  %t844 = icmp eq i8* %t843, null
  br i1 %t844, label %table_cow_alloc_146, label %table_cow_check_147
table_cow_alloc_146:
  %t845 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t846 = getelementptr { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* null, i32 1
  %t847 = ptrtoint { i64, i64, i8**, i8** }* %t846 to i64
  %t848 = call i8* @star_rc_alloc(i64 %t847, i8* %t845)
  %t849 = bitcast i8* %t848 to { i64, i64, i8**, i8** }*
  %t850 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t849, i32 0, i32 0
  store i64 0, i64* %t850
  %t851 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t849, i32 0, i32 1
  store i64 0, i64* %t851
  %t852 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t849, i32 0, i32 2
  store i8** null, i8*** %t852
  %t853 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t849, i32 0, i32 3
  store i8** null, i8*** %t853
  store i8* %t848, i8** %t704
  br label %table_cow_done_148
table_cow_check_147:
  %t854 = getelementptr inbounds i8, i8* %t843, i64 -16
  %t855 = bitcast i8* %t854 to i64*
  %t856 = load atomic i64, i64* %t855 seq_cst, align 8
  %t857 = icmp eq i64 %t856, 1
  br i1 %t857, label %table_cow_done_148, label %table_cow_clone_149
table_cow_clone_149:
  %t858 = bitcast i8* %t843 to { i64, i64, i8**, i8** }*
  %t859 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t858, i32 0, i32 0
  %t860 = load i64, i64* %t859
  %t861 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t858, i32 0, i32 1
  %t862 = load i64, i64* %t861
  %t863 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t864 = getelementptr { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* null, i32 1
  %t865 = ptrtoint { i64, i64, i8**, i8** }* %t864 to i64
  %t866 = call i8* @star_rc_alloc(i64 %t865, i8* %t863)
  %t867 = bitcast i8* %t866 to { i64, i64, i8**, i8** }*
  %t868 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t867, i32 0, i32 0
  store i64 %t860, i64* %t868
  %t869 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t867, i32 0, i32 1
  store i64 %t862, i64* %t869
  %t870 = getelementptr i8*, i8** null, i32 1
  %t871 = ptrtoint i8** %t870 to i64
  %t872 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t858, i32 0, i32 2
  %t873 = load i8**, i8*** %t872
  %t874 = mul i64 %t862, %t871
  %t875 = call i8* @malloc(i64 %t874)
  %t876 = bitcast i8* %t875 to i8**
  %t877 = icmp sgt i64 %t860, 0
  br i1 %t877, label %table_cow_copy_150, label %table_cow_after_copy_151
table_cow_copy_150:
  %t878 = mul i64 %t860, %t871
  %t879 = bitcast i8** %t873 to i8*
  call i8* @memcpy(i8* %t875, i8* %t879, i64 %t878)
  %t880 = alloca i64
  store i64 0, i64* %t880
  br label %table_cow_retain_cond_152
table_cow_retain_cond_152:
  %t881 = load i64, i64* %t880
  %t882 = icmp slt i64 %t881, %t860
  br i1 %t882, label %table_cow_retain_body_153, label %table_cow_retain_end_154
table_cow_retain_body_153:
  %t883 = getelementptr inbounds i8*, i8** %t876, i64 %t881
  %t884 = load i8*, i8** %t883
  call void @star_rc_retain(i8* %t884)
  %t885 = add i64 %t881, 1
  store i64 %t885, i64* %t880
  br label %table_cow_retain_cond_152
table_cow_retain_end_154:
  br label %table_cow_after_copy_151
table_cow_after_copy_151:
  %t886 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t867, i32 0, i32 2
  store i8** %t876, i8*** %t886
  %t887 = getelementptr i8*, i8** null, i32 1
  %t888 = ptrtoint i8** %t887 to i64
  %t889 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t858, i32 0, i32 3
  %t890 = load i8**, i8*** %t889
  %t891 = mul i64 %t862, %t888
  %t892 = call i8* @malloc(i64 %t891)
  %t893 = bitcast i8* %t892 to i8**
  %t894 = icmp sgt i64 %t860, 0
  br i1 %t894, label %table_cow_copy_155, label %table_cow_after_copy_156
table_cow_copy_155:
  %t895 = mul i64 %t860, %t888
  %t896 = bitcast i8** %t890 to i8*
  call i8* @memcpy(i8* %t892, i8* %t896, i64 %t895)
  %t897 = alloca i64
  store i64 0, i64* %t897
  br label %table_cow_retain_cond_157
table_cow_retain_cond_157:
  %t898 = load i64, i64* %t897
  %t899 = icmp slt i64 %t898, %t860
  br i1 %t899, label %table_cow_retain_body_158, label %table_cow_retain_end_159
table_cow_retain_body_158:
  %t900 = getelementptr inbounds i8*, i8** %t893, i64 %t898
  %t901 = load i8*, i8** %t900
  call void @star_rc_retain(i8* %t901)
  %t902 = add i64 %t898, 1
  store i64 %t902, i64* %t897
  br label %table_cow_retain_cond_157
table_cow_retain_end_159:
  br label %table_cow_after_copy_156
table_cow_after_copy_156:
  %t903 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t867, i32 0, i32 3
  store i8** %t893, i8*** %t903
  call void @star_rc_release(i8* %t843)
  store i8* %t866, i8** %t704
  br label %table_cow_done_148
table_cow_done_148:
  %t904 = load i8*, i8** %t704
  %t905 = bitcast i8* %t904 to { i64, i64, i8**, i8** }*
  %t906 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t905, i32 0, i32 0
  %t907 = load i64, i64* %t906
  %t908 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t905, i32 0, i32 1
  %t909 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t905, i32 0, i32 2
  %t910 = load i8**, i8*** %t909
  %t911 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t905, i32 0, i32 3
  %t912 = load i8**, i8*** %t911
  %t913 = alloca %Bag
  %t914 = getelementptr inbounds %Bag, %Bag* %t913, i32 0, i32 0
  store i8* null, i8** %t914
  %t915 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t916 = getelementptr inbounds %Bag, %Bag* %t913, i32 0, i32 1
  store i8* %t915, i8** %t916
  %t917 = load %Bag, %Bag* %t913
  %t918 = load i64, i64* %t908
  %t919 = icmp sge i64 %t907, %t918
  br i1 %t919, label %table_push_grow_160, label %table_push_store_161
table_push_grow_160:
  %t920 = mul i64 %t918, 2
  %t921 = icmp sgt i64 %t920, 0
  %t922 = select i1 %t921, i64 %t920, i64 1
  %t923 = getelementptr i8*, i8** null, i32 1
  %t924 = ptrtoint i8** %t923 to i64
  %t925 = mul i64 %t922, %t924
  %t926 = call i8* @malloc(i64 %t925)
  %t927 = bitcast i8* %t926 to i8**
  %t928 = icmp sgt i64 %t918, 0
  br i1 %t928, label %table_push_copy_162, label %table_push_after_copy_163
table_push_copy_162:
  %t929 = mul i64 %t907, %t924
  %t930 = bitcast i8** %t910 to i8*
  call i8* @memcpy(i8* %t926, i8* %t930, i64 %t929)
  call void @free(i8* %t930)
  br label %table_push_after_copy_163
table_push_after_copy_163:
  store i8** %t927, i8*** %t909
  %t931 = getelementptr i8*, i8** null, i32 1
  %t932 = ptrtoint i8** %t931 to i64
  %t933 = mul i64 %t922, %t932
  %t934 = call i8* @malloc(i64 %t933)
  %t935 = bitcast i8* %t934 to i8**
  %t936 = icmp sgt i64 %t918, 0
  br i1 %t936, label %table_push_copy_164, label %table_push_after_copy_165
table_push_copy_164:
  %t937 = mul i64 %t907, %t932
  %t938 = bitcast i8** %t912 to i8*
  call i8* @memcpy(i8* %t934, i8* %t938, i64 %t937)
  call void @free(i8* %t938)
  br label %table_push_after_copy_165
table_push_after_copy_165:
  store i8** %t935, i8*** %t911
  store i64 %t922, i64* %t908
  br label %table_push_store_161
table_push_store_161:
  %t939 = load i8**, i8*** %t909
  %t940 = extractvalue %Bag %t917, 0
  %t941 = getelementptr inbounds i8*, i8** %t939, i64 %t907
  store i8* %t940, i8** %t941
  %t942 = load i8**, i8*** %t911
  %t943 = extractvalue %Bag %t917, 1
  %t944 = getelementptr inbounds i8*, i8** %t942, i64 %t907
  store i8* %t943, i8** %t944
  %t945 = add i64 %t907, 1
  store i64 %t945, i64* %t906
  %t946 = load i8*, i8** %t704
  %t947 = icmp eq i8* %t946, null
  br i1 %t947, label %table_read_null_166, label %table_read_real_167
table_read_null_166:
  br label %table_read_end_168
table_read_real_167:
  %t948 = bitcast i8* %t946 to { i64, i64, i8**, i8** }*
  %t949 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t948, i32 0, i32 0
  %t950 = load i64, i64* %t949
  %t951 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t948, i32 0, i32 2
  %t952 = load i8**, i8*** %t951
  %t953 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t948, i32 0, i32 3
  %t954 = load i8**, i8*** %t953
  br label %table_read_end_168
table_read_end_168:
  %t955 = phi i64 [ 0, %table_read_null_166 ], [ %t950, %table_read_real_167 ]
  %t956 = phi i8** [ null, %table_read_null_166 ], [ %t952, %table_read_real_167 ]
  %t957 = phi i8** [ null, %table_read_null_166 ], [ %t954, %table_read_real_167 ]
  %t958 = sext i32 0 to i64
  %t959 = alloca %Bag
  %t960 = icmp ult i64 %t958, %t955
  br i1 %t960, label %table_idx_ok_169, label %table_idx_oob_170
table_idx_ok_169:
  %t961 = getelementptr inbounds i8*, i8** %t956, i64 %t958
  %t962 = load i8*, i8** %t961
  call void @star_rc_retain(i8* %t962)
  %t963 = load i8*, i8** %t961
  %t964 = getelementptr inbounds %Bag, %Bag* %t959, i32 0, i32 0
  store i8* %t963, i8** %t964
  %t965 = getelementptr inbounds i8*, i8** %t957, i64 %t958
  %t966 = load i8*, i8** %t965
  call void @star_rc_retain(i8* %t966)
  %t967 = load i8*, i8** %t965
  %t968 = getelementptr inbounds %Bag, %Bag* %t959, i32 0, i32 1
  store i8* %t967, i8** %t968
  br label %table_idx_end_171
table_idx_oob_170:
  store %Bag zeroinitializer, %Bag* %t959
  br label %table_idx_end_171
table_idx_end_171:
  %t969 = load %Bag, %Bag* %t959
  %t970 = alloca %Bag
  store %Bag %t969, %Bag* %t970
  %t971 = getelementptr inbounds %Bag, %Bag* %t970, i32 0, i32 1
  %t972 = load i8*, i8** %t971
  %t973 = load i8*, i8** %t971
  call void @star_rc_retain(i8* %t973)
  call void @star_rc_release(i8* %t972)
  %t974 = load i8*, i8** %t704
  %t975 = icmp eq i8* %t974, null
  br i1 %t975, label %table_read_null_172, label %table_read_real_173
table_read_null_172:
  br label %table_read_end_174
table_read_real_173:
  %t976 = bitcast i8* %t974 to { i64, i64, i8**, i8** }*
  %t977 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t976, i32 0, i32 0
  %t978 = load i64, i64* %t977
  %t979 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t976, i32 0, i32 2
  %t980 = load i8**, i8*** %t979
  %t981 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t976, i32 0, i32 3
  %t982 = load i8**, i8*** %t981
  br label %table_read_end_174
table_read_end_174:
  %t983 = phi i64 [ 0, %table_read_null_172 ], [ %t978, %table_read_real_173 ]
  %t984 = phi i8** [ null, %table_read_null_172 ], [ %t980, %table_read_real_173 ]
  %t985 = phi i8** [ null, %table_read_null_172 ], [ %t982, %table_read_real_173 ]
  %t986 = sext i32 0 to i64
  %t987 = alloca %Bag
  %t988 = icmp ult i64 %t986, %t983
  br i1 %t988, label %table_idx_ok_175, label %table_idx_oob_176
table_idx_ok_175:
  %t989 = getelementptr inbounds i8*, i8** %t984, i64 %t986
  %t990 = load i8*, i8** %t989
  call void @star_rc_retain(i8* %t990)
  %t991 = load i8*, i8** %t989
  %t992 = getelementptr inbounds %Bag, %Bag* %t987, i32 0, i32 0
  store i8* %t991, i8** %t992
  %t993 = getelementptr inbounds i8*, i8** %t985, i64 %t986
  %t994 = load i8*, i8** %t993
  call void @star_rc_retain(i8* %t994)
  %t995 = load i8*, i8** %t993
  %t996 = getelementptr inbounds %Bag, %Bag* %t987, i32 0, i32 1
  store i8* %t995, i8** %t996
  br label %table_idx_end_177
table_idx_oob_176:
  store %Bag zeroinitializer, %Bag* %t987
  br label %table_idx_end_177
table_idx_end_177:
  %t997 = load %Bag, %Bag* %t987
  %t998 = alloca %Bag
  store %Bag %t997, %Bag* %t998
  %t999 = getelementptr inbounds %Bag, %Bag* %t998, i32 0, i32 0
  %t1000 = load i8*, i8** %t999
  %t1001 = icmp eq i8* %t1000, null
  br i1 %t1001, label %list_read_null_178, label %list_read_real_179
list_read_null_178:
  br label %list_read_end_180
list_read_real_179:
  %t1002 = bitcast i8* %t1000 to { i32*, i64, i64 }*
  %t1003 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1002, i32 0, i32 0
  %t1004 = load i32*, i32** %t1003
  %t1005 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1002, i32 0, i32 1
  %t1006 = load i64, i64* %t1005
  br label %list_read_end_180
list_read_end_180:
  %t1007 = phi i32* [ null, %list_read_null_178 ], [ %t1004, %list_read_real_179 ]
  %t1008 = phi i64 [ 0, %list_read_null_178 ], [ %t1006, %list_read_real_179 ]
  %t1009 = trunc i64 %t1008 to i32
  %t1010 = getelementptr inbounds [41 x i8], [41 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1010, i8* %t972, i32 %t1009)
  %t1011 = load i8*, i8** %t704
  %t1012 = icmp eq i8* %t1011, null
  br i1 %t1012, label %table_read_null_181, label %table_read_real_182
table_read_null_181:
  br label %table_read_end_183
table_read_real_182:
  %t1013 = bitcast i8* %t1011 to { i64, i64, i8**, i8** }*
  %t1014 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1013, i32 0, i32 0
  %t1015 = load i64, i64* %t1014
  %t1016 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1013, i32 0, i32 2
  %t1017 = load i8**, i8*** %t1016
  %t1018 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1013, i32 0, i32 3
  %t1019 = load i8**, i8*** %t1018
  br label %table_read_end_183
table_read_end_183:
  %t1020 = phi i64 [ 0, %table_read_null_181 ], [ %t1015, %table_read_real_182 ]
  %t1021 = phi i8** [ null, %table_read_null_181 ], [ %t1017, %table_read_real_182 ]
  %t1022 = phi i8** [ null, %table_read_null_181 ], [ %t1019, %table_read_real_182 ]
  %t1023 = sext i32 1 to i64
  %t1024 = alloca %Bag
  %t1025 = icmp ult i64 %t1023, %t1020
  br i1 %t1025, label %table_idx_ok_184, label %table_idx_oob_185
table_idx_ok_184:
  %t1026 = getelementptr inbounds i8*, i8** %t1021, i64 %t1023
  %t1027 = load i8*, i8** %t1026
  call void @star_rc_retain(i8* %t1027)
  %t1028 = load i8*, i8** %t1026
  %t1029 = getelementptr inbounds %Bag, %Bag* %t1024, i32 0, i32 0
  store i8* %t1028, i8** %t1029
  %t1030 = getelementptr inbounds i8*, i8** %t1022, i64 %t1023
  %t1031 = load i8*, i8** %t1030
  call void @star_rc_retain(i8* %t1031)
  %t1032 = load i8*, i8** %t1030
  %t1033 = getelementptr inbounds %Bag, %Bag* %t1024, i32 0, i32 1
  store i8* %t1032, i8** %t1033
  br label %table_idx_end_186
table_idx_oob_185:
  store %Bag zeroinitializer, %Bag* %t1024
  br label %table_idx_end_186
table_idx_end_186:
  %t1034 = load %Bag, %Bag* %t1024
  %t1035 = alloca %Bag
  store %Bag %t1034, %Bag* %t1035
  %t1036 = getelementptr inbounds %Bag, %Bag* %t1035, i32 0, i32 1
  %t1037 = load i8*, i8** %t1036
  %t1038 = load i8*, i8** %t1036
  call void @star_rc_retain(i8* %t1038)
  call void @star_rc_release(i8* %t1037)
  %t1039 = load i8*, i8** %t704
  %t1040 = icmp eq i8* %t1039, null
  br i1 %t1040, label %table_read_null_187, label %table_read_real_188
table_read_null_187:
  br label %table_read_end_189
table_read_real_188:
  %t1041 = bitcast i8* %t1039 to { i64, i64, i8**, i8** }*
  %t1042 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1041, i32 0, i32 0
  %t1043 = load i64, i64* %t1042
  %t1044 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1041, i32 0, i32 2
  %t1045 = load i8**, i8*** %t1044
  %t1046 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1041, i32 0, i32 3
  %t1047 = load i8**, i8*** %t1046
  br label %table_read_end_189
table_read_end_189:
  %t1048 = phi i64 [ 0, %table_read_null_187 ], [ %t1043, %table_read_real_188 ]
  %t1049 = phi i8** [ null, %table_read_null_187 ], [ %t1045, %table_read_real_188 ]
  %t1050 = phi i8** [ null, %table_read_null_187 ], [ %t1047, %table_read_real_188 ]
  %t1051 = sext i32 1 to i64
  %t1052 = alloca %Bag
  %t1053 = icmp ult i64 %t1051, %t1048
  br i1 %t1053, label %table_idx_ok_190, label %table_idx_oob_191
table_idx_ok_190:
  %t1054 = getelementptr inbounds i8*, i8** %t1049, i64 %t1051
  %t1055 = load i8*, i8** %t1054
  call void @star_rc_retain(i8* %t1055)
  %t1056 = load i8*, i8** %t1054
  %t1057 = getelementptr inbounds %Bag, %Bag* %t1052, i32 0, i32 0
  store i8* %t1056, i8** %t1057
  %t1058 = getelementptr inbounds i8*, i8** %t1050, i64 %t1051
  %t1059 = load i8*, i8** %t1058
  call void @star_rc_retain(i8* %t1059)
  %t1060 = load i8*, i8** %t1058
  %t1061 = getelementptr inbounds %Bag, %Bag* %t1052, i32 0, i32 1
  store i8* %t1060, i8** %t1061
  br label %table_idx_end_192
table_idx_oob_191:
  store %Bag zeroinitializer, %Bag* %t1052
  br label %table_idx_end_192
table_idx_end_192:
  %t1062 = load %Bag, %Bag* %t1052
  %t1063 = alloca %Bag
  store %Bag %t1062, %Bag* %t1063
  %t1064 = getelementptr inbounds %Bag, %Bag* %t1063, i32 0, i32 0
  %t1065 = load i8*, i8** %t1064
  %t1066 = icmp eq i8* %t1065, null
  br i1 %t1066, label %list_read_null_193, label %list_read_real_194
list_read_null_193:
  br label %list_read_end_195
list_read_real_194:
  %t1067 = bitcast i8* %t1065 to { i32*, i64, i64 }*
  %t1068 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1067, i32 0, i32 0
  %t1069 = load i32*, i32** %t1068
  %t1070 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1067, i32 0, i32 1
  %t1071 = load i64, i64* %t1070
  br label %list_read_end_195
list_read_end_195:
  %t1072 = phi i32* [ null, %list_read_null_193 ], [ %t1069, %list_read_real_194 ]
  %t1073 = phi i64 [ 0, %list_read_null_193 ], [ %t1071, %list_read_real_194 ]
  %t1074 = trunc i64 %t1073 to i32
  %t1075 = getelementptr inbounds [41 x i8], [41 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1075, i8* %t1037, i32 %t1074)
  %t1076 = load i8*, i8** %t704
  call void @star_rc_release(i8* %t1076)
  %t1077 = load i8*, i8** %t480
  call void @star_rc_release(i8* %t1077)
  %t1078 = load i8*, i8** %t290
  call void @star_rc_release(i8* %t1078)
  %t1079 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t102, i32 0, i32 0
  %t1080 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t1079, i32 0, i64 0
  %t1081 = getelementptr inbounds %Bag, %Bag* %t1080, i32 0, i32 0
  %t1082 = load i8*, i8** %t1081
  call void @star_rc_release(i8* %t1082)
  %t1083 = getelementptr inbounds %Bag, %Bag* %t1080, i32 0, i32 1
  %t1084 = load i8*, i8** %t1083
  call void @star_rc_release(i8* %t1084)
  %t1085 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t1079, i32 0, i64 1
  %t1086 = getelementptr inbounds %Bag, %Bag* %t1085, i32 0, i32 0
  %t1087 = load i8*, i8** %t1086
  call void @star_rc_release(i8* %t1087)
  %t1088 = getelementptr inbounds %Bag, %Bag* %t1085, i32 0, i32 1
  %t1089 = load i8*, i8** %t1088
  call void @star_rc_release(i8* %t1089)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_i32(i8* %objp) {
entry:
  %t117 = bitcast i8* %objp to { i32*, i64, i64 }*
  %t118 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t117, i32 0, i32 0
  %t119 = load i32*, i32** %t118
  %t120 = bitcast i32* %t119 to i8*
  call void @free(i8* %t120)
  ret void
}


define void @table_release_s_Point(i8* %objp) {
entry:
  %t293 = bitcast i8* %objp to { i64, i64, i32*, i32* }*
  %t294 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t293, i32 0, i32 0
  %t295 = load i64, i64* %t294
  %t296 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t293, i32 0, i32 2
  %t297 = load i32*, i32** %t296
  %t298 = bitcast i32* %t297 to i8*
  call void @free(i8* %t298)
  %t299 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t293, i32 0, i32 3
  %t300 = load i32*, i32** %t299
  %t301 = bitcast i32* %t300 to i8*
  call void @free(i8* %t301)
  ret void
}


define void @table_release_s_Bag(i8* %objp) {
entry:
  %t707 = bitcast i8* %objp to { i64, i64, i8**, i8** }*
  %t708 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t707, i32 0, i32 0
  %t709 = load i64, i64* %t708
  %t710 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t707, i32 0, i32 2
  %t711 = load i8**, i8*** %t710
  %t712 = alloca i64
  store i64 0, i64* %t712
  br label %table_release_cond_123
table_release_cond_123:
  %t713 = load i64, i64* %t712
  %t714 = icmp slt i64 %t713, %t709
  br i1 %t714, label %table_release_body_124, label %table_release_end_125
table_release_body_124:
  %t715 = getelementptr inbounds i8*, i8** %t711, i64 %t713
  %t716 = load i8*, i8** %t715
  call void @star_rc_release(i8* %t716)
  %t717 = add i64 %t713, 1
  store i64 %t717, i64* %t712
  br label %table_release_cond_123
table_release_end_125:
  %t718 = bitcast i8** %t711 to i8*
  call void @free(i8* %t718)
  %t719 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t707, i32 0, i32 3
  %t720 = load i8**, i8*** %t719
  %t721 = alloca i64
  store i64 0, i64* %t721
  br label %table_release_cond_126
table_release_cond_126:
  %t722 = load i64, i64* %t721
  %t723 = icmp slt i64 %t722, %t709
  br i1 %t723, label %table_release_body_127, label %table_release_end_128
table_release_body_127:
  %t724 = getelementptr inbounds i8*, i8** %t720, i64 %t722
  %t725 = load i8*, i8** %t724
  call void @star_rc_release(i8* %t725)
  %t726 = add i64 %t722, 1
  store i64 %t726, i64* %t721
  br label %table_release_cond_126
table_release_end_128:
  %t727 = bitcast i8** %t720 to i8*
  call void @free(i8* %t727)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant [20 x i8] c"r1 len=%d r1[0]=%d\0A\00"
@.str.1 = private unnamed_addr constant [11 x i8] c"r2[-1]=%d\0A\00"
@.str.2 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"first\00" }
@.str.3 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"second\00" }
@.str.4 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"third\00" }
@.str.5 = private unnamed_addr constant [37 x i8] c"r3[0].label=%s r3[0].items.len()=%d\0A\00"
@.str.6 = private unnamed_addr constant [37 x i8] c"r3[1].label=%s r3[1].items.len()=%d\0A\00"
@.str.7 = private unnamed_addr constant [25 x i8] c"pts len=%d clone len=%d\0A\00"
@.str.8 = private unnamed_addr constant [19 x i8] c"pts[1] = (%d, %d)\0A\00"
@.str.9 = private unnamed_addr constant [20 x i8] c"pts[-1] = (%d, %d)\0A\00"
@.str.10 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"alpha\00" }
@.str.11 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"beta\00" }
@.str.12 = private unnamed_addr constant [41 x i8] c"bags[0].label=%s bags[0].items.len()=%d\0A\00"
@.str.13 = private unnamed_addr constant [41 x i8] c"bags[1].label=%s bags[1].items.len()=%d\0A\00"
