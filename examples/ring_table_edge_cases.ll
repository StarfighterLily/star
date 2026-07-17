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

%Bag = type { i8*, i8* }
%Point = type { i32, i32 }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca { [1 x i32], i64, i64 }
  %t59 = alloca i32
  %t63 = alloca { [3 x i32], i64, i64 }
  %t103 = alloca i32
  %t107 = alloca { [2 x %Bag], i64, i64 }
  %t108 = alloca %Bag
  %t148 = alloca %Bag
  %t183 = alloca %Bag
  %t229 = alloca %Bag
  %t246 = alloca %Bag
  %t272 = alloca %Bag
  %t289 = alloca %Bag
  %t303 = alloca i8*
  %t371 = alloca %Point
  %t464 = alloca %Point
  %t499 = alloca i8*
  %t560 = alloca %Point
  %t635 = alloca %Point
  %t644 = alloca %Point
  %t660 = alloca %Point
  %t669 = alloca %Point
  %t687 = alloca %Point
  %t696 = alloca %Point
  %t713 = alloca %Point
  %t722 = alloca %Point
  %t726 = alloca i8*
  %t785 = alloca i64
  %t802 = alloca i64
  %t818 = alloca %Bag
  %t905 = alloca i64
  %t922 = alloca i64
  %t938 = alloca %Bag
  %t987 = alloca %Bag
  %t998 = alloca %Bag
  %t1015 = alloca %Bag
  %t1026 = alloca %Bag
  %t1052 = alloca %Bag
  %t1063 = alloca %Bag
  %t1080 = alloca %Bag
  %t1091 = alloca %Bag
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  store { [1 x i32], i64, i64 } zeroinitializer, { [1 x i32], i64, i64 }* %t1
  %t2 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t3 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t4 = load i64, i64* %t3
  %t5 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t6 = load i64, i64* %t5
  %t7 = icmp sge i64 %t6, 1
  br i1 %t7, label %ring_push_full_0, label %ring_push_grow_1
ring_push_grow_1:
  %t8 = add i64 %t4, %t6
  %t9 = urem i64 %t8, 1
  %t10 = getelementptr inbounds [1 x i32], [1 x i32]* %t2, i32 0, i64 %t9
  store i32 10, i32* %t10
  %t11 = add i64 %t6, 1
  store i64 %t11, i64* %t5
  br label %ring_push_done_2
ring_push_full_0:
  %t12 = getelementptr inbounds [1 x i32], [1 x i32]* %t2, i32 0, i64 %t4
  store i32 10, i32* %t12
  %t13 = add i64 %t4, 1
  %t14 = urem i64 %t13, 1
  store i64 %t14, i64* %t3
  br label %ring_push_done_2
ring_push_done_2:
  %t15 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t16 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t17 = load i64, i64* %t16
  %t18 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t19 = load i64, i64* %t18
  %t20 = icmp sge i64 %t19, 1
  br i1 %t20, label %ring_push_full_3, label %ring_push_grow_4
ring_push_grow_4:
  %t21 = add i64 %t17, %t19
  %t22 = urem i64 %t21, 1
  %t23 = getelementptr inbounds [1 x i32], [1 x i32]* %t15, i32 0, i64 %t22
  store i32 20, i32* %t23
  %t24 = add i64 %t19, 1
  store i64 %t24, i64* %t18
  br label %ring_push_done_5
ring_push_full_3:
  %t25 = getelementptr inbounds [1 x i32], [1 x i32]* %t15, i32 0, i64 %t17
  store i32 20, i32* %t25
  %t26 = add i64 %t17, 1
  %t27 = urem i64 %t26, 1
  store i64 %t27, i64* %t16
  br label %ring_push_done_5
ring_push_done_5:
  %t28 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t29 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t30 = load i64, i64* %t29
  %t31 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t32 = load i64, i64* %t31
  %t33 = icmp sge i64 %t32, 1
  br i1 %t33, label %ring_push_full_6, label %ring_push_grow_7
ring_push_grow_7:
  %t34 = add i64 %t30, %t32
  %t35 = urem i64 %t34, 1
  %t36 = getelementptr inbounds [1 x i32], [1 x i32]* %t28, i32 0, i64 %t35
  store i32 30, i32* %t36
  %t37 = add i64 %t32, 1
  store i64 %t37, i64* %t31
  br label %ring_push_done_8
ring_push_full_6:
  %t38 = getelementptr inbounds [1 x i32], [1 x i32]* %t28, i32 0, i64 %t30
  store i32 30, i32* %t38
  %t39 = add i64 %t30, 1
  %t40 = urem i64 %t39, 1
  store i64 %t40, i64* %t29
  br label %ring_push_done_8
ring_push_done_8:
  %t41 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t42 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t43 = load i64, i64* %t42
  %t44 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t45 = load i64, i64* %t44
  %t46 = trunc i64 %t45 to i32
  %t47 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t1, i32 0, i32 0
  %t48 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t1, i32 0, i32 1
  %t49 = load i64, i64* %t48
  %t50 = getelementptr inbounds { [1 x i32], i64, i64 }, { [1 x i32], i64, i64 }* %t1, i32 0, i32 2
  %t51 = load i64, i64* %t50
  %t52 = sext i32 0 to i64
  %t53 = load i64, i64* %t48
  %t54 = load i64, i64* %t50
  %t55 = icmp ult i64 %t52, %t54
  br i1 %t55, label %ring_rplace_ok_9, label %ring_rplace_oob_10
ring_rplace_ok_9:
  %t56 = add i64 %t53, %t52
  %t57 = urem i64 %t56, 1
  %t58 = getelementptr inbounds [1 x i32], [1 x i32]* %t47, i32 0, i64 %t57
  br label %ring_rplace_end_11
ring_rplace_oob_10:
  store i32 0, i32* %t59
  br label %ring_rplace_end_11
ring_rplace_end_11:
  %t60 = phi i32* [ %t58, %ring_rplace_ok_9 ], [ %t59, %ring_rplace_oob_10 ]
  %t61 = load i32, i32* %t60
  %t62 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t62, i32 %t46, i32 %t61)
  store { [3 x i32], i64, i64 } zeroinitializer, { [3 x i32], i64, i64 }* %t63
  %t64 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t63, i32 0, i32 0
  %t65 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t63, i32 0, i32 1
  %t66 = load i64, i64* %t65
  %t67 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t63, i32 0, i32 2
  %t68 = load i64, i64* %t67
  %t69 = icmp sge i64 %t68, 3
  br i1 %t69, label %ring_push_full_12, label %ring_push_grow_13
ring_push_grow_13:
  %t70 = add i64 %t66, %t68
  %t71 = urem i64 %t70, 3
  %t72 = getelementptr inbounds [3 x i32], [3 x i32]* %t64, i32 0, i64 %t71
  store i32 1, i32* %t72
  %t73 = add i64 %t68, 1
  store i64 %t73, i64* %t67
  br label %ring_push_done_14
ring_push_full_12:
  %t74 = getelementptr inbounds [3 x i32], [3 x i32]* %t64, i32 0, i64 %t66
  store i32 1, i32* %t74
  %t75 = add i64 %t66, 1
  %t76 = urem i64 %t75, 3
  store i64 %t76, i64* %t65
  br label %ring_push_done_14
ring_push_done_14:
  %t77 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t63, i32 0, i32 0
  %t78 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t63, i32 0, i32 1
  %t79 = load i64, i64* %t78
  %t80 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t63, i32 0, i32 2
  %t81 = load i64, i64* %t80
  %t82 = icmp sge i64 %t81, 3
  br i1 %t82, label %ring_push_full_15, label %ring_push_grow_16
ring_push_grow_16:
  %t83 = add i64 %t79, %t81
  %t84 = urem i64 %t83, 3
  %t85 = getelementptr inbounds [3 x i32], [3 x i32]* %t77, i32 0, i64 %t84
  store i32 2, i32* %t85
  %t86 = add i64 %t81, 1
  store i64 %t86, i64* %t80
  br label %ring_push_done_17
ring_push_full_15:
  %t87 = getelementptr inbounds [3 x i32], [3 x i32]* %t77, i32 0, i64 %t79
  store i32 2, i32* %t87
  %t88 = add i64 %t79, 1
  %t89 = urem i64 %t88, 3
  store i64 %t89, i64* %t78
  br label %ring_push_done_17
ring_push_done_17:
  %t90 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t63, i32 0, i32 0
  %t91 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t63, i32 0, i32 1
  %t92 = load i64, i64* %t91
  %t93 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t63, i32 0, i32 2
  %t94 = load i64, i64* %t93
  %t95 = sub i32 0, 1
  %t96 = sext i32 %t95 to i64
  %t97 = load i64, i64* %t91
  %t98 = load i64, i64* %t93
  %t99 = icmp ult i64 %t96, %t98
  br i1 %t99, label %ring_rplace_ok_18, label %ring_rplace_oob_19
ring_rplace_ok_18:
  %t100 = add i64 %t97, %t96
  %t101 = urem i64 %t100, 3
  %t102 = getelementptr inbounds [3 x i32], [3 x i32]* %t90, i32 0, i64 %t101
  br label %ring_rplace_end_20
ring_rplace_oob_19:
  store i32 0, i32* %t103
  br label %ring_rplace_end_20
ring_rplace_end_20:
  %t104 = phi i32* [ %t102, %ring_rplace_ok_18 ], [ %t103, %ring_rplace_oob_19 ]
  %t105 = load i32, i32* %t104
  %t106 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t106, i32 %t105)
  store { [2 x %Bag], i64, i64 } zeroinitializer, { [2 x %Bag], i64, i64 }* %t107
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
  %t131 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 0
  %t132 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 1
  %t133 = load i64, i64* %t132
  %t134 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 2
  %t135 = load i64, i64* %t134
  %t136 = icmp sge i64 %t135, 2
  br i1 %t136, label %ring_push_full_21, label %ring_push_grow_22
ring_push_grow_22:
  %t137 = add i64 %t133, %t135
  %t138 = urem i64 %t137, 2
  %t139 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t131, i32 0, i64 %t138
  store %Bag %t130, %Bag* %t139
  %t140 = add i64 %t135, 1
  store i64 %t140, i64* %t134
  br label %ring_push_done_23
ring_push_full_21:
  %t141 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t131, i32 0, i64 %t133
  %t142 = getelementptr inbounds %Bag, %Bag* %t141, i32 0, i32 0
  %t143 = load i8*, i8** %t142
  call void @star_rc_release(i8* %t143)
  %t144 = getelementptr inbounds %Bag, %Bag* %t141, i32 0, i32 1
  %t145 = load i8*, i8** %t144
  call void @star_rc_release(i8* %t145)
  store %Bag %t130, %Bag* %t141
  %t146 = add i64 %t133, 1
  %t147 = urem i64 %t146, 2
  store i64 %t147, i64* %t132
  br label %ring_push_done_23
ring_push_done_23:
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
  %t166 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 0
  %t167 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 1
  %t168 = load i64, i64* %t167
  %t169 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 2
  %t170 = load i64, i64* %t169
  %t171 = icmp sge i64 %t170, 2
  br i1 %t171, label %ring_push_full_24, label %ring_push_grow_25
ring_push_grow_25:
  %t172 = add i64 %t168, %t170
  %t173 = urem i64 %t172, 2
  %t174 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t166, i32 0, i64 %t173
  store %Bag %t165, %Bag* %t174
  %t175 = add i64 %t170, 1
  store i64 %t175, i64* %t169
  br label %ring_push_done_26
ring_push_full_24:
  %t176 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t166, i32 0, i64 %t168
  %t177 = getelementptr inbounds %Bag, %Bag* %t176, i32 0, i32 0
  %t178 = load i8*, i8** %t177
  call void @star_rc_release(i8* %t178)
  %t179 = getelementptr inbounds %Bag, %Bag* %t176, i32 0, i32 1
  %t180 = load i8*, i8** %t179
  call void @star_rc_release(i8* %t180)
  store %Bag %t165, %Bag* %t176
  %t181 = add i64 %t168, 1
  %t182 = urem i64 %t181, 2
  store i64 %t182, i64* %t167
  br label %ring_push_done_26
ring_push_done_26:
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
  %t200 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 0
  %t201 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 1
  %t202 = load i64, i64* %t201
  %t203 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 2
  %t204 = load i64, i64* %t203
  %t205 = icmp sge i64 %t204, 2
  br i1 %t205, label %ring_push_full_27, label %ring_push_grow_28
ring_push_grow_28:
  %t206 = add i64 %t202, %t204
  %t207 = urem i64 %t206, 2
  %t208 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t200, i32 0, i64 %t207
  store %Bag %t199, %Bag* %t208
  %t209 = add i64 %t204, 1
  store i64 %t209, i64* %t203
  br label %ring_push_done_29
ring_push_full_27:
  %t210 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t200, i32 0, i64 %t202
  %t211 = getelementptr inbounds %Bag, %Bag* %t210, i32 0, i32 0
  %t212 = load i8*, i8** %t211
  call void @star_rc_release(i8* %t212)
  %t213 = getelementptr inbounds %Bag, %Bag* %t210, i32 0, i32 1
  %t214 = load i8*, i8** %t213
  call void @star_rc_release(i8* %t214)
  store %Bag %t199, %Bag* %t210
  %t215 = add i64 %t202, 1
  %t216 = urem i64 %t215, 2
  store i64 %t216, i64* %t201
  br label %ring_push_done_29
ring_push_done_29:
  %t217 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 0
  %t218 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 1
  %t219 = load i64, i64* %t218
  %t220 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 2
  %t221 = load i64, i64* %t220
  %t222 = sext i32 0 to i64
  %t223 = load i64, i64* %t218
  %t224 = load i64, i64* %t220
  %t225 = icmp ult i64 %t222, %t224
  br i1 %t225, label %ring_rplace_ok_30, label %ring_rplace_oob_31
ring_rplace_ok_30:
  %t226 = add i64 %t223, %t222
  %t227 = urem i64 %t226, 2
  %t228 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t217, i32 0, i64 %t227
  br label %ring_rplace_end_32
ring_rplace_oob_31:
  store %Bag zeroinitializer, %Bag* %t229
  br label %ring_rplace_end_32
ring_rplace_end_32:
  %t230 = phi %Bag* [ %t228, %ring_rplace_ok_30 ], [ %t229, %ring_rplace_oob_31 ]
  %t231 = getelementptr inbounds %Bag, %Bag* %t230, i32 0, i32 1
  %t232 = load i8*, i8** %t231
  %t233 = load i8*, i8** %t231
  call void @star_rc_retain(i8* %t233)
  call void @star_rc_release(i8* %t232)
  %t234 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 0
  %t235 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 1
  %t236 = load i64, i64* %t235
  %t237 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 2
  %t238 = load i64, i64* %t237
  %t239 = sext i32 0 to i64
  %t240 = load i64, i64* %t235
  %t241 = load i64, i64* %t237
  %t242 = icmp ult i64 %t239, %t241
  br i1 %t242, label %ring_rplace_ok_33, label %ring_rplace_oob_34
ring_rplace_ok_33:
  %t243 = add i64 %t240, %t239
  %t244 = urem i64 %t243, 2
  %t245 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t234, i32 0, i64 %t244
  br label %ring_rplace_end_35
ring_rplace_oob_34:
  store %Bag zeroinitializer, %Bag* %t246
  br label %ring_rplace_end_35
ring_rplace_end_35:
  %t247 = phi %Bag* [ %t245, %ring_rplace_ok_33 ], [ %t246, %ring_rplace_oob_34 ]
  %t248 = getelementptr inbounds %Bag, %Bag* %t247, i32 0, i32 0
  %t249 = load i8*, i8** %t248
  %t250 = icmp eq i8* %t249, null
  br i1 %t250, label %list_read_null_36, label %list_read_real_37
list_read_null_36:
  br label %list_read_end_38
list_read_real_37:
  %t251 = bitcast i8* %t249 to { i32*, i64, i64 }*
  %t252 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t251, i32 0, i32 0
  %t253 = load i32*, i32** %t252
  %t254 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t251, i32 0, i32 1
  %t255 = load i64, i64* %t254
  br label %list_read_end_38
list_read_end_38:
  %t256 = phi i32* [ null, %list_read_null_36 ], [ %t253, %list_read_real_37 ]
  %t257 = phi i64 [ 0, %list_read_null_36 ], [ %t255, %list_read_real_37 ]
  %t258 = trunc i64 %t257 to i32
  %t259 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t259, i8* %t232, i32 %t258)
  %t260 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 0
  %t261 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 1
  %t262 = load i64, i64* %t261
  %t263 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 2
  %t264 = load i64, i64* %t263
  %t265 = sext i32 1 to i64
  %t266 = load i64, i64* %t261
  %t267 = load i64, i64* %t263
  %t268 = icmp ult i64 %t265, %t267
  br i1 %t268, label %ring_rplace_ok_39, label %ring_rplace_oob_40
ring_rplace_ok_39:
  %t269 = add i64 %t266, %t265
  %t270 = urem i64 %t269, 2
  %t271 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t260, i32 0, i64 %t270
  br label %ring_rplace_end_41
ring_rplace_oob_40:
  store %Bag zeroinitializer, %Bag* %t272
  br label %ring_rplace_end_41
ring_rplace_end_41:
  %t273 = phi %Bag* [ %t271, %ring_rplace_ok_39 ], [ %t272, %ring_rplace_oob_40 ]
  %t274 = getelementptr inbounds %Bag, %Bag* %t273, i32 0, i32 1
  %t275 = load i8*, i8** %t274
  %t276 = load i8*, i8** %t274
  call void @star_rc_retain(i8* %t276)
  call void @star_rc_release(i8* %t275)
  %t277 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 0
  %t278 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 1
  %t279 = load i64, i64* %t278
  %t280 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 2
  %t281 = load i64, i64* %t280
  %t282 = sext i32 1 to i64
  %t283 = load i64, i64* %t278
  %t284 = load i64, i64* %t280
  %t285 = icmp ult i64 %t282, %t284
  br i1 %t285, label %ring_rplace_ok_42, label %ring_rplace_oob_43
ring_rplace_ok_42:
  %t286 = add i64 %t283, %t282
  %t287 = urem i64 %t286, 2
  %t288 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t277, i32 0, i64 %t287
  br label %ring_rplace_end_44
ring_rplace_oob_43:
  store %Bag zeroinitializer, %Bag* %t289
  br label %ring_rplace_end_44
ring_rplace_end_44:
  %t290 = phi %Bag* [ %t288, %ring_rplace_ok_42 ], [ %t289, %ring_rplace_oob_43 ]
  %t291 = getelementptr inbounds %Bag, %Bag* %t290, i32 0, i32 0
  %t292 = load i8*, i8** %t291
  %t293 = icmp eq i8* %t292, null
  br i1 %t293, label %list_read_null_45, label %list_read_real_46
list_read_null_45:
  br label %list_read_end_47
list_read_real_46:
  %t294 = bitcast i8* %t292 to { i32*, i64, i64 }*
  %t295 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t294, i32 0, i32 0
  %t296 = load i32*, i32** %t295
  %t297 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t294, i32 0, i32 1
  %t298 = load i64, i64* %t297
  br label %list_read_end_47
list_read_end_47:
  %t299 = phi i32* [ null, %list_read_null_45 ], [ %t296, %list_read_real_46 ]
  %t300 = phi i64 [ 0, %list_read_null_45 ], [ %t298, %list_read_real_46 ]
  %t301 = trunc i64 %t300 to i32
  %t302 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t302, i8* %t275, i32 %t301)
  store i8* null, i8** %t303
  %t304 = load i8*, i8** %t303
  %t305 = icmp eq i8* %t304, null
  br i1 %t305, label %table_cow_alloc_48, label %table_cow_check_49
table_cow_alloc_48:
  %t315 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t316 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t317 = ptrtoint { i64, i64, i32*, i32* }* %t316 to i64
  %t318 = call i8* @star_rc_alloc(i64 %t317, i8* %t315)
  %t319 = bitcast i8* %t318 to { i64, i64, i32*, i32* }*
  %t320 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t319, i32 0, i32 0
  store i64 0, i64* %t320
  %t321 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t319, i32 0, i32 1
  store i64 0, i64* %t321
  %t322 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t319, i32 0, i32 2
  store i32* null, i32** %t322
  %t323 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t319, i32 0, i32 3
  store i32* null, i32** %t323
  store i8* %t318, i8** %t303
  br label %table_cow_done_50
table_cow_check_49:
  %t324 = getelementptr inbounds i8, i8* %t304, i64 -16
  %t325 = bitcast i8* %t324 to i64*
  %t326 = load atomic i64, i64* %t325 seq_cst, align 8
  %t327 = icmp eq i64 %t326, 1
  br i1 %t327, label %table_cow_done_50, label %table_cow_clone_51
table_cow_clone_51:
  %t328 = bitcast i8* %t304 to { i64, i64, i32*, i32* }*
  %t329 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t328, i32 0, i32 0
  %t330 = load i64, i64* %t329
  %t331 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t328, i32 0, i32 1
  %t332 = load i64, i64* %t331
  %t333 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t334 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t335 = ptrtoint { i64, i64, i32*, i32* }* %t334 to i64
  %t336 = call i8* @star_rc_alloc(i64 %t335, i8* %t333)
  %t337 = bitcast i8* %t336 to { i64, i64, i32*, i32* }*
  %t338 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t337, i32 0, i32 0
  store i64 %t330, i64* %t338
  %t339 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t337, i32 0, i32 1
  store i64 %t332, i64* %t339
  %t340 = getelementptr i32, i32* null, i32 1
  %t341 = ptrtoint i32* %t340 to i64
  %t342 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t328, i32 0, i32 2
  %t343 = load i32*, i32** %t342
  %t344 = mul i64 %t332, %t341
  %t345 = call i8* @malloc(i64 %t344)
  %t346 = bitcast i8* %t345 to i32*
  %t347 = icmp sgt i64 %t330, 0
  br i1 %t347, label %table_cow_copy_52, label %table_cow_after_copy_53
table_cow_copy_52:
  %t348 = mul i64 %t330, %t341
  %t349 = bitcast i32* %t343 to i8*
  call i8* @memcpy(i8* %t345, i8* %t349, i64 %t348)
  br label %table_cow_after_copy_53
table_cow_after_copy_53:
  %t350 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t337, i32 0, i32 2
  store i32* %t346, i32** %t350
  %t351 = getelementptr i32, i32* null, i32 1
  %t352 = ptrtoint i32* %t351 to i64
  %t353 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t328, i32 0, i32 3
  %t354 = load i32*, i32** %t353
  %t355 = mul i64 %t332, %t352
  %t356 = call i8* @malloc(i64 %t355)
  %t357 = bitcast i8* %t356 to i32*
  %t358 = icmp sgt i64 %t330, 0
  br i1 %t358, label %table_cow_copy_54, label %table_cow_after_copy_55
table_cow_copy_54:
  %t359 = mul i64 %t330, %t352
  %t360 = bitcast i32* %t354 to i8*
  call i8* @memcpy(i8* %t356, i8* %t360, i64 %t359)
  br label %table_cow_after_copy_55
table_cow_after_copy_55:
  %t361 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t337, i32 0, i32 3
  store i32* %t357, i32** %t361
  call void @star_rc_release(i8* %t304)
  store i8* %t336, i8** %t303
  br label %table_cow_done_50
table_cow_done_50:
  %t362 = load i8*, i8** %t303
  %t363 = bitcast i8* %t362 to { i64, i64, i32*, i32* }*
  %t364 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t363, i32 0, i32 0
  %t365 = load i64, i64* %t364
  %t366 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t363, i32 0, i32 1
  %t367 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t363, i32 0, i32 2
  %t368 = load i32*, i32** %t367
  %t369 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t363, i32 0, i32 3
  %t370 = load i32*, i32** %t369
  %t372 = getelementptr inbounds %Point, %Point* %t371, i32 0, i32 0
  store i32 1, i32* %t372
  %t373 = getelementptr inbounds %Point, %Point* %t371, i32 0, i32 1
  store i32 2, i32* %t373
  %t374 = load %Point, %Point* %t371
  %t375 = load i64, i64* %t366
  %t376 = load i64, i64* %t364
  %t377 = load i32*, i32** %t367
  %t378 = load i32*, i32** %t369
  %t379 = icmp sge i64 %t376, %t375
  br i1 %t379, label %table_push_grow_56, label %table_push_store_57
table_push_grow_56:
  %t380 = mul i64 %t375, 2
  %t381 = icmp sgt i64 %t380, 0
  %t382 = select i1 %t381, i64 %t380, i64 1
  %t383 = getelementptr i32, i32* null, i32 1
  %t384 = ptrtoint i32* %t383 to i64
  %t385 = mul i64 %t382, %t384
  %t386 = call i8* @malloc(i64 %t385)
  %t387 = bitcast i8* %t386 to i32*
  %t388 = icmp sgt i64 %t375, 0
  br i1 %t388, label %table_push_copy_58, label %table_push_after_copy_59
table_push_copy_58:
  %t389 = mul i64 %t376, %t384
  %t390 = bitcast i32* %t377 to i8*
  call i8* @memcpy(i8* %t386, i8* %t390, i64 %t389)
  call void @free(i8* %t390)
  br label %table_push_after_copy_59
table_push_after_copy_59:
  store i32* %t387, i32** %t367
  %t391 = getelementptr i32, i32* null, i32 1
  %t392 = ptrtoint i32* %t391 to i64
  %t393 = mul i64 %t382, %t392
  %t394 = call i8* @malloc(i64 %t393)
  %t395 = bitcast i8* %t394 to i32*
  %t396 = icmp sgt i64 %t375, 0
  br i1 %t396, label %table_push_copy_60, label %table_push_after_copy_61
table_push_copy_60:
  %t397 = mul i64 %t376, %t392
  %t398 = bitcast i32* %t378 to i8*
  call i8* @memcpy(i8* %t394, i8* %t398, i64 %t397)
  call void @free(i8* %t398)
  br label %table_push_after_copy_61
table_push_after_copy_61:
  store i32* %t395, i32** %t369
  store i64 %t382, i64* %t366
  br label %table_push_store_57
table_push_store_57:
  %t399 = load i32*, i32** %t367
  %t400 = extractvalue %Point %t374, 0
  %t401 = getelementptr inbounds i32, i32* %t399, i64 %t376
  store i32 %t400, i32* %t401
  %t402 = load i32*, i32** %t369
  %t403 = extractvalue %Point %t374, 1
  %t404 = getelementptr inbounds i32, i32* %t402, i64 %t376
  store i32 %t403, i32* %t404
  %t405 = add i64 %t376, 1
  store i64 %t405, i64* %t364
  %t406 = load i8*, i8** %t303
  %t407 = icmp eq i8* %t406, null
  br i1 %t407, label %table_cow_alloc_62, label %table_cow_check_63
table_cow_alloc_62:
  %t408 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t409 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t410 = ptrtoint { i64, i64, i32*, i32* }* %t409 to i64
  %t411 = call i8* @star_rc_alloc(i64 %t410, i8* %t408)
  %t412 = bitcast i8* %t411 to { i64, i64, i32*, i32* }*
  %t413 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t412, i32 0, i32 0
  store i64 0, i64* %t413
  %t414 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t412, i32 0, i32 1
  store i64 0, i64* %t414
  %t415 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t412, i32 0, i32 2
  store i32* null, i32** %t415
  %t416 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t412, i32 0, i32 3
  store i32* null, i32** %t416
  store i8* %t411, i8** %t303
  br label %table_cow_done_64
table_cow_check_63:
  %t417 = getelementptr inbounds i8, i8* %t406, i64 -16
  %t418 = bitcast i8* %t417 to i64*
  %t419 = load atomic i64, i64* %t418 seq_cst, align 8
  %t420 = icmp eq i64 %t419, 1
  br i1 %t420, label %table_cow_done_64, label %table_cow_clone_65
table_cow_clone_65:
  %t421 = bitcast i8* %t406 to { i64, i64, i32*, i32* }*
  %t422 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t421, i32 0, i32 0
  %t423 = load i64, i64* %t422
  %t424 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t421, i32 0, i32 1
  %t425 = load i64, i64* %t424
  %t426 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t427 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t428 = ptrtoint { i64, i64, i32*, i32* }* %t427 to i64
  %t429 = call i8* @star_rc_alloc(i64 %t428, i8* %t426)
  %t430 = bitcast i8* %t429 to { i64, i64, i32*, i32* }*
  %t431 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t430, i32 0, i32 0
  store i64 %t423, i64* %t431
  %t432 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t430, i32 0, i32 1
  store i64 %t425, i64* %t432
  %t433 = getelementptr i32, i32* null, i32 1
  %t434 = ptrtoint i32* %t433 to i64
  %t435 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t421, i32 0, i32 2
  %t436 = load i32*, i32** %t435
  %t437 = mul i64 %t425, %t434
  %t438 = call i8* @malloc(i64 %t437)
  %t439 = bitcast i8* %t438 to i32*
  %t440 = icmp sgt i64 %t423, 0
  br i1 %t440, label %table_cow_copy_66, label %table_cow_after_copy_67
table_cow_copy_66:
  %t441 = mul i64 %t423, %t434
  %t442 = bitcast i32* %t436 to i8*
  call i8* @memcpy(i8* %t438, i8* %t442, i64 %t441)
  br label %table_cow_after_copy_67
table_cow_after_copy_67:
  %t443 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t430, i32 0, i32 2
  store i32* %t439, i32** %t443
  %t444 = getelementptr i32, i32* null, i32 1
  %t445 = ptrtoint i32* %t444 to i64
  %t446 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t421, i32 0, i32 3
  %t447 = load i32*, i32** %t446
  %t448 = mul i64 %t425, %t445
  %t449 = call i8* @malloc(i64 %t448)
  %t450 = bitcast i8* %t449 to i32*
  %t451 = icmp sgt i64 %t423, 0
  br i1 %t451, label %table_cow_copy_68, label %table_cow_after_copy_69
table_cow_copy_68:
  %t452 = mul i64 %t423, %t445
  %t453 = bitcast i32* %t447 to i8*
  call i8* @memcpy(i8* %t449, i8* %t453, i64 %t452)
  br label %table_cow_after_copy_69
table_cow_after_copy_69:
  %t454 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t430, i32 0, i32 3
  store i32* %t450, i32** %t454
  call void @star_rc_release(i8* %t406)
  store i8* %t429, i8** %t303
  br label %table_cow_done_64
table_cow_done_64:
  %t455 = load i8*, i8** %t303
  %t456 = bitcast i8* %t455 to { i64, i64, i32*, i32* }*
  %t457 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t456, i32 0, i32 0
  %t458 = load i64, i64* %t457
  %t459 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t456, i32 0, i32 1
  %t460 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t456, i32 0, i32 2
  %t461 = load i32*, i32** %t460
  %t462 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t456, i32 0, i32 3
  %t463 = load i32*, i32** %t462
  %t465 = getelementptr inbounds %Point, %Point* %t464, i32 0, i32 0
  store i32 3, i32* %t465
  %t466 = getelementptr inbounds %Point, %Point* %t464, i32 0, i32 1
  store i32 4, i32* %t466
  %t467 = load %Point, %Point* %t464
  %t468 = load i64, i64* %t459
  %t469 = load i64, i64* %t457
  %t470 = load i32*, i32** %t460
  %t471 = load i32*, i32** %t462
  %t472 = icmp sge i64 %t469, %t468
  br i1 %t472, label %table_push_grow_70, label %table_push_store_71
table_push_grow_70:
  %t473 = mul i64 %t468, 2
  %t474 = icmp sgt i64 %t473, 0
  %t475 = select i1 %t474, i64 %t473, i64 1
  %t476 = getelementptr i32, i32* null, i32 1
  %t477 = ptrtoint i32* %t476 to i64
  %t478 = mul i64 %t475, %t477
  %t479 = call i8* @malloc(i64 %t478)
  %t480 = bitcast i8* %t479 to i32*
  %t481 = icmp sgt i64 %t468, 0
  br i1 %t481, label %table_push_copy_72, label %table_push_after_copy_73
table_push_copy_72:
  %t482 = mul i64 %t469, %t477
  %t483 = bitcast i32* %t470 to i8*
  call i8* @memcpy(i8* %t479, i8* %t483, i64 %t482)
  call void @free(i8* %t483)
  br label %table_push_after_copy_73
table_push_after_copy_73:
  store i32* %t480, i32** %t460
  %t484 = getelementptr i32, i32* null, i32 1
  %t485 = ptrtoint i32* %t484 to i64
  %t486 = mul i64 %t475, %t485
  %t487 = call i8* @malloc(i64 %t486)
  %t488 = bitcast i8* %t487 to i32*
  %t489 = icmp sgt i64 %t468, 0
  br i1 %t489, label %table_push_copy_74, label %table_push_after_copy_75
table_push_copy_74:
  %t490 = mul i64 %t469, %t485
  %t491 = bitcast i32* %t471 to i8*
  call i8* @memcpy(i8* %t487, i8* %t491, i64 %t490)
  call void @free(i8* %t491)
  br label %table_push_after_copy_75
table_push_after_copy_75:
  store i32* %t488, i32** %t462
  store i64 %t475, i64* %t459
  br label %table_push_store_71
table_push_store_71:
  %t492 = load i32*, i32** %t460
  %t493 = extractvalue %Point %t467, 0
  %t494 = getelementptr inbounds i32, i32* %t492, i64 %t469
  store i32 %t493, i32* %t494
  %t495 = load i32*, i32** %t462
  %t496 = extractvalue %Point %t467, 1
  %t497 = getelementptr inbounds i32, i32* %t495, i64 %t469
  store i32 %t496, i32* %t497
  %t498 = add i64 %t469, 1
  store i64 %t498, i64* %t457
  %t500 = load i8*, i8** %t303
  %t501 = load i8*, i8** %t303
  call void @star_rc_retain(i8* %t501)
  store i8* %t500, i8** %t499
  %t502 = load i8*, i8** %t499
  %t503 = icmp eq i8* %t502, null
  br i1 %t503, label %table_cow_alloc_76, label %table_cow_check_77
table_cow_alloc_76:
  %t504 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t505 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t506 = ptrtoint { i64, i64, i32*, i32* }* %t505 to i64
  %t507 = call i8* @star_rc_alloc(i64 %t506, i8* %t504)
  %t508 = bitcast i8* %t507 to { i64, i64, i32*, i32* }*
  %t509 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t508, i32 0, i32 0
  store i64 0, i64* %t509
  %t510 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t508, i32 0, i32 1
  store i64 0, i64* %t510
  %t511 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t508, i32 0, i32 2
  store i32* null, i32** %t511
  %t512 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t508, i32 0, i32 3
  store i32* null, i32** %t512
  store i8* %t507, i8** %t499
  br label %table_cow_done_78
table_cow_check_77:
  %t513 = getelementptr inbounds i8, i8* %t502, i64 -16
  %t514 = bitcast i8* %t513 to i64*
  %t515 = load atomic i64, i64* %t514 seq_cst, align 8
  %t516 = icmp eq i64 %t515, 1
  br i1 %t516, label %table_cow_done_78, label %table_cow_clone_79
table_cow_clone_79:
  %t517 = bitcast i8* %t502 to { i64, i64, i32*, i32* }*
  %t518 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t517, i32 0, i32 0
  %t519 = load i64, i64* %t518
  %t520 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t517, i32 0, i32 1
  %t521 = load i64, i64* %t520
  %t522 = bitcast void (i8*)* @table_release_s_Point to i8*
  %t523 = getelementptr { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* null, i32 1
  %t524 = ptrtoint { i64, i64, i32*, i32* }* %t523 to i64
  %t525 = call i8* @star_rc_alloc(i64 %t524, i8* %t522)
  %t526 = bitcast i8* %t525 to { i64, i64, i32*, i32* }*
  %t527 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t526, i32 0, i32 0
  store i64 %t519, i64* %t527
  %t528 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t526, i32 0, i32 1
  store i64 %t521, i64* %t528
  %t529 = getelementptr i32, i32* null, i32 1
  %t530 = ptrtoint i32* %t529 to i64
  %t531 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t517, i32 0, i32 2
  %t532 = load i32*, i32** %t531
  %t533 = mul i64 %t521, %t530
  %t534 = call i8* @malloc(i64 %t533)
  %t535 = bitcast i8* %t534 to i32*
  %t536 = icmp sgt i64 %t519, 0
  br i1 %t536, label %table_cow_copy_80, label %table_cow_after_copy_81
table_cow_copy_80:
  %t537 = mul i64 %t519, %t530
  %t538 = bitcast i32* %t532 to i8*
  call i8* @memcpy(i8* %t534, i8* %t538, i64 %t537)
  br label %table_cow_after_copy_81
table_cow_after_copy_81:
  %t539 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t526, i32 0, i32 2
  store i32* %t535, i32** %t539
  %t540 = getelementptr i32, i32* null, i32 1
  %t541 = ptrtoint i32* %t540 to i64
  %t542 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t517, i32 0, i32 3
  %t543 = load i32*, i32** %t542
  %t544 = mul i64 %t521, %t541
  %t545 = call i8* @malloc(i64 %t544)
  %t546 = bitcast i8* %t545 to i32*
  %t547 = icmp sgt i64 %t519, 0
  br i1 %t547, label %table_cow_copy_82, label %table_cow_after_copy_83
table_cow_copy_82:
  %t548 = mul i64 %t519, %t541
  %t549 = bitcast i32* %t543 to i8*
  call i8* @memcpy(i8* %t545, i8* %t549, i64 %t548)
  br label %table_cow_after_copy_83
table_cow_after_copy_83:
  %t550 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t526, i32 0, i32 3
  store i32* %t546, i32** %t550
  call void @star_rc_release(i8* %t502)
  store i8* %t525, i8** %t499
  br label %table_cow_done_78
table_cow_done_78:
  %t551 = load i8*, i8** %t499
  %t552 = bitcast i8* %t551 to { i64, i64, i32*, i32* }*
  %t553 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t552, i32 0, i32 0
  %t554 = load i64, i64* %t553
  %t555 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t552, i32 0, i32 1
  %t556 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t552, i32 0, i32 2
  %t557 = load i32*, i32** %t556
  %t558 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t552, i32 0, i32 3
  %t559 = load i32*, i32** %t558
  %t561 = getelementptr inbounds %Point, %Point* %t560, i32 0, i32 0
  store i32 5, i32* %t561
  %t562 = getelementptr inbounds %Point, %Point* %t560, i32 0, i32 1
  store i32 6, i32* %t562
  %t563 = load %Point, %Point* %t560
  %t564 = load i64, i64* %t555
  %t565 = load i64, i64* %t553
  %t566 = load i32*, i32** %t556
  %t567 = load i32*, i32** %t558
  %t568 = icmp sge i64 %t565, %t564
  br i1 %t568, label %table_push_grow_84, label %table_push_store_85
table_push_grow_84:
  %t569 = mul i64 %t564, 2
  %t570 = icmp sgt i64 %t569, 0
  %t571 = select i1 %t570, i64 %t569, i64 1
  %t572 = getelementptr i32, i32* null, i32 1
  %t573 = ptrtoint i32* %t572 to i64
  %t574 = mul i64 %t571, %t573
  %t575 = call i8* @malloc(i64 %t574)
  %t576 = bitcast i8* %t575 to i32*
  %t577 = icmp sgt i64 %t564, 0
  br i1 %t577, label %table_push_copy_86, label %table_push_after_copy_87
table_push_copy_86:
  %t578 = mul i64 %t565, %t573
  %t579 = bitcast i32* %t566 to i8*
  call i8* @memcpy(i8* %t575, i8* %t579, i64 %t578)
  call void @free(i8* %t579)
  br label %table_push_after_copy_87
table_push_after_copy_87:
  store i32* %t576, i32** %t556
  %t580 = getelementptr i32, i32* null, i32 1
  %t581 = ptrtoint i32* %t580 to i64
  %t582 = mul i64 %t571, %t581
  %t583 = call i8* @malloc(i64 %t582)
  %t584 = bitcast i8* %t583 to i32*
  %t585 = icmp sgt i64 %t564, 0
  br i1 %t585, label %table_push_copy_88, label %table_push_after_copy_89
table_push_copy_88:
  %t586 = mul i64 %t565, %t581
  %t587 = bitcast i32* %t567 to i8*
  call i8* @memcpy(i8* %t583, i8* %t587, i64 %t586)
  call void @free(i8* %t587)
  br label %table_push_after_copy_89
table_push_after_copy_89:
  store i32* %t584, i32** %t558
  store i64 %t571, i64* %t555
  br label %table_push_store_85
table_push_store_85:
  %t588 = load i32*, i32** %t556
  %t589 = extractvalue %Point %t563, 0
  %t590 = getelementptr inbounds i32, i32* %t588, i64 %t565
  store i32 %t589, i32* %t590
  %t591 = load i32*, i32** %t558
  %t592 = extractvalue %Point %t563, 1
  %t593 = getelementptr inbounds i32, i32* %t591, i64 %t565
  store i32 %t592, i32* %t593
  %t594 = add i64 %t565, 1
  store i64 %t594, i64* %t553
  %t595 = load i8*, i8** %t303
  %t596 = icmp eq i8* %t595, null
  br i1 %t596, label %table_read_null_90, label %table_read_real_91
table_read_null_90:
  br label %table_read_end_92
table_read_real_91:
  %t597 = bitcast i8* %t595 to { i64, i64, i32*, i32* }*
  %t598 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t597, i32 0, i32 0
  %t599 = load i64, i64* %t598
  %t600 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t597, i32 0, i32 2
  %t601 = load i32*, i32** %t600
  %t602 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t597, i32 0, i32 3
  %t603 = load i32*, i32** %t602
  br label %table_read_end_92
table_read_end_92:
  %t604 = phi i64 [ 0, %table_read_null_90 ], [ %t599, %table_read_real_91 ]
  %t605 = phi i32* [ null, %table_read_null_90 ], [ %t601, %table_read_real_91 ]
  %t606 = phi i32* [ null, %table_read_null_90 ], [ %t603, %table_read_real_91 ]
  %t607 = trunc i64 %t604 to i32
  %t608 = load i8*, i8** %t499
  %t609 = icmp eq i8* %t608, null
  br i1 %t609, label %table_read_null_93, label %table_read_real_94
table_read_null_93:
  br label %table_read_end_95
table_read_real_94:
  %t610 = bitcast i8* %t608 to { i64, i64, i32*, i32* }*
  %t611 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t610, i32 0, i32 0
  %t612 = load i64, i64* %t611
  %t613 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t610, i32 0, i32 2
  %t614 = load i32*, i32** %t613
  %t615 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t610, i32 0, i32 3
  %t616 = load i32*, i32** %t615
  br label %table_read_end_95
table_read_end_95:
  %t617 = phi i64 [ 0, %table_read_null_93 ], [ %t612, %table_read_real_94 ]
  %t618 = phi i32* [ null, %table_read_null_93 ], [ %t614, %table_read_real_94 ]
  %t619 = phi i32* [ null, %table_read_null_93 ], [ %t616, %table_read_real_94 ]
  %t620 = trunc i64 %t617 to i32
  %t621 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t621, i32 %t607, i32 %t620)
  %t622 = sext i32 1 to i64
  %t623 = load i8*, i8** %t303
  %t624 = icmp eq i8* %t623, null
  br i1 %t624, label %table_read_null_96, label %table_read_real_97
table_read_null_96:
  br label %table_read_end_98
table_read_real_97:
  %t625 = bitcast i8* %t623 to { i64, i64, i32*, i32* }*
  %t626 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t625, i32 0, i32 0
  %t627 = load i64, i64* %t626
  %t628 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t625, i32 0, i32 2
  %t629 = load i32*, i32** %t628
  %t630 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t625, i32 0, i32 3
  %t631 = load i32*, i32** %t630
  br label %table_read_end_98
table_read_end_98:
  %t632 = phi i64 [ 0, %table_read_null_96 ], [ %t627, %table_read_real_97 ]
  %t633 = phi i32* [ null, %table_read_null_96 ], [ %t629, %table_read_real_97 ]
  %t634 = phi i32* [ null, %table_read_null_96 ], [ %t631, %table_read_real_97 ]
  %t636 = icmp ult i64 %t622, %t632
  br i1 %t636, label %table_idx_ok_99, label %table_idx_oob_100
table_idx_ok_99:
  %t637 = getelementptr inbounds i32, i32* %t633, i64 %t622
  %t638 = load i32, i32* %t637
  %t639 = getelementptr inbounds %Point, %Point* %t635, i32 0, i32 0
  store i32 %t638, i32* %t639
  %t640 = getelementptr inbounds i32, i32* %t634, i64 %t622
  %t641 = load i32, i32* %t640
  %t642 = getelementptr inbounds %Point, %Point* %t635, i32 0, i32 1
  store i32 %t641, i32* %t642
  br label %table_idx_end_101
table_idx_oob_100:
  store %Point zeroinitializer, %Point* %t635
  br label %table_idx_end_101
table_idx_end_101:
  %t643 = load %Point, %Point* %t635
  store %Point %t643, %Point* %t644
  %t645 = getelementptr inbounds %Point, %Point* %t644, i32 0, i32 0
  %t646 = load i32, i32* %t645
  %t647 = sext i32 1 to i64
  %t648 = load i8*, i8** %t303
  %t649 = icmp eq i8* %t648, null
  br i1 %t649, label %table_read_null_102, label %table_read_real_103
table_read_null_102:
  br label %table_read_end_104
table_read_real_103:
  %t650 = bitcast i8* %t648 to { i64, i64, i32*, i32* }*
  %t651 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t650, i32 0, i32 0
  %t652 = load i64, i64* %t651
  %t653 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t650, i32 0, i32 2
  %t654 = load i32*, i32** %t653
  %t655 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t650, i32 0, i32 3
  %t656 = load i32*, i32** %t655
  br label %table_read_end_104
table_read_end_104:
  %t657 = phi i64 [ 0, %table_read_null_102 ], [ %t652, %table_read_real_103 ]
  %t658 = phi i32* [ null, %table_read_null_102 ], [ %t654, %table_read_real_103 ]
  %t659 = phi i32* [ null, %table_read_null_102 ], [ %t656, %table_read_real_103 ]
  %t661 = icmp ult i64 %t647, %t657
  br i1 %t661, label %table_idx_ok_105, label %table_idx_oob_106
table_idx_ok_105:
  %t662 = getelementptr inbounds i32, i32* %t658, i64 %t647
  %t663 = load i32, i32* %t662
  %t664 = getelementptr inbounds %Point, %Point* %t660, i32 0, i32 0
  store i32 %t663, i32* %t664
  %t665 = getelementptr inbounds i32, i32* %t659, i64 %t647
  %t666 = load i32, i32* %t665
  %t667 = getelementptr inbounds %Point, %Point* %t660, i32 0, i32 1
  store i32 %t666, i32* %t667
  br label %table_idx_end_107
table_idx_oob_106:
  store %Point zeroinitializer, %Point* %t660
  br label %table_idx_end_107
table_idx_end_107:
  %t668 = load %Point, %Point* %t660
  store %Point %t668, %Point* %t669
  %t670 = getelementptr inbounds %Point, %Point* %t669, i32 0, i32 1
  %t671 = load i32, i32* %t670
  %t672 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t672, i32 %t646, i32 %t671)
  %t673 = sub i32 0, 1
  %t674 = sext i32 %t673 to i64
  %t675 = load i8*, i8** %t303
  %t676 = icmp eq i8* %t675, null
  br i1 %t676, label %table_read_null_108, label %table_read_real_109
table_read_null_108:
  br label %table_read_end_110
table_read_real_109:
  %t677 = bitcast i8* %t675 to { i64, i64, i32*, i32* }*
  %t678 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t677, i32 0, i32 0
  %t679 = load i64, i64* %t678
  %t680 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t677, i32 0, i32 2
  %t681 = load i32*, i32** %t680
  %t682 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t677, i32 0, i32 3
  %t683 = load i32*, i32** %t682
  br label %table_read_end_110
table_read_end_110:
  %t684 = phi i64 [ 0, %table_read_null_108 ], [ %t679, %table_read_real_109 ]
  %t685 = phi i32* [ null, %table_read_null_108 ], [ %t681, %table_read_real_109 ]
  %t686 = phi i32* [ null, %table_read_null_108 ], [ %t683, %table_read_real_109 ]
  %t688 = icmp ult i64 %t674, %t684
  br i1 %t688, label %table_idx_ok_111, label %table_idx_oob_112
table_idx_ok_111:
  %t689 = getelementptr inbounds i32, i32* %t685, i64 %t674
  %t690 = load i32, i32* %t689
  %t691 = getelementptr inbounds %Point, %Point* %t687, i32 0, i32 0
  store i32 %t690, i32* %t691
  %t692 = getelementptr inbounds i32, i32* %t686, i64 %t674
  %t693 = load i32, i32* %t692
  %t694 = getelementptr inbounds %Point, %Point* %t687, i32 0, i32 1
  store i32 %t693, i32* %t694
  br label %table_idx_end_113
table_idx_oob_112:
  store %Point zeroinitializer, %Point* %t687
  br label %table_idx_end_113
table_idx_end_113:
  %t695 = load %Point, %Point* %t687
  store %Point %t695, %Point* %t696
  %t697 = getelementptr inbounds %Point, %Point* %t696, i32 0, i32 0
  %t698 = load i32, i32* %t697
  %t699 = sub i32 0, 1
  %t700 = sext i32 %t699 to i64
  %t701 = load i8*, i8** %t303
  %t702 = icmp eq i8* %t701, null
  br i1 %t702, label %table_read_null_114, label %table_read_real_115
table_read_null_114:
  br label %table_read_end_116
table_read_real_115:
  %t703 = bitcast i8* %t701 to { i64, i64, i32*, i32* }*
  %t704 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t703, i32 0, i32 0
  %t705 = load i64, i64* %t704
  %t706 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t703, i32 0, i32 2
  %t707 = load i32*, i32** %t706
  %t708 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t703, i32 0, i32 3
  %t709 = load i32*, i32** %t708
  br label %table_read_end_116
table_read_end_116:
  %t710 = phi i64 [ 0, %table_read_null_114 ], [ %t705, %table_read_real_115 ]
  %t711 = phi i32* [ null, %table_read_null_114 ], [ %t707, %table_read_real_115 ]
  %t712 = phi i32* [ null, %table_read_null_114 ], [ %t709, %table_read_real_115 ]
  %t714 = icmp ult i64 %t700, %t710
  br i1 %t714, label %table_idx_ok_117, label %table_idx_oob_118
table_idx_ok_117:
  %t715 = getelementptr inbounds i32, i32* %t711, i64 %t700
  %t716 = load i32, i32* %t715
  %t717 = getelementptr inbounds %Point, %Point* %t713, i32 0, i32 0
  store i32 %t716, i32* %t717
  %t718 = getelementptr inbounds i32, i32* %t712, i64 %t700
  %t719 = load i32, i32* %t718
  %t720 = getelementptr inbounds %Point, %Point* %t713, i32 0, i32 1
  store i32 %t719, i32* %t720
  br label %table_idx_end_119
table_idx_oob_118:
  store %Point zeroinitializer, %Point* %t713
  br label %table_idx_end_119
table_idx_end_119:
  %t721 = load %Point, %Point* %t713
  store %Point %t721, %Point* %t722
  %t723 = getelementptr inbounds %Point, %Point* %t722, i32 0, i32 1
  %t724 = load i32, i32* %t723
  %t725 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t725, i32 %t698, i32 %t724)
  store i8* null, i8** %t726
  %t727 = load i8*, i8** %t726
  %t728 = icmp eq i8* %t727, null
  br i1 %t728, label %table_cow_alloc_120, label %table_cow_check_121
table_cow_alloc_120:
  %t750 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t751 = getelementptr { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* null, i32 1
  %t752 = ptrtoint { i64, i64, i8**, i8** }* %t751 to i64
  %t753 = call i8* @star_rc_alloc(i64 %t752, i8* %t750)
  %t754 = bitcast i8* %t753 to { i64, i64, i8**, i8** }*
  %t755 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t754, i32 0, i32 0
  store i64 0, i64* %t755
  %t756 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t754, i32 0, i32 1
  store i64 0, i64* %t756
  %t757 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t754, i32 0, i32 2
  store i8** null, i8*** %t757
  %t758 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t754, i32 0, i32 3
  store i8** null, i8*** %t758
  store i8* %t753, i8** %t726
  br label %table_cow_done_122
table_cow_check_121:
  %t759 = getelementptr inbounds i8, i8* %t727, i64 -16
  %t760 = bitcast i8* %t759 to i64*
  %t761 = load atomic i64, i64* %t760 seq_cst, align 8
  %t762 = icmp eq i64 %t761, 1
  br i1 %t762, label %table_cow_done_122, label %table_cow_clone_129
table_cow_clone_129:
  %t763 = bitcast i8* %t727 to { i64, i64, i8**, i8** }*
  %t764 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t763, i32 0, i32 0
  %t765 = load i64, i64* %t764
  %t766 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t763, i32 0, i32 1
  %t767 = load i64, i64* %t766
  %t768 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t769 = getelementptr { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* null, i32 1
  %t770 = ptrtoint { i64, i64, i8**, i8** }* %t769 to i64
  %t771 = call i8* @star_rc_alloc(i64 %t770, i8* %t768)
  %t772 = bitcast i8* %t771 to { i64, i64, i8**, i8** }*
  %t773 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t772, i32 0, i32 0
  store i64 %t765, i64* %t773
  %t774 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t772, i32 0, i32 1
  store i64 %t767, i64* %t774
  %t775 = getelementptr i8*, i8** null, i32 1
  %t776 = ptrtoint i8** %t775 to i64
  %t777 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t763, i32 0, i32 2
  %t778 = load i8**, i8*** %t777
  %t779 = mul i64 %t767, %t776
  %t780 = call i8* @malloc(i64 %t779)
  %t781 = bitcast i8* %t780 to i8**
  %t782 = icmp sgt i64 %t765, 0
  br i1 %t782, label %table_cow_copy_130, label %table_cow_after_copy_131
table_cow_copy_130:
  %t783 = mul i64 %t765, %t776
  %t784 = bitcast i8** %t778 to i8*
  call i8* @memcpy(i8* %t780, i8* %t784, i64 %t783)
  store i64 0, i64* %t785
  br label %table_cow_retain_cond_132
table_cow_retain_cond_132:
  %t786 = load i64, i64* %t785
  %t787 = icmp slt i64 %t786, %t765
  br i1 %t787, label %table_cow_retain_body_133, label %table_cow_retain_end_134
table_cow_retain_body_133:
  %t788 = getelementptr inbounds i8*, i8** %t781, i64 %t786
  %t789 = load i8*, i8** %t788
  call void @star_rc_retain(i8* %t789)
  %t790 = add i64 %t786, 1
  store i64 %t790, i64* %t785
  br label %table_cow_retain_cond_132
table_cow_retain_end_134:
  br label %table_cow_after_copy_131
table_cow_after_copy_131:
  %t791 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t772, i32 0, i32 2
  store i8** %t781, i8*** %t791
  %t792 = getelementptr i8*, i8** null, i32 1
  %t793 = ptrtoint i8** %t792 to i64
  %t794 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t763, i32 0, i32 3
  %t795 = load i8**, i8*** %t794
  %t796 = mul i64 %t767, %t793
  %t797 = call i8* @malloc(i64 %t796)
  %t798 = bitcast i8* %t797 to i8**
  %t799 = icmp sgt i64 %t765, 0
  br i1 %t799, label %table_cow_copy_135, label %table_cow_after_copy_136
table_cow_copy_135:
  %t800 = mul i64 %t765, %t793
  %t801 = bitcast i8** %t795 to i8*
  call i8* @memcpy(i8* %t797, i8* %t801, i64 %t800)
  store i64 0, i64* %t802
  br label %table_cow_retain_cond_137
table_cow_retain_cond_137:
  %t803 = load i64, i64* %t802
  %t804 = icmp slt i64 %t803, %t765
  br i1 %t804, label %table_cow_retain_body_138, label %table_cow_retain_end_139
table_cow_retain_body_138:
  %t805 = getelementptr inbounds i8*, i8** %t798, i64 %t803
  %t806 = load i8*, i8** %t805
  call void @star_rc_retain(i8* %t806)
  %t807 = add i64 %t803, 1
  store i64 %t807, i64* %t802
  br label %table_cow_retain_cond_137
table_cow_retain_end_139:
  br label %table_cow_after_copy_136
table_cow_after_copy_136:
  %t808 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t772, i32 0, i32 3
  store i8** %t798, i8*** %t808
  call void @star_rc_release(i8* %t727)
  store i8* %t771, i8** %t726
  br label %table_cow_done_122
table_cow_done_122:
  %t809 = load i8*, i8** %t726
  %t810 = bitcast i8* %t809 to { i64, i64, i8**, i8** }*
  %t811 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t810, i32 0, i32 0
  %t812 = load i64, i64* %t811
  %t813 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t810, i32 0, i32 1
  %t814 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t810, i32 0, i32 2
  %t815 = load i8**, i8*** %t814
  %t816 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t810, i32 0, i32 3
  %t817 = load i8**, i8*** %t816
  %t819 = getelementptr i32, i32* null, i32 1
  %t820 = ptrtoint i32* %t819 to i64
  %t821 = mul i64 %t820, 3
  %t822 = call i8* @malloc(i64 %t821)
  %t823 = bitcast i8* %t822 to i32*
  %t824 = getelementptr inbounds i32, i32* %t823, i64 0
  store i32 7, i32* %t824
  %t825 = getelementptr inbounds i32, i32* %t823, i64 1
  store i32 8, i32* %t825
  %t826 = getelementptr inbounds i32, i32* %t823, i64 2
  store i32 9, i32* %t826
  %t827 = bitcast void (i8*)* @list_release_i32 to i8*
  %t828 = call i8* @star_rc_alloc(i64 24, i8* %t827)
  %t829 = bitcast i8* %t828 to { i32*, i64, i64 }*
  %t830 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t829, i32 0, i32 0
  store i32* %t823, i32** %t830
  %t831 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t829, i32 0, i32 1
  store i64 3, i64* %t831
  %t832 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t829, i32 0, i32 2
  store i64 3, i64* %t832
  %t833 = getelementptr inbounds %Bag, %Bag* %t818, i32 0, i32 0
  store i8* %t828, i8** %t833
  %t834 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t835 = getelementptr inbounds %Bag, %Bag* %t818, i32 0, i32 1
  store i8* %t834, i8** %t835
  %t836 = load %Bag, %Bag* %t818
  %t837 = load i64, i64* %t813
  %t838 = load i64, i64* %t811
  %t839 = load i8**, i8*** %t814
  %t840 = load i8**, i8*** %t816
  %t841 = icmp sge i64 %t838, %t837
  br i1 %t841, label %table_push_grow_140, label %table_push_store_141
table_push_grow_140:
  %t842 = mul i64 %t837, 2
  %t843 = icmp sgt i64 %t842, 0
  %t844 = select i1 %t843, i64 %t842, i64 1
  %t845 = getelementptr i8*, i8** null, i32 1
  %t846 = ptrtoint i8** %t845 to i64
  %t847 = mul i64 %t844, %t846
  %t848 = call i8* @malloc(i64 %t847)
  %t849 = bitcast i8* %t848 to i8**
  %t850 = icmp sgt i64 %t837, 0
  br i1 %t850, label %table_push_copy_142, label %table_push_after_copy_143
table_push_copy_142:
  %t851 = mul i64 %t838, %t846
  %t852 = bitcast i8** %t839 to i8*
  call i8* @memcpy(i8* %t848, i8* %t852, i64 %t851)
  call void @free(i8* %t852)
  br label %table_push_after_copy_143
table_push_after_copy_143:
  store i8** %t849, i8*** %t814
  %t853 = getelementptr i8*, i8** null, i32 1
  %t854 = ptrtoint i8** %t853 to i64
  %t855 = mul i64 %t844, %t854
  %t856 = call i8* @malloc(i64 %t855)
  %t857 = bitcast i8* %t856 to i8**
  %t858 = icmp sgt i64 %t837, 0
  br i1 %t858, label %table_push_copy_144, label %table_push_after_copy_145
table_push_copy_144:
  %t859 = mul i64 %t838, %t854
  %t860 = bitcast i8** %t840 to i8*
  call i8* @memcpy(i8* %t856, i8* %t860, i64 %t859)
  call void @free(i8* %t860)
  br label %table_push_after_copy_145
table_push_after_copy_145:
  store i8** %t857, i8*** %t816
  store i64 %t844, i64* %t813
  br label %table_push_store_141
table_push_store_141:
  %t861 = load i8**, i8*** %t814
  %t862 = extractvalue %Bag %t836, 0
  %t863 = getelementptr inbounds i8*, i8** %t861, i64 %t838
  store i8* %t862, i8** %t863
  %t864 = load i8**, i8*** %t816
  %t865 = extractvalue %Bag %t836, 1
  %t866 = getelementptr inbounds i8*, i8** %t864, i64 %t838
  store i8* %t865, i8** %t866
  %t867 = add i64 %t838, 1
  store i64 %t867, i64* %t811
  %t868 = load i8*, i8** %t726
  %t869 = icmp eq i8* %t868, null
  br i1 %t869, label %table_cow_alloc_146, label %table_cow_check_147
table_cow_alloc_146:
  %t870 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t871 = getelementptr { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* null, i32 1
  %t872 = ptrtoint { i64, i64, i8**, i8** }* %t871 to i64
  %t873 = call i8* @star_rc_alloc(i64 %t872, i8* %t870)
  %t874 = bitcast i8* %t873 to { i64, i64, i8**, i8** }*
  %t875 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t874, i32 0, i32 0
  store i64 0, i64* %t875
  %t876 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t874, i32 0, i32 1
  store i64 0, i64* %t876
  %t877 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t874, i32 0, i32 2
  store i8** null, i8*** %t877
  %t878 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t874, i32 0, i32 3
  store i8** null, i8*** %t878
  store i8* %t873, i8** %t726
  br label %table_cow_done_148
table_cow_check_147:
  %t879 = getelementptr inbounds i8, i8* %t868, i64 -16
  %t880 = bitcast i8* %t879 to i64*
  %t881 = load atomic i64, i64* %t880 seq_cst, align 8
  %t882 = icmp eq i64 %t881, 1
  br i1 %t882, label %table_cow_done_148, label %table_cow_clone_149
table_cow_clone_149:
  %t883 = bitcast i8* %t868 to { i64, i64, i8**, i8** }*
  %t884 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t883, i32 0, i32 0
  %t885 = load i64, i64* %t884
  %t886 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t883, i32 0, i32 1
  %t887 = load i64, i64* %t886
  %t888 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t889 = getelementptr { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* null, i32 1
  %t890 = ptrtoint { i64, i64, i8**, i8** }* %t889 to i64
  %t891 = call i8* @star_rc_alloc(i64 %t890, i8* %t888)
  %t892 = bitcast i8* %t891 to { i64, i64, i8**, i8** }*
  %t893 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t892, i32 0, i32 0
  store i64 %t885, i64* %t893
  %t894 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t892, i32 0, i32 1
  store i64 %t887, i64* %t894
  %t895 = getelementptr i8*, i8** null, i32 1
  %t896 = ptrtoint i8** %t895 to i64
  %t897 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t883, i32 0, i32 2
  %t898 = load i8**, i8*** %t897
  %t899 = mul i64 %t887, %t896
  %t900 = call i8* @malloc(i64 %t899)
  %t901 = bitcast i8* %t900 to i8**
  %t902 = icmp sgt i64 %t885, 0
  br i1 %t902, label %table_cow_copy_150, label %table_cow_after_copy_151
table_cow_copy_150:
  %t903 = mul i64 %t885, %t896
  %t904 = bitcast i8** %t898 to i8*
  call i8* @memcpy(i8* %t900, i8* %t904, i64 %t903)
  store i64 0, i64* %t905
  br label %table_cow_retain_cond_152
table_cow_retain_cond_152:
  %t906 = load i64, i64* %t905
  %t907 = icmp slt i64 %t906, %t885
  br i1 %t907, label %table_cow_retain_body_153, label %table_cow_retain_end_154
table_cow_retain_body_153:
  %t908 = getelementptr inbounds i8*, i8** %t901, i64 %t906
  %t909 = load i8*, i8** %t908
  call void @star_rc_retain(i8* %t909)
  %t910 = add i64 %t906, 1
  store i64 %t910, i64* %t905
  br label %table_cow_retain_cond_152
table_cow_retain_end_154:
  br label %table_cow_after_copy_151
table_cow_after_copy_151:
  %t911 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t892, i32 0, i32 2
  store i8** %t901, i8*** %t911
  %t912 = getelementptr i8*, i8** null, i32 1
  %t913 = ptrtoint i8** %t912 to i64
  %t914 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t883, i32 0, i32 3
  %t915 = load i8**, i8*** %t914
  %t916 = mul i64 %t887, %t913
  %t917 = call i8* @malloc(i64 %t916)
  %t918 = bitcast i8* %t917 to i8**
  %t919 = icmp sgt i64 %t885, 0
  br i1 %t919, label %table_cow_copy_155, label %table_cow_after_copy_156
table_cow_copy_155:
  %t920 = mul i64 %t885, %t913
  %t921 = bitcast i8** %t915 to i8*
  call i8* @memcpy(i8* %t917, i8* %t921, i64 %t920)
  store i64 0, i64* %t922
  br label %table_cow_retain_cond_157
table_cow_retain_cond_157:
  %t923 = load i64, i64* %t922
  %t924 = icmp slt i64 %t923, %t885
  br i1 %t924, label %table_cow_retain_body_158, label %table_cow_retain_end_159
table_cow_retain_body_158:
  %t925 = getelementptr inbounds i8*, i8** %t918, i64 %t923
  %t926 = load i8*, i8** %t925
  call void @star_rc_retain(i8* %t926)
  %t927 = add i64 %t923, 1
  store i64 %t927, i64* %t922
  br label %table_cow_retain_cond_157
table_cow_retain_end_159:
  br label %table_cow_after_copy_156
table_cow_after_copy_156:
  %t928 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t892, i32 0, i32 3
  store i8** %t918, i8*** %t928
  call void @star_rc_release(i8* %t868)
  store i8* %t891, i8** %t726
  br label %table_cow_done_148
table_cow_done_148:
  %t929 = load i8*, i8** %t726
  %t930 = bitcast i8* %t929 to { i64, i64, i8**, i8** }*
  %t931 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t930, i32 0, i32 0
  %t932 = load i64, i64* %t931
  %t933 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t930, i32 0, i32 1
  %t934 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t930, i32 0, i32 2
  %t935 = load i8**, i8*** %t934
  %t936 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t930, i32 0, i32 3
  %t937 = load i8**, i8*** %t936
  %t939 = getelementptr inbounds %Bag, %Bag* %t938, i32 0, i32 0
  store i8* null, i8** %t939
  %t940 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t941 = getelementptr inbounds %Bag, %Bag* %t938, i32 0, i32 1
  store i8* %t940, i8** %t941
  %t942 = load %Bag, %Bag* %t938
  %t943 = load i64, i64* %t933
  %t944 = load i64, i64* %t931
  %t945 = load i8**, i8*** %t934
  %t946 = load i8**, i8*** %t936
  %t947 = icmp sge i64 %t944, %t943
  br i1 %t947, label %table_push_grow_160, label %table_push_store_161
table_push_grow_160:
  %t948 = mul i64 %t943, 2
  %t949 = icmp sgt i64 %t948, 0
  %t950 = select i1 %t949, i64 %t948, i64 1
  %t951 = getelementptr i8*, i8** null, i32 1
  %t952 = ptrtoint i8** %t951 to i64
  %t953 = mul i64 %t950, %t952
  %t954 = call i8* @malloc(i64 %t953)
  %t955 = bitcast i8* %t954 to i8**
  %t956 = icmp sgt i64 %t943, 0
  br i1 %t956, label %table_push_copy_162, label %table_push_after_copy_163
table_push_copy_162:
  %t957 = mul i64 %t944, %t952
  %t958 = bitcast i8** %t945 to i8*
  call i8* @memcpy(i8* %t954, i8* %t958, i64 %t957)
  call void @free(i8* %t958)
  br label %table_push_after_copy_163
table_push_after_copy_163:
  store i8** %t955, i8*** %t934
  %t959 = getelementptr i8*, i8** null, i32 1
  %t960 = ptrtoint i8** %t959 to i64
  %t961 = mul i64 %t950, %t960
  %t962 = call i8* @malloc(i64 %t961)
  %t963 = bitcast i8* %t962 to i8**
  %t964 = icmp sgt i64 %t943, 0
  br i1 %t964, label %table_push_copy_164, label %table_push_after_copy_165
table_push_copy_164:
  %t965 = mul i64 %t944, %t960
  %t966 = bitcast i8** %t946 to i8*
  call i8* @memcpy(i8* %t962, i8* %t966, i64 %t965)
  call void @free(i8* %t966)
  br label %table_push_after_copy_165
table_push_after_copy_165:
  store i8** %t963, i8*** %t936
  store i64 %t950, i64* %t933
  br label %table_push_store_161
table_push_store_161:
  %t967 = load i8**, i8*** %t934
  %t968 = extractvalue %Bag %t942, 0
  %t969 = getelementptr inbounds i8*, i8** %t967, i64 %t944
  store i8* %t968, i8** %t969
  %t970 = load i8**, i8*** %t936
  %t971 = extractvalue %Bag %t942, 1
  %t972 = getelementptr inbounds i8*, i8** %t970, i64 %t944
  store i8* %t971, i8** %t972
  %t973 = add i64 %t944, 1
  store i64 %t973, i64* %t931
  %t974 = sext i32 0 to i64
  %t975 = load i8*, i8** %t726
  %t976 = icmp eq i8* %t975, null
  br i1 %t976, label %table_read_null_166, label %table_read_real_167
table_read_null_166:
  br label %table_read_end_168
table_read_real_167:
  %t977 = bitcast i8* %t975 to { i64, i64, i8**, i8** }*
  %t978 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t977, i32 0, i32 0
  %t979 = load i64, i64* %t978
  %t980 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t977, i32 0, i32 2
  %t981 = load i8**, i8*** %t980
  %t982 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t977, i32 0, i32 3
  %t983 = load i8**, i8*** %t982
  br label %table_read_end_168
table_read_end_168:
  %t984 = phi i64 [ 0, %table_read_null_166 ], [ %t979, %table_read_real_167 ]
  %t985 = phi i8** [ null, %table_read_null_166 ], [ %t981, %table_read_real_167 ]
  %t986 = phi i8** [ null, %table_read_null_166 ], [ %t983, %table_read_real_167 ]
  %t988 = icmp ult i64 %t974, %t984
  br i1 %t988, label %table_idx_ok_169, label %table_idx_oob_170
table_idx_ok_169:
  %t989 = getelementptr inbounds i8*, i8** %t985, i64 %t974
  %t990 = load i8*, i8** %t989
  call void @star_rc_retain(i8* %t990)
  %t991 = load i8*, i8** %t989
  %t992 = getelementptr inbounds %Bag, %Bag* %t987, i32 0, i32 0
  store i8* %t991, i8** %t992
  %t993 = getelementptr inbounds i8*, i8** %t986, i64 %t974
  %t994 = load i8*, i8** %t993
  call void @star_rc_retain(i8* %t994)
  %t995 = load i8*, i8** %t993
  %t996 = getelementptr inbounds %Bag, %Bag* %t987, i32 0, i32 1
  store i8* %t995, i8** %t996
  br label %table_idx_end_171
table_idx_oob_170:
  store %Bag zeroinitializer, %Bag* %t987
  br label %table_idx_end_171
table_idx_end_171:
  %t997 = load %Bag, %Bag* %t987
  store %Bag %t997, %Bag* %t998
  %t999 = getelementptr inbounds %Bag, %Bag* %t998, i32 0, i32 1
  %t1000 = load i8*, i8** %t999
  %t1001 = load i8*, i8** %t999
  call void @star_rc_retain(i8* %t1001)
  call void @star_rc_release(i8* %t1000)
  %t1002 = sext i32 0 to i64
  %t1003 = load i8*, i8** %t726
  %t1004 = icmp eq i8* %t1003, null
  br i1 %t1004, label %table_read_null_172, label %table_read_real_173
table_read_null_172:
  br label %table_read_end_174
table_read_real_173:
  %t1005 = bitcast i8* %t1003 to { i64, i64, i8**, i8** }*
  %t1006 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1005, i32 0, i32 0
  %t1007 = load i64, i64* %t1006
  %t1008 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1005, i32 0, i32 2
  %t1009 = load i8**, i8*** %t1008
  %t1010 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1005, i32 0, i32 3
  %t1011 = load i8**, i8*** %t1010
  br label %table_read_end_174
table_read_end_174:
  %t1012 = phi i64 [ 0, %table_read_null_172 ], [ %t1007, %table_read_real_173 ]
  %t1013 = phi i8** [ null, %table_read_null_172 ], [ %t1009, %table_read_real_173 ]
  %t1014 = phi i8** [ null, %table_read_null_172 ], [ %t1011, %table_read_real_173 ]
  %t1016 = icmp ult i64 %t1002, %t1012
  br i1 %t1016, label %table_idx_ok_175, label %table_idx_oob_176
table_idx_ok_175:
  %t1017 = getelementptr inbounds i8*, i8** %t1013, i64 %t1002
  %t1018 = load i8*, i8** %t1017
  call void @star_rc_retain(i8* %t1018)
  %t1019 = load i8*, i8** %t1017
  %t1020 = getelementptr inbounds %Bag, %Bag* %t1015, i32 0, i32 0
  store i8* %t1019, i8** %t1020
  %t1021 = getelementptr inbounds i8*, i8** %t1014, i64 %t1002
  %t1022 = load i8*, i8** %t1021
  call void @star_rc_retain(i8* %t1022)
  %t1023 = load i8*, i8** %t1021
  %t1024 = getelementptr inbounds %Bag, %Bag* %t1015, i32 0, i32 1
  store i8* %t1023, i8** %t1024
  br label %table_idx_end_177
table_idx_oob_176:
  store %Bag zeroinitializer, %Bag* %t1015
  br label %table_idx_end_177
table_idx_end_177:
  %t1025 = load %Bag, %Bag* %t1015
  store %Bag %t1025, %Bag* %t1026
  %t1027 = getelementptr inbounds %Bag, %Bag* %t1026, i32 0, i32 0
  %t1028 = load i8*, i8** %t1027
  %t1029 = icmp eq i8* %t1028, null
  br i1 %t1029, label %list_read_null_178, label %list_read_real_179
list_read_null_178:
  br label %list_read_end_180
list_read_real_179:
  %t1030 = bitcast i8* %t1028 to { i32*, i64, i64 }*
  %t1031 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1030, i32 0, i32 0
  %t1032 = load i32*, i32** %t1031
  %t1033 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1030, i32 0, i32 1
  %t1034 = load i64, i64* %t1033
  br label %list_read_end_180
list_read_end_180:
  %t1035 = phi i32* [ null, %list_read_null_178 ], [ %t1032, %list_read_real_179 ]
  %t1036 = phi i64 [ 0, %list_read_null_178 ], [ %t1034, %list_read_real_179 ]
  %t1037 = trunc i64 %t1036 to i32
  %t1038 = getelementptr inbounds [41 x i8], [41 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1038, i8* %t1000, i32 %t1037)
  %t1039 = sext i32 1 to i64
  %t1040 = load i8*, i8** %t726
  %t1041 = icmp eq i8* %t1040, null
  br i1 %t1041, label %table_read_null_181, label %table_read_real_182
table_read_null_181:
  br label %table_read_end_183
table_read_real_182:
  %t1042 = bitcast i8* %t1040 to { i64, i64, i8**, i8** }*
  %t1043 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1042, i32 0, i32 0
  %t1044 = load i64, i64* %t1043
  %t1045 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1042, i32 0, i32 2
  %t1046 = load i8**, i8*** %t1045
  %t1047 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1042, i32 0, i32 3
  %t1048 = load i8**, i8*** %t1047
  br label %table_read_end_183
table_read_end_183:
  %t1049 = phi i64 [ 0, %table_read_null_181 ], [ %t1044, %table_read_real_182 ]
  %t1050 = phi i8** [ null, %table_read_null_181 ], [ %t1046, %table_read_real_182 ]
  %t1051 = phi i8** [ null, %table_read_null_181 ], [ %t1048, %table_read_real_182 ]
  %t1053 = icmp ult i64 %t1039, %t1049
  br i1 %t1053, label %table_idx_ok_184, label %table_idx_oob_185
table_idx_ok_184:
  %t1054 = getelementptr inbounds i8*, i8** %t1050, i64 %t1039
  %t1055 = load i8*, i8** %t1054
  call void @star_rc_retain(i8* %t1055)
  %t1056 = load i8*, i8** %t1054
  %t1057 = getelementptr inbounds %Bag, %Bag* %t1052, i32 0, i32 0
  store i8* %t1056, i8** %t1057
  %t1058 = getelementptr inbounds i8*, i8** %t1051, i64 %t1039
  %t1059 = load i8*, i8** %t1058
  call void @star_rc_retain(i8* %t1059)
  %t1060 = load i8*, i8** %t1058
  %t1061 = getelementptr inbounds %Bag, %Bag* %t1052, i32 0, i32 1
  store i8* %t1060, i8** %t1061
  br label %table_idx_end_186
table_idx_oob_185:
  store %Bag zeroinitializer, %Bag* %t1052
  br label %table_idx_end_186
table_idx_end_186:
  %t1062 = load %Bag, %Bag* %t1052
  store %Bag %t1062, %Bag* %t1063
  %t1064 = getelementptr inbounds %Bag, %Bag* %t1063, i32 0, i32 1
  %t1065 = load i8*, i8** %t1064
  %t1066 = load i8*, i8** %t1064
  call void @star_rc_retain(i8* %t1066)
  call void @star_rc_release(i8* %t1065)
  %t1067 = sext i32 1 to i64
  %t1068 = load i8*, i8** %t726
  %t1069 = icmp eq i8* %t1068, null
  br i1 %t1069, label %table_read_null_187, label %table_read_real_188
table_read_null_187:
  br label %table_read_end_189
table_read_real_188:
  %t1070 = bitcast i8* %t1068 to { i64, i64, i8**, i8** }*
  %t1071 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1070, i32 0, i32 0
  %t1072 = load i64, i64* %t1071
  %t1073 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1070, i32 0, i32 2
  %t1074 = load i8**, i8*** %t1073
  %t1075 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t1070, i32 0, i32 3
  %t1076 = load i8**, i8*** %t1075
  br label %table_read_end_189
table_read_end_189:
  %t1077 = phi i64 [ 0, %table_read_null_187 ], [ %t1072, %table_read_real_188 ]
  %t1078 = phi i8** [ null, %table_read_null_187 ], [ %t1074, %table_read_real_188 ]
  %t1079 = phi i8** [ null, %table_read_null_187 ], [ %t1076, %table_read_real_188 ]
  %t1081 = icmp ult i64 %t1067, %t1077
  br i1 %t1081, label %table_idx_ok_190, label %table_idx_oob_191
table_idx_ok_190:
  %t1082 = getelementptr inbounds i8*, i8** %t1078, i64 %t1067
  %t1083 = load i8*, i8** %t1082
  call void @star_rc_retain(i8* %t1083)
  %t1084 = load i8*, i8** %t1082
  %t1085 = getelementptr inbounds %Bag, %Bag* %t1080, i32 0, i32 0
  store i8* %t1084, i8** %t1085
  %t1086 = getelementptr inbounds i8*, i8** %t1079, i64 %t1067
  %t1087 = load i8*, i8** %t1086
  call void @star_rc_retain(i8* %t1087)
  %t1088 = load i8*, i8** %t1086
  %t1089 = getelementptr inbounds %Bag, %Bag* %t1080, i32 0, i32 1
  store i8* %t1088, i8** %t1089
  br label %table_idx_end_192
table_idx_oob_191:
  store %Bag zeroinitializer, %Bag* %t1080
  br label %table_idx_end_192
table_idx_end_192:
  %t1090 = load %Bag, %Bag* %t1080
  store %Bag %t1090, %Bag* %t1091
  %t1092 = getelementptr inbounds %Bag, %Bag* %t1091, i32 0, i32 0
  %t1093 = load i8*, i8** %t1092
  %t1094 = icmp eq i8* %t1093, null
  br i1 %t1094, label %list_read_null_193, label %list_read_real_194
list_read_null_193:
  br label %list_read_end_195
list_read_real_194:
  %t1095 = bitcast i8* %t1093 to { i32*, i64, i64 }*
  %t1096 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1095, i32 0, i32 0
  %t1097 = load i32*, i32** %t1096
  %t1098 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t1095, i32 0, i32 1
  %t1099 = load i64, i64* %t1098
  br label %list_read_end_195
list_read_end_195:
  %t1100 = phi i32* [ null, %list_read_null_193 ], [ %t1097, %list_read_real_194 ]
  %t1101 = phi i64 [ 0, %list_read_null_193 ], [ %t1099, %list_read_real_194 ]
  %t1102 = trunc i64 %t1101 to i32
  %t1103 = getelementptr inbounds [41 x i8], [41 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1103, i8* %t1065, i32 %t1102)
  %t1104 = getelementptr inbounds %Bag, %Bag* %t1091, i32 0, i32 0
  %t1105 = load i8*, i8** %t1104
  call void @star_rc_release(i8* %t1105)
  %t1106 = getelementptr inbounds %Bag, %Bag* %t1091, i32 0, i32 1
  %t1107 = load i8*, i8** %t1106
  call void @star_rc_release(i8* %t1107)
  %t1108 = getelementptr inbounds %Bag, %Bag* %t1063, i32 0, i32 0
  %t1109 = load i8*, i8** %t1108
  call void @star_rc_release(i8* %t1109)
  %t1110 = getelementptr inbounds %Bag, %Bag* %t1063, i32 0, i32 1
  %t1111 = load i8*, i8** %t1110
  call void @star_rc_release(i8* %t1111)
  %t1112 = getelementptr inbounds %Bag, %Bag* %t1026, i32 0, i32 0
  %t1113 = load i8*, i8** %t1112
  call void @star_rc_release(i8* %t1113)
  %t1114 = getelementptr inbounds %Bag, %Bag* %t1026, i32 0, i32 1
  %t1115 = load i8*, i8** %t1114
  call void @star_rc_release(i8* %t1115)
  %t1116 = getelementptr inbounds %Bag, %Bag* %t998, i32 0, i32 0
  %t1117 = load i8*, i8** %t1116
  call void @star_rc_release(i8* %t1117)
  %t1118 = getelementptr inbounds %Bag, %Bag* %t998, i32 0, i32 1
  %t1119 = load i8*, i8** %t1118
  call void @star_rc_release(i8* %t1119)
  %t1120 = load i8*, i8** %t726
  call void @star_rc_release(i8* %t1120)
  %t1121 = load i8*, i8** %t499
  call void @star_rc_release(i8* %t1121)
  %t1122 = load i8*, i8** %t303
  call void @star_rc_release(i8* %t1122)
  %t1123 = getelementptr inbounds { [2 x %Bag], i64, i64 }, { [2 x %Bag], i64, i64 }* %t107, i32 0, i32 0
  %t1124 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t1123, i32 0, i64 0
  %t1125 = getelementptr inbounds %Bag, %Bag* %t1124, i32 0, i32 0
  %t1126 = load i8*, i8** %t1125
  call void @star_rc_release(i8* %t1126)
  %t1127 = getelementptr inbounds %Bag, %Bag* %t1124, i32 0, i32 1
  %t1128 = load i8*, i8** %t1127
  call void @star_rc_release(i8* %t1128)
  %t1129 = getelementptr inbounds [2 x %Bag], [2 x %Bag]* %t1123, i32 0, i64 1
  %t1130 = getelementptr inbounds %Bag, %Bag* %t1129, i32 0, i32 0
  %t1131 = load i8*, i8** %t1130
  call void @star_rc_release(i8* %t1131)
  %t1132 = getelementptr inbounds %Bag, %Bag* %t1129, i32 0, i32 1
  %t1133 = load i8*, i8** %t1132
  call void @star_rc_release(i8* %t1133)
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
  %t306 = bitcast i8* %objp to { i64, i64, i32*, i32* }*
  %t307 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t306, i32 0, i32 0
  %t308 = load i64, i64* %t307
  %t309 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t306, i32 0, i32 2
  %t310 = load i32*, i32** %t309
  %t311 = bitcast i32* %t310 to i8*
  call void @free(i8* %t311)
  %t312 = getelementptr inbounds { i64, i64, i32*, i32* }, { i64, i64, i32*, i32* }* %t306, i32 0, i32 3
  %t313 = load i32*, i32** %t312
  %t314 = bitcast i32* %t313 to i8*
  call void @free(i8* %t314)
  ret void
}


define void @table_release_s_Bag(i8* %objp) {
entry:
  %t734 = alloca i64
  %t743 = alloca i64
  %t729 = bitcast i8* %objp to { i64, i64, i8**, i8** }*
  %t730 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t729, i32 0, i32 0
  %t731 = load i64, i64* %t730
  %t732 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t729, i32 0, i32 2
  %t733 = load i8**, i8*** %t732
  store i64 0, i64* %t734
  br label %table_release_cond_123
table_release_cond_123:
  %t735 = load i64, i64* %t734
  %t736 = icmp slt i64 %t735, %t731
  br i1 %t736, label %table_release_body_124, label %table_release_end_125
table_release_body_124:
  %t737 = getelementptr inbounds i8*, i8** %t733, i64 %t735
  %t738 = load i8*, i8** %t737
  call void @star_rc_release(i8* %t738)
  %t739 = add i64 %t735, 1
  store i64 %t739, i64* %t734
  br label %table_release_cond_123
table_release_end_125:
  %t740 = bitcast i8** %t733 to i8*
  call void @free(i8* %t740)
  %t741 = getelementptr inbounds { i64, i64, i8**, i8** }, { i64, i64, i8**, i8** }* %t729, i32 0, i32 3
  %t742 = load i8**, i8*** %t741
  store i64 0, i64* %t743
  br label %table_release_cond_126
table_release_cond_126:
  %t744 = load i64, i64* %t743
  %t745 = icmp slt i64 %t744, %t731
  br i1 %t745, label %table_release_body_127, label %table_release_end_128
table_release_body_127:
  %t746 = getelementptr inbounds i8*, i8** %t742, i64 %t744
  %t747 = load i8*, i8** %t746
  call void @star_rc_release(i8* %t747)
  %t748 = add i64 %t744, 1
  store i64 %t748, i64* %t743
  br label %table_release_cond_126
table_release_end_128:
  %t749 = bitcast i8** %t742 to i8*
  call void @free(i8* %t749)
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
