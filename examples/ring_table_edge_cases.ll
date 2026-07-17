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

%Bag = type { i8*, i8* }
%Point = type { i32, i32 }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca { [1 x i32], i64, i64 }
  %t60 = alloca i32
  %t64 = alloca { [3 x i32], i64, i64 }
  %t104 = alloca i32
  %t108 = alloca { [2 x %Bag], i64, i64 }
  %t109 = alloca %Bag
  %t149 = alloca %Bag
  %t184 = alloca %Bag
  %t230 = alloca %Bag
  %t247 = alloca %Bag
  %t273 = alloca %Bag
  %t290 = alloca %Bag
  %t304 = alloca i8*
  %t372 = alloca %Point
  %t465 = alloca %Point
  %t500 = alloca i8*
  %t561 = alloca %Point
  %t636 = alloca %Point
  %t647 = alloca %Point
  %t663 = alloca %Point
  %t674 = alloca %Point
  %t692 = alloca %Point
  %t703 = alloca %Point
  %t720 = alloca %Point
  %t731 = alloca %Point
  %t735 = alloca i8*
  %t794 = alloca i64
  %t811 = alloca i64
  %t827 = alloca %Bag
  %t914 = alloca i64
  %t931 = alloca i64
  %t947 = alloca %Bag
  %t996 = alloca %Bag
  %t1010 = alloca %Bag
  %t1027 = alloca %Bag
  %t1041 = alloca %Bag
  %t1067 = alloca %Bag
  %t1081 = alloca %Bag
  %t1098 = alloca %Bag
  %t1112 = alloca %Bag
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  store { [1 x i32], i64, i64 } zeroinitializer, { [1 x i32], i64, i64 }* %t2
  %t3 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t4 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t5 = load i64, i64* %t4
  %t6 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t7 = load i64, i64* %t6
  %t8 = icmp sge i64 %t7, 1
  br i1 %t8, label %ring_push_full_0, label %ring_push_grow_1
ring_push_grow_1:
  %t9 = add i64 %t5, %t7
  %t10 = urem i64 %t9, 1
  %t11 = getelementptr inbounds [1 x i32], [1 x i32]* %t3, i32 0, i64 %t10
  store i32 10, i32* %t11
  %t12 = add i64 %t7, 1
  store i64 %t12, i64* %t6
  br label %ring_push_done_2
ring_push_full_0:
  %t13 = getelementptr inbounds [1 x i32], [1 x i32]* %t3, i32 0, i64 %t5
  store i32 10, i32* %t13
  %t14 = add i64 %t5, 1
  %t15 = urem i64 %t14, 1
  store i64 %t15, i64* %t4
  br label %ring_push_done_2
ring_push_done_2:
  %t16 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t17 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t18 = load i64, i64* %t17
  %t19 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t20 = load i64, i64* %t19
  %t21 = icmp sge i64 %t20, 1
  br i1 %t21, label %ring_push_full_3, label %ring_push_grow_4
ring_push_grow_4:
  %t22 = add i64 %t18, %t20
  %t23 = urem i64 %t22, 1
  %t24 = getelementptr inbounds [1 x i32], [1 x i32]* %t16, i32 0, i64 %t23
  store i32 20, i32* %t24
  %t25 = add i64 %t20, 1
  store i64 %t25, i64* %t19
  br label %ring_push_done_5
ring_push_full_3:
  %t26 = getelementptr inbounds [1 x i32], [1 x i32]* %t16, i32 0, i64 %t18
  store i32 20, i32* %t26
  %t27 = add i64 %t18, 1
  %t28 = urem i64 %t27, 1
  store i64 %t28, i64* %t17
  br label %ring_push_done_5
ring_push_done_5:
  %t29 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t30 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t31 = load i64, i64* %t30
  %t32 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t33 = load i64, i64* %t32
  %t34 = icmp sge i64 %t33, 1
  br i1 %t34, label %ring_push_full_6, label %ring_push_grow_7
ring_push_grow_7:
  %t35 = add i64 %t31, %t33
  %t36 = urem i64 %t35, 1
  %t37 = getelementptr inbounds [1 x i32], [1 x i32]* %t29, i32 0, i64 %t36
  store i32 30, i32* %t37
  %t38 = add i64 %t33, 1
  store i64 %t38, i64* %t32
  br label %ring_push_done_8
ring_push_full_6:
  %t39 = getelementptr inbounds [1 x i32], [1 x i32]* %t29, i32 0, i64 %t31
  store i32 30, i32* %t39
  %t40 = add i64 %t31, 1
  %t41 = urem i64 %t40, 1
  store i64 %t41, i64* %t30
  br label %ring_push_done_8
ring_push_done_8:
  %t42 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t43 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t44 = load i64, i64* %t43
  %t45 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t46 = load i64, i64* %t45
  %t47 = trunc i64 %t46 to i32
  %t48 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t2, i32 0, i32 0
  %t49 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t2, i32 0, i32 1
  %t50 = load i64, i64* %t49
  %t51 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t2, i32 0, i32 2
  %t52 = load i64, i64* %t51
  %t53 = sext i32 0 to i64
  %t54 = load i64, i64* %t49
  %t55 = load i64, i64* %t51
  %t56 = icmp ult i64 %t53, %t55
  br i1 %t56, label %ring_rplace_ok_9, label %ring_rplace_oob_10
ring_rplace_ok_9:
  %t57 = add i64 %t54, %t53
  %t58 = urem i64 %t57, 1
  %t59 = getelementptr inbounds [1 x i32], [1 x i32]* %t48, i32 0, i64 %t58
  br label %ring_rplace_end_11
ring_rplace_oob_10:
  store i32 0, i32* %t60
  br label %ring_rplace_end_11
ring_rplace_end_11:
  %t61 = phi i32* [ %t59, %ring_rplace_ok_9 ], [ %t60, %ring_rplace_oob_10 ]
  %t62 = load i32, i32* %t61
  %t63 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t63, i32 %t47, i32 %t62)
  store { [3 x i32], i64, i64 } zeroinitializer, { [3 x i32], i64, i64 }* %t64
  %t65 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t64, i32 0, i32 0
  %t66 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t64, i32 0, i32 1
  %t67 = load i64, i64* %t66
  %t68 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t64, i32 0, i32 2
  %t69 = load i64, i64* %t68
  %t70 = icmp sge i64 %t69, 3
  br i1 %t70, label %ring_push_full_12, label %ring_push_grow_13
ring_push_grow_13:
  %t71 = add i64 %t67, %t69
  %t72 = urem i64 %t71, 3
  %t73 = getelementptr inbounds [3 x i32], [3 x i32]* %t65, i32 0, i64 %t72
  store i32 1, i32* %t73
  %t74 = add i64 %t69, 1
  store i64 %t74, i64* %t68
  br label %ring_push_done_14
ring_push_full_12:
  %t75 = getelementptr inbounds [3 x i32], [3 x i32]* %t65, i32 0, i64 %t67
  store i32 1, i32* %t75
  %t76 = add i64 %t67, 1
  %t77 = urem i64 %t76, 3
  store i64 %t77, i64* %t66
  br label %ring_push_done_14
ring_push_done_14:
  %t78 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t64, i32 0, i32 0
  %t79 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t64, i32 0, i32 1
  %t80 = load i64, i64* %t79
  %t81 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t64, i32 0, i32 2
  %t82 = load i64, i64* %t81
  %t83 = icmp sge i64 %t82, 3
  br i1 %t83, label %ring_push_full_15, label %ring_push_grow_16
ring_push_grow_16:
  %t84 = add i64 %t80, %t82
  %t85 = urem i64 %t84, 3
  %t86 = getelementptr inbounds [3 x i32], [3 x i32]* %t78, i32 0, i64 %t85
  store i32 2, i32* %t86
  %t87 = add i64 %t82, 1
  store i64 %t87, i64* %t81
  br label %ring_push_done_17
ring_push_full_15:
  %t88 = getelementptr inbounds [3 x i32], [3 x i32]* %t78, i32 0, i64 %t80
  store i32 2, i32* %t88
  %t89 = add i64 %t80, 1
  %t90 = urem i64 %t89, 3
  store i64 %t90, i64* %t79
  br label %ring_push_done_17
ring_push_done_17:
  %t91 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t64, i32 0, i32 0
  %t92 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t64, i32 0, i32 1
  %t93 = load i64, i64* %t92
  %t94 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t64, i32 0, i32 2
  %t95 = load i64, i64* %t94
  %t96 = sub i32 0, 1
  %t97 = sext i32 %t96 to i64
  %t98 = load i64, i64* %t92
  %t99 = load i64, i64* %t94
  %t100 = icmp ult i64 %t97, %t99
  br i1 %t100, label %ring_rplace_ok_18, label %ring_rplace_oob_19
ring_rplace_ok_18:
  %t101 = add i64 %t98, %t97
  %t102 = urem i64 %t101, 3
  %t103 = getelementptr inbounds [3 x i32], [3 x i32]* %t91, i32 0, i64 %t102
  br label %ring_rplace_end_20
ring_rplace_oob_19:
  store i32 0, i32* %t104
  br label %ring_rplace_end_20
ring_rplace_end_20:
  %t105 = phi i32* [ %t103, %ring_rplace_ok_18 ], [ %t104, %ring_rplace_oob_19 ]
  %t106 = load i32, i32* %t105
  %t107 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t107, i32 %t106)
  store { [2 x %Bag], i64, i64 } zeroinitializer, { [2 x %Bag], i64, i64 }* %t108
  %t110 = getelementptr i32, i32* null, i32 1
  %t111 = ptrtoint i32* %t110 to i64
  %t112 = mul i64 %t111, 3
  %t113 = call i8* @malloc(i64 %t112)
  %t114 = bitcast i8* %t113 to i32*
  %t115 = getelementptr inbounds i32, i32* %t114, i64 0
  store i32 1, i32* %t115
  %t116 = getelementptr inbounds i32, i32* %t114, i64 1
  store i32 2, i32* %t116
  %t117 = getelementptr inbounds i32, i32* %t114, i64 2
  store i32 3, i32* %t117
  %t122 = bitcast void (i8*)* @list_release_i32 to i8*
  %t123 = call i8* @star_rc_alloc(i64 24, i8* %t122)
  %t124 = bitcast i8* %t123 to { i32*, i64, i64 }*
  %t125 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t124, i32 0, i32 0
  store i32* %t114, i32** %t125
  %t126 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t124, i32 0, i32 1
  store i64 3, i64* %t126
  %t127 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t124, i32 0, i32 2
  store i64 3, i64* %t127
  %t128 = getelementptr inbounds %Bag, %Bag* %t109, i32 0, i32 0
  store i8* %t123, i8** %t128
  %t129 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t130 = getelementptr inbounds %Bag, %Bag* %t109, i32 0, i32 1
  store i8* %t129, i8** %t130
  %t131 = load %Bag, %Bag* %t109
  %t132 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 0
  %t133 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 1
  %t134 = load i64, i64* %t133
  %t135 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 2
  %t136 = load i64, i64* %t135
  %t137 = icmp sge i64 %t136, 2
  br i1 %t137, label %ring_push_full_21, label %ring_push_grow_22
ring_push_grow_22:
  %t138 = add i64 %t134, %t136
  %t139 = urem i64 %t138, 2
  %t140 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t132, i32 0, i64 %t139
  store %Bag %t131, %Bag* %t140
  %t141 = add i64 %t136, 1
  store i64 %t141, i64* %t135
  br label %ring_push_done_23
ring_push_full_21:
  %t142 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t132, i32 0, i64 %t134
  %t143 = getelementptr inbounds %Bag, %Bag* %t142, i32 0, i32 0
  %t144 = load i8*, i8** %t143
  call void @star_rc_release(i8* %t144)
  %t145 = getelementptr inbounds %Bag, %Bag* %t142, i32 0, i32 1
  %t146 = load i8*, i8** %t145
  call void @star_rc_release(i8* %t146)
  store %Bag %t131, %Bag* %t142
  %t147 = add i64 %t134, 1
  %t148 = urem i64 %t147, 2
  store i64 %t148, i64* %t133
  br label %ring_push_done_23
ring_push_done_23:
  %t150 = getelementptr i32, i32* null, i32 1
  %t151 = ptrtoint i32* %t150 to i64
  %t152 = mul i64 %t151, 2
  %t153 = call i8* @malloc(i64 %t152)
  %t154 = bitcast i8* %t153 to i32*
  %t155 = getelementptr inbounds i32, i32* %t154, i64 0
  store i32 4, i32* %t155
  %t156 = getelementptr inbounds i32, i32* %t154, i64 1
  store i32 5, i32* %t156
  %t157 = bitcast void (i8*)* @list_release_i32 to i8*
  %t158 = call i8* @star_rc_alloc(i64 24, i8* %t157)
  %t159 = bitcast i8* %t158 to { i32*, i64, i64 }*
  %t160 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t159, i32 0, i32 0
  store i32* %t154, i32** %t160
  %t161 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t159, i32 0, i32 1
  store i64 2, i64* %t161
  %t162 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t159, i32 0, i32 2
  store i64 2, i64* %t162
  %t163 = getelementptr inbounds %Bag, %Bag* %t149, i32 0, i32 0
  store i8* %t158, i8** %t163
  %t164 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t165 = getelementptr inbounds %Bag, %Bag* %t149, i32 0, i32 1
  store i8* %t164, i8** %t165
  %t166 = load %Bag, %Bag* %t149
  %t167 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 0
  %t168 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 1
  %t169 = load i64, i64* %t168
  %t170 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 2
  %t171 = load i64, i64* %t170
  %t172 = icmp sge i64 %t171, 2
  br i1 %t172, label %ring_push_full_24, label %ring_push_grow_25
ring_push_grow_25:
  %t173 = add i64 %t169, %t171
  %t174 = urem i64 %t173, 2
  %t175 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t167, i32 0, i64 %t174
  store %Bag %t166, %Bag* %t175
  %t176 = add i64 %t171, 1
  store i64 %t176, i64* %t170
  br label %ring_push_done_26
ring_push_full_24:
  %t177 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t167, i32 0, i64 %t169
  %t178 = getelementptr inbounds %Bag, %Bag* %t177, i32 0, i32 0
  %t179 = load i8*, i8** %t178
  call void @star_rc_release(i8* %t179)
  %t180 = getelementptr inbounds %Bag, %Bag* %t177, i32 0, i32 1
  %t181 = load i8*, i8** %t180
  call void @star_rc_release(i8* %t181)
  store %Bag %t166, %Bag* %t177
  %t182 = add i64 %t169, 1
  %t183 = urem i64 %t182, 2
  store i64 %t183, i64* %t168
  br label %ring_push_done_26
ring_push_done_26:
  %t185 = getelementptr i32, i32* null, i32 1
  %t186 = ptrtoint i32* %t185 to i64
  %t187 = mul i64 %t186, 1
  %t188 = call i8* @malloc(i64 %t187)
  %t189 = bitcast i8* %t188 to i32*
  %t190 = getelementptr inbounds i32, i32* %t189, i64 0
  store i32 6, i32* %t190
  %t191 = bitcast void (i8*)* @list_release_i32 to i8*
  %t192 = call i8* @star_rc_alloc(i64 24, i8* %t191)
  %t193 = bitcast i8* %t192 to { i32*, i64, i64 }*
  %t194 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t193, i32 0, i32 0
  store i32* %t189, i32** %t194
  %t195 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t193, i32 0, i32 1
  store i64 1, i64* %t195
  %t196 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t193, i32 0, i32 2
  store i64 1, i64* %t196
  %t197 = getelementptr inbounds %Bag, %Bag* %t184, i32 0, i32 0
  store i8* %t192, i8** %t197
  %t198 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t199 = getelementptr inbounds %Bag, %Bag* %t184, i32 0, i32 1
  store i8* %t198, i8** %t199
  %t200 = load %Bag, %Bag* %t184
  %t201 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 0
  %t202 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 1
  %t203 = load i64, i64* %t202
  %t204 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 2
  %t205 = load i64, i64* %t204
  %t206 = icmp sge i64 %t205, 2
  br i1 %t206, label %ring_push_full_27, label %ring_push_grow_28
ring_push_grow_28:
  %t207 = add i64 %t203, %t205
  %t208 = urem i64 %t207, 2
  %t209 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t201, i32 0, i64 %t208
  store %Bag %t200, %Bag* %t209
  %t210 = add i64 %t205, 1
  store i64 %t210, i64* %t204
  br label %ring_push_done_29
ring_push_full_27:
  %t211 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t201, i32 0, i64 %t203
  %t212 = getelementptr inbounds %Bag, %Bag* %t211, i32 0, i32 0
  %t213 = load i8*, i8** %t212
  call void @star_rc_release(i8* %t213)
  %t214 = getelementptr inbounds %Bag, %Bag* %t211, i32 0, i32 1
  %t215 = load i8*, i8** %t214
  call void @star_rc_release(i8* %t215)
  store %Bag %t200, %Bag* %t211
  %t216 = add i64 %t203, 1
  %t217 = urem i64 %t216, 2
  store i64 %t217, i64* %t202
  br label %ring_push_done_29
ring_push_done_29:
  %t218 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 0
  %t219 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 1
  %t220 = load i64, i64* %t219
  %t221 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 2
  %t222 = load i64, i64* %t221
  %t223 = sext i32 0 to i64
  %t224 = load i64, i64* %t219
  %t225 = load i64, i64* %t221
  %t226 = icmp ult i64 %t223, %t225
  br i1 %t226, label %ring_rplace_ok_30, label %ring_rplace_oob_31
ring_rplace_ok_30:
  %t227 = add i64 %t224, %t223
  %t228 = urem i64 %t227, 2
  %t229 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t218, i32 0, i64 %t228
  br label %ring_rplace_end_32
ring_rplace_oob_31:
  store %Bag zeroinitializer, %Bag* %t230
  br label %ring_rplace_end_32
ring_rplace_end_32:
  %t231 = phi %Bag* [ %t229, %ring_rplace_ok_30 ], [ %t230, %ring_rplace_oob_31 ]
  %t232 = getelementptr inbounds %Bag, %Bag* %t231, i32 0, i32 1
  %t233 = load i8*, i8** %t232
  %t234 = load i8*, i8** %t232
  call void @star_rc_retain(i8* %t234)
  call void @star_rc_release(i8* %t233)
  %t235 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 0
  %t236 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 1
  %t237 = load i64, i64* %t236
  %t238 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 2
  %t239 = load i64, i64* %t238
  %t240 = sext i32 0 to i64
  %t241 = load i64, i64* %t236
  %t242 = load i64, i64* %t238
  %t243 = icmp ult i64 %t240, %t242
  br i1 %t243, label %ring_rplace_ok_33, label %ring_rplace_oob_34
ring_rplace_ok_33:
  %t244 = add i64 %t241, %t240
  %t245 = urem i64 %t244, 2
  %t246 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t235, i32 0, i64 %t245
  br label %ring_rplace_end_35
ring_rplace_oob_34:
  store %Bag zeroinitializer, %Bag* %t247
  br label %ring_rplace_end_35
ring_rplace_end_35:
  %t248 = phi %Bag* [ %t246, %ring_rplace_ok_33 ], [ %t247, %ring_rplace_oob_34 ]
  %t249 = getelementptr inbounds %Bag, %Bag* %t248, i32 0, i32 0
  %t250 = load i8*, i8** %t249
  %t251 = icmp eq i8* %t250, null
  br i1 %t251, label %list_read_null_36, label %list_read_real_37
list_read_null_36:
  br label %list_read_end_38
list_read_real_37:
  %t252 = bitcast i8* %t250 to { i32*, i64, i64 }*
  %t253 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t252, i32 0, i32 0
  %t254 = load i32*, i32** %t253
  %t255 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t252, i32 0, i32 1
  %t256 = load i64, i64* %t255
  br label %list_read_end_38
list_read_end_38:
  %t257 = phi i32* [ null, %list_read_null_36 ], [ %t254, %list_read_real_37 ]
  %t258 = phi i64 [ 0, %list_read_null_36 ], [ %t256, %list_read_real_37 ]
  %t259 = trunc i64 %t258 to i32
  %t260 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t260, i8* %t233, i32 %t259)
  %t261 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 0
  %t262 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 1
  %t263 = load i64, i64* %t262
  %t264 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 2
  %t265 = load i64, i64* %t264
  %t266 = sext i32 1 to i64
  %t267 = load i64, i64* %t262
  %t268 = load i64, i64* %t264
  %t269 = icmp ult i64 %t266, %t268
  br i1 %t269, label %ring_rplace_ok_39, label %ring_rplace_oob_40
ring_rplace_ok_39:
  %t270 = add i64 %t267, %t266
  %t271 = urem i64 %t270, 2
  %t272 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t261, i32 0, i64 %t271
  br label %ring_rplace_end_41
ring_rplace_oob_40:
  store %Bag zeroinitializer, %Bag* %t273
  br label %ring_rplace_end_41
ring_rplace_end_41:
  %t274 = phi %Bag* [ %t272, %ring_rplace_ok_39 ], [ %t273, %ring_rplace_oob_40 ]
  %t275 = getelementptr inbounds %Bag, %Bag* %t274, i32 0, i32 1
  %t276 = load i8*, i8** %t275
  %t277 = load i8*, i8** %t275
  call void @star_rc_retain(i8* %t277)
  call void @star_rc_release(i8* %t276)
  %t278 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 0
  %t279 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 1
  %t280 = load i64, i64* %t279
  %t281 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 2
  %t282 = load i64, i64* %t281
  %t283 = sext i32 1 to i64
  %t284 = load i64, i64* %t279
  %t285 = load i64, i64* %t281
  %t286 = icmp ult i64 %t283, %t285
  br i1 %t286, label %ring_rplace_ok_42, label %ring_rplace_oob_43
ring_rplace_ok_42:
  %t287 = add i64 %t284, %t283
  %t288 = urem i64 %t287, 2
  %t289 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t278, i32 0, i64 %t288
  br label %ring_rplace_end_44
ring_rplace_oob_43:
  store %Bag zeroinitializer, %Bag* %t290
  br label %ring_rplace_end_44
ring_rplace_end_44:
  %t291 = phi %Bag* [ %t289, %ring_rplace_ok_42 ], [ %t290, %ring_rplace_oob_43 ]
  %t292 = getelementptr inbounds %Bag, %Bag* %t291, i32 0, i32 0
  %t293 = load i8*, i8** %t292
  %t294 = icmp eq i8* %t293, null
  br i1 %t294, label %list_read_null_45, label %list_read_real_46
list_read_null_45:
  br label %list_read_end_47
list_read_real_46:
  %t295 = bitcast i8* %t293 to { i32*, i64, i64 }*
  %t296 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t295, i32 0, i32 0
  %t297 = load i32*, i32** %t296
  %t298 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t295, i32 0, i32 1
  %t299 = load i64, i64* %t298
  br label %list_read_end_47
list_read_end_47:
  %t300 = phi i32* [ null, %list_read_null_45 ], [ %t297, %list_read_real_46 ]
  %t301 = phi i64 [ 0, %list_read_null_45 ], [ %t299, %list_read_real_46 ]
  %t302 = trunc i64 %t301 to i32
  %t303 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t303, i8* %t276, i32 %t302)
  store i8* null, i8** %t304
  %t305 = load i8*, i8** %t304
  %t306 = icmp eq i8* %t305, null
  br i1 %t306, label %table_cow_alloc_48, label %table_cow_check_49
table_cow_alloc_48:
  %t316 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t317 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t318 = ptrtoint { i64, i64, i32*, i32* }* %t317 to i64
  %t319 = call i8* @star_rc_alloc(i64 %t318, i8* %t316)
  %t320 = bitcast i8* %t319 to { i64, i64, i32*, i32* }*
  %t321 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t320, i32 0, i32 0
  store i64 0, i64* %t321
  %t322 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t320, i32 0, i32 1
  store i64 0, i64* %t322
  %t323 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t320, i32 0, i32 2
  store i32* null, i32** %t323
  %t324 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t320, i32 0, i32 3
  store i32* null, i32** %t324
  store i8* %t319, i8** %t304
  br label %table_cow_done_50
table_cow_check_49:
  %t325 = getelementptr inbounds i8, i8* %t305, i64 -16
  %t326 = bitcast i8* %t325 to i64*
  %t327 = load atomic i64, i64* %t326 seq_cst, align 8
  %t328 = icmp eq i64 %t327, 1
  br i1 %t328, label %table_cow_done_50, label %table_cow_clone_51
table_cow_clone_51:
  %t329 = bitcast i8* %t305 to { i64, i64, i32*, i32* }*
  %t330 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t329, i32 0, i32 0
  %t331 = load i64, i64* %t330
  %t332 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t329, i32 0, i32 1
  %t333 = load i64, i64* %t332
  %t334 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t335 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t336 = ptrtoint { i64, i64, i32*, i32* }* %t335 to i64
  %t337 = call i8* @star_rc_alloc(i64 %t336, i8* %t334)
  %t338 = bitcast i8* %t337 to { i64, i64, i32*, i32* }*
  %t339 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t338, i32 0, i32 0
  store i64 %t331, i64* %t339
  %t340 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t338, i32 0, i32 1
  store i64 %t333, i64* %t340
  %t341 = getelementptr i32, i32* null, i32 1
  %t342 = ptrtoint i32* %t341 to i64
  %t343 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t329, i32 0, i32 2
  %t344 = load i32*, i32** %t343
  %t345 = mul i64 %t333, %t342
  %t346 = call i8* @malloc(i64 %t345)
  %t347 = bitcast i8* %t346 to i32*
  %t348 = icmp sgt i64 %t331, 0
  br i1 %t348, label %table_cow_copy_52, label %table_cow_after_copy_53
table_cow_copy_52:
  %t349 = mul i64 %t331, %t342
  %t350 = bitcast i32* %t344 to i8*
  call i8* @memcpy(i8* %t346, i8* %t350, i64 %t349)
  br label %table_cow_after_copy_53
table_cow_after_copy_53:
  %t351 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t338, i32 0, i32 2
  store i32* %t347, i32** %t351
  %t352 = getelementptr i32, i32* null, i32 1
  %t353 = ptrtoint i32* %t352 to i64
  %t354 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t329, i32 0, i32 3
  %t355 = load i32*, i32** %t354
  %t356 = mul i64 %t333, %t353
  %t357 = call i8* @malloc(i64 %t356)
  %t358 = bitcast i8* %t357 to i32*
  %t359 = icmp sgt i64 %t331, 0
  br i1 %t359, label %table_cow_copy_54, label %table_cow_after_copy_55
table_cow_copy_54:
  %t360 = mul i64 %t331, %t353
  %t361 = bitcast i32* %t355 to i8*
  call i8* @memcpy(i8* %t357, i8* %t361, i64 %t360)
  br label %table_cow_after_copy_55
table_cow_after_copy_55:
  %t362 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t338, i32 0, i32 3
  store i32* %t358, i32** %t362
  call void @star_rc_release(i8* %t305)
  store i8* %t337, i8** %t304
  br label %table_cow_done_50
table_cow_done_50:
  %t363 = load i8*, i8** %t304
  %t364 = bitcast i8* %t363 to { i64, i64, i32*, i32* }*
  %t365 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t364, i32 0, i32 0
  %t366 = load i64, i64* %t365
  %t367 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t364, i32 0, i32 1
  %t368 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t364, i32 0, i32 2
  %t369 = load i32*, i32** %t368
  %t370 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t364, i32 0, i32 3
  %t371 = load i32*, i32** %t370
  %t373 = getelementptr inbounds %Point, %Point* %t372, i32 0, i32 0
  store i32 1, i32* %t373
  %t374 = getelementptr inbounds %Point, %Point* %t372, i32 0, i32 1
  store i32 2, i32* %t374
  %t375 = load %Point, %Point* %t372
  %t376 = load i64, i64* %t367
  %t377 = load i64, i64* %t365
  %t378 = load i32*, i32** %t368
  %t379 = load i32*, i32** %t370
  %t380 = icmp sge i64 %t377, %t376
  br i1 %t380, label %table_push_grow_56, label %table_push_store_57
table_push_grow_56:
  %t381 = mul i64 %t376, 2
  %t382 = icmp sgt i64 %t381, 0
  %t383 = select i1 %t382, i64 %t381, i64 1
  %t384 = getelementptr i32, i32* null, i32 1
  %t385 = ptrtoint i32* %t384 to i64
  %t386 = mul i64 %t383, %t385
  %t387 = call i8* @malloc(i64 %t386)
  %t388 = bitcast i8* %t387 to i32*
  %t389 = icmp sgt i64 %t376, 0
  br i1 %t389, label %table_push_copy_58, label %table_push_after_copy_59
table_push_copy_58:
  %t390 = mul i64 %t377, %t385
  %t391 = bitcast i32* %t378 to i8*
  call i8* @memcpy(i8* %t387, i8* %t391, i64 %t390)
  call void @free(i8* %t391)
  br label %table_push_after_copy_59
table_push_after_copy_59:
  store i32* %t388, i32** %t368
  %t392 = getelementptr i32, i32* null, i32 1
  %t393 = ptrtoint i32* %t392 to i64
  %t394 = mul i64 %t383, %t393
  %t395 = call i8* @malloc(i64 %t394)
  %t396 = bitcast i8* %t395 to i32*
  %t397 = icmp sgt i64 %t376, 0
  br i1 %t397, label %table_push_copy_60, label %table_push_after_copy_61
table_push_copy_60:
  %t398 = mul i64 %t377, %t393
  %t399 = bitcast i32* %t379 to i8*
  call i8* @memcpy(i8* %t395, i8* %t399, i64 %t398)
  call void @free(i8* %t399)
  br label %table_push_after_copy_61
table_push_after_copy_61:
  store i32* %t396, i32** %t370
  store i64 %t383, i64* %t367
  br label %table_push_store_57
table_push_store_57:
  %t400 = load i32*, i32** %t368
  %t401 = extractvalue %Point %t375, 0
  %t402 = getelementptr inbounds i32, i32* %t400, i64 %t377
  store i32 %t401, i32* %t402
  %t403 = load i32*, i32** %t370
  %t404 = extractvalue %Point %t375, 1
  %t405 = getelementptr inbounds i32, i32* %t403, i64 %t377
  store i32 %t404, i32* %t405
  %t406 = add i64 %t377, 1
  store i64 %t406, i64* %t365
  %t407 = load i8*, i8** %t304
  %t408 = icmp eq i8* %t407, null
  br i1 %t408, label %table_cow_alloc_62, label %table_cow_check_63
table_cow_alloc_62:
  %t409 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t410 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t411 = ptrtoint { i64, i64, i32*, i32* }* %t410 to i64
  %t412 = call i8* @star_rc_alloc(i64 %t411, i8* %t409)
  %t413 = bitcast i8* %t412 to { i64, i64, i32*, i32* }*
  %t414 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t413, i32 0, i32 0
  store i64 0, i64* %t414
  %t415 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t413, i32 0, i32 1
  store i64 0, i64* %t415
  %t416 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t413, i32 0, i32 2
  store i32* null, i32** %t416
  %t417 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t413, i32 0, i32 3
  store i32* null, i32** %t417
  store i8* %t412, i8** %t304
  br label %table_cow_done_64
table_cow_check_63:
  %t418 = getelementptr inbounds i8, i8* %t407, i64 -16
  %t419 = bitcast i8* %t418 to i64*
  %t420 = load atomic i64, i64* %t419 seq_cst, align 8
  %t421 = icmp eq i64 %t420, 1
  br i1 %t421, label %table_cow_done_64, label %table_cow_clone_65
table_cow_clone_65:
  %t422 = bitcast i8* %t407 to { i64, i64, i32*, i32* }*
  %t423 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t422, i32 0, i32 0
  %t424 = load i64, i64* %t423
  %t425 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t422, i32 0, i32 1
  %t426 = load i64, i64* %t425
  %t427 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t428 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t429 = ptrtoint { i64, i64, i32*, i32* }* %t428 to i64
  %t430 = call i8* @star_rc_alloc(i64 %t429, i8* %t427)
  %t431 = bitcast i8* %t430 to { i64, i64, i32*, i32* }*
  %t432 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t431, i32 0, i32 0
  store i64 %t424, i64* %t432
  %t433 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t431, i32 0, i32 1
  store i64 %t426, i64* %t433
  %t434 = getelementptr i32, i32* null, i32 1
  %t435 = ptrtoint i32* %t434 to i64
  %t436 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t422, i32 0, i32 2
  %t437 = load i32*, i32** %t436
  %t438 = mul i64 %t426, %t435
  %t439 = call i8* @malloc(i64 %t438)
  %t440 = bitcast i8* %t439 to i32*
  %t441 = icmp sgt i64 %t424, 0
  br i1 %t441, label %table_cow_copy_66, label %table_cow_after_copy_67
table_cow_copy_66:
  %t442 = mul i64 %t424, %t435
  %t443 = bitcast i32* %t437 to i8*
  call i8* @memcpy(i8* %t439, i8* %t443, i64 %t442)
  br label %table_cow_after_copy_67
table_cow_after_copy_67:
  %t444 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t431, i32 0, i32 2
  store i32* %t440, i32** %t444
  %t445 = getelementptr i32, i32* null, i32 1
  %t446 = ptrtoint i32* %t445 to i64
  %t447 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t422, i32 0, i32 3
  %t448 = load i32*, i32** %t447
  %t449 = mul i64 %t426, %t446
  %t450 = call i8* @malloc(i64 %t449)
  %t451 = bitcast i8* %t450 to i32*
  %t452 = icmp sgt i64 %t424, 0
  br i1 %t452, label %table_cow_copy_68, label %table_cow_after_copy_69
table_cow_copy_68:
  %t453 = mul i64 %t424, %t446
  %t454 = bitcast i32* %t448 to i8*
  call i8* @memcpy(i8* %t450, i8* %t454, i64 %t453)
  br label %table_cow_after_copy_69
table_cow_after_copy_69:
  %t455 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t431, i32 0, i32 3
  store i32* %t451, i32** %t455
  call void @star_rc_release(i8* %t407)
  store i8* %t430, i8** %t304
  br label %table_cow_done_64
table_cow_done_64:
  %t456 = load i8*, i8** %t304
  %t457 = bitcast i8* %t456 to { i64, i64, i32*, i32* }*
  %t458 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t457, i32 0, i32 0
  %t459 = load i64, i64* %t458
  %t460 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t457, i32 0, i32 1
  %t461 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t457, i32 0, i32 2
  %t462 = load i32*, i32** %t461
  %t463 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t457, i32 0, i32 3
  %t464 = load i32*, i32** %t463
  %t466 = getelementptr inbounds %Point, %Point* %t465, i32 0, i32 0
  store i32 3, i32* %t466
  %t467 = getelementptr inbounds %Point, %Point* %t465, i32 0, i32 1
  store i32 4, i32* %t467
  %t468 = load %Point, %Point* %t465
  %t469 = load i64, i64* %t460
  %t470 = load i64, i64* %t458
  %t471 = load i32*, i32** %t461
  %t472 = load i32*, i32** %t463
  %t473 = icmp sge i64 %t470, %t469
  br i1 %t473, label %table_push_grow_70, label %table_push_store_71
table_push_grow_70:
  %t474 = mul i64 %t469, 2
  %t475 = icmp sgt i64 %t474, 0
  %t476 = select i1 %t475, i64 %t474, i64 1
  %t477 = getelementptr i32, i32* null, i32 1
  %t478 = ptrtoint i32* %t477 to i64
  %t479 = mul i64 %t476, %t478
  %t480 = call i8* @malloc(i64 %t479)
  %t481 = bitcast i8* %t480 to i32*
  %t482 = icmp sgt i64 %t469, 0
  br i1 %t482, label %table_push_copy_72, label %table_push_after_copy_73
table_push_copy_72:
  %t483 = mul i64 %t470, %t478
  %t484 = bitcast i32* %t471 to i8*
  call i8* @memcpy(i8* %t480, i8* %t484, i64 %t483)
  call void @free(i8* %t484)
  br label %table_push_after_copy_73
table_push_after_copy_73:
  store i32* %t481, i32** %t461
  %t485 = getelementptr i32, i32* null, i32 1
  %t486 = ptrtoint i32* %t485 to i64
  %t487 = mul i64 %t476, %t486
  %t488 = call i8* @malloc(i64 %t487)
  %t489 = bitcast i8* %t488 to i32*
  %t490 = icmp sgt i64 %t469, 0
  br i1 %t490, label %table_push_copy_74, label %table_push_after_copy_75
table_push_copy_74:
  %t491 = mul i64 %t470, %t486
  %t492 = bitcast i32* %t472 to i8*
  call i8* @memcpy(i8* %t488, i8* %t492, i64 %t491)
  call void @free(i8* %t492)
  br label %table_push_after_copy_75
table_push_after_copy_75:
  store i32* %t489, i32** %t463
  store i64 %t476, i64* %t460
  br label %table_push_store_71
table_push_store_71:
  %t493 = load i32*, i32** %t461
  %t494 = extractvalue %Point %t468, 0
  %t495 = getelementptr inbounds i32, i32* %t493, i64 %t470
  store i32 %t494, i32* %t495
  %t496 = load i32*, i32** %t463
  %t497 = extractvalue %Point %t468, 1
  %t498 = getelementptr inbounds i32, i32* %t496, i64 %t470
  store i32 %t497, i32* %t498
  %t499 = add i64 %t470, 1
  store i64 %t499, i64* %t458
  %t501 = load i8*, i8** %t304
  %t502 = load i8*, i8** %t304
  call void @star_rc_retain(i8* %t502)
  store i8* %t501, i8** %t500
  %t503 = load i8*, i8** %t500
  %t504 = icmp eq i8* %t503, null
  br i1 %t504, label %table_cow_alloc_76, label %table_cow_check_77
table_cow_alloc_76:
  %t505 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t506 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t507 = ptrtoint { i64, i64, i32*, i32* }* %t506 to i64
  %t508 = call i8* @star_rc_alloc(i64 %t507, i8* %t505)
  %t509 = bitcast i8* %t508 to { i64, i64, i32*, i32* }*
  %t510 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t509, i32 0, i32 0
  store i64 0, i64* %t510
  %t511 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t509, i32 0, i32 1
  store i64 0, i64* %t511
  %t512 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t509, i32 0, i32 2
  store i32* null, i32** %t512
  %t513 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t509, i32 0, i32 3
  store i32* null, i32** %t513
  store i8* %t508, i8** %t500
  br label %table_cow_done_78
table_cow_check_77:
  %t514 = getelementptr inbounds i8, i8* %t503, i64 -16
  %t515 = bitcast i8* %t514 to i64*
  %t516 = load atomic i64, i64* %t515 seq_cst, align 8
  %t517 = icmp eq i64 %t516, 1
  br i1 %t517, label %table_cow_done_78, label %table_cow_clone_79
table_cow_clone_79:
  %t518 = bitcast i8* %t503 to { i64, i64, i32*, i32* }*
  %t519 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t518, i32 0, i32 0
  %t520 = load i64, i64* %t519
  %t521 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t518, i32 0, i32 1
  %t522 = load i64, i64* %t521
  %t523 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t524 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t525 = ptrtoint { i64, i64, i32*, i32* }* %t524 to i64
  %t526 = call i8* @star_rc_alloc(i64 %t525, i8* %t523)
  %t527 = bitcast i8* %t526 to { i64, i64, i32*, i32* }*
  %t528 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t527, i32 0, i32 0
  store i64 %t520, i64* %t528
  %t529 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t527, i32 0, i32 1
  store i64 %t522, i64* %t529
  %t530 = getelementptr i32, i32* null, i32 1
  %t531 = ptrtoint i32* %t530 to i64
  %t532 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t518, i32 0, i32 2
  %t533 = load i32*, i32** %t532
  %t534 = mul i64 %t522, %t531
  %t535 = call i8* @malloc(i64 %t534)
  %t536 = bitcast i8* %t535 to i32*
  %t537 = icmp sgt i64 %t520, 0
  br i1 %t537, label %table_cow_copy_80, label %table_cow_after_copy_81
table_cow_copy_80:
  %t538 = mul i64 %t520, %t531
  %t539 = bitcast i32* %t533 to i8*
  call i8* @memcpy(i8* %t535, i8* %t539, i64 %t538)
  br label %table_cow_after_copy_81
table_cow_after_copy_81:
  %t540 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t527, i32 0, i32 2
  store i32* %t536, i32** %t540
  %t541 = getelementptr i32, i32* null, i32 1
  %t542 = ptrtoint i32* %t541 to i64
  %t543 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t518, i32 0, i32 3
  %t544 = load i32*, i32** %t543
  %t545 = mul i64 %t522, %t542
  %t546 = call i8* @malloc(i64 %t545)
  %t547 = bitcast i8* %t546 to i32*
  %t548 = icmp sgt i64 %t520, 0
  br i1 %t548, label %table_cow_copy_82, label %table_cow_after_copy_83
table_cow_copy_82:
  %t549 = mul i64 %t520, %t542
  %t550 = bitcast i32* %t544 to i8*
  call i8* @memcpy(i8* %t546, i8* %t550, i64 %t549)
  br label %table_cow_after_copy_83
table_cow_after_copy_83:
  %t551 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t527, i32 0, i32 3
  store i32* %t547, i32** %t551
  call void @star_rc_release(i8* %t503)
  store i8* %t526, i8** %t500
  br label %table_cow_done_78
table_cow_done_78:
  %t552 = load i8*, i8** %t500
  %t553 = bitcast i8* %t552 to { i64, i64, i32*, i32* }*
  %t554 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t553, i32 0, i32 0
  %t555 = load i64, i64* %t554
  %t556 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t553, i32 0, i32 1
  %t557 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t553, i32 0, i32 2
  %t558 = load i32*, i32** %t557
  %t559 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t553, i32 0, i32 3
  %t560 = load i32*, i32** %t559
  %t562 = getelementptr inbounds %Point, %Point* %t561, i32 0, i32 0
  store i32 5, i32* %t562
  %t563 = getelementptr inbounds %Point, %Point* %t561, i32 0, i32 1
  store i32 6, i32* %t563
  %t564 = load %Point, %Point* %t561
  %t565 = load i64, i64* %t556
  %t566 = load i64, i64* %t554
  %t567 = load i32*, i32** %t557
  %t568 = load i32*, i32** %t559
  %t569 = icmp sge i64 %t566, %t565
  br i1 %t569, label %table_push_grow_84, label %table_push_store_85
table_push_grow_84:
  %t570 = mul i64 %t565, 2
  %t571 = icmp sgt i64 %t570, 0
  %t572 = select i1 %t571, i64 %t570, i64 1
  %t573 = getelementptr i32, i32* null, i32 1
  %t574 = ptrtoint i32* %t573 to i64
  %t575 = mul i64 %t572, %t574
  %t576 = call i8* @malloc(i64 %t575)
  %t577 = bitcast i8* %t576 to i32*
  %t578 = icmp sgt i64 %t565, 0
  br i1 %t578, label %table_push_copy_86, label %table_push_after_copy_87
table_push_copy_86:
  %t579 = mul i64 %t566, %t574
  %t580 = bitcast i32* %t567 to i8*
  call i8* @memcpy(i8* %t576, i8* %t580, i64 %t579)
  call void @free(i8* %t580)
  br label %table_push_after_copy_87
table_push_after_copy_87:
  store i32* %t577, i32** %t557
  %t581 = getelementptr i32, i32* null, i32 1
  %t582 = ptrtoint i32* %t581 to i64
  %t583 = mul i64 %t572, %t582
  %t584 = call i8* @malloc(i64 %t583)
  %t585 = bitcast i8* %t584 to i32*
  %t586 = icmp sgt i64 %t565, 0
  br i1 %t586, label %table_push_copy_88, label %table_push_after_copy_89
table_push_copy_88:
  %t587 = mul i64 %t566, %t582
  %t588 = bitcast i32* %t568 to i8*
  call i8* @memcpy(i8* %t584, i8* %t588, i64 %t587)
  call void @free(i8* %t588)
  br label %table_push_after_copy_89
table_push_after_copy_89:
  store i32* %t585, i32** %t559
  store i64 %t572, i64* %t556
  br label %table_push_store_85
table_push_store_85:
  %t589 = load i32*, i32** %t557
  %t590 = extractvalue %Point %t564, 0
  %t591 = getelementptr inbounds i32, i32* %t589, i64 %t566
  store i32 %t590, i32* %t591
  %t592 = load i32*, i32** %t559
  %t593 = extractvalue %Point %t564, 1
  %t594 = getelementptr inbounds i32, i32* %t592, i64 %t566
  store i32 %t593, i32* %t594
  %t595 = add i64 %t566, 1
  store i64 %t595, i64* %t554
  %t596 = load i8*, i8** %t304
  %t597 = icmp eq i8* %t596, null
  br i1 %t597, label %table_read_null_90, label %table_read_real_91
table_read_null_90:
  br label %table_read_end_92
table_read_real_91:
  %t598 = bitcast i8* %t596 to { i64, i64, i32*, i32* }*
  %t599 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t598, i32 0, i32 0
  %t600 = load i64, i64* %t599
  %t601 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t598, i32 0, i32 2
  %t602 = load i32*, i32** %t601
  %t603 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t598, i32 0, i32 3
  %t604 = load i32*, i32** %t603
  br label %table_read_end_92
table_read_end_92:
  %t605 = phi i64 [ 0, %table_read_null_90 ], [ %t600, %table_read_real_91 ]
  %t606 = phi i32* [ null, %table_read_null_90 ], [ %t602, %table_read_real_91 ]
  %t607 = phi i32* [ null, %table_read_null_90 ], [ %t604, %table_read_real_91 ]
  %t608 = trunc i64 %t605 to i32
  %t609 = load i8*, i8** %t500
  %t610 = icmp eq i8* %t609, null
  br i1 %t610, label %table_read_null_93, label %table_read_real_94
table_read_null_93:
  br label %table_read_end_95
table_read_real_94:
  %t611 = bitcast i8* %t609 to { i64, i64, i32*, i32* }*
  %t612 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t611, i32 0, i32 0
  %t613 = load i64, i64* %t612
  %t614 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t611, i32 0, i32 2
  %t615 = load i32*, i32** %t614
  %t616 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t611, i32 0, i32 3
  %t617 = load i32*, i32** %t616
  br label %table_read_end_95
table_read_end_95:
  %t618 = phi i64 [ 0, %table_read_null_93 ], [ %t613, %table_read_real_94 ]
  %t619 = phi i32* [ null, %table_read_null_93 ], [ %t615, %table_read_real_94 ]
  %t620 = phi i32* [ null, %table_read_null_93 ], [ %t617, %table_read_real_94 ]
  %t621 = trunc i64 %t618 to i32
  %t622 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t622, i32 %t608, i32 %t621)
  %t623 = sext i32 1 to i64
  %t624 = load i8*, i8** %t304
  %t625 = icmp eq i8* %t624, null
  br i1 %t625, label %table_read_null_96, label %table_read_real_97
table_read_null_96:
  br label %table_read_end_98
table_read_real_97:
  %t626 = bitcast i8* %t624 to { i64, i64, i32*, i32* }*
  %t627 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t626, i32 0, i32 0
  %t628 = load i64, i64* %t627
  %t629 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t626, i32 0, i32 2
  %t630 = load i32*, i32** %t629
  %t631 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t626, i32 0, i32 3
  %t632 = load i32*, i32** %t631
  br label %table_read_end_98
table_read_end_98:
  %t633 = phi i64 [ 0, %table_read_null_96 ], [ %t628, %table_read_real_97 ]
  %t634 = phi i32* [ null, %table_read_null_96 ], [ %t630, %table_read_real_97 ]
  %t635 = phi i32* [ null, %table_read_null_96 ], [ %t632, %table_read_real_97 ]
  %t637 = icmp ult i64 %t623, %t633
  br i1 %t637, label %table_idx_ok_99, label %table_idx_oob_100
table_idx_ok_99:
  %t638 = getelementptr inbounds i32, i32* %t634, i64 %t623
  %t639 = load i32, i32* %t638
  %t640 = getelementptr inbounds %Point, %Point* %t636, i32 0, i32 0
  store i32 %t639, i32* %t640
  %t641 = getelementptr inbounds i32, i32* %t635, i64 %t623
  %t642 = load i32, i32* %t641
  %t643 = getelementptr inbounds %Point, %Point* %t636, i32 0, i32 1
  store i32 %t642, i32* %t643
  br label %table_idx_end_101
table_idx_oob_100:
  %t644 = getelementptr inbounds %Point, %Point* %t636, i32 0, i32 0
  store i32 0, i32* %t644
  %t645 = getelementptr inbounds %Point, %Point* %t636, i32 0, i32 1
  store i32 0, i32* %t645
  br label %table_idx_end_101
table_idx_end_101:
  %t646 = load %Point, %Point* %t636
  store %Point %t646, %Point* %t647
  %t648 = getelementptr inbounds %Point, %Point* %t647, i32 0, i32 0
  %t649 = load i32, i32* %t648
  %t650 = sext i32 1 to i64
  %t651 = load i8*, i8** %t304
  %t652 = icmp eq i8* %t651, null
  br i1 %t652, label %table_read_null_102, label %table_read_real_103
table_read_null_102:
  br label %table_read_end_104
table_read_real_103:
  %t653 = bitcast i8* %t651 to { i64, i64, i32*, i32* }*
  %t654 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t653, i32 0, i32 0
  %t655 = load i64, i64* %t654
  %t656 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t653, i32 0, i32 2
  %t657 = load i32*, i32** %t656
  %t658 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t653, i32 0, i32 3
  %t659 = load i32*, i32** %t658
  br label %table_read_end_104
table_read_end_104:
  %t660 = phi i64 [ 0, %table_read_null_102 ], [ %t655, %table_read_real_103 ]
  %t661 = phi i32* [ null, %table_read_null_102 ], [ %t657, %table_read_real_103 ]
  %t662 = phi i32* [ null, %table_read_null_102 ], [ %t659, %table_read_real_103 ]
  %t664 = icmp ult i64 %t650, %t660
  br i1 %t664, label %table_idx_ok_105, label %table_idx_oob_106
table_idx_ok_105:
  %t665 = getelementptr inbounds i32, i32* %t661, i64 %t650
  %t666 = load i32, i32* %t665
  %t667 = getelementptr inbounds %Point, %Point* %t663, i32 0, i32 0
  store i32 %t666, i32* %t667
  %t668 = getelementptr inbounds i32, i32* %t662, i64 %t650
  %t669 = load i32, i32* %t668
  %t670 = getelementptr inbounds %Point, %Point* %t663, i32 0, i32 1
  store i32 %t669, i32* %t670
  br label %table_idx_end_107
table_idx_oob_106:
  %t671 = getelementptr inbounds %Point, %Point* %t663, i32 0, i32 0
  store i32 0, i32* %t671
  %t672 = getelementptr inbounds %Point, %Point* %t663, i32 0, i32 1
  store i32 0, i32* %t672
  br label %table_idx_end_107
table_idx_end_107:
  %t673 = load %Point, %Point* %t663
  store %Point %t673, %Point* %t674
  %t675 = getelementptr inbounds %Point, %Point* %t674, i32 0, i32 1
  %t676 = load i32, i32* %t675
  %t677 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t677, i32 %t649, i32 %t676)
  %t678 = sub i32 0, 1
  %t679 = sext i32 %t678 to i64
  %t680 = load i8*, i8** %t304
  %t681 = icmp eq i8* %t680, null
  br i1 %t681, label %table_read_null_108, label %table_read_real_109
table_read_null_108:
  br label %table_read_end_110
table_read_real_109:
  %t682 = bitcast i8* %t680 to { i64, i64, i32*, i32* }*
  %t683 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t682, i32 0, i32 0
  %t684 = load i64, i64* %t683
  %t685 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t682, i32 0, i32 2
  %t686 = load i32*, i32** %t685
  %t687 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t682, i32 0, i32 3
  %t688 = load i32*, i32** %t687
  br label %table_read_end_110
table_read_end_110:
  %t689 = phi i64 [ 0, %table_read_null_108 ], [ %t684, %table_read_real_109 ]
  %t690 = phi i32* [ null, %table_read_null_108 ], [ %t686, %table_read_real_109 ]
  %t691 = phi i32* [ null, %table_read_null_108 ], [ %t688, %table_read_real_109 ]
  %t693 = icmp ult i64 %t679, %t689
  br i1 %t693, label %table_idx_ok_111, label %table_idx_oob_112
table_idx_ok_111:
  %t694 = getelementptr inbounds i32, i32* %t690, i64 %t679
  %t695 = load i32, i32* %t694
  %t696 = getelementptr inbounds %Point, %Point* %t692, i32 0, i32 0
  store i32 %t695, i32* %t696
  %t697 = getelementptr inbounds i32, i32* %t691, i64 %t679
  %t698 = load i32, i32* %t697
  %t699 = getelementptr inbounds %Point, %Point* %t692, i32 0, i32 1
  store i32 %t698, i32* %t699
  br label %table_idx_end_113
table_idx_oob_112:
  %t700 = getelementptr inbounds %Point, %Point* %t692, i32 0, i32 0
  store i32 0, i32* %t700
  %t701 = getelementptr inbounds %Point, %Point* %t692, i32 0, i32 1
  store i32 0, i32* %t701
  br label %table_idx_end_113
table_idx_end_113:
  %t702 = load %Point, %Point* %t692
  store %Point %t702, %Point* %t703
  %t704 = getelementptr inbounds %Point, %Point* %t703, i32 0, i32 0
  %t705 = load i32, i32* %t704
  %t706 = sub i32 0, 1
  %t707 = sext i32 %t706 to i64
  %t708 = load i8*, i8** %t304
  %t709 = icmp eq i8* %t708, null
  br i1 %t709, label %table_read_null_114, label %table_read_real_115
table_read_null_114:
  br label %table_read_end_116
table_read_real_115:
  %t710 = bitcast i8* %t708 to { i64, i64, i32*, i32* }*
  %t711 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t710, i32 0, i32 0
  %t712 = load i64, i64* %t711
  %t713 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t710, i32 0, i32 2
  %t714 = load i32*, i32** %t713
  %t715 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t710, i32 0, i32 3
  %t716 = load i32*, i32** %t715
  br label %table_read_end_116
table_read_end_116:
  %t717 = phi i64 [ 0, %table_read_null_114 ], [ %t712, %table_read_real_115 ]
  %t718 = phi i32* [ null, %table_read_null_114 ], [ %t714, %table_read_real_115 ]
  %t719 = phi i32* [ null, %table_read_null_114 ], [ %t716, %table_read_real_115 ]
  %t721 = icmp ult i64 %t707, %t717
  br i1 %t721, label %table_idx_ok_117, label %table_idx_oob_118
table_idx_ok_117:
  %t722 = getelementptr inbounds i32, i32* %t718, i64 %t707
  %t723 = load i32, i32* %t722
  %t724 = getelementptr inbounds %Point, %Point* %t720, i32 0, i32 0
  store i32 %t723, i32* %t724
  %t725 = getelementptr inbounds i32, i32* %t719, i64 %t707
  %t726 = load i32, i32* %t725
  %t727 = getelementptr inbounds %Point, %Point* %t720, i32 0, i32 1
  store i32 %t726, i32* %t727
  br label %table_idx_end_119
table_idx_oob_118:
  %t728 = getelementptr inbounds %Point, %Point* %t720, i32 0, i32 0
  store i32 0, i32* %t728
  %t729 = getelementptr inbounds %Point, %Point* %t720, i32 0, i32 1
  store i32 0, i32* %t729
  br label %table_idx_end_119
table_idx_end_119:
  %t730 = load %Point, %Point* %t720
  store %Point %t730, %Point* %t731
  %t732 = getelementptr inbounds %Point, %Point* %t731, i32 0, i32 1
  %t733 = load i32, i32* %t732
  %t734 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t734, i32 %t705, i32 %t733)
  store i8* null, i8** %t735
  %t736 = load i8*, i8** %t735
  %t737 = icmp eq i8* %t736, null
  br i1 %t737, label %table_cow_alloc_120, label %table_cow_check_121
table_cow_alloc_120:
  %t759 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t760 = getelementptr { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* null, i32 1
  %t761 = ptrtoint { i64, i64, i8**, i8** }* %t760 to i64
  %t762 = call i8* @star_rc_alloc(i64 %t761, i8* %t759)
  %t763 = bitcast i8* %t762 to { i64, i64, i8**, i8** }*
  %t764 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t763, i32 0, i32 0
  store i64 0, i64* %t764
  %t765 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t763, i32 0, i32 1
  store i64 0, i64* %t765
  %t766 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t763, i32 0, i32 2
  store i8** null, i8*** %t766
  %t767 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t763, i32 0, i32 3
  store i8** null, i8*** %t767
  store i8* %t762, i8** %t735
  br label %table_cow_done_122
table_cow_check_121:
  %t768 = getelementptr inbounds i8, i8* %t736, i64 -16
  %t769 = bitcast i8* %t768 to i64*
  %t770 = load atomic i64, i64* %t769 seq_cst, align 8
  %t771 = icmp eq i64 %t770, 1
  br i1 %t771, label %table_cow_done_122, label %table_cow_clone_129
table_cow_clone_129:
  %t772 = bitcast i8* %t736 to { i64, i64, i8**, i8** }*
  %t773 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t772, i32 0, i32 0
  %t774 = load i64, i64* %t773
  %t775 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t772, i32 0, i32 1
  %t776 = load i64, i64* %t775
  %t777 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t778 = getelementptr { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* null, i32 1
  %t779 = ptrtoint { i64, i64, i8**, i8** }* %t778 to i64
  %t780 = call i8* @star_rc_alloc(i64 %t779, i8* %t777)
  %t781 = bitcast i8* %t780 to { i64, i64, i8**, i8** }*
  %t782 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t781, i32 0, i32 0
  store i64 %t774, i64* %t782
  %t783 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t781, i32 0, i32 1
  store i64 %t776, i64* %t783
  %t784 = getelementptr i8*, i8** null, i32 1
  %t785 = ptrtoint i8** %t784 to i64
  %t786 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t772, i32 0, i32 2
  %t787 = load i8**, i8*** %t786
  %t788 = mul i64 %t776, %t785
  %t789 = call i8* @malloc(i64 %t788)
  %t790 = bitcast i8* %t789 to i8**
  %t791 = icmp sgt i64 %t774, 0
  br i1 %t791, label %table_cow_copy_130, label %table_cow_after_copy_131
table_cow_copy_130:
  %t792 = mul i64 %t774, %t785
  %t793 = bitcast i8** %t787 to i8*
  call i8* @memcpy(i8* %t789, i8* %t793, i64 %t792)
  store i64 0, i64* %t794
  br label %table_cow_retain_cond_132
table_cow_retain_cond_132:
  %t795 = load i64, i64* %t794
  %t796 = icmp slt i64 %t795, %t774
  br i1 %t796, label %table_cow_retain_body_133, label %table_cow_retain_end_134
table_cow_retain_body_133:
  %t797 = getelementptr inbounds i8*, i8** %t790, i64 %t795
  %t798 = load i8*, i8** %t797
  call void @star_rc_retain(i8* %t798)
  %t799 = add i64 %t795, 1
  store i64 %t799, i64* %t794
  br label %table_cow_retain_cond_132
table_cow_retain_end_134:
  br label %table_cow_after_copy_131
table_cow_after_copy_131:
  %t800 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t781, i32 0, i32 2
  store i8** %t790, i8*** %t800
  %t801 = getelementptr i8*, i8** null, i32 1
  %t802 = ptrtoint i8** %t801 to i64
  %t803 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t772, i32 0, i32 3
  %t804 = load i8**, i8*** %t803
  %t805 = mul i64 %t776, %t802
  %t806 = call i8* @malloc(i64 %t805)
  %t807 = bitcast i8* %t806 to i8**
  %t808 = icmp sgt i64 %t774, 0
  br i1 %t808, label %table_cow_copy_135, label %table_cow_after_copy_136
table_cow_copy_135:
  %t809 = mul i64 %t774, %t802
  %t810 = bitcast i8** %t804 to i8*
  call i8* @memcpy(i8* %t806, i8* %t810, i64 %t809)
  store i64 0, i64* %t811
  br label %table_cow_retain_cond_137
table_cow_retain_cond_137:
  %t812 = load i64, i64* %t811
  %t813 = icmp slt i64 %t812, %t774
  br i1 %t813, label %table_cow_retain_body_138, label %table_cow_retain_end_139
table_cow_retain_body_138:
  %t814 = getelementptr inbounds i8*, i8** %t807, i64 %t812
  %t815 = load i8*, i8** %t814
  call void @star_rc_retain(i8* %t815)
  %t816 = add i64 %t812, 1
  store i64 %t816, i64* %t811
  br label %table_cow_retain_cond_137
table_cow_retain_end_139:
  br label %table_cow_after_copy_136
table_cow_after_copy_136:
  %t817 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t781, i32 0, i32 3
  store i8** %t807, i8*** %t817
  call void @star_rc_release(i8* %t736)
  store i8* %t780, i8** %t735
  br label %table_cow_done_122
table_cow_done_122:
  %t818 = load i8*, i8** %t735
  %t819 = bitcast i8* %t818 to { i64, i64, i8**, i8** }*
  %t820 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t819, i32 0, i32 0
  %t821 = load i64, i64* %t820
  %t822 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t819, i32 0, i32 1
  %t823 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t819, i32 0, i32 2
  %t824 = load i8**, i8*** %t823
  %t825 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t819, i32 0, i32 3
  %t826 = load i8**, i8*** %t825
  %t828 = getelementptr i32, i32* null, i32 1
  %t829 = ptrtoint i32* %t828 to i64
  %t830 = mul i64 %t829, 3
  %t831 = call i8* @malloc(i64 %t830)
  %t832 = bitcast i8* %t831 to i32*
  %t833 = getelementptr inbounds i32, i32* %t832, i64 0
  store i32 7, i32* %t833
  %t834 = getelementptr inbounds i32, i32* %t832, i64 1
  store i32 8, i32* %t834
  %t835 = getelementptr inbounds i32, i32* %t832, i64 2
  store i32 9, i32* %t835
  %t836 = bitcast void (i8*)* @list_release_i32 to i8*
  %t837 = call i8* @star_rc_alloc(i64 24, i8* %t836)
  %t838 = bitcast i8* %t837 to { i32*, i64, i64 }*
  %t839 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t838, i32 0, i32 0
  store i32* %t832, i32** %t839
  %t840 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t838, i32 0, i32 1
  store i64 3, i64* %t840
  %t841 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t838, i32 0, i32 2
  store i64 3, i64* %t841
  %t842 = getelementptr inbounds %Bag, %Bag* %t827, i32 0, i32 0
  store i8* %t837, i8** %t842
  %t843 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t844 = getelementptr inbounds %Bag, %Bag* %t827, i32 0, i32 1
  store i8* %t843, i8** %t844
  %t845 = load %Bag, %Bag* %t827
  %t846 = load i64, i64* %t822
  %t847 = load i64, i64* %t820
  %t848 = load i8**, i8*** %t823
  %t849 = load i8**, i8*** %t825
  %t850 = icmp sge i64 %t847, %t846
  br i1 %t850, label %table_push_grow_140, label %table_push_store_141
table_push_grow_140:
  %t851 = mul i64 %t846, 2
  %t852 = icmp sgt i64 %t851, 0
  %t853 = select i1 %t852, i64 %t851, i64 1
  %t854 = getelementptr i8*, i8** null, i32 1
  %t855 = ptrtoint i8** %t854 to i64
  %t856 = mul i64 %t853, %t855
  %t857 = call i8* @malloc(i64 %t856)
  %t858 = bitcast i8* %t857 to i8**
  %t859 = icmp sgt i64 %t846, 0
  br i1 %t859, label %table_push_copy_142, label %table_push_after_copy_143
table_push_copy_142:
  %t860 = mul i64 %t847, %t855
  %t861 = bitcast i8** %t848 to i8*
  call i8* @memcpy(i8* %t857, i8* %t861, i64 %t860)
  call void @free(i8* %t861)
  br label %table_push_after_copy_143
table_push_after_copy_143:
  store i8** %t858, i8*** %t823
  %t862 = getelementptr i8*, i8** null, i32 1
  %t863 = ptrtoint i8** %t862 to i64
  %t864 = mul i64 %t853, %t863
  %t865 = call i8* @malloc(i64 %t864)
  %t866 = bitcast i8* %t865 to i8**
  %t867 = icmp sgt i64 %t846, 0
  br i1 %t867, label %table_push_copy_144, label %table_push_after_copy_145
table_push_copy_144:
  %t868 = mul i64 %t847, %t863
  %t869 = bitcast i8** %t849 to i8*
  call i8* @memcpy(i8* %t865, i8* %t869, i64 %t868)
  call void @free(i8* %t869)
  br label %table_push_after_copy_145
table_push_after_copy_145:
  store i8** %t866, i8*** %t825
  store i64 %t853, i64* %t822
  br label %table_push_store_141
table_push_store_141:
  %t870 = load i8**, i8*** %t823
  %t871 = extractvalue %Bag %t845, 0
  %t872 = getelementptr inbounds i8*, i8** %t870, i64 %t847
  store i8* %t871, i8** %t872
  %t873 = load i8**, i8*** %t825
  %t874 = extractvalue %Bag %t845, 1
  %t875 = getelementptr inbounds i8*, i8** %t873, i64 %t847
  store i8* %t874, i8** %t875
  %t876 = add i64 %t847, 1
  store i64 %t876, i64* %t820
  %t877 = load i8*, i8** %t735
  %t878 = icmp eq i8* %t877, null
  br i1 %t878, label %table_cow_alloc_146, label %table_cow_check_147
table_cow_alloc_146:
  %t879 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t880 = getelementptr { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* null, i32 1
  %t881 = ptrtoint { i64, i64, i8**, i8** }* %t880 to i64
  %t882 = call i8* @star_rc_alloc(i64 %t881, i8* %t879)
  %t883 = bitcast i8* %t882 to { i64, i64, i8**, i8** }*
  %t884 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t883, i32 0, i32 0
  store i64 0, i64* %t884
  %t885 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t883, i32 0, i32 1
  store i64 0, i64* %t885
  %t886 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t883, i32 0, i32 2
  store i8** null, i8*** %t886
  %t887 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t883, i32 0, i32 3
  store i8** null, i8*** %t887
  store i8* %t882, i8** %t735
  br label %table_cow_done_148
table_cow_check_147:
  %t888 = getelementptr inbounds i8, i8* %t877, i64 -16
  %t889 = bitcast i8* %t888 to i64*
  %t890 = load atomic i64, i64* %t889 seq_cst, align 8
  %t891 = icmp eq i64 %t890, 1
  br i1 %t891, label %table_cow_done_148, label %table_cow_clone_149
table_cow_clone_149:
  %t892 = bitcast i8* %t877 to { i64, i64, i8**, i8** }*
  %t893 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t892, i32 0, i32 0
  %t894 = load i64, i64* %t893
  %t895 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t892, i32 0, i32 1
  %t896 = load i64, i64* %t895
  %t897 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t898 = getelementptr { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* null, i32 1
  %t899 = ptrtoint { i64, i64, i8**, i8** }* %t898 to i64
  %t900 = call i8* @star_rc_alloc(i64 %t899, i8* %t897)
  %t901 = bitcast i8* %t900 to { i64, i64, i8**, i8** }*
  %t902 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t901, i32 0, i32 0
  store i64 %t894, i64* %t902
  %t903 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t901, i32 0, i32 1
  store i64 %t896, i64* %t903
  %t904 = getelementptr i8*, i8** null, i32 1
  %t905 = ptrtoint i8** %t904 to i64
  %t906 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t892, i32 0, i32 2
  %t907 = load i8**, i8*** %t906
  %t908 = mul i64 %t896, %t905
  %t909 = call i8* @malloc(i64 %t908)
  %t910 = bitcast i8* %t909 to i8**
  %t911 = icmp sgt i64 %t894, 0
  br i1 %t911, label %table_cow_copy_150, label %table_cow_after_copy_151
table_cow_copy_150:
  %t912 = mul i64 %t894, %t905
  %t913 = bitcast i8** %t907 to i8*
  call i8* @memcpy(i8* %t909, i8* %t913, i64 %t912)
  store i64 0, i64* %t914
  br label %table_cow_retain_cond_152
table_cow_retain_cond_152:
  %t915 = load i64, i64* %t914
  %t916 = icmp slt i64 %t915, %t894
  br i1 %t916, label %table_cow_retain_body_153, label %table_cow_retain_end_154
table_cow_retain_body_153:
  %t917 = getelementptr inbounds i8*, i8** %t910, i64 %t915
  %t918 = load i8*, i8** %t917
  call void @star_rc_retain(i8* %t918)
  %t919 = add i64 %t915, 1
  store i64 %t919, i64* %t914
  br label %table_cow_retain_cond_152
table_cow_retain_end_154:
  br label %table_cow_after_copy_151
table_cow_after_copy_151:
  %t920 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t901, i32 0, i32 2
  store i8** %t910, i8*** %t920
  %t921 = getelementptr i8*, i8** null, i32 1
  %t922 = ptrtoint i8** %t921 to i64
  %t923 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t892, i32 0, i32 3
  %t924 = load i8**, i8*** %t923
  %t925 = mul i64 %t896, %t922
  %t926 = call i8* @malloc(i64 %t925)
  %t927 = bitcast i8* %t926 to i8**
  %t928 = icmp sgt i64 %t894, 0
  br i1 %t928, label %table_cow_copy_155, label %table_cow_after_copy_156
table_cow_copy_155:
  %t929 = mul i64 %t894, %t922
  %t930 = bitcast i8** %t924 to i8*
  call i8* @memcpy(i8* %t926, i8* %t930, i64 %t929)
  store i64 0, i64* %t931
  br label %table_cow_retain_cond_157
table_cow_retain_cond_157:
  %t932 = load i64, i64* %t931
  %t933 = icmp slt i64 %t932, %t894
  br i1 %t933, label %table_cow_retain_body_158, label %table_cow_retain_end_159
table_cow_retain_body_158:
  %t934 = getelementptr inbounds i8*, i8** %t927, i64 %t932
  %t935 = load i8*, i8** %t934
  call void @star_rc_retain(i8* %t935)
  %t936 = add i64 %t932, 1
  store i64 %t936, i64* %t931
  br label %table_cow_retain_cond_157
table_cow_retain_end_159:
  br label %table_cow_after_copy_156
table_cow_after_copy_156:
  %t937 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t901, i32 0, i32 3
  store i8** %t927, i8*** %t937
  call void @star_rc_release(i8* %t877)
  store i8* %t900, i8** %t735
  br label %table_cow_done_148
table_cow_done_148:
  %t938 = load i8*, i8** %t735
  %t939 = bitcast i8* %t938 to { i64, i64, i8**, i8** }*
  %t940 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t939, i32 0, i32 0
  %t941 = load i64, i64* %t940
  %t942 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t939, i32 0, i32 1
  %t943 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t939, i32 0, i32 2
  %t944 = load i8**, i8*** %t943
  %t945 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t939, i32 0, i32 3
  %t946 = load i8**, i8*** %t945
  %t948 = getelementptr inbounds %Bag, %Bag* %t947, i32 0, i32 0
  store i8* null, i8** %t948
  %t949 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t950 = getelementptr inbounds %Bag, %Bag* %t947, i32 0, i32 1
  store i8* %t949, i8** %t950
  %t951 = load %Bag, %Bag* %t947
  %t952 = load i64, i64* %t942
  %t953 = load i64, i64* %t940
  %t954 = load i8**, i8*** %t943
  %t955 = load i8**, i8*** %t945
  %t956 = icmp sge i64 %t953, %t952
  br i1 %t956, label %table_push_grow_160, label %table_push_store_161
table_push_grow_160:
  %t957 = mul i64 %t952, 2
  %t958 = icmp sgt i64 %t957, 0
  %t959 = select i1 %t958, i64 %t957, i64 1
  %t960 = getelementptr i8*, i8** null, i32 1
  %t961 = ptrtoint i8** %t960 to i64
  %t962 = mul i64 %t959, %t961
  %t963 = call i8* @malloc(i64 %t962)
  %t964 = bitcast i8* %t963 to i8**
  %t965 = icmp sgt i64 %t952, 0
  br i1 %t965, label %table_push_copy_162, label %table_push_after_copy_163
table_push_copy_162:
  %t966 = mul i64 %t953, %t961
  %t967 = bitcast i8** %t954 to i8*
  call i8* @memcpy(i8* %t963, i8* %t967, i64 %t966)
  call void @free(i8* %t967)
  br label %table_push_after_copy_163
table_push_after_copy_163:
  store i8** %t964, i8*** %t943
  %t968 = getelementptr i8*, i8** null, i32 1
  %t969 = ptrtoint i8** %t968 to i64
  %t970 = mul i64 %t959, %t969
  %t971 = call i8* @malloc(i64 %t970)
  %t972 = bitcast i8* %t971 to i8**
  %t973 = icmp sgt i64 %t952, 0
  br i1 %t973, label %table_push_copy_164, label %table_push_after_copy_165
table_push_copy_164:
  %t974 = mul i64 %t953, %t969
  %t975 = bitcast i8** %t955 to i8*
  call i8* @memcpy(i8* %t971, i8* %t975, i64 %t974)
  call void @free(i8* %t975)
  br label %table_push_after_copy_165
table_push_after_copy_165:
  store i8** %t972, i8*** %t945
  store i64 %t959, i64* %t942
  br label %table_push_store_161
table_push_store_161:
  %t976 = load i8**, i8*** %t943
  %t977 = extractvalue %Bag %t951, 0
  %t978 = getelementptr inbounds i8*, i8** %t976, i64 %t953
  store i8* %t977, i8** %t978
  %t979 = load i8**, i8*** %t945
  %t980 = extractvalue %Bag %t951, 1
  %t981 = getelementptr inbounds i8*, i8** %t979, i64 %t953
  store i8* %t980, i8** %t981
  %t982 = add i64 %t953, 1
  store i64 %t982, i64* %t940
  %t983 = sext i32 0 to i64
  %t984 = load i8*, i8** %t735
  %t985 = icmp eq i8* %t984, null
  br i1 %t985, label %table_read_null_166, label %table_read_real_167
table_read_null_166:
  br label %table_read_end_168
table_read_real_167:
  %t986 = bitcast i8* %t984 to { i64, i64, i8**, i8** }*
  %t987 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t986, i32 0, i32 0
  %t988 = load i64, i64* %t987
  %t989 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t986, i32 0, i32 2
  %t990 = load i8**, i8*** %t989
  %t991 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t986, i32 0, i32 3
  %t992 = load i8**, i8*** %t991
  br label %table_read_end_168
table_read_end_168:
  %t993 = phi i64 [ 0, %table_read_null_166 ], [ %t988, %table_read_real_167 ]
  %t994 = phi i8** [ null, %table_read_null_166 ], [ %t990, %table_read_real_167 ]
  %t995 = phi i8** [ null, %table_read_null_166 ], [ %t992, %table_read_real_167 ]
  %t997 = icmp ult i64 %t983, %t993
  br i1 %t997, label %table_idx_ok_169, label %table_idx_oob_170
table_idx_ok_169:
  %t998 = getelementptr inbounds i8*, i8** %t994, i64 %t983
  %t999 = load i8*, i8** %t998
  call void @star_rc_retain(i8* %t999)
  %t1000 = load i8*, i8** %t998
  %t1001 = getelementptr inbounds %Bag, %Bag* %t996, i32 0, i32 0
  store i8* %t1000, i8** %t1001
  %t1002 = getelementptr inbounds i8*, i8** %t995, i64 %t983
  %t1003 = load i8*, i8** %t1002
  call void @star_rc_retain(i8* %t1003)
  %t1004 = load i8*, i8** %t1002
  %t1005 = getelementptr inbounds %Bag, %Bag* %t996, i32 0, i32 1
  store i8* %t1004, i8** %t1005
  br label %table_idx_end_171
table_idx_oob_170:
  %t1006 = getelementptr inbounds %Bag, %Bag* %t996, i32 0, i32 0
  store i8* null, i8** %t1006
  %t1007 = getelementptr inbounds %Bag, %Bag* %t996, i32 0, i32 1
  %t1008 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t1008
  store i8* %t1008, i8** %t1007
  br label %table_idx_end_171
table_idx_end_171:
  %t1009 = load %Bag, %Bag* %t996
  store %Bag %t1009, %Bag* %t1010
  %t1011 = getelementptr inbounds %Bag, %Bag* %t1010, i32 0, i32 1
  %t1012 = load i8*, i8** %t1011
  %t1013 = load i8*, i8** %t1011
  call void @star_rc_retain(i8* %t1013)
  call void @star_rc_release(i8* %t1012)
  %t1014 = sext i32 0 to i64
  %t1015 = load i8*, i8** %t735
  %t1016 = icmp eq i8* %t1015, null
  br i1 %t1016, label %table_read_null_172, label %table_read_real_173
table_read_null_172:
  br label %table_read_end_174
table_read_real_173:
  %t1017 = bitcast i8* %t1015 to { i64, i64, i8**, i8** }*
  %t1018 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1017, i32 0, i32 0
  %t1019 = load i64, i64* %t1018
  %t1020 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1017, i32 0, i32 2
  %t1021 = load i8**, i8*** %t1020
  %t1022 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1017, i32 0, i32 3
  %t1023 = load i8**, i8*** %t1022
  br label %table_read_end_174
table_read_end_174:
  %t1024 = phi i64 [ 0, %table_read_null_172 ], [ %t1019, %table_read_real_173 ]
  %t1025 = phi i8** [ null, %table_read_null_172 ], [ %t1021, %table_read_real_173 ]
  %t1026 = phi i8** [ null, %table_read_null_172 ], [ %t1023, %table_read_real_173 ]
  %t1028 = icmp ult i64 %t1014, %t1024
  br i1 %t1028, label %table_idx_ok_175, label %table_idx_oob_176
table_idx_ok_175:
  %t1029 = getelementptr inbounds i8*, i8** %t1025, i64 %t1014
  %t1030 = load i8*, i8** %t1029
  call void @star_rc_retain(i8* %t1030)
  %t1031 = load i8*, i8** %t1029
  %t1032 = getelementptr inbounds %Bag, %Bag* %t1027, i32 0, i32 0
  store i8* %t1031, i8** %t1032
  %t1033 = getelementptr inbounds i8*, i8** %t1026, i64 %t1014
  %t1034 = load i8*, i8** %t1033
  call void @star_rc_retain(i8* %t1034)
  %t1035 = load i8*, i8** %t1033
  %t1036 = getelementptr inbounds %Bag, %Bag* %t1027, i32 0, i32 1
  store i8* %t1035, i8** %t1036
  br label %table_idx_end_177
table_idx_oob_176:
  %t1037 = getelementptr inbounds %Bag, %Bag* %t1027, i32 0, i32 0
  store i8* null, i8** %t1037
  %t1038 = getelementptr inbounds %Bag, %Bag* %t1027, i32 0, i32 1
  %t1039 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t1039
  store i8* %t1039, i8** %t1038
  br label %table_idx_end_177
table_idx_end_177:
  %t1040 = load %Bag, %Bag* %t1027
  store %Bag %t1040, %Bag* %t1041
  %t1042 = getelementptr inbounds %Bag, %Bag* %t1041, i32 0, i32 0
  %t1043 = load i8*, i8** %t1042
  %t1044 = icmp eq i8* %t1043, null
  br i1 %t1044, label %list_read_null_178, label %list_read_real_179
list_read_null_178:
  br label %list_read_end_180
list_read_real_179:
  %t1045 = bitcast i8* %t1043 to { i32*, i64, i64 }*
  %t1046 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1045, i32 0, i32 0
  %t1047 = load i32*, i32** %t1046
  %t1048 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1045, i32 0, i32 1
  %t1049 = load i64, i64* %t1048
  br label %list_read_end_180
list_read_end_180:
  %t1050 = phi i32* [ null, %list_read_null_178 ], [ %t1047, %list_read_real_179 ]
  %t1051 = phi i64 [ 0, %list_read_null_178 ], [ %t1049, %list_read_real_179 ]
  %t1052 = trunc i64 %t1051 to i32
  %t1053 = getelementptr inbounds [41 x i8], [41 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1053, i8* %t1012, i32 %t1052)
  %t1054 = sext i32 1 to i64
  %t1055 = load i8*, i8** %t735
  %t1056 = icmp eq i8* %t1055, null
  br i1 %t1056, label %table_read_null_181, label %table_read_real_182
table_read_null_181:
  br label %table_read_end_183
table_read_real_182:
  %t1057 = bitcast i8* %t1055 to { i64, i64, i8**, i8** }*
  %t1058 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1057, i32 0, i32 0
  %t1059 = load i64, i64* %t1058
  %t1060 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1057, i32 0, i32 2
  %t1061 = load i8**, i8*** %t1060
  %t1062 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1057, i32 0, i32 3
  %t1063 = load i8**, i8*** %t1062
  br label %table_read_end_183
table_read_end_183:
  %t1064 = phi i64 [ 0, %table_read_null_181 ], [ %t1059, %table_read_real_182 ]
  %t1065 = phi i8** [ null, %table_read_null_181 ], [ %t1061, %table_read_real_182 ]
  %t1066 = phi i8** [ null, %table_read_null_181 ], [ %t1063, %table_read_real_182 ]
  %t1068 = icmp ult i64 %t1054, %t1064
  br i1 %t1068, label %table_idx_ok_184, label %table_idx_oob_185
table_idx_ok_184:
  %t1069 = getelementptr inbounds i8*, i8** %t1065, i64 %t1054
  %t1070 = load i8*, i8** %t1069
  call void @star_rc_retain(i8* %t1070)
  %t1071 = load i8*, i8** %t1069
  %t1072 = getelementptr inbounds %Bag, %Bag* %t1067, i32 0, i32 0
  store i8* %t1071, i8** %t1072
  %t1073 = getelementptr inbounds i8*, i8** %t1066, i64 %t1054
  %t1074 = load i8*, i8** %t1073
  call void @star_rc_retain(i8* %t1074)
  %t1075 = load i8*, i8** %t1073
  %t1076 = getelementptr inbounds %Bag, %Bag* %t1067, i32 0, i32 1
  store i8* %t1075, i8** %t1076
  br label %table_idx_end_186
table_idx_oob_185:
  %t1077 = getelementptr inbounds %Bag, %Bag* %t1067, i32 0, i32 0
  store i8* null, i8** %t1077
  %t1078 = getelementptr inbounds %Bag, %Bag* %t1067, i32 0, i32 1
  %t1079 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t1079
  store i8* %t1079, i8** %t1078
  br label %table_idx_end_186
table_idx_end_186:
  %t1080 = load %Bag, %Bag* %t1067
  store %Bag %t1080, %Bag* %t1081
  %t1082 = getelementptr inbounds %Bag, %Bag* %t1081, i32 0, i32 1
  %t1083 = load i8*, i8** %t1082
  %t1084 = load i8*, i8** %t1082
  call void @star_rc_retain(i8* %t1084)
  call void @star_rc_release(i8* %t1083)
  %t1085 = sext i32 1 to i64
  %t1086 = load i8*, i8** %t735
  %t1087 = icmp eq i8* %t1086, null
  br i1 %t1087, label %table_read_null_187, label %table_read_real_188
table_read_null_187:
  br label %table_read_end_189
table_read_real_188:
  %t1088 = bitcast i8* %t1086 to { i64, i64, i8**, i8** }*
  %t1089 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1088, i32 0, i32 0
  %t1090 = load i64, i64* %t1089
  %t1091 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1088, i32 0, i32 2
  %t1092 = load i8**, i8*** %t1091
  %t1093 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1088, i32 0, i32 3
  %t1094 = load i8**, i8*** %t1093
  br label %table_read_end_189
table_read_end_189:
  %t1095 = phi i64 [ 0, %table_read_null_187 ], [ %t1090, %table_read_real_188 ]
  %t1096 = phi i8** [ null, %table_read_null_187 ], [ %t1092, %table_read_real_188 ]
  %t1097 = phi i8** [ null, %table_read_null_187 ], [ %t1094, %table_read_real_188 ]
  %t1099 = icmp ult i64 %t1085, %t1095
  br i1 %t1099, label %table_idx_ok_190, label %table_idx_oob_191
table_idx_ok_190:
  %t1100 = getelementptr inbounds i8*, i8** %t1096, i64 %t1085
  %t1101 = load i8*, i8** %t1100
  call void @star_rc_retain(i8* %t1101)
  %t1102 = load i8*, i8** %t1100
  %t1103 = getelementptr inbounds %Bag, %Bag* %t1098, i32 0, i32 0
  store i8* %t1102, i8** %t1103
  %t1104 = getelementptr inbounds i8*, i8** %t1097, i64 %t1085
  %t1105 = load i8*, i8** %t1104
  call void @star_rc_retain(i8* %t1105)
  %t1106 = load i8*, i8** %t1104
  %t1107 = getelementptr inbounds %Bag, %Bag* %t1098, i32 0, i32 1
  store i8* %t1106, i8** %t1107
  br label %table_idx_end_192
table_idx_oob_191:
  %t1108 = getelementptr inbounds %Bag, %Bag* %t1098, i32 0, i32 0
  store i8* null, i8** %t1108
  %t1109 = getelementptr inbounds %Bag, %Bag* %t1098, i32 0, i32 1
  %t1110 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t1110
  store i8* %t1110, i8** %t1109
  br label %table_idx_end_192
table_idx_end_192:
  %t1111 = load %Bag, %Bag* %t1098
  store %Bag %t1111, %Bag* %t1112
  %t1113 = getelementptr inbounds %Bag, %Bag* %t1112, i32 0, i32 0
  %t1114 = load i8*, i8** %t1113
  %t1115 = icmp eq i8* %t1114, null
  br i1 %t1115, label %list_read_null_193, label %list_read_real_194
list_read_null_193:
  br label %list_read_end_195
list_read_real_194:
  %t1116 = bitcast i8* %t1114 to { i32*, i64, i64 }*
  %t1117 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1116, i32 0, i32 0
  %t1118 = load i32*, i32** %t1117
  %t1119 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1116, i32 0, i32 1
  %t1120 = load i64, i64* %t1119
  br label %list_read_end_195
list_read_end_195:
  %t1121 = phi i32* [ null, %list_read_null_193 ], [ %t1118, %list_read_real_194 ]
  %t1122 = phi i64 [ 0, %list_read_null_193 ], [ %t1120, %list_read_real_194 ]
  %t1123 = trunc i64 %t1122 to i32
  %t1124 = getelementptr inbounds [41 x i8], [41 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1124, i8* %t1083, i32 %t1123)
  %t1125 = getelementptr inbounds %Bag, %Bag* %t1112, i32 0, i32 0
  %t1126 = load i8*, i8** %t1125
  call void @star_rc_release(i8* %t1126)
  %t1127 = getelementptr inbounds %Bag, %Bag* %t1112, i32 0, i32 1
  %t1128 = load i8*, i8** %t1127
  call void @star_rc_release(i8* %t1128)
  %t1129 = getelementptr inbounds %Bag, %Bag* %t1081, i32 0, i32 0
  %t1130 = load i8*, i8** %t1129
  call void @star_rc_release(i8* %t1130)
  %t1131 = getelementptr inbounds %Bag, %Bag* %t1081, i32 0, i32 1
  %t1132 = load i8*, i8** %t1131
  call void @star_rc_release(i8* %t1132)
  %t1133 = getelementptr inbounds %Bag, %Bag* %t1041, i32 0, i32 0
  %t1134 = load i8*, i8** %t1133
  call void @star_rc_release(i8* %t1134)
  %t1135 = getelementptr inbounds %Bag, %Bag* %t1041, i32 0, i32 1
  %t1136 = load i8*, i8** %t1135
  call void @star_rc_release(i8* %t1136)
  %t1137 = getelementptr inbounds %Bag, %Bag* %t1010, i32 0, i32 0
  %t1138 = load i8*, i8** %t1137
  call void @star_rc_release(i8* %t1138)
  %t1139 = getelementptr inbounds %Bag, %Bag* %t1010, i32 0, i32 1
  %t1140 = load i8*, i8** %t1139
  call void @star_rc_release(i8* %t1140)
  %t1141 = load i8*, i8** %t735
  call void @star_rc_release(i8* %t1141)
  %t1142 = load i8*, i8** %t500
  call void @star_rc_release(i8* %t1142)
  %t1143 = load i8*, i8** %t304
  call void @star_rc_release(i8* %t1143)
  %t1144 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t108, i32 0, i32 0
  %t1145 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t1144, i32 0, i64 0
  %t1146 = getelementptr inbounds %Bag, %Bag* %t1145, i32 0, i32 0
  %t1147 = load i8*, i8** %t1146
  call void @star_rc_release(i8* %t1147)
  %t1148 = getelementptr inbounds %Bag, %Bag* %t1145, i32 0, i32 1
  %t1149 = load i8*, i8** %t1148
  call void @star_rc_release(i8* %t1149)
  %t1150 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t1144, i32 0, i64 1
  %t1151 = getelementptr inbounds %Bag, %Bag* %t1150, i32 0, i32 0
  %t1152 = load i8*, i8** %t1151
  call void @star_rc_release(i8* %t1152)
  %t1153 = getelementptr inbounds %Bag, %Bag* %t1150, i32 0, i32 1
  %t1154 = load i8*, i8** %t1153
  call void @star_rc_release(i8* %t1154)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_i32(i8* %objp) {
entry:
  %t118 = bitcast i8* %objp to { i32*, i64, i64 }*
  %t119 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t118, i32 0, i32 0
  %t120 = load i32*, i32** %t119
  %t121 = bitcast i32* %t120 to i8*
  call void @free(i8* %t121)
  ret void
}


define void @table_release_s_Point(i8* %objp) {
entry:
  %t307 = bitcast i8* %objp to { i64, i64, i32*, i32* }*
  %t308 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t307, i32 0, i32 0
  %t309 = load i64, i64* %t308
  %t310 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t307, i32 0, i32 2
  %t311 = load i32*, i32** %t310
  %t312 = bitcast i32* %t311 to i8*
  call void @free(i8* %t312)
  %t313 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t307, i32 0, i32 3
  %t314 = load i32*, i32** %t313
  %t315 = bitcast i32* %t314 to i8*
  call void @free(i8* %t315)
  ret void
}


define void @table_release_s_Bag(i8* %objp) {
entry:
  %t743 = alloca i64
  %t752 = alloca i64
  %t738 = bitcast i8* %objp to { i64, i64, i8**, i8** }*
  %t739 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t738, i32 0, i32 0
  %t740 = load i64, i64* %t739
  %t741 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t738, i32 0, i32 2
  %t742 = load i8**, i8*** %t741
  store i64 0, i64* %t743
  br label %table_release_cond_123
table_release_cond_123:
  %t744 = load i64, i64* %t743
  %t745 = icmp slt i64 %t744, %t740
  br i1 %t745, label %table_release_body_124, label %table_release_end_125
table_release_body_124:
  %t746 = getelementptr inbounds i8*, i8** %t742, i64 %t744
  %t747 = load i8*, i8** %t746
  call void @star_rc_release(i8* %t747)
  %t748 = add i64 %t744, 1
  store i64 %t748, i64* %t743
  br label %table_release_cond_123
table_release_end_125:
  %t749 = bitcast i8** %t742 to i8*
  call void @free(i8* %t749)
  %t750 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t738, i32 0, i32 3
  %t751 = load i8**, i8*** %t750
  store i64 0, i64* %t752
  br label %table_release_cond_126
table_release_cond_126:
  %t753 = load i64, i64* %t752
  %t754 = icmp slt i64 %t753, %t740
  br i1 %t754, label %table_release_body_127, label %table_release_end_128
table_release_body_127:
  %t755 = getelementptr inbounds i8*, i8** %t751, i64 %t753
  %t756 = load i8*, i8** %t755
  call void @star_rc_release(i8* %t756)
  %t757 = add i64 %t753, 1
  store i64 %t757, i64* %t752
  br label %table_release_cond_126
table_release_end_128:
  %t758 = bitcast i8** %t751 to i8*
  call void @free(i8* %t758)
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
