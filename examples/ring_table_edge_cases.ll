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
  %t0 = alloca { [1 x i32], i64, i64 }
  %t58 = alloca i32
  %t62 = alloca { [3 x i32], i64, i64 }
  %t102 = alloca i32
  %t106 = alloca { [2 x %Bag], i64, i64 }
  %t107 = alloca %Bag
  %t147 = alloca %Bag
  %t182 = alloca %Bag
  %t228 = alloca %Bag
  %t245 = alloca %Bag
  %t271 = alloca %Bag
  %t288 = alloca %Bag
  %t302 = alloca i8*
  %t370 = alloca %Point
  %t463 = alloca %Point
  %t498 = alloca i8*
  %t559 = alloca %Point
  %t634 = alloca %Point
  %t643 = alloca %Point
  %t659 = alloca %Point
  %t668 = alloca %Point
  %t686 = alloca %Point
  %t695 = alloca %Point
  %t712 = alloca %Point
  %t721 = alloca %Point
  %t725 = alloca i8*
  %t784 = alloca i64
  %t801 = alloca i64
  %t817 = alloca %Bag
  %t904 = alloca i64
  %t921 = alloca i64
  %t937 = alloca %Bag
  %t986 = alloca %Bag
  %t997 = alloca %Bag
  %t1014 = alloca %Bag
  %t1025 = alloca %Bag
  %t1051 = alloca %Bag
  %t1062 = alloca %Bag
  %t1079 = alloca %Bag
  %t1090 = alloca %Bag
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
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
  %t52 = load i64, i64* %t47
  %t53 = load i64, i64* %t49
  %t54 = icmp ult i64 %t51, %t53
  br i1 %t54, label %ring_rplace_ok_9, label %ring_rplace_oob_10
ring_rplace_ok_9:
  %t55 = add i64 %t52, %t51
  %t56 = urem i64 %t55, 1
  %t57 = getelementptr inbounds [1 x i32], [1 x i32]* %t46, i32 0, i64 %t56
  br label %ring_rplace_end_11
ring_rplace_oob_10:
  store i32 0, i32* %t58
  br label %ring_rplace_end_11
ring_rplace_end_11:
  %t59 = phi i32* [ %t57, %ring_rplace_ok_9 ], [ %t58, %ring_rplace_oob_10 ]
  %t60 = load i32, i32* %t59
  %t61 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t61, i32 %t45, i32 %t60)
  store { [3 x i32], i64, i64 } zeroinitializer, { [3 x i32], i64, i64 }* %t62
  %t63 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t62, i32 0, i32 0
  %t64 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t62, i32 0, i32 1
  %t65 = load i64, i64* %t64
  %t66 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t62, i32 0, i32 2
  %t67 = load i64, i64* %t66
  %t68 = icmp sge i64 %t67, 3
  br i1 %t68, label %ring_push_full_12, label %ring_push_grow_13
ring_push_grow_13:
  %t69 = add i64 %t65, %t67
  %t70 = urem i64 %t69, 3
  %t71 = getelementptr inbounds [3 x i32], [3 x i32]* %t63, i32 0, i64 %t70
  store i32 1, i32* %t71
  %t72 = add i64 %t67, 1
  store i64 %t72, i64* %t66
  br label %ring_push_done_14
ring_push_full_12:
  %t73 = getelementptr inbounds [3 x i32], [3 x i32]* %t63, i32 0, i64 %t65
  store i32 1, i32* %t73
  %t74 = add i64 %t65, 1
  %t75 = urem i64 %t74, 3
  store i64 %t75, i64* %t64
  br label %ring_push_done_14
ring_push_done_14:
  %t76 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t62, i32 0, i32 0
  %t77 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t62, i32 0, i32 1
  %t78 = load i64, i64* %t77
  %t79 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t62, i32 0, i32 2
  %t80 = load i64, i64* %t79
  %t81 = icmp sge i64 %t80, 3
  br i1 %t81, label %ring_push_full_15, label %ring_push_grow_16
ring_push_grow_16:
  %t82 = add i64 %t78, %t80
  %t83 = urem i64 %t82, 3
  %t84 = getelementptr inbounds [3 x i32], [3 x i32]* %t76, i32 0, i64 %t83
  store i32 2, i32* %t84
  %t85 = add i64 %t80, 1
  store i64 %t85, i64* %t79
  br label %ring_push_done_17
ring_push_full_15:
  %t86 = getelementptr inbounds [3 x i32], [3 x i32]* %t76, i32 0, i64 %t78
  store i32 2, i32* %t86
  %t87 = add i64 %t78, 1
  %t88 = urem i64 %t87, 3
  store i64 %t88, i64* %t77
  br label %ring_push_done_17
ring_push_done_17:
  %t89 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t62, i32 0, i32 0
  %t90 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t62, i32 0, i32 1
  %t91 = load i64, i64* %t90
  %t92 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t62, i32 0, i32 2
  %t93 = load i64, i64* %t92
  %t94 = sub i32 0, 1
  %t95 = sext i32 %t94 to i64
  %t96 = load i64, i64* %t90
  %t97 = load i64, i64* %t92
  %t98 = icmp ult i64 %t95, %t97
  br i1 %t98, label %ring_rplace_ok_18, label %ring_rplace_oob_19
ring_rplace_ok_18:
  %t99 = add i64 %t96, %t95
  %t100 = urem i64 %t99, 3
  %t101 = getelementptr inbounds [3 x i32], [3 x i32]* %t89, i32 0, i64 %t100
  br label %ring_rplace_end_20
ring_rplace_oob_19:
  store i32 0, i32* %t102
  br label %ring_rplace_end_20
ring_rplace_end_20:
  %t103 = phi i32* [ %t101, %ring_rplace_ok_18 ], [ %t102, %ring_rplace_oob_19 ]
  %t104 = load i32, i32* %t103
  %t105 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t105, i32 %t104)
  store { [2 x %Bag], i64, i64 } zeroinitializer, { [2 x %Bag], i64, i64 }* %t106
  %t108 = getelementptr i32, i32* null, i32 1
  %t109 = ptrtoint i32* %t108 to i64
  %t110 = mul i64 %t109, 3
  %t111 = call i8* @malloc(i64 %t110)
  %t112 = bitcast i8* %t111 to i32*
  %t113 = getelementptr inbounds i32, i32* %t112, i64 0
  store i32 1, i32* %t113
  %t114 = getelementptr inbounds i32, i32* %t112, i64 1
  store i32 2, i32* %t114
  %t115 = getelementptr inbounds i32, i32* %t112, i64 2
  store i32 3, i32* %t115
  %t120 = bitcast void (i8*)* @list_release_i32 to i8*
  %t121 = call i8* @star_rc_alloc(i64 24, i8* %t120)
  %t122 = bitcast i8* %t121 to { i32*, i64, i64 }*
  %t123 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t122, i32 0, i32 0
  store i32* %t112, i32** %t123
  %t124 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t122, i32 0, i32 1
  store i64 3, i64* %t124
  %t125 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t122, i32 0, i32 2
  store i64 3, i64* %t125
  %t126 = getelementptr inbounds %Bag, %Bag* %t107, i32 0, i32 0
  store i8* %t121, i8** %t126
  %t127 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t128 = getelementptr inbounds %Bag, %Bag* %t107, i32 0, i32 1
  store i8* %t127, i8** %t128
  %t129 = load %Bag, %Bag* %t107
  %t130 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 0
  %t131 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 1
  %t132 = load i64, i64* %t131
  %t133 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 2
  %t134 = load i64, i64* %t133
  %t135 = icmp sge i64 %t134, 2
  br i1 %t135, label %ring_push_full_21, label %ring_push_grow_22
ring_push_grow_22:
  %t136 = add i64 %t132, %t134
  %t137 = urem i64 %t136, 2
  %t138 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t130, i32 0, i64 %t137
  store %Bag %t129, %Bag* %t138
  %t139 = add i64 %t134, 1
  store i64 %t139, i64* %t133
  br label %ring_push_done_23
ring_push_full_21:
  %t140 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t130, i32 0, i64 %t132
  %t141 = getelementptr inbounds %Bag, %Bag* %t140, i32 0, i32 0
  %t142 = load i8*, i8** %t141
  call void @star_rc_release(i8* %t142)
  %t143 = getelementptr inbounds %Bag, %Bag* %t140, i32 0, i32 1
  %t144 = load i8*, i8** %t143
  call void @star_rc_release(i8* %t144)
  store %Bag %t129, %Bag* %t140
  %t145 = add i64 %t132, 1
  %t146 = urem i64 %t145, 2
  store i64 %t146, i64* %t131
  br label %ring_push_done_23
ring_push_done_23:
  %t148 = getelementptr i32, i32* null, i32 1
  %t149 = ptrtoint i32* %t148 to i64
  %t150 = mul i64 %t149, 2
  %t151 = call i8* @malloc(i64 %t150)
  %t152 = bitcast i8* %t151 to i32*
  %t153 = getelementptr inbounds i32, i32* %t152, i64 0
  store i32 4, i32* %t153
  %t154 = getelementptr inbounds i32, i32* %t152, i64 1
  store i32 5, i32* %t154
  %t155 = bitcast void (i8*)* @list_release_i32 to i8*
  %t156 = call i8* @star_rc_alloc(i64 24, i8* %t155)
  %t157 = bitcast i8* %t156 to { i32*, i64, i64 }*
  %t158 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t157, i32 0, i32 0
  store i32* %t152, i32** %t158
  %t159 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t157, i32 0, i32 1
  store i64 2, i64* %t159
  %t160 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t157, i32 0, i32 2
  store i64 2, i64* %t160
  %t161 = getelementptr inbounds %Bag, %Bag* %t147, i32 0, i32 0
  store i8* %t156, i8** %t161
  %t162 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t163 = getelementptr inbounds %Bag, %Bag* %t147, i32 0, i32 1
  store i8* %t162, i8** %t163
  %t164 = load %Bag, %Bag* %t147
  %t165 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 0
  %t166 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 1
  %t167 = load i64, i64* %t166
  %t168 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 2
  %t169 = load i64, i64* %t168
  %t170 = icmp sge i64 %t169, 2
  br i1 %t170, label %ring_push_full_24, label %ring_push_grow_25
ring_push_grow_25:
  %t171 = add i64 %t167, %t169
  %t172 = urem i64 %t171, 2
  %t173 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t165, i32 0, i64 %t172
  store %Bag %t164, %Bag* %t173
  %t174 = add i64 %t169, 1
  store i64 %t174, i64* %t168
  br label %ring_push_done_26
ring_push_full_24:
  %t175 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t165, i32 0, i64 %t167
  %t176 = getelementptr inbounds %Bag, %Bag* %t175, i32 0, i32 0
  %t177 = load i8*, i8** %t176
  call void @star_rc_release(i8* %t177)
  %t178 = getelementptr inbounds %Bag, %Bag* %t175, i32 0, i32 1
  %t179 = load i8*, i8** %t178
  call void @star_rc_release(i8* %t179)
  store %Bag %t164, %Bag* %t175
  %t180 = add i64 %t167, 1
  %t181 = urem i64 %t180, 2
  store i64 %t181, i64* %t166
  br label %ring_push_done_26
ring_push_done_26:
  %t183 = getelementptr i32, i32* null, i32 1
  %t184 = ptrtoint i32* %t183 to i64
  %t185 = mul i64 %t184, 1
  %t186 = call i8* @malloc(i64 %t185)
  %t187 = bitcast i8* %t186 to i32*
  %t188 = getelementptr inbounds i32, i32* %t187, i64 0
  store i32 6, i32* %t188
  %t189 = bitcast void (i8*)* @list_release_i32 to i8*
  %t190 = call i8* @star_rc_alloc(i64 24, i8* %t189)
  %t191 = bitcast i8* %t190 to { i32*, i64, i64 }*
  %t192 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t191, i32 0, i32 0
  store i32* %t187, i32** %t192
  %t193 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t191, i32 0, i32 1
  store i64 1, i64* %t193
  %t194 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t191, i32 0, i32 2
  store i64 1, i64* %t194
  %t195 = getelementptr inbounds %Bag, %Bag* %t182, i32 0, i32 0
  store i8* %t190, i8** %t195
  %t196 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t197 = getelementptr inbounds %Bag, %Bag* %t182, i32 0, i32 1
  store i8* %t196, i8** %t197
  %t198 = load %Bag, %Bag* %t182
  %t199 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 0
  %t200 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 1
  %t201 = load i64, i64* %t200
  %t202 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 2
  %t203 = load i64, i64* %t202
  %t204 = icmp sge i64 %t203, 2
  br i1 %t204, label %ring_push_full_27, label %ring_push_grow_28
ring_push_grow_28:
  %t205 = add i64 %t201, %t203
  %t206 = urem i64 %t205, 2
  %t207 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t199, i32 0, i64 %t206
  store %Bag %t198, %Bag* %t207
  %t208 = add i64 %t203, 1
  store i64 %t208, i64* %t202
  br label %ring_push_done_29
ring_push_full_27:
  %t209 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t199, i32 0, i64 %t201
  %t210 = getelementptr inbounds %Bag, %Bag* %t209, i32 0, i32 0
  %t211 = load i8*, i8** %t210
  call void @star_rc_release(i8* %t211)
  %t212 = getelementptr inbounds %Bag, %Bag* %t209, i32 0, i32 1
  %t213 = load i8*, i8** %t212
  call void @star_rc_release(i8* %t213)
  store %Bag %t198, %Bag* %t209
  %t214 = add i64 %t201, 1
  %t215 = urem i64 %t214, 2
  store i64 %t215, i64* %t200
  br label %ring_push_done_29
ring_push_done_29:
  %t216 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 0
  %t217 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 1
  %t218 = load i64, i64* %t217
  %t219 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 2
  %t220 = load i64, i64* %t219
  %t221 = sext i32 0 to i64
  %t222 = load i64, i64* %t217
  %t223 = load i64, i64* %t219
  %t224 = icmp ult i64 %t221, %t223
  br i1 %t224, label %ring_rplace_ok_30, label %ring_rplace_oob_31
ring_rplace_ok_30:
  %t225 = add i64 %t222, %t221
  %t226 = urem i64 %t225, 2
  %t227 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t216, i32 0, i64 %t226
  br label %ring_rplace_end_32
ring_rplace_oob_31:
  store %Bag zeroinitializer, %Bag* %t228
  br label %ring_rplace_end_32
ring_rplace_end_32:
  %t229 = phi %Bag* [ %t227, %ring_rplace_ok_30 ], [ %t228, %ring_rplace_oob_31 ]
  %t230 = getelementptr inbounds %Bag, %Bag* %t229, i32 0, i32 1
  %t231 = load i8*, i8** %t230
  %t232 = load i8*, i8** %t230
  call void @star_rc_retain(i8* %t232)
  call void @star_rc_release(i8* %t231)
  %t233 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 0
  %t234 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 1
  %t235 = load i64, i64* %t234
  %t236 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 2
  %t237 = load i64, i64* %t236
  %t238 = sext i32 0 to i64
  %t239 = load i64, i64* %t234
  %t240 = load i64, i64* %t236
  %t241 = icmp ult i64 %t238, %t240
  br i1 %t241, label %ring_rplace_ok_33, label %ring_rplace_oob_34
ring_rplace_ok_33:
  %t242 = add i64 %t239, %t238
  %t243 = urem i64 %t242, 2
  %t244 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t233, i32 0, i64 %t243
  br label %ring_rplace_end_35
ring_rplace_oob_34:
  store %Bag zeroinitializer, %Bag* %t245
  br label %ring_rplace_end_35
ring_rplace_end_35:
  %t246 = phi %Bag* [ %t244, %ring_rplace_ok_33 ], [ %t245, %ring_rplace_oob_34 ]
  %t247 = getelementptr inbounds %Bag, %Bag* %t246, i32 0, i32 0
  %t248 = load i8*, i8** %t247
  %t249 = icmp eq i8* %t248, null
  br i1 %t249, label %list_read_null_36, label %list_read_real_37
list_read_null_36:
  br label %list_read_end_38
list_read_real_37:
  %t250 = bitcast i8* %t248 to { i32*, i64, i64 }*
  %t251 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t250, i32 0, i32 0
  %t252 = load i32*, i32** %t251
  %t253 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t250, i32 0, i32 1
  %t254 = load i64, i64* %t253
  br label %list_read_end_38
list_read_end_38:
  %t255 = phi i32* [ null, %list_read_null_36 ], [ %t252, %list_read_real_37 ]
  %t256 = phi i64 [ 0, %list_read_null_36 ], [ %t254, %list_read_real_37 ]
  %t257 = trunc i64 %t256 to i32
  %t258 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t258, i8* %t231, i32 %t257)
  %t259 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 0
  %t260 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 1
  %t261 = load i64, i64* %t260
  %t262 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 2
  %t263 = load i64, i64* %t262
  %t264 = sext i32 1 to i64
  %t265 = load i64, i64* %t260
  %t266 = load i64, i64* %t262
  %t267 = icmp ult i64 %t264, %t266
  br i1 %t267, label %ring_rplace_ok_39, label %ring_rplace_oob_40
ring_rplace_ok_39:
  %t268 = add i64 %t265, %t264
  %t269 = urem i64 %t268, 2
  %t270 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t259, i32 0, i64 %t269
  br label %ring_rplace_end_41
ring_rplace_oob_40:
  store %Bag zeroinitializer, %Bag* %t271
  br label %ring_rplace_end_41
ring_rplace_end_41:
  %t272 = phi %Bag* [ %t270, %ring_rplace_ok_39 ], [ %t271, %ring_rplace_oob_40 ]
  %t273 = getelementptr inbounds %Bag, %Bag* %t272, i32 0, i32 1
  %t274 = load i8*, i8** %t273
  %t275 = load i8*, i8** %t273
  call void @star_rc_retain(i8* %t275)
  call void @star_rc_release(i8* %t274)
  %t276 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 0
  %t277 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 1
  %t278 = load i64, i64* %t277
  %t279 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 2
  %t280 = load i64, i64* %t279
  %t281 = sext i32 1 to i64
  %t282 = load i64, i64* %t277
  %t283 = load i64, i64* %t279
  %t284 = icmp ult i64 %t281, %t283
  br i1 %t284, label %ring_rplace_ok_42, label %ring_rplace_oob_43
ring_rplace_ok_42:
  %t285 = add i64 %t282, %t281
  %t286 = urem i64 %t285, 2
  %t287 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t276, i32 0, i64 %t286
  br label %ring_rplace_end_44
ring_rplace_oob_43:
  store %Bag zeroinitializer, %Bag* %t288
  br label %ring_rplace_end_44
ring_rplace_end_44:
  %t289 = phi %Bag* [ %t287, %ring_rplace_ok_42 ], [ %t288, %ring_rplace_oob_43 ]
  %t290 = getelementptr inbounds %Bag, %Bag* %t289, i32 0, i32 0
  %t291 = load i8*, i8** %t290
  %t292 = icmp eq i8* %t291, null
  br i1 %t292, label %list_read_null_45, label %list_read_real_46
list_read_null_45:
  br label %list_read_end_47
list_read_real_46:
  %t293 = bitcast i8* %t291 to { i32*, i64, i64 }*
  %t294 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t293, i32 0, i32 0
  %t295 = load i32*, i32** %t294
  %t296 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t293, i32 0, i32 1
  %t297 = load i64, i64* %t296
  br label %list_read_end_47
list_read_end_47:
  %t298 = phi i32* [ null, %list_read_null_45 ], [ %t295, %list_read_real_46 ]
  %t299 = phi i64 [ 0, %list_read_null_45 ], [ %t297, %list_read_real_46 ]
  %t300 = trunc i64 %t299 to i32
  %t301 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t301, i8* %t274, i32 %t300)
  store i8* null, i8** %t302
  %t303 = load i8*, i8** %t302
  %t304 = icmp eq i8* %t303, null
  br i1 %t304, label %table_cow_alloc_48, label %table_cow_check_49
table_cow_alloc_48:
  %t314 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t315 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t316 = ptrtoint { i64, i64, i32*, i32* }* %t315 to i64
  %t317 = call i8* @star_rc_alloc(i64 %t316, i8* %t314)
  %t318 = bitcast i8* %t317 to { i64, i64, i32*, i32* }*
  %t319 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t318, i32 0, i32 0
  store i64 0, i64* %t319
  %t320 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t318, i32 0, i32 1
  store i64 0, i64* %t320
  %t321 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t318, i32 0, i32 2
  store i32* null, i32** %t321
  %t322 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t318, i32 0, i32 3
  store i32* null, i32** %t322
  store i8* %t317, i8** %t302
  br label %table_cow_done_50
table_cow_check_49:
  %t323 = getelementptr inbounds i8, i8* %t303, i64 -16
  %t324 = bitcast i8* %t323 to i64*
  %t325 = load atomic i64, i64* %t324 seq_cst, align 8
  %t326 = icmp eq i64 %t325, 1
  br i1 %t326, label %table_cow_done_50, label %table_cow_clone_51
table_cow_clone_51:
  %t327 = bitcast i8* %t303 to { i64, i64, i32*, i32* }*
  %t328 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t327, i32 0, i32 0
  %t329 = load i64, i64* %t328
  %t330 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t327, i32 0, i32 1
  %t331 = load i64, i64* %t330
  %t332 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t333 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t334 = ptrtoint { i64, i64, i32*, i32* }* %t333 to i64
  %t335 = call i8* @star_rc_alloc(i64 %t334, i8* %t332)
  %t336 = bitcast i8* %t335 to { i64, i64, i32*, i32* }*
  %t337 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t336, i32 0, i32 0
  store i64 %t329, i64* %t337
  %t338 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t336, i32 0, i32 1
  store i64 %t331, i64* %t338
  %t339 = getelementptr i32, i32* null, i32 1
  %t340 = ptrtoint i32* %t339 to i64
  %t341 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t327, i32 0, i32 2
  %t342 = load i32*, i32** %t341
  %t343 = mul i64 %t331, %t340
  %t344 = call i8* @malloc(i64 %t343)
  %t345 = bitcast i8* %t344 to i32*
  %t346 = icmp sgt i64 %t329, 0
  br i1 %t346, label %table_cow_copy_52, label %table_cow_after_copy_53
table_cow_copy_52:
  %t347 = mul i64 %t329, %t340
  %t348 = bitcast i32* %t342 to i8*
  call i8* @memcpy(i8* %t344, i8* %t348, i64 %t347)
  br label %table_cow_after_copy_53
table_cow_after_copy_53:
  %t349 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t336, i32 0, i32 2
  store i32* %t345, i32** %t349
  %t350 = getelementptr i32, i32* null, i32 1
  %t351 = ptrtoint i32* %t350 to i64
  %t352 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t327, i32 0, i32 3
  %t353 = load i32*, i32** %t352
  %t354 = mul i64 %t331, %t351
  %t355 = call i8* @malloc(i64 %t354)
  %t356 = bitcast i8* %t355 to i32*
  %t357 = icmp sgt i64 %t329, 0
  br i1 %t357, label %table_cow_copy_54, label %table_cow_after_copy_55
table_cow_copy_54:
  %t358 = mul i64 %t329, %t351
  %t359 = bitcast i32* %t353 to i8*
  call i8* @memcpy(i8* %t355, i8* %t359, i64 %t358)
  br label %table_cow_after_copy_55
table_cow_after_copy_55:
  %t360 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t336, i32 0, i32 3
  store i32* %t356, i32** %t360
  call void @star_rc_release(i8* %t303)
  store i8* %t335, i8** %t302
  br label %table_cow_done_50
table_cow_done_50:
  %t361 = load i8*, i8** %t302
  %t362 = bitcast i8* %t361 to { i64, i64, i32*, i32* }*
  %t363 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t362, i32 0, i32 0
  %t364 = load i64, i64* %t363
  %t365 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t362, i32 0, i32 1
  %t366 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t362, i32 0, i32 2
  %t367 = load i32*, i32** %t366
  %t368 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t362, i32 0, i32 3
  %t369 = load i32*, i32** %t368
  %t371 = getelementptr inbounds %Point, %Point* %t370, i32 0, i32 0
  store i32 1, i32* %t371
  %t372 = getelementptr inbounds %Point, %Point* %t370, i32 0, i32 1
  store i32 2, i32* %t372
  %t373 = load %Point, %Point* %t370
  %t374 = load i64, i64* %t365
  %t375 = load i64, i64* %t363
  %t376 = load i32*, i32** %t366
  %t377 = load i32*, i32** %t368
  %t378 = icmp sge i64 %t375, %t374
  br i1 %t378, label %table_push_grow_56, label %table_push_store_57
table_push_grow_56:
  %t379 = mul i64 %t374, 2
  %t380 = icmp sgt i64 %t379, 0
  %t381 = select i1 %t380, i64 %t379, i64 1
  %t382 = getelementptr i32, i32* null, i32 1
  %t383 = ptrtoint i32* %t382 to i64
  %t384 = mul i64 %t381, %t383
  %t385 = call i8* @malloc(i64 %t384)
  %t386 = bitcast i8* %t385 to i32*
  %t387 = icmp sgt i64 %t374, 0
  br i1 %t387, label %table_push_copy_58, label %table_push_after_copy_59
table_push_copy_58:
  %t388 = mul i64 %t375, %t383
  %t389 = bitcast i32* %t376 to i8*
  call i8* @memcpy(i8* %t385, i8* %t389, i64 %t388)
  call void @free(i8* %t389)
  br label %table_push_after_copy_59
table_push_after_copy_59:
  store i32* %t386, i32** %t366
  %t390 = getelementptr i32, i32* null, i32 1
  %t391 = ptrtoint i32* %t390 to i64
  %t392 = mul i64 %t381, %t391
  %t393 = call i8* @malloc(i64 %t392)
  %t394 = bitcast i8* %t393 to i32*
  %t395 = icmp sgt i64 %t374, 0
  br i1 %t395, label %table_push_copy_60, label %table_push_after_copy_61
table_push_copy_60:
  %t396 = mul i64 %t375, %t391
  %t397 = bitcast i32* %t377 to i8*
  call i8* @memcpy(i8* %t393, i8* %t397, i64 %t396)
  call void @free(i8* %t397)
  br label %table_push_after_copy_61
table_push_after_copy_61:
  store i32* %t394, i32** %t368
  store i64 %t381, i64* %t365
  br label %table_push_store_57
table_push_store_57:
  %t398 = load i32*, i32** %t366
  %t399 = extractvalue %Point %t373, 0
  %t400 = getelementptr inbounds i32, i32* %t398, i64 %t375
  store i32 %t399, i32* %t400
  %t401 = load i32*, i32** %t368
  %t402 = extractvalue %Point %t373, 1
  %t403 = getelementptr inbounds i32, i32* %t401, i64 %t375
  store i32 %t402, i32* %t403
  %t404 = add i64 %t375, 1
  store i64 %t404, i64* %t363
  %t405 = load i8*, i8** %t302
  %t406 = icmp eq i8* %t405, null
  br i1 %t406, label %table_cow_alloc_62, label %table_cow_check_63
table_cow_alloc_62:
  %t407 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t408 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t409 = ptrtoint { i64, i64, i32*, i32* }* %t408 to i64
  %t410 = call i8* @star_rc_alloc(i64 %t409, i8* %t407)
  %t411 = bitcast i8* %t410 to { i64, i64, i32*, i32* }*
  %t412 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t411, i32 0, i32 0
  store i64 0, i64* %t412
  %t413 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t411, i32 0, i32 1
  store i64 0, i64* %t413
  %t414 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t411, i32 0, i32 2
  store i32* null, i32** %t414
  %t415 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t411, i32 0, i32 3
  store i32* null, i32** %t415
  store i8* %t410, i8** %t302
  br label %table_cow_done_64
table_cow_check_63:
  %t416 = getelementptr inbounds i8, i8* %t405, i64 -16
  %t417 = bitcast i8* %t416 to i64*
  %t418 = load atomic i64, i64* %t417 seq_cst, align 8
  %t419 = icmp eq i64 %t418, 1
  br i1 %t419, label %table_cow_done_64, label %table_cow_clone_65
table_cow_clone_65:
  %t420 = bitcast i8* %t405 to { i64, i64, i32*, i32* }*
  %t421 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t420, i32 0, i32 0
  %t422 = load i64, i64* %t421
  %t423 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t420, i32 0, i32 1
  %t424 = load i64, i64* %t423
  %t425 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t426 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t427 = ptrtoint { i64, i64, i32*, i32* }* %t426 to i64
  %t428 = call i8* @star_rc_alloc(i64 %t427, i8* %t425)
  %t429 = bitcast i8* %t428 to { i64, i64, i32*, i32* }*
  %t430 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t429, i32 0, i32 0
  store i64 %t422, i64* %t430
  %t431 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t429, i32 0, i32 1
  store i64 %t424, i64* %t431
  %t432 = getelementptr i32, i32* null, i32 1
  %t433 = ptrtoint i32* %t432 to i64
  %t434 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t420, i32 0, i32 2
  %t435 = load i32*, i32** %t434
  %t436 = mul i64 %t424, %t433
  %t437 = call i8* @malloc(i64 %t436)
  %t438 = bitcast i8* %t437 to i32*
  %t439 = icmp sgt i64 %t422, 0
  br i1 %t439, label %table_cow_copy_66, label %table_cow_after_copy_67
table_cow_copy_66:
  %t440 = mul i64 %t422, %t433
  %t441 = bitcast i32* %t435 to i8*
  call i8* @memcpy(i8* %t437, i8* %t441, i64 %t440)
  br label %table_cow_after_copy_67
table_cow_after_copy_67:
  %t442 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t429, i32 0, i32 2
  store i32* %t438, i32** %t442
  %t443 = getelementptr i32, i32* null, i32 1
  %t444 = ptrtoint i32* %t443 to i64
  %t445 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t420, i32 0, i32 3
  %t446 = load i32*, i32** %t445
  %t447 = mul i64 %t424, %t444
  %t448 = call i8* @malloc(i64 %t447)
  %t449 = bitcast i8* %t448 to i32*
  %t450 = icmp sgt i64 %t422, 0
  br i1 %t450, label %table_cow_copy_68, label %table_cow_after_copy_69
table_cow_copy_68:
  %t451 = mul i64 %t422, %t444
  %t452 = bitcast i32* %t446 to i8*
  call i8* @memcpy(i8* %t448, i8* %t452, i64 %t451)
  br label %table_cow_after_copy_69
table_cow_after_copy_69:
  %t453 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t429, i32 0, i32 3
  store i32* %t449, i32** %t453
  call void @star_rc_release(i8* %t405)
  store i8* %t428, i8** %t302
  br label %table_cow_done_64
table_cow_done_64:
  %t454 = load i8*, i8** %t302
  %t455 = bitcast i8* %t454 to { i64, i64, i32*, i32* }*
  %t456 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t455, i32 0, i32 0
  %t457 = load i64, i64* %t456
  %t458 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t455, i32 0, i32 1
  %t459 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t455, i32 0, i32 2
  %t460 = load i32*, i32** %t459
  %t461 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t455, i32 0, i32 3
  %t462 = load i32*, i32** %t461
  %t464 = getelementptr inbounds %Point, %Point* %t463, i32 0, i32 0
  store i32 3, i32* %t464
  %t465 = getelementptr inbounds %Point, %Point* %t463, i32 0, i32 1
  store i32 4, i32* %t465
  %t466 = load %Point, %Point* %t463
  %t467 = load i64, i64* %t458
  %t468 = load i64, i64* %t456
  %t469 = load i32*, i32** %t459
  %t470 = load i32*, i32** %t461
  %t471 = icmp sge i64 %t468, %t467
  br i1 %t471, label %table_push_grow_70, label %table_push_store_71
table_push_grow_70:
  %t472 = mul i64 %t467, 2
  %t473 = icmp sgt i64 %t472, 0
  %t474 = select i1 %t473, i64 %t472, i64 1
  %t475 = getelementptr i32, i32* null, i32 1
  %t476 = ptrtoint i32* %t475 to i64
  %t477 = mul i64 %t474, %t476
  %t478 = call i8* @malloc(i64 %t477)
  %t479 = bitcast i8* %t478 to i32*
  %t480 = icmp sgt i64 %t467, 0
  br i1 %t480, label %table_push_copy_72, label %table_push_after_copy_73
table_push_copy_72:
  %t481 = mul i64 %t468, %t476
  %t482 = bitcast i32* %t469 to i8*
  call i8* @memcpy(i8* %t478, i8* %t482, i64 %t481)
  call void @free(i8* %t482)
  br label %table_push_after_copy_73
table_push_after_copy_73:
  store i32* %t479, i32** %t459
  %t483 = getelementptr i32, i32* null, i32 1
  %t484 = ptrtoint i32* %t483 to i64
  %t485 = mul i64 %t474, %t484
  %t486 = call i8* @malloc(i64 %t485)
  %t487 = bitcast i8* %t486 to i32*
  %t488 = icmp sgt i64 %t467, 0
  br i1 %t488, label %table_push_copy_74, label %table_push_after_copy_75
table_push_copy_74:
  %t489 = mul i64 %t468, %t484
  %t490 = bitcast i32* %t470 to i8*
  call i8* @memcpy(i8* %t486, i8* %t490, i64 %t489)
  call void @free(i8* %t490)
  br label %table_push_after_copy_75
table_push_after_copy_75:
  store i32* %t487, i32** %t461
  store i64 %t474, i64* %t458
  br label %table_push_store_71
table_push_store_71:
  %t491 = load i32*, i32** %t459
  %t492 = extractvalue %Point %t466, 0
  %t493 = getelementptr inbounds i32, i32* %t491, i64 %t468
  store i32 %t492, i32* %t493
  %t494 = load i32*, i32** %t461
  %t495 = extractvalue %Point %t466, 1
  %t496 = getelementptr inbounds i32, i32* %t494, i64 %t468
  store i32 %t495, i32* %t496
  %t497 = add i64 %t468, 1
  store i64 %t497, i64* %t456
  %t499 = load i8*, i8** %t302
  %t500 = load i8*, i8** %t302
  call void @star_rc_retain(i8* %t500)
  store i8* %t499, i8** %t498
  %t501 = load i8*, i8** %t498
  %t502 = icmp eq i8* %t501, null
  br i1 %t502, label %table_cow_alloc_76, label %table_cow_check_77
table_cow_alloc_76:
  %t503 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t504 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t505 = ptrtoint { i64, i64, i32*, i32* }* %t504 to i64
  %t506 = call i8* @star_rc_alloc(i64 %t505, i8* %t503)
  %t507 = bitcast i8* %t506 to { i64, i64, i32*, i32* }*
  %t508 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t507, i32 0, i32 0
  store i64 0, i64* %t508
  %t509 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t507, i32 0, i32 1
  store i64 0, i64* %t509
  %t510 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t507, i32 0, i32 2
  store i32* null, i32** %t510
  %t511 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t507, i32 0, i32 3
  store i32* null, i32** %t511
  store i8* %t506, i8** %t498
  br label %table_cow_done_78
table_cow_check_77:
  %t512 = getelementptr inbounds i8, i8* %t501, i64 -16
  %t513 = bitcast i8* %t512 to i64*
  %t514 = load atomic i64, i64* %t513 seq_cst, align 8
  %t515 = icmp eq i64 %t514, 1
  br i1 %t515, label %table_cow_done_78, label %table_cow_clone_79
table_cow_clone_79:
  %t516 = bitcast i8* %t501 to { i64, i64, i32*, i32* }*
  %t517 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t516, i32 0, i32 0
  %t518 = load i64, i64* %t517
  %t519 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t516, i32 0, i32 1
  %t520 = load i64, i64* %t519
  %t521 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t522 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t523 = ptrtoint { i64, i64, i32*, i32* }* %t522 to i64
  %t524 = call i8* @star_rc_alloc(i64 %t523, i8* %t521)
  %t525 = bitcast i8* %t524 to { i64, i64, i32*, i32* }*
  %t526 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t525, i32 0, i32 0
  store i64 %t518, i64* %t526
  %t527 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t525, i32 0, i32 1
  store i64 %t520, i64* %t527
  %t528 = getelementptr i32, i32* null, i32 1
  %t529 = ptrtoint i32* %t528 to i64
  %t530 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t516, i32 0, i32 2
  %t531 = load i32*, i32** %t530
  %t532 = mul i64 %t520, %t529
  %t533 = call i8* @malloc(i64 %t532)
  %t534 = bitcast i8* %t533 to i32*
  %t535 = icmp sgt i64 %t518, 0
  br i1 %t535, label %table_cow_copy_80, label %table_cow_after_copy_81
table_cow_copy_80:
  %t536 = mul i64 %t518, %t529
  %t537 = bitcast i32* %t531 to i8*
  call i8* @memcpy(i8* %t533, i8* %t537, i64 %t536)
  br label %table_cow_after_copy_81
table_cow_after_copy_81:
  %t538 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t525, i32 0, i32 2
  store i32* %t534, i32** %t538
  %t539 = getelementptr i32, i32* null, i32 1
  %t540 = ptrtoint i32* %t539 to i64
  %t541 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t516, i32 0, i32 3
  %t542 = load i32*, i32** %t541
  %t543 = mul i64 %t520, %t540
  %t544 = call i8* @malloc(i64 %t543)
  %t545 = bitcast i8* %t544 to i32*
  %t546 = icmp sgt i64 %t518, 0
  br i1 %t546, label %table_cow_copy_82, label %table_cow_after_copy_83
table_cow_copy_82:
  %t547 = mul i64 %t518, %t540
  %t548 = bitcast i32* %t542 to i8*
  call i8* @memcpy(i8* %t544, i8* %t548, i64 %t547)
  br label %table_cow_after_copy_83
table_cow_after_copy_83:
  %t549 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t525, i32 0, i32 3
  store i32* %t545, i32** %t549
  call void @star_rc_release(i8* %t501)
  store i8* %t524, i8** %t498
  br label %table_cow_done_78
table_cow_done_78:
  %t550 = load i8*, i8** %t498
  %t551 = bitcast i8* %t550 to { i64, i64, i32*, i32* }*
  %t552 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t551, i32 0, i32 0
  %t553 = load i64, i64* %t552
  %t554 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t551, i32 0, i32 1
  %t555 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t551, i32 0, i32 2
  %t556 = load i32*, i32** %t555
  %t557 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t551, i32 0, i32 3
  %t558 = load i32*, i32** %t557
  %t560 = getelementptr inbounds %Point, %Point* %t559, i32 0, i32 0
  store i32 5, i32* %t560
  %t561 = getelementptr inbounds %Point, %Point* %t559, i32 0, i32 1
  store i32 6, i32* %t561
  %t562 = load %Point, %Point* %t559
  %t563 = load i64, i64* %t554
  %t564 = load i64, i64* %t552
  %t565 = load i32*, i32** %t555
  %t566 = load i32*, i32** %t557
  %t567 = icmp sge i64 %t564, %t563
  br i1 %t567, label %table_push_grow_84, label %table_push_store_85
table_push_grow_84:
  %t568 = mul i64 %t563, 2
  %t569 = icmp sgt i64 %t568, 0
  %t570 = select i1 %t569, i64 %t568, i64 1
  %t571 = getelementptr i32, i32* null, i32 1
  %t572 = ptrtoint i32* %t571 to i64
  %t573 = mul i64 %t570, %t572
  %t574 = call i8* @malloc(i64 %t573)
  %t575 = bitcast i8* %t574 to i32*
  %t576 = icmp sgt i64 %t563, 0
  br i1 %t576, label %table_push_copy_86, label %table_push_after_copy_87
table_push_copy_86:
  %t577 = mul i64 %t564, %t572
  %t578 = bitcast i32* %t565 to i8*
  call i8* @memcpy(i8* %t574, i8* %t578, i64 %t577)
  call void @free(i8* %t578)
  br label %table_push_after_copy_87
table_push_after_copy_87:
  store i32* %t575, i32** %t555
  %t579 = getelementptr i32, i32* null, i32 1
  %t580 = ptrtoint i32* %t579 to i64
  %t581 = mul i64 %t570, %t580
  %t582 = call i8* @malloc(i64 %t581)
  %t583 = bitcast i8* %t582 to i32*
  %t584 = icmp sgt i64 %t563, 0
  br i1 %t584, label %table_push_copy_88, label %table_push_after_copy_89
table_push_copy_88:
  %t585 = mul i64 %t564, %t580
  %t586 = bitcast i32* %t566 to i8*
  call i8* @memcpy(i8* %t582, i8* %t586, i64 %t585)
  call void @free(i8* %t586)
  br label %table_push_after_copy_89
table_push_after_copy_89:
  store i32* %t583, i32** %t557
  store i64 %t570, i64* %t554
  br label %table_push_store_85
table_push_store_85:
  %t587 = load i32*, i32** %t555
  %t588 = extractvalue %Point %t562, 0
  %t589 = getelementptr inbounds i32, i32* %t587, i64 %t564
  store i32 %t588, i32* %t589
  %t590 = load i32*, i32** %t557
  %t591 = extractvalue %Point %t562, 1
  %t592 = getelementptr inbounds i32, i32* %t590, i64 %t564
  store i32 %t591, i32* %t592
  %t593 = add i64 %t564, 1
  store i64 %t593, i64* %t552
  %t594 = load i8*, i8** %t302
  %t595 = icmp eq i8* %t594, null
  br i1 %t595, label %table_read_null_90, label %table_read_real_91
table_read_null_90:
  br label %table_read_end_92
table_read_real_91:
  %t596 = bitcast i8* %t594 to { i64, i64, i32*, i32* }*
  %t597 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t596, i32 0, i32 0
  %t598 = load i64, i64* %t597
  %t599 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t596, i32 0, i32 2
  %t600 = load i32*, i32** %t599
  %t601 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t596, i32 0, i32 3
  %t602 = load i32*, i32** %t601
  br label %table_read_end_92
table_read_end_92:
  %t603 = phi i64 [ 0, %table_read_null_90 ], [ %t598, %table_read_real_91 ]
  %t604 = phi i32* [ null, %table_read_null_90 ], [ %t600, %table_read_real_91 ]
  %t605 = phi i32* [ null, %table_read_null_90 ], [ %t602, %table_read_real_91 ]
  %t606 = trunc i64 %t603 to i32
  %t607 = load i8*, i8** %t498
  %t608 = icmp eq i8* %t607, null
  br i1 %t608, label %table_read_null_93, label %table_read_real_94
table_read_null_93:
  br label %table_read_end_95
table_read_real_94:
  %t609 = bitcast i8* %t607 to { i64, i64, i32*, i32* }*
  %t610 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t609, i32 0, i32 0
  %t611 = load i64, i64* %t610
  %t612 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t609, i32 0, i32 2
  %t613 = load i32*, i32** %t612
  %t614 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t609, i32 0, i32 3
  %t615 = load i32*, i32** %t614
  br label %table_read_end_95
table_read_end_95:
  %t616 = phi i64 [ 0, %table_read_null_93 ], [ %t611, %table_read_real_94 ]
  %t617 = phi i32* [ null, %table_read_null_93 ], [ %t613, %table_read_real_94 ]
  %t618 = phi i32* [ null, %table_read_null_93 ], [ %t615, %table_read_real_94 ]
  %t619 = trunc i64 %t616 to i32
  %t620 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t620, i32 %t606, i32 %t619)
  %t621 = sext i32 1 to i64
  %t622 = load i8*, i8** %t302
  %t623 = icmp eq i8* %t622, null
  br i1 %t623, label %table_read_null_96, label %table_read_real_97
table_read_null_96:
  br label %table_read_end_98
table_read_real_97:
  %t624 = bitcast i8* %t622 to { i64, i64, i32*, i32* }*
  %t625 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t624, i32 0, i32 0
  %t626 = load i64, i64* %t625
  %t627 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t624, i32 0, i32 2
  %t628 = load i32*, i32** %t627
  %t629 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t624, i32 0, i32 3
  %t630 = load i32*, i32** %t629
  br label %table_read_end_98
table_read_end_98:
  %t631 = phi i64 [ 0, %table_read_null_96 ], [ %t626, %table_read_real_97 ]
  %t632 = phi i32* [ null, %table_read_null_96 ], [ %t628, %table_read_real_97 ]
  %t633 = phi i32* [ null, %table_read_null_96 ], [ %t630, %table_read_real_97 ]
  %t635 = icmp ult i64 %t621, %t631
  br i1 %t635, label %table_idx_ok_99, label %table_idx_oob_100
table_idx_ok_99:
  %t636 = getelementptr inbounds i32, i32* %t632, i64 %t621
  %t637 = load i32, i32* %t636
  %t638 = getelementptr inbounds %Point, %Point* %t634, i32 0, i32 0
  store i32 %t637, i32* %t638
  %t639 = getelementptr inbounds i32, i32* %t633, i64 %t621
  %t640 = load i32, i32* %t639
  %t641 = getelementptr inbounds %Point, %Point* %t634, i32 0, i32 1
  store i32 %t640, i32* %t641
  br label %table_idx_end_101
table_idx_oob_100:
  store %Point zeroinitializer, %Point* %t634
  br label %table_idx_end_101
table_idx_end_101:
  %t642 = load %Point, %Point* %t634
  store %Point %t642, %Point* %t643
  %t644 = getelementptr inbounds %Point, %Point* %t643, i32 0, i32 0
  %t645 = load i32, i32* %t644
  %t646 = sext i32 1 to i64
  %t647 = load i8*, i8** %t302
  %t648 = icmp eq i8* %t647, null
  br i1 %t648, label %table_read_null_102, label %table_read_real_103
table_read_null_102:
  br label %table_read_end_104
table_read_real_103:
  %t649 = bitcast i8* %t647 to { i64, i64, i32*, i32* }*
  %t650 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t649, i32 0, i32 0
  %t651 = load i64, i64* %t650
  %t652 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t649, i32 0, i32 2
  %t653 = load i32*, i32** %t652
  %t654 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t649, i32 0, i32 3
  %t655 = load i32*, i32** %t654
  br label %table_read_end_104
table_read_end_104:
  %t656 = phi i64 [ 0, %table_read_null_102 ], [ %t651, %table_read_real_103 ]
  %t657 = phi i32* [ null, %table_read_null_102 ], [ %t653, %table_read_real_103 ]
  %t658 = phi i32* [ null, %table_read_null_102 ], [ %t655, %table_read_real_103 ]
  %t660 = icmp ult i64 %t646, %t656
  br i1 %t660, label %table_idx_ok_105, label %table_idx_oob_106
table_idx_ok_105:
  %t661 = getelementptr inbounds i32, i32* %t657, i64 %t646
  %t662 = load i32, i32* %t661
  %t663 = getelementptr inbounds %Point, %Point* %t659, i32 0, i32 0
  store i32 %t662, i32* %t663
  %t664 = getelementptr inbounds i32, i32* %t658, i64 %t646
  %t665 = load i32, i32* %t664
  %t666 = getelementptr inbounds %Point, %Point* %t659, i32 0, i32 1
  store i32 %t665, i32* %t666
  br label %table_idx_end_107
table_idx_oob_106:
  store %Point zeroinitializer, %Point* %t659
  br label %table_idx_end_107
table_idx_end_107:
  %t667 = load %Point, %Point* %t659
  store %Point %t667, %Point* %t668
  %t669 = getelementptr inbounds %Point, %Point* %t668, i32 0, i32 1
  %t670 = load i32, i32* %t669
  %t671 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t671, i32 %t645, i32 %t670)
  %t672 = sub i32 0, 1
  %t673 = sext i32 %t672 to i64
  %t674 = load i8*, i8** %t302
  %t675 = icmp eq i8* %t674, null
  br i1 %t675, label %table_read_null_108, label %table_read_real_109
table_read_null_108:
  br label %table_read_end_110
table_read_real_109:
  %t676 = bitcast i8* %t674 to { i64, i64, i32*, i32* }*
  %t677 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t676, i32 0, i32 0
  %t678 = load i64, i64* %t677
  %t679 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t676, i32 0, i32 2
  %t680 = load i32*, i32** %t679
  %t681 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t676, i32 0, i32 3
  %t682 = load i32*, i32** %t681
  br label %table_read_end_110
table_read_end_110:
  %t683 = phi i64 [ 0, %table_read_null_108 ], [ %t678, %table_read_real_109 ]
  %t684 = phi i32* [ null, %table_read_null_108 ], [ %t680, %table_read_real_109 ]
  %t685 = phi i32* [ null, %table_read_null_108 ], [ %t682, %table_read_real_109 ]
  %t687 = icmp ult i64 %t673, %t683
  br i1 %t687, label %table_idx_ok_111, label %table_idx_oob_112
table_idx_ok_111:
  %t688 = getelementptr inbounds i32, i32* %t684, i64 %t673
  %t689 = load i32, i32* %t688
  %t690 = getelementptr inbounds %Point, %Point* %t686, i32 0, i32 0
  store i32 %t689, i32* %t690
  %t691 = getelementptr inbounds i32, i32* %t685, i64 %t673
  %t692 = load i32, i32* %t691
  %t693 = getelementptr inbounds %Point, %Point* %t686, i32 0, i32 1
  store i32 %t692, i32* %t693
  br label %table_idx_end_113
table_idx_oob_112:
  store %Point zeroinitializer, %Point* %t686
  br label %table_idx_end_113
table_idx_end_113:
  %t694 = load %Point, %Point* %t686
  store %Point %t694, %Point* %t695
  %t696 = getelementptr inbounds %Point, %Point* %t695, i32 0, i32 0
  %t697 = load i32, i32* %t696
  %t698 = sub i32 0, 1
  %t699 = sext i32 %t698 to i64
  %t700 = load i8*, i8** %t302
  %t701 = icmp eq i8* %t700, null
  br i1 %t701, label %table_read_null_114, label %table_read_real_115
table_read_null_114:
  br label %table_read_end_116
table_read_real_115:
  %t702 = bitcast i8* %t700 to { i64, i64, i32*, i32* }*
  %t703 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t702, i32 0, i32 0
  %t704 = load i64, i64* %t703
  %t705 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t702, i32 0, i32 2
  %t706 = load i32*, i32** %t705
  %t707 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t702, i32 0, i32 3
  %t708 = load i32*, i32** %t707
  br label %table_read_end_116
table_read_end_116:
  %t709 = phi i64 [ 0, %table_read_null_114 ], [ %t704, %table_read_real_115 ]
  %t710 = phi i32* [ null, %table_read_null_114 ], [ %t706, %table_read_real_115 ]
  %t711 = phi i32* [ null, %table_read_null_114 ], [ %t708, %table_read_real_115 ]
  %t713 = icmp ult i64 %t699, %t709
  br i1 %t713, label %table_idx_ok_117, label %table_idx_oob_118
table_idx_ok_117:
  %t714 = getelementptr inbounds i32, i32* %t710, i64 %t699
  %t715 = load i32, i32* %t714
  %t716 = getelementptr inbounds %Point, %Point* %t712, i32 0, i32 0
  store i32 %t715, i32* %t716
  %t717 = getelementptr inbounds i32, i32* %t711, i64 %t699
  %t718 = load i32, i32* %t717
  %t719 = getelementptr inbounds %Point, %Point* %t712, i32 0, i32 1
  store i32 %t718, i32* %t719
  br label %table_idx_end_119
table_idx_oob_118:
  store %Point zeroinitializer, %Point* %t712
  br label %table_idx_end_119
table_idx_end_119:
  %t720 = load %Point, %Point* %t712
  store %Point %t720, %Point* %t721
  %t722 = getelementptr inbounds %Point, %Point* %t721, i32 0, i32 1
  %t723 = load i32, i32* %t722
  %t724 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t724, i32 %t697, i32 %t723)
  store i8* null, i8** %t725
  %t726 = load i8*, i8** %t725
  %t727 = icmp eq i8* %t726, null
  br i1 %t727, label %table_cow_alloc_120, label %table_cow_check_121
table_cow_alloc_120:
  %t749 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t750 = getelementptr { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* null, i32 1
  %t751 = ptrtoint { i64, i64, i8**, i8** }* %t750 to i64
  %t752 = call i8* @star_rc_alloc(i64 %t751, i8* %t749)
  %t753 = bitcast i8* %t752 to { i64, i64, i8**, i8** }*
  %t754 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t753, i32 0, i32 0
  store i64 0, i64* %t754
  %t755 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t753, i32 0, i32 1
  store i64 0, i64* %t755
  %t756 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t753, i32 0, i32 2
  store i8** null, i8*** %t756
  %t757 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t753, i32 0, i32 3
  store i8** null, i8*** %t757
  store i8* %t752, i8** %t725
  br label %table_cow_done_122
table_cow_check_121:
  %t758 = getelementptr inbounds i8, i8* %t726, i64 -16
  %t759 = bitcast i8* %t758 to i64*
  %t760 = load atomic i64, i64* %t759 seq_cst, align 8
  %t761 = icmp eq i64 %t760, 1
  br i1 %t761, label %table_cow_done_122, label %table_cow_clone_129
table_cow_clone_129:
  %t762 = bitcast i8* %t726 to { i64, i64, i8**, i8** }*
  %t763 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t762, i32 0, i32 0
  %t764 = load i64, i64* %t763
  %t765 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t762, i32 0, i32 1
  %t766 = load i64, i64* %t765
  %t767 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t768 = getelementptr { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* null, i32 1
  %t769 = ptrtoint { i64, i64, i8**, i8** }* %t768 to i64
  %t770 = call i8* @star_rc_alloc(i64 %t769, i8* %t767)
  %t771 = bitcast i8* %t770 to { i64, i64, i8**, i8** }*
  %t772 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t771, i32 0, i32 0
  store i64 %t764, i64* %t772
  %t773 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t771, i32 0, i32 1
  store i64 %t766, i64* %t773
  %t774 = getelementptr i8*, i8** null, i32 1
  %t775 = ptrtoint i8** %t774 to i64
  %t776 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t762, i32 0, i32 2
  %t777 = load i8**, i8*** %t776
  %t778 = mul i64 %t766, %t775
  %t779 = call i8* @malloc(i64 %t778)
  %t780 = bitcast i8* %t779 to i8**
  %t781 = icmp sgt i64 %t764, 0
  br i1 %t781, label %table_cow_copy_130, label %table_cow_after_copy_131
table_cow_copy_130:
  %t782 = mul i64 %t764, %t775
  %t783 = bitcast i8** %t777 to i8*
  call i8* @memcpy(i8* %t779, i8* %t783, i64 %t782)
  store i64 0, i64* %t784
  br label %table_cow_retain_cond_132
table_cow_retain_cond_132:
  %t785 = load i64, i64* %t784
  %t786 = icmp slt i64 %t785, %t764
  br i1 %t786, label %table_cow_retain_body_133, label %table_cow_retain_end_134
table_cow_retain_body_133:
  %t787 = getelementptr inbounds i8*, i8** %t780, i64 %t785
  %t788 = load i8*, i8** %t787
  call void @star_rc_retain(i8* %t788)
  %t789 = add i64 %t785, 1
  store i64 %t789, i64* %t784
  br label %table_cow_retain_cond_132
table_cow_retain_end_134:
  br label %table_cow_after_copy_131
table_cow_after_copy_131:
  %t790 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t771, i32 0, i32 2
  store i8** %t780, i8*** %t790
  %t791 = getelementptr i8*, i8** null, i32 1
  %t792 = ptrtoint i8** %t791 to i64
  %t793 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t762, i32 0, i32 3
  %t794 = load i8**, i8*** %t793
  %t795 = mul i64 %t766, %t792
  %t796 = call i8* @malloc(i64 %t795)
  %t797 = bitcast i8* %t796 to i8**
  %t798 = icmp sgt i64 %t764, 0
  br i1 %t798, label %table_cow_copy_135, label %table_cow_after_copy_136
table_cow_copy_135:
  %t799 = mul i64 %t764, %t792
  %t800 = bitcast i8** %t794 to i8*
  call i8* @memcpy(i8* %t796, i8* %t800, i64 %t799)
  store i64 0, i64* %t801
  br label %table_cow_retain_cond_137
table_cow_retain_cond_137:
  %t802 = load i64, i64* %t801
  %t803 = icmp slt i64 %t802, %t764
  br i1 %t803, label %table_cow_retain_body_138, label %table_cow_retain_end_139
table_cow_retain_body_138:
  %t804 = getelementptr inbounds i8*, i8** %t797, i64 %t802
  %t805 = load i8*, i8** %t804
  call void @star_rc_retain(i8* %t805)
  %t806 = add i64 %t802, 1
  store i64 %t806, i64* %t801
  br label %table_cow_retain_cond_137
table_cow_retain_end_139:
  br label %table_cow_after_copy_136
table_cow_after_copy_136:
  %t807 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t771, i32 0, i32 3
  store i8** %t797, i8*** %t807
  call void @star_rc_release(i8* %t726)
  store i8* %t770, i8** %t725
  br label %table_cow_done_122
table_cow_done_122:
  %t808 = load i8*, i8** %t725
  %t809 = bitcast i8* %t808 to { i64, i64, i8**, i8** }*
  %t810 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t809, i32 0, i32 0
  %t811 = load i64, i64* %t810
  %t812 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t809, i32 0, i32 1
  %t813 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t809, i32 0, i32 2
  %t814 = load i8**, i8*** %t813
  %t815 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t809, i32 0, i32 3
  %t816 = load i8**, i8*** %t815
  %t818 = getelementptr i32, i32* null, i32 1
  %t819 = ptrtoint i32* %t818 to i64
  %t820 = mul i64 %t819, 3
  %t821 = call i8* @malloc(i64 %t820)
  %t822 = bitcast i8* %t821 to i32*
  %t823 = getelementptr inbounds i32, i32* %t822, i64 0
  store i32 7, i32* %t823
  %t824 = getelementptr inbounds i32, i32* %t822, i64 1
  store i32 8, i32* %t824
  %t825 = getelementptr inbounds i32, i32* %t822, i64 2
  store i32 9, i32* %t825
  %t826 = bitcast void (i8*)* @list_release_i32 to i8*
  %t827 = call i8* @star_rc_alloc(i64 24, i8* %t826)
  %t828 = bitcast i8* %t827 to { i32*, i64, i64 }*
  %t829 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t828, i32 0, i32 0
  store i32* %t822, i32** %t829
  %t830 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t828, i32 0, i32 1
  store i64 3, i64* %t830
  %t831 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t828, i32 0, i32 2
  store i64 3, i64* %t831
  %t832 = getelementptr inbounds %Bag, %Bag* %t817, i32 0, i32 0
  store i8* %t827, i8** %t832
  %t833 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t834 = getelementptr inbounds %Bag, %Bag* %t817, i32 0, i32 1
  store i8* %t833, i8** %t834
  %t835 = load %Bag, %Bag* %t817
  %t836 = load i64, i64* %t812
  %t837 = load i64, i64* %t810
  %t838 = load i8**, i8*** %t813
  %t839 = load i8**, i8*** %t815
  %t840 = icmp sge i64 %t837, %t836
  br i1 %t840, label %table_push_grow_140, label %table_push_store_141
table_push_grow_140:
  %t841 = mul i64 %t836, 2
  %t842 = icmp sgt i64 %t841, 0
  %t843 = select i1 %t842, i64 %t841, i64 1
  %t844 = getelementptr i8*, i8** null, i32 1
  %t845 = ptrtoint i8** %t844 to i64
  %t846 = mul i64 %t843, %t845
  %t847 = call i8* @malloc(i64 %t846)
  %t848 = bitcast i8* %t847 to i8**
  %t849 = icmp sgt i64 %t836, 0
  br i1 %t849, label %table_push_copy_142, label %table_push_after_copy_143
table_push_copy_142:
  %t850 = mul i64 %t837, %t845
  %t851 = bitcast i8** %t838 to i8*
  call i8* @memcpy(i8* %t847, i8* %t851, i64 %t850)
  call void @free(i8* %t851)
  br label %table_push_after_copy_143
table_push_after_copy_143:
  store i8** %t848, i8*** %t813
  %t852 = getelementptr i8*, i8** null, i32 1
  %t853 = ptrtoint i8** %t852 to i64
  %t854 = mul i64 %t843, %t853
  %t855 = call i8* @malloc(i64 %t854)
  %t856 = bitcast i8* %t855 to i8**
  %t857 = icmp sgt i64 %t836, 0
  br i1 %t857, label %table_push_copy_144, label %table_push_after_copy_145
table_push_copy_144:
  %t858 = mul i64 %t837, %t853
  %t859 = bitcast i8** %t839 to i8*
  call i8* @memcpy(i8* %t855, i8* %t859, i64 %t858)
  call void @free(i8* %t859)
  br label %table_push_after_copy_145
table_push_after_copy_145:
  store i8** %t856, i8*** %t815
  store i64 %t843, i64* %t812
  br label %table_push_store_141
table_push_store_141:
  %t860 = load i8**, i8*** %t813
  %t861 = extractvalue %Bag %t835, 0
  %t862 = getelementptr inbounds i8*, i8** %t860, i64 %t837
  store i8* %t861, i8** %t862
  %t863 = load i8**, i8*** %t815
  %t864 = extractvalue %Bag %t835, 1
  %t865 = getelementptr inbounds i8*, i8** %t863, i64 %t837
  store i8* %t864, i8** %t865
  %t866 = add i64 %t837, 1
  store i64 %t866, i64* %t810
  %t867 = load i8*, i8** %t725
  %t868 = icmp eq i8* %t867, null
  br i1 %t868, label %table_cow_alloc_146, label %table_cow_check_147
table_cow_alloc_146:
  %t869 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t870 = getelementptr { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* null, i32 1
  %t871 = ptrtoint { i64, i64, i8**, i8** }* %t870 to i64
  %t872 = call i8* @star_rc_alloc(i64 %t871, i8* %t869)
  %t873 = bitcast i8* %t872 to { i64, i64, i8**, i8** }*
  %t874 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t873, i32 0, i32 0
  store i64 0, i64* %t874
  %t875 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t873, i32 0, i32 1
  store i64 0, i64* %t875
  %t876 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t873, i32 0, i32 2
  store i8** null, i8*** %t876
  %t877 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t873, i32 0, i32 3
  store i8** null, i8*** %t877
  store i8* %t872, i8** %t725
  br label %table_cow_done_148
table_cow_check_147:
  %t878 = getelementptr inbounds i8, i8* %t867, i64 -16
  %t879 = bitcast i8* %t878 to i64*
  %t880 = load atomic i64, i64* %t879 seq_cst, align 8
  %t881 = icmp eq i64 %t880, 1
  br i1 %t881, label %table_cow_done_148, label %table_cow_clone_149
table_cow_clone_149:
  %t882 = bitcast i8* %t867 to { i64, i64, i8**, i8** }*
  %t883 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t882, i32 0, i32 0
  %t884 = load i64, i64* %t883
  %t885 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t882, i32 0, i32 1
  %t886 = load i64, i64* %t885
  %t887 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t888 = getelementptr { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* null, i32 1
  %t889 = ptrtoint { i64, i64, i8**, i8** }* %t888 to i64
  %t890 = call i8* @star_rc_alloc(i64 %t889, i8* %t887)
  %t891 = bitcast i8* %t890 to { i64, i64, i8**, i8** }*
  %t892 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t891, i32 0, i32 0
  store i64 %t884, i64* %t892
  %t893 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t891, i32 0, i32 1
  store i64 %t886, i64* %t893
  %t894 = getelementptr i8*, i8** null, i32 1
  %t895 = ptrtoint i8** %t894 to i64
  %t896 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t882, i32 0, i32 2
  %t897 = load i8**, i8*** %t896
  %t898 = mul i64 %t886, %t895
  %t899 = call i8* @malloc(i64 %t898)
  %t900 = bitcast i8* %t899 to i8**
  %t901 = icmp sgt i64 %t884, 0
  br i1 %t901, label %table_cow_copy_150, label %table_cow_after_copy_151
table_cow_copy_150:
  %t902 = mul i64 %t884, %t895
  %t903 = bitcast i8** %t897 to i8*
  call i8* @memcpy(i8* %t899, i8* %t903, i64 %t902)
  store i64 0, i64* %t904
  br label %table_cow_retain_cond_152
table_cow_retain_cond_152:
  %t905 = load i64, i64* %t904
  %t906 = icmp slt i64 %t905, %t884
  br i1 %t906, label %table_cow_retain_body_153, label %table_cow_retain_end_154
table_cow_retain_body_153:
  %t907 = getelementptr inbounds i8*, i8** %t900, i64 %t905
  %t908 = load i8*, i8** %t907
  call void @star_rc_retain(i8* %t908)
  %t909 = add i64 %t905, 1
  store i64 %t909, i64* %t904
  br label %table_cow_retain_cond_152
table_cow_retain_end_154:
  br label %table_cow_after_copy_151
table_cow_after_copy_151:
  %t910 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t891, i32 0, i32 2
  store i8** %t900, i8*** %t910
  %t911 = getelementptr i8*, i8** null, i32 1
  %t912 = ptrtoint i8** %t911 to i64
  %t913 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t882, i32 0, i32 3
  %t914 = load i8**, i8*** %t913
  %t915 = mul i64 %t886, %t912
  %t916 = call i8* @malloc(i64 %t915)
  %t917 = bitcast i8* %t916 to i8**
  %t918 = icmp sgt i64 %t884, 0
  br i1 %t918, label %table_cow_copy_155, label %table_cow_after_copy_156
table_cow_copy_155:
  %t919 = mul i64 %t884, %t912
  %t920 = bitcast i8** %t914 to i8*
  call i8* @memcpy(i8* %t916, i8* %t920, i64 %t919)
  store i64 0, i64* %t921
  br label %table_cow_retain_cond_157
table_cow_retain_cond_157:
  %t922 = load i64, i64* %t921
  %t923 = icmp slt i64 %t922, %t884
  br i1 %t923, label %table_cow_retain_body_158, label %table_cow_retain_end_159
table_cow_retain_body_158:
  %t924 = getelementptr inbounds i8*, i8** %t917, i64 %t922
  %t925 = load i8*, i8** %t924
  call void @star_rc_retain(i8* %t925)
  %t926 = add i64 %t922, 1
  store i64 %t926, i64* %t921
  br label %table_cow_retain_cond_157
table_cow_retain_end_159:
  br label %table_cow_after_copy_156
table_cow_after_copy_156:
  %t927 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t891, i32 0, i32 3
  store i8** %t917, i8*** %t927
  call void @star_rc_release(i8* %t867)
  store i8* %t890, i8** %t725
  br label %table_cow_done_148
table_cow_done_148:
  %t928 = load i8*, i8** %t725
  %t929 = bitcast i8* %t928 to { i64, i64, i8**, i8** }*
  %t930 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t929, i32 0, i32 0
  %t931 = load i64, i64* %t930
  %t932 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t929, i32 0, i32 1
  %t933 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t929, i32 0, i32 2
  %t934 = load i8**, i8*** %t933
  %t935 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t929, i32 0, i32 3
  %t936 = load i8**, i8*** %t935
  %t938 = getelementptr inbounds %Bag, %Bag* %t937, i32 0, i32 0
  store i8* null, i8** %t938
  %t939 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t940 = getelementptr inbounds %Bag, %Bag* %t937, i32 0, i32 1
  store i8* %t939, i8** %t940
  %t941 = load %Bag, %Bag* %t937
  %t942 = load i64, i64* %t932
  %t943 = load i64, i64* %t930
  %t944 = load i8**, i8*** %t933
  %t945 = load i8**, i8*** %t935
  %t946 = icmp sge i64 %t943, %t942
  br i1 %t946, label %table_push_grow_160, label %table_push_store_161
table_push_grow_160:
  %t947 = mul i64 %t942, 2
  %t948 = icmp sgt i64 %t947, 0
  %t949 = select i1 %t948, i64 %t947, i64 1
  %t950 = getelementptr i8*, i8** null, i32 1
  %t951 = ptrtoint i8** %t950 to i64
  %t952 = mul i64 %t949, %t951
  %t953 = call i8* @malloc(i64 %t952)
  %t954 = bitcast i8* %t953 to i8**
  %t955 = icmp sgt i64 %t942, 0
  br i1 %t955, label %table_push_copy_162, label %table_push_after_copy_163
table_push_copy_162:
  %t956 = mul i64 %t943, %t951
  %t957 = bitcast i8** %t944 to i8*
  call i8* @memcpy(i8* %t953, i8* %t957, i64 %t956)
  call void @free(i8* %t957)
  br label %table_push_after_copy_163
table_push_after_copy_163:
  store i8** %t954, i8*** %t933
  %t958 = getelementptr i8*, i8** null, i32 1
  %t959 = ptrtoint i8** %t958 to i64
  %t960 = mul i64 %t949, %t959
  %t961 = call i8* @malloc(i64 %t960)
  %t962 = bitcast i8* %t961 to i8**
  %t963 = icmp sgt i64 %t942, 0
  br i1 %t963, label %table_push_copy_164, label %table_push_after_copy_165
table_push_copy_164:
  %t964 = mul i64 %t943, %t959
  %t965 = bitcast i8** %t945 to i8*
  call i8* @memcpy(i8* %t961, i8* %t965, i64 %t964)
  call void @free(i8* %t965)
  br label %table_push_after_copy_165
table_push_after_copy_165:
  store i8** %t962, i8*** %t935
  store i64 %t949, i64* %t932
  br label %table_push_store_161
table_push_store_161:
  %t966 = load i8**, i8*** %t933
  %t967 = extractvalue %Bag %t941, 0
  %t968 = getelementptr inbounds i8*, i8** %t966, i64 %t943
  store i8* %t967, i8** %t968
  %t969 = load i8**, i8*** %t935
  %t970 = extractvalue %Bag %t941, 1
  %t971 = getelementptr inbounds i8*, i8** %t969, i64 %t943
  store i8* %t970, i8** %t971
  %t972 = add i64 %t943, 1
  store i64 %t972, i64* %t930
  %t973 = sext i32 0 to i64
  %t974 = load i8*, i8** %t725
  %t975 = icmp eq i8* %t974, null
  br i1 %t975, label %table_read_null_166, label %table_read_real_167
table_read_null_166:
  br label %table_read_end_168
table_read_real_167:
  %t976 = bitcast i8* %t974 to { i64, i64, i8**, i8** }*
  %t977 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t976, i32 0, i32 0
  %t978 = load i64, i64* %t977
  %t979 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t976, i32 0, i32 2
  %t980 = load i8**, i8*** %t979
  %t981 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t976, i32 0, i32 3
  %t982 = load i8**, i8*** %t981
  br label %table_read_end_168
table_read_end_168:
  %t983 = phi i64 [ 0, %table_read_null_166 ], [ %t978, %table_read_real_167 ]
  %t984 = phi i8** [ null, %table_read_null_166 ], [ %t980, %table_read_real_167 ]
  %t985 = phi i8** [ null, %table_read_null_166 ], [ %t982, %table_read_real_167 ]
  %t987 = icmp ult i64 %t973, %t983
  br i1 %t987, label %table_idx_ok_169, label %table_idx_oob_170
table_idx_ok_169:
  %t988 = getelementptr inbounds i8*, i8** %t984, i64 %t973
  %t989 = load i8*, i8** %t988
  call void @star_rc_retain(i8* %t989)
  %t990 = load i8*, i8** %t988
  %t991 = getelementptr inbounds %Bag, %Bag* %t986, i32 0, i32 0
  store i8* %t990, i8** %t991
  %t992 = getelementptr inbounds i8*, i8** %t985, i64 %t973
  %t993 = load i8*, i8** %t992
  call void @star_rc_retain(i8* %t993)
  %t994 = load i8*, i8** %t992
  %t995 = getelementptr inbounds %Bag, %Bag* %t986, i32 0, i32 1
  store i8* %t994, i8** %t995
  br label %table_idx_end_171
table_idx_oob_170:
  store %Bag zeroinitializer, %Bag* %t986
  br label %table_idx_end_171
table_idx_end_171:
  %t996 = load %Bag, %Bag* %t986
  store %Bag %t996, %Bag* %t997
  %t998 = getelementptr inbounds %Bag, %Bag* %t997, i32 0, i32 1
  %t999 = load i8*, i8** %t998
  %t1000 = load i8*, i8** %t998
  call void @star_rc_retain(i8* %t1000)
  call void @star_rc_release(i8* %t999)
  %t1001 = sext i32 0 to i64
  %t1002 = load i8*, i8** %t725
  %t1003 = icmp eq i8* %t1002, null
  br i1 %t1003, label %table_read_null_172, label %table_read_real_173
table_read_null_172:
  br label %table_read_end_174
table_read_real_173:
  %t1004 = bitcast i8* %t1002 to { i64, i64, i8**, i8** }*
  %t1005 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1004, i32 0, i32 0
  %t1006 = load i64, i64* %t1005
  %t1007 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1004, i32 0, i32 2
  %t1008 = load i8**, i8*** %t1007
  %t1009 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1004, i32 0, i32 3
  %t1010 = load i8**, i8*** %t1009
  br label %table_read_end_174
table_read_end_174:
  %t1011 = phi i64 [ 0, %table_read_null_172 ], [ %t1006, %table_read_real_173 ]
  %t1012 = phi i8** [ null, %table_read_null_172 ], [ %t1008, %table_read_real_173 ]
  %t1013 = phi i8** [ null, %table_read_null_172 ], [ %t1010, %table_read_real_173 ]
  %t1015 = icmp ult i64 %t1001, %t1011
  br i1 %t1015, label %table_idx_ok_175, label %table_idx_oob_176
table_idx_ok_175:
  %t1016 = getelementptr inbounds i8*, i8** %t1012, i64 %t1001
  %t1017 = load i8*, i8** %t1016
  call void @star_rc_retain(i8* %t1017)
  %t1018 = load i8*, i8** %t1016
  %t1019 = getelementptr inbounds %Bag, %Bag* %t1014, i32 0, i32 0
  store i8* %t1018, i8** %t1019
  %t1020 = getelementptr inbounds i8*, i8** %t1013, i64 %t1001
  %t1021 = load i8*, i8** %t1020
  call void @star_rc_retain(i8* %t1021)
  %t1022 = load i8*, i8** %t1020
  %t1023 = getelementptr inbounds %Bag, %Bag* %t1014, i32 0, i32 1
  store i8* %t1022, i8** %t1023
  br label %table_idx_end_177
table_idx_oob_176:
  store %Bag zeroinitializer, %Bag* %t1014
  br label %table_idx_end_177
table_idx_end_177:
  %t1024 = load %Bag, %Bag* %t1014
  store %Bag %t1024, %Bag* %t1025
  %t1026 = getelementptr inbounds %Bag, %Bag* %t1025, i32 0, i32 0
  %t1027 = load i8*, i8** %t1026
  %t1028 = icmp eq i8* %t1027, null
  br i1 %t1028, label %list_read_null_178, label %list_read_real_179
list_read_null_178:
  br label %list_read_end_180
list_read_real_179:
  %t1029 = bitcast i8* %t1027 to { i32*, i64, i64 }*
  %t1030 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1029, i32 0, i32 0
  %t1031 = load i32*, i32** %t1030
  %t1032 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1029, i32 0, i32 1
  %t1033 = load i64, i64* %t1032
  br label %list_read_end_180
list_read_end_180:
  %t1034 = phi i32* [ null, %list_read_null_178 ], [ %t1031, %list_read_real_179 ]
  %t1035 = phi i64 [ 0, %list_read_null_178 ], [ %t1033, %list_read_real_179 ]
  %t1036 = trunc i64 %t1035 to i32
  %t1037 = getelementptr inbounds [41 x i8], [41 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1037, i8* %t999, i32 %t1036)
  %t1038 = sext i32 1 to i64
  %t1039 = load i8*, i8** %t725
  %t1040 = icmp eq i8* %t1039, null
  br i1 %t1040, label %table_read_null_181, label %table_read_real_182
table_read_null_181:
  br label %table_read_end_183
table_read_real_182:
  %t1041 = bitcast i8* %t1039 to { i64, i64, i8**, i8** }*
  %t1042 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1041, i32 0, i32 0
  %t1043 = load i64, i64* %t1042
  %t1044 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1041, i32 0, i32 2
  %t1045 = load i8**, i8*** %t1044
  %t1046 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1041, i32 0, i32 3
  %t1047 = load i8**, i8*** %t1046
  br label %table_read_end_183
table_read_end_183:
  %t1048 = phi i64 [ 0, %table_read_null_181 ], [ %t1043, %table_read_real_182 ]
  %t1049 = phi i8** [ null, %table_read_null_181 ], [ %t1045, %table_read_real_182 ]
  %t1050 = phi i8** [ null, %table_read_null_181 ], [ %t1047, %table_read_real_182 ]
  %t1052 = icmp ult i64 %t1038, %t1048
  br i1 %t1052, label %table_idx_ok_184, label %table_idx_oob_185
table_idx_ok_184:
  %t1053 = getelementptr inbounds i8*, i8** %t1049, i64 %t1038
  %t1054 = load i8*, i8** %t1053
  call void @star_rc_retain(i8* %t1054)
  %t1055 = load i8*, i8** %t1053
  %t1056 = getelementptr inbounds %Bag, %Bag* %t1051, i32 0, i32 0
  store i8* %t1055, i8** %t1056
  %t1057 = getelementptr inbounds i8*, i8** %t1050, i64 %t1038
  %t1058 = load i8*, i8** %t1057
  call void @star_rc_retain(i8* %t1058)
  %t1059 = load i8*, i8** %t1057
  %t1060 = getelementptr inbounds %Bag, %Bag* %t1051, i32 0, i32 1
  store i8* %t1059, i8** %t1060
  br label %table_idx_end_186
table_idx_oob_185:
  store %Bag zeroinitializer, %Bag* %t1051
  br label %table_idx_end_186
table_idx_end_186:
  %t1061 = load %Bag, %Bag* %t1051
  store %Bag %t1061, %Bag* %t1062
  %t1063 = getelementptr inbounds %Bag, %Bag* %t1062, i32 0, i32 1
  %t1064 = load i8*, i8** %t1063
  %t1065 = load i8*, i8** %t1063
  call void @star_rc_retain(i8* %t1065)
  call void @star_rc_release(i8* %t1064)
  %t1066 = sext i32 1 to i64
  %t1067 = load i8*, i8** %t725
  %t1068 = icmp eq i8* %t1067, null
  br i1 %t1068, label %table_read_null_187, label %table_read_real_188
table_read_null_187:
  br label %table_read_end_189
table_read_real_188:
  %t1069 = bitcast i8* %t1067 to { i64, i64, i8**, i8** }*
  %t1070 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1069, i32 0, i32 0
  %t1071 = load i64, i64* %t1070
  %t1072 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1069, i32 0, i32 2
  %t1073 = load i8**, i8*** %t1072
  %t1074 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1069, i32 0, i32 3
  %t1075 = load i8**, i8*** %t1074
  br label %table_read_end_189
table_read_end_189:
  %t1076 = phi i64 [ 0, %table_read_null_187 ], [ %t1071, %table_read_real_188 ]
  %t1077 = phi i8** [ null, %table_read_null_187 ], [ %t1073, %table_read_real_188 ]
  %t1078 = phi i8** [ null, %table_read_null_187 ], [ %t1075, %table_read_real_188 ]
  %t1080 = icmp ult i64 %t1066, %t1076
  br i1 %t1080, label %table_idx_ok_190, label %table_idx_oob_191
table_idx_ok_190:
  %t1081 = getelementptr inbounds i8*, i8** %t1077, i64 %t1066
  %t1082 = load i8*, i8** %t1081
  call void @star_rc_retain(i8* %t1082)
  %t1083 = load i8*, i8** %t1081
  %t1084 = getelementptr inbounds %Bag, %Bag* %t1079, i32 0, i32 0
  store i8* %t1083, i8** %t1084
  %t1085 = getelementptr inbounds i8*, i8** %t1078, i64 %t1066
  %t1086 = load i8*, i8** %t1085
  call void @star_rc_retain(i8* %t1086)
  %t1087 = load i8*, i8** %t1085
  %t1088 = getelementptr inbounds %Bag, %Bag* %t1079, i32 0, i32 1
  store i8* %t1087, i8** %t1088
  br label %table_idx_end_192
table_idx_oob_191:
  store %Bag zeroinitializer, %Bag* %t1079
  br label %table_idx_end_192
table_idx_end_192:
  %t1089 = load %Bag, %Bag* %t1079
  store %Bag %t1089, %Bag* %t1090
  %t1091 = getelementptr inbounds %Bag, %Bag* %t1090, i32 0, i32 0
  %t1092 = load i8*, i8** %t1091
  %t1093 = icmp eq i8* %t1092, null
  br i1 %t1093, label %list_read_null_193, label %list_read_real_194
list_read_null_193:
  br label %list_read_end_195
list_read_real_194:
  %t1094 = bitcast i8* %t1092 to { i32*, i64, i64 }*
  %t1095 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1094, i32 0, i32 0
  %t1096 = load i32*, i32** %t1095
  %t1097 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1094, i32 0, i32 1
  %t1098 = load i64, i64* %t1097
  br label %list_read_end_195
list_read_end_195:
  %t1099 = phi i32* [ null, %list_read_null_193 ], [ %t1096, %list_read_real_194 ]
  %t1100 = phi i64 [ 0, %list_read_null_193 ], [ %t1098, %list_read_real_194 ]
  %t1101 = trunc i64 %t1100 to i32
  %t1102 = getelementptr inbounds [41 x i8], [41 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1102, i8* %t1064, i32 %t1101)
  %t1103 = getelementptr inbounds %Bag, %Bag* %t1090, i32 0, i32 0
  %t1104 = load i8*, i8** %t1103
  call void @star_rc_release(i8* %t1104)
  %t1105 = getelementptr inbounds %Bag, %Bag* %t1090, i32 0, i32 1
  %t1106 = load i8*, i8** %t1105
  call void @star_rc_release(i8* %t1106)
  %t1107 = getelementptr inbounds %Bag, %Bag* %t1062, i32 0, i32 0
  %t1108 = load i8*, i8** %t1107
  call void @star_rc_release(i8* %t1108)
  %t1109 = getelementptr inbounds %Bag, %Bag* %t1062, i32 0, i32 1
  %t1110 = load i8*, i8** %t1109
  call void @star_rc_release(i8* %t1110)
  %t1111 = getelementptr inbounds %Bag, %Bag* %t1025, i32 0, i32 0
  %t1112 = load i8*, i8** %t1111
  call void @star_rc_release(i8* %t1112)
  %t1113 = getelementptr inbounds %Bag, %Bag* %t1025, i32 0, i32 1
  %t1114 = load i8*, i8** %t1113
  call void @star_rc_release(i8* %t1114)
  %t1115 = getelementptr inbounds %Bag, %Bag* %t997, i32 0, i32 0
  %t1116 = load i8*, i8** %t1115
  call void @star_rc_release(i8* %t1116)
  %t1117 = getelementptr inbounds %Bag, %Bag* %t997, i32 0, i32 1
  %t1118 = load i8*, i8** %t1117
  call void @star_rc_release(i8* %t1118)
  %t1119 = load i8*, i8** %t725
  call void @star_rc_release(i8* %t1119)
  %t1120 = load i8*, i8** %t498
  call void @star_rc_release(i8* %t1120)
  %t1121 = load i8*, i8** %t302
  call void @star_rc_release(i8* %t1121)
  %t1122 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t106, i32 0, i32 0
  %t1123 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t1122, i32 0, i64 0
  %t1124 = getelementptr inbounds %Bag, %Bag* %t1123, i32 0, i32 0
  %t1125 = load i8*, i8** %t1124
  call void @star_rc_release(i8* %t1125)
  %t1126 = getelementptr inbounds %Bag, %Bag* %t1123, i32 0, i32 1
  %t1127 = load i8*, i8** %t1126
  call void @star_rc_release(i8* %t1127)
  %t1128 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t1122, i32 0, i64 1
  %t1129 = getelementptr inbounds %Bag, %Bag* %t1128, i32 0, i32 0
  %t1130 = load i8*, i8** %t1129
  call void @star_rc_release(i8* %t1130)
  %t1131 = getelementptr inbounds %Bag, %Bag* %t1128, i32 0, i32 1
  %t1132 = load i8*, i8** %t1131
  call void @star_rc_release(i8* %t1132)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_i32(i8* %objp) {
entry:
  %t116 = bitcast i8* %objp to { i32*, i64, i64 }*
  %t117 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t116, i32 0, i32 0
  %t118 = load i32*, i32** %t117
  %t119 = bitcast i32* %t118 to i8*
  call void @free(i8* %t119)
  ret void
}


define void @table_release_s_Point(i8* %objp) {
entry:
  %t305 = bitcast i8* %objp to { i64, i64, i32*, i32* }*
  %t306 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t305, i32 0, i32 0
  %t307 = load i64, i64* %t306
  %t308 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t305, i32 0, i32 2
  %t309 = load i32*, i32** %t308
  %t310 = bitcast i32* %t309 to i8*
  call void @free(i8* %t310)
  %t311 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t305, i32 0, i32 3
  %t312 = load i32*, i32** %t311
  %t313 = bitcast i32* %t312 to i8*
  call void @free(i8* %t313)
  ret void
}


define void @table_release_s_Bag(i8* %objp) {
entry:
  %t733 = alloca i64
  %t742 = alloca i64
  %t728 = bitcast i8* %objp to { i64, i64, i8**, i8** }*
  %t729 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t728, i32 0, i32 0
  %t730 = load i64, i64* %t729
  %t731 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t728, i32 0, i32 2
  %t732 = load i8**, i8*** %t731
  store i64 0, i64* %t733
  br label %table_release_cond_123
table_release_cond_123:
  %t734 = load i64, i64* %t733
  %t735 = icmp slt i64 %t734, %t730
  br i1 %t735, label %table_release_body_124, label %table_release_end_125
table_release_body_124:
  %t736 = getelementptr inbounds i8*, i8** %t732, i64 %t734
  %t737 = load i8*, i8** %t736
  call void @star_rc_release(i8* %t737)
  %t738 = add i64 %t734, 1
  store i64 %t738, i64* %t733
  br label %table_release_cond_123
table_release_end_125:
  %t739 = bitcast i8** %t732 to i8*
  call void @free(i8* %t739)
  %t740 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t728, i32 0, i32 3
  %t741 = load i8**, i8*** %t740
  store i64 0, i64* %t742
  br label %table_release_cond_126
table_release_cond_126:
  %t743 = load i64, i64* %t742
  %t744 = icmp slt i64 %t743, %t730
  br i1 %t744, label %table_release_body_127, label %table_release_end_128
table_release_body_127:
  %t745 = getelementptr inbounds i8*, i8** %t741, i64 %t743
  %t746 = load i8*, i8** %t745
  call void @star_rc_release(i8* %t746)
  %t747 = add i64 %t743, 1
  store i64 %t747, i64* %t742
  br label %table_release_cond_126
table_release_end_128:
  %t748 = bitcast i8** %t741 to i8*
  call void @free(i8* %t748)
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
